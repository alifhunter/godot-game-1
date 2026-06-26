extends Node

const MARKET_SIMULATOR = preload("res://systems/MarketSimulator.gd")
const RUN_SEED := 20260614
const CATALOG_COMPANY_COUNT := 30
const PROCEDURAL_COMPANY_COUNT := 18


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var catalog_report: Dictionary = _run_catalog_exposure_simulation_check()
	if catalog_report.is_empty():
		return
	var neutral_report: Dictionary = _run_procedural_neutral_simulation_check()
	if neutral_report.is_empty():
		return
	var calculation_report: Dictionary = _assert_calculation_consumes_exposure_drift()
	if calculation_report.is_empty():
		return

	print("PRICE_EXPOSURE_SIMULATION_INTEGRATION_OK %s" % JSON.stringify({
		"catalog": catalog_report,
		"neutral": neutral_report,
		"calculation": calculation_report
	}))
	get_tree().quit(0)


func _run_catalog_exposure_simulation_check() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = CATALOG_COMPANY_COUNT
	difficulty_config["use_company_universe_catalog"] = true
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)

	var advance_result: Dictionary = GameManager.simulate_opening_session(false)
	if not _assert_advance_ok(advance_result, "catalog"):
		return {}

	var exposed_company_id: String = ""
	var exposed_context: Dictionary = {}
	var exposed_volume_context: Dictionary = {}
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = RunState.get_company(company_id)
		var price_exposure_context: Dictionary = runtime.get("price_exposure_context", {}) if typeof(runtime.get("price_exposure_context", {})) == TYPE_DICTIONARY else {}
		var rows: Array = price_exposure_context.get("exposure_rows", []) if typeof(price_exposure_context.get("exposure_rows", [])) == TYPE_ARRAY else []
		if rows.is_empty():
			continue
		exposed_company_id = company_id
		exposed_context = price_exposure_context
		exposed_volume_context = runtime.get("volume_context", {}) if typeof(runtime.get("volume_context", {})) == TYPE_DICTIONARY else {}
		break

	if exposed_company_id.is_empty():
		_fail("Expected at least one catalog company to receive non-empty exposure context after simulation.")
		return {}
	if not _assert_exposure_context_shape(exposed_company_id, exposed_context, exposed_volume_context):
		return {}
	return {
		"company_id": exposed_company_id,
		"drift": float(exposed_context.get("exposure_drift_adjustment", 0.0)),
		"confidence": float(exposed_context.get("exposure_confidence", 0.0)),
		"rows": exposed_context.get("exposure_rows", []).size(),
		"volume_multiplier": float(exposed_volume_context.get("volume_multiplier", 1.0)),
		"exposure_volume_multiplier": float(exposed_context.get("exposure_volume_multiplier", 1.0))
	}


func _run_procedural_neutral_simulation_check() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = PROCEDURAL_COMPANY_COUNT
	difficulty_config["use_company_universe_catalog"] = false
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED + 1, difficulty_config)
	RunState.setup_new_run(RUN_SEED + 1, company_definitions, difficulty_config, false)

	var advance_result: Dictionary = GameManager.simulate_opening_session(false)
	if not _assert_advance_ok(advance_result, "procedural"):
		return {}

	var checked_count: int = 0
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = RunState.get_company(company_id)
		var price_exposure_context: Dictionary = runtime.get("price_exposure_context", {}) if typeof(runtime.get("price_exposure_context", {})) == TYPE_DICTIONARY else {}
		var exposure_rows: Array = price_exposure_context.get("exposure_rows", []) if typeof(price_exposure_context.get("exposure_rows", [])) == TYPE_ARRAY else []
		if not exposure_rows.is_empty():
			_fail("Expected procedural company '%s' to have neutral exposure rows, got %s." % [company_id, JSON.stringify(price_exposure_context)])
			return {}
		if not is_zero_approx(float(price_exposure_context.get("exposure_drift_adjustment", 0.0))):
			_fail("Expected procedural company '%s' to have neutral exposure drift, got %s." % [company_id, JSON.stringify(price_exposure_context)])
			return {}
		if not is_equal_approx(float(price_exposure_context.get("exposure_volatility_multiplier", 1.0)), 1.0):
			_fail("Expected procedural company '%s' to have neutral exposure volatility, got %s." % [company_id, JSON.stringify(price_exposure_context)])
			return {}
		if not is_equal_approx(float(price_exposure_context.get("exposure_volume_multiplier", 1.0)), 1.0):
			_fail("Expected procedural company '%s' to have neutral exposure volume, got %s." % [company_id, JSON.stringify(price_exposure_context)])
			return {}
		checked_count += 1
	return {
		"checked_companies": checked_count
	}


func _assert_calculation_consumes_exposure_drift() -> Dictionary:
	var simulator = MARKET_SIMULATOR.new()
	var definition: Dictionary = {
		"id": "exposure_calculation_probe",
		"quality_score": 50.0,
		"growth_score": 50.0,
		"risk_score": 50.0,
		"base_volatility": 0.0
	}
	var sector_definition: Dictionary = {
		"id": "test_sector",
		"volatility_bias": 0.0
	}
	var difficulty_config: Dictionary = {
		"volatility_multiplier": 1.0,
		"broker_impact_multiplier": 1.0,
		"daily_move_cap": 0.12
	}
	var neutral_context: Dictionary = {
		"exposure_drift_adjustment": 0.0,
		"exposure_volatility_multiplier": 1.0
	}
	var shifted_context: Dictionary = {
		"exposure_drift_adjustment": 0.003,
		"exposure_volatility_multiplier": 1.0
	}
	var neutral_change: float = float(simulator.call(
		"_calculate_daily_change",
		definition,
		sector_definition,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		neutral_context,
		RUN_SEED,
		9,
		"exposure_calculation_probe",
		difficulty_config,
		1.0
	))
	var shifted_change: float = float(simulator.call(
		"_calculate_daily_change",
		definition,
		sector_definition,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		shifted_context,
		RUN_SEED,
		9,
		"exposure_calculation_probe",
		difficulty_config,
		1.0
	))
	var delta: float = shifted_change - neutral_change
	if absf(delta - 0.003) > 0.00001:
		_fail("Expected exposure drift to add exactly 0.003 to deterministic price calculation, got delta=%s neutral=%s shifted=%s." % [
			String.num(delta, 6),
			String.num(neutral_change, 6),
			String.num(shifted_change, 6)
		])
		return {}
	return {
		"neutral_change": neutral_change,
		"shifted_change": shifted_change,
		"delta": delta
	}


func _assert_advance_ok(advance_result: Dictionary, label: String) -> bool:
	if advance_result.has("success") and not bool(advance_result.get("success", false)):
		_fail("%s simulation advance failed: %s" % [label, str(advance_result.get("message", ""))])
		return false
	if typeof(advance_result.get("day_result", {})) != TYPE_DICTIONARY or advance_result.get("day_result", {}).is_empty():
		_fail("%s simulation advance returned no day_result." % label)
		return false
	return true


func _assert_exposure_context_shape(company_id: String, exposure_context: Dictionary, volume_context: Dictionary) -> bool:
	var drift: float = float(exposure_context.get("exposure_drift_adjustment", 0.0))
	var volatility_multiplier: float = float(exposure_context.get("exposure_volatility_multiplier", 1.0))
	var volume_multiplier: float = float(exposure_context.get("exposure_volume_multiplier", 1.0))
	var confidence: float = float(exposure_context.get("exposure_confidence", 0.0))
	if drift < -0.004 or drift > 0.004:
		_fail("Catalog company '%s' exposure drift out of bounds: %s." % [company_id, JSON.stringify(exposure_context)])
		return false
	if volatility_multiplier < 0.90 or volatility_multiplier > 1.16:
		_fail("Catalog company '%s' exposure volatility out of bounds: %s." % [company_id, JSON.stringify(exposure_context)])
		return false
	if volume_multiplier < 0.92 or volume_multiplier > 1.22:
		_fail("Catalog company '%s' exposure volume out of bounds: %s." % [company_id, JSON.stringify(exposure_context)])
		return false
	if confidence <= 0.0 or confidence > 1.0:
		_fail("Catalog company '%s' expected positive exposure confidence, got %s." % [company_id, JSON.stringify(exposure_context)])
		return false
	if typeof(volume_context.get("price_exposure_context", {})) != TYPE_DICTIONARY:
		_fail("Catalog company '%s' missing nested price_exposure_context in volume context." % company_id)
		return false
	if not is_equal_approx(float(volume_context.get("exposure_drift_adjustment", 999.0)), drift):
		_fail("Catalog company '%s' volume context drift does not match resolver drift." % company_id)
		return false
	if not is_equal_approx(float(volume_context.get("exposure_volume_multiplier", 0.0)), volume_multiplier):
		_fail("Catalog company '%s' volume context volume multiplier does not match resolver output." % company_id)
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	print("PRICE_EXPOSURE_SIMULATION_INTEGRATION_FAIL: %s" % message)
	get_tree().quit(1)
