extends Node

const RUN_SEED := 6062526
const SIZE_RATIO_LIMIT := 0.45


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config("normal")
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	if RunState.company_order.is_empty():
		_fail("Broker history compact contract expected a generated company roster.")
		return

	var company_id: String = str(RunState.company_order[0])
	var runtime: Dictionary = RunState.get_company(company_id)
	var compact_history: Array = runtime.get("broker_flow_history", [])
	if compact_history.is_empty():
		_fail("Expected seeded broker history rows.")
		return
	var legacy_entry: Dictionary = RunState.broker_history_v2_entry_to_range_entry(compact_history.back())
	legacy_entry.erase("schema_version")
	var v2_from_legacy: Dictionary = RunState.normalize_broker_history_v2_entry(legacy_entry)
	var v2_from_flow: Dictionary = RunState.build_broker_flow_history_v2_entry(
		runtime.get("broker_flow", {}),
		RunState.get_current_trade_date(),
		RunState.day_index
	)

	var contract_error: String = _validate_v2_entry(v2_from_legacy)
	if not contract_error.is_empty():
		_fail("Legacy row did not normalize into v2 contract: %s" % contract_error)
		return
	contract_error = _validate_v2_entry(v2_from_flow)
	if not contract_error.is_empty():
		_fail("Current broker flow did not build v2 contract: %s" % contract_error)
		return

	var legacy_bytes: int = _json_byte_size(legacy_entry)
	var v2_bytes: int = _json_byte_size(v2_from_legacy)
	if v2_bytes >= int(float(legacy_bytes) * SIZE_RATIO_LIMIT):
		_fail("Expected v2 row to be less than %.0f%% of v1 bytes, got v1=%d v2=%d." % [
			SIZE_RATIO_LIMIT * 100.0,
			legacy_bytes,
			v2_bytes
		])
		return

	var v2_rows: Array = []
	for entry_value in compact_history:
		var v2_entry: Dictionary = RunState.normalize_broker_history_v2_entry(entry_value)
		if not v2_entry.is_empty():
			v2_rows.append(v2_entry)
	var range_rows: Array = RunState.broker_history_v2_entries_to_range_rows(v2_rows)
	var one_month: Dictionary = GameManager.call("_aggregate_compact_broker_flow_range", range_rows, GameManager.call("_broker_range_definition", "1m"))
	if not _has_populated_broker_range(one_month, "1m"):
		_fail("Expected v2 range adapter to populate a 1M broker range.")
		return
	var three_month: Dictionary = GameManager.call("_aggregate_compact_broker_flow_range", range_rows, GameManager.call("_broker_range_definition", "3m"))
	if not _has_populated_broker_range(three_month, "3m"):
		_fail("Expected v2 range adapter to populate a 3M broker range.")
		return

	print("BROKER_HISTORY_COMPACT_CONTRACT_OK v1_bytes=%d v2_bytes=%d rows=%d" % [
		legacy_bytes,
		v2_bytes,
		v2_rows.size()
	])
	get_tree().quit(0)


func _validate_v2_entry(entry: Dictionary) -> String:
	if entry.is_empty():
		return "entry_empty"
	if int(entry.get("schema_version", 0)) != RunState.BROKER_HISTORY_COMPACT_SCHEMA_VERSION:
		return "schema_version"
	for key_value in RunState.broker_history_v2_required_keys():
		var key: String = str(key_value)
		if not entry.has(key):
			return "missing_%s" % key
	if entry.has("top_buy_brokers") or entry.has("top_sell_brokers") or entry.has("broker_type_totals"):
		return "kept_v1_heavy_fields"
	var type_nets: Dictionary = entry.get("type_nets", {})
	for type_key in ["retail", "foreign", "institution", "bandar", "zombie"]:
		if not type_nets.has(type_key):
			return "missing_type_net_%s" % type_key
	if max(float(entry.get("total_buy_value", 0.0)), float(entry.get("total_sell_value", 0.0))) <= 0.0:
		return "missing_total_value"
	return ""


func _has_populated_broker_range(snapshot: Dictionary, expected_range_id: String) -> bool:
	return (
		str(snapshot.get("range_id", "")) == expected_range_id and
		int(snapshot.get("range_day_count", 0)) > 0 and
		not snapshot.get("buy_brokers", []).is_empty() and
		not snapshot.get("sell_brokers", []).is_empty()
	)


func _json_byte_size(value: Variant) -> int:
	return JSON.stringify(value).to_utf8_buffer().size()


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
