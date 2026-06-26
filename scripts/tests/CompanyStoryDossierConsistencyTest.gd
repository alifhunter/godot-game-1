extends Node

const RUN_SEED := 20260615
const CATALOG_COMPANY_COUNT := 30
const EXPECTED_DOSSIER_COUNT := 30
const EXPECTED_CONSISTENCY_HASH := "2006435509"
const EXPECTED_THESIS_ROW_COUNT := 201

const REQUIRED_SURFACE_IDS := ["network", "news", "statement_note", "twooter"]
const REQUIRED_THESIS_TYPES := ["company_story", "financial_clue", "private_clue"]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_consistency_report()
	var second_report: Dictionary = _build_consistency_report()
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Company story dossier consistency payload was not stable across repeated fixed-seed runs.")
		return
	if str(first_report.get("hash", "")) != str(second_report.get("hash", "")):
		_fail("Company story dossier consistency hash was not stable across repeated fixed-seed runs.")
		return
	if int(first_report.get("dossier_count", 0)) != EXPECTED_DOSSIER_COUNT:
		_fail("Expected %d dossiers, got %d." % [EXPECTED_DOSSIER_COUNT, int(first_report.get("dossier_count", 0))])
		return
	if int(first_report.get("issue_count", 0)) != 0:
		_fail("Expected zero consistency issues, got %d: %s" % [
			int(first_report.get("issue_count", 0)),
			JSON.stringify(first_report.get("issues", []))
		])
		return
	if int(first_report.get("thesis_row_count", 0)) != EXPECTED_THESIS_ROW_COUNT:
		_fail("Expected %d dossier thesis rows, got %d." % [
			EXPECTED_THESIS_ROW_COUNT,
			int(first_report.get("thesis_row_count", 0))
		])
		return
	for surface_id in REQUIRED_SURFACE_IDS:
		if int(first_report.get("surface_counts", {}).get(surface_id, 0)) != EXPECTED_DOSSIER_COUNT:
			_fail("Expected one '%s' clue per dossier, got %d." % [
				surface_id,
				int(first_report.get("surface_counts", {}).get(surface_id, 0))
			])
			return
	for evidence_type in REQUIRED_THESIS_TYPES:
		if int(first_report.get("thesis_type_counts", {}).get(evidence_type, 0)) < EXPECTED_DOSSIER_COUNT:
			_fail("Expected at least one '%s' thesis row per dossier, got %d." % [
				evidence_type,
				int(first_report.get("thesis_type_counts", {}).get(evidence_type, 0))
			])
			return
	if EXPECTED_CONSISTENCY_HASH != "BASELINE_PENDING" and str(first_report.get("hash", "")) != EXPECTED_CONSISTENCY_HASH:
		_fail("Company story dossier consistency fingerprint changed. expected=%s actual=%s." % [
			EXPECTED_CONSISTENCY_HASH,
			str(first_report.get("hash", ""))
		])
		return

	first_report.erase("payload")
	print("COMPANY_STORY_DOSSIER_CONSISTENCY_OK %s" % JSON.stringify(first_report))
	get_tree().quit(0)


func _build_consistency_report() -> Dictionary:
	_setup_fixed_seed_run()
	var state: Dictionary = RunState.get_company_story_dossier_state()
	var dossier_index: Dictionary = state.get("dossier_index", {})
	var story_ids: Array = _unique_string_array(
		_variant_array(state.get("active_story_ids", [])) +
		_variant_array(state.get("resolved_story_ids", [])) +
		dossier_index.keys()
	)
	story_ids.sort()

	var issues: Array[String] = []
	var payload_lines: Array[String] = []
	var surface_counts: Dictionary = {}
	var thesis_type_counts: Dictionary = {}
	var thesis_row_count: int = 0
	var dossier_count: int = 0

	for story_id_value in story_ids:
		var story_id: String = str(story_id_value)
		if not dossier_index.has(story_id):
			issues.append("missing_dossier_index:%s" % story_id)
			continue
		if typeof(dossier_index.get(story_id)) != TYPE_DICTIONARY:
			issues.append("bad_dossier_row:%s" % story_id)
			continue
		var dossier: Dictionary = dossier_index.get(story_id, {})
		dossier_count += 1
		var dossier_payload: Dictionary = _validate_dossier(dossier, state, issues, surface_counts)
		payload_lines.append(str(dossier_payload.get("line", "")))
		var company_id: String = str(dossier.get("company_id", ""))
		var thesis_rows: Array = GameManager.get_company_story_dossier_evidence_options(company_id)
		var thesis_payload: Dictionary = _validate_thesis_rows_for_story(story_id, dossier, thesis_rows, issues, thesis_type_counts)
		thesis_row_count += int(thesis_payload.get("row_count", 0))
		payload_lines.append(str(thesis_payload.get("line", "")))

	_validate_global_story_refs(state, story_ids, issues)

	var payload: String = "\n".join(payload_lines)
	return {
		"seed": RUN_SEED,
		"dossier_count": dossier_count,
		"hash": _stable_hash(payload),
		"issue_count": issues.size(),
		"issues": issues,
		"surface_counts": _sorted_int_dictionary(surface_counts),
		"thesis_type_counts": _sorted_int_dictionary(thesis_type_counts),
		"thesis_row_count": thesis_row_count,
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


func _validate_dossier(dossier: Dictionary, state: Dictionary, issues: Array[String], surface_counts: Dictionary) -> Dictionary:
	var story_id: String = str(dossier.get("story_id", ""))
	var company_id: String = str(dossier.get("company_id", ""))
	var fact_ids: Array = _fact_ids(dossier.get("cause_facts", []))
	var effect_ids: Array = _effect_ids(dossier.get("financial_effects", []))
	var metric_ids: Array = _metric_ids(dossier.get("financial_effects", []))
	var clue_ids: Array = _clue_ids(dossier)
	var surface_ids: Array = _surface_ids(dossier)

	if story_id.strip_edges().is_empty():
		issues.append("missing_story_id")
	if company_id.strip_edges().is_empty():
		issues.append("missing_company_id:%s" % story_id)
	if str(dossier.get("ticker", "")).strip_edges().is_empty():
		issues.append("missing_ticker:%s" % story_id)
	if not str(story_id).begins_with("story|%s|" % company_id):
		issues.append("story_id_company_mismatch:%s:%s" % [story_id, company_id])

	var company_story_ids: Dictionary = state.get("company_story_ids", {})
	if not _string_array(company_story_ids.get(company_id, [])).has(story_id):
		issues.append("company_story_ids_missing:%s:%s" % [company_id, story_id])
	var company_state: Dictionary = RunState.get_company_story_dossier_company_state(company_id)
	if not (_string_array(company_state.get("active_story_ids", [])).has(story_id) or _string_array(company_state.get("resolved_story_ids", [])).has(story_id)):
		issues.append("company_runtime_missing_story:%s:%s" % [company_id, story_id])

	_validate_fact_rows(story_id, dossier.get("cause_facts", []), issues)
	_validate_clue_rows(story_id, "public_clues", dossier.get("public_clues", []), fact_ids, metric_ids, issues, surface_counts)
	_validate_clue_rows(story_id, "private_clues", dossier.get("private_clues", []), fact_ids, metric_ids, issues, surface_counts)
	_validate_clue_rows(story_id, "statement_clues", dossier.get("statement_clues", []), fact_ids, metric_ids, issues, surface_counts)
	_validate_financial_effect_rows(story_id, dossier.get("financial_effects", []), issues)
	_validate_timeline_rows(story_id, dossier.get("timeline", []), fact_ids, issues)
	_validate_thesis_hook_rows(story_id, company_id, dossier.get("thesis_hooks", []), fact_ids, metric_ids, issues)
	_validate_resolution_rows(story_id, dossier.get("resolution_conditions", []), metric_ids, issues)
	_validate_price_effects(story_id, dossier.get("price_effects", {}), issues)
	_validate_traceability(story_id, dossier.get("traceability", {}), fact_ids, clue_ids, surface_ids, effect_ids, dossier.get("price_effects", {}), issues)

	return {
		"line": "story=%s|company=%s|facts=%s|clues=%s|effects=%s|surfaces=%s|stage=%s|status=%s" % [
			story_id,
			company_id,
			_array_payload(fact_ids),
			_array_payload(clue_ids),
			_array_payload(effect_ids),
			_array_payload(surface_ids),
			str(dossier.get("stage_id", "")),
			str(dossier.get("public_status", ""))
		]
	}


func _validate_fact_rows(story_id: String, facts_value: Variant, issues: Array[String]) -> void:
	var seen: Dictionary = {}
	var facts: Array = _variant_array(facts_value)
	if facts.is_empty():
		issues.append("missing_facts:%s" % story_id)
	for fact_value in facts:
		if typeof(fact_value) != TYPE_DICTIONARY:
			issues.append("bad_fact_row:%s" % story_id)
			continue
		var fact: Dictionary = fact_value
		var fact_id: String = str(fact.get("fact_id", ""))
		if fact_id.strip_edges().is_empty():
			issues.append("missing_fact_id:%s" % story_id)
		elif not fact_id.begins_with("fact|%s|" % story_id):
			issues.append("fact_wrong_story:%s:%s" % [story_id, fact_id])
		elif seen.has(fact_id):
			issues.append("duplicate_fact_id:%s" % fact_id)
		seen[fact_id] = true
		if str(fact.get("fact_type", "")).strip_edges().is_empty() or str(fact.get("source_id", "")).strip_edges().is_empty():
			issues.append("incomplete_fact:%s:%s" % [story_id, fact_id])


func _validate_clue_rows(story_id: String, field_name: String, clues_value: Variant, fact_ids: Array, metric_ids: Array, issues: Array[String], surface_counts: Dictionary) -> void:
	var clues: Array = _variant_array(clues_value)
	if clues.is_empty():
		issues.append("missing_%s:%s" % [field_name, story_id])
	for clue_value in clues:
		if typeof(clue_value) != TYPE_DICTIONARY:
			issues.append("bad_%s_row:%s" % [field_name, story_id])
			continue
		var clue: Dictionary = clue_value
		var clue_id: String = str(clue.get("clue_id", ""))
		var surface_id: String = str(clue.get("surface_id", ""))
		if clue_id.strip_edges().is_empty() or not clue_id.begins_with("clue|%s|" % story_id):
			issues.append("clue_wrong_story:%s:%s" % [story_id, clue_id])
		if surface_id.strip_edges().is_empty():
			issues.append("clue_missing_surface:%s:%s" % [story_id, clue_id])
		else:
			_increment(surface_counts, surface_id)
		for fact_id in _string_array(clue.get("fact_ids", [])):
			if not fact_ids.has(fact_id):
				issues.append("clue_orphan_fact:%s:%s:%s" % [story_id, clue_id, fact_id])
		for metric_id in _string_array(clue.get("metric_ids", [])):
			if not metric_ids.has(metric_id):
				issues.append("clue_orphan_metric:%s:%s:%s" % [story_id, clue_id, metric_id])
		if field_name != "statement_clues" and _string_array(clue.get("fact_ids", [])).is_empty():
			issues.append("non_statement_clue_missing_facts:%s:%s" % [story_id, clue_id])


func _validate_financial_effect_rows(story_id: String, effects_value: Variant, issues: Array[String]) -> void:
	var effects: Array = _variant_array(effects_value)
	if effects.is_empty():
		issues.append("missing_effects:%s" % story_id)
	for effect_value in effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			issues.append("bad_effect_row:%s" % story_id)
			continue
		var effect: Dictionary = effect_value
		var effect_id: String = str(effect.get("effect_id", ""))
		if effect_id.strip_edges().is_empty() or not effect_id.begins_with("effect|%s|" % story_id):
			issues.append("effect_wrong_story:%s:%s" % [story_id, effect_id])
		if str(effect.get("metric_id", "")).strip_edges().is_empty():
			issues.append("effect_missing_metric:%s:%s" % [story_id, effect_id])


func _validate_timeline_rows(story_id: String, timeline_value: Variant, fact_ids: Array, issues: Array[String]) -> void:
	var rows: Array = _variant_array(timeline_value)
	if rows.is_empty():
		issues.append("missing_timeline:%s" % story_id)
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			issues.append("bad_timeline_row:%s" % story_id)
			continue
		var row: Dictionary = row_value
		var timeline_id: String = str(row.get("timeline_id", ""))
		if timeline_id.strip_edges().is_empty() or not timeline_id.begins_with("timeline|%s|" % story_id):
			issues.append("timeline_wrong_story:%s:%s" % [story_id, timeline_id])
		if int(row.get("end_day_index", -1)) < int(row.get("start_day_index", 0)):
			issues.append("timeline_bad_range:%s:%s" % [story_id, timeline_id])
		for fact_id in _string_array(row.get("fact_ids", [])):
			if not fact_ids.has(fact_id):
				issues.append("timeline_orphan_fact:%s:%s:%s" % [story_id, timeline_id, fact_id])


func _validate_thesis_hook_rows(story_id: String, company_id: String, hooks_value: Variant, fact_ids: Array, metric_ids: Array, issues: Array[String]) -> void:
	var rows: Array = _variant_array(hooks_value)
	if rows.is_empty():
		issues.append("missing_thesis_hooks:%s" % story_id)
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			issues.append("bad_thesis_hook:%s" % story_id)
			continue
		var row: Dictionary = row_value
		var hook_id: String = str(row.get("thesis_hook_id", ""))
		if hook_id.strip_edges().is_empty() or not hook_id.begins_with("thesis|%s|" % story_id):
			issues.append("thesis_hook_wrong_story:%s:%s" % [story_id, hook_id])
		if str(row.get("story_id", "")) != story_id or str(row.get("company_id", "")) != company_id:
			issues.append("thesis_hook_identity_mismatch:%s:%s" % [story_id, hook_id])
		for fact_id in _string_array(row.get("fact_ids", [])):
			if not fact_ids.has(fact_id):
				issues.append("thesis_hook_orphan_fact:%s:%s:%s" % [story_id, hook_id, fact_id])
		for metric_id in _string_array(row.get("metric_ids", [])):
			if not metric_ids.has(metric_id):
				issues.append("thesis_hook_orphan_metric:%s:%s:%s" % [story_id, hook_id, metric_id])


func _validate_resolution_rows(story_id: String, conditions_value: Variant, metric_ids: Array, issues: Array[String]) -> void:
	var rows: Array = _variant_array(conditions_value)
	if rows.is_empty():
		issues.append("missing_resolution_conditions:%s" % story_id)
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			issues.append("bad_resolution_condition:%s" % story_id)
			continue
		var row: Dictionary = row_value
		var condition_id: String = str(row.get("condition_id", ""))
		var metric_id: String = str(row.get("metric_id", ""))
		if condition_id.strip_edges().is_empty() or not condition_id.begins_with("condition|%s|" % story_id):
			issues.append("condition_wrong_story:%s:%s" % [story_id, condition_id])
		if not metric_ids.has(metric_id):
			issues.append("condition_orphan_metric:%s:%s:%s" % [story_id, condition_id, metric_id])


func _validate_price_effects(story_id: String, price_effects_value: Variant, issues: Array[String]) -> void:
	if typeof(price_effects_value) != TYPE_DICTIONARY:
		issues.append("missing_price_effects:%s" % story_id)
		return
	var price_effects: Dictionary = price_effects_value
	var price_effect_id: String = str(price_effects.get("price_effect_id", ""))
	if price_effect_id.strip_edges().is_empty() or not price_effect_id.begins_with("price|%s|" % story_id):
		issues.append("price_wrong_story:%s:%s" % [story_id, price_effect_id])
	if absf(float(price_effects.get("drift_bps", 0.0))) > 18.0:
		issues.append("price_drift_out_of_bounds:%s" % story_id)


func _validate_traceability(story_id: String, traceability_value: Variant, fact_ids: Array, clue_ids: Array, surface_ids: Array, effect_ids: Array, price_effects_value: Variant, issues: Array[String]) -> void:
	if typeof(traceability_value) != TYPE_DICTIONARY:
		issues.append("missing_traceability:%s" % story_id)
		return
	var traceability: Dictionary = traceability_value
	var price_effect_id: String = ""
	if typeof(price_effects_value) == TYPE_DICTIONARY:
		price_effect_id = str(price_effects_value.get("price_effect_id", ""))
	if _array_payload(traceability.get("source_fact_ids", [])) != _array_payload(fact_ids):
		issues.append("traceability_fact_mismatch:%s" % story_id)
	if _array_payload(traceability.get("evidence_ids", [])) != _array_payload(clue_ids):
		issues.append("traceability_evidence_mismatch:%s" % story_id)
	if _array_payload(traceability.get("generated_surface_ids", [])) != _array_payload(surface_ids):
		issues.append("traceability_surface_mismatch:%s" % story_id)
	if _array_payload(traceability.get("statement_effect_ids", [])) != _array_payload(effect_ids):
		issues.append("traceability_statement_effect_mismatch:%s" % story_id)
	if _array_payload(traceability.get("price_effect_ids", [])) != _array_payload([price_effect_id]):
		issues.append("traceability_price_effect_mismatch:%s" % story_id)


func _validate_thesis_rows_for_story(story_id: String, dossier: Dictionary, thesis_rows: Array, issues: Array[String], thesis_type_counts: Dictionary) -> Dictionary:
	var fact_ids: Array = _fact_ids(dossier.get("cause_facts", []))
	var effect_ids: Array = _effect_ids(dossier.get("financial_effects", []))
	var metric_ids: Array = _metric_ids(dossier.get("financial_effects", []))
	var clue_ids: Array = _clue_ids(dossier)
	var payload_parts: Array[String] = []
	var row_count: int = 0

	for row_value in thesis_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("story_id", "")) != story_id:
			continue
		row_count += 1
		var evidence_type: String = str(row.get("dossier_evidence_type", ""))
		_increment(thesis_type_counts, evidence_type)
		if str(row.get("source_type", "")) != "company_story_dossier":
			issues.append("thesis_row_bad_source:%s:%s" % [story_id, evidence_type])
		if row.has("truth_state") or str(row.get("value", "")).find("fraud_risk") >= 0 or str(row.get("detail", "")).find("truth_state") >= 0:
			issues.append("thesis_row_truth_leak:%s:%s" % [story_id, evidence_type])
		var fact_id: String = str(row.get("fact_id", ""))
		if fact_id.strip_edges().is_empty() or not fact_ids.has(fact_id):
			issues.append("thesis_row_orphan_fact:%s:%s:%s" % [story_id, evidence_type, fact_id])
		for row_fact_id in _string_array(row.get("fact_ids", [])):
			if not fact_ids.has(row_fact_id):
				issues.append("thesis_row_orphan_fact_array:%s:%s:%s" % [story_id, evidence_type, row_fact_id])
		var clue_id: String = str(row.get("clue_id", ""))
		if not clue_id.strip_edges().is_empty() and not clue_ids.has(clue_id):
			issues.append("thesis_row_orphan_clue:%s:%s:%s" % [story_id, evidence_type, clue_id])
		var effect_id: String = str(row.get("effect_id", ""))
		if not effect_id.strip_edges().is_empty() and not effect_ids.has(effect_id):
			issues.append("thesis_row_orphan_effect:%s:%s:%s" % [story_id, evidence_type, effect_id])
		var metric_id: String = str(row.get("metric_id", ""))
		if not metric_id.strip_edges().is_empty() and not metric_ids.has(metric_id):
			issues.append("thesis_row_orphan_metric:%s:%s:%s" % [story_id, evidence_type, metric_id])
		payload_parts.append("%s|%s|%s|%s|%s|%s|%s" % [
			evidence_type,
			str(row.get("category", "")),
			str(row.get("source_id", "")),
			fact_id,
			clue_id,
			effect_id,
			str(row.get("surface_id", ""))
		])

	payload_parts.sort()
	return {
		"row_count": row_count,
		"line": "thesis_rows=%s|%s" % [story_id, ";;".join(payload_parts)]
	}


func _validate_global_story_refs(state: Dictionary, story_ids: Array, issues: Array[String]) -> void:
	var known_story_ids: Dictionary = {}
	for story_id_value in story_ids:
		known_story_ids[str(story_id_value)] = true
	for list_name in ["active_story_ids", "resolved_story_ids"]:
		for story_id in _string_array(state.get(list_name, [])):
			if not known_story_ids.has(story_id):
				issues.append("global_orphan_%s:%s" % [list_name, story_id])
	var company_story_ids: Dictionary = state.get("company_story_ids", {})
	for company_id_value in company_story_ids.keys():
		var company_id: String = str(company_id_value)
		for story_id in _string_array(company_story_ids.get(company_id_value, [])):
			if not known_story_ids.has(story_id):
				issues.append("company_orphan_story:%s:%s" % [company_id, story_id])
	var recent_rows: Array = _variant_array(state.get("recent_resolved_stories", []))
	for row_value in recent_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var story_id: String = str(row_value.get("story_id", ""))
		if not story_id.strip_edges().is_empty() and not known_story_ids.has(story_id):
			issues.append("recent_resolved_orphan_story:%s" % story_id)


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


func _surface_ids(dossier: Dictionary) -> Array:
	var result: Array = []
	for field_name in ["public_clues", "private_clues", "statement_clues"]:
		for clue_value in _variant_array(dossier.get(field_name, [])):
			if typeof(clue_value) != TYPE_DICTIONARY:
				continue
			var surface_id: String = str(clue_value.get("surface_id", ""))
			if not surface_id.strip_edges().is_empty() and not result.has(surface_id):
				result.append(surface_id)
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


func _unique_string_array(source_value: Variant) -> Array:
	var result: Array = []
	for item_value in _variant_array(source_value):
		var text: String = str(item_value).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	return result


func _array_payload(source_value: Variant) -> String:
	var rows: Array = _string_array(source_value)
	return "|".join(rows)


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
	print("COMPANY_STORY_DOSSIER_CONSISTENCY_FAIL: %s" % message)
	get_tree().quit(1)
