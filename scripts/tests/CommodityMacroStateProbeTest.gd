extends Node

const MACRO_STATE_SYSTEM = preload("res://systems/MacroStateSystem.gd")
const RUN_SEED := 20260614
const START_YEAR := 2020
const YEARS_TO_PROBE := 3
const EXPECTED_COMMODITY_COUNT := 25


func _ready() -> void:
	DataRepository.reload_all()
	var first_history: Array = _build_history()
	var second_history: Array = _build_history()
	if JSON.stringify(first_history) != JSON.stringify(second_history):
		_fail("Commodity macro state was not deterministic across repeated fixed-seed builds.")
		return
	if first_history.size() != YEARS_TO_PROBE:
		_fail("Expected %d macro states, got %d." % [YEARS_TO_PROBE, first_history.size()])
		return

	for state_value in first_history:
		if typeof(state_value) != TYPE_DICTIONARY:
			_fail("Commodity macro state history contained a non-dictionary entry.")
			return
		var state: Dictionary = state_value
		var indicators: Dictionary = state.get("commodity_indicators", {})
		if indicators.size() != EXPECTED_COMMODITY_COUNT:
			_fail("Expected %d commodity indicators, got %d." % [EXPECTED_COMMODITY_COUNT, indicators.size()])
			return
		for required_id in ["coal", "crude_oil", "cpo", "nickel", "gold", "copper", "natural_gas", "rare_earth", "silica"]:
			if not indicators.has(required_id):
				_fail("Missing required commodity indicator '%s'." % required_id)
				return
		for commodity_id_value in indicators.keys():
			var commodity_id: String = str(commodity_id_value)
			var indicator: Dictionary = indicators.get(commodity_id, {})
			if not _is_valid_indicator(indicator):
				_fail("Invalid commodity indicator for '%s': %s" % [commodity_id, JSON.stringify(indicator)])
				return

	var sample: Dictionary = first_history[0]
	print("COMMODITY_MACRO_STATE_PROBE_OK %s" % JSON.stringify({
		"seed": RUN_SEED,
		"years": YEARS_TO_PROBE,
		"first_year": sample.get("year", START_YEAR),
		"commodity_count": sample.get("commodity_indicators", {}).size(),
		"regime_counts": sample.get("commodity_regime_counts", {}),
		"leaders": sample.get("commodity_leaders", []),
		"laggards": sample.get("commodity_laggards", []),
		"sample_coal": sample.get("commodity_indicators", {}).get("coal", {}),
		"sample_rare_earth": sample.get("commodity_indicators", {}).get("rare_earth", {}),
		"sample_silica": sample.get("commodity_indicators", {}).get("silica", {})
	}))
	get_tree().quit(0)


func _build_history() -> Array:
	var system = MACRO_STATE_SYSTEM.new()
	var history: Array = []
	var previous_state: Dictionary = {}
	for offset in range(YEARS_TO_PROBE):
		var year: int = START_YEAR + offset
		var state: Dictionary = system.build_year_state(
			RUN_SEED,
			year,
			DataRepository.get_sector_definitions(),
			previous_state,
			DataRepository.get_commodity_indicator_catalog()
		)
		history.append(state)
		previous_state = state.duplicate(true)
	return history


func _is_valid_indicator(indicator: Dictionary) -> bool:
	if str(indicator.get("id", "")).strip_edges().is_empty():
		return false
	if str(indicator.get("display_name", "")).strip_edges().is_empty():
		return false
	if str(indicator.get("category", "")).strip_edges().is_empty():
		return false
	var level: float = float(indicator.get("level", 0.0))
	if level < 40.0 or level > 200.0:
		return false
	var ytd_move: float = float(indicator.get("ytd_move", 0.0))
	if ytd_move < -75.0 or ytd_move > 75.0:
		return false
	var volatility: float = float(indicator.get("volatility", 0.0))
	if volatility < 0.0 or volatility > 0.85:
		return false
	if not str(indicator.get("direction", "")) in ["falling", "softening", "flat", "firming", "rising"]:
		return false
	if not str(indicator.get("regime", "")) in ["bear", "soft", "neutral", "firm", "bull"]:
		return false
	if typeof(indicator.get("related_sectors", [])) != TYPE_ARRAY:
		return false
	if typeof(indicator.get("story_tags", [])) != TYPE_ARRAY:
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	print("COMMODITY_MACRO_STATE_PROBE_FAIL: %s" % message)
	get_tree().quit(1)
