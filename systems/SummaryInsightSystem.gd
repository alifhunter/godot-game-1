extends RefCounted


func build_daily_summary(run_state, _data_repository, log_phase_details: bool = false) -> Dictionary:
	var phase_started_at_usec: int = Time.get_ticks_usec()
	var rows: Array = []

	for company_id in run_state.company_order:
		var definition: Dictionary = run_state.get_effective_company_definition(str(company_id))
		var runtime: Dictionary = run_state.get_company(str(company_id))
		if definition.is_empty() or runtime.is_empty():
			continue

		rows.append({
			"company_id": company_id,
			"ticker": definition.get("ticker", str(company_id).to_upper()),
			"name": definition.get("name", ""),
			"change_pct": float(runtime.get("daily_change_pct", 0.0)),
			"current_price": float(runtime.get("current_price", 0.0)),
			"event_tags": runtime.get("active_event_tags", []).duplicate(),
			"broker_flow": runtime.get("broker_flow", {}).duplicate(true)
		})

	_log_perf_elapsed(log_phase_details, "build_daily_summary:rows", phase_started_at_usec, " count=%d" % rows.size())
	phase_started_at_usec = Time.get_ticks_usec()
	rows.sort_custom(_sort_by_change_descending)
	_log_perf_elapsed(log_phase_details, "build_daily_summary:sort_rows", phase_started_at_usec)

	phase_started_at_usec = Time.get_ticks_usec()
	var biggest_winner: Dictionary = {}
	for row in rows:
		if float(row.get("change_pct", 0.0)) >= 0.0:
			biggest_winner = row
			break

	var biggest_loser: Dictionary = {}
	for index in range(rows.size() - 1, -1, -1):
		var row = rows[index]
		if float(row.get("change_pct", 0.0)) <= 0.0:
			biggest_loser = row
			break
	_log_perf_elapsed(log_phase_details, "build_daily_summary:extreme_movers", phase_started_at_usec)

	phase_started_at_usec = Time.get_ticks_usec()
	var movers: Array = rows.slice(0, min(rows.size(), 3))
	var most_accumulated: Dictionary = _find_extreme_by_pressure(rows, true)
	var most_distributed: Dictionary = _find_extreme_by_pressure(rows, false)
	_log_perf_elapsed(log_phase_details, "build_daily_summary:pressure_rows", phase_started_at_usec)

	phase_started_at_usec = Time.get_ticks_usec()
	var current_equity: float = run_state.get_total_equity()
	var starting_equity: float = float(run_state.last_day_results.get("starting_equity", run_state.last_equity_value))
	var portfolio_delta: float = current_equity - starting_equity
	_log_perf_elapsed(log_phase_details, "build_daily_summary:portfolio", phase_started_at_usec)

	phase_started_at_usec = Time.get_ticks_usec()
	var macro_state: Dictionary = run_state.get_current_macro_state()
	var active_company_arcs: Array = run_state.get_active_company_arcs()
	var active_special_events: Array = run_state.get_active_special_events()
	_log_perf_elapsed(log_phase_details, "build_daily_summary:context", phase_started_at_usec)

	phase_started_at_usec = Time.get_ticks_usec()
	var explanation: String = _build_explanation(biggest_winner, biggest_loser, most_accumulated, most_distributed, portfolio_delta)
	_log_perf_elapsed(log_phase_details, "build_daily_summary:explanation", phase_started_at_usec)

	return {
		"day_index": run_state.day_index,
		"portfolio_value": current_equity,
		"portfolio_delta": portfolio_delta,
		"cash": float(run_state.player_portfolio.get("cash", 0.0)),
		"biggest_winner": biggest_winner,
		"biggest_loser": biggest_loser,
		"top_movers": movers,
		"best_accumulation": most_accumulated,
		"heaviest_distribution": most_distributed,
		"macro_state": macro_state,
		"active_company_arcs": active_company_arcs,
		"active_special_events": active_special_events,
		"explanation": explanation
	}


func _sort_by_change_descending(left: Dictionary, right: Dictionary) -> bool:
	return float(left.get("change_pct", 0.0)) > float(right.get("change_pct", 0.0))


func _find_extreme_by_pressure(rows: Array, highest: bool) -> Dictionary:
	var selected: Dictionary = {}
	var selected_value: float = -INF if highest else INF

	for row in rows:
		var flow: Dictionary = row.get("broker_flow", {})
		var pressure = float(flow.get("net_pressure", 0.0))
		if highest and pressure > selected_value:
			selected_value = pressure
			selected = row
		elif not highest and pressure < selected_value:
			selected_value = pressure
			selected = row

	return selected


func _build_explanation(
	biggest_winner: Dictionary,
	biggest_loser: Dictionary,
	most_accumulated: Dictionary,
	most_distributed: Dictionary,
	portfolio_delta: float
) -> String:
	if not most_accumulated.is_empty():
		var buyer: String = str(most_accumulated.get("broker_flow", {}).get("dominant_buyer", "balanced")).capitalize()
		var ticker: String = str(most_accumulated.get("ticker", ""))
		if float(most_accumulated.get("change_pct", 0.0)) > 0.0:
			return "%s-led accumulation gave %s the cleanest tape today." % [buyer, ticker]

	if not most_distributed.is_empty():
		var seller: String = str(most_distributed.get("broker_flow", {}).get("dominant_seller", "balanced")).capitalize()
		var ticker: String = str(most_distributed.get("ticker", ""))
		if float(most_distributed.get("change_pct", 0.0)) < 0.0:
			return "%s distribution hit %s hardest and kept the day defensive." % [seller, ticker]

	if portfolio_delta >= 0.0 and not biggest_winner.is_empty():
		return "%s carried the tape enough to keep your book green." % str(biggest_winner.get("ticker", "The watchlist"))

	if not biggest_loser.is_empty():
		return "%s set the weaker tone, so capital preservation mattered today." % str(biggest_loser.get("ticker", "The watchlist"))

	return "A mixed session printed without a dominant signal."


func _log_perf_elapsed(enabled: bool, label: String, started_at_usec: int, extra: String = "") -> void:
	if not enabled:
		return
	var elapsed_ms: float = float(Time.get_ticks_usec() - started_at_usec) / 1000.0
	print("[perf][advance] %s %.2fms%s" % [label, elapsed_ms, extra])
