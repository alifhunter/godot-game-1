extends Node

const NEWS_FEED_SYSTEM_SCRIPT := preload("res://systems/NewsFeedSystem.gd")

const RUN_SEED := 20260622
const CATALOG_COMPANY_COUNT := 30
const EXPECTED_PREVIEW_HASH := "236925374"
const REQUIRED_GENERATED_SURFACES := ["company_news", "sector_news", "macro_news"]
const EXPECTED_OUTLET_LABELS := {
	"gorengan_daily": "Harian Investor",
	"waduh_finance": "The Egonomist",
	"harian_investor": "IDK Channel",
	"ordal_news": "MarketSnitch"
}
const EXPECTED_OUTLET_COVERAGE := {
	"gorengan_daily": "market_wrap_chatter",
	"waduh_finance": "macro_commodity_sector",
	"harian_investor": "corporate_action_filing",
	"ordal_news": "early_signal"
}


class MockDossierRunState:
	extends RefCounted

	var state: Dictionary = {}

	func get_company_story_dossier_state() -> Dictionary:
		return state.duplicate(true)


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var report: Dictionary = _build_report()
	if int(report.get("generated_article_count", 0)) <= 0:
		_fail("Expected generated dossier news preview articles.")
		return
	if int(report.get("authored_article_count", 0)) <= 0:
		_fail("Expected existing authored/public news articles to remain present.")
		return
	if int(report.get("issue_count", 0)) != 0:
		_fail("Generated news preview issues: %s" % JSON.stringify(report.get("issues", [])))
		return
	for surface_id in REQUIRED_GENERATED_SURFACES:
		if int(report.get("surface_counts", {}).get(surface_id, 0)) <= 0:
			_fail("Expected generated surface '%s' to appear in news preview." % surface_id)
			return
	if EXPECTED_PREVIEW_HASH != "BASELINE_PENDING" and str(report.get("hash", "")) != EXPECTED_PREVIEW_HASH:
		_fail("Generated news preview fingerprint changed. expected=%s actual=%s." % [
			EXPECTED_PREVIEW_HASH,
			str(report.get("hash", ""))
		])
		return

	report.erase("payload")
	print("CONTENT_SURFACE_NEWS_PREVIEW_OK %s" % JSON.stringify(report))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	_setup_fixed_seed_run()
	var target_day_index: int = _best_public_news_day_index()
	if target_day_index < 0:
		return {
			"seed": RUN_SEED,
			"generated_article_count": 0,
			"authored_article_count": 0,
			"issue_count": 1,
			"issues": ["no_public_news_clue_day"],
			"surface_counts": {},
			"hash": "",
			"payload": ""
		}
	RunState.day_index = target_day_index
	var trade_date: Dictionary = {
		"weekday": 1 + (target_day_index % 5),
		"day": 1 + (target_day_index % 28),
		"month": 1 + int(target_day_index / 28) % 12,
		"year": 2020,
		"day_index": target_day_index
	}
	var company_rows: Array = GameManager.get_company_market_rows(true)
	var market_history: Array = [_market_entry_for_rows(company_rows, trade_date, target_day_index)]
	var snapshot: Dictionary = NEWS_FEED_SYSTEM_SCRIPT.new().build_news_snapshot(
		RunState,
		DataRepository.get_news_feed_data(),
		company_rows,
		market_history,
		[],
		[],
		[],
		trade_date,
		4
	)
	var synthetic_snapshot: Dictionary = _build_synthetic_macro_snapshot()
	var generated_articles: Array = []
	var authored_article_count: int = 0
	var issues: Array[String] = []
	for snapshot_value in [snapshot, synthetic_snapshot]:
		if typeof(snapshot_value) != TYPE_DICTIONARY:
			continue
		var snapshot_row: Dictionary = snapshot_value
		_validate_news_contract(snapshot_row, issues)
		for feed_value in snapshot_row.get("feeds", {}).values():
			if typeof(feed_value) != TYPE_DICTIONARY:
				continue
			var feed: Dictionary = feed_value
			for article_value in feed.get("articles", []):
				if typeof(article_value) != TYPE_DICTIONARY:
					continue
				var article: Dictionary = article_value
				if bool(article.get("generated_content_surface", false)):
					generated_articles.append(article)
				else:
					authored_article_count += 1
	RunState.record_news_snapshot(snapshot)
	_validate_news_archive_filter_contract(snapshot, trade_date, issues)

	var surface_counts: Dictionary = {}
	var payload_lines: Array[String] = []
	for article_value in generated_articles:
		var article: Dictionary = article_value
		_validate_generated_article(article, issues, surface_counts)
		payload_lines.append(_article_payload_line(article))

	payload_lines.sort()
	var payload: String = "\n".join(payload_lines)
	return {
		"seed": RUN_SEED,
		"day_index": target_day_index,
		"generated_article_count": generated_articles.size(),
		"authored_article_count": authored_article_count,
		"surface_counts": _sorted_int_dictionary(surface_counts),
		"issue_count": issues.size(),
		"issues": issues,
		"hash": _stable_hash(payload),
		"payload": payload
	}


func _build_synthetic_macro_snapshot() -> Dictionary:
	var story_id: String = "story|synthetic_energy|commodity_tailwind|preview"
	var clue_id: String = "clue|%s|news|01" % story_id
	var fact_id: String = "fact|%s|commodity|coal" % story_id
	var synthetic_run_state := MockDossierRunState.new()
	synthetic_run_state.state = {
		"dossier_index": {
			story_id: {
				"story_id": story_id,
				"company_id": "synthetic_energy",
				"ticker": "SYN",
				"archetype_id": "commodity_tailwind",
				"story_family": "company_story",
				"public_status": "reported",
				"stage_id": "public_chatter",
				"priority": 0.72,
				"public_clues": [{
					"clue_id": clue_id,
					"fact_ids": [fact_id],
					"surface_id": "news",
					"visibility": "public",
					"earliest_day_index": 0,
					"latest_day_index": 12,
					"detail_level": "low",
					"reliability": 0.58,
					"tone": "positive",
					"leak_risk": 0.0
				}],
				"cause_facts": [
					{
						"fact_id": "fact|%s|sector|energy" % story_id,
						"fact_type": "sector",
						"source_id": "energy",
						"direction": "positive",
						"strength": 0.52,
						"related_company_ids": ["synthetic_energy"],
						"related_sector_ids": ["energy"]
					},
					{
						"fact_id": fact_id,
						"fact_type": "commodity",
						"source_id": "coal",
						"direction": "positive",
						"strength": 0.72,
						"related_company_ids": ["synthetic_energy"],
						"related_sector_ids": ["energy"]
					}
				]
			}
		}
	}
	var trade_date: Dictionary = {
		"weekday": 1,
		"day": 6,
		"month": 1,
		"year": 2020,
		"day_index": 5
	}
	var company_rows: Array = [{
		"id": "synthetic_energy",
		"ticker": "SYN",
		"name": "Synthetic Energy",
		"sector_id": "energy",
		"sector_name": "Energy",
		"current_price": 1000.0,
		"previous_close": 990.0,
		"daily_change_pct": 0.0101,
		"broker_flow": {"flow_tag": "accumulation"}
	}]
	var market_history: Array = [{
		"day_index": 5,
		"trade_date": trade_date.duplicate(true),
		"average_change_pct": 0.004,
		"advancers": 1,
		"decliners": 0,
		"biggest_winner": company_rows[0].duplicate(true),
		"biggest_loser": company_rows[0].duplicate(true)
	}]
	return NEWS_FEED_SYSTEM_SCRIPT.new().build_news_snapshot(
		synthetic_run_state,
		DataRepository.get_news_feed_data(),
		company_rows,
		market_history,
		[],
		[],
		[],
		trade_date,
		4
	)


func _setup_fixed_seed_run() -> void:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = CATALOG_COMPANY_COUNT
	difficulty_config["use_company_universe_catalog"] = true
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0


func _best_public_news_day_index() -> int:
	var day_counts: Dictionary = {}
	var dossier_state: Dictionary = RunState.get_company_story_dossier_state()
	var dossier_index: Dictionary = dossier_state.get("dossier_index", {})
	for dossier_value in dossier_index.values():
		if typeof(dossier_value) != TYPE_DICTIONARY:
			continue
		var dossier: Dictionary = dossier_value
		for clue_value in dossier.get("public_clues", []):
			if typeof(clue_value) != TYPE_DICTIONARY:
				continue
			var clue: Dictionary = clue_value
			if str(clue.get("surface_id", "")) != "news" or str(clue.get("visibility", "")) != "public":
				continue
			var earliest: int = int(clue.get("earliest_day_index", 0))
			var latest: int = int(clue.get("latest_day_index", earliest))
			for day_index in range(earliest, latest + 1):
				day_counts[day_index] = int(day_counts.get(day_index, 0)) + 1
	var best_day: int = -1
	var best_count: int = 0
	for day_value in day_counts.keys():
		var day_index: int = int(day_value)
		var count: int = int(day_counts.get(day_index, 0))
		if count > best_count:
			best_count = count
			best_day = day_index
	return best_day


func _market_entry_for_rows(company_rows: Array, trade_date: Dictionary, day_index: int) -> Dictionary:
	var total_change: float = 0.0
	var advancers: int = 0
	var decliners: int = 0
	var biggest_winner: Dictionary = {}
	var biggest_loser: Dictionary = {}
	for row_value in company_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var change_pct: float = float(row.get("daily_change_pct", 0.0))
		total_change += change_pct
		if change_pct >= 0.0:
			advancers += 1
		else:
			decliners += 1
		if biggest_winner.is_empty() or change_pct > float(biggest_winner.get("daily_change_pct", -999.0)):
			biggest_winner = row.duplicate(true)
		if biggest_loser.is_empty() or change_pct < float(biggest_loser.get("daily_change_pct", 999.0)):
			biggest_loser = row.duplicate(true)
	return {
		"day_index": day_index,
		"trade_date": trade_date.duplicate(true),
		"average_change_pct": total_change / float(max(company_rows.size(), 1)),
		"advancers": advancers,
		"decliners": decliners,
		"biggest_winner": biggest_winner,
		"biggest_loser": biggest_loser
	}


func _validate_generated_article(article: Dictionary, issues: Array[String], surface_counts: Dictionary) -> void:
	var article_id: String = str(article.get("id", ""))
	var surface_id: String = str(article.get("generated_surface_id", ""))
	_increment(surface_counts, surface_id)
	_validate_public_article_contract(article, issues)
	if str(article.get("source_system_id", "")) != "company_story_dossier":
		issues.append("bad_source_system:%s" % article_id)
	if str(article.get("visibility", "")) != "public":
		issues.append("bad_visibility:%s" % article_id)
	if float(article.get("leak_risk", 1.0)) > 0.0:
		issues.append("bad_leak_risk:%s" % article_id)
	if str(article.get("story_id", "")).is_empty():
		issues.append("missing_story_id:%s" % article_id)
	if _string_array(article.get("source_fact_ids", [])).is_empty():
		issues.append("missing_fact_ids:%s" % article_id)
	if _string_array(article.get("source_clue_ids", [])).is_empty():
		issues.append("missing_clue_ids:%s" % article_id)
	if _visible_copy_leaks_private_terms(article):
		issues.append("visible_private_leak:%s" % article_id)


func _validate_news_contract(snapshot: Dictionary, issues: Array[String]) -> void:
	if str(snapshot.get("access_model", "")) != "free_topic_coverage":
		issues.append("bad_news_access_model")
	if int(snapshot.get("public_depth_level", 0)) != 1:
		issues.append("bad_news_public_depth")
	var feeds: Dictionary = snapshot.get("feeds", {})
	for outlet_value in snapshot.get("outlets", []):
		if typeof(outlet_value) != TYPE_DICTIONARY:
			continue
		var outlet: Dictionary = outlet_value
		var outlet_id: String = str(outlet.get("id", ""))
		if str(outlet.get("label", "")) != str(EXPECTED_OUTLET_LABELS.get(outlet_id, "")):
			issues.append("bad_outlet_label:%s" % outlet_id)
		if str(outlet.get("coverage_type", "")) != str(EXPECTED_OUTLET_COVERAGE.get(outlet_id, "")):
			issues.append("bad_outlet_coverage:%s" % outlet_id)
		if not bool(outlet.get("unlocked", false)):
			issues.append("locked_outlet:%s" % outlet_id)
		if int(outlet.get("public_depth_level", 0)) != 1:
			issues.append("bad_outlet_public_depth:%s" % outlet_id)
		if _string_array(outlet.get("topic_ids", [])).is_empty():
			issues.append("missing_outlet_topics:%s" % outlet_id)
		var feed: Dictionary = feeds.get(outlet_id, {})
		if feed.is_empty():
			issues.append("missing_feed:%s" % outlet_id)
			continue
		if str(feed.get("coverage_type", "")) != str(EXPECTED_OUTLET_COVERAGE.get(outlet_id, "")):
			issues.append("bad_feed_coverage:%s" % outlet_id)
		if int(feed.get("public_depth_level", 0)) != 1:
			issues.append("bad_feed_public_depth:%s" % outlet_id)
		for article_value in feed.get("articles", []):
			if typeof(article_value) != TYPE_DICTIONARY:
				continue
			_validate_public_article_contract(article_value, issues)


func _validate_public_article_contract(article: Dictionary, issues: Array[String]) -> void:
	var article_id: String = str(article.get("id", article.get("headline", "")))
	if int(article.get("public_depth_level", 0)) != 1:
		issues.append("bad_article_public_depth:%s" % article_id)
	if str(article.get("access_model", "")) != "free_topic_coverage":
		issues.append("bad_article_access_model:%s" % article_id)
	if str(article.get("coverage_type", "")).is_empty():
		issues.append("missing_article_coverage:%s" % article_id)
	if _string_array(article.get("topic_ids", [])).is_empty():
		issues.append("missing_article_topics:%s" % article_id)
	if str(article.get("headline", "")).strip_edges().is_empty() or str(article.get("body", "")).strip_edges().is_empty():
		issues.append("missing_visible_article_copy:%s" % article_id)
	if _visible_copy_leaks_private_terms(article):
		issues.append("visible_private_leak:%s" % article_id)
	if bool(article.get("generated_content_surface", false)):
		if str(article.get("lead", "")).strip_edges().is_empty():
			issues.append("missing_generated_lead:%s" % article_id)
		if str(article.get("what_to_watch", "")).strip_edges().is_empty():
			issues.append("missing_generated_watch:%s" % article_id)


func _validate_news_archive_filter_contract(snapshot: Dictionary, trade_date: Dictionary, issues: Array[String]) -> void:
	var expected_year: int = int(trade_date.get("year", 0))
	var expected_month: int = int(trade_date.get("month", 0))
	for outlet_value in snapshot.get("outlets", []):
		if typeof(outlet_value) != TYPE_DICTIONARY:
			continue
		var outlet: Dictionary = outlet_value
		var outlet_id: String = str(outlet.get("id", ""))
		var feed: Dictionary = snapshot.get("feeds", {}).get(outlet_id, {})
		var feed_articles: Array = feed.get("articles", [])
		if feed_articles.is_empty():
			continue
		var summaries: Array = RunState.get_news_archive_article_summaries(outlet_id, expected_year, expected_month)
		if summaries.is_empty():
			issues.append("missing_archive_summaries:%s" % outlet_id)
			continue
		var saw_coverage: bool = false
		for summary_value in summaries:
			if typeof(summary_value) != TYPE_DICTIONARY:
				continue
			var summary: Dictionary = summary_value
			var summary_id: String = str(summary.get("id", ""))
			if int(summary.get("public_depth_level", 0)) != 1:
				issues.append("bad_archive_public_depth:%s" % summary_id)
			if str(summary.get("access_model", "")) != "free_topic_coverage":
				issues.append("bad_archive_access_model:%s" % summary_id)
			if str(summary.get("coverage_type", "")).is_empty():
				issues.append("missing_archive_coverage:%s" % summary_id)
			if _string_array(summary.get("topic_ids", [])).is_empty():
				issues.append("missing_archive_topics:%s" % summary_id)
			if str(summary.get("coverage_type", "")) == str(feed.get("coverage_type", "")):
				saw_coverage = true
			var full_article: Dictionary = RunState.get_news_archive_article(summary_id)
			if full_article.is_empty():
				issues.append("missing_archive_article:%s" % summary_id)
			elif int(full_article.get("public_depth_level", 0)) != 1 or str(full_article.get("coverage_type", "")).is_empty():
				issues.append("bad_archive_article_metadata:%s" % summary_id)
		if not saw_coverage:
			issues.append("archive_filter_coverage_gap:%s" % outlet_id)


func _visible_copy_leaks_private_terms(article: Dictionary) -> bool:
	var visible_text: String = " ".join([
		str(article.get("headline", "")),
		str(article.get("deck", "")),
		str(article.get("lead", "")),
		str(article.get("context", "")),
		str(article.get("market_reaction", "")),
		str(article.get("what_to_watch", "")),
		str(article.get("body", ""))
	]).to_lower()
	var forbidden_terms: Array = [
		"truth_state",
		"source_quality",
		"source trail",
		"source story",
		"private clue",
		"network clue",
		"clue|",
		"fact|",
		"story|"
	]
	for term in forbidden_terms:
		if visible_text.contains(str(term)):
			return true
	return false


func _article_payload_line(article: Dictionary) -> String:
	return "%s|%s|%s|%s|%s|facts=%s|clues=%s" % [
		str(article.get("outlet_id", "")),
		str(article.get("generated_surface_id", "")),
		str(article.get("story_id", "")),
		str(article.get("headline", "")),
		str(article.get("deck", "")),
		_array_payload(_string_array(article.get("source_fact_ids", []))),
		_array_payload(_string_array(article.get("source_clue_ids", [])))
	]


func _string_array(source_value: Variant) -> Array:
	var source_array: Array = []
	if typeof(source_value) == TYPE_ARRAY:
		source_array = source_value
	else:
		source_array = [source_value]
	var result: Array = []
	var seen: Dictionary = {}
	for item_value in source_array:
		var item: String = str(item_value).strip_edges()
		if item.is_empty() or seen.has(item):
			continue
		seen[item] = true
		result.append(item)
	return result


func _array_payload(values: Array) -> String:
	var string_values: Array = []
	for value in values:
		string_values.append(str(value))
	string_values.sort()
	return ",".join(string_values)


func _sorted_int_dictionary(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var keys: Array = source.keys()
	keys.sort()
	for key_value in keys:
		var key: String = str(key_value)
		result[key] = int(source.get(key_value, 0))
	return result


func _increment(counts: Dictionary, key: String) -> void:
	if key.strip_edges().is_empty():
		key = "unknown"
	counts[key] = int(counts.get(key, 0)) + 1


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int((hash_value ^ text.unicode_at(index)) * 16777619) & 0xFFFFFFFF
	return str(hash_value)


func _fail(message: String) -> void:
	push_error(message)
	print("CONTENT_SURFACE_NEWS_PREVIEW_FAIL %s" % message)
	get_tree().quit(1)
