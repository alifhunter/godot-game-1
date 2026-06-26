extends Node

const COMPANY_STORY_DOSSIER_SYSTEM = preload("res://systems/CompanyStoryDossierSystem.gd")
const MACRO_STATE_SYSTEM = preload("res://systems/MacroStateSystem.gd")

const RUN_SEED := 20260615
const START_YEAR := 2020
const EXPECTED_DOSSIER_COUNT := 30
const EXPECTED_FINGERPRINT_HASH := "1867741019"
const EXPECTED_FIRST_STORY_ID := "story|pulp_nusantara|commodity_tailwind|2532662389"
const EXPECTED_LAST_STORY_ID := "story|bank_syariah_harmoni|commodity_headwind|2473540029"
const VALID_TRUTH_STATES := ["real", "delayed", "failed", "overhyped", "fraud_risk", "uncertain"]
const VALID_PUBLIC_STATUSES := ["silent", "rumor", "reported", "confirmed", "questioned", "disputed", "resolved"]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	if not bool(DataRepository.get_company_universe_validation_result().get("valid", false)):
		_fail("Company universe catalog must be valid before dossier fingerprint runs.")
		return

	var first_report: Dictionary = _build_fingerprint_report()
	var second_report: Dictionary = _build_fingerprint_report()
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Company story dossier payload was not stable across repeated fixed-seed builds.")
		return
	if str(first_report.get("hash", "")) != str(second_report.get("hash", "")):
		_fail("Company story dossier hash was not stable across repeated fixed-seed builds.")
		return
	if int(first_report.get("dossier_count", 0)) != EXPECTED_DOSSIER_COUNT:
		_fail("Expected %d generated dossiers, got %d." % [
			EXPECTED_DOSSIER_COUNT,
			int(first_report.get("dossier_count", 0))
		])
		return
	if int(first_report.get("duplicate_story_id_count", 0)) != 0:
		_fail("Expected zero duplicate story ids, got %d." % int(first_report.get("duplicate_story_id_count", 0)))
		return
	if int(first_report.get("invalid_dossier_count", 0)) != 0:
		_fail("Expected zero invalid dossiers, got %d." % int(first_report.get("invalid_dossier_count", 0)))
		return

	if EXPECTED_FINGERPRINT_HASH != "BASELINE_PENDING":
		if str(first_report.get("hash", "")) != EXPECTED_FINGERPRINT_HASH:
			_fail("Company story dossier fingerprint changed. expected=%s actual=%s." % [
				EXPECTED_FINGERPRINT_HASH,
				str(first_report.get("hash", ""))
			])
			return
		if str(first_report.get("first_story_id", "")) != EXPECTED_FIRST_STORY_ID:
			_fail("Company story dossier first story changed. expected=%s actual=%s." % [
				EXPECTED_FIRST_STORY_ID,
				str(first_report.get("first_story_id", ""))
			])
			return
		if str(first_report.get("last_story_id", "")) != EXPECTED_LAST_STORY_ID:
			_fail("Company story dossier last story changed. expected=%s actual=%s." % [
				EXPECTED_LAST_STORY_ID,
				str(first_report.get("last_story_id", ""))
			])
			return

	first_report.erase("payload")
	print("COMPANY_STORY_DOSSIER_FINGERPRINT_OK %s" % JSON.stringify(first_report))
	get_tree().quit(0)


func _build_fingerprint_report() -> Dictionary:
	var roster: Array = _build_roster()
	var macro_state: Dictionary = _build_macro_state()
	var system = COMPANY_STORY_DOSSIER_SYSTEM.new()
	var dossiers: Array = system.generate_dossiers(
		RUN_SEED,
		roster,
		macro_state,
		{"max_dossiers": EXPECTED_DOSSIER_COUNT, "dossiers_per_company": 1}
	)

	var payload_lines: Array[String] = []
	var archetype_counts: Dictionary = {}
	var truth_counts: Dictionary = {}
	var stage_counts: Dictionary = {}
	var surface_counts: Dictionary = {}
	var seen_story_ids: Dictionary = {}
	var duplicate_story_ids: Array[String] = []
	var invalid_dossiers: Array[String] = []

	for dossier_value in dossiers:
		if typeof(dossier_value) != TYPE_DICTIONARY:
			invalid_dossiers.append("non_dictionary")
			continue
		var dossier: Dictionary = dossier_value
		var story_id: String = str(dossier.get("story_id", ""))
		if seen_story_ids.has(story_id):
			duplicate_story_ids.append(story_id)
		seen_story_ids[story_id] = true
		var validation_issue: String = _validation_issue(dossier)
		if not validation_issue.is_empty():
			invalid_dossiers.append("%s:%s" % [story_id, validation_issue])
		_increment(archetype_counts, str(dossier.get("archetype_id", "")))
		_increment(truth_counts, str(dossier.get("truth_state", "")))
		_increment(stage_counts, str(dossier.get("stage_id", "")))
		for surface_id in _surface_ids(dossier):
			_increment(surface_counts, str(surface_id))
		payload_lines.append(_dossier_payload(dossier))

	var payload: String = "\n--dossier--\n".join(payload_lines)
	var first_dossier: Dictionary = dossiers[0] if not dossiers.is_empty() and typeof(dossiers[0]) == TYPE_DICTIONARY else {}
	var last_dossier: Dictionary = dossiers[dossiers.size() - 1] if not dossiers.is_empty() and typeof(dossiers[dossiers.size() - 1]) == TYPE_DICTIONARY else {}
	return {
		"seed": RUN_SEED,
		"start_year": START_YEAR,
		"dossier_count": dossiers.size(),
		"hash": _stable_hash(payload),
		"first_story_id": str(first_dossier.get("story_id", "")),
		"first_company_id": str(first_dossier.get("company_id", "")),
		"first_archetype_id": str(first_dossier.get("archetype_id", "")),
		"last_story_id": str(last_dossier.get("story_id", "")),
		"last_company_id": str(last_dossier.get("company_id", "")),
		"last_archetype_id": str(last_dossier.get("archetype_id", "")),
		"duplicate_story_id_count": duplicate_story_ids.size(),
		"invalid_dossier_count": invalid_dossiers.size(),
		"invalid_dossiers": invalid_dossiers,
		"archetype_counts": _sorted_int_dictionary(archetype_counts),
		"truth_counts": _sorted_int_dictionary(truth_counts),
		"stage_counts": _sorted_int_dictionary(stage_counts),
		"surface_counts": _sorted_int_dictionary(surface_counts),
		"payload": payload
	}


func _build_roster() -> Array:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = EXPECTED_DOSSIER_COUNT
	difficulty_config["use_company_universe_catalog"] = true
	return GameManager.build_company_roster(RUN_SEED, difficulty_config)


func _build_macro_state() -> Dictionary:
	var system = MACRO_STATE_SYSTEM.new()
	return system.build_year_state(
		RUN_SEED,
		START_YEAR,
		DataRepository.get_sector_definitions(),
		{},
		DataRepository.get_commodity_indicator_catalog()
	)


func _validation_issue(dossier: Dictionary) -> String:
	if int(dossier.get("schema_version", 0)) != 1:
		return "bad_schema"
	if str(dossier.get("story_id", "")).strip_edges().is_empty():
		return "missing_story_id"
	if str(dossier.get("company_id", "")).strip_edges().is_empty():
		return "missing_company_id"
	if not (str(dossier.get("truth_state", "")) in VALID_TRUTH_STATES):
		return "bad_truth_state"
	if not (str(dossier.get("public_status", "")) in VALID_PUBLIC_STATUSES):
		return "bad_public_status"
	if _array_size(dossier.get("cause_facts", [])) <= 0:
		return "missing_cause_facts"
	if _array_size(dossier.get("timeline", [])) <= 0:
		return "missing_timeline"
	if _array_size(dossier.get("financial_effects", [])) <= 0:
		return "missing_financial_effects"
	if _array_size(dossier.get("public_clues", [])) <= 0:
		return "missing_public_clues"
	if _array_size(dossier.get("private_clues", [])) <= 0:
		return "missing_private_clues"
	if _array_size(dossier.get("statement_clues", [])) <= 0:
		return "missing_statement_clues"
	if _array_size(dossier.get("resolution_conditions", [])) <= 0:
		return "missing_resolution_conditions"
	if typeof(dossier.get("price_effects", {})) != TYPE_DICTIONARY:
		return "missing_price_effects"
	var price_effects: Dictionary = dossier.get("price_effects", {})
	if absf(float(price_effects.get("drift_bps", 0.0))) > 18.0:
		return "price_drift_out_of_bounds"
	if float(price_effects.get("volatility_multiplier", 1.0)) < 0.96 or float(price_effects.get("volatility_multiplier", 1.0)) > 1.14:
		return "price_volatility_out_of_bounds"
	if float(price_effects.get("volume_multiplier", 1.0)) < 0.96 or float(price_effects.get("volume_multiplier", 1.0)) > 1.20:
		return "price_volume_out_of_bounds"
	var traceability: Dictionary = dossier.get("traceability", {})
	if _array_size(traceability.get("source_fact_ids", [])) <= 0:
		return "missing_traceability_facts"
	return ""


func _dossier_payload(dossier: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("story_id=%s" % str(dossier.get("story_id", "")))
	lines.append("company_id=%s" % str(dossier.get("company_id", "")))
	lines.append("ticker=%s" % str(dossier.get("ticker", "")))
	lines.append("archetype_id=%s" % str(dossier.get("archetype_id", "")))
	lines.append("story_family=%s" % str(dossier.get("story_family", "")))
	lines.append("hook_id=%s" % str(dossier.get("hook_id", "")))
	lines.append("truth_state=%s" % str(dossier.get("truth_state", "")))
	lines.append("public_status=%s" % str(dossier.get("public_status", "")))
	lines.append("stage_id=%s" % str(dossier.get("stage_id", "")))
	lines.append("priority=%s" % _float_token(float(dossier.get("priority", 0.0))))
	lines.append("confidence=%s" % _float_token(float(dossier.get("confidence", 0.0))))
	lines.append("started=%d" % int(dossier.get("started_day_index", -1)))
	lines.append("expected_resolution=%d" % int(dossier.get("expected_resolution_day_index", -1)))
	lines.append("facts=%s" % _facts_payload(dossier.get("cause_facts", [])))
	lines.append("effects=%s" % _effects_payload(dossier.get("financial_effects", [])))
	lines.append("price=%s" % _price_payload(dossier.get("price_effects", {})))
	lines.append("public_clues=%s" % _clues_payload(dossier.get("public_clues", [])))
	lines.append("private_clues=%s" % _clues_payload(dossier.get("private_clues", [])))
	lines.append("statement_clues=%s" % _clues_payload(dossier.get("statement_clues", [])))
	lines.append("conditions=%s" % _conditions_payload(dossier.get("resolution_conditions", [])))
	lines.append("traceability=%s" % _traceability_payload(dossier.get("traceability", {})))
	return "\n".join(lines)


func _facts_payload(source_value: Variant) -> String:
	if typeof(source_value) != TYPE_ARRAY:
		return ""
	var rows: Array = source_value.duplicate(true)
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return str(left.get("fact_id", "")) < str(right.get("fact_id", ""))
	)
	var parts: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		parts.append("%s|%s|%s|%s|%s" % [
			str(row.get("fact_id", "")),
			str(row.get("fact_type", "")),
			str(row.get("source_id", "")),
			str(row.get("direction", "")),
			_float_token(float(row.get("strength", 0.0)))
		])
	return ";;".join(parts)


func _effects_payload(source_value: Variant) -> String:
	if typeof(source_value) != TYPE_ARRAY:
		return ""
	var rows: Array = source_value.duplicate(true)
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return str(left.get("effect_id", "")) < str(right.get("effect_id", ""))
	)
	var parts: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		parts.append("%s|%s|%s|%s|%s|%s" % [
			str(row.get("effect_id", "")),
			str(row.get("metric_id", "")),
			str(row.get("statement_section", "")),
			str(row.get("direction", "")),
			str(row.get("magnitude_band", "")),
			str(row.get("note_type", ""))
		])
	return ";;".join(parts)


func _price_payload(source_value: Variant) -> String:
	if typeof(source_value) != TYPE_DICTIONARY:
		return ""
	var source: Dictionary = source_value
	return "%s|sentiment=%s|drift=%s|vol=%s|volume=%s|duration=%d" % [
		str(source.get("price_effect_id", "")),
		_float_token(float(source.get("sentiment_bias", 0.0))),
		_float_token(float(source.get("drift_bps", 0.0))),
		_float_token(float(source.get("volatility_multiplier", 1.0))),
		_float_token(float(source.get("volume_multiplier", 1.0))),
		int(source.get("duration_days", 0))
	]


func _clues_payload(source_value: Variant) -> String:
	if typeof(source_value) != TYPE_ARRAY:
		return ""
	var rows: Array = source_value.duplicate(true)
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return str(left.get("clue_id", "")) < str(right.get("clue_id", ""))
	)
	var parts: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		parts.append("%s|%s|%s|%d|%s|%s" % [
			str(row.get("clue_id", "")),
			str(row.get("surface_id", "")),
			str(row.get("visibility", "")),
			int(row.get("earliest_day_index", 0)),
			_float_token(float(row.get("reliability", 0.0))),
			str(row.get("text_key", ""))
		])
	return ";;".join(parts)


func _conditions_payload(source_value: Variant) -> String:
	if typeof(source_value) != TYPE_ARRAY:
		return ""
	var rows: Array = source_value.duplicate(true)
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return str(left.get("condition_id", "")) < str(right.get("condition_id", ""))
	)
	var parts: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		parts.append("%s|%s|%s|%s|%s|%s" % [
			str(row.get("condition_id", "")),
			str(row.get("metric_id", "")),
			str(row.get("operator", "")),
			_float_token(float(row.get("threshold", 0.0))),
			str(row.get("success_outcome", "")),
			str(row.get("failure_outcome", ""))
		])
	return ";;".join(parts)


func _traceability_payload(source_value: Variant) -> String:
	if typeof(source_value) != TYPE_DICTIONARY:
		return ""
	var source: Dictionary = source_value
	return "hooks=%s|facts=%s|surfaces=%s|evidence=%s|price=%s|statement=%s" % [
		_array_payload(source.get("source_company_hook_ids", [])),
		_array_payload(source.get("source_fact_ids", [])),
		_array_payload(source.get("generated_surface_ids", [])),
		_array_payload(source.get("evidence_ids", [])),
		_array_payload(source.get("price_effect_ids", [])),
		_array_payload(source.get("statement_effect_ids", []))
	]


func _surface_ids(dossier: Dictionary) -> Array:
	var result: Array = []
	for key in ["public_clues", "private_clues", "statement_clues"]:
		var clues_value: Variant = dossier.get(key, [])
		if typeof(clues_value) != TYPE_ARRAY:
			continue
		for clue_value in clues_value:
			if typeof(clue_value) != TYPE_DICTIONARY:
				continue
			var clue: Dictionary = clue_value
			result.append(str(clue.get("surface_id", "")))
	return result


func _array_payload(source_value: Variant) -> String:
	if typeof(source_value) != TYPE_ARRAY:
		return ""
	var source: Array = source_value
	var parts: Array[String] = []
	for item_value in source:
		parts.append(str(item_value))
	parts.sort()
	return "|".join(parts)


func _sorted_int_dictionary(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var keys: Array = source.keys()
	keys.sort()
	for key_value in keys:
		var key: String = str(key_value)
		result[key] = int(source.get(key_value, 0))
	return result


func _increment(counts: Dictionary, key: String) -> void:
	if key.strip_edges().is_empty():
		return
	counts[key] = int(counts.get(key, 0)) + 1


func _array_size(source_value: Variant) -> int:
	if typeof(source_value) != TYPE_ARRAY:
		return 0
	return source_value.size()


func _float_token(value: float) -> String:
	return "%.4f" % value


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int((hash_value ^ text.unicode_at(index)) * 16777619)
		hash_value = hash_value % 2147483647
		if hash_value < 0:
			hash_value += 2147483647
	return str(hash_value)


func _fail(message: String) -> void:
	push_error(message)
	print("COMPANY_STORY_DOSSIER_FINGERPRINT_FAIL: %s" % message)
	get_tree().quit(1)
