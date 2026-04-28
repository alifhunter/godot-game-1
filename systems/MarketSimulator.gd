extends RefCounted

const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")

var company_event_system = preload("res://systems/CompanyEventSystem.gd").new()
var person_event_system = preload("res://systems/PersonEventSystem.gd").new()
var special_event_system = preload("res://systems/SpecialEventSystem.gd").new()


func simulate_day(run_state, data_repository, broker_flow_system, corporate_action_system) -> Dictionary:
	var day_number: int = int(run_state.day_index) + 1
	var trade_date: Dictionary = run_state.get_current_trade_date()
	var macro_state: Dictionary = run_state.get_current_macro_state()
	var difficulty_config: Dictionary = run_state.get_difficulty_config()
	var report_events: Array = run_state.get_quarterly_report_events_for_day_number(day_number, trade_date)
	var corporate_action_resolution: Dictionary = corporate_action_system.resolve_day(
		run_state,
		data_repository,
		trade_date,
		day_number,
		macro_state,
		report_events
	)
	var company_arc_resolution: Dictionary = company_event_system.resolve_day(
		run_state,
		trade_date,
		day_number,
		macro_state
	)
	var active_company_arcs: Array = company_arc_resolution.get("active_arcs", []).duplicate(true)
	active_company_arcs.append_array(corporate_action_resolution.get("active_company_arcs", []).duplicate(true))
	var special_event_resolution: Dictionary = special_event_system.resolve_day(
		run_state,
		trade_date,
		day_number,
		macro_state
	)
	var active_special_events: Array = special_event_resolution.get("active_events", []).duplicate(true)
	var combined_market_volatility: float = (
		float(macro_state.get("volatility_multiplier", 1.0)) *
		float(special_event_resolution.get("volatility_multiplier", 1.0))
	)
	var base_market_sentiment: float = _sample_market_sentiment(
		run_state.run_seed,
		day_number,
		float(difficulty_config.get("market_swing_range", 0.02)) * combined_market_volatility
	)
	var market_sentiment: float = clamp(
		base_market_sentiment +
		float(macro_state.get("market_bias", 0.0)) +
		float(special_event_resolution.get("market_bias_shift", 0.0)),
		-float(difficulty_config.get("daily_move_cap", 0.12)),
		float(difficulty_config.get("daily_move_cap", 0.12))
	)
	var sector_sentiments: Dictionary = _build_sector_sentiments(
		data_repository.get_sector_definitions(),
		run_state.run_seed,
		day_number,
		market_sentiment,
		float(difficulty_config.get("volatility_multiplier", 1.0)),
		_merge_sector_biases(
			macro_state.get("sector_biases", {}),
			special_event_resolution.get("sector_biases", {})
		)
	)
	var scheduled_event: Dictionary = _build_daily_event_plan(
		run_state,
		trade_date,
		sector_sentiments,
		market_sentiment,
		day_number,
		difficulty_config,
		macro_state
	)
	var companies_result: Dictionary = {}

	for company_id_value in run_state.company_order:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = run_state.get_effective_company_definition(company_id)
		if definition.is_empty():
			continue
		var runtime: Dictionary = run_state.get_company(company_id).duplicate(true)
		var sector_definition: Dictionary = data_repository.get_sector_definition(str(definition.get("sector_id", "")))
		var listing_board: String = str(definition.get("listing_board", "main"))
		var recent_momentum: float = _recent_momentum(runtime.get("price_history", []))
		var sector_sentiment: float = float(sector_sentiments.get(str(sector_definition.get("id", "")), 0.0))
		var previous_close: float = IDX_PRICE_RULES.normalize_last_price(float(runtime.get("current_price", definition.get("base_price", 0.0))))
		var ar_limits: Dictionary = IDX_PRICE_RULES.auto_rejection_limits(previous_close, listing_board)
		var player_flow_context: Dictionary = _build_player_flow_impact_context(
			definition,
			runtime,
			run_state.get_player_market_flow_context(company_id, day_number)
		)
		var event_context: Dictionary = _resolve_event_context(
			definition,
			runtime,
			sector_definition,
			scheduled_event,
			report_events,
			active_special_events,
			active_company_arcs
		)
		var market_depth_context: Dictionary = _build_market_depth_context(
			definition,
			runtime,
			recent_momentum,
			market_sentiment,
			sector_sentiment,
			event_context,
			difficulty_config,
			run_state.run_seed,
			day_number,
			company_id
		)
		player_flow_context = _resolve_player_market_impact_context(
			player_flow_context,
			market_depth_context,
			previous_close,
			ar_limits
		)

		var broker_context: Dictionary = {
			"run_seed": run_state.run_seed,
			"day_index": day_number,
			"company_id": company_id,
			"market_sentiment": market_sentiment,
			"sector_sentiment": sector_sentiment,
			"recent_momentum": recent_momentum,
			"event_bias": float(event_context.get("event_bias", 0.0)),
			"player_flow": player_flow_context.duplicate(true)
		}
		var broker_flow: Dictionary = broker_flow_system.generate_day_flow(
			definition,
			runtime,
			broker_context,
			data_repository
		)
		var volume_context: Dictionary = _build_volume_activity_context(
			definition,
			runtime,
			recent_momentum,
			market_sentiment,
			sector_sentiment,
			event_context,
			broker_flow,
			run_state.run_seed,
			day_number,
			company_id
		)
		var daily_change_pct: float = _calculate_daily_change(
			definition,
			sector_definition,
			recent_momentum,
			market_sentiment,
			sector_sentiment,
			float(event_context.get("event_bias", 0.0)),
			float(broker_flow.get("net_pressure", 0.0)),
			volume_context,
			run_state.run_seed,
			day_number,
			company_id,
			difficulty_config,
			float(event_context.get("event_volatility_multiplier", 1.0))
		)
		var raw_price: float = previous_close * (1.0 + daily_change_pct)
		var close_context: Dictionary = _resolve_day_close_context(
			raw_price,
			previous_close,
			ar_limits,
			str(sector_definition.get("id", "")),
			active_special_events,
			day_number,
			run_state.run_seed,
			company_id,
			player_flow_context
		)
		var current_price: float = float(close_context.get("close_price", previous_close))
		daily_change_pct = 0.0
		if not is_zero_approx(previous_close):
			daily_change_pct = (current_price - previous_close) / previous_close
		volume_context["market_depth_context"] = market_depth_context.duplicate(true)
		volume_context["limit_lock"] = str(close_context.get("limit_lock", ""))
		volume_context["limit_source"] = str(close_context.get("limit_source", ""))
		volume_context["impact_side"] = str(player_flow_context.get("impact_side", "neutral"))
		volume_context["player_depth_impact_ratio"] = float(player_flow_context.get("depth_impact_ratio", 0.0))
		var price_history: Array = runtime.get("price_history", []).duplicate()
		price_history.append(current_price)
		var price_bars: Array = runtime.get("price_bars", []).duplicate(true)
		var daily_price_bar: Dictionary = _build_daily_price_bar(
			definition,
			previous_close,
			current_price,
			daily_change_pct,
			market_sentiment,
			sector_sentiment,
			float(event_context.get("event_bias", 0.0)),
			broker_flow,
			volume_context,
			run_state.run_seed,
			day_number,
			company_id,
			ar_limits,
			trade_date,
			close_context,
			player_flow_context,
			market_depth_context
		)
		price_bars.append(daily_price_bar)
		broker_flow = broker_flow_system.finalize_day_flow(
			definition,
			runtime,
			broker_context,
			broker_flow,
			daily_price_bar,
			current_price,
			data_repository
		)

		runtime["previous_close"] = previous_close
		runtime["current_price"] = current_price
		runtime["price_history"] = price_history
		runtime["price_bars"] = price_bars
		runtime["sentiment"] = daily_change_pct
		runtime["active_event_tags"] = event_context.get("event_tags", []).duplicate()
		runtime["active_events"] = event_context.get("active_events", []).duplicate(true)
		runtime["hidden_story_flags"] = event_context.get("hidden_story_flags", []).duplicate()
		runtime["broker_flow"] = broker_flow
		runtime["daily_change_pct"] = daily_change_pct
		runtime["ar_limits"] = ar_limits.duplicate(true)
		runtime["volume_context"] = volume_context.duplicate(true)
		runtime["market_depth_context"] = market_depth_context.duplicate(true)
		runtime["player_market_impact"] = _build_player_market_impact_snapshot(player_flow_context, close_context)

		companies_result[company_id] = runtime

	return {
		"day_number": day_number,
		"market_sentiment": market_sentiment,
		"companies": companies_result,
		"starting_equity": run_state.get_total_equity(),
		"scheduled_event": scheduled_event.duplicate(true),
		"report_events": report_events.duplicate(true),
		"started_company_arcs": company_arc_resolution.get("started_events", []).duplicate(true),
		"company_arc_phase_events": company_arc_resolution.get("phase_events", []).duplicate(true),
		"corporate_action_events": corporate_action_resolution.get("corporate_action_events", []).duplicate(true),
		"active_company_arcs": active_company_arcs,
		"started_special_events": special_event_resolution.get("started_events", []).duplicate(true),
		"active_special_events": active_special_events,
		"active_corporate_action_chains": corporate_action_resolution.get("active_corporate_action_chains", {}).duplicate(true),
		"corporate_meeting_calendar": corporate_action_resolution.get("corporate_meeting_calendar", {}).duplicate(true),
		"corporate_action_intel": corporate_action_resolution.get("corporate_action_intel", {}).duplicate(true),
		"corporate_dividend_calendar": corporate_action_resolution.get("corporate_dividend_calendar", {}).duplicate(true),
		"dividend_payments": corporate_action_resolution.get("dividend_payments", []).duplicate(true),
		"attended_meetings": corporate_action_resolution.get("attended_meetings", {}).duplicate(true),
		"corporate_meeting_sessions": corporate_action_resolution.get("corporate_meeting_sessions", {}).duplicate(true),
		"macro_state": macro_state.duplicate(true),
		"trade_date": trade_date.duplicate(true)
	}


func _resolve_day_close_price(
	raw_price: float,
	previous_close: float,
	ar_limits: Dictionary,
	sector_id: String,
	active_special_events: Array,
	day_number: int,
	run_seed: int,
	company_id: String
) -> float:
	var scripted_price: float = _resolve_special_price_override(
		previous_close,
		ar_limits,
		sector_id,
		active_special_events,
		day_number,
		run_seed,
		company_id
	)
	if scripted_price > 0.0:
		return scripted_price

	var current_price: float = IDX_PRICE_RULES.snap_price_for_day(raw_price, previous_close)
	return clamp(
		current_price,
		float(ar_limits.get("lower_price", 1.0)),
		float(ar_limits.get("upper_price", current_price))
	)


func _resolve_day_close_context(
	raw_price: float,
	previous_close: float,
	ar_limits: Dictionary,
	sector_id: String,
	active_special_events: Array,
	day_number: int,
	run_seed: int,
	company_id: String,
	player_flow_context: Dictionary
) -> Dictionary:
	var scripted_price: float = _resolve_special_price_override(
		previous_close,
		ar_limits,
		sector_id,
		active_special_events,
		day_number,
		run_seed,
		company_id
	)
	if scripted_price > 0.0:
		var scripted_lock: String = _limit_lock_for_price(scripted_price, ar_limits)
		return {
			"close_price": scripted_price,
			"limit_lock": scripted_lock,
			"limit_source": "scripted_event" if not scripted_lock.is_empty() else "",
			"scripted_override": true
		}

	var player_limit_lock: String = str(player_flow_context.get("limit_lock", ""))
	if player_limit_lock == "ara":
		return {
			"close_price": float(ar_limits.get("upper_price", previous_close)),
			"limit_lock": "ara",
			"limit_source": "player_market_impact",
			"scripted_override": false
		}
	if player_limit_lock == "arb":
		return {
			"close_price": float(ar_limits.get("lower_price", previous_close)),
			"limit_lock": "arb",
			"limit_source": "player_market_impact",
			"scripted_override": false
		}

	var adjusted_raw_price: float = raw_price * (1.0 + float(player_flow_context.get("depth_price_bias", 0.0)))
	var current_price: float = IDX_PRICE_RULES.snap_price_for_day(adjusted_raw_price, previous_close)
	current_price = clamp(
		current_price,
		float(ar_limits.get("lower_price", 1.0)),
		float(ar_limits.get("upper_price", current_price))
	)
	return {
		"close_price": current_price,
		"limit_lock": _limit_lock_for_price(current_price, ar_limits),
		"limit_source": "",
		"scripted_override": false
	}


func _limit_lock_for_price(price: float, ar_limits: Dictionary) -> String:
	var upper_price: float = float(ar_limits.get("upper_price", price))
	var lower_price: float = float(ar_limits.get("lower_price", price))
	if price >= upper_price - 0.0001:
		return "ara"
	if price <= lower_price + 0.0001:
		return "arb"
	return ""


func _resolve_special_price_override(
	previous_close: float,
	ar_limits: Dictionary,
	sector_id: String,
	active_special_events: Array,
	day_number: int,
	run_seed: int,
	company_id: String
) -> float:
	for special_event_value in active_special_events:
		var special_event: Dictionary = special_event_value
		var shock_profile: Dictionary = special_event.get("shock_profile", {}).duplicate(true)
		if shock_profile.is_empty():
			continue
		if not _special_shock_applies_to_sector(sector_id, special_event, shock_profile):
			continue

		var elapsed_days: int = day_number - int(special_event.get("start_day_index", day_number)) + 1
		var shock_days: int = max(int(shock_profile.get("shock_days", 0)), 0)
		if elapsed_days <= shock_days:
			return _price_for_limit_script(previous_close, ar_limits, shock_profile)

		if str(shock_profile.get("post_shock_mode", "")) == "sideways":
			return _price_for_sideways_script(
				previous_close,
				ar_limits,
				run_seed,
				day_number,
				company_id,
				special_event,
				shock_profile
			)

	return 0.0


func _special_shock_applies_to_sector(sector_id: String, special_event: Dictionary, shock_profile: Dictionary) -> bool:
	var sector_biases: Dictionary = special_event.get("sector_biases", {})
	if not sector_biases.has(sector_id):
		return false

	var bias_value: float = float(sector_biases.get(sector_id, 0.0))
	var apply_bias_sign: String = str(shock_profile.get("apply_bias_sign", "all"))
	if apply_bias_sign == "negative":
		return bias_value < 0.0
	if apply_bias_sign == "positive":
		return bias_value > 0.0
	return not is_zero_approx(bias_value)


func _price_for_limit_script(previous_close: float, ar_limits: Dictionary, shock_profile: Dictionary) -> float:
	var limit_side: String = str(shock_profile.get("limit_side", "lower"))
	var limit_ratio: float = clamp(float(shock_profile.get("limit_ratio", 1.0)), 0.0, 1.0)
	if limit_side == "upper":
		var upper_price: float = float(ar_limits.get("upper_price", previous_close))
		if limit_ratio >= 0.999:
			return upper_price
		var upper_raw_target: float = previous_close + ((upper_price - previous_close) * limit_ratio)
		return min(upper_price, IDX_PRICE_RULES.snap_down_to_tick_for_day(upper_raw_target, previous_close))

	var lower_price: float = float(ar_limits.get("lower_price", previous_close))
	if limit_ratio >= 0.999:
		return lower_price
	var lower_raw_target: float = previous_close - ((previous_close - lower_price) * limit_ratio)
	return max(lower_price, IDX_PRICE_RULES.snap_up_to_tick_for_day(lower_raw_target, previous_close))


func _price_for_sideways_script(
	previous_close: float,
	ar_limits: Dictionary,
	run_seed: int,
	day_number: int,
	company_id: String,
	special_event: Dictionary,
	shock_profile: Dictionary
) -> float:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|sideways|%s|%s|%s" % [
		run_seed,
		str(special_event.get("event_id", "")),
		company_id,
		day_number
	]))
	var band_ratio: float = clamp(float(shock_profile.get("sideways_band_ratio", 0.1)), 0.02, 0.2)
	var upper_distance: float = max(float(ar_limits.get("upper_price", previous_close)) - previous_close, 0.0) * band_ratio
	var lower_distance: float = max(previous_close - float(ar_limits.get("lower_price", previous_close)), 0.0) * band_ratio
	var sideways_raw: float = previous_close + rng.randf_range(-lower_distance, upper_distance)
	var sideways_price: float = IDX_PRICE_RULES.snap_price_for_day(sideways_raw, previous_close)
	return clamp(
		sideways_price,
		float(ar_limits.get("lower_price", 1.0)),
		float(ar_limits.get("upper_price", sideways_price))
	)


func _sample_market_sentiment(run_seed: int, day_number: int, swing_range: float) -> float:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|market|%s" % [run_seed, day_number]))
	return rng.randf_range(-swing_range, swing_range)


func _build_sector_sentiments(
	sectors: Array,
	run_seed: int,
	day_number: int,
	market_sentiment: float,
	volatility_multiplier: float,
	macro_sector_biases: Dictionary = {}
) -> Dictionary:
	var sector_sentiments: Dictionary = {}

	for sector in sectors:
		var sector_id: String = str(sector.get("id", ""))
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = int(hash("%s|sector|%s|%s" % [run_seed, day_number, sector_id]))
		var trend_bias: float = float(sector.get("trend_bias", 0.0))
		var macro_bias: float = float(macro_sector_biases.get(sector_id, 0.0))
		var volatility_bias: float = float(sector.get("volatility_bias", 0.0)) * volatility_multiplier
		sector_sentiments[sector_id] = market_sentiment + trend_bias + macro_bias + rng.randf_range(-volatility_bias, volatility_bias)

	return sector_sentiments


func _merge_sector_biases(primary_biases: Dictionary, additive_biases: Dictionary) -> Dictionary:
	var merged_biases: Dictionary = primary_biases.duplicate(true)
	for sector_id_value in additive_biases.keys():
		var sector_id: String = str(sector_id_value)
		merged_biases[sector_id] = float(merged_biases.get(sector_id, 0.0)) + float(additive_biases.get(sector_id, 0.0))
	return merged_biases


func _build_daily_event_plan(
	run_state,
	trade_date: Dictionary,
	sector_sentiments: Dictionary,
	market_sentiment: float,
	day_number: int,
	difficulty_config: Dictionary,
	macro_state: Dictionary = {}
) -> Dictionary:
	var event_interval_days: float = max(float(difficulty_config.get("event_interval_days", 30.0)), 1.0)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|daily_event|%s" % [run_state.run_seed, day_number]))

	if rng.randf() >= (1.0 / event_interval_days):
		return {}

	var candidates: Array = []
	var macro_market_bias: float = float(macro_state.get("market_bias", 0.0))
	var policy_action_bps: int = int(macro_state.get("policy_action_bps", 0))
	if market_sentiment < -0.015:
		candidates.append({
			"event_id": "risk_off_headline",
			"scope": "market",
			"weight": 1.0 + clamp(abs(market_sentiment) * 8.0, 0.0, 0.45) + clamp(abs(macro_market_bias) * 10.0, 0.0, 0.35)
		})
	elif macro_market_bias < -0.008 and policy_action_bps > 0:
		candidates.append({
			"event_id": "risk_off_headline",
			"scope": "market",
			"weight": 0.75 + clamp(abs(macro_market_bias) * 8.0, 0.0, 0.3)
		})

	var strongest_sector: Dictionary = _strongest_sector_signal(sector_sentiments)
	if not strongest_sector.is_empty():
		var strongest_sector_sentiment: float = float(strongest_sector.get("sentiment", 0.0))
		if strongest_sector_sentiment > 0.02:
			candidates.append({
				"event_id": "sector_tailwind",
				"scope": "sector",
				"target_sector_id": str(strongest_sector.get("sector_id", "")),
				"weight": 0.8 + clamp(strongest_sector_sentiment * 6.0, 0.0, 0.35)
			})
		elif strongest_sector_sentiment < -0.012:
			candidates.append({
				"event_id": "sector_headwind",
				"scope": "sector",
				"target_sector_id": str(strongest_sector.get("sector_id", "")),
				"weight": 0.95 + clamp(abs(strongest_sector_sentiment) * 7.0, 0.0, 0.4)
			})

	candidates.append_array(
		company_event_system.build_company_event_candidates(run_state, trade_date, day_number, macro_state)
	)
	candidates.append_array(
		person_event_system.build_person_event_candidates(
			run_state,
			trade_date,
			day_number,
			macro_state,
			sector_sentiments,
			market_sentiment
		)
	)

	if candidates.is_empty():
		return {}

	return _pick_weighted_candidate(rng, candidates)


func _strongest_sector_signal(sector_sentiments: Dictionary) -> Dictionary:
	var strongest_sector_id: String = ""
	var strongest_magnitude: float = -1.0

	for sector_id in sector_sentiments.keys():
		var sentiment_value: float = abs(float(sector_sentiments[sector_id]))
		if sentiment_value > strongest_magnitude:
			strongest_magnitude = sentiment_value
			strongest_sector_id = str(sector_id)

	if strongest_sector_id.is_empty():
		return {}

	return {
		"sector_id": strongest_sector_id,
		"sentiment": float(sector_sentiments[strongest_sector_id])
	}


func _resolve_event_context(
	definition: Dictionary,
	runtime: Dictionary,
	sector_definition: Dictionary,
	scheduled_event: Dictionary,
	report_events: Array = [],
	active_special_events: Array = [],
	active_company_arcs: Array = []
) -> Dictionary:
	var event_tags: Array = []
	var active_events: Array = []
	var hidden_story_flags: Array = runtime.get("hidden_story_flags", []).duplicate()
	var event_bias: float = 0.0
	var event_volatility_multiplier: float = 1.0
	var company_id: String = str(definition.get("id", ""))
	var sector_id: String = str(sector_definition.get("id", ""))

	event_bias = _append_event_if_applicable(
		scheduled_event,
		company_id,
		sector_id,
		event_tags,
		active_events,
		event_bias
	)
	for report_event_value in report_events:
		var report_event: Dictionary = report_event_value
		event_bias = _append_event_if_applicable(
			report_event,
			company_id,
			sector_id,
			event_tags,
			active_events,
			event_bias
		)
	for special_event_value in active_special_events:
		event_bias = _append_event_if_applicable(
			special_event_value,
			company_id,
			sector_id,
			event_tags,
			active_events,
			event_bias
		)
	for company_arc_value in active_company_arcs:
		var company_arc: Dictionary = company_arc_value
		if not _event_applies_to_company(company_arc, company_id, sector_id):
			continue

		event_bias += float(company_arc.get("phase_sentiment_shift", 0.0))
		event_volatility_multiplier *= float(company_arc.get("phase_volatility_multiplier", 1.0))
		var phase_visibility: String = str(company_arc.get("phase_visibility", "visible"))
		if phase_visibility == "hidden":
			var hidden_flag: String = str(company_arc.get("phase_hidden_flag", ""))
			if not hidden_flag.is_empty() and not hidden_story_flags.has(hidden_flag):
				hidden_story_flags.append(hidden_flag)
			continue

		var visible_arc: Dictionary = company_arc.duplicate(true)
		visible_arc["sentiment_shift"] = float(company_arc.get("phase_sentiment_shift", 0.0))
		event_bias = _append_event_if_applicable(
			visible_arc,
			company_id,
			sector_id,
			event_tags,
			active_events,
			event_bias - float(company_arc.get("phase_sentiment_shift", 0.0))
		)

	return {
		"event_tags": event_tags,
		"active_events": active_events,
		"event_bias": event_bias,
		"event_volatility_multiplier": clamp(event_volatility_multiplier, 0.55, 2.1),
		"hidden_story_flags": hidden_story_flags,
		"sector_id": str(sector_definition.get("id", ""))
	}


func _append_event_if_applicable(
	event_data: Dictionary,
	company_id: String,
	sector_id: String,
	event_tags: Array,
	active_events: Array,
	running_event_bias: float
) -> float:
	if not _event_applies_to_company(event_data, company_id, sector_id):
		return running_event_bias

	var event_id: String = str(event_data.get("event_id", ""))
	if event_id.is_empty():
		return running_event_bias

	event_tags.append(event_id)
	active_events.append(event_data.duplicate(true))
	var event_definition: Dictionary = DataRepository.get_event_definition(event_id)
	return running_event_bias + float(event_data.get("sentiment_shift", event_definition.get("sentiment_shift", 0.0)))


func _event_applies_to_company(scheduled_event: Dictionary, company_id: String, sector_id: String) -> bool:
	if scheduled_event.is_empty():
		return false

	var scope: String = str(scheduled_event.get("scope", "company"))
	if scope == "market":
		return true
	if scope == "sector":
		var target_sector_id: String = str(scheduled_event.get("target_sector_id", ""))
		if not target_sector_id.is_empty():
			return target_sector_id == sector_id
		return sector_id in scheduled_event.get("affected_sector_ids", [])
	return str(scheduled_event.get("target_company_id", "")) == company_id


func _build_player_flow_impact_context(definition: Dictionary, runtime: Dictionary, player_flow: Dictionary) -> Dictionary:
	var enriched_flow: Dictionary = player_flow.duplicate(true)
	var current_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var financials: Dictionary = definition.get("financials", {})
	var market_cap: float = max(float(financials.get("market_cap", current_price * 1000000000.0)), current_price * 1000000.0)
	var free_float_ratio: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, 0.07, 0.85)
	var avg_daily_value: float = max(float(financials.get("avg_daily_value", current_price * 250000.0)), current_price * 1000.0)
	var estimated_float_value: float = max(market_cap * free_float_ratio * 0.0022, current_price * 1000.0)
	var impact_baseline_value: float = max(lerp(avg_daily_value, estimated_float_value, 0.42), current_price * 1000.0)
	var net_value: float = float(enriched_flow.get("net_value", 0.0))
	var gross_value: float = max(absf(float(enriched_flow.get("buy_value", 0.0))) + absf(float(enriched_flow.get("sell_value", 0.0))), absf(net_value))
	enriched_flow["impact_baseline_value"] = impact_baseline_value
	enriched_flow["impact_ratio"] = clamp(net_value / impact_baseline_value, -3.0, 3.0)
	enriched_flow["gross_impact_ratio"] = clamp(gross_value / impact_baseline_value, 0.0, 6.0)
	return enriched_flow


func _build_market_depth_context(
	definition: Dictionary,
	runtime: Dictionary,
	recent_momentum: float,
	market_sentiment: float,
	sector_sentiment: float,
	event_context: Dictionary,
	difficulty_config: Dictionary,
	run_seed: int,
	day_number: int,
	company_id: String
) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|depth|%s|%s" % [run_seed, day_number, company_id]))

	var financials: Dictionary = definition.get("financials", {})
	var traits: Dictionary = definition.get("generation_traits", {})
	var current_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var market_cap: float = max(float(financials.get("market_cap", current_price * 1000000000.0)), current_price * 1000000.0)
	var shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", market_cap / current_price))), 1.0)
	var free_float_ratio: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, 0.07, 0.85)
	var free_float_shares: float = max(shares_outstanding * free_float_ratio, 1.0)
	var free_float_value: float = max(free_float_shares * current_price, current_price * 1000.0)
	var avg_daily_value: float = max(float(financials.get("avg_daily_value", current_price * 250000.0)), current_price * 1000.0)
	var liquidity_profile: float = clamp(float(traits.get("liquidity_profile", 0.5)), 0.0, 1.0)
	var story_heat: float = clamp(float(traits.get("story_heat", 0.5)), 0.0, 1.0)
	var base_volatility: float = max(float(definition.get("base_volatility", 0.025)), 0.004)
	var event_intensity: float = min(absf(float(event_context.get("event_bias", 0.0))) * 7.0, 1.35)
	var volatility_multiplier: float = clamp(float(difficulty_config.get("volatility_multiplier", 1.0)), 0.55, 1.85)
	var float_tightness: float = clamp((0.48 - free_float_ratio) / 0.40, 0.0, 1.0)
	var sentiment_bias: float = clamp(
		market_sentiment * 2.2 +
		sector_sentiment * 2.4 +
		recent_momentum * 4.0 +
		float(event_context.get("event_bias", 0.0)) * 5.0,
		-1.0,
		1.0
	)

	var turnover_rate: float = clamp(
		0.00042 +
		(liquidity_profile * 0.0036) +
		(story_heat * 0.0015) +
		(free_float_ratio * 0.0010) +
		(base_volatility * 0.018),
		0.00035,
		0.0105
	)
	var synthetic_daily_value: float = max(
		lerp(avg_daily_value, free_float_value * turnover_rate, 0.54),
		current_price * 1000.0
	)
	synthetic_daily_value *= clamp(
		(1.0 + story_heat * 0.22 + event_intensity * 0.62) *
		volatility_multiplier *
		rng.randf_range(0.86, 1.18),
		0.55,
		2.85
	)

	var depth_quality: float = lerp(0.72, 1.72, liquidity_profile) * lerp(0.78, 1.18, free_float_ratio)
	var ask_sentiment_modifier: float = clamp(1.0 - max(sentiment_bias, 0.0) * 0.28 + max(-sentiment_bias, 0.0) * 0.16, 0.62, 1.35)
	var bid_sentiment_modifier: float = clamp(1.0 + max(sentiment_bias, 0.0) * 0.16 - max(-sentiment_bias, 0.0) * 0.30, 0.62, 1.35)
	var ask_depth_value: float = max(synthetic_daily_value * depth_quality * ask_sentiment_modifier, current_price * 1000.0)
	var bid_depth_value: float = max(synthetic_daily_value * depth_quality * bid_sentiment_modifier, current_price * 1000.0)
	var lock_depth_multiplier: float = lerp(2.6, 6.8, liquidity_profile) * lerp(0.78, 1.28, free_float_ratio)
	var free_float_lock_threshold: float = clamp(lerp(0.045, 0.145, liquidity_profile) + free_float_ratio * 0.04, 0.045, 0.18)

	return {
		"current_price": current_price,
		"market_cap": market_cap,
		"shares_outstanding": shares_outstanding,
		"free_float_ratio": free_float_ratio,
		"free_float_shares": free_float_shares,
		"free_float_value": free_float_value,
		"avg_daily_value": avg_daily_value,
		"synthetic_daily_value": synthetic_daily_value,
		"ask_depth_value": ask_depth_value,
		"bid_depth_value": bid_depth_value,
		"ask_depth_shares": ask_depth_value / current_price,
		"bid_depth_shares": bid_depth_value / current_price,
		"ask_resistance": clamp(ask_depth_value / max(synthetic_daily_value, 1.0), 0.0, 12.0),
		"bid_resistance": clamp(bid_depth_value / max(synthetic_daily_value, 1.0), 0.0, 12.0),
		"lock_depth_multiplier": lock_depth_multiplier,
		"free_float_lock_threshold": free_float_lock_threshold,
		"liquidity_profile": liquidity_profile,
		"story_heat": story_heat,
		"float_tightness": float_tightness,
		"sentiment_bias": sentiment_bias,
		"event_intensity": event_intensity
	}


func _resolve_player_market_impact_context(
	player_flow: Dictionary,
	market_depth_context: Dictionary,
	previous_close: float,
	ar_limits: Dictionary
) -> Dictionary:
	var resolved_flow: Dictionary = player_flow.duplicate(true)
	var buy_value: float = max(float(resolved_flow.get("buy_value", 0.0)), 0.0)
	var sell_value: float = max(float(resolved_flow.get("sell_value", 0.0)), 0.0)
	var buy_shares: float = max(float(resolved_flow.get("buy_shares", 0.0)), 0.0)
	var sell_shares: float = max(float(resolved_flow.get("sell_shares", 0.0)), 0.0)
	var net_value: float = buy_value - sell_value
	var gross_value: float = buy_value + sell_value
	var ask_depth_value: float = max(float(market_depth_context.get("ask_depth_value", 1.0)), 1.0)
	var bid_depth_value: float = max(float(market_depth_context.get("bid_depth_value", 1.0)), 1.0)
	var free_float_shares: float = max(float(market_depth_context.get("free_float_shares", 1.0)), 1.0)
	var free_float_value: float = max(float(market_depth_context.get("free_float_value", 1.0)), 1.0)
	var buy_liquidity_consumed: float = buy_value / ask_depth_value
	var sell_liquidity_consumed: float = sell_value / bid_depth_value
	var buy_free_float_pct: float = buy_shares / free_float_shares
	var sell_free_float_pct: float = sell_shares / free_float_shares
	var gross_free_float_pct: float = (buy_shares + sell_shares) / free_float_shares
	var net_free_float_pct: float = (buy_shares - sell_shares) / free_float_shares
	var lock_depth_multiplier: float = max(float(market_depth_context.get("lock_depth_multiplier", 4.0)), 0.5)
	var free_float_lock_threshold: float = max(float(market_depth_context.get("free_float_lock_threshold", 0.08)), 0.01)

	var limit_lock: String = ""
	var impact_side: String = "neutral"
	var side_depth_ratio: float = 0.0
	var side_free_float_pct: float = 0.0
	if net_value > 0.0:
		impact_side = "buy"
		side_depth_ratio = buy_liquidity_consumed
		side_free_float_pct = buy_free_float_pct
		if buy_liquidity_consumed >= lock_depth_multiplier or buy_free_float_pct >= free_float_lock_threshold:
			limit_lock = "ara"
	elif net_value < 0.0:
		impact_side = "sell"
		side_depth_ratio = sell_liquidity_consumed
		side_free_float_pct = sell_free_float_pct
		if sell_liquidity_consumed >= lock_depth_multiplier or sell_free_float_pct >= free_float_lock_threshold:
			limit_lock = "arb"

	var signed_depth_ratio: float = clamp(net_value / (ask_depth_value if net_value >= 0.0 else bid_depth_value), -8.0, 8.0)
	var signed_float_pressure: float = clamp(net_free_float_pct / max(free_float_lock_threshold, 0.01), -5.0, 5.0)
	var depth_price_bias: float = clamp(
		(signed_depth_ratio * lerp(0.004, 0.020, float(market_depth_context.get("float_tightness", 0.0)))) +
		(signed_float_pressure * 0.010),
		-0.16,
		0.16
	)
	if limit_lock == "ara":
		depth_price_bias = max(depth_price_bias, 0.12)
	elif limit_lock == "arb":
		depth_price_bias = min(depth_price_bias, -0.12)

	resolved_flow["market_depth_context"] = market_depth_context.duplicate(true)
	resolved_flow["buy_liquidity_consumed"] = buy_liquidity_consumed
	resolved_flow["sell_liquidity_consumed"] = sell_liquidity_consumed
	resolved_flow["gross_liquidity_consumed"] = gross_value / max((ask_depth_value + bid_depth_value) * 0.5, 1.0)
	resolved_flow["buy_free_float_pct"] = buy_free_float_pct
	resolved_flow["sell_free_float_pct"] = sell_free_float_pct
	resolved_flow["gross_free_float_pct"] = gross_free_float_pct
	resolved_flow["net_free_float_pct"] = net_free_float_pct
	resolved_flow["free_float_value_pct"] = gross_value / free_float_value
	resolved_flow["impact_side"] = impact_side
	resolved_flow["side_depth_ratio"] = side_depth_ratio
	resolved_flow["side_free_float_pct"] = side_free_float_pct
	resolved_flow["depth_impact_ratio"] = signed_depth_ratio
	resolved_flow["depth_price_bias"] = depth_price_bias
	resolved_flow["limit_lock"] = limit_lock
	resolved_flow["limit_source"] = "player_market_impact" if not limit_lock.is_empty() else ""
	resolved_flow["overwhelmed_liquidity"] = not limit_lock.is_empty() or absf(signed_depth_ratio) >= 1.0
	resolved_flow["limit_price"] = _player_limit_price(limit_lock, previous_close, ar_limits)
	resolved_flow["impact_summary"] = _build_player_impact_summary(resolved_flow)
	return resolved_flow


func _player_limit_price(limit_lock: String, previous_close: float, ar_limits: Dictionary) -> float:
	if limit_lock == "ara":
		return float(ar_limits.get("upper_price", previous_close))
	if limit_lock == "arb":
		return float(ar_limits.get("lower_price", previous_close))
	return 0.0


func _build_player_impact_summary(player_flow: Dictionary) -> String:
	var limit_lock: String = str(player_flow.get("limit_lock", ""))
	if limit_lock == "ara":
		return "XL buy pressure overwhelmed ask depth and locked the stock at ARA."
	if limit_lock == "arb":
		return "XL sell pressure overwhelmed bid depth and locked the stock at ARB."
	var side: String = str(player_flow.get("impact_side", "neutral"))
	if side == "buy" and float(player_flow.get("side_depth_ratio", 0.0)) >= 1.0:
		return "XL buy pressure consumed more than one day of visible ask depth."
	if side == "sell" and float(player_flow.get("side_depth_ratio", 0.0)) >= 1.0:
		return "XL sell pressure consumed more than one day of visible bid depth."
	if side == "buy" and float(player_flow.get("buy_value", 0.0)) > 0.0:
		return "XL buy pressure is visible but still within normal market depth."
	if side == "sell" and float(player_flow.get("sell_value", 0.0)) > 0.0:
		return "XL sell pressure is visible but still within normal market depth."
	return ""


func _build_player_market_impact_snapshot(player_flow_context: Dictionary, close_context: Dictionary) -> Dictionary:
	return {
		"broker_code": str(player_flow_context.get("broker_code", "")),
		"broker_name": str(player_flow_context.get("broker_name", "")),
		"impact_side": str(player_flow_context.get("impact_side", "neutral")),
		"buy_value": float(player_flow_context.get("buy_value", 0.0)),
		"sell_value": float(player_flow_context.get("sell_value", 0.0)),
		"net_value": float(player_flow_context.get("net_value", 0.0)),
		"depth_impact_ratio": float(player_flow_context.get("depth_impact_ratio", 0.0)),
		"buy_liquidity_consumed": float(player_flow_context.get("buy_liquidity_consumed", 0.0)),
		"sell_liquidity_consumed": float(player_flow_context.get("sell_liquidity_consumed", 0.0)),
		"buy_free_float_pct": float(player_flow_context.get("buy_free_float_pct", 0.0)),
		"sell_free_float_pct": float(player_flow_context.get("sell_free_float_pct", 0.0)),
		"net_free_float_pct": float(player_flow_context.get("net_free_float_pct", 0.0)),
		"overwhelmed_liquidity": bool(player_flow_context.get("overwhelmed_liquidity", false)),
		"limit_lock": str(close_context.get("limit_lock", player_flow_context.get("limit_lock", ""))),
		"limit_source": str(close_context.get("limit_source", player_flow_context.get("limit_source", ""))),
		"limit_price": float(player_flow_context.get("limit_price", 0.0)),
		"impact_summary": str(player_flow_context.get("impact_summary", "")),
		"scripted_override": bool(close_context.get("scripted_override", false))
	}


func _calculate_daily_change(
	definition: Dictionary,
	sector_definition: Dictionary,
	recent_momentum: float,
	market_sentiment: float,
	sector_sentiment: float,
	event_bias: float,
	broker_pressure: float,
	volume_context: Dictionary,
	run_seed: int,
	day_number: int,
	company_id: String,
	difficulty_config: Dictionary,
	event_volatility_multiplier: float = 1.0
) -> float:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|price|%s|%s" % [run_seed, day_number, company_id]))

	var quality: float = float(definition.get("quality_score", 50.0))
	var growth: float = float(definition.get("growth_score", 50.0))
	var risk: float = float(definition.get("risk_score", 50.0))
	var volatility_multiplier: float = float(difficulty_config.get("volatility_multiplier", 1.0))
	var broker_impact_multiplier: float = float(difficulty_config.get("broker_impact_multiplier", 1.0))
	var daily_move_cap: float = float(difficulty_config.get("daily_move_cap", 0.12))
	var base_volatility: float = (
		float(definition.get("base_volatility", 0.03)) +
		float(sector_definition.get("volatility_bias", 0.0))
	) * volatility_multiplier * clamp(event_volatility_multiplier, 0.55, 2.1)
	var quality_edge: float = (quality - 50.0) / 50.0
	var growth_edge: float = (growth - 50.0) / 50.0
	var risk_edge: float = (risk - 50.0) / 50.0
	var quality_drift: float = (quality_edge * 0.0032) + (growth_edge * 0.002) - (risk_edge * 0.0034) - 0.0014
	var momentum_component: float = clamp(-recent_momentum * 0.16, -0.015, 0.015)
	var noise_component: float = rng.randf_range(-base_volatility, base_volatility) * 0.65
	var daily_change: float = quality_drift
	daily_change += market_sentiment * 0.45
	daily_change += sector_sentiment * 0.55
	daily_change += event_bias * 0.8
	daily_change += broker_pressure * 0.03 * broker_impact_multiplier
	daily_change += float(volume_context.get("lead_price_bias", 0.0)) * broker_impact_multiplier
	daily_change += float(volume_context.get("buying_exhaustion_drag", 0.0))
	daily_change += float(volume_context.get("distribution_drag", 0.0))
	daily_change += momentum_component
	daily_change += noise_component

	return clamp(daily_change, -daily_move_cap, daily_move_cap)


func _recent_momentum(price_history: Array) -> float:
	if price_history.size() < 2:
		return 0.0

	var last_close: float = float(price_history[price_history.size() - 1])
	var previous_close: float = float(price_history[price_history.size() - 2])
	if is_zero_approx(previous_close):
		return 0.0

	return (last_close - previous_close) / previous_close


func _build_volume_activity_context(
	definition: Dictionary,
	runtime: Dictionary,
	recent_momentum: float,
	market_sentiment: float,
	sector_sentiment: float,
	event_context: Dictionary,
	broker_flow: Dictionary,
	run_seed: int,
	day_number: int,
	company_id: String
) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|volume_activity|%s|%s" % [run_seed, day_number, company_id]))

	var financials: Dictionary = definition.get("financials", {})
	var traits: Dictionary = definition.get("generation_traits", {})
	var current_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var market_cap: float = max(float(financials.get("market_cap", current_price * 1000000000.0)), current_price * 1000000.0)
	var free_float_ratio: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, 0.07, 0.85)
	var avg_daily_value: float = max(float(financials.get("avg_daily_value", current_price * 250000.0)), current_price * 1000.0)
	var liquidity_profile: float = clamp(float(traits.get("liquidity_profile", 0.5)), 0.0, 1.0)
	var story_heat: float = clamp(float(traits.get("story_heat", 0.5)), 0.0, 1.0)
	var narrative_tags: Array = definition.get("narrative_tags", [])
	var hidden_flags: Array = event_context.get("hidden_story_flags", runtime.get("hidden_story_flags", [])).duplicate()
	var price_bars: Array = runtime.get("price_bars", [])
	var event_bias: float = float(event_context.get("event_bias", 0.0))
	var event_volatility_multiplier: float = clamp(float(event_context.get("event_volatility_multiplier", 1.0)), 0.55, 2.1)
	var net_pressure: float = clamp(float(broker_flow.get("net_pressure", 0.0)), -1.0, 1.0)
	var smart_money_pressure: float = clamp(float(broker_flow.get("smart_money_pressure", 0.0)), -1.0, 1.0)
	var retail_pressure: float = clamp(float(broker_flow.get("retail_net", 0.0)) / 100.0, -1.0, 1.0)
	var float_tightness: float = clamp((0.48 - free_float_ratio) / 0.40, 0.0, 1.0)

	var free_float_value: float = market_cap * free_float_ratio
	var turnover_rate: float = clamp(
		0.00045 +
		(liquidity_profile * 0.0028) +
		(story_heat * 0.0013) +
		(free_float_ratio * 0.0012),
		0.00035,
		0.0085
	)
	if "retail_favorite" in narrative_tags:
		turnover_rate += 0.00035
	if "narrative_hot" in narrative_tags:
		turnover_rate += 0.00045
	if "institution_quality" in narrative_tags:
		turnover_rate += 0.00020
	turnover_rate = clamp(turnover_rate, 0.00035, 0.0095)

	var free_float_daily_value: float = max(free_float_value * turnover_rate, current_price * 1000.0)
	var quiet_float_drag: float = lerp(1.0, 0.78, float_tightness * (1.0 - liquidity_profile))
	var base_daily_value: float = max(lerp(avg_daily_value, free_float_daily_value, 0.48) * quiet_float_drag, current_price * 1000.0)
	var player_flow: Dictionary = broker_flow.get("player_flow", {})
	var player_net_value: float = float(player_flow.get("net_value", 0.0))
	var player_abs_value: float = max(absf(float(player_flow.get("buy_value", 0.0))) + absf(float(player_flow.get("sell_value", 0.0))), absf(player_net_value))
	var player_abs_ratio: float = clamp(player_abs_value / max(base_daily_value, 1.0), 0.0, 6.0)
	var player_impact_ratio: float = clamp(player_net_value / max(base_daily_value, 1.0), -3.0, 3.0)
	var depth_price_bias: float = float(player_flow.get("depth_price_bias", 0.0))
	var player_price_bias: float = clamp(
		(player_impact_ratio * lerp(0.006, 0.024, float_tightness)) + depth_price_bias,
		-0.110,
		0.110
	)
	var player_volume_multiplier: float = 1.0 + clamp(player_abs_ratio * 0.55, 0.0, 2.8)
	player_volume_multiplier += clamp(float(player_flow.get("gross_liquidity_consumed", 0.0)) * 0.18, 0.0, 2.2)

	var recent_value_average: float = _average_recent_bar_value(price_bars, 20, base_daily_value)
	var recent_short_value_average: float = _average_recent_bar_value(price_bars, 3, recent_value_average)
	var previous_value: float = _latest_bar_value(price_bars, recent_value_average)
	var previous_activity_ratio: float = previous_value / max(recent_value_average, 1.0)
	var short_activity_ratio: float = recent_short_value_average / max(recent_value_average, 1.0)
	var high_activity_streak: int = _recent_high_activity_streak(price_bars, recent_value_average, 5, 1.85)
	var recent_runup: float = max(_recent_price_change_from_bars(price_bars, 8), 0.0)
	var recent_drawdown: float = max(-_recent_price_change_from_bars(price_bars, 8), 0.0)
	var prior_activity_pressure: float = clamp(((previous_activity_ratio + short_activity_ratio) * 0.5 - 1.10) / 2.40, 0.0, 1.0)

	var has_hidden_accumulation: bool = "smart_money_accumulation" in hidden_flags
	var has_stealth_interest: bool = "stealth_interest" in hidden_flags
	var hidden_distribution: bool = "smart_money_distribution" in hidden_flags
	var retail_chase: float = clamp(
		max(retail_pressure, 0.0) * 0.42 +
		max(recent_momentum, 0.0) * 5.0 +
		story_heat * 0.22 +
		(0.16 if "retail_favorite" in narrative_tags else 0.0) +
		(0.12 if "narrative_hot" in narrative_tags else 0.0),
		0.0,
		1.0
	)
	var accumulation_signal: float = clamp(
		max(net_pressure, 0.0) * 0.25 +
		max(smart_money_pressure, 0.0) * 0.38 +
		max(event_bias, 0.0) * 5.0 +
		max(sector_sentiment, 0.0) * 1.6 +
		max(market_sentiment, 0.0) * 0.9 +
		float_tightness * 0.14 +
		(0.34 if has_hidden_accumulation else 0.0) +
		(0.16 if has_stealth_interest else 0.0) +
		max(-recent_momentum, 0.0) * 1.4,
		0.0,
		1.0
	)
	var distribution_signal: float = clamp(
		max(-smart_money_pressure, 0.0) * 0.36 +
		max(-net_pressure, 0.0) * 0.18 +
		max(-event_bias, 0.0) * 5.0 +
		max(-sector_sentiment, 0.0) * 1.6 +
		max(-market_sentiment, 0.0) * 0.9 +
		float_tightness * 0.12 +
		(0.38 if hidden_distribution else 0.0) +
		retail_chase * 0.18 +
		max(recent_momentum, 0.0) * 1.2,
		0.0,
		1.0
	)

	var lead_direction: float = 0.0
	if accumulation_signal > distribution_signal:
		lead_direction = accumulation_signal
	elif distribution_signal > accumulation_signal:
		lead_direction = -distribution_signal
	var lead_price_bias: float = clamp(prior_activity_pressure * lead_direction * 0.011, -0.012, 0.012)
	lead_price_bias = clamp(lead_price_bias + player_price_bias, -0.060, 0.060)

	var exhaustion_score: float = clamp(
		recent_runup * 4.8 +
		max(previous_activity_ratio - 1.55, 0.0) * 0.18 +
		float(high_activity_streak) * 0.12 +
		retail_chase * 0.24 +
		max(player_impact_ratio, 0.0) * 0.10 +
		float_tightness * 0.12 +
		story_heat * 0.08 +
		max(-smart_money_pressure, 0.0) * 0.22 -
		max(smart_money_pressure, 0.0) * 0.18,
		0.0,
		1.0
	)
	var exhaustion_drag: float = -exhaustion_score * lerp(0.0025, 0.0160, clamp(recent_runup * 8.0, 0.0, 1.0))
	var distribution_drag: float = -distribution_signal * prior_activity_pressure * lerp(0.0015, 0.0075, clamp(recent_runup * 7.0, 0.0, 1.0))
	distribution_drag += clamp(min(player_impact_ratio, 0.0) * lerp(0.004, 0.018, float_tightness), -0.045, 0.0)
	if recent_drawdown > 0.06 and distribution_signal < 0.35:
		distribution_drag *= 0.45

	var event_multiplier: float = 1.0 + min(absf(event_bias) * 6.0, 1.55) + max(event_volatility_multiplier - 1.0, 0.0) * 0.70
	var broker_multiplier: float = 1.0 + absf(net_pressure) * 0.50 + absf(smart_money_pressure) * 0.35
	var hidden_multiplier: float = 1.0 + (0.34 if has_hidden_accumulation else 0.0) + (0.14 if has_stealth_interest else 0.0) + (0.36 if hidden_distribution else 0.0)
	var story_multiplier: float = 1.0 + story_heat * 0.16 + float_tightness * 0.14
	var memory_multiplier: float = clamp(lerp(0.88, 1.42, clamp((short_activity_ratio - 0.65) / 2.60, 0.0, 1.0)), 0.82, 1.48)
	var exhaustion_multiplier: float = 1.0 + exhaustion_score * 0.80
	var lumpy_noise: float = _sample_lumpy_volume_noise(
		rng,
		story_heat,
		float_tightness,
		absf(event_bias),
		max(accumulation_signal, distribution_signal)
	)
	var volume_multiplier: float = clamp(
		event_multiplier *
		broker_multiplier *
		hidden_multiplier *
		story_multiplier *
		memory_multiplier *
		exhaustion_multiplier *
		player_volume_multiplier *
		lumpy_noise,
		0.30,
		8.00
	)
	var expected_activity_ratio: float = (base_daily_value * volume_multiplier) / max(recent_value_average, 1.0)

	return {
		"base_daily_value": base_daily_value,
		"volume_multiplier": volume_multiplier,
		"expected_activity_ratio": expected_activity_ratio,
		"previous_activity_ratio": previous_activity_ratio,
		"short_activity_ratio": short_activity_ratio,
		"high_activity_streak": high_activity_streak,
		"accumulation_signal": accumulation_signal,
		"distribution_signal": distribution_signal,
		"lead_price_bias": lead_price_bias,
		"buying_exhaustion_score": exhaustion_score,
		"buying_exhaustion_drag": exhaustion_drag,
		"distribution_drag": distribution_drag,
		"player_impact_ratio": player_impact_ratio,
		"player_abs_ratio": player_abs_ratio,
		"player_price_bias": player_price_bias,
		"player_depth_price_bias": depth_price_bias,
		"player_depth_impact_ratio": float(player_flow.get("depth_impact_ratio", 0.0)),
		"player_buy_liquidity_consumed": float(player_flow.get("buy_liquidity_consumed", 0.0)),
		"player_sell_liquidity_consumed": float(player_flow.get("sell_liquidity_consumed", 0.0)),
		"player_gross_free_float_pct": float(player_flow.get("gross_free_float_pct", 0.0))
	}


func _average_recent_bar_value(price_bars: Array, lookback: int, fallback_value: float) -> float:
	if price_bars.is_empty():
		return max(fallback_value, 1.0)

	var start_index: int = max(price_bars.size() - max(lookback, 1), 0)
	var total_value: float = 0.0
	var count: int = 0
	for bar_index in range(start_index, price_bars.size()):
		var bar: Dictionary = price_bars[bar_index]
		var bar_value: float = float(bar.get("value", 0.0))
		if bar_value <= 0.0:
			bar_value = float(bar.get("close", 0.0)) * float(bar.get("volume_shares", 0))
		if bar_value <= 0.0:
			continue
		total_value += bar_value
		count += 1
	if count <= 0:
		return max(fallback_value, 1.0)
	return max(total_value / float(count), 1.0)


func _latest_bar_value(price_bars: Array, fallback_value: float) -> float:
	if price_bars.is_empty():
		return max(fallback_value, 1.0)
	var latest_bar: Dictionary = price_bars[price_bars.size() - 1]
	var bar_value: float = float(latest_bar.get("value", 0.0))
	if bar_value <= 0.0:
		bar_value = float(latest_bar.get("close", 0.0)) * float(latest_bar.get("volume_shares", 0))
	if bar_value <= 0.0:
		return max(fallback_value, 1.0)
	return max(bar_value, 1.0)


func _recent_high_activity_streak(price_bars: Array, baseline_value: float, lookback: int, threshold_ratio: float) -> int:
	if price_bars.is_empty():
		return 0

	var safe_baseline: float = max(baseline_value, 1.0)
	var max_lookback: int = min(max(lookback, 1), price_bars.size())
	var streak: int = 0
	for offset in range(max_lookback):
		var bar_index: int = price_bars.size() - 1 - offset
		var bar: Dictionary = price_bars[bar_index]
		var bar_value: float = float(bar.get("value", 0.0))
		if bar_value <= 0.0:
			bar_value = float(bar.get("close", 0.0)) * float(bar.get("volume_shares", 0))
		if (bar_value / safe_baseline) < threshold_ratio:
			break
		streak += 1
	return streak


func _recent_price_change_from_bars(price_bars: Array, lookback: int) -> float:
	if price_bars.size() < 2:
		return 0.0

	var end_bar: Dictionary = price_bars[price_bars.size() - 1]
	var start_index: int = max(price_bars.size() - max(lookback, 1), 0)
	var start_bar: Dictionary = price_bars[start_index]
	var start_price: float = float(start_bar.get("open", start_bar.get("close", 0.0)))
	var end_price: float = float(end_bar.get("close", start_price))
	if is_zero_approx(start_price):
		return 0.0
	return (end_price - start_price) / start_price


func _sample_lumpy_volume_noise(
	rng: RandomNumberGenerator,
	story_heat: float,
	float_tightness: float,
	event_intensity: float,
	signal_intensity: float
) -> float:
	var base_noise: float = rng.randf_range(0.76, 1.18)
	var spike_chance: float = clamp(
		0.025 +
		story_heat * 0.060 +
		float_tightness * 0.045 +
		event_intensity * 0.240 +
		signal_intensity * 0.075,
		0.025,
		0.380
	)
	if rng.randf() < spike_chance:
		base_noise *= rng.randf_range(
			1.16,
			2.05 + story_heat * 0.45 + float_tightness * 0.35 + event_intensity * 1.20
		)
	return clamp(base_noise, 0.45, 4.80)


func _build_daily_price_bar(
	definition: Dictionary,
	previous_close: float,
	current_price: float,
	daily_change_pct: float,
	market_sentiment: float,
	sector_sentiment: float,
	event_bias: float,
	_broker_flow: Dictionary,
	volume_context: Dictionary,
	run_seed: int,
	day_number: int,
	company_id: String,
	ar_limits: Dictionary,
	trade_date: Dictionary,
	close_context: Dictionary = {},
	player_flow_context: Dictionary = {},
	market_depth_context: Dictionary = {}
) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|bar|%s|%s" % [run_seed, day_number, company_id]))

	var limit_lock: String = str(close_context.get("limit_lock", ""))
	var limit_source: String = str(close_context.get("limit_source", ""))
	var gap_bias: float = clamp(
		(daily_change_pct * 0.32) +
		(event_bias * 0.18) +
		(market_sentiment * 0.08) +
		(sector_sentiment * 0.1),
		-0.08,
		0.08
	)
	var gap_noise: float = rng.randf_range(-0.012, 0.012)
	var open_raw: float = previous_close * (1.0 + gap_bias + gap_noise)
	var open_price: float = clamp(
		IDX_PRICE_RULES.snap_price_for_day(open_raw, previous_close),
		float(ar_limits.get("lower_price", 1.0)),
		float(ar_limits.get("upper_price", previous_close))
	)

	var intraday_span_pct: float = max(
		absf(daily_change_pct) * 0.65,
		float(definition.get("base_volatility", 0.02)) * 0.42,
		0.004
	)
	var upper_probe: float = max(open_price, current_price) * (1.0 + rng.randf_range(0.12, 0.75) * intraday_span_pct)
	var lower_probe: float = min(open_price, current_price) * (1.0 - rng.randf_range(0.12, 0.75) * intraday_span_pct)
	var high_price: float = clamp(
		IDX_PRICE_RULES.normalize_last_price(max(upper_probe, open_price, current_price)),
		float(ar_limits.get("lower_price", 1.0)),
		float(ar_limits.get("upper_price", current_price))
	)
	var low_price: float = clamp(
		IDX_PRICE_RULES.normalize_last_price(min(lower_probe, open_price, current_price)),
		float(ar_limits.get("lower_price", 1.0)),
		float(ar_limits.get("upper_price", current_price))
	)
	if limit_lock == "ara":
		open_price = previous_close
		low_price = min(previous_close, current_price)
		high_price = float(ar_limits.get("upper_price", current_price))
		current_price = high_price
	elif limit_lock == "arb":
		open_price = previous_close
		high_price = max(previous_close, current_price)
		low_price = float(ar_limits.get("lower_price", current_price))
		current_price = low_price

	var base_daily_value: float = max(float(volume_context.get("base_daily_value", current_price * 250000.0)), current_price * 1000.0)
	var volume_multiplier: float = max(float(volume_context.get("volume_multiplier", 1.0)), 0.10)
	var day_move_confirmation: float = 1.0 + min(absf(daily_change_pct) * 4.5, 0.75)
	if not limit_lock.is_empty():
		day_move_confirmation += 0.65 + min(absf(float(player_flow_context.get("depth_impact_ratio", 0.0))) * 0.12, 0.95)
	var traded_value: float = max(base_daily_value * volume_multiplier * day_move_confirmation, current_price * 1000.0)
	var volume_shares: int = int(max(round(traded_value / max(current_price, 1.0) / 100.0), 1.0) * 100.0)
	var bar_value: float = current_price * float(volume_shares)

	var bar: Dictionary = {
		"trade_date": trade_date.duplicate(true),
		"open": open_price,
		"high": high_price,
		"low": low_price,
		"close": current_price,
		"volume_shares": volume_shares,
		"value": bar_value
	}
	if not limit_lock.is_empty():
		bar["limit_lock"] = limit_lock
		bar["limit_source"] = limit_source
		bar["locked_through_day"] = true
		bar["impact_side"] = "buy" if limit_lock == "ara" else "sell"
	if float(player_flow_context.get("buy_value", 0.0)) > 0.0 or float(player_flow_context.get("sell_value", 0.0)) > 0.0:
		bar["player_impact_ratio"] = float(player_flow_context.get("depth_impact_ratio", 0.0))
		bar["player_liquidity_consumed"] = float(player_flow_context.get("side_depth_ratio", 0.0))
		bar["player_free_float_pct"] = float(player_flow_context.get("side_free_float_pct", 0.0))
		bar["player_broker_code"] = str(player_flow_context.get("broker_code", ""))
	if not market_depth_context.is_empty():
		bar["ask_depth_value"] = float(market_depth_context.get("ask_depth_value", 0.0))
		bar["bid_depth_value"] = float(market_depth_context.get("bid_depth_value", 0.0))
	return bar


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
