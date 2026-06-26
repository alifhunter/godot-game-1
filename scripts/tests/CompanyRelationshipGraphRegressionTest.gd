extends Node

const COMPANY_RELATIONSHIP_GRAPH_SYSTEM := preload("res://systems/CompanyRelationshipGraphSystem.gd")

const RUN_SEED := 20260622
const CATALOG_COMPANY_COUNT := 30


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var issues: Array[String] = []
	_setup_catalog_run()
	var state: Dictionary = RunState.get_company_relationship_graph_state()
	_validate_graph_state(state, issues)
	_validate_event_type_coverage(issues)
	_validate_private_edge_suppression(issues)
	_validate_mna_candidate_fixture_guard(issues)

	if not issues.is_empty():
		_fail("Relationship graph regression issues: %s" % JSON.stringify(issues))
		return

	print("COMPANY_RELATIONSHIP_GRAPH_REGRESSION_OK %s" % JSON.stringify({
		"seed": RUN_SEED,
		"edge_count": int(state.get("edge_ids", []).size()),
		"event_types_checked": COMPANY_RELATIONSHIP_GRAPH_SYSTEM.EVENT_KIND_BY_TYPE.keys().size(),
		"private_guard_checked": true,
		"mna_fixture_checked": true
	}))
	get_tree().quit(0)


func _setup_catalog_run() -> void:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = CATALOG_COMPANY_COUNT
	difficulty_config["use_company_universe_catalog"] = true
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)


func _validate_graph_state(state: Dictionary, issues: Array[String]) -> void:
	if not bool(state.get("generated", false)):
		issues.append("graph_not_generated")
	if int(state.get("schema_version", 0)) != COMPANY_RELATIONSHIP_GRAPH_SYSTEM.SCHEMA_VERSION:
		issues.append("bad_schema_version")
	if not _string_array(state.get("validation_issues", [])).is_empty():
		issues.append("state_validation_issues:%s" % JSON.stringify(_string_array(state.get("validation_issues", []))))

	var edge_ids: Array = _string_array(state.get("edge_ids", []))
	var edge_index: Dictionary = state.get("edge_index", {}) if typeof(state.get("edge_index", {})) == TYPE_DICTIONARY else {}
	var company_edge_ids: Dictionary = state.get("company_edge_ids", {}) if typeof(state.get("company_edge_ids", {})) == TYPE_DICTIONARY else {}
	var selected_lookup: Dictionary = _lookup(RunState.company_order)
	var seen_canonical: Dictionary = {}
	var actual_counts_by_type: Dictionary = {}
	var actual_counts_by_visibility: Dictionary = {}
	var actual_counts_by_origin: Dictionary = {}
	var outgoing_counts: Dictionary = {}
	var incoming_counts: Dictionary = {}
	var incident_counts: Dictionary = {}
	var competitor_counts: Dictionary = {}

	for edge_id_value in edge_ids:
		var edge_id: String = str(edge_id_value)
		var edge: Dictionary = edge_index.get(edge_id, {})
		if edge.is_empty():
			issues.append("missing_edge:%s" % edge_id)
			continue
		_validate_edge(edge, selected_lookup, seen_canonical, issues)
		_increment(actual_counts_by_type, str(edge.get("relationship_type", "")))
		_increment(actual_counts_by_visibility, str(edge.get("visibility", "")))
		_increment(actual_counts_by_origin, str(edge.get("origin", "")))
		_increment(outgoing_counts, str(edge.get("source_company_id", "")))
		_increment(incoming_counts, str(edge.get("target_company_id", "")))
		_increment(incident_counts, str(edge.get("source_company_id", "")))
		_increment(incident_counts, str(edge.get("target_company_id", "")))
		if str(edge.get("relationship_type", "")) == "competitor":
			_increment(competitor_counts, str(edge.get("source_company_id", "")))
			_increment(competitor_counts, str(edge.get("target_company_id", "")))

	_validate_counts("type", actual_counts_by_type, state.get("counts_by_type", {}), issues)
	_validate_counts("visibility", actual_counts_by_visibility, state.get("counts_by_visibility", {}), issues)
	_validate_counts("origin", actual_counts_by_origin, state.get("counts_by_origin", {}), issues)
	_validate_density_caps(outgoing_counts, incoming_counts, incident_counts, competitor_counts, issues)
	_validate_company_edge_buckets(edge_index, company_edge_ids, issues)


func _validate_edge(edge: Dictionary, selected_lookup: Dictionary, seen_canonical: Dictionary, issues: Array[String]) -> void:
	var edge_id: String = str(edge.get("edge_id", ""))
	var source_company_id: String = str(edge.get("source_company_id", ""))
	var target_company_id: String = str(edge.get("target_company_id", ""))
	var relationship_type: String = str(edge.get("relationship_type", ""))
	if source_company_id.is_empty() or target_company_id.is_empty():
		issues.append("missing_endpoint:%s" % edge_id)
	if source_company_id == target_company_id:
		issues.append("self_edge:%s" % edge_id)
	if not selected_lookup.has(source_company_id):
		issues.append("source_not_selected:%s:%s" % [edge_id, source_company_id])
	if not selected_lookup.has(target_company_id):
		issues.append("target_not_selected:%s:%s" % [edge_id, target_company_id])
	if not (relationship_type in COMPANY_RELATIONSHIP_GRAPH_SYSTEM.TASK2_GENERATED_TYPES):
		issues.append("unexpected_relationship_type:%s:%s" % [edge_id, relationship_type])
	if str(edge.get("counterpart_type", "")) != str(COMPANY_RELATIONSHIP_GRAPH_SYSTEM.COUNTERPART_BY_TYPE.get(relationship_type, "")):
		issues.append("bad_counterpart:%s" % edge_id)
	if str(edge.get("relationship_scope", "")) != str(COMPANY_RELATIONSHIP_GRAPH_SYSTEM.SCOPE_BY_TYPE.get(relationship_type, "")):
		issues.append("bad_scope:%s" % edge_id)
	if not (str(edge.get("visibility", "")) in COMPANY_RELATIONSHIP_GRAPH_SYSTEM.VALID_VISIBILITIES):
		issues.append("bad_visibility:%s" % edge_id)
	if str(edge.get("lifecycle_status", "")) != "active":
		issues.append("bad_lifecycle_status:%s" % edge_id)
	if not _bounded(edge.get("strength", -1.0)):
		issues.append("bad_strength:%s" % edge_id)
	if not _bounded(edge.get("confidence", -1.0)):
		issues.append("bad_confidence:%s" % edge_id)
	if not _bounded(edge.get("sector_fit_score", -1.0)):
		issues.append("bad_sector_fit:%s" % edge_id)
	var canonical_key: String = COMPANY_RELATIONSHIP_GRAPH_SYSTEM.canonical_edge_key(edge)
	if seen_canonical.has(canonical_key):
		issues.append("duplicate_canonical:%s" % canonical_key)
	seen_canonical[canonical_key] = true


func _validate_counts(label: String, actual: Dictionary, recorded_value: Variant, issues: Array[String]) -> void:
	var recorded: Dictionary = recorded_value if typeof(recorded_value) == TYPE_DICTIONARY else {}
	if JSON.stringify(_sorted_int_dictionary(actual)) != JSON.stringify(_sorted_int_dictionary(recorded)):
		issues.append("%s_count_mismatch actual=%s recorded=%s" % [
			label,
			JSON.stringify(_sorted_int_dictionary(actual)),
			JSON.stringify(_sorted_int_dictionary(recorded))
		])


func _validate_density_caps(
	outgoing_counts: Dictionary,
	incoming_counts: Dictionary,
	incident_counts: Dictionary,
	competitor_counts: Dictionary,
	issues: Array[String]
) -> void:
	for company_id_value in outgoing_counts.keys():
		if int(outgoing_counts.get(company_id_value, 0)) > int(COMPANY_RELATIONSHIP_GRAPH_SYSTEM.DEFAULT_OPTIONS.get("max_outgoing_edges_per_company", 3)):
			issues.append("outgoing_cap:%s:%d" % [str(company_id_value), int(outgoing_counts.get(company_id_value, 0))])
	for company_id_value in incoming_counts.keys():
		if int(incoming_counts.get(company_id_value, 0)) > int(COMPANY_RELATIONSHIP_GRAPH_SYSTEM.DEFAULT_OPTIONS.get("max_incoming_edges_per_company", 4)):
			issues.append("incoming_cap:%s:%d" % [str(company_id_value), int(incoming_counts.get(company_id_value, 0))])
	for company_id_value in incident_counts.keys():
		if int(incident_counts.get(company_id_value, 0)) > int(COMPANY_RELATIONSHIP_GRAPH_SYSTEM.DEFAULT_OPTIONS.get("max_incident_edges_per_company", 5)):
			issues.append("incident_cap:%s:%d" % [str(company_id_value), int(incident_counts.get(company_id_value, 0))])
	for company_id_value in competitor_counts.keys():
		if int(competitor_counts.get(company_id_value, 0)) > int(COMPANY_RELATIONSHIP_GRAPH_SYSTEM.DEFAULT_OPTIONS.get("max_competitor_edges_per_company", 1)):
			issues.append("competitor_cap:%s:%d" % [str(company_id_value), int(competitor_counts.get(company_id_value, 0))])


func _validate_company_edge_buckets(edge_index: Dictionary, company_edge_ids: Dictionary, issues: Array[String]) -> void:
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var expected_incoming: Array = []
		var expected_outgoing: Array = []
		for edge_id_value in edge_index.keys():
			var edge: Dictionary = edge_index.get(edge_id_value, {})
			if str(edge.get("source_company_id", "")) == company_id:
				expected_outgoing.append(str(edge_id_value))
			if str(edge.get("target_company_id", "")) == company_id:
				expected_incoming.append(str(edge_id_value))
		expected_incoming = _string_array(expected_incoming)
		expected_outgoing = _string_array(expected_outgoing)
		var expected_all: Array = _string_array(expected_incoming + expected_outgoing)
		var bucket: Dictionary = company_edge_ids.get(company_id, {}) if typeof(company_edge_ids.get(company_id, {})) == TYPE_DICTIONARY else {}
		if _array_key(expected_incoming) != _array_key(_string_array(bucket.get("incoming", []))):
			issues.append("incoming_bucket_mismatch:%s" % company_id)
		if _array_key(expected_outgoing) != _array_key(_string_array(bucket.get("outgoing", []))):
			issues.append("outgoing_bucket_mismatch:%s" % company_id)
		if _array_key(expected_all) != _array_key(_string_array(bucket.get("all", []))):
			issues.append("all_bucket_mismatch:%s" % company_id)
		var accessor_all: Array = _edge_ids_from_rows(RunState.get_company_relationship_edges_for_company(company_id, true, true))
		var accessor_incoming: Array = _edge_ids_from_rows(RunState.get_company_relationship_edges_for_company(company_id, true, false))
		var accessor_outgoing: Array = _edge_ids_from_rows(RunState.get_company_relationship_edges_for_company(company_id, false, true))
		if _array_key(expected_all) != _array_key(accessor_all):
			issues.append("accessor_all_mismatch:%s" % company_id)
		if _array_key(expected_incoming) != _array_key(accessor_incoming):
			issues.append("accessor_incoming_mismatch:%s" % company_id)
		if _array_key(expected_outgoing) != _array_key(accessor_outgoing):
			issues.append("accessor_outgoing_mismatch:%s" % company_id)


func _validate_event_type_coverage(issues: Array[String]) -> void:
	for relationship_type_value in COMPANY_RELATIONSHIP_GRAPH_SYSTEM.EVENT_KIND_BY_TYPE.keys():
		var relationship_type: String = str(relationship_type_value)
		_setup_catalog_run()
		var edge: Dictionary = _first_edge_for_type(relationship_type, COMPANY_RELATIONSHIP_GRAPH_SYSTEM.EVENT_ELIGIBLE_VISIBILITIES)
		if edge.is_empty():
			issues.append("missing_event_edge:%s" % relationship_type)
			continue
		var events: Array = _resolve_forced_events(edge, {})
		if events.size() != 2:
			issues.append("event_row_count:%s:%d" % [relationship_type, events.size()])
			continue
		_validate_event_rows(relationship_type, edge, events, issues)


func _validate_private_edge_suppression(issues: Array[String]) -> void:
	_setup_catalog_run()
	var private_edge: Dictionary = _first_edge_for_visibility("private")
	if private_edge.is_empty():
		issues.append("missing_private_edge_fixture")
		return
	var suppressed_events: Array = _resolve_forced_events(private_edge, {})
	if not suppressed_events.is_empty():
		issues.append("private_edge_not_suppressed:%s:%d" % [str(private_edge.get("edge_id", "")), suppressed_events.size()])
	var included_events: Array = _resolve_forced_events(private_edge, {"include_private_edges": true})
	if included_events.size() != 2:
		issues.append("private_edge_include_override_failed:%s:%d" % [str(private_edge.get("edge_id", "")), included_events.size()])


func _validate_mna_candidate_fixture_guard(issues: Array[String]) -> void:
	_setup_catalog_run()
	if RunState.company_order.size() < 2:
		issues.append("not_enough_companies_for_mna_fixture")
		return
	var source_company_id: String = str(RunState.company_order[0])
	var target_company_id: String = str(RunState.company_order[1])
	var source_definition: Dictionary = RunState.get_effective_company_definition(source_company_id)
	var target_definition: Dictionary = RunState.get_effective_company_definition(target_company_id)
	var edge_id: String = "edge|%d|%s|%s|acquirer_candidate|fixture" % [RUN_SEED, source_company_id, target_company_id]
	var fixture_edge: Dictionary = {
		"edge_id": edge_id,
		"source_company_id": source_company_id,
		"target_company_id": target_company_id,
		"source_ticker": str(source_definition.get("ticker", "")).to_upper(),
		"target_ticker": str(target_definition.get("ticker", "")).to_upper(),
		"relationship_type": "acquirer_candidate",
		"origin": "manual_test_fixture",
		"strength": 0.72,
		"confidence": 0.61,
		"visibility": "private",
		"sector_fit_score": 0.66,
		"lifecycle_status": "rumored",
		"source_fact_ids": ["fixture|mna_candidate"],
		"source_clue_ids": ["fixture|mna_candidate|private"]
	}
	var manual_state: Dictionary = {
		"schema_version": COMPANY_RELATIONSHIP_GRAPH_SYSTEM.SCHEMA_VERSION,
		"generated": true,
		"run_seed": RUN_SEED,
		"generated_day_index": 0,
		"edge_ids": [edge_id],
		"edge_index": {edge_id: fixture_edge},
		"company_edge_ids": {},
		"counts_by_type": {},
		"counts_by_visibility": {},
		"counts_by_origin": {},
		"unresolved_hook_count": 0,
		"validation_issues": []
	}
	RunState.set_company_relationship_graph_state(manual_state)
	var normalized_edge: Dictionary = RunState.get_company_relationship_edge(edge_id)
	if normalized_edge.is_empty():
		issues.append("mna_fixture_edge_dropped")
		return
	if str(normalized_edge.get("relationship_type", "")) != "acquirer_candidate":
		issues.append("mna_fixture_bad_type")
	if str(normalized_edge.get("counterpart_type", "")) != "target_candidate":
		issues.append("mna_fixture_bad_counterpart")
	if str(normalized_edge.get("relationship_scope", "")) != "mna_candidate":
		issues.append("mna_fixture_bad_scope")
	var events: Array = _resolve_forced_events(normalized_edge, {"include_private_edges": true})
	if not events.is_empty():
		issues.append("mna_candidate_emitted_runtime_event:%d" % events.size())
	var source_profile: Dictionary = RunState.get_company_runtime(source_company_id).profile_dict()
	var target_profile: Dictionary = RunState.get_company_runtime(target_company_id).profile_dict()
	if str(source_profile.get("listing_status", "")) == "acquired_cashout" or bool(source_profile.get("trade_disabled", false)):
		issues.append("mna_fixture_mutated_source_listing")
	if str(target_profile.get("listing_status", "")) == "acquired_cashout" or bool(target_profile.get("trade_disabled", false)):
		issues.append("mna_fixture_mutated_target_listing")


func _validate_event_rows(relationship_type: String, edge: Dictionary, events: Array, issues: Array[String]) -> void:
	var relationship_event_ids: Array = []
	var impacted_companies: Array = []
	var roles: Array = []
	for event_value in events:
		if typeof(event_value) != TYPE_DICTIONARY:
			issues.append("event_not_dictionary:%s" % relationship_type)
			continue
		var event: Dictionary = event_value
		if str(event.get("event_family", "")) != COMPANY_RELATIONSHIP_GRAPH_SYSTEM.SOURCE_SYSTEM_ID:
			issues.append("event_bad_family:%s" % relationship_type)
		if str(event.get("relationship_edge_id", "")) != str(edge.get("edge_id", "")):
			issues.append("event_bad_edge:%s" % relationship_type)
		if str(event.get("relationship_type", "")) != relationship_type:
			issues.append("event_bad_relationship_type:%s" % relationship_type)
		if str(event.get("relationship_visibility", "")) != str(edge.get("visibility", "")):
			issues.append("event_bad_visibility:%s" % relationship_type)
		if absf(float(event.get("sentiment_shift", 0.0))) > 0.024:
			issues.append("event_shift_unbounded:%s:%s" % [relationship_type, String.num(float(event.get("sentiment_shift", 0.0)), 5)])
		var relationship_event_id: String = str(event.get("relationship_event_id", ""))
		if relationship_event_id.is_empty():
			issues.append("event_missing_relationship_id:%s" % relationship_type)
		elif not relationship_event_ids.has(relationship_event_id):
			relationship_event_ids.append(relationship_event_id)
		var company_id: String = str(event.get("target_company_id", ""))
		if company_id.is_empty():
			issues.append("event_missing_company:%s" % relationship_type)
		elif not impacted_companies.has(company_id):
			impacted_companies.append(company_id)
		var role: String = str(event.get("relationship_impact_role", ""))
		if not roles.has(role):
			roles.append(role)
	if relationship_event_ids.size() != 1:
		issues.append("event_relationship_id_count:%s:%d" % [relationship_type, relationship_event_ids.size()])
	if impacted_companies.size() != 2:
		issues.append("event_impacted_company_count:%s:%d" % [relationship_type, impacted_companies.size()])
	_validate_event_roles(relationship_type, roles, issues)


func _validate_event_roles(relationship_type: String, roles: Array, issues: Array[String]) -> void:
	var expected_roles: Array = []
	match relationship_type:
		"partner":
			expected_roles = ["partner"]
		"supplier":
			expected_roles = ["customer", "supplier"]
		"customer":
			expected_roles = ["customer", "supplier"]
		"competitor":
			expected_roles = ["competitor_loser", "competitor_winner"]
	for expected_role_value in expected_roles:
		if not roles.has(str(expected_role_value)):
			issues.append("missing_event_role:%s:%s roles=%s" % [relationship_type, str(expected_role_value), JSON.stringify(roles)])


func _resolve_forced_events(edge: Dictionary, extra_options: Dictionary) -> Array:
	var graph_system = COMPANY_RELATIONSHIP_GRAPH_SYSTEM.new()
	var day_number: int = 8
	var trade_date: Dictionary = RunState.trading_calendar.trade_date_for_index(day_number)
	var macro_state: Dictionary = RunState.get_macro_state_for_year(int(trade_date.get("year", 2020)))
	var options: Dictionary = {
		"force_event": true,
		"force_edge_id": str(edge.get("edge_id", "")),
		"blocked_company_ids": []
	}
	for key in extra_options.keys():
		options[key] = extra_options.get(key)
	var result: Dictionary = graph_system.resolve_day(RunState, trade_date, day_number, macro_state, options)
	return result.get("relationship_graph_events", []) if typeof(result.get("relationship_graph_events", [])) == TYPE_ARRAY else []


func _first_edge_for_type(relationship_type: String, allowed_visibilities: Array) -> Dictionary:
	var state: Dictionary = RunState.get_company_relationship_graph_state()
	var edge_ids: Array = _string_array(state.get("edge_ids", []))
	var edge_index: Dictionary = state.get("edge_index", {}) if typeof(state.get("edge_index", {})) == TYPE_DICTIONARY else {}
	for edge_id_value in edge_ids:
		var edge: Dictionary = edge_index.get(str(edge_id_value), {})
		if edge.is_empty():
			continue
		if str(edge.get("relationship_type", "")) != relationship_type:
			continue
		if not allowed_visibilities.has(str(edge.get("visibility", ""))):
			continue
		return edge.duplicate(true)
	return {}


func _first_edge_for_visibility(visibility: String) -> Dictionary:
	var state: Dictionary = RunState.get_company_relationship_graph_state()
	var edge_ids: Array = _string_array(state.get("edge_ids", []))
	var edge_index: Dictionary = state.get("edge_index", {}) if typeof(state.get("edge_index", {})) == TYPE_DICTIONARY else {}
	for edge_id_value in edge_ids:
		var edge: Dictionary = edge_index.get(str(edge_id_value), {})
		if edge.is_empty():
			continue
		if str(edge.get("visibility", "")) != visibility:
			continue
		if not (str(edge.get("relationship_type", "")) in COMPANY_RELATIONSHIP_GRAPH_SYSTEM.EVENT_ELIGIBLE_TYPES):
			continue
		return edge.duplicate(true)
	return {}


func _edge_ids_from_rows(rows: Array) -> Array:
	var ids: Array = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		ids.append(str(row.get("edge_id", "")))
	return _string_array(ids)


func _bounded(value: Variant) -> bool:
	var number: float = float(value)
	return number >= 0.0 and number <= 1.0


func _lookup(values: Array) -> Dictionary:
	var result: Dictionary = {}
	for value in values:
		var item: String = str(value).strip_edges()
		if item.is_empty():
			continue
		result[item] = true
	return result


func _increment(counts: Dictionary, key: String) -> void:
	if key.is_empty():
		return
	counts[key] = int(counts.get(key, 0)) + 1


func _string_array(source_value: Variant) -> Array:
	var source_array: Array = source_value if typeof(source_value) == TYPE_ARRAY else [source_value]
	var result: Array = []
	var seen: Dictionary = {}
	for item_value in source_array:
		var item: String = str(item_value).strip_edges()
		if item.is_empty() or seen.has(item):
			continue
		seen[item] = true
		result.append(item)
	result.sort()
	return result


func _array_key(values: Array) -> String:
	return "|".join(_string_array(values))


func _sorted_int_dictionary(source_value: Variant) -> Dictionary:
	var source: Dictionary = source_value if typeof(source_value) == TYPE_DICTIONARY else {}
	var result: Dictionary = {}
	var keys: Array = source.keys()
	keys.sort()
	for key_value in keys:
		result[str(key_value)] = int(source.get(key_value, 0))
	return result


func _fail(message: String) -> void:
	push_error(message)
	print("COMPANY_RELATIONSHIP_GRAPH_REGRESSION_FAIL %s" % message)
	get_tree().quit(1)
