extends Node

const RUN_SEED := 617028
const DAY_INDEX := 12
const TWOOTER_INTERACTION_SYSTEM_SCRIPT := preload("res://systems/TwooterInteractionSystem.gd")

var _interaction_system = TWOOTER_INTERACTION_SYSTEM_SCRIPT.new()
var _failed := false
var _audit := {
	"default_public": [],
	"default_private": [],
	"overrides": [],
	"fallbacks": []
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
	_assert_default_public_routes(feed_data)
	_assert_default_private_routes(feed_data)
	_assert_routing_overrides(feed_data)
	_assert_routing_fallbacks(feed_data)
	if _failed:
		return

	print("TWOOTER_ROUTING_RULES_OK %s" % JSON.stringify(_audit))
	get_tree().quit(0)


func _assert_default_public_routes(feed_data: Dictionary) -> void:
	_assert_public_route(feed_data, "public_profile_preferred", _account("public_profile", {"dialog_trees": ["source_check"]}, 1), _account_state(1, 0, 0), "market", "source_check", "default_public")
	_assert_public_route(feed_data, "public_source_category", _account("public_source", {}, 1), _account_state(1, 0, 0), "corporate rumor source", "source_check", "default_public")
	_assert_public_route(feed_data, "public_trust_relationship", _account("public_trust", {}, 1), _account_state(18, 12, 12), "market", "trust_building", "default_public")
	_assert_public_route(feed_data, "public_default", _account("public_default", {}, 1), _account_state(1, 0, 0), "market", "market_read", "default_public")


func _assert_default_private_routes(feed_data: Dictionary) -> void:
	_assert_private_route(feed_data, "private_network_stranger", _network_account("private_network_stranger", ["network_source_followup", "network_relationship_probe"], {}), _account_state(4, 4, 4), [], "network_stranger_source", "default_private")
	_assert_private_route(feed_data, "private_network_familiar", _network_account("private_network_familiar", ["network_source_followup", "network_relationship_probe"], {}), _account_state(18, 12, 12), [], "network_familiar_source", "default_private")
	_assert_private_route(feed_data, "private_network_trusted", _network_account("private_network_trusted", ["network_source_followup", "network_relationship_probe"], {}), _account_state(45, 20, 30), [], "network_trusted_source", "default_private")
	_assert_private_route(feed_data, "private_network_inner_circle", _network_account("private_network_inner", ["network_source_followup", "network_relationship_probe"], {}), _account_state(72, 48, 58, 36), [], "network_inner_circle_source", "default_private")
	_assert_private_route(feed_data, "private_network_insider_profile", _network_account("private_network_insider", ["network_insider_boundary", "network_source_followup", "source_check"], {"affiliation_role": "insider"}), _account_state(18, 12, 12), [], "network_insider_boundary", "default_private")
	_assert_private_route(feed_data, "private_network_guarded_profile", _network_account("private_network_guarded", ["network_guarded_source", "suspicious_boundary", "source_check"], {"risk_profile": "suspicious"}), _account_state(18, 12, 12), [], "network_guarded_source", "default_private")
	_assert_private_route(feed_data, "private_suspicious", _account("private_suspicious", {"risk_profile": "suspicious"}, 0), _account_state(1, 0, 0), [], "suspicious_boundary", "default_private")
	_assert_private_route(feed_data, "private_trusted_stage", _account("private_trusted", {}, 0), _account_state(45, 18, 18), [], "event_invite", "default_private")
	_assert_private_route(feed_data, "private_intro", _account("private_intro", {}, 0), _account_state(1, 0, 0), [], "clean_intro", "default_private")
	_assert_private_route(feed_data, "private_thesis_review", _account("private_thesis", {}, 0), _account_state(6, 0, 0), [], "thesis_review", "default_private")
	_assert_private_route(feed_data, "private_thread_trust", _account("private_thread", {}, 0), _account_state(8, 12, 6), _message_rows(4), "trust_building", "default_private")
	_assert_private_route(feed_data, "private_relationship_trust", _account("private_relationship", {}, 0), _account_state(18, 12, 10), [], "trust_building", "default_private")
	_assert_private_route(feed_data, "private_profile_preferred", _account("private_profile", {"dialog_trees": ["source_check"]}, 0), _account_state(8, 12, 6), [], "source_check", "default_private")
	_assert_private_route(feed_data, "private_default", _account("private_default", {}, 0), _account_state(8, 12, 6), [], "clean_intro", "default_private")


func _assert_routing_overrides(feed_data: Dictionary) -> void:
	var override_feed: Dictionary = feed_data.duplicate(true)
	var routing: Dictionary = override_feed.get("dialog_routing", {}).duplicate(true) if typeof(override_feed.get("dialog_routing", {})) == TYPE_DICTIONARY else {}
	routing["public_rules"] = [
		{
			"id": "override_market_public",
			"tree_id": "trust_building",
			"conditions": {
				"post_category_contains_any": ["market"]
			}
		},
		{
			"id": "override_public_default",
			"tree_id": "market_read"
		}
	]
	routing["private_rules"] = [
		{
			"id": "override_intro_private",
			"tree_id": "event_invite",
			"conditions": {
				"relationship_lt": 5
			}
		},
		{
			"id": "override_private_default",
			"tree_id": "clean_intro"
		}
	]
	override_feed["dialog_routing"] = routing
	_assert_public_route(override_feed, "override_public_market", _account("override_public", {}, 1), _account_state(1, 0, 0), "market", "trust_building", "overrides")
	_assert_private_route(override_feed, "override_private_intro", _account("override_private", {}, 0), _account_state(1, 0, 0), [], "event_invite", "overrides")


func _assert_routing_fallbacks(feed_data: Dictionary) -> void:
	var absent_feed: Dictionary = feed_data.duplicate(true)
	absent_feed.erase("dialog_routing")
	_assert_public_route(absent_feed, "absent_public_profile_fallback", _account("absent_profile", {"dialog_trees": ["source_check"]}, 1), _account_state(1, 0, 0), "market", "source_check", "fallbacks")
	_assert_private_route(absent_feed, "absent_private_intro_fallback", _account("absent_private", {}, 0), _account_state(1, 0, 0), [], "clean_intro", "fallbacks")

	var invalid_feed: Dictionary = feed_data.duplicate(true)
	invalid_feed["dialog_routing"] = {
		"public_rules": "not an array",
		"private_rules": 123
	}
	_assert_public_route(invalid_feed, "invalid_public_fallback", _account("invalid_public", {}, 1), _account_state(1, 0, 0), "market", "market_read", "fallbacks")
	_assert_private_route(invalid_feed, "invalid_private_fallback", _account("invalid_private", {}, 0), _account_state(1, 0, 0), [], "clean_intro", "fallbacks")


func _assert_public_route(feed_data: Dictionary, case_id: String, account: Dictionary, account_state: Dictionary, category: String, expected_tree_id: String, audit_key: String) -> void:
	var social_state: Dictionary = _social_state_for_account(account, account_state)
	var post: Dictionary = _post(account, category)
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
		_fail("Expected public routing case '%s' to expose options." % case_id)
		return
	var tree_id: String = _first_option_tree(options)
	if tree_id != expected_tree_id:
		_fail("Expected public routing case '%s' to choose '%s', got '%s'." % [case_id, expected_tree_id, tree_id])
		return
	_audit[audit_key].append({"case": case_id, "tree": tree_id})


func _assert_private_route(feed_data: Dictionary, case_id: String, account: Dictionary, account_state: Dictionary, rows: Array, expected_tree_id: String, audit_key: String) -> void:
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
		_fail("Expected private routing case '%s' to expose options." % case_id)
		return
	var tree_id: String = _first_option_tree(options)
	if tree_id != expected_tree_id:
		_fail("Expected private routing case '%s' to choose '%s', got '%s'." % [case_id, expected_tree_id, tree_id])
		return
	_audit[audit_key].append({"case": case_id, "tree": tree_id})


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
	var account_id: String = "routing_%s" % id_suffix
	var profile: Dictionary = {
		"role": "Routing test account",
		"intro": "Synthetic account for routing rules.",
		"description": "Synthetic account for routing rules.",
		"risk_profile": "clean",
		"target_company_id": "test_company",
		"target_ticker": "TEST",
		"target_company_name": "Test Company"
	}
	for key_value in profile_overrides.keys():
		profile[key_value] = profile_overrides.get(key_value)
	return {
		"id": account_id,
		"display_name": "Routing %s" % id_suffix.capitalize(),
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


func _account_state(relationship: int, credibility: int, importance: int, exposure: int = 0) -> Dictionary:
	return {
		"relationship": relationship,
		"exposure": exposure,
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


func _post(account: Dictionary, category: String) -> Dictionary:
	var account_id: String = str(account.get("id", ""))
	return {
		"id": "post_%s_%s" % [account_id, category.replace(" ", "_")],
		"account_id": account_id,
		"account_name": str(account.get("display_name", "Routing Account")),
		"account_handle": str(account.get("handle", "@routing")),
		"post_text": "Synthetic post for %s routing." % category,
		"category": category,
		"tone": "mixed",
		"target_company_id": "test_company",
		"target_ticker": "TEST",
		"target_company_name": "Test Company",
		"likes": 0
	}


func _message_rows(count: int) -> Array:
	var rows: Array = []
	for index in range(count):
		rows.append({
			"sender": "player" if index % 2 == 0 else "account",
			"text": "Synthetic routing message %d" % index,
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


func _fail(message: String) -> void:
	_failed = true
	push_error(message)
	get_tree().quit(1)
