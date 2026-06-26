extends Node

const RUN_SEED := 20260614
const EXPECTED_COMMODITY_COUNT := 25


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)

	var baseline_save: Dictionary = RunState.to_save_dict()
	var baseline_state: Dictionary = RunState.get_macro_state_for_year(2020)
	if baseline_state.get("commodity_indicators", {}).size() != EXPECTED_COMMODITY_COUNT:
		_fail("Expected baseline macro state to contain %d commodity indicators." % EXPECTED_COMMODITY_COUNT)
		return

	var legacy_save: Dictionary = _save_without_commodity_state(baseline_save)
	RunState.load_from_dict(legacy_save)
	var normalized_legacy_state: Dictionary = RunState.get_macro_state_for_year(2020)
	if not _assert_neutral_commodity_defaults(normalized_legacy_state):
		return
	var normalized_save: Dictionary = RunState.to_save_dict()
	var normalized_save_state: Dictionary = normalized_save.get("yearly_macro_states", {}).get("2020", {})
	if not _assert_neutral_commodity_defaults(normalized_save_state):
		return

	var partial_save: Dictionary = _save_with_partial_commodity_state(baseline_save)
	RunState.load_from_dict(partial_save)
	var normalized_partial_state: Dictionary = RunState.get_macro_state_for_year(2020)
	if not _assert_partial_commodity_defaults(normalized_partial_state):
		return

	print("COMMODITY_MACRO_SAVE_DEFAULTS_OK %s" % JSON.stringify({
		"commodity_count": normalized_legacy_state.get("commodity_indicators", {}).size(),
		"legacy_regime_counts": normalized_legacy_state.get("commodity_regime_counts", {}),
		"partial_regime_counts": normalized_partial_state.get("commodity_regime_counts", {}),
		"partial_leaders": normalized_partial_state.get("commodity_leaders", [])
	}))
	get_tree().quit(0)


func _save_without_commodity_state(source_save: Dictionary) -> Dictionary:
	var save: Dictionary = source_save.duplicate(true)
	var macro_states: Dictionary = save.get("yearly_macro_states", {}).duplicate(true)
	var year_state: Dictionary = macro_states.get("2020", {}).duplicate(true)
	for key in ["commodity_indicators", "commodity_regime_counts", "commodity_leaders", "commodity_laggards"]:
		year_state.erase(key)
	macro_states["2020"] = year_state
	save["yearly_macro_states"] = macro_states
	return save


func _save_with_partial_commodity_state(source_save: Dictionary) -> Dictionary:
	var save: Dictionary = source_save.duplicate(true)
	var macro_states: Dictionary = save.get("yearly_macro_states", {}).duplicate(true)
	var year_state: Dictionary = macro_states.get("2020", {}).duplicate(true)
	year_state["commodity_indicators"] = {
		"coal": {
			"id": "coal",
			"display_name": "Thermal Coal",
			"category": "energy",
			"level": 112.0,
			"direction": "firming",
			"volatility": 0.31,
			"regime": "firm",
			"ytd_move": 8.5,
			"driver_score": 0.4
		}
	}
	year_state.erase("commodity_regime_counts")
	year_state.erase("commodity_leaders")
	year_state.erase("commodity_laggards")
	macro_states["2020"] = year_state
	save["yearly_macro_states"] = macro_states
	return save


func _assert_neutral_commodity_defaults(state: Dictionary) -> bool:
	var indicators: Dictionary = state.get("commodity_indicators", {})
	if indicators.size() != EXPECTED_COMMODITY_COUNT:
		_fail("Expected %d neutral commodity defaults, got %d." % [EXPECTED_COMMODITY_COUNT, indicators.size()])
		return false
	var neutral_levels: Dictionary = _neutral_level_by_id()
	for commodity_id_value in indicators.keys():
		var commodity_id: String = str(commodity_id_value)
		var indicator: Dictionary = indicators.get(commodity_id, {})
		if str(indicator.get("direction", "")) != "flat":
			_fail("Expected neutral direction flat for '%s', got '%s'." % [commodity_id, str(indicator.get("direction", ""))])
			return false
		if str(indicator.get("regime", "")) != "neutral":
			_fail("Expected neutral regime for '%s', got '%s'." % [commodity_id, str(indicator.get("regime", ""))])
			return false
		if not is_equal_approx(float(indicator.get("ytd_move", -999.0)), 0.0):
			_fail("Expected neutral ytd_move=0.0 for '%s', got %.2f." % [commodity_id, float(indicator.get("ytd_move", 0.0))])
			return false
		if not is_equal_approx(float(indicator.get("driver_score", -999.0)), 0.0):
			_fail("Expected neutral driver_score=0.0 for '%s', got %.2f." % [commodity_id, float(indicator.get("driver_score", 0.0))])
			return false
		if not is_equal_approx(float(indicator.get("level", 0.0)), float(neutral_levels.get(commodity_id, 100.0))):
			_fail("Expected neutral level for '%s', got %.2f." % [commodity_id, float(indicator.get("level", 0.0))])
			return false
	var regime_counts: Dictionary = state.get("commodity_regime_counts", {})
	if int(regime_counts.get("neutral", 0)) != EXPECTED_COMMODITY_COUNT:
		_fail("Expected all neutral regime counts, got %s." % JSON.stringify(regime_counts))
		return false
	if not state.get("commodity_leaders", []).is_empty() or not state.get("commodity_laggards", []).is_empty():
		_fail("Expected neutral commodity defaults to have no leaders or laggards.")
		return false
	return true


func _assert_partial_commodity_defaults(state: Dictionary) -> bool:
	var indicators: Dictionary = state.get("commodity_indicators", {})
	if indicators.size() != EXPECTED_COMMODITY_COUNT:
		_fail("Expected partial normalization to backfill %d commodities, got %d." % [EXPECTED_COMMODITY_COUNT, indicators.size()])
		return false
	var coal: Dictionary = indicators.get("coal", {})
	if str(coal.get("regime", "")) != "firm" or not is_equal_approx(float(coal.get("ytd_move", 0.0)), 8.5):
		_fail("Expected partial coal indicator to preserve firm 8.5 ytd move, got %s." % JSON.stringify(coal))
		return false
	var rare_earth: Dictionary = indicators.get("rare_earth", {})
	if str(rare_earth.get("regime", "")) != "neutral" or not is_equal_approx(float(rare_earth.get("ytd_move", -999.0)), 0.0):
		_fail("Expected missing rare_earth indicator to be neutral, got %s." % JSON.stringify(rare_earth))
		return false
	var regime_counts: Dictionary = state.get("commodity_regime_counts", {})
	if int(regime_counts.get("firm", 0)) != 1 or int(regime_counts.get("neutral", 0)) != EXPECTED_COMMODITY_COUNT - 1:
		_fail("Expected partial regime counts to preserve one firm row, got %s." % JSON.stringify(regime_counts))
		return false
	if not state.get("commodity_leaders", []).has("coal"):
		_fail("Expected partial commodity leaders to include coal, got %s." % JSON.stringify(state.get("commodity_leaders", [])))
		return false
	if not state.get("commodity_laggards", []).is_empty():
		_fail("Expected partial commodity laggards to be empty, got %s." % JSON.stringify(state.get("commodity_laggards", [])))
		return false
	return true


func _neutral_level_by_id() -> Dictionary:
	var levels: Dictionary = {}
	for commodity_value in DataRepository.get_commodity_indicator_definitions():
		if typeof(commodity_value) != TYPE_DICTIONARY:
			continue
		var commodity: Dictionary = commodity_value
		var commodity_id: String = str(commodity.get("id", "")).strip_edges()
		if commodity_id.is_empty():
			continue
		var model: Dictionary = {}
		if typeof(commodity.get("model", {})) == TYPE_DICTIONARY:
			model = commodity.get("model", {})
		levels[commodity_id] = snappedf(float(model.get("neutral_level", 100.0)), 0.1)
	return levels


func _fail(message: String) -> void:
	push_error(message)
	print("COMMODITY_MACRO_SAVE_DEFAULTS_FAIL: %s" % message)
	get_tree().quit(1)
