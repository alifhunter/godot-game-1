extends RefCounted

const TRADING_CALENDAR = preload("res://systems/TradingCalendar.gd")

const DIFFICULTY_CHAIN_CAP := {
	"chill": 2,
	"normal": 3,
	"grind": 5
}
const V1_FAMILY_IDS := {
	"rights_issue": true,
	"stock_buyback": true,
	"stock_split": true,
	"ceo_change": true
}
const INTEL_LADDER := ["weak", "medium", "strong", "very_strong"]
const SESSION_STAGE_ORDER := ["arrival", "seating", "host_intro", "agenda_reveal", "vote", "result"]
const INTERACTIVE_RUPSLB_FAMILY_IDS := {
	"rights_issue": true
}

var trading_calendar = TRADING_CALENDAR.new()


func ensure_initialized(run_state, data_repository) -> void:
	var catalog: Dictionary = data_repository.get_corporate_action_catalog()
	if catalog.is_empty():
		return
	var calendar: Dictionary = run_state.get_corporate_meeting_calendar()
	if _ensure_annual_rups_meetings(run_state, catalog, calendar):
		run_state.set_corporate_meeting_calendar(calendar)


func resolve_day(
	run_state,
	data_repository,
	trade_date: Dictionary,
	day_number: int,
	macro_state: Dictionary,
	report_events: Array
) -> Dictionary:
	var catalog: Dictionary = data_repository.get_corporate_action_catalog()
	if catalog.is_empty():
		return {
			"active_corporate_action_chains": run_state.get_active_corporate_action_chains(),
			"corporate_meeting_calendar": run_state.get_corporate_meeting_calendar(),
			"corporate_action_intel": run_state.get_corporate_action_intel(),
			"attended_meetings": run_state.get_attended_meetings(),
			"corporate_meeting_sessions": run_state.get_corporate_meeting_sessions(),
			"corporate_action_events": [],
			"active_company_arcs": []
		}

	var chains: Dictionary = run_state.get_active_corporate_action_chains()
	var calendar: Dictionary = run_state.get_corporate_meeting_calendar()
	var intel: Dictionary = run_state.get_corporate_action_intel()
	var attended_meetings: Dictionary = run_state.get_attended_meetings()
	var meeting_sessions: Dictionary = run_state.get_corporate_meeting_sessions()
	var corporate_action_events: Array = []

	_ensure_annual_rups_meetings(run_state, catalog, calendar)
	_schedule_earnings_calls_for_reports(run_state, catalog, calendar, report_events, day_number)
	_refresh_meeting_statuses(calendar, attended_meetings, day_number)

	if _should_run_family_review(catalog, day_number):
		var spawn_result: Dictionary = _maybe_spawn_chain(
			run_state,
			catalog,
			trade_date,
			day_number,
			macro_state,
			chains,
			calendar
		)
		if not spawn_result.is_empty():
			var spawned_chain: Dictionary = spawn_result.get("chain", {})
			if not spawned_chain.is_empty():
				chains[str(spawned_chain.get("chain_id", ""))] = spawned_chain
			corporate_action_events.append_array(spawn_result.get("events", []))

	var next_chains: Dictionary = {}
	var chain_ids: Array = chains.keys()
	chain_ids.sort()
	for chain_id_value in chain_ids:
		var chain_id: String = str(chain_id_value)
		var chain: Dictionary = chains.get(chain_id, {}).duplicate(true)
		if chain.is_empty():
			continue
		var advance_result: Dictionary = _advance_chain(
			run_state,
			catalog,
			chain,
			trade_date,
			day_number,
			macro_state,
			calendar
		)
		var advanced_chain: Dictionary = advance_result.get("chain", {}).duplicate(true)
		corporate_action_events.append_array(advance_result.get("events", []))
		if advanced_chain.is_empty():
			continue
		if str(advanced_chain.get("status", "active")) == "completed" and str(advanced_chain.get("stage", "")) != "aftermath":
			continue
		next_chains[chain_id] = advanced_chain

	var active_company_arcs: Array = []
	var next_chain_ids: Array = next_chains.keys()
	next_chain_ids.sort()
	for chain_id_value in next_chain_ids:
		var chain: Dictionary = next_chains.get(str(chain_id_value), {})
		var arc: Dictionary = _build_chain_arc(catalog, chain, trade_date, day_number)
		if not arc.is_empty():
			active_company_arcs.append(arc)
	meeting_sessions = run_state.get_corporate_meeting_sessions()

	return {
		"active_corporate_action_chains": next_chains,
		"corporate_meeting_calendar": calendar,
		"corporate_action_intel": intel,
		"attended_meetings": attended_meetings,
		"corporate_meeting_sessions": meeting_sessions,
		"corporate_action_events": corporate_action_events,
		"active_company_arcs": active_company_arcs
	}


func get_meeting_snapshot(run_state, day_index: int = -1) -> Dictionary:
	var current_day_index: int = day_index if day_index > 0 else run_state.day_index
	var current_trade_date: Dictionary = run_state.get_current_trade_date()
	var calendar: Dictionary = run_state.get_corporate_meeting_calendar()
	var attended_meetings: Dictionary = run_state.get_attended_meetings()
	var holding_share_cache: Dictionary = {}
	var rows: Array = []
	var today_rows: Array = []
	for date_key_value in calendar.keys():
		var date_key: String = str(date_key_value)
		var meetings: Array = calendar.get(date_key, [])
		for meeting_value in meetings:
			var meeting: Dictionary = meeting_value
			if not _meeting_is_player_visible(meeting):
				continue
			var row: Dictionary = _meeting_row(meeting, run_state, attended_meetings, holding_share_cache)
			rows.append(row)
			if int(meeting.get("trading_day_number", -1)) == current_day_index + 1:
				today_rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("trading_day_number", 0)) == int(b.get("trading_day_number", 0)):
			return str(a.get("company_name", "")) < str(b.get("company_name", ""))
		return int(a.get("trading_day_number", 0)) < int(b.get("trading_day_number", 0))
	)
	today_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("company_name", "")) < str(b.get("company_name", ""))
	)
	var upcoming_rows: Array = []
	for row_value in rows:
		var row: Dictionary = row_value
		if int(row.get("trading_day_number", 0)) < current_day_index:
			continue
		upcoming_rows.append(row)
		if upcoming_rows.size() >= 12:
			break
	return {
		"day_index": current_day_index,
		"trade_date": current_trade_date,
		"today_rows": today_rows,
		"upcoming_rows": upcoming_rows,
		"all_rows": rows
	}


func get_dashboard_meeting_snapshot(run_state, day_index: int = -1, limit: int = 12) -> Dictionary:
	var current_day_index: int = day_index if day_index > 0 else run_state.day_index
	var current_trade_date: Dictionary = run_state.get_current_trade_date()
	var calendar: Dictionary = run_state.get_corporate_meeting_calendar()
	var attended_meetings: Dictionary = run_state.get_attended_meetings()
	var holding_share_cache: Dictionary = {}
	var today_rows: Array = []
	var upcoming_rows: Array = []
	var date_keys: Array = calendar.keys()
	date_keys.sort()
	for date_key_value in date_keys:
		var date_key: String = str(date_key_value)
		var meetings: Array = calendar.get(date_key, [])
		if meetings.is_empty():
			continue
		var first_meeting: Dictionary = meetings[0]
		var date_trading_day_number: int = int(first_meeting.get("trading_day_number", 0))
		if date_trading_day_number < current_day_index:
			continue
		var needs_today_rows: bool = date_trading_day_number == current_day_index + 1
		var needs_upcoming_rows: bool = limit <= 0 or upcoming_rows.size() < limit
		if not needs_today_rows and not needs_upcoming_rows:
			break
		var date_rows: Array = []
		for meeting_value in meetings:
			if typeof(meeting_value) != TYPE_DICTIONARY:
				continue
			var meeting: Dictionary = meeting_value
			if not _meeting_is_player_visible(meeting):
				continue
			var trading_day_number: int = int(meeting.get("trading_day_number", 0))
			if trading_day_number < current_day_index:
				continue
			var row: Dictionary = _meeting_row(meeting, run_state, attended_meetings, holding_share_cache)
			if trading_day_number == current_day_index + 1:
				today_rows.append(row)
			date_rows.append(row)
		date_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return str(a.get("company_name", "")) < str(b.get("company_name", ""))
		)
		for row_value in date_rows:
			if limit > 0 and upcoming_rows.size() >= limit:
				break
			upcoming_rows.append(row_value)
	today_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("company_name", "")) < str(b.get("company_name", ""))
	)
	return {
		"day_index": current_day_index,
		"trade_date": current_trade_date,
		"today_rows": today_rows,
		"upcoming_rows": upcoming_rows,
		"all_rows": []
	}


func get_meeting_detail(run_state, meeting_id: String) -> Dictionary:
	if meeting_id.is_empty():
		return {}
	var meeting: Dictionary = _meeting_by_id(run_state.get_corporate_meeting_calendar(), meeting_id)
	if meeting.is_empty():
		return {}
	var detail: Dictionary = meeting.duplicate(true)
	var chain_id: String = str(meeting.get("source_chain_id", ""))
	var intel: Dictionary = run_state.get_corporate_action_intel().get(chain_id, {}).duplicate(true)
	if not chain_id.is_empty():
		var chains: Dictionary = run_state.get_active_corporate_action_chains()
		if chains.has(chain_id):
			var chain: Dictionary = chains.get(chain_id, {}).duplicate(true)
			detail["chain"] = chain
			if detail.get("agenda_payload", []).is_empty():
				detail["agenda_payload"] = chain.get("agenda_payload", []).duplicate(true)
			detail["chain_family"] = str(chain.get("family", detail.get("chain_family", "")))
			detail["stage"] = str(chain.get("stage", detail.get("stage", "")))
			detail["management_stance"] = str(chain.get("management_stance", detail.get("management_stance", "")))
			detail["public_summary"] = _meeting_public_summary(chain)
	detail["intel"] = intel
	detail["attended"] = bool(run_state.get_attended_meetings().get(meeting_id, {}).get("attended", false))
	detail["family_label"] = _family_label(str(detail.get("chain_family", "")))
	detail["meeting_label"] = _meeting_type_label(str(detail.get("meeting_type", "")))
	detail["interactive_v1"] = _is_interactive_rupslb_meeting(detail)
	var attendance_gate: Dictionary = _meeting_attendance_gate(run_state, detail)
	detail["requires_shareholder"] = bool(attendance_gate.get("requires_shareholder", false))
	detail["attendance_eligible"] = bool(attendance_gate.get("eligible", true))
	detail["attendance_blocked_reason"] = str(attendance_gate.get("blocked_reason", ""))
	detail["player_shares_owned"] = int(attendance_gate.get("shares_owned", 0))
	if detail["interactive_v1"]:
		detail["session"] = run_state.get_corporate_meeting_sessions().get(meeting_id, {}).duplicate(true)
	return detail


func get_company_snapshot(run_state, company_id: String) -> Dictionary:
	if company_id.is_empty():
		return {}
	var chains: Array = _company_chains(run_state.get_active_corporate_action_chains(), company_id)
	var calendar: Dictionary = run_state.get_corporate_meeting_calendar()
	var intel_lookup: Dictionary = run_state.get_corporate_action_intel()
	var chain_rows: Array = []
	for chain_value in chains:
		var chain: Dictionary = chain_value
		var intel_bucket: Dictionary = intel_lookup.get(str(chain.get("chain_id", "")), {}).duplicate(true)
		var visible_meeting_id: String = ""
		var active_meeting_id: String = str(chain.get("active_meeting_id", ""))
		if not active_meeting_id.is_empty():
			var active_meeting: Dictionary = _meeting_by_id(calendar, active_meeting_id)
			if _meeting_is_player_visible(active_meeting):
				visible_meeting_id = active_meeting_id
		chain_rows.append({
			"chain_id": str(chain.get("chain_id", "")),
			"family": str(chain.get("family", "")),
			"family_label": _family_label(str(chain.get("family", ""))),
			"stage": str(chain.get("stage", "")),
			"current_timeline_state": str(chain.get("current_timeline_state", "")),
			"management_stance": str(chain.get("management_stance", "")),
			"meeting_id": visible_meeting_id,
			"public_summary": _meeting_public_summary(chain),
			"intel_summary": _intel_summary(intel_bucket),
			"intel_confidence": str(intel_bucket.get("confidence", ""))
		})
	var upcoming_meetings: Array = []
	for meeting_value in _company_meetings(calendar, company_id):
		var meeting: Dictionary = meeting_value
		if not _meeting_is_player_visible(meeting):
			continue
		upcoming_meetings.append(_meeting_row(meeting, run_state))
	upcoming_meetings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("trading_day_number", 0)) < int(b.get("trading_day_number", 0))
	)
	return {
		"company_id": company_id,
		"has_live_chain": not chain_rows.is_empty(),
		"chains": chain_rows,
		"upcoming_meetings": upcoming_meetings,
		"primary_chain": chain_rows[0] if not chain_rows.is_empty() else {}
	}


func attend_meeting(run_state, meeting_id: String) -> Dictionary:
	if meeting_id.is_empty():
		return {"success": false, "message": "No meeting selected."}
	var calendar: Dictionary = run_state.get_corporate_meeting_calendar()
	var meeting: Dictionary = _meeting_by_id(calendar, meeting_id)
	if meeting.is_empty():
		return {"success": false, "message": "Meeting not found."}
	var attendance_gate: Dictionary = _meeting_attendance_gate(run_state, meeting)
	if not bool(attendance_gate.get("eligible", true)):
		return {
			"success": false,
			"message": str(attendance_gate.get("blocked_reason", "Shareholder ownership is required to attend this meeting.")),
			"meeting": get_meeting_detail(run_state, meeting_id)
		}
	var attended_meetings: Dictionary = run_state.get_attended_meetings()
	if bool(attended_meetings.get(meeting_id, {}).get("attended", false)):
		return {"success": true, "message": "Already marked as attended.", "meeting": get_meeting_detail(run_state, meeting_id)}
	attended_meetings[meeting_id] = {
		"meeting_id": meeting_id,
		"attended": true,
		"day_index": run_state.day_index,
		"chain_id": str(meeting.get("source_chain_id", "")),
		"shares_owned": int(attendance_gate.get("shares_owned", 0))
	}
	_set_meeting_flag(calendar, meeting_id, "attended", true)
	run_state.set_attended_meetings(attended_meetings)
	run_state.set_corporate_meeting_calendar(calendar)
	var chain_id: String = str(meeting.get("source_chain_id", ""))
	if not chain_id.is_empty():
		var chain: Dictionary = run_state.get_active_corporate_action_chains().get(chain_id, {})
		if not chain.is_empty():
			var intel_result: Dictionary = _reveal_chain_intel(
				run_state.get_corporate_action_intel(),
				chain,
				"attend",
				"strong",
				[
					"family",
					"truth_level",
					"current_timeline_state",
					"management_stance",
					"agenda_payload",
					"approval_odds",
					"completion_odds",
					"next_expected_step"
				]
			)
			run_state.set_corporate_action_intel(intel_result.get("intel", {}))
	return {"success": true, "message": "Meeting attendance logged.", "meeting": get_meeting_detail(run_state, meeting_id)}


func start_meeting_session(run_state, data_repository, meeting_id: String) -> Dictionary:
	if meeting_id.is_empty():
		return {"success": false, "message": "No meeting selected."}
	var detail: Dictionary = get_meeting_detail(run_state, meeting_id)
	if detail.is_empty():
		return {"success": false, "message": "Meeting not found."}
	if not _is_interactive_rupslb_meeting(detail):
		return {"success": false, "message": "This meeting uses the standard venue flow."}
	var attendance_result: Dictionary = attend_meeting(run_state, meeting_id)
	if not bool(attendance_result.get("success", false)):
		return attendance_result
	var sessions: Dictionary = run_state.get_corporate_meeting_sessions()
	var session: Dictionary = sessions.get(meeting_id, {}).duplicate(true)
	if session.is_empty():
		session = _build_meeting_session_record(run_state, detail)
	var stage_id: String = str(session.get("presentation_stage", "arrival"))
	if str(session.get("selected_vote", "")).is_empty() and not session.get("resolved_result_summary", {}).is_empty():
		stage_id = "result"
	session["presentation_stage"] = _normalized_session_stage(stage_id)
	session["attended"] = true
	session["closed"] = false
	session["interactive_v1"] = true
	session["last_updated_day_index"] = run_state.day_index
	sessions[meeting_id] = session
	run_state.set_corporate_meeting_sessions(sessions)
	return {
		"success": true,
		"interactive": true,
		"message": "RUPSLB session opened.",
		"meeting": detail,
		"session": get_meeting_session_snapshot(run_state, data_repository, meeting_id)
	}


func get_meeting_session_snapshot(run_state, data_repository, meeting_id: String) -> Dictionary:
	if meeting_id.is_empty():
		return {}
	var detail: Dictionary = get_meeting_detail(run_state, meeting_id)
	if detail.is_empty() or not _is_interactive_rupslb_meeting(detail):
		return {}
	if bool(detail.get("requires_shareholder", false)) and not bool(detail.get("attendance_eligible", true)):
		return {}
	var sessions: Dictionary = run_state.get_corporate_meeting_sessions()
	var session: Dictionary = sessions.get(meeting_id, {}).duplicate(true)
	if session.is_empty():
		session = _build_meeting_session_record(run_state, detail)
	var family_id: String = str(detail.get("chain_family", ""))
	var presentation: Dictionary = _meeting_presentation_copy(data_repository.get_corporate_action_catalog(), family_id)
	var stage_labels: Dictionary = presentation.get("stage_labels", {}).duplicate(true)
	var stage_rows: Array = []
	for stage_id_value in SESSION_STAGE_ORDER:
		var stage_id: String = str(stage_id_value)
		stage_rows.append({
			"id": stage_id,
			"label": str(stage_labels.get(stage_id, stage_id.replace("_", " ").capitalize()))
		})
	var current_stage_id: String = _normalized_session_stage(str(session.get("presentation_stage", "arrival")))
	var agenda_payload: Array = detail.get("agenda_payload", []).duplicate(true)
	var result_summary: Dictionary = session.get("resolved_result_summary", {}).duplicate(true)
	if not result_summary.is_empty():
		current_stage_id = "result"
		session["presentation_stage"] = "result"
	var observer_copy: String = str(presentation.get("observer_copy", "Only verified shareholders can enter the vote room on the meeting day."))
	var vote_prompt: String = str(presentation.get("vote_prompt", "Cast your vote on the proposed agenda."))
	var host_intro_lines: Array = presentation.get("host_intro_lines", []).duplicate(true)
	var host_intro_text: String = ""
	if not host_intro_lines.is_empty():
		var intro_index: int = abs(hash("%s|host_intro" % [meeting_id])) % host_intro_lines.size()
		host_intro_text = str(host_intro_lines[intro_index])
	var result_copy: String = ""
	if not result_summary.is_empty():
		var result_copy_key: String = "approved_result_copy" if bool(result_summary.get("approved", false)) else "rejected_result_copy"
		result_copy = str(presentation.get(result_copy_key, ""))
	return {
		"meeting_id": meeting_id,
		"interactive": true,
		"meeting": detail,
		"session": session,
		"stages": stage_rows,
		"current_stage_id": current_stage_id,
		"current_stage_label": str(stage_labels.get(current_stage_id, current_stage_id.replace("_", " ").capitalize())),
		"agenda_payload": agenda_payload,
		"host_intro_text": host_intro_text,
		"observer_copy": observer_copy,
		"vote_prompt": vote_prompt,
		"result_copy": result_copy,
		"presentation": presentation,
		"result_summary": result_summary
	}


func set_meeting_session_stage(run_state, data_repository, meeting_id: String, stage_id: String) -> Dictionary:
	if meeting_id.is_empty():
		return {"success": false, "message": "No meeting selected."}
	var snapshot: Dictionary = get_meeting_session_snapshot(run_state, data_repository, meeting_id)
	if snapshot.is_empty():
		return {"success": false, "message": "Interactive session not available."}
	var sessions: Dictionary = run_state.get_corporate_meeting_sessions()
	var session: Dictionary = sessions.get(meeting_id, {}).duplicate(true)
	if session.is_empty():
		session = _build_meeting_session_record(run_state, snapshot.get("meeting", {}))
	var normalized_stage_id: String = _normalized_session_stage(stage_id)
	if not session.get("resolved_result_summary", {}).is_empty():
		normalized_stage_id = "result"
	session["presentation_stage"] = normalized_stage_id
	session["closed"] = false
	session["last_updated_day_index"] = run_state.day_index
	sessions[meeting_id] = session
	run_state.set_corporate_meeting_sessions(sessions)
	return {
		"success": true,
		"message": "Meeting session updated.",
		"session": get_meeting_session_snapshot(run_state, data_repository, meeting_id)
	}


func submit_meeting_vote(
	run_state,
	data_repository,
	meeting_id: String,
	agenda_id: String,
	vote_choice: String,
	ownership_snapshot: Dictionary
) -> Dictionary:
	if meeting_id.is_empty():
		return {"success": false, "message": "No meeting selected."}
	var detail: Dictionary = get_meeting_detail(run_state, meeting_id)
	if detail.is_empty() or not _is_interactive_rupslb_meeting(detail):
		return {"success": false, "message": "Interactive meeting not found."}
	if bool(detail.get("requires_shareholder", false)) and not bool(detail.get("attendance_eligible", true)):
		return {
			"success": false,
			"message": str(detail.get("attendance_blocked_reason", "Shareholder ownership is required to attend this meeting."))
		}
	var sessions: Dictionary = run_state.get_corporate_meeting_sessions()
	var session: Dictionary = sessions.get(meeting_id, {}).duplicate(true)
	if session.is_empty():
		session = _build_meeting_session_record(run_state, detail)
	var normalized_vote_choice: String = _normalized_vote_choice(vote_choice)
	var player_weight_pct: float = float(session.get("player_vote_weight_pct", ownership_snapshot.get("ownership_pct", 0.0)))
	var voting_eligible: bool = bool(session.get("voting_eligible", player_weight_pct > 0.0))
	if not voting_eligible and normalized_vote_choice != "abstain":
		return {"success": false, "message": "Voting requires current shareholder ownership on the meeting day."}
	var chain: Dictionary = detail.get("chain", {}).duplicate(true)
	var result_summary: Dictionary = _resolve_interactive_meeting_vote(
		data_repository.get_corporate_action_catalog(),
		meeting_id,
		chain,
		detail,
		ownership_snapshot,
		normalized_vote_choice
	)
	session["selected_vote"] = normalized_vote_choice
	session["presentation_stage"] = "result"
	session["player_vote_weight_pct"] = player_weight_pct
	session["voting_eligible"] = voting_eligible
	session["resolved_result_summary"] = result_summary
	session["closed"] = false
	session["consumed"] = false
	session["last_updated_day_index"] = run_state.day_index
	if agenda_id.is_empty():
		var agenda_payload: Array = detail.get("agenda_payload", [])
		if not agenda_payload.is_empty():
			session["agenda_id"] = str(agenda_payload[0].get("id", ""))
	else:
		session["agenda_id"] = agenda_id
	sessions[meeting_id] = session
	run_state.set_corporate_meeting_sessions(sessions)
	return {
		"success": true,
		"message": "Vote recorded. The market will only digest it on the next simulation day.",
		"session": get_meeting_session_snapshot(run_state, data_repository, meeting_id)
	}


func close_meeting_session(run_state, meeting_id: String) -> Dictionary:
	if meeting_id.is_empty():
		return {"success": false, "message": "No meeting selected."}
	var sessions: Dictionary = run_state.get_corporate_meeting_sessions()
	if not sessions.has(meeting_id):
		return {"success": true, "message": "Session already closed."}
	var session: Dictionary = sessions.get(meeting_id, {}).duplicate(true)
	session["closed"] = true
	session["last_updated_day_index"] = run_state.day_index
	sessions[meeting_id] = session
	run_state.set_corporate_meeting_sessions(sessions)
	return {"success": true, "message": "Meeting session closed."}


func request_contact_tip_intel(run_state, _data_repository, contact: Dictionary, company_id: String) -> Dictionary:
	var chain: Dictionary = _best_company_chain(run_state.get_active_corporate_action_chains(), company_id)
	if chain.is_empty():
		return {}
	var affiliation_type: String = str(contact.get("affiliation_type", "floater"))
	var quality: String = "weak"
	var fields: Array = ["family", "truth_level", "next_expected_step"]
	if affiliation_type == "insider":
		quality = "strong"
		fields = [
			"family",
			"truth_level",
			"current_timeline_state",
			"management_stance",
			"agenda_payload",
			"approval_odds",
			"completion_odds",
			"delay_risk",
			"next_expected_step"
		]
	else:
		if str(chain.get("stage", "")) in ["hidden_positioning", "unusual_activity", "rumor_leak"]:
			quality = "medium"
		fields = [
			"family",
			"truth_level",
			"smart_money_phase",
			"public_heat",
			"retail_positioning",
			"next_expected_step"
		]
		if str(chain.get("current_timeline_state", "")) == "delayed":
			quality = "very_strong"
			fields.append("current_timeline_state")
	var intel_result: Dictionary = _reveal_chain_intel(
		run_state.get_corporate_action_intel(),
		chain,
		str(contact.get("id", "")),
		quality,
		fields
	)
	run_state.set_corporate_action_intel(intel_result.get("intel", {}))
	return {
		"success": true,
		"chain_id": str(chain.get("chain_id", "")),
		"meeting_id": str(chain.get("active_meeting_id", "")),
		"message": str(intel_result.get("message", "")),
		"intel_quality": quality,
		"intel_summary": str(intel_result.get("summary", "")),
		"family_label": _family_label(str(chain.get("family", "")))
	}


func debug_spawn_chain(run_state, data_repository, company_id: String, family_id: String, day_number: int) -> Dictionary:
	var catalog: Dictionary = data_repository.get_corporate_action_catalog()
	var calendar: Dictionary = run_state.get_corporate_meeting_calendar()
	var chain: Dictionary = _build_new_chain(run_state, catalog, company_id, family_id, day_number)
	if chain.is_empty():
		return {}
	var chains: Dictionary = run_state.get_active_corporate_action_chains()
	chains[str(chain.get("chain_id", ""))] = chain
	run_state.set_active_corporate_action_chains(chains)
	if str(chain.get("expected_meeting_type", "")) == "annual_rups":
		_attach_chain_to_existing_annual_meeting(run_state, chain, calendar)
		run_state.set_corporate_meeting_calendar(calendar)
	return chain


func debug_force_stage(run_state, data_repository, chain_id: String, stage_id: String) -> Dictionary:
	var catalog: Dictionary = data_repository.get_corporate_action_catalog()
	var chains: Dictionary = run_state.get_active_corporate_action_chains()
	if not chains.has(chain_id):
		return {}
	var chain: Dictionary = chains.get(chain_id, {}).duplicate(true)
	chain["stage"] = stage_id
	chain["last_advanced_day_index"] = run_state.day_index
	chain["next_review_day_index"] = run_state.day_index + 1
	var stage_template: Dictionary = _stage_template(catalog, stage_id)
	chain["management_stance"] = _management_stance_for_stage(chain, stage_template)
	chains[chain_id] = chain
	run_state.set_active_corporate_action_chains(chains)
	return chain


func debug_force_rights_issue_rupslb(run_state, data_repository, company_id: String) -> Dictionary:
	var catalog: Dictionary = data_repository.get_corporate_action_catalog()
	if catalog.is_empty() or company_id.is_empty():
		return {}
	var chains: Dictionary = run_state.get_active_corporate_action_chains()
	if _company_has_live_chain(chains, company_id):
		return {}
	var day_number: int = max(run_state.day_index, 1)
	var chain: Dictionary = _build_new_chain(run_state, catalog, company_id, "rights_issue", day_number)
	if chain.is_empty():
		return {}
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	if definition.is_empty():
		return {}
	var current_trade_date: Dictionary = run_state.get_current_trade_date()
	var meeting_id: String = "rupslb|%s|%s|debug" % [company_id, str(chain.get("chain_id", ""))]
	var meeting: Dictionary = {
		"id": meeting_id,
		"meeting_type": "rupslb",
		"venue_type": "rupslb",
		"company_id": company_id,
		"ticker": str(definition.get("ticker", company_id.to_upper())),
		"company_name": str(definition.get("name", company_id.to_upper())),
		"target_sector_id": str(definition.get("sector_id", "")),
		"trade_date": current_trade_date.duplicate(true),
		"date_key": trading_calendar.to_key(current_trade_date),
		"trading_day_number": day_number,
		"status": "scheduled",
		"source_chain_id": str(chain.get("chain_id", "")),
		"chain_family": "rights_issue",
		"stage": "meeting_or_call",
		"management_stance": "confirm",
		"agenda_payload": chain.get("agenda_payload", []).duplicate(true),
		"public_summary": "",
		"attended": false
	}
	chain["stage"] = "meeting_or_call"
	chain["current_timeline_state"] = "active"
	chain["management_stance"] = "confirm"
	chain["public_heat"] = max(float(chain.get("public_heat", 0.0)), 0.42)
	chain["retail_positioning"] = max(float(chain.get("retail_positioning", 0.0)), 0.24)
	chain["active_meeting_id"] = meeting_id
	chain["last_advanced_day_index"] = day_number
	chain["next_review_day_index"] = day_number + 1
	chain["next_expected_step"] = "The room is waiting on the vote."
	meeting["public_summary"] = _meeting_public_summary(chain)
	var calendar: Dictionary = run_state.get_corporate_meeting_calendar()
	_add_meeting(calendar, meeting)
	run_state.set_corporate_meeting_calendar(calendar)
	chains[str(chain.get("chain_id", ""))] = chain
	run_state.set_active_corporate_action_chains(chains)
	var sessions: Dictionary = run_state.get_corporate_meeting_sessions()
	sessions.erase(meeting_id)
	run_state.set_corporate_meeting_sessions(sessions)
	return {
		"chain": chain,
		"meeting": meeting
	}


func debug_schedule_next_day_rights_issue_rupslb(run_state, data_repository, company_id: String) -> Dictionary:
	var catalog: Dictionary = data_repository.get_corporate_action_catalog()
	if catalog.is_empty() or company_id.is_empty():
		return {}
	var chains: Dictionary = run_state.get_active_corporate_action_chains()
	if _company_has_live_chain(chains, company_id):
		return {}
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	if definition.is_empty():
		return {}
	var current_trade_date: Dictionary = run_state.get_current_trade_date()
	var current_day_number: int = max(trading_calendar.trade_index_for_date(current_trade_date), 1)
	var meeting_date: Dictionary = trading_calendar.advance_trade_days(current_trade_date, 1)
	var meeting_day_number: int = max(trading_calendar.trade_index_for_date(meeting_date), current_day_number + 1)
	var chain: Dictionary = _build_new_chain(run_state, catalog, company_id, "rights_issue", current_day_number)
	if chain.is_empty():
		return {}
	var meeting_id: String = "rupslb|%s|%s|debug_next" % [company_id, str(chain.get("chain_id", ""))]
	chain["stage"] = "meeting_or_call"
	chain["current_timeline_state"] = "active"
	chain["management_stance"] = "confirm"
	chain["public_heat"] = max(float(chain.get("public_heat", 0.0)), 0.42)
	chain["retail_positioning"] = max(float(chain.get("retail_positioning", 0.0)), 0.24)
	chain["active_meeting_id"] = meeting_id
	chain["last_advanced_day_index"] = current_day_number
	chain["next_review_day_index"] = meeting_day_number
	chain["next_expected_step"] = "The room is waiting on the vote."
	var meeting: Dictionary = {
		"id": meeting_id,
		"meeting_type": "rupslb",
		"venue_type": "rupslb",
		"company_id": company_id,
		"ticker": str(definition.get("ticker", company_id.to_upper())),
		"company_name": str(definition.get("name", company_id.to_upper())),
		"target_sector_id": str(definition.get("sector_id", "")),
		"trade_date": meeting_date.duplicate(true),
		"date_key": trading_calendar.to_key(meeting_date),
		"trading_day_number": meeting_day_number,
		"status": "queued",
		"source_chain_id": str(chain.get("chain_id", "")),
		"chain_family": "rights_issue",
		"stage": "meeting_or_call",
		"management_stance": "confirm",
		"agenda_payload": chain.get("agenda_payload", []).duplicate(true),
		"public_summary": _meeting_public_summary(chain),
		"attended": false
	}
	var calendar: Dictionary = run_state.get_corporate_meeting_calendar()
	_add_meeting(calendar, meeting)
	run_state.set_corporate_meeting_calendar(calendar)
	chains[str(chain.get("chain_id", ""))] = chain
	run_state.set_active_corporate_action_chains(chains)
	var sessions: Dictionary = run_state.get_corporate_meeting_sessions()
	sessions.erase(meeting_id)
	run_state.set_corporate_meeting_sessions(sessions)
	return {
		"chain": chain,
		"meeting": meeting
	}


func _should_run_family_review(catalog: Dictionary, day_number: int) -> bool:
	var review_interval_days: int = max(int(catalog.get("review_interval_days", 5)), 1)
	return day_number <= 1 or day_number % review_interval_days == 0


func _maybe_spawn_chain(
	run_state,
	catalog: Dictionary,
	trade_date: Dictionary,
	day_number: int,
	macro_state: Dictionary,
	chains: Dictionary,
	calendar: Dictionary
) -> Dictionary:
	var difficulty_id: String = str(run_state.get_difficulty_config().get("id", "normal"))
	var active_cap: int = int(DIFFICULTY_CHAIN_CAP.get(difficulty_id, DIFFICULTY_CHAIN_CAP["normal"]))
	if chains.size() >= active_cap:
		return {}
	var candidates: Array = _build_spawn_candidates(run_state, catalog, macro_state, chains)
	if candidates.is_empty():
		return {}
	var picked: Dictionary = candidates[0]
	var company_id: String = str(picked.get("company_id", ""))
	var family_id: String = str(picked.get("family", ""))
	var chain: Dictionary = _build_new_chain(run_state, catalog, company_id, family_id, day_number)
	if chain.is_empty():
		return {}
	if str(chain.get("expected_meeting_type", "")) == "annual_rups":
		_attach_chain_to_existing_annual_meeting(run_state, chain, calendar)
	var spawned_event: Dictionary = _build_public_event(
		catalog,
		chain,
		trade_date,
		day_number,
		"corporate_action_rumor",
		"%s starts drawing quiet interest around %s" % [
			str(chain.get("target_ticker", "")),
			_family_label(family_id)
		],
		"%s is starting to attract quiet positioning around a possible %s storyline." % [
			str(chain.get("target_company_name", "")),
			_family_label(family_id).to_lower()
		]
	)
	return {
		"chain": chain,
		"events": [spawned_event] if not spawned_event.is_empty() else []
	}


func _build_spawn_candidates(run_state, catalog: Dictionary, macro_state: Dictionary, chains: Dictionary) -> Array:
	var candidates: Array = []
	for company_id_value in run_state.company_order:
		var company_id: String = str(company_id_value)
		if _company_has_live_chain(chains, company_id):
			continue
		var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
		var runtime: Dictionary = run_state.get_company(company_id)
		if definition.is_empty() or runtime.is_empty():
			continue
		for family_value in catalog.get("families", []):
			var family: Dictionary = family_value
			var family_id: String = str(family.get("id", ""))
			if family_id.is_empty() or not bool(family.get("enabled", false)) or not V1_FAMILY_IDS.has(family_id):
				continue
			if _family_conflicts(chains, company_id, family_id, family):
				continue
			var score: float = _score_family_for_company(run_state, definition, runtime, macro_state, family)
			if score < 0.45:
				continue
			candidates.append({
				"company_id": company_id,
				"family": family_id,
				"score": score
			})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	if candidates.size() > 8:
		candidates = candidates.slice(0, 8)
	return candidates


func _score_family_for_company(run_state, definition: Dictionary, runtime: Dictionary, macro_state: Dictionary, family: Dictionary) -> float:
	var family_id: String = str(family.get("id", ""))
	var financials: Dictionary = definition.get("financials", {})
	var profile: Dictionary = runtime.get("company_profile", {})
	var traits: Dictionary = profile.get("generation_traits", {})
	var current_price: float = float(runtime.get("current_price", definition.get("base_price", 0.0)))
	var starting_price: float = max(float(runtime.get("starting_price", current_price)), 1.0)
	var since_start_pct: float = (current_price - starting_price) / starting_price
	var debt_to_equity: float = float(financials.get("debt_to_equity", 0.0))
	var roe: float = float(financials.get("roe", 0.0))
	var margin: float = float(financials.get("net_profit_margin", 0.0))
	var free_float_pct: float = clamp(float(financials.get("free_float_pct", 30.0)) / 100.0, 0.0, 1.0)
	var controller_support: float = clamp(1.0 - free_float_pct, 0.0, 1.0)
	var growth: float = float(financials.get("revenue_growth_yoy", 0.0))
	var earnings_growth: float = float(financials.get("earnings_growth_yoy", 0.0))
	var balance_sheet_strength: float = float(traits.get("balance_sheet_strength", 0.5))
	var execution_consistency: float = float(traits.get("execution_consistency", 0.5))
	var story_heat: float = float(traits.get("story_heat", 0.5))
	var liquidity_profile: float = float(traits.get("liquidity_profile", 0.5))
	var capital_intensity: float = float(traits.get("capital_intensity", 0.5))
	var risk_appetite: float = float(macro_state.get("risk_appetite", 0.5))
	var score: float = 0.0
	match family_id:
		"rights_issue":
			score = (
				max(debt_to_equity - 0.8, 0.0) * 0.40 +
				max(0.0 - margin, 0.0) * 0.02 +
				max(0.0 - earnings_growth, 0.0) * 0.01 +
				max(0.55 - balance_sheet_strength, 0.0) * 0.85 +
				capital_intensity * 0.22 +
				controller_support * 0.18 +
				max(0.45 - risk_appetite, 0.0) * 0.12
			)
		"stock_buyback":
			score = (
				max(margin, 0.0) * 0.015 +
				max(roe, 0.0) * 0.018 +
				balance_sheet_strength * 0.55 +
				max(-since_start_pct, 0.0) * 0.75 +
				controller_support * 0.15 +
				max(0.45 - free_float_pct, 0.0) * 0.18
			)
		"stock_split":
			score = (
				clamp((current_price - 1200.0) / 1600.0, 0.0, 1.0) * 0.62 +
				max(since_start_pct, 0.0) * 0.42 +
				story_heat * 0.32 +
				liquidity_profile * 0.16 +
				max(risk_appetite - 0.45, 0.0) * 0.18
			)
		"ceo_change":
			score = (
				max(0.58 - execution_consistency, 0.0) * 0.95 +
				max(debt_to_equity - 0.7, 0.0) * 0.12 +
				max(0.0 - growth, 0.0) * 0.01 +
				max(0.0 - earnings_growth, 0.0) * 0.014 +
				max(-since_start_pct, 0.0) * 0.35 +
				controller_support * 0.12
			)
		_:
			score = 0.0
	return score * float(family.get("story_bias", 1.0))


func _build_new_chain(run_state, catalog: Dictionary, company_id: String, family_id: String, day_number: int) -> Dictionary:
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = run_state.get_company(company_id)
	if definition.is_empty() or runtime.is_empty():
		return {}
	var family: Dictionary = _family_definition(catalog, family_id)
	if family.is_empty():
		return {}
	var financials: Dictionary = definition.get("financials", {})
	var profile: Dictionary = runtime.get("company_profile", {})
	var traits: Dictionary = profile.get("generation_traits", {})
	var free_float_pct: float = clamp(float(financials.get("free_float_pct", 30.0)) / 100.0, 0.0, 1.0)
	var controller_support: float = clamp(1.0 - free_float_pct, 0.0, 1.0)
	var approval_odds: float = clamp(
		0.45 +
		controller_support * 0.35 +
		float(traits.get("execution_consistency", 0.5)) * 0.12 +
		float(traits.get("balance_sheet_strength", 0.5)) * 0.08,
		0.15,
		0.92
	)
	var completion_odds: float = clamp(
		0.5 +
		float(traits.get("execution_consistency", 0.5)) * 0.25 +
		float(traits.get("story_heat", 0.5)) * 0.08,
		0.18,
		0.9
	)
	var delay_risk: float = clamp(
		0.12 +
		max(float(financials.get("debt_to_equity", 0.0)) - 0.8, 0.0) * 0.16 +
		(0.15 if bool(family.get("supports_delay", false)) else 0.0),
		0.05,
		0.7
	)
	var cancellation_risk: float = clamp(
		0.08 +
		max(0.0 - float(financials.get("earnings_growth_yoy", 0.0)), 0.0) * 0.01 +
		max(0.0 - float(financials.get("net_profit_margin", 0.0)), 0.0) * 0.01,
		0.04,
		0.52
	)
	var funding_pressure: float = clamp(
		max(float(financials.get("debt_to_equity", 0.0)) - 0.8, 0.0) * 0.42 +
		max(0.0 - float(financials.get("net_profit_margin", 0.0)), 0.0) * 0.02 +
		max(0.55 - float(traits.get("balance_sheet_strength", 0.5)), 0.0) * 0.58 +
		float(traits.get("capital_intensity", 0.5)) * 0.24,
		0.08,
		0.95
	)
	var public_heat: float = clamp(float(traits.get("story_heat", 0.5)) * 0.35, 0.05, 0.45)
	var retail_positioning: float = clamp(public_heat * 0.55, 0.02, 0.35)
	var chain_id: String = "ca|%s|%s|%d" % [family_id, company_id, day_number]
	var stage_id: String = "hidden_positioning"
	var next_review_day_index: int = day_number + 1
	return {
		"chain_id": chain_id,
		"family": family_id,
		"company_id": company_id,
		"counterparty_company_id": "",
		"status": "active",
		"stage": stage_id,
		"started_day_index": day_number,
		"last_advanced_day_index": day_number,
		"next_review_day_index": next_review_day_index,
		"truth_level": "real",
		"current_timeline_state": "forming",
		"management_stance": "silent",
		"public_heat": public_heat,
		"retail_positioning": retail_positioning,
		"smart_money_phase": "accumulating",
		"frontrunner_strength": clamp(0.35 + controller_support * 0.4, 0.2, 0.92),
		"approval_odds": approval_odds,
		"completion_odds": completion_odds,
		"delay_risk": delay_risk,
		"cancellation_risk": cancellation_risk,
		"funding_pressure": funding_pressure,
		"market_overpricing": 0.0,
		"expected_meeting_type": str(family.get("default_venue_type", "")),
		"active_meeting_id": "",
		"agenda_payload": family.get("agendas", []).duplicate(true),
		"player_known_fields": [],
		"network_visibility": "limited",
		"outcome_state": "",
		"delay_cycles_used": 0,
		"next_expected_step": "Watch for unusual activity.",
		"target_ticker": str(definition.get("ticker", company_id.to_upper())),
		"target_company_name": str(definition.get("name", company_id.to_upper())),
		"target_sector_id": str(definition.get("sector_id", "")),
		"family_label": _family_label(family_id)
	}


func _advance_chain(
	run_state,
	catalog: Dictionary,
	chain: Dictionary,
	trade_date: Dictionary,
	day_number: int,
	_macro_state: Dictionary,
	calendar: Dictionary
) -> Dictionary:
	if int(chain.get("next_review_day_index", day_number + 1)) > day_number:
		return {"chain": chain, "events": []}

	var stage_id: String = str(chain.get("stage", "hidden_positioning"))
	var next_stage_id: String = stage_id
	var events: Array = []
	match stage_id:
		"hidden_positioning":
			next_stage_id = "unusual_activity"
			chain["smart_money_phase"] = "accumulating"
			chain["current_timeline_state"] = "forming"
		"unusual_activity":
			next_stage_id = "rumor_leak"
			chain["public_heat"] = clamp(float(chain.get("public_heat", 0.0)) + 0.08, 0.0, 1.0)
			chain["retail_positioning"] = clamp(float(chain.get("retail_positioning", 0.0)) + 0.04, 0.0, 1.0)
			events.append(_build_public_event(
				catalog,
				chain,
				trade_date,
				day_number,
				"corporate_action_rumor",
				"%s sparks fresh rumor flow" % str(chain.get("target_ticker", "")),
				"Talk around %s is picking up as traders chase a possible %s angle." % [
					str(chain.get("target_company_name", "")),
					_family_label(str(chain.get("family", ""))).to_lower()
				]
			))
		"rumor_leak":
			next_stage_id = "public_speculation"
			chain["public_heat"] = clamp(float(chain.get("public_heat", 0.0)) + 0.12, 0.0, 1.0)
			chain["retail_positioning"] = clamp(float(chain.get("retail_positioning", 0.0)) + 0.1, 0.0, 1.0)
			chain["smart_money_phase"] = "waiting"
			events.append(_build_public_event(
				catalog,
				chain,
				trade_date,
				day_number,
				"corporate_action_speculation",
				"%s speculation grows louder" % str(chain.get("target_ticker", "")),
				"Speculation around %s is broadening as more traders focus on a possible %s setup." % [
					str(chain.get("target_company_name", "")),
					_family_label(str(chain.get("family", ""))).to_lower()
				]
			))
		"public_speculation":
			next_stage_id = "management_response"
			chain["management_stance"] = "deny" if bool(_family_definition(catalog, str(chain.get("family", ""))).get("prefers_denial_response", false)) else "clarify"
			chain["next_expected_step"] = "Wait for management response."
		"management_response":
			var supports_delay: bool = bool(_family_definition(catalog, str(chain.get("family", ""))).get("supports_delay", false))
			var delayed_once: bool = int(chain.get("delay_cycles_used", 0)) > 0
			if supports_delay and not delayed_once and _roll(chain, "delay", day_number) < float(chain.get("delay_risk", 0.0)):
				chain["delay_cycles_used"] = int(chain.get("delay_cycles_used", 0)) + 1
				chain["current_timeline_state"] = "delayed"
				chain["management_stance"] = "deny"
				chain["smart_money_phase"] = "trapping"
				chain["market_overpricing"] = clamp(float(chain.get("market_overpricing", 0.0)) + 0.18, 0.0, 1.0)
				chain["public_heat"] = clamp(float(chain.get("public_heat", 0.0)) - 0.08, 0.0, 1.0)
				chain["retail_positioning"] = clamp(float(chain.get("retail_positioning", 0.0)) + 0.14, 0.0, 1.0)
				chain["next_expected_step"] = "The story looks delayed, but the chain is still alive."
				chain["last_advanced_day_index"] = day_number
				chain["next_review_day_index"] = day_number + 2
				events.append(_build_public_event(
					catalog,
					chain,
					trade_date,
					day_number,
					"corporate_action_denial",
					"%s management pushes back on market talk" % str(chain.get("target_ticker", "")),
					"%s is cooling speculation for now, but the tape still looks unstable." % str(chain.get("target_company_name", ""))
				))
				return {"chain": chain, "events": events}
			next_stage_id = "formal_agenda_or_filing"
			chain["current_timeline_state"] = "active"
			chain["management_stance"] = "clarify" if str(chain.get("management_stance", "")) == "deny" else "confirm"
			chain["smart_money_phase"] = "re_accumulating"
			chain["next_expected_step"] = "Watch for a formal agenda or filing."
			events.append(_build_public_event(
				catalog,
				chain,
				trade_date,
				day_number,
				"corporate_action_clarification",
				"%s story survives management pushback" % str(chain.get("target_ticker", "")),
				"%s is clarifying parts of the rumor flow as the market waits for something more formal." % str(chain.get("target_company_name", ""))
			))
		"formal_agenda_or_filing":
			var meeting_id: String = _ensure_chain_meeting(run_state, catalog, chain, calendar, day_number)
			chain["active_meeting_id"] = meeting_id
			var meeting: Dictionary = _meeting_by_id(calendar, meeting_id)
			var meeting_day_number: int = int(meeting.get("trading_day_number", day_number))
			if meeting_day_number > day_number:
				chain["last_advanced_day_index"] = day_number
				chain["next_review_day_index"] = meeting_day_number
				chain["next_expected_step"] = "The market is now waiting for %s." % _meeting_type_label(str(chain.get("expected_meeting_type", ""))).to_lower()
				events.append(_build_public_event(
					catalog,
					chain,
					trade_date,
					day_number,
					"corporate_action_filing",
					"%s formally schedules %s" % [
						str(chain.get("target_ticker", "")),
						_meeting_type_label(str(chain.get("expected_meeting_type", "")))
					],
					"%s now has a formal %s on the calendar tied to its %s storyline." % [
						str(chain.get("target_company_name", "")),
						_meeting_type_label(str(chain.get("expected_meeting_type", ""))).to_lower(),
						_family_label(str(chain.get("family", ""))).to_lower()
					]
				))
				return {"chain": chain, "events": events}
			next_stage_id = "meeting_or_call"
		"meeting_or_call":
			if _is_interactive_rupslb_chain(chain):
				var interactive_resolution: Dictionary = _consume_interactive_meeting_resolution(
					run_state,
					catalog,
					chain,
					trade_date,
					day_number,
					calendar
				)
				if not interactive_resolution.is_empty():
					return interactive_resolution
			next_stage_id = "resolution"
			chain["current_timeline_state"] = "active"
			chain["next_expected_step"] = "Await the meeting outcome."
			events.append(_build_meeting_event(chain, trade_date, day_number))
		"resolution":
			var approval_roll: float = _roll(chain, "approval", day_number)
			if approval_roll <= float(chain.get("approval_odds", 0.5)):
				chain["outcome_state"] = "approved"
				chain["current_timeline_state"] = "approved"
				chain["management_stance"] = "confirm"
				chain["smart_money_phase"] = "accumulating"
				chain["next_expected_step"] = "Watch for execution."
				next_stage_id = "execution"
				events.append(_build_public_event(
					catalog,
					chain,
					trade_date,
					day_number,
					"corporate_action_resolution",
					"%s approves key %s agenda" % [
						str(chain.get("target_ticker", "")),
						_family_label(str(chain.get("family", ""))).to_lower()
					],
					"%s clears a major approval hurdle and traders are now looking for execution follow-through." % str(chain.get("target_company_name", ""))
				))
			else:
				chain["outcome_state"] = "cancelled"
				chain["current_timeline_state"] = "cancelled"
				chain["truth_level"] = "dead"
				chain["management_stance"] = "evasive"
				chain["smart_money_phase"] = "distributing"
				chain["next_expected_step"] = "The story has broken down."
				next_stage_id = "aftermath"
				events.append(_build_public_event(
					catalog,
					chain,
					trade_date,
					day_number,
					"corporate_action_cancellation",
					"%s loses momentum after meeting setback" % str(chain.get("target_ticker", "")),
					"%s leaves the market dealing with a failed %s setup after the agenda falls short." % [
						str(chain.get("target_company_name", "")),
						_family_label(str(chain.get("family", ""))).to_lower()
					]
				))
		"execution":
			next_stage_id = "aftermath"
			chain["current_timeline_state"] = "executing"
			chain["outcome_state"] = "completed"
			chain["smart_money_phase"] = "distributing"
			chain["next_expected_step"] = "The market is moving into aftermath mode."
			events.append(_build_public_event(
				catalog,
				chain,
				trade_date,
				day_number,
				"corporate_action_execution",
				"%s enters execution phase" % str(chain.get("target_ticker", "")),
				"%s is moving from approval into execution, with price action now deciding whether the move can extend." % str(chain.get("target_company_name", ""))
			))
		"aftermath":
			return {"chain": {}, "events": events}
		_:
			next_stage_id = "aftermath"

	chain["stage"] = next_stage_id
	chain["last_advanced_day_index"] = day_number
	chain["next_review_day_index"] = day_number + 1
	chain["next_expected_step"] = _next_step_hint(next_stage_id, chain)
	if next_stage_id == "meeting_or_call":
		chain["current_timeline_state"] = "active"
	elif next_stage_id == "execution":
		chain["current_timeline_state"] = "approved"
	elif next_stage_id == "aftermath" and str(chain.get("outcome_state", "")) == "approved":
		chain["current_timeline_state"] = "completed"
	return {"chain": chain, "events": events}


func _build_chain_arc(catalog: Dictionary, chain: Dictionary, trade_date: Dictionary, day_number: int) -> Dictionary:
	var stage_template: Dictionary = _stage_template(catalog, str(chain.get("stage", "")))
	if stage_template.is_empty():
		return {}
	var sentiment_shift: float = float(stage_template.get("sentiment_shift", 0.0))
	var volatility_multiplier: float = float(stage_template.get("volatility_multiplier", 1.0))
	var tone: String = str(stage_template.get("tone", "mixed"))
	var category: String = str(stage_template.get("category", "corporate_action_speculation"))
	var current_timeline_state: String = str(chain.get("current_timeline_state", "active"))
	if current_timeline_state == "delayed":
		tone = "negative"
		category = "corporate_action_denial"
		sentiment_shift = -abs(sentiment_shift) * 1.35
		volatility_multiplier = max(volatility_multiplier, 1.18)
	elif str(chain.get("outcome_state", "")) == "cancelled":
		tone = "negative"
		category = "corporate_action_cancellation"
		sentiment_shift = -0.24
		volatility_multiplier = 1.16
	elif str(chain.get("stage", "")) == "execution" and str(chain.get("outcome_state", "")) == "approved":
		tone = "positive"
		sentiment_shift = 0.22
		volatility_multiplier = 1.18
	return {
		"arc_id": str(chain.get("chain_id", "")),
		"event_id": str(chain.get("family", "")),
		"event_family": "company_arc",
		"scope": "company",
		"category": category,
		"tone": tone,
		"target_company_id": str(chain.get("company_id", "")),
		"target_ticker": str(chain.get("target_ticker", "")),
		"target_company_name": str(chain.get("target_company_name", "")),
		"target_sector_id": str(chain.get("target_sector_id", "")),
		"description": _meeting_public_summary(chain),
		"source_system": "corporate_action",
		"source_chain_id": str(chain.get("chain_id", "")),
		"chain_family": str(chain.get("family", "")),
		"meeting_id": str(chain.get("active_meeting_id", "")),
		"venue_type": str(chain.get("expected_meeting_type", "")),
		"current_phase_id": str(chain.get("stage", "")),
		"current_phase_label": str(stage_template.get("label", "")),
		"phase_sentiment_shift": sentiment_shift,
		"phase_volatility_multiplier": volatility_multiplier,
		"phase_visibility": str(stage_template.get("visibility", "visible")),
		"phase_hidden_flag": "corporate_action_%s" % str(chain.get("family", "")),
		"day_index": day_number,
		"trade_date": trade_date.duplicate(true)
	}


func _build_public_event(
	catalog: Dictionary,
	chain: Dictionary,
	trade_date: Dictionary,
	day_number: int,
	category: String,
	headline: String,
	summary: String
) -> Dictionary:
	var tone: String = "positive"
	if category in ["corporate_action_denial", "corporate_action_cancellation"]:
		tone = "negative"
	elif category in ["corporate_action_clarification", "corporate_meeting"]:
		tone = "mixed"
	return {
		"event_id": str(chain.get("family", "")),
		"scope": "company",
		"event_family": "corporate_action",
		"category": category,
		"tone": tone,
		"target_company_id": str(chain.get("company_id", "")),
		"target_ticker": str(chain.get("target_ticker", "")),
		"target_company_name": str(chain.get("target_company_name", "")),
		"target_sector_id": str(chain.get("target_sector_id", "")),
		"headline": headline,
		"summary": summary,
		"description": _meeting_public_summary(chain),
		"sentiment_shift": _event_sentiment_shift(catalog, chain, category),
		"source_chain_id": str(chain.get("chain_id", "")),
		"chain_family": str(chain.get("family", "")),
		"meeting_id": str(chain.get("active_meeting_id", "")),
		"venue_type": str(chain.get("expected_meeting_type", "")),
		"trade_date": trade_date.duplicate(true),
		"day_index": day_number
	}


func _build_meeting_event(chain: Dictionary, trade_date: Dictionary, day_number: int) -> Dictionary:
	return {
		"event_id": str(chain.get("family", "")),
		"scope": "company",
		"event_family": "corporate_action",
		"category": "corporate_meeting",
		"tone": "mixed",
		"target_company_id": str(chain.get("company_id", "")),
		"target_ticker": str(chain.get("target_ticker", "")),
		"target_company_name": str(chain.get("target_company_name", "")),
		"target_sector_id": str(chain.get("target_sector_id", "")),
		"headline": "%s hosts %s" % [
			str(chain.get("target_ticker", "")),
			_meeting_type_label(str(chain.get("expected_meeting_type", "")))
		],
		"summary": "%s is holding a %s tied to its %s storyline." % [
			str(chain.get("target_company_name", "")),
			_meeting_type_label(str(chain.get("expected_meeting_type", ""))).to_lower(),
			_family_label(str(chain.get("family", ""))).to_lower()
		],
		"description": _meeting_public_summary(chain),
		"sentiment_shift": 0.08,
		"source_chain_id": str(chain.get("chain_id", "")),
		"chain_family": str(chain.get("family", "")),
		"meeting_id": str(chain.get("active_meeting_id", "")),
		"venue_type": str(chain.get("expected_meeting_type", "")),
		"trade_date": trade_date.duplicate(true),
		"day_index": day_number
	}


func _ensure_annual_rups_meetings(run_state, catalog: Dictionary, calendar: Dictionary) -> bool:
	var annual_config: Dictionary = catalog.get("annual_rups", {})
	var start_year: int = int(annual_config.get("start_year", 2020))
	var end_year: int = int(annual_config.get("end_year", 2030))
	var existing_meeting_ids: Dictionary = {}
	for meetings_value in calendar.values():
		if typeof(meetings_value) != TYPE_ARRAY:
			continue
		var meetings: Array = meetings_value
		for meeting_value in meetings:
			if typeof(meeting_value) != TYPE_DICTIONARY:
				continue
			var meeting_id_value: String = str(meeting_value.get("id", ""))
			if not meeting_id_value.is_empty():
				existing_meeting_ids[meeting_id_value] = true
	var changed: bool = false
	for company_id_value in run_state.company_order:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
		if definition.is_empty():
			continue
		for year_value in range(start_year, end_year + 1):
			var meeting_id: String = "annual_rups|%s|%d" % [company_id, year_value]
			if existing_meeting_ids.has(meeting_id):
				continue
			var meeting: Dictionary = _build_annual_rups_meeting(catalog, definition, company_id, year_value)
			if meeting.is_empty():
				continue
			_add_meeting(calendar, meeting)
			existing_meeting_ids[meeting_id] = true
			changed = true
	return changed


func _build_annual_rups_meeting(catalog: Dictionary, definition: Dictionary, company_id: String, year_value: int) -> Dictionary:
	var annual_config: Dictionary = catalog.get("annual_rups", {})
	var start_month: int = int(annual_config.get("start_month", 3))
	var end_month: int = int(annual_config.get("end_month", 6))
	var month_span: int = max(end_month - start_month, 0)
	var picked_month: int = start_month + int(abs(hash("%s|annual_month|%d" % [company_id, year_value]))) % (month_span + 1)
	var picked_day: int = 5 + int(abs(hash("%s|annual_day|%d" % [company_id, year_value]))) % 18
	var meeting_date: Dictionary = _trade_date_on_or_after(year_value, picked_month, picked_day)
	if meeting_date.is_empty():
		return {}
	var trading_day_number: int = trading_calendar.trade_index_for_date(meeting_date)
	return {
		"id": "annual_rups|%s|%d" % [company_id, year_value],
		"meeting_type": "annual_rups",
		"venue_type": "annual_rups",
		"company_id": company_id,
		"ticker": str(definition.get("ticker", company_id.to_upper())),
		"company_name": str(definition.get("name", company_id.to_upper())),
		"target_sector_id": str(definition.get("sector_id", "")),
		"trade_date": meeting_date,
		"date_key": trading_calendar.to_key(meeting_date),
		"trading_day_number": trading_day_number,
		"status": "scheduled",
		"source_chain_id": "",
		"chain_family": "",
		"stage": "annual_governance",
		"management_stance": "clarify",
		"agenda_payload": [
			{
				"id": "annual_governance_review",
				"label": "Review annual governance agenda",
				"description": "Shareholders review routine governance, board, and capital-allocation items."
			}
		],
		"public_summary": "%s is holding its annual RUPS governance meeting." % str(definition.get("name", company_id.to_upper())),
		"attended": false
	}


func _schedule_earnings_calls_for_reports(run_state, catalog: Dictionary, calendar: Dictionary, report_events: Array, day_number: int) -> void:
	for report_event_value in report_events:
		var report_event: Dictionary = report_event_value
		var company_id: String = str(report_event.get("target_company_id", ""))
		if company_id.is_empty():
			continue
		var meeting_id: String = "earnings_call|%s|%s" % [company_id, str(report_event.get("report_id", ""))]
		if not _meeting_by_id(calendar, meeting_id).is_empty():
			continue
		var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
		if definition.is_empty():
			continue
		var trade_date: Dictionary = report_event.get("trade_date", {})
		var delay_days: int = _meeting_delay_days(catalog, "earnings_call", company_id, int(report_event.get("day_index", day_number)))
		var meeting_date: Dictionary = trade_date.duplicate(true)
		if delay_days > 0:
			meeting_date = trading_calendar.advance_trade_days(meeting_date, delay_days)
		var trading_day_number: int = trading_calendar.trade_index_for_date(meeting_date)
		var meeting: Dictionary = {
			"id": meeting_id,
			"meeting_type": "earnings_call",
			"venue_type": "earnings_call",
			"company_id": company_id,
			"ticker": str(definition.get("ticker", company_id.to_upper())),
			"company_name": str(definition.get("name", company_id.to_upper())),
			"target_sector_id": str(definition.get("sector_id", "")),
			"trade_date": meeting_date,
			"date_key": trading_calendar.to_key(meeting_date),
			"trading_day_number": trading_day_number,
			"status": "scheduled",
			"source_chain_id": "",
			"chain_family": "",
			"stage": "earnings_call",
			"management_stance": "clarify",
			"agenda_payload": [
				{
					"id": "earnings_call_review",
					"label": "Quarterly review and guidance",
					"description": "Management walks through the filing, answers questions, and frames the next quarter."
				}
			],
			"public_summary": "%s is scheduled for an earnings call after its latest filing." % str(definition.get("name", company_id.to_upper())),
			"report_id": str(report_event.get("report_id", "")),
			"attended": false
		}
		_add_meeting(calendar, meeting)


func _refresh_meeting_statuses(calendar: Dictionary, attended_meetings: Dictionary, day_number: int) -> void:
	for date_key_value in calendar.keys():
		var date_key: String = str(date_key_value)
		var meetings: Array = calendar.get(date_key, []).duplicate(true)
		var changed: bool = false
		for meeting_index in range(meetings.size()):
			var meeting: Dictionary = meetings[meeting_index]
			var next_status: String = "completed" if int(meeting.get("trading_day_number", 0)) < day_number else "scheduled"
			if str(meeting.get("status", "")) != next_status:
				meeting["status"] = next_status
				changed = true
			var attended: bool = bool(attended_meetings.get(str(meeting.get("id", "")), {}).get("attended", false))
			if bool(meeting.get("attended", false)) != attended:
				meeting["attended"] = attended
				changed = true
			meetings[meeting_index] = meeting
		if changed:
			calendar[date_key] = meetings


func _ensure_chain_meeting(run_state, catalog: Dictionary, chain: Dictionary, calendar: Dictionary, day_number: int) -> String:
	var meeting_id: String = str(chain.get("active_meeting_id", ""))
	if not meeting_id.is_empty() and not _meeting_by_id(calendar, meeting_id).is_empty():
		return meeting_id
	var meeting_type: String = str(chain.get("expected_meeting_type", ""))
	if meeting_type == "annual_rups":
		var existing_id: String = _attach_chain_to_existing_annual_meeting(run_state, chain, calendar)
		return existing_id
	var definition: Dictionary = run_state.get_effective_company_definition(str(chain.get("company_id", "")), false, false)
	if definition.is_empty():
		return ""
	var base_date: Dictionary = run_state.get_current_trade_date()
	var delay_days: int = _meeting_delay_days(catalog, meeting_type, str(chain.get("company_id", "")), day_number)
	var meeting_date: Dictionary = trading_calendar.advance_trade_days(base_date, max(delay_days, 1))
	meeting_id = "%s|%s|%s" % [meeting_type, str(chain.get("company_id", "")), str(chain.get("chain_id", ""))]
	var meeting: Dictionary = {
		"id": meeting_id,
		"meeting_type": meeting_type,
		"venue_type": meeting_type,
		"company_id": str(chain.get("company_id", "")),
		"ticker": str(definition.get("ticker", "")),
		"company_name": str(definition.get("name", "")),
		"target_sector_id": str(definition.get("sector_id", "")),
		"trade_date": meeting_date,
		"date_key": trading_calendar.to_key(meeting_date),
		"trading_day_number": trading_calendar.trade_index_for_date(meeting_date),
		"status": "scheduled",
		"source_chain_id": str(chain.get("chain_id", "")),
		"chain_family": str(chain.get("family", "")),
		"stage": str(chain.get("stage", "")),
		"management_stance": str(chain.get("management_stance", "")),
		"agenda_payload": chain.get("agenda_payload", []).duplicate(true),
		"public_summary": _meeting_public_summary(chain),
		"attended": false
	}
	_add_meeting(calendar, meeting)
	return meeting_id


func _attach_chain_to_existing_annual_meeting(run_state, chain: Dictionary, calendar: Dictionary) -> String:
	var current_year: int = int(run_state.get_current_trade_date().get("year", 2020))
	var current_day_number: int = max(run_state.day_index + 1, 1)
	var company_id: String = str(chain.get("company_id", ""))
	var meeting_id: String = ""
	var meeting: Dictionary = {}
	for year_value in [current_year, current_year + 1]:
		var candidate_id: String = "annual_rups|%s|%d" % [company_id, year_value]
		var candidate_meeting: Dictionary = _meeting_by_id(calendar, candidate_id)
		if candidate_meeting.is_empty():
			continue
		if int(candidate_meeting.get("trading_day_number", 0)) >= current_day_number:
			meeting_id = candidate_id
			meeting = candidate_meeting
			break
	if meeting.is_empty():
		meeting_id = "annual_rups|%s|%d" % [company_id, current_year]
		meeting = _meeting_by_id(calendar, meeting_id)
	if meeting.is_empty():
		return ""
	var meetings: Array = calendar.get(str(meeting.get("date_key", "")), []).duplicate(true)
	for meeting_index in range(meetings.size()):
		if str(meetings[meeting_index].get("id", "")) != meeting_id:
			continue
		meeting = meetings[meeting_index].duplicate(true)
		meeting["source_chain_id"] = str(chain.get("chain_id", ""))
		meeting["chain_family"] = str(chain.get("family", ""))
		meeting["stage"] = str(chain.get("stage", ""))
		meeting["management_stance"] = str(chain.get("management_stance", ""))
		meeting["agenda_payload"] = chain.get("agenda_payload", []).duplicate(true)
		meeting["public_summary"] = _meeting_public_summary(chain)
		meetings[meeting_index] = meeting
		calendar[str(meeting.get("date_key", ""))] = meetings
		return meeting_id
	return ""


func _is_interactive_rupslb_chain(chain: Dictionary) -> bool:
	return str(chain.get("expected_meeting_type", "")) == "rupslb" and INTERACTIVE_RUPSLB_FAMILY_IDS.has(str(chain.get("family", "")))


func _is_interactive_rupslb_meeting(meeting: Dictionary) -> bool:
	var meeting_type: String = str(meeting.get("meeting_type", meeting.get("venue_type", "")))
	return meeting_type == "rupslb" and INTERACTIVE_RUPSLB_FAMILY_IDS.has(str(meeting.get("chain_family", "")))


func _meeting_requires_shareholder(meeting: Dictionary) -> bool:
	var meeting_type: String = str(meeting.get("meeting_type", meeting.get("venue_type", "")))
	return meeting_type in ["annual_rups", "rupslb"]


func _meeting_attendance_gate(run_state, meeting: Dictionary, holding_share_cache: Dictionary = {}) -> Dictionary:
	var requires_shareholder: bool = _meeting_requires_shareholder(meeting)
	var company_id: String = str(meeting.get("company_id", ""))
	var shares_owned: int = 0
	if not company_id.is_empty():
		if holding_share_cache.has(company_id):
			shares_owned = int(holding_share_cache.get(company_id, 0))
		else:
			shares_owned = int(run_state.get_holding(company_id).get("shares", 0))
			holding_share_cache[company_id] = shares_owned
	var eligible: bool = not requires_shareholder or shares_owned > 0
	var blocked_reason: String = ""
	if not eligible:
		var label: String = _meeting_type_label(str(meeting.get("meeting_type", meeting.get("venue_type", ""))))
		var ticker: String = str(meeting.get("ticker", company_id.to_upper()))
		blocked_reason = "%s attendance requires owning shares of %s. Buy at least 1 lot before attending." % [
			label,
			ticker
		]
	return {
		"requires_shareholder": requires_shareholder,
		"eligible": eligible,
		"shares_owned": shares_owned,
		"blocked_reason": blocked_reason
	}


func _normalized_session_stage(stage_id: String) -> String:
	var normalized_stage_id: String = stage_id.strip_edges().to_lower()
	if SESSION_STAGE_ORDER.has(normalized_stage_id):
		return normalized_stage_id
	return SESSION_STAGE_ORDER[0]


func _normalized_vote_choice(vote_choice: String) -> String:
	var normalized_vote_choice: String = vote_choice.strip_edges().to_lower()
	if normalized_vote_choice in ["agree", "disagree", "abstain"]:
		return normalized_vote_choice
	return "abstain"


func _meeting_presentation_copy(catalog: Dictionary, family_id: String) -> Dictionary:
	var family: Dictionary = _family_definition(catalog, family_id)
	var presentation: Dictionary = family.get("meeting_presentation", {}).duplicate(true)
	if presentation.is_empty():
		presentation = {
			"stage_labels": {
				"arrival": "Arrival",
				"seating": "Seating",
				"host_intro": "Host Intro",
				"agenda_reveal": "Agenda",
				"vote": "Vote",
				"result": "Result"
			},
			"host_intro_lines": [
				"The chair opens the meeting and frames the agenda for the room.",
				"Management moves to the podium and starts walking shareholders through the rationale."
			],
			"observer_copy": "Only verified shareholders can enter the vote room on the meeting day.",
			"vote_prompt": "Cast your vote on the published agenda.",
			"approved_result_copy": "The room clears the proposal and the market will react on the next simulation day.",
			"rejected_result_copy": "The room rejects the proposal and the market will react on the next simulation day."
		}
	return presentation


func _build_meeting_session_record(run_state, meeting: Dictionary) -> Dictionary:
	var company_id: String = str(meeting.get("company_id", ""))
	var ownership_snapshot: Dictionary = _ownership_snapshot_from_run_state(run_state, company_id)
	var agenda_payload: Array = meeting.get("agenda_payload", []).duplicate(true)
	return {
		"meeting_id": str(meeting.get("id", "")),
		"chain_id": str(meeting.get("source_chain_id", "")),
		"company_id": company_id,
		"presentation_stage": "arrival",
		"attended": bool(meeting.get("attended", false)),
		"voting_eligible": float(ownership_snapshot.get("player_pct", 0.0)) > 0.0,
		"selected_vote": "",
		"player_vote_weight_pct": float(ownership_snapshot.get("player_pct", 0.0)),
		"resolved_result_summary": {},
		"agenda_id": str(agenda_payload[0].get("id", "")) if not agenda_payload.is_empty() else "",
		"closed": false,
		"consumed": false,
		"interactive_v1": true,
		"created_day_index": run_state.day_index,
		"last_updated_day_index": run_state.day_index
	}


func _ownership_snapshot_from_run_state(run_state, company_id: String) -> Dictionary:
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	var holding: Dictionary = run_state.get_holding(company_id)
	if definition.is_empty():
		return {
			"company_id": company_id,
			"shares_owned": 0,
			"shares_outstanding": 0.0,
			"ownership_pct": 0.0,
			"player_pct": 0.0,
			"controller_pct": 0.0,
			"public_pct": 0.0
		}
	var financials: Dictionary = definition.get("financials", {})
	var shares_outstanding: float = max(
		float(definition.get("shares_outstanding", financials.get("shares_outstanding", 0.0))),
		0.0
	)
	var shares_owned: int = int(holding.get("shares", 0))
	var ownership_pct: float = 0.0
	if shares_outstanding > 0.0:
		ownership_pct = clamp(float(shares_owned) / shares_outstanding, 0.0, 1.0)
	var free_float_pct: float = clamp(float(financials.get("free_float_pct", 0.0)) / 100.0, 0.0, 1.0)
	var controlling_group_pct: float = clamp(1.0 - free_float_pct, 0.0, 1.0)
	var player_public_pct: float = min(ownership_pct, free_float_pct)
	var player_control_pct: float = max(ownership_pct - player_public_pct, 0.0)
	var public_pct: float = max(free_float_pct - player_public_pct, 0.0)
	var controller_pct: float = max(controlling_group_pct - player_control_pct, 0.0)
	return {
		"company_id": company_id,
		"shares_owned": shares_owned,
		"shares_outstanding": shares_outstanding,
		"ownership_pct": ownership_pct,
		"player_pct": ownership_pct,
		"controller_pct": controller_pct,
		"public_pct": public_pct
	}


func _resolve_interactive_meeting_vote(
	catalog: Dictionary,
	meeting_id: String,
	chain: Dictionary,
	_meeting: Dictionary,
	ownership_snapshot: Dictionary,
	player_vote_choice: String
) -> Dictionary:
	var controller_pct: float = float(ownership_snapshot.get("controller_pct", 0.0))
	var player_pct: float = float(ownership_snapshot.get("player_pct", 0.0))
	var public_pct: float = float(ownership_snapshot.get("public_pct", 0.0))
	var approval_odds: float = float(chain.get("approval_odds", 0.5))
	var funding_pressure: float = float(chain.get("funding_pressure", 0.5))
	var public_heat: float = float(chain.get("public_heat", 0.0))
	var market_overpricing: float = float(chain.get("market_overpricing", 0.0))
	var frontrunner_strength: float = float(chain.get("frontrunner_strength", 0.5))
	var management_stance: String = str(chain.get("management_stance", "clarify"))
	var timeline_state: String = str(chain.get("current_timeline_state", "active"))
	var public_noise: float = float(abs(hash("%s|public_vote" % [meeting_id])) % 1000) / 1000.0
	var controller_yes_bias: float = approval_odds * 0.68 + funding_pressure * 0.26 + frontrunner_strength * 0.12
	var controller_no_bias: float = (1.0 - approval_odds) * 0.38 + market_overpricing * 0.22 + (0.16 if management_stance == "deny" else 0.0)
	var controller_vote: String = "agree"
	if controller_no_bias > controller_yes_bias + 0.08:
		controller_vote = "disagree"
	elif abs(controller_yes_bias - controller_no_bias) <= 0.08:
		controller_vote = "abstain"

	var public_yes_share: float = clamp(
		approval_odds * 0.46 +
		funding_pressure * 0.14 +
		public_heat * 0.16 +
		(0.10 if management_stance in ["clarify", "confirm"] else -0.08) -
		market_overpricing * 0.18 +
		(public_noise - 0.5) * 0.18,
		0.05,
		0.82
	)
	var public_no_share: float = clamp(
		(1.0 - approval_odds) * 0.28 +
		market_overpricing * 0.24 +
		(0.12 if management_stance == "deny" else 0.0) +
		(0.08 if timeline_state == "delayed" else 0.0) +
		(0.5 - public_noise) * 0.12,
		0.05,
		0.82
	)
	var public_abstain_share: float = clamp(1.0 - public_yes_share - public_no_share, 0.06, 0.45)
	var public_total_share: float = public_yes_share + public_no_share + public_abstain_share
	public_yes_share /= public_total_share
	public_no_share /= public_total_share
	public_abstain_share /= public_total_share

	var controller_yes_pct: float = controller_pct if controller_vote == "agree" else 0.0
	var controller_no_pct: float = controller_pct if controller_vote == "disagree" else 0.0
	var controller_abstain_pct: float = controller_pct if controller_vote == "abstain" else 0.0
	var player_yes_pct: float = player_pct if player_vote_choice == "agree" else 0.0
	var player_no_pct: float = player_pct if player_vote_choice == "disagree" else 0.0
	var player_abstain_pct: float = player_pct if player_vote_choice == "abstain" else 0.0
	var public_yes_pct: float = public_pct * public_yes_share
	var public_no_pct: float = public_pct * public_no_share
	var public_abstain_pct: float = public_pct * public_abstain_share
	var yes_pct: float = controller_yes_pct + player_yes_pct + public_yes_pct
	var no_pct: float = controller_no_pct + player_no_pct + public_no_pct
	var abstain_pct: float = controller_abstain_pct + player_abstain_pct + public_abstain_pct
	var approved: bool = yes_pct > no_pct
	return {
		"approved": approved,
		"yes_pct": yes_pct,
		"no_pct": no_pct,
		"abstain_pct": abstain_pct,
		"player_vote": player_vote_choice,
		"player_weight_pct": player_pct,
		"bloc_rows": [
			{
				"bloc_id": "controller",
				"label": "Controlling Group",
				"agree_pct": controller_yes_pct,
				"disagree_pct": controller_no_pct,
				"abstain_pct": controller_abstain_pct,
				"decision": controller_vote,
				"note": "Controller weighting leaned on approval odds and funding pressure."
			},
			{
				"bloc_id": "player",
				"label": "Player",
				"agree_pct": player_yes_pct,
				"disagree_pct": player_no_pct,
				"abstain_pct": player_abstain_pct,
				"decision": player_vote_choice,
				"note": "Player influence uses owned shares on the meeting day."
			},
			{
				"bloc_id": "public",
				"label": "Public Float",
				"agree_pct": public_yes_pct,
				"disagree_pct": public_no_pct,
				"abstain_pct": public_abstain_pct,
				"decision": "split",
				"note": "Retail and float holders split across conviction, caution, and passivity."
			}
		],
		"result_category": "approved" if approved else "rejected"
	}


func _consume_interactive_meeting_resolution(
	run_state,
	catalog: Dictionary,
	chain: Dictionary,
	trade_date: Dictionary,
	day_number: int,
	calendar: Dictionary
) -> Dictionary:
	var meeting_id: String = str(chain.get("active_meeting_id", ""))
	if meeting_id.is_empty():
		return {}
	var detail: Dictionary = get_meeting_detail(run_state, meeting_id)
	if detail.is_empty():
		return {}
	var sessions: Dictionary = run_state.get_corporate_meeting_sessions()
	var session: Dictionary = sessions.get(meeting_id, {}).duplicate(true)
	if session.is_empty():
		session = _build_meeting_session_record(run_state, detail)
	var result_summary: Dictionary = session.get("resolved_result_summary", {}).duplicate(true)
	if result_summary.is_empty():
		var ownership_snapshot: Dictionary = _ownership_snapshot_from_run_state(run_state, str(chain.get("company_id", "")))
		result_summary = _resolve_interactive_meeting_vote(
			catalog,
			meeting_id,
			chain,
			detail,
			ownership_snapshot,
			"abstain"
		)
		session["selected_vote"] = "abstain"
		session["player_vote_weight_pct"] = float(ownership_snapshot.get("player_pct", 0.0))
		session["voting_eligible"] = float(ownership_snapshot.get("player_pct", 0.0)) > 0.0
		session["resolved_result_summary"] = result_summary
	session["presentation_stage"] = "result"
	session["closed"] = true
	session["consumed"] = true
	session["last_updated_day_index"] = run_state.day_index
	sessions[meeting_id] = session
	run_state.set_corporate_meeting_sessions(sessions)
	_set_meeting_flag(calendar, meeting_id, "status", "completed")
	_set_meeting_flag(calendar, meeting_id, "attended", bool(session.get("attended", false)))
	return _apply_interactive_meeting_result(catalog, chain, trade_date, day_number, result_summary)


func _apply_interactive_meeting_result(
	catalog: Dictionary,
	chain: Dictionary,
	trade_date: Dictionary,
	day_number: int,
	result_summary: Dictionary
) -> Dictionary:
	var events: Array = []
	var approved: bool = bool(result_summary.get("approved", false))
	var next_stage_id: String = "execution" if approved else "aftermath"
	chain["meeting_result_summary"] = result_summary.duplicate(true)
	if approved:
		chain["outcome_state"] = "approved"
		chain["current_timeline_state"] = "approved"
		chain["management_stance"] = "confirm"
		chain["smart_money_phase"] = "accumulating"
		chain["next_expected_step"] = "Watch for execution."
		events.append(_build_public_event(
			catalog,
			chain,
			trade_date,
			day_number,
			"corporate_action_resolution",
			"%s approves key %s agenda" % [
				str(chain.get("target_ticker", "")),
				_family_label(str(chain.get("family", ""))).to_lower()
			],
			"%s clears a major approval hurdle and traders are now looking for execution follow-through." % str(chain.get("target_company_name", ""))
		))
	else:
		chain["outcome_state"] = "cancelled"
		chain["current_timeline_state"] = "cancelled"
		chain["truth_level"] = "dead"
		chain["management_stance"] = "evasive"
		chain["smart_money_phase"] = "distributing"
		chain["next_expected_step"] = "The story has broken down."
		events.append(_build_public_event(
			catalog,
			chain,
			trade_date,
			day_number,
			"corporate_action_cancellation",
			"%s loses momentum after meeting setback" % str(chain.get("target_ticker", "")),
			"%s leaves the market dealing with a failed %s setup after the agenda falls short." % [
				str(chain.get("target_company_name", "")),
				_family_label(str(chain.get("family", ""))).to_lower()
			]
		))
	chain["stage"] = next_stage_id
	chain["last_advanced_day_index"] = day_number
	chain["next_review_day_index"] = day_number + 1
	chain["next_expected_step"] = _next_step_hint(next_stage_id, chain)
	if next_stage_id == "execution":
		chain["current_timeline_state"] = "approved"
	elif str(chain.get("outcome_state", "")) == "approved":
		chain["current_timeline_state"] = "completed"
	return {
		"chain": chain,
		"events": events
	}


func _reveal_chain_intel(intel_store: Dictionary, chain: Dictionary, source_id: String, quality: String, fields: Array) -> Dictionary:
	var chain_id: String = str(chain.get("chain_id", ""))
	var bucket: Dictionary = intel_store.get(chain_id, {
		"chain_id": chain_id,
		"discovered_fields": [],
		"sources": [],
		"confidence": "weak"
	}).duplicate(true)
	var discovered_fields: Array = bucket.get("discovered_fields", []).duplicate()
	for field_value in fields:
		var field_name: String = str(field_value)
		if not discovered_fields.has(field_name):
			discovered_fields.append(field_name)
		if chain.has(field_name):
			bucket[field_name] = chain.get(field_name)
	bucket["discovered_fields"] = discovered_fields
	var sources: Array = bucket.get("sources", []).duplicate()
	if not sources.has(source_id):
		sources.append(source_id)
	bucket["sources"] = sources
	bucket["confidence"] = _max_quality(str(bucket.get("confidence", "weak")), quality)
	bucket["best_known_truth_level"] = str(bucket.get("truth_level", chain.get("truth_level", "")))
	bucket["best_known_current_timeline_state"] = str(bucket.get("current_timeline_state", chain.get("current_timeline_state", "")))
	bucket["best_known_management_stance"] = str(bucket.get("management_stance", chain.get("management_stance", "")))
	bucket["best_known_next_expected_step"] = str(bucket.get("next_expected_step", chain.get("next_expected_step", "")))
	intel_store[chain_id] = bucket
	return {
		"intel": intel_store,
		"message": _intel_message(chain, quality),
		"summary": _intel_summary(bucket)
	}


func _intel_message(chain: Dictionary, quality: String) -> String:
	var family_label: String = _family_label(str(chain.get("family", "")))
	match quality:
		"very_strong":
			return "High-conviction read: %s looks real, but the timing is shifting." % family_label
		"strong":
			return "%s intel improved. The action looks real, but the tape can still shake out first." % family_label
		"medium":
			return "Something is building around %s." % family_label
		_:
			return "Your contact is hearing that something may be moving."


func _intel_summary(intel_bucket: Dictionary) -> String:
	var pieces: Array = []
	var family: String = str(intel_bucket.get("family", ""))
	if not family.is_empty():
		pieces.append(_family_label(family))
	var timeline_state: String = str(intel_bucket.get("best_known_current_timeline_state", intel_bucket.get("current_timeline_state", "")))
	if not timeline_state.is_empty():
		pieces.append(_timeline_state_label(timeline_state))
	var stance: String = str(intel_bucket.get("best_known_management_stance", intel_bucket.get("management_stance", "")))
	if not stance.is_empty():
		pieces.append(_management_stance_label(stance))
	var next_step: String = str(intel_bucket.get("best_known_next_expected_step", intel_bucket.get("next_expected_step", "")))
	if not next_step.is_empty():
		pieces.append(next_step)
	return " | ".join(pieces)


func _timeline_state_label(timeline_state: String) -> String:
	match timeline_state:
		"forming":
			return "Still forming"
		"active":
			return "Active"
		"delayed":
			return "Timing slipped"
		"approved":
			return "Approved"
		"executing":
			return "Execution underway"
		"completed":
			return "Completed"
		"cancelled":
			return "Cancelled"
		_:
			return timeline_state.replace("_", " ").capitalize()


func _management_stance_label(stance: String) -> String:
	match stance:
		"silent":
			return "Company quiet"
		"deny":
			return "Company denying it"
		"clarify":
			return "Company clarifying"
		"confirm":
			return "Company confirming"
		"evasive":
			return "Company evasive"
		_:
			return stance.replace("_", " ").capitalize()


func _meeting_is_player_visible(meeting: Dictionary) -> bool:
	if meeting.is_empty():
		return false
	return str(meeting.get("status", "scheduled")) != "queued"


func _meeting_row(meeting: Dictionary, run_state, attended_meetings: Variant = null, holding_share_cache: Dictionary = {}) -> Dictionary:
	var resolved_attended_meetings: Dictionary = attended_meetings if typeof(attended_meetings) == TYPE_DICTIONARY else run_state.get_attended_meetings()
	var attended: bool = bool(resolved_attended_meetings.get(str(meeting.get("id", "")), {}).get("attended", false))
	var attendance_gate: Dictionary = _meeting_attendance_gate(run_state, meeting, holding_share_cache)
	return {
		"id": str(meeting.get("id", "")),
		"meeting_type": str(meeting.get("meeting_type", "")),
		"meeting_label": _meeting_type_label(str(meeting.get("meeting_type", ""))),
		"company_id": str(meeting.get("company_id", "")),
		"company_name": str(meeting.get("company_name", "")),
		"ticker": str(meeting.get("ticker", "")),
		"trade_date": meeting.get("trade_date", {}).duplicate(true),
		"trading_day_number": int(meeting.get("trading_day_number", 0)),
		"status": str(meeting.get("status", "scheduled")),
		"attended": attended,
		"chain_family": str(meeting.get("chain_family", "")),
		"family_label": _family_label(str(meeting.get("chain_family", ""))),
		"source_chain_id": str(meeting.get("source_chain_id", "")),
		"public_summary": str(meeting.get("public_summary", "")),
		"stage": str(meeting.get("stage", "")),
		"management_stance": str(meeting.get("management_stance", "")),
		"interactive_v1": _is_interactive_rupslb_meeting(meeting),
		"requires_shareholder": bool(attendance_gate.get("requires_shareholder", false)),
		"attendance_eligible": bool(attendance_gate.get("eligible", true)),
		"attendance_blocked_reason": str(attendance_gate.get("blocked_reason", "")),
		"player_shares_owned": int(attendance_gate.get("shares_owned", 0))
	}


func _meeting_by_id(calendar: Dictionary, meeting_id: String) -> Dictionary:
	for date_key_value in calendar.keys():
		var meetings: Array = calendar.get(str(date_key_value), [])
		for meeting_value in meetings:
			var meeting: Dictionary = meeting_value
			if str(meeting.get("id", "")) == meeting_id:
				return meeting.duplicate(true)
	return {}


func _set_meeting_flag(calendar: Dictionary, meeting_id: String, key: String, value) -> void:
	for date_key_value in calendar.keys():
		var date_key: String = str(date_key_value)
		var meetings: Array = calendar.get(date_key, []).duplicate(true)
		var changed: bool = false
		for meeting_index in range(meetings.size()):
			if str(meetings[meeting_index].get("id", "")) != meeting_id:
				continue
			var meeting: Dictionary = meetings[meeting_index].duplicate(true)
			meeting[key] = value
			meetings[meeting_index] = meeting
			changed = true
			break
		if changed:
			calendar[date_key] = meetings
			return


func _company_chains(chains: Dictionary, company_id: String) -> Array:
	var rows: Array = []
	for chain_value in chains.values():
		var chain: Dictionary = chain_value
		if str(chain.get("company_id", "")) == company_id and str(chain.get("status", "active")) != "completed":
			rows.append(chain.duplicate(true))
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("started_day_index", 0)) > int(b.get("started_day_index", 0))
	)
	return rows


func _company_meetings(calendar: Dictionary, company_id: String) -> Array:
	var rows: Array = []
	for date_key_value in calendar.keys():
		var meetings: Array = calendar.get(str(date_key_value), [])
		for meeting_value in meetings:
			var meeting: Dictionary = meeting_value
			if str(meeting.get("company_id", "")) == company_id:
				rows.append(meeting.duplicate(true))
	return rows


func _best_company_chain(chains: Dictionary, company_id: String) -> Dictionary:
	var rows: Array = _company_chains(chains, company_id)
	if rows.is_empty():
		return {}
	return rows[0]


func _company_has_live_chain(chains: Dictionary, company_id: String) -> bool:
	for chain_value in chains.values():
		var chain: Dictionary = chain_value
		if str(chain.get("company_id", "")) != company_id:
			continue
		if str(chain.get("status", "active")) != "completed":
			return true
	return false


func _family_conflicts(chains: Dictionary, company_id: String, family_id: String, family: Dictionary) -> bool:
	var blocked_families: Array = family.get("mutually_exclusive_families", []).duplicate()
	for chain_value in chains.values():
		var chain: Dictionary = chain_value
		if str(chain.get("company_id", "")) != company_id:
			continue
		if str(chain.get("status", "active")) == "completed":
			continue
		var active_family: String = str(chain.get("family", ""))
		if active_family == family_id:
			return true
		if blocked_families.has(active_family):
			return true
	return false


func _stage_template(catalog: Dictionary, stage_id: String) -> Dictionary:
	return catalog.get("stage_templates", {}).get(stage_id, {}).duplicate(true)


func _family_definition(catalog: Dictionary, family_id: String) -> Dictionary:
	for family_value in catalog.get("families", []):
		var family: Dictionary = family_value
		if str(family.get("id", "")) == family_id:
			return family.duplicate(true)
	return {}


func _family_label(family_id: String) -> String:
	match family_id:
		"rights_issue":
			return "Rights Issue"
		"stock_buyback":
			return "Stock Buyback"
		"stock_split":
			return "Stock Split"
		"ceo_change":
			return "CEO Change"
		"private_placement":
			return "Private Placement"
		"restructuring":
			return "Restructuring"
		"strategic_merger_acquisition":
			return "Strategic M&A"
		"backdoor_listing":
			return "Backdoor Listing"
		_:
			return family_id.replace("_", " ").capitalize()


func _management_stance_for_stage(chain: Dictionary, _stage_template: Dictionary) -> String:
	var stage_id: String = str(chain.get("stage", ""))
	match stage_id:
		"management_response":
			return "deny"
		"formal_agenda_or_filing":
			return "clarify"
		"meeting_or_call", "resolution", "execution":
			return "confirm"
		_:
			return str(chain.get("management_stance", "silent"))


func _meeting_type_label(meeting_type: String) -> String:
	match meeting_type:
		"earnings_call":
			return "Earnings Call"
		"annual_rups":
			return "Annual RUPS"
		"rupslb":
			return "RUPSLB"
		_:
			return meeting_type.replace("_", " ").capitalize()


func _next_step_hint(stage_id: String, chain: Dictionary) -> String:
	match stage_id:
		"unusual_activity":
			return "Watch for tape changes and fresher chatter."
		"rumor_leak":
			return "The market is starting to whisper."
		"public_speculation":
			return "Retail attention is starting to build."
		"management_response":
			return "The next clue is how management responds."
		"formal_agenda_or_filing":
			return "The market now wants a filing or meeting date."
		"meeting_or_call":
			return "The market is waiting for the room outcome."
		"resolution":
			return "The market wants the vote or call result."
		"execution":
			return "Now the tape will decide whether the move can keep going."
		"aftermath":
			return "The story is in its aftermath."
		_:
			return str(chain.get("next_expected_step", ""))


func _meeting_public_summary(chain: Dictionary) -> String:
	return "%s is now in the %s stage of a %s storyline, with management stance at %s." % [
		str(chain.get("target_company_name", "")),
		str(chain.get("stage", "")).replace("_", " "),
		_family_label(str(chain.get("family", ""))).to_lower(),
		str(chain.get("management_stance", "silent"))
	]


func _event_sentiment_shift(catalog: Dictionary, chain: Dictionary, category: String) -> float:
	var stage_id: String = str(chain.get("stage", "public_speculation"))
	var stage_template: Dictionary = _stage_template(catalog, stage_id)
	var shift: float = float(stage_template.get("sentiment_shift", 0.0))
	if category in ["corporate_action_denial", "corporate_action_cancellation"]:
		return -abs(shift) * 1.35
	if category == "corporate_action_filing":
		return max(shift, 0.18)
	if category == "corporate_action_resolution":
		return max(shift, 0.16)
	return shift


func _meeting_delay_days(catalog: Dictionary, meeting_type: String, company_id: String, seed_value: int) -> int:
	var defaults: Dictionary = catalog.get("meeting_defaults", {}).get(meeting_type, {})
	var min_days: int = int(defaults.get("delay_min_days", defaults.get("fallback_delay_min_days", 0)))
	var max_days: int = int(defaults.get("delay_max_days", defaults.get("fallback_delay_max_days", min_days)))
	if max_days <= min_days:
		return min_days
	return min_days + int(abs(hash("%s|meeting_delay|%s|%d" % [company_id, meeting_type, seed_value]))) % (max_days - min_days + 1)


func _trade_date_on_or_after(year_value: int, month_value: int, day_value: int) -> Dictionary:
	var current: Dictionary = trading_calendar.start_date()
	var safety: int = 0
	while safety < 5000:
		var current_year: int = int(current.get("year", 2020))
		var current_month: int = int(current.get("month", 1))
		var current_day: int = int(current.get("day", 1))
		if current_year > year_value:
			break
		if current_year == year_value:
			if current_month > month_value or (current_month == month_value and current_day >= day_value):
				return current.duplicate(true)
		current = trading_calendar.next_trade_date(current)
		safety += 1
	return {}


func _add_meeting(calendar: Dictionary, meeting: Dictionary) -> void:
	if meeting.is_empty():
		return
	var date_key: String = str(meeting.get("date_key", ""))
	if date_key.is_empty():
		return
	var meetings: Array = calendar.get(date_key, []).duplicate(true)
	for meeting_index in range(meetings.size()):
		if str(meetings[meeting_index].get("id", "")) == str(meeting.get("id", "")):
			meetings[meeting_index] = meeting.duplicate(true)
			calendar[date_key] = meetings
			return
	meetings.append(meeting.duplicate(true))
	meetings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("company_name", "")) < str(b.get("company_name", ""))
	)
	calendar[date_key] = meetings


func _roll(chain: Dictionary, key: String, day_number: int) -> float:
	var seed_key: String = "%s|%s|%d" % [str(chain.get("chain_id", "")), key, day_number]
	var raw_value: int = abs(hash(seed_key)) % 1000
	return float(raw_value) / 1000.0


func _max_quality(a: String, b: String) -> String:
	var a_index: int = INTEL_LADDER.find(a)
	var b_index: int = INTEL_LADDER.find(b)
	if a_index < 0:
		return b
	if b_index < 0:
		return a
	return a if a_index >= b_index else b
