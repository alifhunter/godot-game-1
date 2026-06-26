extends Node

const RUN_SEED := 20260614


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = 30
	difficulty_config["use_company_universe_catalog"] = true
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0

	var company_id: String = _first_company_with_commodity_exposure()
	if company_id.is_empty():
		_fail("Expected catalog roster to include at least one commodity-exposed company.")
		return
	if not RunState.ensure_company_full_detail(company_id):
		_fail("Expected company detail hydration for '%s'." % company_id)
		return
	var company: Dictionary = GameManager.get_company_snapshot(company_id, true, true, true)
	var sector_id: String = str(company.get("sector_id", "")).strip_edges()
	var summary: Dictionary = GameManager.get_commodity_macro_summary(sector_id)
	if int(summary.get("year", 0)) != 2020:
		_fail("Expected commodity summary year 2020, got %d." % int(summary.get("year", 0)))
		return
	if summary.get("sector_relevant", []).is_empty():
		_fail("Expected sector-relevant commodity summary rows for sector '%s'." % sector_id)
		return

	var rows: Array = GameManager.get_commodity_macro_evidence_options(company_id, sector_id)
	if rows.is_empty():
		_fail("Expected commodity macro evidence rows for '%s'." % company_id)
		return
	var row: Dictionary = rows[0]
	if not _assert_commodity_evidence_shape(row, company_id):
		return

	var options: Dictionary = GameManager.get_thesis_evidence_options(company_id)
	if not _options_include_commodity_macro(options):
		_fail("Expected thesis sector/macro options to include commodity macro rows.")
		return

	var capture_result: Dictionary = GameManager.capture_research_evidence(row)
	if not bool(capture_result.get("success", false)):
		_fail("Expected commodity macro evidence capture to succeed: %s" % str(capture_result.get("message", "")))
		return
	var captured: Dictionary = capture_result.get("evidence", {})
	if str(captured.get("commodity_id", "")) != str(row.get("commodity_id", "")):
		_fail("Expected Research Tray capture to preserve commodity_id, got %s." % JSON.stringify(captured))
		return

	var thesis_result: Dictionary = GameManager.create_thesis(company_id, "bullish", "swing", "Commodity Macro Thesis")
	if not bool(thesis_result.get("success", false)):
		_fail("Expected thesis creation to succeed: %s" % str(thesis_result.get("message", "")))
		return
	var thesis_id: String = str(thesis_result.get("thesis", {}).get("id", ""))
	var attach_result: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(captured.get("id", "")), "watch")
	if not bool(attach_result.get("success", false)):
		_fail("Expected commodity macro research row to attach to thesis: %s" % str(attach_result.get("message", "")))
		return
	if str(attach_result.get("evidence", {}).get("commodity_id", "")) != str(row.get("commodity_id", "")):
		_fail("Expected attached evidence to preserve commodity_id, got %s." % JSON.stringify(attach_result.get("evidence", {})))
		return

	var direct_thesis_result: Dictionary = GameManager.create_thesis(company_id, "watch", "swing", "Direct Commodity Option Thesis")
	if not bool(direct_thesis_result.get("success", false)):
		_fail("Expected second thesis creation to succeed: %s" % str(direct_thesis_result.get("message", "")))
		return
	var direct_add_result: Dictionary = GameManager.add_thesis_evidence(str(direct_thesis_result.get("thesis", {}).get("id", "")), row)
	if not bool(direct_add_result.get("success", false)):
		_fail("Expected direct commodity option add to succeed: %s" % str(direct_add_result.get("message", "")))
		return
	if str(direct_add_result.get("evidence", {}).get("commodity_id", "")) != str(row.get("commodity_id", "")):
		_fail("Expected direct thesis evidence to preserve commodity_id, got %s." % JSON.stringify(direct_add_result.get("evidence", {})))
		return

	print("COMMODITY_MACRO_EVIDENCE_CONTRACT_OK %s" % JSON.stringify({
		"company_id": company_id,
		"sector_id": sector_id,
		"commodity_id": row.get("commodity_id", ""),
		"impact": row.get("impact", ""),
		"summary_rows": summary.get("sector_relevant", []).size(),
		"evidence_rows": rows.size()
	}))
	get_tree().quit(0)


func _first_company_with_commodity_exposure() -> String:
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		var exposures: Dictionary = definition.get("commodity_exposures", {}) if typeof(definition.get("commodity_exposures", {})) == TYPE_DICTIONARY else {}
		if not exposures.is_empty():
			return company_id
	return ""


func _assert_commodity_evidence_shape(row: Dictionary, company_id: String) -> bool:
	if str(row.get("company_id", "")) != company_id:
		_fail("Expected commodity evidence company_id '%s', got %s." % [company_id, str(row.get("company_id", ""))])
		return false
	if str(row.get("source_type", "")) != "commodity_macro":
		_fail("Expected source_type commodity_macro, got %s." % str(row.get("source_type", "")))
		return false
	if str(row.get("source_label", "")) != "Macro Commodities":
		_fail("Expected Macro Commodities source label, got %s." % str(row.get("source_label", "")))
		return false
	if str(row.get("category", "")) != "sector_macro":
		_fail("Expected sector_macro category, got %s." % str(row.get("category", "")))
		return false
	if str(row.get("source_id", "")).strip_edges().is_empty() or str(row.get("commodity_id", "")).strip_edges().is_empty():
		_fail("Expected commodity evidence to include source_id and commodity_id: %s." % JSON.stringify(row))
		return false
	if not _valid_impact(str(row.get("impact", ""))):
		_fail("Expected valid commodity impact, got %s." % str(row.get("impact", "")))
		return false
	if typeof(row.get("related_sectors", [])) != TYPE_ARRAY or typeof(row.get("story_tags", [])) != TYPE_ARRAY:
		_fail("Expected commodity evidence related_sectors/story_tags arrays: %s." % JSON.stringify(row))
		return false
	return true


func _options_include_commodity_macro(options: Dictionary) -> bool:
	for category_value in options.get("categories", []):
		if typeof(category_value) != TYPE_DICTIONARY:
			continue
		var category: Dictionary = category_value
		if str(category.get("id", "")) != "sector_macro":
			continue
		for option_value in category.get("options", []):
			if typeof(option_value) == TYPE_DICTIONARY and str(option_value.get("source_type", "")) == "commodity_macro":
				return true
	return false


func _valid_impact(value: String) -> bool:
	return value in ["positive", "negative", "mixed"]


func _fail(message: String) -> void:
	push_error(message)
	print("COMMODITY_MACRO_EVIDENCE_CONTRACT_FAIL: %s" % message)
	get_tree().quit(1)
