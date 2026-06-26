extends Node

const SMOKE_LOCAL_IO_ARG := "--smoke-local-io"
const RESULT_PATH := "res://logs/normal_play_perf_result.txt"
const EXPECTED_ADVANCE_VALUATION_REFRESHES := 4
const MAX_SHORT_RUN_SAVE_BYTES := 4000000
const MAX_SCHEDULED_SAVE_FLUSH_MS := 900.0
const SAVE_SECTION_KEYS := [
	"companies",
	"company_story_dossier_state",
	"quarterly_report_calendar",
	"news_archive_articles",
	"event_history"
]
const TOP_COMPANY_PAYLOAD_COUNT := 5

var results: Array = []
var advance_day_portfolio_refresh_metrics: Dictionary = {}
var advance_day_deferred_refresh_metrics: Dictionary = {}
var advance_day_save_flush_metrics: Dictionary = {}


func _ready() -> void:
	call_deferred("_run_perf_pass")


func _run_perf_pass() -> void:
	DataRepository.reload_all()
	if OS.get_cmdline_user_args().has(SMOKE_LOCAL_IO_ARG):
		SaveManager.delete_save()

	var run_seed: int = 246810
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(run_seed, difficulty_config)
	RunState.setup_new_run(run_seed, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)

	var game_root = load("res://scenes/game/GameRoot.tscn").instantiate()
	add_child(game_root)
	await _settle_frames(4)
	await _wait_for_background_hydration()

	var network_button: Button = game_root.find_child("NetworkAppButton", true, false) as Button
	var stock_button: Button = game_root.find_child("StockAppButton", true, false) as Button
	var news_button: Button = game_root.find_child("NewsAppButton", true, false) as Button
	var advance_button: Button = game_root.find_child("DesktopAdvanceDayButton", true, false) as Button
	if network_button == null or stock_button == null or news_button == null or advance_button == null:
		_finish(false, "NORMAL_PLAY_PERF_FAIL missing desktop buttons")
		return

	await _measure_button("open_network", network_button, 3)
	await _measure_advance_button("advance_network_open", advance_button, game_root, 4)
	game_root.close_desktop_app("network")
	await _settle_frames(2)

	await _measure_advance_button("advance_desktop_only", advance_button, game_root, 4)
	await _measure_button("open_stock", stock_button, 4)
	await _measure_advance_button("advance_stock_open", advance_button, game_root, 4)
	game_root.close_desktop_app("stock")
	await _settle_frames(2)

	await _measure_button("open_news", news_button, 3)
	await _measure_button("open_network_with_news", network_button, 3)
	await _measure_advance_button("advance_news_network_open", advance_button, game_root, 4)

	var portfolio_refresh_error: String = _advance_day_portfolio_refresh_error(game_root)
	if not portfolio_refresh_error.is_empty():
		_finish(false, "NORMAL_PLAY_PERF_FAIL %s" % portfolio_refresh_error)
		return
	var deferred_refresh_error: String = _advance_day_deferred_refresh_error(game_root)
	if not deferred_refresh_error.is_empty():
		_finish(false, "NORMAL_PLAY_PERF_FAIL %s" % deferred_refresh_error)
		return

	await _wait_for_post_recap_save_flush("post_recap_save_flush", game_root, 180)
	var save_flush_error: String = _advance_day_save_flush_error(game_root)
	if not save_flush_error.is_empty():
		_finish(false, "NORMAL_PLAY_PERF_FAIL %s" % save_flush_error)
		return

	await _measure_callable("flush_pending_save", Callable(SaveManager, "flush_pending_save"), 2)
	var save_metrics: Dictionary = _build_save_metrics()
	var save_size_error: String = _save_size_budget_error(save_metrics)
	if not save_size_error.is_empty():
		_finish(false, "NORMAL_PLAY_PERF_FAIL %s" % save_size_error)
		return

	game_root.queue_free()
	await _settle_frames(2)

	var result_line: String = _build_result_line(save_metrics)
	_finish(true, result_line)


func _measure_button(label: String, button: Button, settle_frames: int) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	button.emit_signal("pressed")
	await _settle_frames(settle_frames)
	_record_result(label, started_at_usec)


func _measure_advance_button(label: String, button: Button, game_root: Node, settle_frames: int) -> void:
	var recap_dialog: Control = game_root.find_child("DailyRecapDialog", true, false) as Control
	if recap_dialog != null:
		recap_dialog.visible = false
	var starting_day_index: int = RunState.day_index
	var started_at_usec: int = Time.get_ticks_usec()
	button.emit_signal("pressed")
	for _frame_index in range(90):
		recap_dialog = game_root.find_child("DailyRecapDialog", true, false) as Control
		if RunState.day_index > starting_day_index and recap_dialog != null and recap_dialog.visible and not button.disabled:
			break
		await get_tree().process_frame
	_record_result("%s_recap_ready" % label, started_at_usec)
	await _settle_frames(settle_frames)
	_record_result(label, started_at_usec)
	await _dismiss_daily_recap_and_wait_for_deferred_refresh(label, game_root, settle_frames)


func _measure_callable(label: String, callable: Callable, settle_frames: int) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	callable.call()
	await _settle_frames(settle_frames)
	_record_result(label, started_at_usec)


func _wait_for_post_recap_save_flush(label: String, game_root: Node, max_frames: int) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	for _frame_index in range(max(max_frames, 1)):
		var metrics: Dictionary = _read_advance_day_save_flush_metrics(game_root)
		if not bool(metrics.get("pending_save", false)) and not bool(metrics.get("scheduled", false)):
			break
		await get_tree().process_frame
	await _settle_frames(2)
	_record_result(label, started_at_usec)


func _dismiss_daily_recap_and_wait_for_deferred_refresh(label: String, game_root: Node, settle_frames: int) -> void:
	var recap_dialog: Control = game_root.find_child("DailyRecapDialog", true, false) as Control
	if recap_dialog == null or not recap_dialog.visible:
		return
	var continue_button: Button = game_root.find_child("DailyRecapContinueButton", true, false) as Button
	if continue_button == null:
		_finish(false, "NORMAL_PLAY_PERF_FAIL missing daily recap continue button")
		return
	var started_at_usec: int = Time.get_ticks_usec()
	continue_button.emit_signal("pressed")
	for _frame_index in range(120):
		var metrics: Dictionary = _read_advance_day_deferred_refresh_metrics(game_root)
		var queue_size: int = int(metrics.get("queue_size", 0))
		var is_scheduled: bool = bool(metrics.get("scheduled", false))
		var recap_visible: bool = recap_dialog != null and recap_dialog.visible
		if not recap_visible and queue_size == 0 and not is_scheduled:
			break
		await get_tree().process_frame
	await _settle_frames(settle_frames)
	_record_result("%s_post_recap_refresh" % label, started_at_usec)


func _advance_day_portfolio_refresh_error(game_root: Node) -> String:
	if not game_root.has_method("get_advance_day_portfolio_refresh_metrics"):
		return "missing advance-day portfolio refresh metrics"
	var metrics: Dictionary = game_root.get_advance_day_portfolio_refresh_metrics()
	advance_day_portfolio_refresh_metrics = metrics.duplicate(true)
	var full_refresh_count: int = int(metrics.get("full_refresh_count", 0))
	var light_refresh_count: int = int(metrics.get("light_refresh_count", 0))
	if full_refresh_count > 0:
		return "guarded Advance Day used full portfolio refresh count=%d" % full_refresh_count
	if light_refresh_count < EXPECTED_ADVANCE_VALUATION_REFRESHES:
		return "guarded Advance Day light portfolio refresh count=%d expected>=%d" % [
			light_refresh_count,
			EXPECTED_ADVANCE_VALUATION_REFRESHES
		]
	if bool(metrics.get("guard_active", false)):
		return "advance-day portfolio refresh guard stayed active"
	return ""


func _read_advance_day_deferred_refresh_metrics(game_root: Node) -> Dictionary:
	if not game_root.has_method("get_advance_day_deferred_refresh_metrics"):
		return {}
	return game_root.get_advance_day_deferred_refresh_metrics()


func _advance_day_deferred_refresh_error(game_root: Node) -> String:
	if not game_root.has_method("get_advance_day_deferred_refresh_metrics"):
		return "missing advance-day deferred refresh metrics"
	var metrics: Dictionary = _read_advance_day_deferred_refresh_metrics(game_root)
	advance_day_deferred_refresh_metrics = metrics.duplicate(true)
	var queue_size: int = int(metrics.get("queue_size", 0))
	var is_scheduled: bool = bool(metrics.get("scheduled", false))
	var refreshed_count: int = int(metrics.get("refreshed_count", 0))
	var queued_count: int = int(metrics.get("queued_count", 0))
	if queue_size > 0:
		return "advance-day deferred refresh queue not drained size=%d" % queue_size
	if is_scheduled:
		return "advance-day deferred refresh stayed scheduled"
	if refreshed_count < EXPECTED_ADVANCE_VALUATION_REFRESHES:
		return "advance-day deferred open-app refresh count=%d expected>=%d" % [
			refreshed_count,
			EXPECTED_ADVANCE_VALUATION_REFRESHES
		]
	if queued_count < refreshed_count:
		return "advance-day deferred queued count=%d below refreshed count=%d" % [
			queued_count,
			refreshed_count
		]
	var app_counts_value = metrics.get("app_refresh_counts", {})
	if typeof(app_counts_value) == TYPE_DICTIONARY:
		var app_counts: Dictionary = app_counts_value
		for app_id_value in app_counts.keys():
			var app_count: int = int(app_counts.get(app_id_value, 0))
			if app_count > EXPECTED_ADVANCE_VALUATION_REFRESHES:
				return "advance-day app %s refreshed too often count=%d" % [
					str(app_id_value),
					app_count
				]
	return ""


func _read_advance_day_save_flush_metrics(game_root: Node) -> Dictionary:
	if not game_root.has_method("get_advance_day_save_flush_metrics"):
		return {}
	return game_root.get_advance_day_save_flush_metrics()


func _advance_day_save_flush_error(game_root: Node) -> String:
	if not game_root.has_method("get_advance_day_save_flush_metrics"):
		return "missing advance-day save flush metrics"
	var metrics: Dictionary = _read_advance_day_save_flush_metrics(game_root)
	advance_day_save_flush_metrics = metrics.duplicate(true)
	if bool(metrics.get("pending_save", false)):
		return "advance-day save stayed pending after post-recap scheduler"
	if bool(metrics.get("scheduled", false)):
		return "advance-day save flush scheduler stayed active"
	if int(metrics.get("completed_count", 0)) <= 0:
		return "advance-day save flush never completed"
	var last_ms: float = float(metrics.get("last_ms", 0.0))
	if last_ms > MAX_SCHEDULED_SAVE_FLUSH_MS:
		return "advance-day scheduled save flush %.2fms exceeded %.2fms" % [
			last_ms,
			MAX_SCHEDULED_SAVE_FLUSH_MS
		]
	return ""


func _save_size_budget_error(save_metrics: Dictionary) -> String:
	var save_size: int = int(save_metrics.get("local_save_bytes", -1))
	if save_size > MAX_SHORT_RUN_SAVE_BYTES:
		return "short-run save size %d exceeded %d" % [save_size, MAX_SHORT_RUN_SAVE_BYTES]
	return ""


func _record_result(label: String, started_at_usec: int) -> void:
	results.append({
		"label": label,
		"ms": float(Time.get_ticks_usec() - started_at_usec) / 1000.0
	})


func _settle_frames(frame_count: int) -> void:
	for _frame_index in range(max(frame_count, 0)):
		await get_tree().process_frame


func _wait_for_background_hydration() -> void:
	for _frame_index in range(90):
		if not GameManager.background_company_detail_hydration_running and not RunState.has_pending_company_detail_hydration():
			return
		await get_tree().process_frame


func _project_local_save_path() -> String:
	return str(SaveManager.get_save_file_info().get(
		"absolute_path",
		ProjectSettings.globalize_path("res://logs/saves/slot_1.json")
	))


func _project_local_save_size() -> int:
	if not OS.get_cmdline_user_args().has(SMOKE_LOCAL_IO_ARG):
		return -1
	var absolute_path: String = _project_local_save_path()
	if not FileAccess.file_exists(absolute_path):
		return 0
	var file = FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return 0
	return int(file.get_length())


func _read_project_local_save_dictionary() -> Dictionary:
	if not OS.get_cmdline_user_args().has(SMOKE_LOCAL_IO_ARG):
		return {}
	var absolute_path: String = _project_local_save_path()
	if not FileAccess.file_exists(absolute_path):
		return {}
	var file = FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed_value = JSON.parse_string(file.get_as_text())
	if typeof(parsed_value) != TYPE_DICTIONARY:
		return {}
	return parsed_value


func _json_byte_size(value: Variant) -> int:
	return JSON.stringify(value).to_utf8_buffer().size()


func _build_save_metrics() -> Dictionary:
	var save_size: int = _project_local_save_size()
	var save_data: Dictionary = _read_project_local_save_dictionary()
	var section_sizes: Dictionary = {}
	for section_key in SAVE_SECTION_KEYS:
		section_sizes[section_key] = _json_byte_size(save_data.get(section_key, null)) if save_data.has(section_key) else 0
	return {
		"local_save_bytes": save_size,
		"section_sizes": section_sizes,
		"broker_history": _build_broker_history_metrics(save_data.get("companies", {})),
		"largest_company_payloads": _largest_company_payloads(save_data.get("companies", {}))
	}


func _build_broker_history_metrics(companies_value: Variant) -> Dictionary:
	var metrics: Dictionary = {
		"company_count": 0,
		"min_rows": 0,
		"max_rows": 0,
		"avg_rows": 0.0,
		"total_history_bytes": 0,
		"avg_history_bytes_per_company": 0.0
	}
	if typeof(companies_value) != TYPE_DICTIONARY:
		return metrics
	var companies: Dictionary = companies_value
	var total_rows: int = 0
	var total_history_bytes: int = 0
	var min_rows: int = 0
	var max_rows: int = 0
	var company_count: int = 0
	for company_id_value in companies.keys():
		var runtime_value = companies.get(company_id_value, {})
		if typeof(runtime_value) != TYPE_DICTIONARY:
			continue
		var runtime: Dictionary = runtime_value
		var history_value = runtime.get("broker_flow_history", [])
		var row_count: int = history_value.size() if typeof(history_value) == TYPE_ARRAY else 0
		var history_bytes: int = _json_byte_size(history_value) if typeof(history_value) == TYPE_ARRAY else 0
		if company_count == 0:
			min_rows = row_count
			max_rows = row_count
		else:
			min_rows = min(min_rows, row_count)
			max_rows = max(max_rows, row_count)
		company_count += 1
		total_rows += row_count
		total_history_bytes += history_bytes
	metrics["company_count"] = company_count
	metrics["min_rows"] = min_rows
	metrics["max_rows"] = max_rows
	metrics["avg_rows"] = _round_to(float(total_rows) / float(max(company_count, 1)), 2)
	metrics["total_history_bytes"] = total_history_bytes
	metrics["avg_history_bytes_per_company"] = _round_to(float(total_history_bytes) / float(max(company_count, 1)), 2)
	return metrics


func _largest_company_payloads(companies_value: Variant) -> Array:
	var rows: Array = []
	if typeof(companies_value) != TYPE_DICTIONARY:
		return rows
	var companies: Dictionary = companies_value
	for company_id_value in companies.keys():
		var company_id: String = str(company_id_value)
		var runtime_value = companies.get(company_id_value, {})
		if typeof(runtime_value) != TYPE_DICTIONARY:
			continue
		var runtime: Dictionary = runtime_value
		rows.append({
			"company_id": company_id,
			"runtime_bytes": _json_byte_size(runtime),
			"broker_history_bytes": _json_byte_size(runtime.get("broker_flow_history", [])),
			"broker_history_rows": runtime.get("broker_flow_history", []).size() if typeof(runtime.get("broker_flow_history", [])) == TYPE_ARRAY else 0,
			"broker_flow_bytes": _json_byte_size(runtime.get("broker_flow", {})),
			"company_profile_bytes": _json_byte_size(runtime.get("company_profile", {}))
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("runtime_bytes", 0)) > int(b.get("runtime_bytes", 0))
	)
	if rows.size() > TOP_COMPANY_PAYLOAD_COUNT:
		rows = rows.slice(0, TOP_COMPANY_PAYLOAD_COUNT)
	return rows


func _timing_metrics() -> Dictionary:
	var metrics: Dictionary = {}
	for row_value in results:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		metrics[str(row.get("label", ""))] = _round_to(float(row.get("ms", 0.0)), 2)
	return metrics


func _round_to(value: float, decimals: int) -> float:
	var scale: float = pow(10.0, float(decimals))
	return round(value * scale) / scale


func _build_result_line(save_metrics: Dictionary) -> String:
	var structured_report: Dictionary = {
		"status": "NORMAL_PLAY_PERF_OK",
		"timings_ms": _timing_metrics(),
		"save_metrics": save_metrics,
		"advance_day_portfolio_refresh": advance_day_portfolio_refresh_metrics,
		"advance_day_deferred_refresh": advance_day_deferred_refresh_metrics,
		"advance_day_save_flush": advance_day_save_flush_metrics,
		"soft_budgets": {
			"advance_day_ms_target": 1200.0,
			"flush_pending_save_ms_target": 150.0,
			"short_run_save_bytes_target": 2500000
		},
		"guard_budgets": {
			"scheduled_save_flush_ms_max": MAX_SCHEDULED_SAVE_FLUSH_MS,
			"short_run_save_bytes_max": MAX_SHORT_RUN_SAVE_BYTES
		}
	}
	var parts: Array = ["NORMAL_PLAY_PERF_OK"]
	for row_value in results:
		var row: Dictionary = row_value
		parts.append("%s=%sms" % [
			str(row.get("label", "")),
			String.num(float(row.get("ms", 0.0)), 2)
		])
	parts.append("local_save_bytes=%d" % int(save_metrics.get("local_save_bytes", -1)))
	parts.append("metrics=%s" % JSON.stringify(structured_report))
	return " ".join(parts)


func _finish(success: bool, message: String) -> void:
	print(message)
	if OS.get_cmdline_user_args().has(SMOKE_LOCAL_IO_ARG):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://logs"))
		var result_file = FileAccess.open(RESULT_PATH, FileAccess.WRITE)
		if result_file != null:
			result_file.store_string(message)
	get_tree().quit(0 if success else 1)
