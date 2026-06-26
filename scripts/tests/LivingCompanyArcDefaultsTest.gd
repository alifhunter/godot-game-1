extends Node

const RUN_SEED := 20260615


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)

	if not _assert_default_state("new run"):
		return
	if not _assert_save_payload_defaults():
		return
	if not _assert_legacy_save_backfill():
		return
	if not _assert_partial_state_normalization():
		return

	print("LIVING_COMPANY_ARC_DEFAULTS_TEST_OK")
	get_tree().quit(0)


func _assert_default_state(label: String) -> bool:
	var run_state: Dictionary = RunState.get_living_company_arc_state()
	if int(run_state.get("schema_version", 0)) != 1:
		_fail("Expected living arc schema version 1 for %s." % label)
		return false
	if not run_state.get("active_arc_ids", []).is_empty():
		_fail("Expected no active living arcs for %s." % label)
		return false
	if typeof(run_state.get("active_arc_index", {})) != TYPE_DICTIONARY:
		_fail("Expected active arc index dictionary for %s." % label)
		return false

	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var arc_state: Dictionary = RunState.get_company_living_arc_state(company_id)
		if int(arc_state.get("schema_version", 0)) != 1:
			_fail("Expected company %s living arc schema version 1 for %s." % [company_id, label])
			return false
		if str(arc_state.get("company_id", "")) != company_id:
			_fail("Expected company id mirror for %s in %s." % [company_id, label])
			return false
		if not str(arc_state.get("active_arc_id", "")).is_empty():
			_fail("Expected company %s to start with no active living arc in %s." % [company_id, label])
			return false
		var cooldowns: Dictionary = arc_state.get("cooldowns", {})
		for cooldown_key in ["any", "company_arc", "company_roadmap", "corporate_action", "index_review", "macro_sector", "relationship_graph"]:
			if int(cooldowns.get(cooldown_key, 0)) != -999:
				_fail("Expected default cooldown %s=-999 for %s in %s." % [cooldown_key, company_id, label])
				return false
		var story_memory: Dictionary = arc_state.get("story_memory", {})
		if int(story_memory.get("completed_count", -1)) != 0:
			_fail("Expected empty story memory for %s in %s." % [company_id, label])
			return false
	return true


func _assert_save_payload_defaults() -> bool:
	var save_payload: Dictionary = RunState.to_save_dict()
	if typeof(save_payload.get("living_company_arc_state", {})) != TYPE_DICTIONARY:
		_fail("Expected save payload to include living_company_arc_state.")
		return false
	var save_companies: Dictionary = save_payload.get("companies", {})
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = save_companies.get(company_id, {})
		if typeof(runtime.get("living_arc_state", {})) != TYPE_DICTIONARY:
			_fail("Expected save payload company %s to include living_arc_state." % company_id)
			return false
	return true


func _assert_legacy_save_backfill() -> bool:
	var legacy_save: Dictionary = RunState.to_save_dict()
	var start_day_index: int = int(legacy_save.get("day_index", 0))
	legacy_save.erase("living_company_arc_state")
	var legacy_companies: Dictionary = legacy_save.get("companies", {}).duplicate(true)
	for company_id_value in legacy_companies.keys():
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = legacy_companies.get(company_id, {}).duplicate(true)
		runtime.erase("living_arc_state")
		legacy_companies[company_id] = runtime
	legacy_save["companies"] = legacy_companies

	RunState.load_from_dict(legacy_save)
	if not _assert_default_state("legacy save backfill"):
		return false

	GameManager.simulate_opening_session(false)
	if RunState.day_index <= start_day_index:
		_fail("Expected legacy-style save to advance through existing day simulation.")
		return false
	if not _assert_default_state("legacy save after day advance"):
		return false
	return true


func _assert_partial_state_normalization() -> bool:
	var save_payload: Dictionary = RunState.to_save_dict()
	var first_company_id: String = str(RunState.company_order[0])
	var live_arc_id: String = "live_arc"
	save_payload["living_company_arc_state"] = {
		"schema_version": -10,
		"active_arc_ids": [live_arc_id, live_arc_id, ""],
		"active_company_ids": [first_company_id, first_company_id, ""],
		"active_arc_index": {},
		"recent_completed_arcs": [
			{
				"arc_id": "global_done",
				"source_system": "company_arc",
				"story_tags": ["turnaround", "turnaround"]
			}
		],
		"completed_arc_count": 1,
		"source_last_spawn_day": {"company_arc": "7"},
		"source_daily_start_counts": {"company_arc": "2"}
	}
	save_payload["living_company_arc_state"]["active_arc_index"][live_arc_id] = {
		"arc_id": live_arc_id,
		"target_company_id": first_company_id,
		"source_system": "company_arc",
		"arc_type": "earnings",
		"tone": "LOUD",
		"started_day_index": "2",
		"expected_end_day_index": "5"
	}
	save_payload["active_company_arcs"] = [
		{
			"arc_id": live_arc_id,
			"target_company_id": first_company_id,
			"source_system": "company_arc",
			"event_family": "company_arc",
			"category": "earnings",
			"event_id": "earnings_beat",
			"tone": "LOUD",
			"start_day_index": 2,
			"end_day_index": RunState.day_index + 10,
			"current_phase_id": "breakout",
			"current_phase_label": "Breakout"
		}
	]

	var companies_payload: Dictionary = save_payload.get("companies", {}).duplicate(true)
	var runtime: Dictionary = companies_payload.get(first_company_id, {}).duplicate(true)
	var completed_arcs: Array = []
	for index in range(10):
		completed_arcs.append({
			"arc_id": "done_%d" % index,
			"source_system": "company_arc",
			"arc_type": "earnings",
			"tone": "positive",
			"started_day_index": index,
			"resolved_day_index": index + 2,
			"story_tags": ["beat", "beat"]
		})
	runtime["living_arc_state"] = {
		"schema_version": -1,
		"company_id": "wrong_company",
		"active_arc_id": " %s " % live_arc_id,
		"active_source_system": " company_arc ",
		"active_arc_type": " earnings ",
		"active_event_id": " earnings_beat ",
		"active_tone": "LOUD",
		"active_arc_started_day": "3",
		"active_arc_expected_end_day": "8",
		"last_resolved_day": "1",
		"cooldowns": {
			"any": "12",
			"custom_future_source": "15"
		},
		"eligibility_tags": ["growth", "growth", "turnaround"],
		"suppression_tags": ["blocked", "blocked"],
		"completed_arcs": completed_arcs,
		"story_memory": {
			"completed_count": "1",
			"last_tone": "LOUD",
			"recent_arc_ids": ["a", "a", "b"],
			"recent_story_tags": ["beat", "beat", "miss"]
		}
	}
	companies_payload[first_company_id] = runtime
	save_payload["companies"] = companies_payload

	RunState.load_from_dict(save_payload)
	var global_state: Dictionary = RunState.get_living_company_arc_state()
	if int(global_state.get("schema_version", 0)) != 1:
		_fail("Expected malformed global living state to normalize schema version.")
		return false
	if global_state.get("active_arc_ids", []).size() != 1:
		_fail("Expected duplicate global active arc ids to collapse.")
		return false
	var active_index: Dictionary = global_state.get("active_arc_index", {})
	var active_row: Dictionary = active_index.get(live_arc_id, {})
	if str(active_row.get("tone", "")) != "neutral" or int(active_row.get("started_day_index", -1)) != 2:
		_fail("Expected active arc index row to normalize tone and day.")
		return false
	if int(global_state.get("source_last_spawn_day", {}).get("company_arc", -1)) != 7:
		_fail("Expected source spawn day to normalize to int.")
		return false

	var company_state: Dictionary = RunState.get_company_living_arc_state(first_company_id)
	if str(company_state.get("company_id", "")) != first_company_id:
		_fail("Expected company living state to use owning company id.")
		return false
	if str(company_state.get("active_arc_id", "")) != "live_arc":
		_fail("Expected active arc id to be trimmed.")
		return false
	if str(company_state.get("active_tone", "")) != "neutral":
		_fail("Expected invalid active tone to normalize to neutral.")
		return false
	var cooldowns: Dictionary = company_state.get("cooldowns", {})
	if int(cooldowns.get("any", 0)) != 12 or int(cooldowns.get("company_arc", 0)) != -999:
		_fail("Expected living cooldowns to merge source and defaults.")
		return false
	var eligibility_tags: Array = company_state.get("eligibility_tags", [])
	if eligibility_tags.is_empty():
		_fail("Expected living eligibility tags to refresh from company facts.")
		return false
	var seen_eligibility_tags: Dictionary = {}
	for tag_value in eligibility_tags:
		var tag: String = str(tag_value)
		if seen_eligibility_tags.has(tag):
			_fail("Expected living eligibility tags to de-duplicate after refresh.")
			return false
		seen_eligibility_tags[tag] = true
	if company_state.get("suppression_tags", []).size() != 1:
		_fail("Expected living tag arrays to de-duplicate.")
		return false
	var normalized_completed: Array = company_state.get("completed_arcs", [])
	if normalized_completed.size() != 8:
		_fail("Expected completed arcs to cap at eight rows.")
		return false
	if str(normalized_completed[0].get("arc_id", "")) != "done_2" or str(normalized_completed[7].get("arc_id", "")) != "done_9":
		_fail("Expected completed arc cap to keep newest rows.")
		return false
	var story_memory: Dictionary = company_state.get("story_memory", {})
	if int(story_memory.get("completed_count", 0)) != 8:
		_fail("Expected story memory completed count to reflect retained rows.")
		return false
	if story_memory.get("recent_arc_ids", []).size() != 2:
		_fail("Expected story memory recent ids to de-duplicate.")
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
