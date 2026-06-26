extends Node

const MARKET_SIMULATOR = preload("res://systems/MarketSimulator.gd")
const RUN_SEED := 20260614


func _ready() -> void:
	var simulator = MARKET_SIMULATOR.new()
	var scenario_reports: Array = []
	scenario_reports.append(_run_coal_rally_probe(simulator))
	scenario_reports.append(_run_cpo_rally_probe(simulator))
	scenario_reports.append(_run_rate_hike_probe(simulator))
	scenario_reports.append(_run_oil_spike_probe(simulator))

	for report_value in scenario_reports:
		if typeof(report_value) != TYPE_DICTIONARY:
			_fail("Probe returned invalid scenario report.")
			return
		var report: Dictionary = report_value
		if not bool(report.get("success", false)):
			_fail("Scenario '%s' failed: %s" % [str(report.get("id", "")), str(report.get("message", ""))])
			return

	var compact_reports: Array = []
	for report_value in scenario_reports:
		var report: Dictionary = report_value
		compact_reports.append({
			"id": str(report.get("id", "")),
			"expected_leader": str(report.get("expected_leader", "")),
			"expected_laggard": str(report.get("expected_laggard", "")),
			"leader_change": float(report.get("leader_change", 0.0)),
			"neutral_change": float(report.get("neutral_change", 0.0)),
			"laggard_change": float(report.get("laggard_change", 0.0)),
			"spread": float(report.get("spread", 0.0)),
			"leader_summary": str(report.get("leader_summary", "")),
			"laggard_summary": str(report.get("laggard_summary", ""))
		})
	print("PRICE_EXPOSURE_IMPACT_PROBE_OK %s" % JSON.stringify({
		"scenario_count": compact_reports.size(),
		"scenarios": compact_reports
	}))
	get_tree().quit(0)


func _run_coal_rally_probe(simulator) -> Dictionary:
	var macro_state: Dictionary = _base_macro_state()
	macro_state["sector_biases"]["energy"] = 0.012
	macro_state["commodity_indicators"] = {
		"coal": _commodity_indicator("coal", "Coal", "bull", "rising", 18.0, 0.85)
	}
	var leader: Dictionary = _probe_company(simulator, "coal_producer", _company({
		"commodity_exposures": {"coal": 0.92},
		"macro_exposures": {"global_trade": 0.30, "energy_demand": 0.42},
		"price_traits": {"volatility_profile": "high", "event_sensitivity": 0.42, "risk_bias": 0.18},
		"moat_tags": ["reserve_life", "barge_access", "low_strip_ratio"]
	}), macro_state, 11)
	var neutral: Dictionary = _probe_company(simulator, "neutral_industrial", _company({}), macro_state, 11)
	var laggard: Dictionary = _probe_company(simulator, "coal_input_consumer", _company({
		"commodity_exposures": {"coal": -0.34},
		"macro_exposures": {"industrial_activity": 0.18},
		"price_traits": {"volatility_profile": "moderate", "event_sensitivity": 0.18, "risk_bias": 0.06},
		"moat_tags": ["regional_distribution"]
	}), macro_state, 11)
	return _rank_report("coal_rally", leader, neutral, laggard, "coal_producer", "coal_input_consumer")


func _run_cpo_rally_probe(simulator) -> Dictionary:
	var macro_state: Dictionary = _base_macro_state()
	macro_state["commodity_indicators"] = {
		"cpo": _commodity_indicator("cpo", "CPO", "bull", "rising", 16.0, 0.72),
		"fuel": _commodity_indicator("fuel", "Fuel", "neutral", "flat", 0.0, 0.0),
		"fertilizer": _commodity_indicator("fertilizer", "Fertilizer", "neutral", "flat", 0.0, 0.0)
	}
	var leader: Dictionary = _probe_company(simulator, "plantation", _company({
		"commodity_exposures": {"cpo": 0.86, "fuel": -0.08, "fertilizer": -0.16},
		"macro_exposures": {"export_policy": 0.36, "domestic_demand": 0.16},
		"price_traits": {"volatility_profile": "high", "event_sensitivity": 0.34, "risk_bias": 0.18},
		"moat_tags": ["landbank", "mill_access", "estate_age_profile"]
	}), macro_state, 12)
	var neutral: Dictionary = _probe_company(simulator, "neutral_consumer", _company({}), macro_state, 12)
	var laggard: Dictionary = _probe_company(simulator, "cpo_input_consumer", _company({
		"commodity_exposures": {"cpo": -0.26, "sugar": -0.10},
		"macro_exposures": {"consumer_confidence": 0.28, "domestic_demand": 0.22},
		"price_traits": {"volatility_profile": "low", "event_sensitivity": 0.14, "risk_bias": -0.12},
		"moat_tags": ["brand_portfolio", "pricing_power"]
	}), macro_state, 12)
	return _rank_report("cpo_rally", leader, neutral, laggard, "plantation", "cpo_input_consumer")


func _run_rate_hike_probe(simulator) -> Dictionary:
	var macro_state: Dictionary = _base_macro_state()
	macro_state["policy_rate"] = 6.75
	macro_state["policy_action_bps"] = 50
	macro_state["risk_appetite"] = 0.38
	macro_state["market_bias"] = -0.010
	macro_state["sector_biases"]["property"] = -0.016
	macro_state["sector_biases"]["finance"] = 0.006
	var leader: Dictionary = _probe_company(simulator, "rate_beneficiary", _company({
		"macro_exposures": {"interest_rate": 0.62, "market_liquidity": 0.12},
		"price_traits": {"volatility_profile": "moderate", "event_sensitivity": 0.12, "risk_bias": -0.08},
		"moat_tags": ["deposit_franchise", "capital_buffer"]
	}), macro_state, 13)
	var neutral: Dictionary = _probe_company(simulator, "neutral_rate_name", _company({}), macro_state, 13)
	var laggard: Dictionary = _probe_company(simulator, "leveraged_property", _company({
		"macro_exposures": {"interest_rate": -0.58, "property_cycle": 0.70, "consumer_confidence": 0.24},
		"price_traits": {"volatility_profile": "high", "event_sensitivity": 0.36, "risk_bias": 0.24},
		"moat_tags": ["landbank"]
	}), macro_state, 13)
	return _rank_report("rate_hike", leader, neutral, laggard, "rate_beneficiary", "leveraged_property")


func _run_oil_spike_probe(simulator) -> Dictionary:
	var macro_state: Dictionary = _base_macro_state()
	macro_state["inflation_yoy"] = 5.6
	macro_state["sector_biases"]["energy"] = 0.014
	macro_state["sector_biases"]["transport"] = -0.010
	macro_state["commodity_indicators"] = {
		"crude_oil": _commodity_indicator("crude_oil", "Crude Oil", "bull", "rising", 20.0, 0.88),
		"fuel": _commodity_indicator("fuel", "Fuel", "firm", "rising", 14.0, 0.70),
		"natural_gas": _commodity_indicator("natural_gas", "Natural Gas", "firm", "firming", 9.0, 0.42)
	}
	var leader: Dictionary = _probe_company(simulator, "oil_producer", _company({
		"commodity_exposures": {"crude_oil": 0.78, "natural_gas": 0.42},
		"macro_exposures": {"energy_demand": 0.42, "global_trade": 0.20},
		"price_traits": {"volatility_profile": "high", "event_sensitivity": 0.44, "risk_bias": 0.22},
		"moat_tags": ["field_operatorship", "technical_recovery"]
	}), macro_state, 14)
	var neutral: Dictionary = _probe_company(simulator, "neutral_transport", _company({}), macro_state, 14)
	var laggard: Dictionary = _probe_company(simulator, "fuel_cost_carrier", _company({
		"commodity_exposures": {"crude_oil": -0.10, "fuel": -0.42},
		"macro_exposures": {"logistics_cost": -0.34, "global_trade": 0.12},
		"price_traits": {"volatility_profile": "high", "event_sensitivity": 0.30, "risk_bias": 0.18},
		"moat_tags": ["route_density"]
	}), macro_state, 14)
	return _rank_report("oil_spike", leader, neutral, laggard, "oil_producer", "fuel_cost_carrier")


func _probe_company(simulator, company_id: String, definition: Dictionary, macro_state: Dictionary, day_number: int) -> Dictionary:
	definition["id"] = company_id
	var exposure_context: Dictionary = simulator.call("_resolve_price_exposure_context", definition, macro_state)
	var volume_context: Dictionary = simulator.call("_apply_price_exposure_context", {
		"volume_multiplier": 1.0,
		"expected_activity_ratio": 1.0
	}, exposure_context)
	var change: float = float(simulator.call(
		"_calculate_daily_change",
		definition,
		{"id": str(definition.get("sector_id", "probe_sector")), "volatility_bias": 0.0},
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		volume_context,
		RUN_SEED,
		day_number,
		company_id,
		{
			"volatility_multiplier": 1.0,
			"broker_impact_multiplier": 1.0,
			"daily_move_cap": 0.12
		},
		1.0
	))
	return {
		"company_id": company_id,
		"change": change,
		"drift": float(exposure_context.get("exposure_drift_adjustment", 0.0)),
		"volatility_multiplier": float(exposure_context.get("exposure_volatility_multiplier", 1.0)),
		"volume_multiplier": float(exposure_context.get("exposure_volume_multiplier", 1.0)),
		"confidence": float(exposure_context.get("exposure_confidence", 0.0)),
		"summary": str(exposure_context.get("exposure_summary", "")),
		"top_rows": _top_exposure_rows(exposure_context.get("exposure_rows", []), 3)
	}


func _rank_report(
	scenario_id: String,
	leader: Dictionary,
	neutral: Dictionary,
	laggard: Dictionary,
	expected_leader: String,
	expected_laggard: String
) -> Dictionary:
	var leader_change: float = float(leader.get("change", 0.0))
	var neutral_change: float = float(neutral.get("change", 0.0))
	var laggard_change: float = float(laggard.get("change", 0.0))
	if leader_change <= neutral_change:
		return _failed_report(scenario_id, "%s did not outperform neutral. leader=%s neutral=%s" % [
			expected_leader,
			String.num(leader_change, 6),
			String.num(neutral_change, 6)
		])
	if neutral_change <= laggard_change:
		return _failed_report(scenario_id, "Neutral did not outperform %s. neutral=%s laggard=%s" % [
			expected_laggard,
			String.num(neutral_change, 6),
			String.num(laggard_change, 6)
		])
	var spread: float = leader_change - laggard_change
	if spread < 0.001:
		return _failed_report(scenario_id, "Expected at least 10 bps leader-laggard spread, got %s." % String.num(spread, 6))
	return {
		"success": true,
		"id": scenario_id,
		"expected_leader": expected_leader,
		"expected_laggard": expected_laggard,
		"leader_change": leader_change,
		"neutral_change": neutral_change,
		"laggard_change": laggard_change,
		"spread": spread,
		"leader_volatility_multiplier": float(leader.get("volatility_multiplier", 1.0)),
		"laggard_volatility_multiplier": float(laggard.get("volatility_multiplier", 1.0)),
		"leader_volume_multiplier": float(leader.get("volume_multiplier", 1.0)),
		"laggard_volume_multiplier": float(laggard.get("volume_multiplier", 1.0)),
		"leader_summary": str(leader.get("summary", "")),
		"laggard_summary": str(laggard.get("summary", "")),
		"leader_rows": leader.get("top_rows", []).duplicate(true),
		"laggard_rows": laggard.get("top_rows", []).duplicate(true)
	}


func _failed_report(scenario_id: String, message: String) -> Dictionary:
	return {
		"success": false,
		"id": scenario_id,
		"message": message
	}


func _company(overrides: Dictionary) -> Dictionary:
	var definition: Dictionary = {
		"name": "Probe Company",
		"sector_id": "probe_sector",
		"quality_score": 50.0,
		"growth_score": 50.0,
		"risk_score": 50.0,
		"base_volatility": 0.0,
		"commodity_exposures": {},
		"macro_exposures": {},
		"price_traits": {},
		"moat_tags": []
	}
	for override_key in overrides.keys():
		definition[override_key] = overrides.get(override_key)
	return definition


func _base_macro_state() -> Dictionary:
	return {
		"year": 2020,
		"inflation_yoy": 3.2,
		"gdp_growth": 5.0,
		"employment_index": 0.58,
		"policy_rate": 5.0,
		"policy_action_bps": 0,
		"risk_appetite": 0.50,
		"market_bias": 0.0,
		"sector_biases": {
			"consumer": 0.0,
			"noncyclical": 0.0,
			"energy": 0.0,
			"basicindustry": 0.0,
			"industrial": 0.0,
			"tech": 0.0,
			"infra": 0.0,
			"transport": 0.0,
			"health": 0.0,
			"finance": 0.0,
			"property": 0.0
		},
		"commodity_indicators": {}
	}


func _commodity_indicator(
	commodity_id: String,
	display_name: String,
	regime: String,
	direction: String,
	ytd_move: float,
	driver_score: float
) -> Dictionary:
	return {
		"id": commodity_id,
		"display_name": display_name,
		"category": "probe",
		"level": 100.0 + ytd_move,
		"direction": direction,
		"regime": regime,
		"ytd_move": ytd_move,
		"driver_score": driver_score,
		"volatility": 0.30,
		"related_sectors": [],
		"story_tags": []
	}


func _top_exposure_rows(rows: Array, limit: int) -> Array:
	var output: Array = []
	for row_value in rows:
		if output.size() >= limit:
			break
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		output.append({
			"source_type": str(row.get("source_type", "")),
			"id": str(row.get("id", "")),
			"label": str(row.get("label", "")),
			"exposure": float(row.get("exposure", 0.0)),
			"signal": float(row.get("signal", 0.0)),
			"contribution": float(row.get("contribution", 0.0))
		})
	return output


func _fail(message: String) -> void:
	push_error(message)
	print("PRICE_EXPOSURE_IMPACT_PROBE_FAIL: %s" % message)
	get_tree().quit(1)
