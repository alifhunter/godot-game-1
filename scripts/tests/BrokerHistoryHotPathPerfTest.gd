extends Node

const RUN_SEED := 6062528
const ADVANCE_DAYS := 30
const NORMALIZE_LATE_MAX_SOFT_LIMIT_MS := 750.0


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config("normal")
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	if RunState.company_order.is_empty():
		_fail("Broker history hot-path test expected a generated company roster.")
		return

	var normalize_samples: Array = []
	for _day in range(ADVANCE_DAYS):
		GameManager.advance_day_deferred_save()
		var metrics: Dictionary = RunState.get_last_apply_day_perf_metrics()
		if not metrics.has("normalize_companies"):
			_fail("Missing normalize_companies apply-day metric.")
			return
		normalize_samples.append(float(metrics.get("normalize_companies", 0.0)))

	var company_id: String = str(RunState.company_order[0])
	var runtime: Dictionary = RunState.get_company(company_id)
	var history: Array = runtime.get("broker_flow_history", [])
	var history_error: String = _validate_hot_path_history(history)
	if not history_error.is_empty():
		_fail("Broker history hot path produced invalid v2 history: %s" % history_error)
		return

	var median_ms: float = _median(normalize_samples)
	var late_max_ms: float = _max_value(normalize_samples.slice(max(normalize_samples.size() - 10, 0), normalize_samples.size()))
	if late_max_ms > NORMALIZE_LATE_MAX_SOFT_LIMIT_MS:
		_fail("normalize_companies late max %.2fms exceeded soft guard %.2fms." % [
			late_max_ms,
			NORMALIZE_LATE_MAX_SOFT_LIMIT_MS
		])
		return

	print("BROKER_HISTORY_HOT_PATH_OK days=%d normalize_median=%.2fms normalize_late_max=%.2fms history_rows=%d" % [
		ADVANCE_DAYS,
		median_ms,
		late_max_ms,
		history.size()
	])
	get_tree().quit(0)


func _validate_hot_path_history(history: Array) -> String:
	var expected_max_rows: int = RunState.BROKER_HISTORY_BACKFILL_DAYS + ADVANCE_DAYS
	if history.size() <= 0:
		return "empty"
	if history.size() > min(expected_max_rows, RunState.MAX_BROKER_COMPACT_HISTORY_DAYS):
		return "too_many_rows"
	var previous_day: int = -999999
	for row_value in history:
		if typeof(row_value) != TYPE_DICTIONARY:
			return "non_dictionary_row"
		var row: Dictionary = row_value
		if int(row.get("schema_version", 0)) != RunState.BROKER_HISTORY_COMPACT_SCHEMA_VERSION:
			return "schema_version"
		if row.has("top_buy_brokers") or row.has("top_sell_brokers") or row.has("broker_type_totals"):
			return "heavy_v1_field"
		if typeof(row.get("type_nets", {})) != TYPE_DICTIONARY:
			return "missing_type_nets"
		var day_number: int = int(row.get("day_index", 0))
		if day_number <= previous_day:
			return "not_strictly_sorted"
		previous_day = day_number
	return ""


func _median(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var sorted_values: Array = values.duplicate()
	sorted_values.sort()
	var middle_index: int = int(sorted_values.size() / 2)
	if sorted_values.size() % 2 == 1:
		return float(sorted_values[middle_index])
	return (float(sorted_values[middle_index - 1]) + float(sorted_values[middle_index])) * 0.5


func _max_value(values: Array) -> float:
	var max_value: float = 0.0
	for value in values:
		max_value = max(max_value, float(value))
	return max_value


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
