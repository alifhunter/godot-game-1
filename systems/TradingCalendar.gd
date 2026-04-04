extends RefCounted

const HOLIDAY_DATA_PATH := "res://data/calendar/idx_holidays.json"
const START_DATE := {
	"year": 2020,
	"month": 1,
	"day": 2,
	"weekday": 3
}
const WEEKDAY_NAMES := ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
const MONTH_NAMES := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

var holidays_by_year: Dictionary = {}
var is_loaded: bool = false


func start_date() -> Dictionary:
	return START_DATE.duplicate(true)


func next_trade_date(date_info: Dictionary) -> Dictionary:
	var next_date: Dictionary = _sanitize_date(date_info)
	_increment_calendar_day(next_date)
	while not is_trade_day(next_date):
		_increment_calendar_day(next_date)
	return next_date


func previous_trade_date(date_info: Dictionary) -> Dictionary:
	var previous_date: Dictionary = _sanitize_date(date_info)
	_decrement_calendar_day(previous_date)
	while not is_trade_day(previous_date):
		_decrement_calendar_day(previous_date)
	return previous_date


func trade_date_for_index(trading_day_number: int) -> Dictionary:
	var safe_index: int = max(trading_day_number, 1)
	var date_info: Dictionary = start_date()
	var remaining_days: int = safe_index - 1
	while remaining_days > 0:
		date_info = next_trade_date(date_info)
		remaining_days -= 1
	return date_info


func is_trade_day(date_info: Dictionary) -> bool:
	var sanitized_date: Dictionary = _sanitize_date(date_info)
	var weekday_value: int = int(sanitized_date.get("weekday", 0))
	if weekday_value >= 5:
		return false
	return not is_holiday(sanitized_date)


func is_holiday(date_info: Dictionary) -> bool:
	_ensure_loaded()
	var sanitized_date: Dictionary = _sanitize_date(date_info)
	var year_key: String = str(int(sanitized_date.get("year", 0)))
	if not holidays_by_year.has(year_key):
		return false
	return bool(holidays_by_year[year_key].get(to_key(sanitized_date), false))


func format_date(date_info: Dictionary) -> String:
	var sanitized_date: Dictionary = _sanitize_date(date_info)
	var weekday_name: String = WEEKDAY_NAMES[int(sanitized_date.get("weekday", 0))]
	var month_index: int = clamp(int(sanitized_date.get("month", 1)) - 1, 0, MONTH_NAMES.size() - 1)
	return "%s, %02d %s %d" % [
		weekday_name,
		int(sanitized_date.get("day", 1)),
		MONTH_NAMES[month_index],
		int(sanitized_date.get("year", 2020))
	]


func to_key(date_info: Dictionary) -> String:
	var sanitized_date: Dictionary = _sanitize_date(date_info)
	return "%04d-%02d-%02d" % [
		int(sanitized_date.get("year", 2020)),
		int(sanitized_date.get("month", 1)),
		int(sanitized_date.get("day", 1))
	]


func _ensure_loaded() -> void:
	if is_loaded:
		return

	holidays_by_year.clear()
	if not FileAccess.file_exists(HOLIDAY_DATA_PATH):
		push_error("Missing trading calendar data file: %s" % HOLIDAY_DATA_PATH)
		is_loaded = true
		return

	var raw_text: String = FileAccess.get_file_as_string(HOLIDAY_DATA_PATH)
	var parsed_value = JSON.parse_string(raw_text)
	if typeof(parsed_value) != TYPE_DICTIONARY:
		push_error("Expected trading calendar dictionary in %s" % HOLIDAY_DATA_PATH)
		is_loaded = true
		return

	for year_key_value in parsed_value.keys():
		var year_key: String = str(year_key_value)
		var lookup: Dictionary = {}
		for date_key_value in parsed_value[year_key]:
			lookup[str(date_key_value)] = true
		holidays_by_year[year_key] = lookup

	is_loaded = true


func _sanitize_date(date_info: Dictionary) -> Dictionary:
	if date_info.is_empty():
		return start_date()

	return {
		"year": int(date_info.get("year", START_DATE["year"])),
		"month": int(date_info.get("month", START_DATE["month"])),
		"day": int(date_info.get("day", START_DATE["day"])),
		"weekday": int(date_info.get("weekday", START_DATE["weekday"]))
	}


func _increment_calendar_day(date_info: Dictionary) -> void:
	var year_value: int = int(date_info.get("year", START_DATE["year"]))
	var month_value: int = int(date_info.get("month", START_DATE["month"]))
	var day_value: int = int(date_info.get("day", START_DATE["day"])) + 1
	var days_in_month: int = _days_in_month(year_value, month_value)
	if day_value > days_in_month:
		day_value = 1
		month_value += 1
		if month_value > 12:
			month_value = 1
			year_value += 1

	date_info["year"] = year_value
	date_info["month"] = month_value
	date_info["day"] = day_value
	date_info["weekday"] = int(posmod(int(date_info.get("weekday", START_DATE["weekday"])) + 1, 7))


func _decrement_calendar_day(date_info: Dictionary) -> void:
	var year_value: int = int(date_info.get("year", START_DATE["year"]))
	var month_value: int = int(date_info.get("month", START_DATE["month"]))
	var day_value: int = int(date_info.get("day", START_DATE["day"])) - 1
	if day_value < 1:
		month_value -= 1
		if month_value < 1:
			month_value = 12
			year_value -= 1
		day_value = _days_in_month(year_value, month_value)

	date_info["year"] = year_value
	date_info["month"] = month_value
	date_info["day"] = day_value
	date_info["weekday"] = int(posmod(int(date_info.get("weekday", START_DATE["weekday"])) - 1, 7))


func _days_in_month(year_value: int, month_value: int) -> int:
	if month_value in [1, 3, 5, 7, 8, 10, 12]:
		return 31
	if month_value == 2:
		return 29 if _is_leap_year(year_value) else 28
	return 30


func _is_leap_year(year_value: int) -> bool:
	if year_value % 400 == 0:
		return true
	if year_value % 100 == 0:
		return false
	return year_value % 4 == 0
