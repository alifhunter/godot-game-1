extends Node

const FINANCIAL_STATEMENT_LAYER = preload("res://systems/FinancialStatementLayer.gd")

const EXPECTED_HASH := "1888558735"


func _ready() -> void:
	var matrix_report: Dictionary = _run_snapshot_matrix()
	if not matrix_report.get("success", false):
		_fail(str(matrix_report.get("message", "snapshot matrix failed")))
		return

	var repeated_report: Dictionary = _run_snapshot_matrix()
	if not repeated_report.get("success", false):
		_fail(str(repeated_report.get("message", "repeated snapshot matrix failed")))
		return
	if str(matrix_report.get("payload", "")) != str(repeated_report.get("payload", "")):
		_fail("Financial statement snapshot matrix changed across repeated fixed input runs.")
		return

	var hash: String = _stable_hash(str(matrix_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Financial statement snapshot matrix hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("FINANCIAL_STATEMENT_LAYER_SNAPSHOT_MATRIX_OK %s" % JSON.stringify({
		"hash": hash,
		"case_count": int(matrix_report.get("case_count", 0)),
		"summaries": matrix_report.get("summaries", {})
	}))
	get_tree().quit(0)


func _run_snapshot_matrix() -> Dictionary:
	var reports: Array = [
		_run_customer_contract_case(),
		_run_use_of_proceeds_case(),
		_run_margin_pressure_case(),
		_run_debt_liquidity_case(),
		_run_statement_contradiction_case()
	]
	var payloads: Array = []
	var summaries: Dictionary = {}
	for report_value in reports:
		if typeof(report_value) != TYPE_DICTIONARY:
			return _case_fail("Snapshot matrix produced a non-dictionary report.")
		var report: Dictionary = report_value
		if not report.get("success", false):
			return report
		var case_id: String = str(report.get("case_id", ""))
		payloads.append(str(report.get("payload", "")))
		summaries[case_id] = report.get("summary", {})
	return {
		"success": true,
		"case_count": reports.size(),
		"summaries": summaries,
		"payload": "\n---\n".join(payloads)
	}


func _run_customer_contract_case() -> Dictionary:
	var case_id: String = "customer_contract"
	var base_statement: Dictionary = _base_statement(case_id)
	var adjusted: Dictionary = _apply_case(base_statement, _dossier(case_id, [
		{"metric_id": "revenue", "section": "income_statement", "direction": "up", "magnitude_band": "large", "confidence": 0.90, "persistence": "durable", "note_type": "customer_contract"},
		{"metric_id": "backlog", "section": "operating_metrics", "direction": "up", "magnitude_band": "moderate", "confidence": 0.76, "persistence": "temporary", "note_type": "customer_contract"}
	], "clear", "real", 0.91), "inner_circle")
	var expected_effect_ids: Array = [_effect_id(case_id, "revenue"), _effect_id(case_id, "backlog")]
	var common_check: Dictionary = _validate_common(adjusted, expected_effect_ids, ["customer_contract"], 2, 1)
	if not common_check.get("success", false):
		return common_check
	var check: Dictionary = _expect_line_change(base_statement, adjusted, "income_statement", "revenue", "up")
	if not check.get("success", false):
		return check
	check = _expect_line_change(base_statement, adjusted, "income_statement", "net_income", "up")
	if not check.get("success", false):
		return check
	check = _expect_line_change(base_statement, adjusted, "operating_metrics", "backlog", "up")
	if not check.get("success", false):
		return check
	var note: Dictionary = _note_by_type(adjusted, "customer_contract")
	check = _expect_note_quality(note, "clear", "high", [])
	if not check.get("success", false):
		return check
	return _case_ok(case_id, {
		"revenue_delta": snappedf(_line_delta(base_statement, adjusted, "income_statement", "revenue"), 0.001),
		"net_income_delta": snappedf(_line_delta(base_statement, adjusted, "income_statement", "net_income"), 0.001),
		"backlog_delta": snappedf(_line_delta(base_statement, adjusted, "operating_metrics", "backlog"), 0.001),
		"note_quality": note.get("disclosure_quality", ""),
		"note_detail": note.get("detail_level", "")
	}, _statement_payload(case_id, adjusted))


func _run_use_of_proceeds_case() -> Dictionary:
	var case_id: String = "use_of_proceeds"
	var base_statement: Dictionary = _base_statement(case_id)
	var adjusted: Dictionary = _apply_case(base_statement, _dossier(case_id, [
		{"metric_id": "cash", "section": "balance_sheet", "direction": "up", "magnitude_band": "moderate", "confidence": 0.82, "persistence": "temporary", "note_type": "use_of_proceeds"},
		{"metric_id": "capex", "section": "cash_flow", "direction": "up", "magnitude_band": "small", "confidence": 0.70, "persistence": "durable", "note_type": "use_of_proceeds"}
	], "partial", "delayed", 0.78), "public")
	var expected_effect_ids: Array = [_effect_id(case_id, "cash"), _effect_id(case_id, "capex")]
	var common_check: Dictionary = _validate_common(adjusted, expected_effect_ids, ["use_of_proceeds"], 2, 1)
	if not common_check.get("success", false):
		return common_check
	for expectation in [
		["balance_sheet", "cash", "up"],
		["balance_sheet", "current_assets", "up"],
		["balance_sheet", "total_assets", "up"],
		["cash_flow", "capex", "up"],
		["cash_flow", "cash_from_investing", "down"]
	]:
		var check: Dictionary = _expect_line_change(base_statement, adjusted, str(expectation[0]), str(expectation[1]), str(expectation[2]))
		if not check.get("success", false):
			return check
	var note: Dictionary = _note_by_type(adjusted, "use_of_proceeds")
	var note_check: Dictionary = _expect_note_quality(note, "partial", "public", ["post_corporate_action"])
	if not note_check.get("success", false):
		return note_check
	return _case_ok(case_id, {
		"cash_delta": snappedf(_line_delta(base_statement, adjusted, "balance_sheet", "cash"), 0.001),
		"capex_delta": snappedf(_line_delta(base_statement, adjusted, "cash_flow", "capex"), 0.001),
		"investing_delta": snappedf(_line_delta(base_statement, adjusted, "cash_flow", "cash_from_investing"), 0.001),
		"note_tags": _string_array(note.get("explain_tags", []))
	}, _statement_payload(case_id, adjusted))


func _run_margin_pressure_case() -> Dictionary:
	var case_id: String = "margin_pressure"
	var base_statement: Dictionary = _base_statement(case_id)
	var adjusted: Dictionary = _apply_case(base_statement, _dossier(case_id, [
		{"metric_id": "gross_margin", "section": "income_statement", "direction": "down", "magnitude_band": "moderate", "confidence": 0.84, "persistence": "temporary", "note_type": "input_cost_pressure"},
		{"metric_id": "inventory", "section": "balance_sheet", "direction": "up", "magnitude_band": "small", "confidence": 0.70, "persistence": "temporary", "note_type": "input_cost_pressure"}
	], "weak", "failed", 0.80), "public")
	var expected_effect_ids: Array = [_effect_id(case_id, "gross_margin"), _effect_id(case_id, "inventory")]
	var common_check: Dictionary = _validate_common(adjusted, expected_effect_ids, ["input_cost_pressure"], 2, 1)
	if not common_check.get("success", false):
		return common_check
	for expectation in [
		["income_statement", "gross_profit", "down"],
		["income_statement", "net_income", "down"],
		["balance_sheet", "inventory", "up"],
		["balance_sheet", "current_assets", "up"]
	]:
		var check: Dictionary = _expect_line_change(base_statement, adjusted, str(expectation[0]), str(expectation[1]), str(expectation[2]))
		if not check.get("success", false):
			return check
	var note: Dictionary = _note_by_type(adjusted, "input_cost_pressure")
	var note_check: Dictionary = _expect_note_quality(note, "weak", "public", [])
	if not note_check.get("success", false):
		return note_check
	if str(note.get("tone", "")) != "mixed":
		return _case_fail("Expected margin pressure note tone to be mixed, got %s." % str(note.get("tone", "")))
	return _case_ok(case_id, {
		"gross_profit_delta": snappedf(_line_delta(base_statement, adjusted, "income_statement", "gross_profit"), 0.001),
		"net_income_delta": snappedf(_line_delta(base_statement, adjusted, "income_statement", "net_income"), 0.001),
		"inventory_delta": snappedf(_line_delta(base_statement, adjusted, "balance_sheet", "inventory"), 0.001),
		"note_quality": note.get("disclosure_quality", ""),
		"note_tone": note.get("tone", "")
	}, _statement_payload(case_id, adjusted))


func _run_debt_liquidity_case() -> Dictionary:
	var case_id: String = "debt_liquidity"
	var base_statement: Dictionary = _base_statement(case_id)
	var adjusted: Dictionary = _apply_case(base_statement, _dossier(case_id, [
		{"metric_id": "debt", "section": "balance_sheet", "direction": "up", "magnitude_band": "moderate", "confidence": 0.80, "persistence": "durable", "note_type": "debt_change"},
		{"metric_id": "cash", "section": "balance_sheet", "direction": "down", "magnitude_band": "small", "confidence": 0.78, "persistence": "temporary", "note_type": "liquidity"}
	], "partial", "delayed", 0.82), "recognized")
	var expected_effect_ids: Array = [_effect_id(case_id, "debt"), _effect_id(case_id, "cash")]
	var common_check: Dictionary = _validate_common(adjusted, expected_effect_ids, ["debt_change", "liquidity"], 2, 2)
	if not common_check.get("success", false):
		return common_check
	for expectation in [
		["balance_sheet", "debt", "up"],
		["balance_sheet", "total_liabilities", "up"],
		["balance_sheet", "cash", "down"],
		["balance_sheet", "current_assets", "down"],
		["balance_sheet", "total_assets", "down"]
	]:
		var check: Dictionary = _expect_line_change(base_statement, adjusted, str(expectation[0]), str(expectation[1]), str(expectation[2]))
		if not check.get("success", false):
			return check
	var debt_note: Dictionary = _note_by_type(adjusted, "debt_change")
	var liquidity_note: Dictionary = _note_by_type(adjusted, "liquidity")
	var note_check: Dictionary = _expect_note_quality(debt_note, "partial", "medium", [])
	if not note_check.get("success", false):
		return note_check
	note_check = _expect_note_quality(liquidity_note, "partial", "medium", [])
	if not note_check.get("success", false):
		return note_check
	return _case_ok(case_id, {
		"debt_delta": snappedf(_line_delta(base_statement, adjusted, "balance_sheet", "debt"), 0.001),
		"cash_delta": snappedf(_line_delta(base_statement, adjusted, "balance_sheet", "cash"), 0.001),
		"note_count": _variant_array(adjusted.get("notes", [])).size()
	}, _statement_payload(case_id, adjusted))


func _run_statement_contradiction_case() -> Dictionary:
	var case_id: String = "statement_contradiction"
	var base_statement: Dictionary = _base_statement(case_id)
	var adjusted: Dictionary = _apply_case(base_statement, _dossier(case_id, [
		{"metric_id": "operating_margin", "section": "income_statement", "direction": "up", "magnitude_band": "moderate", "confidence": 0.82, "persistence": "temporary", "note_type": "statement_contradiction"}
	], "contradictory", "fraud_risk", 0.84), "trusted")
	var expected_effect_ids: Array = [_effect_id(case_id, "operating_margin")]
	var common_check: Dictionary = _validate_common(adjusted, expected_effect_ids, ["statement_contradiction"], 1, 1)
	if not common_check.get("success", false):
		return common_check
	var check: Dictionary = _expect_line_change(base_statement, adjusted, "income_statement", "operating_income", "up")
	if not check.get("success", false):
		return check
	check = _expect_line_change(base_statement, adjusted, "income_statement", "net_income", "up")
	if not check.get("success", false):
		return check
	var note: Dictionary = _note_by_type(adjusted, "statement_contradiction")
	var note_check: Dictionary = _expect_note_quality(note, "contradictory", "challenge", ["challenge_claim"])
	if not note_check.get("success", false):
		return note_check
	if not bool(note.get("contradiction", false)):
		return _case_fail("Expected contradiction note flag.")
	return _case_ok(case_id, {
		"operating_income_delta": snappedf(_line_delta(base_statement, adjusted, "income_statement", "operating_income"), 0.001),
		"net_income_delta": snappedf(_line_delta(base_statement, adjusted, "income_statement", "net_income"), 0.001),
		"note_quality": note.get("disclosure_quality", ""),
		"note_tags": _string_array(note.get("explain_tags", []))
	}, _statement_payload(case_id, adjusted))


func _apply_case(base_statement: Dictionary, dossier: Dictionary, access_level: String) -> Dictionary:
	var company_id: String = str(dossier.get("company_id", "matrixco"))
	return FINANCIAL_STATEMENT_LAYER.apply_story_effects_to_statement(
		base_statement,
		[dossier],
		{"revenue": _line_value(base_statement, "income_statement", "revenue") * 4.0},
		{
			"company_id": company_id,
			"ticker": "MTRX",
			"sector_id": "industrial",
			"filing_day_index": 120,
			"relationship_access_level": access_level,
			"max_story_adjustments": 8
		}
	)


func _dossier(case_id: String, effect_specs: Array, disclosure_quality: String, truth_state: String, priority: float) -> Dictionary:
	var story_id: String = _story_id(case_id)
	var effects: Array = []
	var metric_ids: Array = []
	for spec_value in effect_specs:
		if typeof(spec_value) != TYPE_DICTIONARY:
			continue
		var spec: Dictionary = spec_value
		var metric_id: String = str(spec.get("metric_id", ""))
		metric_ids.append(metric_id)
		effects.append({
			"effect_id": _effect_id(case_id, metric_id),
			"metric_id": metric_id,
			"statement_section": str(spec.get("section", "")),
			"direction": str(spec.get("direction", "mixed")),
			"magnitude_band": str(spec.get("magnitude_band", "moderate")),
			"persistence": str(spec.get("persistence", "")),
			"confidence": float(spec.get("confidence", 0.70)),
			"note_type": str(spec.get("note_type", "management_outlook"))
		})
	return {
		"story_id": story_id,
		"company_id": _company_id(case_id),
		"truth_state": truth_state,
		"priority": priority,
		"cause_facts": [
			{"fact_id": _fact_id(case_id), "fact_type": "company_story", "source_id": case_id}
		],
		"financial_effects": effects,
		"statement_clues": [
			{
				"clue_id": _clue_id(case_id),
				"fact_ids": [_fact_id(case_id)],
				"surface_id": "statement_note",
				"metric_ids": _string_array(metric_ids),
				"disclosure_quality": disclosure_quality
			}
		]
	}


func _validate_common(
	statement: Dictionary,
	expected_effect_ids: Array,
	expected_note_types: Array,
	expected_adjustment_count: int,
	expected_note_count: int
) -> Dictionary:
	if int(statement.get("schema_version", 0)) <= 0:
		return _case_fail("Expected statement schema version metadata.")
	if str(statement.get("source_system_id", "")) != "financial_statement_layer":
		return _case_fail("Expected statement source system metadata.")
	if str(statement.get("statement_id", "")).strip_edges().is_empty():
		return _case_fail("Expected stable statement id.")
	if _json_contains_hidden_truth(statement):
		return _case_fail("Adjusted statement leaked hidden story truth metadata.")

	var adjustments: Array = _variant_array(statement.get("story_adjustments", []))
	if adjustments.size() != expected_adjustment_count:
		return _case_fail("Expected %d story adjustments, got %d." % [expected_adjustment_count, adjustments.size()])
	var notes: Array = _variant_array(statement.get("notes", []))
	if notes.size() != expected_note_count:
		return _case_fail("Expected %d statement notes, got %d." % [expected_note_count, notes.size()])

	var actual_effect_ids: Array = []
	var actual_note_types: Array = []
	var note_ids: Array = []
	for note_value in notes:
		if typeof(note_value) != TYPE_DICTIONARY:
			return _case_fail("Expected note dictionary.")
		var note: Dictionary = note_value
		var note_id: String = str(note.get("note_id", "")).strip_edges()
		if note_id.is_empty():
			return _case_fail("Expected generated note id.")
		note_ids.append(note_id)
		actual_note_types.append(str(note.get("note_type", "")))
		if _variant_array(note.get("metric_ids", [])).is_empty():
			return _case_fail("Expected note metric ids for %s." % note_id)
		if _variant_array(note.get("effect_ids", [])).is_empty():
			return _case_fail("Expected note effect ids for %s." % note_id)
		if _variant_array(note.get("fact_ids", [])).is_empty():
			return _case_fail("Expected note fact ids for %s." % note_id)
		if _variant_array(note.get("clue_ids", [])).is_empty():
			return _case_fail("Expected note clue ids for %s." % note_id)
		if _variant_array(note.get("source_statement_sections", [])).is_empty():
			return _case_fail("Expected note source statement sections for %s." % note_id)
		if str(note.get("summary", "")).strip_edges().is_empty():
			return _case_fail("Expected note summary for %s." % note_id)

	if _string_array(actual_note_types) != _string_array(expected_note_types):
		return _case_fail("Note types changed. expected=%s actual=%s." % [_string_array(expected_note_types), _string_array(actual_note_types)])

	for adjustment_value in adjustments:
		if typeof(adjustment_value) != TYPE_DICTIONARY:
			return _case_fail("Expected adjustment dictionary.")
		var adjustment: Dictionary = adjustment_value
		var effect_id: String = str(adjustment.get("effect_id", ""))
		var note_id: String = str(adjustment.get("note_id", ""))
		actual_effect_ids.append(effect_id)
		if not _string_array(note_ids).has(note_id):
			return _case_fail("Adjustment %s did not point at a generated note." % effect_id)
		if str(adjustment.get("adjustment_id", "")).strip_edges().is_empty():
			return _case_fail("Expected adjustment id for %s." % effect_id)
		if str(adjustment.get("statement_id", "")) != str(statement.get("statement_id", "")):
			return _case_fail("Adjustment %s statement id mismatch." % effect_id)
		if str(adjustment.get("metric_id", "")).strip_edges().is_empty():
			return _case_fail("Expected adjustment metric id for %s." % effect_id)
		if str(adjustment.get("story_id", "")).strip_edges().is_empty():
			return _case_fail("Expected adjustment story id for %s." % effect_id)
		var before_value: float = float(adjustment.get("before_value", 0.0))
		var after_value: float = float(adjustment.get("after_value", 0.0))
		var delta_amount: float = float(adjustment.get("applied_delta_amount", 0.0))
		if absf((after_value - before_value) - delta_amount) > 0.002:
			return _case_fail("Adjustment %s before/after/delta became inconsistent." % effect_id)
		if absf(float(adjustment.get("applied_delta_pct", 0.0))) > 0.351:
			return _case_fail("Adjustment %s breached bounded delta plausibility." % effect_id)
		if _variant_array(adjustment.get("fact_ids", [])).is_empty():
			return _case_fail("Expected adjustment fact ids for %s." % effect_id)
		if _variant_array(adjustment.get("clue_ids", [])).is_empty():
			return _case_fail("Expected adjustment clue ids for %s." % effect_id)

	if _string_array(actual_effect_ids) != _string_array(expected_effect_ids):
		return _case_fail("Adjustment effect ids changed. expected=%s actual=%s." % [_string_array(expected_effect_ids), _string_array(actual_effect_ids)])

	for effect_id in _string_array(expected_effect_ids):
		if not _line_has_source_any(statement, effect_id):
			return _case_fail("No statement line preserved source effect id %s." % effect_id)

	var traceability_check: Dictionary = _validate_traceability(statement, expected_effect_ids, note_ids, adjustments)
	if not traceability_check.get("success", false):
		return traceability_check
	return _validate_numeric_plausibility(statement)


func _validate_traceability(statement: Dictionary, expected_effect_ids: Array, note_ids: Array, adjustments: Array) -> Dictionary:
	var traceability_value: Variant = statement.get("traceability", {})
	if typeof(traceability_value) != TYPE_DICTIONARY:
		return _case_fail("Expected statement traceability dictionary.")
	var traceability: Dictionary = traceability_value
	for effect_id in _string_array(expected_effect_ids):
		if not _string_array(traceability.get("source_effect_ids", [])).has(effect_id):
			return _case_fail("Traceability missing source effect id %s." % effect_id)
	for note_id in _string_array(note_ids):
		if not _string_array(traceability.get("generated_note_ids", [])).has(note_id):
			return _case_fail("Traceability missing generated note id %s." % note_id)
	for adjustment_value in adjustments:
		if typeof(adjustment_value) != TYPE_DICTIONARY:
			continue
		var adjustment: Dictionary = adjustment_value
		if not _string_array(traceability.get("generated_adjustment_ids", [])).has(str(adjustment.get("adjustment_id", ""))):
			return _case_fail("Traceability missing generated adjustment id %s." % str(adjustment.get("adjustment_id", "")))
	return _case_ok("", {}, "")


func _validate_numeric_plausibility(statement: Dictionary) -> Dictionary:
	for section_id in ["income_statement", "balance_sheet", "cash_flow", "operating_metrics"]:
		for line_value in _variant_array(statement.get(section_id, [])):
			if typeof(line_value) != TYPE_DICTIONARY:
				continue
			var line: Dictionary = line_value
			var line_id: String = str(line.get("id", line.get("metric_id", "")))
			var value: float = float(line.get("value", 0.0))
			if value < -0.001 and not _negative_allowed_line_ids().has(line_id):
				return _case_fail("Line %s/%s became implausibly negative: %s." % [section_id, line_id, value])
	if _line_value(statement, "balance_sheet", "current_assets") > _line_value(statement, "balance_sheet", "total_assets") + 0.001:
		return _case_fail("Current assets exceeded total assets.")
	if _line_value(statement, "balance_sheet", "debt") > _line_value(statement, "balance_sheet", "total_liabilities") + 0.001:
		return _case_fail("Debt exceeded total liabilities.")
	if _line_value(statement, "balance_sheet", "cash") > _line_value(statement, "balance_sheet", "current_assets") + 0.001:
		return _case_fail("Cash exceeded current assets.")
	return _case_ok("", {}, "")


func _expect_line_change(base_statement: Dictionary, adjusted: Dictionary, section_id: String, line_id: String, direction: String) -> Dictionary:
	var before_value: float = _line_value(base_statement, section_id, line_id)
	var after_value: float = _line_value(adjusted, section_id, line_id)
	match direction:
		"up":
			if after_value <= before_value:
				return _case_fail("Expected %s/%s to increase. before=%s after=%s." % [section_id, line_id, before_value, after_value])
		"down":
			if after_value >= before_value:
				return _case_fail("Expected %s/%s to decrease. before=%s after=%s." % [section_id, line_id, before_value, after_value])
		_:
			return _case_fail("Unknown line direction expectation %s." % direction)
	return _case_ok("", {}, "")


func _expect_note_quality(note: Dictionary, expected_quality: String, expected_detail: String, required_tags: Array) -> Dictionary:
	if note.is_empty():
		return _case_fail("Expected note dictionary for quality check.")
	if str(note.get("disclosure_quality", "")) != expected_quality:
		return _case_fail("Expected note quality %s, got %s." % [expected_quality, str(note.get("disclosure_quality", ""))])
	if str(note.get("detail_level", "")) != expected_detail:
		return _case_fail("Expected note detail %s, got %s." % [expected_detail, str(note.get("detail_level", ""))])
	var note_tags: Array = _string_array(note.get("explain_tags", []))
	for tag_value in required_tags:
		var tag: String = str(tag_value)
		if not note_tags.has(tag):
			return _case_fail("Expected note explain tag %s." % tag)
	return _case_ok("", {}, "")


func _base_statement(case_id: String) -> Dictionary:
	return {
		"statement_id": "statement|%s|2021|Q3" % _company_id(case_id),
		"company_id": _company_id(case_id),
		"ticker": "MTRX",
		"sector_id": "industrial",
		"statement_year": 2021,
		"statement_quarter": 3,
		"statement_period_label": "Q3 2021",
		"income_statement": [
			{"id": "revenue", "label": "Total revenue", "value": 1000.0, "format": "currency"},
			{"id": "gross_profit", "label": "Gross profit", "value": 340.0, "format": "currency"},
			{"id": "operating_income", "label": "Income from operations", "value": 170.0, "format": "currency"},
			{"id": "net_income", "label": "Net income for the period", "value": 88.0, "format": "currency"}
		],
		"balance_sheet": [
			{"id": "current_assets", "label": "Current assets", "value": 640.0, "format": "currency"},
			{"id": "total_assets", "label": "Total assets", "value": 1850.0, "format": "currency"},
			{"id": "total_liabilities", "label": "Total liabilities", "value": 740.0, "format": "currency"},
			{"id": "equity", "label": "Equity", "value": 1110.0, "format": "currency"},
			{"id": "cash", "label": "Cash and equivalents", "value": 190.0, "format": "currency"},
			{"id": "debt", "label": "Debt", "value": 430.0, "format": "currency"},
			{"id": "inventory", "label": "Inventory", "value": 135.0, "format": "currency"},
			{"id": "receivables", "label": "Receivables", "value": 160.0, "format": "currency"},
			{"id": "shares_outstanding", "label": "Shares outstanding", "value": 1000000.0, "format": "shares"}
		],
		"cash_flow": [
			{"id": "cash_from_operating", "label": "Cash from operating", "value": 130.0, "format": "currency"},
			{"id": "cash_from_investing", "label": "Cash from investing", "value": -190.0, "format": "currency"},
			{"id": "cash_from_financing", "label": "Cash from financing", "value": 42.0, "format": "currency"},
			{"id": "capex", "label": "Capital expenditure", "value": 118.0, "format": "currency"},
			{"id": "free_cash_flow", "label": "Free cash flow", "value": 64.0, "format": "currency"}
		],
		"operating_metrics": [
			{"id": "backlog", "label": "Backlog", "value": 310.0, "format": "number"},
			{"id": "customer_concentration", "label": "Customer concentration", "value": 30.0, "format": "percent"},
			{"id": "production_volume", "label": "Production volume", "value": 100.0, "format": "number"}
		]
	}


func _statement_payload(case_id: String, statement: Dictionary) -> String:
	var rows: Array = []
	rows.append("case=%s" % case_id)
	rows.append("statement:%s:%s:%s" % [
		str(statement.get("statement_id", "")),
		int(statement.get("schema_version", 0)),
		str(statement.get("source_system_id", ""))
	])
	for section_id in ["income_statement", "balance_sheet", "cash_flow", "operating_metrics"]:
		for line_value in _variant_array(statement.get(section_id, [])):
			if typeof(line_value) != TYPE_DICTIONARY:
				continue
			var line: Dictionary = line_value
			rows.append("line:%s:%s:%s:%s:%s" % [
				section_id,
				str(line.get("id", line.get("metric_id", ""))),
				str(line.get("metric_id", line.get("id", ""))),
				snappedf(float(line.get("value", 0.0)), 0.001),
				"|".join(_string_array(line.get("source_effect_ids", [])))
			])
	for note_value in _variant_array(statement.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		rows.append("note:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [
			str(note.get("note_id", "")),
			str(note.get("note_type", "")),
			str(note.get("disclosure_quality", "")),
			str(note.get("detail_level", "")),
			str(note.get("tone", "")),
			snappedf(float(note.get("importance", 0.0)), 0.001),
			"|".join(_string_array(note.get("metric_ids", []))),
			"|".join(_string_array(note.get("effect_ids", []))),
			"|".join(_string_array(note.get("explain_tags", []))),
			str(note.get("summary", ""))
		])
	for adjustment_value in _variant_array(statement.get("story_adjustments", [])):
		if typeof(adjustment_value) != TYPE_DICTIONARY:
			continue
		var adjustment: Dictionary = adjustment_value
		rows.append("adjustment:%s:%s:%s:%s:%s:%s:%s" % [
			str(adjustment.get("adjustment_id", "")),
			str(adjustment.get("metric_id", "")),
			str(adjustment.get("direction", "")),
			str(adjustment.get("note_id", "")),
			snappedf(float(adjustment.get("applied_delta_pct", 0.0)), 0.0001),
			snappedf(float(adjustment.get("applied_delta_amount", 0.0)), 0.001),
			"|".join(_string_array(adjustment.get("clue_ids", [])))
		])
	var traceability: Dictionary = statement.get("traceability", {}) if typeof(statement.get("traceability", {})) == TYPE_DICTIONARY else {}
	rows.append("trace:%s:%s:%s" % [
		"|".join(_string_array(traceability.get("source_effect_ids", []))),
		"|".join(_string_array(traceability.get("generated_adjustment_ids", []))),
		"|".join(_string_array(traceability.get("generated_note_ids", [])))
	])
	return "\n".join(rows)


func _line_value(statement: Dictionary, section_id: String, line_id: String) -> float:
	for line_value in _variant_array(statement.get(section_id, [])):
		if typeof(line_value) != TYPE_DICTIONARY:
			continue
		var line: Dictionary = line_value
		if str(line.get("id", "")) == line_id or str(line.get("metric_id", "")) == line_id:
			return float(line.get("value", 0.0))
	return 0.0


func _line_delta(base_statement: Dictionary, adjusted: Dictionary, section_id: String, line_id: String) -> float:
	return _line_value(adjusted, section_id, line_id) - _line_value(base_statement, section_id, line_id)


func _line_has_source_any(statement: Dictionary, effect_id: String) -> bool:
	for section_id in ["income_statement", "balance_sheet", "cash_flow", "operating_metrics"]:
		for line_value in _variant_array(statement.get(section_id, [])):
			if typeof(line_value) != TYPE_DICTIONARY:
				continue
			var line: Dictionary = line_value
			if _string_array(line.get("source_effect_ids", [])).has(effect_id):
				return true
	return false


func _note_by_type(statement: Dictionary, note_type: String) -> Dictionary:
	for note_value in _variant_array(statement.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		if str(note.get("note_type", "")) == note_type:
			return note
	return {}


func _company_id(case_id: String) -> String:
	return "matrixco_%s" % case_id


func _story_id(case_id: String) -> String:
	return "story|%s|%s" % [_company_id(case_id), case_id]


func _effect_id(case_id: String, metric_id: String) -> String:
	return "effect|%s|%s" % [_story_id(case_id), metric_id]


func _fact_id(case_id: String) -> String:
	return "fact|%s|primary" % _story_id(case_id)


func _clue_id(case_id: String) -> String:
	return "clue|%s|statement|01" % _story_id(case_id)


func _negative_allowed_line_ids() -> Array:
	return ["cash_from_investing", "free_cash_flow", "net_income", "operating_income"]


func _json_contains_hidden_truth(statement: Dictionary) -> bool:
	var text: String = JSON.stringify(statement).to_lower()
	for token in ["truth_state", "fraud_risk", "overhyped", "uncertain", "delayed", "failed"]:
		if text.find(token) >= 0:
			return true
	return false


func _case_ok(case_id: String, summary: Dictionary, payload: String) -> Dictionary:
	return {"success": true, "case_id": case_id, "summary": summary, "payload": payload}


func _case_fail(message: String) -> Dictionary:
	return {"success": false, "message": message}


func _variant_array(source_value: Variant) -> Array:
	if typeof(source_value) == TYPE_ARRAY:
		return source_value.duplicate(true)
	return []


func _string_array(source_value: Variant) -> Array:
	var result: Array = []
	for item_value in _variant_array(source_value):
		var text: String = str(item_value).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	result.sort()
	return result


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
	print("FINANCIAL_STATEMENT_LAYER_SNAPSHOT_MATRIX_FAIL: %s" % message)
	get_tree().quit(1)
