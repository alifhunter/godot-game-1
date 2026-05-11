extends RefCounted

const STABLE_RNG = preload("res://systems/StableRng.gd")

const REQUEST_TYPE := "dirty_tip"
const MIN_OFFER_DAY := 20
const MAX_LEGAL_HOLD_DAYS := 5
const OPERATOR_CONTACT_ID := "operator_room"
const OPERATOR_CONTACT_NAME := "Operator Room"
const PLAYER_VISIBLE_RECOGNITION := 35.0
const PLAYER_VISIBLE_EQUITY_RATIO := 1.5
const DIFFICULTY_PROFILES := {
	"chill": {
		"threshold": 0.62,
		"roll_chance": 0.16,
		"case_days": 3,
		"legal_days": 1,
		"fine_pct": 0.06,
		"catch_multiplier": 0.72,
		"decline_cooldown": 8,
		"report_cooldown": 18,
		"market_pressure": 0.52
	},
	"normal": {
		"threshold": 0.52,
		"roll_chance": 0.28,
		"case_days": 4,
		"legal_days": 2,
		"fine_pct": 0.10,
		"catch_multiplier": 1.0,
		"decline_cooldown": 6,
		"report_cooldown": 14,
		"market_pressure": 0.78
	},
	"grind": {
		"threshold": 0.42,
		"roll_chance": 0.44,
		"case_days": 5,
		"legal_days": 3,
		"fine_pct": 0.14,
		"catch_multiplier": 1.24,
		"decline_cooldown": 4,
		"report_cooldown": 10,
		"market_pressure": 1.0
	}
}


func resolve_day(
	run_state,
	data_repository,
	attention_directives: Dictionary,
	day_number: int,
	trade_date: Dictionary,
	force_company_id: String = ""
) -> Dictionary:
	if not run_state.has_active_run():
		return {"eligible": false, "reason": "no_active_run", "offers": []}
	var profile: Dictionary = _difficulty_profile(run_state)
	var forced: bool = not force_company_id.strip_edges().is_empty()
	if day_number < MIN_OFFER_DAY and not forced:
		return {"eligible": false, "reason": "before_day_20", "offers": []}
	if _legal_hold_active(run_state):
		return {"eligible": false, "reason": "legal_hold_active", "offers": []}
	if _has_open_dirty_tip(run_state):
		return {"eligible": false, "reason": "open_case_exists", "offers": []}
	if _dirty_tip_cooldown_active(run_state, day_number):
		return {"eligible": false, "reason": "cooldown_active", "offers": []}
	var visibility: Dictionary = _visibility_snapshot(run_state)
	if not bool(visibility.get("eligible", false)) and not forced:
		return {"eligible": false, "reason": "player_not_visible", "offers": []}

	var dirty_pressure: float = clamp(float(attention_directives.get("dirty_market_pressure", 0.0)), 0.0, 1.0)
	if str(attention_directives.get("selected_lane", "")) == "dirty_market":
		dirty_pressure = clamp(dirty_pressure + 0.12, 0.0, 1.0)
	if dirty_pressure < float(profile.get("threshold", 0.52)) and not forced:
		return {"eligible": true, "reason": "pressure_below_threshold", "offers": []}

	var roll_chance: float = clamp(float(profile.get("roll_chance", 0.28)) * max(dirty_pressure, 0.35), 0.0, 0.72)
	var roll: float = STABLE_RNG.unit_float([run_state.run_seed, "dirty_tip_offer_roll", day_number, force_company_id])
	if roll > roll_chance and not forced:
		return {"eligible": true, "reason": "offer_roll_missed", "offers": []}

	var candidate: Dictionary = _select_candidate(run_state, data_repository, attention_directives, day_number, force_company_id)
	if candidate.is_empty():
		return {"eligible": true, "reason": "no_candidate", "offers": []}

	var offer: Dictionary = _build_offer(run_state, candidate, profile, day_number, trade_date)
	var requests: Dictionary = run_state.get_network_requests()
	requests[str(offer.get("id", ""))] = offer.duplicate(true)
	run_state.set_network_requests(requests)
	return {
		"eligible": true,
		"reason": "offered",
		"offers": [offer.duplicate(true)]
	}


func accept_offer(run_state, offer_id: String) -> Dictionary:
	var request: Dictionary = _get_dirty_tip_request(run_state, offer_id)
	if request.is_empty():
		return {"success": false, "message": "Dirty tip offer not found."}
	if str(request.get("status", "")) != "offered":
		return {"success": false, "message": "Dirty tip offer is no longer open."}
	var requests: Dictionary = run_state.get_network_requests()
	request["status"] = "accepted"
	request["decision"] = "accepted"
	request["decision_day_index"] = int(run_state.day_index)
	request["due_day_index"] = int(run_state.day_index) + int(request.get("case_days", 4))
	request["active_until_day_index"] = int(request.get("due_day_index", run_state.day_index))
	request["journal_detail"] = "%s accepted an unsolicited tape offer on %s." % [
		str(run_state.PLAYER_BROKER_CODE),
		str(request.get("target_ticker", ""))
	]
	requests[offer_id] = request.duplicate(true)
	run_state.set_network_requests(requests)
	return {"success": true, "message": "Dirty tip accepted.", "request": request.duplicate(true)}


func decline_offer(run_state, offer_id: String) -> Dictionary:
	return _close_offer(run_state, offer_id, "declined", "Dirty tip declined.", "You ignored the unsolicited offer.")


func report_offer(run_state, offer_id: String) -> Dictionary:
	return _close_offer(run_state, offer_id, "reported", "Dirty tip reported.", "You reported the approach and kept your hands clean.")


func process_due_cases(run_state, data_repository) -> Array:
	var results: Array = []
	var requests: Dictionary = run_state.get_network_requests()
	var changed: bool = false
	for request_id_value in requests.keys():
		var request_id: String = str(request_id_value)
		var request_value: Variant = requests.get(request_id)
		if typeof(request_value) != TYPE_DICTIONARY:
			continue
		var request: Dictionary = request_value
		if str(request.get("request_type", "")) != REQUEST_TYPE:
			continue
		if str(request.get("status", "")) == "offered" and int(request.get("due_day_index", 0)) <= int(run_state.day_index):
			request["status"] = "expired"
			request["completed_day_index"] = int(run_state.day_index)
			request["resolved_day_index"] = int(run_state.day_index)
			request["outcome_label"] = "Expired"
			request["outcome_note"] = "The room moved on after you ignored the approach."
			requests[request_id] = request.duplicate(true)
			results.append(_result_row(request, "expired", 0.0, 0))
			changed = true
			continue
		if str(request.get("status", "")) != "accepted":
			continue
		if int(request.get("due_day_index", 0)) > int(run_state.day_index):
			continue
		var outcome: Dictionary = _resolve_case_outcome(run_state, data_repository, request)
		for key_value in outcome.keys():
			request[str(key_value)] = outcome[key_value]
		request["completed_day_index"] = int(run_state.day_index)
		request["resolved_day_index"] = int(run_state.day_index)
		requests[request_id] = request.duplicate(true)
		results.append(_result_row(request, str(request.get("status", "")), float(outcome.get("fine_amount", 0.0)), int(outcome.get("legal_days", 0))))
		changed = true
	if changed:
		run_state.set_network_requests(requests)
	return results


func market_effect_for_company(run_state, company_id: String, day_number: int) -> Dictionary:
	var active: Dictionary = _active_case_for_company(run_state, company_id, day_number)
	if active.is_empty():
		return {}
	var pressure: float = clamp(float(active.get("pressure_score", 0.0)) * float(active.get("market_pressure_multiplier", 0.78)), 0.0, 1.0)
	if pressure <= 0.0:
		return {}
	var direction: float = 1.0 if str(active.get("direction", "pump")) != "dump" else -1.0
	return {
		"offer_id": str(active.get("id", "")),
		"pressure": snappedf(pressure, 0.001),
		"price_bias": direction * clamp(0.0035 + pressure * 0.0075, 0.0, 0.012),
		"broker_pressure": direction * clamp(pressure * 0.34, 0.0, 0.58),
		"volume_multiplier": clamp(1.0 + pressure * 0.42, 1.0, 1.58)
	}


func has_active_case_or_legal_hold(run_state) -> bool:
	return _has_open_dirty_tip(run_state) or _legal_hold_active(run_state)


func _close_offer(run_state, offer_id: String, status: String, message: String, note: String) -> Dictionary:
	var request: Dictionary = _get_dirty_tip_request(run_state, offer_id)
	if request.is_empty():
		return {"success": false, "message": "Dirty tip offer not found."}
	if str(request.get("status", "")) != "offered":
		return {"success": false, "message": "Dirty tip offer is no longer open."}
	var requests: Dictionary = run_state.get_network_requests()
	request["status"] = status
	request["decision"] = status
	request["decision_day_index"] = int(run_state.day_index)
	request["completed_day_index"] = int(run_state.day_index)
	request["resolved_day_index"] = int(run_state.day_index)
	request["outcome_label"] = status.capitalize()
	request["outcome_note"] = note
	request["journal_detail"] = note
	var cooldown_key: String = "report_cooldown" if status == "reported" else "decline_cooldown"
	var cooldown_days: int = int(_difficulty_profile(run_state).get(cooldown_key, 6))
	request["suppress_until_day_index"] = int(run_state.day_index) + cooldown_days
	requests[offer_id] = request.duplicate(true)
	run_state.set_network_requests(requests)
	return {"success": true, "message": message, "request": request.duplicate(true)}


func _resolve_case_outcome(run_state, data_repository, request: Dictionary) -> Dictionary:
	var trade_stats: Dictionary = _player_trade_stats_for_case(run_state, request)
	if float(trade_stats.get("gross_value", 0.0)) <= 0.0 and not bool(request.get("debug_force_caught", false)):
		return {
			"status": "expired",
			"outcome_label": "No trail",
			"outcome_note": "You accepted the room talk but did not trade into it.",
			"trade_stats": trade_stats.duplicate(true),
			"fine_amount": 0.0,
			"legal_days": 0
		}
	var catch_probability: float = _catch_probability(run_state, request, trade_stats)
	var roll: float = STABLE_RNG.unit_float([run_state.run_seed, "dirty_tip_case_outcome", str(request.get("id", "")), int(run_state.day_index)])
	var caught: bool = bool(request.get("debug_force_caught", false)) or roll <= catch_probability
	if not caught:
		return {
			"status": "resolved_clean",
			"outcome_label": "Clean exit",
			"outcome_note": "The case cooled down without an authority action.",
			"catch_probability": snappedf(catch_probability, 0.001),
			"trade_stats": trade_stats.duplicate(true),
			"fine_amount": 0.0,
			"legal_days": 0
		}
	var severity: float = clamp(float(trade_stats.get("gross_to_adv", 0.0)) * 0.42 + float(request.get("pressure_score", 0.0)) * 0.36 + float(trade_stats.get("profit_to_adv", 0.0)) * 0.22, 0.0, 1.0)
	var legal_days: int = clampi(int(_difficulty_profile(run_state).get("legal_days", 2)) + int(round(severity * 2.0)), 1, MAX_LEGAL_HOLD_DAYS)
	var fine_amount: float = _apply_dirty_tip_fine(run_state, request, trade_stats, severity)
	_apply_legal_hold(run_state, request, legal_days, fine_amount)
	return {
		"status": "caught",
		"outcome_label": "Caught",
		"outcome_note": "Authority traced the dirty tape. A fine was applied and trading is locked during legal hold.",
		"catch_probability": snappedf(catch_probability, 0.001),
		"trade_stats": trade_stats.duplicate(true),
		"fine_amount": fine_amount,
		"legal_days": legal_days
	}


func _apply_dirty_tip_fine(run_state, request: Dictionary, trade_stats: Dictionary, severity: float) -> float:
	var equity: float = max(run_state.get_total_equity(), 1.0)
	var fine_pct: float = float(_difficulty_profile(run_state).get("fine_pct", 0.10))
	var base_amount: float = max(float(trade_stats.get("gross_value", 0.0)) * fine_pct, float(run_state.get_difficulty_config().get("starting_cash", 1.0)) * 0.015)
	var fine_amount: float = clamp(base_amount * (1.0 + severity), 0.0, equity * 0.38)
	if fine_amount <= 0.0:
		return 0.0
	var detail: Dictionary = {
		"company_id": str(request.get("target_company_id", "dirty_tip")),
		"ticker": str(request.get("target_ticker", "")),
		"side": "dirty_tip_fine",
		"case_id": str(request.get("id", "")),
		"reason": "market_conduct_fine"
	}
	var result: Dictionary = run_state.apply_cash_obligation("dirty_tip_fine", fine_amount, detail)
	return float(result.get("amount", fine_amount))


func _apply_legal_hold(run_state, request: Dictionary, legal_days: int, fine_amount: float) -> void:
	var life_state: Dictionary = run_state.get_player_life()
	var legal_state: Dictionary = life_state.get("legal_state", {}) if typeof(life_state.get("legal_state", {})) == TYPE_DICTIONARY else {}
	legal_state["active"] = true
	legal_state["status"] = "held"
	legal_state["case_id"] = str(request.get("id", ""))
	legal_state["target_company_id"] = str(request.get("target_company_id", ""))
	legal_state["target_ticker"] = str(request.get("target_ticker", ""))
	legal_state["days_remaining"] = clampi(legal_days, 1, MAX_LEGAL_HOLD_DAYS)
	legal_state["started_day_index"] = int(run_state.day_index)
	legal_state["release_day_index"] = int(run_state.day_index) + clampi(legal_days, 1, MAX_LEGAL_HOLD_DAYS)
	legal_state["fine_amount"] = fine_amount
	legal_state["reason"] = "market_conduct_inquiry"
	life_state["legal_state"] = legal_state
	run_state.set_player_life(life_state)


func _build_offer(run_state, candidate: Dictionary, profile: Dictionary, day_number: int, trade_date: Dictionary) -> Dictionary:
	var company_id: String = str(candidate.get("company_id", ""))
	var ticker: String = str(candidate.get("ticker", company_id.to_upper()))
	var case_days: int = int(profile.get("case_days", 4))
	var request_id: String = "dirty_tip|%s|%d" % [company_id, day_number]
	var pressure_score: float = clamp(float(candidate.get("score", 0.0)), 0.0, 1.0)
	return {
		"id": request_id,
		"request_type": REQUEST_TYPE,
		"status": "offered",
		"direction": "pump",
		"created_day_index": int(run_state.day_index),
		"offered_day_index": int(run_state.day_index),
		"due_day_index": int(run_state.day_index) + 1,
		"decision_day_index": -1,
		"resolved_day_index": -1,
		"completed_day_index": -1,
		"active_until_day_index": -1,
		"trade_date": trade_date.duplicate(true),
		"contact_id": OPERATOR_CONTACT_ID,
		"contact_name": OPERATOR_CONTACT_NAME,
		"target_company_id": company_id,
		"target_ticker": ticker,
		"target_name": str(candidate.get("name", ticker)),
		"offer_headline": "A market room wants help moving %s." % ticker,
		"offer_body": "Someone you barely know says %s is thin enough to move if the tape gets loud. It is not a clean request." % ticker,
		"journal_detail": "An unsolicited room offer appeared for %s." % ticker,
		"case_days": case_days,
		"legal_days": int(profile.get("legal_days", 2)),
		"fine_pct": float(profile.get("fine_pct", 0.10)),
		"market_pressure_multiplier": float(profile.get("market_pressure", 0.78)),
		"pressure_score": snappedf(pressure_score, 0.001),
		"candidate_score": snappedf(float(candidate.get("score", pressure_score)), 0.001),
		"operator_pressure": snappedf(float(candidate.get("operator_pressure", 0.0)), 0.001),
		"player_relevance": snappedf(float(candidate.get("player_relevance", 0.0)), 0.001),
		"free_float_pct": snappedf(float(candidate.get("free_float_pct", 0.0)), 0.01),
		"avg_daily_value": float(candidate.get("avg_daily_value", 0.0)),
		"visible_depth_value": float(candidate.get("visible_depth_value", 0.0)),
		"difficulty_profile_id": str(profile.get("id", "normal")),
		"outcome_label": "",
		"outcome_note": ""
	}


func _select_candidate(run_state, data_repository, attention_directives: Dictionary, day_number: int, force_company_id: String = "") -> Dictionary:
	var candidates: Array = []
	var focus_weights: Dictionary = attention_directives.get("focus_company_weights", {}) if typeof(attention_directives.get("focus_company_weights", {})) == TYPE_DICTIONARY else {}
	var preferred_ids: Array = []
	if not force_company_id.strip_edges().is_empty():
		preferred_ids.append(force_company_id.strip_edges())
	for id_value in attention_directives.get("focus_company_ids", []):
		var id: String = str(id_value)
		if not id.is_empty() and not preferred_ids.has(id):
			preferred_ids.append(id)
	for company_id_value in run_state.company_order:
		var company_id: String = str(company_id_value)
		if not preferred_ids.has(company_id):
			preferred_ids.append(company_id)
	for company_id_value in preferred_ids:
		var company_id: String = str(company_id_value)
		var candidate: Dictionary = _score_candidate(run_state, data_repository, company_id, day_number, float(focus_weights.get(company_id, 1.0)), company_id == force_company_id)
		if not candidate.is_empty():
			candidates.append(candidate)
	if candidates.is_empty():
		return {}
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_state.run_seed, "dirty_tip_pick", day_number, force_company_id])
	var total_weight: float = 0.0
	for candidate_value in candidates:
		var candidate: Dictionary = candidate_value
		total_weight += max(float(candidate.get("weight", 0.0)), 0.001)
	var target: float = rng.randf() * total_weight
	var running: float = 0.0
	for candidate_value in candidates:
		var candidate: Dictionary = candidate_value
		running += max(float(candidate.get("weight", 0.0)), 0.001)
		if running >= target:
			return candidate
	return candidates[0]


func _score_candidate(run_state, _data_repository, company_id: String, day_number: int, focus_weight: float, forced: bool = false) -> Dictionary:
	var definition: Dictionary = run_state.get_effective_company_definition(company_id)
	var runtime: Dictionary = run_state.get_company(company_id)
	if definition.is_empty() or runtime.is_empty():
		return {}
	var company_profile: Dictionary = runtime.get("company_profile", {}) if typeof(runtime.get("company_profile", {})) == TYPE_DICTIONARY else {}
	if bool(company_profile.get("trade_disabled", false)):
		return {}
	var financials: Dictionary = definition.get("financials", {}) if typeof(definition.get("financials", {})) == TYPE_DICTIONARY else {}
	var current_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var avg_daily_value: float = max(float(financials.get("avg_daily_value", current_price * 250000.0)), current_price * 1000.0)
	var free_float_pct: float = clamp(float(financials.get("free_float_pct", 35.0)), 2.0, 95.0)
	var depth_context: Dictionary = runtime.get("market_depth_context", {}) if typeof(runtime.get("market_depth_context", {})) == TYPE_DICTIONARY else {}
	var visible_depth_value: float = max(float(depth_context.get("visible_depth_value", depth_context.get("ask_depth_value", avg_daily_value))), current_price * 1000.0)
	var traits: Dictionary = company_profile.get("generation_traits", {}) if typeof(company_profile.get("generation_traits", {})) == TYPE_DICTIONARY else {}
	var chart_profile: Dictionary = traits.get("chart_profile", {}) if typeof(traits.get("chart_profile", {})) == TYPE_DICTIONARY else {}
	var volume_context: Dictionary = runtime.get("volume_context", {}) if typeof(runtime.get("volume_context", {})) == TYPE_DICTIONARY else {}
	var broker_flow: Dictionary = runtime.get("broker_flow", {}) if typeof(runtime.get("broker_flow", {})) == TYPE_DICTIONARY else {}
	var player_flow: Dictionary = run_state.get_player_market_flow_context(company_id, day_number)
	var cash: float = max(float(run_state.player_portfolio.get("cash", 0.0)), 0.0)
	var holding: Dictionary = run_state.get_holding(company_id)
	var holding_value: float = float(holding.get("shares", 0)) * current_price
	var low_float_score: float = clamp((42.0 - free_float_pct) / 36.0, 0.0, 1.0)
	var thin_depth_score: float = clamp(cash / max(visible_depth_value, 1.0) / 1.4, 0.0, 1.0)
	var liquidity_score: float = clamp((log(avg_daily_value) - 14.0) / 6.0, 0.0, 1.0)
	var story_heat: float = clamp(float(traits.get("story_heat", 0.5)), 0.0, 1.0)
	var narrative_tags: Array = definition.get("narrative_tags", [])
	if "narrative_hot" in narrative_tags:
		story_heat = clamp(story_heat + 0.16, 0.0, 1.0)
	if "retail_favorite" in narrative_tags:
		story_heat = clamp(story_heat + 0.12, 0.0, 1.0)
	var operator_pressure: float = max(float(chart_profile.get("operator_pressure", 0.0)), float(volume_context.get("operator_pressure", 0.0)))
	operator_pressure = clamp(max(operator_pressure, float(depth_context.get("float_tightness", 0.0))), 0.0, 1.0)
	var broker_dirty: float = clamp(
		max(float(broker_flow.get("bandar_net", 0.0)), 0.0) / 100.0 * 0.45 +
		max(float(broker_flow.get("zombie_net", 0.0)), 0.0) / 100.0 * 0.34 +
		max(float(broker_flow.get("retail_net", 0.0)), 0.0) / 100.0 * 0.21,
		0.0,
		1.0
	)
	var player_relevance: float = holding_value / max(avg_daily_value, 1.0)
	player_relevance = max(player_relevance, cash / max(visible_depth_value, 1.0) / 1.4)
	player_relevance = max(player_relevance, float(player_flow.get("gross_free_float_pct", 0.0)) * 32.0)
	player_relevance = max(player_relevance, float(player_flow.get("max_single_trade_free_float_pct", 0.0)) * 54.0)
	player_relevance = clamp(max(player_relevance, float(player_flow.get("active_entries", 0)) * 0.07), 0.0, 1.0)
	if player_relevance < 0.05 and not forced:
		return {}
	var score: float = clamp(
		low_float_score * 0.22 +
		(1.0 - liquidity_score) * 0.12 +
		thin_depth_score * 0.14 +
		story_heat * 0.12 +
		operator_pressure * 0.18 +
		broker_dirty * 0.12 +
		player_relevance * 0.16 +
		clamp(focus_weight - 1.0, 0.0, 1.0) * 0.10,
		0.0,
		1.0
	)
	if forced:
		score = max(score, 0.62)
	if score < 0.34 and not forced:
		return {}
	return {
		"company_id": company_id,
		"ticker": str(definition.get("ticker", company_id.to_upper())),
		"name": str(definition.get("name", company_id.to_upper())),
		"score": score,
		"weight": max(pow(score, 2.0), 0.01) * max(focus_weight, 1.0),
		"operator_pressure": operator_pressure,
		"player_relevance": player_relevance,
		"free_float_pct": free_float_pct,
		"avg_daily_value": avg_daily_value,
		"visible_depth_value": visible_depth_value
	}


func _player_trade_stats_for_case(run_state, request: Dictionary) -> Dictionary:
	var company_id: String = str(request.get("target_company_id", ""))
	var start_day: int = int(request.get("decision_day_index", request.get("created_day_index", run_state.day_index)))
	var end_day: int = int(request.get("due_day_index", run_state.day_index))
	var buy_value: float = 0.0
	var sell_value: float = 0.0
	var gross_value: float = 0.0
	var realized_pnl: float = 0.0
	for trade_value in run_state.get_trade_history():
		if typeof(trade_value) != TYPE_DICTIONARY:
			continue
		var trade: Dictionary = trade_value
		if str(trade.get("company_id", "")) != company_id:
			continue
		var trade_day: int = int(trade.get("day_index", 0))
		if trade_day < start_day or trade_day > end_day:
			continue
		var value: float = max(float(trade.get("gross_value", 0.0)), 0.0)
		gross_value += value
		if str(trade.get("side", "")) == "buy":
			buy_value += value
		elif str(trade.get("side", "")) == "sell":
			sell_value += value
			realized_pnl += max(float(trade.get("realized_pnl", 0.0)), 0.0)
	var avg_daily_value: float = max(float(request.get("avg_daily_value", 1.0)), 1.0)
	return {
		"buy_value": buy_value,
		"sell_value": sell_value,
		"gross_value": gross_value,
		"net_value": buy_value - sell_value,
		"realized_pnl": realized_pnl,
		"gross_to_adv": clamp(gross_value / avg_daily_value, 0.0, 4.0),
		"profit_to_adv": clamp(realized_pnl / avg_daily_value, 0.0, 2.0)
	}


func _catch_probability(run_state, request: Dictionary, trade_stats: Dictionary) -> float:
	var visibility: Dictionary = _visibility_snapshot(run_state)
	var repeat_pressure: float = _repeat_dirty_tip_pressure(run_state)
	var raw: float = (
		clamp(float(trade_stats.get("gross_to_adv", 0.0)) / 1.3, 0.0, 1.0) * 0.34 +
		clamp(float(trade_stats.get("profit_to_adv", 0.0)) / 0.35, 0.0, 1.0) * 0.16 +
		float(request.get("operator_pressure", 0.0)) * 0.18 +
		float(request.get("pressure_score", 0.0)) * 0.12 +
		float(visibility.get("score", 0.0)) * 0.12 +
		repeat_pressure * 0.08
	)
	return clamp(raw * float(_difficulty_profile(run_state).get("catch_multiplier", 1.0)), 0.05, 0.86)


func _result_row(request: Dictionary, status: String, fine_amount: float, legal_days: int) -> Dictionary:
	return {
		"id": str(request.get("id", "")),
		"status": status,
		"target_company_id": str(request.get("target_company_id", "")),
		"target_ticker": str(request.get("target_ticker", "")),
		"outcome_label": str(request.get("outcome_label", status.capitalize())),
		"outcome_note": str(request.get("outcome_note", "")),
		"fine_amount": fine_amount,
		"legal_days": legal_days
	}


func _active_case_for_company(run_state, company_id: String, day_number: int) -> Dictionary:
	for request_value in run_state.get_network_requests().values():
		if typeof(request_value) != TYPE_DICTIONARY:
			continue
		var request: Dictionary = request_value
		if str(request.get("request_type", "")) != REQUEST_TYPE:
			continue
		if str(request.get("status", "")) != "accepted":
			continue
		if str(request.get("target_company_id", "")) != company_id:
			continue
		if int(request.get("decision_day_index", 0)) >= day_number:
			continue
		if int(request.get("active_until_day_index", request.get("due_day_index", 0))) < day_number:
			continue
		return request.duplicate(true)
	return {}


func _get_dirty_tip_request(run_state, offer_id: String) -> Dictionary:
	var requests: Dictionary = run_state.get_network_requests()
	if not requests.has(offer_id):
		return {}
	var request_value: Variant = requests.get(offer_id)
	if typeof(request_value) != TYPE_DICTIONARY:
		return {}
	var request: Dictionary = request_value
	if str(request.get("request_type", "")) != REQUEST_TYPE:
		return {}
	return request.duplicate(true)


func _has_open_dirty_tip(run_state) -> bool:
	for request_value in run_state.get_network_requests().values():
		if typeof(request_value) != TYPE_DICTIONARY:
			continue
		var request: Dictionary = request_value
		if str(request.get("request_type", "")) != REQUEST_TYPE:
			continue
		if str(request.get("status", "")) in ["offered", "accepted"]:
			return true
	return false


func _dirty_tip_cooldown_active(run_state, day_number: int) -> bool:
	for request_value in run_state.get_network_requests().values():
		if typeof(request_value) != TYPE_DICTIONARY:
			continue
		var request: Dictionary = request_value
		if str(request.get("request_type", "")) != REQUEST_TYPE:
			continue
		if int(request.get("suppress_until_day_index", -1)) >= day_number:
			return true
	return false


func _legal_hold_active(run_state) -> bool:
	var life_state: Dictionary = run_state.get_player_life()
	var legal_state: Dictionary = life_state.get("legal_state", {}) if typeof(life_state.get("legal_state", {})) == TYPE_DICTIONARY else {}
	return bool(legal_state.get("active", false)) and int(legal_state.get("days_remaining", 0)) > 0


func _visibility_snapshot(run_state) -> Dictionary:
	var difficulty_config: Dictionary = run_state.get_difficulty_config()
	var starting_cash: float = max(float(difficulty_config.get("starting_cash", 1.0)), 1.0)
	var equity: float = max(run_state.get_total_equity(), 0.0)
	var equity_ratio: float = equity / starting_cash
	var recognition_score: float = _recognition_score(run_state)
	var eligible: bool = recognition_score >= PLAYER_VISIBLE_RECOGNITION or equity_ratio >= PLAYER_VISIBLE_EQUITY_RATIO
	return {
		"eligible": eligible,
		"recognition_score": recognition_score,
		"equity_ratio": equity_ratio,
		"score": clamp(max(recognition_score / 100.0, (equity_ratio - 1.0) / 1.2), 0.0, 1.0)
	}


func _recognition_score(run_state) -> float:
	var difficulty_config: Dictionary = run_state.get_difficulty_config()
	var starting_cash: float = max(float(difficulty_config.get("starting_cash", 1.0)), 1.0)
	var equity: float = max(run_state.get_total_equity(), 0.0)
	var equity_score: float = clamp((equity - starting_cash) / starting_cash, 0.0, 1.0) * 40.0
	var holdings: Dictionary = run_state.player_portfolio.get("holdings", {})
	var held_company_count: int = 0
	for holding_value in holdings.values():
		if typeof(holding_value) == TYPE_DICTIONARY and int(holding_value.get("shares", 0)) >= int(run_state.LOT_SIZE):
			held_company_count += 1
	var exposure_ratio: float = 0.0
	if equity > 0.0:
		exposure_ratio = clamp(run_state.get_portfolio_market_value() / equity, 0.0, 1.0)
	var ownership_score: float = clamp(float(held_company_count) / 6.0, 0.0, 1.0) * 15.0 + exposure_ratio * 15.0
	var met_count: int = 0
	for runtime_value in run_state.get_network_contacts().values():
		if typeof(runtime_value) == TYPE_DICTIONARY and bool(runtime_value.get("met", false)):
			met_count += 1
	var contact_score: float = clamp(float(met_count) / 8.0, 0.0, 1.0) * 30.0
	return clamp(equity_score + ownership_score + contact_score, 0.0, 100.0)


func _repeat_dirty_tip_pressure(run_state) -> float:
	var count: int = 0
	for request_value in run_state.get_network_requests().values():
		if typeof(request_value) != TYPE_DICTIONARY:
			continue
		var request: Dictionary = request_value
		if str(request.get("request_type", "")) == REQUEST_TYPE and str(request.get("status", "")) == "caught":
			count += 1
	return clamp(float(count) / 3.0, 0.0, 1.0)


func _difficulty_profile(run_state) -> Dictionary:
	var difficulty_id: String = str(run_state.get_difficulty_config().get("id", "normal")).to_lower()
	var source: Dictionary = DIFFICULTY_PROFILES.get(difficulty_id, DIFFICULTY_PROFILES.get("normal", {}))
	var profile: Dictionary = source.duplicate(true)
	profile["id"] = difficulty_id if DIFFICULTY_PROFILES.has(difficulty_id) else "normal"
	return profile
