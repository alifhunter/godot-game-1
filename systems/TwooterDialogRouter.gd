extends RefCounted

const TWOOTER_OUTCOME_RESOLVER_SCRIPT := preload("res://systems/TwooterOutcomeResolver.gd")

const DIALOG_TRUST_TREE_RELATIONSHIP := 18
const DIALOG_INTRO_RELATIONSHIP_CEILING := 5
const DIALOG_THESIS_REVIEW_CREDIBILITY := 12
const DIALOG_SOURCE_CHECK_CREDIBILITY := 8
const DIALOG_TRUST_THREAD_ROWS := 4


static func dialog_branch(state: Dictionary, scope: String, key_id: String, fallback_tree_id: String, feed_data: Dictionary, emergency_tree_id: String, fallback_dialog_trees: Dictionary, public_action_ids: Array, private_action_ids: Array) -> Dictionary:
	var dialog_state: Dictionary = state.get("dialog_state", {}) if typeof(state.get("dialog_state", {})) == TYPE_DICTIONARY else {}
	var scope_rows: Dictionary = dialog_state.get(scope, {}) if typeof(dialog_state.get(scope, {})) == TYPE_DICTIONARY else {}
	var branch: Dictionary = normalize_dialog_branch(scope_rows.get(key_id, {}))
	var is_private: bool = scope == "accounts"
	var tree_id: String = str(branch.get("tree_id", ""))
	if tree_id.is_empty():
		tree_id = fallback_tree_id
	if tree_id.is_empty() or not tree_has_surface(feed_data, tree_id, is_private, public_action_ids, private_action_ids):
		tree_id = emergency_tree_id
	var tree: Dictionary = dialog_tree(feed_data, tree_id, emergency_tree_id, fallback_dialog_trees)
	branch["tree_id"] = tree_id
	if str(branch.get("node_id", "")).is_empty():
		branch["node_id"] = str(tree.get("entry_node", ""))
	var graduation_node_id: String = dialog_graduation_node_id(tree, branch)
	if not graduation_node_id.is_empty():
		branch["node_id"] = graduation_node_id
	return branch


static func select_public_tree_id(feed_data: Dictionary, account: Dictionary, account_state: Dictionary, post: Dictionary, public_action_ids: Array, private_action_ids: Array) -> String:
	var routed_tree_id: String = select_routed_tree_id(feed_data, "public", account, account_state, post, {}, [], public_action_ids, private_action_ids)
	if not routed_tree_id.is_empty():
		return routed_tree_id
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var preferred_tree_id: String = profile_preferred_tree_id(feed_data, profile, false, public_action_ids, private_action_ids)
	if not preferred_tree_id.is_empty():
		return preferred_tree_id
	var category: String = str(post.get("category", "")).to_lower()
	if category.contains("source") or category.contains("rumor") or category.contains("corporate"):
		return "source_check"
	if int(account_state.get("relationship", 0)) >= DIALOG_TRUST_TREE_RELATIONSHIP:
		return "trust_building"
	return "market_read"


static func select_message_tree_id(feed_data: Dictionary, account: Dictionary, account_state: Dictionary, thread: Dictionary, shareable_theses: Array, public_action_ids: Array, private_action_ids: Array) -> String:
	var routed_tree_id: String = select_routed_tree_id(feed_data, "private", account, account_state, {}, thread, shareable_theses, public_action_ids, private_action_ids)
	if not routed_tree_id.is_empty():
		return routed_tree_id
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var is_network_source: bool = TWOOTER_OUTCOME_RESOLVER_SCRIPT.is_network_source_account(account)
	if is_network_source:
		var preferred_network_tree_id: String = profile_preferred_tree_id(feed_data, profile, true, public_action_ids, private_action_ids)
		if not preferred_network_tree_id.is_empty():
			return preferred_network_tree_id
	if str(profile.get("risk_profile", "")) == "suspicious":
		return "suspicious_boundary"
	var stage: String = relationship_stage(int(account_state.get("relationship", 0)), int(account_state.get("credibility", 0)), int(account_state.get("importance", 0)))
	if stage in ["trusted", "inner_circle_candidate"]:
		return "event_invite"
	if int(account_state.get("relationship", 0)) < DIALOG_INTRO_RELATIONSHIP_CEILING:
		return "clean_intro"
	if int(account_state.get("credibility", 0)) < DIALOG_THESIS_REVIEW_CREDIBILITY:
		return "thesis_review"
	var rows: Array = thread.get("rows", []) if typeof(thread.get("rows", [])) == TYPE_ARRAY else []
	if rows.size() >= DIALOG_TRUST_THREAD_ROWS or int(account_state.get("relationship", 0)) >= DIALOG_TRUST_TREE_RELATIONSHIP:
		return "trust_building"
	if int(account_state.get("credibility", 0)) < DIALOG_SOURCE_CHECK_CREDIBILITY:
		return "source_check"
	var preferred_tree_id: String = profile_preferred_tree_id(feed_data, profile, true, public_action_ids, private_action_ids)
	if not preferred_tree_id.is_empty():
		return preferred_tree_id
	return "clean_intro"


static func select_routed_tree_id(feed_data: Dictionary, surface: String, account: Dictionary, account_state: Dictionary, post: Dictionary, thread: Dictionary, shareable_theses: Array, public_action_ids: Array, private_action_ids: Array) -> String:
	var is_private: bool = surface == "private"
	var routing: Dictionary = feed_data.get("dialog_routing", {}) if typeof(feed_data.get("dialog_routing", {})) == TYPE_DICTIONARY else {}
	var rule_key: String = "private_rules" if is_private else "public_rules"
	var rules: Array = routing.get(rule_key, []) if typeof(routing.get(rule_key, [])) == TYPE_ARRAY else []
	if rules.is_empty():
		return ""
	for rule_value: Variant in rules:
		if typeof(rule_value) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_value
		var conditions: Dictionary = rule.get("conditions", {}) if typeof(rule.get("conditions", {})) == TYPE_DICTIONARY else {}
		if not routing_conditions_match(conditions, account, account_state, post, thread, shareable_theses):
			continue
		var tree_id: String = str(rule.get("tree_id", "")).strip_edges()
		if tree_id == "profile_preferred":
			var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
			tree_id = profile_preferred_tree_id(feed_data, profile, is_private, public_action_ids, private_action_ids)
		if tree_id.is_empty() or not tree_has_surface(feed_data, tree_id, is_private, public_action_ids, private_action_ids):
			continue
		return tree_id
	return ""


static func routing_conditions_match(conditions: Dictionary, account: Dictionary, account_state: Dictionary, post: Dictionary, thread: Dictionary, _shareable_theses: Array) -> bool:
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	if conditions.has("risk_profile") and str(profile.get("risk_profile", "")) != str(conditions.get("risk_profile", "")):
		return false
	if conditions.has("affiliation_role") and str(profile.get("affiliation_role", "")) != str(conditions.get("affiliation_role", "")):
		return false
	if conditions.has("network_source"):
		var is_network_source: bool = TWOOTER_OUTCOME_RESOLVER_SCRIPT.is_network_source_account(account)
		if is_network_source != bool(conditions.get("network_source", false)):
			return false
	if conditions.has("relationship_lt") and int(account_state.get("relationship", 0)) >= int(conditions.get("relationship_lt", 0)):
		return false
	if conditions.has("relationship_gte") and int(account_state.get("relationship", 0)) < int(conditions.get("relationship_gte", 0)):
		return false
	if conditions.has("credibility_lt") and int(account_state.get("credibility", 0)) >= int(conditions.get("credibility_lt", 0)):
		return false
	if conditions.has("credibility_gte") and int(account_state.get("credibility", 0)) < int(conditions.get("credibility_gte", 0)):
		return false
	if conditions.has("relationship_stage"):
		var stage: String = relationship_stage(int(account_state.get("relationship", 0)), int(account_state.get("credibility", 0)), int(account_state.get("importance", 0)))
		var required_stage: Variant = conditions.get("relationship_stage", "")
		if typeof(required_stage) == TYPE_ARRAY:
			var stage_matched := false
			for stage_value: Variant in required_stage:
				if stage == str(stage_value):
					stage_matched = true
					break
			if not stage_matched:
				return false
		elif stage != str(required_stage):
			return false
	if conditions.has("thread_rows_gte"):
		var rows: Array = thread.get("rows", []) if typeof(thread.get("rows", [])) == TYPE_ARRAY else []
		if rows.size() < int(conditions.get("thread_rows_gte", 0)):
			return false
	if conditions.has("post_category_contains_any"):
		var needles: Array = conditions.get("post_category_contains_any", []) if typeof(conditions.get("post_category_contains_any", [])) == TYPE_ARRAY else []
		var category: String = str(post.get("category", "")).to_lower()
		var category_matched := false
		for needle_value: Variant in needles:
			var needle: String = str(needle_value).to_lower().strip_edges()
			if not needle.is_empty() and category.contains(needle):
				category_matched = true
				break
		if not category_matched:
			return false
	return true


static func profile_preferred_tree_id(feed_data: Dictionary, profile: Dictionary, is_private: bool, public_action_ids: Array, private_action_ids: Array) -> String:
	var trees: Array = profile.get("dialog_trees", []) if typeof(profile.get("dialog_trees", [])) == TYPE_ARRAY else []
	for tree_value: Variant in trees:
		var tree_id: String = str(tree_value)
		if tree_has_surface(feed_data, tree_id, is_private, public_action_ids, private_action_ids):
			return tree_id
	return ""


static func tree_has_surface(feed_data: Dictionary, tree_id: String, is_private: bool, public_action_ids: Array, private_action_ids: Array) -> bool:
	var tree: Dictionary = dialog_tree_exact(feed_data, tree_id)
	var nodes: Dictionary = tree.get("nodes", {}) if typeof(tree.get("nodes", {})) == TYPE_DICTIONARY else {}
	for node_value: Variant in nodes.values():
		if typeof(node_value) != TYPE_DICTIONARY:
			continue
		var node: Dictionary = node_value
		var options: Array = node.get("options", []) if typeof(node.get("options", [])) == TYPE_ARRAY else []
		for option_value: Variant in options:
			if typeof(option_value) == TYPE_DICTIONARY and not dialog_option_action_id(option_value, is_private, public_action_ids, private_action_ids).is_empty():
				return true
	return false


static func dialog_tree(feed_data: Dictionary, tree_id: String, fallback_tree_id: String, fallback_dialog_trees: Dictionary) -> Dictionary:
	var tree: Dictionary = dialog_tree_exact_with_fallback(feed_data, tree_id, fallback_dialog_trees)
	if tree.is_empty():
		tree = dialog_tree_exact_with_fallback(feed_data, fallback_tree_id, fallback_dialog_trees)
	return tree


static func dialog_tree_exact(feed_data: Dictionary, tree_id: String) -> Dictionary:
	var trees: Dictionary = feed_data.get("dialog_trees", {}) if typeof(feed_data.get("dialog_trees", {})) == TYPE_DICTIONARY else {}
	return trees.get(tree_id, {}) if typeof(trees.get(tree_id, {})) == TYPE_DICTIONARY else {}


static func dialog_tree_exact_with_fallback(feed_data: Dictionary, tree_id: String, fallback_dialog_trees: Dictionary) -> Dictionary:
	var trees: Dictionary = feed_data.get("dialog_trees", {}) if typeof(feed_data.get("dialog_trees", {})) == TYPE_DICTIONARY else {}
	if trees.is_empty():
		trees = fallback_dialog_trees
	return trees.get(tree_id, {}) if typeof(trees.get(tree_id, {})) == TYPE_DICTIONARY else {}


static func dialog_graduation(tree: Dictionary) -> Dictionary:
	var graduation: Dictionary = tree.get("graduation", {}) if typeof(tree.get("graduation", {})) == TYPE_DICTIONARY else {}
	var steps: int = int(graduation.get("steps", 0))
	var node_id: String = str(graduation.get("node", "")).strip_edges()
	var next_tree_id: String = str(graduation.get("next_tree", "")).strip_edges()
	if steps <= 0 or node_id.is_empty() or next_tree_id.is_empty():
		return {}
	return {
		"steps": steps,
		"node": node_id,
		"next_tree": next_tree_id
	}


static func dialog_graduation_node_id(tree: Dictionary, branch: Dictionary) -> String:
	var graduation: Dictionary = dialog_graduation(tree)
	if graduation.is_empty() or int(branch.get("step_count", 0)) < int(graduation.get("steps", 0)):
		return ""
	var node_id: String = str(graduation.get("node", "")).strip_edges()
	var nodes: Dictionary = tree.get("nodes", {}) if typeof(tree.get("nodes", {})) == TYPE_DICTIONARY else {}
	if node_id.is_empty() or not nodes.has(node_id):
		return ""
	return node_id


static func normalize_dialog_branch(source: Variant) -> Dictionary:
	var row: Dictionary = source if typeof(source) == TYPE_DICTIONARY else {}
	return {
		"tree_id": str(row.get("tree_id", "")),
		"node_id": str(row.get("node_id", "")),
		"last_option_id": str(row.get("last_option_id", "")),
		"last_outcome": str(row.get("last_outcome", "")),
		"last_action_id": str(row.get("last_action_id", "")),
		"repeat_count": max(int(row.get("repeat_count", 0)), 0),
		"last_day_index": int(row.get("last_day_index", -1)),
		"cooldown_until_day": int(row.get("cooldown_until_day", -1)),
		"cooldown_reason": str(row.get("cooldown_reason", "")),
		"step_count": max(int(row.get("step_count", 0)), 0)
	}


static func dialog_option_action_id(option: Dictionary, is_private: bool, public_action_ids: Array, private_action_ids: Array) -> String:
	var key: String = "private_action_id" if is_private else "public_action_id"
	var action_id: String = str(option.get(key, ""))
	if action_id.is_empty():
		action_id = str(option.get("action_id", ""))
	if is_private and not private_action_ids.has(action_id):
		return ""
	if not is_private and not public_action_ids.has(action_id):
		return ""
	return action_id


static func relationship_stage(relationship: int, credibility: int, importance: int) -> String:
	if relationship >= 70 and credibility >= 45 and importance >= 55:
		return "inner_circle_candidate"
	if relationship >= 45:
		return "trusted"
	if relationship >= 18:
		return "familiar"
	return "stranger"
