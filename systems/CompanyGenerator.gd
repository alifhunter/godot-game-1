extends RefCounted

const HISTORY_START_YEAR := 2010
const HISTORY_END_YEAR := 2019
const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")
const COMPANY_NARRATIVE_GENERATOR = preload("res://systems/CompanyNarrativeGenerator.gd")
const COMPANY_ROADMAP_SYSTEM = preload("res://systems/CompanyRoadmapSystem.gd")
const STABLE_RNG = preload("res://systems/StableRng.gd")
const DEFAULT_SECTOR_PROFILE := {
	"scale": 0.50,
	"growth": 0.50,
	"margin": 0.40,
	"capital_intensity": 0.50,
	"cyclicality": 0.50,
	"liquidity": 0.45,
	"growth_drift": 0.005
}
const CHART_SMA_PERIODS := [3, 5, 10, 20, 60, 100, 200]
const CHART_INTENTS := ["investing", "swing_trading", "short_term_trading", "speculative"]
const CHART_PATTERN_TIMEFRAMES := ["5y", "1y", "6m", "3m", "1m"]
const CHART_GAP_STYLES := ["none", "news_gap", "breakout_gap", "exhaustion_gap", "rug_gap", "mixed"]
const CHART_GAP_BIASES := ["up", "down", "mixed"]
const CHART_GAP_FREQUENCIES := ["rare", "moderate", "active"]
const CHART_GAP_FOLLOWTHROUGH := ["hold", "fade", "fill", "continue"]
const CHART_CYCLE_TEMPLATES := ["", "markup_clean", "markup_exhaustion", "distribution_clean", "failed_markup", "operator_markup", "operator_rug"]
const CHART_TEMPO_PROFILES := ["slow_setup", "normal_setup", "fast_operator", "failed_setup"]
const CHART_SHAKEOUT_PROFILES := ["none", "healthy_pullback", "hard_shakeout", "dead_cat", "failed_reclaim"]
const CHART_BAR_FRICTION_PROFILES := ["clean_liquid", "balanced_chop", "operator_dirty", "distribution_chop"]
const CHART_TAPE_REGIME_PROFILES := ["clean_trend", "messy_accumulation", "operator_campaign", "distribution_breakdown", "failed_reclaim"]
const CHART_FIB_PROFILES := {
	"fib_shallow": {"wave2": 0.382, "wave3": 1.272, "wave4": 0.236},
	"fib_classic": {"wave2": 0.500, "wave3": 1.618, "wave4": 0.382},
	"fib_deep": {"wave2": 0.618, "wave3": 1.618, "wave4": 0.382},
	"fib_operator": {"wave2": 0.236, "wave3": 2.000, "wave4": 0.236},
	"fib_rug": {"wave2": 0.382, "wave3": 1.618, "wave4": 0.618}
}
const BULLISH_CHART_PATTERNS := [
	"double_bottom",
	"inverse_head_shoulders",
	"cup_handle",
	"ascending_triangle",
	"rounded_base",
	"bull_flag",
	"breakout_retest",
	"higher_low_accumulation"
]
const BEARISH_CHART_PATTERNS := [
	"double_top",
	"head_shoulders",
	"descending_triangle",
	"lower_high_distribution",
	"failed_breakout",
	"breakdown_retest",
	"sma_resistance_rejection"
]
const GORENGAN_CHART_PATTERNS := [
	"pump_dump",
	"false_breakout",
	"sharp_squeeze",
	"rug_pull_volume",
	"messy_range"
]

var company_narrative_generator = COMPANY_NARRATIVE_GENERATOR.new()
var company_roadmap_system = COMPANY_ROADMAP_SYSTEM.new()
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
	var core_profile: Dictionary = generate_company_profile_core(template, sector_definition, run_seed)
	return hydrate_company_profile_detail(core_profile, template, sector_definition, run_seed)


func generate_company_profile_core(template: Dictionary, sector_definition: Dictionary, run_seed: int) -> Dictionary:
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
	var location_profile: Dictionary = company_roadmap_system.build_location_profile(
		template,
		sector_definition,
		traits,
		financials,
		run_seed
	)
	var roadmap_profile: Dictionary = company_roadmap_system.build_roadmap_profile(
		template,
		sector_definition,
		traits,
		financials,
		location_profile,
		run_seed
	)
	return {
		"base_price": generated_base_price,
		"quality_score": quality_score,
		"growth_score": growth_score,
		"risk_score": risk_score,
		"base_volatility": base_volatility,
		"financials": financials,
		"generation_traits": traits,
		"shares_outstanding": shares_outstanding,
		"location_profile": location_profile,
		"roadmap_profile": roadmap_profile,
		"detail_status": "cold"
	}


func hydrate_company_profile_detail(
	core_profile: Dictionary,
	template: Dictionary,
	sector_definition: Dictionary,
	run_seed: int
) -> Dictionary:
	var generated_profile: Dictionary = core_profile.duplicate(true)
	var company_id: String = str(template.get("id", "company"))
	var sector_id: String = str(sector_definition.get("id", template.get("sector_id", "")))
	var sector_profile: Dictionary = _sector_profile(sector_id)
	var traits: Dictionary = generated_profile.get("generation_traits", {}).duplicate(true)
	if traits.is_empty():
		traits = _build_traits(template, sector_profile, run_seed, company_id)
		generated_profile["generation_traits"] = traits
	var financial_history: Array = _build_financial_history(
		template,
		sector_profile,
		traits,
		run_seed,
		company_id
	)
	var shares_outstanding: float = max(float(generated_profile.get("shares_outstanding", 0.0)), 0.0)
	if shares_outstanding <= 0.0:
		var latest_year: Dictionary = financial_history[financial_history.size() - 1].duplicate(true)
		var target_price: float = _derive_target_price(template, traits, run_seed, company_id)
		shares_outstanding = _derive_shares_outstanding(float(latest_year.get("market_cap", 0.0)), target_price, template)
		generated_profile["shares_outstanding"] = shares_outstanding
	financial_history = _apply_share_price_history(financial_history, shares_outstanding)
	generated_profile["financial_history"] = financial_history
	generated_profile["financial_statement_snapshot"] = build_financial_statement_snapshot_from_profile(
		generated_profile,
		sector_id,
		run_seed,
		company_id
	)
	var narrative_profile: Dictionary = company_narrative_generator.build_profile(
		template,
		sector_definition,
		generated_profile.get("financials", {}),
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
	generated_profile["detail_status"] = "ready"
	return generated_profile


func ensure_company_life_profile(
	company_profile: Dictionary,
	template: Dictionary,
	sector_definition: Dictionary,
	run_seed: int
) -> Dictionary:
	return company_roadmap_system.ensure_company_life_profile(
		company_profile,
		template,
		sector_definition,
		run_seed
	)


func build_management_roster(template: Dictionary, sector_definition: Dictionary, run_seed: int) -> Array:
	var network_data: Dictionary = DataRepository.get_contact_network_data_ref()
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

	return _apply_chart_profile_to_historical_bars(
		bars,
		_chart_profile_from_traits(traits, run_seed, company_id),
		run_seed,
		company_id,
		end_price
	)


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
	var tier_scale: float = _scale_trait_from_tier(template, market_cap_anchor)
	var scale: float = clamp(
		(tier_scale * 0.72) +
		(float(sector_profile.get("scale", 0.45)) * 0.18) +
		(market_cap_anchor * 0.10) +
		rng.randf_range(-0.08, 0.08),
		0.06,
		0.96
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

	var traits: Dictionary = {
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
	traits["chart_profile"] = _build_chart_profile(
		template,
		sector_profile,
		traits,
		run_seed,
		company_id
	)
	return traits


func _scale_trait_from_tier(template: Dictionary, fallback_scale: float) -> float:
	var anchors: Dictionary = template.get("anchors", {})
	if not anchors.has("scale_tier_rank"):
		return fallback_scale
	match int(anchors.get("scale_tier_rank", 2)):
		0:
			return 0.10
		1:
			return 0.28
		2:
			return 0.52
		3:
			return 0.74
		4:
			return 0.92
		_:
			return fallback_scale


func _build_chart_profile(
	template: Dictionary,
	sector_profile: Dictionary,
	traits: Dictionary,
	run_seed: int,
	company_id: String
) -> Dictionary:
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "chart_profile", company_id])
	var narrative_tags: Array = template.get("narrative_tags", [])
	var story_heat: float = clamp(float(traits.get("story_heat", 0.5)), 0.0, 1.0)
	var float_tightness: float = clamp(float(traits.get("float_tightness", 0.5)), 0.0, 1.0)
	var liquidity_profile: float = clamp(float(traits.get("liquidity_profile", 0.5)), 0.0, 1.0)
	var quality_core: float = clamp(float(traits.get("balance_sheet_strength", 0.5)), 0.0, 1.0)
	var growth_engine: float = clamp(float(traits.get("growth_engine", 0.5)), 0.0, 1.0)
	var cyclicality: float = clamp(float(traits.get("cyclicality", sector_profile.get("cyclicality", 0.5))), 0.0, 1.0)
	var execution_consistency: float = clamp(float(traits.get("execution_consistency", 0.5)), 0.0, 1.0)

	var archetype: String = "range_bound"
	if story_heat >= 0.66 and float_tightness >= 0.54 and liquidity_profile <= 0.58:
		archetype = "gorengan"
	elif quality_core >= 0.62 and growth_engine >= 0.58 and execution_consistency >= 0.54:
		archetype = "funda" if quality_core >= growth_engine else "organic"
	elif quality_core <= 0.34 or (cyclicality >= 0.68 and execution_consistency <= 0.42):
		archetype = "distressed"
	elif cyclicality >= 0.66:
		archetype = "cyclical"
	elif float_tightness >= 0.58 and story_heat >= 0.44:
		archetype = "accumulation"
	elif rng.randf() < 0.28:
		archetype = "distribution"
	elif rng.randf() < 0.54:
		archetype = "organic"

	if "retail_favorite" in narrative_tags or "narrative_hot" in narrative_tags:
		if rng.randf() < 0.58:
			archetype = "gorengan"
	if "institution_quality" in narrative_tags or "supportive_balance_sheet" in narrative_tags:
		if rng.randf() < 0.62:
			archetype = "funda"
	if "commodity_beta" in narrative_tags or "policy_beta" in narrative_tags:
		if rng.randf() < 0.54:
			archetype = "cyclical"

	var bias: String = "sideways"
	match archetype:
		"organic", "funda", "accumulation":
			bias = "bullish" if rng.randf() < 0.72 else "transition"
		"distressed", "distribution":
			bias = "bearish" if rng.randf() < 0.76 else "transition"
		"gorengan":
			bias = ["bullish", "bearish", "sideways", "transition"][rng.randi_range(0, 3)]
		"cyclical":
			bias = ["bullish", "bearish", "transition"][rng.randi_range(0, 2)]
		_:
			bias = ["sideways", "bullish", "bearish"][rng.randi_range(0, 2)]

	var sma_behavior: String = "ignored"
	if archetype in ["organic", "funda", "accumulation"] and bias != "bearish":
		sma_behavior = "support"
	elif archetype in ["distressed", "distribution"] or bias == "bearish":
		sma_behavior = "resistance"
	elif archetype == "range_bound" or bias == "sideways":
		sma_behavior = "magnet"
	elif archetype == "gorengan":
		sma_behavior = "ignored" if rng.randf() < 0.64 else "magnet"

	var preferred_periods: Array = [20, 60]
	match archetype:
		"gorengan":
			preferred_periods = [3, 5, 10, 20]
		"organic", "accumulation":
			preferred_periods = [10, 20, 60]
		"funda":
			preferred_periods = [20, 60, 100, 200]
		"distressed", "distribution":
			preferred_periods = [20, 60, 100]
		"cyclical":
			preferred_periods = [20, 60, 100]
		"range_bound":
			preferred_periods = [10, 20, 60]
	var preferred_sma_period: int = int(preferred_periods[rng.randi_range(0, preferred_periods.size() - 1)])

	var pattern_pool: Array = _chart_pattern_pool_for(archetype, bias)
	var primary_pattern: String = str(pattern_pool[rng.randi_range(0, pattern_pool.size() - 1)])
	var pattern_variant: String = _chart_pattern_variant_for(primary_pattern, archetype, bias, rng)
	var supporting_patterns: Array = []
	for pattern_value in pattern_pool:
		var pattern_id: String = str(pattern_value)
		if pattern_id == primary_pattern:
			continue
		if supporting_patterns.size() >= 2:
			break
		if rng.randf() < 0.58:
			supporting_patterns.append(pattern_id)
	if supporting_patterns.is_empty() and pattern_pool.size() > 1:
		supporting_patterns.append(str(pattern_pool[(pattern_pool.find(primary_pattern) + 1) % pattern_pool.size()]))

	var volatility_style: String = _chart_volatility_style(archetype, cyclicality, story_heat, rng)
	var chart_intent: String = _chart_intent_for(
		archetype,
		bias,
		quality_core,
		growth_engine,
		story_heat,
		float_tightness,
		cyclicality,
		rng
	)
	var pattern_timeframe: String = _chart_pattern_timeframe_for(chart_intent, archetype, bias, rng)
	var gap_profile: Dictionary = _chart_gap_profile_for(
		chart_intent,
		archetype,
		bias,
		volatility_style,
		story_heat,
		float_tightness,
		quality_core,
		rng
	)
	var operator_pressure: float = _chart_operator_pressure_for_profile(
		archetype,
		bias,
		narrative_tags,
		story_heat,
		float_tightness,
		liquidity_profile
	)
	var cycle_template: String = _chart_cycle_template_for(
		archetype,
		bias,
		operator_pressure,
		story_heat,
		float_tightness,
		rng
	)
	var fib_profile_id: String = _chart_fib_profile_for(cycle_template, operator_pressure, rng)
	var cycle_strength: float = _chart_cycle_strength_for(cycle_template, operator_pressure, story_heat, float_tightness, rng)
	var cycle_tempo_profile: String = _chart_tempo_profile_for(archetype, bias, narrative_tags, cycle_template, operator_pressure, story_heat, liquidity_profile, quality_core, rng)
	var shakeout_profile: String = _chart_shakeout_profile_for(cycle_template, cycle_tempo_profile, operator_pressure, story_heat, float_tightness, rng)
	var microstructure_intensity: float = _chart_microstructure_intensity_for(cycle_template, cycle_tempo_profile, shakeout_profile, cycle_strength, operator_pressure, story_heat, float_tightness, liquidity_profile, rng)
	var setup_duration_bias: float = _chart_setup_duration_bias_for(cycle_tempo_profile, cycle_template, liquidity_profile, operator_pressure, rng)
	var bar_friction_profile: String = _chart_bar_friction_profile_for(archetype, bias, narrative_tags, cycle_template, cycle_tempo_profile, operator_pressure, story_heat, liquidity_profile, float_tightness, rng)
	var microleg_frequency_bias: float = _chart_microleg_frequency_bias_for(bar_friction_profile, cycle_tempo_profile, operator_pressure, story_heat, liquidity_profile, float_tightness, rng)
	var wick_noise_intensity: float = _chart_wick_noise_intensity_for(bar_friction_profile, operator_pressure, story_heat, float_tightness, liquidity_profile, rng)
	var volume_disagreement_rate: float = _chart_volume_disagreement_rate_for(bar_friction_profile, operator_pressure, story_heat, liquidity_profile, rng)
	var tape_regime_profile: String = _chart_tape_regime_profile_for(
		archetype,
		bias,
		cycle_template,
		cycle_tempo_profile,
		bar_friction_profile,
		operator_pressure,
		story_heat,
		liquidity_profile,
		float_tightness,
		rng
	)
	var regime_block_intensity: float = _chart_regime_block_intensity_for(
		tape_regime_profile,
		cycle_strength,
		microstructure_intensity,
		operator_pressure,
		story_heat,
		liquidity_profile,
		rng
	)
	var regime_tempo_bias: float = _chart_regime_tempo_bias_for(
		tape_regime_profile,
		cycle_tempo_profile,
		setup_duration_bias,
		operator_pressure,
		liquidity_profile,
		rng
	)

	return {
		"archetype": archetype,
		"bias": bias,
		"chart_intent": chart_intent,
		"pattern_timeframe": pattern_timeframe,
		"sma_behavior": sma_behavior,
		"preferred_sma_period": preferred_sma_period,
		"primary_pattern": primary_pattern,
		"pattern_variant": pattern_variant,
		"supporting_patterns": supporting_patterns,
		"clarity": rng.randf_range(0.58, 0.84),
		"volatility_style": volatility_style,
		"volume_behavior": _chart_volume_behavior(archetype, bias),
		"gap_style": str(gap_profile.get("gap_style", "none")),
		"gap_bias": str(gap_profile.get("gap_bias", "mixed")),
		"gap_frequency": str(gap_profile.get("gap_frequency", "rare")),
		"gap_followthrough": str(gap_profile.get("gap_followthrough", "fill")),
		"cycle_template": cycle_template,
		"cycle_strength": cycle_strength,
		"cycle_phase_bias": _chart_cycle_phase_bias(cycle_template),
		"operator_pressure": operator_pressure,
		"fib_profile_id": fib_profile_id,
		"cycle_fib_ratios": _chart_fib_ratios_for_profile(fib_profile_id),
		"cycle_tempo_profile": cycle_tempo_profile,
		"microstructure_intensity": microstructure_intensity,
		"setup_duration_bias": setup_duration_bias,
		"shakeout_profile": shakeout_profile,
		"bar_friction_profile": bar_friction_profile,
		"microleg_frequency_bias": microleg_frequency_bias,
		"wick_noise_intensity": wick_noise_intensity,
		"volume_disagreement_rate": volume_disagreement_rate,
		"tape_regime_profile": tape_regime_profile,
		"regime_block_intensity": regime_block_intensity,
		"regime_tempo_bias": regime_tempo_bias
	}


func _chart_profile_from_traits(traits: Dictionary, run_seed: int, company_id: String) -> Dictionary:
	var profile_value = traits.get("chart_profile", {})
	if typeof(profile_value) == TYPE_DICTIONARY and not profile_value.is_empty():
		return _normalize_chart_profile(profile_value, traits, run_seed, company_id)
	return _build_chart_profile({}, DEFAULT_SECTOR_PROFILE, traits, run_seed, company_id)


func _normalize_chart_profile(profile: Dictionary, traits: Dictionary, run_seed: int, company_id: String) -> Dictionary:
	var fallback: Dictionary = _build_chart_profile({}, DEFAULT_SECTOR_PROFILE, traits, run_seed, company_id)
	var normalized: Dictionary = profile.duplicate(true)
	for key_value in fallback.keys():
		var key: String = str(key_value)
		if _is_chart_cycle_key(key) and not profile.has(key):
			continue
		if not normalized.has(key) or (typeof(normalized.get(key)) == TYPE_STRING and str(normalized.get(key)).is_empty()):
			normalized[key] = fallback[key]
	var preferred_period: int = int(normalized.get("preferred_sma_period", fallback.get("preferred_sma_period", 20)))
	if not CHART_SMA_PERIODS.has(preferred_period):
		preferred_period = int(fallback.get("preferred_sma_period", 20))
	normalized["preferred_sma_period"] = preferred_period
	var pattern_id: String = str(normalized.get("primary_pattern", fallback.get("primary_pattern", "messy_range")))
	var archetype: String = str(normalized.get("archetype", fallback.get("archetype", "range_bound")))
	var bias: String = str(normalized.get("bias", fallback.get("bias", "sideways")))
	var pattern_variant: String = str(normalized.get("pattern_variant", "")).strip_edges()
	if not _chart_pattern_variant_ids(pattern_id, archetype, bias).has(pattern_variant):
		var variant_rng: RandomNumberGenerator = STABLE_RNG.rng([
			run_seed,
			"chart_profile_variant",
			company_id,
			pattern_id,
			archetype,
			bias
		])
		normalized["pattern_variant"] = _chart_pattern_variant_for(pattern_id, archetype, bias, variant_rng)
	normalized["chart_intent"] = _chart_safe_choice(
		str(normalized.get("chart_intent", "")),
		CHART_INTENTS,
		str(fallback.get("chart_intent", "swing_trading"))
	)
	normalized["pattern_timeframe"] = _chart_safe_choice(
		str(normalized.get("pattern_timeframe", "")),
		CHART_PATTERN_TIMEFRAMES,
		str(fallback.get("pattern_timeframe", "1y"))
	)
	normalized["gap_style"] = _chart_safe_choice(
		str(normalized.get("gap_style", "")),
		CHART_GAP_STYLES,
		str(fallback.get("gap_style", "none"))
	)
	normalized["gap_bias"] = _chart_safe_choice(
		str(normalized.get("gap_bias", "")),
		CHART_GAP_BIASES,
		str(fallback.get("gap_bias", "mixed"))
	)
	normalized["gap_frequency"] = _chart_safe_choice(
		str(normalized.get("gap_frequency", "")),
		CHART_GAP_FREQUENCIES,
		str(fallback.get("gap_frequency", "rare"))
	)
	normalized["gap_followthrough"] = _chart_safe_choice(
		str(normalized.get("gap_followthrough", "")),
		CHART_GAP_FOLLOWTHROUGH,
		str(fallback.get("gap_followthrough", "fill"))
	)
	normalized["cycle_template"] = _chart_safe_choice(
		str(normalized.get("cycle_template", "")),
		CHART_CYCLE_TEMPLATES,
		""
	)
	normalized["cycle_strength"] = clamp(float(normalized.get("cycle_strength", 0.0)), 0.0, 1.0)
	normalized["cycle_phase_bias"] = _chart_cycle_phase_bias(str(normalized.get("cycle_template", "")))
	normalized["operator_pressure"] = clamp(float(normalized.get("operator_pressure", 0.0)), 0.0, 1.0)
	var fib_profile_id: String = str(normalized.get("fib_profile_id", ""))
	if not CHART_FIB_PROFILES.has(fib_profile_id):
		fib_profile_id = ""
	normalized["fib_profile_id"] = fib_profile_id
	var fib_ratios_value = normalized.get("cycle_fib_ratios", {})
	if typeof(fib_ratios_value) != TYPE_DICTIONARY or (fib_ratios_value as Dictionary).is_empty():
		normalized["cycle_fib_ratios"] = _chart_fib_ratios_for_profile(fib_profile_id)
	normalized["cycle_tempo_profile"] = _chart_safe_choice(
		str(normalized.get("cycle_tempo_profile", "normal_setup")),
		CHART_TEMPO_PROFILES,
		"normal_setup"
	)
	normalized["microstructure_intensity"] = clamp(float(normalized.get("microstructure_intensity", 0.0)), 0.0, 1.0)
	normalized["setup_duration_bias"] = clamp(float(normalized.get("setup_duration_bias", 0.0)), -1.0, 1.0)
	normalized["shakeout_profile"] = _chart_safe_choice(
		str(normalized.get("shakeout_profile", "none")),
		CHART_SHAKEOUT_PROFILES,
		"none"
	)
	normalized["bar_friction_profile"] = _chart_safe_choice(
		str(normalized.get("bar_friction_profile", "balanced_chop")),
		CHART_BAR_FRICTION_PROFILES,
		"balanced_chop"
	)
	normalized["microleg_frequency_bias"] = clamp(float(normalized.get("microleg_frequency_bias", 0.55)), 0.0, 1.0)
	normalized["wick_noise_intensity"] = clamp(float(normalized.get("wick_noise_intensity", 0.42)), 0.0, 1.0)
	normalized["volume_disagreement_rate"] = clamp(float(normalized.get("volume_disagreement_rate", 0.36)), 0.0, 1.0)
	normalized["tape_regime_profile"] = _chart_safe_choice(
		str(normalized.get("tape_regime_profile", "")),
		CHART_TAPE_REGIME_PROFILES,
		str(fallback.get("tape_regime_profile", "messy_accumulation"))
	)
	normalized["regime_block_intensity"] = clamp(float(normalized.get("regime_block_intensity", fallback.get("regime_block_intensity", 0.55))), 0.0, 1.0)
	normalized["regime_tempo_bias"] = clamp(float(normalized.get("regime_tempo_bias", fallback.get("regime_tempo_bias", 0.0))), -1.0, 1.0)
	return normalized


func _is_chart_cycle_key(key: String) -> bool:
	return key in [
		"cycle_template",
		"cycle_strength",
		"cycle_phase_bias",
		"operator_pressure",
		"fib_profile_id",
		"cycle_fib_ratios",
		"cycle_tempo_profile",
		"microstructure_intensity",
		"setup_duration_bias",
		"shakeout_profile",
		"bar_friction_profile",
		"microleg_frequency_bias",
		"wick_noise_intensity",
		"volume_disagreement_rate",
		"tape_regime_profile",
		"regime_block_intensity",
		"regime_tempo_bias"
	]


func _chart_operator_pressure_for_profile(
	archetype: String,
	bias: String,
	narrative_tags: Array,
	story_heat: float,
	float_tightness: float,
	liquidity_profile: float
) -> float:
	var pressure: float = 0.0
	pressure += float_tightness * 0.30
	pressure += (1.0 - liquidity_profile) * 0.18
	pressure += story_heat * 0.16
	pressure += 0.24 if archetype == "gorengan" else 0.0
	pressure += 0.10 if archetype in ["accumulation", "distribution"] else 0.0
	pressure += 0.11 if bias in ["bullish", "transition"] else 0.0
	pressure += 0.13 if "retail_favorite" in narrative_tags else 0.0
	pressure += 0.12 if "narrative_hot" in narrative_tags else 0.0
	pressure += 0.08 if "turnaround_story" in narrative_tags else 0.0
	pressure -= 0.12 if "institution_quality" in narrative_tags else 0.0
	return clamp(pressure, 0.0, 1.0)


func _chart_cycle_template_for(
	archetype: String,
	bias: String,
	operator_pressure: float,
	story_heat: float,
	float_tightness: float,
	rng: RandomNumberGenerator
) -> String:
	var roll: float = rng.randf()
	if operator_pressure >= 0.72 and roll < 0.72:
		return "operator_rug" if rng.randf() < 0.36 else "operator_markup"
	if operator_pressure >= 0.58 and roll < 0.46:
		return "operator_markup" if rng.randf() < 0.66 else "failed_markup"
	if bias == "bullish" or archetype in ["organic", "accumulation"]:
		if roll < 0.36 + story_heat * 0.18:
			return "markup_exhaustion" if operator_pressure + float_tightness > 1.10 and rng.randf() < 0.34 else "markup_clean"
	if bias == "bearish" or archetype in ["distribution", "distressed"]:
		if roll < 0.34 + story_heat * 0.12:
			return "distribution_clean"
	if bias == "transition" and roll < 0.24 + operator_pressure * 0.16:
		return "failed_markup" if rng.randf() < 0.54 else "markup_exhaustion"
	return ""


func _chart_fib_profile_for(cycle_template: String, operator_pressure: float, rng: RandomNumberGenerator) -> String:
	match cycle_template:
		"operator_markup":
			return "fib_operator"
		"operator_rug":
			return "fib_rug"
		"markup_exhaustion", "failed_markup":
			return "fib_deep" if rng.randf() < 0.54 + operator_pressure * 0.20 else "fib_classic"
		"distribution_clean":
			return "fib_classic" if rng.randf() < 0.62 else "fib_shallow"
		"markup_clean":
			return ["fib_shallow", "fib_classic", "fib_deep"][rng.randi_range(0, 2)]
	return ""


func _chart_cycle_strength_for(
	cycle_template: String,
	operator_pressure: float,
	story_heat: float,
	float_tightness: float,
	rng: RandomNumberGenerator
) -> float:
	if cycle_template.is_empty():
		return 0.0
	var base_strength: float = 0.42 + story_heat * 0.20 + float_tightness * 0.14 + rng.randf_range(-0.06, 0.14)
	if cycle_template.begins_with("operator"):
		base_strength += operator_pressure * 0.28
	elif cycle_template in ["markup_exhaustion", "failed_markup"]:
		base_strength += operator_pressure * 0.12
	return clamp(base_strength, 0.25, 1.0)


func _chart_tempo_profile_for(
	archetype: String,
	bias: String,
	narrative_tags: Array,
	cycle_template: String,
	operator_pressure: float,
	story_heat: float,
	liquidity_profile: float,
	quality_core: float,
	rng: RandomNumberGenerator
) -> String:
	if cycle_template.is_empty():
		return "normal_setup"
	if cycle_template == "failed_markup":
		return "failed_setup" if rng.randf() < 0.72 else "normal_setup"
	if cycle_template.begins_with("operator") or archetype == "gorengan":
		if operator_pressure >= 0.50 or story_heat >= 0.68 or rng.randf() < 0.58:
			return "fast_operator"
	if quality_core >= 0.64 and liquidity_profile >= 0.54 and operator_pressure <= 0.42:
		return "slow_setup" if rng.randf() < 0.70 else "normal_setup"
	if "institution_quality" in narrative_tags and liquidity_profile >= 0.48 and operator_pressure <= 0.50:
		return "slow_setup" if rng.randf() < 0.54 else "normal_setup"
	if liquidity_profile <= 0.34 and story_heat >= 0.58 and rng.randf() < 0.44:
		return "fast_operator"
	if bias == "transition" and story_heat >= 0.62 and rng.randf() < 0.32:
		return "failed_setup"
	return "normal_setup"


func _chart_shakeout_profile_for(
	cycle_template: String,
	cycle_tempo_profile: String,
	operator_pressure: float,
	story_heat: float,
	float_tightness: float,
	rng: RandomNumberGenerator
) -> String:
	if cycle_template.is_empty():
		return "none"
	match cycle_template:
		"operator_rug":
			return "failed_reclaim" if rng.randf() < 0.48 else "hard_shakeout"
		"operator_markup":
			return "hard_shakeout" if operator_pressure + float_tightness > 1.05 or rng.randf() < 0.62 else "healthy_pullback"
		"failed_markup":
			return "failed_reclaim"
		"distribution_clean":
			return "dead_cat"
		"markup_exhaustion":
			return "hard_shakeout" if operator_pressure + story_heat + float_tightness > 1.55 or rng.randf() < 0.38 else "healthy_pullback"
		"markup_clean":
			if cycle_tempo_profile == "slow_setup" and operator_pressure < 0.36:
				return "healthy_pullback"
			return "hard_shakeout" if operator_pressure > 0.62 and rng.randf() < 0.46 else "healthy_pullback"
	return "none"


func _chart_microstructure_intensity_for(
	cycle_template: String,
	cycle_tempo_profile: String,
	shakeout_profile: String,
	cycle_strength: float,
	operator_pressure: float,
	story_heat: float,
	float_tightness: float,
	liquidity_profile: float,
	rng: RandomNumberGenerator
) -> float:
	if cycle_template.is_empty() or shakeout_profile == "none":
		return 0.0
	var intensity: float = 0.18 + cycle_strength * 0.24
	intensity += operator_pressure * 0.18
	intensity += story_heat * 0.12
	intensity += float_tightness * 0.10
	intensity += (1.0 - liquidity_profile) * 0.08
	match cycle_tempo_profile:
		"slow_setup":
			intensity -= 0.08
		"fast_operator":
			intensity += 0.10
		"failed_setup":
			intensity += 0.08
	match shakeout_profile:
		"healthy_pullback":
			intensity += 0.03
		"hard_shakeout":
			intensity += 0.11
		"dead_cat":
			intensity += 0.08
		"failed_reclaim":
			intensity += 0.10
	intensity += rng.randf_range(-0.035, 0.055)
	return clamp(intensity, 0.12, 0.88)


func _chart_setup_duration_bias_for(
	cycle_tempo_profile: String,
	cycle_template: String,
	liquidity_profile: float,
	operator_pressure: float,
	rng: RandomNumberGenerator
) -> float:
	var bias: float = 0.0
	match cycle_tempo_profile:
		"slow_setup":
			bias = 0.46
		"fast_operator":
			bias = -0.54
		"failed_setup":
			bias = 0.16
	if cycle_template.begins_with("operator"):
		bias -= 0.18 + operator_pressure * 0.16
	bias += (liquidity_profile - 0.50) * 0.26
	bias -= operator_pressure * 0.12
	bias += rng.randf_range(-0.07, 0.07)
	return clamp(bias, -0.82, 0.82)


func _chart_bar_friction_profile_for(
	archetype: String,
	bias: String,
	narrative_tags: Array,
	cycle_template: String,
	cycle_tempo_profile: String,
	operator_pressure: float,
	story_heat: float,
	liquidity_profile: float,
	float_tightness: float,
	rng: RandomNumberGenerator
) -> String:
	if cycle_template == "distribution_clean" or bias == "bearish" or archetype in ["distribution", "distressed"]:
		return "distribution_chop"
	if cycle_template.begins_with("operator") or archetype == "gorengan" or operator_pressure >= 0.62:
		return "operator_dirty"
	if cycle_tempo_profile == "fast_operator" or (float_tightness >= 0.66 and story_heat >= 0.54 and liquidity_profile <= 0.48):
		return "operator_dirty" if rng.randf() < 0.66 else "balanced_chop"
	if ("institution_quality" in narrative_tags or "supportive_balance_sheet" in narrative_tags) and liquidity_profile >= 0.58 and operator_pressure <= 0.38:
		return "clean_liquid"
	if liquidity_profile >= 0.68 and float_tightness <= 0.38 and story_heat <= 0.56:
		return "clean_liquid" if rng.randf() < 0.72 else "balanced_chop"
	return "balanced_chop"


func _chart_microleg_frequency_bias_for(
	bar_friction_profile: String,
	cycle_tempo_profile: String,
	operator_pressure: float,
	story_heat: float,
	liquidity_profile: float,
	float_tightness: float,
	rng: RandomNumberGenerator
) -> float:
	var bias: float = 0.44
	match bar_friction_profile:
		"clean_liquid":
			bias = 0.28
		"balanced_chop":
			bias = 0.56
		"operator_dirty":
			bias = 0.76
		"distribution_chop":
			bias = 0.66
	if cycle_tempo_profile == "fast_operator":
		bias += 0.10
	elif cycle_tempo_profile == "slow_setup":
		bias -= 0.06
	bias += operator_pressure * 0.10
	bias += story_heat * 0.06
	bias += float_tightness * 0.06
	bias -= liquidity_profile * 0.08
	bias += rng.randf_range(-0.04, 0.04)
	return clamp(bias, 0.12, 0.92)


func _chart_wick_noise_intensity_for(
	bar_friction_profile: String,
	operator_pressure: float,
	story_heat: float,
	float_tightness: float,
	liquidity_profile: float,
	rng: RandomNumberGenerator
) -> float:
	var intensity: float = 0.30
	match bar_friction_profile:
		"clean_liquid":
			intensity = 0.14
		"balanced_chop":
			intensity = 0.32
		"operator_dirty":
			intensity = 0.52
		"distribution_chop":
			intensity = 0.42
	intensity += operator_pressure * 0.10
	intensity += story_heat * 0.04
	intensity += float_tightness * 0.05
	intensity -= liquidity_profile * 0.06
	intensity += rng.randf_range(-0.035, 0.045)
	return clamp(intensity, 0.08, 0.78)


func _chart_volume_disagreement_rate_for(
	bar_friction_profile: String,
	operator_pressure: float,
	story_heat: float,
	liquidity_profile: float,
	rng: RandomNumberGenerator
) -> float:
	var rate: float = 0.28
	match bar_friction_profile:
		"clean_liquid":
			rate = 0.18
		"balanced_chop":
			rate = 0.38
		"operator_dirty":
			rate = 0.56
		"distribution_chop":
			rate = 0.48
	rate += operator_pressure * 0.12
	rate += story_heat * 0.06
	rate -= liquidity_profile * 0.04
	rate += rng.randf_range(-0.035, 0.045)
	return clamp(rate, 0.08, 0.84)


func _chart_tape_regime_profile_for(
	archetype: String,
	bias: String,
	cycle_template: String,
	cycle_tempo_profile: String,
	bar_friction_profile: String,
	operator_pressure: float,
	story_heat: float,
	liquidity_profile: float,
	float_tightness: float,
	rng: RandomNumberGenerator
) -> String:
	if cycle_template == "failed_markup":
		return "failed_reclaim"
	if cycle_template == "distribution_clean" or bias == "bearish" or archetype in ["distribution", "distressed"]:
		return "distribution_breakdown"
	if cycle_template.begins_with("operator") or bar_friction_profile == "operator_dirty" or archetype == "gorengan" or operator_pressure >= 0.62:
		return "operator_campaign"
	if cycle_template in ["markup_clean", "markup_exhaustion"] or archetype in ["accumulation", "organic", "cyclical"]:
		if liquidity_profile >= 0.64 and float_tightness <= 0.42 and operator_pressure <= 0.34 and rng.randf() < 0.54:
			return "clean_trend"
		return "messy_accumulation"
	if cycle_tempo_profile == "slow_setup" and liquidity_profile >= 0.58 and story_heat <= 0.58:
		return "clean_trend"
	return "messy_accumulation" if rng.randf() < 0.62 + story_heat * 0.14 else "clean_trend"


func _chart_regime_block_intensity_for(
	tape_regime_profile: String,
	cycle_strength: float,
	microstructure_intensity: float,
	operator_pressure: float,
	story_heat: float,
	liquidity_profile: float,
	rng: RandomNumberGenerator
) -> float:
	var intensity: float = 0.44
	match tape_regime_profile:
		"clean_trend":
			intensity = 0.26
		"messy_accumulation":
			intensity = 0.48
		"operator_campaign":
			intensity = 0.62
		"distribution_breakdown":
			intensity = 0.54
		"failed_reclaim":
			intensity = 0.56
	intensity += cycle_strength * 0.06
	intensity += microstructure_intensity * 0.08
	intensity += operator_pressure * 0.08
	intensity += story_heat * 0.04
	intensity -= liquidity_profile * 0.05
	intensity += rng.randf_range(-0.035, 0.045)
	return clamp(intensity, 0.12, 0.78)


func _chart_regime_tempo_bias_for(
	tape_regime_profile: String,
	cycle_tempo_profile: String,
	setup_duration_bias: float,
	operator_pressure: float,
	liquidity_profile: float,
	rng: RandomNumberGenerator
) -> float:
	var tempo_bias: float = setup_duration_bias * 0.72
	match cycle_tempo_profile:
		"slow_setup":
			tempo_bias += 0.20
		"fast_operator":
			tempo_bias -= 0.24
		"failed_setup":
			tempo_bias += 0.08
	match tape_regime_profile:
		"clean_trend":
			tempo_bias += 0.10 + liquidity_profile * 0.06
		"operator_campaign":
			tempo_bias -= 0.18 + operator_pressure * 0.12
		"distribution_breakdown", "failed_reclaim":
			tempo_bias -= 0.04
	tempo_bias += rng.randf_range(-0.055, 0.055)
	return clamp(tempo_bias, -0.86, 0.86)


func _chart_cycle_phase_bias(cycle_template: String) -> String:
	match cycle_template:
		"markup_clean", "operator_markup":
			return "accumulation_to_markup"
		"markup_exhaustion":
			return "late_markup"
		"distribution_clean":
			return "distribution"
		"failed_markup":
			return "failed_breakout"
		"operator_rug":
			return "operator_distribution"
	return ""


func _chart_fib_ratios_for_profile(fib_profile_id: String) -> Dictionary:
	if not CHART_FIB_PROFILES.has(fib_profile_id):
		return {}
	return (CHART_FIB_PROFILES[fib_profile_id] as Dictionary).duplicate(true)


func _chart_pattern_pool_for(archetype: String, bias: String) -> Array:
	if archetype == "gorengan":
		return GORENGAN_CHART_PATTERNS.duplicate()
	if bias == "bullish":
		return BULLISH_CHART_PATTERNS.duplicate()
	if bias == "bearish":
		return BEARISH_CHART_PATTERNS.duplicate()
	if archetype == "accumulation":
		return ["higher_low_accumulation", "rounded_base", "ascending_triangle", "breakout_retest"]
	if archetype == "distribution":
		return ["lower_high_distribution", "double_top", "failed_breakout", "descending_triangle"]
	if bias == "transition":
		return ["rounded_base", "double_bottom", "failed_breakout", "breakout_retest", "double_top"]
	return ["messy_range", "false_breakout", "ascending_triangle", "descending_triangle"]


func _chart_pattern_variant_for(
	pattern_id: String,
	archetype: String,
	bias: String,
	rng: RandomNumberGenerator
) -> String:
	var options: Array = _chart_pattern_variant_options(pattern_id, archetype, bias)
	if options.is_empty():
		return "standard"
	var total_weight: float = 0.0
	for option_value in options:
		var option: Dictionary = option_value
		total_weight += max(float(option.get("weight", 1.0)), 0.0)
	if total_weight <= 0.0:
		var fallback_option: Dictionary = options[0]
		return str(fallback_option.get("id", "standard"))
	var roll: float = rng.randf_range(0.0, total_weight)
	var cursor: float = 0.0
	for option_value in options:
		var option: Dictionary = option_value
		cursor += max(float(option.get("weight", 1.0)), 0.0)
		if roll <= cursor:
			return str(option.get("id", "standard"))
	var last_option: Dictionary = options[options.size() - 1]
	return str(last_option.get("id", "standard"))


func _chart_pattern_variant_ids(pattern_id: String, archetype: String, bias: String) -> Array:
	var ids: Array = []
	for option_value in _chart_pattern_variant_options(pattern_id, archetype, bias):
		var option: Dictionary = option_value
		ids.append(str(option.get("id", "standard")))
	return ids


func _chart_pattern_variant_options(pattern_id: String, archetype: String, bias: String) -> Array:
	var bullish_weight: float = 1.0 if bias == "bullish" else 0.0
	var bearish_weight: float = 1.0 if bias == "bearish" else 0.0
	var transition_weight: float = 1.0 if bias == "transition" else 0.0
	var sideways_weight: float = 1.0 if bias == "sideways" else 0.0
	var gorengan_weight: float = 1.0 if archetype == "gorengan" else 0.0
	match pattern_id:
		"double_bottom":
			return [
				{"id": "breakout_retest_continue", "weight": 5.0 + (bullish_weight * 5.0)},
				{"id": "measured_breakout", "weight": 2.4 + (bullish_weight * 2.8)},
				{"id": "undercut_spring", "weight": 2.2 + (transition_weight * 1.6)},
				{"id": "base_no_breakout", "weight": 1.4 + (sideways_weight * 3.2)},
				{"id": "failed_breakout", "weight": 0.8 + (transition_weight * 2.0) + (sideways_weight * 1.4)}
			]
		"inverse_head_shoulders":
			return [
				{"id": "neckline_break_retest", "weight": 4.8 + (bullish_weight * 4.2)},
				{"id": "right_shoulder_shakeout", "weight": 2.4 + (transition_weight * 1.4)},
				{"id": "slow_neckline_grind", "weight": 2.2},
				{"id": "failed_neckline", "weight": 0.8 + (sideways_weight * 2.4) + (transition_weight * 1.2)}
			]
		"cup_handle":
			return [
				{"id": "clean_handle_breakout", "weight": 4.8 + (bullish_weight * 4.0)},
				{"id": "deep_cup_shallow_handle", "weight": 2.4},
				{"id": "long_handle_grind", "weight": 2.0 + (sideways_weight * 1.2)},
				{"id": "failed_handle", "weight": 0.8 + (transition_weight * 2.0)}
			]
		"ascending_triangle":
			return [
				{"id": "flat_top_breakout", "weight": 4.4 + (bullish_weight * 3.8)},
				{"id": "tight_coil", "weight": 2.4 + (sideways_weight * 1.8)},
				{"id": "throwback_retest", "weight": 2.2 + (bullish_weight * 1.0)},
				{"id": "fake_breakout", "weight": 1.0 + (transition_weight * 2.2) + (gorengan_weight * 2.0)}
			]
		"rounded_base":
			return [
				{"id": "quiet_saucer_breakout", "weight": 4.4 + (bullish_weight * 3.0)},
				{"id": "long_accumulation_base", "weight": 3.0},
				{"id": "sleepy_base", "weight": 1.8 + (sideways_weight * 2.4)},
				{"id": "base_failure", "weight": 0.8 + (transition_weight * 1.8)}
			]
		"bull_flag":
			return [
				{"id": "shallow_flag_continue", "weight": 4.8 + (bullish_weight * 4.0)},
				{"id": "high_tight_flag", "weight": 2.2 + (gorengan_weight * 1.4)},
				{"id": "deep_flag_recovery", "weight": 1.8},
				{"id": "failed_flag", "weight": 0.8 + (transition_weight * 2.0)}
			]
		"breakout_retest":
			return [
				{"id": "clean_retest_continue", "weight": 5.0 + (bullish_weight * 3.6)},
				{"id": "deep_retest_hold", "weight": 2.4},
				{"id": "stair_step_retest", "weight": 2.0},
				{"id": "failed_retest", "weight": 0.8 + (transition_weight * 2.2) + (sideways_weight * 1.2)}
			]
		"higher_low_accumulation":
			return [
				{"id": "orderly_stair_step", "weight": 4.4 + (bullish_weight * 2.6)},
				{"id": "shakeout_then_markup", "weight": 2.6},
				{"id": "quiet_absorption", "weight": 2.2 + (sideways_weight * 1.2)},
				{"id": "failed_accumulation", "weight": 0.8 + (transition_weight * 2.0)}
			]
		"double_top":
			return [
				{"id": "neckline_break_continue", "weight": 4.8 + (bearish_weight * 4.0)},
				{"id": "second_top_lower", "weight": 2.4},
				{"id": "range_top_chop", "weight": 1.8 + (sideways_weight * 2.2)},
				{"id": "failed_breakdown", "weight": 0.8 + (transition_weight * 2.2)}
			]
		"head_shoulders":
			return [
				{"id": "clean_neckline_break", "weight": 4.8 + (bearish_weight * 4.0)},
				{"id": "right_shoulder_chop", "weight": 2.2},
				{"id": "slanted_neckline", "weight": 2.0},
				{"id": "failed_breakdown", "weight": 0.8 + (transition_weight * 2.0)}
			]
		"descending_triangle":
			return [
				{"id": "flat_floor_breakdown", "weight": 4.6 + (bearish_weight * 3.8)},
				{"id": "tight_floor_pressure", "weight": 2.4 + (sideways_weight * 1.6)},
				{"id": "breakdown_retest", "weight": 2.2},
				{"id": "bear_trap_reclaim", "weight": 0.8 + (transition_weight * 2.0)}
			]
		"lower_high_distribution":
			return [
				{"id": "orderly_distribution", "weight": 4.2 + (bearish_weight * 2.8)},
				{"id": "fast_distribution", "weight": 2.4},
				{"id": "range_distribution", "weight": 2.0 + (sideways_weight * 1.6)},
				{"id": "failed_distribution", "weight": 0.8 + (transition_weight * 2.0)}
			]
		"failed_breakout":
			return [
				{"id": "classic_bull_trap", "weight": 4.0 + (bearish_weight * 2.4)},
				{"id": "double_fakeout", "weight": 2.6 + (gorengan_weight * 1.6)},
				{"id": "late_failed_breakout", "weight": 2.0},
				{"id": "failed_then_recovery", "weight": 0.8 + (transition_weight * 2.0)}
			]
		"breakdown_retest":
			return [
				{"id": "breakdown_reject_continue", "weight": 4.6 + (bearish_weight * 3.4)},
				{"id": "deep_retest_reject", "weight": 2.4},
				{"id": "grind_lower", "weight": 2.0},
				{"id": "failed_breakdown_reclaim", "weight": 0.8 + (transition_weight * 2.2)}
			]
		"sma_resistance_rejection":
			return [
				{"id": "single_clean_rejection", "weight": 3.8 + (bearish_weight * 2.8)},
				{"id": "repeated_rejections", "weight": 3.0},
				{"id": "rolling_lower_sma", "weight": 2.0},
				{"id": "sma_reclaim", "weight": 0.8 + (transition_weight * 2.0)}
			]
		"pump_dump":
			return [
				{"id": "early_pump_dump", "weight": 2.6},
				{"id": "late_pump_dump", "weight": 2.6},
				{"id": "stair_pump_dump", "weight": 2.0},
				{"id": "multi_spike_dump", "weight": 1.8}
			]
		"false_breakout":
			return [
				{"id": "single_false_breakout", "weight": 2.8},
				{"id": "double_false_breakout", "weight": 2.4},
				{"id": "range_whipsaw", "weight": 2.2},
				{"id": "spring_reclaim", "weight": 1.4}
			]
		"sharp_squeeze":
			return [
				{"id": "squeeze_hold", "weight": 2.8},
				{"id": "squeeze_fade", "weight": 2.6},
				{"id": "late_squeeze", "weight": 2.2},
				{"id": "two_leg_squeeze", "weight": 1.6}
			]
		"rug_pull_volume":
			return [
				{"id": "classic_rug_pull", "weight": 2.8},
				{"id": "delayed_rug_pull", "weight": 2.4},
				{"id": "stair_step_rug", "weight": 2.0},
				{"id": "rebound_after_rug", "weight": 1.4}
			]
		"messy_range":
			return [
				{"id": "wide_range", "weight": 2.6},
				{"id": "tightening_range", "weight": 2.4},
				{"id": "shakeout_range", "weight": 2.2},
				{"id": "range_break_fake", "weight": 1.8}
			]
	return [{"id": "standard", "weight": 1.0}]


func _chart_intent_for(
	archetype: String,
	bias: String,
	quality_core: float,
	growth_engine: float,
	story_heat: float,
	float_tightness: float,
	cyclicality: float,
	rng: RandomNumberGenerator
) -> String:
	var candidates: Array = []
	match archetype:
		"funda":
			candidates = [
				{"id": "investing", "weight": 5.2 + quality_core},
				{"id": "swing_trading", "weight": 1.2 + growth_engine * 0.4},
				{"id": "short_term_trading", "weight": story_heat * 0.25},
				{"id": "speculative", "weight": 0.05}
			]
		"organic":
			candidates = [
				{"id": "investing", "weight": 2.5 + quality_core * 1.5},
				{"id": "swing_trading", "weight": 2.1 + growth_engine + story_heat * 0.4},
				{"id": "short_term_trading", "weight": story_heat * 0.55},
				{"id": "speculative", "weight": 0.08}
			]
		"accumulation":
			candidates = [
				{"id": "swing_trading", "weight": 4.0 + growth_engine * 0.8},
				{"id": "investing", "weight": 1.2 + quality_core},
				{"id": "short_term_trading", "weight": 1.1 + story_heat * 0.8},
				{"id": "speculative", "weight": max(story_heat + float_tightness - 1.16, 0.0) * 0.55}
			]
		"cyclical":
			candidates = [
				{"id": "swing_trading", "weight": 4.2 + cyclicality},
				{"id": "investing", "weight": 0.8 + quality_core * 0.7},
				{"id": "short_term_trading", "weight": 1.1 + story_heat * 0.5},
				{"id": "speculative", "weight": 0.08 + max(cyclicality - 0.78, 0.0) * 0.45}
			]
		"gorengan":
			candidates = [
				{"id": "short_term_trading", "weight": 4.2 + story_heat * 0.7},
				{"id": "speculative", "weight": 1.6 + max(story_heat + float_tightness - 1.12, 0.0) * 2.0},
				{"id": "swing_trading", "weight": 0.9},
				{"id": "investing", "weight": 0.08}
			]
		"distressed", "distribution":
			candidates = [
				{"id": "short_term_trading", "weight": 2.8 + story_heat * 0.5},
				{"id": "swing_trading", "weight": 2.4 + cyclicality * 0.6},
				{"id": "speculative", "weight": 0.35 + (0.25 if bias == "bearish" else 0.0)},
				{"id": "investing", "weight": 0.20 + quality_core * 0.3}
			]
		_:
			candidates = [
				{"id": "swing_trading", "weight": 1.8},
				{"id": "investing", "weight": 1.0 + quality_core * 0.6},
				{"id": "short_term_trading", "weight": 1.0 + story_heat * 0.4},
				{"id": "speculative", "weight": 0.06 + float_tightness * 0.10}
			]
	return _chart_weighted_pick(candidates, rng, "swing_trading")


func _chart_pattern_timeframe_for(
	chart_intent: String,
	archetype: String,
	bias: String,
	rng: RandomNumberGenerator
) -> String:
	var candidates: Array = []
	match chart_intent:
		"investing":
			candidates = [
				{"id": "5y", "weight": 2.9 if archetype == "funda" else 1.7},
				{"id": "1y", "weight": 2.2}
			]
		"swing_trading":
			candidates = [
				{"id": "6m", "weight": 2.7},
				{"id": "1y", "weight": 2.0},
				{"id": "3m", "weight": 0.55},
				{"id": "5y", "weight": 0.25}
			]
		"short_term_trading":
			candidates = [
				{"id": "3m", "weight": 2.6},
				{"id": "1m", "weight": 1.6},
				{"id": "6m", "weight": 1.1}
			]
		"speculative":
			candidates = [
				{"id": "1m", "weight": 2.5},
				{"id": "3m", "weight": 2.2},
				{"id": "6m", "weight": 0.45}
			]
		_:
			candidates = [{"id": "1y", "weight": 1.0}, {"id": "6m", "weight": 1.0}]
	if archetype == "gorengan":
		candidates.append({"id": "1m", "weight": 1.0})
	if bias == "sideways":
		candidates.append({"id": "6m", "weight": 0.6})
	return _chart_weighted_pick(candidates, rng, "1y")


func _chart_gap_profile_for(
	chart_intent: String,
	archetype: String,
	bias: String,
	volatility_style: String,
	story_heat: float,
	float_tightness: float,
	quality_core: float,
	rng: RandomNumberGenerator
) -> Dictionary:
	var style_candidates: Array = [{"id": "none", "weight": 1.0}]
	var frequency_candidates: Array = [{"id": "rare", "weight": 1.0}]
	var follow_candidates: Array = [{"id": "fill", "weight": 1.0}]
	var gap_bias: String = "mixed"
	if chart_intent == "investing" or archetype == "funda":
		style_candidates = [
			{"id": "news_gap", "weight": 2.2 + quality_core},
			{"id": "breakout_gap", "weight": 0.7 if bias == "bullish" else 0.2},
			{"id": "none", "weight": 1.8}
		]
		frequency_candidates = [{"id": "rare", "weight": 4.0}, {"id": "moderate", "weight": 0.7}]
		follow_candidates = [{"id": "hold", "weight": 2.0}, {"id": "continue", "weight": 1.0}, {"id": "fill", "weight": 1.0}]
		gap_bias = "up" if bias == "bullish" else "mixed"
	elif archetype == "gorengan" or chart_intent == "speculative":
		style_candidates = [
			{"id": "mixed", "weight": 2.4},
			{"id": "rug_gap", "weight": 1.6},
			{"id": "breakout_gap", "weight": 1.3},
			{"id": "exhaustion_gap", "weight": 0.9}
		]
		frequency_candidates = [
			{"id": "moderate", "weight": 2.6},
			{"id": "active", "weight": 0.45 + max(story_heat + float_tightness - 1.35, 0.0) * 3.0},
			{"id": "rare", "weight": 0.35}
		]
		follow_candidates = [{"id": "fade", "weight": 2.4}, {"id": "fill", "weight": 1.8}, {"id": "continue", "weight": 0.9}]
		gap_bias = "mixed"
	elif volatility_style == "spiky":
		style_candidates = [
			{"id": "mixed", "weight": 1.4},
			{"id": "breakout_gap", "weight": 0.8 if bias == "bullish" else 0.35},
			{"id": "exhaustion_gap", "weight": 0.75 if bias == "bearish" else 0.35},
			{"id": "none", "weight": 0.7}
		]
		frequency_candidates = [{"id": "moderate", "weight": 1.9}, {"id": "rare", "weight": 1.2}, {"id": "active", "weight": 0.20}]
		follow_candidates = [{"id": "fill", "weight": 1.6}, {"id": "fade", "weight": 1.2}, {"id": "hold", "weight": 0.8}]
		gap_bias = "mixed"
	elif bias == "bullish" or archetype == "accumulation":
		style_candidates = [
			{"id": "breakout_gap", "weight": 2.5 + story_heat},
			{"id": "news_gap", "weight": 1.0},
			{"id": "mixed", "weight": 0.4},
			{"id": "none", "weight": 0.5}
		]
		frequency_candidates = [{"id": "moderate", "weight": 2.5}, {"id": "rare", "weight": 1.2}]
		follow_candidates = [{"id": "hold", "weight": 2.2}, {"id": "continue", "weight": 1.6}, {"id": "fill", "weight": 0.8}]
		gap_bias = "up"
	elif bias == "bearish" or archetype in ["distressed", "distribution"]:
		style_candidates = [
			{"id": "exhaustion_gap", "weight": 1.8},
			{"id": "rug_gap", "weight": 1.6 + float_tightness * 0.6},
			{"id": "mixed", "weight": 0.8},
			{"id": "none", "weight": 0.35}
		]
		frequency_candidates = [{"id": "moderate", "weight": 2.1}, {"id": "active", "weight": 0.25}, {"id": "rare", "weight": 1.0}]
		follow_candidates = [{"id": "fade", "weight": 1.8}, {"id": "fill", "weight": 1.6}, {"id": "continue", "weight": 1.0}]
		gap_bias = "down"
	else:
		style_candidates = [
			{"id": "mixed", "weight": 1.2 + story_heat * 0.5},
			{"id": "news_gap", "weight": 0.9},
			{"id": "none", "weight": 1.0}
		]
		frequency_candidates = [{"id": "rare", "weight": 1.8}, {"id": "moderate", "weight": 1.0}]
		follow_candidates = [{"id": "fill", "weight": 1.8}, {"id": "fade", "weight": 0.8}, {"id": "hold", "weight": 0.6}]
		gap_bias = "mixed"
	return {
		"gap_style": _chart_weighted_pick(style_candidates, rng, "none"),
		"gap_bias": gap_bias,
		"gap_frequency": _chart_weighted_pick(frequency_candidates, rng, "rare"),
		"gap_followthrough": _chart_weighted_pick(follow_candidates, rng, "fill")
	}


func _chart_weighted_pick(candidates: Array, rng: RandomNumberGenerator, fallback: String) -> String:
	var total_weight: float = 0.0
	for candidate_value in candidates:
		if typeof(candidate_value) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = candidate_value
		total_weight += max(float(candidate.get("weight", 1.0)), 0.0)
	if total_weight <= 0.0:
		return fallback
	var roll: float = rng.randf_range(0.0, total_weight)
	var cursor: float = 0.0
	for candidate_value in candidates:
		if typeof(candidate_value) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = candidate_value
		cursor += max(float(candidate.get("weight", 1.0)), 0.0)
		if roll <= cursor:
			return str(candidate.get("id", fallback))
	return fallback


func _chart_safe_choice(value: String, valid_values: Array, fallback: String) -> String:
	var normalized: String = str(value).strip_edges().to_lower()
	if valid_values.has(normalized):
		return normalized
	return fallback


func _chart_volatility_style(archetype: String, cyclicality: float, story_heat: float, rng: RandomNumberGenerator) -> String:
	if archetype == "gorengan" or story_heat >= 0.72:
		return "spiky"
	if archetype == "cyclical" or cyclicality >= 0.68:
		return "swingy"
	if archetype in ["organic", "funda", "accumulation"]:
		return "smooth" if rng.randf() < 0.62 else "normal"
	if archetype in ["distressed", "distribution"]:
		return "heavy"
	return "normal"


func _chart_volume_behavior(archetype: String, bias: String) -> String:
	if archetype == "gorengan":
		return "spike"
	if bias == "bullish" or archetype == "accumulation":
		return "accumulation"
	if bias == "bearish" or archetype == "distribution" or archetype == "distressed":
		return "distribution"
	return "neutral"


func _build_financial_history(
	template: Dictionary,
	sector_profile: Dictionary,
	traits: Dictionary,
	run_seed: int,
	company_id: String
) -> Array:
	var target_market_cap: float = _anchor_value(template, "market_cap", 0.0)
	if target_market_cap <= 0.0:
		target_market_cap = lerp(800000000000.0, 4200000000000.0, float(traits.get("scale", 0.5)))
	var scale_market_cap_floor: float = _anchor_value(template, "scale_market_cap_floor", 0.0)
	var scale_market_cap_ceiling: float = _anchor_value(template, "scale_market_cap_ceiling", 0.0)
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
	var minimum_revenue_floor: float = clamp(target_market_cap * 0.12, 30000000000.0, 120000000000.0)
	var target_revenue_2019: float = max(target_market_cap / price_to_sales_multiple, minimum_revenue_floor)
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
		if (
			year == HISTORY_END_YEAR and
			scale_market_cap_floor > 0.0 and
			scale_market_cap_ceiling >= scale_market_cap_floor
		):
			market_cap = clamp(market_cap, scale_market_cap_floor, scale_market_cap_ceiling)
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


func _apply_chart_profile_to_historical_bars(
	source_bars: Array,
	chart_profile: Dictionary,
	run_seed: int,
	company_id: String,
	end_price: float
) -> Array:
	if source_bars.size() < 12:
		return source_bars

	var normalized_end_price: float = IDX_PRICE_RULES.normalize_last_price(max(end_price, 1.0))
	var start_price: float = _chart_history_start_price(chart_profile, normalized_end_price, run_seed, company_id)
	var anchors: Array = _chart_shape_anchors(chart_profile)
	var pattern_window: Dictionary = _chart_pattern_timeframe_window(chart_profile, source_bars.size())
	var closes: Array = []
	var reshaped_bars: Array = []
	var previous_close: float = start_price
	var body_mismatch_direction: int = 0
	var body_mismatch_count: int = 0
	var volatility_style: String = str(chart_profile.get("volatility_style", "normal"))
	var clarity: float = clamp(float(chart_profile.get("clarity", 0.68)), 0.35, 0.92)
	var noise_scale: float = _chart_noise_scale(volatility_style) * lerp(1.20, 0.58, clarity)
	var trend_log_start: float = log(max(start_price, 1.0))
	var trend_log_end: float = log(max(normalized_end_price, 1.0))

	for bar_index in range(source_bars.size()):
		var source_bar: Dictionary = source_bars[bar_index]
		var progress: float = float(bar_index) / float(max(source_bars.size() - 1, 1))
		var trend_price: float = exp(lerp(trend_log_start, trend_log_end, progress))
		var shape_multiplier: float = _chart_profile_shape_multiplier(
			chart_profile,
			anchors,
			progress,
			bar_index,
			source_bars.size(),
			pattern_window
		)
		var wave_component: float = _chart_wave_component(chart_profile, progress, run_seed, company_id)
		var noise_component: float = _sample_noise(
			run_seed,
			company_id,
			"chart_profile_noise",
			-noise_scale,
			noise_scale,
			bar_index + 1
		)
		var micro_context: Dictionary = _chart_historical_microstructure_context(
			chart_profile,
			progress,
			bar_index,
			source_bars.size(),
			pattern_window,
			run_seed,
			company_id
		)
		var close_price: float = trend_price * shape_multiplier * float(micro_context.get("price_multiplier", 1.0)) * (1.0 + wave_component + noise_component)
		var regime_context: Dictionary = _chart_tape_regime_context(
			chart_profile,
			progress,
			bar_index,
			source_bars.size(),
			pattern_window,
			run_seed,
			company_id,
			previous_close,
			close_price,
			closes
		)
		close_price *= float(regime_context.get("price_multiplier", 1.0))
		var close_blend_to_previous: float = float(regime_context.get("close_blend_to_previous", 0.0))
		if close_blend_to_previous > 0.0:
			var previous_close_anchor: float = previous_close * (1.0 + float(regime_context.get("previous_close_bias", 0.0)))
			close_price = lerp(close_price, previous_close_anchor, close_blend_to_previous)
		var friction_context: Dictionary = _chart_daily_tape_friction_context(
			chart_profile,
			progress,
			bar_index,
			source_bars.size(),
			pattern_window,
			run_seed,
			company_id,
			previous_close,
			close_price,
			closes
		)
		close_price *= float(friction_context.get("price_multiplier", 1.0))
		close_price = _apply_chart_sma_behavior(close_price, closes, chart_profile, progress)
		if bar_index == 0:
			close_price = start_price
		if bar_index == source_bars.size() - 1:
			close_price = normalized_end_price
		close_price = IDX_PRICE_RULES.normalize_last_price(max(close_price, 1.0))

		var gap_ratio: float = _chart_historical_gap_ratio(
			chart_profile,
			bar_index,
			source_bars.size(),
			pattern_window,
			run_seed,
			company_id
		)
		if not is_zero_approx(gap_ratio):
			close_price = _chart_apply_gap_followthrough(close_price, previous_close, gap_ratio, chart_profile)
			if bar_index == source_bars.size() - 1:
				close_price = normalized_end_price
			close_price = IDX_PRICE_RULES.normalize_last_price(max(close_price, 1.0))

		var ar_limits: Dictionary = IDX_PRICE_RULES.auto_rejection_limits(previous_close, "main")
		var remaining_bars: int = max(source_bars.size() - bar_index - 1, 0)
		close_price = _chart_clamp_historical_close(
			close_price,
			previous_close,
			normalized_end_price,
			remaining_bars,
			ar_limits
		)
		var open_price: float = previous_close
		if not is_zero_approx(gap_ratio):
			open_price = IDX_PRICE_RULES.normalize_last_price(max(previous_close * (1.0 + gap_ratio), 1.0))
		open_price = _chart_clamp_historical_price(open_price, ar_limits)
		var body_context: Dictionary = _chart_reconcile_historical_body_intent(
			chart_profile,
			micro_context,
			regime_context,
			friction_context,
			previous_close,
			open_price,
			close_price,
			normalized_end_price,
			remaining_bars,
			ar_limits,
			gap_ratio,
			bar_index,
			run_seed,
			company_id,
			body_mismatch_direction,
			body_mismatch_count
		)
		open_price = float(body_context.get("open", open_price))
		close_price = float(body_context.get("close", close_price))
		var intended_body_direction: int = int(body_context.get("intended_direction", 0))
		var actual_body_direction: int = _chart_direction_for_delta(close_price - open_price)
		if intended_body_direction != 0 and actual_body_direction != 0 and actual_body_direction != intended_body_direction:
			if body_mismatch_direction == intended_body_direction:
				body_mismatch_count += 1
			else:
				body_mismatch_direction = intended_body_direction
				body_mismatch_count = 1
		else:
			body_mismatch_direction = 0
			body_mismatch_count = 0
		var day_move_ratio: float = absf(close_price - open_price) / max(open_price, 1.0)
		var range_ratio: float = _chart_intraday_range_ratio(chart_profile, day_move_ratio, run_seed, company_id, bar_index)
		range_ratio *= float(micro_context.get("range_multiplier", 1.0))
		range_ratio *= float(regime_context.get("range_multiplier", 1.0))
		range_ratio *= float(friction_context.get("range_multiplier", 1.0))
		range_ratio = min(range_ratio, _chart_daily_range_cap(chart_profile))
		var high_price: float = IDX_PRICE_RULES.normalize_last_price(max(
			max(open_price, close_price) * (1.0 + range_ratio * 0.62),
			max(open_price, close_price)
		))
		var low_price: float = IDX_PRICE_RULES.normalize_last_price(min(
			min(open_price, close_price) * max(1.0 - range_ratio * 0.74, 0.35),
			min(open_price, close_price)
		))
		var lower_wick_bias: float = (
			float(micro_context.get("lower_wick_bias", 0.0)) +
			float(regime_context.get("lower_wick_bias", 0.0)) +
			float(friction_context.get("lower_wick_bias", 0.0))
		)
		if intended_body_direction > 0 and actual_body_direction > 0:
			lower_wick_bias *= 0.86
		lower_wick_bias = _chart_clamp_wick_bias_for_daily_profile(chart_profile, lower_wick_bias)
		if lower_wick_bias > 0.0:
			low_price = IDX_PRICE_RULES.normalize_last_price(min(
				low_price,
				min(open_price, close_price) * max(1.0 - lower_wick_bias, 0.35)
			))
		var upper_wick_bias: float = (
			float(micro_context.get("upper_wick_bias", 0.0)) +
			float(regime_context.get("upper_wick_bias", 0.0)) +
			float(friction_context.get("upper_wick_bias", 0.0))
		)
		if intended_body_direction < 0 and actual_body_direction < 0:
			upper_wick_bias *= 0.86
		upper_wick_bias = _chart_clamp_wick_bias_for_daily_profile(chart_profile, upper_wick_bias)
		if upper_wick_bias > 0.0:
			high_price = IDX_PRICE_RULES.normalize_last_price(max(
				high_price,
				max(open_price, close_price) * (1.0 + upper_wick_bias)
			))
		high_price = _chart_clamp_historical_price(max(high_price, open_price, close_price), ar_limits)
		low_price = _chart_clamp_historical_price(min(low_price, open_price, close_price), ar_limits)
		high_price = max(high_price, open_price, close_price)
		low_price = min(low_price, open_price, close_price)

		var baseline_value: float = max(float(source_bar.get("value", 0.0)), close_price * 1000.0)
		var volume_multiplier: float = _chart_volume_multiplier(
			chart_profile,
			progress,
			(close_price - open_price) / max(open_price, 1.0),
			run_seed,
			company_id,
			bar_index
		)
		volume_multiplier *= float(micro_context.get("volume_multiplier", 1.0))
		volume_multiplier *= float(regime_context.get("volume_multiplier", 1.0))
		volume_multiplier *= float(friction_context.get("volume_multiplier", 1.0))
		if absf(gap_ratio) >= 0.018:
			volume_multiplier *= _chart_gap_volume_multiplier(chart_profile, gap_ratio)
		var traded_value: float = max(baseline_value * volume_multiplier, close_price * 1000.0)
		var volume_shares: int = int(max(round(traded_value / max(close_price, 1.0) / 100.0), 1.0) * 100.0)
		var bar_value: float = close_price * float(volume_shares)
		reshaped_bars.append({
			"trade_date": source_bar.get("trade_date", {}).duplicate(true),
			"open": open_price,
			"high": high_price,
			"low": low_price,
			"close": close_price,
			"volume_shares": volume_shares,
			"value": bar_value
		})
		closes.append(close_price)
		previous_close = close_price

	return reshaped_bars


func _chart_clamp_historical_close(
	desired_close: float,
	previous_close: float,
	final_target: float,
	remaining_bars: int,
	ar_limits: Dictionary
) -> float:
	var lower_price: float = float(ar_limits.get("lower_price", max(previous_close * 0.85, 1.0)))
	var upper_price: float = float(ar_limits.get("upper_price", previous_close * 1.20))
	var close_price: float = clamp(
		IDX_PRICE_RULES.normalize_last_price(max(desired_close, 1.0)),
		lower_price,
		upper_price
	)
	if remaining_bars <= 0:
		return close_price

	var target_price: float = IDX_PRICE_RULES.normalize_last_price(max(final_target, 1.0))
	var future_up_multiplier: float = pow(1.20, float(remaining_bars))
	var future_down_multiplier: float = pow(0.85, float(remaining_bars))
	var reachable_lower: float = target_price / max(future_up_multiplier, 0.0001)
	var reachable_upper: float = target_price / max(future_down_multiplier, 0.0001)
	var min_close: float = max(lower_price, IDX_PRICE_RULES.normalize_last_price(max(reachable_lower, 1.0)))
	var max_close: float = min(upper_price, IDX_PRICE_RULES.normalize_last_price(max(reachable_upper, 1.0)))
	if min_close <= max_close:
		close_price = clamp(close_price, min_close, max_close)
	return IDX_PRICE_RULES.normalize_last_price(max(close_price, 1.0))


func _chart_clamp_historical_price(price: float, ar_limits: Dictionary) -> float:
	var lower_price: float = float(ar_limits.get("lower_price", 1.0))
	var upper_price: float = float(ar_limits.get("upper_price", max(price, 1.0)))
	return IDX_PRICE_RULES.normalize_last_price(clamp(
		IDX_PRICE_RULES.normalize_last_price(max(price, 1.0)),
		lower_price,
		upper_price
	))


func _chart_reconcile_historical_body_intent(
	chart_profile: Dictionary,
	micro_context: Dictionary,
	regime_context: Dictionary,
	friction_context: Dictionary,
	previous_close: float,
	open_price: float,
	close_price: float,
	final_target: float,
	remaining_bars: int,
	ar_limits: Dictionary,
	gap_ratio: float,
	bar_index: int,
	run_seed: int,
	company_id: String,
	mismatch_direction: int,
	mismatch_count: int
) -> Dictionary:
	var intended_direction: int = _chart_historical_body_intent_direction(
		chart_profile,
		micro_context,
		regime_context,
		friction_context,
		previous_close,
		close_price
	)
	if intended_direction == 0:
		return {
			"open": open_price,
			"close": close_price,
			"intended_direction": intended_direction
		}

	var body_direction: int = _chart_direction_for_delta(close_price - open_price)
	if body_direction == intended_direction:
		return {
			"open": open_price,
			"close": close_price,
			"intended_direction": intended_direction
		}
	var tick_size: float = IDX_PRICE_RULES.tick_size_for_reference_price(previous_close)
	if remaining_bars <= 0:
		var final_open: float = open_price
		if intended_direction > 0 and close_price <= final_open:
			final_open = _chart_clamp_historical_price(min(final_open, close_price - tick_size), ar_limits)
		elif intended_direction < 0 and close_price >= final_open:
			final_open = _chart_clamp_historical_price(max(final_open, close_price + tick_size), ar_limits)
		return {
			"open": final_open,
			"close": close_price,
			"intended_direction": intended_direction
		}
	if _chart_body_intent_allows_mismatch(
		chart_profile,
		intended_direction,
		mismatch_direction,
		mismatch_count,
		previous_close,
		open_price,
		close_price,
		gap_ratio,
		bar_index,
		run_seed,
		company_id
	):
		return {
			"open": open_price,
			"close": close_price,
			"intended_direction": intended_direction
		}

	var adjusted_open: float = open_price
	var adjusted_close: float = close_price
	if intended_direction > 0:
		if gap_ratio > 0.0 and adjusted_close >= previous_close:
			adjusted_open = _chart_clamp_historical_price(min(adjusted_open, max(previous_close, adjusted_close - tick_size)), ar_limits)
		if adjusted_close <= adjusted_open:
			adjusted_close = _chart_clamp_historical_close(
				max(adjusted_close, adjusted_open + tick_size),
				previous_close,
				final_target,
				remaining_bars,
				ar_limits
			)
		if adjusted_close <= adjusted_open:
			adjusted_open = _chart_clamp_historical_price(min(adjusted_open, adjusted_close - tick_size), ar_limits)
	elif intended_direction < 0:
		if gap_ratio < 0.0 and adjusted_close <= previous_close:
			adjusted_open = _chart_clamp_historical_price(max(adjusted_open, min(previous_close, adjusted_close + tick_size)), ar_limits)
		if adjusted_close >= adjusted_open:
			adjusted_close = _chart_clamp_historical_close(
				min(adjusted_close, adjusted_open - tick_size),
				previous_close,
				final_target,
				remaining_bars,
				ar_limits
			)
		if adjusted_close >= adjusted_open:
			adjusted_open = _chart_clamp_historical_price(max(adjusted_open, adjusted_close + tick_size), ar_limits)

	return {
		"open": _chart_clamp_historical_price(adjusted_open, ar_limits),
		"close": _chart_clamp_historical_close(adjusted_close, previous_close, final_target, remaining_bars, ar_limits),
		"intended_direction": intended_direction
	}


func _chart_historical_body_intent_direction(
	chart_profile: Dictionary,
	micro_context: Dictionary,
	regime_context: Dictionary,
	friction_context: Dictionary,
	previous_close: float,
	close_price: float
) -> int:
	var structural_ratio: float = (close_price - previous_close) / max(previous_close, 1.0)
	if absf(structural_ratio) >= 0.003:
		return _chart_direction_for_delta(structural_ratio)

	var trend_direction: int = _chart_daily_tape_trend_direction(chart_profile)
	var friction_phase: String = str(friction_context.get("phase", "calm"))
	match friction_phase:
		"reclaim", "dead_cat", "range_fakeout_up":
			return 1
		"turunin_penumpang", "lower_high", "continuation", "range_fakeout_down":
			return -1
		"run_guard":
			if trend_direction != 0:
				return -trend_direction
			return -_chart_direction_for_delta(close_price - previous_close)

	var micro_phase: String = str(micro_context.get("phase", "calm"))
	match micro_phase:
		"reclaim", "operator_run", "hope", "dead_cat":
			return 1
		"shakeout", "shelf", "rug", "failed_reclaim", "continuation":
			return -1

	var regime_phase: String = str(regime_context.get("phase", "calm"))
	match regime_phase:
		"markup":
			return 1
		"channel":
			var block_value = regime_context.get("regime_block", {})
			if typeof(block_value) == TYPE_DICTIONARY:
				var block_direction: int = int((block_value as Dictionary).get("direction", 0))
				if block_direction != 0:
					return block_direction
			return trend_direction
		"dead_cat":
			return 1
		"distribution", "breakdown", "markdown", "rug", "failed_reclaim":
			return -1

	return 0


func _chart_body_intent_allows_mismatch(
	chart_profile: Dictionary,
	intended_direction: int,
	mismatch_direction: int,
	mismatch_count: int,
	previous_close: float,
	open_price: float,
	close_price: float,
	gap_ratio: float,
	bar_index: int,
	run_seed: int,
	company_id: String
) -> bool:
	if intended_direction == 0:
		return true
	return false


func _chart_daily_range_cap(chart_profile: Dictionary) -> float:
	var cap: float = 0.026
	match str(chart_profile.get("bar_friction_profile", "balanced_chop")):
		"clean_liquid":
			cap = 0.020
		"operator_dirty":
			cap = 0.040
		"distribution_chop":
			cap = 0.032
		_:
			cap = 0.026
	cap += clamp(float(chart_profile.get("operator_pressure", 0.0)), 0.0, 1.0) * 0.004
	return clamp(cap, 0.018, 0.046)


func _chart_clamp_wick_bias_for_daily_profile(chart_profile: Dictionary, wick_bias: float) -> float:
	var cap: float = 0.018
	match str(chart_profile.get("bar_friction_profile", "balanced_chop")):
		"clean_liquid":
			cap = 0.012
		"operator_dirty":
			cap = 0.032
		"distribution_chop":
			cap = 0.024
		_:
			cap = 0.018
	cap += clamp(float(chart_profile.get("operator_pressure", 0.0)), 0.0, 1.0) * 0.004
	return clamp(wick_bias, 0.0, clamp(cap, 0.010, 0.038))


func _chart_pattern_timeframe_window(chart_profile: Dictionary, total_bars: int) -> Dictionary:
	var timeframe: String = str(chart_profile.get("pattern_timeframe", "5y")).to_lower()
	var target_count: int = _chart_timeframe_bar_count(timeframe, total_bars)
	target_count = clamp(target_count, 12, max(total_bars, 12))
	var end_index: int = max(total_bars - 1, 0)
	var start_index: int = max(end_index - target_count + 1, 0)
	return {
		"start": start_index,
		"end": end_index,
		"count": end_index - start_index + 1,
		"timeframe": timeframe
	}


func _chart_timeframe_bar_count(timeframe: String, total_bars: int) -> int:
	match str(timeframe).to_lower():
		"1m":
			return min(21, total_bars)
		"3m":
			return min(63, total_bars)
		"6m":
			return min(126, total_bars)
		"1y":
			return min(252, total_bars)
	return total_bars


func _chart_profile_shape_multiplier(
	chart_profile: Dictionary,
	anchors: Array,
	progress: float,
	bar_index: int,
	total_bars: int,
	pattern_window: Dictionary
) -> float:
	var adjusted_progress: float = _chart_tempo_adjusted_progress(chart_profile, progress)
	var full_shape: float = _interpolate_chart_shape(anchors, adjusted_progress)
	var timeframe: String = str(chart_profile.get("pattern_timeframe", "5y")).to_lower()
	if timeframe == "5y" or total_bars <= 0:
		return full_shape

	var chart_intent: String = str(chart_profile.get("chart_intent", "swing_trading"))
	var base_shape_weight: float = 0.34
	var window_shape_weight: float = 0.88
	if chart_intent == "short_term_trading":
		base_shape_weight = 0.28
		window_shape_weight = 0.88
	elif chart_intent == "speculative":
		base_shape_weight = 0.22
		window_shape_weight = 0.94
	elif chart_intent == "investing":
		base_shape_weight = 0.46
		window_shape_weight = 0.82

	var shape_multiplier: float = lerp(1.0, full_shape, base_shape_weight)
	var start_index: int = int(pattern_window.get("start", 0))
	var end_index: int = int(pattern_window.get("end", total_bars - 1))
	if bar_index < start_index or bar_index > end_index:
		return shape_multiplier

	var span: int = max(end_index - start_index, 1)
	var local_progress: float = clamp(float(bar_index - start_index) / float(span), 0.0, 1.0)
	var local_shape: float = _interpolate_chart_shape(anchors, _chart_tempo_adjusted_progress(chart_profile, local_progress))
	var edge_distance: float = float(min(bar_index - start_index, end_index - bar_index))
	var edge_width: float = max(float(span) * 0.16, 1.0)
	var edge_fade: float = clamp(edge_distance / edge_width, 0.28, 1.0)
	return shape_multiplier * lerp(1.0, local_shape, clamp(window_shape_weight * edge_fade, 0.0, 1.02))


func _chart_tempo_adjusted_progress(chart_profile: Dictionary, progress: float) -> float:
	var safe_progress: float = clamp(progress, 0.0, 1.0)
	var tempo_profile: String = str(chart_profile.get("cycle_tempo_profile", "normal_setup"))
	var duration_bias: float = clamp(float(chart_profile.get("setup_duration_bias", 0.0)), -1.0, 1.0)
	var exponent: float = 1.0
	match tempo_profile:
		"slow_setup":
			exponent = 1.28 + max(duration_bias, 0.0) * 0.34
		"fast_operator":
			exponent = 0.74 + min(duration_bias, 0.0) * 0.18
		"failed_setup":
			exponent = 1.10 + max(duration_bias, 0.0) * 0.18
		_:
			exponent = 1.0 + duration_bias * 0.14
	return clamp(pow(safe_progress, clamp(exponent, 0.56, 1.74)), 0.0, 1.0)


func _chart_historical_microstructure_context(
	chart_profile: Dictionary,
	progress: float,
	bar_index: int,
	total_bars: int,
	pattern_window: Dictionary,
	run_seed: int,
	company_id: String
) -> Dictionary:
	var intensity: float = clamp(float(chart_profile.get("microstructure_intensity", 0.0)), 0.0, 1.0)
	var shakeout_profile: String = str(chart_profile.get("shakeout_profile", "none"))
	var cycle_template: String = str(chart_profile.get("cycle_template", ""))
	if intensity <= 0.0 or shakeout_profile == "none" or cycle_template.is_empty() or bar_index <= 1 or bar_index >= total_bars - 2:
		return _chart_neutral_microstructure_context()

	var local_progress: float = _chart_pattern_local_progress(progress, bar_index, total_bars, pattern_window)
	if local_progress < -0.08 or local_progress > 1.08:
		return _chart_neutral_microstructure_context()

	var centers: Dictionary = _chart_microstructure_centers(chart_profile)
	var width: float = float(centers.get("width", 0.052))
	var operator_pressure: float = clamp(float(chart_profile.get("operator_pressure", 0.0)), 0.0, 1.0)
	var price_bias: float = 0.0
	var range_boost: float = 0.0
	var volume_boost: float = 0.0
	var lower_wick_bias: float = 0.0
	var upper_wick_bias: float = 0.0
	var phase: String = "calm"

	if cycle_template in ["markup_clean", "markup_exhaustion", "operator_markup"]:
		var pullback_pulse: float = _chart_microstructure_pulse(local_progress, float(centers.get("pullback", 0.31)), width)
		var reclaim_pulse: float = _chart_microstructure_pulse(local_progress, float(centers.get("reclaim", 0.39)), width * 0.92)
		var shelf_pulse: float = _chart_microstructure_pulse(local_progress, float(centers.get("shelf", 0.68)), width * 1.08)
		var pull_depth: float = lerp(0.014, 0.052, intensity) * (1.0 + operator_pressure * 0.42)
		if shakeout_profile == "hard_shakeout":
			pull_depth *= 1.32
		elif shakeout_profile == "healthy_pullback":
			pull_depth *= 0.88
		price_bias -= pullback_pulse * pull_depth
		price_bias += reclaim_pulse * pull_depth * 0.56
		price_bias -= shelf_pulse * pull_depth * 0.48
		range_boost += (pullback_pulse + shelf_pulse) * lerp(0.20, 0.82, intensity)
		volume_boost += (pullback_pulse * 0.66 + reclaim_pulse * 0.42 + shelf_pulse * 0.30) * lerp(0.22, 1.16, intensity)
		lower_wick_bias += pullback_pulse * lerp(0.006, 0.036, intensity) * (1.0 + operator_pressure * 0.45)
		if reclaim_pulse > max(pullback_pulse, shelf_pulse):
			phase = "reclaim"
		elif pullback_pulse > 0.12:
			phase = "shakeout"
		elif shelf_pulse > 0.12:
			phase = "shelf"
	elif cycle_template == "distribution_clean":
		var dead_cat_pulse: float = _chart_microstructure_pulse(local_progress, float(centers.get("dead_cat", 0.36)), width * 1.08)
		var lower_high_pulse: float = _chart_microstructure_pulse(local_progress, float(centers.get("lower_high", 0.48)), width * 0.92)
		var continuation_pulse: float = _chart_microstructure_pulse(local_progress, float(centers.get("continuation", 0.58)), width * 1.02)
		var bounce_size: float = lerp(0.012, 0.046, intensity)
		price_bias += dead_cat_pulse * bounce_size
		price_bias -= lower_high_pulse * bounce_size * 0.42
		price_bias -= continuation_pulse * bounce_size * 0.72
		range_boost += (dead_cat_pulse + lower_high_pulse + continuation_pulse) * lerp(0.16, 0.72, intensity)
		volume_boost += (dead_cat_pulse * 0.32 + lower_high_pulse * 0.44 + continuation_pulse * 0.70) * lerp(0.18, 1.02, intensity)
		upper_wick_bias += lower_high_pulse * lerp(0.006, 0.032, intensity)
		if dead_cat_pulse > max(lower_high_pulse, continuation_pulse):
			phase = "dead_cat"
		elif continuation_pulse > 0.12:
			phase = "continuation"
	elif cycle_template == "failed_markup":
		var hope_pulse: float = _chart_microstructure_pulse(local_progress, float(centers.get("reclaim", 0.42)), width)
		var failure_pulse: float = _chart_microstructure_pulse(local_progress, float(centers.get("continuation", 0.62)), width * 1.10)
		var failed_size: float = lerp(0.016, 0.054, intensity) * (1.0 + operator_pressure * 0.24)
		price_bias += hope_pulse * failed_size * 0.46
		price_bias -= failure_pulse * failed_size
		range_boost += (hope_pulse + failure_pulse) * lerp(0.18, 0.78, intensity)
		volume_boost += (hope_pulse * 0.28 + failure_pulse * 0.74) * lerp(0.20, 1.08, intensity)
		upper_wick_bias += failure_pulse * lerp(0.008, 0.036, intensity)
		phase = "failed_reclaim" if failure_pulse > hope_pulse else "hope"
	elif cycle_template == "operator_rug":
		var shake_pulse: float = _chart_microstructure_pulse(local_progress, float(centers.get("pullback", 0.24)), width * 0.95)
		var run_pulse: float = _chart_microstructure_pulse(local_progress, float(centers.get("reclaim", 0.34)), width)
		var rug_pulse: float = _chart_microstructure_pulse(local_progress, float(centers.get("continuation", 0.70)), width * 1.08)
		var rug_size: float = lerp(0.020, 0.064, intensity) * (1.0 + operator_pressure * 0.52)
		price_bias -= shake_pulse * rug_size * 0.52
		price_bias += run_pulse * rug_size * 0.58
		price_bias -= rug_pulse * rug_size
		range_boost += (shake_pulse + run_pulse + rug_pulse) * lerp(0.26, 1.12, intensity)
		volume_boost += (shake_pulse * 0.54 + run_pulse * 0.48 + rug_pulse * 1.05) * lerp(0.24, 1.36, intensity)
		lower_wick_bias += (shake_pulse + rug_pulse) * lerp(0.010, 0.050, intensity)
		phase = "rug" if rug_pulse > max(shake_pulse, run_pulse) else "operator_run"

	var jitter: float = _sample_noise(run_seed, company_id, "chart_microstructure_jitter", -0.010, 0.010, bar_index + 1) * intensity * 0.28
	return {
		"price_multiplier": clamp(1.0 + price_bias + jitter, 0.86, 1.14),
		"range_multiplier": clamp(1.0 + range_boost, 0.88, 1.65),
		"volume_multiplier": clamp(1.0 + volume_boost, 0.50, 3.25),
		"lower_wick_bias": clamp(lower_wick_bias, 0.0, 0.045),
		"upper_wick_bias": clamp(upper_wick_bias, 0.0, 0.045),
		"phase": phase
	}


func _chart_neutral_microstructure_context() -> Dictionary:
	return {
		"price_multiplier": 1.0,
		"range_multiplier": 1.0,
		"volume_multiplier": 1.0,
		"lower_wick_bias": 0.0,
		"upper_wick_bias": 0.0,
		"phase": "calm"
	}


func _chart_pattern_local_progress(progress: float, bar_index: int, total_bars: int, pattern_window: Dictionary) -> float:
	var timeframe: String = str(pattern_window.get("timeframe", "5y")).to_lower()
	if timeframe == "5y" or total_bars <= 0:
		return progress
	var start_index: int = int(pattern_window.get("start", 0))
	var end_index: int = int(pattern_window.get("end", total_bars - 1))
	var span: int = max(end_index - start_index, 1)
	return float(bar_index - start_index) / float(span)


func _chart_microstructure_centers(chart_profile: Dictionary) -> Dictionary:
	var tempo_profile: String = str(chart_profile.get("cycle_tempo_profile", "normal_setup"))
	var duration_bias: float = clamp(float(chart_profile.get("setup_duration_bias", 0.0)), -1.0, 1.0)
	var centers: Dictionary = {
		"pullback": 0.31,
		"reclaim": 0.39,
		"shelf": 0.68,
		"dead_cat": 0.36,
		"lower_high": 0.48,
		"continuation": 0.58,
		"width": 0.052
	}
	match tempo_profile:
		"slow_setup":
			centers = {
				"pullback": 0.40,
				"reclaim": 0.50,
				"shelf": 0.74,
				"dead_cat": 0.42,
				"lower_high": 0.56,
				"continuation": 0.68,
				"width": 0.070
			}
		"fast_operator":
			centers = {
				"pullback": 0.21,
				"reclaim": 0.28,
				"shelf": 0.54,
				"dead_cat": 0.27,
				"lower_high": 0.36,
				"continuation": 0.47,
				"width": 0.037
			}
		"failed_setup":
			centers = {
				"pullback": 0.32,
				"reclaim": 0.43,
				"shelf": 0.64,
				"dead_cat": 0.36,
				"lower_high": 0.49,
				"continuation": 0.63,
				"width": 0.058
			}
	var shift: float = clamp(duration_bias * 0.045, -0.045, 0.045)
	for key_value in ["pullback", "reclaim", "shelf", "dead_cat", "lower_high", "continuation"]:
		centers[key_value] = clamp(float(centers.get(key_value, 0.5)) + shift, 0.06, 0.94)
	return centers


func _chart_microstructure_pulse(progress: float, center: float, width: float) -> float:
	var distance: float = absf(progress - center)
	if width <= 0.0 or distance >= width:
		return 0.0
	var t: float = 1.0 - distance / width
	return t * t * (3.0 - 2.0 * t)


func _chart_tape_regime_blocks(
	chart_profile: Dictionary,
	total_bars: int,
	pattern_window: Dictionary,
	run_seed: int,
	company_id: String
) -> Array:
	var profile_id: String = str(chart_profile.get("tape_regime_profile", "messy_accumulation"))
	if not CHART_TAPE_REGIME_PROFILES.has(profile_id):
		profile_id = "messy_accumulation"
	var tempo_bias: float = clamp(float(chart_profile.get("regime_tempo_bias", 0.0)), -1.0, 1.0)
	var boundary_jitter: float = _sample_noise(run_seed, company_id, "tape_regime_boundary_jitter", -0.018, 0.018, 1)
	var base_end: float = _chart_tape_regime_base_end(chart_profile, profile_id, tempo_bias + boundary_jitter)
	match profile_id:
		"clean_trend":
			var impulse_end: float = clamp(base_end + 0.16 - tempo_bias * 0.025, base_end + 0.09, 0.56)
			return _chart_tape_regime_rows([
				["base", 0.00, base_end, 0],
				["markup", base_end, impulse_end, 1],
				["channel", impulse_end, 0.84, 1],
				["consolidation", 0.84, 1.00, 0]
			])
		"operator_campaign":
			var operator_markup_end: float = clamp(base_end + 0.15, base_end + 0.08, 0.42)
			var dirty_channel_end: float = clamp(operator_markup_end + 0.24, operator_markup_end + 0.14, 0.70)
			var distribution_end: float = clamp(dirty_channel_end + 0.13, dirty_channel_end + 0.08, 0.84)
			var final_type: String = "rug" if str(chart_profile.get("cycle_template", "")) == "operator_rug" else "failed_reclaim"
			return _chart_tape_regime_rows([
				["base", 0.00, base_end, 0],
				["markup", base_end, operator_markup_end, 1],
				["channel", operator_markup_end, dirty_channel_end, 1],
				["distribution", dirty_channel_end, distribution_end, -1],
				[final_type, distribution_end, 1.00, -1]
			])
		"distribution_breakdown":
			var distribution_end_1: float = clamp(max(base_end, 0.24), 0.18, 0.36)
			var breakdown_end: float = clamp(distribution_end_1 + 0.18, distribution_end_1 + 0.10, 0.58)
			var dead_cat_end: float = clamp(breakdown_end + 0.13, breakdown_end + 0.08, 0.72)
			return _chart_tape_regime_rows([
				["distribution", 0.00, distribution_end_1, -1],
				["breakdown", distribution_end_1, breakdown_end, -1],
				["dead_cat", breakdown_end, dead_cat_end, 1],
				["markdown", dead_cat_end, 0.86, -1],
				["failed_reclaim", 0.86, 1.00, -1]
			])
		"failed_reclaim":
			var failed_markup_end: float = clamp(base_end + 0.14, base_end + 0.08, 0.50)
			var failed_dist_end: float = clamp(failed_markup_end + 0.16, failed_markup_end + 0.08, 0.66)
			var failed_break_end: float = clamp(failed_dist_end + 0.16, failed_dist_end + 0.08, 0.82)
			return _chart_tape_regime_rows([
				["base", 0.00, base_end, 0],
				["markup", base_end, failed_markup_end, 1],
				["distribution", failed_markup_end, failed_dist_end, -1],
				["breakdown", failed_dist_end, failed_break_end, -1],
				["failed_reclaim", failed_break_end, 1.00, -1]
			])
	var messy_markup_end: float = clamp(base_end + 0.16, base_end + 0.08, 0.56)
	var messy_channel_end: float = clamp(messy_markup_end + 0.30, messy_markup_end + 0.16, 0.84)
	return _chart_tape_regime_rows([
		["base", 0.00, base_end, 0],
		["markup", base_end, messy_markup_end, 1],
		["channel", messy_markup_end, messy_channel_end, 1],
		["distribution", messy_channel_end, 1.00, -1]
	])


func _chart_tape_regime_base_end(chart_profile: Dictionary, profile_id: String, tempo_bias: float) -> float:
	var base_end: float = 0.32
	match profile_id:
		"clean_trend":
			base_end = 0.34
		"messy_accumulation":
			base_end = 0.34
		"operator_campaign":
			base_end = 0.19
		"distribution_breakdown":
			base_end = 0.25
		"failed_reclaim":
			base_end = 0.30
	match str(chart_profile.get("cycle_tempo_profile", "normal_setup")):
		"slow_setup":
			base_end += 0.06
		"fast_operator":
			base_end -= 0.06
		"failed_setup":
			base_end += 0.03
	base_end += tempo_bias * 0.10
	return clamp(base_end, 0.12, 0.48)


func _chart_tape_regime_rows(rows: Array) -> Array:
	var blocks: Array = []
	var previous_end: float = 0.0
	for row_value in rows:
		if typeof(row_value) != TYPE_ARRAY:
			continue
		var row: Array = row_value
		if row.size() < 4:
			continue
		var start_progress: float = clamp(max(float(row[1]), previous_end), 0.0, 1.0)
		var end_progress: float = clamp(max(float(row[2]), start_progress + 0.015), 0.0, 1.0)
		if end_progress <= start_progress:
			continue
		blocks.append({
			"type": str(row[0]),
			"p0": start_progress,
			"p1": end_progress,
			"direction": int(row[3])
		})
		previous_end = end_progress
	return blocks


func _chart_tape_regime_block_at(blocks: Array, local_progress: float) -> Dictionary:
	var selected: Dictionary = {}
	for block_value in blocks:
		if typeof(block_value) != TYPE_DICTIONARY:
			continue
		var block: Dictionary = block_value
		if local_progress >= float(block.get("p0", 0.0)) and local_progress <= float(block.get("p1", 1.0)):
			return block
		selected = block
	return selected


func _chart_tape_regime_context(
	chart_profile: Dictionary,
	progress: float,
	bar_index: int,
	total_bars: int,
	pattern_window: Dictionary,
	run_seed: int,
	company_id: String,
	previous_close: float,
	desired_close: float,
	closes: Array
) -> Dictionary:
	if bar_index <= 1 or bar_index >= total_bars - 3:
		return _chart_neutral_tape_regime_context()
	var strength: float = clamp(float(chart_profile.get("regime_block_intensity", 0.0)), 0.0, 1.0)
	if strength <= 0.0:
		return _chart_neutral_tape_regime_context()
	var local_progress: float = _chart_pattern_local_progress(progress, bar_index, total_bars, pattern_window)
	if local_progress < -0.08 or local_progress > 1.08:
		return _chart_neutral_tape_regime_context()
	local_progress = clamp(local_progress, 0.0, 1.0)
	var blocks: Array = _chart_tape_regime_blocks(chart_profile, total_bars, pattern_window, run_seed, company_id)
	var block: Dictionary = _chart_tape_regime_block_at(blocks, local_progress)
	if block.is_empty():
		return _chart_neutral_tape_regime_context()
	var block_type: String = str(block.get("type", "base"))
	var block_start: float = float(block.get("p0", 0.0))
	var block_end: float = float(block.get("p1", 1.0))
	var block_progress: float = clamp((local_progress - block_start) / max(block_end - block_start, 0.001), 0.0, 1.0)
	var direction: int = int(block.get("direction", 0))
	var trend_direction: int = _chart_daily_tape_trend_direction(chart_profile)
	if direction == 0:
		direction = trend_direction
	var operator_pressure: float = clamp(float(chart_profile.get("operator_pressure", 0.0)), 0.0, 1.0)
	var profile_id: String = str(chart_profile.get("tape_regime_profile", "messy_accumulation"))
	var price_bias: float = 0.0
	var range_boost: float = 0.0
	var volume_bias: float = 0.0
	var lower_wick_bias: float = 0.0
	var upper_wick_bias: float = 0.0
	var close_blend: float = 0.0
	var previous_close_bias: float = 0.0
	var pulse: float = _chart_microstructure_pulse(block_progress, 0.50, 0.42)
	var edge_pulse: float = max(
		_chart_microstructure_pulse(block_progress, 0.16, 0.13),
		_chart_microstructure_pulse(block_progress, 0.84, 0.13)
	)
	match block_type:
		"base":
			var fake_up: float = _chart_microstructure_pulse(block_progress, 0.30, 0.18)
			var fake_down: float = _chart_microstructure_pulse(block_progress, 0.66, 0.18)
			price_bias += (fake_up - fake_down) * lerp(0.003, 0.013, strength)
			close_blend = lerp(0.24, 0.62, strength)
			previous_close_bias = _sample_noise(run_seed, company_id, "tape_regime_base_bias", -0.0035, 0.0035, bar_index + 1) * strength
			range_boost -= lerp(0.05, 0.22, strength)
			volume_bias -= lerp(0.10, 0.34, strength)
			lower_wick_bias += fake_down * lerp(0.004, 0.024, strength)
			upper_wick_bias += fake_up * lerp(0.004, 0.024, strength)
		"markup":
			var impulse_size: float = lerp(0.005, 0.024, strength) * (1.0 + operator_pressure * 0.26)
			price_bias += impulse_size * (0.62 + pulse)
			range_boost += lerp(0.08, 0.55, strength) * (0.40 + pulse)
			volume_bias += lerp(0.18, 1.05, strength) * (0.50 + pulse)
			lower_wick_bias += edge_pulse * lerp(0.003, 0.020, strength)
		"channel":
			var pullback_pulse: float = _chart_microstructure_pulse(block_progress, 0.34, 0.17)
			var reclaim_pulse: float = _chart_microstructure_pulse(block_progress, 0.55, 0.15)
			var shelf_pulse: float = _chart_microstructure_pulse(block_progress, 0.78, 0.16)
			var channel_direction: int = 1 if direction >= 0 else -1
			var counter_size: float = lerp(0.006, 0.030, strength) * (1.0 + operator_pressure * 0.22)
			price_bias += float(channel_direction) * lerp(0.0015, 0.0045, strength)
			price_bias -= float(channel_direction) * pullback_pulse * counter_size
			price_bias += float(channel_direction) * reclaim_pulse * counter_size * 0.52
			price_bias -= float(channel_direction) * shelf_pulse * counter_size * 0.20
			range_boost += (pullback_pulse + shelf_pulse) * lerp(0.12, 0.62, strength)
			volume_bias += pullback_pulse * lerp(0.10, 0.70, strength)
			volume_bias -= shelf_pulse * lerp(0.06, 0.22, strength)
			if channel_direction > 0:
				lower_wick_bias += pullback_pulse * lerp(0.006, 0.036, strength)
			else:
				upper_wick_bias += pullback_pulse * lerp(0.006, 0.036, strength)
		"distribution":
			var top_fail: float = _chart_microstructure_pulse(block_progress, 0.58, 0.22)
			var churn: float = _chart_microstructure_pulse(block_progress, 0.28, 0.20)
			price_bias -= top_fail * lerp(0.006, 0.028, strength)
			price_bias += churn * lerp(0.002, 0.008, strength)
			range_boost += (top_fail + churn) * lerp(0.10, 0.66, strength)
			volume_bias += (top_fail * 0.72 + churn * 0.36) * lerp(0.16, 0.95, strength)
			upper_wick_bias += top_fail * lerp(0.008, 0.044, strength)
		"breakdown", "markdown", "rug":
			var drop_pulse: float = _chart_microstructure_pulse(block_progress, 0.46, 0.34)
			var drop_size: float = lerp(0.006, 0.030, strength) * (1.0 + operator_pressure * 0.34)
			if block_type == "rug":
				drop_size *= 1.24
			price_bias -= drop_size * (0.50 + drop_pulse)
			range_boost += lerp(0.12, 0.78, strength) * (0.35 + drop_pulse)
			volume_bias += lerp(0.16, 1.10, strength) * (0.38 + drop_pulse)
			lower_wick_bias += drop_pulse * lerp(0.008, 0.050, strength)
		"dead_cat":
			var bounce_pulse: float = _chart_microstructure_pulse(block_progress, 0.34, 0.20)
			var failure_pulse: float = _chart_microstructure_pulse(block_progress, 0.72, 0.22)
			price_bias += bounce_pulse * lerp(0.006, 0.026, strength)
			price_bias -= failure_pulse * lerp(0.008, 0.030, strength)
			range_boost += (bounce_pulse + failure_pulse) * lerp(0.10, 0.58, strength)
			volume_bias += failure_pulse * lerp(0.14, 0.82, strength)
			upper_wick_bias += failure_pulse * lerp(0.006, 0.036, strength)
		"failed_reclaim":
			var reclaim_try: float = _chart_microstructure_pulse(block_progress, 0.32, 0.20)
			var rejection: float = _chart_microstructure_pulse(block_progress, 0.62, 0.26)
			price_bias += reclaim_try * lerp(0.004, 0.020, strength)
			price_bias -= rejection * lerp(0.008, 0.034, strength)
			range_boost += (reclaim_try + rejection) * lerp(0.10, 0.66, strength)
			volume_bias += rejection * lerp(0.14, 0.96, strength)
			upper_wick_bias += rejection * lerp(0.008, 0.046, strength)
		"consolidation":
			close_blend = lerp(0.14, 0.36, strength)
			price_bias += _sample_noise(run_seed, company_id, "tape_regime_consolidation_bias", -0.004, 0.004, bar_index + 1) * strength
			range_boost -= lerp(0.04, 0.16, strength)
			volume_bias -= lerp(0.04, 0.22, strength)
	if profile_id == "operator_campaign":
		range_boost += operator_pressure * 0.08
		volume_bias += edge_pulse * operator_pressure * 0.28
	return {
		"price_multiplier": clamp(1.0 + price_bias, 0.86, 1.14),
		"range_multiplier": clamp(1.0 + range_boost, 0.82, 1.75),
		"volume_multiplier": clamp(1.0 + volume_bias, 0.36, 3.40),
		"lower_wick_bias": clamp(lower_wick_bias, 0.0, 0.045),
		"upper_wick_bias": clamp(upper_wick_bias, 0.0, 0.045),
		"close_blend_to_previous": clamp(close_blend, 0.0, 0.72),
		"previous_close_bias": clamp(previous_close_bias, -0.012, 0.012),
		"phase": block_type,
		"regime_strength": strength,
		"regime_block": block
	}


func _chart_neutral_tape_regime_context() -> Dictionary:
	return {
		"price_multiplier": 1.0,
		"range_multiplier": 1.0,
		"volume_multiplier": 1.0,
		"lower_wick_bias": 0.0,
		"upper_wick_bias": 0.0,
		"close_blend_to_previous": 0.0,
		"previous_close_bias": 0.0,
		"phase": "calm",
		"regime_strength": 0.0,
		"regime_block": {}
	}


func _chart_daily_tape_friction_context(
	chart_profile: Dictionary,
	progress: float,
	bar_index: int,
	total_bars: int,
	pattern_window: Dictionary,
	run_seed: int,
	company_id: String,
	previous_close: float,
	desired_close: float,
	closes: Array
) -> Dictionary:
	if bar_index <= 1 or bar_index >= total_bars - 3:
		return _chart_neutral_daily_tape_friction_context()

	var bar_friction_profile: String = str(chart_profile.get("bar_friction_profile", "balanced_chop"))
	var frequency_bias: float = clamp(float(chart_profile.get("microleg_frequency_bias", 0.55)), 0.0, 1.0)
	var wick_intensity: float = clamp(float(chart_profile.get("wick_noise_intensity", 0.42)), 0.0, 1.0)
	var disagreement_rate: float = clamp(float(chart_profile.get("volume_disagreement_rate", 0.36)), 0.0, 1.0)
	var strength: float = _chart_daily_tape_friction_strength(chart_profile)
	if strength <= 0.0:
		return _chart_neutral_daily_tape_friction_context()

	var local_progress: float = _chart_pattern_local_progress(progress, bar_index, total_bars, pattern_window)
	var window_weight: float = 1.0 if local_progress >= 0.0 and local_progress <= 1.0 else 0.48
	var start_index: int = int(pattern_window.get("start", 0))
	var micro_index: int = bar_index - start_index if local_progress >= 0.0 and local_progress <= 1.0 else bar_index
	var period: int = _chart_daily_tape_microleg_period(chart_profile, bar_index, run_seed, company_id)
	var phase_offset: int = int(round(_sample_noise(run_seed, company_id, "daily_tape_phase_offset", 0.0, float(max(period - 1, 1)), bar_index + 1)))
	var cycle_phase: float = float((micro_index + phase_offset) % max(period, 1)) / float(max(period, 1))
	var trend_direction: int = _chart_daily_tape_trend_direction(chart_profile)
	var desired_direction: int = _chart_direction_for_delta(desired_close - previous_close)
	var run_state: Dictionary = _chart_same_direction_streak(closes)
	var streak_direction: int = int(run_state.get("direction", 0))
	var streak_count: int = int(run_state.get("count", 0))
	var run_limit: int = _chart_same_direction_run_limit(chart_profile)

	var price_bias: float = 0.0
	var range_boost: float = 0.0
	var volume_bias: float = 0.0
	var lower_wick_bias: float = 0.0
	var upper_wick_bias: float = 0.0
	var phase_label: String = "daily_chop"
	var counter_size: float = lerp(0.0045, 0.018, strength) * window_weight
	var reclaim_size: float = counter_size * lerp(0.34, 0.58, frequency_bias)
	var shock_wick: float = lerp(0.0025, 0.018, wick_intensity) * window_weight

	if trend_direction > 0:
		var shake_pulse: float = _chart_microstructure_pulse(cycle_phase, 0.34, 0.18)
		var reclaim_pulse: float = _chart_microstructure_pulse(cycle_phase, 0.54, 0.16)
		var shelf_pulse: float = _chart_microstructure_pulse(cycle_phase, 0.78, 0.14)
		price_bias -= shake_pulse * counter_size
		price_bias += reclaim_pulse * reclaim_size
		price_bias -= shelf_pulse * counter_size * 0.26
		range_boost += (shake_pulse + shelf_pulse) * lerp(0.12, 0.55, wick_intensity)
		volume_bias += shake_pulse * lerp(0.12, 0.74, strength)
		volume_bias -= shelf_pulse * lerp(0.08, 0.26, disagreement_rate)
		lower_wick_bias += shake_pulse * shock_wick
		if shake_pulse > max(reclaim_pulse, shelf_pulse):
			phase_label = "turunin_penumpang"
		elif reclaim_pulse > shelf_pulse:
			phase_label = "reclaim"
		elif shelf_pulse > 0.12:
			phase_label = "shelf"
	elif trend_direction < 0:
		var bounce_pulse: float = _chart_microstructure_pulse(cycle_phase, 0.30, 0.17)
		var lower_high_pulse: float = _chart_microstructure_pulse(cycle_phase, 0.52, 0.16)
		var continuation_pulse: float = _chart_microstructure_pulse(cycle_phase, 0.72, 0.15)
		price_bias += bounce_pulse * reclaim_size
		price_bias -= lower_high_pulse * counter_size * 0.52
		price_bias -= continuation_pulse * counter_size * 0.66
		range_boost += (bounce_pulse + lower_high_pulse + continuation_pulse) * lerp(0.10, 0.52, wick_intensity)
		volume_bias += (lower_high_pulse + continuation_pulse) * lerp(0.10, 0.68, strength)
		volume_bias -= bounce_pulse * lerp(0.03, 0.20, disagreement_rate)
		upper_wick_bias += lower_high_pulse * shock_wick
		if bounce_pulse > max(lower_high_pulse, continuation_pulse):
			phase_label = "dead_cat"
		elif lower_high_pulse > continuation_pulse:
			phase_label = "lower_high"
		elif continuation_pulse > 0.12:
			phase_label = "continuation"
	else:
		var chop_up_pulse: float = _chart_microstructure_pulse(cycle_phase, 0.28, 0.18)
		var chop_down_pulse: float = _chart_microstructure_pulse(cycle_phase, 0.62, 0.18)
		price_bias += chop_up_pulse * reclaim_size * 0.62
		price_bias -= chop_down_pulse * counter_size * 0.62
		range_boost += (chop_up_pulse + chop_down_pulse) * lerp(0.08, 0.38, wick_intensity)
		volume_bias -= max(chop_up_pulse, chop_down_pulse) * lerp(0.04, 0.22, disagreement_rate)
		lower_wick_bias += chop_down_pulse * shock_wick * 0.66
		upper_wick_bias += chop_up_pulse * shock_wick * 0.66
		if chop_up_pulse > chop_down_pulse:
			phase_label = "range_fakeout_up"
		elif chop_down_pulse > 0.12:
			phase_label = "range_fakeout_down"

	if desired_direction != 0 and streak_direction == desired_direction and streak_count >= run_limit:
		var guard_pressure: float = clamp(float(streak_count - run_limit + 1) / 3.0, 0.35, 1.0)
		price_bias += -float(desired_direction) * max(counter_size * 0.92 * guard_pressure, 0.004)
		range_boost += lerp(0.08, 0.42, wick_intensity) * guard_pressure
		volume_bias += lerp(0.05, 0.38, strength) * guard_pressure
		if desired_direction > 0:
			lower_wick_bias += shock_wick * guard_pressure
		else:
			upper_wick_bias += shock_wick * guard_pressure
		phase_label = "run_guard"

	var disagreement_roll: float = _sample_noise(run_seed, company_id, "daily_tape_volume_disagreement", 0.0, 1.0, bar_index + 1)
	if disagreement_roll < disagreement_rate:
		if desired_direction == trend_direction and desired_direction != 0:
			volume_bias -= lerp(0.08, 0.32, disagreement_rate)
		else:
			volume_bias += lerp(0.06, 0.42, disagreement_rate)
	var spike_roll: float = _sample_noise(run_seed, company_id, "daily_tape_volume_spike", 0.0, 1.0, bar_index + 1)
	if bar_friction_profile == "operator_dirty" and spike_roll > 0.78:
		volume_bias += lerp(0.30, 1.10, strength)
		range_boost += lerp(0.06, 0.24, wick_intensity)

	return {
		"price_multiplier": clamp(1.0 + price_bias, 0.88, 1.12),
		"range_multiplier": clamp(1.0 + range_boost, 0.86, 1.55),
		"volume_multiplier": clamp(1.0 + volume_bias, 0.42, 2.85),
		"lower_wick_bias": clamp(lower_wick_bias, 0.0, 0.030),
		"upper_wick_bias": clamp(upper_wick_bias, 0.0, 0.030),
		"phase": phase_label,
		"run_limit": run_limit,
		"friction_strength": strength
	}


func _chart_neutral_daily_tape_friction_context() -> Dictionary:
	return {
		"price_multiplier": 1.0,
		"range_multiplier": 1.0,
		"volume_multiplier": 1.0,
		"lower_wick_bias": 0.0,
		"upper_wick_bias": 0.0,
		"phase": "calm",
		"run_limit": 6,
		"friction_strength": 0.0
	}


func _chart_daily_tape_friction_strength(chart_profile: Dictionary) -> float:
	var profile_id: String = str(chart_profile.get("bar_friction_profile", "balanced_chop"))
	var strength: float = 0.34
	match profile_id:
		"clean_liquid":
			strength = 0.20
		"balanced_chop":
			strength = 0.44
		"operator_dirty":
			strength = 0.64
		"distribution_chop":
			strength = 0.54
	strength += clamp(float(chart_profile.get("microleg_frequency_bias", 0.55)), 0.0, 1.0) * 0.09
	strength += clamp(float(chart_profile.get("wick_noise_intensity", 0.42)), 0.0, 1.0) * 0.06
	strength += clamp(float(chart_profile.get("volume_disagreement_rate", 0.36)), 0.0, 1.0) * 0.05
	strength += clamp(float(chart_profile.get("operator_pressure", 0.0)), 0.0, 1.0) * 0.06
	return clamp(strength, 0.10, 0.78)


func _chart_daily_tape_microleg_period(chart_profile: Dictionary, bar_index: int, run_seed: int, company_id: String) -> int:
	var profile_id: String = str(chart_profile.get("bar_friction_profile", "balanced_chop"))
	var frequency_bias: float = clamp(float(chart_profile.get("microleg_frequency_bias", 0.55)), 0.0, 1.0)
	var base_period: float = 6.0
	match profile_id:
		"clean_liquid":
			base_period = lerp(9.0, 6.0, frequency_bias)
		"balanced_chop":
			base_period = lerp(7.0, 4.8, frequency_bias)
		"operator_dirty":
			base_period = lerp(5.4, 3.2, frequency_bias)
		"distribution_chop":
			base_period = lerp(6.2, 4.0, frequency_bias)
	var jitter: float = _sample_noise(run_seed, company_id, "daily_tape_period_jitter", -0.9, 0.9, int(float(bar_index) / 7.0) + 1)
	return int(clamp(round(base_period + jitter), 3.0, 10.0))


func _chart_same_direction_run_limit(chart_profile: Dictionary) -> int:
	var profile_id: String = str(chart_profile.get("bar_friction_profile", "balanced_chop"))
	var limit: int = 5
	match profile_id:
		"clean_liquid":
			limit = 6
		"balanced_chop":
			limit = 5
		"operator_dirty":
			limit = 4
		"distribution_chop":
			limit = 4
	if str(chart_profile.get("cycle_tempo_profile", "normal_setup")) == "fast_operator":
		limit -= 1
	if clamp(float(chart_profile.get("microleg_frequency_bias", 0.55)), 0.0, 1.0) >= 0.78:
		limit -= 1
	return int(clamp(limit, 3, 7))


func _chart_daily_tape_trend_direction(chart_profile: Dictionary) -> int:
	var cycle_template: String = str(chart_profile.get("cycle_template", ""))
	if cycle_template in ["markup_clean", "markup_exhaustion", "operator_markup"]:
		return 1
	if cycle_template in ["distribution_clean", "failed_markup", "operator_rug"]:
		return -1
	var bias: String = str(chart_profile.get("bias", "sideways"))
	if bias == "bullish":
		return 1
	if bias == "bearish":
		return -1
	return 0


func _chart_same_direction_streak(closes: Array) -> Dictionary:
	var direction: int = 0
	var count: int = 0
	if closes.size() < 2:
		return {"direction": 0, "count": 0}
	for index in range(closes.size() - 1, 0, -1):
		var current_close: float = float(closes[index])
		var previous_close: float = float(closes[index - 1])
		var step_direction: int = _chart_direction_for_delta(current_close - previous_close)
		if step_direction == 0:
			break
		if direction == 0:
			direction = step_direction
			count = 1
		elif step_direction == direction:
			count += 1
		else:
			break
	return {"direction": direction, "count": count}


func _chart_direction_for_delta(delta: float) -> int:
	if delta > 0.0001:
		return 1
	if delta < -0.0001:
		return -1
	return 0


func _chart_historical_gap_ratio(
	chart_profile: Dictionary,
	bar_index: int,
	total_bars: int,
	pattern_window: Dictionary,
	run_seed: int,
	company_id: String
) -> float:
	if bar_index <= 0 or bar_index >= total_bars - 1:
		return 0.0
	var gap_style: String = str(chart_profile.get("gap_style", "none"))
	if gap_style == "none":
		return 0.0

	var start_index: int = int(pattern_window.get("start", 0))
	var end_index: int = int(pattern_window.get("end", total_bars - 1))
	var span: int = max(end_index - start_index, 1)
	var local_progress: float = float(bar_index - start_index) / float(span)
	var target_progresses: Array = _chart_gap_target_progresses(chart_profile)
	var matched_target: bool = false
	for target_value in target_progresses:
		var target_progress: float = clamp(float(target_value), 0.0, 1.0)
		var target_index: int = clamp(start_index + int(round(target_progress * float(span))), 1, total_bars - 2)
		var tolerance: int = max(1, int(round(float(span) * 0.012)))
		if abs(bar_index - target_index) <= tolerance:
			matched_target = true
			break

	var frequency: String = str(chart_profile.get("gap_frequency", "rare"))
	var random_chance: float = 0.0
	if frequency == "moderate":
		random_chance = 0.0015
	elif frequency == "active":
		random_chance = 0.0055
	var random_gap: bool = false
	if local_progress >= -0.20 and local_progress <= 1.06 and random_chance > 0.0:
		var random_roll: float = _sample_noise(run_seed, company_id, "chart_profile_random_gap", 0.0, 1.0, bar_index + 1)
		random_gap = random_roll < random_chance
	if not matched_target and not random_gap:
		return 0.0

	var direction: int = _chart_gap_direction(chart_profile, bar_index, run_seed, company_id)
	if direction == 0:
		return 0.0
	var magnitude: float = _chart_gap_magnitude(chart_profile, bar_index, run_seed, company_id)
	return clamp(float(direction) * magnitude, -0.12, 0.12)


func _chart_gap_target_progresses(chart_profile: Dictionary) -> Array:
	var frequency: String = str(chart_profile.get("gap_frequency", "rare"))
	var style: String = str(chart_profile.get("gap_style", "none"))
	var pattern_id: String = str(chart_profile.get("primary_pattern", ""))
	var targets: Array = []
	if style == "breakout_gap" or pattern_id in ["ascending_triangle", "breakout_retest", "bull_flag", "cup_handle"]:
		targets = [0.62]
	elif style == "rug_gap" or pattern_id in ["rug_pull_volume", "pump_dump"]:
		targets = [0.58]
	elif style == "exhaustion_gap" or pattern_id in ["descending_triangle", "breakdown_retest", "double_top", "head_shoulders"]:
		targets = [0.68]
	else:
		targets = [0.54]
	if frequency == "moderate":
		if str(chart_profile.get("archetype", "")) == "gorengan":
			targets.append(0.78 if style != "rug_gap" else 0.72)
	elif frequency == "active":
		targets.append(0.78 if style != "rug_gap" else 0.72)
	return targets


func _chart_gap_direction(chart_profile: Dictionary, bar_index: int, run_seed: int, company_id: String) -> int:
	var gap_bias: String = str(chart_profile.get("gap_bias", "mixed"))
	var gap_style: String = str(chart_profile.get("gap_style", "none"))
	var chart_bias: String = str(chart_profile.get("bias", "sideways"))
	var primary_pattern: String = str(chart_profile.get("primary_pattern", ""))
	if gap_bias == "up":
		return 1
	if gap_bias == "down":
		return -1
	if gap_style == "breakout_gap":
		return 1
	if gap_style == "rug_gap" or gap_style == "exhaustion_gap":
		return -1
	if primary_pattern in ["breakout_retest", "ascending_triangle", "bull_flag", "cup_handle", "double_bottom", "inverse_head_shoulders"]:
		return 1
	if primary_pattern in ["breakdown_retest", "descending_triangle", "rug_pull_volume", "double_top", "head_shoulders"]:
		return -1
	if chart_bias == "bullish":
		return 1
	if chart_bias == "bearish":
		return -1
	var direction_roll: float = _sample_noise(run_seed, company_id, "chart_profile_gap_direction", 0.0, 1.0, bar_index + 1)
	return 1 if direction_roll >= 0.5 else -1


func _chart_gap_magnitude(chart_profile: Dictionary, bar_index: int, run_seed: int, company_id: String) -> float:
	var style: String = str(chart_profile.get("gap_style", "none"))
	var frequency: String = str(chart_profile.get("gap_frequency", "rare"))
	var archetype: String = str(chart_profile.get("archetype", "range_bound"))
	var low: float = 0.024
	var high: float = 0.040
	if frequency == "moderate":
		low = 0.026
		high = 0.055
	elif frequency == "active":
		low = 0.032
		high = 0.078
	if style == "breakout_gap":
		low += 0.004
		high += 0.012
	elif style == "rug_gap":
		low += 0.014
		high += 0.026
	elif style == "exhaustion_gap":
		low += 0.008
		high += 0.018
	elif style == "news_gap":
		high -= 0.006
	elif style == "mixed":
		high += 0.006
	if archetype == "gorengan":
		low *= 1.08
		high *= 1.12
	return _sample_noise(run_seed, company_id, "chart_profile_gap_magnitude", low, max(high, low), bar_index + 1)


func _chart_apply_gap_followthrough(
	close_price: float,
	previous_close: float,
	gap_ratio: float,
	chart_profile: Dictionary
) -> float:
	var followthrough: String = str(chart_profile.get("gap_followthrough", "fill"))
	var magnitude: float = absf(gap_ratio)
	if magnitude <= 0.0:
		return close_price
	if gap_ratio > 0.0:
		match followthrough:
			"continue":
				return max(close_price, previous_close * (1.0 + magnitude * 1.20))
			"hold":
				return max(close_price, previous_close * (1.0 + magnitude * 0.58))
			"fade":
				return lerp(close_price, previous_close * (1.0 - magnitude * 0.18), 0.42)
			_:
				return lerp(close_price, previous_close * (1.0 + magnitude * 0.16), 0.46)
	match followthrough:
		"continue":
			return min(close_price, previous_close * (1.0 - magnitude * 1.16))
		"hold":
			return min(close_price, previous_close * (1.0 - magnitude * 0.58))
		"fade":
			return lerp(close_price, previous_close * (1.0 + magnitude * 0.16), 0.42)
		_:
			return lerp(close_price, previous_close * (1.0 - magnitude * 0.16), 0.46)


func _chart_gap_volume_multiplier(chart_profile: Dictionary, gap_ratio: float) -> float:
	var style: String = str(chart_profile.get("gap_style", "none"))
	var multiplier: float = 1.14 + absf(gap_ratio) * 6.8
	if style in ["rug_gap", "breakout_gap", "mixed"]:
		multiplier += 0.18
	if str(chart_profile.get("archetype", "")) == "gorengan":
		multiplier += 0.24
	return clamp(multiplier, 1.12, 2.65)


func _chart_history_start_price(chart_profile: Dictionary, end_price: float, run_seed: int, company_id: String) -> float:
	var bias: String = str(chart_profile.get("bias", "sideways"))
	var archetype: String = str(chart_profile.get("archetype", "range_bound"))
	var low_ratio: float = 0.82
	var high_ratio: float = 1.18
	if bias == "bullish":
		low_ratio = 0.42
		high_ratio = 0.76
	elif bias == "bearish":
		low_ratio = 1.28
		high_ratio = 2.12
	elif bias == "transition":
		low_ratio = 0.78
		high_ratio = 1.36
	if archetype == "gorengan":
		low_ratio *= 0.82
		high_ratio *= 1.18
	var ratio: float = _sample_noise(run_seed, company_id, "chart_profile_start_ratio", low_ratio, high_ratio, 1)
	return IDX_PRICE_RULES.normalize_last_price(max(end_price * ratio, 1.0))


func _chart_cycle_shape_anchors(chart_profile: Dictionary) -> Array:
	var cycle_template: String = str(chart_profile.get("cycle_template", ""))
	if cycle_template.is_empty():
		return []
	var ratios_value = chart_profile.get("cycle_fib_ratios", {})
	var ratios: Dictionary = {}
	if typeof(ratios_value) == TYPE_DICTIONARY:
		ratios = ratios_value
	if ratios.is_empty():
		ratios = _chart_fib_ratios_for_profile(str(chart_profile.get("fib_profile_id", "")))
	if ratios.is_empty():
		return []
	var strength: float = clamp(float(chart_profile.get("cycle_strength", 0.0)), 0.25, 1.0)
	var operator_pressure: float = clamp(float(chart_profile.get("operator_pressure", 0.0)), 0.0, 1.0)
	match cycle_template:
		"markup_clean", "markup_exhaustion", "failed_markup", "operator_markup", "operator_rug":
			return _chart_markup_cycle_anchors(cycle_template, ratios, strength, operator_pressure)
		"distribution_clean":
			return _chart_distribution_cycle_anchors(ratios, strength)
	return []


func _chart_markup_cycle_anchors(
	cycle_template: String,
	ratios: Dictionary,
	strength: float,
	operator_pressure: float
) -> Array:
	var impulse: float = lerp(0.12, 0.25, strength)
	var wave2_ratio: float = float(ratios.get("wave2", 0.500))
	var wave3_ratio: float = float(ratios.get("wave3", 1.618))
	var wave4_ratio: float = float(ratios.get("wave4", 0.382))
	var wave1: float = 1.0 + impulse
	var wave2: float = 1.0 + impulse * (1.0 - wave2_ratio)
	var wave3: float = 1.0 + impulse * wave3_ratio + strength * 0.06
	var wave4: float = wave3 - (wave3 - wave2) * wave4_ratio
	var wave5: float = max(wave3 * 1.035, wave3 + impulse * 0.32)
	match cycle_template:
		"markup_exhaustion":
			wave5 = max(wave3 * 1.012, wave3 + impulse * 0.10)
			return _chart_anchor_rows([[0.00, 0.93], [0.14, wave1], [0.27, wave2], [0.48, wave3], [0.64, wave4], [0.82, wave5], [0.93, wave5 * 0.96], [1.00, 1.00]])
		"failed_markup":
			wave5 = wave3 * 0.88
			return _chart_anchor_rows([[0.00, 0.96], [0.14, wave1], [0.29, wave2], [0.48, wave3], [0.63, wave4], [0.80, wave5], [0.92, min(wave5, wave4) * 0.94], [1.00, 1.00]])
		"operator_markup":
			wave2 = max(1.0 + impulse * 0.58, wave2)
			wave3 += operator_pressure * 0.32
			wave4 = wave3 - (wave3 - wave2) * 0.18
			wave5 = wave3 * (1.06 + operator_pressure * 0.08)
			return _chart_anchor_rows([[0.00, 0.90], [0.11, wave1], [0.22, wave2], [0.44, wave3], [0.56, wave4], [0.72, wave5], [0.88, wave5 * 0.92], [1.00, 1.00]])
		"operator_rug":
			wave2 = max(1.0 + impulse * 0.48, wave2)
			wave3 += operator_pressure * 0.36
			wave4 = wave3 * 0.96
			wave5 = wave3 * (1.02 + operator_pressure * 0.05)
			var rug_low: float = max(0.62, min(wave4 * lerp(0.62, 0.42, operator_pressure), wave3 - impulse * (2.60 + operator_pressure)))
			return _chart_anchor_rows([[0.00, 0.90], [0.12, wave1], [0.25, wave2], [0.46, wave3], [0.58, wave4], [0.70, wave5], [0.84, rug_low], [0.94, rug_low * 1.06], [1.00, 1.00]])
	return _chart_anchor_rows([[0.00, 0.94], [0.15, wave1], [0.30, wave2], [0.51, wave3], [0.66, wave4], [0.84, wave5], [1.00, 1.00]])


func _chart_distribution_cycle_anchors(ratios: Dictionary, strength: float) -> Array:
	var impulse: float = lerp(0.10, 0.22, strength)
	var wave2_ratio: float = float(ratios.get("wave2", 0.500))
	var wave3_ratio: float = float(ratios.get("wave3", 1.618))
	var wave4_ratio: float = float(ratios.get("wave4", 0.382))
	var wave1: float = 1.0 - impulse
	var wave2: float = 1.0 - impulse * (1.0 - wave2_ratio)
	var wave3: float = 1.0 - impulse * wave3_ratio - strength * 0.04
	var wave4: float = wave3 + (wave2 - wave3) * wave4_ratio
	var wave5: float = min(wave3 * 0.96, wave3 - impulse * 0.28)
	return _chart_anchor_rows([[0.00, 1.08], [0.15, wave1], [0.30, wave2], [0.50, wave3], [0.66, wave4], [0.84, wave5], [1.00, 1.00]])


func _chart_shape_anchors(chart_profile: Dictionary) -> Array:
	var cycle_anchors: Array = _chart_cycle_shape_anchors(chart_profile)
	if not cycle_anchors.is_empty():
		return cycle_anchors
	var pattern_id: String = str(chart_profile.get("primary_pattern", "messy_range"))
	var variant: String = str(chart_profile.get("pattern_variant", "standard"))
	match pattern_id:
		"double_bottom":
			match variant:
				"measured_breakout":
					return _chart_anchor_rows([[0.00, 1.03], [0.14, 0.82], [0.27, 1.00], [0.41, 0.84], [0.56, 1.12], [0.70, 1.05], [0.86, 1.20], [1.00, 1.00]])
				"undercut_spring":
					return _chart_anchor_rows([[0.00, 1.04], [0.15, 0.88], [0.29, 1.00], [0.43, 0.80], [0.55, 1.08], [0.68, 1.00], [0.84, 1.16], [1.00, 1.00]])
				"base_no_breakout":
					return _chart_anchor_rows([[0.00, 1.02], [0.16, 0.86], [0.30, 0.99], [0.45, 0.87], [0.62, 1.04], [0.78, 0.96], [0.92, 1.05], [1.00, 1.00]])
				"failed_breakout":
					return _chart_anchor_rows([[0.00, 1.05], [0.16, 0.84], [0.30, 1.02], [0.44, 0.86], [0.58, 1.11], [0.70, 0.96], [0.86, 0.90], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 1.03], [0.15, 0.83], [0.28, 1.00], [0.42, 0.85], [0.56, 1.12], [0.68, 1.04], [0.84, 1.18], [1.00, 1.00]])
		"inverse_head_shoulders":
			match variant:
				"right_shoulder_shakeout":
					return _chart_anchor_rows([[0.00, 1.03], [0.12, 0.90], [0.26, 1.01], [0.42, 0.77], [0.56, 1.03], [0.69, 0.87], [0.82, 1.15], [1.00, 1.00]])
				"slow_neckline_grind":
					return _chart_anchor_rows([[0.00, 1.00], [0.16, 0.89], [0.30, 0.99], [0.45, 0.80], [0.58, 1.01], [0.72, 0.93], [0.90, 1.10], [1.00, 1.00]])
				"failed_neckline":
					return _chart_anchor_rows([[0.00, 1.02], [0.14, 0.88], [0.28, 1.01], [0.43, 0.78], [0.56, 1.02], [0.70, 0.90], [0.84, 1.07], [0.94, 0.95], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 1.02], [0.14, 0.88], [0.28, 1.00], [0.42, 0.78], [0.55, 1.02], [0.68, 0.91], [0.84, 1.15], [1.00, 1.00]])
		"cup_handle":
			match variant:
				"deep_cup_shallow_handle":
					return _chart_anchor_rows([[0.00, 1.10], [0.16, 0.96], [0.36, 0.76], [0.56, 0.94], [0.72, 1.10], [0.82, 1.05], [0.92, 1.16], [1.00, 1.00]])
				"long_handle_grind":
					return _chart_anchor_rows([[0.00, 1.08], [0.18, 0.97], [0.38, 0.84], [0.58, 0.96], [0.70, 1.08], [0.84, 1.00], [0.94, 1.11], [1.00, 1.00]])
				"failed_handle":
					return _chart_anchor_rows([[0.00, 1.08], [0.16, 0.96], [0.36, 0.84], [0.58, 0.96], [0.72, 1.10], [0.84, 1.00], [0.92, 0.94], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 1.08], [0.16, 0.96], [0.36, 0.84], [0.58, 0.97], [0.72, 1.10], [0.82, 1.03], [0.92, 1.16], [1.00, 1.00]])
		"ascending_triangle":
			match variant:
				"tight_coil":
					return _chart_anchor_rows([[0.00, 0.96], [0.14, 1.07], [0.30, 0.98], [0.44, 1.08], [0.58, 1.01], [0.72, 1.09], [0.88, 1.12], [1.00, 1.00]])
				"throwback_retest":
					return _chart_anchor_rows([[0.00, 0.98], [0.14, 1.08], [0.28, 0.95], [0.42, 1.08], [0.56, 0.99], [0.70, 1.14], [0.80, 1.06], [0.92, 1.17], [1.00, 1.00]])
				"fake_breakout":
					return _chart_anchor_rows([[0.00, 0.98], [0.14, 1.08], [0.28, 0.95], [0.42, 1.08], [0.56, 0.99], [0.70, 1.13], [0.82, 0.95], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 0.98], [0.14, 1.08], [0.28, 0.94], [0.42, 1.08], [0.56, 0.98], [0.70, 1.10], [0.84, 1.17], [1.00, 1.00]])
		"rounded_base":
			match variant:
				"long_accumulation_base":
					return _chart_anchor_rows([[0.00, 1.04], [0.18, 0.95], [0.40, 0.86], [0.60, 0.91], [0.76, 1.02], [0.90, 1.10], [1.00, 1.00]])
				"sleepy_base":
					return _chart_anchor_rows([[0.00, 1.02], [0.20, 0.96], [0.42, 0.91], [0.62, 0.94], [0.80, 1.02], [0.92, 1.05], [1.00, 1.00]])
				"base_failure":
					return _chart_anchor_rows([[0.00, 1.06], [0.18, 0.95], [0.40, 0.86], [0.60, 0.92], [0.74, 1.04], [0.88, 0.92], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 1.05], [0.18, 0.94], [0.38, 0.86], [0.56, 0.92], [0.74, 1.06], [0.90, 1.13], [1.00, 1.00]])
		"bull_flag":
			match variant:
				"high_tight_flag":
					return _chart_anchor_rows([[0.00, 0.94], [0.16, 1.10], [0.32, 1.26], [0.46, 1.22], [0.60, 1.18], [0.78, 1.28], [1.00, 1.00]])
				"deep_flag_recovery":
					return _chart_anchor_rows([[0.00, 0.96], [0.18, 1.10], [0.34, 1.24], [0.52, 1.08], [0.66, 1.04], [0.84, 1.19], [1.00, 1.00]])
				"failed_flag":
					return _chart_anchor_rows([[0.00, 0.96], [0.18, 1.08], [0.35, 1.22], [0.52, 1.12], [0.66, 1.04], [0.82, 0.96], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 0.96], [0.18, 1.08], [0.35, 1.22], [0.52, 1.15], [0.66, 1.10], [0.82, 1.22], [1.00, 1.00]])
		"breakout_retest":
			match variant:
				"deep_retest_hold":
					return _chart_anchor_rows([[0.00, 0.98], [0.18, 1.02], [0.36, 1.00], [0.54, 1.15], [0.70, 1.01], [0.86, 1.17], [1.00, 1.00]])
				"stair_step_retest":
					return _chart_anchor_rows([[0.00, 0.96], [0.18, 1.02], [0.34, 1.00], [0.50, 1.10], [0.62, 1.04], [0.76, 1.16], [0.90, 1.23], [1.00, 1.00]])
				"failed_retest":
					return _chart_anchor_rows([[0.00, 0.98], [0.18, 1.02], [0.36, 1.00], [0.54, 1.15], [0.68, 1.05], [0.82, 0.94], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 0.98], [0.18, 1.02], [0.36, 1.00], [0.54, 1.15], [0.68, 1.06], [0.84, 1.20], [1.00, 1.00]])
		"higher_low_accumulation":
			match variant:
				"shakeout_then_markup":
					return _chart_anchor_rows([[0.00, 0.98], [0.14, 0.88], [0.28, 1.00], [0.42, 0.84], [0.56, 1.05], [0.72, 0.99], [0.88, 1.16], [1.00, 1.00]])
				"quiet_absorption":
					return _chart_anchor_rows([[0.00, 0.98], [0.18, 0.93], [0.34, 1.00], [0.50, 0.96], [0.66, 1.06], [0.80, 1.02], [0.92, 1.10], [1.00, 1.00]])
				"failed_accumulation":
					return _chart_anchor_rows([[0.00, 0.98], [0.16, 0.88], [0.30, 1.00], [0.44, 0.92], [0.58, 1.06], [0.74, 0.94], [0.90, 0.90], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 0.98], [0.16, 0.88], [0.30, 1.00], [0.44, 0.92], [0.58, 1.06], [0.72, 0.98], [0.88, 1.13], [1.00, 1.00]])
		"double_top":
			match variant:
				"second_top_lower":
					return _chart_anchor_rows([[0.00, 0.96], [0.18, 1.16], [0.34, 0.98], [0.50, 1.11], [0.66, 0.92], [0.84, 0.85], [1.00, 1.00]])
				"range_top_chop":
					return _chart_anchor_rows([[0.00, 0.98], [0.18, 1.14], [0.34, 0.99], [0.50, 1.13], [0.66, 0.97], [0.82, 1.04], [1.00, 1.00]])
				"failed_breakdown":
					return _chart_anchor_rows([[0.00, 0.96], [0.18, 1.16], [0.34, 0.98], [0.50, 1.15], [0.66, 0.92], [0.80, 0.98], [0.92, 1.08], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 0.96], [0.18, 1.16], [0.34, 0.98], [0.50, 1.15], [0.66, 0.92], [0.84, 0.86], [1.00, 1.00]])
		"head_shoulders":
			match variant:
				"right_shoulder_chop":
					return _chart_anchor_rows([[0.00, 0.96], [0.16, 1.12], [0.30, 0.98], [0.44, 1.24], [0.58, 0.98], [0.72, 1.10], [0.84, 0.95], [0.94, 0.88], [1.00, 1.00]])
				"slanted_neckline":
					return _chart_anchor_rows([[0.00, 0.98], [0.16, 1.12], [0.30, 1.00], [0.44, 1.24], [0.58, 0.96], [0.72, 1.09], [0.88, 0.86], [1.00, 1.00]])
				"failed_breakdown":
					return _chart_anchor_rows([[0.00, 0.96], [0.16, 1.12], [0.30, 0.98], [0.44, 1.24], [0.58, 0.98], [0.72, 1.10], [0.86, 0.94], [0.94, 1.06], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 0.96], [0.16, 1.12], [0.30, 0.98], [0.44, 1.24], [0.58, 0.98], [0.72, 1.10], [0.88, 0.88], [1.00, 1.00]])
		"descending_triangle":
			match variant:
				"tight_floor_pressure":
					return _chart_anchor_rows([[0.00, 1.08], [0.16, 0.96], [0.30, 1.03], [0.44, 0.96], [0.58, 1.00], [0.72, 0.95], [0.86, 0.92], [1.00, 1.00]])
				"breakdown_retest":
					return _chart_anchor_rows([[0.00, 1.08], [0.16, 0.96], [0.30, 1.04], [0.44, 0.96], [0.58, 1.00], [0.72, 0.86], [0.84, 0.94], [1.00, 1.00]])
				"bear_trap_reclaim":
					return _chart_anchor_rows([[0.00, 1.08], [0.16, 0.96], [0.30, 1.04], [0.44, 0.96], [0.58, 1.00], [0.72, 0.88], [0.86, 1.04], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 1.08], [0.16, 0.96], [0.30, 1.04], [0.44, 0.96], [0.58, 1.00], [0.72, 0.95], [0.88, 0.84], [1.00, 1.00]])
		"lower_high_distribution":
			match variant:
				"fast_distribution":
					return _chart_anchor_rows([[0.00, 1.10], [0.14, 1.20], [0.28, 1.00], [0.42, 1.08], [0.56, 0.92], [0.72, 0.96], [0.88, 0.82], [1.00, 1.00]])
				"range_distribution":
					return _chart_anchor_rows([[0.00, 1.06], [0.16, 1.16], [0.30, 0.99], [0.44, 1.10], [0.58, 0.96], [0.72, 1.04], [0.88, 0.94], [1.00, 1.00]])
				"failed_distribution":
					return _chart_anchor_rows([[0.00, 1.08], [0.16, 1.18], [0.30, 0.98], [0.44, 1.10], [0.58, 0.94], [0.72, 1.02], [0.88, 1.10], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 1.08], [0.16, 1.18], [0.30, 0.98], [0.44, 1.10], [0.58, 0.94], [0.72, 1.02], [0.88, 0.86], [1.00, 1.00]])
		"failed_breakout":
			match variant:
				"double_fakeout":
					return _chart_anchor_rows([[0.00, 0.98], [0.16, 1.06], [0.32, 1.00], [0.48, 1.16], [0.60, 1.02], [0.72, 1.14], [0.84, 0.90], [1.00, 1.00]])
				"late_failed_breakout":
					return _chart_anchor_rows([[0.00, 0.98], [0.20, 1.04], [0.40, 1.00], [0.62, 1.08], [0.78, 1.20], [0.88, 0.92], [1.00, 1.00]])
				"failed_then_recovery":
					return _chart_anchor_rows([[0.00, 0.98], [0.18, 1.06], [0.36, 1.02], [0.54, 1.18], [0.66, 0.92], [0.84, 1.06], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 0.98], [0.18, 1.06], [0.36, 1.02], [0.54, 1.18], [0.64, 1.05], [0.78, 0.92], [1.00, 1.00]])
		"breakdown_retest":
			match variant:
				"deep_retest_reject":
					return _chart_anchor_rows([[0.00, 1.06], [0.22, 0.98], [0.44, 1.02], [0.62, 0.84], [0.76, 0.98], [0.90, 0.82], [1.00, 1.00]])
				"grind_lower":
					return _chart_anchor_rows([[0.00, 1.08], [0.18, 1.00], [0.34, 1.02], [0.50, 0.92], [0.66, 0.96], [0.82, 0.88], [1.00, 1.00]])
				"failed_breakdown_reclaim":
					return _chart_anchor_rows([[0.00, 1.06], [0.22, 0.98], [0.44, 1.02], [0.62, 0.86], [0.76, 0.96], [0.90, 1.08], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 1.06], [0.22, 0.98], [0.44, 1.02], [0.62, 0.86], [0.76, 0.94], [0.90, 0.84], [1.00, 1.00]])
		"sma_resistance_rejection":
			match variant:
				"repeated_rejections":
					return _chart_anchor_rows([[0.00, 1.08], [0.16, 0.98], [0.30, 1.04], [0.44, 0.94], [0.58, 1.01], [0.72, 0.92], [0.86, 0.98], [1.00, 1.00]])
				"rolling_lower_sma":
					return _chart_anchor_rows([[0.00, 1.10], [0.18, 1.00], [0.34, 1.04], [0.50, 0.96], [0.66, 0.99], [0.82, 0.90], [1.00, 1.00]])
				"sma_reclaim":
					return _chart_anchor_rows([[0.00, 1.08], [0.18, 0.98], [0.34, 1.04], [0.50, 0.94], [0.66, 1.00], [0.82, 1.08], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 1.08], [0.18, 0.98], [0.34, 1.04], [0.50, 0.94], [0.66, 1.00], [0.82, 0.88], [1.00, 1.00]])
		"pump_dump":
			match variant:
				"late_pump_dump":
					return _chart_anchor_rows([[0.00, 0.96], [0.20, 1.02], [0.40, 0.98], [0.58, 1.18], [0.72, 1.48], [0.82, 0.78], [1.00, 1.00]])
				"stair_pump_dump":
					return _chart_anchor_rows([[0.00, 0.94], [0.16, 1.04], [0.30, 1.16], [0.44, 1.34], [0.56, 1.18], [0.68, 0.78], [0.84, 0.94], [1.00, 1.00]])
				"multi_spike_dump":
					return _chart_anchor_rows([[0.00, 0.94], [0.14, 1.08], [0.28, 1.34], [0.42, 1.02], [0.54, 1.44], [0.64, 0.76], [0.82, 0.96], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 0.94], [0.16, 1.05], [0.34, 1.42], [0.48, 1.18], [0.60, 0.76], [0.76, 0.94], [1.00, 1.00]])
		"false_breakout":
			match variant:
				"double_false_breakout":
					return _chart_anchor_rows([[0.00, 0.98], [0.16, 1.05], [0.30, 0.98], [0.44, 1.24], [0.56, 0.96], [0.70, 1.18], [0.84, 0.90], [1.00, 1.00]])
				"range_whipsaw":
					return _chart_anchor_rows([[0.00, 1.00], [0.16, 1.10], [0.32, 0.90], [0.48, 1.16], [0.64, 0.88], [0.82, 1.06], [1.00, 1.00]])
				"spring_reclaim":
					return _chart_anchor_rows([[0.00, 1.02], [0.20, 0.96], [0.38, 0.88], [0.54, 1.10], [0.68, 0.98], [0.84, 1.12], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 0.98], [0.20, 1.04], [0.38, 0.98], [0.54, 1.28], [0.64, 0.96], [0.82, 0.90], [1.00, 1.00]])
		"sharp_squeeze":
			match variant:
				"squeeze_fade":
					return _chart_anchor_rows([[0.00, 0.92], [0.18, 0.88], [0.36, 0.96], [0.52, 1.36], [0.66, 1.14], [0.82, 0.94], [1.00, 1.00]])
				"late_squeeze":
					return _chart_anchor_rows([[0.00, 0.94], [0.22, 0.90], [0.44, 0.96], [0.66, 1.04], [0.82, 1.38], [0.92, 1.18], [1.00, 1.00]])
				"two_leg_squeeze":
					return _chart_anchor_rows([[0.00, 0.92], [0.18, 0.88], [0.34, 1.08], [0.48, 0.98], [0.62, 1.34], [0.78, 1.18], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 0.92], [0.18, 0.88], [0.36, 0.96], [0.52, 1.34], [0.66, 1.18], [0.82, 1.04], [1.00, 1.00]])
		"rug_pull_volume":
			match variant:
				"delayed_rug_pull":
					return _chart_anchor_rows([[0.00, 0.96], [0.20, 1.04], [0.40, 1.12], [0.58, 1.34], [0.70, 0.78], [0.84, 0.88], [1.00, 1.00]])
				"stair_step_rug":
					return _chart_anchor_rows([[0.00, 0.96], [0.16, 1.06], [0.32, 1.20], [0.48, 1.30], [0.60, 1.04], [0.72, 0.78], [1.00, 1.00]])
				"rebound_after_rug":
					return _chart_anchor_rows([[0.00, 0.96], [0.18, 1.10], [0.36, 1.30], [0.50, 1.22], [0.58, 0.78], [0.76, 1.02], [1.00, 1.00]])
				_:
					return _chart_anchor_rows([[0.00, 0.96], [0.18, 1.10], [0.36, 1.30], [0.50, 1.22], [0.58, 0.78], [0.76, 0.88], [1.00, 1.00]])
	match variant:
		"tightening_range":
			return _chart_anchor_rows([[0.00, 1.00], [0.16, 1.10], [0.32, 0.92], [0.48, 1.06], [0.64, 0.96], [0.82, 1.04], [1.00, 1.00]])
		"shakeout_range":
			return _chart_anchor_rows([[0.00, 1.00], [0.16, 0.90], [0.32, 1.08], [0.48, 0.94], [0.64, 1.10], [0.82, 0.92], [1.00, 1.00]])
		"range_break_fake":
			return _chart_anchor_rows([[0.00, 1.00], [0.18, 1.08], [0.34, 0.94], [0.52, 1.16], [0.66, 0.96], [0.86, 1.04], [1.00, 1.00]])
		_:
			return _chart_anchor_rows([[0.00, 1.00], [0.18, 1.08], [0.34, 0.94], [0.52, 1.07], [0.70, 0.95], [0.86, 1.05], [1.00, 1.00]])


func _chart_anchor_rows(rows: Array) -> Array:
	var anchors: Array = []
	for row_value in rows:
		var row: Array = row_value
		anchors.append({"t": float(row[0]), "m": float(row[1])})
	return anchors


func _interpolate_chart_shape(anchors: Array, progress: float) -> float:
	if anchors.is_empty():
		return 1.0
	var previous_anchor: Dictionary = anchors[0]
	for anchor_index in range(1, anchors.size()):
		var next_anchor: Dictionary = anchors[anchor_index]
		var left_t: float = float(previous_anchor.get("t", 0.0))
		var right_t: float = float(next_anchor.get("t", 1.0))
		if progress <= right_t:
			var local_t: float = clamp((progress - left_t) / max(right_t - left_t, 0.0001), 0.0, 1.0)
			local_t = local_t * local_t * (3.0 - (2.0 * local_t))
			return lerp(float(previous_anchor.get("m", 1.0)), float(next_anchor.get("m", 1.0)), local_t)
		previous_anchor = next_anchor
	return float(anchors[anchors.size() - 1].get("m", 1.0))


func _chart_wave_component(chart_profile: Dictionary, progress: float, run_seed: int, company_id: String) -> float:
	var archetype: String = str(chart_profile.get("archetype", "range_bound"))
	var volatility_style: String = str(chart_profile.get("volatility_style", "normal"))
	var amplitude: float = 0.018
	var cycles: float = 7.0
	if volatility_style == "smooth":
		amplitude = 0.010
		cycles = 4.0
	elif volatility_style == "swingy":
		amplitude = 0.026
		cycles = 6.0
	elif volatility_style == "spiky" or archetype == "gorengan":
		amplitude = 0.036 if archetype == "gorengan" else 0.032
		cycles = 8.4 if archetype == "gorengan" else 7.6
	elif volatility_style == "heavy":
		amplitude = 0.024
		cycles = 5.0
	var phase: float = _sample_noise(run_seed, company_id, "chart_profile_wave_phase", 0.0, TAU, 1)
	return sin((progress * TAU * cycles) + phase) * amplitude * sin(progress * PI)


func _chart_noise_scale(volatility_style: String) -> float:
	match volatility_style:
		"smooth":
			return 0.006
		"swingy":
			return 0.014
		"spiky":
			return 0.018
		"heavy":
			return 0.012
	return 0.010


func _apply_chart_sma_behavior(close_price: float, closes: Array, chart_profile: Dictionary, progress: float) -> float:
	var behavior: String = str(chart_profile.get("sma_behavior", "ignored"))
	if behavior == "ignored" or progress < 0.18:
		return close_price
	var period: int = int(chart_profile.get("preferred_sma_period", 20))
	var sma_value: float = _chart_sma_value(closes, period)
	if sma_value <= 0.0:
		return close_price
	var distance: float = (close_price - sma_value) / max(sma_value, 1.0)
	if behavior == "support" and distance >= -0.070 and distance <= 0.030:
		return lerp(close_price, sma_value * 1.012, 0.42)
	if behavior == "resistance" and distance >= -0.030 and distance <= 0.075:
		return lerp(close_price, sma_value * 0.988, 0.40)
	if behavior == "magnet" and absf(distance) <= 0.12:
		return lerp(close_price, sma_value, 0.18)
	return close_price


func _chart_sma_value(closes: Array, period: int) -> float:
	if period <= 0 or closes.size() < period:
		return 0.0
	var total: float = 0.0
	for index in range(closes.size() - period, closes.size()):
		total += float(closes[index])
	return total / float(period)


func _chart_intraday_range_ratio(
	chart_profile: Dictionary,
	day_move_ratio: float,
	run_seed: int,
	company_id: String,
	bar_index: int
) -> float:
	var volatility_style: String = str(chart_profile.get("volatility_style", "normal"))
	var base_range: float = 0.010
	if volatility_style == "smooth":
		base_range = 0.006
	elif volatility_style == "swingy":
		base_range = 0.014
	elif volatility_style == "spiky":
		base_range = 0.024
	elif volatility_style == "heavy":
		base_range = 0.016
	var noise: float = _sample_noise(run_seed, company_id, "chart_profile_intraday", 0.65, 1.45, bar_index + 1)
	return clamp(max(day_move_ratio * 0.85, base_range * noise), 0.003, 0.090)


func _chart_volume_multiplier(
	chart_profile: Dictionary,
	progress: float,
	daily_return: float,
	run_seed: int,
	company_id: String,
	bar_index: int
) -> float:
	var behavior: String = str(chart_profile.get("volume_behavior", "neutral"))
	var archetype: String = str(chart_profile.get("archetype", "range_bound"))
	var multiplier: float = 0.92
	if behavior == "accumulation":
		multiplier = 0.72 if progress < 0.52 else 1.05
		if progress >= 0.58 and daily_return > 0.006:
			multiplier += 0.72
		if progress >= 0.74 and daily_return > 0.012:
			multiplier += 0.46
	elif behavior == "distribution":
		multiplier = 1.05
		if progress >= 0.42 and daily_return < -0.006:
			multiplier += 0.82
		if progress >= 0.62 and daily_return < -0.012:
			multiplier += 0.56
	elif behavior == "spike" or archetype == "gorengan":
		multiplier = 1.10 + absf(daily_return) * 12.0
		var spike_roll: float = _sample_noise(run_seed, company_id, "chart_profile_volume_spike", 0.0, 1.0, bar_index + 1)
		if spike_roll > 0.935 or (progress > 0.42 and progress < 0.64 and absf(daily_return) > 0.018):
			multiplier += 2.2
	else:
		if absf(daily_return) > 0.010:
			multiplier += 0.28
	var noise: float = _sample_noise(run_seed, company_id, "chart_profile_volume_noise", 0.82, 1.22, bar_index + 1)
	return clamp(multiplier * noise, 0.32, 5.8)


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
			if market_cap_trillions < 1.0:
				fundamental_price_floor = lerp(80.0, 1650.0, pow(scarcity_score, 1.35))
			else:
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
	return STABLE_RNG.rng([run_seed, "company", company_id, salt])


func _sample_noise(
	run_seed: int,
	company_id: String,
	salt: String,
	minimum: float,
	maximum: float,
	year: int
) -> float:
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "company_noise", company_id, salt, year])
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
