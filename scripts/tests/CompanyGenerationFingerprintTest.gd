extends Node

const RUN_SEED := 20260614
const EXPECTED_ROSTER_SIZE := 30
const EXPECTED_FINGERPRINT_HASH := "1225696160"
const EXPECTED_FIRST_COMPANY_ID := "anre"
const EXPECTED_FIRST_TICKER := "ANRE"
const EXPECTED_LAST_COMPANY_ID := "waba"
const EXPECTED_LAST_TICKER := "WABA"


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_fingerprint_report()
	var second_report: Dictionary = _build_fingerprint_report()
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Company generation fingerprint payload was not stable across repeated builds.")
		return
	if str(first_report.get("hash", "")) != str(second_report.get("hash", "")):
		_fail("Company generation fingerprint hash was not stable across repeated builds.")
		return

	var roster_size: int = int(first_report.get("roster_size", 0))
	if roster_size != EXPECTED_ROSTER_SIZE:
		_fail("Company generation fingerprint expected %d companies, got %d." % [EXPECTED_ROSTER_SIZE, roster_size])
		return
	if int(first_report.get("duplicate_name_count", 0)) != 0 or int(first_report.get("duplicate_ticker_count", 0)) != 0:
		_fail("Company generation fingerprint expected zero procedural-roster duplicate names/tickers, got names=%d tickers=%d." % [
			int(first_report.get("duplicate_name_count", 0)),
			int(first_report.get("duplicate_ticker_count", 0))
		])
		return

	if EXPECTED_FINGERPRINT_HASH != "BASELINE_PENDING":
		if str(first_report.get("hash", "")) != EXPECTED_FINGERPRINT_HASH:
			_fail("Company generation fingerprint changed. expected=%s actual=%s." % [
				EXPECTED_FINGERPRINT_HASH,
				str(first_report.get("hash", ""))
			])
			return
		if str(first_report.get("first_company_id", "")) != EXPECTED_FIRST_COMPANY_ID:
			_fail("Company generation first company id changed. expected=%s actual=%s." % [
				EXPECTED_FIRST_COMPANY_ID,
				str(first_report.get("first_company_id", ""))
			])
			return
		if str(first_report.get("first_ticker", "")) != EXPECTED_FIRST_TICKER:
			_fail("Company generation first ticker changed. expected=%s actual=%s." % [
				EXPECTED_FIRST_TICKER,
				str(first_report.get("first_ticker", ""))
			])
			return
		if str(first_report.get("last_company_id", "")) != EXPECTED_LAST_COMPANY_ID:
			_fail("Company generation last company id changed. expected=%s actual=%s." % [
				EXPECTED_LAST_COMPANY_ID,
				str(first_report.get("last_company_id", ""))
			])
			return
		if str(first_report.get("last_ticker", "")) != EXPECTED_LAST_TICKER:
			_fail("Company generation last ticker changed. expected=%s actual=%s." % [
				EXPECTED_LAST_TICKER,
				str(first_report.get("last_ticker", ""))
			])
			return

	first_report.erase("payload")
	print("COMPANY_GENERATION_FINGERPRINT_OK %s" % JSON.stringify(first_report))
	get_tree().quit(0)


func _build_fingerprint_report() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["use_company_universe_catalog"] = false
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		if not RunState.ensure_company_full_detail(company_id):
			_fail("Company generation fingerprint could not hydrate full detail for %s." % company_id)
			return {}

	var company_ids: Array = []
	for company_id_value in RunState.company_order:
		company_ids.append(str(company_id_value))
	company_ids.sort()

	var payload_lines: Array[String] = []
	var names_seen: Dictionary = {}
	var duplicate_names: Array[String] = []
	var tickers_seen: Dictionary = {}
	var duplicate_tickers: Array[String] = []
	var spot_rows: Array = []
	for company_id_value in company_ids:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, true, true)
		if definition.is_empty():
			_fail("Company generation fingerprint missing effective definition for %s." % company_id)
			return {}
		var company_name: String = str(definition.get("name", ""))
		var ticker: String = str(definition.get("ticker", ""))
		if names_seen.has(company_name):
			duplicate_names.append(company_name)
		names_seen[company_name] = true
		if tickers_seen.has(ticker):
			duplicate_tickers.append(ticker)
		tickers_seen[ticker] = true
		payload_lines.append(_company_payload(company_id, definition))
		spot_rows.append(_spot_row(company_id, definition))

	if spot_rows.is_empty():
		_fail("Company generation fingerprint produced no spot rows.")
		return {}
	var payload: String = "\n--company--\n".join(payload_lines)
	var first_spot: Dictionary = spot_rows[0]
	var last_spot: Dictionary = spot_rows[spot_rows.size() - 1]
	return {
		"seed": RUN_SEED,
		"roster_size": company_ids.size(),
		"hash": _stable_hash(payload),
		"first_company_id": str(first_spot.get("id", "")),
		"first_ticker": str(first_spot.get("ticker", "")),
		"first_name": str(first_spot.get("name", "")),
		"first_base_price": str(first_spot.get("base_price", "")),
		"first_chart_archetype": str(first_spot.get("chart_archetype", "")),
		"last_company_id": str(last_spot.get("id", "")),
		"last_ticker": str(last_spot.get("ticker", "")),
		"last_name": str(last_spot.get("name", "")),
		"last_base_price": str(last_spot.get("base_price", "")),
		"last_chart_archetype": str(last_spot.get("chart_archetype", "")),
		"duplicate_name_count": duplicate_names.size(),
		"duplicate_ticker_count": duplicate_tickers.size(),
		"payload": payload
	}


func _company_payload(company_id: String, definition: Dictionary) -> String:
	var lines: Array[String] = []
	var financials: Dictionary = definition.get("financials", {}) if typeof(definition.get("financials", {})) == TYPE_DICTIONARY else {}
	var financial_history: Array = definition.get("financial_history", []) if typeof(definition.get("financial_history", [])) == TYPE_ARRAY else []
	var first_history: Dictionary = financial_history[0] if not financial_history.is_empty() and typeof(financial_history[0]) == TYPE_DICTIONARY else {}
	var last_history: Dictionary = financial_history[financial_history.size() - 1] if not financial_history.is_empty() and typeof(financial_history[financial_history.size() - 1]) == TYPE_DICTIONARY else {}
	var traits: Dictionary = definition.get("generation_traits", {}) if typeof(definition.get("generation_traits", {})) == TYPE_DICTIONARY else {}
	var chart_profile: Dictionary = traits.get("chart_profile", {}) if typeof(traits.get("chart_profile", {})) == TYPE_DICTIONARY else {}
	lines.append("id=%s" % company_id)
	lines.append("ticker=%s" % str(definition.get("ticker", "")))
	lines.append("name=%s" % str(definition.get("name", "")))
	lines.append("sector_id=%s" % str(definition.get("sector_id", "")))
	lines.append("base_price=%s" % _float_token(float(definition.get("base_price", 0.0))))
	lines.append("quality_score=%d" % int(definition.get("quality_score", 0)))
	lines.append("growth_score=%d" % int(definition.get("growth_score", 0)))
	lines.append("risk_score=%d" % int(definition.get("risk_score", 0)))
	lines.append("market_cap=%s" % _float_token(float(financials.get("market_cap", 0.0))))
	lines.append("shares_outstanding=%s" % _float_token(float(definition.get("shares_outstanding", 0.0))))
	lines.append("chart_archetype=%s" % str(chart_profile.get("archetype", "")))
	lines.append("first_year=%s" % str(first_history.get("year", "")))
	lines.append("first_revenue=%s" % _float_token(float(first_history.get("revenue", 0.0))))
	lines.append("first_net_income=%s" % _float_token(float(first_history.get("net_income", 0.0))))
	lines.append("first_equity=%s" % _float_token(float(first_history.get("equity", 0.0))))
	lines.append("last_year=%s" % str(last_history.get("year", "")))
	lines.append("last_revenue=%s" % _float_token(float(last_history.get("revenue", 0.0))))
	lines.append("last_net_income=%s" % _float_token(float(last_history.get("net_income", 0.0))))
	lines.append("last_equity=%s" % _float_token(float(last_history.get("equity", 0.0))))
	lines.append("management_roster=%s" % _management_roster_payload(definition))
	return "\n".join(lines)


func _spot_row(company_id: String, definition: Dictionary) -> Dictionary:
	var traits: Dictionary = definition.get("generation_traits", {}) if typeof(definition.get("generation_traits", {})) == TYPE_DICTIONARY else {}
	var chart_profile: Dictionary = traits.get("chart_profile", {}) if typeof(traits.get("chart_profile", {})) == TYPE_DICTIONARY else {}
	return {
		"id": company_id,
		"ticker": str(definition.get("ticker", "")),
		"name": str(definition.get("name", "")),
		"base_price": _float_token(float(definition.get("base_price", 0.0))),
		"chart_archetype": str(chart_profile.get("archetype", ""))
	}


func _management_roster_payload(definition: Dictionary) -> String:
	var roster: Array = definition.get("management_roster", []) if typeof(definition.get("management_roster", [])) == TYPE_ARRAY else []
	var rows: Array[String] = []
	for entry_value in roster:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_value
		rows.append("%s:%s" % [
			str(entry.get("role", entry.get("affiliation_role", ""))),
			str(entry.get("display_name", entry.get("name", "")))
		])
	return "|".join(rows)


func _float_token(value: float) -> String:
	return "%.6f" % value


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
	get_tree().quit(1)
