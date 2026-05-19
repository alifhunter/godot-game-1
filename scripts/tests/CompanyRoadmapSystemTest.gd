extends Node

const RUN_SEED := 982451653
const ROADMAP_SYSTEM = preload("res://systems/CompanyRoadmapSystem.gd")

var roadmap_system = ROADMAP_SYSTEM.new()


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)

	if not _assert_catalog_shape():
		return
	if not _assert_generated_profiles():
		return
	if not _assert_old_save_backfill():
		return
	if not _assert_funding_gate_behaviour():
		return

	print("COMPANY_ROADMAP_SYSTEM_TEST_OK")
	get_tree().quit(0)


func _assert_catalog_shape() -> bool:
	var catalog: Dictionary = DataRepository.get_company_roadmap_catalog()
	var expected_location_ids: Array = [
		"jakarta",
		"bogor",
		"depok",
		"tangerang",
		"bekasi",
		"karawang",
		"bandung",
		"surabaya",
		"semarang",
		"medan",
		"makassar",
		"batam",
		"balikpapan",
		"denpasar"
	]
	var seen_locations: Dictionary = {}
	for location_value in catalog.get("locations", []):
		if typeof(location_value) != TYPE_DICTIONARY:
			continue
		var location: Dictionary = location_value
		seen_locations[str(location.get("id", ""))] = true
		var visible_location_text: String = "%s %s" % [str(location.get("id", "")), str(location.get("label", ""))]
		if _contains_legacy_location_text(visible_location_text):
			_fail("Roadmap location catalog should not expose legacy metro labels.")
			return false
	for expected_location_id in expected_location_ids:
		if not seen_locations.has(str(expected_location_id)):
			_fail("Roadmap location catalog missing %s." % str(expected_location_id))
			return false

	var sector_roadmaps: Dictionary = catalog.get("sector_roadmaps", {})
	for sector_id in [
		"health",
		"tech",
		"industrial",
		"infra",
		"transport",
		"finance",
		"property",
		"energy",
		"basicindustry",
		"consumer",
		"noncyclical"
	]:
		if not sector_roadmaps.has(sector_id) or sector_roadmaps.get(sector_id, []).is_empty():
			_fail("Roadmap catalog missing sector family for %s." % sector_id)
			return false
	return true


func _assert_generated_profiles() -> bool:
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		var location_profile: Dictionary = definition.get("location_profile", {})
		var roadmap_profile: Dictionary = definition.get("roadmap_profile", {})
		if location_profile.is_empty() or roadmap_profile.is_empty():
			_fail("Expected every generated company to include location and roadmap profiles.")
			return false
		if str(location_profile.get("hq_location_id", "")).is_empty() or str(location_profile.get("hq_location_label", "")).is_empty():
			_fail("Expected company %s to include public HQ location data." % company_id)
			return false
		if str(roadmap_profile.get("primary_family_id", "")).is_empty() or str(roadmap_profile.get("public_priority", "")).is_empty():
			_fail("Expected company %s to include a public roadmap priority." % company_id)
			return false
		var visible_profile_text: String = "%s %s %s %s" % [
			str(location_profile.get("hq_location_label", "")),
			str(location_profile.get("public_footprint", "")),
			str(roadmap_profile.get("primary_family_label", "")),
			str(roadmap_profile.get("public_priority", ""))
		]
		if _contains_legacy_location_text(visible_profile_text):
			_fail("Expected profile copy to avoid legacy metro labels for %s." % company_id)
			return false
		var family: Dictionary = roadmap_system.roadmap_family_for_profile(roadmap_profile, str(definition.get("sector_id", "")))
		if family.is_empty():
			_fail("Expected company %s roadmap family to be compatible with its sector." % company_id)
			return false
		if bool(roadmap_profile.get("physical_project", false)) and str(roadmap_profile.get("property_development_location_id", "")).is_empty():
			_fail("Expected physical roadmap for %s to carry an explicit property city." % company_id)
			return false
	return true


func _assert_old_save_backfill() -> bool:
	var baseline_save: Dictionary = RunState.to_save_dict()
	var legacy_save: Dictionary = baseline_save.duplicate(true)
	var first_company_id: String = str(RunState.company_order[0])
	var legacy_companies: Dictionary = legacy_save.get("companies", {}).duplicate(true)
	for company_id_value in legacy_companies.keys():
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = legacy_companies.get(company_id, {}).duplicate(true)
		var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
		profile.erase("location_profile")
		profile.erase("roadmap_profile")
		runtime["company_profile"] = profile
		legacy_companies[company_id] = runtime
	legacy_save["companies"] = legacy_companies
	legacy_save["company_roadmap_state"] = {
		"active_milestones": {
			"legacy_milestone": {
				"id": "legacy_milestone",
				"company_id": first_company_id,
				"location_id": "bodetabek",
				"location_label": "Bodetabek",
				"start_day_index": RunState.day_index,
				"end_day_index": RunState.day_index + 3,
				"duration_days": 4
			}
		},
		"resolved_milestones": {},
		"company_cooldowns": {},
		"last_spawn_day_index": -999
	}
	var legacy_life: Dictionary = legacy_save.get("player_life", {}).duplicate(true)
	legacy_life["properties"] = [
		{
			"id": "legacy_property",
			"catalog_id": "kost_room",
			"location_id": "bodetabek",
			"location_label": "Bodetabek",
			"purchase_price": 100000000.0,
			"current_value": 100000000.0
		}
	]
	legacy_life["development_leads"] = [
		{
			"id": "legacy_lead",
			"location_id": "jabodetabek",
			"location_label": "Jabodetabek",
			"theme": "modern_city",
			"source_type": "news",
			"source_note": "Legacy Jabodetabek note",
			"due_day_index": RunState.day_index + 4
		}
	]
	legacy_save["player_life"] = legacy_life

	RunState.load_from_dict(legacy_save)
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		if definition.get("location_profile", {}).is_empty() or definition.get("roadmap_profile", {}).is_empty():
			_fail("Expected old-save profile backfill for %s." % company_id)
			return false
	var life_text: String = str(RunState.get_player_life())
	if _contains_legacy_location_text(life_text):
		_fail("Expected old Life save data to migrate away from legacy location text.")
		return false
	var roadmap_state_text: String = str(RunState.get_company_roadmap_state())
	if _contains_legacy_location_text(roadmap_state_text):
		_fail("Expected old roadmap save state to migrate away from legacy location text.")
		return false

	RunState.load_from_dict(baseline_save)
	return true


func _assert_funding_gate_behaviour() -> bool:
	var finance_company_id: String = _first_company_in_sector("finance")
	var project_company_id: String = _first_non_finance_company()
	if finance_company_id.is_empty() or project_company_id.is_empty():
		_fail("Expected generated roster to include finance and project companies.")
		return false
	_make_finance_company_eligible(finance_company_id)
	_make_project_company_weak(project_company_id)
	var large_family: Dictionary = {
		"id": "test_large_project",
		"label": "Large project",
		"funding_scale": "transformational",
		"funding_routes": ["loan", "rights_issue"],
		"positive_bias": 0.12
	}
	var linked_funding: Dictionary = roadmap_system.debug_evaluate_funding(RunState, project_company_id, large_family)
	if str(linked_funding.get("outcome", "")) != "needs_financing" or str(linked_funding.get("finance_company_id", "")).is_empty():
		_fail("Expected weak-cash large project to link to an eligible finance company.")
		return false
	var linked_partner_id: String = str(linked_funding.get("finance_company_id", ""))
	var linked_partner: Dictionary = RunState.get_effective_company_definition(linked_partner_id, false, false)
	if str(linked_partner.get("sector_id", "")) != "finance":
		_fail("Expected funding partner to come from the generated finance sector.")
		return false
	var excluded_funding: Dictionary = roadmap_system.debug_evaluate_funding(RunState, project_company_id, large_family, [linked_partner_id])
	if str(excluded_funding.get("finance_company_id", "")) == linked_partner_id:
		_fail("Expected funding gate to respect live-conflict/excluded finance partners.")
		return false

	_make_project_company_strong(project_company_id)
	var small_family: Dictionary = {
		"id": "test_small_project",
		"label": "Small project",
		"funding_scale": "low",
		"funding_routes": ["self"],
		"positive_bias": 0.08
	}
	var self_funding: Dictionary = roadmap_system.debug_evaluate_funding(RunState, project_company_id, small_family)
	if str(self_funding.get("outcome", "")) != "self_funded":
		_fail("Expected strong company with a small milestone to self-fund.")
		return false
	return true


func _first_company_in_sector(sector_id: String) -> String:
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		if str(definition.get("sector_id", "")) == sector_id:
			return company_id
	return ""


func _first_non_finance_company() -> String:
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		if str(definition.get("sector_id", "")) != "finance":
			return company_id
	return ""


func _make_finance_company_eligible(company_id: String) -> void:
	var runtime: Dictionary = RunState.companies.get(company_id, {}).duplicate(true)
	var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var financials: Dictionary = profile.get("financials", {}).duplicate(true)
	financials["market_cap"] = 9000000000000.0
	financials["roe"] = 20.0
	financials["debt_to_equity"] = 0.35
	profile["financials"] = financials
	profile["quality_score"] = 92
	runtime["company_profile"] = profile
	RunState.companies[company_id] = runtime


func _make_project_company_weak(company_id: String) -> void:
	var runtime: Dictionary = RunState.companies.get(company_id, {}).duplicate(true)
	var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var financials: Dictionary = profile.get("financials", {}).duplicate(true)
	financials["market_cap"] = 8000000000000.0
	financials["revenue"] = 200000000000.0
	financials["net_income"] = 1000000000.0
	financials["net_profit_margin"] = 1.0
	financials["debt_to_equity"] = 0.8
	profile["financials"] = financials
	var traits: Dictionary = profile.get("generation_traits", {}).duplicate(true)
	traits["balance_sheet_strength"] = 0.1
	profile["generation_traits"] = traits
	runtime["company_profile"] = profile
	RunState.companies[company_id] = runtime


func _make_project_company_strong(company_id: String) -> void:
	var runtime: Dictionary = RunState.companies.get(company_id, {}).duplicate(true)
	var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var financials: Dictionary = profile.get("financials", {}).duplicate(true)
	financials["market_cap"] = 100000000000.0
	financials["revenue"] = 20000000000000.0
	financials["net_income"] = 2000000000000.0
	financials["net_profit_margin"] = 20.0
	financials["debt_to_equity"] = 0.2
	profile["financials"] = financials
	var traits: Dictionary = profile.get("generation_traits", {}).duplicate(true)
	traits["balance_sheet_strength"] = 1.0
	profile["generation_traits"] = traits
	runtime["company_profile"] = profile
	RunState.companies[company_id] = runtime


func _contains_legacy_location_text(text_value: String) -> bool:
	var text: String = text_value.to_lower()
	return text.contains("bodetabek") or text.contains("jabodetabek")


func _fail(message: String) -> void:
	push_error(message)
	print("COMPANY_ROADMAP_SYSTEM_TEST_FAIL: %s" % message)
	get_tree().quit(1)
