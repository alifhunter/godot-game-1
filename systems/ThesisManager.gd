extends RefCounted
class_name ThesisManager
## Thesis / research-evidence domain logic moved out of GameManager.
## `gm` is the GameManager autoload instance (untyped to avoid a cyclic reference).

const THESIS_VOCABULARY_SCRIPT = preload("res://systems/ThesisVocabulary.gd")

const QUALITY_GROWTH_BAND_TOP_MIN := 80
const QUALITY_GROWTH_BAND_STRONG_MIN := 65
const QUALITY_GROWTH_BAND_AVERAGE_MIN := 50
const QUALITY_GROWTH_BAND_WEAK_MIN := 35

const RISK_BAND_HIGH_MIN := 80
const RISK_BAND_ELEVATED_MIN := 65
const RISK_BAND_MODERATE_MIN := 45
const RISK_BAND_MANAGEABLE_MIN := 25
const RISK_PROFILE_NEGATIVE_IMPACT_MIN := 58

const THESIS_OPTION_CAP_OWNERSHIP := 4
const THESIS_OPTION_CAP_NEWS := 5
const THESIS_OPTION_CAP_TWOOTER := 5
const THESIS_OPTION_CAP_NETWORK := 4
const THESIS_OPTION_CAP_CORPORATE_EVENTS := 5


static func get_thesis_board_snapshot(gm) -> Dictionary:
	if not RunState.has_active_run():
		return {"theses": [], "companies": [], "research_tray": {"rows": []}}
	var theses: Array = []
	for thesis_value in RunState.get_player_theses().values():
		if typeof(thesis_value) != TYPE_DICTIONARY:
			continue
		var thesis: Dictionary = thesis_value.duplicate(true)
		thesis["has_report"] = not thesis.get("report", {}).is_empty()
		thesis["evidence_count"] = thesis.get("evidence", []).size()
		theses.append(thesis)
	theses.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("updated_day_index", 0)) == int(b.get("updated_day_index", 0)):
			return str(a.get("title", "")) < str(b.get("title", ""))
		return int(a.get("updated_day_index", 0)) > int(b.get("updated_day_index", 0))
	)
	return {
		"day_index": RunState.day_index,
		"trade_date": gm.get_current_trade_date(),
		"theses": theses,
		"companies": thesis_company_options(gm),
		"research_tray": get_research_tray_snapshot(gm)
	}


static func get_research_tray_snapshot(gm, company_id: String = "") -> Dictionary:
	if not RunState.has_active_run():
		return {"day_index": 0, "trade_date": {}, "company_id": str(company_id), "rows": []}
	var normalized_company_id: String = str(company_id)
	var selected_sector_id: String = ""
	if not normalized_company_id.is_empty():
		var selected_company: Dictionary = RunState.get_company(normalized_company_id)
		selected_sector_id = str(selected_company.get("sector_id", "")).strip_edges()
		if selected_sector_id.is_empty() and typeof(selected_company.get("company_profile", {})) == TYPE_DICTIONARY:
			selected_sector_id = str(selected_company.get("company_profile", {}).get("sector_id", "")).strip_edges()
		if selected_sector_id.is_empty():
			selected_sector_id = str(RunState.company_definitions.get(normalized_company_id, {}).get("sector_id", "")).strip_edges()
	var rows: Array = []
	for row_value in RunState.get_thesis_research_tray().values():
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value.duplicate(true)
		if not normalized_company_id.is_empty():
			var row_company_id: String = str(row.get("company_id", "")).strip_edges()
			var row_category: String = str(row.get("category", "")).to_lower()
			var row_sector_id: String = str(row.get("sector_id", "")).strip_edges()
			var sector_context_match: bool = (
				row_company_id.is_empty() and
				row_category == "sector_macro" and
				(row_sector_id.is_empty() or row_sector_id == selected_sector_id)
			)
			if row_company_id != normalized_company_id and not sector_context_match:
				continue
		rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("captured_day_index", 0)) == int(b.get("captured_day_index", 0)):
			return str(a.get("label", "")) < str(b.get("label", ""))
		return int(a.get("captured_day_index", 0)) > int(b.get("captured_day_index", 0))
	)
	return {
		"day_index": RunState.day_index,
		"trade_date": gm.get_current_trade_date(),
		"company_id": normalized_company_id,
		"rows": rows
	}


static func capture_research_evidence(gm, payload: Dictionary) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var company_id: String = str(payload.get("company_id", "")).strip_edges()
	var company: Dictionary = {}
	if not company_id.is_empty():
		company = gm.get_company_snapshot(company_id, false, false, false)
		if company.is_empty():
			return {"success": false, "message": "Unknown company for research evidence."}
	var row: Dictionary = gm.thesis_evidence_capture_system.normalize_capture(payload, {
		"company": company,
		"day_index": RunState.day_index,
		"trade_date": gm.get_current_trade_date()
	})
	if str(row.get("company_id", "")).is_empty():
		row["company_id"] = company_id
	if str(row.get("ticker", "")).is_empty() and not company.is_empty():
		row["ticker"] = str(company.get("ticker", ""))
	if str(row.get("company_name", "")).is_empty() and not company.is_empty():
		row["company_name"] = str(company.get("name", ""))
	if str(row.get("category", "")).is_empty() or str(row.get("label", "")).is_empty():
		return {"success": false, "message": "Pick a valid evidence row first."}
	var tray: Dictionary = RunState.get_thesis_research_tray()
	var dedupe_key: String = research_evidence_dedupe_key(row)
	row["dedupe_key"] = dedupe_key
	for existing_value in tray.values():
		if typeof(existing_value) != TYPE_DICTIONARY:
			continue
		var existing: Dictionary = existing_value
		var existing_key: String = str(existing.get("dedupe_key", ""))
		if existing_key.is_empty():
			existing_key = research_evidence_dedupe_key(existing)
		if not dedupe_key.is_empty() and existing_key == dedupe_key:
			return {
				"success": true,
				"message": "Already in Research Tray.",
				"evidence": existing.duplicate(true),
				"snapshot": get_research_tray_snapshot(gm, str(existing.get("company_id", "")))
			}
	var evidence_id: String = next_research_evidence_id(tray)
	row["id"] = evidence_id
	row["captured_day_index"] = RunState.day_index
	row["day_index"] = RunState.day_index
	row["captured_trade_date"] = gm.get_current_trade_date()
	row["status"] = "active"
	tray[evidence_id] = row
	RunState.set_thesis_research_tray(tray)
	gm._record_steam_progress_event("research_evidence_captured", {
		"source_type": str(row.get("source_type", "")),
		"company_id": str(row.get("company_id", "")),
		"category": str(row.get("category", ""))
	})
	gm._request_autosave("thesis_capture_research")
	gm.thesis_changed.emit()
	return {"success": true, "message": "Added to Research Tray.", "evidence": row, "snapshot": get_research_tray_snapshot(gm, str(row.get("company_id", "")))}


static func research_evidence_dedupe_key(row: Dictionary) -> String:
	var parts: Array = [
		research_dedupe_segment(str(row.get("source_type", "manual"))),
		research_dedupe_segment(str(row.get("company_id", ""))),
		research_dedupe_segment(str(row.get("sector_id", ""))),
		research_dedupe_segment(str(row.get("source_id", ""))),
		research_dedupe_segment(str(row.get("label", ""))),
		research_dedupe_segment(str(row.get("value", ""))),
		research_dedupe_segment(str(row.get("pattern_id", ""))),
		research_dedupe_segment(str(row.get("chart_range", row.get("range_id", "")))),
		research_dedupe_segment(str(row.get("region_label", "")))
	]
	return "|".join(parts)


static func research_dedupe_segment(value: String) -> String:
	return value.strip_edges().to_lower().replace("\n", " ").replace("\t", " ")


static func attach_research_evidence_to_thesis(gm, thesis_id: String, evidence_id: String, interpretation: String = "watch", note: String = "") -> Dictionary:
	var block_reason: String = gm.get_life_action_block_reason("thesis")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if thesis.is_empty():
		return {"success": false, "message": "Unknown thesis."}
	if str(thesis.get("status", "open")) == "closed":
		return {"success": false, "message": "This thesis is closed."}
	var research_row: Dictionary = RunState.get_research_evidence(evidence_id)
	if research_row.is_empty():
		return {"success": false, "message": "This research item is no longer available."}
	var research_company_id: String = str(research_row.get("company_id", "")).strip_edges()
	var thesis_company_id: String = str(thesis.get("company_id", "")).strip_edges()
	if research_company_id != thesis_company_id:
		var thesis_company: Dictionary = RunState.get_company(thesis_company_id)
		var thesis_sector_id: String = str(thesis_company.get("sector_id", "")).strip_edges()
		if thesis_sector_id.is_empty() and typeof(thesis_company.get("company_profile", {})) == TYPE_DICTIONARY:
			thesis_sector_id = str(thesis_company.get("company_profile", {}).get("sector_id", "")).strip_edges()
		if thesis_sector_id.is_empty():
			thesis_sector_id = str(RunState.company_definitions.get(thesis_company_id, {}).get("sector_id", "")).strip_edges()
		var research_sector_id: String = str(research_row.get("sector_id", "")).strip_edges()
		var sector_context_match: bool = (
			research_company_id.is_empty() and
			str(research_row.get("category", "")).to_lower() == "sector_macro" and
			(research_sector_id.is_empty() or research_sector_id == thesis_sector_id)
		)
		if not sector_context_match:
			return {"success": false, "message": "This research belongs to a different stock."}
	for evidence_value in thesis.get("evidence", []):
		if typeof(evidence_value) == TYPE_DICTIONARY and str(evidence_value.get("source_evidence_id", "")) == evidence_id:
			return {"success": false, "message": "Research item is already attached."}
	var evidence_rows: Array = thesis.get("evidence", [])
	var attached: Dictionary = gm.thesis_evidence_capture_system.normalize_attached_evidence(research_row, interpretation, note)
	attached["id"] = next_thesis_evidence_id(evidence_rows)
	attached["source_evidence_id"] = evidence_id
	attached["day_index"] = RunState.day_index
	attached["impact"] = gm.thesis_evidence_capture_system.impact_for_interpretation(str(attached.get("interpretation", interpretation)))
	evidence_rows.append(attached)
	thesis["evidence"] = evidence_rows
	thesis["updated_day_index"] = RunState.day_index
	RunState.set_player_thesis(thesis)
	gm._record_steam_progress_event("research_evidence_attached", {
		"thesis_id": thesis_id,
		"evidence_id": evidence_id,
		"source_type": str(attached.get("source_type", ""))
	})
	gm._request_autosave("thesis_attach_research")
	gm.thesis_changed.emit()
	return {"success": true, "message": "Research attached as %s." % str(attached.get("interpretation_label", "evidence")), "thesis": thesis, "evidence": attached}


static func update_thesis_evidence_interpretation(gm, thesis_id: String, evidence_id: String, fields: Dictionary = {}) -> Dictionary:
	var block_reason: String = gm.get_life_action_block_reason("thesis")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if thesis.is_empty():
		return {"success": false, "message": "Unknown thesis."}
	var rows: Array = []
	var updated_row: Dictionary = {}
	for evidence_value in thesis.get("evidence", []):
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = evidence_value.duplicate(true)
		if str(row.get("id", "")) == evidence_id:
			if fields.has("interpretation"):
				row["interpretation"] = gm.thesis_evidence_capture_system.normalize_interpretation(str(fields.get("interpretation", row.get("interpretation", "watch"))))
				row["interpretation_label"] = gm.thesis_evidence_capture_system.interpretation_label(str(row.get("interpretation", "watch")))
				row["impact"] = gm.thesis_evidence_capture_system.impact_for_interpretation(str(row.get("interpretation", "watch")))
			if fields.has("note") or fields.has("player_note"):
				row["player_note"] = str(fields.get("player_note", fields.get("note", ""))).strip_edges()
			updated_row = row.duplicate(true)
		rows.append(row)
	if updated_row.is_empty():
		return {"success": false, "message": "Unknown evidence row."}
	thesis["evidence"] = rows
	thesis["updated_day_index"] = RunState.day_index
	RunState.set_player_thesis(thesis)
	gm._request_autosave("thesis_update_evidence")
	gm.thesis_changed.emit()
	return {"success": true, "message": "Evidence interpretation updated.", "thesis": thesis, "evidence": updated_row}


static func get_thesis_evidence_options(gm, company_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"company": {}, "categories": []}
	var company: Dictionary = gm.get_company_snapshot(company_id, true, true, true)
	if company.is_empty():
		return {"company": {}, "categories": []}

	var categories: Array = [
		{"id": "fundamentals", "label": thesis_category_label("fundamentals"), "options": thesis_fundamental_options(company)},
		{"id": "financials", "label": thesis_category_label("financials"), "options": thesis_financial_options(company)},
		{"id": "price_action", "label": thesis_category_label("price_action"), "options": thesis_price_action_options(company)},
		{"id": "broker_flow", "label": thesis_category_label("broker_flow"), "options": thesis_broker_options(company)},
		{"id": "ownership", "label": thesis_category_label("ownership"), "options": thesis_ownership_options(company)},
		{"id": "sector_macro", "label": thesis_category_label("sector_macro"), "options": thesis_sector_macro_options(gm, company)},
		{"id": "news", "label": thesis_category_label("news"), "options": thesis_news_options(gm, company)},
		{"id": "twooter", "label": thesis_category_label("twooter"), "options": thesis_twooter_options(gm, company)},
		{"id": "network_intel", "label": thesis_category_label("network_intel"), "options": thesis_network_options(gm, company)},
		{"id": "corporate_events", "label": thesis_category_label("corporate_events"), "options": thesis_corporate_event_options(gm, company)},
		{"id": "risk_invalidation", "label": thesis_category_label("risk_invalidation"), "options": thesis_risk_options(company)}
	]
	return {
		"company": thesis_company_compact(company),
		"categories": categories
	}


static func get_open_theses_for_company(company_id: String) -> Array:
	if not RunState.has_active_run():
		return []
	var normalized_company_id: String = str(company_id)
	var rows: Array = []
	for thesis_value in RunState.get_player_theses().values():
		if typeof(thesis_value) != TYPE_DICTIONARY:
			continue
		var thesis: Dictionary = thesis_value
		if str(thesis.get("company_id", "")) != normalized_company_id:
			continue
		if str(thesis.get("status", "open")) == "closed":
			continue
		rows.append({
			"id": str(thesis.get("id", "")),
			"title": str(thesis.get("title", "")),
			"ticker": str(thesis.get("ticker", "")),
			"company_name": str(thesis.get("company_name", "")),
			"stance": str(thesis.get("stance", "")),
			"horizon": str(thesis.get("horizon", "")),
			"evidence_count": thesis.get("evidence", []).size(),
			"updated_day_index": int(thesis.get("updated_day_index", 0))
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("updated_day_index", 0)) == int(b.get("updated_day_index", 0)):
			return str(a.get("title", "")) < str(b.get("title", ""))
		return int(a.get("updated_day_index", 0)) > int(b.get("updated_day_index", 0))
	)
	return rows


static func add_chart_pattern_evidence_to_thesis(gm, thesis_id: String, claim: Dictionary) -> Dictionary:
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if thesis.is_empty():
		return {"success": false, "message": "Unknown thesis."}
	if str(thesis.get("status", "open")) == "closed":
		return {"success": false, "message": "This thesis is closed."}
	if not bool(claim.get("success", false)):
		return {"success": false, "message": str(claim.get("message", "Complete a valid chart pattern claim first."))}
	var claim_company_id: String = str(claim.get("company_id", thesis.get("company_id", "")))
	if not claim_company_id.is_empty() and claim_company_id != str(thesis.get("company_id", "")):
		return {"success": false, "message": "This pattern claim belongs to a different stock."}
	var evidence: Dictionary = claim.duplicate(true)
	evidence["category"] = "price_action"
	evidence["category_label"] = thesis_category_label("price_action")
	evidence["source_type"] = "chart_pattern"
	evidence["source_label"] = "STOCKBOT Chart"
	var capture_result: Dictionary = capture_research_evidence(gm, evidence)
	if not bool(capture_result.get("success", false)):
		return capture_result
	var captured_id: String = str(capture_result.get("evidence", {}).get("id", ""))
	return attach_research_evidence_to_thesis(gm, thesis_id, captured_id, "watch")


static func create_thesis(gm, company_id: String, stance: String, horizon: String, title: String = "") -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var block_reason: String = gm.get_life_action_block_reason("thesis")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var company: Dictionary = gm.get_company_snapshot(company_id, false, true, true)
	if company.is_empty():
		return {"success": false, "message": "Unknown company selection."}
	var thesis_id: String = next_thesis_id(company_id)
	var normalized_stance: String = normalize_thesis_stance(stance)
	var normalized_horizon: String = normalize_thesis_horizon(horizon)
	var resolved_title: String = title.strip_edges()
	if resolved_title.is_empty():
		resolved_title = "%s %s thesis" % [str(company.get("ticker", company_id.to_upper())), normalized_stance.capitalize()]
	var thesis: Dictionary = {
		"id": thesis_id,
		"company_id": company_id,
		"ticker": str(company.get("ticker", company_id.to_upper())),
		"company_name": str(company.get("name", "")),
		"title": resolved_title,
		"stance": normalized_stance,
		"horizon": normalized_horizon,
		"status": "open",
		"created_day_index": RunState.day_index,
		"created_trade_date": gm.get_current_trade_date(),
		"updated_day_index": RunState.day_index,
		"evidence": [],
		"report": {},
		"review": {}
	}
	RunState.set_player_thesis(thesis)
	gm._record_steam_progress_event("thesis_created", {
		"company_id": company_id,
		"stance": normalized_stance,
		"horizon": normalized_horizon
	})
	gm._request_autosave("thesis_create")
	gm.thesis_changed.emit()
	return {"success": true, "message": "Thesis created.", "thesis": thesis}


static func update_thesis_meta(gm, thesis_id: String, fields: Dictionary) -> Dictionary:
	var block_reason: String = gm.get_life_action_block_reason("thesis")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if thesis.is_empty():
		return {"success": false, "message": "Unknown thesis."}
	if fields.has("title"):
		thesis["title"] = str(fields.get("title", thesis.get("title", ""))).strip_edges()
	if fields.has("stance"):
		thesis["stance"] = normalize_thesis_stance(str(fields.get("stance", thesis.get("stance", "bullish"))))
	if fields.has("horizon"):
		thesis["horizon"] = normalize_thesis_horizon(str(fields.get("horizon", thesis.get("horizon", "swing"))))
	if fields.has("status"):
		var status: String = str(fields.get("status", thesis.get("status", "open"))).to_lower()
		thesis["status"] = "closed" if status == "closed" else "open"
	thesis["updated_day_index"] = RunState.day_index
	RunState.set_player_thesis(thesis)
	gm._request_autosave("thesis_update")
	gm.thesis_changed.emit()
	return {"success": true, "message": "Thesis updated.", "thesis": thesis}


static func add_thesis_evidence(gm, thesis_id: String, evidence: Dictionary) -> Dictionary:
	var block_reason: String = gm.get_life_action_block_reason("thesis")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if thesis.is_empty():
		return {"success": false, "message": "Unknown thesis."}
	var evidence_rows: Array = thesis.get("evidence", [])
	var evidence_id: String = next_thesis_evidence_id(evidence_rows)
	var context: String = "add_thesis_evidence:%s" % str(evidence.get("label", evidence_id))
	var category: String = gm.thesis_evidence_capture_system.normalize_category(str(evidence.get("category", "")), true, context)
	var impact: String = gm.thesis_evidence_capture_system.normalize_impact(str(evidence.get("impact", THESIS_VOCABULARY_SCRIPT.DEFAULT_IMPACT)), true, context)
	var compact_evidence: Dictionary = {
		"id": evidence_id,
		"category": category,
		"category_label": str(evidence.get("category_label", "")),
		"label": str(evidence.get("label", "")),
		"value": str(evidence.get("value", "")),
		"detail": str(evidence.get("detail", "")),
		"source_label": str(evidence.get("source_label", "")),
		"impact": impact,
		"day_index": RunState.day_index
	}
	for key_value in ["source_type", "source_id", "source_evidence_id", "interpretation", "interpretation_label", "player_note"]:
		var key: String = str(key_value)
		if evidence.has(key):
			compact_evidence[key] = str(evidence.get(key, ""))
	var explicit_interpretation: String = str(evidence.get("interpretation", "")).strip_edges()
	if explicit_interpretation.is_empty():
		compact_evidence["interpretation"] = THESIS_VOCABULARY_SCRIPT.DEFAULT_INTERPRETATION
	else:
		compact_evidence["interpretation"] = gm.thesis_evidence_capture_system.normalize_interpretation(explicit_interpretation, true, context)
		compact_evidence["impact"] = THESIS_VOCABULARY_SCRIPT.validate_impact_for_interpretation(str(compact_evidence.get("impact", "")), str(compact_evidence.get("interpretation", "")), context)
	compact_evidence["interpretation_label"] = gm.thesis_evidence_capture_system.interpretation_label(str(compact_evidence.get("interpretation", THESIS_VOCABULARY_SCRIPT.DEFAULT_INTERPRETATION)))
	if str(compact_evidence.get("category_label", "")).strip_edges().is_empty() and not category.is_empty():
		compact_evidence["category_label"] = thesis_category_label(category)
	copy_optional_thesis_evidence_fields(compact_evidence, evidence)
	if str(compact_evidence.get("category", "")).is_empty() or str(compact_evidence.get("label", "")).is_empty():
		return {"success": false, "message": "Pick a valid evidence row first."}
	evidence_rows.append(compact_evidence)
	thesis["evidence"] = evidence_rows
	thesis["updated_day_index"] = RunState.day_index
	RunState.set_player_thesis(thesis)
	gm._request_autosave("thesis_add_evidence")
	gm.thesis_changed.emit()
	return {"success": true, "message": "Evidence added.", "thesis": thesis}


static func remove_thesis_evidence(gm, thesis_id: String, evidence_id: String) -> Dictionary:
	var block_reason: String = gm.get_life_action_block_reason("thesis")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if thesis.is_empty():
		return {"success": false, "message": "Unknown thesis."}
	var next_rows: Array = []
	for evidence_value in thesis.get("evidence", []):
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = evidence_value
		if str(row.get("id", "")) != evidence_id:
			next_rows.append(row)
	thesis["evidence"] = next_rows
	thesis["updated_day_index"] = RunState.day_index
	RunState.set_player_thesis(thesis)
	gm._request_autosave("thesis_remove_evidence")
	gm.thesis_changed.emit()
	return {"success": true, "message": "Evidence removed.", "thesis": thesis}


static func generate_thesis_report(gm, thesis_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run.", "action_cost": gm.THESIS_REPORT_ACTION_COST}
	var block_reason: String = gm.get_life_action_block_reason("thesis")
	if not block_reason.is_empty():
		return {
			"success": false,
			"message": block_reason,
			"action_cost": gm.THESIS_REPORT_ACTION_COST,
			"snapshot": RunState.get_daily_action_snapshot()
		}
	if not RunState.can_spend_daily_action(gm.THESIS_REPORT_ACTION_COST):
		return {
			"success": false,
			"message": "Need %d AP to generate a Thesis report." % gm.THESIS_REPORT_ACTION_COST,
			"action_cost": gm.THESIS_REPORT_ACTION_COST,
			"snapshot": RunState.get_daily_action_snapshot()
		}
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if thesis.is_empty():
		return {"success": false, "message": "Unknown thesis.", "action_cost": gm.THESIS_REPORT_ACTION_COST}
	var context: Dictionary = thesis_report_context(gm, str(thesis.get("company_id", "")))
	var report: Dictionary = gm.thesis_report_system.build_report(thesis, context)
	if report.is_empty():
		return {"success": false, "message": "Could not generate report for this thesis.", "action_cost": gm.THESIS_REPORT_ACTION_COST}
	var spend_result: Dictionary = RunState.spend_daily_action(gm.THESIS_REPORT_ACTION_COST)
	if not bool(spend_result.get("success", false)):
		return {
			"success": false,
			"message": "Need %d AP to generate a Thesis report." % gm.THESIS_REPORT_ACTION_COST,
			"action_cost": gm.THESIS_REPORT_ACTION_COST,
			"snapshot": RunState.get_daily_action_snapshot()
		}
	thesis["report"] = report
	thesis["review"] = gm.thesis_report_system.build_review(thesis, context)
	thesis["updated_day_index"] = RunState.day_index
	RunState.set_player_thesis(thesis)
	gm._request_autosave("thesis_generate_report")
	gm.daily_actions_changed.emit()
	gm.thesis_changed.emit()
	return {
		"success": true,
		"message": "Research note generated. Spent %d AP." % gm.THESIS_REPORT_ACTION_COST,
		"thesis": thesis,
		"report": report,
		"action_cost": gm.THESIS_REPORT_ACTION_COST,
		"snapshot": spend_result.get("snapshot", RunState.get_daily_action_snapshot())
	}


static func refresh_thesis_review(gm, thesis_id: String) -> Dictionary:
	var block_reason: String = gm.get_life_action_block_reason("thesis")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if thesis.is_empty():
		return {"success": false, "message": "Unknown thesis."}
	var context: Dictionary = thesis_report_context(gm, str(thesis.get("company_id", "")))
	var review: Dictionary = gm.thesis_report_system.build_review(thesis, context)
	thesis["review"] = review
	thesis["updated_day_index"] = RunState.day_index
	RunState.set_player_thesis(thesis)
	gm._request_autosave("thesis_refresh_review")
	gm.thesis_changed.emit()
	return {"success": true, "message": "Thesis review refreshed.", "thesis": thesis, "review": review}


static func close_thesis(gm, thesis_id: String) -> Dictionary:
	return update_thesis_meta(gm, thesis_id, {"status": "closed"})


static func thesis_company_options(gm) -> Array:
	var rows: Array = []
	for row_value in gm.get_company_rows():
		var row: Dictionary = row_value
		rows.append({
			"id": str(row.get("id", "")),
			"ticker": str(row.get("ticker", "")),
			"name": str(row.get("name", "")),
			"sector_name": str(row.get("sector_name", "")),
			"current_price": float(row.get("current_price", 0.0)),
			"daily_change_pct": float(row.get("daily_change_pct", 0.0))
		})
	return rows


static func thesis_company_compact(company: Dictionary) -> Dictionary:
	return {
		"id": str(company.get("id", company.get("company_id", ""))),
		"ticker": str(company.get("ticker", "")),
		"name": str(company.get("name", "")),
		"sector_name": str(company.get("sector_name", "")),
		"current_price": float(company.get("current_price", 0.0)),
		"daily_change_pct": float(company.get("daily_change_pct", 0.0))
	}


static func thesis_report_context(gm, company_id: String) -> Dictionary:
	return {
		"day_index": RunState.day_index,
		"trade_date": gm.get_current_trade_date(),
		"company": gm.get_company_snapshot(company_id, true, true, true),
		"macro_state": gm.get_current_macro_state()
	}


static func thesis_fundamental_options(company: Dictionary) -> Array:
	var financials: Dictionary = company.get("financials", {})
	var quality_score: int = int(company.get("quality_score", 0))
	var growth_score: int = int(company.get("growth_score", 0))
	var risk_score: int = int(company.get("risk_score", 0))
	return thesis_options_from_specs([
		thesis_option_spec("fundamentals", "Business quality", thesis_quality_band_label(quality_score), thesis_quality_band_detail(quality_score), impact_from_score(float(quality_score), 62.0, 48.0)),
		thesis_option_spec("fundamentals", "Growth profile", thesis_growth_band_label(growth_score), thesis_growth_band_detail(growth_score), impact_from_score(float(growth_score), 62.0, 48.0)),
		thesis_option_spec("fundamentals", "Risk profile", thesis_risk_band_label(risk_score), thesis_risk_band_detail(risk_score), "negative" if risk_score >= RISK_PROFILE_NEGATIVE_IMPACT_MIN else "positive"),
		thesis_option_spec("fundamentals", "ROE", thesis_format_percent(float(financials.get("roe", 0.0)) / 100.0), "Return on equity gives a quick quality check.", impact_from_score(float(financials.get("roe", 0.0)), 14.0, 8.0)),
		thesis_option_spec("fundamentals", "Debt to equity", "%sx" % String.num(float(financials.get("debt_to_equity", 0.0)), 2), "Leverage affects how much room the thesis has for mistakes.", "negative" if float(financials.get("debt_to_equity", 0.0)) >= 1.0 else "positive")
	])


static func thesis_financial_options(company: Dictionary) -> Array:
	var financials: Dictionary = company.get("financials", {})
	var market_cap: float = float(financials.get("market_cap", 0.0))
	var net_income: float = float(financials.get("net_income", 0.0))
	var pe: float = safe_divide(market_cap, net_income)
	return thesis_options_from_specs([
		thesis_option_spec("financials", "Revenue growth YoY", thesis_format_percent(float(financials.get("revenue_growth_yoy", 0.0)) / 100.0), "Revenue growth helps tell whether the story is expanding or fading.", impact_from_score(float(financials.get("revenue_growth_yoy", 0.0)), 10.0, 0.0)),
		thesis_option_spec("financials", "Earnings growth YoY", thesis_format_percent(float(financials.get("earnings_growth_yoy", 0.0)) / 100.0), "Earnings growth checks whether growth reaches the bottom line.", impact_from_score(float(financials.get("earnings_growth_yoy", 0.0)), 8.0, 0.0)),
		thesis_option_spec("financials", "Net profit margin", thesis_format_percent(float(financials.get("net_profit_margin", 0.0)) / 100.0), "Margin quality helps separate real business strength from noisy sales.", impact_from_score(float(financials.get("net_profit_margin", 0.0)), 8.0, 3.0)),
		thesis_option_spec("valuation", "Current PE", "%sx" % String.num(pe, 2), "PE is an approximate valuation anchor from generated earnings.", "negative" if pe > 20.0 else ("positive" if pe > 0.0 and pe < 12.0 else "mixed")),
		thesis_option_spec("valuation", "Market cap", thesis_format_currency(market_cap), "Market cap helps keep expectations realistic for the company size.", "mixed")
	])


static func thesis_price_action_options(company: Dictionary) -> Array:
	var price_bars: Array = company.get("price_bars", [])
	var recent_return: float = recent_price_bar_return(price_bars, 5)
	return thesis_options_from_specs([
		thesis_option_spec("price_action", "Current price", thesis_format_currency(float(company.get("current_price", 0.0))), "This freezes the entry context for the thesis.", "mixed"),
		thesis_option_spec("price_action", "Daily move", thesis_format_percent(float(company.get("daily_change_pct", 0.0))), "The daily move shows whether the thesis is early or chasing strength.", impact_from_change(float(company.get("daily_change_pct", 0.0)))),
		thesis_option_spec("price_action", "Five-bar trend", thesis_format_percent(recent_return), "Recent bars show whether price action confirms the setup.", impact_from_change(recent_return)),
		thesis_option_spec("price_action", "YTD move", thesis_format_percent(float(company.get("ytd_change_pct", 0.0))), "YTD context helps avoid confusing a late move with an early setup.", impact_from_change(float(company.get("ytd_change_pct", 0.0))))
	])


static func thesis_broker_options(company: Dictionary) -> Array:
	var broker_flow: Dictionary = company.get("broker_flow", {})
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))
	var buyer: String = broker_actor_label_for_thesis(broker_flow, "buy")
	var seller: String = broker_actor_label_for_thesis(broker_flow, "sell")
	return thesis_options_from_specs([
		thesis_option_spec("broker_flow", "Broker flow", flow_tag.capitalize(), "Broker flow checks whether stronger desks are supporting or leaning on the tape.", "positive" if flow_tag == "accumulation" else ("negative" if flow_tag == "distribution" else "mixed")),
		thesis_option_spec("broker_flow", "Dominant buyer", buyer, "Strong buyer identity helps judge the quality of demand.", "positive" if buyer != "Balanced" else "mixed"),
		thesis_option_spec("broker_flow", "Dominant seller", seller, "Strong seller identity is useful risk evidence.", "negative" if seller != "Balanced" else "mixed"),
		thesis_option_spec("broker_flow", "Net pressure", String.num(float(broker_flow.get("net_pressure", 0.0)), 2), "Net pressure gives the tape read a compact direction.", impact_from_change(float(broker_flow.get("net_pressure", 0.0))))
	])


static func thesis_ownership_options(company: Dictionary) -> Array:
	var rows: Array = []
	rows.append(thesis_option("ownership", "Player ownership", thesis_format_percent(float(company.get("ownership_pct", 0.0))), "Your ownership affects meeting eligibility and concentration.", "mixed"))
	rows.append(thesis_option("ownership", "Free float", thesis_format_percent(float(company.get("financials", {}).get("free_float_pct", 0.0)) / 100.0), "Free float shapes liquidity and how crowded the tape can become.", "mixed"))
	for shareholder_value in company.get("shareholder_rows", []):
		if typeof(shareholder_value) != TYPE_DICTIONARY:
			continue
		var shareholder: Dictionary = shareholder_value
		if append_capped_thesis_option(rows, thesis_option("ownership", "Major holder", "%s %s" % [str(shareholder.get("name", "Holder")), thesis_format_percent(float(shareholder.get("ownership_pct", 0.0)))], "Ownership concentration can support or constrain a thesis.", "mixed"), THESIS_OPTION_CAP_OWNERSHIP):
			break
	return rows


static func thesis_sector_macro_options(gm, company: Dictionary) -> Array:
	var rows: Array = []
	var company_sector_id: String = str(company.get("sector_id", ""))
	var company_sector_name: String = "Sector"
	for sector_value in gm.get_sector_rows():
		var sector: Dictionary = sector_value
		if str(sector.get("id", "")) != company_sector_id:
			continue
		company_sector_name = str(sector.get("name", company_sector_name))
		rows.append(thesis_option("sector_macro", "Sector performance", thesis_format_percent(float(sector.get("average_change_pct", 0.0))), thesis_sector_macro_detail("Sector tape shows whether the stock is moving with or against its group.", company_sector_id), impact_from_change(float(sector.get("average_change_pct", 0.0)))))
		rows.append(thesis_option("sector_macro", "Sector breadth", "%d green / %d red" % [int(sector.get("advancers", 0)), int(sector.get("decliners", 0))], thesis_sector_macro_detail("Breadth helps separate broad sector demand from one-stock noise.", company_sector_id), "positive" if int(sector.get("advancers", 0)) >= int(sector.get("decliners", 0)) else "negative"))
		break
	var macro: Dictionary = gm.get_current_macro_state()
	rows.append(thesis_option("sector_macro", "Inflation backdrop", "%s%% YoY" % String.num(float(macro.get("inflation_yoy", 0.0)), 1), thesis_sector_macro_detail("Inflation pressure affects margins, consumer demand, rate expectations, and valuation tolerance.", company_sector_id), thesis_inflation_impact(float(macro.get("inflation_yoy", 0.0)))))
	rows.append(thesis_option("sector_macro", "GDP growth", "%s%%" % String.num(float(macro.get("gdp_growth", 0.0)), 1), thesis_sector_macro_detail("GDP growth is the broad demand backdrop for revenue cycles and market risk appetite.", company_sector_id), thesis_gdp_impact(float(macro.get("gdp_growth", 0.0)))))
	rows.append(thesis_option("sector_macro", "Employment backdrop", "%s / unemployment %s%%" % [str(macro.get("employment_label", "Mixed")), String.num(float(macro.get("unemployment_rate", 0.0)), 1)], thesis_sector_macro_detail("Employment strength helps explain household demand and how much risk the market can carry.", company_sector_id), thesis_employment_impact(float(macro.get("employment_index", 0.0)))))
	rows.append(thesis_option("sector_macro", "Policy rate", thesis_policy_rate_label(macro), thesis_sector_macro_detail("The policy-rate path changes funding cost, valuation appetite, and sector leadership.", company_sector_id), thesis_policy_impact(str(macro.get("central_bank_stance", "hold")))))
	rows.append(thesis_option("sector_macro", "Risk appetite", thesis_risk_appetite_label(float(macro.get("risk_appetite", 0.5))), thesis_sector_macro_detail("Risk appetite is the market-wide willingness to pay for uncertainty.", company_sector_id), thesis_risk_appetite_impact(float(macro.get("risk_appetite", 0.5)))))
	var sector_macro_bias: float = float(macro.get("sector_biases", {}).get(company_sector_id, 0.0))
	rows.append(thesis_option("sector_macro", "Sector macro bias", "%s %s" % [company_sector_name, thesis_format_percent(sector_macro_bias)], thesis_sector_macro_detail("This is the simulator's direct macro tilt for the company's sector from inflation, GDP, employment, rates, and risk appetite.", company_sector_id), impact_from_change(sector_macro_bias)))
	rows.append(thesis_active_macro_shock_option(gm))
	return rows


static func thesis_news_options(gm, company: Dictionary) -> Array:
	var rows: Array = []
	var snapshot: Dictionary = gm.get_news_snapshot()
	for feed_value in snapshot.get("feeds", {}).values():
		if typeof(feed_value) != TYPE_DICTIONARY:
			continue
		var feed: Dictionary = feed_value
		for article_value in feed.get("articles", []):
			if typeof(article_value) != TYPE_DICTIONARY:
				continue
			var article: Dictionary = article_value
			if str(article.get("target_company_id", "")) != str(company.get("id", "")) and str(article.get("target_ticker", "")) != str(company.get("ticker", "")):
				continue
			if append_capped_thesis_option(rows, thesis_option("news", str(article.get("headline", "News article")), str(article.get("public_status_label", article.get("tone", "mixed"))), str(article.get("deck", article.get("body", ""))).left(220), impact_from_tone(str(article.get("tone", "mixed"))), str(feed.get("label", "News"))), THESIS_OPTION_CAP_NEWS):
				return rows
	if rows.is_empty():
		rows.append(thesis_option("news", "No company-specific article", "No current article", "No fresh company-specific News article is available for this stock today.", "mixed", "News"))
	return rows


static func thesis_twooter_options(gm, company: Dictionary) -> Array:
	var rows: Array = []
	var snapshot: Dictionary = gm.get_twooter_snapshot()
	for post_value in snapshot.get("posts", []):
		if typeof(post_value) != TYPE_DICTIONARY:
			continue
		var post: Dictionary = post_value
		if str(post.get("target_ticker", "")) != str(company.get("ticker", "")):
			continue
		if append_capped_thesis_option(rows, thesis_option("twooter", "@%s" % str(post.get("account_handle", "")), str(post.get("post_text", "")).left(120), str(post.get("context_hint", "")), impact_from_tone(str(post.get("tone", "mixed"))), "Twooter"), THESIS_OPTION_CAP_TWOOTER):
			return rows
	if rows.is_empty():
		rows.append(thesis_option("twooter", "No company-specific chatter", "No current post", "No fresh company-specific Twooter post is available for this stock today.", "mixed", "Twooter"))
	return rows


static func thesis_network_options(gm, company: Dictionary) -> Array:
	var rows: Array = []
	var snapshot: Dictionary = gm.get_network_snapshot()
	for contact_value in snapshot.get("contacts", []):
		if typeof(contact_value) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = contact_value
		if not bool(contact.get("met", false)):
			continue
		var company_ids: Array = contact.get("target_company_ids", [])
		var focus_company_id: String = str(contact.get("company_id", ""))
		if focus_company_id != str(company.get("id", "")) and not company_ids.has(str(company.get("id", ""))):
			continue
		if append_capped_thesis_option(rows, thesis_option("network_intel", str(contact.get("display_name", contact.get("name", "Network contact"))), str(contact.get("role", contact.get("affiliation_role", "Contact"))), str(contact.get("last_tip_note", contact.get("description", "Known contact can add private context."))).left(220), "mixed", "Network"), THESIS_OPTION_CAP_NETWORK):
			return rows
	if rows.is_empty():
		rows.append(thesis_option("network_intel", "No met contact", "No private read", "Meet relevant contacts before treating Network as thesis evidence.", "mixed", "Network"))
	return rows


static func thesis_corporate_event_options(gm, company: Dictionary) -> Array:
	var rows: Array = []
	for event_value in gm.get_event_history():
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_value
		if str(event.get("target_company_id", "")) != str(company.get("id", "")):
			continue
		if append_capped_thesis_option(rows, thesis_option("corporate_events", str(event.get("headline", event.get("event_id", "Corporate event"))), str(event.get("summary", event.get("category", ""))).left(140), "Corporate event history can be a catalyst or a risk depending on confirmation.", impact_from_tone(str(event.get("tone", "mixed"))), "Corporate events"), THESIS_OPTION_CAP_CORPORATE_EVENTS):
			return rows
	var meeting_snapshot: Dictionary = gm.get_corporate_meeting_snapshot()
	for meeting_value in meeting_snapshot.get("upcoming_rows", []):
		if typeof(meeting_value) != TYPE_DICTIONARY:
			continue
		var meeting: Dictionary = meeting_value
		if str(meeting.get("company_id", "")) != str(company.get("id", "")):
			continue
		rows.append(thesis_option("corporate_events", str(meeting.get("label", "Corporate meeting")), str(meeting.get("ticker", "")), str(meeting.get("public_summary", "Upcoming meeting can change the setup.")).left(180), "mixed", "Meeting calendar"))
	if rows.is_empty():
		rows.append(thesis_option("corporate_events", "No active corporate event", "No event selected", "No current corporate event is tied to this company.", "mixed", "Corporate events"))
	return rows


static func thesis_risk_options(company: Dictionary) -> Array:
	var financials: Dictionary = company.get("financials", {})
	var risk_score: int = int(company.get("risk_score", 0))
	var debt_to_equity: float = float(financials.get("debt_to_equity", 0.0))
	var daily_change: float = float(company.get("daily_change_pct", 0.0))
	return thesis_options_from_specs([
		thesis_option_spec("risk_invalidation", "Risk profile invalidation", thesis_risk_band_label(risk_score), thesis_risk_band_detail(risk_score), "negative" if risk_score >= RISK_PROFILE_NEGATIVE_IMPACT_MIN else "mixed"),
		thesis_option_spec("risk_invalidation", "Leverage invalidation", "%sx debt/equity" % String.num(debt_to_equity, 2), "If leverage is high, weak earnings can break the thesis faster.", "negative" if debt_to_equity >= 1.0 else "mixed"),
		thesis_option_spec("risk_invalidation", "Price invalidation", "Breaks below today's price by 5%", "If price loses the thesis level, re-check before averaging down.", "negative"),
		thesis_option_spec("risk_invalidation", "Chasing risk", thesis_format_percent(daily_change), "If the move already ran, a good story can still be a bad entry.", "negative" if daily_change > 0.05 else "mixed")
	])


static func thesis_option_spec(category: String, label: String, value: String, detail: String, impact: String = "mixed", source_label: String = "") -> Dictionary:
	return {
		"category": category,
		"label": label,
		"value": value,
		"detail": detail,
		"impact": impact,
		"source_label": source_label
	}


static func thesis_options_from_specs(specs: Array) -> Array:
	var rows: Array = []
	for spec_value in specs:
		if typeof(spec_value) != TYPE_DICTIONARY:
			continue
		var spec: Dictionary = spec_value
		rows.append(thesis_option(
			str(spec.get("category", "")),
			str(spec.get("label", "")),
			str(spec.get("value", "")),
			str(spec.get("detail", "")),
			str(spec.get("impact", THESIS_VOCABULARY_SCRIPT.DEFAULT_IMPACT)),
			str(spec.get("source_label", ""))
		))
	return rows


static func append_capped_thesis_option(rows: Array, option: Dictionary, cap: int) -> bool:
	rows.append(option)
	return rows.size() >= cap


static func thesis_option(category: String, label: String, value: String, detail: String, impact: String = "mixed", source_label: String = "") -> Dictionary:
	var normalized_category: String = THESIS_VOCABULARY_SCRIPT.normalize_category(category, true, "thesis_option:%s" % label)
	var normalized_impact: String = THESIS_VOCABULARY_SCRIPT.normalize_impact(impact, true, "thesis_option:%s" % label)
	return {
		"category": normalized_category,
		"category_label": thesis_category_label(normalized_category),
		"label": label,
		"value": value,
		"detail": detail,
		"impact": normalized_impact,
		"source_label": source_label
	}


static func copy_optional_thesis_evidence_fields(target: Dictionary, source: Dictionary) -> void:
	for key_value in [
		"company_id",
		"ticker",
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
		var key: String = str(key_value)
		if source.has(key):
			target[key] = str(source.get(key, ""))
	for key_value in ["start_price", "end_price", "current_price"]:
		var key: String = str(key_value)
		if source.has(key):
			target[key] = float(source.get(key, 0.0))
	for key_value in ["start_anchor", "end_anchor", "start_date", "end_date", "report_date", "captured_trade_date"]:
		var key: String = str(key_value)
		if typeof(source.get(key, {})) == TYPE_DICTIONARY:
			target[key] = source.get(key, {}).duplicate(true)


static func thesis_category_label(category: String) -> String:
	return THESIS_VOCABULARY_SCRIPT.category_label(category)


static func next_thesis_id(company_id: String) -> String:
	var index: int = RunState.get_player_theses().size() + 1
	while true:
		var thesis_id: String = "thesis_%s_%03d" % [company_id, index]
		if RunState.get_player_thesis(thesis_id).is_empty():
			return thesis_id
		index += 1
	return "thesis_%s_%03d" % [company_id, index]


static func next_thesis_evidence_id(evidence_rows: Array) -> String:
	var index: int = evidence_rows.size() + 1
	while true:
		var evidence_id: String = "evidence_%03d" % index
		var found: bool = false
		for row_value in evidence_rows:
			if typeof(row_value) == TYPE_DICTIONARY and str(row_value.get("id", "")) == evidence_id:
				found = true
				break
		if not found:
			return evidence_id
		index += 1
	return "evidence_%03d" % index


static func next_research_evidence_id(tray: Dictionary) -> String:
	var index: int = tray.size() + 1
	while true:
		var evidence_id: String = "research_%03d" % index
		if not tray.has(evidence_id):
			return evidence_id
		index += 1
	return "research_%03d" % index


static func normalize_thesis_stance(stance: String) -> String:
	return THESIS_VOCABULARY_SCRIPT.normalize_stance(stance)


static func normalize_thesis_horizon(horizon: String) -> String:
	return THESIS_VOCABULARY_SCRIPT.normalize_horizon(horizon)


static func recent_price_bar_return(price_bars: Array, lookback: int) -> float:
	if price_bars.size() < 2:
		return 0.0
	var end_bar: Dictionary = price_bars[price_bars.size() - 1]
	var start_index: int = max(price_bars.size() - lookback, 0)
	var start_bar: Dictionary = price_bars[start_index]
	var start_price: float = float(start_bar.get("close", start_bar.get("price", 0.0)))
	var end_price: float = float(end_bar.get("close", end_bar.get("price", 0.0)))
	if is_zero_approx(start_price):
		return 0.0
	return (end_price - start_price) / start_price


static func thesis_quality_band_label(score: int) -> String:
	if score >= QUALITY_GROWTH_BAND_TOP_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_label("quality", score, "Excellent")
	if score >= QUALITY_GROWTH_BAND_STRONG_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_label("quality", score, "Strong")
	if score >= QUALITY_GROWTH_BAND_AVERAGE_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_label("quality", score, "Average")
	if score >= QUALITY_GROWTH_BAND_WEAK_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_label("quality", score, "Weak")
	return THESIS_VOCABULARY_SCRIPT.band_label("quality", score, "Fragile")


static func thesis_growth_band_label(score: int) -> String:
	if score >= QUALITY_GROWTH_BAND_TOP_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_label("growth", score, "Accelerating")
	if score >= QUALITY_GROWTH_BAND_STRONG_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_label("growth", score, "Healthy")
	if score >= QUALITY_GROWTH_BAND_AVERAGE_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_label("growth", score, "Steady")
	if score >= QUALITY_GROWTH_BAND_WEAK_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_label("growth", score, "Uneven")
	return THESIS_VOCABULARY_SCRIPT.band_label("growth", score, "Stalling")


static func thesis_risk_band_label(score: int) -> String:
	if score >= RISK_BAND_HIGH_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_label("risk", score, "High")
	if score >= RISK_BAND_ELEVATED_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_label("risk", score, "Elevated")
	if score >= RISK_BAND_MODERATE_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_label("risk", score, "Moderate")
	if score >= RISK_BAND_MANAGEABLE_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_label("risk", score, "Manageable")
	return THESIS_VOCABULARY_SCRIPT.band_label("risk", score, "Low")


static func thesis_quality_band_detail(score: int) -> String:
	if score >= QUALITY_GROWTH_BAND_TOP_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_detail("quality", score, "Excellent quality can support conviction, but the entry and valuation still need confirmation.")
	if score >= QUALITY_GROWTH_BAND_STRONG_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_detail("quality", score, "Strong quality gives the thesis fundamental support if valuation is still reasonable.")
	if score >= QUALITY_GROWTH_BAND_AVERAGE_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_detail("quality", score, "Average quality is workable, but the stock needs help from price action, valuation, or catalysts.")
	if score >= QUALITY_GROWTH_BAND_WEAK_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_detail("quality", score, "Weak quality means the thesis needs clear confirmation before adding size.")
	return THESIS_VOCABULARY_SCRIPT.band_detail("quality", score, "Fragile quality means the thesis needs more than one bullish signal before it deserves conviction.")


static func thesis_growth_band_detail(score: int) -> String:
	if score >= QUALITY_GROWTH_BAND_TOP_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_detail("growth", score, "Accelerating growth can justify a stronger upside case if margins and tape confirm.")
	if score >= QUALITY_GROWTH_BAND_STRONG_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_detail("growth", score, "Healthy growth supports a constructive thesis when valuation is not stretched.")
	if score >= QUALITY_GROWTH_BAND_AVERAGE_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_detail("growth", score, "Steady growth is useful, but it rarely carries the thesis alone.")
	if score >= QUALITY_GROWTH_BAND_WEAK_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_detail("growth", score, "Uneven growth is not broken, but it needs confirmation from fresh financials or catalysts.")
	return THESIS_VOCABULARY_SCRIPT.band_detail("growth", score, "Stalling growth needs either a valuation gap, turnaround catalyst, or clear tape support.")


static func thesis_risk_band_detail(score: int) -> String:
	if score >= RISK_BAND_HIGH_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_detail("risk", score, "High risk needs tight invalidation and strong evidence before the position can be sized.")
	if score >= RISK_BAND_ELEVATED_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_detail("risk", score, "Elevated risk means the idea can work, but only with clear confirmation and controlled size.")
	if score >= RISK_BAND_MODERATE_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_detail("risk", score, "Moderate risk demands confirmation, but it does not reject the idea by itself.")
	if score >= RISK_BAND_MANAGEABLE_MIN:
		return THESIS_VOCABULARY_SCRIPT.band_detail("risk", score, "Manageable risk gives the thesis room to develop if evidence stays consistent.")
	return THESIS_VOCABULARY_SCRIPT.band_detail("risk", score, "Low risk gives the thesis more room, though price and valuation still matter.")


static func thesis_policy_rate_label(macro: Dictionary) -> String:
	var stance: String = str(macro.get("central_bank_stance", "hold")).capitalize()
	var rate: float = float(macro.get("policy_rate", 0.0))
	var bps: int = int(macro.get("policy_action_bps", 0))
	return "%s to %s%% (%+d bps)" % [stance, String.num(rate, 2), bps]


static func thesis_risk_appetite_label(risk_appetite: float) -> String:
	if risk_appetite >= 0.64:
		return "Risk-on"
	if risk_appetite >= 0.54:
		return "Constructive"
	if risk_appetite <= 0.36:
		return "Risk-off"
	if risk_appetite <= 0.46:
		return "Defensive"
	return "Neutral"


static func thesis_sector_macro_detail(base_detail: String, sector_id: String) -> String:
	var focus: String = thesis_sector_macro_focus(sector_id)
	if focus.is_empty():
		return base_detail
	return "%s Sector lens: %s." % [base_detail, focus]


static func thesis_sector_macro_focus(sector_id: String) -> String:
	return THESIS_VOCABULARY_SCRIPT.sector_macro_focus(sector_id)


static func thesis_active_macro_shock_option(gm) -> Dictionary:
	var active_events: Array = gm.get_active_special_events()
	if active_events.is_empty():
		return thesis_option("sector_macro", "Active macro shock", "None", "No active special macro shock is currently pressuring the tape.", "mixed", "Macro shocks")
	var event: Dictionary = active_events[0] if typeof(active_events[0]) == TYPE_DICTIONARY else {}
	var headline: String = str(event.get("headline", event.get("headline_detail", event.get("event_id", "Macro shock"))))
	var detail: String = str(event.get("description", event.get("headline_detail", "An active macro shock is changing volatility, market bias, or sector leadership.")))
	return thesis_option("sector_macro", "Active macro shock", headline, detail.left(220), impact_from_tone(str(event.get("tone", "mixed"))), "Macro shocks")


static func thesis_inflation_impact(inflation_yoy: float) -> String:
	if inflation_yoy >= 4.6:
		return "negative"
	if inflation_yoy <= 2.8:
		return "positive"
	return "mixed"


static func thesis_gdp_impact(gdp_growth: float) -> String:
	if gdp_growth >= 5.2:
		return "positive"
	if gdp_growth <= 3.4:
		return "negative"
	return "mixed"


static func thesis_employment_impact(employment_index: float) -> String:
	if employment_index >= 0.58:
		return "positive"
	if employment_index <= 0.42:
		return "negative"
	return "mixed"


static func thesis_policy_impact(central_bank_stance: String) -> String:
	var normalized: String = central_bank_stance.to_lower()
	if normalized == "cut":
		return "positive"
	if normalized == "hike":
		return "negative"
	return "mixed"


static func thesis_risk_appetite_impact(risk_appetite: float) -> String:
	if risk_appetite >= 0.54:
		return "positive"
	if risk_appetite <= 0.46:
		return "negative"
	return "mixed"


static func impact_from_score(value: float, positive_threshold: float, negative_threshold: float) -> String:
	if value >= positive_threshold:
		return "positive"
	if value <= negative_threshold:
		return "negative"
	return "mixed"


static func impact_from_change(value: float) -> String:
	if value > 0.005:
		return "positive"
	if value < -0.005:
		return "negative"
	return "mixed"


static func impact_from_tone(tone: String) -> String:
	var normalized: String = tone.to_lower()
	if normalized in ["positive", "bullish", "constructive"]:
		return "positive"
	if normalized in ["negative", "bearish", "defensive"]:
		return "negative"
	return "mixed"


static func broker_actor_label_for_thesis(broker_flow: Dictionary, side: String) -> String:
	var broker_code_key: String = "dominant_buy_broker_code" if side == "buy" else "dominant_sell_broker_code"
	var broker_type_key: String = "dominant_buy_broker_type" if side == "buy" else "dominant_sell_broker_type"
	var fallback_key: String = "dominant_buyer" if side == "buy" else "dominant_seller"
	var broker_code: String = str(broker_flow.get(broker_code_key, ""))
	if not broker_code.is_empty():
		return broker_code
	var fallback_value: String = str(broker_flow.get(broker_type_key, broker_flow.get(fallback_key, "balanced")))
	return "Balanced" if fallback_value.is_empty() else fallback_value.capitalize()


static func thesis_format_currency(value: float) -> String:
	var sign_prefix: String = "-" if value < 0.0 else ""
	var abs_value: float = abs(value)
	if abs_value >= 1000000000000.0:
		return "%sRp%sT" % [sign_prefix, String.num(abs_value / 1000000000000.0, 2)]
	if abs_value >= 1000000000.0:
		return "%sRp%sB" % [sign_prefix, String.num(abs_value / 1000000000.0, 2)]
	if abs_value >= 1000000.0:
		return "%sRp%sM" % [sign_prefix, String.num(abs_value / 1000000.0, 2)]
	return "%sRp%s" % [sign_prefix, String.num(abs_value, 2)]


static func thesis_format_percent(value: float) -> String:
	var sign_prefix: String = "+" if value > 0.0 else ""
	return "%s%s%%" % [sign_prefix, String.num(value * 100.0, 2)]


static func safe_divide(numerator: float, denominator: float) -> float:
	if is_zero_approx(denominator):
		return 0.0
	return numerator / denominator
