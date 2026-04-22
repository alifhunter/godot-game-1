extends RefCounted

const HISTORY_START_YEAR := 2010
const HISTORY_END_YEAR := 2019
const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")
const COMPANY_NARRATIVE_GENERATOR = preload("res://systems/CompanyNarrativeGenerator.gd")
const DEFAULT_SECTOR_PROFILE := {
	"scale": 0.50,
	"growth": 0.50,
	"margin": 0.40,
	"capital_intensity": 0.50,
	"cyclicality": 0.50,
	"liquidity": 0.45,
	"growth_drift": 0.005
}

var company_narrative_generator = COMPANY_NARRATIVE_GENERATOR.new()
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
const DEFAULT_QUARTER_WEIGHTS := [0.23, 0.24, 0.25, 0.28]
const MANAGEMENT_ROLES := [
	{"id": "ceo", "label": "CEO"},
	{"id": "cfo", "label": "CFO"},
	{"id": "commissioner", "label": "Commissioner"}
]
const QUARTER_WEIGHT_PROFILES := {
	"consumer": [0.21, 0.24, 0.25, 0.30],
	"industrial": [0.23, 0.25, 0.26, 0.26],
	"energy": [0.24, 0.25, 0.26, 0.25],
	"tech": [0.21, 0.24, 0.25, 0.30],
	"infra": [0.24, 0.24, 0.25, 0.27],
	"transport": [0.22, 0.25, 0.27, 0.26],
	"health": [0.24, 0.25, 0.25, 0.26],
	"finance": [0.24, 0.25, 0.25, 0.26],
	"basicindustry": [0.24, 0.25, 0.26, 0.25],
	"property": [0.20, 0.22, 0.26, 0.32],
	"noncyclical": [0.24, 0.25, 0.25, 0.26]
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
	var shares_outstanding: float = _derive_shares_outstanding(float(latest_year.get("market_cap", 0.0)), target_price, template)
	financial_history = _apply_share_price_history(financial_history, shares_outstanding)
	latest_year = financial_history[financial_history.size() - 1].duplicate(true)

	var financials: Dictionary = _build_current_financials(financial_history, latest_year, shares_outstanding)
	var quality_score: int = _derive_quality_score(traits, financials)
	var growth_score: int = _derive_growth_score(traits, financials)
	var risk_score: int = _derive_risk_score(traits, financials)
	var base_volatility: float = _derive_base_volatility(traits, risk_score)
	var generated_base_price: float = IDX_PRICE_RULES.normalize_last_price(float(latest_year.get("implied_share_price", target_price)))
	var generated_profile: Dictionary = {
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
	generated_profile["financial_statement_snapshot"] = build_financial_statement_snapshot_from_profile(
		generated_profile,
		sector_id,
		run_seed,
		company_id
	)
	var narrative_profile: Dictionary = company_narrative_generator.build_profile(
		template,
		sector_definition,
		financials,
		run_seed,
		company_id
	)
	for narrative_key_value in narrative_profile.keys():
		generated_profile[str(narrative_key_value)] = narrative_profile[narrative_key_value]
	generated_profile["management_roster"] = build_management_roster(
		template,
		sector_definition,
		run_seed
	)
	return generated_profile


func build_management_roster(template: Dictionary, sector_definition: Dictionary, run_seed: int) -> Array:
	var network_data: Dictionary = DataRepository.get_contact_network_data()
	var company_id: String = str(template.get("id", "company"))
	var company_name: String = str(template.get("name", company_id.to_upper()))
	var sector_id: String = str(sector_definition.get("id", template.get("sector_id", "")))
	var roster: Array = []
	for role_value in MANAGEMENT_ROLES:
		var role: Dictionary = role_value
		var role_id: String = str(role.get("id", ""))
		var template_contact: Dictionary = _pick_management_template(network_data, role_id, sector_id, run_seed, company_id)
		roster.append(_build_management_contact(
			template_contact,
			network_data,
			company_id,
			company_name,
			sector_id,
			role,
			run_seed
		))
	return roster


func build_financial_statement_snapshot_from_profile(
	company_profile: Dictionary,
	sector_id: String,
	run_seed: int,
	company_id: String
) -> Dictionary:
	var financial_history: Array = company_profile.get("financial_history", []).duplicate(true)
	var financials: Dictionary = company_profile.get("financials", {}).duplicate(true)
	var traits: Dictionary = company_profile.get("generation_traits", {}).duplicate(true)
	return _build_financial_statement_snapshot(
		financial_history,
		financials,
		traits,
		run_seed,
		company_id,
		sector_id
	)


func build_historical_chart_bars(
	company_profile: Dictionary,
	trade_dates: Array,
	end_price: float,
	run_seed: int,
	company_id: String
) -> Array:
	if trade_dates.is_empty():
		return []

	var financial_history: Array = company_profile.get("financial_history", []).duplicate(true)
	var statement_snapshot: Dictionary = company_profile.get("financial_statement_snapshot", {}).duplicate(true)
	var traits: Dictionary = company_profile.get("generation_traits", {}).duplicate(true)
	if financial_history.is_empty() or statement_snapshot.is_empty():
		return []

	var annual_by_year: Dictionary = {}
	for annual_entry_value in financial_history:
		var annual_entry: Dictionary = annual_entry_value.duplicate(true)
		annual_by_year[int(annual_entry.get("year", 0))] = annual_entry

	var quarterly_by_key: Dictionary = {}
	for statement_value in statement_snapshot.get("quarterly_statements", []):
		var statement: Dictionary = statement_value.duplicate(true)
		quarterly_by_key[_quarter_key(
			int(statement.get("statement_year", 0)),
			int(statement.get("statement_quarter", 0))
		)] = statement

	var quarter_trade_dates: Dictionary = _group_trade_dates_by_quarter(trade_dates)
	if quarter_trade_dates.is_empty():
		return []

	var processed_years: Array = []
	for trade_date_value in trade_dates:
		var trade_date: Dictionary = trade_date_value
		var trade_year: int = int(trade_date.get("year", HISTORY_END_YEAR))
		if processed_years.has(trade_year):
			continue
		processed_years.append(trade_year)

	var year_end_price_map: Dictionary = _build_historical_year_end_price_map(
		processed_years,
		annual_by_year,
		traits,
		run_seed,
		company_id,
		end_price
	)
	var previous_year_end_price: float = _historical_year_start_price(
		int(processed_years[0]),
		annual_by_year,
		float(year_end_price_map.get(int(processed_years[0]), end_price))
	)
	var previous_quarter_end_price: float = previous_year_end_price
	var bars: Array = []

	for year_value in processed_years:
		var year: int = int(year_value)
		var annual_entry: Dictionary = annual_by_year.get(year, annual_by_year.get(year - 1, {})).duplicate(true)
		var year_end_price: float = max(float(year_end_price_map.get(year, previous_year_end_price)), 1.0)

		var quarter_end_prices: Array = _build_historical_year_quarter_end_prices(
			year,
			previous_year_end_price,
			year_end_price,
			quarterly_by_key,
			traits,
			run_seed,
			company_id
		)
		for quarter in range(1, 5):
			var quarter_key: String = _quarter_key(year, quarter)
			if quarter_trade_dates.has(quarter_key):
				var quarter_bars: Array = _build_historical_quarter_bars(
					quarter_trade_dates[quarter_key],
					previous_quarter_end_price,
					float(quarter_end_prices[quarter - 1]),
					annual_entry,
					quarterly_by_key.get(quarter_key, {}).duplicate(true),
					traits,
					run_seed,
					company_id,
					year,
					quarter
				)
				bars.append_array(quarter_bars)
			previous_quarter_end_price = float(quarter_end_prices[quarter - 1])
		previous_year_end_price = year_end_price

	return bars


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
	var owner_concentration_anchor: float = clamp(
		_anchor_value(template, "owner_concentration_pct", 100.0 - _anchor_value(template, "free_float_pct", 28.0)) / 100.0,
		0.25,
		0.95
	)
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
		((1.0 - owner_concentration_anchor) * 0.08) +
		rng.randf_range(-0.08, 0.08),
		0.08,
		0.95
	)
	var float_tightness: float = clamp(
		((1.0 - free_float_anchor) * 0.54) +
		(owner_concentration_anchor * 0.18) +
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


func _build_financial_statement_snapshot(
	financial_history: Array,
	financials: Dictionary,
	traits: Dictionary,
	run_seed: int,
	company_id: String,
	sector_id: String
) -> Dictionary:
	if financial_history.is_empty():
		return {}

	var quarterly_statements: Array = _build_quarterly_statement_history(
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
	return {
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


func _build_quarterly_statement_history(
	financial_history: Array,
	traits: Dictionary,
	run_seed: int,
	company_id: String,
	sector_id: String,
	default_shares_outstanding: float
) -> Array:
	var normalized_sector_id: String = str(SECTOR_ALIASES.get(sector_id, sector_id))
	var statements: Array = []
	var previous_year_end_equity: float = 0.0
	var previous_year_end_debt: float = 0.0
	var previous_quarter_revenue: float = 0.0

	for history_index in range(financial_history.size()):
		var annual_entry: Dictionary = financial_history[history_index]
		var year: int = int(annual_entry.get("year", HISTORY_START_YEAR + history_index))
		var annual_revenue: float = max(float(annual_entry.get("revenue", 0.0)), 1.0)
		var annual_net_income: float = float(annual_entry.get("net_income", 0.0))
		var year_end_equity: float = max(float(annual_entry.get("equity", 0.0)), annual_revenue * 0.04)
		var year_end_debt: float = max(float(annual_entry.get("debt", 0.0)), 0.0)
		var shares_outstanding: float = max(
			float(annual_entry.get("shares_outstanding", default_shares_outstanding)),
			0.0
		)
		var previous_annual_revenue: float = annual_revenue
		if history_index > 0:
			previous_annual_revenue = float(financial_history[history_index - 1].get("revenue", annual_revenue))
		else:
			var initial_growth_ratio: float = max(
				1.0 + (float(annual_entry.get("revenue_growth_yoy", 0.0)) / 100.0),
				0.70
			)
			previous_annual_revenue = annual_revenue / initial_growth_ratio

		var year_start_equity: float = previous_year_end_equity
		if history_index == 0:
			year_start_equity = _estimate_start_of_history_equity(annual_revenue, annual_net_income, year_end_equity)

		var year_start_debt: float = previous_year_end_debt
		if history_index == 0:
			year_start_debt = _estimate_start_of_history_debt(annual_revenue, year_end_debt, traits)

		var revenue_weights: Array = _build_quarter_weight_profile(
			normalized_sector_id,
			run_seed,
			company_id,
			"quarter_revenue",
			year
		)
		var earnings_seed_weights: Array = []
		var debt_seed_weights: Array = []
		var equity_seed_weights: Array = []
		for quarter_index in range(4):
			var margin_jitter: float = _sample_noise(
				run_seed,
				company_id,
				"quarter_margin",
				-0.06,
				0.06,
				(year * 10) + quarter_index + 1
			)
			var earnings_bias: float = 1.0
			if quarter_index == 3:
				earnings_bias += 0.04 + (float(traits.get("story_heat", 0.5)) * 0.03)
			if quarter_index == 0:
				earnings_bias -= float(traits.get("cyclicality", 0.5)) * 0.03
			earnings_bias += (float(traits.get("execution_consistency", 0.5)) - 0.5) * 0.08
			earnings_bias += margin_jitter
			earnings_seed_weights.append(max(float(revenue_weights[quarter_index]) * earnings_bias, 0.05))

			var debt_bias: float = float(revenue_weights[quarter_index]) * (
				1.0 +
				(float(traits.get("capital_intensity", 0.5)) * 0.28) +
				(0.05 if quarter_index in [1, 2] else 0.0) +
				_sample_noise(
					run_seed,
					company_id,
					"quarter_debt_bias",
					-0.04,
					0.04,
					(year * 10) + quarter_index + 1
				)
			)
			debt_seed_weights.append(max(debt_bias, 0.05))

			var equity_bias: float = float(revenue_weights[quarter_index]) * (
				1.0 +
				(float(traits.get("balance_sheet_strength", 0.5)) - 0.5) * 0.10 +
				_sample_noise(
					run_seed,
					company_id,
					"quarter_equity_bias",
					-0.03,
					0.03,
					(year * 10) + quarter_index + 1
				)
			)
			equity_seed_weights.append(max(equity_bias, 0.05))

		var earnings_weights: Array = _normalize_quarter_weights(earnings_seed_weights)
		var debt_progress_weights: Array = _normalize_quarter_weights(debt_seed_weights)
		var equity_progress_weights: Array = _normalize_quarter_weights(equity_seed_weights)
		var cumulative_equity_progress: float = 0.0
		var cumulative_debt_progress: float = 0.0
		var quarter_start_debt: float = year_start_debt
		var previous_revenue_reference: float = previous_quarter_revenue
		if history_index == 0 and is_zero_approx(previous_revenue_reference):
			previous_revenue_reference = previous_annual_revenue * float(revenue_weights[3])

		for quarter_index in range(4):
			var quarter_revenue: float = annual_revenue * float(revenue_weights[quarter_index])
			var quarter_net_income: float = annual_net_income * float(earnings_weights[quarter_index])
			cumulative_equity_progress += float(equity_progress_weights[quarter_index])
			cumulative_debt_progress += float(debt_progress_weights[quarter_index])

			var quarter_end_equity: float = year_start_equity + (
				(year_end_equity - year_start_equity) * cumulative_equity_progress
			)
			var quarter_end_debt: float = year_start_debt + (
				(year_end_debt - year_start_debt) * cumulative_debt_progress
			)
			if quarter_index == 3:
				quarter_end_equity = year_end_equity
				quarter_end_debt = year_end_debt

			var statement_rng: RandomNumberGenerator = _rng_for(
				run_seed,
				company_id,
				"statement_%d_q%d" % [year, quarter_index + 1]
			)
			statements.append(_build_statement_period(
				year,
				quarter_index + 1,
				quarter_revenue,
				quarter_net_income,
				quarter_end_equity,
				quarter_end_debt,
				shares_outstanding,
				previous_revenue_reference,
				quarter_start_debt,
				traits,
				statement_rng
			))

			previous_revenue_reference = quarter_revenue
			previous_quarter_revenue = quarter_revenue
			quarter_start_debt = quarter_end_debt
		previous_year_end_equity = year_end_equity
		previous_year_end_debt = year_end_debt

	return statements


func _build_statement_period(
	statement_year: int,
	statement_quarter: int,
	revenue: float,
	net_income: float,
	equity: float,
	debt: float,
	shares_outstanding: float,
	previous_revenue: float,
	previous_debt: float,
	traits: Dictionary,
	rng: RandomNumberGenerator
) -> Dictionary:
	var safe_revenue: float = max(revenue, 1.0)
	var safe_equity: float = max(equity, safe_revenue * 0.04)
	var safe_debt: float = max(debt, 0.0)
	var net_margin_ratio: float = clamp(net_income / safe_revenue, -0.30, 0.35)
	var margin_strength: float = float(traits.get("margin_strength", 0.5))
	var capital_intensity: float = float(traits.get("capital_intensity", 0.5))
	var balance_sheet_strength: float = float(traits.get("balance_sheet_strength", 0.5))
	var liquidity_profile: float = float(traits.get("liquidity_profile", 0.5))
	var growth_engine: float = float(traits.get("growth_engine", 0.5))
	var scale: float = float(traits.get("scale", 0.5))
	var cyclicality: float = float(traits.get("cyclicality", 0.5))
	var story_heat: float = float(traits.get("story_heat", 0.5))

	var tax_rate: float = clamp(
		0.19 +
		(capital_intensity * 0.03) +
		(cyclicality * 0.015) -
		(balance_sheet_strength * 0.02) +
		rng.randf_range(-0.012, 0.012),
		0.15,
		0.30
	)
	var income_before_tax: float = net_income / max(1.0 - tax_rate, 0.60)
	var average_debt: float = max((safe_debt + max(previous_debt, 0.0)) * 0.5, 0.0)
	var interest_rate: float = clamp(
		0.032 +
		(cyclicality * 0.028) +
		((1.0 - balance_sheet_strength) * 0.025) +
		rng.randf_range(-0.004, 0.004),
		0.025,
		0.10
	)
	var finance_cost: float = max(average_debt * interest_rate * 0.25, 0.0)
	var income_from_operations: float = income_before_tax + finance_cost
	var gross_margin_ratio: float = clamp(
		max(income_from_operations / safe_revenue, net_margin_ratio + 0.02) +
		0.09 +
		(margin_strength * 0.12) -
		(capital_intensity * 0.04) +
		rng.randf_range(-0.018, 0.018),
		0.10,
		0.78
	)
	var gross_profit: float = safe_revenue * gross_margin_ratio
	if gross_profit < income_from_operations:
		gross_profit = income_from_operations * 1.08

	var oci_amount: float = net_income * (rng.randf_range(-0.025, 0.025) * lerp(0.35, 1.0, cyclicality))
	var total_comprehensive_income: float = net_income + oci_amount
	var others_ratio: float = clamp(
		0.02 +
		(scale * 0.07) +
		(capital_intensity * 0.03) +
		rng.randf_range(-0.012, 0.018),
		0.0,
		0.18
	)
	var owners_income: float = net_income * (1.0 - others_ratio)
	var others_income: float = net_income - owners_income

	var other_liabilities: float = max(
		safe_revenue * (0.012 + (capital_intensity * 0.02) + ((1.0 - liquidity_profile) * 0.01)),
		safe_equity * (0.08 + (capital_intensity * 0.16) + (cyclicality * 0.04) - (balance_sheet_strength * 0.05))
	)
	var total_liabilities: float = max(safe_debt + other_liabilities, safe_debt)
	var total_assets: float = max(total_liabilities + safe_equity, safe_revenue * 0.20)
	var current_asset_ratio: float = clamp(
		0.32 +
		(liquidity_profile * 0.18) +
		(balance_sheet_strength * 0.06) -
		(capital_intensity * 0.10) +
		rng.randf_range(-0.025, 0.025),
		0.18,
		0.72
	)
	var current_assets: float = total_assets * current_asset_ratio
	var non_current_assets: float = total_assets - current_assets
	var current_liability_ratio: float = clamp(
		0.40 +
		(capital_intensity * 0.12) -
		(balance_sheet_strength * 0.07) +
		rng.randf_range(-0.025, 0.025),
		0.24,
		0.74
	)
	var current_liabilities: float = total_liabilities * current_liability_ratio
	var non_current_liabilities: float = total_liabilities - current_liabilities

	var depreciation: float = safe_revenue * clamp(0.02 + (capital_intensity * 0.07), 0.02, 0.09)
	var working_capital_outflow: float = (safe_revenue - previous_revenue) * clamp(
		0.03 + (capital_intensity * 0.04) + ((1.0 - liquidity_profile) * 0.03),
		0.02,
		0.10
	)
	var cash_from_operating: float = net_income + depreciation - working_capital_outflow
	var capex: float = safe_revenue * clamp(
		0.04 + (capital_intensity * 0.14) + (growth_engine * 0.03) + (scale * 0.02),
		0.03,
		0.22
	)
	var asset_sales: float = 0.0
	if net_income < 0.0 or balance_sheet_strength < 0.35:
		asset_sales = capex * 0.12 * rng.randf_range(0.0, 1.0)
	var cash_from_investing: float = -capex + asset_sales
	var dividend_payout_ratio: float = 0.0
	if net_income > 0.0:
		dividend_payout_ratio = clamp(
			0.05 +
			(balance_sheet_strength * 0.14) +
			(scale * 0.08) -
			(growth_engine * 0.14),
			0.0,
			0.30
		)
	var dividends: float = max(net_income, 0.0) * dividend_payout_ratio
	var debt_change: float = safe_debt - max(previous_debt, 0.0)
	var equity_raise: float = 0.0
	if cash_from_operating + cash_from_investing < 0.0 and story_heat > 0.55:
		equity_raise = safe_revenue * (0.008 + (story_heat * 0.016)) * clamp(
			0.72 - balance_sheet_strength,
			0.0,
			1.0
		)
	var cash_from_financing: float = debt_change + equity_raise - dividends

	return {
		"statement_year": statement_year,
		"statement_quarter": statement_quarter,
		"statement_period_label": "Q%d %d" % [statement_quarter, statement_year],
		"income_statement": [
			_statement_line("revenue", "Total revenue", safe_revenue),
			_statement_line("gross_profit", "Gross profit", gross_profit),
			_statement_line("operating_income", "Income from operations", income_from_operations),
			_statement_line("income_before_tax", "Income before tax", income_before_tax),
			_statement_line("net_income", "Net income for the period", net_income),
			_statement_line("comprehensive_income", "Total comprehensive income", total_comprehensive_income),
			_statement_line("owners_income", "Net income attributable to owners", owners_income),
			_statement_line("others_income", "Net income attributable to others", others_income)
		],
		"balance_sheet": [
			_statement_line("current_assets", "Current assets", current_assets),
			_statement_line("non_current_assets", "Non-current assets", non_current_assets),
			_statement_line("total_assets", "Total assets", total_assets),
			_statement_line("current_liabilities", "Current liabilities", current_liabilities),
			_statement_line("non_current_liabilities", "Non-current liabilities", non_current_liabilities),
			_statement_line("total_liabilities", "Total liabilities", total_liabilities),
			_statement_line("equity", "Equity", safe_equity),
			_statement_line("shares_outstanding", "Shares outstanding", max(shares_outstanding, 0.0), "shares")
		],
		"cash_flow": [
			_statement_line("cash_from_operating", "Cash from operating", cash_from_operating),
			_statement_line("cash_from_investing", "Cash from investing", cash_from_investing),
			_statement_line("cash_from_financing", "Cash from financing", cash_from_financing)
		]
	}


func _build_quarter_weight_profile(
	sector_id: String,
	run_seed: int,
	company_id: String,
	salt: String,
	year: int
) -> Array:
	var base_weights: Array = DEFAULT_QUARTER_WEIGHTS
	if QUARTER_WEIGHT_PROFILES.has(sector_id):
		base_weights = QUARTER_WEIGHT_PROFILES[sector_id]

	var seeded_weights: Array = []
	for quarter_index in range(4):
		var jitter: float = _sample_noise(
			run_seed,
			company_id,
			salt,
			-0.018,
			0.018,
			(year * 10) + quarter_index + 1
		)
		seeded_weights.append(max(float(base_weights[quarter_index]) + jitter, 0.12))
	return _normalize_quarter_weights(seeded_weights)


func _normalize_quarter_weights(weights: Array) -> Array:
	var normalized_weights: Array = []
	var total_weight: float = 0.0
	for weight_value in weights:
		var safe_weight: float = max(float(weight_value), 0.001)
		normalized_weights.append(safe_weight)
		total_weight += safe_weight

	if total_weight <= 0.0:
		return DEFAULT_QUARTER_WEIGHTS.duplicate()

	for weight_index in range(normalized_weights.size()):
		normalized_weights[weight_index] = float(normalized_weights[weight_index]) / total_weight
	return normalized_weights


func _estimate_start_of_history_equity(annual_revenue: float, annual_net_income: float, year_end_equity: float) -> float:
	var implied_start_equity: float = year_end_equity - (annual_net_income * 0.72)
	return max(implied_start_equity, annual_revenue * 0.10)


func _estimate_start_of_history_debt(
	annual_revenue: float,
	year_end_debt: float,
	traits: Dictionary
) -> float:
	if year_end_debt <= 0.0:
		return 0.0

	var starting_debt_multiplier: float = clamp(
		0.90 + (float(traits.get("capital_intensity", 0.5)) * 0.08),
		0.82,
		1.04
	)
	return max(year_end_debt * starting_debt_multiplier, annual_revenue * 0.015)


func _statement_line(id: String, label: String, value: float, value_format: String = "currency") -> Dictionary:
	return {
		"id": id,
		"label": label,
		"value": value,
		"format": value_format
	}


func _quarter_key(year: int, quarter: int) -> String:
	return "%d_q%d" % [year, quarter]


func _group_trade_dates_by_quarter(trade_dates: Array) -> Dictionary:
	var grouped_dates: Dictionary = {}
	for trade_date_value in trade_dates:
		if typeof(trade_date_value) != TYPE_DICTIONARY:
			continue
		var trade_date: Dictionary = trade_date_value
		var year: int = int(trade_date.get("year", HISTORY_END_YEAR))
		var month: int = int(trade_date.get("month", 1))
		var quarter: int = int(clamp(ceili(float(month) / 3.0), 1, 4))
		var quarter_key: String = _quarter_key(year, quarter)
		if not grouped_dates.has(quarter_key):
			grouped_dates[quarter_key] = []
		grouped_dates[quarter_key].append(trade_date.duplicate(true))
	return grouped_dates


func _historical_year_start_price(start_year: int, annual_by_year: Dictionary, fallback_price: float) -> float:
	if annual_by_year.has(start_year - 1):
		return IDX_PRICE_RULES.normalize_last_price(max(
			float(annual_by_year[start_year - 1].get("implied_share_price", fallback_price)),
			1.0
		))
	if annual_by_year.has(start_year):
		return IDX_PRICE_RULES.normalize_last_price(max(
			float(annual_by_year[start_year].get("implied_share_price", fallback_price)),
			1.0
		))
	return IDX_PRICE_RULES.normalize_last_price(max(fallback_price, 1.0))


func _build_historical_year_end_price_map(
	processed_years: Array,
	annual_by_year: Dictionary,
	traits: Dictionary,
	run_seed: int,
	company_id: String,
	end_price: float
) -> Dictionary:
	var price_map: Dictionary = {}
	if processed_years.is_empty():
		return price_map

	var first_year: int = int(processed_years[0])
	var current_price: float = _historical_year_start_price(first_year, annual_by_year, end_price)
	var balance_sheet_strength: float = float(traits.get("balance_sheet_strength", 0.5))
	var cyclicality: float = float(traits.get("cyclicality", 0.5))
	var story_heat: float = float(traits.get("story_heat", 0.5))
	var execution_consistency: float = float(traits.get("execution_consistency", 0.5))
	var valuation_state: float = _sample_noise(
		run_seed,
		company_id,
		"historical_valuation_state",
		-0.18,
		0.18,
		first_year
	)
	var previous_year_return: float = 0.0

	for year_value in processed_years:
		var year: int = int(year_value)
		var annual_entry: Dictionary = annual_by_year.get(year, {})
		if annual_entry.is_empty():
			annual_entry = annual_by_year.get(year - 1, {}).duplicate(true)
		var previous_annual_entry: Dictionary = annual_by_year.get(year - 1, annual_entry).duplicate(true)
		var current_anchor: float = max(
			float(annual_entry.get("implied_share_price", current_price)),
			1.0
		)
		var previous_anchor: float = max(
			float(previous_annual_entry.get("implied_share_price", current_price)),
			1.0
		)
		var anchor_return: float = clamp((current_anchor / previous_anchor) - 1.0, -0.28, 0.36)
		var revenue_growth: float = clamp(float(annual_entry.get("revenue_growth_yoy", 0.0)) / 100.0, -0.24, 0.30)
		var earnings_growth: float = clamp(float(annual_entry.get("earnings_growth_yoy", 0.0)) / 100.0, -0.36, 0.42)
		var roe_signal: float = clamp((float(annual_entry.get("roe", 0.0)) - 12.0) / 100.0, -0.18, 0.18)
		var leverage_drag: float = max(float(annual_entry.get("debt_to_equity", 0.0)) - 0.75, 0.0)
		var regime_noise: float = _sample_noise(
			run_seed,
			company_id,
			"historical_year_regime",
			-0.22,
			0.22,
			year
		)
		valuation_state = clamp(
			(valuation_state * 0.44) +
			(regime_noise * (0.78 + (cyclicality * 0.36) + (story_heat * 0.22))) +
			(revenue_growth * 0.08) +
			(earnings_growth * 0.12) -
			(previous_year_return * 0.16),
			-0.38,
			0.38
		)
		var yearly_return: float = clamp(
			(anchor_return * 0.24) +
			(revenue_growth * 0.16) +
			(earnings_growth * 0.24) +
			(roe_signal * 0.34) +
			(valuation_state * 0.54) -
			(leverage_drag * 0.09) +
			((balance_sheet_strength - 0.5) * 0.05) -
			((cyclicality - 0.5) * 0.02),
			-0.48,
			0.58
		)
		current_price = max(current_price * (1.0 + yearly_return), 1.0)
		var anchor_pull: float = 0.14 + (execution_consistency * 0.08) + (balance_sheet_strength * 0.04)
		current_price = lerp(current_price, current_anchor, clamp(anchor_pull, 0.12, 0.26))
		price_map[year] = IDX_PRICE_RULES.normalize_last_price(max(current_price, 1.0))
		previous_year_return = yearly_return

	var last_year: int = int(processed_years[processed_years.size() - 1])
	var last_generated_price: float = max(float(price_map.get(last_year, end_price)), 1.0)
	var scale_factor: float = max(end_price, 1.0) / last_generated_price
	for year_value in processed_years:
		var year: int = int(year_value)
		price_map[year] = IDX_PRICE_RULES.normalize_last_price(max(float(price_map.get(year, 1.0)) * scale_factor, 1.0))
	price_map[last_year] = IDX_PRICE_RULES.normalize_last_price(max(end_price, 1.0))
	return price_map


func _build_historical_year_quarter_end_prices(
	year: int,
	year_start_price: float,
	year_end_price: float,
	quarterly_by_key: Dictionary,
	traits: Dictionary,
	run_seed: int,
	company_id: String
) -> Array:
	var quarter_end_prices: Array = []
	var current_price: float = max(year_start_price, 1.0)
	var balance_sheet_strength: float = float(traits.get("balance_sheet_strength", 0.5))
	var cyclicality: float = float(traits.get("cyclicality", 0.5))
	var story_heat: float = float(traits.get("story_heat", 0.5))
	var execution_consistency: float = float(traits.get("execution_consistency", 0.5))
	var corridor_floor: float = max(min(year_start_price, year_end_price) * max(0.58 - (cyclicality * 0.10), 0.38), 1.0)
	var corridor_ceiling: float = max(year_start_price, year_end_price) * (1.28 + (cyclicality * 0.18) + (story_heat * 0.08))
	for quarter in range(1, 5):
		if quarter == 4:
			quarter_end_prices.append(IDX_PRICE_RULES.normalize_last_price(max(year_end_price, 1.0)))
			break

		var remaining_steps: float = float(5 - quarter)
		var baseline_target: float = lerp(current_price, year_end_price, 1.0 / remaining_steps)
		var statement: Dictionary = quarterly_by_key.get(_quarter_key(year, quarter), {})
		var revenue: float = max(_statement_value(statement.get("income_statement", []), "revenue"), 1.0)
		var net_income: float = _statement_value(statement.get("income_statement", []), "net_income")
		var operating_cash: float = _statement_value(statement.get("cash_flow", []), "cash_from_operating")
		var quarter_signal: float = clamp(
			((net_income / revenue) * 0.75) +
			((operating_cash / revenue) * 0.35),
			-0.18,
			0.22
		)
		var regime_noise: float = _sample_noise(
			run_seed,
			company_id,
			"historical_quarter_regime_%d" % year,
			-0.22,
			0.22,
			quarter
		)
		var quarter_target: float = baseline_target * (
			1.0 +
			(quarter_signal * 0.22) +
			(regime_noise * (0.20 + (cyclicality * 0.12) + (story_heat * 0.08))) +
			((0.5 - execution_consistency) * 0.03) -
			((balance_sheet_strength - 0.5) * 0.02)
		)
		quarter_target = clamp(quarter_target, corridor_floor, corridor_ceiling)
		current_price = IDX_PRICE_RULES.normalize_last_price(max(quarter_target, 1.0))
		quarter_end_prices.append(current_price)
	return quarter_end_prices


func _build_historical_quarter_bars(
	trade_dates: Array,
	quarter_start_price: float,
	quarter_end_price: float,
	annual_entry: Dictionary,
	quarter_statement: Dictionary,
	traits: Dictionary,
	run_seed: int,
	company_id: String,
	year: int,
	quarter: int
) -> Array:
	if trade_dates.is_empty():
		return []

	var safe_start_price: float = IDX_PRICE_RULES.normalize_last_price(max(quarter_start_price, 1.0))
	var safe_end_price: float = IDX_PRICE_RULES.normalize_last_price(max(quarter_end_price, 1.0))
	var annual_revenue: float = max(float(annual_entry.get("revenue", 0.0)), 1.0)
	var quarter_revenue: float = max(_statement_value(quarter_statement.get("income_statement", []), "revenue"), annual_revenue / 4.0)
	var quarter_operating_cash: float = _statement_value(quarter_statement.get("cash_flow", []), "cash_from_operating")
	var quarter_value_bias: float = clamp((quarter_revenue / annual_revenue) * 4.0, 0.70, 1.35)
	var base_daily_value: float = max(
		float(annual_entry.get("avg_daily_value", 0.0)) * quarter_value_bias,
		safe_end_price * 5000.0
	)
	var noise_scale: float = clamp(
		0.0045 +
		(float(traits.get("cyclicality", 0.5)) * 0.0050) +
		(float(traits.get("story_heat", 0.5)) * 0.0035) +
		((1.0 - float(traits.get("liquidity_profile", 0.5))) * 0.0030),
		0.0040,
		0.0150
	)

	var bars: Array = []
	var previous_close: float = safe_start_price
	for trade_date_index in range(trade_dates.size()):
		var trade_date: Dictionary = trade_dates[trade_date_index]
		var progress: float = float(trade_date_index + 1) / float(trade_dates.size())
		var noise_envelope: float = sin(progress * PI)
		var deterministic_close: float = lerp(safe_start_price, safe_end_price, progress)
		var close_noise: float = _sample_noise(
			run_seed,
			company_id,
			"historical_close_%d_q%d" % [year, quarter],
			-1.0,
			1.0,
			trade_date_index + 1
		)
		var close_price: float = deterministic_close + (
			deterministic_close * noise_scale * noise_envelope * close_noise
		)
		close_price += (deterministic_close - previous_close) * 0.22
		if trade_date_index == trade_dates.size() - 1:
			close_price = safe_end_price
		close_price = IDX_PRICE_RULES.normalize_last_price(max(close_price, 1.0))

		var intraday_multiplier: float = _sample_noise(
			run_seed,
			company_id,
			"historical_intraday_%d_q%d" % [year, quarter],
			0.45,
			1.20,
			trade_date_index + 1
		)
		var day_move_ratio: float = absf(close_price - previous_close) / max(previous_close, 1.0)
		var intraday_range_ratio: float = max(day_move_ratio * 0.70, noise_scale * intraday_multiplier)
		var high_price: float = IDX_PRICE_RULES.normalize_last_price(max(
			max(previous_close, close_price) * (1.0 + intraday_range_ratio),
			max(previous_close, close_price)
		))
		var low_floor: float = max(
			min(previous_close, close_price) * max(1.0 - intraday_range_ratio, 0.55),
			1.0
		)
		var low_price: float = IDX_PRICE_RULES.normalize_last_price(min(
			min(previous_close, close_price),
			low_floor
		))
		high_price = max(high_price, previous_close, close_price)
		low_price = min(low_price, previous_close, close_price)

		var value_multiplier: float = _sample_noise(
			run_seed,
			company_id,
			"historical_value_%d_q%d" % [year, quarter],
			0.82,
			1.18,
			trade_date_index + 1
		)
		var operating_cash_multiplier: float = 1.0
		if quarter_revenue > 0.0:
			operating_cash_multiplier += clamp(quarter_operating_cash / quarter_revenue, -0.15, 0.25)
		var traded_value: float = max(
			base_daily_value * value_multiplier * (1.0 + (day_move_ratio * 7.0)) * operating_cash_multiplier,
			close_price * 1000.0
		)
		var volume_shares: int = int(max(round(traded_value / max(close_price, 1.0) / 100.0), 1.0) * 100.0)
		var bar_value: float = close_price * float(volume_shares)
		bars.append({
			"trade_date": trade_date.duplicate(true),
			"open": previous_close,
			"high": high_price,
			"low": low_price,
			"close": close_price,
			"volume_shares": volume_shares,
			"value": bar_value
		})
		previous_close = close_price
	return bars


func _statement_value(statement_lines: Array, line_id: String) -> float:
	for line_value in statement_lines:
		if typeof(line_value) != TYPE_DICTIONARY:
			continue
		var line: Dictionary = line_value
		if str(line.get("id", "")) == line_id:
			return float(line.get("value", 0.0))
	return 0.0


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
	var anchors: Dictionary = template.get("anchors", {})
	var capital_structure_style: String = str(anchors.get("capital_structure_style", "balanced"))
	var target_price_floor: float = float(anchors.get("target_price_floor", 0.0))
	var target_price_ceiling: float = float(anchors.get("target_price_ceiling", 0.0))
	var anchor_price: float = max(_anchor_value(template, "base_price", 100.0, "base_price"), 50.0)
	var market_cap_trillions: float = max(_anchor_value(template, "market_cap", 1000000000000.0), 100000000000.0) / 1000000000000.0
	var free_float_ratio: float = clamp(_anchor_value(template, "free_float_pct", 28.0) / 100.0, 0.07, 0.60)
	var margin_ratio: float = clamp(_anchor_value(template, "net_profit_margin", 7.5) / 18.0, 0.0, 1.0)
	var debt_ratio: float = clamp(_anchor_value(template, "debt_to_equity", 0.75) / 1.8, 0.0, 1.0)
	var quality_ratio: float = clamp(_anchor_ratio(template, "quality", "quality_score", 58.0), 0.25, 0.95)
	var owner_concentration_ratio: float = clamp(
		float(anchors.get("owner_concentration_pct", 100.0 - (_anchor_value(template, "free_float_pct", 28.0)))) / 100.0,
		0.25,
		0.95
	)
	var price_multiplier: float = _sample_noise(run_seed, company_id, "price_anchor", 0.92, 1.08, HISTORY_END_YEAR)
	var target_price: float = anchor_price * price_multiplier
	var fundamental_multiplier: float = (
		1.0 +
		((float(traits.get("story_heat", 0.5)) - 0.5) * 0.08) +
		((float(traits.get("liquidity_profile", 0.5)) - 0.5) * 0.05) -
		((float(traits.get("cyclicality", 0.5)) - 0.5) * 0.03)
	)
	target_price *= fundamental_multiplier
	var size_score: float = clamp((market_cap_trillions - 1.6) / 4.4, 0.0, 1.0)
	var institutional_score: float = clamp(
		(size_score * 0.34) +
		(float(traits.get("balance_sheet_strength", 0.5)) * 0.20) +
		(float(traits.get("margin_strength", 0.5)) * 0.16) +
		(float(traits.get("liquidity_profile", 0.5)) * 0.10) +
		(free_float_ratio * 0.10) +
		(quality_ratio * 0.10),
		0.0,
		1.0
	)
	var scarcity_score: float = clamp(
		(size_score * 0.50) +
		(clamp((0.20 - free_float_ratio) / 0.13, 0.0, 1.0) * 0.18) +
		(clamp((margin_ratio - 0.42) / 0.58, 0.0, 1.0) * 0.10) +
		(clamp(1.0 - debt_ratio, 0.0, 1.0) * 0.06) +
		(clamp((quality_ratio - 0.52) / 0.43, 0.0, 1.0) * 0.06) +
		(owner_concentration_ratio * 0.10),
		0.0,
		1.0
	)
	match capital_structure_style:
		"wide_float":
			target_price *= lerp(0.82, 1.18, clamp((size_score * 0.58) + (free_float_ratio * 0.42), 0.0, 1.0))
		"institutional_premium":
			target_price *= lerp(1.8, 8.4, institutional_score)
		"owner_controlled":
			target_price *= lerp(2.2, 11.5, scarcity_score)
		_:
			target_price *= lerp(0.96, 1.72, clamp((size_score * 0.36) + (quality_ratio * 0.24) + (free_float_ratio * 0.10), 0.0, 1.0))

	if target_price_floor > 0.0:
		target_price = max(target_price, target_price_floor * _sample_noise(run_seed, company_id, "price_floor", 0.97, 1.05, HISTORY_END_YEAR))
	if target_price_ceiling > 0.0:
		var safe_ceiling: float = max(target_price_ceiling, target_price_floor if target_price_floor > 0.0 else target_price_ceiling)
		target_price = min(target_price, safe_ceiling * _sample_noise(run_seed, company_id, "price_ceiling", 0.97, 1.05, HISTORY_END_YEAR))
	if target_price_floor > 0.0 and target_price_ceiling > target_price_floor:
		target_price = clamp(target_price, target_price_floor * 0.97, target_price_ceiling * 1.05)

	var fundamental_price_floor: float = 60.0
	match capital_structure_style:
		"wide_float":
			fundamental_price_floor = lerp(50.0, 720.0, pow(institutional_score, 1.45))
		"institutional_premium":
			fundamental_price_floor = lerp(220.0, 2200.0, pow(institutional_score, 1.15))
		"owner_controlled":
			fundamental_price_floor = lerp(160.0, 2600.0, pow(scarcity_score, 1.05))
		_:
			fundamental_price_floor = lerp(60.0, 1400.0, pow(institutional_score, 1.35))
	target_price = max(target_price, fundamental_price_floor)
	return IDX_PRICE_RULES.normalize_last_price(clamp(target_price, 50.0, 45000.0))


func _derive_shares_outstanding(market_cap: float, target_price: float, template: Dictionary) -> float:
	var safe_price: float = max(target_price, 1.0)
	var capital_structure_style: String = str(template.get("anchors", {}).get("capital_structure_style", "balanced"))
	var raw_shares_outstanding: float = max(market_cap / safe_price, 1000000.0)
	var minimum_shares_outstanding: float = 40000000.0
	match capital_structure_style:
		"wide_float":
			minimum_shares_outstanding = 120000000.0
		"institutional_premium":
			minimum_shares_outstanding = 12000000.0
		"owner_controlled":
			minimum_shares_outstanding = 4000000.0
		_:
			minimum_shares_outstanding = 40000000.0

	return max(_round_shares_outstanding(raw_shares_outstanding), minimum_shares_outstanding)


func _round_shares_outstanding(raw_shares_outstanding: float) -> float:
	if raw_shares_outstanding >= 1000000000.0:
		return round(raw_shares_outstanding / 10000000.0) * 10000000.0
	if raw_shares_outstanding >= 100000000.0:
		return round(raw_shares_outstanding / 5000000.0) * 5000000.0
	if raw_shares_outstanding >= 20000000.0:
		return round(raw_shares_outstanding / 1000000.0) * 1000000.0
	return round(raw_shares_outstanding / 250000.0) * 250000.0


func _pick_management_template(network_data: Dictionary, role_id: String, sector_id: String, run_seed: int, company_id: String) -> Dictionary:
	var candidates: Array = []
	for contact_value in network_data.get("contacts", []):
		var contact: Dictionary = contact_value
		if str(contact.get("affiliation_type", "floater")) != "insider_template":
			continue
		if str(contact.get("affiliation_role", "")) != role_id:
			continue
		var score: float = 1.0
		if sector_id in contact.get("sector_ids", []):
			score += 3.0
		score += float(contact.get("reliability", 0.5))
		score += _sample_noise(run_seed, company_id, "management_template_%s_%s" % [role_id, str(contact.get("id", ""))], 0.0, 1.0, 0)
		candidates.append({"contact": contact, "score": score})

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	if not candidates.is_empty():
		return candidates[0].get("contact", {}).duplicate(true)
	return _fallback_management_template(role_id)


func _fallback_management_template(role_id: String) -> Dictionary:
	var role_label: String = _management_role_label(role_id)
	return {
		"id": "fallback_%s_template" % role_id,
		"display_name": role_label,
		"role": "Listed Company %s" % role_label,
		"sector_ids": [],
		"categories": _management_categories(role_id),
		"recognition_required": 50,
		"base_relationship": 18,
		"reliability": 0.68,
		"tone": "mixed",
		"intro": "A senior company insider with direct visibility over the issuer.",
		"affiliation_type": "insider_template",
		"affiliation_role": role_id
	}


func _build_management_contact(
	template_contact: Dictionary,
	network_data: Dictionary,
	company_id: String,
	company_name: String,
	sector_id: String,
	role: Dictionary,
	run_seed: int
) -> Dictionary:
	var role_id: String = str(role.get("id", ""))
	var role_label: String = str(role.get("label", _management_role_label(role_id)))
	var display_name: String = _generated_management_name(network_data, run_seed, company_id, role_id)
	var categories: Array = []
	for category_value in template_contact.get("categories", _management_categories(role_id)):
		var category: String = str(category_value)
		if not category.is_empty() and not categories.has(category):
			categories.append(category)
	for category_value in _management_categories(role_id):
		var fallback_category: String = str(category_value)
		if not categories.has(fallback_category):
			categories.append(fallback_category)

	return {
		"contact_id": "insider_%s_%s" % [company_id, role_id],
		"id": "insider_%s_%s" % [company_id, role_id],
		"display_name": display_name,
		"affiliation_type": "insider",
		"affiliation_role": role_id,
		"company_id": company_id,
		"affiliated_company_id": company_id,
		"sector_id": sector_id,
		"sector_ids": [sector_id],
		"template_contact_id": str(template_contact.get("id", "")),
		"role": role_label,
		"role_label": role_label,
		"categories": categories,
		"recognition_required": int(template_contact.get("recognition_required", 50)),
		"base_relationship": int(template_contact.get("base_relationship", 18)),
		"reliability": float(template_contact.get("reliability", 0.68)),
		"tone": str(template_contact.get("tone", "mixed")),
		"intro": "%s serves as %s at %s. %s" % [
			display_name,
			role_label,
			company_name,
			str(template_contact.get("intro", "They have direct visibility over the issuer."))
		],
		"connected_floaters": _connected_floaters_for_insider(
			network_data,
			sector_id,
			categories,
			role_id,
			run_seed,
			company_id
		)
	}


func _generated_management_name(network_data: Dictionary, run_seed: int, company_id: String, role_id: String) -> String:
	var name_pools: Dictionary = network_data.get("person_name_pools", {})
	var first_names: Array = name_pools.get("first_names", ["Aditya", "Dewi", "Prasetyo", "Rani"])
	var family_names: Array = name_pools.get("family_names", ["Santoso", "Wijaya", "Kusuma", "Hidayat"])
	if first_names.is_empty():
		first_names = ["Aditya"]
	if family_names.is_empty():
		family_names = ["Santoso"]
	var rng: RandomNumberGenerator = _rng_for(run_seed, company_id, "management_name_%s" % role_id)
	var first_name: String = str(first_names[int(rng.randi_range(0, first_names.size() - 1))])
	var family_name: String = str(family_names[int(rng.randi_range(0, family_names.size() - 1))])
	return "%s %s" % [first_name, family_name]


func _connected_floaters_for_insider(
	network_data: Dictionary,
	sector_id: String,
	insider_categories: Array,
	role_id: String,
	run_seed: int,
	company_id: String
) -> Array:
	var rows: Array = []
	for contact_value in network_data.get("contacts", []):
		var contact: Dictionary = contact_value
		if str(contact.get("affiliation_type", "floater")) != "floater":
			continue
		var contact_id: String = str(contact.get("id", ""))
		if contact_id.is_empty():
			continue
		var sector_score: float = 24.0 if sector_id in contact.get("sector_ids", []) else 0.0
		var category_score: float = 0.0
		for category_value in contact.get("categories", []):
			if str(category_value) in insider_categories:
				category_score += 12.0
		var role_score: float = _floater_role_affinity(contact, role_id)
		var reliability_score: float = clamp(float(contact.get("reliability", 0.5)), 0.0, 1.0) * 18.0
		var recognition_bonus: float = max(0.0, 70.0 - float(contact.get("recognition_required", 0))) * 0.45
		var noise: float = _sample_noise(run_seed, company_id, "floater_bridge_%s_%s" % [role_id, contact_id], 0.0, 18.0, 0)
		var score: int = int(round(clamp(sector_score + category_score + role_score + reliability_score + recognition_bonus + noise, 0.0, 100.0)))
		if score < 35:
			continue
		rows.append({"contact_id": contact_id, "score": score})

	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)
	if rows.size() > 6:
		rows = rows.slice(0, 6)
	return rows


func _floater_role_affinity(contact: Dictionary, role_id: String) -> float:
	var role_text: String = str(contact.get("role", "")).to_lower()
	var categories: Array = contact.get("categories", [])
	match role_id:
		"ceo":
			if "management" in categories or "mna" in categories:
				return 16.0
			if role_text.contains("strategy") or role_text.contains("director"):
				return 12.0
		"cfo":
			if "earnings" in categories or "mna" in categories:
				return 16.0
			if role_text.contains("account") or role_text.contains("broker") or role_text.contains("finance"):
				return 12.0
		"commissioner":
			if "management" in categories or "policy_post" in categories:
				return 16.0
			if role_text.contains("law") or role_text.contains("regulator") or role_text.contains("commissioner"):
				return 12.0
	return 4.0


func _management_categories(role_id: String) -> Array:
	match role_id:
		"ceo":
			return ["management", "mna", "company"]
		"cfo":
			return ["earnings", "management", "mna"]
		"commissioner":
			return ["management", "policy_post", "mna"]
	return ["management", "company"]


func _management_role_label(role_id: String) -> String:
	match role_id:
		"ceo":
			return "CEO"
		"cfo":
			return "CFO"
		"commissioner":
			return "Commissioner"
	return role_id.capitalize()


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
