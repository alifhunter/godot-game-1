extends Node

signal progress_changed(snapshot: Dictionary)

const CATALOG_PATH := "res://data/steam/achievement_catalog.json"
const STORE_DELAY_SECONDS := 4.0
const FIRST_MONTH_TRADING_DAYS := 20
const RECOVERY_DRAWDOWN_RATIO := 0.10
const OPERATOR_SCARS_DAILY_DROP := -0.10
const STORE_ENABLED_SETTING := "steam/progress/store_enabled"

const STAT_SETTER_METHODS := ["setStatInt", "set_stat_int", "setStat"]
const STAT_FLOAT_SETTER_METHODS := ["setStatFloat", "set_stat_float"]
const ACHIEVEMENT_SETTER_METHODS := ["setAchievement", "set_achievement"]
const STORE_METHODS := ["storeStats", "store_stats"]
const REQUEST_STATS_METHODS := ["requestCurrentStats", "request_current_stats"]

var catalog: Dictionary = {}
var stat_definitions: Dictionary = {}
var achievement_definitions: Dictionary = {}
var dirty_stat_names: Dictionary = {}
var dirty_achievement_names: Dictionary = {}
var store_timer: Timer = null
var current_stats_requested: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_catalog()
	_ensure_store_timer()
	if has_node("/root/SteamManager"):
		var steam_manager = get_node("/root/SteamManager")
		if steam_manager.has_signal("status_changed") and not steam_manager.status_changed.is_connected(_on_steam_status_changed):
			steam_manager.status_changed.connect(_on_steam_status_changed)
		if steam_manager.has_method("is_steam_enabled") and bool(steam_manager.is_steam_enabled()):
			request_current_stats()
			queue_store(false)


func sync_from_run_state(backfill: bool = true, flush_after: bool = false) -> Dictionary:
	if not _has_run_state():
		return {}
	_load_catalog()
	var progress: Dictionary = RunState.get_steam_progress()
	if backfill and RunState.has_active_run():
		_backfill_from_run_state(progress)
		_evaluate_stat_achievements(progress)
		RunState.set_steam_progress(progress)
		progress = RunState.get_steam_progress()
	if flush_after:
		queue_store(true)
	progress_changed.emit(progress.duplicate(true))
	return progress


func reset_for_active_run() -> void:
	if not _has_run_state():
		return
	dirty_stat_names.clear()
	dirty_achievement_names.clear()
	RunState.set_steam_progress({})
	sync_from_run_state(true, false)


func record_trade(trade_entry: Dictionary, ownership_snapshot: Dictionary = {}) -> void:
	if trade_entry.is_empty():
		return
	var side: String = str(trade_entry.get("side", "")).to_lower()
	var payload: Dictionary = trade_entry.duplicate(true)
	payload["trade_side"] = side
	payload["lots"] = max(int(trade_entry.get("lots", 0)), 0)
	payload["shares"] = max(int(trade_entry.get("shares", 0)), 0)
	payload["realized_pnl"] = float(trade_entry.get("realized_pnl", 0.0))
	payload["ownership"] = ownership_snapshot.duplicate(true)
	record_event("trade_placed", payload)
	if side == "buy":
		record_event("buy_order", payload)
	elif side == "sell":
		record_event("sell_order", payload)
		if float(trade_entry.get("realized_pnl", 0.0)) > 0.0:
			record_event("profitable_sell", payload)
	if bool(ownership_snapshot.get("is_control_shareholder", false)):
		unlock_achievement("ACH_CONTROL_ROOM")


func record_day_advanced(context: Dictionary = {}) -> void:
	var payload: Dictionary = context.duplicate(true)
	if _has_run_state() and RunState.has_active_run():
		payload["day_index"] = RunState.day_index
		payload["trade_date"] = RunState.current_trade_date.duplicate(true)
		payload["equity"] = RunState.get_total_equity()
		payload["cash"] = float(RunState.player_portfolio.get("cash", 0.0))
		payload["difficulty_id"] = RunState.difficulty_id
		payload["held_major_down_move"] = _held_major_down_move()
	record_event("day_survived", payload)


func record_stockbot_tab_view(tab_title: String, company_id: String = "") -> void:
	var normalized_title: String = tab_title.strip_edges()
	if normalized_title.is_empty():
		return
	var payload: Dictionary = {
		"tab_title": normalized_title,
		"company_id": company_id
	}
	record_event("stockbot_tab_view", payload)
	match normalized_title:
		"Key Stats":
			record_event("key_stats_inspected", payload)
		"Financials":
			record_event("financials_inspected", payload)
		"Broker":
			record_event("broker_flow_inspected", payload)
		"Corp. Action":
			record_event("corp_action_inspected", payload)
		"Profile":
			record_event("profile_inspected", payload)


func record_news_article_read(article_id: String = "") -> void:
	record_event("news_article_read", {"article_id": article_id})


func record_event(event_id: String, payload: Dictionary = {}, count: int = 1) -> Dictionary:
	var normalized_event_id: String = event_id.strip_edges()
	if normalized_event_id.is_empty() or count <= 0 or not _has_run_state():
		return {}
	var progress: Dictionary = RunState.get_steam_progress()
	_increment_event_count(progress, normalized_event_id, count)
	_apply_event_stats(progress, normalized_event_id, payload, count)
	_apply_event_achievements(progress, normalized_event_id, payload)
	_evaluate_stat_achievements(progress)
	progress["last_synced_unix"] = int(Time.get_unix_time_from_system())
	RunState.set_steam_progress(progress)
	var snapshot: Dictionary = RunState.get_steam_progress()
	progress_changed.emit(snapshot.duplicate(true))
	queue_store(_event_should_flush_immediately(normalized_event_id))
	return snapshot


func increment_stat(api_name: String, delta: int = 1, payload: Dictionary = {}) -> Dictionary:
	var normalized_api_name: String = api_name.strip_edges()
	if normalized_api_name.is_empty() or delta == 0 or not _has_run_state():
		return {}
	var progress: Dictionary = RunState.get_steam_progress()
	_increment_stat(progress, normalized_api_name, delta)
	_evaluate_stat_achievements(progress)
	progress["last_synced_unix"] = int(Time.get_unix_time_from_system())
	RunState.set_steam_progress(progress)
	var snapshot: Dictionary = RunState.get_steam_progress()
	progress_changed.emit(snapshot.duplicate(true))
	queue_store(bool(payload.get("flush", false)))
	return snapshot


func set_stat_max(api_name: String, value: int, flush_after: bool = false) -> Dictionary:
	var normalized_api_name: String = api_name.strip_edges()
	if normalized_api_name.is_empty() or not _has_run_state():
		return {}
	var progress: Dictionary = RunState.get_steam_progress()
	_set_stat(progress, normalized_api_name, value, true)
	_evaluate_stat_achievements(progress)
	progress["last_synced_unix"] = int(Time.get_unix_time_from_system())
	RunState.set_steam_progress(progress)
	var snapshot: Dictionary = RunState.get_steam_progress()
	progress_changed.emit(snapshot.duplicate(true))
	queue_store(flush_after)
	return snapshot


func unlock_achievement(api_name: String, payload: Dictionary = {}) -> Dictionary:
	var normalized_api_name: String = api_name.strip_edges()
	if normalized_api_name.is_empty() or not _has_run_state():
		return {}
	var progress: Dictionary = RunState.get_steam_progress()
	_unlock_achievement(progress, normalized_api_name)
	progress["last_synced_unix"] = int(Time.get_unix_time_from_system())
	RunState.set_steam_progress(progress)
	var snapshot: Dictionary = RunState.get_steam_progress()
	progress_changed.emit(snapshot.duplicate(true))
	queue_store(bool(payload.get("flush", true)))
	return snapshot


func request_current_stats() -> void:
	if current_stats_requested or not _steam_enabled():
		return
	current_stats_requested = true
	_call_steam_first(REQUEST_STATS_METHODS, [], false)


func queue_store(immediate: bool = false) -> void:
	if dirty_stat_names.is_empty() and dirty_achievement_names.is_empty():
		return
	if not _steam_enabled():
		return
	request_current_stats()
	if immediate:
		flush()
		return
	_ensure_store_timer()
	if store_timer != null and store_timer.is_stopped():
		store_timer.start(STORE_DELAY_SECONDS)


func flush() -> bool:
	if dirty_stat_names.is_empty() and dirty_achievement_names.is_empty():
		return true
	if not _steam_enabled():
		return false
	var progress: Dictionary = RunState.get_steam_progress() if _has_run_state() else {}
	var pushed_any: bool = false
	for stat_name_value in dirty_stat_names.keys():
		var stat_name: String = str(stat_name_value)
		var stat_value: int = int(progress.get("stats", {}).get(stat_name, 0))
		if _push_stat(stat_name, stat_value):
			pushed_any = true
	for achievement_name_value in dirty_achievement_names.keys():
		var achievement_name: String = str(achievement_name_value)
		if bool(progress.get("achievements", {}).get(achievement_name, false)) and _push_achievement(achievement_name):
			pushed_any = true
	if not pushed_any:
		return false
	var store_result: Variant = _call_steam_first(STORE_METHODS, [], null)
	if typeof(store_result) == TYPE_BOOL and not bool(store_result):
		return false
	dirty_stat_names.clear()
	dirty_achievement_names.clear()
	return true


func get_progress_snapshot() -> Dictionary:
	if not _has_run_state():
		return {}
	return RunState.get_steam_progress()


func get_catalog_snapshot() -> Dictionary:
	_load_catalog()
	return catalog.duplicate(true)


func _load_catalog() -> void:
	if not catalog.is_empty():
		return
	if not FileAccess.file_exists(CATALOG_PATH):
		catalog = {"stats": [], "achievements": []}
		return
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		catalog = {"stats": [], "achievements": []}
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		catalog = {"stats": [], "achievements": []}
		return
	catalog = parsed
	stat_definitions.clear()
	for stat_value in catalog.get("stats", []):
		if typeof(stat_value) != TYPE_DICTIONARY:
			continue
		var stat: Dictionary = stat_value
		var api_name: String = str(stat.get("api_name", "")).strip_edges()
		if not api_name.is_empty():
			stat_definitions[api_name] = stat.duplicate(true)
	achievement_definitions.clear()
	for achievement_value in catalog.get("achievements", []):
		if typeof(achievement_value) != TYPE_DICTIONARY:
			continue
		var achievement: Dictionary = achievement_value
		var api_name: String = str(achievement.get("api_name", "")).strip_edges()
		if not api_name.is_empty():
			achievement_definitions[api_name] = achievement.duplicate(true)


func _ensure_store_timer() -> void:
	if store_timer != null:
		return
	store_timer = Timer.new()
	store_timer.name = "SteamProgressStoreTimer"
	store_timer.one_shot = true
	store_timer.wait_time = STORE_DELAY_SECONDS
	store_timer.timeout.connect(_on_store_timer_timeout)
	add_child(store_timer)


func _on_store_timer_timeout() -> void:
	flush()


func _on_steam_status_changed(_is_available: bool, is_initialized: bool) -> void:
	if is_initialized:
		current_stats_requested = false
		request_current_stats()
		queue_store(false)


func _apply_event_stats(progress: Dictionary, event_id: String, payload: Dictionary, count: int) -> void:
	match event_id:
		"trade_placed":
			_increment_stat(progress, "STAT_TRADES_PLACED", count)
			_increment_stat(progress, "STAT_LOTS_TRADED", max(int(payload.get("lots", 0)), 0))
		"buy_order":
			_increment_stat(progress, "STAT_BUY_ORDERS", count)
		"sell_order":
			_increment_stat(progress, "STAT_SELL_ORDERS", count)
		"profitable_sell":
			_increment_stat(progress, "STAT_PROFITABLE_SELLS", count)
		"day_survived":
			_set_stat(progress, "STAT_DAYS_SURVIVED", max(int(payload.get("day_index", 0)), 0), true)
			_apply_day_progress_meta(progress, payload)
		"watchlist_added":
			_increment_stat(progress, "STAT_WATCHLIST_ADDS", count)
		"news_article_read":
			_increment_stat(progress, "STAT_NEWS_ARTICLES_READ", count)
		"stockbot_tab_view":
			_increment_stat(progress, "STAT_STOCKBOT_TAB_VIEWS", count)
		"key_stats_inspected":
			_increment_stat(progress, "STAT_KEY_STATS_INSPECTED", count)
		"financials_inspected":
			_increment_stat(progress, "STAT_FINANCIALS_INSPECTED", count)
		"broker_flow_inspected":
			_increment_stat(progress, "STAT_BROKER_FLOW_INSPECTED", count)
		"corp_action_inspected":
			_increment_stat(progress, "STAT_CORP_ACTION_INSPECTED", count)
		"profile_inspected":
			_increment_stat(progress, "STAT_PROFILE_INSPECTED", count)
		"chart_pattern_claimed":
			_increment_stat(progress, "STAT_CHART_PATTERNS_CLAIMED", count)
		"research_evidence_captured":
			_increment_stat(progress, "STAT_RESEARCH_EVIDENCE_CAPTURED", count)
		"research_evidence_attached":
			_increment_stat(progress, "STAT_RESEARCH_EVIDENCE_ATTACHED", count)
		"thesis_created":
			_increment_stat(progress, "STAT_THESES_CREATED", count)
		"upgrade_purchased":
			_increment_stat(progress, "STAT_UPGRADES_PURCHASED", count)
		"network_contact_met":
			_increment_stat(progress, "STAT_NETWORK_CONTACTS_MET", count)
		"network_tip_requested":
			_increment_stat(progress, "STAT_NETWORK_TIPS_REQUESTED", count)
		"rupslb_attended":
			_increment_stat(progress, "STAT_RUPSLB_ATTENDED", count)
		"corporate_vote_submitted":
			_increment_stat(progress, "STAT_CORPORATE_MEETING_VOTES", count)
		"academy_lesson_completed":
			_increment_stat(progress, "STAT_ACADEMY_LESSONS_COMPLETED", count)
		"academy_quiz_passed":
			_increment_stat(progress, "STAT_ACADEMY_QUIZZES_PASSED", count)
		"life_property_purchased":
			_increment_stat(progress, "STAT_LIFE_PROPERTIES_PURCHASED", count)
		"life_car_purchased":
			_increment_stat(progress, "STAT_LIFE_CARS_PURCHASED", count)
		"emergency_loan_taken":
			_increment_stat(progress, "STAT_EMERGENCY_LOANS_TAKEN", count)


func _apply_event_achievements(progress: Dictionary, event_id: String, payload: Dictionary) -> void:
	match event_id:
		"watchlist_added":
			_unlock_achievement(progress, "ACH_FIRST_WATCHLIST")
		"news_article_read":
			_unlock_achievement(progress, "ACH_READ_FIRST_NEWS")
		"key_stats_inspected":
			_unlock_achievement(progress, "ACH_CHECK_KEY_STATS")
		"network_tip_requested":
			_unlock_achievement(progress, "ACH_FIRST_TIP")
		"rupslb_attended":
			_unlock_achievement(progress, "ACH_ATTEND_RUPSLB")
		"academy_quiz_passed":
			if str(payload.get("category_id", "")).to_lower() == "technical":
				_unlock_achievement(progress, "ACH_COMPLETE_TECHNICAL_PATH")


func _apply_day_progress_meta(progress: Dictionary, payload: Dictionary) -> void:
	var meta: Dictionary = progress.get("meta", {}).duplicate(true)
	var equity: float = max(float(payload.get("equity", 0.0)), 0.0)
	var previous_equity: float = max(float(meta.get("last_equity", equity)), 0.0)
	var month_key: String = _month_key(payload.get("trade_date", {}))
	var stored_month_key: String = str(meta.get("month_key", ""))
	if stored_month_key.is_empty() and not month_key.is_empty():
		meta["month_key"] = month_key
		meta["month_start_equity"] = equity
	elif not month_key.is_empty() and month_key != stored_month_key:
		var month_start_equity: float = max(float(meta.get("month_start_equity", previous_equity)), 0.0)
		if previous_equity > month_start_equity + 0.0001:
			_increment_stat(progress, "STAT_GREEN_MONTHS", 1)
		meta["month_key"] = month_key
		meta["month_start_equity"] = equity

	var equity_peak: float = max(float(meta.get("equity_peak", 0.0)), equity)
	if equity_peak <= 0.0:
		equity_peak = equity
	if equity_peak > 0.0 and equity <= equity_peak * (1.0 - RECOVERY_DRAWDOWN_RATIO):
		meta["drawdown_armed"] = true
	if bool(meta.get("drawdown_armed", false)) and equity >= equity_peak - 0.0001 and equity_peak > 0.0:
		_unlock_achievement(progress, "ACH_RECOVER_DRAWDOWN")
		meta["drawdown_armed"] = false
	if equity > equity_peak:
		equity_peak = equity
	meta["equity_peak"] = equity_peak
	meta["last_equity"] = equity
	progress["meta"] = meta

	var day_index: int = max(int(payload.get("day_index", 0)), 0)
	if day_index >= FIRST_MONTH_TRADING_DAYS:
		_unlock_achievement(progress, "ACH_SURVIVE_FIRST_MONTH")
		match str(payload.get("difficulty_id", "")).to_lower():
			"normal":
				_unlock_achievement(progress, "ACH_NORMAL_MONTH")
			"grind":
				_unlock_achievement(progress, "ACH_GRIND_MONTH")
	if bool(payload.get("held_major_down_move", false)) and float(payload.get("cash", 0.0)) >= 0.0:
		_unlock_achievement(progress, "ACH_OPERATOR_SCARS")


func _evaluate_stat_achievements(progress: Dictionary) -> void:
	var stats: Dictionary = progress.get("stats", {})
	for achievement_value in achievement_definitions.values():
		var achievement: Dictionary = achievement_value
		var progress_stat: String = str(achievement.get("progress_stat", "")).strip_edges()
		var unlock_value: int = int(achievement.get("unlock_value", 0))
		var api_name: String = str(achievement.get("api_name", "")).strip_edges()
		if api_name.is_empty() or progress_stat.is_empty() or unlock_value <= 0:
			continue
		if int(stats.get(progress_stat, 0)) >= unlock_value:
			_unlock_achievement(progress, api_name)


func _backfill_from_run_state(progress: Dictionary) -> void:
	_set_stat(progress, "STAT_DAYS_SURVIVED", max(RunState.day_index, 0), true)
	_set_stat(progress, "STAT_THESES_CREATED", RunState.get_player_theses().size(), true)
	_set_stat(progress, "STAT_RESEARCH_EVIDENCE_CAPTURED", RunState.get_thesis_research_tray().size(), true)
	_set_stat(progress, "STAT_LIFE_PROPERTIES_PURCHASED", RunState.get_player_life().get("properties", []).size(), true)
	_set_stat(progress, "STAT_LIFE_CARS_PURCHASED", RunState.get_player_life().get("cars", []).size(), true)
	_set_stat(progress, "STAT_WATCHLIST_ADDS", RunState.get_watchlist_company_ids().size(), true)
	var purchased_upgrades: int = 0
	for track_id_value in RunState.UPGRADE_TRACK_IDS:
		purchased_upgrades += max(RunState.DEFAULT_UPGRADE_TIER - RunState.get_upgrade_tier(str(track_id_value)), 0)
	_set_stat(progress, "STAT_UPGRADES_PURCHASED", purchased_upgrades, true)
	var read_count: int = 0
	var read_sections: Dictionary = RunState.get_academy_progress().get("read_sections", {})
	for read_list_value in read_sections.values():
		if typeof(read_list_value) == TYPE_ARRAY:
			read_count += read_list_value.size()
	_set_stat(progress, "STAT_ACADEMY_LESSONS_COMPLETED", read_count, true)
	var passed_quizzes: int = 0
	for passed_value in RunState.get_academy_progress().get("quiz_passed", {}).values():
		if bool(passed_value):
			passed_quizzes += 1
	_set_stat(progress, "STAT_ACADEMY_QUIZZES_PASSED", passed_quizzes, true)
	var met_count: int = 0
	for contact_value in RunState.get_network_contacts().values():
		if typeof(contact_value) == TYPE_DICTIONARY and bool(contact_value.get("met", false)):
			met_count += 1
	_set_stat(progress, "STAT_NETWORK_CONTACTS_MET", met_count, true)
	_set_stat(progress, "STAT_RUPSLB_ATTENDED", RunState.attended_meetings.size(), true)
	var meta: Dictionary = progress.get("meta", {}).duplicate(true)
	var equity: float = RunState.get_total_equity()
	if float(meta.get("equity_peak", 0.0)) <= 0.0:
		meta["equity_peak"] = equity
	if float(meta.get("last_equity", 0.0)) <= 0.0:
		meta["last_equity"] = equity
	if str(meta.get("month_key", "")).is_empty():
		meta["month_key"] = _month_key(RunState.current_trade_date)
		meta["month_start_equity"] = equity
	progress["meta"] = meta


func _increment_event_count(progress: Dictionary, event_id: String, count: int) -> void:
	var event_counts: Dictionary = progress.get("event_counts", {}).duplicate(true)
	event_counts[event_id] = int(event_counts.get(event_id, 0)) + count
	progress["event_counts"] = event_counts


func _increment_stat(progress: Dictionary, api_name: String, delta: int) -> void:
	if delta <= 0:
		return
	var stats: Dictionary = progress.get("stats", {}).duplicate(true)
	stats[api_name] = max(int(stats.get(api_name, 0)) + delta, 0)
	progress["stats"] = stats
	dirty_stat_names[api_name] = true


func _set_stat(progress: Dictionary, api_name: String, value: int, max_only: bool = false) -> void:
	var stats: Dictionary = progress.get("stats", {}).duplicate(true)
	var normalized_value: int = max(value, 0)
	var current_value: int = int(stats.get(api_name, 0))
	if max_only:
		normalized_value = max(current_value, normalized_value)
	if current_value == normalized_value:
		progress["stats"] = stats
		return
	stats[api_name] = normalized_value
	progress["stats"] = stats
	dirty_stat_names[api_name] = true


func _unlock_achievement(progress: Dictionary, api_name: String) -> void:
	if api_name.is_empty():
		return
	var achievements: Dictionary = progress.get("achievements", {}).duplicate(true)
	if bool(achievements.get(api_name, false)):
		progress["achievements"] = achievements
		return
	achievements[api_name] = true
	progress["achievements"] = achievements
	dirty_achievement_names[api_name] = true


func _push_stat(api_name: String, value: int) -> bool:
	if api_name.is_empty():
		return false
	var definition: Dictionary = stat_definitions.get(api_name, {})
	var stat_type: String = str(definition.get("type", "INT")).to_upper()
	var result: Variant = null
	if stat_type == "FLOAT":
		result = _call_steam_first(STAT_FLOAT_SETTER_METHODS, [api_name, float(value)], null)
	else:
		result = _call_steam_first(STAT_SETTER_METHODS, [api_name, value], null)
	return result != null and (typeof(result) != TYPE_BOOL or bool(result))


func _push_achievement(api_name: String) -> bool:
	if api_name.is_empty():
		return false
	var result: Variant = _call_steam_first(ACHIEVEMENT_SETTER_METHODS, [api_name], null)
	return result != null and (typeof(result) != TYPE_BOOL or bool(result))


func _call_steam_first(method_names: Array, arguments: Array = [], fallback: Variant = null) -> Variant:
	if not has_node("/root/SteamManager"):
		return fallback
	var steam_manager = get_node("/root/SteamManager")
	if steam_manager.has_method("call_first_available"):
		return steam_manager.call_first_available(method_names, arguments, fallback)
	var steam_api = steam_manager.get_steam_api() if steam_manager.has_method("get_steam_api") else null
	if steam_api == null:
		return fallback
	for method_value in method_names:
		var method_name: String = str(method_value)
		if steam_api.has_method(method_name):
			return steam_api.callv(method_name, arguments)
	return fallback


func _steam_enabled() -> bool:
	if not bool(ProjectSettings.get_setting(STORE_ENABLED_SETTING, true)):
		return false
	if not has_node("/root/SteamManager"):
		return false
	var steam_manager = get_node("/root/SteamManager")
	if steam_manager.has_method("is_steam_enabled"):
		return bool(steam_manager.is_steam_enabled())
	return false


func _has_run_state() -> bool:
	return has_node("/root/RunState")


func _held_major_down_move() -> bool:
	if not _has_run_state() or not RunState.has_active_run():
		return false
	var holdings: Dictionary = RunState.player_portfolio.get("holdings", {})
	for company_id_value in holdings.keys():
		var company_id: String = str(company_id_value)
		var holding: Dictionary = holdings.get(company_id, {})
		if int(holding.get("shares", 0)) <= 0:
			continue
		var runtime: Dictionary = RunState.get_company(company_id)
		if float(runtime.get("daily_change_pct", 0.0)) <= OPERATOR_SCARS_DAILY_DROP:
			return true
	return false


func _month_key(trade_date_value: Variant) -> String:
	if typeof(trade_date_value) != TYPE_DICTIONARY:
		return ""
	var trade_date: Dictionary = trade_date_value
	var year: int = int(trade_date.get("year", 0))
	var month: int = int(trade_date.get("month", 0))
	if year <= 0 or month <= 0:
		return ""
	return "%04d-%02d" % [year, month]


func _event_should_flush_immediately(event_id: String) -> bool:
	return [
		"trade_placed",
		"profitable_sell",
		"watchlist_added",
		"news_article_read",
		"key_stats_inspected",
		"chart_pattern_claimed",
		"thesis_created",
		"upgrade_purchased",
		"network_contact_met",
		"network_tip_requested",
		"rupslb_attended",
		"academy_lesson_completed",
		"academy_quiz_passed"
	].has(event_id)
