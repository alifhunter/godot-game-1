extends Node

const RUN_SEED := 20260614
const CATALOG_COMPANY_COUNT := 30


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	if not bool(DataRepository.get_company_universe_validation_result().get("valid", false)):
		_fail("Company universe catalog must be valid before roster bridge test runs.")
		return

	var default_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var default_roster: Array = GameManager.build_company_roster(RUN_SEED, default_config)
	if default_roster.is_empty():
		_fail("Default catalog roster returned no companies.")
		return
	if not _roster_has_catalog_source(default_roster):
		_fail("Default roster expected company universe catalog metadata.")
		return

	var procedural_config: Dictionary = default_config.duplicate(true)
	procedural_config["use_company_universe_catalog"] = false
	var procedural_roster: Array = GameManager.build_company_roster(RUN_SEED, procedural_config)
	if procedural_roster.is_empty():
		_fail("Explicit procedural roster returned no companies.")
		return
	if _roster_has_catalog_source(procedural_roster):
		_fail("Explicit procedural roster unexpectedly used company universe catalog metadata.")
		return

	var catalog_config: Dictionary = default_config.duplicate(true)
	catalog_config["company_count"] = CATALOG_COMPANY_COUNT
	catalog_config["use_company_universe_catalog"] = true
	var first_catalog_roster: Array = GameManager.build_company_roster(RUN_SEED, catalog_config)
	var second_catalog_roster: Array = GameManager.build_company_roster(RUN_SEED, catalog_config)
	if JSON.stringify(first_catalog_roster) != JSON.stringify(second_catalog_roster):
		_fail("Catalog roster bridge is not deterministic for a fixed seed.")
		return
	if first_catalog_roster.size() != CATALOG_COMPANY_COUNT:
		_fail("Expected %d catalog roster companies, got %d." % [CATALOG_COMPANY_COUNT, first_catalog_roster.size()])
		return
	if not _assert_catalog_roster_shape(first_catalog_roster):
		return

	RunState.setup_new_run(RUN_SEED, first_catalog_roster, catalog_config, false)
	if RunState.company_order.size() != CATALOG_COMPANY_COUNT:
		_fail("RunState expected %d catalog companies, got %d." % [CATALOG_COMPANY_COUNT, RunState.company_order.size()])
		return

	var sample_effective_definitions: Array = []
	for sample_index in range(min(5, RunState.company_order.size())):
		var company_id: String = str(RunState.company_order[sample_index])
		if not RunState.ensure_company_full_detail(company_id):
			_fail("Could not hydrate catalog company detail for '%s'." % company_id)
			return
		var effective_definition: Dictionary = RunState.get_effective_company_definition(company_id, true, true)
		if effective_definition.is_empty():
			_fail("Missing effective definition for catalog company '%s'." % company_id)
			return
		if str(effective_definition.get("company_source", "")) != "universe_catalog":
			_fail("Catalog company '%s' lost company_source metadata after RunState setup." % company_id)
			return
		if typeof(effective_definition.get("financials", {})) != TYPE_DICTIONARY or effective_definition.get("financials", {}).is_empty():
			_fail("Catalog company '%s' did not build financials." % company_id)
			return
		sample_effective_definitions.append({
			"id": company_id,
			"ticker": effective_definition.get("ticker", ""),
			"subsector": effective_definition.get("subsector", ""),
			"source": effective_definition.get("company_source", "")
		})

	print("COMPANY_UNIVERSE_ROSTER_BRIDGE_OK %s" % JSON.stringify({
		"seed": RUN_SEED,
		"catalog_count": first_catalog_roster.size(),
		"default_count": default_roster.size(),
		"procedural_count": procedural_roster.size(),
		"samples": sample_effective_definitions
	}))
	get_tree().quit(0)


func _roster_has_catalog_source(roster: Array) -> bool:
	for definition_value in roster:
		if typeof(definition_value) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = definition_value
		if str(definition.get("company_source", "")) == "universe_catalog":
			return true
	return false


func _assert_catalog_roster_shape(roster: Array) -> bool:
	var seen_ids: Dictionary = {}
	var seen_tickers: Dictionary = {}
	var seen_names: Dictionary = {}
	for definition_index in range(roster.size()):
		var definition_value: Variant = roster[definition_index]
		if typeof(definition_value) != TYPE_DICTIONARY:
			_fail("Catalog roster definition %d is not a dictionary." % definition_index)
			return false
		var definition: Dictionary = definition_value
		var company_id: String = str(definition.get("id", "")).strip_edges()
		var ticker: String = str(definition.get("ticker", "")).strip_edges()
		var name: String = str(definition.get("name", "")).strip_edges()
		var catalog_id: String = str(definition.get("universe_catalog_id", "")).strip_edges()
		if company_id.is_empty() or ticker.is_empty() or name.is_empty():
			_fail("Catalog roster definition %d has empty id, ticker, or name." % definition_index)
			return false
		if catalog_id != company_id:
			_fail("Catalog roster definition %d has mismatched catalog id '%s' vs company id '%s'." % [definition_index, catalog_id, company_id])
			return false
		if DataRepository.get_company_universe_company(catalog_id).is_empty():
			_fail("Catalog roster definition %d references unknown catalog id '%s'." % [definition_index, catalog_id])
			return false
		if DataRepository.get_sector_definition(str(definition.get("sector_id", ""))).is_empty():
			_fail("Catalog roster definition %d references unknown sector '%s'." % [definition_index, str(definition.get("sector_id", ""))])
			return false
		if str(definition.get("company_source", "")) != "universe_catalog":
			_fail("Catalog roster definition %d missing company_source universe_catalog." % definition_index)
			return false
		if str(definition.get("subsector", "")).strip_edges().is_empty():
			_fail("Catalog roster definition %d missing subsector." % definition_index)
			return false
		if typeof(definition.get("anchors", {})) != TYPE_DICTIONARY or definition.get("anchors", {}).is_empty():
			_fail("Catalog roster definition %d missing anchors." % definition_index)
			return false
		if typeof(definition.get("commodity_exposures", {})) != TYPE_DICTIONARY:
			_fail("Catalog roster definition %d has invalid commodity_exposures." % definition_index)
			return false
		if typeof(definition.get("macro_exposures", {})) != TYPE_DICTIONARY:
			_fail("Catalog roster definition %d has invalid macro_exposures." % definition_index)
			return false
		if typeof(definition.get("relationship_hooks", [])) != TYPE_ARRAY:
			_fail("Catalog roster definition %d has invalid relationship_hooks." % definition_index)
			return false
		if seen_ids.has(company_id):
			_fail("Catalog roster duplicate id '%s'." % company_id)
			return false
		if seen_tickers.has(ticker):
			_fail("Catalog roster duplicate ticker '%s'." % ticker)
			return false
		if seen_names.has(name):
			_fail("Catalog roster duplicate name '%s'." % name)
			return false
		seen_ids[company_id] = true
		seen_tickers[ticker] = true
		seen_names[name] = true
	return true


func _fail(message: String) -> void:
	push_error(message)
	print("COMPANY_UNIVERSE_ROSTER_BRIDGE_FAIL: %s" % message)
	get_tree().quit(1)
