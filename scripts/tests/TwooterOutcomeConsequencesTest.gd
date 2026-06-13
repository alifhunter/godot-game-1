extends Node

const RUN_SEED := 617030
const DAY_INDEX := 12
const TWOOTER_INTERACTION_SYSTEM_SCRIPT := preload("res://systems/TwooterInteractionSystem.gd")

var _interaction_system = TWOOTER_INTERACTION_SYSTEM_SCRIPT.new()
var _failed := false
var _audit := {
	"thesis_response": {},
	"contact_discovery": {},
	"event_invite": {},
	"same_day_repeat": {}
}


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var feed_data: Dictionary = DataRepository.get_twooter_feed_data()

	_assert_thesis_response_effect(feed_data)
	if _failed:
		return
	_assert_contact_discovery_effect(feed_data)
	if _failed:
		return
	_assert_event_invite_effect(feed_data)
	if _failed:
		return

	print("TWOOTER_OUTCOME_CONSEQUENCES_OK %s" % JSON.stringify(_audit))
	get_tree().quit(0)


func _assert_thesis_response_effect(feed_data: Dictionary) -> void:
	_setup_run(DAY_INDEX)
	var account: Dictionary = _account("thesis", {"dialog_trees": ["thesis_review"]}, 0)
	var thesis: Dictionary = _thesis("outcome_thesis", "B")
	_reset_social_state(account, _account_state(8, 0, 0), DAY_INDEX)
	var options: Array = _thread_options(feed_data, account, [thesis], DAY_INDEX)
	var option: Dictionary = _enabled_option_by_id(options, "share_structure")
	if option.is_empty():
		_fail("Expected thesis_response test to expose share_structure.")
		return

	var result: Dictionary = _apply_option(feed_data, _snapshot(account, [thesis]), account, option, str(thesis.get("id", "")))
	if not bool(result.get("success", false)):
		_fail("Expected thesis_response option to apply: %s" % str(result.get("message", "")))
		return
	var effect: Dictionary = result.get("outcome_effect", {}) if typeof(result.get("outcome_effect", {})) == TYPE_DICTIONARY else {}
	if str(result.get("dialog_outcome", "")) != "thesis_response" or int(effect.get("credibility_delta", 0)) != 1:
		_fail("Expected thesis_response to add exactly one outcome credibility point, got %s." % str(result))
		return
	if int(result.get("credibility_delta", 0)) != 7:
		_fail("Expected B-grade thesis share to total 7 credibility after base, thesis, and outcome effects, got %d." % int(result.get("credibility_delta", 0)))
		return
	if not _timeline_has_note(str(account.get("id", "")), "Thesis response: credibility improved."):
		_fail("Expected thesis_response timeline note to expose the credibility effect.")
		return
	var thesis_journal: Dictionary = _latest_journal_for_outcome(str(account.get("id", "")), "thesis_response")
	if thesis_journal.is_empty() or int(thesis_journal.get("dialog_outcome_credibility_delta", 0)) != 1 or not bool(thesis_journal.get("dialog_outcome_thesis_response_recorded", false)):
		_fail("Expected thesis_response Network journal metadata, got %s." % str(thesis_journal))
		return

	_force_account_branch(str(account.get("id", "")), "thesis_review", "review")
	var repeat_option: Dictionary = _enabled_option_by_id(_thread_options(feed_data, account, [thesis], DAY_INDEX), "share_structure")
	var repeat_result: Dictionary = _apply_option(feed_data, _snapshot(account, [thesis]), account, repeat_option, str(thesis.get("id", "")))
	var repeat_effect: Dictionary = repeat_result.get("outcome_effect", {}) if typeof(repeat_result.get("outcome_effect", {})) == TYPE_DICTIONARY else {}
	if not bool(repeat_result.get("success", false)) or int(repeat_result.get("credibility_delta", -1)) != 0 or not repeat_effect.is_empty():
		_fail("Expected same-day repeated thesis_response to no-op mechanical gains, got %s." % str(repeat_result))
		return

	_audit["thesis_response"] = {
		"outcome_credibility_delta": int(effect.get("credibility_delta", 0)),
		"total_credibility_delta": int(result.get("credibility_delta", 0)),
		"journal_note": str(thesis_journal.get("dialog_outcome_note", ""))
	}
	_audit["same_day_repeat"] = {
		"credibility_delta": int(repeat_result.get("credibility_delta", 0)),
		"outcome_effect_empty": repeat_effect.is_empty()
	}


func _assert_contact_discovery_effect(feed_data: Dictionary) -> void:
	_setup_run(DAY_INDEX + 1)
	var account: Dictionary = _network_account("contact", ["network_source_followup", "network_relationship_probe"], {})
	var account_id: String = str(account.get("id", ""))
	_reset_social_state(account, _account_state(4, 6, 4), DAY_INDEX + 1)
	var option: Dictionary = _enabled_option_by_id(_thread_options(feed_data, account, [], DAY_INDEX + 1), "ask_to_connect")
	if option.is_empty():
		_fail("Expected contact_discovery test to expose ask_to_connect.")
		return

	var result: Dictionary = _apply_option(feed_data, _snapshot(account), account, option, "")
	if not bool(result.get("success", false)):
		_fail("Expected contact_discovery option to apply: %s" % str(result.get("message", "")))
		return
	var effect: Dictionary = result.get("outcome_effect", {}) if typeof(result.get("outcome_effect", {})) == TYPE_DICTIONARY else {}
	if str(result.get("dialog_outcome", "")) != "contact_discovery" or int(effect.get("network_source_quality_delta", 0)) != 1:
		_fail("Expected Network-source contact_discovery to add one lead-quality point, got %s." % str(result))
		return
	var contact_id: String = _contact_id(account)
	var discovery: Dictionary = RunState.get_network_discoveries().get(contact_id, {}) if typeof(RunState.get_network_discoveries().get(contact_id, {})) == TYPE_DICTIONARY else {}
	if int(discovery.get("lead_score", 0)) < 73:
		_fail("Expected contact_discovery lead score to include quality delta, got %s." % str(discovery))
		return
	var journal: Dictionary = _latest_journal_for_outcome(account_id, "contact_discovery")
	if journal.is_empty() or int(journal.get("dialog_outcome_quality_delta", 0)) != 1 or str(journal.get("dialog_outcome_note", "")).find("lead quality improved") == -1:
		_fail("Expected contact_discovery journal quality note, got %s." % str(journal))
		return
	_audit["contact_discovery"] = {
		"quality_delta": int(effect.get("network_source_quality_delta", 0)),
		"lead_score": int(discovery.get("lead_score", 0)),
		"journal_note": str(journal.get("dialog_outcome_note", ""))
	}


func _assert_event_invite_effect(feed_data: Dictionary) -> void:
	_setup_run(DAY_INDEX + 2)
	var account: Dictionary = _account("event", {"dialog_trees": ["event_invite"]}, 0)
	var account_id: String = str(account.get("id", ""))
	_reset_social_state(account, _account_state(45, 18, 18), DAY_INDEX + 2)
	var option: Dictionary = _enabled_option_by_id(_thread_options(feed_data, account, [], DAY_INDEX + 2), "accept_clean")
	if option.is_empty():
		_fail("Expected event_invite test to expose accept_clean.")
		return

	var result: Dictionary = _apply_option(feed_data, _snapshot(account), account, option, "")
	if not bool(result.get("success", false)):
		_fail("Expected event_invite option to apply: %s" % str(result.get("message", "")))
		return
	var effect: Dictionary = result.get("outcome_effect", {}) if typeof(result.get("outcome_effect", {})) == TYPE_DICTIONARY else {}
	if str(result.get("dialog_outcome", "")) != "event_invite" or int(effect.get("relationship_delta", 0)) != 1 or not bool(effect.get("event_invite_unlocked", false)):
		_fail("Expected event_invite to add one relationship point and unlock the opportunity flag, got %s." % str(result))
		return
	if int(result.get("relationship_delta", 0)) != 4:
		_fail("Expected event_invite total relationship delta to include base and outcome effects, got %d." % int(result.get("relationship_delta", 0)))
		return
	if not _timeline_has_note(account_id, "Event invite: room opportunity logged."):
		_fail("Expected event_invite timeline note to expose the room opportunity.")
		return
	var journal: Dictionary = _latest_journal_for_outcome(account_id, "event_invite")
	if journal.is_empty() or not bool(journal.get("dialog_outcome_event_invite_unlocked", false)) or int(journal.get("dialog_outcome_relationship_delta", 0)) != 1:
		_fail("Expected event_invite journal opportunity metadata, got %s." % str(journal))
		return
	_audit["event_invite"] = {
		"outcome_relationship_delta": int(effect.get("relationship_delta", 0)),
		"total_relationship_delta": int(result.get("relationship_delta", 0)),
		"journal_note": str(journal.get("dialog_outcome_note", ""))
	}


func _setup_run(day_index: int) -> void:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED + day_index, difficulty_config)
	RunState.setup_new_run(RUN_SEED + day_index, company_definitions, difficulty_config, false)
	RunState.day_index = day_index
	RunState.daily_action_day_index = day_index
	RunState.daily_actions_used = 0


func _reset_social_state(account: Dictionary, account_state: Dictionary, day_index: int) -> void:
	RunState.set_twooter_social_state(_social_state_for_account(account, account_state, day_index))


func _thread_options(feed_data: Dictionary, account: Dictionary, theses: Array, day_index: int) -> Array:
	var thread: Dictionary = _interaction_system.get_message_thread(
		RunState.get_twooter_social_state(),
		[account],
		str(account.get("id", "")),
		day_index,
		theses,
		feed_data,
		_daily_action(day_index)
	)
	return thread.get("dialog_options", []) if typeof(thread.get("dialog_options", [])) == TYPE_ARRAY else []


func _enabled_option_by_id(options: Array, option_id: String) -> Dictionary:
	for option_value: Variant in options:
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		if str(option.get("option_id", "")) == option_id and bool(option.get("enabled", false)):
			return option
	return {}


func _apply_option(feed_data: Dictionary, snapshot: Dictionary, account: Dictionary, option: Dictionary, thesis_id: String) -> Dictionary:
	return _interaction_system.apply_message_action(
		RunState,
		feed_data,
		snapshot,
		str(account.get("id", "")),
		str(option.get("action_id", "")),
		thesis_id,
		str(option.get("player_text", "")),
		str(option.get("option_id", ""))
	)


func _force_account_branch(account_id: String, tree_id: String, node_id: String) -> void:
	var state: Dictionary = RunState.get_twooter_social_state()
	var dialog_state: Dictionary = state.get("dialog_state", {}) if typeof(state.get("dialog_state", {})) == TYPE_DICTIONARY else {}
	var accounts: Dictionary = dialog_state.get("accounts", {}) if typeof(dialog_state.get("accounts", {})) == TYPE_DICTIONARY else {}
	accounts[account_id] = {
		"tree_id": tree_id,
		"node_id": node_id,
		"last_option_id": "",
		"last_outcome": "",
		"last_action_id": "",
		"repeat_count": 0,
		"last_day_index": DAY_INDEX,
		"cooldown_until_day": -1,
		"cooldown_reason": "",
		"step_count": 0
	}
	dialog_state["accounts"] = accounts
	state["dialog_state"] = dialog_state
	RunState.set_twooter_social_state(state)


func _timeline_has_note(account_id: String, note: String) -> bool:
	var social_state: Dictionary = RunState.get_twooter_social_state()
	var account_states: Dictionary = social_state.get("account_states", {}) if typeof(social_state.get("account_states", {})) == TYPE_DICTIONARY else {}
	var account_state: Dictionary = account_states.get(account_id, {}) if typeof(account_states.get(account_id, {})) == TYPE_DICTIONARY else {}
	var rows: Array = account_state.get("timeline", []) if typeof(account_state.get("timeline", [])) == TYPE_ARRAY else []
	for row_value: Variant in rows:
		if typeof(row_value) == TYPE_DICTIONARY and str(row_value.get("text", "")).find(note) >= 0:
			return true
	return false


func _latest_journal_for_outcome(account_id: String, outcome: String) -> Dictionary:
	var best: Dictionary = {}
	var best_day: int = -9999
	for tip_value: Variant in RunState.get_network_tip_journal().values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		if str(tip.get("twooter_account_id", "")) != account_id or str(tip.get("dialog_outcome", "")) != outcome:
			continue
		var created_day_index: int = int(tip.get("created_day_index", -1))
		if best.is_empty() or created_day_index >= best_day:
			best = tip
			best_day = created_day_index
	return best


func _snapshot(account: Dictionary, theses: Array = []) -> Dictionary:
	return {
		"accounts": [account],
		"posts": [],
		"message_threads": [],
		"shareable_theses": theses,
		"trending_rows": [],
		"who_to_follow": []
	}


func _social_state_for_account(account: Dictionary, account_state: Dictionary, day_index: int) -> Dictionary:
	var account_id: String = str(account.get("id", ""))
	return {
		"account_states": {
			account_id: account_state
		},
		"post_interactions": {},
		"liked_posts": {},
		"messages": {},
		"network_contact_definitions": {},
		"dialog_state": {
			"accounts": {},
			"posts": {}
		},
		"daily_public_interactions": {
			"day_index": day_index,
			"account_action_counts": {}
		}
	}


func _account(id_suffix: String, profile_overrides: Dictionary, public_post_count: int) -> Dictionary:
	var account_id: String = "outcome_%s" % id_suffix
	var profile: Dictionary = {
		"role": "Outcome test account",
		"intro": "Synthetic account for outcome consequence tests.",
		"description": "Synthetic account for outcome consequence tests.",
		"risk_profile": "clean",
		"target_company_id": "test_company",
		"target_ticker": "TEST",
		"target_company_name": "Test Company"
	}
	for key_value: Variant in profile_overrides.keys():
		profile[key_value] = profile_overrides.get(key_value)
	return {
		"id": account_id,
		"display_name": "Outcome %s" % id_suffix.capitalize(),
		"handle": "@%s" % account_id,
		"tier": 1,
		"verified": false,
		"voice": "evidence",
		"public_post_count": public_post_count,
		"social_profile": profile
	}


func _network_account(id_suffix: String, dialog_trees: Array, profile_overrides: Dictionary) -> Dictionary:
	var overrides: Dictionary = {
		"account_origin": "network_contact",
		"network_source": true,
		"network_contact_id": "contact_%s" % id_suffix,
		"dialog_trees": dialog_trees,
		"risk_profile": "clean"
	}
	for key_value: Variant in profile_overrides.keys():
		overrides[key_value] = profile_overrides.get(key_value)
	return _account(id_suffix, overrides, 0)


func _contact_id(account: Dictionary) -> String:
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var contact_id: String = str(profile.get("network_contact_id", ""))
	if contact_id.is_empty():
		return "social_%s" % str(account.get("id", ""))
	return contact_id


func _account_state(relationship: int, credibility: int, importance: int) -> Dictionary:
	return {
		"relationship": relationship,
		"exposure": 0,
		"credibility": credibility,
		"importance": importance,
		"relationship_stage": _expected_stage(relationship, credibility, importance),
		"following": true,
		"connected": false,
		"likes_given": 0,
		"interaction_count": 0,
		"like_relationship_progress": 0.0
	}


func _expected_stage(relationship: int, credibility: int, importance: int) -> String:
	if relationship >= 70 and credibility >= 45 and importance >= 55:
		return "inner_circle_candidate"
	if relationship >= 45:
		return "trusted"
	if relationship >= 18:
		return "familiar"
	return "stranger"


func _thesis(thesis_id: String, grade: String) -> Dictionary:
	return {
		"id": thesis_id,
		"title": "Outcome Test Thesis",
		"ticker": "TEST",
		"company_id": "test_company",
		"company_name": "Test Company",
		"status": "open",
		"report": {
			"grade": grade
		}
	}


func _daily_action(day_index: int) -> Dictionary:
	return {
		"day_index": day_index,
		"used": 0,
		"remaining": 99,
		"limit": 99
	}


func _fail(message: String) -> void:
	_failed = true
	push_error(message)
	get_tree().quit(1)
