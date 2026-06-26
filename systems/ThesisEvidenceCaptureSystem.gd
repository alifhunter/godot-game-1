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
	"commodity_macro": "Macro Commodities",
	"company_story_dossier": "Story Dossier",
	"company_relationship_graph": "Relationship Graph",
	"sector_macro": "Sector / Macro",
	"company_profile": "Company Profile",
	"financial_statement": "Financials",
	"trade_quote": "STOCKBOT Quote"
}

const PROVENANCE_LABELS := {
	"market": "Market / Price",
	"macro": "Macro",
	"commodity": "Commodity",
	"sector": "Sector",
	"company": "Company",
	"filing": "Filing",
	"relationship": "Relationship",
	"network": "Network",
	"social": "Social",
	"news": "News",
	"flow": "Broker Flow",
	"manual": "Manual"
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


func provenance_label(group_id: String) -> String:
	var normalized_group: String = str(group_id).strip_edges().to_lower()
	if normalized_group.is_empty():
		return "Research"
	return str(PROVENANCE_LABELS.get(normalized_group, normalized_group.capitalize()))


func ensure_provenance_metadata(row: Dictionary) -> Dictionary:
	var normalized: Dictionary = row.duplicate(true)
	_apply_provenance_metadata(normalized, row, str(normalized.get("source_type", "")))
	return normalized


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
	_apply_provenance_metadata(normalized, row, str(normalized.get("source_type", "")))
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
	_copy_optional_contract_fields(row, payload)
	_apply_provenance_metadata(row, payload, source_type)
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
		"macro", "macro_indicator", "commodity_macro", "sector_macro":
			return THESIS_VOCABULARY_SCRIPT.CATEGORY_SECTOR_MACRO
		"company_story_dossier":
			return THESIS_VOCABULARY_SCRIPT.CATEGORY_CORPORATE_EVENTS
		"company_relationship_graph":
			return THESIS_VOCABULARY_SCRIPT.CATEGORY_CORPORATE_EVENTS
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


func _apply_provenance_metadata(row: Dictionary, source: Dictionary, source_type: String) -> void:
	var explicit_group: String = str(source.get("provenance_group", row.get("provenance_group", ""))).strip_edges().to_lower()
	var group: String = explicit_group
	if group.is_empty():
		group = _provenance_group_for_row(row, source_type)
	row["provenance_group"] = group

	var explicit_label: String = str(source.get("provenance_label", row.get("provenance_label", ""))).strip_edges()
	row["provenance_label"] = explicit_label if not explicit_label.is_empty() else provenance_label(group)

	var explicit_path: String = str(source.get("provenance_path", row.get("provenance_path", ""))).strip_edges()
	row["provenance_path"] = explicit_path if not explicit_path.is_empty() else _provenance_path_for_row(row, group)

	var tags: Array = []
	if typeof(row.get("provenance_tags", [])) == TYPE_ARRAY:
		tags.append_array(row.get("provenance_tags", []))
	if typeof(source.get("provenance_tags", [])) == TYPE_ARRAY:
		tags.append_array(source.get("provenance_tags", []))
	tags.append_array(_provenance_tags_for_row(row, group))
	row["provenance_tags"] = _unique_string_array(tags)


func _provenance_group_for_row(row: Dictionary, source_type: String) -> String:
	var normalized_source: String = str(source_type).strip_edges().to_lower()
	var category: String = str(row.get("category", "")).strip_edges().to_lower()
	if normalized_source == "commodity_macro" or not str(row.get("commodity_id", "")).strip_edges().is_empty():
		return "commodity"
	if normalized_source in ["macro", "macro_indicator"]:
		return "macro"
	if normalized_source == "sector_macro":
		return "sector"
	if normalized_source in ["news", "news_article"]:
		return "news"
	if normalized_source in ["twooter_post", "twooter_dm"]:
		return "social"
	if normalized_source == "network_journal":
		return "network"
	if normalized_source == "company_relationship_graph" or not str(row.get("relationship_edge_id", "")).strip_edges().is_empty() or not str(row.get("counterparty_company_id", "")).strip_edges().is_empty():
		return "relationship"
	if normalized_source == "financial_statement" or _has_filing_metadata(row):
		return "filing"
	if normalized_source in ["broker_summary", "broker_flow"]:
		return "flow"
	if normalized_source in ["chart_pattern", "trade_quote"]:
		return "market"
	if normalized_source in ["company_profile", "key_stats"]:
		return "company"
	if normalized_source == "company_story_dossier":
		if category == THESIS_VOCABULARY_SCRIPT.CATEGORY_NETWORK_INTEL:
			return "network"
		if category == THESIS_VOCABULARY_SCRIPT.CATEGORY_SECTOR_MACRO:
			return "sector"
		return "company"
	if category == THESIS_VOCABULARY_SCRIPT.CATEGORY_TWOOTER:
		return "social"
	if category == THESIS_VOCABULARY_SCRIPT.CATEGORY_NETWORK_INTEL:
		return "network"
	if category == THESIS_VOCABULARY_SCRIPT.CATEGORY_NEWS:
		return "news"
	if category == THESIS_VOCABULARY_SCRIPT.CATEGORY_PRICE_ACTION:
		return "market"
	if category == THESIS_VOCABULARY_SCRIPT.CATEGORY_BROKER_FLOW:
		return "flow"
	if category == THESIS_VOCABULARY_SCRIPT.CATEGORY_SECTOR_MACRO:
		return "sector"
	return "manual"


func _has_filing_metadata(row: Dictionary) -> bool:
	for key_value in [
		"filing_section_id",
		"filing_excerpt_id",
		"filing_table_id",
		"statement_id",
		"statement_section",
		"statement_line_id",
		"note_id",
		"disclosure_packet_id",
		"disclosure_section_id"
	]:
		if not str(row.get(str(key_value), "")).strip_edges().is_empty():
			return true
	return false


func _provenance_path_for_row(row: Dictionary, group: String) -> String:
	var parts: Array = []
	_append_unique_string(parts, provenance_label(group))
	var source_label: String = str(row.get("source_label", "")).strip_edges()
	if not source_label.is_empty() and source_label != parts[0]:
		_append_unique_string(parts, source_label)
	match group:
		"commodity":
			_append_unique_string(parts, str(row.get("commodity_name", row.get("commodity_id", ""))).strip_edges())
			_append_unique_string(parts, str(row.get("sector_name", "")).strip_edges())
		"sector":
			_append_unique_string(parts, str(row.get("sector_name", row.get("sector_id", ""))).strip_edges())
		"filing":
			_append_unique_string(parts, str(row.get("filing_visible_label", "")).strip_edges())
			_append_unique_string(parts, str(row.get("filing_section_label", row.get("statement_section_label", ""))).strip_edges())
			_append_unique_string(parts, str(row.get("statement_period_label", "")).strip_edges())
		"relationship":
			_append_unique_string(parts, str(row.get("counterparty_ticker", row.get("counterparty_company_id", ""))).strip_edges())
		"company":
			_append_unique_string(parts, str(row.get("category_label", "")).strip_edges())
		"news", "network", "social", "flow", "market", "macro":
			_append_unique_string(parts, str(row.get("category_label", "")).strip_edges())
	var ticker: String = str(row.get("ticker", "")).strip_edges()
	var company_name: String = str(row.get("company_name", "")).strip_edges()
	if not ticker.is_empty():
		_append_unique_string(parts, ticker)
	elif not company_name.is_empty():
		_append_unique_string(parts, company_name)
	return " > ".join(parts)


func _provenance_tags_for_row(row: Dictionary, group: String) -> Array:
	var tags: Array = []
	_append_unique_string(tags, "group:%s" % group)
	_append_tag(tags, "source", row.get("source_type", ""))
	_append_tag(tags, "category", row.get("category", ""))
	_append_tag(tags, "company", row.get("company_id", ""))
	_append_tag(tags, "sector", row.get("sector_id", ""))
	_append_tag(tags, "commodity", row.get("commodity_id", ""))
	_append_tag(tags, "story", row.get("story_id", ""))
	_append_tag(tags, "surface", row.get("generated_surface_id", row.get("surface_id", "")))
	_append_tag(tags, "filing_section", row.get("filing_section_id", row.get("statement_section", "")))
	_append_tag(tags, "relationship", row.get("relationship_edge_id", ""))
	_append_tag(tags, "counterparty", row.get("counterparty_company_id", ""))
	return tags


func _append_tag(target: Array, prefix: String, value) -> void:
	var normalized: String = str(value).strip_edges()
	if normalized.is_empty():
		return
	_append_unique_string(target, "%s:%s" % [prefix, normalized])


func _append_unique_string(target: Array, value: String) -> void:
	var normalized: String = str(value).strip_edges()
	if normalized.is_empty():
		return
	if not target.has(normalized):
		target.append(normalized)


func _unique_string_array(values: Array) -> Array:
	var normalized_values: Array = []
	for value in values:
		_append_unique_string(normalized_values, str(value))
	return normalized_values


func _copy_optional_contract_fields(target: Dictionary, source: Dictionary) -> void:
	for key_value in [
		"commodity_id",
		"commodity_name",
		"commodity_category",
		"commodity_regime",
		"commodity_direction",
		"generated_surface_id",
		"generated_scope_id",
		"source_system_id",
		"story_id",
		"story_note_fact_id",
		"story_family",
		"archetype_id",
		"fact_id",
		"clue_id",
		"effect_id",
		"surface_id",
		"public_status",
		"stage_id",
		"visibility",
		"dossier_evidence_type",
		"dossier_archetype_id",
		"dossier_story_family",
		"dossier_hook_id",
		"dossier_public_status",
		"dossier_stage_id",
		"metric_id",
		"statement_section",
		"magnitude_band",
		"direction",
		"directness",
		"original_directness",
		"required_relationship_stage",
		"source_quality",
		"source_excerpt",
		"filing_capture_type",
		"filing_excerpt_type",
		"filing_section_id",
		"filing_section_label",
		"filing_excerpt_id",
		"filing_visible_label",
		"filing_visible_text",
		"filing_table_id",
		"filing_table_title",
		"filing_table_row_id",
		"filing_table_row_caption",
		"filing_table_row_value",
		"filing_table_reference",
		"statement_id",
		"statement_period_label",
		"statement_scope",
		"statement_year",
		"statement_quarter",
		"filing_day_index",
		"line_id",
		"statement_line_id",
		"line_item_id",
		"statement_section_label",
		"statement_value_format",
		"capture_level",
		"note_id",
		"note_type",
		"note_title_key",
		"note_text_key",
		"note_paragraph_id",
		"note_paragraph_index",
		"note_paragraph_role",
		"note_paragraph_text",
		"disclosure_packet_id",
		"disclosure_placement_id",
		"disclosure_section_id",
		"disclosure_section_label",
		"disclosure_subtlety",
		"disclosure_reader_effort",
		"disclosure_evidence_density",
		"disclosure_fragment_role",
		"disclosure_packet_role",
		"cross_reference_target_note_type",
		"cross_reference_target_note_number",
		"cross_reference_target_title",
		"cross_reference_reason",
		"cross_reference_display_text",
		"disclosure_quality",
		"detail_level",
		"access_level",
		"tone",
		"provenance_group",
		"provenance_label",
		"provenance_path",
		"provenance_surface",
		"provenance_origin",
		"relationship_edge_id",
		"relationship_type",
		"relationship_label",
		"counterparty_company_id",
		"counterparty_ticker",
		"counterparty_name"
	]:
		var key: String = str(key_value)
		if source.has(key):
			target[key] = str(source.get(key, ""))
	for key_value in [
		"commodity_level",
		"commodity_ytd_move",
		"commodity_driver_score",
		"commodity_exposure",
		"reliability",
		"leak_risk",
		"fact_strength",
		"fact_confidence",
		"clue_reliability",
		"effect_confidence",
		"required_recognition_min",
		"network_relationship",
		"recognition_score",
		"raw_value",
		"importance"
	]:
		var key: String = str(key_value)
		if source.has(key):
			target[key] = float(source.get(key, 0.0))
	for key_value in ["generated_content_surface", "commodity_has_direct_exposure", "commodity_sector_related", "statement_consolidated"]:
		var key: String = str(key_value)
		if source.has(key):
			target[key] = bool(source.get(key, false))
	for key_value in [
		"related_sectors",
		"story_tags",
		"fact_ids",
		"metric_ids",
		"effect_ids",
		"clue_ids",
		"source_fact_ids",
		"source_clue_ids",
		"source_company_ids",
		"source_sector_ids",
		"source_commodity_ids",
		"source_story_ids",
		"source_story_note_fact_ids",
		"source_effect_ids",
		"source_disclosure_packet_ids",
		"source_disclosure_placement_ids",
		"source_disclosure_section_ids",
		"source_living_arc_ids",
		"source_corporate_action_ids",
		"source_event_ids",
		"source_event_ref_ids",
		"source_roadmap_ids",
		"source_statement_sections",
		"story_source_refs",
		"disclosure_packet_refs",
		"living_arc_refs",
		"corporate_action_refs",
		"event_refs",
		"roadmap_refs",
		"explain_tags",
		"vocabulary_tags",
		"provenance_tags"
	]:
		var key: String = str(key_value)
		if typeof(source.get(key, [])) == TYPE_ARRAY:
			target[key] = source.get(key, []).duplicate(true)
	_normalize_generated_source_aliases(target)


func _normalize_generated_source_aliases(row: Dictionary) -> void:
	var source_fact_ids: Array = row.get("source_fact_ids", []) if typeof(row.get("source_fact_ids", [])) == TYPE_ARRAY else []
	var source_clue_ids: Array = row.get("source_clue_ids", []) if typeof(row.get("source_clue_ids", [])) == TYPE_ARRAY else []
	if source_fact_ids.is_empty() and typeof(row.get("fact_ids", [])) == TYPE_ARRAY:
		row["source_fact_ids"] = row.get("fact_ids", []).duplicate(true)
	if source_clue_ids.is_empty() and typeof(row.get("clue_ids", [])) == TYPE_ARRAY:
		row["source_clue_ids"] = row.get("clue_ids", []).duplicate(true)
	if str(row.get("generated_surface_id", "")).strip_edges().is_empty() and not str(row.get("surface_id", "")).strip_edges().is_empty():
		row["generated_surface_id"] = str(row.get("surface_id", "")).strip_edges()
	if bool(row.get("generated_content_surface", false)) and str(row.get("source_system_id", "")).strip_edges().is_empty():
		row["source_system_id"] = "company_story_dossier"
