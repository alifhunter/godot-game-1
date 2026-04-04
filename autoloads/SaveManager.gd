extends Node

const SAVE_PATH := "user://daytrader_save.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_run(run_state: Dictionary) -> bool:
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		push_error("Unable to open save file for writing.")
		return false

	save_file.store_string(JSON.stringify(run_state, "\t"))
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
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
