extends Node

const RUN_SEED := 20260617
const EXPECTED_HASH := "867613961"
const EXPECTED_NOTE_COUNT := 14
const EXPECTED_NOTE_TYPES := [
	"company_information",
	"basis_of_preparation",
	"revenue",
	"cost_of_revenue_and_gross_profit",
	"operating_expenses",
	"segment_information",
	"cash_and_cash_equivalents",
	"trade_receivables",
	"inventories",
	"property_plant_and_equipment",
	"debt_and_borrowings",
	"equity_and_dividends",
	"cash_flow_information",
	"commitments_contingencies_and_subsequent_events"
]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_report()
	if not first_report.get("success", false):
		_fail(str(first_report.get("message", "annual consolidated statement report failed")))
		return
	var second_report: Dictionary = _build_report()
	if not second_report.get("success", false):
		_fail(str(second_report.get("message", "repeated annual consolidated statement report failed")))
		return
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Annual consolidated statement payload changed across repeated fixed-seed runs.")
		return

	var hash: String = _stable_hash(str(first_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual consolidated statement hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK %s" % JSON.stringify({
		"hash": hash,
		"company_id": str(first_report.get("company_id", "")),
		"ticker": str(first_report.get("ticker", "")),
		"fiscal_year": int(first_report.get("fiscal_year", 0)),
		"note_count": int(first_report.get("note_count", 0)),
		"section_count": int(first_report.get("section_count", 0)),
		"revenue": float(first_report.get("revenue", 0.0)),
		"net_income": float(first_report.get("net_income", 0.0))
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
	var validation: Dictionary = _validate_annual_statement(snapshot, annual)
	if not validation.get("success", false):
		return validation
	var payload: String = _annual_payload(company_id, definition, annual, snapshot)
	return {
		"success": true,
		"payload": payload,
		"company_id": company_id,
		"ticker": str(definition.get("ticker", "")),
		"fiscal_year": int(annual.get("fiscal_year", 0)),
		"note_count": _variant_array(annual.get("note_index", [])).size(),
		"section_count": _variant_array(annual.get("document_sections", [])).size(),
		"revenue": _line_value(annual, "profit_or_loss_and_oci", "revenue"),
		"net_income": _line_value(annual, "profit_or_loss_and_oci", "net_income")
	}


func _validate_annual_statement(snapshot: Dictionary, annual: Dictionary) -> Dictionary:
	if annual.is_empty():
		return _case_fail("Expected annual consolidated statement in financial statement snapshot.")
	if int(annual.get("schema_version", 0)) <= 0:
		return _case_fail("Expected annual statement schema version.")
	if str(annual.get("source_system_id", "")) != "annual_consolidated_statement_builder":
		return _case_fail("Expected annual statement builder source system.")
	if str(annual.get("statement_scope", "")) != "annual":
		return _case_fail("Expected annual statement scope.")
	if not bool(annual.get("consolidated", false)):
		return _case_fail("Expected consolidated annual statement flag.")
	if int(annual.get("fiscal_year", 0)) != 2019:
		return _case_fail("Expected FY2019 annual statement, got %s." % str(annual.get("fiscal_year", "")))
	if int(annual.get("comparative_year", 0)) != 2018:
		return _case_fail("Expected FY2018 comparative year, got %s." % str(annual.get("comparative_year", "")))
	if str(annual.get("statement_period_label", "")) != "FY2019":
		return _case_fail("Expected FY2019 period label.")
	if str(annual.get("page_size_hint", "")) != "A4":
		return _case_fail("Expected A4 page size hint.")
	if str(annual.get("report_title", "")) != "Consolidated Financial Statements":
		return _case_fail("Expected consolidated financial statements report title.")
	if str(annual.get("audit_status", "")) != "audited":
		return _case_fail("Expected audited annual statement status.")

	var section_ids: Array = _document_section_ids(annual)
	var required_sections: Array = ["financial_position", "profit_or_loss_and_oci", "changes_in_equity", "cash_flows", "notes"]
	if _string_array(section_ids) != _string_array(required_sections):
		return _case_fail("Annual document sections changed. expected=%s actual=%s." % [_string_array(required_sections), _string_array(section_ids)])
	if _variant_array(annual.get("note_index", [])).size() != EXPECTED_NOTE_COUNT:
		return _case_fail("Expected %d annual note index rows, got %d." % [EXPECTED_NOTE_COUNT, _variant_array(annual.get("note_index", [])).size()])
	if _variant_array(annual.get("notes", [])).size() != EXPECTED_NOTE_COUNT:
		return _case_fail("Expected %d generated annual notes, got %d." % [EXPECTED_NOTE_COUNT, _variant_array(annual.get("notes", [])).size()])
	var note_validation: Dictionary = _validate_annual_notes(annual)
	if not bool(note_validation.get("success", false)):
		return note_validation

	for section_id in ["financial_position", "profit_or_loss_and_oci", "changes_in_equity", "cash_flows"]:
		if _variant_array(annual.get(section_id, [])).is_empty():
			return _case_fail("Expected annual section %s to be populated." % section_id)

	if _variant_array(annual.get("income_statement", [])).size() != _variant_array(annual.get("profit_or_loss_and_oci", [])).size():
		return _case_fail("Annual compatibility income_statement mirror is missing.")
	if _variant_array(annual.get("balance_sheet", [])).size() != _variant_array(annual.get("financial_position", [])).size():
		return _case_fail("Annual compatibility balance_sheet mirror is missing.")
	if _variant_array(annual.get("cash_flow", [])).size() != _variant_array(annual.get("cash_flows", [])).size():
		return _case_fail("Annual compatibility cash_flow mirror is missing.")

	var quarterly_statements: Array = _variant_array(snapshot.get("quarterly_statements", []))
	var year_quarters: Array = []
	for statement_value in quarterly_statements:
		if typeof(statement_value) == TYPE_DICTIONARY and int(statement_value.get("statement_year", 0)) == 2019:
			year_quarters.append(statement_value)
	if year_quarters.size() != 4:
		return _case_fail("Expected four FY2019 source quarters, got %d." % year_quarters.size())
	var annual_revenue: float = _line_value(annual, "profit_or_loss_and_oci", "revenue")
	var quarter_revenue: float = _sum_quarter_lines(year_quarters, "income_statement", "revenue")
	if not _nearly_equal(annual_revenue, quarter_revenue, 0.02):
		return _case_fail("Annual revenue did not match source quarter sum. annual=%s quarterly=%s" % [annual_revenue, quarter_revenue])
	var annual_net_income: float = _line_value(annual, "profit_or_loss_and_oci", "net_income")
	var quarter_net_income: float = _sum_quarter_lines(year_quarters, "income_statement", "net_income")
	if not _nearly_equal(annual_net_income, quarter_net_income, 0.02):
		return _case_fail("Annual net income did not match source quarter sum. annual=%s quarterly=%s" % [annual_net_income, quarter_net_income])

	var total_assets: float = _line_value(annual, "financial_position", "total_assets")
	var total_liabilities: float = _line_value(annual, "financial_position", "total_liabilities")
	var equity: float = _line_value(annual, "financial_position", "equity")
	if not _nearly_equal(total_assets, total_liabilities + equity, 0.03):
		return _case_fail("Annual financial position does not balance.")
	var current_assets: float = _line_value(annual, "financial_position", "current_assets")
	var non_current_assets: float = _line_value(annual, "financial_position", "non_current_assets")
	if not _nearly_equal(total_assets, current_assets + non_current_assets, 0.03):
		return _case_fail("Annual asset subtotals do not add to total assets.")
	var cash: float = _line_value(annual, "financial_position", "cash")
	var receivables: float = _line_value(annual, "financial_position", "trade_receivables")
	var inventories: float = _line_value(annual, "financial_position", "inventories")
	var other_current_assets: float = _line_value(annual, "financial_position", "other_current_assets")
	if not _nearly_equal(current_assets, cash + receivables + inventories + other_current_assets, 0.04):
		return _case_fail("Annual current asset split does not add to current assets.")

	var opening_equity: float = _line_value(annual, "changes_in_equity", "opening_equity")
	var profit_for_year: float = _line_value(annual, "changes_in_equity", "profit_for_year")
	var oci: float = _line_value(annual, "changes_in_equity", "other_comprehensive_income")
	var dividends: float = _line_value(annual, "changes_in_equity", "dividends_declared")
	var other_equity_movements: float = _line_value(annual, "changes_in_equity", "other_equity_movements")
	var closing_equity: float = _line_value(annual, "changes_in_equity", "closing_equity")
	if not _nearly_equal(closing_equity, opening_equity + profit_for_year + oci + dividends + other_equity_movements, 0.04):
		return _case_fail("Annual changes in equity do not roll forward to closing equity.")
	if not _nearly_equal(closing_equity, equity, 0.03):
		return _case_fail("Annual closing equity does not match financial position equity.")

	var net_change_cash: float = _line_value(annual, "cash_flows", "net_change_cash")
	var beginning_cash: float = _line_value(annual, "cash_flows", "beginning_cash")
	var exchange_effect: float = _line_value(annual, "cash_flows", "effect_of_exchange_rate")
	var ending_cash: float = _line_value(annual, "cash_flows", "ending_cash")
	if not _nearly_equal(ending_cash, beginning_cash + net_change_cash + exchange_effect, 0.04):
		return _case_fail("Annual cash flow does not reconcile to ending cash.")
	if not _nearly_equal(ending_cash, cash, 0.03):
		return _case_fail("Annual ending cash does not match financial position cash.")

	var traceability: Dictionary = annual.get("traceability", {}) if typeof(annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	if _variant_array(traceability.get("source_quarterly_periods", [])).size() != 4:
		return _case_fail("Annual statement traceability should list four source quarters.")
	if _variant_array(traceability.get("generated_note_ids", [])).size() != EXPECTED_NOTE_COUNT:
		return _case_fail("Annual statement traceability should list generated note index ids.")
	return _case_ok("", "")


func _annual_payload(company_id: String, definition: Dictionary, annual: Dictionary, snapshot: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("company=%s" % company_id)
	lines.append("ticker=%s" % str(definition.get("ticker", "")))
	lines.append("statement_id=%s" % str(annual.get("statement_id", "")))
	lines.append("scope=%s consolidated=%s fiscal=%d comparative=%d page=%s" % [
		str(annual.get("statement_scope", "")),
		str(annual.get("consolidated", false)),
		int(annual.get("fiscal_year", 0)),
		int(annual.get("comparative_year", 0)),
		str(annual.get("page_size_hint", ""))
	])
	for section_id in ["financial_position", "profit_or_loss_and_oci", "changes_in_equity", "cash_flows"]:
		for line_value in _variant_array(annual.get(section_id, [])):
			if typeof(line_value) != TYPE_DICTIONARY:
				continue
			var line: Dictionary = line_value
			lines.append("%s:%s:%s:%s" % [
				section_id,
				str(line.get("id", line.get("metric_id", ""))),
				str(line.get("metric_id", "")),
				_float_token(float(line.get("value", 0.0)))
			])
	for note_value in _variant_array(annual.get("note_index", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		lines.append("note:%02d:%s:%s:%s" % [
			int(note.get("note_number", 0)),
			str(note.get("note_type", "")),
			str(note.get("title", "")),
			"|".join(_string_array(note.get("source_statement_sections", [])))
		])
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		lines.append("generated_note:%02d:%s:%s:%s:%s:%s" % [
			int(note.get("note_number", 0)),
			str(note.get("note_type", "")),
			str(note.get("statement_scope", "")),
			str(note.get("statement_consolidated", false)),
			"|".join(_string_array(note.get("metric_ids", []))),
			str(note.get("summary", ""))
		])
	lines.append("source_quarters=%s" % "|".join(_source_periods(snapshot)))
	return "\n".join(lines)


func _validate_annual_notes(annual: Dictionary) -> Dictionary:
	var note_index_ids: Array = []
	var note_index_types: Array = []
	for note_index_value in _variant_array(annual.get("note_index", [])):
		if typeof(note_index_value) == TYPE_DICTIONARY:
			note_index_ids.append(str(note_index_value.get("note_id", "")))
			note_index_types.append(str(note_index_value.get("note_type", "")))
	var note_ids: Array = []
	var note_types: Array = []
	var has_revenue_note: bool = false
	var has_debt_note: bool = false
	var has_ppe_note: bool = false
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			return _case_fail("Expected annual note rows to be dictionaries.")
		var note: Dictionary = note_value
		var note_id: String = str(note.get("note_id", "")).strip_edges()
		if note_id.is_empty():
			return _case_fail("Expected generated annual note id.")
		if not note_index_ids.has(note_id):
			return _case_fail("Generated annual note id missing from note index: %s." % note_id)
		note_ids.append(note_id)
		if str(note.get("statement_id", "")) != str(annual.get("statement_id", "")):
			return _case_fail("Expected annual note %s to preserve statement_id." % note_id)
		if str(note.get("statement_scope", "")) != "annual":
			return _case_fail("Expected annual note %s to preserve annual statement scope." % note_id)
		if not bool(note.get("statement_consolidated", false)):
			return _case_fail("Expected annual note %s to preserve consolidated flag." % note_id)
		if int(note.get("statement_year", 0)) != int(annual.get("fiscal_year", 0)):
			return _case_fail("Expected annual note %s to preserve fiscal statement year." % note_id)
		if str(note.get("statement_section", "")) != "notes":
			return _case_fail("Expected annual note %s to use notes statement section." % note_id)
		if str(note.get("summary", "")).strip_edges().is_empty():
			return _case_fail("Expected annual note %s to include deterministic summary." % note_id)
		var note_type: String = str(note.get("note_type", "")).strip_edges()
		if note_type.is_empty():
			return _case_fail("Expected annual note %s to include note_type." % note_id)
		note_types.append(note_type)
		if _variant_array(note.get("source_statement_sections", [])).is_empty():
			return _case_fail("Expected annual note %s to include source statement sections." % note_id)
		if str(note.get("visibility", "")) != "filing":
			return _case_fail("Expected annual note %s to be filing-visible." % note_id)
		if float(note.get("importance", 0.0)) <= 0.0:
			return _case_fail("Expected annual note %s to include importance." % note_id)
		var metric_ids: Array = _string_array(note.get("metric_ids", []))
		has_revenue_note = has_revenue_note or metric_ids.has("revenue")
		has_debt_note = has_debt_note or metric_ids.has("debt")
		has_ppe_note = has_ppe_note or metric_ids.has("property_plant_equipment")
	note_ids.sort()
	note_index_ids.sort()
	if _string_array(note_ids) != _string_array(note_index_ids):
		return _case_fail("Generated annual note ids do not match note index ids.")
	if _string_array(note_index_types) != _string_array(EXPECTED_NOTE_TYPES):
		return _case_fail("Annual note index types changed. expected=%s actual=%s." % [_string_array(EXPECTED_NOTE_TYPES), _string_array(note_index_types)])
	if _string_array(note_types) != _string_array(EXPECTED_NOTE_TYPES):
		return _case_fail("Generated annual note types changed. expected=%s actual=%s." % [_string_array(EXPECTED_NOTE_TYPES), _string_array(note_types)])
	if not has_revenue_note or not has_debt_note or not has_ppe_note:
		return _case_fail("Expected annual notes to cover revenue, debt, and PPE metrics.")
	return _case_ok("", "")


func _document_section_ids(annual: Dictionary) -> Array:
	var ids: Array = []
	for section_value in _variant_array(annual.get("document_sections", [])):
		if typeof(section_value) == TYPE_DICTIONARY:
			ids.append(str(section_value.get("section_id", "")))
	return ids


func _source_periods(snapshot: Dictionary) -> Array:
	var periods: Array = []
	for statement_value in _variant_array(snapshot.get("quarterly_statements", [])):
		if typeof(statement_value) == TYPE_DICTIONARY and int(statement_value.get("statement_year", 0)) == 2019:
			periods.append(str(statement_value.get("statement_period_label", "")))
	return periods


func _sum_quarter_lines(statements: Array, section_id: String, line_id: String) -> float:
	var total: float = 0.0
	for statement_value in statements:
		if typeof(statement_value) == TYPE_DICTIONARY:
			total += _line_value(statement_value, section_id, line_id)
	return total


func _line_value(statement: Dictionary, section_id: String, line_id: String) -> float:
	for line_value in _variant_array(statement.get(section_id, [])):
		if typeof(line_value) != TYPE_DICTIONARY:
			continue
		var line: Dictionary = line_value
		if str(line.get("id", "")) == line_id or str(line.get("metric_id", "")) == line_id:
			return float(line.get("value", 0.0))
	return 0.0


func _nearly_equal(left: float, right: float, tolerance: float) -> bool:
	return absf(left - right) <= tolerance


func _float_token(value: float) -> String:
	return "%.3f" % value


func _case_ok(message: String, payload: String) -> Dictionary:
	return {"success": true, "message": message, "payload": payload}


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
	print("ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_FAIL: %s" % message)
	get_tree().quit(1)
