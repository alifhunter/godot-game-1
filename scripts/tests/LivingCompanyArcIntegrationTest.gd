extends Node

const RUN_SEED := 20260617
const COMPANY_EVENT_SYSTEM_SCRIPT = preload("res://systems/CompanyEventSystem.gd")
const COMPANY_ROADMAP_SYSTEM_SCRIPT = preload("res://systems/CompanyRoadmapSystem.gd")

var company_event_system = COMPANY_EVENT_SYSTEM_SCRIPT.new()
var company_roadmap_system = COMPANY_ROADMAP_SYSTEM_SCRIPT.new()


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)

	if not _assert_company_event_living_gate():
		return
	if not _assert_roadmap_living_gate():
		return

	print("LIVING_COMPANY_ARC_INTEGRATION_TEST_OK")
	get_tree().quit(0)


func _assert_company_event_living_gate() -> bool:
	var day_number: int = 30
	var trade_date: Dictionary = RunState.trading_calendar.trade_date_for_index(day_number)
	var macro_state: Dictionary = RunState.get_macro_state_for_year(int(trade_date.get("year", 2020)))
	var candidate: Dictionary = _first_company_arc_candidate(trade_date, day_number, macro_state)
	if candidate.is_empty():
		_fail("Expected at least one company arc candidate for the integration test.")
		return false
	var company_id: String = str(candidate.get("target_company_id", ""))
	var event_id: String = str(candidate.get("event_id", ""))
	var directives: Dictionary = {
		"force_company_arc_start": true,
		"focus_company_ids": [company_id],
		"blocked_company_ids": _all_company_ids_except(company_id)
	}
	var control_result: Dictionary = company_event_system.resolve_day(RunState, trade_date, day_number, macro_state, directives)
	if control_result.get("active_arcs", []).is_empty():
		_fail("Expected focused control company arc to start before living gate is applied.")
		return false
	var control_arc: Dictionary = control_result.get("active_arcs", [])[0]
	if str(control_arc.get("target_company_id", "")) != company_id:
		_fail("Expected focused control arc to target the selected company.")
		return false

	RunState.set_company_living_arc_state(company_id, {
		"company_id": company_id,
		"active_arc_id": "manual_active_block",
		"active_source_system": "company_arc",
		"active_arc_type": "earnings",
		"active_event_id": event_id,
		"active_tone": "positive",
		"active_arc_started_day": day_number - 1,
		"active_arc_expected_end_day": day_number + 4
	})
	var active_block_result: Dictionary = company_event_system.resolve_day(RunState, trade_date, day_number, macro_state, directives)
	if not active_block_result.get("active_arcs", []).is_empty():
		_fail("Expected living active state to block a duplicate company arc.")
		return false

	var cooldowns: Dictionary = {
		"any": day_number + 4,
		"company_arc": day_number + 8
	}
	cooldowns["event:%s" % event_id] = day_number + 8
	RunState.set_company_living_arc_state(company_id, {
		"company_id": company_id,
		"cooldowns": cooldowns
	})
	var cooldown_block_result: Dictionary = company_event_system.resolve_day(RunState, trade_date, day_number, macro_state, directives)
	if not cooldown_block_result.get("active_arcs", []).is_empty():
		_fail("Expected living cooldown state to block a company arc.")
		return false

	var override_directives: Dictionary = directives.duplicate(true)
	override_directives["allow_living_arc_cooldown"] = true
	var override_result: Dictionary = company_event_system.resolve_day(RunState, trade_date, day_number, macro_state, override_directives)
	if override_result.get("active_arcs", []).is_empty():
		_fail("Expected explicit cooldown override to allow the focused company arc.")
		return false
	RunState.set_company_living_arc_state(company_id, {})
	return true


func _assert_roadmap_living_gate() -> bool:
	var day_number: int = 35
	var trade_date: Dictionary = RunState.trading_calendar.trade_date_for_index(day_number)
	var macro_state: Dictionary = RunState.get_macro_state_for_year(int(trade_date.get("year", 2020)))
	var eligible_company_id: String = _first_roadmap_company_id()
	if eligible_company_id.is_empty():
		_fail("Expected at least one roadmap-capable company.")
		return false

	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		RunState.set_company_living_arc_state(company_id, {
			"company_id": company_id,
			"active_arc_id": "roadmap_block_%s" % company_id,
			"active_source_system": "company_arc",
			"active_arc_type": "test_block",
			"active_event_id": "test_block",
			"active_tone": "neutral",
			"active_arc_started_day": day_number - 1,
			"active_arc_expected_end_day": day_number + 5
		})
	var blocked_candidate: Dictionary = company_roadmap_system._pick_spawn_candidate(RunState, day_number, macro_state, {}, {})
	if not blocked_candidate.is_empty():
		_fail("Expected roadmap selection to skip all living-blocked companies.")
		return false

	RunState.set_company_living_arc_state(eligible_company_id, {})
	var eligible_candidate: Dictionary = company_roadmap_system._pick_spawn_candidate(RunState, day_number, macro_state, {}, {})
	if str(eligible_candidate.get("company_id", "")) != eligible_company_id:
		_fail("Expected roadmap selection to resume with the only eligible company.")
		return false
	return true


func _first_company_arc_candidate(trade_date: Dictionary, day_number: int, macro_state: Dictionary) -> Dictionary:
	var candidates: Array = company_event_system.build_company_arc_candidates(RunState, trade_date, day_number, macro_state, {})
	if candidates.is_empty():
		return {}
	return candidates[0].duplicate(true)


func _first_roadmap_company_id() -> String:
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		var family: Dictionary = company_roadmap_system.roadmap_family_for_profile(
			definition.get("roadmap_profile", {}),
			str(definition.get("sector_id", ""))
		)
		if not family.is_empty():
			return company_id
	return ""


func _all_company_ids_except(company_id: String) -> Array:
	var ids: Array = []
	for company_id_value in RunState.company_order:
		var other_company_id: String = str(company_id_value)
		if other_company_id != company_id:
			ids.append(other_company_id)
	return ids


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
