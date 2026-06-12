class_name CompanyRuntime
extends RefCounted

# Typed wrapper for RunState.companies entries. Public save/runtime boundaries
# still use dictionaries; this class lets RunState migrate hot internals in
# small slices while preserving unknown fields during round-trips.

const KNOWN_FIELDS := [
	"company_id",
	"current_price",
	"previous_close",
	"starting_price",
	"ytd_open_price",
	"ytd_reference_year",
	"price_history",
	"price_bars",
	"sentiment",
	"active_event_tags",
	"active_events",
	"hidden_story_flags",
	"broker_flow",
	"broker_flow_history",
	"daily_change_pct",
	"market_depth_context",
	"player_market_impact",
	"company_profile",
	"ar_limits",
	"volume_context"
]

var company_id: String = ""
var current_price: float = 0.0
var previous_close: float = 0.0
var starting_price: float = 0.0
var ytd_open_price: float = 0.0
var ytd_reference_year: int = 2020
var price_history: Array = []
var price_bars: Array = []
var sentiment: float = 0.0
var active_event_tags: Array = []
var active_events: Array = []
var hidden_story_flags: Array = []
var broker_flow: Dictionary = {}
var broker_flow_history: Array = []
var daily_change_pct: float = 0.0
var market_depth_context: Dictionary = {}
var player_market_impact: Dictionary = {}
var company_profile: Dictionary = {}
var ar_limits: Dictionary = {}
var volume_context: Dictionary = {}
var _extra_data: Dictionary = {}
var _present_fields: Dictionary = {}


func load_from_dict(d: Dictionary) -> void:
	_reset()
	if d.is_empty():
		return

	for key_value in d.keys():
		var key: String = str(key_value)
		if KNOWN_FIELDS.has(key):
			_present_fields[key] = true
			continue
		var value = d[key_value]
		_extra_data[key] = value.duplicate(true) if _is_deep_copy_value(value) else value

	company_id = str(d.get("company_id", ""))
	current_price = float(d.get("current_price", 0.0))
	previous_close = float(d.get("previous_close", current_price))
	starting_price = float(d.get("starting_price", current_price))
	ytd_open_price = float(d.get("ytd_open_price", starting_price))
	ytd_reference_year = int(d.get("ytd_reference_year", 2020))
	price_history = _array_copy(d.get("price_history", []), true)
	price_bars = _array_copy(d.get("price_bars", []), true)
	sentiment = float(d.get("sentiment", 0.0))
	active_event_tags = _array_copy(d.get("active_event_tags", []), false)
	active_events = _array_copy(d.get("active_events", []), true)
	hidden_story_flags = _array_copy(d.get("hidden_story_flags", []), false)
	broker_flow = _dict_copy(d.get("broker_flow", {}), true)
	broker_flow_history = _array_copy(d.get("broker_flow_history", []), true)
	daily_change_pct = float(d.get("daily_change_pct", 0.0))
	market_depth_context = _dict_copy(d.get("market_depth_context", {}), true)
	player_market_impact = _dict_copy(d.get("player_market_impact", {}), true)
	company_profile = _dict_copy(d.get("company_profile", {}), true)
	ar_limits = _dict_copy(d.get("ar_limits", {}), true)
	volume_context = _dict_copy(d.get("volume_context", {}), true)


func to_dict() -> Dictionary:
	var d: Dictionary = _extra_data.duplicate(true)
	if _has_field("company_id") or not company_id.is_empty():
		d["company_id"] = company_id
	if _has_field("current_price"):
		d["current_price"] = current_price
	if _has_field("previous_close"):
		d["previous_close"] = previous_close
	if _has_field("starting_price"):
		d["starting_price"] = starting_price
	if _has_field("ytd_open_price"):
		d["ytd_open_price"] = ytd_open_price
	if _has_field("ytd_reference_year"):
		d["ytd_reference_year"] = ytd_reference_year
	if _has_field("price_history"):
		d["price_history"] = price_history.duplicate(true)
	if _has_field("price_bars"):
		d["price_bars"] = price_bars.duplicate(true)
	if _has_field("sentiment"):
		d["sentiment"] = sentiment
	if _has_field("active_event_tags"):
		d["active_event_tags"] = active_event_tags.duplicate()
	if _has_field("active_events"):
		d["active_events"] = active_events.duplicate(true)
	if _has_field("hidden_story_flags"):
		d["hidden_story_flags"] = hidden_story_flags.duplicate()
	if _has_field("broker_flow"):
		d["broker_flow"] = broker_flow.duplicate(true)
	if _has_field("broker_flow_history"):
		d["broker_flow_history"] = broker_flow_history.duplicate(true)
	if _has_field("daily_change_pct"):
		d["daily_change_pct"] = daily_change_pct
	if _has_field("market_depth_context"):
		d["market_depth_context"] = market_depth_context.duplicate(true)
	if _has_field("player_market_impact"):
		d["player_market_impact"] = player_market_impact.duplicate(true)
	if _has_field("company_profile"):
		d["company_profile"] = company_profile.duplicate(true)
	if _has_field("ar_limits"):
		d["ar_limits"] = ar_limits.duplicate(true)
	if _has_field("volume_context"):
		d["volume_context"] = volume_context.duplicate(true)
	return d


func is_empty() -> bool:
	return company_id.is_empty() and _present_fields.is_empty() and _extra_data.is_empty()


func profile_detail_status(default_status: String = "ready") -> String:
	if company_profile.is_empty():
		return ""
	return str(company_profile.get("detail_status", default_status))


func has_profile() -> bool:
	return not company_profile.is_empty()


func profile_dict() -> Dictionary:
	return company_profile.duplicate(true)


func set_profile(next_profile: Dictionary) -> void:
	_present_fields["company_profile"] = true
	company_profile = next_profile.duplicate(true)


func market_depth_dict() -> Dictionary:
	return market_depth_context.duplicate(true)


func set_market_depth(next_context: Dictionary) -> void:
	_present_fields["market_depth_context"] = true
	market_depth_context = next_context.duplicate(true)


func get_field(key: String, default_value = null):
	match key:
		"company_id":
			return company_id
		"current_price":
			return current_price
		"previous_close":
			return previous_close
		"starting_price":
			return starting_price
		"ytd_open_price":
			return ytd_open_price
		"ytd_reference_year":
			return ytd_reference_year
		"price_history":
			return price_history
		"price_bars":
			return price_bars
		"sentiment":
			return sentiment
		"active_event_tags":
			return active_event_tags
		"active_events":
			return active_events
		"hidden_story_flags":
			return hidden_story_flags
		"broker_flow":
			return broker_flow
		"broker_flow_history":
			return broker_flow_history
		"daily_change_pct":
			return daily_change_pct
		"market_depth_context":
			return market_depth_context
		"player_market_impact":
			return player_market_impact
		"company_profile":
			return company_profile
		"ar_limits":
			return ar_limits
		"volume_context":
			return volume_context
		_:
			return _extra_data.get(key, default_value)


func set_field(key: String, value) -> void:
	match key:
		"company_id":
			_present_fields[key] = true
			company_id = str(value)
		"current_price":
			_present_fields[key] = true
			current_price = float(value)
		"previous_close":
			_present_fields[key] = true
			previous_close = float(value)
		"starting_price":
			_present_fields[key] = true
			starting_price = float(value)
		"ytd_open_price":
			_present_fields[key] = true
			ytd_open_price = float(value)
		"ytd_reference_year":
			_present_fields[key] = true
			ytd_reference_year = int(value)
		"price_history":
			_present_fields[key] = true
			price_history = _array_copy(value, true)
		"price_bars":
			_present_fields[key] = true
			price_bars = _array_copy(value, true)
		"sentiment":
			_present_fields[key] = true
			sentiment = float(value)
		"active_event_tags":
			_present_fields[key] = true
			active_event_tags = _array_copy(value, false)
		"active_events":
			_present_fields[key] = true
			active_events = _array_copy(value, true)
		"hidden_story_flags":
			_present_fields[key] = true
			hidden_story_flags = _array_copy(value, false)
		"broker_flow":
			_present_fields[key] = true
			broker_flow = _dict_copy(value, true)
		"broker_flow_history":
			_present_fields[key] = true
			broker_flow_history = _array_copy(value, true)
		"daily_change_pct":
			_present_fields[key] = true
			daily_change_pct = float(value)
		"market_depth_context":
			_present_fields[key] = true
			market_depth_context = _dict_copy(value, true)
		"player_market_impact":
			_present_fields[key] = true
			player_market_impact = _dict_copy(value, true)
		"company_profile":
			_present_fields[key] = true
			company_profile = _dict_copy(value, true)
		"ar_limits":
			_present_fields[key] = true
			ar_limits = _dict_copy(value, true)
		"volume_context":
			_present_fields[key] = true
			volume_context = _dict_copy(value, true)
		_:
			_extra_data[key] = value.duplicate(true) if _is_deep_copy_value(value) else value


static func _array_copy(value, deep: bool) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	return value.duplicate(deep)


static func _dict_copy(value, deep: bool) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return value.duplicate(deep)


static func _is_deep_copy_value(value) -> bool:
	return typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY


func _has_field(key: String) -> bool:
	return _present_fields.has(key)


func _reset() -> void:
	company_id = ""
	current_price = 0.0
	previous_close = 0.0
	starting_price = 0.0
	ytd_open_price = 0.0
	ytd_reference_year = 2020
	price_history = []
	price_bars = []
	sentiment = 0.0
	active_event_tags = []
	active_events = []
	hidden_story_flags = []
	broker_flow = {}
	broker_flow_history = []
	daily_change_pct = 0.0
	market_depth_context = {}
	player_market_impact = {}
	company_profile = {}
	ar_limits = {}
	volume_context = {}
	_extra_data = {}
	_present_fields = {}
