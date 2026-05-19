extends Node

const RUN_SEED := 516316


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0
	RunState.player_portfolio["cash"] = 50000000000.0
	RunState.refresh_cash_stress_state()

	var baseline_save: Dictionary = RunState.to_save_dict()
	var legacy_save: Dictionary = baseline_save.duplicate(true)
	var legacy_life: Dictionary = legacy_save.get("player_life", {}).duplicate(true)
	legacy_life.erase("properties")
	legacy_life.erase("cars")
	legacy_save["player_life"] = legacy_life
	RunState.load_from_dict(legacy_save)
	var legacy_state: Dictionary = RunState.get_player_life()
	if not legacy_state.has("properties") or not legacy_state.has("cars") or not legacy_state.get("properties", []).is_empty() or not legacy_state.get("cars", []).is_empty():
		_fail("Old saves should normalize with empty Life properties and cars.")
		return

	RunState.load_from_dict(baseline_save)
	RunState.player_portfolio["cash"] = 50000000000.0
	RunState.refresh_cash_stress_state()
	var baseline_snapshot: Dictionary = GameManager.get_life_snapshot()
	var jakarta_mansion_price: float = _property_catalog_price(baseline_snapshot, "mansion", "jakarta")
	var tangerang_mansion_price: float = _property_catalog_price(baseline_snapshot, "mansion", "tangerang")
	var bali_mansion_price: float = _property_catalog_price(baseline_snapshot, "mansion", "denpasar")
	var bandung_mansion_price: float = _property_catalog_price(baseline_snapshot, "mansion", "bandung")
	var surabaya_mansion_price: float = _property_catalog_price(baseline_snapshot, "mansion", "surabaya")
	if absf(jakarta_mansion_price - 100000000000.0) > 0.01:
		_fail("Expected Jakarta mansion pricing to anchor at Rp100B.")
		return
	if absf(tangerang_mansion_price - 90000000000.0) > 0.01:
		_fail("Expected Tangerang mansion pricing to anchor at Rp90B.")
		return
	if absf(bali_mansion_price - 108000000000.0) > 0.01:
		_fail("Expected Bali mansion pricing to anchor at Rp108B.")
		return
	if absf(bandung_mansion_price - 85000000000.0) > 0.01:
		_fail("Expected Bandung mansion pricing to anchor at Rp85B.")
		return
	if absf(surabaya_mansion_price - 88000000000.0) > 0.01:
		_fail("Expected Surabaya mansion pricing to anchor at Rp88B.")
		return
	var baseline_public_image_score: float = float(baseline_snapshot.get("public_image", {}).get("score", 0.0))
	var cash_before_property: float = float(GameManager.get_portfolio_snapshot().get("cash", 0.0))
	var property_result: Dictionary = GameManager.purchase_life_property("basic_apartment", "jakarta", true)
	if not bool(property_result.get("success", false)):
		_fail("Expected primary property purchase to succeed: %s" % str(property_result.get("message", "")))
		return
	var property_row: Dictionary = property_result.get("property", {})
	var after_primary_snapshot: Dictionary = GameManager.get_life_snapshot()
	if (
		after_primary_snapshot.get("properties", []).size() != 1 or
		not bool(after_primary_snapshot.get("owned_primary_residence", false)) or
		str(after_primary_snapshot.get("primary_property", {}).get("id", "")) != str(property_row.get("id", ""))
	):
		_fail("Expected purchased property to become the primary residence.")
		return
	var property_price: float = float(property_row.get("purchase_price", 0.0))
	var cash_after_property: float = float(GameManager.get_portfolio_snapshot().get("cash", 0.0))
	if absf(cash_after_property - (cash_before_property - property_price)) > 0.01:
		_fail("Expected property purchase to reduce cash by the full purchase price.")
		return
	if absf(float(after_primary_snapshot.get("housing_cost_monthly", 0.0)) - float(property_row.get("monthly_upkeep", 0.0))) > 0.01:
		_fail("Expected owned primary residence upkeep to replace the rented housing cost.")
		return

	var rental_result: Dictionary = GameManager.purchase_life_property("kost_room", "jakarta", false)
	if not bool(rental_result.get("success", false)):
		_fail("Expected investment property purchase to succeed.")
		return
	var rental_property_id: String = str(rental_result.get("property", {}).get("id", ""))
	var before_rent_snapshot: Dictionary = GameManager.get_life_snapshot()
	var rental_toggle: Dictionary = GameManager.set_property_rental(rental_property_id, true)
	if not bool(rental_toggle.get("success", false)):
		_fail("Expected non-primary property to be rentable.")
		return
	var after_rent_snapshot: Dictionary = GameManager.get_life_snapshot()
	if (
		float(after_rent_snapshot.get("rental_income", 0.0)) <= 0.0 or
		float(after_rent_snapshot.get("monthly_outflow", 0.0)) >= float(before_rent_snapshot.get("monthly_outflow", 0.0))
	):
		_fail("Expected rented property to add modest rental income and reduce net monthly outflow.")
		return

	var car_result: Dictionary = GameManager.purchase_life_car("city_car")
	if not bool(car_result.get("success", false)):
		_fail("Expected car purchase to succeed.")
		return
	var after_car_snapshot: Dictionary = GameManager.get_life_snapshot()
	if (
		after_car_snapshot.get("cars", []).size() != 1 or
		after_car_snapshot.get("active_car", {}).is_empty() or
		float(after_car_snapshot.get("car_upkeep", 0.0)) <= 0.0 or
		float(after_car_snapshot.get("public_image", {}).get("score", 0.0)) <= baseline_public_image_score
	):
		_fail("Expected first car to become active, add upkeep, and improve public image.")
		return

	var saved_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(saved_state)
	var reloaded_snapshot: Dictionary = GameManager.get_life_snapshot()
	if (
		reloaded_snapshot.get("properties", []).size() != 2 or
		reloaded_snapshot.get("cars", []).size() != 1 or
		reloaded_snapshot.get("primary_property", {}).is_empty() or
		reloaded_snapshot.get("active_car", {}).is_empty()
	):
		_fail("Expected Life assets to survive save/load.")
		return

	var monthly_snapshot: Dictionary = GameManager.get_life_snapshot()
	var expected_due: float = float(monthly_snapshot.get("monthly_outflow", 0.0))
	var life_payment_count: int = 0
	for _day in range(35):
		GameManager._advance_day_internal(false, true)
		var obligation: Dictionary = RunState.last_day_results.get("life_obligation", {})
		if not obligation.is_empty():
			life_payment_count += 1
			if absf(float(obligation.get("amount", 0.0)) - expected_due) > 0.01:
				_fail("Expected monthly Life obligation to use the net lifestyle outflow.")
				return
	if life_payment_count != 1:
		_fail("Expected exactly one monthly Life obligation within 35 trading days, got %d." % life_payment_count)
		return

	print("LIFE_LIFESTYLE_ASSET_TEST_OK")
	get_tree().quit(0)


func _property_catalog_price(life_snapshot: Dictionary, catalog_id: String, location_id: String) -> float:
	for row_value in life_snapshot.get("property_catalog", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("catalog_id", "")) == catalog_id and str(row.get("location_id", "")) == location_id:
			return float(row.get("price", 0.0))
	return 0.0


func _fail(message: String) -> void:
	push_error(message)
	print("LIFE_LIFESTYLE_ASSET_TEST_FAIL: %s" % message)
	get_tree().quit(1)
