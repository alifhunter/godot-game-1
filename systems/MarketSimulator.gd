extends RefCounted

const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")
const STABLE_RNG = preload("res://systems/StableRng.gd")
const CHART_GAP_STYLES := ["none", "news_gap", "breakout_gap", "exhaustion_gap", "rug_gap", "mixed"]
const CHART_GAP_BIASES := ["up", "down", "mixed"]
const CHART_GAP_FREQUENCIES := ["rare", "moderate", "active"]
const CHART_GAP_FOLLOWTHROUGH := ["hold", "fade", "fill", "continue"]
const CHART_BAR_FRICTION_PROFILES := ["clean_liquid", "balanced_chop", "operator_dirty", "distribution_chop"]
const CHART_TAPE_REGIME_PROFILES := ["clean_trend", "messy_accumulation", "operator_campaign", "distribution_breakdown", "failed_reclaim"]

var company_event_system = preload("res://systems/CompanyEventSystem.gd").new()
var company_roadmap_system = preload("res://systems/CompanyRoadmapSystem.gd").new()
var person_event_system = preload("res://systems/PersonEventSystem.gd").new()
var special_event_system = preload("res://systems/SpecialEventSystem.gd").new()
var index_review_system = preload("res://systems/IndexReviewSystem.gd").new()
var attention_director_system = preload("res://systems/AttentionDirectorSystem.gd").new()
var dirty_tip_system = preload("res://systems/DirtyTipSystem.gd").new()


func simulate_day(run_state, data_repository, broker_flow_system, corporate_action_system) -> Dictionary:
	var day_number: int = int(run_state.day_index) + 1
	var trade_date: Dictionary = run_state.get_current_trade_date()
	var macro_state: Dictionary = run_state.get_current_macro_state()
	var difficulty_config: Dictionary = run_state.get_difficulty_config()
	var attention_directives: Dictionary = attention_director_system.resolve_day(
		run_state,
		trade_date,
		day_number,
		macro_state
	)
	var report_events: Array = run_state.get_quarterly_report_events_for_day_number(day_number, trade_date)
	var corporate_action_resolution: Dictionary = corporate_action_system.resolve_day(
		run_state,
		data_repository,
		trade_date,
		day_number,
		macro_state,
		report_events
	)
	var company_roadmap_resolution: Dictionary = company_roadmap_system.resolve_day(
		run_state,
		data_repository,
		corporate_action_system,
		trade_date,
		day_number,
		macro_state,
		corporate_action_resolution
	)
	if company_roadmap_resolution.has("active_corporate_action_chains"):
		corporate_action_resolution["active_corporate_action_chains"] = company_roadmap_resolution.get("active_corporate_action_chains", {}).duplicate(true)
	if company_roadmap_resolution.has("corporate_meeting_calendar"):
		corporate_action_resolution["corporate_meeting_calendar"] = company_roadmap_resolution.get("corporate_meeting_calendar", {}).duplicate(true)
	var company_attention_directives: Dictionary = attention_directives.duplicate(true)
	var blocked_company_ids: Array = []
	for blocked_company_id_value in company_roadmap_resolution.get("blocked_company_ids", []):
		var blocked_company_id: String = str(blocked_company_id_value)
		if not blocked_company_id.is_empty() and not blocked_company_ids.has(blocked_company_id):
			blocked_company_ids.append(blocked_company_id)
	if not blocked_company_ids.is_empty():
		company_attention_directives["blocked_company_ids"] = blocked_company_ids
	var company_arc_resolution: Dictionary = company_event_system.resolve_day(
		run_state,
		trade_date,
		day_number,
		macro_state,
		company_attention_directives
	)
	var index_review_resolution: Dictionary = index_review_system.resolve_day(
		run_state,
		data_repository,
		trade_date,
		day_number,
		macro_state
	)
	var active_company_arcs: Array = company_roadmap_resolution.get("active_company_arcs", []).duplicate(true)
	active_company_arcs.append_array(company_arc_resolution.get("active_arcs", []).duplicate(true))
	active_company_arcs.append_array(corporate_action_resolution.get("active_company_arcs", []).duplicate(true))
	active_company_arcs.append_array(index_review_resolution.get("active_company_arcs", []).duplicate(true))
	var special_event_resolution: Dictionary = special_event_system.resolve_day(
		run_state,
		trade_date,
		day_number,
		macro_state,
		attention_directives
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
		macro_state,
		attention_directives
	)
	var companies_result: Dictionary = {}

	for company_id_value in run_state.company_order:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = run_state.get_effective_company_definition(company_id)
		if definition.is_empty():
			continue
		var runtime: Dictionary = run_state.get_company(company_id).duplicate(true)
		var company_profile: Dictionary = runtime.get("company_profile", {})
		if bool(company_profile.get("trade_disabled", false)):
			var disabled_price: float = IDX_PRICE_RULES.normalize_last_price(float(runtime.get("current_price", definition.get("base_price", 0.0))))
			runtime["previous_close"] = disabled_price
			runtime["current_price"] = disabled_price
			runtime["daily_change_pct"] = 0.0
			runtime["sentiment"] = 0.0
			companies_result[company_id] = runtime
			continue
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
		event_context = _apply_dirty_tip_market_effect(
			event_context,
			dirty_tip_system.market_effect_for_company(run_state, company_id, day_number)
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
			"passive_flow_pressure": float(event_context.get("passive_flow_pressure", 0.0)),
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
		"company_roadmap_events": company_roadmap_resolution.get("started_events", []).duplicate(true),
		"company_roadmap_state": company_roadmap_resolution.get("company_roadmap_state", run_state.get_company_roadmap_state()).duplicate(true),
		"corporate_action_events": _combined_arrays(
			corporate_action_resolution.get("corporate_action_events", []),
			company_roadmap_resolution.get("corporate_action_events", [])
		),
		"index_review_events": index_review_resolution.get("index_review_events", []).duplicate(true),
		"index_review_state": index_review_resolution.get("index_review_state", {}).duplicate(true),
		"active_company_arcs": active_company_arcs,
		"started_special_events": special_event_resolution.get("started_events", []).duplicate(true),
		"active_special_events": active_special_events,
		"attention_directives": attention_directives.duplicate(true),
		"active_corporate_action_chains": corporate_action_resolution.get("active_corporate_action_chains", {}).duplicate(true),
		"corporate_meeting_calendar": corporate_action_resolution.get("corporate_meeting_calendar", {}).duplicate(true),
		"corporate_action_intel": corporate_action_resolution.get("corporate_action_intel", {}).duplicate(true),
		"corporate_dividend_calendar": corporate_action_resolution.get("corporate_dividend_calendar", {}).duplicate(true),
		"dividend_payments": corporate_action_resolution.get("dividend_payments", []).duplicate(true),
		"stock_dividend_distributions": corporate_action_resolution.get("stock_dividend_distributions", []).duplicate(true),
		"corporate_action_applications": corporate_action_resolution.get("corporate_action_applications", []).duplicate(true),
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
	var rng: RandomNumberGenerator = STABLE_RNG.rng([
		run_seed,
		"sideways",
		str(special_event.get("event_id", "")),
		company_id,
		day_number
	])
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
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "market", day_number])
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
		var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "sector", day_number, sector_id])
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
	macro_state: Dictionary = {},
	attention_directives: Dictionary = {}
) -> Dictionary:
	var event_interval_days: float = max(float(difficulty_config.get("event_interval_days", 30.0)), 1.0)
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_state.run_seed, "daily_event", day_number])
	var scheduled_event_probability_multiplier: float = clamp(float(attention_directives.get("scheduled_event_probability_multiplier", 1.0)), 0.0, 4.0)

	if scheduled_event_probability_multiplier <= 0.0:
		return {}
	if rng.randf() >= clamp((1.0 / event_interval_days) * scheduled_event_probability_multiplier, 0.0, 0.85):
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
		company_event_system.build_company_event_candidates(run_state, trade_date, day_number, macro_state, attention_directives)
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
	candidates = _apply_attention_focus_weights(candidates, attention_directives)
	if bool(attention_directives.get("suppress_market_scheduled_event", false)):
		candidates = candidates.filter(func(candidate_value: Dictionary) -> bool:
			return str(candidate_value.get("scope", "company")) != "market"
		)

	if candidates.is_empty():
		return {}

	return _pick_weighted_candidate(rng, candidates)


func _apply_attention_focus_weights(candidates: Array, attention_directives: Dictionary) -> Array:
	var focus_weights: Dictionary = attention_directives.get("focus_company_weights", {})
	if focus_weights.is_empty():
		return candidates
	var weighted_candidates: Array = []
	for candidate_value in candidates:
		if typeof(candidate_value) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = candidate_value.duplicate(true)
		var company_id: String = str(candidate.get("target_company_id", ""))
		if not company_id.is_empty():
			var multiplier: float = clamp(float(focus_weights.get(company_id, 1.0)), 0.25, 3.0)
			candidate["weight"] = float(candidate.get("weight", 1.0)) * multiplier
		weighted_candidates.append(candidate)
	return weighted_candidates


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


func _combined_arrays(first_value: Variant, second_value: Variant) -> Array:
	var rows: Array = []
	if typeof(first_value) == TYPE_ARRAY:
		rows.append_array(first_value)
	if typeof(second_value) == TYPE_ARRAY:
		rows.append_array(second_value)
	return rows


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
	var passive_flow_pressure: float = 0.0
	var volume_activity_multiplier: float = 1.0
	var depth_liquidity_multiplier: float = 1.0
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
		passive_flow_pressure += float(company_arc.get("phase_passive_flow_pressure", 0.0))
		volume_activity_multiplier *= float(company_arc.get("phase_volume_activity_multiplier", 1.0))
		depth_liquidity_multiplier *= float(company_arc.get("phase_depth_liquidity_multiplier", 1.0))
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
		"passive_flow_pressure": clamp(passive_flow_pressure, -1.0, 1.0),
		"volume_activity_multiplier": clamp(volume_activity_multiplier, 0.35, 3.0),
		"depth_liquidity_multiplier": clamp(depth_liquidity_multiplier, 0.55, 2.4),
		"hidden_story_flags": hidden_story_flags,
		"sector_id": str(sector_definition.get("id", ""))
	}


func _apply_dirty_tip_market_effect(event_context: Dictionary, dirty_tip_effect: Dictionary) -> Dictionary:
	if dirty_tip_effect.is_empty():
		return event_context
	var context: Dictionary = event_context.duplicate(true)
	context["event_bias"] = clamp(float(context.get("event_bias", 0.0)) + float(dirty_tip_effect.get("price_bias", 0.0)), -0.08, 0.08)
	context["passive_flow_pressure"] = clamp(float(context.get("passive_flow_pressure", 0.0)) + float(dirty_tip_effect.get("broker_pressure", 0.0)), -1.0, 1.0)
	context["volume_activity_multiplier"] = clamp(float(context.get("volume_activity_multiplier", 1.0)) * float(dirty_tip_effect.get("volume_multiplier", 1.0)), 0.35, 3.0)
	var hidden_flags: Array = context.get("hidden_story_flags", []).duplicate()
	if not hidden_flags.has("dirty_tip_pressure"):
		hidden_flags.append("dirty_tip_pressure")
	context["hidden_story_flags"] = hidden_flags
	context["dirty_tip_pressure"] = float(dirty_tip_effect.get("pressure", 0.0))
	context["dirty_tip_offer_id"] = str(dirty_tip_effect.get("offer_id", ""))
	return context


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
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "depth", day_number, company_id])

	var financials: Dictionary = definition.get("financials", {})
	var traits: Dictionary = definition.get("generation_traits", {})
	var profile: Dictionary = runtime.get("company_profile", {})
	var delisting_watch: Dictionary = profile.get("delisting_watch", {}) if typeof(profile) == TYPE_DICTIONARY else {}
	var sponsor_lockup: Dictionary = profile.get("backdoor_sponsor_lockup", {}) if typeof(profile) == TYPE_DICTIONARY else {}
	var backdoor_milestone_state: Dictionary = profile.get("backdoor_milestone_state", {}) if typeof(profile) == TYPE_DICTIONARY else {}
	var restructuring_result: Dictionary = profile.get("restructuring_result", {}) if typeof(profile) == TYPE_DICTIONARY else {}
	var has_delisting_watch: bool = not delisting_watch.is_empty()
	var liquidity_penalty: float = clamp(float(delisting_watch.get("liquidity_penalty_multiplier", profile.get("liquidity_penalty_multiplier", 1.0) if typeof(profile) == TYPE_DICTIONARY else 1.0)), 0.05, 1.0)
	if not restructuring_result.is_empty():
		liquidity_penalty = min(liquidity_penalty, clamp(float(restructuring_result.get("liquidity_penalty_multiplier", 1.0)), 0.05, 1.0))
	var volatility_event_multiplier: float = clamp(float(delisting_watch.get("volatility_event_multiplier", profile.get("volatility_event_multiplier", 1.0) if typeof(profile) == TYPE_DICTIONARY else 1.0)), 1.0, 3.0)
	if not restructuring_result.is_empty():
		volatility_event_multiplier = max(volatility_event_multiplier, clamp(float(restructuring_result.get("volatility_event_multiplier", 1.0)), 1.0, 3.0))
	var current_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var market_cap: float = max(float(financials.get("market_cap", current_price * 1000000000.0)), current_price * 1000000.0)
	var shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", market_cap / current_price))), 1.0)
	var free_float_floor: float = 0.02 if has_delisting_watch else 0.07
	var free_float_ratio: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, free_float_floor, 0.85)
	var free_float_shares: float = max(shares_outstanding * free_float_ratio, 1.0)
	var free_float_value: float = max(free_float_shares * current_price, current_price * 1000.0)
	var avg_daily_value: float = max(float(financials.get("avg_daily_value", current_price * 250000.0)), current_price * 1000.0)
	var liquidity_profile: float = clamp(float(traits.get("liquidity_profile", 0.5)), 0.0, 1.0)
	var story_heat: float = clamp(float(traits.get("story_heat", 0.5)), 0.0, 1.0)
	var base_volatility: float = max(float(definition.get("base_volatility", 0.025)), 0.004)
	var event_intensity: float = min(absf(float(event_context.get("event_bias", 0.0))) * 7.0, 1.35)
	var passive_flow_pressure: float = clamp(float(event_context.get("passive_flow_pressure", 0.0)), -1.0, 1.0)
	var depth_liquidity_multiplier: float = clamp(float(event_context.get("depth_liquidity_multiplier", 1.0)), 0.65, 2.0)
	if not is_zero_approx(passive_flow_pressure):
		event_intensity = max(event_intensity, min(absf(passive_flow_pressure) * 1.35, 1.35))
	if has_delisting_watch or volatility_event_multiplier > 1.0:
		event_intensity = max(event_intensity, min((volatility_event_multiplier - 1.0) * 1.4, 1.35))
	var sponsor_overhang_pressure: float = 0.0
	var sponsor_lockup_state: String = ""
	if not sponsor_lockup.is_empty():
		sponsor_lockup_state = str(sponsor_lockup.get("state", ""))
		if sponsor_lockup_state in ["warning", "extended"] or sponsor_lockup_state.begins_with("unlocked_"):
			sponsor_overhang_pressure = clamp(float(sponsor_lockup.get("active_overhang_pressure_pct", sponsor_lockup.get("overhang_pressure_pct", 0.0))), 0.0, 1.0)
			event_intensity = max(event_intensity, min(sponsor_overhang_pressure * 2.2, 1.35))
	var milestone_pressure: float = 0.0
	var milestone_state: String = ""
	if not backdoor_milestone_state.is_empty():
		milestone_state = str(backdoor_milestone_state.get("state", ""))
		if str(backdoor_milestone_state.get("last_result_state", "")) in ["delayed", "setback"]:
			milestone_pressure = clamp(absf(float(backdoor_milestone_state.get("last_price_adjustment_pct", 0.0))) * 4.0, 0.0, 0.65)
			event_intensity = max(event_intensity, min(milestone_pressure * 2.0, 1.35))
	var restructuring_pressure: float = 0.0
	if not restructuring_result.is_empty():
		restructuring_pressure = clamp(float(restructuring_result.get("stress_overhang_pct", 0.0)), 0.0, 1.0)
		event_intensity = max(event_intensity, min(restructuring_pressure * 1.8, 1.35))
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
	synthetic_daily_value = max(synthetic_daily_value * liquidity_penalty, current_price * 1000.0)
	synthetic_daily_value = max(synthetic_daily_value * depth_liquidity_multiplier, current_price * 1000.0)

	var depth_quality: float = lerp(0.72, 1.72, liquidity_profile) * lerp(0.78, 1.18, free_float_ratio) * liquidity_penalty
	var ask_sentiment_modifier: float = clamp(1.0 - max(sentiment_bias, 0.0) * 0.28 + max(-sentiment_bias, 0.0) * 0.16, 0.62, 1.35)
	var bid_sentiment_modifier: float = clamp(1.0 + max(sentiment_bias, 0.0) * 0.16 - max(-sentiment_bias, 0.0) * 0.30, 0.62, 1.35)
	var ask_depth_value: float = max(synthetic_daily_value * depth_quality * ask_sentiment_modifier, current_price * 1000.0)
	var bid_depth_value: float = max(synthetic_daily_value * depth_quality * bid_sentiment_modifier, current_price * 1000.0)
	if passive_flow_pressure > 0.0:
		ask_depth_value = max(ask_depth_value * clamp(1.0 - passive_flow_pressure * 0.16, 0.70, 1.0), current_price * 1000.0)
		bid_depth_value = max(bid_depth_value * (1.0 + passive_flow_pressure * 0.24), current_price * 1000.0)
	elif passive_flow_pressure < 0.0:
		var passive_sell_pressure: float = absf(passive_flow_pressure)
		ask_depth_value = max(ask_depth_value * (1.0 + passive_sell_pressure * 0.24), current_price * 1000.0)
		bid_depth_value = max(bid_depth_value * clamp(1.0 - passive_sell_pressure * 0.16, 0.70, 1.0), current_price * 1000.0)
	if sponsor_overhang_pressure > 0.0:
		synthetic_daily_value = max(synthetic_daily_value * (1.0 + sponsor_overhang_pressure * 0.55), current_price * 1000.0)
		ask_depth_value = max(ask_depth_value * (1.0 + sponsor_overhang_pressure * 1.45), current_price * 1000.0)
		bid_depth_value = max(bid_depth_value * clamp(1.0 - sponsor_overhang_pressure * 0.30, 0.58, 1.0), current_price * 1000.0)
	if restructuring_pressure > 0.0:
		synthetic_daily_value = max(synthetic_daily_value * (1.0 + restructuring_pressure * 0.34), current_price * 1000.0)
		ask_depth_value = max(ask_depth_value * (1.0 + restructuring_pressure * 1.05), current_price * 1000.0)
		bid_depth_value = max(bid_depth_value * clamp(1.0 - restructuring_pressure * 0.22, 0.60, 1.0), current_price * 1000.0)
	if milestone_pressure > 0.0:
		synthetic_daily_value = max(synthetic_daily_value * (1.0 + milestone_pressure * 0.42), current_price * 1000.0)
		ask_depth_value = max(ask_depth_value * (1.0 + milestone_pressure * 1.18), current_price * 1000.0)
		bid_depth_value = max(bid_depth_value * clamp(1.0 - milestone_pressure * 0.26, 0.58, 1.0), current_price * 1000.0)
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
		"event_intensity": event_intensity,
		"delisting_watch_state": str(delisting_watch.get("state", "")),
		"restructuring_state": str(restructuring_result.get("state", "")),
		"restructuring_stress_overhang_pct": restructuring_pressure,
		"backdoor_milestone_state": milestone_state,
		"backdoor_milestone_pressure_pct": milestone_pressure,
		"sponsor_lockup_state": sponsor_lockup_state,
		"sponsor_overhang_pressure_pct": sponsor_overhang_pressure,
		"passive_flow_pressure": passive_flow_pressure,
		"depth_liquidity_multiplier": depth_liquidity_multiplier,
		"liquidity_penalty_multiplier": liquidity_penalty,
		"volatility_event_multiplier": volatility_event_multiplier
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
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "price", day_number, company_id])

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
	daily_change += float(volume_context.get("technical_price_bias", 0.0))
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
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "volume_activity", day_number, company_id])

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
	var chart_profile: Dictionary = _chart_profile_from_definition(definition, run_seed, company_id)
	var event_bias: float = float(event_context.get("event_bias", 0.0))
	var event_volatility_multiplier: float = clamp(float(event_context.get("event_volatility_multiplier", 1.0)), 0.55, 2.1)
	var passive_flow_pressure: float = clamp(float(event_context.get("passive_flow_pressure", 0.0)), -1.0, 1.0)
	var passive_volume_multiplier: float = clamp(float(event_context.get("volume_activity_multiplier", 1.0)), 0.35, 3.0)
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
	var operator_pressure: float = _live_operator_pressure(
		definition,
		runtime,
		chart_profile,
		broker_flow,
		player_flow,
		float_tightness,
		liquidity_profile,
		story_heat,
		hidden_flags
	)
	var cycle_template: String = str(chart_profile.get("cycle_template", ""))
	var retail_chase: float = clamp(
		max(retail_pressure, 0.0) * 0.42 +
		max(recent_momentum, 0.0) * 5.0 +
		story_heat * 0.22 +
		(0.16 if "retail_favorite" in narrative_tags else 0.0) +
		(0.12 if "narrative_hot" in narrative_tags else 0.0) +
		operator_pressure * 0.12,
		0.0,
		1.0
	)
	var accumulation_signal: float = clamp(
		max(net_pressure, 0.0) * 0.25 +
		max(smart_money_pressure, 0.0) * 0.38 +
		max(event_bias, 0.0) * 5.0 +
		max(passive_flow_pressure, 0.0) * 0.26 +
		max(sector_sentiment, 0.0) * 1.6 +
		max(market_sentiment, 0.0) * 0.9 +
		float_tightness * 0.14 +
		(0.34 if has_hidden_accumulation else 0.0) +
		(0.16 if has_stealth_interest else 0.0) +
		(operator_pressure * 0.18 if cycle_template == "operator_markup" else 0.0) +
		(operator_pressure * 0.08 if cycle_template == "markup_clean" else 0.0) +
		max(-recent_momentum, 0.0) * 1.4,
		0.0,
		1.0
	)
	var distribution_signal: float = clamp(
		max(-smart_money_pressure, 0.0) * 0.36 +
		max(-net_pressure, 0.0) * 0.18 +
		max(-event_bias, 0.0) * 5.0 +
		max(-passive_flow_pressure, 0.0) * 0.26 +
		max(-sector_sentiment, 0.0) * 1.6 +
		max(-market_sentiment, 0.0) * 0.9 +
		float_tightness * 0.12 +
		(0.38 if hidden_distribution else 0.0) +
		(operator_pressure * 0.20 if cycle_template == "operator_rug" else 0.0) +
		(operator_pressure * 0.10 if cycle_template == "distribution_clean" else 0.0) +
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
		operator_pressure * 0.18 +
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
	var technical_context: Dictionary = _build_technical_structure_context(
		definition,
		runtime,
		event_bias,
		net_pressure,
		smart_money_pressure,
		player_abs_ratio,
		run_seed,
		day_number,
		company_id,
		chart_profile
	)

	var event_multiplier: float = 1.0 + min(absf(event_bias) * 6.0, 1.55) + max(event_volatility_multiplier - 1.0, 0.0) * 0.70
	var broker_multiplier: float = 1.0 + absf(net_pressure) * 0.50 + absf(smart_money_pressure) * 0.35
	var hidden_multiplier: float = 1.0 + (0.34 if has_hidden_accumulation else 0.0) + (0.14 if has_stealth_interest else 0.0) + (0.36 if hidden_distribution else 0.0)
	var story_multiplier: float = 1.0 + story_heat * 0.16 + float_tightness * 0.14
	var memory_multiplier: float = clamp(lerp(0.88, 1.42, clamp((short_activity_ratio - 0.65) / 2.60, 0.0, 1.0)), 0.82, 1.48)
	var exhaustion_multiplier: float = 1.0 + exhaustion_score * 0.80
	var operator_multiplier: float = 1.0 + operator_pressure * 0.24
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
		operator_multiplier *
		float(technical_context.get("volume_multiplier", 1.0)) *
		passive_volume_multiplier *
		player_volume_multiplier *
		lumpy_noise,
		0.30,
		8.00
	)
	var expected_activity_ratio: float = (base_daily_value * volume_multiplier) / max(recent_value_average, 1.0)

	return {
		"base_daily_value": base_daily_value,
		"volume_multiplier": volume_multiplier,
		"passive_flow_pressure": passive_flow_pressure,
		"passive_volume_multiplier": passive_volume_multiplier,
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
		"technical_price_bias": float(technical_context.get("price_bias", 0.0)),
		"technical_volume_multiplier": float(technical_context.get("volume_multiplier", 1.0)),
		"technical_sma_period": int(technical_context.get("sma_period", 0)),
		"technical_sma_behavior": str(technical_context.get("sma_behavior", "")),
		"operator_pressure": operator_pressure,
		"cycle_template": cycle_template,
		"cycle_phase_bias": str(chart_profile.get("cycle_phase_bias", "")),
		"player_impact_ratio": player_impact_ratio,
		"player_abs_ratio": player_abs_ratio,
		"player_price_bias": player_price_bias,
		"player_depth_price_bias": depth_price_bias,
		"player_depth_impact_ratio": float(player_flow.get("depth_impact_ratio", 0.0)),
		"player_buy_liquidity_consumed": float(player_flow.get("buy_liquidity_consumed", 0.0)),
		"player_sell_liquidity_consumed": float(player_flow.get("sell_liquidity_consumed", 0.0)),
		"player_gross_free_float_pct": float(player_flow.get("gross_free_float_pct", 0.0))
	}


func _live_operator_pressure(
	definition: Dictionary,
	runtime: Dictionary,
	chart_profile: Dictionary,
	broker_flow: Dictionary,
	player_flow: Dictionary,
	float_tightness: float,
	liquidity_profile: float,
	story_heat: float,
	hidden_flags: Array
) -> float:
	var traits: Dictionary = definition.get("generation_traits", {})
	var narrative_tags: Array = definition.get("narrative_tags", [])
	var pressure: float = clamp(float(chart_profile.get("operator_pressure", 0.0)), 0.0, 1.0) * 0.30
	pressure += float_tightness * 0.22
	pressure += (1.0 - liquidity_profile) * 0.12
	pressure += story_heat * 0.10
	pressure += clamp(absf(float(broker_flow.get("bandar_net", 0.0))) / 100.0, 0.0, 1.0) * 0.12
	pressure += clamp(absf(float(broker_flow.get("zombie_net", 0.0))) / 100.0, 0.0, 1.0) * 0.08
	pressure += max(absf(float(broker_flow.get("smart_money_pressure", 0.0))), 0.0) * 0.10
	pressure += clamp(float(player_flow.get("gross_free_float_pct", 0.0)) * 18.0, 0.0, 1.0) * 0.08
	pressure += clamp(float(player_flow.get("depth_impact_ratio", 0.0)), 0.0, 1.0) * 0.06
	pressure += 0.07 if str(chart_profile.get("cycle_template", "")).begins_with("operator") else 0.0
	pressure += 0.06 if "retail_favorite" in narrative_tags else 0.0
	pressure += 0.06 if "narrative_hot" in narrative_tags else 0.0
	pressure += 0.08 if "smart_money_accumulation" in hidden_flags else 0.0
	pressure += 0.08 if "smart_money_distribution" in hidden_flags else 0.0
	pressure += 0.06 if bool(traits.get("is_gorengan", false)) else 0.0
	var depth_context: Dictionary = runtime.get("market_depth_context", {}) if typeof(runtime.get("market_depth_context", {})) == TYPE_DICTIONARY else {}
	pressure += clamp(1.0 - float(depth_context.get("depth_liquidity_score", liquidity_profile)), 0.0, 1.0) * 0.08
	return clamp(pressure, 0.0, 1.0)


func _live_microstructure_context(
	chart_profile: Dictionary,
	price_bars: Array,
	run_seed: int,
	day_number: int,
	company_id: String
) -> Dictionary:
	var intensity: float = clamp(float(chart_profile.get("microstructure_intensity", 0.0)), 0.0, 1.0)
	var shakeout_profile: String = str(chart_profile.get("shakeout_profile", "none"))
	var cycle_template: String = str(chart_profile.get("cycle_template", ""))
	var microstructure_active: bool = intensity > 0.0 and shakeout_profile != "none" and not cycle_template.is_empty()

	var operator_pressure: float = clamp(float(chart_profile.get("operator_pressure", 0.0)), 0.0, 1.0)
	var tempo_profile: String = str(chart_profile.get("cycle_tempo_profile", "normal_setup"))
	var period: float = 21.0
	var width: float = 0.070
	match tempo_profile:
		"slow_setup":
			period = 34.0
			width = 0.088
		"fast_operator":
			period = 13.0
			width = 0.052
		"failed_setup":
			period = 18.0
			width = 0.074
	var offset: float = _sim_noise(run_seed, company_id, "live_microstructure_phase_offset", 0.0, 1.0, 1)
	var raw_phase: float = float(day_number) / max(period, 1.0) + offset
	var phase: float = raw_phase - floor(raw_phase)
	var pressure: float = clamp(intensity * (0.55 + operator_pressure * 0.45), 0.0, 1.0) if microstructure_active else 0.0
	var recent_runup: float = max(_recent_price_change_from_bars(price_bars, 8), 0.0)
	var recent_drawdown: float = max(-_recent_price_change_from_bars(price_bars, 8), 0.0)
	var price_bias: float = 0.0
	var volume_boost: float = 0.0

	if microstructure_active and cycle_template in ["markup_clean", "markup_exhaustion", "operator_markup"]:
		var shake_pulse: float = _live_microstructure_pulse(phase, 0.30, width)
		var reclaim_pulse: float = _live_microstructure_pulse(phase, 0.40, width * 0.90)
		var shelf_pulse: float = _live_microstructure_pulse(phase, 0.68, width)
		var runup_factor: float = clamp(0.42 + recent_runup * 6.0, 0.42, 1.28)
		var shake_depth: float = 0.0040 * pressure * runup_factor
		if shakeout_profile == "hard_shakeout":
			shake_depth *= 1.32
		price_bias -= shake_pulse * shake_depth
		price_bias += reclaim_pulse * 0.0028 * pressure
		price_bias -= shelf_pulse * 0.0021 * pressure
		volume_boost += (shake_pulse * 0.22 + reclaim_pulse * 0.14 + shelf_pulse * 0.10) * pressure
	elif microstructure_active and cycle_template in ["distribution_clean", "failed_markup", "operator_rug"]:
		var bounce_pulse: float = _live_microstructure_pulse(phase, 0.36, width)
		var failure_pulse: float = _live_microstructure_pulse(phase, 0.50, width)
		var continuation_pulse: float = _live_microstructure_pulse(phase, 0.63, width * 1.08)
		var drawdown_factor: float = clamp(0.38 + recent_drawdown * 6.5, 0.38, 1.30)
		var bounce_size: float = 0.0032 * pressure * drawdown_factor
		price_bias += bounce_pulse * bounce_size
		price_bias -= failure_pulse * 0.0024 * pressure
		price_bias -= continuation_pulse * 0.0034 * pressure
		if cycle_template == "operator_rug":
			price_bias -= continuation_pulse * 0.0018 * operator_pressure
		volume_boost += (bounce_pulse * 0.12 + failure_pulse * 0.16 + continuation_pulse * 0.24) * pressure

	var regime_context: Dictionary = _live_tape_regime_context(chart_profile, price_bars, run_seed, day_number, company_id)
	price_bias += float(regime_context.get("price_bias", 0.0))
	volume_boost += float(regime_context.get("volume_boost", 0.0))
	pressure = max(pressure, float(regime_context.get("pressure", 0.0)))

	var friction_context: Dictionary = _live_daily_tape_friction_context(chart_profile, price_bars, run_seed, day_number, company_id)
	price_bias += float(friction_context.get("price_bias", 0.0))
	volume_boost += float(friction_context.get("volume_boost", 0.0))
	pressure = max(pressure, float(friction_context.get("pressure", 0.0)))

	return {
		"price_bias": clamp(price_bias, -0.0048, 0.0048),
		"volume_boost": clamp(volume_boost, -0.16, 0.55),
		"pressure": pressure,
		"phase": phase
	}


func _live_tape_regime_context(
	chart_profile: Dictionary,
	price_bars: Array,
	run_seed: int,
	day_number: int,
	company_id: String
) -> Dictionary:
	var strength: float = clamp(float(chart_profile.get("regime_block_intensity", 0.0)), 0.0, 1.0)
	if strength <= 0.0:
		return {"price_bias": 0.0, "volume_boost": 0.0, "pressure": 0.0, "phase": "calm"}
	var blocks: Array = _live_tape_regime_blocks(chart_profile)
	if blocks.is_empty():
		return {"price_bias": 0.0, "volume_boost": 0.0, "pressure": 0.0, "phase": "calm"}
	var period: float = _live_tape_regime_period(chart_profile)
	var offset: float = _sim_noise(run_seed, company_id, "live_tape_regime_phase_offset", 0.0, 1.0, 1)
	var raw_progress: float = float(day_number) / max(period, 1.0) + offset
	var progress: float = raw_progress - floor(raw_progress)
	var block: Dictionary = _live_tape_regime_block_at(blocks, progress)
	if block.is_empty():
		return {"price_bias": 0.0, "volume_boost": 0.0, "pressure": 0.0, "phase": "calm"}
	var block_type: String = str(block.get("type", "base"))
	var block_start: float = float(block.get("p0", 0.0))
	var block_end: float = float(block.get("p1", 1.0))
	var block_progress: float = clamp((progress - block_start) / max(block_end - block_start, 0.001), 0.0, 1.0)
	var operator_pressure: float = clamp(float(chart_profile.get("operator_pressure", 0.0)), 0.0, 1.0)
	var recent_runup: float = max(_recent_price_change_from_bars(price_bars, 8), 0.0)
	var recent_drawdown: float = max(-_recent_price_change_from_bars(price_bars, 8), 0.0)
	var price_bias: float = 0.0
	var volume_boost: float = 0.0
	var pulse: float = _live_microstructure_pulse(block_progress, 0.50, 0.38)
	match block_type:
		"base", "consolidation":
			price_bias += _sim_noise(run_seed, company_id, "live_regime_base_bias", -0.0014, 0.0014, day_number) * strength
			volume_boost -= lerp(0.02, 0.10, strength)
		"markup":
			price_bias += lerp(0.0009, 0.0038, strength) * (0.50 + pulse) * (1.0 + operator_pressure * 0.18)
			volume_boost += lerp(0.04, 0.26, strength) * (0.45 + pulse)
		"channel":
			var pullback: float = _live_microstructure_pulse(block_progress, 0.34, 0.18)
			var reclaim: float = _live_microstructure_pulse(block_progress, 0.55, 0.16)
			price_bias += lerp(0.0004, 0.0016, strength)
			price_bias -= pullback * lerp(0.0013, 0.0042, strength) * (1.0 + clamp(recent_runup * 6.0, 0.0, 0.8))
			price_bias += reclaim * lerp(0.0008, 0.0024, strength)
			volume_boost += pullback * lerp(0.03, 0.20, strength)
		"distribution":
			var top_fail: float = _live_microstructure_pulse(block_progress, 0.58, 0.24)
			price_bias -= top_fail * lerp(0.0012, 0.0044, strength) * (1.0 + clamp(recent_runup * 5.0, 0.0, 0.8))
			volume_boost += top_fail * lerp(0.04, 0.28, strength)
		"breakdown", "markdown", "rug":
			var drop_pulse: float = _live_microstructure_pulse(block_progress, 0.46, 0.32)
			price_bias -= lerp(0.0010, 0.0048, strength) * (0.48 + drop_pulse) * (1.0 + operator_pressure * 0.18)
			volume_boost += lerp(0.04, 0.32, strength) * (0.35 + drop_pulse)
		"dead_cat":
			var bounce: float = _live_microstructure_pulse(block_progress, 0.34, 0.20)
			var fail: float = _live_microstructure_pulse(block_progress, 0.72, 0.22)
			price_bias += bounce * lerp(0.0012, 0.0036, strength) * (1.0 + clamp(recent_drawdown * 5.5, 0.0, 0.8))
			price_bias -= fail * lerp(0.0014, 0.0042, strength)
			volume_boost += fail * lerp(0.04, 0.24, strength)
		"failed_reclaim":
			var reclaim_try: float = _live_microstructure_pulse(block_progress, 0.32, 0.20)
			var reject: float = _live_microstructure_pulse(block_progress, 0.62, 0.24)
			price_bias += reclaim_try * lerp(0.0009, 0.0030, strength)
			price_bias -= reject * lerp(0.0015, 0.0046, strength)
			volume_boost += reject * lerp(0.04, 0.28, strength)
	return {
		"price_bias": clamp(price_bias, -0.0044, 0.0044),
		"volume_boost": clamp(volume_boost, -0.12, 0.38),
		"pressure": strength,
		"phase": block_type
	}


func _live_tape_regime_blocks(chart_profile: Dictionary) -> Array:
	var profile_id: String = str(chart_profile.get("tape_regime_profile", "messy_accumulation"))
	if not CHART_TAPE_REGIME_PROFILES.has(profile_id):
		profile_id = "messy_accumulation"
	var tempo_bias: float = clamp(float(chart_profile.get("regime_tempo_bias", 0.0)), -1.0, 1.0)
	var base_end: float = _live_tape_regime_base_end(chart_profile, profile_id, tempo_bias)
	match profile_id:
		"clean_trend":
			var impulse_end: float = clamp(base_end + 0.16 - tempo_bias * 0.025, base_end + 0.09, 0.56)
			return _live_tape_regime_rows([
				["base", 0.00, base_end, 0],
				["markup", base_end, impulse_end, 1],
				["channel", impulse_end, 0.84, 1],
				["consolidation", 0.84, 1.00, 0]
			])
		"operator_campaign":
			var operator_markup_end: float = clamp(base_end + 0.15, base_end + 0.08, 0.42)
			var dirty_channel_end: float = clamp(operator_markup_end + 0.24, operator_markup_end + 0.14, 0.70)
			var distribution_end: float = clamp(dirty_channel_end + 0.13, dirty_channel_end + 0.08, 0.84)
			var final_type: String = "rug" if str(chart_profile.get("cycle_template", "")) == "operator_rug" else "failed_reclaim"
			return _live_tape_regime_rows([
				["base", 0.00, base_end, 0],
				["markup", base_end, operator_markup_end, 1],
				["channel", operator_markup_end, dirty_channel_end, 1],
				["distribution", dirty_channel_end, distribution_end, -1],
				[final_type, distribution_end, 1.00, -1]
			])
		"distribution_breakdown":
			var distribution_end_1: float = clamp(max(base_end, 0.24), 0.18, 0.36)
			var breakdown_end: float = clamp(distribution_end_1 + 0.18, distribution_end_1 + 0.10, 0.58)
			var dead_cat_end: float = clamp(breakdown_end + 0.13, breakdown_end + 0.08, 0.72)
			return _live_tape_regime_rows([
				["distribution", 0.00, distribution_end_1, -1],
				["breakdown", distribution_end_1, breakdown_end, -1],
				["dead_cat", breakdown_end, dead_cat_end, 1],
				["markdown", dead_cat_end, 0.86, -1],
				["failed_reclaim", 0.86, 1.00, -1]
			])
		"failed_reclaim":
			var failed_markup_end: float = clamp(base_end + 0.14, base_end + 0.08, 0.50)
			var failed_dist_end: float = clamp(failed_markup_end + 0.16, failed_markup_end + 0.08, 0.66)
			var failed_break_end: float = clamp(failed_dist_end + 0.16, failed_dist_end + 0.08, 0.82)
			return _live_tape_regime_rows([
				["base", 0.00, base_end, 0],
				["markup", base_end, failed_markup_end, 1],
				["distribution", failed_markup_end, failed_dist_end, -1],
				["breakdown", failed_dist_end, failed_break_end, -1],
				["failed_reclaim", failed_break_end, 1.00, -1]
			])
	var messy_markup_end: float = clamp(base_end + 0.16, base_end + 0.08, 0.56)
	var messy_channel_end: float = clamp(messy_markup_end + 0.30, messy_markup_end + 0.16, 0.84)
	return _live_tape_regime_rows([
		["base", 0.00, base_end, 0],
		["markup", base_end, messy_markup_end, 1],
		["channel", messy_markup_end, messy_channel_end, 1],
		["distribution", messy_channel_end, 1.00, -1]
	])


func _live_tape_regime_base_end(chart_profile: Dictionary, profile_id: String, tempo_bias: float) -> float:
	var base_end: float = 0.32
	match profile_id:
		"clean_trend":
			base_end = 0.34
		"messy_accumulation":
			base_end = 0.34
		"operator_campaign":
			base_end = 0.19
		"distribution_breakdown":
			base_end = 0.25
		"failed_reclaim":
			base_end = 0.30
	match str(chart_profile.get("cycle_tempo_profile", "normal_setup")):
		"slow_setup":
			base_end += 0.06
		"fast_operator":
			base_end -= 0.06
		"failed_setup":
			base_end += 0.03
	base_end += tempo_bias * 0.10
	return clamp(base_end, 0.12, 0.48)


func _live_tape_regime_rows(rows: Array) -> Array:
	var blocks: Array = []
	var previous_end: float = 0.0
	for row_value in rows:
		if typeof(row_value) != TYPE_ARRAY:
			continue
		var row: Array = row_value
		if row.size() < 4:
			continue
		var start_progress: float = clamp(max(float(row[1]), previous_end), 0.0, 1.0)
		var end_progress: float = clamp(max(float(row[2]), start_progress + 0.015), 0.0, 1.0)
		if end_progress <= start_progress:
			continue
		blocks.append({
			"type": str(row[0]),
			"p0": start_progress,
			"p1": end_progress,
			"direction": int(row[3])
		})
		previous_end = end_progress
	return blocks


func _live_tape_regime_block_at(blocks: Array, progress: float) -> Dictionary:
	var selected: Dictionary = {}
	for block_value in blocks:
		if typeof(block_value) != TYPE_DICTIONARY:
			continue
		var block: Dictionary = block_value
		if progress >= float(block.get("p0", 0.0)) and progress <= float(block.get("p1", 1.0)):
			return block
		selected = block
	return selected


func _live_tape_regime_period(chart_profile: Dictionary) -> float:
	var period: float = 42.0
	match str(chart_profile.get("tape_regime_profile", "messy_accumulation")):
		"clean_trend":
			period = 54.0
		"operator_campaign":
			period = 26.0
		"distribution_breakdown":
			period = 34.0
		"failed_reclaim":
			period = 30.0
		_:
			period = 40.0
	match str(chart_profile.get("cycle_tempo_profile", "normal_setup")):
		"slow_setup":
			period += 10.0
		"fast_operator":
			period -= 8.0
		"failed_setup":
			period -= 4.0
	return clamp(period + clamp(float(chart_profile.get("regime_tempo_bias", 0.0)), -1.0, 1.0) * 8.0, 18.0, 68.0)


func _live_daily_tape_friction_context(
	chart_profile: Dictionary,
	price_bars: Array,
	run_seed: int,
	day_number: int,
	company_id: String
) -> Dictionary:
	var strength: float = _live_tape_friction_strength(chart_profile)
	if strength <= 0.0:
		return {"price_bias": 0.0, "volume_boost": 0.0, "pressure": 0.0, "phase": 0.0}
	var frequency_bias: float = clamp(float(chart_profile.get("microleg_frequency_bias", 0.55)), 0.0, 1.0)
	var disagreement_rate: float = clamp(float(chart_profile.get("volume_disagreement_rate", 0.36)), 0.0, 1.0)
	var wick_intensity: float = clamp(float(chart_profile.get("wick_noise_intensity", 0.42)), 0.0, 1.0)
	var friction_profile: String = str(chart_profile.get("bar_friction_profile", "balanced_chop"))
	var period: float = 7.0
	match friction_profile:
		"clean_liquid":
			period = lerp(10.0, 7.0, frequency_bias)
		"balanced_chop":
			period = lerp(7.0, 5.0, frequency_bias)
		"operator_dirty":
			period = lerp(5.2, 3.4, frequency_bias)
		"distribution_chop":
			period = lerp(6.4, 4.2, frequency_bias)
	var offset: float = _sim_noise(run_seed, company_id, "live_daily_tape_phase_offset", 0.0, 1.0, 1)
	var raw_phase: float = float(day_number) / max(period, 1.0) + offset
	var phase: float = raw_phase - floor(raw_phase)
	var trend_direction: int = _live_tape_trend_direction(chart_profile)
	var streak_state: Dictionary = _live_tape_direction_streak(price_bars)
	var streak_direction: int = int(streak_state.get("direction", 0))
	var streak_count: int = int(streak_state.get("count", 0))
	var run_limit: int = _live_tape_run_limit(chart_profile)
	var price_bias: float = 0.0
	var volume_boost: float = 0.0
	var counter_size: float = lerp(0.0012, 0.0039, strength)

	if trend_direction > 0:
		var shake_pulse: float = _live_microstructure_pulse(phase, 0.34, 0.17)
		var reclaim_pulse: float = _live_microstructure_pulse(phase, 0.54, 0.15)
		var shelf_pulse: float = _live_microstructure_pulse(phase, 0.78, 0.13)
		price_bias -= shake_pulse * counter_size
		price_bias += reclaim_pulse * counter_size * 0.52
		price_bias -= shelf_pulse * counter_size * 0.28
		volume_boost += shake_pulse * lerp(0.02, 0.20, strength)
		volume_boost -= shelf_pulse * lerp(0.02, 0.10, disagreement_rate)
	elif trend_direction < 0:
		var bounce_pulse: float = _live_microstructure_pulse(phase, 0.30, 0.16)
		var fail_pulse: float = _live_microstructure_pulse(phase, 0.52, 0.15)
		var continuation_pulse: float = _live_microstructure_pulse(phase, 0.72, 0.14)
		price_bias += bounce_pulse * counter_size * 0.58
		price_bias -= fail_pulse * counter_size * 0.52
		price_bias -= continuation_pulse * counter_size * 0.62
		volume_boost += (fail_pulse + continuation_pulse) * lerp(0.02, 0.18, strength)
	else:
		var chop_up: float = _live_microstructure_pulse(phase, 0.28, 0.18)
		var chop_down: float = _live_microstructure_pulse(phase, 0.62, 0.18)
		price_bias += chop_up * counter_size * 0.36
		price_bias -= chop_down * counter_size * 0.36
		volume_boost -= max(chop_up, chop_down) * lerp(0.02, 0.10, disagreement_rate)

	if streak_direction != 0 and streak_count >= run_limit:
		var guard_pressure: float = clamp(float(streak_count - run_limit + 1) / 3.0, 0.35, 1.0)
		price_bias += -float(streak_direction) * max(counter_size * 0.86 * guard_pressure, 0.0010)
		volume_boost += lerp(0.02, 0.16, strength) * guard_pressure

	var disagreement_roll: float = _sim_noise(run_seed, company_id, "live_daily_tape_volume_disagreement", 0.0, 1.0, day_number)
	if disagreement_roll < disagreement_rate:
		volume_boost += lerp(-0.08, 0.10, _sim_noise(run_seed, company_id, "live_daily_tape_disagreement_side", 0.0, 1.0, day_number))
	var operator_spike_roll: float = _sim_noise(run_seed, company_id, "live_daily_tape_operator_spike", 0.0, 1.0, day_number)
	if friction_profile == "operator_dirty" and operator_spike_roll > 0.80:
		volume_boost += lerp(0.10, 0.34, max(strength, wick_intensity))

	return {
		"price_bias": clamp(price_bias, -0.0038, 0.0038),
		"volume_boost": clamp(volume_boost, -0.16, 0.42),
		"pressure": strength,
		"phase": phase
	}


func _live_tape_friction_strength(chart_profile: Dictionary) -> float:
	var profile_id: String = str(chart_profile.get("bar_friction_profile", "balanced_chop"))
	var strength: float = 0.34
	match profile_id:
		"clean_liquid":
			strength = 0.18
		"balanced_chop":
			strength = 0.42
		"operator_dirty":
			strength = 0.62
		"distribution_chop":
			strength = 0.52
	strength += clamp(float(chart_profile.get("microleg_frequency_bias", 0.55)), 0.0, 1.0) * 0.08
	strength += clamp(float(chart_profile.get("wick_noise_intensity", 0.42)), 0.0, 1.0) * 0.05
	strength += clamp(float(chart_profile.get("operator_pressure", 0.0)), 0.0, 1.0) * 0.06
	return clamp(strength, 0.08, 0.76)


func _live_tape_run_limit(chart_profile: Dictionary) -> int:
	var profile_id: String = str(chart_profile.get("bar_friction_profile", "balanced_chop"))
	var limit: int = 5
	match profile_id:
		"clean_liquid":
			limit = 6
		"operator_dirty", "distribution_chop":
			limit = 4
		_:
			limit = 5
	if str(chart_profile.get("cycle_tempo_profile", "normal_setup")) == "fast_operator":
		limit -= 1
	if clamp(float(chart_profile.get("microleg_frequency_bias", 0.55)), 0.0, 1.0) >= 0.78:
		limit -= 1
	return int(clamp(limit, 3, 7))


func _live_tape_trend_direction(chart_profile: Dictionary) -> int:
	var cycle_template: String = str(chart_profile.get("cycle_template", ""))
	if cycle_template in ["markup_clean", "markup_exhaustion", "operator_markup"]:
		return 1
	if cycle_template in ["distribution_clean", "failed_markup", "operator_rug"]:
		return -1
	var bias: String = str(chart_profile.get("bias", "sideways"))
	if bias == "bullish":
		return 1
	if bias == "bearish":
		return -1
	return 0


func _live_tape_direction_streak(price_bars: Array) -> Dictionary:
	if price_bars.size() < 2:
		return {"direction": 0, "count": 0}
	var direction: int = 0
	var count: int = 0
	for index in range(price_bars.size() - 1, 0, -1):
		if typeof(price_bars[index]) != TYPE_DICTIONARY or typeof(price_bars[index - 1]) != TYPE_DICTIONARY:
			break
		var current_bar: Dictionary = price_bars[index]
		var previous_bar: Dictionary = price_bars[index - 1]
		var step_direction: int = _live_tape_direction_for_delta(float(current_bar.get("close", 0.0)) - float(previous_bar.get("close", 0.0)))
		if step_direction == 0:
			break
		if direction == 0:
			direction = step_direction
			count = 1
		elif step_direction == direction:
			count += 1
		else:
			break
	return {"direction": direction, "count": count}


func _live_tape_direction_for_delta(delta: float) -> int:
	if delta > 0.0001:
		return 1
	if delta < -0.0001:
		return -1
	return 0


func _live_microstructure_pulse(phase: float, center: float, width: float) -> float:
	var distance: float = absf(phase - center)
	distance = min(distance, 1.0 - distance)
	if width <= 0.0 or distance >= width:
		return 0.0
	var t: float = 1.0 - distance / width
	return t * t * (3.0 - 2.0 * t)


func _build_technical_structure_context(
	definition: Dictionary,
	runtime: Dictionary,
	event_bias: float,
	net_pressure: float,
	smart_money_pressure: float,
	player_abs_ratio: float,
	run_seed: int,
	day_number: int,
	company_id: String,
	chart_profile: Dictionary = {}
) -> Dictionary:
	if chart_profile.is_empty():
		chart_profile = _chart_profile_from_definition(definition, run_seed, company_id)
	var behavior: String = str(chart_profile.get("sma_behavior", "ignored"))
	var archetype: String = str(chart_profile.get("archetype", "range_bound"))
	var bias: String = str(chart_profile.get("bias", "sideways"))
	var period: int = int(chart_profile.get("preferred_sma_period", 20))
	var price_bars: Array = runtime.get("price_bars", [])
	var current_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var sma_value: float = _technical_average_close(price_bars, period)
	var price_bias: float = 0.0
	var volume_multiplier: float = 1.0

	if sma_value > 0.0 and behavior != "ignored":
		var distance: float = (current_price - sma_value) / max(sma_value, 1.0)
		if behavior == "support":
			if distance >= -0.055 and distance <= 0.028:
				price_bias = lerp(0.0012, 0.0060, clamp((0.028 - distance) / 0.083, 0.0, 1.0))
				volume_multiplier += 0.12
			elif distance < -0.085:
				price_bias = -0.0022
		elif behavior == "resistance":
			if distance >= -0.028 and distance <= 0.070:
				price_bias = -lerp(0.0012, 0.0060, clamp((distance + 0.028) / 0.098, 0.0, 1.0))
				volume_multiplier += 0.16
			elif distance > 0.105:
				price_bias = 0.0018
		elif behavior == "magnet" and absf(distance) <= 0.12:
			price_bias = clamp(-distance * 0.035, -0.0038, 0.0038)
	else:
		if bias == "bullish":
			price_bias = 0.0012
		elif bias == "bearish":
			price_bias = -0.0012

	if archetype == "gorengan":
		var fakeout_noise: float = _sim_noise(run_seed, company_id, "gorengan_technical_fakeout", -0.0052, 0.0052, day_number)
		price_bias += fakeout_noise
		volume_multiplier += 0.22 + absf(fakeout_noise) * 34.0
		var spike_roll: float = _sim_noise(run_seed, company_id, "gorengan_technical_spike", 0.0, 1.0, day_number)
		if spike_roll > 0.90:
			volume_multiplier += 1.65
	elif archetype == "accumulation" and price_bias > 0.0:
		volume_multiplier += 0.12
	elif archetype in ["distribution", "distressed"] and price_bias < 0.0:
		volume_multiplier += 0.18

	var cycle_template: String = str(chart_profile.get("cycle_template", ""))
	var cycle_strength: float = clamp(float(chart_profile.get("cycle_strength", 0.0)), 0.0, 1.0)
	var operator_pressure: float = clamp(float(chart_profile.get("operator_pressure", 0.0)), 0.0, 1.0)
	if not cycle_template.is_empty() and cycle_strength > 0.0:
		var recent_runup: float = max(_recent_price_change_from_bars(price_bars, 8), 0.0)
		match cycle_template:
			"markup_clean":
				price_bias += 0.0016 * cycle_strength
				volume_multiplier += 0.05 * cycle_strength
			"markup_exhaustion":
				price_bias += 0.0011 * cycle_strength - clamp(recent_runup * 0.018, 0.0, 0.0045)
				volume_multiplier += 0.10 * cycle_strength
			"distribution_clean":
				price_bias -= 0.0016 * cycle_strength
				volume_multiplier += 0.08 * cycle_strength
			"failed_markup":
				price_bias += 0.0008 * cycle_strength - clamp(recent_runup * 0.022, 0.0, 0.0055)
				volume_multiplier += 0.12 * cycle_strength
			"operator_markup":
				var operator_noise: float = _sim_noise(run_seed, company_id, "operator_markup_technical", -0.0018, 0.0048, day_number)
				price_bias += (0.0018 * cycle_strength) + operator_noise * operator_pressure
				volume_multiplier += 0.18 + operator_pressure * 0.26
			"operator_rug":
				var rug_noise: float = _sim_noise(run_seed, company_id, "operator_rug_technical", -0.0060, 0.0020, day_number)
				price_bias += rug_noise * max(operator_pressure, 0.45)
				price_bias -= clamp(recent_runup * 0.032 * max(operator_pressure, 0.45), 0.0, 0.0090)
				volume_multiplier += 0.22 + operator_pressure * 0.36

	var micro_context: Dictionary = _live_microstructure_context(chart_profile, price_bars, run_seed, day_number, company_id)
	price_bias += float(micro_context.get("price_bias", 0.0))
	volume_multiplier += float(micro_context.get("volume_boost", 0.0))

	var override_drag: float = (
		absf(event_bias) * 9.0 +
		absf(net_pressure) * 0.34 +
		absf(smart_money_pressure) * 0.30 +
		player_abs_ratio * 0.12
	)
	var override_factor: float = clamp(1.0 - override_drag, 0.22, 1.0)
	price_bias = clamp(price_bias * override_factor, -0.0065, 0.0065)
	return {
		"price_bias": price_bias,
		"volume_multiplier": clamp(volume_multiplier, 0.82, 3.2),
		"sma_period": period,
		"sma_behavior": behavior,
		"sma_value": sma_value
	}


func _chart_profile_from_definition(definition: Dictionary, run_seed: int, company_id: String) -> Dictionary:
	var traits: Dictionary = definition.get("generation_traits", {})
	var profile_value = traits.get("chart_profile", {})
	if typeof(profile_value) == TYPE_DICTIONARY and not profile_value.is_empty():
		var profile: Dictionary = profile_value.duplicate(true)
		if not profile.has("preferred_sma_period"):
			profile["preferred_sma_period"] = _derived_sma_period_for_chart_profile(traits, run_seed, company_id)
		if not profile.has("sma_behavior"):
			profile["sma_behavior"] = "support" if str(profile.get("bias", "sideways")) == "bullish" else "resistance"
		if not profile.has("archetype"):
			profile["archetype"] = "range_bound"
		if not profile.has("bias"):
			profile["bias"] = "sideways"
		return _chart_profile_with_gap_defaults(profile, traits, run_seed, company_id)
	return _derive_chart_profile_for_simulation(traits, run_seed, company_id)


func _derive_chart_profile_for_simulation(traits: Dictionary, run_seed: int, company_id: String) -> Dictionary:
	var story_heat: float = float(traits.get("story_heat", 0.5))
	var float_tightness: float = float(traits.get("float_tightness", 0.5))
	var liquidity_profile: float = float(traits.get("liquidity_profile", 0.5))
	var balance_sheet_strength: float = float(traits.get("balance_sheet_strength", 0.5))
	var growth_engine: float = float(traits.get("growth_engine", 0.5))
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "chart_profile_sim_fallback", company_id])
	var archetype: String = "range_bound"
	if story_heat >= 0.66 and float_tightness >= 0.54 and liquidity_profile <= 0.58:
		archetype = "gorengan"
	elif balance_sheet_strength >= 0.62 and growth_engine >= 0.58:
		archetype = "organic"
	elif balance_sheet_strength <= 0.34:
		archetype = "distressed"
	elif rng.randf() < 0.34:
		archetype = "accumulation"
	var bias: String = "sideways"
	if archetype in ["organic", "accumulation"]:
		bias = "bullish"
	elif archetype == "distressed":
		bias = "bearish"
	elif archetype == "gorengan":
		bias = ["bullish", "bearish", "sideways"][rng.randi_range(0, 2)]
	var behavior: String = "ignored"
	if bias == "bullish":
		behavior = "support"
	elif bias == "bearish":
		behavior = "resistance"
	elif archetype == "range_bound":
		behavior = "magnet"
	var profile: Dictionary = {
		"archetype": archetype,
		"bias": bias,
		"sma_behavior": behavior,
		"preferred_sma_period": _derived_sma_period_for_chart_profile(traits, run_seed, company_id)
	}
	return _chart_profile_with_gap_defaults(profile, traits, run_seed, company_id)


func _chart_profile_with_gap_defaults(
	profile: Dictionary,
	traits: Dictionary,
	run_seed: int,
	company_id: String
) -> Dictionary:
	var normalized: Dictionary = profile.duplicate(true)
	var archetype: String = str(normalized.get("archetype", "range_bound"))
	var bias: String = str(normalized.get("bias", "sideways"))
	var story_heat: float = clamp(float(traits.get("story_heat", 0.5)), 0.0, 1.0)
	var float_tightness: float = clamp(float(traits.get("float_tightness", 0.5)), 0.0, 1.0)
	var liquidity_profile: float = clamp(float(traits.get("liquidity_profile", 0.5)), 0.0, 1.0)
	var quality_core: float = clamp(float(traits.get("balance_sheet_strength", 0.5)), 0.0, 1.0)
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "chart_profile_gap_sim_defaults", company_id])
	if not normalized.has("chart_intent") or str(normalized.get("chart_intent", "")).is_empty():
		normalized["chart_intent"] = _sim_chart_intent_for(archetype, bias, story_heat, quality_core, rng)
	if not normalized.has("pattern_timeframe") or str(normalized.get("pattern_timeframe", "")).is_empty():
		normalized["pattern_timeframe"] = _sim_chart_pattern_timeframe_for(str(normalized.get("chart_intent", "")), archetype, story_heat, rng)
	if not normalized.has("gap_style") or not CHART_GAP_STYLES.has(str(normalized.get("gap_style", ""))):
		normalized["gap_style"] = _sim_chart_gap_style_for(str(normalized.get("chart_intent", "")), archetype, bias, story_heat, rng)
	if not normalized.has("gap_bias") or not CHART_GAP_BIASES.has(str(normalized.get("gap_bias", ""))):
		normalized["gap_bias"] = _sim_chart_gap_bias_for(archetype, bias, str(normalized.get("gap_style", "")))
	if not normalized.has("gap_frequency") or not CHART_GAP_FREQUENCIES.has(str(normalized.get("gap_frequency", ""))):
		normalized["gap_frequency"] = _sim_chart_gap_frequency_for(str(normalized.get("chart_intent", "")), archetype, story_heat, float_tightness)
	if not normalized.has("gap_followthrough") or not CHART_GAP_FOLLOWTHROUGH.has(str(normalized.get("gap_followthrough", ""))):
		normalized["gap_followthrough"] = _sim_chart_gap_followthrough_for(str(normalized.get("gap_style", "")), bias, rng)
	_apply_live_tape_friction_defaults(normalized, archetype, bias, story_heat, float_tightness, liquidity_profile)
	return normalized


func _apply_live_tape_friction_defaults(
	chart_profile: Dictionary,
	archetype: String,
	bias: String,
	story_heat: float,
	float_tightness: float,
	liquidity_profile: float
) -> void:
	if not chart_profile.has("bar_friction_profile") or not CHART_BAR_FRICTION_PROFILES.has(str(chart_profile.get("bar_friction_profile", ""))):
		var operator_pressure: float = clamp(float(chart_profile.get("operator_pressure", 0.0)), 0.0, 1.0)
		if str(chart_profile.get("cycle_template", "")).begins_with("operator") or archetype == "gorengan" or operator_pressure >= 0.62:
			chart_profile["bar_friction_profile"] = "operator_dirty"
		elif bias == "bearish" or archetype in ["distribution", "distressed"]:
			chart_profile["bar_friction_profile"] = "distribution_chop"
		elif liquidity_profile >= 0.62 and float_tightness <= 0.40 and story_heat <= 0.56:
			chart_profile["bar_friction_profile"] = "clean_liquid"
		else:
			chart_profile["bar_friction_profile"] = "balanced_chop"
	var friction_profile: String = str(chart_profile.get("bar_friction_profile", "balanced_chop"))
	if not chart_profile.has("microleg_frequency_bias"):
		match friction_profile:
			"clean_liquid":
				chart_profile["microleg_frequency_bias"] = 0.26
			"operator_dirty":
				chart_profile["microleg_frequency_bias"] = 0.78
			"distribution_chop":
				chart_profile["microleg_frequency_bias"] = 0.66
			_:
				chart_profile["microleg_frequency_bias"] = 0.56
	if not chart_profile.has("wick_noise_intensity"):
		match friction_profile:
			"clean_liquid":
				chart_profile["wick_noise_intensity"] = 0.14
			"operator_dirty":
				chart_profile["wick_noise_intensity"] = 0.52
			"distribution_chop":
				chart_profile["wick_noise_intensity"] = 0.42
			_:
				chart_profile["wick_noise_intensity"] = 0.32
	if not chart_profile.has("volume_disagreement_rate"):
		match friction_profile:
			"clean_liquid":
				chart_profile["volume_disagreement_rate"] = 0.18
			"operator_dirty":
				chart_profile["volume_disagreement_rate"] = 0.58
			"distribution_chop":
				chart_profile["volume_disagreement_rate"] = 0.48
			_:
				chart_profile["volume_disagreement_rate"] = 0.38
	chart_profile["microleg_frequency_bias"] = clamp(float(chart_profile.get("microleg_frequency_bias", 0.56)), 0.0, 1.0)
	chart_profile["wick_noise_intensity"] = clamp(float(chart_profile.get("wick_noise_intensity", 0.32)), 0.0, 1.0)
	chart_profile["volume_disagreement_rate"] = clamp(float(chart_profile.get("volume_disagreement_rate", 0.38)), 0.0, 1.0)
	_apply_live_tape_regime_defaults(chart_profile, archetype, bias, story_heat, float_tightness, liquidity_profile)


func _apply_live_tape_regime_defaults(
	chart_profile: Dictionary,
	archetype: String,
	bias: String,
	story_heat: float,
	float_tightness: float,
	liquidity_profile: float
) -> void:
	var operator_pressure: float = clamp(float(chart_profile.get("operator_pressure", 0.0)), 0.0, 1.0)
	if not chart_profile.has("tape_regime_profile") or not CHART_TAPE_REGIME_PROFILES.has(str(chart_profile.get("tape_regime_profile", ""))):
		var cycle_template: String = str(chart_profile.get("cycle_template", ""))
		var friction_profile: String = str(chart_profile.get("bar_friction_profile", "balanced_chop"))
		if cycle_template == "failed_markup":
			chart_profile["tape_regime_profile"] = "failed_reclaim"
		elif cycle_template == "distribution_clean" or bias == "bearish" or archetype in ["distribution", "distressed"]:
			chart_profile["tape_regime_profile"] = "distribution_breakdown"
		elif cycle_template.begins_with("operator") or friction_profile == "operator_dirty" or archetype == "gorengan" or operator_pressure >= 0.62:
			chart_profile["tape_regime_profile"] = "operator_campaign"
		elif liquidity_profile >= 0.64 and float_tightness <= 0.42 and story_heat <= 0.56 and operator_pressure <= 0.34:
			chart_profile["tape_regime_profile"] = "clean_trend"
		else:
			chart_profile["tape_regime_profile"] = "messy_accumulation"
	if not chart_profile.has("regime_block_intensity"):
		match str(chart_profile.get("tape_regime_profile", "messy_accumulation")):
			"clean_trend":
				chart_profile["regime_block_intensity"] = 0.26
			"operator_campaign":
				chart_profile["regime_block_intensity"] = 0.62
			"distribution_breakdown":
				chart_profile["regime_block_intensity"] = 0.54
			"failed_reclaim":
				chart_profile["regime_block_intensity"] = 0.56
			_:
				chart_profile["regime_block_intensity"] = 0.48
	if not chart_profile.has("regime_tempo_bias"):
		var tempo_bias: float = 0.0
		match str(chart_profile.get("cycle_tempo_profile", "normal_setup")):
			"slow_setup":
				tempo_bias = 0.24
			"fast_operator":
				tempo_bias = -0.30
			"failed_setup":
				tempo_bias = 0.08
		tempo_bias -= operator_pressure * 0.12
		tempo_bias += liquidity_profile * 0.08
		chart_profile["regime_tempo_bias"] = tempo_bias
	chart_profile["regime_block_intensity"] = clamp(float(chart_profile.get("regime_block_intensity", 0.48)), 0.0, 1.0)
	chart_profile["regime_tempo_bias"] = clamp(float(chart_profile.get("regime_tempo_bias", 0.0)), -1.0, 1.0)


func _sim_chart_intent_for(
	archetype: String,
	bias: String,
	story_heat: float,
	quality_core: float,
	rng: RandomNumberGenerator
) -> String:
	if archetype == "funda" or (quality_core >= 0.68 and story_heat < 0.62):
		return "investing"
	if archetype in ["accumulation", "cyclical"]:
		return "swing_trading"
	if archetype == "gorengan":
		return "speculative" if rng.randf() < 0.52 + story_heat * 0.22 else "short_term_trading"
	if archetype in ["distressed", "distribution"]:
		return "short_term_trading" if bias == "bearish" else "swing_trading"
	return "swing_trading" if rng.randf() < 0.58 else "short_term_trading"


func _sim_chart_pattern_timeframe_for(
	chart_intent: String,
	archetype: String,
	story_heat: float,
	rng: RandomNumberGenerator
) -> String:
	match chart_intent:
		"investing":
			return "5y" if rng.randf() < 0.48 else "1y"
		"swing_trading":
			return "6m" if rng.randf() < 0.58 else "1y"
		"short_term_trading":
			return "1m" if story_heat > 0.68 and rng.randf() < 0.45 else "3m"
		"speculative":
			return "1m" if archetype == "gorengan" and rng.randf() < 0.58 else "3m"
	return "1y"


func _sim_chart_gap_style_for(
	chart_intent: String,
	archetype: String,
	bias: String,
	story_heat: float,
	rng: RandomNumberGenerator
) -> String:
	if chart_intent == "investing" or archetype == "funda":
		return "news_gap" if rng.randf() < 0.62 else "none"
	if archetype == "gorengan" or chart_intent == "speculative":
		return ["mixed", "rug_gap", "breakout_gap"][rng.randi_range(0, 2)]
	if bias == "bullish" or archetype == "accumulation":
		return "breakout_gap" if rng.randf() < 0.72 + story_heat * 0.12 else "news_gap"
	if bias == "bearish" or archetype in ["distressed", "distribution"]:
		return "rug_gap" if rng.randf() < 0.46 + story_heat * 0.15 else "exhaustion_gap"
	return "mixed" if rng.randf() < 0.56 else "news_gap"


func _sim_chart_gap_bias_for(archetype: String, bias: String, gap_style: String) -> String:
	if gap_style == "breakout_gap":
		return "up"
	if gap_style in ["rug_gap", "exhaustion_gap"]:
		return "down"
	if archetype == "gorengan":
		return "mixed"
	if bias == "bullish":
		return "up"
	if bias == "bearish":
		return "down"
	return "mixed"


func _sim_chart_gap_frequency_for(
	chart_intent: String,
	archetype: String,
	story_heat: float,
	float_tightness: float
) -> String:
	if chart_intent == "investing":
		return "rare"
	if (archetype == "gorengan" or chart_intent == "speculative") and story_heat + float_tightness >= 1.42:
		return "active"
	if story_heat + float_tightness >= 1.48:
		return "active"
	if chart_intent in ["swing_trading", "short_term_trading"]:
		return "moderate"
	return "rare"


func _sim_chart_gap_followthrough_for(gap_style: String, bias: String, rng: RandomNumberGenerator) -> String:
	if gap_style == "breakout_gap":
		return "continue" if rng.randf() < 0.48 or bias == "bullish" else "hold"
	if gap_style in ["rug_gap", "exhaustion_gap"]:
		return "continue" if bias == "bearish" and rng.randf() < 0.42 else "fade"
	if gap_style == "mixed":
		return "fade" if rng.randf() < 0.54 else "fill"
	return "hold" if rng.randf() < 0.45 else "fill"


func _live_chart_gap_bias(
	chart_profile: Dictionary,
	daily_change_pct: float,
	event_bias: float,
	broker_flow: Dictionary,
	volume_context: Dictionary,
	run_seed: int,
	day_number: int,
	company_id: String
) -> float:
	var gap_style: String = str(chart_profile.get("gap_style", "none"))
	if gap_style == "none":
		return 0.0
	var frequency: String = str(chart_profile.get("gap_frequency", "rare"))
	var trigger_threshold: float = 0.982
	if frequency == "moderate":
		trigger_threshold = 0.925
	elif frequency == "active":
		trigger_threshold = 0.845
	var event_intensity: float = absf(event_bias)
	var activity_ratio: float = max(float(volume_context.get("expected_activity_ratio", 1.0)), 0.0)
	trigger_threshold -= clamp(event_intensity * 1.2 + max(activity_ratio - 1.45, 0.0) * 0.020, 0.0, 0.10)
	var trigger_roll: float = _sim_noise(run_seed, company_id, "live_chart_gap_trigger", 0.0, 1.0, day_number)
	if trigger_roll < trigger_threshold:
		return 0.0

	var direction: int = _live_chart_gap_direction(chart_profile, daily_change_pct, event_bias, broker_flow, run_seed, day_number, company_id)
	if direction == 0:
		return 0.0
	var magnitude_low: float = 0.006
	var magnitude_high: float = 0.020
	if frequency == "moderate":
		magnitude_low = 0.008
		magnitude_high = 0.025
	elif frequency == "active":
		magnitude_low = 0.012
		magnitude_high = 0.036
	if gap_style == "rug_gap":
		magnitude_high += 0.014
	elif gap_style == "breakout_gap":
		magnitude_high += 0.008
	elif gap_style == "mixed":
		magnitude_high += 0.005
	var magnitude: float = _sim_noise(
		run_seed,
		company_id,
		"live_chart_gap_magnitude",
		magnitude_low,
		magnitude_high,
		day_number
	)
	magnitude *= 1.0 + clamp(event_intensity * 4.5 + max(activity_ratio - 1.4, 0.0) * 0.10, 0.0, 0.62)
	return clamp(float(direction) * magnitude, -0.055, 0.055)


func _live_chart_gap_direction(
	chart_profile: Dictionary,
	daily_change_pct: float,
	event_bias: float,
	broker_flow: Dictionary,
	run_seed: int,
	day_number: int,
	company_id: String
) -> int:
	var net_pressure: float = clamp(float(broker_flow.get("net_pressure", 0.0)), -1.0, 1.0)
	if absf(event_bias) >= 0.024:
		return 1 if event_bias > 0.0 else -1
	if absf(net_pressure) >= 0.58:
		return 1 if net_pressure > 0.0 else -1
	if absf(daily_change_pct) >= 0.045:
		return 1 if daily_change_pct > 0.0 else -1
	var gap_bias: String = str(chart_profile.get("gap_bias", "mixed"))
	if gap_bias == "up":
		return 1
	if gap_bias == "down":
		return -1
	var gap_style: String = str(chart_profile.get("gap_style", "none"))
	if gap_style == "breakout_gap":
		return 1
	if gap_style in ["rug_gap", "exhaustion_gap"]:
		return -1
	var direction_roll: float = _sim_noise(run_seed, company_id, "live_chart_gap_direction", 0.0, 1.0, day_number)
	return 1 if direction_roll >= 0.5 else -1


func _derived_sma_period_for_chart_profile(traits: Dictionary, run_seed: int, company_id: String) -> int:
	var periods: Array = [3, 5, 10, 20, 60, 100, 200]
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "chart_profile_sma_fallback", company_id])
	var balance_sheet_strength: float = float(traits.get("balance_sheet_strength", 0.5))
	if balance_sheet_strength >= 0.62:
		periods = [20, 60, 100, 200]
	elif float(traits.get("story_heat", 0.5)) >= 0.66:
		periods = [3, 5, 10, 20]
	return int(periods[rng.randi_range(0, periods.size() - 1)])


func _technical_average_close(price_bars: Array, period: int) -> float:
	if period <= 0 or price_bars.size() < period:
		return 0.0
	var total: float = 0.0
	for bar_index in range(price_bars.size() - period, price_bars.size()):
		var bar: Dictionary = price_bars[bar_index]
		total += float(bar.get("close", 0.0))
	return total / float(period)


func _sim_noise(run_seed: int, company_id: String, key: String, min_value: float, max_value: float, salt: int) -> float:
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, key, company_id, salt])
	return rng.randf_range(min_value, max_value)


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
	broker_flow: Dictionary,
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
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "bar", day_number, company_id])

	var limit_lock: String = str(close_context.get("limit_lock", ""))
	var limit_source: String = str(close_context.get("limit_source", ""))
	var chart_profile: Dictionary = _chart_profile_from_definition(definition, run_seed, company_id)
	var technical_gap_bias: float = _live_chart_gap_bias(
		chart_profile,
		daily_change_pct,
		event_bias,
		broker_flow,
		volume_context,
		run_seed,
		day_number,
		company_id
	)
	var gap_bias: float = clamp(
		(daily_change_pct * 0.32) +
		(event_bias * 0.18) +
		(market_sentiment * 0.08) +
		(sector_sentiment * 0.1) +
		technical_gap_bias,
		-0.10,
		0.10
	)
	var gap_noise: float = rng.randf_range(-0.012, 0.012)
	var open_raw: float = previous_close * (1.0 + gap_bias + gap_noise)
	var open_price: float = clamp(
		IDX_PRICE_RULES.snap_price_for_day(open_raw, previous_close),
		float(ar_limits.get("lower_price", 1.0)),
		float(ar_limits.get("upper_price", previous_close))
	)

	var candle_profile: Dictionary = _build_candle_profile(
		rng,
		daily_change_pct,
		market_sentiment,
		sector_sentiment,
		event_bias,
		broker_flow,
		volume_context,
		player_flow_context,
		market_depth_context
	)
	var open_close_blend: float = float(candle_profile.get("open_close_blend", 0.0))
	if open_close_blend > 0.0:
		open_price = clamp(
			IDX_PRICE_RULES.snap_price_for_day(lerp(open_price, current_price, open_close_blend), previous_close),
			float(ar_limits.get("lower_price", 1.0)),
			float(ar_limits.get("upper_price", previous_close))
		)
	if limit_lock.is_empty():
		var body_context: Dictionary = _reconcile_live_candle_body_intent(
			chart_profile,
			volume_context,
			previous_close,
			open_price,
			current_price,
			daily_change_pct,
			event_bias,
			ar_limits,
			run_seed,
			day_number,
			company_id
		)
		open_price = float(body_context.get("open", open_price))
		current_price = float(body_context.get("close", current_price))

	var activity_span_boost: float = clamp(
		(max(float(volume_context.get("expected_activity_ratio", 1.0)) - 1.0, 0.0) * 0.11) +
		(max(float(volume_context.get("volume_multiplier", 1.0)) - 1.0, 0.0) * 0.035) +
		(absf(float(player_flow_context.get("depth_impact_ratio", 0.0))) * 0.045),
		0.0,
		0.85
	)
	var intraday_span_pct: float = max(
		absf(daily_change_pct) * 0.65,
		float(definition.get("base_volatility", 0.02)) * 0.42,
		0.004
	) * float(candle_profile.get("span_multiplier", 1.0)) * (1.0 + activity_span_boost)
	var upper_probe: float = max(open_price, current_price) * (
		1.0 + rng.randf_range(
			float(candle_profile.get("upper_min", 0.12)),
			float(candle_profile.get("upper_max", 0.75))
		) * intraday_span_pct
	)
	var lower_probe: float = min(open_price, current_price) * (
		1.0 - rng.randf_range(
			float(candle_profile.get("lower_min", 0.12)),
			float(candle_profile.get("lower_max", 0.75))
		) * intraday_span_pct
	)
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
		candle_profile["id"] = "limit_ara"
	elif limit_lock == "arb":
		open_price = previous_close
		high_price = max(previous_close, current_price)
		low_price = float(ar_limits.get("lower_price", current_price))
		current_price = low_price
		candle_profile["id"] = "limit_arb"

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
		"candle_archetype": str(candle_profile.get("id", "neutral")),
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


func _reconcile_live_candle_body_intent(
	chart_profile: Dictionary,
	volume_context: Dictionary,
	previous_close: float,
	open_price: float,
	close_price: float,
	daily_change_pct: float,
	event_bias: float,
	ar_limits: Dictionary,
	run_seed: int,
	day_number: int,
	company_id: String
) -> Dictionary:
	var intended_direction: int = _live_candle_body_intent_direction(chart_profile, volume_context, daily_change_pct, event_bias)
	if intended_direction == 0:
		return {"open": open_price, "close": close_price, "intended_direction": 0}
	var structural_direction: int = _live_tape_direction_for_delta(close_price - previous_close)
	if structural_direction != 0:
		intended_direction = structural_direction
	var body_direction: int = _live_tape_direction_for_delta(close_price - open_price)
	if body_direction == intended_direction:
		return {"open": open_price, "close": close_price, "intended_direction": intended_direction}

	var gap_ratio: float = (open_price - previous_close) / max(previous_close, 1.0)

	var tick_size: float = IDX_PRICE_RULES.tick_size_for_reference_price(previous_close)
	var lower_price: float = float(ar_limits.get("lower_price", 1.0))
	var upper_price: float = float(ar_limits.get("upper_price", previous_close))
	var adjusted_open: float = open_price
	var adjusted_close: float = close_price
	if intended_direction > 0:
		if gap_ratio > 0.0 and adjusted_close >= previous_close:
			adjusted_open = IDX_PRICE_RULES.snap_price_for_day(min(adjusted_open, max(previous_close, adjusted_close - tick_size)), previous_close)
		if adjusted_close <= adjusted_open:
			adjusted_close = IDX_PRICE_RULES.snap_price_for_day(max(adjusted_close, adjusted_open + tick_size), previous_close)
		if adjusted_close <= adjusted_open:
			adjusted_open = IDX_PRICE_RULES.snap_price_for_day(min(adjusted_open, adjusted_close - tick_size), previous_close)
	elif intended_direction < 0:
		if gap_ratio < 0.0 and adjusted_close <= previous_close:
			adjusted_open = IDX_PRICE_RULES.snap_price_for_day(max(adjusted_open, min(previous_close, adjusted_close + tick_size)), previous_close)
		if adjusted_close >= adjusted_open:
			adjusted_close = IDX_PRICE_RULES.snap_price_for_day(min(adjusted_close, adjusted_open - tick_size), previous_close)
		if adjusted_close >= adjusted_open:
			adjusted_open = IDX_PRICE_RULES.snap_price_for_day(max(adjusted_open, adjusted_close + tick_size), previous_close)

	adjusted_open = clamp(IDX_PRICE_RULES.normalize_last_price(adjusted_open), lower_price, upper_price)
	adjusted_close = clamp(IDX_PRICE_RULES.normalize_last_price(adjusted_close), lower_price, upper_price)
	return {
		"open": adjusted_open,
		"close": adjusted_close,
		"intended_direction": intended_direction
	}


func _live_candle_body_intent_direction(
	chart_profile: Dictionary,
	volume_context: Dictionary,
	daily_change_pct: float,
	event_bias: float
) -> int:
	if absf(daily_change_pct) >= 0.003:
		return _live_tape_direction_for_delta(daily_change_pct)
	if absf(event_bias) >= 0.006:
		return _live_tape_direction_for_delta(event_bias)
	var accumulation_signal: float = float(volume_context.get("accumulation_signal", 0.0))
	var distribution_signal: float = float(volume_context.get("distribution_signal", 0.0))
	if accumulation_signal - distribution_signal > 0.14:
		return 1
	if distribution_signal - accumulation_signal > 0.14:
		return -1
	var technical_bias: float = (
		float(volume_context.get("technical_price_bias", 0.0)) +
		float(volume_context.get("lead_price_bias", 0.0)) +
		float(volume_context.get("buying_exhaustion_drag", 0.0)) +
		float(volume_context.get("distribution_drag", 0.0))
	)
	if absf(technical_bias) >= 0.0018:
		return _live_tape_direction_for_delta(technical_bias)
	return _live_tape_trend_direction(chart_profile)


func _build_candle_profile(
	rng: RandomNumberGenerator,
	daily_change_pct: float,
	market_sentiment: float,
	sector_sentiment: float,
	event_bias: float,
	broker_flow: Dictionary,
	volume_context: Dictionary,
	player_flow_context: Dictionary,
	market_depth_context: Dictionary
) -> Dictionary:
	var broker_pressure: float = clamp(float(broker_flow.get("net_pressure", 0.0)), -1.0, 1.0)
	var smart_money_pressure: float = clamp(float(broker_flow.get("smart_money_pressure", 0.0)), -1.0, 1.0)
	var accumulation_signal: float = clamp(float(volume_context.get("accumulation_signal", 0.0)), 0.0, 1.0)
	var distribution_signal: float = clamp(float(volume_context.get("distribution_signal", 0.0)), 0.0, 1.0)
	var exhaustion_score: float = clamp(float(volume_context.get("buying_exhaustion_score", 0.0)), 0.0, 1.0)
	var expected_activity_ratio: float = max(float(volume_context.get("expected_activity_ratio", 1.0)), 0.0)
	var volume_multiplier: float = max(float(volume_context.get("volume_multiplier", 1.0)), 0.0)
	var player_depth_pressure: float = clamp(float(player_flow_context.get("depth_impact_ratio", 0.0)), -3.0, 3.0)
	var float_tightness: float = clamp(float(market_depth_context.get("float_tightness", 0.0)), 0.0, 1.0)
	var pressure_score: float = clamp(
		(daily_change_pct * 7.0) +
		(event_bias * 5.0) +
		(market_sentiment * 2.0) +
		(sector_sentiment * 2.0) +
		(broker_pressure * 0.55) +
		(smart_money_pressure * 0.25) +
		(accumulation_signal * 0.50) -
		(distribution_signal * 0.58) +
		(player_depth_pressure * 0.22),
		-2.4,
		2.4
	)
	var abs_change: float = absf(daily_change_pct)
	var active_tape: bool = expected_activity_ratio >= 1.55 or volume_multiplier >= 1.85
	var quiet_tape: bool = expected_activity_ratio <= 1.12 and volume_multiplier <= 1.18

	if exhaustion_score >= 0.58 and pressure_score > -0.55:
		return _candle_profile("upper_rejection", 0.95, 2.35, 0.04, 0.38, 1.15 + float_tightness * 0.16)
	if distribution_signal >= 0.56 and daily_change_pct <= 0.012:
		return _candle_profile("distribution_selloff", 0.08, 0.48, 0.58, 1.50, 1.08 + distribution_signal * 0.22)
	if accumulation_signal >= 0.56 and daily_change_pct >= -0.010:
		return _candle_profile("accumulation_bid", 0.18, 0.72, 0.05, 0.35, 1.02 + accumulation_signal * 0.16)
	if daily_change_pct <= -0.016 and distribution_signal < 0.40 and (accumulation_signal >= 0.24 or rng.randf() < 0.42):
		return _candle_profile("lower_absorption", 0.05, 0.40, 0.90, 2.30, 1.12 + float_tightness * 0.16)
	if abs_change <= 0.0065 and quiet_tape and rng.randf() < 0.64:
		return _candle_profile("compressed_doji", 0.08, 0.34, 0.08, 0.34, 0.62, rng.randf_range(0.38, 0.66))
	if active_tape and abs_change <= 0.020 and rng.randf() < 0.34:
		return _candle_profile("wide_range_chop", 0.55, 1.55, 0.55, 1.55, 1.24)
	if pressure_score >= 0.35:
		return _candle_profile("trend_up", 0.14, 0.68, 0.06, 0.36, 1.00)
	if pressure_score <= -0.35:
		return _candle_profile("trend_down", 0.06, 0.38, 0.16, 0.78, 1.00)
	return _candle_profile("neutral", 0.18, 0.86, 0.18, 0.86, 0.95)


func _candle_profile(
	profile_id: String,
	upper_min: float,
	upper_max: float,
	lower_min: float,
	lower_max: float,
	span_multiplier: float = 1.0,
	open_close_blend: float = 0.0
) -> Dictionary:
	return {
		"id": profile_id,
		"upper_min": upper_min,
		"upper_max": max(upper_max, upper_min),
		"lower_min": lower_min,
		"lower_max": max(lower_max, lower_min),
		"span_multiplier": max(span_multiplier, 0.25),
		"open_close_blend": clamp(open_close_blend, 0.0, 0.85)
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
