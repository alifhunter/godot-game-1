extends RefCounted

const HISTORY_START_YEAR := 2010
const HISTORY_END_YEAR := 2019
const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")
const DEFAULT_SECTOR_PROFILE := {
	"scale": 0.50,
	"growth": 0.50,
	"margin": 0.40,
	"capital_intensity": 0.50,
	"cyclicality": 0.50,
	"liquidity": 0.45,
	"growth_drift": 0.005
}
const SECTOR_ALIASES := {
	"industry": "industrial"
}
const SECTOR_PROFILES := {
	"consumer": {
		"scale": 0.45,
		"growth": 0.56,
		"margin": 0.42,
		"capital_intensity": 0.34,
		"cyclicality": 0.34,
		"liquidity": 0.46,
		"growth_drift": 0.010
	},
	"industrial": {
		"scale": 0.58,
		"growth": 0.47,
		"margin": 0.38,
		"capital_intensity": 0.67,
		"cyclicality": 0.56,
		"liquidity": 0.48,
		"growth_drift": 0.004
	},
	"energy": {
		"scale": 0.62,
		"growth": 0.52,
		"margin": 0.47,
		"capital_intensity": 0.74,
		"cyclicality": 0.78,
		"liquidity": 0.56,
		"growth_drift": 0.006
	},
	"tech": {
		"scale": 0.40,
		"growth": 0.72,
		"margin": 0.52,
		"capital_intensity": 0.24,
		"cyclicality": 0.46,
		"liquidity": 0.48,
		"growth_drift": 0.016
	},
	"infra": {
		"scale": 0.68,
		"growth": 0.44,
		"margin": 0.36,
		"capital_intensity": 0.82,
		"cyclicality": 0.42,
		"liquidity": 0.52,
		"growth_drift": 0.006
	},
	"transport": {
		"scale": 0.46,
		"growth": 0.49,
		"margin": 0.28,
		"capital_intensity": 0.58,
		"cyclicality": 0.72,
		"liquidity": 0.43,
		"growth_drift": 0.003
	},
	"health": {
		"scale": 0.42,
		"growth": 0.63,
		"margin": 0.51,
		"capital_intensity": 0.32,
		"cyclicality": 0.22,
		"liquidity": 0.41,
		"growth_drift": 0.012
	},
	"finance": {
		"scale": 0.72,
		"growth": 0.50,
		"margin": 0.44,
		"capital_intensity": 0.18,
		"cyclicality": 0.38,
		"liquidity": 0.62,
		"growth_drift": 0.007
	},
	"basicindustry": {
		"scale": 0.55,
		"growth": 0.45,
		"margin": 0.34,
		"capital_intensity": 0.76,
		"cyclicality": 0.69,
		"liquidity": 0.44,
		"growth_drift": 0.002
	},
	"property": {
		"scale": 0.57,
		"growth": 0.43,
		"margin": 0.40,
		"capital_intensity": 0.71,
		"cyclicality": 0.74,
		"liquidity": 0.40,
		"growth_drift": 0.003
	},
	"noncyclical": {
		"scale": 0.49,
		"growth": 0.48,
		"margin": 0.45,
		"capital_intensity": 0.31,
		"cyclicality": 0.18,
		"liquidity": 0.47,
		"growth_drift": 0.008
	}
}


func generate_company_profile(template: Dictionary, sector_definition: Dictionary, run_seed: int) -> Dictionary:
	var company_id: String = str(template.get("id", "company"))
	var sector_id: String = str(sector_definition.get("id", template.get("sector_id", "")))
	var sector_profile: Dictionary = _sector_profile(sector_id)
	var traits: Dictionary = _build_traits(template, sector_profile, run_seed, company_id)
	var financial_history: Array = _build_financial_history(
		template,
		sector_profile,
		traits,
		run_seed,
		company_id
	)
	var latest_year: Dictionary = financial_history[financial_history.size() - 1].duplicate(true)
	var target_price: float = _derive_target_price(template, traits, run_seed, company_id)
	var shares_outstanding: float = _derive_shares_outstanding(float(latest_year.get("market_cap", 0.0)), target_price)
	financial_history = _apply_share_price_history(financial_history, shares_outstanding)
	latest_year = financial_history[financial_history.size() - 1].duplicate(true)

	var financials: Dictionary = _build_current_financials(financial_history, latest_year, shares_outstanding)
	var quality_score: int = _derive_quality_score(traits, financials)
	var growth_score: int = _derive_growth_score(traits, financials)
	var risk_score: int = _derive_risk_score(traits, financials)
	var base_volatility: float = _derive_base_volatility(traits, risk_score)
	var generated_base_price: float = IDX_PRICE_RULES.normalize_last_price(float(latest_year.get("implied_share_price", target_price)))

	return {
		"base_price": generated_base_price,
		"quality_score": quality_score,
		"growth_score": growth_score,
		"risk_score": risk_score,
		"base_volatility": base_volatility,
		"financials": financials,
		"financial_history": financial_history,
		"generation_traits": traits,
		"shares_outstanding": shares_outstanding
	}


func _build_traits(
	template: Dictionary,
	sector_profile: Dictionary,
	run_seed: int,
	company_id: String
) -> Dictionary:
	var rng: RandomNumberGenerator = _rng_for(run_seed, company_id, "traits")
	var narrative_tags: Array = template.get("narrative_tags", [])
	var quality_anchor: float = _anchor_ratio(template, "quality", "quality_score", 58.0)
	var growth_anchor: float = _anchor_ratio(template, "growth", "growth_score", 58.0)
	var risk_anchor: float = _anchor_ratio(template, "risk", "risk_score", 42.0)
	var free_float_anchor: float = clamp(_anchor_value(template, "free_float_pct", 28.0) / 100.0, 0.07, 0.60)
	var debt_anchor: float = clamp(_anchor_value(template, "debt_to_equity", 0.75) / 1.8, 0.0, 1.0)
	var margin_anchor: float = clamp(_anchor_value(template, "net_profit_margin", 7.5) / 20.0, 0.0, 1.0)
	var liquidity_anchor: float = clamp(
		(log(max(_anchor_value(template, "avg_daily_value", 2000000000.0), 1000000.0)) - 14.0) / 4.0,
		0.0,
		1.0
	)
	var market_cap_anchor: float = clamp(
		(log(max(_anchor_value(template, "market_cap", 1000000000000.0), 1000000000.0)) - 20.0) / 9.0,
		0.0,
		1.0
	)
	var quality_core: float = clamp(
		(quality_anchor * 0.56) +
		((1.0 - risk_anchor) * 0.22) +
		(float(sector_profile.get("margin", 0.45)) * 0.12) +
		(margin_anchor * 0.10) +
		rng.randf_range(-0.07, 0.07),
		0.08,
		0.95
	)
	var growth_engine: float = clamp(
		(growth_anchor * 0.58) +
		(float(sector_profile.get("growth", 0.5)) * 0.24) +
		(rng.randf_range(-0.08, 0.08)),
		0.08,
		0.95
	)
	var balance_sheet_strength: float = clamp(
		(quality_core * 0.36) +
		((1.0 - debt_anchor) * 0.34) +
		((1.0 - risk_anchor) * 0.18) +
		rng.randf_range(-0.07, 0.07),
		0.08,
		0.95
	)
	var margin_strength: float = clamp(
		(quality_core * 0.42) +
		(margin_anchor * 0.34) +
		(float(sector_profile.get("margin", 0.45)) * 0.16) +
		rng.randf_range(-0.08, 0.08),
		0.08,
		0.95
	)
	var capital_intensity: float = clamp(
		(float(sector_profile.get("capital_intensity", 0.5)) * 0.60) +
		(debt_anchor * 0.16) +
		rng.randf_range(-0.08, 0.08),
		0.10,
		0.95
	)
	var cyclicality: float = clamp(
		(float(sector_profile.get("cyclicality", 0.5)) * 0.60) +
		(risk_anchor * 0.24) +
		rng.randf_range(-0.08, 0.08),
		0.08,
		0.95
	)
	var liquidity_profile: float = clamp(
		(liquidity_anchor * 0.42) +
		(free_float_anchor * 0.24) +
		(float(sector_profile.get("liquidity", 0.45)) * 0.20) +
		rng.randf_range(-0.08, 0.08),
		0.08,
		0.95
	)
	var float_tightness: float = clamp(
		((1.0 - free_float_anchor) * 0.70) +
		rng.randf_range(-0.07, 0.07),
		0.05,
		0.95
	)
	var story_heat: float = clamp(
		(growth_anchor * 0.18) +
		(liquidity_profile * 0.12) +
		rng.randf_range(-0.08, 0.08),
		0.05,
		0.95
	)
	var execution_consistency: float = clamp(
		(quality_core * 0.54) +
		(balance_sheet_strength * 0.20) +
		rng.randf_range(-0.08, 0.08),
		0.08,
		0.95
	)
	var scale: float = clamp(
		(market_cap_anchor * 0.55) +
		(float(sector_profile.get("scale", 0.45)) * 0.30) +
		rng.randf_range(-0.08, 0.08),
		0.08,
		0.95
	)

	if "quiet_execution" in narrative_tags:
		execution_consistency = clamp(execution_consistency + 0.10, 0.08, 0.95)
		story_heat = clamp(story_heat - 0.05, 0.05, 0.95)
	if "stealth_interest" in narrative_tags:
		float_tightness = clamp(float_tightness + 0.12, 0.05, 0.95)
		liquidity_profile = clamp(liquidity_profile - 0.04, 0.08, 0.95)
	if "retail_favorite" in narrative_tags:
		story_heat = clamp(story_heat + 0.18, 0.05, 0.95)
		float_tightness = clamp(float_tightness + 0.06, 0.05, 0.95)
	if "narrative_hot" in narrative_tags:
		story_heat = clamp(story_heat + 0.12, 0.05, 0.95)
		growth_engine = clamp(growth_engine + 0.05, 0.08, 0.95)
	if "commodity_beta" in narrative_tags:
		cyclicality = clamp(cyclicality + 0.16, 0.08, 0.95)
		capital_intensity = clamp(capital_intensity + 0.08, 0.10, 0.95)
	if "policy_beta" in narrative_tags:
		cyclicality = clamp(cyclicality + 0.10, 0.08, 0.95)
	if "foreign_watchlist" in narrative_tags:
		liquidity_profile = clamp(liquidity_profile + 0.08, 0.08, 0.95)
	if "institution_quality" in narrative_tags:
		quality_core = clamp(quality_core + 0.10, 0.08, 0.95)
		balance_sheet_strength = clamp(balance_sheet_strength + 0.08, 0.08, 0.95)
	if "supportive_balance_sheet" in narrative_tags:
		balance_sheet_strength = clamp(balance_sheet_strength + 0.12, 0.08, 0.95)
	if "domestic_demand" in narrative_tags:
		cyclicality = clamp(cyclicality - 0.06, 0.08, 0.95)
	if "capex_cycle" in narrative_tags:
		capital_intensity = clamp(capital_intensity + 0.10, 0.10, 0.95)

	return {
		"scale": scale,
		"growth_engine": growth_engine,
		"margin_strength": margin_strength,
		"balance_sheet_strength": balance_sheet_strength,
		"capital_intensity": capital_intensity,
		"cyclicality": cyclicality,
		"liquidity_profile": liquidity_profile,
		"float_tightness": float_tightness,
		"story_heat": story_heat,
		"execution_consistency": execution_consistency
	}


func _build_financial_history(
	template: Dictionary,
	sector_profile: Dictionary,
	traits: Dictionary,
	run_seed: int,
	company_id: String
) -> Array:
	var target_market_cap: float = max(
		_anchor_value(template, "market_cap", 0.0),
		lerp(800000000000.0, 4200000000000.0, float(traits.get("scale", 0.5)))
	)
	var target_margin: float = clamp(
		_anchor_value(template, "net_profit_margin", 7.5) / 100.0,
		0.01,
		0.22
	)
	var target_free_float: float = clamp(
		_anchor_value(template, "free_float_pct", lerp(18.0, 42.0, 1.0 - float(traits.get("float_tightness", 0.5)))),
		7.0,
		60.0
	)
	var target_debt_to_equity: float = clamp(
		_anchor_value(template, "debt_to_equity", lerp(1.45, 0.22, float(traits.get("balance_sheet_strength", 0.5)))),
		0.05,
		1.8
	)
	var price_to_sales_multiple: float = clamp(
		0.55 +
		(float(traits.get("growth_engine", 0.5)) * 0.95) +
		(float(traits.get("margin_strength", 0.5)) * 0.52) +
		(float(traits.get("story_heat", 0.5)) * 0.68) -
		(float(traits.get("cyclicality", 0.5)) * 0.18),
		0.40,
		3.20
	)
	var target_revenue_2019: float = max(target_market_cap / price_to_sales_multiple, 120000000000.0)
	var expected_growth_rate: float = clamp(
		0.035 +
		(float(traits.get("growth_engine", 0.5)) * 0.11) +
		(float(traits.get("execution_consistency", 0.5)) * 0.020) -
		(float(traits.get("scale", 0.5)) * 0.018) -
		(float(traits.get("cyclicality", 0.5)) * 0.015) +
		(float(sector_profile.get("growth_drift", 0.0))),
		0.02,
		0.18
	)
	var revenue: float = target_revenue_2019 / pow(1.0 + expected_growth_rate, float(HISTORY_END_YEAR - HISTORY_START_YEAR))
	revenue *= _sample_noise(run_seed, company_id, "revenue_start", 0.90, 1.10, HISTORY_START_YEAR)
	var margin: float = clamp(
		target_margin -
		_sample_noise(run_seed, company_id, "margin_start", -0.006, 0.030, HISTORY_START_YEAR) +
		((float(traits.get("growth_engine", 0.5)) - 0.5) * 0.010) -
		((float(traits.get("capital_intensity", 0.5)) - 0.5) * 0.012),
		0.01,
		0.18
	)
	var equity: float = max(
		revenue * lerp(0.14, 0.34, float(traits.get("balance_sheet_strength", 0.5))),
		50000000000.0
	)
	var debt_to_equity: float = clamp(
		target_debt_to_equity + _sample_noise(run_seed, company_id, "de_start", -0.20, 0.20, HISTORY_START_YEAR),
		0.05,
		1.8
	)
	var free_float_pct: float = clamp(
		target_free_float + _sample_noise(run_seed, company_id, "float_start", -3.0, 3.0, HISTORY_START_YEAR),
		7.0,
		60.0
	)
	var history: Array = []
	var previous_revenue: float = revenue
	var previous_net_income: float = revenue * margin

	for year in range(HISTORY_START_YEAR, HISTORY_END_YEAR + 1):
		if year > HISTORY_START_YEAR:
			var sector_cycle: float = _sample_noise(run_seed, company_id, "sector_cycle", -1.0, 1.0, year)
			var execution_shock: float = _sample_noise(run_seed, company_id, "execution", -1.0, 1.0, year)
			var revenue_growth_rate: float = clamp(
				0.020 +
				(float(traits.get("growth_engine", 0.5)) * 0.12) +
				(float(traits.get("execution_consistency", 0.5)) * 0.020) -
				(float(traits.get("scale", 0.5)) * 0.020) -
				max(debt_to_equity - 1.1, 0.0) * 0.030 +
				sector_cycle * lerp(0.03, 0.08, float(traits.get("cyclicality", 0.5))) +
				execution_shock * 0.018 +
				float(sector_profile.get("growth_drift", 0.0)),
				-0.18,
				0.34
			)
			revenue *= 1.0 + revenue_growth_rate

			var margin_drift: float = (
				(target_margin - margin) * 0.26 +
				sector_cycle * 0.024 +
				execution_shock * 0.008 +
				((float(traits.get("margin_strength", 0.5)) - 0.5) * 0.014) -
				(float(traits.get("capital_intensity", 0.5)) * 0.006)
			)
			margin = clamp(margin + margin_drift, 0.005, 0.24)

		var net_income: float = revenue * margin
		var payout_ratio: float = clamp(
			0.12 +
			(float(traits.get("scale", 0.5)) * 0.10) +
			max(0.18 - float(traits.get("growth_engine", 0.5)) * 0.18, 0.0) +
			max(margin - 0.12, 0.0) * 0.25,
			0.08,
			0.45
		)
		equity = max(
			equity + (net_income * (1.0 - payout_ratio)),
			revenue * 0.05
		)

		var delever_target: float = clamp(
			target_debt_to_equity +
			(float(traits.get("capital_intensity", 0.5)) * 0.22) +
			(float(traits.get("cyclicality", 0.5)) * 0.12) -
			(float(traits.get("balance_sheet_strength", 0.5)) * 0.34) -
			(float(traits.get("execution_consistency", 0.5)) * 0.08),
			0.05,
			1.8
		)
		debt_to_equity = clamp(
			lerp(debt_to_equity, delever_target, 0.28) +
			_sample_noise(run_seed, company_id, "de_year", -0.05, 0.05, year),
			0.05,
			1.8
		)
		var debt: float = equity * debt_to_equity
		var roe_ratio: float = 0.0
		if equity > 0.0:
			roe_ratio = net_income / equity

		var valuation_shock: float = _sample_noise(run_seed, company_id, "valuation", -1.0, 1.0, year)
		var pe_multiple: float = clamp(
			7.0 +
			(float(traits.get("growth_engine", 0.5)) * 8.0) +
			(float(traits.get("margin_strength", 0.5)) * 4.0) +
			(float(traits.get("story_heat", 0.5)) * 6.0) +
			(float(traits.get("execution_consistency", 0.5)) * 3.0) -
			(float(traits.get("cyclicality", 0.5)) * 2.0) -
			max(debt_to_equity - 1.0, 0.0) * 4.0 +
			valuation_shock * 2.4,
			5.5,
			28.0
		)
		var sales_floor_multiple: float = clamp(
			0.42 +
			(float(traits.get("growth_engine", 0.5)) * 0.90) +
			(float(traits.get("margin_strength", 0.5)) * 0.46) +
			(float(traits.get("story_heat", 0.5)) * 0.60) -
			(float(traits.get("cyclicality", 0.5)) * 0.18) +
			valuation_shock * 0.18,
			0.35,
			3.20
		)
		var market_cap: float = max(net_income * pe_multiple, revenue * sales_floor_multiple)
		free_float_pct = clamp(
			lerp(free_float_pct, target_free_float, 0.18) +
			_sample_noise(run_seed, company_id, "free_float_year", -0.8, 0.8, year),
			7.0,
			60.0
		)
		var turnover_ratio: float = clamp(
			0.0008 +
			(float(traits.get("liquidity_profile", 0.5)) * 0.0032) +
			(float(traits.get("story_heat", 0.5)) * 0.0018) +
			((free_float_pct / 100.0) * 0.0016) +
			(absf((revenue - previous_revenue) / max(previous_revenue, 1.0)) * 0.0024),
			0.0006,
			0.0100
		)
		var avg_daily_value: float = market_cap * turnover_ratio
		var revenue_growth_yoy: float = 0.0
		if year > HISTORY_START_YEAR and previous_revenue > 0.0:
			revenue_growth_yoy = ((revenue / previous_revenue) - 1.0) * 100.0
		var earnings_growth_yoy: float = 0.0
		if year > HISTORY_START_YEAR:
			earnings_growth_yoy = _growth_percent(previous_net_income, net_income)

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
			"net_profit_margin": margin * 100.0,
			"roe": roe_ratio * 100.0,
			"debt_to_equity": debt_to_equity
		})

		previous_revenue = revenue
		previous_net_income = net_income

	return history


func _apply_share_price_history(financial_history: Array, shares_outstanding: float) -> Array:
	var adjusted_history: Array = []
	for entry_value in financial_history:
		var entry: Dictionary = entry_value.duplicate(true)
		var implied_share_price: float = 1.0
		if shares_outstanding > 0.0:
			implied_share_price = float(entry.get("market_cap", 0.0)) / shares_outstanding
		entry["shares_outstanding"] = shares_outstanding
		entry["implied_share_price"] = IDX_PRICE_RULES.normalize_last_price(max(implied_share_price, 1.0))
		adjusted_history.append(entry)
	return adjusted_history


func _build_current_financials(financial_history: Array, latest_year: Dictionary, shares_outstanding: float) -> Dictionary:
	var first_year: Dictionary = financial_history[0]
	var revenue_cagr_10y: float = _calculate_cagr(
		float(first_year.get("revenue", 0.0)),
		float(latest_year.get("revenue", 0.0)),
		max(financial_history.size() - 1, 1)
	)
	var earnings_cagr_10y: float = _calculate_cagr(
		max(float(first_year.get("net_income", 0.0)), 1.0),
		max(float(latest_year.get("net_income", 0.0)), 1.0),
		max(financial_history.size() - 1, 1)
	)
	return {
		"market_cap": float(latest_year.get("market_cap", 0.0)),
		"free_float_pct": float(latest_year.get("free_float_pct", 0.0)),
		"avg_daily_value": float(latest_year.get("avg_daily_value", 0.0)),
		"revenue_growth_yoy": float(latest_year.get("revenue_growth_yoy", 0.0)),
		"earnings_growth_yoy": float(latest_year.get("earnings_growth_yoy", 0.0)),
		"net_profit_margin": float(latest_year.get("net_profit_margin", 0.0)),
		"roe": float(latest_year.get("roe", 0.0)),
		"debt_to_equity": float(latest_year.get("debt_to_equity", 0.0)),
		"revenue": float(latest_year.get("revenue", 0.0)),
		"net_income": float(latest_year.get("net_income", 0.0)),
		"shares_outstanding": shares_outstanding,
		"revenue_cagr_10y": revenue_cagr_10y,
		"earnings_cagr_10y": earnings_cagr_10y,
		"history_start_year": int(first_year.get("year", HISTORY_START_YEAR)),
		"history_end_year": int(latest_year.get("year", HISTORY_END_YEAR)),
		"history_years": financial_history.size()
	}


func _derive_quality_score(traits: Dictionary, financials: Dictionary) -> int:
	var quality_raw: float = (
		25.0 +
		(float(financials.get("net_profit_margin", 0.0)) * 1.2) +
		(float(financials.get("roe", 0.0)) * 0.9) +
		(float(traits.get("execution_consistency", 0.5)) * 18.0) +
		(float(traits.get("balance_sheet_strength", 0.5)) * 16.0) -
		(float(financials.get("debt_to_equity", 0.0)) * 10.0)
	)
	return int(round(clamp(quality_raw, 20.0, 90.0)))


func _derive_growth_score(traits: Dictionary, financials: Dictionary) -> int:
	var growth_raw: float = (
		20.0 +
		(float(financials.get("revenue_cagr_10y", 0.0)) * 1.4) +
		(float(financials.get("earnings_cagr_10y", 0.0)) * 1.0) +
		(float(traits.get("growth_engine", 0.5)) * 18.0) +
		(float(traits.get("story_heat", 0.5)) * 6.0) -
		(float(traits.get("scale", 0.5)) * 3.0)
	)
	return int(round(clamp(growth_raw, 20.0, 92.0)))


func _derive_risk_score(traits: Dictionary, financials: Dictionary) -> int:
	var risk_raw: float = (
		18.0 +
		(float(traits.get("cyclicality", 0.5)) * 24.0) +
		(float(traits.get("capital_intensity", 0.5)) * 10.0) +
		(float(traits.get("float_tightness", 0.5)) * 12.0) +
		(float(traits.get("story_heat", 0.5)) * 10.0) +
		(float(financials.get("debt_to_equity", 0.0)) * 12.0) -
		(float(traits.get("balance_sheet_strength", 0.5)) * 10.0) -
		(float(traits.get("execution_consistency", 0.5)) * 8.0)
	)
	return int(round(clamp(risk_raw, 18.0, 88.0)))


func _derive_base_volatility(traits: Dictionary, risk_score: int) -> float:
	var base_volatility: float = (
		0.018 +
		((float(risk_score) / 100.0) * 0.018) +
		(float(traits.get("story_heat", 0.5)) * 0.006) +
		(float(traits.get("cyclicality", 0.5)) * 0.007) +
		((1.0 - float(traits.get("liquidity_profile", 0.5))) * 0.006)
	)
	return clamp(base_volatility, 0.018, 0.052)


func _derive_target_price(template: Dictionary, traits: Dictionary, run_seed: int, company_id: String) -> float:
	var anchor_price: float = max(_anchor_value(template, "base_price", 100.0, "base_price"), 50.0)
	var price_multiplier: float = _sample_noise(run_seed, company_id, "price_anchor", 0.92, 1.08, HISTORY_END_YEAR)
	var target_price: float = anchor_price * price_multiplier
	var fundamental_multiplier: float = (
		1.0 +
		((float(traits.get("story_heat", 0.5)) - 0.5) * 0.08) +
		((float(traits.get("liquidity_profile", 0.5)) - 0.5) * 0.05) -
		((float(traits.get("cyclicality", 0.5)) - 0.5) * 0.03)
	)
	target_price *= fundamental_multiplier
	return IDX_PRICE_RULES.normalize_last_price(clamp(target_price, 50.0, 500.0))


func _derive_shares_outstanding(market_cap: float, target_price: float) -> float:
	var safe_price: float = max(target_price, 1.0)
	return max(round(market_cap / safe_price), 100000000.0)


func _sector_profile(sector_id: String) -> Dictionary:
	var normalized_sector_id: String = str(SECTOR_ALIASES.get(sector_id, sector_id))
	if SECTOR_PROFILES.has(normalized_sector_id):
		return SECTOR_PROFILES[normalized_sector_id].duplicate(true)
	return DEFAULT_SECTOR_PROFILE.duplicate(true)


func _anchor_value(
	template: Dictionary,
	anchor_key: String,
	default_value: float,
	legacy_key: String = "",
	legacy_group_key: String = "financials"
) -> float:
	var anchors: Dictionary = template.get("anchors", {})
	if anchors.has(anchor_key):
		return float(anchors.get(anchor_key, default_value))

	var resolved_legacy_key: String = legacy_key
	if resolved_legacy_key.is_empty():
		resolved_legacy_key = anchor_key

	if template.has(resolved_legacy_key):
		return float(template.get(resolved_legacy_key, default_value))

	var legacy_group: Dictionary = template.get(legacy_group_key, {})
	if legacy_group.has(resolved_legacy_key):
		return float(legacy_group.get(resolved_legacy_key, default_value))

	return default_value


func _anchor_ratio(template: Dictionary, anchor_key: String, legacy_key: String, default_percent: float) -> float:
	return _anchor_value(template, anchor_key, default_percent, legacy_key) / 100.0


func _rng_for(run_seed: int, company_id: String, salt: String) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|%s|%s" % [run_seed, company_id, salt]))
	return rng


func _sample_noise(
	run_seed: int,
	company_id: String,
	salt: String,
	minimum: float,
	maximum: float,
	year: int
) -> float:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|%s|%s|%s" % [run_seed, company_id, salt, year]))
	return rng.randf_range(minimum, maximum)


func _calculate_cagr(start_value: float, end_value: float, periods: int) -> float:
	var safe_start: float = max(start_value, 1.0)
	var safe_end: float = max(end_value, 1.0)
	if periods <= 0:
		return 0.0
	return (pow(safe_end / safe_start, 1.0 / float(periods)) - 1.0) * 100.0


func _growth_percent(previous_value: float, current_value: float) -> float:
	var safe_previous: float = max(absf(previous_value), 1.0)
	return ((current_value - previous_value) / safe_previous) * 100.0
