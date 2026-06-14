extends Node

const RUN_SEED := 20260614
const COMPANY_ID := "anre"
const EXPECTED_FINGERPRINT_HASH := "672110177"
const EXPECTED_OPTION_HASH := "747086609"
const EXPECTED_REPORT_HASH := "1836382259"
const EXPECTED_SCORE := 72
const EXPECTED_MEMO_STATE := "Developing Memo"
const EXPECTED_GRADE := "B"
const EXPECTED_OPTION_CATEGORY_COUNT := 11
const EXPECTED_EVIDENCE_COUNT := 7


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_fingerprint_report()
	var second_report: Dictionary = _build_fingerprint_report()
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Thesis fingerprint payload was not stable across repeated builds.")
		return
	if str(first_report.get("hash", "")) != str(second_report.get("hash", "")):
		_fail("Thesis fingerprint hash was not stable across repeated builds.")
		return
	if int(first_report.get("option_category_count", 0)) != EXPECTED_OPTION_CATEGORY_COUNT:
		_fail("Thesis fingerprint expected %d option categories, got %d." % [
			EXPECTED_OPTION_CATEGORY_COUNT,
			int(first_report.get("option_category_count", 0))
		])
		return
	if int(first_report.get("evidence_count", 0)) != EXPECTED_EVIDENCE_COUNT:
		_fail("Thesis fingerprint expected %d evidence rows, got %d." % [
			EXPECTED_EVIDENCE_COUNT,
			int(first_report.get("evidence_count", 0))
		])
		return
	if EXPECTED_OPTION_HASH != "BASELINE_PENDING" and str(first_report.get("option_hash", "")) != EXPECTED_OPTION_HASH:
		_fail("Thesis fingerprint option list changed. expected=%s actual=%s." % [
			EXPECTED_OPTION_HASH,
			str(first_report.get("option_hash", ""))
		])
		return
	if EXPECTED_REPORT_HASH != "BASELINE_PENDING" and str(first_report.get("report_hash", "")) != EXPECTED_REPORT_HASH:
		_fail("Thesis fingerprint report section changed. expected=%s actual=%s." % [
			EXPECTED_REPORT_HASH,
			str(first_report.get("report_hash", ""))
		])
		return

	if EXPECTED_FINGERPRINT_HASH != "BASELINE_PENDING":
		if str(first_report.get("hash", "")) != EXPECTED_FINGERPRINT_HASH:
			_fail("Thesis fingerprint changed. expected=%s actual=%s." % [
				EXPECTED_FINGERPRINT_HASH,
				str(first_report.get("hash", ""))
			])
			return
		if int(first_report.get("score", -1)) != EXPECTED_SCORE:
			_fail("Thesis fingerprint score changed. expected=%d actual=%d." % [
				EXPECTED_SCORE,
				int(first_report.get("score", -1))
			])
			return
		if str(first_report.get("memo_state", "")) != EXPECTED_MEMO_STATE:
			_fail("Thesis fingerprint memo state changed. expected=%s actual=%s." % [
				EXPECTED_MEMO_STATE,
				str(first_report.get("memo_state", ""))
			])
			return
		if str(first_report.get("grade", "")) != EXPECTED_GRADE:
			_fail("Thesis fingerprint grade changed. expected=%s actual=%s." % [
				EXPECTED_GRADE,
				str(first_report.get("grade", ""))
			])
			return

	first_report.erase("payload")
	print("THESIS_FINGERPRINT_OK %s" % JSON.stringify(first_report))
	get_tree().quit(0)


func _build_fingerprint_report() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0
	if not RunState.ensure_company_full_detail(COMPANY_ID):
		_fail("Thesis fingerprint could not hydrate full detail for %s." % COMPANY_ID)
		return {}

	var company: Dictionary = GameManager.get_company_snapshot(COMPANY_ID, true, true, true)
	if company.is_empty():
		_fail("Thesis fingerprint missing pinned company snapshot for %s." % COMPANY_ID)
		return {}

	var option_snapshot: Dictionary = GameManager.get_thesis_evidence_options(COMPANY_ID)
	var thesis_result: Dictionary = GameManager.create_thesis(COMPANY_ID, "bullish", "swing", "Fingerprint Thesis")
	if not bool(thesis_result.get("success", false)):
		_fail("Thesis fingerprint could not create thesis: %s" % str(thesis_result.get("message", "")))
		return {}
	var thesis_id: String = str(thesis_result.get("thesis", {}).get("id", ""))
	for evidence in _fixed_evidence_rows(company):
		var add_result: Dictionary = GameManager.add_thesis_evidence(thesis_id, evidence)
		if not bool(add_result.get("success", false)):
			_fail("Thesis fingerprint could not add evidence %s: %s" % [
				str(evidence.get("label", "")),
				str(add_result.get("message", ""))
			])
			return {}

	var report_result: Dictionary = GameManager.generate_thesis_report(thesis_id)
	if not bool(report_result.get("success", false)):
		_fail("Thesis fingerprint could not generate report: %s" % str(report_result.get("message", "")))
		return {}
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	var report: Dictionary = report_result.get("report", {})
	var option_payload: String = _option_payload(option_snapshot)
	var report_payload: String = _report_payload(report)
	var payload: String = option_payload + "\n--report--\n" + report_payload
	return {
		"seed": RUN_SEED,
		"company_id": COMPANY_ID,
		"ticker": str(company.get("ticker", "")),
		"hash": _stable_hash(payload),
		"option_hash": _stable_hash(option_payload),
		"report_hash": _stable_hash(report_payload),
		"score": int(report.get("reasoning_score", 0)),
		"memo_state": str(report.get("memo_state", "")),
		"grade": str(report.get("reasoning_grade", "")),
		"missing_note_count": report.get("missing_notes", []).size(),
		"discipline_pillar_count": report.get("discipline_rows", []).size(),
		"support_count": int(report.get("support_count", 0)),
		"risk_count": int(report.get("risk_count", 0)),
		"contradiction_count": int(report.get("contradiction_count", 0)),
		"watch_count": int(report.get("watch_count", 0)),
		"evidence_count": thesis.get("evidence", []).size(),
		"option_category_count": option_snapshot.get("categories", []).size(),
		"payload": payload
	}


func _fixed_evidence_rows(company: Dictionary) -> Array:
	var ticker: String = str(company.get("ticker", COMPANY_ID.to_upper()))
	return [
		_make_evidence("fundamentals", "Business quality", "Strong", "The operating profile gives the thesis a useful anchor.", "positive", "support", "Company Profile"),
		_make_evidence("financials", "Earnings growth YoY", "+12.00%", "Earnings growth supports the story but conflicts with the cash-flow warning below.", "positive", "support", "Financials"),
		_make_evidence("financials", "Cash from investing", "-Rp127.64B", "Capital spending may be too heavy for the current earnings story.", "negative", "contradiction", "Financials"),
		_make_evidence("price_action", "Five-bar trend", "+4.20%", "The tape is confirming the thesis, but the move may already be crowded.", "positive", "support", "STOCKBOT Chart"),
		_make_evidence("broker_flow", "Net pressure", "Accumulation", "Broker flow shows buyers are still willing to absorb supply.", "positive", "support", "Broker Summary"),
		_make_evidence("sector_macro", "Sector macro bias", "Constructive", "%s is moving with a constructive sector backdrop." % ticker, "mixed", "watch", "Sector / Macro"),
		_make_evidence("risk_invalidation", "Price invalidation", "Break below entry", "If price loses the thesis level, the setup should be reviewed before adding size.", "negative", "risk", "Risk")
	]


func _make_evidence(category: String, label: String, value: String, detail: String, impact: String, interpretation: String, source_label: String) -> Dictionary:
	return {
		"category": category,
		"category_label": ThesisManager.thesis_category_label(category),
		"label": label,
		"value": value,
		"detail": detail,
		"impact": impact,
		"interpretation": interpretation,
		"interpretation_label": GameManager.thesis_evidence_capture_system.interpretation_label(interpretation),
		"source_label": source_label,
		"source_type": "fingerprint"
	}


func _option_payload(option_snapshot: Dictionary) -> String:
	var lines: Array[String] = []
	var categories: Array = option_snapshot.get("categories", [])
	for category_index in range(categories.size()):
		var category: Dictionary = categories[category_index] if typeof(categories[category_index]) == TYPE_DICTIONARY else {}
		lines.append("category[%02d]=%s|%s" % [
			category_index,
			str(category.get("id", "")),
			str(category.get("label", ""))
		])
		var options: Array = category.get("options", [])
		for option_index in range(options.size()):
			var option: Dictionary = options[option_index] if typeof(options[option_index]) == TYPE_DICTIONARY else {}
			lines.append("option[%02d.%02d]=%s|%s|%s|%s|%s|%s" % [
				category_index,
				option_index,
				str(option.get("category", "")),
				str(option.get("label", "")),
				str(option.get("value", "")),
				str(option.get("detail", "")),
				str(option.get("impact", "")),
				str(option.get("source_label", ""))
			])
	return "\n".join(lines)


func _report_payload(report: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("score=%d" % int(report.get("reasoning_score", 0)))
	lines.append("memo_state=%s" % str(report.get("memo_state", "")))
	lines.append("grade=%s" % str(report.get("reasoning_grade", "")))
	lines.append("support_count=%d" % int(report.get("support_count", 0)))
	lines.append("risk_count=%d" % int(report.get("risk_count", 0)))
	lines.append("contradiction_count=%d" % int(report.get("contradiction_count", 0)))
	lines.append("watch_count=%d" % int(report.get("watch_count", 0)))
	var missing_notes: Array = report.get("missing_notes", []).duplicate()
	missing_notes.sort()
	for note_index in range(missing_notes.size()):
		lines.append("missing_note[%02d]=%s" % [note_index, str(missing_notes[note_index])])
	var discipline_rows: Array = report.get("discipline_rows", [])
	for row_index in range(discipline_rows.size()):
		var row: Dictionary = discipline_rows[row_index] if typeof(discipline_rows[row_index]) == TYPE_DICTIONARY else {}
		lines.append("pillar[%02d]=%s|%s|%s|%s" % [
			row_index,
			str(row.get("id", "")),
			str(row.get("label", "")),
			str(row.get("complete", "")),
			str(row.get("missing_note", ""))
		])
	return "\n".join(lines)


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int((hash_value ^ text.unicode_at(index)) * 16777619)
		hash_value = hash_value % 2147483647
		if hash_value < 0:
			hash_value += 2147483647
	return str(hash_value)


func _fail(message: String) -> void:
	push_error(message)
	print("THESIS_FINGERPRINT_FAIL: %s" % message)
	get_tree().quit(1)
