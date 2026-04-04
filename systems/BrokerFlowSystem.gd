extends RefCounted

const BROKER_KEYS := [
	"retail_net",
	"foreign_net",
	"institution_net",
	"zombie_net"
]


func generate_day_flow(definition: Dictionary, runtime: Dictionary, context: Dictionary) -> Dictionary:
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

	var retail_score: float = clamp(
		(recent_momentum * 6.0) +
		(event_bias * 4.6) +
		(_sample_noise(context, "retail", -0.2, 0.2)),
		-1.0,
		1.0
	)
	var foreign_score: float = clamp(
		(market_sentiment * 1.8) +
		(sector_sentiment * 2.4) +
		(growth * 0.25) -
		(risk * 0.3) +
		(recent_momentum * 1.6) -
		(max(recent_momentum, 0.0) * 1.0) +
		(_sample_noise(context, "foreign", -0.16, 0.16)),
		-1.0,
		1.0
	)

	var institution_score: float = clamp(
		(quality * 0.55) -
		(risk * 0.52) -
		(max(recent_momentum, 0.0) * 2.7) +
		(max(-recent_momentum, 0.0) * 1.6) +
		(event_bias * 1.4) +
		(_sample_noise(context, "institution", -0.12, 0.12)),
		-1.0,
		1.0
	)

	var zombie_bonus: float = 0.0
	if quiet_range:
		zombie_bonus += 0.12
	if "stealth_interest" in hidden_flags:
		zombie_bonus += 0.18
	if "quiet_execution" in narrative_tags:
		zombie_bonus += 0.08
	if "retail_favorite" in narrative_tags:
		zombie_bonus -= 0.14
	if recent_momentum > 0.02:
		zombie_bonus -= 0.18
	elif recent_momentum < -0.02:
		zombie_bonus += 0.08

	var zombie_score: float = clamp(
		(event_bias * 1.0) +
		(sector_sentiment * 0.45) +
		zombie_bonus +
		(_sample_noise(context, "zombie", -0.2, 0.2)),
		-1.0,
		1.0
	)

	var raw_scores: Dictionary = {
		"retail_net": round(retail_score * 100.0),
		"foreign_net": round(foreign_score * 100.0),
		"institution_net": round(institution_score * 100.0),
		"zombie_net": round(zombie_score * 100.0)
	}
	var net_pressure: float = (
		float(raw_scores["retail_net"]) +
		float(raw_scores["foreign_net"]) +
		float(raw_scores["institution_net"]) +
		float(raw_scores["zombie_net"])
	) / 400.0

	return {
		"retail_net": raw_scores["retail_net"],
		"foreign_net": raw_scores["foreign_net"],
		"institution_net": raw_scores["institution_net"],
		"zombie_net": raw_scores["zombie_net"],
		"net_pressure": clamp(net_pressure, -1.0, 1.0),
		"dominant_buyer": _dominant_buyer(raw_scores),
		"dominant_seller": _dominant_seller(raw_scores),
		"flow_tag": _flow_tag(net_pressure)
	}


func _dominant_buyer(raw_scores: Dictionary) -> String:
	var winner: String = "balanced"
	var best_value: float = 5.0

	for key in BROKER_KEYS:
		var value = float(raw_scores[key])
		if value > best_value:
			best_value = value
			winner = key.replace("_net", "")

	return winner


func _dominant_seller(raw_scores: Dictionary) -> String:
	var winner: String = "balanced"
	var worst_value: float = -5.0

	for key in BROKER_KEYS:
		var value = float(raw_scores[key])
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


func _sample_noise(context: Dictionary, broker_name: String, minimum: float, maximum: float) -> float:
	var rng = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|%s|%s|%s" % [
		context.get("run_seed", 0),
		context.get("day_index", 0),
		context.get("company_id", ""),
		broker_name
	]))
	return rng.randf_range(minimum, maximum)
