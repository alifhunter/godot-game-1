extends Node

const SMOKE_LOCAL_IO_ARG := "--smoke-local-io"
const BUY_WINNERS_ARG := "--event-audit-buy-winners"
const RESULT_PATH := "res://logs/event_generation_audit_result.txt"
const DEFAULT_AUDIT_DAYS := 60
const WINNER_BUY_INTERVAL_DAYS := 5
const WINNER_BUY_TOP_COUNT := 3
const WINNER_BUY_CASH_RESERVE_RATIO := 0.25
const WINNER_BUY_TARGET_EXPOSURE_RATIO := 0.70
const WINNER_BUY_MAX_CASH_USE_RATIO := 0.14
const POLICY_EVENT_IDS := [
	"policy_free_lunch_budget_balloon",
	"policy_fiscal_guardian_swap",
	"policy_market_speech_jolt",
	"policy_village_fx_comment",
	"policy_commodity_export_gate"
]

var seen_counts := {}
var first_seen := {}
var family_counts := {}
var scenario_lines: Array = []


func _ready() -> void:
	call_deferred("_run_event_audit")


func _run_event_audit() -> void:
	DataRepository.reload_all()
	if OS.get_cmdline_user_args().has(SMOKE_LOCAL_IO_ARG):
		for slot_index in range(1, SaveManager.SAVE_SLOT_COUNT + 1):
			SaveManager.delete_save("slot_%d" % slot_index)

	var audit_days: int = _audit_days()
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
		var scenario_line: String = _run_scenario(
			int(scenario.get("seed", 0)),
			str(scenario.get("difficulty", "normal")),
			audit_days,
			OS.get_cmdline_user_args().has(BUY_WINNERS_ARG)
		)
		if scenario_line.begins_with("EVENT_AUDIT_FAIL"):
			_finish(false, scenario_line)
			return
		scenario_lines.append(scenario_line)
		print(scenario_line)

	var result_line: String = _build_result_line(scenarios.size(), audit_days, started_at_usec)
	_finish(true, result_line)


func _audit_days() -> int:
	for arg in OS.get_cmdline_user_args():
		var clean_arg: String = str(arg)
		if clean_arg.begins_with("--event-audit-days="):
			return max(int(clean_arg.trim_prefix("--event-audit-days=")), 1)
	return DEFAULT_AUDIT_DAYS


func _run_scenario(run_seed: int, difficulty_id: String, days_to_advance: int, buy_winners: bool) -> String:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(difficulty_id)
	var company_definitions: Array = GameManager.build_company_roster(run_seed, difficulty_config)
	if company_definitions.is_empty():
		return "EVENT_AUDIT_FAIL difficulty=%s seed=%d generated empty roster" % [difficulty_id, run_seed]

	RunState.setup_new_run(run_seed, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	var scenario_counts := {}
	var winner_buy_count: int = 0
	var winner_buy_value: float = 0.0
	for day_offset in range(days_to_advance):
		var result: Dictionary = GameManager.call("_advance_day_internal", false, false, false)
		if result.is_empty():
			return "EVENT_AUDIT_FAIL difficulty=%s seed=%d day=%d returned empty result" % [
				difficulty_id,
				run_seed,
				day_offset + 1
			]
		_record_day_events(result.get("day_result", {}), difficulty_id, run_seed, scenario_counts)
		if buy_winners and ((day_offset + 1) % WINNER_BUY_INTERVAL_DAYS == 0 or day_offset == 0):
			var buy_result: Dictionary = _buy_recent_winners(difficulty_config)
			winner_buy_count += int(buy_result.get("buys", 0))
			winner_buy_value += float(buy_result.get("gross_value", 0.0))

	var scenario_seen: Array = scenario_counts.keys()
	scenario_seen.sort()
	var policy_seen: Array = []
	for policy_id in POLICY_EVENT_IDS:
		if scenario_counts.has(policy_id):
			policy_seen.append(policy_id)
	var portfolio: Dictionary = GameManager.get_portfolio_snapshot()
	return "EVENT_AUDIT_SCENARIO difficulty=%s seed=%d days=%d unique_events=%d policy_seen=%s winner_buys=%d winner_buy_value=%s equity=%s top_holdings=%s events=%s" % [
		difficulty_id,
		run_seed,
		days_to_advance,
		scenario_seen.size(),
		_join_or_dash(policy_seen),
		winner_buy_count,
		String.num(winner_buy_value, 2),
		String.num(float(portfolio.get("equity", 0.0)), 2),
		_format_top_holdings(portfolio, 3),
		_join_or_dash(scenario_seen)
	]


func _record_day_events(day_result: Dictionary, difficulty_id: String, run_seed: int, scenario_counts: Dictionary) -> void:
	var event_groups: Array = [
		day_result.get("scheduled_event", {}),
		day_result.get("report_events", []),
		day_result.get("started_company_arcs", []),
		day_result.get("company_arc_phase_events", []),
		day_result.get("company_roadmap_events", []),
		day_result.get("started_special_events", []),
		day_result.get("corporate_action_events", []),
		day_result.get("index_review_events", [])
	]
	for group_value in event_groups:
		if typeof(group_value) == TYPE_ARRAY:
			for event_value in group_value:
				_record_event(event_value, day_result, difficulty_id, run_seed, scenario_counts)
		else:
			_record_event(group_value, day_result, difficulty_id, run_seed, scenario_counts)


func _record_event(
	event_value: Variant,
	day_result: Dictionary,
	difficulty_id: String,
	run_seed: int,
	scenario_counts: Dictionary
) -> void:
	if typeof(event_value) != TYPE_DICTIONARY:
		return
	var event_data: Dictionary = event_value
	var event_id: String = str(event_data.get("event_id", event_data.get("id", "")))
	if event_id.is_empty():
		return

	seen_counts[event_id] = int(seen_counts.get(event_id, 0)) + 1
	scenario_counts[event_id] = int(scenario_counts.get(event_id, 0)) + 1
	if not first_seen.has(event_id):
		first_seen[event_id] = "%s/%d day %d" % [
			difficulty_id,
			run_seed,
			int(day_result.get("day_number", RunState.day_index))
		]

	var event_definition: Dictionary = DataRepository.get_event_definition(event_id)
	var family: String = str(event_data.get("event_family", event_definition.get("event_family", "unknown")))
	if family.is_empty():
		family = "unknown"
	family_counts[family] = int(family_counts.get(family, 0)) + 1


func _build_result_line(scenario_count: int, days_each: int, started_at_usec: int) -> String:
	var elapsed_seconds: float = float(Time.get_ticks_usec() - started_at_usec) / 1000000.0
	var all_definition_ids: Array = _event_definition_ids()
	var seen_definition_ids: Array = []
	var missing_definition_ids: Array = []
	for event_id_value in all_definition_ids:
		var event_id: String = str(event_id_value)
		if seen_counts.has(event_id):
			seen_definition_ids.append(event_id)
		else:
			missing_definition_ids.append(event_id)

	var policy_seen: Array = []
	var policy_missing: Array = []
	for policy_id in POLICY_EVENT_IDS:
		if seen_counts.has(policy_id):
			policy_seen.append(policy_id)
		else:
			policy_missing.append(policy_id)

	return "EVENT_AUDIT_OK scenarios=%d days_each=%d total_days=%d definitions_seen=%d/%d policy_seen=%d/%d policy=%s missing_policy=%s missing_definitions=%s family_counts=%s top_events=%s elapsed=%ss" % [
		scenario_count,
		days_each,
		scenario_count * days_each,
		seen_definition_ids.size(),
		all_definition_ids.size(),
		policy_seen.size(),
		POLICY_EVENT_IDS.size(),
		_join_or_dash(policy_seen),
		_join_or_dash(policy_missing),
		_join_or_dash(missing_definition_ids),
		_format_counts(family_counts),
		_format_top_events(18),
		String.num(elapsed_seconds, 2)
	]


func _event_definition_ids() -> Array:
	var ids: Array = []
	for definition_value in DataRepository.get_event_definitions():
		if typeof(definition_value) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = definition_value
		var event_id: String = str(definition.get("id", ""))
		if not event_id.is_empty():
			ids.append(event_id)
	ids.sort()
	return ids


func _format_counts(counts: Dictionary) -> String:
	var keys: Array = counts.keys()
	keys.sort()
	var parts: Array = []
	for key_value in keys:
		var key: String = str(key_value)
		parts.append("%s:%d" % [key, int(counts.get(key, 0))])
	return ",".join(parts)


func _format_top_events(limit: int) -> String:
	var rows: Array = []
	for event_id_value in seen_counts.keys():
		var event_id: String = str(event_id_value)
		rows.append({
			"id": event_id,
			"count": int(seen_counts.get(event_id, 0)),
			"first": str(first_seen.get(event_id, ""))
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("count", 0)) == int(b.get("count", 0)):
			return str(a.get("id", "")) < str(b.get("id", ""))
		return int(a.get("count", 0)) > int(b.get("count", 0))
	)
	var parts: Array = []
	for index in range(min(limit, rows.size())):
		var row: Dictionary = rows[index]
		parts.append("%s:%d@%s" % [
			str(row.get("id", "")),
			int(row.get("count", 0)),
			str(row.get("first", ""))
		])
	return _join_or_dash(parts)


func _buy_recent_winners(difficulty_config: Dictionary) -> Dictionary:
	var portfolio: Dictionary = GameManager.get_portfolio_snapshot()
	var cash: float = max(float(portfolio.get("cash", 0.0)), 0.0)
	var equity: float = max(float(portfolio.get("equity", cash)), 1.0)
	var market_value: float = max(equity - cash, 0.0)
	var starting_cash: float = max(float(difficulty_config.get("starting_cash", cash)), 1.0)
	var cash_reserve: float = starting_cash * WINNER_BUY_CASH_RESERVE_RATIO
	var exposure_room: float = (equity * WINNER_BUY_TARGET_EXPOSURE_RATIO) - market_value
	var spendable_cash: float = min(cash - cash_reserve, exposure_room, cash * WINNER_BUY_MAX_CASH_USE_RATIO)
	if spendable_cash <= 0.0:
		return {"buys": 0, "gross_value": 0.0}

	var rows: Array = GameManager.get_company_market_rows(true)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a.get("daily_change_pct", 0.0)) == float(b.get("daily_change_pct", 0.0)):
			return str(a.get("ticker", "")) < str(b.get("ticker", ""))
		return float(a.get("daily_change_pct", 0.0)) > float(b.get("daily_change_pct", 0.0))
	)

	var buys: int = 0
	var gross_value: float = 0.0
	var selected: int = 0
	for row_value in rows:
		if selected >= WINNER_BUY_TOP_COUNT:
			break
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if bool(row.get("trade_disabled", false)):
			continue
		if float(row.get("daily_change_pct", 0.0)) <= 0.0:
			continue
		var company_id: String = str(row.get("id", ""))
		if company_id.is_empty():
			continue

		var remaining_budget: float = spendable_cash - gross_value
		if remaining_budget <= 0.0:
			break
		var target_budget: float = remaining_budget / float(max(WINNER_BUY_TOP_COUNT - selected, 1))
		var one_lot_estimate: Dictionary = GameManager.estimate_buy_lots(company_id, 1)
		if not bool(one_lot_estimate.get("success", false)):
			continue
		var one_lot_cost: float = max(float(one_lot_estimate.get("total_cost", 0.0)), 0.0)
		if one_lot_cost <= 0.0 or one_lot_cost > remaining_budget:
			continue
		var lots: int = max(int(floor(target_budget / one_lot_cost)), 1)
		lots = min(lots, int(floor(remaining_budget / one_lot_cost)))
		if lots <= 0:
			continue
		var buy_result: Dictionary = GameManager.buy_lots(company_id, lots)
		if not bool(buy_result.get("success", false)):
			continue
		buys += 1
		gross_value += one_lot_cost * float(lots)
		selected += 1

	return {"buys": buys, "gross_value": gross_value}


func _format_top_holdings(portfolio: Dictionary, limit: int) -> String:
	var holdings: Array = portfolio.get("holdings", [])
	if holdings.is_empty():
		return "-"
	var rows: Array = holdings.duplicate(true)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a.get("unrealized_pnl_pct", 0.0)) == float(b.get("unrealized_pnl_pct", 0.0)):
			return str(a.get("ticker", "")) < str(b.get("ticker", ""))
		return float(a.get("unrealized_pnl_pct", 0.0)) > float(b.get("unrealized_pnl_pct", 0.0))
	)
	var parts: Array = []
	for index in range(min(limit, rows.size())):
		var row: Dictionary = rows[index]
		parts.append("%s:%s%%" % [
			str(row.get("ticker", row.get("company_id", ""))),
			String.num(float(row.get("unrealized_pnl_pct", 0.0)) * 100.0, 2)
		])
	return _join_or_dash(parts)


func _join_or_dash(values: Array) -> String:
	if values.is_empty():
		return "-"
	var text_values: Array = []
	for value in values:
		text_values.append(str(value))
	return "|".join(text_values)


func _finish(success: bool, message: String) -> void:
	print(message)
	if OS.get_cmdline_user_args().has(SMOKE_LOCAL_IO_ARG):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://logs"))
		var result_file = FileAccess.open(RESULT_PATH, FileAccess.WRITE)
		if result_file != null:
			result_file.store_string("%s\n%s" % [
				"\n".join(scenario_lines),
				message
			])
	get_tree().quit(0 if success else 1)
