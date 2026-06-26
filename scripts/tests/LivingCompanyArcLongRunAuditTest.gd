extends Node

const DEFAULT_AUDIT_SEED := 20260615
const DEFAULT_AUDIT_DIFFICULTY := "normal"
const DEFAULT_AUDIT_DAYS := 120
const DEFAULT_COMPANY_COUNT := 50
const REPORT_PREFIX := "LIVING_COMPANY_ARC_LONG_RUN_AUDIT "
const MAX_COMPLETED_PER_COMPANY := 8
const MAX_RECENT_COMPLETED := 80
const MAX_RECENT_MEMORY_IDS := 12


func _ready() -> void:
	call_deferred("_run_audit_from_args")


func _run_audit_from_args() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var args: Array = OS.get_cmdline_user_args()
	var seed: int = _arg_int(args, "--living-arc-audit-seed", DEFAULT_AUDIT_SEED)
	var difficulty_id: String = _arg_string(args, "--living-arc-audit-difficulty", DEFAULT_AUDIT_DIFFICULTY)
	var trading_days: int = _arg_int(args, "--living-arc-audit-days", DEFAULT_AUDIT_DAYS)
	var use_catalog: bool = _arg_bool(args, "--living-arc-audit-use-catalog", true)
	var company_count: int = _arg_int(args, "--living-arc-audit-company-count", DEFAULT_COMPANY_COUNT)
	var started_at_usec: int = Time.get_ticks_usec()
	var report: Dictionary = _run_living_arc_audit(seed, difficulty_id, trading_days, use_catalog, company_count)
	report["audit_elapsed_msec"] = snappedf(float(Time.get_ticks_usec() - started_at_usec) / 1000.0, 0.001)
	print("%s%s" % [REPORT_PREFIX, JSON.stringify(report)])
	get_tree().quit(0 if bool(report.get("success", false)) else 1)


func _run_living_arc_audit(seed: int, difficulty_id: String, trading_days: int, use_catalog: bool, company_count: int) -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(difficulty_id)
	difficulty_id = str(difficulty_config.get("id", difficulty_id))
	if company_count > 0:
		difficulty_config["company_count"] = company_count
	if use_catalog:
		difficulty_config["use_company_universe_catalog"] = true

	var company_definitions: Array = GameManager.build_company_roster(seed, difficulty_config)
	if company_definitions.is_empty():
		return _failure_report(seed, difficulty_id, trading_days, use_catalog, company_count, "Generated an empty company roster.")

	RunState.setup_new_run(seed, company_definitions, difficulty_config, false)
	var opening_result: Dictionary = GameManager.simulate_opening_session(false)
	if opening_result.has("success") and not bool(opening_result.get("success", false)):
		return _failure_report(seed, difficulty_id, trading_days, use_catalog, company_count, str(opening_result.get("message", "Opening session failed.")))

	var tracker: Dictionary = _default_tracker()
	var opening_validation: String = _collect_living_state(tracker)
	if not opening_validation.is_empty():
		return _failure_report(seed, difficulty_id, trading_days, use_catalog, company_count, opening_validation)

	for _day_offset in range(max(trading_days, 0)):
		var advance_result: Dictionary = GameManager.call("_advance_day_internal", false, false, false)
		if advance_result.is_empty():
			return _failure_report(seed, difficulty_id, trading_days, use_catalog, company_count, "Advance returned an empty result.")
		if advance_result.has("success") and not bool(advance_result.get("success", false)):
			return _failure_report(seed, difficulty_id, trading_days, use_catalog, company_count, str(advance_result.get("message", "Advance failed.")))
		tracker["days_completed"] = int(tracker.get("days_completed", 0)) + 1
		_collect_day_result_events(advance_result.get("day_result", {}), tracker)
		var validation: String = _collect_living_state(tracker)
		if not validation.is_empty():
			return _failure_report(seed, difficulty_id, trading_days, use_catalog, company_count, validation)

	var living_report: Dictionary = _build_living_report(tracker)
	return {
		"success": true,
		"seed": seed,
		"difficulty_id": difficulty_id,
		"use_company_universe_catalog": bool(difficulty_config.get("use_company_universe_catalog", false)),
		"requested_trading_days": trading_days,
		"days_completed": int(tracker.get("days_completed", 0)),
		"final_day_index": RunState.day_index,
		"final_trade_date": RunState.get_current_trade_date(),
		"company_count": RunState.company_order.size(),
		"living_arcs": living_report,
		"event_counts": {
			"started_company_arcs": int(tracker.get("started_company_arcs", 0)),
			"company_arc_phase_events": int(tracker.get("company_arc_phase_events", 0)),
			"company_roadmap_events": int(tracker.get("company_roadmap_events", 0)),
			"corporate_action_events": int(tracker.get("corporate_action_events", 0)),
			"index_review_events": int(tracker.get("index_review_events", 0))
		}
	}


func _default_tracker() -> Dictionary:
	return {
		"days_completed": 0,
		"max_active_arc_count": 0,
		"max_active_company_count": 0,
		"max_cooldowned_companies": 0,
		"max_completed_rows_per_company": 0,
		"max_story_memory_recent_arc_ids": 0,
		"max_story_memory_recent_story_tags": 0,
		"status_stock_days": {},
		"started_company_arcs": 0,
		"company_arc_phase_events": 0,
		"company_roadmap_events": 0,
		"corporate_action_events": 0,
		"index_review_events": 0
	}


func _collect_day_result_events(day_result: Dictionary, tracker: Dictionary) -> void:
	tracker["started_company_arcs"] = int(tracker.get("started_company_arcs", 0)) + day_result.get("started_company_arcs", []).size()
	tracker["company_arc_phase_events"] = int(tracker.get("company_arc_phase_events", 0)) + day_result.get("company_arc_phase_events", []).size()
	tracker["company_roadmap_events"] = int(tracker.get("company_roadmap_events", 0)) + day_result.get("company_roadmap_events", []).size()
	tracker["corporate_action_events"] = int(tracker.get("corporate_action_events", 0)) + day_result.get("corporate_action_events", []).size()
	tracker["index_review_events"] = int(tracker.get("index_review_events", 0)) + day_result.get("index_review_events", []).size()


func _collect_living_state(tracker: Dictionary) -> String:
	var global_state: Dictionary = RunState.get_living_company_arc_state()
	var active_arc_ids: Array = global_state.get("active_arc_ids", [])
	var active_company_ids: Array = global_state.get("active_company_ids", [])
	var duplicate_error: String = _duplicate_check(active_arc_ids, "active arc ids")
	if not duplicate_error.is_empty():
		return duplicate_error
	duplicate_error = _duplicate_check(active_company_ids, "active company ids")
	if not duplicate_error.is_empty():
		return duplicate_error
	var active_arc_index: Dictionary = global_state.get("active_arc_index", {})
	if active_arc_index.size() != active_arc_ids.size():
		return "Living arc active index size does not match active arc ids."
	if global_state.get("recent_completed_arcs", []).size() > MAX_RECENT_COMPLETED:
		return "Living arc global recent completion history exceeded cap."

	tracker["max_active_arc_count"] = max(int(tracker.get("max_active_arc_count", 0)), active_arc_ids.size())
	tracker["max_active_company_count"] = max(int(tracker.get("max_active_company_count", 0)), active_company_ids.size())

	var cooldowned_companies: int = 0
	var day_index: int = RunState.day_index
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var company_state: Dictionary = RunState.get_company_living_arc_state(company_id)
		var completed_arcs: Array = company_state.get("completed_arcs", [])
		if completed_arcs.size() > MAX_COMPLETED_PER_COMPANY:
			return "Company %s exceeded completed living arc cap." % company_id
		tracker["max_completed_rows_per_company"] = max(int(tracker.get("max_completed_rows_per_company", 0)), completed_arcs.size())

		var story_memory: Dictionary = company_state.get("story_memory", {})
		var recent_arc_ids: Array = story_memory.get("recent_arc_ids", [])
		var recent_story_tags: Array = story_memory.get("recent_story_tags", [])
		if recent_arc_ids.size() > MAX_RECENT_MEMORY_IDS:
			return "Company %s exceeded living story-memory recent arc id cap." % company_id
		if recent_story_tags.size() > MAX_RECENT_MEMORY_IDS:
			return "Company %s exceeded living story-memory recent story tag cap." % company_id
		tracker["max_story_memory_recent_arc_ids"] = max(int(tracker.get("max_story_memory_recent_arc_ids", 0)), recent_arc_ids.size())
		tracker["max_story_memory_recent_story_tags"] = max(int(tracker.get("max_story_memory_recent_story_tags", 0)), recent_story_tags.size())

		var status: String = RunState.get_company_living_arc_status(company_id, day_index)
		_increment_dict(tracker["status_stock_days"], status)
		if _company_has_future_cooldown(company_state, day_index):
			cooldowned_companies += 1

	tracker["max_cooldowned_companies"] = max(int(tracker.get("max_cooldowned_companies", 0)), cooldowned_companies)
	return ""


func _build_living_report(tracker: Dictionary) -> Dictionary:
	var global_state: Dictionary = RunState.get_living_company_arc_state()
	var recent_completed: Array = global_state.get("recent_completed_arcs", [])
	var source_completion_counts: Dictionary = {}
	var tone_completion_counts: Dictionary = {}
	var event_completion_counts: Dictionary = {}
	for row_value in recent_completed:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		_increment_dict(source_completion_counts, str(row.get("source_system", "unknown")))
		_increment_dict(tone_completion_counts, str(row.get("tone", "neutral")))
		_increment_dict(event_completion_counts, str(row.get("event_id", "")))

	var active_count: int = 0
	var cooldown_count: int = 0
	var eligible_count: int = 0
	var suppressed_count: int = 0
	var stagnant_count: int = 0
	var repeat_company_count: int = 0
	var any_activity_count: int = 0
	var top_company_rows: Array = []
	var final_day_index: int = RunState.day_index
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var company_state: Dictionary = RunState.get_company_living_arc_state(company_id)
		var status: String = RunState.get_company_living_arc_status(company_id, final_day_index)
		if status == "active":
			active_count += 1
		elif status == "cooling_down":
			cooldown_count += 1
		elif status == "suppressed":
			suppressed_count += 1
		else:
			eligible_count += 1

		var story_memory: Dictionary = company_state.get("story_memory", {})
		var completed_count: int = int(story_memory.get("completed_count", company_state.get("completed_arcs", []).size()))
		var active_arc_id: String = str(company_state.get("active_arc_id", ""))
		var has_activity: bool = completed_count > 0 or not active_arc_id.is_empty() or _company_has_future_cooldown(company_state, final_day_index)
		if not has_activity:
			stagnant_count += 1
		else:
			any_activity_count += 1
		if completed_count > 1:
			repeat_company_count += 1
		if completed_count > 0 or not active_arc_id.is_empty():
			top_company_rows.append(_company_activity_row(company_id, company_state, completed_count, status))

	top_company_rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if int(left.get("completed_count", 0)) == int(right.get("completed_count", 0)):
			return str(left.get("ticker", "")) < str(right.get("ticker", ""))
		return int(left.get("completed_count", 0)) > int(right.get("completed_count", 0))
	)

	return {
		"global_completed_arc_count": int(global_state.get("completed_arc_count", 0)),
		"recent_completed_arc_count": recent_completed.size(),
		"active_arc_count": global_state.get("active_arc_ids", []).size(),
		"active_company_count": global_state.get("active_company_ids", []).size(),
		"final_status_counts": {
			"active": active_count,
			"cooling_down": cooldown_count,
			"eligible": eligible_count,
			"suppressed": suppressed_count
		},
		"max_active_arc_count": int(tracker.get("max_active_arc_count", 0)),
		"max_active_company_count": int(tracker.get("max_active_company_count", 0)),
		"max_cooldowned_companies": int(tracker.get("max_cooldowned_companies", 0)),
		"max_completed_rows_per_company": int(tracker.get("max_completed_rows_per_company", 0)),
		"max_story_memory_recent_arc_ids": int(tracker.get("max_story_memory_recent_arc_ids", 0)),
		"max_story_memory_recent_story_tags": int(tracker.get("max_story_memory_recent_story_tags", 0)),
		"status_stock_days": tracker.get("status_stock_days", {}),
		"companies_with_any_activity": any_activity_count,
		"stagnant_company_count": stagnant_count,
		"repeat_company_count": repeat_company_count,
		"source_completion_counts": source_completion_counts,
		"tone_completion_counts": tone_completion_counts,
		"top_event_completion_counts": _top_count_rows(event_completion_counts, 12),
		"top_company_activity": _limit_rows(top_company_rows, 10)
	}


func _company_activity_row(company_id: String, company_state: Dictionary, completed_count: int, status: String) -> Dictionary:
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	return {
		"company_id": company_id,
		"ticker": str(definition.get("ticker", company_id.to_upper())),
		"name": str(definition.get("name", company_id)),
		"status": status,
		"completed_count": completed_count,
		"last_source_system": str(company_state.get("story_memory", {}).get("last_source_system", "")),
		"last_arc_type": str(company_state.get("story_memory", {}).get("last_arc_type", "")),
		"last_event_id": str(company_state.get("story_memory", {}).get("last_event_id", "")),
		"active_source_system": str(company_state.get("active_source_system", "")),
		"active_event_id": str(company_state.get("active_event_id", "")),
		"completed_rows": company_state.get("completed_arcs", []).size()
	}


func _company_has_future_cooldown(company_state: Dictionary, day_index: int) -> bool:
	var cooldowns: Dictionary = company_state.get("cooldowns", {})
	for cooldown_key_value in cooldowns.keys():
		if int(cooldowns.get(cooldown_key_value, -999)) > day_index:
			return true
	return false


func _duplicate_check(values: Array, label: String) -> String:
	var seen: Dictionary = {}
	for value in values:
		var key: String = str(value)
		if seen.has(key):
			return "Living arc state has duplicate %s entry: %s." % [label, key]
		seen[key] = true
	return ""


func _top_count_rows(counts: Dictionary, limit: int) -> Array:
	var rows: Array = []
	for key_value in counts.keys():
		var key: String = str(key_value)
		if key.is_empty():
			continue
		rows.append({"id": key, "count": int(counts.get(key_value, 0))})
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if int(left.get("count", 0)) == int(right.get("count", 0)):
			return str(left.get("id", "")) < str(right.get("id", ""))
		return int(left.get("count", 0)) > int(right.get("count", 0))
	)
	return _limit_rows(rows, limit)


func _limit_rows(rows: Array, limit: int) -> Array:
	var output: Array = []
	for row_value in rows:
		if output.size() >= limit:
			break
		if typeof(row_value) == TYPE_DICTIONARY:
			output.append(row_value.duplicate(true))
	return output


func _increment_dict(counts: Dictionary, key_value: String) -> void:
	var key: String = key_value.strip_edges()
	if key.is_empty():
		key = "unknown"
	counts[key] = int(counts.get(key, 0)) + 1


func _failure_report(seed: int, difficulty_id: String, trading_days: int, use_catalog: bool, company_count: int, message: String) -> Dictionary:
	return {
		"success": false,
		"seed": seed,
		"difficulty_id": difficulty_id,
		"use_company_universe_catalog": use_catalog,
		"requested_trading_days": trading_days,
		"company_count": company_count,
		"final_day_index": RunState.day_index,
		"message": message
	}


func _arg_string(args: Array, key: String, fallback: String) -> String:
	var index: int = args.find(key)
	if index >= 0 and index + 1 < args.size():
		var value: String = str(args[index + 1]).strip_edges()
		if not value.is_empty():
			return value
	for arg_value in args:
		var arg: String = str(arg_value)
		if arg.begins_with("%s=" % key):
			var value: String = arg.substr(key.length() + 1).strip_edges()
			if not value.is_empty():
				return value
	return fallback


func _arg_int(args: Array, key: String, fallback: int) -> int:
	return int(_arg_string(args, key, str(fallback)))


func _arg_bool(args: Array, key: String, fallback: bool) -> bool:
	var index: int = args.find(key)
	if index >= 0:
		if index + 1 < args.size():
			var next_value: String = str(args[index + 1]).strip_edges().to_lower()
			if next_value in ["true", "1", "yes", "on"]:
				return true
			if next_value in ["false", "0", "no", "off"]:
				return false
		return true
	for arg_value in args:
		var arg: String = str(arg_value)
		if arg.begins_with("%s=" % key):
			var value: String = arg.substr(key.length() + 1).strip_edges().to_lower()
			if value in ["true", "1", "yes", "on"]:
				return true
			if value in ["false", "0", "no", "off"]:
				return false
	return fallback
