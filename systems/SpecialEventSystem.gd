extends RefCounted

const MIN_TRIGGER_DAY := 8


func resolve_day(run_state, trade_date: Dictionary, day_number: int, macro_state: Dictionary) -> Dictionary:
	var active_events: Array = _active_events_for_day(run_state.get_active_special_events(), day_number)
	var started_events: Array = []
	var history: Array = run_state.get_event_history()

	if _should_start_event(run_state, day_number, active_events):
		var new_event: Dictionary = _build_special_event(run_state, trade_date, day_number, macro_state, history, active_events)
		if not new_event.is_empty():
			active_events.append(new_event)
			started_events.append(new_event.duplicate(true))

	var aggregate: Dictionary = _aggregate_effects(active_events)
	return {
		"active_events": active_events,
		"started_events": started_events,
		"market_bias_shift": float(aggregate.get("market_bias_shift", 0.0)),
		"volatility_multiplier": float(aggregate.get("volatility_multiplier", 1.0)),
		"sector_biases": aggregate.get("sector_biases", {}).duplicate(true)
	}


func _active_events_for_day(stored_events: Array, day_number: int) -> Array:
	var active_events: Array = []
	for event_value in stored_events:
		var event_data: Dictionary = event_value.duplicate(true)
		if int(event_data.get("end_day_index", 0)) >= day_number:
			active_events.append(event_data)
	return active_events


func _should_start_event(run_state, day_number: int, active_events: Array) -> bool:
	if day_number < MIN_TRIGGER_DAY:
		return false
	if not active_events.is_empty():
		return false

	var difficulty_config: Dictionary = run_state.get_difficulty_config()
	var event_interval_days: float = max(float(difficulty_config.get("event_interval_days", 30.0)), 1.0)
	var cadence: int = int(clamp(round(event_interval_days * 1.6), 10, 30))
	var cadence_offset: int = int(posmod(hash("%s|special_offset" % run_state.run_seed), cadence))
	var cadence_hit: bool = int(posmod(day_number + cadence_offset, cadence)) == 0
	if cadence_hit:
		return true

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|special_roll|%s" % [run_state.run_seed, day_number]))
	var random_threshold: float = 1.0 / max(event_interval_days * 2.8, 14.0)
	return rng.randf() < random_threshold


func _build_special_event(
	run_state,
	trade_date: Dictionary,
	day_number: int,
	macro_state: Dictionary,
	history: Array,
	active_events: Array
) -> Dictionary:
	var candidates: Array = _build_candidates(run_state, trade_date, macro_state, history, active_events)
	if candidates.is_empty():
		return {}

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|special_pick|%s" % [run_state.run_seed, day_number]))
	var picked_candidate: Dictionary = _pick_weighted_candidate(rng, candidates)
	if picked_candidate.is_empty():
		return {}

	var event_definition: Dictionary = DataRepository.get_event_definition(str(picked_candidate.get("event_id", "")))
	var duration_days: int = int(event_definition.get("duration_days", 8))
	var minimum_duration: int = int(event_definition.get("duration_days_min", duration_days))
	var maximum_duration: int = int(event_definition.get("duration_days_max", duration_days))
	duration_days = rng.randi_range(minimum_duration, max(minimum_duration, maximum_duration))

	return {
		"event_id": str(event_definition.get("id", "")),
		"scope": str(event_definition.get("scope", "market")),
		"event_family": str(event_definition.get("event_family", "special")),
		"category": str(event_definition.get("category", "special")),
		"tone": str(event_definition.get("tone", "mixed")),
		"duration_days": duration_days,
		"start_day_index": day_number,
		"end_day_index": day_number + duration_days - 1,
		"trade_date": trade_date.duplicate(true),
		"sentiment_shift": float(event_definition.get("sentiment_shift", 0.0)),
		"market_bias_shift": float(event_definition.get("market_bias_shift", 0.0)),
		"volatility_multiplier": float(event_definition.get("volatility_multiplier", 1.0)),
		"shock_profile": event_definition.get("shock_profile", {}).duplicate(true),
		"sector_biases": event_definition.get("sector_biases", {}).duplicate(true),
		"affected_sector_ids": _sector_ids_from_biases(event_definition.get("sector_biases", {})),
		"headline": str(event_definition.get("headline_template", event_definition.get("description", ""))),
		"headline_detail": str(event_definition.get("headline_detail_template", event_definition.get("description", ""))),
		"description": str(event_definition.get("description", "")),
		"broker_bias": str(event_definition.get("broker_bias", "balanced"))
	}


func _build_candidates(
	run_state,
	trade_date: Dictionary,
	macro_state: Dictionary,
	history: Array,
	active_events: Array
) -> Array:
	var candidates: Array = []
	var event_definitions: Array = DataRepository.get_event_definitions()
	var year_value: int = int(trade_date.get("year", 2020))
	var month_value: int = int(trade_date.get("month", 1))
	var event_interval_days: float = max(float(run_state.get_difficulty_config().get("event_interval_days", 30.0)), 1.0)
	var risk_appetite: float = float(macro_state.get("risk_appetite", 0.5))
	var inflation_yoy: float = float(macro_state.get("inflation_yoy", 3.0))

	for event_definition_value in event_definitions:
		var event_definition: Dictionary = event_definition_value
		if str(event_definition.get("event_family", "")) != "special":
			continue

		var event_id: String = str(event_definition.get("id", ""))
		if _already_active_or_consumed(event_id, event_definition, history, active_events):
			continue
		if year_value < int(event_definition.get("min_year", year_value)):
			continue
		if year_value > int(event_definition.get("max_year", year_value)):
			continue
		if month_value < int(event_definition.get("min_month", 1)):
			continue

		var weight: float = 0.18
		match event_id:
			"covid_wave":
				weight += 0.68
				weight += max(0.55 - risk_appetite, 0.0) * 0.45
				weight += max(month_value - 1, 0) * 0.10
			"geopolitical_turmoil":
				weight += 0.46
				weight += max(0.52 - risk_appetite, 0.0) * 0.55
				weight += max(inflation_yoy - 4.0, 0.0) * 0.05
			"commodity_price_shock":
				weight += 0.34
				weight += max(inflation_yoy - 4.1, 0.0) * 0.14
				weight += max(0.50 - risk_appetite, 0.0) * 0.20
			_:
				weight += 0.12

		weight += clamp((30.0 - event_interval_days) / 80.0, 0.0, 0.28)
		candidates.append({
			"event_id": event_id,
			"weight": weight
		})

	return candidates


func _already_active_or_consumed(event_id: String, event_definition: Dictionary, history: Array, active_events: Array) -> bool:
	for active_event_value in active_events:
		var active_event: Dictionary = active_event_value
		if str(active_event.get("event_id", "")) == event_id:
			return true

	if not bool(event_definition.get("once_per_run", false)):
		return false

	for history_value in history:
		var history_entry: Dictionary = history_value
		if str(history_entry.get("event_id", "")) == event_id:
			return true

	return false


func _aggregate_effects(active_events: Array) -> Dictionary:
	var market_bias_shift: float = 0.0
	var volatility_multiplier: float = 1.0
	var sector_biases: Dictionary = {}

	for event_value in active_events:
		var event_data: Dictionary = event_value
		market_bias_shift += float(event_data.get("market_bias_shift", 0.0))
		volatility_multiplier *= float(event_data.get("volatility_multiplier", 1.0))
		for sector_id_value in event_data.get("sector_biases", {}).keys():
			var sector_id: String = str(sector_id_value)
			sector_biases[sector_id] = float(sector_biases.get(sector_id, 0.0)) + float(event_data.get("sector_biases", {}).get(sector_id, 0.0))

	return {
		"market_bias_shift": clamp(market_bias_shift, -0.05, 0.05),
		"volatility_multiplier": clamp(volatility_multiplier, 1.0, 2.4),
		"sector_biases": sector_biases
	}


func _sector_ids_from_biases(sector_biases: Dictionary) -> Array:
	var sector_ids: Array = []
	for sector_id_value in sector_biases.keys():
		sector_ids.append(str(sector_id_value))
	return sector_ids


func _pick_weighted_candidate(rng: RandomNumberGenerator, candidates: Array) -> Dictionary:
	var total_weight: float = 0.0
	for candidate_value in candidates:
		var candidate: Dictionary = candidate_value
		total_weight += max(float(candidate.get("weight", 1.0)), 0.01)

	if total_weight <= 0.0:
		return {}

	var roll: float = rng.randf_range(0.0, total_weight)
	var cumulative_weight: float = 0.0
	for candidate_value in candidates:
		var candidate: Dictionary = candidate_value
		cumulative_weight += max(float(candidate.get("weight", 1.0)), 0.01)
		if roll <= cumulative_weight:
			var picked_candidate: Dictionary = candidate.duplicate(true)
			picked_candidate.erase("weight")
			return picked_candidate

	var fallback_candidate: Dictionary = candidates[candidates.size() - 1].duplicate(true)
	fallback_candidate.erase("weight")
	return fallback_candidate
