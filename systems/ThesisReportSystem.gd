extends RefCounted

const RATING_BUY := "Buy"
const RATING_ACCUMULATE := "Accumulate"
const RATING_WATCH := "Hold/Watch"
const RATING_TRADE_ONLY := "Trade Only"
const RATING_AVOID := "Avoid"
const RATING_DIVIDEND_HOLD := "Dividend Hold"
const CORE_DISCIPLINE_PILLARS := [
	{"id": "anchor", "label": "Anchor", "categories": ["fundamentals", "key_stats", "financials", "valuation"], "missing_note": "Add a Fundamentals, Financials, or Valuation anchor."},
	{"id": "price", "label": "Price", "categories": ["price_action"], "missing_note": "Add Price Action so the thesis has an entry context."},
	{"id": "tape", "label": "Tape", "categories": ["broker_flow"], "missing_note": "Add Broker Flow to check whether the tape agrees."},
	{"id": "catalyst", "label": "Catalyst", "categories": ["news", "twooter", "network_intel", "corporate_events", "sector_macro"], "missing_note": "Add a catalyst or market-context check."},
	{"id": "risk", "label": "Invalidation", "categories": ["risk_invalidation"], "missing_note": "Add a Risk / Invalidation point before sizing up."}
]


func build_report(thesis: Dictionary, context: Dictionary) -> Dictionary:
	var company: Dictionary = context.get("company", {})
	if company.is_empty():
		return {}

	var evidence: Array = thesis.get("evidence", [])
	var score_data: Dictionary = _score_evidence(thesis, evidence)
	var score: int = int(score_data.get("score", 0))
	var grade: String = _grade_for_score(score)
	var rating: String = _rating_for(thesis, company, score, score_data)
	var price: float = float(company.get("current_price", 0.0))
	var target: Dictionary = _target_range_for(thesis, company, score, score_data)
	var report_date: Dictionary = context.get("trade_date", {})

	return {
		"generated_day_index": int(context.get("day_index", 0)),
		"generated_trade_date": report_date.duplicate(true),
		"generated_date_label": _format_trade_date(report_date),
		"company_id": str(thesis.get("company_id", company.get("id", ""))),
		"ticker": str(company.get("ticker", "")),
		"company_name": str(company.get("name", "")),
		"sector_name": str(company.get("sector_name", "Unknown")),
		"stance": str(thesis.get("stance", "bullish")),
		"horizon": str(thesis.get("horizon", "swing")),
		"report_price": price,
		"rating": rating,
		"reasoning_score": score,
		"reasoning_grade": grade,
		"missing_notes": score_data.get("missing_notes", []).duplicate(),
		"discipline_rows": score_data.get("discipline_rows", []).duplicate(true),
		"target": target,
		"implied_upside_pct": float(target.get("implied_upside_pct", 0.0)),
		"sections": _build_sections(thesis, company, evidence, score_data, rating, target)
	}


func build_review(thesis: Dictionary, context: Dictionary) -> Dictionary:
	var company: Dictionary = context.get("company", {})
	var report: Dictionary = thesis.get("report", {})
	if company.is_empty() or report.is_empty():
		return {
			"state": "Needs Review",
			"summary": "Generate a report first, then review how the thesis ages against the tape.",
			"updated_day_index": int(context.get("day_index", 0))
		}

	var stance: String = str(thesis.get("stance", report.get("stance", "bullish"))).to_lower()
	var report_price: float = max(float(report.get("report_price", 0.0)), 0.0)
	var current_price: float = float(company.get("current_price", 0.0))
	var return_pct: float = 0.0
	if report_price > 0.0:
		return_pct = (current_price - report_price) / report_price
	var broker_flow: Dictionary = company.get("broker_flow", {})
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))
	var lots_owned: int = int(company.get("lots_owned", 0))
	var unrealized_pnl: float = float(company.get("unrealized_pnl", 0.0))

	var state: String = "Unchanged"
	if stance == "bearish":
		if return_pct <= -0.03 or flow_tag == "distribution":
			state = "Strengthening"
		elif return_pct >= 0.03 or flow_tag == "accumulation":
			state = "Weakening"
	elif stance == "income":
		if return_pct >= -0.03 and flow_tag != "distribution":
			state = "Strengthening"
		elif return_pct <= -0.06 or flow_tag == "distribution":
			state = "Weakening"
	else:
		if return_pct >= 0.03 or flow_tag == "accumulation":
			state = "Strengthening"
		elif return_pct <= -0.03 or flow_tag == "distribution":
			state = "Weakening"

	var summary: String = "%s is %s from the report price. Broker flow is %s." % [
		str(company.get("ticker", "")),
		_format_signed_percent(return_pct),
		flow_tag.capitalize()
	]
	if lots_owned > 0:
		summary += " You hold %d lot(s); open P/L is %s." % [lots_owned, _format_currency(unrealized_pnl)]
	else:
		summary += " You do not currently hold the position."

	return {
		"state": state,
		"summary": summary,
		"report_price": report_price,
		"current_price": current_price,
		"return_pct": return_pct,
		"lots_owned": lots_owned,
		"unrealized_pnl": unrealized_pnl,
		"flow_tag": flow_tag,
		"updated_day_index": int(context.get("day_index", 0)),
		"updated_trade_date": context.get("trade_date", {}).duplicate(true)
	}


func _score_evidence(thesis: Dictionary, evidence: Array) -> Dictionary:
	var categories: Dictionary = {}
	var positive_count: int = 0
	var negative_count: int = 0
	var mixed_count: int = 0
	var weak_pattern_count: int = 0
	var contradicted_pattern_count: int = 0
	for evidence_value in evidence:
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = evidence_value
		var category: String = str(row.get("category", ""))
		if not category.is_empty():
			categories[category] = true
		if category == "price_action":
			var feedback_state: String = str(row.get("feedback_state", "")).to_lower()
			if feedback_state == "weak read":
				weak_pattern_count += 1
			elif feedback_state == "contradicted":
				contradicted_pattern_count += 1
		var impact: String = str(row.get("impact", "mixed"))
		if impact == "positive":
			positive_count += 1
		elif impact == "negative":
			negative_count += 1
		else:
			mixed_count += 1

	var score: int = 18
	score += min(categories.size(), 8) * 7
	score += min(evidence.size(), 10) * 2
	if _has_any_category(categories, ["fundamentals", "key_stats", "financials", "valuation"]):
		score += 10
	if categories.has("price_action"):
		score += 8
	if categories.has("broker_flow"):
		score += 7
	if _has_any_category(categories, ["news", "twooter", "network_intel", "corporate_events"]):
		score += 8
	if categories.has("risk_invalidation"):
		score += 14
	if categories.has("network_intel"):
		score += 4

	var stance: String = str(thesis.get("stance", "bullish")).to_lower()
	var contradiction_count: int = 0
	if stance == "bearish":
		contradiction_count = positive_count
	elif stance == "income":
		contradiction_count = max(negative_count - 1, 0)
	else:
		contradiction_count = negative_count
	score -= min(contradiction_count, 4) * 5

	var public_only: bool = _has_any_category(categories, ["news", "twooter"]) and not _has_any_category(categories, ["fundamentals", "financials", "valuation", "price_action", "broker_flow", "network_intel", "risk_invalidation"])
	if public_only:
		score -= 18
	if not categories.has("risk_invalidation"):
		score -= 12
	var discipline_rows: Array = _discipline_rows(categories)
	var missing_pillar_count: int = _missing_pillar_count(discipline_rows)
	score -= missing_pillar_count * 3
	score -= weak_pattern_count * 3
	score -= contradicted_pattern_count * 7

	var missing_notes: Array = []
	for discipline_value in discipline_rows:
		var discipline_row: Dictionary = discipline_value
		if not bool(discipline_row.get("complete", false)):
			missing_notes.append(str(discipline_row.get("missing_note", "")))
	if public_only:
		missing_notes.append("Public chatter alone is not enough for an investment thesis.")
	if contradiction_count > 0:
		missing_notes.append("Address evidence that pushes against your stance.")
	if weak_pattern_count > 0:
		missing_notes.append("Treat weak chart-pattern evidence as a question, not confirmation.")
	if contradicted_pattern_count > 0:
		missing_notes.append("Resolve chart-pattern evidence that the coaching marked as contradicted.")

	return {
		"score": clamp(score, 0, 100),
		"categories": categories,
		"discipline_rows": discipline_rows,
		"missing_pillar_count": missing_pillar_count,
		"positive_count": positive_count,
		"negative_count": negative_count,
		"mixed_count": mixed_count,
		"contradiction_count": contradiction_count,
		"weak_pattern_count": weak_pattern_count,
		"contradicted_pattern_count": contradicted_pattern_count,
		"missing_notes": missing_notes
	}


func _rating_for(thesis: Dictionary, company: Dictionary, score: int, score_data: Dictionary) -> String:
	var stance: String = str(thesis.get("stance", "bullish")).to_lower()
	var quality: int = int(company.get("quality_score", 0))
	var growth: int = int(company.get("growth_score", 0))
	var risk: int = int(company.get("risk_score", 0))
	var flow_tag: String = str(company.get("broker_flow", {}).get("flow_tag", "neutral"))
	var contradiction_count: int = int(score_data.get("contradiction_count", 0))
	var categories: Dictionary = score_data.get("categories", {})
	var missing_pillar_count: int = int(score_data.get("missing_pillar_count", 0))
	var has_anchor: bool = _has_any_category(categories, ["fundamentals", "key_stats", "financials", "valuation"])
	var has_price: bool = categories.has("price_action")
	var has_invalidation: bool = categories.has("risk_invalidation")
	var has_contradicted_pattern: bool = int(score_data.get("contradicted_pattern_count", 0)) > 0

	if stance == "bearish":
		if score >= 70 and missing_pillar_count <= 1:
			return RATING_AVOID
		return RATING_TRADE_ONLY
	if stance == "income":
		return RATING_DIVIDEND_HOLD if score >= 64 and risk <= 58 and has_anchor and has_invalidation else RATING_WATCH
	if has_contradicted_pattern:
		return RATING_WATCH if score >= 52 else RATING_AVOID
	if score >= 84 and quality >= 62 and risk <= 62 and contradiction_count == 0 and missing_pillar_count == 0:
		return RATING_BUY
	if score >= 70 and has_anchor and has_price and has_invalidation and contradiction_count <= 1 and (growth >= 58 or flow_tag == "accumulation"):
		return RATING_ACCUMULATE
	if score >= 54:
		return RATING_WATCH
	if flow_tag == "accumulation" and growth >= 60 and has_price:
		return RATING_TRADE_ONLY
	return RATING_AVOID


func _target_range_for(thesis: Dictionary, company: Dictionary, score: int, score_data: Dictionary) -> Dictionary:
	var price: float = max(float(company.get("current_price", 0.0)), 0.0)
	if price <= 0.0:
		return {"defensible": false, "label": "No target available", "low": 0.0, "high": 0.0, "implied_upside_pct": 0.0}

	var categories: Dictionary = score_data.get("categories", {})
	var has_anchor: bool = _has_any_category(categories, ["fundamentals", "key_stats", "financials", "valuation"])
	var has_entry_check: bool = categories.has("price_action")
	var has_risk_check: bool = categories.has("risk_invalidation")
	var missing_pillar_count: int = int(score_data.get("missing_pillar_count", 0))
	var quality: float = float(company.get("quality_score", 50))
	var growth: float = float(company.get("growth_score", 50))
	var risk: float = float(company.get("risk_score", 50))
	var stance: String = str(thesis.get("stance", "bullish")).to_lower()
	var fair_value_bias: float = clamp(((quality - 55.0) / 220.0) + ((growth - 55.0) / 240.0) - ((risk - 45.0) / 260.0) + ((float(score) - 60.0) / 260.0), -0.28, 0.38)
	fair_value_bias *= clamp(1.0 - float(missing_pillar_count) * 0.12, 0.52, 1.0)
	if stance == "bearish":
		fair_value_bias = -abs(fair_value_bias)
	elif stance == "income":
		fair_value_bias = clamp(fair_value_bias * 0.55, -0.12, 0.18)

	var midpoint: float = price * (1.0 + fair_value_bias)
	var low: float = midpoint * 0.94
	var high: float = midpoint * 1.06
	var implied: float = 0.0
	if price > 0.0:
		implied = (midpoint - price) / price
	var label: String = "%s - %s" % [_format_currency(low), _format_currency(high)]
	var defensible: bool = has_anchor and has_entry_check and has_risk_check and score >= 45
	if not defensible:
		label = "Not defensible yet; working range %s - %s" % [_format_currency(low), _format_currency(high)]
	return {
		"defensible": defensible,
		"label": label,
		"low": low,
		"high": high,
		"midpoint": midpoint,
		"implied_upside_pct": implied
	}


func _build_sections(thesis: Dictionary, company: Dictionary, evidence: Array, score_data: Dictionary, rating: String, target: Dictionary) -> Array:
	var thesis_bullets: Array = _investment_thesis_bullets(company, thesis, evidence, score_data)
	var valuation_bullets: Array = _valuation_recommendation_bullets(thesis, company, score_data, rating, target)
	var risk_bullets: Array = _investment_risk_bullets(company, evidence, score_data, target)
	var catalyst_bullets: Array = _catalyst_check_bullets(evidence)
	var tape_bullets: Array = _tape_bullets(company, evidence)
	return [
		{
			"title": "Investment Thesis",
			"bullets": thesis_bullets,
			"body": _format_claim_bullets(thesis_bullets)
		},
		{
			"title": "Valuation & Recommendation",
			"bullets": valuation_bullets,
			"body": _format_claim_bullets(valuation_bullets)
		},
		{
			"title": "Investment Risks",
			"bullets": risk_bullets,
			"body": _format_claim_bullets(risk_bullets)
		},
		{
			"title": "Catalysts / Checks",
			"bullets": catalyst_bullets,
			"body": _format_claim_bullets(catalyst_bullets)
		},
		{
			"title": "Tape / Broker Flow",
			"bullets": tape_bullets,
			"body": _format_claim_bullets(tape_bullets)
		},
		{
			"title": "Learning Note",
			"body": _learning_note(score_data)
		}
	]


func _investment_thesis_bullets(company: Dictionary, thesis: Dictionary, evidence: Array, score_data: Dictionary) -> Array:
	var bullets: Array = []
	var categories: Dictionary = score_data.get("categories", {})
	if categories.has("fundamentals"):
		bullets.append(_make_claim_bullet(_quality_profile_claim(company), _quality_profile_body(company, thesis)))
	else:
		bullets.append(_make_claim_bullet("FUNDAMENTAL ANCHOR STILL MISSING", "No fundamentals evidence has been selected yet, so the thesis should lean less on long-term business quality and more on observable confirmation."))

	var financial_row: Dictionary = _first_evidence(evidence, ["financials", "valuation"])
	if not financial_row.is_empty():
		bullets.append(_make_claim_bullet("VALUATION ANCHOR", _evidence_sentence(financial_row, "This gives the thesis a financial anchor instead of relying only on story or tape.")))

	var price_row: Dictionary = _first_pattern_evidence(evidence, "price_action")
	if price_row.is_empty():
		price_row = _first_evidence(evidence, ["price_action"])
	if not price_row.is_empty():
		bullets.append(_make_claim_bullet("PRICE ACTION CHECK", _price_action_sentence(price_row)))

	var public_row: Dictionary = _first_evidence(evidence, ["news", "twooter", "network_intel", "corporate_events", "sector_macro"])
	if not public_row.is_empty():
		bullets.append(_make_claim_bullet(_catalyst_claim_for(public_row), _evidence_sentence(public_row, "This selected source gives the thesis a concrete watch item.")))

	if bullets.size() <= 1:
		bullets.append(_make_claim_bullet("EVIDENCE BASE STILL FORMING", "Add valuation, price action, broker flow, and a risk/invalidation point before treating this as more than a watchlist idea."))
	return bullets


func _valuation_recommendation_bullets(thesis: Dictionary, company: Dictionary, score_data: Dictionary, rating: String, target: Dictionary) -> Array:
	var bullets: Array = []
	var ticker: String = str(company.get("ticker", ""))
	var stance: String = str(thesis.get("stance", "bullish")).capitalize()
	var horizon: String = str(thesis.get("horizon", "swing")).capitalize()
	var current_price: String = _format_currency(float(company.get("current_price", 0.0)))
	var target_label: String = str(target.get("label", ""))
	var implied_move: String = _format_signed_percent(float(target.get("implied_upside_pct", 0.0)))
	if bool(target.get("defensible", false)):
		bullets.append(_make_claim_bullet(
			"%s AT CURRENT PRICE" % rating.to_upper(),
			"%s is framed as a %s thesis over a %s horizon. Current price is %s, with a target area of %s and an implied midpoint move of %s." % [ticker, stance, horizon, current_price, target_label, implied_move]
		))
	else:
		bullets.append(_make_claim_bullet(
			"NO DEFENSIBLE TARGET YET",
			"%s is framed as a %s thesis, but the selected evidence does not yet support a confident target. Current price is %s; working range is %s." % [ticker, stance, current_price, target_label]
		))

	var missing_notes: Array = score_data.get("missing_notes", [])
	var grade: String = _grade_for_score(int(score_data.get("score", 0)))
	if missing_notes.is_empty():
		bullets.append(_make_claim_bullet("PROCESS QUALITY SUPPORTS THE CALL", "The reasoning grade is %s because the thesis includes enough evidence categories, risk handling, and confirmation checks to support a disciplined decision." % grade))
	else:
		bullets.append(_make_claim_bullet("GRADE LIMITED BY EVIDENCE GAPS", "The reasoning grade is %s because the report still needs: %s" % [grade, "; ".join(_plain_notes(missing_notes, 3))]))
	return bullets


func _investment_risk_bullets(company: Dictionary, evidence: Array, score_data: Dictionary, target: Dictionary) -> Array:
	var bullets: Array = []
	var risk_rows: Array = _evidence_rows(evidence, ["risk_invalidation"])
	var risk_score: int = int(company.get("risk_score", 0))
	if not risk_rows.is_empty():
		for row_value in risk_rows.slice(0, min(risk_rows.size(), 3)):
			var row: Dictionary = row_value
			bullets.append(_make_claim_bullet(_claim_from_label(str(row.get("label", "Risk"))), _evidence_sentence(row, "This is the selected condition that should force a review.")))
	else:
		bullets.append(_make_claim_bullet("NO EXPLICIT INVALIDATION", "No risk or invalidation evidence has been selected. The report should stay low conviction until the player defines what would break the idea."))

	bullets.append(_make_claim_bullet("%s RISK PROFILE" % _risk_band_label(risk_score).to_upper(), _risk_profile_body(risk_score)))
	if int(score_data.get("contradiction_count", 0)) > 0:
		bullets.append(_make_claim_bullet("CONTRADICTION RISK", "At least one selected evidence item pushes against the chosen stance. The thesis needs an explicit explanation before confidence can rise."))
	if not bool(target.get("defensible", false)):
		bullets.append(_make_claim_bullet("VALUATION RISK", "The target area is not defensible yet, so price upside should be treated as a scenario rather than a conclusion."))
	return bullets


func _catalyst_check_bullets(evidence: Array) -> Array:
	var rows: Array = _evidence_rows(evidence, ["news", "twooter", "network_intel", "corporate_events", "sector_macro"])
	var bullets: Array = []
	for row_value in rows.slice(0, min(rows.size(), 4)):
		var row: Dictionary = row_value
		bullets.append(_make_claim_bullet(_catalyst_claim_for(row), _evidence_sentence(row, "Track whether this evidence is confirmed or contradicted by later filings, tape, or contacts.")))
	if bullets.is_empty():
		bullets.append(_make_claim_bullet("NO CLEAR CATALYST SELECTED", "No News, Twooter, Network, corporate-event, or sector/macro catalyst is attached yet. The thesis may still be valid, but the timing case is weak."))
	return bullets


func _tape_bullets(company: Dictionary, evidence: Array) -> Array:
	var bullets: Array = []
	var broker_row: Dictionary = _first_evidence(evidence, ["broker_flow"])
	if broker_row.is_empty():
		bullets.append(_make_claim_bullet("TAPE NOT CONFIRMED", _tape_read(company)))
	else:
		bullets.append(_make_claim_bullet("TAPE CONFIRMATION", _evidence_sentence(broker_row, _tape_read(company))))
	return bullets


func _make_claim_bullet(claim: String, body: String) -> Dictionary:
	return {
		"claim": _claim_from_label(claim),
		"body": body.strip_edges()
	}


func _format_claim_bullets(bullets: Array) -> String:
	var lines: Array = []
	for bullet_value in bullets:
		if typeof(bullet_value) != TYPE_DICTIONARY:
			continue
		var bullet: Dictionary = bullet_value
		lines.append("- %s. %s" % [str(bullet.get("claim", "")), str(bullet.get("body", ""))])
	return "\n".join(lines)


func _quality_profile_claim(company: Dictionary) -> String:
	return "%s BUSINESS QUALITY" % _quality_band_label(int(company.get("quality_score", 0))).to_upper()


func _quality_profile_body(company: Dictionary, thesis: Dictionary) -> String:
	var ticker: String = str(company.get("ticker", ""))
	var quality: int = int(company.get("quality_score", 0))
	var growth: int = int(company.get("growth_score", 0))
	var risk: int = int(company.get("risk_score", 0))
	var sector: String = str(company.get("sector_name", "the sector"))
	var stance: String = str(thesis.get("stance", "bullish"))
	return "%s is a %s name with %s business quality, %s growth, and %s risk. %s %s The selected evidence currently makes this a %s case." % [
		ticker,
		sector,
		_quality_band_label(quality),
		_growth_band_label(growth),
		_risk_band_label(risk),
		_quality_implication(quality),
		_growth_risk_implication(growth, risk),
		stance
	]


func _risk_profile_body(score: int) -> String:
	if score >= 80:
		return "High risk needs tight invalidation, smaller sizing, and stronger confirmation before acting."
	if score >= 65:
		return "Elevated risk means the idea can work, but only with clear confirmation and controlled size."
	if score >= 45:
		return "Moderate risk demands confirmation, but it does not reject the idea by itself."
	if score >= 25:
		return "Manageable risk gives the thesis room to develop if evidence stays consistent."
	return "Low risk gives the thesis more room, though price and valuation still matter."


func _evidence_sentence(row: Dictionary, fallback: String) -> String:
	var label: String = str(row.get("label", "Evidence")).strip_edges()
	var value: String = str(row.get("value", "")).strip_edges()
	var detail: String = str(row.get("detail", "")).strip_edges()
	var source: String = str(row.get("source_label", "")).strip_edges()
	var line: String = ""
	if not value.is_empty():
		line = "%s reads %s." % [label, value]
	elif not detail.is_empty():
		line = detail
	else:
		line = fallback
	if not detail.is_empty() and line.find(detail) == -1:
		line += " %s" % detail
	if not source.is_empty():
		line += " Source: %s." % source
	return line


func _price_action_sentence(row: Dictionary) -> String:
	var pattern_label: String = str(row.get("pattern_label", "")).strip_edges()
	var feedback_state: String = str(row.get("feedback_state", row.get("value", ""))).strip_edges()
	var reason: String = str(row.get("feedback_reason", "")).strip_edges()
	var invalidation: String = str(row.get("invalidation", "")).strip_edges()
	var next_check: String = str(row.get("next_check", "")).strip_edges()
	var region: String = str(row.get("region_label", "")).strip_edges()
	if pattern_label.is_empty():
		return _evidence_sentence(row, "This helps judge whether the idea is early, extended, or breaking down.")

	var line: String = "The player marked a %s region" % pattern_label
	if not region.is_empty():
		line += " over %s" % region
	line += "."
	if not feedback_state.is_empty():
		line += " Coaching feedback reads %s" % feedback_state
		if not reason.is_empty():
			line += " because %s" % _strip_terminal_period(reason)
		line += "."
	elif not reason.is_empty():
		line += " Coaching note: %s" % reason
	if not invalidation.is_empty():
		line += " Invalidation: %s" % invalidation
	if next_check.is_empty():
		next_check = _pattern_state_followup(feedback_state)
	if not next_check.is_empty():
		line += " Next check: %s" % next_check
	return line


func _first_evidence(evidence: Array, category_ids: Array) -> Dictionary:
	for evidence_value in evidence:
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = evidence_value
		if category_ids.has(str(row.get("category", ""))):
			return row
	return {}


func _first_pattern_evidence(evidence: Array, category_id: String) -> Dictionary:
	for evidence_value in evidence:
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = evidence_value
		if str(row.get("category", "")) == category_id and not str(row.get("pattern_label", "")).is_empty():
			return row
	return {}


func _evidence_rows(evidence: Array, category_ids: Array) -> Array:
	var rows: Array = []
	for evidence_value in evidence:
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = evidence_value
		if category_ids.has(str(row.get("category", ""))):
			rows.append(row)
	return rows


func _catalyst_claim_for(row: Dictionary) -> String:
	match str(row.get("category", "")):
		"news":
			return "NEWS FLOW"
		"twooter":
			return "MARKET CHATTER"
		"network_intel":
			return "PRIVATE READ"
		"corporate_events":
			return "CORPORATE EVENT"
		"sector_macro":
			return "SECTOR OR MACRO SETUP"
	return _claim_from_label(str(row.get("label", "Catalyst")))


func _claim_from_label(label: String) -> String:
	var normalized: String = label.strip_edges()
	if normalized.is_empty():
		normalized = "Evidence"
	normalized = normalized.replace("_", " ")
	normalized = normalized.replace("/", " / ")
	normalized = normalized.replace("  ", " ")
	return normalized.to_upper()


func _plain_notes(notes: Array, limit: int) -> Array:
	var rows: Array = []
	for note_value in notes:
		rows.append(str(note_value))
		if rows.size() >= limit:
			break
	return rows


func _quality_band_label(score: int) -> String:
	if score >= 80:
		return "excellent"
	if score >= 65:
		return "strong"
	if score >= 50:
		return "average"
	if score >= 35:
		return "weak"
	return "fragile"


func _growth_band_label(score: int) -> String:
	if score >= 80:
		return "accelerating"
	if score >= 65:
		return "healthy"
	if score >= 50:
		return "steady"
	if score >= 35:
		return "uneven"
	return "stalling"


func _risk_band_label(score: int) -> String:
	if score >= 80:
		return "high"
	if score >= 65:
		return "elevated"
	if score >= 45:
		return "moderate"
	if score >= 25:
		return "manageable"
	return "low"


func _quality_implication(score: int) -> String:
	if score >= 80:
		return "The business can support a higher bar for conviction, but the setup still needs a clean entry."
	if score >= 65:
		return "Business quality is a source of support, so the thesis can lean more on fundamentals if valuation is fair."
	if score >= 50:
		return "Business quality is serviceable, so the thesis still needs confirmation from price action or catalysts."
	if score >= 35:
		return "Weak quality means the thesis needs clear confirmation before adding size."
	return "Fragile quality means this thesis needs more than one bullish signal before it deserves conviction."


func _growth_risk_implication(growth_score: int, risk_score: int) -> String:
	var growth_text: String = "Growth is %s" % _growth_band_label(growth_score)
	if growth_score >= 65:
		growth_text += ", which can support upside if the tape confirms."
	elif growth_score >= 35:
		growth_text += " rather than broken, so the stock is still watchable with discipline."
	else:
		growth_text += ", so the thesis needs a strong catalyst or valuation gap."

	var risk_text: String = "Risk is %s" % _risk_band_label(risk_score)
	if risk_score >= 65:
		risk_text += ", so invalidation should stay tight."
	elif risk_score >= 45:
		risk_text += ", enough to demand confirmation but not enough to reject the idea by itself."
	else:
		risk_text += ", giving the thesis more room to develop."
	return "%s %s" % [growth_text, risk_text]


func _tape_read(company: Dictionary) -> String:
	var change_pct: float = float(company.get("daily_change_pct", 0.0))
	var broker_flow: Dictionary = company.get("broker_flow", {})
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))
	var buyer: String = _broker_actor_label(broker_flow, "buy")
	var seller: String = _broker_actor_label(broker_flow, "sell")
	return "Today the stock is %s. Broker flow reads %s, with %s as the strongest buyer and %s as the strongest seller." % [
		_format_signed_percent(change_pct),
		flow_tag,
		buyer,
		seller
	]


func _learning_note(score_data: Dictionary) -> String:
	var missing_notes: Array = score_data.get("missing_notes", [])
	var discipline_rows: Array = score_data.get("discipline_rows", [])
	var discipline_complete: bool = _missing_pillar_count(discipline_rows) == 0
	if missing_notes.is_empty():
		return "Evidence discipline is complete: Anchor, Price, Tape, Catalyst, and Invalidation are all present. Keep the invalidation point visible before adding size."
	var discipline_gaps: Array = _discipline_gap_lines(discipline_rows)
	var note_lines: Array = _bullet_lines(missing_notes, 5)
	if discipline_gaps.is_empty():
		var status_line: String = "Evidence discipline is complete, but the attached evidence still needs interpretation." if discipline_complete else "Evidence discipline needs more support."
		return "%s\nBefore treating this as high conviction:\n%s" % [status_line, "\n".join(note_lines)]
	return "Evidence discipline gaps:\n%s\nBefore treating this as high conviction:\n%s" % [
		"\n".join(discipline_gaps),
		"\n".join(note_lines)
	]


func _evidence_lines(evidence: Array, category_ids: Array, limit: int) -> Array:
	var lines: Array = []
	for evidence_value in evidence:
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = evidence_value
		if not category_ids.has(str(row.get("category", ""))):
			continue
		lines.append("- %s: %s" % [str(row.get("label", "Evidence")), str(row.get("value", row.get("detail", "")))])
		if lines.size() >= limit:
			break
	return lines


func _bullet_lines(values: Array, limit: int) -> Array:
	var lines: Array = []
	for value in values:
		lines.append("- %s" % str(value))
		if lines.size() >= limit:
			break
	return lines


func _has_any_category(categories: Dictionary, ids: Array) -> bool:
	for id_value in ids:
		if categories.has(str(id_value)):
			return true
	return false


func _discipline_rows(categories: Dictionary) -> Array:
	var rows: Array = []
	for pillar_value in CORE_DISCIPLINE_PILLARS:
		var pillar: Dictionary = pillar_value
		var complete: bool = _has_any_category(categories, pillar.get("categories", []))
		rows.append({
			"id": str(pillar.get("id", "")),
			"label": str(pillar.get("label", "")),
			"complete": complete,
			"missing_note": str(pillar.get("missing_note", ""))
		})
	return rows


func _missing_pillar_count(discipline_rows: Array) -> int:
	var count: int = 0
	for row_value in discipline_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if not bool(row.get("complete", false)):
			count += 1
	return count


func _discipline_gap_lines(discipline_rows: Array) -> Array:
	var lines: Array = []
	for row_value in discipline_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if not bool(row.get("complete", false)):
			lines.append("- %s: missing" % str(row.get("label", "Evidence")))
	return lines


func _pattern_state_followup(feedback_state: String) -> String:
	match feedback_state:
		"Good read":
			return "Watch whether the next close respects the marked structure."
		"Plausible, needs confirmation":
			return "Wait for one more close or volume confirmation before treating it as support."
		"Weak read":
			return "Use the mark as a question and look for a cleaner structure."
		"Contradicted":
			return "Do not use this as confirmation unless price rebuilds the marked level."
	return ""


func _strip_terminal_period(value: String) -> String:
	var stripped: String = value.strip_edges()
	while stripped.ends_with("."):
		stripped = stripped.left(stripped.length() - 1).strip_edges()
	return stripped


func _grade_for_score(score: int) -> String:
	if score >= 82:
		return "A"
	if score >= 68:
		return "B"
	if score >= 52:
		return "C"
	return "D"


func _broker_actor_label(broker_flow: Dictionary, side: String) -> String:
	var broker_code_key: String = "dominant_buy_broker_code" if side == "buy" else "dominant_sell_broker_code"
	var broker_type_key: String = "dominant_buy_broker_type" if side == "buy" else "dominant_sell_broker_type"
	var fallback_key: String = "dominant_buyer" if side == "buy" else "dominant_seller"
	var broker_code: String = str(broker_flow.get(broker_code_key, ""))
	if not broker_code.is_empty():
		return broker_code
	var fallback_value: String = str(broker_flow.get(broker_type_key, broker_flow.get(fallback_key, "balanced")))
	return "Balanced" if fallback_value.is_empty() else fallback_value.capitalize()


func _format_trade_date(date_info: Dictionary) -> String:
	if date_info.is_empty():
		return "Unknown date"
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var month_index: int = clamp(int(date_info.get("month", 1)) - 1, 0, months.size() - 1)
	return "%02d %s %d" % [int(date_info.get("day", 1)), months[month_index], int(date_info.get("year", 2020))]


func _format_currency(value: float) -> String:
	var sign: String = "-" if value < 0.0 else ""
	var abs_value: float = abs(value)
	if abs_value >= 1000000000000.0:
		return "%sRp%sT" % [sign, String.num(abs_value / 1000000000000.0, 2)]
	if abs_value >= 1000000000.0:
		return "%sRp%sB" % [sign, String.num(abs_value / 1000000000.0, 2)]
	if abs_value >= 1000000.0:
		return "%sRp%sM" % [sign, String.num(abs_value / 1000000.0, 2)]
	return "%sRp%s" % [sign, String.num(abs_value, 2)]


func _format_signed_percent(value: float) -> String:
	var sign: String = "+" if value > 0.0 else ""
	return "%s%s%%" % [sign, String.num(value * 100.0, 2)]
