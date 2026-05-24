extends RefCounted

const STABLE_RNG = preload("res://systems/StableRng.gd")
const MIN_TRIGGER_DAY := 8
const POLICY_PARODY_SHOCK_CLASS := "policy_parody"
const POLICY_PARODY_MIN_TRIGGER_DAY := 10
const POLICY_PARODY_MIN_SPACING_DAYS := 12
const POLICY_PARODY_MAX_ACTIVE_EVENTS := 1
const NO_RECENT_POLICY_PARODY_DAYS := 9999


func resolve_day(run_state, trade_date: Dictionary, day_number: int, macro_state: Dictionary, attention_directives: Dictionary = {}) -> Dictionary:
	var active_events: Array = _active_events_for_day(run_state.get_active_special_events(), day_number)
	var blocking_active_events: Array = _blocking_special_events(active_events)
	var started_events: Array = []
	var history: Array = run_state.get_event_history()

	if _should_start_event(run_state, day_number, blocking_active_events, attention_directives):
		var new_event: Dictionary = _build_special_event(run_state, trade_date, day_number, macro_state, history, active_events)
		if not new_event.is_empty():
			active_events.append(new_event)
			started_events.append(new_event.duplicate(true))

	if _should_start_policy_parody_event(run_state, day_number, history, active_events, attention_directives):
		var policy_event: Dictionary = _build_policy_parody_event(run_state, trade_date, day_number, macro_state, history, active_events)
		if not policy_event.is_empty():
			active_events.append(policy_event)
			started_events.append(policy_event.duplicate(true))

	var aggregate: Dictionary = _aggregate_effects(active_events)
	return {
		"active_events": active_events,
		"started_events": started_events,
		"market_bias_shift": float(aggregate.get("market_bias_shift", 0.0)),
		"volatility_multiplier": float(aggregate.get("volatility_multiplier", 1.0)),
		"sector_biases": aggregate.get("sector_biases", {}).duplicate(true)
	}


func build_debug_special_event(
	run_state,
	trade_date: Dictionary,
	day_number: int,
	macro_state: Dictionary,
	event_id: String
) -> Dictionary:
	var event_definition: Dictionary = DataRepository.get_event_definition(event_id)
	if event_definition.is_empty() or str(event_definition.get("event_family", "")) != "special":
		return {}

	return _build_special_event_from_definition(run_state, trade_date, day_number, event_definition, macro_state)


func _active_events_for_day(stored_events: Array, day_number: int) -> Array:
	var active_events: Array = []
	for event_value in stored_events:
		var event_data: Dictionary = event_value.duplicate(true)
		if int(event_data.get("end_day_index", 0)) >= day_number:
			active_events.append(event_data)
	return active_events


func _blocking_special_events(active_events: Array) -> Array:
	var blocking_events: Array = []
	for event_value in active_events:
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event_data: Dictionary = event_value
		if _is_policy_parody_event(event_data):
			continue
		blocking_events.append(event_data)
	return blocking_events


func _should_start_event(run_state, day_number: int, active_events: Array, attention_directives: Dictionary = {}) -> bool:
	if not active_events.is_empty():
		return false
	if bool(attention_directives.get("force_special_event", false)):
		return true
	if bool(attention_directives.get("suppress_special_event", false)):
		return false
	if day_number < MIN_TRIGGER_DAY:
		return false

	var difficulty_config: Dictionary = run_state.get_difficulty_config()
	var event_interval_days: float = max(float(difficulty_config.get("event_interval_days", 30.0)), 1.0)
	var probability_multiplier: float = clamp(float(attention_directives.get("special_event_probability_multiplier", 1.0)), 0.0, 4.0)
	if probability_multiplier <= 0.0:
		return false
	var cadence: int = int(clamp(round(event_interval_days * 1.6), 10, 30))
	var cadence_offset: int = int(STABLE_RNG.seed_from_parts([run_state.run_seed, "special_offset"]) % cadence)
	var cadence_hit: bool = int(posmod(day_number + cadence_offset, cadence)) == 0
	if cadence_hit:
		return true

	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_state.run_seed, "special_roll", day_number])
	var random_threshold: float = (1.0 / max(event_interval_days * 2.8, 14.0)) * probability_multiplier
	return rng.randf() < random_threshold


func _should_start_policy_parody_event(
	run_state,
	day_number: int,
	history: Array,
	active_events: Array,
	attention_directives: Dictionary = {}
) -> bool:
	if _active_policy_parody_count(active_events) >= POLICY_PARODY_MAX_ACTIVE_EVENTS:
		return false
	if bool(attention_directives.get("force_policy_parody_event", false)):
		return true
	if bool(attention_directives.get("suppress_policy_parody_event", false)):
		return false
	if day_number < POLICY_PARODY_MIN_TRIGGER_DAY:
		return false

	var days_since_policy_parody: int = _days_since_policy_parody_event(history, day_number)
	var min_spacing_days: int = int(attention_directives.get("policy_parody_min_spacing_days", POLICY_PARODY_MIN_SPACING_DAYS))
	if days_since_policy_parody < min_spacing_days:
		return false

	var difficulty_config: Dictionary = run_state.get_difficulty_config()
	var event_interval_days: float = max(float(difficulty_config.get("event_interval_days", 30.0)), 1.0)
	var probability_multiplier: float = clamp(float(attention_directives.get("policy_parody_probability_multiplier", 1.0)), 0.0, 4.0)
	if probability_multiplier <= 0.0:
		return false

	var cadence: int = int(clamp(round(event_interval_days * 0.95), 12, 28))
	var cadence_offset: int = int(STABLE_RNG.seed_from_parts([run_state.run_seed, "policy_parody_offset"]) % cadence)
	var cadence_hit: bool = int(posmod(day_number + cadence_offset, cadence)) == 0
	if cadence_hit:
		return true

	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_state.run_seed, "policy_parody_roll", day_number])
	var random_threshold: float = (1.0 / max(event_interval_days * 2.0, 16.0)) * probability_multiplier
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

	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_state.run_seed, "special_pick", day_number])
	var picked_candidate: Dictionary = _pick_weighted_candidate(rng, candidates)
	if picked_candidate.is_empty():
		return {}

	var event_definition: Dictionary = DataRepository.get_event_definition(str(picked_candidate.get("event_id", "")))
	return _build_special_event_from_definition(run_state, trade_date, day_number, event_definition, macro_state)


func _build_policy_parody_event(
	run_state,
	trade_date: Dictionary,
	day_number: int,
	macro_state: Dictionary,
	history: Array,
	active_events: Array
) -> Dictionary:
	var candidates: Array = _build_policy_parody_candidates(run_state, trade_date, macro_state, history, active_events)
	if candidates.is_empty():
		return {}

	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_state.run_seed, "policy_parody_pick", day_number])
	var picked_candidate: Dictionary = _pick_weighted_candidate(rng, candidates)
	if picked_candidate.is_empty():
		return {}

	var event_definition: Dictionary = DataRepository.get_event_definition(str(picked_candidate.get("event_id", "")))
	return _build_special_event_from_definition(run_state, trade_date, day_number, event_definition, macro_state)


func _build_special_event_from_definition(
	run_state,
	trade_date: Dictionary,
	day_number: int,
	event_definition: Dictionary,
	macro_state: Dictionary = {}
) -> Dictionary:
	var duration_days: int = int(event_definition.get("duration_days", 8))
	var minimum_duration: int = int(event_definition.get("duration_days_min", duration_days))
	var maximum_duration: int = int(event_definition.get("duration_days_max", duration_days))
	var rng: RandomNumberGenerator = STABLE_RNG.rng([
		run_state.run_seed,
		"special_manual",
		day_number,
		str(event_definition.get("id", ""))
	])
	duration_days = rng.randi_range(minimum_duration, max(minimum_duration, maximum_duration))

	var event_data: Dictionary = {
		"event_id": str(event_definition.get("id", "")),
		"scope": str(event_definition.get("scope", "market")),
		"event_family": str(event_definition.get("event_family", "special")),
		"category": str(event_definition.get("category", "special")),
		"shock_class": str(event_definition.get("shock_class", "")),
		"allows_overlap": bool(event_definition.get("allows_overlap", false)),
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
		"summary": str(event_definition.get("summary", event_definition.get("headline_detail_template", event_definition.get("description", "")))),
		"description": str(event_definition.get("description", "")),
		"broker_bias": str(event_definition.get("broker_bias", "balanced"))
	}
	return _apply_contextual_special_event_effects(run_state, event_definition, event_data, macro_state)


func _apply_contextual_special_event_effects(
	run_state,
	event_definition: Dictionary,
	event_data: Dictionary,
	macro_state: Dictionary
) -> Dictionary:
	if str(event_data.get("event_id", "")) != "policy_free_lunch_budget_balloon":
		return event_data

	var contextual_effects_value: Variant = event_definition.get("contextual_effects", {})
	if typeof(contextual_effects_value) != TYPE_DICTIONARY:
		return event_data
	var contextual_effects: Dictionary = contextual_effects_value
	if contextual_effects.is_empty():
		return event_data

	var context: Dictionary = _policy_free_meal_market_context(run_state, macro_state)
	var context_key: String = str(context.get("key", "balanced"))
	var effect_value: Variant = contextual_effects.get(context_key, contextual_effects.get("balanced", {}))
	if typeof(effect_value) != TYPE_DICTIONARY:
		return event_data
	var effect: Dictionary = effect_value
	if effect.is_empty():
		return event_data

	event_data["policy_context"] = context_key
	event_data["policy_context_score"] = snappedf(float(context.get("score", 0.5)), 0.01)
	for numeric_key in ["sentiment_shift", "market_bias_shift", "volatility_multiplier"]:
		if effect.has(numeric_key):
			event_data[numeric_key] = float(effect.get(numeric_key, event_data.get(numeric_key, 0.0)))
	if effect.has("shock_profile") and typeof(effect.get("shock_profile", {})) == TYPE_DICTIONARY:
		event_data["shock_profile"] = effect.get("shock_profile", {}).duplicate(true)
	if effect.has("sector_biases") and typeof(effect.get("sector_biases", {})) == TYPE_DICTIONARY:
		event_data["sector_biases"] = effect.get("sector_biases", {}).duplicate(true)
		event_data["affected_sector_ids"] = _sector_ids_from_biases(event_data.get("sector_biases", {}))
	return event_data


func _policy_free_meal_market_context(run_state, macro_state: Dictionary) -> Dictionary:
	var risk_appetite: float = clamp(float(macro_state.get("risk_appetite", 0.5)), 0.0, 1.0)
	var market_bias: float = clamp(float(macro_state.get("market_bias", 0.0)), -0.026, 0.026)
	var gdp_growth: float = float(macro_state.get("gdp_growth", 4.8))
	var inflation_yoy: float = float(macro_state.get("inflation_yoy", 3.2))
	var volatility_multiplier: float = clamp(float(macro_state.get("volatility_multiplier", 1.0)), 0.8, 1.75)
	var policy_action_bps: int = int(macro_state.get("policy_action_bps", 0))
	var recent_context: Dictionary = _recent_market_context(run_state)

	var score: float = 0.5
	score += (risk_appetite - 0.5) * 0.42
	score += clamp(market_bias / 0.026, -1.0, 1.0) * 0.16
	score += clamp((gdp_growth - 4.8) / 3.0, -1.0, 1.0) * 0.12
	score -= clamp((inflation_yoy - 4.2) / 3.4, 0.0, 1.0) * 0.12
	score -= clamp((volatility_multiplier - 1.0) / 0.75, 0.0, 1.0) * 0.10
	score -= clamp(float(policy_action_bps) / 50.0, 0.0, 1.0) * 0.04
	score += clamp(float(-policy_action_bps) / 50.0, 0.0, 1.0) * 0.03
	score += float(recent_context.get("change_score", 0.0)) * 0.14
	score += float(recent_context.get("breadth_score", 0.0)) * 0.08
	score = clamp(score, 0.0, 1.0)

	var context_key: String = "balanced"
	if score >= 0.58:
		context_key = "supportive"
	elif score <= 0.43:
		context_key = "fragile"
	return {
		"key": context_key,
		"score": score
	}


func _recent_market_context(run_state) -> Dictionary:
	if run_state == null or not run_state.has_method("get_market_history"):
		return {
			"change_score": 0.0,
			"breadth_score": 0.0
		}

	var market_history: Array = run_state.get_market_history()
	var sample_count: int = min(3, market_history.size())
	if sample_count <= 0:
		return {
			"change_score": 0.0,
			"breadth_score": 0.0
		}

	var change_sum: float = 0.0
	var breadth_sum: float = 0.0
	var used_count: int = 0
	for index in range(market_history.size() - sample_count, market_history.size()):
		var entry_value: Variant = market_history[index]
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_value
		change_sum += float(entry.get("average_change_pct", entry.get("market_sentiment", 0.0)))
		var advancers: int = int(entry.get("advancers", 0))
		var decliners: int = int(entry.get("decliners", 0))
		var breadth_total: int = advancers + decliners
		if breadth_total > 0:
			breadth_sum += (float(advancers) / float(breadth_total)) - 0.5
		used_count += 1
	if used_count <= 0:
		return {
			"change_score": 0.0,
			"breadth_score": 0.0
		}

	var average_change: float = change_sum / float(used_count)
	var average_breadth_gap: float = breadth_sum / float(used_count)
	return {
		"change_score": clamp(average_change / 0.018, -1.0, 1.0),
		"breadth_score": clamp(average_breadth_gap * 2.0, -1.0, 1.0)
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
		if _is_policy_parody_definition(event_definition):
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


func _build_policy_parody_candidates(
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
		if not _is_policy_parody_definition(event_definition):
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

		var category: String = str(event_definition.get("category", ""))
		var weight: float = 0.72
		match category:
			"policy_free_meal":
				weight += max(inflation_yoy - 3.4, 0.0) * 0.08
			"policy_fiscal_shock":
				weight += max(0.58 - risk_appetite, 0.0) * 0.28
			"policy_market_speech":
				weight += 0.12
			"policy_fx_comment":
				weight += max(0.52 - risk_appetite, 0.0) * 0.24
			"policy_commodity_gate":
				weight += max(inflation_yoy - 3.8, 0.0) * 0.06
			_:
				weight += 0.06
		weight += clamp((30.0 - event_interval_days) / 90.0, 0.0, 0.22)
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


func _active_policy_parody_count(active_events: Array) -> int:
	var count: int = 0
	for event_value in active_events:
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		if _is_policy_parody_event(event_value):
			count += 1
	return count


func _days_since_policy_parody_event(history: Array, day_number: int) -> int:
	var days_since: int = NO_RECENT_POLICY_PARODY_DAYS
	for history_value in history:
		if typeof(history_value) != TYPE_DICTIONARY:
			continue
		var history_entry: Dictionary = history_value
		if not _is_policy_parody_event(history_entry):
			continue
		var event_day: int = int(history_entry.get("day_index", day_number))
		if event_day > day_number:
			continue
		days_since = min(days_since, max(day_number - event_day, 0))
	return days_since


func _is_policy_parody_definition(event_definition: Dictionary) -> bool:
	return (
		str(event_definition.get("shock_class", "")) == POLICY_PARODY_SHOCK_CLASS or
		str(event_definition.get("category", "")).begins_with("policy_") or
		str(event_definition.get("id", "")).begins_with("policy_")
	)


func _is_policy_parody_event(event_data: Dictionary) -> bool:
	return (
		str(event_data.get("shock_class", "")) == POLICY_PARODY_SHOCK_CLASS or
		str(event_data.get("category", "")).begins_with("policy_") or
		str(event_data.get("event_id", "")).begins_with("policy_")
	)


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
