extends Node

const FINANCIAL_STATEMENT_LAYER = preload("res://systems/FinancialStatementLayer.gd")

const EXPECTED_HASH := "353480211"


func _ready() -> void:
	var revenue_report: Dictionary = _run_revenue_jump_case()
	if not revenue_report.get("success", false):
		_fail(str(revenue_report.get("message", "revenue jump case failed")))
		return

	var capex_report: Dictionary = _run_failed_capex_case()
	if not capex_report.get("success", false):
		_fail(str(capex_report.get("message", "failed capex case failed")))
		return

	var payload: String = "%s\n%s" % [
		str(revenue_report.get("payload", "")),
		str(capex_report.get("payload", ""))
	]
	var hash: String = _stable_hash(payload)
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Financial statement story-effect hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("FINANCIAL_STATEMENT_LAYER_STORY_EFFECT_OK %s" % JSON.stringify({
		"hash": hash,
		"revenue_case": revenue_report.get("summary", {}),
		"capex_case": capex_report.get("summary", {})
	}))
	get_tree().quit(0)


func _run_revenue_jump_case() -> Dictionary:
	var statement: Dictionary = _base_statement()
	var base_revenue: float = _line_value(statement, "income_statement", "revenue")
	var base_net_income: float = _line_value(statement, "income_statement", "net_income")
	var dossier: Dictionary = {
		"story_id": "story|testco|contract_win|case_a",
		"company_id": "testco",
		"priority": 0.84,
		"cause_facts": [
			{"fact_id": "fact|story|testco|contract_win|case_a|customer", "fact_type": "company_trait", "source_id": "contract_win"}
		],
		"financial_effects": [
			{
				"effect_id": "effect|story|testco|contract_win|case_a|revenue",
				"metric_id": "revenue",
				"statement_section": "income_statement",
				"direction": "up",
				"magnitude_band": "large",
				"persistence": "durable",
				"confidence": 0.90,
				"note_type": "customer_contract"
			},
			{
				"effect_id": "effect|story|testco|contract_win|case_a|backlog",
				"metric_id": "backlog",
				"statement_section": "operating_metrics",
				"direction": "up",
				"magnitude_band": "moderate",
				"persistence": "temporary",
				"confidence": 0.78,
				"note_type": "backlog_contract"
			}
		],
		"statement_clues": [
			{
				"clue_id": "clue|story|testco|contract_win|case_a|statement|01",
				"surface_id": "statement_note",
				"metric_ids": ["revenue", "backlog"],
				"disclosure_quality": "clear"
			}
		]
	}
	var adjusted: Dictionary = FINANCIAL_STATEMENT_LAYER.apply_story_effects_to_statement(
		statement,
		[dossier],
		{"revenue": base_revenue * 4.0},
		{"company_id": "testco", "ticker": "TEST", "sector_id": "industrial", "filing_day_index": 80}
	)
	var adjusted_revenue: float = _line_value(adjusted, "income_statement", "revenue")
	var adjusted_net_income: float = _line_value(adjusted, "income_statement", "net_income")
	var backlog: float = _line_value(adjusted, "operating_metrics", "backlog")
	var adjustments: Array = _variant_array(adjusted.get("story_adjustments", []))
	if adjusted_revenue <= base_revenue:
		return _case_fail("Expected story revenue effect to increase revenue.")
	if adjusted_revenue > base_revenue * 1.18:
		return _case_fail("Revenue effect exceeded 18%% cap. base=%s adjusted=%s" % [base_revenue, adjusted_revenue])
	if adjusted_net_income <= base_net_income:
		return _case_fail("Expected revenue effect to carry through to net income.")
	if backlog <= 0.0:
		return _case_fail("Expected backlog effect to create an operating metric row.")
	if adjustments.size() != 2:
		return _case_fail("Expected exactly two story adjustments, got %d." % adjustments.size())
	if not _line_has_source(adjusted, "income_statement", "revenue", "effect|story|testco|contract_win|case_a|revenue"):
		return _case_fail("Expected revenue line to preserve source effect id.")
	if not _line_has_source(adjusted, "operating_metrics", "backlog", "effect|story|testco|contract_win|case_a|backlog"):
		return _case_fail("Expected backlog line to preserve source effect id.")
	if _json_contains_hidden_truth(adjusted):
		return _case_fail("Adjusted revenue statement leaked hidden truth metadata.")
	return _case_ok({
		"revenue_delta": snappedf(adjusted_revenue - base_revenue, 0.001),
		"net_income_delta": snappedf(adjusted_net_income - base_net_income, 0.001),
		"backlog": snappedf(backlog, 0.001),
		"adjustments": adjustments.size()
	}, _statement_payload(adjusted))


func _run_failed_capex_case() -> Dictionary:
	var statement: Dictionary = _base_statement()
	statement["cash_flow"].append({"id": "capex", "label": "Capital expenditure", "value": 140.0, "format": "currency"})
	var base_capex: float = _line_value(statement, "cash_flow", "capex")
	var base_investing: float = _line_value(statement, "cash_flow", "cash_from_investing")
	var dossier: Dictionary = {
		"story_id": "story|testco|capex_expansion|case_b",
		"company_id": "testco",
		"priority": 0.78,
		"cause_facts": [
			{"fact_id": "fact|story|testco|capex_expansion|case_b|plant", "fact_type": "company_trait", "source_id": "capacity_expansion"}
		],
		"financial_effects": [
			{
				"effect_id": "effect|story|testco|capex_expansion|case_b|capex",
				"metric_id": "capex",
				"statement_section": "cash_flow",
				"direction": "down",
				"magnitude_band": "large",
				"persistence": "negative",
				"confidence": 0.90,
				"note_type": "capex_progress"
			}
		],
		"statement_clues": [
			{
				"clue_id": "clue|story|testco|capex_expansion|case_b|statement|01",
				"surface_id": "statement_note",
				"metric_ids": ["capex"],
				"disclosure_quality": "weak"
			}
		]
	}
	var adjusted: Dictionary = FINANCIAL_STATEMENT_LAYER.apply_story_effects_to_statement(
		statement,
		[dossier],
		{"revenue": 4000.0},
		{"company_id": "testco", "ticker": "TEST", "sector_id": "industrial", "filing_day_index": 90}
	)
	var adjusted_capex: float = _line_value(adjusted, "cash_flow", "capex")
	var adjusted_investing: float = _line_value(adjusted, "cash_flow", "cash_from_investing")
	var adjustments: Array = _variant_array(adjusted.get("story_adjustments", []))
	if adjusted_capex >= base_capex:
		return _case_fail("Expected failed capex effect to reduce capex. base=%s adjusted=%s" % [base_capex, adjusted_capex])
	if adjusted_capex < 0.0:
		return _case_fail("Capex effect should not drive capex below zero.")
	if adjusted_investing <= base_investing:
		return _case_fail("Lower capex should make cash from investing less negative.")
	if adjustments.size() != 1:
		return _case_fail("Expected one capex story adjustment, got %d." % adjustments.size())
	var adjustment: Dictionary = adjustments[0]
	if float(adjustment.get("applied_delta_amount", 0.0)) >= 0.0:
		return _case_fail("Expected capex adjustment delta to be negative.")
	if not _line_has_source(adjusted, "cash_flow", "capex", "effect|story|testco|capex_expansion|case_b|capex"):
		return _case_fail("Expected capex line to preserve source effect id.")
	if _json_contains_hidden_truth(adjusted):
		return _case_fail("Adjusted capex statement leaked hidden truth metadata.")
	return _case_ok({
		"capex_delta": snappedf(adjusted_capex - base_capex, 0.001),
		"investing_delta": snappedf(adjusted_investing - base_investing, 0.001),
		"adjustments": adjustments.size()
	}, _statement_payload(adjusted))


func _base_statement() -> Dictionary:
	return {
		"statement_year": 2020,
		"statement_quarter": 2,
		"statement_period_label": "Q2 2020",
		"income_statement": [
			{"id": "revenue", "label": "Total revenue", "value": 1000.0, "format": "currency"},
			{"id": "gross_profit", "label": "Gross profit", "value": 320.0, "format": "currency"},
			{"id": "operating_income", "label": "Income from operations", "value": 160.0, "format": "currency"},
			{"id": "net_income", "label": "Net income for the period", "value": 90.0, "format": "currency"}
		],
		"balance_sheet": [
			{"id": "current_assets", "label": "Current assets", "value": 620.0, "format": "currency"},
			{"id": "total_assets", "label": "Total assets", "value": 1800.0, "format": "currency"},
			{"id": "total_liabilities", "label": "Total liabilities", "value": 720.0, "format": "currency"},
			{"id": "equity", "label": "Equity", "value": 1080.0, "format": "currency"},
			{"id": "shares_outstanding", "label": "Shares outstanding", "value": 1000000.0, "format": "shares"}
		],
		"cash_flow": [
			{"id": "cash_from_operating", "label": "Cash from operating", "value": 120.0, "format": "currency"},
			{"id": "cash_from_investing", "label": "Cash from investing", "value": -180.0, "format": "currency"},
			{"id": "cash_from_financing", "label": "Cash from financing", "value": 30.0, "format": "currency"}
		]
	}


func _line_value(statement: Dictionary, section_id: String, line_id: String) -> float:
	for line_value in _variant_array(statement.get(section_id, [])):
		if typeof(line_value) != TYPE_DICTIONARY:
			continue
		var line: Dictionary = line_value
		if str(line.get("id", "")) == line_id or str(line.get("metric_id", "")) == line_id:
			return float(line.get("value", 0.0))
	return 0.0


func _line_has_source(statement: Dictionary, section_id: String, line_id: String, effect_id: String) -> bool:
	for line_value in _variant_array(statement.get(section_id, [])):
		if typeof(line_value) != TYPE_DICTIONARY:
			continue
		var line: Dictionary = line_value
		if str(line.get("id", "")) != line_id and str(line.get("metric_id", "")) != line_id:
			continue
		return _string_array(line.get("source_effect_ids", [])).has(effect_id)
	return false


func _json_contains_hidden_truth(statement: Dictionary) -> bool:
	var text: String = JSON.stringify(statement).to_lower()
	for token in ["truth_state", "fraud_risk", "overhyped", "uncertain"]:
		if text.find(token) >= 0:
			return true
	return false


func _statement_payload(statement: Dictionary) -> String:
	var rows: Array[String] = []
	rows.append("statement_id=%s" % str(statement.get("statement_id", "")))
	for section_id in ["income_statement", "balance_sheet", "cash_flow", "operating_metrics"]:
		for line_value in _variant_array(statement.get(section_id, [])):
			if typeof(line_value) != TYPE_DICTIONARY:
				continue
			var line: Dictionary = line_value
			rows.append("%s:%s:%s:%s" % [
				section_id,
				str(line.get("id", line.get("metric_id", ""))),
				snappedf(float(line.get("value", 0.0)), 0.001),
				"|".join(_string_array(line.get("source_effect_ids", [])))
			])
	for adjustment_value in _variant_array(statement.get("story_adjustments", [])):
		if typeof(adjustment_value) != TYPE_DICTIONARY:
			continue
		var adjustment: Dictionary = adjustment_value
		rows.append("adjustment:%s:%s:%s:%s:%s" % [
			str(adjustment.get("adjustment_id", "")),
			str(adjustment.get("metric_id", "")),
			str(adjustment.get("direction", "")),
			snappedf(float(adjustment.get("applied_delta_amount", 0.0)), 0.001),
			"|".join(_string_array(adjustment.get("clue_ids", [])))
		])
	return "\n".join(rows)


func _case_ok(summary: Dictionary, payload: String) -> Dictionary:
	return {"success": true, "summary": summary, "payload": payload}


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
	print("FINANCIAL_STATEMENT_LAYER_STORY_EFFECT_FAIL: %s" % message)
	get_tree().quit(1)
