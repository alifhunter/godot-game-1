extends Node

const RUN_SEED := 6062527
const LEGACY_EXTRA_ROWS := 36


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config("normal")
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	if RunState.company_order.is_empty():
		_fail("Broker history migration expected a generated company roster.")
		return

	var company_id: String = str(RunState.company_order[0])
	var source_runtime: Dictionary = RunState.get_company(company_id)
	var source_history: Array = source_runtime.get("broker_flow_history", [])
	if source_history.is_empty():
		_fail("Expected seeded broker history rows for migration fixture.")
		return

	var legacy_history: Array = _build_legacy_history(source_history)
	var source_save: Dictionary = RunState.to_save_dict()
	var companies: Dictionary = source_save.get("companies", {})
	var legacy_runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	legacy_runtime["broker_flow_history"] = legacy_history
	legacy_runtime["broker_flow_full_history"] = [{"day_index": 1, "heavy": true}]
	companies[company_id] = legacy_runtime
	source_save["companies"] = companies

	RunState.load_from_dict(source_save)
	var reloaded_runtime: Dictionary = RunState.get_company(company_id)
	var reloaded_history: Array = reloaded_runtime.get("broker_flow_history", [])
	var validation_error: String = _validate_v2_history(reloaded_history, RunState.MAX_BROKER_COMPACT_HISTORY_DAYS)
	if not validation_error.is_empty():
		_fail("Loaded legacy broker history did not migrate to v2: %s" % validation_error)
		return
	if not reloaded_runtime.get("broker_flow_full_history", []).is_empty():
		_fail("Expected broker_flow_full_history to be removed during load migration.")
		return

	var saved_again: Dictionary = RunState.to_save_dict()
	var saved_runtime: Dictionary = saved_again.get("companies", {}).get(company_id, {})
	var saved_history: Array = saved_runtime.get("broker_flow_history", [])
	validation_error = _validate_v2_history(saved_history, RunState.MAX_BROKER_COMPACT_HISTORY_DAYS)
	if not validation_error.is_empty():
		_fail("Re-saved broker history did not remain v2 compact: %s" % validation_error)
		return
	if saved_runtime.has("broker_flow_full_history"):
		_fail("Expected broker_flow_full_history to stay out of saved runtime payload.")
		return

	var three_month: Dictionary = GameManager.get_company_broker_flow_snapshot(company_id, "3m")
	if not _has_populated_broker_range(three_month, "3m"):
		_fail("Expected migrated v2 history to populate 3M broker range.")
		return

	print("BROKER_HISTORY_MIGRATION_OK legacy_rows=%d migrated_rows=%d saved_rows=%d" % [
		legacy_history.size(),
		reloaded_history.size(),
		saved_history.size()
	])
	get_tree().quit(0)


func _build_legacy_history(source_history: Array) -> Array:
	var legacy_history: Array = []
	var target_count: int = RunState.MAX_BROKER_COMPACT_HISTORY_DAYS + LEGACY_EXTRA_ROWS
	for index in range(target_count):
		var source_entry: Dictionary = source_history[index % source_history.size()]
		var legacy_entry: Dictionary = RunState.broker_history_v2_entry_to_range_entry(source_entry)
		legacy_entry.erase("schema_version")
		var day_number: int = index + 1
		legacy_entry["day_index"] = day_number
		legacy_entry["trade_date"] = RunState.trading_calendar.trade_date_for_index(day_number)
		legacy_history.append(legacy_entry)
	return legacy_history


func _validate_v2_history(history: Array, expected_count: int) -> String:
	if history.size() != expected_count:
		return "row_count_%d_expected_%d" % [history.size(), expected_count]
	var previous_day: int = -999999
	for row_value in history:
		if typeof(row_value) != TYPE_DICTIONARY:
			return "non_dictionary_row"
		var row: Dictionary = row_value
		if int(row.get("schema_version", 0)) != RunState.BROKER_HISTORY_COMPACT_SCHEMA_VERSION:
			return "schema_version"
		if row.has("top_buy_brokers") or row.has("top_sell_brokers") or row.has("top_net_buy_brokers") or row.has("top_net_sell_brokers"):
			return "kept_top_broker_rows"
		if row.has("broker_type_totals"):
			return "kept_broker_type_totals"
		if typeof(row.get("type_nets", {})) != TYPE_DICTIONARY:
			return "missing_type_nets"
		var day_number: int = int(row.get("day_index", 0))
		if day_number <= previous_day:
			return "not_sorted"
		previous_day = day_number
	return ""


func _has_populated_broker_range(snapshot: Dictionary, expected_range_id: String) -> bool:
	return (
		str(snapshot.get("range_id", "")) == expected_range_id and
		int(snapshot.get("range_day_count", 0)) > 0 and
		not snapshot.get("buy_brokers", []).is_empty() and
		not snapshot.get("sell_brokers", []).is_empty()
	)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
