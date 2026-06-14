extends Node

const RUN_SEED := 706134
const HIGH_CONTACT_ID := "pak_gunawan_personal_lawyer"
const BRIDGE_CONTACT_ID := "pak_budihardjo_energy_dir"
const HIGH_CONTACT_REQUIRED_RECOGNITION := 95
const INNER_CIRCLE_REFERRAL_ROLE := "inner_circle"
const INNER_RELATIONSHIP := 72
const INNER_CREDIBILITY := 48
const INNER_IMPORTANCE := 58
const ADVANCE_DAYS_FOR_TIP := 4
const LOW_CONTACT_IDS := [
	"journalist_ayu_larasati",
	"budi_supply_chain",
	"andika_brokerage_sales",
	"aryo_port_ops",
	"pak_asep_coal_hauler",
	"aulia_consumer_brand",
	"bagas_fuel_station_mgr",
	"pak_bonar_cement_sales"
]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	_reset_daily_actions()

	var high_contact: Dictionary = _contact_definition(HIGH_CONTACT_ID)
	if high_contact.is_empty():
		_fail("High-recognition scenario missing contact definition: %s." % HIGH_CONTACT_ID)
		return
	if int(high_contact.get("recognition_required", 0)) < HIGH_CONTACT_REQUIRED_RECOGNITION:
		_fail("High-recognition scenario target no longer requires high recognition.")
		return

	var target_company: Dictionary = _company_context_for_contact(high_contact)
	if target_company.is_empty():
		_fail("High-recognition scenario expected at least one generated company.")
		return

	var low_recognition: Dictionary = GameManager.get_network_snapshot().get("recognition", {})
	if int(low_recognition.get("score", 0)) >= HIGH_CONTACT_REQUIRED_RECOGNITION:
		_fail("Fresh run unexpectedly started above the high-recognition gate.")
		return

	var blocked_rows: Array = GameManager.discover_network_contacts_from_article(_article_for_high_contact(target_company, high_contact, "blocked_gate"))
	if _contains_contact(blocked_rows, HIGH_CONTACT_ID) or RunState.get_network_discoveries().has(HIGH_CONTACT_ID):
		_fail("High-recognition contact should not discover before recognition gate is met.")
		return

	_seed_high_recognition_state(target_company)
	var high_recognition: Dictionary = GameManager.get_network_snapshot().get("recognition", {})
	if float(high_recognition.get("score", 0.0)) < HIGH_CONTACT_REQUIRED_RECOGNITION or int(high_recognition.get("contact_cap", 0)) < 12:
		_fail("Expected top-tier recognition after seed, got %s." % JSON.stringify(high_recognition))
		return

	var discovered_rows: Array = GameManager.discover_network_contacts_from_article(_article_for_high_contact(target_company, high_contact, "public_after_recognition"))
	if _contains_contact(discovered_rows, HIGH_CONTACT_ID) or RunState.get_network_discoveries().has(HIGH_CONTACT_ID):
		_fail("High-recognition contact should remain private after recognition gate; expected referral unlock.")
		return
	if not _network_account_for_contact(HIGH_CONTACT_ID).is_empty():
		_fail("High-recognition contact should not produce a Network Twooter account before referral/met.")
		return

	_seed_inner_circle_bridge_state(BRIDGE_CONTACT_ID, target_company)
	_reset_daily_actions()
	var referral_result: Dictionary = GameManager.request_contact_referral(BRIDGE_CONTACT_ID, str(target_company.get("id", "")), INNER_CIRCLE_REFERRAL_ROLE)
	if not bool(referral_result.get("success", false)):
		_fail("Inner-circle referral failed: %s." % str(referral_result.get("message", "")))
		return
	if str(referral_result.get("contact_id", "")) != HIGH_CONTACT_ID:
		_fail("Inner-circle referral expected %s, got %s." % [HIGH_CONTACT_ID, str(referral_result.get("contact_id", ""))])
		return
	var unlocked_row: Dictionary = _network_row(HIGH_CONTACT_ID, "discoveries")
	if unlocked_row.is_empty() or not bool(unlocked_row.get("can_meet", false)):
		_fail("High-recognition contact should be meetable after private referral, row=%s." % JSON.stringify(unlocked_row))
		return
	if str(unlocked_row.get("source_type", "")) != "referral" or str(unlocked_row.get("referred_by_contact_id", "")) != BRIDGE_CONTACT_ID:
		_fail("High-recognition unlock should preserve private referral provenance, row=%s." % JSON.stringify(unlocked_row))
		return
	_assert_referral_provenance(unlocked_row, "discovery")

	_reset_daily_actions()
	var meet_result: Dictionary = GameManager.meet_contact(HIGH_CONTACT_ID, {"source_type": "high_recognition_test"})
	if not bool(meet_result.get("success", false)):
		_fail("High-recognition contact meet failed: %s." % str(meet_result.get("message", "")))
		return
	_set_contact_relationship(HIGH_CONTACT_ID, INNER_RELATIONSHIP)
	var met_referral_row: Dictionary = _network_row(HIGH_CONTACT_ID, "contacts")
	if met_referral_row.is_empty():
		_fail("High-recognition contact should move into met contact rows after meeting.")
		return
	_assert_referral_provenance(met_referral_row, "met contact")

	var account: Dictionary = _network_account_for_contact(HIGH_CONTACT_ID)
	if account.is_empty():
		_fail("High-recognition contact did not produce a Network Twooter account.")
		return
	var account_id: String = str(account.get("id", ""))
	_seed_inner_circle_account_state(account_id)
	var follow_result: Dictionary = GameManager.follow_twooter_account(account_id)
	if not bool(follow_result.get("success", false)):
		_fail("High-recognition account follow failed: %s." % str(follow_result.get("message", "")))
		return
	var inner_state: Dictionary = RunState.get_twooter_social_state().get("account_states", {}).get(account_id, {})
	if str(inner_state.get("relationship_stage", "")) != "inner_circle_candidate":
		_fail("Expected saved Twooter account state to reach inner_circle_candidate, got %s." % JSON.stringify(inner_state))
		return
	var inner_account: Dictionary = _network_account_for_contact(HIGH_CONTACT_ID)
	if str(inner_account.get("relationship_stage", "")) != "inner_circle_candidate":
		_fail("Expected enhanced Network Twooter account to expose inner_circle_candidate, got %s." % JSON.stringify(inner_account))
		return

	var dialog_audit: Dictionary = _run_inner_circle_dialog(account_id)
	if not bool(dialog_audit.get("success", false)):
		_fail(str(dialog_audit.get("message", "Inner-circle dialog audit failed.")))
		return
	var referral_journal_row: Dictionary = _snapshot_referral_journal_row(HIGH_CONTACT_ID)
	if referral_journal_row.is_empty():
		_fail("Expected Network snapshot journal to expose referral provenance row.")
		return
	_assert_referral_journal_row(referral_journal_row)
	var direct_tip_journal_row: Dictionary = _snapshot_direct_tip_journal_row(HIGH_CONTACT_ID)
	if direct_tip_journal_row.is_empty():
		_fail("Expected Network snapshot journal to expose inner-circle direct-tip row.")
		return
	_assert_direct_tip_journal_row(direct_tip_journal_row)
	inner_state = RunState.get_twooter_social_state().get("account_states", {}).get(account_id, {})

	_reset_daily_actions()
	var tip_result: Dictionary = GameManager.request_contact_tip(HIGH_CONTACT_ID, str(target_company.get("id", "")))
	if not bool(tip_result.get("success", false)):
		_fail("High-recognition contact tip request failed: %s." % str(tip_result.get("message", "")))
		return
	var high_tip_id: String = _latest_tip_id_for_contact(HIGH_CONTACT_ID)
	if high_tip_id.is_empty():
		_fail("High-recognition contact tip request did not create a journal row.")
		return
	for _day in range(ADVANCE_DAYS_FOR_TIP):
		GameManager.simulate_opening_session(false)
	var resolved_tip: Dictionary = RunState.get_network_tip_journal().get(high_tip_id, {})
	if not (str(resolved_tip.get("status", "")) in ["resolved", "unresolved"]):
		_fail("High-recognition contact tip did not resolve after %d days: %s." % [ADVANCE_DAYS_FOR_TIP, JSON.stringify(resolved_tip)])
		return

	var final_snapshot: Dictionary = GameManager.get_network_snapshot()
	var report: Dictionary = {
		"seed": RUN_SEED,
		"target_contact_id": HIGH_CONTACT_ID,
		"target_contact_name": str(high_contact.get("display_name", "")),
		"recognition_before": _recognition_report(low_recognition),
		"recognition_after": _recognition_report(high_recognition),
		"public_after_rows": _lead_ids(discovered_rows),
		"public_after_exposed": _contains_contact(discovered_rows, HIGH_CONTACT_ID),
		"referral_bridge_contact_id": BRIDGE_CONTACT_ID,
		"referral_success": bool(referral_result.get("success", false)),
		"referral_contact_id": str(referral_result.get("contact_id", "")),
		"referral_type": str(referral_result.get("referral_type", "")),
		"referral_connection_score": int(referral_result.get("connection_score", 0)),
		"referral_source_type": str(unlocked_row.get("source_type", "")),
		"referral_referred_by_contact_id": str(unlocked_row.get("referred_by_contact_id", "")),
		"referral_referred_by_contact_name": str(unlocked_row.get("referred_by_contact_name", "")),
		"referral_access_label": str(unlocked_row.get("access_label", "")),
		"referral_day_label": str(unlocked_row.get("referral_day_label", "")),
		"referral_privacy_gate": str(unlocked_row.get("privacy_gate", "")),
		"referral_journal_title": str(referral_journal_row.get("title", "")),
		"referral_journal_detail": str(referral_journal_row.get("detail", "")),
		"met_count": int(final_snapshot.get("met_count", 0)),
		"contact_cap": int(final_snapshot.get("contact_cap", 0)),
		"target_ticker": str(target_company.get("ticker", "")),
		"network_relationship": int(RunState.get_network_contacts().get(HIGH_CONTACT_ID, {}).get("relationship", 0)),
		"twooter_account_id": account_id,
		"twooter_relationship": int(inner_state.get("relationship", 0)),
		"twooter_credibility": int(inner_state.get("credibility", 0)),
		"twooter_importance": int(inner_state.get("importance", 0)),
		"twooter_stage": str(inner_state.get("relationship_stage", "")),
		"dialog_tree_id": str(dialog_audit.get("tree_id", "")),
		"dialog_node_id": str(dialog_audit.get("node_id", "")),
		"dialog_options": dialog_audit.get("options", []),
		"dialog_chosen_option_id": str(dialog_audit.get("chosen_option_id", "")),
		"dialog_chosen_action_id": str(dialog_audit.get("chosen_action_id", "")),
		"dialog_player_text": str(dialog_audit.get("player_text", "")),
		"dialog_reply_text": str(dialog_audit.get("reply_text", "")),
		"dialog_outcome": str(dialog_audit.get("dialog_outcome", "")),
		"direct_tip_payload": dialog_audit.get("direct_tip_payload", {}),
		"direct_tip_direction": str(dialog_audit.get("direct_tip_direction", "")),
		"direct_tip_entry_timing": str(dialog_audit.get("direct_tip_entry_timing", "")),
		"direct_tip_hold_period": str(dialog_audit.get("direct_tip_hold_period", "")),
		"direct_tip_confidence_label": str(dialog_audit.get("direct_tip_confidence_label", "")),
		"direct_tip_journal_title": str(direct_tip_journal_row.get("title", "")),
		"direct_tip_journal_detail": str(direct_tip_journal_row.get("detail", "")),
		"dialog_relationship_delta": int(dialog_audit.get("relationship_delta", 0)),
		"dialog_network_changed": bool(dialog_audit.get("network_changed", false)),
		"dialog_message_rows": int(dialog_audit.get("message_rows", 0)),
		"high_tip_status": str(resolved_tip.get("status", "")),
		"high_tip_outcome": str(resolved_tip.get("outcome_label", "")),
		"final_day_index": RunState.day_index,
		"scenario_hash": _stable_hash(JSON.stringify({
			"recognition_after": _recognition_report(high_recognition),
			"referral_contact_id": str(referral_result.get("contact_id", "")),
			"referral_source_type": str(unlocked_row.get("source_type", "")),
			"public_after_exposed": _contains_contact(discovered_rows, HIGH_CONTACT_ID),
			"network_relationship": int(RunState.get_network_contacts().get(HIGH_CONTACT_ID, {}).get("relationship", 0)),
			"twooter_stage": str(inner_state.get("relationship_stage", "")),
			"dialog_tree_id": str(dialog_audit.get("tree_id", "")),
			"dialog_chosen_option_id": str(dialog_audit.get("chosen_option_id", "")),
			"dialog_outcome": str(dialog_audit.get("dialog_outcome", "")),
			"direct_tip_direction": str(dialog_audit.get("direct_tip_direction", "")),
			"direct_tip_entry_timing": str(dialog_audit.get("direct_tip_entry_timing", "")),
			"high_tip_status": str(resolved_tip.get("status", "")),
			"high_tip_outcome": str(resolved_tip.get("outcome_label", ""))
		}))
	}
	print("CONTACT_NETWORK_HIGH_RECOGNITION_OK %s" % JSON.stringify(report))
	get_tree().quit(0)


func _seed_high_recognition_state(target_company: Dictionary) -> void:
	RunState.player_portfolio["cash"] = 5000000.0
	var holdings: Dictionary = {}
	var seeded_holdings: int = 0
	for company_id_value in RunState.company_order:
		if seeded_holdings >= 6:
			break
		var company_id: String = str(company_id_value)
		var company: Dictionary = RunState.get_company(company_id)
		var current_price: float = max(float(company.get("current_price", 0.0)), 1.0)
		var shares: int = max(100, int(floor(200000000.0 / current_price / 100.0)) * 100)
		holdings[company_id] = {
			"company_id": company_id,
			"shares": shares,
			"average_price": current_price
		}
		seeded_holdings += 1
	RunState.player_portfolio["holdings"] = holdings

	var contacts: Dictionary = RunState.get_network_contacts()
	var discoveries: Dictionary = RunState.get_network_discoveries()
	for contact_id_value in LOW_CONTACT_IDS:
		var contact_id: String = str(contact_id_value)
		var contact: Dictionary = _contact_definition(contact_id)
		if contact.is_empty():
			continue
		contacts[contact_id] = {
			"contact_id": contact_id,
			"met": true,
			"relationship": max(int(contact.get("base_relationship", 25)), 45),
			"met_day_index": RunState.day_index,
			"last_source_type": "recognition_seed"
		}
		discoveries[contact_id] = _discovery_row(contact_id, "recognition_seed", "high_recognition_seed", target_company)
	RunState.set_network_contacts(contacts)
	RunState.set_network_discoveries(discoveries)


func _seed_inner_circle_bridge_state(contact_id: String, target_company: Dictionary) -> void:
	var contact: Dictionary = _contact_definition(contact_id)
	if contact.is_empty():
		return
	var contacts: Dictionary = RunState.get_network_contacts()
	var discoveries: Dictionary = RunState.get_network_discoveries()
	contacts[contact_id] = {
		"contact_id": contact_id,
		"met": true,
		"relationship": 62,
		"met_day_index": RunState.day_index,
		"last_source_type": "recognition_seed",
		"last_tip_label": "Useful read",
		"last_tip_day_index": RunState.day_index - 1
	}
	discoveries[contact_id] = _discovery_row(contact_id, "recognition_seed", "inner_circle_bridge_seed", target_company)
	RunState.set_network_contacts(contacts)
	RunState.set_network_discoveries(discoveries)


func _seed_inner_circle_account_state(account_id: String) -> void:
	var social_state: Dictionary = RunState.get_twooter_social_state()
	var account_states: Dictionary = social_state.get("account_states", {}) if typeof(social_state.get("account_states", {})) == TYPE_DICTIONARY else {}
	account_states[account_id] = {
		"relationship": INNER_RELATIONSHIP,
		"exposure": 35,
		"credibility": INNER_CREDIBILITY,
		"importance": INNER_IMPORTANCE,
		"following": false,
		"connected": true,
		"likes_given": 8,
		"last_like_day_index": RunState.day_index - 1,
		"like_relationship_progress": 0.0,
		"unfollowed_ask_count": 0,
		"last_unfollowed_ask_day_index": -1,
		"last_interaction_day_index": RunState.day_index,
		"interaction_count": 9,
		"relationship_stage": "stranger",
		"timeline": []
	}
	social_state["account_states"] = account_states
	RunState.set_twooter_social_state(social_state)


func _run_inner_circle_dialog(account_id: String) -> Dictionary:
	_reset_daily_actions()
	var thread: Dictionary = GameManager.get_twooter_message_thread(account_id)
	var raw_options: Array = thread.get("dialog_options", []) if typeof(thread.get("dialog_options", [])) == TYPE_ARRAY else []
	var options: Array = _dialog_option_audit_rows(raw_options)
	if options.is_empty():
		return {"success": false, "message": "Expected inner-circle message thread to expose dialog options."}
	var chosen: Dictionary = _preferred_enabled_dialog_option(raw_options)
	if chosen.is_empty():
		return {
			"success": false,
			"message": "Expected at least one enabled inner-circle dialog option.",
			"options": options
		}
	var action_id: String = str(chosen.get("action_id", chosen.get("id", "")))
	var option_id: String = str(chosen.get("option_id", chosen.get("id", action_id)))
	var player_text: String = str(chosen.get("player_text", ""))
	var thesis_id: String = str(chosen.get("thesis_id", ""))
	var result: Dictionary = GameManager.send_twooter_message(account_id, action_id, thesis_id, player_text, option_id)
	if not bool(result.get("success", false)):
		return {
			"success": false,
			"message": "Inner-circle dialog option failed: %s" % str(result.get("message", "")),
			"options": options,
			"chosen_option_id": option_id
		}
	var reply_text: String = str(result.get("reply_text", ""))
	var result_player_text: String = str(result.get("player_text", player_text))
	var dialog_outcome: String = str(result.get("dialog_outcome", ""))
	var effect: Dictionary = result.get("outcome_effect", {}) if typeof(result.get("outcome_effect", {})) == TYPE_DICTIONARY else {}
	var direct_tip_payload: Dictionary = effect.get("direct_tip_payload", {}) if typeof(effect.get("direct_tip_payload", {})) == TYPE_DICTIONARY else {}
	var message_rows: Array = _message_rows(account_id)
	if result_player_text.strip_edges().is_empty() or reply_text.strip_edges().is_empty():
		return {
			"success": false,
			"message": "Inner-circle dialog should produce nonempty player and reply text.",
			"options": options,
			"chosen_option_id": option_id,
			"player_text": result_player_text,
			"reply_text": reply_text
		}
	if dialog_outcome.strip_edges().is_empty():
		return {
			"success": false,
			"message": "Inner-circle dialog should record a dialog outcome.",
			"options": options,
			"chosen_option_id": option_id,
			"player_text": result_player_text,
			"reply_text": reply_text
		}
	if option_id == "direct_tip":
		if dialog_outcome != "direct_tip" or direct_tip_payload.is_empty() or not bool(direct_tip_payload.get("success", false)):
			return {
				"success": false,
				"message": "Inner-circle direct_tip should produce a successful direct-tip payload, outcome=%s payload=%s." % [dialog_outcome, JSON.stringify(direct_tip_payload)],
				"options": options,
				"chosen_option_id": option_id,
				"player_text": result_player_text,
				"reply_text": reply_text
			}
		if str(direct_tip_payload.get("ticker", "")) != str(direct_tip_payload.get("ticker", "")).to_upper() or str(direct_tip_payload.get("direction", "")).is_empty():
			return {
				"success": false,
				"message": "Inner-circle direct-tip payload should include ticker and direction, payload=%s." % JSON.stringify(direct_tip_payload),
				"options": options,
				"chosen_option_id": option_id
			}
	if message_rows.size() < 2:
		return {
			"success": false,
			"message": "Inner-circle dialog should record player/account message rows.",
			"options": options,
			"chosen_option_id": option_id,
			"player_text": result_player_text,
			"reply_text": reply_text
		}
	return {
		"success": true,
		"tree_id": str(chosen.get("tree_id", "")),
		"node_id": str(chosen.get("node_id", "")),
		"options": options,
		"chosen_option_id": option_id,
		"chosen_action_id": action_id,
		"player_text": result_player_text,
		"reply_text": reply_text,
		"dialog_outcome": dialog_outcome,
		"direct_tip_payload": direct_tip_payload.duplicate(true),
		"direct_tip_direction": str(direct_tip_payload.get("direction", "")),
		"direct_tip_entry_timing": str(direct_tip_payload.get("entry_timing", "")),
		"direct_tip_hold_period": str(direct_tip_payload.get("hold_period", "")),
		"direct_tip_confidence_label": str(direct_tip_payload.get("confidence_label", "")),
		"relationship_delta": int(result.get("relationship_delta", 0)),
		"network_changed": bool(result.get("network_changed", false)),
		"message_rows": message_rows.size()
	}


func _dialog_option_audit_rows(source_options: Array) -> Array:
	var rows: Array = []
	for option_value: Variant in source_options:
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		rows.append({
			"option_id": str(option.get("option_id", option.get("id", ""))),
			"action_id": str(option.get("action_id", option.get("id", ""))),
			"label": str(option.get("label", "")),
			"tree_id": str(option.get("tree_id", "")),
			"node_id": str(option.get("node_id", "")),
			"enabled": bool(option.get("enabled", true)),
			"blocked_reason": str(option.get("blocked_reason", "")),
			"player_text": str(option.get("player_text", ""))
		})
	return rows


func _preferred_enabled_dialog_option(options: Array) -> Dictionary:
	var preferred_option_ids: Array[String] = [
		"direct_tip",
		"accept_clean",
		"public_trail",
		"clean_read_only",
		"bring_evidence_next",
		"ask_specific_source",
		"ask_read",
		"source_thesis",
		"ask_purpose",
		"show_process_next",
		"news_context_intro"
	]
	for preferred_option_id: String in preferred_option_ids:
		for option_value: Variant in options:
			if typeof(option_value) != TYPE_DICTIONARY:
				continue
			var option: Dictionary = option_value
			if str(option.get("option_id", option.get("id", ""))) == preferred_option_id and bool(option.get("enabled", true)):
				return option
	for option_value: Variant in options:
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		if bool(option.get("enabled", true)):
			return option
	return {}


func _message_rows(account_id: String) -> Array:
	var social_state: Dictionary = RunState.get_twooter_social_state()
	var messages: Dictionary = social_state.get("messages", {}) if typeof(social_state.get("messages", {})) == TYPE_DICTIONARY else {}
	var thread: Dictionary = messages.get(account_id, {}) if typeof(messages.get(account_id, {})) == TYPE_DICTIONARY else {}
	return thread.get("rows", []).duplicate(true) if typeof(thread.get("rows", [])) == TYPE_ARRAY else []


func _article_for_high_contact(target_company: Dictionary, high_contact: Dictionary, suffix: String) -> Dictionary:
	var contact_sector_ids: Array = high_contact.get("sector_ids", []) if typeof(high_contact.get("sector_ids", [])) == TYPE_ARRAY else []
	var target_sector_id: String = str(target_company.get("sector_id", ""))
	var company_id: String = str(target_company.get("id", ""))
	if not (target_sector_id in contact_sector_ids):
		target_sector_id = ""
		company_id = ""
	return {
		"id": "high_recognition_%s_%d" % [suffix, RunState.day_index],
		"category": "mna",
		"target_company_id": company_id,
		"target_sector_id": target_sector_id,
		"author_contact_id": HIGH_CONTACT_ID,
		"title": "High-recognition owner-family legal signal",
		"summary": "%s is attached to a controlling-shareholder legal read." % str(high_contact.get("display_name", "A source"))
	}


func _company_context_for_contact(contact: Dictionary) -> Dictionary:
	var sector_ids: Array = contact.get("sector_ids", []) if typeof(contact.get("sector_ids", [])) == TYPE_ARRAY else []
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		if str(definition.get("sector_id", "")) in sector_ids:
			return _company_context(company_id)
	if not RunState.company_order.is_empty():
		return _company_context(str(RunState.company_order[0]))
	return {}


func _company_context(company_id: String) -> Dictionary:
	var company: Dictionary = RunState.get_company(company_id)
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	return {
		"id": company_id,
		"ticker": str(definition.get("ticker", company_id.to_upper())),
		"sector_id": str(definition.get("sector_id", "")),
		"current_price": float(company.get("current_price", 0.0))
	}


func _network_row(contact_id: String, bucket_name: String) -> Dictionary:
	var snapshot: Dictionary = GameManager.get_network_snapshot()
	for row_value in snapshot.get(bucket_name, []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("id", row.get("contact_id", ""))) == contact_id:
			return row
	return {}


func _assert_referral_provenance(row: Dictionary, label: String) -> void:
	var bridge_name: String = str(_contact_definition(BRIDGE_CONTACT_ID).get("display_name", ""))
	if str(row.get("access_label", "")) != "Inner-circle contact":
		_fail("%s row should show inner-circle access label, row=%s." % [label, JSON.stringify(row)])
		return
	if str(row.get("referred_by_contact_name", "")) != bridge_name:
		_fail("%s row should show referral source name %s, row=%s." % [label, bridge_name, JSON.stringify(row)])
		return
	if int(row.get("referral_day_index", -9999)) < 0 or str(row.get("referral_day_label", "")).strip_edges().is_empty():
		_fail("%s row should show referral day label, row=%s." % [label, JSON.stringify(row)])
		return
	if not str(row.get("referral_note", "")).contains(bridge_name):
		_fail("%s row should include referral note provenance, row=%s." % [label, JSON.stringify(row)])
		return


func _snapshot_referral_journal_row(contact_id: String) -> Dictionary:
	for row_value in GameManager.get_network_snapshot().get("journal", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("type", "")) == "referral" and str(row.get("contact_id", "")) == contact_id:
			return row
	return {}


func _snapshot_direct_tip_journal_row(contact_id: String) -> Dictionary:
	for row_value in GameManager.get_network_snapshot().get("journal", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("type", "")) == "twooter" and str(row.get("contact_id", "")) == contact_id and not str(row.get("direct_tip_direction", "")).is_empty():
			return row
	return {}


func _assert_referral_journal_row(row: Dictionary) -> void:
	var bridge_name: String = str(_contact_definition(BRIDGE_CONTACT_ID).get("display_name", ""))
	if str(row.get("access_label", "")) != "Inner-circle contact":
		_fail("Referral journal row should carry inner-circle access label, row=%s." % JSON.stringify(row))
		return
	if str(row.get("referred_by_contact_name", "")) != bridge_name:
		_fail("Referral journal row should carry source contact display name, row=%s." % JSON.stringify(row))
		return
	if not str(row.get("title", "")).contains("Inner-circle contact") or not str(row.get("detail", "")).contains("Access: Inner-circle contact"):
		_fail("Referral journal row should explain inner-circle provenance, row=%s." % JSON.stringify(row))
		return


func _assert_direct_tip_journal_row(row: Dictionary) -> void:
	if not str(row.get("title", "")).contains("Inner-circle Direct Read"):
		_fail("Direct-tip journal title should distinguish inner-circle read, row=%s." % JSON.stringify(row))
		return
	if str(row.get("direct_tip_direction", "")).is_empty() or str(row.get("direct_tip_entry_timing", "")).is_empty() or str(row.get("direct_tip_hold_period", "")).is_empty():
		_fail("Direct-tip journal row should expose direction, timing, and hold fields, row=%s." % JSON.stringify(row))
		return
	if str(row.get("direct_tip_confidence_label", "")).is_empty() or str(row.get("direct_tip_risk_note", "")).is_empty():
		_fail("Direct-tip journal row should expose confidence and risk fields, row=%s." % JSON.stringify(row))
		return
	if not str(row.get("detail", "")).contains("Inner-circle direct read") or not str(row.get("detail", "")).contains("Risk:"):
		_fail("Direct-tip journal detail should include direct-read and risk wording, row=%s." % JSON.stringify(row))
		return


func _network_account_for_contact(contact_id: String) -> Dictionary:
	for account_value in GameManager.get_twooter_snapshot(99).get("accounts", []):
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value
		var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
		if str(profile.get("network_contact_id", "")) == contact_id:
			return account
	return {}


func _latest_tip_id_for_contact(contact_id: String) -> String:
	var best_id: String = ""
	var best_day: int = -9999
	for tip_id_value in RunState.get_network_tip_journal().keys():
		var tip_id: String = str(tip_id_value)
		var tip: Dictionary = RunState.get_network_tip_journal().get(tip_id, {})
		if str(tip.get("contact_id", "")) != contact_id:
			continue
		if int(tip.get("created_day_index", 0)) >= best_day:
			best_day = int(tip.get("created_day_index", 0))
			best_id = tip_id
	return best_id


func _set_contact_relationship(contact_id: String, relationship: int) -> void:
	var contacts: Dictionary = RunState.get_network_contacts()
	var runtime: Dictionary = contacts.get(contact_id, {}) if typeof(contacts.get(contact_id, {})) == TYPE_DICTIONARY else {}
	runtime["contact_id"] = contact_id
	runtime["relationship"] = relationship
	contacts[contact_id] = runtime
	RunState.set_network_contacts(contacts)


func _discovery_row(contact_id: String, source_type: String, source_id: String, target_company: Dictionary) -> Dictionary:
	return {
		"contact_id": contact_id,
		"discovered": true,
		"source_type": source_type,
		"source_id": source_id,
		"target_company_id": str(target_company.get("id", "")),
		"target_company_ids": [str(target_company.get("id", ""))],
		"target_ticker": str(target_company.get("ticker", "")),
		"target_sector_id": str(target_company.get("sector_id", "")),
		"lead_score": 96,
		"day_index": RunState.day_index
	}


func _contains_contact(rows: Array, contact_id: String) -> bool:
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("id", row.get("contact_id", ""))) == contact_id:
			return true
	return false


func _lead_ids(rows: Array) -> Array:
	var ids: Array = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		ids.append(str(row.get("id", row.get("contact_id", ""))))
	ids.sort()
	return ids


func _contact_definition(contact_id: String) -> Dictionary:
	for contact_value in DataRepository.get_contact_network_data().get("contacts", []):
		if typeof(contact_value) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = contact_value
		if str(contact.get("id", "")) == contact_id:
			return contact.duplicate(true)
	return {}


func _recognition_report(recognition: Dictionary) -> Dictionary:
	return {
		"score": _round_to(float(recognition.get("score", 0.0)), 2),
		"label": str(recognition.get("label", "")),
		"tier_index": int(recognition.get("tier_index", 0)),
		"contact_cap": int(recognition.get("contact_cap", 0)),
		"equity_score": _round_to(float(recognition.get("equity_score", 0.0)), 2),
		"ownership_score": _round_to(float(recognition.get("ownership_score", 0.0)), 2),
		"contact_score": _round_to(float(recognition.get("contact_score", 0.0)), 2)
	}


func _reset_daily_actions() -> void:
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0


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
	push_error(message)
	get_tree().quit(1)
