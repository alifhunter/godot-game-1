extends RefCounted

const EARNINGS_MONTHS := [1, 4, 7, 10]
const SAMPLE_MIN := 4
const SAMPLE_MAX := 12
const TOP_CANDIDATE_COUNT := 5
const MAX_ARC_CANDIDATE_COUNT := 6
const ARC_MIN_TRIGGER_DAY := 5
const ARC_ELIGIBLE_EVENT_IDS := {
	"earnings_beat": true,
	"earnings_miss": true,
	"strategic_acquisition": true,
	"integration_overhang": true
}
const LAUNCH_SECTORS := {
	"consumer": true,
	"tech": true,
	"health": true,
	"transport": true
}
const RECALL_SECTORS := {
	"consumer": true,
	"health": true,
	"industrial": true,
	"transport": true,
	"energy": true
}
const MNA_SECTORS := {
	"industrial": true,
	"tech": true,
	"infra": true,
	"property": true,
	"finance": true,
	"health": true
}


func build_company_event_candidates(run_state, trade_date: Dictionary, day_number: int, macro_state: Dictionary) -> Array:
	return _build_ranked_company_candidates(run_state, trade_date, day_number, macro_state, false)


func build_company_arc_candidates(run_state, trade_date: Dictionary, day_number: int, macro_state: Dictionary) -> Array:
	return _build_ranked_company_candidates(run_state, trade_date, day_number, macro_state, true)


func resolve_day(run_state, trade_date: Dictionary, day_number: int, macro_state: Dictionary) -> Dictionary:
	var active_arcs: Array = _active_arcs_for_day(run_state.get_active_company_arcs(), day_number)
	var started_events: Array = []
	var phase_events: Array = []

	if _should_start_arc(run_state, day_number, active_arcs):
		var new_arc: Dictionary = _build_company_arc(
			run_state,
			trade_date,
			day_number,
			macro_state,
			run_state.get_event_history(),
			active_arcs
		)
		if not new_arc.is_empty():
			active_arcs.append(new_arc)
			started_events.append(_build_arc_start_event(new_arc, trade_date, day_number))

	var progressed_arcs: Array = []
	for active_arc_value in active_arcs:
		var stored_arc: Dictionary = active_arc_value.duplicate(true)
		var decorated_arc: Dictionary = _decorate_arc_for_day(stored_arc, day_number)
		if decorated_arc.is_empty():
			continue

		var previous_phase_id: String = str(stored_arc.get("last_logged_phase_id", stored_arc.get("current_phase_id", "")))
		var current_phase_id: String = str(decorated_arc.get("current_phase_id", ""))
		if previous_phase_id != current_phase_id and not previous_phase_id.is_empty():
			if str(decorated_arc.get("phase_visibility", "hidden")) != "hidden":
				phase_events.append(_build_arc_phase_event(decorated_arc, trade_date, day_number))
		decorated_arc["last_logged_phase_id"] = current_phase_id
		progressed_arcs.append(decorated_arc)

	return {
		"active_arcs": progressed_arcs,
		"started_events": started_events,
		"phase_events": phase_events
	}


func _build_ranked_company_candidates(
	run_state,
	trade_date: Dictionary,
	day_number: int,
	macro_state: Dictionary,
	arc_backed_only: bool
) -> Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|company_event|%s|%s" % [run_state.run_seed, day_number, arc_backed_only]))
	var sampled_company_ids: Array = _sample_company_ids(run_state.company_order, rng)
	var candidates: Array = []

	for company_id_value in sampled_company_ids:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = run_state.get_effective_company_definition(company_id)
		var runtime: Dictionary = run_state.get_company(company_id)
		if definition.is_empty() or runtime.is_empty():
			continue

		var company_candidates: Array = _build_company_candidates(
			definition,
			runtime,
			trade_date,
			macro_state,
			arc_backed_only
		)
		company_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get("weight", 0.0)) > float(b.get("weight", 0.0))
		)
		if not company_candidates.is_empty():
			candidates.append(company_candidates[0])
			if (
				not arc_backed_only and
				company_candidates.size() > 1 and
				float(company_candidates[1].get("weight", 0.0)) >= float(company_candidates[0].get("weight", 0.0)) * 0.86
			):
				candidates.append(company_candidates[1])

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("weight", 0.0)) > float(b.get("weight", 0.0))
	)
	var max_candidates: int = MAX_ARC_CANDIDATE_COUNT if arc_backed_only else TOP_CANDIDATE_COUNT
	if candidates.size() > max_candidates:
		candidates = candidates.slice(0, max_candidates)

	return candidates


func _sample_company_ids(company_order: Array, rng: RandomNumberGenerator) -> Array:
	var sampled_ids: Array = []
	var remaining_ids: Array = company_order.duplicate()
	var target_count: int = clamp(int(round(sqrt(float(max(company_order.size(), 1))) * 1.7)), SAMPLE_MIN, SAMPLE_MAX)
	target_count = min(target_count, remaining_ids.size())

	for _index in range(target_count):
		if remaining_ids.is_empty():
			break
		var picked_index: int = rng.randi_range(0, remaining_ids.size() - 1)
		sampled_ids.append(str(remaining_ids[picked_index]))
		remaining_ids.remove_at(picked_index)

	return sampled_ids


func _build_company_candidates(
	definition: Dictionary,
	runtime: Dictionary,
	trade_date: Dictionary,
	macro_state: Dictionary,
	arc_backed_only: bool
) -> Array:
	var candidates: Array = []
	var company_id: String = str(definition.get("id", ""))
	var ticker: String = str(definition.get("ticker", company_id.to_upper()))
	var company_name: String = str(definition.get("name", ticker))
	var sector_id: String = str(definition.get("sector_id", ""))
	var narrative_tags: Array = definition.get("narrative_tags", []).duplicate()
	var financials: Dictionary = definition.get("financials", {}).duplicate(true)
	var company_profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var traits: Dictionary = company_profile.get("generation_traits", {}).duplicate(true)
	var quality: float = float(definition.get("quality_score", 50.0))
	var growth: float = float(definition.get("growth_score", 50.0))
	var risk: float = float(definition.get("risk_score", 50.0))
	var margin: float = float(financials.get("net_profit_margin", 0.0))
	var debt_to_equity: float = float(financials.get("debt_to_equity", 0.0))
	var execution_consistency: float = float(traits.get("execution_consistency", 0.5))
	var balance_sheet_strength: float = float(traits.get("balance_sheet_strength", 0.5))
	var story_heat: float = float(traits.get("story_heat", 0.5))
	var scale: float = float(traits.get("scale", 0.5))
	var recent_sentiment: float = float(runtime.get("daily_change_pct", runtime.get("sentiment", 0.0)))
	var month_value: int = int(trade_date.get("month", 1))
	var day_value: int = int(trade_date.get("day", 1))
	var earnings_season_factor: float = _earnings_season_factor(month_value, day_value)
	var risk_appetite: float = float(macro_state.get("risk_appetite", 0.5))
	var policy_action_bps: int = int(macro_state.get("policy_action_bps", 0))
	var quarter_label: String = _quarter_label(month_value)

	var earnings_beat_weight: float = (
		earnings_season_factor * 0.70 +
		max((quality + growth - risk - 96.0) / 160.0, 0.0) +
		max(execution_consistency - 0.55, 0.0) * 0.55 +
		max((margin - 8.0) / 18.0, 0.0) * 0.22 +
		max(-recent_sentiment, 0.0) * 1.2
	)
	if "institution_quality" in narrative_tags:
		earnings_beat_weight += 0.16
	if "foreign_watchlist" in narrative_tags:
		earnings_beat_weight += 0.06
	candidates.append(_build_candidate(
		"earnings_beat",
		earnings_beat_weight,
		definition,
		trade_date,
		"%s %s earnings beat" % [ticker, quarter_label],
		"%s lands %s earnings above expectations." % [company_name, quarter_label]
	))

	var earnings_miss_weight: float = (
		earnings_season_factor * 0.62 +
		max((risk - quality + 8.0) / 115.0, 0.0) +
		max(debt_to_equity - 0.95, 0.0) * 0.18 +
		max(0.52 - execution_consistency, 0.0) * 0.72 +
		max(recent_sentiment, 0.0) * 1.45
	)
	if "narrative_hot" in narrative_tags:
		earnings_miss_weight += 0.08
	candidates.append(_build_candidate(
		"earnings_miss",
		earnings_miss_weight,
		definition,
		trade_date,
		"%s %s earnings miss" % [ticker, quarter_label],
		"%s misses %s earnings expectations and resets confidence." % [company_name, quarter_label]
	))

	if MNA_SECTORS.has(sector_id):
		var acquisition_weight: float = (
			0.14 +
			max(balance_sheet_strength - 0.55, 0.0) * 0.52 +
			max(scale - 0.50, 0.0) * 0.36 +
			max(risk_appetite - 0.50, 0.0) * 0.38
		)
		if "capex_cycle" in narrative_tags or "foreign_watchlist" in narrative_tags:
			acquisition_weight += 0.10
		candidates.append(_build_candidate(
			"strategic_acquisition",
			acquisition_weight,
			definition,
			trade_date,
			"%s explores strategic acquisition options" % ticker,
			"%s draws attention around a strategic acquisition push." % company_name
		))

		var integration_weight: float = (
			0.08 +
			max((risk - quality) / 100.0, 0.0) +
			max(debt_to_equity - 0.85, 0.0) * 0.18 +
			max(0.50 - risk_appetite, 0.0) * 0.24 +
			max(0.52 - execution_consistency, 0.0) * 0.24
		)
		candidates.append(_build_candidate(
			"integration_overhang",
			integration_weight,
			definition,
			trade_date,
			"%s faces merger integration overhang" % ticker,
			"%s faces execution overhang from merger and integration chatter." % company_name
		))

	if LAUNCH_SECTORS.has(sector_id):
		var launch_weight: float = (
			0.12 +
			max((growth - 56.0) / 95.0, 0.0) +
			story_heat * 0.30 +
			max(risk_appetite - 0.45, 0.0) * 0.16
		)
		if "narrative_hot" in narrative_tags or "retail_favorite" in narrative_tags:
			launch_weight += 0.14
		candidates.append(_build_candidate(
			"product_launch",
			launch_weight,
			definition,
			trade_date,
			"%s refreshes the product cycle" % ticker,
			"%s kicks off a product launch cycle that sharpens the growth story." % company_name
		))

	if RECALL_SECTORS.has(sector_id):
		var recall_weight: float = (
			0.07 +
			max((risk - 54.0) / 92.0, 0.0) +
			max(0.56 - execution_consistency, 0.0) * 0.74 +
			max(recent_sentiment, 0.0) * 0.20
		)
		candidates.append(_build_candidate(
			"product_recall",
			recall_weight,
			definition,
			trade_date,
			"%s hit by product recall pressure" % ticker,
			"%s faces recall-related pressure on a key product line." % company_name
		))

	var upgrade_weight: float = (
		0.09 +
		max((quality - 56.0) / 115.0, 0.0) +
		max(0.62 - execution_consistency, 0.0) * 0.28 +
		max(0.44 - balance_sheet_strength, 0.0) * 0.12
	)
	if "institution_quality" in narrative_tags:
		upgrade_weight += 0.08
	candidates.append(_build_candidate(
		"management_upgrade",
		upgrade_weight,
		definition,
		trade_date,
		"%s appoints a stronger management team" % ticker,
		"%s gets a management refresh that improves execution confidence." % company_name
	))

	var exit_weight: float = (
		0.06 +
		max((risk - 56.0) / 102.0, 0.0) +
		max(0.50 - execution_consistency, 0.0) * 0.36 +
		max(recent_sentiment, 0.0) * 0.26 +
		max(policy_action_bps, 0) / 100.0 * 0.06
	)
	if "narrative_hot" in narrative_tags or "retail_favorite" in narrative_tags:
		exit_weight += 0.08
	candidates.append(_build_candidate(
		"management_exit",
		exit_weight,
		definition,
		trade_date,
		"%s faces executive turnover questions" % ticker,
		"%s sees management turnover raise fresh execution questions." % company_name
	))

	var minimum_weight: float = 0.20 if arc_backed_only else 0.16
	return candidates.filter(func(candidate_value: Dictionary) -> bool:
		var event_id: String = str(candidate_value.get("event_id", ""))
		var is_arc_backed: bool = ARC_ELIGIBLE_EVENT_IDS.has(event_id)
		if float(candidate_value.get("weight", 0.0)) < minimum_weight:
			return false
		return is_arc_backed if arc_backed_only else not is_arc_backed
	)


func _should_start_arc(run_state, day_number: int, active_arcs: Array) -> bool:
	if day_number < ARC_MIN_TRIGGER_DAY:
		return false

	var difficulty_config: Dictionary = run_state.get_difficulty_config()
	var event_interval_days: float = max(float(difficulty_config.get("event_interval_days", 30.0)), 1.0)
	var company_count: int = max(int(difficulty_config.get("company_count", run_state.company_order.size())), 1)
	var max_active_arcs: int = clamp(int(round(sqrt(float(company_count)) * 0.45)), 1, 6)
	if active_arcs.size() >= max_active_arcs:
		return false

	var cadence: int = int(clamp(round(event_interval_days * 0.85), 5, 22))
	var cadence_offset: int = int(posmod(hash("%s|company_arc_offset" % run_state.run_seed), cadence))
	if int(posmod(day_number + cadence_offset, cadence)) == 0:
		return true

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|company_arc_roll|%s" % [run_state.run_seed, day_number]))
	var random_threshold: float = clamp(1.0 / max(event_interval_days * 1.9, 9.0), 0.03, 0.16)
	return rng.randf() < random_threshold


func _build_company_arc(
	run_state,
	trade_date: Dictionary,
	day_number: int,
	macro_state: Dictionary,
	history: Array,
	active_arcs: Array
) -> Dictionary:
	var candidates: Array = []
	for candidate_value in build_company_arc_candidates(run_state, trade_date, day_number, macro_state):
		var candidate: Dictionary = candidate_value
		if _candidate_is_available(candidate, history, active_arcs, day_number):
			candidates.append(candidate)

	if candidates.is_empty():
		return {}

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|company_arc_pick|%s" % [run_state.run_seed, day_number]))
	var picked_candidate: Dictionary = _pick_weighted_candidate(rng, candidates)
	if picked_candidate.is_empty():
		return {}

	var company_id: String = str(picked_candidate.get("target_company_id", ""))
	var definition: Dictionary = run_state.get_effective_company_definition(company_id)
	var runtime: Dictionary = run_state.get_company(company_id)
	if definition.is_empty() or runtime.is_empty():
		return {}

	var company_profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var traits: Dictionary = company_profile.get("generation_traits", {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {}).duplicate(true)
	var event_id: String = str(picked_candidate.get("event_id", ""))
	var event_definition: Dictionary = DataRepository.get_event_definition(event_id)
	var tone: String = str(event_definition.get("tone", picked_candidate.get("tone", "mixed")))
	var weight: float = float(picked_candidate.get("weight", 0.2))
	var scale: float = float(traits.get("scale", 0.5))
	var execution_consistency: float = float(traits.get("execution_consistency", 0.5))
	var balance_sheet_strength: float = float(traits.get("balance_sheet_strength", 0.5))
	var story_heat: float = float(traits.get("story_heat", 0.5))
	var free_float_pct: float = float(financials.get("free_float_pct", 28.0))
	var risk_score: float = float(definition.get("risk_score", 50.0))
	var quality_score: float = float(definition.get("quality_score", 50.0))
	var event_scale: float = _derive_arc_scale(event_id, weight, scale, story_heat)
	var confidence: float = _derive_arc_confidence(
		event_id,
		tone,
		execution_consistency,
		balance_sheet_strength,
		story_heat,
		scale,
		float(macro_state.get("risk_appetite", 0.5))
	)
	var outcome_quality: float = _derive_arc_outcome_quality(
		tone,
		event_scale,
		confidence,
		free_float_pct,
		risk_score,
		quality_score
	)
	var phase_schedule: Array = _build_phase_schedule(
		event_id,
		tone,
		event_scale,
		confidence,
		outcome_quality,
		scale,
		free_float_pct,
		run_state.run_seed,
		company_id,
		day_number
	)
	var duration_days: int = _total_phase_duration(phase_schedule)
	var arc: Dictionary = {
		"arc_id": "%s_%s_%s" % [event_id, company_id, day_number],
		"scope": "company",
		"event_id": event_id,
		"event_family": "company_arc",
		"category": str(event_definition.get("category", "company")),
		"tone": tone,
		"target_company_id": company_id,
		"target_sector_id": str(definition.get("sector_id", "")),
		"target_ticker": str(definition.get("ticker", company_id.to_upper())),
		"target_company_name": str(definition.get("name", company_id.to_upper())),
		"trade_date": trade_date.duplicate(true),
		"description": str(event_definition.get("description", "")),
		"broker_bias": str(event_definition.get("broker_bias", "balanced")),
		"phase_schedule": phase_schedule,
		"event_scale": event_scale,
		"confidence": confidence,
		"outcome_quality": outcome_quality,
		"duration_days": duration_days,
		"start_day_index": day_number,
		"end_day_index": day_number + duration_days - 1,
		"hidden_story_flag": "smart_money_accumulation" if tone != "negative" else "smart_money_distribution"
	}
	return _decorate_arc_for_day(arc, day_number)


func _candidate_is_available(candidate: Dictionary, history: Array, active_arcs: Array, day_number: int) -> bool:
	var company_id: String = str(candidate.get("target_company_id", ""))
	var event_id: String = str(candidate.get("event_id", ""))
	var cooldown_days: int = 70 if event_id in ["strategic_acquisition", "integration_overhang"] else 28

	for active_arc_value in active_arcs:
		var active_arc: Dictionary = active_arc_value
		if str(active_arc.get("target_company_id", "")) == company_id:
			return false

	for history_entry_value in history:
		var history_entry: Dictionary = history_entry_value
		if str(history_entry.get("target_company_id", "")) != company_id:
			continue
		if str(history_entry.get("event_id", "")) != event_id:
			continue
		if int(history_entry.get("day_index", -9999)) >= day_number - cooldown_days:
			return false

	return true


func _active_arcs_for_day(stored_arcs: Array, day_number: int) -> Array:
	var active_arcs: Array = []
	for arc_value in stored_arcs:
		var arc_data: Dictionary = arc_value.duplicate(true)
		if int(arc_data.get("end_day_index", 0)) >= day_number:
			active_arcs.append(arc_data)
	return active_arcs


func _decorate_arc_for_day(arc: Dictionary, day_number: int) -> Dictionary:
	var phase_schedule: Array = arc.get("phase_schedule", []).duplicate(true)
	if phase_schedule.is_empty():
		return {}

	var elapsed_days: int = max(day_number - int(arc.get("start_day_index", day_number)) + 1, 1)
	var running_total: int = 0
	for phase_value in phase_schedule:
		var phase: Dictionary = phase_value
		var duration_days: int = max(int(phase.get("duration_days", 1)), 1)
		var start_offset: int = running_total + 1
		var end_offset: int = running_total + duration_days
		if elapsed_days <= end_offset:
			arc["current_phase_id"] = str(phase.get("id", ""))
			arc["current_phase_label"] = str(phase.get("label", ""))
			arc["phase_day_index"] = elapsed_days - start_offset + 1
			arc["phase_duration_days"] = duration_days
			arc["phase_sentiment_shift"] = float(phase.get("sentiment_shift", 0.0))
			arc["phase_volatility_multiplier"] = float(phase.get("volatility_multiplier", 1.0))
			arc["phase_visibility"] = str(phase.get("visibility", "visible"))
			arc["phase_hidden_flag"] = str(phase.get("hidden_flag", arc.get("hidden_story_flag", "")))
			arc["phase_start_offset"] = start_offset
			arc["phase_end_offset"] = end_offset
			arc["days_remaining"] = int(arc.get("end_day_index", day_number)) - day_number + 1
			return arc
		running_total = end_offset

	return {}


func _derive_arc_scale(event_id: String, weight: float, scale: float, story_heat: float) -> float:
	var base_scale: float = 0.45
	match event_id:
		"strategic_acquisition", "integration_overhang":
			base_scale = 0.66
		"earnings_beat", "earnings_miss":
			base_scale = 0.52
		_:
			base_scale = 0.48

	return clamp(
		base_scale +
		clamp((weight - 0.18) / 1.05, 0.0, 0.24) +
		(scale * 0.12) +
		(story_heat * 0.06),
		0.35,
		0.96
	)


func _derive_arc_confidence(
	event_id: String,
	tone: String,
	execution_consistency: float,
	balance_sheet_strength: float,
	story_heat: float,
	scale: float,
	risk_appetite: float
) -> float:
	var confidence: float = (
		execution_consistency * 0.34 +
		balance_sheet_strength * 0.28 +
		scale * 0.14 +
		story_heat * 0.10
	)
	if event_id in ["strategic_acquisition", "integration_overhang"]:
		confidence += max(risk_appetite - 0.45, 0.0) * 0.22
	else:
		confidence += max(risk_appetite - 0.40, 0.0) * 0.08

	if tone == "negative":
		confidence += max(0.55 - execution_consistency, 0.0) * 0.18

	return clamp(confidence, 0.18, 0.96)


func _derive_arc_outcome_quality(
	tone: String,
	event_scale: float,
	confidence: float,
	free_float_pct: float,
	risk_score: float,
	quality_score: float
) -> float:
	var outcome_quality: float = (
		event_scale * 0.42 +
		confidence * 0.34 +
		clamp((quality_score - 50.0) / 40.0, 0.0, 1.0) * 0.12 +
		clamp((25.0 - free_float_pct) / 18.0, 0.0, 1.0) * 0.12
	)
	if tone == "negative":
		outcome_quality += clamp((risk_score - 50.0) / 35.0, 0.0, 1.0) * 0.14
	return clamp(outcome_quality, 0.16, 0.98)


func _build_phase_schedule(
	event_id: String,
	tone: String,
	event_scale: float,
	confidence: float,
	outcome_quality: float,
	scale: float,
	free_float_pct: float,
	run_seed: int,
	company_id: String,
	day_number: int
) -> Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|company_arc_schedule|%s|%s|%s" % [run_seed, company_id, event_id, day_number]))
	var free_float_ratio: float = clamp(free_float_pct / 100.0, 0.07, 0.60)
	var scarcity_score: float = clamp((0.60 - free_float_ratio) / 0.53, 0.0, 1.0)
	var long_rumor_event: bool = event_id in ["strategic_acquisition", "integration_overhang"]
	var accumulation_days: int
	var breakout_days: int
	var sideways_days: int
	var decline_days: int

	if long_rumor_event:
		accumulation_days = _duration_from_range(
			rng,
			18,
			60,
			clamp((event_scale * 0.36) + (confidence * 0.22) + (scale * 0.18) + (scarcity_score * 0.24), 0.0, 1.0)
		)
	else:
		accumulation_days = _duration_from_range(
			rng,
			6,
			24,
			clamp((event_scale * 0.40) + (confidence * 0.28) + (scarcity_score * 0.18) + (scale * 0.14), 0.0, 1.0)
		)
	breakout_days = _duration_from_range(
		rng,
		2,
		7 if long_rumor_event else 5,
		clamp((event_scale * 0.56) + (outcome_quality * 0.28) + (scarcity_score * 0.16), 0.0, 1.0)
	)
	sideways_days = _duration_from_range(
		rng,
		5,
		20,
		clamp((confidence * 0.34) + (outcome_quality * 0.34) + (scale * 0.14) + ((1.0 - scarcity_score) * 0.18), 0.0, 1.0)
	)
	decline_days = _duration_from_range(
		rng,
		5,
		30,
		clamp((event_scale * 0.26) + ((1.0 - outcome_quality) * 0.36) + (scale * 0.12) + (scarcity_score * 0.26), 0.0, 1.0)
	)

	if tone == "negative":
		var leak_shift: float = -lerp(0.0020, 0.0080, clamp((event_scale * 0.42) + (confidence * 0.18) + (scarcity_score * 0.40), 0.0, 1.0))
		var breakdown_shift: float = -lerp(0.0180, 0.0420, clamp((event_scale * 0.58) + (outcome_quality * 0.24) + (scarcity_score * 0.18), 0.0, 1.0))
		var sideways_shift: float = lerp(0.0010, -0.0020, outcome_quality)
		var decline_shift: float = -lerp(0.0050, 0.0160, clamp((event_scale * 0.30) + ((1.0 - outcome_quality) * 0.30) + (scarcity_score * 0.40), 0.0, 1.0))
		return [
			_build_phase_entry("distribution", "Distribution", accumulation_days, leak_shift, lerp(0.82, 1.08, scarcity_score), "hidden", "smart_money_distribution"),
			_build_phase_entry("breakdown", "Breakdown", breakout_days, breakdown_shift, lerp(1.35, 1.95, event_scale), "visible"),
			_build_phase_entry("sideways", "Sideways", sideways_days, sideways_shift, lerp(0.55, 0.88, 1.0 - event_scale), "visible"),
			_build_phase_entry("decline", "Decline", decline_days, decline_shift, lerp(0.92, 1.28, clamp((1.0 - outcome_quality) * 0.55 + scarcity_score * 0.45, 0.0, 1.0)), "visible")
		]

	var accumulation_shift: float = lerp(0.0025, 0.0095, clamp((event_scale * 0.46) + (confidence * 0.20) + (scarcity_score * 0.34), 0.0, 1.0))
	var breakout_shift: float = lerp(0.0180, 0.0430, clamp((event_scale * 0.58) + (outcome_quality * 0.24) + (scarcity_score * 0.18), 0.0, 1.0))
	var sideways_shift_positive: float = lerp(-0.0010, 0.0040, outcome_quality)
	var decline_shift_positive: float = -lerp(0.0040, 0.0130, clamp(((1.0 - outcome_quality) * 0.62) + (scarcity_score * 0.24) + ((1.0 - confidence) * 0.14), 0.0, 1.0))
	return [
		_build_phase_entry("accumulation", "Accumulation", accumulation_days, accumulation_shift, lerp(0.72, 1.02, scarcity_score), "hidden", "smart_money_accumulation"),
		_build_phase_entry("breakout", "Breakout", breakout_days, breakout_shift, lerp(1.30, 1.90, event_scale), "visible"),
		_build_phase_entry("sideways", "Sideways", sideways_days, sideways_shift_positive, lerp(0.55, 0.84, 1.0 - event_scale), "visible"),
		_build_phase_entry("decline", "Decline", decline_days, decline_shift_positive, lerp(0.86, 1.22, clamp((1.0 - outcome_quality) * 0.52 + scarcity_score * 0.48, 0.0, 1.0)), "visible")
	]


func _build_phase_entry(
	phase_id: String,
	label: String,
	duration_days: int,
	sentiment_shift: float,
	volatility_multiplier: float,
	visibility: String,
	hidden_flag: String = ""
) -> Dictionary:
	return {
		"id": phase_id,
		"label": label,
		"duration_days": max(duration_days, 1),
		"sentiment_shift": sentiment_shift,
		"volatility_multiplier": volatility_multiplier,
		"visibility": visibility,
		"hidden_flag": hidden_flag
	}


func _duration_from_range(rng: RandomNumberGenerator, minimum_days: int, maximum_days: int, bias: float) -> int:
	var weighted_bias: float = clamp(bias + rng.randf_range(-0.08, 0.08), 0.0, 1.0)
	return int(round(lerp(float(minimum_days), float(maximum_days), weighted_bias)))


func _total_phase_duration(phase_schedule: Array) -> int:
	var total_duration: int = 0
	for phase_value in phase_schedule:
		total_duration += max(int(phase_value.get("duration_days", 1)), 1)
	return total_duration


func _build_arc_start_event(arc: Dictionary, trade_date: Dictionary, day_number: int) -> Dictionary:
	return {
		"arc_id": str(arc.get("arc_id", "")),
		"event_id": str(arc.get("event_id", "")),
		"scope": "company",
		"event_family": "company_arc",
		"category": str(arc.get("category", "company")),
		"tone": str(arc.get("tone", "mixed")),
		"target_company_id": str(arc.get("target_company_id", "")),
		"target_sector_id": str(arc.get("target_sector_id", "")),
		"target_ticker": str(arc.get("target_ticker", "")),
		"target_company_name": str(arc.get("target_company_name", "")),
		"duration_days": int(arc.get("duration_days", 0)),
		"arc_phase": str(arc.get("current_phase_id", "")),
		"headline": _arc_start_headline(arc),
		"headline_detail": _arc_start_detail(arc),
		"description": str(arc.get("description", "")),
		"sentiment_shift": float(arc.get("phase_sentiment_shift", 0.0)),
		"trade_date": trade_date.duplicate(true),
		"day_index": day_number,
		"company_arc": true
	}


func _build_arc_phase_event(arc: Dictionary, trade_date: Dictionary, day_number: int) -> Dictionary:
	return {
		"arc_id": str(arc.get("arc_id", "")),
		"event_id": str(arc.get("event_id", "")),
		"scope": "company",
		"event_family": "company_arc",
		"category": str(arc.get("category", "company")),
		"tone": str(arc.get("tone", "mixed")),
		"target_company_id": str(arc.get("target_company_id", "")),
		"target_sector_id": str(arc.get("target_sector_id", "")),
		"target_ticker": str(arc.get("target_ticker", "")),
		"target_company_name": str(arc.get("target_company_name", "")),
		"duration_days": int(arc.get("duration_days", 0)),
		"arc_phase": str(arc.get("current_phase_id", "")),
		"headline": _arc_phase_headline(arc),
		"headline_detail": _arc_phase_detail(arc),
		"description": str(arc.get("description", "")),
		"sentiment_shift": float(arc.get("phase_sentiment_shift", 0.0)),
		"trade_date": trade_date.duplicate(true),
		"day_index": day_number,
		"company_arc": true
	}


func _arc_start_headline(arc: Dictionary) -> String:
	var ticker: String = str(arc.get("target_ticker", ""))
	var event_id: String = str(arc.get("event_id", ""))
	var phase_label: String = str(arc.get("current_phase_label", "Accumulation"))
	match event_id:
		"earnings_beat":
			return "%s enters %s ahead of earnings" % [ticker, phase_label.to_lower()]
		"earnings_miss":
			return "%s slips into %s ahead of earnings" % [ticker, phase_label.to_lower()]
		"strategic_acquisition":
			return "%s begins a quiet acquisition buildup" % ticker
		"integration_overhang":
			return "%s starts leaking on integration worry" % ticker
		_:
			return "%s starts a multi-phase company arc" % ticker


func _arc_start_detail(arc: Dictionary) -> String:
	var company_name: String = str(arc.get("target_company_name", "This company"))
	var phase_label: String = str(arc.get("current_phase_label", "Accumulation")).to_lower()
	return "%s enters a %s phase that can simmer for weeks before the visible move arrives." % [
		company_name,
		phase_label
	]


func _arc_phase_headline(arc: Dictionary) -> String:
	var ticker: String = str(arc.get("target_ticker", ""))
	var phase_id: String = str(arc.get("current_phase_id", ""))
	match phase_id:
		"breakout":
			return "%s breaks out from the rumor base" % ticker
		"breakdown":
			return "%s breaks down as the leak turns public" % ticker
		"sideways":
			return "%s enters a sideways digestion phase" % ticker
		"decline":
			return "%s rolls into the decline phase" % ticker
		_:
			return "%s shifts into %s" % [ticker, str(arc.get("current_phase_label", phase_id)).to_lower()]


func _arc_phase_detail(arc: Dictionary) -> String:
	var company_name: String = str(arc.get("target_company_name", "This company"))
	var phase_label: String = str(arc.get("current_phase_label", "")).to_lower()
	return "%s rotates into a %s phase as the earlier positioning starts to unwind." % [
		company_name,
		phase_label
	]


func _earnings_season_factor(month_value: int, day_value: int) -> float:
	if month_value in EARNINGS_MONTHS:
		if day_value <= 10:
			return 1.05
		if day_value <= 20:
			return 0.88
		return 0.68
	if month_value in [2, 5, 8, 11]:
		return 0.18
	return 0.10


func _quarter_label(month_value: int) -> String:
	if month_value in [1, 2, 3]:
		return "Q1"
	if month_value in [4, 5, 6]:
		return "Q2"
	if month_value in [7, 8, 9]:
		return "Q3"
	return "Q4"


func _build_candidate(
	event_id: String,
	weight: float,
	definition: Dictionary,
	trade_date: Dictionary,
	headline: String,
	headline_detail: String
) -> Dictionary:
	var event_definition: Dictionary = DataRepository.get_event_definition(event_id)
	var company_id: String = str(definition.get("id", ""))
	var ticker: String = str(definition.get("ticker", company_id.to_upper()))
	var company_name: String = str(definition.get("name", ticker))
	return {
		"event_id": event_id,
		"scope": str(event_definition.get("scope", "company")),
		"event_family": str(event_definition.get("event_family", "company")),
		"category": str(event_definition.get("category", "company")),
		"tone": str(event_definition.get("tone", "mixed")),
		"duration_days": int(event_definition.get("duration_days", 1)),
		"target_company_id": company_id,
		"target_sector_id": str(definition.get("sector_id", "")),
		"target_ticker": ticker,
		"target_company_name": company_name,
		"trade_date": trade_date.duplicate(true),
		"headline": headline,
		"headline_detail": headline_detail,
		"description": str(event_definition.get("description", "")),
		"weight": weight
	}


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
