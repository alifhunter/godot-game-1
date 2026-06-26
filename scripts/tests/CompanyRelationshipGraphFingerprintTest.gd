extends Node

const COMPANY_RELATIONSHIP_GRAPH_SYSTEM := preload("res://systems/CompanyRelationshipGraphSystem.gd")

const RUN_SEED := 20260622
const EXPECTED_ROSTER_SIZE := 30
const EXPECTED_FINGERPRINT_HASH := "2129898825"
const EXPECTED_EDGE_COUNT := 46
const EXPECTED_FIRST_EDGE_ID := "edge|20260622|armada_kurir_nusantara|pasar_digital_prima|supplier|00"
const EXPECTED_LAST_EDGE_ID := "edge|20260622|wisata_kuliner_nusantara|rel_kargo_nusantara|partner|35"


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	if not bool(DataRepository.get_company_universe_validation_result().get("valid", false)):
		_fail("Company universe catalog must be valid before relationship graph fingerprint runs.")
		return

	var first_report: Dictionary = _build_fingerprint_report()
	var second_report: Dictionary = _build_fingerprint_report()
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Company relationship graph payload was not stable across repeated fixed-seed builds.")
		return
	if str(first_report.get("hash", "")) != str(second_report.get("hash", "")):
		_fail("Company relationship graph hash was not stable across repeated fixed-seed builds.")
		return
	if int(first_report.get("roster_size", 0)) != EXPECTED_ROSTER_SIZE:
		_fail("Expected %d selected companies, got %d." % [EXPECTED_ROSTER_SIZE, int(first_report.get("roster_size", 0))])
		return
	if int(first_report.get("edge_count", 0)) <= 0:
		_fail("Expected relationship graph edges to be generated.")
		return
	if int(first_report.get("issue_count", 0)) != 0:
		_fail("Company relationship graph issues: %s" % JSON.stringify(first_report.get("issues", [])))
		return
	if int(first_report.get("company_with_edges_count", 0)) < EXPECTED_ROSTER_SIZE - 2:
		_fail("Expected most selected companies to have at least one relationship edge.")
		return
	if int(first_report.get("save_load_hash_mismatch", 0)) != 0:
		_fail("Company relationship graph save/load hash changed.")
		return

	if EXPECTED_FINGERPRINT_HASH != "BASELINE_PENDING":
		if str(first_report.get("hash", "")) != EXPECTED_FINGERPRINT_HASH:
			_fail("Company relationship graph fingerprint changed. expected=%s actual=%s." % [
				EXPECTED_FINGERPRINT_HASH,
				str(first_report.get("hash", ""))
			])
			return
		if EXPECTED_EDGE_COUNT >= 0 and int(first_report.get("edge_count", 0)) != EXPECTED_EDGE_COUNT:
			_fail("Company relationship graph edge count changed. expected=%d actual=%d." % [
				EXPECTED_EDGE_COUNT,
				int(first_report.get("edge_count", 0))
			])
			return
		if not EXPECTED_FIRST_EDGE_ID.is_empty() and str(first_report.get("first_edge_id", "")) != EXPECTED_FIRST_EDGE_ID:
			_fail("Company relationship graph first edge changed. expected=%s actual=%s." % [
				EXPECTED_FIRST_EDGE_ID,
				str(first_report.get("first_edge_id", ""))
			])
			return
		if not EXPECTED_LAST_EDGE_ID.is_empty() and str(first_report.get("last_edge_id", "")) != EXPECTED_LAST_EDGE_ID:
			_fail("Company relationship graph last edge changed. expected=%s actual=%s." % [
				EXPECTED_LAST_EDGE_ID,
				str(first_report.get("last_edge_id", ""))
			])
			return

	first_report.erase("payload")
	print("COMPANY_RELATIONSHIP_GRAPH_FINGERPRINT_OK %s" % JSON.stringify(first_report))
	get_tree().quit(0)


func _build_fingerprint_report() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = EXPECTED_ROSTER_SIZE
	difficulty_config["use_company_universe_catalog"] = true
	var roster: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, roster, difficulty_config, false)
	var state: Dictionary = RunState.get_company_relationship_graph_state()
	var report: Dictionary = _state_report(state, RunState.company_order)
	var save_dict: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(save_dict)
	var loaded_state: Dictionary = RunState.get_company_relationship_graph_state()
	var loaded_report: Dictionary = _state_report(loaded_state, RunState.company_order)
	report["save_load_hash_mismatch"] = 0 if str(report.get("hash", "")) == str(loaded_report.get("hash", "")) else 1
	report["save_load_edge_count"] = int(loaded_report.get("edge_count", 0))
	return report


func _state_report(state: Dictionary, selected_company_ids: Array) -> Dictionary:
	var edge_ids: Array = _string_array(state.get("edge_ids", []))
	var edge_index: Dictionary = state.get("edge_index", {}) if typeof(state.get("edge_index", {})) == TYPE_DICTIONARY else {}
	var selected_lookup: Dictionary = _lookup(selected_company_ids)
	var issues: Array[String] = []
	var payload_lines: Array[String] = []
	var seen_canonical: Dictionary = {}
	var company_with_edges: Dictionary = {}
	var max_incident_edges: int = 0
	var public_edge_count: int = 0
	var private_edge_count: int = 0

	if not bool(state.get("generated", false)):
		issues.append("state_not_generated")
	if int(state.get("schema_version", 0)) != COMPANY_RELATIONSHIP_GRAPH_SYSTEM.SCHEMA_VERSION:
		issues.append("bad_schema_version")
	if not _string_array(state.get("validation_issues", [])).is_empty():
		issues.append("state_validation_issues:%s" % _array_payload(_string_array(state.get("validation_issues", []))))

	for edge_id_value in edge_ids:
		var edge_id: String = str(edge_id_value)
		var edge: Dictionary = edge_index.get(edge_id, {})
		if edge.is_empty():
			issues.append("missing_edge_index:%s" % edge_id)
			continue
		_validate_edge(edge, selected_lookup, seen_canonical, issues)
		company_with_edges[str(edge.get("source_company_id", ""))] = true
		company_with_edges[str(edge.get("target_company_id", ""))] = true
		if str(edge.get("visibility", "")) == "public":
			public_edge_count += 1
		if str(edge.get("visibility", "")) == "private":
			private_edge_count += 1
		payload_lines.append(_edge_payload(edge))

	var company_edge_ids: Dictionary = state.get("company_edge_ids", {}) if typeof(state.get("company_edge_ids", {})) == TYPE_DICTIONARY else {}
	for company_id_value in selected_company_ids:
		var company_id: String = str(company_id_value)
		var bucket: Dictionary = company_edge_ids.get(company_id, {}) if typeof(company_edge_ids.get(company_id, {})) == TYPE_DICTIONARY else {}
		var all_edges: Array = _string_array(bucket.get("all", []))
		max_incident_edges = max(max_incident_edges, all_edges.size())
		if not all_edges.is_empty():
			payload_lines.append("company_edges|%s|%s" % [company_id, _array_payload(all_edges)])
		var accessor_edges: Array = RunState.get_company_relationship_edges_for_company(company_id)
		if accessor_edges.size() != all_edges.size():
			issues.append("accessor_edge_count_mismatch:%s:%d:%d" % [company_id, accessor_edges.size(), all_edges.size()])

	payload_lines.sort()
	var payload: String = "\n".join(payload_lines)
	var first_edge_id: String = str(edge_ids[0]) if not edge_ids.is_empty() else ""
	var last_edge_id: String = str(edge_ids[edge_ids.size() - 1]) if not edge_ids.is_empty() else ""
	return {
		"seed": RUN_SEED,
		"roster_size": selected_company_ids.size(),
		"edge_count": edge_ids.size(),
		"company_with_edges_count": company_with_edges.size(),
		"max_incident_edges": max_incident_edges,
		"public_edge_count": public_edge_count,
		"private_edge_count": private_edge_count,
		"unresolved_hook_count": int(state.get("unresolved_hook_count", 0)),
		"counts_by_type": _sorted_int_dictionary(state.get("counts_by_type", {})),
		"counts_by_visibility": _sorted_int_dictionary(state.get("counts_by_visibility", {})),
		"counts_by_origin": _sorted_int_dictionary(state.get("counts_by_origin", {})),
		"first_edge_id": first_edge_id,
		"last_edge_id": last_edge_id,
		"issue_count": issues.size(),
		"issues": issues,
		"hash": _stable_hash(payload),
		"payload": payload
	}


func _validate_edge(edge: Dictionary, selected_lookup: Dictionary, seen_canonical: Dictionary, issues: Array[String]) -> void:
	var edge_id: String = str(edge.get("edge_id", ""))
	var source_company_id: String = str(edge.get("source_company_id", ""))
	var target_company_id: String = str(edge.get("target_company_id", ""))
	var relationship_type: String = str(edge.get("relationship_type", ""))
	if source_company_id.is_empty() or target_company_id.is_empty():
		issues.append("missing_endpoint:%s" % edge_id)
	if source_company_id == target_company_id:
		issues.append("self_edge:%s" % edge_id)
	if not selected_lookup.has(source_company_id):
		issues.append("source_not_selected:%s:%s" % [edge_id, source_company_id])
	if not selected_lookup.has(target_company_id):
		issues.append("target_not_selected:%s:%s" % [edge_id, target_company_id])
	if not (relationship_type in COMPANY_RELATIONSHIP_GRAPH_SYSTEM.TASK2_GENERATED_TYPES):
		issues.append("unexpected_task2_type:%s:%s" % [edge_id, relationship_type])
	if str(edge.get("counterpart_type", "")) != str(COMPANY_RELATIONSHIP_GRAPH_SYSTEM.COUNTERPART_BY_TYPE.get(relationship_type, "")):
		issues.append("bad_counterpart:%s" % edge_id)
	if float(edge.get("strength", -1.0)) < 0.0 or float(edge.get("strength", -1.0)) > 1.0:
		issues.append("bad_strength:%s" % edge_id)
	if float(edge.get("confidence", -1.0)) < 0.0 or float(edge.get("confidence", -1.0)) > 1.0:
		issues.append("bad_confidence:%s" % edge_id)
	if float(edge.get("sector_fit_score", -1.0)) < 0.0 or float(edge.get("sector_fit_score", -1.0)) > 1.0:
		issues.append("bad_sector_fit:%s" % edge_id)
	var canonical_key: String = COMPANY_RELATIONSHIP_GRAPH_SYSTEM.canonical_edge_key(edge)
	if seen_canonical.has(canonical_key):
		issues.append("duplicate_canonical:%s" % canonical_key)
	seen_canonical[canonical_key] = true


func _edge_payload(edge: Dictionary) -> String:
	return "edge|%s|%s>%s|%s|%s|%s|%s|s=%s|c=%s|fit=%s|hook=%d" % [
		str(edge.get("edge_id", "")),
		str(edge.get("source_company_id", "")),
		str(edge.get("target_company_id", "")),
		str(edge.get("relationship_type", "")),
		str(edge.get("counterpart_type", "")),
		str(edge.get("origin", "")),
		str(edge.get("visibility", "")),
		_float_token(float(edge.get("strength", 0.0))),
		_float_token(float(edge.get("confidence", 0.0))),
		_float_token(float(edge.get("sector_fit_score", 0.0))),
		int(edge.get("source_hook_index", -1))
	]


func _lookup(values: Array) -> Dictionary:
	var result: Dictionary = {}
	for value in values:
		var item: String = str(value).strip_edges()
		if item.is_empty():
			continue
		result[item] = true
	return result


func _string_array(source_value: Variant) -> Array:
	var source_array: Array = source_value if typeof(source_value) == TYPE_ARRAY else [source_value]
	var result: Array = []
	var seen: Dictionary = {}
	for item_value in source_array:
		var item: String = str(item_value).strip_edges()
		if item.is_empty() or seen.has(item):
			continue
		seen[item] = true
		result.append(item)
	result.sort()
	return result


func _sorted_int_dictionary(source_value: Variant) -> Dictionary:
	var source: Dictionary = source_value if typeof(source_value) == TYPE_DICTIONARY else {}
	var result: Dictionary = {}
	var keys: Array = source.keys()
	keys.sort()
	for key_value in keys:
		result[str(key_value)] = int(source.get(key_value, 0))
	return result


func _array_payload(values: Array) -> String:
	var rows: Array = []
	for value in values:
		rows.append(str(value))
	rows.sort()
	return ",".join(rows)


func _float_token(value: float) -> String:
	return "%.3f" % snappedf(value, 0.001)


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int((hash_value ^ text.unicode_at(index)) * 16777619) & 0xFFFFFFFF
	return str(hash_value)


func _fail(message: String) -> void:
	push_error(message)
	print("COMPANY_RELATIONSHIP_GRAPH_FINGERPRINT_FAIL %s" % message)
	get_tree().quit(1)
