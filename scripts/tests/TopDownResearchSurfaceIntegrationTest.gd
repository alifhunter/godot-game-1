extends Node

const NEWS_CONTROLLER_SCRIPT := preload("res://scripts/ui/controllers/NewsController.gd")
const ANNUAL_FILING_DOCUMENT_SCRIPT := preload("res://systems/AnnualFilingDocument.gd")

const RUN_SEED := 20260622
const REQUIRED_NEWS_COVERAGE_TYPES := [
	"market_wrap_chatter",
	"macro_commodity_sector",
	"corporate_action_filing",
	"early_signal"
]
const CORE_NEWS_FILTER_IDS := ["market", "macro", "commodity", "sector", "corporate", "rumor"]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var setup_error: String = _setup_fixed_seed_run()
	if not setup_error.is_empty():
		_fail(setup_error)
		return

	var news_snapshot: Dictionary = GameManager.get_news_snapshot()
	var news_controller = NEWS_CONTROLLER_SCRIPT.new()
	var news_issue: String = _validate_news_filter_surface(news_controller, news_snapshot)
	if not news_issue.is_empty():
		_fail(news_issue)
		return

	var candidate: Dictionary = _select_integration_candidate(news_snapshot)
	if candidate.is_empty():
		_fail("Expected at least one company with News, top-down profile evidence, and annual filing access.")
		return
	var company_id: String = str(candidate.get("company_id", "")).strip_edges()
	var article: Dictionary = candidate.get("article", {})
	var profile_payload: Dictionary = candidate.get("profile_payload", {})
	var annual_statement: Dictionary = candidate.get("annual_statement", {})
	var filing_document: Dictionary = candidate.get("filing_document", {})

	var thesis_result: Dictionary = GameManager.create_thesis(company_id, "bullish", "swing", "Top-Down Integration Smoke")
	if not bool(thesis_result.get("success", false)):
		_fail("Expected thesis creation to succeed for top-down integration smoke.")
		return
	var thesis_id: String = str(thesis_result.get("thesis", {}).get("id", ""))

	var news_payload: Dictionary = news_controller._build_news_capture_payload(article, "headline_article")
	if not _capture_and_attach(thesis_id, news_payload, "support", "news"):
		return
	if not _capture_and_attach(thesis_id, profile_payload, "watch", str(candidate.get("profile_expected_group", ""))):
		return
	var filing_payload: Dictionary = _annual_filing_line_payload(company_id, annual_statement, filing_document)
	if not _capture_and_attach(thesis_id, filing_payload, "support", "filing"):
		return

	var relationship_payload: Dictionary = candidate.get("relationship_payload", {})
	if not relationship_payload.is_empty():
		if not _capture_and_attach(thesis_id, relationship_payload, "watch", "relationship"):
			return

	var tray_snapshot: Dictionary = GameManager.get_research_tray_snapshot(company_id)
	for required_group in ["news", str(candidate.get("profile_expected_group", "")), "filing"]:
		if not _snapshot_has_provenance_group(tray_snapshot, required_group):
			_fail("Expected integrated Research Tray snapshot to include provenance group %s." % required_group)
			return
	if not relationship_payload.is_empty() and not _snapshot_has_provenance_group(tray_snapshot, "relationship"):
		_fail("Expected integrated Research Tray snapshot to include relationship provenance.")
		return

	var report_result: Dictionary = GameManager.generate_thesis_report(thesis_id)
	if not bool(report_result.get("success", false)):
		_fail("Expected top-down integration thesis report generation to succeed.")
		return

	var save_payload: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(save_payload)
	var loaded_thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if loaded_thesis.get("evidence", []).size() < 3:
		_fail("Expected top-down integrated thesis evidence to survive save/load.")
		return
	for evidence_value in loaded_thesis.get("evidence", []):
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var evidence: Dictionary = evidence_value
		if str(evidence.get("provenance_group", "")).strip_edges().is_empty():
			_fail("Expected top-down thesis evidence to preserve provenance group after save/load.")
			return

	print("TOP_DOWN_RESEARCH_SURFACE_INTEGRATION_OK %s" % JSON.stringify({
		"company_id": company_id,
		"news_article_id": str(article.get("id", "")),
		"profile_group": str(candidate.get("profile_expected_group", "")),
		"filing_document_sections": int(filing_document.get("visible_filing_section_count", 0)),
		"thesis_evidence_count": loaded_thesis.get("evidence", []).size(),
		"seed": RUN_SEED
	}))
	get_tree().quit(0)


func _setup_fixed_seed_run() -> String:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	if company_definitions.is_empty():
		return "Expected company roster generation to produce companies."
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0
	return ""


func _validate_news_filter_surface(news_controller, snapshot: Dictionary) -> String:
	if int(snapshot.get("public_depth_level", 0)) != 1:
		return "Expected News snapshot to stay level-1 public."
	var coverage_types: Dictionary = {}
	for outlet_value in snapshot.get("outlets", []):
		if typeof(outlet_value) != TYPE_DICTIONARY:
			continue
		var outlet: Dictionary = outlet_value
		if not bool(outlet.get("unlocked", false)):
			return "Expected all top-down News outlets to be free/unlocked."
		coverage_types[str(outlet.get("coverage_type", ""))] = true
	for coverage_type in REQUIRED_NEWS_COVERAGE_TYPES:
		if not coverage_types.has(str(coverage_type)):
			return "Expected News outlets to include coverage type %s." % str(coverage_type)
	var articles: Array = _all_news_articles(snapshot)
	if articles.is_empty():
		return "Expected News snapshot to include articles for filtering."
	for article_value in articles:
		if typeof(article_value) != TYPE_DICTIONARY:
			continue
		var article: Dictionary = article_value
		if int(article.get("public_depth_level", 0)) != 1:
			return "Expected News article %s to stay level-1 public." % str(article.get("id", ""))
		if str(article.get("coverage_type", "")).strip_edges().is_empty():
			return "Expected News article %s to keep coverage metadata." % str(article.get("id", ""))
		if _string_array(article.get("topic_ids", [])).is_empty():
			return "Expected News article %s to keep topic metadata." % str(article.get("id", ""))
	var matched_filter_count: int = 0
	var market_count: int = int(news_controller._count_news_articles_for_topic_filter(articles, "market"))
	var top_down_count: int = 0
	for filter_id in CORE_NEWS_FILTER_IDS:
		var filter_count: int = int(news_controller._count_news_articles_for_topic_filter(articles, str(filter_id)))
		if filter_count > 0:
			matched_filter_count += 1
		if str(filter_id) in ["macro", "commodity", "sector"]:
			top_down_count += filter_count
	if market_count <= 0:
		return "Expected News market topic filter to match at least one article."
	if top_down_count <= 0:
		return "Expected at least one macro, commodity, or sector News topic filter match."
	if matched_filter_count < 3:
		return "Expected News topic filters to expose at least three live filter buckets."
	return ""


func _select_integration_candidate(snapshot: Dictionary) -> Dictionary:
	var article_by_company: Dictionary = {}
	for article_value in _all_news_articles(snapshot):
		if typeof(article_value) != TYPE_DICTIONARY:
			continue
		var article: Dictionary = article_value
		var company_id: String = str(article.get("target_company_id", "")).strip_edges()
		if company_id.is_empty() or article_by_company.has(company_id):
			continue
		article_by_company[company_id] = article.duplicate(true)
	var candidate_ids: Array = article_by_company.keys()
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		if not candidate_ids.has(company_id):
			candidate_ids.append(company_id)
	for company_id_value in candidate_ids:
		var company_id: String = str(company_id_value)
		if not RunState.ensure_company_full_detail(company_id):
			continue
		var company: Dictionary = GameManager.get_company_snapshot(company_id, true, true, true)
		var article: Dictionary = article_by_company.get(company_id, {})
		if article.is_empty():
			continue
		var annual_statement: Dictionary = _annual_statement(company_id)
		if annual_statement.is_empty():
			continue
		var filing_document: Dictionary = _annual_filing_document(company_id, annual_statement, company)
		if filing_document.is_empty() or int(filing_document.get("visible_filing_section_count", 0)) <= 0:
			continue
		var profile_candidate: Dictionary = _profile_capture_candidate(company)
		if profile_candidate.is_empty():
			continue
		return {
			"company_id": company_id,
			"article": article,
			"annual_statement": annual_statement,
			"filing_document": filing_document,
			"profile_payload": profile_candidate.get("payload", {}),
			"profile_expected_group": str(profile_candidate.get("expected_group", "")),
			"relationship_payload": _relationship_capture_payload(company)
		}
	return {}


func _profile_capture_candidate(company: Dictionary) -> Dictionary:
	var company_id: String = str(company.get("id", company.get("company_id", ""))).strip_edges()
	var sector_id: String = str(company.get("sector_id", "")).strip_edges()
	for option_value in GameManager.get_commodity_macro_evidence_options(company_id, sector_id):
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		if str(option.get("source_type", "")) == "commodity_macro":
			return {"payload": option.duplicate(true), "expected_group": "commodity"}
	for option_value in GameManager.get_company_story_dossier_evidence_options(company_id):
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var story_option: Dictionary = option_value
		if str(story_option.get("category", "")) == "network_intel":
			continue
		return {"payload": story_option.duplicate(true), "expected_group": "company"}
	return {}


func _relationship_capture_payload(company: Dictionary) -> Dictionary:
	var company_id: String = str(company.get("id", company.get("company_id", ""))).strip_edges()
	for edge_value in RunState.get_company_relationship_edges_for_company(company_id, true, true):
		if typeof(edge_value) != TYPE_DICTIONARY:
			continue
		var edge: Dictionary = edge_value
		var visibility: String = str(edge.get("visibility", "public")).strip_edges().to_lower()
		if visibility == "private" or visibility == "hidden":
			continue
		var counterparty_id: String = _relationship_counterparty_id(edge, company_id)
		var counterparty: Dictionary = GameManager.get_company_snapshot(counterparty_id, true, true, true)
		var counterparty_ticker: String = str(counterparty.get("ticker", counterparty_id.to_upper())).strip_edges()
		var relationship_type: String = str(edge.get("relationship_type", "relationship")).strip_edges()
		return {
			"source_type": "company_relationship_graph",
			"category": "corporate_events",
			"company_id": company_id,
			"ticker": str(company.get("ticker", "")),
			"company_name": str(company.get("name", "")),
			"label": "Counterparty: %s" % counterparty_ticker,
			"value": relationship_type.replace("_", " ").capitalize(),
			"detail": "Public relationship graph context captured from the company profile top-down links.",
			"source_id": "top_down_integration_relationship_%s" % str(edge.get("edge_id", "")),
			"relationship_edge_id": str(edge.get("edge_id", "")),
			"relationship_type": relationship_type,
			"counterparty_company_id": counterparty_id,
			"counterparty_ticker": counterparty_ticker,
			"counterparty_name": str(counterparty.get("name", counterparty_ticker))
		}
	return {}


func _capture_and_attach(thesis_id: String, payload: Dictionary, interpretation: String, expected_group: String) -> bool:
	if payload.is_empty():
		_fail("Expected non-empty %s capture payload." % expected_group)
		return false
	var capture_result: Dictionary = GameManager.capture_research_evidence(payload)
	if not bool(capture_result.get("success", false)):
		_fail("Expected %s evidence capture to succeed: %s" % [expected_group, str(capture_result.get("message", ""))])
		return false
	var evidence: Dictionary = capture_result.get("evidence", {})
	if str(evidence.get("provenance_group", "")) != expected_group:
		_fail("Expected %s evidence provenance group, got %s." % [expected_group, str(evidence.get("provenance_group", ""))])
		return false
	var attach_result: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(evidence.get("id", "")), interpretation)
	if not bool(attach_result.get("success", false)):
		_fail("Expected %s evidence to attach to thesis: %s" % [expected_group, str(attach_result.get("message", ""))])
		return false
	if str(attach_result.get("evidence", {}).get("provenance_group", "")) != expected_group:
		_fail("Expected attached %s evidence to preserve provenance group." % expected_group)
		return false
	return true


func _all_news_articles(snapshot: Dictionary) -> Array:
	var rows: Array = []
	for feed_value in snapshot.get("feeds", {}).values():
		if typeof(feed_value) != TYPE_DICTIONARY:
			continue
		var feed: Dictionary = feed_value
		for article_value in feed.get("articles", []):
			if typeof(article_value) == TYPE_DICTIONARY:
				rows.append(article_value)
	return rows


func _annual_statement(company_id: String) -> Dictionary:
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, true, true)
	var snapshot: Dictionary = definition.get("financial_statement_snapshot", {}) if typeof(definition.get("financial_statement_snapshot", {})) == TYPE_DICTIONARY else {}
	var annual: Dictionary = snapshot.get("annual_statement", {}) if typeof(snapshot.get("annual_statement", {})) == TYPE_DICTIONARY else {}
	return annual.duplicate(true)


func _annual_filing_document(company_id: String, annual_statement: Dictionary, company: Dictionary) -> Dictionary:
	return ANNUAL_FILING_DOCUMENT_SCRIPT.get_or_build_document({}, annual_statement, RunState.run_seed, company_id, {
		"company_name": str(company.get("name", "")),
		"ticker": str(company.get("ticker", "")),
		"sector_style_id": str(company.get("sector_id", "generic_annual_filing"))
	})


func _annual_filing_line_payload(company_id: String, annual: Dictionary, filing_document: Dictionary) -> Dictionary:
	var line_item: Dictionary = _annual_line(annual, "profit_or_loss_and_oci", "revenue")
	var statement_id: String = str(annual.get("statement_id", ""))
	var period_label: String = str(annual.get("statement_period_label", "FY2019"))
	return {
		"source_type": "financial_statement",
		"category": "financials",
		"company_id": company_id,
		"source_label": "Annual Filing",
		"label": str(line_item.get("label", "Revenue")),
		"value": "Annual revenue",
		"detail": "Revenue line from annual consolidated statement (%s)." % period_label,
		"source_id": "top_down_integration_filing_%s_%s" % [company_id, _token(statement_id)],
		"statement_id": statement_id,
		"statement_period_label": period_label,
		"statement_scope": "annual",
		"statement_consolidated": true,
		"statement_year": str(annual.get("statement_year", annual.get("fiscal_year", ""))),
		"statement_section": "profit_or_loss_and_oci",
		"statement_section_label": "Consolidated Statement of Profit or Loss and Other Comprehensive Income",
		"line_id": str(line_item.get("line_id", "")),
		"statement_line_id": str(line_item.get("line_id", "")),
		"line_item_id": str(line_item.get("id", "")),
		"metric_id": str(line_item.get("metric_id", "")),
		"metric_ids": [str(line_item.get("metric_id", ""))],
		"statement_value_format": str(line_item.get("format", "currency")),
		"raw_value": float(line_item.get("value", 0.0)),
		"filing_capture_type": "statement_row",
		"filing_excerpt_type": "statement_row",
		"filing_section_id": "profit_or_loss_and_oci",
		"filing_section_label": "Consolidated Statement of Profit or Loss and Other Comprehensive Income",
		"filing_excerpt_id": str(line_item.get("line_id", "revenue")),
		"filing_visible_label": str(line_item.get("label", "Revenue")),
		"filing_visible_text": "%s from %s." % [str(line_item.get("label", "Revenue")), str(filing_document.get("title", "Consolidated Financial Statements"))],
		"generated_content_surface": true,
		"generated_surface_id": "annual_filing_reader",
		"surface_id": "annual_filing_reader",
		"source_system_id": "annual_filing_document",
		"vocabulary_tags": ["financial_statement", "filing", "annual", "consolidated", "revenue"]
	}


func _annual_line(annual: Dictionary, section_id: String, metric_id: String) -> Dictionary:
	for row_value in annual.get(section_id, []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("metric_id", row.get("id", ""))) == metric_id:
			return row.duplicate(true)
	for row_value in annual.get(section_id, []):
		if typeof(row_value) == TYPE_DICTIONARY:
			return row_value.duplicate(true)
	return {}


func _relationship_counterparty_id(edge: Dictionary, company_id: String) -> String:
	var source_id: String = str(edge.get("source_company_id", "")).strip_edges()
	var target_id: String = str(edge.get("target_company_id", "")).strip_edges()
	if source_id == company_id:
		return target_id
	if target_id == company_id:
		return source_id
	return target_id if not target_id.is_empty() else source_id


func _snapshot_has_provenance_group(snapshot: Dictionary, group_id: String) -> bool:
	for group_value in snapshot.get("provenance_groups", []):
		if typeof(group_value) == TYPE_DICTIONARY and str(group_value.get("id", "")) == group_id:
			return true
	return false


func _string_array(value) -> Array:
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


func _token(value: String) -> String:
	var token: String = value.strip_edges().to_lower()
	for ch in ["|", " ", "/", "\\", ":", ".", ",", "(", ")", "[", "]"]:
		token = token.replace(ch, "_")
	while token.find("__") != -1:
		token = token.replace("__", "_")
	return token.strip_edges().trim_prefix("_").trim_suffix("_")


func _fail(message: String) -> void:
	push_error(message)
	print("TOP_DOWN_RESEARCH_SURFACE_INTEGRATION_FAIL: %s" % message)
	get_tree().quit(1)
