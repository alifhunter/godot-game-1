extends RefCounted

const CORE_MEMO_PILLARS := [
	{"id": "anchor", "label": "Anchor", "categories": ["fundamentals", "key_stats", "financials", "valuation"], "missing_note": "Capture a business, financial, or valuation anchor."},
	{"id": "price", "label": "Price", "categories": ["price_action"], "missing_note": "Capture price action or a chart pattern."},
	{"id": "catalyst", "label": "Catalyst", "categories": ["news", "twooter", "network_intel", "corporate_events", "sector_macro"], "missing_note": "Capture a catalyst, source read, or market-context item."},
	{"id": "risk", "label": "Risk", "categories": ["risk_invalidation"], "missing_note": "Attach at least one risk or invalidation item."}
]


func build_report(thesis: Dictionary, context: Dictionary) -> Dictionary:
	var company: Dictionary = context.get("company", {})
	if company.is_empty():
		return {}
	var evidence: Array = thesis.get("evidence", [])
	var score_data: Dictionary = _score_memo(evidence)
	var report_date: Dictionary = context.get("trade_date", {})
	var price: float = float(company.get("current_price", 0.0))
	return {
		"generated_day_index": int(context.get("day_index", 0)),
		"generated_trade_date": report_date.duplicate(true),
		"generated_date_label": _format_trade_date(report_date),
		"company_id": str(thesis.get("company_id", company.get("id", ""))),
		"ticker": str(company.get("ticker", "")),
		"company_name": str(company.get("name", "")),
		"sector_name": str(company.get("sector_name", "Unknown")),
		"stance": str(thesis.get("stance", "watch")),
		"horizon": str(thesis.get("horizon", "swing")),
		"report_price": price,
		"rating": _memo_state(score_data),
		"memo_state": _memo_state(score_data),
		"reasoning_score": int(score_data.get("score", 0)),
		"reasoning_grade": _grade_for_score(int(score_data.get("score", 0))),
		"missing_notes": score_data.get("missing_notes", []).duplicate(),
		"discipline_rows": score_data.get("discipline_rows", []).duplicate(true),
		"target": {"defensible": false, "label": "", "low": 0.0, "high": 0.0, "midpoint": 0.0, "implied_upside_pct": 0.0},
		"implied_upside_pct": 0.0,
		"evidence_count": evidence.size(),
		"support_count": int(score_data.get("support_count", 0)),
		"risk_count": int(score_data.get("risk_count", 0)),
		"contradiction_count": int(score_data.get("contradiction_count", 0)),
		"watch_count": int(score_data.get("watch_count", 0)),
		"sections": _build_sections(thesis, company, evidence, score_data)
	}


func build_review(thesis: Dictionary, context: Dictionary) -> Dictionary:
	var company: Dictionary = context.get("company", {})
	var report: Dictionary = thesis.get("report", {})
	if company.is_empty() or report.is_empty():
		return {
			"state": "Needs Memo",
			"summary": "Generate a memo first, then revisit whether the captured evidence still holds up.",
			"updated_day_index": int(context.get("day_index", 0))
		}
	var memo_price: float = max(float(report.get("report_price", 0.0)), 0.0)
	var current_price: float = float(company.get("current_price", 0.0))
	var return_pct: float = 0.0
	if memo_price > 0.0:
		return_pct = (current_price - memo_price) / memo_price
	var state: String = "Still Open"
	if abs(return_pct) >= 0.08:
		state = "Needs Fresh Evidence"
	elif abs(return_pct) >= 0.03:
		state = "Re-check"
	var summary: String = "%s moved %s since the memo. Re-read the attached evidence before changing size." % [
		str(company.get("ticker", "")),
		_format_signed_percent(return_pct)
	]
	return {
		"state": state,
		"summary": summary,
		"report_price": memo_price,
		"current_price": current_price,
		"return_pct": return_pct,
		"lots_owned": int(company.get("lots_owned", 0)),
		"unrealized_pnl": float(company.get("unrealized_pnl", 0.0)),
		"flow_tag": str(company.get("broker_flow", {}).get("flow_tag", "neutral")),
		"updated_day_index": int(context.get("day_index", 0)),
		"updated_trade_date": context.get("trade_date", {}).duplicate(true)
	}


func _score_memo(evidence: Array) -> Dictionary:
	var categories: Dictionary = {}
	var support_count: int = 0
	var risk_count: int = 0
	var contradiction_count: int = 0
	var watch_count: int = 0
	for evidence_value in evidence:
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = evidence_value
		var category: String = str(row.get("category", ""))
		if not category.is_empty():
			categories[category] = true
		match str(row.get("interpretation", "watch")):
			"support":
				support_count += 1
			"risk", "invalidation":
				risk_count += 1
			"contradiction":
				contradiction_count += 1
			_:
				watch_count += 1
	var discipline_rows: Array = _discipline_rows(categories)
	var missing_notes: Array = []
	for row_value in discipline_rows:
		var row: Dictionary = row_value
		if not bool(row.get("complete", false)):
			missing_notes.append(str(row.get("missing_note", "")))
	if contradiction_count > 0:
		missing_notes.append("Explain the contradiction instead of hiding it.")
	if risk_count <= 0:
		missing_notes.append("Add a risk or invalidation note before treating this as high conviction.")
	var score: int = 20 + min(evidence.size(), 10) * 5 + min(categories.size(), 6) * 5 + min(support_count, 4) * 4 + min(risk_count, 3) * 5
	score -= min(contradiction_count, 4) * 4
	score -= _missing_pillar_count(discipline_rows) * 5
	return {
		"score": clamp(score, 0, 100),
		"categories": categories,
		"discipline_rows": discipline_rows,
		"missing_notes": missing_notes,
		"support_count": support_count,
		"risk_count": risk_count,
		"contradiction_count": contradiction_count,
		"watch_count": watch_count
	}


func _build_sections(thesis: Dictionary, company: Dictionary, evidence: Array, score_data: Dictionary) -> Array:
	return [
		{"title": "Evidence Summary", "bullets": _summary_bullets(thesis, company, evidence, score_data), "body": ""},
		{"title": "Supporting Evidence", "bullets": _evidence_bullets(evidence, ["support"], "No supporting evidence has been classified yet."), "body": ""},
		{"title": "Risks And Contradictions", "bullets": _evidence_bullets(evidence, ["risk", "contradiction"], "No risk or contradiction has been attached yet."), "body": ""},
		{"title": "Invalidation", "bullets": _evidence_bullets(evidence, ["invalidation"], "No explicit invalidation item has been attached yet."), "body": ""},
		{"title": "Next Research Questions", "bullets": _next_question_bullets(score_data), "body": ""},
		{"title": "Learning Note", "body": _learning_note(score_data)}
	]


func _summary_bullets(thesis: Dictionary, company: Dictionary, evidence: Array, score_data: Dictionary) -> Array:
	var ticker: String = str(company.get("ticker", ""))
	var stance: String = str(thesis.get("stance", "watch")).capitalize()
	var horizon: String = str(thesis.get("horizon", "swing")).capitalize()
	var bullets: Array = []
	bullets.append(_make_claim_bullet("THESIS FRAME", "%s is a %s thesis over a %s horizon, built from %s." % [ticker, stance, horizon, _count_phrase(evidence.size(), "piece of evidence", "pieces of evidence")]))
	bullets.append(_make_claim_bullet("EVIDENCE MIX", "Support %d, risk %d, contradiction %d, watch %d." % [
		int(score_data.get("support_count", 0)),
		int(score_data.get("risk_count", 0)),
		int(score_data.get("contradiction_count", 0)),
		int(score_data.get("watch_count", 0))
	]))
	var first_row: Dictionary = _first_evidence(evidence)
	if not first_row.is_empty():
		bullets.append(_make_claim_bullet("FIRST ANCHOR", _evidence_sentence(first_row)))
	return bullets


func _evidence_bullets(evidence: Array, interpretations: Array, empty_body: String) -> Array:
	var bullets: Array = []
	for evidence_value in evidence:
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = evidence_value
		if not interpretations.has(str(row.get("interpretation", "watch"))):
			continue
		bullets.append(_make_claim_bullet(str(row.get("label", "Evidence")), _evidence_sentence(row)))
		if bullets.size() >= 5:
			break
	if bullets.is_empty():
		bullets.append(_make_claim_bullet("OPEN GAP", empty_body))
	return bullets


func _next_question_bullets(score_data: Dictionary) -> Array:
	var bullets: Array = []
	for note_value in score_data.get("missing_notes", []).slice(0, 5):
		bullets.append(_make_claim_bullet("NEXT CHECK", str(note_value)))
	if bullets.is_empty():
		bullets.append(_make_claim_bullet("NEXT CHECK", "Wait for new information, then capture fresh evidence before changing the memo."))
	return bullets


func _learning_note(score_data: Dictionary) -> String:
	var missing_notes: Array = score_data.get("missing_notes", [])
	if missing_notes.is_empty():
		return "The memo has a balanced base. Keep updating it only when you capture new evidence from the actual app surfaces."
	return "This memo is useful, but incomplete. The next step is:\n- %s" % "\n- ".join(missing_notes.slice(0, 5))


func _evidence_sentence(row: Dictionary) -> String:
	var label: String = str(row.get("label", "Evidence")).strip_edges()
	var value: String = str(row.get("value", "")).strip_edges()
	var detail: String = str(row.get("detail", "")).strip_edges()
	var source: String = str(row.get("source_label", "")).strip_edges()
	var note: String = str(row.get("player_note", "")).strip_edges()
	var line: String = label
	if not value.is_empty():
		line += " reads %s." % value
	elif not detail.is_empty():
		line += ": %s" % detail
	else:
		line += " was captured as evidence."
	if not detail.is_empty() and line.find(detail) == -1:
		line += " %s" % detail
	if not note.is_empty():
		line += " Player note: %s" % note
	if not source.is_empty():
		line += " Source: %s." % source
	return line


func _first_evidence(evidence: Array) -> Dictionary:
	for evidence_value in evidence:
		if typeof(evidence_value) == TYPE_DICTIONARY:
			return evidence_value
	return {}


func _make_claim_bullet(claim: String, body: String) -> Dictionary:
	return {"claim": _claim_from_label(claim), "body": body.strip_edges()}


func _count_phrase(count: int, singular: String, plural: String) -> String:
	if count == 1:
		return "one %s" % singular
	return "%d %s" % [count, plural]


func _claim_from_label(label: String) -> String:
	var normalized: String = label.strip_edges()
	if normalized.is_empty():
		normalized = "Evidence"
	return normalized.replace("_", " ").to_upper()


func _discipline_rows(categories: Dictionary) -> Array:
	var rows: Array = []
	for pillar_value in CORE_MEMO_PILLARS:
		var pillar: Dictionary = pillar_value
		var complete: bool = _has_any_category(categories, pillar.get("categories", []))
		rows.append({
			"id": str(pillar.get("id", "")),
			"label": str(pillar.get("label", "")),
			"complete": complete,
			"missing_note": str(pillar.get("missing_note", ""))
		})
	return rows


func _has_any_category(categories: Dictionary, ids: Array) -> bool:
	for id_value in ids:
		if categories.has(str(id_value)):
			return true
	return false


func _missing_pillar_count(discipline_rows: Array) -> int:
	var count: int = 0
	for row_value in discipline_rows:
		if typeof(row_value) == TYPE_DICTIONARY and not bool(row_value.get("complete", false)):
			count += 1
	return count


func _memo_state(score_data: Dictionary) -> String:
	var score: int = int(score_data.get("score", 0))
	if score >= 76:
		return "Well Supported Memo"
	if score >= 58:
		return "Developing Memo"
	if score >= 38:
		return "Thin Memo"
	return "Evidence Needed"


func _grade_for_score(score: int) -> String:
	if score >= 82:
		return "A"
	if score >= 68:
		return "B"
	if score >= 52:
		return "C"
	return "D"


func _format_trade_date(date_info: Dictionary) -> String:
	if date_info.is_empty():
		return "Unknown date"
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var month_index: int = clamp(int(date_info.get("month", 1)) - 1, 0, months.size() - 1)
	return "%02d %s %d" % [int(date_info.get("day", 1)), months[month_index], int(date_info.get("year", 2020))]


func _format_signed_percent(value: float) -> String:
	var sign_prefix: String = "+" if value > 0.0 else ""
	return "%s%s%%" % [sign_prefix, String.num(value * 100.0, 2)]
