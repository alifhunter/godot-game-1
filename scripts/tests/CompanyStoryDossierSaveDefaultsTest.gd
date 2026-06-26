extends Node

const RUN_SEED := 20260615
const CATALOG_COMPANY_COUNT := 30


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = CATALOG_COMPANY_COUNT
	difficulty_config["use_company_universe_catalog"] = true
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)

	if not _assert_seeded_new_run_state("new run"):
		return

	var baseline_save: Dictionary = RunState.to_save_dict()
	var baseline_state: Dictionary = baseline_save.get("company_story_dossier_state", {})
	var first_story_id: String = str(baseline_state.get("active_story_ids", [])[0])
	var first_dossier: Dictionary = baseline_state.get("dossier_index", {}).get(first_story_id, {})
	var first_company_id: String = str(first_dossier.get("company_id", ""))

	if not RunState.update_company_story_dossier_progress(first_story_id, "resolution", "resolved", "confirmed", 42):
		_fail("Expected dossier progress update to succeed.")
		return
	if not _assert_progress_update(first_story_id, first_company_id, "before reload"):
		return
	var progressed_save: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(progressed_save)
	if not _assert_progress_update(first_story_id, first_company_id, "after reload"):
		return

	var legacy_save: Dictionary = _remove_dossier_state(baseline_save)
	RunState.load_from_dict(legacy_save)
	if not _assert_legacy_defaults():
		return

	var partial_save: Dictionary = _partial_dossier_state(baseline_save, first_story_id, first_company_id)
	RunState.load_from_dict(partial_save)
	if not _assert_partial_normalization(first_story_id, first_company_id):
		return

	var final_state: Dictionary = RunState.get_company_story_dossier_state()
	print("COMPANY_STORY_DOSSIER_SAVE_DEFAULTS_OK %s" % JSON.stringify({
		"seed": RUN_SEED,
		"baseline_count": baseline_state.get("active_story_ids", []).size(),
		"partial_count": final_state.get("active_story_ids", []).size(),
		"first_story_id": first_story_id,
		"first_company_id": first_company_id
	}))
	get_tree().quit(0)


func _assert_seeded_new_run_state(label: String) -> bool:
	var state: Dictionary = RunState.get_company_story_dossier_state()
	if int(state.get("schema_version", 0)) != 1:
		_fail("Expected dossier schema version 1 for %s." % label)
		return false
	if not bool(state.get("generated", false)):
		_fail("Expected generated dossier state for %s." % label)
		return false
	if int(state.get("run_seed", 0)) != RUN_SEED:
		_fail("Expected run seed to be saved in dossier state for %s." % label)
		return false
	if state.get("active_story_ids", []).size() != CATALOG_COMPANY_COUNT:
		_fail("Expected %d active story ids for %s, got %d." % [
			CATALOG_COMPANY_COUNT,
			label,
			state.get("active_story_ids", []).size()
		])
		return false
	if state.get("dossier_index", {}).size() != CATALOG_COMPANY_COUNT:
		_fail("Expected %d dossier index rows for %s." % [CATALOG_COMPANY_COUNT, label])
		return false
	if state.get("company_story_ids", {}).size() != CATALOG_COMPANY_COUNT:
		_fail("Expected each company to have a story id for %s." % label)
		return false

	var save_payload: Dictionary = RunState.to_save_dict()
	if typeof(save_payload.get("company_story_dossier_state", {})) != TYPE_DICTIONARY:
		_fail("Expected save payload to include company_story_dossier_state.")
		return false
	var save_companies: Dictionary = save_payload.get("companies", {})
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = save_companies.get(company_id, {})
		var company_state: Dictionary = runtime.get("company_story_dossier_state", {})
		if typeof(company_state) != TYPE_DICTIONARY:
			_fail("Expected company %s save payload to include company_story_dossier_state." % company_id)
			return false
		if str(company_state.get("company_id", "")) != company_id:
			_fail("Expected company story state id mirror for %s." % company_id)
			return false
	return true


func _assert_progress_update(story_id: String, company_id: String, label: String) -> bool:
	var state: Dictionary = RunState.get_company_story_dossier_state()
	if state.get("active_story_ids", []).has(story_id):
		_fail("Expected story %s to leave active ids %s." % [story_id, label])
		return false
	if not state.get("resolved_story_ids", []).has(story_id):
		_fail("Expected story %s to enter resolved ids %s." % [story_id, label])
		return false
	var dossier: Dictionary = RunState.get_company_story_dossier(story_id)
	if str(dossier.get("stage_id", "")) != "resolution":
		_fail("Expected updated story stage to persist as resolution %s." % label)
		return false
	if str(dossier.get("public_status", "")) != "resolved":
		_fail("Expected updated public status to persist as resolved %s." % label)
		return false
	if int(dossier.get("resolved_day_index", -1)) != 42:
		_fail("Expected resolved day 42 %s." % label)
		return false
	var recent_rows: Array = state.get("recent_resolved_stories", [])
	if recent_rows.is_empty() or str(recent_rows[recent_rows.size() - 1].get("story_id", "")) != story_id:
		_fail("Expected recent resolved stories to include %s %s." % [story_id, label])
		return false
	var company_state: Dictionary = RunState.get_company_story_dossier_company_state(company_id)
	if not company_state.get("resolved_story_ids", []).has(story_id):
		_fail("Expected company state to include resolved story %s %s." % [story_id, label])
		return false
	return true


func _assert_legacy_defaults() -> bool:
	var state: Dictionary = RunState.get_company_story_dossier_state()
	if bool(state.get("generated", false)):
		_fail("Expected legacy save without dossier state to remain ungenerated.")
		return false
	if not state.get("active_story_ids", []).is_empty() or not state.get("dossier_index", {}).is_empty():
		_fail("Expected legacy save without dossier state to normalize to empty registry.")
		return false
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var company_state: Dictionary = RunState.get_company_story_dossier_company_state(company_id)
		if int(company_state.get("schema_version", 0)) != 1:
			_fail("Expected company dossier state schema version for legacy company %s." % company_id)
			return false
		if str(company_state.get("company_id", "")) != company_id:
			_fail("Expected company id mirror for legacy company %s." % company_id)
			return false
		if not company_state.get("active_story_ids", []).is_empty():
			_fail("Expected legacy company %s to have no active story refs." % company_id)
			return false
	return true


func _assert_partial_normalization(story_id: String, company_id: String) -> bool:
	var state: Dictionary = RunState.get_company_story_dossier_state()
	if int(state.get("schema_version", 0)) != 1:
		_fail("Expected partial global state schema to normalize.")
		return false
	if state.get("active_story_ids", []).size() != 1:
		_fail("Expected duplicate active story ids to collapse in partial state.")
		return false
	var dossier: Dictionary = RunState.get_company_story_dossier(story_id)
	if str(dossier.get("truth_state", "")) != "uncertain":
		_fail("Expected invalid truth state to normalize to uncertain.")
		return false
	if str(dossier.get("public_status", "")) != "silent":
		_fail("Expected invalid public status to normalize to silent.")
		return false
	if str(dossier.get("stage_id", "")) != "seeded":
		_fail("Expected invalid stage to normalize to seeded.")
		return false
	if not is_equal_approx(float(dossier.get("priority", 0.0)), 1.0):
		_fail("Expected priority to clamp to 1.0.")
		return false
	if not is_equal_approx(float(dossier.get("price_effects", {}).get("drift_bps", 0.0)), 18.0):
		_fail("Expected drift bps to clamp to 18.")
		return false
	var company_state: Dictionary = RunState.get_company_story_dossier_company_state(company_id)
	if str(company_state.get("company_id", "")) != company_id:
		_fail("Expected company state id to normalize to owning company.")
		return false
	if company_state.get("active_story_ids", []).size() != 1:
		_fail("Expected company active story ids to collapse.")
		return false
	if str(company_state.get("current_story_id", "")) != story_id:
		_fail("Expected current story id to be restored from global state.")
		return false
	return true


func _remove_dossier_state(source_save: Dictionary) -> Dictionary:
	var save: Dictionary = source_save.duplicate(true)
	save.erase("company_story_dossier_state")
	var companies_payload: Dictionary = save.get("companies", {}).duplicate(true)
	for company_id_value in companies_payload.keys():
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = companies_payload.get(company_id, {}).duplicate(true)
		runtime.erase("company_story_dossier_state")
		companies_payload[company_id] = runtime
	save["companies"] = companies_payload
	return save


func _partial_dossier_state(source_save: Dictionary, story_id: String, company_id: String) -> Dictionary:
	var save: Dictionary = source_save.duplicate(true)
	var state: Dictionary = save.get("company_story_dossier_state", {}).duplicate(true)
	var dossier_index: Dictionary = state.get("dossier_index", {}).duplicate(true)
	var dossier: Dictionary = dossier_index.get(story_id, {}).duplicate(true)
	var price_effects: Dictionary = dossier.get("price_effects", {}).duplicate(true)
	price_effects["drift_bps"] = 999.0
	dossier["schema_version"] = -9
	dossier["truth_state"] = "too_loud"
	dossier["public_status"] = "too_loud"
	dossier["stage_id"] = "too_loud"
	dossier["priority"] = 99.0
	dossier["confidence"] = -9.0
	dossier["price_effects"] = price_effects
	dossier_index = {story_id: dossier}
	state = {
		"schema_version": -3,
		"generated": true,
		"run_seed": str(RUN_SEED),
		"generated_day_index": "0",
		"active_story_ids": [story_id, story_id, ""],
		"resolved_story_ids": [],
		"dossier_index": dossier_index,
		"company_story_ids": {company_id: [story_id, story_id, ""]},
		"recent_resolved_stories": []
	}
	save["company_story_dossier_state"] = state

	var companies_payload: Dictionary = save.get("companies", {}).duplicate(true)
	var runtime: Dictionary = companies_payload.get(company_id, {}).duplicate(true)
	runtime["company_story_dossier_state"] = {
		"schema_version": -1,
		"company_id": "wrong_company",
		"active_story_ids": [story_id, story_id, ""],
		"resolved_story_ids": [],
		"current_story_id": "missing_story",
		"current_stage_by_story_id": {story_id: "too_loud"},
		"public_status_by_story_id": {story_id: "too_loud"},
		"last_story_day_index": "7",
		"recent_story_ids": [story_id, story_id]
	}
	companies_payload[company_id] = runtime
	save["companies"] = companies_payload
	return save


func _fail(message: String) -> void:
	push_error(message)
	print("COMPANY_STORY_DOSSIER_SAVE_DEFAULTS_FAIL: %s" % message)
	get_tree().quit(1)
