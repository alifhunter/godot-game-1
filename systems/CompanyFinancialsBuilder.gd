extends RefCounted

const ANNUAL_STATEMENT_BUILDER = preload("res://systems/AnnualStatementBuilder.gd")

const HISTORY_START_YEAR := 2010
const HISTORY_END_YEAR := 2019
const FINANCIAL_PERCENT_SCALE := 100.0
const FINANCIAL_MARGIN_MIN := 0.005
const FINANCIAL_MARGIN_MAX := 0.24
const FINANCIAL_RETAINED_EQUITY_FLOOR_RATIO := 0.05
const FINANCIAL_DELEVER_MIN := 0.05
const FINANCIAL_DELEVER_MAX := 1.8
const FINANCIAL_DELEVER_BLEND_WEIGHT := 0.28
const FINANCIAL_FREE_FLOAT_BLEND_WEIGHT := 0.18


static func build_history(
	source,
	template: Dictionary,
	sector_profile: Dictionary,
	traits: Dictionary,
	run_seed: int,
	company_id: String
) -> Array:
	var target_market_cap: float = float(source.call("_financial_target_market_cap", template, traits))
	var scale_market_cap_floor: float = float(source.call("_anchor_value", template, "scale_market_cap_floor", 0.0))
	var scale_market_cap_ceiling: float = float(source.call("_anchor_value", template, "scale_market_cap_ceiling", 0.0))
	var target_margin: float = float(source.call("_financial_target_margin", template))
	var target_free_float: float = float(source.call("_financial_target_free_float", template, traits))
	var target_debt_to_equity: float = float(source.call("_financial_target_debt_to_equity", template, traits))
	var price_to_sales_multiple: float = float(source.call("_financial_price_to_sales_multiple", traits))
	var minimum_revenue_floor: float = float(source.call("_financial_minimum_revenue_floor", target_market_cap))
	var target_revenue_2019: float = max(target_market_cap / price_to_sales_multiple, minimum_revenue_floor)
	var expected_growth_rate: float = float(source.call("_financial_expected_growth_rate", traits, sector_profile))
	var revenue: float = target_revenue_2019 / pow(1.0 + expected_growth_rate, float(HISTORY_END_YEAR - HISTORY_START_YEAR))
	revenue *= float(source.call("_sample_noise", run_seed, company_id, "revenue_start", 0.90, 1.10, HISTORY_START_YEAR))
	var margin: float = float(source.call("_financial_initial_margin", target_margin, traits, run_seed, company_id))
	var equity: float = float(source.call("_financial_initial_equity", revenue, traits))
	var debt_to_equity: float = clamp(
		target_debt_to_equity + float(source.call("_sample_noise", run_seed, company_id, "de_start", -0.20, 0.20, HISTORY_START_YEAR)),
		FINANCIAL_DELEVER_MIN,
		FINANCIAL_DELEVER_MAX
	)
	var free_float_pct: float = clamp(
		target_free_float + float(source.call("_sample_noise", run_seed, company_id, "float_start", -3.0, 3.0, HISTORY_START_YEAR)),
		7.0,
		60.0
	)
	var history: Array = []
	var previous_revenue: float = revenue
	var previous_net_income: float = revenue * margin

	for year in range(HISTORY_START_YEAR, HISTORY_END_YEAR + 1):
		if year > HISTORY_START_YEAR:
			var sector_cycle: float = float(source.call("_sample_noise", run_seed, company_id, "sector_cycle", -1.0, 1.0, year))
			var execution_shock: float = float(source.call("_sample_noise", run_seed, company_id, "execution", -1.0, 1.0, year))
			var revenue_growth_rate: float = float(source.call(
				"_financial_revenue_growth_rate",
				traits,
				sector_profile,
				debt_to_equity,
				sector_cycle,
				execution_shock
			))
			revenue *= 1.0 + revenue_growth_rate

			var margin_drift: float = float(source.call("_financial_margin_drift", target_margin, margin, traits, sector_cycle, execution_shock))
			margin = clamp(margin + margin_drift, FINANCIAL_MARGIN_MIN, FINANCIAL_MARGIN_MAX)

		var net_income: float = revenue * margin
		var payout_ratio: float = float(source.call("_financial_payout_ratio", traits, margin))
		equity = max(
			equity + (net_income * (1.0 - payout_ratio)),
			revenue * FINANCIAL_RETAINED_EQUITY_FLOOR_RATIO
		)

		var delever_target: float = float(source.call("_financial_delever_target", target_debt_to_equity, traits))
		debt_to_equity = clamp(
			lerp(debt_to_equity, delever_target, FINANCIAL_DELEVER_BLEND_WEIGHT) +
			float(source.call("_sample_noise", run_seed, company_id, "de_year", -0.05, 0.05, year)),
			FINANCIAL_DELEVER_MIN,
			FINANCIAL_DELEVER_MAX
		)
		var debt: float = equity * debt_to_equity
		var roe_ratio: float = 0.0
		if equity > 0.0:
			roe_ratio = net_income / equity

		var valuation_shock: float = float(source.call("_sample_noise", run_seed, company_id, "valuation", -1.0, 1.0, year))
		var pe_multiple: float = float(source.call("_financial_pe_multiple", traits, debt_to_equity, valuation_shock))
		var sales_floor_multiple: float = float(source.call("_financial_sales_floor_multiple", traits, valuation_shock))
		var market_cap: float = max(net_income * pe_multiple, revenue * sales_floor_multiple)
		if (
			year == HISTORY_END_YEAR and
			scale_market_cap_floor > 0.0 and
			scale_market_cap_ceiling >= scale_market_cap_floor
		):
			market_cap = clamp(market_cap, scale_market_cap_floor, scale_market_cap_ceiling)
		free_float_pct = clamp(
			lerp(free_float_pct, target_free_float, FINANCIAL_FREE_FLOAT_BLEND_WEIGHT) +
			float(source.call("_sample_noise", run_seed, company_id, "free_float_year", -0.8, 0.8, year)),
			7.0,
			60.0
		)
		var turnover_ratio: float = float(source.call("_financial_turnover_ratio", traits, free_float_pct, revenue, previous_revenue))
		var avg_daily_value: float = market_cap * turnover_ratio
		var revenue_growth_yoy: float = 0.0
		if year > HISTORY_START_YEAR and previous_revenue > 0.0:
			revenue_growth_yoy = ((revenue / previous_revenue) - 1.0) * FINANCIAL_PERCENT_SCALE
		var earnings_growth_yoy: float = 0.0
		if year > HISTORY_START_YEAR:
			earnings_growth_yoy = float(source.call("_growth_percent", previous_net_income, net_income))

		history.append({
			"year": year,
			"revenue": revenue,
			"net_income": net_income,
			"equity": equity,
			"debt": debt,
			"market_cap": market_cap,
			"free_float_pct": free_float_pct,
			"avg_daily_value": avg_daily_value,
			"revenue_growth_yoy": revenue_growth_yoy,
			"earnings_growth_yoy": earnings_growth_yoy,
			"net_profit_margin": margin * FINANCIAL_PERCENT_SCALE,
			"roe": roe_ratio * FINANCIAL_PERCENT_SCALE,
			"debt_to_equity": debt_to_equity
		})

		previous_revenue = revenue
		previous_net_income = net_income

	return history


static func build_statement_snapshot(
	source,
	financial_history: Array,
	financials: Dictionary,
	traits: Dictionary,
	run_seed: int,
	company_id: String,
	sector_id: String
) -> Dictionary:
	if financial_history.is_empty():
		return {}

	var quarterly_statements: Array = source.call(
		"_build_quarterly_statement_history",
		financial_history,
		traits,
		run_seed,
		company_id,
		sector_id,
		float(financials.get("shares_outstanding", 0.0))
	)
	if quarterly_statements.is_empty():
		return {}

	var latest_statement: Dictionary = quarterly_statements[quarterly_statements.size() - 1].duplicate(true)
	var first_statement: Dictionary = quarterly_statements[0]
	var annual_statements: Array = ANNUAL_STATEMENT_BUILDER.build_annual_statements(
		financial_history,
		quarterly_statements,
		financials,
		traits,
		run_seed,
		company_id,
		sector_id,
		{
			"fiscal_year": HISTORY_END_YEAR,
			"currency": "IDR",
			"unit": "million_idr",
			"audit_status": "audited"
		}
	)
	var annual_statement: Dictionary = annual_statements[annual_statements.size() - 1].duplicate(true) if not annual_statements.is_empty() else {}
	var snapshot: Dictionary = {
		"statement_year": int(latest_statement.get("statement_year", HISTORY_END_YEAR)),
		"statement_quarter": int(latest_statement.get("statement_quarter", 4)),
		"statement_period_label": str(latest_statement.get("statement_period_label", "Q4 %d" % HISTORY_END_YEAR)),
		"statement_scope": "quarterly",
		"quarterly_statement_count": quarterly_statements.size(),
		"history_start_period_label": str(first_statement.get("statement_period_label", "Q1 %d" % HISTORY_START_YEAR)),
		"history_end_period_label": str(latest_statement.get("statement_period_label", "Q4 %d" % HISTORY_END_YEAR)),
		"income_statement": latest_statement.get("income_statement", []).duplicate(true),
		"balance_sheet": latest_statement.get("balance_sheet", []).duplicate(true),
		"cash_flow": latest_statement.get("cash_flow", []).duplicate(true),
		"quarterly_statements": quarterly_statements
	}
	if not annual_statement.is_empty():
		snapshot["annual_statement_year"] = int(annual_statement.get("fiscal_year", HISTORY_END_YEAR))
		snapshot["annual_statement_period_label"] = str(annual_statement.get("statement_period_label", "FY%d" % HISTORY_END_YEAR))
		snapshot["annual_statement_count"] = annual_statements.size()
		snapshot["annual_statement"] = annual_statement
		snapshot["annual_statements"] = annual_statements
	return snapshot
