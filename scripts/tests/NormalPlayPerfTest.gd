extends Node

const SMOKE_LOCAL_IO_ARG := "--smoke-local-io"
const RESULT_PATH := "res://logs/normal_play_perf_result.txt"

var results: Array = []


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

	await _measure_callable("flush_pending_save", Callable(SaveManager, "flush_pending_save"), 2)
	var save_size: int = _project_local_save_size()

	game_root.queue_free()
	await _settle_frames(2)

	var result_line: String = _build_result_line(save_size)
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


func _measure_callable(label: String, callable: Callable, settle_frames: int) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	callable.call()
	await _settle_frames(settle_frames)
	_record_result(label, started_at_usec)


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


func _project_local_save_size() -> int:
	if not OS.get_cmdline_user_args().has(SMOKE_LOCAL_IO_ARG):
		return -1
	var absolute_path: String = str(SaveManager.get_save_file_info().get("absolute_path", ProjectSettings.globalize_path("res://logs/saves/slot_1.json")))
	if not FileAccess.file_exists(absolute_path):
		return 0
	var file = FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return 0
	return int(file.get_length())


func _build_result_line(save_size: int) -> String:
	var parts: Array = ["NORMAL_PLAY_PERF_OK"]
	for row_value in results:
		var row: Dictionary = row_value
		parts.append("%s=%sms" % [
			str(row.get("label", "")),
			String.num(float(row.get("ms", 0.0)), 2)
		])
	parts.append("local_save_bytes=%d" % save_size)
	return " ".join(parts)


func _finish(success: bool, message: String) -> void:
	print(message)
	if OS.get_cmdline_user_args().has(SMOKE_LOCAL_IO_ARG):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://logs"))
		var result_file = FileAccess.open(RESULT_PATH, FileAccess.WRITE)
		if result_file != null:
			result_file.store_string(message)
	get_tree().quit(0 if success else 1)
