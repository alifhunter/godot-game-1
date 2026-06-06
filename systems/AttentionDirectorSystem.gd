extends RefCounted

const CHART_SYSTEM_SCRIPT = preload("res://systems/ChartSystem.gd")
const GORENGAN_CAMPAIGN_SYSTEM_SCRIPT = preload("res://systems/GorenganCampaignSystem.gd")
const PLAYER_FACING_DAY_SIX_TRIGGER_DAY := 5
const POLICY_PARODY_MIN_TRIGGER_DAY := 10
const NO_RECENT_EVENT_DAYS := 9999
const FOCUS_COMPANY_LIMIT := 5
const DIRTY_MARKET_MIN_DAY := 20

const DIFFICULTY_PROFILES := {
	"chill": {
		"id": "chill",
		"digestion_days": 2,
		"quiet_days_before_clue": 5,
		"special_min_spacing_days": 24,
		"special_due_days": 44,
		"special_ready_multiplier": 1.05,
		"special_due_multiplier": 1.55,
		"policy_parody_min_spacing_days": 18,
		"policy_parody_due_days": 34,
		"policy_parody_quiet_days": 5,
		"policy_parody_ready_multiplier": 1.05,
		"policy_parody_due_multiplier": 1.45,
		"company_clue_multiplier": 1.45,
		"scheduled_clue_multiplier": 1.12,
		"company_lane_multiplier": 1.15,
		"scheduled_lane_multiplier": 1.05,
		"dirty_market_multiplier": 0.55,
		"max_focus_multiplier": 1.35
	},
	"normal": {
		"id": "normal",
		"digestion_days": 1,
		"quiet_days_before_clue": 3,
		"special_min_spacing_days": 18,
		"special_due_days": 35,
		"special_ready_multiplier": 1.15,
		"special_due_multiplier": 2.0,
		"policy_parody_min_spacing_days": 14,
		"policy_parody_due_days": 25,
		"policy_parody_quiet_days": 3,
		"policy_parody_ready_multiplier": 1.2,
		"policy_parody_due_multiplier": 1.9,
		"company_clue_multiplier": 2.2,
		"scheduled_clue_multiplier": 1.35,
		"company_lane_multiplier": 1.45,
		"scheduled_lane_multiplier": 1.18,
		"dirty_market_multiplier": 1.0,
		"max_focus_multiplier": 1.75
	},
	"grind": {
		"id": "grind",
		"digestion_days": 1,
		"quiet_days_before_clue": 2,
		"special_min_spacing_days": 14,
		"special_due_days": 28,
		"special_ready_multiplier": 1.28,
		"special_due_multiplier": 2.45,
		"policy_parody_min_spacing_days": 10,
		"policy_parody_due_days": 18,
		"policy_parody_quiet_days": 2,
		"policy_parody_ready_multiplier": 1.35,
		"policy_parody_due_multiplier": 2.25,
		"company_clue_multiplier": 2.75,
		"scheduled_clue_multiplier": 1.65,
		"company_lane_multiplier": 1.85,
		"scheduled_lane_multiplier": 1.38,
		"dirty_market_multiplier": 1.45,
		"max_focus_multiplier": 2.15
	}
}

var gorengan_campaign_system = GORENGAN_CAMPAIGN_SYSTEM_SCRIPT.new()


func resolve_day(run_state, trade_date: Dictionary, day_number: int, macro_state: Dictionary) -> Dictionary:
	var difficulty_profile: Dictionary = _difficulty_profile(run_state)
	var history_metrics: Dictionary = _build_history_metrics(run_state, day_number)
	var attention_snapshot: Dictionary = _build_attention_snapshot(
		run_state,
		trade_date,
		day_number,
		macro_state,
		difficulty_profile,
		history_metrics
	)
	var days_since_special_macro: int = int(history_metrics.get("days_since_special_macro", NO_RECENT_EVENT_DAYS))
	var days_since_policy_parody: int = int(history_metrics.get("days_since_policy_parody", NO_RECENT_EVENT_DAYS))
	var days_since_headline: int = int(history_metrics.get("days_since_headline", NO_RECENT_EVENT_DAYS))
	var days_since_attention_beat: int = int(history_metrics.get("days_since_attention_beat", NO_RECENT_EVENT_DAYS))
	var special_event_started: bool = days_since_special_macro < NO_RECENT_EVENT_DAYS
	var force_special_event: bool = day_number == PLAYER_FACING_DAY_SIX_TRIGGER_DAY and not special_event_started
	var headline_digesting: bool = days_since_headline <= int(difficulty_profile.get("digestion_days", 1))
	var macro_cooling_down: bool = (
		special_event_started and
		days_since_special_macro < int(difficulty_profile.get("special_min_spacing_days", 18)) and
		not force_special_event
	)
	var quiet_pressure: bool = (
		day_number > PLAYER_FACING_DAY_SIX_TRIGGER_DAY and
		not headline_digesting and
		days_since_attention_beat >= int(difficulty_profile.get("quiet_days_before_clue", 3))
	)
	var lane_scores: Dictionary = _build_lane_scores(
		attention_snapshot,
		difficulty_profile,
		macro_cooling_down,
		quiet_pressure
	)
	var selected_lane: String = _select_lane(lane_scores)
	var debug_context: Dictionary = _debug_context(
		selected_lane,
		lane_scores,
		difficulty_profile,
		attention_snapshot
	)
	_apply_policy_parody_debug_context(
		debug_context,
		day_number,
		days_since_policy_parody,
		days_since_headline,
		days_since_attention_beat,
		difficulty_profile,
		lane_scores
	)

	if force_special_event:
		debug_context["selected_lane"] = "macro"
		return _build_directives(
			true,
			false,
			1.0,
			true,
			false,
			0.0,
			true,
			1.0,
			"headline_reserved",
			"day_six_macro_reserved",
			days_since_headline,
			days_since_attention_beat,
			days_since_special_macro,
			debug_context
		)

	if day_number < PLAYER_FACING_DAY_SIX_TRIGGER_DAY:
		debug_context["selected_lane"] = "quiet"
		return _build_directives(
			false,
			true,
			0.0,
			false,
			false,
			1.0,
			false,
			1.0,
			"quiet",
			"early_game_quiet",
			days_since_headline,
			days_since_attention_beat,
			days_since_special_macro,
			debug_context
		)

	if headline_digesting:
		debug_context["selected_lane"] = "digestion"
		return _build_directives(
			false,
			true,
			0.0,
			true,
			false,
			0.0,
			true,
			0.65,
			"digestion",
			"recent_headline_cooldown",
			days_since_headline,
			days_since_attention_beat,
			days_since_special_macro,
			debug_context
		)

	if quiet_pressure:
		var quiet_selected_lane: String = "dirty_market" if selected_lane == "dirty_market" else "company"
		debug_context["selected_lane"] = quiet_selected_lane
		return _build_directives(
			false,
			macro_cooling_down,
			0.0 if macro_cooling_down else _special_event_multiplier(days_since_special_macro, difficulty_profile),
			false,
			true,
			float(difficulty_profile.get("company_clue_multiplier", 2.2)),
			false,
			float(difficulty_profile.get("scheduled_clue_multiplier", 1.35)),
			"clue_due" if quiet_selected_lane == "company" else "dirty_market_due",
			"quiet_stretch_clue_due" if quiet_selected_lane == "company" else "dirty_market_pressure_due",
			days_since_headline,
			days_since_attention_beat,
			days_since_special_macro,
			debug_context
		)

	if selected_lane == "macro" and float(lane_scores.get("macro", 0.0)) >= 0.72:
		return _build_directives(
			false,
			macro_cooling_down,
			0.0 if macro_cooling_down else _special_event_multiplier(days_since_special_macro, difficulty_profile),
			true,
			false,
			0.0,
			true,
			0.85,
			"macro_due",
			"special_due",
			days_since_headline,
			days_since_attention_beat,
			days_since_special_macro,
			debug_context
		)

	if selected_lane == "dirty_market" and float(attention_snapshot.get("dirty_market_pressure", 0.0)) > 0.0:
		return _build_directives(
			false,
			macro_cooling_down,
			0.0 if macro_cooling_down else _special_event_multiplier(days_since_special_macro, difficulty_profile),
			false,
			false,
			float(difficulty_profile.get("company_lane_multiplier", 1.45)),
			false,
			float(difficulty_profile.get("scheduled_lane_multiplier", 1.18)),
			"dirty_market_watch",
			"dirty_market_pressure",
			days_since_headline,
			days_since_attention_beat,
			days_since_special_macro,
			debug_context
		)

	if selected_lane == "company":
		return _build_directives(
			false,
			macro_cooling_down,
			0.0 if macro_cooling_down else _special_event_multiplier(days_since_special_macro, difficulty_profile),
			false,
			false,
			float(difficulty_profile.get("company_lane_multiplier", 1.45)),
			false,
			float(difficulty_profile.get("scheduled_lane_multiplier", 1.18)),
			"company_watch",
			"company_attention",
			days_since_headline,
			days_since_attention_beat,
			days_since_special_macro,
			debug_context
		)

	return _build_directives(
		false,
		macro_cooling_down,
		0.0 if macro_cooling_down else _special_event_multiplier(days_since_special_macro, difficulty_profile),
		false,
		false,
		1.0,
		false,
		1.0,
		"normal",
		"special_cooldown" if macro_cooling_down else ("special_due" if days_since_special_macro >= int(difficulty_profile.get("special_due_days", 35)) else "normal"),
		days_since_headline,
		days_since_attention_beat,
		days_since_special_macro,
		debug_context
	)


func _build_directives(
	force_special_event: bool,
	suppress_special_event: bool,
	special_event_probability_multiplier: float,
	suppress_company_arc_start: bool,
	force_company_arc_start: bool,
	company_arc_probability_multiplier: float,
	suppress_market_scheduled_event: bool,
	scheduled_event_probability_multiplier: float,
	attention_tier: String,
	reason: String,
	days_since_headline: int,
	days_since_attention_beat: int,
	days_since_special_macro: int,
	debug_context: Dictionary = {}
) -> Dictionary:
	var directives: Dictionary = {
		"force_special_event": force_special_event,
		"suppress_special_event": suppress_special_event,
		"special_event_probability_multiplier": special_event_probability_multiplier,
		"suppress_company_arc_start": suppress_company_arc_start,
		"force_company_arc_start": force_company_arc_start,
		"company_arc_probability_multiplier": company_arc_probability_multiplier,
		"suppress_market_scheduled_event": suppress_market_scheduled_event,
		"scheduled_event_probability_multiplier": scheduled_event_probability_multiplier,
		"attention_tier": attention_tier,
		"reason": reason,
		"days_since_headline": days_since_headline,
		"days_since_attention_beat": days_since_attention_beat,
		"days_since_special_macro": days_since_special_macro,
		"days_since_policy_parody": int(debug_context.get("days_since_policy_parody", NO_RECENT_EVENT_DAYS)),
		"suppress_policy_parody_event": bool(debug_context.get("suppress_policy_parody_event", true)),
		"policy_parody_probability_multiplier": float(debug_context.get("policy_parody_probability_multiplier", 0.0)),
		"policy_parody_min_spacing_days": int(debug_context.get("policy_parody_min_spacing_days", 14)),
		"policy_parody_attention_score": float(debug_context.get("policy_parody_attention_score", 0.0)),
		"selected_lane": str(debug_context.get("selected_lane", attention_tier)),
		"lane_scores": debug_context.get("lane_scores", {}).duplicate(true),
		"difficulty_profile_id": str(debug_context.get("difficulty_profile_id", "normal")),
		"focus_company_ids": debug_context.get("focus_company_ids", []).duplicate(),
		"focus_company_weights": debug_context.get("focus_company_weights", {}).duplicate(true),
		"dirty_market_pressure": float(debug_context.get("dirty_market_pressure", 0.0)),
		"market_stress_score": float(debug_context.get("market_stress_score", 0.0)),
		"best_company_attention_score": float(debug_context.get("best_company_attention_score", 0.0))
	}
	return directives


func _debug_context(
	selected_lane: String,
	lane_scores: Dictionary,
	difficulty_profile: Dictionary,
	attention_snapshot: Dictionary
) -> Dictionary:
	return {
		"selected_lane": selected_lane,
		"lane_scores": lane_scores.duplicate(true),
		"difficulty_profile_id": str(difficulty_profile.get("id", "normal")),
		"focus_company_ids": attention_snapshot.get("focus_company_ids", []).duplicate(),
		"focus_company_weights": attention_snapshot.get("focus_company_weights", {}).duplicate(true),
		"dirty_market_pressure": float(attention_snapshot.get("dirty_market_pressure", 0.0)),
		"market_stress_score": float(attention_snapshot.get("market_stress_score", 0.0)),
		"best_company_attention_score": float(attention_snapshot.get("best_company_attention_score", 0.0))
	}


func _difficulty_profile(run_state) -> Dictionary:
	var difficulty_config: Dictionary = run_state.get_difficulty_config()
	var difficulty_id: String = str(difficulty_config.get("id", "normal")).strip_edges().to_lower()
	var profile: Dictionary = DIFFICULTY_PROFILES.get(difficulty_id, DIFFICULTY_PROFILES["normal"]).duplicate(true)
	profile["id"] = str(profile.get("id", difficulty_id))
	return profile


func _build_history_metrics(run_state, day_number: int) -> Dictionary:
	var days_since_special_macro: int = _days_since_recent_event(run_state, day_number, Callable(self, "_is_special_macro_event"))
	var days_since_policy_parody: int = _days_since_recent_event(run_state, day_number, Callable(self, "_is_policy_parody_event"))
	var days_since_headline: int = _days_since_recent_event(run_state, day_number, Callable(self, "_is_headline_event"))
	var days_since_attention_beat: int = _days_since_recent_event(run_state, day_number, Callable(self, "_is_attention_beat"))
	return {
		"days_since_special_macro": days_since_special_macro,
		"days_since_policy_parody": days_since_policy_parody,
		"days_since_headline": days_since_headline,
		"days_since_attention_beat": days_since_attention_beat
	}


func _build_attention_snapshot(
	run_state,
	_trade_date: Dictionary,
	day_number: int,
	macro_state: Dictionary,
	difficulty_profile: Dictionary,
	history_metrics: Dictionary
) -> Dictionary:
	var company_rows: Array = _build_company_attention_rows(run_state, day_number, difficulty_profile)
	var best_company_attention_score: float = 0.0
	var dirty_market_pressure: float = 0.0
	var focus_company_ids: Array = []
	var focus_company_weights: Dictionary = {}
	var focus_limit: int = min(FOCUS_COMPANY_LIMIT, company_rows.size())
	for row_index in range(company_rows.size()):
		var row: Dictionary = company_rows[row_index]
		best_company_attention_score = max(best_company_attention_score, float(row.get("attention_score", 0.0)))
		dirty_market_pressure = max(dirty_market_pressure, float(row.get("dirty_market_score", 0.0)))
		if row_index < focus_limit and float(row.get("attention_score", 0.0)) >= 0.12:
			var company_id: String = str(row.get("company_id", ""))
			if not company_id.is_empty():
				focus_company_ids.append(company_id)
				focus_company_weights[company_id] = float(row.get("focus_weight", 1.0))

	var dirty_visibility: Dictionary = _dirty_market_visibility(run_state, day_number)
	if not bool(dirty_visibility.get("eligible", false)):
		dirty_market_pressure = 0.0

	return {
		"days_since_special_macro": int(history_metrics.get("days_since_special_macro", NO_RECENT_EVENT_DAYS)),
		"days_since_policy_parody": int(history_metrics.get("days_since_policy_parody", NO_RECENT_EVENT_DAYS)),
		"days_since_headline": int(history_metrics.get("days_since_headline", NO_RECENT_EVENT_DAYS)),
		"days_since_attention_beat": int(history_metrics.get("days_since_attention_beat", NO_RECENT_EVENT_DAYS)),
		"market_stress_score": _market_stress_score(macro_state, run_state.get_active_special_events()),
		"active_special_event_count": run_state.get_active_special_events().size(),
		"best_company_attention_score": best_company_attention_score,
		"dirty_market_pressure": dirty_market_pressure,
		"dirty_market_visibility_score": float(dirty_visibility.get("score", 0.0)),
		"focus_company_ids": focus_company_ids,
		"focus_company_weights": focus_company_weights
	}


func _build_lane_scores(
	attention_snapshot: Dictionary,
	difficulty_profile: Dictionary,
	macro_cooling_down: bool,
	quiet_pressure: bool
) -> Dictionary:
	var days_since_special_macro: int = int(attention_snapshot.get("days_since_special_macro", NO_RECENT_EVENT_DAYS))
	var days_since_policy_parody: int = int(attention_snapshot.get("days_since_policy_parody", NO_RECENT_EVENT_DAYS))
	var days_since_attention_beat: int = int(attention_snapshot.get("days_since_attention_beat", NO_RECENT_EVENT_DAYS))
	var special_due_days: float = max(float(difficulty_profile.get("special_due_days", 35)), 1.0)
	var special_due_score: float = clamp(float(days_since_special_macro) / special_due_days, 0.0, 1.0)
	var policy_due_days: float = max(float(difficulty_profile.get("policy_parody_due_days", 25)), 1.0)
	var policy_due_score: float = clamp(float(days_since_policy_parody) / policy_due_days, 0.0, 1.0)
	var policy_quiet_days: float = max(float(difficulty_profile.get("policy_parody_quiet_days", 3)), 1.0)
	var policy_quiet_score: float = clamp(float(days_since_attention_beat) / policy_quiet_days, 0.0, 1.0)
	var market_stress_score: float = float(attention_snapshot.get("market_stress_score", 0.0))
	var best_company_score: float = float(attention_snapshot.get("best_company_attention_score", 0.0))
	var dirty_market_pressure: float = float(attention_snapshot.get("dirty_market_pressure", 0.0))

	var macro_score: float = clamp((special_due_score * 0.58) + (market_stress_score * 0.42), 0.0, 1.0)
	if macro_cooling_down:
		macro_score = 0.0

	var company_score: float = clamp(
		(best_company_score * 0.72) +
		(0.28 if quiet_pressure else 0.08),
		0.0,
		1.0
	)
	var scheduled_score: float = clamp(
		0.18 +
		(market_stress_score * 0.18) +
		(0.24 if quiet_pressure else 0.0) +
		(best_company_score * 0.22),
		0.0,
		1.0
	)
	var dirty_score: float = clamp(dirty_market_pressure, 0.0, 1.0)
	var policy_parody_score: float = clamp(
		0.12 +
		(policy_due_score * 0.48) +
		(policy_quiet_score * 0.30) -
		(market_stress_score * 0.10),
		0.0,
		1.0
	)

	return {
		"macro": snappedf(macro_score, 0.001),
		"company": snappedf(company_score, 0.001),
		"scheduled": snappedf(scheduled_score, 0.001),
		"dirty_market": snappedf(dirty_score, 0.001),
		"policy_parody": snappedf(policy_parody_score, 0.001),
		"digestion": 0.0
	}


func _select_lane(lane_scores: Dictionary) -> String:
	var order: Array = ["dirty_market", "macro", "company", "scheduled"]
	var selected_lane: String = "normal"
	var selected_score: float = 0.0
	for lane_value in order:
		var lane: String = str(lane_value)
		var score: float = float(lane_scores.get(lane, 0.0))
		if score > selected_score:
			selected_score = score
			selected_lane = lane
	return selected_lane if selected_score >= 0.34 else "normal"


func _special_event_multiplier(days_since_special_macro: int, difficulty_profile: Dictionary) -> float:
	if days_since_special_macro >= int(difficulty_profile.get("special_due_days", 35)):
		return float(difficulty_profile.get("special_due_multiplier", 2.0))
	if days_since_special_macro >= int(difficulty_profile.get("special_min_spacing_days", 18)):
		return float(difficulty_profile.get("special_ready_multiplier", 1.15))
	if days_since_special_macro >= NO_RECENT_EVENT_DAYS:
		return 1.0
	return 0.0


func _apply_policy_parody_debug_context(
	debug_context: Dictionary,
	day_number: int,
	days_since_policy_parody: int,
	days_since_headline: int,
	days_since_attention_beat: int,
	difficulty_profile: Dictionary,
	lane_scores: Dictionary
) -> void:
	var min_spacing_days: int = int(difficulty_profile.get("policy_parody_min_spacing_days", 14))
	var probability_multiplier: float = _policy_parody_event_multiplier(
		day_number,
		days_since_policy_parody,
		days_since_headline,
		days_since_attention_beat,
		difficulty_profile
	)
	debug_context["days_since_policy_parody"] = days_since_policy_parody
	debug_context["suppress_policy_parody_event"] = probability_multiplier <= 0.0
	debug_context["policy_parody_probability_multiplier"] = probability_multiplier
	debug_context["policy_parody_min_spacing_days"] = min_spacing_days
	debug_context["policy_parody_attention_score"] = float(lane_scores.get("policy_parody", 0.0))


func _policy_parody_event_multiplier(
	day_number: int,
	days_since_policy_parody: int,
	days_since_headline: int,
	days_since_attention_beat: int,
	difficulty_profile: Dictionary
) -> float:
	if day_number < POLICY_PARODY_MIN_TRIGGER_DAY:
		return 0.0
	if days_since_policy_parody < int(difficulty_profile.get("policy_parody_min_spacing_days", 14)):
		return 0.0

	var multiplier: float = 0.85
	if days_since_policy_parody >= int(difficulty_profile.get("policy_parody_due_days", 25)):
		multiplier = float(difficulty_profile.get("policy_parody_due_multiplier", 1.9))
	elif days_since_policy_parody >= int(difficulty_profile.get("policy_parody_min_spacing_days", 14)):
		multiplier = float(difficulty_profile.get("policy_parody_ready_multiplier", 1.2))

	if days_since_attention_beat >= int(difficulty_profile.get("policy_parody_quiet_days", 3)):
		multiplier *= 1.2
	if days_since_headline <= int(difficulty_profile.get("digestion_days", 1)):
		multiplier *= 0.65
	return clamp(multiplier, 0.0, 3.0)


func _build_company_attention_rows(run_state, day_number: int, difficulty_profile: Dictionary) -> Array:
	var rows: Array = []
	var chart_signal_system = CHART_SYSTEM_SCRIPT.new()
	for company_id_value in run_state.company_order:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
		var runtime: Dictionary = run_state.get_company(company_id)
		if definition.is_empty() or runtime.is_empty():
			continue
		var row: Dictionary = _score_company_attention(run_state, definition, runtime, day_number, difficulty_profile, chart_signal_system)
		if not row.is_empty():
			rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("focus_rank_score", 0.0)), float(b.get("focus_rank_score", 0.0))):
			return str(a.get("company_id", "")) < str(b.get("company_id", ""))
		return float(a.get("focus_rank_score", 0.0)) > float(b.get("focus_rank_score", 0.0))
	)
	return rows


func _score_company_attention(
	run_state,
	definition: Dictionary,
	runtime: Dictionary,
	day_number: int,
	difficulty_profile: Dictionary,
	chart_signal_system
) -> Dictionary:
	var company_id: String = str(definition.get("id", ""))
	if company_id.is_empty():
		return {}
	var financials: Dictionary = definition.get("financials", {})
	var company_profile: Dictionary = runtime.get("company_profile", {}) if typeof(runtime.get("company_profile", {})) == TYPE_DICTIONARY else {}
	if bool(company_profile.get("trade_disabled", false)):
		return {}

	var current_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var market_cap: float = max(float(financials.get("market_cap", current_price * 1000000000.0)), current_price * 1000000.0)
	var avg_daily_value: float = max(float(financials.get("avg_daily_value", current_price * 250000.0)), current_price * 1000.0)
	var free_float_ratio: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, 0.02, 0.95)
	var quality_score: float = clamp(float(definition.get("quality_score", 50.0)) / 100.0, 0.0, 1.0)
	var growth_score: float = clamp(float(definition.get("growth_score", 50.0)) / 100.0, 0.0, 1.0)
	var risk_score: float = clamp(float(definition.get("risk_score", 50.0)) / 100.0, 0.0, 1.0)
	var financial_tension: float = clamp(
		(risk_score * 0.42) +
		(clamp(float(financials.get("debt_to_equity", 0.0)) / 2.0, 0.0, 1.0) * 0.22) +
		(clamp((8.0 - float(financials.get("net_profit_margin", 0.0))) / 18.0, 0.0, 1.0) * 0.18) +
		((1.0 - quality_score) * 0.18),
		0.0,
		1.0
	)
	var fundamental_interest: float = clamp(
		max(quality_score, growth_score) * 0.38 +
		risk_score * 0.26 +
		clamp(absf(float(financials.get("revenue_growth_yoy", 0.0))) / 24.0, 0.0, 1.0) * 0.18 +
		clamp(absf(float(financials.get("earnings_growth_yoy", 0.0))) / 28.0, 0.0, 1.0) * 0.18,
		0.0,
		1.0
	)

	var traits: Dictionary = company_profile.get("generation_traits", {}) if typeof(company_profile.get("generation_traits", {})) == TYPE_DICTIONARY else {}
	var narrative_tags: Array = definition.get("narrative_tags", []).duplicate()
	var story_heat: float = clamp(float(traits.get("story_heat", 0.5)), 0.0, 1.0)
	if "narrative_hot" in narrative_tags:
		story_heat = clamp(story_heat + 0.18, 0.0, 1.0)
	if "retail_favorite" in narrative_tags:
		story_heat = clamp(story_heat + 0.14, 0.0, 1.0)
	if "foreign_watchlist" in narrative_tags or "institution_quality" in narrative_tags:
		story_heat = clamp(story_heat + 0.08, 0.0, 1.0)

	var depth_context: Dictionary = runtime.get("market_depth_context", {}) if typeof(runtime.get("market_depth_context", {})) == TYPE_DICTIONARY else {}
	var visible_depth_value: float = max(float(depth_context.get("visible_depth_value", depth_context.get("ask_depth_value", avg_daily_value))), current_price * 1000.0)
	var cash_to_depth_ratio: float = max(float(run_state.player_portfolio.get("cash", 0.0)), 0.0) / max(visible_depth_value, 1.0)
	var liquidity_score: float = clamp((log(avg_daily_value) - 14.0) / 6.0, 0.0, 1.0)
	var thin_float_score: float = clamp((0.42 - free_float_ratio) / 0.35, 0.0, 1.0)
	var depth_tension: float = clamp(
		thin_float_score * 0.42 +
		(1.0 - liquidity_score) * 0.28 +
		clamp(cash_to_depth_ratio / 1.4, 0.0, 1.0) * 0.18 +
		clamp(float(depth_context.get("float_tightness", 0.0)), 0.0, 1.0) * 0.12,
		0.0,
		1.0
	)

	var broker_flow: Dictionary = runtime.get("broker_flow", {}) if typeof(runtime.get("broker_flow", {})) == TYPE_DICTIONARY else {}
	var broker_activity: float = _broker_activity_score(broker_flow)
	var dirty_broker_score: float = _dirty_broker_score(broker_flow)
	var volume_context: Dictionary = runtime.get("volume_context", {}) if typeof(runtime.get("volume_context", {})) == TYPE_DICTIONARY else {}
	var volume_activity: float = clamp(
		(clamp(float(volume_context.get("expected_activity_ratio", 1.0)) - 1.0, 0.0, 2.5) / 2.5) * 0.42 +
		(clamp(float(volume_context.get("volume_multiplier", 1.0)) - 1.0, 0.0, 2.5) / 2.5) * 0.28 +
		max(float(volume_context.get("accumulation_signal", 0.0)), float(volume_context.get("distribution_signal", 0.0))) * 0.30,
		0.0,
		1.0
	)
	var chart_activity: float = _chart_activity_score(runtime.get("price_bars", []))
	var chart_profile: Dictionary = _chart_profile_for_attention(definition, company_profile)
	var operator_pressure: float = clamp(
		max(
			float(chart_profile.get("operator_pressure", 0.0)),
			float(volume_context.get("operator_pressure", 0.0))
		),
		0.0,
		1.0
	)
	var cycle_attention: float = _cycle_attention_score(chart_profile, chart_activity, volume_activity)
	var technical_signal_summary: Dictionary = {}
	if chart_signal_system != null:
		technical_signal_summary = chart_signal_system.build_technical_signal_summary_from_bars(runtime.get("price_bars", []), "3m")
	var technical_signal_score: float = clamp(float(technical_signal_summary.get("score", 0.0)), 0.0, 1.0)
	var divergence_pressure: float = _technical_divergence_pressure(technical_signal_summary)
	var player_flow_context: Dictionary = run_state.get_player_market_flow_context(company_id, day_number) if run_state.has_method("get_player_market_flow_context") else {}
	var player_footprint: float = clamp(
		float(player_flow_context.get("gross_free_float_pct", 0.0)) * 22.0 +
		float(player_flow_context.get("max_single_trade_free_float_pct", 0.0)) * 42.0 +
		float(player_flow_context.get("active_entries", 0.0)) * 0.05,
		0.0,
		1.0
	)
	var corporate_pressure: float = _corporate_pressure_score(company_profile, runtime)
	var campaign_attention: Dictionary = gorengan_campaign_system.campaign_attention_context(runtime)

	var attention_score: float = clamp(
		fundamental_interest * 0.18 +
		story_heat * 0.16 +
		depth_tension * 0.16 +
		broker_activity * 0.15 +
		volume_activity * 0.12 +
		chart_activity * 0.08 +
		cycle_attention * 0.07 +
		technical_signal_score * 0.05 +
		corporate_pressure * 0.08 +
		player_footprint * 0.05 +
		operator_pressure * 0.04 +
		float(campaign_attention.get("attention_boost", 0.0)),
		0.0,
		1.0
	)
	var dirty_market_score: float = clamp(
		(
			thin_float_score * 0.21 +
			depth_tension * 0.17 +
			financial_tension * 0.16 +
			story_heat * 0.13 +
			dirty_broker_score * 0.20 +
			max(volume_activity, chart_activity) * 0.08 +
			player_footprint * 0.05 +
			operator_pressure * 0.13 +
			divergence_pressure * 0.04 +
			float(campaign_attention.get("dirty_boost", 0.0))
		) * float(difficulty_profile.get("dirty_market_multiplier", 1.0)),
		0.0,
		1.0
	)
	var focus_rank_score: float = max(attention_score, dirty_market_score * 0.85, operator_pressure * 0.58 + float(campaign_attention.get("focus_boost", 0.0)))
	var focus_weight: float = clamp(
		1.0 + (attention_score * 0.72) + (dirty_market_score * 0.36) + (cycle_attention * 0.12) + float(campaign_attention.get("focus_boost", 0.0)),
		1.0,
		float(difficulty_profile.get("max_focus_multiplier", 1.75))
	)
	return {
		"company_id": company_id,
		"attention_score": snappedf(attention_score, 0.001),
		"dirty_market_score": snappedf(dirty_market_score, 0.001),
		"focus_rank_score": snappedf(focus_rank_score, 0.001),
		"focus_weight": snappedf(focus_weight, 0.001),
		"market_cap": market_cap,
		"avg_daily_value": avg_daily_value,
		"free_float_ratio": free_float_ratio,
		"operator_pressure": snappedf(operator_pressure, 0.001),
		"cycle_attention_score": snappedf(cycle_attention, 0.001),
		"technical_signal_score": snappedf(technical_signal_score, 0.001)
	}


func _market_stress_score(macro_state: Dictionary, active_special_events: Array) -> float:
	var volatility_score: float = clamp((float(macro_state.get("volatility_multiplier", 1.0)) - 1.0) / 0.75, 0.0, 1.0)
	var risk_appetite_stress: float = clamp((0.55 - float(macro_state.get("risk_appetite", 0.5))) / 0.45, 0.0, 1.0)
	var market_bias_stress: float = clamp(absf(float(macro_state.get("market_bias", 0.0))) / 0.026, 0.0, 1.0)
	var special_event_stress: float = 0.0
	for event_value in active_special_events:
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event_data: Dictionary = event_value
		special_event_stress = max(special_event_stress, clamp(float(event_data.get("volatility_multiplier", 1.0)) - 1.0, 0.0, 1.0))
	return clamp(
		volatility_score * 0.34 +
		risk_appetite_stress * 0.28 +
		market_bias_stress * 0.26 +
		special_event_stress * 0.12,
		0.0,
		1.0
	)


func _dirty_market_visibility(run_state, day_number: int) -> Dictionary:
	if day_number < DIRTY_MARKET_MIN_DAY:
		return {"eligible": false, "score": 0.0}
	var difficulty_config: Dictionary = run_state.get_difficulty_config()
	var starting_cash: float = max(float(difficulty_config.get("starting_cash", 1.0)), 1.0)
	var equity: float = max(run_state.get_total_equity(), 0.0)
	var equity_ratio: float = equity / starting_cash
	var recognition_score: float = _recognition_score(run_state)
	var eligible: bool = recognition_score >= 35.0 or equity_ratio >= 1.5
	return {
		"eligible": eligible,
		"score": clamp(max(recognition_score / 100.0, (equity_ratio - 1.0) / 1.2), 0.0, 1.0)
	}


func _recognition_score(run_state) -> float:
	var difficulty_config: Dictionary = run_state.get_difficulty_config()
	var starting_cash: float = max(float(difficulty_config.get("starting_cash", 1.0)), 1.0)
	var equity: float = max(run_state.get_total_equity(), 0.0)
	var equity_ratio: float = clamp((equity - starting_cash) / starting_cash, 0.0, 1.0)
	var equity_score: float = equity_ratio * 40.0

	var holdings: Dictionary = run_state.player_portfolio.get("holdings", {})
	var held_company_count: int = 0
	for holding_value in holdings.values():
		if typeof(holding_value) != TYPE_DICTIONARY:
			continue
		var holding: Dictionary = holding_value
		if int(holding.get("shares", 0)) >= int(run_state.LOT_SIZE):
			held_company_count += 1
	var exposure_ratio: float = 0.0
	if equity > 0.0:
		exposure_ratio = clamp(run_state.get_portfolio_market_value() / equity, 0.0, 1.0)
	var ownership_score: float = clamp(float(held_company_count) / 6.0, 0.0, 1.0) * 15.0 + exposure_ratio * 15.0

	var met_count: int = 0
	for runtime_value in run_state.get_network_contacts().values():
		if typeof(runtime_value) != TYPE_DICTIONARY:
			continue
		var runtime: Dictionary = runtime_value
		if bool(runtime.get("met", false)):
			met_count += 1
	var contact_score: float = clamp(float(met_count) / 8.0, 0.0, 1.0) * 30.0
	return clamp(equity_score + ownership_score + contact_score, 0.0, 100.0)


func _broker_activity_score(broker_flow: Dictionary) -> float:
	if broker_flow.is_empty():
		return 0.0
	return clamp(
		absf(float(broker_flow.get("net_pressure", 0.0))) * 0.30 +
		absf(float(broker_flow.get("smart_money_pressure", 0.0))) * 0.22 +
		clamp(absf(float(broker_flow.get("action_meter_score", 0.0))) / 100.0, 0.0, 1.0) * 0.18 +
		clamp(absf(float(broker_flow.get("foreign_net", 0.0))) / 100.0, 0.0, 1.0) * 0.10 +
		clamp(absf(float(broker_flow.get("institution_net", 0.0))) / 100.0, 0.0, 1.0) * 0.10 +
		clamp(absf(float(broker_flow.get("retail_net", 0.0))) / 100.0, 0.0, 1.0) * 0.10,
		0.0,
		1.0
	)


func _dirty_broker_score(broker_flow: Dictionary) -> float:
	if broker_flow.is_empty():
		return 0.0
	return clamp(
		clamp(absf(float(broker_flow.get("bandar_net", 0.0))) / 100.0, 0.0, 1.0) * 0.44 +
		clamp(absf(float(broker_flow.get("zombie_net", 0.0))) / 100.0, 0.0, 1.0) * 0.28 +
		clamp(max(float(broker_flow.get("retail_net", 0.0)), 0.0) / 100.0, 0.0, 1.0) * 0.18 +
		clamp(max(float(broker_flow.get("action_meter_score", 0.0)), 0.0) / 100.0, 0.0, 1.0) * 0.10,
		0.0,
		1.0
	)


func _chart_activity_score(price_bars: Array) -> float:
	if price_bars.size() < 3:
		return 0.0
	var latest_bar: Dictionary = price_bars[price_bars.size() - 1] if typeof(price_bars[price_bars.size() - 1]) == TYPE_DICTIONARY else {}
	var start_bar: Dictionary = price_bars[max(price_bars.size() - 6, 0)] if typeof(price_bars[max(price_bars.size() - 6, 0)]) == TYPE_DICTIONARY else {}
	var start_close: float = max(float(start_bar.get("close", latest_bar.get("close", 1.0))), 1.0)
	var latest_close: float = max(float(latest_bar.get("close", start_close)), 1.0)
	var recent_move: float = absf((latest_close / start_close) - 1.0)
	var latest_value: float = _bar_value(latest_bar)
	var recent_average_value: float = _average_bar_value(price_bars, min(price_bars.size(), 10), latest_value)
	var volume_ratio_score: float = clamp((latest_value / max(recent_average_value, 1.0) - 1.0) / 1.8, 0.0, 1.0)
	return clamp(recent_move * 5.0 + volume_ratio_score * 0.34, 0.0, 1.0)


func _chart_profile_for_attention(definition: Dictionary, company_profile: Dictionary) -> Dictionary:
	var traits_value = definition.get("generation_traits", {})
	var traits: Dictionary = {}
	if typeof(traits_value) == TYPE_DICTIONARY:
		traits = traits_value
	if traits.is_empty():
		var runtime_traits_value = company_profile.get("generation_traits", {})
		if typeof(runtime_traits_value) == TYPE_DICTIONARY:
			traits = runtime_traits_value
	var chart_profile_value = traits.get("chart_profile", {})
	if typeof(chart_profile_value) != TYPE_DICTIONARY:
		return {}
	return chart_profile_value


func _cycle_attention_score(chart_profile: Dictionary, chart_activity: float, volume_activity: float) -> float:
	var cycle_template: String = str(chart_profile.get("cycle_template", ""))
	if cycle_template.is_empty():
		return 0.0
	var cycle_strength: float = clamp(float(chart_profile.get("cycle_strength", 0.0)), 0.0, 1.0)
	var operator_pressure: float = clamp(float(chart_profile.get("operator_pressure", 0.0)), 0.0, 1.0)
	var template_weight: float = 0.50
	match cycle_template:
		"markup_clean":
			template_weight = 0.56
		"markup_exhaustion":
			template_weight = 0.68
		"distribution_clean":
			template_weight = 0.62
		"failed_markup":
			template_weight = 0.70
		"operator_markup":
			template_weight = 0.74
		"operator_rug":
			template_weight = 0.82
	return clamp(
		cycle_strength * template_weight +
		operator_pressure * 0.18 +
		max(chart_activity, volume_activity) * 0.18,
		0.0,
		1.0
	)


func _technical_divergence_pressure(technical_signal_summary: Dictionary) -> float:
	var pressure: float = 0.0
	for signal_value in technical_signal_summary.get("signals", []):
		if typeof(signal_value) != TYPE_DICTIONARY:
			continue
		var signal_row: Dictionary = signal_value
		var signal_type: String = str(signal_row.get("signal_type", ""))
		if signal_type.ends_with("divergence"):
			pressure = max(pressure, float(signal_row.get("strength", 0.0)))
	return clamp(pressure, 0.0, 1.0)


func _average_bar_value(price_bars: Array, lookback: int, fallback_value: float) -> float:
	if price_bars.is_empty():
		return max(fallback_value, 1.0)
	var start_index: int = max(price_bars.size() - max(lookback, 1), 0)
	var total_value: float = 0.0
	var count: int = 0
	for bar_index in range(start_index, price_bars.size()):
		if typeof(price_bars[bar_index]) != TYPE_DICTIONARY:
			continue
		total_value += _bar_value(price_bars[bar_index])
		count += 1
	if count <= 0:
		return max(fallback_value, 1.0)
	return max(total_value / float(count), 1.0)


func _bar_value(bar: Dictionary) -> float:
	var value: float = float(bar.get("value", 0.0))
	if value <= 0.0:
		value = float(bar.get("close", 0.0)) * float(bar.get("volume_shares", 0.0))
	return max(value, 1.0)


func _corporate_pressure_score(company_profile: Dictionary, runtime: Dictionary) -> float:
	var score: float = 0.0
	for key in ["delisting_watch", "restructuring_result", "acquisition_result", "backdoor_listing_result", "backdoor_milestone_state", "ceo_change_result"]:
		if typeof(company_profile.get(key, {})) == TYPE_DICTIONARY and not company_profile.get(key, {}).is_empty():
			score += 0.18
	if not runtime.get("active_events", []).is_empty():
		score += 0.12
	return clamp(score, 0.0, 1.0)


func _days_since_recent_event(run_state, day_number: int, predicate: Callable) -> int:
	var days_since: int = NO_RECENT_EVENT_DAYS
	for history_value in run_state.get_event_history():
		if typeof(history_value) != TYPE_DICTIONARY:
			continue
		var history_entry: Dictionary = history_value
		if not predicate.call(history_entry):
			continue
		var event_day: int = int(history_entry.get("day_index", day_number))
		if event_day > day_number:
			continue
		days_since = min(days_since, max(day_number - event_day, 0))
	return days_since


func _is_attention_beat(event_value: Variant) -> bool:
	return _is_headline_event(event_value) or _is_company_signal_event(event_value)


func _is_headline_event(event_value: Variant) -> bool:
	if typeof(event_value) != TYPE_DICTIONARY:
		return false
	var event_data: Dictionary = event_value
	var event_family: String = str(event_data.get("event_family", ""))
	var scope: String = str(event_data.get("scope", ""))
	var category: String = str(event_data.get("category", ""))
	if _is_policy_parody_event(event_data):
		return false
	return (
		_is_special_macro_event(event_data) or
		event_family in ["corporate_action", "index_review"] or
		category in ["corporate_action", "index_review"] or
		scope == "market"
	)


func _is_company_signal_event(event_value: Variant) -> bool:
	if typeof(event_value) != TYPE_DICTIONARY:
		return false
	var event_data: Dictionary = event_value
	var event_family: String = str(event_data.get("event_family", ""))
	return event_family in ["company_arc", "company", "person"]


func _is_special_macro_event(event_value: Variant) -> bool:
	if typeof(event_value) != TYPE_DICTIONARY:
		return false
	var event_data: Dictionary = event_value
	return (
		str(event_data.get("scope", "")) == "market" and
		str(event_data.get("event_family", "")) == "special" and
		not _is_policy_parody_event(event_data)
	)


func _is_policy_parody_event(event_value: Variant) -> bool:
	if typeof(event_value) != TYPE_DICTIONARY:
		return false
	var event_data: Dictionary = event_value
	return (
		str(event_data.get("shock_class", "")) == "policy_parody" or
		str(event_data.get("category", "")).begins_with("policy_") or
		str(event_data.get("event_id", "")).begins_with("policy_")
	)
