extends Node

signal day_started(day_index)
signal price_formed(day_index)
signal portfolio_changed
signal watchlist_changed
signal network_changed
signal upgrades_changed
signal daily_actions_changed
signal academy_changed
signal thesis_changed
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
var chart_pattern_system = preload("res://systems/ChartPatternSystem.gd").new()
var news_feed_system = preload("res://systems/NewsFeedSystem.gd").new()
var twooter_feed_system = preload("res://systems/TwooterFeedSystem.gd").new()
var contact_network_system = preload("res://systems/ContactNetworkSystem.gd").new()
var corporate_action_system = preload("res://systems/CorporateActionSystem.gd").new()
var company_event_system = preload("res://systems/CompanyEventSystem.gd").new()
var person_event_system = preload("res://systems/PersonEventSystem.gd").new()
var special_event_system = preload("res://systems/SpecialEventSystem.gd").new()
var academy_system = preload("res://systems/AcademySystem.gd").new()
var thesis_report_system = preload("res://systems/ThesisReportSystem.gd").new()
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
	var summary: Dictionary = summary_system.build_daily_summary(RunState, DataRepository, log_advance_perf)
	_log_advance_perf_elapsed(log_advance_perf, "build_daily_summary", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	RunState.set_daily_summary(summary)
	_log_advance_perf_elapsed(log_advance_perf, "set_daily_summary", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var feed_context: Dictionary = _build_news_feed_context(log_advance_perf)
	var news_snapshot: Dictionary = _build_news_snapshot(-1, log_advance_perf, feed_context)
	_log_advance_perf_elapsed(log_advance_perf, "build_news_snapshot", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	RunState.record_news_snapshot(news_snapshot)
	_log_advance_perf_elapsed(log_advance_perf, "record_news_snapshot", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_rebuild_daily_activity_snapshot_cache(news_snapshot, "", log_advance_perf, feed_context)
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
	var meeting_snapshot: Dictionary = corporate_action_system.get_dashboard_meeting_snapshot(RunState, -1, 12)
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


func _rebuild_daily_activity_snapshot_cache(news_snapshot: Dictionary = {}, cache_key: String = "", log_phase_details: bool = false, feed_context: Dictionary = {}) -> Dictionary:
	if not RunState.has_active_run():
		daily_activity_snapshot_cache = _empty_daily_activity_snapshot()
		return daily_activity_snapshot_cache
	var phase_started_at_usec: int = Time.get_ticks_usec()
	var resolved_news_snapshot: Dictionary = news_snapshot
	if resolved_news_snapshot.is_empty():
		resolved_news_snapshot = _build_news_snapshot()
	_log_advance_perf_elapsed(log_phase_details, "build_daily_activity_cache:resolve_news", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var social_activity_count: int = _count_twooter_current_day_activity(feed_context)
	_log_advance_perf_elapsed(log_phase_details, "build_daily_activity_cache:social_count", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var network_activity_count: int = contact_network_system.count_current_day_activity(RunState)
	_log_advance_perf_elapsed(log_phase_details, "build_daily_activity_cache:network_count", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var activity_counts: Dictionary = {
		"news": _count_news_articles(resolved_news_snapshot),
		"social": social_activity_count,
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


func _count_twooter_current_day_activity(feed_context: Dictionary = {}) -> int:
	var social_trade_date: Dictionary = {}
	if feed_context.has("trade_date"):
		social_trade_date = feed_context.get("trade_date", {}).duplicate(true)
	else:
		social_trade_date = get_current_trade_date()
		social_trade_date["day_index"] = RunState.day_index
	var market_history: Array = []
	if feed_context.has("market_history"):
		market_history = feed_context.get("market_history", [])
	else:
		market_history = get_market_history()
	var event_history: Array = []
	if feed_context.has("event_history"):
		event_history = feed_context.get("event_history", [])
	else:
		event_history = get_event_history()
	var active_special_events: Array = []
	if feed_context.has("active_special_events"):
		active_special_events = feed_context.get("active_special_events", [])
	else:
		active_special_events = get_active_special_events()
	var active_company_arcs: Array = []
	if feed_context.has("active_company_arcs"):
		active_company_arcs = feed_context.get("active_company_arcs", [])
	else:
		active_company_arcs = get_active_company_arcs()
	return twooter_feed_system.count_social_posts(
		DataRepository.get_twooter_feed_data(),
		market_history,
		event_history,
		active_special_events,
		active_company_arcs,
		social_trade_date,
		get_unlocked_twooter_access_tier()
	)


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


func _build_news_feed_context(log_phase_details: bool = false) -> Dictionary:
	var phase_started_at_usec: int = Time.get_ticks_usec()
	var news_trade_date: Dictionary = get_current_trade_date()
	news_trade_date["day_index"] = RunState.day_index
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:trade_date", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var company_rows: Array = get_company_rows()
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:company_rows", phase_started_at_usec, " count=%d" % company_rows.size())
	phase_started_at_usec = Time.get_ticks_usec()
	var market_history: Array = get_market_history()
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:market_history", phase_started_at_usec, " count=%d" % market_history.size())
	phase_started_at_usec = Time.get_ticks_usec()
	var event_history: Array = get_event_history()
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:event_history", phase_started_at_usec, " count=%d" % event_history.size())
	phase_started_at_usec = Time.get_ticks_usec()
	var active_special_events: Array = get_active_special_events()
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:special_events", phase_started_at_usec, " count=%d" % active_special_events.size())
	phase_started_at_usec = Time.get_ticks_usec()
	var active_company_arcs: Array = get_active_company_arcs()
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:company_arcs", phase_started_at_usec, " count=%d" % active_company_arcs.size())
	return {
		"trade_date": news_trade_date,
		"company_rows": company_rows,
		"market_history": market_history,
		"event_history": event_history,
		"active_special_events": active_special_events,
		"active_company_arcs": active_company_arcs
	}


func _build_news_snapshot(unlocked_intel_level: int = -1, log_phase_details: bool = false, feed_context: Dictionary = {}) -> Dictionary:
	var phase_started_at_usec: int = Time.get_ticks_usec()
	if unlocked_intel_level < 1:
		unlocked_intel_level = get_unlocked_news_intel_level()
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:access", phase_started_at_usec)
	if not RunState.has_active_run():
		return {
			"intel_level": max(unlocked_intel_level, 1),
			"outlets": [],
			"feeds": {}
		}

	var resolved_feed_context: Dictionary = feed_context
	if resolved_feed_context.is_empty():
		resolved_feed_context = _build_news_feed_context(log_phase_details)
	phase_started_at_usec = Time.get_ticks_usec()
	var feed_data: Dictionary = DataRepository.get_news_feed_data()
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:feed_data", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var news_snapshot: Dictionary = news_feed_system.build_news_snapshot(
		RunState,
		feed_data,
		resolved_feed_context.get("company_rows", []),
		resolved_feed_context.get("market_history", []),
		resolved_feed_context.get("event_history", []),
		resolved_feed_context.get("active_special_events", []),
		resolved_feed_context.get("active_company_arcs", []),
		resolved_feed_context.get("trade_date", {}),
		unlocked_intel_level
	)
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:feed_system", phase_started_at_usec)
	return news_snapshot


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


func get_thesis_board_snapshot() -> Dictionary:
	if not RunState.has_active_run():
		return {"theses": [], "companies": []}
	var theses: Array = []
	for thesis_value in RunState.get_player_theses().values():
		if typeof(thesis_value) != TYPE_DICTIONARY:
			continue
		var thesis: Dictionary = thesis_value.duplicate(true)
		thesis["has_report"] = not thesis.get("report", {}).is_empty()
		thesis["evidence_count"] = thesis.get("evidence", []).size()
		theses.append(thesis)
	theses.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("updated_day_index", 0)) == int(b.get("updated_day_index", 0)):
			return str(a.get("title", "")) < str(b.get("title", ""))
		return int(a.get("updated_day_index", 0)) > int(b.get("updated_day_index", 0))
	)
	return {
		"day_index": RunState.day_index,
		"trade_date": get_current_trade_date(),
		"theses": theses,
		"companies": _thesis_company_options()
	}


func get_thesis_evidence_options(company_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"company": {}, "categories": []}
	var company: Dictionary = get_company_snapshot(company_id, true, true, true)
	if company.is_empty():
		return {"company": {}, "categories": []}

	var categories: Array = [
		{"id": "fundamentals", "label": "Fundamentals / Key Stats", "options": _thesis_fundamental_options(company)},
		{"id": "financials", "label": "Financials", "options": _thesis_financial_options(company)},
		{"id": "price_action", "label": "Price Action", "options": _thesis_price_action_options(company)},
		{"id": "broker_flow", "label": "Broker Flow", "options": _thesis_broker_options(company)},
		{"id": "ownership", "label": "Ownership", "options": _thesis_ownership_options(company)},
		{"id": "sector_macro", "label": "Sector / Macro", "options": _thesis_sector_macro_options(company)},
		{"id": "news", "label": "News", "options": _thesis_news_options(company)},
		{"id": "twooter", "label": "Twooter", "options": _thesis_twooter_options(company)},
		{"id": "network_intel", "label": "Network Intel", "options": _thesis_network_options(company)},
		{"id": "corporate_events", "label": "Corporate Events", "options": _thesis_corporate_event_options(company)},
		{"id": "risk_invalidation", "label": "Risk / Invalidation", "options": _thesis_risk_options(company)}
	]
	return {
		"company": _thesis_company_compact(company),
		"categories": categories
	}


func get_chart_pattern_catalog() -> Array:
	return chart_pattern_system.get_pattern_catalog()


func get_open_theses_for_company(company_id: String) -> Array:
	if not RunState.has_active_run():
		return []
	var normalized_company_id: String = str(company_id)
	var rows: Array = []
	for thesis_value in RunState.get_player_theses().values():
		if typeof(thesis_value) != TYPE_DICTIONARY:
			continue
		var thesis: Dictionary = thesis_value
		if str(thesis.get("company_id", "")) != normalized_company_id:
			continue
		if str(thesis.get("status", "open")) == "closed":
			continue
		rows.append({
			"id": str(thesis.get("id", "")),
			"title": str(thesis.get("title", "")),
			"ticker": str(thesis.get("ticker", "")),
			"company_name": str(thesis.get("company_name", "")),
			"stance": str(thesis.get("stance", "")),
			"horizon": str(thesis.get("horizon", "")),
			"evidence_count": thesis.get("evidence", []).size(),
			"updated_day_index": int(thesis.get("updated_day_index", 0))
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("updated_day_index", 0)) == int(b.get("updated_day_index", 0)):
			return str(a.get("title", "")) < str(b.get("title", ""))
		return int(a.get("updated_day_index", 0)) > int(b.get("updated_day_index", 0))
	)
	return rows


func evaluate_chart_pattern_claim(
	company_id: String,
	range_id: String,
	pattern_id: String,
	start_anchor: Dictionary,
	end_anchor: Dictionary
) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var company: Dictionary = get_company_snapshot(company_id, false, false, false)
	if company.is_empty():
		return {"success": false, "message": "Unknown company selection."}
	var chart_snapshot: Dictionary = get_company_chart_snapshot(company_id, range_id, [])
	if chart_snapshot.is_empty():
		return {"success": false, "message": "Chart history is not ready yet."}
	return chart_pattern_system.evaluate_pattern_claim({
		"company_id": str(company_id),
		"ticker": str(company.get("ticker", company_id.to_upper())),
		"range_id": str(chart_snapshot.get("range_id", range_id)),
		"range_label": str(chart_snapshot.get("range_label", get_chart_range_label(range_id))),
		"pattern_id": pattern_id,
		"start_anchor": start_anchor.duplicate(true),
		"end_anchor": end_anchor.duplicate(true),
		"bars": chart_snapshot.get("bars", []).duplicate(true),
		"current_price": float(company.get("current_price", 0.0)),
		"trade_date": get_current_trade_date()
	})


func add_chart_pattern_evidence_to_thesis(thesis_id: String, claim: Dictionary) -> Dictionary:
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if thesis.is_empty():
		return {"success": false, "message": "Unknown thesis."}
	if str(thesis.get("status", "open")) == "closed":
		return {"success": false, "message": "This thesis is closed."}
	if not bool(claim.get("success", false)):
		return {"success": false, "message": str(claim.get("message", "Complete a valid chart pattern claim first."))}
	var claim_company_id: String = str(claim.get("company_id", thesis.get("company_id", "")))
	if not claim_company_id.is_empty() and claim_company_id != str(thesis.get("company_id", "")):
		return {"success": false, "message": "This pattern claim belongs to a different stock."}
	var evidence: Dictionary = claim.duplicate(true)
	evidence["category"] = "price_action"
	evidence["category_label"] = "Price Action"
	evidence["source_label"] = "STOCKBOT Chart"
	return add_thesis_evidence(thesis_id, evidence)


func create_thesis(company_id: String, stance: String, horizon: String, title: String = "") -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var company: Dictionary = get_company_snapshot(company_id, false, true, true)
	if company.is_empty():
		return {"success": false, "message": "Unknown company selection."}
	var thesis_id: String = _next_thesis_id(company_id)
	var normalized_stance: String = _normalize_thesis_stance(stance)
	var normalized_horizon: String = _normalize_thesis_horizon(horizon)
	var resolved_title: String = title.strip_edges()
	if resolved_title.is_empty():
		resolved_title = "%s %s thesis" % [str(company.get("ticker", company_id.to_upper())), normalized_stance.capitalize()]
	var thesis: Dictionary = {
		"id": thesis_id,
		"company_id": company_id,
		"ticker": str(company.get("ticker", company_id.to_upper())),
		"company_name": str(company.get("name", "")),
		"title": resolved_title,
		"stance": normalized_stance,
		"horizon": normalized_horizon,
		"status": "open",
		"created_day_index": RunState.day_index,
		"created_trade_date": get_current_trade_date(),
		"updated_day_index": RunState.day_index,
		"evidence": [],
		"report": {},
		"review": {}
	}
	RunState.set_player_thesis(thesis)
	_request_autosave("thesis_create")
	thesis_changed.emit()
	return {"success": true, "message": "Thesis created.", "thesis": thesis}


func update_thesis_meta(thesis_id: String, fields: Dictionary) -> Dictionary:
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if thesis.is_empty():
		return {"success": false, "message": "Unknown thesis."}
	if fields.has("title"):
		thesis["title"] = str(fields.get("title", thesis.get("title", ""))).strip_edges()
	if fields.has("stance"):
		thesis["stance"] = _normalize_thesis_stance(str(fields.get("stance", thesis.get("stance", "bullish"))))
	if fields.has("horizon"):
		thesis["horizon"] = _normalize_thesis_horizon(str(fields.get("horizon", thesis.get("horizon", "swing"))))
	if fields.has("status"):
		var status: String = str(fields.get("status", thesis.get("status", "open"))).to_lower()
		thesis["status"] = "closed" if status == "closed" else "open"
	thesis["updated_day_index"] = RunState.day_index
	RunState.set_player_thesis(thesis)
	_request_autosave("thesis_update")
	thesis_changed.emit()
	return {"success": true, "message": "Thesis updated.", "thesis": thesis}


func add_thesis_evidence(thesis_id: String, evidence: Dictionary) -> Dictionary:
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if thesis.is_empty():
		return {"success": false, "message": "Unknown thesis."}
	var evidence_rows: Array = thesis.get("evidence", [])
	var evidence_id: String = _next_thesis_evidence_id(evidence_rows)
	var compact_evidence: Dictionary = {
		"id": evidence_id,
		"category": str(evidence.get("category", "")),
		"category_label": str(evidence.get("category_label", "")),
		"label": str(evidence.get("label", "")),
		"value": str(evidence.get("value", "")),
		"detail": str(evidence.get("detail", "")),
		"source_label": str(evidence.get("source_label", "")),
		"impact": str(evidence.get("impact", "mixed")),
		"day_index": RunState.day_index
	}
	_copy_optional_thesis_evidence_fields(compact_evidence, evidence)
	if str(compact_evidence.get("category", "")).is_empty() or str(compact_evidence.get("label", "")).is_empty():
		return {"success": false, "message": "Pick a valid evidence row first."}
	evidence_rows.append(compact_evidence)
	thesis["evidence"] = evidence_rows
	thesis["updated_day_index"] = RunState.day_index
	RunState.set_player_thesis(thesis)
	_request_autosave("thesis_add_evidence")
	thesis_changed.emit()
	return {"success": true, "message": "Evidence added.", "thesis": thesis}


func remove_thesis_evidence(thesis_id: String, evidence_id: String) -> Dictionary:
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if thesis.is_empty():
		return {"success": false, "message": "Unknown thesis."}
	var next_rows: Array = []
	for evidence_value in thesis.get("evidence", []):
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = evidence_value
		if str(row.get("id", "")) != evidence_id:
			next_rows.append(row)
	thesis["evidence"] = next_rows
	thesis["updated_day_index"] = RunState.day_index
	RunState.set_player_thesis(thesis)
	_request_autosave("thesis_remove_evidence")
	thesis_changed.emit()
	return {"success": true, "message": "Evidence removed.", "thesis": thesis}


func generate_thesis_report(thesis_id: String) -> Dictionary:
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if thesis.is_empty():
		return {"success": false, "message": "Unknown thesis."}
	var context: Dictionary = _thesis_report_context(str(thesis.get("company_id", "")))
	var report: Dictionary = thesis_report_system.build_report(thesis, context)
	if report.is_empty():
		return {"success": false, "message": "Could not generate report for this thesis."}
	thesis["report"] = report
	thesis["review"] = thesis_report_system.build_review(thesis, context)
	thesis["updated_day_index"] = RunState.day_index
	RunState.set_player_thesis(thesis)
	_request_autosave("thesis_generate_report")
	thesis_changed.emit()
	return {"success": true, "message": "Research note generated.", "thesis": thesis, "report": report}


func refresh_thesis_review(thesis_id: String) -> Dictionary:
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if thesis.is_empty():
		return {"success": false, "message": "Unknown thesis."}
	var context: Dictionary = _thesis_report_context(str(thesis.get("company_id", "")))
	var review: Dictionary = thesis_report_system.build_review(thesis, context)
	thesis["review"] = review
	thesis["updated_day_index"] = RunState.day_index
	RunState.set_player_thesis(thesis)
	_request_autosave("thesis_refresh_review")
	thesis_changed.emit()
	return {"success": true, "message": "Thesis review refreshed.", "thesis": thesis, "review": review}


func close_thesis(thesis_id: String) -> Dictionary:
	return update_thesis_meta(thesis_id, {"status": "closed"})


func _thesis_company_options() -> Array:
	var rows: Array = []
	for row_value in get_company_rows():
		var row: Dictionary = row_value
		rows.append({
			"id": str(row.get("id", "")),
			"ticker": str(row.get("ticker", "")),
			"name": str(row.get("name", "")),
			"sector_name": str(row.get("sector_name", "")),
			"current_price": float(row.get("current_price", 0.0)),
			"daily_change_pct": float(row.get("daily_change_pct", 0.0))
		})
	return rows


func _thesis_company_compact(company: Dictionary) -> Dictionary:
	return {
		"id": str(company.get("id", company.get("company_id", ""))),
		"ticker": str(company.get("ticker", "")),
		"name": str(company.get("name", "")),
		"sector_name": str(company.get("sector_name", "")),
		"current_price": float(company.get("current_price", 0.0)),
		"daily_change_pct": float(company.get("daily_change_pct", 0.0))
	}


func _thesis_report_context(company_id: String) -> Dictionary:
	return {
		"day_index": RunState.day_index,
		"trade_date": get_current_trade_date(),
		"company": get_company_snapshot(company_id, true, true, true),
		"macro_state": get_current_macro_state()
	}


func _thesis_fundamental_options(company: Dictionary) -> Array:
	var financials: Dictionary = company.get("financials", {})
	var quality_score: int = int(company.get("quality_score", 0))
	var growth_score: int = int(company.get("growth_score", 0))
	var risk_score: int = int(company.get("risk_score", 0))
	return [
		_thesis_option("fundamentals", "Business quality", _thesis_quality_band_label(quality_score), _thesis_quality_band_detail(quality_score), _impact_from_score(float(quality_score), 62.0, 48.0)),
		_thesis_option("fundamentals", "Growth profile", _thesis_growth_band_label(growth_score), _thesis_growth_band_detail(growth_score), _impact_from_score(float(growth_score), 62.0, 48.0)),
		_thesis_option("fundamentals", "Risk profile", _thesis_risk_band_label(risk_score), _thesis_risk_band_detail(risk_score), "negative" if risk_score >= 58 else "positive"),
		_thesis_option("fundamentals", "ROE", _thesis_format_percent(float(financials.get("roe", 0.0)) / 100.0), "Return on equity gives a quick quality check.", _impact_from_score(float(financials.get("roe", 0.0)), 14.0, 8.0)),
		_thesis_option("fundamentals", "Debt to equity", "%sx" % String.num(float(financials.get("debt_to_equity", 0.0)), 2), "Leverage affects how much room the thesis has for mistakes.", "negative" if float(financials.get("debt_to_equity", 0.0)) >= 1.0 else "positive")
	]


func _thesis_financial_options(company: Dictionary) -> Array:
	var financials: Dictionary = company.get("financials", {})
	var market_cap: float = float(financials.get("market_cap", 0.0))
	var net_income: float = float(financials.get("net_income", 0.0))
	var pe: float = _safe_divide(market_cap, net_income)
	return [
		_thesis_option("financials", "Revenue growth YoY", _thesis_format_percent(float(financials.get("revenue_growth_yoy", 0.0)) / 100.0), "Revenue growth helps tell whether the story is expanding or fading.", _impact_from_score(float(financials.get("revenue_growth_yoy", 0.0)), 10.0, 0.0)),
		_thesis_option("financials", "Earnings growth YoY", _thesis_format_percent(float(financials.get("earnings_growth_yoy", 0.0)) / 100.0), "Earnings growth checks whether growth reaches the bottom line.", _impact_from_score(float(financials.get("earnings_growth_yoy", 0.0)), 8.0, 0.0)),
		_thesis_option("financials", "Net profit margin", _thesis_format_percent(float(financials.get("net_profit_margin", 0.0)) / 100.0), "Margin quality helps separate real business strength from noisy sales.", _impact_from_score(float(financials.get("net_profit_margin", 0.0)), 8.0, 3.0)),
		_thesis_option("valuation", "Current PE", "%sx" % String.num(pe, 2), "PE is an approximate valuation anchor from generated earnings.", "negative" if pe > 20.0 else ("positive" if pe > 0.0 and pe < 12.0 else "mixed")),
		_thesis_option("valuation", "Market cap", _thesis_format_currency(market_cap), "Market cap helps keep expectations realistic for the company size.", "mixed")
	]


func _thesis_price_action_options(company: Dictionary) -> Array:
	var price_bars: Array = company.get("price_bars", [])
	var recent_return: float = _recent_price_bar_return(price_bars, 5)
	return [
		_thesis_option("price_action", "Current price", _thesis_format_currency(float(company.get("current_price", 0.0))), "This freezes the entry context for the thesis.", "mixed"),
		_thesis_option("price_action", "Daily move", _thesis_format_percent(float(company.get("daily_change_pct", 0.0))), "The daily move shows whether the thesis is early or chasing strength.", _impact_from_change(float(company.get("daily_change_pct", 0.0)))),
		_thesis_option("price_action", "Five-bar trend", _thesis_format_percent(recent_return), "Recent bars show whether price action confirms the setup.", _impact_from_change(recent_return)),
		_thesis_option("price_action", "YTD move", _thesis_format_percent(float(company.get("ytd_change_pct", 0.0))), "YTD context helps avoid confusing a late move with an early setup.", _impact_from_change(float(company.get("ytd_change_pct", 0.0))))
	]


func _thesis_broker_options(company: Dictionary) -> Array:
	var broker_flow: Dictionary = company.get("broker_flow", {})
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))
	var buyer: String = _broker_actor_label_for_thesis(broker_flow, "buy")
	var seller: String = _broker_actor_label_for_thesis(broker_flow, "sell")
	return [
		_thesis_option("broker_flow", "Broker flow", flow_tag.capitalize(), "Broker flow checks whether stronger desks are supporting or leaning on the tape.", "positive" if flow_tag == "accumulation" else ("negative" if flow_tag == "distribution" else "mixed")),
		_thesis_option("broker_flow", "Dominant buyer", buyer, "Strong buyer identity helps judge the quality of demand.", "positive" if buyer != "Balanced" else "mixed"),
		_thesis_option("broker_flow", "Dominant seller", seller, "Strong seller identity is useful risk evidence.", "negative" if seller != "Balanced" else "mixed"),
		_thesis_option("broker_flow", "Net pressure", String.num(float(broker_flow.get("net_pressure", 0.0)), 2), "Net pressure gives the tape read a compact direction.", _impact_from_change(float(broker_flow.get("net_pressure", 0.0))))
	]


func _thesis_ownership_options(company: Dictionary) -> Array:
	var rows: Array = []
	rows.append(_thesis_option("ownership", "Player ownership", _thesis_format_percent(float(company.get("ownership_pct", 0.0))), "Your ownership affects meeting eligibility and concentration.", "mixed"))
	rows.append(_thesis_option("ownership", "Free float", _thesis_format_percent(float(company.get("financials", {}).get("free_float_pct", 0.0)) / 100.0), "Free float shapes liquidity and how crowded the tape can become.", "mixed"))
	for shareholder_value in company.get("shareholder_rows", []):
		if typeof(shareholder_value) != TYPE_DICTIONARY:
			continue
		var shareholder: Dictionary = shareholder_value
		rows.append(_thesis_option("ownership", "Major holder", "%s %s" % [str(shareholder.get("name", "Holder")), _thesis_format_percent(float(shareholder.get("ownership_pct", 0.0)))], "Ownership concentration can support or constrain a thesis.", "mixed"))
		if rows.size() >= 4:
			break
	return rows


func _thesis_sector_macro_options(company: Dictionary) -> Array:
	var rows: Array = []
	var company_sector_id: String = str(company.get("sector_id", ""))
	var company_sector_name: String = "Sector"
	for sector_value in get_sector_rows():
		var sector: Dictionary = sector_value
		if str(sector.get("id", "")) != company_sector_id:
			continue
		company_sector_name = str(sector.get("name", company_sector_name))
		rows.append(_thesis_option("sector_macro", "Sector performance", _thesis_format_percent(float(sector.get("average_change_pct", 0.0))), "Sector tape shows whether the stock is moving with or against its group.", _impact_from_change(float(sector.get("average_change_pct", 0.0)))))
		rows.append(_thesis_option("sector_macro", "Sector breadth", "%d green / %d red" % [int(sector.get("advancers", 0)), int(sector.get("decliners", 0))], "Breadth helps separate broad sector demand from one-stock noise.", "positive" if int(sector.get("advancers", 0)) >= int(sector.get("decliners", 0)) else "negative"))
		break
	var macro: Dictionary = get_current_macro_state()
	rows.append(_thesis_option("sector_macro", "Inflation backdrop", "%s%% YoY" % String.num(float(macro.get("inflation_yoy", 0.0)), 1), "Inflation pressure affects margins, consumer demand, rate expectations, and valuation tolerance.", _thesis_inflation_impact(float(macro.get("inflation_yoy", 0.0)))))
	rows.append(_thesis_option("sector_macro", "GDP growth", "%s%%" % String.num(float(macro.get("gdp_growth", 0.0)), 1), "GDP growth is the broad demand backdrop for cyclical revenue and market risk appetite.", _thesis_gdp_impact(float(macro.get("gdp_growth", 0.0)))))
	rows.append(_thesis_option("sector_macro", "Employment backdrop", "%s / unemployment %s%%" % [str(macro.get("employment_label", "Mixed")), String.num(float(macro.get("unemployment_rate", 0.0)), 1)], "Employment strength helps explain household demand and how much risk the market can carry.", _thesis_employment_impact(float(macro.get("employment_index", 0.0)))))
	rows.append(_thesis_option("sector_macro", "Policy rate", _thesis_policy_rate_label(macro), "The policy-rate path changes funding cost, valuation appetite, and sector leadership.", _thesis_policy_impact(str(macro.get("central_bank_stance", "hold")))))
	rows.append(_thesis_option("sector_macro", "Risk appetite", _thesis_risk_appetite_label(float(macro.get("risk_appetite", 0.5))), "Risk appetite is the market-wide willingness to pay for uncertainty.", _thesis_risk_appetite_impact(float(macro.get("risk_appetite", 0.5)))))
	var sector_macro_bias: float = float(macro.get("sector_biases", {}).get(company_sector_id, 0.0))
	rows.append(_thesis_option("sector_macro", "Sector macro bias", "%s %s" % [company_sector_name, _thesis_format_percent(sector_macro_bias)], "This is the simulator's direct macro tilt for the company's sector from inflation, GDP, employment, rates, and risk appetite.", _impact_from_change(sector_macro_bias)))
	rows.append(_thesis_active_macro_shock_option())
	return rows


func _thesis_news_options(company: Dictionary) -> Array:
	var rows: Array = []
	var snapshot: Dictionary = get_news_snapshot()
	for feed_value in snapshot.get("feeds", {}).values():
		if typeof(feed_value) != TYPE_DICTIONARY:
			continue
		var feed: Dictionary = feed_value
		for article_value in feed.get("articles", []):
			if typeof(article_value) != TYPE_DICTIONARY:
				continue
			var article: Dictionary = article_value
			if str(article.get("target_company_id", "")) != str(company.get("id", "")) and str(article.get("target_ticker", "")) != str(company.get("ticker", "")):
				continue
			rows.append(_thesis_option("news", str(article.get("headline", "News article")), str(article.get("public_status_label", article.get("tone", "mixed"))), str(article.get("deck", article.get("body", ""))).left(220), _impact_from_tone(str(article.get("tone", "mixed"))), str(feed.get("label", "News"))))
			if rows.size() >= 5:
				return rows
	if rows.is_empty():
		rows.append(_thesis_option("news", "No company-specific article", "No current article", "No fresh company-specific News article is available for this stock today.", "mixed", "News"))
	return rows


func _thesis_twooter_options(company: Dictionary) -> Array:
	var rows: Array = []
	var snapshot: Dictionary = get_twooter_snapshot()
	for post_value in snapshot.get("posts", []):
		if typeof(post_value) != TYPE_DICTIONARY:
			continue
		var post: Dictionary = post_value
		if str(post.get("target_ticker", "")) != str(company.get("ticker", "")):
			continue
		rows.append(_thesis_option("twooter", "@%s" % str(post.get("account_handle", "")), str(post.get("post_text", "")).left(120), str(post.get("context_hint", "")), _impact_from_tone(str(post.get("tone", "mixed"))), "Twooter"))
		if rows.size() >= 5:
			return rows
	if rows.is_empty():
		rows.append(_thesis_option("twooter", "No company-specific chatter", "No current post", "No fresh company-specific Twooter post is available for this stock today.", "mixed", "Twooter"))
	return rows


func _thesis_network_options(company: Dictionary) -> Array:
	var rows: Array = []
	var snapshot: Dictionary = get_network_snapshot()
	for contact_value in snapshot.get("contacts", []):
		if typeof(contact_value) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = contact_value
		if not bool(contact.get("met", false)):
			continue
		var company_ids: Array = contact.get("target_company_ids", [])
		var focus_company_id: String = str(contact.get("company_id", ""))
		if focus_company_id != str(company.get("id", "")) and not company_ids.has(str(company.get("id", ""))):
			continue
		rows.append(_thesis_option("network_intel", str(contact.get("display_name", contact.get("name", "Network contact"))), str(contact.get("role", contact.get("affiliation_role", "Contact"))), str(contact.get("last_tip_note", contact.get("description", "Known contact can add private context."))).left(220), "mixed", "Network"))
		if rows.size() >= 4:
			return rows
	if rows.is_empty():
		rows.append(_thesis_option("network_intel", "No met contact", "No private read", "Meet relevant contacts before treating Network as thesis evidence.", "mixed", "Network"))
	return rows


func _thesis_corporate_event_options(company: Dictionary) -> Array:
	var rows: Array = []
	for event_value in get_event_history():
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_value
		if str(event.get("target_company_id", "")) != str(company.get("id", "")):
			continue
		rows.append(_thesis_option("corporate_events", str(event.get("headline", event.get("event_id", "Corporate event"))), str(event.get("summary", event.get("category", ""))).left(140), "Corporate event history can be a catalyst or a risk depending on confirmation.", _impact_from_tone(str(event.get("tone", "mixed"))), "Corporate events"))
		if rows.size() >= 5:
			return rows
	var meeting_snapshot: Dictionary = get_corporate_meeting_snapshot()
	for meeting_value in meeting_snapshot.get("upcoming_rows", []):
		if typeof(meeting_value) != TYPE_DICTIONARY:
			continue
		var meeting: Dictionary = meeting_value
		if str(meeting.get("company_id", "")) != str(company.get("id", "")):
			continue
		rows.append(_thesis_option("corporate_events", str(meeting.get("label", "Corporate meeting")), str(meeting.get("ticker", "")), str(meeting.get("public_summary", "Upcoming meeting can change the setup.")).left(180), "mixed", "Meeting calendar"))
	if rows.is_empty():
		rows.append(_thesis_option("corporate_events", "No active corporate event", "No event selected", "No current corporate event is tied to this company.", "mixed", "Corporate events"))
	return rows


func _thesis_risk_options(company: Dictionary) -> Array:
	var financials: Dictionary = company.get("financials", {})
	var risk_score: int = int(company.get("risk_score", 0))
	var debt_to_equity: float = float(financials.get("debt_to_equity", 0.0))
	var daily_change: float = float(company.get("daily_change_pct", 0.0))
	return [
		_thesis_option("risk_invalidation", "Risk profile invalidation", _thesis_risk_band_label(risk_score), _thesis_risk_band_detail(risk_score), "negative" if risk_score >= 58 else "mixed"),
		_thesis_option("risk_invalidation", "Leverage invalidation", "%sx debt/equity" % String.num(debt_to_equity, 2), "If leverage is high, weak earnings can break the thesis faster.", "negative" if debt_to_equity >= 1.0 else "mixed"),
		_thesis_option("risk_invalidation", "Price invalidation", "Breaks below today's price by 5%", "If price loses the thesis level, re-check before averaging down.", "negative"),
		_thesis_option("risk_invalidation", "Chasing risk", _thesis_format_percent(daily_change), "If the move already ran, a good story can still be a bad entry.", "negative" if daily_change > 0.05 else "mixed")
	]


func _thesis_option(category: String, label: String, value: String, detail: String, impact: String = "mixed", source_label: String = "") -> Dictionary:
	return {
		"category": category,
		"category_label": _thesis_category_label(category),
		"label": label,
		"value": value,
		"detail": detail,
		"impact": impact,
		"source_label": source_label
	}


func _copy_optional_thesis_evidence_fields(target: Dictionary, source: Dictionary) -> void:
	for key_value in [
		"company_id",
		"ticker",
		"pattern_id",
		"pattern_label",
		"feedback_state",
		"feedback_reason",
		"invalidation",
		"chart_range",
		"chart_range_label",
		"region_label"
	]:
		var key: String = str(key_value)
		if source.has(key):
			target[key] = str(source.get(key, ""))
	for key_value in ["start_price", "end_price", "current_price"]:
		var key: String = str(key_value)
		if source.has(key):
			target[key] = float(source.get(key, 0.0))
	for key_value in ["start_anchor", "end_anchor", "start_date", "end_date", "report_date"]:
		var key: String = str(key_value)
		if typeof(source.get(key, {})) == TYPE_DICTIONARY:
			target[key] = source.get(key, {}).duplicate(true)


func _thesis_category_label(category: String) -> String:
	var labels := {
		"fundamentals": "Fundamentals / Key Stats",
		"financials": "Financials",
		"valuation": "Valuation",
		"price_action": "Price Action",
		"broker_flow": "Broker Flow",
		"ownership": "Ownership",
		"sector_macro": "Sector / Macro",
		"news": "News",
		"twooter": "Twooter",
		"network_intel": "Network Intel",
		"corporate_events": "Corporate Events",
		"risk_invalidation": "Risk / Invalidation"
	}
	return str(labels.get(category, category.capitalize()))


func _next_thesis_id(company_id: String) -> String:
	var index: int = RunState.get_player_theses().size() + 1
	while true:
		var thesis_id: String = "thesis_%s_%03d" % [company_id, index]
		if RunState.get_player_thesis(thesis_id).is_empty():
			return thesis_id
		index += 1
	return "thesis_%s_%03d" % [company_id, index]


func _next_thesis_evidence_id(evidence_rows: Array) -> String:
	var index: int = evidence_rows.size() + 1
	while true:
		var evidence_id: String = "evidence_%03d" % index
		var found: bool = false
		for row_value in evidence_rows:
			if typeof(row_value) == TYPE_DICTIONARY and str(row_value.get("id", "")) == evidence_id:
				found = true
				break
		if not found:
			return evidence_id
		index += 1
	return "evidence_%03d" % index


func _normalize_thesis_stance(stance: String) -> String:
	var normalized: String = stance.to_lower()
	if normalized in ["bullish", "bearish", "income", "watch"]:
		return normalized
	return "bullish"


func _normalize_thesis_horizon(horizon: String) -> String:
	var normalized: String = horizon.to_lower()
	if normalized in ["swing", "position", "income", "event"]:
		return normalized
	return "swing"


func _recent_price_bar_return(price_bars: Array, lookback: int) -> float:
	if price_bars.size() < 2:
		return 0.0
	var end_bar: Dictionary = price_bars[price_bars.size() - 1]
	var start_index: int = max(price_bars.size() - lookback, 0)
	var start_bar: Dictionary = price_bars[start_index]
	var start_price: float = float(start_bar.get("close", start_bar.get("price", 0.0)))
	var end_price: float = float(end_bar.get("close", end_bar.get("price", 0.0)))
	if is_zero_approx(start_price):
		return 0.0
	return (end_price - start_price) / start_price


func _thesis_quality_band_label(score: int) -> String:
	if score >= 80:
		return "Excellent"
	if score >= 65:
		return "Strong"
	if score >= 50:
		return "Average"
	if score >= 35:
		return "Weak"
	return "Fragile"


func _thesis_growth_band_label(score: int) -> String:
	if score >= 80:
		return "Accelerating"
	if score >= 65:
		return "Healthy"
	if score >= 50:
		return "Steady"
	if score >= 35:
		return "Uneven"
	return "Stalling"


func _thesis_risk_band_label(score: int) -> String:
	if score >= 80:
		return "High"
	if score >= 65:
		return "Elevated"
	if score >= 45:
		return "Moderate"
	if score >= 25:
		return "Manageable"
	return "Low"


func _thesis_quality_band_detail(score: int) -> String:
	if score >= 80:
		return "Excellent quality can support conviction, but the entry and valuation still need confirmation."
	if score >= 65:
		return "Strong quality gives the thesis fundamental support if valuation is still reasonable."
	if score >= 50:
		return "Average quality is workable, but the stock needs help from price action, valuation, or catalysts."
	if score >= 35:
		return "Weak quality means the thesis needs clear confirmation before adding size."
	return "Fragile quality means the thesis needs more than one bullish signal before it deserves conviction."


func _thesis_growth_band_detail(score: int) -> String:
	if score >= 80:
		return "Accelerating growth can justify a stronger upside case if margins and tape confirm."
	if score >= 65:
		return "Healthy growth supports a constructive thesis when valuation is not stretched."
	if score >= 50:
		return "Steady growth is useful, but it rarely carries the thesis alone."
	if score >= 35:
		return "Uneven growth is not broken, but it needs confirmation from fresh financials or catalysts."
	return "Stalling growth needs either a valuation gap, turnaround catalyst, or clear tape support."


func _thesis_risk_band_detail(score: int) -> String:
	if score >= 80:
		return "High risk needs tight invalidation and strong evidence before the position can be sized."
	if score >= 65:
		return "Elevated risk means the idea can work, but only with clear confirmation and controlled size."
	if score >= 45:
		return "Moderate risk demands confirmation, but it does not reject the idea by itself."
	if score >= 25:
		return "Manageable risk gives the thesis room to develop if evidence stays consistent."
	return "Low risk gives the thesis more room, though price and valuation still matter."


func _thesis_policy_rate_label(macro: Dictionary) -> String:
	var stance: String = str(macro.get("central_bank_stance", "hold")).capitalize()
	var rate: float = float(macro.get("policy_rate", 0.0))
	var bps: int = int(macro.get("policy_action_bps", 0))
	return "%s to %s%% (%+d bps)" % [stance, String.num(rate, 2), bps]


func _thesis_risk_appetite_label(risk_appetite: float) -> String:
	if risk_appetite >= 0.64:
		return "Risk-on"
	if risk_appetite >= 0.54:
		return "Constructive"
	if risk_appetite <= 0.36:
		return "Risk-off"
	if risk_appetite <= 0.46:
		return "Defensive"
	return "Neutral"


func _thesis_active_macro_shock_option() -> Dictionary:
	var active_events: Array = get_active_special_events()
	if active_events.is_empty():
		return _thesis_option("sector_macro", "Active macro shock", "None", "No active special macro shock is currently pressuring the tape.", "mixed", "Macro shocks")
	var event: Dictionary = active_events[0] if typeof(active_events[0]) == TYPE_DICTIONARY else {}
	var headline: String = str(event.get("headline", event.get("headline_detail", event.get("event_id", "Macro shock"))))
	var detail: String = str(event.get("description", event.get("headline_detail", "An active macro shock is changing volatility, market bias, or sector leadership.")))
	return _thesis_option("sector_macro", "Active macro shock", headline, detail.left(220), _impact_from_tone(str(event.get("tone", "mixed"))), "Macro shocks")


func _thesis_inflation_impact(inflation_yoy: float) -> String:
	if inflation_yoy >= 4.6:
		return "negative"
	if inflation_yoy <= 2.8:
		return "positive"
	return "mixed"


func _thesis_gdp_impact(gdp_growth: float) -> String:
	if gdp_growth >= 5.2:
		return "positive"
	if gdp_growth <= 3.4:
		return "negative"
	return "mixed"


func _thesis_employment_impact(employment_index: float) -> String:
	if employment_index >= 0.58:
		return "positive"
	if employment_index <= 0.42:
		return "negative"
	return "mixed"


func _thesis_policy_impact(central_bank_stance: String) -> String:
	var normalized: String = central_bank_stance.to_lower()
	if normalized == "cut":
		return "positive"
	if normalized == "hike":
		return "negative"
	return "mixed"


func _thesis_risk_appetite_impact(risk_appetite: float) -> String:
	if risk_appetite >= 0.54:
		return "positive"
	if risk_appetite <= 0.46:
		return "negative"
	return "mixed"


func _impact_from_score(value: float, positive_threshold: float, negative_threshold: float) -> String:
	if value >= positive_threshold:
		return "positive"
	if value <= negative_threshold:
		return "negative"
	return "mixed"


func _impact_from_change(value: float) -> String:
	if value > 0.005:
		return "positive"
	if value < -0.005:
		return "negative"
	return "mixed"


func _impact_from_tone(tone: String) -> String:
	var normalized: String = tone.to_lower()
	if normalized in ["positive", "bullish", "constructive"]:
		return "positive"
	if normalized in ["negative", "bearish", "defensive"]:
		return "negative"
	return "mixed"


func _broker_actor_label_for_thesis(broker_flow: Dictionary, side: String) -> String:
	var broker_code_key: String = "dominant_buy_broker_code" if side == "buy" else "dominant_sell_broker_code"
	var broker_type_key: String = "dominant_buy_broker_type" if side == "buy" else "dominant_sell_broker_type"
	var fallback_key: String = "dominant_buyer" if side == "buy" else "dominant_seller"
	var broker_code: String = str(broker_flow.get(broker_code_key, ""))
	if not broker_code.is_empty():
		return broker_code
	var fallback_value: String = str(broker_flow.get(broker_type_key, broker_flow.get(fallback_key, "balanced")))
	return "Balanced" if fallback_value.is_empty() else fallback_value.capitalize()


func _thesis_format_currency(value: float) -> String:
	var sign: String = "-" if value < 0.0 else ""
	var abs_value: float = abs(value)
	if abs_value >= 1000000000000.0:
		return "%sRp%sT" % [sign, String.num(abs_value / 1000000000000.0, 2)]
	if abs_value >= 1000000000.0:
		return "%sRp%sB" % [sign, String.num(abs_value / 1000000000.0, 2)]
	if abs_value >= 1000000.0:
		return "%sRp%sM" % [sign, String.num(abs_value / 1000000.0, 2)]
	return "%sRp%s" % [sign, String.num(abs_value, 2)]


func _thesis_format_percent(value: float) -> String:
	var sign: String = "+" if value > 0.0 else ""
	return "%s%s%%" % [sign, String.num(value * 100.0, 2)]


func _safe_divide(numerator: float, denominator: float) -> float:
	if is_zero_approx(denominator):
		return 0.0
	return numerator / denominator


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
