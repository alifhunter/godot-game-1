extends Node

const RUN_SEED := 706130
const DAY_INDEX := 10
const CONSTRUCTIVE_CONTACT_ID := "journalist_dian_permatasari"
const CAUTION_CONTACT_ID := "andika_brokerage_sales"
const REFERRAL_CONTACT_ID := "journalist_raka_pradipta"
const MEETING_CONTACT_ID := "haris_construction_worker"
const SOCIAL_CONTACT_ID := "social_auditroom"
const EXPECTED_AUDIT_HASH := "805271236"
const CONTACT_NETWORK_SYSTEM_SCRIPT := preload("res://systems/ContactNetworkSystem.gd")
const JOURNAL_ROW_FIELDS := [
	"id",
	"type",
	"day_index",
	"sort_index",
	"contact_id",
	"contact_name",
	"target_company_id",
	"target_ticker",
	"status",
	"title",
	"detail",
	"source_label",
	"access_label",
	"referred_by_contact_id",
	"referred_by_contact_name",
	"referral_day_index",
	"dialog_outcome",
	"dialog_outcome_label",
	"direct_tip_direction",
	"direct_tip_entry_timing",
	"direct_tip_hold_period",
	"direct_tip_risk_note",
	"direct_tip_confidence_label"
]
const EXPECTED_JOURNAL_TYPES := [
	"social_reaction",
	"social_reaction",
	"social_reaction",
	"property_development_lead",
	"dirty_tip",
	"source_check",
	"followup",
	"tip_result",
	"tip_result",
	"dirty_tip",
	"meeting_lead",
	"twooter",
	"request",
	"twooter_discovery",
	"dirty_tip",
	"referral",
	"tip",
	"tip"
]

var _network = CONTACT_NETWORK_SYSTEM_SCRIPT.new()
var _failed := false


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	RunState.day_index = DAY_INDEX
	RunState.daily_action_day_index = DAY_INDEX
	RunState.daily_actions_used = 0
	RunState.player_portfolio["cash"] = 100000000.0

	var company_id: String = str(RunState.company_order[0]) if not RunState.company_order.is_empty() else ""
	if company_id.is_empty():
		_fail("Expected a generated company for the network audit.")
		return
	var company: Dictionary = RunState.get_company(company_id)
	var company_definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	var ticker: String = str(company_definition.get("ticker", company_id.to_upper()))
	var sector_id: String = str(company_definition.get("sector_id", ""))
	var current_price: float = max(float(company.get("current_price", 0.0)), 1.0)

	_assert_contact_exists(CONSTRUCTIVE_CONTACT_ID)
	_assert_contact_exists(CAUTION_CONTACT_ID)
	_assert_contact_exists(REFERRAL_CONTACT_ID)
	_assert_contact_exists(MEETING_CONTACT_ID)
	if _failed:
		return

	_seed_social_contact_definition(company_id, ticker, sector_id)
	_seed_network_runtime(company_id, ticker, sector_id)
	_seed_tip_journal(company_id, ticker, current_price)
	_seed_network_requests(company_id, ticker)
	_seed_property_lead()

	RunState.day_index = DAY_INDEX - 1
	var buy_result: Dictionary = RunState.buy_company(company_id, 100)
	if not bool(buy_result.get("success", false)):
		_fail("Expected audit buy to succeed: %s" % str(buy_result.get("message", "")))
		return
	RunState.day_index = DAY_INDEX
	RunState.daily_action_day_index = DAY_INDEX

	var due_results: Array = _network.process_due_tip_memories(RunState, DataRepository)
	if due_results.size() != 5:
		_fail("Expected 5 due tip/reaction results, got %d." % due_results.size())
		return
	var followup_result: Dictionary = _network.follow_up_tip(RunState, DataRepository, CONSTRUCTIVE_CONTACT_ID, "thank")
	if not bool(followup_result.get("success", false)):
		_fail("Expected constructive tip follow-up to succeed: %s" % str(followup_result.get("message", "")))
		return
	var source_check_result: Dictionary = _network.ask_source_check(RunState, DataRepository, CONSTRUCTIVE_CONTACT_ID)
	if not bool(source_check_result.get("success", false)):
		_fail("Expected constructive source check to succeed: %s" % str(source_check_result.get("message", "")))
		return

	var snapshot: Dictionary = _network.build_snapshot(RunState, DataRepository)
	var journal_rows: Array = snapshot.get("journal", []) if typeof(snapshot.get("journal", [])) == TYPE_ARRAY else []
	_assert_journal_contract(journal_rows)
	_assert_journal_type_order(journal_rows)
	if _failed:
		return

	var payload: Dictionary = _audit_payload(snapshot, company_id, ticker, current_price)
	var canonical_payload: String = JSON.stringify(payload)
	var audit_hash: String = _stable_hash(canonical_payload)
	if EXPECTED_AUDIT_HASH == "BASELINE_PENDING":
		print("NETWORK_SNAPSHOT_AUDIT_BASELINE hash=%s payload=%s" % [audit_hash, canonical_payload])
		_fail("Set EXPECTED_AUDIT_HASH in NetworkSnapshotAuditTest.gd.")
		return
	if audit_hash != EXPECTED_AUDIT_HASH:
		_fail("Network snapshot audit hash drifted. expected=%s actual=%s payload=%s" % [EXPECTED_AUDIT_HASH, audit_hash, canonical_payload])
		return

	print("NETWORK_SNAPSHOT_AUDIT_OK hash=%s contacts=%d discoveries=%d journal=%d" % [
		audit_hash,
		int(snapshot.get("met_count", 0)),
		(snapshot.get("discoveries", []) as Array).size(),
		journal_rows.size()
	])
	get_tree().quit(0)


func _seed_social_contact_definition(company_id: String, ticker: String, sector_id: String) -> void:
	var social_state: Dictionary = RunState.get_twooter_social_state()
	var definitions: Dictionary = social_state.get("network_contact_definitions", {}) if typeof(social_state.get("network_contact_definitions", {})) == TYPE_DICTIONARY else {}
	definitions[SOCIAL_CONTACT_ID] = {
		"id": SOCIAL_CONTACT_ID,
		"display_name": "Audit Room",
		"role": "Twooter Source",
		"intro": "A synthetic source used by the network snapshot audit.",
		"affiliation_type": "social",
		"affiliation_role": "public_chatter",
		"recognition_required": 0,
		"reliability": 0.61,
		"sector_ids": [sector_id],
		"categories": ["twooter", "market"],
		"source_label": "Twooter Lead",
		"source_note": "A Twooter exchange became a tracked Network contact.",
		"twooter_origin": "public_chatter",
		"source_only": true,
		"twooter_account_id": "audit_room_account",
		"twooter_handle": "@auditroom",
		"target_company_id": company_id,
		"target_ticker": ticker
	}
	social_state["network_contact_definitions"] = definitions
	RunState.set_twooter_social_state(social_state)


func _seed_network_runtime(company_id: String, ticker: String, sector_id: String) -> void:
	var contacts: Dictionary = {
		CONSTRUCTIVE_CONTACT_ID: {
			"contact_id": CONSTRUCTIVE_CONTACT_ID,
			"met": true,
			"relationship": 50,
			"met_day_index": DAY_INDEX - 5,
			"last_source_type": "news"
		},
		CAUTION_CONTACT_ID: {
			"contact_id": CAUTION_CONTACT_ID,
			"met": true,
			"relationship": 46,
			"met_day_index": DAY_INDEX - 5,
			"last_source_type": "profile"
		}
	}
	var discoveries: Dictionary = {
		CONSTRUCTIVE_CONTACT_ID: _discovery_row(CONSTRUCTIVE_CONTACT_ID, "news", "audit_news", company_id, ticker, sector_id, DAY_INDEX - 5),
		CAUTION_CONTACT_ID: _discovery_row(CAUTION_CONTACT_ID, "profile", "audit_profile", company_id, ticker, sector_id, DAY_INDEX - 5),
		REFERRAL_CONTACT_ID: _discovery_row(REFERRAL_CONTACT_ID, "referral", CONSTRUCTIVE_CONTACT_ID, company_id, ticker, sector_id, DAY_INDEX - 3),
		MEETING_CONTACT_ID: _discovery_row(MEETING_CONTACT_ID, "meeting_lead", "audit_meeting", company_id, ticker, sector_id, DAY_INDEX - 2),
		SOCIAL_CONTACT_ID: _discovery_row(SOCIAL_CONTACT_ID, "twooter", "audit_twooter_exchange", company_id, ticker, sector_id, DAY_INDEX - 2)
	}
	discoveries[REFERRAL_CONTACT_ID]["referred_by_contact_id"] = CONSTRUCTIVE_CONTACT_ID
	discoveries[REFERRAL_CONTACT_ID]["connection_score"] = 78
	discoveries[MEETING_CONTACT_ID]["meeting_id"] = "audit_rupslb"
	discoveries[SOCIAL_CONTACT_ID]["source_label"] = "Twooter Lead"
	discoveries[SOCIAL_CONTACT_ID]["source_note"] = "A Twooter exchange became a tracked Network contact."
	RunState.set_network_contacts(contacts)
	RunState.set_network_discoveries(discoveries)


func _seed_tip_journal(company_id: String, ticker: String, current_price: float) -> void:
	var journal: Dictionary = {}
	journal["audit_constructive_tip"] = {
		"id": "audit_constructive_tip",
		"contact_id": CONSTRUCTIVE_CONTACT_ID,
		"contact_name": _contact_name(CONSTRUCTIVE_CONTACT_ID),
		"target_company_id": company_id,
		"target_ticker": ticker,
		"truth_label": "Accumulation",
		"confidence_label": "Grounded read",
		"source_role": "source book",
		"tip_read": "%s looks like quiet accumulation before wider confirmation." % ticker,
		"status": "pending",
		"created_day_index": DAY_INDEX - 4,
		"resolve_day_index": DAY_INDEX,
		"baseline_price": current_price / 1.03,
		"baseline_shares": 0,
		"reaction_due_day_index": DAY_INDEX,
		"reaction_sent": false
	}
	journal["audit_caution_tip"] = {
		"id": "audit_caution_tip",
		"contact_id": CAUTION_CONTACT_ID,
		"contact_name": _contact_name(CAUTION_CONTACT_ID),
		"target_company_id": company_id,
		"target_ticker": ticker,
		"truth_label": "Distribution Risk",
		"confidence_label": "Soft read",
		"source_role": "flow desk",
		"tip_read": "%s may be crowded enough for stronger hands to sell into attention." % ticker,
		"status": "pending",
		"created_day_index": DAY_INDEX - 3,
		"resolve_day_index": DAY_INDEX,
		"baseline_price": current_price / 0.97,
		"baseline_shares": 0,
		"reaction_due_day_index": DAY_INDEX,
		"reaction_sent": false
	}
	journal["audit_twooter_check"] = {
		"id": "audit_twooter_check",
		"journal_type": "twooter_social",
		"contact_id": SOCIAL_CONTACT_ID,
		"contact_name": "Audit Room",
		"target_company_id": company_id,
		"target_ticker": ticker,
		"truth_label": "Network Source",
		"dialog_outcome_label": "Clean check-in",
		"dialog_outcome_note": "The source stayed public and narrow.",
		"confidence_label": "social",
		"source_label": "Twooter Lead",
		"source_note": "Twooter contact checked the public trail.",
		"source_only": true,
		"twooter_action_id": "message_check_in",
		"tip_read": "Kept the ask to public evidence and timing.",
		"status": "recorded",
		"created_day_index": DAY_INDEX - 2,
		"reaction_due_day_index": DAY_INDEX,
		"reaction_sent": false,
		"twooter_account_id": "audit_room_account",
		"twooter_handle": "@auditroom"
	}
	RunState.set_network_tip_journal(journal)


func _seed_network_requests(company_id: String, ticker: String) -> void:
	var requests: Dictionary = {
		"audit_request": {
			"id": "audit_request",
			"contact_id": CAUTION_CONTACT_ID,
			"target_company_id": company_id,
			"status": "pending",
			"created_day_index": DAY_INDEX - 2,
			"due_day_index": DAY_INDEX + 2,
			"relationship_delta_success": 10,
			"relationship_delta_failure": -4
		},
		"audit_dirty_tip": {
			"id": "audit_dirty_tip",
			"request_type": "dirty_tip",
			"contact_id": "operator_room",
			"contact_name": "Operator Room",
			"target_company_id": company_id,
			"target_ticker": ticker,
			"status": "caught",
			"created_day_index": DAY_INDEX - 2,
			"decision": "accepted",
			"decision_day_index": DAY_INDEX - 1,
			"resolved_day_index": DAY_INDEX,
			"outcome_label": "Caught",
			"outcome_note": "Audit dirty-tip control caught the room approach.",
			"offer_body": "Operator offered a non-public push.",
			"journal_detail": "Audit room offer preserved for journal shape.",
			"fine_amount": 1250000.0,
			"legal_days": 2
		}
	}
	RunState.set_network_requests(requests)


func _seed_property_lead() -> void:
	var life_state: Dictionary = RunState.get_player_life()
	life_state["development_leads"] = [
		{
			"id": "audit_property_lead",
			"contact_id": CONSTRUCTIVE_CONTACT_ID,
			"contact_name": _contact_name(CONSTRUCTIVE_CONTACT_ID),
			"display_location_label": "Kemang",
			"display_theme_label": "Transit",
			"theme": "transit",
			"stage": "rumor",
			"clarity_label": "Early read",
			"source_note": "A station access rumor is being tracked.",
			"discovered_day_index": DAY_INDEX
		}
	]
	RunState.set_player_life(life_state)


func _discovery_row(contact_id: String, source_type: String, source_id: String, company_id: String, ticker: String, sector_id: String, day_index: int) -> Dictionary:
	return {
		"contact_id": contact_id,
		"discovered": true,
		"source_type": source_type,
		"source_id": source_id,
		"target_company_id": company_id,
		"target_company_ids": [company_id],
		"target_ticker": ticker,
		"target_sector_id": sector_id,
		"lead_score": 80,
		"day_index": day_index
	}


func _audit_payload(snapshot: Dictionary, company_id: String, ticker: String, current_price: float) -> Dictionary:
	return {
		"company": {
			"id": company_id,
			"ticker": ticker,
			"current_price": _round_to(current_price, 2)
		},
		"recognition": _recognition_audit(snapshot.get("recognition", {})),
		"met_count": int(snapshot.get("met_count", 0)),
		"contact_cap": int(snapshot.get("contact_cap", 0)),
		"contacts": _contact_audit_rows(snapshot.get("contacts", [])),
		"discoveries": _discovery_audit_rows(snapshot.get("discoveries", [])),
		"requests": _request_audit_rows(snapshot.get("requests", [])),
		"journal": _journal_audit_rows(snapshot.get("journal", [])),
		"tips": _tip_audit_rows(RunState.get_network_tip_journal()),
		"twooter_threads": _twooter_thread_audit_rows(RunState.get_twooter_social_state())
	}


func _recognition_audit(recognition: Variant) -> Dictionary:
	var row: Dictionary = recognition if typeof(recognition) == TYPE_DICTIONARY else {}
	return {
		"score": _round_to(float(row.get("score", 0.0)), 4),
		"label": str(row.get("label", "")),
		"tier_index": int(row.get("tier_index", 0)),
		"contact_cap": int(row.get("contact_cap", 0)),
		"equity_score": _round_to(float(row.get("equity_score", 0.0)), 4),
		"ownership_score": _round_to(float(row.get("ownership_score", 0.0)), 4),
		"contact_score": _round_to(float(row.get("contact_score", 0.0)), 4)
	}


func _contact_audit_rows(source_rows: Variant) -> Array:
	var rows: Array = source_rows if typeof(source_rows) == TYPE_ARRAY else []
	var result: Array = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		result.append({
			"id": str(row.get("id", "")),
			"display_name": str(row.get("display_name", "")),
			"relationship": int(row.get("relationship", 0)),
			"last_tip_label": str(row.get("last_tip_label", "")),
			"last_tip_player_action_label": str(row.get("last_tip_player_action_label", "")),
			"last_tip_player_action_alignment": str(row.get("last_tip_player_action_alignment", "")),
			"last_tip_followup_label": str(row.get("last_tip_followup_label", "")),
			"last_reaction_label": str(row.get("last_reaction_label", "")),
			"last_development_lead_label": str(row.get("last_development_lead_label", "")),
			"access_label": str(row.get("access_label", "")),
			"provenance_label": str(row.get("provenance_label", "")),
			"referred_by_contact_name": str(row.get("referred_by_contact_name", "")),
			"referral_day_label": str(row.get("referral_day_label", "")),
			"tip_reliability_label": str(row.get("tip_reliability_label", "")),
			"tip_resolved_count": int(row.get("tip_resolved_count", 0)),
			"tip_useful_count": int(row.get("tip_useful_count", 0)),
			"tip_missed_count": int(row.get("tip_missed_count", 0)),
			"cross_contact_label": str(row.get("cross_contact_label", "")),
			"has_direct_source_conflict": bool(row.get("has_direct_source_conflict", false)),
			"can_ask_source_check": bool(row.get("can_ask_source_check", false)),
			"source_check_label": str(row.get("source_check_label", ""))
		})
	return result


func _discovery_audit_rows(source_rows: Variant) -> Array:
	var rows: Array = source_rows if typeof(source_rows) == TYPE_ARRAY else []
	var result: Array = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		result.append({
			"id": str(row.get("id", "")),
			"display_name": str(row.get("display_name", "")),
			"source_type": str(row.get("source_type", "")),
			"can_meet": bool(row.get("can_meet", false)),
			"target_ticker": str(row.get("target_ticker", "")),
			"source_label": str(row.get("source_label", "")),
			"source_note": str(row.get("source_note", "")),
			"access_label": str(row.get("access_label", "")),
			"provenance_label": str(row.get("provenance_label", "")),
			"referred_by_contact_name": str(row.get("referred_by_contact_name", "")),
			"referral_day_label": str(row.get("referral_day_label", ""))
		})
	return result


func _request_audit_rows(source_rows: Variant) -> Array:
	var rows: Array = source_rows if typeof(source_rows) == TYPE_ARRAY else []
	var result: Array = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		result.append({
			"id": str(row.get("id", "")),
			"request_type": str(row.get("request_type", "position")),
			"contact_id": str(row.get("contact_id", "")),
			"target_company_id": str(row.get("target_company_id", "")),
			"status": str(row.get("status", "")),
			"created_day_index": int(row.get("created_day_index", 0)),
			"due_day_index": int(row.get("due_day_index", 0)),
			"decision": str(row.get("decision", "")),
			"resolved_day_index": int(row.get("resolved_day_index", -1))
		})
	return result


func _journal_audit_rows(source_rows: Variant) -> Array:
	var rows: Array = source_rows if typeof(source_rows) == TYPE_ARRAY else []
	var result: Array = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		result.append({
			"id": str(row.get("id", "")),
			"type": str(row.get("type", "")),
			"day_index": int(row.get("day_index", 0)),
			"sort_index": int(row.get("sort_index", 0)),
			"contact_id": str(row.get("contact_id", "")),
			"target_ticker": str(row.get("target_ticker", "")),
			"status": str(row.get("status", "")),
			"title": str(row.get("title", "")),
			"detail": str(row.get("detail", "")),
			"source_label": str(row.get("source_label", "")),
			"access_label": str(row.get("access_label", "")),
			"referred_by_contact_name": str(row.get("referred_by_contact_name", "")),
			"referral_day_index": int(row.get("referral_day_index", -9999)),
			"dialog_outcome": str(row.get("dialog_outcome", "")),
			"direct_tip_direction": str(row.get("direct_tip_direction", "")),
			"direct_tip_entry_timing": str(row.get("direct_tip_entry_timing", "")),
			"direct_tip_hold_period": str(row.get("direct_tip_hold_period", "")),
			"direct_tip_risk_note": str(row.get("direct_tip_risk_note", "")),
			"direct_tip_confidence_label": str(row.get("direct_tip_confidence_label", ""))
		})
	return result


func _tip_audit_rows(journal: Dictionary) -> Array:
	var rows: Array = []
	for tip_value in journal.values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		rows.append({
			"id": str(tip.get("id", "")),
			"journal_type": str(tip.get("journal_type", "")),
			"contact_id": str(tip.get("contact_id", "")),
			"truth_label": str(tip.get("truth_label", "")),
			"status": str(tip.get("status", "")),
			"outcome_label": str(tip.get("outcome_label", "")),
			"player_action_label": str(tip.get("player_action_label", "")),
			"player_action_alignment": str(tip.get("player_action_alignment", "")),
			"relationship_delta": int(tip.get("relationship_delta", 0)),
			"resolved_change_pct": _round_to(float(tip.get("resolved_change_pct", 0.0)), 6),
			"followup_label": str(tip.get("followup_label", "")),
			"source_check_label": str(tip.get("source_check_label", "")),
			"reaction_label": str(tip.get("reaction_label", ""))
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("id", "")) < str(b.get("id", ""))
	)
	return rows


func _twooter_thread_audit_rows(social_state: Dictionary) -> Array:
	var messages: Dictionary = social_state.get("messages", {}) if typeof(social_state.get("messages", {})) == TYPE_DICTIONARY else {}
	var rows: Array = []
	for thread_value in messages.values():
		if typeof(thread_value) != TYPE_DICTIONARY:
			continue
		var thread: Dictionary = thread_value
		rows.append({
			"account_id": str(thread.get("account_id", "")),
			"account_handle": str(thread.get("account_handle", "")),
			"row_count": (thread.get("rows", []) as Array).size() if typeof(thread.get("rows", [])) == TYPE_ARRAY else 0,
			"unread_count": int(thread.get("unread_count", 0)),
			"last_day_index": int(thread.get("last_day_index", 0))
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("account_id", "")) < str(b.get("account_id", ""))
	)
	return rows


func _assert_journal_contract(rows: Array) -> void:
	if rows.size() != EXPECTED_JOURNAL_TYPES.size():
		_fail("Expected %d journal rows, got %d." % [EXPECTED_JOURNAL_TYPES.size(), rows.size()])
		return
	var expected_fields: Array = JOURNAL_ROW_FIELDS.duplicate()
	expected_fields.sort()
	var previous_sort_index: int = 999999
	var previous_id: String = ""
	for index in range(rows.size()):
		if typeof(rows[index]) != TYPE_DICTIONARY:
			_fail("Journal row %d is not a Dictionary." % index)
			return
		var row: Dictionary = rows[index]
		var actual_fields: Array = []
		for key_value in row.keys():
			actual_fields.append(str(key_value))
		actual_fields.sort()
		_assert_array_equal(actual_fields, expected_fields, "journal row fields %d" % index)
		var sort_index: int = int(row.get("sort_index", 0))
		var row_id: String = str(row.get("id", ""))
		if index > 0:
			if sort_index > previous_sort_index:
				_fail("Journal sort_index increased at row %d." % index)
				return
			if sort_index == previous_sort_index and row_id > previous_id:
				_fail("Journal id tie-breaker drifted at row %d." % index)
				return
		previous_sort_index = sort_index
		previous_id = row_id


func _assert_journal_type_order(rows: Array) -> void:
	var actual_types: Array = []
	for row_value in rows:
		var row: Dictionary = row_value
		actual_types.append(str(row.get("type", "")))
	_assert_array_equal(actual_types, EXPECTED_JOURNAL_TYPES, "journal type order")


func _assert_array_equal(actual: Array, expected: Array, label: String) -> void:
	if actual.size() != expected.size():
		_fail("%s size mismatch. expected=%s actual=%s" % [label, JSON.stringify(expected), JSON.stringify(actual)])
		return
	for index in range(actual.size()):
		if str(actual[index]) != str(expected[index]):
			_fail("%s mismatch at %d. expected=%s actual=%s" % [label, index, JSON.stringify(expected), JSON.stringify(actual)])
			return


func _assert_contact_exists(contact_id: String) -> void:
	if _contact_definition(contact_id).is_empty():
		_fail("Missing audit contact definition: %s" % contact_id)


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
