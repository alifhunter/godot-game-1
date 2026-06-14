extends RefCounted

const THESIS_VOCABULARY_SCRIPT = preload("res://systems/ThesisVocabulary.gd")
const VALID_INTERPRETATIONS := THESIS_VOCABULARY_SCRIPT.VALID_INTERPRETATIONS
const VALID_IMPACTS := THESIS_VOCABULARY_SCRIPT.VALID_IMPACTS
const VALID_CATEGORIES := THESIS_VOCABULARY_SCRIPT.VALID_CATEGORIES

const SOURCE_LABELS := {
	"key_stats": "Key Stats",
	"chart_pattern": "STOCKBOT Chart",
	"news_article": "News",
	"news": "News",
	"twooter_post": "Twooter",
	"twooter_dm": "Twooter DM",
	"network_journal": "Network",
	"corporate_event": "Corporate Event",
	"corporate_events": "Corporate Event",
	"broker_summary": "Broker Summary",
	"broker_flow": "Broker Summary",
	"macro": "Macro",
	"macro_indicator": "Macro",
	"sector_macro": "Sector / Macro",
	"company_profile": "Company Profile",
	"financial_statement": "Financials",
	"trade_quote": "STOCKBOT Quote"
}


func normalize_capture(payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	var source_type: String = str(payload.get("source_type", payload.get("source", ""))).to_lower()
	if source_type.is_empty():
		source_type = "manual"
	match source_type:
		"chart_pattern":
			return _normalize_chart_pattern_capture(payload, context)
		"key_stats":
			return _normalize_key_stats_capture(payload, context)
		_:
			return _normalize_generic_capture(payload, context, source_type)


func normalize_interpretation(value: String, warn_on_unknown: bool = false, context: String = "") -> String:
	return THESIS_VOCABULARY_SCRIPT.normalize_interpretation(value, warn_on_unknown, context)


func normalize_impact(value: String, warn_on_unknown: bool = false, context: String = "") -> String:
	return THESIS_VOCABULARY_SCRIPT.normalize_impact(value, warn_on_unknown, context)


func normalize_category(value: String, warn_on_unknown: bool = false, context: String = "") -> String:
	return THESIS_VOCABULARY_SCRIPT.normalize_category(value, warn_on_unknown, context)


func interpretation_label(value: String) -> String:
	return THESIS_VOCABULARY_SCRIPT.interpretation_label(value)


func impact_for_interpretation(value: String) -> String:
	return THESIS_VOCABULARY_SCRIPT.impact_for_interpretation(value)


func normalize_attached_evidence(row: Dictionary, interpretation: String = "watch", note: String = "") -> Dictionary:
	var normalized: Dictionary = row.duplicate(true)
	var context: String = str(normalized.get("label", normalized.get("id", "attached_evidence")))
	var resolved_category: String = normalize_category(str(normalized.get("category", "")), true, context)
	if not resolved_category.is_empty():
		normalized["category"] = resolved_category
	if str(normalized.get("category_label", "")).strip_edges().is_empty() and not resolved_category.is_empty():
		normalized["category_label"] = _category_label(resolved_category)
	var resolved_interpretation: String = normalize_interpretation(str(normalized.get("interpretation", interpretation)), true, context)
	normalized["interpretation"] = resolved_interpretation
	normalized["interpretation_label"] = interpretation_label(resolved_interpretation)
	normalized["player_note"] = str(normalized.get("player_note", note)).strip_edges()
	if str(normalized.get("impact", "")).is_empty():
		normalized["impact"] = impact_for_interpretation(resolved_interpretation)
	else:
		normalized["impact"] = THESIS_VOCABULARY_SCRIPT.validate_impact_for_interpretation(str(normalized.get("impact", "")), resolved_interpretation, context)
	return normalized


func _normalize_key_stats_capture(payload: Dictionary, context: Dictionary) -> Dictionary:
	var label: String = str(payload.get("label", "")).strip_edges()
	var category: String = str(payload.get("category", _key_stats_category_for_label(label)))
	return _normalize_generic_capture(payload.merged({
		"source_type": "key_stats",
		"source_label": _source_label("key_stats"),
		"category": category,
		"category_label": _category_label(category),
		"detail": str(payload.get("detail", _key_stats_detail_for_label(label)))
	}, true), context, "key_stats")


func _normalize_chart_pattern_capture(payload: Dictionary, context: Dictionary) -> Dictionary:
	var pattern_label: String = str(payload.get("pattern_label", payload.get("label", "Chart pattern"))).strip_edges()
	if pattern_label.is_empty():
		pattern_label = "Chart pattern"
	var feedback_state: String = str(payload.get("feedback_state", payload.get("value", ""))).strip_edges()
	var detail: String = str(payload.get("feedback_reason", payload.get("detail", ""))).strip_edges()
	var row: Dictionary = _normalize_generic_capture(payload.merged({
		"source_type": "chart_pattern",
		"source_label": _source_label("chart_pattern"),
		"category": "price_action",
		"category_label": "Price Action",
		"label": pattern_label,
		"value": feedback_state if not feedback_state.is_empty() else str(payload.get("value", "Pattern marked")),
		"detail": detail
	}, true), context, "chart_pattern")
	for key in [
		"pattern_id",
		"pattern_label",
		"feedback_state",
		"feedback_reason",
		"invalidation",
		"next_check",
		"chart_range",
		"chart_range_label",
		"region_label"
	]:
		if payload.has(key):
			row[key] = str(payload.get(key, ""))
	for key in ["start_price", "end_price", "current_price"]:
		if payload.has(key):
			row[key] = float(payload.get(key, 0.0))
	for key in ["start_anchor", "end_anchor", "start_date", "end_date", "report_date"]:
		if typeof(payload.get(key, {})) == TYPE_DICTIONARY:
			row[key] = payload.get(key, {}).duplicate(true)
	return row


func _normalize_generic_capture(payload: Dictionary, context: Dictionary, source_type: String) -> Dictionary:
	var company: Dictionary = context.get("company", {}) if typeof(context.get("company", {})) == TYPE_DICTIONARY else {}
	var company_id: String = str(payload.get("company_id", company.get("id", company.get("company_id", "")))).strip_edges()
	var ticker: String = str(payload.get("ticker", company.get("ticker", ""))).strip_edges()
	var company_name: String = str(payload.get("company_name", company.get("name", ""))).strip_edges()
	var sector_id: String = str(payload.get("sector_id", company.get("sector_id", ""))).strip_edges()
	var sector_name: String = str(payload.get("sector_name", company.get("sector_name", ""))).strip_edges()
	var category: String = str(payload.get("category", "")).strip_edges()
	if category.is_empty():
		category = _category_for_source_type(source_type)
	category = normalize_category(category, true, source_type)
	var label: String = str(payload.get("label", "")).strip_edges()
	var value: String = str(payload.get("value", "")).strip_edges()
	var source_label: String = str(payload.get("source_label", _source_label(source_type))).strip_edges()
	var row: Dictionary = {
		"company_id": company_id,
		"ticker": ticker,
		"company_name": company_name,
		"sector_id": sector_id,
		"sector_name": sector_name,
		"category": category,
		"category_label": str(payload.get("category_label", _category_label(category))),
		"label": label,
		"value": value,
		"detail": str(payload.get("detail", "")).strip_edges(),
		"source_type": source_type,
		"source_label": source_label,
		"source_id": str(payload.get("source_id", "")).strip_edges(),
		"impact": normalize_impact(str(payload.get("impact", THESIS_VOCABULARY_SCRIPT.DEFAULT_IMPACT)), true, source_type)
	}
	if str(row.get("category_label", "")).is_empty():
		row["category_label"] = _category_label(category)
	if str(row.get("impact", "")).is_empty():
		row["impact"] = THESIS_VOCABULARY_SCRIPT.DEFAULT_IMPACT
	return row


func _key_stats_category_for_label(label: String) -> String:
	var normalized: String = label.to_lower()
	if normalized.find("free float") != -1 or normalized.find("share outstanding") != -1:
		return "ownership"
	if normalized.find("price") != -1:
		return "price_action"
	if normalized.find("pe") != -1 or normalized.find("yield") != -1 or normalized.find("market cap") != -1 or normalized.find("book") != -1 or normalized.find("sales") != -1 or normalized.find("cashflow") != -1:
		return "valuation"
	if normalized.find("revenue") != -1 or normalized.find("income") != -1 or normalized.find("eps") != -1 or normalized.find("margin") != -1 or normalized.find("free cash") != -1:
		return "financials"
	if normalized.find("debt") != -1:
		return "risk_invalidation"
	return "fundamentals"


func _key_stats_detail_for_label(label: String) -> String:
	var normalized: String = label.to_lower()
	if normalized.find("market cap") != -1:
		return "Company size anchors what kind of upside story is realistic."
	if normalized.find("pe") != -1:
		return "Valuation multiple helps compare price against current earnings."
	if normalized.find("revenue") != -1:
		return "Revenue shows whether the business base is growing or shrinking."
	if normalized.find("net income") != -1:
		return "Net income checks whether the business converts sales into profit."
	if normalized.find("margin") != -1:
		return "Margin quality helps separate durable earnings from noisy sales."
	if normalized.find("debt") != -1:
		return "Leverage affects how much room the thesis has for mistakes."
	if normalized.find("free cash") != -1:
		return "Free cash flow checks whether profit is turning into usable cash."
	if normalized.find("dividend") != -1 or normalized.find("dps") != -1:
		return "Dividend data can support or challenge an income case."
	if normalized.find("price") != -1:
		return "Price context freezes where the player noticed the evidence."
	return "Captured directly from Key Stats."


func _category_for_source_type(source_type: String) -> String:
	match source_type:
		"broker_summary", "broker_flow":
			return THESIS_VOCABULARY_SCRIPT.CATEGORY_BROKER_FLOW
		"news", "news_article":
			return THESIS_VOCABULARY_SCRIPT.CATEGORY_NEWS
		"twooter_post", "twooter_dm":
			return THESIS_VOCABULARY_SCRIPT.CATEGORY_TWOOTER
		"network_journal":
			return THESIS_VOCABULARY_SCRIPT.CATEGORY_NETWORK_INTEL
		"corporate_event", "corporate_events":
			return THESIS_VOCABULARY_SCRIPT.CATEGORY_CORPORATE_EVENTS
		"macro", "macro_indicator", "sector_macro":
			return THESIS_VOCABULARY_SCRIPT.CATEGORY_SECTOR_MACRO
		"financial_statement":
			return THESIS_VOCABULARY_SCRIPT.CATEGORY_FINANCIALS
		"company_profile":
			return THESIS_VOCABULARY_SCRIPT.CATEGORY_FUNDAMENTALS
		"trade_quote":
			return THESIS_VOCABULARY_SCRIPT.CATEGORY_PRICE_ACTION
	return ""


func _category_label(category: String) -> String:
	return THESIS_VOCABULARY_SCRIPT.category_label(category)


func _source_label(source_type: String) -> String:
	return THESIS_VOCABULARY_SCRIPT.source_label(source_type, str(SOURCE_LABELS.get(source_type, source_type.capitalize())))
