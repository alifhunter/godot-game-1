extends Node

const LOT_SIZE := 100
const BUY_FEE_RATE := 0.0015
const SELL_FEE_RATE := 0.0025
const MAX_TRADE_HISTORY := 64
const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")
const COMPANY_PROFILE_KEYS := [
	"base_price",
	"quality_score",
	"growth_score",
	"risk_score",
	"base_volatility",
	"financials",
	"financial_history",
	"generation_traits",
	"shares_outstanding"
]
const DEFAULT_DIFFICULTY_CONFIG := {
	"id": "normal",
	"label": "Normal",
	"starting_cash": 100000000.0,
	"company_count": 50,
	"market_swing_range": 0.02,
	"volatility_multiplier": 0.75,
	"event_interval_days": 30.0,
	"broker_impact_multiplier": 0.85,
	"daily_move_cap": 0.08,
	"volatility_label": "Low",
	"event_label": "Low"
}

var run_seed = 0
var day_index = 0
var market_sentiment = 0.0
var companies = {}
var company_definitions = {}
var company_order = []
var player_portfolio = {}
var daily_summary = {}
var last_day_results = {}
var last_equity_value = 0.0
var trade_history = []
var difficulty_id = "normal"
var difficulty_config = DEFAULT_DIFFICULTY_CONFIG.duplicate(true)
var tutorial_enabled = false
var tutorial_shown = false
var current_trade_date = {}
var trading_calendar = preload("res://systems/TradingCalendar.gd").new()
var company_generator = preload("res://systems/CompanyGenerator.gd").new()


func _ready() -> void:
	reset()


func reset() -> void:
	run_seed = 0
	day_index = 0
	market_sentiment = 0.0
	companies = {}
	company_definitions = {}
	company_order = []
	player_portfolio = {
		"cash": 0.0,
		"holdings": {},
		"realized_pnl": 0.0
	}
	daily_summary = {}
	last_day_results = {}
	last_equity_value = 0.0
	trade_history = []
	difficulty_id = str(DEFAULT_DIFFICULTY_CONFIG.get("id", "normal"))
	difficulty_config = DEFAULT_DIFFICULTY_CONFIG.duplicate(true)
	tutorial_enabled = false
	tutorial_shown = false
	current_trade_date = trading_calendar.start_date()


func has_active_run() -> bool:
	return not company_order.is_empty()


func setup_new_run(
	new_run_seed: int,
	run_company_definitions: Array,
	new_difficulty_config: Dictionary,
	wants_tutorial: bool
) -> void:
	reset()
	run_seed = new_run_seed
	difficulty_config = new_difficulty_config.duplicate(true)
	if difficulty_config.is_empty():
		difficulty_config = DEFAULT_DIFFICULTY_CONFIG.duplicate(true)

	difficulty_id = str(difficulty_config.get("id", "normal"))
	tutorial_enabled = wants_tutorial
	tutorial_shown = false
	current_trade_date = trading_calendar.start_date()
	player_portfolio["cash"] = float(difficulty_config.get("starting_cash", DEFAULT_DIFFICULTY_CONFIG.get("starting_cash", 0.0)))

	for definition in run_company_definitions:
		var base_definition: Dictionary = definition.duplicate(true)
		var company_id = str(base_definition.get("id", ""))
		if company_id.is_empty():
			continue

		self.company_definitions[company_id] = base_definition
		var sector_definition: Dictionary = DataRepository.get_sector_definition(str(base_definition.get("sector_id", "")))
		var company_profile: Dictionary = company_generator.generate_company_profile(base_definition, sector_definition, run_seed)
		var effective_definition: Dictionary = _apply_company_profile_to_definition(base_definition, company_profile)
		var base_price: float = IDX_PRICE_RULES.normalize_last_price(float(effective_definition.get("base_price", 0.0)))
		company_order.append(company_id)
		companies[company_id] = {
			"company_id": company_id,
			"current_price": base_price,
			"previous_close": base_price,
			"price_history": [base_price],
			"sentiment": 0.0,
			"active_event_tags": [],
			"hidden_story_flags": _seed_hidden_story_flags(base_definition),
			"broker_flow": _empty_broker_flow(),
			"daily_change_pct": 0.0,
			"company_profile": company_profile
		}

	last_equity_value = get_total_equity()


func load_from_dict(data: Dictionary) -> void:
	reset()
	run_seed = int(data.get("seed", 0))
	day_index = int(data.get("day_index", 0))
	market_sentiment = float(data.get("market_sentiment", 0.0))
	last_equity_value = float(data.get("last_equity_value", 0.0))
	daily_summary = data.get("daily_summary", {}).duplicate(true)
	last_day_results = data.get("last_day_results", {}).duplicate(true)
	trade_history = data.get("trade_history", []).duplicate(true)
	difficulty_id = str(data.get("difficulty_id", "normal"))
	difficulty_config = data.get("difficulty_config", {}).duplicate(true)
	if difficulty_config.is_empty():
		difficulty_config = DEFAULT_DIFFICULTY_CONFIG.duplicate(true)
		difficulty_config["id"] = difficulty_id

	difficulty_id = str(difficulty_config.get("id", difficulty_id))
	tutorial_enabled = bool(data.get("tutorial_enabled", false))
	tutorial_shown = bool(data.get("tutorial_shown", false))
	current_trade_date = data.get("current_trade_date", {}).duplicate(true)
	if current_trade_date.is_empty():
		current_trade_date = trading_calendar.trade_date_for_index(day_index + 1)

	for company_id in data.get("company_definitions", {}).keys():
		company_definitions[str(company_id)] = data["company_definitions"][company_id].duplicate(true)

	for company_id in data.get("company_order", []):
		company_order.append(str(company_id))

	for company_id in data.get("companies", {}).keys():
		companies[str(company_id)] = _normalize_company_runtime(data["companies"][company_id].duplicate(true))

	_ensure_company_profiles()

	player_portfolio = data.get("player_portfolio", {
		"cash": 0.0,
		"holdings": {},
		"realized_pnl": 0.0
	}).duplicate(true)


func to_save_dict() -> Dictionary:
	return {
		"seed": run_seed,
		"day_index": day_index,
		"market_sentiment": market_sentiment,
		"companies": companies.duplicate(true),
		"company_definitions": company_definitions.duplicate(true),
		"company_order": company_order.duplicate(),
		"player_portfolio": player_portfolio.duplicate(true),
		"daily_summary": daily_summary.duplicate(true),
		"last_day_results": last_day_results.duplicate(true),
		"last_equity_value": last_equity_value,
		"trade_history": trade_history.duplicate(true),
		"difficulty_id": difficulty_id,
		"difficulty_config": difficulty_config.duplicate(true),
		"tutorial_enabled": tutorial_enabled,
		"tutorial_shown": tutorial_shown,
		"current_trade_date": current_trade_date.duplicate(true)
	}


func get_company(company_id: String) -> Dictionary:
	if not companies.has(company_id):
		return {}
	return companies[company_id]


func get_company_profile(company_id: String) -> Dictionary:
	var company: Dictionary = get_company(company_id)
	if company.is_empty():
		return {}
	return company.get("company_profile", {}).duplicate(true)


func get_effective_company_definition(company_id: String) -> Dictionary:
	var definition: Dictionary = _get_base_company_definition(company_id)
	if definition.is_empty():
		return {}
	return _apply_company_profile_to_definition(definition, get_company_profile(company_id))


func get_effective_company_definitions() -> Array:
	var definitions: Array = []
	for company_id in company_order:
		var definition: Dictionary = get_effective_company_definition(str(company_id))
		if not definition.is_empty():
			definitions.append(definition)
	return definitions


func get_previous_close(company_id: String) -> float:
	var company = get_company(company_id)
	if company.is_empty():
		return 0.0

	var price_history: Array = company.get("price_history", [])
	if price_history.size() >= 2:
		return IDX_PRICE_RULES.normalize_last_price(float(price_history[price_history.size() - 2]))

	return IDX_PRICE_RULES.normalize_last_price(float(company.get("previous_close", company.get("current_price", 0.0))))


func get_holding(company_id: String) -> Dictionary:
	var holdings: Dictionary = player_portfolio.get("holdings", {})
	if not holdings.has(company_id):
		return {}
	return holdings[company_id]


func buy_company(company_id: String, shares: int) -> Dictionary:
	if not companies.has(company_id):
		return {"success": false, "message": "Unknown company selection."}
	if shares <= 0:
		return {"success": false, "message": "Share count must be positive."}

	var estimate: Dictionary = estimate_buy_order(company_id, shares)
	if not bool(estimate.get("success", false)):
		return estimate

	var total_cost = float(estimate.get("total_cost", 0.0))
	var fee = float(estimate.get("fee", 0.0))
	var cash_available = float(player_portfolio.get("cash", 0.0))

	if total_cost > cash_available + 0.0001:
		return {"success": false, "message": "Not enough cash for that order."}

	var holdings: Dictionary = player_portfolio.get("holdings", {})
	var holding: Dictionary = holdings.get(company_id, {
		"company_id": company_id,
		"shares": 0,
		"average_price": 0.0
	})
	var current_shares = int(holding.get("shares", 0))
	var current_average = float(holding.get("average_price", 0.0))
	var new_share_total = current_shares + shares
	var new_average = 0.0

	if new_share_total > 0:
		new_average = ((current_average * current_shares) + total_cost) / float(new_share_total)

	holding["shares"] = new_share_total
	holding["average_price"] = new_average
	holdings[company_id] = holding
	player_portfolio["holdings"] = holdings
	player_portfolio["cash"] = cash_available - total_cost
	_record_trade(
		company_id,
		"buy",
		estimate,
		0.0,
		-total_cost,
		float(player_portfolio.get("cash", 0.0))
	)

	return {
		"success": true,
		"message": "Bought %d lot(s) / %d share(s) of %s for %s including %s fee." % [
			int(estimate.get("lots", 0)),
			shares,
			company_id.to_upper(),
			_format_currency(total_cost),
			_format_currency(fee)
		]
	}


func sell_company(company_id: String, shares: int) -> Dictionary:
	if not companies.has(company_id):
		return {"success": false, "message": "Unknown company selection."}
	if shares <= 0:
		return {"success": false, "message": "Share count must be positive."}

	var holdings: Dictionary = player_portfolio.get("holdings", {})
	if not holdings.has(company_id):
		return {"success": false, "message": "You do not own that position yet."}

	var holding: Dictionary = holdings[company_id]
	var current_shares = int(holding.get("shares", 0))
	if shares > current_shares:
		return {"success": false, "message": "Not enough shares to sell."}

	var estimate: Dictionary = estimate_sell_order(company_id, shares)
	if not bool(estimate.get("success", false)):
		return estimate

	var fee = float(estimate.get("fee", 0.0))
	var net_proceeds = float(estimate.get("net_proceeds", 0.0))
	var average_price = float(holding.get("average_price", 0.0))
	var realized_pnl = net_proceeds - (average_price * shares)
	var remaining_shares = current_shares - shares

	if remaining_shares <= 0:
		holdings.erase(company_id)
	else:
		holding["shares"] = remaining_shares
		holdings[company_id] = holding

	player_portfolio["holdings"] = holdings
	player_portfolio["cash"] = float(player_portfolio.get("cash", 0.0)) + net_proceeds
	player_portfolio["realized_pnl"] = float(player_portfolio.get("realized_pnl", 0.0)) + realized_pnl
	_record_trade(
		company_id,
		"sell",
		estimate,
		realized_pnl,
		net_proceeds,
		float(player_portfolio.get("cash", 0.0))
	)

	return {
		"success": true,
		"message": "Sold %d lot(s) / %d share(s) of %s for %s after %s fee." % [
			int(estimate.get("lots", 0)),
			shares,
			company_id.to_upper(),
			_format_currency(net_proceeds),
			_format_currency(fee)
		]
	}


func get_portfolio_market_value() -> float:
	var total = 0.0
	var holdings: Dictionary = player_portfolio.get("holdings", {})

	for company_id in holdings.keys():
		if not companies.has(company_id):
			continue

		var holding: Dictionary = holdings[company_id]
		var shares = int(holding.get("shares", 0))
		var current_price = float(companies[company_id].get("current_price", 0.0))
		total += shares * current_price

	return total


func get_total_equity() -> float:
	return float(player_portfolio.get("cash", 0.0)) + get_portfolio_market_value()


func apply_day_result(day_result: Dictionary) -> void:
	day_index += 1
	market_sentiment = float(day_result.get("market_sentiment", market_sentiment))
	last_day_results = day_result.duplicate(true)
	current_trade_date = trading_calendar.next_trade_date(current_trade_date)

	for company_id in day_result.get("companies", {}).keys():
		companies[str(company_id)] = day_result["companies"][company_id].duplicate(true)


func set_daily_summary(summary: Dictionary) -> void:
	daily_summary = summary.duplicate(true)
	last_equity_value = get_total_equity()


func get_difficulty_config() -> Dictionary:
	return difficulty_config.duplicate(true)


func get_current_trade_date() -> Dictionary:
	return current_trade_date.duplicate(true)


func get_next_trade_date() -> Dictionary:
	return trading_calendar.next_trade_date(current_trade_date)


func get_trade_history() -> Array:
	return trade_history.duplicate(true)


func estimate_buy_order(company_id: String, shares: int) -> Dictionary:
	return _estimate_order(company_id, shares, true)


func estimate_sell_order(company_id: String, shares: int) -> Dictionary:
	return _estimate_order(company_id, shares, false)


func should_show_tutorial() -> bool:
	return tutorial_enabled and not tutorial_shown


func mark_tutorial_shown() -> void:
	tutorial_shown = true


func _seed_hidden_story_flags(definition: Dictionary) -> Array:
	var hidden_flags = []
	for narrative_tag in definition.get("narrative_tags", []):
		if str(narrative_tag) in ["stealth_interest", "institution_quality", "supportive_balance_sheet"]:
			hidden_flags.append(str(narrative_tag))
	return hidden_flags


func _empty_broker_flow() -> Dictionary:
	return {
		"retail_net": 0.0,
		"foreign_net": 0.0,
		"institution_net": 0.0,
		"zombie_net": 0.0,
		"net_pressure": 0.0,
		"dominant_buyer": "balanced",
		"dominant_seller": "balanced",
		"flow_tag": "neutral"
	}


func _record_trade(
	company_id: String,
	side: String,
	estimate: Dictionary,
	realized_pnl: float,
	net_cash_impact: float,
	cash_after: float
) -> void:
	var entry: Dictionary = {
		"day_index": day_index,
		"company_id": company_id,
		"side": side,
		"lots": int(estimate.get("lots", 0)),
		"shares": int(estimate.get("shares", 0)),
		"price_per_share": float(estimate.get("price_per_share", 0.0)),
		"gross_value": float(estimate.get("gross_value", 0.0)),
		"fee_rate": float(estimate.get("fee_rate", 0.0)),
		"fee": float(estimate.get("fee", 0.0)),
		"net_cash_impact": net_cash_impact,
		"cash_after": cash_after,
		"realized_pnl": realized_pnl
	}

	trade_history.append(entry)
	if trade_history.size() > MAX_TRADE_HISTORY:
		trade_history = trade_history.slice(trade_history.size() - MAX_TRADE_HISTORY, trade_history.size())


func _normalize_company_runtime(runtime: Dictionary) -> Dictionary:
	var normalized_runtime: Dictionary = runtime.duplicate(true)
	normalized_runtime["current_price"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_runtime.get("current_price", 0.0)))
	normalized_runtime["previous_close"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_runtime.get("previous_close", normalized_runtime.get("current_price", 0.0))))
	normalized_runtime["price_history"] = _normalize_price_history(normalized_runtime.get("price_history", []))
	normalized_runtime["company_profile"] = _normalize_company_profile(normalized_runtime.get("company_profile", {}))
	return normalized_runtime


func _normalize_price_history(price_history: Array) -> Array:
	var normalized_history: Array = []
	for price in price_history:
		normalized_history.append(IDX_PRICE_RULES.normalize_last_price(float(price)))
	return normalized_history


func _normalize_company_profile(company_profile: Dictionary) -> Dictionary:
	var normalized_profile: Dictionary = company_profile.duplicate(true)
	if normalized_profile.is_empty():
		return {}

	normalized_profile["base_price"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_profile.get("base_price", 0.0)))
	var financial_history: Array = []
	for history_entry_value in normalized_profile.get("financial_history", []):
		var history_entry: Dictionary = history_entry_value.duplicate(true)
		if history_entry.has("implied_share_price"):
			history_entry["implied_share_price"] = IDX_PRICE_RULES.normalize_last_price(float(history_entry.get("implied_share_price", 0.0)))
		financial_history.append(history_entry)
	normalized_profile["financial_history"] = financial_history
	return normalized_profile


func _ensure_company_profiles() -> void:
	for company_id_value in company_order:
		var company_id: String = str(company_id_value)
		if not companies.has(company_id):
			continue

		var runtime: Dictionary = companies[company_id].duplicate(true)
		var company_profile: Dictionary = runtime.get("company_profile", {})
		if company_profile.is_empty():
			var template: Dictionary = _get_base_company_definition(company_id)
			if template.is_empty():
				continue

			var sector_definition: Dictionary = DataRepository.get_sector_definition(str(template.get("sector_id", "")))
			company_profile = company_generator.generate_company_profile(template, sector_definition, run_seed)
			runtime["company_profile"] = company_profile
			companies[company_id] = runtime


func _get_base_company_definition(company_id: String) -> Dictionary:
	if company_definitions.has(company_id):
		return company_definitions[company_id].duplicate(true)
	return DataRepository.get_company_archetype(company_id)


func _apply_company_profile_to_definition(definition: Dictionary, company_profile: Dictionary) -> Dictionary:
	var effective_definition: Dictionary = definition.duplicate(true)
	for profile_key_value in COMPANY_PROFILE_KEYS:
		var profile_key: String = str(profile_key_value)
		if company_profile.has(profile_key):
			effective_definition[profile_key] = company_profile[profile_key]
	return effective_definition


func _estimate_order(company_id: String, shares: int, is_buy: bool) -> Dictionary:
	if not companies.has(company_id):
		return {"success": false, "message": "Unknown company selection."}
	if shares <= 0:
		return {"success": false, "message": "Share count must be positive."}

	var current_price = float(companies[company_id].get("current_price", 0.0))
	var gross_value: float = current_price * shares
	var fee_rate: float = BUY_FEE_RATE if is_buy else SELL_FEE_RATE
	var fee: float = gross_value * fee_rate
	var lots: int = int(round(float(shares) / float(LOT_SIZE)))
	var result: Dictionary = {
		"success": true,
		"shares": shares,
		"lots": lots,
		"price_per_share": current_price,
		"gross_value": gross_value,
		"fee_rate": fee_rate,
		"fee": fee
	}

	if is_buy:
		result["total_cost"] = gross_value + fee
	else:
		result["net_proceeds"] = gross_value - fee

	return result


func _format_currency(value: float) -> String:
	return "Rp %s" % String.num(value, 2)
