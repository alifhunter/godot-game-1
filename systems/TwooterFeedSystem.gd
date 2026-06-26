extends RefCounted

const MAX_EVENT_LOOKBACK := 20
const MAX_RECENT_POSTS_PER_SOURCE := 2
const MAX_GENERATED_DOSSIER_TWOOTER_SOURCES := 6
const MAX_GENERATED_DOSSIER_TWOOTER_POSTS := 5
const GENERATED_DOSSIER_TWOOTER_SOURCE_SYSTEM_ID := "company_story_dossier"
const RELATIONSHIP_GRAPH_SOURCE_SYSTEM_ID := "company_relationship_graph"


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
	var latest_market_entry: Dictionary = _latest_market_entry(market_history)
	var generated_twooter_sources: Array = _build_generated_dossier_twooter_sources(
		_run_state,
		company_row_lookup,
		current_trade_date,
		current_day_index
	)

	var posts: Array = []
	var seen_ids: Dictionary = {}
	for post_value in _build_hidden_arc_posts(feed_data, unlocked_accounts, company_row_lookup, active_company_arcs, current_trade_date, story_memory):
		_append_unique_post(posts, seen_ids, post_value)
	for post_value in _build_active_special_posts(feed_data, unlocked_accounts, active_special_events, current_trade_date, story_memory, latest_market_entry):
		_append_unique_post(posts, seen_ids, post_value)
	for post_value in _build_recent_event_posts(feed_data, unlocked_accounts, company_row_lookup, event_history, current_trade_date, story_memory, latest_market_entry):
		_append_unique_post(posts, seen_ids, post_value)
	for post_value in _build_generated_dossier_twooter_posts(feed_data, unlocked_accounts, company_row_lookup, generated_twooter_sources, current_trade_date, story_memory):
		_append_unique_post(posts, seen_ids, post_value)
	for post_value in _build_ambient_posts(feed_data, unlocked_accounts, company_rows, market_history, current_trade_date):
		_append_unique_post(posts, seen_ids, post_value)

	var market_wrap_post: Dictionary = _build_market_wrap_post(feed_data, unlocked_accounts, market_history, current_trade_date, story_memory)
	if not market_wrap_post.is_empty():
		_append_unique_post(posts, seen_ids, market_wrap_post)

	if posts.is_empty():
		var fallback_post: Dictionary = _build_fallback_post(feed_data, unlocked_accounts, current_trade_date)
		if not fallback_post.is_empty():
			_append_unique_post(posts, seen_ids, fallback_post)

	posts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("day_index", -1)) == int(b.get("day_index", -1)):
			if float(a.get("priority", 0.0)) == float(b.get("priority", 0.0)):
				return str(a.get("account_handle", "")) < str(b.get("account_handle", ""))
			return float(a.get("priority", 0.0)) > float(b.get("priority", 0.0))
		return int(a.get("day_index", -1)) > int(b.get("day_index", -1))
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


func count_social_posts(
	feed_data: Dictionary,
	market_history: Array,
	event_history: Array,
	active_special_events: Array,
	active_company_arcs: Array,
	current_trade_date: Dictionary,
	unlocked_access_tier: int = -1,
	company_rows: Array = []
) -> int:
	var snapshot: Dictionary = build_social_snapshot(
		null,
		feed_data,
		company_rows,
		market_history,
		event_history,
		active_special_events,
		active_company_arcs,
		current_trade_date,
		unlocked_access_tier
	)
	return int(snapshot.get("posts", []).size())


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
	story_memory: Dictionary,
	latest_market_entry: Dictionary = {}
) -> Array:
	var posts: Array = []
	var current_day_index: int = int(current_trade_date.get("day_index", current_trade_date.get("day", 0)))
	for event_value in active_special_events:
		var event_data: Dictionary = event_value
		var source_data: Dictionary = _source_with_market_context(event_data, latest_market_entry)
		var start_day_index: int = int(event_data.get("start_day_index", current_day_index))
		var duration_days: int = max(int(event_data.get("duration_days", 1)), 1)
		var elapsed_days: int = max(current_day_index - start_day_index + 1, 1)
		var progress_ratio: float = clamp(float(elapsed_days) / float(duration_days), 0.0, 1.0)
		if _is_policy_parody_source(event_data):
			for post_value in _build_policy_parody_account_posts(
				feed_data,
				unlocked_accounts,
				event_data,
				current_trade_date,
				story_memory,
				progress_ratio,
				start_day_index
			):
				posts.append(post_value)
			continue
		var minimum_tier: int = _required_tier_for_progress(progress_ratio)
		var account: Dictionary = _pick_generic_account(unlocked_accounts, minimum_tier, "special|%s|%s" % [str(event_data.get("event_id", "")), start_day_index])
		if account.is_empty():
			continue

		var context: Dictionary = _build_context(feed_data, source_data, {}, current_trade_date, story_memory)
		var text_key: String = _scope_voice_key(source_data)
		var post_text: String = _pick_voice_text(
			feed_data,
			str(account.get("voice", "")),
			text_key,
			"special|%s|%s" % [str(source_data.get("event_id", "")), start_day_index],
			context
		)
		posts.append(_build_post(
			feed_data,
			account,
			"active_special|%s|%s" % [str(source_data.get("event_id", "")), start_day_index],
			post_text,
			source_data,
			current_trade_date,
			context,
			_progress_label_for_ratio(progress_ratio),
			3.2 + (1.0 - progress_ratio)
		))

	return posts


func _build_policy_parody_account_posts(
	feed_data: Dictionary,
	unlocked_accounts: Array,
	event_data: Dictionary,
	current_trade_date: Dictionary,
	story_memory: Dictionary,
	progress_ratio: float,
	start_day_index: int
) -> Array:
	var posts: Array = []
	var sorted_accounts: Array = unlocked_accounts.duplicate(true)
	sorted_accounts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("tier", 1)) == int(b.get("tier", 1)):
			return str(a.get("id", "")) < str(b.get("id", ""))
		return int(a.get("tier", 1)) < int(b.get("tier", 1))
	)
	var context: Dictionary = _build_context(feed_data, event_data, {}, current_trade_date, story_memory)
	var text_key: String = _policy_parody_template_key(event_data)
	var account_index: int = 0
	for account_value in sorted_accounts:
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value
		var account_id: String = str(account.get("id", ""))
		if account_id.is_empty():
			continue
		var seed_key: String = "policy|%s|%s|%s" % [str(event_data.get("event_id", "")), start_day_index, account_id]
		var post_text: String = _pick_voice_text(
			feed_data,
			str(account.get("voice", "")),
			text_key,
			seed_key,
			context
		)
		posts.append(_build_post(
			feed_data,
			account,
			"active_special|%s|%s|%s" % [str(event_data.get("event_id", "")), start_day_index, account_id],
			post_text,
			event_data,
			current_trade_date,
			context,
			_progress_label_for_ratio(progress_ratio),
			4.7 + (1.0 - progress_ratio) - (float(account_index) * 0.01)
		))
		account_index += 1
	return posts


func _build_recent_event_posts(
	feed_data: Dictionary,
	unlocked_accounts: Array,
	company_row_lookup: Dictionary,
	event_history: Array,
	current_trade_date: Dictionary,
	story_memory: Dictionary,
	latest_market_entry: Dictionary = {}
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
		if str(event_data.get("event_family", "")) == RELATIONSHIP_GRAPH_SOURCE_SYSTEM_ID:
			var relationship_source_key: String = "relationship|%s" % str(event_data.get("relationship_event_id", event_data.get("event_id", "")))
			source_counts[relationship_source_key] = int(source_counts.get(relationship_source_key, 0))
			if int(source_counts.get(relationship_source_key, 0)) > 0:
				continue
			var relationship_post: Dictionary = _build_relationship_event_post(
				feed_data,
				unlocked_accounts,
				company_row_lookup,
				event_data,
				current_trade_date,
				current_day_index,
				story_memory,
				latest_market_entry
			)
			if not relationship_post.is_empty():
				source_counts[relationship_source_key] = int(source_counts.get(relationship_source_key, 0)) + 1
				posts.append(relationship_post)
			continue
		var source_data: Dictionary = _source_with_market_context(event_data, latest_market_entry)
		var source_key: String = str(source_data.get("event_id", "")) + "|" + str(source_data.get("target_company_id", ""))
		source_counts[source_key] = int(source_counts.get(source_key, 0))
		if int(source_counts.get(source_key, 0)) >= MAX_RECENT_POSTS_PER_SOURCE:
			continue

		var age_days: int = max(current_day_index - int(source_data.get("day_index", current_day_index)), 0)
		var company_id: String = str(source_data.get("target_company_id", ""))
		var row: Dictionary = company_row_lookup.get(company_id, {})
		var context: Dictionary = _build_context(feed_data, source_data, row, current_trade_date, story_memory)
		var post: Dictionary = {}

		if str(source_data.get("event_family", "")) == "person":
			post = _build_persona_post(feed_data, unlocked_accounts, source_data, current_trade_date, context)
		if post.is_empty():
			var minimum_tier: int = _required_tier_for_event_age(age_days)
			if str(source_data.get("event_family", "")) == "index_review":
				minimum_tier = 1
			var account: Dictionary = _pick_generic_account(unlocked_accounts, minimum_tier, "event|%s|%s" % [str(source_data.get("event_id", "")), company_id])
			if account.is_empty():
				continue
			var text_key: String = _voice_key_for_event(source_data)
			var post_text: String = _pick_voice_text(
				feed_data,
				str(account.get("voice", "")),
				text_key,
				"event|%s|%s|%s" % [str(source_data.get("event_id", "")), company_id, age_days],
				context
			)
			var post_priority: float = 2.4 - min(float(age_days) * 0.08, 1.0)
			if str(source_data.get("event_family", "")) == "index_review":
				post_priority = 4.25 - min(float(age_days) * 0.05, 0.4)
			post = _build_post(
				feed_data,
				account,
				"event|%s|%s|%s" % [str(source_data.get("event_id", "")), int(source_data.get("day_index", -1)), company_id],
				post_text,
				source_data,
				current_trade_date,
				context,
				_visibility_label_for_age(age_days),
				post_priority
			)

		if not post.is_empty():
			source_counts[source_key] = int(source_counts.get(source_key, 0)) + 1
			posts.append(post)

	return posts


func _build_relationship_event_post(
	feed_data: Dictionary,
	unlocked_accounts: Array,
	company_row_lookup: Dictionary,
	event_data: Dictionary,
	current_trade_date: Dictionary,
	current_day_index: int,
	story_memory: Dictionary,
	latest_market_entry: Dictionary
) -> Dictionary:
	if not _relationship_event_allows_public_surface(event_data):
		return {}
	var age_days: int = max(current_day_index - int(event_data.get("day_index", current_day_index)), 0)
	var minimum_tier: int = _required_tier_for_event_age(age_days)
	if str(event_data.get("relationship_visibility", "")) == "semi_public":
		minimum_tier = max(minimum_tier, 2)
	var account: Dictionary = _pick_generic_account(
		unlocked_accounts,
		minimum_tier,
		"relationship|%s" % str(event_data.get("relationship_event_id", event_data.get("event_id", "")))
	)
	if account.is_empty():
		return {}
	var company_id: String = str(event_data.get("target_company_id", ""))
	var row: Dictionary = company_row_lookup.get(company_id, {})
	var source_data: Dictionary = _source_with_market_context(_relationship_event_social_source(event_data), latest_market_entry)
	var context: Dictionary = _build_context(feed_data, source_data, row, current_trade_date, story_memory)
	var post_id: String = "relationship|%s|%s|%s" % [
		str(source_data.get("relationship_event_id", source_data.get("event_id", ""))),
		int(source_data.get("day_index", -1)),
		str(account.get("id", ""))
	]
	var post: Dictionary = _build_post(
		feed_data,
		account,
		post_id,
		_relationship_event_post_text(source_data, account),
		source_data,
		current_trade_date,
		context,
		_visibility_label_for_age(age_days),
		3.05 - min(float(age_days) * 0.08, 0.8)
	)
	if post.is_empty():
		return {}
	post = _apply_generated_twooter_metadata(post, source_data, account)
	return _copy_relationship_event_metadata(post, source_data)


func _relationship_event_allows_public_surface(event_data: Dictionary) -> bool:
	var visibility: String = str(event_data.get("relationship_visibility", "")).strip_edges().to_lower()
	return visibility == "public" or visibility == "semi_public"


func _relationship_event_social_source(event_data: Dictionary) -> Dictionary:
	var source_data: Dictionary = event_data.duplicate(true)
	var visibility: String = str(source_data.get("relationship_visibility", "semi_public")).strip_edges().to_lower()
	source_data["scope"] = "company"
	source_data["category"] = "generated_twooter_relationship"
	source_data["event_family"] = RELATIONSHIP_GRAPH_SOURCE_SYSTEM_ID
	source_data["generated_content_surface"] = true
	source_data["generated_surface_id"] = "twooter"
	source_data["generated_scope_id"] = "relationship"
	source_data["source_system_id"] = RELATIONSHIP_GRAPH_SOURCE_SYSTEM_ID
	source_data["story_id"] = str(source_data.get("relationship_event_id", ""))
	source_data["story_family"] = "company_relationship"
	source_data["archetype_id"] = str(source_data.get("relationship_event_kind", source_data.get("category", "")))
	source_data["public_status"] = "reported" if visibility == "public" else "market_talk"
	source_data["stage_id"] = "relationship_event"
	source_data["visibility"] = "public" if visibility == "public" else "semi_public"
	source_data["detail_level"] = "relationship"
	source_data["reliability"] = snappedf(clamp(float(source_data.get("relationship_confidence", source_data.get("confidence", 0.0))) * 0.88, 0.0, 1.0), 0.001)
	source_data["leak_risk"] = 0.0 if visibility == "public" else 0.12
	source_data["source_fact_ids"] = _unique_string_array(["relationship_event:%s" % str(source_data.get("relationship_event_id", ""))])
	source_data["source_clue_ids"] = _unique_string_array(["relationship_edge:%s" % str(source_data.get("relationship_edge_id", ""))])
	source_data["source_company_ids"] = _unique_string_array([
		str(source_data.get("target_company_id", "")),
		str(source_data.get("counterparty_company_id", ""))
	])
	source_data["source_sector_ids"] = _unique_string_array([str(source_data.get("target_sector_id", ""))])
	source_data["source_event_ids"] = _unique_string_array([str(source_data.get("relationship_event_id", ""))])
	source_data["description"] = _relationship_event_social_summary(source_data)
	return source_data


func _relationship_event_social_summary(source_data: Dictionary) -> String:
	var target_ticker: String = str(source_data.get("target_ticker", source_data.get("target_company_id", ""))).to_upper()
	var counterparty_ticker: String = str(source_data.get("counterparty_ticker", source_data.get("counterparty_company_id", ""))).to_upper()
	var role: String = str(source_data.get("relationship_impact_role", ""))
	var event_kind: String = str(source_data.get("relationship_event_kind", ""))
	if event_kind == "competitor_pressure":
		return "%s/%s relative momentum is what people are watching, not a clean standalone catalyst yet." % [target_ticker, counterparty_ticker]
	if role == "supplier":
		return "%s is getting attention for the commercial link with %s; follow-through still matters." % [target_ticker, counterparty_ticker]
	if role == "customer":
		return "%s has exposure to the %s link, but the economics are still being argued." % [target_ticker, counterparty_ticker]
	return "%s and %s are being tied together by relationship chatter." % [target_ticker, counterparty_ticker]


func _relationship_event_post_text(source_data: Dictionary, account: Dictionary) -> String:
	var target_ticker: String = str(source_data.get("target_ticker", source_data.get("target_company_id", ""))).to_upper()
	var counterparty_ticker: String = str(source_data.get("counterparty_ticker", source_data.get("counterparty_company_id", ""))).to_upper()
	var summary: String = str(source_data.get("description", "")).strip_edges()
	var voice_id: String = str(account.get("voice", ""))
	if voice_id == "funda_thread" or voice_id == "quality_hold":
		return "%s/%s link is worth tracking, but the real test is whether it appears in orders, margins, or filings. %s" % [target_ticker, counterparty_ticker, summary]
	if voice_id == "rumor_feed" or voice_id == "retail_hype":
		return "%s-%s relationship chatter is back on the tape. Not enough for blind chasing, but enough to keep it on watch." % [target_ticker, counterparty_ticker]
	return "%s and %s are getting relationship-linked attention today. %s" % [target_ticker, counterparty_ticker, summary]


func _copy_relationship_event_metadata(target: Dictionary, source_data: Dictionary) -> Dictionary:
	var enriched: Dictionary = target.duplicate(true)
	for key in [
		"relationship_event_id",
		"relationship_event_kind",
		"relationship_edge_id",
		"relationship_type",
		"relationship_visibility",
		"relationship_impact_role",
		"counterparty_company_id",
		"counterparty_ticker",
		"counterparty_company_name",
		"source_event_ids"
	]:
		if source_data.has(key):
			enriched[key] = source_data.get(key)
	return enriched


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


func _build_ambient_posts(
	feed_data: Dictionary,
	unlocked_accounts: Array,
	company_rows: Array,
	market_history: Array,
	current_trade_date: Dictionary
) -> Array:
	var posts: Array = []
	var current_day_index: int = int(current_trade_date.get("day_index", current_trade_date.get("day", 0)))
	var sorted_rows: Array = []
	for row_value in company_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if not str(row.get("ticker", "")).is_empty():
			sorted_rows.append(row.duplicate(true))
	sorted_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("daily_change_pct", 0.0)) > float(b.get("daily_change_pct", 0.0))
	)

	if not sorted_rows.is_empty():
		var winner_row: Dictionary = sorted_rows[0]
		posts.append(_build_ambient_company_post(
			feed_data,
			unlocked_accounts,
			winner_row,
			current_trade_date,
			"top_mover",
			1.55
		))
		var loser_row: Dictionary = sorted_rows[sorted_rows.size() - 1]
		if str(loser_row.get("id", "")) != str(winner_row.get("id", "")):
			posts.append(_build_ambient_company_post(
				feed_data,
				unlocked_accounts,
				loser_row,
				current_trade_date,
				"weak_mover",
				1.45
			))

	var sector_source: Dictionary = _build_ambient_sector_source(sorted_rows, current_trade_date)
	if not sector_source.is_empty():
		posts.append(_build_ambient_source_post(
			feed_data,
			unlocked_accounts,
			sector_source,
			{},
			current_trade_date,
			"sector_watch",
			1.35
		))

	if not market_history.is_empty():
		var latest_entry: Dictionary = market_history[market_history.size() - 1]
		var market_source: Dictionary = latest_entry.duplicate(true)
		market_source["scope"] = "market"
		market_source["category"] = "ambient_market"
		market_source["event_family"] = "ambient"
		market_source["tone"] = _tone_from_change(float(latest_entry.get("average_change_pct", 0.0)))
		market_source["day_index"] = current_day_index
		market_source["trade_date"] = current_trade_date.duplicate(true)
		posts.append(_build_ambient_source_post(
			feed_data,
			unlocked_accounts,
			market_source,
			{},
			current_trade_date,
			"market_mood",
			1.25
		))

	if posts.is_empty():
		var fallback_source: Dictionary = {
			"scope": "market",
			"category": "ambient_watch",
			"event_family": "ambient",
			"tone": "mixed",
			"day_index": current_day_index,
			"trade_date": current_trade_date.duplicate(true)
		}
		posts.append(_build_ambient_source_post(
			feed_data,
			unlocked_accounts,
			fallback_source,
			{},
			current_trade_date,
			"watching_tomorrow",
			1.0
		))

	return posts


func _build_ambient_company_post(
	feed_data: Dictionary,
	unlocked_accounts: Array,
	company_row: Dictionary,
	current_trade_date: Dictionary,
	ambient_key: String,
	priority: float
) -> Dictionary:
	var source_data: Dictionary = company_row.duplicate(true)
	source_data["scope"] = "company"
	source_data["category"] = "ambient_company"
	source_data["event_family"] = "ambient"
	source_data["tone"] = _tone_from_change(float(company_row.get("daily_change_pct", 0.0)))
	source_data["target_company_id"] = str(company_row.get("id", ""))
	source_data["target_ticker"] = str(company_row.get("ticker", ""))
	source_data["target_company_name"] = str(company_row.get("name", ""))
	source_data["target_sector_id"] = str(company_row.get("sector_id", ""))
	source_data["sector_name"] = str(company_row.get("sector_name", ""))
	source_data["summary"] = "%s moved %s today." % [
		str(company_row.get("ticker", "This name")),
		_format_percent(float(company_row.get("daily_change_pct", 0.0)))
	]
	source_data["day_index"] = int(current_trade_date.get("day_index", -1))
	source_data["trade_date"] = current_trade_date.duplicate(true)
	return _build_ambient_source_post(
		feed_data,
		unlocked_accounts,
		source_data,
		company_row,
		current_trade_date,
		ambient_key,
		priority
	)


func _build_ambient_source_post(
	feed_data: Dictionary,
	unlocked_accounts: Array,
	source_data: Dictionary,
	company_row: Dictionary,
	current_trade_date: Dictionary,
	ambient_key: String,
	priority: float
) -> Dictionary:
	var source_key: String = str(source_data.get("target_company_id", ""))
	if source_key.is_empty():
		source_key = str(source_data.get("target_sector_id", ""))
	if source_key.is_empty():
		source_key = "market"
	var post_id: String = "ambient|%s|%s|%s" % [
		ambient_key,
		source_key,
		int(current_trade_date.get("day_index", 0))
	]
	var account: Dictionary = _pick_generic_account(unlocked_accounts, 1, post_id)
	if account.is_empty():
		return {}
	var context: Dictionary = _build_context(feed_data, source_data, company_row, current_trade_date, {})
	if str(source_data.get("scope", "")) == "market":
		context["market_change"] = _format_percent(float(source_data.get("average_change_pct", 0.0)))
		context["advancers"] = str(int(source_data.get("advancers", 0)))
		context["decliners"] = str(int(source_data.get("decliners", 0)))
		var biggest_winner: Dictionary = source_data.get("biggest_winner", {})
		var biggest_loser: Dictionary = source_data.get("biggest_loser", {})
		context["biggest_winner"] = str(biggest_winner.get("ticker", "leader"))
		context["biggest_loser"] = str(biggest_loser.get("ticker", "laggard"))
	var text_key: String = _voice_key_for_event(source_data)
	var post_text: String = _pick_voice_text(
		feed_data,
		str(account.get("voice", "")),
		text_key,
		post_id,
		context
	)
	return _build_post(
		feed_data,
		account,
		post_id,
		post_text,
		source_data,
		current_trade_date,
		context,
		"Today",
		priority
	)


func _build_ambient_sector_source(company_rows: Array, current_trade_date: Dictionary) -> Dictionary:
	var sector_totals: Dictionary = {}
	for row_value in company_rows:
		var row: Dictionary = row_value
		var sector_id: String = str(row.get("sector_id", ""))
		if sector_id.is_empty():
			continue
		var sector_row: Dictionary = sector_totals.get(sector_id, {
			"sector_id": sector_id,
			"sector_name": str(row.get("sector_name", sector_id)),
			"total_change": 0.0,
			"count": 0
		})
		sector_row["total_change"] = float(sector_row.get("total_change", 0.0)) + float(row.get("daily_change_pct", 0.0))
		sector_row["count"] = int(sector_row.get("count", 0)) + 1
		sector_totals[sector_id] = sector_row

	var best_sector: Dictionary = {}
	var best_abs_change: float = 0.0
	for sector_value in sector_totals.values():
		var sector_row: Dictionary = sector_value
		var average_change: float = float(sector_row.get("total_change", 0.0)) / float(max(int(sector_row.get("count", 1)), 1))
		if absf(average_change) > best_abs_change:
			best_abs_change = absf(average_change)
			best_sector = sector_row.duplicate(true)
			best_sector["average_change_pct"] = average_change
	if best_sector.is_empty():
		return {}
	var sector_name: String = str(best_sector.get("sector_name", "the sector"))
	return {
		"scope": "sector",
		"category": "ambient_sector",
		"event_family": "ambient",
		"tone": _tone_from_change(float(best_sector.get("average_change_pct", 0.0))),
		"target_sector_id": str(best_sector.get("sector_id", "")),
		"sector_name": sector_name,
		"summary": "%s was one of today's clearer sector moves." % sector_name,
		"day_index": int(current_trade_date.get("day_index", -1)),
		"trade_date": current_trade_date.duplicate(true)
	}


func _build_generated_dossier_twooter_sources(
	run_state,
	company_row_lookup: Dictionary,
	current_trade_date: Dictionary,
	current_day_index: int
) -> Array:
	if run_state == null or not run_state.has_method("get_company_story_dossier_state"):
		return []

	var dossier_state: Dictionary = run_state.get_company_story_dossier_state()
	var dossier_index: Dictionary = dossier_state.get("dossier_index", {})
	var source_candidates: Array = []
	var seen_sector_ids: Dictionary = {}
	var seen_macro_keys: Dictionary = {}
	for story_id_value in dossier_index.keys():
		var dossier_value: Variant = dossier_index.get(story_id_value, {})
		if typeof(dossier_value) != TYPE_DICTIONARY:
			continue
		var dossier: Dictionary = dossier_value
		var public_clue: Dictionary = _public_twooter_clue_for_day(dossier, current_day_index)
		if public_clue.is_empty():
			continue
		var company_id: String = str(dossier.get("company_id", ""))
		var company_row: Dictionary = company_row_lookup.get(company_id, {})
		if company_row.is_empty():
			company_row = _company_row_from_dossier(dossier)

		var company_source: Dictionary = _generated_twooter_company_source(dossier, public_clue, company_row, current_trade_date, current_day_index)
		if not company_source.is_empty():
			source_candidates.append(company_source)

		var sector_fact: Dictionary = _best_fact_for_types(dossier, ["sector"])
		var sector_id: String = str(sector_fact.get("source_id", company_row.get("sector_id", "")))
		if not sector_id.is_empty() and not seen_sector_ids.has(sector_id):
			var sector_source: Dictionary = _generated_twooter_sector_source(dossier, public_clue, sector_fact, company_row, current_trade_date, current_day_index)
			if not sector_source.is_empty():
				source_candidates.append(sector_source)
				seen_sector_ids[sector_id] = true

		var macro_fact: Dictionary = _best_fact_for_types(dossier, ["macro", "commodity"])
		var macro_key: String = "%s|%s" % [
			str(macro_fact.get("fact_type", "")),
			str(macro_fact.get("source_id", ""))
		]
		if not macro_fact.is_empty() and not seen_macro_keys.has(macro_key):
			var macro_source: Dictionary = _generated_twooter_macro_source(dossier, public_clue, macro_fact, company_row, current_trade_date, current_day_index)
			if not macro_source.is_empty():
				source_candidates.append(macro_source)
				seen_macro_keys[macro_key] = true

	source_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("priority", 0.0)), float(b.get("priority", 0.0))):
			return str(a.get("event_id", "")) < str(b.get("event_id", ""))
		return float(a.get("priority", 0.0)) > float(b.get("priority", 0.0))
	)
	return _select_generated_dossier_twooter_sources(source_candidates)


func _build_generated_dossier_twooter_posts(
	feed_data: Dictionary,
	unlocked_accounts: Array,
	company_row_lookup: Dictionary,
	generated_twooter_sources: Array,
	current_trade_date: Dictionary,
	story_memory: Dictionary
) -> Array:
	var posts: Array = []
	for source_value in generated_twooter_sources:
		if posts.size() >= MAX_GENERATED_DOSSIER_TWOOTER_POSTS:
			break
		if typeof(source_value) != TYPE_DICTIONARY:
			continue
		var source_data: Dictionary = source_value
		var account: Dictionary = _pick_generated_twooter_account(unlocked_accounts, source_data)
		if account.is_empty():
			continue
		var company_id: String = str(source_data.get("target_company_id", ""))
		var company_row: Dictionary = company_row_lookup.get(company_id, {})
		var post_id: String = "generated_dossier_twooter|%s|%s|%s|%d" % [
			str(account.get("id", "")),
			str(source_data.get("generated_scope_id", "")),
			str(source_data.get("story_id", "")).replace("|", "_"),
			int(source_data.get("day_index", current_trade_date.get("day_index", -1)))
		]
		var context: Dictionary = _build_context(feed_data, source_data, company_row, current_trade_date, story_memory)
		var post_text: String = _generated_twooter_post_text(account, source_data, context, post_id)
		if post_text.is_empty():
			post_text = _pick_voice_text(
				feed_data,
				str(account.get("voice", "")),
				_voice_key_for_event(source_data),
				post_id,
				context
			)
		var post: Dictionary = _build_post(
			feed_data,
			account,
			post_id,
			post_text,
			source_data,
			current_trade_date,
			context,
			_generated_twooter_visibility_label(account, source_data),
			float(source_data.get("priority", 2.0))
		)
		if post.is_empty():
			continue
		posts.append(_apply_generated_twooter_metadata(post, source_data, account))
	return posts


func _select_generated_dossier_twooter_sources(source_candidates: Array) -> Array:
	var buckets: Dictionary = {
		"company": [],
		"sector": [],
		"macro": []
	}
	for source_value in source_candidates:
		if typeof(source_value) != TYPE_DICTIONARY:
			continue
		var source_data: Dictionary = source_value
		var scope_id: String = str(source_data.get("generated_scope_id", "company"))
		if not buckets.has(scope_id):
			scope_id = "company"
		var bucket: Array = buckets.get(scope_id, [])
		bucket.append(source_data)
		buckets[scope_id] = bucket

	var selected: Array = []
	for scope_id in ["company", "sector", "macro"]:
		var bucket: Array = buckets.get(scope_id, [])
		var bucket_limit: int = 2 if scope_id != "macro" else 1
		for index in range(min(bucket_limit, bucket.size())):
			selected.append(bucket[index])

	if selected.size() < MAX_GENERATED_DOSSIER_TWOOTER_SOURCES:
		var seen_ids: Dictionary = {}
		for selected_value in selected:
			if typeof(selected_value) != TYPE_DICTIONARY:
				continue
			var selected_source: Dictionary = selected_value
			seen_ids[str(selected_source.get("event_id", ""))] = true
		for source_value in source_candidates:
			if typeof(source_value) != TYPE_DICTIONARY:
				continue
			var source_data: Dictionary = source_value
			var event_id: String = str(source_data.get("event_id", ""))
			if seen_ids.has(event_id):
				continue
			selected.append(source_data)
			seen_ids[event_id] = true
			if selected.size() >= MAX_GENERATED_DOSSIER_TWOOTER_SOURCES:
				break

	selected.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("priority", 0.0)), float(b.get("priority", 0.0))):
			return str(a.get("event_id", "")) < str(b.get("event_id", ""))
		return float(a.get("priority", 0.0)) > float(b.get("priority", 0.0))
	)
	return selected


func _public_twooter_clue_for_day(dossier: Dictionary, current_day_index: int) -> Dictionary:
	for clue_value in dossier.get("public_clues", []):
		if typeof(clue_value) != TYPE_DICTIONARY:
			continue
		var clue: Dictionary = clue_value
		if str(clue.get("surface_id", "")) != "twooter":
			continue
		if str(clue.get("visibility", "public")) != "public":
			continue
		var earliest_day_index: int = int(clue.get("earliest_day_index", 0))
		var latest_day_index: int = int(clue.get("latest_day_index", earliest_day_index))
		if current_day_index < earliest_day_index or current_day_index > latest_day_index:
			continue
		return clue.duplicate(true)
	return {}


func _generated_twooter_company_source(
	dossier: Dictionary,
	clue: Dictionary,
	company_row: Dictionary,
	current_trade_date: Dictionary,
	current_day_index: int
) -> Dictionary:
	var ticker: String = str(dossier.get("ticker", company_row.get("ticker", "")))
	if ticker.is_empty():
		return {}
	var company_id: String = str(dossier.get("company_id", company_row.get("id", "")))
	var company_name: String = str(company_row.get("name", ticker))
	var sector_id: String = str(company_row.get("sector_id", ""))
	var sector_name: String = str(company_row.get("sector_name", DataRepository.get_sector_definition(sector_id).get("name", sector_id.capitalize())))
	var detail: String = _generated_twooter_company_detail(dossier, company_name, sector_name)
	return _generated_twooter_source_base(dossier, clue, current_trade_date, current_day_index, {
		"generated_scope_id": "company",
		"category": "generated_twooter_company",
		"scope": "company",
		"event_id": "generated_dossier_twooter_company|%s" % str(dossier.get("story_id", "")),
		"target_company_id": company_id,
		"target_ticker": ticker,
		"target_company_name": company_name,
		"target_sector_id": sector_id,
		"sector_name": sector_name,
		"description": detail,
		"summary": detail,
		"source_company_ids": _unique_string_array([company_id]),
		"source_sector_ids": _unique_string_array([sector_id]),
		"priority": 2.18 + float(dossier.get("priority", 0.0)) * 0.24 + float(clue.get("reliability", 0.0)) * 0.06
	})


func _generated_twooter_sector_source(
	dossier: Dictionary,
	clue: Dictionary,
	fact: Dictionary,
	company_row: Dictionary,
	current_trade_date: Dictionary,
	current_day_index: int
) -> Dictionary:
	var sector_id: String = str(fact.get("source_id", company_row.get("sector_id", "")))
	if sector_id.is_empty():
		return {}
	var sector_definition: Dictionary = DataRepository.get_sector_definition(sector_id)
	var sector_name: String = str(company_row.get("sector_name", sector_definition.get("name", sector_id.capitalize())))
	var detail: String = "%s chatter is shifting from one-name noise into a broader watchlist." % sector_name
	return _generated_twooter_source_base(dossier, clue, current_trade_date, current_day_index, {
		"generated_scope_id": "sector",
		"category": "generated_twooter_sector",
		"scope": "sector",
		"event_id": "generated_dossier_twooter_sector|%s|%s" % [sector_id, str(dossier.get("story_id", ""))],
		"target_sector_id": sector_id,
		"sector_name": sector_name,
		"description": detail,
		"summary": detail,
		"source_company_ids": _source_company_ids_from_fact(fact, str(dossier.get("company_id", ""))),
		"source_sector_ids": _source_sector_ids_from_fact(fact, sector_id),
		"priority": 2.08 + float(dossier.get("priority", 0.0)) * 0.20 + float(clue.get("reliability", 0.0)) * 0.05
	})


func _generated_twooter_macro_source(
	dossier: Dictionary,
	clue: Dictionary,
	fact: Dictionary,
	company_row: Dictionary,
	current_trade_date: Dictionary,
	current_day_index: int
) -> Dictionary:
	var fact_type: String = str(fact.get("fact_type", "macro"))
	var source_id: String = str(fact.get("source_id", "macro"))
	var public_label: String = _public_fact_source_label(source_id)
	var sector_id: String = str(company_row.get("sector_id", ""))
	var sector_name: String = str(company_row.get("sector_name", DataRepository.get_sector_definition(sector_id).get("name", sector_id.capitalize())))
	var detail: String = "%s is turning into a noisy exposure map, not a clean single-name answer." % public_label
	return _generated_twooter_source_base(dossier, clue, current_trade_date, current_day_index, {
		"generated_scope_id": "macro",
		"category": "generated_twooter_commodity" if fact_type == "commodity" else "generated_twooter_macro",
		"scope": "market",
		"event_id": "generated_dossier_twooter_macro|%s|%s|%s" % [fact_type, source_id, str(dossier.get("story_id", ""))],
		"target_sector_id": sector_id,
		"sector_name": sector_name,
		"description": detail,
		"summary": detail,
		"source_company_ids": _source_company_ids_from_fact(fact, str(dossier.get("company_id", ""))),
		"source_sector_ids": _source_sector_ids_from_fact(fact, sector_id),
		"public_factor_label": public_label,
		"priority": 2.00 + float(dossier.get("priority", 0.0)) * 0.16 + float(clue.get("reliability", 0.0)) * 0.05
	})


func _generated_twooter_source_base(
	dossier: Dictionary,
	clue: Dictionary,
	current_trade_date: Dictionary,
	current_day_index: int,
	overrides: Dictionary
) -> Dictionary:
	var source_data: Dictionary = overrides.duplicate(true)
	source_data["event_family"] = "content_surface_generation"
	source_data["tone"] = str(clue.get("tone", "mixed"))
	source_data["day_index"] = current_day_index
	source_data["trade_date"] = current_trade_date.duplicate(true)
	source_data["generated_content_surface"] = true
	source_data["generated_surface_id"] = "twooter"
	source_data["source_system_id"] = GENERATED_DOSSIER_TWOOTER_SOURCE_SYSTEM_ID
	source_data["story_id"] = str(dossier.get("story_id", ""))
	source_data["story_family"] = str(dossier.get("story_family", "company_story"))
	source_data["archetype_id"] = str(dossier.get("archetype_id", ""))
	source_data["public_status"] = str(dossier.get("public_status", ""))
	source_data["stage_id"] = str(dossier.get("stage_id", ""))
	source_data["visibility"] = "public"
	source_data["detail_level"] = str(clue.get("detail_level", "low"))
	source_data["reliability"] = snappedf(clamp(float(clue.get("reliability", 0.0)), 0.0, 0.68), 0.001)
	source_data["leak_risk"] = 0.0
	source_data["source_fact_ids"] = _source_fact_ids_from_dossier(dossier, clue)
	source_data["source_clue_ids"] = _unique_string_array([str(clue.get("clue_id", ""))])
	return source_data


func _pick_generated_twooter_account(unlocked_accounts: Array, source_data: Dictionary) -> Dictionary:
	var preferred_voices: Array = _generated_twooter_preferred_voices(source_data)
	for voice_value in preferred_voices:
		var voice_id: String = str(voice_value)
		var account: Dictionary = _account_by_voice(unlocked_accounts, voice_id)
		if not account.is_empty():
			return account
	return _pick_generic_account(unlocked_accounts, 1, "generated_twooter|%s|%s" % [
		str(source_data.get("generated_scope_id", "company")),
		str(source_data.get("story_id", ""))
	])


func _generated_twooter_preferred_voices(source_data: Dictionary) -> Array:
	var scope_id: String = str(source_data.get("generated_scope_id", "company"))
	var tone: String = str(source_data.get("tone", "mixed"))
	var reliability: float = float(source_data.get("reliability", 0.0))
	var seed_value: int = int(abs(hash("%s|%s|voice" % [str(source_data.get("event_id", "")), tone])))
	if scope_id == "macro":
		var macro_voices: Array = ["macro_watch", "sector_classroom", "oil_psych", "market_diary"]
		return _rotated_array(macro_voices, seed_value)
	if scope_id == "sector":
		var sector_voices: Array = ["sector_classroom", "flow_watch", "market_diary", "retail_hype"]
		return _rotated_array(sector_voices, seed_value)
	if reliability < 0.38:
		var noisy_voices: Array = ["rumor_feed", "retail_hype", "flow_watch", "market_diary"]
		return _rotated_array(noisy_voices, seed_value)
	var company_voices: Array = ["rumor_feed", "flow_watch", "retail_hype", "funda_thread", "stock_mapper"]
	return _rotated_array(company_voices, seed_value)


func _account_by_voice(unlocked_accounts: Array, voice_id: String) -> Dictionary:
	for account_value in unlocked_accounts:
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value
		if str(account.get("voice", "")) == voice_id:
			return account
	return {}


func _generated_twooter_post_text(account: Dictionary, source_data: Dictionary, context: Dictionary, seed_key: String) -> String:
	var voice_id: String = str(account.get("voice", ""))
	var ticker: String = str(context.get("target_ticker", "")).strip_edges()
	var sector_name: String = str(context.get("sector_name", "the sector")).strip_edges()
	var factor_label: String = str(source_data.get("public_factor_label", "Macro")).strip_edges()
	var hint: String = _short_public_hint(str(source_data.get("summary", source_data.get("description", ""))))
	var label: String = ticker if not ticker.is_empty() else sector_name
	var scope_id: String = str(source_data.get("generated_scope_id", "company"))
	var tail_pool: Array = [
		"Needs confirmation, not chest-thumping.",
		"Good lead, bad shortcut.",
		"Watch the follow-through before calling it clean.",
		"Could be signal, could be timeline drama.",
		"Still just a lead until the next public clue."
	]
	var tail: String = str(_pick_from_pool(tail_pool, "%s|tail" % seed_key))
	if scope_id == "macro":
		match voice_id:
			"macro_watch":
				return "%s is the macro read today. Map exposure first; do not turn every ticker into the same story." % factor_label
			"sector_classroom":
				return "%s matters only after you map who actually has exposure. Theme passengers are where people get lazy." % factor_label
			"oil_psych":
				return "%s gives the market a simple story. The hard part is separating cash-flow names from hype riders." % factor_label
			_:
				return "%s chatter is moving across the board. %s" % [factor_label, tail]
	if scope_id == "sector":
		match voice_id:
			"sector_classroom":
				return "%s thread: the move is more useful if second-line names confirm it. One hot ticker is not a sector story." % sector_name
			"flow_watch":
				return "%s flow looks less random now. I want breadth inside the sector before respecting the story." % sector_name
			"market_diary":
				return "Diary note: %s is on the timeline again. %s" % [sector_name, tail]
			_:
				return "%s becoming the room everyone watches. Exciting, but crowding cuts both ways." % sector_name
	match voice_id:
		"rumor_feed":
			return "%s is on the rumor table. %s %s" % [label, hint, tail]
		"retail_hype":
			return "%s has a fresh story and ritel will probably overreact if the tape keeps moving. %s" % [label, tail]
		"flow_watch":
			return "%s flow is worth watching now. Story is useful only if volume keeps confirming." % label
		"funda_thread":
			return "%s story is interesting, but I still want the boring public source before upgrading the thesis." % label
		"stock_mapper":
			return "%s goes on the watch map. The setup needs one more public clue before it becomes more than chatter." % label
		_:
			return "%s has public chatter now. %s" % [label, tail]


func _generated_twooter_visibility_label(account: Dictionary, source_data: Dictionary) -> String:
	if bool(account.get("verified", false)):
		return "Public thread"
	if str(source_data.get("generated_scope_id", "")) == "macro":
		return "Macro chatter"
	if str(account.get("voice", "")) == "rumor_feed":
		return "Rumor watch"
	return "On feed"


func _generated_twooter_confidence_label(account: Dictionary, source_data: Dictionary) -> String:
	var voice_id: String = str(account.get("voice", ""))
	if voice_id == "rumor_feed" or voice_id == "retail_hype":
		return "Noisy chatter"
	if voice_id == "flow_watch":
		return "Flow watch"
	if bool(account.get("verified", false)):
		return "Public thread"
	if float(source_data.get("reliability", 0.0)) < 0.38:
		return "Low-confidence chatter"
	return "Public chatter"


func _apply_generated_twooter_metadata(post: Dictionary, source_data: Dictionary, account: Dictionary) -> Dictionary:
	var enriched: Dictionary = post.duplicate(true)
	for key in [
		"generated_content_surface",
		"generated_surface_id",
		"generated_scope_id",
		"source_system_id",
		"story_id",
		"story_family",
		"archetype_id",
		"public_status",
		"stage_id",
		"visibility",
		"detail_level",
		"reliability",
		"leak_risk",
		"source_fact_ids",
		"source_clue_ids",
		"source_company_ids",
		"source_sector_ids",
		"source_event_ids",
		"target_company_id"
	]:
		enriched[key] = source_data.get(key)
	enriched["account_voice"] = str(account.get("voice", ""))
	enriched["public_confidence_label"] = _generated_twooter_confidence_label(account, source_data)
	return enriched


func _generated_twooter_company_detail(dossier: Dictionary, company_name: String, sector_name: String) -> String:
	match str(dossier.get("archetype_id", "")):
		"contract_win":
			return "public chatter is circling new work around %s." % company_name
		"capex_expansion":
			return "capacity talk around %s is getting noisy." % company_name
		"margin_recovery":
			return "people are debating whether %s has a cleaner margin setup." % company_name
		"commodity_tailwind":
			return "%s is being tied to a friendlier commodity read in %s." % [company_name, sector_name]
		"commodity_headwind":
			return "%s is being checked against tougher commodity talk in %s." % [company_name, sector_name]
		"governance_risk":
			return "governance talk around %s is making the feed cautious." % company_name
		"balance_sheet_stress":
			return "%s balance-sheet chatter is getting louder." % company_name
		"fraud_signal":
			return "people are asking rougher questions about %s." % company_name
		"turnaround":
			return "%s has a turnaround story people want to believe, maybe too quickly." % company_name
		_:
			return "%s has a fresh public story on the feed." % company_name


func _company_row_from_dossier(dossier: Dictionary) -> Dictionary:
	var company_id: String = str(dossier.get("company_id", ""))
	var ticker: String = str(dossier.get("ticker", company_id.to_upper()))
	return {
		"id": company_id,
		"ticker": ticker,
		"name": ticker,
		"sector_id": "",
		"sector_name": "",
		"daily_change_pct": 0.0,
		"current_price": 0.0
	}


func _best_fact_for_types(dossier: Dictionary, fact_types: Array) -> Dictionary:
	for fact_value in dossier.get("cause_facts", []):
		if typeof(fact_value) != TYPE_DICTIONARY:
			continue
		var fact: Dictionary = fact_value
		if str(fact.get("fact_type", "")) in fact_types:
			return fact.duplicate(true)
	return {}


func _source_fact_ids_from_dossier(dossier: Dictionary, clue: Dictionary) -> Array:
	var clue_fact_ids: Array = _unique_string_array(clue.get("fact_ids", []))
	if not clue_fact_ids.is_empty():
		return clue_fact_ids
	var fact_ids: Array = []
	for fact_value in dossier.get("cause_facts", []):
		if typeof(fact_value) != TYPE_DICTIONARY:
			continue
		var fact: Dictionary = fact_value
		fact_ids.append(str(fact.get("fact_id", "")))
	return _unique_string_array(fact_ids)


func _source_company_ids_from_fact(fact: Dictionary, fallback_company_id: String) -> Array:
	var company_ids: Array = []
	if not fallback_company_id.is_empty():
		company_ids.append(fallback_company_id)
	for key in ["company_ids", "source_company_ids", "affected_company_ids", "related_company_ids"]:
		for company_id_value in fact.get(key, []):
			company_ids.append(str(company_id_value))
	return _unique_string_array(company_ids)


func _source_sector_ids_from_fact(fact: Dictionary, fallback_sector_id: String) -> Array:
	var sector_ids: Array = []
	if not fallback_sector_id.is_empty():
		sector_ids.append(fallback_sector_id)
	for key in ["sector_ids", "source_sector_ids", "affected_sector_ids", "related_sector_ids"]:
		for sector_id_value in fact.get(key, []):
			sector_ids.append(str(sector_id_value))
	return _unique_string_array(sector_ids)


func _public_fact_source_label(source_id: String) -> String:
	var cleaned: String = source_id.replace("_", " ").strip_edges()
	if cleaned.is_empty():
		return "Macro"
	var words: PackedStringArray = cleaned.split(" ")
	var title_words: Array[String] = []
	for word in words:
		if word.is_empty():
			continue
		title_words.append(word.substr(0, 1).to_upper() + word.substr(1).to_lower())
	return " ".join(title_words)


func _short_public_hint(value: String) -> String:
	var cleaned: String = value.strip_edges()
	if cleaned.is_empty() or _looks_like_system_summary(cleaned):
		return "The public trail is still thin."
	cleaned = cleaned.replace("\n", " ")
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	if cleaned.length() > 96:
		cleaned = cleaned.substr(0, 96).strip_edges().trim_suffix(",").trim_suffix(".") + "."
	if not cleaned.ends_with(".") and not cleaned.ends_with("!") and not cleaned.ends_with("?"):
		cleaned += "."
	return cleaned


func _unique_string_array(source_value: Variant) -> Array:
	var source_array: Array = []
	if typeof(source_value) == TYPE_ARRAY:
		source_array = source_value
	else:
		source_array = [source_value]
	var seen: Dictionary = {}
	var result: Array = []
	for item_value in source_array:
		var item: String = str(item_value).strip_edges()
		if item.is_empty() or seen.has(item):
			continue
		seen[item] = true
		result.append(item)
	return result


func _rotated_array(source_array: Array, seed_value: int) -> Array:
	if source_array.is_empty():
		return []
	var offset: int = seed_value % source_array.size()
	var rotated: Array = []
	for index in range(source_array.size()):
		rotated.append(source_array[(offset + index) % source_array.size()])
	return rotated


func _build_market_wrap_post(
	feed_data: Dictionary,
	unlocked_accounts: Array,
	market_history: Array,
	current_trade_date: Dictionary,
	_story_memory: Dictionary
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
	context["public_confidence_label"] = "Market close"
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
		"Market close",
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
	post_text = post_text.strip_edges()
	if post_text.is_empty():
		return {}
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
	var provider_label: String = str(source_data.get("provider_label", ""))
	var context: Dictionary = {
		"target_ticker": str(source_data.get("target_ticker", company_row.get("ticker", ""))),
		"target_company_name": str(source_data.get("target_company_name", company_row.get("name", ""))),
		"provider_label": provider_label,
		"sector_name": str(source_data.get("sector_name", company_row.get("sector_name", sector_definition.get("name", "the sector")))),
		"person_name": str(source_data.get("person_name", "")),
		"scope": str(source_data.get("scope", "")),
		"description": str(source_data.get("description", "")),
		"tone": tone,
		"category": category,
		"public_topic_label": _public_topic_label(source_data),
		"public_confidence_label": _public_confidence_label(source_data),
		"public_continuity_phrase": continuity_phrase,
		"continuity_phrase": continuity_phrase,
		"public_context_hint": _public_context_hint(source_data, continuity_phrase)
	}
	if _source_needs_market_context(source_data):
		var biggest_winner: Dictionary = source_data.get("biggest_winner", {}) if typeof(source_data.get("biggest_winner", {})) == TYPE_DICTIONARY else {}
		var biggest_loser: Dictionary = source_data.get("biggest_loser", {}) if typeof(source_data.get("biggest_loser", {})) == TYPE_DICTIONARY else {}
		context["market_change"] = _format_percent(float(source_data.get("average_change_pct", source_data.get("market_change_pct", 0.0))))
		context["advancers"] = str(int(source_data.get("advancers", 0)))
		context["decliners"] = str(int(source_data.get("decliners", 0)))
		context["biggest_winner"] = str(biggest_winner.get("ticker", "leader"))
		context["biggest_loser"] = str(biggest_loser.get("ticker", "laggard"))
	return context


func _latest_market_entry(market_history: Array) -> Dictionary:
	if market_history.is_empty():
		return {}
	var latest_value = market_history[market_history.size() - 1]
	if typeof(latest_value) != TYPE_DICTIONARY:
		return {}
	return latest_value.duplicate(true)


func _source_with_market_context(source_data: Dictionary, latest_market_entry: Dictionary) -> Dictionary:
	if not _source_needs_market_context(source_data) or latest_market_entry.is_empty():
		return source_data.duplicate(true)
	var enriched: Dictionary = source_data.duplicate(true)
	for key in ["average_change_pct", "advancers", "decliners", "biggest_winner", "biggest_loser"]:
		if not enriched.has(key) and latest_market_entry.has(key):
			enriched[key] = latest_market_entry.get(key)
	return enriched


func _source_needs_market_context(source_data: Dictionary) -> bool:
	var category: String = str(source_data.get("category", ""))
	return str(source_data.get("scope", "")) == "market" or category == "market_wrap" or _category_family_key(source_data) == "market_wrap"


func _build_thread_lines(feed_data: Dictionary, account: Dictionary, source_data: Dictionary, context: Dictionary, _post_id: String) -> Array:
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
	var event_id: String = str(source_data.get("event_id", ""))
	if event_id.begins_with("policy_"):
		keys.append(event_id)
	if not category.is_empty():
		keys.append(category)
	if _is_policy_parody_source(source_data):
		keys.append("policy_parody")
		return keys
	if category.begins_with("index_") or str(source_data.get("event_family", "")) == "index_review":
		keys.append("index_review")
	if category.begins_with("corporate_action"):
		keys.append("corporate_action")
	if category == "corporate_meeting":
		keys.append("corporate_meeting")
	if category.begins_with("roadmap_"):
		keys.append("company_roadmap")
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
	if category.begins_with("generated_twooter"):
		return "generated_twooter"
	if category.begins_with("index_") or str(source_data.get("event_family", "")) == "index_review":
		return "index_review"
	if category.begins_with("corporate_action"):
		return "corporate_action"
	if category == "corporate_meeting":
		return "corporate_meeting"
	if category.begins_with("roadmap_"):
		return "company_roadmap"
	if _is_policy_parody_source(source_data):
		return "policy_parody"
	if category in ["earnings", "management", "market_wrap"]:
		return category
	if category.contains("commodity"):
		return "commodity"
	if str(source_data.get("scope", "")) == "market":
		return "market_wrap"
	return "company"


func _public_topic_label(source_data: Dictionary) -> String:
	var category: String = str(source_data.get("category", ""))
	if category == "generated_twooter_company":
		return "Emiten chatter"
	if category == "generated_twooter_sector":
		return "Sector chatter"
	if category == "generated_twooter_macro" or category == "generated_twooter_commodity":
		return "Macro chatter"
	if category.begins_with("index_") or str(source_data.get("event_family", "")) == "index_review":
		return "Index review"
	if category.begins_with("corporate_action"):
		return "Corporate action"
	if category == "corporate_meeting":
		return "RUPSLB watch"
	if category.begins_with("roadmap_"):
		return "Company roadmap"
	if category == "earnings":
		return "Earnings"
	if category == "management":
		return "Management"
	if _is_policy_parody_source(source_data):
		return _policy_parody_topic_label(category)
	if category.contains("commodity"):
		return "Commodity"
	if str(source_data.get("scope", "")) == "market" or category == "market_wrap":
		return "IHSG close"
	if str(source_data.get("scope", "")) == "sector":
		return "Sector watch"
	return "Emiten watch"


func _public_confidence_label(source_data: Dictionary) -> String:
	var category: String = str(source_data.get("category", ""))
	if category.begins_with("generated_twooter"):
		return "Public chatter"
	if category == "index_inclusion" or category == "index_exclusion":
		return "Index review"
	if category == "index_watch":
		return "Review watch"
	if category in ["corporate_action_filing", "corporate_action_resolution", "corporate_action_execution"]:
		return "Filed paperwork"
	if category == "corporate_meeting":
		return "Meeting calendar"
	if category == "corporate_action_rumor":
		return "Market talk"
	if category == "corporate_action_denial" or category == "corporate_action_clarification":
		return "Company response"
	if category.begins_with("roadmap_"):
		return "Public signals"
	if _is_policy_parody_source(source_data):
		return "Policy shock"
	if category == "market_wrap":
		return "Closing tape"
	return "Public chatter"


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
		lowered_value.contains("vague public hint") or
		lowered_value.contains("source reliability") or
		lowered_value.contains("current read") or
		lowered_value.contains("unclear location") or
		lowered_value.contains("development lead") or
		lowered_value.contains("intel level") or
		lowered_value.contains("source trail") or
		lowered_value.contains("source article") or
		lowered_value.contains("source story") or
		lowered_value.contains("working read") or
		lowered_value.contains("raw statement") or
		lowered_value.contains("system metadata") or
		lowered_value.contains("stage of a") or
		lowered_value.contains("price-bias read") or
		lowered_value.contains("funding_gate") or
		lowered_value.contains("funding readiness") or
		lowered_value.contains("roadmap_id") or
		lowered_value.contains("company_roadmap") or
		lowered_value.contains("participant_role") or
		lowered_value.contains("milestone_state") or
		lowered_value.contains("hidden_positioning") or
		lowered_value.contains("formal_agenda_or_filing") or
		lowered_value.contains("meeting_or_call")
	)


func _memory_label(source_data: Dictionary) -> String:
	var category: String = str(source_data.get("category", ""))
	if category.begins_with("generated_twooter"):
		return "Twooter chatter"
	if category == "index_inclusion":
		return "index inclusion"
	if category == "index_exclusion":
		return "index exclusion"
	if category == "index_watch":
		return "index watch"
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
	if seed_key.contains("policy_parody") or seed_key.contains("policy_"):
		var policy_voices: Array = ["macro_watch", "market_diary", "retail_hype", "rumor_feed"]
		return str(policy_voices[int(abs(hash("%s|voice" % seed_key))) % policy_voices.size()])
	if seed_key.contains("index_review") or seed_key.contains("index_"):
		return "funda_thread"
	if seed_key.contains("market_mood") or seed_key.contains("watching_tomorrow"):
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
	if _is_policy_parody_source(event_data):
		return _policy_parody_template_key(event_data)
	if event_family == "index_review" and not category.is_empty():
		return category
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
	if _is_policy_parody_source(event_data):
		return _policy_parody_template_key(event_data)
	if event_family == "index_review" and not category.is_empty():
		return category
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
	var fallback_templates: Dictionary = feed_data.get("fallback_templates", {})
	var voice_pool: Array = voice_templates.get(voice_id, {}).get(text_key, [])
	var is_policy_key: bool = text_key.begins_with("policy_")
	if voice_pool.is_empty() and is_policy_key:
		voice_pool = fallback_templates.get(text_key, [])
	if voice_pool.is_empty() and is_policy_key:
		voice_pool = voice_templates.get(voice_id, {}).get("policy_parody", [])
	var is_index_key: bool = text_key.begins_with("index_") or text_key == "index_review"
	if voice_pool.is_empty() and is_index_key:
		voice_pool = voice_templates.get(voice_id, {}).get("index_review", [])
	if voice_pool.is_empty() and is_index_key:
		var index_fallback_templates: Dictionary = feed_data.get("fallback_templates", {})
		for index_fallback_key in [text_key, "index_review"]:
			voice_pool = index_fallback_templates.get(str(index_fallback_key), [])
			if not voice_pool.is_empty():
				break
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
		var fallback_keys: Array = [
			text_key,
			"policy_parody" if is_policy_key else "",
			_category_family_key({"category": str(context.get("category", text_key)), "scope": str(context.get("scope", ""))}),
			"company_%s" % str(context.get("tone", "mixed")),
			"company",
			"all"
		]
		for fallback_key_value in fallback_keys:
			var fallback_key: String = str(fallback_key_value)
			voice_pool = fallback_templates.get(fallback_key, [])
			if not voice_pool.is_empty():
				break
		if voice_pool.is_empty():
			return ""
	return _render_template(_pick_from_pool(voice_pool, seed_key), context)


func _is_policy_parody_source(source_data: Dictionary) -> bool:
	return (
		str(source_data.get("shock_class", "")) == "policy_parody" or
		str(source_data.get("category", "")).begins_with("policy_") or
		str(source_data.get("event_id", "")).begins_with("policy_") or
		str(source_data.get("id", "")).begins_with("active_special|policy_")
	)


func _policy_parody_template_key(source_data: Dictionary) -> String:
	var event_id: String = str(source_data.get("event_id", ""))
	if event_id.begins_with("policy_"):
		return event_id
	var category: String = str(source_data.get("category", ""))
	if category.begins_with("policy_"):
		return category
	return "policy_parody"


func _policy_parody_topic_label(category: String) -> String:
	match category:
		"policy_fiscal_shock":
			return "Fiscal shock"
		"policy_commodity_gate":
			return "Commodity rule"
		"policy_fx_comment":
			return "FX comment"
		"policy_market_speech":
			return "Policy shock"
		"policy_free_meal":
			return "Policy shock"
		_:
			return "Policy shock"


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


func _append_unique_post_id(post_ids: Array, seen_ids: Dictionary, post_id: String) -> void:
	if post_id.is_empty() or seen_ids.has(post_id):
		return
	seen_ids[post_id] = true
	post_ids.append(post_id)


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
