extends Node

const RUN_SEED := 20260621
const EXPECTED_HASH := "1613787417"
const EXPECTED_ROW_MODEL_COUNT := 62
const EXPECTED_CHECK_COUNT := 22
const REQUIRED_ROW_METRICS := [
	"cash",
	"trade_receivables",
	"inventories",
	"property_plant_equipment",
	"short_term_borrowings",
	"long_term_borrowings",
	"debt_and_borrowings",
	"equity",
	"retained_earnings",
	"dividends_declared",
	"revenue",
	"cost_of_revenue",
	"gross_profit",
	"selling_expenses",
	"general_admin_expenses",
	"operating_income",
	"finance_cost",
	"tax_expense",
	"net_income",
	"depreciation_and_amortization",
	"working_capital_changes",
	"cash_from_operating",
	"cash_from_investing",
	"cash_from_financing",
	"other_financing_cash_flow",
	"ending_cash"
]
const REQUIRED_CHECK_KEYS := [
	"current_asset_subtotal",
	"non_current_asset_subtotal",
	"asset_subtotal",
	"current_liability_subtotal",
	"non_current_liability_subtotal",
	"debt_borrowings_subtotal",
	"liability_subtotal",
	"equity_subtotal",
	"balance_sheet_equation",
	"gross_profit_bridge",
	"operating_income_bridge",
	"pretax_income_bridge",
	"net_income_bridge",
	"comprehensive_income_bridge",
	"equity_roll_forward",
	"operating_cash_flow_bridge",
	"investing_cash_flow_bridge",
	"financing_cash_flow_bridge",
	"net_cash_change_bridge",
	"cash_reconciliation",
	"cash_matches_financial_position",
	"equity_matches_financial_position"
]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_report()
	if not bool(first_report.get("success", false)):
		_fail(str(first_report.get("message", "annual statement accounting continuity failed")))
		return
	var second_report: Dictionary = _build_report()
	if not bool(second_report.get("success", false)):
		_fail(str(second_report.get("message", "repeated annual statement accounting continuity failed")))
		return
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Annual accounting continuity payload changed across repeated fixed-seed runs.")
		return

	var hash: String = _stable_hash(str(first_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual accounting continuity hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_STATEMENT_ACCOUNTING_CONTINUITY_OK %s" % JSON.stringify({
		"hash": hash,
		"company_id": str(first_report.get("company_id", "")),
		"fiscal_year": int(first_report.get("fiscal_year", 0)),
		"row_model_count": int(first_report.get("row_model_count", 0)),
		"check_count": int(first_report.get("check_count", 0))
	}))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	if RunState.company_order.is_empty():
		return _case_fail("Expected generated company order.")
	var company_id: String = str(RunState.company_order[0])
	if not RunState.ensure_company_full_detail(company_id):
		return _case_fail("Could not hydrate full detail for %s." % company_id)
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, true, true)
	var snapshot: Dictionary = definition.get("financial_statement_snapshot", {}) if typeof(definition.get("financial_statement_snapshot", {})) == TYPE_DICTIONARY else {}
	var annual: Dictionary = snapshot.get("annual_statement", {}) if typeof(snapshot.get("annual_statement", {})) == TYPE_DICTIONARY else {}
	var validation: Dictionary = _validate_annual_accounting(annual)
	if not bool(validation.get("success", false)):
		return validation
	return {
		"success": true,
		"payload": _continuity_payload(company_id, annual),
		"company_id": company_id,
		"fiscal_year": int(annual.get("fiscal_year", 0)),
		"row_model_count": _variant_array(annual.get("accounting_row_model", [])).size(),
		"check_count": _variant_array(annual.get("accounting_continuity_checks", [])).size()
	}


func _validate_annual_accounting(annual: Dictionary) -> Dictionary:
	if annual.is_empty():
		return _case_fail("Expected annual statement.")
	var row_model: Array = _variant_array(annual.get("accounting_row_model", []))
	if row_model.size() != EXPECTED_ROW_MODEL_COUNT:
		return _case_fail("Expected %d accounting row model rows, got %d." % [EXPECTED_ROW_MODEL_COUNT, row_model.size()])
	var row_metric_ids: Array = []
	var row_model_ids: Array = []
	for row_value in row_model:
		if typeof(row_value) != TYPE_DICTIONARY:
			return _case_fail("Expected accounting row model dictionaries.")
		var row: Dictionary = row_value
		if int(row.get("schema_version", 0)) != 1:
			return _case_fail("Expected accounting row model schema version 1.")
		var row_model_id: String = str(row.get("row_model_id", "")).strip_edges()
		if row_model_id.is_empty() or row_model_ids.has(row_model_id):
			return _case_fail("Expected unique accounting row model ids.")
		row_model_ids.append(row_model_id)
		var metric_id: String = str(row.get("metric_id", "")).strip_edges()
		if metric_id.is_empty():
			return _case_fail("Expected accounting row model metric ids.")
		row_metric_ids.append(metric_id)
		if str(row.get("section_id", "")).strip_edges().is_empty():
			return _case_fail("Expected accounting row model section id for %s." % metric_id)
		if str(row.get("note_ref", "")).strip_edges().is_empty():
			return _case_fail("Expected accounting row model note ref for %s." % metric_id)
		if str(row.get("continuity_group", "")).strip_edges().is_empty():
			return _case_fail("Expected accounting row model continuity group for %s." % metric_id)
	for required_metric in REQUIRED_ROW_METRICS:
		if not row_metric_ids.has(str(required_metric)):
			return _case_fail("Missing accounting row model metric %s." % str(required_metric))

	var checks: Array = _variant_array(annual.get("accounting_continuity_checks", []))
	if checks.size() != EXPECTED_CHECK_COUNT:
		return _case_fail("Expected %d accounting continuity checks, got %d." % [EXPECTED_CHECK_COUNT, checks.size()])
	var check_keys: Array = []
	var failed_checks: Array = []
	for check_value in checks:
		if typeof(check_value) != TYPE_DICTIONARY:
			return _case_fail("Expected accounting continuity check dictionaries.")
		var check: Dictionary = check_value
		if int(check.get("schema_version", 0)) != 1:
			return _case_fail("Expected accounting continuity schema version 1.")
		var check_key: String = str(check.get("check_key", "")).strip_edges()
		if check_key.is_empty() or check_keys.has(check_key):
			return _case_fail("Expected unique accounting continuity check keys.")
		check_keys.append(check_key)
		if str(check.get("status", "")) != "passed":
			failed_checks.append("%s:%s" % [check_key, str(check.get("variance", ""))])
		if absf(float(check.get("variance", 0.0))) > float(check.get("tolerance", 0.0)):
			return _case_fail("Continuity check %s exceeded tolerance." % check_key)
		if _variant_array(check.get("metric_ids", [])).is_empty():
			return _case_fail("Expected continuity check %s to reference metrics." % check_key)
		for metric_value in _variant_array(check.get("metric_ids", [])):
			var metric_id: String = str(metric_value)
			if not row_metric_ids.has(metric_id):
				return _case_fail("Continuity check %s references unmodeled metric %s." % [check_key, metric_id])
	for required_check in REQUIRED_CHECK_KEYS:
		if not check_keys.has(str(required_check)):
			return _case_fail("Missing accounting continuity check %s." % str(required_check))
	if not failed_checks.is_empty():
		return _case_fail("Accounting continuity checks failed: %s." % "|".join(_string_array(failed_checks)))

	var traceability: Dictionary = annual.get("traceability", {}) if typeof(annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	if int(traceability.get("accounting_row_model_schema_version", 0)) != 1:
		return _case_fail("Expected traceability accounting row model schema version.")
	if int(traceability.get("accounting_continuity_schema_version", 0)) != 1:
		return _case_fail("Expected traceability accounting continuity schema version.")
	if str(traceability.get("accounting_continuity_status", "")) != "r3_2_continuity_ready":
		return _case_fail("Expected R3.2 continuity-ready traceability status.")
	if int(traceability.get("accounting_continuity_failed_count", -1)) != 0:
		return _case_fail("Expected zero accounting continuity failures.")
	if _variant_array(traceability.get("accounting_continuity_check_ids", [])).size() != EXPECTED_CHECK_COUNT:
		return _case_fail("Expected traceability to list all accounting continuity check ids.")
	if _line_value(annual, "financial_position", "debt_and_borrowings") <= 0.0:
		return _case_fail("Expected explicit total debt and borrowings row.")
	if _line_value(annual, "cash_flows", "depreciation_and_amortization") <= 0.0:
		return _case_fail("Expected depreciation and amortization cash-flow bridge row.")
	if not _has_line(annual, "cash_flows", "other_financing_cash_flow"):
		return _case_fail("Expected other financing cash flow bridge row.")
	return _case_ok()


func _continuity_payload(company_id: String, annual: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("company=%s" % company_id)
	lines.append("statement=%s" % str(annual.get("statement_id", "")))
	for row_value in _variant_array(annual.get("accounting_row_model", [])):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("row:%s:%s:%s:%s:%s" % [
			str(row.get("section_id", "")),
			str(row.get("metric_id", "")),
			str(row.get("row_role", "")),
			str(row.get("normal_balance", "")),
			str(row.get("continuity_group", ""))
		])
	for check_value in _variant_array(annual.get("accounting_continuity_checks", [])):
		if typeof(check_value) != TYPE_DICTIONARY:
			continue
		var check: Dictionary = check_value
		lines.append("check:%s:%s:%s:%s:%s" % [
			str(check.get("check_key", "")),
			str(check.get("section_id", "")),
			str(check.get("status", "")),
			_float_token(float(check.get("expected_value", 0.0))),
			_float_token(float(check.get("actual_value", 0.0)))
		])
	for section_id in ["financial_position", "profit_or_loss_and_oci", "changes_in_equity", "cash_flows"]:
		for metric_id in _section_payload_metrics(section_id):
			lines.append("line:%s:%s:%s" % [
				section_id,
				metric_id,
				_float_token(_line_value(annual, section_id, metric_id))
			])
	return "\n".join(lines)


func _section_payload_metrics(section_id: String) -> Array:
	match section_id:
		"financial_position":
			return ["cash", "trade_receivables", "inventories", "property_plant_equipment", "short_term_borrowings", "long_term_borrowings", "debt_and_borrowings", "equity"]
		"profit_or_loss_and_oci":
			return ["revenue", "cost_of_revenue", "gross_profit", "operating_income", "finance_cost", "tax_expense", "net_income"]
		"changes_in_equity":
			return ["opening_equity", "profit_for_year", "dividends_declared", "closing_equity"]
		"cash_flows":
			return ["net_income_cash_flow_anchor", "depreciation_and_amortization", "working_capital_changes", "other_operating_cash_flow", "cash_from_operating", "purchase_of_ppe", "asset_sale_proceeds", "cash_from_investing", "debt_proceeds", "debt_repayments", "dividends_paid", "other_financing_cash_flow", "cash_from_financing", "ending_cash"]
	return []


func _line_value(statement: Dictionary, section_id: String, metric_id: String) -> float:
	for line_value in _variant_array(statement.get(section_id, [])):
		if typeof(line_value) != TYPE_DICTIONARY:
			continue
		var line: Dictionary = line_value
		if str(line.get("id", "")) == metric_id or str(line.get("metric_id", "")) == metric_id:
			return float(line.get("value", 0.0))
	return 0.0


func _has_line(statement: Dictionary, section_id: String, metric_id: String) -> bool:
	for line_value in _variant_array(statement.get(section_id, [])):
		if typeof(line_value) != TYPE_DICTIONARY:
			continue
		var line: Dictionary = line_value
		if str(line.get("id", "")) == metric_id or str(line.get("metric_id", "")) == metric_id:
			return true
	return false


func _case_ok() -> Dictionary:
	return {"success": true}


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


func _float_token(value: float) -> String:
	return "%.3f" % value


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
	print("ANNUAL_STATEMENT_ACCOUNTING_CONTINUITY_FAIL: %s" % message)
	get_tree().quit(1)
