extends Node

const RUN_SEED := 20260614
const EXPECTED_ROSTER_SIZE := 30
const EXPECTED_FINGERPRINT_HASH := "1266026255"
const EXPECTED_FIRST_COMPANY_ID := "armada_kurir_nusantara"
const EXPECTED_FIRST_TICKER := "AKRN"
const EXPECTED_LAST_COMPANY_ID := "asuransi_nusa"
const EXPECTED_LAST_TICKER := "ASNS"


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	if not bool(DataRepository.get_company_universe_validation_result().get("valid", false)):
		_fail("Company universe catalog must be valid before selection fingerprint runs.")
		return

	var first_report: Dictionary = _build_fingerprint_report()
	var second_report: Dictionary = _build_fingerprint_report()
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Company universe selection fingerprint payload was not stable across repeated builds.")
		return
	if str(first_report.get("hash", "")) != str(second_report.get("hash", "")):
		_fail("Company universe selection fingerprint hash was not stable across repeated builds.")
		return

	if int(first_report.get("roster_size", 0)) != EXPECTED_ROSTER_SIZE:
		_fail("Expected %d company universe selections, got %d." % [
			EXPECTED_ROSTER_SIZE,
			int(first_report.get("roster_size", 0))
		])
		return
	if int(first_report.get("duplicate_id_count", 0)) != 0:
		_fail("Expected zero duplicate company universe ids, got %d." % int(first_report.get("duplicate_id_count", 0)))
		return
	if int(first_report.get("duplicate_ticker_count", 0)) != 0:
		_fail("Expected zero duplicate company universe tickers, got %d." % int(first_report.get("duplicate_ticker_count", 0)))
		return

	if EXPECTED_FINGERPRINT_HASH != "BASELINE_PENDING":
		if str(first_report.get("hash", "")) != EXPECTED_FINGERPRINT_HASH:
			_fail("Company universe selection fingerprint changed. expected=%s actual=%s." % [
				EXPECTED_FINGERPRINT_HASH,
				str(first_report.get("hash", ""))
			])
			return
		if str(first_report.get("first_company_id", "")) != EXPECTED_FIRST_COMPANY_ID:
			_fail("Company universe first company id changed. expected=%s actual=%s." % [
				EXPECTED_FIRST_COMPANY_ID,
				str(first_report.get("first_company_id", ""))
			])
			return
		if str(first_report.get("first_ticker", "")) != EXPECTED_FIRST_TICKER:
			_fail("Company universe first ticker changed. expected=%s actual=%s." % [
				EXPECTED_FIRST_TICKER,
				str(first_report.get("first_ticker", ""))
			])
			return
		if str(first_report.get("last_company_id", "")) != EXPECTED_LAST_COMPANY_ID:
			_fail("Company universe last company id changed. expected=%s actual=%s." % [
				EXPECTED_LAST_COMPANY_ID,
				str(first_report.get("last_company_id", ""))
			])
			return
		if str(first_report.get("last_ticker", "")) != EXPECTED_LAST_TICKER:
			_fail("Company universe last ticker changed. expected=%s actual=%s." % [
				EXPECTED_LAST_TICKER,
				str(first_report.get("last_ticker", ""))
			])
			return

	first_report.erase("payload")
	print("COMPANY_UNIVERSE_SELECTION_FINGERPRINT_OK %s" % JSON.stringify(first_report))
	get_tree().quit(0)


func _build_fingerprint_report() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = EXPECTED_ROSTER_SIZE
	difficulty_config["use_company_universe_catalog"] = true
	var roster: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	var payload_lines: Array[String] = []
	var selected_ids: Array[String] = []
	var selected_tickers: Array[String] = []
	var sector_counts: Dictionary = {}
	var commodity_exposure_summary: Dictionary = {}
	var macro_exposure_summary: Dictionary = {}
	var seen_ids: Dictionary = {}
	var seen_tickers: Dictionary = {}
	var duplicate_ids: Array[String] = []
	var duplicate_tickers: Array[String] = []

	for definition_value in roster:
		if typeof(definition_value) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = definition_value
		var company_id: String = str(definition.get("id", ""))
		var ticker: String = str(definition.get("ticker", ""))
		var sector_id: String = str(definition.get("sector_id", ""))
		selected_ids.append(company_id)
		selected_tickers.append(ticker)
		if seen_ids.has(company_id):
			duplicate_ids.append(company_id)
		seen_ids[company_id] = true
		if seen_tickers.has(ticker):
			duplicate_tickers.append(ticker)
		seen_tickers[ticker] = true
		sector_counts[sector_id] = int(sector_counts.get(sector_id, 0)) + 1
		_accumulate_exposures(commodity_exposure_summary, definition.get("commodity_exposures", {}))
		_accumulate_exposures(macro_exposure_summary, definition.get("macro_exposures", {}))
		payload_lines.append(_definition_payload(definition))

	var payload: String = "\n--company--\n".join(payload_lines)
	var first_definition: Dictionary = roster[0] if not roster.is_empty() and typeof(roster[0]) == TYPE_DICTIONARY else {}
	var last_definition: Dictionary = roster[roster.size() - 1] if not roster.is_empty() and typeof(roster[roster.size() - 1]) == TYPE_DICTIONARY else {}
	return {
		"seed": RUN_SEED,
		"roster_size": roster.size(),
		"hash": _stable_hash(payload),
		"first_company_id": str(first_definition.get("id", "")),
		"first_ticker": str(first_definition.get("ticker", "")),
		"last_company_id": str(last_definition.get("id", "")),
		"last_ticker": str(last_definition.get("ticker", "")),
		"duplicate_id_count": duplicate_ids.size(),
		"duplicate_ticker_count": duplicate_tickers.size(),
		"selected_ids": selected_ids,
		"selected_tickers": selected_tickers,
		"sector_counts": _sorted_count_dictionary(sector_counts),
		"top_commodity_exposures": _top_exposure_rows(commodity_exposure_summary, 8),
		"top_macro_exposures": _top_exposure_rows(macro_exposure_summary, 8),
		"payload": payload
	}


func _definition_payload(definition: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("id=%s" % str(definition.get("id", "")))
	lines.append("ticker=%s" % str(definition.get("ticker", "")))
	lines.append("sector_id=%s" % str(definition.get("sector_id", "")))
	lines.append("subsector=%s" % str(definition.get("subsector", "")))
	lines.append("source=%s" % str(definition.get("company_source", "")))
	lines.append("narrative_tags=%s" % _array_payload(definition.get("narrative_tags", [])))
	lines.append("moat_tags=%s" % _array_payload(definition.get("moat_tags", [])))
	lines.append("story_hooks=%s" % _array_payload(definition.get("story_hooks", [])))
	lines.append("commodity_exposures=%s" % _dictionary_payload(definition.get("commodity_exposures", {})))
	lines.append("macro_exposures=%s" % _dictionary_payload(definition.get("macro_exposures", {})))
	return "\n".join(lines)


func _accumulate_exposures(summary: Dictionary, exposures_value: Variant) -> void:
	if typeof(exposures_value) != TYPE_DICTIONARY:
		return
	var exposures: Dictionary = exposures_value
	for exposure_key_value in exposures.keys():
		var exposure_key: String = str(exposure_key_value)
		var exposure_value: float = float(exposures.get(exposure_key_value, 0.0))
		var row: Dictionary = summary.get(exposure_key, {"signed": 0.0, "absolute": 0.0})
		row["signed"] = float(row.get("signed", 0.0)) + exposure_value
		row["absolute"] = float(row.get("absolute", 0.0)) + abs(exposure_value)
		summary[exposure_key] = row


func _top_exposure_rows(summary: Dictionary, limit: int) -> Array:
	var rows: Array = []
	for exposure_key_value in summary.keys():
		var exposure_key: String = str(exposure_key_value)
		var row: Dictionary = summary.get(exposure_key, {})
		rows.append({
			"id": exposure_key,
			"signed": _float_token(float(row.get("signed", 0.0))),
			"absolute": _float_token(float(row.get("absolute", 0.0)))
		})
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_abs: float = float(left.get("absolute", "0.0000"))
		var right_abs: float = float(right.get("absolute", "0.0000"))
		if is_equal_approx(left_abs, right_abs):
			return str(left.get("id", "")) < str(right.get("id", ""))
		return left_abs > right_abs
	)
	if rows.size() > limit:
		return rows.slice(0, limit)
	return rows


func _sorted_count_dictionary(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var keys: Array = source.keys()
	keys.sort()
	for key_value in keys:
		var key: String = str(key_value)
		result[key] = int(source.get(key_value, 0))
	return result


func _dictionary_payload(source_value: Variant) -> String:
	if typeof(source_value) != TYPE_DICTIONARY:
		return ""
	var source: Dictionary = source_value
	var keys: Array = source.keys()
	keys.sort()
	var parts: Array[String] = []
	for key_value in keys:
		var key: String = str(key_value)
		parts.append("%s:%s" % [key, _float_token(float(source.get(key_value, 0.0)))])
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
	print("COMPANY_UNIVERSE_SELECTION_FINGERPRINT_FAIL: %s" % message)
	get_tree().quit(1)
