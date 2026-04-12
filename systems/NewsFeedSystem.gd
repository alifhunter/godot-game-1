extends RefCounted

const MAX_EVENT_LOOKBACK := 18
const MAX_RECENT_ARTICLES_PER_SOURCE := 2


func build_news_snapshot(
	_run_state,
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

	var market_history_lookup: Dictionary = {}
	var latest_market_entry: Dictionary = {}
	for market_entry_value in market_history:
		var market_entry: Dictionary = market_entry_value
		var day_index: int = int(market_entry.get("day_index", -1))
		market_history_lookup[day_index] = market_entry.duplicate(true)
		latest_market_entry = market_entry.duplicate(true)

	var outlet_rows: Array = []
	var feeds: Dictionary = {}
	for outlet_value in outlets:
		var outlet: Dictionary = outlet_value.duplicate(true)
		var outlet_id: String = str(outlet.get("id", ""))
		var outlet_level: int = int(outlet.get("intel_level", 1))
		outlet["unlocked"] = outlet_level <= resolved_intel_level
		outlet_rows.append(outlet)
		feeds[outlet_id] = _build_outlet_feed(
			outlet,
			feed_data,
			company_row_lookup,
			market_history_lookup,
			latest_market_entry,
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
	outlet: Dictionary,
	feed_data: Dictionary,
	company_row_lookup: Dictionary,
	market_history_lookup: Dictionary,
	latest_market_entry: Dictionary,
	event_history: Array,
	active_special_events: Array,
	active_company_arcs: Array,
	current_trade_date: Dictionary
) -> Dictionary:
	var articles: Array = []
	var seen_ids: Dictionary = {}
	var outlet_level: int = int(outlet.get("intel_level", 1))
	var article_limit: int = int(feed_data.get("article_limit", 12))

	for article_value in _build_hidden_arc_articles(
		outlet,
		feed_data,
		company_row_lookup,
		market_history_lookup,
		latest_market_entry,
		active_company_arcs,
		current_trade_date
	):
		_append_unique_article(articles, seen_ids, article_value)
	for article_value in _build_active_special_articles(
		outlet,
		feed_data,
		company_row_lookup,
		market_history_lookup,
		latest_market_entry,
		active_special_events,
		current_trade_date
	):
		_append_unique_article(articles, seen_ids, article_value)
	for article_value in _build_recent_event_articles(
		outlet,
		feed_data,
		company_row_lookup,
		market_history_lookup,
		latest_market_entry,
		event_history,
		current_trade_date
	):
		_append_unique_article(articles, seen_ids, article_value)

	var market_wrap: Dictionary = _build_market_wrap_article(
		outlet,
		feed_data,
		latest_market_entry,
		current_trade_date
	)
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
	outlet: Dictionary,
	feed_data: Dictionary,
	company_row_lookup: Dictionary,
	market_history_lookup: Dictionary,
	latest_market_entry: Dictionary,
	active_company_arcs: Array,
	current_trade_date: Dictionary
) -> Array:
	if int(outlet.get("intel_level", 1)) < 4:
		return []

	var articles: Array = []
	for arc_value in active_company_arcs:
		var arc: Dictionary = arc_value
		if str(arc.get("phase_visibility", "visible")) != "hidden":
			continue

		var company_id: String = str(arc.get("target_company_id", ""))
		var row: Dictionary = company_row_lookup.get(company_id, {})
		var article_id: String = "hidden_arc|%s" % str(arc.get("arc_id", ""))
		var context: Dictionary = _build_story_context(
			feed_data,
			arc,
			row,
			_market_entry_for_day(market_history_lookup, latest_market_entry, int(current_trade_date.get("day_index", -1))),
			current_trade_date,
			"whisper",
			article_id
		)
		articles.append(_build_article_record(
			outlet,
			feed_data,
			arc,
			context,
			"whisper",
			"early",
			current_trade_date,
			int(current_trade_date.get("day_index", -1)),
			article_id,
			4.1
		))

	return articles


func _build_active_special_articles(
	outlet: Dictionary,
	feed_data: Dictionary,
	_company_row_lookup: Dictionary,
	market_history_lookup: Dictionary,
	latest_market_entry: Dictionary,
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
		var stage_key: String = _stage_key_for_progress(progress_key)
		var article_id: String = "active_special|%s|%s" % [str(event_data.get("event_id", "")), start_day_index]
		var context: Dictionary = _build_story_context(
			feed_data,
			event_data,
			{},
			_market_entry_for_day(market_history_lookup, latest_market_entry, current_day_index),
			current_trade_date,
			stage_key,
			article_id
		)
		articles.append(_build_article_record(
			outlet,
			feed_data,
			event_data,
			context,
			stage_key,
			progress_key,
			current_trade_date,
			current_day_index,
			article_id,
			3.2 + (1.0 - progress_ratio)
		))

	return articles


func _build_recent_event_articles(
	outlet: Dictionary,
	feed_data: Dictionary,
	company_row_lookup: Dictionary,
	market_history_lookup: Dictionary,
	latest_market_entry: Dictionary,
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

	var source_counts: Dictionary = {}
	var articles: Array = []
	for event_value in recent_history:
		var event_data: Dictionary = event_value
		var age_days: int = max(current_day_index - int(event_data.get("day_index", current_day_index)), 0)
		var required_level: int = _intel_requirement_for_history_age(age_days)
		if outlet_level < required_level:
			continue

		var source_key: String = "%s|%s|%s|%s" % [
			str(event_data.get("event_id", "")),
			str(event_data.get("target_company_id", "")),
			str(event_data.get("target_sector_id", "")),
			str(event_data.get("person_name", ""))
		]
		source_counts[source_key] = int(source_counts.get(source_key, 0))
		if int(source_counts.get(source_key, 0)) >= MAX_RECENT_ARTICLES_PER_SOURCE:
			continue

		var company_id: String = str(event_data.get("target_company_id", ""))
		var row: Dictionary = company_row_lookup.get(company_id, {})
		var progress_key: String = _progress_key_for_history_age(age_days)
		var stage_key: String = _stage_key_for_progress(progress_key)
		var article_id: String = "event_history|%s|%s|%s|%s" % [
			str(event_data.get("event_id", "")),
			int(event_data.get("day_index", -1)),
			company_id,
			str(outlet.get("id", ""))
		]
		var event_trade_date: Dictionary = event_data.get("trade_date", current_trade_date).duplicate(true)
		var context: Dictionary = _build_story_context(
			feed_data,
			event_data,
			row,
			_market_entry_for_day(market_history_lookup, latest_market_entry, int(event_data.get("day_index", current_day_index))),
			event_trade_date,
			stage_key,
			article_id
		)
		articles.append(_build_article_record(
			outlet,
			feed_data,
			event_data,
			context,
			stage_key,
			progress_key,
			event_trade_date,
			int(event_data.get("day_index", -1)),
			article_id,
			2.2 - min(float(age_days) * 0.08, 0.9)
		))
		source_counts[source_key] = int(source_counts.get(source_key, 0)) + 1

	return articles


func _build_market_wrap_article(
	outlet: Dictionary,
	feed_data: Dictionary,
	latest_market_entry: Dictionary,
	current_trade_date: Dictionary
) -> Dictionary:
	if latest_market_entry.is_empty():
		return {}

	var market_wrap_source: Dictionary = latest_market_entry.duplicate(true)
	market_wrap_source["scope"] = "market"
	market_wrap_source["category"] = "market_wrap"
	market_wrap_source["event_family"] = "market"
	market_wrap_source["tone"] = _tone_from_change(float(latest_market_entry.get("average_change_pct", 0.0)))
	var article_id: String = "market_wrap|%s|%s" % [
		str(outlet.get("id", "market_wrap")),
		int(latest_market_entry.get("day_index", -1))
	]
	var context: Dictionary = _build_story_context(
		feed_data,
		market_wrap_source,
		{},
		latest_market_entry,
		latest_market_entry.get("trade_date", current_trade_date).duplicate(true),
		"market_wrap",
		article_id
	)
	return _build_article_record(
		outlet,
		feed_data,
		market_wrap_source,
		context,
		"market_wrap",
		"recap",
		latest_market_entry.get("trade_date", current_trade_date).duplicate(true),
		int(latest_market_entry.get("day_index", -1)),
		article_id,
		1.2
	)


func _build_article_record(
	outlet: Dictionary,
	feed_data: Dictionary,
	source_data: Dictionary,
	context: Dictionary,
	stage_key: String,
	progress_key: String,
	trade_date: Dictionary,
	day_index: int,
	article_id: String,
	priority: float
) -> Dictionary:
	var voice_profile: Dictionary = _voice_profile(feed_data, outlet)
	var voice_seed: String = "%s|%s" % [str(outlet.get("id", "")), article_id]
	var headline_template: String = _pick_voice_template(voice_profile, "headline_templates", stage_key, "%s|headline" % voice_seed)
	var deck_template: String = _pick_voice_template(voice_profile, "deck_templates", stage_key, "%s|deck" % voice_seed)
	var headline: String = _render_template(headline_template, context)
	var deck: String = _render_template(deck_template, context)
	if headline.is_empty():
		headline = str(source_data.get("headline", context.get("focus_label", "Market note")))
	if deck.is_empty():
		deck = str(context.get("detail_blend", context.get("driver_phrase", "")))

	return {
		"id": article_id,
		"headline": _compose_headline(outlet, voice_profile, headline, "%s|prefix" % voice_seed),
		"deck": deck,
		"body": _build_article_body(voice_profile, context, stage_key, voice_seed),
		"day_index": day_index,
		"trade_date": trade_date.duplicate(true),
		"progress_label": str(feed_data.get("progress_labels", {}).get(progress_key, "Developing")),
		"category": str(source_data.get("category", "")),
		"tone": str(context.get("tone", source_data.get("tone", "mixed"))),
		"target_company_id": str(context.get("target_company_id", "")),
		"target_ticker": str(context.get("target_ticker", "")),
		"target_company_name": str(context.get("target_company_name", "")),
		"target_sector_id": str(context.get("target_sector_id", "")),
		"sector_name": str(context.get("sector_name", "")),
		"person_name": str(context.get("person_name", "")),
		"priority": priority
	}


func _build_article_body(voice_profile: Dictionary, context: Dictionary, stage_key: String, seed_key: String) -> String:
	var lead_template: String = _pick_voice_template(voice_profile, "lead_templates", stage_key, "%s|lead" % seed_key)
	var context_template: String = str(_pick_from_pool(voice_profile.get("context_templates", []), "%s|context" % seed_key))
	var impact_template: String = str(_pick_from_pool(voice_profile.get("impact_templates", []), "%s|impact" % seed_key))

	var paragraphs: Array = []
	var lead_paragraph: String = _join_sentences([_render_template(lead_template, context)])
	var context_paragraph: String = _join_sentences([_render_template(context_template, context)])
	var impact_paragraph: String = _join_sentences([_render_template(impact_template, context)])
	if not lead_paragraph.is_empty():
		paragraphs.append(lead_paragraph)
	if not context_paragraph.is_empty():
		paragraphs.append(context_paragraph)
	if not impact_paragraph.is_empty():
		paragraphs.append(impact_paragraph)
	return _join_paragraphs(paragraphs)


func _build_story_context(
	feed_data: Dictionary,
	source_data: Dictionary,
	company_row: Dictionary,
	market_entry: Dictionary,
	trade_date: Dictionary,
	stage_key: String,
	seed_key: String
) -> Dictionary:
	var tone: String = str(source_data.get("tone", "mixed"))
	if tone.is_empty():
		tone = "mixed"

	var sector_context: Dictionary = _resolve_sector_context(source_data, company_row)
	var target_company_id: String = str(source_data.get("target_company_id", company_row.get("id", "")))
	var target_ticker: String = str(source_data.get("target_ticker", company_row.get("ticker", "")))
	var target_company_name: String = str(source_data.get("target_company_name", company_row.get("name", "")))
	var target_sector_id: String = str(sector_context.get("id", ""))
	var sector_name: String = str(sector_context.get("name", "the market"))
	var scope: String = str(source_data.get("scope", "company"))
	var person_name: String = str(source_data.get("person_name", ""))

	var focus_label: String = "Index Gorengan"
	if not target_ticker.is_empty():
		focus_label = target_ticker
	elif scope == "sector" and not sector_name.is_empty():
		focus_label = sector_name
	elif not person_name.is_empty():
		focus_label = person_name
	elif scope == "market":
		focus_label = "Index Gorengan"

	var subject_label: String = "Index Gorengan"
	if not target_company_name.is_empty():
		subject_label = target_company_name
	elif scope == "sector" and not sector_name.is_empty():
		subject_label = sector_name
	elif not person_name.is_empty():
		subject_label = person_name
	var subject_reference: String = subject_label
	if not target_company_name.is_empty() and not target_ticker.is_empty():
		subject_reference = "%s (%s)" % [target_company_name, target_ticker]
	elif not target_ticker.is_empty():
		subject_reference = target_ticker

	var current_price: float = float(company_row.get("current_price", 0.0))
	var price_change_pct: float = float(company_row.get("daily_change_pct", 0.0))
	if company_row.is_empty():
		price_change_pct = float(market_entry.get("average_change_pct", 0.0))

	var advancers: int = int(market_entry.get("advancers", 0))
	var decliners: int = int(market_entry.get("decliners", 0))
	var market_change_pct: float = float(market_entry.get("average_change_pct", 0.0))
	var biggest_winner: Dictionary = market_entry.get("biggest_winner", {})
	var biggest_loser: Dictionary = market_entry.get("biggest_loser", {})
	var market_change_text: String = _format_percent(market_change_pct)
	var breadth_summary: String = "%d stocks rose while %d stocks fell" % [advancers, decliners]
	var market_state_label: String = _market_state_label(market_change_pct, advancers, decliners)

	var broker_flow: Dictionary = company_row.get("broker_flow", {})
	var flow_label: String = _flow_label(str(broker_flow.get("flow_tag", "neutral")))
	var phase_phrase: String = _phase_phrase(
		str(source_data.get("current_phase_id", source_data.get("arc_phase", ""))),
		str(source_data.get("current_phase_label", "")),
		tone,
		stage_key
	)
	var price_action_label: String = _price_action_label(price_change_pct, company_row.is_empty())
	var detail_hint: String = _sanitize_fragment(str(source_data.get("headline_detail", source_data.get("description", ""))))
	var whisper_phrase: String = _pick_reference_signal(feed_data, "whisper_hedges", "%s|whisper" % seed_key)
	var desk_watch: String = _pick_reference_signal(feed_data, "desk_watch", "%s|desk" % seed_key)
	var formal_phrase: String = _pick_reference_signal(feed_data, "formal_markers", "%s|formal" % seed_key)
	var analysis_phrase: String = _pick_reference_signal(feed_data, "analysis_markers", "%s|analysis" % seed_key)
	var reaction_phrase: String = _pick_reference_signal(feed_data, "reaction_markers", "%s|reaction" % seed_key)
	var market_jargon: String = _pick_reference_signal(feed_data, "market_jargon", "%s|jargon" % seed_key)
	var driver_phrase: String = _pick_driver_phrase(feed_data, source_data, tone, "%s|driver" % seed_key)
	var watch_phrase: String = _pick_watch_phrase(feed_data, stage_key, "%s|watch" % seed_key)

	return {
		"target_company_id": target_company_id,
		"target_ticker": target_ticker,
		"target_company_name": target_company_name,
		"target_sector_id": target_sector_id,
		"sector_name": sector_name,
		"person_name": person_name,
		"scope": scope,
		"tone": tone,
		"focus_label": focus_label,
		"subject_label": subject_label,
		"subject_reference": subject_reference,
		"headline_hint": _sanitize_fragment(str(source_data.get("headline", ""))),
		"detail_hint": detail_hint,
		"detail_blend": detail_hint if not detail_hint.is_empty() else driver_phrase,
		"current_price": _format_price(current_price),
		"price_action_label": price_action_label,
		"market_change": market_change_text,
		"market_state_label": market_state_label,
		"breadth_summary": breadth_summary,
		"advancers": str(advancers),
		"decliners": str(decliners),
		"biggest_winner": str(biggest_winner.get("ticker", "the leaders")),
		"biggest_loser": str(biggest_loser.get("ticker", "the laggards")),
		"whisper_phrase": whisper_phrase,
		"desk_watch": desk_watch,
		"formal_phrase": formal_phrase,
		"analysis_phrase": analysis_phrase,
		"reaction_phrase": reaction_phrase,
		"market_jargon": market_jargon,
		"driver_phrase": driver_phrase,
		"watch_phrase": watch_phrase,
		"phase_phrase": phase_phrase,
		"flow_label": flow_label,
		"stance_word": _stance_word(tone),
		"trade_day_label": _format_trade_day_label(trade_date)
	}


func _resolve_sector_context(source_data: Dictionary, company_row: Dictionary) -> Dictionary:
	var target_sector_id: String = str(source_data.get("target_sector_id", company_row.get("sector_id", "")))
	if target_sector_id.is_empty():
		target_sector_id = _primary_sector_id_from_source(source_data)

	var sector_definition: Dictionary = DataRepository.get_sector_definition(target_sector_id)
	var sector_name: String = str(source_data.get("sector_name", company_row.get("sector_name", sector_definition.get("name", ""))))
	if sector_name.is_empty():
		sector_name = "the market"
	return {
		"id": target_sector_id,
		"name": sector_name
	}


func _primary_sector_id_from_source(source_data: Dictionary) -> String:
	var sector_biases: Dictionary = source_data.get("sector_biases", {})
	var strongest_sector_id: String = ""
	var strongest_bias: float = -1.0
	for sector_id_value in sector_biases.keys():
		var sector_id: String = str(sector_id_value)
		var bias_value: float = absf(float(sector_biases.get(sector_id, 0.0)))
		if bias_value > strongest_bias:
			strongest_bias = bias_value
			strongest_sector_id = sector_id
	if not strongest_sector_id.is_empty():
		return strongest_sector_id

	var affected_sector_ids: Array = source_data.get("affected_sector_ids", [])
	if not affected_sector_ids.is_empty():
		return str(affected_sector_ids[0])
	return ""


func _voice_profile(feed_data: Dictionary, outlet: Dictionary) -> Dictionary:
	var voice_profiles: Dictionary = feed_data.get("voice_profiles", {})
	var voice_id: String = str(outlet.get("voice", outlet.get("id", "")))
	return voice_profiles.get(voice_id, {})


func _pick_voice_template(voice_profile: Dictionary, section_key: String, stage_key: String, seed_key: String) -> String:
	var template_groups: Dictionary = voice_profile.get(section_key, {})
	var pool: Array = template_groups.get(stage_key, [])
	if pool.is_empty():
		pool = template_groups.get("recap", [])
	if pool.is_empty():
		return ""
	return str(_pick_from_pool(pool, seed_key))


func _pick_reference_signal(feed_data: Dictionary, signal_key: String, seed_key: String) -> String:
	var reference_signals: Dictionary = feed_data.get("reference_signals", {})
	return str(_pick_from_pool(reference_signals.get(signal_key, []), seed_key))


func _pick_driver_phrase(feed_data: Dictionary, source_data: Dictionary, tone: String, seed_key: String) -> String:
	var driver_phrases: Dictionary = feed_data.get("driver_phrases", {})
	var category: String = str(source_data.get("category", ""))
	var event_family: String = str(source_data.get("event_family", ""))
	var scope: String = str(source_data.get("scope", ""))
	var keys: Array = []
	if category == "market_wrap":
		keys.append("market_wrap")
	if not category.is_empty():
		keys.append("%s_%s" % [category, tone])
		keys.append(category)
	if event_family == "company_arc":
		keys.append("company_arc_%s" % tone)
	if not event_family.is_empty():
		keys.append("%s_%s" % [event_family, tone])
	if scope == "market":
		keys.append("special_%s" % tone)
	if not scope.is_empty():
		keys.append("%s_%s" % [scope, tone])
	keys.append("fallback")

	for key_value in keys:
		var key: String = str(key_value)
		if not driver_phrases.has(key):
			continue
		var picked_line: String = str(_pick_from_pool(driver_phrases.get(key, []), "%s|%s" % [seed_key, key]))
		if not picked_line.is_empty():
			return picked_line
	return ""


func _pick_watch_phrase(feed_data: Dictionary, stage_key: String, seed_key: String) -> String:
	var watch_phrases: Dictionary = feed_data.get("watch_phrases", {})
	var pool: Array = watch_phrases.get(stage_key, [])
	if pool.is_empty():
		pool = watch_phrases.get("recap", [])
	return str(_pick_from_pool(pool, seed_key))


func _market_entry_for_day(market_history_lookup: Dictionary, latest_market_entry: Dictionary, day_index: int) -> Dictionary:
	if market_history_lookup.has(day_index):
		return market_history_lookup[day_index].duplicate(true)
	return latest_market_entry.duplicate(true)


func _append_unique_article(articles: Array, seen_ids: Dictionary, article: Dictionary) -> void:
	if article.is_empty():
		return
	var article_id: String = str(article.get("id", ""))
	if article_id.is_empty() or seen_ids.has(article_id):
		return
	seen_ids[article_id] = true
	articles.append(article)


func _compose_headline(outlet: Dictionary, voice_profile: Dictionary, base_headline: String, seed_key: String) -> String:
	if base_headline.is_empty():
		return ""
	var prefix: String = str(_pick_from_pool(voice_profile.get("headline_prefixes", []), seed_key))
	if prefix.is_empty():
		prefix = str(outlet.get("label", ""))
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


func _join_paragraphs(paragraphs: Array) -> String:
	var filtered: Array = []
	for paragraph_value in paragraphs:
		var paragraph: String = str(paragraph_value).strip_edges()
		if paragraph.is_empty():
			continue
		filtered.append(paragraph)
	return "\n\n".join(filtered)


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


func _stage_key_for_progress(progress_key: String) -> String:
	match progress_key:
		"early":
			return "whisper"
		"developing":
			return "confirmation"
		"follow_through":
			return "analysis"
		_:
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


func _format_price(value: float) -> String:
	if is_zero_approx(value):
		return ""
	return "Rp %s" % String.num(value, 0)


func _format_abs_percent(value: float) -> String:
	return "%0.2f%%" % (absf(value) * 100.0)


func _price_action_label(change_pct: float, market_fallback: bool) -> String:
	if absf(change_pct) < 0.0015:
		return "moving marginally %s" % _format_percent(change_pct)
	if change_pct > 0.0:
		return "up %s" % _format_abs_percent(change_pct)
	if market_fallback:
		return "closing weaker by %s" % _format_abs_percent(change_pct)
	return "correcting %s" % _format_abs_percent(change_pct)


func _flow_label(flow_tag: String) -> String:
	match flow_tag:
		"accumulation":
			return "buyers had the edge"
		"distribution":
			return "sellers had the edge"
		"neutral":
			return "trading stayed balanced"
		_:
			return "buyers and sellers were both active"


func _phase_phrase(phase_id: String, phase_label: String, tone: String, stage_key: String) -> String:
	var normalized_phase_id: String = phase_id.to_lower()
	match normalized_phase_id:
		"accumulation":
			return "an early buying phase"
		"distribution":
			return "a selling phase"
		"breakout":
			return "an early breakout phase"
		"breakdown":
			return "a breakdown phase"
		"sideways":
			return "a flat phase"
		"decline":
			return "a weaker phase"
		_:
			if not phase_label.is_empty():
				return "%s phase" % phase_label.to_lower()

	match stage_key:
		"whisper":
			return "an early stage"
		"confirmation":
			return "a confirmation stage"
		"analysis":
			return "a later stage"
		"market_wrap":
			return "the close"
		_:
			return "a recap stage" if tone != "positive" else "a review stage"


func _market_state_label(market_change_pct: float, advancers: int, decliners: int) -> String:
	if market_change_pct > 0.004 and advancers > decliners:
		return "mostly positive"
	if market_change_pct < -0.004 and decliners > advancers:
		return "mostly negative"
	if abs(advancers - decliners) <= 2 and absf(market_change_pct) < 0.0025:
		return "mixed"
	if advancers > decliners:
		return "slightly positive"
	if decliners > advancers:
		return "slightly negative"
	return "unclear"


func _tone_from_change(change_pct: float) -> String:
	if change_pct > 0.002:
		return "positive"
	if change_pct < -0.002:
		return "negative"
	return "mixed"


func _stance_word(tone: String) -> String:
	match tone:
		"positive":
			return "more hopeful"
		"negative":
			return "more cautious"
		_:
			return "still unclear"


func _sanitize_fragment(text: String) -> String:
	return text.strip_edges().trim_suffix(".")


func _format_trade_day_label(trade_date: Dictionary) -> String:
	if trade_date.is_empty():
		return ""
	var weekday: String = str(trade_date.get("weekday_name", ""))
	var day_number: int = int(trade_date.get("day", 0))
	var month_number: int = int(trade_date.get("month", 0))
	var year_number: int = int(trade_date.get("year", 0))
	if weekday.is_empty():
		return "%02d/%02d/%d" % [day_number, month_number, year_number]
	return "%s, %02d/%02d/%d" % [weekday, day_number, month_number, year_number]
