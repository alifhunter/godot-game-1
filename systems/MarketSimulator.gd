extends RefCounted

const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")

var company_event_system = preload("res://systems/CompanyEventSystem.gd").new()
var person_event_system = preload("res://systems/PersonEventSystem.gd").new()
var special_event_system = preload("res://systems/SpecialEventSystem.gd").new()


func simulate_day(run_state, data_repository, broker_flow_system) -> Dictionary:
	var day_number: int = int(run_state.day_index) + 1
	var trade_date: Dictionary = run_state.get_current_trade_date()
	var macro_state: Dictionary = run_state.get_current_macro_state()
	var difficulty_config: Dictionary = run_state.get_difficulty_config()
	var company_arc_resolution: Dictionary = company_event_system.resolve_day(
		run_state,
		trade_date,
		day_number,
		macro_state
	)
	var active_company_arcs: Array = company_arc_resolution.get("active_arcs", []).duplicate(true)
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
		var event_context: Dictionary = _resolve_event_context(
			definition,
			runtime,
			sector_definition,
			scheduled_event,
			active_special_events,
			active_company_arcs
		)

		var broker_context: Dictionary = {
			"run_seed": run_state.run_seed,
			"day_index": day_number,
			"company_id": company_id,
			"market_sentiment": market_sentiment,
			"sector_sentiment": sector_sentiment,
			"recent_momentum": recent_momentum,
			"event_bias": float(event_context.get("event_bias", 0.0))
		}
		var broker_flow: Dictionary = broker_flow_system.generate_day_flow(definition, runtime, broker_context)
		var previous_close: float = IDX_PRICE_RULES.normalize_last_price(float(runtime.get("current_price", definition.get("base_price", 0.0))))
		var daily_change_pct: float = _calculate_daily_change(
			definition,
			sector_definition,
			recent_momentum,
			market_sentiment,
			sector_sentiment,
			float(event_context.get("event_bias", 0.0)),
			float(broker_flow.get("net_pressure", 0.0)),
			run_state.run_seed,
			day_number,
			company_id,
			difficulty_config,
			float(event_context.get("event_volatility_multiplier", 1.0))
		)
		var raw_price: float = previous_close * (1.0 + daily_change_pct)
		var ar_limits: Dictionary = IDX_PRICE_RULES.auto_rejection_limits(previous_close, listing_board)
		var current_price: float = _resolve_day_close_price(
			raw_price,
			previous_close,
			ar_limits,
			str(sector_definition.get("id", "")),
			active_special_events,
			day_number,
			run_state.run_seed,
			company_id
		)
		daily_change_pct = 0.0
		if not is_zero_approx(previous_close):
			daily_change_pct = (current_price - previous_close) / previous_close
		var price_history: Array = runtime.get("price_history", []).duplicate()
		price_history.append(current_price)
		var price_bars: Array = runtime.get("price_bars", []).duplicate(true)
		price_bars.append(_build_daily_price_bar(
			definition,
			previous_close,
			current_price,
			daily_change_pct,
			market_sentiment,
			sector_sentiment,
			float(event_context.get("event_bias", 0.0)),
			broker_flow,
			run_state.run_seed,
			day_number,
			company_id,
			ar_limits,
			trade_date
		))

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

		companies_result[company_id] = runtime

	return {
		"day_number": day_number,
		"market_sentiment": market_sentiment,
		"companies": companies_result,
		"starting_equity": run_state.get_total_equity(),
		"scheduled_event": scheduled_event.duplicate(true),
		"started_company_arcs": company_arc_resolution.get("started_events", []).duplicate(true),
		"company_arc_phase_events": company_arc_resolution.get("phase_events", []).duplicate(true),
		"active_company_arcs": active_company_arcs,
		"started_special_events": special_event_resolution.get("started_events", []).duplicate(true),
		"active_special_events": active_special_events,
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


func _calculate_daily_change(
	definition: Dictionary,
	sector_definition: Dictionary,
	recent_momentum: float,
	market_sentiment: float,
	sector_sentiment: float,
	event_bias: float,
	broker_pressure: float,
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


func _build_daily_price_bar(
	definition: Dictionary,
	previous_close: float,
	current_price: float,
	daily_change_pct: float,
	market_sentiment: float,
	sector_sentiment: float,
	event_bias: float,
	broker_flow: Dictionary,
	run_seed: int,
	day_number: int,
	company_id: String,
	ar_limits: Dictionary,
	trade_date: Dictionary
) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|bar|%s|%s" % [run_seed, day_number, company_id]))

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

	var financials: Dictionary = definition.get("financials", {})
	var avg_daily_value: float = max(float(financials.get("avg_daily_value", current_price * 250000.0)), current_price * 1000.0)
	var flow_intensity: float = absf(float(broker_flow.get("net_pressure", 0.0)))
	var volume_multiplier: float = 1.0 + (flow_intensity * 0.75) + min(absf(event_bias) * 3.0, 1.5) + min(absf(daily_change_pct) * 8.0, 1.2)
	var traded_value: float = avg_daily_value * volume_multiplier * rng.randf_range(0.82, 1.24)
	var volume_shares: int = max(int(round(traded_value / max(current_price, 1.0))), 100)

	return {
		"trade_date": trade_date.duplicate(true),
		"open": open_price,
		"high": high_price,
		"low": low_price,
		"close": current_price,
		"volume_shares": volume_shares,
		"value": traded_value
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
