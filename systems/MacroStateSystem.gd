extends RefCounted

const STABLE_RNG = preload("res://systems/StableRng.gd")
const BASE_YEAR := 2020
const BASE_POLICY_RATE := 5.0


func build_year_state(
	run_seed: int,
	year: int,
	sector_definitions: Array,
	previous_state: Dictionary = {}
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
		"headwind_sectors": headwinds
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
