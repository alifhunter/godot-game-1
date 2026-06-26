extends RefCounted

const SCHEMA_VERSION := 1
const SOURCE_SYSTEM_ID := "annual_consolidated_statement_builder"
const DEFAULT_CURRENCY := "IDR"
const DEFAULT_UNIT := "million_idr"
const PAGE_SIZE_HINT := "A4"
const DOCUMENT_READING_CONTRACT_SCHEMA_VERSION := 1
const DOCUMENT_READER_STATUS := "r3_1_contract_ready"
const ACCOUNTING_ROW_MODEL_SCHEMA_VERSION := 1
const ACCOUNTING_CONTINUITY_SCHEMA_VERSION := 1
const ACCOUNTING_CONTINUITY_STATUS := "r3_2_continuity_ready"
const ACCOUNTING_CONTINUITY_TOLERANCE := 0.05
const FILING_NOTE_BODY_SCHEMA_VERSION := 1
const FILING_NOTE_BODY_STATUS := "r3_3_filing_note_body_ready"
const DISCLOSURE_PACKET_RENDER_SCHEMA_VERSION := 1
const DISCLOSURE_PACKET_RENDER_STATUS := "r3_5_story_dossier_packets_consumed"

const DOCUMENT_SECTIONS := [
	{
		"section_id": "financial_position",
		"title": "Consolidated Statement of Financial Position",
		"source_array": "financial_position"
	},
	{
		"section_id": "profit_or_loss_and_oci",
		"title": "Consolidated Statement of Profit or Loss and Other Comprehensive Income",
		"source_array": "profit_or_loss_and_oci"
	},
	{
		"section_id": "changes_in_equity",
		"title": "Consolidated Statement of Changes in Equity",
		"source_array": "changes_in_equity"
	},
	{
		"section_id": "cash_flows",
		"title": "Consolidated Statement of Cash Flows",
		"source_array": "cash_flows"
	},
	{
		"section_id": "notes",
		"title": "Notes to the Consolidated Financial Statements",
		"source_array": "notes"
	}
]

const NOTE_INDEX := [
	{"note_type": "company_information", "title": "Company Information", "source_sections": ["financial_position"]},
	{"note_type": "basis_of_preparation", "title": "Basis Of Preparation", "source_sections": ["financial_position", "profit_or_loss_and_oci", "cash_flows"]},
	{"note_type": "revenue", "title": "Revenue", "source_sections": ["profit_or_loss_and_oci"]},
	{"note_type": "cost_of_revenue_and_gross_profit", "title": "Cost Of Revenue And Gross Profit", "source_sections": ["profit_or_loss_and_oci"]},
	{"note_type": "operating_expenses", "title": "Operating Expenses", "source_sections": ["profit_or_loss_and_oci"]},
	{"note_type": "segment_information", "title": "Segment Information", "source_sections": ["profit_or_loss_and_oci"]},
	{"note_type": "cash_and_cash_equivalents", "title": "Cash And Cash Equivalents", "source_sections": ["financial_position", "cash_flows"]},
	{"note_type": "trade_receivables", "title": "Trade Receivables", "source_sections": ["financial_position"]},
	{"note_type": "inventories", "title": "Inventories", "source_sections": ["financial_position"]},
	{"note_type": "property_plant_and_equipment", "title": "Property, Plant, And Equipment", "source_sections": ["financial_position", "cash_flows"]},
	{"note_type": "debt_and_borrowings", "title": "Debt And Borrowings", "source_sections": ["financial_position", "cash_flows"]},
	{"note_type": "equity_and_dividends", "title": "Equity And Dividends", "source_sections": ["financial_position", "changes_in_equity", "cash_flows"]},
	{"note_type": "cash_flow_information", "title": "Cash Flow Information", "source_sections": ["cash_flows"]},
	{"note_type": "commitments_contingencies_and_subsequent_events", "title": "Commitments, Contingencies, And Subsequent Events", "source_sections": ["notes"]}
]

const ANNUAL_REPORT_SECTION_MAP := [
	{
		"section_id": "financial_position",
		"section_number": "1",
		"title": "Consolidated Statement of Financial Position",
		"localized_title": "Laporan Posisi Keuangan Konsolidasian",
		"page_start": 1,
		"page_end": 3,
		"source_array": "financial_position",
		"read_mode": "statement_rows",
		"capture_mode": "line_item",
		"r3_status": "readable_now"
	},
	{
		"section_id": "profit_or_loss_and_oci",
		"section_number": "2",
		"title": "Consolidated Statement of Profit or Loss and Other Comprehensive Income",
		"localized_title": "Laporan Laba Rugi dan Penghasilan Komprehensif Lain Konsolidasian",
		"page_start": 4,
		"page_end": 5,
		"source_array": "profit_or_loss_and_oci",
		"read_mode": "statement_rows",
		"capture_mode": "line_item",
		"r3_status": "readable_now"
	},
	{
		"section_id": "changes_in_equity",
		"section_number": "3",
		"title": "Consolidated Statement of Changes in Equity",
		"localized_title": "Laporan Perubahan Ekuitas Konsolidasian",
		"page_start": 6,
		"page_end": 7,
		"source_array": "changes_in_equity",
		"read_mode": "statement_rows",
		"capture_mode": "line_item",
		"r3_status": "readable_now"
	},
	{
		"section_id": "cash_flows",
		"section_number": "4",
		"title": "Consolidated Statement of Cash Flows",
		"localized_title": "Laporan Arus Kas Konsolidasian",
		"page_start": 8,
		"page_end": 9,
		"source_array": "cash_flows",
		"read_mode": "statement_rows",
		"capture_mode": "line_item",
		"r3_status": "readable_now"
	},
	{
		"section_id": "notes",
		"section_number": "5",
		"title": "Notes to the Consolidated Financial Statements",
		"localized_title": "Catatan atas Laporan Keuangan Konsolidasian",
		"page_start": 10,
		"page_end": 140,
		"source_array": "notes",
		"read_mode": "filing_note_bodies",
		"capture_mode": "note_paragraph",
		"r3_status": "readable_note_bodies"
	}
]


static func build_annual_statements(
	financial_history: Array,
	quarterly_statements: Array,
	financials: Dictionary,
	traits: Dictionary,
	run_seed: int,
	company_id: String,
	sector_id: String,
	options: Dictionary = {}
) -> Array:
	if financial_history.is_empty():
		return []
	var fiscal_year: int = int(options.get("fiscal_year", _latest_financial_year(financial_history)))
	var annual_entry: Dictionary = _financial_history_entry_for_year(financial_history, fiscal_year)
	if annual_entry.is_empty():
		return []
	var previous_entry: Dictionary = _financial_history_entry_for_year(financial_history, fiscal_year - 1)
	var year_quarters: Array = _quarterly_statements_for_year(quarterly_statements, fiscal_year)
	var statement: Dictionary = build_annual_statement(
		annual_entry,
		previous_entry,
		year_quarters,
		financials,
		traits,
		run_seed,
		company_id,
		sector_id,
		options
	)
	if statement.is_empty():
		return []
	return [statement]


static func build_annual_statement(
	annual_entry: Dictionary,
	previous_entry: Dictionary,
	year_quarters: Array,
	financials: Dictionary,
	traits: Dictionary,
	run_seed: int,
	company_id: String,
	sector_id: String,
	options: Dictionary = {}
) -> Dictionary:
	var fiscal_year: int = int(annual_entry.get("year", options.get("fiscal_year", 2019)))
	if fiscal_year <= 0:
		return {}
	var comparative_year: int = int(previous_entry.get("year", fiscal_year - 1))
	var safe_company_id: String = company_id if not company_id.strip_edges().is_empty() else "unknown_company"
	var statement_id: String = "annual_statement|%s|%d|consolidated" % [safe_company_id, fiscal_year]
	var ticker: String = str(options.get("ticker", safe_company_id.to_upper()))
	var company_name: String = str(options.get("company_name", safe_company_id.to_upper()))
	var currency: String = str(options.get("currency", DEFAULT_CURRENCY))
	var unit: String = str(options.get("unit", DEFAULT_UNIT))

	var revenue: float = max(_sum_or_entry(year_quarters, "income_statement", "revenue", annual_entry.get("revenue", 0.0)), 1.0)
	var gross_profit: float = _sum_or_ratio(year_quarters, "income_statement", "gross_profit", revenue, _gross_margin_ratio(traits))
	var operating_income: float = _sum_or_ratio(year_quarters, "income_statement", "operating_income", revenue, _operating_margin_ratio(annual_entry, traits))
	var income_before_tax: float = _sum_or_ratio(year_quarters, "income_statement", "income_before_tax", revenue, _pretax_margin_ratio(annual_entry))
	var net_income: float = _sum_or_entry(year_quarters, "income_statement", "net_income", annual_entry.get("net_income", 0.0))
	var comprehensive_income: float = _sum_or_entry(year_quarters, "income_statement", "comprehensive_income", net_income)
	var owners_income: float = _sum_or_entry(year_quarters, "income_statement", "owners_income", net_income * 0.94)
	var others_income: float = _sum_or_entry(year_quarters, "income_statement", "others_income", net_income - owners_income)
	if gross_profit < operating_income:
		gross_profit = operating_income * 1.08
	if income_before_tax < net_income and net_income >= 0.0:
		income_before_tax = net_income / 0.78
	var cost_of_revenue: float = max(revenue - gross_profit, 0.0)
	var operating_expenses: float = max(gross_profit - operating_income, 0.0)
	var selling_expenses: float = operating_expenses * _selling_expense_ratio(traits)
	var general_admin_expenses: float = max(operating_expenses - selling_expenses, 0.0)
	var finance_income: float = max(revenue * (0.001 + float(traits.get("liquidity_profile", 0.5)) * 0.002), 0.0)
	var finance_cost: float = max(operating_income + finance_income - income_before_tax, 0.0)
	var tax_expense: float = max(income_before_tax - net_income, 0.0)
	var other_comprehensive_income: float = comprehensive_income - net_income

	var q4_statement: Dictionary = _latest_quarter_statement(year_quarters)
	var equity: float = max(float(annual_entry.get("equity", _line_value(q4_statement, "balance_sheet", "equity"))), revenue * 0.04)
	var debt: float = max(float(annual_entry.get("debt", 0.0)), 0.0)
	var total_liabilities: float = max(_line_value(q4_statement, "balance_sheet", "total_liabilities"), debt + max(revenue * 0.035, equity * 0.08))
	if total_liabilities < debt:
		total_liabilities = debt
	var total_assets: float = total_liabilities + equity
	var current_asset_ratio: float = _safe_ratio(
		_line_value(q4_statement, "balance_sheet", "current_assets"),
		_line_value(q4_statement, "balance_sheet", "total_assets"),
		_current_asset_ratio(traits)
	)
	var current_liability_ratio: float = _safe_ratio(
		_line_value(q4_statement, "balance_sheet", "current_liabilities"),
		_line_value(q4_statement, "balance_sheet", "total_liabilities"),
		_current_liability_ratio(traits)
	)
	var current_assets: float = total_assets * current_asset_ratio
	var non_current_assets: float = total_assets - current_assets
	var current_liabilities: float = total_liabilities * current_liability_ratio
	var non_current_liabilities: float = total_liabilities - current_liabilities

	var current_asset_split: Dictionary = _split_current_assets(current_assets, traits)
	var cash: float = float(current_asset_split.get("cash", 0.0))
	var receivables: float = float(current_asset_split.get("receivables", 0.0))
	var inventory: float = float(current_asset_split.get("inventory", 0.0))
	var other_current_assets: float = float(current_asset_split.get("other_current_assets", 0.0))
	var non_current_asset_split: Dictionary = _split_non_current_assets(non_current_assets, traits)
	var ppe: float = float(non_current_asset_split.get("ppe", 0.0))
	var right_of_use_assets: float = float(non_current_asset_split.get("right_of_use_assets", 0.0))
	var other_non_current_assets: float = float(non_current_asset_split.get("other_non_current_assets", 0.0))
	var liability_split: Dictionary = _split_liabilities(total_liabilities, current_liabilities, non_current_liabilities, debt, traits)
	var short_term_debt: float = float(liability_split.get("short_term_debt", 0.0))
	var long_term_debt: float = float(liability_split.get("long_term_debt", 0.0))
	var debt_and_borrowings: float = short_term_debt + long_term_debt
	var trade_payables: float = float(liability_split.get("trade_payables", 0.0))
	var other_current_liabilities: float = float(liability_split.get("other_current_liabilities", 0.0))
	var other_non_current_liabilities: float = float(liability_split.get("other_non_current_liabilities", 0.0))
	var share_capital: float = max(equity * clamp(0.18 + (1.0 - float(traits.get("scale", 0.5))) * 0.10, 0.12, 0.34), 0.0)
	var retained_earnings: float = max(equity - share_capital, 0.0)
	var shares_outstanding: float = max(float(annual_entry.get("shares_outstanding", financials.get("shares_outstanding", 0.0))), 0.0)

	var opening_equity: float = max(float(previous_entry.get("equity", equity - max(net_income, 0.0) * 0.62)), 0.0)
	var dividend_ratio: float = _dividend_ratio(traits, net_income)
	var dividends_declared: float = max(net_income, 0.0) * dividend_ratio
	var other_equity_movements: float = equity - (opening_equity + net_income + other_comprehensive_income - dividends_declared)

	var cash_from_operating: float = _sum_or_entry(year_quarters, "cash_flow", "cash_from_operating", net_income + max(revenue * 0.035, 0.0))
	var cash_from_investing: float = _sum_or_entry(year_quarters, "cash_flow", "cash_from_investing", -max(revenue * (0.035 + float(traits.get("capital_intensity", 0.5)) * 0.09), 0.0))
	var previous_debt: float = max(float(previous_entry.get("debt", debt_and_borrowings)), 0.0)
	var cash_from_financing: float = _sum_or_entry(year_quarters, "cash_flow", "cash_from_financing", debt_and_borrowings - previous_debt - dividends_declared)
	var net_cash_change: float = cash_from_operating + cash_from_investing + cash_from_financing
	var beginning_cash: float = max(cash - net_cash_change, cash * 0.42)
	var exchange_effect: float = cash - beginning_cash - net_cash_change
	var depreciation_and_amortization: float = max(ppe * (0.025 + float(traits.get("capital_intensity", 0.5)) * 0.025), revenue * 0.006)
	var working_capital_changes: float = _working_capital_cash_flow_adjustment(receivables, inventory, trade_payables, revenue, traits)
	var other_operating_cash_flow: float = cash_from_operating - net_income - depreciation_and_amortization - working_capital_changes
	var target_ppe_purchase: float = max(absf(cash_from_investing) * 0.82, revenue * (0.025 + float(traits.get("capital_intensity", 0.5)) * 0.05))
	var purchase_of_ppe: float = -target_ppe_purchase
	if cash_from_investing <= 0.0:
		purchase_of_ppe = -max(target_ppe_purchase, absf(cash_from_investing))
	var asset_sale_proceeds: float = cash_from_investing - purchase_of_ppe
	var debt_delta: float = debt_and_borrowings - previous_debt
	var debt_proceeds: float = max(debt_delta, 0.0)
	var debt_repayments: float = -max(-debt_delta, 0.0)
	var other_financing_cash_flow: float = cash_from_financing - debt_proceeds - debt_repayments + dividends_declared

	var profit_or_loss_and_oci: Array = [
		_line(statement_id, "profit_or_loss_and_oci", "revenue", "Revenue", revenue),
		_line(statement_id, "profit_or_loss_and_oci", "cost_of_revenue", "Cost of revenue", -cost_of_revenue),
		_line(statement_id, "profit_or_loss_and_oci", "gross_profit", "Gross profit", gross_profit),
		_line(statement_id, "profit_or_loss_and_oci", "selling_expenses", "Selling expenses", -selling_expenses),
		_line(statement_id, "profit_or_loss_and_oci", "general_admin_expenses", "General and administrative expenses", -general_admin_expenses),
		_line(statement_id, "profit_or_loss_and_oci", "operating_income", "Income from operations", operating_income),
		_line(statement_id, "profit_or_loss_and_oci", "finance_income", "Finance income", finance_income),
		_line(statement_id, "profit_or_loss_and_oci", "finance_cost", "Finance cost", -finance_cost),
		_line(statement_id, "profit_or_loss_and_oci", "income_before_tax", "Income before tax", income_before_tax),
		_line(statement_id, "profit_or_loss_and_oci", "tax_expense", "Income tax expense", -tax_expense),
		_line(statement_id, "profit_or_loss_and_oci", "net_income", "Net income for the year", net_income),
		_line(statement_id, "profit_or_loss_and_oci", "other_comprehensive_income", "Other comprehensive income", other_comprehensive_income),
		_line(statement_id, "profit_or_loss_and_oci", "comprehensive_income", "Total comprehensive income", comprehensive_income),
		_line(statement_id, "profit_or_loss_and_oci", "owners_income", "Net income attributable to owners", owners_income),
		_line(statement_id, "profit_or_loss_and_oci", "others_income", "Net income attributable to non-controlling interests", others_income),
		_line(statement_id, "profit_or_loss_and_oci", "basic_eps", "Basic earnings per share", _safe_ratio(net_income, max(shares_outstanding, 1.0), 0.0), "ratio")
	]
	var financial_position: Array = [
		_line(statement_id, "financial_position", "cash", "Cash and cash equivalents", cash),
		_line(statement_id, "financial_position", "trade_receivables", "Trade receivables", receivables),
		_line(statement_id, "financial_position", "inventories", "Inventories", inventory),
		_line(statement_id, "financial_position", "other_current_assets", "Other current assets", other_current_assets),
		_line(statement_id, "financial_position", "current_assets", "Current assets", current_assets),
		_line(statement_id, "financial_position", "property_plant_equipment", "Property, plant and equipment", ppe),
		_line(statement_id, "financial_position", "right_of_use_assets", "Right-of-use assets", right_of_use_assets),
		_line(statement_id, "financial_position", "other_non_current_assets", "Other non-current assets", other_non_current_assets),
		_line(statement_id, "financial_position", "non_current_assets", "Non-current assets", non_current_assets),
		_line(statement_id, "financial_position", "total_assets", "Total assets", total_assets),
		_line(statement_id, "financial_position", "trade_payables", "Trade payables", trade_payables),
		_line(statement_id, "financial_position", "short_term_borrowings", "Short-term borrowings", short_term_debt),
		_line(statement_id, "financial_position", "other_current_liabilities", "Other current liabilities", other_current_liabilities),
		_line(statement_id, "financial_position", "current_liabilities", "Current liabilities", current_liabilities),
		_line(statement_id, "financial_position", "long_term_borrowings", "Long-term borrowings", long_term_debt),
		_line(statement_id, "financial_position", "debt_and_borrowings", "Total debt and borrowings", debt_and_borrowings),
		_line(statement_id, "financial_position", "other_non_current_liabilities", "Other non-current liabilities", other_non_current_liabilities),
		_line(statement_id, "financial_position", "non_current_liabilities", "Non-current liabilities", non_current_liabilities),
		_line(statement_id, "financial_position", "total_liabilities", "Total liabilities", total_liabilities),
		_line(statement_id, "financial_position", "share_capital", "Share capital", share_capital),
		_line(statement_id, "financial_position", "retained_earnings", "Retained earnings", retained_earnings),
		_line(statement_id, "financial_position", "equity", "Total equity", equity),
		_line(statement_id, "financial_position", "shares_outstanding", "Shares outstanding", shares_outstanding, "shares")
	]
	var changes_in_equity: Array = [
		_line(statement_id, "changes_in_equity", "opening_equity", "Opening equity", opening_equity),
		_line(statement_id, "changes_in_equity", "profit_for_year", "Profit for the year", net_income),
		_line(statement_id, "changes_in_equity", "other_comprehensive_income", "Other comprehensive income", other_comprehensive_income),
		_line(statement_id, "changes_in_equity", "dividends_declared", "Dividends declared", -dividends_declared),
		_line(statement_id, "changes_in_equity", "other_equity_movements", "Other equity movements", other_equity_movements),
		_line(statement_id, "changes_in_equity", "closing_equity", "Closing equity", equity)
	]
	var cash_flows: Array = [
		_line(statement_id, "cash_flows", "net_income_cash_flow_anchor", "Net income", net_income),
		_line(statement_id, "cash_flows", "depreciation_and_amortization", "Depreciation and amortization", depreciation_and_amortization),
		_line(statement_id, "cash_flows", "working_capital_changes", "Changes in working capital", working_capital_changes),
		_line(statement_id, "cash_flows", "other_operating_cash_flow", "Other operating cash flow adjustments", other_operating_cash_flow),
		_line(statement_id, "cash_flows", "cash_from_operating", "Net cash from operating activities", cash_from_operating),
		_line(statement_id, "cash_flows", "purchase_of_ppe", "Purchase of property, plant and equipment", purchase_of_ppe),
		_line(statement_id, "cash_flows", "asset_sale_proceeds", "Proceeds from asset sales", asset_sale_proceeds),
		_line(statement_id, "cash_flows", "cash_from_investing", "Net cash from investing activities", cash_from_investing),
		_line(statement_id, "cash_flows", "debt_proceeds", "Proceeds from borrowings", debt_proceeds),
		_line(statement_id, "cash_flows", "debt_repayments", "Repayment of borrowings", debt_repayments),
		_line(statement_id, "cash_flows", "dividends_paid", "Dividends paid", -dividends_declared),
		_line(statement_id, "cash_flows", "other_financing_cash_flow", "Other financing cash flow", other_financing_cash_flow),
		_line(statement_id, "cash_flows", "cash_from_financing", "Net cash from financing activities", cash_from_financing),
		_line(statement_id, "cash_flows", "net_change_cash", "Net increase in cash and cash equivalents", net_cash_change),
		_line(statement_id, "cash_flows", "beginning_cash", "Cash and cash equivalents at beginning of year", beginning_cash),
		_line(statement_id, "cash_flows", "effect_of_exchange_rate", "Effect of exchange rate changes", exchange_effect),
		_line(statement_id, "cash_flows", "ending_cash", "Cash and cash equivalents at end of year", cash)
	]
	var note_index: Array = _build_note_index(statement_id, "generated")
	var note_context: Dictionary = {
		"statement_id": statement_id,
		"company_id": safe_company_id,
		"ticker": ticker,
		"company_name": company_name,
		"sector_id": sector_id,
		"fiscal_year": fiscal_year,
		"comparative_year": comparative_year,
		"statement_period_label": "FY%d" % fiscal_year,
		"currency": currency,
		"unit": unit,
		"consolidated": true,
		"revenue": revenue,
		"prior_revenue": float(previous_entry.get("revenue", 0.0)),
		"cost_of_revenue": cost_of_revenue,
		"gross_profit": gross_profit,
		"operating_expenses": operating_expenses,
		"selling_expenses": selling_expenses,
		"general_admin_expenses": general_admin_expenses,
		"operating_income": operating_income,
		"net_income": net_income,
		"cash": cash,
		"receivables": receivables,
		"inventory": inventory,
		"ppe": ppe,
		"right_of_use_assets": right_of_use_assets,
		"debt": debt_and_borrowings,
		"short_term_debt": short_term_debt,
		"long_term_debt": long_term_debt,
		"debt_and_borrowings": debt_and_borrowings,
		"finance_cost": finance_cost,
		"share_capital": share_capital,
		"retained_earnings": retained_earnings,
		"shares_outstanding": shares_outstanding,
		"dividends_declared": dividends_declared,
		"depreciation_and_amortization": depreciation_and_amortization,
		"working_capital_changes": working_capital_changes,
		"other_operating_cash_flow": other_operating_cash_flow,
		"cash_from_operating": cash_from_operating,
		"cash_from_investing": cash_from_investing,
		"cash_from_financing": cash_from_financing,
		"purchase_of_ppe": purchase_of_ppe,
		"asset_sale_proceeds": asset_sale_proceeds,
		"other_financing_cash_flow": other_financing_cash_flow,
		"ending_cash": cash
	}
	var notes: Array = _build_annual_notes(note_index, note_context, options)
	var section_lines: Dictionary = {
		"financial_position": financial_position,
		"profit_or_loss_and_oci": profit_or_loss_and_oci,
		"changes_in_equity": changes_in_equity,
		"cash_flows": cash_flows
	}
	var accounting_row_model: Array = _accounting_row_model(statement_id)
	var accounting_continuity_checks: Array = _accounting_continuity_checks(statement_id, section_lines)
	var statement: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"source_system_id": SOURCE_SYSTEM_ID,
		"statement_id": statement_id,
		"company_id": safe_company_id,
		"ticker": ticker,
		"company_name": company_name,
		"sector_id": sector_id,
		"statement_scope": "annual",
		"consolidated": true,
		"fiscal_year": fiscal_year,
		"comparative_year": comparative_year,
		"statement_year": fiscal_year,
		"statement_period_label": "FY%d" % fiscal_year,
		"report_title": "Consolidated Financial Statements",
		"page_size_hint": PAGE_SIZE_HINT,
		"currency": currency,
		"unit": unit,
		"audit_status": str(options.get("audit_status", "audited")),
		"document_sections": DOCUMENT_SECTIONS.duplicate(true),
		"document_reading_contract": _document_reading_contract(statement_id, fiscal_year, comparative_year),
		"annual_report_section_map": _annual_report_section_map(),
		"table_of_contents": _annual_report_table_of_contents(),
		"accounting_row_model": accounting_row_model,
		"accounting_continuity_checks": accounting_continuity_checks,
		"financial_position": financial_position,
		"profit_or_loss_and_oci": profit_or_loss_and_oci,
		"changes_in_equity": changes_in_equity,
		"cash_flows": cash_flows,
		"note_index": note_index,
		"notes": notes,
		"income_statement": profit_or_loss_and_oci.duplicate(true),
		"balance_sheet": financial_position.duplicate(true),
		"cash_flow": cash_flows.duplicate(true),
		"traceability": {
			"source_system_ids": ["company_financials_builder", "company_generator", SOURCE_SYSTEM_ID],
			"source_financial_years": _source_years(previous_entry, annual_entry),
			"source_quarterly_periods": _source_quarterly_periods(year_quarters),
			"generated_section_ids": _document_section_ids(),
			"generated_note_ids": _note_ids(note_index),
			"document_reading_contract_schema_version": DOCUMENT_READING_CONTRACT_SCHEMA_VERSION,
			"document_reader_status": DOCUMENT_READER_STATUS,
			"accounting_row_model_schema_version": ACCOUNTING_ROW_MODEL_SCHEMA_VERSION,
			"accounting_continuity_schema_version": ACCOUNTING_CONTINUITY_SCHEMA_VERSION,
			"accounting_continuity_status": ACCOUNTING_CONTINUITY_STATUS,
			"accounting_continuity_check_ids": _continuity_check_ids(accounting_continuity_checks),
			"accounting_continuity_failed_count": _failed_continuity_count(accounting_continuity_checks)
		}
	}
	return with_filing_note_bodies(statement)


static func with_filing_note_bodies(statement_value: Dictionary) -> Dictionary:
	var statement: Dictionary = statement_value.duplicate(true)
	var notes: Array = _variant_array(statement.get("notes", []))
	if notes.is_empty():
		return statement
	var note_lookup: Dictionary = _note_lookup_by_type(notes)
	var line_values: Dictionary = _statement_line_values(statement)
	var enriched_notes: Array = []
	for note_value in notes:
		if typeof(note_value) != TYPE_DICTIONARY:
			enriched_notes.append(note_value)
			continue
		enriched_notes.append(_annual_note_with_filing_body(note_value, note_lookup, line_values, statement))
	statement["notes"] = enriched_notes
	var traceability: Dictionary = statement.get("traceability", {}) if typeof(statement.get("traceability", {})) == TYPE_DICTIONARY else {}
	traceability = traceability.duplicate(true)
	traceability["filing_note_body_schema_version"] = FILING_NOTE_BODY_SCHEMA_VERSION
	traceability["filing_note_body_status"] = FILING_NOTE_BODY_STATUS
	traceability["filing_note_body_note_ids"] = _filing_body_note_ids(enriched_notes)
	traceability["filing_note_body_cross_reference_count"] = _filing_body_cross_reference_count(enriched_notes)
	traceability["disclosure_packet_render_schema_version"] = DISCLOSURE_PACKET_RENDER_SCHEMA_VERSION
	traceability["disclosure_packet_render_status"] = DISCLOSURE_PACKET_RENDER_STATUS
	traceability["disclosure_packet_render_packet_ids"] = _filing_body_disclosure_packet_ids(enriched_notes)
	traceability["disclosure_packet_render_story_ids"] = _filing_body_disclosure_story_ids(enriched_notes)
	traceability["disclosure_packet_render_visible_paragraph_count"] = _filing_body_disclosure_packet_paragraph_count(enriched_notes)
	statement["traceability"] = traceability
	var contract: Dictionary = statement.get("document_reading_contract", {}) if typeof(statement.get("document_reading_contract", {})) == TYPE_DICTIONARY else {}
	if not contract.is_empty():
		contract = contract.duplicate(true)
		contract["readable_section_ids"] = _string_array(_variant_array(contract.get("readable_section_ids", [])) + ["notes"])
		contract["compact_until_revision_section_ids"] = []
		var next_revisions: Dictionary = contract.get("next_revision_expectations", {}) if typeof(contract.get("next_revision_expectations", {})) == TYPE_DICTIONARY else {}
		next_revisions = next_revisions.duplicate(true)
		next_revisions["r3_3"] = "filing_note_bodies_ready"
		next_revisions["r3_5"] = "story_dossier_packets_consumed"
		contract["next_revision_expectations"] = next_revisions
		statement["document_reading_contract"] = contract
	return statement


static func _annual_note_with_filing_body(note_value: Dictionary, note_lookup: Dictionary, line_values: Dictionary, statement: Dictionary) -> Dictionary:
	var note: Dictionary = note_value.duplicate(true)
	var note_type: String = str(note.get("note_type", "")).strip_edges()
	var paragraphs: Array = _filing_note_paragraphs(note, note_lookup, line_values, statement)
	var compact_tables: Array = _filing_note_tables(note, note_lookup, line_values, statement)
	var cross_references: Array = _filing_note_cross_references(note, note_lookup)
	note["filing_note_body"] = {
		"schema_version": FILING_NOTE_BODY_SCHEMA_VERSION,
		"body_status": FILING_NOTE_BODY_STATUS,
		"body_style": "annual_report_note",
		"note_type": note_type,
		"paragraph_count": paragraphs.size(),
		"table_count": compact_tables.size(),
		"cross_reference_count": cross_references.size(),
		"disclosure_packet_count": _variant_array(note.get("disclosure_packet_refs", [])).size(),
		"disclosure_packet_paragraph_count": _paragraph_count_by_role(paragraphs, "disclosure_packet"),
		"disclosure_packet_render_schema_version": DISCLOSURE_PACKET_RENDER_SCHEMA_VERSION,
		"disclosure_packet_render_status": DISCLOSURE_PACKET_RENDER_STATUS,
		"hidden_source_ids_visible": false,
		"source_ids_stored_in_metadata_only": true
	}
	note["body_paragraphs"] = paragraphs
	note["compact_tables"] = compact_tables
	note["cross_note_references"] = cross_references
	note["visible_cross_reference_text"] = _visible_cross_reference_text(cross_references)
	note["body_text"] = _body_text_from_paragraphs(paragraphs)
	note["body_text_key"] = "%s_filing_body_r3_3" % note_type
	return note


static func _filing_note_paragraphs(note: Dictionary, note_lookup: Dictionary, line_values: Dictionary, statement: Dictionary) -> Array:
	var note_type: String = str(note.get("note_type", "")).strip_edges()
	var note_number: int = int(note.get("note_number", 0))
	var fiscal_year: int = int(statement.get("fiscal_year", 0))
	var paragraphs: Array = []
	paragraphs.append(_note_paragraph(note, 1, "basis", _filing_note_opening_sentence(note_type, fiscal_year)))
	paragraphs.append(_note_paragraph(note, 2, "measurement", _filing_note_measurement_sentence(note_type, line_values)))
	paragraphs.append_array(_filing_note_packet_paragraphs(note, line_values, paragraphs.size() + 1))
	var packet_count: int = _variant_array(note.get("disclosure_packet_refs", [])).size()
	var related_text: String = _filing_note_related_sentence(note, note_lookup, packet_count)
	if not related_text.is_empty():
		paragraphs.append(_note_paragraph(note, paragraphs.size() + 1, "cross_reference", related_text))
	var closing_text: String = _filing_note_closing_sentence(note_type, note_number)
	if not closing_text.is_empty():
		paragraphs.append(_note_paragraph(note, paragraphs.size() + 1, "filing_context", closing_text))
	return paragraphs


static func _note_paragraph(note: Dictionary, paragraph_index: int, paragraph_role: String, text: String, metadata: Dictionary = {}) -> Dictionary:
	var row: Dictionary = {
		"paragraph_id": "paragraph|%s|%02d" % [str(note.get("note_id", "")), paragraph_index],
		"paragraph_index": paragraph_index,
		"paragraph_role": paragraph_role,
		"capture_level": "note_paragraph",
		"text": text,
		"visible_to_player": true
	}
	for key_value in metadata.keys():
		var key: String = str(key_value)
		row[key] = metadata.get(key)
	return row


static func _filing_note_packet_paragraphs(note: Dictionary, line_values: Dictionary, start_index: int) -> Array:
	var rows: Array = []
	var packet_refs: Array = _sorted_disclosure_packet_refs(note.get("disclosure_packet_refs", []))
	var paragraph_index: int = start_index
	for packet_ref: Dictionary in packet_refs:
		var text: String = _disclosure_packet_visible_sentence(packet_ref, line_values)
		if text.strip_edges().is_empty():
			continue
		rows.append(_note_paragraph(
			note,
			paragraph_index,
			"disclosure_packet",
			text,
			_disclosure_packet_paragraph_metadata(packet_ref)
		))
		paragraph_index += 1
	return rows


static func _sorted_disclosure_packet_refs(source_value: Variant) -> Array:
	var rows: Array = []
	for row_value in _variant_array(source_value):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("packet_id", "")).strip_edges().is_empty():
			continue
		rows.append(row.duplicate(true))
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_priority: int = int(left.get("render_priority", 0))
		var right_priority: int = int(right.get("render_priority", 0))
		if left_priority == right_priority:
			return str(left.get("packet_id", "")) < str(right.get("packet_id", ""))
		return left_priority > right_priority
	)
	return rows


static func _disclosure_packet_paragraph_metadata(packet_ref: Dictionary) -> Dictionary:
	var packet_id: String = str(packet_ref.get("packet_id", "")).strip_edges()
	var placement_id: String = str(packet_ref.get("placement_id", "")).strip_edges()
	var story_id: String = str(packet_ref.get("story_id", "")).strip_edges()
	var section_id: String = str(packet_ref.get("section_id", "")).strip_edges()
	var metric_ids: Array = _string_array(packet_ref.get("metric_ids", []))
	var effect_ids: Array = _string_array(packet_ref.get("effect_ids", []))
	var clue_ids: Array = _string_array(packet_ref.get("clue_ids", []))
	var fact_ids: Array = _string_array(packet_ref.get("fact_ids", []))
	var metadata: Dictionary = {
		"surface_id": str(packet_ref.get("surface_id", "annual_report")).strip_edges(),
		"story_id": story_id,
		"disclosure_packet_id": packet_id,
		"disclosure_placement_id": placement_id,
		"disclosure_section_id": section_id,
		"disclosure_section_label": _disclosure_section_label(packet_ref),
		"disclosure_subtlety": str(packet_ref.get("subtlety", "implied")).strip_edges(),
		"disclosure_reader_effort": str(packet_ref.get("reader_effort", "")).strip_edges(),
		"disclosure_evidence_density": str(packet_ref.get("evidence_density", "")).strip_edges(),
		"disclosure_fragment_role": str(packet_ref.get("fragment_role", "")).strip_edges(),
		"disclosure_packet_role": str(packet_ref.get("packet_role", "")).strip_edges(),
		"metric_ids": metric_ids,
		"effect_ids": effect_ids,
		"clue_ids": clue_ids,
		"fact_ids": fact_ids,
		"source_effect_ids": effect_ids,
		"source_disclosure_packet_ids": [packet_id] if not packet_id.is_empty() else [],
		"source_disclosure_placement_ids": [placement_id] if not placement_id.is_empty() else [],
		"source_disclosure_section_ids": [section_id] if not section_id.is_empty() else [],
		"disclosure_packet_refs": [packet_ref.duplicate(true)]
	}
	if not story_id.is_empty():
		metadata["source_story_ids"] = [story_id]
	return metadata


static func _disclosure_packet_visible_sentence(packet_ref: Dictionary, line_values: Dictionary) -> String:
	var section_label: String = _disclosure_section_label(packet_ref)
	var metrics_text: String = _packet_metric_phrase(packet_ref, line_values)
	var cross_text: String = _packet_cross_reference_phrase(packet_ref)
	var subtlety: String = str(packet_ref.get("subtlety", "implied")).strip_edges()
	match subtlety:
		"direct":
			return "The %s disclosure gives a clear filing trail through %s%s." % [section_label, metrics_text, cross_text]
		"buried":
			return "The %s evidence is buried in routine movement details for %s%s." % [section_label, metrics_text, cross_text]
		"conflicting":
			return "The %s disclosure carries a conflicting signal around %s; readers should compare the related notes before relying on the narrative%s." % [section_label, metrics_text, cross_text]
		"missing":
			return "The %s section does not separately quantify the expected support for %s; that absence is part of the filing trail%s." % [section_label, metrics_text, cross_text]
		_:
			return "The %s discussion implies a filing trail through %s without isolating the driver in one statement line%s." % [section_label, metrics_text, cross_text]


static func _disclosure_section_label(packet_ref: Dictionary) -> String:
	var label: String = str(packet_ref.get("section_label", "")).strip_edges()
	if not label.is_empty():
		return label
	var section_id: String = str(packet_ref.get("section_id", "")).strip_edges()
	if section_id.is_empty():
		return "related disclosure"
	return section_id.replace("_", " ").capitalize()


static func _packet_metric_phrase(packet_ref: Dictionary, line_values: Dictionary) -> String:
	var labels: Array[String] = []
	for metric_id_value: String in _string_array(packet_ref.get("metric_ids", [])):
		var metric_id: String = str(metric_id_value)
		var display_metric_id: String = _statement_metric_for_packet_metric(metric_id)
		var amount_label: String = _metric_amount_label(line_values, display_metric_id)
		var caption: String = _metric_caption(metric_id)
		if not amount_label.is_empty():
			labels.append("%s (%s)" % [caption, amount_label])
		else:
			labels.append(caption)
		if labels.size() >= 3:
			break
	if labels.is_empty():
		return "related annual statement amounts"
	return _human_list(labels)


static func _statement_metric_for_packet_metric(metric_id: String) -> String:
	match metric_id:
		"gross_margin":
			return "gross_profit"
		"operating_margin":
			return "operating_income"
		"debt":
			return "debt_and_borrowings"
		"capex":
			return "purchase_of_ppe"
		"working_capital":
			return "trade_receivables"
		"inventory":
			return "inventories"
		"receivables":
			return "trade_receivables"
		"customer_concentration":
			return "trade_receivables"
		_:
			return metric_id


static func _packet_cross_reference_phrase(packet_ref: Dictionary) -> String:
	var section_labels: Array[String] = []
	for section_id_value: String in _string_array(packet_ref.get("cross_reference_section_ids", [])):
		var section_id: String = str(section_id_value)
		var note_type: String = _note_type_from_disclosure_section_id(section_id)
		if note_type.is_empty():
			section_labels.append(section_id.replace("_", " ").capitalize())
		else:
			section_labels.append(_metric_caption(note_type))
		if section_labels.size() >= 2:
			break
	if section_labels.is_empty():
		return ""
	return ", with cross-checks in %s" % _human_list(section_labels)


static func _human_list(values: Array[String]) -> String:
	var clean_values: Array[String] = []
	for value: String in values:
		var text: String = str(value).strip_edges()
		if not text.is_empty() and not clean_values.has(text):
			clean_values.append(text)
	if clean_values.is_empty():
		return ""
	if clean_values.size() == 1:
		return clean_values[0]
	if clean_values.size() == 2:
		return "%s and %s" % [clean_values[0], clean_values[1]]
	return "%s, and %s" % [", ".join(clean_values.slice(0, clean_values.size() - 1)), clean_values[clean_values.size() - 1]]


static func _filing_note_tables(note: Dictionary, note_lookup: Dictionary, line_values: Dictionary, statement: Dictionary) -> Array:
	var note_type: String = str(note.get("note_type", "")).strip_edges()
	var rows: Array = []
	for metric_id in _filing_note_table_metrics(note_type):
		var value_label: String = _metric_amount_label(line_values, str(metric_id))
		if value_label.is_empty():
			continue
		rows.append({
			"caption": _metric_caption(str(metric_id)),
			"fy_value": value_label,
			"related_note": _related_note_label_for_metric(str(metric_id), note_lookup)
		})
	if rows.is_empty():
		return []
	return [{
		"table_id": "table|%s|summary" % str(note.get("note_id", "")),
		"table_role": "compact_filing_summary",
		"title": _filing_note_table_title(note_type),
		"columns": ["Description", "FY amount", "Reference"],
		"rows": rows
	}]


static func _filing_note_cross_references(note: Dictionary, note_lookup: Dictionary) -> Array:
	var note_type: String = str(note.get("note_type", "")).strip_edges()
	var target_note_types: Array = []
	target_note_types = _array_with_values(target_note_types, _default_cross_reference_note_types(note_type))
	for packet_ref_value in _variant_array(note.get("disclosure_packet_refs", [])):
		if typeof(packet_ref_value) != TYPE_DICTIONARY:
			continue
		var packet_ref: Dictionary = packet_ref_value
		target_note_types = _array_with_value(target_note_types, str(packet_ref.get("annual_statement_note_type", "")))
		target_note_types = _array_with_values(target_note_types, _note_types_from_disclosure_sections(packet_ref.get("cross_reference_section_ids", [])))
	target_note_types = _string_array(target_note_types)
	var refs: Array = []
	for target_note_type_value in target_note_types:
		var target_note_type: String = str(target_note_type_value)
		if target_note_type.is_empty() or target_note_type == note_type:
			continue
		var target_note: Dictionary = note_lookup.get(target_note_type, {}) if typeof(note_lookup.get(target_note_type, {})) == TYPE_DICTIONARY else {}
		if target_note.is_empty():
			continue
		var target_number: int = int(target_note.get("note_number", 0))
		var target_title: String = str(target_note.get("title", target_note_type.replace("_", " ").capitalize()))
		refs.append({
			"target_note_type": target_note_type,
			"target_note_number": target_number,
			"target_title": target_title,
			"display_text": "See Note %d - %s." % [target_number, target_title],
			"reason": _cross_reference_reason(note_type, target_note_type)
		})
	refs.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("target_note_number", 0)) < int(right.get("target_note_number", 0))
	)
	return refs


static func _note_lookup_by_type(notes: Array) -> Dictionary:
	var lookup: Dictionary = {}
	for note_value in notes:
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		var note_type: String = str(note.get("note_type", "")).strip_edges()
		if not note_type.is_empty():
			lookup[note_type] = note.duplicate(true)
	return lookup


static func _statement_line_values(statement: Dictionary) -> Dictionary:
	var values: Dictionary = {}
	for section_id in ["financial_position", "profit_or_loss_and_oci", "changes_in_equity", "cash_flows"]:
		for line_value in _variant_array(statement.get(section_id, [])):
			if typeof(line_value) != TYPE_DICTIONARY:
				continue
			var line: Dictionary = line_value
			var metric_id: String = str(line.get("metric_id", line.get("id", ""))).strip_edges()
			if not metric_id.is_empty():
				values[metric_id] = float(line.get("value", 0.0))
	return values


static func _filing_note_opening_sentence(note_type: String, fiscal_year: int) -> String:
	match note_type:
		"company_information":
			return "This note describes the issuer, the consolidation perimeter, and the operating context used for the FY%d annual report." % fiscal_year
		"basis_of_preparation":
			return "The consolidated financial statements are prepared from the deterministic full-year financial profile and present FY%d with comparative information." % fiscal_year
		"revenue":
			return "Revenue is recognized when control of goods or services is transferred to customers and is presented net of returns and commercial allowances."
		"cost_of_revenue_and_gross_profit":
			return "Cost of revenue includes the direct cost of goods sold, service delivery, logistics, and production inputs allocated to annual sales."
		"operating_expenses":
			return "Operating expenses are grouped between selling activities and general and administrative functions to show the cost of running the issuer."
		"segment_information":
			return "Management reviews the issuer by primary operating exposure and supporting activities when assessing segment performance."
		"cash_and_cash_equivalents":
			return "Cash and cash equivalents comprise cash on hand, bank balances, and short-term placements available for operating needs."
		"trade_receivables":
			return "Trade receivables represent invoiced customer balances after deterministic allowance assumptions for collectability."
		"inventories":
			return "Inventories are carried at a simplified lower-of-cost-and-realizable-value measure based on the issuer's operating profile."
		"property_plant_and_equipment":
			return "Property, plant, and equipment includes production, logistics, office, and operating assets controlled by the issuer."
		"debt_and_borrowings":
			return "Borrowings are classified between short-term and long-term maturities based on the annual liability profile."
		"equity_and_dividends":
			return "Equity comprises issued capital, retained earnings, profit for the year, other comprehensive income, and declared distributions."
		"cash_flow_information":
			return "Cash flows are presented by operating, investing, and financing activities using a simplified annual bridge."
		"commitments_contingencies_and_subsequent_events":
			return "Commitments, contingencies, and subsequent events are disclosed when they may affect how readers interpret the annual statements."
		_:
			return "This note provides supporting information for the annual consolidated financial statements."


static func _filing_note_measurement_sentence(note_type: String, line_values: Dictionary) -> String:
	match note_type:
		"company_information":
			return "The report uses the company profile, sector exposure, and generated entity data as the source of the consolidated presentation."
		"basis_of_preparation":
			return "Amounts are stated in the report currency and unit shown in the document header; line items are rounded for gameplay readability."
		"revenue":
			return "Revenue of %s is read together with gross profit of %s and trade receivables of %s." % [_metric_amount_label(line_values, "revenue"), _metric_amount_label(line_values, "gross_profit"), _metric_amount_label(line_values, "trade_receivables")]
		"cost_of_revenue_and_gross_profit":
			return "Cost of revenue of %s produces gross profit of %s, before operating expenses of %s." % [_metric_amount_label(line_values, "cost_of_revenue"), _metric_amount_label(line_values, "gross_profit"), _metric_amount_label(line_values, "operating_income")]
		"operating_expenses":
			return "Selling expenses of %s and general and administrative expenses of %s bridge gross profit to operating income." % [_metric_amount_label(line_values, "selling_expenses"), _metric_amount_label(line_values, "general_admin_expenses")]
		"segment_information":
			return "Segment performance should be read with revenue of %s, gross profit of %s, and capital investment disclosures." % [_metric_amount_label(line_values, "revenue"), _metric_amount_label(line_values, "gross_profit")]
		"cash_and_cash_equivalents":
			return "Cash closes at %s and agrees to the ending balance in the statement of cash flows." % _metric_amount_label(line_values, "cash")
		"trade_receivables":
			return "Trade receivables of %s should be considered against annual revenue of %s." % [_metric_amount_label(line_values, "trade_receivables"), _metric_amount_label(line_values, "revenue")]
		"inventories":
			return "Inventories of %s are evaluated with cost of revenue of %s and sector operating conditions." % [_metric_amount_label(line_values, "inventories"), _metric_amount_label(line_values, "cost_of_revenue")]
		"property_plant_and_equipment":
			return "Property, plant, and equipment closes at %s after purchases of %s and related investing cash-flow movements." % [_metric_amount_label(line_values, "property_plant_equipment"), _metric_amount_label(line_values, "purchase_of_ppe")]
		"debt_and_borrowings":
			return "Debt and borrowings of %s comprise short-term borrowings of %s and long-term borrowings of %s." % [_metric_amount_label(line_values, "debt_and_borrowings"), _metric_amount_label(line_values, "short_term_borrowings"), _metric_amount_label(line_values, "long_term_borrowings")]
		"equity_and_dividends":
			return "Closing equity of %s includes retained earnings of %s and dividends declared of %s." % [_metric_amount_label(line_values, "equity"), _metric_amount_label(line_values, "retained_earnings"), _metric_amount_label(line_values, "dividends_declared")]
		"cash_flow_information":
			return "Operating cash flow of %s, investing cash flow of %s, and financing cash flow of %s reconcile to ending cash." % [_metric_amount_label(line_values, "cash_from_operating"), _metric_amount_label(line_values, "cash_from_investing"), _metric_amount_label(line_values, "cash_from_financing")]
		"commitments_contingencies_and_subsequent_events":
			return "The note is read with capital expenditure, borrowing, segment, and cash-flow disclosures when the issuer has active execution or funding signals."
		_:
			return "The note is derived from the annual statement rows and related deterministic company context."


static func _filing_note_related_sentence(note: Dictionary, note_lookup: Dictionary, packet_count: int) -> String:
	var refs: Array = _filing_note_cross_references(note, note_lookup)
	if refs.is_empty() and packet_count <= 0:
		return ""
	var prefix: String = "Related disclosures are distributed across annual report sections"
	if packet_count > 0:
		prefix = "The filing includes %d related disclosure packet(s) whose visible trail is distributed across annual report sections" % packet_count
	var labels: Array[String] = []
	for ref_value in refs.slice(0, min(refs.size(), 3)):
		if typeof(ref_value) != TYPE_DICTIONARY:
			continue
		var ref: Dictionary = ref_value
		labels.append("Note %d" % int(ref.get("target_note_number", 0)))
	if labels.is_empty():
		return "%s; source identifiers remain in capture metadata rather than visible note text." % prefix
	return "%s, including %s; source identifiers remain in capture metadata rather than visible note text." % [prefix, ", ".join(labels)]


static func _filing_note_closing_sentence(note_type: String, note_number: int) -> String:
	match note_type:
		"basis_of_preparation":
			return "No private source labels are displayed in this note."
		"commitments_contingencies_and_subsequent_events":
			return "The absence of a quantified provision should not be read as the absence of operational commitments."
		_:
			return "The amounts and references in Note %d are intended to be read together with the primary statements." % note_number


static func _filing_note_table_metrics(note_type: String) -> Array:
	match note_type:
		"revenue":
			return ["revenue", "gross_profit", "trade_receivables"]
		"cost_of_revenue_and_gross_profit":
			return ["cost_of_revenue", "gross_profit", "inventories"]
		"operating_expenses":
			return ["selling_expenses", "general_admin_expenses", "operating_income"]
		"segment_information":
			return ["revenue", "gross_profit", "property_plant_equipment"]
		"cash_and_cash_equivalents":
			return ["cash", "cash_from_operating", "ending_cash"]
		"trade_receivables":
			return ["trade_receivables", "revenue"]
		"inventories":
			return ["inventories", "cost_of_revenue"]
		"property_plant_and_equipment":
			return ["property_plant_equipment", "purchase_of_ppe", "cash_from_investing"]
		"debt_and_borrowings":
			return ["debt_and_borrowings", "short_term_borrowings", "long_term_borrowings", "finance_cost"]
		"equity_and_dividends":
			return ["share_capital", "retained_earnings", "dividends_declared", "equity"]
		"cash_flow_information":
			return ["cash_from_operating", "cash_from_investing", "cash_from_financing", "ending_cash"]
		"commitments_contingencies_and_subsequent_events":
			return ["property_plant_equipment", "debt_and_borrowings", "cash_from_investing"]
		_:
			return []


static func _filing_note_table_title(note_type: String) -> String:
	match note_type:
		"company_information":
			return "Company information summary"
		"basis_of_preparation":
			return "Preparation basis summary"
		_:
			return "Selected annual amounts"


static func _metric_caption(metric_id: String) -> String:
	return metric_id.replace("_", " ").capitalize()


static func _metric_amount_label(line_values: Dictionary, metric_id: String) -> String:
	if not line_values.has(metric_id):
		return ""
	var value: float = float(line_values.get(metric_id, 0.0))
	if metric_id == "shares_outstanding":
		return "%.0f" % value
	if metric_id == "basic_eps":
		return "%.4f" % value
	return _amount_label(value)


static func _related_note_label_for_metric(metric_id: String, note_lookup: Dictionary) -> String:
	var note_type: String = _note_type_for_metric(metric_id)
	var note: Dictionary = note_lookup.get(note_type, {}) if typeof(note_lookup.get(note_type, {})) == TYPE_DICTIONARY else {}
	if note.is_empty():
		return ""
	return "Note %d" % int(note.get("note_number", 0))


static func _note_type_for_metric(metric_id: String) -> String:
	match metric_id:
		"revenue":
			return "revenue"
		"cost_of_revenue", "gross_profit":
			return "cost_of_revenue_and_gross_profit"
		"selling_expenses", "general_admin_expenses", "operating_income":
			return "operating_expenses"
		"cash", "ending_cash":
			return "cash_and_cash_equivalents"
		"trade_receivables":
			return "trade_receivables"
		"inventories":
			return "inventories"
		"property_plant_equipment", "purchase_of_ppe":
			return "property_plant_and_equipment"
		"debt", "debt_and_borrowings", "short_term_borrowings", "long_term_borrowings", "finance_cost":
			return "debt_and_borrowings"
		"share_capital", "retained_earnings", "dividends_declared", "equity":
			return "equity_and_dividends"
		"cash_from_operating", "cash_from_investing", "cash_from_financing":
			return "cash_flow_information"
		_:
			return ""


static func _default_cross_reference_note_types(note_type: String) -> Array:
	match note_type:
		"revenue":
			return ["segment_information", "trade_receivables", "cash_flow_information"]
		"cost_of_revenue_and_gross_profit":
			return ["inventories", "segment_information", "cash_flow_information"]
		"operating_expenses":
			return ["cash_flow_information", "segment_information"]
		"segment_information":
			return ["revenue", "property_plant_and_equipment", "commitments_contingencies_and_subsequent_events"]
		"cash_and_cash_equivalents":
			return ["cash_flow_information", "debt_and_borrowings", "equity_and_dividends"]
		"trade_receivables":
			return ["revenue", "segment_information"]
		"inventories":
			return ["cost_of_revenue_and_gross_profit", "segment_information"]
		"property_plant_and_equipment":
			return ["cash_flow_information", "commitments_contingencies_and_subsequent_events", "segment_information"]
		"debt_and_borrowings":
			return ["cash_flow_information", "equity_and_dividends", "commitments_contingencies_and_subsequent_events"]
		"equity_and_dividends":
			return ["cash_flow_information", "debt_and_borrowings"]
		"cash_flow_information":
			return ["cash_and_cash_equivalents", "property_plant_and_equipment", "debt_and_borrowings", "equity_and_dividends"]
		"commitments_contingencies_and_subsequent_events":
			return ["property_plant_and_equipment", "debt_and_borrowings", "segment_information"]
		_:
			return []


static func _note_types_from_disclosure_sections(section_ids: Variant) -> Array:
	var note_types: Array = []
	for section_id_value in _variant_array(section_ids):
		note_types = _array_with_value(note_types, _note_type_from_disclosure_section_id(str(section_id_value)))
	return note_types


static func _note_type_from_disclosure_section_id(section_id: String) -> String:
	if section_id in [
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
	]:
		return section_id
	if section_id.contains("receivable"):
		return "trade_receivables"
	if section_id.contains("inventory"):
		return "inventories"
	if section_id.contains("ppe") or section_id.contains("capex") or section_id.contains("plant"):
		return "property_plant_and_equipment"
	if section_id.contains("debt") or section_id.contains("borrowing"):
		return "debt_and_borrowings"
	if section_id.contains("cash_flow") or section_id.contains("cashflow"):
		return "cash_flow_information"
	if section_id.contains("segment"):
		return "segment_information"
	if section_id.contains("revenue") or section_id.contains("customer"):
		return "revenue"
	if section_id.contains("commitment") or section_id.contains("contingenc") or section_id.contains("subsequent"):
		return "commitments_contingencies_and_subsequent_events"
	return ""


static func _cross_reference_reason(note_type: String, target_note_type: String) -> String:
	if note_type == "revenue" and target_note_type == "trade_receivables":
		return "customer balance corroboration"
	if note_type == "property_plant_and_equipment" and target_note_type == "cash_flow_information":
		return "capex cash-flow bridge"
	if note_type == "debt_and_borrowings" and target_note_type == "cash_flow_information":
		return "funding movement bridge"
	if target_note_type == "segment_information":
		return "operating exposure context"
	if target_note_type == "commitments_contingencies_and_subsequent_events":
		return "execution and subsequent-event context"
	return "related annual report disclosure"


static func _visible_cross_reference_text(cross_references: Array) -> String:
	var parts: Array[String] = []
	for ref_value in cross_references:
		if typeof(ref_value) != TYPE_DICTIONARY:
			continue
		parts.append(str(ref_value.get("display_text", "")).strip_edges())
	if parts.is_empty():
		return ""
	return " ".join(parts)


static func _body_text_from_paragraphs(paragraphs: Array) -> String:
	var texts: Array[String] = []
	for paragraph_value in paragraphs:
		if typeof(paragraph_value) != TYPE_DICTIONARY:
			continue
		var text: String = str(paragraph_value.get("text", "")).strip_edges()
		if not text.is_empty():
			texts.append(text)
	return "\n\n".join(texts)


static func _filing_body_note_ids(notes: Array) -> Array:
	var ids: Array = []
	for note_value in notes:
		if typeof(note_value) == TYPE_DICTIONARY:
			var note: Dictionary = note_value
			var body: Dictionary = note.get("filing_note_body", {}) if typeof(note.get("filing_note_body", {})) == TYPE_DICTIONARY else {}
			if int(body.get("schema_version", 0)) == FILING_NOTE_BODY_SCHEMA_VERSION:
				ids.append(str(note.get("note_id", "")))
	return _string_array(ids)


static func _filing_body_cross_reference_count(notes: Array) -> int:
	var count: int = 0
	for note_value in notes:
		if typeof(note_value) == TYPE_DICTIONARY:
			var note: Dictionary = note_value
			count += _variant_array(note.get("cross_note_references", [])).size()
	return count


static func _filing_body_disclosure_packet_ids(notes: Array) -> Array:
	var ids: Array = []
	for note_value in notes:
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		for packet_id_value: Variant in _variant_array(note.get("source_disclosure_packet_ids", [])):
			ids = _array_with_value(ids, str(packet_id_value))
	return _string_array(ids)


static func _filing_body_disclosure_story_ids(notes: Array) -> Array:
	var ids: Array = []
	for note_value in notes:
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		for story_id_value: Variant in _variant_array(note.get("source_story_ids", [])):
			ids = _array_with_value(ids, str(story_id_value))
	return _string_array(ids)


static func _filing_body_disclosure_packet_paragraph_count(notes: Array) -> int:
	var count: int = 0
	for note_value in notes:
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		count += _paragraph_count_by_role(_variant_array(note.get("body_paragraphs", [])), "disclosure_packet")
	return count


static func _paragraph_count_by_role(paragraphs: Array, paragraph_role: String) -> int:
	var count: int = 0
	for paragraph_value in paragraphs:
		if typeof(paragraph_value) != TYPE_DICTIONARY:
			continue
		var paragraph: Dictionary = paragraph_value
		if str(paragraph.get("paragraph_role", "")) == paragraph_role:
			count += 1
	return count


static func _array_with_value(source_value: Variant, next_value: String) -> Array:
	var values: Array = _variant_array(source_value)
	var text: String = next_value.strip_edges()
	if not text.is_empty() and not values.has(text):
		values.append(text)
	return values


static func _array_with_values(source_value: Variant, next_values: Variant) -> Array:
	var values: Array = _variant_array(source_value)
	for next_value in _variant_array(next_values):
		values = _array_with_value(values, str(next_value))
	return values


static func _document_reading_contract(statement_id: String, fiscal_year: int, comparative_year: int) -> Dictionary:
	return {
		"schema_version": DOCUMENT_READING_CONTRACT_SCHEMA_VERSION,
		"contract_id": "document_reading_contract|%s|r3_1" % statement_id,
		"document_reader_status": DOCUMENT_READER_STATUS,
		"page_size_hint": PAGE_SIZE_HINT,
		"statement_scope": "annual",
		"consolidated": true,
		"fiscal_year": fiscal_year,
		"comparative_year": comparative_year,
		"table_of_contents_source": "annual_report_section_map",
		"section_order": _document_section_ids_from_map(),
		"section_numbering": {
			"style": "numeric",
			"starts_at": 1,
			"visible_in_table_of_contents": true
		},
		"note_numbering": {
			"style": "numeric",
			"starts_at": 1,
			"source_array": "note_index",
			"cross_reference_prefix": "Note"
		},
		"cross_reference_behavior": {
			"enabled": true,
			"source": "disclosure_packet_refs",
			"target_fields": ["section_id", "annual_statement_note_type", "cross_reference_section_ids"],
			"visible_format": "See Note {note_number} and related sections.",
			"hidden_truth_labels_visible": false
		},
		"capture_behavior": {
			"statement_rows": {
				"enabled": true,
				"source_type": "financial_statement",
				"capture_level": "line_item",
				"preserve_fields": ["statement_id", "statement_section", "line_id", "metric_id", "statement_scope", "statement_year"]
			},
			"note_paragraphs": {
				"enabled": true,
				"source_type": "financial_statement",
				"capture_level": "note_paragraph",
				"preserve_fields": ["note_id", "note_type", "source_story_ids", "fact_ids", "effect_ids", "clue_ids", "source_disclosure_packet_ids", "disclosure_packet_refs"]
			}
		},
		"readable_section_ids": ["financial_position", "profit_or_loss_and_oci", "changes_in_equity", "cash_flows"],
		"compact_until_revision_section_ids": ["notes"],
		"next_revision_expectations": {
			"r3_2": "expand_accounting_rows_and_continuity",
			"r3_3": "build_filing_style_note_bodies",
			"r3_4": "render_document_reader_flow",
			"r3_5": "consume_story_dossier_packet_refs"
		}
	}


static func _annual_report_section_map() -> Array:
	return ANNUAL_REPORT_SECTION_MAP.duplicate(true)


static func _annual_report_table_of_contents() -> Array:
	var rows: Array = []
	for section_value in ANNUAL_REPORT_SECTION_MAP:
		var section: Dictionary = section_value
		rows.append({
			"section_id": str(section.get("section_id", "")),
			"section_number": str(section.get("section_number", "")),
			"title": str(section.get("title", "")),
			"localized_title": str(section.get("localized_title", "")),
			"page_start": int(section.get("page_start", 0)),
			"page_end": int(section.get("page_end", 0)),
			"page_label": _page_label(int(section.get("page_start", 0)), int(section.get("page_end", 0))),
			"read_mode": str(section.get("read_mode", "")),
			"capture_mode": str(section.get("capture_mode", ""))
		})
	return rows


static func _page_label(page_start: int, page_end: int) -> String:
	if page_start <= 0:
		return ""
	if page_end <= page_start:
		return str(page_start)
	return "%d-%d" % [page_start, page_end]


static func _line(statement_id: String, section_id: String, metric_id: String, label: String, value: float, format: String = "currency") -> Dictionary:
	return {
		"id": metric_id,
		"line_id": "line|%s|%s|%s" % [statement_id, section_id, metric_id],
		"section_id": section_id,
		"metric_id": metric_id,
		"label": label,
		"value": snappedf(value, 0.001),
		"format": format
	}


static func _accounting_row_model(statement_id: String) -> Array:
	var specs: Array = [
		["financial_position", "cash", "Cash and cash equivalents", "asset", "debit", "note_07", "current_asset_split"],
		["financial_position", "trade_receivables", "Trade receivables", "asset", "debit", "note_08", "current_asset_split"],
		["financial_position", "inventories", "Inventories", "asset", "debit", "note_09", "current_asset_split"],
		["financial_position", "other_current_assets", "Other current assets", "asset", "debit", "note_02", "current_asset_split"],
		["financial_position", "current_assets", "Current assets", "subtotal", "debit", "note_02", "current_asset_subtotal"],
		["financial_position", "property_plant_equipment", "Property, plant and equipment", "asset", "debit", "note_10", "non_current_asset_split"],
		["financial_position", "right_of_use_assets", "Right-of-use assets", "asset", "debit", "note_10", "non_current_asset_split"],
		["financial_position", "other_non_current_assets", "Other non-current assets", "asset", "debit", "note_02", "non_current_asset_split"],
		["financial_position", "non_current_assets", "Non-current assets", "subtotal", "debit", "note_02", "non_current_asset_subtotal"],
		["financial_position", "total_assets", "Total assets", "total", "debit", "note_02", "balance_sheet_equation"],
		["financial_position", "trade_payables", "Trade payables", "liability", "credit", "note_04", "current_liability_split"],
		["financial_position", "short_term_borrowings", "Short-term borrowings", "liability", "credit", "note_11", "debt_split"],
		["financial_position", "other_current_liabilities", "Other current liabilities", "liability", "credit", "note_02", "current_liability_split"],
		["financial_position", "current_liabilities", "Current liabilities", "subtotal", "credit", "note_02", "current_liability_subtotal"],
		["financial_position", "long_term_borrowings", "Long-term borrowings", "liability", "credit", "note_11", "debt_split"],
		["financial_position", "debt_and_borrowings", "Total debt and borrowings", "subtotal", "credit", "note_11", "debt_subtotal"],
		["financial_position", "other_non_current_liabilities", "Other non-current liabilities", "liability", "credit", "note_02", "non_current_liability_split"],
		["financial_position", "non_current_liabilities", "Non-current liabilities", "subtotal", "credit", "note_02", "non_current_liability_subtotal"],
		["financial_position", "total_liabilities", "Total liabilities", "total", "credit", "note_02", "liability_subtotal"],
		["financial_position", "share_capital", "Share capital", "equity", "credit", "note_12", "equity_split"],
		["financial_position", "retained_earnings", "Retained earnings", "equity", "credit", "note_12", "equity_split"],
		["financial_position", "equity", "Total equity", "total", "credit", "note_12", "balance_sheet_equation"],
		["financial_position", "shares_outstanding", "Shares outstanding", "share_count", "memo", "note_12", "equity_split"],
		["profit_or_loss_and_oci", "revenue", "Revenue", "income", "credit", "note_03", "gross_profit_bridge"],
		["profit_or_loss_and_oci", "cost_of_revenue", "Cost of revenue", "expense", "debit", "note_04", "gross_profit_bridge"],
		["profit_or_loss_and_oci", "gross_profit", "Gross profit", "subtotal", "credit", "note_04", "gross_profit_bridge"],
		["profit_or_loss_and_oci", "selling_expenses", "Selling expenses", "expense", "debit", "note_05", "operating_income_bridge"],
		["profit_or_loss_and_oci", "general_admin_expenses", "General and administrative expenses", "expense", "debit", "note_05", "operating_income_bridge"],
		["profit_or_loss_and_oci", "operating_income", "Income from operations", "subtotal", "credit", "note_05", "operating_income_bridge"],
		["profit_or_loss_and_oci", "finance_income", "Finance income", "income", "credit", "note_11", "pretax_bridge"],
		["profit_or_loss_and_oci", "finance_cost", "Finance cost", "expense", "debit", "note_11", "pretax_bridge"],
		["profit_or_loss_and_oci", "income_before_tax", "Income before tax", "subtotal", "credit", "note_02", "pretax_bridge"],
		["profit_or_loss_and_oci", "tax_expense", "Income tax expense", "expense", "debit", "note_02", "net_income_bridge"],
		["profit_or_loss_and_oci", "net_income", "Net income for the year", "total", "credit", "note_12", "net_income_bridge"],
		["profit_or_loss_and_oci", "other_comprehensive_income", "Other comprehensive income", "equity_movement", "mixed", "note_12", "comprehensive_income_bridge"],
		["profit_or_loss_and_oci", "comprehensive_income", "Total comprehensive income", "total", "credit", "note_12", "comprehensive_income_bridge"],
		["profit_or_loss_and_oci", "owners_income", "Net income attributable to owners", "allocation", "credit", "note_12", "profit_allocation"],
		["profit_or_loss_and_oci", "others_income", "Net income attributable to non-controlling interests", "allocation", "credit", "note_12", "profit_allocation"],
		["profit_or_loss_and_oci", "basic_eps", "Basic earnings per share", "ratio", "memo", "note_12", "per_share_metric"],
		["changes_in_equity", "opening_equity", "Opening equity", "opening_balance", "credit", "note_12", "equity_roll_forward"],
		["changes_in_equity", "profit_for_year", "Profit for the year", "equity_movement", "credit", "note_12", "equity_roll_forward"],
		["changes_in_equity", "other_comprehensive_income", "Other comprehensive income", "equity_movement", "mixed", "note_12", "equity_roll_forward"],
		["changes_in_equity", "dividends_declared", "Dividends declared", "distribution", "debit", "note_12", "equity_roll_forward"],
		["changes_in_equity", "other_equity_movements", "Other equity movements", "equity_movement", "mixed", "note_12", "equity_roll_forward"],
		["changes_in_equity", "closing_equity", "Closing equity", "closing_balance", "credit", "note_12", "equity_roll_forward"],
		["cash_flows", "net_income_cash_flow_anchor", "Net income", "operating_anchor", "credit", "note_13", "operating_cash_flow_bridge"],
		["cash_flows", "depreciation_and_amortization", "Depreciation and amortization", "non_cash_add_back", "credit", "note_10", "operating_cash_flow_bridge"],
		["cash_flows", "working_capital_changes", "Changes in working capital", "working_capital", "mixed", "note_13", "operating_cash_flow_bridge"],
		["cash_flows", "other_operating_cash_flow", "Other operating cash flow adjustments", "operating_adjustment", "mixed", "note_13", "operating_cash_flow_bridge"],
		["cash_flows", "cash_from_operating", "Net cash from operating activities", "subtotal", "mixed", "note_13", "operating_cash_flow_bridge"],
		["cash_flows", "purchase_of_ppe", "Purchase of property, plant and equipment", "investing_outflow", "debit", "note_10", "investing_cash_flow_bridge"],
		["cash_flows", "asset_sale_proceeds", "Proceeds from asset sales", "investing_inflow", "credit", "note_10", "investing_cash_flow_bridge"],
		["cash_flows", "cash_from_investing", "Net cash from investing activities", "subtotal", "mixed", "note_13", "investing_cash_flow_bridge"],
		["cash_flows", "debt_proceeds", "Proceeds from borrowings", "financing_inflow", "credit", "note_11", "financing_cash_flow_bridge"],
		["cash_flows", "debt_repayments", "Repayment of borrowings", "financing_outflow", "debit", "note_11", "financing_cash_flow_bridge"],
		["cash_flows", "dividends_paid", "Dividends paid", "financing_outflow", "debit", "note_12", "financing_cash_flow_bridge"],
		["cash_flows", "other_financing_cash_flow", "Other financing cash flow", "financing_adjustment", "mixed", "note_13", "financing_cash_flow_bridge"],
		["cash_flows", "cash_from_financing", "Net cash from financing activities", "subtotal", "mixed", "note_13", "financing_cash_flow_bridge"],
		["cash_flows", "net_change_cash", "Net increase in cash and cash equivalents", "subtotal", "mixed", "note_13", "cash_reconciliation"],
		["cash_flows", "beginning_cash", "Cash and cash equivalents at beginning of year", "opening_balance", "debit", "note_07", "cash_reconciliation"],
		["cash_flows", "effect_of_exchange_rate", "Effect of exchange rate changes", "cash_adjustment", "mixed", "note_13", "cash_reconciliation"],
		["cash_flows", "ending_cash", "Cash and cash equivalents at end of year", "total", "debit", "note_07", "cash_reconciliation"]
	]
	var rows: Array = []
	for spec_value in specs:
		var spec: Array = spec_value
		var section_id: String = str(spec[0])
		var metric_id: String = str(spec[1])
		rows.append({
			"schema_version": ACCOUNTING_ROW_MODEL_SCHEMA_VERSION,
			"row_model_id": "row_model|%s|%s|%s" % [statement_id, section_id, metric_id],
			"statement_id": statement_id,
			"section_id": section_id,
			"metric_id": metric_id,
			"label": str(spec[2]),
			"row_role": str(spec[3]),
			"normal_balance": str(spec[4]),
			"note_ref": str(spec[5]),
			"continuity_group": str(spec[6]),
			"source_rule": "deterministic_from_financial_history_quarters_and_company_traits"
		})
	return rows


static func _accounting_continuity_checks(statement_id: String, section_lines: Dictionary) -> Array:
	var financial_position: Array = _variant_array(section_lines.get("financial_position", []))
	var profit_or_loss: Array = _variant_array(section_lines.get("profit_or_loss_and_oci", []))
	var equity: Array = _variant_array(section_lines.get("changes_in_equity", []))
	var cash_flows: Array = _variant_array(section_lines.get("cash_flows", []))
	var checks: Array = []
	checks.append(_continuity_check(statement_id, "current_asset_subtotal", "financial_position", "Current assets equal cash, receivables, inventories, and other current assets.", _value_from_lines(financial_position, "current_assets"), _sum_line_values(financial_position, ["cash", "trade_receivables", "inventories", "other_current_assets"]), ["current_assets", "cash", "trade_receivables", "inventories", "other_current_assets"]))
	checks.append(_continuity_check(statement_id, "non_current_asset_subtotal", "financial_position", "Non-current assets equal PPE, right-of-use assets, and other non-current assets.", _value_from_lines(financial_position, "non_current_assets"), _sum_line_values(financial_position, ["property_plant_equipment", "right_of_use_assets", "other_non_current_assets"]), ["non_current_assets", "property_plant_equipment", "right_of_use_assets", "other_non_current_assets"]))
	checks.append(_continuity_check(statement_id, "asset_subtotal", "financial_position", "Total assets equal current and non-current assets.", _value_from_lines(financial_position, "total_assets"), _sum_line_values(financial_position, ["current_assets", "non_current_assets"]), ["total_assets", "current_assets", "non_current_assets"]))
	checks.append(_continuity_check(statement_id, "current_liability_subtotal", "financial_position", "Current liabilities equal trade payables, short-term borrowings, and other current liabilities.", _value_from_lines(financial_position, "current_liabilities"), _sum_line_values(financial_position, ["trade_payables", "short_term_borrowings", "other_current_liabilities"]), ["current_liabilities", "trade_payables", "short_term_borrowings", "other_current_liabilities"]))
	checks.append(_continuity_check(statement_id, "non_current_liability_subtotal", "financial_position", "Non-current liabilities equal long-term borrowings and other non-current liabilities.", _value_from_lines(financial_position, "non_current_liabilities"), _sum_line_values(financial_position, ["long_term_borrowings", "other_non_current_liabilities"]), ["non_current_liabilities", "long_term_borrowings", "other_non_current_liabilities"]))
	checks.append(_continuity_check(statement_id, "debt_borrowings_subtotal", "financial_position", "Total debt and borrowings equal short-term and long-term borrowings.", _value_from_lines(financial_position, "debt_and_borrowings"), _sum_line_values(financial_position, ["short_term_borrowings", "long_term_borrowings"]), ["debt_and_borrowings", "short_term_borrowings", "long_term_borrowings"]))
	checks.append(_continuity_check(statement_id, "liability_subtotal", "financial_position", "Total liabilities equal current and non-current liabilities.", _value_from_lines(financial_position, "total_liabilities"), _sum_line_values(financial_position, ["current_liabilities", "non_current_liabilities"]), ["total_liabilities", "current_liabilities", "non_current_liabilities"]))
	checks.append(_continuity_check(statement_id, "equity_subtotal", "financial_position", "Total equity equals share capital and retained earnings.", _value_from_lines(financial_position, "equity"), _sum_line_values(financial_position, ["share_capital", "retained_earnings"]), ["equity", "share_capital", "retained_earnings"]))
	checks.append(_continuity_check(statement_id, "balance_sheet_equation", "financial_position", "Total assets equal total liabilities plus total equity.", _value_from_lines(financial_position, "total_assets"), _sum_line_values(financial_position, ["total_liabilities", "equity"]), ["total_assets", "total_liabilities", "equity"]))
	checks.append(_continuity_check(statement_id, "gross_profit_bridge", "profit_or_loss_and_oci", "Gross profit equals revenue less cost of revenue.", _value_from_lines(profit_or_loss, "gross_profit"), _sum_line_values(profit_or_loss, ["revenue", "cost_of_revenue"]), ["gross_profit", "revenue", "cost_of_revenue"]))
	checks.append(_continuity_check(statement_id, "operating_income_bridge", "profit_or_loss_and_oci", "Operating income equals gross profit less operating expenses.", _value_from_lines(profit_or_loss, "operating_income"), _sum_line_values(profit_or_loss, ["gross_profit", "selling_expenses", "general_admin_expenses"]), ["operating_income", "gross_profit", "selling_expenses", "general_admin_expenses"]))
	checks.append(_continuity_check(statement_id, "pretax_income_bridge", "profit_or_loss_and_oci", "Income before tax equals operating income plus net finance result.", _value_from_lines(profit_or_loss, "income_before_tax"), _sum_line_values(profit_or_loss, ["operating_income", "finance_income", "finance_cost"]), ["income_before_tax", "operating_income", "finance_income", "finance_cost"]))
	checks.append(_continuity_check(statement_id, "net_income_bridge", "profit_or_loss_and_oci", "Net income equals income before tax less income tax expense.", _value_from_lines(profit_or_loss, "net_income"), _sum_line_values(profit_or_loss, ["income_before_tax", "tax_expense"]), ["net_income", "income_before_tax", "tax_expense"]))
	checks.append(_continuity_check(statement_id, "comprehensive_income_bridge", "profit_or_loss_and_oci", "Comprehensive income equals net income and other comprehensive income.", _value_from_lines(profit_or_loss, "comprehensive_income"), _sum_line_values(profit_or_loss, ["net_income", "other_comprehensive_income"]), ["comprehensive_income", "net_income", "other_comprehensive_income"]))
	checks.append(_continuity_check(statement_id, "equity_roll_forward", "changes_in_equity", "Closing equity rolls forward from opening equity, profit, OCI, dividends, and other movements.", _value_from_lines(equity, "closing_equity"), _sum_line_values(equity, ["opening_equity", "profit_for_year", "other_comprehensive_income", "dividends_declared", "other_equity_movements"]), ["closing_equity", "opening_equity", "profit_for_year", "other_comprehensive_income", "dividends_declared", "other_equity_movements"]))
	checks.append(_continuity_check(statement_id, "operating_cash_flow_bridge", "cash_flows", "Operating cash flow bridges net income, non-cash charges, working capital, and other operating movements.", _value_from_lines(cash_flows, "cash_from_operating"), _sum_line_values(cash_flows, ["net_income_cash_flow_anchor", "depreciation_and_amortization", "working_capital_changes", "other_operating_cash_flow"]), ["cash_from_operating", "net_income_cash_flow_anchor", "depreciation_and_amortization", "working_capital_changes", "other_operating_cash_flow"]))
	checks.append(_continuity_check(statement_id, "investing_cash_flow_bridge", "cash_flows", "Investing cash flow bridges PPE purchases and asset sale proceeds.", _value_from_lines(cash_flows, "cash_from_investing"), _sum_line_values(cash_flows, ["purchase_of_ppe", "asset_sale_proceeds"]), ["cash_from_investing", "purchase_of_ppe", "asset_sale_proceeds"]))
	checks.append(_continuity_check(statement_id, "financing_cash_flow_bridge", "cash_flows", "Financing cash flow bridges debt proceeds, repayments, dividends, and other financing movements.", _value_from_lines(cash_flows, "cash_from_financing"), _sum_line_values(cash_flows, ["debt_proceeds", "debt_repayments", "dividends_paid", "other_financing_cash_flow"]), ["cash_from_financing", "debt_proceeds", "debt_repayments", "dividends_paid", "other_financing_cash_flow"]))
	checks.append(_continuity_check(statement_id, "net_cash_change_bridge", "cash_flows", "Net cash change equals operating, investing, and financing cash flows.", _value_from_lines(cash_flows, "net_change_cash"), _sum_line_values(cash_flows, ["cash_from_operating", "cash_from_investing", "cash_from_financing"]), ["net_change_cash", "cash_from_operating", "cash_from_investing", "cash_from_financing"]))
	checks.append(_continuity_check(statement_id, "cash_reconciliation", "cash_flows", "Ending cash reconciles from beginning cash, net cash change, and exchange-rate effects.", _value_from_lines(cash_flows, "ending_cash"), _sum_line_values(cash_flows, ["beginning_cash", "net_change_cash", "effect_of_exchange_rate"]), ["ending_cash", "beginning_cash", "net_change_cash", "effect_of_exchange_rate"]))
	checks.append(_continuity_check(statement_id, "cash_matches_financial_position", "cross_statement", "Cash in the statement of financial position matches ending cash in the cash-flow statement.", _value_from_lines(financial_position, "cash"), _value_from_lines(cash_flows, "ending_cash"), ["cash", "ending_cash"]))
	checks.append(_continuity_check(statement_id, "equity_matches_financial_position", "cross_statement", "Closing equity in changes in equity matches total equity in financial position.", _value_from_lines(financial_position, "equity"), _value_from_lines(equity, "closing_equity"), ["equity", "closing_equity"]))
	return checks


static func _continuity_check(statement_id: String, check_key: String, section_id: String, assertion: String, expected_value: float, actual_value: float, metric_ids: Array) -> Dictionary:
	var variance: float = snappedf(actual_value - expected_value, 0.001)
	var passed: bool = absf(variance) <= ACCOUNTING_CONTINUITY_TOLERANCE
	return {
		"schema_version": ACCOUNTING_CONTINUITY_SCHEMA_VERSION,
		"check_id": "continuity|%s|%s" % [statement_id, check_key],
		"check_key": check_key,
		"statement_id": statement_id,
		"section_id": section_id,
		"assertion": assertion,
		"expected_value": snappedf(expected_value, 0.001),
		"actual_value": snappedf(actual_value, 0.001),
		"variance": variance,
		"tolerance": ACCOUNTING_CONTINUITY_TOLERANCE,
		"status": "passed" if passed else "attention",
		"metric_ids": _string_array(metric_ids)
	}


static func _sum_line_values(lines: Array, metric_ids: Array) -> float:
	var total: float = 0.0
	for metric_id_value in metric_ids:
		total += _value_from_lines(lines, str(metric_id_value))
	return total


static func _value_from_lines(lines: Array, metric_id: String) -> float:
	for line_value in lines:
		if typeof(line_value) != TYPE_DICTIONARY:
			continue
		var line: Dictionary = line_value
		if str(line.get("id", "")) == metric_id or str(line.get("metric_id", "")) == metric_id:
			return float(line.get("value", 0.0))
	return 0.0


static func _continuity_check_ids(checks: Array) -> Array:
	var ids: Array = []
	for check_value in checks:
		if typeof(check_value) == TYPE_DICTIONARY:
			ids.append(str(check_value.get("check_id", "")))
	return ids


static func _failed_continuity_count(checks: Array) -> int:
	var count: int = 0
	for check_value in checks:
		if typeof(check_value) == TYPE_DICTIONARY and str(check_value.get("status", "")) != "passed":
			count += 1
	return count


static func _build_note_index(statement_id: String, generation_status: String = "outline_pending") -> Array:
	var rows: Array = []
	for index in range(NOTE_INDEX.size()):
		var note_spec: Dictionary = NOTE_INDEX[index]
		var note_number: int = index + 1
		var note_type: String = str(note_spec.get("note_type", "note_%02d" % note_number))
		rows.append({
			"note_id": "annual_note|%s|%02d_%s" % [statement_id, note_number, note_type],
			"note_number": note_number,
			"note_type": note_type,
			"title": str(note_spec.get("title", "")),
			"source_statement_sections": note_spec.get("source_sections", []).duplicate(true),
			"generation_status": generation_status
		})
	return rows


static func _build_annual_notes(note_index: Array, context: Dictionary, options: Dictionary) -> Array:
	var notes: Array = []
	for note_value in note_index:
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note_index_row: Dictionary = note_value
		var note_type: String = str(note_index_row.get("note_type", "")).strip_edges()
		var summary: String = _annual_note_summary(note_type, context)
		if summary.strip_edges().is_empty():
			continue
		notes.append(_annual_note(
			note_index_row,
			context,
			summary,
			_annual_note_metric_ids(note_type),
			_annual_note_tone(note_type, context),
			_annual_note_importance(note_type, context),
			options
		))
	return notes


static func _annual_note(
	note_index_row: Dictionary,
	context: Dictionary,
	summary: String,
	metric_ids: Array,
	tone: String,
	importance: float,
	options: Dictionary
) -> Dictionary:
	var note_type: String = str(note_index_row.get("note_type", "annual_note")).strip_edges()
	var note_id: String = str(note_index_row.get("note_id", "")).strip_edges()
	var source_story_ids: Array = _string_array(options.get("source_story_ids", []))
	var source_effect_ids: Array = _string_array(options.get("source_effect_ids", []))
	var fact_ids: Array = _string_array(options.get("fact_ids", []))
	var clue_ids: Array = _string_array(options.get("clue_ids", []))
	var story_id: String = str(source_story_ids[0]) if not source_story_ids.is_empty() else ""
	var effect_id: String = str(source_effect_ids[0]) if not source_effect_ids.is_empty() else ""
	var metric_id: String = str(metric_ids[0]) if not metric_ids.is_empty() else ""
	return {
		"note_id": note_id,
		"note_number": int(note_index_row.get("note_number", 0)),
		"statement_id": str(context.get("statement_id", "")),
		"company_id": str(context.get("company_id", "")),
		"statement_scope": "annual",
		"statement_year": int(context.get("fiscal_year", 0)),
		"statement_period_label": str(context.get("statement_period_label", "")),
		"statement_section": "notes",
		"statement_section_label": "Notes to the Consolidated Financial Statements",
		"statement_consolidated": bool(context.get("consolidated", true)),
		"consolidated": bool(context.get("consolidated", true)),
		"note_type": note_type,
		"title_key": "%s_title" % note_type,
		"title": str(note_index_row.get("title", note_type.replace("_", " ").capitalize())),
		"text_key": "%s_annual_%s" % [note_type, tone],
		"summary": summary,
		"source_statement_sections": _string_array(note_index_row.get("source_statement_sections", [])),
		"metric_id": metric_id,
		"metric_ids": _string_array(metric_ids),
		"story_id": story_id,
		"effect_id": effect_id,
		"fact_id": str(fact_ids[0]) if not fact_ids.is_empty() else "",
		"clue_id": str(clue_ids[0]) if not clue_ids.is_empty() else "",
		"source_story_ids": source_story_ids,
		"source_effect_ids": source_effect_ids,
		"effect_ids": source_effect_ids,
		"fact_ids": fact_ids,
		"clue_ids": clue_ids,
		"disclosure_quality": "clear",
		"detail_level": "annual",
		"access_level": "public",
		"tone": tone,
		"visibility": "filing",
		"importance": snappedf(clamp(importance, 0.05, 1.0), 0.001),
		"contradiction": false,
		"explain_tags": _annual_note_tags(note_type)
	}


static func _annual_note_summary(note_type: String, context: Dictionary) -> String:
	var company_name: String = str(context.get("company_name", context.get("company_id", "The company"))).strip_edges()
	if company_name.is_empty():
		company_name = "The company"
	var sector_id: String = str(context.get("sector_id", "general")).replace("_", " ")
	var fiscal_year: int = int(context.get("fiscal_year", 0))
	var revenue: float = float(context.get("revenue", 0.0))
	var gross_profit: float = float(context.get("gross_profit", 0.0))
	var operating_income: float = float(context.get("operating_income", 0.0))
	var cost_of_revenue: float = float(context.get("cost_of_revenue", 0.0))
	var operating_expenses: float = float(context.get("operating_expenses", 0.0))
	var cash: float = float(context.get("cash", 0.0))
	var receivables: float = float(context.get("receivables", 0.0))
	var inventory: float = float(context.get("inventory", 0.0))
	var ppe: float = float(context.get("ppe", 0.0))
	var debt: float = float(context.get("debt", 0.0))
	var dividends: float = float(context.get("dividends_declared", 0.0))
	var cash_from_operating: float = float(context.get("cash_from_operating", 0.0))
	var cash_from_investing: float = float(context.get("cash_from_investing", 0.0))
	var cash_from_financing: float = float(context.get("cash_from_financing", 0.0))
	match note_type:
		"company_information":
			return "%s is presented as a %s issuer for FY%d, with the annual report anchored to its generated company profile and consolidated entity view." % [company_name, sector_id, fiscal_year]
		"basis_of_preparation":
			return "The FY%d consolidated financial statements are prepared in %s and displayed in %s, with comparative FY%d figures used where the run has a prior-year base." % [fiscal_year, str(context.get("currency", DEFAULT_CURRENCY)), str(context.get("unit", DEFAULT_UNIT)), int(context.get("comparative_year", fiscal_year - 1))]
		"revenue":
			return "Revenue for FY%d is %s; the note links sales quality to sector demand, generated customer mix, and the full-year statement rows rather than the selected quarterly filing." % [fiscal_year, _amount_label(revenue)]
		"cost_of_revenue_and_gross_profit":
			return "Cost of revenue is %s and gross profit is %s, implying a gross margin of %s for the annual period." % [_amount_label(cost_of_revenue), _amount_label(gross_profit), _percent_label(_safe_ratio(gross_profit, revenue, 0.0))]
		"operating_expenses":
			return "Operating expenses total %s, split deterministically between selling expense %s and general/admin expense %s before arriving at operating income of %s." % [_amount_label(operating_expenses), _amount_label(float(context.get("selling_expenses", 0.0))), _amount_label(float(context.get("general_admin_expenses", 0.0))), _amount_label(operating_income)]
		"segment_information":
			return "Segment disclosure groups the company around its %s exposure and a deterministic primary/supporting segment split for top-down comparison." % sector_id
		"cash_and_cash_equivalents":
			return "Cash and cash equivalents end FY%d at %s after operating, investing, and financing cash-flow movements." % [fiscal_year, _amount_label(cash)]
		"trade_receivables":
			return "Trade receivables are %s, giving an annual receivable-to-revenue ratio of %s and a deterministic collection-quality band." % [_amount_label(receivables), _percent_label(_safe_ratio(receivables, revenue, 0.0))]
		"inventories":
			return "Inventories are %s, with the note tying stock build and write-down risk to the company's sector and cost-of-revenue profile." % _amount_label(inventory)
		"property_plant_and_equipment":
			return "Property, plant, and equipment closes at %s; annual investing cash flow of %s is used as the simplified capex roll-forward anchor." % [_amount_label(ppe), _amount_label(cash_from_investing)]
		"debt_and_borrowings":
			return "Debt and borrowings total %s, with finance cost of %s and deterministic current/non-current maturity disclosure." % [_amount_label(debt), _amount_label(float(context.get("finance_cost", 0.0)))]
		"equity_and_dividends":
			return "Equity disclosure links share capital, retained earnings, and dividends declared of %s to the FY%d changes-in-equity roll-forward." % [_amount_label(dividends), fiscal_year]
		"cash_flow_information":
			return "Cash-flow disclosure reconciles operating cash flow %s, investing cash flow %s, and financing cash flow %s to ending cash." % [_amount_label(cash_from_operating), _amount_label(cash_from_investing), _amount_label(cash_from_financing)]
		"commitments_contingencies_and_subsequent_events":
			return "Commitments, contingencies, and subsequent events remain source-ready for story dossiers, living arcs, corporate actions, and roadmap events; no unmodeled quantified liability is added to FY%d." % fiscal_year
		_:
			return ""


static func _annual_note_metric_ids(note_type: String) -> Array:
	match note_type:
		"revenue":
			return ["revenue"]
		"cost_of_revenue_and_gross_profit":
			return ["cost_of_revenue", "gross_profit"]
		"operating_expenses":
			return ["selling_expenses", "general_admin_expenses", "operating_income"]
		"segment_information":
			return ["revenue", "gross_profit"]
		"cash_and_cash_equivalents":
			return ["cash", "ending_cash"]
		"trade_receivables":
			return ["trade_receivables", "revenue"]
		"inventories":
			return ["inventories", "cost_of_revenue"]
		"property_plant_and_equipment":
			return ["property_plant_equipment", "purchase_of_ppe"]
		"debt_and_borrowings":
			return ["debt", "short_term_borrowings", "long_term_borrowings", "finance_cost"]
		"equity_and_dividends":
			return ["share_capital", "retained_earnings", "dividends_declared"]
		"cash_flow_information":
			return ["cash_from_operating", "cash_from_investing", "cash_from_financing", "ending_cash"]
		"commitments_contingencies_and_subsequent_events":
			return ["capex", "debt"]
		_:
			return []


static func _annual_note_tone(note_type: String, context: Dictionary) -> String:
	match note_type:
		"revenue", "cash_and_cash_equivalents", "cash_flow_information":
			return "positive" if float(context.get("revenue", 0.0)) >= max(float(context.get("prior_revenue", 0.0)), 0.0) else "mixed"
		"debt_and_borrowings":
			return "watch" if float(context.get("debt", 0.0)) > max(float(context.get("revenue", 0.0)) * 0.35, 1.0) else "neutral"
		"commitments_contingencies_and_subsequent_events":
			return "watch"
		_:
			return "neutral"


static func _annual_note_importance(note_type: String, context: Dictionary) -> float:
	match note_type:
		"revenue":
			return 0.90
		"debt_and_borrowings":
			return clamp(0.45 + _safe_ratio(float(context.get("debt", 0.0)), max(float(context.get("revenue", 0.0)), 1.0), 0.0), 0.45, 0.92)
		"cash_flow_information":
			return 0.82
		"commitments_contingencies_and_subsequent_events":
			return 0.64
		_:
			return 0.55


static func _annual_note_tags(note_type: String) -> Array:
	var tags: Array = ["annual_report", "consolidated", note_type]
	match note_type:
		"revenue", "segment_information":
			tags.append("top_down_revenue")
		"debt_and_borrowings":
			tags.append("balance_sheet_risk")
		"cash_flow_information":
			tags.append("cash_conversion")
		"commitments_contingencies_and_subsequent_events":
			tags.append("story_ready")
	return tags


static func _working_capital_cash_flow_adjustment(receivables: float, inventory: float, trade_payables: float, revenue: float, traits: Dictionary) -> float:
	var cyclicality: float = clamp(float(traits.get("cyclicality", 0.5)), 0.0, 1.0)
	var liquidity: float = clamp(float(traits.get("liquidity_profile", 0.5)), 0.0, 1.0)
	var working_capital_base: float = (trade_payables - receivables - inventory) * (0.035 + cyclicality * 0.035)
	var liquidity_release: float = revenue * max(liquidity - 0.55, 0.0) * 0.018
	return clamp(working_capital_base + liquidity_release, -revenue * 0.12, revenue * 0.08)


static func _split_current_assets(current_assets: float, traits: Dictionary) -> Dictionary:
	var liquidity: float = clamp(float(traits.get("liquidity_profile", 0.5)), 0.0, 1.0)
	var capital_intensity: float = clamp(float(traits.get("capital_intensity", 0.5)), 0.0, 1.0)
	var cyclicality: float = clamp(float(traits.get("cyclicality", 0.5)), 0.0, 1.0)
	var scale: float = clamp(float(traits.get("scale", 0.5)), 0.0, 1.0)
	var cash_ratio: float = clamp(0.10 + liquidity * 0.27 - capital_intensity * 0.04, 0.08, 0.42)
	var receivable_ratio: float = clamp(0.18 + scale * 0.06 + cyclicality * 0.03, 0.12, 0.36)
	var inventory_ratio: float = clamp(0.12 + capital_intensity * 0.10 + cyclicality * 0.06 - liquidity * 0.03, 0.05, 0.34)
	var ratio_total: float = cash_ratio + receivable_ratio + inventory_ratio
	if ratio_total > 0.88:
		var scale_down: float = 0.88 / ratio_total
		cash_ratio *= scale_down
		receivable_ratio *= scale_down
		inventory_ratio *= scale_down
	var cash: float = current_assets * cash_ratio
	var receivables: float = current_assets * receivable_ratio
	var inventory: float = current_assets * inventory_ratio
	return {
		"cash": cash,
		"receivables": receivables,
		"inventory": inventory,
		"other_current_assets": max(current_assets - cash - receivables - inventory, 0.0)
	}


static func _split_non_current_assets(non_current_assets: float, traits: Dictionary) -> Dictionary:
	var capital_intensity: float = clamp(float(traits.get("capital_intensity", 0.5)), 0.0, 1.0)
	var scale: float = clamp(float(traits.get("scale", 0.5)), 0.0, 1.0)
	var ppe_ratio: float = clamp(0.42 + capital_intensity * 0.36 + scale * 0.04, 0.30, 0.84)
	var right_of_use_ratio: float = clamp(0.04 + capital_intensity * 0.07, 0.03, 0.14)
	if ppe_ratio + right_of_use_ratio > 0.90:
		right_of_use_ratio = max(0.90 - ppe_ratio, 0.02)
	var ppe: float = non_current_assets * ppe_ratio
	var right_of_use_assets: float = non_current_assets * right_of_use_ratio
	return {
		"ppe": ppe,
		"right_of_use_assets": right_of_use_assets,
		"other_non_current_assets": max(non_current_assets - ppe - right_of_use_assets, 0.0)
	}


static func _split_liabilities(total_liabilities: float, current_liabilities: float, non_current_liabilities: float, debt: float, traits: Dictionary) -> Dictionary:
	var balance_strength: float = clamp(float(traits.get("balance_sheet_strength", 0.5)), 0.0, 1.0)
	var cyclicality: float = clamp(float(traits.get("cyclicality", 0.5)), 0.0, 1.0)
	var short_debt_ratio: float = clamp(0.24 + (1.0 - balance_strength) * 0.22 + cyclicality * 0.08, 0.18, 0.58)
	var current_debt_capacity: float = max(current_liabilities * 0.92, 0.0)
	var non_current_debt_capacity: float = max(non_current_liabilities * 0.95, 0.0)
	var allocatable_debt: float = min(max(debt, 0.0), current_debt_capacity + non_current_debt_capacity)
	var short_term_debt: float = min(allocatable_debt * short_debt_ratio, current_debt_capacity)
	var long_term_debt: float = min(max(allocatable_debt - short_term_debt, 0.0), non_current_debt_capacity)
	if short_term_debt + long_term_debt < allocatable_debt:
		short_term_debt = min(current_debt_capacity, allocatable_debt - long_term_debt)
	if short_term_debt + long_term_debt < allocatable_debt:
		long_term_debt = min(non_current_debt_capacity, allocatable_debt - short_term_debt)
	var current_residual: float = max(current_liabilities - short_term_debt, 0.0)
	var trade_payables: float = min(current_liabilities * clamp(0.24 + cyclicality * 0.12, 0.20, 0.42), current_residual)
	return {
		"short_term_debt": short_term_debt,
		"long_term_debt": long_term_debt,
		"trade_payables": trade_payables,
		"other_current_liabilities": max(current_liabilities - short_term_debt - trade_payables, 0.0),
		"other_non_current_liabilities": max(non_current_liabilities - long_term_debt, 0.0),
		"total_liabilities": total_liabilities
	}


static func _sum_or_entry(quarterly_statements: Array, section_id: String, metric_id: String, fallback_value: Variant) -> float:
	if _quarters_have_line(quarterly_statements, section_id, metric_id):
		return _sum_statement_entries(quarterly_statements, section_id, metric_id)
	return float(fallback_value)


static func _sum_or_ratio(quarterly_statements: Array, section_id: String, metric_id: String, basis: float, fallback_ratio: float) -> float:
	if _quarters_have_line(quarterly_statements, section_id, metric_id):
		return _sum_statement_entries(quarterly_statements, section_id, metric_id)
	return basis * fallback_ratio


static func _quarters_have_line(quarterly_statements: Array, section_id: String, metric_id: String) -> bool:
	for statement_value in quarterly_statements:
		if typeof(statement_value) != TYPE_DICTIONARY:
			continue
		var statement: Dictionary = statement_value
		for line_value in _variant_array(statement.get(section_id, [])):
			if typeof(line_value) != TYPE_DICTIONARY:
				continue
			var line: Dictionary = line_value
			if str(line.get("id", "")) == metric_id or str(line.get("metric_id", "")) == metric_id:
				return true
	return false


static func _sum_statement_entries(quarterly_statements: Array, section_id: String, metric_id: String) -> float:
	var total: float = 0.0
	for statement_value in quarterly_statements:
		if typeof(statement_value) != TYPE_DICTIONARY:
			continue
		total += _line_value(statement_value, section_id, metric_id)
	return total


static func _line_value(statement: Dictionary, section_id: String, metric_id: String) -> float:
	for line_value in _variant_array(statement.get(section_id, [])):
		if typeof(line_value) != TYPE_DICTIONARY:
			continue
		var line: Dictionary = line_value
		if str(line.get("id", "")) == metric_id or str(line.get("metric_id", "")) == metric_id:
			return float(line.get("value", 0.0))
	return 0.0


static func _latest_quarter_statement(quarterly_statements: Array) -> Dictionary:
	var latest: Dictionary = {}
	var latest_sort_value: int = -1
	for statement_value in quarterly_statements:
		if typeof(statement_value) != TYPE_DICTIONARY:
			continue
		var statement: Dictionary = statement_value
		var sort_value: int = int(statement.get("statement_year", 0)) * 10 + int(statement.get("statement_quarter", 0))
		if sort_value > latest_sort_value:
			latest_sort_value = sort_value
			latest = statement.duplicate(true)
	return latest


static func _quarterly_statements_for_year(quarterly_statements: Array, fiscal_year: int) -> Array:
	var rows: Array = []
	for statement_value in quarterly_statements:
		if typeof(statement_value) != TYPE_DICTIONARY:
			continue
		var statement: Dictionary = statement_value
		if int(statement.get("statement_year", 0)) == fiscal_year:
			rows.append(statement.duplicate(true))
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("statement_quarter", 0)) < int(right.get("statement_quarter", 0))
	)
	return rows


static func _financial_history_entry_for_year(financial_history: Array, year_value: int) -> Dictionary:
	for entry_value in financial_history:
		if typeof(entry_value) == TYPE_DICTIONARY and int(entry_value.get("year", 0)) == year_value:
			return entry_value.duplicate(true)
	return {}


static func _latest_financial_year(financial_history: Array) -> int:
	var latest_year: int = 0
	for entry_value in financial_history:
		if typeof(entry_value) == TYPE_DICTIONARY:
			latest_year = max(latest_year, int(entry_value.get("year", 0)))
	return latest_year


static func _current_asset_ratio(traits: Dictionary) -> float:
	return clamp(
		0.32 +
		float(traits.get("liquidity_profile", 0.5)) * 0.18 +
		float(traits.get("balance_sheet_strength", 0.5)) * 0.06 -
		float(traits.get("capital_intensity", 0.5)) * 0.10,
		0.18,
		0.72
	)


static func _current_liability_ratio(traits: Dictionary) -> float:
	return clamp(
		0.40 +
		float(traits.get("capital_intensity", 0.5)) * 0.12 -
		float(traits.get("balance_sheet_strength", 0.5)) * 0.07,
		0.24,
		0.74
	)


static func _gross_margin_ratio(traits: Dictionary) -> float:
	return clamp(0.18 + float(traits.get("margin_strength", 0.5)) * 0.28 - float(traits.get("capital_intensity", 0.5)) * 0.04, 0.10, 0.72)


static func _operating_margin_ratio(annual_entry: Dictionary, traits: Dictionary) -> float:
	var revenue: float = max(float(annual_entry.get("revenue", 0.0)), 1.0)
	var net_margin: float = float(annual_entry.get("net_income", 0.0)) / revenue
	return clamp(net_margin + 0.03 + float(traits.get("balance_sheet_strength", 0.5)) * 0.02, -0.20, 0.42)


static func _pretax_margin_ratio(annual_entry: Dictionary) -> float:
	var revenue: float = max(float(annual_entry.get("revenue", 0.0)), 1.0)
	var net_margin: float = float(annual_entry.get("net_income", 0.0)) / revenue
	if net_margin >= 0.0:
		return clamp(net_margin / 0.78, 0.0, 0.46)
	return clamp(net_margin * 0.92, -0.30, 0.0)


static func _selling_expense_ratio(traits: Dictionary) -> float:
	return clamp(0.42 + float(traits.get("scale", 0.5)) * 0.08 - float(traits.get("capital_intensity", 0.5)) * 0.10, 0.28, 0.64)


static func _dividend_ratio(traits: Dictionary, net_income: float) -> float:
	if net_income <= 0.0:
		return 0.0
	return clamp(
		0.05 +
		float(traits.get("balance_sheet_strength", 0.5)) * 0.14 +
		float(traits.get("scale", 0.5)) * 0.08 -
		float(traits.get("growth_engine", 0.5)) * 0.14,
		0.0,
		0.30
	)


static func _safe_ratio(numerator: float, denominator: float, fallback_value: float) -> float:
	if absf(denominator) <= 0.0001:
		return fallback_value
	return numerator / denominator


static func _source_years(previous_entry: Dictionary, annual_entry: Dictionary) -> Array:
	var years: Array = []
	if not previous_entry.is_empty():
		years.append(int(previous_entry.get("year", 0)))
	years.append(int(annual_entry.get("year", 0)))
	return years


static func _source_quarterly_periods(quarterly_statements: Array) -> Array:
	var periods: Array = []
	for statement_value in quarterly_statements:
		if typeof(statement_value) == TYPE_DICTIONARY:
			periods.append(str(statement_value.get("statement_period_label", "")))
	return periods


static func _document_section_ids() -> Array:
	var ids: Array = []
	for section in DOCUMENT_SECTIONS:
		ids.append(str(section.get("section_id", "")))
	return ids


static func _document_section_ids_from_map() -> Array:
	var ids: Array = []
	for section in ANNUAL_REPORT_SECTION_MAP:
		ids.append(str(section.get("section_id", "")))
	return ids


static func _note_ids(note_index: Array) -> Array:
	var ids: Array = []
	for note_value in note_index:
		if typeof(note_value) == TYPE_DICTIONARY:
			ids.append(str(note_value.get("note_id", "")))
	return ids


static func _amount_label(value: float) -> String:
	var sign: String = "-" if value < 0.0 else ""
	var amount: float = absf(value)
	if amount >= 1000000000000.0:
		return "%sRp%.2fT" % [sign, amount / 1000000000000.0]
	if amount >= 1000000000.0:
		return "%sRp%.2fB" % [sign, amount / 1000000000.0]
	if amount >= 1000000.0:
		return "%sRp%.2fM" % [sign, amount / 1000000.0]
	if amount >= 1000.0:
		return "%sRp%.2fK" % [sign, amount / 1000.0]
	return "%sRp%.2f" % [sign, amount]


static func _percent_label(ratio: float) -> String:
	return "%.1f%%" % (ratio * 100.0)


static func _string_array(source_value: Variant) -> Array:
	var result: Array = []
	for item_value in _variant_array(source_value):
		var text: String = str(item_value).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	result.sort()
	return result


static func _variant_array(source_value: Variant) -> Array:
	if typeof(source_value) == TYPE_ARRAY:
		return source_value.duplicate(true)
	return []
