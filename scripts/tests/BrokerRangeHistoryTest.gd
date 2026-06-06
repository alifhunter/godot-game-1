extends Node

const RUN_SEED := 6062026
const ADVANCE_DAYS := 25


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config("normal")
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	if RunState.company_order.is_empty():
		_fail("Broker range test expected a generated company roster.")
		return

	var company_id: String = str(RunState.company_order[0])
	var runtime: Dictionary = RunState.get_company(company_id)
	if runtime.get("broker_flow_history", []).size() < RunState.BROKER_HISTORY_BACKFILL_DAYS:
		_fail("Expected seeded compact broker history to cover the December backfill window.")
		return
	if not runtime.get("broker_flow_full_history", []).is_empty():
		_fail("Expected full broker row history to stay empty for the lightweight broker range path.")
		return

	var opening_month: Dictionary = GameManager.get_company_broker_flow_snapshot(company_id, "1m")
	if not _has_populated_broker_range(opening_month, "1m"):
		_fail("Expected opening 1M broker range to aggregate seeded broker rows.")
		return
	if str(opening_month.get("history_mode", "")) != "compact":
		_fail("Expected opening 1M broker range to use compact broker history.")
		return

	for _day in range(ADVANCE_DAYS):
		GameManager.advance_day_deferred_save()

	runtime = RunState.get_company(company_id)
	var compact_history: Array = runtime.get("broker_flow_history", [])
	if compact_history.size() < RunState.BROKER_HISTORY_BACKFILL_DAYS + ADVANCE_DAYS:
		_fail("Expected compact broker history to keep accumulating across advanced days.")
		return
	if not runtime.get("broker_flow_full_history", []).is_empty():
		_fail("Expected full broker row history to remain empty after advancing days.")
		return

	var three_month: Dictionary = GameManager.get_company_broker_flow_snapshot(company_id, "3m")
	if not _has_populated_broker_range(three_month, "3m"):
		_fail("Expected 3M broker range to aggregate compact broker rows after the full-history window rolls forward.")
		return
	if str(three_month.get("history_mode", "")) != "compact":
		_fail("Expected 3M broker range to use compact history after advancing beyond the full broker-row window.")
		return

	var saved_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(saved_state)
	var reloaded_runtime: Dictionary = RunState.get_company(company_id)
	if reloaded_runtime.get("broker_flow_history", []).size() != compact_history.size():
		_fail("Expected compact broker history size to survive save/load.")
		return
	if not reloaded_runtime.get("broker_flow_full_history", []).is_empty():
		_fail("Expected save/load normalization to drop full broker row history.")
		return

	print("BROKER_RANGE_HISTORY_OK compact=%d mode=%s" % [
		compact_history.size(),
		str(three_month.get("history_mode", ""))
	])
	get_tree().quit(0)


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
