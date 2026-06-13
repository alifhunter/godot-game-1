extends Node

const RUN_SEED := 617031
const DAY_INDEX := 12
const TWOOTER_INTERACTION_SYSTEM_SCRIPT := preload("res://systems/TwooterInteractionSystem.gd")

var _interaction_system = TWOOTER_INTERACTION_SYSTEM_SCRIPT.new()
var _failed := false
var _audit := {
	"public": {},
	"private": {},
	"stale_branch": {}
}


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	_setup_run()
	var account: Dictionary = _account()
	var post: Dictionary = _post(account)
	RunState.set_twooter_social_state(_social_state_for_account(account, _account_state(), DAY_INDEX))

	_assert_public_fallback(account, post)
	if _failed:
		return
	_assert_private_fallback(account)
	if _failed:
		return
	_assert_stale_branch_fallback(account)
	if _failed:
		return

	print("TWOOTER_FALLBACK_DIALOG_OK %s" % JSON.stringify(_audit))
	get_tree().quit(0)


func _assert_public_fallback(account: Dictionary, post: Dictionary) -> void:
	var snapshot: Dictionary = _snapshot(account, post)
	var enriched: Dictionary = _interaction_system.enhance_snapshot(
		snapshot,
		RunState.get_twooter_social_state(),
		{},
		{},
		_daily_action(DAY_INDEX),
		DAY_INDEX
	)
	var posts: Array = enriched.get("posts", []) if typeof(enriched.get("posts", [])) == TYPE_ARRAY else []
	var enriched_post: Dictionary = posts[0] if not posts.is_empty() and typeof(posts[0]) == TYPE_DICTIONARY else {}
	var options: Array = enriched_post.get("reply_dialog_options", []) if typeof(enriched_post.get("reply_dialog_options", [])) == TYPE_ARRAY else []
	if options.size() < 3:
		_fail("Expected empty-feed public fallback to expose three options, got %d." % options.size())
		return
	if not _all_options_use_tree(options, "clean_intro"):
		_fail("Expected empty-feed public fallback options to use clean_intro, got %s." % str(options))
		return
	var source_option: Dictionary = _option_by_id(options, "fallback_source")
	if source_option.is_empty() or str(source_option.get("action_id", "")) != "ask_source_public":
		_fail("Expected empty-feed public fallback_source to map to ask_source_public.")
		return
	var result: Dictionary = _interaction_system.apply_post_interaction(
		RunState,
		{},
		snapshot,
		str(post.get("id", "")),
		str(source_option.get("action_id", "")),
		"",
		str(source_option.get("player_text", "")),
		str(source_option.get("option_id", ""))
	)
	if not bool(result.get("success", false)) or str(result.get("dialog_outcome", "")) != "source_check":
		_fail("Expected empty-feed public fallback_source to apply source_check, got %s." % str(result))
		return
	_audit["public"] = {
		"tree": str(source_option.get("tree_id", "")),
		"option": str(source_option.get("option_id", "")),
		"action": str(source_option.get("action_id", "")),
		"outcome": str(result.get("dialog_outcome", ""))
	}


func _assert_private_fallback(account: Dictionary) -> void:
	var options: Array = _thread_options(account)
	if options.size() < 3:
		_fail("Expected empty-feed private fallback to expose three options, got %d." % options.size())
		return
	if not _all_options_use_tree(options, "clean_intro"):
		_fail("Expected empty-feed private fallback options to use clean_intro, got %s." % str(options))
		return
	var source_option: Dictionary = _option_by_id(options, "fallback_source")
	if source_option.is_empty() or str(source_option.get("action_id", "")) != "ask_source_private":
		_fail("Expected empty-feed private fallback_source to map to ask_source_private.")
		return
	var result: Dictionary = _interaction_system.apply_message_action(
		RunState,
		{},
		_snapshot(account, {}),
		str(account.get("id", "")),
		str(source_option.get("action_id", "")),
		"",
		str(source_option.get("player_text", "")),
		str(source_option.get("option_id", ""))
	)
	if not bool(result.get("success", false)) or str(result.get("dialog_outcome", "")) != "source_check":
		_fail("Expected empty-feed private fallback_source to apply source_check, got %s." % str(result))
		return
	_audit["private"] = {
		"tree": str(source_option.get("tree_id", "")),
		"option": str(source_option.get("option_id", "")),
		"action": str(source_option.get("action_id", "")),
		"outcome": str(result.get("dialog_outcome", "")),
		"network_changed": bool(result.get("network_changed", false))
	}


func _assert_stale_branch_fallback(account: Dictionary) -> void:
	var account_id: String = str(account.get("id", ""))
	var state: Dictionary = RunState.get_twooter_social_state()
	var dialog_state: Dictionary = state.get("dialog_state", {}) if typeof(state.get("dialog_state", {})) == TYPE_DICTIONARY else {}
	var accounts: Dictionary = dialog_state.get("accounts", {}) if typeof(dialog_state.get("accounts", {})) == TYPE_DICTIONARY else {}
	accounts[account_id] = {
		"tree_id": "event_invite",
		"node_id": "invite",
		"last_option_id": "accept_clean",
		"last_outcome": "event_invite",
		"last_action_id": "accept_invite",
		"repeat_count": 0,
		"last_day_index": DAY_INDEX - 1,
		"cooldown_until_day": -1,
		"cooldown_reason": "",
		"step_count": 1
	}
	dialog_state["accounts"] = accounts
	state["dialog_state"] = dialog_state
	RunState.set_twooter_social_state(state)

	var options: Array = _thread_options(account)
	if options.is_empty() or not _all_options_use_tree(options, "clean_intro"):
		_fail("Expected stale missing branch tree to normalize to clean_intro, got %s." % str(options))
		return
	_audit["stale_branch"] = {
		"tree": str(options[0].get("tree_id", "")),
		"option_count": options.size()
	}


func _setup_run() -> void:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	RunState.day_index = DAY_INDEX
	RunState.daily_action_day_index = DAY_INDEX
	RunState.daily_actions_used = 0


func _thread_options(account: Dictionary) -> Array:
	var thread: Dictionary = _interaction_system.get_message_thread(
		RunState.get_twooter_social_state(),
		[account],
		str(account.get("id", "")),
		DAY_INDEX,
		[],
		{},
		_daily_action(DAY_INDEX)
	)
	return thread.get("dialog_options", []) if typeof(thread.get("dialog_options", [])) == TYPE_ARRAY else []


func _option_by_id(options: Array, option_id: String) -> Dictionary:
	for option_value: Variant in options:
		if typeof(option_value) == TYPE_DICTIONARY and str(option_value.get("option_id", "")) == option_id:
			return option_value
	return {}


func _all_options_use_tree(options: Array, tree_id: String) -> bool:
	for option_value: Variant in options:
		if typeof(option_value) != TYPE_DICTIONARY or str(option_value.get("tree_id", "")) != tree_id:
			return false
	return not options.is_empty()


func _snapshot(account: Dictionary, post: Dictionary = {}) -> Dictionary:
	var posts: Array = []
	if not post.is_empty():
		posts.append(post)
	return {
		"accounts": [account],
		"posts": posts,
		"message_threads": [],
		"shareable_theses": [],
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


func _account() -> Dictionary:
	return {
		"id": "fallback_account",
		"display_name": "Fallback Account",
		"handle": "@fallback_account",
		"tier": 1,
		"verified": false,
		"voice": "evidence",
		"public_post_count": 1,
		"social_profile": {
			"role": "Fallback test account",
			"intro": "Synthetic account for default dialog fallback tests.",
			"description": "Synthetic account for default dialog fallback tests.",
			"risk_profile": "clean",
			"dialog_trees": ["source_check", "event_invite"],
			"target_company_id": "test_company",
			"target_ticker": "TEST",
			"target_company_name": "Test Company"
		}
	}


func _post(account: Dictionary) -> Dictionary:
	return {
		"id": "fallback_post",
		"account_id": str(account.get("id", "")),
		"account_name": str(account.get("display_name", "")),
		"account_handle": str(account.get("handle", "")),
		"post_text": "Synthetic fallback public post.",
		"category": "corporate rumor source",
		"tone": "mixed",
		"target_company_id": "test_company",
		"target_ticker": "TEST",
		"target_company_name": "Test Company",
		"likes": 0
	}


func _account_state() -> Dictionary:
	return {
		"relationship": 18,
		"exposure": 0,
		"credibility": 12,
		"importance": 10,
		"relationship_stage": "familiar",
		"following": true,
		"connected": false,
		"likes_given": 0,
		"interaction_count": 0,
		"like_relationship_progress": 0.0
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
