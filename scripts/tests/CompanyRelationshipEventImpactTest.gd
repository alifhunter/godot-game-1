extends Node

const COMPANY_RELATIONSHIP_GRAPH_SYSTEM := preload("res://systems/CompanyRelationshipGraphSystem.gd")
const MARKET_SIMULATOR := preload("res://systems/MarketSimulator.gd")

const RUN_SEED := 20260622
const CATALOG_COMPANY_COUNT := 30


class ForcedRelationshipGraphSystem:
	extends RefCounted

	var force_edge_id: String = ""
	var real_graph_system

	func _init(p_real_graph_system, p_force_edge_id: String) -> void:
		real_graph_system = p_real_graph_system
		force_edge_id = p_force_edge_id

	func resolve_day(run_state, trade_date: Dictionary, day_number: int, macro_state: Dictionary, options: Dictionary = {}) -> Dictionary:
		var forced_options: Dictionary = options.duplicate(true)
		forced_options["force_event"] = true
		forced_options["force_edge_id"] = force_edge_id
		forced_options["blocked_company_ids"] = []
		return real_graph_system.resolve_day(run_state, trade_date, day_number, macro_state, forced_options)


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var edge: Dictionary = _setup_run_and_pick_edge()
	if edge.is_empty():
		return
	if not _assert_resolver_event(edge):
		return
	if not _assert_simulation_integration(edge):
		return

	print("COMPANY_RELATIONSHIP_EVENT_IMPACT_OK %s" % JSON.stringify({
		"edge_id": str(edge.get("edge_id", "")),
		"relationship_type": str(edge.get("relationship_type", "")),
		"source_company_id": str(edge.get("source_company_id", "")),
		"target_company_id": str(edge.get("target_company_id", ""))
	}))
	get_tree().quit(0)


func _setup_run_and_pick_edge() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = CATALOG_COMPANY_COUNT
	difficulty_config["use_company_universe_catalog"] = true
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	var state: Dictionary = RunState.get_company_relationship_graph_state()
	var edge: Dictionary = _first_eligible_edge(state)
	if edge.is_empty():
		_fail("Expected at least one public or semi-public supplier/customer/partner/competitor edge.")
	return edge


func _assert_resolver_event(edge: Dictionary) -> bool:
	var graph_system = COMPANY_RELATIONSHIP_GRAPH_SYSTEM.new()
	var day_number: int = 8
	var trade_date: Dictionary = RunState.trading_calendar.trade_date_for_index(day_number)
	var macro_state: Dictionary = RunState.get_macro_state_for_year(int(trade_date.get("year", 2020)))
	var result: Dictionary = graph_system.resolve_day(
		RunState,
		trade_date,
		day_number,
		macro_state,
		{
			"force_event": true,
			"force_edge_id": str(edge.get("edge_id", ""))
		}
	)
	var events: Array = result.get("relationship_graph_events", [])
	if events.size() != 2:
		_fail("Expected forced relationship event to emit exactly two company rows, got %d." % events.size())
		return false
	if not _assert_event_rows(events, edge):
		return false
	var next_state: Dictionary = result.get("company_relationship_graph_state", {})
	var next_edge_index: Dictionary = next_state.get("edge_index", {}) if typeof(next_state.get("edge_index", {})) == TYPE_DICTIONARY else {}
	var next_edge: Dictionary = next_edge_index.get(str(edge.get("edge_id", "")), {})
	if int(next_edge.get("event_cooldown_until_day", -1)) <= day_number:
		_fail("Expected forced event to update edge cooldown, got %s." % JSON.stringify(next_edge))
		return false
	return true


func _assert_simulation_integration(edge: Dictionary) -> bool:
	edge = _setup_run_and_pick_edge()
	var forced_graph_system = ForcedRelationshipGraphSystem.new(
		COMPANY_RELATIONSHIP_GRAPH_SYSTEM.new(),
		str(edge.get("edge_id", ""))
	)
	GameManager.market_simulator = MARKET_SIMULATOR.new(
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		forced_graph_system
	)
	var advance_result: Dictionary = GameManager.simulate_opening_session(false)
	var day_result: Dictionary = advance_result.get("day_result", {})
	var events: Array = day_result.get("relationship_graph_events", [])
	if events.size() != 2:
		_fail("Expected simulation day to carry exactly two relationship graph event rows, got %d." % events.size())
		return false
	if not _assert_event_rows(events, edge):
		return false
	var family_count: int = 0
	for event_value in RunState.get_event_history():
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_value
		if str(event.get("event_family", "")) == COMPANY_RELATIONSHIP_GRAPH_SYSTEM.SOURCE_SYSTEM_ID:
			family_count += 1
	if family_count != 2:
		_fail("Expected event history to record two relationship graph rows, got %d." % family_count)
		return false
	for event_value in events:
		var event: Dictionary = event_value
		var company_id: String = str(event.get("target_company_id", ""))
		var runtime: Dictionary = RunState.get_company(company_id)
		if not _runtime_has_relationship_event(runtime, str(event.get("relationship_event_id", ""))):
			_fail("Expected runtime for '%s' to include active relationship event." % company_id)
			return false
	var state: Dictionary = RunState.get_company_relationship_graph_state()
	var edge_index: Dictionary = state.get("edge_index", {}) if typeof(state.get("edge_index", {})) == TYPE_DICTIONARY else {}
	var updated_edge: Dictionary = edge_index.get(str(edge.get("edge_id", "")), {})
	if int(updated_edge.get("event_cooldown_until_day", -1)) <= int(RunState.day_index):
		_fail("Expected simulation integration to persist edge cooldown, got %s." % JSON.stringify(updated_edge))
		return false
	var save_dict: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(save_dict)
	var loaded_state: Dictionary = RunState.get_company_relationship_graph_state()
	var loaded_edge_index: Dictionary = loaded_state.get("edge_index", {}) if typeof(loaded_state.get("edge_index", {})) == TYPE_DICTIONARY else {}
	var loaded_edge: Dictionary = loaded_edge_index.get(str(edge.get("edge_id", "")), {})
	if int(loaded_edge.get("event_cooldown_until_day", -1)) != int(updated_edge.get("event_cooldown_until_day", -1)):
		_fail("Expected relationship edge cooldown to survive save/load.")
		return false
	return true


func _assert_event_rows(events: Array, edge: Dictionary) -> bool:
	var relationship_event_ids: Array = []
	var impacted_companies: Array = []
	for event_value in events:
		if typeof(event_value) != TYPE_DICTIONARY:
			_fail("Relationship event row was not a dictionary.")
			return false
		var event: Dictionary = event_value
		if str(event.get("event_family", "")) != COMPANY_RELATIONSHIP_GRAPH_SYSTEM.SOURCE_SYSTEM_ID:
			_fail("Expected relationship event family, got %s." % str(event.get("event_family", "")))
			return false
		if str(event.get("relationship_edge_id", "")) != str(edge.get("edge_id", "")):
			_fail("Expected event to reference forced edge.")
			return false
		if str(event.get("scope", "")) != "company":
			_fail("Expected company-scoped relationship event.")
			return false
		var shift: float = float(event.get("sentiment_shift", 0.0))
		if absf(shift) > 0.024:
			_fail("Relationship event shift was outside bounded range: %s" % String.num(shift, 5))
			return false
		var relationship_event_id: String = str(event.get("relationship_event_id", ""))
		if relationship_event_id.is_empty():
			_fail("Expected shared relationship_event_id.")
			return false
		if not relationship_event_ids.has(relationship_event_id):
			relationship_event_ids.append(relationship_event_id)
		var company_id: String = str(event.get("target_company_id", ""))
		if company_id.is_empty():
			_fail("Expected impacted company id.")
			return false
		if not impacted_companies.has(company_id):
			impacted_companies.append(company_id)
	if relationship_event_ids.size() != 1:
		_fail("Expected both company rows to share one relationship event id.")
		return false
	if impacted_companies.size() != 2:
		_fail("Expected exactly two distinct impacted companies, got %s." % JSON.stringify(impacted_companies))
		return false
	return true


func _runtime_has_relationship_event(runtime: Dictionary, relationship_event_id: String) -> bool:
	for event_value in runtime.get("active_events", []):
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_value
		if str(event.get("relationship_event_id", "")) == relationship_event_id:
			return true
	return false


func _first_eligible_edge(state: Dictionary) -> Dictionary:
	var edge_ids: Array = state.get("edge_ids", []) if typeof(state.get("edge_ids", [])) == TYPE_ARRAY else []
	var edge_index: Dictionary = state.get("edge_index", {}) if typeof(state.get("edge_index", {})) == TYPE_DICTIONARY else {}
	for preferred_type in ["partner", "supplier", "customer", "competitor"]:
		for edge_id_value in edge_ids:
			var edge: Dictionary = edge_index.get(str(edge_id_value), {})
			if edge.is_empty():
				continue
			if str(edge.get("relationship_type", "")) != preferred_type:
				continue
			if not (str(edge.get("visibility", "")) in COMPANY_RELATIONSHIP_GRAPH_SYSTEM.EVENT_ELIGIBLE_VISIBILITIES):
				continue
			return edge.duplicate(true)
	return {}


func _fail(message: String) -> void:
	push_error(message)
	print("COMPANY_RELATIONSHIP_EVENT_IMPACT_FAIL %s" % message)
	get_tree().quit(1)
