extends Node

const RUN_SEED := 20260615
const CATALOG_COMPANY_COUNT := 30
const EXPECTED_DOSSIER_COUNT := 30
const EXPECTED_PERSISTENCE_HASH := "2080268323"
const HIDDEN_DISCLOSURE_KEYS := ["truth_state", "disclosure_quality", "reliability", "confidence", "source_quality"]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_report()
	var second_report: Dictionary = _build_report()
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Company story dossier disclosure persistence payload was not stable across repeated fixed-seed runs.")
		return
	if str(first_report.get("hash", "")) != str(second_report.get("hash", "")):
		_fail("Company story dossier disclosure persistence hash was not stable across repeated fixed-seed runs.")
		return
	if int(first_report.get("dossier_count", 0)) != EXPECTED_DOSSIER_COUNT:
		_fail("Expected %d dossiers, got %d." % [EXPECTED_DOSSIER_COUNT, int(first_report.get("dossier_count", 0))])
		return
	if int(first_report.get("issue_count", 0)) != 0:
		_fail("Expected zero disclosure persistence issues, got %d: %s" % [
			int(first_report.get("issue_count", 0)),
			JSON.stringify(first_report.get("issues", []))
		])
		return
	if EXPECTED_PERSISTENCE_HASH != "BASELINE_PENDING" and str(first_report.get("hash", "")) != EXPECTED_PERSISTENCE_HASH:
		_fail("Company story dossier disclosure persistence fingerprint changed. expected=%s actual=%s." % [
			EXPECTED_PERSISTENCE_HASH,
			str(first_report.get("hash", ""))
		])
		return

	first_report.erase("payload")
	print("COMPANY_STORY_DOSSIER_DISCLOSURE_PERSISTENCE_OK %s" % JSON.stringify(first_report))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	_setup_fixed_seed_run()
	var baseline_save: Dictionary = RunState.to_save_dict()
	var baseline_state: Dictionary = baseline_save.get("company_story_dossier_state", {})
	var story_ids: Array = baseline_state.get("active_story_ids", []).duplicate()
	story_ids.sort()
	if story_ids.is_empty():
		return {
			"seed": RUN_SEED,
			"dossier_count": 0,
			"placement_count": 0,
			"packet_count": 0,
			"hash": "0",
			"issue_count": 1,
			"issues": ["no_story_ids"],
			"payload": ""
		}

	var target_story_id: String = str(story_ids.front())
	var target_dossier: Dictionary = baseline_state.get("dossier_index", {}).get(target_story_id, {})
	var target_company_id: String = str(target_dossier.get("company_id", ""))
	var issues: Array[String] = []

	RunState.load_from_dict(_legacy_disclosure_save(baseline_save))
	var legacy_report: Dictionary = _validate_loaded_registry("legacy", target_story_id, target_company_id, issues)

	RunState.load_from_dict(_malformed_disclosure_save(baseline_save, target_story_id))
	var malformed_report: Dictionary = _validate_loaded_registry("malformed", target_story_id, target_company_id, issues)

	var payload: String = "%s\n%s" % [str(legacy_report.get("payload", "")), str(malformed_report.get("payload", ""))]
	return {
		"seed": RUN_SEED,
		"dossier_count": int(legacy_report.get("dossier_count", 0)),
		"placement_count": int(legacy_report.get("placement_count", 0)),
		"packet_count": int(legacy_report.get("packet_count", 0)),
		"malformed_placement_count": int(malformed_report.get("placement_count", 0)),
		"malformed_packet_count": int(malformed_report.get("packet_count", 0)),
		"hash": _stable_hash(payload),
		"issue_count": issues.size(),
		"issues": issues,
		"payload": payload
	}


func _setup_fixed_seed_run() -> void:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = CATALOG_COMPANY_COUNT
	difficulty_config["use_company_universe_catalog"] = true
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0


func _validate_loaded_registry(label: String, target_story_id: String, target_company_id: String, issues: Array[String]) -> Dictionary:
	var state: Dictionary = RunState.get_company_story_dossier_state()
	var dossier_index: Dictionary = state.get("dossier_index", {})
	var story_ids: Array = dossier_index.keys()
	story_ids.sort()
	var placement_count: int = 0
	var packet_count: int = 0
	var payload_lines: Array[String] = []

	for story_id_value in story_ids:
		var story_id: String = str(story_id_value)
		if typeof(dossier_index.get(story_id)) != TYPE_DICTIONARY:
			issues.append("%s:bad_dossier:%s" % [label, story_id])
			continue
		var dossier: Dictionary = dossier_index.get(story_id, {})
		var placements: Array = _variant_array(dossier.get("disclosure_placements", []))
		var packets: Array = _variant_array(dossier.get("disclosure_packets", []))
		var placement_ids: Array = _ids_from_rows(placements, "placement_id")
		var packet_ids: Array = _ids_from_rows(packets, "packet_id")
		var section_ids: Array = _ids_from_rows(placements, "section_id")
		placement_count += placements.size()
		packet_count += packets.size()

		if placements.is_empty():
			issues.append("%s:missing_disclosure_placements:%s" % [label, story_id])
		if packets.is_empty():
			issues.append("%s:missing_disclosure_packets:%s" % [label, story_id])
		if placements.size() != packets.size():
			issues.append("%s:placement_packet_count_mismatch:%s:%d:%d" % [label, story_id, placements.size(), packets.size()])
		_validate_hidden_keys(label, story_id, placements, packets, issues)

		var traceability: Dictionary = dossier.get("traceability", {})
		if _array_payload(traceability.get("disclosure_placement_ids", [])) != _array_payload(placement_ids):
			issues.append("%s:traceability_placement_mismatch:%s" % [label, story_id])
		if _array_payload(traceability.get("disclosure_section_ids", [])) != _array_payload(section_ids):
			issues.append("%s:traceability_section_mismatch:%s" % [label, story_id])
		if _array_payload(traceability.get("disclosure_packet_ids", [])) != _array_payload(packet_ids):
			issues.append("%s:traceability_packet_mismatch:%s" % [label, story_id])

		payload_lines.append("%s=%s=%s" % [
			story_id,
			_array_payload(placement_ids),
			_array_payload(packet_ids)
		])

	_validate_lookup_helpers(label, target_story_id, target_company_id, issues)

	return {
		"dossier_count": story_ids.size(),
		"placement_count": placement_count,
		"packet_count": packet_count,
		"payload": "%s:%s" % [label, "\n".join(payload_lines)]
	}


func _validate_lookup_helpers(label: String, story_id: String, company_id: String, issues: Array[String]) -> void:
	var story_packets: Array = RunState.get_company_story_disclosure_packets(story_id)
	var company_packets: Array = RunState.get_company_story_disclosure_packets_for_company(company_id)
	var story_placements: Array = RunState.get_company_story_disclosure_placements(story_id)
	var company_placements: Array = RunState.get_company_story_disclosure_placements_for_company(company_id)
	if story_packets.is_empty() or story_placements.is_empty():
		issues.append("%s:story_lookup_empty:%s" % [label, story_id])
	if company_packets.is_empty() or company_placements.is_empty():
		issues.append("%s:company_lookup_empty:%s" % [label, company_id])
	if story_packets.size() != story_placements.size():
		issues.append("%s:story_lookup_count_mismatch:%s:%d:%d" % [label, story_id, story_packets.size(), story_placements.size()])
	if company_packets.size() != company_placements.size():
		issues.append("%s:company_lookup_count_mismatch:%s:%d:%d" % [label, company_id, company_packets.size(), company_placements.size()])
	if story_packets.is_empty():
		return
	var section_id: String = str(story_packets[0].get("section_id", ""))
	var section_packets: Array = RunState.get_company_story_disclosure_packets_for_company(company_id, section_id)
	var section_placements: Array = RunState.get_company_story_disclosure_placements_for_company(company_id, section_id)
	if section_packets.is_empty() or section_placements.is_empty():
		issues.append("%s:section_lookup_empty:%s:%s" % [label, company_id, section_id])
	for packet_value in section_packets:
		if typeof(packet_value) != TYPE_DICTIONARY:
			issues.append("%s:section_lookup_bad_packet:%s" % [label, section_id])
			continue
		var packet: Dictionary = packet_value
		if str(packet.get("section_id", "")) != section_id:
			issues.append("%s:section_lookup_wrong_packet:%s:%s" % [label, section_id, str(packet.get("section_id", ""))])
	for placement_value in section_placements:
		if typeof(placement_value) != TYPE_DICTIONARY:
			issues.append("%s:section_lookup_bad_placement:%s" % [label, section_id])
			continue
		var placement: Dictionary = placement_value
		if str(placement.get("section_id", "")) != section_id:
			issues.append("%s:section_lookup_wrong_placement:%s:%s" % [label, section_id, str(placement.get("section_id", ""))])


func _validate_hidden_keys(label: String, story_id: String, placements: Array, packets: Array, issues: Array[String]) -> void:
	for placement_value in placements:
		if typeof(placement_value) != TYPE_DICTIONARY:
			continue
		var placement: Dictionary = placement_value
		for hidden_key in HIDDEN_DISCLOSURE_KEYS:
			if placement.has(hidden_key):
				issues.append("%s:placement_hidden_key:%s:%s" % [label, story_id, hidden_key])
	for packet_value in packets:
		if typeof(packet_value) != TYPE_DICTIONARY:
			continue
		var packet: Dictionary = packet_value
		for hidden_key in HIDDEN_DISCLOSURE_KEYS:
			if packet.has(hidden_key):
				issues.append("%s:packet_hidden_key:%s:%s" % [label, story_id, hidden_key])


func _legacy_disclosure_save(source_save: Dictionary) -> Dictionary:
	var save: Dictionary = source_save.duplicate(true)
	var state: Dictionary = save.get("company_story_dossier_state", {}).duplicate(true)
	var dossier_index: Dictionary = state.get("dossier_index", {}).duplicate(true)
	for story_id_value in dossier_index.keys():
		var story_id: String = str(story_id_value)
		var dossier: Dictionary = dossier_index.get(story_id, {}).duplicate(true)
		dossier.erase("disclosure_placements")
		dossier.erase("disclosure_packets")
		if typeof(dossier.get("traceability", {})) == TYPE_DICTIONARY:
			var traceability: Dictionary = dossier.get("traceability", {}).duplicate(true)
			traceability.erase("disclosure_placement_ids")
			traceability.erase("disclosure_section_ids")
			traceability.erase("disclosure_packet_ids")
			dossier["traceability"] = traceability
		dossier_index[story_id] = dossier
	state["dossier_index"] = dossier_index
	save["company_story_dossier_state"] = state
	return save


func _malformed_disclosure_save(source_save: Dictionary, target_story_id: String) -> Dictionary:
	var save: Dictionary = source_save.duplicate(true)
	var state: Dictionary = save.get("company_story_dossier_state", {}).duplicate(true)
	var dossier_index: Dictionary = state.get("dossier_index", {}).duplicate(true)
	var dossier: Dictionary = dossier_index.get(target_story_id, {}).duplicate(true)
	dossier["disclosure_placements"] = [
		{
			"placement_id": "",
			"section_id": "",
			"truth_state": "real",
			"reliability": 1.0
		}
	]
	dossier["disclosure_packets"] = [
		{
			"packet_id": "",
			"placement_id": "missing",
			"truth_state": "real",
			"confidence": 1.0
		}
	]
	dossier["traceability"] = {
		"seed_parts": ["stale"],
		"disclosure_placement_ids": ["stale-placement"],
		"disclosure_section_ids": ["stale-section"],
		"disclosure_packet_ids": ["stale-packet"]
	}
	dossier_index[target_story_id] = dossier
	state["dossier_index"] = dossier_index
	save["company_story_dossier_state"] = state
	return save


func _ids_from_rows(rows_value: Variant, id_key: String) -> Array:
	var result: Array = []
	for row_value in _variant_array(rows_value):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var text: String = str(row_value.get(id_key, "")).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	result.sort()
	return result


func _variant_array(source_value: Variant) -> Array:
	if typeof(source_value) == TYPE_ARRAY:
		return source_value.duplicate(true)
	return []


func _array_payload(source_value: Variant) -> String:
	return "|".join(_string_array(source_value))


func _string_array(source_value: Variant) -> Array:
	var result: Array = []
	for item_value in _variant_array(source_value):
		var text: String = str(item_value).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	result.sort()
	return result


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int(hash_value ^ text.unicode_at(index))
		hash_value = int((hash_value * 16777619) & 0x7fffffff)
	return str(hash_value)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
