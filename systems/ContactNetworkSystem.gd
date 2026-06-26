extends RefCounted

const LOT_SIZE := 100
const REFERRAL_RELATIONSHIP_THRESHOLD := 45
const REFERRAL_RELATIONSHIP_COST := 10
const REFERRAL_CONNECTION_THRESHOLD := 50
const INNER_CIRCLE_REFERRAL_ROLE := "inner_circle"
const INNER_CIRCLE_REFERRAL_RECOGNITION_THRESHOLD := 90
const INNER_CIRCLE_BRIDGE_RECOGNITION_MIN := 70
const INNER_CIRCLE_BRIDGE_RECOGNITION_MAX := 90
const INNER_CIRCLE_REFERRAL_TRUST_RELATIONSHIP := 60
const TIP_RELATIONSHIP_COST := 2
const REQUEST_RELATIONSHIP_SUCCESS := 10
const REQUEST_RELATIONSHIP_FAILURE := -4
const MAX_COMPANY_LEADS_PER_FLOATER := 2
const MAX_MEETING_LEADS := 4
const MEETING_LEAD_RELATIONSHIP_BONUS := 2
const MEETING_LEAD_SOURCE_TYPE := "meeting_lead"
const TIP_MEMORY_RESOLVE_DAYS := 3
const MAX_TIP_MEMORY_ROWS := 96
const MAX_NETWORK_JOURNAL_ROWS := 18
const MAX_SOCIAL_MESSAGE_ROWS_PER_THREAD := 24
const NETWORK_TWOOTER_ACCOUNT_PREFIX := "network_"
const NETWORK_REACTION_ACTION_ID := "network_followup_reaction"
const GENERATED_DOSSIER_NETWORK_SOURCE_SYSTEM_ID := "company_story_dossier"
const GENERATED_DOSSIER_NETWORK_SURFACE_ID := "network"
const NETWORK_PRIVATE_STAGE_RECOGNIZED_RELATIONSHIP := 25
const NETWORK_PRIVATE_STAGE_TRUSTED_RELATIONSHIP := 45
const NETWORK_PRIVATE_STAGE_INNER_RELATIONSHIP := 70
const NETWORK_PRIVATE_STAGE_INNER_RECOGNITION := 70
const TRUTH_LABEL_NETWORK_READ := "Network Read"
const TRUTH_LABEL_ACCUMULATION := "Accumulation"
const TRUTH_LABEL_FILING_BACKED := "Filing-Backed"
const TRUTH_LABEL_EXECUTION_WATCH := "Execution Watch"
const TRUTH_LABEL_REAL_BUT_DELAYED := "Real But Delayed"
const TRUTH_LABEL_ROOM_RISK := "Room Risk"
const TRUTH_LABEL_EARLY_READ := "Early Read"
const TRUTH_LABEL_DISTRIBUTION_RISK := "Distribution Risk"
const TRUTH_LABEL_RETAIL_TRAP := "Retail Trap"
const TRUTH_LABEL_DEAD_STORY := "Dead Story"
const TRUTH_LABEL_PRESSURE_READ := "Pressure Read"
const CONSTRUCTIVE_TRUTH_LABELS := [
	TRUTH_LABEL_ACCUMULATION,
	TRUTH_LABEL_FILING_BACKED,
	TRUTH_LABEL_EXECUTION_WATCH,
	TRUTH_LABEL_NETWORK_READ
]
const TIMING_RISK_TRUTH_LABELS := [
	TRUTH_LABEL_REAL_BUT_DELAYED,
	TRUTH_LABEL_ROOM_RISK,
	TRUTH_LABEL_EARLY_READ
]
const CAUTIONARY_TRUTH_LABELS := [
	TRUTH_LABEL_DISTRIBUTION_RISK,
	TRUTH_LABEL_RETAIL_TRAP,
	TRUTH_LABEL_DEAD_STORY,
	TRUTH_LABEL_PRESSURE_READ
]
const OUTCOME_LABEL_USEFUL_READ := "Useful read"
const OUTCOME_LABEL_USEFUL_WARNING := "Useful warning"
const OUTCOME_LABEL_USEFUL_TIMING_READ := "Useful timing read"
const OUTCOME_LABEL_EARLY_NOT_WRONG := "Early, not wrong"
const OUTCOME_LABEL_TOO_EARLY := "Too early"
const OUTCOME_LABEL_MISSED_BADLY := "Missed badly"
const OUTCOME_LABEL_STILL_PENDING := "Still pending"
const GOOD_OUTCOME_LABELS := [
	OUTCOME_LABEL_USEFUL_READ,
	OUTCOME_LABEL_USEFUL_WARNING,
	OUTCOME_LABEL_USEFUL_TIMING_READ,
	OUTCOME_LABEL_EARLY_NOT_WRONG
]
const TIP_STATUS_PENDING := "pending"
const TIP_STATUS_RESOLVED := "resolved"
const TIP_STATUS_UNRESOLVED := "unresolved"
const DISCOVERY_STATUS_DISCOVERED := "discovered"
const REQUEST_STATUS_COMPLETED := "completed"
const REQUEST_STATUS_MISSED := "missed"
const DIRTY_TIP_STATUS_OFFERED := "offered"
const DIRTY_TIP_STATUS_CAUGHT := "caught"
const DIRTY_TIP_STATUS_RESOLVED_CLEAN := "resolved_clean"
const MEETING_LEAD_STATUS_MET := "met"
const REQUEST_TYPE_DIRTY_TIP := "dirty_tip"
const TIP_JOURNAL_TYPE_TWOOTER_SOCIAL := "twooter_social"
const STANCE_CONSTRUCTIVE := "constructive"
const STANCE_CAUTION := "caution"
const STANCE_TIMING_RISK := "timing_risk"
const STANCE_UNCERTAIN := "uncertain"
const RELATIONSHIP_GRAPH_SOURCE_SYSTEM_ID := "company_relationship_graph"
const LAST_TIP_NOTE_FIELD_MAP := [
	{"target": "last_tip_status", "source": "status", "default": "", "type": "string"},
	{"target": "last_tip_label", "source": "outcome_label", "default": "", "type": "string"},
	{"target": "last_tip_note", "source": "outcome_note", "default": "", "type": "string"},
	{"target": "last_tip_player_action_label", "source": "player_action_label", "default": "", "type": "string"},
	{"target": "last_tip_player_action_alignment", "source": "player_action_alignment", "default": "", "type": "string"},
	{"target": "last_tip_day_index", "source": "resolved_day_index", "default": 0, "type": "int"},
	{"target": "last_tip_followup_id", "source": "followup_id", "default": "", "type": "string"},
	{"target": "last_tip_followup_label", "source": "followup_label", "default": "", "type": "string"},
	{"target": "last_tip_followup_note", "source": "followup_note", "default": "", "type": "string"},
	{"target": "can_follow_up_tip", "method": "_decorator_tip_can_follow_up", "default": false, "type": "bool"},
	{"target": "tip_followup_options", "method": "_decorator_tip_followup_options", "default": [], "type": "array_duplicate"}
]
const TIP_HISTORY_FIELD_MAP := [
	{"target": "tip_history", "source": "rows", "default": [], "type": "array_duplicate"},
	{"target": "tip_reliability_label", "source": "reliability_label", "default": "No track record yet", "type": "string"},
	{"target": "tip_reliability_score", "source": "reliability_score", "default": 50.0, "type": "float"},
	{"target": "tip_resolved_count", "source": "resolved_count", "default": 0, "type": "int"},
	{"target": "tip_useful_count", "source": "useful_count", "default": 0, "type": "int"},
	{"target": "tip_missed_count", "source": "missed_count", "default": 0, "type": "int"}
]
const TIP_HISTORY_DEFAULTS := [
	{"target": "tip_history", "value": []},
	{"target": "tip_reliability_label", "value": "No track record yet"},
	{"target": "tip_reliability_score", "value": 50.0},
	{"target": "tip_resolved_count", "value": 0},
	{"target": "tip_useful_count", "value": 0},
	{"target": "tip_missed_count", "value": 0}
]
const LATEST_REACTION_FIELD_MAP := [
	{"target": "last_reaction_label", "source": "reaction_label", "default": "", "type": "string"},
	{"target": "last_reaction_note", "source": "reaction_note", "default": "", "type": "string"},
	{"target": "last_reaction_day_index", "source": "reaction_day_index", "default": 0, "type": "int"},
	{"target": "last_reaction_twooter_account_id", "source": "reaction_twooter_account_id", "default": "", "type": "string"},
	{"target": "last_reaction_twooter_handle", "source": "reaction_twooter_handle", "default": "", "type": "string"}
]
const LATEST_REACTION_DEFAULTS := [
	{"target": "last_reaction_label", "value": ""},
	{"target": "last_reaction_note", "value": ""},
	{"target": "last_reaction_day_index", "value": 0},
	{"target": "last_reaction_twooter_account_id", "value": ""},
	{"target": "last_reaction_twooter_handle", "value": ""}
]
const DEVELOPMENT_LEAD_FIELD_MAP := [
	{"target": "last_development_lead_id", "source": "id", "default": "", "type": "string"},
	{"target": "last_development_lead_label", "method": "_decorator_development_lead_label", "default": "", "type": "string"},
	{"target": "last_development_lead_note", "method": "_decorator_development_lead_note", "default": "", "type": "string"},
	{"target": "last_development_lead_location", "method": "_decorator_development_lead_location", "default": "", "type": "string"},
	{"target": "last_development_lead_day_index", "source": "discovered_day_index", "default": 0, "type": "int"}
]
const DEVELOPMENT_LEAD_DEFAULTS := [
	{"target": "last_development_lead_id", "value": ""},
	{"target": "last_development_lead_label", "value": ""},
	{"target": "last_development_lead_note", "value": ""},
	{"target": "last_development_lead_location", "value": ""},
	{"target": "last_development_lead_day_index", "value": 0}
]
const CROSS_CONTACT_FIELD_MAP := [
	{"target": "cross_contact_label", "source": "label", "default": "Mixed sources", "type": "string"},
	{"target": "cross_contact_note", "source": "note", "default": "", "type": "string"},
	{"target": "cross_contact_rows", "source": "rows", "default": [], "type": "array_duplicate"},
	{"target": "has_direct_source_conflict", "source": "has_direct_source_conflict", "default": false, "type": "bool"},
	{"target": "can_ask_source_check", "source": "can_ask_source_check", "default": false, "type": "bool"},
	{"target": "source_check_label", "source": "source_check_label", "default": "", "type": "string"},
	{"target": "source_check_note", "source": "source_check_note", "default": "", "type": "string"},
	{"target": "source_check_day_index", "source": "source_check_day_index", "default": 0, "type": "int"}
]
const CROSS_CONTACT_DEFAULTS := [
	{"target": "cross_contact_label", "value": ""},
	{"target": "cross_contact_note", "value": ""},
	{"target": "cross_contact_rows", "value": []},
	{"target": "has_direct_source_conflict", "value": false},
	{"target": "can_ask_source_check", "value": false},
	{"target": "source_check_label", "value": ""},
	{"target": "source_check_note", "value": ""},
	{"target": "source_check_day_index", "value": 0}
]
var trading_calendar = preload("res://systems/TradingCalendar.gd").new()
const STABLE_RNG = preload("res://systems/StableRng.gd")
const NETWORK_CONTACT_PRESENTER_SCRIPT := preload("res://systems/NetworkContactPresenter.gd")
const NETWORK_JOURNAL_BUILDER_SCRIPT := preload("res://systems/NetworkJournalBuilder.gd")
const NETWORK_TIP_RESOLVER_SCRIPT := preload("res://systems/NetworkTipResolver.gd")
const NETWORK_DISCOVERY_SCRIPT := preload("res://systems/NetworkDiscovery.gd")


func build_snapshot(run_state, data_repository) -> Dictionary:
	var contacts: Dictionary = run_state.get_network_contacts()
	var discoveries: Dictionary = run_state.get_network_discoveries()
	var requests: Dictionary = run_state.get_network_requests()
	var recognition: Dictionary = build_recognition_snapshot(run_state)
	var last_tip_notes: Dictionary = _last_tip_notes_by_contact(run_state)
	var tip_histories: Dictionary = _tip_histories_by_contact(run_state)
	var reaction_notes: Dictionary = _latest_reaction_notes_by_contact(run_state)
	var development_lead_notes: Dictionary = _latest_development_leads_by_contact(run_state)
	var cross_checks: Dictionary = _cross_contact_reads_by_contact(run_state)
	var contact_rows: Array = []
	var discovered_rows: Array = []

	for contact_value in data_repository.get_contact_network_data().get("contacts", []):
		var contact: Dictionary = contact_value
		var contact_id: String = str(contact.get("id", ""))
		if contact_id.is_empty():
			continue
		if str(contact.get("affiliation_type", "floater")) == "insider_template":
			continue
		var runtime: Dictionary = contacts.get(contact_id, {})
		var discovery: Dictionary = discoveries.get(contact_id, {})
		if _is_referral_required_contact(contact) and not _inner_circle_contact_is_unlocked(runtime, discovery):
			continue
		var row: Dictionary = _contact_row(contact, runtime, discovery, recognition)
		_apply_access_provenance(row, contact, discovery, run_state, data_repository)
		_apply_last_tip_note(row, last_tip_notes)
		_apply_tip_history(row, tip_histories)
		_apply_latest_reaction(row, reaction_notes)
		_apply_latest_development_lead(row, development_lead_notes)
		_apply_cross_contact_read(row, cross_checks)
		if bool(runtime.get("met", false)):
			contact_rows.append(row)
		elif bool(discovery.get("discovered", false)):
			discovered_rows.append(row)

	var generated_contact_ids := {}
	for contact_id_value in contacts.keys():
		var contact_id: String = str(contact_id_value)
		if contact_id.begins_with("insider_") or contact_id.begins_with("social_"):
			generated_contact_ids[contact_id] = true
	for contact_id_value in discoveries.keys():
		var contact_id: String = str(contact_id_value)
		if contact_id.begins_with("insider_") or contact_id.begins_with("social_"):
			generated_contact_ids[contact_id] = true
	for generated_contact_id_value in generated_contact_ids.keys():
		var generated_contact_id: String = str(generated_contact_id_value)
		var generated_contact: Dictionary = _contact_definition(run_state, data_repository, generated_contact_id)
		if generated_contact.is_empty():
			continue
		var runtime: Dictionary = contacts.get(generated_contact_id, {})
		var discovery: Dictionary = discoveries.get(generated_contact_id, {})
		if _is_referral_required_contact(generated_contact) and not _inner_circle_contact_is_unlocked(runtime, discovery):
			continue
		var row: Dictionary = _contact_row(generated_contact, runtime, discovery, recognition)
		_apply_access_provenance(row, generated_contact, discovery, run_state, data_repository)
		_apply_last_tip_note(row, last_tip_notes)
		_apply_tip_history(row, tip_histories)
		_apply_latest_reaction(row, reaction_notes)
		_apply_latest_development_lead(row, development_lead_notes)
		_apply_cross_contact_read(row, cross_checks)
		if bool(runtime.get("met", false)):
			contact_rows.append(row)
		elif bool(discovery.get("discovered", false)):
			discovered_rows.append(row)

	contact_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("display_name", "")) < str(b.get("display_name", ""))
	)
	discovered_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("display_name", "")) < str(b.get("display_name", ""))
	)

	return {
		"recognition": recognition,
		"contacts": contact_rows,
		"discoveries": discovered_rows,
		"requests": _request_rows(requests),
		"journal": _network_journal_rows(run_state, data_repository, requests, discoveries),
		"met_count": contact_rows.size(),
		"contact_cap": int(recognition.get("contact_cap", 2))
	}


func build_twooter_accounts(run_state, data_repository) -> Array:
	var rows: Array = []
	var seen: Dictionary = {}
	for contact_value in _all_contact_definitions(run_state, data_repository):
		if typeof(contact_value) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = contact_value
		var contact_id: String = str(contact.get("id", contact.get("contact_id", "")))
		var affiliation_type: String = str(contact.get("affiliation_type", "floater"))
		if affiliation_type == "insider_template" or affiliation_type == "social":
			continue
		var discovery: Dictionary = run_state.get_network_discoveries().get(contact_id, {}) if not contact_id.is_empty() else {}
		var runtime: Dictionary = run_state.get_network_contacts().get(contact_id, {}) if not contact_id.is_empty() else {}
		if _is_referral_required_contact(contact) and not _inner_circle_contact_is_unlocked(runtime, discovery):
			continue
		var account: Dictionary = _contact_twooter_account(contact, discovery, run_state)
		var account_id: String = str(account.get("id", ""))
		if account_id.is_empty() or seen.has(account_id):
			continue
		seen[account_id] = true
		rows.append(account)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("display_name", "")) < str(b.get("display_name", ""))
	)
	return rows


func count_current_day_activity(run_state) -> int:
	var target_day_index: int = int(run_state.day_index)
	var count: int = 0
	for tip_value in run_state.get_network_tip_journal().values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		if int(tip.get("created_day_index", 0)) == target_day_index:
			count += 1
		if str(tip.get("status", TIP_STATUS_PENDING)) != TIP_STATUS_PENDING and int(tip.get("resolved_day_index", tip.get("created_day_index", 0))) == target_day_index:
			count += 1
		if not str(tip.get("followup_note", "")).is_empty() and int(tip.get("followup_day_index", tip.get("resolved_day_index", tip.get("created_day_index", 0)))) == target_day_index:
			count += 1
		if not str(tip.get("source_check_note", "")).is_empty() and int(tip.get("source_check_day_index", tip.get("created_day_index", 0))) == target_day_index:
			count += 1
	for request_value in run_state.get_network_requests().values():
		if typeof(request_value) != TYPE_DICTIONARY:
			continue
		var request: Dictionary = request_value
		if str(request.get("request_type", "")) == REQUEST_TYPE_DIRTY_TIP:
			if int(request.get("created_day_index", -9999)) == target_day_index:
				count += 1
			if not str(request.get("decision", "")).is_empty() and int(request.get("decision_day_index", -9999)) == target_day_index:
				count += 1
			if int(request.get("resolved_day_index", -9999)) == target_day_index:
				count += 1
			continue
		var status: String = str(request.get("status", TIP_STATUS_PENDING))
		var request_day_index: int = int(request.get("completed_day_index", request.get("created_day_index", 0))) if status != TIP_STATUS_PENDING else int(request.get("created_day_index", 0))
		if request_day_index == target_day_index:
			count += 1
	for discovery_value in run_state.get_network_discoveries().values():
		if typeof(discovery_value) != TYPE_DICTIONARY:
			continue
		var discovery: Dictionary = discovery_value
		if str(discovery.get("source_type", "")) == "referral" and int(discovery.get("day_index", 0)) == target_day_index:
			count += 1
		if str(discovery.get("source_type", "")) == MEETING_LEAD_SOURCE_TYPE and int(discovery.get("day_index", 0)) == target_day_index:
			count += 1
	return count


func build_recognition_snapshot(run_state) -> Dictionary:
	var starting_cash: float = max(float(run_state.get_difficulty_config().get("starting_cash", 1.0)), 1.0)
	var equity: float = max(run_state.get_total_equity(), 0.0)
	var equity_ratio: float = clamp((equity - starting_cash) / starting_cash, 0.0, 1.0)
	var equity_score: float = equity_ratio * 40.0

	var holdings: Dictionary = run_state.player_portfolio.get("holdings", {})
	var held_company_count: int = 0
	for holding_value in holdings.values():
		var holding: Dictionary = holding_value
		if int(holding.get("shares", 0)) >= LOT_SIZE:
			held_company_count += 1
	var exposure_ratio: float = 0.0
	if equity > 0.0:
		exposure_ratio = clamp(run_state.get_portfolio_market_value() / equity, 0.0, 1.0)
	var ownership_score: float = clamp(float(held_company_count) / 6.0, 0.0, 1.0) * 15.0 + exposure_ratio * 15.0

	var met_count: int = 0
	for runtime_value in run_state.get_network_contacts().values():
		var runtime: Dictionary = runtime_value
		if bool(runtime.get("met", false)):
			met_count += 1
	var contact_score: float = clamp(float(met_count) / 8.0, 0.0, 1.0) * 30.0
	var score: float = clamp(equity_score + ownership_score + contact_score, 0.0, 100.0)
	var tier: Dictionary = _recognition_tier(score)
	return {
		"score": score,
		"label": str(tier.get("label", "Unknown")),
		"tier_index": int(tier.get("tier_index", 0)),
		"contact_cap": int(tier.get("contact_cap", 2)),
		"equity_score": equity_score,
		"ownership_score": ownership_score,
		"contact_score": contact_score
	}


func discover_from_article(run_state, data_repository, article: Dictionary) -> Array:
	var company_id: String = str(article.get("target_company_id", ""))
	var sector_id: String = str(article.get("target_sector_id", ""))
	var discovered: Array = _discover_matching_contacts(
		run_state,
		data_repository,
		company_id,
		sector_id,
		str(article.get("category", "")),
		"news",
		str(article.get("id", "")),
		true
	)
	var author_contact_id: String = str(article.get("author_contact_id", ""))
	if not author_contact_id.is_empty():
		discovered.append_array(_discover_article_author_contact(
			run_state,
			data_repository,
			author_contact_id,
			company_id,
			sector_id,
			str(article.get("category", "")),
			str(article.get("id", ""))
		))
	return discovered


func discover_for_company(run_state, data_repository, company_id: String) -> Array:
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	if definition.is_empty():
		return []
	return _discover_matching_contacts(
		run_state,
		data_repository,
		company_id,
		str(definition.get("sector_id", "")),
		"company",
		"profile",
		company_id,
		false
	)


func decorate_meeting_session_snapshot(
	run_state,
	data_repository,
	session_snapshot: Dictionary,
	can_spend_meet_action: bool,
	meet_action_cost: int
) -> Dictionary:
	if session_snapshot.is_empty():
		return {}
	var decorated_snapshot: Dictionary = session_snapshot.duplicate(true)
	var meeting_id: String = str(decorated_snapshot.get("meeting_id", ""))
	if meeting_id.is_empty():
		return decorated_snapshot
	var leads: Array = _ensure_meeting_leads(run_state, data_repository, decorated_snapshot)
	var sessions: Dictionary = run_state.get_corporate_meeting_sessions()
	var session: Dictionary = sessions.get(meeting_id, decorated_snapshot.get("session", {})).duplicate(true)
	decorated_snapshot["session"] = session
	var lead_rows: Array = []
	for lead_value in leads:
		if typeof(lead_value) != TYPE_DICTIONARY:
			continue
		lead_rows.append(_meeting_lead_public_row(
			run_state,
			data_repository,
			decorated_snapshot,
			lead_value,
			can_spend_meet_action,
			meet_action_cost
		))
	decorated_snapshot["meeting_leads"] = lead_rows
	return decorated_snapshot


func approach_meeting_lead(
	run_state,
	data_repository,
	session_snapshot: Dictionary,
	lead_id: String,
	can_spend_meet_action: bool,
	meet_action_cost: int
) -> Dictionary:
	if session_snapshot.is_empty():
		return {"success": false, "message": "Meeting session not available."}
	var meeting_id: String = str(session_snapshot.get("meeting_id", ""))
	if meeting_id.is_empty():
		return {"success": false, "message": "Meeting session not available."}
	var decorated_snapshot: Dictionary = decorate_meeting_session_snapshot(
		run_state,
		data_repository,
		session_snapshot,
		can_spend_meet_action,
		meet_action_cost
	)
	var selected_lead: Dictionary = {}
	for lead_value in decorated_snapshot.get("meeting_leads", []):
		if typeof(lead_value) != TYPE_DICTIONARY:
			continue
		var lead: Dictionary = lead_value
		if str(lead.get("lead_id", "")) == lead_id:
			selected_lead = lead
			break
	if selected_lead.is_empty():
		return {"success": false, "message": "That meeting lead is no longer available."}
	if bool(selected_lead.get("approached", false)):
		return {
			"success": false,
			"message": "You already approached this attendee.",
			"lead": selected_lead
		}
	if not bool(selected_lead.get("approachable", false)):
		return {
			"success": false,
			"message": str(selected_lead.get("locked_reason", "This attendee is not approachable right now.")),
			"lead": selected_lead
		}

	var contact_id: String = str(selected_lead.get("contact_id", ""))
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	if contact.is_empty():
		return {"success": false, "message": "Unknown meeting contact."}
	var meeting: Dictionary = decorated_snapshot.get("meeting", {})
	var session: Dictionary = decorated_snapshot.get("session", {}).duplicate(true)
	var company_id: String = str(selected_lead.get("company_id", meeting.get("company_id", "")))
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	var contact_was_met: bool = _is_met(run_state, contact_id)
	_record_meeting_lead_discovery(run_state, contact, selected_lead, meeting_id, company_id, definition)
	if contact_was_met:
		_adjust_relationship(run_state, contact_id, MEETING_LEAD_RELATIONSHIP_BONUS)
	else:
		_mark_meeting_contact_met(run_state, data_repository, contact, selected_lead)
	var response_text: String = _meeting_lead_response_text(
		selected_lead,
		contact,
		meeting,
		definition,
		meeting_id
	)
	_mark_contact_meeting_note(run_state, contact_id, response_text)

	var approached_ids: Array = session.get("approached_lead_ids", []).duplicate(true)
	if not approached_ids.has(lead_id):
		approached_ids.append(lead_id)
	var results: Dictionary = session.get("meeting_lead_results", {}).duplicate(true)
	results[lead_id] = {
		"lead_id": lead_id,
		"contact_id": contact_id,
		"contact_name": str(contact.get("display_name", "Contact")),
		"response_text": response_text,
		"relationship_delta": MEETING_LEAD_RELATIONSHIP_BONUS if contact_was_met else 0,
		"met_contact": not contact_was_met,
		"day_index": run_state.day_index
	}
	session["approached_lead_ids"] = approached_ids
	session["meeting_lead_results"] = results
	session["last_updated_day_index"] = run_state.day_index
	var sessions: Dictionary = run_state.get_corporate_meeting_sessions()
	sessions[meeting_id] = session
	run_state.set_corporate_meeting_sessions(sessions)

	var refreshed_snapshot: Dictionary = decorate_meeting_session_snapshot(
		run_state,
		data_repository,
		session_snapshot,
		can_spend_meet_action,
		meet_action_cost
	)
	var refreshed_lead: Dictionary = selected_lead
	for lead_value in refreshed_snapshot.get("meeting_leads", []):
		if typeof(lead_value) == TYPE_DICTIONARY and str(lead_value.get("lead_id", "")) == lead_id:
			refreshed_lead = lead_value
			break
	var result_message: String = "%s is now in your Network." % str(contact.get("display_name", "Contact"))
	if contact_was_met:
		result_message = "%s shared a quick meeting read." % str(contact.get("display_name", "Contact"))
	return {
		"success": true,
		"message": result_message,
		"lead": refreshed_lead,
		"contact_id": contact_id,
		"response_text": response_text,
		"met_contact": not contact_was_met
	}


func meet_contact(run_state, data_repository, contact_id: String, source_context: Dictionary = {}) -> Dictionary:
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	if contact.is_empty():
		return {"success": false, "message": "Unknown contact."}
	var recognition: Dictionary = build_recognition_snapshot(run_state)
	var contacts: Dictionary = run_state.get_network_contacts()
	var discoveries: Dictionary = run_state.get_network_discoveries()
	var runtime: Dictionary = contacts.get(contact_id, {})
	if bool(runtime.get("met", false)):
		return {"success": false, "message": "%s is already in your network." % str(contact.get("display_name", "Contact"))}
	if not bool(discoveries.get(contact_id, {}).get("discovered", false)):
		return {"success": false, "message": "You have not discovered that contact yet."}
	var has_warm_referral: bool = str(discoveries.get(contact_id, {}).get("source_type", "")) == "referral"
	if not has_warm_referral and int(recognition.get("score", 0)) < int(contact.get("recognition_required", 0)):
		return {"success": false, "message": "Your recognition is not high enough yet."}
	var met_count: int = 0
	for runtime_value in contacts.values():
		var existing_runtime: Dictionary = runtime_value
		if bool(existing_runtime.get("met", false)):
			met_count += 1
	if met_count >= int(recognition.get("contact_cap", 2)):
		return {"success": false, "message": "Your network is full for this recognition tier."}

	runtime["contact_id"] = contact_id
	runtime["met"] = true
	runtime["relationship"] = int(contact.get("base_relationship", data_repository.get_contact_network_data().get("relationship_default", 25)))
	runtime["met_day_index"] = run_state.day_index
	runtime["last_source_type"] = str(source_context.get("source_type", "network"))
	contacts[contact_id] = runtime
	run_state.set_network_contacts(contacts)
	return {"success": true, "message": "Met %s." % str(contact.get("display_name", "Contact")), "contact": runtime.duplicate(true)}


func request_tip(run_state, data_repository, corporate_action_system, contact_id: String, company_id: String = "") -> Dictionary:
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	if contact.is_empty():
		return {"success": false, "message": "Unknown contact."}
	if not _is_met(run_state, contact_id):
		return {"success": false, "message": "Meet this contact first."}
	var runtime: Dictionary = run_state.get_network_contacts().get(contact_id, {})
	if int(runtime.get("last_tip_request_day_index", -9999)) == run_state.day_index:
		return {"success": false, "message": "You already asked this contact for a read today. Let the tape breathe until tomorrow."}
	var resolved_company_id: String = _resolve_target_company_id(run_state, data_repository, contact_id, company_id)
	if resolved_company_id.is_empty():
		return {"success": false, "message": "No target company is available for that tip."}
	var generated_relationship_tip_result: Dictionary = _generated_relationship_network_tip_result(
		run_state,
		data_repository,
		contact,
		contact_id,
		resolved_company_id
	)
	if bool(generated_relationship_tip_result.get("success", false)):
		_adjust_relationship(run_state, contact_id, -TIP_RELATIONSHIP_COST)
		_mark_contact_day_flag(run_state, contact_id, "last_tip_request_day_index")
		generated_relationship_tip_result["contact_id"] = contact_id
		generated_relationship_tip_result["target_company_id"] = resolved_company_id
		_record_tip_memory(run_state, contact, resolved_company_id, generated_relationship_tip_result)
		return generated_relationship_tip_result
	var generated_dossier_tip_result: Dictionary = _generated_dossier_network_tip_result(
		run_state,
		data_repository,
		contact,
		contact_id,
		resolved_company_id
	)
	if bool(generated_dossier_tip_result.get("success", false)):
		_adjust_relationship(run_state, contact_id, -TIP_RELATIONSHIP_COST)
		_mark_contact_day_flag(run_state, contact_id, "last_tip_request_day_index")
		generated_dossier_tip_result["contact_id"] = contact_id
		generated_dossier_tip_result["target_company_id"] = resolved_company_id
		_record_tip_memory(run_state, contact, resolved_company_id, generated_dossier_tip_result)
		return generated_dossier_tip_result
	var intel_result: Dictionary = corporate_action_system.request_contact_tip_intel(
		run_state,
		data_repository,
		contact,
		resolved_company_id
	)
	if bool(intel_result.get("success", false)):
		_adjust_relationship(run_state, contact_id, -TIP_RELATIONSHIP_COST)
		_mark_contact_day_flag(run_state, contact_id, "last_tip_request_day_index")
		var decorated_intel_result: Dictionary = _decorate_tip_result(
			run_state,
			data_repository,
			contact,
			resolved_company_id,
			intel_result
		)
		decorated_intel_result["contact_id"] = contact_id
		decorated_intel_result["target_company_id"] = resolved_company_id
		_record_tip_memory(run_state, contact, resolved_company_id, decorated_intel_result)
		return decorated_intel_result
	var build_result: Dictionary = _build_and_store_contact_arc(run_state, data_repository, contact_id, resolved_company_id, "tip")
	if not bool(build_result.get("success", false)):
		return build_result
	_adjust_relationship(run_state, contact_id, -TIP_RELATIONSHIP_COST)
	_mark_contact_day_flag(run_state, contact_id, "last_tip_request_day_index")
	var decorated_build_result: Dictionary = _decorate_contact_arc_tip_result(run_state, data_repository, contact, resolved_company_id, build_result)
	_record_tip_memory(run_state, contact, resolved_company_id, decorated_build_result)
	return decorated_build_result


func accept_request(run_state, data_repository, contact_id: String, company_id: String = "") -> Dictionary:
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	if contact.is_empty():
		return {"success": false, "message": "Unknown contact."}
	if not _is_met(run_state, contact_id):
		return {"success": false, "message": "Meet this contact first."}
	var resolved_company_id: String = _resolve_target_company_id(run_state, data_repository, contact_id, company_id)
	if resolved_company_id.is_empty():
		return {"success": false, "message": "No target company is available for that request."}
	if _has_pending_request(run_state, contact_id, resolved_company_id):
		return {"success": false, "message": "%s already has a pending position request on that stock." % str(contact.get("display_name", "Contact"))}
	var request_id: String = "%s|%s|%d" % [contact_id, resolved_company_id, run_state.day_index]
	var requests: Dictionary = run_state.get_network_requests()
	var request: Dictionary = {
		"id": request_id,
		"contact_id": contact_id,
		"target_company_id": resolved_company_id,
		"status": "pending",
		"created_day_index": run_state.day_index,
		"due_day_index": run_state.day_index + 3,
		"relationship_delta_success": REQUEST_RELATIONSHIP_SUCCESS,
		"relationship_delta_failure": REQUEST_RELATIONSHIP_FAILURE
	}
	requests[request_id] = request
	run_state.set_network_requests(requests)
	return {
		"success": true,
		"message": "%s gave you a position request. Hold at least 1 lot by %s for +%d relationship, or miss it for %d." % [
			str(contact.get("display_name", "Contact")),
			_request_due_date_text(request),
			REQUEST_RELATIONSHIP_SUCCESS,
			REQUEST_RELATIONSHIP_FAILURE
		],
		"request_id": request_id,
		"relationship_delta_success": REQUEST_RELATIONSHIP_SUCCESS,
		"relationship_delta_failure": REQUEST_RELATIONSHIP_FAILURE
	}


func request_referral(run_state, data_repository, contact_id: String, company_id: String = "", affiliation_role: String = "") -> Dictionary:
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	if contact.is_empty():
		return {"success": false, "message": "Unknown contact."}
	if str(contact.get("affiliation_type", "floater")) != "floater":
		return {"success": false, "message": "Only floaters can introduce company insiders."}
	if not _is_met(run_state, contact_id):
		return {"success": false, "message": "Meet this contact first."}
	var relationship: int = int(run_state.get_network_contacts().get(contact_id, {}).get("relationship", 0))
	if relationship < REFERRAL_RELATIONSHIP_THRESHOLD:
		return {"success": false, "message": "Relationship must reach %d before asking for referrals." % REFERRAL_RELATIONSHIP_THRESHOLD}
	if int(run_state.get_network_contacts().get(contact_id, {}).get("last_referral_day_index", -9999)) == run_state.day_index:
		return {"success": false, "message": "You already asked this contact for an introduction today."}

	var target_company_id: String = company_id
	if target_company_id.is_empty():
		target_company_id = _resolve_target_company_id(run_state, data_repository, contact_id, company_id)
	if affiliation_role == INNER_CIRCLE_REFERRAL_ROLE:
		return _request_inner_circle_referral(run_state, data_repository, contact, contact_id, target_company_id)
	var insider: Dictionary = _best_referral_insider(run_state, contact_id, target_company_id, affiliation_role)
	if insider.is_empty():
		return {"success": false, "message": "No connected insider referral is available for that company."}

	var insider_id: String = str(insider.get("id", insider.get("contact_id", "")))
	var connection_score: int = _connection_score_for_floater(insider, contact_id)
	if connection_score < REFERRAL_CONNECTION_THRESHOLD:
		return {"success": false, "message": "This contact is not close enough to that insider."}

	var discoveries: Dictionary = run_state.get_network_discoveries()
	discoveries[insider_id] = {
		"contact_id": insider_id,
		"discovered": true,
		"source_type": "referral",
		"source_id": contact_id,
		"referred_by_contact_id": contact_id,
		"referral_day_index": run_state.day_index,
		"target_company_id": str(insider.get("affiliated_company_id", insider.get("company_id", ""))),
		"target_company_ids": [str(insider.get("affiliated_company_id", insider.get("company_id", "")))],
		"target_sector_id": str(insider.get("sector_id", "")),
		"connection_score": connection_score,
		"day_index": run_state.day_index
	}
	run_state.set_network_discoveries(discoveries)
	_adjust_relationship(run_state, contact_id, -REFERRAL_RELATIONSHIP_COST)
	_mark_contact_day_flag(run_state, contact_id, "last_referral_day_index")
	return {
		"success": true,
		"message": "%s introduced you to %s." % [
			str(contact.get("display_name", "Contact")),
			str(insider.get("display_name", "an insider"))
		],
		"contact_id": insider_id
	}


func _request_inner_circle_referral(run_state, data_repository, bridge_contact: Dictionary, bridge_contact_id: String, target_company_id: String) -> Dictionary:
	var bridge_runtime: Dictionary = run_state.get_network_contacts().get(bridge_contact_id, {})
	if not _is_inner_circle_referral_bridge(bridge_contact):
		return {"success": false, "message": "Only high-recognition bridge contacts can make inner-circle introductions."}
	if not _has_inner_circle_referral_trust_signal(bridge_runtime):
		return {"success": false, "message": "Build a stronger recent track record before asking for an inner-circle introduction."}
	var referred_contact: Dictionary = _best_inner_circle_referral_contact(run_state, data_repository, bridge_contact, bridge_contact_id, target_company_id)
	if referred_contact.is_empty():
		return {"success": false, "message": "No private inner-circle referral is available for that context."}

	var referred_contact_id: String = str(referred_contact.get("id", referred_contact.get("contact_id", "")))
	var definition: Dictionary = run_state.get_effective_company_definition(target_company_id, false, false)
	var target_sector_id: String = str(definition.get("sector_id", referred_contact.get("sector_id", "")))
	var target_ticker: String = str(definition.get("ticker", target_company_id.to_upper()))
	var connection_score: int = _inner_circle_referral_score(referred_contact, bridge_contact, target_sector_id)
	if connection_score < REFERRAL_CONNECTION_THRESHOLD:
		return {"success": false, "message": "This contact is not close enough to make that private introduction."}

	var discoveries: Dictionary = run_state.get_network_discoveries()
	discoveries[referred_contact_id] = {
		"contact_id": referred_contact_id,
		"discovered": true,
		"source_type": "referral",
		"source_id": bridge_contact_id,
		"referred_by_contact_id": bridge_contact_id,
		"referral_day_index": run_state.day_index,
		"privacy_gate": INNER_CIRCLE_REFERRAL_ROLE,
		"referral_required": true,
		"target_company_id": target_company_id,
		"target_company_ids": [target_company_id],
		"target_ticker": target_ticker,
		"target_sector_id": target_sector_id,
		"connection_score": connection_score,
		"day_index": run_state.day_index
	}
	run_state.set_network_discoveries(discoveries)
	_adjust_relationship(run_state, bridge_contact_id, -REFERRAL_RELATIONSHIP_COST)
	_mark_contact_day_flag(run_state, bridge_contact_id, "last_referral_day_index")
	return {
		"success": true,
		"message": "%s made a private introduction to %s." % [
			str(bridge_contact.get("display_name", "Contact")),
			str(referred_contact.get("display_name", "an inner-circle contact"))
		],
		"contact_id": referred_contact_id,
		"referral_type": INNER_CIRCLE_REFERRAL_ROLE,
		"connection_score": connection_score
	}


func follow_up_tip(run_state, data_repository, contact_id: String, followup_id: String) -> Dictionary:
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	if contact.is_empty():
		return {"success": false, "message": "Unknown contact."}
	if not _is_met(run_state, contact_id):
		return {"success": false, "message": "Meet this contact first."}
	var tip: Dictionary = _latest_followup_tip_for_contact(run_state, contact_id)
	if tip.is_empty():
		return {"success": false, "message": "No resolved tip needs a follow-up right now."}
	var followup_result: Dictionary = _build_tip_followup_result(contact, tip, followup_id)
	if not bool(followup_result.get("success", false)):
		return followup_result
	var journal: Dictionary = run_state.get_network_tip_journal()
	var tip_id: String = str(tip.get("id", ""))
	tip["followup_id"] = followup_id
	tip["followup_label"] = str(followup_result.get("followup_label", "Follow-up"))
	tip["followup_note"] = str(followup_result.get("followup_note", ""))
	tip["followup_day_index"] = run_state.day_index
	tip["followup_relationship_delta"] = int(followup_result.get("relationship_delta", 0))
	journal[tip_id] = tip
	run_state.set_network_tip_journal(journal)
	var relationship_delta: int = int(followup_result.get("relationship_delta", 0))
	if relationship_delta != 0:
		_adjust_relationship(run_state, contact_id, relationship_delta)
	_store_contact_tip_followup(run_state, tip)
	return {
		"success": true,
		"message": str(followup_result.get("message", "Follow-up recorded.")),
		"tip_id": tip_id,
		"followup_id": followup_id,
		"relationship_delta": relationship_delta
	}


func ask_source_check(run_state, data_repository, contact_id: String) -> Dictionary:
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	if contact.is_empty():
		return {"success": false, "message": "Unknown contact."}
	if not _is_met(run_state, contact_id):
		return {"success": false, "message": "Meet this contact first."}
	var source_checks: Dictionary = _cross_contact_reads_by_contact(run_state)
	var source_check: Dictionary = source_checks.get(contact_id, {})
	if source_check.is_empty():
		return {"success": false, "message": "No source cross-check is active for this contact."}
	if str(source_check.get("label", "")) != "Conflicting sources":
		return {"success": false, "message": "The current source check is not a direct conflict."}
	if not bool(source_check.get("can_ask_source_check", false)):
		return {"success": false, "message": "You already asked about this source conflict."}
	var tip_id: String = str(source_check.get("current_tip_id", ""))
	if tip_id.is_empty():
		return {"success": false, "message": "This source conflict is missing its read record."}
	var journal: Dictionary = run_state.get_network_tip_journal()
	var tip: Dictionary = journal.get(tip_id, {})
	if tip.is_empty():
		return {"success": false, "message": "This source conflict is no longer available."}
	var response: Dictionary = _build_source_check_response(contact, run_state, source_check)
	tip["source_check_label"] = str(response.get("label", "Asked about conflict"))
	tip["source_check_note"] = str(response.get("note", ""))
	tip["source_check_day_index"] = run_state.day_index
	tip["source_check_relationship_delta"] = int(response.get("relationship_delta", 0))
	tip["source_check_peer_contact_id"] = str(response.get("peer_contact_id", ""))
	tip["source_check_peer_contact_name"] = str(response.get("peer_contact_name", ""))
	journal[tip_id] = tip
	run_state.set_network_tip_journal(journal)
	var relationship_delta: int = int(response.get("relationship_delta", 0))
	if relationship_delta != 0:
		_adjust_relationship(run_state, contact_id, relationship_delta)
	return {
		"success": true,
		"message": str(response.get("message", "Source check recorded.")),
		"tip_id": tip_id,
		"relationship_delta": relationship_delta
	}


func process_due_requests(run_state, data_repository) -> Array:
	var requests: Dictionary = run_state.get_network_requests()
	var results: Array = []
	for request_id_value in requests.keys():
		var request_id: String = str(request_id_value)
		var request: Dictionary = requests.get(request_id, {})
		if str(request.get("status", "")) != "pending":
			continue
		if int(request.get("due_day_index", 0)) > run_state.day_index:
			continue

		var contact_id: String = str(request.get("contact_id", ""))
		var company_id: String = str(request.get("target_company_id", ""))
		if _has_at_least_one_lot(run_state, company_id):
			if _has_active_contact_arc(run_state, contact_id, company_id):
				requests[request_id] = request
				continue
			var arc_result: Dictionary = _build_and_store_contact_arc(run_state, data_repository, contact_id, company_id, "request")
			if not bool(arc_result.get("success", false)):
				requests[request_id] = request
				continue
			request["status"] = "completed"
			request["completed_day_index"] = run_state.day_index
			_adjust_relationship(run_state, contact_id, int(request.get("relationship_delta_success", 8)))
			results.append(arc_result)
		else:
			request["status"] = "missed"
			request["completed_day_index"] = run_state.day_index
			_adjust_relationship(run_state, contact_id, int(request.get("relationship_delta_failure", -6)))
			results.append({"success": false, "message": "Network request missed.", "request_id": request_id})
		requests[request_id] = request
	run_state.set_network_requests(requests)
	return results


func process_due_tip_memories(run_state, data_repository) -> Array:
	var results: Array = []
	var journal: Dictionary = run_state.get_network_tip_journal()
	var contacts: Dictionary = run_state.get_network_contacts()
	var changed: bool = false
	var contacts_changed: bool = false
	for tip_id_value in journal.keys():
		var tip_id: String = str(tip_id_value)
		var tip: Dictionary = journal.get(tip_id, {})
		if str(tip.get("journal_type", "")) == TIP_JOURNAL_TYPE_TWOOTER_SOCIAL:
			if _network_reaction_is_due(tip, run_state.day_index):
				var social_reaction: Dictionary = _apply_network_followup_reaction_with_contacts(run_state, data_repository, tip, contacts)
				tip = social_reaction.get("tip", tip)
				contacts_changed = contacts_changed or bool(social_reaction.get("_contacts_changed", false))
				journal[tip_id] = tip
				changed = true
				results.append(tip.duplicate(true))
			continue
		if str(tip.get("status", TIP_STATUS_PENDING)) == TIP_STATUS_PENDING:
			if int(tip.get("resolve_day_index", 0)) > run_state.day_index:
				continue
			var outcome: Dictionary = _resolve_tip_memory(run_state, data_repository, tip)
			tip["status"] = str(outcome.get("status", TIP_STATUS_RESOLVED))
			tip["outcome_label"] = str(outcome.get("outcome_label", OUTCOME_LABEL_STILL_PENDING))
			tip["outcome_note"] = str(outcome.get("outcome_note", "The read is still unresolved."))
			tip["player_action_label"] = str(outcome.get("player_action_label", "No action"))
			tip["player_action_note"] = str(outcome.get("player_action_note", ""))
			tip["player_action_alignment"] = str(outcome.get("player_action_alignment", "neutral"))
			tip["player_net_shares"] = int(outcome.get("player_net_shares", 0))
			tip["relationship_delta"] = int(outcome.get("relationship_delta", 0))
			tip["resolved_day_index"] = run_state.day_index
			tip["resolved_price"] = float(outcome.get("resolved_price", 0.0))
			tip["resolved_change_pct"] = float(outcome.get("change_pct", 0.0))
			var relationship_delta: int = int(outcome.get("relationship_delta", 0))
			if relationship_delta != 0:
				contacts_changed = _adjust_relationship_in_contacts(contacts, str(tip.get("contact_id", "")), relationship_delta) or contacts_changed
			contacts_changed = _store_contact_tip_note_in_contacts(contacts, tip, run_state.day_index) or contacts_changed
			journal[tip_id] = tip
			changed = true
			results.append(tip.duplicate(true))
		if _network_reaction_is_due(tip, run_state.day_index):
			var reaction: Dictionary = _apply_network_followup_reaction_with_contacts(run_state, data_repository, tip, contacts)
			tip = reaction.get("tip", tip)
			contacts_changed = contacts_changed or bool(reaction.get("_contacts_changed", false))
			journal[tip_id] = tip
			changed = true
			results.append(tip.duplicate(true))
	if contacts_changed:
		run_state.set_network_contacts(contacts)
	if changed:
		run_state.set_network_tip_journal(_pruned_tip_journal(journal))
	return results


func _discover_matching_contacts(
	run_state,
	data_repository,
	company_id: String,
	sector_id: String,
	category: String,
	source_type: String,
	source_id: String,
	include_insiders: bool
) -> Array:
	var network_data: Dictionary = data_repository.get_contact_network_data()
	var recognition: Dictionary = build_recognition_snapshot(run_state)
	var discoveries: Dictionary = run_state.get_network_discoveries()
	var contacts: Dictionary = run_state.get_network_contacts()
	var discovered: Array = []
	var discovery_limit: int = _discovery_limit_for_source(source_type, run_state)
	if include_insiders and not company_id.is_empty():
		_discover_company_insiders(run_state, company_id, category, source_type, source_id, recognition, discoveries, contacts, discovered, discovery_limit)
	if discovered.size() >= discovery_limit:
		run_state.set_network_discoveries(discoveries)
		return discovered
	var candidates: Array = []
	for contact_value in network_data.get("contacts", []):
		var contact: Dictionary = contact_value
		if str(contact.get("affiliation_type", "floater")) != "floater":
			continue
		var contact_id: String = str(contact.get("id", ""))
		if contact_id.is_empty() or bool(contacts.get(contact_id, {}).get("met", false)):
			continue
		if _should_skip_public_contact_discovery(contact, contact_id, discoveries, contacts):
			continue
		if not _can_add_company_lead(discoveries.get(contact_id, {}), company_id):
			continue
		if int(recognition.get("score", 0)) < int(contact.get("recognition_required", 0)):
			continue
		var lead_score: float = _floater_discovery_score(contact, company_id, sector_id, category, source_type)
		if lead_score < 0.0:
			continue
		candidates.append({"contact": contact, "score": lead_score})

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	for candidate_value in candidates:
		var candidate: Dictionary = candidate_value
		var contact: Dictionary = candidate.get("contact", {})
		var contact_id: String = str(contact.get("id", ""))
		var discovery: Dictionary = discoveries.get(contact_id, {})
		var target_company_ids: Array = _contact_company_targets(discovery)
		if not company_id.is_empty() and not target_company_ids.has(company_id):
			target_company_ids.append(company_id)
		discovery["contact_id"] = contact_id
		discovery["discovered"] = true
		discovery["source_type"] = source_type
		discovery["source_id"] = source_id
		discovery["target_company_id"] = company_id if not company_id.is_empty() else str(discovery.get("target_company_id", ""))
		discovery["target_company_ids"] = target_company_ids
		discovery["target_sector_id"] = sector_id
		discovery["lead_score"] = int(round(float(candidate.get("score", 0.0))))
		discovery["day_index"] = run_state.day_index
		discoveries[contact_id] = discovery
		discovered.append(_contact_row(contact, contacts.get(contact_id, {}), discovery, recognition))
		if discovered.size() >= discovery_limit:
			break
	run_state.set_network_discoveries(discoveries)
	return discovered


func _discover_article_author_contact(
	run_state,
	data_repository,
	author_contact_id: String,
	company_id: String,
	sector_id: String,
	category: String,
	source_id: String
) -> Array:
	var contact: Dictionary = _contact_definition(run_state, data_repository, author_contact_id)
	if contact.is_empty() or str(contact.get("affiliation_type", "floater")) != "floater":
		return []
	var recognition: Dictionary = build_recognition_snapshot(run_state)
	var contacts: Dictionary = run_state.get_network_contacts()
	if bool(contacts.get(author_contact_id, {}).get("met", false)):
		return []
	var discoveries: Dictionary = run_state.get_network_discoveries()
	if _should_skip_public_contact_discovery(contact, author_contact_id, discoveries, contacts):
		return []
	if int(recognition.get("score", 0)) < int(contact.get("recognition_required", 0)):
		return []
	if _floater_discovery_score(contact, company_id, sector_id, category, "news") < 0.0:
		return []
	var discovery: Dictionary = discoveries.get(author_contact_id, {})
	var target_company_ids: Array = _contact_company_targets(discovery)
	if not company_id.is_empty() and not target_company_ids.has(company_id):
		target_company_ids.append(company_id)
	discovery["contact_id"] = author_contact_id
	discovery["discovered"] = true
	discovery["source_type"] = "news"
	discovery["source_id"] = source_id
	discovery["target_company_id"] = company_id if not company_id.is_empty() else str(discovery.get("target_company_id", ""))
	discovery["target_company_ids"] = target_company_ids
	discovery["target_sector_id"] = sector_id
	discovery["lead_score"] = max(int(discovery.get("lead_score", 0)), 96)
	discovery["day_index"] = run_state.day_index
	discoveries[author_contact_id] = discovery
	run_state.set_network_discoveries(discoveries)
	return [_contact_row(contact, contacts.get(author_contact_id, {}), discovery, recognition)]


func _discovery_limit_for_source(source_type: String, run_state) -> int:
	return NETWORK_DISCOVERY_SCRIPT.discovery_limit_for_source(source_type, run_state.company_order.size())


func _floater_discovery_score(contact: Dictionary, company_id: String, sector_id: String, category: String, source_type: String) -> float:
	return NETWORK_DISCOVERY_SCRIPT.floater_discovery_score(contact, company_id, sector_id, category, source_type)


func _discover_company_insiders(
	run_state,
	company_id: String,
	category: String,
	source_type: String,
	source_id: String,
	recognition: Dictionary,
	discoveries: Dictionary,
	contacts: Dictionary,
	discovered: Array,
	discovery_limit: int
) -> void:
	var roster: Array = _management_roster_for_company(run_state, company_id)
	for insider_value in roster:
		var insider: Dictionary = insider_value
		if str(insider.get("affiliation_type", "insider")) != "insider":
			continue
		var insider_id: String = str(insider.get("id", insider.get("contact_id", "")))
		if insider_id.is_empty() or bool(contacts.get(insider_id, {}).get("met", false)):
			continue
		if bool(discoveries.get(insider_id, {}).get("discovered", false)):
			continue
		if _should_skip_public_contact_discovery(insider, insider_id, discoveries, contacts):
			continue
		if int(recognition.get("score", 0)) < int(insider.get("recognition_required", 0)):
			continue
		if not category.is_empty() and not (category in insider.get("categories", [])):
			continue
		var discovery: Dictionary = {
			"contact_id": insider_id,
			"discovered": true,
			"source_type": source_type,
			"source_id": source_id,
			"target_company_id": company_id,
			"target_company_ids": [company_id],
			"target_sector_id": str(insider.get("sector_id", "")),
			"lead_score": 100,
			"day_index": run_state.day_index
		}
		discoveries[insider_id] = discovery
		discovered.append(_contact_row(insider, contacts.get(insider_id, {}), discovery, recognition))
		if discovered.size() >= discovery_limit:
			return


func _build_and_store_contact_arc(run_state, data_repository, contact_id: String, company_id: String, action: String) -> Dictionary:
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	if contact.is_empty():
		return {"success": false, "message": "Unknown contact."}
	if not _is_met(run_state, contact_id):
		return {"success": false, "message": "Meet this contact first."}
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	if definition.is_empty():
		return {"success": false, "message": "No target company is available."}
	if _has_active_contact_arc(run_state, contact_id, company_id):
		return {"success": false, "message": "That contact already has an active read on this stock."}

	var start_day: int = run_state.day_index + 1
	var tone: String = str(contact.get("tone", "mixed"))
	var sentiment: float = _sentiment_for_contact(contact, action)
	var target_ticker: String = str(definition.get("ticker", company_id.to_upper()))
	var arc: Dictionary = {
		"arc_id": "contact_%s_%s_%s_%d" % [action, contact_id, company_id, start_day],
		"scope": "company",
		"event_id": "contact_%s" % action,
		"event_family": "contact",
		"category": "network",
		"tone": tone,
		"target_company_id": company_id,
		"target_sector_id": str(definition.get("sector_id", "")),
		"target_ticker": target_ticker,
		"target_company_name": str(definition.get("name", target_ticker)),
		"trade_date": run_state.get_current_trade_date(),
		"description": _contact_arc_description(contact, target_ticker, action),
		"broker_bias": "institution",
		"source_contact_id": contact_id,
		"source_contact_name": str(contact.get("display_name", "")),
		"source_action": action,
		"phase_schedule": [
			{"id": "hidden_whisper", "label": "Hidden whisper", "duration_days": 1, "sentiment_shift": sentiment * 0.55, "volatility_multiplier": 1.12, "visibility": "hidden", "hidden_flag": "contact_whisper"},
			{"id": "visible_reaction", "label": "Visible reaction", "duration_days": 2, "sentiment_shift": sentiment, "volatility_multiplier": 1.22, "visibility": "visible", "hidden_flag": ""},
			{"id": "digestion", "label": "Digestion", "duration_days": 2, "sentiment_shift": sentiment * -0.28, "volatility_multiplier": 0.95, "visibility": "visible", "hidden_flag": ""}
		],
		"duration_days": 5,
		"start_day_index": start_day,
		"end_day_index": start_day + 4,
		"hidden_story_flag": "contact_whisper"
	}
	run_state.add_network_company_arc(arc)
	return {"success": true, "message": "%s created a %s arc on %s." % [str(contact.get("display_name", "Contact")), action, target_ticker], "arc": arc}


func _generated_relationship_network_tip_result(
	run_state,
	_data_repository,
	contact: Dictionary,
	contact_id: String,
	company_id: String
) -> Dictionary:
	if not run_state.has_method("get_event_history"):
		return {}
	var recognition: Dictionary = build_recognition_snapshot(run_state)
	var runtime: Dictionary = run_state.get_network_contacts().get(contact_id, {}) if typeof(run_state.get_network_contacts().get(contact_id, {})) == TYPE_DICTIONARY else {}
	var candidates: Array = []
	for event_value in run_state.get_event_history():
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event_data: Dictionary = event_value
		if str(event_data.get("event_family", "")) != RELATIONSHIP_GRAPH_SOURCE_SYSTEM_ID:
			continue
		if str(event_data.get("target_company_id", "")) != company_id:
			continue
		if not _relationship_network_visibility_allowed(str(event_data.get("relationship_visibility", ""))):
			continue
		var age_days: int = max(run_state.day_index - int(event_data.get("day_index", run_state.day_index)), 0)
		if age_days > 6:
			continue
		if not _relationship_network_gate_met(event_data, runtime, recognition):
			continue
		candidates.append({
			"event": event_data.duplicate(true),
			"score": _relationship_network_score(event_data, contact, age_days)
		})
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("score", 0.0)), float(b.get("score", 0.0))):
			return str(a.get("event", {}).get("relationship_event_id", "")) < str(b.get("event", {}).get("relationship_event_id", ""))
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	return _build_generated_relationship_network_tip_result(run_state, contact, company_id, candidates[0].get("event", {}), runtime, recognition)


func _relationship_network_visibility_allowed(visibility_value: String) -> bool:
	var visibility: String = visibility_value.strip_edges().to_lower()
	return visibility == "semi_public" or visibility == "private"


func _relationship_network_gate_met(event_data: Dictionary, runtime: Dictionary, recognition: Dictionary) -> bool:
	var relationship: int = int(runtime.get("relationship", 0))
	var recognition_score: float = float(recognition.get("score", 0.0))
	var visibility: String = str(event_data.get("relationship_visibility", "")).strip_edges().to_lower()
	if visibility == "private":
		return relationship >= NETWORK_PRIVATE_STAGE_TRUSTED_RELATIONSHIP and recognition_score >= 45.0
	return relationship >= NETWORK_PRIVATE_STAGE_RECOGNIZED_RELATIONSHIP or recognition_score >= 35.0


func _relationship_network_score(event_data: Dictionary, contact: Dictionary, age_days: int) -> float:
	var confidence: float = clamp(float(event_data.get("relationship_confidence", event_data.get("confidence", 0.0))), 0.0, 1.0)
	var strength: float = clamp(float(event_data.get("relationship_strength", 0.0)), 0.0, 1.0)
	var recency: float = clamp(1.0 - float(age_days) / 7.0, 0.0, 1.0)
	return confidence * 0.46 + strength * 0.26 + recency * 0.18 + float(contact.get("reliability", 0.0)) * 0.10


func _build_generated_relationship_network_tip_result(
	run_state,
	contact: Dictionary,
	company_id: String,
	event_data: Dictionary,
	runtime: Dictionary,
	recognition: Dictionary
) -> Dictionary:
	if event_data.is_empty():
		return {}
	var ticker: String = _company_ticker(run_state, company_id)
	var counterparty_ticker: String = str(event_data.get("counterparty_ticker", event_data.get("counterparty_company_id", ""))).to_upper()
	var contact_name: String = str(contact.get("display_name", "Contact"))
	var truth_label: String = _relationship_network_truth_label(event_data)
	var confidence_label: String = _relationship_network_confidence_label(event_data, contact)
	var tip_read: String = _relationship_network_tip_read(contact, ticker, counterparty_ticker, event_data)
	var reliability: float = clamp(float(event_data.get("relationship_confidence", event_data.get("confidence", 0.0))) * 0.70 + float(contact.get("reliability", 0.0)) * 0.30, 0.0, 1.0)
	var visibility: String = str(event_data.get("relationship_visibility", "semi_public")).strip_edges().to_lower()
	return {
		"success": true,
		"message": "%s | %s: %s" % [truth_label, contact_name, tip_read],
		"public_truth_label": truth_label,
		"public_tip_read": tip_read,
		"public_confidence_label": confidence_label,
		"tip_source_role": _contact_tip_voice(contact),
		"intel_summary": "%s | %s" % [truth_label, confidence_label],
		"intel_quality": _relationship_network_intel_quality(reliability),
		"chain_id": "",
		"generated_content_surface": true,
		"generated_surface_id": GENERATED_DOSSIER_NETWORK_SURFACE_ID,
		"generated_scope_id": "relationship",
		"source_system_id": RELATIONSHIP_GRAPH_SOURCE_SYSTEM_ID,
		"story_id": str(event_data.get("relationship_event_id", "")),
		"story_family": "company_relationship",
		"archetype_id": str(event_data.get("relationship_event_kind", event_data.get("category", ""))),
		"public_status": "market_talk",
		"stage_id": "relationship_event",
		"visibility": "private",
		"detail_level": "relationship",
		"reliability": snappedf(reliability, 0.001),
		"leak_risk": 0.22 if visibility == "semi_public" else 0.42,
		"source_fact_ids": _network_unique_string_array(["relationship_event:%s" % str(event_data.get("relationship_event_id", ""))]),
		"source_clue_ids": _network_unique_string_array(["relationship_edge:%s" % str(event_data.get("relationship_edge_id", ""))]),
		"source_company_ids": _network_unique_string_array([
			str(event_data.get("target_company_id", "")),
			str(event_data.get("counterparty_company_id", ""))
		]),
		"source_sector_ids": _network_unique_string_array([str(event_data.get("target_sector_id", ""))]),
		"source_event_ids": _network_unique_string_array([str(event_data.get("relationship_event_id", ""))]),
		"target_company_id": company_id,
		"target_ticker": ticker,
		"source_quality": "relationship_network",
		"directness": "relationship",
		"original_directness": "relationship",
		"required_relationship_stage": "recognized",
		"required_recognition_min": 35,
		"network_relationship": int(runtime.get("relationship", 0)),
		"recognition_score": snappedf(float(recognition.get("score", 0.0)), 0.01)
	}


func _relationship_network_truth_label(event_data: Dictionary) -> String:
	match str(event_data.get("tone", "mixed")):
		"positive":
			return TRUTH_LABEL_NETWORK_READ
		"negative":
			return TRUTH_LABEL_PRESSURE_READ
		_:
			return TRUTH_LABEL_EARLY_READ


func _relationship_network_confidence_label(event_data: Dictionary, contact: Dictionary) -> String:
	var reliability: float = clamp(float(event_data.get("relationship_confidence", event_data.get("confidence", 0.0))) * 0.68 + float(contact.get("reliability", 0.0)) * 0.32, 0.0, 1.0)
	if reliability >= 0.76:
		return "Grounded relationship read"
	if reliability >= 0.64:
		return "Useful relationship read"
	return "Soft relationship read"


func _relationship_network_intel_quality(reliability: float) -> String:
	if reliability >= 0.76:
		return "strong"
	if reliability >= 0.62:
		return "medium"
	return "weak"


func _relationship_network_tip_read(contact: Dictionary, ticker: String, counterparty_ticker: String, event_data: Dictionary) -> String:
	var source_role: String = _contact_tip_voice(contact).capitalize()
	var event_kind: String = str(event_data.get("relationship_event_kind", ""))
	var role: String = str(event_data.get("relationship_impact_role", ""))
	if event_kind == "competitor_pressure":
		return "%s says %s versus %s is the real read. Do not treat it as a standalone trade until the relative move confirms." % [source_role, ticker, counterparty_ticker]
	if role == "supplier":
		return "%s says the %s link matters for %s if orders or delivery follow through; the tape alone is not enough." % [source_role, counterparty_ticker, ticker]
	if role == "customer":
		return "%s says %s has exposure to the %s link, but the margin effect still needs checking." % [source_role, ticker, counterparty_ticker]
	return "%s says %s and %s are being tied together by a relationship read; watch confirmation before sizing it." % [source_role, ticker, counterparty_ticker]


func _generated_dossier_network_tip_result(
	run_state,
	data_repository,
	contact: Dictionary,
	contact_id: String,
	company_id: String
) -> Dictionary:
	if not run_state.has_method("get_company_story_dossiers_for_company"):
		return {}
	var recognition: Dictionary = build_recognition_snapshot(run_state)
	var runtime: Dictionary = run_state.get_network_contacts().get(contact_id, {}) if typeof(run_state.get_network_contacts().get(contact_id, {})) == TYPE_DICTIONARY else {}
	var candidates: Array = []
	for dossier_value in run_state.get_company_story_dossiers_for_company(company_id):
		if typeof(dossier_value) != TYPE_DICTIONARY:
			continue
		var dossier: Dictionary = dossier_value
		var private_clue: Dictionary = _eligible_private_network_clue_for_dossier(dossier, runtime, recognition, run_state.day_index)
		if private_clue.is_empty():
			continue
		var effective_directness: String = _network_clue_effective_directness(private_clue, contact, runtime, recognition)
		var fact_ids: Array = _network_clue_fact_ids(dossier, private_clue)
		candidates.append({
			"dossier": dossier.duplicate(true),
			"clue": private_clue,
			"effective_directness": effective_directness,
			"source_fact_ids": fact_ids,
			"score": _generated_network_clue_score(dossier, private_clue, effective_directness)
		})
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("score", 0.0)), float(b.get("score", 0.0))):
			return str(a.get("dossier", {}).get("story_id", "")) < str(b.get("dossier", {}).get("story_id", ""))
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	return _build_generated_dossier_network_tip_result(
		run_state,
		data_repository,
		contact,
		company_id,
		candidates[0],
		runtime,
		recognition
	)


func _eligible_private_network_clue_for_dossier(
	dossier: Dictionary,
	runtime: Dictionary,
	recognition: Dictionary,
	day_index: int
) -> Dictionary:
	for clue_value in dossier.get("private_clues", []):
		if typeof(clue_value) != TYPE_DICTIONARY:
			continue
		var clue: Dictionary = clue_value
		if str(clue.get("surface_id", "")) != GENERATED_DOSSIER_NETWORK_SURFACE_ID:
			continue
		if str(clue.get("visibility", "")) != "private":
			continue
		var earliest_day_index: int = int(clue.get("earliest_day_index", 0))
		var latest_day_index: int = int(clue.get("latest_day_index", earliest_day_index))
		if day_index < earliest_day_index or day_index > latest_day_index:
			continue
		if not _network_private_clue_gate_met(clue, runtime, recognition):
			continue
		return clue.duplicate(true)
	return {}


func _network_private_clue_gate_met(clue: Dictionary, runtime: Dictionary, recognition: Dictionary) -> bool:
	if float(recognition.get("score", 0.0)) < float(clue.get("required_recognition_min", 0.0)):
		return false
	var relationship: int = int(runtime.get("relationship", 0))
	match str(clue.get("required_relationship_stage", "recognized")):
		"inner_circle", "inner_circle_candidate", "specific":
			return relationship >= NETWORK_PRIVATE_STAGE_INNER_RELATIONSHIP
		"trusted":
			return relationship >= NETWORK_PRIVATE_STAGE_TRUSTED_RELATIONSHIP
		"recognized":
			return relationship >= NETWORK_PRIVATE_STAGE_RECOGNIZED_RELATIONSHIP
		_:
			return relationship >= NETWORK_PRIVATE_STAGE_RECOGNIZED_RELATIONSHIP


func _network_clue_effective_directness(clue: Dictionary, contact: Dictionary, runtime: Dictionary, recognition: Dictionary) -> String:
	var requested_directness: String = str(clue.get("directness", "contextual")).strip_edges().to_lower()
	if requested_directness == "specific" and _network_contact_allows_specific_clue(clue, contact, runtime, recognition):
		return "specific"
	if requested_directness == "specific":
		return "high"
	if requested_directness in ["high", "medium", "contextual"]:
		return requested_directness
	return "contextual"


func _network_contact_allows_specific_clue(clue: Dictionary, contact: Dictionary, runtime: Dictionary, recognition: Dictionary) -> bool:
	if int(runtime.get("relationship", 0)) < NETWORK_PRIVATE_STAGE_INNER_RELATIONSHIP:
		return false
	if float(recognition.get("score", 0.0)) < NETWORK_PRIVATE_STAGE_INNER_RECOGNITION:
		return false
	var source_quality: String = str(clue.get("source_quality", "")).strip_edges().to_lower()
	if source_quality == "operator":
		return true
	if str(contact.get("affiliation_type", "floater")) == "insider":
		return true
	return float(contact.get("reliability", 0.0)) >= 0.72


func _generated_network_clue_score(dossier: Dictionary, clue: Dictionary, effective_directness: String) -> float:
	var directness_bonus: float = 0.0
	match effective_directness:
		"specific":
			directness_bonus = 0.18
		"high":
			directness_bonus = 0.11
		"medium":
			directness_bonus = 0.06
		_:
			directness_bonus = 0.0
	return float(clue.get("reliability", 0.0)) + float(dossier.get("priority", 0.0)) * 0.18 + directness_bonus


func _build_generated_dossier_network_tip_result(
	run_state,
	data_repository,
	contact: Dictionary,
	company_id: String,
	candidate: Dictionary,
	runtime: Dictionary,
	recognition: Dictionary
) -> Dictionary:
	var dossier: Dictionary = candidate.get("dossier", {}) if typeof(candidate.get("dossier", {})) == TYPE_DICTIONARY else {}
	var clue: Dictionary = candidate.get("clue", {}) if typeof(candidate.get("clue", {})) == TYPE_DICTIONARY else {}
	var effective_directness: String = str(candidate.get("effective_directness", "contextual"))
	var fact_ids: Array = candidate.get("source_fact_ids", []) if typeof(candidate.get("source_fact_ids", [])) == TYPE_ARRAY else []
	var ticker: String = _company_ticker(run_state, company_id)
	var contact_name: String = str(contact.get("display_name", "Contact"))
	var truth_label: String = _generated_network_truth_label(dossier)
	var confidence_label: String = _generated_network_confidence_label(clue, contact, effective_directness)
	var source_role: String = _contact_tip_voice(contact)
	var tip_read: String = _generated_network_tip_read(
		run_state,
		data_repository,
		contact,
		dossier,
		clue,
		company_id,
		effective_directness,
		truth_label
	)
	return {
		"success": true,
		"message": "%s | %s: %s" % [truth_label, contact_name, tip_read],
		"public_truth_label": truth_label,
		"public_tip_read": tip_read,
		"public_confidence_label": confidence_label,
		"tip_source_role": source_role,
		"intel_summary": "%s | %s" % [truth_label, confidence_label],
		"intel_quality": _generated_network_intel_quality(clue, effective_directness),
		"chain_id": "",
		"generated_content_surface": true,
		"generated_surface_id": GENERATED_DOSSIER_NETWORK_SURFACE_ID,
		"source_system_id": GENERATED_DOSSIER_NETWORK_SOURCE_SYSTEM_ID,
		"story_id": str(dossier.get("story_id", "")),
		"story_family": str(dossier.get("story_family", "company_story")),
		"archetype_id": str(dossier.get("archetype_id", "")),
		"public_status": str(dossier.get("public_status", "")),
		"stage_id": str(dossier.get("stage_id", "")),
		"visibility": "private",
		"detail_level": effective_directness,
		"reliability": snappedf(clamp(float(clue.get("reliability", 0.0)), 0.0, 1.0), 0.001),
		"leak_risk": snappedf(clamp(float(clue.get("leak_risk", 0.0)), 0.0, 1.0), 0.001),
		"source_fact_ids": _network_unique_string_array(fact_ids),
		"source_clue_ids": _network_unique_string_array([str(clue.get("clue_id", ""))]),
		"source_company_ids": _network_source_company_ids(dossier),
		"source_sector_ids": _network_source_sector_ids(dossier, run_state.get_effective_company_definition(company_id, false, false)),
		"target_company_id": company_id,
		"target_ticker": ticker,
		"source_quality": str(clue.get("source_quality", "")),
		"directness": effective_directness,
		"original_directness": str(clue.get("directness", "")),
		"required_relationship_stage": str(clue.get("required_relationship_stage", "")),
		"required_recognition_min": int(clue.get("required_recognition_min", 0)),
		"network_relationship": int(runtime.get("relationship", 0)),
		"recognition_score": snappedf(float(recognition.get("score", 0.0)), 0.01)
	}


func _generated_network_truth_label(dossier: Dictionary) -> String:
	match str(dossier.get("truth_state", "uncertain")):
		"real":
			return TRUTH_LABEL_ACCUMULATION
		"delayed":
			return TRUTH_LABEL_REAL_BUT_DELAYED
		"failed":
			return TRUTH_LABEL_DEAD_STORY
		"fraud_risk":
			return TRUTH_LABEL_PRESSURE_READ
		"overhyped":
			return TRUTH_LABEL_RETAIL_TRAP
		_:
			return TRUTH_LABEL_EARLY_READ


func _generated_network_confidence_label(clue: Dictionary, contact: Dictionary, effective_directness: String) -> String:
	var reliability: float = clamp(float(clue.get("reliability", 0.0)) * 0.72 + float(contact.get("reliability", 0.0)) * 0.28, 0.0, 1.0)
	if effective_directness == "specific" and reliability >= 0.74:
		return "High conviction"
	if reliability >= 0.76:
		return "Grounded read"
	if reliability >= 0.66:
		return "Early but credible"
	return "Soft read"


func _generated_network_intel_quality(clue: Dictionary, effective_directness: String) -> String:
	var reliability: float = float(clue.get("reliability", 0.0))
	if effective_directness == "specific" and reliability >= 0.78:
		return "very_strong"
	if reliability >= 0.74 or effective_directness == "high":
		return "strong"
	if reliability >= 0.64:
		return "medium"
	return "weak"


func _generated_network_tip_read(
	run_state,
	_data_repository,
	contact: Dictionary,
	dossier: Dictionary,
	_clue: Dictionary,
	company_id: String,
	effective_directness: String,
	truth_label: String
) -> String:
	var ticker: String = _company_ticker(run_state, company_id)
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	var company_name: String = str(definition.get("name", ticker))
	var source_role: String = _contact_tip_voice(contact)
	var mechanism: String = _generated_network_mechanism_phrase(dossier, definition)
	var watch_note: String = _generated_network_watch_note(truth_label, ticker, mechanism)
	if effective_directness == "specific":
		if truth_label in CAUTIONARY_TRUTH_LABELS:
			return "%s says do not chase %s here; the cleaner move is to wait for pressure to clear. %s" % [
				source_role.capitalize(),
				ticker,
				watch_note
			]
		return "%s says the direct read is buy %s and hold through the next public checkpoint. %s" % [
			source_role.capitalize(),
			ticker,
			watch_note
		]
	if effective_directness == "high":
		return "%s has a stronger private read on %s: %s %s" % [
			source_role.capitalize(),
			ticker,
			mechanism,
			watch_note
		]
	if effective_directness == "medium":
		return "%s frames %s as more than public chatter, but not clean enough for a blind trade. %s" % [
			source_role.capitalize(),
			ticker,
			watch_note
		]
	return "%s says %s is worth tracking quietly; the useful part is still the mechanism, not the noise around %s. %s" % [
		source_role.capitalize(),
		ticker,
		company_name,
		watch_note
	]


func _generated_network_mechanism_phrase(dossier: Dictionary, definition: Dictionary) -> String:
	var sector_name: String = str(definition.get("sector_name", definition.get("sector_id", "sector"))).replace("_", " ")
	match str(dossier.get("archetype_id", "")):
		"contract_win":
			return "the work pipeline sounds more tangible than the public headline."
		"capex_expansion":
			return "capacity and execution timing matter more than the announcement itself."
		"margin_recovery":
			return "the margin setup is improving, but confirmation still has to show up in numbers."
		"commodity_tailwind":
			return "%s exposure is helping the story, but only names with real pass-through deserve credit." % sector_name
		"commodity_headwind":
			return "%s cost pressure is the part people are underestimating." % sector_name
		"governance_risk":
			return "the governance read is not clean enough to ignore."
		"balance_sheet_stress":
			return "cash collection and refinancing pressure are the real tells."
		"fraud_signal":
			return "the accounting trail needs careful checking before trusting the story."
		"turnaround":
			return "the turnaround path is alive, but execution is still doing the heavy lifting."
		_:
			return "there is a company-specific read behind the public story."


func _generated_network_watch_note(truth_label: String, ticker: String, mechanism: String) -> String:
	match truth_label:
		TRUTH_LABEL_REAL_BUT_DELAYED:
			return "Timing is the risk; keep %s on watch until the next dated clue." % ticker
		TRUTH_LABEL_DEAD_STORY:
			return "Do not reopen it unless a fresh public clue changes the setup."
		TRUTH_LABEL_PRESSURE_READ, TRUTH_LABEL_RETAIL_TRAP, TRUTH_LABEL_DISTRIBUTION_RISK:
			return "The next confirmation should be balance-sheet, filing, or tape behavior, not louder chatter."
		TRUTH_LABEL_ACCUMULATION:
			return "If volume builds without the room getting too loud, the read improves."
		_:
			return "Use filings, tape, or a second source to test whether %s is real." % mechanism.trim_suffix(".")


func _network_clue_fact_ids(dossier: Dictionary, clue: Dictionary) -> Array:
	var clue_fact_ids: Array = _network_unique_string_array(clue.get("fact_ids", []))
	if not clue_fact_ids.is_empty():
		return clue_fact_ids
	var fact_ids: Array = []
	for fact_value in dossier.get("cause_facts", []):
		if typeof(fact_value) != TYPE_DICTIONARY:
			continue
		var fact: Dictionary = fact_value
		fact_ids.append(str(fact.get("fact_id", "")))
	return _network_unique_string_array(fact_ids)


func _network_source_company_ids(dossier: Dictionary) -> Array:
	var company_ids: Array = [str(dossier.get("company_id", ""))]
	for fact_value in dossier.get("cause_facts", []):
		if typeof(fact_value) != TYPE_DICTIONARY:
			continue
		var fact: Dictionary = fact_value
		for company_id_value in fact.get("related_company_ids", []):
			company_ids.append(str(company_id_value))
	return _network_unique_string_array(company_ids)


func _network_source_sector_ids(dossier: Dictionary, definition: Dictionary) -> Array:
	var sector_ids: Array = [str(definition.get("sector_id", ""))]
	for fact_value in dossier.get("cause_facts", []):
		if typeof(fact_value) != TYPE_DICTIONARY:
			continue
		var fact: Dictionary = fact_value
		for sector_id_value in fact.get("related_sector_ids", []):
			sector_ids.append(str(sector_id_value))
	return _network_unique_string_array(sector_ids)


func _network_unique_string_array(source_value: Variant) -> Array:
	var source_array: Array = source_value if typeof(source_value) == TYPE_ARRAY else [source_value]
	var seen: Dictionary = {}
	var result: Array = []
	for item_value in source_array:
		var item: String = str(item_value).strip_edges()
		if item.is_empty() or seen.has(item):
			continue
		seen[item] = true
		result.append(item)
	return result


func _decorate_tip_result(run_state, data_repository, contact: Dictionary, company_id: String, tip_result: Dictionary) -> Dictionary:
	var result: Dictionary = tip_result.duplicate(true)
	var chain: Dictionary = _active_corporate_chain_for_company(run_state, company_id)
	var truth_read: Dictionary = _build_public_tip_read(
		run_state,
		data_repository,
		contact,
		company_id,
		chain,
		str(tip_result.get("intel_quality", "weak"))
	)
	var contact_name: String = str(contact.get("display_name", "Contact"))
	result["public_truth_label"] = str(truth_read.get("truth_label", TRUTH_LABEL_NETWORK_READ))
	result["public_tip_read"] = str(truth_read.get("tip_read", ""))
	result["public_confidence_label"] = str(truth_read.get("confidence_label", "Soft read"))
	result["tip_source_role"] = str(truth_read.get("source_role", "market contact"))
	result["intel_summary"] = "%s | %s" % [
		str(truth_read.get("truth_label", TRUTH_LABEL_NETWORK_READ)),
		str(truth_read.get("confidence_label", "Soft read"))
	]
	result["message"] = "%s | %s: %s" % [
		str(truth_read.get("truth_label", TRUTH_LABEL_NETWORK_READ)),
		contact_name,
		str(truth_read.get("tip_read", ""))
	]
	return result


func _decorate_contact_arc_tip_result(run_state, data_repository, contact: Dictionary, company_id: String, tip_result: Dictionary) -> Dictionary:
	var result: Dictionary = tip_result.duplicate(true)
	var truth_read: Dictionary = _build_public_tip_read(
		run_state,
		data_repository,
		contact,
		company_id,
		{},
		"weak"
	)
	var contact_name: String = str(contact.get("display_name", "Contact"))
	result["public_truth_label"] = str(truth_read.get("truth_label", TRUTH_LABEL_NETWORK_READ))
	result["public_tip_read"] = str(truth_read.get("tip_read", ""))
	result["public_confidence_label"] = str(truth_read.get("confidence_label", "Soft read"))
	result["tip_source_role"] = str(truth_read.get("source_role", "market contact"))
	result["message"] = "%s | %s: %s" % [
		str(truth_read.get("truth_label", TRUTH_LABEL_NETWORK_READ)),
		contact_name,
		str(truth_read.get("tip_read", ""))
	]
	return result


func _record_tip_memory(run_state, contact: Dictionary, company_id: String, tip_result: Dictionary) -> void:
	var contact_id: String = str(contact.get("id", contact.get("contact_id", "")))
	if contact_id.is_empty() or company_id.is_empty():
		return
	var company: Dictionary = run_state.get_company(company_id)
	var baseline_price: float = float(company.get("current_price", 0.0))
	if baseline_price <= 0.0:
		return
	var holding: Dictionary = run_state.get_holding(company_id)
	var tip_id: String = "tip_%s_%s_%d_%d" % [
		contact_id,
		company_id,
		run_state.day_index,
		run_state.get_network_tip_journal().size()
	]
	var journal: Dictionary = run_state.get_network_tip_journal()
	var journal_row: Dictionary = {
		"id": tip_id,
		"contact_id": contact_id,
		"contact_name": str(contact.get("display_name", "Contact")),
		"target_company_id": company_id,
		"target_ticker": _company_ticker(run_state, company_id),
		"created_day_index": run_state.day_index,
		"resolve_day_index": run_state.day_index + TIP_MEMORY_RESOLVE_DAYS,
		"baseline_price": baseline_price,
		"baseline_shares": int(holding.get("shares", 0)),
		"chain_id": str(tip_result.get("chain_id", "")),
		"truth_label": str(tip_result.get("public_truth_label", TRUTH_LABEL_NETWORK_READ)),
		"confidence_label": str(tip_result.get("public_confidence_label", "Soft read")),
		"source_role": str(tip_result.get("tip_source_role", "market contact")),
		"tip_read": str(tip_result.get("public_tip_read", "")),
		"status": TIP_STATUS_PENDING,
		"reaction_due_day_index": run_state.day_index + TIP_MEMORY_RESOLVE_DAYS,
		"reaction_sent": false,
		"reaction_label": "",
		"reaction_note": "",
		"reaction_relationship_delta": 0,
		"reaction_reliability_delta": 0,
		"reaction_twooter_account_id": _contact_twooter_account_id(contact),
		"reaction_twooter_handle": _contact_twooter_handle(contact)
	}
	for key in [
		"generated_content_surface",
		"generated_surface_id",
		"generated_scope_id",
		"source_system_id",
		"story_id",
		"story_family",
		"archetype_id",
		"public_status",
		"stage_id",
		"visibility",
		"detail_level",
		"reliability",
		"leak_risk",
		"source_fact_ids",
		"source_clue_ids",
		"source_company_ids",
		"source_sector_ids",
		"source_event_ids",
		"source_quality",
		"directness",
		"original_directness",
		"required_relationship_stage",
		"required_recognition_min",
		"network_relationship",
		"recognition_score"
	]:
		if tip_result.has(key):
			journal_row[key] = _decorator_copy_value(tip_result.get(key))
	journal[tip_id] = journal_row
	run_state.set_network_tip_journal(_pruned_tip_journal(journal))


func _resolve_tip_memory(run_state, _data_repository, tip: Dictionary) -> Dictionary:
	return NETWORK_TIP_RESOLVER_SCRIPT.resolve_tip_memory(
		run_state,
		tip,
		_chain_by_id(run_state, str(tip.get("chain_id", "")))
	)


func _player_action_for_tip(run_state, tip: Dictionary) -> Dictionary:
	return NETWORK_TIP_RESOLVER_SCRIPT.player_action_for_tip(run_state, tip)


func _player_tip_action_read(tip: Dictionary, outcome_label: String, player_action: Dictionary) -> Dictionary:
	return NETWORK_TIP_RESOLVER_SCRIPT.player_tip_action_read(tip, outcome_label, player_action)


func _tip_label_is_cautionary(truth_label: String) -> bool:
	return NETWORK_TIP_RESOLVER_SCRIPT.tip_label_is_cautionary(truth_label)


func _tip_outcome_note(outcome_label: String, ticker: String, change_pct: float) -> String:
	return NETWORK_TIP_RESOLVER_SCRIPT.tip_outcome_note(outcome_label, ticker, change_pct)


func _store_contact_tip_note(run_state, tip: Dictionary) -> void:
	var contacts: Dictionary = run_state.get_network_contacts()
	if _store_contact_tip_note_in_contacts(contacts, tip, run_state.day_index):
		run_state.set_network_contacts(contacts)


func _store_contact_tip_note_in_contacts(contacts: Dictionary, tip: Dictionary, default_day_index: int) -> bool:
	var contact_id: String = str(tip.get("contact_id", ""))
	if contact_id.is_empty():
		return false
	var runtime: Dictionary = contacts.get(contact_id, {})
	runtime["last_tip_id"] = str(tip.get("id", ""))
	runtime["last_tip_status"] = str(tip.get("status", ""))
	runtime["last_tip_label"] = str(tip.get("outcome_label", OUTCOME_LABEL_STILL_PENDING))
	runtime["last_tip_note"] = str(tip.get("outcome_note", ""))
	runtime["last_tip_player_action_label"] = str(tip.get("player_action_label", ""))
	runtime["last_tip_player_action_alignment"] = str(tip.get("player_action_alignment", ""))
	runtime["last_tip_day_index"] = int(tip.get("resolved_day_index", default_day_index))
	contacts[contact_id] = runtime
	return true


func _store_contact_tip_followup(run_state, tip: Dictionary) -> void:
	var contact_id: String = str(tip.get("contact_id", ""))
	if contact_id.is_empty():
		return
	var contacts: Dictionary = run_state.get_network_contacts()
	var runtime: Dictionary = contacts.get(contact_id, {})
	runtime["last_tip_followup_id"] = str(tip.get("followup_id", ""))
	runtime["last_tip_followup_label"] = str(tip.get("followup_label", ""))
	runtime["last_tip_followup_note"] = str(tip.get("followup_note", ""))
	runtime["last_tip_followup_day_index"] = int(tip.get("followup_day_index", run_state.day_index))
	contacts[contact_id] = runtime
	run_state.set_network_contacts(contacts)


func _network_reaction_is_due(tip: Dictionary, day_index: int) -> bool:
	if not tip.has("reaction_due_day_index"):
		return false
	if bool(tip.get("reaction_sent", false)):
		return false
	var contact_id: String = str(tip.get("contact_id", ""))
	if contact_id.is_empty():
		return false
	var due_day_index: int = int(tip.get("reaction_due_day_index", tip.get("resolve_day_index", int(tip.get("created_day_index", 0)) + TIP_MEMORY_RESOLVE_DAYS)))
	return due_day_index <= day_index


func _apply_network_followup_reaction(run_state, data_repository, source_tip: Dictionary) -> Dictionary:
	var contacts: Dictionary = run_state.get_network_contacts()
	var result: Dictionary = _apply_network_followup_reaction_with_contacts(run_state, data_repository, source_tip, contacts)
	if bool(result.get("_contacts_changed", false)):
		run_state.set_network_contacts(contacts)
	result.erase("_contacts_changed")
	return result


func _apply_network_followup_reaction_with_contacts(run_state, data_repository, source_tip: Dictionary, contacts: Dictionary) -> Dictionary:
	var tip: Dictionary = source_tip.duplicate(true)
	var contact_id: String = str(tip.get("contact_id", ""))
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	if contact.is_empty():
		contact = {
			"id": contact_id,
			"display_name": str(tip.get("contact_name", "Contact")),
			"role": "Network contact",
			"affiliation_type": "floater"
	}
	var reaction: Dictionary = _build_network_followup_reaction(run_state, contact, tip)
	var relationship_delta: int = int(reaction.get("relationship_delta", 0))
	var contacts_changed: bool = false
	if relationship_delta != 0:
		contacts_changed = _adjust_relationship_in_contacts(contacts, contact_id, relationship_delta) or contacts_changed
	var account: Dictionary = _reaction_twooter_account(run_state, contact, tip)
	var account_id: String = str(account.get("id", tip.get("twooter_account_id", "")))
	var handle: String = str(account.get("handle", tip.get("twooter_handle", "")))
	if not account_id.is_empty():
		_append_twooter_account_message(
			run_state,
			account,
			NETWORK_REACTION_ACTION_ID,
			str(reaction.get("note", "")),
			run_state.day_index
		)
	tip["reaction_sent"] = true
	tip["reaction_day_index"] = run_state.day_index
	tip["reaction_label"] = str(reaction.get("label", "Follow-up"))
	tip["reaction_note"] = str(reaction.get("note", ""))
	tip["reaction_relationship_delta"] = relationship_delta
	tip["reaction_reliability_delta"] = int(reaction.get("reliability_delta", 0))
	tip["reaction_twooter_account_id"] = account_id
	tip["reaction_twooter_handle"] = handle
	contacts_changed = _store_contact_reaction_in_contacts(contacts, tip, run_state.day_index) or contacts_changed
	return {
		"success": true,
		"tip": tip,
		"reaction": reaction,
		"twooter_account_id": account_id,
		"_contacts_changed": contacts_changed
	}


func _build_network_followup_reaction(run_state, contact: Dictionary, tip: Dictionary) -> Dictionary:
	if bool(tip.get("source_only", false)) or str(tip.get("journal_type", "")) == TIP_JOURNAL_TYPE_TWOOTER_SOCIAL:
		return _build_source_only_reaction(run_state, contact, tip)
	var ticker: String = str(tip.get("target_ticker", tip.get("target_company_id", ""))).strip_edges().to_upper()
	if ticker.is_empty():
		ticker = "the read"
	var outcome_label: String = str(tip.get("outcome_label", OUTCOME_LABEL_STILL_PENDING))
	var player_alignment: String = str(tip.get("player_action_alignment", "neutral"))
	var player_action_label: String = str(tip.get("player_action_label", "No action"))
	var read_was_good: bool = outcome_label in GOOD_OUTCOME_LABELS
	var read_was_bad: bool = outcome_label == OUTCOME_LABEL_MISSED_BADLY
	if read_was_good and player_alignment == "followed":
		return {
			"label": "Good follow-through",
			"note": "Follow-up on %s: the read aged well, and you handled it with discipline. Keep the next position tied to confirmation, not excitement." % ticker,
			"relationship_delta": 1,
			"reliability_delta": 1
		}
	if read_was_good and player_alignment == "ignored":
		return {
			"label": "Useful read missed",
			"note": "Follow-up on %s: the signal worked, but you left it alone. That is not a failure; next time decide what confirmation would make you act." % ticker,
			"relationship_delta": 0,
			"reliability_delta": 1
		}
	if read_was_bad and player_alignment == "followed":
		return {
			"label": "Read aged poorly",
			"note": "Follow-up on %s: that read aged poorly, and following it too closely cost trust in the setup. Size smaller when the evidence is still soft." % ticker,
			"relationship_delta": -1,
			"reliability_delta": -1
		}
	if read_was_bad and player_alignment in ["ignored", "against"]:
		return {
			"label": "Good restraint",
			"note": "Follow-up on %s: restraint was the right call. The source was noisy, and waiting for confirmation protected you." % ticker,
			"relationship_delta": 1,
			"reliability_delta": -1
		}
	return {
		"label": "Still developing",
		"note": "Follow-up on %s: the read is still not clean enough to score. Your action was %s; keep watching the next filing, volume, or date catalyst." % [ticker, player_action_label.to_lower()],
		"relationship_delta": 0,
		"reliability_delta": 0
	}


func _build_source_only_reaction(run_state, contact: Dictionary, tip: Dictionary) -> Dictionary:
	var contact_id: String = str(tip.get("contact_id", contact.get("id", "")))
	var action_id: String = str(tip.get("twooter_action_id", "message_check_in"))
	var handle: String = str(tip.get("twooter_handle", _contact_twooter_handle(contact))).strip_edges()
	var target: String = str(tip.get("target_ticker", "")).strip_edges().to_upper()
	var target_text: String = " on $%s" % target if not target.is_empty() else ""
	var is_met: bool = bool(run_state.get_network_contacts().get(contact_id, {}).get("met", false))
	match action_id:
		"connect":
			return {
				"label": "Connection warmed",
				"note": "%s follow-up%s: clean boundary, clean channel. I can keep this line open if the next ask comes with evidence." % [handle if not handle.is_empty() else "Source", target_text],
				"relationship_delta": 1,
				"reliability_delta": 0
			}
		"ask_tip":
			return {
				"label": "Read requested",
				"note": "%s follow-up%s: the read is useful only if you keep it public and sized properly. Bring a thesis next time, not just urgency." % [handle if not handle.is_empty() else "Source", target_text],
				"relationship_delta": 0,
				"reliability_delta": 0
			}
		"respond_suspicious_request":
			return {
				"label": "Clean boundary",
				"note": "%s follow-up%s: good refusal. Clean players are remembered because they do not make every source a liability." % [handle if not handle.is_empty() else "Source", target_text],
				"relationship_delta": 2,
				"reliability_delta": 1
			}
		_:
			var relationship_delta: int = 1 if not is_met else 0
			return {
				"label": "Source noted",
				"note": "%s follow-up%s: good first check-in. You kept the ask narrow; build the public trail before pushing for more." % [handle if not handle.is_empty() else "Source", target_text],
				"relationship_delta": relationship_delta,
				"reliability_delta": 0
			}


func _reaction_twooter_account(run_state, contact: Dictionary, tip: Dictionary) -> Dictionary:
	var discovery: Dictionary = run_state.get_network_discoveries().get(str(tip.get("contact_id", "")), {})
	if discovery.is_empty():
		discovery = {
			"target_company_id": str(tip.get("target_company_id", "")),
			"target_ticker": str(tip.get("target_ticker", ""))
		}
	var account: Dictionary = _contact_twooter_account(contact, discovery, run_state)
	if str(account.get("id", "")).is_empty() and not str(tip.get("twooter_account_id", "")).is_empty():
		account = {
			"id": str(tip.get("twooter_account_id", "")),
			"display_name": str(tip.get("contact_name", "Contact")),
			"handle": str(tip.get("twooter_handle", "")),
			"social_profile": {
				"network_contact_id": str(tip.get("contact_id", "")),
				"account_origin": "network_contact"
			}
		}
	return account


func _append_twooter_account_message(run_state, account: Dictionary, action_id: String, text: String, day_index: int) -> void:
	var account_id: String = str(account.get("id", ""))
	if account_id.is_empty() or text.strip_edges().is_empty():
		return
	var social_state: Dictionary = run_state.get_twooter_social_state()
	var messages: Dictionary = social_state.get("messages", {}) if typeof(social_state.get("messages", {})) == TYPE_DICTIONARY else {}
	var thread: Dictionary = messages.get(account_id, {}) if typeof(messages.get(account_id, {})) == TYPE_DICTIONARY else {}
	var rows: Array = thread.get("rows", []) if typeof(thread.get("rows", [])) == TYPE_ARRAY else []
	rows.append({
		"sender": "account",
		"action_id": action_id,
		"text": text,
		"day_index": day_index
	})
	if rows.size() > MAX_SOCIAL_MESSAGE_ROWS_PER_THREAD:
		rows = rows.slice(rows.size() - MAX_SOCIAL_MESSAGE_ROWS_PER_THREAD, rows.size())
	thread["account_id"] = account_id
	thread["account_name"] = str(account.get("display_name", thread.get("account_name", "Contact")))
	thread["account_handle"] = str(account.get("handle", thread.get("account_handle", "")))
	thread["rows"] = rows
	thread["last_day_index"] = day_index
	thread["unread_count"] = int(thread.get("unread_count", 0)) + 1
	messages[account_id] = thread
	social_state["messages"] = messages
	run_state.set_twooter_social_state(social_state)


func _store_contact_reaction(run_state, tip: Dictionary) -> void:
	var contacts: Dictionary = run_state.get_network_contacts()
	if _store_contact_reaction_in_contacts(contacts, tip, run_state.day_index):
		run_state.set_network_contacts(contacts)


func _store_contact_reaction_in_contacts(contacts: Dictionary, tip: Dictionary, default_day_index: int) -> bool:
	var contact_id: String = str(tip.get("contact_id", ""))
	if contact_id.is_empty():
		return false
	var runtime: Dictionary = contacts.get(contact_id, {})
	runtime["last_reaction_label"] = str(tip.get("reaction_label", ""))
	runtime["last_reaction_note"] = str(tip.get("reaction_note", ""))
	runtime["last_reaction_day_index"] = int(tip.get("reaction_day_index", default_day_index))
	runtime["last_reaction_twooter_account_id"] = str(tip.get("reaction_twooter_account_id", ""))
	runtime["last_reaction_twooter_handle"] = str(tip.get("reaction_twooter_handle", ""))
	contacts[contact_id] = runtime
	return true


func _latest_reaction_notes_by_contact(run_state) -> Dictionary:
	var notes: Dictionary = {}
	for tip_value in run_state.get_network_tip_journal().values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		if not bool(tip.get("reaction_sent", false)):
			continue
		var contact_id: String = str(tip.get("contact_id", ""))
		if contact_id.is_empty():
			continue
		var existing: Dictionary = notes.get(contact_id, {})
		if existing.is_empty() or int(tip.get("reaction_day_index", 0)) >= int(existing.get("reaction_day_index", 0)):
			notes[contact_id] = tip.duplicate(true)
	return notes


func _apply_latest_reaction(row: Dictionary, reaction_notes: Dictionary) -> void:
	var contact_id: String = str(row.get("id", ""))
	_apply_decorator(row, reaction_notes, contact_id, LATEST_REACTION_FIELD_MAP, LATEST_REACTION_DEFAULTS)


func _latest_development_leads_by_contact(run_state) -> Dictionary:
	var notes: Dictionary = {}
	var life_state: Dictionary = run_state.get_player_life()
	for lead_value in life_state.get("development_leads", []):
		if typeof(lead_value) != TYPE_DICTIONARY:
			continue
		var lead: Dictionary = lead_value
		var contact_id: String = str(lead.get("contact_id", ""))
		if contact_id.is_empty():
			continue
		var existing: Dictionary = notes.get(contact_id, {})
		if existing.is_empty() or int(lead.get("discovered_day_index", 0)) >= int(existing.get("discovered_day_index", 0)):
			notes[contact_id] = lead.duplicate(true)
	return notes


func _apply_latest_development_lead(row: Dictionary, development_lead_notes: Dictionary) -> void:
	var contact_id: String = str(row.get("id", ""))
	_apply_decorator(row, development_lead_notes, contact_id, DEVELOPMENT_LEAD_FIELD_MAP, DEVELOPMENT_LEAD_DEFAULTS)


func _apply_decorator(row: Dictionary, lookup: Dictionary, contact_id: String, field_map: Array, defaults: Array) -> bool:
	var source: Dictionary = lookup.get(contact_id, {}) if not contact_id.is_empty() else {}
	if source.is_empty():
		_apply_decorator_defaults(row, defaults)
		return false
	for rule_value in field_map:
		if typeof(rule_value) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_value
		var target: String = str(rule.get("target", ""))
		if target.is_empty():
			continue
		row[target] = _decorator_rule_value(source, rule)
	return true


func _apply_decorator_defaults(row: Dictionary, defaults: Array) -> void:
	for default_value in defaults:
		if typeof(default_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = default_value
		var target: String = str(entry.get("target", ""))
		if target.is_empty():
			continue
		row[target] = _decorator_copy_value(entry.get("value", null))


func _decorator_rule_value(source: Dictionary, rule: Dictionary) -> Variant:
	var default_value: Variant = rule.get("default", null)
	var value: Variant = default_value
	var method_name: String = str(rule.get("method", ""))
	if not method_name.is_empty() and has_method(method_name):
		value = call(method_name, source)
	else:
		var source_key: String = str(rule.get("source", ""))
		if not source_key.is_empty():
			value = source.get(source_key, default_value)
	return _decorator_cast_value(value, str(rule.get("type", "")), default_value)


func _decorator_cast_value(value: Variant, type_name: String, default_value: Variant) -> Variant:
	match type_name:
		"string":
			return str(value)
		"int":
			return int(value)
		"float":
			return float(value)
		"bool":
			return bool(value)
		"array_duplicate":
			var array_value: Variant = value if typeof(value) == TYPE_ARRAY else default_value
			if typeof(array_value) == TYPE_ARRAY:
				return array_value.duplicate(true)
			return []
		"dictionary_duplicate":
			var dictionary_value: Variant = value if typeof(value) == TYPE_DICTIONARY else default_value
			if typeof(dictionary_value) == TYPE_DICTIONARY:
				return dictionary_value.duplicate(true)
			return {}
		_:
			return _decorator_copy_value(value)


func _decorator_copy_value(value: Variant) -> Variant:
	if typeof(value) == TYPE_ARRAY or typeof(value) == TYPE_DICTIONARY:
		return value.duplicate(true)
	return value


func _decorator_development_lead_label(lead: Dictionary) -> String:
	var theme_label: String = str(lead.get("display_theme_label", lead.get("theme_label", lead.get("theme", "Development")))).capitalize()
	var location_label: String = str(lead.get("display_location_label", lead.get("location_label", lead.get("location_id", ""))))
	return "%s | %s" % [location_label, theme_label]


func _decorator_development_lead_note(lead: Dictionary) -> String:
	var clarity_label: String = str(lead.get("clarity_label", "")).strip_edges()
	return "%s%s" % [
		"%s. " % clarity_label if not clarity_label.is_empty() else "",
		str(lead.get("source_note", ""))
	]


func _decorator_development_lead_location(lead: Dictionary) -> String:
	return str(lead.get("display_location_label", lead.get("location_label", lead.get("location_id", ""))))


func _last_tip_notes_by_contact(run_state) -> Dictionary:
	var notes: Dictionary = {}
	for tip_value in run_state.get_network_tip_journal().values():
		var tip: Dictionary = tip_value
		var contact_id: String = str(tip.get("contact_id", ""))
		if contact_id.is_empty():
			continue
		if str(tip.get("status", TIP_STATUS_PENDING)) == TIP_STATUS_PENDING:
			continue
		var existing: Dictionary = notes.get(contact_id, {})
		if existing.is_empty() or int(tip.get("resolved_day_index", 0)) >= int(existing.get("resolved_day_index", 0)):
			notes[contact_id] = tip.duplicate(true)
	return notes


func _apply_last_tip_note(row: Dictionary, last_tip_notes: Dictionary) -> void:
	var contact_id: String = str(row.get("id", ""))
	_apply_decorator(row, last_tip_notes, contact_id, LAST_TIP_NOTE_FIELD_MAP, [])


func _decorator_tip_can_follow_up(note: Dictionary) -> bool:
	return str(note.get("followup_id", "")).is_empty()


func _decorator_tip_followup_options(note: Dictionary) -> Array:
	return _tip_followup_options(note)


func _tip_histories_by_contact(run_state) -> Dictionary:
	return NETWORK_TIP_RESOLVER_SCRIPT.tip_histories_by_contact(run_state.get_network_tip_journal())


func _tip_history_row(tip: Dictionary) -> Dictionary:
	return NETWORK_TIP_RESOLVER_SCRIPT.tip_history_row(tip)


func _tip_history_summary(rows: Array) -> Dictionary:
	return NETWORK_TIP_RESOLVER_SCRIPT.tip_history_summary(rows)


func _tip_reliability_label(resolved_count: int, useful_count: int, missed_count: int, reliability_score: float) -> String:
	return NETWORK_TIP_RESOLVER_SCRIPT.tip_reliability_label(resolved_count, useful_count, missed_count, reliability_score)


func _apply_tip_history(row: Dictionary, tip_histories: Dictionary) -> void:
	var contact_id: String = str(row.get("id", ""))
	_apply_decorator(row, tip_histories, contact_id, TIP_HISTORY_FIELD_MAP, TIP_HISTORY_DEFAULTS)


func _cross_contact_reads_by_contact(run_state) -> Dictionary:
	return NETWORK_TIP_RESOLVER_SCRIPT.cross_contact_reads_by_contact(run_state.get_network_tip_journal(), run_state.day_index)


func _cross_contact_read_row(tip: Dictionary) -> Dictionary:
	return NETWORK_TIP_RESOLVER_SCRIPT.cross_contact_read_row(tip)


func _cross_contact_summary(current: Dictionary, peers: Array) -> Dictionary:
	return NETWORK_TIP_RESOLVER_SCRIPT.cross_contact_summary(current, peers)


func _truth_stance(truth_label: String) -> String:
	return NETWORK_TIP_RESOLVER_SCRIPT.truth_stance(truth_label)


func _truth_stances_conflict(a: String, b: String) -> bool:
	return NETWORK_TIP_RESOLVER_SCRIPT.truth_stances_conflict(a, b)


func _apply_cross_contact_read(row: Dictionary, cross_checks: Dictionary) -> void:
	var contact_id: String = str(row.get("id", ""))
	_apply_decorator(row, cross_checks, contact_id, CROSS_CONTACT_FIELD_MAP, CROSS_CONTACT_DEFAULTS)


func _pruned_tip_journal(journal: Dictionary) -> Dictionary:
	var rows: Array = []
	for tip_value in journal.values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		rows.append(tip_value)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("created_day_index", 0)) > int(b.get("created_day_index", 0))
	)
	var pruned: Dictionary = {}
	for index in range(min(rows.size(), MAX_TIP_MEMORY_ROWS)):
		var tip: Dictionary = rows[index]
		pruned[str(tip.get("id", "tip_%d" % index))] = tip.duplicate(true)
	return pruned


func _latest_followup_tip_for_contact(run_state, contact_id: String) -> Dictionary:
	var candidates: Array = []
	for tip_value in run_state.get_network_tip_journal().values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		if str(tip.get("contact_id", "")) != contact_id:
			continue
		if str(tip.get("status", TIP_STATUS_PENDING)) == TIP_STATUS_PENDING:
			continue
		if not str(tip.get("followup_id", "")).is_empty():
			continue
		candidates.append(tip.duplicate(true))
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("resolved_day_index", 0)) > int(b.get("resolved_day_index", 0))
	)
	if candidates.is_empty():
		return {}
	return candidates[0]


func _tip_followup_options(tip: Dictionary) -> Array:
	return NETWORK_TIP_RESOLVER_SCRIPT.tip_followup_options(tip)


func _build_tip_followup_result(contact: Dictionary, tip: Dictionary, followup_id: String) -> Dictionary:
	return NETWORK_TIP_RESOLVER_SCRIPT.build_tip_followup_result(contact, tip, followup_id)


func _build_source_check_response(contact: Dictionary, run_state, source_check: Dictionary) -> Dictionary:
	return NETWORK_TIP_RESOLVER_SCRIPT.build_source_check_response(contact, run_state, source_check)


func _source_check_evidence_phrase(contact: Dictionary, source_role: String) -> String:
	return NETWORK_TIP_RESOLVER_SCRIPT.source_check_evidence_phrase(contact, source_role)


func _tip_followup_explanation(contact_name: String, truth_label: String, outcome_label: String, player_action_label: String) -> String:
	return NETWORK_TIP_RESOLVER_SCRIPT.tip_followup_explanation(contact_name, truth_label, outcome_label, player_action_label)


func _chain_by_id(run_state, chain_id: String) -> Dictionary:
	if chain_id.is_empty():
		return {}
	return run_state.get_active_corporate_action_chains().get(chain_id, {}).duplicate(true)


func _build_public_tip_read(
	run_state,
	_data_repository,
	contact: Dictionary,
	company_id: String,
	chain: Dictionary,
	intel_quality: String
) -> Dictionary:
	var ticker: String = _company_ticker(run_state, company_id)
	var family_label: String = _public_family_label(str(chain.get("family", "")))
	if family_label.is_empty():
		family_label = "story"
	var truth_label: String = _public_truth_label(contact, chain, intel_quality)
	var confidence_label: String = _public_confidence_label(contact, intel_quality)
	var source_role: String = _contact_tip_voice(contact)
	var read: String = _public_tip_opening(truth_label, ticker, family_label)
	var color: String = _public_tip_source_color(contact, source_role, ticker)
	if not color.is_empty():
		read += " " + color
	var watch_note: String = _public_tip_watch_note(truth_label, chain)
	if not watch_note.is_empty():
		read += " " + watch_note
	return {
		"truth_label": truth_label,
		"confidence_label": confidence_label,
		"source_role": source_role,
		"tip_read": read.strip_edges()
	}


func _public_tip_opening(truth_label: String, ticker: String, family_label: String) -> String:
	match truth_label:
		TRUTH_LABEL_REAL_BUT_DELAYED:
			return "%s still looks live, but the timing is no longer clean." % ticker
		TRUTH_LABEL_ROOM_RISK:
			return "%s has a real %s path, but the room can still reset the trade." % [ticker, family_label]
		TRUTH_LABEL_FILING_BACKED:
			return "%s has moved past loose rumor; the paper trail is now doing the work." % ticker
		TRUTH_LABEL_ACCUMULATION:
			return "%s looks like a quiet accumulation story before the wider market fully agrees." % ticker
		TRUTH_LABEL_DISTRIBUTION_RISK:
			return "%s is getting crowded, and stronger hands may be selling into attention." % ticker
		TRUTH_LABEL_RETAIL_TRAP:
			return "%s has the shape of a crowded ritel chase rather than a clean confirmation." % ticker
		TRUTH_LABEL_EXECUTION_WATCH:
			return "%s cleared the noisy part; now the question is whether execution keeps pace." % ticker
		TRUTH_LABEL_DEAD_STORY:
			return "%s looks mostly spent for now; do not treat the old headline as fresh fuel." % ticker
		_:
			return "%s has a live read, but it is still early enough to demand confirmation." % ticker


func _public_tip_source_color(contact: Dictionary, source_role: String, _ticker: String) -> String:
	var reliability: float = clamp(float(contact.get("reliability", 0.6)), 0.0, 1.0)
	match source_role:
		"flow desk":
			return "The tape matters more than the headline here: watch whether bandar flow keeps absorbing ritel supply."
		"corporate desk":
			return "The useful signal is paperwork, agenda language, and whether a formal notice appears on schedule."
		"company room":
			return "The room sounds engaged, but support still has to survive the meeting and the next disclosure."
		"source book":
			return "Sources are willing to talk, although the public story is still catching up."
		"research desk":
			return "The thesis only gets cleaner if price action follows fundamentals instead of chat-room heat."
		_:
			if reliability >= 0.74:
				return "This is not a public confirmation, but the contact has been useful enough to keep it on the watchlist."
			return "Treat it as a lead, not a signal by itself."


func _public_tip_watch_note(truth_label: String, chain: Dictionary) -> String:
	match truth_label:
		TRUTH_LABEL_REAL_BUT_DELAYED:
			return "Wait for a fresh date, renewed accumulation, or a clearer boardroom cue."
		TRUTH_LABEL_ROOM_RISK:
			return "Meeting notices, attendance, and vote wording matter more than intraday noise."
		TRUTH_LABEL_FILING_BACKED:
			return "The next useful clue is whether the market buys the filing after the first reaction."
		TRUTH_LABEL_ACCUMULATION:
			return "If volume rises without the story getting too loud, the read improves."
		TRUTH_LABEL_DISTRIBUTION_RISK, TRUTH_LABEL_RETAIL_TRAP:
			return "Be careful if volume expands while the bid keeps slipping."
		TRUTH_LABEL_EXECUTION_WATCH:
			return "Follow-through now matters more than another headline."
		TRUTH_LABEL_DEAD_STORY:
			return "Only a new notice or hard reversal would make it worth reopening."
		_:
			if not str(chain.get("active_meeting_id", "")).is_empty():
				return "The calendar is the cleanest thing to track next."
			return "Confirmation should come from tape, filings, or a cleaner second source."


func _public_truth_label(contact: Dictionary, chain: Dictionary, intel_quality: String) -> String:
	if chain.is_empty():
		if str(contact.get("tone", "mixed")) == "negative":
			return TRUTH_LABEL_PRESSURE_READ
		return TRUTH_LABEL_NETWORK_READ
	var stage: String = str(chain.get("stage", ""))
	var timeline_state: String = str(chain.get("current_timeline_state", ""))
	var outcome_state: String = str(chain.get("outcome_state", ""))
	var smart_money_phase: String = str(chain.get("smart_money_phase", ""))
	var public_heat: float = float(chain.get("public_heat", 0.0))
	var retail_positioning: float = float(chain.get("retail_positioning", 0.0))
	var source_role: String = _contact_tip_voice(contact)
	if outcome_state == "cancelled" or timeline_state == "cancelled":
		return TRUTH_LABEL_DEAD_STORY
	if stage == "execution" or outcome_state == "approved":
		return TRUTH_LABEL_EXECUTION_WATCH
	if timeline_state == "delayed" or intel_quality == "very_strong":
		return TRUTH_LABEL_REAL_BUT_DELAYED
	if source_role == "flow desk" and public_heat >= 0.45 and retail_positioning >= 0.24:
		return TRUTH_LABEL_RETAIL_TRAP
	if stage == "meeting_or_call" or not str(chain.get("active_meeting_id", "")).is_empty():
		return TRUTH_LABEL_ROOM_RISK
	if smart_money_phase in ["distributing", "trapping"]:
		return TRUTH_LABEL_RETAIL_TRAP if public_heat >= 0.58 or retail_positioning >= 0.36 else TRUTH_LABEL_DISTRIBUTION_RISK
	if stage == "formal_agenda_or_filing":
		return TRUTH_LABEL_FILING_BACKED
	if smart_money_phase in ["accumulating", "re_accumulating"] and stage in ["hidden_positioning", "unusual_activity", "rumor_leak"]:
		return TRUTH_LABEL_ACCUMULATION
	if public_heat >= 0.64 and retail_positioning >= 0.34:
		return TRUTH_LABEL_RETAIL_TRAP
	return TRUTH_LABEL_EARLY_READ


func _public_confidence_label(contact: Dictionary, intel_quality: String) -> String:
	var reliability: float = clamp(float(contact.get("reliability", 0.6)), 0.0, 1.0)
	match intel_quality:
		"very_strong":
			return "High conviction"
		"strong":
			return "Grounded read" if reliability >= 0.64 else "Useful but partial"
		"medium":
			return "Early but credible"
		_:
			return "Soft read"


func _contact_tip_voice(contact: Dictionary) -> String:
	var haystack: String = "%s %s %s" % [
		str(contact.get("role", "")),
		str(contact.get("affiliation_role", "")),
		str(contact.get("intro", ""))
	]
	for category_value in contact.get("categories", []):
		haystack += " " + str(category_value)
	haystack = haystack.to_lower()
	if str(contact.get("affiliation_type", "floater")) == "insider":
		return "company room"
	if haystack.find("journal") >= 0 or haystack.find("media") >= 0 or haystack.find("news") >= 0:
		return "source book"
	if haystack.find("broker") >= 0 or haystack.find("flow") >= 0 or haystack.find("dealer") >= 0 or haystack.find("trader") >= 0:
		return "flow desk"
	if haystack.find("legal") >= 0 or haystack.find("law") >= 0 or haystack.find("corporate") >= 0 or haystack.find("disclosure") >= 0 or haystack.find("ojk") >= 0:
		return "corporate desk"
	if haystack.find("analyst") >= 0 or haystack.find("research") >= 0 or haystack.find("fund") >= 0 or haystack.find("investor") >= 0:
		return "research desk"
	return "market contact"


func _active_corporate_chain_for_company(run_state, company_id: String) -> Dictionary:
	var rows: Array = []
	for chain_value in run_state.get_active_corporate_action_chains().values():
		var chain: Dictionary = chain_value
		if str(chain.get("company_id", "")) == company_id and str(chain.get("status", "active")) != "completed":
			rows.append(chain.duplicate(true))
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("started_day_index", 0)) > int(b.get("started_day_index", 0))
	)
	if rows.is_empty():
		return {}
	return rows[0]


func _company_ticker(run_state, company_id: String) -> String:
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	return str(definition.get("ticker", company_id.to_upper()))


func _public_family_label(family_id: String) -> String:
	match family_id:
		"rights_issue":
			return "rights issue"
		"private_placement":
			return "private placement"
		"stock_split":
			return "stock split"
		"stock_buyback":
			return "buyback"
		"merger_acquisition":
			return "deal"
		"ceo_change":
			return "leadership change"
		"dividend_special":
			return "special dividend"
		"stock_dividend":
			return "stock dividend"
		_:
			return family_id.replace("_", " ")


func _ensure_meeting_leads(run_state, data_repository, session_snapshot: Dictionary) -> Array:
	var meeting_id: String = str(session_snapshot.get("meeting_id", ""))
	if meeting_id.is_empty():
		return []
	var sessions: Dictionary = run_state.get_corporate_meeting_sessions()
	var session: Dictionary = sessions.get(meeting_id, session_snapshot.get("session", {})).duplicate(true)
	var existing_leads: Array = session.get("meeting_leads", []).duplicate(true)
	if not existing_leads.is_empty():
		var profile_lookup: Dictionary = {}
		for profile_value in data_repository.get_contact_network_data().get("meeting_lead_profiles", []):
			if typeof(profile_value) != TYPE_DICTIONARY:
				continue
			var profile: Dictionary = profile_value
			profile_lookup[str(profile.get("id", ""))] = profile
		var changed_existing_leads: bool = false
		for lead_index in range(existing_leads.size()):
			if typeof(existing_leads[lead_index]) != TYPE_DICTIONARY:
				continue
			var lead: Dictionary = existing_leads[lead_index].duplicate(true)
			var stage_speech_bubbles_value = lead.get("stage_speech_bubbles", {})
			if typeof(stage_speech_bubbles_value) == TYPE_DICTIONARY and not stage_speech_bubbles_value.is_empty():
				continue
			var profile_id: String = str(lead.get("profile_id", ""))
			var profile: Dictionary = profile_lookup.get(profile_id, {})
			if typeof(profile.get("stage_speech_bubbles", {})) != TYPE_DICTIONARY:
				continue
			lead["stage_speech_bubbles"] = profile.get("stage_speech_bubbles", {}).duplicate(true)
			existing_leads[lead_index] = lead
			changed_existing_leads = true
		if changed_existing_leads:
			session["meeting_leads"] = existing_leads
			sessions[meeting_id] = session
			run_state.set_corporate_meeting_sessions(sessions)
		return existing_leads
	var meeting: Dictionary = session_snapshot.get("meeting", {})
	var leads: Array = _build_meeting_leads(run_state, data_repository, meeting_id, meeting)
	session["meeting_leads"] = leads
	if not session.has("approached_lead_ids"):
		session["approached_lead_ids"] = []
	if not session.has("meeting_lead_results"):
		session["meeting_lead_results"] = {}
	sessions[meeting_id] = session
	run_state.set_corporate_meeting_sessions(sessions)
	return leads


func _build_meeting_leads(run_state, data_repository, meeting_id: String, meeting: Dictionary) -> Array:
	var network_data: Dictionary = data_repository.get_contact_network_data()
	var profiles: Array = network_data.get("meeting_lead_profiles", []).duplicate(true)
	profiles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_rank: int = _meeting_lead_tier_rank(str(a.get("tier", "open")))
		var b_rank: int = _meeting_lead_tier_rank(str(b.get("tier", "open")))
		if a_rank != b_rank:
			return a_rank < b_rank
		return str(a.get("id", "")) < str(b.get("id", ""))
	)
	var company_id: String = str(meeting.get("company_id", ""))
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	var sector_id: String = str(definition.get("sector_id", meeting.get("target_sector_id", "")))
	var used_contact_ids := {}
	var leads: Array = []
	for profile_value in profiles:
		if typeof(profile_value) != TYPE_DICTIONARY:
			continue
		var profile: Dictionary = profile_value
		var contact: Dictionary = _best_meeting_lead_contact(
			run_state,
			data_repository,
			profile,
			company_id,
			sector_id,
			used_contact_ids
		)
		if contact.is_empty():
			continue
		var contact_id: String = str(contact.get("id", ""))
		used_contact_ids[contact_id] = true
		var profile_id: String = str(profile.get("id", "lead"))
		var lead_id: String = "%s|lead|%s" % [meeting_id, profile_id]
		var speech_bubble: String = _pick_meeting_text(profile.get("speech_bubbles", []), [meeting_id, profile_id, contact_id, "bubble"], "There is something useful in the hallway chatter.")
		var stage_speech_bubbles: Dictionary = {}
		if typeof(profile.get("stage_speech_bubbles", {})) == TYPE_DICTIONARY:
			stage_speech_bubbles = profile.get("stage_speech_bubbles", {}).duplicate(true)
		leads.append({
			"lead_id": lead_id,
			"contact_id": contact_id,
			"profile_id": profile_id,
			"tier": str(profile.get("tier", "open")),
			"company_id": company_id,
			"target_sector_id": sector_id,
			"role_label": str(profile.get("role_label", contact.get("role", "Meeting Attendee"))),
			"recognition_required": max(int(profile.get("recognition_required", 0)), int(contact.get("recognition_required", 0))),
			"speech_bubble": speech_bubble,
			"stage_speech_bubbles": stage_speech_bubbles,
			"approach_prompt": str(profile.get("approach_prompt", "Approach this attendee.")),
			"success_responses": profile.get("success_responses", []).duplicate(true),
			"locked_copy": str(profile.get("locked_copy", "This attendee is not ready to talk yet."))
		})
		if leads.size() >= MAX_MEETING_LEADS:
			break
	return leads


func _best_meeting_lead_contact(
	run_state,
	data_repository,
	profile: Dictionary,
	company_id: String,
	sector_id: String,
	used_contact_ids: Dictionary
) -> Dictionary:
	var candidates: Array = []
	for contact_value in data_repository.get_contact_network_data().get("contacts", []):
		if typeof(contact_value) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = contact_value
		var contact_id: String = str(contact.get("id", ""))
		if contact_id.is_empty() or used_contact_ids.has(contact_id):
			continue
		if str(contact.get("affiliation_type", "floater")) != "floater":
			continue
		if not _meeting_profile_matches_contact(profile, contact, sector_id):
			continue
		candidates.append({
			"contact": contact,
			"score": _meeting_lead_contact_score(run_state, contact, profile, company_id, sector_id)
		})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_score: float = float(a.get("score", 0.0))
		var b_score: float = float(b.get("score", 0.0))
		if not is_equal_approx(a_score, b_score):
			return a_score > b_score
		return str(a.get("contact", {}).get("display_name", "")) < str(b.get("contact", {}).get("display_name", ""))
	)
	if candidates.is_empty():
		return {}
	return candidates[0].get("contact", {}).duplicate(true)


func _meeting_profile_matches_contact(profile: Dictionary, contact: Dictionary, sector_id: String) -> bool:
	return NETWORK_DISCOVERY_SCRIPT.meeting_profile_matches_contact(profile, contact, sector_id)


func _meeting_lead_contact_score(run_state, contact: Dictionary, profile: Dictionary, company_id: String, sector_id: String) -> float:
	return NETWORK_DISCOVERY_SCRIPT.meeting_lead_contact_score(run_state, contact, profile, company_id, sector_id)


func _meeting_lead_public_row(
	run_state,
	data_repository,
	session_snapshot: Dictionary,
	lead: Dictionary,
	can_spend_meet_action: bool,
	meet_action_cost: int
) -> Dictionary:
	var meeting: Dictionary = session_snapshot.get("meeting", {})
	var session: Dictionary = session_snapshot.get("session", {})
	var current_stage_id: String = str(session_snapshot.get("current_stage_id", session.get("presentation_stage", "arrival")))
	var contact_id: String = str(lead.get("contact_id", ""))
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	var definition: Dictionary = run_state.get_effective_company_definition(str(lead.get("company_id", meeting.get("company_id", ""))), false, false)
	var recognition: Dictionary = build_recognition_snapshot(run_state)
	var recognition_score: int = int(recognition.get("score", 0))
	var contact_met: bool = _is_met(run_state, contact_id)
	var approached: bool = _meeting_lead_is_approached(session, str(lead.get("lead_id", "")))
	var result: Dictionary = _meeting_lead_result(session, str(lead.get("lead_id", "")))
	var required_recognition: int = max(int(lead.get("recognition_required", 0)), int(contact.get("recognition_required", 0)))
	if _is_guided_first_hour_meeting(meeting) and str(lead.get("tier", "open")) == "open":
		required_recognition = 0
	var locked_copy: String = _format_meeting_lead_template(str(lead.get("locked_copy", "")).strip_edges(), lead, contact, meeting, definition)
	var locked_reason: String = ""
	if not approached:
		if current_stage_id == "result":
			locked_reason = "The meeting has ended. Approach attendees before the result board."
		elif recognition_score < required_recognition:
			locked_reason = "Need recognition %d to approach this attendee." % required_recognition
			if not locked_copy.is_empty():
				locked_reason = "%s Need recognition %d." % [locked_copy, required_recognition]
		elif not contact_met and _met_contact_count(run_state) >= int(recognition.get("contact_cap", 2)):
			locked_reason = "Your Network is full for this recognition tier."
		elif not can_spend_meet_action:
			locked_reason = "Need %d AP to approach this attendee." % meet_action_cost
	var revealed_name: String = str(contact.get("display_name", "Contact")) if contact_met or approached else ""
	var display_label: String = revealed_name if not revealed_name.is_empty() else str(lead.get("role_label", "Meeting Attendee"))
	return {
		"lead_id": str(lead.get("lead_id", "")),
		"contact_id": contact_id,
		"profile_id": str(lead.get("profile_id", "")),
		"tier": str(lead.get("tier", "open")),
		"company_id": str(lead.get("company_id", meeting.get("company_id", ""))),
		"role_label": str(lead.get("role_label", "Meeting Attendee")),
		"display_label": display_label,
		"revealed_name": revealed_name,
		"speech_bubble": _meeting_lead_stage_speech_bubble(lead, current_stage_id, contact_id, contact, meeting, definition),
		"speech_bubble_stage_id": current_stage_id,
		"approach_prompt": _format_meeting_lead_template(str(lead.get("approach_prompt", "Approach this attendee.")), lead, contact, meeting, definition),
		"recognition_required": required_recognition,
		"approachable": locked_reason.is_empty() and not approached,
		"locked_reason": str(result.get("response_text", "")) if approached else locked_reason,
		"locked_copy": locked_copy,
		"approached": approached,
		"response_text": str(result.get("response_text", "")),
		"ap_cost": meet_action_cost,
		"relationship": int(run_state.get_network_contacts().get(contact_id, {}).get("relationship", 0)),
		"met": contact_met
	}


func _meeting_lead_stage_speech_bubble(
	lead: Dictionary,
	current_stage_id: String,
	contact_id: String,
	contact: Dictionary,
	meeting: Dictionary,
	definition: Dictionary
) -> String:
	var fallback: String = _format_meeting_lead_template(str(lead.get("speech_bubble", "")), lead, contact, meeting, definition)
	var stage_rows: Array = []
	var stage_speech_bubbles_value = lead.get("stage_speech_bubbles", {})
	if typeof(stage_speech_bubbles_value) == TYPE_DICTIONARY:
		var stage_speech_bubbles: Dictionary = stage_speech_bubbles_value
		var raw_rows = stage_speech_bubbles.get(current_stage_id, [])
		if typeof(raw_rows) == TYPE_ARRAY:
			stage_rows = raw_rows
		elif typeof(raw_rows) == TYPE_STRING and not str(raw_rows).strip_edges().is_empty():
			stage_rows = [str(raw_rows)]
	if stage_rows.is_empty():
		return fallback
	var template: String = _pick_meeting_text(
		stage_rows,
		[str(lead.get("lead_id", "")), contact_id, current_stage_id, "stage_bubble"],
		fallback
	)
	return _format_meeting_lead_template(template, lead, contact, meeting, definition)


func _is_guided_first_hour_meeting(meeting: Dictionary) -> bool:
	return str(meeting.get("request_source", "")).strip_edges() == "guided_first_hour"


func _record_meeting_lead_discovery(
	run_state,
	contact: Dictionary,
	lead: Dictionary,
	meeting_id: String,
	company_id: String,
	definition: Dictionary
) -> void:
	var contact_id: String = str(contact.get("id", ""))
	if contact_id.is_empty():
		return
	var discoveries: Dictionary = run_state.get_network_discoveries()
	var discovery: Dictionary = discoveries.get(contact_id, {}).duplicate(true)
	var target_company_ids: Array = _contact_company_targets(discovery)
	if not company_id.is_empty() and not target_company_ids.has(company_id):
		target_company_ids.append(company_id)
	discovery["contact_id"] = contact_id
	discovery["discovered"] = true
	discovery["source_type"] = MEETING_LEAD_SOURCE_TYPE
	discovery["source_id"] = meeting_id
	discovery["meeting_id"] = meeting_id
	discovery["meeting_lead_id"] = str(lead.get("lead_id", ""))
	discovery["target_company_id"] = company_id if not company_id.is_empty() else str(discovery.get("target_company_id", ""))
	discovery["target_company_ids"] = target_company_ids
	discovery["target_sector_id"] = str(definition.get("sector_id", lead.get("target_sector_id", "")))
	discovery["lead_score"] = max(int(discovery.get("lead_score", 0)), 88)
	discovery["day_index"] = run_state.day_index
	discoveries[contact_id] = discovery
	run_state.set_network_discoveries(discoveries)


func _mark_meeting_contact_met(run_state, data_repository, contact: Dictionary, lead: Dictionary) -> void:
	var contact_id: String = str(contact.get("id", ""))
	if contact_id.is_empty():
		return
	var contacts: Dictionary = run_state.get_network_contacts()
	var runtime: Dictionary = contacts.get(contact_id, {}).duplicate(true)
	runtime["contact_id"] = contact_id
	runtime["met"] = true
	runtime["relationship"] = int(contact.get("base_relationship", data_repository.get_contact_network_data().get("relationship_default", 25)))
	runtime["met_day_index"] = run_state.day_index
	runtime["last_source_type"] = MEETING_LEAD_SOURCE_TYPE
	runtime["last_meeting_lead_id"] = str(lead.get("lead_id", ""))
	contacts[contact_id] = runtime
	run_state.set_network_contacts(contacts)


func _mark_contact_meeting_note(run_state, contact_id: String, response_text: String) -> void:
	if contact_id.is_empty():
		return
	var contacts: Dictionary = run_state.get_network_contacts()
	var runtime: Dictionary = contacts.get(contact_id, {}).duplicate(true)
	runtime["last_meeting_lead_note"] = response_text
	runtime["last_meeting_lead_day_index"] = run_state.day_index
	contacts[contact_id] = runtime
	run_state.set_network_contacts(contacts)


func _meeting_lead_response_text(lead: Dictionary, contact: Dictionary, meeting: Dictionary, definition: Dictionary, meeting_id: String) -> String:
	var template: String = _pick_meeting_text(
		lead.get("success_responses", []),
		[meeting_id, str(lead.get("lead_id", "")), str(contact.get("id", "")), "response"],
		"{contact} gives you a quick read on {ticker}. Treat it as context, not certainty."
	)
	return _format_meeting_lead_template(template, lead, contact, meeting, definition)


func _format_meeting_lead_template(template: String, lead: Dictionary, contact: Dictionary, meeting: Dictionary, definition: Dictionary) -> String:
	var company_id: String = str(lead.get("company_id", meeting.get("company_id", "")))
	var ticker: String = str(definition.get("ticker", company_id.to_upper()))
	var company_name: String = str(definition.get("name", meeting.get("company_name", ticker)))
	var agenda_label: String = "the agenda"
	var agenda_payload: Array = meeting.get("agenda_payload", [])
	if not agenda_payload.is_empty() and typeof(agenda_payload[0]) == TYPE_DICTIONARY:
		agenda_label = str(agenda_payload[0].get("label", agenda_label))
	var formatted_text: String = template
	formatted_text = formatted_text.replace("{contact}", str(contact.get("display_name", "The contact")))
	formatted_text = formatted_text.replace("{role}", str(lead.get("role_label", "attendee")))
	formatted_text = formatted_text.replace("{ticker}", ticker)
	formatted_text = formatted_text.replace("{company}", company_name)
	formatted_text = formatted_text.replace("{agenda}", agenda_label)
	return formatted_text


func _pick_meeting_text(text_rows: Array, seed_parts: Array, fallback: String) -> String:
	if text_rows.is_empty():
		return fallback
	var index: int = STABLE_RNG.seed_from_parts(seed_parts) % text_rows.size()
	return str(text_rows[index])


func _meeting_lead_tier_rank(tier_id: String) -> int:
	return NETWORK_DISCOVERY_SCRIPT.meeting_lead_tier_rank(tier_id)


func _meeting_lead_is_approached(session: Dictionary, lead_id: String) -> bool:
	return lead_id in session.get("approached_lead_ids", [])


func _meeting_lead_result(session: Dictionary, lead_id: String) -> Dictionary:
	return session.get("meeting_lead_results", {}).get(lead_id, {}).duplicate(true)


func _met_contact_count(run_state) -> int:
	var met_count: int = 0
	for runtime_value in run_state.get_network_contacts().values():
		if typeof(runtime_value) == TYPE_DICTIONARY and bool(runtime_value.get("met", false)):
			met_count += 1
	return met_count


func _all_contact_definitions(run_state, data_repository) -> Array:
	var definitions: Array = []
	for contact_value in data_repository.get_contact_network_data().get("contacts", []):
		var contact: Dictionary = contact_value
		definitions.append(contact.duplicate(true))
	definitions.append_array(_generated_insider_definitions(run_state))
	definitions.append_array(_generated_social_contact_definitions(run_state))
	return definitions


func _generated_insider_definitions(run_state) -> Array:
	var insiders: Array = []
	for company_id_value in run_state.company_order:
		var company_id: String = str(company_id_value)
		insiders.append_array(_management_roster_for_company(run_state, company_id))
	return insiders


func _generated_social_contact_definitions(run_state) -> Array:
	var rows: Array = []
	var social_state: Dictionary = run_state.get_twooter_social_state()
	for definition_value in social_state.get("network_contact_definitions", {}).values():
		if typeof(definition_value) != TYPE_DICTIONARY:
			continue
		rows.append(definition_value.duplicate(true))
	return rows


func _management_roster_for_company(run_state, company_id: String) -> Array:
	var profile: Dictionary = run_state.get_company_profile(company_id, false, false)
	var rows: Array = []
	for row_value in profile.get("management_roster", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value.duplicate(true)
		var contact_id: String = str(row.get("id", row.get("contact_id", "")))
		if contact_id.is_empty():
			contact_id = "insider_%s_%s" % [company_id, str(row.get("affiliation_role", "management"))]
		row["id"] = contact_id
		row["contact_id"] = contact_id
		var affiliation_type: String = str(row.get("affiliation_type", "insider"))
		row["affiliation_type"] = "insider" if affiliation_type.is_empty() else affiliation_type
		row["affiliated_company_id"] = str(row.get("affiliated_company_id", row.get("company_id", company_id)))
		row["company_id"] = str(row.get("company_id", company_id))
		rows.append(row)
	return rows


func _best_referral_insider(run_state, floater_id: String, company_id: String, affiliation_role: String) -> Dictionary:
	var discoveries: Dictionary = run_state.get_network_discoveries()
	var contacts: Dictionary = run_state.get_network_contacts()
	var candidates: Array = []
	for insider_value in _management_roster_for_company(run_state, company_id):
		var insider: Dictionary = insider_value
		if str(insider.get("affiliation_type", "insider")) != "insider":
			continue
		var insider_id: String = str(insider.get("id", insider.get("contact_id", "")))
		if insider_id.is_empty():
			continue
		if not affiliation_role.is_empty() and str(insider.get("affiliation_role", "")) != affiliation_role:
			continue
		if bool(contacts.get(insider_id, {}).get("met", false)) or bool(discoveries.get(insider_id, {}).get("discovered", false)):
			continue
		var score: int = _connection_score_for_floater(insider, floater_id)
		candidates.append({"insider": insider, "score": score})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)
	if candidates.is_empty():
		return {}
	return candidates[0].get("insider", {}).duplicate(true)


func _is_referral_required_contact(contact: Dictionary) -> bool:
	if str(contact.get("affiliation_type", "floater")) == "social":
		return false
	return int(contact.get("recognition_required", 0)) >= INNER_CIRCLE_REFERRAL_RECOGNITION_THRESHOLD


func _inner_circle_contact_is_unlocked(runtime: Dictionary, discovery: Dictionary) -> bool:
	if bool(runtime.get("met", false)):
		return true
	return str(discovery.get("source_type", "")) == "referral"


func _should_skip_public_contact_discovery(contact: Dictionary, contact_id: String, discoveries: Dictionary, contacts: Dictionary) -> bool:
	if not _is_referral_required_contact(contact):
		return false
	var runtime: Dictionary = contacts.get(contact_id, {}) if typeof(contacts.get(contact_id, {})) == TYPE_DICTIONARY else {}
	var discovery: Dictionary = discoveries.get(contact_id, {}) if typeof(discoveries.get(contact_id, {})) == TYPE_DICTIONARY else {}
	if _inner_circle_contact_is_unlocked(runtime, discovery):
		return true
	return true


func _is_inner_circle_referral_bridge(contact: Dictionary) -> bool:
	if str(contact.get("affiliation_type", "floater")) != "floater":
		return false
	var recognition_required: int = int(contact.get("recognition_required", 0))
	return recognition_required >= INNER_CIRCLE_BRIDGE_RECOGNITION_MIN and recognition_required < INNER_CIRCLE_BRIDGE_RECOGNITION_MAX


func _has_inner_circle_referral_trust_signal(runtime: Dictionary) -> bool:
	if int(runtime.get("relationship", 0)) >= INNER_CIRCLE_REFERRAL_TRUST_RELATIONSHIP:
		return true
	if str(runtime.get("last_tip_label", "")) in GOOD_OUTCOME_LABELS:
		return true
	if not str(runtime.get("last_tip_followup_id", "")).is_empty():
		return true
	return not str(runtime.get("last_reaction_label", "")).is_empty()


func _best_inner_circle_referral_contact(
	run_state,
	data_repository,
	bridge_contact: Dictionary,
	bridge_contact_id: String,
	company_id: String
) -> Dictionary:
	var discoveries: Dictionary = run_state.get_network_discoveries()
	var contacts: Dictionary = run_state.get_network_contacts()
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	var sector_id: String = str(definition.get("sector_id", ""))
	var candidates: Array = []
	for contact_value in data_repository.get_contact_network_data().get("contacts", []):
		if typeof(contact_value) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = contact_value
		var candidate_id: String = str(candidate.get("id", candidate.get("contact_id", "")))
		if candidate_id.is_empty() or candidate_id == bridge_contact_id:
			continue
		if str(candidate.get("affiliation_type", "floater")) != "floater":
			continue
		if not _is_referral_required_contact(candidate):
			continue
		var candidate_runtime: Dictionary = contacts.get(candidate_id, {}) if typeof(contacts.get(candidate_id, {})) == TYPE_DICTIONARY else {}
		var candidate_discovery: Dictionary = discoveries.get(candidate_id, {}) if typeof(discoveries.get(candidate_id, {})) == TYPE_DICTIONARY else {}
		if _inner_circle_contact_is_unlocked(candidate_runtime, candidate_discovery):
			continue
		var score: int = _inner_circle_referral_score(candidate, bridge_contact, sector_id)
		if score < REFERRAL_CONNECTION_THRESHOLD:
			continue
		candidates.append({"contact": candidate, "score": score})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)
	if candidates.is_empty():
		return {}
	return candidates[0].get("contact", {}).duplicate(true)


func _inner_circle_referral_score(candidate: Dictionary, bridge_contact: Dictionary, sector_id: String) -> int:
	var score: int = 0
	var candidate_sectors: Array = _string_array(candidate.get("sector_ids", []))
	var bridge_sectors: Array = _string_array(bridge_contact.get("sector_ids", []))
	if not sector_id.is_empty() and sector_id in candidate_sectors:
		score += 34
	if not sector_id.is_empty() and sector_id in bridge_sectors:
		score += 10
	score += min(_overlap_count(candidate_sectors, bridge_sectors), 3) * 8
	score += min(_overlap_count(_string_array(candidate.get("categories", [])), _string_array(bridge_contact.get("categories", []))), 3) * 10
	score += int(round(clamp(float(candidate.get("reliability", 0.5)), 0.0, 1.0) * 18.0))
	score += int(round(clamp(float(bridge_contact.get("reliability", 0.5)), 0.0, 1.0) * 8.0))
	score += max(0, int(candidate.get("recognition_required", 0)) - INNER_CIRCLE_REFERRAL_RECOGNITION_THRESHOLD) * 2
	return score


func _string_array(source: Variant) -> Array:
	var rows: Array = []
	if typeof(source) != TYPE_ARRAY:
		return rows
	for value in source:
		var text: String = str(value).strip_edges()
		if not text.is_empty() and not rows.has(text):
			rows.append(text)
	return rows


func _overlap_count(left: Array, right: Array) -> int:
	var count: int = 0
	for value in left:
		if right.has(value):
			count += 1
	return count


func _connection_score_for_floater(insider: Dictionary, floater_id: String) -> int:
	for bridge_value in insider.get("connected_floaters", []):
		if typeof(bridge_value) != TYPE_DICTIONARY:
			continue
		var bridge: Dictionary = bridge_value
		if str(bridge.get("contact_id", "")) == floater_id:
			return int(bridge.get("score", 0))
	return 0


func _contact_definition(run_state, data_repository, contact_id: String) -> Dictionary:
	for contact_value in data_repository.get_contact_network_data().get("contacts", []):
		var contact: Dictionary = contact_value
		if str(contact.get("id", "")) == contact_id:
			return contact.duplicate(true)
	for insider_value in _generated_insider_definitions(run_state):
		var insider: Dictionary = insider_value
		if str(insider.get("id", insider.get("contact_id", ""))) == contact_id:
			return insider.duplicate(true)
	for social_value in _generated_social_contact_definitions(run_state):
		var social_contact: Dictionary = social_value
		if str(social_contact.get("id", social_contact.get("contact_id", ""))) == contact_id:
			return social_contact.duplicate(true)
	return {}


func _contact_row(contact: Dictionary, runtime: Dictionary, discovery: Dictionary, recognition: Dictionary) -> Dictionary:
	return NETWORK_CONTACT_PRESENTER_SCRIPT.contact_row(contact, runtime, discovery, recognition, NETWORK_TWOOTER_ACCOUNT_PREFIX)


func _apply_access_provenance(row: Dictionary, contact: Dictionary, discovery: Dictionary, run_state, data_repository) -> void:
	var source_type: String = str(discovery.get("source_type", "")).strip_edges().to_lower()
	var access_label: String = _access_label_for_contact(contact, discovery)
	var provenance_label: String = access_label
	if provenance_label.is_empty():
		provenance_label = _source_type_label_for_snapshot(source_type)
	row["access_label"] = access_label
	row["provenance_label"] = provenance_label
	if source_type != "referral":
		return
	var source_contact_id: String = str(discovery.get("referred_by_contact_id", discovery.get("source_id", ""))).strip_edges()
	var source_name: String = str(_contact_display_name(run_state, data_repository, source_contact_id)) if not source_contact_id.is_empty() else ""
	var referral_day_index: int = int(discovery.get("referral_day_index", discovery.get("day_index", -9999)))
	row["referred_by_contact_id"] = source_contact_id
	row["referred_by_contact_name"] = source_name
	row["referral_day_index"] = referral_day_index
	row["referral_day_label"] = "Day %d" % referral_day_index if referral_day_index >= 0 else ""
	var note_parts: Array = []
	if not source_name.is_empty():
		note_parts.append("%s from %s." % [access_label if not access_label.is_empty() else "Private referral", source_name])
	if referral_day_index >= 0:
		note_parts.append("Introduced on day %d." % referral_day_index)
	if int(discovery.get("connection_score", 0)) > 0:
		note_parts.append("Connection score %d." % int(discovery.get("connection_score", 0)))
	row["referral_note"] = " ".join(note_parts).strip_edges()


func _access_label_for_contact(contact: Dictionary, discovery: Dictionary) -> String:
	var source_type: String = str(discovery.get("source_type", "")).strip_edges().to_lower()
	if source_type != "referral":
		return ""
	var privacy_gate: String = str(discovery.get("privacy_gate", "")).strip_edges()
	var referral_required: bool = bool(discovery.get("referral_required", false))
	if privacy_gate == INNER_CIRCLE_REFERRAL_ROLE or referral_required or int(contact.get("recognition_required", 0)) >= INNER_CIRCLE_REFERRAL_RECOGNITION_THRESHOLD:
		return "Inner-circle contact"
	return "Private referral"


func _source_type_label_for_snapshot(source_type: String) -> String:
	match source_type:
		"news":
			return "News lead"
		"twooter":
			return "Twooter lead"
		"referral":
			return "Private referral"
		MEETING_LEAD_SOURCE_TYPE:
			return "RUPSLB room"
		"manual":
			return "Manual note"
		"debug":
			return "Test lead"
		_:
			return "Network lead"


func _contact_twooter_account(contact: Dictionary, discovery: Dictionary = {}, run_state = null) -> Dictionary:
	return NETWORK_CONTACT_PRESENTER_SCRIPT.contact_twooter_account(contact, discovery, run_state, NETWORK_TWOOTER_ACCOUNT_PREFIX)


func _contact_twooter_account_id(contact: Dictionary) -> String:
	return NETWORK_CONTACT_PRESENTER_SCRIPT.contact_twooter_account_id(contact, NETWORK_TWOOTER_ACCOUNT_PREFIX)


func _contact_twooter_handle(contact: Dictionary) -> String:
	return NETWORK_CONTACT_PRESENTER_SCRIPT.contact_twooter_handle(contact)


func _contact_twooter_target_company_id(contact: Dictionary, discovery: Dictionary) -> String:
	return NETWORK_CONTACT_PRESENTER_SCRIPT.contact_twooter_target_company_id(contact, discovery)


func _contact_twooter_description(contact: Dictionary) -> String:
	return NETWORK_CONTACT_PRESENTER_SCRIPT.contact_twooter_description(contact)


func _contact_twooter_dialog_trees(contact: Dictionary) -> Array:
	return NETWORK_CONTACT_PRESENTER_SCRIPT.contact_twooter_dialog_trees(contact)


func _contact_twooter_risk_profile(contact: Dictionary) -> String:
	return NETWORK_CONTACT_PRESENTER_SCRIPT.contact_twooter_risk_profile(contact)


func _contact_twooter_follow_weight(contact: Dictionary) -> int:
	return NETWORK_CONTACT_PRESENTER_SCRIPT.contact_twooter_follow_weight(contact)


func _contact_twooter_verified(contact: Dictionary) -> bool:
	return NETWORK_CONTACT_PRESENTER_SCRIPT.contact_twooter_verified(contact)


func _contact_twooter_voice(contact: Dictionary) -> String:
	return NETWORK_CONTACT_PRESENTER_SCRIPT.contact_twooter_voice(contact)


func _contact_string_array(source: Variant) -> Array:
	return NETWORK_CONTACT_PRESENTER_SCRIPT.contact_string_array(source)


func _slug_text(value: String, keep_separator: bool) -> String:
	return NETWORK_CONTACT_PRESENTER_SCRIPT.slug_text(value, keep_separator)


func _contact_company_targets(discovery: Dictionary) -> Array:
	return NETWORK_CONTACT_PRESENTER_SCRIPT.contact_company_targets(discovery)


func _can_add_company_lead(discovery: Dictionary, company_id: String) -> bool:
	return NETWORK_CONTACT_PRESENTER_SCRIPT.can_add_company_lead(discovery, company_id, MAX_COMPANY_LEADS_PER_FLOATER)


func _request_rows(requests: Dictionary) -> Array:
	var rows: Array = []
	for request_value in requests.values():
		var request: Dictionary = request_value
		var row: Dictionary = request.duplicate(true)
		row["relationship_delta_success"] = int(row.get("relationship_delta_success", REQUEST_RELATIONSHIP_SUCCESS))
		row["relationship_delta_failure"] = int(row.get("relationship_delta_failure", REQUEST_RELATIONSHIP_FAILURE))
		rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("due_day_index", 0)) < int(b.get("due_day_index", 0))
	)
	return rows


func _network_journal_rows(run_state, data_repository, requests: Dictionary, discoveries: Dictionary) -> Array:
	return NETWORK_JOURNAL_BUILDER_SCRIPT.network_journal_rows(
		run_state,
		data_repository,
		requests,
		discoveries,
		Callable(self, "_contact_display_name"),
		Callable(self, "_company_ticker")
	)


func _request_due_date_text(request: Dictionary) -> String:
	return NETWORK_JOURNAL_BUILDER_SCRIPT.request_due_date_text(request)


func _contact_display_name(run_state, data_repository, contact_id: String) -> String:
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	if contact.is_empty():
		return "Contact"
	return str(contact.get("display_name", "Contact"))


func _recognition_tier(score: float) -> Dictionary:
	if score >= 85.0:
		return {"label": "Market Name", "tier_index": 4, "contact_cap": 12}
	if score >= 65.0:
		return {"label": "Connected Player", "tier_index": 3, "contact_cap": 8}
	if score >= 40.0:
		return {"label": "Known Trader", "tier_index": 2, "contact_cap": 5}
	if score >= 20.0:
		return {"label": "Retail Regular", "tier_index": 1, "contact_cap": 3}
	return {"label": "Unknown", "tier_index": 0, "contact_cap": 2}


func _is_met(run_state, contact_id: String) -> bool:
	return bool(run_state.get_network_contacts().get(contact_id, {}).get("met", false))


func _resolve_target_company_id(run_state, data_repository, contact_id: String, company_id: String) -> String:
	if not company_id.is_empty():
		return company_id
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	var affiliated_company_id: String = str(contact.get("affiliated_company_id", contact.get("company_id", "")))
	if not affiliated_company_id.is_empty():
		return affiliated_company_id
	var discovery: Dictionary = run_state.get_network_discoveries().get(contact_id, {})
	var discovered_company_id: String = str(discovery.get("target_company_id", ""))
	if not discovered_company_id.is_empty():
		return discovered_company_id
	return str(run_state.company_order[0]) if not run_state.company_order.is_empty() else ""


func _has_active_contact_arc(run_state, contact_id: String, company_id: String) -> bool:
	for arc_value in run_state.get_active_company_arcs():
		var arc: Dictionary = arc_value
		if str(arc.get("source_contact_id", "")) == contact_id and str(arc.get("target_company_id", "")) == company_id:
			return true
	return false


func _has_pending_request(run_state, contact_id: String, company_id: String) -> bool:
	for request_value in run_state.get_network_requests().values():
		var request: Dictionary = request_value
		if str(request.get("status", "")) != "pending":
			continue
		if str(request.get("contact_id", "")) != contact_id:
			continue
		if str(request.get("target_company_id", "")) != company_id:
			continue
		return true
	return false


func _has_at_least_one_lot(run_state, company_id: String) -> bool:
	return int(run_state.get_holding(company_id).get("shares", 0)) >= LOT_SIZE


func _adjust_relationship(run_state, contact_id: String, delta: int) -> void:
	var contacts: Dictionary = run_state.get_network_contacts()
	if _adjust_relationship_in_contacts(contacts, contact_id, delta):
		run_state.set_network_contacts(contacts)


func _adjust_relationship_in_contacts(contacts: Dictionary, contact_id: String, delta: int) -> bool:
	if contact_id.is_empty():
		return false
	var runtime: Dictionary = contacts.get(contact_id, {})
	runtime["relationship"] = clampi(int(runtime.get("relationship", 25)) + delta, 0, 100)
	contacts[contact_id] = runtime
	return true


func _mark_contact_day_flag(run_state, contact_id: String, flag_key: String) -> void:
	var contacts: Dictionary = run_state.get_network_contacts()
	if _mark_contact_day_flag_in_contacts(contacts, contact_id, flag_key, run_state.day_index):
		run_state.set_network_contacts(contacts)


func _mark_contact_day_flag_in_contacts(contacts: Dictionary, contact_id: String, flag_key: String, day_index: int) -> bool:
	if contact_id.is_empty() or flag_key.is_empty():
		return false
	var runtime: Dictionary = contacts.get(contact_id, {})
	runtime[flag_key] = day_index
	contacts[contact_id] = runtime
	return true


func _sentiment_for_contact(contact: Dictionary, action: String) -> float:
	return NETWORK_DISCOVERY_SCRIPT.sentiment_for_contact(contact, action)


func _contact_arc_description(contact: Dictionary, ticker: String, action: String) -> String:
	return NETWORK_DISCOVERY_SCRIPT.contact_arc_description(contact, ticker, action)
