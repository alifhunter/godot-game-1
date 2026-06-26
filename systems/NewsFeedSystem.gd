extends RefCounted

const MAX_EVENT_LOOKBACK := 18
const MAX_RECENT_ARTICLES_PER_SOURCE := 2
const MAX_GENERATED_DOSSIER_NEWS_SOURCES := 6
const MAX_GENERATED_DOSSIER_NEWS_ARTICLES_PER_OUTLET := 4
const GENERATED_DOSSIER_NEWS_SOURCE_SYSTEM_ID := "company_story_dossier"
const RELATIONSHIP_GRAPH_SOURCE_SYSTEM_ID := "company_relationship_graph"
const NEWS_ACCESS_MODEL := "free_topic_coverage"
const PUBLIC_NEWS_DEPTH_LEVEL := 1
const COVERAGE_MARKET_WRAP_CHATTER := "market_wrap_chatter"
const COVERAGE_MACRO_COMMODITY_SECTOR := "macro_commodity_sector"
const COVERAGE_CORPORATE_ACTION_FILING := "corporate_action_filing"
const COVERAGE_EARLY_SIGNAL := "early_signal"


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
	var resolved_intel_level: int = PUBLIC_NEWS_DEPTH_LEVEL
	if unlocked_intel_level > 0:
		resolved_intel_level = PUBLIC_NEWS_DEPTH_LEVEL

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
	var current_day_index: int = int(current_trade_date.get("day_index", current_trade_date.get("day", 0)))
	var story_memory: Dictionary = _build_story_memory(event_history, active_company_arcs, current_day_index)
	var generated_news_sources: Array = _build_generated_dossier_news_sources(
		_run_state,
		company_row_lookup,
		current_trade_date,
		current_day_index
	)

	var outlet_rows: Array = []
	var feeds: Dictionary = {}
	for outlet_value in outlets:
		var outlet: Dictionary = _normalized_outlet(outlet_value)
		var outlet_id: String = str(outlet.get("id", ""))
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
			current_trade_date,
			story_memory,
			generated_news_sources
		)

	return {
		"intel_level": resolved_intel_level,
		"public_depth_level": PUBLIC_NEWS_DEPTH_LEVEL,
		"access_model": NEWS_ACCESS_MODEL,
		"outlets": outlet_rows,
		"feeds": feeds
	}


func _normalized_outlet(outlet_value: Dictionary) -> Dictionary:
	var outlet: Dictionary = outlet_value.duplicate(true)
	outlet["legacy_intel_level"] = int(outlet.get("intel_level", PUBLIC_NEWS_DEPTH_LEVEL))
	outlet["intel_level"] = PUBLIC_NEWS_DEPTH_LEVEL
	outlet["public_depth_level"] = PUBLIC_NEWS_DEPTH_LEVEL
	outlet["unlocked"] = true
	outlet["access_model"] = NEWS_ACCESS_MODEL
	if str(outlet.get("coverage_type", "")).strip_edges().is_empty():
		outlet["coverage_type"] = _default_coverage_type_for_outlet_id(str(outlet.get("id", "")))
	if _unique_string_array(outlet.get("topic_ids", [])).is_empty():
		outlet["topic_ids"] = _default_topic_ids_for_coverage(str(outlet.get("coverage_type", "")))
	return outlet


func _default_coverage_type_for_outlet_id(outlet_id: String) -> String:
	match outlet_id:
		"waduh_finance":
			return COVERAGE_MACRO_COMMODITY_SECTOR
		"harian_investor":
			return COVERAGE_CORPORATE_ACTION_FILING
		"ordal_news":
			return COVERAGE_EARLY_SIGNAL
		_:
			return COVERAGE_MARKET_WRAP_CHATTER


func _default_topic_ids_for_coverage(coverage_type: String) -> Array:
	match coverage_type:
		COVERAGE_MACRO_COMMODITY_SECTOR:
			return ["macro", "commodity", "sector", "subsector", "policy"]
		COVERAGE_CORPORATE_ACTION_FILING:
			return ["corporate_action", "filing", "earnings", "meeting", "index_review"]
		COVERAGE_EARLY_SIGNAL:
			return ["rumor", "early_signal", "market_whisper", "watchlist"]
		_:
			return ["market_wrap", "public_mover", "chatter", "sentiment"]


func _outlet_has_coverage(outlet: Dictionary, coverage_type: String) -> bool:
	var outlet_coverage_type: String = str(outlet.get("coverage_type", "")).strip_edges()
	if outlet_coverage_type.is_empty():
		outlet_coverage_type = _default_coverage_type_for_outlet_id(str(outlet.get("id", "")))
	if coverage_type.is_empty():
		return true
	if outlet_coverage_type == coverage_type:
		return true
	for coverage_value in outlet.get("coverage_types", []):
		if str(coverage_value) == coverage_type:
			return true
	return false


func _outlet_covers_source(outlet: Dictionary, source_data: Dictionary) -> bool:
	return _outlet_has_coverage(outlet, _source_coverage_type(source_data))


func _source_coverage_type(source_data: Dictionary) -> String:
	var explicit_coverage: String = str(source_data.get("coverage_type", "")).strip_edges()
	if not explicit_coverage.is_empty():
		return explicit_coverage
	var generated_surface_id: String = str(source_data.get("generated_surface_id", ""))
	match generated_surface_id:
		"macro_news", "sector_news":
			return COVERAGE_MACRO_COMMODITY_SECTOR
		"company_news":
			return COVERAGE_MARKET_WRAP_CHATTER

	var category: String = str(source_data.get("category", "")).strip_edges()
	var event_family: String = str(source_data.get("event_family", "")).strip_edges()
	var visibility: String = str(source_data.get("relationship_visibility", source_data.get("visibility", ""))).strip_edges().to_lower()
	if category == "market_wrap" or category == "public_mover" or event_family == "market":
		return COVERAGE_MARKET_WRAP_CHATTER
	if category == "sector_rotation" or category == "generated_sector_news" or category == "generated_macro_news":
		return COVERAGE_MACRO_COMMODITY_SECTOR
	if category.contains("macro") or category.contains("policy") or category.contains("commodity"):
		return COVERAGE_MACRO_COMMODITY_SECTOR
	if category in ["deal_post", "pandemic", "geopolitics", "special"]:
		return COVERAGE_MACRO_COMMODITY_SECTOR
	if category.contains("rumor") or category.contains("speculation") or category.contains("whisper"):
		return COVERAGE_EARLY_SIGNAL
	if category.begins_with("index_") or category == "corporate_meeting" or not str(source_data.get("meeting_id", "")).is_empty():
		return COVERAGE_CORPORATE_ACTION_FILING
	if category.begins_with("corporate_action") or category == "earnings" or category.contains("filing"):
		return COVERAGE_CORPORATE_ACTION_FILING
	if event_family == RELATIONSHIP_GRAPH_SOURCE_SYSTEM_ID:
		return COVERAGE_CORPORATE_ACTION_FILING if visibility == "public" else COVERAGE_EARLY_SIGNAL
	if str(source_data.get("phase_visibility", "")).strip_edges() == "hidden":
		return COVERAGE_EARLY_SIGNAL
	return COVERAGE_MARKET_WRAP_CHATTER


func _source_topic_ids(source_data: Dictionary, coverage_type: String) -> Array:
	var topic_ids: Array = _unique_string_array(source_data.get("topic_ids", []))
	if not topic_ids.is_empty():
		return topic_ids
	topic_ids = _default_topic_ids_for_coverage(coverage_type)
	var category: String = str(source_data.get("category", "")).strip_edges()
	var generated_surface_id: String = str(source_data.get("generated_surface_id", "")).strip_edges()
	var scope: String = str(source_data.get("scope", "")).strip_edges()
	if not category.is_empty():
		topic_ids.append(category)
	if not generated_surface_id.is_empty():
		topic_ids.append(generated_surface_id)
	if not scope.is_empty():
		topic_ids.append(scope)
	if not str(source_data.get("target_sector_id", "")).is_empty():
		topic_ids.append("sector")
	if not str(source_data.get("target_company_id", "")).is_empty():
		topic_ids.append("company")
	return _unique_string_array(topic_ids)


func _source_public_depth_level(_source_data: Dictionary) -> int:
	return PUBLIC_NEWS_DEPTH_LEVEL


func _source_specificity(source_data: Dictionary) -> String:
	var specificity: String = str(source_data.get("specificity", "")).strip_edges()
	if not specificity.is_empty():
		return specificity
	if not str(source_data.get("target_company_id", "")).is_empty():
		return "company"
	if not str(source_data.get("target_sector_id", "")).is_empty():
		return "sector"
	return str(source_data.get("scope", "market"))


func _source_noise_level(source_data: Dictionary, outlet: Dictionary, coverage_type: String) -> float:
	if source_data.has("noise_level"):
		return clamp(float(source_data.get("noise_level", 0.0)), 0.0, 1.0)
	if coverage_type == COVERAGE_EARLY_SIGNAL:
		return clamp(float(outlet.get("noise_level", 0.72)), 0.0, 1.0)
	if coverage_type == COVERAGE_CORPORATE_ACTION_FILING:
		return clamp(float(outlet.get("noise_level", 0.18)), 0.0, 1.0)
	if coverage_type == COVERAGE_MACRO_COMMODITY_SECTOR:
		return clamp(float(outlet.get("noise_level", 0.30)), 0.0, 1.0)
	return clamp(float(outlet.get("noise_level", 0.42)), 0.0, 1.0)


func _source_reliability(source_data: Dictionary, outlet: Dictionary, coverage_type: String) -> float:
	if source_data.has("reliability"):
		return clamp(float(source_data.get("reliability", 0.0)), 0.0, 1.0)
	if coverage_type == COVERAGE_CORPORATE_ACTION_FILING:
		return clamp(float(outlet.get("reliability", 0.74)), 0.0, 1.0)
	if coverage_type == COVERAGE_EARLY_SIGNAL:
		return clamp(float(outlet.get("reliability", 0.42)), 0.0, 1.0)
	if coverage_type == COVERAGE_MACRO_COMMODITY_SECTOR:
		return clamp(float(outlet.get("reliability", 0.62)), 0.0, 1.0)
	return clamp(float(outlet.get("reliability", 0.52)), 0.0, 1.0)


func _build_outlet_feed(
	outlet: Dictionary,
	feed_data: Dictionary,
	company_row_lookup: Dictionary,
	market_history_lookup: Dictionary,
	latest_market_entry: Dictionary,
	event_history: Array,
	active_special_events: Array,
	active_company_arcs: Array,
	current_trade_date: Dictionary,
	story_memory: Dictionary,
	generated_news_sources: Array = []
) -> Dictionary:
	var articles: Array = []
	var seen_ids: Dictionary = {}
	var public_depth_level: int = PUBLIC_NEWS_DEPTH_LEVEL
	var article_limit: int = int(feed_data.get("article_limit", 12))

	for article_value in _build_hidden_arc_articles(
		outlet,
		feed_data,
		company_row_lookup,
		market_history_lookup,
		latest_market_entry,
		active_company_arcs,
		current_trade_date,
		story_memory
	):
		_append_unique_article(articles, seen_ids, article_value)
	for article_value in _build_active_special_articles(
		outlet,
		feed_data,
		company_row_lookup,
		market_history_lookup,
		latest_market_entry,
		active_special_events,
		current_trade_date,
		story_memory
	):
		_append_unique_article(articles, seen_ids, article_value)
	for article_value in _build_recent_event_articles(
		outlet,
		feed_data,
		company_row_lookup,
		market_history_lookup,
		latest_market_entry,
		event_history,
		current_trade_date,
		story_memory
	):
		_append_unique_article(articles, seen_ids, article_value)
	for article_value in _build_public_daily_brief_articles(
		outlet,
		feed_data,
		company_row_lookup,
		latest_market_entry,
		event_history,
		current_trade_date,
		story_memory
	):
		_append_unique_article(articles, seen_ids, article_value)
	for article_value in _build_generated_dossier_news_articles(
		outlet,
		feed_data,
		company_row_lookup,
		latest_market_entry,
		generated_news_sources,
		current_trade_date,
		story_memory
	):
		_append_unique_article(articles, seen_ids, article_value)

	var market_wrap: Dictionary = _build_market_wrap_article(
		outlet,
		feed_data,
		latest_market_entry,
		current_trade_date,
		story_memory
	)
	if not market_wrap.is_empty():
		_append_unique_article(articles, seen_ids, market_wrap)

	articles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("day_index", -1)) == int(b.get("day_index", -1)):
			if float(a.get("priority", 0.0)) == float(b.get("priority", 0.0)):
				return str(a.get("headline", "")) < str(b.get("headline", ""))
			return float(a.get("priority", 0.0)) > float(b.get("priority", 0.0))
		return int(a.get("day_index", -1)) > int(b.get("day_index", -1))
	)
	if articles.size() > article_limit:
		articles = articles.slice(0, article_limit)

	return {
		"outlet_id": str(outlet.get("id", "")),
		"outlet_label": str(outlet.get("label", "")),
		"intel_level": PUBLIC_NEWS_DEPTH_LEVEL,
		"public_depth_level": public_depth_level,
		"access_model": NEWS_ACCESS_MODEL,
		"coverage_type": str(outlet.get("coverage_type", "")),
		"topic_ids": _unique_string_array(outlet.get("topic_ids", [])),
		"reliability": float(outlet.get("reliability", 0.55)),
		"specificity": str(outlet.get("specificity", "market")),
		"noise_level": float(outlet.get("noise_level", 0.35)),
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
	current_trade_date: Dictionary,
	story_memory: Dictionary
) -> Array:
	if not _outlet_has_coverage(outlet, COVERAGE_EARLY_SIGNAL):
		return []

	var articles: Array = []
	for arc_value in active_company_arcs:
		var arc: Dictionary = arc_value
		if str(arc.get("phase_visibility", "visible")) != "hidden":
			continue
		var source_data: Dictionary = arc.duplicate(true)
		source_data["coverage_type"] = COVERAGE_EARLY_SIGNAL
		source_data["topic_ids"] = _unique_string_array(["early_signal", "rumor", "company_arc"])
		source_data["public_depth_level"] = PUBLIC_NEWS_DEPTH_LEVEL

		var company_id: String = str(source_data.get("target_company_id", ""))
		var row: Dictionary = company_row_lookup.get(company_id, {})
		var article_id: String = "hidden_arc|%s" % str(source_data.get("arc_id", ""))
		var context: Dictionary = _build_story_context(
			feed_data,
			source_data,
			row,
			_market_entry_for_day(market_history_lookup, latest_market_entry, int(current_trade_date.get("day_index", -1))),
			current_trade_date,
			"whisper",
			article_id,
			story_memory
		)
		articles.append(_build_article_record(
			outlet,
			feed_data,
			source_data,
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
	current_trade_date: Dictionary,
	story_memory: Dictionary
) -> Array:
	var articles: Array = []
	var current_day_index: int = int(current_trade_date.get("day_index", current_trade_date.get("day", 0)))

	for event_value in active_special_events:
		var event_data: Dictionary = event_value
		if not _outlet_covers_source(outlet, event_data):
			continue
		var start_day_index: int = int(event_data.get("start_day_index", current_day_index))
		var duration_days: int = max(int(event_data.get("duration_days", 1)), 1)
		var elapsed_days: int = max(current_day_index - start_day_index + 1, 1)
		var progress_ratio: float = clamp(float(elapsed_days) / float(duration_days), 0.0, 1.0)

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
			article_id,
			story_memory
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
	current_trade_date: Dictionary,
	story_memory: Dictionary
) -> Array:
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
		if str(event_data.get("event_family", "")) == RELATIONSHIP_GRAPH_SOURCE_SYSTEM_ID:
			var relationship_source_key: String = "relationship|%s|%s" % [
				str(event_data.get("relationship_event_id", event_data.get("event_id", ""))),
				str(outlet.get("id", ""))
			]
			source_counts[relationship_source_key] = int(source_counts.get(relationship_source_key, 0))
			if int(source_counts.get(relationship_source_key, 0)) > 0:
				continue
			var relationship_article: Dictionary = _build_relationship_event_article(
				outlet,
				feed_data,
				company_row_lookup,
				market_history_lookup,
				latest_market_entry,
				event_data,
				current_trade_date,
				current_day_index,
				story_memory
			)
			if not relationship_article.is_empty():
				source_counts[relationship_source_key] = int(source_counts.get(relationship_source_key, 0)) + 1
				articles.append(relationship_article)
			continue
		var age_days: int = max(current_day_index - int(event_data.get("day_index", current_day_index)), 0)
		if not _outlet_covers_source(outlet, event_data):
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
			article_id,
			story_memory
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


func _build_relationship_event_article(
	outlet: Dictionary,
	feed_data: Dictionary,
	company_row_lookup: Dictionary,
	market_history_lookup: Dictionary,
	latest_market_entry: Dictionary,
	event_data: Dictionary,
	current_trade_date: Dictionary,
	current_day_index: int,
	story_memory: Dictionary
) -> Dictionary:
	if not _relationship_event_allows_public_surface(event_data):
		return {}
	var age_days: int = max(current_day_index - int(event_data.get("day_index", current_day_index)), 0)
	var company_id: String = str(event_data.get("target_company_id", ""))
	var row: Dictionary = company_row_lookup.get(company_id, {})
	var source_data: Dictionary = _relationship_event_content_source(event_data, "news")
	if not _outlet_covers_source(outlet, source_data):
		return {}
	var progress_key: String = _progress_key_for_history_age(age_days)
	var stage_key: String = _stage_key_for_progress(progress_key)
	var article_id: String = "relationship_news|%s|%s|%s" % [
		str(source_data.get("relationship_event_id", source_data.get("event_id", ""))),
		int(source_data.get("day_index", -1)),
		str(outlet.get("id", ""))
	]
	var event_trade_date: Dictionary = source_data.get("trade_date", current_trade_date).duplicate(true)
	var context: Dictionary = _build_story_context(
		feed_data,
		source_data,
		row,
		_market_entry_for_day(market_history_lookup, latest_market_entry, int(source_data.get("day_index", current_day_index))),
		event_trade_date,
		stage_key,
		article_id,
		story_memory
	)
	var article: Dictionary = _build_article_record(
		outlet,
		feed_data,
		source_data,
		context,
		stage_key,
		progress_key,
		event_trade_date,
		int(source_data.get("day_index", -1)),
		article_id,
		2.85 - min(float(age_days) * 0.08, 0.8)
	)
	article["headline"] = str(source_data.get("headline", article.get("headline", "")))
	article["deck"] = str(source_data.get("summary", article.get("deck", "")))
	article["body"] = _relationship_event_news_body(source_data)
	var relationship_sections: Dictionary = _article_sections_from_body(str(article.get("body", "")))
	article["lead"] = str(relationship_sections.get("lead", ""))
	article["context"] = str(relationship_sections.get("context", ""))
	article["market_reaction"] = str(relationship_sections.get("market_reaction", ""))
	article["what_to_watch"] = str(relationship_sections.get("what_to_watch", ""))
	article = _apply_generated_news_metadata(article, source_data)
	return _copy_relationship_event_metadata(article, source_data)


func _relationship_event_allows_public_surface(event_data: Dictionary) -> bool:
	var visibility: String = str(event_data.get("relationship_visibility", "")).strip_edges().to_lower()
	return visibility == "public" or visibility == "semi_public"


func _relationship_event_content_source(event_data: Dictionary, surface_context: String) -> Dictionary:
	var source_data: Dictionary = event_data.duplicate(true)
	var target_ticker: String = str(source_data.get("target_ticker", source_data.get("target_company_id", ""))).to_upper()
	var counterparty_ticker: String = str(source_data.get("counterparty_ticker", source_data.get("counterparty_company_id", ""))).to_upper()
	var target_name: String = str(source_data.get("target_company_name", target_ticker))
	var counterparty_name: String = str(source_data.get("counterparty_company_name", counterparty_ticker))
	var headline_pair: String = "%s-%s" % [target_ticker, counterparty_ticker] if not counterparty_ticker.is_empty() else target_ticker
	var event_kind: String = str(source_data.get("relationship_event_kind", source_data.get("category", "")))
	var role: String = str(source_data.get("relationship_impact_role", ""))
	var visibility: String = str(source_data.get("relationship_visibility", "semi_public")).strip_edges().to_lower()
	source_data["scope"] = "company"
	source_data["category"] = "relationship_graph_news" if surface_context == "news" else "generated_twooter_relationship"
	source_data["event_family"] = RELATIONSHIP_GRAPH_SOURCE_SYSTEM_ID
	source_data["coverage_type"] = COVERAGE_CORPORATE_ACTION_FILING if visibility == "public" else COVERAGE_EARLY_SIGNAL
	source_data["topic_ids"] = _unique_string_array(["company_relationship", "corporate_action"] if visibility == "public" else ["company_relationship", "early_signal", "rumor"])
	source_data["public_depth_level"] = PUBLIC_NEWS_DEPTH_LEVEL
	source_data["generated_content_surface"] = true
	source_data["generated_surface_id"] = "company_news" if surface_context == "news" else "twooter"
	source_data["generated_scope_id"] = "relationship"
	source_data["source_system_id"] = RELATIONSHIP_GRAPH_SOURCE_SYSTEM_ID
	source_data["story_id"] = str(source_data.get("relationship_event_id", ""))
	source_data["story_family"] = "company_relationship"
	source_data["archetype_id"] = event_kind
	source_data["public_status"] = "reported" if visibility == "public" else "market_talk"
	source_data["stage_id"] = "relationship_event"
	source_data["visibility"] = "public" if visibility == "public" else "semi_public"
	source_data["detail_level"] = "relationship"
	source_data["reliability"] = snappedf(clamp(float(source_data.get("relationship_confidence", source_data.get("confidence", 0.0))), 0.0, 1.0), 0.001)
	source_data["leak_risk"] = 0.0 if visibility == "public" else 0.08
	source_data["source_fact_ids"] = _unique_string_array(["relationship_event:%s" % str(source_data.get("relationship_event_id", ""))])
	source_data["source_clue_ids"] = _unique_string_array(["relationship_edge:%s" % str(source_data.get("relationship_edge_id", ""))])
	source_data["source_company_ids"] = _unique_string_array([
		str(source_data.get("target_company_id", "")),
		str(source_data.get("counterparty_company_id", ""))
	])
	source_data["source_sector_ids"] = _unique_string_array([str(source_data.get("target_sector_id", ""))])
	source_data["source_event_ids"] = _unique_string_array([str(source_data.get("relationship_event_id", ""))])
	source_data["headline"] = "%s relationship move draws attention" % headline_pair
	source_data["summary"] = _relationship_event_public_summary(event_kind, role, target_name, target_ticker, counterparty_name, counterparty_ticker, visibility)
	source_data["description"] = str(source_data.get("summary", source_data.get("description", "")))
	return source_data


func _relationship_event_public_summary(
	event_kind: String,
	role: String,
	target_name: String,
	target_ticker: String,
	counterparty_name: String,
	counterparty_ticker: String,
	visibility: String
) -> String:
	var target_label: String = "%s (%s)" % [target_name, target_ticker] if not target_ticker.is_empty() else target_name
	var counterparty_label: String = "%s (%s)" % [counterparty_name, counterparty_ticker] if not counterparty_ticker.is_empty() else counterparty_name
	var qualifier: String = "confirmed" if visibility == "public" else "being discussed"
	match event_kind:
		"partnership_announcement":
			return "%s is %s around a commercial partnership with %s; traders are watching whether the link becomes visible in execution." % [target_label, qualifier, counterparty_label]
		"supply_deal":
			if role == "supplier":
				return "%s is %s around a supply mandate tied to %s, with attention on delivery and order flow." % [target_label, qualifier, counterparty_label]
			return "%s is %s around a vendor link with %s, with debate on whether the economics help or pressure margins." % [target_label, qualifier, counterparty_label]
		"customer_win":
			if role == "supplier":
				return "%s is %s around a new demand channel tied to %s, with follow-through still the main test." % [target_label, qualifier, counterparty_label]
			return "%s is %s around procurement exposure to %s, and the market is weighing commitment risk." % [target_label, qualifier, counterparty_label]
		"competitor_pressure":
			if role == "competitor_winner":
				return "%s is %s as %s faces peer pressure; the read is relative momentum, not a full thesis yet." % [target_label, qualifier, counterparty_label]
			return "%s is %s under peer pressure as %s shows stronger relative momentum." % [target_label, qualifier, counterparty_label]
	return "%s is %s around a commercial link with %s." % [target_label, qualifier, counterparty_label]


func _relationship_event_news_body(source_data: Dictionary) -> String:
	var summary: String = str(source_data.get("summary", "")).strip_edges()
	var description: String = str(source_data.get("description", "")).strip_edges()
	var visibility: String = str(source_data.get("relationship_visibility", source_data.get("visibility", ""))).strip_edges()
	var confidence_text: String = "The relationship is visible enough for public desks to track, but the useful question is still whether the operating effect shows up in filings, orders, or margins."
	if visibility == "semi_public":
		confidence_text = "The relationship is still closer to market talk than a full public disclosure, so the clean read is to watch confirmation rather than assume the economics."
	var body: Array = []
	if not summary.is_empty():
		body.append(summary)
	elif not description.is_empty():
		body.append(description)
	body.append(confidence_text)
	body.append("The move is being treated as a company-specific relationship signal rather than a broad sector call.")
	return "\n\n".join(body)


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


func _build_public_daily_brief_articles(
	outlet: Dictionary,
	feed_data: Dictionary,
	company_row_lookup: Dictionary,
	latest_market_entry: Dictionary,
	event_history: Array,
	current_trade_date: Dictionary,
	story_memory: Dictionary
) -> Array:
	var articles: Array = []
	var current_day_index: int = int(current_trade_date.get("day_index", current_trade_date.get("day", 0)))
	var company_rows: Array = []
	for row_value in company_row_lookup.values():
		var row: Dictionary = row_value
		if not str(row.get("ticker", "")).is_empty():
			company_rows.append(row.duplicate(true))

	company_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("daily_change_pct", 0.0)) > float(b.get("daily_change_pct", 0.0))
	)

	if not company_rows.is_empty():
		var winner_row: Dictionary = company_rows[0]
		var winner_article: Dictionary = _build_public_company_brief_article(
			outlet,
			feed_data,
			winner_row,
			latest_market_entry,
			current_trade_date,
			story_memory,
			"top_mover",
			2.85
		)
		if not winner_article.is_empty():
			articles.append(winner_article)
		var loser_row: Dictionary = company_rows[company_rows.size() - 1]
		if str(loser_row.get("id", "")) != str(winner_row.get("id", "")):
			var loser_article: Dictionary = _build_public_company_brief_article(
				outlet,
				feed_data,
				loser_row,
				latest_market_entry,
				current_trade_date,
				story_memory,
				"weak_mover",
				2.75
			)
			if not loser_article.is_empty():
				articles.append(loser_article)

	var sector_source: Dictionary = _build_public_sector_brief_source(company_rows, current_trade_date)
	if not sector_source.is_empty():
		var sector_article: Dictionary = _build_public_source_brief_article(
			outlet,
			feed_data,
			sector_source,
			{},
			latest_market_entry,
			current_trade_date,
			story_memory,
			"sector_watch",
			2.65
		)
		if not sector_article.is_empty():
			articles.append(sector_article)

	var calendar_articles_added: int = 0
	for event_value in event_history:
		if calendar_articles_added >= 2 or typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event_data: Dictionary = event_value
		if int(event_data.get("day_index", -9999)) != current_day_index:
			continue
		if not _is_public_calendar_event(event_data):
			continue
		var company_id: String = str(event_data.get("target_company_id", ""))
		var company_row: Dictionary = company_row_lookup.get(company_id, {})
		var calendar_article: Dictionary = _build_public_source_brief_article(
			outlet,
			feed_data,
			_build_public_calendar_source(event_data),
			company_row,
			latest_market_entry,
			current_trade_date,
			story_memory,
			"calendar_%d" % calendar_articles_added,
			2.95 - (float(calendar_articles_added) * 0.05)
		)
		if not calendar_article.is_empty():
			articles.append(calendar_article)
			calendar_articles_added += 1

	return articles


func _build_public_company_brief_article(
	outlet: Dictionary,
	feed_data: Dictionary,
	company_row: Dictionary,
	latest_market_entry: Dictionary,
	current_trade_date: Dictionary,
	story_memory: Dictionary,
	brief_key: String,
	priority: float
) -> Dictionary:
	var source_data: Dictionary = company_row.duplicate(true)
	var ticker: String = str(company_row.get("ticker", ""))
	var change_pct: float = float(company_row.get("daily_change_pct", 0.0))
	source_data["scope"] = "company"
	source_data["category"] = "public_mover"
	source_data["event_family"] = "public_brief"
	source_data["coverage_type"] = COVERAGE_MARKET_WRAP_CHATTER
	source_data["topic_ids"] = _unique_string_array(["market_wrap", "public_mover", "chatter"])
	source_data["public_depth_level"] = PUBLIC_NEWS_DEPTH_LEVEL
	source_data["tone"] = _tone_from_change(change_pct)
	source_data["target_company_id"] = str(company_row.get("id", ""))
	source_data["target_ticker"] = ticker
	source_data["target_company_name"] = str(company_row.get("name", ticker))
	source_data["target_sector_id"] = str(company_row.get("sector_id", ""))
	source_data["sector_name"] = str(company_row.get("sector_name", ""))
	source_data["headline"] = "%s stays on public watch after moving %s" % [ticker, _format_percent(change_pct)]
	source_data["summary"] = "%s moved %s today. Public traders are watching whether the next session confirms the move or fades it." % [
		ticker,
		_format_percent(change_pct)
	]
	source_data["day_index"] = int(current_trade_date.get("day_index", -1))
	source_data["trade_date"] = current_trade_date.duplicate(true)
	return _build_public_source_brief_article(
		outlet,
		feed_data,
		source_data,
		company_row,
		latest_market_entry,
		current_trade_date,
		story_memory,
		brief_key,
		priority
	)


func _build_public_source_brief_article(
	outlet: Dictionary,
	feed_data: Dictionary,
	source_data: Dictionary,
	company_row: Dictionary,
	latest_market_entry: Dictionary,
	current_trade_date: Dictionary,
	story_memory: Dictionary,
	brief_key: String,
	priority: float
) -> Dictionary:
	if not _outlet_covers_source(outlet, source_data):
		return {}
	var day_index: int = int(source_data.get("day_index", current_trade_date.get("day_index", -1)))
	var source_key: String = str(source_data.get("target_company_id", ""))
	if source_key.is_empty():
		source_key = str(source_data.get("target_sector_id", ""))
	if source_key.is_empty():
		source_key = str(source_data.get("event_id", "market"))
	var article_id: String = "public_brief|%s|%s|%s" % [
		brief_key,
		source_key,
		day_index
	]
	var context: Dictionary = _build_story_context(
		feed_data,
		source_data,
		company_row,
		latest_market_entry,
		source_data.get("trade_date", current_trade_date).duplicate(true),
		"public_brief",
		article_id,
		story_memory
	)
	return _build_article_record(
		outlet,
		feed_data,
		source_data,
		context,
		"public_brief",
		"developing",
		source_data.get("trade_date", current_trade_date).duplicate(true),
		day_index,
		article_id,
		priority
	)


func _build_public_sector_brief_source(company_rows: Array, current_trade_date: Dictionary) -> Dictionary:
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
	var change_pct: float = float(best_sector.get("average_change_pct", 0.0))
	return {
		"event_id": "public_sector_brief",
		"scope": "sector",
		"category": "sector_rotation",
		"event_family": "public_brief",
		"coverage_type": COVERAGE_MACRO_COMMODITY_SECTOR,
		"topic_ids": _unique_string_array(["sector", "subsector", "market_breadth"]),
		"public_depth_level": PUBLIC_NEWS_DEPTH_LEVEL,
		"tone": _tone_from_change(change_pct),
		"target_sector_id": str(best_sector.get("sector_id", "")),
		"sector_name": sector_name,
		"headline": "%s draws attention after moving %s on average" % [sector_name, _format_percent(change_pct)],
		"summary": "%s was one of the clearer sector moves today. The next clue is whether more names in the group join the move." % sector_name,
		"day_index": int(current_trade_date.get("day_index", -1)),
		"trade_date": current_trade_date.duplicate(true)
	}


func _build_generated_dossier_news_sources(
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
		var story_id: String = str(story_id_value)
		var dossier_value: Variant = dossier_index.get(story_id, {})
		if typeof(dossier_value) != TYPE_DICTIONARY:
			continue
		var dossier: Dictionary = dossier_value
		var public_clue: Dictionary = _public_news_clue_for_day(dossier, current_day_index)
		if public_clue.is_empty():
			continue
		var company_id: String = str(dossier.get("company_id", ""))
		var company_row: Dictionary = company_row_lookup.get(company_id, {})
		if company_row.is_empty():
			company_row = _company_row_from_dossier(dossier)

		var company_source: Dictionary = _generated_news_company_source(dossier, public_clue, company_row, current_trade_date, current_day_index)
		if not company_source.is_empty():
			source_candidates.append(company_source)

		var sector_fact: Dictionary = _best_fact_for_types(dossier, ["sector"])
		var sector_id: String = str(sector_fact.get("source_id", company_row.get("sector_id", "")))
		if not sector_id.is_empty() and not seen_sector_ids.has(sector_id):
			var sector_source: Dictionary = _generated_news_sector_source(dossier, public_clue, sector_fact, company_row, current_trade_date, current_day_index)
			if not sector_source.is_empty():
				source_candidates.append(sector_source)
				seen_sector_ids[sector_id] = true

		var macro_fact: Dictionary = _best_fact_for_types(dossier, ["macro", "commodity"])
		var macro_key: String = "%s|%s" % [
			str(macro_fact.get("fact_type", "")),
			str(macro_fact.get("source_id", ""))
		]
		if not macro_fact.is_empty() and not seen_macro_keys.has(macro_key):
			var macro_source: Dictionary = _generated_news_macro_source(dossier, public_clue, macro_fact, company_row, current_trade_date, current_day_index)
			if not macro_source.is_empty():
				source_candidates.append(macro_source)
				seen_macro_keys[macro_key] = true

	source_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("priority", 0.0)), float(b.get("priority", 0.0))):
			return str(a.get("event_id", "")) < str(b.get("event_id", ""))
		return float(a.get("priority", 0.0)) > float(b.get("priority", 0.0))
	)
	return _select_generated_dossier_news_sources(source_candidates)


func _build_generated_dossier_news_articles(
	outlet: Dictionary,
	feed_data: Dictionary,
	company_row_lookup: Dictionary,
	latest_market_entry: Dictionary,
	generated_news_sources: Array,
	current_trade_date: Dictionary,
	story_memory: Dictionary
) -> Array:
	var articles: Array = []
	for source_value in generated_news_sources:
		if articles.size() >= MAX_GENERATED_DOSSIER_NEWS_ARTICLES_PER_OUTLET:
			break
		if typeof(source_value) != TYPE_DICTIONARY:
			continue
		var source_data: Dictionary = source_value
		if not _outlet_covers_source(outlet, source_data):
			continue
		var company_id: String = str(source_data.get("target_company_id", ""))
		var company_row: Dictionary = company_row_lookup.get(company_id, {})
		var day_index: int = int(source_data.get("day_index", current_trade_date.get("day_index", -1)))
		var article_id: String = "generated_dossier_news|%s|%s|%s|%d" % [
			str(outlet.get("id", "")),
			str(source_data.get("generated_surface_id", "")),
			str(source_data.get("story_id", "")).replace("|", "_"),
			day_index
		]
		var article_trade_date: Dictionary = source_data.get("trade_date", current_trade_date).duplicate(true)
		var context: Dictionary = _build_story_context(
			feed_data,
			source_data,
			company_row,
			latest_market_entry,
			article_trade_date,
			"public_brief",
			article_id,
			story_memory
		)
		var article: Dictionary = _build_article_record(
			outlet,
			feed_data,
			source_data,
			context,
			"public_brief",
			"developing",
			article_trade_date,
			day_index,
			article_id,
			float(source_data.get("priority", 2.35))
		)
		articles.append(_apply_generated_news_metadata(article, source_data))
	return articles


func _select_generated_dossier_news_sources(source_candidates: Array) -> Array:
	var buckets: Dictionary = {
		"company_news": [],
		"sector_news": [],
		"macro_news": []
	}
	for source_value in source_candidates:
		if typeof(source_value) != TYPE_DICTIONARY:
			continue
		var source_data: Dictionary = source_value
		var surface_id: String = str(source_data.get("generated_surface_id", ""))
		if not buckets.has(surface_id):
			continue
		var bucket: Array = buckets.get(surface_id, [])
		bucket.append(source_data)
		buckets[surface_id] = bucket

	var selected: Array = []
	for surface_id in ["company_news", "sector_news", "macro_news"]:
		var bucket: Array = buckets.get(surface_id, [])
		var bucket_limit: int = 2 if surface_id != "macro_news" else 1
		for index in range(min(bucket_limit, bucket.size())):
			selected.append(bucket[index])

	if selected.size() < MAX_GENERATED_DOSSIER_NEWS_SOURCES:
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
			if selected.size() >= MAX_GENERATED_DOSSIER_NEWS_SOURCES:
				break

	selected.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("priority", 0.0)), float(b.get("priority", 0.0))):
			return str(a.get("event_id", "")) < str(b.get("event_id", ""))
		return float(a.get("priority", 0.0)) > float(b.get("priority", 0.0))
	)
	return selected


func _public_news_clue_for_day(dossier: Dictionary, current_day_index: int) -> Dictionary:
	for clue_value in dossier.get("public_clues", []):
		if typeof(clue_value) != TYPE_DICTIONARY:
			continue
		var clue: Dictionary = clue_value
		if str(clue.get("surface_id", "")) != "news":
			continue
		if str(clue.get("visibility", "public")) != "public":
			continue
		var earliest_day_index: int = int(clue.get("earliest_day_index", 0))
		var latest_day_index: int = int(clue.get("latest_day_index", earliest_day_index))
		if current_day_index < earliest_day_index or current_day_index > latest_day_index:
			continue
		return clue.duplicate(true)
	return {}


func _generated_news_company_source(
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
	var detail: String = _generated_company_news_detail(dossier, clue, company_name, sector_name)
	return _generated_news_source_base(dossier, clue, current_trade_date, current_day_index, {
		"generated_surface_id": "company_news",
		"category": "generated_company_news",
		"scope": "company",
		"coverage_type": COVERAGE_MARKET_WRAP_CHATTER,
		"topic_ids": _unique_string_array(["company", "public_chatter", "story"]),
		"public_depth_level": PUBLIC_NEWS_DEPTH_LEVEL,
		"event_id": "generated_dossier_company_news|%s" % str(dossier.get("story_id", "")),
		"target_company_id": company_id,
		"target_ticker": ticker,
		"target_company_name": company_name,
		"target_sector_id": sector_id,
		"sector_name": sector_name,
		"headline": "%s draws attention as its latest business signals get noticed" % ticker,
		"summary": detail,
		"headline_detail": detail,
		"source_company_ids": _unique_string_array([company_id]),
		"source_sector_ids": _unique_string_array([sector_id]),
		"priority": 2.52 + float(dossier.get("priority", 0.0)) * 0.35 + float(clue.get("reliability", 0.0)) * 0.08
	})


func _generated_news_sector_source(
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
	var detail: String = "%s names are getting a cleaner public read as traders compare which companies have the stronger follow-through." % sector_name
	return _generated_news_source_base(dossier, clue, current_trade_date, current_day_index, {
		"generated_surface_id": "sector_news",
		"category": "generated_sector_news",
		"scope": "sector",
		"coverage_type": COVERAGE_MACRO_COMMODITY_SECTOR,
		"topic_ids": _unique_string_array(["sector", "subsector", "readthrough"]),
		"public_depth_level": PUBLIC_NEWS_DEPTH_LEVEL,
		"event_id": "generated_dossier_sector_news|%s|%s" % [sector_id, str(dossier.get("story_id", ""))],
		"target_sector_id": sector_id,
		"sector_name": sector_name,
		"headline": "%s desks sort leaders from passengers" % sector_name,
		"summary": detail,
		"headline_detail": detail,
		"source_company_ids": _source_company_ids_from_fact(fact, str(dossier.get("company_id", ""))),
		"source_sector_ids": _source_sector_ids_from_fact(fact, sector_id),
		"priority": 2.42 + float(dossier.get("priority", 0.0)) * 0.28 + float(clue.get("reliability", 0.0)) * 0.06
	})


func _generated_news_macro_source(
	dossier: Dictionary,
	clue: Dictionary,
	fact: Dictionary,
	company_row: Dictionary,
	current_trade_date: Dictionary,
	current_day_index: int
) -> Dictionary:
	var fact_type: String = str(fact.get("fact_type", "macro"))
	var source_id: String = str(fact.get("source_id", "macro"))
	var commodity_label: String = _public_fact_source_label(source_id)
	var sector_id: String = str(company_row.get("sector_id", ""))
	var sector_name: String = str(company_row.get("sector_name", DataRepository.get_sector_definition(sector_id).get("name", sector_id.capitalize())))
	var detail: String = ""
	if fact_type == "commodity":
		detail = "%s remains the wider input to watch, with traders checking which exposed companies can turn the move into real numbers." % commodity_label
	else:
		detail = "The wider macro backdrop is giving traders a reason to re-check sector exposure before deciding which company stories deserve attention."
	return _generated_news_source_base(dossier, clue, current_trade_date, current_day_index, {
		"generated_surface_id": "macro_news",
		"category": "generated_macro_news",
		"scope": "market",
		"coverage_type": COVERAGE_MACRO_COMMODITY_SECTOR,
		"topic_ids": _unique_string_array([fact_type, "macro", "commodity", "sector"]),
		"public_depth_level": PUBLIC_NEWS_DEPTH_LEVEL,
		"event_id": "generated_dossier_macro_news|%s|%s|%s" % [fact_type, source_id, str(dossier.get("story_id", ""))],
		"target_sector_id": sector_id,
		"sector_name": sector_name,
		"headline": "%s signal puts exposed names back on watch" % commodity_label,
		"summary": detail,
		"headline_detail": detail,
		"source_company_ids": _source_company_ids_from_fact(fact, str(dossier.get("company_id", ""))),
		"source_sector_ids": _source_sector_ids_from_fact(fact, sector_id),
		"source_commodity_ids": _unique_string_array([source_id]) if fact_type == "commodity" else [],
		"priority": 2.32 + float(dossier.get("priority", 0.0)) * 0.22 + float(clue.get("reliability", 0.0)) * 0.05
	})


func _generated_news_source_base(
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
	source_data["source_system_id"] = GENERATED_DOSSIER_NEWS_SOURCE_SYSTEM_ID
	source_data["story_id"] = str(dossier.get("story_id", ""))
	source_data["story_family"] = str(dossier.get("story_family", "company_story"))
	source_data["archetype_id"] = str(dossier.get("archetype_id", ""))
	source_data["public_status"] = str(dossier.get("public_status", ""))
	source_data["stage_id"] = str(dossier.get("stage_id", ""))
	source_data["visibility"] = "public"
	source_data["public_depth_level"] = PUBLIC_NEWS_DEPTH_LEVEL
	source_data["detail_level"] = str(clue.get("detail_level", "low"))
	source_data["reliability"] = float(clue.get("reliability", 0.0))
	source_data["leak_risk"] = float(clue.get("leak_risk", 0.0))
	source_data["source_fact_ids"] = _source_fact_ids_from_dossier(dossier, clue)
	source_data["source_clue_ids"] = _unique_string_array([str(clue.get("clue_id", ""))])
	return source_data


func _generated_company_news_detail(dossier: Dictionary, _clue: Dictionary, company_name: String, sector_name: String) -> String:
	match str(dossier.get("archetype_id", "")):
		"contract_win":
			return "%s is being watched after fresh work-pipeline signals appeared around the company." % company_name
		"capex_expansion":
			return "%s has a capacity story that is becoming easier for public investors to follow." % company_name
		"margin_recovery":
			return "%s is drawing attention as traders look for signs that cost pressure may be easing." % company_name
		"commodity_tailwind":
			return "%s is being linked to a better commodity backdrop inside %s." % [company_name, sector_name]
		"commodity_headwind":
			return "%s is being checked against a tougher commodity backdrop inside %s." % [company_name, sector_name]
		"governance_risk":
			return "%s is getting a more cautious public read after governance-related signals surfaced." % company_name
		"balance_sheet_stress":
			return "%s is under closer watch as traders focus on whether balance-sheet pressure is manageable." % company_name
		"fraud_signal":
			return "%s is facing a rougher public read as questions around reported activity get louder." % company_name
		"turnaround":
			return "%s is being watched for signs that the turnaround story has more than one good day behind it." % company_name
		_:
			return "%s has a fresh company-specific story that traders are beginning to place on watchlists." % company_name


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


func _apply_generated_news_metadata(article: Dictionary, source_data: Dictionary) -> Dictionary:
	var enriched: Dictionary = article.duplicate(true)
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
		"source_commodity_ids",
		"source_event_ids",
		"topic_ids",
		"coverage_type",
		"public_depth_level",
		"specificity",
		"noise_level"
	]:
		enriched[key] = source_data.get(key)
	return enriched


func _is_public_calendar_event(event_data: Dictionary) -> bool:
	var category: String = str(event_data.get("category", ""))
	if str(event_data.get("event_family", "")) == "index_review" or category.begins_with("index_"):
		return true
	if category == "corporate_meeting" or not str(event_data.get("meeting_id", "")).is_empty():
		return true
	if category in ["corporate_action_filing", "corporate_action_resolution", "corporate_action_execution", "corporate_action_cancellation"]:
		return true
	return false


func _build_public_calendar_source(event_data: Dictionary) -> Dictionary:
	var source_data: Dictionary = event_data.duplicate(true)
	if str(source_data.get("event_family", "")) == "index_review" or str(source_data.get("category", "")).begins_with("index_"):
		var provider_label: String = str(source_data.get("provider_label", "Index"))
		var ticker: String = str(source_data.get("target_ticker", ""))
		source_data["scope"] = str(source_data.get("scope", "market" if ticker.is_empty() else "company"))
		source_data["coverage_type"] = COVERAGE_CORPORATE_ACTION_FILING
		source_data["topic_ids"] = _unique_string_array(["index_review", "corporate_action", "filing"])
		source_data["public_depth_level"] = PUBLIC_NEWS_DEPTH_LEVEL
		source_data["headline"] = "%s review is on the calendar" % provider_label
		source_data["summary"] = "%s review timing is now visible. Traders are watching announcement and effective-date passive flow." % provider_label
		return source_data
	var ticker: String = str(source_data.get("target_ticker", ""))
	var focus_label: String = ticker if not ticker.is_empty() else str(source_data.get("target_company_name", "The company"))
	source_data["scope"] = "company"
	source_data["event_family"] = str(source_data.get("event_family", "corporate_action"))
	source_data["coverage_type"] = COVERAGE_CORPORATE_ACTION_FILING
	source_data["topic_ids"] = _unique_string_array(["corporate_action", "filing", "meeting"])
	source_data["public_depth_level"] = PUBLIC_NEWS_DEPTH_LEVEL
	source_data["headline"] = "%s has a public corporate update on the calendar" % focus_label
	source_data["summary"] = "%s now has a public update to follow. Traders can use the calendar and the next market reaction to judge whether the event still matters." % focus_label
	return source_data


func _build_market_wrap_article(
	outlet: Dictionary,
	feed_data: Dictionary,
	latest_market_entry: Dictionary,
	current_trade_date: Dictionary,
	story_memory: Dictionary
) -> Dictionary:
	if latest_market_entry.is_empty():
		return {}
	if not _outlet_has_coverage(outlet, COVERAGE_MARKET_WRAP_CHATTER):
		return {}

	var market_wrap_source: Dictionary = latest_market_entry.duplicate(true)
	market_wrap_source["scope"] = "market"
	market_wrap_source["category"] = "market_wrap"
	market_wrap_source["event_family"] = "market"
	market_wrap_source["coverage_type"] = COVERAGE_MARKET_WRAP_CHATTER
	market_wrap_source["topic_ids"] = _unique_string_array(["market_wrap", "breadth", "sentiment"])
	market_wrap_source["public_depth_level"] = PUBLIC_NEWS_DEPTH_LEVEL
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
		article_id,
		story_memory
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
	if _is_policy_parody_source(source_data):
		headline = str(source_data.get("headline", context.get("focus_label", "Policy shock"))).strip_edges()
		deck = str(source_data.get("headline_detail", source_data.get("summary", context.get("detail_blend", "")))).strip_edges()
	if headline.is_empty():
		headline = str(source_data.get("headline", context.get("focus_label", "Market note")))
	if deck.is_empty():
		deck = str(context.get("detail_blend", context.get("driver_phrase", "")))
	var author: Dictionary = _author_for_article(feed_data, outlet, source_data, context, article_id)
	var public_status_label: String = _public_status_label(feed_data, progress_key, stage_key, source_data)
	var public_section_label: String = _public_section_label(source_data, context)
	var image_slot: String = _image_slot_for_article(source_data, context, stage_key)
	var public_story_angle: String = str(context.get("public_story_angle", ""))
	var public_confidence_label: String = str(context.get("public_confidence_label", ""))
	var public_continuity_phrase: String = str(context.get("public_continuity_phrase", ""))
	var coverage_type: String = _source_coverage_type(source_data)
	var body_sections: Dictionary = _build_article_body_sections(feed_data, voice_profile, source_data, context, stage_key, voice_seed)
	var article_headline: String = headline if _is_policy_parody_source(source_data) else _compose_headline(outlet, voice_profile, headline, "%s|prefix" % voice_seed)
	var article_deck: String = deck
	var lead_text: String = str(body_sections.get("lead", ""))
	var context_text: String = str(body_sections.get("context", ""))
	var market_reaction_text: String = str(body_sections.get("market_reaction", ""))
	var watch_text: String = str(body_sections.get("what_to_watch", ""))
	var body_text: String = str(body_sections.get("body", ""))
	article_headline = _public_news_visible_text(article_headline, str(context.get("focus_label", "Market note")))
	article_deck = _public_news_visible_text(article_deck, str(context.get("detail_blend", "Public details are still developing.")))
	lead_text = _public_news_visible_text(lead_text, article_deck)
	context_text = _public_news_visible_text(context_text, "")
	market_reaction_text = _public_news_visible_text(market_reaction_text, "")
	watch_text = _public_news_visible_text(watch_text, "Traders are watching the next public update and market reaction.")
	body_text = _public_news_visible_text(body_text, _join_paragraphs([lead_text, context_text, market_reaction_text, watch_text]))
	var topic_ids: Array = _source_topic_ids(source_data, coverage_type)
	var source_company_ids: Array = _unique_string_array(source_data.get("source_company_ids", []))
	if not str(context.get("target_company_id", "")).is_empty():
		source_company_ids.append(str(context.get("target_company_id", "")))
	source_company_ids = _unique_string_array(source_company_ids)
	var source_sector_ids: Array = _unique_string_array(source_data.get("source_sector_ids", []))
	if not str(context.get("target_sector_id", "")).is_empty():
		source_sector_ids.append(str(context.get("target_sector_id", "")))
	source_sector_ids = _unique_string_array(source_sector_ids)

	return {
		"id": article_id,
		"outlet_id": str(outlet.get("id", "")),
		"outlet_label": str(outlet.get("label", "News")),
		"intel_level": PUBLIC_NEWS_DEPTH_LEVEL,
		"public_depth_level": _source_public_depth_level(source_data),
		"access_model": NEWS_ACCESS_MODEL,
		"coverage_type": coverage_type,
		"topic_ids": topic_ids,
		"reliability": _source_reliability(source_data, outlet, coverage_type),
		"specificity": _source_specificity(source_data),
		"noise_level": _source_noise_level(source_data, outlet, coverage_type),
		"headline": article_headline,
		"deck": article_deck,
		"lead": lead_text,
		"context": context_text,
		"market_reaction": market_reaction_text,
		"what_to_watch": watch_text,
		"body": body_text,
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
		"event_family": str(source_data.get("event_family", "")),
		"source_system_id": str(source_data.get("source_system_id", "")),
		"source_fact_ids": _unique_string_array(source_data.get("source_fact_ids", [])),
		"source_clue_ids": _unique_string_array(source_data.get("source_clue_ids", [])),
		"source_company_ids": source_company_ids,
		"source_sector_ids": source_sector_ids,
		"source_commodity_ids": _unique_string_array(source_data.get("source_commodity_ids", [])),
		"source_event_ids": _unique_string_array(source_data.get("source_event_ids", [])),
		"source_chain_id": str(source_data.get("source_chain_id", "")),
		"chain_family": str(source_data.get("chain_family", "")),
		"meeting_id": str(source_data.get("meeting_id", "")),
		"venue_type": str(source_data.get("venue_type", "")),
		"author_id": str(author.get("id", "")),
		"author_name": str(author.get("display_name", "")),
		"author_role": str(author.get("role", "")),
		"author_contact_id": str(author.get("contact_id", "")) if bool(author.get("author_lead_available", false)) else "",
		"public_section_label": public_section_label,
		"public_status_label": public_status_label,
		"outlet_logo_asset": str(outlet.get("logo_asset", "")),
		"author_portrait_asset": str(author.get("portrait_asset", "")),
		"article_image_asset": str(source_data.get("article_image_asset", "")),
		"image_slot": image_slot,
		"public_story_angle": public_story_angle,
		"public_confidence_label": public_confidence_label,
		"public_continuity_phrase": public_continuity_phrase,
		"property_development_location_id": str(source_data.get("property_development_location_id", "")),
		"property_development_location_label": str(source_data.get("property_development_location_label", "")),
		"property_development_theme": str(source_data.get("property_development_theme", "")),
		"property_development_theme_label": str(source_data.get("property_development_theme_label", "")),
		"priority": priority
	}


func _build_article_body(
	feed_data: Dictionary,
	voice_profile: Dictionary,
	source_data: Dictionary,
	context: Dictionary,
	stage_key: String,
	seed_key: String
) -> String:
	return str(_build_article_body_sections(feed_data, voice_profile, source_data, context, stage_key, seed_key).get("body", ""))


func _build_article_body_sections(
	feed_data: Dictionary,
	voice_profile: Dictionary,
	source_data: Dictionary,
	context: Dictionary,
	stage_key: String,
	seed_key: String
) -> Dictionary:
	if _is_policy_parody_source(source_data):
		var policy_body: String = _build_policy_parody_article_body(feed_data, source_data, context, seed_key)
		if not policy_body.is_empty():
			return _article_sections_from_body(policy_body)

	var lead_template: String = _pick_voice_template(voice_profile, "lead_templates", stage_key, "%s|lead" % seed_key)
	var context_template: String = str(_pick_from_pool(voice_profile.get("context_templates", []), "%s|context" % seed_key))
	var impact_template: String = str(_pick_from_pool(voice_profile.get("impact_templates", []), "%s|impact" % seed_key))
	var market_reaction_template: String = _pick_body_slot_template(feed_data, "market_reaction_templates", source_data, "%s|reaction" % seed_key)
	var source_color_template: String = _pick_body_slot_template(feed_data, "source_color_templates", source_data, "%s|source" % seed_key)
	var continuity_slot: String = "with_prior" if not str(context.get("public_continuity_phrase", "")).is_empty() else "without_prior"
	var continuity_template: String = _pick_body_slot_template(feed_data, "continuity_templates", {"category": continuity_slot}, "%s|continuity" % seed_key)
	var closing_template: String = _pick_body_slot_template(feed_data, "closing_templates", source_data, "%s|closing" % seed_key)

	var paragraphs: Array = []
	var lead_paragraph: String = _join_sentences([_render_template(lead_template, context)])
	var context_paragraph: String = _join_sentences([_render_template(context_template, context)])
	var market_reaction_paragraph: String = _join_sentences([_render_template(market_reaction_template, context)])
	var source_color_paragraph: String = _join_sentences([_render_template(source_color_template, context)])
	var continuity_paragraph: String = _join_sentences([_render_template(continuity_template, context)])
	var impact_paragraph: String = _join_sentences([_render_template(impact_template, context)])
	var closing_paragraph: String = _join_sentences([_render_template(closing_template, context)])
	if not lead_paragraph.is_empty():
		paragraphs.append(lead_paragraph)
	if not context_paragraph.is_empty():
		paragraphs.append(context_paragraph)
	if not market_reaction_paragraph.is_empty():
		paragraphs.append(market_reaction_paragraph)
	if not source_color_paragraph.is_empty():
		paragraphs.append(source_color_paragraph)
	if not continuity_paragraph.is_empty():
		paragraphs.append(continuity_paragraph)
	if not impact_paragraph.is_empty():
		paragraphs.append(impact_paragraph)
	if not closing_paragraph.is_empty():
		paragraphs.append(closing_paragraph)
	return {
		"lead": lead_paragraph,
		"context": context_paragraph,
		"market_reaction": market_reaction_paragraph,
		"source_color": source_color_paragraph,
		"continuity": continuity_paragraph,
		"impact": impact_paragraph,
		"what_to_watch": closing_paragraph,
		"body": _join_paragraphs(paragraphs)
	}


func _article_sections_from_body(body: String) -> Dictionary:
	var paragraphs: PackedStringArray = body.split("\n\n")
	var lead: String = ""
	var context_text: String = ""
	var market_reaction: String = ""
	var what_to_watch: String = ""
	if paragraphs.size() > 0:
		lead = str(paragraphs[0])
	if paragraphs.size() > 1:
		context_text = str(paragraphs[1])
	if paragraphs.size() > 2:
		market_reaction = str(paragraphs[2])
	if paragraphs.size() > 0:
		what_to_watch = str(paragraphs[paragraphs.size() - 1])
	return {
		"lead": lead,
		"context": context_text,
		"market_reaction": market_reaction,
		"what_to_watch": what_to_watch,
		"body": body
	}


func _public_news_visible_text(text: String, fallback: String) -> String:
	var resolved: String = text.strip_edges()
	if resolved.is_empty():
		return fallback.strip_edges()
	if _public_news_text_has_private_terms(resolved):
		return fallback.strip_edges()
	return resolved


func _public_news_text_has_private_terms(text: String) -> bool:
	var lower_text: String = text.to_lower()
	var forbidden_terms: Array = [
		"truth_state",
		"source_quality",
		"source trail",
		"source story",
		"private clue",
		"network clue",
		"relationship edge",
		"hidden_positioning",
		"formal_agenda_or_filing",
		"current_timeline_state",
		"source reliability",
		"price-bias read",
		"raw statement",
		"system metadata",
		"clue|",
		"fact|",
		"story|"
	]
	for term_value in forbidden_terms:
		if lower_text.contains(str(term_value)):
			return true
	return false


func _build_policy_parody_article_body(feed_data: Dictionary, source_data: Dictionary, context: Dictionary, seed_key: String) -> String:
	var article_templates: Dictionary = feed_data.get("policy_event_article_templates", {})
	var template_keys: Array = _policy_parody_template_keys(source_data)
	template_keys.append("policy_parody")
	var templates: Array = []
	for key_value in template_keys:
		var key: String = str(key_value)
		templates = article_templates.get(key, [])
		if not templates.is_empty():
			break
	if templates.is_empty():
		return ""

	var paragraphs: Array = []
	for template_value in templates:
		var rendered_paragraph: String = _join_sentences([_render_template(str(template_value), context)])
		if not rendered_paragraph.is_empty():
			paragraphs.append(rendered_paragraph)
	return _join_paragraphs(paragraphs)


func _build_story_context(
	feed_data: Dictionary,
	source_data: Dictionary,
	company_row: Dictionary,
	market_entry: Dictionary,
	trade_date: Dictionary,
	stage_key: String,
	seed_key: String,
	story_memory: Dictionary
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
	var provider_label: String = str(source_data.get("provider_label", ""))

	var focus_label: String = "Index Gorengan"
	if not target_ticker.is_empty():
		focus_label = target_ticker
	elif scope == "sector" and not sector_name.is_empty():
		focus_label = sector_name
	elif not person_name.is_empty():
		focus_label = person_name
	elif not provider_label.is_empty():
		focus_label = provider_label
	elif scope == "market":
		focus_label = "Index Gorengan"

	var subject_label: String = "Index Gorengan"
	if not target_company_name.is_empty():
		subject_label = target_company_name
	elif scope == "sector" and not sector_name.is_empty():
		subject_label = sector_name
	elif not person_name.is_empty():
		subject_label = person_name
	elif not provider_label.is_empty():
		subject_label = provider_label
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
	var detail_hint: String = _public_detail_hint(source_data, phase_phrase)
	var whisper_phrase: String = _pick_reference_signal(feed_data, "whisper_hedges", "%s|whisper" % seed_key)
	var desk_watch: String = _pick_reference_signal(feed_data, "desk_watch", "%s|desk" % seed_key)
	var formal_phrase: String = _pick_formal_phrase(feed_data, source_data, stage_key, "%s|formal" % seed_key)
	var analysis_phrase: String = _pick_reference_signal(feed_data, "analysis_markers", "%s|analysis" % seed_key)
	var reaction_phrase: String = _pick_reaction_phrase(feed_data, source_data, tone, stage_key, "%s|reaction" % seed_key)
	var market_jargon: String = _pick_reference_signal(feed_data, "market_jargon", "%s|jargon" % seed_key)
	var driver_phrase: String = _pick_driver_phrase(feed_data, source_data, tone, "%s|driver" % seed_key)
	var watch_phrase: String = _pick_watch_phrase(feed_data, stage_key, "%s|watch" % seed_key)
	var continuity_phrase: String = _continuity_phrase_for_source(source_data, int(trade_date.get("day_index", source_data.get("day_index", -1))), story_memory)
	var public_confidence_label: String = _public_confidence_label(stage_key, source_data)
	var public_story_angle: String = _public_story_angle(source_data, stage_key, tone, scope)

	return {
		"target_company_id": target_company_id,
		"target_ticker": target_ticker,
		"target_company_name": target_company_name,
		"target_sector_id": target_sector_id,
		"sector_name": sector_name,
		"person_name": person_name,
		"provider_label": provider_label,
		"event_id": str(source_data.get("event_id", "")),
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
		"trade_day_label": _format_trade_day_label(trade_date),
		"public_story_angle": public_story_angle,
		"public_confidence_label": public_confidence_label,
		"public_continuity_phrase": continuity_phrase,
		"continuity_phrase": continuity_phrase
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
		"label": _public_memory_label(source_data),
		"category": str(source_data.get("category", "")),
		"target_company_id": str(source_data.get("target_company_id", "")),
		"source_chain_id": str(source_data.get("source_chain_id", "")),
		"headline": str(source_data.get("headline", ""))
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
		var category_family: String = _category_family_key(source_data)
		keys.append("company|%s|%s" % [company_id, category_family])
		keys.append("company|%s" % company_id)

	var sector_id: String = str(source_data.get("target_sector_id", ""))
	if not sector_id.is_empty():
		keys.append("sector|%s|%s" % [sector_id, _category_family_key(source_data)])
	return keys


func _continuity_phrase_for_source(source_data: Dictionary, article_day_index: int, story_memory: Dictionary) -> String:
	if article_day_index < 0:
		return ""
	var best_entry: Dictionary = {}
	for key_value in _story_memory_keys(source_data):
		var key: String = str(key_value)
		var entries: Array = story_memory.get(key, [])
		for entry_value in entries:
			var entry: Dictionary = entry_value
			if entry.is_empty():
				continue
			var prior_day_index: int = int(entry.get("day_index", -1))
			if prior_day_index < 0 or prior_day_index >= article_day_index:
				continue
			if best_entry.is_empty() or prior_day_index > int(best_entry.get("day_index", -1)):
				best_entry = entry.duplicate(true)
	if best_entry.is_empty():
		return ""

	var age_days: int = max(article_day_index - int(best_entry.get("day_index", article_day_index)), 1)
	var label: String = str(best_entry.get("label", "earlier update"))
	if age_days == 1:
		return "This follows yesterday's %s" % label
	if age_days <= 5:
		return "This follows the recent %s" % label
	return "This follows an earlier %s" % label


func _public_memory_label(source_data: Dictionary) -> String:
	var category: String = str(source_data.get("category", ""))
	if category == "index_inclusion":
		return "index inclusion"
	if category == "index_exclusion":
		return "index exclusion"
	if category == "index_watch":
		return "index review watch"
	if category == "corporate_action_rumor":
		return "market talk"
	if category == "corporate_action_speculation":
		return "public speculation"
	if category == "corporate_action_denial":
		return "company response"
	if category == "corporate_action_clarification":
		return "clarification"
	if category == "corporate_action_filing":
		return "formal notice"
	if category == "corporate_meeting":
		return "meeting notice"
	if category == "corporate_action_resolution":
		return "approval update"
	if category == "corporate_action_execution":
		return "execution update"
	if category == "corporate_action_cancellation":
		return "setback"
	if category == "earnings":
		return "earnings print"
	if category == "sector_rotation":
		return "sector move"
	if category == "management":
		return "management update"
	if category == "market_wrap":
		return "market close"
	return "company update"


func _public_detail_hint(source_data: Dictionary, phase_phrase: String) -> String:
	var category: String = str(source_data.get("category", ""))
	var summary: String = _sanitize_fragment(str(source_data.get("summary", "")))
	if not summary.is_empty() and not _looks_like_system_summary(summary):
		return summary
	var headline_detail: String = _sanitize_fragment(str(source_data.get("headline_detail", "")))
	if not headline_detail.is_empty() and not _looks_like_system_summary(headline_detail):
		return headline_detail
	var description: String = _sanitize_fragment(str(source_data.get("description", "")))
	if not description.is_empty() and not _looks_like_system_summary(description):
		return description

	if category == "corporate_action_rumor":
		return "early corporate-action talk is starting to show up in public trading activity"
	if category == "corporate_action_speculation":
		return "public speculation is getting loud enough for traders to price in a possible transaction"
	if category == "corporate_action_denial":
		return "the company response has made timing less certain without fully ending the story"
	if category == "corporate_action_clarification":
		return "the company has given the market a cleaner version of what it wants people to know"
	if category == "corporate_action_filing":
		return "a formal filing or notice has made the setup easier for traders to track"
	if category == "corporate_meeting":
		return "the story has moved toward a meeting or call where the next public clue should appear"
	if category == "corporate_action_resolution":
		return "the market now has an outcome to trade instead of only expectation"
	if category == "corporate_action_execution":
		return "the story is shifting from approval into execution"
	if category == "corporate_action_cancellation":
		return "the setup has lost momentum and the market is resetting expectations"
	if category.begins_with("roadmap_"):
		return "public business signals are making the company's expansion plans easier to follow"
	if category == "index_inclusion":
		return "the review list points to potential passive buying around the effective date"
	if category == "index_exclusion":
		return "the review list points to potential passive selling around the effective date"
	if category == "index_watch":
		return "index-review positioning is active while traders wait for the formal list"
	if category.begins_with("corporate_action"):
		return "the corporate-action track is now in %s" % phase_phrase
	return ""


func _looks_like_system_summary(value: String) -> bool:
	var lowered_value: String = value.to_lower()
	return (
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
		lowered_value.contains("price-bias read") or
		lowered_value.contains("funding_gate") or
		lowered_value.contains("funding readiness") or
		lowered_value.contains("roadmap_id") or
		lowered_value.contains("participant_role") or
		lowered_value.contains("milestone_state") or
		lowered_value.contains("company_roadmap") or
		lowered_value.contains("current_timeline_state") or
		lowered_value.contains("source_chain_id") or
		lowered_value.contains("stage of a")
	)


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


func _pick_formal_phrase(feed_data: Dictionary, source_data: Dictionary, stage_key: String, seed_key: String) -> String:
	if stage_key == "public_brief":
		var public_pool: Array = [
			"By the close",
			"On public screens",
			"In regular market trade",
			"From the market tape"
		]
		return str(_pick_from_pool(public_pool, seed_key))
	return _pick_reference_signal(feed_data, "formal_markers", seed_key)


func _pick_reaction_phrase(feed_data: Dictionary, source_data: Dictionary, tone: String, stage_key: String, seed_key: String) -> String:
	if tone == "positive":
		var positive_pool: Array = [
			"tracking follow-through instead of chasing blindly",
			"keeping the stronger names on watchlists",
			"waiting to see whether buyers return next session",
			"watching confirmation before adding size"
		]
		return str(_pick_from_pool(positive_pool, "%s|positive|%s" % [seed_key, stage_key]))
	if tone == "negative":
		var negative_pool: Array = [
			"cutting risk",
			"moving toward safer names",
			"selling weaker positions",
			"waiting before making bigger bets"
		]
		return str(_pick_from_pool(negative_pool, "%s|negative|%s" % [seed_key, stage_key]))
	var mixed_pool: Array = [
		"waiting before making bigger bets",
		"watching for cleaner confirmation",
		"keeping position sizes smaller",
		"checking whether the move spreads"
	]
	if stage_key == "public_brief" and str(source_data.get("category", "")) == "public_mover":
		return str(_pick_from_pool(mixed_pool, "%s|mixed_public" % seed_key))
	return _pick_reference_signal(feed_data, "reaction_markers", seed_key)


func _pick_driver_phrase(feed_data: Dictionary, source_data: Dictionary, tone: String, seed_key: String) -> String:
	var driver_phrases: Dictionary = feed_data.get("driver_phrases", {})
	var category: String = str(source_data.get("category", ""))
	var event_family: String = str(source_data.get("event_family", ""))
	var scope: String = str(source_data.get("scope", ""))
	var keys: Array = []
	if _is_policy_parody_source(source_data):
		for policy_key_value in _policy_parody_template_keys(source_data):
			var policy_key: String = str(policy_key_value)
			keys.append("%s_%s" % [policy_key, tone])
			keys.append(policy_key)
		keys.append("policy_parody_%s" % tone)
		keys.append("policy_parody")
	if category == "market_wrap":
		keys.append("market_wrap")
	if category.begins_with("index_"):
		keys.append("index_review_%s" % tone)
		keys.append("index_review")
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


func _pick_body_slot_template(feed_data: Dictionary, slot_key: String, source_data: Dictionary, seed_key: String) -> String:
	var body_slots: Dictionary = feed_data.get("body_slots", {})
	var slot_groups: Dictionary = body_slots.get(slot_key, {})
	for key_value in _body_template_keys(source_data):
		var key: String = str(key_value)
		var pool: Array = slot_groups.get(key, [])
		if pool.is_empty():
			continue
		return str(_pick_from_pool(pool, "%s|%s" % [seed_key, key]))
	return str(_pick_from_pool(slot_groups.get("fallback", []), "%s|fallback" % seed_key))


func _body_template_keys(source_data: Dictionary) -> Array:
	var category: String = str(source_data.get("category", ""))
	var tone: String = str(source_data.get("tone", ""))
	var event_family: String = str(source_data.get("event_family", ""))
	var scope: String = str(source_data.get("scope", ""))
	var keys: Array = []
	if _is_policy_parody_source(source_data):
		for policy_key_value in _policy_parody_template_keys(source_data):
			var policy_key: String = str(policy_key_value)
			if not tone.is_empty():
				keys.append("%s_%s" % [policy_key, tone])
			keys.append(policy_key)
		if not tone.is_empty():
			keys.append("policy_parody_%s" % tone)
		keys.append("policy_parody")
	if not category.is_empty() and not tone.is_empty():
		keys.append("%s_%s" % [category, tone])
	if not category.is_empty():
		keys.append(category)
	if category.begins_with("corporate_action"):
		keys.append("corporate_action")
	if category == "corporate_meeting":
		keys.append("corporate_meeting")
	if category.begins_with("index_"):
		keys.append("index_review")
	if category == "rumor_positive" or category == "rumor_negative" or category == "rumor":
		keys.append("rumor")
	if event_family == "special" or scope == "market":
		keys.append("special")
	if not event_family.is_empty() and not tone.is_empty():
		keys.append("%s_%s" % [event_family, tone])
	if not event_family.is_empty():
		keys.append(event_family)
	if not scope.is_empty():
		keys.append(scope)
	keys.append(_category_family_key(source_data))
	keys.append("fallback")
	return keys


func _category_family_key(source_data: Dictionary) -> String:
	var category: String = str(source_data.get("category", ""))
	if category.begins_with("generated_"):
		return "generated_news"
	if category.begins_with("index_") or str(source_data.get("event_family", "")) == "index_review":
		return "index_review"
	if category.begins_with("corporate_action"):
		return "corporate_action"
	if category == "corporate_meeting":
		return "corporate_meeting"
	if category.contains("rumor"):
		return "rumor"
	if _is_policy_parody_source(source_data):
		return "policy_parody"
	if category in ["earnings", "sector_rotation", "management", "market_wrap"]:
		return category
	var event_family: String = str(source_data.get("event_family", ""))
	if event_family == "special":
		return "special"
	if str(source_data.get("scope", "")) == "market":
		return "market_wrap"
	if not event_family.is_empty():
		return event_family
	return "company"


func _public_confidence_label(stage_key: String, source_data: Dictionary) -> String:
	var category: String = str(source_data.get("category", ""))
	if category.begins_with("generated_"):
		return "Public story"
	if category == "index_inclusion" or category == "index_exclusion":
		return "Effective flow" if str(source_data.get("review_stage", "")) == "effective" else "Index review"
	if category == "index_watch":
		return "Review watch"
	if category == "corporate_action_filing" or category == "corporate_action_resolution" or category == "corporate_action_execution":
		return "Filing-backed"
	if category == "corporate_meeting":
		return "Calendar watch"
	if category == "corporate_action_denial" or category == "corporate_action_clarification":
		return "Company response"
	if category.begins_with("roadmap_"):
		return "Public signals"
	if _is_policy_parody_source(source_data):
		return "Policy shock"
	match stage_key:
		"whisper":
			return "Early report"
		"confirmation":
			return "Confirmed"
		"analysis":
			return "Follow-up"
		"market_wrap":
			return "Market close"
		_:
			return "Public recap"


func _public_story_angle(source_data: Dictionary, stage_key: String, tone: String, scope: String) -> String:
	var category: String = str(source_data.get("category", ""))
	if category == "generated_macro_news":
		return "Macro read"
	if category == "generated_sector_news":
		return "Sector read"
	if category == "generated_company_news":
		return "Company story"
	if category.begins_with("index_") or str(source_data.get("event_family", "")) == "index_review":
		return "Index review"
	if category.begins_with("corporate_action"):
		return "Corporate action"
	if category.begins_with("roadmap_"):
		return "Company roadmap"
	if category == "corporate_meeting":
		return "Boardroom calendar"
	if category == "earnings":
		return "Earnings quality"
	if category == "sector_rotation":
		return "Sector rotation"
	if category == "management":
		return "Management change"
	if _is_policy_parody_source(source_data):
		return _policy_parody_story_angle(category)
	if category == "market_wrap" or stage_key == "market_wrap" or scope == "market":
		return "Market breadth"
	if category.contains("rumor"):
		return "Market talk"
	if tone == "negative":
		return "Risk watch"
	if tone == "positive":
		return "Momentum watch"
	return "Developing story"


func _is_policy_parody_source(source_data: Dictionary) -> bool:
	return (
		str(source_data.get("shock_class", "")) == "policy_parody" or
		str(source_data.get("category", "")).begins_with("policy_") or
		str(source_data.get("event_id", "")).begins_with("policy_") or
		str(source_data.get("id", "")).begins_with("active_special|policy_")
	)


func _policy_parody_template_keys(source_data: Dictionary) -> Array:
	var keys: Array = []
	var event_id: String = str(source_data.get("event_id", ""))
	if event_id.begins_with("policy_"):
		keys.append(event_id)
	var category: String = str(source_data.get("category", ""))
	if category.begins_with("policy_"):
		keys.append(category)
	return keys


func _policy_parody_story_angle(category: String) -> String:
	match category:
		"policy_fiscal_shock":
			return "Fiscal shock"
		"policy_commodity_gate":
			return "Commodity rule"
		"policy_fx_comment":
			return "FX comment"
		"policy_market_speech":
			return "Market speech"
		"policy_free_meal":
			return "Policy shock"
		_:
			return "Policy shock"


func _author_for_article(feed_data: Dictionary, outlet: Dictionary, source_data: Dictionary, context: Dictionary, article_id: String) -> Dictionary:
	var outlet_id: String = str(outlet.get("id", ""))
	var category: String = str(source_data.get("category", ""))
	var event_family: String = str(source_data.get("event_family", ""))
	var sector_id: String = str(context.get("target_sector_id", ""))
	var candidates: Array = []
	for author_value in feed_data.get("authors", []):
		var author: Dictionary = author_value
		var outlet_ids: Array = author.get("outlet_ids", [])
		if not outlet_ids.is_empty() and not (outlet_id in outlet_ids):
			continue
		var score: float = 10.0
		if category in author.get("specialties", []):
			score += 40.0
		if event_family in author.get("specialties", []):
			score += 30.0
		if sector_id in author.get("sector_ids", []):
			score += 20.0
		score += float(abs(hash("%s|%s" % [str(author.get("id", "")), article_id])) % 1000) / 1000.0
		candidates.append({"author": author, "score": score})
	if candidates.is_empty():
		return {
			"id": "desk_%s" % outlet_id,
			"display_name": str(outlet.get("label", "News Desk")),
			"role": "News Desk",
			"contact_id": "",
			"portrait_asset": "",
			"author_lead_available": false
		}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	var picked: Dictionary = candidates[0].get("author", {}).duplicate(true)
	var lead_frequency: float = clamp(float(picked.get("lead_frequency", 0.0)), 0.0, 1.0)
	var lead_roll: float = float(abs(hash("%s|lead" % article_id)) % 1000) / 1000.0
	picked["author_lead_available"] = not str(picked.get("contact_id", "")).is_empty() and lead_roll <= lead_frequency
	return picked


func _public_status_label(feed_data: Dictionary, progress_key: String, stage_key: String, source_data: Dictionary) -> String:
	var category: String = str(source_data.get("category", ""))
	if category.contains("denial"):
		return "Company Response"
	if category.contains("resolution") or category.contains("execution"):
		return "Confirmed"
	if stage_key == "whisper":
		return "Market Talk"
	if stage_key == "confirmation":
		return "Developing"
	if stage_key == "analysis":
		return "Follow-up"
	return str(feed_data.get("progress_labels", {}).get(progress_key, "Brief"))


func _public_section_label(source_data: Dictionary, context: Dictionary) -> String:
	var category: String = str(source_data.get("category", ""))
	var event_family: String = str(source_data.get("event_family", ""))
	if category == "generated_macro_news":
		return "Macro Watch"
	if category == "generated_sector_news":
		return "Sector Watch"
	if category == "generated_company_news":
		return "Companies"
	if category.begins_with("index_") or event_family == "index_review":
		return "Index Review"
	if category.begins_with("corporate_action") or category == "corporate_meeting":
		return "Boardroom"
	if category.begins_with("roadmap_"):
		return "Company Roadmap"
	if event_family == "market" or category == "market_wrap":
		return "Market Brief"
	if category == "earnings":
		return "Earnings"
	if category == "sector_rotation":
		return "Sector Watch"
	if category == "management":
		return "Management"
	if not str(context.get("sector_name", "")).is_empty() and str(context.get("scope", "")) == "sector":
		return str(context.get("sector_name", "Sector Watch"))
	return "Companies"


func _image_slot_for_article(source_data: Dictionary, context: Dictionary, stage_key: String) -> String:
	var category: String = str(source_data.get("category", ""))
	if category == "generated_macro_news":
		return "market"
	if category == "generated_sector_news":
		return "market"
	if category == "generated_company_news":
		return "company"
	if category.begins_with("index_") or str(source_data.get("event_family", "")) == "index_review":
		return "market"
	if category.begins_with("corporate_action") or category == "corporate_meeting":
		return "boardroom"
	if category.begins_with("roadmap_"):
		return "brief"
	if stage_key == "market_wrap" or str(context.get("scope", "")) == "market":
		return "market"
	if not str(context.get("target_company_id", "")).is_empty():
		return "company"
	return "brief"


func _market_entry_for_day(market_history_lookup: Dictionary, latest_market_entry: Dictionary, day_index: int) -> Dictionary:
	if market_history_lookup.has(day_index):
		return market_history_lookup[day_index].duplicate(true)
	return latest_market_entry.duplicate(true)


func _append_unique_article(articles: Array, seen_ids: Dictionary, article: Dictionary) -> void:
	if article.is_empty():
		return
	var normalized_article: Dictionary = _article_with_public_metadata_defaults(article)
	var article_id: String = str(normalized_article.get("id", ""))
	if article_id.is_empty() or seen_ids.has(article_id):
		return
	seen_ids[article_id] = true
	articles.append(normalized_article)


func _article_with_public_metadata_defaults(article: Dictionary) -> Dictionary:
	var normalized: Dictionary = article.duplicate(true)
	normalized["public_depth_level"] = PUBLIC_NEWS_DEPTH_LEVEL
	normalized["intel_level"] = PUBLIC_NEWS_DEPTH_LEVEL
	if str(normalized.get("access_model", "")).strip_edges().is_empty():
		normalized["access_model"] = NEWS_ACCESS_MODEL
	if str(normalized.get("coverage_type", "")).strip_edges().is_empty():
		normalized["coverage_type"] = _default_coverage_type_for_outlet_id(str(normalized.get("outlet_id", "")))
	if _unique_string_array(normalized.get("topic_ids", [])).is_empty():
		normalized["topic_ids"] = _default_topic_ids_for_coverage(str(normalized.get("coverage_type", "")))
	else:
		normalized["topic_ids"] = _unique_string_array(normalized.get("topic_ids", []))
	return normalized


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
	return _clean_generated_copy(rendered)


func _join_sentences(lines: Array) -> String:
	var sentences: Array = []
	for line_value in lines:
		var sentence: String = _clean_generated_copy(str(line_value))
		if sentence.is_empty():
			continue
		if not sentence.ends_with(".") and not sentence.ends_with("!") and not sentence.ends_with("?"):
			sentence += "."
		sentences.append(_clean_generated_copy(sentence))
	return " ".join(sentences)


func _join_paragraphs(paragraphs: Array) -> String:
	var filtered: Array = []
	for paragraph_value in paragraphs:
		var paragraph: String = _clean_generated_copy(str(paragraph_value))
		if paragraph.is_empty():
			continue
		filtered.append(paragraph)
	return "\n\n".join(filtered)


func _clean_generated_copy(value: String) -> String:
	var cleaned: String = value.strip_edges()
	var replacements: Array = [
		[" .", "."],
		[" ,", ","],
		[" ;", ";"],
		[" :", ":"],
		[" !", "!"],
		[" ?", "?"],
		["?.", "?"],
		["!.", "!"],
		["..", "."],
		["!!", "!"],
		["??", "?"]
	]
	for _iteration in range(3):
		cleaned = cleaned.replace("  ", " ")
		for replacement in replacements:
			cleaned = cleaned.replace(str(replacement[0]), str(replacement[1]))
	return cleaned


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
	return "%sRp%s" % [
		"-" if value < 0.0 else "",
		_format_decimal(absf(value), 2, true)
	]


func _format_decimal(value: float, decimal_places: int = 2, use_grouping: bool = true) -> String:
	var safe_places: int = max(decimal_places, 0)
	var decimal_scale: int = 1
	for _index in range(safe_places):
		decimal_scale *= 10
	var scaled_value: int = int(round(absf(value) * float(decimal_scale)))
	var whole_value: int = int(floor(float(scaled_value) / float(decimal_scale)))
	var decimal_value: int = scaled_value % decimal_scale
	var whole_text: String = _format_grouped_integer(whole_value) if use_grouping else str(whole_value)
	if safe_places <= 0:
		return whole_text
	var decimal_text: String = str(decimal_value)
	while decimal_text.length() < safe_places:
		decimal_text = "0" + decimal_text
	return "%s,%s" % [whole_text, decimal_text]


func _format_grouped_integer(value: int) -> String:
	var negative: bool = value < 0
	var digits: String = str(abs(value))
	var groups: Array = []
	while digits.length() > 3:
		groups.push_front(digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	if not digits.is_empty():
		groups.push_front(digits)
	var grouped_value: String = ".".join(groups)
	if grouped_value.is_empty():
		grouped_value = "0"
	return "-%s" % grouped_value if negative else grouped_value


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
