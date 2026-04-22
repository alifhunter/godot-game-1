extends Node

const SAVE_PATH := "user://daytrader_save.json"
const DEFAULT_REQUEST_DELAY_SECONDS := 0.35
const PERF_LOG_PREFIX := "[perf][save]"

var _save_timer: Timer = null
var _pending_reason: String = ""
func _ready() -> void:
	_ensure_save_timer()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func request_save(reason: String, delay_seconds: float = DEFAULT_REQUEST_DELAY_SECONDS) -> void:
	_ensure_save_timer()
	var started_at_usec: int = Time.get_ticks_usec()
	_pending_reason = reason.strip_edges()
	if _pending_reason.is_empty():
		_pending_reason = "unspecified"
	_save_timer.wait_time = max(delay_seconds, 0.001)
	_save_timer.stop()
	_save_timer.start()
	_log_elapsed("request_save:%s" % _pending_reason, started_at_usec)


func flush_pending_save() -> bool:
	_ensure_save_timer()
	if not has_pending_save():
		return true

	var flush_reason: String = _pending_reason
	_save_timer.stop()
	_pending_reason = ""
	return _save_current_run("flush_pending_save:%s" % flush_reason)


func has_pending_save() -> bool:
	return _save_timer != null and not _save_timer.is_stopped()


func save_run(run_state: Dictionary) -> bool:
	var started_at_usec: int = Time.get_ticks_usec()
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		push_error("Unable to open save file for writing.")
		return false

	save_file.store_string(JSON.stringify(run_state, "\t"))
	_log_elapsed("save_run", started_at_usec)
	return true


func load_run() -> Dictionary:
	if not has_save():
		return {}

	var raw_text = FileAccess.get_file_as_string(SAVE_PATH)
	var parsed = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save file is malformed.")
		return {}

	return parsed.duplicate(true)


func delete_save() -> void:
	if _save_timer != null:
		_save_timer.stop()
	_pending_reason = ""
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _ensure_save_timer() -> void:
	if _save_timer != null:
		return

	_save_timer = Timer.new()
	_save_timer.name = "PendingSaveTimer"
	_save_timer.one_shot = true
	_save_timer.autostart = false
	add_child(_save_timer)
	_save_timer.timeout.connect(_on_save_timer_timeout)


func _on_save_timer_timeout() -> void:
	var flush_reason: String = _pending_reason
	_pending_reason = ""
	_save_current_run("debounced:%s" % flush_reason)


func _save_current_run(context: String) -> bool:
	var started_at_usec: int = Time.get_ticks_usec()
	var saved: bool = save_run(RunState.to_save_dict())
	_log_elapsed(context, started_at_usec)
	return saved


func _log_elapsed(label: String, started_at_usec: int) -> void:
	if not OS.is_debug_build():
		return
	var elapsed_ms: float = float(Time.get_ticks_usec() - started_at_usec) / 1000.0
	print("%s %s %.2fms" % [PERF_LOG_PREFIX, label, elapsed_ms])
