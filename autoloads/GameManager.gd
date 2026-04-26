extends Node

signal day_started(day_index)
signal price_formed(day_index)
signal portfolio_changed
signal watchlist_changed
signal network_changed
signal upgrades_changed
signal daily_actions_changed
signal academy_changed
signal summary_ready(summary)
signal broker_flow_generated(day_index)
signal run_started
signal run_loaded
signal run_loading_started(difficulty_id)
signal run_loading_progress(stage_id, stage_label, stage_index, stage_count, progress_ratio)
signal run_loading_detail_updated(subprogress_text, log_lines)
signal run_loading_finished
signal company_detail_ready(company_id)

const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"
const GAME_SCENE := "res://scenes/game/GameRoot.tscn"
const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")
const DEFAULT_DIFFICULTY_ID := "normal"
const STARTING_CASH := 100000000.0
const CONSOLE_CASH_GRANT_AMOUNT := 999999999999.0
const PLAYER_MAJOR_SHAREHOLDER_THRESHOLD := 0.05
const DEBUG_COMPANY_ARC_EVENT_IDS := {
	"earnings_beat": true,
	"earnings_miss": true,
	"strategic_acquisition": true,
	"integration_overhang": true
}
const DIFFICULTY_ORDER := ["chill", "normal", "grind"]
const NEW_RUN_FINAL_STEP_HOLD_SECONDS := 0.28
const NEW_RUN_LOADING_STEPS := [
	{"id": "seed", "label": "Preparing market seed"},
	{"id": "companies", "label": "Creating companies"},
	{"id": "financials", "label": "Creating financials"},
	{"id": "opening_day", "label": "Simulating opening session"},
	{"id": "save", "label": "Saving run"},
	{"id": "launch", "label": "Opening trading desk"}
]
const NETWORK_ACTION_COSTS := {
	"meet": 1,
	"tip": 2,
	"request": 1,
	"referral": 2,
	"followup": 1,
	"source_check": 1
}
const LOAD_RUN_LOADING_STEPS := [
	{"id": "load_save", "label": "Reading save file"},
	{"id": "restore_state", "label": "Restoring run state"},
	{"id": "load_launch", "label": "Opening trading desk"}
]
const STARTUP_PERF_LOG_PREFIX := "[perf][startup]"
const ADVANCE_PERF_LOG_PREFIX := "[perf][advance]"
const DASHBOARD_REPORT_ROW_CACHE_LIMIT := 8
const DIFFICULTY_PRESETS := {
	"chill": {
		"id": "chill",
		"label": "Chill",
		"starting_cash": 1000000000.0,
		"company_count": 20,
		"market_swing_range": 0.02,
		"volatility_multiplier": 0.75,
		"event_interval_days": 14.0,
		"broker_impact_multiplier": 0.85,
		"daily_move_cap": 0.08,
		"volatility_label": "Low",
		"event_label": "Every 14 Days",
		"description": "A forgiving tape with calmer moves, slower event cadence, and plenty of cash to experiment."
	},
	"normal": {
		"id": "normal",
		"label": "Normal",
		"starting_cash": 100000000.0,
		"company_count": 30,
		"market_swing_range": 0.035,
		"volatility_multiplier": 1.0,
		"event_interval_days": 10.0,
		"broker_impact_multiplier": 1.0,
		"daily_move_cap": 0.12,
		"volatility_label": "Normal",
		"event_label": "Every 10 Days",
		"description": "The balanced prototype experience with readable tape, meaningful bankroll pressure, and a tighter market roster."
	},
	"grind": {
		"id": "grind",
		"label": "Grind",
		"starting_cash": 10000000.0,
		"company_count": 50,
		"market_swing_range": 0.055,
		"volatility_multiplier": 1.35,
		"event_interval_days": 7.0,
		"broker_impact_multiplier": 1.2,
		"daily_move_cap": 0.18,
		"volatility_label": "High",
		"event_label": "Every 7 Days",
		"description": "A leaner hard mode with sharper moves, tighter bankroll pressure, and regular news catalysts."
	}
}

var market_simulator = preload("res://systems/MarketSimulator.gd").new()
var summary_system = preload("res://systems/SummaryInsightSystem.gd").new()
var broker_flow_system = preload("res://systems/BrokerFlowSystem.gd").new()
var trading_calendar = preload("res://systems/TradingCalendar.gd").new()
var company_roster_generator = preload("res://systems/CompanyRosterGenerator.gd").new()
var chart_system = preload("res://systems/ChartSystem.gd").new()
var news_feed_system = preload("res://systems/NewsFeedSystem.gd").new()
var twooter_feed_system = preload("res://systems/TwooterFeedSystem.gd").new()
var contact_network_system = preload("res://systems/ContactNetworkSystem.gd").new()
var corporate_action_system = preload("res://systems/CorporateActionSystem.gd").new()
var company_event_system = preload("res://systems/CompanyEventSystem.gd").new()
var person_event_system = preload("res://systems/PersonEventSystem.gd").new()
var special_event_system = preload("res://systems/SpecialEventSystem.gd").new()
var academy_system = preload("res://systems/AcademySystem.gd").new()
var background_company_detail_hydration_running: bool = false
var loading_detail_log_lines: Array = []
var dashboard_event_snapshot_cache: Dictionary = {}
var daily_activity_snapshot_cache: Dictionary = {}


func _ready() -> void:
	DataRepository.reload_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_flush_pending_save_if_needed()


func _request_autosave(reason: String) -> void:
	SaveManager.request_save(reason)


func _save_active_run_now(reason: String) -> bool:
	if not RunState.has_active_run():
		return false
	SaveManager.request_save(reason, 0.0)
	return SaveManager.flush_pending_save()


func _flush_pending_save_if_needed() -> bool:
	if not SaveManager.has_pending_save():
		return true
	return SaveManager.flush_pending_save()


func flush_pending_save_if_needed() -> bool:
	return _flush_pending_save_if_needed()


func start_new_run(run_seed: int = 0, difficulty_id: String = DEFAULT_DIFFICULTY_ID, tutorial_enabled: bool = false) -> void:
	if run_seed == 0:
		run_seed = int(Time.get_unix_time_from_system())

	var difficulty_config: Dictionary = get_difficulty_config(difficulty_id)
	var company_definitions: Array = build_company_roster(run_seed, difficulty_config)
	RunState.setup_new_run(run_seed, company_definitions, difficulty_config, tutorial_enabled)
	background_company_detail_hydration_running = false
	_invalidate_dashboard_event_snapshot_cache()
	_invalidate_daily_activity_snapshot_cache()
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	simulate_opening_session(false)
	_save_active_run_now("start_new_run")
	run_started.emit()
	_enter_game_scene()


func start_new_run_with_loading(
	run_seed: int = 0,
	difficulty_id: String = DEFAULT_DIFFICULTY_ID,
	tutorial_enabled: bool = false
) -> void:
	if run_seed == 0:
		run_seed = int(Time.get_unix_time_from_system())

	var difficulty_config: Dictionary = get_difficulty_config(difficulty_id)
	background_company_detail_hydration_running = false
	loading_detail_log_lines.clear()
	run_loading_started.emit(str(difficulty_config.get("id", difficulty_id)))
	_emit_run_loading_detail("", [])
	_emit_run_loading_step(0)
	await get_tree().process_frame

	_emit_run_loading_step(1)
	var company_definitions: Array = build_company_roster(run_seed, difficulty_config)
	await get_tree().process_frame

	_emit_run_loading_step(2)
	await get_tree().process_frame
	var financials_started_at_usec: int = Time.get_ticks_usec()
	await RunState.setup_new_run_batched(
		run_seed,
		company_definitions,
		difficulty_config,
		tutorial_enabled,
		Callable(self, "_on_new_run_financial_batch_progress"),
		5,
		Callable(self, "_on_new_run_financial_batch_detail")
	)
	_log_startup_perf_elapsed("new_run_financials_total", financials_started_at_usec, " companies=%d" % company_definitions.size())
	_invalidate_dashboard_event_snapshot_cache()
	_invalidate_daily_activity_snapshot_cache()
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	await get_tree().process_frame

	_emit_run_loading_step(3)
	simulate_opening_session(false)
	await get_tree().process_frame

	_emit_run_loading_step(4)
	_save_active_run_now("start_new_run_with_loading")
	run_started.emit()
	await _hold_loading_stage(NEW_RUN_FINAL_STEP_HOLD_SECONDS)

	_emit_run_loading_step(5)
	await _hold_loading_stage(NEW_RUN_FINAL_STEP_HOLD_SECONDS)
	_emit_run_loading_detail("", [])
	run_loading_finished.emit()
	_enter_game_scene()


func load_run_from_save() -> bool:
	var saved_run: Dictionary = SaveManager.load_run()
	if saved_run.is_empty():
		return false

	RunState.load_from_dict(saved_run)
	background_company_detail_hydration_running = false
	_invalidate_dashboard_event_snapshot_cache()
	_invalidate_daily_activity_snapshot_cache()
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	run_loaded.emit()
	_enter_game_scene()
	return true


func load_run_from_save_with_loading() -> bool:
	_emit_load_run_loading_step(0)
	await get_tree().process_frame

	var saved_run: Dictionary = SaveManager.load_run()
	if saved_run.is_empty():
		run_loading_finished.emit()
		return false

	_emit_load_run_loading_step(1)
	RunState.load_from_dict(saved_run)
	background_company_detail_hydration_running = false
	_invalidate_dashboard_event_snapshot_cache()
	_invalidate_daily_activity_snapshot_cache()
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	run_loaded.emit()
	await get_tree().process_frame

	_emit_load_run_loading_step(2)
	await get_tree().process_frame
	run_loading_finished.emit()
	_enter_game_scene()
	return true


func return_to_menu() -> void:
	_flush_pending_save_if_needed()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func quit_game() -> void:
	_flush_pending_save_if_needed()
	get_tree().quit()


func advance_day() -> void:
	_advance_day_internal(true, true)


func advance_day_deferred_save() -> void:
	_advance_day_internal(true, true, false)


func simulate_opening_session(save_after: bool = false) -> Dictionary:
	return _advance_day_internal(save_after, false)


func _advance_day_internal(save_after: bool = true, emit_runtime_signals: bool = true, flush_save_immediately: bool = true) -> Dictionary:
	if not RunState.has_active_run():
		return {}
	var log_advance_perf: bool = _should_log_advance_perf(save_after, emit_runtime_signals)
	var total_started_at_usec: int = Time.get_ticks_usec()
	var phase_started_at_usec: int = total_started_at_usec
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	_log_advance_perf_elapsed(log_advance_perf, "ensure_corporate_actions", phase_started_at_usec)

	if emit_runtime_signals:
		phase_started_at_usec = Time.get_ticks_usec()
		day_started.emit(RunState.day_index + 1)
		_log_advance_perf_elapsed(log_advance_perf, "emit_day_started", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var day_result: Dictionary = market_simulator.simulate_day(RunState, DataRepository, broker_flow_system, corporate_action_system)
	_log_advance_perf_elapsed(log_advance_perf, "simulate_day", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	RunState.apply_day_result(day_result)
	_log_advance_perf_elapsed(log_advance_perf, "apply_day_result", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var network_results: Array = contact_network_system.process_due_requests(RunState, DataRepository)
	_log_advance_perf_elapsed(log_advance_perf, "process_due_requests", phase_started_at_usec, " count=%d" % network_results.size())
	phase_started_at_usec = Time.get_ticks_usec()
	var network_tip_results: Array = contact_network_system.process_due_tip_memories(RunState, DataRepository)
	_log_advance_perf_elapsed(log_advance_perf, "process_due_tip_memories", phase_started_at_usec, " count=%d" % network_tip_results.size())
	phase_started_at_usec = Time.get_ticks_usec()
	_rebuild_dashboard_event_snapshot_cache("", log_advance_perf)
	_log_advance_perf_elapsed(log_advance_perf, "build_dashboard_event_cache", phase_started_at_usec)
	if (not network_results.is_empty() or not network_tip_results.is_empty()) and emit_runtime_signals:
		phase_started_at_usec = Time.get_ticks_usec()
		network_changed.emit()
		_log_advance_perf_elapsed(log_advance_perf, "emit_network_changed", phase_started_at_usec)
	if emit_runtime_signals:
		phase_started_at_usec = Time.get_ticks_usec()
		broker_flow_generated.emit(RunState.day_index)
		_log_advance_perf_elapsed(log_advance_perf, "emit_broker_flow_generated", phase_started_at_usec)
		phase_started_at_usec = Time.get_ticks_usec()
		price_formed.emit(RunState.day_index)
		_log_advance_perf_elapsed(log_advance_perf, "emit_price_formed", phase_started_at_usec)
		phase_started_at_usec = Time.get_ticks_usec()
		daily_actions_changed.emit()
		_log_advance_perf_elapsed(log_advance_perf, "emit_daily_actions_changed", phase_started_at_usec)

	phase_started_at_usec = Time.get_ticks_usec()
	var summary: Dictionary = summary_system.build_daily_summary(RunState, DataRepository)
	_log_advance_perf_elapsed(log_advance_perf, "build_daily_summary", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	RunState.set_daily_summary(summary)
	_log_advance_perf_elapsed(log_advance_perf, "set_daily_summary", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var news_snapshot: Dictionary = _build_news_snapshot()
	_log_advance_perf_elapsed(log_advance_perf, "build_news_snapshot", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	RunState.record_news_snapshot(news_snapshot)
	_log_advance_perf_elapsed(log_advance_perf, "record_news_snapshot", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_rebuild_daily_activity_snapshot_cache(news_snapshot, "", log_advance_perf)
	_log_advance_perf_elapsed(log_advance_perf, "build_daily_activity_cache", phase_started_at_usec)
	if save_after:
		phase_started_at_usec = Time.get_ticks_usec()
		if flush_save_immediately:
			_save_active_run_now("advance_day")
			_log_advance_perf_elapsed(log_advance_perf, "save_active_run", phase_started_at_usec)
		else:
			_request_autosave("advance_day")
			_log_advance_perf_elapsed(log_advance_perf, "request_save", phase_started_at_usec)
	if emit_runtime_signals:
		phase_started_at_usec = Time.get_ticks_usec()
		summary_ready.emit(summary)
		_log_advance_perf_elapsed(log_advance_perf, "emit_summary_ready", phase_started_at_usec)
		phase_started_at_usec = Time.get_ticks_usec()
		portfolio_changed.emit()
		_log_advance_perf_elapsed(log_advance_perf, "emit_portfolio_changed", phase_started_at_usec)
	_log_advance_perf_elapsed(log_advance_perf, "total", total_started_at_usec, " save_after=%s emit_runtime_signals=%s flush_save_immediately=%s" % [str(save_after), str(emit_runtime_signals), str(flush_save_immediately)])
	return {
		"day_result": day_result,
		"summary": summary
	}


func buy_company(company_id: String, shares: int = 1) -> Dictionary:
	var result: Dictionary = RunState.buy_company(company_id, shares)
	if result.get("success", false):
		_invalidate_dashboard_event_snapshot_cache()
		_request_autosave("buy_company")
		portfolio_changed.emit()
	return result


func sell_company(company_id: String, shares: int = 1) -> Dictionary:
	var result: Dictionary = RunState.sell_company(company_id, shares)
	if result.get("success", false):
		_invalidate_dashboard_event_snapshot_cache()
		_request_autosave("sell_company")
		portfolio_changed.emit()
	return result


func buy_lots(company_id: String, lots: int = 1) -> Dictionary:
	return buy_company(company_id, lots_to_shares(lots))


func sell_lots(company_id: String, lots: int = 1) -> Dictionary:
	return sell_company(company_id, lots_to_shares(lots))


func estimate_buy_lots(company_id: String, lots: int = 1) -> Dictionary:
	return RunState.estimate_buy_order(company_id, lots_to_shares(lots))


func estimate_sell_lots(company_id: String, lots: int = 1) -> Dictionary:
	return RunState.estimate_sell_order(company_id, lots_to_shares(lots))


func add_company_to_watchlist(company_id: String) -> Dictionary:
	var result: Dictionary = RunState.add_to_watchlist(company_id)
	if result.get("success", false):
		_request_autosave("watchlist_add")
		watchlist_changed.emit()
	return result


func remove_company_from_watchlist(company_id: String) -> Dictionary:
	var result: Dictionary = RunState.remove_from_watchlist(company_id)
	if result.get("success", false):
		_request_autosave("watchlist_remove")
		watchlist_changed.emit()
	return result


func get_upgrade_shop_snapshot() -> Dictionary:
	var cash_available: float = float(RunState.player_portfolio.get("cash", 0.0))
	var tracks: Array = []
	for track_value in DataRepository.get_upgrade_catalog().get("tracks", []):
		if typeof(track_value) != TYPE_DICTIONARY:
			continue
		var track: Dictionary = track_value
		var track_id: String = str(track.get("id", ""))
		if track_id.is_empty():
			continue
		var current_tier: int = RunState.get_upgrade_tier(track_id)
		var current_data: Dictionary = _upgrade_tier_data(track, current_tier)
		var next_tier: int = current_tier - 1
		var next_data: Dictionary = _upgrade_tier_data(track, next_tier)
		var next_cost: float = float(next_data.get("cost", 0.0)) if next_tier >= 1 else 0.0
		tracks.append({
			"id": track_id,
			"label": str(track.get("label", track_id.capitalize())),
			"description": str(track.get("description", "")),
			"tier": current_tier,
			"effect_label": str(current_data.get("effect_label", "Tier %d" % current_tier)),
			"next_tier": next_tier if next_tier >= 1 else 0,
			"next_effect_label": str(next_data.get("effect_label", "")),
			"next_cost": next_cost,
			"maxed": current_tier <= 1,
			"affordable": cash_available + 0.0001 >= next_cost and next_cost > 0.0,
			"can_purchase": current_tier > 1 and cash_available + 0.0001 >= next_cost and next_cost > 0.0
		})

	return {
		"cash": cash_available,
		"tracks": tracks,
		"daily_action": RunState.get_daily_action_snapshot()
	}


func purchase_upgrade(track_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}

	var track: Dictionary = _upgrade_track(track_id)
	if track.is_empty():
		return {"success": false, "message": "Unknown upgrade."}

	var normalized_track_id: String = str(track.get("id", track_id))
	var current_tier: int = RunState.get_upgrade_tier(normalized_track_id)
	if current_tier <= 1:
		return {"success": false, "message": "%s is already maxed." % str(track.get("label", "Upgrade"))}

	var next_tier: int = current_tier - 1
	var next_data: Dictionary = _upgrade_tier_data(track, next_tier)
	var cost: float = float(next_data.get("cost", 0.0))
	if cost <= 0.0:
		return {"success": false, "message": "That upgrade tier has no price."}

	var cash_available: float = float(RunState.player_portfolio.get("cash", 0.0))
	if cost > cash_available + 0.0001:
		return {"success": false, "message": "Not enough cash for that upgrade."}

	RunState.player_portfolio["cash"] = cash_available - cost
	RunState.set_upgrade_tier(normalized_track_id, next_tier)
	_invalidate_daily_activity_snapshot_cache()
	_request_autosave("purchase_upgrade")
	upgrades_changed.emit()
	portfolio_changed.emit()
	if normalized_track_id == "daily_action_points":
		daily_actions_changed.emit()
	return {
		"success": true,
		"message": "%s upgraded to tier %d." % [str(track.get("label", "Upgrade")), next_tier],
		"track_id": normalized_track_id,
		"tier": next_tier,
		"cash": float(RunState.player_portfolio.get("cash", 0.0))
	}


func execute_console_command(command_text: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}

	var normalized_command: String = command_text.strip_edges().to_lower()
	match normalized_command:
		"cuankus":
			var cash_before: float = float(RunState.player_portfolio.get("cash", 0.0))
			RunState.player_portfolio["cash"] = cash_before + CONSOLE_CASH_GRANT_AMOUNT
			_request_autosave("console_cuankus")
			portfolio_changed.emit()
			return {
				"success": true,
				"message": "Cuankus! Cash added: Rp999.999.999.999.",
				"command": normalized_command,
				"cash": float(RunState.player_portfolio.get("cash", 0.0))
			}
		"ordalbos":
			for track_id in RunState.UPGRADE_TRACK_IDS:
				RunState.set_upgrade_tier(str(track_id), 1)
			_invalidate_daily_activity_snapshot_cache()
			_request_autosave("console_ordalbos")
			upgrades_changed.emit()
			daily_actions_changed.emit()
			return {
				"success": true,
				"message": "Ordal bos unlocked every upgrade.",
				"command": normalized_command,
				"upgrade_tiers": RunState.get_upgrade_tiers()
			}

	return {
		"success": false,
		"message": "Unknown command: %s" % command_text.strip_edges(),
		"command": normalized_command
	}


func debug_force_rights_issue_rupslb(company_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_force_rights_issue_rupslb(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not force a same-day rights issue RUPSLB for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	return {
		"success": true,
		"message": "Forced same-day rights issue RUPSLB created.",
		"chain": result.get("chain", {}).duplicate(true),
		"meeting": result.get("meeting", {}).duplicate(true)
	}


func debug_schedule_next_day_rights_issue_rupslb(company_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	var holding: Dictionary = RunState.get_holding(company_id)
	if int(holding.get("shares", 0)) < get_lot_size():
		return {"success": false, "message": "Own at least 1 lot first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_schedule_next_day_rights_issue_rupslb(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not schedule a next-day rights issue RUPSLB for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_schedule_next_day_rupslb")
	var meeting: Dictionary = result.get("meeting", {}).duplicate(true)
	return {
		"success": true,
		"message": "Scheduled next-day rights issue RUPSLB for %s on %s." % [
			str(meeting.get("ticker", company_id.to_upper())),
			format_trade_date(meeting.get("trade_date", {}))
		],
		"chain": result.get("chain", {}).duplicate(true),
		"meeting": meeting
	}


func get_unlocked_news_intel_level() -> int:
	return _content_level_for_upgrade("news_content")


func get_unlocked_twooter_access_tier() -> int:
	return _content_level_for_upgrade("twooter_content")


func get_unlocked_chart_indicator_ids() -> Array:
	var track: Dictionary = _upgrade_track("chart_indicators")
	var tier_data: Dictionary = _upgrade_tier_data(track, RunState.get_upgrade_tier("chart_indicators"))
	return tier_data.get("indicator_ids", []).duplicate()


func get_daily_action_snapshot() -> Dictionary:
	return RunState.get_daily_action_snapshot()


func try_spend_daily_action(action_id: String, metadata: Dictionary = {}) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if not RunState.can_spend_daily_action(1):
		return {
			"success": false,
			"message": "No daily action points left.",
			"action_id": action_id,
			"metadata": metadata.duplicate(true),
			"snapshot": RunState.get_daily_action_snapshot()
		}
	var result: Dictionary = RunState.spend_daily_action(1)
	if bool(result.get("success", false)):
		_request_autosave("spend_daily_action")
		daily_actions_changed.emit()
	result["action_id"] = action_id
	result["metadata"] = metadata.duplicate(true)
	return result


func get_network_action_cost(action_id: String) -> int:
	return int(NETWORK_ACTION_COSTS.get(action_id, 1))


func _can_spend_network_action(action_id: String) -> bool:
	return RunState.can_spend_daily_action(get_network_action_cost(action_id))


func _spend_network_action(action_id: String) -> Dictionary:
	return RunState.spend_daily_action(get_network_action_cost(action_id))


func _network_action_no_ap_message(action_id: String) -> String:
	return "Need %d AP for this Network action." % get_network_action_cost(action_id)


func get_academy_snapshot(category_id: String = "technical", section_id: String = "") -> Dictionary:
	var requested_category_id: String = category_id
	if requested_category_id.is_empty():
		requested_category_id = str(RunState.get_academy_progress().get("last_category_id", "technical"))
	var requested_section_id: String = section_id
	if requested_section_id.is_empty():
		requested_section_id = str(RunState.get_academy_progress().get("last_section_id", "intro"))
	return academy_system.build_snapshot(
		DataRepository.get_academy_catalog(),
		RunState.get_academy_progress(),
		requested_category_id,
		requested_section_id
	)


func mark_academy_section_read(category_id: String, section_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var result: Dictionary = academy_system.mark_section_read(
		DataRepository.get_academy_catalog(),
		RunState.get_academy_progress(),
		category_id,
		section_id
	)
	if bool(result.get("success", false)):
		RunState.set_academy_progress(result.get("progress", {}))
		_request_autosave("academy_mark_read")
		academy_changed.emit()
	return result


func submit_academy_inline_check(
	category_id: String,
	section_id: String,
	check_id: String,
	answer_id: String
) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var result: Dictionary = academy_system.submit_inline_check(
		DataRepository.get_academy_catalog(),
		RunState.get_academy_progress(),
		category_id,
		section_id,
		check_id,
		answer_id
	)
	if bool(result.get("success", false)):
		RunState.set_academy_progress(result.get("progress", {}))
		_request_autosave("academy_inline_check")
		academy_changed.emit()
	return result


func submit_academy_quiz(category_id: String, answers: Dictionary) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var result: Dictionary = academy_system.submit_quiz(
		DataRepository.get_academy_catalog(),
		RunState.get_academy_progress(),
		category_id,
		answers
	)
	if bool(result.get("success", false)):
		RunState.set_academy_progress(result.get("progress", {}))
		_request_autosave("academy_quiz")
		academy_changed.emit()
	return result


func search_academy_glossary(query: String) -> Array:
	return academy_system.search_glossary(DataRepository.get_academy_catalog(), query)


func get_watchlist_company_ids() -> Array:
	return RunState.get_watchlist_company_ids()


func get_company_rows() -> Array:
	var rows: Array = []
	for company_id in RunState.company_order:
		rows.append(get_company_snapshot(str(company_id), false, false, false))
	return rows


func get_report_calendar_snapshot(year_value: int = 0, month_value: int = 0) -> Dictionary:
	var trade_date: Dictionary = RunState.get_current_trade_date()
	var resolved_year: int = int(trade_date.get("year", 2020)) if year_value <= 0 else year_value
	var resolved_month: int = int(trade_date.get("month", 1)) if month_value <= 0 else month_value
	if _is_current_report_calendar_month(resolved_year, resolved_month):
		return get_dashboard_event_snapshot().get("report_calendar_snapshot", {}).duplicate(true)
	return RunState.get_report_calendar_month(resolved_year, resolved_month)


func get_upcoming_report_rows(limit: int = 8) -> Array:
	if limit > 0 and limit <= DASHBOARD_REPORT_ROW_CACHE_LIMIT:
		var rows: Array = get_dashboard_event_snapshot().get("upcoming_report_rows", []).duplicate(true)
		if rows.size() > limit:
			rows = rows.slice(0, limit)
		return rows
	return RunState.get_upcoming_quarterly_reports(limit)


func get_dashboard_event_snapshot(force_refresh: bool = false) -> Dictionary:
	if not RunState.has_active_run():
		return _empty_dashboard_event_snapshot()
	var cache_key: String = _dashboard_event_snapshot_cache_key()
	if (
		force_refresh or
		dashboard_event_snapshot_cache.is_empty() or
		str(dashboard_event_snapshot_cache.get("cache_key", "")) != cache_key
	):
		_rebuild_dashboard_event_snapshot_cache(cache_key)
	return dashboard_event_snapshot_cache.duplicate(true)


func get_corporate_meeting_snapshot(day_index: int = -1) -> Dictionary:
	if not RunState.has_active_run():
		return {"day_index": 0, "trade_date": {}, "today_rows": [], "upcoming_rows": [], "all_rows": []}
	if day_index <= 0 or day_index == RunState.day_index:
		return get_dashboard_event_snapshot().get("corporate_meeting_snapshot", {}).duplicate(true)
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	return corporate_action_system.get_meeting_snapshot(RunState, day_index)


func _rebuild_dashboard_event_snapshot_cache(cache_key: String = "", log_phase_details: bool = false) -> Dictionary:
	if not RunState.has_active_run():
		dashboard_event_snapshot_cache = _empty_dashboard_event_snapshot()
		return dashboard_event_snapshot_cache
	var phase_started_at_usec: int = Time.get_ticks_usec()
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	_log_advance_perf_elapsed(log_phase_details, "build_dashboard_event_cache:ensure_corporate_actions", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var trade_date: Dictionary = RunState.get_current_trade_date()
	var report_calendar_snapshot: Dictionary = RunState.get_report_calendar_month(
		int(trade_date.get("year", 2020)),
		int(trade_date.get("month", 1))
	)
	_log_advance_perf_elapsed(log_phase_details, "build_dashboard_event_cache:report_calendar", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var meeting_snapshot: Dictionary = corporate_action_system.get_meeting_snapshot(RunState)
	_log_advance_perf_elapsed(log_phase_details, "build_dashboard_event_cache:meeting_snapshot", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var upcoming_report_rows: Array = RunState.get_upcoming_quarterly_reports(DASHBOARD_REPORT_ROW_CACHE_LIMIT)
	_log_advance_perf_elapsed(log_phase_details, "build_dashboard_event_cache:upcoming_reports", phase_started_at_usec)
	var resolved_cache_key: String = cache_key if not cache_key.is_empty() else _dashboard_event_snapshot_cache_key()
	dashboard_event_snapshot_cache = {
		"cache_key": resolved_cache_key,
		"day_index": RunState.day_index,
		"trade_date": trade_date,
		"report_calendar_snapshot": report_calendar_snapshot,
		"upcoming_report_rows": upcoming_report_rows,
		"corporate_meeting_snapshot": meeting_snapshot,
		"upcoming_meeting_rows": meeting_snapshot.get("upcoming_rows", []).duplicate(true)
	}
	return dashboard_event_snapshot_cache


func _invalidate_dashboard_event_snapshot_cache() -> void:
	dashboard_event_snapshot_cache = {}


func _empty_dashboard_event_snapshot() -> Dictionary:
	return {
		"cache_key": "",
		"day_index": RunState.day_index if RunState.has_active_run() else 0,
		"trade_date": RunState.get_current_trade_date() if RunState.has_active_run() else {},
		"report_calendar_snapshot": {},
		"upcoming_report_rows": [],
		"corporate_meeting_snapshot": {
			"day_index": RunState.day_index if RunState.has_active_run() else 0,
			"trade_date": RunState.get_current_trade_date() if RunState.has_active_run() else {},
			"today_rows": [],
			"upcoming_rows": [],
			"all_rows": []
		},
		"upcoming_meeting_rows": []
	}


func _is_current_report_calendar_month(year_value: int, month_value: int) -> bool:
	if not RunState.has_active_run():
		return false
	var trade_date: Dictionary = RunState.get_current_trade_date()
	return int(trade_date.get("year", 2020)) == year_value and int(trade_date.get("month", 1)) == month_value


func _dashboard_event_snapshot_cache_key() -> String:
	if not RunState.has_active_run():
		return ""
	var trade_date: Dictionary = RunState.get_current_trade_date()
	var holding_parts: Array = []
	var holdings: Dictionary = RunState.player_portfolio.get("holdings", {})
	for company_id_value in holdings.keys():
		var company_id: String = str(company_id_value)
		var holding: Dictionary = holdings.get(company_id, {})
		holding_parts.append("%s:%d" % [company_id, int(holding.get("shares", 0))])
	holding_parts.sort()
	var attended_parts: Array = []
	for meeting_id_value in RunState.attended_meetings.keys():
		var meeting_id: String = str(meeting_id_value)
		var attended_row: Dictionary = RunState.attended_meetings.get(meeting_id, {})
		if bool(attended_row.get("attended", false)):
			attended_parts.append("%s:%d" % [meeting_id, int(attended_row.get("day_index", 0))])
	attended_parts.sort()
	var meeting_parts: Array = []
	for date_key_value in RunState.corporate_meeting_calendar.keys():
		var date_key: String = str(date_key_value)
		for meeting_value in RunState.corporate_meeting_calendar.get(date_key, []):
			var meeting: Dictionary = meeting_value
			meeting_parts.append("%s:%s:%d" % [
				str(meeting.get("id", "")),
				str(meeting.get("status", "")),
				int(meeting.get("trading_day_number", 0))
			])
	meeting_parts.sort()
	return "%d|%s|%s|%s|%s" % [
		RunState.day_index,
		trading_calendar.to_key(trade_date),
		str(hash("|".join(holding_parts))),
		str(hash("|".join(attended_parts))),
		str(hash("|".join(meeting_parts)))
	]


func get_corporate_meeting_detail(meeting_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	return corporate_action_system.get_meeting_detail(RunState, meeting_id)


func get_company_corporate_action_snapshot(company_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	return corporate_action_system.get_company_snapshot(RunState, company_id)


func attend_corporate_meeting(meeting_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.attend_meeting(RunState, meeting_id)
	if bool(result.get("success", false)):
		_invalidate_dashboard_event_snapshot_cache()
		_request_autosave("corporate_meeting_attend")
		network_changed.emit()
	return result


func start_corporate_meeting_session(meeting_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.start_meeting_session(RunState, DataRepository, meeting_id)
	if bool(result.get("success", false)):
		_invalidate_dashboard_event_snapshot_cache()
		_request_autosave("corporate_meeting_session_start")
		network_changed.emit()
	return result


func get_corporate_meeting_session_snapshot(meeting_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	return corporate_action_system.get_meeting_session_snapshot(RunState, DataRepository, meeting_id)


func set_corporate_meeting_session_stage(meeting_id: String, stage_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.set_meeting_session_stage(RunState, DataRepository, meeting_id, stage_id)
	if bool(result.get("success", false)):
		_request_autosave("corporate_meeting_session_stage")
	return result


func submit_corporate_meeting_vote(meeting_id: String, agenda_id: String, vote_choice: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var detail: Dictionary = corporate_action_system.get_meeting_detail(RunState, meeting_id)
	if detail.is_empty():
		return {"success": false, "message": "Meeting not found."}
	var ownership_snapshot: Dictionary = get_company_ownership_snapshot(str(detail.get("company_id", "")))
	var result: Dictionary = corporate_action_system.submit_meeting_vote(
		RunState,
		DataRepository,
		meeting_id,
		agenda_id,
		vote_choice,
		ownership_snapshot
	)
	if bool(result.get("success", false)):
		_invalidate_dashboard_event_snapshot_cache()
		_request_autosave("corporate_meeting_vote")
		network_changed.emit()
	return result


func close_corporate_meeting_session(meeting_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.close_meeting_session(RunState, meeting_id)
	if bool(result.get("success", false)):
		_request_autosave("corporate_meeting_session_close")
	return result


func get_company_ownership_snapshot(company_id: String) -> Dictionary:
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	var holding: Dictionary = RunState.get_holding(company_id)
	if definition.is_empty():
		return {}

	var financials: Dictionary = definition.get("financials", {})
	var shares_outstanding: float = max(
		float(definition.get("shares_outstanding", financials.get("shares_outstanding", 0.0))),
		0.0
	)
	var shares_owned: int = int(holding.get("shares", 0))
	var ownership_pct: float = 0.0
	if shares_outstanding > 0.0:
		ownership_pct = clamp(float(shares_owned) / shares_outstanding, 0.0, 1.0)

	var free_float_pct: float = clamp(float(financials.get("free_float_pct", 0.0)) / 100.0, 0.0, 1.0)
	var owner_concentration_pct: float = clamp(1.0 - free_float_pct, 0.0, 1.0)
	var player_public_float_pct: float = min(ownership_pct, free_float_pct)
	var player_control_block_pct: float = max(ownership_pct - player_public_float_pct, 0.0)
	var public_float_pct: float = max(free_float_pct - player_public_float_pct, 0.0)
	var remaining_control_pct: float = max(owner_concentration_pct - player_control_block_pct, 0.0)
	var shareholder_rows: Array = []
	if remaining_control_pct > 0.0:
		shareholder_rows.append({
			"name": "Controlling Group",
			"ownership_pct": remaining_control_pct,
			"role": "Founder / strategic holder"
		})
	if ownership_pct >= PLAYER_MAJOR_SHAREHOLDER_THRESHOLD:
		shareholder_rows.append({
			"name": "Player",
			"ownership_pct": ownership_pct,
			"role": "Major shareholder"
		})
	if public_float_pct > 0.0:
		shareholder_rows.append({
			"name": "Public Float",
			"ownership_pct": public_float_pct,
			"role": "Market holders"
		})
	shareholder_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("ownership_pct", 0.0)) > float(b.get("ownership_pct", 0.0))
	)
	return {
		"company_id": company_id,
		"shares_owned": shares_owned,
		"shares_outstanding": shares_outstanding,
		"ownership_pct": ownership_pct,
		"player_pct": ownership_pct,
		"controller_pct": remaining_control_pct,
		"public_pct": public_float_pct,
		"is_major_shareholder": ownership_pct >= PLAYER_MAJOR_SHAREHOLDER_THRESHOLD,
		"major_shareholder_threshold": PLAYER_MAJOR_SHAREHOLDER_THRESHOLD,
		"shareholder_rows": shareholder_rows
	}


func get_company_snapshot(
	company_id: String,
	include_price_history: bool = false,
	include_financial_history: bool = false,
	include_statement_history: bool = false
) -> Dictionary:
	var definition: Dictionary = RunState.get_effective_company_definition(
		company_id,
		include_financial_history,
		include_statement_history
	)
	var runtime: Dictionary = RunState.get_company(company_id)
	if definition.is_empty() or runtime.is_empty():
		return {}

	var sector_definition: Dictionary = DataRepository.get_sector_definition(str(definition.get("sector_id", "")))
	var holding: Dictionary = RunState.get_holding(company_id)
	var previous_close: float = RunState.get_previous_close(company_id)
	var current_price: float = float(runtime.get("current_price", 0.0))
	var listing_board: String = str(definition.get("listing_board", "main"))
	var ar_limits: Dictionary = runtime.get("ar_limits", IDX_PRICE_RULES.auto_rejection_limits(previous_close, listing_board))
	var daily_change_pct: float = 0.0
	if not is_zero_approx(previous_close):
		daily_change_pct = (current_price - previous_close) / previous_close

	var shares_owned: int = int(holding.get("shares", 0))
	var lot_size: int = get_lot_size()
	var average_price: float = float(holding.get("average_price", 0.0))
	var financials: Dictionary = definition.get("financials", {}).duplicate(true)
	var ownership_snapshot: Dictionary = get_company_ownership_snapshot(company_id)
	var financial_history: Array = []
	if include_financial_history:
		financial_history = definition.get("financial_history", []).duplicate(true)
	var starting_price: float = float(runtime.get("starting_price", current_price))
	var ytd_open_price: float = float(runtime.get("ytd_open_price", starting_price))
	var since_start_pct: float = 0.0
	var ytd_change_pct: float = 0.0
	if not is_zero_approx(starting_price):
		since_start_pct = (current_price - starting_price) / starting_price
	if not is_zero_approx(ytd_open_price):
		ytd_change_pct = (current_price - ytd_open_price) / ytd_open_price
	var broker_flow_view: Dictionary = _build_broker_flow_view(
		runtime.get("broker_flow", {}),
		include_price_history or include_financial_history or include_statement_history
	)
	var market_depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	var player_market_impact: Dictionary = runtime.get("player_market_impact", {}).duplicate(true)
	var shareholder_rows: Array = ownership_snapshot.get("shareholder_rows", [])
	var snapshot: Dictionary = {
		"id": company_id,
		"detail_status": str(definition.get("detail_status", "ready")),
		"ticker": definition.get("ticker", company_id.to_upper()),
		"name": definition.get("name", ""),
		"sector_id": str(definition.get("sector_id", "")),
		"sector_name": sector_definition.get("name", "Unknown"),
		"archetype_id": str(definition.get("archetype_id", "")),
		"archetype_label": str(definition.get("archetype_label", "")),
		"company_size_id": int(definition.get("company_size_id", 0)),
		"company_size_label": str(definition.get("company_size_label", "")),
		"company_age": int(definition.get("company_age", 0)),
		"founded_year": int(definition.get("founded_year", 0)),
		"employee_count": int(definition.get("employee_count", 0)),
		"profile_revenue": float(definition.get("profile_revenue", 0.0)),
		"profile_revenue_value": float(definition.get("profile_revenue_value", 0.0)),
		"profile_revenue_unit": str(definition.get("profile_revenue_unit", "")),
		"profile_description": str(definition.get("profile_description", "")),
		"profile_tags": definition.get("profile_tags", []).duplicate(),
		"management_roster": definition.get("management_roster", []).duplicate(true),
		"current_price": current_price,
		"previous_close": previous_close,
		"daily_change_pct": daily_change_pct,
		"quality_score": int(definition.get("quality_score", 0)),
		"growth_score": int(definition.get("growth_score", 0)),
		"risk_score": int(definition.get("risk_score", 0)),
		"financials": financials,
		"financial_history": financial_history,
		"financial_statement_snapshot": definition.get("financial_statement_snapshot", {}).duplicate(true),
		"narrative_tags": definition.get("narrative_tags", []).duplicate(),
		"sentiment": float(runtime.get("sentiment", 0.0)),
		"event_tags": runtime.get("active_event_tags", []).duplicate(),
		"active_events": runtime.get("active_events", []).duplicate(true),
		"starting_price": starting_price,
		"ytd_open_price": ytd_open_price,
		"ytd_reference_year": int(runtime.get("ytd_reference_year", int(RunState.get_current_trade_date().get("year", 2020)))),
		"since_start_pct": since_start_pct,
		"ytd_change_pct": ytd_change_pct,
		"broker_flow": broker_flow_view,
		"market_depth_context": market_depth_context,
		"player_market_impact": player_market_impact,
		"player_market_impact_summary": str(player_market_impact.get("impact_summary", "")),
		"hidden_story_flags": runtime.get("hidden_story_flags", []).duplicate(),
		"listing_board": listing_board,
		"shares_owned": shares_owned,
		"lots_owned": int(floor(float(shares_owned) / float(lot_size))),
		"odd_lot_remainder": int(posmod(shares_owned, lot_size)),
		"tick_size": get_tick_size_for_price(current_price),
		"ara_price": float(ar_limits.get("upper_price", current_price)),
		"arb_price": float(ar_limits.get("lower_price", current_price)),
		"ara_label": str(ar_limits.get("upper_label", "")),
		"arb_label": str(ar_limits.get("lower_label", "")),
		"average_price": average_price,
		"market_value": shares_owned * current_price,
		"unrealized_pnl": (current_price - average_price) * shares_owned,
		"ownership_pct": float(ownership_snapshot.get("ownership_pct", 0.0)),
		"is_major_shareholder": bool(ownership_snapshot.get("is_major_shareholder", false)),
		"shareholder_rows": shareholder_rows.duplicate(true),
		"shares_outstanding": float(ownership_snapshot.get("shares_outstanding", 0.0))
	}

	if include_price_history:
		snapshot["price_history"] = runtime.get("price_history", []).duplicate()
		snapshot["price_bars"] = runtime.get("price_bars", []).duplicate(true)

	return snapshot


func get_company_market_depth_snapshot(company_id: String) -> Dictionary:
	var runtime: Dictionary = RunState.get_company(company_id)
	if runtime.is_empty():
		return {}

	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	var depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	if depth_context.is_empty():
		var current_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
		var financials: Dictionary = definition.get("financials", {})
		var market_cap: float = max(float(financials.get("market_cap", current_price * 1000000000.0)), current_price * 1000000.0)
		var shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", market_cap / current_price))), 1.0)
		var free_float_ratio: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, 0.07, 0.85)
		depth_context = {
			"current_price": current_price,
			"market_cap": market_cap,
			"shares_outstanding": shares_outstanding,
			"free_float_ratio": free_float_ratio,
			"free_float_shares": shares_outstanding * free_float_ratio,
			"avg_daily_value": max(float(financials.get("avg_daily_value", current_price * 250000.0)), current_price * 1000.0),
			"ask_depth_value": 0.0,
			"bid_depth_value": 0.0,
			"synthetic_daily_value": 0.0
		}
	return depth_context


func get_player_market_impact_snapshot(company_id: String) -> Dictionary:
	var runtime: Dictionary = RunState.get_company(company_id)
	if runtime.is_empty():
		return {}
	var impact: Dictionary = runtime.get("player_market_impact", {}).duplicate(true)
	if impact.is_empty():
		impact = RunState.get_player_market_flow_context(company_id, RunState.day_index + 1)
		impact["impact_summary"] = ""
		impact["limit_lock"] = ""
		impact["limit_source"] = ""
	return impact


func _build_broker_flow_view(broker_flow: Dictionary, include_rows: bool) -> Dictionary:
	if broker_flow.is_empty():
		return {}

	var broker_flow_view: Dictionary = broker_flow.duplicate(true)
	if not include_rows:
		broker_flow_view.erase("buy_brokers")
		broker_flow_view.erase("sell_brokers")
		broker_flow_view.erase("net_buy_brokers")
		broker_flow_view.erase("net_sell_brokers")
	return broker_flow_view


func get_company_chart_snapshot(company_id: String, range_id: String = "1m", enabled_indicator_ids: Array = []) -> Dictionary:
	var chart_bars: Array = RunState.get_company_chart_bars(company_id)
	if chart_bars.is_empty():
		return {}
	return chart_system.build_chart_snapshot_from_bars(chart_bars, range_id, enabled_indicator_ids)


func get_portfolio_snapshot() -> Dictionary:
	var holdings_rows: Array = []
	var invested_cost_total: float = 0.0
	var unrealized_pnl_total: float = 0.0
	for company_id in RunState.player_portfolio.get("holdings", {}).keys():
		var snapshot: Dictionary = get_company_snapshot(str(company_id), false)
		var holding: Dictionary = RunState.get_holding(str(company_id))
		var shares: int = int(holding.get("shares", 0))
		var invested_cost: float = float(holding.get("average_price", 0.0)) * float(shares)
		var unrealized_pnl: float = float(snapshot.get("unrealized_pnl", 0.0))
		var pnl_pct: float = 0.0
		if invested_cost > 0.0:
			pnl_pct = unrealized_pnl / invested_cost

		invested_cost_total += invested_cost
		unrealized_pnl_total += unrealized_pnl
		holdings_rows.append({
			"company_id": company_id,
			"ticker": snapshot.get("ticker", str(company_id).to_upper()),
			"shares": shares,
			"lots": int(floor(float(shares) / float(get_lot_size()))),
			"average_price": float(holding.get("average_price", 0.0)),
			"current_price": float(snapshot.get("current_price", 0.0)),
			"invested_cost": invested_cost,
			"market_value": float(snapshot.get("market_value", 0.0)),
			"unrealized_pnl": unrealized_pnl,
			"unrealized_pnl_pct": pnl_pct
		})

	holdings_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("ticker", "")) < str(b.get("ticker", ""))
	)

	var unrealized_pnl_pct_total: float = 0.0
	if invested_cost_total > 0.0:
		unrealized_pnl_pct_total = unrealized_pnl_total / invested_cost_total

	return {
		"cash": float(RunState.player_portfolio.get("cash", 0.0)),
		"realized_pnl": float(RunState.player_portfolio.get("realized_pnl", 0.0)),
		"invested_cost": invested_cost_total,
		"market_value": RunState.get_portfolio_market_value(),
		"unrealized_pnl": unrealized_pnl_total,
		"unrealized_pnl_pct": unrealized_pnl_pct_total,
		"equity": RunState.get_total_equity(),
		"holdings": holdings_rows
	}


func get_sector_rows() -> Array:
	var grouped_rows: Dictionary = {}
	var ordered_rows: Array = []

	for company_id in RunState.company_order:
		var snapshot: Dictionary = get_company_snapshot(str(company_id), false)
		var sector_id: String = str(snapshot.get("sector_id", ""))
		if sector_id.is_empty():
			continue

		var sector_definition: Dictionary = DataRepository.get_sector_definition(sector_id)
		if not grouped_rows.has(sector_id):
			grouped_rows[sector_id] = {
				"id": sector_id,
				"name": str(sector_definition.get("name", sector_id.capitalize())),
				"trend_bias": float(sector_definition.get("trend_bias", 0.0)),
				"volatility_bias": float(sector_definition.get("volatility_bias", 0.0)),
				"company_count": 0,
				"advancers": 0,
				"decliners": 0,
				"change_sum": 0.0,
				"strongest_ticker": "",
				"strongest_change_pct": 0.0,
				"strongest_flow_tag": "neutral",
				"strongest_flow_pressure": -1.0
			}

		var sector_row: Dictionary = grouped_rows[sector_id]
		var daily_change_pct: float = float(snapshot.get("daily_change_pct", 0.0))
		var broker_flow: Dictionary = snapshot.get("broker_flow", {})
		var pressure_value: float = abs(float(broker_flow.get("net_pressure", 0.0)))

		sector_row["company_count"] = int(sector_row.get("company_count", 0)) + 1
		sector_row["change_sum"] = float(sector_row.get("change_sum", 0.0)) + daily_change_pct
		if daily_change_pct > 0.0:
			sector_row["advancers"] = int(sector_row.get("advancers", 0)) + 1
		elif daily_change_pct < 0.0:
			sector_row["decliners"] = int(sector_row.get("decliners", 0)) + 1

		if pressure_value > float(sector_row.get("strongest_flow_pressure", -1.0)):
			sector_row["strongest_ticker"] = str(snapshot.get("ticker", ""))
			sector_row["strongest_change_pct"] = daily_change_pct
			sector_row["strongest_flow_tag"] = str(broker_flow.get("flow_tag", "neutral"))
			sector_row["strongest_flow_pressure"] = pressure_value

		grouped_rows[sector_id] = sector_row

	for sector_definition_value in DataRepository.get_sector_definitions():
		var sector_definition: Dictionary = sector_definition_value
		var sector_id: String = str(sector_definition.get("id", ""))
		if not grouped_rows.has(sector_id):
			continue

		var grouped_row: Dictionary = grouped_rows[sector_id].duplicate(true)
		var company_count: int = int(grouped_row.get("company_count", 0))
		var average_change_pct: float = 0.0
		if company_count > 0:
			average_change_pct = float(grouped_row.get("change_sum", 0.0)) / float(company_count)

		grouped_row["average_change_pct"] = average_change_pct
		ordered_rows.append(grouped_row)

	return ordered_rows


func get_latest_summary() -> Dictionary:
	return RunState.daily_summary.duplicate(true)


func get_daily_activity_snapshot(force_refresh: bool = false) -> Dictionary:
	if not RunState.has_active_run():
		return _empty_daily_activity_snapshot()
	var cache_key: String = _daily_activity_snapshot_cache_key()
	if (
		force_refresh or
		daily_activity_snapshot_cache.is_empty() or
		str(daily_activity_snapshot_cache.get("cache_key", "")) != cache_key
	):
		_rebuild_daily_activity_snapshot_cache({}, cache_key)
	return daily_activity_snapshot_cache.duplicate(true)


func get_daily_recap_snapshot() -> Dictionary:
	if not RunState.has_active_run():
		return {}
	var summary: Dictionary = get_latest_summary()
	var dashboard_event_snapshot: Dictionary = get_dashboard_event_snapshot()
	var daily_activity_snapshot: Dictionary = get_daily_activity_snapshot()
	var activity_counts: Dictionary = daily_activity_snapshot.get("activity_counts", {}).duplicate(true)
	return {
		"day_index": RunState.day_index,
		"trade_date": get_current_trade_date(),
		"summary": summary,
		"market_sentiment": RunState.market_sentiment,
		"portfolio": get_portfolio_snapshot(),
		"dashboard_events": dashboard_event_snapshot,
		"activity_counts": activity_counts,
		"badges": get_desktop_app_badge_snapshot(activity_counts),
		"daily_action": get_daily_action_snapshot()
	}


func get_desktop_app_badge_snapshot(activity_counts: Dictionary = {}) -> Dictionary:
	if not RunState.has_active_run():
		return {}
	var resolved_counts: Dictionary = activity_counts
	var badge_day_index: int = RunState.day_index
	if resolved_counts.is_empty():
		var cached_badges: Dictionary = RunState.get_desktop_app_badge_counts()
		resolved_counts = cached_badges.get("counts", {})
		badge_day_index = int(cached_badges.get("day_index", RunState.day_index))
	var rows: Dictionary = {}
	for app_id in ["news", "social", "network"]:
		var count: int = max(int(resolved_counts.get(app_id, 0)), 0)
		var seen_day: int = RunState.get_desktop_app_seen_day(app_id)
		var visible: bool = count > 0 and badge_day_index == RunState.day_index and seen_day < badge_day_index
		rows[app_id] = {
			"visible": visible,
			"count": count,
			"label": str(min(count, 9)) if count > 0 and count < 10 else ("9+" if count >= 10 else "!"),
			"day_index": badge_day_index,
			"seen_day_index": seen_day
		}
	return rows


func _rebuild_daily_activity_snapshot_cache(news_snapshot: Dictionary = {}, cache_key: String = "", log_phase_details: bool = false) -> Dictionary:
	if not RunState.has_active_run():
		daily_activity_snapshot_cache = _empty_daily_activity_snapshot()
		return daily_activity_snapshot_cache
	var phase_started_at_usec: int = Time.get_ticks_usec()
	var resolved_news_snapshot: Dictionary = news_snapshot
	if resolved_news_snapshot.is_empty():
		resolved_news_snapshot = _build_news_snapshot()
	_log_advance_perf_elapsed(log_phase_details, "build_daily_activity_cache:resolve_news", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var social_snapshot: Dictionary = get_twooter_snapshot()
	_log_advance_perf_elapsed(log_phase_details, "build_daily_activity_cache:social_snapshot", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var network_activity_count: int = contact_network_system.count_current_day_activity(RunState)
	_log_advance_perf_elapsed(log_phase_details, "build_daily_activity_cache:network_count", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var activity_counts: Dictionary = {
		"news": _count_news_articles(resolved_news_snapshot),
		"social": social_snapshot.get("posts", []).size(),
		"network": network_activity_count,
	}
	_log_advance_perf_elapsed(log_phase_details, "build_daily_activity_cache:count_activity", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	RunState.set_desktop_app_badge_counts(activity_counts)
	_log_advance_perf_elapsed(log_phase_details, "build_daily_activity_cache:set_badges", phase_started_at_usec)
	var resolved_cache_key: String = cache_key if not cache_key.is_empty() else _daily_activity_snapshot_cache_key()
	daily_activity_snapshot_cache = {
		"cache_key": resolved_cache_key,
		"day_index": RunState.day_index,
		"trade_date": RunState.get_current_trade_date(),
		"activity_counts": activity_counts,
		"badge_counts": RunState.get_desktop_app_badge_counts()
	}
	return daily_activity_snapshot_cache


func _invalidate_daily_activity_snapshot_cache() -> void:
	daily_activity_snapshot_cache = {}


func _empty_daily_activity_snapshot() -> Dictionary:
	return {
		"cache_key": "",
		"day_index": RunState.day_index if RunState.has_active_run() else 0,
		"trade_date": RunState.get_current_trade_date() if RunState.has_active_run() else {},
		"activity_counts": {
			"news": 0,
			"social": 0,
			"network": 0
		},
		"badge_counts": RunState.get_desktop_app_badge_counts() if RunState.has_active_run() else {
			"day_index": 0,
			"counts": {
				"news": 0,
				"social": 0,
				"network": 0
			}
		}
	}


func _daily_activity_snapshot_cache_key() -> String:
	if not RunState.has_active_run():
		return ""
	var trade_date: Dictionary = RunState.get_current_trade_date()
	return "%d|%s|news:%d|social:%d|events:%d|tips:%d|requests:%d|discoveries:%d|contacts:%d" % [
		RunState.day_index,
		trading_calendar.to_key(trade_date),
		get_unlocked_news_intel_level(),
		get_unlocked_twooter_access_tier(),
		RunState.event_history.size(),
		RunState.network_tip_journal.size(),
		RunState.network_requests.size(),
		RunState.network_discoveries.size(),
		RunState.network_contacts.size()
	]


func mark_desktop_app_seen(app_id: String) -> void:
	if RunState.get_desktop_app_seen_day(app_id) >= RunState.day_index:
		return
	RunState.mark_desktop_app_seen(app_id)
	_request_autosave("desktop_app_seen")


func _count_news_articles(news_snapshot: Dictionary) -> int:
	var seen_article_ids: Dictionary = {}
	var outlet_lookup: Dictionary = {}
	for outlet_value in news_snapshot.get("outlets", []):
		var outlet: Dictionary = outlet_value
		outlet_lookup[str(outlet.get("id", ""))] = bool(outlet.get("unlocked", true))
	for feed_value in news_snapshot.get("feeds", {}).values():
		var feed: Dictionary = feed_value
		var outlet_id: String = str(feed.get("outlet_id", ""))
		if not bool(outlet_lookup.get(outlet_id, true)):
			continue
		for article_value in feed.get("articles", []):
			var article: Dictionary = article_value
			var article_id: String = str(article.get("id", article.get("headline", "")))
			if article_id.is_empty() or seen_article_ids.has(article_id):
				continue
			seen_article_ids[article_id] = true
	return seen_article_ids.size()


func _count_network_current_day_activity(network_snapshot: Dictionary) -> int:
	var count: int = 0
	for row_value in network_snapshot.get("journal", []):
		var row: Dictionary = row_value
		if int(row.get("day_index", -9999)) == RunState.day_index:
			count += 1
	return count


func get_trade_history() -> Array:
	var rows: Array = []
	var raw_history: Array = RunState.get_trade_history()

	for index in range(raw_history.size() - 1, -1, -1):
		var entry: Dictionary = raw_history[index]
		var company_id: String = str(entry.get("company_id", ""))
		var definition: Dictionary = RunState.get_effective_company_definition(company_id)
		rows.append({
			"day_index": int(entry.get("day_index", 0)),
			"company_id": company_id,
			"ticker": str(definition.get("ticker", company_id.to_upper())),
			"side": str(entry.get("side", "")),
			"lots": int(entry.get("lots", 0)),
			"shares": int(entry.get("shares", 0)),
			"price_per_share": float(entry.get("price_per_share", 0.0)),
			"gross_value": float(entry.get("gross_value", 0.0)),
			"fee_rate": float(entry.get("fee_rate", 0.0)),
			"fee": float(entry.get("fee", 0.0)),
			"net_cash_impact": float(entry.get("net_cash_impact", 0.0)),
			"cash_after": float(entry.get("cash_after", 0.0)),
			"realized_pnl": float(entry.get("realized_pnl", 0.0))
		})

	return rows


func get_event_history() -> Array:
	return RunState.get_event_history()


func get_market_history() -> Array:
	return RunState.get_market_history()


func get_active_company_arcs() -> Array:
	return RunState.get_active_company_arcs()


func get_active_special_events() -> Array:
	return RunState.get_active_special_events()


func get_network_snapshot() -> Dictionary:
	if not RunState.has_active_run():
		return {
			"recognition": {"score": 0.0, "label": "Unknown", "contact_cap": 2},
			"contacts": [],
			"discoveries": [],
			"requests": [],
			"met_count": 0,
			"contact_cap": 2
		}
	return contact_network_system.build_snapshot(RunState, DataRepository)


func discover_network_contacts_from_article(article: Dictionary) -> Array:
	if not RunState.has_active_run() or article.is_empty():
		return []
	var discovered: Array = contact_network_system.discover_from_article(RunState, DataRepository, article)
	if not discovered.is_empty():
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("discover_network_from_article")
	return discovered


func discover_network_contacts_for_company(company_id: String) -> Array:
	if not RunState.has_active_run() or company_id.is_empty():
		return []
	var discovered: Array = contact_network_system.discover_for_company(RunState, DataRepository, company_id)
	if not discovered.is_empty():
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("discover_network_for_company")
	return discovered


func meet_contact(contact_id: String, source_context: Dictionary = {}) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if not _can_spend_network_action("meet"):
		return {"success": false, "message": _network_action_no_ap_message("meet")}
	var result: Dictionary = contact_network_system.meet_contact(RunState, DataRepository, contact_id, source_context)
	if bool(result.get("success", false)):
		_spend_network_action("meet")
		result["action_cost"] = get_network_action_cost("meet")
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("network_meet")
		daily_actions_changed.emit()
		network_changed.emit()
	return result


func request_contact_tip(contact_id: String, company_id: String = "") -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if not _can_spend_network_action("tip"):
		return {"success": false, "message": _network_action_no_ap_message("tip")}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = contact_network_system.request_tip(RunState, DataRepository, corporate_action_system, contact_id, company_id)
	if bool(result.get("success", false)):
		_spend_network_action("tip")
		result["action_cost"] = get_network_action_cost("tip")
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("network_tip")
		daily_actions_changed.emit()
		network_changed.emit()
	return result


func accept_contact_request(contact_id: String, company_id: String = "") -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if not _can_spend_network_action("request"):
		return {"success": false, "message": _network_action_no_ap_message("request")}
	var result: Dictionary = contact_network_system.accept_request(RunState, DataRepository, contact_id, company_id)
	if bool(result.get("success", false)):
		_spend_network_action("request")
		result["action_cost"] = get_network_action_cost("request")
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("network_request")
		daily_actions_changed.emit()
		network_changed.emit()
	return result


func request_contact_referral(contact_id: String, company_id: String = "", affiliation_role: String = "") -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if not _can_spend_network_action("referral"):
		return {"success": false, "message": _network_action_no_ap_message("referral")}
	var result: Dictionary = contact_network_system.request_referral(RunState, DataRepository, contact_id, company_id, affiliation_role)
	if bool(result.get("success", false)):
		_spend_network_action("referral")
		result["action_cost"] = get_network_action_cost("referral")
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("network_referral")
		daily_actions_changed.emit()
		network_changed.emit()
	return result


func follow_up_contact_tip(contact_id: String, followup_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if not _can_spend_network_action("followup"):
		return {"success": false, "message": _network_action_no_ap_message("followup")}
	var result: Dictionary = contact_network_system.follow_up_tip(RunState, DataRepository, contact_id, followup_id)
	if bool(result.get("success", false)):
		_spend_network_action("followup")
		result["action_cost"] = get_network_action_cost("followup")
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("network_tip_followup")
		daily_actions_changed.emit()
		network_changed.emit()
	return result


func ask_contact_source_check(contact_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if not _can_spend_network_action("source_check"):
		return {"success": false, "message": _network_action_no_ap_message("source_check")}
	var result: Dictionary = contact_network_system.ask_source_check(RunState, DataRepository, contact_id)
	if bool(result.get("success", false)):
		_spend_network_action("source_check")
		result["action_cost"] = get_network_action_cost("source_check")
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("network_source_check")
		daily_actions_changed.emit()
		network_changed.emit()
	return result


func get_debug_event_generator_catalog() -> Array:
	var group_labels: Dictionary = {
		"market": "Market Events",
		"company": "Company Events",
		"company_arc": "Company Arcs",
		"person": "Person Events",
		"special": "Special Events"
	}
	var group_order: Array = ["market", "company", "company_arc", "person", "special"]
	var grouped_events: Dictionary = {}
	for group_id_value in group_order:
		grouped_events[str(group_id_value)] = []

	for event_definition_value in DataRepository.get_event_definitions():
		var event_definition: Dictionary = event_definition_value
		var event_id: String = str(event_definition.get("id", ""))
		if event_id.is_empty():
			continue

		var group_id: String = "company_arc" if DEBUG_COMPANY_ARC_EVENT_IDS.has(event_id) else str(event_definition.get("event_family", ""))
		if not grouped_events.has(group_id):
			continue

		grouped_events[group_id].append({
			"event_id": event_id,
			"description": str(event_definition.get("description", ""))
		})

	var catalog: Array = []
	for group_id_value in group_order:
		var group_id: String = str(group_id_value)
		var events: Array = grouped_events.get(group_id, [])
		events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return str(a.get("event_id", "")) < str(b.get("event_id", ""))
		)
		catalog.append({
			"id": group_id,
			"label": str(group_labels.get(group_id, group_id.capitalize())),
			"events": events
		})

	return catalog


func debug_generate_event(event_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run to modify."}

	var event_definition: Dictionary = DataRepository.get_event_definition(event_id)
	if event_definition.is_empty():
		return {"success": false, "message": "Unknown debug event id."}

	var trade_date: Dictionary = get_current_trade_date()
	var day_number: int = max(int(RunState.day_index), 1)
	var macro_state: Dictionary = get_current_macro_state()
	var generated_event: Dictionary = {}
	var event_family: String = str(event_definition.get("event_family", ""))

	if DEBUG_COMPANY_ARC_EVENT_IDS.has(event_id):
		var generated_arc: Dictionary = company_event_system.build_debug_company_arc(
			RunState,
			trade_date,
			day_number,
			macro_state,
			event_id
		)
		if generated_arc.is_empty():
			return {"success": false, "message": "Could not build that company arc right now."}

		var arc_start_event: Dictionary = company_event_system.build_arc_start_event(
			generated_arc,
			trade_date,
			day_number
		)
		RunState.debug_add_company_arc(generated_arc, arc_start_event)
		generated_event = arc_start_event
	elif event_family == "company":
		generated_event = company_event_system.build_debug_company_event(
			RunState,
			trade_date,
			day_number,
			macro_state,
			event_id
		)
		if generated_event.is_empty():
			return {"success": false, "message": "Could not find a company match for that event."}
		RunState.debug_add_recorded_event(generated_event)
	elif event_family == "person":
		generated_event = person_event_system.build_debug_person_event(
			RunState,
			trade_date,
			day_number,
			macro_state,
			_build_debug_sector_sentiments(),
			float(RunState.market_sentiment),
			event_id
		)
		if generated_event.is_empty():
			return {"success": false, "message": "Could not find a person-event target right now."}
		RunState.debug_add_recorded_event(generated_event)
	elif event_family == "special":
		generated_event = special_event_system.build_debug_special_event(
			RunState,
			trade_date,
			day_number,
			macro_state,
			event_id
		)
		if generated_event.is_empty():
			return {"success": false, "message": "Could not build that special event right now."}
		RunState.debug_add_special_event(generated_event)
	elif event_family == "market":
		generated_event = _build_debug_market_event(event_definition, trade_date)
		if generated_event.is_empty():
			return {"success": false, "message": "Could not build that market event right now."}
		RunState.debug_add_recorded_event(generated_event)
	else:
		return {"success": false, "message": "No debug generator is defined for that event family."}

	_invalidate_daily_activity_snapshot_cache()
	_request_autosave("debug_generate_event")
	return {
		"success": true,
		"message": _build_debug_generated_message(generated_event, event_definition),
		"event": generated_event
	}


func _build_news_snapshot(unlocked_intel_level: int = -1) -> Dictionary:
	if unlocked_intel_level < 1:
		unlocked_intel_level = get_unlocked_news_intel_level()
	if not RunState.has_active_run():
		return {
			"intel_level": max(unlocked_intel_level, 1),
			"outlets": [],
			"feeds": {}
		}

	var news_trade_date: Dictionary = get_current_trade_date()
	news_trade_date["day_index"] = RunState.day_index

	return news_feed_system.build_news_snapshot(
		RunState,
		DataRepository.get_news_feed_data(),
		get_company_rows(),
		get_market_history(),
		get_event_history(),
		get_active_special_events(),
		get_active_company_arcs(),
		news_trade_date,
		unlocked_intel_level
	)


func get_news_snapshot(unlocked_intel_level: int = -1) -> Dictionary:
	if unlocked_intel_level < 1:
		unlocked_intel_level = get_unlocked_news_intel_level()
	var snapshot: Dictionary = _build_news_snapshot(unlocked_intel_level)
	RunState.record_news_snapshot(snapshot)
	return snapshot


func get_news_archive_years(outlet_id: String) -> Array:
	return RunState.get_news_archive_years(outlet_id)


func get_news_archive_months(outlet_id: String, year: int) -> Array:
	return RunState.get_news_archive_months(outlet_id, year)


func get_news_archive_article_summaries(outlet_id: String, year: int, month: int) -> Array:
	return RunState.get_news_archive_article_summaries(outlet_id, year, month)


func get_news_archive_article(article_id: String) -> Dictionary:
	return RunState.get_news_archive_article(article_id)


func get_twooter_snapshot(unlocked_access_tier: int = -1) -> Dictionary:
	if unlocked_access_tier < 1:
		unlocked_access_tier = get_unlocked_twooter_access_tier()
	if not RunState.has_active_run():
		return {
			"access_tier": max(unlocked_access_tier, 1),
			"tier_label": "Tier 1",
			"accounts": [],
			"posts": []
		}

	var social_trade_date: Dictionary = get_current_trade_date()
	social_trade_date["day_index"] = RunState.day_index

	return twooter_feed_system.build_social_snapshot(
		RunState,
		DataRepository.get_twooter_feed_data(),
		get_company_rows(),
		get_market_history(),
		get_event_history(),
		get_active_special_events(),
		get_active_company_arcs(),
		social_trade_date,
		unlocked_access_tier
	)


func get_difficulty_options() -> Array:
	var options: Array = []

	for difficulty_id in DIFFICULTY_ORDER:
		options.append(get_difficulty_config(str(difficulty_id)))

	return options


func build_company_roster(run_seed: int, selected_difficulty_config: Dictionary) -> Array:
	var started_at_usec: int = Time.get_ticks_usec()
	var difficulty_config: Dictionary = selected_difficulty_config.duplicate(true)
	if difficulty_config.is_empty():
		difficulty_config = get_difficulty_config(DEFAULT_DIFFICULTY_ID)

	var company_count: int = int(difficulty_config.get("company_count", DataRepository.get_company_archetypes().size()))
	var generated_roster: Array = company_roster_generator.generate_roster(
		DataRepository.get_company_archetypes(),
		DataRepository.get_sector_definitions(),
		DataRepository.get_company_word_data(),
		run_seed,
		company_count
	)
	_log_startup_perf_elapsed("build_company_roster", started_at_usec, " companies=%d" % generated_roster.size())
	return generated_roster


func get_difficulty_config(difficulty_id: String) -> Dictionary:
	var normalized_id: String = difficulty_id.to_lower()
	if not DIFFICULTY_PRESETS.has(normalized_id):
		normalized_id = DEFAULT_DIFFICULTY_ID

	return DIFFICULTY_PRESETS[normalized_id].duplicate(true)


func get_current_difficulty_config() -> Dictionary:
	return RunState.get_difficulty_config()


func get_current_difficulty_label() -> String:
	var current_config: Dictionary = get_current_difficulty_config()
	if current_config.is_empty():
		current_config = get_difficulty_config(DEFAULT_DIFFICULTY_ID)

	return str(current_config.get("label", "Normal"))


func get_current_trade_date() -> Dictionary:
	return RunState.get_current_trade_date()


func get_current_macro_state() -> Dictionary:
	return RunState.get_current_macro_state()


func get_macro_state_history() -> Array:
	return RunState.get_macro_state_history()


func get_next_trade_date() -> Dictionary:
	return RunState.get_next_trade_date()


func format_trade_date(date_info: Dictionary) -> String:
	return trading_calendar.format_date(date_info)


func should_show_tutorial() -> bool:
	return RunState.should_show_tutorial()


func mark_tutorial_shown() -> void:
	RunState.mark_tutorial_shown()
	_request_autosave("tutorial_shown")


func get_lot_size() -> int:
	return int(RunState.LOT_SIZE)


func get_buy_fee_rate() -> float:
	return RunState.get_effective_buy_fee_rate()


func get_sell_fee_rate() -> float:
	return RunState.get_effective_sell_fee_rate()


func lots_to_shares(lots: int) -> int:
	return max(lots, 0) * get_lot_size()


func get_tick_size_for_price(price: float) -> float:
	return IDX_PRICE_RULES.tick_size_for_reference_price(price)


func get_chart_range_label(range_id: String) -> String:
	return chart_system.get_range_label(range_id)


func get_chart_indicator_catalog() -> Array:
	var unlocked_lookup: Dictionary = {}
	for indicator_id_value in get_unlocked_chart_indicator_ids():
		unlocked_lookup[str(indicator_id_value)] = true
	var catalog: Array = []
	for indicator_value in chart_system.get_indicator_catalog():
		var indicator: Dictionary = indicator_value
		var indicator_id: String = str(indicator.get("id", ""))
		indicator["unlocked"] = unlocked_lookup.has(indicator_id)
		catalog.append(indicator)
	return catalog


func _upgrade_track(track_id: String) -> Dictionary:
	for track_value in DataRepository.get_upgrade_catalog().get("tracks", []):
		if typeof(track_value) != TYPE_DICTIONARY:
			continue
		var track: Dictionary = track_value
		if str(track.get("id", "")) == track_id:
			return track.duplicate(true)
	return {}


func _upgrade_tier_data(track: Dictionary, tier: int) -> Dictionary:
	if track.is_empty() or tier < 1:
		return {}
	var tiers: Dictionary = track.get("tiers", {})
	return tiers.get(str(tier), {}).duplicate(true)


func _content_level_for_upgrade(track_id: String) -> int:
	var track: Dictionary = _upgrade_track(track_id)
	var tier_data: Dictionary = _upgrade_tier_data(track, RunState.get_upgrade_tier(track_id))
	if tier_data.has("content_level"):
		return int(tier_data.get("content_level", 1))
	return clamp(5 - RunState.get_upgrade_tier(track_id), 1, 4)


func _build_debug_sector_sentiments() -> Dictionary:
	var sector_sentiments: Dictionary = {}
	for sector_row_value in get_sector_rows():
		var sector_row: Dictionary = sector_row_value
		sector_sentiments[str(sector_row.get("id", ""))] = float(sector_row.get("average_change_pct", 0.0))

	if sector_sentiments.is_empty():
		for sector_definition_value in DataRepository.get_sector_definitions():
			var sector_definition: Dictionary = sector_definition_value
			sector_sentiments[str(sector_definition.get("id", ""))] = float(sector_definition.get("trend_bias", 0.0))

	return sector_sentiments


func _build_debug_market_event(event_definition: Dictionary, trade_date: Dictionary) -> Dictionary:
	var event_id: String = str(event_definition.get("id", ""))
	if event_id.is_empty():
		return {}

	var event_data: Dictionary = {
		"event_id": event_id,
		"scope": str(event_definition.get("scope", "market")),
		"event_family": str(event_definition.get("event_family", "market")),
		"category": str(event_definition.get("category", "market")),
		"tone": str(event_definition.get("tone", "mixed")),
		"duration_days": int(event_definition.get("duration_days", 1)),
		"trade_date": trade_date.duplicate(true),
		"sentiment_shift": float(event_definition.get("sentiment_shift", 0.0)),
		"description": str(event_definition.get("description", "")),
		"broker_bias": str(event_definition.get("broker_bias", "balanced"))
	}

	if str(event_definition.get("scope", "market")) == "market":
		event_data["headline"] = "Risk-off pressure hits the tape"
		event_data["headline_detail"] = "A manually injected market headline pushes traders into defense mode."
		return event_data

	var sector_sentiments: Dictionary = _build_debug_sector_sentiments()
	var target_sector_id: String = _pick_debug_market_sector(event_id, sector_sentiments)
	if target_sector_id.is_empty():
		return {}

	var sector_definition: Dictionary = DataRepository.get_sector_definition(target_sector_id)
	var sector_name: String = str(sector_definition.get("name", target_sector_id.capitalize()))
	event_data["target_sector_id"] = target_sector_id
	if event_id == "sector_tailwind":
		event_data["headline"] = "%s catches a sector tailwind" % sector_name
		event_data["headline_detail"] = "A fresh wave of buyers rotates into %s and keeps the tape constructive." % sector_name
	else:
		event_data["headline"] = "%s runs into a sector headwind" % sector_name
		event_data["headline_detail"] = "Sellers lean on %s as the sector tone rolls over." % sector_name

	return event_data


func _pick_debug_market_sector(event_id: String, sector_sentiments: Dictionary) -> String:
	var selected_sector_id: String = ""
	var selected_value: float = -INF if event_id == "sector_tailwind" else INF

	for sector_id_value in sector_sentiments.keys():
		var sector_id: String = str(sector_id_value)
		var sentiment_value: float = float(sector_sentiments.get(sector_id, 0.0))
		if event_id == "sector_tailwind":
			if sentiment_value > selected_value:
				selected_value = sentiment_value
				selected_sector_id = sector_id
		elif sentiment_value < selected_value:
			selected_value = sentiment_value
			selected_sector_id = sector_id

	if not selected_sector_id.is_empty():
		return selected_sector_id

	for sector_definition_value in DataRepository.get_sector_definitions():
		return str(sector_definition_value.get("id", ""))
	return ""


func _build_debug_generated_message(event_data: Dictionary, event_definition: Dictionary) -> String:
	var event_label: String = _format_debug_event_label(str(event_definition.get("id", "")))
	var target_ticker: String = str(event_data.get("target_ticker", ""))
	if not target_ticker.is_empty():
		return "%s generated for %s." % [event_label, target_ticker]

	var person_name: String = str(event_data.get("person_name", ""))
	if not person_name.is_empty():
		return "%s generated from %s." % [event_label, person_name]

	var target_sector_id: String = str(event_data.get("target_sector_id", ""))
	if not target_sector_id.is_empty():
		var sector_definition: Dictionary = DataRepository.get_sector_definition(target_sector_id)
		return "%s generated for %s." % [event_label, str(sector_definition.get("name", target_sector_id.capitalize()))]

	return "%s generated." % event_label


func _format_debug_event_label(event_id: String) -> String:
	var words: Array = event_id.split("_", false)
	for index in range(words.size()):
		words[index] = str(words[index]).capitalize()
	return " ".join(words)


func _emit_run_loading_step(step_index: int) -> void:
	_emit_loading_step_from_list(NEW_RUN_LOADING_STEPS, step_index)


func _on_new_run_financial_batch_progress(done_count: int, total_count: int) -> void:
	if total_count <= 0:
		_emit_run_loading_step_with_progress(2, 1.0)
		return
	_emit_run_loading_step_with_progress(2, float(done_count) / float(total_count))


func _on_new_run_financial_batch_detail(done_count: int, total_count: int, batch_company_ids: Array) -> void:
	var subprogress_text: String = "%d / %d companies prepared" % [done_count, max(total_count, 0)]
	for company_id_value in batch_company_ids:
		var company_id: String = str(company_id_value)
		if company_id.is_empty():
			continue
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		var ticker: String = str(definition.get("ticker", company_id.to_upper()))
		loading_detail_log_lines.append("Built core profile for %s" % ticker)
	while loading_detail_log_lines.size() > 3:
		loading_detail_log_lines.remove_at(0)
	_emit_run_loading_detail(subprogress_text, loading_detail_log_lines)


func _hold_loading_stage(duration_seconds: float) -> void:
	if duration_seconds <= 0.0:
		await get_tree().process_frame
		return

	await get_tree().create_timer(duration_seconds).timeout


func _emit_load_run_loading_step(step_index: int) -> void:
	_emit_loading_step_from_list(LOAD_RUN_LOADING_STEPS, step_index)


func _emit_run_loading_step_with_progress(step_index: int, stage_progress_ratio: float) -> void:
	_emit_loading_step_from_list(NEW_RUN_LOADING_STEPS, step_index, stage_progress_ratio)


func _emit_run_loading_detail(subprogress_text: String, log_lines: Array) -> void:
	run_loading_detail_updated.emit(subprogress_text, log_lines.duplicate())


func _emit_loading_step_from_list(steps: Array, step_index: int, stage_progress_ratio: float = 0.0) -> void:
	if steps.is_empty():
		run_loading_progress.emit("", "", 0, 0, 1.0)
		return

	var clamped_index: int = clamp(step_index, 0, steps.size() - 1)
	var step: Dictionary = steps[clamped_index]
	var denominator: float = max(float(steps.size() - 1), 1.0)
	var current_step_progress: float = float(clamped_index) / denominator
	var next_step_progress: float = min(float(clamped_index + 1), denominator) / denominator
	var progress_ratio: float = lerp(current_step_progress, next_step_progress, clamp(stage_progress_ratio, 0.0, 1.0))
	run_loading_progress.emit(
		str(step.get("id", "")),
		str(step.get("label", "")),
		clamped_index + 1,
		steps.size(),
		progress_ratio
	)


func start_background_company_detail_hydration(priority_company_ids: Array = []) -> void:
	if not RunState.has_active_run():
		return
	for company_id_value in priority_company_ids:
		RunState.queue_company_detail_hydration(str(company_id_value), true)
	var should_queue_full_roster: bool = priority_company_ids.is_empty() or (
		not background_company_detail_hydration_running and
		not RunState.has_pending_company_detail_hydration()
	)
	if should_queue_full_roster:
		for company_id_value in RunState.company_order:
			RunState.queue_company_detail_hydration(str(company_id_value), false)
	if background_company_detail_hydration_running:
		return
	background_company_detail_hydration_running = true
	call_deferred("_background_company_detail_hydration_loop")


func _background_company_detail_hydration_loop() -> void:
	while RunState.has_pending_company_detail_hydration():
		var company_id: String = RunState.dequeue_company_detail_hydration()
		if company_id.is_empty():
			break
		if RunState.ensure_company_full_detail(company_id, false):
			company_detail_ready.emit(company_id)
		await get_tree().process_frame
	background_company_detail_hydration_running = false


func _should_log_startup_perf() -> bool:
	return OS.is_debug_build()


func _should_log_advance_perf(save_after: bool, emit_runtime_signals: bool) -> bool:
	return OS.is_debug_build() and (save_after or emit_runtime_signals)


func _log_startup_perf_elapsed(label: String, started_at_usec: int, extra: String = "") -> void:
	if not _should_log_startup_perf():
		return
	var elapsed_msec: float = max(float(Time.get_ticks_usec() - started_at_usec) / 1000.0, 0.0)
	if extra.is_empty():
		print("%s %s %.2fms" % [STARTUP_PERF_LOG_PREFIX, label, elapsed_msec])
		return
	print("%s %s %.2fms%s" % [STARTUP_PERF_LOG_PREFIX, label, elapsed_msec, extra])


func _log_advance_perf_elapsed(enabled: bool, label: String, started_at_usec: int, extra: String = "") -> void:
	if not enabled:
		return
	var elapsed_msec: float = max(float(Time.get_ticks_usec() - started_at_usec) / 1000.0, 0.0)
	if extra.is_empty():
		print("%s %s %.2fms" % [ADVANCE_PERF_LOG_PREFIX, label, elapsed_msec])
		return
	print("%s %s %.2fms%s" % [ADVANCE_PERF_LOG_PREFIX, label, elapsed_msec, extra])


func _enter_game_scene() -> void:
	var current_scene = get_tree().current_scene
	if current_scene != null and current_scene.scene_file_path == GAME_SCENE:
		return

	get_tree().change_scene_to_file(GAME_SCENE)
