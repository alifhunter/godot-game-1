extends Node

const THESIS_REPORT_SYSTEM_SCRIPT = preload("res://systems/ThesisReportSystem.gd")


func _ready() -> void:
	var reporter = THESIS_REPORT_SYSTEM_SCRIPT.new()
	var clean_report: Dictionary = reporter.build_report(_make_thesis("clean", _clean_five_pillar_evidence()), _make_context())
	var contradiction_report: Dictionary = reporter.build_report(_make_thesis("contradiction_heavy", _contradiction_heavy_evidence()), _make_context())
	var thin_report: Dictionary = reporter.build_report(_make_thesis("thin", _thin_evidence()), _make_context())

	if not _assert_report(clean_report, "clean five-pillar", 82, "Well Supported Memo", "A", 5, 0):
		return
	if not _assert_report(contradiction_report, "contradiction-heavy", 68, "Thin Memo", "C", 5, 2):
		return
	if not _assert_report(thin_report, "thin", 16, "Evidence Needed", "D", 5, 0):
		return

	print("THESIS_SCORING_REBALANCE_OK %s" % JSON.stringify({
		"clean": _summary(clean_report),
		"contradiction_heavy": _summary(contradiction_report),
		"thin": _summary(thin_report)
	}))
	get_tree().quit(0)


func _make_context() -> Dictionary:
	return {
		"day_index": 12,
		"trade_date": {"day": 14, "month": 6, "year": 2026},
		"company": {
			"id": "testco",
			"ticker": "TSTC",
			"name": "Test Company",
			"sector_name": "Test Sector",
			"current_price": 1200.0
		}
	}


func _make_thesis(name: String, evidence: Array) -> Dictionary:
	return {
		"id": name,
		"company_id": "testco",
		"stance": "bullish",
		"horizon": "swing",
		"evidence": evidence
	}


func _clean_five_pillar_evidence() -> Array:
	return [
		_make_evidence("fundamentals", "Business quality", "Strong", "Anchor is usable.", "support"),
		_make_evidence("financials", "Margin trend", "Improving", "Financials support the anchor.", "support"),
		_make_evidence("price_action", "Trend", "Up", "Price confirms the thesis.", "support"),
		_make_evidence("broker_flow", "Flow", "Accumulation", "Tape confirms buyer demand.", "support"),
		_make_evidence("sector_macro", "Sector", "Constructive", "Catalyst backdrop is constructive.", "watch"),
		_make_evidence("risk_invalidation", "Invalidation", "Break below support", "Risk is explicit.", "risk")
	]


func _contradiction_heavy_evidence() -> Array:
	return [
		_make_evidence("fundamentals", "Business quality", "Strong", "Anchor is usable.", "support"),
		_make_evidence("financials", "Revenue", "Growing", "Growth supports the thesis.", "support"),
		_make_evidence("price_action", "Trend", "Up", "Price supports the thesis.", "support"),
		_make_evidence("broker_flow", "Flow", "Accumulation", "Tape supports the thesis.", "support"),
		_make_evidence("sector_macro", "Sector", "Constructive", "Catalyst backdrop is constructive.", "support"),
		_make_evidence("risk_invalidation", "Invalidation", "Break below support", "Risk is explicit.", "risk"),
		_make_evidence("risk_invalidation", "Size risk", "Elevated", "Sizing risk should stay visible.", "risk"),
		_make_evidence("financials", "Free cash flow", "Weak", "Cash flow conflicts with the growth story.", "contradiction"),
		_make_evidence("price_action", "Failed breakout", "Rejected", "Price action also conflicts with the bullish case.", "contradiction"),
		_make_evidence("news", "Rumor", "Unconfirmed", "Catalyst needs verification.", "watch")
	]


func _thin_evidence() -> Array:
	return [
		_make_evidence("fundamentals", "Business quality", "Okay", "One anchor is not enough.", "support"),
		_make_evidence("price_action", "Trend", "Flat", "Price needs confirmation.", "watch")
	]


func _make_evidence(category: String, label: String, value: String, detail: String, interpretation: String) -> Dictionary:
	return {
		"category": category,
		"label": label,
		"value": value,
		"detail": detail,
		"impact": ThesisVocabulary.impact_for_interpretation(interpretation),
		"interpretation": interpretation,
		"source_label": "Test"
	}


func _assert_report(report: Dictionary, label: String, expected_score: int, expected_state: String, expected_grade: String, expected_pillars: int, expected_contradictions: int) -> bool:
	if report.is_empty():
		_fail("Expected %s report to be generated." % label)
		return false
	if int(report.get("reasoning_score", -1)) != expected_score:
		_fail("Expected %s score %d, got %d." % [label, expected_score, int(report.get("reasoning_score", -1))])
		return false
	if str(report.get("memo_state", "")) != expected_state:
		_fail("Expected %s state %s, got %s." % [label, expected_state, str(report.get("memo_state", ""))])
		return false
	if str(report.get("reasoning_grade", "")) != expected_grade:
		_fail("Expected %s grade %s, got %s." % [label, expected_grade, str(report.get("reasoning_grade", ""))])
		return false
	if report.get("discipline_rows", []).size() != expected_pillars:
		_fail("Expected %s to report %d pillars, got %d." % [label, expected_pillars, report.get("discipline_rows", []).size()])
		return false
	if int(report.get("contradiction_count", -1)) != expected_contradictions:
		_fail("Expected %s contradiction count %d, got %d." % [label, expected_contradictions, int(report.get("contradiction_count", -1))])
		return false
	return true


func _summary(report: Dictionary) -> Dictionary:
	return {
		"score": int(report.get("reasoning_score", 0)),
		"memo_state": str(report.get("memo_state", "")),
		"grade": str(report.get("reasoning_grade", "")),
		"pillars": _pillar_summary(report.get("discipline_rows", [])),
		"missing_note_count": report.get("missing_notes", []).size(),
		"contradiction_count": int(report.get("contradiction_count", 0))
	}


func _pillar_summary(rows: Array) -> Array:
	var summary: Array = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		summary.append("%s:%s" % [str(row.get("id", "")), str(row.get("complete", false))])
	return summary


func _fail(message: String) -> void:
	push_error(message)
	print("THESIS_SCORING_REBALANCE_FAIL: %s" % message)
	get_tree().quit(1)
