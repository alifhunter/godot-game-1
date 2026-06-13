class_name TwooterStateSystem
extends RefCounted

# Pure normalization logic for the Twooter social-state dict that RunState
# persists in saves. State stays in RunState (twooter_social_state); only the
# defaults/normalizers live here. Run context (day_index) is passed explicitly.


static func default_social_state(day_index: int) -> Dictionary:
	return {
		"account_states": {},
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


static func normalize_social_state(source_state: Variant, day_index: int) -> Dictionary:
	var source: Dictionary = source_state if typeof(source_state) == TYPE_DICTIONARY else {}
	var normalized: Dictionary = default_social_state(day_index)
	var account_states: Dictionary = source.get("account_states", {}) if typeof(source.get("account_states", {})) == TYPE_DICTIONARY else {}
	for account_id_value in account_states.keys():
		var account_id: String = str(account_id_value)
		if account_id.is_empty() or typeof(account_states.get(account_id_value)) != TYPE_DICTIONARY:
			continue
		normalized["account_states"][account_id] = normalize_account_state(account_states.get(account_id_value, {}))
	var post_interactions: Dictionary = source.get("post_interactions", {}) if typeof(source.get("post_interactions", {})) == TYPE_DICTIONARY else {}
	for post_id_value in post_interactions.keys():
		var post_id: String = str(post_id_value)
		if post_id.is_empty() or typeof(post_interactions.get(post_id_value)) != TYPE_DICTIONARY:
			continue
		normalized["post_interactions"][post_id] = normalize_post_interaction(post_interactions.get(post_id_value, {}))
	var liked_posts: Dictionary = source.get("liked_posts", {}) if typeof(source.get("liked_posts", {})) == TYPE_DICTIONARY else {}
	for post_id_value in liked_posts.keys():
		var liked_post_id: String = str(post_id_value)
		if liked_post_id.is_empty() or typeof(liked_posts.get(post_id_value)) != TYPE_DICTIONARY:
			continue
		normalized["liked_posts"][liked_post_id] = normalize_liked_post(liked_posts.get(post_id_value, {}))
	var messages: Dictionary = source.get("messages", {}) if typeof(source.get("messages", {})) == TYPE_DICTIONARY else {}
	for account_id_value in messages.keys():
		var account_id: String = str(account_id_value)
		if account_id.is_empty() or typeof(messages.get(account_id_value)) != TYPE_DICTIONARY:
			continue
		normalized["messages"][account_id] = normalize_message_thread(messages.get(account_id_value, {}))
	var dialog_source: Dictionary = source.get("dialog_state", {}) if typeof(source.get("dialog_state", {})) == TYPE_DICTIONARY else {}
	var normalized_dialog: Dictionary = {"accounts": {}, "posts": {}}
	for scope_id in ["accounts", "posts"]:
		var scope_rows: Dictionary = dialog_source.get(scope_id, {}) if typeof(dialog_source.get(scope_id, {})) == TYPE_DICTIONARY else {}
		for key_value in scope_rows.keys():
			var key_id: String = str(key_value)
			if key_id.is_empty() or typeof(scope_rows.get(key_value)) != TYPE_DICTIONARY:
				continue
			normalized_dialog[scope_id][key_id] = normalize_dialog_branch(scope_rows.get(key_value, {}))
	normalized["dialog_state"] = normalized_dialog
	var definitions: Dictionary = source.get("network_contact_definitions", {}) if typeof(source.get("network_contact_definitions", {})) == TYPE_DICTIONARY else {}
	for contact_id_value in definitions.keys():
		var contact_id: String = str(contact_id_value)
		if contact_id.is_empty() or typeof(definitions.get(contact_id_value)) != TYPE_DICTIONARY:
			continue
		normalized["network_contact_definitions"][contact_id] = definitions.get(contact_id_value, {}).duplicate(true)
	var daily: Dictionary = source.get("daily_public_interactions", {}) if typeof(source.get("daily_public_interactions", {})) == TYPE_DICTIONARY else {}
	if int(daily.get("day_index", day_index)) == day_index:
		normalized["daily_public_interactions"] = {
			"day_index": day_index,
			"account_action_counts": daily.get("account_action_counts", {}).duplicate(true) if typeof(daily.get("account_action_counts", {})) == TYPE_DICTIONARY else {}
		}
	return normalized


static func normalize_account_state(source_state: Variant) -> Dictionary:
	var source: Dictionary = source_state if typeof(source_state) == TYPE_DICTIONARY else {}
	var normalized: Dictionary = {
		"relationship": clampi(int(source.get("relationship", 0)), 0, 100),
		"exposure": clampi(int(source.get("exposure", 0)), 0, 100),
		"credibility": clampi(int(source.get("credibility", 0)), 0, 100),
		"importance": clampi(int(source.get("importance", 0)), 0, 100),
		"following": bool(source.get("following", false)),
		"connected": bool(source.get("connected", false)),
		"likes_given": max(int(source.get("likes_given", 0)), 0),
		"last_like_day_index": int(source.get("last_like_day_index", -1)),
		"like_relationship_progress": float(clamp(float(source.get("like_relationship_progress", 0.0)), 0.0, 0.99)),
		"unfollowed_ask_count": max(int(source.get("unfollowed_ask_count", 0)), 0),
		"last_unfollowed_ask_day_index": int(source.get("last_unfollowed_ask_day_index", -1)),
		"last_interaction_day_index": int(source.get("last_interaction_day_index", -1)),
		"interaction_count": max(int(source.get("interaction_count", 0)), 0),
		"relationship_stage": str(source.get("relationship_stage", "stranger")),
		"timeline": []
	}
	for timeline_value in source.get("timeline", []):
		if typeof(timeline_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = timeline_value
		normalized["timeline"].append({
			"day_index": int(row.get("day_index", 0)),
			"action_id": str(row.get("action_id", "")),
			"text": str(row.get("text", "")),
			"post_id": str(row.get("post_id", "")),
			"dialog_outcome": str(row.get("dialog_outcome", ""))
		})
	if normalized["timeline"].size() > 12:
		normalized["timeline"] = normalized["timeline"].slice(normalized["timeline"].size() - 12, normalized["timeline"].size())
	return normalized


static func normalize_post_interaction(source_interaction: Variant) -> Dictionary:
	var source: Dictionary = source_interaction if typeof(source_interaction) == TYPE_DICTIONARY else {}
	var replies: Array = []
	for reply_value in source.get("replies", []):
		if typeof(reply_value) != TYPE_DICTIONARY:
			continue
		var reply: Dictionary = reply_value
		replies.append({
			"account_id": str(reply.get("account_id", "")),
			"action_id": str(reply.get("action_id", "")),
			"player_text": str(reply.get("player_text", "")),
			"reply_text": str(reply.get("reply_text", "")),
			"day_index": int(reply.get("day_index", 0)),
			"relationship_delta": int(reply.get("relationship_delta", 0)),
			"exposure_delta": int(reply.get("exposure_delta", 0)),
			"credibility_delta": int(reply.get("credibility_delta", 0)),
			"dialog_outcome": str(reply.get("dialog_outcome", ""))
		})
	if replies.size() > 6:
		replies = replies.slice(replies.size() - 6, replies.size())
	return {
		"replies": replies,
		"interaction_count": max(int(source.get("interaction_count", 0)), 0),
		"last_day_index": int(source.get("last_day_index", -1)),
		"conversation_step": max(int(source.get("conversation_step", 0)), 0),
		"concluded": bool(source.get("concluded", false)),
		"conclusion_reason": str(source.get("conclusion_reason", "")),
		"followup_unlocked": bool(source.get("followup_unlocked", false))
	}


static func normalize_liked_post(source_like: Variant) -> Dictionary:
	var source: Dictionary = source_like if typeof(source_like) == TYPE_DICTIONARY else {}
	return {
		"account_id": str(source.get("account_id", "")),
		"day_index": int(source.get("day_index", -1))
	}


static func normalize_message_thread(source_thread: Variant) -> Dictionary:
	var source: Dictionary = source_thread if typeof(source_thread) == TYPE_DICTIONARY else {}
	var rows: Array = []
	for message_value in source.get("rows", []):
		if typeof(message_value) != TYPE_DICTIONARY:
			continue
		var message: Dictionary = message_value
		rows.append({
			"sender": str(message.get("sender", "")),
			"action_id": str(message.get("action_id", "")),
			"text": str(message.get("text", "")),
			"day_index": int(message.get("day_index", 0))
		})
	if rows.size() > 24:
		rows = rows.slice(rows.size() - 24, rows.size())
	return {
		"account_id": str(source.get("account_id", "")),
		"account_name": str(source.get("account_name", "")),
		"account_handle": str(source.get("account_handle", "")),
		"last_day_index": int(source.get("last_day_index", 0)),
		"unread_count": max(int(source.get("unread_count", 0)), 0),
		"rows": rows
	}


static func normalize_dialog_branch(source_branch: Variant) -> Dictionary:
	var source: Dictionary = source_branch if typeof(source_branch) == TYPE_DICTIONARY else {}
	return {
		"tree_id": str(source.get("tree_id", "")),
		"node_id": str(source.get("node_id", "")),
		"last_option_id": str(source.get("last_option_id", "")),
		"last_outcome": str(source.get("last_outcome", "")),
		"last_action_id": str(source.get("last_action_id", "")),
		"repeat_count": max(int(source.get("repeat_count", 0)), 0),
		"last_day_index": int(source.get("last_day_index", -1)),
		"cooldown_until_day": int(source.get("cooldown_until_day", -1)),
		"cooldown_reason": str(source.get("cooldown_reason", "")),
		"step_count": max(int(source.get("step_count", 0)), 0)
	}
