extends Node

signal day_started(day_index)
signal price_formed(day_index)
signal portfolio_changed
signal watchlist_changed
signal summary_ready(summary)
signal broker_flow_generated(day_index)
signal run_started
signal run_loaded
signal run_loading_started(difficulty_id)
signal run_loading_progress(stage_id, stage_label, stage_index, stage_count, progress_ratio)
signal run_loading_finished

const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"
const GAME_SCENE := "res://scenes/game/GameRoot.tscn"
const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")
const DEFAULT_DIFFICULTY_ID := "normal"
const STARTING_CASH := 100000000.0
const DEBUG_COMPANY_ARC_EVENT_IDS := {
	"earnings_beat": true,
	"earnings_miss": true,
	"strategic_acquisition": true,
	"integration_overhang": true
}
const DIFFICULTY_ORDER := ["newbie", "normal", "hard", "hardcore"]
const NEW_RUN_LOADING_STEPS := [
	{"id": "seed", "label": "Preparing market seed"},
	{"id": "companies", "label": "Creating companies"},
	{"id": "financials", "label": "Creating financials"},
	{"id": "opening_day", "label": "Simulating opening session"},
	{"id": "save", "label": "Saving run"},
	{"id": "launch", "label": "Opening trading desk"}
]
const LOAD_RUN_LOADING_STEPS := [
	{"id": "load_save", "label": "Reading save file"},
	{"id": "restore_state", "label": "Restoring run state"},
	{"id": "load_launch", "label": "Opening trading desk"}
]
const DIFFICULTY_PRESETS := {
	"newbie": {
		"id": "newbie",
		"label": "Newbie",
		"starting_cash": 1000000000.0,
		"company_count": 25,
		"market_swing_range": 0.012,
		"volatility_multiplier": 0.55,
		"event_interval_days": 60.0,
		"broker_impact_multiplier": 0.65,
		"daily_move_cap": 0.06,
		"volatility_label": "Very Low",
		"event_label": "Very Low",
		"description": "A forgiving tape with gentle moves, rare news shocks, and plenty of cash to experiment."
	},
	"normal": {
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
		"event_label": "Low",
		"description": "A calmer starter mode where market context matters, but the tape stays readable."
	},
	"hard": {
		"id": "hard",
		"label": "Hard",
		"starting_cash": 10000000.0,
		"company_count": 75,
		"market_swing_range": 0.035,
		"volatility_multiplier": 1.0,
		"event_interval_days": 14.0,
		"broker_impact_multiplier": 1.0,
		"daily_move_cap": 0.12,
		"volatility_label": "Normal",
		"event_label": "Normal",
		"description": "The baseline prototype experience with sharper moves, tighter bankroll pressure, and regular news catalysts."
	},
	"hardcore": {
		"id": "hardcore",
		"label": "Hardcore",
		"starting_cash": 1000000.0,
		"company_count": 100,
		"market_swing_range": 0.055,
		"volatility_multiplier": 1.35,
		"event_interval_days": 7.0,
		"broker_impact_multiplier": 1.2,
		"daily_move_cap": 0.18,
		"volatility_label": "High",
		"event_label": "High",
		"description": "Fast, noisy, and hostile. Expect crypto-style swings, frequent headlines, and less room for mistakes."
	}
}

var market_simulator = preload("res://systems/MarketSimulator.gd").new()
var summary_system = preload("res://systems/SummaryInsightSystem.gd").new()
var broker_flow_system = preload("res://systems/BrokerFlowSystem.gd").new()
var trading_calendar = preload("res://systems/TradingCalendar.gd").new()
var company_roster_generator = preload("res://systems/CompanyRosterGenerator.gd").new()
var chart_system = preload("res://systems/ChartSystem.gd").new()
var news_feed_system = preload("res://systems/NewsFeedSystem.gd").new()
var twooter_feed_system = preload("res://systems/TwooterFeedSystem.gd").new()
var company_event_system = preload("res://systems/CompanyEventSystem.gd").new()
var person_event_system = preload("res://systems/PersonEventSystem.gd").new()
var special_event_system = preload("res://systems/SpecialEventSystem.gd").new()


func _ready() -> void:
	DataRepository.reload_all()


func start_new_run(run_seed: int = 0, difficulty_id: String = DEFAULT_DIFFICULTY_ID, tutorial_enabled: bool = false) -> void:
	if run_seed == 0:
		run_seed = int(Time.get_unix_time_from_system())

	var difficulty_config: Dictionary = get_difficulty_config(difficulty_id)
	var company_definitions: Array = build_company_roster(run_seed, difficulty_config)
	RunState.setup_new_run(run_seed, company_definitions, difficulty_config, tutorial_enabled)
	simulate_opening_session(false)
	SaveManager.save_run(RunState.to_save_dict())
	run_started.emit()
	_enter_game_scene()


func start_new_run_with_loading(
	run_seed: int = 0,
	difficulty_id: String = DEFAULT_DIFFICULTY_ID,
	tutorial_enabled: bool = false
) -> void:
	if run_seed == 0:
		run_seed = int(Time.get_unix_time_from_system())

	var difficulty_config: Dictionary = get_difficulty_config(difficulty_id)
	run_loading_started.emit(str(difficulty_config.get("id", difficulty_id)))
	_emit_run_loading_step(0)
	await get_tree().process_frame

	_emit_run_loading_step(1)
	var company_definitions: Array = build_company_roster(run_seed, difficulty_config)
	await get_tree().process_frame

	_emit_run_loading_step(2)
	RunState.setup_new_run(run_seed, company_definitions, difficulty_config, tutorial_enabled)
	await get_tree().process_frame

	_emit_run_loading_step(3)
	simulate_opening_session(false)
	await get_tree().process_frame

	_emit_run_loading_step(4)
	SaveManager.save_run(RunState.to_save_dict())
	run_started.emit()
	await get_tree().process_frame

	_emit_run_loading_step(5)
	await get_tree().process_frame
	run_loading_finished.emit()
	_enter_game_scene()


func load_run_from_save() -> bool:
	var saved_run: Dictionary = SaveManager.load_run()
	if saved_run.is_empty():
		return false

	RunState.load_from_dict(saved_run)
	run_loaded.emit()
	_enter_game_scene()
	return true


func load_run_from_save_with_loading() -> bool:
	_emit_load_run_loading_step(0)
	await get_tree().process_frame

	var saved_run: Dictionary = SaveManager.load_run()
	if saved_run.is_empty():
		run_loading_finished.emit()
		return false

	_emit_load_run_loading_step(1)
	RunState.load_from_dict(saved_run)
	run_loaded.emit()
	await get_tree().process_frame

	_emit_load_run_loading_step(2)
	await get_tree().process_frame
	run_loading_finished.emit()
	_enter_game_scene()
	return true


func return_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func quit_game() -> void:
	get_tree().quit()


func advance_day() -> void:
	_advance_day_internal(true, true)


func simulate_opening_session(save_after: bool = false) -> Dictionary:
	return _advance_day_internal(save_after, false)


func _advance_day_internal(save_after: bool = true, emit_runtime_signals: bool = true) -> Dictionary:
	if not RunState.has_active_run():
		return {}

	if emit_runtime_signals:
		day_started.emit(RunState.day_index + 1)
	var day_result: Dictionary = market_simulator.simulate_day(RunState, DataRepository, broker_flow_system)
	RunState.apply_day_result(day_result)
	if emit_runtime_signals:
		broker_flow_generated.emit(RunState.day_index)
		price_formed.emit(RunState.day_index)

	var summary: Dictionary = summary_system.build_daily_summary(RunState, DataRepository)
	RunState.set_daily_summary(summary)
	if save_after:
		SaveManager.save_run(RunState.to_save_dict())
	if emit_runtime_signals:
		summary_ready.emit(summary)
		portfolio_changed.emit()
	return {
		"day_result": day_result,
		"summary": summary
	}


func buy_company(company_id: String, shares: int = 1) -> Dictionary:
	var result: Dictionary = RunState.buy_company(company_id, shares)
	if result.get("success", false):
		SaveManager.save_run(RunState.to_save_dict())
		portfolio_changed.emit()
	return result


func sell_company(company_id: String, shares: int = 1) -> Dictionary:
	var result: Dictionary = RunState.sell_company(company_id, shares)
	if result.get("success", false):
		SaveManager.save_run(RunState.to_save_dict())
		portfolio_changed.emit()
	return result


func buy_lots(company_id: String, lots: int = 1) -> Dictionary:
	return buy_company(company_id, lots_to_shares(lots))


func sell_lots(company_id: String, lots: int = 1) -> Dictionary:
	return sell_company(company_id, lots_to_shares(lots))


func estimate_buy_lots(company_id: String, lots: int = 1) -> Dictionary:
	return RunState.estimate_buy_order(company_id, lots_to_shares(lots))


func estimate_sell_lots(company_id: String, lots: int = 1) -> Dictionary:
	return RunState.estimate_sell_order(company_id, lots_to_shares(lots))


func add_company_to_watchlist(company_id: String) -> Dictionary:
	var result: Dictionary = RunState.add_to_watchlist(company_id)
	if result.get("success", false):
		SaveManager.save_run(RunState.to_save_dict())
		watchlist_changed.emit()
	return result


func get_watchlist_company_ids() -> Array:
	return RunState.get_watchlist_company_ids()


func get_company_rows() -> Array:
	var rows: Array = []
	for company_id in RunState.company_order:
		rows.append(get_company_snapshot(str(company_id), false, false, false))
	return rows


func get_company_snapshot(
	company_id: String,
	include_price_history: bool = false,
	include_financial_history: bool = false,
	include_statement_history: bool = false
) -> Dictionary:
	var definition: Dictionary = RunState.get_effective_company_definition(
		company_id,
		include_financial_history,
		include_statement_history
	)
	var runtime: Dictionary = RunState.get_company(company_id)
	if definition.is_empty() or runtime.is_empty():
		return {}

	var sector_definition: Dictionary = DataRepository.get_sector_definition(str(definition.get("sector_id", "")))
	var holding: Dictionary = RunState.get_holding(company_id)
	var previous_close: float = RunState.get_previous_close(company_id)
	var current_price: float = float(runtime.get("current_price", 0.0))
	var listing_board: String = str(definition.get("listing_board", "main"))
	var ar_limits: Dictionary = runtime.get("ar_limits", IDX_PRICE_RULES.auto_rejection_limits(previous_close, listing_board))
	var daily_change_pct: float = 0.0
	if not is_zero_approx(previous_close):
		daily_change_pct = (current_price - previous_close) / previous_close

	var shares_owned: int = int(holding.get("shares", 0))
	var lot_size: int = get_lot_size()
	var average_price: float = float(holding.get("average_price", 0.0))
	var financials: Dictionary = definition.get("financials", {}).duplicate(true)
	var financial_history: Array = []
	if include_financial_history:
		financial_history = definition.get("financial_history", []).duplicate(true)
	var starting_price: float = float(runtime.get("starting_price", current_price))
	var ytd_open_price: float = float(runtime.get("ytd_open_price", starting_price))
	var since_start_pct: float = 0.0
	var ytd_change_pct: float = 0.0
	if not is_zero_approx(starting_price):
		since_start_pct = (current_price - starting_price) / starting_price
	if not is_zero_approx(ytd_open_price):
		ytd_change_pct = (current_price - ytd_open_price) / ytd_open_price
	var snapshot: Dictionary = {
		"id": company_id,
		"ticker": definition.get("ticker", company_id.to_upper()),
		"name": definition.get("name", ""),
		"sector_id": str(definition.get("sector_id", "")),
		"sector_name": sector_definition.get("name", "Unknown"),
		"archetype_id": str(definition.get("archetype_id", "")),
		"archetype_label": str(definition.get("archetype_label", "")),
		"company_size_id": int(definition.get("company_size_id", 0)),
		"company_size_label": str(definition.get("company_size_label", "")),
		"company_age": int(definition.get("company_age", 0)),
		"founded_year": int(definition.get("founded_year", 0)),
		"employee_count": int(definition.get("employee_count", 0)),
		"profile_revenue": float(definition.get("profile_revenue", 0.0)),
		"profile_revenue_value": float(definition.get("profile_revenue_value", 0.0)),
		"profile_revenue_unit": str(definition.get("profile_revenue_unit", "")),
		"profile_description": str(definition.get("profile_description", "")),
		"profile_tags": definition.get("profile_tags", []).duplicate(),
		"current_price": current_price,
		"previous_close": previous_close,
		"daily_change_pct": daily_change_pct,
		"quality_score": int(definition.get("quality_score", 0)),
		"growth_score": int(definition.get("growth_score", 0)),
		"risk_score": int(definition.get("risk_score", 0)),
		"financials": financials,
		"financial_history": financial_history,
		"financial_statement_snapshot": definition.get("financial_statement_snapshot", {}).duplicate(true),
		"narrative_tags": definition.get("narrative_tags", []).duplicate(),
		"sentiment": float(runtime.get("sentiment", 0.0)),
		"event_tags": runtime.get("active_event_tags", []).duplicate(),
		"active_events": runtime.get("active_events", []).duplicate(true),
		"starting_price": starting_price,
		"ytd_open_price": ytd_open_price,
		"ytd_reference_year": int(runtime.get("ytd_reference_year", int(RunState.get_current_trade_date().get("year", 2020)))),
		"since_start_pct": since_start_pct,
		"ytd_change_pct": ytd_change_pct,
		"broker_flow": runtime.get("broker_flow", {}).duplicate(true),
		"hidden_story_flags": runtime.get("hidden_story_flags", []).duplicate(),
		"listing_board": listing_board,
		"shares_owned": shares_owned,
		"lots_owned": int(floor(float(shares_owned) / float(lot_size))),
		"odd_lot_remainder": int(posmod(shares_owned, lot_size)),
		"tick_size": get_tick_size_for_price(current_price),
		"ara_price": float(ar_limits.get("upper_price", current_price)),
		"arb_price": float(ar_limits.get("lower_price", current_price)),
		"ara_label": str(ar_limits.get("upper_label", "")),
		"arb_label": str(ar_limits.get("lower_label", "")),
		"average_price": average_price,
		"market_value": shares_owned * current_price,
		"unrealized_pnl": (current_price - average_price) * shares_owned
	}

	if include_price_history:
		snapshot["price_history"] = runtime.get("price_history", []).duplicate()
		snapshot["price_bars"] = runtime.get("price_bars", []).duplicate(true)

	return snapshot


func get_company_chart_snapshot(company_id: String, range_id: String = "1m", enabled_indicator_ids: Array = []) -> Dictionary:
	var chart_bars: Array = RunState.get_company_chart_bars(company_id)
	if chart_bars.is_empty():
		return {}
	return chart_system.build_chart_snapshot_from_bars(chart_bars, range_id, enabled_indicator_ids)


func get_portfolio_snapshot() -> Dictionary:
	var holdings_rows: Array = []
	var invested_cost_total: float = 0.0
	var unrealized_pnl_total: float = 0.0
	for company_id in RunState.player_portfolio.get("holdings", {}).keys():
		var snapshot: Dictionary = get_company_snapshot(str(company_id), false)
		var holding: Dictionary = RunState.get_holding(str(company_id))
		var shares: int = int(holding.get("shares", 0))
		var invested_cost: float = float(holding.get("average_price", 0.0)) * float(shares)
		var unrealized_pnl: float = float(snapshot.get("unrealized_pnl", 0.0))
		var pnl_pct: float = 0.0
		if invested_cost > 0.0:
			pnl_pct = unrealized_pnl / invested_cost

		invested_cost_total += invested_cost
		unrealized_pnl_total += unrealized_pnl
		holdings_rows.append({
			"company_id": company_id,
			"ticker": snapshot.get("ticker", str(company_id).to_upper()),
			"shares": shares,
			"lots": int(floor(float(shares) / float(get_lot_size()))),
			"average_price": float(holding.get("average_price", 0.0)),
			"current_price": float(snapshot.get("current_price", 0.0)),
			"invested_cost": invested_cost,
			"market_value": float(snapshot.get("market_value", 0.0)),
			"unrealized_pnl": unrealized_pnl,
			"unrealized_pnl_pct": pnl_pct
		})

	holdings_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("ticker", "")) < str(b.get("ticker", ""))
	)

	var unrealized_pnl_pct_total: float = 0.0
	if invested_cost_total > 0.0:
		unrealized_pnl_pct_total = unrealized_pnl_total / invested_cost_total

	return {
		"cash": float(RunState.player_portfolio.get("cash", 0.0)),
		"realized_pnl": float(RunState.player_portfolio.get("realized_pnl", 0.0)),
		"invested_cost": invested_cost_total,
		"market_value": RunState.get_portfolio_market_value(),
		"unrealized_pnl": unrealized_pnl_total,
		"unrealized_pnl_pct": unrealized_pnl_pct_total,
		"equity": RunState.get_total_equity(),
		"holdings": holdings_rows
	}


func get_sector_rows() -> Array:
	var grouped_rows: Dictionary = {}
	var ordered_rows: Array = []

	for company_id in RunState.company_order:
		var snapshot: Dictionary = get_company_snapshot(str(company_id), false)
		var sector_id: String = str(snapshot.get("sector_id", ""))
		if sector_id.is_empty():
			continue

		var sector_definition: Dictionary = DataRepository.get_sector_definition(sector_id)
		if not grouped_rows.has(sector_id):
			grouped_rows[sector_id] = {
				"id": sector_id,
				"name": str(sector_definition.get("name", sector_id.capitalize())),
				"trend_bias": float(sector_definition.get("trend_bias", 0.0)),
				"volatility_bias": float(sector_definition.get("volatility_bias", 0.0)),
				"company_count": 0,
				"advancers": 0,
				"decliners": 0,
				"change_sum": 0.0,
				"strongest_ticker": "",
				"strongest_change_pct": 0.0,
				"strongest_flow_tag": "neutral",
				"strongest_flow_pressure": -1.0
			}

		var sector_row: Dictionary = grouped_rows[sector_id]
		var daily_change_pct: float = float(snapshot.get("daily_change_pct", 0.0))
		var broker_flow: Dictionary = snapshot.get("broker_flow", {})
		var pressure_value: float = abs(float(broker_flow.get("net_pressure", 0.0)))

		sector_row["company_count"] = int(sector_row.get("company_count", 0)) + 1
		sector_row["change_sum"] = float(sector_row.get("change_sum", 0.0)) + daily_change_pct
		if daily_change_pct > 0.0:
			sector_row["advancers"] = int(sector_row.get("advancers", 0)) + 1
		elif daily_change_pct < 0.0:
			sector_row["decliners"] = int(sector_row.get("decliners", 0)) + 1

		if pressure_value > float(sector_row.get("strongest_flow_pressure", -1.0)):
			sector_row["strongest_ticker"] = str(snapshot.get("ticker", ""))
			sector_row["strongest_change_pct"] = daily_change_pct
			sector_row["strongest_flow_tag"] = str(broker_flow.get("flow_tag", "neutral"))
			sector_row["strongest_flow_pressure"] = pressure_value

		grouped_rows[sector_id] = sector_row

	for sector_definition_value in DataRepository.get_sector_definitions():
		var sector_definition: Dictionary = sector_definition_value
		var sector_id: String = str(sector_definition.get("id", ""))
		if not grouped_rows.has(sector_id):
			continue

		var grouped_row: Dictionary = grouped_rows[sector_id].duplicate(true)
		var company_count: int = int(grouped_row.get("company_count", 0))
		var average_change_pct: float = 0.0
		if company_count > 0:
			average_change_pct = float(grouped_row.get("change_sum", 0.0)) / float(company_count)

		grouped_row["average_change_pct"] = average_change_pct
		ordered_rows.append(grouped_row)

	return ordered_rows


func get_latest_summary() -> Dictionary:
	return RunState.daily_summary.duplicate(true)


func get_trade_history() -> Array:
	var rows: Array = []
	var raw_history: Array = RunState.get_trade_history()

	for index in range(raw_history.size() - 1, -1, -1):
		var entry: Dictionary = raw_history[index]
		var company_id: String = str(entry.get("company_id", ""))
		var definition: Dictionary = RunState.get_effective_company_definition(company_id)
		rows.append({
			"day_index": int(entry.get("day_index", 0)),
			"company_id": company_id,
			"ticker": str(definition.get("ticker", company_id.to_upper())),
			"side": str(entry.get("side", "")),
			"lots": int(entry.get("lots", 0)),
			"shares": int(entry.get("shares", 0)),
			"price_per_share": float(entry.get("price_per_share", 0.0)),
			"gross_value": float(entry.get("gross_value", 0.0)),
			"fee_rate": float(entry.get("fee_rate", 0.0)),
			"fee": float(entry.get("fee", 0.0)),
			"net_cash_impact": float(entry.get("net_cash_impact", 0.0)),
			"cash_after": float(entry.get("cash_after", 0.0)),
			"realized_pnl": float(entry.get("realized_pnl", 0.0))
		})

	return rows


func get_event_history() -> Array:
	return RunState.get_event_history()


func get_market_history() -> Array:
	return RunState.get_market_history()


func get_active_company_arcs() -> Array:
	return RunState.get_active_company_arcs()


func get_active_special_events() -> Array:
	return RunState.get_active_special_events()


func get_debug_event_generator_catalog() -> Array:
	var group_labels: Dictionary = {
		"market": "Market Events",
		"company": "Company Events",
		"company_arc": "Company Arcs",
		"person": "Person Events",
		"special": "Special Events"
	}
	var group_order: Array = ["market", "company", "company_arc", "person", "special"]
	var grouped_events: Dictionary = {}
	for group_id_value in group_order:
		grouped_events[str(group_id_value)] = []

	for event_definition_value in DataRepository.get_event_definitions():
		var event_definition: Dictionary = event_definition_value
		var event_id: String = str(event_definition.get("id", ""))
		if event_id.is_empty():
			continue

		var group_id: String = "company_arc" if DEBUG_COMPANY_ARC_EVENT_IDS.has(event_id) else str(event_definition.get("event_family", ""))
		if not grouped_events.has(group_id):
			continue

		grouped_events[group_id].append({
			"event_id": event_id,
			"description": str(event_definition.get("description", ""))
		})

	var catalog: Array = []
	for group_id_value in group_order:
		var group_id: String = str(group_id_value)
		var events: Array = grouped_events.get(group_id, [])
		events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return str(a.get("event_id", "")) < str(b.get("event_id", ""))
		)
		catalog.append({
			"id": group_id,
			"label": str(group_labels.get(group_id, group_id.capitalize())),
			"events": events
		})

	return catalog


func debug_generate_event(event_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run to modify."}

	var event_definition: Dictionary = DataRepository.get_event_definition(event_id)
	if event_definition.is_empty():
		return {"success": false, "message": "Unknown debug event id."}

	var trade_date: Dictionary = get_current_trade_date()
	var day_number: int = max(int(RunState.day_index), 1)
	var macro_state: Dictionary = get_current_macro_state()
	var generated_event: Dictionary = {}
	var event_family: String = str(event_definition.get("event_family", ""))

	if DEBUG_COMPANY_ARC_EVENT_IDS.has(event_id):
		var generated_arc: Dictionary = company_event_system.build_debug_company_arc(
			RunState,
			trade_date,
			day_number,
			macro_state,
			event_id
		)
		if generated_arc.is_empty():
			return {"success": false, "message": "Could not build that company arc right now."}

		var arc_start_event: Dictionary = company_event_system.build_arc_start_event(
			generated_arc,
			trade_date,
			day_number
		)
		RunState.debug_add_company_arc(generated_arc, arc_start_event)
		generated_event = arc_start_event
	elif event_family == "company":
		generated_event = company_event_system.build_debug_company_event(
			RunState,
			trade_date,
			day_number,
			macro_state,
			event_id
		)
		if generated_event.is_empty():
			return {"success": false, "message": "Could not find a company match for that event."}
		RunState.debug_add_recorded_event(generated_event)
	elif event_family == "person":
		generated_event = person_event_system.build_debug_person_event(
			RunState,
			trade_date,
			day_number,
			macro_state,
			_build_debug_sector_sentiments(),
			float(RunState.market_sentiment),
			event_id
		)
		if generated_event.is_empty():
			return {"success": false, "message": "Could not find a person-event target right now."}
		RunState.debug_add_recorded_event(generated_event)
	elif event_family == "special":
		generated_event = special_event_system.build_debug_special_event(
			RunState,
			trade_date,
			day_number,
			macro_state,
			event_id
		)
		if generated_event.is_empty():
			return {"success": false, "message": "Could not build that special event right now."}
		RunState.debug_add_special_event(generated_event)
	elif event_family == "market":
		generated_event = _build_debug_market_event(event_definition, trade_date)
		if generated_event.is_empty():
			return {"success": false, "message": "Could not build that market event right now."}
		RunState.debug_add_recorded_event(generated_event)
	else:
		return {"success": false, "message": "No debug generator is defined for that event family."}

	SaveManager.save_run(RunState.to_save_dict())
	return {
		"success": true,
		"message": _build_debug_generated_message(generated_event, event_definition),
		"event": generated_event
	}


func get_news_snapshot(unlocked_intel_level: int = -1) -> Dictionary:
	if not RunState.has_active_run():
		return {
			"intel_level": max(unlocked_intel_level, 1),
			"outlets": [],
			"feeds": {}
		}

	var news_trade_date: Dictionary = get_current_trade_date()
	news_trade_date["day_index"] = RunState.day_index

	return news_feed_system.build_news_snapshot(
		RunState,
		DataRepository.get_news_feed_data(),
		get_company_rows(),
		get_market_history(),
		get_event_history(),
		get_active_special_events(),
		get_active_company_arcs(),
		news_trade_date,
		unlocked_intel_level
	)


func get_twooter_snapshot(unlocked_access_tier: int = -1) -> Dictionary:
	if not RunState.has_active_run():
		return {
			"access_tier": max(unlocked_access_tier, 1),
			"tier_label": "Tier 1",
			"accounts": [],
			"posts": []
		}

	var social_trade_date: Dictionary = get_current_trade_date()
	social_trade_date["day_index"] = RunState.day_index

	return twooter_feed_system.build_social_snapshot(
		RunState,
		DataRepository.get_twooter_feed_data(),
		get_company_rows(),
		get_market_history(),
		get_event_history(),
		get_active_special_events(),
		get_active_company_arcs(),
		social_trade_date,
		unlocked_access_tier
	)


func get_difficulty_options() -> Array:
	var options: Array = []

	for difficulty_id in DIFFICULTY_ORDER:
		options.append(get_difficulty_config(str(difficulty_id)))

	return options


func build_company_roster(run_seed: int, selected_difficulty_config: Dictionary) -> Array:
	var difficulty_config: Dictionary = selected_difficulty_config.duplicate(true)
	if difficulty_config.is_empty():
		difficulty_config = get_difficulty_config(DEFAULT_DIFFICULTY_ID)

	var company_count: int = int(difficulty_config.get("company_count", DataRepository.get_company_archetypes().size()))
	return company_roster_generator.generate_roster(
		DataRepository.get_company_archetypes(),
		DataRepository.get_sector_definitions(),
		DataRepository.get_company_word_data(),
		run_seed,
		company_count
	)


func get_difficulty_config(difficulty_id: String) -> Dictionary:
	var normalized_id: String = difficulty_id.to_lower()
	if not DIFFICULTY_PRESETS.has(normalized_id):
		normalized_id = DEFAULT_DIFFICULTY_ID

	return DIFFICULTY_PRESETS[normalized_id].duplicate(true)


func get_current_difficulty_config() -> Dictionary:
	return RunState.get_difficulty_config()


func get_current_difficulty_label() -> String:
	var current_config: Dictionary = get_current_difficulty_config()
	if current_config.is_empty():
		current_config = get_difficulty_config(DEFAULT_DIFFICULTY_ID)

	return str(current_config.get("label", "Normal"))


func get_current_trade_date() -> Dictionary:
	return RunState.get_current_trade_date()


func get_current_macro_state() -> Dictionary:
	return RunState.get_current_macro_state()


func get_macro_state_history() -> Array:
	return RunState.get_macro_state_history()


func get_next_trade_date() -> Dictionary:
	return RunState.get_next_trade_date()


func format_trade_date(date_info: Dictionary) -> String:
	return trading_calendar.format_date(date_info)


func should_show_tutorial() -> bool:
	return RunState.should_show_tutorial()


func mark_tutorial_shown() -> void:
	RunState.mark_tutorial_shown()
	SaveManager.save_run(RunState.to_save_dict())


func get_lot_size() -> int:
	return int(RunState.LOT_SIZE)


func get_buy_fee_rate() -> float:
	return float(RunState.BUY_FEE_RATE)


func get_sell_fee_rate() -> float:
	return float(RunState.SELL_FEE_RATE)


func lots_to_shares(lots: int) -> int:
	return max(lots, 0) * get_lot_size()


func get_tick_size_for_price(price: float) -> float:
	return IDX_PRICE_RULES.tick_size_for_reference_price(price)


func get_chart_range_label(range_id: String) -> String:
	return chart_system.get_range_label(range_id)


func get_chart_indicator_catalog() -> Array:
	return chart_system.get_indicator_catalog()


func _build_debug_sector_sentiments() -> Dictionary:
	var sector_sentiments: Dictionary = {}
	for sector_row_value in get_sector_rows():
		var sector_row: Dictionary = sector_row_value
		sector_sentiments[str(sector_row.get("id", ""))] = float(sector_row.get("average_change_pct", 0.0))

	if sector_sentiments.is_empty():
		for sector_definition_value in DataRepository.get_sector_definitions():
			var sector_definition: Dictionary = sector_definition_value
			sector_sentiments[str(sector_definition.get("id", ""))] = float(sector_definition.get("trend_bias", 0.0))

	return sector_sentiments


func _build_debug_market_event(event_definition: Dictionary, trade_date: Dictionary) -> Dictionary:
	var event_id: String = str(event_definition.get("id", ""))
	if event_id.is_empty():
		return {}

	var event_data: Dictionary = {
		"event_id": event_id,
		"scope": str(event_definition.get("scope", "market")),
		"event_family": str(event_definition.get("event_family", "market")),
		"category": str(event_definition.get("category", "market")),
		"tone": str(event_definition.get("tone", "mixed")),
		"duration_days": int(event_definition.get("duration_days", 1)),
		"trade_date": trade_date.duplicate(true),
		"sentiment_shift": float(event_definition.get("sentiment_shift", 0.0)),
		"description": str(event_definition.get("description", "")),
		"broker_bias": str(event_definition.get("broker_bias", "balanced"))
	}

	if str(event_definition.get("scope", "market")) == "market":
		event_data["headline"] = "Risk-off pressure hits the tape"
		event_data["headline_detail"] = "A manually injected market headline pushes traders into defense mode."
		return event_data

	var sector_sentiments: Dictionary = _build_debug_sector_sentiments()
	var target_sector_id: String = _pick_debug_market_sector(event_id, sector_sentiments)
	if target_sector_id.is_empty():
		return {}

	var sector_definition: Dictionary = DataRepository.get_sector_definition(target_sector_id)
	var sector_name: String = str(sector_definition.get("name", target_sector_id.capitalize()))
	event_data["target_sector_id"] = target_sector_id
	if event_id == "sector_tailwind":
		event_data["headline"] = "%s catches a sector tailwind" % sector_name
		event_data["headline_detail"] = "A fresh wave of buyers rotates into %s and keeps the tape constructive." % sector_name
	else:
		event_data["headline"] = "%s runs into a sector headwind" % sector_name
		event_data["headline_detail"] = "Sellers lean on %s as the sector tone rolls over." % sector_name

	return event_data


func _pick_debug_market_sector(event_id: String, sector_sentiments: Dictionary) -> String:
	var selected_sector_id: String = ""
	var selected_value: float = -INF if event_id == "sector_tailwind" else INF

	for sector_id_value in sector_sentiments.keys():
		var sector_id: String = str(sector_id_value)
		var sentiment_value: float = float(sector_sentiments.get(sector_id, 0.0))
		if event_id == "sector_tailwind":
			if sentiment_value > selected_value:
				selected_value = sentiment_value
				selected_sector_id = sector_id
		elif sentiment_value < selected_value:
			selected_value = sentiment_value
			selected_sector_id = sector_id

	if not selected_sector_id.is_empty():
		return selected_sector_id

	for sector_definition_value in DataRepository.get_sector_definitions():
		return str(sector_definition_value.get("id", ""))
	return ""


func _build_debug_generated_message(event_data: Dictionary, event_definition: Dictionary) -> String:
	var event_label: String = _format_debug_event_label(str(event_definition.get("id", "")))
	var target_ticker: String = str(event_data.get("target_ticker", ""))
	if not target_ticker.is_empty():
		return "%s generated for %s." % [event_label, target_ticker]

	var person_name: String = str(event_data.get("person_name", ""))
	if not person_name.is_empty():
		return "%s generated from %s." % [event_label, person_name]

	var target_sector_id: String = str(event_data.get("target_sector_id", ""))
	if not target_sector_id.is_empty():
		var sector_definition: Dictionary = DataRepository.get_sector_definition(target_sector_id)
		return "%s generated for %s." % [event_label, str(sector_definition.get("name", target_sector_id.capitalize()))]

	return "%s generated." % event_label


func _format_debug_event_label(event_id: String) -> String:
	var words: Array = event_id.split("_", false)
	for index in range(words.size()):
		words[index] = str(words[index]).capitalize()
	return " ".join(words)


func _emit_run_loading_step(step_index: int) -> void:
	_emit_loading_step_from_list(NEW_RUN_LOADING_STEPS, step_index)


func _emit_load_run_loading_step(step_index: int) -> void:
	_emit_loading_step_from_list(LOAD_RUN_LOADING_STEPS, step_index)


func _emit_loading_step_from_list(steps: Array, step_index: int) -> void:
	if steps.is_empty():
		run_loading_progress.emit("", "", 0, 0, 1.0)
		return

	var clamped_index: int = clamp(step_index, 0, steps.size() - 1)
	var step: Dictionary = steps[clamped_index]
	var denominator: float = max(float(steps.size() - 1), 1.0)
	var progress_ratio: float = float(clamped_index) / denominator
	run_loading_progress.emit(
		str(step.get("id", "")),
		str(step.get("label", "")),
		clamped_index + 1,
		steps.size(),
		progress_ratio
	)


func _enter_game_scene() -> void:
	var current_scene = get_tree().current_scene
	if current_scene != null and current_scene.scene_file_path == GAME_SCENE:
		return

	get_tree().change_scene_to_file(GAME_SCENE)
