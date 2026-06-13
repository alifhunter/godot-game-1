extends Node

const RUN_SEED := 617027
const START_DAY_INDEX := 12
const TWOOTER_INTERACTION_SYSTEM_SCRIPT := preload("res://systems/TwooterInteractionSystem.gd")
const CONTACT_NETWORK_SYSTEM_SCRIPT := preload("res://systems/ContactNetworkSystem.gd")

var _interaction_system = TWOOTER_INTERACTION_SYSTEM_SCRIPT.new()
var _network_system = CONTACT_NETWORK_SYSTEM_SCRIPT.new()
var _failed := false
var _audit := {
	"profiles": {},
	"progressions": [],
	"boundaries": []
}


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	var feed_data: Dictionary = DataRepository.get_twooter_feed_data()

	_audit_profile_inventory()
	if _failed:
		return

	var reporter_trees: Array = _audit["profiles"].get("reporter", [])
	var analyst_trees: Array = _audit["profiles"].get("analyst", [])
	var floater_trees: Array = _audit["profiles"].get("floater", [])
	_run_progression(feed_data, "reporter", reporter_trees)
	_run_progression(feed_data, "analyst", analyst_trees)
	_run_progression(feed_data, "floater", floater_trees)
	_assert_boundary(feed_data, "insider", _audit["profiles"].get("insider", []), "network_insider_boundary")
	_assert_boundary(feed_data, "suspicious", _audit["profiles"].get("suspicious", []), "network_guarded_source")
	if _failed:
		return

	if _audit["progressions"].size() != 3:
		_fail("Expected reporter, analyst, and floater Network source progressions.")
		return
	if _audit["boundaries"].size() != 2:
		_fail("Expected insider and suspicious Network source boundary assertions.")
		return

	print("TWOOTER_NETWORK_PROGRESSION_OK %s" % JSON.stringify(_audit))
	get_tree().quit(0)


func _audit_profile_inventory() -> void:
	var contacts: Dictionary = {
		"reporter": _contact("market reporter", "floater", 0.72, "mixed"),
		"analyst": _contact("sector analyst", "floater", 0.72, "mixed"),
		"floater": _contact("market contact", "floater", 0.72, "mixed"),
		"insider": _contact("company insider", "insider", 0.72, "mixed"),
		"suspicious": _contact("market operator", "floater", 0.72, "suspicious")
	}
	for archetype_value: String in contacts.keys():
		var trees: Array = _network_system._contact_twooter_dialog_trees(contacts.get(archetype_value, {}))
		_audit["profiles"][archetype_value] = trees
		if trees.is_empty():
			_fail("Expected %s Network profile to produce a dialog tree list." % archetype_value)
			return
	if _audit["profiles"].get("reporter", []) != ["network_source_followup", "network_relationship_probe", "source_check"]:
		_fail("Reporter Network profile list drifted: %s" % [str(_audit["profiles"].get("reporter", []))])
	if _audit["profiles"].get("analyst", []) != ["network_source_followup", "network_relationship_probe", "thesis_review"]:
		_fail("Analyst Network profile list drifted: %s" % [str(_audit["profiles"].get("analyst", []))])
	if _audit["profiles"].get("floater", []) != ["network_source_followup", "network_relationship_probe", "source_check"]:
		_fail("Floater Network profile list drifted: %s" % [str(_audit["profiles"].get("floater", []))])
	if _audit["profiles"].get("insider", []) != ["network_insider_boundary", "network_source_followup", "source_check"]:
		_fail("Insider Network profile list drifted: %s" % [str(_audit["profiles"].get("insider", []))])
	if _audit["profiles"].get("suspicious", []) != ["network_guarded_source", "suspicious_boundary", "source_check"]:
		_fail("Suspicious Network profile list drifted: %s" % [str(_audit["profiles"].get("suspicious", []))])


func _run_progression(feed_data: Dictionary, archetype: String, dialog_trees: Array) -> void:
	var account: Dictionary = _network_account(archetype, dialog_trees, {})
	var account_id: String = str(account.get("id", ""))
	var snapshot: Dictionary = _snapshot(account)
	_reset_social_state(account, _account_state(6, 5, 4), START_DAY_INDEX)
	_assert_thread_tree(feed_data, account, START_DAY_INDEX, "network_source_followup", "open")

	var steps: Array = [
		{"day": START_DAY_INDEX, "option_id": "news_context_intro", "expect_next_node": "verify"},
		{"day": START_DAY_INDEX + 1, "option_id": "clean_read_only", "expect_next_node": "guarded_trust"},
		{"day": START_DAY_INDEX + 2, "option_id": "close_thread_clean", "expect_next_node": "open"}
	]
	for step_value: Dictionary in steps:
		var day_index: int = int(step_value.get("day", START_DAY_INDEX))
		_set_day(day_index)
		var option: Dictionary = _option_by_id(_thread_options(feed_data, account, day_index), str(step_value.get("option_id", "")))
		if option.is_empty():
			_fail("Expected %s progression option '%s' on day %d." % [archetype, str(step_value.get("option_id", "")), day_index])
			return
		var result: Dictionary = _apply_option(feed_data, snapshot, account_id, option)
		if not bool(result.get("success", false)):
			_fail("Expected %s option '%s' to apply: %s" % [archetype, str(step_value.get("option_id", "")), str(result.get("message", ""))])
			return
		var branch: Dictionary = _account_branch(account_id)
		if str(branch.get("tree_id", "")) != "network_source_followup" or str(branch.get("node_id", "")) != str(step_value.get("expect_next_node", "")):
			_fail("Expected %s branch to remain in network_source_followup and move to '%s', got %s." % [archetype, str(step_value.get("expect_next_node", "")), str(branch)])
			return

	_set_day(START_DAY_INDEX + 3)
	_assert_thread_tree(feed_data, account, START_DAY_INDEX + 3, "network_source_followup", "relationship_handoff")
	var handoff_option: Dictionary = _option_by_id(_thread_options(feed_data, account, START_DAY_INDEX + 3), "show_process_next")
	if handoff_option.is_empty():
		_fail("Expected %s handoff option before graduation." % archetype)
		return
	var handoff_result: Dictionary = _apply_option(feed_data, snapshot, account_id, handoff_option)
	if not bool(handoff_result.get("success", false)) or not bool(handoff_result.get("dialog_graduated", false)):
		_fail("Expected %s handoff to graduate: %s" % [archetype, str(handoff_result)])
		return
	var branch_after: Dictionary = _account_branch(account_id)
	if str(branch_after.get("tree_id", "")) != "network_relationship_probe" or str(branch_after.get("node_id", "")) != "probe":
		_fail("Expected %s branch to persist network_relationship_probe after graduation, got %s." % [archetype, str(branch_after)])
		return
	_assert_thread_tree(feed_data, account, START_DAY_INDEX + 3, "network_relationship_probe", "probe")
	_audit["progressions"].append({
		"archetype": archetype,
		"from_tree": "network_source_followup",
		"handoff_node": "relationship_handoff",
		"next_tree": str(handoff_result.get("dialog_next_tree", "")),
		"final_tree": str(branch_after.get("tree_id", ""))
	})


func _assert_boundary(feed_data: Dictionary, archetype: String, dialog_trees: Array, expected_tree_id: String) -> void:
	var overrides: Dictionary = {}
	if archetype == "insider":
		overrides["affiliation_type"] = "insider"
		overrides["affiliation_role"] = "insider"
	elif archetype == "suspicious":
		overrides["risk_profile"] = "suspicious"
	var account: Dictionary = _network_account(archetype, dialog_trees, overrides)
	var account_id: String = str(account.get("id", ""))
	_reset_social_state(account, _account_state(24, 16, 12), START_DAY_INDEX)
	_assert_thread_tree(feed_data, account, START_DAY_INDEX, expected_tree_id, "")
	var state: Dictionary = RunState.get_twooter_social_state()
	var dialog_state: Dictionary = state.get("dialog_state", {})
	var accounts: Dictionary = dialog_state.get("accounts", {})
	accounts[account_id] = {
		"tree_id": expected_tree_id,
		"node_id": "",
		"last_option_id": "synthetic_boundary",
		"last_outcome": "",
		"last_action_id": "message_check_in",
		"repeat_count": 0,
		"last_day_index": START_DAY_INDEX - 1,
		"cooldown_until_day": -1,
		"cooldown_reason": "",
		"step_count": 6
	}
	dialog_state["accounts"] = accounts
	state["dialog_state"] = dialog_state
	RunState.set_twooter_social_state(state)
	_assert_thread_tree(feed_data, account, START_DAY_INDEX + 1, expected_tree_id, "")
	_audit["boundaries"].append({
		"archetype": archetype,
		"expected_tree": expected_tree_id,
		"profile_trees": dialog_trees
	})


func _assert_thread_tree(feed_data: Dictionary, account: Dictionary, day_index: int, expected_tree_id: String, expected_node_id: String) -> void:
	var options: Array = _thread_options(feed_data, account, day_index)
	if options.is_empty():
		_fail("Expected thread options for '%s'." % expected_tree_id)
		return
	var option: Dictionary = options[0] if typeof(options[0]) == TYPE_DICTIONARY else {}
	if str(option.get("tree_id", "")) != expected_tree_id:
		_fail("Expected tree '%s', got '%s'." % [expected_tree_id, str(option.get("tree_id", ""))])
		return
	if not expected_node_id.is_empty() and str(option.get("node_id", "")) != expected_node_id:
		_fail("Expected node '%s' for tree '%s', got '%s'." % [expected_node_id, expected_tree_id, str(option.get("node_id", ""))])


func _thread_options(feed_data: Dictionary, account: Dictionary, day_index: int) -> Array:
	var thread: Dictionary = _interaction_system.get_message_thread(
		RunState.get_twooter_social_state(),
		[account],
		str(account.get("id", "")),
		day_index,
		[],
		feed_data,
		_daily_action(day_index)
	)
	return thread.get("dialog_options", []) if typeof(thread.get("dialog_options", [])) == TYPE_ARRAY else []


func _option_by_id(options: Array, option_id: String) -> Dictionary:
	for option_value in options:
		if typeof(option_value) == TYPE_DICTIONARY and str(option_value.get("option_id", "")) == option_id:
			return option_value
	return {}


func _apply_option(feed_data: Dictionary, snapshot: Dictionary, account_id: String, option: Dictionary) -> Dictionary:
	return _interaction_system.apply_message_action(
		RunState,
		feed_data,
		snapshot,
		account_id,
		str(option.get("action_id", "")),
		str(option.get("thesis_id", "")),
		str(option.get("player_text", "")),
		str(option.get("option_id", ""))
	)


func _account_branch(account_id: String) -> Dictionary:
	var state: Dictionary = RunState.get_twooter_social_state()
	var dialog_state: Dictionary = state.get("dialog_state", {}) if typeof(state.get("dialog_state", {})) == TYPE_DICTIONARY else {}
	var accounts: Dictionary = dialog_state.get("accounts", {}) if typeof(dialog_state.get("accounts", {})) == TYPE_DICTIONARY else {}
	return accounts.get(account_id, {}) if typeof(accounts.get(account_id, {})) == TYPE_DICTIONARY else {}


func _reset_social_state(account: Dictionary, account_state: Dictionary, day_index: int) -> void:
	_set_day(day_index)
	RunState.set_twooter_social_state(_social_state_for_account(account, account_state, day_index))


func _set_day(day_index: int) -> void:
	RunState.day_index = day_index
	RunState.daily_action_day_index = day_index
	RunState.daily_actions_used = 0


func _snapshot(account: Dictionary) -> Dictionary:
	return {
		"accounts": [account],
		"posts": [],
		"shareable_theses": [],
		"message_threads": [],
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


func _network_account(id_suffix: String, dialog_trees: Array, profile_overrides: Dictionary) -> Dictionary:
	var account_id: String = "progress_%s" % id_suffix
	var profile: Dictionary = {
		"role": "Network progression test account",
		"intro": "Synthetic Network contact for Twooter progression.",
		"description": "Synthetic Network contact for Twooter progression.",
		"account_origin": "network_contact",
		"network_source": true,
		"network_contact_id": "contact_%s" % id_suffix,
		"dialog_trees": dialog_trees,
		"risk_profile": "clean",
		"target_company_id": "test_company",
		"target_ticker": "TEST",
		"target_company_name": "Test Company"
	}
	for key_value in profile_overrides.keys():
		profile[key_value] = profile_overrides.get(key_value)
	return {
		"id": account_id,
		"display_name": "Progress %s" % id_suffix.capitalize(),
		"handle": "@%s" % account_id,
		"tier": 1,
		"verified": false,
		"voice": "evidence",
		"public_post_count": 0,
		"social_profile": profile
	}


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


func _contact(role: String, affiliation_type: String, reliability: float, tone: String) -> Dictionary:
	return {
		"id": "contact_%s" % role.replace(" ", "_"),
		"role": role,
		"affiliation_type": affiliation_type,
		"reliability": reliability,
		"tone": tone,
		"intro": "Synthetic contact for Twooter progression test."
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
