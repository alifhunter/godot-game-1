extends RefCounted

const STABLE_RNG := preload("res://systems/StableRng.gd")

const SCHEMA_VERSION := 1
const SOURCE_SYSTEM_ID := "company_relationship_graph"
const VALID_RELATIONSHIP_TYPES := [
	"supplier",
	"customer",
	"competitor",
	"partner",
	"parent",
	"subsidiary",
	"acquirer_candidate",
	"target_candidate"
]
const TASK2_GENERATED_TYPES := ["supplier", "customer", "competitor", "partner"]
const VALID_VISIBILITIES := ["public", "semi_public", "private", "internal"]
const VALID_LIFECYCLE_STATUSES := ["active", "dormant", "rumored", "proposed", "resolved", "expired"]
const COUNTERPART_BY_TYPE := {
	"supplier": "customer",
	"customer": "supplier",
	"competitor": "competitor",
	"partner": "partner",
	"parent": "subsidiary",
	"subsidiary": "parent",
	"acquirer_candidate": "target_candidate",
	"target_candidate": "acquirer_candidate"
}
const SCOPE_BY_TYPE := {
	"supplier": "supply_chain",
	"customer": "demand_channel",
	"competitor": "competition",
	"partner": "commercial_partner",
	"parent": "control",
	"subsidiary": "control",
	"acquirer_candidate": "mna_candidate",
	"target_candidate": "mna_candidate"
}
const DEFAULT_OPTIONS := {
	"generated_day_index": 0,
	"max_outgoing_edges_per_company": 3,
	"max_incoming_edges_per_company": 4,
	"max_incident_edges_per_company": 5,
	"max_competitor_edges_per_company": 1,
	"max_catalog_edges": 44,
	"max_generated_competitor_edges": 16
}
const EVENT_MIN_DAY_INDEX := 6
const EVENT_BASE_CADENCE_DAYS := 13
const EVENT_RANDOM_THRESHOLD := 0.045
const EVENT_EDGE_COOLDOWN_DAYS := 24
const EVENT_ACTIVE_DURATION_DAYS := 1
const EVENT_ELIGIBLE_TYPES := ["supplier", "customer", "competitor", "partner"]
const EVENT_ELIGIBLE_VISIBILITIES := ["public", "semi_public"]
const EVENT_KIND_BY_TYPE := {
	"supplier": "supply_deal",
	"customer": "customer_win",
	"competitor": "competitor_pressure",
	"partner": "partnership_announcement"
}


func generate_graph_state(run_seed: int, company_definitions: Array, options: Dictionary = {}) -> Dictionary:
	var normalized_options: Dictionary = DEFAULT_OPTIONS.duplicate(true)
	for key in options.keys():
		normalized_options[key] = options.get(key)
	var definitions: Array = _normalized_definitions(company_definitions)
	if definitions.is_empty():
		return default_graph_state(run_seed, int(normalized_options.get("generated_day_index", 0)))

	var candidates: Array = []
	candidates.append_array(_catalog_hook_candidates(run_seed, definitions))
	candidates.append_array(_generated_competitor_candidates(run_seed, definitions))
	var selected_edges: Array = _select_edges(run_seed, candidates, definitions, normalized_options)
	return _build_graph_state(
		run_seed,
		selected_edges,
		int(normalized_options.get("generated_day_index", 0)),
		definitions
	)


static func default_graph_state(run_seed: int = 0, generated_day_index: int = -1) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"generated": false,
		"run_seed": run_seed,
		"generated_day_index": generated_day_index,
		"edge_ids": [],
		"edge_index": {},
		"company_edge_ids": {},
		"counts_by_type": {},
		"counts_by_visibility": {},
		"counts_by_origin": {},
		"unresolved_hook_count": 0,
		"validation_issues": []
	}


func resolve_day(
	run_state,
	trade_date: Dictionary,
	day_number: int,
	macro_state: Dictionary,
	options: Dictionary = {}
) -> Dictionary:
	var state: Dictionary = normalize_graph_state(
		run_state.get_company_relationship_graph_state(),
		run_state.company_order,
		int(run_state.run_seed),
		day_number
	)
	var result: Dictionary = {
		"company_relationship_graph_state": state.duplicate(true),
		"relationship_graph_events": [],
		"active_company_arcs": []
	}
	if not bool(state.get("generated", false)):
		return result
	if not _should_emit_relationship_event(run_state, day_number, options):
		return result

	var candidates: Array = _relationship_event_candidates(run_state, state, day_number, macro_state, options)
	if candidates.is_empty():
		return result
	var picked_candidate: Dictionary = _pick_relationship_event_candidate(candidates, int(run_state.run_seed), day_number)
	if picked_candidate.is_empty():
		return result

	var event_rows: Array = _build_relationship_event_rows(run_state, picked_candidate, trade_date, day_number)
	if event_rows.is_empty():
		return result
	var edge_id: String = str(picked_candidate.get("edge_id", ""))
	var cooldown_days: int = max(int(options.get("edge_cooldown_days", EVENT_EDGE_COOLDOWN_DAYS)), 1)
	state = _apply_edge_event_cooldown(state, edge_id, day_number + cooldown_days)
	result["company_relationship_graph_state"] = state.duplicate(true)
	result["relationship_graph_events"] = event_rows.duplicate(true)
	result["active_company_arcs"] = event_rows.duplicate(true)
	return result


static func normalize_graph_state(
	source_state: Variant,
	valid_company_ids: Array = [],
	fallback_run_seed: int = 0,
	fallback_generated_day_index: int = -1
) -> Dictionary:
	var normalized: Dictionary = default_graph_state(fallback_run_seed, fallback_generated_day_index)
	if typeof(source_state) != TYPE_DICTIONARY:
		return normalized
	var source: Dictionary = source_state
	normalized["schema_version"] = SCHEMA_VERSION
	normalized["generated"] = bool(source.get("generated", false))
	normalized["run_seed"] = int(source.get("run_seed", fallback_run_seed))
	normalized["generated_day_index"] = int(source.get("generated_day_index", fallback_generated_day_index))
	normalized["unresolved_hook_count"] = max(int(source.get("unresolved_hook_count", 0)), 0)

	var valid_lookup: Dictionary = _string_lookup(valid_company_ids)
	var edge_index: Dictionary = {}
	var edge_ids: Array = []
	var seen_canonical: Dictionary = {}
	var issues: Array = []
	var source_edge_index: Dictionary = source.get("edge_index", {}) if typeof(source.get("edge_index", {})) == TYPE_DICTIONARY else {}
	var ordered_ids: Array = _string_array(source.get("edge_ids", []))
	if ordered_ids.is_empty():
		ordered_ids = _string_array(source_edge_index.keys())
	for edge_id_value in ordered_ids:
		var source_edge_id: String = str(edge_id_value).strip_edges()
		var edge_value: Variant = source_edge_index.get(source_edge_id, {})
		if typeof(edge_value) != TYPE_DICTIONARY:
			issues.append("edge_not_dictionary:%s" % source_edge_id)
			continue
		var edge: Dictionary = normalize_edge(edge_value)
		if edge.is_empty():
			issues.append("edge_invalid:%s" % source_edge_id)
			continue
		var source_company_id: String = str(edge.get("source_company_id", ""))
		var target_company_id: String = str(edge.get("target_company_id", ""))
		if not valid_lookup.is_empty() and (not valid_lookup.has(source_company_id) or not valid_lookup.has(target_company_id)):
			issues.append("edge_endpoint_missing:%s" % source_edge_id)
			continue
		var canonical_key: String = canonical_edge_key(edge)
		if seen_canonical.has(canonical_key):
			issues.append("duplicate_canonical_edge:%s" % canonical_key)
			continue
		seen_canonical[canonical_key] = true
		var edge_id: String = str(edge.get("edge_id", "")).strip_edges()
		edge_ids.append(edge_id)
		edge_index[edge_id] = edge
	normalized["edge_ids"] = edge_ids
	normalized["edge_index"] = edge_index
	normalized["company_edge_ids"] = company_edge_lookup(edge_ids, edge_index)
	normalized["counts_by_type"] = count_edges_by_field(edge_ids, edge_index, "relationship_type")
	normalized["counts_by_visibility"] = count_edges_by_field(edge_ids, edge_index, "visibility")
	normalized["counts_by_origin"] = count_edges_by_field(edge_ids, edge_index, "origin")
	normalized["validation_issues"] = _string_array(source.get("validation_issues", [])) + issues
	return normalized


static func normalize_edge(source_edge: Variant) -> Dictionary:
	if typeof(source_edge) != TYPE_DICTIONARY:
		return {}
	var source: Dictionary = source_edge
	var source_company_id: String = str(source.get("source_company_id", "")).strip_edges()
	var target_company_id: String = str(source.get("target_company_id", "")).strip_edges()
	var relationship_type: String = normalize_relationship_type(str(source.get("relationship_type", "")))
	if source_company_id.is_empty() or target_company_id.is_empty() or source_company_id == target_company_id or relationship_type.is_empty():
		return {}
	var edge_id: String = str(source.get("edge_id", "")).strip_edges()
	if edge_id.is_empty():
		edge_id = "edge|%s|%s|%s" % [source_company_id, target_company_id, relationship_type]
	var visibility: String = normalize_visibility(str(source.get("visibility", "semi_public")))
	var lifecycle_status: String = normalize_lifecycle_status(str(source.get("lifecycle_status", "active")))
	return {
		"edge_id": edge_id,
		"source_company_id": source_company_id,
		"target_company_id": target_company_id,
		"source_ticker": str(source.get("source_ticker", "")).strip_edges().to_upper(),
		"target_ticker": str(source.get("target_ticker", "")).strip_edges().to_upper(),
		"relationship_type": relationship_type,
		"counterpart_type": str(COUNTERPART_BY_TYPE.get(relationship_type, relationship_type)),
		"origin": str(source.get("origin", "generated_runtime")).strip_edges(),
		"source_hook_index": int(source.get("source_hook_index", -1)),
		"strength": snappedf(clamp(float(source.get("strength", 0.0)), 0.0, 1.0), 0.001),
		"confidence": snappedf(clamp(float(source.get("confidence", 0.0)), 0.0, 1.0), 0.001),
		"visibility": visibility,
		"relationship_scope": str(SCOPE_BY_TYPE.get(relationship_type, "commercial_partner")),
		"sector_fit_score": snappedf(clamp(float(source.get("sector_fit_score", 0.0)), 0.0, 1.0), 0.001),
		"lifecycle_status": lifecycle_status,
		"start_day_index": int(source.get("start_day_index", 0)),
		"end_day_index": int(source.get("end_day_index", -1)),
		"event_cooldown_until_day": int(source.get("event_cooldown_until_day", -1)),
		"source_fact_ids": _string_array(source.get("source_fact_ids", [])),
		"source_clue_ids": _string_array(source.get("source_clue_ids", []))
	}


static func normalize_relationship_type(value: String) -> String:
	var relationship_type: String = value.strip_edges().to_lower()
	if relationship_type in VALID_RELATIONSHIP_TYPES:
		return relationship_type
	return ""


static func normalize_visibility(value: String) -> String:
	var visibility: String = value.strip_edges().to_lower()
	if visibility in VALID_VISIBILITIES:
		return visibility
	return "semi_public"


static func normalize_lifecycle_status(value: String) -> String:
	var lifecycle_status: String = value.strip_edges().to_lower()
	if lifecycle_status in VALID_LIFECYCLE_STATUSES:
		return lifecycle_status
	return "active"


static func canonical_edge_key(edge: Dictionary) -> String:
	var source_company_id: String = str(edge.get("source_company_id", ""))
	var target_company_id: String = str(edge.get("target_company_id", ""))
	var relationship_type: String = str(edge.get("relationship_type", ""))
	var pair: Array = [source_company_id, target_company_id]
	pair.sort()
	if relationship_type in ["supplier", "customer"]:
		return "%s|%s|trade" % [str(pair[0]), str(pair[1])]
	if relationship_type in ["competitor", "partner"]:
		return "%s|%s|%s" % [str(pair[0]), str(pair[1]), relationship_type]
	return "%s|%s|%s" % [source_company_id, target_company_id, relationship_type]


static func company_edge_lookup(edge_ids: Array, edge_index: Dictionary) -> Dictionary:
	var lookup: Dictionary = {}
	for edge_id_value in edge_ids:
		var edge_id: String = str(edge_id_value)
		var edge: Dictionary = edge_index.get(edge_id, {})
		if edge.is_empty():
			continue
		var source_company_id: String = str(edge.get("source_company_id", ""))
		var target_company_id: String = str(edge.get("target_company_id", ""))
		if not lookup.has(source_company_id):
			lookup[source_company_id] = {"outgoing": [], "incoming": [], "all": []}
		if not lookup.has(target_company_id):
			lookup[target_company_id] = {"outgoing": [], "incoming": [], "all": []}
		lookup[source_company_id]["outgoing"].append(edge_id)
		lookup[source_company_id]["all"].append(edge_id)
		lookup[target_company_id]["incoming"].append(edge_id)
		lookup[target_company_id]["all"].append(edge_id)
	for company_id in lookup.keys():
		lookup[company_id]["outgoing"] = _string_array(lookup[company_id].get("outgoing", []))
		lookup[company_id]["incoming"] = _string_array(lookup[company_id].get("incoming", []))
		lookup[company_id]["all"] = _string_array(lookup[company_id].get("all", []))
	return lookup


static func count_edges_by_field(edge_ids: Array, edge_index: Dictionary, field: String) -> Dictionary:
	var counts: Dictionary = {}
	for edge_id_value in edge_ids:
		var edge: Dictionary = edge_index.get(str(edge_id_value), {})
		if edge.is_empty():
			continue
		var value: String = str(edge.get(field, "")).strip_edges()
		if value.is_empty():
			continue
		counts[value] = int(counts.get(value, 0)) + 1
	return counts


func _should_emit_relationship_event(run_state, day_number: int, options: Dictionary) -> bool:
	if bool(options.get("force_event", false)):
		return true
	if day_number < int(options.get("min_day_index", EVENT_MIN_DAY_INDEX)):
		return false
	if _active_relationship_arc_count(run_state.get_active_company_arcs()) > 0:
		return false
	var cadence_days: int = max(int(options.get("cadence_days", EVENT_BASE_CADENCE_DAYS)), 1)
	var cadence_offset: int = int(STABLE_RNG.seed_from_parts([run_state.run_seed, SOURCE_SYSTEM_ID, "event_offset"]) % cadence_days)
	if int(posmod(day_number + cadence_offset, cadence_days)) == 0:
		return true
	var threshold: float = clamp(float(options.get("random_threshold", EVENT_RANDOM_THRESHOLD)), 0.0, 1.0)
	if threshold <= 0.0:
		return false
	var roll: float = STABLE_RNG.unit_float([run_state.run_seed, SOURCE_SYSTEM_ID, "event_roll", day_number])
	return roll < threshold


func _active_relationship_arc_count(active_arcs: Array) -> int:
	var count: int = 0
	for arc_value in active_arcs:
		if typeof(arc_value) != TYPE_DICTIONARY:
			continue
		var arc: Dictionary = arc_value
		if str(arc.get("source_system", arc.get("event_family", ""))) == SOURCE_SYSTEM_ID:
			count += 1
	return count


func _relationship_event_candidates(
	run_state,
	state: Dictionary,
	day_number: int,
	macro_state: Dictionary,
	options: Dictionary
) -> Array:
	var edge_ids: Array = _string_array(state.get("edge_ids", []))
	var edge_index: Dictionary = state.get("edge_index", {}) if typeof(state.get("edge_index", {})) == TYPE_DICTIONARY else {}
	var candidates: Array = []
	var force_edge_id: String = str(options.get("force_edge_id", "")).strip_edges()
	var force_relationship_type: String = str(options.get("force_relationship_type", "")).strip_edges()
	for edge_id_value in edge_ids:
		var edge_id: String = str(edge_id_value)
		var edge: Dictionary = edge_index.get(edge_id, {})
		if edge.is_empty():
			continue
		var relationship_type: String = str(edge.get("relationship_type", ""))
		if not force_edge_id.is_empty() and edge_id != force_edge_id:
			continue
		if not force_relationship_type.is_empty() and relationship_type != force_relationship_type:
			continue
		if not (relationship_type in EVENT_ELIGIBLE_TYPES):
			continue
		if int(edge.get("event_cooldown_until_day", -1)) > day_number:
			continue
		if str(edge.get("lifecycle_status", "active")) != "active":
			continue
		if not bool(options.get("include_private_edges", false)) and not (str(edge.get("visibility", "")) in EVENT_ELIGIBLE_VISIBILITIES):
			continue
		if not _edge_companies_available_for_event(run_state, edge, day_number, relationship_type, options):
			continue
		candidates.append(_relationship_event_candidate(run_state, edge, day_number, macro_state))
	return candidates


func _edge_companies_available_for_event(
	run_state,
	edge: Dictionary,
	day_number: int,
	relationship_type: String,
	options: Dictionary
) -> bool:
	var source_company_id: String = str(edge.get("source_company_id", ""))
	var target_company_id: String = str(edge.get("target_company_id", ""))
	var blocked_company_ids: Array = _string_array(options.get("blocked_company_ids", []))
	if source_company_id in blocked_company_ids or target_company_id in blocked_company_ids:
		return false
	if run_state.get_effective_company_definition(source_company_id).is_empty():
		return false
	if run_state.get_effective_company_definition(target_company_id).is_empty():
		return false
	if run_state.get_company(source_company_id).is_empty() or run_state.get_company(target_company_id).is_empty():
		return false
	var event_kind: String = str(EVENT_KIND_BY_TYPE.get(relationship_type, relationship_type))
	if run_state.has_method("is_company_living_arc_available"):
		if not run_state.is_company_living_arc_available(source_company_id, SOURCE_SYSTEM_ID, event_kind, day_number):
			return false
		if not run_state.is_company_living_arc_available(target_company_id, SOURCE_SYSTEM_ID, event_kind, day_number):
			return false
	return true


func _relationship_event_candidate(run_state, edge: Dictionary, day_number: int, macro_state: Dictionary) -> Dictionary:
	var edge_id: String = str(edge.get("edge_id", ""))
	var relationship_type: String = str(edge.get("relationship_type", ""))
	var event_kind: String = str(EVENT_KIND_BY_TYPE.get(relationship_type, relationship_type))
	var visibility_bonus: float = 0.04 if str(edge.get("visibility", "")) == "public" else 0.0
	var risk_appetite: float = float(macro_state.get("risk_appetite", 0.5))
	var type_bonus: float = 0.0
	match relationship_type:
		"partner":
			type_bonus = 0.07
		"supplier", "customer":
			type_bonus = 0.05
		"competitor":
			type_bonus = 0.02
	var noise: float = STABLE_RNG.unit_float([run_state.run_seed, SOURCE_SYSTEM_ID, "event_candidate", day_number, edge_id])
	var weight: float = (
		float(edge.get("strength", 0.0)) * 0.42 +
		float(edge.get("confidence", 0.0)) * 0.24 +
		float(edge.get("sector_fit_score", 0.0)) * 0.12 +
		max(risk_appetite - 0.42, 0.0) * 0.10 +
		visibility_bonus +
		type_bonus +
		noise * 0.12
	)
	return {
		"edge_id": edge_id,
		"edge": edge.duplicate(true),
		"relationship_type": relationship_type,
		"event_kind": event_kind,
		"weight": snappedf(weight, 0.0001),
		"noise": snappedf(noise, 0.0001)
	}


func _pick_relationship_event_candidate(candidates: Array, run_seed: int, day_number: int) -> Dictionary:
	var ordered: Array = candidates.duplicate(true)
	ordered.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if is_equal_approx(float(left.get("weight", 0.0)), float(right.get("weight", 0.0))):
			return str(left.get("edge_id", "")) < str(right.get("edge_id", ""))
		return float(left.get("weight", 0.0)) > float(right.get("weight", 0.0))
	)
	if ordered.is_empty():
		return {}
	var top_count: int = min(ordered.size(), 4)
	var picked_index: int = int(STABLE_RNG.seed_from_parts([run_seed, SOURCE_SYSTEM_ID, "event_pick", day_number]) % top_count)
	return ordered[picked_index].duplicate(true)


func _build_relationship_event_rows(run_state, candidate: Dictionary, trade_date: Dictionary, day_number: int) -> Array:
	var edge: Dictionary = candidate.get("edge", {}) if typeof(candidate.get("edge", {})) == TYPE_DICTIONARY else {}
	if edge.is_empty():
		return []
	var relationship_type: String = str(edge.get("relationship_type", ""))
	var source_company_id: String = str(edge.get("source_company_id", ""))
	var target_company_id: String = str(edge.get("target_company_id", ""))
	var source_definition: Dictionary = run_state.get_effective_company_definition(source_company_id)
	var target_definition: Dictionary = run_state.get_effective_company_definition(target_company_id)
	if source_definition.is_empty() or target_definition.is_empty():
		return []
	var materiality: float = clamp(float(edge.get("strength", 0.0)) * 0.72 + float(edge.get("confidence", 0.0)) * 0.28, 0.20, 1.0)
	var relationship_event_id: String = "relationship|%d|%s|%s" % [day_number, str(edge.get("edge_id", "")), str(candidate.get("event_kind", ""))]
	match relationship_type:
		"partner":
			var partner_shift: float = snappedf(clamp(0.004 + materiality * 0.012, 0.004, 0.018), 0.0001)
			return [
				_relationship_event_row(run_state, candidate, edge, source_definition, target_definition, relationship_event_id, "partner", partner_shift, "positive", trade_date, day_number),
				_relationship_event_row(run_state, candidate, edge, target_definition, source_definition, relationship_event_id, "partner", partner_shift * 0.92, "positive", trade_date, day_number)
			]
		"supplier":
			var supplier_shift: float = snappedf(clamp(0.006 + materiality * 0.014, 0.006, 0.022), 0.0001)
			var buyer_shift: float = snappedf(clamp(0.002 - materiality * 0.007, -0.006, 0.003), 0.0001)
			return [
				_relationship_event_row(run_state, candidate, edge, source_definition, target_definition, relationship_event_id, "supplier", supplier_shift, "positive", trade_date, day_number),
				_relationship_event_row(run_state, candidate, edge, target_definition, source_definition, relationship_event_id, "customer", buyer_shift, "mixed", trade_date, day_number)
			]
		"customer":
			var vendor_shift: float = snappedf(clamp(0.006 + materiality * 0.013, 0.006, 0.021), 0.0001)
			var customer_shift: float = snappedf(clamp(0.001 - materiality * 0.005, -0.005, 0.002), 0.0001)
			return [
				_relationship_event_row(run_state, candidate, edge, target_definition, source_definition, relationship_event_id, "supplier", vendor_shift, "positive", trade_date, day_number),
				_relationship_event_row(run_state, candidate, edge, source_definition, target_definition, relationship_event_id, "customer", customer_shift, "mixed", trade_date, day_number)
			]
		"competitor":
			var source_wins: bool = STABLE_RNG.unit_float([run_state.run_seed, SOURCE_SYSTEM_ID, "competitor_winner", day_number, str(edge.get("edge_id", ""))]) >= 0.5
			var winner_definition: Dictionary = source_definition if source_wins else target_definition
			var loser_definition: Dictionary = target_definition if source_wins else source_definition
			var winner_shift: float = snappedf(clamp(0.006 + materiality * 0.010, 0.006, 0.018), 0.0001)
			var loser_shift: float = snappedf(clamp(-0.006 - materiality * 0.010, -0.018, -0.006), 0.0001)
			return [
				_relationship_event_row(run_state, candidate, edge, winner_definition, loser_definition, relationship_event_id, "competitor_winner", winner_shift, "positive", trade_date, day_number),
				_relationship_event_row(run_state, candidate, edge, loser_definition, winner_definition, relationship_event_id, "competitor_loser", loser_shift, "negative", trade_date, day_number)
			]
	return []


func _relationship_event_row(
	run_state,
	candidate: Dictionary,
	edge: Dictionary,
	target_definition: Dictionary,
	counterparty_definition: Dictionary,
	relationship_event_id: String,
	impact_role: String,
	sentiment_shift: float,
	tone: String,
	trade_date: Dictionary,
	day_number: int
) -> Dictionary:
	var target_company_id: String = str(target_definition.get("id", ""))
	var counterparty_company_id: String = str(counterparty_definition.get("id", ""))
	var event_kind: String = str(candidate.get("event_kind", "relationship_event"))
	var event_id: String = "relationship_%s" % event_kind
	var description: String = _relationship_event_description(event_kind, impact_role, target_definition, counterparty_definition)
	var volatility_multiplier: float = clamp(1.0 + absf(sentiment_shift) * 6.0, 1.02, 1.16)
	var passive_pressure: float = clamp(sentiment_shift * 10.0, -0.22, 0.28)
	var volume_multiplier: float = clamp(1.0 + absf(sentiment_shift) * 8.0, 1.0, 1.18)
	return {
		"arc_id": "relationship_graph|%d|%s|%s" % [day_number, target_company_id, impact_role],
		"scope": "company",
		"source_system": SOURCE_SYSTEM_ID,
		"event_id": event_id,
		"event_family": SOURCE_SYSTEM_ID,
		"category": event_kind,
		"tone": tone,
		"target_company_id": target_company_id,
		"target_sector_id": str(target_definition.get("sector_id", "")),
		"target_ticker": str(target_definition.get("ticker", target_company_id.to_upper())).to_upper(),
		"target_company_name": str(target_definition.get("name", target_company_id.to_upper())),
		"counterparty_company_id": counterparty_company_id,
		"counterparty_ticker": str(counterparty_definition.get("ticker", counterparty_company_id.to_upper())).to_upper(),
		"counterparty_company_name": str(counterparty_definition.get("name", counterparty_company_id.to_upper())),
		"relationship_event_id": relationship_event_id,
		"relationship_event_kind": event_kind,
		"relationship_impact_role": impact_role,
		"relationship_type": str(edge.get("relationship_type", "")),
		"relationship_edge_id": str(edge.get("edge_id", "")),
		"relationship_visibility": str(edge.get("visibility", "")),
		"relationship_strength": float(edge.get("strength", 0.0)),
		"relationship_confidence": float(edge.get("confidence", 0.0)),
		"relationship_weight": float(candidate.get("weight", 0.0)),
		"trade_date": trade_date.duplicate(true),
		"description": description,
		"headline": description,
		"sentiment_shift": sentiment_shift,
		"phase_schedule": [{
			"id": "impact",
			"label": "relationship repricing",
			"duration_days": EVENT_ACTIVE_DURATION_DAYS,
			"sentiment_shift": sentiment_shift,
			"volatility_multiplier": volatility_multiplier,
			"visibility": "visible",
			"hidden_flag": "relationship_graph_%s" % event_kind
		}],
		"event_scale": clamp(absf(sentiment_shift) / 0.022, 0.18, 1.0),
		"confidence": float(edge.get("confidence", 0.0)),
		"duration_days": EVENT_ACTIVE_DURATION_DAYS,
		"start_day_index": day_number,
		"end_day_index": day_number + EVENT_ACTIVE_DURATION_DAYS - 1,
		"current_phase_id": "impact",
		"current_phase_label": "relationship repricing",
		"phase_day_index": 1,
		"phase_duration_days": EVENT_ACTIVE_DURATION_DAYS,
		"phase_sentiment_shift": sentiment_shift,
		"phase_volatility_multiplier": volatility_multiplier,
		"phase_visibility": "visible",
		"phase_hidden_flag": "relationship_graph_%s" % event_kind,
		"phase_passive_flow_pressure": passive_pressure,
		"phase_volume_activity_multiplier": volume_multiplier,
		"phase_depth_liquidity_multiplier": 1.0,
		"story_tags": [
			SOURCE_SYSTEM_ID,
			event_kind,
			str(edge.get("relationship_type", "")),
			impact_role,
			"counterparty:%s" % counterparty_company_id
		],
		"content_surface_status": "deferred_task4"
	}


func _relationship_event_description(
	event_kind: String,
	impact_role: String,
	target_definition: Dictionary,
	counterparty_definition: Dictionary
) -> String:
	var target_name: String = str(target_definition.get("name", target_definition.get("ticker", "The company")))
	var counterparty_name: String = str(counterparty_definition.get("name", counterparty_definition.get("ticker", "its counterparty")))
	match event_kind:
		"partnership_announcement":
			return "%s and %s confirm a commercial partnership with modest execution upside." % [target_name, counterparty_name]
		"supply_deal":
			if impact_role == "supplier":
				return "%s wins a supply-chain mandate linked to %s." % [target_name, counterparty_name]
			return "%s prices in the operating impact of a new vendor arrangement with %s." % [target_name, counterparty_name]
		"customer_win":
			if impact_role == "supplier":
				return "%s secures a demand channel tied to %s." % [target_name, counterparty_name]
			return "%s absorbs near-term commitment risk from a larger procurement link with %s." % [target_name, counterparty_name]
		"competitor_pressure":
			if impact_role == "competitor_winner":
				return "%s gains relative momentum as %s faces competitive pressure." % [target_name, counterparty_name]
			return "%s trades under peer-pressure as %s shows stronger relative momentum." % [target_name, counterparty_name]
	return "%s reprices a relationship-linked development with %s." % [target_name, counterparty_name]


func _apply_edge_event_cooldown(state: Dictionary, edge_id: String, cooldown_until_day: int) -> Dictionary:
	if edge_id.is_empty():
		return state
	var next_state: Dictionary = state.duplicate(true)
	var edge_index: Dictionary = next_state.get("edge_index", {}).duplicate(true) if typeof(next_state.get("edge_index", {})) == TYPE_DICTIONARY else {}
	var edge: Dictionary = normalize_edge(edge_index.get(edge_id, {}))
	if edge.is_empty():
		return state
	edge["event_cooldown_until_day"] = max(int(edge.get("event_cooldown_until_day", -1)), cooldown_until_day)
	edge_index[edge_id] = edge
	next_state["edge_index"] = edge_index
	return normalize_graph_state(
		next_state,
		next_state.get("company_edge_ids", {}).keys() if typeof(next_state.get("company_edge_ids", {})) == TYPE_DICTIONARY else [],
		int(next_state.get("run_seed", 0)),
		int(next_state.get("generated_day_index", -1))
	)


func _normalized_definitions(company_definitions: Array) -> Array:
	var rows: Array = []
	var seen: Dictionary = {}
	for definition_value in company_definitions:
		if typeof(definition_value) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = definition_value
		var company_id: String = str(definition.get("id", "")).strip_edges()
		if company_id.is_empty() or seen.has(company_id):
			continue
		seen[company_id] = true
		rows.append(definition.duplicate(true))
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return str(left.get("id", "")) < str(right.get("id", ""))
	)
	return rows


func _catalog_hook_candidates(run_seed: int, definitions: Array) -> Array:
	var candidates: Array = []
	for source_index in range(definitions.size()):
		var source_definition: Dictionary = definitions[source_index]
		var hooks: Array = source_definition.get("relationship_hooks", []) if typeof(source_definition.get("relationship_hooks", [])) == TYPE_ARRAY else []
		for hook_index in range(hooks.size()):
			var hook_value: Variant = hooks[hook_index]
			if typeof(hook_value) != TYPE_DICTIONARY:
				continue
			var hook: Dictionary = hook_value
			var relationship_type: String = normalize_relationship_type(str(hook.get("type", "")))
			if not (relationship_type in TASK2_GENERATED_TYPES):
				continue
			var target_candidates: Array = _target_candidates_for_hook(run_seed, definitions, source_definition, hook, hook_index)
			for target_candidate_value in target_candidates:
				var target_candidate: Dictionary = target_candidate_value
				var target_definition: Dictionary = target_candidate.get("target", {}) if typeof(target_candidate.get("target", {})) == TYPE_DICTIONARY else {}
				var sector_fit_score: float = float(target_candidate.get("sector_fit_score", 0.0))
				var strength: float = clamp(float(hook.get("strength", 0.0)), 0.0, 1.0)
				var visibility: String = normalize_visibility(str(hook.get("visibility", "semi_public")))
				var confidence: float = _catalog_confidence(run_seed, source_definition, target_definition, hook_index, strength, sector_fit_score, visibility)
				var score: float = sector_fit_score * 0.58 + strength * 0.28 + confidence * 0.10 + _unit_noise(run_seed, "catalog_candidate", source_definition, target_definition, hook_index) * 0.04
				candidates.append(_candidate_row(
					run_seed,
					source_definition,
					target_definition,
					relationship_type,
					"catalog_hook",
					hook_index,
					strength,
					confidence,
					visibility,
					sector_fit_score,
					score
				))
	return candidates


func _target_candidates_for_hook(
	run_seed: int,
	definitions: Array,
	source_definition: Dictionary,
	hook: Dictionary,
	hook_index: int
) -> Array:
	var target_sector: String = str(hook.get("target_sector", "")).strip_edges()
	var target_subsector: String = str(hook.get("target_subsector", "")).strip_edges()
	var exact_rows: Array = []
	var sector_rows: Array = []
	for target_value in definitions:
		var target_definition: Dictionary = target_value
		if str(target_definition.get("id", "")) == str(source_definition.get("id", "")):
			continue
		if str(target_definition.get("sector_id", target_definition.get("sector", ""))) != target_sector:
			continue
		var target_company_subsector: String = str(target_definition.get("subsector", "")).strip_edges()
		if not target_subsector.is_empty() and target_company_subsector == target_subsector:
			exact_rows.append({"target": target_definition, "sector_fit_score": 1.0})
		else:
			sector_rows.append({"target": target_definition, "sector_fit_score": 0.72})
	var rows: Array = exact_rows if not exact_rows.is_empty() else sector_rows
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_target: Dictionary = left.get("target", {})
		var right_target: Dictionary = right.get("target", {})
		var left_score: float = _target_tie_score(run_seed, source_definition, left_target, hook_index)
		var right_score: float = _target_tie_score(run_seed, source_definition, right_target, hook_index)
		if is_equal_approx(left_score, right_score):
			return str(left_target.get("id", "")) < str(right_target.get("id", ""))
		return left_score > right_score
	)
	return rows


func _generated_competitor_candidates(run_seed: int, definitions: Array) -> Array:
	var candidates: Array = []
	for left_index in range(definitions.size()):
		var left_definition: Dictionary = definitions[left_index]
		for right_index in range(left_index + 1, definitions.size()):
			var right_definition: Dictionary = definitions[right_index]
			if str(left_definition.get("sector_id", "")) != str(right_definition.get("sector_id", "")):
				continue
			var same_subsector: bool = str(left_definition.get("subsector", "")) == str(right_definition.get("subsector", "")) and not str(left_definition.get("subsector", "")).is_empty()
			var sector_fit_score: float = 0.95 if same_subsector else 0.70
			var noise: float = _unit_noise(run_seed, "competitor_candidate", left_definition, right_definition, 0)
			var strength: float = clamp(0.26 + sector_fit_score * 0.28 + noise * 0.10, 0.0, 1.0)
			var confidence: float = clamp(0.52 + sector_fit_score * 0.26 + noise * 0.08, 0.0, 1.0)
			var visibility: String = "public" if same_subsector else "semi_public"
			var score: float = sector_fit_score * 0.56 + strength * 0.30 + confidence * 0.08 + noise * 0.06
			candidates.append(_candidate_row(
				run_seed,
				left_definition,
				right_definition,
				"competitor",
				"generated_runtime",
				-1,
				strength,
				confidence,
				visibility,
				sector_fit_score,
				score
			))
	return candidates


func _candidate_row(
	run_seed: int,
	source_definition: Dictionary,
	target_definition: Dictionary,
	relationship_type: String,
	origin: String,
	hook_index: int,
	strength: float,
	confidence: float,
	visibility: String,
	sector_fit_score: float,
	score: float
) -> Dictionary:
	return {
		"source_company_id": str(source_definition.get("id", "")),
		"target_company_id": str(target_definition.get("id", "")),
		"source_ticker": str(source_definition.get("ticker", "")).to_upper(),
		"target_ticker": str(target_definition.get("ticker", "")).to_upper(),
		"relationship_type": relationship_type,
		"counterpart_type": str(COUNTERPART_BY_TYPE.get(relationship_type, relationship_type)),
		"origin": origin,
		"source_hook_index": hook_index,
		"strength": snappedf(clamp(strength, 0.0, 1.0), 0.001),
		"confidence": snappedf(clamp(confidence, 0.0, 1.0), 0.001),
		"visibility": visibility,
		"relationship_scope": str(SCOPE_BY_TYPE.get(relationship_type, "commercial_partner")),
		"sector_fit_score": snappedf(clamp(sector_fit_score, 0.0, 1.0), 0.001),
		"lifecycle_status": "active",
		"start_day_index": 0,
		"end_day_index": -1,
		"event_cooldown_until_day": -1,
		"source_fact_ids": [],
		"source_clue_ids": [],
		"selection_score": snappedf(score, 0.0001),
		"hook_key": "%s|%d" % [str(source_definition.get("id", "")), hook_index]
	}


func _select_edges(run_seed: int, candidates: Array, definitions: Array, options: Dictionary) -> Array:
	var selected: Array = []
	var seen_canonical: Dictionary = {}
	var seen_hook_keys: Dictionary = {}
	var outgoing_counts: Dictionary = {}
	var incoming_counts: Dictionary = {}
	var incident_counts: Dictionary = {}
	var competitor_counts: Dictionary = {}
	var catalog_edge_count: int = 0
	var competitor_edge_count: int = 0
	var max_outgoing: int = int(options.get("max_outgoing_edges_per_company", 3))
	var max_incoming: int = int(options.get("max_incoming_edges_per_company", 4))
	var max_incident: int = int(options.get("max_incident_edges_per_company", 5))
	var max_competitor_per_company: int = int(options.get("max_competitor_edges_per_company", 1))
	var max_catalog_edges: int = int(options.get("max_catalog_edges", 44))
	var max_competitor_edges: int = int(options.get("max_generated_competitor_edges", 16))
	candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if is_equal_approx(float(left.get("selection_score", 0.0)), float(right.get("selection_score", 0.0))):
			return _candidate_sort_key(left) < _candidate_sort_key(right)
		return float(left.get("selection_score", 0.0)) > float(right.get("selection_score", 0.0))
	)

	for candidate_value in candidates:
		var candidate: Dictionary = candidate_value
		var source_company_id: String = str(candidate.get("source_company_id", ""))
		var target_company_id: String = str(candidate.get("target_company_id", ""))
		var relationship_type: String = str(candidate.get("relationship_type", ""))
		if source_company_id.is_empty() or target_company_id.is_empty() or source_company_id == target_company_id:
			continue
		var canonical_key: String = canonical_edge_key(candidate)
		if seen_canonical.has(canonical_key):
			continue
		if str(candidate.get("origin", "")) == "catalog_hook":
			if catalog_edge_count >= max_catalog_edges:
				continue
			var hook_key: String = str(candidate.get("hook_key", ""))
			if seen_hook_keys.has(hook_key):
				continue
		if str(candidate.get("origin", "")) == "generated_runtime" and relationship_type == "competitor":
			if competitor_edge_count >= max_competitor_edges:
				continue
			if int(competitor_counts.get(source_company_id, 0)) >= max_competitor_per_company:
				continue
			if int(competitor_counts.get(target_company_id, 0)) >= max_competitor_per_company:
				continue
		if int(outgoing_counts.get(source_company_id, 0)) >= max_outgoing:
			continue
		if int(incoming_counts.get(target_company_id, 0)) >= max_incoming:
			continue
		if int(incident_counts.get(source_company_id, 0)) >= max_incident:
			continue
		if int(incident_counts.get(target_company_id, 0)) >= max_incident:
			continue
		seen_canonical[canonical_key] = true
		if str(candidate.get("origin", "")) == "catalog_hook":
			seen_hook_keys[str(candidate.get("hook_key", ""))] = true
			catalog_edge_count += 1
		if str(candidate.get("origin", "")) == "generated_runtime" and relationship_type == "competitor":
			competitor_edge_count += 1
			competitor_counts[source_company_id] = int(competitor_counts.get(source_company_id, 0)) + 1
			competitor_counts[target_company_id] = int(competitor_counts.get(target_company_id, 0)) + 1
		outgoing_counts[source_company_id] = int(outgoing_counts.get(source_company_id, 0)) + 1
		incoming_counts[target_company_id] = int(incoming_counts.get(target_company_id, 0)) + 1
		incident_counts[source_company_id] = int(incident_counts.get(source_company_id, 0)) + 1
		incident_counts[target_company_id] = int(incident_counts.get(target_company_id, 0)) + 1
		selected.append(candidate)

	selected.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return _candidate_sort_key(left) < _candidate_sort_key(right)
	)
	for index in range(selected.size()):
		var edge: Dictionary = selected[index]
		edge["edge_id"] = "edge|%d|%s|%s|%s|%02d" % [
			run_seed,
			str(edge.get("source_company_id", "")),
			str(edge.get("target_company_id", "")),
			str(edge.get("relationship_type", "")),
			index
		]
		edge.erase("selection_score")
		edge.erase("hook_key")
		selected[index] = normalize_edge(edge)
	return selected


func _build_graph_state(run_seed: int, edges: Array, generated_day_index: int, definitions: Array) -> Dictionary:
	var edge_ids: Array = []
	var edge_index: Dictionary = {}
	for edge_value in edges:
		if typeof(edge_value) != TYPE_DICTIONARY:
			continue
		var edge: Dictionary = normalize_edge(edge_value)
		if edge.is_empty():
			continue
		var edge_id: String = str(edge.get("edge_id", ""))
		edge_ids.append(edge_id)
		edge_index[edge_id] = edge
	var valid_company_ids: Array = []
	for definition in definitions:
		valid_company_ids.append(str(definition.get("id", "")))
	var state: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"generated": true,
		"run_seed": run_seed,
		"generated_day_index": generated_day_index,
		"edge_ids": edge_ids,
		"edge_index": edge_index,
		"company_edge_ids": company_edge_lookup(edge_ids, edge_index),
		"counts_by_type": count_edges_by_field(edge_ids, edge_index, "relationship_type"),
		"counts_by_visibility": count_edges_by_field(edge_ids, edge_index, "visibility"),
		"counts_by_origin": count_edges_by_field(edge_ids, edge_index, "origin"),
		"unresolved_hook_count": _unresolved_hook_count(definitions, edges),
		"validation_issues": []
	}
	return normalize_graph_state(state, valid_company_ids, run_seed, generated_day_index)


func _unresolved_hook_count(definitions: Array, edges: Array) -> int:
	var resolved_hook_keys: Dictionary = {}
	for edge_value in edges:
		if typeof(edge_value) != TYPE_DICTIONARY:
			continue
		var edge: Dictionary = edge_value
		if str(edge.get("origin", "")) != "catalog_hook":
			continue
		resolved_hook_keys["%s|%d" % [str(edge.get("source_company_id", "")), int(edge.get("source_hook_index", -1))]] = true
	var hook_count: int = 0
	for definition_value in definitions:
		var definition: Dictionary = definition_value
		var hooks: Array = definition.get("relationship_hooks", []) if typeof(definition.get("relationship_hooks", [])) == TYPE_ARRAY else []
		for hook_index in range(hooks.size()):
			var hook_value: Variant = hooks[hook_index]
			if typeof(hook_value) != TYPE_DICTIONARY:
				continue
			var hook: Dictionary = hook_value
			var relationship_type: String = normalize_relationship_type(str(hook.get("type", "")))
			if not (relationship_type in TASK2_GENERATED_TYPES):
				continue
			if not resolved_hook_keys.has("%s|%d" % [str(definition.get("id", "")), hook_index]):
				hook_count += 1
	return hook_count


func _catalog_confidence(
	run_seed: int,
	source_definition: Dictionary,
	target_definition: Dictionary,
	hook_index: int,
	strength: float,
	sector_fit_score: float,
	visibility: String
) -> float:
	var visibility_bonus: float = 0.02
	match visibility:
		"public":
			visibility_bonus = 0.08
		"semi_public":
			visibility_bonus = 0.04
		"private":
			visibility_bonus = -0.02
		"internal":
			visibility_bonus = -0.06
	var noise: float = _unit_noise(run_seed, "catalog_confidence", source_definition, target_definition, hook_index)
	return clamp(0.54 + strength * 0.24 + sector_fit_score * 0.16 + visibility_bonus + noise * 0.04, 0.0, 1.0)


func _target_tie_score(run_seed: int, source_definition: Dictionary, target_definition: Dictionary, hook_index: int) -> float:
	return _unit_noise(run_seed, "target_tie", source_definition, target_definition, hook_index)


func _unit_noise(run_seed: int, channel: String, source_definition: Dictionary, target_definition: Dictionary, ordinal: int) -> float:
	return STABLE_RNG.unit_float([
		SOURCE_SYSTEM_ID,
		channel,
		run_seed,
		str(source_definition.get("id", "")),
		str(target_definition.get("id", "")),
		ordinal
	])


func _candidate_sort_key(candidate: Dictionary) -> String:
	return "%s|%s|%s|%s|%02d" % [
		str(candidate.get("origin", "")),
		str(candidate.get("source_company_id", "")),
		str(candidate.get("target_company_id", "")),
		str(candidate.get("relationship_type", "")),
		int(candidate.get("source_hook_index", -1))
	]


static func _string_lookup(values: Array) -> Dictionary:
	var lookup: Dictionary = {}
	for value in values:
		var item: String = str(value).strip_edges()
		if item.is_empty():
			continue
		lookup[item] = true
	return lookup


static func _string_array(source_value: Variant) -> Array:
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
