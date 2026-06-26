extends Node

const RUN_SEED := 20260615
const CATALOG_COMPANY_COUNT := 30
const REQUIRED_TYPES := ["macro_cause", "sector_cause", "company_story", "financial_clue", "private_clue"]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = CATALOG_COMPANY_COUNT
	difficulty_config["use_company_universe_catalog"] = true
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0

	var company_id: String = _first_company_with_required_dossier_shapes()
	if company_id.is_empty():
		_fail("Expected at least one catalog company to expose all required dossier evidence shapes.")
		return
	if not RunState.ensure_company_full_detail(company_id):
		_fail("Expected company detail hydration for '%s'." % company_id)
		return

	var rows: Array = GameManager.get_company_story_dossier_evidence_options(company_id)
	var rows_by_type: Dictionary = _rows_by_dossier_type(rows)
	for type_value in REQUIRED_TYPES:
		var evidence_type: String = str(type_value)
		if not rows_by_type.has(evidence_type):
			_fail("Expected dossier evidence type '%s' for company '%s'. Rows=%s" % [evidence_type, company_id, JSON.stringify(rows)])
			return
		if not _assert_dossier_evidence_shape(rows_by_type.get(evidence_type, {}), company_id, evidence_type):
			return

	var options: Dictionary = GameManager.get_thesis_evidence_options(company_id)
	if not _options_include_dossier_rows(options, rows_by_type):
		return

	var capture_row: Dictionary = rows_by_type.get("private_clue", {})
	var capture_result: Dictionary = GameManager.capture_research_evidence(capture_row)
	if not bool(capture_result.get("success", false)):
		_fail("Expected private dossier clue to capture into Research Tray: %s" % str(capture_result.get("message", "")))
		return
	var captured: Dictionary = capture_result.get("evidence", {})
	if not _assert_preserved_dossier_fields(captured, capture_row, "captured"):
		return

	var thesis_result: Dictionary = GameManager.create_thesis(company_id, "bullish", "event", "Dossier Thesis")
	if not bool(thesis_result.get("success", false)):
		_fail("Expected thesis creation to succeed: %s" % str(thesis_result.get("message", "")))
		return
	var thesis_id: String = str(thesis_result.get("thesis", {}).get("id", ""))
	var attach_result: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(captured.get("id", "")), "watch")
	if not bool(attach_result.get("success", false)):
		_fail("Expected captured dossier clue to attach to thesis: %s" % str(attach_result.get("message", "")))
		return
	if not _assert_preserved_dossier_fields(attach_result.get("evidence", {}), capture_row, "attached"):
		return

	var direct_thesis_result: Dictionary = GameManager.create_thesis(company_id, "watch", "event", "Direct Dossier Thesis")
	if not bool(direct_thesis_result.get("success", false)):
		_fail("Expected direct thesis creation to succeed: %s" % str(direct_thesis_result.get("message", "")))
		return
	var financial_row: Dictionary = rows_by_type.get("financial_clue", {})
	var add_result: Dictionary = GameManager.add_thesis_evidence(str(direct_thesis_result.get("thesis", {}).get("id", "")), financial_row)
	if not bool(add_result.get("success", false)):
		_fail("Expected direct dossier financial clue add to succeed: %s" % str(add_result.get("message", "")))
		return
	if not _assert_preserved_dossier_fields(add_result.get("evidence", {}), financial_row, "direct"):
		return

	print("COMPANY_STORY_DOSSIER_THESIS_EVIDENCE_OK %s" % JSON.stringify({
		"seed": RUN_SEED,
		"company_id": company_id,
		"row_count": rows.size(),
		"story_id": str(capture_row.get("story_id", "")),
		"types": REQUIRED_TYPES
	}))
	get_tree().quit(0)


func _first_company_with_required_dossier_shapes() -> String:
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var rows: Array = GameManager.get_company_story_dossier_evidence_options(company_id)
		var rows_by_type: Dictionary = _rows_by_dossier_type(rows)
		var has_all: bool = true
		for type_value in REQUIRED_TYPES:
			if not rows_by_type.has(str(type_value)):
				has_all = false
				break
		if has_all:
			return company_id
	return ""


func _rows_by_dossier_type(rows: Array) -> Dictionary:
	var result: Dictionary = {}
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var evidence_type: String = str(row.get("dossier_evidence_type", "")).strip_edges()
		if not evidence_type.is_empty() and not result.has(evidence_type):
			result[evidence_type] = row
	return result


func _assert_dossier_evidence_shape(row: Dictionary, company_id: String, expected_type: String) -> bool:
	if str(row.get("source_type", "")) != "company_story_dossier":
		_fail("Expected company_story_dossier source for %s row, got %s." % [expected_type, JSON.stringify(row)])
		return false
	if str(row.get("source_label", "")) != "Story Dossier":
		_fail("Expected Story Dossier source label for %s row, got %s." % [expected_type, JSON.stringify(row)])
		return false
	var row_company_id: String = str(row.get("company_id", "")).strip_edges()
	if not row_company_id.is_empty() and row_company_id != company_id:
		_fail("Expected company_id to remain compatible for %s row, got %s." % [expected_type, JSON.stringify(row)])
		return false
	if str(row.get("story_id", "")).strip_edges().is_empty():
		_fail("Expected %s row to include story_id: %s." % [expected_type, JSON.stringify(row)])
		return false
	if str(row.get("fact_id", "")).strip_edges().is_empty():
		_fail("Expected %s row to include fact_id: %s." % [expected_type, JSON.stringify(row)])
		return false
	if str(row.get("surface_id", "")).strip_edges().is_empty():
		_fail("Expected %s row to include surface_id: %s." % [expected_type, JSON.stringify(row)])
		return false
	if str(row.get("source_id", "")).strip_edges().is_empty():
		_fail("Expected %s row to include source_id: %s." % [expected_type, JSON.stringify(row)])
		return false
	if str(row.get("dossier_evidence_type", "")) != expected_type:
		_fail("Expected dossier type %s, got %s." % [expected_type, str(row.get("dossier_evidence_type", ""))])
		return false
	if row.has("truth_state") or str(row.get("value", "")).find("fraud_risk") >= 0 or str(row.get("detail", "")).find("truth_state") >= 0:
		_fail("Dossier thesis row leaked hidden truth metadata: %s." % JSON.stringify(row))
		return false
	var category: String = str(row.get("category", ""))
	if expected_type in ["macro_cause", "sector_cause"] and category != "sector_macro":
		_fail("Expected %s to map to sector_macro, got %s." % [expected_type, category])
		return false
	if expected_type == "company_story" and category != "corporate_events":
		_fail("Expected company_story to map to corporate_events, got %s." % category)
		return false
	if expected_type == "financial_clue" and category != "financials":
		_fail("Expected financial_clue to map to financials, got %s." % category)
		return false
	if expected_type == "private_clue" and category != "network_intel":
		_fail("Expected private_clue to map to network_intel, got %s." % category)
		return false
	return true


func _options_include_dossier_rows(options: Dictionary, rows_by_type: Dictionary) -> bool:
	var source_ids: Dictionary = {}
	for category_value in options.get("categories", []):
		if typeof(category_value) != TYPE_DICTIONARY:
			continue
		for option_value in category_value.get("options", []):
			if typeof(option_value) != TYPE_DICTIONARY:
				continue
			var option: Dictionary = option_value
			if str(option.get("source_type", "")) == "company_story_dossier":
				source_ids[str(option.get("source_id", ""))] = true
	for type_value in REQUIRED_TYPES:
		var row: Dictionary = rows_by_type.get(str(type_value), {})
		if not source_ids.has(str(row.get("source_id", ""))):
			_fail("Expected thesis option snapshot to include dossier %s row with source_id %s." % [
				str(type_value),
				str(row.get("source_id", ""))
			])
			return false
	return true


func _assert_preserved_dossier_fields(actual: Dictionary, expected: Dictionary, label: String) -> bool:
	for key_value in ["story_id", "fact_id", "surface_id", "dossier_evidence_type", "source_id"]:
		var key: String = str(key_value)
		if str(actual.get(key, "")) != str(expected.get(key, "")):
			_fail("Expected %s evidence to preserve %s. expected=%s actual=%s" % [
				label,
				key,
				str(expected.get(key, "")),
				str(actual.get(key, ""))
			])
			return false
	if str(expected.get("clue_id", "")).strip_edges() != "" and str(actual.get("clue_id", "")) != str(expected.get("clue_id", "")):
		_fail("Expected %s evidence to preserve clue_id." % label)
		return false
	if str(expected.get("effect_id", "")).strip_edges() != "" and str(actual.get("effect_id", "")) != str(expected.get("effect_id", "")):
		_fail("Expected %s evidence to preserve effect_id." % label)
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	print("COMPANY_STORY_DOSSIER_THESIS_EVIDENCE_FAIL: %s" % message)
	get_tree().quit(1)
