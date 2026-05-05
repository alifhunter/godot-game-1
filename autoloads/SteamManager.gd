extends Node

signal status_changed(is_available: bool, is_initialized: bool)
signal runtime_info_refreshed(runtime_info: Dictionary)

const STEAM_SINGLETON_NAME := "Steam"
const APP_ID_SETTING := "steam/initialization/app_id"
const EMBED_CALLBACKS_SETTING := "steam/initialization/embed_callbacks"
const DEFAULT_TEST_APP_ID := 480

var steam_api: Object = null
var steam_available: bool = false
var steam_initialized: bool = false
var initialization_result: Dictionary = {}
var app_id: int = DEFAULT_TEST_APP_ID

var app_installed_depots: Array = []
var app_languages: String = ""
var app_owner: int = 0
var steam_app_build_id: int = 0
var game_language: String = ""
var install_dir: Dictionary = {}
var is_on_steam_deck: bool = false
var is_on_vr: bool = false
var is_online: bool = false
var is_owned: bool = false
var launch_command_line: String = ""
var steam_id: int = 0
var steam_username: String = ""
var ui_language: String = ""
var godotsteam_version: String = ""

var runtime_info: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	initialize_steam()


func _process(_delta: float) -> void:
	if not steam_available or steam_api == null:
		return
	if bool(ProjectSettings.get_setting(EMBED_CALLBACKS_SETTING, false)):
		return
	_call_steam("run_callbacks")


func initialize_steam(force_reinitialize: bool = false) -> Dictionary:
	app_id = get_configured_app_id()
	steam_api = _get_steam_singleton()
	steam_available = steam_api != null
	if not steam_available:
		steam_initialized = false
		initialization_result = {
			"status": -1,
			"verbal": "GodotSteam singleton is not available."
		}
		_clear_runtime_values()
		runtime_info = _build_runtime_info()
		status_changed.emit(steam_available, steam_initialized)
		runtime_info_refreshed.emit(runtime_info.duplicate(true))
		return initialization_result.duplicate(true)

	var cached_result: Dictionary = _get_cached_initialization_result()
	if not force_reinitialize and _has_status(cached_result):
		initialization_result = cached_result
	else:
		var raw_result: Variant = _call_steam("steamInitEx", [app_id, false], {})
		initialization_result = _normalize_initialization_result(raw_result)

	steam_initialized = int(initialization_result.get("status", -1)) == 0
	if steam_initialized:
		refresh_runtime_info()
	else:
		_clear_runtime_values()
		runtime_info = _build_runtime_info()
		runtime_info_refreshed.emit(runtime_info.duplicate(true))

	status_changed.emit(steam_available, steam_initialized)
	return initialization_result.duplicate(true)


func refresh_runtime_info() -> Dictionary:
	if not steam_available or steam_api == null:
		_clear_runtime_values()
		runtime_info = _build_runtime_info()
		runtime_info_refreshed.emit(runtime_info.duplicate(true))
		return runtime_info.duplicate(true)

	app_id = get_configured_app_id()
	app_installed_depots = _as_array(_call_steam("getInstalledDepots", [app_id], []))
	app_languages = str(_call_steam("getAvailableGameLanguages", [], ""))
	app_owner = int(_call_steam("getAppOwner", [], 0))
	steam_app_build_id = int(_call_steam("getAppBuildId", [], 0))
	game_language = str(_call_steam("getCurrentGameLanguage", [], ""))
	install_dir = _as_dictionary(_call_steam("getAppInstallDir", [app_id], {}))
	is_on_steam_deck = bool(_call_steam("isSteamRunningOnSteamDeck", [], false))
	is_on_vr = bool(_call_steam("isSteamRunningInVR", [], false))
	is_online = bool(_call_steam("loggedOn", [], false))
	is_owned = bool(_call_steam("isSubscribed", [], false))
	launch_command_line = str(_call_steam("getLaunchCommandLine", [], ""))
	steam_id = int(_call_steam("getSteamID", [], 0))
	steam_username = str(_call_steam("getPersonaName", [], ""))
	ui_language = str(_call_steam("getSteamUILanguage", [], ""))
	godotsteam_version = str(_call_steam("get_godotsteam_version", [], ""))
	runtime_info = _build_runtime_info()
	runtime_info_refreshed.emit(runtime_info.duplicate(true))
	return runtime_info.duplicate(true)


func is_steam_available() -> bool:
	return steam_available


func is_steam_initialized() -> bool:
	return steam_initialized


func is_steam_enabled() -> bool:
	return steam_available and steam_initialized


func get_initialization_result() -> Dictionary:
	return initialization_result.duplicate(true)


func get_runtime_info() -> Dictionary:
	return runtime_info.duplicate(true)


func get_steam_api() -> Object:
	return steam_api


func get_configured_app_id() -> int:
	return int(ProjectSettings.get_setting(APP_ID_SETTING, DEFAULT_TEST_APP_ID))


func get_steam_id() -> int:
	return steam_id


func get_steam_username() -> String:
	return steam_username


func get_steam_app_build_id() -> int:
	return steam_app_build_id


func owns_current_app() -> bool:
	return is_owned


func is_running_on_steam_deck() -> bool:
	return is_on_steam_deck


func get_status_summary() -> String:
	if not steam_available:
		return "Steam unavailable"
	if not steam_initialized:
		return "Steam initialization failed: %s" % str(initialization_result.get("verbal", "unknown"))
	if steam_username.strip_edges().is_empty():
		return "Steam ready"
	return "Steam ready: %s" % steam_username


func _get_steam_singleton() -> Object:
	if not Engine.has_singleton(STEAM_SINGLETON_NAME):
		return null
	return Engine.get_singleton(STEAM_SINGLETON_NAME)


func _get_cached_initialization_result() -> Dictionary:
	var raw_result: Variant = _call_steam("get_steam_init_result", [], {})
	if typeof(raw_result) == TYPE_DICTIONARY:
		return raw_result
	return {}


func _normalize_initialization_result(raw_result: Variant) -> Dictionary:
	if typeof(raw_result) == TYPE_DICTIONARY:
		return raw_result
	if typeof(raw_result) == TYPE_BOOL:
		return {
			"status": 0 if bool(raw_result) else 1,
			"verbal": "Steam initialized." if bool(raw_result) else "Steam initialization failed."
		}
	return {
		"status": 1,
		"verbal": str(raw_result)
	}


func _has_status(result: Dictionary) -> bool:
	return result.has("status")


func _call_steam(method_name: String, arguments: Array = [], fallback: Variant = null) -> Variant:
	if steam_api == null or not steam_api.has_method(method_name):
		return fallback
	return steam_api.callv(method_name, arguments)


func _as_array(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value
	return []


func _as_dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func _clear_runtime_values() -> void:
	app_installed_depots = []
	app_languages = ""
	app_owner = 0
	steam_app_build_id = 0
	game_language = ""
	install_dir = {}
	is_on_steam_deck = false
	is_on_vr = false
	is_online = false
	is_owned = false
	launch_command_line = ""
	steam_id = 0
	steam_username = ""
	ui_language = ""
	godotsteam_version = ""


func _build_runtime_info() -> Dictionary:
	return {
		"available": steam_available,
		"initialized": steam_initialized,
		"init_result": initialization_result.duplicate(true),
		"app_id": app_id,
		"app_installed_depots": app_installed_depots.duplicate(),
		"app_languages": app_languages,
		"app_owner": app_owner,
		"steam_app_build_id": steam_app_build_id,
		"game_language": game_language,
		"install_dir": install_dir.duplicate(true),
		"is_on_steam_deck": is_on_steam_deck,
		"is_on_vr": is_on_vr,
		"is_online": is_online,
		"is_owned": is_owned,
		"launch_command_line": launch_command_line,
		"steam_id": steam_id,
		"steam_username": steam_username,
		"ui_language": ui_language,
		"godotsteam_version": godotsteam_version,
		"status_summary": get_status_summary()
	}
