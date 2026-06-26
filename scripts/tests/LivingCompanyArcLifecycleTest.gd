extends Node

const RUN_SEED := 20260616


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)

	var company_id: String = str(RunState.company_order[0])
	var primary_arc: Dictionary = _build_arc(company_id, 1, 3, "earnings_beat", "company_arc", "earnings", "positive")
	_apply_day_result([_arc_for_phase(primary_arc, 1, "accumulation", "Accumulation")])
	if not _assert_active_state(company_id, "primary_arc", 1, "accumulation"):
		return

	_apply_day_result([_arc_for_phase(primary_arc, 2, "breakout", "Breakout")])
	if not _assert_active_state(company_id, "primary_arc", 2, "breakout"):
		return

	_apply_day_result([_arc_for_phase(primary_arc, 3, "sideways", "Sideways")])
	if not _assert_active_state(company_id, "primary_arc", 3, "sideways"):
		return

	_apply_day_result([])
	if not _assert_resolved_state(company_id):
		return

	var later_day: int = 33
	if RunState.get_company_living_arc_status(company_id, later_day) != "eligible":
		_fail("Expected company to become eligible after cooldown day.")
		return
	var roadmap_arc: Dictionary = _build_arc(company_id, later_day, later_day + 4, "roadmap_channel_rollout", "company_roadmap", "roadmap_strategy", "mixed")
	RunState.sync_living_company_arcs_for_day(later_day, [_arc_for_phase(roadmap_arc, later_day, "public_watch", "Public watch")])
	var later_state: Dictionary = RunState.get_company_living_arc_state(company_id)
	if str(later_state.get("active_arc_id", "")) != "roadmap_channel_rollout_%s_%d" % [company_id, later_day]:
		_fail("Expected eligible company to accept a later roadmap arc.")
		return
	if later_state.get("completed_arcs", []).size() != 1:
		_fail("Expected previous completed arc to remain after later activation.")
		return

	print("LIVING_COMPANY_ARC_LIFECYCLE_TEST_OK")
	get_tree().quit(0)


func _apply_day_result(active_arcs: Array) -> void:
	var company_payloads: Dictionary = {}
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		company_payloads[company_id] = RunState.get_company(company_id).duplicate(true)
	RunState.apply_day_result({
		"day_number": RunState.day_index + 1,
		"trade_date": RunState.get_current_trade_date(),
		"market_sentiment": RunState.market_sentiment,
		"companies": company_payloads,
		"active_company_arcs": active_arcs,
		"company_roadmap_state": RunState.get_company_roadmap_state(),
		"active_special_events": [],
		"active_corporate_action_chains": RunState.get_active_corporate_action_chains(),
		"corporate_meeting_calendar": RunState.get_corporate_meeting_calendar(),
		"corporate_action_intel": RunState.get_corporate_action_intel(),
		"corporate_dividend_calendar": RunState.get_corporate_dividend_calendar(),
		"index_review_state": RunState.get_index_review_state()
	})


func _build_arc(
	company_id: String,
	start_day: int,
	end_day: int,
	event_id: String,
	source_system: String,
	arc_type: String,
	tone: String
) -> Dictionary:
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	return {
		"arc_id": "%s_%s_%d" % [event_id, company_id, start_day],
		"event_id": event_id,
		"event_family": source_system,
		"source_system": source_system,
		"category": arc_type,
		"scope": "company",
		"tone": tone,
		"target_company_id": company_id,
		"target_sector_id": str(definition.get("sector_id", "")),
		"target_ticker": str(definition.get("ticker", company_id.to_upper())),
		"target_company_name": str(definition.get("name", company_id.to_upper())),
		"start_day_index": start_day,
		"end_day_index": end_day,
		"duration_days": end_day - start_day + 1,
		"story_tags": [source_system, arc_type, event_id]
	}


func _arc_for_phase(arc: Dictionary, day_number: int, phase_id: String, phase_label: String) -> Dictionary:
	var phased_arc: Dictionary = arc.duplicate(true)
	phased_arc["day_index"] = day_number
	phased_arc["current_phase_id"] = phase_id
	phased_arc["current_phase_label"] = phase_label
	phased_arc["phase_visibility"] = "visible"
	phased_arc["phase_sentiment_shift"] = 0.03
	phased_arc["phase_volatility_multiplier"] = 1.1
	return phased_arc


func _assert_active_state(company_id: String, expected_arc_key: String, day_number: int, expected_phase_id: String) -> bool:
	var arc_state: Dictionary = RunState.get_company_living_arc_state(company_id)
	if RunState.get_company_living_arc_status(company_id, day_number) != "active":
		_fail("Expected company %s to be active on day %d." % [company_id, day_number])
		return false
	if str(arc_state.get("active_arc_id", "")) != "earnings_beat_%s_1" % company_id:
		_fail("Expected %s active id for %s." % [expected_arc_key, company_id])
		return false
	if str(arc_state.get("active_phase_id", "")) != expected_phase_id:
		_fail("Expected active phase %s for %s." % [expected_phase_id, company_id])
		return false
	if int(arc_state.get("active_arc_started_day", 0)) != 1 or int(arc_state.get("active_arc_expected_end_day", 0)) != 3:
		_fail("Expected active day bounds to stay stable for %s." % company_id)
		return false
	var global_state: Dictionary = RunState.get_living_company_arc_state()
	if not global_state.get("active_arc_ids", []).has("earnings_beat_%s_1" % company_id):
		_fail("Expected global active arc index to include primary arc.")
		return false
	return true


func _assert_resolved_state(company_id: String) -> bool:
	var arc_state: Dictionary = RunState.get_company_living_arc_state(company_id)
	if RunState.get_company_living_arc_status(company_id, 4) != "cooling_down":
		_fail("Expected company to enter cooldown after active arc disappears.")
		return false
	if not str(arc_state.get("active_arc_id", "")).is_empty():
		_fail("Expected active arc id to clear after resolution.")
		return false
	if int(arc_state.get("last_resolved_day", -1)) != 4:
		_fail("Expected last resolved day to be 4.")
		return false
	var cooldowns: Dictionary = arc_state.get("cooldowns", {})
	if int(cooldowns.get("any", 0)) != 16 or int(cooldowns.get("company_arc", 0)) != 32:
		_fail("Expected any/company_arc cooldowns to be applied after resolution.")
		return false
	if int(cooldowns.get("event:earnings_beat", 0)) != 32:
		_fail("Expected event-specific cooldown to match source cooldown.")
		return false
	var completed_arcs: Array = arc_state.get("completed_arcs", [])
	if completed_arcs.size() != 1:
		_fail("Expected one completed arc row.")
		return false
	var completed: Dictionary = completed_arcs[0]
	if str(completed.get("arc_id", "")) != "earnings_beat_%s_1" % company_id:
		_fail("Expected completed arc row to preserve arc id.")
		return false
	if int(completed.get("started_day_index", 0)) != 1 or int(completed.get("resolved_day_index", 0)) != 4:
		_fail("Expected completed arc row to preserve day bounds.")
		return false
	if int(completed.get("duration_days", 0)) != 3:
		_fail("Expected completed duration to reflect active schedule.")
		return false
	var story_memory: Dictionary = arc_state.get("story_memory", {})
	if int(story_memory.get("completed_count", 0)) != 1 or int(story_memory.get("positive_count", 0)) != 1:
		_fail("Expected story memory counters to update after completion.")
		return false
	var global_state: Dictionary = RunState.get_living_company_arc_state()
	if not global_state.get("active_arc_ids", []).is_empty():
		_fail("Expected global active arc ids to clear after resolution.")
		return false
	if int(global_state.get("completed_arc_count", 0)) != 1 or global_state.get("recent_completed_arcs", []).size() != 1:
		_fail("Expected global completed arc audit to update.")
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
