extends RefCounted

const STABLE_RNG = preload("res://systems/StableRng.gd")
const BASE_YEAR := 2020
const BASE_POLICY_RATE := 5.0


func build_year_state(
	run_seed: int,
	year: int,
	sector_definitions: Array,
	previous_state: Dictionary = {},
	commodity_indicator_catalog: Dictionary = {}
) -> Dictionary:
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "macro", year])

	var previous_inflation: float = float(previous_state.get("inflation_yoy", 3.2))
	var previous_gdp_growth: float = float(previous_state.get("gdp_growth", 5.0))
	var previous_employment_index: float = float(previous_state.get("employment_index", 0.58))
	var previous_policy_rate: float = float(previous_state.get("policy_rate", BASE_POLICY_RATE))

	var inflation_yoy: float = clamp(
		lerpf(previous_inflation, rng.randf_range(2.0, 6.5), 0.68),
		1.4,
		7.6
	)
	var gdp_growth: float = clamp(
		lerpf(previous_gdp_growth, rng.randf_range(1.6, 6.8), 0.62),
		-1.2,
		7.8
	)
	var employment_index: float = clamp(
		lerpf(previous_employment_index, rng.randf_range(0.3, 0.85), 0.58),
		0.15,
		0.92
	)
	var unemployment_rate: float = clamp(
		8.2 - (employment_index * 4.4) + rng.randf_range(-0.35, 0.35),
		2.8,
		8.8
	)

	var policy_signal: float = 0.0
	policy_signal += (inflation_yoy - 3.1) * 0.95
	policy_signal += max(gdp_growth - 4.8, 0.0) * 0.35
	policy_signal += max(employment_index - 0.58, 0.0) * 1.1
	policy_signal -= max(4.0 - gdp_growth, 0.0) * 0.75
	policy_signal -= max(0.46 - employment_index, 0.0) * 1.3

	var policy_action_bps: int = 0
	var central_bank_stance: String = "hold"
	if policy_signal >= 1.45:
		policy_action_bps = 50
		central_bank_stance = "hike"
	elif policy_signal >= 0.55:
		policy_action_bps = 25
		central_bank_stance = "hike"
	elif policy_signal <= -1.45:
		policy_action_bps = -50
		central_bank_stance = "cut"
	elif policy_signal <= -0.55:
		policy_action_bps = -25
		central_bank_stance = "cut"

	var policy_rate: float = clamp(
		previous_policy_rate + (float(policy_action_bps) / 100.0),
		2.0,
		8.0
	)
	var growth_gap: float = gdp_growth - 4.8
	var employment_gap: float = employment_index - 0.55
	var risk_appetite: float = clamp(
		0.5 +
		(growth_gap * 0.08) +
		(employment_gap * 0.28) -
		(max(inflation_yoy - 4.5, 0.0) * 0.07) -
		(abs(float(policy_action_bps)) / 100.0 * 0.05) +
		rng.randf_range(-0.04, 0.04),
		0.0,
		1.0
	)
	var market_bias: float = clamp(
		(growth_gap * 0.0042) +
		(employment_gap * 0.0105) -
		(max(inflation_yoy - 4.4, 0.0) * 0.0055) -
		(max(policy_rate - 5.0, 0.0) * 0.0018) +
		((risk_appetite - 0.5) * 0.01),
		-0.026,
		0.026
	)
	var volatility_multiplier: float = clamp(
		1.0 +
		(max(inflation_yoy - 5.0, 0.0) * 0.12) +
		(max(0.42 - employment_index, 0.0) * 0.65) +
		((0.5 - risk_appetite) * 0.3),
		0.8,
		1.75
	)
	var sector_biases: Dictionary = _build_sector_biases(
		sector_definitions,
		gdp_growth,
		inflation_yoy,
		employment_index,
		policy_rate,
		policy_action_bps,
		risk_appetite
	)
	var beneficiaries: Array = _pick_sector_extremes(sector_biases, true)
	var headwinds: Array = _pick_sector_extremes(sector_biases, false)
	var commodity_indicators: Dictionary = _build_commodity_indicators(
		run_seed,
		year,
		commodity_indicator_catalog,
		previous_state,
		gdp_growth,
		inflation_yoy,
		employment_index,
		policy_rate,
		risk_appetite,
		sector_biases
	)
	var outlook: Dictionary = {
		"year": year,
		"inflation_yoy": snappedf(inflation_yoy, 0.1),
		"gdp_growth": snappedf(gdp_growth, 0.1),
		"employment_index": snappedf(employment_index, 0.01),
		"employment_label": _employment_label(employment_index),
		"unemployment_rate": snappedf(unemployment_rate, 0.1),
		"central_bank_stance": central_bank_stance,
		"policy_action_bps": policy_action_bps,
		"policy_rate": snappedf(policy_rate, 0.25),
		"risk_appetite": snappedf(risk_appetite, 0.01),
		"market_bias": snappedf(market_bias, 0.0001),
		"volatility_multiplier": snappedf(volatility_multiplier, 0.01),
		"sector_biases": sector_biases,
		"favored_sectors": beneficiaries,
		"headwind_sectors": headwinds,
		"commodity_indicators": commodity_indicators,
		"commodity_regime_counts": _commodity_regime_counts(commodity_indicators),
		"commodity_leaders": _pick_commodity_extremes(commodity_indicators, true),
		"commodity_laggards": _pick_commodity_extremes(commodity_indicators, false)
	}
	outlook["headline"] = _build_headline(outlook)
	outlook["briefing_lines"] = _build_briefing_lines(outlook)
	return outlook


func _build_sector_biases(
	sector_definitions: Array,
	gdp_growth: float,
	inflation_yoy: float,
	employment_index: float,
	policy_rate: float,
	policy_action_bps: int,
	risk_appetite: float
) -> Dictionary:
	var biases: Dictionary = {}
	var growth_gap: float = gdp_growth - 4.8
	var inflation_gap: float = inflation_yoy - 3.2
	var employment_gap: float = employment_index - 0.55
	var rate_gap: float = policy_rate - BASE_POLICY_RATE
	var rate_step: float = float(policy_action_bps) / 25.0
	var defensive_demand: float = 0.5 - risk_appetite

	for sector_definition_value in sector_definitions:
		var sector_definition: Dictionary = sector_definition_value
		var sector_id: String = str(sector_definition.get("id", ""))
		var bias: float = 0.0
		match sector_id:
			"consumer":
				bias += (employment_gap * 0.014)
				bias -= (inflation_gap * 0.004)
			"industrial":
				bias += (growth_gap * 0.008)
				bias += (employment_gap * 0.005)
				bias -= max(rate_gap, 0.0) * 0.002
			"energy":
				bias += (inflation_gap * 0.0055)
				bias += max(growth_gap, 0.0) * 0.004
			"tech":
				bias += ((risk_appetite - 0.5) * 0.018)
				bias -= max(rate_gap, 0.0) * 0.004
				bias -= max(rate_step, 0.0) * 0.0025
				bias += max(-rate_step, 0.0) * 0.002
			"infra":
				bias += (growth_gap * 0.006)
				bias -= max(rate_gap, 0.0) * 0.0035
			"transport":
				bias += (growth_gap * 0.0065)
				bias -= max(inflation_gap, 0.0) * 0.0045
			"health":
				bias += (defensive_demand * 0.01)
				bias += max(0.45 - employment_index, 0.0) * 0.005
			"finance":
				bias += max(rate_step, 0.0) * 0.004
				bias += max(rate_gap, 0.0) * 0.0025
				bias += (growth_gap * 0.004)
				bias -= max(-rate_step, 0.0) * 0.0025
			"basicindustry":
				bias += (growth_gap * 0.007)
				bias += max(inflation_gap, 0.0) * 0.003
			"property":
				bias += max(-rate_step, 0.0) * 0.004
				bias += max(employment_gap, 0.0) * 0.004
				bias -= max(rate_gap, 0.0) * 0.005
			"noncyclical":
				bias += (defensive_demand * 0.012)
				bias -= max(growth_gap, 0.0) * 0.0025
			_:
				bias += (growth_gap * 0.003)

		biases[sector_id] = snappedf(clamp(bias, -0.018, 0.018), 0.0001)

	return biases


func _pick_sector_extremes(sector_biases: Dictionary, pick_positive: bool) -> Array:
	var rows: Array = []
	for sector_id in sector_biases.keys():
		rows.append({
			"sector_id": str(sector_id),
			"bias": float(sector_biases[sector_id])
		})

	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("bias", 0.0)) > float(b.get("bias", 0.0))
	)
	if not pick_positive:
		rows.reverse()

	var selected: Array = []
	for row_value in rows:
		var row: Dictionary = row_value
		var bias: float = float(row.get("bias", 0.0))
		if pick_positive and bias <= 0.0:
			continue
		if not pick_positive and bias >= 0.0:
			continue
		selected.append(str(row.get("sector_id", "")))
		if selected.size() >= 3:
			break

	return selected


func _build_commodity_indicators(
	run_seed: int,
	year: int,
	catalog: Dictionary,
	previous_state: Dictionary,
	gdp_growth: float,
	inflation_yoy: float,
	employment_index: float,
	policy_rate: float,
	risk_appetite: float,
	sector_biases: Dictionary
) -> Dictionary:
	var commodities_value: Variant = catalog.get("commodities", [])
	if typeof(commodities_value) != TYPE_ARRAY:
		return {}

	var thresholds: Dictionary = _commodity_thresholds(catalog)
	var previous_indicators: Dictionary = previous_state.get("commodity_indicators", {})
	var indicators: Dictionary = {}
	for commodity_value in commodities_value:
		if typeof(commodity_value) != TYPE_DICTIONARY:
			continue
		var commodity: Dictionary = commodity_value
		var commodity_id: String = str(commodity.get("id", "")).strip_edges()
		if commodity_id.is_empty():
			continue
		var model: Dictionary = commodity.get("model", {})
		var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "macro_commodity", year, commodity_id])
		var neutral_level: float = float(model.get("neutral_level", 100.0))
		var previous_entry: Dictionary = previous_indicators.get(commodity_id, {})
		var previous_level: float = float(previous_entry.get("level", neutral_level))
		var previous_ytd_move: float = float(previous_entry.get("ytd_move", 0.0))
		var driver_score: float = _commodity_driver_score(
			commodity,
			gdp_growth,
			inflation_yoy,
			employment_index,
			policy_rate,
			risk_appetite,
			sector_biases
		)
		var persistence: float = clamp(float(model.get("trend_persistence", 0.45)), 0.0, 0.9)
		var mean_reversion: float = clamp(float(model.get("mean_reversion", 0.25)), 0.0, 0.75)
		var volatility_base: float = clamp(float(model.get("volatility_base", 0.24)), 0.05, 0.65)
		var level_floor: float = float(model.get("level_floor", 60.0))
		var level_ceiling: float = float(model.get("level_ceiling", 160.0))
		var ytd_floor: float = float(model.get("ytd_move_floor", -32.0))
		var ytd_ceiling: float = float(model.get("ytd_move_ceiling", 42.0))
		var random_shock: float = rng.randf_range(-1.0, 1.0) * volatility_base * 34.0
		var ytd_move: float = clamp(
			(previous_ytd_move * persistence * 0.32) +
			(driver_score * volatility_base * 28.0) +
			random_shock,
			ytd_floor,
			ytd_ceiling
		)
		var reversion_drag: float = ((previous_level - neutral_level) / max(neutral_level, 1.0)) * mean_reversion * 18.0
		var level: float = clamp(
			previous_level + (ytd_move * 0.72) - reversion_drag,
			level_floor,
			level_ceiling
		)
		var ytd_abs_ceiling: float = max(absf(ytd_ceiling), absf(ytd_floor))
		var volatility: float = clamp(
			volatility_base +
			(absf(ytd_move) / max(ytd_abs_ceiling, 1.0) * 0.18) +
			(rng.randf_range(-0.025, 0.025)),
			0.05,
			0.8
		)
		var direction: String = _commodity_direction(ytd_move, thresholds.get("direction", {}))
		var regime: String = _commodity_regime(level, ytd_move, thresholds.get("regime", {}))
		indicators[commodity_id] = {
			"id": commodity_id,
			"display_name": str(commodity.get("display_name", commodity_id)),
			"category": str(commodity.get("category", "other")),
			"level": snappedf(level, 0.1),
			"direction": direction,
			"volatility": snappedf(volatility, 0.01),
			"regime": regime,
			"ytd_move": snappedf(ytd_move, 0.1),
			"driver_score": snappedf(driver_score, 0.01),
			"related_sectors": commodity.get("related_sectors", []).duplicate(true),
			"story_tags": commodity.get("story_tags", []).duplicate(true)
		}
	return indicators


func _commodity_thresholds(catalog: Dictionary) -> Dictionary:
	var defaults: Dictionary = {
		"direction": {
			"falling_below": -12.0,
			"softening_below": -4.0,
			"firming_above": 4.0,
			"rising_above": 12.0
		},
		"regime": {
			"bear_below_level": 82.0,
			"soft_below_level": 94.0,
			"firm_above_level": 106.0,
			"bull_above_level": 118.0
		}
	}
	var global_thresholds: Dictionary = catalog.get("global_thresholds", {})
	for threshold_group_value in defaults.keys():
		var threshold_group: String = str(threshold_group_value)
		var global_group_value: Variant = global_thresholds.get(threshold_group, {})
		if typeof(global_group_value) != TYPE_DICTIONARY:
			continue
		var global_group: Dictionary = global_group_value
		var default_group: Dictionary = defaults.get(threshold_group, {})
		for threshold_key_value in default_group.keys():
			var threshold_key: String = str(threshold_key_value)
			if global_group.has(threshold_key):
				default_group[threshold_key] = float(global_group.get(threshold_key))
		defaults[threshold_group] = default_group
	return defaults


func _commodity_driver_score(
	commodity: Dictionary,
	gdp_growth: float,
	inflation_yoy: float,
	employment_index: float,
	policy_rate: float,
	risk_appetite: float,
	sector_biases: Dictionary
) -> float:
	var score: float = 0.0
	var drivers: Array = commodity.get("macro_drivers", [])
	if drivers.is_empty():
		drivers = ["global_trade", "industrial_activity"]
	for driver_value in drivers:
		score += _commodity_driver_value(
			str(driver_value),
			gdp_growth,
			inflation_yoy,
			employment_index,
			policy_rate,
			risk_appetite,
			sector_biases
		)
	score /= max(float(drivers.size()), 1.0)
	var related_sectors: Array = commodity.get("related_sectors", [])
	var sector_score: float = 0.0
	for sector_id_value in related_sectors:
		sector_score += clamp(float(sector_biases.get(str(sector_id_value), 0.0)) / 0.018, -1.0, 1.0)
	if not related_sectors.is_empty():
		score = (score * 0.76) + ((sector_score / float(related_sectors.size())) * 0.24)
	return clamp(score, -1.0, 1.0)


func _commodity_driver_value(
	driver: String,
	gdp_growth: float,
	inflation_yoy: float,
	employment_index: float,
	policy_rate: float,
	risk_appetite: float,
	sector_biases: Dictionary
) -> float:
	match driver:
		"industrial_activity":
			return clamp((gdp_growth - 4.0) / 3.2, -1.0, 1.0)
		"global_trade":
			return clamp((gdp_growth - 3.6) / 3.4, -1.0, 1.0)
		"domestic_demand":
			return clamp(((employment_index - 0.48) * 2.1) + ((risk_appetite - 0.5) * 0.8), -1.0, 1.0)
		"consumer_confidence":
			return clamp(((employment_index - 0.5) * 1.8) + ((risk_appetite - 0.5) * 1.0), -1.0, 1.0)
		"inflation", "global_food_prices":
			return clamp((inflation_yoy - 3.2) / 3.2, -1.0, 1.0)
		"interest_rate":
			return clamp((BASE_POLICY_RATE - policy_rate) / 3.0, -1.0, 1.0)
		"fx":
			return clamp((inflation_yoy - 3.6) / 3.4 - ((risk_appetite - 0.5) * 0.45), -1.0, 1.0)
		"risk_appetite":
			return clamp((risk_appetite - 0.5) * 2.0, -1.0, 1.0)
		"geopolitical_risk":
			return clamp((0.55 - risk_appetite) * 1.55 + max(inflation_yoy - 4.8, 0.0) * 0.12, -1.0, 1.0)
		"weather_shock":
			return clamp(max(inflation_yoy - 4.4, 0.0) * 0.24 - max(gdp_growth - 5.4, 0.0) * 0.08, -1.0, 1.0)
		"energy_policy", "export_policy", "import_policy", "regulatory_support", "government_spending", "food_security_policy", "biofuel_policy", "carbon_policy":
			return clamp((inflation_yoy - 3.4) * 0.16 + (gdp_growth - 4.8) * 0.08, -1.0, 1.0)
		"infrastructure_budget", "construction_cycle":
			return clamp(float(sector_biases.get("infra", 0.0)) / 0.018 + (gdp_growth - 4.8) * 0.10, -1.0, 1.0)
		"property_cycle":
			return clamp(float(sector_biases.get("property", 0.0)) / 0.018, -1.0, 1.0)
		"digital_adoption", "semiconductor_cycle", "ev_demand", "solar_demand":
			return clamp(float(sector_biases.get("tech", 0.0)) / 0.018 + ((risk_appetite - 0.5) * 0.7), -1.0, 1.0)
		"logistics_cost", "crude_oil_pass_through":
			return clamp((inflation_yoy - 3.3) / 3.6 + max(4.8 - gdp_growth, 0.0) * 0.08, -1.0, 1.0)
		"packaging_demand":
			return clamp((gdp_growth - 4.2) / 3.2 + ((employment_index - 0.55) * 0.8), -1.0, 1.0)
		"coal":
			return clamp(float(sector_biases.get("energy", 0.0)) / 0.018 + (inflation_yoy - 3.2) * 0.08, -1.0, 1.0)
		"natural_gas":
			return clamp(float(sector_biases.get("energy", 0.0)) / 0.018 + (gdp_growth - 4.8) * 0.08, -1.0, 1.0)
		_:
			return clamp((gdp_growth - 4.8) * 0.08 + (risk_appetite - 0.5) * 0.5, -1.0, 1.0)


func _commodity_direction(ytd_move: float, thresholds: Dictionary) -> String:
	if ytd_move <= float(thresholds.get("falling_below", -12.0)):
		return "falling"
	if ytd_move < float(thresholds.get("softening_below", -4.0)):
		return "softening"
	if ytd_move >= float(thresholds.get("rising_above", 12.0)):
		return "rising"
	if ytd_move > float(thresholds.get("firming_above", 4.0)):
		return "firming"
	return "flat"


func _commodity_regime(level: float, ytd_move: float, thresholds: Dictionary) -> String:
	if level <= float(thresholds.get("bear_below_level", 82.0)) or ytd_move <= -18.0:
		return "bear"
	if level < float(thresholds.get("soft_below_level", 94.0)) or ytd_move <= -8.0:
		return "soft"
	if level >= float(thresholds.get("bull_above_level", 118.0)) or ytd_move >= 18.0:
		return "bull"
	if level > float(thresholds.get("firm_above_level", 106.0)) or ytd_move >= 8.0:
		return "firm"
	return "neutral"


func _commodity_regime_counts(commodity_indicators: Dictionary) -> Dictionary:
	var counts: Dictionary = {
		"bear": 0,
		"soft": 0,
		"neutral": 0,
		"firm": 0,
		"bull": 0
	}
	for commodity_id_value in commodity_indicators.keys():
		var indicator: Dictionary = commodity_indicators.get(commodity_id_value, {})
		var regime: String = str(indicator.get("regime", "neutral"))
		counts[regime] = int(counts.get(regime, 0)) + 1
	return counts


func _pick_commodity_extremes(commodity_indicators: Dictionary, pick_positive: bool) -> Array:
	var rows: Array = []
	for commodity_id_value in commodity_indicators.keys():
		var commodity_id: String = str(commodity_id_value)
		var indicator: Dictionary = commodity_indicators.get(commodity_id, {})
		rows.append({
			"id": commodity_id,
			"ytd_move": float(indicator.get("ytd_move", 0.0))
		})
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_move: float = float(left.get("ytd_move", 0.0))
		var right_move: float = float(right.get("ytd_move", 0.0))
		if is_equal_approx(left_move, right_move):
			return str(left.get("id", "")) < str(right.get("id", ""))
		return left_move > right_move
	)
	if not pick_positive:
		rows.reverse()
	var selected: Array = []
	for row_value in rows:
		var row: Dictionary = row_value
		var move: float = float(row.get("ytd_move", 0.0))
		if pick_positive and move <= 0.0:
			continue
		if not pick_positive and move >= 0.0:
			continue
		selected.append(str(row.get("id", "")))
		if selected.size() >= 3:
			break
	return selected


func _employment_label(employment_index: float) -> String:
	if employment_index >= 0.72:
		return "Very Strong"
	if employment_index >= 0.58:
		return "Firm"
	if employment_index >= 0.46:
		return "Mixed"
	if employment_index >= 0.34:
		return "Soft"
	return "Weak"


func _build_headline(outlook: Dictionary) -> String:
	var rate_text: String = "%s to %s%%" % [
		str(outlook.get("central_bank_stance", "hold")).capitalize(),
		String.num(float(outlook.get("policy_rate", 0.0)), 2)
	]
	return "%d macro setup: inflation %s%%, GDP %s%%, employment %s, central bank %s." % [
		int(outlook.get("year", BASE_YEAR)),
		String.num(float(outlook.get("inflation_yoy", 0.0)), 1),
		String.num(float(outlook.get("gdp_growth", 0.0)), 1),
		str(outlook.get("employment_label", "Mixed")).to_lower(),
		rate_text.to_lower()
	]


func _build_briefing_lines(outlook: Dictionary) -> Array:
	var favored_sectors: Array = outlook.get("favored_sectors", []).duplicate()
	var headwind_sectors: Array = outlook.get("headwind_sectors", []).duplicate()
	var lines: Array = [
		"Inflation prints at %s%% while GDP growth starts the year at %s%%." % [
			String.num(float(outlook.get("inflation_yoy", 0.0)), 1),
			String.num(float(outlook.get("gdp_growth", 0.0)), 1)
		],
		"Employment reads %s and the policy rate opens at %s%% after a %s bps decision." % [
			str(outlook.get("employment_label", "Mixed")).to_lower(),
			String.num(float(outlook.get("policy_rate", 0.0)), 2),
			int(outlook.get("policy_action_bps", 0))
		]
	]
	if not favored_sectors.is_empty():
		lines.append("Macro tailwinds lean toward %s." % ", ".join(favored_sectors))
	if not headwind_sectors.is_empty():
		lines.append("Macro headwinds weigh on %s." % ", ".join(headwind_sectors))
	return lines
