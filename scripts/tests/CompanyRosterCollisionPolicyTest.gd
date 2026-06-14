extends Node

const ROSTER_GENERATOR_SCRIPT = preload("res://systems/CompanyRosterGenerator.gd")
const RUN_SEED := 20260614
const ROSTER_SIZES := [30, 80, 120, 200]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var reports: Array = []
	for roster_size in ROSTER_SIZES:
		reports.append(_build_collision_report(int(roster_size)))

	var default_report: Dictionary = reports[0]
	if int(default_report.get("duplicate_name_count", 0)) != 0 or int(default_report.get("duplicate_ticker_count", 0)) != 0:
		_fail("Default roster should have zero duplicate names/tickers, got names=%d tickers=%d." % [
			int(default_report.get("duplicate_name_count", 0)),
			int(default_report.get("duplicate_ticker_count", 0))
		])
		return

	print("COMPANY_ROSTER_COLLISION_POLICY_OK %s" % JSON.stringify({
		"seed": RUN_SEED,
		"reports": reports
	}))
	get_tree().quit(0)


func _build_collision_report(company_count: int) -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = company_count
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	var fallback_report: Dictionary = _measure_name_fallbacks(company_count)

	var names_seen: Dictionary = {}
	var duplicate_names: Array[String] = []
	var tickers_seen: Dictionary = {}
	var duplicate_tickers: Array[String] = []
	var fallback_ticker_count: int = 0
	var sample_duplicates: Array[String] = []
	for definition_value in company_definitions:
		if typeof(definition_value) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = definition_value
		var name: String = str(definition.get("name", ""))
		var ticker: String = str(definition.get("ticker", ""))
		if ticker == "CMPX":
			fallback_ticker_count += 1
		if names_seen.has(name):
			duplicate_names.append(name)
			if sample_duplicates.size() < 6:
				sample_duplicates.append(name)
		names_seen[name] = true
		if tickers_seen.has(ticker):
			duplicate_tickers.append(ticker)
			if sample_duplicates.size() < 6:
				sample_duplicates.append(ticker)
		tickers_seen[ticker] = true

	return {
		"company_count": company_count,
		"generated_count": company_definitions.size(),
		"unique_name_count": names_seen.size(),
		"unique_ticker_count": tickers_seen.size(),
		"duplicate_name_count": duplicate_names.size(),
		"duplicate_ticker_count": duplicate_tickers.size(),
		"fallback_name_count": int(fallback_report.get("fallback_name_count", 0)),
		"fallback_ticker_count": fallback_ticker_count,
		"fallback_names": fallback_report.get("fallback_names", []),
		"sample_duplicates": sample_duplicates
	}


func _measure_name_fallbacks(company_count: int) -> Dictionary:
	var roster_generator = ROSTER_GENERATOR_SCRIPT.new()
	var words: Array = roster_generator.call("_extract_words", DataRepository.get_company_word_data())
	var sector_rotation: Array = roster_generator.call(
		"_build_sector_rotation",
		DataRepository.get_sector_definitions(),
		company_count,
		RUN_SEED
	)
	var used_names: Dictionary = {}
	var fallback_names: Array[String] = []
	for company_index in range(company_count):
		var sector_definition: Dictionary = {}
		if company_index < sector_rotation.size() and typeof(sector_rotation[company_index]) == TYPE_DICTIONARY:
			sector_definition = sector_rotation[company_index]
		var sector_id: String = str(sector_definition.get("id", "consumer"))
		var name_words: Array = roster_generator.call(
			"_build_unique_name_words",
			words,
			sector_id,
			used_names,
			RUN_SEED,
			company_index
		)
		var name: String = str(roster_generator.call("_join_words", name_words))
		if not used_names.has(name):
			fallback_names.append(name)
	return {
		"fallback_name_count": fallback_names.size(),
		"fallback_names": fallback_names
	}


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
