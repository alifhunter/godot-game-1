extends Node

const RUN_SEED := 706133
const TRADING_DAYS := 30
const CONTACT_A_ID := "andika_brokerage_sales"
const CONTACT_B_ID := "budi_supply_chain"
const CONTACT_NETWORK_SYSTEM_SCRIPT := preload("res://systems/ContactNetworkSystem.gd")

var _network = CONTACT_NETWORK_SYSTEM_SCRIPT.new()
var _failed := false


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	RunState.player_portfolio["cash"] = 125000000.0
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0

	var primary: Dictionary = _company_context(0)
	var secondary: Dictionary = _company_context(1)
	if primary.is_empty() or secondary.is_empty():
		_fail("Network 30-day scenario expected at least two generated companies.")
		return
	_assert_contact_exists(CONTACT_A_ID)
	_assert_contact_exists(CONTACT_B_ID)
	if _failed:
		return

	var metrics: Dictionary = _default_metrics()
	metrics["seed"] = RUN_SEED
	metrics["requested_days"] = TRADING_DAYS
	metrics["primary_ticker"] = str(primary.get("ticker", ""))
	metrics["secondary_ticker"] = str(secondary.get("ticker", ""))

	_seed_known_discoveries(primary)
	metrics["company_discoveries"] = GameManager.discover_network_contacts_for_company(str(primary.get("id", ""))).size()
	if not _meet_contact(CONTACT_A_ID, metrics):
		return
	if not _meet_contact(CONTACT_B_ID, metrics):
		return
	_set_relationship(CONTACT_A_ID, 62)
	_set_relationship(CONTACT_B_ID, 57)

	var buy_result: Dictionary = RunState.buy_company(str(primary.get("id", "")), 100)
	if not bool(buy_result.get("success", false)):
		_fail("Network 30-day scenario expected the initial request holding buy to succeed: %s" % str(buy_result.get("message", "")))
		return

	for day_offset in range(TRADING_DAYS):
		_run_scheduled_network_actions(day_offset, primary, secondary, metrics)
		var advance_result: Dictionary = GameManager.simulate_opening_session(false)
		var day_result: Dictionary = advance_result.get("day_result", {})
		if day_result.is_empty():
			_fail("Network 30-day scenario advance returned no day_result at offset %d." % day_offset)
			return
		metrics["days_completed"] = int(metrics.get("days_completed", 0)) + 1
		_collect_advance_metrics(RunState.last_day_results, metrics)
		_run_available_followups(metrics)
		_run_available_source_checks(metrics)

	var snapshot: Dictionary = GameManager.get_network_snapshot()
	var report: Dictionary = _build_report(snapshot, metrics)
	var validation_error: String = _validate_report(report)
	if not validation_error.is_empty():
		_fail("%s report=%s" % [validation_error, JSON.stringify(report)])
		return

	print("CONTACT_NETWORK_30_DAY_OK %s" % JSON.stringify(report))
	get_tree().quit(0)


func _default_metrics() -> Dictionary:
	return {
		"days_completed": 0,
		"company_discoveries": 0,
		"contacts_met": 0,
		"tips_requested": 0,
		"requests_created": 0,
		"conflict_tips_seeded": 0,
		"followups_sent": 0,
		"source_checks_sent": 0,
		"network_request_results": 0,
		"network_tip_results": 0,
		"network_tip_reactions": 0
	}


func _run_scheduled_network_actions(day_offset: int, primary: Dictionary, secondary: Dictionary, metrics: Dictionary) -> void:
	_reset_daily_actions()
	if day_offset == 0:
		_request_tip(CONTACT_A_ID, str(primary.get("id", "")), metrics)
		_request_tip(CONTACT_B_ID, str(primary.get("id", "")), metrics)
		_accept_request(CONTACT_A_ID, str(primary.get("id", "")), metrics)
	elif day_offset == 1:
		_seed_conflict_tips(primary, metrics)
		_run_available_source_checks(metrics)
	elif day_offset in [5, 10, 15, 20]:
		_request_tip(CONTACT_A_ID, str(primary.get("id", "")), metrics)
		_request_tip(CONTACT_B_ID, str(secondary.get("id", "")), metrics)
	elif day_offset in [8, 14, 22]:
		_request_tip(CONTACT_B_ID, str(primary.get("id", "")), metrics)
	_run_available_followups(metrics)


func _meet_contact(contact_id: String, metrics: Dictionary) -> bool:
	_reset_daily_actions()
	var result: Dictionary = GameManager.meet_contact(contact_id, {"source_type": "network_30_day_scenario"})
	if not bool(result.get("success", false)):
		_fail("Network 30-day scenario expected meet_contact(%s) to succeed: %s" % [contact_id, str(result.get("message", ""))])
		return false
	metrics["contacts_met"] = int(metrics.get("contacts_met", 0)) + 1
	return true


func _request_tip(contact_id: String, company_id: String, metrics: Dictionary) -> void:
	if company_id.is_empty():
		return
	_reset_daily_actions()
	var result: Dictionary = GameManager.request_contact_tip(contact_id, company_id)
	if bool(result.get("success", false)):
		metrics["tips_requested"] = int(metrics.get("tips_requested", 0)) + 1


func _accept_request(contact_id: String, company_id: String, metrics: Dictionary) -> void:
	if company_id.is_empty():
		return
	_reset_daily_actions()
	var result: Dictionary = GameManager.accept_contact_request(contact_id, company_id)
	if not bool(result.get("success", false)):
		_fail("Network 30-day scenario expected accept_contact_request to succeed: %s" % str(result.get("message", "")))
		return
	metrics["requests_created"] = int(metrics.get("requests_created", 0)) + 1


func _run_available_followups(metrics: Dictionary) -> void:
	var snapshot: Dictionary = GameManager.get_network_snapshot()
	for contact_value in snapshot.get("contacts", []):
		if typeof(contact_value) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = contact_value
		if not bool(contact.get("can_follow_up_tip", false)):
			continue
		var options: Array = contact.get("tip_followup_options", []) if typeof(contact.get("tip_followup_options", [])) == TYPE_ARRAY else []
		if options.is_empty() or typeof(options[0]) != TYPE_DICTIONARY:
			continue
		_reset_daily_actions()
		var option: Dictionary = options[0]
		var result: Dictionary = GameManager.follow_up_contact_tip(str(contact.get("id", "")), str(option.get("id", "thank")))
		if bool(result.get("success", false)):
			metrics["followups_sent"] = int(metrics.get("followups_sent", 0)) + 1
			return


func _run_available_source_checks(metrics: Dictionary) -> void:
	if int(metrics.get("source_checks_sent", 0)) > 0:
		return
	var snapshot: Dictionary = GameManager.get_network_snapshot()
	for contact_value in snapshot.get("contacts", []):
		if typeof(contact_value) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = contact_value
		if not bool(contact.get("can_ask_source_check", false)):
			continue
		_reset_daily_actions()
		var result: Dictionary = GameManager.ask_contact_source_check(str(contact.get("id", "")))
		if bool(result.get("success", false)):
			metrics["source_checks_sent"] = int(metrics.get("source_checks_sent", 0)) + 1
			return


func _collect_advance_metrics(day_result: Dictionary, metrics: Dictionary) -> void:
	metrics["network_request_results"] = int(metrics.get("network_request_results", 0)) + day_result.get("network_request_results", []).size()
	var tip_results: Array = day_result.get("network_tip_results", []) if typeof(day_result.get("network_tip_results", [])) == TYPE_ARRAY else []
	metrics["network_tip_results"] = int(metrics.get("network_tip_results", 0)) + tip_results.size()
	for result_value in tip_results:
		if typeof(result_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = result_value
		if bool(row.get("reaction_sent", false)) or not str(row.get("reaction_label", "")).is_empty():
			metrics["network_tip_reactions"] = int(metrics.get("network_tip_reactions", 0)) + 1


func _build_report(snapshot: Dictionary, metrics: Dictionary) -> Dictionary:
	var journal: Dictionary = RunState.get_network_tip_journal()
	var requests: Dictionary = RunState.get_network_requests()
	var journal_rows: Array = snapshot.get("journal", []) if typeof(snapshot.get("journal", [])) == TYPE_ARRAY else []
	var contacts: Dictionary = RunState.get_network_contacts()
	var report: Dictionary = metrics.duplicate(true)
	report["final_day_index"] = RunState.day_index
	report["final_trade_date"] = RunState.get_current_trade_date()
	report["final_cash"] = _round_to(float(RunState.player_portfolio.get("cash", 0.0)), 2)
	report["final_equity"] = _round_to(RunState.get_total_equity(), 2)
	report["met_count"] = int(snapshot.get("met_count", 0))
	report["discoveries_count"] = (snapshot.get("discoveries", []) as Array).size() if typeof(snapshot.get("discoveries", [])) == TYPE_ARRAY else 0
	report["journal_rows"] = journal_rows.size()
	report["journal_type_counts"] = _journal_type_counts(journal_rows)
	report["tip_status_counts"] = _tip_status_counts(journal)
	report["tip_outcome_counts"] = _tip_outcome_counts(journal)
	report["request_status_counts"] = _request_status_counts(requests)
	report["relationships"] = _relationship_summary(contacts)
	report["overdue_pending_tips"] = _overdue_pending_tip_count(journal)
	report["overdue_pending_requests"] = _overdue_pending_request_count(requests)
	report["scenario_hash"] = _stable_hash(JSON.stringify({
		"metrics": metrics,
		"tip_status_counts": report.get("tip_status_counts", {}),
		"tip_outcome_counts": report.get("tip_outcome_counts", {}),
		"request_status_counts": report.get("request_status_counts", {}),
		"journal_type_counts": report.get("journal_type_counts", {}),
		"relationships": report.get("relationships", {}),
		"final_day_index": report.get("final_day_index", 0)
	}))
	return report


func _validate_report(report: Dictionary) -> String:
	if int(report.get("days_completed", 0)) != TRADING_DAYS:
		return "Expected exactly %d completed trading days." % TRADING_DAYS
	if int(report.get("met_count", 0)) < 2:
		return "Expected at least two met contacts."
	if int(report.get("tips_requested", 0)) < 8:
		return "Expected at least eight requested contact tips."
	if int(report.get("network_tip_results", 0)) < 8:
		return "Expected at least eight due network tip results."
	if int(report.get("network_tip_reactions", 0)) < 4:
		return "Expected at least four network tip reactions."
	if int(report.get("network_request_results", 0)) < 1:
		return "Expected at least one due network request result."
	if int(report.get("followups_sent", 0)) < 1:
		return "Expected at least one contact tip follow-up."
	if int(report.get("source_checks_sent", 0)) < 1:
		return "Expected at least one source conflict check."
	if int(report.get("journal_rows", 0)) < 10:
		return "Expected at least ten Network journal rows."
	if int(report.get("overdue_pending_tips", 0)) != 0:
		return "Expected no overdue pending network tips."
	if int(report.get("overdue_pending_requests", 0)) != 0:
		return "Expected no overdue pending network requests."
	var request_status_counts: Dictionary = report.get("request_status_counts", {}) if typeof(report.get("request_status_counts", {})) == TYPE_DICTIONARY else {}
	if int(request_status_counts.get("completed", 0)) < 1:
		return "Expected at least one completed network request."
	return ""


func _seed_known_discoveries(primary: Dictionary) -> void:
	var discoveries: Dictionary = RunState.get_network_discoveries()
	discoveries[CONTACT_A_ID] = _discovery_row(CONTACT_A_ID, "scenario", "network_30_day", primary)
	discoveries[CONTACT_B_ID] = _discovery_row(CONTACT_B_ID, "scenario", "network_30_day", primary)
	RunState.set_network_discoveries(discoveries)


func _seed_conflict_tips(primary: Dictionary, metrics: Dictionary) -> void:
	var company_id: String = str(primary.get("id", ""))
	var current_price: float = max(float(primary.get("current_price", 0.0)), 1.0)
	var ticker: String = str(primary.get("ticker", company_id.to_upper()))
	var journal: Dictionary = RunState.get_network_tip_journal()
	var first_id: String = "scenario_conflict_constructive_%d" % RunState.day_index
	var second_id: String = "scenario_conflict_caution_%d" % RunState.day_index
	if journal.has(first_id) or journal.has(second_id):
		return
	journal[first_id] = _manual_tip(first_id, CONTACT_A_ID, company_id, ticker, "Accumulation", "source book", current_price / 1.02)
	journal[second_id] = _manual_tip(second_id, CONTACT_B_ID, company_id, ticker, "Distribution Risk", "flow desk", current_price / 0.98)
	RunState.set_network_tip_journal(journal)
	metrics["conflict_tips_seeded"] = int(metrics.get("conflict_tips_seeded", 0)) + 2


func _manual_tip(tip_id: String, contact_id: String, company_id: String, ticker: String, truth_label: String, source_role: String, baseline_price: float) -> Dictionary:
	return {
		"id": tip_id,
		"contact_id": contact_id,
		"contact_name": _contact_name(contact_id),
		"target_company_id": company_id,
		"target_ticker": ticker,
		"created_day_index": RunState.day_index,
		"resolve_day_index": RunState.day_index + 3,
		"baseline_price": baseline_price,
		"baseline_shares": 100,
		"chain_id": "",
		"truth_label": truth_label,
		"confidence_label": "Scenario read",
		"source_role": source_role,
		"tip_read": "%s scenario conflict read for %s." % [ticker, truth_label],
		"status": "pending",
		"reaction_due_day_index": RunState.day_index + 3,
		"reaction_sent": false,
		"reaction_label": "",
		"reaction_note": "",
		"reaction_relationship_delta": 0,
		"reaction_reliability_delta": 0,
		"reaction_twooter_account_id": "network_%s" % contact_id,
		"reaction_twooter_handle": "@%s" % contact_id.replace("_", "")
	}


func _company_context(order_index: int) -> Dictionary:
	if RunState.company_order.size() <= order_index:
		return {}
	var company_id: String = str(RunState.company_order[order_index])
	var company: Dictionary = RunState.get_company(company_id)
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	return {
		"id": company_id,
		"ticker": str(definition.get("ticker", company_id.to_upper())),
		"sector_id": str(definition.get("sector_id", "")),
		"current_price": float(company.get("current_price", 0.0))
	}


func _discovery_row(contact_id: String, source_type: String, source_id: String, primary: Dictionary) -> Dictionary:
	return {
		"contact_id": contact_id,
		"discovered": true,
		"source_type": source_type,
		"source_id": source_id,
		"target_company_id": str(primary.get("id", "")),
		"target_company_ids": [str(primary.get("id", ""))],
		"target_ticker": str(primary.get("ticker", "")),
		"target_sector_id": str(primary.get("sector_id", "")),
		"lead_score": 90,
		"day_index": RunState.day_index
	}


func _set_relationship(contact_id: String, relationship: int) -> void:
	var contacts: Dictionary = RunState.get_network_contacts()
	var runtime: Dictionary = contacts.get(contact_id, {})
	runtime["relationship"] = relationship
	contacts[contact_id] = runtime
	RunState.set_network_contacts(contacts)


func _reset_daily_actions() -> void:
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0


func _journal_type_counts(rows: Array) -> Dictionary:
	var counts: Dictionary = {}
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		_increment(counts, str(row.get("type", "")))
	return counts


func _tip_status_counts(journal: Dictionary) -> Dictionary:
	var counts: Dictionary = {}
	for tip_value in journal.values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		_increment(counts, str(tip.get("status", "pending")))
	return counts


func _tip_outcome_counts(journal: Dictionary) -> Dictionary:
	var counts: Dictionary = {}
	for tip_value in journal.values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		var outcome_label: String = str(tip.get("outcome_label", ""))
		if not outcome_label.is_empty():
			_increment(counts, outcome_label)
	return counts


func _request_status_counts(requests: Dictionary) -> Dictionary:
	var counts: Dictionary = {}
	for request_value in requests.values():
		if typeof(request_value) != TYPE_DICTIONARY:
			continue
		var request: Dictionary = request_value
		_increment(counts, str(request.get("status", "")))
	return counts


func _relationship_summary(contacts: Dictionary) -> Dictionary:
	var relationships: Array = []
	for contact_id in [CONTACT_A_ID, CONTACT_B_ID]:
		var runtime: Dictionary = contacts.get(contact_id, {}) if typeof(contacts.get(contact_id, {})) == TYPE_DICTIONARY else {}
		relationships.append(int(runtime.get("relationship", 0)))
	var total: int = 0
	for value in relationships:
		total += int(value)
	return {
		"min": relationships.min() if not relationships.is_empty() else 0,
		"max": relationships.max() if not relationships.is_empty() else 0,
		"avg": _round_to(float(total) / float(max(relationships.size(), 1)), 2),
		"values": relationships
	}


func _overdue_pending_tip_count(journal: Dictionary) -> int:
	var count: int = 0
	for tip_value in journal.values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		if str(tip.get("status", "pending")) == "pending" and int(tip.get("resolve_day_index", 0)) <= RunState.day_index:
			count += 1
	return count


func _overdue_pending_request_count(requests: Dictionary) -> int:
	var count: int = 0
	for request_value in requests.values():
		if typeof(request_value) != TYPE_DICTIONARY:
			continue
		var request: Dictionary = request_value
		if str(request.get("status", "")) == "pending" and int(request.get("due_day_index", 0)) <= RunState.day_index:
			count += 1
	return count


func _increment(counts: Dictionary, key: String) -> void:
	if key.is_empty():
		key = "(empty)"
	counts[key] = int(counts.get(key, 0)) + 1


func _assert_contact_exists(contact_id: String) -> void:
	if _contact_definition(contact_id).is_empty():
		_fail("Missing network scenario contact definition: %s" % contact_id)


func _contact_definition(contact_id: String) -> Dictionary:
	for contact_value in DataRepository.get_contact_network_data().get("contacts", []):
		if typeof(contact_value) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = contact_value
		if str(contact.get("id", "")) == contact_id:
			return contact.duplicate(true)
	return {}


func _contact_name(contact_id: String) -> String:
	return str(_contact_definition(contact_id).get("display_name", contact_id))


func _round_to(value: float, digits: int) -> float:
	var scale: float = pow(10.0, float(digits))
	return round(value * scale) / scale


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int((hash_value ^ text.unicode_at(index)) * 16777619)
		hash_value = hash_value % 2147483647
		if hash_value < 0:
			hash_value += 2147483647
	return str(hash_value)


func _fail(message: String) -> void:
	_failed = true
	push_error(message)
	get_tree().quit(1)
