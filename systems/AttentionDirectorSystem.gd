extends RefCounted

const PLAYER_FACING_DAY_SIX_TRIGGER_DAY := 5
const HEADLINE_DIGESTION_DAYS := 1
const QUIET_DAYS_BEFORE_CLUE := 3
const SPECIAL_EVENT_MIN_SPACING_DAYS := 18
const SPECIAL_EVENT_DUE_DAYS := 35
const NO_RECENT_EVENT_DAYS := 9999


func resolve_day(run_state, trade_date: Dictionary, day_number: int, macro_state: Dictionary) -> Dictionary:
	var _resolved_trade_date: Dictionary = trade_date
	var _resolved_macro_state: Dictionary = macro_state
	var days_since_special_macro: int = _days_since_recent_event(run_state, day_number, Callable(self, "_is_special_macro_event"))
	var days_since_headline: int = _days_since_recent_event(run_state, day_number, Callable(self, "_is_headline_event"))
	var days_since_attention_beat: int = _days_since_recent_event(run_state, day_number, Callable(self, "_is_attention_beat"))
	var special_event_started: bool = days_since_special_macro < NO_RECENT_EVENT_DAYS
	var force_special_event: bool = day_number == PLAYER_FACING_DAY_SIX_TRIGGER_DAY and not special_event_started
	var headline_digesting: bool = days_since_headline <= HEADLINE_DIGESTION_DAYS
	var macro_cooling_down: bool = (
		special_event_started and
		days_since_special_macro < SPECIAL_EVENT_MIN_SPACING_DAYS and
		not force_special_event
	)
	var quiet_pressure: bool = (
		day_number > PLAYER_FACING_DAY_SIX_TRIGGER_DAY and
		not headline_digesting and
		days_since_attention_beat >= QUIET_DAYS_BEFORE_CLUE
	)
	if force_special_event:
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
			days_since_special_macro
		)

	if day_number < PLAYER_FACING_DAY_SIX_TRIGGER_DAY:
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
			days_since_special_macro
		)

	if headline_digesting:
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
			days_since_special_macro
		)

	if quiet_pressure:
		return _build_directives(
			false,
			macro_cooling_down,
			0.0 if macro_cooling_down else _special_event_multiplier(days_since_special_macro),
			false,
			true,
			2.2,
			false,
			1.35,
			"clue_due",
			"quiet_stretch_clue_due",
			days_since_headline,
			days_since_attention_beat,
			days_since_special_macro
		)

	return _build_directives(
		false,
		macro_cooling_down,
		0.0 if macro_cooling_down else _special_event_multiplier(days_since_special_macro),
		false,
		false,
		1.0,
		false,
		1.0,
		"normal",
		"special_cooldown" if macro_cooling_down else ("special_due" if days_since_special_macro >= SPECIAL_EVENT_DUE_DAYS else "normal"),
		days_since_headline,
		days_since_attention_beat,
		days_since_special_macro
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
	days_since_special_macro: int
) -> Dictionary:
	return {
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
		"days_since_special_macro": days_since_special_macro
	}


func _special_event_multiplier(days_since_special_macro: int) -> float:
	if days_since_special_macro >= SPECIAL_EVENT_DUE_DAYS:
		return 2.0
	if days_since_special_macro >= SPECIAL_EVENT_MIN_SPACING_DAYS:
		return 1.15
	if days_since_special_macro >= NO_RECENT_EVENT_DAYS:
		return 1.0
	return 0.0


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
		str(event_data.get("event_family", "")) == "special"
	)
