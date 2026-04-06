extends RefCounted

const MAX_EVENT_LOOKBACK := 18


func build_news_snapshot(
	run_state,
	feed_data: Dictionary,
	company_rows: Array,
	market_history: Array,
	event_history: Array,
	active_special_events: Array,
	active_company_arcs: Array,
	current_trade_date: Dictionary,
	unlocked_intel_level: int = -1
) -> Dictionary:
	var outlets: Array = feed_data.get("outlets", []).duplicate(true)
	var resolved_intel_level: int = unlocked_intel_level
	if resolved_intel_level < 1:
		resolved_intel_level = int(feed_data.get("prototype_default_intel_level", max(outlets.size(), 1)))
	resolved_intel_level = clamp(resolved_intel_level, 1, max(outlets.size(), 1))

	var company_row_lookup: Dictionary = {}
	for row_value in company_rows:
		var row: Dictionary = row_value
		company_row_lookup[str(row.get("id", ""))] = row.duplicate(true)

	var outlet_rows: Array = []
	var feeds: Dictionary = {}
	for outlet_value in outlets:
		var outlet: Dictionary = outlet_value.duplicate(true)
		var outlet_id: String = str(outlet.get("id", ""))
		var outlet_level: int = int(outlet.get("intel_level", 1))
		outlet["unlocked"] = outlet_level <= resolved_intel_level
		outlet_rows.append(outlet)
		feeds[outlet_id] = _build_outlet_feed(
			run_state,
			outlet,
			feed_data,
			company_row_lookup,
			market_history,
			event_history,
			active_special_events,
			active_company_arcs,
			current_trade_date
		)

	return {
		"intel_level": resolved_intel_level,
		"outlets": outlet_rows,
		"feeds": feeds
	}


func _build_outlet_feed(
	run_state,
	outlet: Dictionary,
	feed_data: Dictionary,
	company_row_lookup: Dictionary,
	market_history: Array,
	event_history: Array,
	active_special_events: Array,
	active_company_arcs: Array,
	current_trade_date: Dictionary
) -> Dictionary:
	var articles: Array = []
	var seen_ids: Dictionary = {}
	var outlet_level: int = int(outlet.get("intel_level", 1))
	var article_limit: int = int(feed_data.get("article_limit", 12))

	for article_value in _build_hidden_arc_articles(run_state, outlet, feed_data, company_row_lookup, active_company_arcs, current_trade_date):
		_append_unique_article(articles, seen_ids, article_value)
	for article_value in _build_active_special_articles(outlet, feed_data, company_row_lookup, active_special_events, current_trade_date):
		_append_unique_article(articles, seen_ids, article_value)
	for article_value in _build_recent_event_articles(outlet, feed_data, company_row_lookup, event_history, current_trade_date):
		_append_unique_article(articles, seen_ids, article_value)

	var market_wrap: Dictionary = _build_market_wrap_article(outlet, feed_data, market_history, current_trade_date)
	if not market_wrap.is_empty():
		_append_unique_article(articles, seen_ids, market_wrap)

	articles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a.get("priority", 0.0)) == float(b.get("priority", 0.0)):
			if int(a.get("day_index", -1)) == int(b.get("day_index", -1)):
				return str(a.get("headline", "")) < str(b.get("headline", ""))
			return int(a.get("day_index", -1)) > int(b.get("day_index", -1))
		return float(a.get("priority", 0.0)) > float(b.get("priority", 0.0))
	)
	if articles.size() > article_limit:
		articles = articles.slice(0, article_limit)

	return {
		"outlet_id": str(outlet.get("id", "")),
		"outlet_label": str(outlet.get("label", "")),
		"intel_level": outlet_level,
		"tagline": str(outlet.get("tagline", "")),
		"summary": str(outlet.get("summary", "")),
		"articles": articles
	}


func _build_hidden_arc_articles(
	_run_state,
	outlet: Dictionary,
	feed_data: Dictionary,
	company_row_lookup: Dictionary,
	active_company_arcs: Array,
	current_trade_date: Dictionary
) -> Array:
	var outlet_level: int = int(outlet.get("intel_level", 1))
	if outlet_level < 4:
		return []

	var articles: Array = []
	for arc_value in active_company_arcs:
		var arc: Dictionary = arc_value
		if str(arc.get("phase_visibility", "visible")) != "hidden":
			continue

		var company_id: String = str(arc.get("target_company_id", ""))
		var row: Dictionary = company_row_lookup.get(company_id, {})
		var context: Dictionary = _build_event_context(arc, row)
		var hidden_flag: String = str(arc.get("hidden_flag", "smart_money_accumulation"))
		var template_group: Dictionary = feed_data.get("hidden_phase_templates", {}).get(hidden_flag, {})
		var headline: String = _render_template(
			_pick_from_pool(template_group.get("headline", []), "%s|headline|%s" % [company_id, hidden_flag]),
			context
		)
		var deck: String = _render_template(
			_pick_from_pool(template_group.get("deck", []), "%s|deck|%s" % [company_id, hidden_flag]),
			context
		)
		var body: String = _join_sentences([
			str(deck),
			_render_template(_pick_from_pool(feed_data.get("family_lines", {}).get("company_arc", []), company_id), context),
			_render_template(_pick_from_pool(feed_data.get("scope_lines", {}).get("company", []), company_id), context),
			_render_template(_pick_from_pool(feed_data.get("intel_lines", {}).get("4", []), company_id), context),
			_render_template(_pick_from_pool(feed_data.get("tone_lines", {}).get(str(arc.get("tone", "mixed")), []), company_id), context)
		])
		articles.append({
			"id": "hidden_arc|%s|%s" % [company_id, str(arc.get("arc_id", ""))],
			"headline": _compose_headline(outlet, feed_data, headline, "headline|%s" % company_id),
			"deck": deck,
			"body": body,
			"day_index": int(arc.get("start_day_index", -1)),
			"trade_date": current_trade_date.duplicate(true),
			"progress_label": str(feed_data.get("progress_labels", {}).get("early", "Early read")),
			"category": str(arc.get("category", "company")),
			"tone": str(arc.get("tone", "mixed")),
			"target_company_id": company_id,
			"target_ticker": str(context.get("target_ticker", "")),
			"target_company_name": str(context.get("target_company_name", "")),
			"target_sector_id": str(context.get("target_sector_id", "")),
			"sector_name": str(context.get("sector_name", "")),
			"person_name": "",
			"priority": 4.0
		})

	return articles


func _build_active_special_articles(
	outlet: Dictionary,
	feed_data: Dictionary,
	_company_row_lookup: Dictionary,
	active_special_events: Array,
	current_trade_date: Dictionary
) -> Array:
	var outlet_level: int = int(outlet.get("intel_level", 1))
	var articles: Array = []
	var current_day_index: int = int(current_trade_date.get("day_index", current_trade_date.get("day", 0)))

	for event_value in active_special_events:
		var event_data: Dictionary = event_value
		var start_day_index: int = int(event_data.get("start_day_index", current_day_index))
		var duration_days: int = max(int(event_data.get("duration_days", 1)), 1)
		var elapsed_days: int = max(current_day_index - start_day_index + 1, 1)
		var progress_ratio: float = clamp(float(elapsed_days) / float(duration_days), 0.0, 1.0)
		var required_level: int = _intel_requirement_for_progress(progress_ratio)
		if outlet_level < required_level:
			continue

		var progress_key: String = _progress_key_for_ratio(progress_ratio)
		var context: Dictionary = _build_event_context(event_data, {})
		var deck: String = str(event_data.get("headline_detail", event_data.get("description", "")))
		var body: String = _join_sentences([
			str(event_data.get("description", "")),
			_render_template(_pick_from_pool(feed_data.get("family_lines", {}).get(str(event_data.get("event_family", "special")), []), str(event_data.get("event_id", ""))), context),
			_render_template(_pick_from_pool(feed_data.get("scope_lines", {}).get(str(event_data.get("scope", "market")), []), str(event_data.get("event_id", ""))), context),
			_render_template(_pick_from_pool(feed_data.get("intel_lines", {}).get(str(outlet_level), []), str(event_data.get("event_id", ""))), context),
			_render_template(_pick_from_pool(feed_data.get("tone_lines", {}).get(str(event_data.get("tone", "mixed")), []), str(event_data.get("event_id", ""))), context)
		])
		articles.append({
			"id": "active_special|%s|%s" % [str(event_data.get("event_id", "")), start_day_index],
			"headline": _compose_headline(outlet, feed_data, str(event_data.get("headline", "")), "special|%s" % str(event_data.get("event_id", ""))),
			"deck": deck,
			"body": body,
			"day_index": start_day_index,
			"trade_date": event_data.get("trade_date", current_trade_date).duplicate(true),
			"progress_label": str(feed_data.get("progress_labels", {}).get(progress_key, "Developing")),
			"category": str(event_data.get("category", "special")),
			"tone": str(event_data.get("tone", "mixed")),
			"target_company_id": "",
			"target_ticker": "",
			"target_company_name": "",
			"target_sector_id": str(context.get("target_sector_id", "")),
			"sector_name": str(context.get("sector_name", "")),
			"person_name": "",
			"priority": 3.0 + (1.0 - progress_ratio)
		})

	return articles


func _build_recent_event_articles(
	outlet: Dictionary,
	feed_data: Dictionary,
	company_row_lookup: Dictionary,
	event_history: Array,
	current_trade_date: Dictionary
) -> Array:
	var outlet_level: int = int(outlet.get("intel_level", 1))
	var current_day_index: int = int(current_trade_date.get("day_index", current_trade_date.get("day", 0)))
	var recent_history: Array = event_history.duplicate(true)
	recent_history.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("day_index", -1)) > int(b.get("day_index", -1))
	)
	if recent_history.size() > MAX_EVENT_LOOKBACK:
		recent_history = recent_history.slice(0, MAX_EVENT_LOOKBACK)

	var articles: Array = []
	for event_value in recent_history:
		var event_data: Dictionary = event_value
		var age_days: int = max(current_day_index - int(event_data.get("day_index", current_day_index)), 0)
		var required_level: int = _intel_requirement_for_history_age(age_days)
		if outlet_level < required_level:
			continue

		var company_id: String = str(event_data.get("target_company_id", ""))
		var row: Dictionary = company_row_lookup.get(company_id, {})
		var context: Dictionary = _build_event_context(event_data, row)
		var progress_key: String = _progress_key_for_history_age(age_days)
		var deck: String = str(event_data.get("headline_detail", event_data.get("description", "")))
		var body: String = _join_sentences([
			str(event_data.get("description", "")),
			_render_template(_pick_from_pool(feed_data.get("family_lines", {}).get(str(event_data.get("event_family", "company")), []), str(event_data.get("event_id", ""))), context),
			_render_template(_pick_from_pool(feed_data.get("scope_lines", {}).get(str(event_data.get("scope", "company")), []), str(event_data.get("event_id", ""))), context),
			_render_template(_pick_from_pool(feed_data.get("intel_lines", {}).get(str(outlet_level), []), str(event_data.get("event_id", ""))), context),
			_render_template(_pick_from_pool(feed_data.get("tone_lines", {}).get(str(event_data.get("tone", "mixed")), []), str(event_data.get("event_id", ""))), context)
		])
		articles.append({
			"id": "event_history|%s|%s|%s" % [
				str(event_data.get("event_id", "")),
				int(event_data.get("day_index", -1)),
				company_id
			],
			"headline": _compose_headline(outlet, feed_data, str(event_data.get("headline", "")), "history|%s|%s" % [str(event_data.get("event_id", "")), company_id]),
			"deck": deck,
			"body": body,
			"day_index": int(event_data.get("day_index", -1)),
			"trade_date": event_data.get("trade_date", current_trade_date).duplicate(true),
			"progress_label": str(feed_data.get("progress_labels", {}).get(progress_key, "Public recap")),
			"category": str(event_data.get("category", "company")),
			"tone": str(event_data.get("tone", "mixed")),
			"target_company_id": company_id,
			"target_ticker": str(context.get("target_ticker", "")),
			"target_company_name": str(context.get("target_company_name", "")),
			"target_sector_id": str(context.get("target_sector_id", "")),
			"sector_name": str(context.get("sector_name", "")),
			"person_name": str(context.get("person_name", "")),
			"priority": 2.0 - min(float(age_days) * 0.08, 0.9)
		})

	return articles


func _build_market_wrap_article(
	outlet: Dictionary,
	feed_data: Dictionary,
	market_history: Array,
	current_trade_date: Dictionary
) -> Dictionary:
	if market_history.is_empty():
		return {}

	var latest_entry: Dictionary = market_history[market_history.size() - 1]
	var biggest_winner: Dictionary = latest_entry.get("biggest_winner", {})
	var biggest_loser: Dictionary = latest_entry.get("biggest_loser", {})
	var context: Dictionary = {
		"market_change": _format_percent(float(latest_entry.get("average_change_pct", 0.0))),
		"advancers": str(int(latest_entry.get("advancers", 0))),
		"decliners": str(int(latest_entry.get("decliners", 0))),
		"biggest_winner": str(biggest_winner.get("ticker", "the leaders")),
		"biggest_loser": str(biggest_loser.get("ticker", "the laggards"))
	}
	var outlet_id: String = str(outlet.get("id", "market_wrap"))
	var headline: String = _render_template(
		_pick_from_pool(feed_data.get("market_wrap_headlines", []), "%s|wrap_headline" % outlet_id),
		context
	)
	var deck: String = _render_template(
		_pick_from_pool(feed_data.get("market_wrap_decks", []), "%s|wrap_deck" % outlet_id),
		context
	)
	var body: String = _join_sentences([
		deck,
		_render_template(_pick_from_pool(feed_data.get("market_wrap_lines", []), "%s|wrap_line" % outlet_id), context),
		_render_template(_pick_from_pool(feed_data.get("intel_lines", {}).get(str(int(outlet.get("intel_level", 1))), []), "%s|wrap_intel" % outlet_id), context)
	])
	return {
		"id": "market_wrap|%s|%s" % [outlet_id, int(latest_entry.get("day_index", -1))],
		"headline": headline,
		"deck": deck,
		"body": body,
		"day_index": int(latest_entry.get("day_index", -1)),
		"trade_date": latest_entry.get("trade_date", current_trade_date).duplicate(true),
		"progress_label": str(feed_data.get("progress_labels", {}).get("recap", "Public recap")),
		"category": "market_wrap",
		"tone": "mixed",
		"target_company_id": "",
		"target_ticker": "",
		"target_company_name": "",
		"target_sector_id": "",
		"sector_name": "",
		"person_name": "",
		"priority": 1.2
	}


func _build_event_context(event_data: Dictionary, company_row: Dictionary) -> Dictionary:
	var target_sector_id: String = str(event_data.get("target_sector_id", company_row.get("sector_id", "")))
	var sector_definition: Dictionary = DataRepository.get_sector_definition(target_sector_id)
	return {
		"target_company_id": str(event_data.get("target_company_id", company_row.get("id", ""))),
		"target_ticker": str(event_data.get("target_ticker", company_row.get("ticker", ""))),
		"target_company_name": str(event_data.get("target_company_name", company_row.get("name", ""))),
		"target_sector_id": target_sector_id,
		"sector_name": str(event_data.get("sector_name", company_row.get("sector_name", sector_definition.get("name", "the sector")))),
		"person_name": str(event_data.get("person_name", "")),
		"headline": str(event_data.get("headline", "")),
		"description": str(event_data.get("description", "")),
		"category": str(event_data.get("category", "")),
		"tone": str(event_data.get("tone", "mixed"))
	}


func _append_unique_article(articles: Array, seen_ids: Dictionary, article: Dictionary) -> void:
	if article.is_empty():
		return
	var article_id: String = str(article.get("id", ""))
	if article_id.is_empty() or seen_ids.has(article_id):
		return
	seen_ids[article_id] = true
	articles.append(article)


func _compose_headline(outlet: Dictionary, feed_data: Dictionary, base_headline: String, seed_key: String) -> String:
	if base_headline.is_empty():
		return ""
	var outlet_id: String = str(outlet.get("id", ""))
	var prefix: String = str(_pick_from_pool(feed_data.get("headline_prefixes", {}).get(outlet_id, []), seed_key))
	if prefix.is_empty():
		return base_headline
	return "%s: %s" % [prefix, base_headline]


func _pick_from_pool(pool: Array, seed_key: String) -> String:
	if pool.is_empty():
		return ""
	var pool_index: int = int(abs(hash(seed_key))) % pool.size()
	return str(pool[pool_index])


func _render_template(template: String, context: Dictionary) -> String:
	var rendered: String = template
	for context_key in context.keys():
		var placeholder: String = "{%s}" % str(context_key)
		rendered = rendered.replace(placeholder, str(context.get(context_key, "")))
	return rendered


func _join_sentences(lines: Array) -> String:
	var sentences: Array = []
	for line_value in lines:
		var sentence: String = str(line_value).strip_edges()
		if sentence.is_empty():
			continue
		if not sentence.ends_with(".") and not sentence.ends_with("!") and not sentence.ends_with("?"):
			sentence += "."
		sentences.append(sentence)
	return " ".join(sentences)


func _progress_key_for_ratio(progress_ratio: float) -> String:
	if progress_ratio <= 0.24:
		return "early"
	if progress_ratio <= 0.58:
		return "developing"
	if progress_ratio <= 0.88:
		return "follow_through"
	return "recap"


func _progress_key_for_history_age(age_days: int) -> String:
	if age_days <= 0:
		return "developing"
	if age_days <= 2:
		return "follow_through"
	return "recap"


func _intel_requirement_for_progress(progress_ratio: float) -> int:
	if progress_ratio <= 0.24:
		return 4
	if progress_ratio <= 0.52:
		return 3
	if progress_ratio <= 0.82:
		return 2
	return 1


func _intel_requirement_for_history_age(age_days: int) -> int:
	if age_days <= 0:
		return 3
	if age_days <= 2:
		return 2
	return 1


func _format_percent(value: float) -> String:
	return "%+.2f%%" % (value * 100.0)
