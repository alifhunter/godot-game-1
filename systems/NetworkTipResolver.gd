extends RefCounted

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
const TIP_CAUTION_CONFIRMED_MOVE_PCT := -0.015
const TIP_CONSTRUCTIVE_CONFIRMED_MOVE_PCT := 0.018
const TIP_STRONG_UPSIDE_MOVE_PCT := 0.025
const TIP_STRONG_DOWNSIDE_MOVE_PCT := -0.025
const TIP_UNRESOLVED_ABS_MOVE_PCT := 0.012
const TIP_STATUS_PENDING := "pending"
const TIP_STATUS_RESOLVED := "resolved"
const TIP_STATUS_UNRESOLVED := "unresolved"
const STANCE_CONSTRUCTIVE := "constructive"
const STANCE_CAUTION := "caution"
const STANCE_TIMING_RISK := "timing_risk"
const STANCE_UNCERTAIN := "uncertain"


static func resolve_tip_memory(run_state, tip: Dictionary, chain: Dictionary) -> Dictionary:
	var company_id: String = str(tip.get("target_company_id", ""))
	var company: Dictionary = run_state.get_company(company_id)
	var current_price: float = float(company.get("current_price", tip.get("baseline_price", 0.0)))
	var baseline_price: float = max(float(tip.get("baseline_price", current_price)), 1.0)
	var change_pct: float = (current_price - baseline_price) / baseline_price
	var truth_label: String = str(tip.get("truth_label", TRUTH_LABEL_NETWORK_READ))
	var outcome_state: String = str(chain.get("outcome_state", ""))
	var timeline_state: String = str(chain.get("current_timeline_state", ""))
	var status: String = TIP_STATUS_RESOLVED
	var outcome_label: String = OUTCOME_LABEL_STILL_PENDING
	var relationship_delta: int = 0
	if tip_label_is_cautionary(truth_label):
		if change_pct <= TIP_CAUTION_CONFIRMED_MOVE_PCT or outcome_state == "cancelled" or timeline_state == "cancelled":
			outcome_label = OUTCOME_LABEL_USEFUL_WARNING
			relationship_delta = 3
		elif change_pct >= TIP_STRONG_UPSIDE_MOVE_PCT or outcome_state == "approved":
			outcome_label = OUTCOME_LABEL_MISSED_BADLY
			relationship_delta = -3
		elif absf(change_pct) <= TIP_UNRESOLVED_ABS_MOVE_PCT:
			outcome_label = OUTCOME_LABEL_STILL_PENDING
			status = TIP_STATUS_UNRESOLVED
		else:
			outcome_label = OUTCOME_LABEL_TOO_EARLY
	elif truth_label == TRUTH_LABEL_REAL_BUT_DELAYED:
		if timeline_state == "delayed":
			outcome_label = OUTCOME_LABEL_USEFUL_TIMING_READ
			relationship_delta = 2
		elif change_pct >= TIP_STRONG_UPSIDE_MOVE_PCT or outcome_state == "approved":
			outcome_label = OUTCOME_LABEL_EARLY_NOT_WRONG
			relationship_delta = 1
		elif change_pct <= TIP_STRONG_DOWNSIDE_MOVE_PCT or outcome_state == "cancelled":
			outcome_label = OUTCOME_LABEL_MISSED_BADLY
			relationship_delta = -3
		else:
			outcome_label = OUTCOME_LABEL_STILL_PENDING
			status = TIP_STATUS_UNRESOLVED
	else:
		if change_pct >= TIP_CONSTRUCTIVE_CONFIRMED_MOVE_PCT or outcome_state == "approved" or timeline_state in ["approved", "executing", "completed"]:
			outcome_label = OUTCOME_LABEL_USEFUL_READ
			relationship_delta = 3
		elif change_pct <= TIP_STRONG_DOWNSIDE_MOVE_PCT or outcome_state == "cancelled" or timeline_state == "cancelled":
			outcome_label = OUTCOME_LABEL_MISSED_BADLY
			relationship_delta = -3
		elif absf(change_pct) <= TIP_UNRESOLVED_ABS_MOVE_PCT:
			outcome_label = OUTCOME_LABEL_STILL_PENDING
			status = TIP_STATUS_UNRESOLVED
		else:
			outcome_label = OUTCOME_LABEL_TOO_EARLY
	var ticker: String = str(tip.get("target_ticker", company_id.to_upper()))
	var player_action: Dictionary = player_action_for_tip(run_state, tip)
	var player_read: Dictionary = player_tip_action_read(tip, outcome_label, player_action)
	relationship_delta += int(player_read.get("relationship_delta", 0))
	var outcome_note: String = tip_outcome_note(outcome_label, ticker, change_pct)
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


static func player_action_for_tip(run_state, tip: Dictionary) -> Dictionary:
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


static func player_tip_action_read(tip: Dictionary, outcome_label: String, player_action: Dictionary) -> Dictionary:
	var truth_label: String = str(tip.get("truth_label", TRUTH_LABEL_NETWORK_READ))
	var ticker: String = str(tip.get("target_ticker", str(tip.get("target_company_id", "")).to_upper()))
	var action_label: String = str(player_action.get("label", "Ignored"))
	var net_shares: int = int(player_action.get("net_shares", 0))
	var baseline_shares: int = int(player_action.get("baseline_shares", 0))
	var ending_shares: int = int(player_action.get("ending_shares", 0))
	var read_was_good: bool = outcome_label in GOOD_OUTCOME_LABELS
	var read_was_bad: bool = outcome_label == OUTCOME_LABEL_MISSED_BADLY
	var cautionary: bool = tip_label_is_cautionary(truth_label)
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


static func tip_label_is_cautionary(truth_label: String) -> bool:
	return truth_label in CAUTIONARY_TRUTH_LABELS


static func tip_outcome_note(outcome_label: String, ticker: String, change_pct: float) -> String:
	var pct_text: String = String.num(change_pct * 100.0, 1) + "%"
	match outcome_label:
		OUTCOME_LABEL_USEFUL_READ:
			return "Last read: useful. %s moved %s after the tip." % [ticker, pct_text]
		OUTCOME_LABEL_USEFUL_WARNING:
			return "Last read: useful warning. %s cooled %s after the tip." % [ticker, pct_text]
		OUTCOME_LABEL_USEFUL_TIMING_READ:
			return "Last read: useful timing read. The story did slow down."
		OUTCOME_LABEL_EARLY_NOT_WRONG:
			return "Last read: early, not wrong. %s kept moving, just faster than expected." % ticker
		OUTCOME_LABEL_TOO_EARLY:
			return "Last read: too early. %s moved %s, but the signal stayed mixed." % [ticker, pct_text]
		OUTCOME_LABEL_MISSED_BADLY:
			return "Last read: missed badly. %s moved against the read by %s." % [ticker, pct_text]
		_:
			return "Last read: still pending. %s has not confirmed or rejected the setup yet." % ticker


static func tip_histories_by_contact(tip_journal: Dictionary) -> Dictionary:
	var grouped: Dictionary = {}
	for tip_value in tip_journal.values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		var contact_id: String = str(tip.get("contact_id", ""))
		if contact_id.is_empty():
			continue
		if str(tip.get("status", TIP_STATUS_PENDING)) == TIP_STATUS_PENDING:
			continue
		var rows: Array = grouped.get(contact_id, [])
		rows.append(tip_history_row(tip))
		grouped[contact_id] = rows
	var histories: Dictionary = {}
	for contact_id_value in grouped.keys():
		var contact_id: String = str(contact_id_value)
		var rows: Array = grouped.get(contact_id, [])
		rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("resolved_day_index", 0)) > int(b.get("resolved_day_index", 0))
		)
		histories[contact_id] = tip_history_summary(rows)
	return histories


static func tip_history_row(tip: Dictionary) -> Dictionary:
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


static func tip_history_summary(rows: Array) -> Dictionary:
	var useful_count: int = 0
	var missed_count: int = 0
	var neutral_count: int = 0
	var scored_count: int = 0
	var score_total: float = 0.0
	for row_value in rows:
		var row: Dictionary = row_value
		var outcome_label: String = str(row.get("outcome_label", ""))
		if outcome_label in GOOD_OUTCOME_LABELS:
			useful_count += 1
			scored_count += 1
			score_total += 1.0
		elif outcome_label == OUTCOME_LABEL_MISSED_BADLY:
			missed_count += 1
			scored_count += 1
			score_total -= 1.0
		else:
			neutral_count += 1
	var reliability_score: float = 50.0
	if scored_count > 0:
		reliability_score = clamp(50.0 + (score_total / float(scored_count)) * 35.0, 0.0, 100.0)
	var reliability_label: String = tip_reliability_label(rows.size(), useful_count, missed_count, reliability_score)
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


static func tip_reliability_label(resolved_count: int, useful_count: int, missed_count: int, reliability_score: float) -> String:
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


static func cross_contact_reads_by_contact(tip_journal: Dictionary, day_index: int) -> Dictionary:
	var recent_rows: Array = []
	var min_day_index: int = day_index - 8
	for tip_value in tip_journal.values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		var contact_id: String = str(tip.get("contact_id", ""))
		var company_id: String = str(tip.get("target_company_id", ""))
		if contact_id.is_empty() or company_id.is_empty():
			continue
		if int(tip.get("created_day_index", 0)) < min_day_index:
			continue
		recent_rows.append(cross_contact_read_row(tip))
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
		var summary: Dictionary = cross_contact_summary(row, peers)
		var existing: Dictionary = result.get(contact_id, {})
		if existing.is_empty() or int(row.get("created_day_index", 0)) > int(existing.get("created_day_index", 0)):
			result[contact_id] = summary
	return result


static func cross_contact_read_row(tip: Dictionary) -> Dictionary:
	var truth_label: String = str(tip.get("truth_label", TRUTH_LABEL_NETWORK_READ))
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
		"status": str(tip.get("status", TIP_STATUS_PENDING)),
		"created_day_index": int(tip.get("created_day_index", 0)),
		"stance": truth_stance(truth_label)
	}


static func cross_contact_summary(current: Dictionary, peers: Array) -> Dictionary:
	var conflict_rows: Array = []
	var agreement_rows: Array = []
	var mixed_rows: Array = []
	var current_stance: String = str(current.get("stance", "uncertain"))
	for peer_value in peers:
		var peer: Dictionary = peer_value
		var peer_stance: String = str(peer.get("stance", "uncertain"))
		if truth_stances_conflict(current_stance, peer_stance):
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


static func truth_stance(truth_label: String) -> String:
	if tip_label_is_cautionary(truth_label):
		return STANCE_CAUTION
	if truth_label in CONSTRUCTIVE_TRUTH_LABELS:
		return STANCE_CONSTRUCTIVE
	if truth_label in TIMING_RISK_TRUTH_LABELS:
		return STANCE_TIMING_RISK
	return STANCE_UNCERTAIN


static func truth_stances_conflict(a: String, b: String) -> bool:
	return (a == STANCE_CONSTRUCTIVE and b == STANCE_CAUTION) or (a == STANCE_CAUTION and b == STANCE_CONSTRUCTIVE)


static func build_direct_tip_payload(run_state, account: Dictionary, account_state: Dictionary, selection: Dictionary) -> Dictionary:
	if str(selection.get("option_id", "")).strip_edges() != "direct_tip":
		return {}
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	if not (bool(profile.get("network_source", false)) or str(profile.get("account_origin", "")) == "network_contact"):
		return _direct_tip_unavailable("not_network_source", "I cannot give that kind of direct read from this account.")
	if str(account_state.get("relationship_stage", "")) != "inner_circle_candidate":
		return _direct_tip_unavailable("relationship_stage", "Not yet. The direct version needs more trust and a cleaner relationship first.")
	if run_state == null:
		return _direct_tip_unavailable("missing_run_state", "I cannot make that direct read without the current market context.")
	var contact_id: String = str(profile.get("network_contact_id", "")).strip_edges()
	if contact_id.is_empty():
		return _direct_tip_unavailable("missing_contact", "I cannot make that direct read without a real Network contact behind it.")
	var contacts: Dictionary = run_state.get_network_contacts()
	var runtime: Dictionary = contacts.get(contact_id, {}) if typeof(contacts.get(contact_id, {})) == TYPE_DICTIONARY else {}
	if not bool(runtime.get("met", false)):
		return _direct_tip_unavailable("contact_not_met", "I cannot give the direct version until we have a real contact relationship, not just a handle.")
	var discoveries: Dictionary = run_state.get_network_discoveries()
	var discovery: Dictionary = discoveries.get(contact_id, {}) if typeof(discoveries.get(contact_id, {})) == TYPE_DICTIONARY else {}
	var referral_required: bool = bool(discovery.get("referral_required", false)) or str(discovery.get("privacy_gate", "")) == "inner_circle" or int(profile.get("recognition_required", 0)) >= 90
	var referred: bool = str(discovery.get("source_type", "")) == "referral" or not str(discovery.get("referred_by_contact_id", "")).is_empty() or str(discovery.get("privacy_gate", "")) == "inner_circle"
	if referral_required and not referred:
		return _direct_tip_unavailable("missing_referral", "I cannot give the direct version unless this came through a private referral or a properly earned meeting.")
	var company_id: String = str(profile.get("target_company_id", discovery.get("target_company_id", ""))).strip_edges()
	var latest_tip: Dictionary = _direct_tip_latest_tip(run_state, contact_id, company_id)
	if company_id.is_empty():
		company_id = str(latest_tip.get("target_company_id", "")).strip_edges()
	var ticker: String = _direct_tip_ticker(run_state, profile, latest_tip, company_id)
	if ticker.is_empty():
		return _direct_tip_unavailable("missing_ticker", "I do not have a clean ticker for the direct version yet.")
	var truth_label: String = _direct_tip_truth_label(profile, account_state, latest_tip)
	var reliability: float = _direct_tip_reliability(profile, account_state)
	var direction: String = _direct_tip_direction(truth_label, reliability, account_state)
	var entry_timing: String = _direct_tip_entry_timing(account, ticker, direction, truth_label, int(run_state.day_index))
	var hold_period: String = _direct_tip_hold_period(account, ticker, direction, truth_label, int(run_state.day_index))
	var risk_note: String = _direct_tip_risk_note(truth_label, direction, ticker)
	var confidence_label: String = _direct_tip_confidence_label(reliability, account_state, latest_tip)
	var boundary_note: String = "confirm it against public tape, filings, or the next dated checkpoint"
	var payload: Dictionary = {
		"success": true,
		"payload_version": 1,
		"contact_id": contact_id,
		"contact_name": str(account.get("display_name", "Contact")),
		"target_company_id": company_id,
		"ticker": ticker,
		"direction": direction,
		"direction_label": _direct_tip_direction_label(direction),
		"entry_timing": entry_timing,
		"hold_period": hold_period,
		"confidence_label": confidence_label,
		"risk_note": risk_note,
		"public_boundary_note": boundary_note,
		"truth_label": truth_label,
		"source_tip_id": str(latest_tip.get("id", "")),
		"source_read_type": "journal_tip" if not latest_tip.is_empty() else "network_profile",
		"reliability": reliability,
		"relationship": int(account_state.get("relationship", 0)),
		"credibility": int(account_state.get("credibility", 0)),
		"importance": int(account_state.get("importance", 0))
	}
	payload["reply_text"] = _direct_tip_default_reply_text(payload)
	return payload


static func _direct_tip_unavailable(reason: String, reply_text: String) -> Dictionary:
	return {
		"success": false,
		"unavailable_reason": reason,
		"reply_text": reply_text
	}


static func _direct_tip_latest_tip(run_state, contact_id: String, company_id: String) -> Dictionary:
	var best: Dictionary = {}
	var best_day_index: int = -9999
	var journal: Dictionary = run_state.get_network_tip_journal()
	for tip_value in journal.values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		if str(tip.get("contact_id", "")) != contact_id:
			continue
		if not company_id.is_empty() and str(tip.get("target_company_id", "")) != company_id:
			continue
		if str(tip.get("truth_label", "")).is_empty():
			continue
		var created_day_index: int = int(tip.get("created_day_index", -9999))
		if best.is_empty() or created_day_index >= best_day_index:
			best = tip.duplicate(true)
			best_day_index = created_day_index
	return best


static func _direct_tip_ticker(run_state, profile: Dictionary, latest_tip: Dictionary, company_id: String) -> String:
	var ticker: String = str(profile.get("target_ticker", "")).strip_edges().to_upper()
	if ticker.is_empty():
		ticker = str(latest_tip.get("target_ticker", "")).strip_edges().to_upper()
	if ticker.is_empty() and run_state != null and not company_id.is_empty():
		var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
		ticker = str(definition.get("ticker", company_id.to_upper())).strip_edges().to_upper()
	return ticker


static func _direct_tip_reliability(profile: Dictionary, account_state: Dictionary) -> float:
	if profile.has("contact_reliability"):
		return clamp(float(profile.get("contact_reliability", 0.6)), 0.0, 1.0)
	var credibility_score: float = clamp(float(account_state.get("credibility", 0)) / 100.0, 0.0, 1.0)
	var importance_score: float = clamp(float(account_state.get("importance", 0)) / 100.0, 0.0, 1.0)
	return clamp(0.52 + credibility_score * 0.28 + importance_score * 0.16, 0.0, 1.0)


static func _direct_tip_truth_label(profile: Dictionary, account_state: Dictionary, latest_tip: Dictionary) -> String:
	var tip_truth_label: String = str(latest_tip.get("truth_label", "")).strip_edges()
	if not tip_truth_label.is_empty():
		return tip_truth_label
	var categories_text: String = " ".join(profile.get("categories", []) if typeof(profile.get("categories", [])) == TYPE_ARRAY else []).to_lower()
	var role_text: String = "%s %s %s" % [
		str(profile.get("role", "")),
		str(profile.get("affiliation_role", "")),
		categories_text
	]
	role_text = role_text.to_lower()
	var reliability: float = _direct_tip_reliability(profile, account_state)
	if str(profile.get("contact_tone", "")).to_lower() in ["negative", "guarded"]:
		return TRUTH_LABEL_PRESSURE_READ
	if role_text.find("legal") >= 0 or role_text.find("filing") >= 0 or role_text.find("corporate") >= 0 or categories_text.find("company") >= 0:
		return TRUTH_LABEL_FILING_BACKED if reliability >= 0.72 else TRUTH_LABEL_ROOM_RISK
	if role_text.find("flow") >= 0 or role_text.find("broker") >= 0 or role_text.find("bandar") >= 0:
		return TRUTH_LABEL_ACCUMULATION if reliability >= 0.68 else TRUTH_LABEL_EARLY_READ
	if reliability >= 0.80:
		return TRUTH_LABEL_ACCUMULATION
	if reliability <= 0.55:
		return TRUTH_LABEL_PRESSURE_READ
	return TRUTH_LABEL_NETWORK_READ


static func _direct_tip_direction(truth_label: String, reliability: float, account_state: Dictionary) -> String:
	if tip_label_is_cautionary(truth_label):
		return "avoid"
	if truth_label in TIMING_RISK_TRUTH_LABELS:
		return "watch"
	if reliability >= 0.68 and int(account_state.get("relationship", 0)) >= 70:
		return "buy"
	return "watch"


static func _direct_tip_direction_label(direction: String) -> String:
	match direction:
		"buy":
			return "Buy"
		"avoid":
			return "Avoid"
		"reduce":
			return "Reduce"
		_:
			return "Watch"


static func _direct_tip_entry_timing(account: Dictionary, ticker: String, direction: String, truth_label: String, day_index: int) -> String:
	var pool: Array = ["today", "tomorrow", "this week", "next week", "next month"]
	if direction == "watch":
		pool = ["today", "tomorrow", "this week", "next week"]
	elif tip_label_is_cautionary(truth_label):
		pool = ["today", "tomorrow", "this week"]
	return str(pool[int(abs(hash("%s|%s|%s|entry|%d" % [str(account.get("id", "")), ticker, direction, day_index]))) % pool.size()])


static func _direct_tip_hold_period(account: Dictionary, ticker: String, direction: String, truth_label: String, day_index: int) -> String:
	var pool: Array = ["for 3 trading days", "for 1 week", "for 2 weeks", "through the next public checkpoint"]
	if direction == "watch":
		pool = ["until the next public checkpoint", "for 3 trading days", "until volume confirms"]
	elif tip_label_is_cautionary(truth_label):
		pool = ["until the next public checkpoint", "until volume repairs", "until the filing trail clears"]
	return str(pool[int(abs(hash("%s|%s|%s|hold|%d" % [str(account.get("id", "")), ticker, direction, day_index]))) % pool.size()])


static func _direct_tip_risk_note(truth_label: String, direction: String, ticker: String) -> String:
	if tip_label_is_cautionary(truth_label):
		return "%s squeezes higher without matching public confirmation" % ticker
	match truth_label:
		TRUTH_LABEL_FILING_BACKED:
			return "the paperwork or formal notice slips"
		TRUTH_LABEL_ACCUMULATION:
			return "absorption disappears and volume turns into distribution"
		TRUTH_LABEL_EXECUTION_WATCH:
			return "execution news misses the next checkpoint"
		TRUTH_LABEL_REAL_BUT_DELAYED:
			return "the calendar slips again"
		TRUTH_LABEL_ROOM_RISK:
			return "the room resets the terms or timing"
		TRUTH_LABEL_EARLY_READ:
			return "follow-through fails before the story becomes public"
		_:
			if direction == "buy":
				return "the next public tape does not confirm"
			return "confirmation does not arrive"


static func _direct_tip_confidence_label(reliability: float, account_state: Dictionary, latest_tip: Dictionary) -> String:
	if not latest_tip.is_empty() and str(latest_tip.get("confidence_label", "")).strip_edges() != "":
		return str(latest_tip.get("confidence_label", ""))
	var relationship: int = int(account_state.get("relationship", 0))
	var credibility: int = int(account_state.get("credibility", 0))
	if reliability >= 0.82 and relationship >= 72 and credibility >= 45:
		return "high-trust read"
	if reliability >= 0.72:
		return "strong read"
	return "measured read"


static func _direct_tip_default_reply_text(payload: Dictionary) -> String:
	var direction: String = str(payload.get("direction", "watch"))
	var ticker: String = str(payload.get("ticker", "the stock"))
	if direction == "buy":
		return "Buy %s %s and hold %s. Confidence: %s. Risk: %s. Boundary: %s." % [
			ticker,
			str(payload.get("entry_timing", "this week")),
			str(payload.get("hold_period", "through the next public checkpoint")),
			str(payload.get("confidence_label", "measured read")),
			str(payload.get("risk_note", "confirmation does not arrive")),
			str(payload.get("public_boundary_note", "confirm it publicly"))
		]
	if direction == "avoid":
		return "Avoid buying %s %s; stay out %s unless %s clears. Confidence: %s. Boundary: %s." % [
			ticker,
			str(payload.get("entry_timing", "today")),
			str(payload.get("hold_period", "until the next public checkpoint")),
			str(payload.get("risk_note", "the risk")),
			str(payload.get("confidence_label", "measured read")),
			str(payload.get("public_boundary_note", "confirm it publicly"))
		]
	return "Watch %s %s and hold off %s unless %s clears. Confidence: %s. Boundary: %s." % [
		ticker,
		str(payload.get("entry_timing", "this week")),
		str(payload.get("hold_period", "until confirmation")),
		str(payload.get("risk_note", "confirmation does not arrive")),
		str(payload.get("confidence_label", "measured read")),
		str(payload.get("public_boundary_note", "confirm it publicly"))
	]


static func tip_followup_options(tip: Dictionary) -> Array:
	if not str(tip.get("followup_id", "")).is_empty():
		return []
	return [
		{"id": "thank", "label": "Thank"},
		{"id": "ask_why", "label": "Ask Why"},
		{"id": "challenge", "label": "Challenge"}
	]


static func build_tip_followup_result(contact: Dictionary, tip: Dictionary, followup_id: String) -> Dictionary:
	var contact_name: String = str(contact.get("display_name", "Contact"))
	var outcome_label: String = str(tip.get("outcome_label", OUTCOME_LABEL_STILL_PENDING))
	var player_action_label: String = str(tip.get("player_action_label", "No action"))
	var player_alignment: String = str(tip.get("player_action_alignment", "neutral"))
	var truth_label: String = str(tip.get("truth_label", TRUTH_LABEL_NETWORK_READ))
	var read_was_good: bool = outcome_label in GOOD_OUTCOME_LABELS
	var read_was_bad: bool = outcome_label == OUTCOME_LABEL_MISSED_BADLY
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
			note = tip_followup_explanation(contact_name, truth_label, outcome_label, player_action_label)
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


static func build_source_check_response(contact: Dictionary, run_state, source_check: Dictionary) -> Dictionary:
	var rows: Array = source_check.get("rows", [])
	var peer: Dictionary = {}
	if not rows.is_empty() and typeof(rows[0]) == TYPE_DICTIONARY:
		peer = rows[0]
	var contact_id: String = str(contact.get("id", ""))
	var contact_name: String = str(contact.get("display_name", "Contact"))
	var ticker: String = str(source_check.get("target_ticker", "this name"))
	var current_truth: String = str(source_check.get("current_truth_label", "this read"))
	var peer_truth: String = str(peer.get("truth_label", "the other read"))
	var current_stance: String = str(source_check.get("current_stance", STANCE_UNCERTAIN))
	var relationship: int = int(run_state.get_network_contacts().get(contact_id, {}).get("relationship", contact.get("base_relationship", 25)))
	var reliability: float = clamp(float(contact.get("reliability", 0.6)), 0.0, 1.0)
	var evidence_phrase: String = source_check_evidence_phrase(contact, str(source_check.get("current_source_role", "")))
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
		if current_stance == STANCE_CONSTRUCTIVE:
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
		if current_stance == STANCE_CONSTRUCTIVE:
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


static func source_check_evidence_phrase(contact: Dictionary, source_role: String) -> String:
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


static func tip_followup_explanation(contact_name: String, truth_label: String, outcome_label: String, player_action_label: String) -> String:
	if truth_label in CAUTIONARY_TRUTH_LABELS:
		return "%s says the warning was about crowding and weak follow-through. Your action: %s. Outcome: %s." % [contact_name, player_action_label, outcome_label]
	match truth_label:
		TRUTH_LABEL_ACCUMULATION:
			return "%s says the read came from absorption and follow-through, not the headline itself. Your action: %s. Outcome: %s." % [contact_name, player_action_label, outcome_label]
		TRUTH_LABEL_ROOM_RISK:
			return "%s says the meeting room mattered more than the first tape reaction. Your action: %s. Outcome: %s." % [contact_name, player_action_label, outcome_label]
		TRUTH_LABEL_REAL_BUT_DELAYED:
			return "%s says the story was real, but the calendar moved under it. Your action: %s. Outcome: %s." % [contact_name, player_action_label, outcome_label]
		_:
			return "%s says the read was only a lead until tape, filings, or another source confirmed it. Your action: %s. Outcome: %s." % [contact_name, player_action_label, outcome_label]
