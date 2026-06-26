extends RefCounted

const DRIFT_MIN := -0.004
const DRIFT_MAX := 0.004
const VOLATILITY_MIN := 0.90
const VOLATILITY_MAX := 1.16
const VOLUME_MIN := 0.92
const VOLUME_MAX := 1.22
const BASE_POLICY_RATE := 5.0


func resolve(company_definition: Dictionary, macro_state: Dictionary, story_state: Dictionary = {}) -> Dictionary:
	var commodity_rows: Array = _commodity_rows(company_definition, macro_state)
	var macro_rows: Array = _macro_rows(company_definition, macro_state)
	var story_rows: Array = _story_rows(story_state)
	var rows: Array = []
	rows.append_array(commodity_rows)
	rows.append_array(macro_rows)
	rows.append_array(story_rows)

	if rows.is_empty():
		return _neutral_result()

	var commodity_score: float = _weighted_average_score(commodity_rows)
	var macro_score: float = _weighted_average_score(macro_rows)
	var story_score: float = _weighted_average_score(story_rows)
	var raw_score: float = clamp((commodity_score * 0.58) + (macro_score * 0.32) + (story_score * 0.10), -1.0, 1.0)
	var moat_modifier: float = _moat_modifier(raw_score, company_definition.get("moat_tags", []))
	var risk_modifier: float = _risk_modifier(raw_score, company_definition.get("price_traits", {}))
	var adjusted_score: float = clamp(raw_score * moat_modifier * risk_modifier, -1.0, 1.0)
	var confidence: float = _confidence(rows, adjusted_score)
	var activity_score: float = clamp((absf(adjusted_score) * 0.75) + (confidence * 0.25), 0.0, 1.0)
	var volatility_multiplier: float = _volatility_multiplier(activity_score, company_definition.get("price_traits", {}))
	var volume_multiplier: float = _volume_multiplier(activity_score, company_definition.get("price_traits", {}))

	rows.sort_custom(func(left_row: Dictionary, right_row: Dictionary) -> bool:
		var left_contribution: float = absf(float(left_row.get("contribution", 0.0)))
		var right_contribution: float = absf(float(right_row.get("contribution", 0.0)))
		if is_equal_approx(left_contribution, right_contribution):
			return str(left_row.get("id", "")) < str(right_row.get("id", ""))
		return left_contribution > right_contribution
	)

	return {
		"exposure_drift_adjustment": clamp(adjusted_score * DRIFT_MAX, DRIFT_MIN, DRIFT_MAX),
		"exposure_volatility_multiplier": volatility_multiplier,
		"exposure_volume_multiplier": volume_multiplier,
		"exposure_confidence": confidence,
		"exposure_rows": rows,
		"exposure_summary": _summary(rows, adjusted_score),
		"commodity_score": commodity_score,
		"macro_score": macro_score,
		"story_score": story_score,
		"raw_exposure_score": raw_score,
		"adjusted_exposure_score": adjusted_score,
		"moat_modifier": moat_modifier,
		"risk_modifier": risk_modifier
	}


func _neutral_result() -> Dictionary:
	return {
		"exposure_drift_adjustment": 0.0,
		"exposure_volatility_multiplier": 1.0,
		"exposure_volume_multiplier": 1.0,
		"exposure_confidence": 0.0,
		"exposure_rows": [],
		"exposure_summary": "",
		"commodity_score": 0.0,
		"macro_score": 0.0,
		"story_score": 0.0,
		"raw_exposure_score": 0.0,
		"adjusted_exposure_score": 0.0,
		"moat_modifier": 1.0,
		"risk_modifier": 1.0
	}


func _commodity_rows(company_definition: Dictionary, macro_state: Dictionary) -> Array:
	var exposures_value: Variant = company_definition.get("commodity_exposures", {})
	if typeof(exposures_value) != TYPE_DICTIONARY:
		return []
	var indicators_value: Variant = macro_state.get("commodity_indicators", {})
	if typeof(indicators_value) != TYPE_DICTIONARY:
		return []

	var exposures: Dictionary = exposures_value
	var indicators: Dictionary = indicators_value
	var rows: Array = []
	for commodity_key_value in exposures.keys():
		var commodity_id: String = str(commodity_key_value)
		if not indicators.has(commodity_id):
			continue
		var exposure: float = clamp(float(exposures.get(commodity_key_value, 0.0)), -1.0, 1.0)
		if is_zero_approx(exposure):
			continue
		var indicator: Dictionary = indicators.get(commodity_id, {})
		var signal_score: float = _commodity_signal(indicator)
		var contribution: float = clamp(exposure * signal_score, -1.0, 1.0)
		rows.append({
			"source_type": "commodity",
			"id": commodity_id,
			"label": str(indicator.get("display_name", commodity_id)),
			"exposure": exposure,
			"signal": signal_score,
			"contribution": contribution,
			"regime": str(indicator.get("regime", "neutral")),
			"direction": str(indicator.get("direction", "flat")),
			"ytd_move": float(indicator.get("ytd_move", 0.0)),
			"driver_score": float(indicator.get("driver_score", 0.0))
		})
	return rows


func _commodity_signal(indicator: Dictionary) -> float:
	var ytd_signal: float = clamp(float(indicator.get("ytd_move", 0.0)) / 20.0, -1.0, 1.0)
	var regime_score: float = _regime_signal(str(indicator.get("regime", "neutral")))
	var direction_score: float = _direction_signal(str(indicator.get("direction", "flat")))
	var driver_score: float = clamp(float(indicator.get("driver_score", 0.0)), -1.0, 1.0)
	return clamp((ytd_signal * 0.48) + (regime_score * 0.24) + (direction_score * 0.16) + (driver_score * 0.12), -1.0, 1.0)


func _macro_rows(company_definition: Dictionary, macro_state: Dictionary) -> Array:
	var exposures_value: Variant = company_definition.get("macro_exposures", {})
	if typeof(exposures_value) != TYPE_DICTIONARY:
		return []
	var exposures: Dictionary = exposures_value
	var rows: Array = []
	for macro_key_value in exposures.keys():
		var macro_id: String = str(macro_key_value)
		var exposure: float = clamp(float(exposures.get(macro_key_value, 0.0)), -1.0, 1.0)
		if is_zero_approx(exposure):
			continue
		var signal_info: Dictionary = _macro_signal_info(macro_id, macro_state)
		if not bool(signal_info.get("known", false)):
			continue
		var macro_signal_score: float = clamp(float(signal_info.get("signal", 0.0)), -1.0, 1.0)
		rows.append({
			"source_type": "macro",
			"id": macro_id,
			"label": str(signal_info.get("label", macro_id)),
			"exposure": exposure,
			"signal": macro_signal_score,
			"contribution": clamp(exposure * macro_signal_score, -1.0, 1.0)
		})
	return rows


func _macro_signal_info(macro_id: String, macro_state: Dictionary) -> Dictionary:
	var gdp_growth: float = float(macro_state.get("gdp_growth", 5.0))
	var inflation_yoy: float = float(macro_state.get("inflation_yoy", 3.2))
	var employment_index: float = float(macro_state.get("employment_index", 0.58))
	var policy_rate: float = float(macro_state.get("policy_rate", BASE_POLICY_RATE))
	var policy_action_bps: float = float(macro_state.get("policy_action_bps", 0.0))
	var risk_appetite: float = float(macro_state.get("risk_appetite", 0.5))
	var market_bias: float = float(macro_state.get("market_bias", 0.0))
	var rate_pressure: float = clamp(((policy_rate - BASE_POLICY_RATE) / 3.0) + (policy_action_bps / 75.0), -1.0, 1.0)
	var lower_rate_tailwind: float = -rate_pressure

	match macro_id:
		"domestic_demand":
			return _known_macro(macro_id, ((gdp_growth - 4.8) / 3.0 * 0.35) + ((employment_index - 0.50) * 2.0 * 0.35) + ((risk_appetite - 0.5) * 2.0 * 0.30))
		"consumer_confidence":
			return _known_macro(macro_id, ((employment_index - 0.50) * 2.0 * 0.40) + ((risk_appetite - 0.5) * 2.0 * 0.42) - (max(inflation_yoy - 4.0, 0.0) * 0.12))
		"interest_rate":
			return _known_macro(macro_id, rate_pressure)
		"inflation":
			return _known_macro(macro_id, (inflation_yoy - 3.2) / 3.2)
		"fx":
			return _known_macro(macro_id, ((inflation_yoy - 3.6) / 3.4) - ((risk_appetite - 0.5) * 0.45))
		"employment":
			return _known_macro(macro_id, (employment_index - 0.50) * 2.0)
		"global_trade":
			return _known_macro(macro_id, ((gdp_growth - 3.6) / 3.4 * 0.75) + ((risk_appetite - 0.5) * 0.50))
		"industrial_activity":
			return _known_macro(macro_id, ((gdp_growth - 4.0) / 3.2 * 0.65) + (_sector_signal(macro_state, "industrial") * 0.35))
		"energy_demand":
			return _known_macro(macro_id, (_sector_signal(macro_state, "energy") * 0.62) + ((gdp_growth - 4.8) * 0.08))
		"energy_policy", "export_policy", "food_security_policy", "carbon_policy", "policy_support", "regulatory_support":
			return _known_macro(macro_id, ((inflation_yoy - 3.4) * 0.16) + ((gdp_growth - 4.8) * 0.08))
		"government_spending":
			return _known_macro(macro_id, (_sector_signal(macro_state, "infra") * 0.55) + ((gdp_growth - 4.8) * 0.10))
		"infrastructure_budget":
			return _known_macro(macro_id, _sector_signal(macro_state, "infra") + ((gdp_growth - 4.8) * 0.10))
		"property_cycle":
			return _known_macro(macro_id, (_sector_signal(macro_state, "property") * 0.72) + (lower_rate_tailwind * 0.28))
		"digital_adoption", "semiconductor_cycle", "ev_demand", "ev_supply_chain", "solar_demand":
			return _known_macro(macro_id, (_sector_signal(macro_state, "tech") * 0.65) + ((risk_appetite - 0.5) * 0.70))
		"healthcare_spending", "health_awareness":
			return _known_macro(macro_id, (_sector_signal(macro_state, "healthcare") * 0.55) + ((employment_index - 0.50) * 0.85) + ((0.55 - risk_appetite) * 0.25))
		"logistics_cost":
			return _known_macro(macro_id, ((inflation_yoy - 3.3) / 3.6) + (max(4.8 - gdp_growth, 0.0) * 0.08))
		"credit_cycle":
			return _known_macro(macro_id, ((gdp_growth - 4.4) / 3.2 * 0.40) + ((employment_index - 0.50) * 0.80 * 0.30) + (lower_rate_tailwind * 0.30))
		"market_liquidity", "retail_participation":
			return _known_macro(macro_id, ((risk_appetite - 0.5) * 1.35) + (market_bias / 0.026 * 0.40))
		"commodity_cycle":
			return _known_macro(macro_id, _commodity_cycle_signal(macro_state))
		"capex_cycle":
			return _known_macro(macro_id, (_sector_signal(macro_state, "industrial") * 0.35) + (_sector_signal(macro_state, "infra") * 0.35) + (lower_rate_tailwind * 0.30))
		"weather":
			return _known_macro(macro_id, max(inflation_yoy - 4.4, 0.0) * 0.24 - max(gdp_growth - 5.4, 0.0) * 0.08)
		"tourism_flow", "urban_mobility":
			return _known_macro(macro_id, ((employment_index - 0.50) * 1.20 * 0.34) + ((risk_appetite - 0.5) * 1.35 * 0.33) + ((gdp_growth - 4.8) / 3.0 * 0.33))
		_:
			return {
				"known": false,
				"signal": 0.0,
				"label": macro_id
			}


func _known_macro(macro_id: String, macro_signal_score: float) -> Dictionary:
	return {
		"known": true,
		"signal": clamp(macro_signal_score, -1.0, 1.0),
		"label": macro_id.replace("_", " ").capitalize()
	}


func _story_rows(story_state: Dictionary) -> Array:
	var rows: Array = []
	var story_signals_value: Variant = story_state.get("story_signals", [])
	if typeof(story_signals_value) == TYPE_ARRAY:
		for story_signal_value in story_signals_value:
			if typeof(story_signal_value) != TYPE_DICTIONARY:
				continue
			var story_signal: Dictionary = story_signal_value
			var story_id: String = str(story_signal.get("id", "")).strip_edges()
			if story_id.is_empty():
				continue
			var story_signal_score: float = clamp(float(story_signal.get("signal", 0.0)), -1.0, 1.0)
			var weight: float = clamp(float(story_signal.get("weight", 1.0)), 0.0, 1.0)
			if is_zero_approx(story_signal_score) or is_zero_approx(weight):
				continue
			rows.append({
				"source_type": "story",
				"id": story_id,
				"label": str(story_signal.get("label", story_id)),
				"exposure": weight,
				"signal": story_signal_score,
				"contribution": clamp(story_signal_score * weight, -1.0, 1.0)
			})

	var exposure_pressure_value: Variant = story_state.get("exposure_pressure", {})
	if typeof(exposure_pressure_value) == TYPE_DICTIONARY:
		var exposure_pressure: Dictionary = exposure_pressure_value
		var pressure_score: float = clamp(float(exposure_pressure.get("drift_score", 0.0)), -1.0, 1.0)
		if not is_zero_approx(pressure_score):
			rows.append({
				"source_type": "story",
				"id": str(exposure_pressure.get("id", "story_pressure")),
				"label": str(exposure_pressure.get("label", "Story pressure")),
				"exposure": clamp(float(exposure_pressure.get("weight", 1.0)), 0.0, 1.0),
				"signal": pressure_score,
				"contribution": clamp(pressure_score * clamp(float(exposure_pressure.get("weight", 1.0)), 0.0, 1.0), -1.0, 1.0)
			})
	return rows


func _weighted_average_score(rows: Array) -> float:
	if rows.is_empty():
		return 0.0
	var weighted_score: float = 0.0
	var total_weight: float = 0.0
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var exposure_weight: float = max(absf(float(row.get("exposure", 0.0))), 0.05)
		weighted_score += float(row.get("contribution", 0.0)) * exposure_weight
		total_weight += exposure_weight
	if total_weight <= 0.0:
		return 0.0
	return clamp(weighted_score / total_weight, -1.0, 1.0)


func _confidence(rows: Array, adjusted_score: float) -> float:
	var contribution_strength: float = 0.0
	var exposure_strength: float = 0.0
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		contribution_strength += absf(float(row.get("contribution", 0.0)))
		exposure_strength += absf(float(row.get("exposure", 0.0)))
	var normalized_contribution: float = clamp(contribution_strength / max(float(rows.size()), 1.0), 0.0, 1.0)
	var normalized_exposure: float = clamp(exposure_strength / max(float(rows.size()), 1.0), 0.0, 1.0)
	var row_coverage: float = clamp(float(rows.size()) / 6.0, 0.0, 1.0)
	return clamp((normalized_contribution * 0.52) + (normalized_exposure * 0.22) + (row_coverage * 0.14) + (absf(adjusted_score) * 0.12), 0.0, 1.0)


func _moat_modifier(score: float, moat_tags_value: Variant) -> float:
	if typeof(moat_tags_value) != TYPE_ARRAY:
		return 1.0
	var moat_count: int = min((moat_tags_value as Array).size(), 4)
	if moat_count <= 0 or is_zero_approx(score):
		return 1.0
	if score > 0.0:
		return 1.0 + min(float(moat_count) * 0.025, 0.08)
	return 1.0 - min(float(moat_count) * 0.018, 0.06)


func _risk_modifier(score: float, price_traits_value: Variant) -> float:
	if typeof(price_traits_value) != TYPE_DICTIONARY or is_zero_approx(score):
		return 1.0
	var price_traits: Dictionary = price_traits_value
	var risk_bias: float = clamp(float(price_traits.get("risk_bias", 0.0)), -1.0, 1.0)
	if score < 0.0:
		return clamp(1.0 + (risk_bias * 0.10), 0.92, 1.12)
	return clamp(1.0 + (max(-risk_bias, 0.0) * 0.04), 0.96, 1.08)


func _volatility_multiplier(activity_score: float, price_traits_value: Variant) -> float:
	var profile_adjustment: float = 0.0
	if typeof(price_traits_value) == TYPE_DICTIONARY:
		var price_traits: Dictionary = price_traits_value
		match str(price_traits.get("volatility_profile", "moderate")):
			"low":
				profile_adjustment = -0.020
			"high":
				profile_adjustment = 0.025
			_:
				profile_adjustment = 0.0
	var multiplier: float = 1.0 + (activity_score * 0.12) + (profile_adjustment * clamp(activity_score + 0.25, 0.0, 1.0))
	return clamp(multiplier, VOLATILITY_MIN, VOLATILITY_MAX)


func _volume_multiplier(activity_score: float, price_traits_value: Variant) -> float:
	var event_sensitivity: float = 0.0
	if typeof(price_traits_value) == TYPE_DICTIONARY:
		var price_traits: Dictionary = price_traits_value
		event_sensitivity = absf(clamp(float(price_traits.get("event_sensitivity", 0.0)), -1.0, 1.0))
	var multiplier: float = 1.0 + (activity_score * 0.16) + (event_sensitivity * 0.04)
	return clamp(multiplier, VOLUME_MIN, VOLUME_MAX)


func _sector_signal(macro_state: Dictionary, sector_id: String) -> float:
	var sector_biases_value: Variant = macro_state.get("sector_biases", {})
	if typeof(sector_biases_value) != TYPE_DICTIONARY:
		return 0.0
	var sector_biases: Dictionary = sector_biases_value
	return clamp(float(sector_biases.get(sector_id, 0.0)) / 0.018, -1.0, 1.0)


func _commodity_cycle_signal(macro_state: Dictionary) -> float:
	var indicators_value: Variant = macro_state.get("commodity_indicators", {})
	if typeof(indicators_value) != TYPE_DICTIONARY:
		return 0.0
	var indicators: Dictionary = indicators_value
	if indicators.is_empty():
		return 0.0
	var score: float = 0.0
	var count: int = 0
	for indicator_id_value in indicators.keys():
		var indicator: Dictionary = indicators.get(indicator_id_value, {})
		score += _commodity_signal(indicator)
		count += 1
	if count <= 0:
		return 0.0
	return clamp(score / float(count), -1.0, 1.0)


func _regime_signal(regime: String) -> float:
	match regime:
		"bull":
			return 1.0
		"firm":
			return 0.5
		"soft":
			return -0.5
		"bear":
			return -1.0
		_:
			return 0.0


func _direction_signal(direction: String) -> float:
	match direction:
		"rising":
			return 0.75
		"firming":
			return 0.35
		"softening":
			return -0.35
		"falling":
			return -0.75
		_:
			return 0.0


func _summary(rows: Array, adjusted_score: float) -> String:
	if rows.is_empty() or is_zero_approx(adjusted_score):
		return "Neutral exposure"
	var top_labels: Array[String] = []
	for row_value in rows:
		if top_labels.size() >= 3:
			break
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		top_labels.append(str(row.get("label", row.get("id", ""))))
	var direction: String = "tailwind" if adjusted_score > 0.0 else "headwind"
	return "Exposure %s %s from %s" % [
		direction,
		_signed_float(adjusted_score),
		", ".join(top_labels)
	]


func _signed_float(value: float) -> String:
	var prefix: String = "+" if value > 0.0 else ""
	return "%s%s" % [prefix, String.num(value, 3)]
