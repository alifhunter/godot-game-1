extends RefCounted

const BROKER_KEYS := [
	"retail_net",
	"foreign_net",
	"institution_net",
	"bandar_net",
	"zombie_net"
]
const TOP_BROKER_ROW_COUNT := 10
const STABLE_RNG = preload("res://systems/StableRng.gd")


func generate_day_flow(definition: Dictionary, runtime: Dictionary, context: Dictionary, _data_repository = null) -> Dictionary:
	var quality: float = float(definition.get("quality_score", 50.0)) / 100.0
	var growth: float = float(definition.get("growth_score", 50.0)) / 100.0
	var risk: float = float(definition.get("risk_score", 50.0)) / 100.0
	var recent_momentum: float = float(context.get("recent_momentum", 0.0))
	var event_bias: float = float(context.get("event_bias", 0.0))
	var market_sentiment: float = float(context.get("market_sentiment", 0.0))
	var sector_sentiment: float = float(context.get("sector_sentiment", 0.0))
	var narrative_tags: Array = definition.get("narrative_tags", [])
	var hidden_flags: Array = runtime.get("hidden_story_flags", [])
	var quiet_range: bool = abs(recent_momentum) < 0.012 and abs(event_bias) < 0.02
	var free_float_ratio: float = clamp(float(definition.get("financials", {}).get("free_float_pct", 35.0)) / 100.0, 0.08, 0.95)
	var scarcity_score: float = clamp((0.55 - free_float_ratio) / 0.45, 0.0, 1.0)

	var retail_bonus: float = 0.0
	if "retail_favorite" in narrative_tags or "narrative_hot" in narrative_tags:
		retail_bonus += 0.14
	if "smart_money_distribution" in hidden_flags:
		retail_bonus += 0.08
	var retail_score: float = clamp(
		(recent_momentum * 6.0) +
		(event_bias * 4.6) +
		retail_bonus +
		_sample_noise(context, "retail", -0.2, 0.2),
		-1.0,
		1.0
	)

	var foreign_bonus: float = 0.0
	if "foreign_watchlist" in narrative_tags:
		foreign_bonus += 0.16
	if "stealth_interest" in narrative_tags:
		foreign_bonus += 0.08
	if "smart_money_distribution" in hidden_flags:
		foreign_bonus -= 0.08
	var foreign_score: float = clamp(
		(market_sentiment * 1.8) +
		(sector_sentiment * 2.4) +
		(growth * 0.25) -
		(risk * 0.3) +
		(recent_momentum * 1.6) -
		(max(recent_momentum, 0.0) * 1.0) +
		foreign_bonus +
		_sample_noise(context, "foreign", -0.16, 0.16),
		-1.0,
		1.0
	)

	var institution_bonus: float = 0.0
	if "institution_quality" in narrative_tags:
		institution_bonus += 0.18
	if "supportive_balance_sheet" in narrative_tags:
		institution_bonus += 0.12
	if "smart_money_distribution" in hidden_flags:
		institution_bonus -= 0.06
	var institution_score: float = clamp(
		(quality * 0.55) -
		(risk * 0.52) -
		(max(recent_momentum, 0.0) * 2.7) +
		(max(-recent_momentum, 0.0) * 1.6) +
		(event_bias * 1.4) +
		institution_bonus +
		_sample_noise(context, "institution", -0.12, 0.12),
		-1.0,
		1.0
	)

	var bandar_bonus: float = 0.0
	if "smart_money_accumulation" in hidden_flags:
		bandar_bonus += 0.24
	if "smart_money_distribution" in hidden_flags:
		bandar_bonus -= 0.24
	if "stealth_interest" in hidden_flags:
		bandar_bonus += 0.14
	if "quiet_execution" in narrative_tags:
		bandar_bonus += 0.08
	if "retail_favorite" in narrative_tags:
		bandar_bonus += 0.06
	if recent_momentum > 0.03:
		bandar_bonus -= 0.10
	elif recent_momentum < -0.03:
		bandar_bonus += 0.06
	var bandar_score: float = clamp(
		(event_bias * 1.45) +
		(sector_sentiment * 0.55) +
		(market_sentiment * 0.24) +
		(recent_momentum * 0.32) +
		(scarcity_score * 0.18) +
		bandar_bonus +
		_sample_noise(context, "bandar", -0.18, 0.18),
		-1.0,
		1.0
	)

	var zombie_bonus: float = 0.0
	if quiet_range:
		zombie_bonus += 0.12
	if "stealth_interest" in hidden_flags:
		zombie_bonus += 0.16
	if "smart_money_accumulation" in hidden_flags:
		zombie_bonus += 0.18
	if "smart_money_distribution" in hidden_flags:
		zombie_bonus -= 0.18
	if "quiet_execution" in narrative_tags:
		zombie_bonus += 0.10
	if "retail_favorite" in narrative_tags:
		zombie_bonus -= 0.12
	if recent_momentum > 0.02:
		zombie_bonus -= 0.16
	elif recent_momentum < -0.02:
		zombie_bonus += 0.08
	var zombie_score: float = clamp(
		(event_bias * 0.92) +
		(sector_sentiment * 0.42) +
		zombie_bonus +
		_sample_noise(context, "zombie", -0.18, 0.18),
		-1.0,
		1.0
	)

	var raw_scores: Dictionary = {
		"retail_net": round(retail_score * 100.0),
		"foreign_net": round(foreign_score * 100.0),
		"institution_net": round(institution_score * 100.0),
		"bandar_net": round(bandar_score * 100.0),
		"zombie_net": round(zombie_score * 100.0)
	}
	var player_flow: Dictionary = context.get("player_flow", {})
	var player_impact_ratio: float = clamp(float(player_flow.get("impact_ratio", 0.0)), -1.0, 1.0)
	var player_depth_impact_ratio: float = clamp(float(player_flow.get("depth_impact_ratio", 0.0)), -1.0, 1.0)
	if not is_zero_approx(player_impact_ratio):
		raw_scores["retail_net"] = clamp(float(raw_scores.get("retail_net", 0.0)) + player_impact_ratio * 42.0, -100.0, 100.0)
		raw_scores["bandar_net"] = clamp(float(raw_scores.get("bandar_net", 0.0)) + player_impact_ratio * 16.0, -100.0, 100.0)
	if not is_zero_approx(player_depth_impact_ratio):
		raw_scores["retail_net"] = clamp(float(raw_scores.get("retail_net", 0.0)) + player_depth_impact_ratio * 26.0, -100.0, 100.0)
		raw_scores["bandar_net"] = clamp(float(raw_scores.get("bandar_net", 0.0)) + player_depth_impact_ratio * 10.0, -100.0, 100.0)
	var net_pressure: float = 0.0
	for key in BROKER_KEYS:
		net_pressure += float(raw_scores.get(key, 0.0))
	net_pressure /= float(max(BROKER_KEYS.size(), 1) * 100)

	var smart_money_pressure: float = clamp(
		(
			(float(raw_scores.get("foreign_net", 0.0)) * 0.20) +
			(float(raw_scores.get("institution_net", 0.0)) * 0.18) +
			(float(raw_scores.get("bandar_net", 0.0)) * 0.37) +
			(float(raw_scores.get("zombie_net", 0.0)) * 0.25)
		) / 100.0,
		-1.0,
		1.0
	)
	var flow_tag: String = _flow_tag(net_pressure)
	var action_meter_score: float = clamp(net_pressure, -1.0, 1.0)
	var action_meter_label: String = _meter_label_for_score(net_pressure)
	var player_limit_lock: String = str(player_flow.get("limit_lock", ""))
	if player_limit_lock == "ara":
		flow_tag = "accumulation"
		action_meter_score = max(action_meter_score, 0.92)
		action_meter_label = "XL ARA Lock"
	elif player_limit_lock == "arb":
		flow_tag = "distribution"
		action_meter_score = min(action_meter_score, -0.92)
		action_meter_label = "XL ARB Lock"

	return {
		"retail_net": raw_scores["retail_net"],
		"foreign_net": raw_scores["foreign_net"],
		"institution_net": raw_scores["institution_net"],
		"bandar_net": raw_scores["bandar_net"],
		"zombie_net": raw_scores["zombie_net"],
		"net_pressure": clamp(net_pressure, -1.0, 1.0),
		"smart_money_pressure": smart_money_pressure,
		"dominant_buyer": _dominant_buyer(raw_scores),
		"dominant_seller": _dominant_seller(raw_scores),
		"dominant_buy_broker_code": "",
		"dominant_buy_broker_name": "",
		"dominant_buy_broker_type": "",
		"dominant_sell_broker_code": "",
		"dominant_sell_broker_name": "",
		"dominant_sell_broker_type": "",
		"flow_tag": flow_tag,
		"action_meter_score": action_meter_score,
		"action_meter_label": action_meter_label,
		"player_flow": player_flow.duplicate(true),
		"player_impact_summary": str(player_flow.get("impact_summary", "")),
		"limit_lock": player_limit_lock,
		"limit_source": str(player_flow.get("limit_source", "")),
		"buy_brokers": [],
		"sell_brokers": [],
		"broker_type_totals": {},
		"net_buy_brokers": [],
		"net_sell_brokers": []
	}


func finalize_day_flow(
	definition: Dictionary,
	runtime: Dictionary,
	context: Dictionary,
	broker_flow: Dictionary,
	price_bar: Dictionary,
	current_price: float,
	data_repository
) -> Dictionary:
	var final_flow: Dictionary = broker_flow.duplicate(true)
	if data_repository == null or not data_repository.has_method("get_broker_roster"):
		return final_flow

	var broker_roster: Array = data_repository.get_broker_roster()
	if broker_roster.is_empty():
		return final_flow

	var broker_tape: Dictionary = _build_broker_tape(
		definition,
		runtime,
		context,
		final_flow,
		price_bar,
		current_price,
		broker_roster
	)
	for key in broker_tape.keys():
		final_flow[key] = broker_tape[key]
	return final_flow


func _build_broker_tape(
	definition: Dictionary,
	runtime: Dictionary,
	context: Dictionary,
	broker_flow: Dictionary,
	price_bar: Dictionary,
	current_price: float,
	broker_roster: Array
) -> Dictionary:
	var trade_value: float = max(float(price_bar.get("value", 0.0)), current_price * 1000.0)
	var trade_shares: float = max(float(price_bar.get("volume_shares", 0)), 100.0)
	var recent_momentum: float = float(context.get("recent_momentum", 0.0))
	var event_bias: float = float(context.get("event_bias", 0.0))
	var market_sentiment: float = float(context.get("market_sentiment", 0.0))
	var sector_sentiment: float = float(context.get("sector_sentiment", 0.0))
	var quality: float = float(definition.get("quality_score", 50.0)) / 100.0
	var growth: float = float(definition.get("growth_score", 50.0)) / 100.0
	var risk: float = float(definition.get("risk_score", 50.0)) / 100.0
	var narrative_tags: Array = definition.get("narrative_tags", [])
	var hidden_flags: Array = runtime.get("hidden_story_flags", [])
	var quiet_range: bool = abs(recent_momentum) < 0.012 and abs(event_bias) < 0.02
	var day_low: float = float(price_bar.get("low", current_price))
	var day_high: float = float(price_bar.get("high", current_price))
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))

	var broker_rows: Array = []
	var buy_weight_total: float = 0.0
	var sell_weight_total: float = 0.0
	for broker_value in broker_roster:
		var broker: Dictionary = broker_value
		var side_weights: Dictionary = _derive_broker_side_weights(
			broker,
			definition,
			runtime,
			broker_flow,
			current_price,
			recent_momentum,
			event_bias,
			market_sentiment,
			sector_sentiment,
			quality,
			growth,
			risk,
			narrative_tags,
			hidden_flags,
			quiet_range,
			context
		)
		var broker_row: Dictionary = broker.duplicate(true)
		broker_row["buy_weight"] = float(side_weights.get("buy_weight", 1.0))
		broker_row["sell_weight"] = float(side_weights.get("sell_weight", 1.0))
		broker_row["activity_score"] = float(side_weights.get("activity_score", 0.0))
		broker_rows.append(broker_row)
		buy_weight_total += float(broker_row.get("buy_weight", 0.0))
		sell_weight_total += float(broker_row.get("sell_weight", 0.0))

	if buy_weight_total <= 0.0:
		buy_weight_total = float(max(broker_rows.size(), 1))
	if sell_weight_total <= 0.0:
		sell_weight_total = float(max(broker_rows.size(), 1))

	for broker_row_value in broker_rows:
		var row: Dictionary = broker_row_value
		var buy_weight: float = float(row.get("buy_weight", 0.0))
		var sell_weight: float = float(row.get("sell_weight", 0.0))
		var buy_value: float = trade_value * (buy_weight / buy_weight_total)
		var sell_value: float = trade_value * (sell_weight / sell_weight_total)
		var buy_avg_price: float = _derive_broker_average_price(
			row,
			"buy",
			current_price,
			day_low,
			day_high,
			flow_tag,
			context
		)
		var sell_avg_price: float = _derive_broker_average_price(
			row,
			"sell",
			current_price,
			day_low,
			day_high,
			flow_tag,
			context
		)
		row["buy_value"] = buy_value
		row["sell_value"] = sell_value
		row["buy_avg_price"] = buy_avg_price
		row["sell_avg_price"] = sell_avg_price
		row["buy_lots"] = max((buy_value / max(buy_avg_price, 1.0)) / 100.0, 0.0)
		row["sell_lots"] = max((sell_value / max(sell_avg_price, 1.0)) / 100.0, 0.0)
		row["buy_shares"] = max((buy_value / max(buy_avg_price, 1.0)), 0.0)
		row["sell_shares"] = max((sell_value / max(sell_avg_price, 1.0)), 0.0)

	_inject_player_flow_into_broker_rows(broker_rows, context.get("player_flow", {}), current_price)
	var broker_type_totals: Dictionary = _build_broker_type_totals(broker_rows)

	var buy_ranked: Array = broker_rows.duplicate(true)
	var sell_ranked: Array = broker_rows.duplicate(true)
	buy_ranked.sort_custom(_sort_broker_buy_rows)
	sell_ranked.sort_custom(_sort_broker_sell_rows)

	var top_buy_brokers: Array = []
	var top_sell_brokers: Array = []
	var net_buy_ranked: Array = []
	var net_sell_ranked: Array = []
	var max_rows: int = min(TOP_BROKER_ROW_COUNT, broker_rows.size())
	for broker_row_value in broker_rows:
		var broker_row: Dictionary = broker_row_value
		var net_snapshot: Dictionary = _build_broker_net_snapshot(broker_row)
		if net_snapshot.is_empty():
			continue
		if str(net_snapshot.get("net_side", "")) == "buy":
			net_buy_ranked.append(net_snapshot)
		else:
			net_sell_ranked.append(net_snapshot)
	net_buy_ranked.sort_custom(_sort_broker_net_rows)
	net_sell_ranked.sort_custom(_sort_broker_net_rows)
	for index in range(max_rows):
		top_buy_brokers.append(_build_broker_side_snapshot(buy_ranked[index], "buy"))
		top_sell_brokers.append(_build_broker_side_snapshot(sell_ranked[index], "sell"))
	var top_net_buy_brokers: Array = []
	var top_net_sell_brokers: Array = []
	for index in range(min(TOP_BROKER_ROW_COUNT, net_buy_ranked.size())):
		top_net_buy_brokers.append(net_buy_ranked[index].duplicate(true))
	for index in range(min(TOP_BROKER_ROW_COUNT, net_sell_ranked.size())):
		top_net_sell_brokers.append(net_sell_ranked[index].duplicate(true))

	var dominant_buy: Dictionary = top_buy_brokers[0] if not top_buy_brokers.is_empty() else {}
	var dominant_sell: Dictionary = top_sell_brokers[0] if not top_sell_brokers.is_empty() else {}
	var action_meter_score: float = _derive_action_meter_score(broker_flow, broker_rows, trade_value)
	var action_meter_label: String = _meter_label_for_score(action_meter_score)
	var limit_lock: String = str(broker_flow.get("limit_lock", ""))
	if limit_lock == "ara":
		action_meter_score = max(action_meter_score, 0.92)
		action_meter_label = "XL ARA Lock"
	elif limit_lock == "arb":
		action_meter_score = min(action_meter_score, -0.92)
		action_meter_label = "XL ARB Lock"

	return {
		"buy_brokers": top_buy_brokers,
		"sell_brokers": top_sell_brokers,
		"broker_trade_value": trade_value,
		"broker_trade_shares": trade_shares,
		"dominant_buy_broker_code": str(dominant_buy.get("code", "")),
		"dominant_buy_broker_name": str(dominant_buy.get("company_name", "")),
		"dominant_buy_broker_type": str(dominant_buy.get("broker_type", "")),
		"dominant_sell_broker_code": str(dominant_sell.get("code", "")),
		"dominant_sell_broker_name": str(dominant_sell.get("company_name", "")),
		"dominant_sell_broker_type": str(dominant_sell.get("broker_type", "")),
		"action_meter_score": action_meter_score,
		"action_meter_label": action_meter_label,
		"broker_type_totals": broker_type_totals,
		"net_buy_brokers": top_net_buy_brokers,
		"net_sell_brokers": top_net_sell_brokers
	}


func _inject_player_flow_into_broker_rows(broker_rows: Array, player_flow: Dictionary, current_price: float) -> void:
	var broker_code: String = str(player_flow.get("broker_code", ""))
	if broker_code.is_empty():
		return

	var player_buy_value: float = max(float(player_flow.get("buy_value", 0.0)), 0.0)
	var player_sell_value: float = max(float(player_flow.get("sell_value", 0.0)), 0.0)
	if player_buy_value <= 0.0 and player_sell_value <= 0.0:
		return

	var target_row: Dictionary = {}
	for broker_row_value in broker_rows:
		var broker_row: Dictionary = broker_row_value
		if str(broker_row.get("code", "")) == broker_code:
			target_row = broker_row
			break
	if target_row.is_empty():
		target_row = {
			"code": broker_code,
			"company_name": str(player_flow.get("broker_name", "Player Broker")),
			"broker_type": "retail",
			"personality_tags": ["player", "retail_facing"],
			"buy_weight": 0.0,
			"sell_weight": 0.0,
			"activity_score": 0.0,
			"buy_value": 0.0,
			"sell_value": 0.0,
			"buy_shares": 0.0,
			"sell_shares": 0.0,
			"buy_avg_price": current_price,
			"sell_avg_price": current_price,
			"buy_lots": 0.0,
			"sell_lots": 0.0
		}
		broker_rows.append(target_row)

	if player_buy_value > 0.0:
		var previous_buy_value: float = float(target_row.get("buy_value", 0.0))
		var previous_buy_avg: float = float(target_row.get("buy_avg_price", current_price))
		var next_buy_value: float = previous_buy_value + player_buy_value
		target_row["buy_avg_price"] = ((previous_buy_avg * previous_buy_value) + (current_price * player_buy_value)) / max(next_buy_value, 1.0)
		target_row["buy_value"] = next_buy_value
		target_row["buy_shares"] = float(target_row.get("buy_shares", 0.0)) + max(float(player_flow.get("buy_shares", 0.0)), player_buy_value / max(current_price, 1.0))
		target_row["buy_lots"] = float(target_row.get("buy_shares", 0.0)) / 100.0
	if player_sell_value > 0.0:
		var previous_sell_value: float = float(target_row.get("sell_value", 0.0))
		var previous_sell_avg: float = float(target_row.get("sell_avg_price", current_price))
		var next_sell_value: float = previous_sell_value + player_sell_value
		target_row["sell_avg_price"] = ((previous_sell_avg * previous_sell_value) + (current_price * player_sell_value)) / max(next_sell_value, 1.0)
		target_row["sell_value"] = next_sell_value
		target_row["sell_shares"] = float(target_row.get("sell_shares", 0.0)) + max(float(player_flow.get("sell_shares", 0.0)), player_sell_value / max(current_price, 1.0))
		target_row["sell_lots"] = float(target_row.get("sell_shares", 0.0)) / 100.0
	target_row["player_flow"] = true


func _build_broker_type_totals(broker_rows: Array) -> Dictionary:
	var totals: Dictionary = {}
	for broker_row_value in broker_rows:
		var broker_row: Dictionary = broker_row_value
		var broker_type: String = str(broker_row.get("broker_type", "retail"))
		if broker_type.is_empty():
			broker_type = "retail"
		if not totals.has(broker_type):
			totals[broker_type] = {
				"buy_value": 0.0,
				"sell_value": 0.0,
				"buy_lots": 0.0,
				"sell_lots": 0.0,
				"buy_shares": 0.0,
				"sell_shares": 0.0,
				"net_value": 0.0,
				"net_lots": 0.0
			}
		var type_total: Dictionary = totals[broker_type]
		type_total["buy_value"] = float(type_total.get("buy_value", 0.0)) + max(float(broker_row.get("buy_value", 0.0)), 0.0)
		type_total["sell_value"] = float(type_total.get("sell_value", 0.0)) + max(float(broker_row.get("sell_value", 0.0)), 0.0)
		type_total["buy_lots"] = float(type_total.get("buy_lots", 0.0)) + max(float(broker_row.get("buy_lots", 0.0)), 0.0)
		type_total["sell_lots"] = float(type_total.get("sell_lots", 0.0)) + max(float(broker_row.get("sell_lots", 0.0)), 0.0)
		type_total["buy_shares"] = float(type_total.get("buy_shares", 0.0)) + max(float(broker_row.get("buy_shares", 0.0)), 0.0)
		type_total["sell_shares"] = float(type_total.get("sell_shares", 0.0)) + max(float(broker_row.get("sell_shares", 0.0)), 0.0)
		type_total["net_value"] = float(type_total.get("buy_value", 0.0)) - float(type_total.get("sell_value", 0.0))
		type_total["net_lots"] = float(type_total.get("buy_lots", 0.0)) - float(type_total.get("sell_lots", 0.0))
	return totals


func _derive_broker_side_weights(
	broker: Dictionary,
	definition: Dictionary,
	runtime: Dictionary,
	broker_flow: Dictionary,
	current_price: float,
	recent_momentum: float,
	event_bias: float,
	market_sentiment: float,
	sector_sentiment: float,
	quality: float,
	growth: float,
	risk: float,
	narrative_tags: Array,
	hidden_flags: Array,
	quiet_range: bool,
	context: Dictionary
) -> Dictionary:
	var broker_type: String = str(broker.get("broker_type", "retail"))
	var tags: Array = broker.get("personality_tags", [])
	var interest_profile: Dictionary = _derive_broker_interest_profile(
		broker,
		definition,
		runtime,
		current_price,
		recent_momentum,
		event_bias,
		market_sentiment,
		sector_sentiment,
		quality,
		growth,
		risk,
		narrative_tags,
		hidden_flags,
		quiet_range,
		context
	)
	var type_score: float = _broker_type_score(broker_flow, broker_type)
	var volatility_read: float = abs(recent_momentum) + abs(event_bias) + abs(sector_sentiment)
	var buy_weight: float = 4.0 + max(type_score, 0.0) * 0.10
	var sell_weight: float = 4.0 + max(-type_score, 0.0) * 0.10

	if "market_maker" in tags:
		var maker_bonus: float = 2.4 + (volatility_read * 18.0)
		buy_weight += maker_bonus
		sell_weight += maker_bonus
	if "quiet_accumulator" in tags:
		buy_weight += 1.4 + (2.0 if quiet_range else 0.7) + max(event_bias, 0.0) * 10.0
		sell_weight += max(-event_bias, 0.0) * 2.2
	if "quality_buyer" in tags:
		buy_weight += (quality * 4.4) + max(-recent_momentum, 0.0) * 14.0 + max(growth - 0.5, 0.0) * 4.0
		sell_weight += max(risk - 0.55, 0.0) * 2.4
	if "smart_money" in tags:
		buy_weight += max(type_score, 0.0) * 0.08 + max(event_bias, 0.0) * 12.0 + max(sector_sentiment, 0.0) * 5.0
		sell_weight += max(-type_score, 0.0) * 0.08 + max(-event_bias, 0.0) * 12.0 + max(-sector_sentiment, 0.0) * 5.0
	if "speculative" in tags:
		var speculative_bonus: float = 1.8 + (volatility_read * 12.0)
		buy_weight += speculative_bonus + max(recent_momentum, 0.0) * 8.0
		sell_weight += speculative_bonus + max(-recent_momentum, 0.0) * 8.0
	if "distributor" in tags:
		sell_weight += 2.8 + max(recent_momentum, 0.0) * 18.0 + max(-event_bias, 0.0) * 8.0
	if "dumb_money" in tags:
		buy_weight += max(recent_momentum, 0.0) * 20.0 + max(event_bias, 0.0) * 9.0
		sell_weight += max(-recent_momentum, 0.0) * 20.0 + max(-event_bias, 0.0) * 9.0
	if "follow_the_wave" in tags:
		buy_weight += max(recent_momentum, 0.0) * 16.0
		sell_weight += max(-recent_momentum, 0.0) * 16.0
	if "retail_facing" in tags:
		buy_weight += 1.2 + max(recent_momentum, 0.0) * 8.0
		sell_weight += 1.2 + max(-recent_momentum, 0.0) * 8.0
	if "defensive" in tags:
		buy_weight += (quality * 1.8) + max(-market_sentiment, 0.0) * 8.0 + max(-recent_momentum, 0.0) * 6.0
		sell_weight += max(risk, 0.0) * 2.4 + max(-event_bias, 0.0) * 6.0
	if "government" in tags:
		buy_weight += (quality * 1.4) + max(-market_sentiment, 0.0) * 10.0
	if "evil_to_retail" in tags:
		sell_weight += max(recent_momentum, 0.0) * 18.0 + max(event_bias, 0.0) * 6.0
		buy_weight += max(-recent_momentum, 0.0) * 7.0
	if "robotic" in tags:
		buy_weight += (quality * 1.4) + max(type_score, 0.0) * 0.05
		sell_weight += max(-type_score, 0.0) * 0.05 + max(risk, 0.0) * 0.8
	if "trading" in tags:
		var trading_bonus: float = 1.4 + (volatility_read * 8.0)
		buy_weight += trading_bonus
		sell_weight += trading_bonus
	if "retail" in tags:
		buy_weight += max(recent_momentum, 0.0) * 6.0
		sell_weight += max(-recent_momentum, 0.0) * 6.0

	if "smart_money_accumulation" in hidden_flags:
		if "smart_money" in tags or "quiet_accumulator" in tags or broker_type in ["bandar", "zombie"]:
			buy_weight += 3.2
		if "dumb_money" in tags:
			sell_weight += 0.8
	if "smart_money_distribution" in hidden_flags:
		if "smart_money" in tags or "distributor" in tags or broker_type == "bandar":
			sell_weight += 3.4
		if "dumb_money" in tags:
			buy_weight += 1.1
	if "stealth_interest" in hidden_flags and ("quiet_accumulator" in tags or broker_type in ["foreign", "zombie"]):
		buy_weight += 2.0
	if "quiet_execution" in narrative_tags and "market_maker" in tags:
		buy_weight += 0.9
		sell_weight += 0.9
	if "retail_favorite" in narrative_tags and "dumb_money" in tags:
		buy_weight += 2.2
	if "narrative_hot" in narrative_tags and ("follow_the_wave" in tags or "speculative" in tags):
		buy_weight += 1.8

	var noise_rng: RandomNumberGenerator = STABLE_RNG.rng(["broker-weight", context.get("company_id", ""), broker.get("code", "")])
	buy_weight *= noise_rng.randf_range(0.92, 1.08)
	sell_weight *= noise_rng.randf_range(0.92, 1.08)
	buy_weight *= float(interest_profile.get("buy_multiplier", 1.0))
	sell_weight *= float(interest_profile.get("sell_multiplier", 1.0))

	return {
		"buy_weight": max(buy_weight, float(interest_profile.get("minimum_weight", 0.18))),
		"sell_weight": max(sell_weight, float(interest_profile.get("minimum_weight", 0.18))),
		"activity_score": max(buy_weight + sell_weight, 1.0)
	}


func _derive_broker_interest_profile(
	broker: Dictionary,
	definition: Dictionary,
	_runtime: Dictionary,
	current_price: float,
	recent_momentum: float,
	event_bias: float,
	market_sentiment: float,
	_sector_sentiment: float,
	quality: float,
	growth: float,
	_risk: float,
	narrative_tags: Array,
	hidden_flags: Array,
	quiet_range: bool,
	context: Dictionary
) -> Dictionary:
	var broker_type: String = str(broker.get("broker_type", "retail"))
	var tags: Array = broker.get("personality_tags", [])
	var financials: Dictionary = definition.get("financials", {})
	var market_cap: float = max(float(financials.get("market_cap", current_price * 1000000000.0)), current_price * 1000000.0)
	var avg_daily_value: float = max(float(financials.get("avg_daily_value", current_price * 250000.0)), current_price * 1000.0)
	var free_float_ratio: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, 0.07, 0.85)
	var listing_board: String = str(definition.get("listing_board", "main"))
	var sector_id: String = str(definition.get("sector_id", "consumer"))
	var liquidity_score: float = clamp((log(avg_daily_value) - 14.0) / 6.0, 0.0, 1.0)
	var size_score: float = clamp((log(market_cap) - 20.0) / 8.0, 0.0, 1.0)
	var float_tightness: float = clamp((0.48 - free_float_ratio) / 0.40, 0.0, 1.0)
	var cheapness_score: float = clamp((log(5000.0) - log(max(current_price, 50.0))) / 3.6, 0.0, 1.0)
	var retail_heat: float = 0.0
	var accumulation_setup: float = 0.0
	var distribution_setup: float = 0.0

	if "retail_favorite" in narrative_tags:
		retail_heat += 0.24
	if "narrative_hot" in narrative_tags:
		retail_heat += 0.22
	retail_heat += clamp(max(recent_momentum, 0.0) * 8.0, 0.0, 0.28)
	retail_heat += clamp(max(event_bias, 0.0) * 6.0, 0.0, 0.18)
	retail_heat += cheapness_score * 0.10
	retail_heat = clamp(retail_heat, 0.0, 1.0)

	if "smart_money_accumulation" in hidden_flags:
		accumulation_setup += 0.34
	if "stealth_interest" in hidden_flags:
		accumulation_setup += 0.24
	if quiet_range:
		accumulation_setup += 0.12
	accumulation_setup += max(event_bias, 0.0) * 0.18
	accumulation_setup += float_tightness * 0.18
	accumulation_setup = clamp(accumulation_setup, 0.0, 1.0)

	if "smart_money_distribution" in hidden_flags:
		distribution_setup += 0.34
	if "narrative_hot" in narrative_tags:
		distribution_setup += 0.08
	distribution_setup += max(recent_momentum, 0.0) * 0.20
	distribution_setup += max(-event_bias, 0.0) * 0.18
	distribution_setup += retail_heat * 0.12
	distribution_setup = clamp(distribution_setup, 0.0, 1.0)

	var sector_quality_bias: float = 0.0
	if sector_id in ["consumer", "finance", "health", "infra", "noncyclical"]:
		sector_quality_bias = 0.08
	elif sector_id in ["tech", "property", "transport", "basicindustry", "industrial"]:
		sector_quality_bias = -0.05

	var coverage: float = _broker_coverage_score(broker_type, tags)
	var fit: float = 0.34
	match broker_type:
		"foreign":
			fit += (quality * 0.22) + (liquidity_score * 0.18) + (size_score * 0.15) - (float_tightness * 0.05)
		"institution":
			fit += (quality * 0.28) + (liquidity_score * 0.20) + (size_score * 0.16) + max(-market_sentiment, 0.0) * 0.12
		"retail":
			fit += (retail_heat * 0.44) + (cheapness_score * 0.16) + ((1.0 - size_score) * 0.08)
		"bandar":
			fit += (float_tightness * 0.32) + ((1.0 - liquidity_score) * 0.18) + (retail_heat * 0.14) + (accumulation_setup * 0.18)
		"zombie":
			fit += (float_tightness * 0.30) + ((1.0 - liquidity_score) * 0.22) + (accumulation_setup * 0.18)
			if quiet_range:
				fit += 0.16
		_:
			fit += 0.0

	if "quality_buyer" in tags:
		fit += (quality * 0.20) + (growth * 0.08) + sector_quality_bias
	if "quiet_accumulator" in tags:
		fit += (accumulation_setup * 0.24) + (float_tightness * 0.10)
	if "smart_money" in tags:
		fit += (accumulation_setup * 0.14) + max(-recent_momentum, 0.0) * 0.10
	if "market_maker" in tags:
		fit += (float_tightness * 0.06) + ((1.0 - liquidity_score) * 0.06)
	if "speculative" in tags:
		fit += (retail_heat * 0.12) + (abs(recent_momentum) * 0.08) + ((1.0 - size_score) * 0.08)
	if "distributor" in tags:
		fit += distribution_setup * 0.22
	if "dumb_money" in tags or "follow_the_wave" in tags:
		fit += (retail_heat * 0.22) + max(recent_momentum, 0.0) * 0.12
	if "retail_facing" in tags:
		fit += retail_heat * 0.16
	if "defensive" in tags:
		fit += (quality * 0.12) + max(-market_sentiment, 0.0) * 0.16
	if "government" in tags:
		fit += (quality * 0.08) + (size_score * 0.10)
	if "evil_to_retail" in tags:
		fit += (distribution_setup * 0.20) + (retail_heat * 0.08)

	if listing_board == "development":
		if broker_type in ["retail", "bandar", "zombie"]:
			fit += 0.12
		elif broker_type in ["foreign", "institution"]:
			fit -= 0.08
	else:
		if broker_type in ["foreign", "institution"]:
			fit += 0.05
		elif broker_type == "retail":
			fit -= 0.02

	fit = clamp(fit, 0.10, 1.45)

	var coverage_roll: float = _sample_static_broker_value(context, broker.get("code", ""), "coverage")
	var conviction_roll: float = _sample_static_broker_value(context, broker.get("code", ""), "conviction")
	var daily_variation: float = _sample_broker_day_noise(context, broker.get("code", ""), 0.96, 1.04)
	var selective: bool = (
		broker_type in ["bandar", "zombie"] or
		("quiet_accumulator" in tags and broker_type != "foreign") or
		(coverage < 0.42)
	)
	var control_score: float = 0.0
	if selective:
		var control_gate: float = clamp(0.76 - (fit * 0.28) - (coverage * 0.18), 0.34, 0.84)
		control_score = clamp((conviction_roll - control_gate) / max(0.12, 1.0 - control_gate), 0.0, 1.0)
	else:
		control_score = clamp((conviction_roll * 0.30) + (fit * 0.24), 0.0, 1.0)

	var presence: float = 0.0
	if selective:
		presence = 0.04 + (fit * 0.22) + (control_score * 1.36)
	else:
		presence = 0.20 + (coverage * 0.78) + (fit * 0.32) + (coverage_roll * 0.20)
	presence *= daily_variation
	presence = clamp(presence, 0.08, 1.90)

	var buy_multiplier: float = presence
	var sell_multiplier: float = presence
	if "quality_buyer" in tags or "quiet_accumulator" in tags or "government" in tags:
		sell_multiplier *= 0.96
	if "distributor" in tags or "evil_to_retail" in tags:
		buy_multiplier *= 0.93
	if accumulation_setup > distribution_setup and ("quiet_accumulator" in tags or "quality_buyer" in tags or broker_type in ["bandar", "zombie", "foreign"]):
		buy_multiplier *= lerp(0.98, 1.30, control_score)
		sell_multiplier *= lerp(1.0, 0.90, control_score)
	elif distribution_setup > accumulation_setup and ("distributor" in tags or "evil_to_retail" in tags or broker_type == "bandar"):
		sell_multiplier *= lerp(0.98, 1.30, control_score)
		buy_multiplier *= lerp(1.0, 0.90, control_score)

	return {
		"buy_multiplier": clamp(buy_multiplier, 0.08, 2.10),
		"sell_multiplier": clamp(sell_multiplier, 0.08, 2.10),
		"minimum_weight": 0.08 if selective else 0.18
	}


func _broker_coverage_score(broker_type: String, tags: Array) -> float:
	var coverage: float = 0.55
	match broker_type:
		"foreign":
			coverage = 0.72
		"retail":
			coverage = 0.82
		"institution":
			coverage = 0.52
		"bandar":
			coverage = 0.26
		"zombie":
			coverage = 0.18
		_:
			coverage = 0.55
	if "smart_money" in tags:
		coverage -= 0.08
	if "quality_buyer" in tags:
		coverage -= 0.03
	if "quiet_accumulator" in tags:
		coverage -= 0.10
	if "retail_facing" in tags:
		coverage += 0.08
	if "dumb_money" in tags:
		coverage += 0.06
	if "market_maker" in tags and not ("smart_money" in tags or "quiet_accumulator" in tags):
		coverage += 0.05
	return clamp(coverage, 0.12, 0.92)


func _sample_static_broker_value(context: Dictionary, broker_code: Variant, key: String) -> float:
	var rng: RandomNumberGenerator = STABLE_RNG.rng([
		context.get("run_seed", 0),
		"broker-static",
		context.get("company_id", ""),
		broker_code,
		key
	])
	return rng.randf()


func _sample_broker_day_noise(context: Dictionary, broker_code: Variant, minimum: float, maximum: float) -> float:
	var rng: RandomNumberGenerator = STABLE_RNG.rng([
		context.get("run_seed", 0),
		"broker-day-noise",
		context.get("day_index", 0),
		context.get("company_id", ""),
		broker_code
	])
	return rng.randf_range(minimum, maximum)


func _derive_broker_average_price(
	broker_row: Dictionary,
	side: String,
	current_price: float,
	day_low: float,
	day_high: float,
	flow_tag: String,
	context: Dictionary
) -> float:
	var tags: Array = broker_row.get("personality_tags", [])
	var bias: float = -0.0016 if side == "buy" else 0.0016
	if "dumb_money" in tags or "follow_the_wave" in tags:
		bias += 0.0021 if side == "buy" else -0.0021
	if "quiet_accumulator" in tags or "quality_buyer" in tags or "government" in tags:
		bias += -0.0018 if side == "buy" else 0.0018
	if "market_maker" in tags:
		bias += -0.0006 if side == "buy" else 0.0006
	if "evil_to_retail" in tags:
		bias += 0.0018 if side == "buy" else -0.0018
	if flow_tag == "accumulation" and side == "buy":
		bias -= 0.0008
	elif flow_tag == "distribution" and side == "sell":
		bias += 0.0008

	var noise_rng: RandomNumberGenerator = STABLE_RNG.rng([
		"broker-price",
		context.get("company_id", ""),
		broker_row.get("code", ""),
		side
	])
	var noise: float = noise_rng.randf_range(-0.0016, 0.0016)
	var raw_price: float = current_price * (1.0 + bias + noise)
	var low_bound: float = min(day_low, day_high)
	var high_bound: float = max(day_low, day_high)
	return clamp(raw_price, low_bound, high_bound)


func _build_broker_side_snapshot(broker_row: Dictionary, side: String) -> Dictionary:
	var prefix: String = "buy" if side == "buy" else "sell"
	return {
		"code": str(broker_row.get("code", "")),
		"company_name": str(broker_row.get("company_name", "")),
		"broker_type": str(broker_row.get("broker_type", "")),
		"personality_tags": broker_row.get("personality_tags", []).duplicate(),
		"value": float(broker_row.get("%s_value" % prefix, 0.0)),
		"lots": float(broker_row.get("%s_lots" % prefix, 0.0)),
		"avg_price": float(broker_row.get("%s_avg_price" % prefix, 0.0))
	}


func _build_broker_net_snapshot(broker_row: Dictionary) -> Dictionary:
	var buy_value: float = float(broker_row.get("buy_value", 0.0))
	var sell_value: float = float(broker_row.get("sell_value", 0.0))
	var buy_shares: float = float(broker_row.get("buy_shares", 0.0))
	var sell_shares: float = float(broker_row.get("sell_shares", 0.0))
	var net_value: float = buy_value - sell_value
	var net_shares: float = buy_shares - sell_shares
	if absf(net_value) < 1000000.0:
		return {}

	var net_side: String = "buy" if net_value >= 0.0 else "sell"
	var display_value: float = absf(net_value)
	var display_shares: float = absf(net_shares)
	var display_lots: float = max(display_shares / 100.0, 0.0)
	var display_avg_price: float = float(broker_row.get("buy_avg_price", 0.0)) if net_side == "buy" else float(broker_row.get("sell_avg_price", 0.0))
	return {
		"code": str(broker_row.get("code", "")),
		"company_name": str(broker_row.get("company_name", "")),
		"broker_type": str(broker_row.get("broker_type", "")),
		"personality_tags": broker_row.get("personality_tags", []).duplicate(),
		"value": display_value,
		"lots": display_lots,
		"avg_price": display_avg_price,
		"net_side": net_side
	}


func _derive_action_meter_score(broker_flow: Dictionary, broker_rows: Array, trade_value: float) -> float:
	var smart_buy: float = 0.0
	var smart_sell: float = 0.0
	var dumb_buy: float = 0.0
	var dumb_sell: float = 0.0

	for broker_row_value in broker_rows:
		var broker_row: Dictionary = broker_row_value
		var tags: Array = broker_row.get("personality_tags", [])
		var is_smart: bool = (
			"smart_money" in tags or
			"quiet_accumulator" in tags or
			"quality_buyer" in tags or
			str(broker_row.get("broker_type", "")) in ["bandar", "zombie"]
		)
		var is_dumb: bool = (
			"dumb_money" in tags or
			"follow_the_wave" in tags or
			"retail_facing" in tags or
			"evil_to_retail" in tags
		)
		if is_smart:
			smart_buy += float(broker_row.get("buy_value", 0.0))
			smart_sell += float(broker_row.get("sell_value", 0.0))
		if is_dumb:
			dumb_buy += float(broker_row.get("buy_value", 0.0))
			dumb_sell += float(broker_row.get("sell_value", 0.0))

	var smart_bias: float = 0.0
	var dumb_bias: float = 0.0
	if trade_value > 0.0:
		smart_bias = clamp((smart_buy - smart_sell) / trade_value, -1.0, 1.0)
		dumb_bias = clamp((dumb_buy - dumb_sell) / trade_value, -1.0, 1.0)

	var type_bias: float = clamp(
		(
			(float(broker_flow.get("bandar_net", 0.0)) * 0.42) +
			(float(broker_flow.get("zombie_net", 0.0)) * 0.22) +
			(float(broker_flow.get("foreign_net", 0.0)) * 0.18) +
			(float(broker_flow.get("institution_net", 0.0)) * 0.14) -
			(float(broker_flow.get("retail_net", 0.0)) * 0.08)
		) / 100.0,
		-1.0,
		1.0
	)

	return clamp(
		(float(broker_flow.get("net_pressure", 0.0)) * 0.55) +
		(smart_bias * 0.55) -
		(dumb_bias * 0.22) +
		(type_bias * 0.35),
		-1.0,
		1.0
	)


func _meter_label_for_score(score: float) -> String:
	if score >= 0.60:
		return "Big Acc"
	if score >= 0.18:
		return "Accumulation"
	if score <= -0.60:
		return "Big Dist"
	if score <= -0.18:
		return "Distribution"
	return "Neutral"


func _broker_type_score(broker_flow: Dictionary, broker_type: String) -> float:
	match broker_type:
		"retail":
			return float(broker_flow.get("retail_net", 0.0))
		"foreign":
			return float(broker_flow.get("foreign_net", 0.0))
		"institution":
			return float(broker_flow.get("institution_net", 0.0))
		"bandar":
			return float(broker_flow.get("bandar_net", 0.0))
		"zombie":
			return float(broker_flow.get("zombie_net", 0.0))
		_:
			return 0.0


func _dominant_buyer(raw_scores: Dictionary) -> String:
	var winner: String = "balanced"
	var best_value: float = 5.0

	for key in BROKER_KEYS:
		var value: float = float(raw_scores.get(key, 0.0))
		if value > best_value:
			best_value = value
			winner = key.replace("_net", "")

	return winner


func _dominant_seller(raw_scores: Dictionary) -> String:
	var winner: String = "balanced"
	var worst_value: float = -5.0

	for key in BROKER_KEYS:
		var value: float = float(raw_scores.get(key, 0.0))
		if value < worst_value:
			worst_value = value
			winner = key.replace("_net", "")

	return winner


func _flow_tag(net_pressure: float) -> String:
	if net_pressure > 0.18:
		return "accumulation"
	if net_pressure < -0.18:
		return "distribution"
	return "neutral"


func _sort_broker_buy_rows(a: Dictionary, b: Dictionary) -> bool:
	var a_value: float = float(a.get("buy_value", 0.0))
	var b_value: float = float(b.get("buy_value", 0.0))
	if is_equal_approx(a_value, b_value):
		return str(a.get("code", "")) < str(b.get("code", ""))
	return a_value > b_value


func _sort_broker_sell_rows(a: Dictionary, b: Dictionary) -> bool:
	var a_value: float = float(a.get("sell_value", 0.0))
	var b_value: float = float(b.get("sell_value", 0.0))
	if is_equal_approx(a_value, b_value):
		return str(a.get("code", "")) < str(b.get("code", ""))
	return a_value > b_value


func _sort_broker_net_rows(a: Dictionary, b: Dictionary) -> bool:
	var a_value: float = float(a.get("value", 0.0))
	var b_value: float = float(b.get("value", 0.0))
	if is_equal_approx(a_value, b_value):
		return str(a.get("code", "")) < str(b.get("code", ""))
	return a_value > b_value


func _sample_noise(context: Dictionary, broker_name: String, minimum: float, maximum: float) -> float:
	var rng: RandomNumberGenerator = STABLE_RNG.rng([
		context.get("run_seed", 0),
		"broker-noise",
		context.get("day_index", 0),
		context.get("company_id", ""),
		broker_name
	])
	return rng.randf_range(minimum, maximum)
