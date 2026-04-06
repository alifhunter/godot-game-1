extends RefCounted

const SAMPLE_MIN := 6
const SAMPLE_MAX := 14
const TOP_CANDIDATE_COUNT := 4
const TRUMP_TARIFF_SECTORS := {
	"industrial": true,
	"transport": true,
	"consumer": true,
	"basicindustry": true
}
const TRUMP_DEAL_SECTORS := {
	"energy": true,
	"infra": true,
	"industrial": true,
	"property": true
}
const MUSK_AI_SECTORS := {
	"tech": true,
	"consumer": true
}
const MUSK_COMPANY_SECTORS := {
	"tech": true,
	"transport": true,
	"consumer": true
}


func build_person_event_candidates(
	run_state,
	trade_date: Dictionary,
	day_number: int,
	macro_state: Dictionary,
	sector_sentiments: Dictionary,
	market_sentiment: float
) -> Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash("%s|person_event|%s" % [run_state.run_seed, day_number]))
	var sampled_company_ids: Array = _sample_company_ids(run_state.company_order, rng)
	var candidates: Array = []
	var risk_appetite: float = float(macro_state.get("risk_appetite", 0.5))
	var inflation_yoy: float = float(macro_state.get("inflation_yoy", 3.0))
	var gdp_growth: float = float(macro_state.get("gdp_growth", 4.8))

	var tariff_sector_id: String = _pick_sector_by_sentiment(sector_sentiments, TRUMP_TARIFF_SECTORS, true)
	if not tariff_sector_id.is_empty():
		var tariff_sentiment: float = float(sector_sentiments.get(tariff_sector_id, 0.0))
		var tariff_sector_name: String = _sector_name(tariff_sector_id)
		var tariff_weight: float = (
			0.22 +
			max(0.56 - risk_appetite, 0.0) * 0.72 +
			max(inflation_yoy - 3.8, 0.0) * 0.05 +
			max(-tariff_sentiment, 0.0) * 4.4
		)
		candidates.append(_build_sector_candidate(
			"trump_tariff_barrage",
			tariff_weight,
			tariff_sector_id,
			trade_date,
			"Tonald Drump tariff post hits %s" % tariff_sector_name,
			"Tonald Drump fires off a tariff-heavy post that puts %s on the defensive." % tariff_sector_name
		))

	var deal_sector_id: String = _pick_sector_by_sentiment(sector_sentiments, TRUMP_DEAL_SECTORS, false)
	if not deal_sector_id.is_empty():
		var deal_sentiment: float = float(sector_sentiments.get(deal_sector_id, 0.0))
		var deal_sector_name: String = _sector_name(deal_sector_id)
		var deal_weight: float = (
			0.18 +
			max(gdp_growth - 4.7, 0.0) * 0.05 +
			max(risk_appetite - 0.48, 0.0) * 0.54 +
			max(deal_sentiment, 0.0) * 3.4
		)
		candidates.append(_build_sector_candidate(
			"trump_deal_optimism",
			deal_weight,
			deal_sector_id,
			trade_date,
			"Tonald Drump deal optimism lifts %s" % deal_sector_name,
			"Tonald Drump posts upbeat deal commentary that sharpens interest in %s." % deal_sector_name
		))

	var ai_sector_id: String = _pick_sector_by_sentiment(sector_sentiments, MUSK_AI_SECTORS, false)
	if not ai_sector_id.is_empty():
		var ai_sentiment: float = float(sector_sentiments.get(ai_sector_id, 0.0))
		var ai_sector_name: String = _sector_name(ai_sector_id)
		var ai_weight: float = (
			0.24 +
			max(risk_appetite - 0.47, 0.0) * 0.64 +
			max(ai_sentiment, 0.0) * 4.0 +
			max(market_sentiment, 0.0) * 2.2
		)
		candidates.append(_build_sector_candidate(
			"musk_ai_hype",
			ai_weight,
			ai_sector_id,
			trade_date,
			"Melon Tusk AI post ignites %s" % ai_sector_name,
			"A Melon Tusk post around AI and future tech sends %s into the spotlight." % ai_sector_name
		))

	var meme_company: Dictionary = _pick_company_story_target(run_state, sampled_company_ids, true)
	if not meme_company.is_empty():
		var meme_definition: Dictionary = meme_company.get("definition", {})
		var meme_runtime: Dictionary = meme_company.get("runtime", {})
		var meme_weight: float = (
			0.24 +
			float(meme_company.get("score", 0.0)) * 0.82 +
			max(risk_appetite - 0.46, 0.0) * 0.28 +
			max(-float(meme_runtime.get("daily_change_pct", meme_runtime.get("sentiment", 0.0))), 0.0) * 0.75
		)
		candidates.append(_build_company_candidate(
			"musk_meme_pump",
			meme_weight,
			meme_definition,
			trade_date,
			"Melon Tusk post spotlights %s" % str(meme_definition.get("ticker", "")),
			"A Melon Tusk-style hype post puts %s right back on the fast-money radar." % str(meme_definition.get("name", ""))
		))

	var controversy_company: Dictionary = _pick_company_story_target(run_state, sampled_company_ids, false)
	if not controversy_company.is_empty():
		var controversy_definition: Dictionary = controversy_company.get("definition", {})
		var controversy_runtime: Dictionary = controversy_company.get("runtime", {})
		var controversy_weight: float = (
			0.22 +
			float(controversy_company.get("score", 0.0)) * 0.78 +
			max(0.54 - risk_appetite, 0.0) * 0.26 +
			max(float(controversy_runtime.get("daily_change_pct", controversy_runtime.get("sentiment", 0.0))), 0.0) * 0.95
		)
		candidates.append(_build_company_candidate(
			"musk_controversy_spiral",
			controversy_weight,
			controversy_definition,
			trade_date,
			"Melon Tusk controversy drags on %s" % str(controversy_definition.get("ticker", "")),
			"A fresh Melon Tusk controversy post knocks confidence in %s and cools the chase." % str(controversy_definition.get("name", ""))
		))

	candidates = candidates.filter(func(candidate_value: Dictionary) -> bool:
		return float(candidate_value.get("weight", 0.0)) >= 0.2
	)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("weight", 0.0)) > float(b.get("weight", 0.0))
	)
	if candidates.size() > TOP_CANDIDATE_COUNT:
		candidates = candidates.slice(0, TOP_CANDIDATE_COUNT)

	return candidates


func _sample_company_ids(company_order: Array, rng: RandomNumberGenerator) -> Array:
	var sampled_ids: Array = []
	var remaining_ids: Array = company_order.duplicate()
	var target_count: int = clamp(int(round(sqrt(float(max(company_order.size(), 1))) * 2.0)), SAMPLE_MIN, SAMPLE_MAX)
	target_count = min(target_count, remaining_ids.size())

	for _index in range(target_count):
		if remaining_ids.is_empty():
			break
		var picked_index: int = rng.randi_range(0, remaining_ids.size() - 1)
		sampled_ids.append(str(remaining_ids[picked_index]))
		remaining_ids.remove_at(picked_index)

	return sampled_ids


func _pick_sector_by_sentiment(sector_sentiments: Dictionary, sector_pool: Dictionary, prefer_negative: bool) -> String:
	var picked_sector_id: String = ""
	var picked_value: float = INF if prefer_negative else -INF

	for sector_id_value in sector_pool.keys():
		var sector_id: String = str(sector_id_value)
		if not sector_sentiments.has(sector_id):
			continue

		var sentiment_value: float = float(sector_sentiments.get(sector_id, 0.0))
		if prefer_negative:
			if sentiment_value < picked_value:
				picked_value = sentiment_value
				picked_sector_id = sector_id
		elif sentiment_value > picked_value:
			picked_value = sentiment_value
			picked_sector_id = sector_id

	return picked_sector_id


func _pick_company_story_target(run_state, sampled_company_ids: Array, prefer_positive: bool) -> Dictionary:
	var selected: Dictionary = {}
	var selected_score: float = -INF

	for company_id_value in sampled_company_ids:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = run_state.get_effective_company_definition(company_id)
		var runtime: Dictionary = run_state.get_company(company_id)
		if definition.is_empty() or runtime.is_empty():
			continue

		var score: float = _person_company_score(definition, runtime, prefer_positive)
		if score > selected_score:
			selected_score = score
			selected = {
				"definition": definition,
				"runtime": runtime,
				"score": score
			}

	return selected


func _person_company_score(definition: Dictionary, runtime: Dictionary, prefer_positive: bool) -> float:
	var sector_id: String = str(definition.get("sector_id", ""))
	if not MUSK_COMPANY_SECTORS.has(sector_id):
		return -INF

	var narrative_tags: Array = definition.get("narrative_tags", []).duplicate()
	var company_profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var traits: Dictionary = company_profile.get("generation_traits", {}).duplicate(true)
	var story_heat: float = float(traits.get("story_heat", 0.5))
	var growth: float = float(definition.get("growth_score", 50.0))
	var risk: float = float(definition.get("risk_score", 50.0))
	var recent_sentiment: float = float(runtime.get("daily_change_pct", runtime.get("sentiment", 0.0)))
	var score: float = story_heat * 0.7

	if "narrative_hot" in narrative_tags:
		score += 0.22
	if "retail_favorite" in narrative_tags:
		score += 0.18
	if "foreign_watchlist" in narrative_tags:
		score += 0.05

	if prefer_positive:
		score += max((growth - 55.0) / 100.0, 0.0) * 0.28
		score += max(-recent_sentiment, 0.0) * 1.3
	else:
		score += max((risk - 50.0) / 100.0, 0.0) * 0.26
		score += max(recent_sentiment, 0.0) * 1.65

	return score


func _build_sector_candidate(
	event_id: String,
	weight: float,
	target_sector_id: String,
	trade_date: Dictionary,
	headline: String,
	headline_detail: String
) -> Dictionary:
	var event_definition: Dictionary = DataRepository.get_event_definition(event_id)
	return {
		"event_id": event_id,
		"scope": str(event_definition.get("scope", "sector")),
		"event_family": str(event_definition.get("event_family", "person")),
		"category": str(event_definition.get("category", "person")),
		"tone": str(event_definition.get("tone", "mixed")),
		"duration_days": int(event_definition.get("duration_days", 1)),
		"target_sector_id": target_sector_id,
		"trade_date": trade_date.duplicate(true),
		"person_id": str(event_definition.get("person_id", "")),
		"person_name": str(event_definition.get("person_name", "")),
		"headline": headline,
		"headline_detail": headline_detail,
		"description": str(event_definition.get("description", "")),
		"weight": weight
	}


func _build_company_candidate(
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
		"event_family": str(event_definition.get("event_family", "person")),
		"category": str(event_definition.get("category", "person")),
		"tone": str(event_definition.get("tone", "mixed")),
		"duration_days": int(event_definition.get("duration_days", 1)),
		"target_company_id": company_id,
		"target_sector_id": str(definition.get("sector_id", "")),
		"target_ticker": ticker,
		"target_company_name": company_name,
		"trade_date": trade_date.duplicate(true),
		"person_id": str(event_definition.get("person_id", "")),
		"person_name": str(event_definition.get("person_name", "")),
		"headline": headline,
		"headline_detail": headline_detail,
		"description": str(event_definition.get("description", "")),
		"weight": weight
	}


func _sector_name(sector_id: String) -> String:
	var sector_definition: Dictionary = DataRepository.get_sector_definition(sector_id)
	return str(sector_definition.get("name", sector_id.capitalize()))
