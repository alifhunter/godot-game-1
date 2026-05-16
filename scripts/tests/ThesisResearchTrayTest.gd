extends Node

const RUN_SEED := 516226


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0

	if not RunState.get_thesis_research_tray().is_empty():
		_fail("Thesis research tray should start empty on a fresh run.")
		return
	var company_id: String = str(RunState.company_order[0])
	var company: Dictionary = GameManager.get_company_snapshot(company_id, true, true, true)
	var ap_before_capture: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var capture_result: Dictionary = GameManager.capture_research_evidence({
		"source_type": "key_stats",
		"company_id": company_id,
		"label": "Market Cap",
		"value": "Rp1.00T",
		"detail": "Company size anchors what kind of upside story is realistic.",
		"source_id": "test_market_cap"
	})
	if not bool(capture_result.get("success", false)):
		_fail("Expected Key Stats evidence capture to succeed: %s" % str(capture_result.get("message", "")))
		return
	if int(GameManager.get_daily_action_snapshot().get("used", 0)) != ap_before_capture:
		_fail("Capturing research evidence should not spend AP.")
		return
	var evidence_id: String = str(capture_result.get("evidence", {}).get("id", ""))
	var tray_snapshot: Dictionary = GameManager.get_research_tray_snapshot(company_id)
	if evidence_id.is_empty() or tray_snapshot.get("rows", []).size() != 1:
		_fail("Expected captured Market Cap row to appear in the Research Tray.")
		return
	var duplicate_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "key_stats",
		"company_id": company_id,
		"label": "Market Cap",
		"value": "Rp1.00T",
		"detail": "Company size anchors what kind of upside story is realistic.",
		"source_id": "test_market_cap"
	})
	if not bool(duplicate_capture.get("success", false)) or str(duplicate_capture.get("message", "")) != "Already in Research Tray.":
		_fail("Expected duplicate Key Stats capture to return the existing Research Tray row.")
		return
	if str(duplicate_capture.get("evidence", {}).get("id", "")) != evidence_id or GameManager.get_research_tray_snapshot(company_id).get("rows", []).size() != 1:
		_fail("Duplicate capture should not add a second Research Tray row.")
		return

	var thesis_result: Dictionary = GameManager.create_thesis(company_id, "bullish", "swing", "Research Tray Thesis")
	if not bool(thesis_result.get("success", false)):
		_fail("Expected thesis creation to succeed.")
		return
	var thesis_id: String = str(thesis_result.get("thesis", {}).get("id", ""))
	var attach_result: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, evidence_id, "support", "Size anchor for the memo.")
	if not bool(attach_result.get("success", false)):
		_fail("Expected captured research to attach to the thesis.")
		return
	var attached_evidence_id: String = str(attach_result.get("evidence", {}).get("id", ""))
	var update_result: Dictionary = GameManager.update_thesis_evidence_interpretation(thesis_id, attached_evidence_id, {
		"interpretation": "risk",
		"note": "Large size may limit easy upside."
	})
	if not bool(update_result.get("success", false)) or str(update_result.get("evidence", {}).get("interpretation", "")) != "risk":
		_fail("Expected attached evidence interpretation to update.")
		return

	var chart_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "chart_pattern",
		"company_id": company_id,
		"ticker": str(company.get("ticker", "")),
		"success": true,
		"pattern_id": "breakout",
		"pattern_label": "Breakout",
		"feedback_state": "Plausible, needs confirmation",
		"feedback_reason": "price marked a usable structure",
		"value": "Plausible, needs confirmation"
	})
	if not bool(chart_capture.get("success", false)):
		_fail("Expected chart pattern capture to use the Research Tray.")
		return
	var chart_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(chart_capture.get("evidence", {}).get("id", "")), "watch")
	if not bool(chart_attach.get("success", false)):
		_fail("Expected captured chart pattern to attach to the thesis.")
		return

	var wrapper_result: Dictionary = GameManager.add_chart_pattern_evidence_to_thesis(thesis_id, {
		"success": true,
		"company_id": company_id,
		"ticker": str(company.get("ticker", "")),
		"pattern_id": "range",
		"pattern_label": "Range",
		"feedback_state": "Good read",
		"feedback_reason": "range boundary is clean",
		"value": "Good read"
	})
	if not bool(wrapper_result.get("success", false)):
		_fail("Expected old chart-pattern add API to remain compatible through the Research Tray.")
		return

	var broker_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "broker_summary",
		"company_id": company_id,
		"label": "Net Pressure",
		"value": "Accumulation",
		"detail": "foreign and institutional net flow are both positive",
		"impact": "positive",
		"source_id": "test_broker_flow"
	})
	if not bool(broker_capture.get("success", false)) or str(broker_capture.get("evidence", {}).get("category", "")) != "broker_flow":
		_fail("Expected Broker Summary capture to normalize as broker_flow evidence.")
		return
	var broker_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(broker_capture.get("evidence", {}).get("id", "")), "support")
	if not bool(broker_attach.get("success", false)):
		_fail("Expected Broker Summary evidence to attach to the thesis.")
		return
	var broker_sell_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "broker_summary",
		"company_id": company_id,
		"label": "Sell-side broker YP",
		"value": "Rp1.20B | 10.0K lot(s) | avg Rp1,200",
		"detail": "Sell-side YP printed Rp1.20B across 10.0K lot(s) at an average price of Rp1,200.",
		"impact": "negative",
		"source_id": "test_broker_sell_row"
	})
	if not bool(broker_sell_capture.get("success", false)) or str(broker_sell_capture.get("evidence", {}).get("category", "")) != "broker_flow":
		_fail("Expected sell-side Broker Summary row capture to normalize as broker_flow evidence.")
		return

	var news_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "news_article",
		"company_id": company_id,
		"label": "Export quota renewed",
		"value": "Confirmed",
		"detail": "the article gives the market a near-term reason to revisit demand",
		"impact": "positive",
		"source_id": "test_news"
	})
	if not bool(news_capture.get("success", false)) or str(news_capture.get("evidence", {}).get("category", "")) != "news":
		_fail("Expected News capture to normalize as news evidence.")
		return
	var news_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(news_capture.get("evidence", {}).get("id", "")), "support")
	if not bool(news_attach.get("success", false)):
		_fail("Expected News evidence to attach to the thesis.")
		return
	var news_combo_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "news_article",
		"company_id": company_id,
		"label": "Headline + article: Export quota renewed",
		"value": "Export quota renewed",
		"detail": "The headline points at the catalyst and the article explains why demand may improve.",
		"impact": "positive",
		"source_id": "test_news_headline_article"
	})
	if not bool(news_combo_capture.get("success", false)) or str(news_combo_capture.get("evidence", {}).get("category", "")) != "news":
		_fail("Expected headline + article News capture to normalize as news evidence.")
		return
	var source_lead_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "network_journal",
		"company_id": company_id,
		"label": "Source lead: Desk Reporter",
		"value": "@deskreporter",
		"detail": "This source is connected to the article \"Export quota renewed\".",
		"source_id": "test_news_source_lead"
	})
	if not bool(source_lead_capture.get("success", false)) or str(source_lead_capture.get("evidence", {}).get("category", "")) != "network_intel":
		_fail("Expected News source lead capture to normalize as network_intel evidence.")
		return

	var macro_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "macro_indicator",
		"company_id": company_id,
		"label": "Risk Appetite",
		"value": "Improving",
		"detail": "broad market participation is rising",
		"impact": "positive",
		"source_id": "test_macro"
	})
	if not bool(macro_capture.get("success", false)) or str(macro_capture.get("evidence", {}).get("category", "")) != "sector_macro":
		_fail("Expected Macro capture to normalize as sector_macro evidence.")
		return
	var macro_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(macro_capture.get("evidence", {}).get("id", "")), "watch")
	if not bool(macro_attach.get("success", false)):
		_fail("Expected Macro evidence to attach to the thesis.")
		return

	var sector_id: String = str(company.get("sector_id", ""))
	var sector_name: String = str(company.get("sector_name", "Test Sector"))
	var sector_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "sector_macro",
		"sector_id": sector_id,
		"sector_name": sector_name,
		"label": "%s sector breadth" % sector_name,
		"value": "+2.10%",
		"detail": "sector breadth is improving while the selected stock belongs to this group",
		"impact": "positive",
		"source_id": "test_sector_macro"
	})
	if not bool(sector_capture.get("success", false)) or str(sector_capture.get("evidence", {}).get("category", "")) != "sector_macro":
		_fail("Expected sector dashboard capture to normalize as sector_macro evidence.")
		return
	var sector_evidence_id: String = str(sector_capture.get("evidence", {}).get("id", ""))
	var sector_rows: Array = GameManager.get_research_tray_snapshot(company_id).get("rows", [])
	var found_sector_context: bool = false
	for row_value in sector_rows:
		if typeof(row_value) == TYPE_DICTIONARY and str(row_value.get("id", "")) == sector_evidence_id:
			found_sector_context = true
			break
	if not found_sector_context:
		_fail("Expected sector context evidence to appear for companies in the same sector.")
		return
	var sector_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, sector_evidence_id, "watch")
	if not bool(sector_attach.get("success", false)):
		_fail("Expected sector context evidence to attach to the thesis.")
		return

	var eps_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "key_stats",
		"company_id": company_id,
		"label": "EPS TTM 2019",
		"value": "18.50",
		"detail": "EPS captured from the Key Stats metric table.",
		"source_id": "test_key_stats_eps_ttm"
	})
	if not bool(eps_capture.get("success", false)) or str(eps_capture.get("evidence", {}).get("category", "")) != "financials":
		_fail("Expected EPS metric capture to normalize as financials evidence.")
		return
	var eps_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(eps_capture.get("evidence", {}).get("id", "")), "support")
	if not bool(eps_attach.get("success", false)):
		_fail("Expected EPS evidence to attach to the thesis.")
		return

	var profile_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "company_profile",
		"category": "fundamentals",
		"company_id": company_id,
		"label": "Business description",
		"value": str(company.get("ticker", "")),
		"detail": "This company operates a recurring logistics network with scale-sensitive margins.",
		"source_id": "test_profile_description"
	})
	if not bool(profile_capture.get("success", false)) or str(profile_capture.get("evidence", {}).get("category", "")) != "fundamentals":
		_fail("Expected company profile description capture to normalize as fundamentals evidence.")
		return
	var profile_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(profile_capture.get("evidence", {}).get("id", "")), "watch")
	if not bool(profile_attach.get("success", false)):
		_fail("Expected company profile evidence to attach to the thesis.")
		return

	var ownership_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "company_profile",
		"category": "ownership",
		"company_id": company_id,
		"label": "Free float",
		"value": "28.00%",
		"detail": "Free float shapes liquidity and crowding for larger orders.",
		"source_id": "test_profile_free_float"
	})
	if not bool(ownership_capture.get("success", false)) or str(ownership_capture.get("evidence", {}).get("category", "")) != "ownership":
		_fail("Expected free-float profile capture to normalize as ownership evidence.")
		return
	var ownership_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(ownership_capture.get("evidence", {}).get("id", "")), "watch")
	if not bool(ownership_attach.get("success", false)):
		_fail("Expected ownership evidence to attach to the thesis.")
		return

	var management_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "company_profile",
		"category": "management",
		"company_id": company_id,
		"label": "CEO: Sari Wijaya",
		"value": "CEO",
		"detail": "Sari Wijaya is presented as an operations-focused executive with a steady public tone.",
		"source_id": "test_profile_management"
	})
	if not bool(management_capture.get("success", false)) or str(management_capture.get("evidence", {}).get("category", "")) != "management":
		_fail("Expected management profile capture to normalize as management evidence.")
		return
	var management_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(management_capture.get("evidence", {}).get("id", "")), "watch")
	if not bool(management_attach.get("success", false)):
		_fail("Expected management evidence to attach to the thesis.")
		return

	var financial_statement_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "financial_statement",
		"company_id": company_id,
		"label": "Operating Income",
		"value": "Rp120.00B",
		"detail": "Operating Income line from Income Statement (Q4 2019).",
		"source_id": "test_financial_statement_operating_income",
		"raw_value": 120000000000.0
	})
	if not bool(financial_statement_capture.get("success", false)) or str(financial_statement_capture.get("evidence", {}).get("category", "")) != "financials":
		_fail("Expected financial statement capture to normalize as financials evidence.")
		return
	var financial_statement_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(financial_statement_capture.get("evidence", {}).get("id", "")), "support")
	if not bool(financial_statement_attach.get("success", false)):
		_fail("Expected financial statement evidence to attach to the thesis.")
		return
	var investing_cash_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "financial_statement",
		"company_id": company_id,
		"label": "Cash from Investing",
		"value": "-Rp127.64B",
		"detail": "Cash from Investing line from Cash Flow (Q4 2019).",
		"source_id": "test_financial_statement_investing_cash_flow",
		"raw_value": -127640000000.0
	})
	if not bool(investing_cash_capture.get("success", false)) or str(investing_cash_capture.get("evidence", {}).get("category", "")) != "financials":
		_fail("Expected negative investing cash flow capture to normalize as financials evidence.")
		return
	var investing_cash_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(investing_cash_capture.get("evidence", {}).get("id", "")), "watch")
	if not bool(investing_cash_attach.get("success", false)):
		_fail("Expected investing cash flow evidence to attach to the thesis.")
		return

	var twooter_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "twooter_post",
		"company_id": company_id,
		"label": "Twooter post: Macro Classroom",
		"value": "$%s" % str(company.get("ticker", "")),
		"detail": "Macro Classroom says the move needs confirmation from volume and follow-through.",
		"source_id": "test_twooter_post",
		"impact": "mixed"
	})
	if not bool(twooter_capture.get("success", false)) or str(twooter_capture.get("evidence", {}).get("category", "")) != "twooter":
		_fail("Expected Twooter post capture to normalize as twooter evidence.")
		return
	var twooter_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(twooter_capture.get("evidence", {}).get("id", "")), "watch")
	if not bool(twooter_attach.get("success", false)):
		_fail("Expected Twooter post evidence to attach to the thesis.")
		return

	var twooter_dm_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "twooter_dm",
		"company_id": company_id,
		"label": "Twooter DM: Macro Classroom",
		"value": "Macro Classroom",
		"detail": "The account privately warned that the thesis needs a clean invalidation before sizing up.",
		"source_id": "test_twooter_dm",
		"impact": "mixed"
	})
	if not bool(twooter_dm_capture.get("success", false)) or str(twooter_dm_capture.get("evidence", {}).get("category", "")) != "twooter":
		_fail("Expected Twooter DM capture to normalize as twooter evidence.")
		return

	var trade_quote_capture: Dictionary = GameManager.capture_research_evidence({
		"source_type": "trade_quote",
		"company_id": company_id,
		"label": "Current price",
		"value": "Rp1,200",
		"detail": "Current price captured from the quote panel.",
		"source_id": "test_trade_quote_current_price",
		"impact": "mixed"
	})
	if not bool(trade_quote_capture.get("success", false)) or str(trade_quote_capture.get("evidence", {}).get("category", "")) != "price_action":
		_fail("Expected trade quote capture to normalize as price_action evidence.")
		return
	var trade_quote_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(trade_quote_capture.get("evidence", {}).get("id", "")), "watch")
	if not bool(trade_quote_attach.get("success", false)):
		_fail("Expected trade quote evidence to attach to the thesis.")
		return

	var save_payload: Dictionary = RunState.to_save_dict()
	for row_key in save_payload.get("thesis_research_tray", {}).keys():
		if typeof(save_payload["thesis_research_tray"].get(row_key)) == TYPE_DICTIONARY:
			save_payload["thesis_research_tray"][row_key].erase("dedupe_key")
	RunState.load_from_dict(save_payload)
	if RunState.get_thesis_research_tray().size() < 3 or RunState.get_player_thesis(thesis_id).get("evidence", []).size() < 3:
		_fail("Expected save/load to preserve Research Tray rows and attached thesis evidence.")
		return
	for normalized_row in RunState.get_thesis_research_tray().values():
		if typeof(normalized_row) == TYPE_DICTIONARY and str(normalized_row.get("dedupe_key", "")).is_empty():
			_fail("Expected old save-style Research Tray rows to derive a dedupe key.")
			return

	var report_result: Dictionary = GameManager.generate_thesis_report(thesis_id)
	if not bool(report_result.get("success", false)):
		_fail("Expected memo report generation to succeed.")
		return
	var report: Dictionary = report_result.get("report", {})
	var section_titles: Array = []
	var report_text: String = ""
	for section_value in report.get("sections", []):
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		section_titles.append(str(section.get("title", "")))
		report_text += " %s %s" % [str(section.get("title", "")), str(section.get("body", ""))]
		for bullet_value in section.get("bullets", []):
			if typeof(bullet_value) == TYPE_DICTIONARY:
				report_text += " %s %s" % [str(bullet_value.get("claim", "")), str(bullet_value.get("body", ""))]
	for required_title in ["Evidence Summary", "Supporting Evidence", "Risks And Contradictions", "Invalidation", "Next Research Questions"]:
		if not section_titles.has(required_title):
			_fail("Expected memo report to include %s." % required_title)
			return
	var lower_text: String = report_text.to_lower()
	for forbidden in ["recommendation", "target area", "implied move", "buy now", "accumulate"]:
		if lower_text.find(str(forbidden)) != -1:
			_fail("Memo report should avoid old recommendation/target language: %s" % str(forbidden))
			return
	var widget := preload("res://scripts/ui/widgets/ThesisBoardWidget.gd").new()
	var formatted_text: String = widget._format_report_text(RunState.get_player_thesis(thesis_id)).to_lower()
	widget.queue_free()
	for required_phrase in ["recurring logistics", "operating income", "long-term assets", "capital investment", "ownership shows", "management evidence", "twooter", "money pressure", "news adds", "macro context", "current price", "chart"]:
		if formatted_text.find(str(required_phrase)) == -1:
			_fail("Expected formatted thesis text to include %s handling." % str(required_phrase))
			return
	var profile_index: int = formatted_text.find("recurring logistics")
	var price_index: int = formatted_text.find("current price")
	var fundamental_index: int = formatted_text.find("operating income")
	var technical_index: int = formatted_text.find("chart")
	var money_flow_index: int = formatted_text.find("money pressure")
	if profile_index == -1 or price_index == -1 or fundamental_index == -1 or technical_index == -1 or money_flow_index == -1:
		_fail("Expected formatted thesis text to expose all ordered summary sections.")
		return
	if not (profile_index < price_index and price_index < fundamental_index and fundamental_index < technical_index and technical_index < money_flow_index):
		_fail("Expected thesis summary order to be company description, price, fundamentals, technical, then money flow.")
		return
	for forbidden_phrase in ["business read", "ownership read", "management read", "broker-flow read", "news and catalyst read", "tape and risk read", "company profile", "company description", "stockbot", "trade panel", "stock broker", "financial statements show", "from company profile", "from stockbot"]:
		if formatted_text.find(str(forbidden_phrase)) != -1:
			_fail("Formatted thesis text should avoid labeled read phrasing: %s" % str(forbidden_phrase))
			return

	print("THESIS_RESEARCH_TRAY_OK")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	print("THESIS_RESEARCH_TRAY_FAIL: %s" % message)
	get_tree().quit(1)
