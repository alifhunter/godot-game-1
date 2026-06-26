extends Node

const COMPANY_STORY_DOSSIER_SYSTEM = preload("res://systems/CompanyStoryDossierSystem.gd")

const RUN_SEED := 20260615
const CATALOG_COMPANY_COUNT := 30
const EXPECTED_DOSSIER_COUNT := 30
const EXPECTED_DISCLOSURE_HASH := "1192489532"

const VALID_SUBTLETY_BANDS := ["direct", "implied", "buried", "conflicting", "missing"]
const REQUIRED_SECTION_IDS := [
	"revenue",
	"segment_information",
	"trade_receivables",
	"inventories",
	"property_plant_and_equipment",
	"debt_and_borrowings",
	"related_party_transactions",
	"commitments_contingencies",
	"subsequent_events",
	"cash_flow_information"
]
const HIDDEN_PLACEMENT_KEYS := ["truth_state", "disclosure_quality", "reliability", "confidence", "source_quality"]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_report()
	var second_report: Dictionary = _build_report()
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Company story dossier disclosure placement payload was not stable across repeated fixed-seed runs.")
		return
	if str(first_report.get("hash", "")) != str(second_report.get("hash", "")):
		_fail("Company story dossier disclosure placement hash was not stable across repeated fixed-seed runs.")
		return
	if int(first_report.get("dossier_count", 0)) != EXPECTED_DOSSIER_COUNT:
		_fail("Expected %d dossiers, got %d." % [EXPECTED_DOSSIER_COUNT, int(first_report.get("dossier_count", 0))])
		return
	if int(first_report.get("issue_count", 0)) != 0:
		_fail("Expected zero disclosure placement issues, got %d: %s" % [
			int(first_report.get("issue_count", 0)),
			JSON.stringify(first_report.get("issues", []))
		])
		return
	for section_id in REQUIRED_SECTION_IDS:
		if int(first_report.get("section_counts", {}).get(section_id, 0)) <= 0:
			_fail("Expected section '%s' to appear in fixed-seed disclosure placements." % section_id)
			return
	for subtlety in VALID_SUBTLETY_BANDS:
		if int(first_report.get("subtlety_counts", {}).get(subtlety, 0)) <= 0:
			_fail("Expected subtlety '%s' to appear in fixed-seed disclosure placements." % subtlety)
			return
	var truth_subtlety_counts: Dictionary = first_report.get("truth_subtlety_counts", {})
	if int(truth_subtlety_counts.get("real:direct", 0)) + int(truth_subtlety_counts.get("real:implied", 0)) <= 0:
		_fail("Expected real stories to produce direct or implied filing placements.")
		return
	for risky_truth_state in ["failed", "overhyped", "fraud_risk"]:
		if int(truth_subtlety_counts.get("%s:conflicting" % risky_truth_state, 0)) + int(truth_subtlety_counts.get("%s:missing" % risky_truth_state, 0)) <= 0:
			_fail("Expected %s stories to produce conflicting or missing filing placements." % risky_truth_state)
			return
	if EXPECTED_DISCLOSURE_HASH != "BASELINE_PENDING" and str(first_report.get("hash", "")) != EXPECTED_DISCLOSURE_HASH:
		_fail("Company story dossier disclosure placement fingerprint changed. expected=%s actual=%s." % [
			EXPECTED_DISCLOSURE_HASH,
			str(first_report.get("hash", ""))
		])
		return

	first_report.erase("payload")
	print("COMPANY_STORY_DOSSIER_DISCLOSURE_PLACEMENT_OK %s" % JSON.stringify(first_report))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	_setup_fixed_seed_run()
	var system = COMPANY_STORY_DOSSIER_SYSTEM.new()
	var section_definitions: Dictionary = system.disclosure_section_definitions()
	var state: Dictionary = RunState.get_company_story_dossier_state()
	var dossier_index: Dictionary = state.get("dossier_index", {})
	var story_ids: Array = dossier_index.keys()
	story_ids.sort()

	var issues: Array[String] = []
	var payload_lines: Array[String] = []
	var section_counts: Dictionary = {}
	var role_counts: Dictionary = {}
	var subtlety_counts: Dictionary = {}
	var strategy_counts: Dictionary = {}
	var truth_subtlety_counts: Dictionary = {}
	var placement_count: int = 0
	var dossier_count: int = 0

	for story_id_value in story_ids:
		var story_id: String = str(story_id_value)
		if typeof(dossier_index.get(story_id)) != TYPE_DICTIONARY:
			issues.append("bad_dossier:%s" % story_id)
			continue
		var dossier: Dictionary = dossier_index.get(story_id, {})
		dossier_count += 1
		var validation: Dictionary = _validate_dossier_placements(dossier, section_definitions, section_counts, role_counts, subtlety_counts, strategy_counts, truth_subtlety_counts, issues)
		placement_count += int(validation.get("placement_count", 0))
		payload_lines.append(str(validation.get("line", "")))

	_validate_save_load_normalization(story_ids, issues)

	var payload: String = "\n".join(payload_lines)
	return {
		"seed": RUN_SEED,
		"dossier_count": dossier_count,
		"placement_count": placement_count,
		"hash": _stable_hash(payload),
		"issue_count": issues.size(),
		"issues": issues,
		"section_counts": _sorted_int_dictionary(section_counts),
		"role_counts": _sorted_int_dictionary(role_counts),
		"subtlety_counts": _sorted_int_dictionary(subtlety_counts),
		"strategy_counts": _sorted_int_dictionary(strategy_counts),
		"truth_subtlety_counts": _sorted_int_dictionary(truth_subtlety_counts),
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


func _validate_dossier_placements(dossier: Dictionary, section_definitions: Dictionary, section_counts: Dictionary, role_counts: Dictionary, subtlety_counts: Dictionary, strategy_counts: Dictionary, truth_subtlety_counts: Dictionary, issues: Array[String]) -> Dictionary:
	var story_id: String = str(dossier.get("story_id", ""))
	var truth_state: String = str(dossier.get("truth_state", ""))
	var fact_ids: Array = _ids_from_rows(dossier.get("cause_facts", []), "fact_id")
	var effect_ids: Array = _ids_from_rows(dossier.get("financial_effects", []), "effect_id")
	var metric_ids: Array = _ids_from_rows(dossier.get("financial_effects", []), "metric_id")
	var clue_ids: Array = _ids_from_rows(dossier.get("statement_clues", []), "clue_id")
	var placements: Array = _variant_array(dossier.get("disclosure_placements", []))
	var placement_ids: Array = []
	var section_ids: Array = []
	var payload_parts: Array[String] = []

	if placements.is_empty():
		issues.append("missing_disclosure_placements:%s" % story_id)

	for placement_value in placements:
		if typeof(placement_value) != TYPE_DICTIONARY:
			issues.append("bad_placement_row:%s" % story_id)
			continue
		var placement: Dictionary = placement_value
		var placement_id: String = str(placement.get("placement_id", ""))
		var section_id: String = str(placement.get("section_id", ""))
		var placement_role: String = str(placement.get("placement_role", ""))
		var subtlety: String = str(placement.get("subtlety", ""))
		var scattering_strategy: String = str(placement.get("scattering_strategy", ""))
		placement_ids.append(placement_id)
		section_ids.append(section_id)
		_increment(section_counts, section_id)
		_increment(role_counts, placement_role)
		_increment(subtlety_counts, subtlety)
		_increment(strategy_counts, scattering_strategy)
		_increment(truth_subtlety_counts, "%s:%s" % [truth_state, subtlety])

		if placement_id.strip_edges().is_empty() or not placement_id.begins_with("placement|%s|" % story_id):
			issues.append("placement_wrong_story:%s:%s" % [story_id, placement_id])
		if str(placement.get("story_id", "")) != story_id:
			issues.append("placement_story_mismatch:%s:%s" % [story_id, placement_id])
		if str(placement.get("surface_id", "")) != "annual_report":
			issues.append("placement_bad_surface:%s:%s" % [story_id, placement_id])
		if str(placement.get("visibility", "")) != "filing":
			issues.append("placement_bad_visibility:%s:%s" % [story_id, placement_id])
		if not VALID_SUBTLETY_BANDS.has(subtlety):
			issues.append("placement_bad_subtlety:%s:%s:%s" % [story_id, placement_id, subtlety])
		if scattering_strategy.strip_edges().is_empty():
			issues.append("placement_missing_strategy:%s:%s" % [story_id, placement_id])
		if int(placement.get("scattering_total", 0)) != placements.size():
			issues.append("placement_scattering_total_mismatch:%s:%s" % [story_id, placement_id])
		if int(placement.get("scattering_index", -1)) < 0 or int(placement.get("scattering_index", -1)) >= placements.size():
			issues.append("placement_scattering_index_out_of_bounds:%s:%s" % [story_id, placement_id])
		if str(placement.get("reader_effort", "")).strip_edges().is_empty() or str(placement.get("evidence_density", "")).strip_edges().is_empty() or str(placement.get("fragment_role", "")).strip_edges().is_empty():
			issues.append("placement_missing_scattering_metadata:%s:%s" % [story_id, placement_id])
		if not section_definitions.has(section_id):
			issues.append("placement_unknown_section:%s:%s:%s" % [story_id, placement_id, section_id])
		if str(placement.get("section_label", "")).strip_edges().is_empty() or str(placement.get("section_group", "")).strip_edges().is_empty():
			issues.append("placement_missing_section_metadata:%s:%s" % [story_id, placement_id])
		if str(placement.get("annual_statement_note_type", "")).strip_edges().is_empty():
			issues.append("placement_missing_statement_note_type:%s:%s" % [story_id, placement_id])
		if _string_array(placement.get("fact_ids", [])).is_empty():
			issues.append("placement_missing_facts:%s:%s" % [story_id, placement_id])
		if _string_array(placement.get("effect_ids", [])).is_empty():
			issues.append("placement_missing_effects:%s:%s" % [story_id, placement_id])
		if _string_array(placement.get("clue_ids", [])).is_empty():
			issues.append("placement_missing_clues:%s:%s" % [story_id, placement_id])
		if _string_array(placement.get("metric_ids", [])).is_empty():
			issues.append("placement_missing_metrics:%s:%s" % [story_id, placement_id])
		_validate_refs(story_id, placement_id, "fact", placement.get("fact_ids", []), fact_ids, issues)
		_validate_refs(story_id, placement_id, "effect", placement.get("effect_ids", []), effect_ids, issues)
		_validate_refs(story_id, placement_id, "clue", placement.get("clue_ids", []), clue_ids, issues)
		_validate_refs(story_id, placement_id, "metric", placement.get("metric_ids", []), metric_ids, issues)
		_validate_refs(story_id, placement_id, "source_metric", placement.get("source_metric_ids", []), metric_ids, issues)
		for hidden_key in HIDDEN_PLACEMENT_KEYS:
			if placement.has(hidden_key):
				issues.append("placement_hidden_key_leak:%s:%s:%s" % [story_id, placement_id, hidden_key])

		payload_parts.append("%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
			placement_id,
			section_id,
			placement_role,
			subtlety,
			scattering_strategy,
			str(placement.get("scattering_index", "")),
			str(placement.get("scattering_total", "")),
			str(placement.get("note_type", "")),
			_array_payload(placement.get("fact_ids", [])),
			_array_payload(placement.get("effect_ids", [])),
			_array_payload(placement.get("clue_ids", [])),
			_array_payload(placement.get("metric_ids", []))
		])

	var traceability: Dictionary = dossier.get("traceability", {})
	if _array_payload(traceability.get("disclosure_placement_ids", [])) != _array_payload(placement_ids):
		issues.append("traceability_disclosure_placement_mismatch:%s" % story_id)
	if _array_payload(traceability.get("disclosure_section_ids", [])) != _array_payload(section_ids):
		issues.append("traceability_disclosure_section_mismatch:%s" % story_id)

	payload_parts.sort()
	return {
		"placement_count": placements.size(),
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
	var placements: Array = _variant_array(dossier.get("disclosure_placements", []))
	if placements.is_empty() or typeof(placements[0]) != TYPE_DICTIONARY:
		issues.append("save_load_missing_placement:%s" % story_id)
		return
	var first_placement: Dictionary = placements[0].duplicate(true)
	first_placement["truth_state"] = "real"
	first_placement["disclosure_quality"] = "clear"
	first_placement["reliability"] = 1.0
	first_placement["confidence"] = 1.0
	first_placement["source_quality"] = "insider"
	first_placement["subtlety"] = "too_loud"
	placements[0] = first_placement
	dossier["disclosure_placements"] = placements
	dossier_index[story_id] = dossier
	state["dossier_index"] = dossier_index
	save_payload["company_story_dossier_state"] = state
	RunState.load_from_dict(save_payload)

	var loaded: Dictionary = RunState.get_company_story_dossier(story_id)
	var loaded_placements: Array = _variant_array(loaded.get("disclosure_placements", []))
	if loaded_placements.is_empty() or typeof(loaded_placements[0]) != TYPE_DICTIONARY:
		issues.append("save_load_placement_dropped:%s" % story_id)
		return
	var loaded_placement: Dictionary = loaded_placements[0]
	for hidden_key in HIDDEN_PLACEMENT_KEYS:
		if loaded_placement.has(hidden_key):
			issues.append("save_load_hidden_key_survived:%s:%s" % [story_id, hidden_key])
	if not VALID_SUBTLETY_BANDS.has(str(loaded_placement.get("subtlety", ""))):
		issues.append("save_load_invalid_subtlety_survived:%s:%s" % [story_id, str(loaded_placement.get("subtlety", ""))])


func _validate_refs(story_id: String, placement_id: String, ref_kind: String, source_refs: Variant, valid_refs: Array, issues: Array[String]) -> void:
	for ref_id in _string_array(source_refs):
		if not valid_refs.has(ref_id):
			issues.append("placement_orphan_%s:%s:%s:%s" % [ref_kind, story_id, placement_id, ref_id])


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
