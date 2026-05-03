extends RefCounted

const LOT_SIZE := 100
const REFERRAL_RELATIONSHIP_THRESHOLD := 45
const REFERRAL_RELATIONSHIP_COST := 10
const REFERRAL_CONNECTION_THRESHOLD := 50
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
const MEETING_LEAD_TIER_ORDER := {
	"open": 0,
	"low": 1,
	"mid": 2,
	"high": 3
}

var trading_calendar = preload("res://systems/TradingCalendar.gd").new()
const STABLE_RNG = preload("res://systems/StableRng.gd")


func build_snapshot(run_state, data_repository) -> Dictionary:
	var contacts: Dictionary = run_state.get_network_contacts()
	var discoveries: Dictionary = run_state.get_network_discoveries()
	var requests: Dictionary = run_state.get_network_requests()
	var recognition: Dictionary = build_recognition_snapshot(run_state)
	var last_tip_notes: Dictionary = _last_tip_notes_by_contact(run_state)
	var tip_histories: Dictionary = _tip_histories_by_contact(run_state)
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
		var row: Dictionary = _contact_row(contact, runtime, discovery, recognition)
		_apply_last_tip_note(row, last_tip_notes)
		_apply_tip_history(row, tip_histories)
		_apply_cross_contact_read(row, cross_checks)
		if bool(runtime.get("met", false)):
			contact_rows.append(row)
		elif bool(discovery.get("discovered", false)):
			discovered_rows.append(row)

	var generated_contact_ids := {}
	for contact_id_value in contacts.keys():
		var contact_id: String = str(contact_id_value)
		if contact_id.begins_with("insider_"):
			generated_contact_ids[contact_id] = true
	for contact_id_value in discoveries.keys():
		var contact_id: String = str(contact_id_value)
		if contact_id.begins_with("insider_"):
			generated_contact_ids[contact_id] = true
	for generated_contact_id_value in generated_contact_ids.keys():
		var generated_contact_id: String = str(generated_contact_id_value)
		var generated_contact: Dictionary = _contact_definition(run_state, data_repository, generated_contact_id)
		if generated_contact.is_empty():
			continue
		var runtime: Dictionary = contacts.get(generated_contact_id, {})
		var discovery: Dictionary = discoveries.get(generated_contact_id, {})
		var row: Dictionary = _contact_row(generated_contact, runtime, discovery, recognition)
		_apply_last_tip_note(row, last_tip_notes)
		_apply_tip_history(row, tip_histories)
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


func count_current_day_activity(run_state) -> int:
	var target_day_index: int = int(run_state.day_index)
	var count: int = 0
	for tip_value in run_state.get_network_tip_journal().values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		if int(tip.get("created_day_index", 0)) == target_day_index:
			count += 1
		if str(tip.get("status", "pending")) != "pending" and int(tip.get("resolved_day_index", tip.get("created_day_index", 0))) == target_day_index:
			count += 1
		if not str(tip.get("followup_note", "")).is_empty() and int(tip.get("followup_day_index", tip.get("resolved_day_index", tip.get("created_day_index", 0)))) == target_day_index:
			count += 1
		if not str(tip.get("source_check_note", "")).is_empty() and int(tip.get("source_check_day_index", tip.get("created_day_index", 0))) == target_day_index:
			count += 1
	for request_value in run_state.get_network_requests().values():
		if typeof(request_value) != TYPE_DICTIONARY:
			continue
		var request: Dictionary = request_value
		var status: String = str(request.get("status", "pending"))
		var request_day_index: int = int(request.get("completed_day_index", request.get("created_day_index", 0))) if status != "pending" else int(request.get("created_day_index", 0))
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
	var changed: bool = false
	for tip_id_value in journal.keys():
		var tip_id: String = str(tip_id_value)
		var tip: Dictionary = journal.get(tip_id, {})
		if str(tip.get("status", "pending")) != "pending":
			continue
		if int(tip.get("resolve_day_index", 0)) > run_state.day_index:
			continue
		var outcome: Dictionary = _resolve_tip_memory(run_state, data_repository, tip)
		tip["status"] = str(outcome.get("status", "resolved"))
		tip["outcome_label"] = str(outcome.get("outcome_label", "Still pending"))
		tip["outcome_note"] = str(outcome.get("outcome_note", "The read is still unresolved."))
		tip["player_action_label"] = str(outcome.get("player_action_label", "No action"))
		tip["player_action_note"] = str(outcome.get("player_action_note", ""))
		tip["player_action_alignment"] = str(outcome.get("player_action_alignment", "neutral"))
		tip["player_net_shares"] = int(outcome.get("player_net_shares", 0))
		tip["relationship_delta"] = int(outcome.get("relationship_delta", 0))
		tip["resolved_day_index"] = run_state.day_index
		tip["resolved_price"] = float(outcome.get("resolved_price", 0.0))
		tip["resolved_change_pct"] = float(outcome.get("change_pct", 0.0))
		journal[tip_id] = tip
		changed = true
		results.append(tip.duplicate(true))
		var relationship_delta: int = int(outcome.get("relationship_delta", 0))
		if relationship_delta != 0:
			_adjust_relationship(run_state, str(tip.get("contact_id", "")), relationship_delta)
		_store_contact_tip_note(run_state, tip)
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
	if int(recognition.get("score", 0)) < int(contact.get("recognition_required", 0)):
		return []
	if _floater_discovery_score(contact, company_id, sector_id, category, "news") < 0.0:
		return []
	var discoveries: Dictionary = run_state.get_network_discoveries()
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
	if source_type == "profile":
		return max(run_state.company_order.size(), 1)
	if source_type == "news":
		return max(run_state.company_order.size(), 1)
	return 3


func _floater_discovery_score(contact: Dictionary, company_id: String, sector_id: String, category: String, source_type: String) -> float:
	var sector_match: bool = (not sector_id.is_empty()) and (sector_id in contact.get("sector_ids", []))
	var category_match: bool = (not category.is_empty()) and (category in contact.get("categories", []))
	var company_targeted: bool = not company_id.is_empty()
	if company_targeted and not sector_match:
		return -1.0
	if not company_targeted and not category_match:
		return -1.0
	if not sector_match and not category_match:
		return -1.0

	var score: float = 0.0
	if sector_match:
		score += 65.0
	if category_match:
		score += (5.0 if category == "company" else 30.0)
	if source_type == "profile":
		score += 8.0
	score += clamp(float(contact.get("reliability", 0.5)), 0.0, 1.0) * 10.0
	score += max(0.0, 50.0 - float(contact.get("recognition_required", 0))) * 0.1
	return score


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
		var insider_id: String = str(insider.get("id", insider.get("contact_id", "")))
		if insider_id.is_empty() or bool(contacts.get(insider_id, {}).get("met", false)):
			continue
		if bool(discoveries.get(insider_id, {}).get("discovered", false)):
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
	result["public_truth_label"] = str(truth_read.get("truth_label", "Network Read"))
	result["public_tip_read"] = str(truth_read.get("tip_read", ""))
	result["public_confidence_label"] = str(truth_read.get("confidence_label", "Soft read"))
	result["tip_source_role"] = str(truth_read.get("source_role", "market contact"))
	result["intel_summary"] = "%s | %s" % [
		str(truth_read.get("truth_label", "Network Read")),
		str(truth_read.get("confidence_label", "Soft read"))
	]
	result["message"] = "%s | %s: %s" % [
		str(truth_read.get("truth_label", "Network Read")),
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
	result["public_truth_label"] = str(truth_read.get("truth_label", "Network Read"))
	result["public_tip_read"] = str(truth_read.get("tip_read", ""))
	result["public_confidence_label"] = str(truth_read.get("confidence_label", "Soft read"))
	result["tip_source_role"] = str(truth_read.get("source_role", "market contact"))
	result["message"] = "%s | %s: %s" % [
		str(truth_read.get("truth_label", "Network Read")),
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
	journal[tip_id] = {
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
		"truth_label": str(tip_result.get("public_truth_label", "Network Read")),
		"confidence_label": str(tip_result.get("public_confidence_label", "Soft read")),
		"source_role": str(tip_result.get("tip_source_role", "market contact")),
		"tip_read": str(tip_result.get("public_tip_read", "")),
		"status": "pending"
	}
	run_state.set_network_tip_journal(_pruned_tip_journal(journal))


func _resolve_tip_memory(run_state, _data_repository, tip: Dictionary) -> Dictionary:
	var company_id: String = str(tip.get("target_company_id", ""))
	var company: Dictionary = run_state.get_company(company_id)
	var current_price: float = float(company.get("current_price", tip.get("baseline_price", 0.0)))
	var baseline_price: float = max(float(tip.get("baseline_price", current_price)), 1.0)
	var change_pct: float = (current_price - baseline_price) / baseline_price
	var truth_label: String = str(tip.get("truth_label", "Network Read"))
	var chain: Dictionary = _chain_by_id(run_state, str(tip.get("chain_id", "")))
	var outcome_state: String = str(chain.get("outcome_state", ""))
	var timeline_state: String = str(chain.get("current_timeline_state", ""))
	var status: String = "resolved"
	var outcome_label: String = "Still pending"
	var relationship_delta: int = 0
	if _tip_label_is_cautionary(truth_label):
		if change_pct <= -0.015 or outcome_state == "cancelled" or timeline_state == "cancelled":
			outcome_label = "Useful warning"
			relationship_delta = 3
		elif change_pct >= 0.025 or outcome_state == "approved":
			outcome_label = "Missed badly"
			relationship_delta = -3
		elif absf(change_pct) <= 0.012:
			outcome_label = "Still pending"
			status = "unresolved"
		else:
			outcome_label = "Too early"
	elif truth_label == "Real But Delayed":
		if timeline_state == "delayed":
			outcome_label = "Useful timing read"
			relationship_delta = 2
		elif change_pct >= 0.025 or outcome_state == "approved":
			outcome_label = "Early, not wrong"
			relationship_delta = 1
		elif change_pct <= -0.025 or outcome_state == "cancelled":
			outcome_label = "Missed badly"
			relationship_delta = -3
		else:
			outcome_label = "Still pending"
			status = "unresolved"
	else:
		if change_pct >= 0.018 or outcome_state == "approved" or timeline_state in ["approved", "executing", "completed"]:
			outcome_label = "Useful read"
			relationship_delta = 3
		elif change_pct <= -0.025 or outcome_state == "cancelled" or timeline_state == "cancelled":
			outcome_label = "Missed badly"
			relationship_delta = -3
		elif absf(change_pct) <= 0.012:
			outcome_label = "Still pending"
			status = "unresolved"
		else:
			outcome_label = "Too early"
	var ticker: String = str(tip.get("target_ticker", company_id.to_upper()))
	var player_action: Dictionary = _player_action_for_tip(run_state, tip)
	var player_read: Dictionary = _player_tip_action_read(tip, outcome_label, player_action)
	relationship_delta += int(player_read.get("relationship_delta", 0))
	var outcome_note: String = _tip_outcome_note(outcome_label, ticker, change_pct)
	var player_note: String = str(player_read.get("note", ""))
	if not player_note.is_empty():
		outcome_note += " " + player_note
	return {
		"status": status,
		"outcome_label": outcome_label,
		"outcome_note": outcome_note,
		"player_action_label": str(player_read.get("label", "No action")),
		"player_action_note": player_note,
		"player_action_alignment": str(player_read.get("alignment", "neutral")),
		"player_net_shares": int(player_action.get("net_shares", 0)),
		"relationship_delta": relationship_delta,
		"resolved_price": current_price,
		"change_pct": change_pct
	}


func _player_action_for_tip(run_state, tip: Dictionary) -> Dictionary:
	var company_id: String = str(tip.get("target_company_id", ""))
	var created_day_index: int = int(tip.get("created_day_index", 0))
	var resolve_day_index: int = int(tip.get("resolve_day_index", run_state.day_index))
	var buy_shares: int = 0
	var sell_shares: int = 0
	for trade_value in run_state.get_trade_history():
		if typeof(trade_value) != TYPE_DICTIONARY:
			continue
		var trade: Dictionary = trade_value
		if str(trade.get("company_id", "")) != company_id:
			continue
		var trade_day_index: int = int(trade.get("day_index", 0))
		if trade_day_index < created_day_index or trade_day_index > resolve_day_index:
			continue
		var shares: int = int(trade.get("shares", 0))
		if str(trade.get("side", "")) == "buy":
			buy_shares += shares
		elif str(trade.get("side", "")) == "sell":
			sell_shares += shares
	var baseline_shares: int = int(tip.get("baseline_shares", 0))
	var ending_shares: int = int(run_state.get_holding(company_id).get("shares", 0))
	var net_shares: int = buy_shares - sell_shares
	var action_label: String = "Ignored"
	if buy_shares > sell_shares:
		action_label = "Bought after tip"
	elif sell_shares > buy_shares:
		action_label = "Sold after tip"
	elif buy_shares > 0 and sell_shares > 0:
		action_label = "Round-tripped"
	elif baseline_shares > 0 and ending_shares > 0:
		action_label = "Held through read"
	return {
		"label": action_label,
		"buy_shares": buy_shares,
		"sell_shares": sell_shares,
		"net_shares": net_shares,
		"baseline_shares": baseline_shares,
		"ending_shares": ending_shares
	}


func _player_tip_action_read(tip: Dictionary, outcome_label: String, player_action: Dictionary) -> Dictionary:
	var truth_label: String = str(tip.get("truth_label", "Network Read"))
	var ticker: String = str(tip.get("target_ticker", str(tip.get("target_company_id", "")).to_upper()))
	var action_label: String = str(player_action.get("label", "Ignored"))
	var net_shares: int = int(player_action.get("net_shares", 0))
	var baseline_shares: int = int(player_action.get("baseline_shares", 0))
	var ending_shares: int = int(player_action.get("ending_shares", 0))
	var read_was_good: bool = outcome_label in ["Useful read", "Useful warning", "Useful timing read", "Early, not wrong"]
	var read_was_bad: bool = outcome_label == "Missed badly"
	var cautionary: bool = _tip_label_is_cautionary(truth_label)
	var label: String = action_label
	var note: String = ""
	var alignment: String = "neutral"
	var relationship_delta: int = 0
	if cautionary:
		if net_shares < 0:
			label = "Acted on warning"
			alignment = "followed"
			note = "You reduced exposure after the warning."
		elif net_shares > 0:
			label = "Chased against warning"
			alignment = "against"
			note = "You bought anyway, so the contact's warning became a test of discipline."
		elif baseline_shares <= 0 and ending_shares <= 0:
			label = "Avoided warning"
			alignment = "followed"
			note = "You stayed out after the warning."
		elif baseline_shares > 0 and ending_shares > 0:
			label = "Held despite warning"
			alignment = "against"
			note = "You kept holding despite the caution."
	else:
		if net_shares > 0:
			label = "Followed read"
			alignment = "followed"
			note = "You followed the read with a buy."
		elif baseline_shares > 0 and ending_shares > 0:
			label = "Held through read"
			alignment = "followed"
			note = "You were already positioned and held through the read."
		elif net_shares < 0:
			label = "Sold against read"
			alignment = "against"
			note = "You sold against the contact's read."
		else:
			label = "Ignored read"
			alignment = "ignored"
			note = "You did not act on this read."
	if read_was_good and alignment == "followed":
		relationship_delta = 1
		note += " That follow-through gives the relationship a small boost."
	elif read_was_bad and alignment == "followed":
		relationship_delta = -1
		note += " The read aged poorly, and following it costs a little trust."
	elif read_was_bad and alignment in ["ignored", "against"]:
		note += " That restraint helped you dodge a bad read."
	elif read_was_good and alignment == "ignored":
		note += " The contact was useful, but you left it on the table."
	if ticker.is_empty():
		ticker = "the stock"
	return {
		"label": label,
		"note": note,
		"alignment": alignment,
		"relationship_delta": relationship_delta
	}


func _tip_label_is_cautionary(truth_label: String) -> bool:
	return truth_label in ["Distribution Risk", "Retail Trap", "Dead Story", "Pressure Read"]


func _tip_outcome_note(outcome_label: String, ticker: String, change_pct: float) -> String:
	var pct_text: String = String.num(change_pct * 100.0, 1) + "%"
	match outcome_label:
		"Useful read":
			return "Last read: useful. %s moved %s after the tip." % [ticker, pct_text]
		"Useful warning":
			return "Last read: useful warning. %s cooled %s after the tip." % [ticker, pct_text]
		"Useful timing read":
			return "Last read: useful timing read. The story did slow down."
		"Early, not wrong":
			return "Last read: early, not wrong. %s kept moving, just faster than expected." % ticker
		"Too early":
			return "Last read: too early. %s moved %s, but the signal stayed mixed." % [ticker, pct_text]
		"Missed badly":
			return "Last read: missed badly. %s moved against the read by %s." % [ticker, pct_text]
		_:
			return "Last read: still pending. %s has not confirmed or rejected the setup yet." % ticker


func _store_contact_tip_note(run_state, tip: Dictionary) -> void:
	var contact_id: String = str(tip.get("contact_id", ""))
	if contact_id.is_empty():
		return
	var contacts: Dictionary = run_state.get_network_contacts()
	var runtime: Dictionary = contacts.get(contact_id, {})
	runtime["last_tip_id"] = str(tip.get("id", ""))
	runtime["last_tip_status"] = str(tip.get("status", ""))
	runtime["last_tip_label"] = str(tip.get("outcome_label", "Still pending"))
	runtime["last_tip_note"] = str(tip.get("outcome_note", ""))
	runtime["last_tip_player_action_label"] = str(tip.get("player_action_label", ""))
	runtime["last_tip_player_action_alignment"] = str(tip.get("player_action_alignment", ""))
	runtime["last_tip_day_index"] = int(tip.get("resolved_day_index", run_state.day_index))
	contacts[contact_id] = runtime
	run_state.set_network_contacts(contacts)


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


func _last_tip_notes_by_contact(run_state) -> Dictionary:
	var notes: Dictionary = {}
	for tip_value in run_state.get_network_tip_journal().values():
		var tip: Dictionary = tip_value
		var contact_id: String = str(tip.get("contact_id", ""))
		if contact_id.is_empty():
			continue
		if str(tip.get("status", "pending")) == "pending":
			continue
		var existing: Dictionary = notes.get(contact_id, {})
		if existing.is_empty() or int(tip.get("resolved_day_index", 0)) >= int(existing.get("resolved_day_index", 0)):
			notes[contact_id] = tip.duplicate(true)
	return notes


func _apply_last_tip_note(row: Dictionary, last_tip_notes: Dictionary) -> void:
	var contact_id: String = str(row.get("id", ""))
	if contact_id.is_empty():
		return
	var note: Dictionary = last_tip_notes.get(contact_id, {})
	if note.is_empty():
		return
	row["last_tip_status"] = str(note.get("status", ""))
	row["last_tip_label"] = str(note.get("outcome_label", ""))
	row["last_tip_note"] = str(note.get("outcome_note", ""))
	row["last_tip_player_action_label"] = str(note.get("player_action_label", ""))
	row["last_tip_player_action_alignment"] = str(note.get("player_action_alignment", ""))
	row["last_tip_day_index"] = int(note.get("resolved_day_index", 0))
	row["last_tip_followup_id"] = str(note.get("followup_id", ""))
	row["last_tip_followup_label"] = str(note.get("followup_label", ""))
	row["last_tip_followup_note"] = str(note.get("followup_note", ""))
	row["can_follow_up_tip"] = str(note.get("followup_id", "")).is_empty()
	row["tip_followup_options"] = _tip_followup_options(note)


func _tip_histories_by_contact(run_state) -> Dictionary:
	var grouped: Dictionary = {}
	for tip_value in run_state.get_network_tip_journal().values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		var contact_id: String = str(tip.get("contact_id", ""))
		if contact_id.is_empty():
			continue
		if str(tip.get("status", "pending")) == "pending":
			continue
		var rows: Array = grouped.get(contact_id, [])
		rows.append(_tip_history_row(tip))
		grouped[contact_id] = rows
	var histories: Dictionary = {}
	for contact_id_value in grouped.keys():
		var contact_id: String = str(contact_id_value)
		var rows: Array = grouped.get(contact_id, [])
		rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("resolved_day_index", 0)) > int(b.get("resolved_day_index", 0))
		)
		histories[contact_id] = _tip_history_summary(rows)
	return histories


func _tip_history_row(tip: Dictionary) -> Dictionary:
	return {
		"id": str(tip.get("id", "")),
		"target_company_id": str(tip.get("target_company_id", "")),
		"target_ticker": str(tip.get("target_ticker", "")),
		"truth_label": str(tip.get("truth_label", "")),
		"outcome_label": str(tip.get("outcome_label", "")),
		"player_action_label": str(tip.get("player_action_label", "")),
		"followup_label": str(tip.get("followup_label", "")),
		"resolved_day_index": int(tip.get("resolved_day_index", 0)),
		"change_pct": float(tip.get("resolved_change_pct", 0.0))
	}


func _tip_history_summary(rows: Array) -> Dictionary:
	var useful_count: int = 0
	var missed_count: int = 0
	var neutral_count: int = 0
	var scored_count: int = 0
	var score_total: float = 0.0
	for row_value in rows:
		var row: Dictionary = row_value
		var outcome_label: String = str(row.get("outcome_label", ""))
		if outcome_label in ["Useful read", "Useful warning", "Useful timing read", "Early, not wrong"]:
			useful_count += 1
			scored_count += 1
			score_total += 1.0
		elif outcome_label == "Missed badly":
			missed_count += 1
			scored_count += 1
			score_total -= 1.0
		else:
			neutral_count += 1
	var reliability_score: float = 50.0
	if scored_count > 0:
		reliability_score = clamp(50.0 + (score_total / float(scored_count)) * 35.0, 0.0, 100.0)
	var reliability_label: String = _tip_reliability_label(rows.size(), useful_count, missed_count, reliability_score)
	var visible_rows: Array = rows
	if visible_rows.size() > 4:
		visible_rows = visible_rows.slice(0, 4)
	return {
		"rows": visible_rows.duplicate(true),
		"resolved_count": rows.size(),
		"useful_count": useful_count,
		"missed_count": missed_count,
		"neutral_count": neutral_count,
		"reliability_score": reliability_score,
		"reliability_label": reliability_label
	}


func _tip_reliability_label(resolved_count: int, useful_count: int, missed_count: int, reliability_score: float) -> String:
	if resolved_count <= 0:
		return "No track record yet"
	if resolved_count == 1:
		if useful_count > 0:
			return "One useful read"
		if missed_count > 0:
			return "One bad read"
		return "One unresolved read"
	if reliability_score >= 72.0:
		return "Reliable lately"
	if reliability_score <= 38.0:
		return "Cold lately"
	return "Mixed record"


func _apply_tip_history(row: Dictionary, tip_histories: Dictionary) -> void:
	var contact_id: String = str(row.get("id", ""))
	var history: Dictionary = tip_histories.get(contact_id, {})
	if history.is_empty():
		row["tip_history"] = []
		row["tip_reliability_label"] = "No track record yet"
		row["tip_reliability_score"] = 50.0
		row["tip_resolved_count"] = 0
		row["tip_useful_count"] = 0
		row["tip_missed_count"] = 0
		return
	row["tip_history"] = history.get("rows", []).duplicate(true)
	row["tip_reliability_label"] = str(history.get("reliability_label", "No track record yet"))
	row["tip_reliability_score"] = float(history.get("reliability_score", 50.0))
	row["tip_resolved_count"] = int(history.get("resolved_count", 0))
	row["tip_useful_count"] = int(history.get("useful_count", 0))
	row["tip_missed_count"] = int(history.get("missed_count", 0))


func _cross_contact_reads_by_contact(run_state) -> Dictionary:
	var recent_rows: Array = []
	var min_day_index: int = run_state.day_index - 8
	for tip_value in run_state.get_network_tip_journal().values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		var contact_id: String = str(tip.get("contact_id", ""))
		var company_id: String = str(tip.get("target_company_id", ""))
		if contact_id.is_empty() or company_id.is_empty():
			continue
		if int(tip.get("created_day_index", 0)) < min_day_index:
			continue
		recent_rows.append(_cross_contact_read_row(tip))
	var result: Dictionary = {}
	for row_value in recent_rows:
		var row: Dictionary = row_value
		var contact_id: String = str(row.get("contact_id", ""))
		var peers: Array = []
		for peer_value in recent_rows:
			var peer: Dictionary = peer_value
			if str(peer.get("contact_id", "")) == contact_id:
				continue
			if str(peer.get("target_company_id", "")) != str(row.get("target_company_id", "")):
				continue
			peers.append(peer)
		if peers.is_empty():
			continue
		var summary: Dictionary = _cross_contact_summary(row, peers)
		var existing: Dictionary = result.get(contact_id, {})
		if existing.is_empty() or int(row.get("created_day_index", 0)) > int(existing.get("created_day_index", 0)):
			result[contact_id] = summary
	return result


func _cross_contact_read_row(tip: Dictionary) -> Dictionary:
	var truth_label: String = str(tip.get("truth_label", "Network Read"))
	return {
		"tip_id": str(tip.get("id", "")),
		"contact_id": str(tip.get("contact_id", "")),
		"contact_name": str(tip.get("contact_name", "Contact")),
		"target_company_id": str(tip.get("target_company_id", "")),
		"target_ticker": str(tip.get("target_ticker", "")),
		"truth_label": truth_label,
		"confidence_label": str(tip.get("confidence_label", "")),
		"source_role": str(tip.get("source_role", "")),
		"source_check_label": str(tip.get("source_check_label", "")),
		"source_check_note": str(tip.get("source_check_note", "")),
		"source_check_day_index": int(tip.get("source_check_day_index", 0)),
		"status": str(tip.get("status", "pending")),
		"created_day_index": int(tip.get("created_day_index", 0)),
		"stance": _truth_stance(truth_label)
	}


func _cross_contact_summary(current: Dictionary, peers: Array) -> Dictionary:
	var conflict_rows: Array = []
	var agreement_rows: Array = []
	var mixed_rows: Array = []
	var current_stance: String = str(current.get("stance", "uncertain"))
	for peer_value in peers:
		var peer: Dictionary = peer_value
		var peer_stance: String = str(peer.get("stance", "uncertain"))
		if _truth_stances_conflict(current_stance, peer_stance):
			conflict_rows.append(peer)
		elif current_stance == peer_stance:
			agreement_rows.append(peer)
		else:
			mixed_rows.append(peer)
	var label: String = "Mixed sources"
	var note: String = "Other sources are reading the same name differently."
	var rows: Array = mixed_rows
	if not conflict_rows.is_empty():
		label = "Conflicting sources"
		var first_conflict: Dictionary = conflict_rows[0]
		note = "%s has a different read on %s: %s versus %s." % [
			str(first_conflict.get("contact_name", "Another contact")),
			str(current.get("target_ticker", "")),
			str(first_conflict.get("truth_label", "a different read")),
			str(current.get("truth_label", "this read"))
		]
		rows = conflict_rows
	elif not agreement_rows.is_empty():
		label = "Source agreement"
		var first_agreement: Dictionary = agreement_rows[0]
		note = "%s is broadly aligned on %s." % [
			str(first_agreement.get("contact_name", "Another contact")),
			str(current.get("target_ticker", "this name"))
		]
		rows = agreement_rows
	if rows.size() > 3:
		rows = rows.slice(0, 3)
	var source_check_note: String = str(current.get("source_check_note", ""))
	var has_direct_source_conflict: bool = label == "Conflicting sources"
	var can_ask_source_check: bool = has_direct_source_conflict and source_check_note.is_empty()
	return {
		"label": label,
		"note": note,
		"target_ticker": str(current.get("target_ticker", "")),
		"current_tip_id": str(current.get("tip_id", "")),
		"current_truth_label": str(current.get("truth_label", "")),
		"current_confidence_label": str(current.get("confidence_label", "")),
		"current_source_role": str(current.get("source_role", "")),
		"current_stance": current_stance,
		"rows": rows.duplicate(true),
		"created_day_index": int(current.get("created_day_index", 0)),
		"has_direct_source_conflict": has_direct_source_conflict,
		"can_ask_source_check": can_ask_source_check,
		"source_check_label": str(current.get("source_check_label", "")),
		"source_check_note": source_check_note,
		"source_check_day_index": int(current.get("source_check_day_index", 0))
	}


func _truth_stance(truth_label: String) -> String:
	if _tip_label_is_cautionary(truth_label):
		return "caution"
	match truth_label:
		"Accumulation", "Filing-Backed", "Execution Watch", "Network Read":
			return "constructive"
		"Real But Delayed", "Room Risk", "Early Read":
			return "timing_risk"
		_:
			return "uncertain"


func _truth_stances_conflict(a: String, b: String) -> bool:
	return (a == "constructive" and b == "caution") or (a == "caution" and b == "constructive")


func _apply_cross_contact_read(row: Dictionary, cross_checks: Dictionary) -> void:
	var contact_id: String = str(row.get("id", ""))
	var cross_check: Dictionary = cross_checks.get(contact_id, {})
	if cross_check.is_empty():
		row["cross_contact_label"] = ""
		row["cross_contact_note"] = ""
		row["cross_contact_rows"] = []
		row["has_direct_source_conflict"] = false
		row["can_ask_source_check"] = false
		row["source_check_label"] = ""
		row["source_check_note"] = ""
		row["source_check_day_index"] = 0
		return
	row["cross_contact_label"] = str(cross_check.get("label", "Mixed sources"))
	row["cross_contact_note"] = str(cross_check.get("note", ""))
	row["cross_contact_rows"] = cross_check.get("rows", []).duplicate(true)
	row["has_direct_source_conflict"] = bool(cross_check.get("has_direct_source_conflict", false))
	row["can_ask_source_check"] = bool(cross_check.get("can_ask_source_check", false))
	row["source_check_label"] = str(cross_check.get("source_check_label", ""))
	row["source_check_note"] = str(cross_check.get("source_check_note", ""))
	row["source_check_day_index"] = int(cross_check.get("source_check_day_index", 0))


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
		if str(tip.get("status", "pending")) == "pending":
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
	if not str(tip.get("followup_id", "")).is_empty():
		return []
	return [
		{"id": "thank", "label": "Thank"},
		{"id": "ask_why", "label": "Ask Why"},
		{"id": "challenge", "label": "Challenge"}
	]


func _build_tip_followup_result(contact: Dictionary, tip: Dictionary, followup_id: String) -> Dictionary:
	var contact_name: String = str(contact.get("display_name", "Contact"))
	var outcome_label: String = str(tip.get("outcome_label", "Still pending"))
	var player_action_label: String = str(tip.get("player_action_label", "No action"))
	var player_alignment: String = str(tip.get("player_action_alignment", "neutral"))
	var truth_label: String = str(tip.get("truth_label", "Network Read"))
	var read_was_good: bool = outcome_label in ["Useful read", "Useful warning", "Useful timing read", "Early, not wrong"]
	var read_was_bad: bool = outcome_label == "Missed badly"
	var reliability: float = clamp(float(contact.get("reliability", 0.6)), 0.0, 1.0)
	var relationship_delta: int = 0
	var label: String = ""
	var note: String = ""
	match followup_id:
		"thank":
			label = "Thanked"
			if read_was_good and player_alignment == "followed":
				relationship_delta = 2
				note = "%s appreciates that you acted with discipline after the read." % contact_name
			elif read_was_good:
				relationship_delta = 1
				note = "%s accepts the thanks, but points out that the market only pays when you act." % contact_name
			elif read_was_bad:
				note = "%s accepts the note, but admits the read did not age cleanly." % contact_name
			else:
				relationship_delta = 1
				note = "%s logs it as unfinished business and keeps the line warm." % contact_name
		"ask_why":
			label = "Asked Why"
			note = _tip_followup_explanation(contact_name, truth_label, outcome_label, player_action_label)
			if read_was_good:
				relationship_delta = 1
		"challenge":
			label = "Challenged"
			if read_was_bad:
				if reliability >= 0.65:
					relationship_delta = 1
					note = "%s respects the pushback and walks through what broke in the read." % contact_name
				else:
					relationship_delta = -1
					note = "%s gets defensive, which tells you something about the quality of the source." % contact_name
			elif read_was_good:
				relationship_delta = -1
				note = "%s thinks the tape already answered the question and does not love being second-guessed." % contact_name
			else:
				note = "%s agrees the setup is still not clean enough to call." % contact_name
		_:
			return {"success": false, "message": "Unknown follow-up option."}
	return {
		"success": true,
		"followup_label": label,
		"followup_note": note,
		"relationship_delta": relationship_delta,
		"message": "%s: %s" % [label, note]
	}


func _build_source_check_response(contact: Dictionary, run_state, source_check: Dictionary) -> Dictionary:
	var rows: Array = source_check.get("rows", [])
	var peer: Dictionary = {}
	if not rows.is_empty() and typeof(rows[0]) == TYPE_DICTIONARY:
		peer = rows[0]
	var contact_id: String = str(contact.get("id", ""))
	var contact_name: String = str(contact.get("display_name", "Contact"))
	var ticker: String = str(source_check.get("target_ticker", "this name"))
	var current_truth: String = str(source_check.get("current_truth_label", "this read"))
	var peer_truth: String = str(peer.get("truth_label", "the other read"))
	var current_stance: String = str(source_check.get("current_stance", "uncertain"))
	var relationship: int = int(run_state.get_network_contacts().get(contact_id, {}).get("relationship", contact.get("base_relationship", 25)))
	var reliability: float = clamp(float(contact.get("reliability", 0.6)), 0.0, 1.0)
	var evidence_phrase: String = _source_check_evidence_phrase(contact, str(source_check.get("current_source_role", "")))
	var relationship_delta: int = 0
	var note: String = ""
	if relationship < 25:
		relationship_delta = -1
		note = "%s gives a guarded answer on %s: the conflict is real, but they will not open the whole book yet. Their read still leans on %s." % [
			contact_name,
			ticker,
			evidence_phrase
		]
	elif reliability >= 0.72:
		relationship_delta = 1
		if current_stance == "constructive":
			note = "%s says the warning from %s is worth respecting, but their constructive read still has better backing from %s. Treat size and timing carefully." % [
				contact_name,
				str(peer.get("contact_name", "the other source")),
				evidence_phrase
			]
		else:
			note = "%s says the bullish read from %s may be early or crowded; their warning is based on %s. Wait for cleaner confirmation before chasing." % [
				contact_name,
				str(peer.get("contact_name", "the other source")),
				evidence_phrase
			]
	else:
		if current_stance == "constructive":
			note = "%s admits %s is not clean: %s conflicts with %s, so the idea needs confirmation before it deserves full trust." % [
				contact_name,
				ticker,
				current_truth,
				peer_truth
			]
		else:
			note = "%s keeps the caution flag on %s, but admits the opposite read means the setup is not dead. The next tape or filing should decide it." % [
				contact_name,
				ticker
			]
	return {
		"label": "Asked about conflict",
		"note": note,
		"relationship_delta": relationship_delta,
		"peer_contact_id": str(peer.get("contact_id", "")),
		"peer_contact_name": str(peer.get("contact_name", "")),
		"message": "Source check: %s" % note
	}


func _source_check_evidence_phrase(contact: Dictionary, source_role: String) -> String:
	var categories_text: String = " ".join(contact.get("categories", [])).to_lower()
	var role_text: String = ("%s %s %s" % [
		source_role,
		str(contact.get("role", "")),
		categories_text
	]).to_lower()
	if role_text.find("flow") >= 0 or role_text.find("desk") >= 0 or role_text.find("broker") >= 0 or role_text.find("bandar") >= 0:
		return "tape behavior, ritel pressure, and who keeps taking the offer"
	if role_text.find("legal") >= 0 or role_text.find("corporate") >= 0 or role_text.find("insider") >= 0 or role_text.find("commissioner") >= 0:
		return "paperwork timing and what the room is willing to sign"
	if role_text.find("journal") >= 0 or role_text.find("source") >= 0 or role_text.find("news") >= 0:
		return "how many independent source lines are telling the same story"
	if role_text.find("research") >= 0 or role_text.find("analyst") >= 0 or role_text.find("fundamental") >= 0:
		return "filing quality, valuation room, and whether the thesis still holds"
	return "the parts of the story they can personally verify"


func _tip_followup_explanation(contact_name: String, truth_label: String, outcome_label: String, player_action_label: String) -> String:
	match truth_label:
		"Accumulation":
			return "%s says the read came from absorption and follow-through, not the headline itself. Your action: %s. Outcome: %s." % [contact_name, player_action_label, outcome_label]
		"Room Risk":
			return "%s says the meeting room mattered more than the first tape reaction. Your action: %s. Outcome: %s." % [contact_name, player_action_label, outcome_label]
		"Real But Delayed":
			return "%s says the story was real, but the calendar moved under it. Your action: %s. Outcome: %s." % [contact_name, player_action_label, outcome_label]
		"Retail Trap", "Distribution Risk", "Dead Story", "Pressure Read":
			return "%s says the warning was about crowding and weak follow-through. Your action: %s. Outcome: %s." % [contact_name, player_action_label, outcome_label]
		_:
			return "%s says the read was only a lead until tape, filings, or another source confirmed it. Your action: %s. Outcome: %s." % [contact_name, player_action_label, outcome_label]


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
		"Real But Delayed":
			return "%s still looks live, but the timing is no longer clean." % ticker
		"Room Risk":
			return "%s has a real %s path, but the room can still reset the trade." % [ticker, family_label]
		"Filing-Backed":
			return "%s has moved past loose rumor; the paper trail is now doing the work." % ticker
		"Accumulation":
			return "%s looks like a quiet accumulation story before the wider market fully agrees." % ticker
		"Distribution Risk":
			return "%s is getting crowded, and stronger hands may be selling into attention." % ticker
		"Retail Trap":
			return "%s has the shape of a crowded ritel chase rather than a clean confirmation." % ticker
		"Execution Watch":
			return "%s cleared the noisy part; now the question is whether execution keeps pace." % ticker
		"Dead Story":
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
		"Real But Delayed":
			return "Wait for a fresh date, renewed accumulation, or a clearer boardroom cue."
		"Room Risk":
			return "Meeting notices, attendance, and vote wording matter more than intraday noise."
		"Filing-Backed":
			return "The next useful clue is whether the market buys the filing after the first reaction."
		"Accumulation":
			return "If volume rises without the story getting too loud, the read improves."
		"Distribution Risk", "Retail Trap":
			return "Be careful if volume expands while the bid keeps slipping."
		"Execution Watch":
			return "Follow-through now matters more than another headline."
		"Dead Story":
			return "Only a new notice or hard reversal would make it worth reopening."
		_:
			if not str(chain.get("active_meeting_id", "")).is_empty():
				return "The calendar is the cleanest thing to track next."
			return "Confirmation should come from tape, filings, or a cleaner second source."


func _public_truth_label(contact: Dictionary, chain: Dictionary, intel_quality: String) -> String:
	if chain.is_empty():
		if str(contact.get("tone", "mixed")) == "negative":
			return "Pressure Read"
		return "Network Read"
	var stage: String = str(chain.get("stage", ""))
	var timeline_state: String = str(chain.get("current_timeline_state", ""))
	var outcome_state: String = str(chain.get("outcome_state", ""))
	var smart_money_phase: String = str(chain.get("smart_money_phase", ""))
	var public_heat: float = float(chain.get("public_heat", 0.0))
	var retail_positioning: float = float(chain.get("retail_positioning", 0.0))
	var source_role: String = _contact_tip_voice(contact)
	if outcome_state == "cancelled" or timeline_state == "cancelled":
		return "Dead Story"
	if stage == "execution" or outcome_state == "approved":
		return "Execution Watch"
	if timeline_state == "delayed" or intel_quality == "very_strong":
		return "Real But Delayed"
	if source_role == "flow desk" and public_heat >= 0.45 and retail_positioning >= 0.24:
		return "Retail Trap"
	if stage == "meeting_or_call" or not str(chain.get("active_meeting_id", "")).is_empty():
		return "Room Risk"
	if smart_money_phase in ["distributing", "trapping"]:
		return "Retail Trap" if public_heat >= 0.58 or retail_positioning >= 0.36 else "Distribution Risk"
	if stage == "formal_agenda_or_filing":
		return "Filing-Backed"
	if smart_money_phase in ["accumulating", "re_accumulating"] and stage in ["hidden_positioning", "unusual_activity", "rumor_leak"]:
		return "Accumulation"
	if public_heat >= 0.64 and retail_positioning >= 0.34:
		return "Retail Trap"
	return "Early Read"


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
	var contact_categories: Array = contact.get("categories", [])
	var profile_categories: Array = profile.get("category_ids", [])
	var has_category_match: bool = profile_categories.is_empty()
	for category_value in profile_categories:
		if str(category_value) in contact_categories:
			has_category_match = true
			break
	var sector_match: bool = (not sector_id.is_empty()) and (sector_id in contact.get("sector_ids", []))
	if bool(profile.get("sector_match_required", false)) and not sector_match:
		return false
	return has_category_match or sector_match


func _meeting_lead_contact_score(run_state, contact: Dictionary, profile: Dictionary, company_id: String, sector_id: String) -> float:
	var score: float = 0.0
	if not sector_id.is_empty() and sector_id in contact.get("sector_ids", []):
		score += 60.0
	for category_value in profile.get("category_ids", []):
		if str(category_value) in contact.get("categories", []):
			score += 18.0
	score += clamp(float(contact.get("reliability", 0.55)), 0.0, 1.0) * 12.0
	score += max(0.0, 55.0 - float(contact.get("recognition_required", 0))) * 0.08
	if _is_met(run_state, str(contact.get("id", ""))):
		score -= 18.0
	score += float(STABLE_RNG.seed_from_parts([company_id, str(profile.get("id", "")), str(contact.get("id", "")), "meeting_lead"]) % 1000) / 1000.0
	return score


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
	return int(MEETING_LEAD_TIER_ORDER.get(tier_id, 99))


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
	return definitions


func _generated_insider_definitions(run_state) -> Array:
	var insiders: Array = []
	for company_id_value in run_state.company_order:
		var company_id: String = str(company_id_value)
		insiders.append_array(_management_roster_for_company(run_state, company_id))
	return insiders


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
		row["affiliation_type"] = "insider"
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
	return {}


func _contact_row(contact: Dictionary, runtime: Dictionary, discovery: Dictionary, recognition: Dictionary) -> Dictionary:
	var affiliation_type: String = str(contact.get("affiliation_type", "floater"))
	var affiliated_company_id: String = str(contact.get("affiliated_company_id", contact.get("company_id", "")))
	var target_company_ids: Array = _contact_company_targets(discovery)
	var primary_target_company_id: String = str(discovery.get("target_company_id", affiliated_company_id))
	if primary_target_company_id.is_empty() and not target_company_ids.is_empty():
		primary_target_company_id = str(target_company_ids[0])
	return {
		"id": str(contact.get("id", "")),
		"display_name": str(contact.get("display_name", "")),
		"role": str(contact.get("role", "")),
		"intro": str(contact.get("intro", "")),
		"affiliation_type": affiliation_type,
		"affiliation_role": str(contact.get("affiliation_role", "")),
		"affiliated_company_id": affiliated_company_id,
		"company_id": affiliated_company_id,
		"template_contact_id": str(contact.get("template_contact_id", "")),
		"relationship": int(runtime.get("relationship", 0)),
		"met": bool(runtime.get("met", false)),
		"discovered": bool(discovery.get("discovered", false)),
		"can_meet": bool(discovery.get("discovered", false)) and not bool(runtime.get("met", false)) and (str(discovery.get("source_type", "")) == "referral" or int(recognition.get("score", 0)) >= int(contact.get("recognition_required", 0))),
		"recognition_required": int(contact.get("recognition_required", 0)),
		"source_type": str(discovery.get("source_type", "")),
		"source_id": str(discovery.get("source_id", "")),
		"referred_by_contact_id": str(discovery.get("referred_by_contact_id", "")),
		"connection_score": int(discovery.get("connection_score", 0)),
		"target_company_id": primary_target_company_id,
		"target_company_ids": target_company_ids,
		"target_sector_id": str(discovery.get("target_sector_id", contact.get("sector_id", ""))),
		"sector_ids": contact.get("sector_ids", []).duplicate(true),
		"categories": contact.get("categories", []).duplicate(true),
		"lead_score": int(discovery.get("lead_score", 0)),
		"last_tip_status": str(runtime.get("last_tip_status", "")),
		"last_tip_label": str(runtime.get("last_tip_label", "")),
		"last_tip_note": str(runtime.get("last_tip_note", "")),
		"last_tip_player_action_label": str(runtime.get("last_tip_player_action_label", "")),
		"last_tip_player_action_alignment": str(runtime.get("last_tip_player_action_alignment", "")),
		"last_tip_day_index": int(runtime.get("last_tip_day_index", 0)),
		"last_tip_request_day_index": int(runtime.get("last_tip_request_day_index", -9999)),
		"last_referral_day_index": int(runtime.get("last_referral_day_index", -9999)),
		"last_tip_followup_id": str(runtime.get("last_tip_followup_id", "")),
		"last_tip_followup_label": str(runtime.get("last_tip_followup_label", "")),
		"last_tip_followup_note": str(runtime.get("last_tip_followup_note", "")),
		"can_follow_up_tip": false,
		"tip_followup_options": [],
		"tip_history": [],
		"tip_reliability_label": "No track record yet",
		"tip_reliability_score": 50.0,
		"tip_resolved_count": 0,
		"tip_useful_count": 0,
		"tip_missed_count": 0,
		"cross_contact_label": "",
		"cross_contact_note": "",
		"cross_contact_rows": [],
		"has_direct_source_conflict": false,
		"can_ask_source_check": false,
		"source_check_label": "",
		"source_check_note": "",
		"source_check_day_index": 0
	}


func _contact_company_targets(discovery: Dictionary) -> Array:
	var targets: Array = []
	for company_id_value in discovery.get("target_company_ids", []):
		var company_id: String = str(company_id_value)
		if not company_id.is_empty() and not targets.has(company_id):
			targets.append(company_id)
	var primary_company_id: String = str(discovery.get("target_company_id", ""))
	if not primary_company_id.is_empty() and not targets.has(primary_company_id):
		targets.append(primary_company_id)
	return targets


func _can_add_company_lead(discovery: Dictionary, company_id: String) -> bool:
	if company_id.is_empty():
		return true
	var targets: Array = _contact_company_targets(discovery)
	return (not targets.has(company_id)) and targets.size() < MAX_COMPANY_LEADS_PER_FLOATER


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
	var rows: Array = []
	for tip_value in run_state.get_network_tip_journal().values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		rows.append(_network_tip_journal_row(tip))
		if str(tip.get("status", "pending")) != "pending":
			rows.append(_network_tip_resolution_journal_row(tip))
		if not str(tip.get("followup_note", "")).is_empty():
			rows.append(_network_tip_followup_journal_row(tip))
		if not str(tip.get("source_check_note", "")).is_empty():
			rows.append(_network_source_check_journal_row(tip))
	for request_value in requests.values():
		if typeof(request_value) != TYPE_DICTIONARY:
			continue
		rows.append(_network_request_journal_row(run_state, data_repository, request_value))
	for discovery_value in discoveries.values():
		if typeof(discovery_value) != TYPE_DICTIONARY:
			continue
		var discovery: Dictionary = discovery_value
		if str(discovery.get("source_type", "")) == "referral":
			rows.append(_network_referral_journal_row(run_state, data_repository, discovery))
		if str(discovery.get("source_type", "")) == MEETING_LEAD_SOURCE_TYPE:
			rows.append(_network_meeting_lead_journal_row(run_state, data_repository, discovery))
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_sort: int = int(a.get("sort_index", int(a.get("day_index", 0)) * 10))
		var b_sort: int = int(b.get("sort_index", int(b.get("day_index", 0)) * 10))
		if a_sort == b_sort:
			return str(a.get("id", "")) > str(b.get("id", ""))
		return a_sort > b_sort
	)
	if rows.size() > MAX_NETWORK_JOURNAL_ROWS:
		rows = rows.slice(0, MAX_NETWORK_JOURNAL_ROWS)
	return rows


func _network_tip_journal_row(tip: Dictionary) -> Dictionary:
	var day_index: int = int(tip.get("created_day_index", 0))
	var ticker: String = str(tip.get("target_ticker", ""))
	var read_label: String = str(tip.get("truth_label", "Network Read"))
	return {
		"id": "%s:tip" % str(tip.get("id", "")),
		"type": "tip",
		"day_index": day_index,
		"sort_index": day_index * 10 + 1,
		"contact_id": str(tip.get("contact_id", "")),
		"contact_name": str(tip.get("contact_name", "Contact")),
		"target_company_id": str(tip.get("target_company_id", "")),
		"target_ticker": ticker,
		"status": str(tip.get("status", "pending")),
		"title": "Tip | %s | %s" % [ticker, read_label],
		"detail": "%s gave a %s read. %s" % [
			str(tip.get("contact_name", "Contact")),
			str(tip.get("confidence_label", "soft")),
			str(tip.get("tip_read", ""))
		]
	}


func _network_tip_resolution_journal_row(tip: Dictionary) -> Dictionary:
	var day_index: int = int(tip.get("resolved_day_index", tip.get("created_day_index", 0)))
	return {
		"id": "%s:resolved" % str(tip.get("id", "")),
		"type": "tip_result",
		"day_index": day_index,
		"sort_index": day_index * 10 + 4,
		"contact_id": str(tip.get("contact_id", "")),
		"contact_name": str(tip.get("contact_name", "Contact")),
		"target_company_id": str(tip.get("target_company_id", "")),
		"target_ticker": str(tip.get("target_ticker", "")),
		"status": str(tip.get("status", "resolved")),
		"title": "Tip Result | %s | %s" % [
			str(tip.get("target_ticker", "")),
			str(tip.get("outcome_label", "Still pending"))
		],
		"detail": "%s | %s" % [
			str(tip.get("outcome_note", "")),
			str(tip.get("player_action_label", "No action"))
		]
	}


func _network_tip_followup_journal_row(tip: Dictionary) -> Dictionary:
	var day_index: int = int(tip.get("followup_day_index", tip.get("resolved_day_index", tip.get("created_day_index", 0))))
	return {
		"id": "%s:followup" % str(tip.get("id", "")),
		"type": "followup",
		"day_index": day_index,
		"sort_index": day_index * 10 + 6,
		"contact_id": str(tip.get("contact_id", "")),
		"contact_name": str(tip.get("contact_name", "Contact")),
		"target_company_id": str(tip.get("target_company_id", "")),
		"target_ticker": str(tip.get("target_ticker", "")),
		"status": "recorded",
		"title": "Follow-up | %s | %s" % [
			str(tip.get("target_ticker", "")),
			str(tip.get("followup_label", "Follow-up"))
		],
		"detail": str(tip.get("followup_note", ""))
	}


func _network_source_check_journal_row(tip: Dictionary) -> Dictionary:
	var day_index: int = int(tip.get("source_check_day_index", tip.get("created_day_index", 0)))
	return {
		"id": "%s:source_check" % str(tip.get("id", "")),
		"type": "source_check",
		"day_index": day_index,
		"sort_index": day_index * 10 + 7,
		"contact_id": str(tip.get("contact_id", "")),
		"contact_name": str(tip.get("contact_name", "Contact")),
		"target_company_id": str(tip.get("target_company_id", "")),
		"target_ticker": str(tip.get("target_ticker", "")),
		"status": "recorded",
		"title": "Source Check | %s | %s" % [
			str(tip.get("target_ticker", "")),
			str(tip.get("source_check_peer_contact_name", "conflict"))
		],
		"detail": str(tip.get("source_check_note", ""))
	}


func _network_request_journal_row(run_state, data_repository, request: Dictionary) -> Dictionary:
	var contact_id: String = str(request.get("contact_id", ""))
	var company_id: String = str(request.get("target_company_id", ""))
	var status: String = str(request.get("status", "pending"))
	var day_index: int = int(request.get("completed_day_index", request.get("created_day_index", 0))) if status != "pending" else int(request.get("created_day_index", 0))
	var contact_name: String = _contact_display_name(run_state, data_repository, contact_id)
	var ticker: String = _company_ticker(run_state, company_id)
	var due_date_text: String = _request_due_date_text(request)
	var detail: String = "Due date unknown."
	if due_date_text != "the due date":
		detail = "Due %s." % due_date_text
	if status == "completed":
		detail = "Completed after you held at least 1 lot."
	elif status == "missed":
		detail = "Missed because you did not hold the requested target."
	return {
		"id": "%s:request" % str(request.get("id", "")),
		"type": "request",
		"day_index": day_index,
		"sort_index": day_index * 10 + 3,
		"contact_id": contact_id,
		"contact_name": contact_name,
		"target_company_id": company_id,
		"target_ticker": ticker,
		"status": status,
		"title": "Request | %s | %s" % [ticker, status.capitalize()],
		"detail": "%s | %s" % [contact_name, detail]
	}


func _request_due_date_text(request: Dictionary) -> String:
	var due_day_index: int = int(request.get("due_day_index", 0))
	if due_day_index <= 0:
		return "the due date"
	var date_info: Dictionary = trading_calendar.trade_date_for_index(max(due_day_index, 1))
	var month_names := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var month_index: int = clamp(int(date_info.get("month", 1)) - 1, 0, month_names.size() - 1)
	return "%s %d, %d" % [
		month_names[month_index],
		int(date_info.get("day", 1)),
		int(date_info.get("year", 2020))
	]


func _network_referral_journal_row(run_state, data_repository, discovery: Dictionary) -> Dictionary:
	var referred_contact_id: String = str(discovery.get("contact_id", ""))
	var source_contact_id: String = str(discovery.get("referred_by_contact_id", discovery.get("source_id", "")))
	var day_index: int = int(discovery.get("day_index", 0))
	var referred_name: String = _contact_display_name(run_state, data_repository, referred_contact_id)
	var source_name: String = _contact_display_name(run_state, data_repository, source_contact_id)
	var company_id: String = str(discovery.get("target_company_id", ""))
	return {
		"id": "%s:referral" % referred_contact_id,
		"type": "referral",
		"day_index": day_index,
		"sort_index": day_index * 10 + 5,
		"contact_id": referred_contact_id,
		"contact_name": referred_name,
		"target_company_id": company_id,
		"target_ticker": _company_ticker(run_state, company_id),
		"status": "discovered",
		"title": "Referral | %s" % referred_name,
		"detail": "%s introduced this lead." % source_name
	}


func _network_meeting_lead_journal_row(run_state, data_repository, discovery: Dictionary) -> Dictionary:
	var contact_id: String = str(discovery.get("contact_id", ""))
	var company_id: String = str(discovery.get("target_company_id", ""))
	var day_index: int = int(discovery.get("day_index", 0))
	var contact_name: String = _contact_display_name(run_state, data_repository, contact_id)
	var ticker: String = _company_ticker(run_state, company_id)
	return {
		"id": "%s:meeting_lead:%s" % [contact_id, str(discovery.get("meeting_id", ""))],
		"type": "meeting_lead",
		"day_index": day_index,
		"sort_index": day_index * 10 + 5,
		"contact_id": contact_id,
		"contact_name": contact_name,
		"target_company_id": company_id,
		"target_ticker": ticker,
		"status": "met",
		"title": "RUPSLB Lead | %s" % contact_name,
		"detail": "Met during the %s meeting room." % ticker
	}


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
	var runtime: Dictionary = contacts.get(contact_id, {})
	runtime["relationship"] = clampi(int(runtime.get("relationship", 25)) + delta, 0, 100)
	contacts[contact_id] = runtime
	run_state.set_network_contacts(contacts)


func _mark_contact_day_flag(run_state, contact_id: String, flag_key: String) -> void:
	var contacts: Dictionary = run_state.get_network_contacts()
	var runtime: Dictionary = contacts.get(contact_id, {})
	runtime[flag_key] = run_state.day_index
	contacts[contact_id] = runtime
	run_state.set_network_contacts(contacts)


func _sentiment_for_contact(contact: Dictionary, action: String) -> float:
	var reliability: float = clamp(float(contact.get("reliability", 0.6)), 0.25, 0.95)
	var direction: float = -1.0 if str(contact.get("tone", "mixed")) == "negative" else 1.0
	if str(contact.get("tone", "mixed")) == "mixed":
		direction = 1.0 if action == "request" else 0.72
	return direction * lerp(0.009, 0.022, reliability)


func _contact_arc_description(contact: Dictionary, ticker: String, action: String) -> String:
	var verb: String = "tip" if action == "tip" else "request"
	return "%s gave you a %s tied to %s." % [str(contact.get("display_name", "A contact")), verb, ticker]
