extends Node

const SMOKE_LOCAL_IO_ARG := "--smoke-local-io"
const RESULT_PATH := "res://logs/long_run_stability_result.txt"
const DEFAULT_DAYS_PER_SCENARIO := 90
const CHECKPOINT_INTERVAL := 30
const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")

var total_days_checked: int = 0
var max_gain_pct: float = -999.0
var max_drop_pct: float = 999.0
var max_gain_label: String = ""
var max_drop_label: String = ""
var corporate_applications_seen: int = 0
var split_rebases_seen: int = 0


func _ready() -> void:
	call_deferred("_run_long_stability_pass")


func _run_long_stability_pass() -> void:
	DataRepository.reload_all()
	if OS.get_cmdline_user_args().has(SMOKE_LOCAL_IO_ARG):
		for slot_index in range(1, SaveManager.SAVE_SLOT_COUNT + 1):
			SaveManager.delete_save("slot_%d" % slot_index)

	var days_per_scenario: int = _days_per_scenario()
	var scenarios: Array = [
		{"seed": 902101, "difficulty": "normal"},
		{"seed": 902202, "difficulty": "normal"},
		{"seed": 902303, "difficulty": "chill"},
		{"seed": 902404, "difficulty": "chill"},
		{"seed": 902505, "difficulty": "grind"},
		{"seed": 902606, "difficulty": "grind"}
	]

	var started_at_usec: int = Time.get_ticks_usec()
	for scenario_value in scenarios:
		var scenario: Dictionary = scenario_value
		var scenario_result: Dictionary = _run_scenario(
			int(scenario.get("seed", 0)),
			str(scenario.get("difficulty", "normal")),
			days_per_scenario
		)
		if not bool(scenario_result.get("success", false)):
			_finish(false, str(scenario_result.get("message", "LONG_RUN_STABILITY_FAIL unknown failure")))
			return
		print(str(scenario_result.get("summary", "")))

	var elapsed_seconds: float = float(Time.get_ticks_usec() - started_at_usec) / 1000000.0
	var result_line: String = "LONG_RUN_STABILITY_OK scenarios=%d days_each=%d total_days=%d max_gain=%s max_drop=%s corporate_apps=%d split_rebases=%d elapsed=%ss" % [
		scenarios.size(),
		days_per_scenario,
		total_days_checked,
		"%s %.2f%%" % [max_gain_label, max_gain_pct * 100.0],
		"%s %.2f%%" % [max_drop_label, max_drop_pct * 100.0],
		corporate_applications_seen,
		split_rebases_seen,
		String.num(elapsed_seconds, 2)
	]
	_finish(true, result_line)


func _days_per_scenario() -> int:
	for arg in OS.get_cmdline_user_args():
		var clean_arg: String = str(arg)
		if clean_arg.begins_with("--long-run-days="):
			return max(int(clean_arg.trim_prefix("--long-run-days=")), 1)
	return DEFAULT_DAYS_PER_SCENARIO


func _run_scenario(run_seed: int, difficulty_id: String, days_to_advance: int) -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(difficulty_id)
	var company_definitions: Array = GameManager.build_company_roster(run_seed, difficulty_config)
	if company_definitions.is_empty():
		return _failure("LONG_RUN_STABILITY_FAIL %s/%d generated an empty roster." % [difficulty_id, run_seed])
	RunState.setup_new_run(run_seed, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	var opening_validation: String = _validate_runtime_state("%s/%d opening" % [difficulty_id, run_seed])
	if not opening_validation.is_empty():
		return _failure(opening_validation)

	for day_offset in range(days_to_advance):
		var result: Dictionary = GameManager.call("_advance_day_internal", false, false, false)
		if result.is_empty():
			return _failure("LONG_RUN_STABILITY_FAIL %s/%d day %d returned an empty advance result." % [
				difficulty_id,
				run_seed,
				day_offset + 1
			])
		total_days_checked += 1
		_count_corporate_applications(result.get("day_result", {}))
		var validation: String = _validate_runtime_state("%s/%d day %d" % [difficulty_id, run_seed, RunState.day_index])
		if not validation.is_empty():
			return _failure(validation)
		if (day_offset + 1) % CHECKPOINT_INTERVAL == 0 or day_offset == days_to_advance - 1:
			var checkpoint_error: String = _validate_checkpoint_round_trip(difficulty_id, run_seed, day_offset + 1)
			if not checkpoint_error.is_empty():
				return _failure(checkpoint_error)

	var chart_error: String = _validate_chart_snapshots("%s/%d final" % [difficulty_id, run_seed])
	if not chart_error.is_empty():
		return _failure(chart_error)
	var equity: float = float(GameManager.get_portfolio_snapshot().get("equity", 0.0))
	return {
		"success": true,
		"summary": "LONG_RUN_SCENARIO_OK difficulty=%s seed=%d days=%d equity=%s" % [
			difficulty_id,
			run_seed,
			days_to_advance,
			String.num(equity, 2)
		]
	}


func _validate_runtime_state(context_label: String) -> String:
	if not RunState.has_active_run():
		return "LONG_RUN_STABILITY_FAIL %s lost active run state." % context_label
	if RunState.company_order.is_empty():
		return "LONG_RUN_STABILITY_FAIL %s has no companies." % context_label
	if not _is_valid_number(float(RunState.player_portfolio.get("cash", 0.0))):
		return "LONG_RUN_STABILITY_FAIL %s has invalid portfolio cash." % context_label

	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = RunState.get_company(company_id)
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		if runtime.is_empty() or definition.is_empty():
			return "LONG_RUN_STABILITY_FAIL %s missing runtime/definition for %s." % [context_label, company_id]
		var price_error: String = _validate_company_prices(context_label, company_id, runtime, definition)
		if not price_error.is_empty():
			return price_error
		var bars_error: String = _validate_runtime_price_bars(context_label, company_id, runtime)
		if not bars_error.is_empty():
			return bars_error
	return ""


func _validate_company_prices(context_label: String, company_id: String, runtime: Dictionary, definition: Dictionary) -> String:
	var current_price: float = float(runtime.get("current_price", 0.0))
	var previous_close: float = IDX_PRICE_RULES.normalize_last_price(float(runtime.get("previous_close", current_price)))
	if not _is_valid_price(current_price):
		return "LONG_RUN_STABILITY_FAIL %s invalid current price %s for %s." % [context_label, current_price, company_id]
	if not _is_valid_price(previous_close):
		return "LONG_RUN_STABILITY_FAIL %s invalid previous close %s for %s." % [context_label, previous_close, company_id]
	if not is_equal_approx(current_price, round(current_price)):
		return "LONG_RUN_STABILITY_FAIL %s current price for %s is not IDX-normalized: %s." % [context_label, company_id, current_price]

	var ar_limits: Dictionary = IDX_PRICE_RULES.auto_rejection_limits(previous_close, str(definition.get("listing_board", "main")))
	var lower_price: float = float(ar_limits.get("lower_price", current_price))
	var upper_price: float = float(ar_limits.get("upper_price", current_price))
	if current_price < lower_price - 0.0001 or current_price > upper_price + 0.0001:
		return "LONG_RUN_STABILITY_FAIL %s %s broke ARA/ARB %s-%s with current %s prev %s." % [
			context_label,
			company_id,
			lower_price,
			upper_price,
			current_price,
			previous_close
		]

	var daily_change_pct: float = 0.0
	if previous_close > 0.0:
		daily_change_pct = (current_price - previous_close) / previous_close
	_record_extreme_move(company_id, context_label, daily_change_pct)
	var runtime_daily_change_pct: float = float(runtime.get("daily_change_pct", daily_change_pct))
	if absf(runtime_daily_change_pct - daily_change_pct) > 0.0001:
		return "LONG_RUN_STABILITY_FAIL %s %s daily_change_pct drifted. runtime=%s recomputed=%s." % [
			context_label,
			company_id,
			runtime_daily_change_pct,
			daily_change_pct
		]
	return ""


func _validate_runtime_price_bars(context_label: String, company_id: String, runtime: Dictionary) -> String:
	var price_history: Array = runtime.get("price_history", [])
	if price_history.is_empty():
		return "LONG_RUN_STABILITY_FAIL %s %s has empty price history." % [context_label, company_id]
	var price_bars: Array = runtime.get("price_bars", [])
	if price_bars.size() > price_history.size():
		return "LONG_RUN_STABILITY_FAIL %s %s has more runtime bars than history points." % [context_label, company_id]
	if price_bars.size() > RunState.MAX_PRICE_BARS_HISTORY:
		return "LONG_RUN_STABILITY_FAIL %s %s exceeded runtime bar cap." % [context_label, company_id]

	for price_value in price_history:
		var price: float = float(price_value)
		if not _is_valid_price(price):
			return "LONG_RUN_STABILITY_FAIL %s %s has invalid price history value %s." % [context_label, company_id, price]

	var start_index: int = max(price_bars.size() - 12, 0)
	for bar_index in range(start_index, price_bars.size()):
		var bar_value = price_bars[bar_index]
		if typeof(bar_value) != TYPE_DICTIONARY:
			return "LONG_RUN_STABILITY_FAIL %s %s has non-dictionary bar at %d." % [context_label, company_id, bar_index]
		var bar: Dictionary = bar_value
		var bar_error: String = _validate_bar(context_label, company_id, bar, bar_index)
		if not bar_error.is_empty():
			return bar_error
	return ""


func _validate_bar(context_label: String, company_id: String, bar: Dictionary, bar_index: int) -> String:
	var open_price: float = float(bar.get("open", 0.0))
	var high_price: float = float(bar.get("high", 0.0))
	var low_price: float = float(bar.get("low", 0.0))
	var close_price: float = float(bar.get("close", 0.0))
	for price_value in [open_price, high_price, low_price, close_price]:
		var price: float = float(price_value)
		if not _is_valid_price(price):
			return "LONG_RUN_STABILITY_FAIL %s %s bar %d has invalid OHLC price %s." % [context_label, company_id, bar_index, price]
	if high_price < max(open_price, close_price) - 0.0001 or low_price > min(open_price, close_price) + 0.0001:
		return "LONG_RUN_STABILITY_FAIL %s %s bar %d has invalid OHLC order O=%s H=%s L=%s C=%s." % [
			context_label,
			company_id,
			bar_index,
			open_price,
			high_price,
			low_price,
			close_price
		]
	if float(bar.get("volume_shares", 1.0)) <= 0.0 or float(bar.get("value", 1.0)) <= 0.0:
		return "LONG_RUN_STABILITY_FAIL %s %s bar %d has invalid volume/value." % [context_label, company_id, bar_index]
	return ""


func _validate_checkpoint_round_trip(difficulty_id: String, run_seed: int, advanced_days: int) -> String:
	var state_before_save: Dictionary = RunState.to_save_dict()
	if not SaveManager.save_run(state_before_save, "slot_1"):
		return "LONG_RUN_STABILITY_FAIL %s/%d day %d could not save checkpoint." % [difficulty_id, run_seed, advanced_days]
	var loaded_state: Dictionary = SaveManager.load_run("slot_1")
	if loaded_state.is_empty():
		return "LONG_RUN_STABILITY_FAIL %s/%d day %d could not load checkpoint." % [difficulty_id, run_seed, advanced_days]
	RunState.load_from_dict(loaded_state)
	var validation: String = _validate_runtime_state("%s/%d checkpoint %d" % [difficulty_id, run_seed, advanced_days])
	if not validation.is_empty():
		return validation
	var state_after_load: Dictionary = RunState.to_save_dict()
	if int(state_after_load.get("day_index", -1)) != int(state_before_save.get("day_index", -2)):
		return "LONG_RUN_STABILITY_FAIL %s/%d checkpoint day_index changed after load." % [difficulty_id, run_seed]
	if state_after_load.get("company_order", []) != state_before_save.get("company_order", []):
		return "LONG_RUN_STABILITY_FAIL %s/%d checkpoint company order changed after load." % [difficulty_id, run_seed]
	return ""


func _validate_chart_snapshots(context_label: String) -> String:
	var range_ids: Array = ["1m", "3m", "6m", "1y", "5y", "ytd"]
	var checked_companies: int = 0
	for company_id_value in RunState.company_order:
		if checked_companies >= 5:
			break
		var company_id: String = str(company_id_value)
		checked_companies += 1
		for range_id_value in range_ids:
			var range_id: String = str(range_id_value)
			var snapshot: Dictionary = GameManager.get_company_chart_snapshot(company_id, range_id, ["sma_20"])
			var bars: Array = snapshot.get("bars", [])
			if bars.is_empty():
				return "LONG_RUN_STABILITY_FAIL %s %s returned empty chart bars for %s." % [context_label, company_id, range_id]
			for bar_index in range(bars.size()):
				var bar_value = bars[bar_index]
				if typeof(bar_value) != TYPE_DICTIONARY:
					return "LONG_RUN_STABILITY_FAIL %s %s chart %s has non-dictionary bar." % [context_label, company_id, range_id]
				var bar_error: String = _validate_bar("%s chart %s" % [context_label, range_id], company_id, bar_value, bar_index)
				if not bar_error.is_empty():
					return bar_error
	return ""


func _count_corporate_applications(day_result: Dictionary) -> void:
	for application_value in day_result.get("corporate_action_applications", []):
		if typeof(application_value) != TYPE_DICTIONARY:
			continue
		corporate_applications_seen += 1
		if str(application_value.get("application_type", "")) in ["stock_split", "stock_dividend"]:
			split_rebases_seen += 1


func _record_extreme_move(company_id: String, context_label: String, daily_change_pct: float) -> void:
	if daily_change_pct > max_gain_pct:
		max_gain_pct = daily_change_pct
		max_gain_label = "%s/%s" % [context_label, company_id]
	if daily_change_pct < max_drop_pct:
		max_drop_pct = daily_change_pct
		max_drop_label = "%s/%s" % [context_label, company_id]


func _is_valid_price(price: float) -> bool:
	return _is_valid_number(price) and price >= 1.0


func _is_valid_number(value: float) -> bool:
	return is_finite(value) and not is_nan(value)


func _failure(message: String) -> Dictionary:
	return {"success": false, "message": message}


func _finish(success: bool, message: String) -> void:
	print(message)
	if OS.get_cmdline_user_args().has(SMOKE_LOCAL_IO_ARG):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://logs"))
		var result_file = FileAccess.open(RESULT_PATH, FileAccess.WRITE)
		if result_file != null:
			result_file.store_string(message)
	get_tree().quit(0 if success else 1)
