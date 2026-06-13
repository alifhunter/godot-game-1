extends Node

const RUN_SEED := 617026
const DAY_INDEX := 12
const TWOOTER_INTERACTION_SYSTEM_SCRIPT := preload("res://systems/TwooterInteractionSystem.gd")

var _interaction_system = TWOOTER_INTERACTION_SYSTEM_SCRIPT.new()
var _failed := false
var _audit := {
	"private_trees": {},
	"public_trees": {},
	"selected_option_ids": [],
	"blocked_options": [],
	"graduations": [],
	"cooldowns": []
}


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	RunState.day_index = DAY_INDEX
	RunState.daily_action_day_index = DAY_INDEX
	RunState.daily_actions_used = 0

	var feed_data: Dictionary = DataRepository.get_twooter_feed_data()
	var expected_trees: Array = [
		"clean_intro",
		"market_read",
		"source_check",
		"thesis_review",
		"trust_building",
		"event_invite",
		"suspicious_boundary",
		"network_source_followup",
		"network_relationship_probe",
		"network_insider_boundary",
		"network_guarded_source"
	]

	_audit_private_route(feed_data, "clean_intro", _account("regular_low", {}, 1), _account_state(1, 0, 0), [])
	_audit_private_route(feed_data, "thesis_review", _account("regular_thesis", {}, 1), _account_state(6, 0, 0), [])
	_audit_private_route(feed_data, "trust_building", _account("regular_trust", {}, 1), _account_state(18, 12, 12), _message_rows(4))
	_audit_private_route(feed_data, "event_invite", _account("regular_event", {}, 1), _account_state(45, 18, 18), _message_rows(5))
	_audit_private_route(feed_data, "suspicious_boundary", _account("regular_suspicious", {"risk_profile": "suspicious"}, 1), _account_state(1, 0, 0), [])
	_audit_private_route(feed_data, "network_source_followup", _network_account("network_source", ["network_source_followup", "network_relationship_probe", "source_check"], {}), _account_state(4, 4, 4), [])
	_audit_private_route(feed_data, "network_relationship_probe", _network_account("network_probe", ["network_relationship_probe", "network_source_followup"], {}), _account_state(10, 6, 6), [])
	_audit_private_route(feed_data, "network_insider_boundary", _network_account("network_insider", ["network_insider_boundary", "network_source_followup", "source_check"], {"affiliation_role": "insider"}), _account_state(10, 6, 6), [])
	_audit_private_route(feed_data, "network_guarded_source", _network_account("network_guarded", ["network_guarded_source", "suspicious_boundary", "source_check"], {"risk_profile": "suspicious"}), _account_state(10, 6, 6), [])

	_audit_public_route(feed_data, "market_read", _account("public_market", {}, 1), _account_state(1, 0, 0), _post("public_market", "market"))
	_audit_public_route(feed_data, "source_check", _account("public_source", {}, 1), _account_state(1, 0, 0), _post("public_source", "corporate rumor source"))
	_audit_public_route(feed_data, "trust_building", _account("public_trust", {}, 1), _account_state(20, 10, 12), _post("public_trust", "market"))

	_audit_forced_branch(feed_data, "network_relationship_probe", _network_account("forced_probe", ["network_source_followup", "network_relationship_probe"], {}), _account_state(8, 5, 5))
	_audit_blocked_option(feed_data)
	_audit_cooldown(feed_data)
	_audit_graduation(feed_data)
	if _failed:
		return

	var missing: Array = []
	for tree_value in expected_trees:
		var tree_id: String = str(tree_value)
		if not _audit["private_trees"].has(tree_id) and not _audit["public_trees"].has(tree_id):
			missing.append(tree_id)
	if not missing.is_empty():
		_fail("Twooter dialog reachability expected every authored tree to be offered at least once. Missing: %s" % [", ".join(missing)])
		return
	if _audit["blocked_options"].is_empty():
		_fail("Twooter dialog reachability expected at least one blocked option audit row.")
		return
	if _audit["cooldowns"].is_empty():
		_fail("Twooter dialog reachability expected at least one cooldown audit row.")
		return
	if _audit["graduations"].is_empty():
		_fail("Twooter dialog reachability expected at least one graduation audit row.")
		return

	print("TWOOTER_DIALOG_REACHABILITY_OK %s" % JSON.stringify({
		"private_trees": _sorted_keys(_audit["private_trees"]),
		"public_trees": _sorted_keys(_audit["public_trees"]),
		"selected_option_ids": _audit["selected_option_ids"],
		"blocked_options": _audit["blocked_options"],
		"graduations": _audit["graduations"],
		"cooldowns": _audit["cooldowns"]
	}))
	get_tree().quit(0)


func _audit_private_route(feed_data: Dictionary, expected_tree_id: String, account: Dictionary, account_state: Dictionary, rows: Array) -> void:
	var social_state: Dictionary = _social_state_for_account(account, account_state)
	if not rows.is_empty():
		var messages: Dictionary = social_state.get("messages", {})
		messages[str(account.get("id", ""))] = {
			"account_id": str(account.get("id", "")),
			"rows": rows,
			"unread_count": 0,
			"last_day_index": DAY_INDEX - 1
		}
		social_state["messages"] = messages
	var thread: Dictionary = _interaction_system.get_message_thread(
		social_state,
		[account],
		str(account.get("id", "")),
		DAY_INDEX,
		[],
		feed_data,
		_daily_action()
	)
	var options: Array = thread.get("dialog_options", []) if typeof(thread.get("dialog_options", [])) == TYPE_ARRAY else []
	if options.is_empty():
		_fail("Expected private tree '%s' to expose dialog options." % expected_tree_id)
		return
	_record_options(options, "private")
	if not _options_have_tree(options, expected_tree_id):
		_fail("Expected private tree '%s', got '%s'." % [expected_tree_id, _first_option_tree(options)])


func _audit_public_route(feed_data: Dictionary, expected_tree_id: String, account: Dictionary, account_state: Dictionary, post: Dictionary) -> void:
	var social_state: Dictionary = _social_state_for_account(account, account_state)
	var snapshot: Dictionary = {
		"accounts": [account],
		"posts": [post],
		"message_threads": [],
		"shareable_theses": [],
		"trending_rows": [],
		"who_to_follow": []
	}
	var enriched: Dictionary = _interaction_system.enhance_snapshot(snapshot, social_state, feed_data, {}, _daily_action(), DAY_INDEX)
	var posts: Array = enriched.get("posts", []) if typeof(enriched.get("posts", [])) == TYPE_ARRAY else []
	var enriched_post: Dictionary = posts[0] if not posts.is_empty() and typeof(posts[0]) == TYPE_DICTIONARY else {}
	var options: Array = enriched_post.get("reply_dialog_options", []) if typeof(enriched_post.get("reply_dialog_options", [])) == TYPE_ARRAY else []
	if options.is_empty():
		_fail("Expected public tree '%s' to expose reply dialog options." % expected_tree_id)
		return
	_record_options(options, "public")
	if not _options_have_tree(options, expected_tree_id):
		_fail("Expected public tree '%s', got '%s'." % [expected_tree_id, _first_option_tree(options)])


func _audit_forced_branch(feed_data: Dictionary, tree_id: String, account: Dictionary, account_state: Dictionary) -> void:
	var social_state: Dictionary = _social_state_for_account(account, account_state)
	var dialog_state: Dictionary = social_state.get("dialog_state", {})
	var accounts: Dictionary = dialog_state.get("accounts", {})
	accounts[str(account.get("id", ""))] = _branch(tree_id, "")
	dialog_state["accounts"] = accounts
	social_state["dialog_state"] = dialog_state
	var thread: Dictionary = _interaction_system.get_message_thread(
		social_state,
		[account],
		str(account.get("id", "")),
		DAY_INDEX,
		[],
		feed_data,
		_daily_action()
	)
	var options: Array = thread.get("dialog_options", []) if typeof(thread.get("dialog_options", [])) == TYPE_ARRAY else []
	_record_options(options, "private")
	if not _options_have_tree(options, tree_id):
		_fail("Expected forced branch tree '%s' to remain renderable." % tree_id)


func _audit_blocked_option(feed_data: Dictionary) -> void:
	var account: Dictionary = _account("blocked_thesis", {}, 1)
	var social_state: Dictionary = _social_state_for_account(account, _account_state(6, 0, 0))
	var thread: Dictionary = _interaction_system.get_message_thread(
		social_state,
		[account],
		str(account.get("id", "")),
		DAY_INDEX,
		[],
		feed_data,
		_daily_action()
	)
	for option_value in thread.get("dialog_options", []):
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		if not bool(option.get("enabled", true)):
			_audit["blocked_options"].append({
				"tree_id": str(option.get("tree_id", "")),
				"option_id": str(option.get("option_id", "")),
				"blocked_reason": str(option.get("blocked_reason", ""))
			})


func _audit_cooldown(feed_data: Dictionary) -> void:
	var account: Dictionary = _account("cooldown_account", {}, 1)
	var social_state: Dictionary = _social_state_for_account(account, _account_state(3, 0, 0))
	var dialog_state: Dictionary = social_state.get("dialog_state", {})
	var accounts: Dictionary = dialog_state.get("accounts", {})
	accounts[str(account.get("id", ""))] = {
		"tree_id": "clean_intro",
		"node_id": "open",
		"last_option_id": "define_process",
		"last_action_id": "message_check_in",
		"repeat_count": 2,
		"last_day_index": DAY_INDEX,
		"step_count": 1,
		"cooldown_until_day": DAY_INDEX,
		"cooldown_reason": "soft_cooldown"
	}
	dialog_state["accounts"] = accounts
	social_state["dialog_state"] = dialog_state
	var thread: Dictionary = _interaction_system.get_message_thread(
		social_state,
		[account],
		str(account.get("id", "")),
		DAY_INDEX,
		[],
		feed_data,
		_daily_action()
	)
	if str(thread.get("cooldown_reason", "")) == "soft_cooldown" and thread.get("dialog_options", []).is_empty():
		_audit["cooldowns"].append({
			"scope": "private",
			"tree_id": "clean_intro",
			"reason": "soft_cooldown"
		})


func _audit_graduation(feed_data: Dictionary) -> void:
	var account: Dictionary = _account("graduation_account", {}, 1)
	var account_id: String = str(account.get("id", ""))
	var social_state: Dictionary = _social_state_for_account(account, _account_state(3, 0, 0))
	var dialog_state: Dictionary = social_state.get("dialog_state", {})
	var accounts: Dictionary = dialog_state.get("accounts", {})
	accounts[account_id] = {
		"tree_id": "clean_intro",
		"node_id": "open",
		"last_option_id": "trust_clean",
		"last_action_id": "connect",
		"repeat_count": 0,
		"last_day_index": DAY_INDEX - 1,
		"step_count": 3,
		"cooldown_until_day": -1,
		"cooldown_reason": ""
	}
	dialog_state["accounts"] = accounts
	social_state["dialog_state"] = dialog_state
	RunState.set_twooter_social_state(social_state)
	RunState.daily_action_day_index = DAY_INDEX
	RunState.daily_actions_used = 0
	var snapshot: Dictionary = {
		"accounts": [account],
		"posts": [],
		"shareable_theses": [],
		"message_threads": [],
		"trending_rows": [],
		"who_to_follow": []
	}
	var thread: Dictionary = _interaction_system.get_message_thread(
		RunState.get_twooter_social_state(),
		[account],
		account_id,
		DAY_INDEX,
		[],
		feed_data,
		_daily_action()
	)
	var options: Array = thread.get("dialog_options", []) if typeof(thread.get("dialog_options", [])) == TYPE_ARRAY else []
	if options.is_empty() or str(options[0].get("node_id", "")) != "handoff":
		_fail("Expected clean_intro graduation to route to the handoff node.")
		return
	var option: Dictionary = options[0]
	var result: Dictionary = _interaction_system.apply_message_action(
		RunState,
		feed_data,
		snapshot,
		account_id,
		str(option.get("action_id", "")),
		str(option.get("thesis_id", "")),
		str(option.get("player_text", "")),
		str(option.get("option_id", ""))
	)
	if not bool(result.get("success", false)) or not bool(result.get("dialog_graduated", false)) or str(result.get("dialog_next_tree", "")) != "thesis_review":
		_fail("Expected clean_intro handoff selection to complete graduation into thesis_review.")
		return
	_audit["graduations"].append({
		"from_tree": "clean_intro",
		"node_id": "handoff",
		"option_id": str(option.get("option_id", "")),
		"next_tree": str(result.get("dialog_next_tree", ""))
	})


func _record_options(options: Array, surface: String) -> void:
	for option_value in options:
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		var tree_id: String = str(option.get("tree_id", ""))
		if tree_id.is_empty():
			continue
		if surface == "public":
			_audit["public_trees"][tree_id] = true
		else:
			_audit["private_trees"][tree_id] = true
		var option_id: String = str(option.get("option_id", ""))
		if not option_id.is_empty() and not _audit["selected_option_ids"].has(option_id):
			_audit["selected_option_ids"].append(option_id)


func _options_have_tree(options: Array, tree_id: String) -> bool:
	for option_value in options:
		if typeof(option_value) == TYPE_DICTIONARY and str(option_value.get("tree_id", "")) == tree_id:
			return true
	return false


func _first_option_tree(options: Array) -> String:
	for option_value in options:
		if typeof(option_value) == TYPE_DICTIONARY:
			return str(option_value.get("tree_id", ""))
	return ""


func _social_state_for_account(account: Dictionary, account_state: Dictionary) -> Dictionary:
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
			"day_index": DAY_INDEX,
			"account_action_counts": {}
		}
	}


func _account(id_suffix: String, profile_overrides: Dictionary, public_post_count: int) -> Dictionary:
	var account_id: String = "reach_%s" % id_suffix
	var profile: Dictionary = {
		"role": "Reachability test account",
		"intro": "Synthetic account for dialog reachability.",
		"description": "Synthetic account for dialog reachability.",
		"risk_profile": "clean",
		"target_company_id": "test_company",
		"target_ticker": "TEST",
		"target_company_name": "Test Company"
	}
	for key_value in profile_overrides.keys():
		profile[key_value] = profile_overrides.get(key_value)
	return {
		"id": account_id,
		"display_name": "Reach %s" % id_suffix.capitalize(),
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
	for key_value in profile_overrides.keys():
		overrides[key_value] = profile_overrides.get(key_value)
	return _account(id_suffix, overrides, 0)


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


func _post(account_id: String, category: String) -> Dictionary:
	return {
		"id": "post_%s_%s" % [account_id, category.replace(" ", "_")],
		"account_id": "reach_%s" % account_id,
		"account_name": "Reach %s" % account_id.capitalize(),
		"account_handle": "@reach_%s" % account_id,
		"post_text": "Synthetic post for %s routing." % category,
		"category": category,
		"tone": "mixed",
		"target_company_id": "test_company",
		"target_ticker": "TEST",
		"target_company_name": "Test Company",
		"likes": 0
	}


func _branch(tree_id: String, node_id: String) -> Dictionary:
	return {
		"tree_id": tree_id,
		"node_id": node_id,
		"last_option_id": "",
		"last_outcome": "",
		"last_action_id": "",
		"repeat_count": 0,
		"last_day_index": DAY_INDEX - 1,
		"cooldown_until_day": -1,
		"cooldown_reason": "",
		"step_count": 0
	}


func _message_rows(count: int) -> Array:
	var rows: Array = []
	for index in range(count):
		rows.append({
			"sender": "player" if index % 2 == 0 else "account",
			"text": "Synthetic message %d" % index,
			"day_index": DAY_INDEX - 1,
			"action_id": "message_check_in"
		})
	return rows


func _daily_action() -> Dictionary:
	return {
		"day_index": DAY_INDEX,
		"used": 0,
		"remaining": 99,
		"limit": 99
	}


func _sorted_keys(source: Dictionary) -> Array:
	var rows: Array = source.keys()
	rows.sort()
	return rows


func _fail(message: String) -> void:
	_failed = true
	push_error(message)
	get_tree().quit(1)
