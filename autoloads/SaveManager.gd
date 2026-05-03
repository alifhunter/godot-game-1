extends Node

signal save_status_changed

const SAVE_PATH := "user://daytrader_save.json"
const SAVE_BACKUP_PATH := "user://daytrader_save.backup.json"
const SAVE_DIRECTORY_PATH := "user://saves"
const SAVE_CONFIG_PATH := "user://daytrader_save_config.json"
const SMOKE_SAVE_PATH := "res://logs/daytrader_smoke_save.json"
const SMOKE_BACKUP_PATH := "res://logs/daytrader_smoke_save.backup.json"
const SMOKE_SAVE_DIRECTORY_PATH := "res://logs/saves"
const SMOKE_SAVE_CONFIG_PATH := "res://logs/daytrader_save_config.json"
const SMOKE_LOCAL_IO_ARG := "--smoke-local-io"
const DEFAULT_REQUEST_DELAY_SECONDS := 0.35
const PERF_LOG_PREFIX := "[perf][save]"
const TEMP_SAVE_SUFFIX := ".tmp"
const SAVE_SLOT_COUNT := 5
const DEFAULT_SLOT_ID := "slot_1"

var _save_timer: Timer = null
var _pending_reason: String = ""
var _active_save_context: String = ""
var _last_save_unix: int = 0
var _last_save_reason: String = ""
var _last_load_error: String = ""
var _last_load_recovered_from_backup: bool = false
var _active_slot_id: String = DEFAULT_SLOT_ID
var _autosave_enabled: bool = true
var _has_unsaved_changes: bool = false
var _unsaved_reason: String = ""
var _unsaved_since_unix: int = 0
func _ready() -> void:
	_ensure_save_timer()
	_load_save_config()


func has_save(slot_id: String = "") -> bool:
	return FileAccess.file_exists(_read_save_path(slot_id)) or FileAccess.file_exists(_read_backup_path(slot_id))


func has_loadable_save(slot_id: String = "") -> bool:
	if slot_id.is_empty():
		return has_any_loadable_save()
	return bool(get_save_file_info(slot_id).get("loadable", false))


func has_any_loadable_save() -> bool:
	for slot_value in get_save_slots():
		var slot: Dictionary = slot_value
		if bool(slot.get("loadable", false)):
			return true
	return false


func get_active_slot_id() -> String:
	return _active_slot_id


func set_active_slot_id(slot_id: String) -> void:
	var normalized_slot_id: String = _normalize_slot_id(slot_id)
	if _active_slot_id == normalized_slot_id:
		return
	_active_slot_id = normalized_slot_id
	_save_save_config()
	save_status_changed.emit()


func prepare_slot_for_new_run() -> String:
	for index in range(1, SAVE_SLOT_COUNT + 1):
		var slot_id: String = "slot_%d" % index
		if not bool(get_save_file_info(slot_id).get("loadable", false)):
			set_active_slot_id(slot_id)
			return slot_id
	return _active_slot_id


func get_first_loadable_slot_id() -> String:
	for slot_value in get_save_slots():
		var slot: Dictionary = slot_value
		if bool(slot.get("loadable", false)):
			return str(slot.get("slot_id", DEFAULT_SLOT_ID))
	return ""


func get_save_slots() -> Array:
	var slots: Array = []
	for index in range(1, SAVE_SLOT_COUNT + 1):
		var slot_id: String = "slot_%d" % index
		var slot_info: Dictionary = get_save_file_info(slot_id)
		slot_info["slot_id"] = slot_id
		slot_info["slot_index"] = index
		slot_info["slot_label"] = "Slot %d" % index
		slot_info["active"] = slot_id == _active_slot_id
		slots.append(slot_info)
	return slots


func is_autosave_enabled() -> bool:
	return _autosave_enabled


func set_autosave_enabled(enabled: bool) -> void:
	if _autosave_enabled == enabled:
		return
	_autosave_enabled = enabled
	if not _autosave_enabled and _save_timer != null:
		_save_timer.stop()
		_pending_reason = ""
	_save_save_config()
	save_status_changed.emit()
	if _autosave_enabled and _has_unsaved_changes and RunState.has_active_run():
		request_save("autosave_reenabled")


func get_save_file_info(slot_id: String = "") -> Dictionary:
	var resolved_slot_id: String = _normalize_slot_id(slot_id)
	var primary_path: String = _read_save_path(resolved_slot_id)
	var backup_path: String = _read_backup_path(resolved_slot_id)
	var write_path: String = _write_save_path(resolved_slot_id)
	var write_backup_path: String = _write_backup_path(resolved_slot_id)
	var primary_exists: bool = FileAccess.file_exists(primary_path)
	var backup_exists: bool = FileAccess.file_exists(backup_path)
	var primary_data: Dictionary = _read_save_dictionary(primary_path, false)
	var backup_data: Dictionary = _read_save_dictionary(backup_path, false)
	var selected_data: Dictionary = primary_data
	var recovered_from_backup: bool = false
	if selected_data.is_empty() and not backup_data.is_empty():
		selected_data = backup_data
		recovered_from_backup = true

	var info := {
		"exists": primary_exists,
		"backup_exists": backup_exists,
		"valid": not primary_data.is_empty(),
		"backup_loadable": not backup_data.is_empty(),
		"loadable": not selected_data.is_empty(),
		"recovered_from_backup": recovered_from_backup,
		"slot_id": resolved_slot_id,
		"slot_index": _slot_index(resolved_slot_id),
		"slot_label": "Slot %d" % _slot_index(resolved_slot_id),
		"active": resolved_slot_id == _active_slot_id,
		"path": primary_path,
		"backup_path": backup_path,
		"write_path": write_path,
		"write_backup_path": write_backup_path,
		"absolute_path": ProjectSettings.globalize_path(primary_path),
		"backup_absolute_path": ProjectSettings.globalize_path(backup_path),
		"write_absolute_path": ProjectSettings.globalize_path(write_path),
		"write_backup_absolute_path": ProjectSettings.globalize_path(write_backup_path),
		"uses_smoke_path": _using_smoke_path(),
		"storage_label": _storage_label(),
		"load_error": ""
	}
	if primary_exists and primary_data.is_empty():
		info["load_error"] = "Primary save file is unreadable."
	elif not primary_exists and backup_exists and backup_data.is_empty():
		info["load_error"] = "Backup save file is unreadable."

	if not selected_data.is_empty():
		info.merge(_build_save_summary(selected_data), true)
	return info


func get_runtime_save_status() -> Dictionary:
	return {
		"pending": has_pending_save(),
		"pending_reason": _pending_reason,
		"unsaved": has_unsaved_changes(),
		"unsaved_reason": _unsaved_reason,
		"unsaved_since_unix": _unsaved_since_unix,
		"last_save_unix": _last_save_unix,
		"last_save_reason": _last_save_reason,
		"active_slot_id": _active_slot_id,
		"active_slot_label": "Slot %d" % _slot_index(_active_slot_id),
		"autosave_enabled": _autosave_enabled,
		"path": _write_save_path(),
		"absolute_path": ProjectSettings.globalize_path(_write_save_path()),
		"storage_label": _storage_label()
	}


func get_last_load_status() -> Dictionary:
	return {
		"error": _last_load_error,
		"recovered_from_backup": _last_load_recovered_from_backup
	}


func request_save(reason: String, delay_seconds: float = DEFAULT_REQUEST_DELAY_SECONDS) -> void:
	_ensure_save_timer()
	var started_at_usec: int = Time.get_ticks_usec()
	_mark_unsaved(reason)
	if not _autosave_enabled:
		_pending_reason = ""
		if _save_timer != null:
			_save_timer.stop()
		save_status_changed.emit()
		_log_elapsed("request_save:autosave_disabled:%s" % reason.strip_edges(), started_at_usec)
		return
	_pending_reason = reason.strip_edges()
	if _pending_reason.is_empty():
		_pending_reason = "unspecified"
	_save_timer.wait_time = max(delay_seconds, 0.001)
	_save_timer.stop()
	_save_timer.start()
	save_status_changed.emit()
	_log_elapsed("request_save:%s" % _pending_reason, started_at_usec)


func flush_pending_save() -> bool:
	_ensure_save_timer()
	if not has_pending_save():
		return true

	var flush_reason: String = _pending_reason
	_save_timer.stop()
	_pending_reason = ""
	save_status_changed.emit()
	return _save_current_run("flush_pending_save:%s" % flush_reason)


func has_pending_save() -> bool:
	return _save_timer != null and not _save_timer.is_stopped()


func has_unsaved_changes() -> bool:
	return _has_unsaved_changes or has_pending_save()


func get_unsaved_change_summary() -> Dictionary:
	return {
		"unsaved": has_unsaved_changes(),
		"reason": _pending_reason if has_pending_save() else _unsaved_reason,
		"since_unix": _unsaved_since_unix,
		"pending": has_pending_save(),
		"autosave_enabled": _autosave_enabled
	}


func save_current_run_now(reason: String = "manual", slot_id: String = "") -> bool:
	_ensure_save_timer()
	if _save_timer != null:
		_save_timer.stop()
	_pending_reason = ""
	save_status_changed.emit()
	return _save_current_run(reason, slot_id)


func save_run(run_state: Dictionary, slot_id: String = "") -> bool:
	var started_at_usec: int = Time.get_ticks_usec()
	var resolved_slot_id: String = _normalize_slot_id(slot_id)
	var save_payload: Dictionary = run_state.duplicate(true)
	save_payload["save_slot_id"] = resolved_slot_id
	save_payload["save_slot_label"] = "Slot %d" % _slot_index(resolved_slot_id)
	var save_path: String = _write_save_path(resolved_slot_id)
	var temp_path: String = _temp_save_path(resolved_slot_id)
	var backup_path: String = _write_backup_path(resolved_slot_id)
	_ensure_save_parent_dir_for_path(save_path)
	_ensure_save_parent_dir_for_path(temp_path)
	_ensure_save_parent_dir_for_path(backup_path)
	var save_file = FileAccess.open(temp_path, FileAccess.WRITE)
	if save_file == null:
		push_error("Unable to open save file for writing.")
		return false

	var serialize_started_at_usec: int = Time.get_ticks_usec()
	var save_text: String = JSON.stringify(save_payload)
	_log_elapsed("save_run:serialize", serialize_started_at_usec)
	var write_started_at_usec: int = Time.get_ticks_usec()
	save_file.store_string(save_text)
	save_file.flush()
	_log_elapsed("save_run:write", write_started_at_usec)
	save_file = null

	var absolute_save_path: String = ProjectSettings.globalize_path(save_path)
	var absolute_temp_path: String = ProjectSettings.globalize_path(temp_path)
	var absolute_backup_path: String = ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(save_path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(absolute_backup_path)
		var backup_error: int = DirAccess.copy_absolute(absolute_save_path, absolute_backup_path)
		if backup_error != OK:
			push_error("Unable to create save backup before writing. Error %d." % backup_error)
			DirAccess.remove_absolute(absolute_temp_path)
			return false

		var remove_error: int = DirAccess.remove_absolute(absolute_save_path)
		if remove_error != OK:
			push_error("Unable to replace existing save file. Error %d." % remove_error)
			DirAccess.remove_absolute(absolute_temp_path)
			return false

	var rename_error: int = DirAccess.rename_absolute(absolute_temp_path, absolute_save_path)
	if rename_error != OK:
		push_error("Unable to finalize save file. Error %d." % rename_error)
		return false

	_active_slot_id = resolved_slot_id
	_last_save_unix = int(save_payload.get("saved_at_unix", Time.get_unix_time_from_system()))
	_last_save_reason = _active_save_context if not _active_save_context.is_empty() else "manual"
	_clear_unsaved_state()
	_save_save_config()
	_log_elapsed("save_run", started_at_usec)
	save_status_changed.emit()
	return true


func load_run(slot_id: String = "") -> Dictionary:
	var started_at_usec: int = Time.get_ticks_usec()
	var resolved_slot_id: String = _normalize_slot_id(slot_id)
	_last_load_error = ""
	_last_load_recovered_from_backup = false
	if not has_save(resolved_slot_id):
		_log_elapsed("load_run:no_save", started_at_usec)
		return {}

	var parsed: Dictionary = _read_save_dictionary(_read_save_path(resolved_slot_id), true)
	if parsed.is_empty():
		var backup_data: Dictionary = _read_save_dictionary(_read_backup_path(resolved_slot_id), true)
		if backup_data.is_empty():
			push_error("Save file is malformed and no readable backup was available.")
			_log_elapsed("load_run", started_at_usec)
			save_status_changed.emit()
			return {}

		parsed = backup_data
		_last_load_recovered_from_backup = true
		_last_load_error = "Recovered from backup after the primary save failed to load."

	if int(parsed.get("saved_at_unix", 0)) > 0:
		_last_save_unix = int(parsed.get("saved_at_unix", 0))

	_active_slot_id = resolved_slot_id
	_clear_unsaved_state()
	_save_save_config()
	save_status_changed.emit()
	_log_elapsed("load_run", started_at_usec)
	return parsed.duplicate(true)


func delete_save(slot_id: String = "") -> void:
	if _save_timer != null:
		_save_timer.stop()
	_pending_reason = ""
	if _normalize_slot_id(slot_id) == _active_slot_id:
		_clear_unsaved_state()
	var resolved_slot_id: String = _normalize_slot_id(slot_id)
	for path in [
		_write_save_path(resolved_slot_id),
		_write_backup_path(resolved_slot_id),
		_temp_save_path(resolved_slot_id)
	]:
		if FileAccess.file_exists(str(path)):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(str(path)))
	if resolved_slot_id == DEFAULT_SLOT_ID:
		for legacy_path in [SAVE_PATH, SAVE_BACKUP_PATH, SMOKE_SAVE_PATH, SMOKE_BACKUP_PATH]:
			if FileAccess.file_exists(str(legacy_path)):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(str(legacy_path)))
	save_status_changed.emit()


func _mark_unsaved(reason: String) -> void:
	var clean_reason: String = reason.strip_edges()
	if clean_reason.is_empty():
		clean_reason = "unspecified"
	_has_unsaved_changes = true
	_unsaved_reason = clean_reason
	if _unsaved_since_unix <= 0:
		_unsaved_since_unix = int(Time.get_unix_time_from_system())


func _clear_unsaved_state() -> void:
	_has_unsaved_changes = false
	_unsaved_reason = ""
	_unsaved_since_unix = 0


func _write_save_path(slot_id: String = "") -> String:
	var resolved_slot_id: String = _normalize_slot_id(slot_id)
	return "%s/%s.json" % [_save_directory_path(), resolved_slot_id]


func _write_backup_path(slot_id: String = "") -> String:
	var resolved_slot_id: String = _normalize_slot_id(slot_id)
	return "%s/%s.backup.json" % [_save_directory_path(), resolved_slot_id]


func _read_save_path(slot_id: String = "") -> String:
	var resolved_slot_id: String = _normalize_slot_id(slot_id)
	var modern_path: String = _write_save_path(resolved_slot_id)
	if FileAccess.file_exists(modern_path):
		return modern_path
	if resolved_slot_id == DEFAULT_SLOT_ID:
		var legacy_path: String = SMOKE_SAVE_PATH if _using_smoke_path() else SAVE_PATH
		if FileAccess.file_exists(legacy_path):
			return legacy_path
	return modern_path


func _read_backup_path(slot_id: String = "") -> String:
	var resolved_slot_id: String = _normalize_slot_id(slot_id)
	var modern_path: String = _write_backup_path(resolved_slot_id)
	if FileAccess.file_exists(modern_path):
		return modern_path
	if resolved_slot_id == DEFAULT_SLOT_ID:
		var legacy_path: String = SMOKE_BACKUP_PATH if _using_smoke_path() else SAVE_BACKUP_PATH
		if FileAccess.file_exists(legacy_path):
			return legacy_path
	return modern_path


func _temp_save_path(slot_id: String = "") -> String:
	return "%s%s" % [_write_save_path(slot_id), TEMP_SAVE_SUFFIX]


func _save_directory_path() -> String:
	if _using_smoke_path():
		return SMOKE_SAVE_DIRECTORY_PATH
	return SAVE_DIRECTORY_PATH


func _config_path() -> String:
	if _using_smoke_path():
		return SMOKE_SAVE_CONFIG_PATH
	return SAVE_CONFIG_PATH


func _using_smoke_path() -> bool:
	return OS.get_cmdline_user_args().has(SMOKE_LOCAL_IO_ARG)


func _storage_label() -> String:
	return "Project-local smoke save" if _using_smoke_path() else "User save data"


func _ensure_save_parent_dir_for_path(save_path: String) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(save_path)
	var parent_path: String = absolute_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(parent_path)


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
	if not _autosave_enabled:
		save_status_changed.emit()
		return
	_save_current_run("debounced:%s" % flush_reason)


func _save_current_run(context: String, slot_id: String = "") -> bool:
	var started_at_usec: int = Time.get_ticks_usec()
	_active_save_context = context
	var saved: bool = save_run(RunState.to_save_dict(), slot_id)
	_active_save_context = ""
	_log_elapsed(context, started_at_usec)
	return saved


func _load_save_config() -> void:
	_active_slot_id = DEFAULT_SLOT_ID
	_autosave_enabled = true
	var config_path: String = _config_path()
	if not FileAccess.file_exists(config_path):
		return
	var raw_text: String = FileAccess.get_file_as_string(config_path)
	var json := JSON.new()
	if json.parse(raw_text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return
	var config: Dictionary = json.data
	_active_slot_id = _normalize_slot_id(str(config.get("active_slot_id", DEFAULT_SLOT_ID)))
	_autosave_enabled = bool(config.get("autosave_enabled", true))


func _save_save_config() -> void:
	var config_path: String = _config_path()
	_ensure_save_parent_dir_for_path(config_path)
	var config_file = FileAccess.open(config_path, FileAccess.WRITE)
	if config_file == null:
		return
	config_file.store_string(JSON.stringify({
		"active_slot_id": _active_slot_id,
		"autosave_enabled": _autosave_enabled
	}))
	config_file = null


func _normalize_slot_id(slot_id: String = "") -> String:
	var candidate: String = slot_id.strip_edges()
	if candidate.is_empty():
		candidate = _active_slot_id
	if candidate.begins_with("slot_"):
		var parsed_index: int = int(candidate.replace("slot_", ""))
		if parsed_index >= 1 and parsed_index <= SAVE_SLOT_COUNT:
			return "slot_%d" % parsed_index
	var as_index: int = int(candidate)
	if as_index >= 1 and as_index <= SAVE_SLOT_COUNT:
		return "slot_%d" % as_index
	return DEFAULT_SLOT_ID


func _slot_index(slot_id: String) -> int:
	var normalized_slot_id: String = _normalize_slot_id(slot_id)
	return clamp(int(normalized_slot_id.replace("slot_", "")), 1, SAVE_SLOT_COUNT)


func _read_save_dictionary(save_path: String, record_error: bool) -> Dictionary:
	if not FileAccess.file_exists(save_path):
		if record_error:
			_last_load_error = "Save file was not found at %s." % save_path
		return {}

	var read_started_at_usec: int = Time.get_ticks_usec()
	var raw_text: String = FileAccess.get_file_as_string(save_path)
	_log_elapsed("read_save_dictionary:read_file", read_started_at_usec)
	if raw_text.strip_edges().is_empty():
		if record_error:
			_last_load_error = "Save file at %s is empty." % save_path
		return {}

	var parse_started_at_usec: int = Time.get_ticks_usec()
	var json := JSON.new()
	var parse_error: int = json.parse(raw_text)
	_log_elapsed("read_save_dictionary:parse_json", parse_started_at_usec)
	if parse_error != OK:
		if record_error:
			_last_load_error = "Save file at %s is not valid JSON." % save_path
		return {}

	var parsed = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		if record_error:
			_last_load_error = "Save file at %s is not valid JSON." % save_path
		return {}
	return parsed.duplicate(true)


func _build_save_summary(data: Dictionary) -> Dictionary:
	var difficulty_config_value = data.get("difficulty_config", {})
	var saved_difficulty_config: Dictionary = difficulty_config_value if typeof(difficulty_config_value) == TYPE_DICTIONARY else {}
	var portfolio_value = data.get("player_portfolio", {})
	var portfolio: Dictionary = portfolio_value if typeof(portfolio_value) == TYPE_DICTIONARY else {}
	var cash: float = float(portfolio.get("cash", 0.0))
	var equity: float = float(data.get("last_equity_value", 0.0))
	if equity <= 0.0:
		equity = cash

	var schema_version: int = int(data.get("save_schema_version", 0))
	var format_id: String = str(data.get("save_format_id", "legacy_run" if schema_version <= 0 else ""))
	var day_index: int = int(data.get("day_index", 0))
	var trade_date_value = data.get("current_trade_date", {})
	var trade_date: Dictionary = trade_date_value if typeof(trade_date_value) == TYPE_DICTIONARY else {}
	return {
		"schema_version": schema_version,
		"format_id": format_id,
		"save_slot_id": str(data.get("save_slot_id", "")),
		"save_slot_label": str(data.get("save_slot_label", "")),
		"saved_at_unix": int(data.get("saved_at_unix", 0)),
		"saved_at_text": str(data.get("saved_at_text", "Unknown")),
		"seed": int(data.get("seed", 0)),
		"day_index": day_index,
		"trading_day": max(day_index + 1, 1),
		"trade_date_text": _format_trade_date_from_save(trade_date),
		"difficulty_id": str(data.get("difficulty_id", saved_difficulty_config.get("id", "normal"))),
		"difficulty_label": str(saved_difficulty_config.get("label", str(data.get("difficulty_id", "Normal")).capitalize())),
		"cash": cash,
		"cash_text": _format_currency(cash),
		"equity": equity,
		"equity_text": _format_currency(equity),
		"company_count": data.get("company_order", []).size() if typeof(data.get("company_order", [])) == TYPE_ARRAY else 0
	}


func _format_trade_date_from_save(trade_date: Dictionary) -> String:
	if trade_date.is_empty():
		return "Unknown date"
	var month_names := [
		"",
		"Jan",
		"Feb",
		"Mar",
		"Apr",
		"May",
		"Jun",
		"Jul",
		"Aug",
		"Sep",
		"Oct",
		"Nov",
		"Dec"
	]
	var month_index: int = clamp(int(trade_date.get("month", 1)), 1, 12)
	return "%s %d, %d" % [
		month_names[month_index],
		int(trade_date.get("day", 1)),
		int(trade_date.get("year", 2020))
	]


func _format_currency(value: float) -> String:
	return "%sRp%s" % [
		"-" if value < 0.0 else "",
		_format_decimal(absf(value), 2, true)
	]


func _format_decimal(value: float, decimal_places: int = 2, use_grouping: bool = true) -> String:
	var safe_places: int = max(decimal_places, 0)
	var decimal_scale: int = 1
	for _index in range(safe_places):
		decimal_scale *= 10
	var scaled_value: int = int(round(absf(value) * float(decimal_scale)))
	var whole_value: int = int(floor(float(scaled_value) / float(decimal_scale)))
	var decimal_value: int = scaled_value % decimal_scale
	var whole_text: String = _format_grouped_integer(whole_value) if use_grouping else str(whole_value)
	if safe_places <= 0:
		return whole_text
	var decimal_text: String = str(decimal_value)
	while decimal_text.length() < safe_places:
		decimal_text = "0" + decimal_text
	return "%s,%s" % [whole_text, decimal_text]


func _format_grouped_integer(value: int) -> String:
	var negative: bool = value < 0
	var digits: String = str(abs(value))
	var groups: Array = []
	while digits.length() > 3:
		groups.push_front(digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	if not digits.is_empty():
		groups.push_front(digits)
	var grouped_value: String = ".".join(groups)
	if grouped_value.is_empty():
		grouped_value = "0"
	return "-%s" % grouped_value if negative else grouped_value


func _log_elapsed(label: String, started_at_usec: int) -> void:
	if not OS.is_debug_build():
		return
	var elapsed_ms: float = float(Time.get_ticks_usec() - started_at_usec) / 1000.0
	print("%s %s %.2fms" % [PERF_LOG_PREFIX, label, elapsed_ms])
