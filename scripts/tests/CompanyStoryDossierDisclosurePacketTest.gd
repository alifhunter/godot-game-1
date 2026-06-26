extends Node

const RUN_SEED := 20260615
const CATALOG_COMPANY_COUNT := 30
const EXPECTED_DOSSIER_COUNT := 30
const EXPECTED_PACKET_HASH := "2005222199"

const VALID_SUBTLETY_BANDS := ["direct", "implied", "buried", "conflicting", "missing"]
const HIDDEN_PACKET_KEYS := ["truth_state", "disclosure_quality", "reliability", "confidence", "source_quality"]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_report()
	var second_report: Dictionary = _build_report()
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Company story dossier disclosure packet payload was not stable across repeated fixed-seed runs.")
		return
	if str(first_report.get("hash", "")) != str(second_report.get("hash", "")):
		_fail("Company story dossier disclosure packet hash was not stable across repeated fixed-seed runs.")
		return
	if int(first_report.get("dossier_count", 0)) != EXPECTED_DOSSIER_COUNT:
		_fail("Expected %d dossiers, got %d." % [EXPECTED_DOSSIER_COUNT, int(first_report.get("dossier_count", 0))])
		return
	if int(first_report.get("issue_count", 0)) != 0:
		_fail("Expected zero disclosure packet issues, got %d: %s" % [
			int(first_report.get("issue_count", 0)),
			JSON.stringify(first_report.get("issues", []))
		])
		return
	if int(first_report.get("packet_count", 0)) <= EXPECTED_DOSSIER_COUNT:
		_fail("Expected at least one multi-packet story, got %d packets for %d dossiers." % [
			int(first_report.get("packet_count", 0)),
			EXPECTED_DOSSIER_COUNT
		])
		return
	if int(first_report.get("multi_packet_story_count", 0)) <= 0:
		_fail("Expected at least one story with multiple disclosure packets.")
		return
	if EXPECTED_PACKET_HASH != "BASELINE_PENDING" and str(first_report.get("hash", "")) != EXPECTED_PACKET_HASH:
		_fail("Company story dossier disclosure packet fingerprint changed. expected=%s actual=%s." % [
			EXPECTED_PACKET_HASH,
			str(first_report.get("hash", ""))
		])
		return

	first_report.erase("payload")
	print("COMPANY_STORY_DOSSIER_DISCLOSURE_PACKET_OK %s" % JSON.stringify(first_report))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	_setup_fixed_seed_run()
	var state: Dictionary = RunState.get_company_story_dossier_state()
	var dossier_index: Dictionary = state.get("dossier_index", {})
	var story_ids: Array = dossier_index.keys()
	story_ids.sort()

	var issues: Array[String] = []
	var payload_lines: Array[String] = []
	var packet_role_counts: Dictionary = {}
	var phrase_count: int = 0
	var token_count: int = 0
	var packet_count: int = 0
	var multi_packet_story_count: int = 0
	var dossier_count: int = 0

	for story_id_value in story_ids:
		var story_id: String = str(story_id_value)
		if typeof(dossier_index.get(story_id)) != TYPE_DICTIONARY:
			issues.append("bad_dossier:%s" % story_id)
			continue
		var dossier: Dictionary = dossier_index.get(story_id, {})
		dossier_count += 1
		var validation: Dictionary = _validate_dossier_packets(dossier, packet_role_counts, issues)
		var dossier_packet_count: int = int(validation.get("packet_count", 0))
		packet_count += dossier_packet_count
		phrase_count += int(validation.get("phrase_count", 0))
		token_count += int(validation.get("token_count", 0))
		if dossier_packet_count > 1:
			multi_packet_story_count += 1
		payload_lines.append(str(validation.get("line", "")))

	_validate_save_load_normalization(story_ids, issues)

	var payload: String = "\n".join(payload_lines)
	return {
		"seed": RUN_SEED,
		"dossier_count": dossier_count,
		"packet_count": packet_count,
		"multi_packet_story_count": multi_packet_story_count,
		"phrase_count": phrase_count,
		"token_count": token_count,
		"hash": _stable_hash(payload),
		"issue_count": issues.size(),
		"issues": issues,
		"packet_role_counts": _sorted_int_dictionary(packet_role_counts),
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


func _validate_dossier_packets(dossier: Dictionary, packet_role_counts: Dictionary, issues: Array[String]) -> Dictionary:
	var story_id: String = str(dossier.get("story_id", ""))
	var placements: Array = _variant_array(dossier.get("disclosure_placements", []))
	var packets: Array = _variant_array(dossier.get("disclosure_packets", []))
	var placement_ids: Array = _ids_from_rows(placements, "placement_id")
	var fact_ids: Array = _ids_from_rows(dossier.get("cause_facts", []), "fact_id")
	var effect_ids: Array = _ids_from_rows(dossier.get("financial_effects", []), "effect_id")
	var metric_ids: Array = _ids_from_rows(dossier.get("financial_effects", []), "metric_id")
	var clue_ids: Array = _ids_from_rows(dossier.get("statement_clues", []), "clue_id")
	var section_ids: Array = _ids_from_rows(placements, "section_id")
	var packet_ids: Array = []
	var phrase_count: int = 0
	var token_count: int = 0
	var payload_parts: Array[String] = []

	if packets.is_empty():
		issues.append("missing_disclosure_packets:%s" % story_id)
	if packets.size() != placements.size():
		issues.append("packet_placement_count_mismatch:%s:%d:%d" % [story_id, packets.size(), placements.size()])

	for packet_value in packets:
		if typeof(packet_value) != TYPE_DICTIONARY:
			issues.append("bad_packet_row:%s" % story_id)
			continue
		var packet: Dictionary = packet_value
		var packet_id: String = str(packet.get("packet_id", ""))
		var placement_id: String = str(packet.get("placement_id", ""))
		var packet_role: String = str(packet.get("packet_role", ""))
		var subtlety: String = str(packet.get("subtlety", ""))
		packet_ids.append(packet_id)
		_increment(packet_role_counts, packet_role)
		phrase_count += _string_array(packet.get("phrase_ids", [])).size()
		token_count += _string_array(packet.get("render_tokens", [])).size()

		if packet_id.strip_edges().is_empty() or not packet_id.begins_with("packet|%s|" % story_id):
			issues.append("packet_wrong_story:%s:%s" % [story_id, packet_id])
		if str(packet.get("story_id", "")) != story_id:
			issues.append("packet_story_mismatch:%s:%s" % [story_id, packet_id])
		if not placement_ids.has(placement_id):
			issues.append("packet_orphan_placement:%s:%s:%s" % [story_id, packet_id, placement_id])
		if str(packet.get("surface_id", "")) != "annual_report":
			issues.append("packet_bad_surface:%s:%s" % [story_id, packet_id])
		if not VALID_SUBTLETY_BANDS.has(subtlety):
			issues.append("packet_bad_subtlety:%s:%s:%s" % [story_id, packet_id, subtlety])
		if packet_role.strip_edges().is_empty():
			issues.append("packet_missing_role:%s:%s" % [story_id, packet_id])
		if int(packet.get("render_priority", 0)) <= 0:
			issues.append("packet_bad_render_priority:%s:%s" % [story_id, packet_id])
		if _string_array(packet.get("phrase_ids", [])).is_empty():
			issues.append("packet_missing_phrase_ids:%s:%s" % [story_id, packet_id])
		if _string_array(packet.get("render_tokens", [])).is_empty():
			issues.append("packet_missing_render_tokens:%s:%s" % [story_id, packet_id])
		if str(packet.get("text_key", "")).strip_edges().is_empty():
			issues.append("packet_missing_text_key:%s:%s" % [story_id, packet_id])
		_validate_refs(story_id, packet_id, "fact", packet.get("fact_ids", []), fact_ids, issues)
		_validate_refs(story_id, packet_id, "effect", packet.get("effect_ids", []), effect_ids, issues)
		_validate_refs(story_id, packet_id, "clue", packet.get("clue_ids", []), clue_ids, issues)
		_validate_refs(story_id, packet_id, "metric", packet.get("metric_ids", []), metric_ids, issues)
		_validate_refs(story_id, packet_id, "cross_section", packet.get("cross_reference_section_ids", []), section_ids, issues)
		for hidden_key in HIDDEN_PACKET_KEYS:
			if packet.has(hidden_key):
				issues.append("packet_hidden_key_leak:%s:%s:%s" % [story_id, packet_id, hidden_key])

		payload_parts.append("%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
			packet_id,
			placement_id,
			str(packet.get("section_id", "")),
			subtlety,
			packet_role,
			str(packet.get("render_priority", "")),
			_array_payload(packet.get("phrase_ids", [])),
			_array_payload(packet.get("render_tokens", [])),
			_array_payload(packet.get("cross_reference_section_ids", [])),
			_array_payload(packet.get("metric_ids", []))
		])

	var traceability: Dictionary = dossier.get("traceability", {})
	if _array_payload(traceability.get("disclosure_packet_ids", [])) != _array_payload(packet_ids):
		issues.append("traceability_disclosure_packet_mismatch:%s" % story_id)

	payload_parts.sort()
	return {
		"packet_count": packets.size(),
		"phrase_count": phrase_count,
		"token_count": token_count,
		"line": "%s=%s" % [story_id, ";;".join(payload_parts)]
	}


func _validate_save_load_normalization(story_ids: Array, issues: Array[String]) -> void:
	if story_ids.is_empty():
		issues.append("save_load_no_story_ids")
		return
	var story_id: String = str(story_ids.front())
	var save_payload: Dictionary = RunState.to_save_dict()
	var state: Dictionary = save_payload.get("company_story_dossier_state", {}).duplicate(true)
	var dossier_index: Dictionary = state.get("dossier_index", {}).duplicate(true)
	var dossier: Dictionary = dossier_index.get(story_id, {}).duplicate(true)
	var packets: Array = _variant_array(dossier.get("disclosure_packets", []))
	if packets.is_empty() or typeof(packets[0]) != TYPE_DICTIONARY:
		issues.append("save_load_missing_packet:%s" % story_id)
		return
	var first_packet: Dictionary = packets[0].duplicate(true)
	first_packet["truth_state"] = "real"
	first_packet["disclosure_quality"] = "clear"
	first_packet["reliability"] = 1.0
	first_packet["confidence"] = 1.0
	first_packet["source_quality"] = "insider"
	first_packet["subtlety"] = "too_loud"
	packets[0] = first_packet
	dossier["disclosure_packets"] = packets
	dossier_index[story_id] = dossier
	state["dossier_index"] = dossier_index
	save_payload["company_story_dossier_state"] = state
	RunState.load_from_dict(save_payload)

	var loaded: Dictionary = RunState.get_company_story_dossier(story_id)
	var loaded_packets: Array = _variant_array(loaded.get("disclosure_packets", []))
	if loaded_packets.is_empty() or typeof(loaded_packets[0]) != TYPE_DICTIONARY:
		issues.append("save_load_packet_dropped:%s" % story_id)
		return
	var loaded_packet: Dictionary = loaded_packets[0]
	for hidden_key in HIDDEN_PACKET_KEYS:
		if loaded_packet.has(hidden_key):
			issues.append("save_load_hidden_packet_key_survived:%s:%s" % [story_id, hidden_key])
	if not VALID_SUBTLETY_BANDS.has(str(loaded_packet.get("subtlety", ""))):
		issues.append("save_load_invalid_packet_subtlety_survived:%s:%s" % [story_id, str(loaded_packet.get("subtlety", ""))])


func _validate_refs(story_id: String, packet_id: String, ref_kind: String, source_refs: Variant, valid_refs: Array, issues: Array[String]) -> void:
	for ref_id in _string_array(source_refs):
		if not valid_refs.has(ref_id):
			issues.append("packet_orphan_%s:%s:%s:%s" % [ref_kind, story_id, packet_id, ref_id])


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


func _string_array(source_value: Variant) -> Array:
	var result: Array = []
	for item_value in _variant_array(source_value):
		var text: String = str(item_value).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	result.sort()
	return result


func _array_payload(source_value: Variant) -> String:
	return "|".join(_string_array(source_value))


func _sorted_int_dictionary(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var keys: Array = source.keys()
	keys.sort()
	for key_value in keys:
		var key: String = str(key_value)
		result[key] = int(source.get(key_value, 0))
	return result


func _increment(counts: Dictionary, key: String) -> void:
	var normalized: String = key.strip_edges()
	if normalized.is_empty():
		return
	counts[normalized] = int(counts.get(normalized, 0)) + 1


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int(hash_value ^ text.unicode_at(index))
		hash_value = int((hash_value * 16777619) & 0x7fffffff)
	return str(hash_value)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
