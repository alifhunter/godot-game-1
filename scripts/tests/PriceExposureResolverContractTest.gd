extends Node

const MACRO_STATE_SYSTEM = preload("res://systems/MacroStateSystem.gd")
const PRICE_EXPOSURE_RESOLVER = preload("res://systems/PriceExposureResolver.gd")
const RUN_SEED := 20260614
const START_YEAR := 2020


func _ready() -> void:
	DataRepository.reload_all()

	var macro_system = MACRO_STATE_SYSTEM.new()
	var macro_state: Dictionary = macro_system.build_year_state(
		RUN_SEED,
		START_YEAR,
		DataRepository.get_sector_definitions(),
		{},
		DataRepository.get_commodity_indicator_catalog()
	)
	var resolver = PRICE_EXPOSURE_RESOLVER.new()
	var leader_id: String = _first_commodity_with_direction(macro_state, true)
	var laggard_id: String = _first_commodity_with_direction(macro_state, false)
	if leader_id.is_empty() or laggard_id.is_empty():
		_fail("Expected fixed-seed macro state to contain positive and negative commodity signals.")
		return

	var leader_company: Dictionary = {
		"id": "positive_exposure_company",
		"name": "Positive Exposure Company",
		"commodity_exposures": {leader_id: 0.92},
		"macro_exposures": {"global_trade": 0.32, "energy_demand": 0.24},
		"price_traits": {"volatility_profile": "high", "event_sensitivity": 0.42, "risk_bias": 0.18},
		"moat_tags": ["reserve_life", "logistics_access", "customer_contracts"]
	}
	var inverse_company: Dictionary = {
		"id": "inverse_exposure_company",
		"name": "Inverse Exposure Company",
		"commodity_exposures": {leader_id: -0.72},
		"macro_exposures": {"domestic_demand": 0.26, "interest_rate": -0.22},
		"price_traits": {"volatility_profile": "moderate", "event_sensitivity": 0.24, "risk_bias": 0.04},
		"moat_tags": ["distribution_depth"]
	}
	var laggard_company: Dictionary = {
		"id": "laggard_exposure_company",
		"name": "Laggard Exposure Company",
		"commodity_exposures": {laggard_id: 0.86},
		"macro_exposures": {"commodity_cycle": 0.36, "global_trade": 0.20},
		"price_traits": {"volatility_profile": "high", "event_sensitivity": 0.34, "risk_bias": 0.12},
		"moat_tags": ["asset_quality"]
	}
	var neutral_company: Dictionary = {
		"id": "neutral_company",
		"name": "Neutral Company"
	}

	var leader_result: Dictionary = resolver.resolve(leader_company, macro_state)
	var leader_repeat_result: Dictionary = resolver.resolve(leader_company, macro_state)
	if JSON.stringify(leader_result) != JSON.stringify(leader_repeat_result):
		_fail("Expected resolver output to be deterministic for repeated fixed inputs.")
		return
	if not _assert_bounds("leader", leader_result):
		return
	if float(leader_result.get("exposure_drift_adjustment", 0.0)) <= 0.0:
		_fail("Expected positive exposure to positive commodity leader '%s' to create positive drift: %s" % [
			leader_id,
			JSON.stringify(leader_result)
		])
		return
	if not _has_row(leader_result, "commodity", leader_id):
		_fail("Expected leader result to include commodity explainability row for '%s'." % leader_id)
		return
	if not _has_source_type(leader_result, "macro"):
		_fail("Expected leader result to include macro explainability rows.")
		return

	var inverse_result: Dictionary = resolver.resolve(inverse_company, macro_state)
	if not _assert_bounds("inverse", inverse_result):
		return
	if float(inverse_result.get("exposure_drift_adjustment", 0.0)) >= 0.0:
		_fail("Expected inverse exposure to positive commodity leader '%s' to create negative drift: %s" % [
			leader_id,
			JSON.stringify(inverse_result)
		])
		return

	var laggard_result: Dictionary = resolver.resolve(laggard_company, macro_state)
	if not _assert_bounds("laggard", laggard_result):
		return
	if float(laggard_result.get("exposure_drift_adjustment", 0.0)) >= 0.0:
		_fail("Expected positive exposure to commodity laggard '%s' to create negative drift: %s" % [
			laggard_id,
			JSON.stringify(laggard_result)
		])
		return

	var neutral_result: Dictionary = resolver.resolve(neutral_company, macro_state)
	if not _assert_neutral(neutral_result):
		return

	var story_result: Dictionary = resolver.resolve(neutral_company, macro_state, {
		"story_signals": [
			{"id": "turnaround_confirmed", "label": "Turnaround confirmed", "signal": 0.80, "weight": 0.75}
		]
	})
	if not _assert_bounds("story", story_result):
		return
	if float(story_result.get("exposure_drift_adjustment", 0.0)) <= 0.0:
		_fail("Expected positive story signal to create positive bounded drift: %s" % JSON.stringify(story_result))
		return
	if not _has_source_type(story_result, "story"):
		_fail("Expected story result to include story explainability row.")
		return

	print("PRICE_EXPOSURE_RESOLVER_CONTRACT_OK %s" % JSON.stringify({
		"leader_id": leader_id,
		"laggard_id": laggard_id,
		"leader_drift": float(leader_result.get("exposure_drift_adjustment", 0.0)),
		"inverse_drift": float(inverse_result.get("exposure_drift_adjustment", 0.0)),
		"laggard_drift": float(laggard_result.get("exposure_drift_adjustment", 0.0)),
		"story_drift": float(story_result.get("exposure_drift_adjustment", 0.0)),
		"leader_confidence": float(leader_result.get("exposure_confidence", 0.0)),
		"leader_rows": leader_result.get("exposure_rows", []).size()
	}))
	get_tree().quit(0)


func _first_commodity_with_direction(macro_state: Dictionary, positive: bool) -> String:
	var indicators: Dictionary = macro_state.get("commodity_indicators", {})
	var candidates: Array = macro_state.get("commodity_leaders", []) if positive else macro_state.get("commodity_laggards", [])
	for candidate_value in candidates:
		var candidate_id: String = str(candidate_value)
		if not indicators.has(candidate_id):
			continue
		var indicator: Dictionary = indicators.get(candidate_id, {})
		var direction_score: float = _commodity_direction_score(indicator)
		if positive and direction_score > 0.05:
			return candidate_id
		if not positive and direction_score < -0.05:
			return candidate_id
	return ""


func _commodity_direction_score(indicator: Dictionary) -> float:
	var ytd_score: float = clamp(float(indicator.get("ytd_move", 0.0)) / 20.0, -1.0, 1.0)
	var regime_score: float = 0.0
	match str(indicator.get("regime", "neutral")):
		"bull":
			regime_score = 1.0
		"firm":
			regime_score = 0.5
		"soft":
			regime_score = -0.5
		"bear":
			regime_score = -1.0
	var trend_score: float = 0.0
	match str(indicator.get("direction", "flat")):
		"rising":
			trend_score = 0.75
		"firming":
			trend_score = 0.35
		"softening":
			trend_score = -0.35
		"falling":
			trend_score = -0.75
	return clamp((ytd_score * 0.48) + (regime_score * 0.24) + (trend_score * 0.16) + (float(indicator.get("driver_score", 0.0)) * 0.12), -1.0, 1.0)


func _assert_bounds(label: String, result: Dictionary) -> bool:
	var drift: float = float(result.get("exposure_drift_adjustment", 0.0))
	var volatility: float = float(result.get("exposure_volatility_multiplier", 1.0))
	var volume: float = float(result.get("exposure_volume_multiplier", 1.0))
	var confidence: float = float(result.get("exposure_confidence", 0.0))
	if drift < -0.004 or drift > 0.004:
		_fail("%s drift out of bounds: %s" % [label, JSON.stringify(result)])
		return false
	if volatility < 0.90 or volatility > 1.16:
		_fail("%s volatility multiplier out of bounds: %s" % [label, JSON.stringify(result)])
		return false
	if volume < 0.92 or volume > 1.22:
		_fail("%s volume multiplier out of bounds: %s" % [label, JSON.stringify(result)])
		return false
	if confidence < 0.0 or confidence > 1.0:
		_fail("%s confidence out of bounds: %s" % [label, JSON.stringify(result)])
		return false
	if typeof(result.get("exposure_rows", [])) != TYPE_ARRAY:
		_fail("%s exposure rows should be an array: %s" % [label, JSON.stringify(result)])
		return false
	return true


func _assert_neutral(result: Dictionary) -> bool:
	if not is_zero_approx(float(result.get("exposure_drift_adjustment", 1.0))):
		_fail("Expected neutral drift, got %s." % JSON.stringify(result))
		return false
	if not is_equal_approx(float(result.get("exposure_volatility_multiplier", 0.0)), 1.0):
		_fail("Expected neutral volatility multiplier, got %s." % JSON.stringify(result))
		return false
	if not is_equal_approx(float(result.get("exposure_volume_multiplier", 0.0)), 1.0):
		_fail("Expected neutral volume multiplier, got %s." % JSON.stringify(result))
		return false
	if not is_zero_approx(float(result.get("exposure_confidence", 1.0))):
		_fail("Expected neutral confidence, got %s." % JSON.stringify(result))
		return false
	if not result.get("exposure_rows", []).is_empty():
		_fail("Expected neutral result to have no rows, got %s." % JSON.stringify(result))
		return false
	if str(result.get("exposure_summary", "")) != "":
		_fail("Expected neutral result to keep empty summary, got %s." % JSON.stringify(result))
		return false
	return true


func _has_row(result: Dictionary, source_type: String, row_id: String) -> bool:
	for row_value in result.get("exposure_rows", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("source_type", "")) == source_type and str(row.get("id", "")) == row_id:
			return true
	return false


func _has_source_type(result: Dictionary, source_type: String) -> bool:
	for row_value in result.get("exposure_rows", []):
		if typeof(row_value) == TYPE_DICTIONARY and str(row_value.get("source_type", "")) == source_type:
			return true
	return false


func _fail(message: String) -> void:
	push_error(message)
	print("PRICE_EXPOSURE_RESOLVER_CONTRACT_FAIL: %s" % message)
	get_tree().quit(1)
