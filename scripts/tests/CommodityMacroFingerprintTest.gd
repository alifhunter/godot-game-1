extends Node

const MACRO_STATE_SYSTEM = preload("res://systems/MacroStateSystem.gd")
const RUN_SEED := 20260614
const START_YEAR := 2020
const YEARS_TO_FINGERPRINT := 5
const EXPECTED_COMMODITY_COUNT := 25
const EXPECTED_FINGERPRINT_HASH := "773085587"


func _ready() -> void:
	DataRepository.reload_all()

	var first_report: Dictionary = _build_fingerprint_report()
	var second_report: Dictionary = _build_fingerprint_report()
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Commodity macro fingerprint payload was not stable across repeated fixed-seed builds.")
		return
	if str(first_report.get("hash", "")) != str(second_report.get("hash", "")):
		_fail("Commodity macro fingerprint hash was not stable across repeated fixed-seed builds.")
		return
	if int(first_report.get("year_count", 0)) != YEARS_TO_FINGERPRINT:
		_fail("Expected %d commodity macro years, got %d." % [
			YEARS_TO_FINGERPRINT,
			int(first_report.get("year_count", 0))
		])
		return
	if int(first_report.get("commodity_count", 0)) != EXPECTED_COMMODITY_COUNT:
		_fail("Expected %d commodity indicators per year, got %d." % [
			EXPECTED_COMMODITY_COUNT,
			int(first_report.get("commodity_count", 0))
		])
		return
	if not _required_samples_present(first_report.get("sample_rows", {})):
		_fail("Commodity macro fingerprint sample rows were incomplete: %s" % JSON.stringify(first_report.get("sample_rows", {})))
		return

	if EXPECTED_FINGERPRINT_HASH != "BASELINE_PENDING":
		if str(first_report.get("hash", "")) != EXPECTED_FINGERPRINT_HASH:
			_fail("Commodity macro fingerprint changed. expected=%s actual=%s." % [
				EXPECTED_FINGERPRINT_HASH,
				str(first_report.get("hash", ""))
			])
			return

	first_report.erase("payload")
	print("COMMODITY_MACRO_FINGERPRINT_OK %s" % JSON.stringify(first_report))
	get_tree().quit(0)


func _build_fingerprint_report() -> Dictionary:
	var history: Array = _build_history()
	var payload_lines: Array[String] = []
	var regime_counts_by_year: Dictionary = {}
	var sample_rows: Dictionary = {}
	var commodity_count: int = 0

	for state_item in history:
		if typeof(state_item) != TYPE_DICTIONARY:
			continue
		var state_row: Dictionary = state_item
		var year: int = int(state_row.get("year", START_YEAR))
		var indicators: Dictionary = state_row.get("commodity_indicators", {})
		commodity_count = max(commodity_count, indicators.size())
		regime_counts_by_year[str(year)] = _sorted_int_dictionary(state_row.get("commodity_regime_counts", {}))
		payload_lines.append(_state_payload(state_row))
		for sample_id in ["coal", "crude_oil", "cpo", "nickel", "rare_earth", "silica"]:
			if not indicators.has(sample_id):
				continue
			var sample_key: String = "%d:%s" % [year, sample_id]
			sample_rows[sample_key] = _compact_indicator_summary(indicators.get(sample_id, {}))

	var payload: String = "\n--macro-year--\n".join(payload_lines)
	var first_state: Dictionary = history[0] if not history.is_empty() and typeof(history[0]) == TYPE_DICTIONARY else {}
	var last_state: Dictionary = history[history.size() - 1] if not history.is_empty() and typeof(history[history.size() - 1]) == TYPE_DICTIONARY else {}
	return {
		"seed": RUN_SEED,
		"start_year": START_YEAR,
		"year_count": history.size(),
		"commodity_count": commodity_count,
		"hash": _stable_hash(payload),
		"first_year": int(first_state.get("year", START_YEAR)),
		"first_year_leaders": first_state.get("commodity_leaders", []).duplicate(true) if typeof(first_state.get("commodity_leaders", [])) == TYPE_ARRAY else [],
		"first_year_laggards": first_state.get("commodity_laggards", []).duplicate(true) if typeof(first_state.get("commodity_laggards", [])) == TYPE_ARRAY else [],
		"last_year": int(last_state.get("year", START_YEAR + YEARS_TO_FINGERPRINT - 1)),
		"last_year_leaders": last_state.get("commodity_leaders", []).duplicate(true) if typeof(last_state.get("commodity_leaders", [])) == TYPE_ARRAY else [],
		"last_year_laggards": last_state.get("commodity_laggards", []).duplicate(true) if typeof(last_state.get("commodity_laggards", [])) == TYPE_ARRAY else [],
		"regime_counts_by_year": regime_counts_by_year,
		"sample_rows": sample_rows,
		"payload": payload
	}


func _build_history() -> Array:
	var system = MACRO_STATE_SYSTEM.new()
	var history: Array = []
	var previous_state: Dictionary = {}
	for year_offset in range(YEARS_TO_FINGERPRINT):
		var target_year: int = START_YEAR + year_offset
		var state: Dictionary = system.build_year_state(
			RUN_SEED,
			target_year,
			DataRepository.get_sector_definitions(),
			previous_state,
			DataRepository.get_commodity_indicator_catalog()
		)
		if not _is_valid_state(state):
			_fail("Commodity macro fingerprint received invalid state for year %d: %s" % [target_year, JSON.stringify(state)])
			return []
		history.append(state)
		previous_state = state.duplicate(true)
	return history


func _is_valid_state(state: Dictionary) -> bool:
	var indicators: Dictionary = state.get("commodity_indicators", {})
	if indicators.size() != EXPECTED_COMMODITY_COUNT:
		return false
	for required_id in ["coal", "crude_oil", "cpo", "nickel", "gold", "copper", "natural_gas", "rare_earth", "silica"]:
		if not indicators.has(required_id):
			return false
	for commodity_id_value in indicators.keys():
		var indicator: Dictionary = indicators.get(commodity_id_value, {})
		if not _is_valid_indicator(indicator):
			return false
	return true


func _is_valid_indicator(indicator: Dictionary) -> bool:
	if str(indicator.get("id", "")).strip_edges().is_empty():
		return false
	if str(indicator.get("category", "")).strip_edges().is_empty():
		return false
	var level: float = float(indicator.get("level", 0.0))
	if level < 40.0 or level > 200.0:
		return false
	var ytd_move: float = float(indicator.get("ytd_move", 0.0))
	if ytd_move < -75.0 or ytd_move > 75.0:
		return false
	var volatility: float = float(indicator.get("volatility", 0.0))
	if volatility < 0.0 or volatility > 0.85:
		return false
	if not str(indicator.get("direction", "")) in ["falling", "softening", "flat", "firming", "rising"]:
		return false
	if not str(indicator.get("regime", "")) in ["bear", "soft", "neutral", "firm", "bull"]:
		return false
	if typeof(indicator.get("related_sectors", [])) != TYPE_ARRAY:
		return false
	if typeof(indicator.get("story_tags", [])) != TYPE_ARRAY:
		return false
	return true


func _state_payload(state: Dictionary) -> String:
	var lines: Array[String] = []
	var indicators: Dictionary = state.get("commodity_indicators", {})
	var indicator_ids: Array = indicators.keys()
	indicator_ids.sort()
	lines.append("year=%d" % int(state.get("year", START_YEAR)))
	lines.append("regime_counts=%s" % _dictionary_payload(state.get("commodity_regime_counts", {})))
	lines.append("leaders=%s" % _array_payload(state.get("commodity_leaders", [])))
	lines.append("laggards=%s" % _array_payload(state.get("commodity_laggards", [])))
	for indicator_id_value in indicator_ids:
		var indicator_id: String = str(indicator_id_value)
		lines.append(_indicator_payload(indicators.get(indicator_id, {})))
	return "\n".join(lines)


func _indicator_payload(indicator: Dictionary) -> String:
	var parts: Array[String] = []
	parts.append("id=%s" % str(indicator.get("id", "")))
	parts.append("category=%s" % str(indicator.get("category", "")))
	parts.append("level=%s" % _float_token(float(indicator.get("level", 0.0))))
	parts.append("direction=%s" % str(indicator.get("direction", "")))
	parts.append("regime=%s" % str(indicator.get("regime", "")))
	parts.append("ytd=%s" % _float_token(float(indicator.get("ytd_move", 0.0))))
	parts.append("driver=%s" % _float_token(float(indicator.get("driver_score", 0.0))))
	parts.append("volatility=%s" % _float_token(float(indicator.get("volatility", 0.0))))
	parts.append("related=%s" % _array_payload(indicator.get("related_sectors", [])))
	parts.append("stories=%s" % _array_payload(indicator.get("story_tags", [])))
	return "|".join(parts)


func _compact_indicator_summary(indicator: Dictionary) -> Dictionary:
	return {
		"direction": str(indicator.get("direction", "")),
		"regime": str(indicator.get("regime", "")),
		"ytd_move": _float_token(float(indicator.get("ytd_move", 0.0))),
		"level": _float_token(float(indicator.get("level", 0.0))),
		"driver_score": _float_token(float(indicator.get("driver_score", 0.0)))
	}


func _required_samples_present(sample_rows: Variant) -> bool:
	if typeof(sample_rows) != TYPE_DICTIONARY:
		return false
	var samples: Dictionary = sample_rows
	for sample_id in ["2020:coal", "2020:cpo", "2020:rare_earth", "2024:coal", "2024:silica"]:
		if not samples.has(sample_id):
			return false
	return true


func _sorted_int_dictionary(source_value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(source_value) != TYPE_DICTIONARY:
		return result
	var source: Dictionary = source_value
	var keys: Array = source.keys()
	keys.sort()
	for source_key_value in keys:
		var source_key: String = str(source_key_value)
		result[source_key] = int(source.get(source_key_value, 0))
	return result


func _dictionary_payload(source_value: Variant) -> String:
	if typeof(source_value) != TYPE_DICTIONARY:
		return ""
	var source: Dictionary = source_value
	var keys: Array = source.keys()
	keys.sort()
	var parts: Array[String] = []
	for source_key_value in keys:
		var source_key: String = str(source_key_value)
		parts.append("%s:%s" % [source_key, str(source.get(source_key_value, ""))])
	return "|".join(parts)


func _array_payload(source_value: Variant) -> String:
	if typeof(source_value) != TYPE_ARRAY:
		return ""
	var source: Array = source_value
	var parts: Array[String] = []
	for item_value in source:
		parts.append(str(item_value))
	return "|".join(parts)


func _float_token(value: float) -> String:
	return "%.4f" % value


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int((hash_value ^ text.unicode_at(index)) * 16777619)
		hash_value = hash_value % 2147483647
		if hash_value < 0:
			hash_value += 2147483647
	return str(hash_value)


func _fail(message: String) -> void:
	push_error(message)
	print("COMMODITY_MACRO_FINGERPRINT_FAIL: %s" % message)
	get_tree().quit(1)
