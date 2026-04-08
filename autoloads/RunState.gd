extends Node

const LOT_SIZE := 100
const BUY_FEE_RATE := 0.0015
const SELL_FEE_RATE := 0.0025
const MAX_TRADE_HISTORY := 64
const MAX_EVENT_HISTORY := 160
const MAX_MARKET_HISTORY := 512
const MAX_PRICE_BARS_HISTORY := 1600
const CHART_HISTORY_VISIBLE_BARS := 1260
const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")
const COMPANY_PROFILE_KEYS := [
	"base_price",
	"quality_score",
	"growth_score",
	"risk_score",
	"base_volatility",
	"financials",
	"financial_history",
	"financial_statement_snapshot",
	"generation_traits",
	"shares_outstanding",
	"profile_seed",
	"archetype_id",
	"archetype_label",
	"company_size_id",
	"company_size_label",
	"company_age",
	"founded_year",
	"employee_count",
	"profile_revenue",
	"profile_revenue_value",
	"profile_revenue_unit",
	"profile_description",
	"profile_tags"
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
var watchlist_company_ids = []
var player_portfolio = {}
var daily_summary = {}
var last_day_results = {}
var last_equity_value = 0.0
var trade_history = []
var event_history = []
var market_history = []
var active_company_arcs = []
var active_special_events = []
var yearly_macro_states = {}
var historical_chart_bar_cache = {}
var difficulty_id = "normal"
var difficulty_config = DEFAULT_DIFFICULTY_CONFIG.duplicate(true)
var tutorial_enabled = false
var tutorial_shown = false
var current_trade_date = {}
var trading_calendar = preload("res://systems/TradingCalendar.gd").new()
var company_generator = preload("res://systems/CompanyGenerator.gd").new()
var macro_state_system = preload("res://systems/MacroStateSystem.gd").new()


func _ready() -> void:
	reset()


func reset() -> void:
	run_seed = 0
	day_index = 0
	market_sentiment = 0.0
	companies = {}
	company_definitions = {}
	company_order = []
	watchlist_company_ids = []
	player_portfolio = {
		"cash": 0.0,
		"holdings": {},
		"realized_pnl": 0.0
	}
	daily_summary = {}
	last_day_results = {}
	last_equity_value = 0.0
	trade_history = []
	event_history = []
	market_history = []
	active_company_arcs = []
	active_special_events = []
	yearly_macro_states = {}
	historical_chart_bar_cache = {}
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
	_ensure_macro_state_for_year(int(current_trade_date.get("year", 2020)))

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
			"starting_price": base_price,
			"ytd_open_price": base_price,
			"ytd_reference_year": int(current_trade_date.get("year", 2020)),
			"price_history": [base_price],
			"price_bars": [],
			"sentiment": 0.0,
			"active_event_tags": [],
			"active_events": [],
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
	event_history = data.get("event_history", []).duplicate(true)
	market_history = data.get("market_history", []).duplicate(true)
	active_company_arcs = data.get("active_company_arcs", []).duplicate(true)
	active_special_events = data.get("active_special_events", []).duplicate(true)
	yearly_macro_states = data.get("yearly_macro_states", {}).duplicate(true)
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
	_ensure_macro_state_for_year(int(current_trade_date.get("year", 2020)))

	for company_id in data.get("company_definitions", {}).keys():
		company_definitions[str(company_id)] = data["company_definitions"][company_id].duplicate(true)

	for company_id in data.get("company_order", []):
		company_order.append(str(company_id))

	for company_id_value in data.get("watchlist_company_ids", []):
		var company_id: String = str(company_id_value)
		if company_id.is_empty() or watchlist_company_ids.has(company_id):
			continue
		watchlist_company_ids.append(company_id)

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
		"watchlist_company_ids": watchlist_company_ids.duplicate(),
		"player_portfolio": player_portfolio.duplicate(true),
		"daily_summary": daily_summary.duplicate(true),
		"last_day_results": last_day_results.duplicate(true),
		"last_equity_value": last_equity_value,
		"trade_history": trade_history.duplicate(true),
		"event_history": event_history.duplicate(true),
		"market_history": market_history.duplicate(true),
		"active_company_arcs": active_company_arcs.duplicate(true),
		"active_special_events": active_special_events.duplicate(true),
		"yearly_macro_states": yearly_macro_states.duplicate(true),
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


func get_company_chart_bars(company_id: String) -> Array:
	var runtime: Dictionary = get_company(company_id)
	if runtime.is_empty():
		return []

	var runtime_bars: Array = runtime.get("price_bars", []).duplicate(true)
	if runtime_bars.size() >= CHART_HISTORY_VISIBLE_BARS:
		return runtime_bars.slice(
			runtime_bars.size() - CHART_HISTORY_VISIBLE_BARS,
			runtime_bars.size()
		)

	var historical_bars: Array = _get_historical_chart_bars(company_id, runtime, runtime_bars)
	if historical_bars.is_empty():
		return runtime_bars

	var combined_bars: Array = historical_bars.duplicate(true)
	combined_bars.append_array(runtime_bars)
	if combined_bars.size() > CHART_HISTORY_VISIBLE_BARS:
		combined_bars = combined_bars.slice(
			combined_bars.size() - CHART_HISTORY_VISIBLE_BARS,
			combined_bars.size()
		)
	return combined_bars


func get_company_profile(
	company_id: String,
	include_financial_history: bool = true,
	include_statement_history: bool = true
) -> Dictionary:
	var company: Dictionary = get_company(company_id)
	if company.is_empty():
		return {}
	return _build_company_profile_view(
		company.get("company_profile", {}),
		include_financial_history,
		include_statement_history
	)


func get_effective_company_definition(
	company_id: String,
	include_financial_history: bool = true,
	include_statement_history: bool = true
) -> Dictionary:
	var definition: Dictionary = _get_base_company_definition(company_id)
	if definition.is_empty():
		return {}
	return _apply_company_profile_to_definition(
		definition,
		get_company_profile(company_id, include_financial_history, include_statement_history)
	)


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


func get_watchlist_company_ids() -> Array:
	var normalized_ids: Array = []
	for company_id_value in watchlist_company_ids:
		var company_id: String = str(company_id_value)
		if company_id.is_empty() or normalized_ids.has(company_id) or not companies.has(company_id):
			continue
		normalized_ids.append(company_id)
	return normalized_ids


func is_in_watchlist(company_id: String) -> bool:
	return get_watchlist_company_ids().has(company_id)


func add_to_watchlist(company_id: String) -> Dictionary:
	if not companies.has(company_id):
		return {"success": false, "message": "Unknown company selection."}
	if is_in_watchlist(company_id):
		return {"success": false, "message": "%s is already in the watchlist." % str(get_effective_company_definition(company_id).get("ticker", company_id.to_upper()))}

	watchlist_company_ids.append(company_id)
	var ticker: String = str(get_effective_company_definition(company_id).get("ticker", company_id.to_upper()))
	return {
		"success": true,
		"message": "%s added to the watchlist." % ticker
	}


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
	var previous_trade_date: Dictionary = current_trade_date.duplicate(true)
	_record_event(day_result.get("scheduled_event", {}), day_result.get("trade_date", {}), int(day_result.get("day_number", day_index)))
	for company_arc_value in day_result.get("started_company_arcs", []):
		_record_event(company_arc_value, day_result.get("trade_date", {}), int(day_result.get("day_number", day_index)))
	for company_arc_phase_value in day_result.get("company_arc_phase_events", []):
		_record_event(company_arc_phase_value, day_result.get("trade_date", {}), int(day_result.get("day_number", day_index)))
	for special_event_value in day_result.get("started_special_events", []):
		_record_event(special_event_value, day_result.get("trade_date", {}), int(day_result.get("day_number", day_index)))
	active_company_arcs = day_result.get("active_company_arcs", []).duplicate(true)
	active_special_events = day_result.get("active_special_events", []).duplicate(true)

	for company_id in day_result.get("companies", {}).keys():
		companies[str(company_id)] = _normalize_company_runtime(day_result["companies"][company_id].duplicate(true))

	current_trade_date = trading_calendar.next_trade_date(current_trade_date)
	var previous_year: int = int(previous_trade_date.get("year", 2020))
	var current_year: int = int(current_trade_date.get("year", previous_year))
	if current_year != previous_year:
		_reset_ytd_open_prices_for_year(current_year)
	_ensure_macro_state_for_year(current_year)


func set_daily_summary(summary: Dictionary) -> void:
	daily_summary = summary.duplicate(true)
	_record_market_history(summary)
	last_equity_value = get_total_equity()


func get_difficulty_config() -> Dictionary:
	return difficulty_config.duplicate(true)


func get_current_trade_date() -> Dictionary:
	return current_trade_date.duplicate(true)


func get_current_macro_state() -> Dictionary:
	return get_macro_state_for_year(int(current_trade_date.get("year", 2020)))


func get_macro_state_for_year(year: int) -> Dictionary:
	_ensure_macro_state_for_year(year)
	var year_key: String = str(year)
	if not yearly_macro_states.has(year_key):
		return {}
	return yearly_macro_states[year_key].duplicate(true)


func get_macro_state_history() -> Array:
	var year_keys: Array = yearly_macro_states.keys()
	year_keys.sort()
	var history: Array = []
	for year_key_value in year_keys:
		history.append(yearly_macro_states[str(year_key_value)].duplicate(true))
	return history


func get_next_trade_date() -> Dictionary:
	return trading_calendar.next_trade_date(current_trade_date)


func get_trade_history() -> Array:
	return trade_history.duplicate(true)


func get_event_history() -> Array:
	return event_history.duplicate(true)


func get_market_history() -> Array:
	return market_history.duplicate(true)


func get_active_company_arcs() -> Array:
	return active_company_arcs.duplicate(true)


func get_active_special_events() -> Array:
	return active_special_events.duplicate(true)


func debug_add_recorded_event(event_data: Dictionary) -> void:
	if event_data.is_empty():
		return

	var resolved_trade_date: Dictionary = current_trade_date.duplicate(true)
	var resolved_day_index: int = max(day_index, 1)
	_record_event(event_data, resolved_trade_date, resolved_day_index)
	_append_event_to_companies(event_data)


func debug_add_special_event(event_data: Dictionary) -> void:
	if event_data.is_empty():
		return

	active_special_events.append(event_data.duplicate(true))
	var resolved_trade_date: Dictionary = current_trade_date.duplicate(true)
	var resolved_day_index: int = max(day_index, 1)
	_record_event(event_data, resolved_trade_date, resolved_day_index)
	_append_event_to_companies(event_data)


func debug_add_company_arc(arc_data: Dictionary, start_event: Dictionary) -> void:
	if arc_data.is_empty():
		return

	active_company_arcs.append(arc_data.duplicate(true))
	if not start_event.is_empty():
		var resolved_trade_date: Dictionary = current_trade_date.duplicate(true)
		var resolved_day_index: int = max(day_index, 1)
		_record_event(start_event, resolved_trade_date, resolved_day_index)
	_append_company_arc_to_companies(arc_data)


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


func _record_event(event_data: Dictionary, trade_date: Dictionary, resolved_day_index: int) -> void:
	if event_data.is_empty():
		return

	var event_definition: Dictionary = DataRepository.get_event_definition(str(event_data.get("event_id", "")))
	var entry: Dictionary = event_data.duplicate(true)
	entry["day_index"] = resolved_day_index
	entry["trade_date"] = trade_date.duplicate(true)
	entry["scope"] = str(entry.get("scope", event_definition.get("scope", "")))
	entry["event_family"] = str(entry.get("event_family", event_definition.get("event_family", "")))
	entry["category"] = str(entry.get("category", event_definition.get("category", "")))
	entry["tone"] = str(entry.get("tone", event_definition.get("tone", "")))
	entry["description"] = str(entry.get("description", event_definition.get("description", "")))
	event_history.append(entry)
	if event_history.size() > MAX_EVENT_HISTORY:
		event_history = event_history.slice(event_history.size() - MAX_EVENT_HISTORY, event_history.size())


func _record_market_history(summary: Dictionary) -> void:
	if summary.is_empty():
		return

	var advancers: int = 0
	var decliners: int = 0
	var average_change_pct_sum: float = 0.0
	var company_count: int = 0
	for runtime_value in companies.values():
		var runtime: Dictionary = runtime_value
		var daily_change_pct: float = float(runtime.get("daily_change_pct", 0.0))
		average_change_pct_sum += daily_change_pct
		company_count += 1
		if daily_change_pct > 0.0:
			advancers += 1
		elif daily_change_pct < 0.0:
			decliners += 1

	var average_change_pct: float = 0.0
	if company_count > 0:
		average_change_pct = average_change_pct_sum / float(company_count)

	var history_entry: Dictionary = {
		"day_index": int(summary.get("day_index", day_index)),
		"trade_date": last_day_results.get("trade_date", {}).duplicate(true),
		"market_sentiment": market_sentiment,
		"average_change_pct": average_change_pct,
		"advancers": advancers,
		"decliners": decliners,
		"flat_count": max(company_count - advancers - decliners, 0),
		"company_count": company_count,
		"equity": get_total_equity(),
		"portfolio_delta": float(summary.get("portfolio_delta", 0.0)),
		"biggest_winner": summary.get("biggest_winner", {}).duplicate(true),
		"biggest_loser": summary.get("biggest_loser", {}).duplicate(true)
	}

	if not market_history.is_empty() and int(market_history[market_history.size() - 1].get("day_index", -1)) == int(history_entry.get("day_index", -2)):
		market_history[market_history.size() - 1] = history_entry
	else:
		market_history.append(history_entry)

	if market_history.size() > MAX_MARKET_HISTORY:
		market_history = market_history.slice(market_history.size() - MAX_MARKET_HISTORY, market_history.size())


func _append_event_to_companies(event_data: Dictionary) -> void:
	var event_id: String = str(event_data.get("event_id", ""))
	if event_id.is_empty():
		return

	for company_id_value in company_order:
		var company_id: String = str(company_id_value)
		if not companies.has(company_id):
			continue

		var definition: Dictionary = get_effective_company_definition(company_id, false, false)
		if definition.is_empty():
			continue

		if not _event_applies_to_company(event_data, company_id, str(definition.get("sector_id", ""))):
			continue

		var runtime: Dictionary = companies[company_id].duplicate(true)
		var active_events: Array = runtime.get("active_events", []).duplicate(true)
		if not _active_event_exists(active_events, event_data):
			active_events.append(event_data.duplicate(true))
		runtime["active_events"] = active_events

		var active_event_tags: Array = runtime.get("active_event_tags", []).duplicate()
		if not active_event_tags.has(event_id):
			active_event_tags.append(event_id)
		runtime["active_event_tags"] = active_event_tags
		companies[company_id] = runtime


func _append_company_arc_to_companies(arc_data: Dictionary) -> void:
	var company_id: String = str(arc_data.get("target_company_id", ""))
	if company_id.is_empty() or not companies.has(company_id):
		return

	var runtime: Dictionary = companies[company_id].duplicate(true)
	var hidden_story_flags: Array = runtime.get("hidden_story_flags", []).duplicate()
	var phase_visibility: String = str(arc_data.get("phase_visibility", "hidden"))
	if phase_visibility == "hidden":
		var hidden_flag: String = str(arc_data.get("phase_hidden_flag", arc_data.get("hidden_story_flag", "")))
		if not hidden_flag.is_empty() and not hidden_story_flags.has(hidden_flag):
			hidden_story_flags.append(hidden_flag)
		runtime["hidden_story_flags"] = hidden_story_flags
		companies[company_id] = runtime
		return

	runtime["hidden_story_flags"] = hidden_story_flags
	companies[company_id] = runtime
	var visible_arc: Dictionary = arc_data.duplicate(true)
	visible_arc["sentiment_shift"] = float(arc_data.get("phase_sentiment_shift", 0.0))
	_append_event_to_companies(visible_arc)


func _event_applies_to_company(event_data: Dictionary, company_id: String, sector_id: String) -> bool:
	if event_data.is_empty():
		return false

	var scope: String = str(event_data.get("scope", "company"))
	if scope == "market":
		return true
	if scope == "sector":
		var target_sector_id: String = str(event_data.get("target_sector_id", ""))
		if not target_sector_id.is_empty():
			return target_sector_id == sector_id
		return sector_id in event_data.get("affected_sector_ids", [])
	return str(event_data.get("target_company_id", "")) == company_id


func _active_event_exists(active_events: Array, event_data: Dictionary) -> bool:
	var event_id: String = str(event_data.get("event_id", ""))
	var target_company_id: String = str(event_data.get("target_company_id", ""))
	var target_sector_id: String = str(event_data.get("target_sector_id", ""))
	var headline: String = str(event_data.get("headline", ""))
	var arc_id: String = str(event_data.get("arc_id", ""))

	for active_event_value in active_events:
		var active_event: Dictionary = active_event_value
		if str(active_event.get("event_id", "")) != event_id:
			continue
		if str(active_event.get("arc_id", "")) == arc_id and not arc_id.is_empty():
			return true
		if str(active_event.get("target_company_id", "")) != target_company_id:
			continue
		if str(active_event.get("target_sector_id", "")) != target_sector_id:
			continue
		if str(active_event.get("headline", "")) == headline:
			return true

	return false


func _normalize_company_runtime(runtime: Dictionary) -> Dictionary:
	var normalized_runtime: Dictionary = runtime.duplicate(true)
	normalized_runtime["current_price"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_runtime.get("current_price", 0.0)))
	normalized_runtime["previous_close"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_runtime.get("previous_close", normalized_runtime.get("current_price", 0.0))))
	normalized_runtime["starting_price"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_runtime.get("starting_price", normalized_runtime.get("current_price", 0.0))))
	normalized_runtime["ytd_open_price"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_runtime.get("ytd_open_price", normalized_runtime.get("starting_price", normalized_runtime.get("current_price", 0.0)))))
	normalized_runtime["ytd_reference_year"] = int(normalized_runtime.get("ytd_reference_year", int(current_trade_date.get("year", 2020))))
	normalized_runtime["price_history"] = _normalize_price_history(normalized_runtime.get("price_history", []))
	normalized_runtime["price_bars"] = _normalize_price_bars(
		normalized_runtime.get("price_bars", []),
		normalized_runtime.get("price_history", [])
	)
	if normalized_runtime["price_history"].is_empty() and not normalized_runtime["price_bars"].is_empty():
		normalized_runtime["price_history"] = _rebuild_price_history_from_bars(normalized_runtime["price_bars"])
	normalized_runtime["company_profile"] = _normalize_company_profile(normalized_runtime.get("company_profile", {}))
	normalized_runtime["active_events"] = normalized_runtime.get("active_events", []).duplicate(true)
	return normalized_runtime


func _normalize_price_history(price_history: Array) -> Array:
	var normalized_history: Array = []
	for price in price_history:
		normalized_history.append(IDX_PRICE_RULES.normalize_last_price(float(price)))
	return normalized_history


func _normalize_price_bars(price_bars: Array, price_history: Array) -> Array:
	var normalized_bars: Array = []
	for bar_value in price_bars:
		if typeof(bar_value) != TYPE_DICTIONARY:
			continue
		normalized_bars.append(_normalize_price_bar(bar_value.duplicate(true)))

	if normalized_bars.is_empty():
		normalized_bars = _rebuild_price_bars_from_history(price_history)

	if normalized_bars.size() > MAX_PRICE_BARS_HISTORY:
		normalized_bars = normalized_bars.slice(
			normalized_bars.size() - MAX_PRICE_BARS_HISTORY,
			normalized_bars.size()
		)
	return normalized_bars


func _normalize_price_bar(bar: Dictionary) -> Dictionary:
	var trade_date_value = bar.get("trade_date", {})
	var trade_date: Dictionary = trade_date_value.duplicate(true) if typeof(trade_date_value) == TYPE_DICTIONARY else {}
	var normalized_bar: Dictionary = {
		"trade_date": trade_date,
		"open": IDX_PRICE_RULES.normalize_last_price(float(bar.get("open", 0.0))),
		"high": IDX_PRICE_RULES.normalize_last_price(float(bar.get("high", bar.get("open", 0.0)))),
		"low": IDX_PRICE_RULES.normalize_last_price(float(bar.get("low", bar.get("open", 0.0)))),
		"close": IDX_PRICE_RULES.normalize_last_price(float(bar.get("close", bar.get("open", 0.0)))),
		"volume_shares": max(int(bar.get("volume_shares", 0)), 0),
		"value": max(float(bar.get("value", 0.0)), 0.0)
	}
	normalized_bar["high"] = max(
		float(normalized_bar.get("high", 0.0)),
		float(normalized_bar.get("open", 0.0)),
		float(normalized_bar.get("close", 0.0))
	)
	normalized_bar["low"] = min(
		float(normalized_bar.get("low", 0.0)),
		float(normalized_bar.get("open", 0.0)),
		float(normalized_bar.get("close", 0.0))
	)
	normalized_bar["volume_lots"] = int(floor(float(normalized_bar.get("volume_shares", 0)) / float(LOT_SIZE)))
	if is_zero_approx(float(normalized_bar.get("value", 0.0))):
		normalized_bar["value"] = float(normalized_bar.get("close", 0.0)) * float(normalized_bar.get("volume_shares", 0))
	return normalized_bar


func _rebuild_price_bars_from_history(price_history: Array) -> Array:
	var normalized_history: Array = _normalize_price_history(price_history)
	if normalized_history.size() < 2:
		return []

	var rebuilt_bars: Array = []
	var start_history_index: int = max(normalized_history.size() - MAX_PRICE_BARS_HISTORY, 1)
	for history_index in range(start_history_index, normalized_history.size()):
		var previous_close: float = float(normalized_history[history_index - 1])
		var current_close: float = float(normalized_history[history_index])
		rebuilt_bars.append(_normalize_price_bar({
			"trade_date": trading_calendar.trade_date_for_index(history_index),
			"open": previous_close,
			"high": max(previous_close, current_close),
			"low": min(previous_close, current_close),
			"close": current_close,
			"volume_shares": 0,
			"value": 0.0
		}))
	return rebuilt_bars


func _rebuild_price_history_from_bars(price_bars: Array) -> Array:
	if price_bars.is_empty():
		return []

	var history: Array = [float(price_bars[0].get("open", 0.0))]
	for bar_value in price_bars:
		var bar: Dictionary = bar_value
		history.append(float(bar.get("close", 0.0)))
	return _normalize_price_history(history)


func _normalize_company_profile(company_profile: Dictionary) -> Dictionary:
	var normalized_profile: Dictionary = company_profile.duplicate(true)
	if normalized_profile.is_empty():
		return {}

	normalized_profile["base_price"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_profile.get("base_price", 0.0)))
	normalized_profile["profile_seed"] = int(normalized_profile.get("profile_seed", 0))
	normalized_profile["company_size_id"] = int(normalized_profile.get("company_size_id", 0))
	normalized_profile["company_age"] = int(normalized_profile.get("company_age", 0))
	normalized_profile["founded_year"] = int(normalized_profile.get("founded_year", 0))
	normalized_profile["employee_count"] = int(normalized_profile.get("employee_count", 0))
	normalized_profile["profile_revenue"] = float(normalized_profile.get("profile_revenue", 0.0))
	normalized_profile["profile_revenue_value"] = float(normalized_profile.get("profile_revenue_value", 0.0))
	normalized_profile["archetype_id"] = str(normalized_profile.get("archetype_id", ""))
	normalized_profile["archetype_label"] = str(normalized_profile.get("archetype_label", ""))
	normalized_profile["company_size_label"] = str(normalized_profile.get("company_size_label", ""))
	normalized_profile["profile_revenue_unit"] = str(normalized_profile.get("profile_revenue_unit", ""))
	normalized_profile["profile_description"] = str(normalized_profile.get("profile_description", ""))
	var profile_tags: Array = []
	for tag_value in normalized_profile.get("profile_tags", []):
		var tag: String = str(tag_value).strip_edges()
		if tag.is_empty():
			continue
		profile_tags.append(tag)
	normalized_profile["profile_tags"] = profile_tags
	var financial_history: Array = []
	for history_entry_value in normalized_profile.get("financial_history", []):
		var history_entry: Dictionary = history_entry_value.duplicate(true)
		if history_entry.has("implied_share_price"):
			history_entry["implied_share_price"] = IDX_PRICE_RULES.normalize_last_price(float(history_entry.get("implied_share_price", 0.0)))
		financial_history.append(history_entry)
	normalized_profile["financial_history"] = financial_history
	normalized_profile["financial_statement_snapshot"] = normalized_profile.get("financial_statement_snapshot", {}).duplicate(true)
	return normalized_profile


func _get_historical_chart_bars(company_id: String, runtime: Dictionary, runtime_bars: Array) -> Array:
	if historical_chart_bar_cache.has(company_id):
		return historical_chart_bar_cache[company_id].duplicate(true)

	var required_bars: int = max(CHART_HISTORY_VISIBLE_BARS - runtime_bars.size(), 0)
	if required_bars <= 0:
		return []

	var historical_end_date: Dictionary = _historical_chart_end_date(runtime_bars)
	if historical_end_date.is_empty():
		return []

	var company_profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	if company_profile.is_empty():
		return []

	var generated_bars: Array = company_generator.build_historical_chart_bars(
		company_profile,
		_build_historical_trade_dates(historical_end_date, required_bars),
		_historical_chart_end_close(runtime, runtime_bars),
		run_seed,
		company_id
	)
	var normalized_bars: Array = _normalize_price_bars(generated_bars, [])
	historical_chart_bar_cache[company_id] = normalized_bars
	return normalized_bars.duplicate(true)


func _historical_chart_end_date(runtime_bars: Array) -> Dictionary:
	if not runtime_bars.is_empty():
		return trading_calendar.previous_trade_date(
			runtime_bars[0].get("trade_date", current_trade_date)
		)
	return trading_calendar.previous_trade_date(current_trade_date)


func _historical_chart_end_close(runtime: Dictionary, runtime_bars: Array) -> float:
	if not runtime_bars.is_empty():
		return IDX_PRICE_RULES.normalize_last_price(float(
			runtime_bars[0].get("open", runtime.get("starting_price", runtime.get("current_price", 0.0)))
		))
	return IDX_PRICE_RULES.normalize_last_price(float(
		runtime.get("starting_price", runtime.get("current_price", 0.0))
	))


func _build_historical_trade_dates(end_date: Dictionary, bar_count: int) -> Array:
	var dates: Array = []
	if bar_count <= 0:
		return dates

	var cursor: Dictionary = end_date.duplicate(true)
	for bar_index in range(bar_count):
		dates.append(cursor.duplicate(true))
		if bar_index < bar_count - 1:
			cursor = trading_calendar.previous_trade_date(cursor)
	dates.reverse()
	return dates


func _build_company_profile_view(
	company_profile: Dictionary,
	include_financial_history: bool,
	include_statement_history: bool
) -> Dictionary:
	if company_profile.is_empty():
		return {}

	var profile_view: Dictionary = {}
	for profile_key_value in COMPANY_PROFILE_KEYS:
		var profile_key: String = str(profile_key_value)
		if not company_profile.has(profile_key):
			continue
		if profile_key == "financial_history":
			if include_financial_history:
				profile_view[profile_key] = company_profile.get(profile_key, []).duplicate(true)
			continue
		if profile_key == "financial_statement_snapshot":
			profile_view[profile_key] = _build_statement_snapshot_view(
				company_profile.get(profile_key, {}),
				include_statement_history
			)
			continue

		var profile_value = company_profile.get(profile_key)
		match typeof(profile_value):
			TYPE_DICTIONARY, TYPE_ARRAY:
				profile_view[profile_key] = profile_value.duplicate(true)
			_:
				profile_view[profile_key] = profile_value
	return profile_view


func _build_statement_snapshot_view(
	statement_snapshot: Dictionary,
	include_statement_history: bool
) -> Dictionary:
	if statement_snapshot.is_empty():
		return {}

	var snapshot_view: Dictionary = {}
	var passthrough_keys: Array = [
		"statement_year",
		"statement_quarter",
		"statement_period_label",
		"statement_scope",
		"quarterly_statement_count",
		"history_start_period_label",
		"history_end_period_label"
	]
	for snapshot_key_value in passthrough_keys:
		var snapshot_key: String = str(snapshot_key_value)
		if statement_snapshot.has(snapshot_key):
			snapshot_view[snapshot_key] = statement_snapshot[snapshot_key]

	snapshot_view["income_statement"] = statement_snapshot.get("income_statement", []).duplicate(true)
	snapshot_view["balance_sheet"] = statement_snapshot.get("balance_sheet", []).duplicate(true)
	snapshot_view["cash_flow"] = statement_snapshot.get("cash_flow", []).duplicate(true)
	if include_statement_history:
		snapshot_view["quarterly_statements"] = statement_snapshot.get("quarterly_statements", []).duplicate(true)
	return snapshot_view


func _reset_ytd_open_prices_for_year(year: int) -> void:
	for company_id_value in companies.keys():
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = companies[company_id].duplicate(true)
		var current_price: float = IDX_PRICE_RULES.normalize_last_price(float(runtime.get("current_price", 0.0)))
		runtime["ytd_open_price"] = current_price
		runtime["ytd_reference_year"] = year
		companies[company_id] = runtime


func _ensure_macro_state_for_year(year: int) -> void:
	var safe_year: int = max(year, 2020)
	var year_key: String = str(safe_year)
	if yearly_macro_states.has(year_key):
		return

	var previous_state: Dictionary = {}
	if safe_year > 2020:
		_ensure_macro_state_for_year(safe_year - 1)
		previous_state = yearly_macro_states.get(str(safe_year - 1), {}).duplicate(true)

	yearly_macro_states[year_key] = macro_state_system.build_year_state(
		run_seed,
		safe_year,
		DataRepository.get_sector_definitions(),
		previous_state
	)


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
			continue

		var statement_snapshot: Dictionary = company_profile.get("financial_statement_snapshot", {})
		if statement_snapshot.get("quarterly_statements", []).is_empty():
			var template: Dictionary = _get_base_company_definition(company_id)
			if template.is_empty():
				continue

			var refreshed_statement_snapshot: Dictionary = company_generator.build_financial_statement_snapshot_from_profile(
				company_profile,
				str(template.get("sector_id", "")),
				run_seed,
				company_id
			)
			if not refreshed_statement_snapshot.is_empty():
				company_profile["financial_statement_snapshot"] = refreshed_statement_snapshot
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
