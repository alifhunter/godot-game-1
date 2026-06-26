extends Node

const NEWS_CONTROLLER_SCRIPT := preload("res://scripts/ui/controllers/NewsController.gd")
const ANNUAL_FILING_DOCUMENT_SCRIPT := preload("res://systems/AnnualFilingDocument.gd")
const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")

const REPORT_PREFIX := "FULL_YEAR_PLAYER_SCENARIO_OK "
const RUN_SEED := 20260622
const TRADING_DAYS := 225
const INVESTMENT_RATIO := 0.05
const BANK_COMPANY_ID := "bank_orang_indonesia"
const TEST_LOG_PATH := "res://docs/development/test_log/2026-06-24_annual_filing_sector_realism_full_year.md"


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var started_usec: int = Time.get_ticks_usec()

	var setup_error: String = _setup_run()
	if not setup_error.is_empty():
		_fail(setup_error)
		return

	var game_root: Node = GAME_ROOT_SCENE.instantiate()
	add_child(game_root)
	await _wait_frames(8)
	var ui_error: String = _validate_game_root(game_root)
	if not ui_error.is_empty():
		_fail(ui_error)
		return

	var company: Dictionary = _select_research_candidate()
	if company.is_empty():
		_fail("Expected a buyable full-year scenario candidate.")
		return
	var company_id: String = str(company.get("id", company.get("company_id", ""))).strip_edges()
	var initial_prices: Dictionary = _initial_price_lookup()
	var buy_result: Dictionary = _buy_position(company)
	if not bool(buy_result.get("success", false)):
		_fail("Expected player buy to succeed: %s" % str(buy_result.get("message", "")))
		return

	var thesis_result: Dictionary = _create_thesis_with_evidence(company)
	if not bool(thesis_result.get("success", false)):
		_fail("Expected thesis setup to succeed: %s" % str(thesis_result.get("message", "")))
		return

	game_root.queue_free()
	await _wait_frames(2)

	var metrics: Dictionary = _default_metrics(company_id)
	for day_offset: int in range(TRADING_DAYS):
		var advance_result: Dictionary = GameManager.simulate_opening_session(false)
		if advance_result.has("success") and not bool(advance_result.get("success", false)):
			_fail("Advance failed at offset %d: %s" % [day_offset, str(advance_result.get("message", ""))])
			return
		var day_result: Dictionary = advance_result.get("day_result", {})
		if day_result.is_empty():
			_fail("Advance returned empty day_result at offset %d." % day_offset)
			return
		metrics["days_completed"] = int(metrics.get("days_completed", 0)) + 1
		_collect_day_metrics(day_result, metrics)
		_collect_gorengan_snapshot(metrics)
		_collect_price_exposure_snapshot(metrics)
		if (day_offset + 1) % 50 == 0:
			print("FULL_YEAR_PLAYER_SCENARIO_PROGRESS day=%d/%d trade_date=%s" % [
				day_offset + 1,
				TRADING_DAYS,
				JSON.stringify(RunState.get_current_trade_date())
			])

	var final_report_result: Dictionary = GameManager.generate_thesis_report(str(thesis_result.get("thesis_id", "")))
	var report: Dictionary = _build_report(
		company,
		buy_result,
		thesis_result,
		initial_prices,
		metrics,
		final_report_result,
		float(Time.get_ticks_usec() - started_usec) / 1000.0
	)
	var validation_error: String = _validate_report(report)
	if not validation_error.is_empty():
		_fail("%s report=%s" % [validation_error, JSON.stringify(report)])
		return
	var log_error: String = _write_test_log(report)
	if not log_error.is_empty():
		_fail(log_error)
		return

	print("%s%s" % [REPORT_PREFIX, JSON.stringify(report)])
	get_tree().quit(0)


func _setup_run() -> String:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config = difficulty_config.duplicate(true)
	difficulty_config["use_company_universe_catalog"] = true
	difficulty_config["company_count"] = max(70, int(difficulty_config.get("company_count", 30)))
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	if company_definitions.is_empty():
		return "Company roster generation returned no companies."
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	var opening_result: Dictionary = GameManager.simulate_opening_session(false)
	if opening_result.has("success") and not bool(opening_result.get("success", false)):
		return "Opening session failed: %s" % str(opening_result.get("message", ""))
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0
	return ""


func _validate_game_root(game_root: Node) -> String:
	for control_name: String in ["StockAppButton", "NewsAppButton", "ThesisAppButton", "DesktopAdvanceDayButton"]:
		if game_root.find_child(control_name, true, false) == null:
			return "GameRoot did not expose required control %s." % control_name
	return ""


func _select_research_candidate() -> Dictionary:
	var news_by_company: Dictionary = _news_by_company_id(GameManager.get_news_snapshot())
	if RunState.company_order.has(BANK_COMPANY_ID) and RunState.ensure_company_full_detail(BANK_COMPANY_ID):
		var bank_company: Dictionary = GameManager.get_company_snapshot(BANK_COMPANY_ID, true, true, true)
		if not bank_company.is_empty():
			var bank_definition: Dictionary = RunState.get_effective_company_definition(BANK_COMPANY_ID, true, true)
			var bank_price: float = float(bank_company.get("current_price", bank_definition.get("current_price", bank_definition.get("starting_price", 0.0))))
			if bank_price > 0.0:
				var bank_sector_id: String = str(bank_company.get("sector_id", bank_definition.get("sector_id", "")))
				bank_company["selection_score"] = (
					float(bank_definition.get("quality_score", 0)) * 1.0
					+ float(bank_definition.get("growth_score", 0)) * 1.1
					- float(bank_definition.get("risk_score", 0)) * 0.7
				)
				bank_company["selection_reason"] = "fixed catalog bank annual filing scenario target"
				bank_company["initial_news_article"] = news_by_company.get(BANK_COMPANY_ID, {})
				bank_company["initial_commodity_evidence_count"] = GameManager.get_commodity_macro_evidence_options(BANK_COMPANY_ID, bank_sector_id).size()
				bank_company["initial_story_evidence_count"] = GameManager.get_company_story_dossier_evidence_options(BANK_COMPANY_ID).size()
				return bank_company
	var best: Dictionary = {}
	var best_score: float = -999999.0
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		if not RunState.ensure_company_full_detail(company_id):
			continue
		var company: Dictionary = GameManager.get_company_snapshot(company_id, true, true, true)
		if company.is_empty():
			continue
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		var sector_id: String = str(company.get("sector_id", definition.get("sector_id", "")))
		var commodity_options: Array = GameManager.get_commodity_macro_evidence_options(company_id, sector_id)
		var story_options: Array = GameManager.get_company_story_dossier_evidence_options(company_id)
		var score: float = (
			float(definition.get("quality_score", 0)) * 1.0 +
			float(definition.get("growth_score", 0)) * 1.1 -
			float(definition.get("risk_score", 0)) * 0.7 +
			float(commodity_options.size()) * 2.0 +
			float(story_options.size()) * 1.5
		)
		if news_by_company.has(company_id):
			score += 6.0
		var price: float = float(company.get("current_price", definition.get("current_price", definition.get("starting_price", 0.0))))
		if price <= 0.0:
			continue
		if score > best_score:
			best_score = score
			best = company.duplicate(true)
			best["selection_score"] = score
			best["selection_reason"] = "highest initial combined quality/growth, public news, commodity, and story evidence score"
			best["initial_news_article"] = news_by_company.get(company_id, {})
			best["initial_commodity_evidence_count"] = commodity_options.size()
			best["initial_story_evidence_count"] = story_options.size()
	return best


func _buy_position(company: Dictionary) -> Dictionary:
	var company_id: String = str(company.get("id", company.get("company_id", ""))).strip_edges()
	var current_price: float = max(float(company.get("current_price", company.get("starting_price", 0.0))), 1.0)
	var cash: float = float(RunState.player_portfolio.get("cash", 0.0))
	var target_value: float = max(cash * INVESTMENT_RATIO, current_price * 100.0)
	var shares: int = int(floor(target_value / current_price / 100.0)) * 100
	shares = max(shares, 100)
	var estimate: Dictionary = RunState.estimate_buy_order(company_id, shares)
	while shares > 100 and (not bool(estimate.get("success", false)) or float(estimate.get("total_cost", 0.0)) > cash):
		shares -= 100
		estimate = RunState.estimate_buy_order(company_id, shares)
	if not bool(estimate.get("success", false)):
		return estimate
	var result: Dictionary = RunState.buy_company(company_id, shares)
	result["shares"] = shares
	result["estimated_total_cost"] = float(estimate.get("total_cost", 0.0))
	result["estimated_fee"] = float(estimate.get("fee", 0.0))
	result["buy_price"] = current_price
	return result


func _create_thesis_with_evidence(company: Dictionary) -> Dictionary:
	var company_id: String = str(company.get("id", company.get("company_id", ""))).strip_edges()
	var thesis_result: Dictionary = GameManager.create_thesis(company_id, "bullish", "position", "Full-Year Scenario Thesis")
	if not bool(thesis_result.get("success", false)):
		return {"success": false, "message": str(thesis_result.get("message", ""))}
	var thesis_id: String = str(thesis_result.get("thesis", {}).get("id", ""))
	var attached_groups: Array = []
	var filing_capture_types: Array = []
	_capture_and_attach(thesis_id, _news_payload(company), "watch", attached_groups)
	_capture_and_attach(thesis_id, _commodity_payload(company), "support", attached_groups)
	_capture_and_attach(thesis_id, _story_payload(company), "support", attached_groups)
	for filing_payload_value in _annual_filing_payloads(company):
		if typeof(filing_payload_value) != TYPE_DICTIONARY:
			continue
		var filing_payload: Dictionary = filing_payload_value
		_capture_and_attach(thesis_id, filing_payload, "support", attached_groups)
		_append_unique_string(filing_capture_types, str(filing_payload.get("filing_capture_type", filing_payload.get("capture_level", ""))))
	var report_result: Dictionary = GameManager.generate_thesis_report(thesis_id)
	if not bool(report_result.get("success", false)):
		return {"success": false, "message": "Initial thesis report failed: %s" % str(report_result.get("message", ""))}
	return {
		"success": true,
		"thesis_id": thesis_id,
		"attached_groups": attached_groups,
		"initial_report_success": true,
		"annual_filing_company_id": company_id,
		"annual_filing_opened_bank": company_id == BANK_COMPANY_ID,
		"annual_filing_capture_types": filing_capture_types,
		"annual_filing_capture_count": filing_capture_types.size(),
		"annual_filing_profile_id": str(company.get("scenario_annual_filing_profile_id", "")),
		"annual_filing_visible_hash": str(company.get("scenario_annual_filing_visible_hash", ""))
	}


func _capture_and_attach(thesis_id: String, payload: Dictionary, interpretation: String, attached_groups: Array) -> void:
	if payload.is_empty():
		return
	var capture_result: Dictionary = GameManager.capture_research_evidence(payload)
	if not bool(capture_result.get("success", false)):
		return
	var evidence: Dictionary = capture_result.get("evidence", {})
	var attach_result: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(evidence.get("id", "")), interpretation)
	if bool(attach_result.get("success", false)):
		var group_id: String = str(attach_result.get("evidence", {}).get("provenance_group", evidence.get("provenance_group", "")))
		if not group_id.is_empty() and not attached_groups.has(group_id):
			attached_groups.append(group_id)


func _news_payload(company: Dictionary) -> Dictionary:
	var article: Dictionary = company.get("initial_news_article", {}) if typeof(company.get("initial_news_article", {})) == TYPE_DICTIONARY else {}
	if article.is_empty():
		return {}
	var news_controller = NEWS_CONTROLLER_SCRIPT.new()
	return news_controller._build_news_capture_payload(article, "headline_article")


func _commodity_payload(company: Dictionary) -> Dictionary:
	var company_id: String = str(company.get("id", company.get("company_id", ""))).strip_edges()
	var sector_id: String = str(company.get("sector_id", "")).strip_edges()
	for option_value in GameManager.get_commodity_macro_evidence_options(company_id, sector_id):
		if typeof(option_value) == TYPE_DICTIONARY:
			return option_value.duplicate(true)
	return {}


func _story_payload(company: Dictionary) -> Dictionary:
	var company_id: String = str(company.get("id", company.get("company_id", ""))).strip_edges()
	for option_value in GameManager.get_company_story_dossier_evidence_options(company_id):
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		if str(option.get("category", "")) == "network_intel":
			continue
		return option.duplicate(true)
	return {}


func _annual_filing_payloads(company: Dictionary) -> Array:
	var company_id: String = str(company.get("id", company.get("company_id", ""))).strip_edges()
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, true, true)
	var snapshot: Dictionary = definition.get("financial_statement_snapshot", {}) if typeof(definition.get("financial_statement_snapshot", {})) == TYPE_DICTIONARY else {}
	var annual: Dictionary = snapshot.get("annual_statement", {}) if typeof(snapshot.get("annual_statement", {})) == TYPE_DICTIONARY else {}
	if annual.is_empty():
		return []
	var document: Dictionary = ANNUAL_FILING_DOCUMENT_SCRIPT.get_or_build_document({}, annual, RunState.run_seed, company_id, {
		"company_name": str(company.get("name", "")),
		"ticker": str(company.get("ticker", "")),
		"sector_style_id": str(definition.get("sector_id", company.get("sector_id", "generic_annual_filing"))),
		"sector_id": str(definition.get("sector_id", company.get("sector_id", ""))),
		"subsector_id": str(definition.get("subsector_id", company.get("subsector_id", ""))),
		"business_summary": str(definition.get("business_summary", "")),
		"moat_tags": _variant_array(definition.get("moat_tags", [])),
		"story_hooks": _variant_array(definition.get("story_hooks", []))
	})
	if document.is_empty():
		return []
	company["scenario_annual_filing_profile_id"] = str(document.get("filing_profile_id", ""))
	company["scenario_annual_filing_visible_hash"] = str(document.get("visible_filing_hash", ""))
	company["scenario_annual_filing_story_note_fact_count"] = int(document.get("story_note_fact_packet_count", 0))
	company["scenario_annual_filing_story_note_prose_count"] = int(document.get("story_note_prose_count", 0))
	company["scenario_annual_filing_cache_status"] = str(document.get("cache_status", ""))
	company["scenario_annual_filing_generation_timing"] = str(document.get("generation_timing", ""))
	company["scenario_annual_filing_visible_section_count"] = int(document.get("visible_filing_section_count", 0))
	company["scenario_annual_filing_visible_table_count"] = int(document.get("visible_filing_table_count", 0))
	var payloads: Array = []
	var statement_payload: Dictionary = _annual_filing_statement_row_payload(company, annual, document)
	if not statement_payload.is_empty():
		payloads.append(statement_payload)
	var table_payload: Dictionary = _annual_filing_table_row_payload(company, annual, document)
	if not table_payload.is_empty():
		payloads.append(table_payload)
	var paragraph_payload: Dictionary = _annual_filing_risk_paragraph_payload(company, annual, document)
	if not paragraph_payload.is_empty():
		payloads.append(paragraph_payload)
	return payloads


func _annual_filing_statement_row_payload(company: Dictionary, annual: Dictionary, document: Dictionary) -> Dictionary:
	var company_id: String = str(company.get("id", company.get("company_id", ""))).strip_edges()
	var line: Dictionary = _annual_line(annual, "profit_or_loss_and_oci", "revenue")
	if line.is_empty():
		return {}
	return {
		"source_type": "financial_statement",
		"category": "financials",
		"company_id": company_id,
		"source_label": "Annual Filing",
		"label": str(line.get("label", "Revenue")),
		"value": "Annual revenue",
		"detail": "Revenue line from %s." % str(document.get("title", "the consolidated annual filing")),
		"source_excerpt": "%s from annual consolidated statement." % str(line.get("label", "Revenue")),
		"source_id": "full_year_scenario_annual_%s" % company_id,
		"statement_id": str(annual.get("statement_id", "")),
		"statement_period_label": str(annual.get("statement_period_label", "FY2019")),
		"statement_scope": "annual",
		"statement_consolidated": true,
		"statement_year": str(annual.get("statement_year", annual.get("fiscal_year", ""))),
		"line_id": str(line.get("line_id", "")),
		"statement_line_id": str(line.get("line_id", "")),
		"line_item_id": str(line.get("id", "")),
		"metric_id": str(line.get("metric_id", "")),
		"metric_ids": [str(line.get("metric_id", ""))],
		"raw_value": float(line.get("value", 0.0)),
		"filing_capture_type": "statement_row",
		"filing_excerpt_type": "statement_row",
		"filing_section_id": "profit_or_loss_and_oci",
		"filing_section_label": "Consolidated Statement of Profit or Loss and Other Comprehensive Income",
		"filing_excerpt_id": str(line.get("line_id", "revenue")),
		"filing_visible_label": str(line.get("label", "Revenue")),
		"filing_visible_text": "%s from annual consolidated statement." % str(line.get("label", "Revenue")),
		"provenance_group": "filing",
		"provenance_label": "Annual Filing",
		"provenance_surface": "annual_filing_reader",
		"provenance_origin": "visible_filing_document",
		"generated_content_surface": true,
		"generated_surface_id": "annual_filing_reader",
		"surface_id": "annual_filing_reader",
		"source_system_id": "annual_filing_document"
	}


func _annual_filing_table_row_payload(company: Dictionary, annual: Dictionary, document: Dictionary) -> Dictionary:
	var company_id: String = str(company.get("id", company.get("company_id", ""))).strip_edges()
	var period_label: String = str(annual.get("statement_period_label", "FY2019"))
	var row_context: Dictionary = _first_filing_table_row(document, [
		"note_bank_credit_risk",
		"note_bank_loans_financing",
		"note_bank_deposits",
		"note_bank_liquidity_risk",
		"note_segment_information",
		"note_financial_assets_receivables"
	])
	if row_context.is_empty():
		return {}
	var section: Dictionary = row_context.get("section", {}) if typeof(row_context.get("section", {})) == TYPE_DICTIONARY else {}
	var table: Dictionary = row_context.get("table", {}) if typeof(row_context.get("table", {})) == TYPE_DICTIONARY else {}
	var row: Dictionary = row_context.get("row", {}) if typeof(row_context.get("row", {})) == TYPE_DICTIONARY else {}
	var table_title: String = str(table.get("title", "Selected annual amounts")).strip_edges()
	var caption: String = str(row.get("caption", "")).strip_edges()
	var value_text: String = str(row.get("fy_value", "")).strip_edges()
	var related_note: String = str(row.get("related_note", "")).strip_edges()
	var visible_parts: Array = [caption]
	if not value_text.is_empty():
		visible_parts.append(value_text)
	if not related_note.is_empty():
		visible_parts.append(related_note)
	var visible_text: String = " | ".join(visible_parts)
	var source_story_note_fact_ids: Array = _string_array(row.get("source_story_note_fact_ids", []))
	var table_id: String = str(table.get("table_id", table.get("id", ""))).strip_edges()
	if table_id.is_empty():
		table_id = _node_token(table_title)
	var row_id: String = str(row.get("row_id", row.get("id", ""))).strip_edges()
	if row_id.is_empty():
		row_id = "row_%02d" % int(row_context.get("row_index", 1))
	return {
		"source_type": "financial_statement",
		"category": "financials",
		"company_id": company_id,
		"source_label": "Annual Filing",
		"label": caption if not caption.is_empty() else table_title,
		"value": value_text,
		"detail": "%s row from %s (%s)." % [caption if not caption.is_empty() else "Table", table_title, period_label],
		"source_id": "full_year_scenario_annual_%s_table_%s_row_%s" % [company_id, _node_token(table_id), _node_token(row_id)],
		"statement_id": str(annual.get("statement_id", "")),
		"statement_period_label": period_label,
		"statement_scope": "annual",
		"statement_consolidated": true,
		"statement_year": str(annual.get("statement_year", annual.get("fiscal_year", ""))),
		"capture_level": "note_table_row",
		"filing_capture_type": "note_table_row",
		"filing_excerpt_type": "note_table_row",
		"filing_section_id": str(section.get("section_id", "")),
		"filing_section_label": str(section.get("title", "Notes to the Consolidated Financial Statements")),
		"filing_excerpt_id": "%s:%s" % [table_id, row_id],
		"filing_visible_label": caption if not caption.is_empty() else table_title,
		"filing_visible_text": visible_text,
		"filing_table_id": table_id,
		"filing_table_title": table_title,
		"filing_table_row_id": row_id,
		"filing_table_row_caption": caption,
		"filing_table_row_value": value_text,
		"filing_table_reference": related_note,
		"source_excerpt": visible_text,
		"source_story_note_fact_ids": source_story_note_fact_ids,
		"story_note_fact_id": str(source_story_note_fact_ids[0]) if not source_story_note_fact_ids.is_empty() else "",
		"provenance_group": "filing",
		"provenance_label": "Annual Filing",
		"provenance_surface": "annual_filing_reader",
		"provenance_origin": "visible_filing_document",
		"generated_content_surface": true,
		"generated_surface_id": "annual_filing_reader",
		"surface_id": "annual_filing_reader",
		"source_system_id": "annual_filing_document"
	}


func _annual_filing_risk_paragraph_payload(company: Dictionary, annual: Dictionary, document: Dictionary) -> Dictionary:
	var company_id: String = str(company.get("id", company.get("company_id", ""))).strip_edges()
	var period_label: String = str(annual.get("statement_period_label", "FY2019"))
	var paragraph_context: Dictionary = _first_filing_paragraph(document, [
		"note_bank_credit_risk",
		"note_bank_liquidity_risk",
		"note_bank_capital_adequacy",
		"note_financial_risk_management",
		"note_commitments_contingencies"
	])
	if paragraph_context.is_empty():
		return {}
	var section: Dictionary = paragraph_context.get("section", {}) if typeof(paragraph_context.get("section", {})) == TYPE_DICTIONARY else {}
	var paragraph: Dictionary = paragraph_context.get("paragraph", {}) if typeof(paragraph_context.get("paragraph", {})) == TYPE_DICTIONARY else {}
	var paragraph_text: String = str(paragraph.get("text", "")).strip_edges()
	if paragraph_text.is_empty():
		return {}
	var source_story_note_fact_ids: Array = _string_array(paragraph.get("source_story_note_fact_ids", []))
	var paragraph_index: int = int(paragraph.get("paragraph_index", paragraph_context.get("paragraph_index", 1)))
	var paragraph_id: String = str(paragraph.get("paragraph_id", "")).strip_edges()
	if paragraph_id.is_empty():
		paragraph_id = "paragraph_%02d" % paragraph_index
	return {
		"source_type": "financial_statement",
		"category": "financials",
		"company_id": company_id,
		"source_label": "Annual Filing",
		"label": "%s paragraph %d" % [str(section.get("title", "Annual filing note")), paragraph_index],
		"value": paragraph_text,
		"detail": "Paragraph %d from %s (%s)." % [paragraph_index, str(section.get("title", "annual filing note")), period_label],
		"source_id": "full_year_scenario_annual_%s_%s_paragraph_%02d" % [company_id, _node_token(str(section.get("section_id", "note"))), paragraph_index],
		"statement_id": str(annual.get("statement_id", "")),
		"statement_period_label": period_label,
		"statement_scope": "annual",
		"statement_consolidated": true,
		"statement_year": str(annual.get("statement_year", annual.get("fiscal_year", ""))),
		"capture_level": "note_paragraph",
		"note_paragraph_id": paragraph_id,
		"note_paragraph_index": str(paragraph_index),
		"note_paragraph_role": str(paragraph.get("paragraph_role", "")),
		"note_paragraph_text": paragraph_text,
		"filing_capture_type": "note_paragraph",
		"filing_excerpt_type": "note_paragraph",
		"filing_section_id": str(section.get("section_id", "")),
		"filing_section_label": str(section.get("title", "Notes to the Consolidated Financial Statements")),
		"filing_excerpt_id": paragraph_id,
		"filing_visible_label": "%s paragraph %d" % [str(section.get("title", "Annual filing note")), paragraph_index],
		"filing_visible_text": paragraph_text,
		"source_excerpt": paragraph_text,
		"source_story_note_fact_ids": source_story_note_fact_ids,
		"story_note_fact_id": str(source_story_note_fact_ids[0]) if not source_story_note_fact_ids.is_empty() else "",
		"provenance_group": "filing",
		"provenance_label": "Annual Filing",
		"provenance_surface": "annual_filing_reader",
		"provenance_origin": "visible_filing_document",
		"generated_content_surface": true,
		"generated_surface_id": "annual_filing_reader",
		"surface_id": "annual_filing_reader",
		"source_system_id": "annual_filing_document"
	}


func _first_filing_table_row(document: Dictionary, preferred_section_ids: Array) -> Dictionary:
	var sections_by_id: Dictionary = document.get("visible_filing_sections_by_id", {}) if typeof(document.get("visible_filing_sections_by_id", {})) == TYPE_DICTIONARY else {}
	for section_id_value in preferred_section_ids:
		var section_id: String = str(section_id_value)
		var section: Dictionary = sections_by_id.get(section_id, {}) if typeof(sections_by_id.get(section_id, {})) == TYPE_DICTIONARY else {}
		var context: Dictionary = _first_table_row_in_section(section)
		if not context.is_empty():
			return context
	for section_value in _variant_array(document.get("visible_filing_sections", [])):
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var fallback_context: Dictionary = _first_table_row_in_section(section_value)
		if not fallback_context.is_empty():
			return fallback_context
	return {}


func _first_table_row_in_section(section: Dictionary) -> Dictionary:
	if section.is_empty():
		return {}
	for table_value in _variant_array(section.get("compact_tables", [])):
		if typeof(table_value) != TYPE_DICTIONARY:
			continue
		var table: Dictionary = table_value
		var row_index: int = 1
		for row_value in _variant_array(table.get("rows", [])):
			if typeof(row_value) == TYPE_DICTIONARY:
				return {
					"section": section,
					"table": table,
					"row": row_value,
					"row_index": row_index
				}
			row_index += 1
	return {}


func _first_filing_paragraph(document: Dictionary, preferred_section_ids: Array) -> Dictionary:
	var sections_by_id: Dictionary = document.get("visible_filing_sections_by_id", {}) if typeof(document.get("visible_filing_sections_by_id", {})) == TYPE_DICTIONARY else {}
	for section_id_value in preferred_section_ids:
		var section_id: String = str(section_id_value)
		var section: Dictionary = sections_by_id.get(section_id, {}) if typeof(sections_by_id.get(section_id, {})) == TYPE_DICTIONARY else {}
		var context: Dictionary = _first_paragraph_in_section(section)
		if not context.is_empty():
			return context
	for section_value in _variant_array(document.get("visible_filing_sections", [])):
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var fallback_context: Dictionary = _first_paragraph_in_section(section_value)
		if not fallback_context.is_empty():
			return fallback_context
	return {}


func _first_paragraph_in_section(section: Dictionary) -> Dictionary:
	if section.is_empty():
		return {}
	var paragraph_index: int = 1
	for paragraph_value in _variant_array(section.get("paragraphs", [])):
		if typeof(paragraph_value) == TYPE_DICTIONARY and not str(paragraph_value.get("text", "")).strip_edges().is_empty():
			return {
				"section": section,
				"paragraph": paragraph_value,
				"paragraph_index": paragraph_index
			}
		paragraph_index += 1
	return {}


func _default_metrics(company_id: String) -> Dictionary:
	return {
		"scenario_company_id": company_id,
		"days_completed": 0,
		"scheduled_events": 0,
		"company_events": 0,
		"quarterly_report_events": 0,
		"corporate_action_events": 0,
		"index_review_events": 0,
		"special_events": 0,
		"network_request_results": 0,
		"network_tip_results": 0,
		"dirty_tip_offers": 0,
		"dirty_tip_results": 0,
		"event_id_counts": {},
		"event_family_counts": {},
		"corporate_category_counts": {},
		"attention_tier_counts": {},
		"attention_lane_counts": {},
		"attention_focus_days": 0,
		"attention_force_special_days": 0,
		"attention_force_company_arc_days": 0,
		"attention_suppressed_special_days": 0,
		"attention_best_score_total": 0.0,
		"attention_market_stress_total": 0.0,
		"attention_dirty_pressure_total": 0.0,
		"gorengan_seen_ids": {},
		"gorengan_started": 0,
		"gorengan_dump_seen": 0,
		"gorengan_successful": 0,
		"price_exposure_active_stock_days": 0,
		"price_exposure_total_drift": 0.0,
		"price_exposure_total_abs_drift": 0.0
	}


func _collect_day_metrics(day_result: Dictionary, metrics: Dictionary) -> void:
	var scheduled_event: Dictionary = day_result.get("scheduled_event", {}) if typeof(day_result.get("scheduled_event", {})) == TYPE_DICTIONARY else {}
	if not scheduled_event.is_empty():
		metrics["scheduled_events"] = int(metrics.get("scheduled_events", 0)) + 1
		_count_event(scheduled_event, metrics)
	_count_event_array(day_result.get("report_events", []), "company_events", metrics)
	_count_event_array(day_result.get("corporate_action_events", []), "corporate_action_events", metrics)
	_count_event_array(day_result.get("index_review_events", []), "index_review_events", metrics)
	_count_event_array(day_result.get("special_events", []), "special_events", metrics)
	metrics["network_request_results"] = int(metrics.get("network_request_results", 0)) + _variant_array(day_result.get("network_request_results", [])).size()
	metrics["network_tip_results"] = int(metrics.get("network_tip_results", 0)) + _variant_array(day_result.get("network_tip_results", [])).size()
	metrics["dirty_tip_results"] = int(metrics.get("dirty_tip_results", 0)) + _variant_array(day_result.get("dirty_tip_results", [])).size()
	if typeof(day_result.get("dirty_tip_offer", {})) == TYPE_DICTIONARY and not Dictionary(day_result.get("dirty_tip_offer", {})).is_empty():
		metrics["dirty_tip_offers"] = int(metrics.get("dirty_tip_offers", 0)) + 1
	_collect_attention(day_result.get("attention_directives", {}), metrics)


func _count_event_array(rows_value: Variant, counter_key: String, metrics: Dictionary) -> void:
	for row_value in _variant_array(rows_value):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		metrics[counter_key] = int(metrics.get(counter_key, 0)) + 1
		if bool(row.get("quarterly_report", false)):
			metrics["quarterly_report_events"] = int(metrics.get("quarterly_report_events", 0)) + 1
		if counter_key == "corporate_action_events":
			_increment_count(metrics.get("corporate_category_counts", {}), str(row.get("category", row.get("event_id", ""))))
		_count_event(row, metrics)


func _count_event(row: Dictionary, metrics: Dictionary) -> void:
	_increment_count(metrics.get("event_id_counts", {}), str(row.get("event_id", row.get("id", "unknown"))))
	_increment_count(metrics.get("event_family_counts", {}), str(row.get("event_family", row.get("family", row.get("scope", "unknown")))))


func _collect_attention(value: Variant, metrics: Dictionary) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		return
	var attention: Dictionary = value
	_increment_count(metrics.get("attention_tier_counts", {}), str(attention.get("attention_tier", "unknown")))
	_increment_count(metrics.get("attention_lane_counts", {}), str(attention.get("selected_lane", "unknown")))
	var focus_ids: Array = _string_array(attention.get("focus_company_ids", []))
	if focus_ids.has(str(metrics.get("scenario_company_id", ""))):
		metrics["attention_focus_days"] = int(metrics.get("attention_focus_days", 0)) + 1
	if bool(attention.get("force_special_event", false)):
		metrics["attention_force_special_days"] = int(metrics.get("attention_force_special_days", 0)) + 1
	if bool(attention.get("force_company_arc_start", false)):
		metrics["attention_force_company_arc_days"] = int(metrics.get("attention_force_company_arc_days", 0)) + 1
	if bool(attention.get("suppress_special_event", false)):
		metrics["attention_suppressed_special_days"] = int(metrics.get("attention_suppressed_special_days", 0)) + 1
	metrics["attention_best_score_total"] = float(metrics.get("attention_best_score_total", 0.0)) + float(attention.get("best_company_attention_score", 0.0))
	metrics["attention_market_stress_total"] = float(metrics.get("attention_market_stress_total", 0.0)) + float(attention.get("market_stress_score", 0.0))
	metrics["attention_dirty_pressure_total"] = float(metrics.get("attention_dirty_pressure_total", 0.0)) + float(attention.get("dirty_market_pressure", 0.0))


func _collect_gorengan_snapshot(metrics: Dictionary) -> void:
	var seen: Dictionary = metrics.get("gorengan_seen_ids", {})
	var dump_seen: int = 0
	var successful: int = 0
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = RunState.get_company(company_id)
		var campaign_value: Variant = runtime.get("gorengan_campaign", {})
		if typeof(campaign_value) != TYPE_DICTIONARY:
			continue
		var campaign: Dictionary = campaign_value
		if campaign.is_empty():
			continue
		var key: String = "%s|%s" % [company_id, str(campaign.get("campaign_id", campaign.get("started_day_index", "")))]
		seen[key] = true
		if ["dump", "dead_cat", "cooldown"].has(str(campaign.get("phase", ""))):
			dump_seen += 1
		if float(campaign.get("realized_return_pct", campaign.get("max_realized_return_pct", 0.0))) >= 200.0 and dump_seen > 0:
			successful += 1
	metrics["gorengan_seen_ids"] = seen
	metrics["gorengan_started"] = seen.size()
	metrics["gorengan_dump_seen"] = max(int(metrics.get("gorengan_dump_seen", 0)), dump_seen)
	metrics["gorengan_successful"] = max(int(metrics.get("gorengan_successful", 0)), successful)


func _collect_price_exposure_snapshot(metrics: Dictionary) -> void:
	for company_id_value in RunState.company_order:
		var runtime: Dictionary = RunState.get_company(str(company_id_value))
		var context: Dictionary = runtime.get("price_exposure_context", {}) if typeof(runtime.get("price_exposure_context", {})) == TYPE_DICTIONARY else {}
		if context.is_empty():
			continue
		var drift: float = clamp(float(context.get("exposure_drift_adjustment", 0.0)), -0.004, 0.004)
		metrics["price_exposure_active_stock_days"] = int(metrics.get("price_exposure_active_stock_days", 0)) + 1
		metrics["price_exposure_total_drift"] = float(metrics.get("price_exposure_total_drift", 0.0)) + drift
		metrics["price_exposure_total_abs_drift"] = float(metrics.get("price_exposure_total_abs_drift", 0.0)) + absf(drift)


func _build_report(
	company: Dictionary,
	buy_result: Dictionary,
	thesis_result: Dictionary,
	initial_prices: Dictionary,
	metrics: Dictionary,
	final_report_result: Dictionary,
	elapsed_msec: float
) -> Dictionary:
	var company_id: String = str(company.get("id", company.get("company_id", ""))).strip_edges()
	var stock_report: Dictionary = _stock_report(initial_prices)
	var holdings: Dictionary = RunState.player_portfolio.get("holdings", {}) if typeof(RunState.player_portfolio.get("holdings", {})) == TYPE_DICTIONARY else {}
	var holding: Dictionary = holdings.get(company_id, {}) if typeof(holdings.get(company_id, {})) == TYPE_DICTIONARY else {}
	var final_company: Dictionary = GameManager.get_company_snapshot(company_id, true, true, true)
	var final_price: float = float(final_company.get("current_price", company.get("current_price", 0.0)))
	var buy_price: float = max(float(buy_result.get("buy_price", company.get("current_price", 0.0))), 1.0)
	var held_return_pct: float = ((final_price - buy_price) / buy_price) * 100.0
	var days: int = max(int(metrics.get("days_completed", 0)), 1)
	var thesis: Dictionary = RunState.get_player_thesis(str(thesis_result.get("thesis_id", "")))
	var final_news_snapshot: Dictionary = GameManager.get_news_snapshot()
	var report: Dictionary = {
		"success": true,
		"seed": RUN_SEED,
		"requested_trading_days": TRADING_DAYS,
		"days_completed": int(metrics.get("days_completed", 0)),
		"final_day_index": RunState.day_index,
		"final_trade_date": RunState.get_current_trade_date(),
		"elapsed_msec": _round_to(elapsed_msec, 2),
		"game_launch": {
			"scene": "res://scenes/game/GameRoot.tscn",
			"validated_controls": ["StockAppButton", "NewsAppButton", "ThesisAppButton", "DesktopAdvanceDayButton"]
		},
		"player_action": {
			"bought_company_id": company_id,
			"ticker": str(company.get("ticker", "")),
			"name": str(company.get("name", "")),
			"selection_score": _round_to(float(company.get("selection_score", 0.0)), 2),
			"selection_reason": str(company.get("selection_reason", "")),
			"shares_bought": int(buy_result.get("shares", 0)),
			"buy_price": _round_to(buy_price, 2),
			"buy_cost": _round_to(float(buy_result.get("estimated_total_cost", 0.0)), 2),
			"final_price": _round_to(final_price, 2),
			"held_return_pct": _round_to(held_return_pct, 2),
			"holding_shares_end": int(holding.get("shares", 0)),
			"holding_average_price_end": _round_to(float(holding.get("average_price", 0.0)), 2)
		},
		"portfolio": {
			"cash": _round_to(float(RunState.player_portfolio.get("cash", 0.0)), 2),
			"market_value": _round_to(RunState.get_portfolio_market_value(), 2),
			"equity": _round_to(RunState.get_total_equity(), 2),
			"realized_pnl": _round_to(float(RunState.player_portfolio.get("realized_pnl", 0.0)), 2),
			"holdings_count": holdings.size()
		},
		"thesis": {
			"thesis_id": str(thesis_result.get("thesis_id", "")),
			"attached_groups": thesis_result.get("attached_groups", []),
			"evidence_count": _variant_array(thesis.get("evidence", [])).size(),
			"final_report_success": bool(final_report_result.get("success", false)),
			"final_report_message": str(final_report_result.get("message", ""))
		},
		"annual_filing": {
			"opened_company_id": str(thesis_result.get("annual_filing_company_id", "")),
			"opened_bank_filing": bool(thesis_result.get("annual_filing_opened_bank", false)),
			"profile_id": str(thesis_result.get("annual_filing_profile_id", "")),
			"visible_filing_hash": str(thesis_result.get("annual_filing_visible_hash", "")),
			"story_note_fact_count": int(company.get("scenario_annual_filing_story_note_fact_count", 0)),
			"story_note_prose_count": int(company.get("scenario_annual_filing_story_note_prose_count", 0)),
			"cache_status": str(company.get("scenario_annual_filing_cache_status", "")),
			"generation_timing": str(company.get("scenario_annual_filing_generation_timing", "")),
			"visible_section_count": int(company.get("scenario_annual_filing_visible_section_count", 0)),
			"visible_table_count": int(company.get("scenario_annual_filing_visible_table_count", 0)),
			"capture_types": thesis_result.get("annual_filing_capture_types", []),
			"capture_count": int(thesis_result.get("annual_filing_capture_count", 0))
		},
		"stocks": stock_report,
		"events": {
			"scheduled_events": int(metrics.get("scheduled_events", 0)),
			"company_events": int(metrics.get("company_events", 0)),
			"quarterly_report_events": int(metrics.get("quarterly_report_events", 0)),
			"corporate_action_events": int(metrics.get("corporate_action_events", 0)),
			"index_review_events": int(metrics.get("index_review_events", 0)),
			"special_events": int(metrics.get("special_events", 0)),
			"dirty_tip_offers": int(metrics.get("dirty_tip_offers", 0)),
			"dirty_tip_results": int(metrics.get("dirty_tip_results", 0)),
			"network_request_results": int(metrics.get("network_request_results", 0)),
			"network_tip_results": int(metrics.get("network_tip_results", 0)),
			"top_event_id_counts": _top_count_rows(metrics.get("event_id_counts", {}), 12),
			"event_family_counts": metrics.get("event_family_counts", {}),
			"corporate_category_counts": metrics.get("corporate_category_counts", {})
		},
		"gorengan": {
			"started": int(metrics.get("gorengan_started", 0)),
			"dump_seen_active_count_peak": int(metrics.get("gorengan_dump_seen", 0)),
			"successful_active_count_peak": int(metrics.get("gorengan_successful", 0))
		},
		"attention_director": {
			"tier_counts": metrics.get("attention_tier_counts", {}),
			"lane_counts": metrics.get("attention_lane_counts", {}),
			"scenario_company_focus_days": int(metrics.get("attention_focus_days", 0)),
			"force_special_days": int(metrics.get("attention_force_special_days", 0)),
			"force_company_arc_days": int(metrics.get("attention_force_company_arc_days", 0)),
			"suppressed_special_days": int(metrics.get("attention_suppressed_special_days", 0)),
			"avg_best_company_attention_score": _round_to(float(metrics.get("attention_best_score_total", 0.0)) / float(days), 4),
			"avg_market_stress_score": _round_to(float(metrics.get("attention_market_stress_total", 0.0)) / float(days), 4),
			"avg_dirty_market_pressure": _round_to(float(metrics.get("attention_dirty_pressure_total", 0.0)) / float(days), 4)
		},
		"price_exposure": {
			"active_stock_days": int(metrics.get("price_exposure_active_stock_days", 0)),
			"avg_drift_bps": _round_to((float(metrics.get("price_exposure_total_drift", 0.0)) * 10000.0) / float(max(int(metrics.get("price_exposure_active_stock_days", 0)), 1)), 4),
			"avg_abs_drift_bps": _round_to((float(metrics.get("price_exposure_total_abs_drift", 0.0)) * 10000.0) / float(max(int(metrics.get("price_exposure_active_stock_days", 0)), 1)), 4)
		},
		"news": _news_snapshot_metrics(final_news_snapshot)
	}
	return report


func _validate_report(report: Dictionary) -> String:
	if int(report.get("days_completed", 0)) != TRADING_DAYS:
		return "Expected %d completed trading days." % TRADING_DAYS
	if int(report.get("portfolio", {}).get("holdings_count", 0)) < 1:
		return "Expected player to keep at least one holding."
	if int(report.get("thesis", {}).get("evidence_count", 0)) < 2:
		return "Expected thesis to contain at least two evidence rows."
	if not bool(report.get("thesis", {}).get("final_report_success", false)):
		return "Expected final thesis report generation to succeed."
	var filing: Dictionary = report.get("annual_filing", {}) if typeof(report.get("annual_filing", {})) == TYPE_DICTIONARY else {}
	if not bool(filing.get("opened_bank_filing", false)):
		return "Expected full-year scenario to open a bank annual filing."
	if str(filing.get("profile_id", "")) != "bank":
		return "Expected full-year scenario annual filing profile to be bank."
	var capture_types: Array = _string_array(filing.get("capture_types", []))
	if not capture_types.has("note_table_row"):
		return "Expected full-year scenario to capture an annual filing table row."
	if not capture_types.has("note_paragraph"):
		return "Expected full-year scenario to capture an annual filing note/risk paragraph."
	if int(filing.get("story_note_fact_count", 0)) <= 0:
		return "Expected full-year scenario annual filing to include story-note fact packets."
	if str(filing.get("generation_timing", "")) != "lazy_on_request":
		return "Expected full-year scenario annual filing to stay lazy-on-request."
	return ""


func _stock_report(initial_prices: Dictionary) -> Dictionary:
	var rows: Array = []
	var returns: Array = []
	var advancers: int = 0
	var decliners: int = 0
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = RunState.get_company(company_id)
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		var start_price: float = max(float(initial_prices.get(company_id, runtime.get("starting_price", 0.0))), 1.0)
		var final_price: float = float(runtime.get("current_price", start_price))
		var return_pct: float = ((final_price - start_price) / start_price) * 100.0
		returns.append(return_pct)
		if return_pct > 0.0:
			advancers += 1
		elif return_pct < 0.0:
			decliners += 1
		rows.append({
			"company_id": company_id,
			"ticker": str(definition.get("ticker", company_id.to_upper())),
			"name": str(definition.get("name", "")),
			"sector_id": str(definition.get("sector_id", "")),
			"start_price": _round_to(start_price, 2),
			"final_price": _round_to(final_price, 2),
			"return_pct": _round_to(return_pct, 2),
			"high_return_pct": _round_to(_high_return_pct(runtime, start_price), 2),
			"last_daily_change_pct": _round_to(float(runtime.get("daily_change_pct", 0.0)) * 100.0, 2)
		})
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return float(left.get("return_pct", 0.0)) > float(right.get("return_pct", 0.0))
	)
	var worst: Dictionary = rows[rows.size() - 1] if not rows.is_empty() else {}
	return {
		"company_count": rows.size(),
		"advancers": advancers,
		"decliners": decliners,
		"flat": max(rows.size() - advancers - decliners, 0),
		"average_return_pct": _round_to(_average(returns), 2),
		"median_return_pct": _round_to(_median(returns), 2),
		"best_stock": rows[0] if not rows.is_empty() else {},
		"worst_stock": worst,
		"top_5": rows.slice(0, min(rows.size(), 5)),
		"bottom_5": rows.slice(max(rows.size() - 5, 0), rows.size())
	}


func _news_snapshot_metrics(snapshot: Dictionary) -> Dictionary:
	var outlet_counts: Dictionary = {}
	var topic_counts: Dictionary = {}
	var articles: Array = _all_news_articles(snapshot)
	for article_value in articles:
		if typeof(article_value) != TYPE_DICTIONARY:
			continue
		var article: Dictionary = article_value
		_increment_count(outlet_counts, str(article.get("outlet_id", "unknown")))
		for topic_id in _string_array(article.get("topic_ids", [])):
			_increment_count(topic_counts, str(topic_id))
	return {
		"article_count": articles.size(),
		"outlet_counts": outlet_counts,
		"top_topic_counts": _top_count_rows(topic_counts, 10)
	}


func _news_by_company_id(snapshot: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for article_value in _all_news_articles(snapshot):
		if typeof(article_value) != TYPE_DICTIONARY:
			continue
		var article: Dictionary = article_value
		var company_id: String = str(article.get("target_company_id", article.get("company_id", ""))).strip_edges()
		if company_id.is_empty() or result.has(company_id):
			continue
		result[company_id] = article.duplicate(true)
	return result


func _all_news_articles(snapshot: Dictionary) -> Array:
	var rows: Array = []
	var feeds: Dictionary = snapshot.get("feeds", {}) if typeof(snapshot.get("feeds", {})) == TYPE_DICTIONARY else {}
	for feed_value in feeds.values():
		if typeof(feed_value) != TYPE_DICTIONARY:
			continue
		var feed: Dictionary = feed_value
		for article_value in _variant_array(feed.get("articles", [])):
			if typeof(article_value) == TYPE_DICTIONARY:
				rows.append(article_value)
	return rows


func _initial_price_lookup() -> Dictionary:
	var result: Dictionary = {}
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = RunState.get_company(company_id)
		result[company_id] = float(runtime.get("current_price", runtime.get("starting_price", 0.0)))
	return result


func _annual_line(annual: Dictionary, section_id: String, metric_id: String) -> Dictionary:
	for row_value in _variant_array(annual.get(section_id, [])):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("metric_id", row.get("id", ""))) == metric_id:
			return row.duplicate(true)
	for row_value in _variant_array(annual.get(section_id, [])):
		if typeof(row_value) == TYPE_DICTIONARY:
			return row_value.duplicate(true)
	return {}


func _high_return_pct(runtime: Dictionary, start_price: float) -> float:
	var high_price: float = start_price
	for bar_value in _variant_array(runtime.get("price_history", [])):
		if typeof(bar_value) != TYPE_DICTIONARY:
			continue
		var bar: Dictionary = bar_value
		high_price = max(high_price, float(bar.get("close", bar.get("price", start_price))))
	return ((high_price - start_price) / max(start_price, 1.0)) * 100.0


func _increment_count(counts: Dictionary, key: String) -> void:
	var normalized_key: String = key.strip_edges()
	if normalized_key.is_empty():
		normalized_key = "unknown"
	counts[normalized_key] = int(counts.get(normalized_key, 0)) + 1


func _top_count_rows(counts_value: Variant, limit: int) -> Array:
	if typeof(counts_value) != TYPE_DICTIONARY:
		return []
	var rows: Array = []
	var counts: Dictionary = counts_value
	for key_value in counts.keys():
		rows.append({"id": str(key_value), "count": int(counts.get(key_value, 0))})
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if int(left.get("count", 0)) == int(right.get("count", 0)):
			return str(left.get("id", "")) < str(right.get("id", ""))
		return int(left.get("count", 0)) > int(right.get("count", 0))
	)
	return rows.slice(0, min(rows.size(), limit))


func _variant_array(value: Variant) -> Array:
	return value if typeof(value) == TYPE_ARRAY else []


func _string_array(value: Variant) -> Array:
	var source: Array = value if typeof(value) == TYPE_ARRAY else [value]
	var result: Array = []
	var seen: Dictionary = {}
	for item_value in source:
		var item: String = str(item_value).strip_edges()
		if item.is_empty() or seen.has(item):
			continue
		seen[item] = true
		result.append(item)
	return result


func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())


func _median(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var sorted_values: Array = values.duplicate()
	sorted_values.sort()
	var middle: int = sorted_values.size() / 2
	if sorted_values.size() % 2 == 1:
		return float(sorted_values[middle])
	return (float(sorted_values[middle - 1]) + float(sorted_values[middle])) / 2.0


func _round_to(value: float, decimals: int) -> float:
	var factor: float = pow(10.0, float(decimals))
	return round(value * factor) / factor


func _write_test_log(report: Dictionary) -> String:
	var file := FileAccess.open(TEST_LOG_PATH, FileAccess.WRITE)
	if file == null:
		return "Could not write full-year annual filing test log to %s. error=%s" % [TEST_LOG_PATH, str(FileAccess.get_open_error())]
	file.store_string(_markdown_report(report))
	file.close()
	return ""


func _markdown_report(report: Dictionary) -> String:
	var player_action: Dictionary = report.get("player_action", {}) if typeof(report.get("player_action", {})) == TYPE_DICTIONARY else {}
	var portfolio: Dictionary = report.get("portfolio", {}) if typeof(report.get("portfolio", {})) == TYPE_DICTIONARY else {}
	var thesis: Dictionary = report.get("thesis", {}) if typeof(report.get("thesis", {})) == TYPE_DICTIONARY else {}
	var filing: Dictionary = report.get("annual_filing", {}) if typeof(report.get("annual_filing", {})) == TYPE_DICTIONARY else {}
	var events: Dictionary = report.get("events", {}) if typeof(report.get("events", {})) == TYPE_DICTIONARY else {}
	var stocks: Dictionary = report.get("stocks", {}) if typeof(report.get("stocks", {})) == TYPE_DICTIONARY else {}
	var best_stock: Dictionary = stocks.get("best_stock", {}) if typeof(stocks.get("best_stock", {})) == TYPE_DICTIONARY else {}
	var worst_stock: Dictionary = stocks.get("worst_stock", {}) if typeof(stocks.get("worst_stock", {})) == TYPE_DICTIONARY else {}
	var attention: Dictionary = report.get("attention_director", {}) if typeof(report.get("attention_director", {})) == TYPE_DICTIONARY else {}
	var gorengan: Dictionary = report.get("gorengan", {}) if typeof(report.get("gorengan", {})) == TYPE_DICTIONARY else {}
	var lines: Array[String] = []
	lines.append("# Annual Filing Sector Realism Full-Year Player Scenario")
	lines.append("")
	lines.append("## Run")
	lines.append("- Seed: `%s`" % str(report.get("seed", "")))
	lines.append("- Trading days completed: `%s/%s`" % [str(report.get("days_completed", 0)), str(report.get("requested_trading_days", 0))])
	lines.append("- Final trade date: `%s`" % JSON.stringify(report.get("final_trade_date", {})))
	lines.append("- Elapsed: `%sms`" % str(report.get("elapsed_msec", "")))
	lines.append("")
	lines.append("## Player Action")
	lines.append("- Bought: `%s` `%s` (%s)" % [
		str(player_action.get("ticker", "")),
		str(player_action.get("bought_company_id", "")),
		str(player_action.get("name", ""))
	])
	lines.append("- Shares: `%s` at `%s`, final price `%s`, held return `%s%%`" % [
		str(player_action.get("shares_bought", 0)),
		str(player_action.get("buy_price", 0)),
		str(player_action.get("final_price", 0)),
		str(player_action.get("held_return_pct", 0))
	])
	lines.append("- Selection reason: %s" % str(player_action.get("selection_reason", "")))
	lines.append("")
	lines.append("## Annual Filing Evidence")
	lines.append("- Opened bank filing: `%s`" % str(filing.get("opened_bank_filing", false)))
	lines.append("- Opened company: `%s`" % str(filing.get("opened_company_id", "")))
	lines.append("- Filing profile: `%s`" % str(filing.get("profile_id", "")))
	lines.append("- Visible filing hash: `%s`" % str(filing.get("visible_filing_hash", "")))
	lines.append("- Generation timing/cache: `%s` / `%s`" % [
		str(filing.get("generation_timing", "")),
		str(filing.get("cache_status", ""))
	])
	lines.append("- Visible sections/tables: `%s` / `%s`" % [
		str(filing.get("visible_section_count", 0)),
		str(filing.get("visible_table_count", 0))
	])
	lines.append("- Story-note facts/prose: `%s` / `%s`" % [
		str(filing.get("story_note_fact_count", 0)),
		str(filing.get("story_note_prose_count", 0))
	])
	lines.append("- Captures attached: `%s`" % str(filing.get("capture_count", 0)))
	lines.append("- Capture types: `%s`" % ", ".join(_string_array(filing.get("capture_types", []))))
	lines.append("")
	lines.append("## Thesis")
	lines.append("- Thesis id: `%s`" % str(thesis.get("thesis_id", "")))
	lines.append("- Evidence count: `%s`" % str(thesis.get("evidence_count", 0)))
	lines.append("- Final report success: `%s`" % str(thesis.get("final_report_success", false)))
	lines.append("- Attached provenance groups: `%s`" % ", ".join(_string_array(thesis.get("attached_groups", []))))
	lines.append("")
	lines.append("## Portfolio")
	lines.append("- Cash: `%s`" % str(portfolio.get("cash", 0)))
	lines.append("- Market value: `%s`" % str(portfolio.get("market_value", 0)))
	lines.append("- Equity: `%s`" % str(portfolio.get("equity", 0)))
	lines.append("- Holdings count: `%s`" % str(portfolio.get("holdings_count", 0)))
	lines.append("")
	lines.append("## Market")
	lines.append("- Best stock: `%s` `%s` return `%s%%`" % [
		str(best_stock.get("ticker", "")),
		str(best_stock.get("company_id", "")),
		str(best_stock.get("return_pct", 0))
	])
	lines.append("- Worst stock: `%s` `%s` return `%s%%`" % [
		str(worst_stock.get("ticker", "")),
		str(worst_stock.get("company_id", "")),
		str(worst_stock.get("return_pct", 0))
	])
	lines.append("- Average return: `%s%%`; median return: `%s%%`; advancers/decliners: `%s/%s`" % [
		str(stocks.get("average_return_pct", 0)),
		str(stocks.get("median_return_pct", 0)),
		str(stocks.get("advancers", 0)),
		str(stocks.get("decliners", 0))
	])
	lines.append("")
	lines.append("## Events")
	lines.append("- Scheduled/company/corporate/index/special: `%s/%s/%s/%s/%s`" % [
		str(events.get("scheduled_events", 0)),
		str(events.get("company_events", 0)),
		str(events.get("corporate_action_events", 0)),
		str(events.get("index_review_events", 0)),
		str(events.get("special_events", 0))
	])
	lines.append("- Dirty tip offers/results: `%s/%s`" % [str(events.get("dirty_tip_offers", 0)), str(events.get("dirty_tip_results", 0))])
	lines.append("- Network request/tip results: `%s/%s`" % [str(events.get("network_request_results", 0)), str(events.get("network_tip_results", 0))])
	lines.append("- Top event IDs: `%s`" % JSON.stringify(events.get("top_event_id_counts", [])))
	lines.append("")
	lines.append("## Gorengan And Attention")
	lines.append("- Gorengan started/dump peak/success peak: `%s/%s/%s`" % [
		str(gorengan.get("started", 0)),
		str(gorengan.get("dump_seen_active_count_peak", 0)),
		str(gorengan.get("successful_active_count_peak", 0))
	])
	lines.append("- Attention tier counts: `%s`" % JSON.stringify(attention.get("tier_counts", {})))
	lines.append("- Attention lane counts: `%s`" % JSON.stringify(attention.get("lane_counts", {})))
	lines.append("- Scenario focus days: `%s`" % str(attention.get("scenario_company_focus_days", 0)))
	lines.append("")
	lines.append("## Raw Summary")
	lines.append("```json")
	lines.append(JSON.stringify(report, "\t"))
	lines.append("```")
	lines.append("")
	return "\n".join(lines)


func _append_unique_string(target: Array, value: String) -> void:
	var clean: String = value.strip_edges()
	if clean.is_empty() or target.has(clean):
		return
	target.append(clean)


func _node_token(text: String) -> String:
	var token: String = text.strip_edges().to_lower()
	for ch in [" ", "-", ".", "/", "\\", ":", "|", "(", ")", "[", "]", "{", "}", ",", ";", "'", "\"", "&"]:
		token = token.replace(ch, "_")
	while token.find("__") != -1:
		token = token.replace("__", "_")
	token = token.strip_edges()
	return token.trim_prefix("_").trim_suffix("_")


func _wait_frames(count: int) -> void:
	for _index: int in range(max(count, 0)):
		await get_tree().process_frame


func _fail(message: String) -> void:
	push_error(message)
	print("FULL_YEAR_PLAYER_SCENARIO_FAIL: %s" % message)
	get_tree().quit(1)
