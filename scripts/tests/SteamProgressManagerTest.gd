extends Node

const RUN_SEED := 4739020


func _ready() -> void:
	ProjectSettings.set_setting("steam/progress/store_enabled", false)
	var data_repository = get_node("/root/DataRepository")
	var save_manager = get_node("/root/SaveManager")
	var game_manager = get_node("/root/GameManager")
	var run_state = get_node("/root/RunState")
	var steam_progress_manager = get_node("/root/SteamProgressManager")
	data_repository.call("reload_all")
	save_manager.call("set_autosave_enabled", false)
	var difficulty_config: Dictionary = game_manager.call("get_difficulty_config", "normal")
	var company_definitions: Array = game_manager.call("build_company_roster", RUN_SEED, difficulty_config)
	run_state.call("setup_new_run", RUN_SEED, company_definitions, difficulty_config, false)
	steam_progress_manager.call("reset_for_active_run")

	var company_order: Array = run_state.get("company_order")
	var company_id: String = str(company_order[0])
	steam_progress_manager.call("record_event", "watchlist_added", {"company_id": company_id})
	if not _assert_stat("STAT_WATCHLIST_ADDS", 1):
		return
	if not _assert_achievement("ACH_FIRST_WATCHLIST"):
		return

	steam_progress_manager.call("record_trade", {
		"company_id": company_id,
		"side": "buy",
		"lots": 2,
		"shares": 200,
		"realized_pnl": 0.0
	})
	if not _assert_stat("STAT_TRADES_PLACED", 1):
		return
	if not _assert_stat("STAT_BUY_ORDERS", 1):
		return
	if not _assert_stat("STAT_LOTS_TRADED", 2):
		return
	if not _assert_achievement("ACH_FIRST_TRADE"):
		return

	steam_progress_manager.call("record_trade", {
		"company_id": company_id,
		"side": "sell",
		"lots": 1,
		"shares": 100,
		"realized_pnl": 1000.0
	})
	if not _assert_stat("STAT_SELL_ORDERS", 1):
		return
	if not _assert_stat("STAT_PROFITABLE_SELLS", 1):
		return
	if not _assert_achievement("ACH_FIRST_PROFIT"):
		return

	steam_progress_manager.call("record_stockbot_tab_view", "Key Stats", company_id)
	if not _assert_stat("STAT_KEY_STATS_INSPECTED", 1):
		return
	if not _assert_achievement("ACH_CHECK_KEY_STATS"):
		return

	run_state.set("day_index", 20)
	steam_progress_manager.call("record_day_advanced")
	if not _assert_stat("STAT_DAYS_SURVIVED", 20):
		return
	if not _assert_achievement("ACH_SURVIVE_FIRST_MONTH"):
		return
	if not _assert_achievement("ACH_NORMAL_MONTH"):
		return

	var saved: Dictionary = run_state.call("to_save_dict")
	run_state.call("load_from_dict", saved)
	if not _assert_stat("STAT_TRADES_PLACED", 2):
		return
	if not _assert_achievement("ACH_FIRST_TRADE"):
		return

	print("STEAM_PROGRESS_MANAGER_TEST_OK")
	get_tree().quit(0)


func _assert_stat(api_name: String, expected_value: int) -> bool:
	var run_state = get_node("/root/RunState")
	var stats: Dictionary = run_state.call("get_steam_progress").get("stats", {})
	var actual_value: int = int(stats.get(api_name, 0))
	if actual_value != expected_value:
		_fail("Expected %s to be %d, got %d." % [api_name, expected_value, actual_value])
		return false
	return true


func _assert_achievement(api_name: String) -> bool:
	var run_state = get_node("/root/RunState")
	var achievements: Dictionary = run_state.call("get_steam_progress").get("achievements", {})
	if not bool(achievements.get(api_name, false)):
		_fail("Expected %s to be unlocked." % api_name)
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
