extends RefCounted

const MAX_EVENT_LOOKBACK := 20
const MAX_RECENT_POSTS_PER_SOURCE := 2


func build_social_snapshot(
	_run_state,
	feed_data: Dictionary,
	company_rows: Array,
	market_history: Array,
	event_history: Array,
	active_special_events: Array,
	active_company_arcs: Array,
	current_trade_date: Dictionary,
	unlocked_access_tier: int = -1
) -> Dictionary:
	var accounts: Array = feed_data.get("accounts", []).duplicate(true)
	var resolved_access_tier: int = unlocked_access_tier
	if resolved_access_tier < 1:
		resolved_access_tier = int(feed_data.get("prototype_default_access_tier", 4))
	resolved_access_tier = clamp(resolved_access_tier, 1, 4)

	var unlocked_accounts: Array = []
	var all_accounts: Array = []
	for account_value in accounts:
		var account: Dictionary = account_value.duplicate(true)
		var tier: int = int(account.get("tier", 1))
		account["unlocked"] = tier <= resolved_access_tier
		all_accounts.append(account)
		if tier <= resolved_access_tier:
			unlocked_accounts.append(account)

	var company_row_lookup: Dictionary = {}
	for row_value in company_rows:
		var row: Dictionary = row_value
		company_row_lookup[str(row.get("id", ""))] = row.duplicate(true)
	var current_day_index: int = int(current_trade_date.get("day_index", current_trade_date.get("day", 0)))
	var story_memory: Dictionary = _build_story_memory(event_history, active_company_arcs, current_day_index)

	var posts: Array = []
	var seen_ids: Dictionary = {}
	for post_value in _build_hidden_arc_posts(feed_data, unlocked_accounts, company_row_lookup, active_company_arcs, current_trade_date, story_memory):
		_append_unique_post(posts, seen_ids, post_value)
	for post_value in _build_active_special_posts(feed_data, unlocked_accounts, active_special_events, current_trade_date, story_memory):
		_append_unique_post(posts, seen_ids, post_value)
	for post_value in _build_recent_event_posts(feed_data, unlocked_accounts, company_row_lookup, event_history, current_trade_date, story_memory):
		_append_unique_post(posts, seen_ids, post_value)

	var market_wrap_post: Dictionary = _build_market_wrap_post(feed_data, unlocked_accounts, market_history, current_trade_date, story_memory)
	if not market_wrap_post.is_empty():
		_append_unique_post(posts, seen_ids, market_wrap_post)

	if posts.is_empty():
		var fallback_post: Dictionary = _build_fallback_post(feed_data, unlocked_accounts, current_trade_date)
		if not fallback_post.is_empty():
			_append_unique_post(posts, seen_ids, fallback_post)

	posts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a.get("priority", 0.0)) == float(b.get("priority", 0.0)):
			if int(a.get("day_index", -1)) == int(b.get("day_index", -1)):
				return str(a.get("account_handle", "")) < str(b.get("account_handle", ""))
			return int(a.get("day_index", -1)) > int(b.get("day_index", -1))
		return float(a.get("priority", 0.0)) > float(b.get("priority", 0.0))
	)
	var post_limit: int = int(feed_data.get("post_limit", 18))
	if posts.size() > post_limit:
		posts = posts.slice(0, post_limit)

	return {
		"access_tier": resolved_access_tier,
		"tier_label": str(feed_data.get("tier_labels", {}).get(str(resolved_access_tier), "Tier %d" % resolved_access_tier)),
		"accounts": all_accounts,
		"posts": posts
	}


func _build_hidden_arc_posts(
	feed_data: Dictionary,
	unlocked_accounts: Array,
	company_row_lookup: Dictionary,
	active_company_arcs: Array,
	current_trade_date: Dictionary,
	story_memory: Dictionary
) -> Array:
	var posts: Array = []
	for arc_value in active_company_arcs:
		var arc: Dictionary = arc_value
		if str(arc.get("phase_visibility", "visible")) != "hidden":
			continue

		var account: Dictionary = _pick_generic_account(unlocked_accounts, 3, "hidden|%s" % str(arc.get("arc_id", "")))
		if account.is_empty():
			continue

		var company_id: String = str(arc.get("target_company_id", ""))
		var row: Dictionary = company_row_lookup.get(company_id, {})
		var context: Dictionary = _build_context(feed_data, arc, row, current_trade_date, story_memory)
		var post_text: String = _pick_voice_text(
			feed_data,
			str(account.get("voice", "")),
			"hidden_company",
			"hidden|%s" % company_id,
			context
		)
		posts.append(_build_post(
			feed_data,
			account,
			"hidden_arc|%s" % str(arc.get("arc_id", "")),
			post_text,
			arc,
			current_trade_date,
			context,
			"Early chatter",
			3.8
		))

	return posts


func _build_active_special_posts(
	feed_data: Dictionary,
	unlocked_accounts: Array,
	active_special_events: Array,
	current_trade_date: Dictionary,
	story_memory: Dictionary
) -> Array:
	var posts: Array = []
	var current_day_index: int = int(current_trade_date.get("day_index", current_trade_date.get("day", 0)))
	for event_value in active_special_events:
		var event_data: Dictionary = event_value
		var start_day_index: int = int(event_data.get("start_day_index", current_day_index))
		var duration_days: int = max(int(event_data.get("duration_days", 1)), 1)
		var elapsed_days: int = max(current_day_index - start_day_index + 1, 1)
		var progress_ratio: float = clamp(float(elapsed_days) / float(duration_days), 0.0, 1.0)
		var minimum_tier: int = _required_tier_for_progress(progress_ratio)
		var account: Dictionary = _pick_generic_account(unlocked_accounts, minimum_tier, "special|%s|%s" % [str(event_data.get("event_id", "")), start_day_index])
		if account.is_empty():
			continue

		var context: Dictionary = _build_context(feed_data, event_data, {}, current_trade_date, story_memory)
		var text_key: String = _scope_voice_key(event_data)
		var post_text: String = _pick_voice_text(
			feed_data,
			str(account.get("voice", "")),
			text_key,
			"special|%s|%s" % [str(event_data.get("event_id", "")), start_day_index],
			context
		)
		posts.append(_build_post(
			feed_data,
			account,
			"active_special|%s|%s" % [str(event_data.get("event_id", "")), start_day_index],
			post_text,
			event_data,
			current_trade_date,
			context,
			_progress_label_for_ratio(progress_ratio),
			3.2 + (1.0 - progress_ratio)
		))

	return posts


func _build_recent_event_posts(
	feed_data: Dictionary,
	unlocked_accounts: Array,
	company_row_lookup: Dictionary,
	event_history: Array,
	current_trade_date: Dictionary,
	story_memory: Dictionary
) -> Array:
	var posts: Array = []
	var recent_history: Array = event_history.duplicate(true)
	recent_history.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("day_index", -1)) > int(b.get("day_index", -1))
	)
	if recent_history.size() > MAX_EVENT_LOOKBACK:
		recent_history = recent_history.slice(0, MAX_EVENT_LOOKBACK)

	var current_day_index: int = int(current_trade_date.get("day_index", current_trade_date.get("day", 0)))
	var source_counts: Dictionary = {}
	for event_value in recent_history:
		var event_data: Dictionary = event_value
		var source_key: String = str(event_data.get("event_id", "")) + "|" + str(event_data.get("target_company_id", ""))
		source_counts[source_key] = int(source_counts.get(source_key, 0))
		if int(source_counts.get(source_key, 0)) >= MAX_RECENT_POSTS_PER_SOURCE:
			continue

		var age_days: int = max(current_day_index - int(event_data.get("day_index", current_day_index)), 0)
		var company_id: String = str(event_data.get("target_company_id", ""))
		var row: Dictionary = company_row_lookup.get(company_id, {})
		var context: Dictionary = _build_context(feed_data, event_data, row, current_trade_date, story_memory)
		var post: Dictionary = {}

		if str(event_data.get("event_family", "")) == "person":
			post = _build_persona_post(feed_data, unlocked_accounts, event_data, current_trade_date, context)
		if post.is_empty():
			var minimum_tier: int = _required_tier_for_event_age(age_days)
			var account: Dictionary = _pick_generic_account(unlocked_accounts, minimum_tier, "event|%s|%s" % [str(event_data.get("event_id", "")), company_id])
			if account.is_empty():
				continue
			var text_key: String = _voice_key_for_event(event_data)
			var post_text: String = _pick_voice_text(
				feed_data,
				str(account.get("voice", "")),
				text_key,
				"event|%s|%s|%s" % [str(event_data.get("event_id", "")), company_id, age_days],
				context
			)
			post = _build_post(
				feed_data,
				account,
				"event|%s|%s|%s" % [str(event_data.get("event_id", "")), int(event_data.get("day_index", -1)), company_id],
				post_text,
				event_data,
				current_trade_date,
				context,
				_visibility_label_for_age(age_days),
				2.4 - min(float(age_days) * 0.08, 1.0)
			)

		if not post.is_empty():
			source_counts[source_key] = int(source_counts.get(source_key, 0)) + 1
			posts.append(post)

	return posts


func _build_persona_post(
	feed_data: Dictionary,
	unlocked_accounts: Array,
	event_data: Dictionary,
	current_trade_date: Dictionary,
	context: Dictionary
) -> Dictionary:
	var person_id: String = str(event_data.get("person_id", ""))
	if person_id.is_empty():
		return {}

	for account_value in unlocked_accounts:
		var account: Dictionary = account_value
		if str(account.get("person_id", "")) != person_id:
			continue
		var text_key: String = "person_%s" % str(event_data.get("tone", "mixed"))
		var post_text: String = _pick_voice_text(
			feed_data,
			str(account.get("voice", "")),
			text_key,
			"persona|%s|%s" % [person_id, str(event_data.get("event_id", ""))],
			context
		)
		return _build_post(
			feed_data,
			account,
			"persona|%s|%s|%s" % [person_id, str(event_data.get("event_id", "")), int(event_data.get("day_index", -1))],
			post_text,
			event_data,
			current_trade_date,
			context,
			"Direct post",
			4.4
		)
	return {}


func _build_market_wrap_post(
	feed_data: Dictionary,
	unlocked_accounts: Array,
	market_history: Array,
	current_trade_date: Dictionary,
	story_memory: Dictionary
) -> Dictionary:
	if market_history.is_empty():
		return {}
	var account: Dictionary = _pick_generic_account(unlocked_accounts, 1, "market_wrap")
	if account.is_empty():
		return {}

	var latest_entry: Dictionary = market_history[market_history.size() - 1]
	var market_wrap_source: Dictionary = latest_entry.duplicate(true)
	market_wrap_source["scope"] = "market"
	market_wrap_source["category"] = "market_wrap"
	market_wrap_source["event_family"] = "market"
	market_wrap_source["tone"] = _tone_from_change(float(latest_entry.get("average_change_pct", 0.0)))
	var biggest_winner: Dictionary = latest_entry.get("biggest_winner", {})
	var biggest_loser: Dictionary = latest_entry.get("biggest_loser", {})
	var context: Dictionary = {
		"market_change": _format_percent(float(latest_entry.get("average_change_pct", 0.0))),
		"advancers": str(int(latest_entry.get("advancers", 0))),
		"decliners": str(int(latest_entry.get("decliners", 0))),
		"biggest_winner": str(biggest_winner.get("ticker", "leader")),
		"biggest_loser": str(biggest_loser.get("ticker", "laggard")),
		"sector_name": "the board",
		"target_ticker": "",
		"target_company_name": "",
		"person_name": ""
	}
	context["tone"] = _tone_from_change(float(latest_entry.get("average_change_pct", 0.0)))
	context["public_topic_label"] = "Market breadth"
	context["public_confidence_label"] = "Closing tape"
	context["public_continuity_phrase"] = ""
	context["public_context_hint"] = ""
	var post_text: String = _pick_voice_text(
		feed_data,
		str(account.get("voice", "")),
		"market_wrap",
		"market_wrap",
		context
	)
	return _build_post(
		feed_data,
		account,
		"market_wrap|%s" % int(latest_entry.get("day_index", -1)),
		post_text,
		market_wrap_source,
		current_trade_date,
		context,
		"Closing tape",
		1.2
	)


func _build_fallback_post(feed_data: Dictionary, unlocked_accounts: Array, current_trade_date: Dictionary) -> Dictionary:
	var account: Dictionary = _pick_generic_account(unlocked_accounts, 1, "fallback")
	if account.is_empty():
		return {}
	var post_text: String = str(_pick_from_pool(feed_data.get("fallback_posts", {}).get("all", []), "fallback"))
	return _build_post(
		feed_data,
		account,
		"fallback|%s" % int(current_trade_date.get("day_index", 0)),
		post_text,
		{},
		current_trade_date,
		{},
		"Watching",
		0.5
	)


func _build_post(
	feed_data: Dictionary,
	account: Dictionary,
	post_id: String,
	post_text: String,
	source_data: Dictionary,
	current_trade_date: Dictionary,
	context: Dictionary,
	visibility_label: String,
	priority: float
) -> Dictionary:
	var reactions: Dictionary = _build_reactions(post_id, int(account.get("tier", 1)))
	var thread_lines: Array = _build_thread_lines(feed_data, account, source_data, context, post_id)
	return {
		"id": post_id,
		"account_id": str(account.get("id", "")),
		"account_name": str(account.get("display_name", "")),
		"account_handle": str(account.get("handle", "")),
		"account_tier": int(account.get("tier", 1)),
		"account_verified": bool(account.get("verified", false)),
		"post_text": post_text,
		"visibility_label": visibility_label,
		"day_index": int(source_data.get("day_index", current_trade_date.get("day_index", -1))),
		"trade_date": source_data.get("trade_date", current_trade_date).duplicate(true),
		"tone": str(source_data.get("tone", context.get("tone", "mixed"))),
		"category": str(source_data.get("category", "")),
		"event_family": str(source_data.get("event_family", "")),
		"source_chain_id": str(source_data.get("source_chain_id", "")),
		"chain_family": str(source_data.get("chain_family", "")),
		"meeting_id": str(source_data.get("meeting_id", "")),
		"venue_type": str(source_data.get("venue_type", "")),
		"target_ticker": str(context.get("target_ticker", "")),
		"target_company_name": str(context.get("target_company_name", "")),
		"sector_name": str(context.get("sector_name", "")),
		"person_name": str(context.get("person_name", "")),
		"context_hint": str(context.get("public_context_hint", "")),
		"public_topic_label": str(context.get("public_topic_label", "")),
		"public_confidence_label": str(context.get("public_confidence_label", "")),
		"public_continuity_phrase": str(context.get("public_continuity_phrase", "")),
		"thread_lines": thread_lines,
		"likes": int(reactions.get("likes", 0)),
		"replies": int(reactions.get("replies", 0)),
		"retwoots": int(reactions.get("retwoots", 0)),
		"priority": priority
	}


func _build_context(feed_data: Dictionary, source_data: Dictionary, company_row: Dictionary, current_trade_date: Dictionary, story_memory: Dictionary) -> Dictionary:
	var target_sector_id: String = str(source_data.get("target_sector_id", company_row.get("sector_id", "")))
	var sector_definition: Dictionary = DataRepository.get_sector_definition(target_sector_id)
	var current_day_index: int = int(current_trade_date.get("day_index", current_trade_date.get("day", 0)))
	var article_day_index: int = int(source_data.get("day_index", current_day_index))
	var continuity_phrase: String = _continuity_phrase_for_source(feed_data, source_data, article_day_index, story_memory)
	var category: String = str(source_data.get("category", ""))
	var tone: String = str(source_data.get("tone", "mixed"))
	return {
		"target_ticker": str(source_data.get("target_ticker", company_row.get("ticker", ""))),
		"target_company_name": str(source_data.get("target_company_name", company_row.get("name", ""))),
		"sector_name": str(source_data.get("sector_name", company_row.get("sector_name", sector_definition.get("name", "the sector")))),
		"person_name": str(source_data.get("person_name", "")),
		"description": str(source_data.get("description", "")),
		"tone": tone,
		"category": category,
		"public_topic_label": _public_topic_label(source_data),
		"public_confidence_label": _public_confidence_label(source_data),
		"public_continuity_phrase": continuity_phrase,
		"continuity_phrase": continuity_phrase,
		"public_context_hint": _public_context_hint(source_data, continuity_phrase)
	}


func _build_thread_lines(feed_data: Dictionary, account: Dictionary, source_data: Dictionary, context: Dictionary, post_id: String) -> Array:
	if not bool(account.get("thread_preference", false)):
		return []
	var thread_templates: Dictionary = feed_data.get("thread_templates", {})
	var voice_id: String = str(account.get("voice", ""))
	var voice_templates: Dictionary = thread_templates.get(voice_id, {})
	if voice_templates.is_empty():
		return []
	var pool: Array = []
	for key_value in _template_lookup_keys(source_data, context):
		var key: String = str(key_value)
		pool = voice_templates.get(key, [])
		if not pool.is_empty():
			break
	if pool.is_empty():
		return []
	var rendered_lines: Array = []
	for line_value in pool:
		var rendered_line: String = _render_template(str(line_value), context).strip_edges()
		if not rendered_line.is_empty():
			rendered_lines.append(rendered_line)
	return rendered_lines


func _build_story_memory(event_history: Array, active_company_arcs: Array, current_day_index: int) -> Dictionary:
	var memory: Dictionary = {}
	for event_value in event_history:
		var event_data: Dictionary = event_value
		_record_story_memory_entry(memory, event_data, current_day_index)
	for arc_value in active_company_arcs:
		var arc: Dictionary = arc_value
		_record_story_memory_entry(memory, arc, current_day_index)
	return memory


func _record_story_memory_entry(memory: Dictionary, source_data: Dictionary, current_day_index: int) -> void:
	var day_index: int = int(source_data.get("day_index", current_day_index))
	if day_index < 0 or day_index > current_day_index:
		return
	var entry: Dictionary = {
		"day_index": day_index,
		"category": str(source_data.get("category", "")),
		"target_company_id": str(source_data.get("target_company_id", "")),
		"source_chain_id": str(source_data.get("source_chain_id", "")),
		"label": _memory_label(source_data)
	}
	for key_value in _story_memory_keys(source_data):
		var key: String = str(key_value)
		if key.is_empty():
			continue
		var entries: Array = memory.get(key, []).duplicate(true)
		entries.append(entry.duplicate(true))
		entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("day_index", -1)) > int(b.get("day_index", -1))
		)
		if entries.size() > 4:
			entries = entries.slice(0, 4)
		memory[key] = entries


func _story_memory_keys(source_data: Dictionary) -> Array:
	var keys: Array = []
	var chain_id: String = str(source_data.get("source_chain_id", ""))
	if chain_id.is_empty():
		chain_id = str(source_data.get("arc_id", ""))
	if not chain_id.is_empty():
		keys.append("chain|%s" % chain_id)
	var company_id: String = str(source_data.get("target_company_id", source_data.get("company_id", "")))
	if not company_id.is_empty():
		keys.append("company|%s|%s" % [company_id, _category_family_key(source_data)])
		keys.append("company|%s" % company_id)
	var sector_id: String = str(source_data.get("target_sector_id", ""))
	if not sector_id.is_empty():
		keys.append("sector|%s|%s" % [sector_id, _category_family_key(source_data)])
	return keys


func _continuity_phrase_for_source(feed_data: Dictionary, source_data: Dictionary, post_day_index: int, story_memory: Dictionary) -> String:
	if post_day_index < 0:
		return ""
	var best_entry: Dictionary = {}
	for key_value in _story_memory_keys(source_data):
		var entries: Array = story_memory.get(str(key_value), [])
		for entry_value in entries:
			var entry: Dictionary = entry_value
			var prior_day_index: int = int(entry.get("day_index", -1))
			if prior_day_index < 0 or prior_day_index >= post_day_index:
				continue
			if best_entry.is_empty() or prior_day_index > int(best_entry.get("day_index", -1)):
				best_entry = entry.duplicate(true)
	if best_entry.is_empty():
		return ""
	var category: String = str(source_data.get("category", ""))
	var continuity_templates: Dictionary = feed_data.get("continuity_templates", {})
	var pool: Array = continuity_templates.get(category, [])
	if pool.is_empty():
		pool = continuity_templates.get("fallback", [])
	if not pool.is_empty():
		return str(_pick_from_pool(pool, "%s|%s" % [str(source_data.get("source_chain_id", "")), post_day_index]))
	var age_days: int = max(post_day_index - int(best_entry.get("day_index", post_day_index)), 1)
	if age_days == 1:
		return "This follows yesterday's %s." % str(best_entry.get("label", "related post"))
	return "This follows a recent %s." % str(best_entry.get("label", "related post"))


func _template_lookup_keys(source_data: Dictionary, context: Dictionary) -> Array:
	var category: String = str(source_data.get("category", ""))
	var tone: String = str(source_data.get("tone", context.get("tone", "mixed")))
	var scope: String = str(source_data.get("scope", "company"))
	var keys: Array = []
	if not category.is_empty():
		keys.append(category)
	if category.begins_with("corporate_action"):
		keys.append("corporate_action")
	if category == "corporate_meeting":
		keys.append("corporate_meeting")
	if scope == "market":
		keys.append("market_%s" % tone)
		keys.append("market_wrap")
	elif scope == "sector":
		keys.append("sector_%s" % tone)
	else:
		keys.append("company_%s" % tone)
	keys.append(_category_family_key(source_data))
	return keys


func _category_family_key(source_data: Dictionary) -> String:
	var category: String = str(source_data.get("category", ""))
	if category.begins_with("corporate_action"):
		return "corporate_action"
	if category == "corporate_meeting":
		return "corporate_meeting"
	if category in ["earnings", "management", "market_wrap"]:
		return category
	if category.contains("commodity"):
		return "commodity"
	if str(source_data.get("scope", "")) == "market":
		return "market_wrap"
	return "company"


func _public_topic_label(source_data: Dictionary) -> String:
	var category: String = str(source_data.get("category", ""))
	if category.begins_with("corporate_action"):
		return "Corporate action"
	if category == "corporate_meeting":
		return "RUPSLB watch"
	if category == "earnings":
		return "Earnings"
	if category == "management":
		return "Management"
	if category.contains("commodity"):
		return "Commodity"
	if str(source_data.get("scope", "")) == "market" or category == "market_wrap":
		return "IHSG tape"
	if str(source_data.get("scope", "")) == "sector":
		return "Sector watch"
	return "Emiten watch"


func _public_confidence_label(source_data: Dictionary) -> String:
	var category: String = str(source_data.get("category", ""))
	if category in ["corporate_action_filing", "corporate_action_resolution", "corporate_action_execution"]:
		return "Paperwork"
	if category == "corporate_meeting":
		return "Calendar"
	if category == "corporate_action_rumor":
		return "Rumor"
	if category == "corporate_action_denial" or category == "corporate_action_clarification":
		return "Company response"
	if category == "market_wrap":
		return "Close read"
	return "Feed read"


func _public_context_hint(source_data: Dictionary, continuity_phrase: String) -> String:
	if not continuity_phrase.is_empty():
		return continuity_phrase
	var summary: String = str(source_data.get("summary", source_data.get("headline_detail", source_data.get("description", "")))).strip_edges()
	if _looks_like_system_summary(summary):
		return ""
	return summary


func _looks_like_system_summary(value: String) -> bool:
	var lowered_value: String = value.to_lower()
	return (
		lowered_value.contains("source_chain_id") or
		lowered_value.contains("chain_family") or
		lowered_value.contains("meeting_id") or
		lowered_value.contains("venue_type") or
		lowered_value.contains("current_timeline_state") or
		lowered_value.contains("management stance") or
		lowered_value.contains("hidden_positioning") or
		lowered_value.contains("formal_agenda_or_filing") or
		lowered_value.contains("meeting_or_call")
	)


func _memory_label(source_data: Dictionary) -> String:
	var category: String = str(source_data.get("category", ""))
	if category == "corporate_action_denial":
		return "denial"
	if category == "corporate_action_filing":
		return "formal notice"
	if category == "corporate_meeting":
		return "meeting watch"
	if category == "corporate_action_rumor":
		return "rumor"
	return "related post"


func _pick_generic_account(unlocked_accounts: Array, minimum_tier: int, seed_key: String) -> Dictionary:
	var candidates: Array = []
	for account_value in unlocked_accounts:
		var account: Dictionary = account_value
		if str(account.get("person_id", "")).is_empty() and int(account.get("tier", 1)) >= minimum_tier:
			candidates.append(account)
	if candidates.is_empty():
		return {}
	var preferred_voice: String = _preferred_voice_for_seed(seed_key)
	if not preferred_voice.is_empty():
		for candidate_value in candidates:
			var candidate: Dictionary = candidate_value
			if str(candidate.get("voice", "")) == preferred_voice:
				return candidate
	var index: int = int(abs(hash(seed_key))) % candidates.size()
	return candidates[index]


func _preferred_voice_for_seed(seed_key: String) -> String:
	if seed_key == "market_wrap" or seed_key.begins_with("fallback"):
		return "market_diary"
	if seed_key.contains("rights_issue") or seed_key.contains("corporate_action"):
		return "funda_thread"
	if seed_key.contains("earnings"):
		return "quality_hold"
	if seed_key.contains("commodity") or seed_key.contains("geopolitical"):
		return "sector_classroom"
	return ""


func _voice_key_for_event(event_data: Dictionary) -> String:
	var event_family: String = str(event_data.get("event_family", ""))
	var category: String = str(event_data.get("category", ""))
	if event_family == "corporate_action" and not category.is_empty():
		return category
	var scope: String = str(event_data.get("scope", "company"))
	var tone: String = str(event_data.get("tone", "mixed"))
	if scope == "market":
		return "market_%s" % tone
	if scope == "sector":
		return "sector_%s" % tone
	return "company_%s" % tone


func _scope_voice_key(event_data: Dictionary) -> String:
	var event_family: String = str(event_data.get("event_family", ""))
	var category: String = str(event_data.get("category", ""))
	if event_family == "corporate_action" and not category.is_empty():
		return category
	var scope: String = str(event_data.get("scope", "company"))
	var tone: String = str(event_data.get("tone", "mixed"))
	if scope == "market":
		return "market_%s" % tone
	if scope == "sector":
		return "sector_%s" % tone
	return "company_%s" % tone


func _pick_voice_text(feed_data: Dictionary, voice_id: String, text_key: String, seed_key: String, context: Dictionary) -> String:
	var voice_templates: Dictionary = feed_data.get("voice_templates", {})
	var voice_pool: Array = voice_templates.get(voice_id, {}).get(text_key, [])
	if voice_pool.is_empty() and text_key.begins_with("corporate_action"):
		voice_pool = voice_templates.get(voice_id, {}).get("corporate_action", [])
	if voice_pool.is_empty() and text_key == "corporate_meeting":
		voice_pool = voice_templates.get(voice_id, {}).get("corporate_meeting", [])
	if voice_pool.is_empty():
		if text_key != "market_wrap":
			var tone_key: String = "company_%s" % str(context.get("tone", "positive"))
			voice_pool = voice_templates.get(voice_id, {}).get(tone_key, [])
			if voice_pool.is_empty():
				voice_pool = voice_templates.get(voice_id, {}).get("company_positive", [])
		if voice_pool.is_empty():
			return ""
	return _render_template(_pick_from_pool(voice_pool, seed_key), context)


func _pick_from_pool(pool: Array, seed_key: String) -> String:
	if pool.is_empty():
		return ""
	var pool_index: int = int(abs(hash(seed_key))) % pool.size()
	return str(pool[pool_index])


func _render_template(template: String, context: Dictionary) -> String:
	var rendered: String = template
	for context_key in context.keys():
		rendered = rendered.replace("{%s}" % str(context_key), str(context.get(context_key, "")))
	return rendered


func _append_unique_post(posts: Array, seen_ids: Dictionary, post: Dictionary) -> void:
	if post.is_empty():
		return
	var post_id: String = str(post.get("id", ""))
	if post_id.is_empty() or seen_ids.has(post_id):
		return
	seen_ids[post_id] = true
	posts.append(post)


func _required_tier_for_progress(progress_ratio: float) -> int:
	if progress_ratio <= 0.28:
		return 3
	if progress_ratio <= 0.72:
		return 2
	return 1


func _required_tier_for_event_age(age_days: int) -> int:
	if age_days <= 0:
		return 3
	if age_days <= 2:
		return 2
	return 1


func _progress_label_for_ratio(progress_ratio: float) -> String:
	if progress_ratio <= 0.28:
		return "Early chatter"
	if progress_ratio <= 0.72:
		return "On feed"
	return "After move"


func _visibility_label_for_age(age_days: int) -> String:
	if age_days <= 0:
		return "Fresh"
	if age_days <= 2:
		return "Still moving"
	return "After move"


func _build_reactions(post_id: String, account_tier: int) -> Dictionary:
	var seed_value: int = int(abs(hash(post_id)))
	var base_likes: int = 60 + int(seed_value % 420)
	var base_replies: int = 6 + int(floor(float(seed_value) / 7.0)) % 54
	var base_retwoots: int = 4 + int(floor(float(seed_value) / 13.0)) % 48
	return {
		"likes": base_likes * account_tier,
		"replies": base_replies * account_tier,
		"retwoots": base_retwoots * account_tier
	}


func _format_percent(value: float) -> String:
	return "%+.2f%%" % (value * 100.0)


func _tone_from_change(change_pct: float) -> String:
	if change_pct > 0.002:
		return "positive"
	if change_pct < -0.002:
		return "negative"
	return "mixed"
