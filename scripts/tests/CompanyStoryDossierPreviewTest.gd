extends Node

const COMPANY_STORY_DOSSIER_SYSTEM = preload("res://systems/CompanyStoryDossierSystem.gd")

const RUN_SEED := 20260615
const CATALOG_COMPANY_COUNT := 30
const EXPECTED_PREVIEW_COUNT := 30
const EXPECTED_PREVIEW_HASH := "1727264953"
const FORBIDDEN_TRUTH_TOKENS := ["fraud_risk", "overhyped", "uncertain"]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_preview_report()
	var second_report: Dictionary = _build_preview_report()
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Company story dossier preview payload was not stable across repeated fixed-seed runs.")
		return
	if str(first_report.get("hash", "")) != str(second_report.get("hash", "")):
		_fail("Company story dossier preview hash was not stable across repeated fixed-seed runs.")
		return
	if int(first_report.get("preview_count", 0)) != EXPECTED_PREVIEW_COUNT:
		_fail("Expected %d news previews, got %d." % [
			EXPECTED_PREVIEW_COUNT,
			int(first_report.get("preview_count", 0))
		])
		return
	if int(first_report.get("summary_preview_count", 0)) != 5:
		_fail("Expected 5 limited summary previews, got %d." % int(first_report.get("summary_preview_count", 0)))
		return
	if int(first_report.get("issue_count", 0)) != 0:
		_fail("Expected zero preview validation issues, got %d: %s" % [
			int(first_report.get("issue_count", 0)),
			JSON.stringify(first_report.get("issues", []))
		])
		return
	if EXPECTED_PREVIEW_HASH != "BASELINE_PENDING" and str(first_report.get("hash", "")) != EXPECTED_PREVIEW_HASH:
		_fail("Company story dossier preview fingerprint changed. expected=%s actual=%s." % [
			EXPECTED_PREVIEW_HASH,
			str(first_report.get("hash", ""))
		])
		return

	first_report.erase("payload")
	print("COMPANY_STORY_DOSSIER_PREVIEW_OK %s" % JSON.stringify(first_report))
	get_tree().quit(0)


func _build_preview_report() -> Dictionary:
	_setup_fixed_seed_run()
	var state: Dictionary = RunState.get_company_story_dossier_state()
	var dossier_index: Dictionary = state.get("dossier_index", {})
	var story_ids: Array = _string_array(dossier_index.keys())
	var dossiers: Array = []
	for story_id_value in story_ids:
		var story_id: String = str(story_id_value)
		if typeof(dossier_index.get(story_id)) == TYPE_DICTIONARY:
			dossiers.append(dossier_index.get(story_id, {}))

	var system = COMPANY_STORY_DOSSIER_SYSTEM.new()
	var news_previews: Array = system.build_preview_rows(dossiers, "news", {"limit": EXPECTED_PREVIEW_COUNT})
	var summary_previews: Array = system.build_preview_rows(dossiers, "summary", {"limit": 5})
	var issues: Array[String] = []
	var payload_lines: Array[String] = []
	var surface_counts: Dictionary = {}

	for preview_value in news_previews:
		if typeof(preview_value) != TYPE_DICTIONARY:
			issues.append("bad_preview_row")
			continue
		var preview: Dictionary = preview_value
		_validate_preview(preview, dossier_index, issues)
		_increment(surface_counts, str(preview.get("surface_id", "")))
		payload_lines.append(_preview_payload(preview))

	for preview_value in summary_previews:
		if typeof(preview_value) != TYPE_DICTIONARY:
			issues.append("bad_summary_preview_row")
			continue
		var preview: Dictionary = preview_value
		if str(preview.get("surface_id", "")) != "summary":
			issues.append("summary_preview_wrong_surface:%s" % str(preview.get("preview_id", "")))
		_validate_preview(preview, dossier_index, issues, false)

	var payload: String = "\n".join(payload_lines)
	return {
		"seed": RUN_SEED,
		"preview_count": news_previews.size(),
		"summary_preview_count": summary_previews.size(),
		"hash": _stable_hash(payload),
		"issue_count": issues.size(),
		"issues": issues,
		"surface_counts": _sorted_int_dictionary(surface_counts),
		"first_preview_id": str(news_previews[0].get("preview_id", "")) if not news_previews.is_empty() else "",
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


func _validate_preview(preview: Dictionary, dossier_index: Dictionary, issues: Array[String], require_news_clue: bool = true) -> void:
	var preview_id: String = str(preview.get("preview_id", ""))
	var story_id: String = str(preview.get("story_id", ""))
	if preview_id.strip_edges().is_empty() or not preview_id.begins_with("preview|%s|" % story_id):
		issues.append("bad_preview_id:%s" % preview_id)
	if not dossier_index.has(story_id):
		issues.append("preview_orphan_story:%s" % story_id)
		return
	var dossier: Dictionary = dossier_index.get(story_id, {})
	var fact_ids: Array = _fact_ids(dossier.get("cause_facts", []))
	var effect_ids: Array = _effect_ids(dossier.get("financial_effects", []))
	var metric_ids: Array = _metric_ids(dossier.get("financial_effects", []))
	var clue_ids: Array = _clue_ids(dossier)

	if preview.has("truth_state"):
		issues.append("preview_exposes_truth_state_key:%s" % preview_id)
	for unsafe_key in ["tone", "reliability", "source_quality", "disclosure_quality"]:
		if preview.has(unsafe_key):
			issues.append("preview_exposes_hidden_signal:%s:%s" % [preview_id, unsafe_key])
	for text_field in ["headline", "deck", "body"]:
		var text: String = str(preview.get(text_field, ""))
		if text.strip_edges().is_empty():
			issues.append("preview_missing_text:%s:%s" % [preview_id, text_field])
		for token in FORBIDDEN_TRUTH_TOKENS:
			if text.to_lower().find(token) >= 0:
				issues.append("preview_exposes_truth_text:%s:%s:%s" % [preview_id, text_field, token])

	var preview_fact_ids: Array = _string_array(preview.get("fact_ids", []))
	if preview_fact_ids.is_empty():
		issues.append("preview_missing_facts:%s" % preview_id)
	for fact_id in preview_fact_ids:
		if not fact_ids.has(fact_id):
			issues.append("preview_orphan_fact:%s:%s" % [preview_id, fact_id])

	var preview_clue_ids: Array = _string_array(preview.get("clue_ids", []))
	if preview_clue_ids.is_empty():
		issues.append("preview_missing_clues:%s" % preview_id)
	for clue_id in preview_clue_ids:
		if not clue_ids.has(clue_id):
			issues.append("preview_orphan_clue:%s:%s" % [preview_id, clue_id])
		if require_news_clue and clue_id.find("|news|") < 0:
			issues.append("news_preview_wrong_clue:%s:%s" % [preview_id, clue_id])

	for effect_id in _string_array(preview.get("effect_ids", [])):
		if not effect_ids.has(effect_id):
			issues.append("preview_orphan_effect:%s:%s" % [preview_id, effect_id])
	for metric_id in _string_array(preview.get("metric_ids", [])):
		if not metric_ids.has(metric_id):
			issues.append("preview_orphan_metric:%s:%s" % [preview_id, metric_id])

	var traceability: Dictionary = preview.get("traceability", {}) if typeof(preview.get("traceability", {})) == TYPE_DICTIONARY else {}
	for fact_id in _string_array(traceability.get("source_fact_ids", [])):
		if not fact_ids.has(fact_id):
			issues.append("preview_trace_orphan_fact:%s:%s" % [preview_id, fact_id])
	for evidence_id in _string_array(traceability.get("evidence_ids", [])):
		if not clue_ids.has(evidence_id):
			issues.append("preview_trace_orphan_evidence:%s:%s" % [preview_id, evidence_id])
	for statement_effect_id in _string_array(traceability.get("statement_effect_ids", [])):
		if not effect_ids.has(statement_effect_id):
			issues.append("preview_trace_orphan_statement_effect:%s:%s" % [preview_id, statement_effect_id])


func _preview_payload(preview: Dictionary) -> String:
	return "preview=%s|story=%s|surface=%s|headline=%s|deck=%s|facts=%s|clues=%s|effects=%s|metrics=%s" % [
		str(preview.get("preview_id", "")),
		str(preview.get("story_id", "")),
		str(preview.get("surface_id", "")),
		str(preview.get("headline", "")),
		str(preview.get("deck", "")),
		_array_payload(preview.get("fact_ids", [])),
		_array_payload(preview.get("clue_ids", [])),
		_array_payload(preview.get("effect_ids", [])),
		_array_payload(preview.get("metric_ids", []))
	]


func _fact_ids(facts_value: Variant) -> Array:
	var result: Array = []
	for fact_value in _variant_array(facts_value):
		if typeof(fact_value) != TYPE_DICTIONARY:
			continue
		var fact_id: String = str(fact_value.get("fact_id", ""))
		if not fact_id.strip_edges().is_empty() and not result.has(fact_id):
			result.append(fact_id)
	result.sort()
	return result


func _effect_ids(effects_value: Variant) -> Array:
	var result: Array = []
	for effect_value in _variant_array(effects_value):
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect_id: String = str(effect_value.get("effect_id", ""))
		if not effect_id.strip_edges().is_empty() and not result.has(effect_id):
			result.append(effect_id)
	result.sort()
	return result


func _metric_ids(effects_value: Variant) -> Array:
	var result: Array = []
	for effect_value in _variant_array(effects_value):
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var metric_id: String = str(effect_value.get("metric_id", ""))
		if not metric_id.strip_edges().is_empty() and not result.has(metric_id):
			result.append(metric_id)
	result.sort()
	return result


func _clue_ids(dossier: Dictionary) -> Array:
	var result: Array = []
	for field_name in ["public_clues", "private_clues", "statement_clues"]:
		for clue_value in _variant_array(dossier.get(field_name, [])):
			if typeof(clue_value) != TYPE_DICTIONARY:
				continue
			var clue_id: String = str(clue_value.get("clue_id", ""))
			if not clue_id.strip_edges().is_empty() and not result.has(clue_id):
				result.append(clue_id)
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
		hash_value = int((hash_value ^ text.unicode_at(index)) * 16777619)
		hash_value = hash_value % 2147483647
		if hash_value < 0:
			hash_value += 2147483647
	return str(hash_value)


func _fail(message: String) -> void:
	push_error(message)
	print("COMPANY_STORY_DOSSIER_PREVIEW_FAIL: %s" % message)
	get_tree().quit(1)
