extends Node

const CONTACT_NETWORK_SYSTEM_SCRIPT := preload("res://systems/ContactNetworkSystem.gd")
const COMPANY_RELATIONSHIP_GRAPH_SYSTEM := preload("res://systems/CompanyRelationshipGraphSystem.gd")
const MARKET_SIMULATOR := preload("res://systems/MarketSimulator.gd")

const RUN_SEED := 20260622
const CATALOG_COMPANY_COUNT := 30
const NETWORK_CONTACT_ID := "andika_brokerage_sales"


class ForcedRelationshipGraphSystem:
	extends RefCounted

	var force_edge_id: String = ""
	var real_graph_system

	func _init(p_real_graph_system, p_force_edge_id: String) -> void:
		real_graph_system = p_real_graph_system
		force_edge_id = p_force_edge_id

	func resolve_day(run_state, trade_date: Dictionary, day_number: int, macro_state: Dictionary, options: Dictionary = {}) -> Dictionary:
		var forced_options: Dictionary = options.duplicate(true)
		forced_options["force_event"] = true
		forced_options["force_edge_id"] = force_edge_id
		forced_options["blocked_company_ids"] = []
		return real_graph_system.resolve_day(run_state, trade_date, day_number, macro_state, forced_options)


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var edge: Dictionary = _setup_run_and_pick_edge()
	if edge.is_empty():
		return
	var events: Array = _simulate_forced_relationship_event(edge)
	if events.is_empty():
		return
	var event_row: Dictionary = events[0]
	var relationship_event_id: String = str(event_row.get("relationship_event_id", ""))
	var company_id: String = str(event_row.get("target_company_id", ""))

	var issues: Array[String] = []
	var article: Dictionary = _find_relationship_article(relationship_event_id)
	var post: Dictionary = _find_relationship_post(relationship_event_id)
	if article.is_empty():
		issues.append("missing_relationship_news_article")
	else:
		_validate_generated_surface("news", article, issues)
	if post.is_empty():
		issues.append("missing_relationship_twooter_post")
	else:
		_validate_generated_surface("twooter", post, issues)

	_seed_network_contact(company_id)
	var network_result: Dictionary = CONTACT_NETWORK_SYSTEM_SCRIPT.new().request_tip(
		RunState,
		DataRepository,
		GameManager.corporate_action_system,
		NETWORK_CONTACT_ID,
		company_id
	)
	_validate_network_result(network_result, issues)

	if not article.is_empty():
		_capture_and_validate("news", article, company_id, issues)
	if not post.is_empty():
		_capture_and_validate("twooter", post, company_id, issues)
	if bool(network_result.get("success", false)):
		_capture_and_validate("network", network_result, company_id, issues)

	if not issues.is_empty():
		_fail("Relationship content hook issues: %s" % JSON.stringify(issues))
		return

	print("COMPANY_RELATIONSHIP_CONTENT_HOOKS_OK %s" % JSON.stringify({
		"relationship_event_id": relationship_event_id,
		"edge_id": str(edge.get("edge_id", "")),
		"visibility": str(edge.get("visibility", "")),
		"company_id": company_id,
		"article_id": str(article.get("id", "")),
		"post_id": str(post.get("id", "")),
		"network_truth": str(network_result.get("public_truth_label", ""))
	}))
	get_tree().quit(0)


func _setup_run_and_pick_edge() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = CATALOG_COMPANY_COUNT
	difficulty_config["use_company_universe_catalog"] = true
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	var state: Dictionary = RunState.get_company_relationship_graph_state()
	var edge: Dictionary = _first_semipublic_edge(state)
	if edge.is_empty():
		_fail("Expected at least one semi-public relationship edge for content hook coverage.")
	return edge


func _simulate_forced_relationship_event(edge: Dictionary) -> Array:
	GameManager.market_simulator = MARKET_SIMULATOR.new(
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		ForcedRelationshipGraphSystem.new(COMPANY_RELATIONSHIP_GRAPH_SYSTEM.new(), str(edge.get("edge_id", "")))
	)
	var advance_result: Dictionary = GameManager.simulate_opening_session(false)
	var day_result: Dictionary = advance_result.get("day_result", {})
	var events: Array = day_result.get("relationship_graph_events", [])
	if events.size() != 2:
		_fail("Expected forced relationship event to emit two rows, got %d." % events.size())
		return []
	return events


func _first_semipublic_edge(state: Dictionary) -> Dictionary:
	var edge_ids: Array = state.get("edge_ids", []) if typeof(state.get("edge_ids", [])) == TYPE_ARRAY else []
	var edge_index: Dictionary = state.get("edge_index", {}) if typeof(state.get("edge_index", {})) == TYPE_DICTIONARY else {}
	for preferred_type in ["partner", "supplier", "customer", "competitor"]:
		for edge_id_value in edge_ids:
			var edge: Dictionary = edge_index.get(str(edge_id_value), {})
			if edge.is_empty():
				continue
			if str(edge.get("relationship_type", "")) != preferred_type:
				continue
			if str(edge.get("visibility", "")) == "semi_public":
				return edge.duplicate(true)
	return {}


func _find_relationship_article(relationship_event_id: String) -> Dictionary:
	var snapshot: Dictionary = GameManager.get_news_snapshot(4)
	for feed_value in snapshot.get("feeds", {}).values():
		if typeof(feed_value) != TYPE_DICTIONARY:
			continue
		var feed: Dictionary = feed_value
		for article_value in feed.get("articles", []):
			if typeof(article_value) != TYPE_DICTIONARY:
				continue
			var article: Dictionary = article_value
			if str(article.get("source_system_id", "")) == COMPANY_RELATIONSHIP_GRAPH_SYSTEM.SOURCE_SYSTEM_ID and str(article.get("relationship_event_id", "")) == relationship_event_id:
				return article.duplicate(true)
	return {}


func _find_relationship_post(relationship_event_id: String) -> Dictionary:
	var snapshot: Dictionary = GameManager.get_twooter_snapshot(4)
	for post_value in snapshot.get("posts", []):
		if typeof(post_value) != TYPE_DICTIONARY:
			continue
		var post: Dictionary = post_value
		if str(post.get("source_system_id", "")) == COMPANY_RELATIONSHIP_GRAPH_SYSTEM.SOURCE_SYSTEM_ID and str(post.get("relationship_event_id", "")) == relationship_event_id:
			return post.duplicate(true)
	return {}


func _seed_network_contact(company_id: String) -> void:
	var contacts: Dictionary = RunState.get_network_contacts()
	contacts[NETWORK_CONTACT_ID] = {
		"contact_id": NETWORK_CONTACT_ID,
		"met": true,
		"relationship": 50,
		"met_day_index": RunState.day_index,
		"last_source_type": "relationship_content_test"
	}
	RunState.set_network_contacts(contacts)
	var discoveries: Dictionary = RunState.get_network_discoveries()
	discoveries[NETWORK_CONTACT_ID] = {
		"contact_id": NETWORK_CONTACT_ID,
		"discovered": true,
		"source_type": "relationship_content_test",
		"source_id": "relationship_graph_event",
		"target_company_id": company_id,
		"target_company_ids": [company_id],
		"lead_score": 100,
		"day_index": RunState.day_index
	}
	RunState.set_network_discoveries(discoveries)


func _validate_generated_surface(label: String, row: Dictionary, issues: Array[String]) -> void:
	if not bool(row.get("generated_content_surface", false)):
		issues.append("%s_not_generated" % label)
	if str(row.get("source_system_id", "")) != COMPANY_RELATIONSHIP_GRAPH_SYSTEM.SOURCE_SYSTEM_ID:
		issues.append("%s_bad_source_system" % label)
	if str(row.get("generated_scope_id", "")) != "relationship":
		issues.append("%s_bad_scope" % label)
	if _string_array(row.get("source_fact_ids", [])).is_empty():
		issues.append("%s_missing_fact_ids" % label)
	if _string_array(row.get("source_clue_ids", [])).is_empty():
		issues.append("%s_missing_clue_ids" % label)
	if _visible_copy_leaks_hidden_terms(row):
		issues.append("%s_visible_hidden_leak" % label)


func _validate_network_result(result: Dictionary, issues: Array[String]) -> void:
	if not bool(result.get("success", false)):
		issues.append("network_result_failed:%s" % str(result.get("message", "")))
		return
	_validate_generated_surface("network", result, issues)
	if str(result.get("generated_surface_id", "")) != "network":
		issues.append("network_bad_surface")
	if str(result.get("visibility", "")) != "private":
		issues.append("network_bad_visibility")


func _capture_and_validate(label: String, source_row: Dictionary, company_id: String, issues: Array[String]) -> void:
	var payload: Dictionary = source_row.duplicate(true)
	payload["company_id"] = company_id
	payload["category"] = _capture_category(label)
	payload["source_type"] = "relationship_%s" % label
	payload["source_label"] = "Relationship %s" % label.capitalize()
	payload["source_id"] = "relationship_%s_%s" % [label, _token(str(source_row.get("id", source_row.get("story_id", ""))))]
	if str(payload.get("label", "")).is_empty():
		payload["label"] = _surface_label(label, source_row)
	if str(payload.get("summary", "")).is_empty():
		payload["summary"] = _surface_summary(source_row)
	payload["value"] = str(payload.get("label", ""))
	payload["detail"] = str(payload.get("summary", ""))
	payload["impact"] = "mixed"
	var capture_result: Dictionary = GameManager.capture_research_evidence(payload)
	if not bool(capture_result.get("success", false)):
		issues.append("%s_capture_failed:%s" % [label, str(capture_result.get("message", ""))])
		return
	var evidence: Dictionary = capture_result.get("evidence", {})
	if str(evidence.get("source_system_id", "")) != COMPANY_RELATIONSHIP_GRAPH_SYSTEM.SOURCE_SYSTEM_ID:
		issues.append("%s_capture_bad_source_system" % label)
	if str(evidence.get("generated_scope_id", "")) != "relationship":
		issues.append("%s_capture_bad_scope" % label)
	if _string_array(evidence.get("source_fact_ids", [])).is_empty():
		issues.append("%s_capture_missing_fact_ids" % label)
	if _string_array(evidence.get("source_clue_ids", [])).is_empty():
		issues.append("%s_capture_missing_clue_ids" % label)


func _surface_label(label: String, row: Dictionary) -> String:
	if label == "news":
		return str(row.get("headline", "Relationship news"))
	if label == "twooter":
		return str(row.get("post_text", "Relationship Twooter"))
	return str(row.get("message", "Relationship network read"))


func _surface_summary(row: Dictionary) -> String:
	for key in ["deck", "post_text", "public_tip_read", "message", "description"]:
		var value: String = str(row.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	return "Relationship content surface."


func _capture_category(label: String) -> String:
	if label == "news":
		return "news"
	if label == "twooter":
		return "twooter"
	return "network_intel"


func _token(value: String) -> String:
	var cleaned: String = value.strip_edges().to_lower()
	var result: String = ""
	for index in range(cleaned.length()):
		var character: String = cleaned.substr(index, 1)
		if character.is_valid_identifier() or character.is_valid_int():
			result += character
		else:
			result += "_"
	while result.contains("__"):
		result = result.replace("__", "_")
	return result.strip_edges().trim_prefix("_").trim_suffix("_")


func _visible_copy_leaks_hidden_terms(row: Dictionary) -> bool:
	var visible_text: String = " ".join([
		str(row.get("headline", "")),
		str(row.get("deck", "")),
		str(row.get("body", "")),
		str(row.get("post_text", "")),
		str(row.get("message", "")),
		str(row.get("public_tip_read", ""))
	]).to_lower()
	for term in ["relationship_edge:", "relationship_event:", "relationship_edge_id", "truth_state", "source_quality", "clue|", "fact|", "story|"]:
		if visible_text.contains(term):
			return true
	return false


func _string_array(source_value: Variant) -> Array:
	var source_array: Array = source_value if typeof(source_value) == TYPE_ARRAY else [source_value]
	var result: Array = []
	for item_value in source_array:
		var item: String = str(item_value).strip_edges()
		if item.is_empty() or result.has(item):
			continue
		result.append(item)
	return result


func _fail(message: String) -> void:
	push_error(message)
	print("COMPANY_RELATIONSHIP_CONTENT_HOOKS_FAIL %s" % message)
	get_tree().quit(1)
