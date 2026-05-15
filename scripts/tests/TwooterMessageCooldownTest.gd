extends Node


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(515026, difficulty_config)
	RunState.setup_new_run(515026, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)

	var snapshot: Dictionary = GameManager.get_twooter_snapshot()
	var posts: Array = snapshot.get("posts", []) if typeof(snapshot.get("posts", [])) == TYPE_ARRAY else []
	if posts.is_empty() or typeof(posts[0]) != TYPE_DICTIONARY:
		_fail("Twooter cooldown regression expected at least one generated post.")
		return
	var account_id: String = str(posts[0].get("account_id", ""))
	if account_id.is_empty():
		_fail("Twooter cooldown regression expected a post account id.")
		return

	var social_state: Dictionary = RunState.get_twooter_social_state()
	var dialog_state: Dictionary = social_state.get("dialog_state", {}) if typeof(social_state.get("dialog_state", {})) == TYPE_DICTIONARY else {}
	var accounts: Dictionary = dialog_state.get("accounts", {}) if typeof(dialog_state.get("accounts", {})) == TYPE_DICTIONARY else {}
	accounts[account_id] = {
		"tree_id": "clean_intro",
		"node_id": "open",
		"last_option_id": "define_process",
		"last_action_id": "message_check_in",
		"repeat_count": 2,
		"last_day_index": RunState.day_index,
		"step_count": 3,
		"cooldown_until_day": RunState.day_index,
		"cooldown_reason": "soft_cooldown"
	}
	dialog_state["accounts"] = accounts
	social_state["dialog_state"] = dialog_state
	RunState.set_twooter_social_state(social_state)

	var thread: Dictionary = GameManager.get_twooter_message_thread(account_id)
	if str(thread.get("cooldown_reason", "")).is_empty() or not thread.get("dialog_options", []).is_empty():
		_fail("Twooter cooldown regression expected cooled-down message threads to expose no dialog options.")
		return
	var direct_send_ap_before: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var direct_send: Dictionary = GameManager.send_twooter_message(
		account_id,
		"message_check_in",
		"",
		"I am trying to reopen the same thread without new context."
	)
	if bool(direct_send.get("success", false)):
		_fail("Twooter cooldown regression expected direct sends to be rejected while cooled down.")
		return
	if int(GameManager.get_daily_action_snapshot().get("used", 0)) != direct_send_ap_before:
		_fail("Twooter cooldown regression expected rejected direct sends to refund the spent AP.")
		return

	var like_pair: Array = _first_same_account_post_pair(posts)
	if like_pair.size() >= 2:
		var first_like_post: Dictionary = like_pair[0]
		var second_like_post: Dictionary = like_pair[1]
		var first_like: Dictionary = GameManager.like_twooter_post(str(first_like_post.get("id", "")))
		var second_like: Dictionary = GameManager.like_twooter_post(str(second_like_post.get("id", "")))
		if (
			not bool(first_like.get("success", false)) or
			not bool(second_like.get("success", false)) or
			float(first_like.get("relationship_progress_added", 0.0)) < 0.49 or
			float(second_like.get("relationship_progress_added", 0.0)) > 0.26
		):
			_fail("Twooter loop balance expected same-day likes after the first one to help less.")
			return

	var game_root: Node = load("res://scenes/game/GameRoot.tscn").instantiate()
	add_child(game_root)
	await get_tree().process_frame
	game_root.call("_set_active_app", "social")
	await get_tree().process_frame
	var account: Dictionary = {}
	for account_value in snapshot.get("accounts", []):
		if typeof(account_value) == TYPE_DICTIONARY and str(account_value.get("id", "")) == account_id:
			account = account_value
			break
	var search_input: LineEdit = game_root.find_child("SocialAccountSearchInput", true, false) as LineEdit
	if search_input == null or account.is_empty() or str(account.get("display_name", "")).strip_edges().is_empty():
		_fail("Twooter cooldown regression expected right-rail account-name search to exist.")
		return
	var handle_query: String = str(account.get("handle", "")).strip_edges()
	if handle_query.is_empty() or str(account.get("display_name", "")).to_lower().contains(handle_query.to_lower()):
		handle_query = "@not_an_account_name"
	search_input.text = handle_query
	search_input.emit_signal("text_changed", handle_query)
	await get_tree().process_frame
	if game_root.find_child("SocialAccountSearchResultButton", true, false) != null:
		_fail("Twooter account search should match account names only, not handles.")
		return
	var account_name: String = str(account.get("display_name", "")).strip_edges()
	search_input.text = account_name
	search_input.emit_signal("text_changed", account_name)
	await get_tree().process_frame
	var search_result: Button = game_root.find_child("SocialAccountSearchResultButton", true, false) as Button
	if search_result == null or str(search_result.get_meta("social_account_id", "")) != account_id:
		_fail("Twooter account search expected to find the account by display name.")
		return
	search_input.text = ""
	search_input.emit_signal("text_changed", "")
	await get_tree().process_frame

	var silent_account_id: String = ""
	for account_value in snapshot.get("accounts", []):
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var silent_account: Dictionary = account_value
		if int(silent_account.get("public_post_count", 0)) <= 0 and not str(silent_account.get("id", "")).is_empty():
			silent_account_id = str(silent_account.get("id", ""))
			break
	if silent_account_id.is_empty():
		_fail("Twooter self-awareness regression expected at least one account with zero visible posts.")
		return
	var silent_thread: Dictionary = GameManager.get_twooter_message_thread(silent_account_id)
	for option_value in silent_thread.get("dialog_options", []):
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		if str(option_value.get("player_text", "")).to_lower().contains("your posts"):
			_fail("Twooter self-awareness regression expected zero-post accounts to avoid praise about their posts.")
			return
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0
	var no_post_result: Dictionary = GameManager.send_twooter_message(
		silent_account_id,
		"message_check_in",
		"",
		"Your posts are useful. I would like to compare notes without turning this into a shortcut."
	)
	var no_post_reply: String = str(no_post_result.get("reply_text", no_post_result.get("message", ""))).to_lower()
	if (
		not bool(no_post_result.get("success", false)) or
		(
			not no_post_reply.contains("not posted") and
			not no_post_reply.contains("zero public posts") and
			not no_post_reply.contains("no public posts") and
			not no_post_reply.contains("imaginary posts")
		)
	):
		_fail("Twooter self-awareness regression expected zero-post accounts to correct praise about their posts.")
		return
	var no_post_network_result: Dictionary = no_post_result.get("network_result", {}) if typeof(no_post_result.get("network_result", {})) == TYPE_DICTIONARY else {}
	var no_post_contact_id: String = str(no_post_network_result.get("contact_id", ""))
	var no_post_discovery: Dictionary = RunState.get_network_discoveries().get(no_post_contact_id, {}) if not no_post_contact_id.is_empty() else {}
	if (
		not bool(no_post_result.get("network_changed", false)) or
		str(no_post_discovery.get("source_type", "")) != "twooter" or
		str(no_post_discovery.get("source_label", "")).strip_edges().is_empty() or
		str(no_post_discovery.get("source_note", "")).strip_edges().is_empty() or
		not bool(no_post_discovery.get("source_only", false))
	):
		_fail("Twooter Network integration expected source-only DMs to create a provenance-rich Network discovery.")
		return

	game_root.set("selected_social_message_account_id", account_id)
	game_root.set("selected_social_view_id", "message")
	game_root.call("_refresh_social")
	await get_tree().process_frame
	if _visible_message_option_count(game_root) != 0:
		_fail("Twooter cooldown regression expected Message view to hide options for a cooled-down branch.")
		return

	var home_button: Button = game_root.find_child("SocialNavHomeButton", true, false) as Button
	var message_button: Button = game_root.find_child("SocialNavMessageButton", true, false) as Button
	if home_button == null or message_button == null:
		_fail("Twooter cooldown regression expected Home and Message nav buttons.")
		return
	home_button.emit_signal("pressed")
	await get_tree().process_frame
	message_button.emit_signal("pressed")
	await get_tree().process_frame
	if _visible_message_option_count(game_root) != 0:
		_fail("Twooter cooldown regression expected Home -> Message navigation to preserve cooldown.")
		return

	print("TWOOTER_MESSAGE_COOLDOWN_OK")
	game_root.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


func _visible_message_option_count(root: Node) -> int:
	var options: VBoxContainer = root.find_child("SocialMessageComposerOptions", true, false) as VBoxContainer
	if options == null:
		return 0
	var count: int = 0
	for child in options.get_children():
		var button: Button = child as Button
		if button != null and button.visible:
			count += 1
	return count


func _first_same_account_post_pair(posts: Array) -> Array:
	var by_account: Dictionary = {}
	for post_value in posts:
		if typeof(post_value) != TYPE_DICTIONARY:
			continue
		var post: Dictionary = post_value
		var post_id: String = str(post.get("id", ""))
		var account_id: String = str(post.get("account_id", ""))
		if post_id.is_empty() or account_id.is_empty():
			continue
		var rows: Array = by_account.get(account_id, [])
		rows.append(post)
		if rows.size() >= 2:
			return [rows[0], rows[1]]
		by_account[account_id] = rows
	return []


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
