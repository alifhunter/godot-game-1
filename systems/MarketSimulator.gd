extends RefCounted

const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")


func simulate_day(run_state, data_repository, broker_flow_system) -> Dictionary:
	var day_number: int = int(run_state.day_index) + 1
	var difficulty_config: Dictionary = run_state.get_difficulty_config()
	var market_sentiment: float = _sample_market_sentiment(
		run_state.run_seed,
		day_number,
		float(difficulty_config.get("market_swing_range", 0.02))
	)
	var sector_sentiments: Dictionary = _build_sector_sentiments(
		data_repository.get_sector_definitions(),
		run_state.run_seed,
		day_number,
		market_sentiment,
		float(difficulty_config.get("volatility_multiplier", 1.0))
	)
	var scheduled_event: Dictionary = _build_daily_event_plan(
		run_state,
		sector_sentiments,
		market_sentiment,
		day_number,
		difficulty_config
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
			scheduled_event
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
			difficulty_config
		)
		var raw_price: float = previous_close * (1.0 + daily_change_pct)
		var ar_limits: Dictionary = IDX_PRICE_RULES.auto_rejection_limits(previous_close, listing_board)
		var current_price: float = IDX_PRICE_RULES.snap_price_for_day(raw_price, previous_close)
		current_price = clamp(
			current_price,
			float(ar_limits.get("lower_price", 1.0)),
			float(ar_limits.get("upper_price", current_price))
		)
		daily_change_pct = 0.0
		if not is_zero_approx(previous_close):
			daily_change_pct = (current_price - previous_close) / previous_close
		var price_history: Array = runtime.get("price_history", []).duplicate()
		price_history.append(current_price)
		if price_history.size() > 12:
			price_history = price_history.slice(price_history.size() - 12, price_history.size())

		runtime["previous_close"] = previous_close
		runtime["current_price"] = current_price
		runtime["price_history"] = price_history
		runtime["sentiment"] = daily_change_pct
		runtime["active_event_tags"] = event_context.get("event_tags", []).duplicate()
		runtime["hidden_story_flags"] = event_context.get("hidden_story_flags", []).duplicate()
		runtime["broker_flow"] = broker_flow
		runtime["daily_change_pct"] = daily_change_pct
		runtime["ar_limits"] = ar_limits.duplicate(true)

		companies_result[company_id] = runtime

	return {
		"market_sentiment": market_sentiment,
		"companies": companies_result,
		"starting_equity": run_state.get_total_equity(),
		"scheduled_event": scheduled_event.duplicate(true)
	}


func _sample_market_sentiment(run_seed: int, day_number: int, swing_range: float) -> float:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|market|%s" % [run_seed, day_number]))
	return rng.randf_range(-swing_range, swing_range)


func _build_sector_sentiments(
	sectors: Array,
	run_seed: int,
	day_number: int,
	market_sentiment: float,
	volatility_multiplier: float
) -> Dictionary:
	var sector_sentiments: Dictionary = {}

	for sector in sectors:
		var sector_id: String = str(sector.get("id", ""))
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = int(hash("%s|sector|%s|%s" % [run_seed, day_number, sector_id]))
		var trend_bias: float = float(sector.get("trend_bias", 0.0))
		var volatility_bias: float = float(sector.get("volatility_bias", 0.0)) * volatility_multiplier
		sector_sentiments[sector_id] = market_sentiment + trend_bias + rng.randf_range(-volatility_bias, volatility_bias)

	return sector_sentiments


func _build_daily_event_plan(
	run_state,
	sector_sentiments: Dictionary,
	market_sentiment: float,
	day_number: int,
	difficulty_config: Dictionary
) -> Dictionary:
	var event_interval_days: float = max(float(difficulty_config.get("event_interval_days", 30.0)), 1.0)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|daily_event|%s" % [run_state.run_seed, day_number]))

	if rng.randf() >= (1.0 / event_interval_days):
		return {}

	var candidates: Array = []
	if market_sentiment < -0.015:
		candidates.append({
			"event_id": "risk_off_headline",
			"scope": "market",
			"weight": 1.0 + clamp(abs(market_sentiment) * 8.0, 0.0, 0.45)
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

	var company_definitions: Array = run_state.get_effective_company_definitions()
	if not company_definitions.is_empty():
		var target_definition: Dictionary = company_definitions[rng.randi_range(0, company_definitions.size() - 1)]
		var target_company_id: String = str(target_definition.get("id", ""))
		var target_runtime: Dictionary = run_state.get_company(target_company_id)
		var quality: float = float(target_definition.get("quality_score", 50.0))
		var risk: float = float(target_definition.get("risk_score", 50.0))
		var narrative_tags: Array = target_definition.get("narrative_tags", [])
		var recent_sentiment: float = float(target_runtime.get("daily_change_pct", target_runtime.get("sentiment", 0.0)))
		var positive_probability: float = 0.34
		positive_probability += clamp((quality - risk) / 200.0, -0.08, 0.12)
		positive_probability -= clamp(max(recent_sentiment, 0.0) * 2.5, 0.0, 0.12)
		positive_probability += clamp(max(-recent_sentiment, 0.0) * 1.25, 0.0, 0.06)
		if "retail_favorite" in narrative_tags:
			positive_probability += 0.04
		if "commodity_beta" in narrative_tags or "policy_beta" in narrative_tags:
			positive_probability -= 0.03
		positive_probability = clamp(positive_probability, 0.22, 0.55)
		var company_event_id: String = "rumor_wave_negative"
		var company_weight: float = 1.0 + clamp(abs(recent_sentiment) * 8.0, 0.0, 0.35)

		if rng.randf() < positive_probability:
			company_event_id = "favorable_coverage"
			company_weight = 0.85 + clamp((quality - risk) / 120.0, 0.0, 0.25)
			if "retail_favorite" in narrative_tags and rng.randf() < 0.35:
				company_event_id = "rumor_wave_positive"
				company_weight += 0.05
		else:
			company_event_id = "rumor_wave_negative"
			company_weight = 1.0 + clamp((risk - quality) / 120.0, 0.0, 0.25)
			company_weight += clamp(max(recent_sentiment, 0.0) * 3.0, 0.0, 0.2)

		candidates.append({
			"event_id": company_event_id,
			"scope": "company",
			"target_company_id": target_company_id,
			"weight": company_weight
		})

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
	scheduled_event: Dictionary
) -> Dictionary:
	var event_tags: Array = []
	var hidden_story_flags: Array = runtime.get("hidden_story_flags", []).duplicate()
	var event_bias: float = 0.0
	var company_id: String = str(definition.get("id", ""))
	var sector_id: String = str(sector_definition.get("id", ""))

	if _event_applies_to_company(scheduled_event, company_id, sector_id):
		var event_id: String = str(scheduled_event.get("event_id", ""))
		if not event_id.is_empty():
			event_tags.append(event_id)
			event_bias += float(DataRepository.get_event_definition(event_id).get("sentiment_shift", 0.0))

	return {
		"event_tags": event_tags,
		"event_bias": event_bias,
		"hidden_story_flags": hidden_story_flags,
		"sector_id": str(sector_definition.get("id", ""))
	}


func _event_applies_to_company(scheduled_event: Dictionary, company_id: String, sector_id: String) -> bool:
	if scheduled_event.is_empty():
		return false

	var scope: String = str(scheduled_event.get("scope", "company"))
	if scope == "market":
		return true
	if scope == "sector":
		return str(scheduled_event.get("target_sector_id", "")) == sector_id
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
	difficulty_config: Dictionary
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
	) * volatility_multiplier
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
