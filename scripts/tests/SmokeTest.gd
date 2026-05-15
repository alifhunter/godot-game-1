extends Node

const COMPANY_FRAMEWORK_EVENT_IDS := {
	"earnings_beat": true,
	"earnings_miss": true,
	"strategic_acquisition": true,
	"integration_overhang": true,
	"product_launch": true,
	"product_recall": true,
	"management_upgrade": true,
	"management_exit": true
}
const SPECIAL_EVENT_IDS := {
	"covid_wave": true,
	"geopolitical_turmoil": true,
	"commodity_price_shock": true
}
const SMOKE_MODE_FULL := "full"
const SMOKE_MODE_QUICK := "quick"
const NORMAL_FULL_DAYS := 10
const NORMAL_QUICK_DAYS := 3
const GRIND_FULL_DAYS := 30
const QUICK_SMOKE_FLAG_PATH := "user://quick_smoke.flag"
const SMOKE_QUICK_ARG := "--smoke-quick"
const SMOKE_LOCAL_IO_ARG := "--smoke-local-io"
const NEWS_FEED_SYSTEM_SCRIPT = preload("res://systems/NewsFeedSystem.gd")
const TWOOTER_FEED_SYSTEM_SCRIPT = preload("res://systems/TwooterFeedSystem.gd")
const INDEX_REVIEW_SYSTEM_SCRIPT = preload("res://systems/IndexReviewSystem.gd")
const ATTENTION_DIRECTOR_SYSTEM_SCRIPT = preload("res://systems/AttentionDirectorSystem.gd")
const DIRTY_TIP_SYSTEM_SCRIPT = preload("res://systems/DirtyTipSystem.gd")
const SPECIAL_EVENT_SYSTEM_SCRIPT = preload("res://systems/SpecialEventSystem.gd")
const COMPANY_EVENT_SYSTEM_SCRIPT = preload("res://systems/CompanyEventSystem.gd")
const MARKET_SIMULATOR_SCRIPT = preload("res://systems/MarketSimulator.gd")
const COMPANY_GENERATOR_SCRIPT = preload("res://systems/CompanyGenerator.gd")
const CHART_SYSTEM_SCRIPT = preload("res://systems/ChartSystem.gd")
const CHART_PATTERN_SYSTEM_SCRIPT = preload("res://systems/ChartPatternSystem.gd")
const PRICE_CHART_CANVAS_SCRIPT = preload("res://scripts/ui/widgets/PriceChartCanvas.gd")
const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")

var trading_calendar = preload("res://systems/TradingCalendar.gd").new()
var batched_setup_progress_calls := 0
var batched_setup_progress_done := 0
var batched_setup_progress_total := 0


func _ready() -> void:
	var smoke_mode: String = _get_smoke_mode()
	DataRepository.reload_all()
	var release_readiness_validation: String = _validate_release_readiness_assets()
	if not release_readiness_validation.is_empty():
		push_error(release_readiness_validation)
		get_tree().quit(1)
		return

	var design_system_validation: String = _validate_design_system_assets()
	if not design_system_validation.is_empty():
		push_error(design_system_validation)
		get_tree().quit(1)
		return

	var network_data_validation: String = _validate_contact_network_data()
	if not network_data_validation.is_empty():
		push_error(network_data_validation)
		get_tree().quit(1)
		return

	var calendar_validation: String = _validate_trading_calendar_extension()
	if not calendar_validation.is_empty():
		push_error(calendar_validation)
		get_tree().quit(1)
		return

	var enriched_news_validation: String = _validate_enriched_news_generation()
	if not enriched_news_validation.is_empty():
		push_error(enriched_news_validation)
		get_tree().quit(1)
		return

	var enriched_social_validation: String = _validate_enriched_social_generation()
	if not enriched_social_validation.is_empty():
		push_error(enriched_social_validation)
		get_tree().quit(1)
		return

	var structured_chart_validation: String = _validate_structured_chart_generation()
	if not structured_chart_validation.is_empty():
		push_error(structured_chart_validation)
		get_tree().quit(1)
		return

	var macro_scale_validation: String = _validate_macro_scale_tier_generation()
	if not macro_scale_validation.is_empty():
		push_error(macro_scale_validation)
		get_tree().quit(1)
		return

	var corporate_action_price_validation: String = _validate_corporate_action_price_factor_limits()
	if not corporate_action_price_validation.is_empty():
		push_error(corporate_action_price_validation)
		get_tree().quit(1)
		return

	var index_review_content_validation: String = _validate_index_review_content_assets()
	if not index_review_content_validation.is_empty():
		push_error(index_review_content_validation)
		get_tree().quit(1)
		return

	var fishbowl_validation: String = _validate_fishbowl_overlay()
	if not fishbowl_validation.is_empty():
		push_error(fishbowl_validation)
		get_tree().quit(1)
		return

	var menu_result: Dictionary = await _validate_main_menu_flow()
	if not bool(menu_result.get("success", false)):
		push_error(str(menu_result.get("message", "Main menu smoke test failed.")))
		get_tree().quit(1)
		return

	var batched_setup_result: Dictionary = await _validate_batched_new_run_setup()
	if not bool(batched_setup_result.get("success", false)):
		push_error(str(batched_setup_result.get("message", "Batched startup smoke test failed.")))
		get_tree().quit(1)
		return

	var ftue_result: Dictionary = await _validate_ftue_flow()
	if not bool(ftue_result.get("success", false)):
		push_error(str(ftue_result.get("message", "FTUE smoke test failed.")))
		get_tree().quit(1)
		return

	var first_month_result: Dictionary = _validate_first_month_balance_smoke()
	if not bool(first_month_result.get("success", false)):
		push_error(str(first_month_result.get("message", "First-month balance smoke test failed.")))
		get_tree().quit(1)
		return

	var normal_days: int = NORMAL_QUICK_DAYS if smoke_mode == SMOKE_MODE_QUICK else NORMAL_FULL_DAYS
	var normal_result: Dictionary = await _run_scenario(424242, GameManager.DEFAULT_DIFFICULTY_ID, normal_days, 1, false)
	if not bool(normal_result.get("success", false)):
		push_error(str(normal_result.get("message", "Smoke test failed.")))
		get_tree().quit(1)
		return

	if smoke_mode == SMOKE_MODE_QUICK:
		var quick_line: String = "SMOKE_QUICK_OK normal_equity=%s days=%d summary=%s" % [
			String.num(float(normal_result.get("equity", 0.0)), 2),
			normal_days,
			str(normal_result.get("summary", ""))
		]
		print(quick_line)
		_write_smoke_result(quick_line)
		await get_tree().create_timer(1.0).timeout
		get_tree().quit()
		return

	var grind_result: Dictionary = await _run_scenario(987654, "grind", GRIND_FULL_DAYS, 10, true)
	if not bool(grind_result.get("success", false)):
		push_error(str(grind_result.get("message", "Grind smoke test failed.")))
		get_tree().quit(1)
		return

	var smoke_line: String = "SMOKE_OK normal_equity=%s grind_equity=%s grind_down_days=%d summary=%s" % [
		String.num(float(normal_result.get("equity", 0.0)), 2),
		String.num(float(grind_result.get("equity", 0.0)), 2),
		int(grind_result.get("down_days", 0)),
		str(normal_result.get("summary", ""))
	]
	print(smoke_line)
	_write_smoke_result(smoke_line)
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()


func _validate_fishbowl_overlay() -> String:
	var overlay: CanvasLayer = get_node_or_null("/root/FishbowlOverlay") as CanvasLayer
	if overlay == null:
		return "Smoke test expected the global FishbowlOverlay autoload to exist."
	var rect: ColorRect = overlay.get_node_or_null("FishbowlScreenOverlay") as ColorRect
	if rect == null:
		return "Smoke test expected FishbowlOverlay to create a fullscreen ColorRect."
	if rect.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		return "Smoke test expected FishbowlOverlay to ignore mouse input."
	if not (rect.material is ShaderMaterial):
		return "Smoke test expected FishbowlOverlay to use a ShaderMaterial."
	return ""


func _validate_first_month_balance_smoke() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var scenarios: Array = [
		{"seed": 303001, "tutorial": false, "guided": false},
		{"seed": 303002, "tutorial": true, "guided": true}
	]
	for scenario_value in scenarios:
		var scenario: Dictionary = scenario_value
		var run_seed: int = int(scenario.get("seed", 0))
		var company_definitions: Array = GameManager.build_company_roster(run_seed, difficulty_config)
		RunState.setup_new_run(run_seed, company_definitions, difficulty_config, bool(scenario.get("tutorial", false)))
		GameManager.simulate_opening_session(false)
		var expected_guided_meeting_id: String = ""
		if bool(scenario.get("guided", false)):
			var buy_company_id: String = _first_affordable_lot_company_id()
			if buy_company_id.is_empty():
				return {"success": false, "message": "First-month smoke expected an affordable guided starter stock."}
			var buy_result: Dictionary = GameManager.buy_lots(buy_company_id, 1)
			if not bool(buy_result.get("success", false)):
				return {"success": false, "message": "First-month smoke could not buy a guided starter lot: %s" % str(buy_result.get("message", ""))}
			GameManager.start_guide_flow("corporate_event_flow")
			var hook_result: Dictionary = GameManager.ensure_first_hour_guide_hook()
			if not bool(hook_result.get("success", false)):
				return {"success": false, "message": "First-month smoke expected the guided RUPSLB hook to schedule: %s" % str(hook_result.get("message", ""))}
			expected_guided_meeting_id = str(hook_result.get("meeting", {}).get("id", ""))

		var life_payment_count: int = 0
		var saw_life_warning: bool = false
		var saw_next_five_life: bool = false
		var saw_next_five_report: bool = false
		var saw_next_five_meeting: bool = false
		for _day in range(30):
			var snapshot_before: Dictionary = GameManager.get_first_month_balance_snapshot()
			var next_payment: Dictionary = snapshot_before.get("next_life_payment", {})
			if not next_payment.is_empty() and int(next_payment.get("due_in_trading_days", 99)) <= 3:
				var life_warning_found: bool = false
				for warning_value in snapshot_before.get("warning_rows", []):
					if typeof(warning_value) == TYPE_DICTIONARY and str(warning_value.get("id", "")) == "life_due":
						life_warning_found = true
						break
				if not life_warning_found:
					return {"success": false, "message": "First-month smoke expected a Life due warning within 3 trading days."}
				saw_life_warning = true
			for row_value in snapshot_before.get("next_five_trading_days", []):
				if typeof(row_value) != TYPE_DICTIONARY:
					continue
				var row: Dictionary = row_value
				match str(row.get("type", "")):
					"life":
						saw_next_five_life = true
					"report":
						saw_next_five_report = true
					"meeting":
						if expected_guided_meeting_id.is_empty() or str(row.get("label", "")).find("RUPSLB") >= 0 or str(row.get("detail", "")).to_lower().find("stock split") >= 0:
							saw_next_five_meeting = true

			GameManager.simulate_opening_session(false)
			if not RunState.last_day_results.get("life_obligation", {}).is_empty():
				life_payment_count += 1
			var cash_after: float = float(GameManager.get_portfolio_snapshot().get("cash", 0.0))
			if cash_after < 0.0:
				return {"success": false, "message": "First-month smoke expected cash to stay non-negative through day 30."}
			var trading_day_number: int = max(RunState.day_index + 1, 1)
			var organic_count: int = _smoke_organic_corporate_chain_count()
			if trading_day_number < 8 and organic_count > 0:
				return {"success": false, "message": "First-month smoke found an organic corporate chain before day 8."}
			if trading_day_number <= 15 and organic_count > 1:
				return {"success": false, "message": "First-month smoke found more than 1 organic chain through day 15."}
			if trading_day_number <= 25 and organic_count > 2:
				return {"success": false, "message": "First-month smoke found more than 2 organic chains through day 25."}

		if life_payment_count != 1:
			return {"success": false, "message": "First-month smoke expected exactly one Life payment in 30 trading days, got %d." % life_payment_count}
		if not saw_life_warning or not saw_next_five_life:
			return {"success": false, "message": "First-month smoke expected Life warnings and lookahead Life rows before the first payment."}
		if not saw_next_five_report:
			return {"success": false, "message": "First-month smoke expected the first-month lookahead data to include a report row."}
		if bool(scenario.get("guided", false)) and not saw_next_five_meeting:
			return {"success": false, "message": "First-month smoke expected guided lookahead data to include the seeded RUPSLB meeting."}
		if bool(scenario.get("guided", false)):
			var recap_snapshot: Dictionary = GameManager.get_daily_recap_snapshot()
			if recap_snapshot.get("summary", {}).get("portfolio_attribution", []).is_empty():
				return {"success": false, "message": "First-month smoke expected Daily Recap data to include portfolio attribution for holdings."}
	return {"success": true}


func _first_affordable_lot_company_id() -> String:
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var estimate: Dictionary = GameManager.estimate_buy_lots(company_id, 1)
		if bool(estimate.get("success", false)):
			return company_id
	return ""


func _smoke_organic_corporate_chain_count() -> int:
	var count: int = 0
	for chain_value in RunState.get_active_corporate_action_chains().values():
		if typeof(chain_value) != TYPE_DICTIONARY:
			continue
		var chain: Dictionary = chain_value
		var source: String = str(chain.get("request_source", "organic")).strip_edges()
		if source.is_empty() or source == "organic":
			count += 1
		elif source != "guided_first_hour" and not source.begins_with("debug"):
			count += 1
	return count


func _validate_enriched_news_generation() -> String:
	var news_system = NEWS_FEED_SYSTEM_SCRIPT.new()
	var feed_data: Dictionary = DataRepository.get_news_feed_data()
	var trade_date: Dictionary = {
		"weekday": 3,
		"day": 8,
		"month": 1,
		"year": 2020,
		"day_index": 7
	}
	var company_rows: Array = [{
		"id": "mock_bank",
		"ticker": "MBNK",
		"name": "Mock Bank Tbk",
		"sector_id": "finance",
		"sector_name": "Finance",
		"current_price": 1200.0,
		"daily_change_pct": 0.036,
		"broker_flow": {"flow_tag": "accumulation"}
	}]
	var market_history: Array = [
		{
			"day_index": 6,
			"trade_date": {"weekday": 2, "day": 7, "month": 1, "year": 2020, "day_index": 6},
			"average_change_pct": 0.004,
			"advancers": 18,
			"decliners": 12,
			"biggest_winner": {"ticker": "MBNK"},
			"biggest_loser": {"ticker": "DROP"}
		},
		{
			"day_index": 7,
			"trade_date": trade_date.duplicate(true),
			"average_change_pct": 0.006,
			"advancers": 20,
			"decliners": 10,
			"biggest_winner": {"ticker": "MBNK"},
			"biggest_loser": {"ticker": "DROP"}
		}
	]
	var event_history: Array = [
		{
			"event_id": "rights_issue",
			"event_family": "corporate_action",
			"scope": "company",
			"category": "corporate_action_rumor",
			"tone": "positive",
			"target_company_id": "mock_bank",
			"target_ticker": "MBNK",
			"target_company_name": "Mock Bank Tbk",
			"target_sector_id": "finance",
			"headline": "MBNK rumor flow starts",
			"summary": "Early rights issue talk is drawing attention before any formal notice.",
			"source_chain_id": "mock_chain",
			"chain_family": "rights_issue",
			"day_index": 6,
			"trade_date": {"weekday": 2, "day": 7, "month": 1, "year": 2020, "day_index": 6}
		},
		{
			"event_id": "rights_issue",
			"event_family": "corporate_action",
			"scope": "company",
			"category": "corporate_action_filing",
			"tone": "positive",
			"target_company_id": "mock_bank",
			"target_ticker": "MBNK",
			"target_company_name": "Mock Bank Tbk",
			"target_sector_id": "finance",
			"headline": "MBNK formally schedules RUPSLB",
			"summary": "Mock Bank Tbk now has a formal RUPSLB notice tied to the rights issue plan.",
			"source_chain_id": "mock_chain",
			"chain_family": "rights_issue",
			"meeting_id": "mock_meeting",
			"venue_type": "rupslb",
			"day_index": 7,
			"trade_date": trade_date.duplicate(true)
		}
	]
	var first_snapshot: Dictionary = news_system.build_news_snapshot(
		null,
		feed_data,
		company_rows,
		market_history,
		event_history,
		[],
		[],
		trade_date,
		4
	)
	var second_snapshot: Dictionary = news_system.build_news_snapshot(
		null,
		feed_data,
		company_rows,
		market_history,
		event_history,
		[],
		[],
		trade_date,
		4
	)
	var continuity_article: Dictionary = {}
	for feed_value in first_snapshot.get("feeds", {}).values():
		var feed: Dictionary = feed_value
		for article_value in feed.get("articles", []):
			var article: Dictionary = article_value
			if not str(article.get("public_continuity_phrase", "")).is_empty():
				continuity_article = article
				break
		if not continuity_article.is_empty():
			break
	if continuity_article.is_empty():
		return "Smoke test expected enriched News generation to create a continuity phrase for related corporate-action history."
	if str(continuity_article.get("public_story_angle", "")).is_empty() or str(continuity_article.get("public_confidence_label", "")).is_empty():
		return "Smoke test expected enriched News articles to expose public story angle and confidence metadata."
	var body: String = str(continuity_article.get("body", ""))
	var paragraph_count: int = body.split("\n\n", false).size()
	if paragraph_count < 5:
		return "Smoke test expected enriched News article bodies to have at least 5 paragraphs, found %d." % paragraph_count
	var forbidden_terms: Array = [
		"source_chain_id",
		"current_timeline_state",
		"management stance",
		"hidden_positioning",
		"formal_agenda_or_filing",
		"meeting_or_call"
	]
	var searchable_body: String = body.to_lower()
	for forbidden_term_value in forbidden_terms:
		var forbidden_term: String = str(forbidden_term_value)
		if searchable_body.find(forbidden_term) != -1:
			return "Smoke test expected enriched News copy to avoid raw system wording like %s." % forbidden_term
	var first_body_by_id: Dictionary = {}
	for feed_value in first_snapshot.get("feeds", {}).values():
		var feed: Dictionary = feed_value
		for article_value in feed.get("articles", []):
			var article: Dictionary = article_value
			first_body_by_id[str(article.get("id", ""))] = str(article.get("body", ""))
	for feed_value in second_snapshot.get("feeds", {}).values():
		var feed: Dictionary = feed_value
		for article_value in feed.get("articles", []):
			var article: Dictionary = article_value
			var article_id: String = str(article.get("id", ""))
			if first_body_by_id.has(article_id) and str(article.get("body", "")) != str(first_body_by_id.get(article_id, "")):
				return "Smoke test expected enriched News article copy to be deterministic for article %s." % article_id
	var level_one_snapshot: Dictionary = news_system.build_news_snapshot(
		null,
		feed_data,
		company_rows,
		market_history,
		event_history,
		[],
		[],
		trade_date,
		1
	)
	var level_one_feed: Dictionary = level_one_snapshot.get("feeds", {}).get("gorengan_daily", {})
	var level_one_articles: Array = level_one_feed.get("articles", [])
	var has_current_day_article: bool = false
	var has_current_day_non_market_wrap: bool = false
	for article_value in level_one_articles:
		var article: Dictionary = article_value
		if int(article.get("day_index", -1)) != int(trade_date.get("day_index", -2)):
			continue
		has_current_day_article = true
		if str(article.get("category", "")) != "market_wrap":
			has_current_day_non_market_wrap = true
	if not has_current_day_article or not has_current_day_non_market_wrap:
		return "Smoke test expected level 1 Gorengan Daily to include current-day public briefs beyond the market wrap."
	var tape_regex := RegEx.new()
	tape_regex.compile("\\btape\\b")
	for feed_value in first_snapshot.get("feeds", {}).values():
		var feed: Dictionary = feed_value
		for article_value in feed.get("articles", []):
			var article: Dictionary = article_value
			var visible_text: String = "%s\n%s\n%s\n%s\n%s" % [
				str(article.get("headline", "")),
				str(article.get("deck", "")),
				str(article.get("body", "")),
				str(article.get("public_story_angle", "")),
				str(article.get("public_confidence_label", ""))
			]
			if tape_regex.search(visible_text.to_lower()) != null:
				return "Smoke test expected generated News copy to avoid the word tape in player-visible text."
	var level_one_authors: Dictionary = {}
	for day_offset in range(4):
		var day_trade_date: Dictionary = trade_date.duplicate(true)
		day_trade_date["day_index"] = int(trade_date.get("day_index", 0)) + day_offset
		day_trade_date["day"] = int(trade_date.get("day", 1)) + day_offset
		var day_market_entry: Dictionary = market_history[0].duplicate(true)
		day_market_entry["day_index"] = int(day_trade_date.get("day_index", 0))
		day_market_entry["trade_date"] = day_trade_date.duplicate(true)
		var day_snapshot: Dictionary = news_system.build_news_snapshot(
			null,
			feed_data,
			company_rows,
			[day_market_entry],
			[],
			[],
			[],
			day_trade_date,
			1
		)
		var day_feed: Dictionary = day_snapshot.get("feeds", {}).get("gorengan_daily", {})
		for article_value in day_feed.get("articles", []):
			var article: Dictionary = article_value
			var author_name: String = str(article.get("author_name", ""))
			if not author_name.is_empty():
				level_one_authors[author_name] = true
	if level_one_authors.size() < 2:
		return "Smoke test expected level 1 News public briefs to rotate across at least two authors over several days."
	return ""


func _validate_enriched_social_generation() -> String:
	var social_system = TWOOTER_FEED_SYSTEM_SCRIPT.new()
	var feed_data: Dictionary = DataRepository.get_twooter_feed_data()
	var trade_date: Dictionary = {
		"weekday": 3,
		"day": 8,
		"month": 1,
		"year": 2020,
		"day_index": 7
	}
	var company_rows: Array = [{
		"id": "mock_bank",
		"ticker": "MBNK",
		"name": "Mock Bank Tbk",
		"sector_id": "finance",
		"sector_name": "Finance",
		"current_price": 1200.0,
		"daily_change_pct": 0.036,
		"broker_flow": {"flow_tag": "accumulation"}
	}]
	var market_history: Array = [{
		"day_index": 7,
		"trade_date": trade_date.duplicate(true),
		"average_change_pct": 0.006,
		"advancers": 20,
		"decliners": 10,
		"biggest_winner": {"ticker": "MBNK"},
		"biggest_loser": {"ticker": "DROP"}
	}]
	var event_history: Array = [
		{
			"event_id": "rights_issue",
			"event_family": "corporate_action",
			"scope": "company",
			"category": "corporate_action_rumor",
			"tone": "positive",
			"target_company_id": "mock_bank",
			"target_ticker": "MBNK",
			"target_company_name": "Mock Bank Tbk",
			"target_sector_id": "finance",
			"summary": "Early rights issue talk is drawing attention before any formal notice.",
			"source_chain_id": "mock_chain",
			"chain_family": "rights_issue",
			"day_index": 6,
			"trade_date": {"weekday": 2, "day": 7, "month": 1, "year": 2020, "day_index": 6}
		},
		{
			"event_id": "rights_issue",
			"event_family": "corporate_action",
			"scope": "company",
			"category": "corporate_action_filing",
			"tone": "positive",
			"target_company_id": "mock_bank",
			"target_ticker": "MBNK",
			"target_company_name": "Mock Bank Tbk",
			"target_sector_id": "finance",
			"summary": "Mock Bank Tbk now has a formal RUPSLB notice tied to the rights issue plan.",
			"source_chain_id": "mock_chain",
			"chain_family": "rights_issue",
			"meeting_id": "mock_meeting",
			"venue_type": "rupslb",
			"day_index": 7,
			"trade_date": trade_date.duplicate(true)
		}
	]
	var first_snapshot: Dictionary = social_system.build_social_snapshot(
		null,
		feed_data,
		company_rows,
		market_history,
		event_history,
		[],
		[],
		trade_date,
		4
	)
	var level_one_snapshot: Dictionary = social_system.build_social_snapshot(
		null,
		feed_data,
		company_rows,
		market_history,
		event_history,
		[],
		[],
		trade_date,
		1
	)
	var second_snapshot: Dictionary = social_system.build_social_snapshot(
		null,
		feed_data,
		company_rows,
		market_history,
		event_history,
		[],
		[],
		trade_date,
		4
	)
	var posts: Array = first_snapshot.get("posts", [])
	var has_thread_post: bool = false
	var has_continuity_post: bool = false
	var has_new_fictional_account_post: bool = false
	var level_one_posts: Array = level_one_snapshot.get("posts", [])
	var level_one_count: int = social_system.count_social_posts(
		feed_data,
		market_history,
		event_history,
		[],
		[],
		trade_date,
		1,
		company_rows
	)
	if level_one_count != level_one_posts.size():
		return "Smoke test expected Twooter count_social_posts to match rendered level 1 post count."
	var has_level_one_current_day_ambient: bool = false
	for post_value in level_one_posts:
		var post: Dictionary = post_value
		if str(post.get("post_text", "")).strip_edges().is_empty():
			return "Smoke test expected level 1 Twooter to reject blank post text."
		if (
			int(post.get("day_index", -1)) == int(trade_date.get("day_index", -2)) and
			str(post.get("event_family", "")) == "ambient" and
			str(post.get("category", "")) != "market_wrap"
		):
			has_level_one_current_day_ambient = true
	if not has_level_one_current_day_ambient:
		return "Smoke test expected level 1 Twooter to include current-day ambient chatter beyond market wrap."
	var fallback_feed_data: Dictionary = feed_data.duplicate(true)
	fallback_feed_data["accounts"] = [{
		"id": "blank_template_voice",
		"display_name": "Blank Template Voice",
		"handle": "@blanktemplate",
		"tier": 1,
		"verified": false,
		"voice": "blank_template_voice"
	}]
	fallback_feed_data["voice_templates"] = {"blank_template_voice": {}}
	var fallback_snapshot: Dictionary = social_system.build_social_snapshot(
		null,
		fallback_feed_data,
		company_rows,
		market_history,
		[],
		[],
		[],
		trade_date,
		1
	)
	var fallback_posts: Array = fallback_snapshot.get("posts", [])
	if fallback_posts.is_empty() or str(fallback_posts[0].get("post_text", "")).strip_edges().is_empty():
		return "Smoke test expected Twooter fallback templates to prevent blank posts when an account voice lacks a matching template."
	var fallback_second_snapshot: Dictionary = social_system.build_social_snapshot(
		null,
		fallback_feed_data,
		company_rows,
		market_history,
		[],
		[],
		[],
		trade_date,
		1
	)
	var fallback_second_posts: Array = fallback_second_snapshot.get("posts", [])
	if fallback_second_posts.is_empty() or str(fallback_second_posts[0].get("post_text", "")) != str(fallback_posts[0].get("post_text", "")):
		return "Smoke test expected Twooter fallback template output to be deterministic."
	var forbidden_terms: Array = [
		"source_chain_id",
		"chain_family",
		"meeting_id",
		"venue_type",
		"current_timeline_state",
		"hidden_positioning",
		"formal_agenda_or_filing",
		"meeting_or_call"
	]
	var new_account_ids := {
		"market_diary_id": true,
		"oil_tape_watch": true,
		"stockmap_notes": true,
		"emiten_concepts": true,
		"quality_hold_id": true,
		"macro_classroom": true
	}
	for post_value in posts:
		var post: Dictionary = post_value
		if str(post.get("post_text", "")).strip_edges().is_empty():
			return "Smoke test expected enriched Twooter generation to reject blank post text."
		if new_account_ids.has(str(post.get("account_id", ""))):
			has_new_fictional_account_post = true
		if not post.get("thread_lines", []).is_empty():
			has_thread_post = true
		if not str(post.get("public_continuity_phrase", "")).is_empty():
			has_continuity_post = true
		var visible_text: String = "%s\n%s\n%s\n%s" % [
			str(post.get("post_text", "")),
			"\n".join(post.get("thread_lines", [])),
			str(post.get("context_hint", "")),
			str(post.get("public_topic_label", ""))
		]
		var searchable_text: String = visible_text.to_lower()
		if searchable_text.find("{") != -1 or searchable_text.find("}") != -1:
			return "Smoke test expected enriched Twooter copy to avoid unresolved placeholders."
		for forbidden_term_value in forbidden_terms:
			var forbidden_term: String = str(forbidden_term_value)
			if searchable_text.find(forbidden_term) != -1:
				return "Smoke test expected enriched Twooter copy to avoid raw system wording like %s." % forbidden_term
	if not has_thread_post:
		return "Smoke test expected enriched Twooter generation to include at least one thread post."
	if not has_continuity_post:
		return "Smoke test expected enriched Twooter generation to include a continuity-aware post."
	if not has_new_fictional_account_post:
		return "Smoke test expected enriched Twooter generation to surface a new fictional inspired account."
	var first_posts_by_id: Dictionary = {}
	for post_value in posts:
		var post: Dictionary = post_value
		first_posts_by_id[str(post.get("id", ""))] = {
			"text": str(post.get("post_text", "")),
			"thread": post.get("thread_lines", []).duplicate(true),
			"account_id": str(post.get("account_id", ""))
		}
	for post_value in second_snapshot.get("posts", []):
		var post: Dictionary = post_value
		var post_id: String = str(post.get("id", ""))
		if not first_posts_by_id.has(post_id):
			continue
		var first_post: Dictionary = first_posts_by_id.get(post_id, {})
		if (
			str(first_post.get("text", "")) != str(post.get("post_text", "")) or
			str(first_post.get("account_id", "")) != str(post.get("account_id", "")) or
			first_post.get("thread", []) != post.get("thread_lines", [])
			):
			return "Smoke test expected enriched Twooter copy to be deterministic for post %s." % post_id
	return ""


func _validate_structured_chart_generation() -> String:
	var generator = COMPANY_GENERATOR_SCRIPT.new()
	var chart_system = CHART_SYSTEM_SCRIPT.new()
	var pattern_system = CHART_PATTERN_SYSTEM_SCRIPT.new()
	var run_seed: int = 135791
	var technical_signal_validation: String = _validate_technical_signal_detection(chart_system)
	if not technical_signal_validation.is_empty():
		return technical_signal_validation
	var cycle_anchor_validation: String = _validate_hidden_cycle_anchor_generation(generator)
	if not cycle_anchor_validation.is_empty():
		return cycle_anchor_validation
	var microstructure_validation: String = _validate_hidden_microstructure_generation(generator)
	if not microstructure_validation.is_empty():
		return microstructure_validation
	var roster: Array = GameManager.build_company_roster(
		run_seed,
		GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	)
	var trade_dates: Array = _build_smoke_historical_trade_dates(1260)
	if trade_dates.size() != 1260:
		return "Smoke test expected structured chart history to build 1260 trade dates."
	if roster.size() < 12:
		return "Smoke test expected the generated roster to include enough companies for chart-profile diversity."

	var required_indicator_ids := ["sma_3", "sma_5", "sma_10", "sma_20", "sma_60", "sma_100", "sma_200", "ema_20", "rsi_14", "macd_12_26_9"]
	var indicator_catalog: Array = chart_system.get_indicator_catalog()
	for indicator_id_value in required_indicator_ids:
		var indicator_id: String = str(indicator_id_value)
		if not _chart_catalog_has_id(indicator_catalog, indicator_id):
			return "Smoke test expected chart indicator catalog to include %s." % indicator_id

	var upgrade_validation: String = _validate_structured_chart_upgrade_tiers()
	if not upgrade_validation.is_empty():
		return upgrade_validation

	var range_catalog: Array = chart_system.get_available_ranges()
	if not _chart_smoke_range_order_matches(range_catalog, ["1d", "1w", "1m", "3m", "6m", "1y", "5y", "ytd"]):
		return "Smoke test expected chart ranges to include 3M/6M in the planned order."

	var required_pattern_ids := [
		"double_bottom",
		"double_top",
		"cup_handle",
		"head_shoulders",
		"inverse_head_shoulders",
		"ascending_triangle",
		"descending_triangle",
		"bull_flag",
		"sma_support_bounce",
		"sma_resistance_rejection",
		"breakout_retest",
		"breakdown"
	]
	var pattern_catalog: Array = pattern_system.get_pattern_catalog()
	for pattern_id_value in required_pattern_ids:
		var pattern_id: String = str(pattern_id_value)
		if not _chart_catalog_has_id(pattern_catalog, pattern_id):
			return "Smoke test expected chart pattern catalog to include %s." % pattern_id

	var archetypes := {}
	var biases := {}
	var chart_intents := {}
	var pattern_variants := {}
	var saw_hidden_cycle: bool = false
	var saw_operator_cycle_metadata: bool = false
	var saw_bullish_history: bool = false
	var saw_bearish_history: bool = false
	var saw_sideways_history: bool = false
	var saw_support_sma: bool = false
	var saw_resistance_sma: bool = false
	var saw_gap_up: bool = false
	var saw_gap_down: bool = false
	var deterministic_reference: Dictionary = {}
	var tested_count: int = 0

	for definition_value in roster:
		if typeof(definition_value) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = definition_value
		var company_id: String = str(definition.get("id", ""))
		var sector: Dictionary = DataRepository.get_sector_definition(str(definition.get("sector_id", "")))
		var profile: Dictionary = generator.generate_company_profile(definition, sector, run_seed)
		var traits: Dictionary = profile.get("generation_traits", {})
		var chart_profile: Dictionary = traits.get("chart_profile", {})
		if chart_profile.is_empty():
			return "Smoke test expected %s to receive hidden chart_profile metadata." % company_id
		if str(chart_profile.get("primary_pattern", "")).is_empty():
			return "Smoke test expected %s chart_profile to include a primary pattern." % company_id
		if str(chart_profile.get("pattern_variant", "")).strip_edges().is_empty():
			return "Smoke test expected %s chart_profile to include a hidden pattern variant." % company_id
		var chart_intent: String = str(chart_profile.get("chart_intent", ""))
		var pattern_timeframe: String = str(chart_profile.get("pattern_timeframe", ""))
		var gap_style: String = str(chart_profile.get("gap_style", ""))
		var gap_bias: String = str(chart_profile.get("gap_bias", ""))
		var gap_frequency: String = str(chart_profile.get("gap_frequency", ""))
		var gap_followthrough: String = str(chart_profile.get("gap_followthrough", ""))
		var cycle_template: String = str(chart_profile.get("cycle_template", ""))
		var operator_pressure: float = float(chart_profile.get("operator_pressure", 0.0))
		var tempo_profile: String = str(chart_profile.get("cycle_tempo_profile", ""))
		var shakeout_profile: String = str(chart_profile.get("shakeout_profile", ""))
		var microstructure_intensity: float = float(chart_profile.get("microstructure_intensity", 0.0))
		var setup_duration_bias: float = float(chart_profile.get("setup_duration_bias", 0.0))
		var bar_friction_profile: String = str(chart_profile.get("bar_friction_profile", ""))
		var microleg_frequency_bias: float = float(chart_profile.get("microleg_frequency_bias", 0.0))
		var wick_noise_intensity: float = float(chart_profile.get("wick_noise_intensity", 0.0))
		var volume_disagreement_rate: float = float(chart_profile.get("volume_disagreement_rate", 0.0))
		var tape_regime_profile: String = str(chart_profile.get("tape_regime_profile", ""))
		var regime_block_intensity: float = float(chart_profile.get("regime_block_intensity", 0.0))
		var regime_tempo_bias: float = float(chart_profile.get("regime_tempo_bias", 0.0))
		if not ["investing", "swing_trading", "short_term_trading", "speculative"].has(chart_intent):
			return "Smoke test expected %s chart_profile to include a valid chart_intent." % company_id
		if not ["5y", "1y", "6m", "3m", "1m"].has(pattern_timeframe):
			return "Smoke test expected %s chart_profile to include a valid pattern_timeframe." % company_id
		if not ["none", "news_gap", "breakout_gap", "exhaustion_gap", "rug_gap", "mixed"].has(gap_style):
			return "Smoke test expected %s chart_profile to include a valid gap_style." % company_id
		if not ["up", "down", "mixed"].has(gap_bias):
			return "Smoke test expected %s chart_profile to include a valid gap_bias." % company_id
		if not ["rare", "moderate", "active"].has(gap_frequency):
			return "Smoke test expected %s chart_profile to include a valid gap_frequency." % company_id
		if not ["hold", "fade", "fill", "continue"].has(gap_followthrough):
			return "Smoke test expected %s chart_profile to include a valid gap_followthrough." % company_id
		if operator_pressure < 0.0 or operator_pressure > 1.0:
			return "Smoke test expected %s operator pressure to stay normalized." % company_id
		if not ["slow_setup", "normal_setup", "fast_operator", "failed_setup"].has(tempo_profile):
			return "Smoke test expected %s chart_profile to include a valid hidden tempo profile." % company_id
		if not ["none", "healthy_pullback", "hard_shakeout", "dead_cat", "failed_reclaim"].has(shakeout_profile):
			return "Smoke test expected %s chart_profile to include a valid hidden shakeout profile." % company_id
		if microstructure_intensity < 0.0 or microstructure_intensity > 1.0:
			return "Smoke test expected %s microstructure intensity to stay normalized." % company_id
		if setup_duration_bias < -1.0 or setup_duration_bias > 1.0:
			return "Smoke test expected %s setup duration bias to stay normalized." % company_id
		if not ["clean_liquid", "balanced_chop", "operator_dirty", "distribution_chop"].has(bar_friction_profile):
			return "Smoke test expected %s chart_profile to include a valid hidden bar friction profile." % company_id
		if microleg_frequency_bias < 0.0 or microleg_frequency_bias > 1.0:
			return "Smoke test expected %s microleg frequency bias to stay normalized." % company_id
		if wick_noise_intensity < 0.0 or wick_noise_intensity > 1.0:
			return "Smoke test expected %s wick noise intensity to stay normalized." % company_id
		if volume_disagreement_rate < 0.0 or volume_disagreement_rate > 1.0:
			return "Smoke test expected %s volume disagreement rate to stay normalized." % company_id
		if not ["clean_trend", "messy_accumulation", "operator_campaign", "distribution_breakdown", "failed_reclaim"].has(tape_regime_profile):
			return "Smoke test expected %s chart_profile to include a valid hidden tape regime profile." % company_id
		if regime_block_intensity < 0.0 or regime_block_intensity > 1.0:
			return "Smoke test expected %s regime block intensity to stay normalized." % company_id
		if regime_tempo_bias < -1.0 or regime_tempo_bias > 1.0:
			return "Smoke test expected %s regime tempo bias to stay normalized." % company_id
		if not cycle_template.is_empty():
			if not ["markup_clean", "markup_exhaustion", "distribution_clean", "failed_markup", "operator_markup", "operator_rug"].has(cycle_template):
				return "Smoke test expected %s to use a known hidden cycle template." % company_id
			if float(chart_profile.get("cycle_strength", 0.0)) <= 0.0:
				return "Smoke test expected %s hidden cycle to include positive strength." % company_id
			var fib_ratios_value = chart_profile.get("cycle_fib_ratios", {})
			if typeof(fib_ratios_value) != TYPE_DICTIONARY or (fib_ratios_value as Dictionary).is_empty():
				return "Smoke test expected %s hidden cycle to include Fibonacci-like ratios." % company_id
			if shakeout_profile == "none" or microstructure_intensity <= 0.0:
				return "Smoke test expected %s hidden cycle to include structured microstructure metadata." % company_id
			saw_hidden_cycle = true
			if cycle_template.begins_with("operator"):
				saw_operator_cycle_metadata = true
		if chart_intent == "investing" and not ["5y", "1y"].has(pattern_timeframe):
			return "Smoke test expected investing chart profile %s to focus pattern structure on 1Y/5Y." % company_id
		if chart_intent in ["short_term_trading", "speculative"] and not ["1m", "3m", "6m"].has(pattern_timeframe):
			return "Smoke test expected trading chart profile %s to focus pattern structure on 1M/3M/6M." % company_id
		archetypes[str(chart_profile.get("archetype", ""))] = true
		biases[str(chart_profile.get("bias", ""))] = true
		chart_intents[chart_intent] = true
		pattern_variants["%s:%s" % [
			str(chart_profile.get("primary_pattern", "")),
			str(chart_profile.get("pattern_variant", ""))
		]] = true

		var base_price: float = float(profile.get("base_price", 0.0))
		var bars: Array = generator.build_historical_chart_bars(profile, trade_dates, base_price, run_seed, company_id)
		if bars.size() != 1260:
			return "Smoke test expected %s structured chart history to contain 1260 bars, got %d." % [company_id, bars.size()]
		if not _chart_smoke_bars_are_valid(bars):
			return "Smoke test expected %s structured chart bars to keep valid OHLCV values." % company_id
		var end_close: float = _chart_smoke_close_at(bars, bars.size() - 1)
		var tick_tolerance: float = max(GameManager.get_tick_size_for_price(base_price), 1.0)
		if absf(end_close - base_price) > tick_tolerance:
			return "Smoke test expected %s structured chart history to end near base price %.2f, got %.2f." % [
				company_id,
				base_price,
				end_close
			]

		if deterministic_reference.is_empty():
			var repeat_bars: Array = generator.build_historical_chart_bars(profile, trade_dates, base_price, run_seed, company_id)
			if not _chart_smoke_histories_match(bars, repeat_bars):
				return "Smoke test expected structured chart generation to be deterministic for %s." % company_id
			var stripped_profile: Dictionary = profile.duplicate(true)
			var stripped_traits: Dictionary = traits.duplicate(true)
			stripped_traits.erase("chart_profile")
			stripped_profile["generation_traits"] = stripped_traits
			var derived_bars: Array = generator.build_historical_chart_bars(stripped_profile, trade_dates, base_price, run_seed, company_id)
			if derived_bars.size() != 1260 or not _chart_smoke_histories_match(derived_bars, generator.build_historical_chart_bars(stripped_profile, trade_dates, base_price, run_seed, company_id)):
				return "Smoke test expected missing chart_profile metadata to derive deterministic history for old saves."
			var snapshot: Dictionary = chart_system.build_chart_snapshot_from_bars(bars, "5y", required_indicator_ids)
			if snapshot.get("indicator_snapshots", []).size() != required_indicator_ids.size():
				return "Smoke test expected 5Y chart snapshots to render all upgraded indicators."
			var macd_snapshot: Dictionary = _chart_smoke_indicator_snapshot(snapshot, "macd_12_26_9")
			if macd_snapshot.is_empty():
				return "Smoke test expected chart snapshots to include MACD 12/26/9."
			if macd_snapshot.get("macd_values", []).size() != int(snapshot.get("display_bar_count", 0)) or macd_snapshot.get("signal_values", []).size() != int(snapshot.get("display_bar_count", 0)) or macd_snapshot.get("histogram_values", []).size() != int(snapshot.get("display_bar_count", 0)):
				return "Smoke test expected MACD line, signal, and histogram to align with visible chart points."
			if _chart_smoke_indicator_values(snapshot, "macd_12_26_9").is_empty():
				return "Smoke test expected MACD histogram values to render through the shared indicator values path."
			var snapshot_3m: Dictionary = chart_system.build_chart_snapshot_from_bars(bars, "3m", [])
			if int(snapshot_3m.get("visible_bar_count", 0)) != 63 or int(snapshot_3m.get("display_bar_count", 0)) != 63:
				return "Smoke test expected 3M chart snapshots to render 63 unaggregated daily bars."
			var snapshot_6m: Dictionary = chart_system.build_chart_snapshot_from_bars(bars, "6m", [])
			if int(snapshot_6m.get("visible_bar_count", 0)) != 126 or int(snapshot_6m.get("display_bar_count", 0)) != 126:
				return "Smoke test expected 6M chart snapshots to render 126 unaggregated daily bars."
			var snapshot_3m_sma: Dictionary = chart_system.build_chart_snapshot_from_bars(bars, "3m", ["sma_20"])
			var sma_20_values: Array = _chart_smoke_indicator_values(snapshot_3m_sma, "sma_20")
			if sma_20_values.is_empty() or sma_20_values[0] == null:
				return "Smoke test expected SMA 20 to use warmup history and render from the left edge of 3M charts."
			var snapshot_3m_momentum: Dictionary = chart_system.build_chart_snapshot_from_bars(bars, "3m", ["rsi_14", "macd_12_26_9"])
			if not _chart_smoke_has_panel_group(snapshot_3m_momentum, "rsi") or not _chart_smoke_has_panel_group(snapshot_3m_momentum, "macd"):
				return "Smoke test expected RSI and MACD to render as separate stacked indicator panels."
			if not snapshot_3m_momentum.has("technical_signals"):
				return "Smoke test expected chart snapshots to carry hidden technical signals for internal consumers."
			deterministic_reference = {"company_id": company_id}

		var bias: String = str(chart_profile.get("bias", ""))
		var primary_pattern: String = str(chart_profile.get("primary_pattern", ""))
		if bias == "bullish" and not saw_bullish_history:
			if _chart_smoke_close_at(bars, bars.size() - 1) <= _chart_smoke_close_at(bars, 0) * 1.08:
				return "Smoke test expected bullish chart profile %s to show a rising 5Y history." % company_id
			if not _chart_smoke_has_directional_volume_confirmation(bars, true):
				return "Smoke test expected bullish chart profile %s to show volume confirmation on upside moves." % company_id
			if not _chart_smoke_bullish_patterns().has(primary_pattern):
				return "Smoke test expected bullish chart profile %s to use a recognizable bullish pattern." % company_id
			saw_bullish_history = true
		elif bias == "bearish" and not saw_bearish_history:
			if _chart_smoke_close_at(bars, bars.size() - 1) >= _chart_smoke_close_at(bars, 0) * 0.92:
				return "Smoke test expected bearish chart profile %s to show a falling 5Y history." % company_id
			if not _chart_smoke_has_directional_volume_confirmation(bars, false):
				return "Smoke test expected bearish chart profile %s to show selling-volume confirmation." % company_id
			if not _chart_smoke_bearish_patterns().has(primary_pattern):
				return "Smoke test expected bearish chart profile %s to use a recognizable bearish pattern." % company_id
			saw_bearish_history = true
		elif bias == "sideways":
			saw_sideways_history = true

		var sma_behavior: String = str(chart_profile.get("sma_behavior", ""))
		var sma_period: int = int(chart_profile.get("preferred_sma_period", 20))
		if sma_behavior == "support" and not saw_support_sma:
			if not _chart_smoke_has_sma_behavior(bars, sma_period, "support"):
				return "Smoke test expected %s to show support behavior near SMA %d." % [company_id, sma_period]
			saw_support_sma = true
		elif sma_behavior == "resistance" and not saw_resistance_sma:
			if not _chart_smoke_has_sma_behavior(bars, sma_period, "resistance"):
				return "Smoke test expected %s to show resistance behavior near SMA %d." % [company_id, sma_period]
			saw_resistance_sma = true

		if _chart_smoke_has_gap(bars, true):
			saw_gap_up = true
		if _chart_smoke_has_gap(bars, false):
			saw_gap_down = true
		tested_count += 1

	if tested_count < 12:
		return "Smoke test expected to validate at least 12 structured chart profiles."
	if archetypes.size() < 3:
		return "Smoke test expected roster chart profiles to span at least three archetypes."
	if pattern_variants.size() < 6:
		return "Smoke test expected roster chart profiles to use multiple hidden pattern variants."
	if chart_intents.size() < 2:
		return "Smoke test expected roster chart profiles to include multiple hidden chart intents."
	if not saw_hidden_cycle:
		return "Smoke test expected structured chart profiles to include at least one hidden tape cycle."
	if not saw_operator_cycle_metadata:
		return "Smoke test expected low-float/story-heavy chart profiles to include operator-cycle metadata."
	if not biases.has("bullish") or not biases.has("bearish") or not biases.has("sideways"):
		return "Smoke test expected roster chart profiles to include bullish, bearish, and sideways histories."
	if not saw_bullish_history or not saw_bearish_history or not saw_sideways_history:
		return "Smoke test expected structured chart histories to cover bullish, bearish, and sideways examples."
	if not saw_support_sma or not saw_resistance_sma:
		return "Smoke test expected structured chart histories to include measurable SMA support and resistance examples."
	if not saw_gap_up or not saw_gap_down:
		return "Smoke test expected structured chart histories to include both gap-up and gap-down examples."
	return ""


func _validate_technical_signal_detection(chart_system) -> String:
	var bullish_signals: Array = chart_system.build_technical_signals_from_series(
		[100.0, 96.0, 104.0, 94.0, 108.0, 106.0],
		[45.0, 30.0, 48.0, 38.0, 52.0, 50.0],
		[-0.2, -0.9, 0.1, -0.5, 0.5, 0.3],
		[]
	)
	if not _chart_smoke_has_signal(bullish_signals, "bullish_divergence", "rsi_14") or not _chart_smoke_has_signal(bullish_signals, "bullish_divergence", "macd_12_26_9"):
		return "Smoke test expected lower price lows with higher RSI/MACD lows to produce hidden bullish divergence."
	var bearish_signals: Array = chart_system.build_technical_signals_from_series(
		[100.0, 110.0, 103.0, 115.0, 108.0, 107.0],
		[45.0, 72.0, 48.0, 63.0, 52.0, 50.0],
		[0.1, 0.8, -0.1, 0.4, 0.0, -0.2],
		[]
	)
	if not _chart_smoke_has_signal(bearish_signals, "bearish_divergence", "rsi_14") or not _chart_smoke_has_signal(bearish_signals, "bearish_divergence", "macd_12_26_9"):
		return "Smoke test expected higher price highs with lower RSI/MACD highs to produce hidden bearish divergence."
	var bullish_convergence: Array = chart_system.build_technical_signals_from_series(
		[100.0, 106.0, 101.0, 112.0, 105.0, 110.0],
		[45.0, 58.0, 46.0, 70.0, 55.0, 60.0],
		[0.1, 0.4, -0.1, 0.8, 0.2, 0.5],
		[]
	)
	if not _chart_smoke_has_signal(bullish_convergence, "bullish_convergence", "rsi_14"):
		return "Smoke test expected price and RSI higher highs to produce hidden bullish convergence."
	var bearish_convergence: Array = chart_system.build_technical_signals_from_series(
		[112.0, 104.0, 108.0, 98.0, 103.0, 101.0],
		[60.0, 42.0, 55.0, 34.0, 46.0, 40.0],
		[0.5, -0.2, 0.2, -0.8, -0.1, -0.4],
		[]
	)
	if not _chart_smoke_has_signal(bearish_convergence, "bearish_convergence", "rsi_14"):
		return "Smoke test expected price and RSI lower lows to produce hidden bearish convergence."
	return ""


func _validate_hidden_cycle_anchor_generation(generator) -> String:
	var clean_profile: Dictionary = {
		"cycle_template": "markup_clean",
		"cycle_strength": 0.75,
		"operator_pressure": 0.0,
		"fib_profile_id": "fib_classic",
		"cycle_fib_ratios": {"wave2": 0.500, "wave3": 1.618, "wave4": 0.382}
	}
	var clean_anchors: Array = generator.call("_chart_cycle_shape_anchors", clean_profile)
	if clean_anchors.size() < 6:
		return "Smoke test expected hidden clean markup cycle to produce chart anchors."
	var wave1: float = float(clean_anchors[1].get("m", 1.0))
	var wave2: float = float(clean_anchors[2].get("m", 1.0))
	var wave3: float = float(clean_anchors[3].get("m", 1.0))
	var wave4: float = float(clean_anchors[4].get("m", 1.0))
	var wave2_pullback: float = (wave1 - wave2) / max(wave1 - 1.0, 0.001)
	var wave4_pullback: float = (wave3 - wave4) / max(wave3 - wave2, 0.001)
	if absf(wave2_pullback - 0.500) > 0.06 or absf(wave4_pullback - 0.382) > 0.06:
		return "Smoke test expected clean hidden cycle anchors to respect Fibonacci pullback zones."
	var operator_profile: Dictionary = {
		"cycle_template": "operator_rug",
		"cycle_strength": 0.82,
		"operator_pressure": 0.92,
		"fib_profile_id": "fib_rug",
		"cycle_fib_ratios": {"wave2": 0.382, "wave3": 1.618, "wave4": 0.618}
	}
	var operator_anchors: Array = generator.call("_chart_cycle_shape_anchors", operator_profile)
	if operator_anchors.size() < 8:
		return "Smoke test expected hidden operator rug cycle to produce violent chart anchors."
	var peak_value: float = 0.0
	var trough_value: float = INF
	for anchor_value in operator_anchors:
		if typeof(anchor_value) != TYPE_DICTIONARY:
			continue
		var anchor: Dictionary = anchor_value
		peak_value = max(peak_value, float(anchor.get("m", 0.0)))
		trough_value = min(trough_value, float(anchor.get("m", 1.0)))
	if peak_value < 1.25 or trough_value > 0.82:
		return "Smoke test expected operator cycle anchors to allow oversized markups and rug gaps."
	return ""


func _validate_hidden_microstructure_generation(generator) -> String:
	var pattern_window: Dictionary = {"start": 0, "end": 100, "count": 101, "timeframe": "3m"}
	var uptrend_profile: Dictionary = {
		"cycle_template": "markup_clean",
		"cycle_tempo_profile": "normal_setup",
		"microstructure_intensity": 0.72,
		"operator_pressure": 0.18,
		"setup_duration_bias": 0.0,
		"shakeout_profile": "healthy_pullback"
	}
	var pullback_context: Dictionary = generator.call("_chart_historical_microstructure_context", uptrend_profile, 0.30, 30, 101, pattern_window, 246810, "MICRO_UP")
	var reclaim_context: Dictionary = generator.call("_chart_historical_microstructure_context", uptrend_profile, 0.39, 39, 101, pattern_window, 246810, "MICRO_UP")
	if float(pullback_context.get("price_multiplier", 1.0)) >= 0.995:
		return "Smoke test expected hidden uptrend microstructure to include a mid-trend pullback."
	if float(reclaim_context.get("price_multiplier", 1.0)) <= 1.002:
		return "Smoke test expected hidden uptrend microstructure to include a reclaim leg after pullback."

	var downtrend_profile: Dictionary = {
		"cycle_template": "distribution_clean",
		"cycle_tempo_profile": "normal_setup",
		"microstructure_intensity": 0.74,
		"operator_pressure": 0.24,
		"setup_duration_bias": 0.0,
		"shakeout_profile": "dead_cat"
	}
	var dead_cat_context: Dictionary = generator.call("_chart_historical_microstructure_context", downtrend_profile, 0.36, 36, 101, pattern_window, 246810, "MICRO_DOWN")
	var continuation_context: Dictionary = generator.call("_chart_historical_microstructure_context", downtrend_profile, 0.58, 58, 101, pattern_window, 246810, "MICRO_DOWN")
	if float(dead_cat_context.get("price_multiplier", 1.0)) <= 1.002:
		return "Smoke test expected hidden downtrend microstructure to include a dead-cat bounce."
	if float(continuation_context.get("price_multiplier", 1.0)) >= 0.998:
		return "Smoke test expected hidden downtrend microstructure to include continuation after the bounce fails."

	var slow_profile: Dictionary = uptrend_profile.duplicate(true)
	slow_profile["cycle_tempo_profile"] = "slow_setup"
	slow_profile["setup_duration_bias"] = 0.48
	var fast_profile: Dictionary = uptrend_profile.duplicate(true)
	fast_profile["cycle_tempo_profile"] = "fast_operator"
	fast_profile["setup_duration_bias"] = -0.56
	var slow_progress: float = float(generator.call("_chart_tempo_adjusted_progress", slow_profile, 0.25))
	var normal_progress: float = float(generator.call("_chart_tempo_adjusted_progress", uptrend_profile, 0.25))
	var fast_progress: float = float(generator.call("_chart_tempo_adjusted_progress", fast_profile, 0.25))
	if not (slow_progress < normal_progress and normal_progress < fast_progress):
		return "Smoke test expected slow setup profiles to spend more bars in base/setup than fast operator profiles."

	var regime_up_profile: Dictionary = uptrend_profile.duplicate(true)
	regime_up_profile["tape_regime_profile"] = "messy_accumulation"
	regime_up_profile["regime_block_intensity"] = 0.68
	regime_up_profile["regime_tempo_bias"] = 0.10
	regime_up_profile["bar_friction_profile"] = "balanced_chop"
	var regime_blocks_a: Array = generator.call("_chart_tape_regime_blocks", regime_up_profile, 101, pattern_window, 246810, "REGIME_UP")
	var regime_blocks_b: Array = generator.call("_chart_tape_regime_blocks", regime_up_profile, 101, pattern_window, 246810, "REGIME_UP")
	if regime_blocks_a.size() != regime_blocks_b.size() or regime_blocks_a.is_empty():
		return "Smoke test expected hidden tape regime scheduling to be deterministic for the same seed/state."
	for block_index in range(regime_blocks_a.size()):
		if typeof(regime_blocks_a[block_index]) != TYPE_DICTIONARY or typeof(regime_blocks_b[block_index]) != TYPE_DICTIONARY:
			return "Smoke test expected hidden tape regime blocks to use dictionary rows."
		var left_block: Dictionary = regime_blocks_a[block_index]
		var right_block: Dictionary = regime_blocks_b[block_index]
		if str(left_block.get("type", "")) != str(right_block.get("type", "")) or absf(float(left_block.get("p0", 0.0)) - float(right_block.get("p0", 0.0))) > 0.0001 or absf(float(left_block.get("p1", 0.0)) - float(right_block.get("p1", 0.0))) > 0.0001:
			return "Smoke test expected hidden tape regime scheduling to be deterministic for the same seed/state."
	var saw_regime_base: bool = false
	var saw_regime_markup: bool = false
	var saw_regime_channel: bool = false
	for block_value in regime_blocks_a:
		if typeof(block_value) != TYPE_DICTIONARY:
			continue
		var regime_type: String = str((block_value as Dictionary).get("type", ""))
		saw_regime_base = saw_regime_base or regime_type == "base"
		saw_regime_markup = saw_regime_markup or regime_type == "markup"
		saw_regime_channel = saw_regime_channel or regime_type == "channel"
	if not saw_regime_base or not saw_regime_markup or not saw_regime_channel:
		return "Smoke test expected uptrend tape regimes to include base, markup, and channel blocks."

	var regime_distribution_profile: Dictionary = downtrend_profile.duplicate(true)
	regime_distribution_profile["tape_regime_profile"] = "distribution_breakdown"
	regime_distribution_profile["regime_block_intensity"] = 0.72
	regime_distribution_profile["regime_tempo_bias"] = -0.04
	var distribution_blocks: Array = generator.call("_chart_tape_regime_blocks", regime_distribution_profile, 101, pattern_window, 246810, "REGIME_DOWN")
	var saw_regime_breakdown: bool = false
	var saw_regime_dead_cat: bool = false
	var saw_regime_failed_reclaim: bool = false
	for block_value in distribution_blocks:
		if typeof(block_value) != TYPE_DICTIONARY:
			continue
		var down_regime_type: String = str((block_value as Dictionary).get("type", ""))
		saw_regime_breakdown = saw_regime_breakdown or down_regime_type == "breakdown"
		saw_regime_dead_cat = saw_regime_dead_cat or down_regime_type == "dead_cat"
		saw_regime_failed_reclaim = saw_regime_failed_reclaim or down_regime_type == "failed_reclaim"
	if not saw_regime_breakdown or not saw_regime_dead_cat or not saw_regime_failed_reclaim:
		return "Smoke test expected distribution tape regimes to include breakdown, dead-cat, and failed-reclaim blocks."

	var slow_regime_profile: Dictionary = regime_up_profile.duplicate(true)
	slow_regime_profile["cycle_tempo_profile"] = "slow_setup"
	slow_regime_profile["regime_tempo_bias"] = 0.52
	var fast_regime_profile: Dictionary = regime_up_profile.duplicate(true)
	fast_regime_profile["tape_regime_profile"] = "operator_campaign"
	fast_regime_profile["cycle_tempo_profile"] = "fast_operator"
	fast_regime_profile["regime_tempo_bias"] = -0.58
	var slow_regime_blocks: Array = generator.call("_chart_tape_regime_blocks", slow_regime_profile, 101, pattern_window, 246810, "REGIME_SLOW")
	var fast_regime_blocks: Array = generator.call("_chart_tape_regime_blocks", fast_regime_profile, 101, pattern_window, 246810, "REGIME_FAST")
	var slow_base_span: float = float((slow_regime_blocks[0] as Dictionary).get("p1", 0.0)) - float((slow_regime_blocks[0] as Dictionary).get("p0", 0.0)) if not slow_regime_blocks.is_empty() and typeof(slow_regime_blocks[0]) == TYPE_DICTIONARY else 0.0
	var fast_base_span: float = float((fast_regime_blocks[0] as Dictionary).get("p1", 0.0)) - float((fast_regime_blocks[0] as Dictionary).get("p0", 0.0)) if not fast_regime_blocks.is_empty() and typeof(fast_regime_blocks[0]) == TYPE_DICTIONARY else 0.0
	if slow_base_span <= fast_base_span:
		return "Smoke test expected slow tape regimes to spend more bars in base than fast operator regimes."

	var saw_regime_pullback: bool = false
	var saw_regime_reclaim: bool = false
	for bar_index in range(34, 86):
		var regime_context: Dictionary = generator.call(
			"_chart_tape_regime_context",
			regime_up_profile,
			float(bar_index) / 100.0,
			bar_index,
			101,
			pattern_window,
			246810,
			"REGIME_CHANNEL_UP",
			100.0,
			102.0,
			[98.0, 99.0, 100.0]
		)
		if str(regime_context.get("phase", "")) == "channel" and float(regime_context.get("price_multiplier", 1.0)) < 0.998:
			saw_regime_pullback = true
		if str(regime_context.get("phase", "")) == "channel" and float(regime_context.get("price_multiplier", 1.0)) > 1.001:
			saw_regime_reclaim = true
	if not saw_regime_pullback or not saw_regime_reclaim:
		return "Smoke test expected hidden tape regimes to add a pullback and reclaim inside 3M uptrend channels."

	var saw_regime_bounce: bool = false
	var saw_regime_drop: bool = false
	for bar_index in range(24, 88):
		var down_regime_context: Dictionary = generator.call(
			"_chart_tape_regime_context",
			regime_distribution_profile,
			float(bar_index) / 100.0,
			bar_index,
			101,
			pattern_window,
			246810,
			"REGIME_CHANNEL_DOWN",
			100.0,
			98.0,
			[102.0, 101.0, 100.0]
		)
		if str(down_regime_context.get("phase", "")) == "dead_cat" and float(down_regime_context.get("price_multiplier", 1.0)) > 1.001:
			saw_regime_bounce = true
		if ["breakdown", "markdown", "failed_reclaim"].has(str(down_regime_context.get("phase", ""))) and float(down_regime_context.get("price_multiplier", 1.0)) < 0.998:
			saw_regime_drop = true
	if not saw_regime_bounce or not saw_regime_drop:
		return "Smoke test expected hidden tape regimes to add dead-cat bounces and failed continuation in downtrends."

	var simulator = MARKET_SIMULATOR_SCRIPT.new()
	var operator_profile: Dictionary = uptrend_profile.duplicate(true)
	operator_profile["cycle_template"] = "operator_markup"
	operator_profile["cycle_tempo_profile"] = "fast_operator"
	operator_profile["microstructure_intensity"] = 0.84
	operator_profile["operator_pressure"] = 0.88
	operator_profile["shakeout_profile"] = "hard_shakeout"
	operator_profile["tape_regime_profile"] = "operator_campaign"
	operator_profile["regime_block_intensity"] = 0.84
	operator_profile["regime_tempo_bias"] = -0.48
	var liquid_profile: Dictionary = uptrend_profile.duplicate(true)
	liquid_profile["cycle_tempo_profile"] = "slow_setup"
	liquid_profile["microstructure_intensity"] = 0.24
	liquid_profile["operator_pressure"] = 0.04
	liquid_profile["shakeout_profile"] = "healthy_pullback"
	liquid_profile["tape_regime_profile"] = "clean_trend"
	liquid_profile["regime_block_intensity"] = 0.28
	liquid_profile["regime_tempo_bias"] = 0.42
	var live_bars: Array = _chart_smoke_bars_from_closes([100.0, 101.0, 103.0, 104.0, 105.0, 106.0, 108.0, 109.0, 110.0])
	var operator_live: Dictionary = simulator.call("_live_microstructure_context", operator_profile, live_bars, 246810, 24, "MICRO_OP")
	var liquid_live: Dictionary = simulator.call("_live_microstructure_context", liquid_profile, live_bars, 246810, 24, "MICRO_LIQ")
	if float(operator_live.get("pressure", 0.0)) <= float(liquid_live.get("pressure", 0.0)):
		return "Smoke test expected low-float/operator chart profiles to carry stronger live microstructure pressure than liquid quality profiles."
	var operator_live_regime: Dictionary = simulator.call("_live_tape_regime_context", operator_profile, live_bars, 246810, 24, "REGIME_LIVE_OP")
	var liquid_live_regime: Dictionary = simulator.call("_live_tape_regime_context", liquid_profile, live_bars, 246810, 24, "REGIME_LIVE_LIQ")
	if float(operator_live_regime.get("pressure", 0.0)) <= float(liquid_live_regime.get("pressure", 0.0)):
		return "Smoke test expected operator names to receive stronger live tape regime friction than liquid quality names."

	var daily_friction_profile: Dictionary = uptrend_profile.duplicate(true)
	daily_friction_profile["bar_friction_profile"] = "balanced_chop"
	daily_friction_profile["microleg_frequency_bias"] = 0.70
	daily_friction_profile["wick_noise_intensity"] = 0.62
	daily_friction_profile["volume_disagreement_rate"] = 0.58
	var saw_nested_pullback: bool = false
	var saw_nested_reclaim: bool = false
	for bar_index in range(12, 54):
		var friction_context: Dictionary = generator.call(
			"_chart_daily_tape_friction_context",
			daily_friction_profile,
			float(bar_index) / 100.0,
			bar_index,
			101,
			pattern_window,
			246810,
			"MICRO_DAILY_UP",
			100.0,
			101.0,
			[98.0, 99.0, 100.0]
		)
		if float(friction_context.get("price_multiplier", 1.0)) < 0.996:
			saw_nested_pullback = true
		if float(friction_context.get("price_multiplier", 1.0)) > 1.001:
			saw_nested_reclaim = true
	if not saw_nested_pullback or not saw_nested_reclaim:
		return "Smoke test expected nested daily tape friction to add pullback and reclaim microlegs inside uptrends."

	var distribution_friction_profile: Dictionary = downtrend_profile.duplicate(true)
	distribution_friction_profile["bar_friction_profile"] = "distribution_chop"
	distribution_friction_profile["microleg_frequency_bias"] = 0.72
	distribution_friction_profile["wick_noise_intensity"] = 0.64
	distribution_friction_profile["volume_disagreement_rate"] = 0.54
	var saw_nested_dead_cat: bool = false
	var saw_nested_failure: bool = false
	for bar_index in range(12, 54):
		var down_friction_context: Dictionary = generator.call(
			"_chart_daily_tape_friction_context",
			distribution_friction_profile,
			float(bar_index) / 100.0,
			bar_index,
			101,
			pattern_window,
			246810,
			"MICRO_DAILY_DOWN",
			100.0,
			99.0,
			[102.0, 101.0, 100.0]
		)
		if float(down_friction_context.get("price_multiplier", 1.0)) > 1.001:
			saw_nested_dead_cat = true
		if float(down_friction_context.get("price_multiplier", 1.0)) < 0.998:
			saw_nested_failure = true
	if not saw_nested_dead_cat or not saw_nested_failure:
		return "Smoke test expected nested daily tape friction to add dead-cat and lower-high failure microlegs inside downtrends."

	var run_guard_context: Dictionary = generator.call(
		"_chart_daily_tape_friction_context",
		daily_friction_profile,
		0.50,
		50,
		101,
		pattern_window,
		246810,
		"MICRO_RUN_GUARD",
		106.0,
		108.0,
		[100.0, 101.0, 102.0, 103.0, 104.0, 105.0, 106.0]
	)
	if float(run_guard_context.get("price_multiplier", 1.0)) >= 1.0 or str(run_guard_context.get("phase", "")) != "run_guard":
		return "Smoke test expected same-direction daily candle runs to be interrupted by a hidden run guard."

	var operator_friction_profile: Dictionary = operator_profile.duplicate(true)
	operator_friction_profile["bar_friction_profile"] = "operator_dirty"
	operator_friction_profile["microleg_frequency_bias"] = 0.86
	operator_friction_profile["wick_noise_intensity"] = 0.82
	operator_friction_profile["volume_disagreement_rate"] = 0.70
	var clean_friction_profile: Dictionary = liquid_profile.duplicate(true)
	clean_friction_profile["bar_friction_profile"] = "clean_liquid"
	clean_friction_profile["microleg_frequency_bias"] = 0.22
	clean_friction_profile["wick_noise_intensity"] = 0.18
	clean_friction_profile["volume_disagreement_rate"] = 0.16
	var operator_friction_context: Dictionary = generator.call(
		"_chart_daily_tape_friction_context",
		operator_friction_profile,
		0.34,
		34,
		101,
		pattern_window,
		246810,
		"MICRO_OPERATOR_FRICTION",
		100.0,
		102.0,
		[97.0, 98.0, 99.0, 100.0]
	)
	var clean_friction_context: Dictionary = generator.call(
		"_chart_daily_tape_friction_context",
		clean_friction_profile,
		0.34,
		34,
		101,
		pattern_window,
		246810,
		"MICRO_CLEAN_FRICTION",
		100.0,
		102.0,
		[97.0, 98.0, 99.0, 100.0]
	)
	if float(operator_friction_context.get("friction_strength", 0.0)) <= float(clean_friction_context.get("friction_strength", 0.0)):
		return "Smoke test expected operator daily tape friction to be stronger than liquid quality friction."
	if int(operator_friction_context.get("run_limit", 6)) >= int(clean_friction_context.get("run_limit", 6)):
		return "Smoke test expected operator daily tape friction to allow shorter same-color candle runs than liquid profiles."
	if float(operator_friction_context.get("range_multiplier", 1.0)) > 1.56:
		return "Smoke test expected daily operator friction to stay below the wild-candle range cap."
	if float(operator_friction_context.get("lower_wick_bias", 0.0)) > 0.031 or float(operator_friction_context.get("upper_wick_bias", 0.0)) > 0.031:
		return "Smoke test expected daily operator wick pressure to stay below the comb-wick cap."
	var clean_range_cap: float = float(generator.call("_chart_daily_range_cap", clean_friction_profile))
	var balanced_range_cap: float = float(generator.call("_chart_daily_range_cap", daily_friction_profile))
	var operator_range_cap: float = float(generator.call("_chart_daily_range_cap", operator_friction_profile))
	if not (clean_range_cap < balanced_range_cap and balanced_range_cap < operator_range_cap):
		return "Smoke test expected daily range caps to scale from liquid to balanced to operator profiles."
	if operator_range_cap > 0.047:
		return "Smoke test expected operator daily range cap to avoid extreme comb-like daily candles."
	var operator_wick_cap: float = float(generator.call("_chart_clamp_wick_bias_for_daily_profile", operator_friction_profile, 0.20))
	var clean_wick_cap: float = float(generator.call("_chart_clamp_wick_bias_for_daily_profile", clean_friction_profile, 0.20))
	if not (clean_wick_cap < operator_wick_cap and operator_wick_cap <= 0.039):
		return "Smoke test expected wick caps to stay tighter while still allowing operator names to be messier."

	var saw_volume_dryup: bool = false
	var saw_volume_spike: bool = false
	for bar_index in range(10, 70):
		var balanced_volume_context: Dictionary = generator.call(
			"_chart_daily_tape_friction_context",
			daily_friction_profile,
			float(bar_index) / 100.0,
			bar_index,
			101,
			pattern_window,
			246810,
			"MICRO_VOLUME_DRYUP",
			100.0,
			101.0,
			[98.0, 99.0, 100.0]
		)
		if float(balanced_volume_context.get("volume_multiplier", 1.0)) < 0.95:
			saw_volume_dryup = true
		var operator_volume_context: Dictionary = generator.call(
			"_chart_daily_tape_friction_context",
			operator_friction_profile,
			float(bar_index) / 100.0,
			bar_index,
			101,
			pattern_window,
			246810,
			"MICRO_VOLUME_SPIKE",
			100.0,
			101.0,
			[98.0, 99.0, 100.0]
		)
		if float(operator_volume_context.get("volume_multiplier", 1.0)) > 1.18:
			saw_volume_spike = true
	if not saw_volume_dryup or not saw_volume_spike:
		return "Smoke test expected daily tape friction to create both volume dry-ups and operator-style volume spikes."

	var body_limits: Dictionary = IDX_PRICE_RULES.auto_rejection_limits(100.0, "main")
	var bullish_body: Dictionary = generator.call(
		"_chart_reconcile_historical_body_intent",
		daily_friction_profile,
		{"phase": "calm"},
		{"phase": "markup", "regime_block": {"direction": 1}},
		{"phase": "calm"},
		100.0,
		112.0,
		106.0,
		128.0,
		12,
		body_limits,
		0.12,
		42,
		246810,
		"BODY_MARKUP",
		1,
		3
	)
	if float(bullish_body.get("close", 0.0)) < float(bullish_body.get("open", 0.0)):
		return "Smoke test expected bullish body reconciliation to stop rising markup candles from printing red."
	var final_bullish_body: Dictionary = generator.call(
		"_chart_reconcile_historical_body_intent",
		daily_friction_profile,
		{"phase": "calm"},
		{"phase": "markup", "regime_block": {"direction": 1}},
		{"phase": "calm"},
		100.0,
		112.0,
		106.0,
		106.0,
		0,
		body_limits,
		0.12,
		99,
		246810,
		"BODY_MARKUP_FINAL",
		1,
		3
	)
	if float(final_bullish_body.get("close", 0.0)) < float(final_bullish_body.get("open", 0.0)):
		return "Smoke test expected final-bar body reconciliation to avoid red bodies on rising final candles."
	var bearish_body: Dictionary = generator.call(
		"_chart_reconcile_historical_body_intent",
		distribution_friction_profile,
		{"phase": "calm"},
		{"phase": "breakdown", "regime_block": {"direction": -1}},
		{"phase": "calm"},
		100.0,
		91.0,
		96.0,
		80.0,
		12,
		body_limits,
		-0.09,
		43,
		246810,
		"BODY_BREAKDOWN",
		-1,
		3
	)
	if float(bearish_body.get("close", 0.0)) > float(bearish_body.get("open", 0.0)):
		return "Smoke test expected bearish body reconciliation to stop falling breakdown candles from printing green."
	var shakeout_intent: int = int(generator.call(
		"_chart_historical_body_intent_direction",
		daily_friction_profile,
		{"phase": "shakeout"},
		{"phase": "channel", "regime_block": {"direction": 1}},
		{"phase": "turunin_penumpang"},
		100.0,
		98.0
	))
	var reclaim_intent: int = int(generator.call(
		"_chart_historical_body_intent_direction",
		daily_friction_profile,
		{"phase": "reclaim"},
		{"phase": "channel", "regime_block": {"direction": 1}},
		{"phase": "reclaim"},
		100.0,
		104.0
	))
	var structural_up_intent: int = int(generator.call(
		"_chart_historical_body_intent_direction",
		daily_friction_profile,
		{"phase": "shakeout"},
		{"phase": "channel", "regime_block": {"direction": 1}},
		{"phase": "turunin_penumpang"},
		100.0,
		104.0
	))
	var failure_intent: int = int(generator.call(
		"_chart_historical_body_intent_direction",
		distribution_friction_profile,
		{"phase": "failed_reclaim"},
		{"phase": "failed_reclaim", "regime_block": {"direction": -1}},
		{"phase": "lower_high"},
		100.0,
		98.0
	))
	if shakeout_intent >= 0 or reclaim_intent <= 0 or failure_intent >= 0 or structural_up_intent <= 0:
		return "Smoke test expected candle body intent to follow visible daily direction while distinguishing shakeouts, reclaims, and upper-wick failures."
	var chart_canvas = PRICE_CHART_CANVAS_SCRIPT.new()
	var day_color_bars: Array = [
		{"open": 100.0, "close": 100.0},
		{"open": 112.0, "close": 106.0}
	]
	var rendered_day_change_pct: float = float(chart_canvas.call("_bar_day_change_pct", day_color_bars, 1))
	chart_canvas.free()
	if rendered_day_change_pct <= 0.0:
		return "Smoke test expected chart candle color direction to follow close versus previous close."
	var live_body_up: Dictionary = simulator.call(
		"_reconcile_live_candle_body_intent",
		daily_friction_profile,
		{"accumulation_signal": 0.62, "distribution_signal": 0.12},
		100.0,
		110.0,
		104.0,
		0.04,
		0.0,
		body_limits,
		246810,
		44,
		"LIVE_BODY_UP"
	)
	if float(live_body_up.get("close", 0.0)) < float(live_body_up.get("open", 0.0)):
		return "Smoke test expected live candle reconciliation to stop rising days from printing red bodies."
	var live_body_down: Dictionary = simulator.call(
		"_reconcile_live_candle_body_intent",
		distribution_friction_profile,
		{"accumulation_signal": 0.10, "distribution_signal": 0.68},
		100.0,
		92.0,
		96.0,
		-0.04,
		0.0,
		body_limits,
		246810,
		45,
		"LIVE_BODY_DOWN"
	)
	if float(live_body_down.get("close", 0.0)) > float(live_body_down.get("open", 0.0)):
		return "Smoke test expected live candle reconciliation to stop falling days from printing green bodies."
	return ""


func _validate_macro_scale_tier_generation() -> String:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var smoke_seeds: Array = [13579, 246810, 424242]
	var reference_tier_signature: String = ""
	for seed_value in smoke_seeds:
		var run_seed: int = int(seed_value)
		var roster: Array = GameManager.build_company_roster(run_seed, difficulty_config)
		var distribution_error: String = _validate_scale_tier_roster_distribution(roster, run_seed)
		if not distribution_error.is_empty():
			return distribution_error
		var tier_signature: String = _scale_tier_signature(roster)
		if reference_tier_signature.is_empty():
			reference_tier_signature = tier_signature
		elif tier_signature == reference_tier_signature:
			var matching_market_caps: bool = true
			var reference_roster: Array = GameManager.build_company_roster(int(smoke_seeds[0]), difficulty_config)
			for company_index in range(min(reference_roster.size(), roster.size())):
				var left_anchors: Dictionary = reference_roster[company_index].get("anchors", {})
				var right_anchors: Dictionary = roster[company_index].get("anchors", {})
				if not is_equal_approx(float(left_anchors.get("market_cap", 0.0)), float(right_anchors.get("market_cap", 0.0))):
					matching_market_caps = false
					break
			if matching_market_caps:
				return "Smoke test expected macro-aware scale generation to vary across fixed seeds."

	var downstream_roster: Array = GameManager.build_company_roster(int(smoke_seeds[0]), difficulty_config)
	RunState.setup_new_run(int(smoke_seeds[0]), downstream_roster, difficulty_config, false)
	var smallest_market_cap: float = INF
	var smallest_adv: float = INF
	var largest_market_cap: float = 0.0
	var largest_adv: float = 0.0
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		RunState.ensure_company_full_detail(company_id, false)
		var snapshot: Dictionary = GameManager.get_company_snapshot(company_id, false, true, true)
		var financials: Dictionary = snapshot.get("financials", {})
		var statement_snapshot: Dictionary = snapshot.get("financial_statement_snapshot", {})
		var market_cap: float = float(financials.get("market_cap", 0.0))
		var current_price: float = float(snapshot.get("current_price", 0.0))
		var shares_outstanding: float = float(snapshot.get("shares_outstanding", financials.get("shares_outstanding", 0.0)))
		var revenue: float = float(financials.get("revenue", 0.0))
		var net_income: float = float(financials.get("net_income", 0.0))
		var avg_daily_value: float = float(financials.get("avg_daily_value", 0.0))
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		var anchors: Dictionary = definition.get("anchors", {})
		var scale_tier: String = str(anchors.get("scale_tier", ""))
		var scale_market_cap_floor: float = float(anchors.get("scale_market_cap_floor", 0.0))
		var scale_market_cap_ceiling: float = float(anchors.get("scale_market_cap_ceiling", 0.0))
		var expected_profile_size_id: int = _smoke_profile_size_id_for_scale_tier(scale_tier, market_cap)
		var total_assets: float = _smoke_statement_line_value(statement_snapshot.get("balance_sheet", []), "total_assets")
		if (
			market_cap <= 0.0 or
			current_price <= 0.0 or
			shares_outstanding <= 0.0 or
			revenue <= 0.0 or
			net_income <= 0.0 or
			total_assets <= 0.0 or
			avg_daily_value <= 0.0
		):
			return "Smoke test expected %s generated fundamentals to stay positive after scale-tier setup." % company_id.to_upper()
		if (
			scale_market_cap_floor > 0.0 and
			scale_market_cap_ceiling >= scale_market_cap_floor and
			(market_cap < scale_market_cap_floor or market_cap > scale_market_cap_ceiling)
		):
			return "Smoke test expected %s hydrated market cap to stay inside assigned %s range." % [
				company_id.to_upper(),
				scale_tier
			]
		if expected_profile_size_id >= 0 and int(snapshot.get("company_size_id", -1)) != expected_profile_size_id:
			return "Smoke test expected %s profile size to follow generated %s tier." % [
				company_id.to_upper(),
				scale_tier
			]
		var incompatible_profile_tag: String = _smoke_incompatible_profile_tag(snapshot.get("profile_tags", []), expected_profile_size_id)
		if not incompatible_profile_tag.is_empty():
			return "Smoke test expected %s profile tags to respect generated %s tier, but found %s." % [
				company_id.to_upper(),
				scale_tier,
				incompatible_profile_tag
			]
		var implied_market_cap: float = current_price * shares_outstanding
		var market_cap_gap: float = absf(implied_market_cap - market_cap) / max(market_cap, 1.0)
		if market_cap_gap > 0.35:
			return "Smoke test expected %s price * shares to stay close to market cap; gap was %.2f%%." % [
				company_id.to_upper(),
				market_cap_gap * 100.0
			]
		if market_cap < smallest_market_cap:
			smallest_market_cap = market_cap
			smallest_adv = avg_daily_value
		if market_cap > largest_market_cap:
			largest_market_cap = market_cap
			largest_adv = avg_daily_value
	if largest_market_cap <= smallest_market_cap or largest_adv <= smallest_adv:
		return "Smoke test expected larger generated companies to retain higher liquidity than the smallest generated company."
	return ""


func _validate_scale_tier_roster_distribution(roster: Array, run_seed: int) -> String:
	if roster.size() < 30:
		return "Smoke test expected seed %d to generate a 30-company default roster." % run_seed
	var under_1t_count: int = 0
	var over_10t_count: int = 0
	var over_35t_count: int = 0
	var seen_tiers := {}
	for definition_value in roster:
		if typeof(definition_value) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = definition_value
		var anchors: Dictionary = definition.get("anchors", {})
		var market_cap: float = float(anchors.get("market_cap", 0.0))
		var scale_tier: String = str(anchors.get("scale_tier", ""))
		if market_cap <= 0.0 or float(anchors.get("avg_daily_value", 0.0)) <= 0.0 or float(anchors.get("base_price", 0.0)) <= 0.0:
			return "Smoke test expected %s scale-tier anchors to contain positive market cap, price, and liquidity." % str(definition.get("ticker", "")).to_upper()
		if scale_tier.is_empty() or not anchors.has("scale_tier_rank") or not anchors.has("scale_market_cap_floor") or not anchors.has("scale_market_cap_ceiling"):
			return "Smoke test expected %s to store generated scale-tier metadata." % str(definition.get("ticker", "")).to_upper()
		var floor_value: float = float(anchors.get("scale_market_cap_floor", 0.0))
		var ceiling_value: float = float(anchors.get("scale_market_cap_ceiling", 0.0))
		if market_cap < floor_value or market_cap > ceiling_value:
			return "Smoke test expected %s market cap %.2f to stay inside assigned %s range." % [
				str(definition.get("ticker", "")).to_upper(),
				market_cap,
				scale_tier
			]
		seen_tiers[scale_tier] = true
		if market_cap < 1000000000000.0:
			under_1t_count += 1
		if market_cap > 10000000000000.0:
			over_10t_count += 1
		if market_cap > 35000000000000.0:
			over_35t_count += 1
	if under_1t_count < 3:
		return "Smoke test expected seed %d roster to include at least 3 sub-Rp1T companies, found %d." % [run_seed, under_1t_count]
	if over_10t_count < 5:
		return "Smoke test expected seed %d roster to include at least 5 companies above Rp10T, found %d." % [run_seed, over_10t_count]
	if over_35t_count < 1:
		return "Smoke test expected seed %d roster to include at least 1 company above Rp35T." % run_seed
	if seen_tiers.size() < 5:
		return "Smoke test expected seed %d roster to cover all five generated scale tiers." % run_seed
	return ""


func _scale_tier_signature(roster: Array) -> String:
	var tiers: Array = []
	for definition_value in roster:
		if typeof(definition_value) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = definition_value
		tiers.append(str(definition.get("anchors", {}).get("scale_tier", "")))
	return "|".join(tiers)


func _smoke_statement_line_value(lines: Array, line_id: String) -> float:
	for line_value in lines:
		if typeof(line_value) != TYPE_DICTIONARY:
			continue
		var line: Dictionary = line_value
		if str(line.get("id", "")) == line_id:
			return float(line.get("value", 0.0))
	return 0.0


func _smoke_profile_size_id_for_scale_tier(scale_tier: String, market_cap: float) -> int:
	match scale_tier:
		"micro":
			return 0
		"small":
			return 1
		"mid":
			return 2
		"large":
			return 3
		"giant":
			return 4
		_:
			if market_cap <= 0.0:
				return -1
			if market_cap < 950000000000.0:
				return 0
			if market_cap < 2500000000000.0:
				return 1
			if market_cap < 10000000000000.0:
				return 2
			if market_cap < 35000000000000.0:
				return 3
			return 4


func _smoke_incompatible_profile_tag(profile_tags: Array, size_id: int) -> String:
	if size_id < 0:
		return ""
	var tag_rules := {
		"micro-cap": {"max": 0},
		"small-cap": {"min": 1, "max": 1},
		"mid-cap": {"min": 2, "max": 2},
		"large-cap": {"min": 3},
		"mega-cap": {"min": 4},
		"blue-chip": {"min": 3},
		"systemic": {"min": 4},
		"institutional-grade": {"min": 3},
		"market-followed": {"min": 3},
		"market-leader": {"min": 3},
		"national-champion": {"min": 3}
	}
	for tag_value in profile_tags:
		var tag: String = str(tag_value).strip_edges().to_lower()
		if not tag_rules.has(tag):
			continue
		var rule: Dictionary = tag_rules.get(tag, {})
		if size_id < int(rule.get("min", 0)) or size_id > int(rule.get("max", 4)):
			return tag
	return ""


func _build_smoke_historical_trade_dates(count: int) -> Array:
	var dates: Array = []
	var cursor: Dictionary = trading_calendar.previous_trade_date(trading_calendar.start_date())
	for _index in range(max(count, 0)):
		dates.append(cursor.duplicate(true))
		cursor = trading_calendar.previous_trade_date(cursor)
	dates.reverse()
	return dates


func _validate_structured_chart_upgrade_tiers() -> String:
	var chart_track: Dictionary = {}
	for track_value in DataRepository.get_upgrade_catalog().get("tracks", []):
		if typeof(track_value) != TYPE_DICTIONARY:
			continue
		var track: Dictionary = track_value
		if str(track.get("id", "")) == "chart_indicators":
			chart_track = track
			break
	if chart_track.is_empty():
		return "Smoke test expected upgrade catalog to include Chart Indicators track."
	var tiers: Dictionary = chart_track.get("tiers", {})
	if not _chart_smoke_indicator_set_matches(tiers.get("4", {}).get("indicator_ids", []), []):
		return "Smoke test expected Chart Indicators tier 4 to unlock no indicators."
	if not _chart_smoke_indicator_set_matches(tiers.get("3", {}).get("indicator_ids", []), ["sma_20"]):
		return "Smoke test expected Chart Indicators tier 3 to unlock only SMA 20."
	if not _chart_smoke_indicator_set_matches(tiers.get("2", {}).get("indicator_ids", []), ["sma_3", "sma_5", "sma_10", "sma_20", "sma_60"]):
		return "Smoke test expected Chart Indicators tier 2 to unlock SMA 3/5/10/20/60."
	if not _chart_smoke_indicator_set_matches(tiers.get("1", {}).get("indicator_ids", []), ["sma_3", "sma_5", "sma_10", "sma_20", "sma_60", "sma_100", "sma_200", "ema_20", "rsi_14", "macd_12_26_9"]):
		return "Smoke test expected Chart Indicators tier 1 to unlock all planned advanced indicators."
	return ""


func _chart_catalog_has_id(catalog: Array, target_id: String) -> bool:
	for row_value in catalog:
		if typeof(row_value) == TYPE_DICTIONARY and str(row_value.get("id", "")) == target_id:
			return true
	return false


func _chart_smoke_indicator_values(snapshot: Dictionary, target_id: String) -> Array:
	for indicator_value in snapshot.get("indicator_snapshots", []):
		if typeof(indicator_value) != TYPE_DICTIONARY:
			continue
		var indicator: Dictionary = indicator_value
		if str(indicator.get("id", "")) == target_id:
			var values: Array = indicator.get("values", [])
			return values.duplicate()
	return []


func _chart_smoke_indicator_snapshot(snapshot: Dictionary, target_id: String) -> Dictionary:
	for indicator_value in snapshot.get("indicator_snapshots", []):
		if typeof(indicator_value) != TYPE_DICTIONARY:
			continue
		var indicator: Dictionary = indicator_value
		if str(indicator.get("id", "")) == target_id:
			return indicator.duplicate(true)
	return {}


func _chart_smoke_has_panel_group(snapshot: Dictionary, panel_group: String) -> bool:
	var plot_rows: Array = snapshot.get("panel_plots", [])
	if plot_rows.is_empty():
		plot_rows = snapshot.get("plots", [])
	for plot_value in plot_rows:
		if typeof(plot_value) != TYPE_DICTIONARY:
			continue
		var plot: Dictionary = plot_value
		if str(plot.get("panel_group", "")) == panel_group:
			return true
	return false


func _chart_smoke_has_signal(signals: Array, signal_type: String, indicator_id: String) -> bool:
	for signal_value in signals:
		if typeof(signal_value) != TYPE_DICTIONARY:
			continue
		var signal_row: Dictionary = signal_value
		if str(signal_row.get("signal_type", "")) == signal_type and str(signal_row.get("indicator_id", "")) == indicator_id:
			return true
	return false


func _chart_smoke_range_order_matches(catalog: Array, expected_ids: Array) -> bool:
	if catalog.size() != expected_ids.size():
		return false
	for index in range(expected_ids.size()):
		if typeof(catalog[index]) != TYPE_DICTIONARY:
			return false
		var range_row: Dictionary = catalog[index]
		if str(range_row.get("id", "")) != str(expected_ids[index]):
			return false
	return true


func _chart_smoke_indicator_set_matches(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for expected_value in expected:
		if not actual.has(str(expected_value)):
			return false
	return true


func _chart_smoke_bars_are_valid(bars: Array) -> bool:
	var previous_close: float = 0.0
	for bar_value in bars:
		if typeof(bar_value) != TYPE_DICTIONARY:
			return false
		var bar: Dictionary = bar_value
		var open_price: float = float(bar.get("open", 0.0))
		var high_price: float = float(bar.get("high", 0.0))
		var low_price: float = float(bar.get("low", 0.0))
		var close_price: float = float(bar.get("close", 0.0))
		if open_price <= 0.0 or high_price <= 0.0 or low_price <= 0.0 or close_price <= 0.0:
			return false
		if high_price < max(open_price, close_price) or low_price > min(open_price, close_price):
			return false
		if previous_close > 0.0:
			var ar_limits: Dictionary = IDX_PRICE_RULES.auto_rejection_limits(previous_close, "main")
			var upper_price: float = float(ar_limits.get("upper_price", previous_close))
			var lower_price: float = float(ar_limits.get("lower_price", previous_close))
			for price_value in [open_price, high_price, low_price, close_price]:
				var price: float = float(price_value)
				if price > upper_price + 0.0001 or price < lower_price - 0.0001:
					return false
		if int(bar.get("volume_shares", 0)) <= 0 or float(bar.get("value", 0.0)) <= 0.0:
			return false
		previous_close = close_price
	return true


func _chart_smoke_histories_match(left_bars: Array, right_bars: Array) -> bool:
	if left_bars.size() != right_bars.size() or left_bars.is_empty():
		return false
	var check_indexes: Array = [0, int(left_bars.size() / 2), left_bars.size() - 1]
	for index_value in check_indexes:
		var index: int = int(index_value)
		var left_bar: Dictionary = left_bars[index]
		var right_bar: Dictionary = right_bars[index]
		if not is_equal_approx(float(left_bar.get("close", 0.0)), float(right_bar.get("close", 0.0))):
			return false
		if int(left_bar.get("volume_shares", 0)) != int(right_bar.get("volume_shares", 0)):
			return false
	return true


func _chart_smoke_close_at(bars: Array, index: int) -> float:
	if bars.is_empty():
		return 0.0
	var safe_index: int = clamp(index, 0, bars.size() - 1)
	var bar: Dictionary = bars[safe_index]
	return float(bar.get("close", bar.get("open", 0.0)))


func _chart_smoke_bars_from_closes(closes: Array) -> Array:
	var bars: Array = []
	var previous_close: float = 0.0
	for index in range(closes.size()):
		var close_price: float = float(closes[index])
		var open_price: float = previous_close if previous_close > 0.0 else close_price
		bars.append({
			"open": open_price,
			"high": max(open_price, close_price) * 1.01,
			"low": min(open_price, close_price) * 0.99,
			"close": close_price,
			"volume_shares": 100000 + index * 1000,
			"value": close_price * float(100000 + index * 1000)
		})
		previous_close = close_price
	return bars


func _chart_smoke_has_gap(bars: Array, gap_up: bool) -> bool:
	if bars.size() < 2:
		return false
	for index in range(1, bars.size()):
		var previous_close: float = _chart_smoke_close_at(bars, index - 1)
		if previous_close <= 0.0:
			continue
		var bar: Dictionary = bars[index]
		var open_price: float = float(bar.get("open", previous_close))
		var gap_ratio: float = (open_price - previous_close) / previous_close
		if gap_up and gap_ratio >= 0.024:
			return true
		if not gap_up and gap_ratio <= -0.024:
			return true
	return false


func _chart_smoke_has_directional_volume_confirmation(bars: Array, bullish: bool) -> bool:
	if bars.size() < 50:
		return false
	for index in range(35, bars.size()):
		var previous_close: float = _chart_smoke_close_at(bars, index - 1)
		var current_close: float = _chart_smoke_close_at(bars, index)
		if previous_close <= 0.0:
			continue
		var daily_return: float = (current_close - previous_close) / previous_close
		if bullish and daily_return < 0.010:
			continue
		if not bullish and daily_return > -0.010:
			continue
		var previous_value: float = _chart_smoke_average_value(bars, index - 35, index)
		var current_value: float = float(bars[index].get("value", 0.0))
		if previous_value > 0.0 and current_value >= previous_value * 1.18:
			return true
	return false


func _chart_smoke_average_value(bars: Array, start_index: int, end_index: int) -> float:
	var safe_start: int = clamp(start_index, 0, bars.size())
	var safe_end: int = clamp(end_index, safe_start, bars.size())
	var total: float = 0.0
	var count: int = 0
	for index in range(safe_start, safe_end):
		total += float(bars[index].get("value", 0.0))
		count += 1
	return total / float(count) if count > 0 else 0.0


func _chart_smoke_has_sma_behavior(bars: Array, period: int, behavior: String) -> bool:
	if period <= 0 or bars.size() <= period + 2:
		return false
	var touch_count: int = 0
	for index in range(period, bars.size()):
		var sma_value: float = _chart_smoke_sma_at(bars, index, period)
		if sma_value <= 0.0:
			continue
		var bar: Dictionary = bars[index]
		var close_price: float = float(bar.get("close", 0.0))
		if behavior == "support":
			var low_price: float = float(bar.get("low", close_price))
			if low_price <= sma_value * 1.06 and low_price >= sma_value * 0.88 and close_price >= sma_value * 0.96:
				touch_count += 1
		elif behavior == "resistance":
			var high_price: float = float(bar.get("high", close_price))
			if high_price >= sma_value * 0.94 and high_price <= sma_value * 1.14 and close_price <= sma_value * 1.04:
				touch_count += 1
		if touch_count >= 4:
			return true
	return false


func _chart_smoke_sma_at(bars: Array, index: int, period: int) -> float:
	if index < period or period <= 0:
		return 0.0
	var total: float = 0.0
	for sample_index in range(index - period, index):
		total += _chart_smoke_close_at(bars, sample_index)
	return total / float(period)


func _chart_smoke_bullish_patterns() -> Dictionary:
	return {
		"double_bottom": true,
		"inverse_head_shoulders": true,
		"cup_handle": true,
		"ascending_triangle": true,
		"rounded_base": true,
		"bull_flag": true,
		"breakout_retest": true,
		"higher_low_accumulation": true
	}


func _chart_smoke_bearish_patterns() -> Dictionary:
	return {
		"double_top": true,
		"head_shoulders": true,
		"descending_triangle": true,
		"lower_high_distribution": true,
		"failed_breakout": true,
		"breakdown_retest": true,
		"sma_resistance_rejection": true
	}


func _get_smoke_mode() -> String:
	if OS.get_cmdline_user_args().has(SMOKE_QUICK_ARG):
		return SMOKE_MODE_QUICK
	if FileAccess.file_exists(QUICK_SMOKE_FLAG_PATH):
		var user_dir := DirAccess.open("user://")
		if user_dir != null:
			user_dir.remove("quick_smoke.flag")
		return SMOKE_MODE_QUICK
	return SMOKE_MODE_FULL


func _write_smoke_result(smoke_line: String) -> void:
	var result_path: String = "user://smoke_test_result.txt"
	if OS.get_cmdline_user_args().has(SMOKE_LOCAL_IO_ARG):
		result_path = "res://logs/smoke_test_result.txt"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://logs"))
	var result_file = FileAccess.open(result_path, FileAccess.WRITE)
	if result_file != null:
		result_file.store_string(smoke_line)


func _capture_batched_new_run_progress(done_count: int, total_count: int) -> void:
	batched_setup_progress_calls += 1
	batched_setup_progress_done = done_count
	batched_setup_progress_total = total_count


func _validate_main_menu_flow() -> Dictionary:
	var main_menu = load("res://scenes/main_menu/MainMenu.tscn").instantiate()
	add_child(main_menu)
	await get_tree().process_frame

	var new_game_button: Button = main_menu.find_child("NewGameButton", true, false) as Button
	var menu_logo_texture: TextureRect = main_menu.find_child("LogoTexture", true, false) as TextureRect
	var menu_title_label: Label = main_menu.find_child("StartTitle", true, false) as Label
	var menu_build_label: Label = main_menu.find_child("MainMenuBuildLabel", true, false) as Label
	if new_game_button == null:
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the New Game button in the main menu."
		}
	if menu_logo_texture == null or menu_logo_texture.texture == null:
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the main menu to show the Gorengan logo."
		}
	if menu_title_label == null or menu_title_label.visible:
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the old main menu text title to stay hidden behind the logo-led layout."
		}
	if menu_build_label == null or menu_build_label.text.find(BuildInfo.get_build_number()) == -1:
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the main menu to show the current build number."
		}
	var action_card: PanelContainer = main_menu.find_child("ActionCard", true, false) as PanelContainer
	var action_card_style: StyleBoxFlat = null
	if action_card != null:
		action_card_style = action_card.get_theme_stylebox("panel") as StyleBoxFlat
	var new_button_style: StyleBoxFlat = new_game_button.get_theme_stylebox("normal") as StyleBoxFlat
	if action_card_style == null or action_card_style.border_width_top != 26 or not _color_close(action_card_style.border_color, UiTheme.color("desktop.brown")):
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the main menu action card to use the UiTheme desktop window style."
		}
	if new_button_style == null or not _color_close(new_button_style.bg_color, UiTheme.color("desktop.gold")):
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the main menu New Run button to use the UiTheme desktop primary style."
		}

	new_game_button.emit_signal("pressed")
	await get_tree().process_frame

	var difficulty_screen: Control = main_menu.find_child("DifficultyScreen", true, false) as Control
	if difficulty_screen == null or not difficulty_screen.visible:
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected New Game to open the dedicated difficulty selector screen."
	}

	var difficulty_card_grid: GridContainer = main_menu.find_child("DifficultyCardGrid", true, false) as GridContainer
	if difficulty_card_grid == null or difficulty_card_grid.get_child_count() != 3:
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the difficulty selector to render three difficulty cards."
		}

	var expected_difficulty_configs := {
		"chill": {"company_count": 20, "event_interval_days": 14, "volatility_label": "Low"},
		"normal": {"company_count": 30, "event_interval_days": 10, "volatility_label": "Normal"},
		"grind": {"company_count": 50, "event_interval_days": 7, "volatility_label": "High"}
	}
	for difficulty_id in expected_difficulty_configs.keys():
		var expected_config: Dictionary = expected_difficulty_configs[difficulty_id]
		var actual_config: Dictionary = GameManager.get_difficulty_config(str(difficulty_id))
		if (
			int(actual_config.get("company_count", 0)) != int(expected_config.get("company_count", 0)) or
			int(actual_config.get("event_interval_days", 0)) != int(expected_config.get("event_interval_days", 0)) or
			str(actual_config.get("volatility_label", "")) != str(expected_config.get("volatility_label", ""))
		):
			main_menu.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected %s difficulty to use %d companies, %d-day events, and %s volatility." % [
					str(difficulty_id).capitalize(),
					int(expected_config.get("company_count", 0)),
					int(expected_config.get("event_interval_days", 0)),
					str(expected_config.get("volatility_label", ""))
				]
			}

	for expected_button_name in ["ChillCardButton", "NormalCardButton", "GrindCardButton"]:
		if main_menu.find_child(expected_button_name, true, false) == null:
			main_menu.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test could not find expected difficulty card %s." % expected_button_name
			}

	var chill_card_button: Button = main_menu.find_child("ChillCardButton", true, false) as Button
	var chill_card_banner: PanelContainer = null
	var chill_card_title: Label = null
	if chill_card_button != null:
		chill_card_banner = chill_card_button.find_child("DifficultyCardBanner", true, false) as PanelContainer
		chill_card_title = chill_card_button.find_child("DifficultyCardTitle", true, false) as Label
	var chill_banner_style: StyleBoxFlat = null
	if chill_card_banner != null:
		chill_banner_style = chill_card_banner.get_theme_stylebox("panel") as StyleBoxFlat
	if (
		chill_card_button == null or
		chill_card_button.custom_minimum_size.x > 360.0 or
		difficulty_card_grid.custom_minimum_size.x > 1080.0 or
		chill_card_banner == null or
		chill_banner_style == null or
		chill_card_title == null or
		chill_card_title.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER or
		chill_card_title.get_theme_font_size("font_size") <= UiTheme.font_size("title")
	):
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected difficulty choices to render as compact plan cards with centered title banners."
		}

	var selector_card: PanelContainer = main_menu.find_child("SelectorCard", true, false) as PanelContainer
	var maximum_selector_width: float = get_viewport().get_visible_rect().size.x * 0.9 + 1.0
	var compact_selector_width: float = 1042.0
	if (
		selector_card == null or
		selector_card.custom_minimum_size.x > maximum_selector_width or
		selector_card.get_global_rect().size.x > maximum_selector_width or
		selector_card.custom_minimum_size.x > compact_selector_width
	):
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the difficulty selector card to fit within 90 percent of the screen width and hug the plan-card grid."
		}

	var continue_button: Button = main_menu.find_child("ContinueButton", true, false) as Button
	if continue_button == null or not continue_button.disabled:
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Continue to stay disabled until a difficulty card is selected."
		}

	var normal_card_button: Button = main_menu.find_child("NormalCardButton", true, false) as Button
	if normal_card_button == null:
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the Normal difficulty card button."
		}

	normal_card_button.emit_signal("pressed")
	await get_tree().process_frame
	if continue_button.disabled:
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Continue to unlock after selecting a difficulty card."
		}
	var normal_card_banner: PanelContainer = normal_card_button.find_child("DifficultyCardBanner", true, false) as PanelContainer
	var normal_banner_style: StyleBoxFlat = null
	if normal_card_banner != null:
		normal_banner_style = normal_card_banner.get_theme_stylebox("panel") as StyleBoxFlat
	var normal_title_label: Label = normal_card_button.find_child("DifficultyCardTitle", true, false) as Label
	if (
		normal_banner_style == null or
		not _color_close(normal_banner_style.bg_color, UiTheme.color("desktop.brown")) or
		normal_title_label == null or
		not _color_close(normal_title_label.get_theme_color("font_color"), UiTheme.color("desktop.cream"))
	):
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the selected difficulty plan card banner to use readable desktop selected styling."
		}

	var loading_progress_bar: ProgressBar = main_menu.find_child("LoadingProgressBar", true, false) as ProgressBar
	var loading_subprogress_label: Label = main_menu.find_child("LoadingSubprogressLabel", true, false) as Label
	var loading_note_label: Label = main_menu.find_child("LoadingNoteLabel", true, false) as Label
	var load_slots_dialog: Control = main_menu.find_child("LoadSlotsDialog", true, false) as Control
	var load_slots_list: ItemList = main_menu.find_child("LoadSlotsList", true, false) as ItemList
	var load_slots_delete_button: Button = main_menu.find_child("LoadSlotsDeleteButton", true, false) as Button
	var load_slot_delete_dialog: ConfirmationDialog = main_menu.find_child("LoadSlotDeleteDialog", true, false) as ConfirmationDialog
	if (
		loading_progress_bar == null or
		loading_subprogress_label == null or
		loading_note_label == null or
		load_slots_dialog == null or
		load_slots_list == null or
		load_slots_delete_button == null or
		load_slot_delete_dialog == null
	):
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the loading screen and save-slot load/delete controls to expose their required nodes."
		}

	main_menu.queue_free()
	await get_tree().process_frame
	return {"success": true}


func _validate_batched_new_run_setup() -> Dictionary:
	if not RunState.has_method("setup_new_run_batched"):
		return {
			"success": false,
			"message": "Smoke test expected RunState to expose setup_new_run_batched for loading-screen startup generation."
		}

	var run_seed: int = 135791
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(run_seed, difficulty_config)
	batched_setup_progress_calls = 0
	batched_setup_progress_done = 0
	batched_setup_progress_total = 0
	await RunState.setup_new_run_batched(
		run_seed,
		company_definitions,
		difficulty_config,
		false,
		Callable(self, "_capture_batched_new_run_progress")
	)

	if not RunState.has_active_run():
		return {
			"success": false,
			"message": "Smoke test expected the batched startup path to create an active run."
		}

	if RunState.company_order.size() != company_definitions.size():
		return {
			"success": false,
			"message": "Smoke test expected the batched startup path to generate %d companies, got %d." % [company_definitions.size(), RunState.company_order.size()]
		}

	if batched_setup_progress_calls <= 1:
		return {
			"success": false,
			"message": "Smoke test expected batched startup progress to advance across multiple batches."
		}

	if batched_setup_progress_done != company_definitions.size() or batched_setup_progress_total != company_definitions.size():
		return {
			"success": false,
			"message": "Smoke test expected batched startup progress to finish at %d/%d, got %d/%d." % [
				company_definitions.size(),
				company_definitions.size(),
				batched_setup_progress_done,
				batched_setup_progress_total
			]
		}

	if RunState.quarterly_report_calendar.is_empty():
		return {
			"success": false,
			"message": "Smoke test expected the batched startup path to build the quarterly report calendar."
		}

	var first_company_id: String = str(RunState.company_order[0]) if not RunState.company_order.is_empty() else ""
	var first_company: Dictionary = RunState.get_company(first_company_id)
	var first_profile: Dictionary = first_company.get("company_profile", {})
	if first_company_id.is_empty() or first_profile.is_empty():
		return {
			"success": false,
			"message": "Smoke test expected the batched startup path to generate a company profile for the first company."
		}

	if str(first_profile.get("detail_status", "")) != "cold":
		return {
			"success": false,
			"message": "Smoke test expected the batched startup path to leave startup company detail cold until hydration runs."
		}

	if first_profile.get("financials", {}).is_empty():
		return {
			"success": false,
			"message": "Smoke test expected the batched startup path to preserve core market-ready financials."
		}

	if not first_profile.get("financial_history", []).is_empty():
		return {
			"success": false,
			"message": "Smoke test expected the batched startup path to defer full financial history generation."
		}

	if not RunState.ensure_company_full_detail(first_company_id):
		return {
			"success": false,
			"message": "Smoke test expected the batched startup path to allow on-demand full company detail hydration."
		}

	first_company = RunState.get_company(first_company_id)
	first_profile = first_company.get("company_profile", {})
	if str(first_profile.get("detail_status", "")) != "ready":
		return {
			"success": false,
			"message": "Smoke test expected hydrated company detail to move into the ready state."
		}

	if first_profile.get("financial_history", []).is_empty():
		return {
			"success": false,
			"message": "Smoke test expected on-demand hydration to generate financial history."
		}

	var statement_snapshot: Dictionary = first_profile.get("financial_statement_snapshot", {})
	if statement_snapshot.get("quarterly_statements", []).is_empty():
		return {
			"success": false,
			"message": "Smoke test expected on-demand hydration to generate quarterly statement history."
		}

	if first_profile.get("management_roster", []).size() != 3:
		return {
			"success": false,
			"message": "Smoke test expected on-demand hydration to generate the 3-role management roster."
		}

	var save_validation_result: Dictionary = _validate_save_metadata_and_recovery()
	if not bool(save_validation_result.get("success", false)):
		return save_validation_result

	var background_company_id: String = str(RunState.company_order[1]) if RunState.company_order.size() > 1 else ""
	if not background_company_id.is_empty():
		if not SaveManager.flush_pending_save():
			return {
				"success": false,
				"message": "Smoke test expected pending saves to flush before testing background detail hydration."
			}

		GameManager.start_background_company_detail_hydration([background_company_id])
		for _wait_index in range(12):
			await get_tree().process_frame
			if not GameManager.background_company_detail_hydration_running and not RunState.has_pending_company_detail_hydration():
				break

		var background_profile: Dictionary = RunState.get_company(background_company_id).get("company_profile", {})
		if str(background_profile.get("detail_status", "")) != "ready":
			return {
				"success": false,
				"message": "Smoke test expected background hydration to generate ready company detail."
			}

		if str(background_profile.get("detail_persistence", "")) != RunState.COMPANY_DETAIL_PERSISTENCE_EPHEMERAL:
			return {
				"success": false,
				"message": "Smoke test expected background-hydrated company detail to be marked as ephemeral cache."
			}

		if SaveManager.has_pending_save():
			return {
				"success": false,
				"message": "Smoke test expected background detail hydration not to queue an autosave."
			}

		var background_saved_state: Dictionary = RunState.to_save_dict()
		var saved_companies: Dictionary = background_saved_state.get("companies", {})
		var saved_first_profile: Dictionary = saved_companies.get(first_company_id, {}).get("company_profile", {})
		var saved_background_profile: Dictionary = saved_companies.get(background_company_id, {}).get("company_profile", {})
		if str(saved_first_profile.get("detail_status", "")) != "ready" or saved_first_profile.get("financial_history", []).is_empty():
			return {
				"success": false,
				"message": "Smoke test expected on-demand company detail to remain persisted in the save payload."
			}
		if str(saved_background_profile.get("detail_status", "")) != "cold" or not saved_background_profile.get("financial_history", []).is_empty():
			return {
				"success": false,
				"message": "Smoke test expected ephemeral background detail to be trimmed back to cold data in the save payload."
			}

		RunState.load_from_dict(background_saved_state)
		var reloaded_background_profile: Dictionary = RunState.get_company(background_company_id).get("company_profile", {})
		if str(reloaded_background_profile.get("detail_status", "")) != "cold" or not reloaded_background_profile.get("financial_history", []).is_empty():
			return {
				"success": false,
				"message": "Smoke test expected trimmed background detail to reload as lazily hydratable cold data."
			}

	return {"success": true}


func _validate_save_metadata_and_recovery() -> Dictionary:
	if not SaveManager.save_run(RunState.to_save_dict()):
		return {
			"success": false,
			"message": "Smoke test expected SaveManager to write a schema-tagged save."
		}
	if not SaveManager.save_run(RunState.to_save_dict()):
		return {
			"success": false,
			"message": "Smoke test expected SaveManager to write a second save and preserve a backup."
		}

	var save_info: Dictionary = SaveManager.get_save_file_info()
	if not bool(save_info.get("loadable", false)):
		return {
			"success": false,
			"message": "Smoke test expected saved run metadata to be loadable from SaveManager."
		}
	if int(save_info.get("schema_version", 0)) < 2 or str(save_info.get("format_id", "")) != RunState.SAVE_FORMAT_ID:
		return {
			"success": false,
			"message": "Smoke test expected saves to include schema version 2 and the runtime format id."
		}
	if str(save_info.get("game_build", "")) != BuildInfo.get_build_number():
		return {
			"success": false,
			"message": "Smoke test expected saves to include the current game build number."
		}
	if str(save_info.get("absolute_path", "")).is_empty() or str(save_info.get("storage_label", "")).is_empty():
		return {
			"success": false,
			"message": "Smoke test expected SaveManager to expose the save path and storage label."
		}
	if OS.get_cmdline_user_args().has(SMOKE_LOCAL_IO_ARG) and not bool(save_info.get("uses_smoke_path", false)):
		return {
			"success": false,
			"message": "Smoke test expected local-IO smoke runs to use the project-local smoke save path."
		}
	if not bool(save_info.get("backup_loadable", false)):
		return {
			"success": false,
			"message": "Smoke test expected the second save write to create a readable backup file."
		}
	var save_slots: Array = SaveManager.get_save_slots()
	if save_slots.size() != 5:
		return {
			"success": false,
			"message": "Smoke test expected SaveManager to expose five save slots."
		}
	var active_slot_seen: bool = false
	for slot_value in save_slots:
		var slot: Dictionary = slot_value
		if bool(slot.get("active", false)):
			active_slot_seen = true
			if not bool(slot.get("loadable", false)):
				return {
					"success": false,
					"message": "Smoke test expected the active save slot to be loadable after saving."
				}
	if not active_slot_seen:
		return {
			"success": false,
			"message": "Smoke test expected one save slot to be marked active."
		}

	var primary_slot_id: String = SaveManager.get_active_slot_id()
	var secondary_slot_id: String = "slot_2" if primary_slot_id != "slot_2" else "slot_3"
	var slot_one_payload: Dictionary = RunState.to_save_dict()
	var original_cash: float = float(slot_one_payload.get("player_portfolio", {}).get("cash", 0.0))
	var slot_two_payload: Dictionary = slot_one_payload.duplicate(true)
	var slot_two_portfolio: Dictionary = slot_two_payload.get("player_portfolio", {})
	slot_two_portfolio["cash"] = original_cash + 12345.0
	slot_two_payload["player_portfolio"] = slot_two_portfolio
	if not SaveManager.save_run(slot_one_payload, primary_slot_id):
		return {
			"success": false,
			"message": "Smoke test expected SaveManager to save the active slot before slot-switch validation."
		}
	if not SaveManager.save_run(slot_two_payload, secondary_slot_id):
		return {
			"success": false,
			"message": "Smoke test expected SaveManager to save a second slot for slot-switch validation."
		}
	var loaded_primary_slot: Dictionary = SaveManager.load_run(primary_slot_id)
	var loaded_secondary_slot: Dictionary = SaveManager.load_run(secondary_slot_id)
	SaveManager.set_active_slot_id(primary_slot_id)
	var primary_cash: float = float(loaded_primary_slot.get("player_portfolio", {}).get("cash", 0.0))
	var secondary_cash: float = float(loaded_secondary_slot.get("player_portfolio", {}).get("cash", 0.0))
	if not is_equal_approx(primary_cash, original_cash) or not is_equal_approx(secondary_cash, original_cash + 12345.0):
		return {
			"success": false,
			"message": "Smoke test expected save slots to preserve distinct run payloads while switching active slots."
		}
	SaveManager.delete_save(secondary_slot_id)
	var deleted_secondary_slot: Dictionary = SaveManager.get_save_file_info(secondary_slot_id)
	if bool(deleted_secondary_slot.get("loadable", false)) or bool(deleted_secondary_slot.get("exists", false)) or bool(deleted_secondary_slot.get("backup_exists", false)):
		return {
			"success": false,
			"message": "Smoke test expected deleting a save slot to remove its primary and backup files."
		}

	SaveManager.set_autosave_enabled(false)
	SaveManager.request_save("smoke_autosave_disabled")
	if SaveManager.has_pending_save() or not SaveManager.has_unsaved_changes():
		SaveManager.set_autosave_enabled(true)
		return {
			"success": false,
			"message": "Smoke test expected disabled autosave to track unsaved changes without queuing a pending save."
		}
	SaveManager.set_autosave_enabled(true)
	if not SaveManager.has_pending_save():
		return {
			"success": false,
			"message": "Smoke test expected re-enabling autosave to queue the unsaved change for persistence."
		}
	if not SaveManager.flush_pending_save() or SaveManager.has_unsaved_changes():
		return {
			"success": false,
			"message": "Smoke test expected flushing the re-enabled autosave to clear unsaved state."
		}

	if OS.get_cmdline_user_args().has(SMOKE_LOCAL_IO_ARG):
		var save_file = FileAccess.open(str(save_info.get("path", "")), FileAccess.WRITE)
		if save_file == null:
			return {
				"success": false,
				"message": "Smoke test could not intentionally corrupt the smoke save for backup recovery validation."
			}
		save_file.store_string("{broken")
		save_file = null

		var recovered_save: Dictionary = SaveManager.load_run()
		var load_status: Dictionary = SaveManager.get_last_load_status()
		if recovered_save.is_empty() or not bool(load_status.get("recovered_from_backup", false)):
			return {
				"success": false,
				"message": "Smoke test expected SaveManager to recover from the backup when the primary smoke save is malformed."
			}
		if int(recovered_save.get("save_schema_version", 0)) < 2:
			return {
				"success": false,
				"message": "Smoke test expected the recovered backup save to preserve schema metadata."
			}
		if not SaveManager.save_run(RunState.to_save_dict()):
			return {
				"success": false,
				"message": "Smoke test expected SaveManager to restore the primary save after backup recovery validation."
			}

	return {"success": true}


func _guide_smoke_rect_from_dict(rect_data: Dictionary) -> Rect2:
	return Rect2(
		Vector2(float(rect_data.get("x", 0.0)), float(rect_data.get("y", 0.0))),
		Vector2(float(rect_data.get("width", 0.0)), float(rect_data.get("height", 0.0)))
	)


func _guide_smoke_tab_index(tabs: TabContainer, title: String) -> int:
	if tabs == null:
		return -1
	for tab_index in range(tabs.get_tab_count()):
		if tabs.get_tab_title(tab_index) == title:
			return tab_index
	return -1


func _guide_smoke_flow_steps(state: Dictionary, flow_id: String) -> Array:
	var completed_steps: Dictionary = state.get("completed_step_ids", {})
	return completed_steps.get(flow_id, [])


func _guide_smoke_fail(root: Node, message: String) -> Dictionary:
	if root != null:
		root.queue_free()
		await get_tree().process_frame
	return {"success": false, "message": message}


func _guide_smoke_wait(frame_count: int = 4) -> void:
	for _frame in range(frame_count):
		await get_tree().process_frame


func _guide_smoke_press_handoff(root: Node) -> bool:
	var state: Dictionary = root.call("get_guide_smoke_state")
	if str(state.get("current_step_id", "")) != "handoff":
		return true
	var done_button: Button = root.find_child("GuideCoachmarkSkipButton", true, false) as Button
	if done_button == null:
		return false
	done_button.emit_signal("pressed")
	await _guide_smoke_wait(4)
	return true


func _validate_progressive_guide_flow() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(246810, difficulty_config)
	RunState.setup_new_run(246810, company_definitions, difficulty_config, true)
	GameManager.simulate_opening_session(false)
	var game_root = load("res://scenes/game/GameRoot.tscn").instantiate()
	add_child(game_root)
	await _guide_smoke_wait(8)

	if not game_root.has_method("get_guide_smoke_state"):
		return await _guide_smoke_fail(game_root, "Smoke test expected GameRoot to expose unified guide smoke state.")

	var guide_state: Dictionary = game_root.call("get_guide_smoke_state")
	if (
		not bool(guide_state.get("overlay_exists", false)) or
		not bool(guide_state.get("visible", false)) or
		str(guide_state.get("current_flow_id", "")) != "watchlist_flow" or
		str(guide_state.get("current_step_id", "")) != "open_stockbot"
	):
		return await _guide_smoke_fail(game_root, "Smoke test expected tutorial-enabled runs to start watchlist_flow at open_stockbot, got %s." % str(guide_state))
	if (
		float(guide_state.get("card_min_width", 0.0)) < 520.0 or
		not bool(guide_state.get("hub_button_exists", false)) or
		not bool(guide_state.get("taskbar_hub_exists", false)) or
		not bool(guide_state.get("help_hub_exists", false)) or
		str(guide_state.get("title", "")).is_empty() or
		str(guide_state.get("objective", "")).is_empty() or
		str(guide_state.get("progress", "")).find("Step 1") == -1
	):
		return await _guide_smoke_fail(game_root, "Smoke test expected the guide card to be large, readable, and expose Guide Hub entry points.")
	if int(guide_state.get("overlay_mouse_filter", -1)) != Control.MOUSE_FILTER_IGNORE or int(guide_state.get("card_mouse_filter", -1)) != Control.MOUSE_FILTER_STOP or bool(guide_state.get("card_parent_is_overlay", true)):
		return await _guide_smoke_fail(game_root, "Smoke test expected the guide dim/highlight layer to ignore mouse input while only the card captures clicks.")
	if not bool(guide_state.get("highlight_visible", false)) or str(guide_state.get("highlight_target_name", "")) != "StockAppButton":
		return await _guide_smoke_fail(game_root, "Smoke test expected the first guide step to highlight STOCKBOT.")
	var initial_card_rect: Rect2 = _guide_smoke_rect_from_dict(guide_state.get("card_rect", {}))
	var initial_highlight_rect: Rect2 = _guide_smoke_rect_from_dict(guide_state.get("highlight_rect", {}))
	if initial_card_rect.size.x < 520.0 or initial_card_rect.intersects(initial_highlight_rect):
		return await _guide_smoke_fail(game_root, "Smoke test expected the guide card to stay large and not overlap the highlighted desktop target.")

	var settings_app_button: Button = game_root.find_child("ExitAppButton", true, false) as Button
	var settings_dialog: Control = game_root.find_child("SettingsDialog", true, false) as Control
	if settings_app_button == null or settings_dialog == null:
		return await _guide_smoke_fail(game_root, "Smoke test could not find Settings controls for stale-highlight coverage.")
	settings_app_button.emit_signal("pressed")
	await _guide_smoke_wait(3)
	guide_state = game_root.call("get_guide_smoke_state")
	if bool(guide_state.get("visible", false)) or bool(guide_state.get("highlight_visible", false)):
		return await _guide_smoke_fail(game_root, "Smoke test expected modal windows to pause the guide and clear stale highlights. settings_visible=%s state=%s" % [str(settings_dialog.visible), str(guide_state)])
	game_root.call("_hide_settings_dialog")
	await _guide_smoke_wait(2)

	var guide_hub_button: Button = game_root.find_child("GuideHubButton", true, false) as Button
	var guide_hub_close_button: Button = game_root.find_child("GuideHubCloseButton", true, false) as Button
	if guide_hub_button == null or guide_hub_close_button == null:
		return await _guide_smoke_fail(game_root, "Smoke test expected the coachmark to expose Guide Hub controls.")
	guide_hub_button.emit_signal("pressed")
	await _guide_smoke_wait(2)
	guide_state = game_root.call("get_guide_smoke_state")
	if not bool(guide_state.get("hub_visible", false)):
		return await _guide_smoke_fail(game_root, "Smoke test expected Guide Hub to open from the guide card.")
	guide_hub_close_button.emit_signal("pressed")
	await _guide_smoke_wait(2)

	var stock_app_button: Button = game_root.find_child("StockAppButton", true, false) as Button
	var dashboard_button: Button = game_root.find_child("DashboardButton", true, false) as Button
	var markets_button: Button = game_root.find_child("MarketsButton", true, false) as Button
	var stock_list_tabs: TabContainer = game_root.find_child("StockListTabs", true, false) as TabContainer
	var work_tabs: TabContainer = game_root.find_child("WorkTabs", true, false) as TabContainer
	var buy_button: Button = game_root.find_child("BuyButton", true, false) as Button
	var lot_spin_box: SpinBox = game_root.find_child("LotSpinBox", true, false) as SpinBox
	var submit_order_button: Button = game_root.find_child("SubmitOrderButton", true, false) as Button
	var portfolio_button: Button = game_root.find_child("PortfolioButton", true, false) as Button
	var advance_day_button: Button = game_root.find_child("DesktopAdvanceDayButton", true, false) as Button
	var stockbot_close_button: Button = game_root.find_child("StockbotCloseButton", true, false) as Button
	if stock_app_button == null or dashboard_button == null or markets_button == null or stock_list_tabs == null or work_tabs == null or buy_button == null or lot_spin_box == null or submit_order_button == null or portfolio_button == null or advance_day_button == null or stockbot_close_button == null:
		return await _guide_smoke_fail(game_root, "Smoke test could not find the controls needed to drive the starter guide loop.")

	stock_app_button.emit_signal("pressed")
	await _guide_smoke_wait(8)
	guide_state = game_root.call("get_guide_smoke_state")
	if (
		str(guide_state.get("current_flow_id", "")) != "watchlist_flow" or
		not ["open_all_stock", "select_stock", "add_watchlist"].has(str(guide_state.get("current_step_id", ""))) or
		str(guide_state.get("highlight_target_name", "")) != "MarketsButton"
	):
		return await _guide_smoke_fail(game_root, "Smoke test expected Watchlist setup to highlight Trade before showing hidden list controls; state=%s." % str(guide_state))
	markets_button.emit_signal("pressed")
	await _guide_smoke_wait(4)
	var all_stock_tab_index: int = _guide_smoke_tab_index(stock_list_tabs, "All Stock")
	if all_stock_tab_index >= 0 and stock_list_tabs.current_tab != all_stock_tab_index:
		stock_list_tabs.current_tab = all_stock_tab_index
		stock_list_tabs.emit_signal("tab_changed", all_stock_tab_index)
		await _guide_smoke_wait(4)
	var guide_company_id: String = str(RunState.company_order[0])
	var all_stock_select_button: Button = game_root.find_child("AllStockSelectButton_%s" % guide_company_id, true, false) as Button
	var all_stock_add_button: Button = game_root.find_child("AllStockAddButton_%s" % guide_company_id, true, false) as Button
	if all_stock_select_button == null or all_stock_add_button == null:
		return await _guide_smoke_fail(game_root, "Smoke test expected All Stock rows to expose select and watchlist controls.")
	guide_state = game_root.call("get_guide_smoke_state")
	if str(guide_state.get("current_step_id", "")) != "select_stock":
		return await _guide_smoke_fail(game_root, "Smoke test expected Watchlist to wait for an explicit stock selection, got %s." % str(guide_state))
	if str(guide_state.get("current_step_id", "")) != "add_watchlist":
		all_stock_select_button.emit_signal("pressed")
		await _guide_smoke_wait(4)
	dashboard_button.emit_signal("pressed")
	await _guide_smoke_wait(4)
	guide_state = game_root.call("get_guide_smoke_state")
	if str(guide_state.get("current_flow_id", "")) != "watchlist_flow" or str(guide_state.get("current_step_id", "")) != "add_watchlist" or str(guide_state.get("highlight_target_name", "")) != "MarketsButton":
		return await _guide_smoke_fail(game_root, "Smoke test expected Save Company to highlight Trade when the player is still on Dashboard; state=%s." % str(guide_state))
	markets_button.emit_signal("pressed")
	await _guide_smoke_wait(4)
	guide_state = game_root.call("get_guide_smoke_state")
	if str(guide_state.get("highlight_target_name", "")) != "AllStocksScroll":
		return await _guide_smoke_fail(game_root, "Smoke test expected Save Company to highlight the stock/watch column after Trade opens; state=%s." % str(guide_state))
	all_stock_add_button.emit_signal("pressed")
	await _guide_smoke_wait(6)
	guide_state = game_root.call("get_guide_smoke_state")
	if str(guide_state.get("current_flow_id", "")) != "watchlist_flow" or str(guide_state.get("current_step_id", "")) != "handoff":
		return await _guide_smoke_fail(game_root, "Smoke test expected adding a watchlist stock to finish watchlist_flow, got %s." % str(guide_state))
	var completed_watchlist_steps: Array = _guide_smoke_flow_steps(guide_state, "watchlist_flow")
	for required_step in ["open_stockbot", "open_all_stock", "select_stock", "add_watchlist"]:
		if not completed_watchlist_steps.has(required_step):
			return await _guide_smoke_fail(game_root, "Smoke test expected watchlist_flow to complete %s." % required_step)
	var handoff_ok: bool = await _guide_smoke_press_handoff(game_root)
	if not handoff_ok:
		return await _guide_smoke_fail(game_root, "Smoke test could not complete the watchlist handoff card.")

	guide_state = game_root.call("get_guide_smoke_state")
	if str(guide_state.get("current_flow_id", "")) != "trade_flow":
		return await _guide_smoke_fail(game_root, "Smoke test expected completing watchlist_flow to start trade_flow.")
	var key_stats_tab_index: int = _guide_smoke_tab_index(work_tabs, "Key Stats")
	if key_stats_tab_index >= 0:
		work_tabs.current_tab = key_stats_tab_index
		work_tabs.emit_signal("tab_changed", key_stats_tab_index)
		await _guide_smoke_wait(5)
	buy_button.emit_signal("pressed")
	lot_spin_box.value = 1.0
	await _guide_smoke_wait(2)
	submit_order_button.emit_signal("pressed")
	await _guide_smoke_wait(6)
	portfolio_button.emit_signal("pressed")
	await _guide_smoke_wait(5)
	guide_state = game_root.call("get_guide_smoke_state")
	if (
		str(guide_state.get("current_flow_id", "")) != "trade_flow" or
		str(guide_state.get("current_step_id", "")) != "close_stockbot" or
		str(guide_state.get("active_app_id", "")) != "stock" or
		not bool(game_root.call("is_desktop_app_open", "stock")) or
		str(guide_state.get("active_section_id", "")) != "portfolio" or
		str(guide_state.get("highlight_target_name", "")) != "StockbotCloseButton"
	):
		return await _guide_smoke_fail(game_root, "Smoke test expected trade_flow to keep Portfolio visible and target the STOCKBOT close button; state=%s." % str(guide_state))
	stockbot_close_button.emit_signal("pressed")
	await _guide_smoke_wait(5)
	guide_state = game_root.call("get_guide_smoke_state")
	if (
		str(guide_state.get("current_flow_id", "")) != "trade_flow" or
		str(guide_state.get("current_step_id", "")) != "advance_day" or
		str(guide_state.get("active_app_id", "")) != "desktop" or
		bool(game_root.call("is_desktop_app_open", "stock")) or
		str(guide_state.get("highlight_target_name", "")) != "DesktopAdvanceDayButton"
	):
		return await _guide_smoke_fail(game_root, "Smoke test expected closing STOCKBOT to move trade_flow to the desktop Advance Day button; state=%s." % str(guide_state))
	advance_day_button.emit_signal("pressed")
	await _guide_smoke_wait(16)
	var daily_recap_dialog: Control = game_root.find_child("DailyRecapDialog", true, false) as Control
	var daily_recap_continue_button: Button = game_root.find_child("DailyRecapContinueButton", true, false) as Button
	if daily_recap_dialog == null or daily_recap_continue_button == null or not daily_recap_dialog.visible:
		return await _guide_smoke_fail(game_root, "Smoke test expected trade_flow to open Daily Recap after Advance Day.")
	daily_recap_continue_button.emit_signal("pressed")
	await _guide_smoke_wait(6)
	guide_state = game_root.call("get_guide_smoke_state")
	var completed_trade_steps: Array = _guide_smoke_flow_steps(guide_state, "trade_flow")
	for required_step in ["inspect_setup", "buy_one_lot", "open_portfolio", "close_stockbot", "advance_day", "read_recap"]:
		if not completed_trade_steps.has(required_step):
			return await _guide_smoke_fail(game_root, "Smoke test expected trade_flow to complete %s; state=%s." % [required_step, str(guide_state)])
	if str(guide_state.get("current_flow_id", "")) != "trade_flow" or str(guide_state.get("current_step_id", "")) != "handoff":
		return await _guide_smoke_fail(game_root, "Smoke test expected trade_flow to end on its handoff card.")
	handoff_ok = await _guide_smoke_press_handoff(game_root)
	if not handoff_ok:
		return await _guide_smoke_fail(game_root, "Smoke test could not complete the trade handoff card.")
	await _guide_smoke_wait(4)
	guide_state = game_root.call("get_guide_smoke_state")
	var completed_fundamental_early: bool = false
	if str(guide_state.get("current_flow_id", "")) == "fundamental_flow":
		var financials_tab_index_early: int = _guide_smoke_tab_index(work_tabs, "Financials")
		if financials_tab_index_early >= 0:
			work_tabs.current_tab = financials_tab_index_early
			work_tabs.emit_signal("tab_changed", financials_tab_index_early)
		await _guide_smoke_wait(6)
		handoff_ok = await _guide_smoke_press_handoff(game_root)
		if not handoff_ok:
			return await _guide_smoke_fail(game_root, "Smoke test could not complete the immediate contextual fundamental_flow.")
		completed_fundamental_early = true

	var news_app_button: Button = game_root.find_child("NewsAppButton", true, false) as Button
	var news_article_list: ItemList = game_root.find_child("NewsArticleList", true, false) as ItemList
	if news_app_button == null or news_article_list == null:
		return await _guide_smoke_fail(game_root, "Smoke test could not find News controls for research_flow.")
	news_app_button.emit_signal("pressed")
	await _guide_smoke_wait(8)
	guide_state = game_root.call("get_guide_smoke_state")
	if str(guide_state.get("current_flow_id", "")) != "research_flow":
		return await _guide_smoke_fail(game_root, "Smoke test expected opening News to prompt research_flow, got %s." % str(guide_state))
	if str(guide_state.get("current_step_id", "")) != "inspect_context" or str(guide_state.get("button_text", "")) == "Done":
		return await _guide_smoke_fail(game_root, "Smoke test expected opening News to wait for an explicit research action, got %s." % str(guide_state))
	if news_article_list.item_count > 0:
		news_article_list.select(0)
		news_article_list.emit_signal("item_selected", 0)
	await _guide_smoke_wait(5)
	handoff_ok = await _guide_smoke_press_handoff(game_root)
	if not handoff_ok:
		return await _guide_smoke_fail(game_root, "Smoke test could not complete research_flow.")

	if not completed_fundamental_early:
		stock_app_button.emit_signal("pressed")
		await _guide_smoke_wait(5)
		guide_state = game_root.call("get_guide_smoke_state")
		if str(guide_state.get("current_flow_id", "")) != "fundamental_flow" and key_stats_tab_index >= 0:
			work_tabs.current_tab = key_stats_tab_index
			work_tabs.emit_signal("tab_changed", key_stats_tab_index)
			await _guide_smoke_wait(6)
			guide_state = game_root.call("get_guide_smoke_state")
		if str(guide_state.get("current_flow_id", "")) != "fundamental_flow":
			return await _guide_smoke_fail(game_root, "Smoke test expected Key Stats to prompt fundamental_flow.")
		if str(guide_state.get("current_step_id", "")) != "open_key_stats":
			return await _guide_smoke_fail(game_root, "Smoke test expected fundamental_flow to wait on Key Stats instead of auto-jumping, got %s." % str(guide_state))
		var financials_tab_index: int = _guide_smoke_tab_index(work_tabs, "Financials")
		if financials_tab_index >= 0:
			work_tabs.current_tab = financials_tab_index
			work_tabs.emit_signal("tab_changed", financials_tab_index)
		await _guide_smoke_wait(6)
		handoff_ok = await _guide_smoke_press_handoff(game_root)
		if not handoff_ok:
			return await _guide_smoke_fail(game_root, "Smoke test could not complete fundamental_flow.")

	var chart_tab_index: int = _guide_smoke_tab_index(work_tabs, "Chart")
	stock_app_button.emit_signal("pressed")
	await _guide_smoke_wait(5)
	if chart_tab_index >= 0:
		work_tabs.current_tab = chart_tab_index
		work_tabs.emit_signal("tab_changed", chart_tab_index)
	await _guide_smoke_wait(6)
	guide_state = game_root.call("get_guide_smoke_state")
	if str(guide_state.get("current_flow_id", "")) != "technical_flow":
		return await _guide_smoke_fail(game_root, "Smoke test expected Chart to prompt technical_flow, got %s." % str(guide_state))
	if str(guide_state.get("current_step_id", "")) != "use_chart_tool":
		return await _guide_smoke_fail(game_root, "Smoke test expected technical_flow to wait for a fresh chart action, got %s." % str(guide_state))
	var chart_range_button: Button = game_root.find_child("Range6MButton", true, false) as Button
	if chart_range_button != null:
		chart_range_button.emit_signal("pressed")
	else:
		game_root.call("_on_guide_chart_interaction", "6m")
	await _guide_smoke_wait(6)
	handoff_ok = await _guide_smoke_press_handoff(game_root)
	if not handoff_ok:
		return await _guide_smoke_fail(game_root, "Smoke test could not complete technical_flow.")

	var thesis_app_button: Button = game_root.find_child("ThesisAppButton", true, false) as Button
	var thesis_company_option: OptionButton = game_root.find_child("ThesisCompanyOption", true, false) as OptionButton
	if thesis_app_button == null:
		return await _guide_smoke_fail(game_root, "Smoke test could not find Thesis Board for thesis_flow.")
	thesis_app_button.emit_signal("pressed")
	await _guide_smoke_wait(8)
	guide_state = game_root.call("get_guide_smoke_state")
	if str(guide_state.get("current_flow_id", "")) != "thesis_flow":
		return await _guide_smoke_fail(game_root, "Smoke test expected opening Thesis Board to prompt thesis_flow, got %s." % str(guide_state))
	if str(guide_state.get("current_step_id", "")) != "open_thesis" or str(guide_state.get("progress", "")).find("Step 1 of 5") < 0:
		return await _guide_smoke_fail(game_root, "Smoke test expected opening Thesis Board to start at Step 1 until a company is chosen, got %s." % str(guide_state))
	if not bool(guide_state.get("highlight_visible", false)) or str(guide_state.get("highlight_target_name", "")) != "ThesisCompanyOption":
		return await _guide_smoke_fail(game_root, "Smoke test expected thesis_flow Step 1 to highlight the company selector, got %s." % str(guide_state))
	if thesis_company_option != null and thesis_company_option.item_count > 0:
		thesis_company_option.select(0)
		thesis_company_option.emit_signal("item_selected", 0)
	else:
		game_root.call("_mark_guide_thesis_subject_chosen")
	await _guide_smoke_wait(6)
	guide_state = game_root.call("get_guide_smoke_state")
	if str(guide_state.get("current_step_id", "")) != "create_thesis" or str(guide_state.get("progress", "")).find("Step 2 of 5") < 0:
		return await _guide_smoke_fail(game_root, "Smoke test expected choosing a Thesis company to move to Step 2, got %s." % str(guide_state))
	var thesis_result: Dictionary = GameManager.create_thesis(guide_company_id, "bullish", "swing", "Guide Smoke Thesis")
	if not bool(thesis_result.get("success", false)):
		return await _guide_smoke_fail(game_root, "Smoke test expected thesis_flow to create a thesis for the guide company.")
	await _guide_smoke_wait(6)
	guide_state = game_root.call("get_guide_smoke_state")
	var thesis_completed_steps: Array = guide_state.get("completed_step_ids", {}).get("thesis_flow", [])
	if str(guide_state.get("current_step_id", "")) != "add_evidence" or not thesis_completed_steps.has("create_thesis"):
		return await _guide_smoke_fail(game_root, "Smoke test expected creating a thesis to advance thesis_flow to evidence, got %s." % str(guide_state))
	var thesis_id: String = str(thesis_result.get("thesis", {}).get("id", ""))
	GameManager.add_thesis_evidence(thesis_id, {"category": "fundamental", "category_label": "Fundamental", "label": "Profitability", "value": "Improving", "detail": "Guide smoke evidence.", "source_label": "Key Stats", "impact": "positive"})
	GameManager.add_thesis_evidence(thesis_id, {"category": "price_action", "category_label": "Price Action", "label": "Trend", "value": "Constructive", "detail": "Guide smoke chart evidence.", "source_label": "Chart", "impact": "positive"})
	game_root.call("_refresh_ftue_progress")
	await _guide_smoke_wait(8)
	handoff_ok = await _guide_smoke_press_handoff(game_root)
	if not handoff_ok:
		return await _guide_smoke_fail(game_root, "Smoke test could not complete thesis_flow.")

	var life_app_button: Button = game_root.find_child("LifeAppButton", true, false) as Button
	if life_app_button == null:
		return await _guide_smoke_fail(game_root, "Smoke test could not find Life for life_finance_flow.")
	life_app_button.emit_signal("pressed")
	await _guide_smoke_wait(8)
	guide_state = game_root.call("get_guide_smoke_state")
	if str(guide_state.get("current_flow_id", "")) != "life_finance_flow":
		return await _guide_smoke_fail(game_root, "Smoke test expected opening Life to prompt life_finance_flow.")
	if str(guide_state.get("current_step_id", "")) != "open_life" or str(guide_state.get("progress", "")).find("Step 1 of 3") < 0:
		return await _guide_smoke_fail(game_root, "Smoke test expected opening Life to start at Step 1 until the overview is reviewed, got %s." % str(guide_state))
	var life_update_button: Button = game_root.find_child("LifeUpdatePlanButton", true, false) as Button
	if life_update_button != null:
		life_update_button.emit_signal("pressed")
	else:
		game_root.call("_mark_guide_life_plan_reviewed")
	await _guide_smoke_wait(6)
	guide_state = game_root.call("get_guide_smoke_state")
	if str(guide_state.get("current_step_id", "")) != "open_finance" or str(guide_state.get("progress", "")).find("Step 2 of 3") < 0:
		return await _guide_smoke_fail(game_root, "Smoke test expected reviewing Life overview to move to Step 2, got %s." % str(guide_state))
	var life_tabs: TabContainer = game_root.find_child("LifeTabs", true, false) as TabContainer
	var finance_tab_index: int = _guide_smoke_tab_index(life_tabs, "Finance")
	if finance_tab_index >= 0:
		life_tabs.current_tab = finance_tab_index
		life_tabs.emit_signal("tab_changed", finance_tab_index)
	await _guide_smoke_wait(6)
	handoff_ok = await _guide_smoke_press_handoff(game_root)
	if not handoff_ok:
		return await _guide_smoke_fail(game_root, "Smoke test could not complete life_finance_flow.")

	var academy_app_button: Button = game_root.find_child("AcademyAppButton", true, false) as Button
	if academy_app_button == null:
		return await _guide_smoke_fail(game_root, "Smoke test could not find the Academy desktop shortcut.")
	academy_app_button.emit_signal("pressed")
	await _guide_smoke_wait(4)
	guide_state = game_root.call("get_guide_smoke_state")
	if game_root.call("is_desktop_app_open", "academy") or str(guide_state.get("current_flow_id", "")) == "academy_flow":
		return await _guide_smoke_fail(game_root, "Smoke test expected Academy to be release-locked instead of opening or prompting academy_flow, got %s." % str(guide_state))

	GameManager.start_guide_flow("corporate_event_flow")
	game_root.call("_refresh_ftue_progress")
	await _guide_smoke_wait(8)
	guide_state = game_root.call("get_guide_smoke_state")
	if str(guide_state.get("current_flow_id", "")) != "corporate_event_flow" or str(guide_state.get("seeded_meeting_id", "")).is_empty():
		return await _guide_smoke_fail(game_root, "Smoke test expected corporate_event_flow to seed a guided RUPSLB event.")
	GameManager.complete_guide_flow("corporate_event_flow")
	await _guide_smoke_wait(3)

	game_root.call("_show_guide_hub")
	await _guide_smoke_wait(3)
	var academy_flow_token: String = str(game_root.call("_node_token", "academy_flow"))
	var academy_flow_button: Button = game_root.find_child("GuideHubStart%sButton" % academy_flow_token, true, false) as Button
	if academy_flow_button == null or academy_flow_button.text != "Soon" or not academy_flow_button.disabled:
		return await _guide_smoke_fail(game_root, "Smoke test expected Guide Hub to show Academy as a disabled coming-soon guide.")
	var research_flow_token: String = str(game_root.call("_node_token", "research_flow"))
	var restart_research_button: Button = game_root.find_child("GuideHubStart%sButton" % research_flow_token, true, false) as Button
	if restart_research_button == null or restart_research_button.text != "Restart":
		return await _guide_smoke_fail(game_root, "Smoke test expected completed Guide Hub flows to expose a working Restart button.")
	restart_research_button.emit_signal("pressed")
	await _guide_smoke_wait(5)
	guide_state = game_root.call("get_guide_smoke_state")
	if (
		str(guide_state.get("current_flow_id", "")) != "research_flow" or
		str(guide_state.get("current_step_id", "")) != "open_research_app" or
		guide_state.get("completed_flow_ids", []).has("research_flow")
	):
		return await _guide_smoke_fail(game_root, "Smoke test expected Guide Hub Restart to reopen research_flow from the first step, got %s." % str(guide_state))
	GameManager.complete_guide_flow("research_flow")
	await _guide_smoke_wait(3)

	GameManager.start_guide_flow("research_flow")
	game_root.call("_refresh_ftue_progress")
	await _guide_smoke_wait(3)
	var later_button: Button = game_root.find_child("GuidePromptDismissButton", true, false) as Button
	if later_button == null:
		return await _guide_smoke_fail(game_root, "Smoke test expected contextual guide flows to expose a Later button.")
	later_button.emit_signal("pressed")
	await _guide_smoke_wait(3)
	var dismissed_snapshot: Dictionary = GameManager.get_guide_snapshot()
	if (
		not str(dismissed_snapshot.get("active_flow_id", "")).is_empty() or
		not dismissed_snapshot.get("dismissed_prompt_flow_ids", []).has("research_flow") or
		dismissed_snapshot.get("skipped_flow_ids", []).has("research_flow")
	):
		return await _guide_smoke_fail(game_root, "Smoke test expected Later to dismiss research_flow without marking it skipped, got %s." % str(dismissed_snapshot))
	GameManager.start_guide_flow("research_flow")
	GameManager.complete_guide_flow("research_flow")
	GameManager.dismiss_guide_prompt("research_flow")
	await _guide_smoke_wait(3)

	var completed_save_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(completed_save_state)
	var loaded_guide_snapshot: Dictionary = GameManager.get_guide_snapshot()
	var completed_flow_ids: Array = loaded_guide_snapshot.get("completed_flow_ids", [])
	for required_flow in ["watchlist_flow", "trade_flow", "research_flow", "fundamental_flow", "technical_flow", "thesis_flow", "life_finance_flow", "corporate_event_flow"]:
		if not completed_flow_ids.has(required_flow):
			return await _guide_smoke_fail(game_root, "Smoke test expected save/load to preserve completed guide flow %s." % required_flow)
	if not loaded_guide_snapshot.get("dismissed_prompt_flow_ids", []).has("research_flow"):
		return await _guide_smoke_fail(game_root, "Smoke test expected save/load to preserve dismissed contextual prompts.")
	game_root.queue_free()
	await get_tree().process_frame

	RunState.setup_new_run(246811, company_definitions, difficulty_config, true)
	GameManager.simulate_opening_session(false)
	var skip_root = load("res://scenes/game/GameRoot.tscn").instantiate()
	add_child(skip_root)
	await _guide_smoke_wait(6)
	var skip_button: Button = skip_root.find_child("GuideCoachmarkSkipButton", true, false) as Button
	if skip_button == null:
		return await _guide_smoke_fail(skip_root, "Smoke test expected tutorial-enabled guide to expose Skip Flow.")
	skip_button.emit_signal("pressed")
	await _guide_smoke_wait(4)
	var skip_snapshot: Dictionary = GameManager.get_guide_snapshot()
	if not skip_snapshot.get("skipped_flow_ids", []).has("watchlist_flow") or GameManager.should_show_tutorial():
		return await _guide_smoke_fail(skip_root, "Smoke test expected Skip Flow to persist a skipped watchlist guide and hide the active prompt.")
	var skipped_save_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(skipped_save_state)
	if not GameManager.get_guide_snapshot().get("skipped_flow_ids", []).has("watchlist_flow"):
		return await _guide_smoke_fail(skip_root, "Smoke test expected skipped flows to survive reload.")
	skip_root.queue_free()
	await get_tree().process_frame

	RunState.setup_new_run(246812, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	var disabled_root = load("res://scenes/game/GameRoot.tscn").instantiate()
	add_child(disabled_root)
	await _guide_smoke_wait(6)
	var disabled_state: Dictionary = disabled_root.call("get_guide_smoke_state") if disabled_root.has_method("get_guide_smoke_state") else {}
	if bool(disabled_state.get("visible", false)) or GameManager.should_show_tutorial():
		return await _guide_smoke_fail(disabled_root, "Smoke test expected tutorial-disabled runs to suppress automatic guides.")
	var disabled_hub_button: Button = disabled_root.find_child("GuideHubTaskbarButton", true, false) as Button
	if disabled_hub_button == null:
		return await _guide_smoke_fail(disabled_root, "Smoke test expected Guide Hub to remain manually available when tutorial is disabled.")
	disabled_hub_button.emit_signal("pressed")
	await _guide_smoke_wait(3)
	disabled_state = disabled_root.call("get_guide_smoke_state")
	if not bool(disabled_state.get("hub_visible", false)):
		return await _guide_smoke_fail(disabled_root, "Smoke test expected tutorial-disabled runs to open Guide Hub manually.")
	disabled_root.queue_free()
	await get_tree().process_frame

	if SaveManager.has_pending_save():
		SaveManager.flush_pending_save()
	return {"success": true}


func _validate_ftue_flow() -> Dictionary:
	return await _validate_progressive_guide_flow()
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(246810, difficulty_config)
	RunState.setup_new_run(246810, company_definitions, difficulty_config, true)
	GameManager.simulate_opening_session(false)
	var game_root = load("res://scenes/game/GameRoot.tscn").instantiate()
	add_child(game_root)
	for _frame in range(4):
		await get_tree().process_frame

	if not game_root.has_method("get_ftue_smoke_state"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected GameRoot to expose FTUE smoke state."
		}

	var ftue_state: Dictionary = game_root.call("get_ftue_smoke_state")
	if not bool(ftue_state.get("overlay_exists", false)) or not bool(ftue_state.get("visible", false)) or str(ftue_state.get("current_step_id", "")) != "welcome_desktop":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected tutorial-enabled runs to start the guided FTUE overlay on the desktop."
		}
	if int(ftue_state.get("overlay_mouse_filter", -1)) != Control.MOUSE_FILTER_IGNORE or int(ftue_state.get("card_mouse_filter", -1)) != Control.MOUSE_FILTER_STOP or bool(ftue_state.get("card_parent_is_overlay", true)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected FTUE dim/highlight layers to ignore mouse input while only the coachmark card captures clicks."
		}
	if game_root.find_child("Quick Tutorial", true, false) != null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the old Quick Tutorial dialog to be replaced by the FTUE overlay."
		}

	var stock_app_button: Button = game_root.find_child("StockAppButton", true, false) as Button
	var settings_app_button: Button = game_root.find_child("ExitAppButton", true, false) as Button
	var settings_app_label: Label = game_root.find_child("ExitAppLabel", true, false) as Label
	var settings_dialog: Control = game_root.find_child("SettingsDialog", true, false) as Control
	var settings_autosave_checkbox: CheckBox = game_root.find_child("SettingsAutosaveCheckBox", true, false) as CheckBox
	var settings_save_slots_list: ItemList = game_root.find_child("SettingsSaveSlotsList", true, false) as ItemList
	var settings_save_button: Button = game_root.find_child("SettingsSaveButton", true, false) as Button
	var settings_load_button: Button = game_root.find_child("SettingsLoadButton", true, false) as Button
	var settings_delete_button: Button = game_root.find_child("SettingsDeleteButton", true, false) as Button
	var settings_exit_button: Button = game_root.find_child("SettingsExitButton", true, false) as Button
	var settings_panel: PanelContainer = game_root.find_child("SettingsPanel", true, false) as PanelContainer
	var settings_current_slot_label: Label = game_root.find_child("SettingsCurrentSlotLabel", true, false) as Label
	var settings_last_saved_label: Label = game_root.find_child("SettingsLastSavedLabel", true, false) as Label
	var settings_build_label: Label = game_root.find_child("SettingsBuildLabel", true, false) as Label
	var settings_confirm_overlay: Control = game_root.find_child("SettingsConfirmOverlay", true, false) as Control
	var settings_confirm_title_label: Label = game_root.find_child("SettingsConfirmTitleLabel", true, false) as Label
	var settings_confirm_cancel_button: Button = game_root.find_child("SettingsConfirmCancelButton", true, false) as Button
	var taskbar_build_label: Label = game_root.find_child("TaskbarBuildLabel", true, false) as Label
	var work_tabs: TabContainer = game_root.find_child("WorkTabs", true, false) as TabContainer
	var buy_button: Button = game_root.find_child("BuyButton", true, false) as Button
	var lot_spin_box: SpinBox = game_root.find_child("LotSpinBox", true, false) as SpinBox
	var submit_order_button: Button = game_root.find_child("SubmitOrderButton", true, false) as Button
	var advance_day_button: Button = game_root.find_child("DesktopAdvanceDayButton", true, false) as Button
	if stock_app_button == null or work_tabs == null or buy_button == null or lot_spin_box == null or submit_order_button == null or advance_day_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the controls needed to drive the FTUE first trade loop."
		}
	if (
		settings_app_button == null or
		settings_app_label == null or
		settings_app_label.text != "SETTINGS" or
		settings_dialog == null or
		settings_autosave_checkbox == null or
		settings_save_slots_list == null or
		settings_save_button == null or
		settings_load_button == null or
		settings_delete_button == null or
		settings_exit_button == null or
		settings_panel == null or
		settings_current_slot_label == null or
		settings_last_saved_label == null or
		settings_build_label == null or
		settings_confirm_overlay == null or
		settings_confirm_title_label == null or
		settings_confirm_cancel_button == null or
		taskbar_build_label == null
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Settings shortcut and save/load popup controls to exist."
		}
	if taskbar_build_label.text.find(BuildInfo.get_build_number()) == -1:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the in-game taskbar to show the current build number."
		}
	settings_app_button.emit_signal("pressed")
	await get_tree().process_frame
	if not settings_dialog.visible or settings_save_slots_list.item_count != 5:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Settings to open a five-slot save/load overlay."
		}
	if (
		settings_panel.custom_minimum_size.y > 430.0 or
		not settings_save_button.visible or
		not settings_load_button.visible or
		not settings_delete_button.visible or
		not settings_exit_button.visible
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Settings overlay to stay compact with visible Save/Load/Delete/Exit controls."
		}
	if not settings_current_slot_label.text.contains("Current slot") or not settings_last_saved_label.text.contains("Last saved"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Settings to show current-slot and last-saved labels."
		}
	if settings_build_label.text.find(BuildInfo.get_build_number()) == -1:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Settings to show the current build number for bug reports."
		}
	settings_save_button.emit_signal("pressed")
	await get_tree().process_frame
	if not settings_last_saved_label.text.contains("Last saved"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Settings Save to refresh the save summary labels."
		}
	settings_load_button.emit_signal("pressed")
	await get_tree().process_frame
	if not settings_confirm_overlay.visible or settings_confirm_title_label.text != "Load Save?":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Settings Load to require confirmation."
		}
	settings_confirm_cancel_button.emit_signal("pressed")
	await get_tree().process_frame
	settings_delete_button.emit_signal("pressed")
	await get_tree().process_frame
	if not settings_confirm_overlay.visible or settings_confirm_title_label.text != "Delete Save?":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Settings Delete to require confirmation."
		}
	settings_confirm_cancel_button.emit_signal("pressed")
	await get_tree().process_frame
	settings_exit_button.emit_signal("pressed")
	await get_tree().process_frame
	if not settings_confirm_overlay.visible or settings_confirm_title_label.text != "Exit To Menu?":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Settings Exit to require confirmation."
		}
	settings_confirm_cancel_button.emit_signal("pressed")
	await get_tree().process_frame
	settings_dialog.hide()

	stock_app_button.emit_signal("pressed")
	for _frame in range(4):
		await get_tree().process_frame
	var snapshot: Dictionary = GameManager.get_ftue_snapshot()
	var completed_steps: Array = snapshot.get("completed_step_ids", [])
	if not completed_steps.has("welcome_desktop"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected opening STOCKBOT to complete the first FTUE step."
		}
	if str(snapshot.get("current_step_id", "")) == "pick_stock":
		var company_list: ItemList = game_root.find_child("CompanyList", true, false) as ItemList
		if company_list != null and company_list.item_count > 0:
			company_list.select(0)
			company_list.emit_signal("item_selected", 0)
		for _frame in range(3):
			await get_tree().process_frame

	snapshot = GameManager.get_ftue_snapshot()
	completed_steps = snapshot.get("completed_step_ids", [])
	if not completed_steps.has("pick_stock") or not (str(snapshot.get("current_step_id", "")) in ["inspect_setup", "buy_one_lot"]):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected confirming a stock to move FTUE into the inspect step, got %s." % str(snapshot)
		}
	var order_position_label: Label = game_root.find_child("PositionLabel", true, false) as Label
	var order_open_value_label: Label = game_root.find_child("OpenValueLabel", true, false) as Label
	var order_high_value_label: Label = game_root.find_child("HighValueLabel", true, false) as Label
	var order_low_value_label: Label = game_root.find_child("LowValueLabel", true, false) as Label
	var order_prev_value_label: Label = game_root.find_child("PrevValueLabel", true, false) as Label
	var order_lot_value_label: Label = game_root.find_child("LotValueLabel", true, false) as Label
	var order_depth_value_label: Label = game_root.find_child("DepthValueLabel", true, false) as Label
	var order_foreign_buy_value_label: Label = game_root.find_child("FBuyValueLabel", true, false) as Label
	var order_foreign_sell_value_label: Label = game_root.find_child("FSellValueLabel", true, false) as Label
	if (
		order_position_label == null or
		order_open_value_label == null or
		order_high_value_label == null or
		order_low_value_label == null or
		order_prev_value_label == null or
		order_lot_value_label == null or
		order_depth_value_label == null or
		order_foreign_buy_value_label == null or
		order_foreign_sell_value_label == null or
		order_position_label.visible or
		order_open_value_label.text == "-" or
		order_high_value_label.text == "-" or
		order_low_value_label.text == "-" or
		order_prev_value_label.text == "-" or
		order_lot_value_label.text == "-" or
		order_depth_value_label.text == "-" or
		order_foreign_buy_value_label.text == "-" or
		order_foreign_sell_value_label.text == "-" or
		order_foreign_buy_value_label.text == "Rp0,00" or
		order_foreign_sell_value_label.text == "Rp0,00"
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the STOCKBOT order header to show market summary fields while hiding the old holding/cash line."
		}

	if str(snapshot.get("current_step_id", "")) == "inspect_setup":
		work_tabs.current_tab = 1
		work_tabs.emit_signal("tab_changed", 1)
		for _frame in range(4):
			await get_tree().process_frame
	snapshot = GameManager.get_ftue_snapshot()
	completed_steps = snapshot.get("completed_step_ids", [])
	if not completed_steps.has("inspect_setup") or str(snapshot.get("current_step_id", "")) != "buy_one_lot":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected viewing a research tab to unlock the FTUE buy step."
		}

	buy_button.emit_signal("pressed")
	lot_spin_box.value = 1.0
	await get_tree().process_frame
	submit_order_button.emit_signal("pressed")
	for _frame in range(4):
		await get_tree().process_frame
	snapshot = GameManager.get_ftue_snapshot()
	completed_steps = snapshot.get("completed_step_ids", [])
	if not completed_steps.has("buy_one_lot") or str(snapshot.get("current_step_id", "")) != "advance_day":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a successful starter buy to move FTUE to Advance Day."
		}

	advance_day_button.emit_signal("pressed")
	for _frame in range(14):
		await get_tree().process_frame
	var daily_recap_dialog: Control = game_root.find_child("DailyRecapDialog", true, false) as Control
	snapshot = GameManager.get_ftue_snapshot()
	completed_steps = snapshot.get("completed_step_ids", [])
	if daily_recap_dialog == null or not daily_recap_dialog.visible or not completed_steps.has("advance_day") or str(snapshot.get("current_step_id", "")) != "read_recap":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Advance Day to show Daily Recap and move FTUE to the recap step."
		}

	var daily_recap_continue_button: Button = game_root.find_child("DailyRecapContinueButton", true, false) as Button
	if daily_recap_continue_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the Daily Recap continue button for FTUE completion."
		}
	daily_recap_continue_button.emit_signal("pressed")
	for _frame in range(4):
		await get_tree().process_frame
	snapshot = GameManager.get_ftue_snapshot()
	completed_steps = snapshot.get("completed_step_ids", [])
	ftue_state = game_root.call("get_ftue_smoke_state")
	if not completed_steps.has("read_recap") or str(snapshot.get("current_step_id", "")) != "next_steps" or str(ftue_state.get("button_text", "")) != "Finish":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected dismissing Daily Recap to show the final FTUE next-steps card."
		}

	var ftue_finish_button: Button = game_root.find_child("FtueCoachmarkSkipButton", true, false) as Button
	if ftue_finish_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the FTUE finish/skip button."
		}
	ftue_finish_button.emit_signal("pressed")
	await get_tree().process_frame
	snapshot = GameManager.get_ftue_snapshot()
	ftue_state = game_root.call("get_ftue_smoke_state")
	if not bool(snapshot.get("completed", false)) or bool(ftue_state.get("visible", true)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected finishing FTUE to persist completion and hide the overlay."
		}

	if not game_root.has_method("get_first_hour_guide_smoke_state"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected GameRoot to expose Guided First Week smoke state."
		}
	var guide_state: Dictionary = game_root.call("get_first_hour_guide_smoke_state")
	if (
		not bool(guide_state.get("panel_exists", false)) or
		not bool(guide_state.get("visible", false)) or
		str(guide_state.get("current_step_id", "")) != "portfolio_check" or
		str(guide_state.get("anchor_company_id", "")).is_empty()
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Guided First Week to start at Portfolio after FTUE completion."
		}
	if int(guide_state.get("panel_mouse_filter", -1)) != Control.MOUSE_FILTER_STOP:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Guided First Week panel to be interactive without blocking the whole desktop."
		}
	var portfolio_guide_target_name: String = str(guide_state.get("highlight_target_name", ""))
	if not bool(guide_state.get("highlight_visible", false)) or not (portfolio_guide_target_name in ["PortfolioButton", "StockAppButton"]):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Portfolio guide step to highlight the active Portfolio entry point, got %s." % portfolio_guide_target_name
		}
	var guide_anchor_company_id: String = str(guide_state.get("anchor_company_id", ""))
	if bool(GameManager.get_company_corporate_action_snapshot(guide_anchor_company_id).get("has_live_chain", false)):
		for fallback_company_id_value in RunState.company_order:
			var fallback_company_id: String = str(fallback_company_id_value)
			if fallback_company_id == guide_anchor_company_id:
				continue
			if bool(GameManager.get_company_corporate_action_snapshot(fallback_company_id).get("has_live_chain", false)):
				continue
			var fallback_buy_result: Dictionary = GameManager.buy_lots(fallback_company_id, 1)
			if bool(fallback_buy_result.get("success", false)):
				break
	var portfolio_button: Button = game_root.find_child("PortfolioButton", true, false) as Button
	var news_app_button: Button = game_root.find_child("NewsAppButton", true, false) as Button
	if portfolio_button == null or news_app_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find controls needed for Guided First Week."
		}

	portfolio_button.emit_signal("pressed")
	for _frame in range(3):
		await get_tree().process_frame
	guide_state = game_root.call("get_first_hour_guide_smoke_state")
	if not guide_state.get("completed_step_ids", []).has("portfolio_check") or str(guide_state.get("current_step_id", "")) != "create_thesis":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected opening Portfolio to move Guided First Week to Thesis."
		}
	if bool(guide_state.get("highlight_visible", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Thesis guide step to clear stale highlights while STOCKBOT is still the active window."
		}

	game_root._set_active_app("thesis")
	for _frame in range(4):
		await get_tree().process_frame
	guide_state = game_root.call("get_first_hour_guide_smoke_state")
	if (
		str(guide_state.get("current_step_id", "")) != "create_thesis" or
		not bool(guide_state.get("highlight_visible", false)) or
		str(guide_state.get("highlight_target_name", "")) != "ThesisCreateButton"
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected opening Thesis during the guide to highlight the Create button."
		}

	var guide_thesis_result: Dictionary = GameManager.create_thesis(guide_anchor_company_id, "bullish", "swing", "Guide Smoke Thesis")
	game_root._refresh_first_hour_guide_progress()
	await get_tree().process_frame
	guide_state = game_root.call("get_first_hour_guide_smoke_state")
	if not bool(guide_thesis_result.get("success", false)) or not guide_state.get("completed_step_ids", []).has("create_thesis") or str(guide_state.get("current_step_id", "")) != "add_watchlist":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected creating a thesis for the anchor stock to move Guided First Week to Watchlist."
		}
	if bool(guide_state.get("highlight_visible", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Watchlist guide step to clear the Thesis Create highlight after the thesis step completes."
		}

	var guide_watchlist_result: Dictionary = GameManager.add_company_to_watchlist(guide_anchor_company_id)
	if not bool(guide_watchlist_result.get("success", false)) and not RunState.is_in_watchlist(guide_anchor_company_id):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the guide anchor stock to be addable to watchlist."
		}
	game_root._refresh_first_hour_guide_progress()
	await get_tree().process_frame
	guide_state = game_root.call("get_first_hour_guide_smoke_state")
	if not guide_state.get("completed_step_ids", []).has("add_watchlist") or str(guide_state.get("current_step_id", "")) != "read_market_context":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected adding a watchlist stock to move Guided First Week to market context."
		}

	news_app_button.emit_signal("pressed")
	for _frame in range(8):
		await get_tree().process_frame
	guide_state = game_root.call("get_first_hour_guide_smoke_state")
	var guide_seeded_meeting_id: String = str(guide_state.get("seeded_meeting_id", ""))
	var guide_seeded_chain_id: String = str(guide_state.get("seeded_chain_id", ""))
	var guide_seeded_detail: Dictionary = GameManager.get_corporate_meeting_detail(guide_seeded_meeting_id)
	var guide_seeded_chain: Dictionary = RunState.get_active_corporate_action_chains().get(guide_seeded_chain_id, {})
	if (
		not guide_state.get("completed_step_ids", []).has("read_market_context") or
		not guide_state.get("completed_step_ids", []).has("seeded_rupslb") or
		str(guide_state.get("current_step_id", "")) != "attend_rupslb" or
		guide_seeded_meeting_id.is_empty() or
		guide_seeded_chain_id.is_empty() or
		str(guide_seeded_detail.get("request_source", "")) != "guided_first_hour" or
		str(guide_seeded_detail.get("chain_family", "")) != "stock_split" or
		str(guide_seeded_chain.get("request_source", "")) != "guided_first_hour"
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected market context to seed exactly one guided stock-split RUPSLB and move to Attend."
		}
	if not bool(guide_state.get("highlight_visible", false)) or str(guide_state.get("highlight_target_name", "")) != "DesktopAdvanceDayButton":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Attend guide step to highlight Advance Day while the seeded meeting is not yet due."
		}

	advance_day_button.emit_signal("pressed")
	for _frame in range(14):
		await get_tree().process_frame
	if daily_recap_dialog == null or not daily_recap_dialog.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected advancing toward the guided meeting to show Daily Recap."
		}
	var daily_recap_body_label: Label = game_root.find_child("DailyRecapBodyLabel", true, false) as Label
	if daily_recap_body_label == null or not daily_recap_body_label.text.contains("Next useful step"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Daily Recap to include the Guided First Week next-step hint."
		}
	daily_recap_continue_button.emit_signal("pressed")
	for _frame in range(4):
		await get_tree().process_frame

	game_root._open_corporate_meeting_modal(guide_seeded_meeting_id)
	for _frame in range(4):
		await get_tree().process_frame
	if not game_root.is_rupslb_meeting_overlay_visible():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the guided RUPSLB to open the interactive meeting overlay."
		}
	guide_state = game_root.call("get_first_hour_guide_smoke_state")
	if not guide_state.get("completed_step_ids", []).has("attend_rupslb") or str(guide_state.get("current_step_id", "")) != "approach_lead":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected opening the guided RUPSLB to move the guide to the lead approach step."
		}

	var guided_rupslb_continue_button: Button = game_root.find_child("RupslbContinueButton", true, false) as Button
	if guided_rupslb_continue_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the guided RUPSLB continue button."
		}
	guided_rupslb_continue_button.emit_signal("pressed")
	for _frame in range(3):
		await get_tree().process_frame
	var guided_session_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(guide_seeded_meeting_id)
	var guided_leads: Array = guided_session_snapshot.get("meeting_leads", [])
	var guided_lead_index: int = -1
	for lead_index in range(guided_leads.size()):
		if typeof(guided_leads[lead_index]) == TYPE_DICTIONARY and bool(guided_leads[lead_index].get("approachable", false)):
			guided_lead_index = lead_index
			break
	if guided_lead_index < 0:
		var guided_lead_debug_rows: Array = []
		for lead_value in guided_leads:
			if typeof(lead_value) != TYPE_DICTIONARY:
				continue
			var debug_lead: Dictionary = lead_value
			guided_lead_debug_rows.append("%s req=%d lock=%s" % [
				str(debug_lead.get("display_label", debug_lead.get("role_label", "Lead"))),
				int(debug_lead.get("recognition_required", 0)),
				str(debug_lead.get("locked_reason", ""))
			])
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the guided RUPSLB to include an approachable room lead. Leads: %s" % str(guided_lead_debug_rows)
		}
	var guided_marker_row: int = int(guided_lead_index / 5)
	var guided_marker_column: int = guided_lead_index % 5
	var guided_lead_marker: Button = game_root.find_child("RupslbAttendeeMarker_%d_%d" % [guided_marker_row, guided_marker_column], true, false) as Button
	if guided_lead_marker == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the guided RUPSLB approachable lead marker to render."
		}

	var before_no_lead_conclusion_save_state: Dictionary = RunState.to_save_dict()
	var no_lead_vote_stage_result: Dictionary = GameManager.set_corporate_meeting_session_stage(guide_seeded_meeting_id, "vote")
	if not bool(no_lead_vote_stage_result.get("success", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not move the guided RUPSLB to vote stage for stale-guide regression coverage."
		}
	game_root._refresh_rupslb_meeting_overlay()
	await get_tree().process_frame
	var no_lead_agree_button: Button = game_root.find_child("RupslbAgreeButton", true, false) as Button
	if no_lead_agree_button == null or not no_lead_agree_button.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the guided RUPSLB vote stage to expose the agree button."
		}
	no_lead_agree_button.emit_signal("pressed")
	for _frame in range(3):
		await get_tree().process_frame
	game_root._close_rupslb_meeting_overlay()
	for _frame in range(4):
		await get_tree().process_frame
	guide_state = game_root.call("get_first_hour_guide_smoke_state")
	if str(guide_state.get("current_step_id", "")) == "approach_lead":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected concluding the guided RUPSLB without a lead approach to clear Loop 7/8 instead of leaving a stale Room Lead objective."
		}

	RunState.load_from_dict(before_no_lead_conclusion_save_state)
	game_root._open_corporate_meeting_modal(guide_seeded_meeting_id)
	for _frame in range(4):
		await get_tree().process_frame
	if not game_root.is_rupslb_meeting_overlay_visible():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the guided RUPSLB to reopen after restoring pre-conclusion state."
		}
	guided_session_snapshot = GameManager.get_corporate_meeting_session_snapshot(guide_seeded_meeting_id)
	guided_leads = guided_session_snapshot.get("meeting_leads", [])
	guided_lead_marker = game_root.find_child("RupslbAttendeeMarker_%d_%d" % [guided_marker_row, guided_marker_column], true, false) as Button
	if guided_lead_marker == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the guided RUPSLB lead marker to return after save-state restore."
		}
	guided_lead_marker.emit_signal("pressed")
	await get_tree().process_frame
	var guided_lead_approach_button: Button = game_root.find_child("RupslbLeadApproachButton", true, false) as Button
	if guided_lead_approach_button == null or guided_lead_approach_button.disabled:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the selected guided RUPSLB lead to be approachable."
		}
	guided_lead_approach_button.emit_signal("pressed")
	for _frame in range(3):
		await get_tree().process_frame
	guide_state = game_root.call("get_first_hour_guide_smoke_state")
	if not guide_state.get("completed_step_ids", []).has("approach_lead") or str(guide_state.get("current_step_id", "")) != "handoff":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected approaching a guided RUPSLB lead to move the guide to handoff."
		}
	game_root._close_rupslb_meeting_overlay()
	for _frame in range(3):
		await get_tree().process_frame
	guide_state = game_root.call("get_first_hour_guide_smoke_state")
	if not bool(guide_state.get("visible", false)) or str(guide_state.get("button_text", "")) != "Done":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected closing the guided RUPSLB to reveal the final Loop Guide handoff card."
		}
	var guide_done_button: Button = game_root.find_child("FirstHourGuideSkipButton", true, false) as Button
	if guide_done_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the Loop Guide done button."
		}
	guide_done_button.emit_signal("pressed")
	await get_tree().process_frame
	guide_state = game_root.call("get_first_hour_guide_smoke_state")
	if not bool(guide_state.get("completed", false)) or bool(guide_state.get("visible", true)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected finishing Guided First Week to persist completion and hide the panel."
		}

	var completed_save_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(completed_save_state)
	if GameManager.should_show_tutorial():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected completed FTUE to stay hidden after reload."
		}
	if GameManager.should_show_first_hour_guide() or not bool(RunState.get_first_hour_guide_snapshot().get("completed", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected completed Guided First Week to stay hidden after reload."
		}
	var held_company_id: String = ""
	var held_shares: int = 0
	for held_company_id_value in RunState.player_portfolio.get("holdings", {}).keys():
		var candidate_company_id: String = str(held_company_id_value)
		var holding: Dictionary = RunState.player_portfolio.get("holdings", {}).get(candidate_company_id, {})
		var candidate_shares: int = int(holding.get("shares", 0))
		if candidate_shares > 0:
			held_company_id = candidate_company_id
			held_shares = candidate_shares
			break
	if held_company_id.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the guided run to keep at least one holding for fail-state coverage."
		}
	var insufficient_cash_result: Dictionary = GameManager.buy_company(held_company_id, 999999999)
	var insufficient_sell_result: Dictionary = GameManager.sell_company(held_company_id, held_shares + 100)
	if (
		bool(insufficient_cash_result.get("success", false)) or
		not str(insufficient_cash_result.get("message", "")).contains("Shortfall") or
		bool(insufficient_sell_result.get("success", false)) or
		not str(insufficient_sell_result.get("message", "")).contains("only own")
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected blocked order fail states to explain cash shortfall and owned-share limits."
		}
	var fail_recap_snapshot: Dictionary = GameManager.get_daily_recap_snapshot()
	var fail_recap_results: Dictionary = fail_recap_snapshot.get("last_day_results", {}).duplicate(true)
	fail_recap_results["life_obligation"] = {
		"amount": 2500000.0,
		"cash_after": -125000.0
	}
	fail_recap_results["network_request_results"] = [{"success": false, "message": "Network request missed."}]
	fail_recap_results["network_tip_results"] = [{"relationship_delta": -3}]
	fail_recap_snapshot["last_day_results"] = fail_recap_results
	fail_recap_snapshot["life"] = {
		"cash": 500000.0,
		"monthly_outflow": 1500000.0,
		"runway_months": 0.3,
		"next_life_payment": {
			"amount": 1500000.0,
			"date_text": "Mon, 03 Feb 2020",
			"due_in_trading_days": 2,
			"warning": true
		}
	}
	var fail_recap_summary: Dictionary = fail_recap_snapshot.get("summary", {}).duplicate(true)
	fail_recap_summary["portfolio_attribution"] = [{
		"ticker": "SMOK",
		"market_value_delta": -125000.0,
		"price_change_pct": -0.025
	}]
	fail_recap_snapshot["summary"] = fail_recap_summary
	fail_recap_snapshot["first_month_balance"] = {
		"cash": 500000.0,
		"next_life_payment": fail_recap_snapshot.get("life", {}).get("next_life_payment", {}).duplicate(true),
		"daily_action": {"remaining": 1, "limit": 10}
	}
	var fail_recap_text: String = game_root.call("_build_daily_recap_text", fail_recap_snapshot)
	if (
		not fail_recap_text.contains("Why Portfolio Moved") or
		not fail_recap_text.contains("Cash & AP") or
		not fail_recap_text.contains("Next Life payment") or
		not fail_recap_text.contains("AP pressure") or
		not fail_recap_text.contains("Risk Check") or
		not fail_recap_text.contains("Cash stress") or
		not fail_recap_text.contains("Network: 1 request missed") or
		not fail_recap_text.contains("hurt trust") or
		not fail_recap_text.contains("Runway:")
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Daily Recap to surface release-facing fail states for cash pressure, missed requests, weak reads, and runway."
		}
	game_root.queue_free()
	await get_tree().process_frame

	RunState.setup_new_run(246811, company_definitions, difficulty_config, true)
	GameManager.simulate_opening_session(false)
	var skip_root = load("res://scenes/game/GameRoot.tscn").instantiate()
	add_child(skip_root)
	for _frame in range(4):
		await get_tree().process_frame
	var skip_button: Button = skip_root.find_child("FtueCoachmarkSkipButton", true, false) as Button
	if skip_button == null:
		skip_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected tutorial-enabled FTUE to expose a skip button."
		}
	skip_button.emit_signal("pressed")
	await get_tree().process_frame
	var skipped_save_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(skipped_save_state)
	snapshot = GameManager.get_ftue_snapshot()
	if not bool(snapshot.get("skipped", false)) or GameManager.should_show_tutorial() or GameManager.should_show_first_hour_guide():
		skip_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected skipped FTUE to persist and suppress the later guide after reload."
		}
	skip_root.queue_free()
	await get_tree().process_frame

	RunState.setup_new_run(246812, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	var disabled_root = load("res://scenes/game/GameRoot.tscn").instantiate()
	add_child(disabled_root)
	for _frame in range(4):
		await get_tree().process_frame
	var disabled_state: Dictionary = disabled_root.call("get_ftue_smoke_state") if disabled_root.has_method("get_ftue_smoke_state") else {}
	var disabled_guide_state: Dictionary = disabled_root.call("get_first_hour_guide_smoke_state") if disabled_root.has_method("get_first_hour_guide_smoke_state") else {}
	if bool(disabled_state.get("visible", false)) or bool(disabled_guide_state.get("visible", false)) or GameManager.should_show_tutorial() or GameManager.should_show_first_hour_guide():
		disabled_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected tutorial-disabled runs to suppress FTUE and Guided First Week."
		}
	disabled_root.queue_free()
	await get_tree().process_frame

	var legacy_save_state: Dictionary = RunState.to_save_dict()
	for guide_key in [
		"first_hour_guide_enabled",
		"first_hour_guide_completed",
		"first_hour_guide_skipped",
		"first_hour_guide_current_step_id",
		"first_hour_guide_completed_step_ids",
		"first_hour_guide_start_day_index",
		"first_hour_guide_anchor_company_id",
		"first_hour_guide_seeded_meeting_id",
		"first_hour_guide_seeded_chain_id"
	]:
		legacy_save_state.erase(guide_key)
	RunState.load_from_dict(legacy_save_state)
	if GameManager.should_show_first_hour_guide() or bool(RunState.get_first_hour_guide_snapshot().get("enabled", false)):
		return {
			"success": false,
			"message": "Smoke test expected legacy saves without Guided First Week fields to keep the guide disabled."
		}

	if SaveManager.has_pending_save():
		SaveManager.flush_pending_save()
	return {"success": true}


func _validate_corporate_action_price_factor_limits() -> String:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(509917, difficulty_config)
	if company_definitions.is_empty():
		return "Smoke test expected a generated roster for corporate-action price factor limit coverage."
	RunState.setup_new_run(509917, company_definitions, difficulty_config, false)
	var company_id: String = str(RunState.company_order[0])
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	var previous_close: float = 3547.0
	var current_price: float = 3467.0
	var ar_limits: Dictionary = IDX_PRICE_RULES.auto_rejection_limits(previous_close, str(definition.get("listing_board", "main")))
	var runtime: Dictionary = RunState.get_company(company_id).duplicate(true)
	runtime["previous_close"] = previous_close
	runtime["current_price"] = current_price
	runtime["daily_change_pct"] = (current_price - previous_close) / previous_close
	runtime["sentiment"] = runtime["daily_change_pct"]
	runtime["ar_limits"] = ar_limits.duplicate(true)
	runtime["price_history"] = [previous_close, current_price]
	runtime["price_bars"] = [{
		"open": 3490.0,
		"high": 3560.0,
		"low": 3400.0,
		"close": current_price,
		"volume_shares": 100000,
		"value": current_price * 100000.0
	}]
	RunState.companies[company_id] = runtime

	var clamped_down_price: float = float(RunState.call("_apply_company_price_factor", company_id, 0.65, false))
	var after_down: Dictionary = RunState.get_company(company_id)
	var down_limits: Dictionary = after_down.get("ar_limits", {})
	var lower_price: float = float(down_limits.get("lower_price", 0.0))
	if not is_equal_approx(clamped_down_price, lower_price) or float(after_down.get("current_price", 0.0)) < lower_price - 0.0001:
		return "Smoke test expected post-close corporate action markdowns to clamp at ARB, found %s below %s." % [clamped_down_price, lower_price]
	var down_bars: Array = after_down.get("price_bars", [])
	var down_bar: Dictionary = down_bars[down_bars.size() - 1]
	if (
		float(down_bar.get("open", 0.0)) < lower_price - 0.0001 or
		float(down_bar.get("high", 0.0)) < lower_price - 0.0001 or
		float(down_bar.get("low", 0.0)) < lower_price - 0.0001 or
		float(down_bar.get("close", 0.0)) < lower_price - 0.0001 or
		str(down_bar.get("limit_lock", "")) != "arb"
	):
		return "Smoke test expected the corporate-action adjusted daily bar to stay inside ARB with an ARB lock."

	var clamped_up_price: float = float(RunState.call("_apply_company_price_factor", company_id, 1.50, false))
	var after_up: Dictionary = RunState.get_company(company_id)
	var up_limits: Dictionary = after_up.get("ar_limits", {})
	var upper_price: float = float(up_limits.get("upper_price", 0.0))
	if not is_equal_approx(clamped_up_price, upper_price) or float(after_up.get("current_price", 0.0)) > upper_price + 0.0001:
		return "Smoke test expected post-close corporate action markups to clamp at ARA, found %s above %s." % [clamped_up_price, upper_price]
	var up_bars: Array = after_up.get("price_bars", [])
	var up_bar: Dictionary = up_bars[up_bars.size() - 1]
	if (
		float(up_bar.get("open", 0.0)) > upper_price + 0.0001 or
		float(up_bar.get("high", 0.0)) > upper_price + 0.0001 or
		float(up_bar.get("low", 0.0)) > upper_price + 0.0001 or
		float(up_bar.get("close", 0.0)) > upper_price + 0.0001 or
		str(up_bar.get("limit_lock", "")) != "ara"
	):
		return "Smoke test expected the corporate-action adjusted daily bar to stay inside ARA with an ARA lock."
	return ""


func _validate_index_review_content_assets() -> String:
	var catalog: Dictionary = DataRepository.get_index_review_catalog()
	var providers: Array = catalog.get("providers", [])
	if providers.size() != 2:
		return "Smoke test expected exactly two index-review providers."
	var expected_labels := {"mscy": "MSCY", "ftsi": "FTSI"}
	var expected_months := {"mscy": [2, 5, 8, 11], "ftsi": [3, 6, 9, 12]}
	for provider_value in providers:
		if typeof(provider_value) != TYPE_DICTIONARY:
			return "Smoke test expected index-review provider rows to be dictionaries."
		var provider: Dictionary = provider_value
		var provider_id: String = str(provider.get("id", ""))
		if not expected_labels.has(provider_id):
			return "Smoke test found an unexpected index-review provider id: %s." % provider_id
		if str(provider.get("label", "")) != str(expected_labels.get(provider_id, "")):
			return "Smoke test expected provider %s to use fictional label %s." % [provider_id, expected_labels.get(provider_id, "")]
		if _int_array_from_variant(provider.get("review_months", [])) != _int_array_from_variant(expected_months.get(provider_id, [])):
			return "Smoke test expected provider %s review months to match the quarterly catalog." % provider_id
		if int(provider.get("announcement_day", 0)) != 10 or int(provider.get("effective_day", 0)) != 20:
			return "Smoke test expected provider %s to use day-10 announcement and day-20 effective rules." % provider_id

	for event_id in [
		"mscy_index_inclusion",
		"mscy_index_exclusion",
		"mscy_index_watch",
		"ftsi_index_inclusion",
		"ftsi_index_exclusion",
		"ftsi_index_watch",
		"index_review_no_change"
	]:
		var event_definition: Dictionary = DataRepository.get_event_definition(event_id)
		if event_definition.is_empty():
			return "Smoke test expected index-review event definition %s." % event_id
		if str(event_definition.get("event_family", "")) != "index_review":
			return "Smoke test expected %s to use event_family index_review." % event_id

	var trade_date: Dictionary = {
		"weekday": 3,
		"day": 10,
		"month": 2,
		"year": 2020,
		"day_index": 29
	}
	var company_rows: Array = [{
		"id": "mock_bank",
		"ticker": "MBNK",
		"name": "Mock Bank Tbk",
		"sector_id": "finance",
		"sector_name": "Finance",
		"current_price": 1200.0,
		"daily_change_pct": 0.036,
		"broker_flow": {"flow_tag": "accumulation"}
	}]
	var market_history: Array = [{
		"day_index": 29,
		"trade_date": trade_date.duplicate(true),
		"average_change_pct": 0.006,
		"advancers": 20,
		"decliners": 10,
		"biggest_winner": {"ticker": "MBNK"},
		"biggest_loser": {"ticker": "DROP"}
	}]
	var index_event: Dictionary = {
		"event_id": "mscy_index_inclusion",
		"event_family": "index_review",
		"scope": "company",
		"category": "index_inclusion",
		"tone": "positive",
		"target_company_id": "mock_bank",
		"target_ticker": "MBNK",
		"target_company_name": "Mock Bank Tbk",
		"target_sector_id": "finance",
		"provider_label": "MSCY",
		"summary": "MSCY announced MBNK as an index inclusion candidate, with passive buying expected around the effective date.",
		"review_stage": "announcement",
		"day_index": 29,
		"trade_date": trade_date.duplicate(true)
	}
	var news_snapshot: Dictionary = NEWS_FEED_SYSTEM_SCRIPT.new().build_news_snapshot(
		null,
		DataRepository.get_news_feed_data(),
		company_rows,
		market_history,
		[index_event],
		[],
		[],
		trade_date,
		4
	)
	var found_news_article: bool = false
	for feed_value in news_snapshot.get("feeds", {}).values():
		var feed: Dictionary = feed_value
		for article_value in feed.get("articles", []):
			var article: Dictionary = article_value
			if str(article.get("category", "")) != "index_inclusion":
				continue
			found_news_article = true
			var article_text: String = "%s\n%s\n%s" % [str(article.get("headline", "")), str(article.get("deck", "")), str(article.get("body", ""))]
			if article_text.find("MSCY") == -1:
				return "Smoke test expected index-review News copy to include fictional provider MSCY."
			if article_text.find("{") != -1 or article_text.find("}") != -1:
				return "Smoke test expected index-review News copy to render without unresolved template tokens."
	if not found_news_article:
		return "Smoke test expected News generation to produce an index-review article."

	var social_snapshot: Dictionary = TWOOTER_FEED_SYSTEM_SCRIPT.new().build_social_snapshot(
		null,
		DataRepository.get_twooter_feed_data(),
		company_rows,
		market_history,
		[index_event],
		[],
		[],
		trade_date,
		4
	)
	var found_social_post: bool = false
	for post_value in social_snapshot.get("posts", []):
		var post: Dictionary = post_value
		if str(post.get("category", "")) != "index_inclusion":
			continue
		found_social_post = true
		var post_text: String = str(post.get("post_text", ""))
		if post_text.find("MSCY") == -1:
			return "Smoke test expected index-review Twooter copy to include fictional provider MSCY."
		if post_text.find("{") != -1 or post_text.find("}") != -1:
			return "Smoke test expected index-review Twooter copy to render without unresolved template tokens."
	if not found_social_post:
		return "Smoke test expected Twooter generation to produce an index-review post."

	return ""


func _int_array_from_variant(source: Variant) -> Array:
	var values: Array = []
	if typeof(source) != TYPE_ARRAY:
		return values
	for value in source:
		values.append(int(value))
	return values


func _validate_index_review_runtime_flow() -> String:
	var saved_state: Dictionary = RunState.to_save_dict()
	var target_company_id: String = _first_non_member_company_id("mscy")
	if target_company_id.is_empty():
		return "Smoke test expected at least one non-member company for MSCY debug inclusion."

	var generator_catalog: Array = GameManager.get_debug_index_review_generator_catalog()
	if generator_catalog.size() != 2:
		return "Smoke test expected debug index-review catalog to expose MSCY and FTSI groups."
	var debug_result: Dictionary = GameManager.debug_generate_index_review("mscy_inclusion", target_company_id)
	if not bool(debug_result.get("success", false)):
		RunState.load_from_dict(saved_state)
		return "Smoke test expected MSCY debug inclusion generation to succeed: %s" % str(debug_result.get("message", ""))

	var has_index_arc: bool = false
	for arc_value in RunState.get_active_company_arcs():
		if typeof(arc_value) == TYPE_DICTIONARY and str(arc_value.get("source_system", "")) == "index_review":
			has_index_arc = true
			break
	if not has_index_arc:
		RunState.load_from_dict(saved_state)
		return "Smoke test expected debug index-review generation to create an active index_review arc."

	var company_index_snapshot: Dictionary = GameManager.get_company_index_review_snapshot(target_company_id)
	if company_index_snapshot.is_empty() or str(company_index_snapshot.get("summary_label", "")).find("MSCY") == -1:
		RunState.load_from_dict(saved_state)
		return "Smoke test expected company index-review badges to show MSCY after debug generation."

	GameManager.simulate_opening_session(false)
	var index_state: Dictionary = RunState.get_index_review_state()
	var mscy_members: Array = index_state.get("providers", {}).get("mscy", {}).get("members", [])
	if not mscy_members.has(target_company_id):
		RunState.load_from_dict(saved_state)
		return "Smoke test expected next-day effective date to apply MSCY inclusion membership."
	var effective_events: Array = RunState.last_day_results.get("index_review_events", [])
	if effective_events.is_empty():
		RunState.load_from_dict(saved_state)
		return "Smoke test expected next-day index-review effective event output."
	var broker_flow: Dictionary = RunState.get_company(target_company_id).get("broker_flow", {})
	if absf(float(broker_flow.get("passive_flow_pressure", 0.0))) <= 0.0:
		RunState.load_from_dict(saved_state)
		return "Smoke test expected index-review passive flow pressure to reach broker flow."

	var news_text: String = _snapshot_visible_text(GameManager.get_news_snapshot())
	var social_text: String = _snapshot_visible_text(GameManager.get_twooter_snapshot())
	if news_text.find("MSCY") == -1:
		RunState.load_from_dict(saved_state)
		return "Smoke test expected News output to include MSCY index-review coverage."
	if social_text.find("MSCY") == -1:
		RunState.load_from_dict(saved_state)
		return "Smoke test expected Twooter output to include MSCY index-review coverage."

	RunState.load_from_dict(saved_state)
	GameManager.get_dashboard_event_snapshot(true)
	return ""


func _first_non_member_company_id(provider_id: String) -> String:
	var index_system = INDEX_REVIEW_SYSTEM_SCRIPT.new()
	index_system.ensure_initialized(RunState, DataRepository)
	var index_state: Dictionary = RunState.get_index_review_state()
	var members: Array = index_state.get("providers", {}).get(provider_id, {}).get("members", [])
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		if not members.has(company_id):
			return company_id
	return ""


func _snapshot_visible_text(snapshot: Dictionary) -> String:
	var parts: Array = []
	for feed_value in snapshot.get("feeds", {}).values():
		if typeof(feed_value) != TYPE_DICTIONARY:
			continue
		var feed: Dictionary = feed_value
		for article_value in feed.get("articles", []):
			if typeof(article_value) != TYPE_DICTIONARY:
				continue
			var article: Dictionary = article_value
			parts.append(str(article.get("headline", "")))
			parts.append(str(article.get("deck", "")))
			parts.append(str(article.get("body", "")))
	for post_value in snapshot.get("posts", []):
		if typeof(post_value) != TYPE_DICTIONARY:
			continue
		var post: Dictionary = post_value
		parts.append(str(post.get("post_text", "")))
		for line_value in post.get("thread_lines", []):
			parts.append(str(line_value))
	return "\n".join(parts)


func _run_scenario(
	run_seed: int,
	difficulty_id: String,
	days_to_advance: int,
	opening_lots: int,
	require_pullback: bool
) -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(difficulty_id)
	var company_definitions: Array = GameManager.build_company_roster(run_seed, difficulty_config)
	RunState.setup_new_run(
		run_seed,
		company_definitions,
		difficulty_config,
		false
	)
	GameManager.simulate_opening_session(false)
	var game_root = load("res://scenes/game/GameRoot.tscn").instantiate()
	add_child(game_root)
	await get_tree().process_frame

	var desktop_layer: Control = game_root.find_child("DesktopLayer", true, false) as Control
	var stock_app_button: Button = game_root.find_child("StockAppButton", true, false) as Button
	var news_app_button: Button = game_root.find_child("NewsAppButton", true, false) as Button
	var social_app_button: Button = game_root.find_child("SocialAppButton", true, false) as Button
	var network_app_button: Button = game_root.find_child("NetworkAppButton", true, false) as Button
	var academy_app_button: Button = game_root.find_child("AcademyAppButton", true, false) as Button
	var academy_app_label: Label = game_root.find_child("AcademyAppLabel", true, false) as Label
	var thesis_app_button: Button = game_root.find_child("ThesisAppButton", true, false) as Button
	var life_app_button: Button = game_root.find_child("LifeAppButton", true, false) as Button
	var upgrades_app_button: Button = game_root.find_child("UpgradesAppButton", true, false) as Button
	var desktop_advance_day_button: Button = game_root.find_child("DesktopAdvanceDayButton", true, false) as Button
	var taskbar_stock_button: Button = game_root.find_child("TaskbarStockButton", true, false) as Button
	var taskbar_news_button: Button = game_root.find_child("TaskbarNewsButton", true, false) as Button
	var news_window: Control = game_root.find_child("NewsWindow", true, false) as Control
	var news_article_list: ItemList = game_root.find_child("NewsArticleList", true, false) as ItemList
	var news_outlet_buttons: HBoxContainer = game_root.find_child("NewsOutletButtons", true, false) as HBoxContainer
	var news_article_cards: VBoxContainer = game_root.find_child("NewsArticleCards", true, false) as VBoxContainer
	var news_detail_byline_label: Label = game_root.find_child("NewsDetailBylineLabel", true, false) as Label
	var news_detail_chips_label: Label = game_root.find_child("NewsDetailChipsLabel", true, false) as Label
	var news_detail_hero_frame: PanelContainer = game_root.find_child("NewsDetailHeroFrame", true, false) as PanelContainer
	var social_window: Control = game_root.find_child("SocialWindow", true, false) as Control
	var social_feed_cards: VBoxContainer = game_root.find_child("SocialFeedCards", true, false) as VBoxContainer
	var network_window: Control = game_root.find_child("NetworkWindow", true, false) as Control
	var network_contacts_list: ItemList = game_root.find_child("NetworkContactsList", true, false) as ItemList
	var network_action_row: HBoxContainer = game_root.find_child("NetworkActionRow", true, false) as HBoxContainer
	var network_requests_list: ItemList = game_root.find_child("NetworkRequestsList", true, false) as ItemList
	var academy_window: Control = game_root.find_child("AcademyWindow", true, false) as Control
	var academy_category_tabs: HBoxContainer = game_root.find_child("AcademyCategoryTabs", true, false) as HBoxContainer
	var academy_section_list: ItemList = game_root.find_child("AcademySectionList", true, false) as ItemList
	var academy_banner_frame: PanelContainer = game_root.find_child("AcademyLessonBannerFrame", true, false) as PanelContainer
	var academy_action_row: HBoxContainer = game_root.find_child("AcademyActionRow", true, false) as HBoxContainer
	var life_window: Control = game_root.find_child("LifeWindow", true, false) as Control
	var upgrade_window: Control = game_root.find_child("UpgradeWindow", true, false) as Control
	var upgrade_cards_vbox: VBoxContainer = game_root.find_child("UpgradeCardsVBox", true, false) as VBoxContainer
	if desktop_layer == null or not desktop_layer.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected GameRoot to open on the new desktop layer before the trading app is launched."
		}

	if stock_app_button == null or news_app_button == null or social_app_button == null or network_app_button == null or academy_app_button == null or thesis_app_button == null or life_app_button == null or upgrades_app_button == null or desktop_advance_day_button == null or taskbar_stock_button == null or taskbar_news_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the prototype desktop icons, Advance Day button, Academy icon, Thesis icon, Life icon, Upgrades icon, and taskbar launch buttons."
		}

	if (
		not game_root.has_method("is_desktop_app_open") or
		not game_root.has_method("get_active_desktop_app_id") or
		not game_root.has_method("get_desktop_app_window_title") or
		not game_root.has_method("close_desktop_app")
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected GameRoot to expose desktop window manager helpers for app-open, active-app, title, and close checks."
		}

	var upgrade_defaults: Dictionary = RunState.get_upgrade_tiers()
	for track_id in RunState.UPGRADE_TRACK_IDS:
		if int(upgrade_defaults.get(str(track_id), 0)) != 4:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected upgrade track %s to start at tier 4." % str(track_id)
			}
	if int(GameManager.get_daily_action_snapshot().get("limit", 0)) != 10:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Daily Action Points to start at 10."
		}

	var opening_report_month: Dictionary = GameManager.get_report_calendar_snapshot(2020, 1)
	var opening_report_rows: Array = opening_report_month.get("reports", [])
	var opening_report_days: Dictionary = opening_report_month.get("reports_by_day", {})
	if opening_report_rows.size() != RunState.company_order.size() or opening_report_days.keys().size() <= 1:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected every generated company to receive a Q1 report date spread across January."
		}

	if not GameManager.has_method("get_dashboard_event_snapshot"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected GameManager to expose the cached dashboard event snapshot."
		}
	var dashboard_event_snapshot: Dictionary = GameManager.get_dashboard_event_snapshot()
	if (
		dashboard_event_snapshot.get("upcoming_report_rows", []).is_empty() or
		dashboard_event_snapshot.get("upcoming_meeting_rows", []).is_empty() or
		dashboard_event_snapshot.get("upcoming_index_review_rows", []).is_empty() or
		dashboard_event_snapshot.get("report_calendar_snapshot", {}).is_empty()
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the cached dashboard event snapshot to include reports, meetings, index reviews, and the current report calendar."
		}

	var opening_index_snapshot: Dictionary = GameManager.get_index_review_snapshot()
	if opening_index_snapshot.get("upcoming_rows", []).is_empty() or opening_index_snapshot.get("providers", []).size() != 2:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the index-review dashboard snapshot to include MSCY and FTSI schedules."
		}
	var opening_company_index_snapshot: Dictionary = GameManager.get_company_index_review_snapshot(str(RunState.company_order[0]))
	if opening_company_index_snapshot.get("rows", []).size() != 2:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected company detail index-review snapshots to expose MSCY/FTSI rows."
		}

	var opening_meeting_snapshot: Dictionary = GameManager.get_corporate_meeting_snapshot()
	var opening_meeting_rows: Array = opening_meeting_snapshot.get("upcoming_rows", [])
	if opening_meeting_rows.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the corporate meeting snapshot to seed at least one upcoming venue."
		}
	var opening_meeting_id: String = str(opening_meeting_rows[0].get("id", ""))
	var opening_meeting_detail: Dictionary = GameManager.get_corporate_meeting_detail(opening_meeting_id)
	if not bool(opening_meeting_detail.get("interactive_v1", false)):
		game_root._open_corporate_meeting_modal(opening_meeting_id)
		await get_tree().process_frame
		var public_meeting_intel_label: Label = game_root.find_child("CorporateMeetingIntelLabel", true, false) as Label
		if (
			public_meeting_intel_label == null or
			public_meeting_intel_label.visible or
			not public_meeting_intel_label.text.is_empty()
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected public corporate meeting modals to hide private intel/debug chain state."
			}
		game_root._close_corporate_meeting_modal()
		await get_tree().process_frame
	if bool(opening_meeting_detail.get("requires_shareholder", false)):
		var blocked_attend_result: Dictionary = GameManager.attend_corporate_meeting(opening_meeting_id)
		if bool(blocked_attend_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected shareholder-only RUPS/RUPSLB attendance to reject zero-position players."
			}
		var meeting_company_id: String = str(opening_meeting_detail.get("company_id", ""))
		var meeting_buy_result: Dictionary = GameManager.buy_lots(meeting_company_id, 1)
		if not bool(meeting_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before attending a shareholder-only meeting."
			}
	var attend_meeting_result: Dictionary = GameManager.attend_corporate_meeting(opening_meeting_id)
	if not bool(attend_meeting_result.get("success", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected eligible corporate meeting attendance to be markable in v1."
		}
	var saved_meeting_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(saved_meeting_state)
	if not bool(RunState.get_attended_meetings().get(opening_meeting_id, {}).get("attended", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected attended corporate meetings to persist through save/load."
		}

	if difficulty_id == GameManager.DEFAULT_DIFFICULTY_ID:
		var interactive_test_base_state: Dictionary = RunState.to_save_dict()
		if (
			not GameManager.has_method("debug_force_rights_issue_rupslb") or
			not GameManager.has_method("get_debug_corporate_action_generator_catalog") or
			not GameManager.has_method("debug_generate_corporate_action") or
			not GameManager.has_method("debug_schedule_next_day_rights_issue_rupslb") or
			not GameManager.has_method("debug_schedule_next_day_stock_buyback_rupslb") or
			not GameManager.has_method("debug_schedule_next_day_stock_split_rupslb") or
			not GameManager.has_method("debug_schedule_next_day_tender_offer_rupslb") or
			not GameManager.has_method("debug_schedule_next_day_strategic_mna_rupslb") or
			not GameManager.has_method("debug_schedule_next_day_backdoor_listing_rupslb") or
			not GameManager.has_method("debug_schedule_next_day_restructuring_rupslb") or
			not GameManager.has_method("debug_schedule_next_day_ceo_change_rupslb") or
			not GameManager.has_method("get_stock_contact_tip_options") or
			not GameManager.has_method("ask_stock_contact_tip") or
			not GameManager.has_method("get_governance_control_options") or
			not GameManager.has_method("get_company_management_snapshot") or
			not GameManager.has_method("request_governance_control_action") or
			not GameManager.has_method("debug_force_stock_buyback_execution") or
			not GameManager.has_method("debug_force_stock_split_execution") or
			not GameManager.has_method("debug_force_tender_offer_execution") or
			not GameManager.has_method("debug_force_strategic_mna_execution") or
			not GameManager.has_method("debug_force_backdoor_listing_execution") or
			not GameManager.has_method("debug_force_restructuring_execution") or
			not GameManager.has_method("debug_force_ceo_change_execution") or
			not GameManager.has_method("get_debug_index_review_generator_catalog") or
			not GameManager.has_method("debug_generate_index_review") or
			not GameManager.has_method("start_corporate_meeting_session") or
			not GameManager.has_method("get_corporate_meeting_session_snapshot") or
			not GameManager.has_method("set_corporate_meeting_session_stage") or
			not GameManager.has_method("submit_corporate_meeting_vote") or
			not GameManager.has_method("close_corporate_meeting_session") or
			not game_root.has_method("is_rupslb_meeting_overlay_visible") or
			not game_root.has_method("get_rupslb_meeting_stage_id")
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the interactive RUPSLB session helpers to be exposed through GameManager and GameRoot."
			}

		var index_review_runtime_validation: String = _validate_index_review_runtime_flow()
		if not index_review_runtime_validation.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": index_review_runtime_validation
			}

		var rupslb_candidate_ids: Array = []
		for company_index in range(RunState.company_order.size() - 1, -1, -1):
			var candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(candidate_company_id).get("has_live_chain", false)):
				continue
			if int(RunState.get_holding(candidate_company_id).get("shares", 0)) > 0:
				continue
			rupslb_candidate_ids.append(candidate_company_id)
			if rupslb_candidate_ids.size() >= 2:
				break
		if rupslb_candidate_ids.size() < 2:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find at least two companies without live corporate-action chains for deterministic RUPSLB coverage."
			}

		var blocked_company_id: String = str(rupslb_candidate_ids[0])
		var eligible_company_id: String = str(rupslb_candidate_ids[1])

		var contact_intel_panel: Control = game_root.find_child("ContactIntelPanel", true, false) as Control
		var contact_intel_option: OptionButton = game_root.find_child("ContactIntelOption", true, false) as OptionButton
		var contact_intel_button: Button = game_root.find_child("ContactIntelButton", true, false) as Button
		var company_app_button: Button = game_root.find_child("CompanyAppButton", true, false) as Button
		var company_window: Control = game_root.find_child("CompanyWindow", true, false) as Control
		var company_controlled_option: OptionButton = game_root.find_child("CompanyControlledOption", true, false) as OptionButton
		var company_agenda_option: OptionButton = game_root.find_child("CompanyAgendaOption", true, false) as OptionButton
		var company_request_button: Button = game_root.find_child("CompanyRequestButton", true, false) as Button
		var company_status_label: Label = game_root.find_child("CompanyStatusLabel", true, false) as Label
		if contact_intel_panel != null or contact_intel_option != null or contact_intel_button != null:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected STOCKBOT order ticket Contact Intel controls to stay hidden."
			}
		if (
			company_app_button == null or
			company_window == null or
			company_controlled_option == null or
			company_agenda_option == null or
			company_request_button == null or
			company_status_label == null
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the dedicated Company app controls to exist."
			}

		game_root.selected_company_id = blocked_company_id
		game_root._refresh_trade_workspace()
		game_root._refresh_desktop()
		await get_tree().process_frame
		var locked_governance_options: Dictionary = GameManager.get_governance_control_options(blocked_company_id)
		var locked_governance_result: Dictionary = GameManager.request_governance_control_action(blocked_company_id, "stock_split")
		var locked_company_management: Dictionary = GameManager.get_company_management_snapshot(blocked_company_id)
		if (
			bool(locked_governance_options.get("enabled", false)) or
			bool(locked_governance_result.get("success", false)) or
			bool(locked_company_management.get("unlocked", false)) or
			not company_app_button.disabled
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the Company app to stay locked below majority ownership."
			}
		var locked_company_icon_style: StyleBoxFlat = company_app_button.get_theme_stylebox("disabled") as StyleBoxFlat
		var locked_company_icon_color: Color = company_app_button.get_theme_color("icon_disabled_color")
		if (
			locked_company_icon_style == null or
			locked_company_icon_style.bg_color.r < 0.82 or
			locked_company_icon_style.bg_color.b > 0.76 or
			locked_company_icon_color.a > 0.6 or
			not _color_close(Color(locked_company_icon_color.r, locked_company_icon_color.g, locked_company_icon_color.b, 1), UiTheme.color("desktop.brown"))
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the locked Company desktop shortcut to use muted warm desktop disabled colors."
			}
		if game_root.find_child("GovernanceControlButton", true, false) != null:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected company-direction agenda controls to be removed from STOCKBOT."
			}

		var governance_snapshot: Dictionary = GameManager.get_company_snapshot(blocked_company_id, false, false, false)
		var governance_shares_outstanding: float = float(governance_snapshot.get("shares_outstanding", 0.0))
		var governance_required_shares: int = int(floor(governance_shares_outstanding * 0.50)) + RunState.LOT_SIZE
		governance_required_shares = int(ceil(float(governance_required_shares) / float(RunState.LOT_SIZE))) * RunState.LOT_SIZE
		if governance_shares_outstanding <= 0.0 or governance_required_shares <= 0:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Governance Control target to expose shares outstanding."
			}
		RunState.player_portfolio["cash"] = max(
			float(RunState.player_portfolio.get("cash", 0.0)),
			float(governance_snapshot.get("current_price", 1.0)) * float(governance_required_shares) * 20.0
		)
		var governance_buy_result: Dictionary = RunState.buy_company(blocked_company_id, governance_required_shares)
		game_root._refresh_trade_workspace()
		game_root._refresh_desktop()
		await get_tree().process_frame
		var unlocked_governance_options: Dictionary = GameManager.get_governance_control_options(blocked_company_id)
		var unlocked_company_management: Dictionary = GameManager.get_company_management_snapshot(blocked_company_id)
		if (
			not bool(governance_buy_result.get("success", false)) or
			not bool(unlocked_governance_options.get("enabled", false)) or
			not bool(unlocked_company_management.get("unlocked", false)) or
			company_app_button.disabled or
			unlocked_governance_options.get("rows", []).size() < 8
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the Company app to unlock after majority ownership."
			}
		company_app_button.emit_signal("pressed")
		await get_tree().process_frame
		if (
			not company_window.visible or
			not game_root.is_desktop_app_open("company") or
			game_root.get_desktop_app_window_title("company") != "Company" or
			not _desktop_window_has_settings_brown_chrome(game_root, "CompanyDesktopWindow") or
			company_controlled_option.get_item_count() <= 0 or
			company_request_button.disabled
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the unlocked Company app to open with a brown frame and controllable company agenda controls."
			}

		var governance_action_index: int = -1
		for option_index in range(company_agenda_option.get_item_count()):
			if str(company_agenda_option.get_item_metadata(option_index)) == "stock_split":
				governance_action_index = option_index
				break
		if governance_action_index < 0:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Company to list stock split as a controllable agenda."
			}
		company_agenda_option.select(governance_action_index)
		company_request_button.emit_signal("pressed")
		await get_tree().process_frame
		var governance_chain_snapshot: Dictionary = GameManager.get_company_corporate_action_snapshot(blocked_company_id)
		var governance_primary_chain: Dictionary = governance_chain_snapshot.get("primary_chain", {})
		var governance_meeting_id: String = str(governance_primary_chain.get("active_meeting_id", ""))
		if governance_meeting_id.is_empty():
			for date_key_value in RunState.corporate_meeting_calendar.keys():
				for meeting_value in RunState.corporate_meeting_calendar.get(str(date_key_value), []):
					if typeof(meeting_value) != TYPE_DICTIONARY:
						continue
					var meeting_row: Dictionary = meeting_value
					if str(meeting_row.get("company_id", "")) == blocked_company_id and str(meeting_row.get("chain_family", "")) == "stock_split":
						governance_meeting_id = str(meeting_row.get("id", ""))
						break
				if not governance_meeting_id.is_empty():
					break
		var governance_meeting_detail: Dictionary = GameManager.get_corporate_meeting_detail(governance_meeting_id)
		if (
			not bool(governance_chain_snapshot.get("has_live_chain", false)) or
			str(governance_primary_chain.get("family", "")) != "stock_split" or
			str(governance_primary_chain.get("request_source", "")) != "player_control" or
			str(governance_meeting_detail.get("request_source", "")) != "player_control"
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Company to schedule a player-control stock split RUPSLB."
			}
		RunState.load_from_dict(interactive_test_base_state)
		game_root.close_desktop_app("company")
		game_root._refresh_all()
		await get_tree().process_frame

		var forced_blocked_result: Dictionary = GameManager.debug_force_rights_issue_rupslb(blocked_company_id)
		if not bool(forced_blocked_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug helper to force a same-day zero-position RUPSLB meeting."
			}
		var blocked_meeting_id: String = str(forced_blocked_result.get("meeting", {}).get("id", ""))
		var blocked_detail: Dictionary = GameManager.get_corporate_meeting_detail(blocked_meeting_id)
		if (
			not bool(blocked_detail.get("requires_shareholder", false)) or
			bool(blocked_detail.get("attendance_eligible", true))
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected forced zero-position RUPSLB detail to be shareholder-gated."
			}
		var blocked_attend_result: Dictionary = GameManager.attend_corporate_meeting(blocked_meeting_id)
		if bool(blocked_attend_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected zero-position RUPSLB attendance to be rejected."
			}
		var blocked_start_result: Dictionary = GameManager.start_corporate_meeting_session(blocked_meeting_id)
		if bool(blocked_start_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected zero-position RUPSLB sessions to stay closed without shareholder ownership."
			}
		game_root._open_corporate_meeting_modal(blocked_meeting_id)
		await get_tree().process_frame
		if game_root.is_rupslb_meeting_overlay_visible():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the UI to block zero-position RUPSLB overlay entry."
			}

		var eligible_buy_result: Dictionary = GameManager.buy_lots(eligible_company_id, 1)
		if not bool(eligible_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before the forced shareholder RUPSLB flow."
			}
		var forced_eligible_result: Dictionary = GameManager.debug_force_rights_issue_rupslb(eligible_company_id)
		if not bool(forced_eligible_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug helper to force a same-day shareholder RUPSLB meeting."
			}
		var eligible_chain_id: String = str(forced_eligible_result.get("chain", {}).get("chain_id", ""))
		var eligible_meeting_id: String = str(forced_eligible_result.get("meeting", {}).get("id", ""))
		game_root._open_corporate_meeting_modal(eligible_meeting_id)
		await get_tree().process_frame
		var rupslb_overlay: Control = game_root.find_child("RupslbMeetingOverlay", true, false) as Control
		var rupslb_continue_button: Button = game_root.find_child("RupslbContinueButton", true, false) as Button
		var rupslb_agree_button: Button = game_root.find_child("RupslbAgreeButton", true, false) as Button
		var rupslb_close_button: Button = game_root.find_child("RupslbCloseButton", true, false) as Button
		var rupslb_result_label: Label = game_root.find_child("RupslbResultLabel", true, false) as Label
		if (
			rupslb_overlay == null or
			rupslb_continue_button == null or
			rupslb_agree_button == null or
			rupslb_close_button == null or
			rupslb_result_label == null or
			not rupslb_overlay.visible or
			not game_root.is_rupslb_meeting_overlay_visible() or
			game_root.get_rupslb_meeting_stage_id() != "arrival"
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected opening an interactive RUPSLB meeting to enter the dedicated fullscreen overlay at the Arrival stage."
			}

		var opening_session_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(eligible_meeting_id)
		var opening_leads: Array = opening_session_snapshot.get("meeting_leads", [])
		var opening_recognition_score: int = int(GameManager.get_network_snapshot().get("recognition", {}).get("score", 0))
		if opening_leads.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected interactive RUPSLB sessions to generate meeting leads."
			}
		var found_approachable_lead: bool = false
		var found_locked_recognition_lead: bool = false
		for lead_value in opening_leads:
			if typeof(lead_value) != TYPE_DICTIONARY:
				continue
			var lead: Dictionary = lead_value
			if _network_contact_affiliation_type(str(lead.get("contact_id", ""))) != "floater":
				game_root.queue_free()
				await get_tree().process_frame
				return {
					"success": false,
					"message": "Smoke test expected RUPSLB meeting leads to exclude inner-circle insider contacts."
				}
			if bool(lead.get("approachable", false)):
				found_approachable_lead = true
			if int(lead.get("recognition_required", 0)) > opening_recognition_score and not bool(lead.get("approachable", false)):
				found_locked_recognition_lead = true
		if not found_approachable_lead or not found_locked_recognition_lead:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected RUPSLB room leads to include both an approachable attendee and a higher-recognition locked attendee."
			}

		var approached_lead_id: String = ""
		var approached_contact_id: String = ""
		var approachable_lead_index: int = -1
		for lead_index in range(opening_leads.size()):
			if typeof(opening_leads[lead_index]) == TYPE_DICTIONARY and bool(opening_leads[lead_index].get("approachable", false)):
				approachable_lead_index = lead_index
				break
		var meeting_lead_ap_before: int = 0
		var seating_bubble_text: String = ""
		for expected_stage_id in ["seating", "host_intro", "agenda_reveal", "vote"]:
			rupslb_continue_button.emit_signal("pressed")
			await get_tree().process_frame
			if game_root.get_rupslb_meeting_stage_id() != expected_stage_id:
				game_root.queue_free()
				await get_tree().process_frame
				return {
					"success": false,
					"message": "Smoke test expected the interactive RUPSLB flow to progress through %s in order." % expected_stage_id
				}
			if expected_stage_id == "seating":
				var lead_marker_row: int = int(approachable_lead_index / 5)
				var lead_marker_column: int = approachable_lead_index % 5
				var lead_marker: Button = game_root.find_child("RupslbAttendeeMarker_%d_%d" % [lead_marker_row, lead_marker_column], true, false) as Button
				var lead_bubble: PanelContainer = game_root.find_child("RupslbLeadBubble_%d_%d" % [lead_marker_row, lead_marker_column], true, false) as PanelContainer
				var lead_bubble_layer: Control = game_root.find_child("RupslbBubbleLayer", true, false) as Control
				if lead_marker == null or lead_bubble == null or lead_bubble_layer == null or lead_bubble.get_parent() != lead_bubble_layer or not lead_bubble.visible:
					game_root.queue_free()
					await get_tree().process_frame
					return {
						"success": false,
						"message": "Smoke test expected RUPSLB meeting leads to render clickable attendee markers and top-layer speech bubbles at Seating."
					}
				lead_marker.emit_signal("pressed")
				await get_tree().process_frame
				var lead_card: PanelContainer = game_root.find_child("RupslbLeadCard", true, false) as PanelContainer
				var lead_title_label: Label = game_root.find_child("RupslbLeadTitleLabel", true, false) as Label
				var lead_approach_button: Button = game_root.find_child("RupslbLeadApproachButton", true, false) as Button
				if lead_card == null or lead_title_label == null or lead_approach_button == null or not lead_card.visible or lead_title_label.text.is_empty():
					game_root.queue_free()
					await get_tree().process_frame
					return {
						"success": false,
						"message": "Smoke test expected clicking a RUPSLB attendee to populate the meeting lead detail card."
					}
				meeting_lead_ap_before = int(GameManager.get_daily_action_snapshot().get("used", 0))
				var seating_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(eligible_meeting_id)
				var seating_leads: Array = seating_snapshot.get("meeting_leads", [])
				if approachable_lead_index < 0 or approachable_lead_index >= seating_leads.size() or typeof(seating_leads[approachable_lead_index]) != TYPE_DICTIONARY:
					game_root.queue_free()
					await get_tree().process_frame
					return {
						"success": false,
						"message": "Smoke test expected the selected approachable RUPSLB lead to be available in the session snapshot."
				}
				var first_lead: Dictionary = seating_leads[approachable_lead_index]
				seating_bubble_text = str(first_lead.get("speech_bubble", ""))
				approached_lead_id = str(first_lead.get("lead_id", ""))
				approached_contact_id = str(first_lead.get("contact_id", ""))
				for lead_value in seating_leads:
					if typeof(lead_value) != TYPE_DICTIONARY:
						continue
					var lead: Dictionary = lead_value
					for text_key in ["speech_bubble", "approach_prompt", "locked_reason"]:
						if _contains_unresolved_template_token(str(lead.get(text_key, ""))):
							game_root.queue_free()
							await get_tree().process_frame
							return {
								"success": false,
								"message": "Smoke test expected RUPSLB meeting lead %s to format %s without raw template placeholders." % [
									str(lead.get("profile_id", "")),
									str(text_key)
								]
							}
				if lead_approach_button.disabled:
					game_root.queue_free()
					await get_tree().process_frame
					return {
						"success": false,
						"message": "Smoke test expected the first RUPSLB room lead to be approachable on a fresh normal run."
					}
				lead_approach_button.emit_signal("pressed")
				await get_tree().process_frame
				var post_approach_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(eligible_meeting_id)
				if not _has_approached_meeting_lead(post_approach_snapshot, approached_lead_id):
					game_root.queue_free()
					await get_tree().process_frame
					return {
						"success": false,
						"message": "Smoke test expected approaching a RUPSLB room lead to persist the meeting lead result."
					}
				if int(GameManager.get_daily_action_snapshot().get("used", 0)) != meeting_lead_ap_before + GameManager.get_network_action_cost("meet"):
					game_root.queue_free()
					await get_tree().process_frame
					return {
						"success": false,
						"message": "Smoke test expected approaching a RUPSLB room lead to spend the Network meet AP cost."
					}
				if not _has_met_network_contact(GameManager.get_network_snapshot(), approached_contact_id):
					game_root.queue_free()
					await get_tree().process_frame
					return {
						"success": false,
						"message": "Smoke test expected approaching a RUPSLB room lead to meet the contact."
					}
				var discovery: Dictionary = RunState.get_network_discoveries().get(approached_contact_id, {})
				if str(discovery.get("source_type", "")) != "meeting_lead":
					game_root.queue_free()
					await get_tree().process_frame
					return {
						"success": false,
						"message": "Smoke test expected approached RUPSLB contacts to persist a meeting_lead discovery source."
					}
				var duplicate_approach_result: Dictionary = GameManager.approach_corporate_meeting_lead(eligible_meeting_id, approached_lead_id)
				if bool(duplicate_approach_result.get("success", false)) or int(GameManager.get_daily_action_snapshot().get("used", 0)) != meeting_lead_ap_before + GameManager.get_network_action_cost("meet"):
					game_root.queue_free()
					await get_tree().process_frame
					return {
						"success": false,
						"message": "Smoke test expected repeated RUPSLB lead approaches to fail without spending more AP."
					}
			elif expected_stage_id == "host_intro":
				var host_intro_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(eligible_meeting_id)
				var host_intro_leads: Array = host_intro_snapshot.get("meeting_leads", [])
				if approachable_lead_index < 0 or approachable_lead_index >= host_intro_leads.size() or typeof(host_intro_leads[approachable_lead_index]) != TYPE_DICTIONARY:
					game_root.queue_free()
					await get_tree().process_frame
					return {
						"success": false,
						"message": "Smoke test expected RUPSLB meeting leads to stay available after the host intro stage."
					}
				var host_intro_lead: Dictionary = host_intro_leads[approachable_lead_index]
				if str(host_intro_lead.get("speech_bubble_stage_id", "")) != "host_intro" or str(host_intro_lead.get("speech_bubble", "")) == seating_bubble_text:
					game_root.queue_free()
					await get_tree().process_frame
					return {
						"success": false,
						"message": "Smoke test expected RUPSLB lead speech bubbles to change when the meeting advances stages."
					}
				if _contains_unresolved_template_token(str(host_intro_lead.get("speech_bubble", ""))):
					game_root.queue_free()
					await get_tree().process_frame
					return {
						"success": false,
						"message": "Smoke test expected host-intro RUPSLB lead speech bubbles to format meeting placeholders."
					}

		if not rupslb_agree_button.visible:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected shareholder-eligible RUPSLB sessions to expose agree/disagree voting buttons."
			}

		rupslb_agree_button.emit_signal("pressed")
		await get_tree().process_frame
		if (
			game_root.get_rupslb_meeting_stage_id() != "result" or
			rupslb_result_label.text.is_empty()
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected casting a RUPSLB vote to move the meeting into the result board stage."
			}

		rupslb_close_button.emit_signal("pressed")
		await get_tree().process_frame
		if game_root.is_rupslb_meeting_overlay_visible():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected closing the interactive RUPSLB overlay to hide the fullscreen meeting experience."
			}

		var saved_rupslb_state: Dictionary = RunState.to_save_dict()
		RunState.load_from_dict(saved_rupslb_state)
		var resumed_session_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(eligible_meeting_id)
		if (
			resumed_session_snapshot.is_empty() or
			str(resumed_session_snapshot.get("current_stage_id", "")) != "result" or
			resumed_session_snapshot.get("result_summary", {}).is_empty()
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected interactive RUPSLB meeting sessions to persist their stage and result through save/load."
			}
		if approached_lead_id.is_empty() or not _has_approached_meeting_lead(resumed_session_snapshot, approached_lead_id):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected RUPSLB room lead results to persist through save/load."
			}

		game_root._open_corporate_meeting_modal(eligible_meeting_id)
		await get_tree().process_frame
		if not game_root.is_rupslb_meeting_overlay_visible() or game_root.get_rupslb_meeting_stage_id() != "result":
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected reopening a saved RUPSLB session to resume on the persisted result board stage."
			}

		rupslb_close_button = game_root.find_child("RupslbCloseButton", true, false) as Button
		if rupslb_close_button != null:
			rupslb_close_button.emit_signal("pressed")
			await get_tree().process_frame

		var chain_before_resolution: Dictionary = RunState.get_active_corporate_action_chains().get(eligible_chain_id, {}).duplicate(true)
		if str(chain_before_resolution.get("stage", "")) != "meeting_or_call":
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the forced rights issue chain to stay in meeting_or_call until the next simulated day."
			}

		GameManager.advance_day()
		await get_tree().process_frame
		if SaveManager.has_pending_save():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected direct GameManager.advance_day() to flush immediately."
			}
		var chain_after_resolution: Dictionary = RunState.get_active_corporate_action_chains().get(eligible_chain_id, {}).duplicate(true)
		if (
			str(chain_after_resolution.get("stage", "")) == "meeting_or_call" or
			not bool(RunState.get_corporate_meeting_sessions().get(eligible_meeting_id, {}).get("consumed", false))
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the next simulation day to consume the saved RUPSLB vote result and move the chain past meeting_or_call."
			}

		var rights_before_definition: Dictionary = RunState.get_effective_company_definition(eligible_company_id, false, false)
		var rights_before_financials: Dictionary = rights_before_definition.get("financials", {})
		var rights_shares_before: float = float(rights_before_financials.get("shares_outstanding", rights_before_definition.get("shares_outstanding", 0.0)))
		var rights_holding_before: int = int(RunState.get_holding(eligible_company_id).get("shares", 0))
		var rights_cash_before: float = float(RunState.player_portfolio.get("cash", 0.0))
		if rights_shares_before <= 0.0 or rights_holding_before <= 0:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected rights issue target shares outstanding and player holdings before execution."
			}

		GameManager.advance_day()
		await get_tree().process_frame
		var rights_application: Dictionary = {}
		for rights_application_value in RunState.last_day_results.get("corporate_action_applications", []):
			if typeof(rights_application_value) != TYPE_DICTIONARY:
				continue
			var rights_candidate_application: Dictionary = rights_application_value
			if str(rights_candidate_application.get("chain_id", "")) == eligible_chain_id and str(rights_candidate_application.get("application_type", "")) == "rights_issue":
				rights_application = rights_candidate_application.duplicate(true)
				break
		if rights_application.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected approved rights issue execution to emit an application payload."
			}
		var rights_after_definition: Dictionary = RunState.get_effective_company_definition(eligible_company_id, false, false)
		var rights_after_financials: Dictionary = rights_after_definition.get("financials", {})
		var rights_shares_after: float = float(rights_after_financials.get("shares_outstanding", rights_after_definition.get("shares_outstanding", 0.0)))
		if rights_shares_after <= rights_shares_before:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected rights issue execution to increase company shares outstanding."
			}
		var rights_adjustment: Dictionary = {}
		for rights_adjustment_value in RunState.get_company(eligible_company_id).get("company_profile", {}).get("corporate_action_adjustments", []):
			if typeof(rights_adjustment_value) == TYPE_DICTIONARY and str(rights_adjustment_value.get("type", "")) == "rights_issue":
				rights_adjustment = rights_adjustment_value.duplicate(true)
				break
		if rights_adjustment.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected rights issue execution to record a company share-structure adjustment."
			}
		var rights_entitled_shares: int = int(rights_application.get("player_entitled_shares", 0))
		var rights_exercise_cost: float = float(rights_entitled_shares) * float(rights_application.get("exercise_price", 0.0))
		var rights_holding_after: int = int(RunState.get_holding(eligible_company_id).get("shares", 0))
		var rights_trade_side: String = ""
		for rights_trade_index in range(RunState.trade_history.size() - 1, -1, -1):
			var rights_trade: Dictionary = RunState.trade_history[rights_trade_index]
			if str(rights_trade.get("company_id", "")) == eligible_company_id and str(rights_trade.get("side", "")).begins_with("rights_issue"):
				rights_trade_side = str(rights_trade.get("side", ""))
				break
		if rights_entitled_shares <= 0:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected one record-date lot to produce a positive rights entitlement."
			}
		if rights_exercise_cost <= rights_cash_before + 0.0001:
			if (
				rights_holding_after < rights_holding_before + rights_entitled_shares or
				rights_trade_side != "rights_issue_exercise" or
				str(rights_adjustment.get("player_rights_status", "")) != "exercised"
			):
				game_root.queue_free()
				await get_tree().process_frame
				return {
					"success": false,
					"message": "Smoke test expected affordable rights entitlements to auto-exercise into player holdings."
				}
		else:
			if (
				rights_holding_after != rights_holding_before or
				rights_trade_side != "rights_issue_lapsed" or
				str(rights_adjustment.get("player_rights_status", "")) != "lapsed_insufficient_cash"
			):
				game_root.queue_free()
				await get_tree().process_frame
				return {
					"success": false,
					"message": "Smoke test expected unaffordable rights entitlements to lapse without adding shares."
				}

		RunState.load_from_dict(interactive_test_base_state)
		game_root._refresh_all()
		await get_tree().process_frame

		var debug_schedule_candidate_ids: Array = []
		for company_index in range(RunState.company_order.size() - 1, -1, -1):
			var debug_candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(debug_candidate_company_id).get("has_live_chain", false)):
				continue
			debug_schedule_candidate_ids.append(debug_candidate_company_id)
			if debug_schedule_candidate_ids.size() >= 2:
				break
		if debug_schedule_candidate_ids.size() < 2:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find at least two chain-free companies for the debug-scheduled next-day RUPSLB flow."
			}

		var debug_non_owned_company_id: String = str(debug_schedule_candidate_ids[0])
		var debug_target_company_id: String = str(debug_schedule_candidate_ids[1])
		var debug_toggle_event: InputEventKey = InputEventKey.new()
		debug_toggle_event.pressed = true
		debug_toggle_event.ctrl_pressed = true
		debug_toggle_event.keycode = KEY_L
		game_root._unhandled_input(debug_toggle_event)
		await get_tree().process_frame

		var debug_overlay: Control = game_root.find_child("DebugOverlay", true, false) as Control
		var debug_start_rupslb_button: Button = game_root.find_child("DebugStartRupslbButton", true, false) as Button
		var debug_cash_dividend_button: Button = game_root.find_child("DebugCorporateActionButtonCashDividend", true, false) as Button
		var debug_stock_split_button: Button = game_root.find_child("DebugCorporateActionButtonStockSplitRupslb", true, false) as Button
		var debug_mscy_inclusion_button: Button = game_root.find_child("DebugIndexReviewButtonMscyInclusion", true, false) as Button
		var debug_ftsi_exclusion_button: Button = game_root.find_child("DebugIndexReviewButtonFtsiExclusion", true, false) as Button
		var debug_start_rupslb_status_label: Label = game_root.find_child("DebugStartRupslbStatusLabel", true, false) as Label
		var debug_index_review_status_label: Label = game_root.find_child("DebugIndexReviewStatusLabel", true, false) as Label
		if (
			debug_overlay == null or
			not debug_overlay.visible or
			debug_start_rupslb_button == null or
			debug_cash_dividend_button == null or
			debug_stock_split_button == null or
			debug_mscy_inclusion_button == null or
			debug_ftsi_exclusion_button == null or
			debug_start_rupslb_status_label == null or
			debug_index_review_status_label == null
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug overlay to expose selected-stock corporate-action and index-review generator controls."
			}

		game_root.selected_company_id = ""
		game_root._refresh_debug_overlay()
		await get_tree().process_frame
		if (
			not debug_start_rupslb_button.disabled or
			debug_start_rupslb_status_label.text.find("Pick a stock first.") == -1
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug Start RUPSLB control to stay disabled until a stock is selected."
			}
		if (
			not debug_mscy_inclusion_button.disabled or
			debug_index_review_status_label.text.find("Pick a stock first.") == -1
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected index-review debug generators to stay disabled until a stock is selected."
			}

		game_root._on_all_stock_selected(debug_non_owned_company_id)
		await get_tree().process_frame
		if (
			not debug_start_rupslb_button.disabled or
			debug_start_rupslb_status_label.text.find("Own at least 1 lot first.") == -1
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug Start RUPSLB control to require at least one owned lot."
			}
		if debug_cash_dividend_button.disabled:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected non-RUPSLB debug corporate-action generators to work for a selected stock without a held lot."
			}
		if (
			debug_mscy_inclusion_button.disabled or
			debug_ftsi_exclusion_button.disabled or
			debug_index_review_status_label.text.find("Buttons force MSCY/FTSI") == -1
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug index-review generators to enable for any selected stock."
			}

		var debug_target_buy_result: Dictionary = GameManager.buy_lots(debug_target_company_id, 1)
		if not bool(debug_target_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before using the debug-scheduled next-day RUPSLB action."
			}

		game_root._on_all_stock_selected(debug_target_company_id)
		await get_tree().process_frame
		if debug_start_rupslb_button.disabled:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug Start RUPSLB control to enable for the selected held stock."
			}

		var debug_target_ticker: String = str(GameManager.get_company_snapshot(debug_target_company_id, false, false, false).get("ticker", ""))
		debug_start_rupslb_button.emit_signal("pressed")
		await get_tree().process_frame
		if game_root.is_rupslb_meeting_overlay_visible():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected scheduling a next-day debug RUPSLB not to auto-open the fullscreen meeting overlay immediately."
			}

		var debug_chain_snapshot: Dictionary = GameManager.get_company_corporate_action_snapshot(debug_target_company_id)
		var debug_primary_chain: Dictionary = debug_chain_snapshot.get("primary_chain", {})
		var debug_chain_id: String = str(debug_primary_chain.get("chain_id", ""))
		if debug_chain_id.is_empty() or str(debug_primary_chain.get("family", "")) != "rights_issue":
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug Start RUPSLB action to create a rights issue chain for the selected stock."
			}

		var queued_meeting: Dictionary = {}
		for date_key_value in RunState.get_corporate_meeting_calendar().keys():
			var queued_meetings: Array = RunState.get_corporate_meeting_calendar().get(str(date_key_value), [])
			for meeting_value in queued_meetings:
				var meeting: Dictionary = meeting_value
				if str(meeting.get("source_chain_id", "")) == debug_chain_id:
					queued_meeting = meeting.duplicate(true)
					break
			if not queued_meeting.is_empty():
				break
		var queued_meeting_id: String = str(queued_meeting.get("id", ""))
		if (
			queued_meeting.is_empty() or
			str(queued_meeting.get("status", "")) != "queued"
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug Start RUPSLB action to create a hidden queued meeting for the next trade day."
			}

		for row_value in GameManager.get_corporate_meeting_snapshot().get("upcoming_rows", []):
			var row: Dictionary = row_value
			if str(row.get("id", "")) == queued_meeting_id:
				game_root.queue_free()
				await get_tree().process_frame
				return {
					"success": false,
					"message": "Smoke test expected the queued debug RUPSLB meeting to stay hidden from today's upcoming meeting snapshot."
				}

		if (
			not debug_start_rupslb_button.disabled or
			debug_start_rupslb_status_label.text.find("already has a live corporate action") == -1
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug Start RUPSLB control to disable again once the selected company has a live chain."
			}

		if int(queued_meeting.get("record_shares_owned", -1)) < GameManager.get_lot_size():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected debug RUPSLB scheduling to capture the player's shares on the shareholder record date."
			}
		var debug_target_sell_result: Dictionary = GameManager.sell_lots(debug_target_company_id, 1)
		if (
			not bool(debug_target_sell_result.get("success", false)) or
			int(RunState.get_holding(debug_target_company_id).get("shares", 0)) > 0
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to sell the debug RUPSLB holding after record-date capture."
			}

		GameManager.advance_day()
		await get_tree().process_frame

		var queued_meeting_visible_next_day: bool = false
		for row_value in GameManager.get_corporate_meeting_snapshot().get("upcoming_rows", []):
			var row: Dictionary = row_value
			if str(row.get("id", "")) == queued_meeting_id:
				queued_meeting_visible_next_day = true
				break
		if not queued_meeting_visible_next_day:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the queued debug RUPSLB meeting to appear in the upcoming meeting snapshot after one Advance Day."
			}

		var queued_record_detail: Dictionary = GameManager.get_corporate_meeting_detail(queued_meeting_id)
		if (
			not bool(queued_record_detail.get("attendance_eligible", false)) or
			int(queued_record_detail.get("player_shares_owned", 0)) < GameManager.get_lot_size() or
			int(queued_record_detail.get("current_shares_owned", 0)) != 0 or
			not bool(queued_record_detail.get("shareholder_recorded", false))
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected record-date RUPSLB eligibility to survive selling the shares before the meeting opens."
			}

		game_root._refresh_dashboard()
		await get_tree().process_frame
		var dashboard_calendar_grid: GridContainer = game_root.find_child("CalendarDaysGrid", true, false) as GridContainer
		var scheduled_dashboard_day_cell: Control = null
		if dashboard_calendar_grid != null:
			for child in dashboard_calendar_grid.get_children():
				var day_cell: Control = child as Control
				if day_cell == null:
					continue
				var meeting_ids: Array = day_cell.get_meta("meeting_ids", [])
				if meeting_ids.has(queued_meeting_id):
					scheduled_dashboard_day_cell = day_cell
					break
		if scheduled_dashboard_day_cell == null:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the queued debug RUPSLB meeting to surface on a clickable Dashboard calendar day."
			}

		var scheduled_calendar_click := InputEventMouseButton.new()
		scheduled_calendar_click.button_index = MOUSE_BUTTON_LEFT
		scheduled_calendar_click.pressed = true
		scheduled_calendar_click.position = scheduled_dashboard_day_cell.get_global_rect().get_center()
		scheduled_dashboard_day_cell.emit_signal("gui_input", scheduled_calendar_click)
		await get_tree().process_frame
		var scheduled_dashboard_button: Button = game_root.find_child("DashboardCalendarMeetingButton_%s" % queued_meeting_id, true, false) as Button
		if scheduled_dashboard_button == null or scheduled_dashboard_button.disabled or scheduled_dashboard_button.text.find(debug_target_ticker) == -1:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the Dashboard calendar popup to expose an enabled button for the debug RUPSLB."
			}

		scheduled_dashboard_button.emit_signal("pressed")
		await get_tree().process_frame
		if not game_root.is_rupslb_meeting_overlay_visible() or game_root.get_rupslb_meeting_stage_id() != "arrival":
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected opening the next-day debug RUPSLB from the dashboard to enter the fullscreen meeting overlay."
			}

		var scheduled_rupslb_close_button: Button = game_root.find_child("RupslbCloseButton", true, false) as Button
		if scheduled_rupslb_close_button != null:
			scheduled_rupslb_close_button.emit_signal("pressed")
			await get_tree().process_frame

		if debug_overlay.visible:
			game_root._unhandled_input(debug_toggle_event)
			await get_tree().process_frame

		RunState.load_from_dict(interactive_test_base_state)
		game_root._refresh_all()
		await get_tree().process_frame

		var private_placement_company_id: String = ""
		for company_index in range(RunState.company_order.size() - 1, -1, -1):
			var private_candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(private_candidate_company_id).get("has_live_chain", false)):
				continue
			private_placement_company_id = private_candidate_company_id
			break
		if private_placement_company_id.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find a chain-free company for private placement RUPSLB coverage."
			}
		var private_before_definition: Dictionary = RunState.get_effective_company_definition(private_placement_company_id, false, false)
		var private_before_financials: Dictionary = private_before_definition.get("financials", {})
		var private_shares_before: float = float(private_before_financials.get("shares_outstanding", private_before_definition.get("shares_outstanding", 0.0)))
		if private_shares_before <= 0.0:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected private placement target shares outstanding to be available before execution."
			}
		var private_buy_result: Dictionary = GameManager.buy_lots(private_placement_company_id, 1)
		if not bool(private_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before the private placement RUPSLB flow."
			}
		var private_schedule_result: Dictionary = GameManager.debug_schedule_next_day_private_placement_rupslb(private_placement_company_id)
		var private_chain: Dictionary = private_schedule_result.get("chain", {})
		var private_meeting: Dictionary = private_schedule_result.get("meeting", {})
		var private_chain_id: String = str(private_chain.get("chain_id", ""))
		var private_meeting_id: String = str(private_meeting.get("id", ""))
		if (
			not bool(private_schedule_result.get("success", false)) or
			private_chain_id.is_empty() or
			private_meeting_id.is_empty() or
			str(private_chain.get("family", "")) != "private_placement" or
			private_chain.get("placement_terms", {}).is_empty()
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected private placement debug scheduling to create a placement chain with issuance terms."
			}

		var private_chain_store: Dictionary = RunState.get_active_corporate_action_chains()
		var private_live_chain: Dictionary = private_chain_store.get(private_chain_id, {}).duplicate(true)
		private_live_chain["approval_odds"] = 0.99
		private_live_chain["funding_pressure"] = 0.95
		private_live_chain["frontrunner_strength"] = 0.95
		private_live_chain["market_overpricing"] = 0.0
		private_live_chain["management_stance"] = "confirm"
		private_chain_store[private_chain_id] = private_live_chain
		RunState.set_active_corporate_action_chains(private_chain_store)

		GameManager.advance_day()
		await get_tree().process_frame
		var private_meeting_visible: bool = false
		for private_row_value in GameManager.get_corporate_meeting_snapshot().get("upcoming_rows", []):
			if typeof(private_row_value) != TYPE_DICTIONARY:
				continue
			var private_row: Dictionary = private_row_value
			if str(private_row.get("id", "")) == private_meeting_id and str(private_row.get("chain_family", "")) == "private_placement":
				private_meeting_visible = true
				break
		if not private_meeting_visible:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the private placement RUPSLB to appear in upcoming meetings after one Advance Day."
			}

		var private_start_result: Dictionary = GameManager.start_corporate_meeting_session(private_meeting_id)
		if not bool(private_start_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected private placement RUPSLB sessions to open for shareholders."
			}
		var private_vote_result: Dictionary = GameManager.submit_corporate_meeting_vote(private_meeting_id, "", "agree")
		var private_vote_summary: Dictionary = private_vote_result.get("session", {}).get("result_summary", {})
		if not bool(private_vote_result.get("success", false)) or not bool(private_vote_summary.get("approved", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the private placement RUPSLB agree vote to approve the agenda."
			}

		GameManager.advance_day()
		await get_tree().process_frame
		var private_after_vote_chain: Dictionary = RunState.get_active_corporate_action_chains().get(private_chain_id, {})
		if (
			str(private_after_vote_chain.get("stage", "")) != "execution" or
			not bool(RunState.get_corporate_meeting_sessions().get(private_meeting_id, {}).get("consumed", false))
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected approved private placement votes to move the chain into execution on the next simulated day."
			}

		GameManager.advance_day()
		await get_tree().process_frame
		var private_application_found: bool = false
		for private_application_value in RunState.last_day_results.get("corporate_action_applications", []):
			if typeof(private_application_value) != TYPE_DICTIONARY:
				continue
			var private_application: Dictionary = private_application_value
			if str(private_application.get("chain_id", "")) == private_chain_id and str(private_application.get("application_type", "")) == "private_placement":
				private_application_found = true
				break
		if not private_application_found:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected private placement execution to emit an application payload."
			}
		var private_after_definition: Dictionary = RunState.get_effective_company_definition(private_placement_company_id, false, false)
		var private_after_financials: Dictionary = private_after_definition.get("financials", {})
		var private_shares_after: float = float(private_after_financials.get("shares_outstanding", private_after_definition.get("shares_outstanding", 0.0)))
		if private_shares_after <= private_shares_before:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected private placement execution to increase company shares outstanding."
			}
		var private_adjustment_found: bool = false
		for private_adjustment_value in RunState.get_company(private_placement_company_id).get("company_profile", {}).get("corporate_action_adjustments", []):
			if typeof(private_adjustment_value) == TYPE_DICTIONARY and str(private_adjustment_value.get("type", "")) == "private_placement":
				private_adjustment_found = true
				break
		if not private_adjustment_found:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected private placement execution to record a company share-structure adjustment."
			}

		RunState.load_from_dict(interactive_test_base_state)
		game_root._refresh_all()
		await get_tree().process_frame

		var interactive_buyback_company_id: String = ""
		for company_index in range(RunState.company_order.size()):
			var interactive_buyback_candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(interactive_buyback_candidate_company_id).get("has_live_chain", false)):
				continue
			var interactive_buyback_candidate_definition: Dictionary = RunState.get_effective_company_definition(interactive_buyback_candidate_company_id, false, false)
			var interactive_buyback_candidate_financials: Dictionary = interactive_buyback_candidate_definition.get("financials", {})
			if not interactive_buyback_candidate_financials.has("free_float_pct"):
				continue
			if float(interactive_buyback_candidate_financials.get("shares_outstanding", interactive_buyback_candidate_definition.get("shares_outstanding", 0.0))) <= 1000.0:
				continue
			interactive_buyback_company_id = interactive_buyback_candidate_company_id
			break
		if interactive_buyback_company_id.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find a chain-free company for interactive stock buyback RUPSLB coverage."
			}
		var interactive_buyback_buy_result: Dictionary = GameManager.buy_lots(interactive_buyback_company_id, 1)
		if not bool(interactive_buyback_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before the stock buyback RUPSLB flow."
			}
		var interactive_buyback_schedule_result: Dictionary = GameManager.debug_schedule_next_day_stock_buyback_rupslb(interactive_buyback_company_id)
		var interactive_buyback_chain: Dictionary = interactive_buyback_schedule_result.get("chain", {})
		var interactive_buyback_meeting: Dictionary = interactive_buyback_schedule_result.get("meeting", {})
		var interactive_buyback_chain_id: String = str(interactive_buyback_chain.get("chain_id", ""))
		var interactive_buyback_meeting_id: String = str(interactive_buyback_meeting.get("id", ""))
		if (
			not bool(interactive_buyback_schedule_result.get("success", false)) or
			interactive_buyback_chain_id.is_empty() or
			interactive_buyback_meeting_id.is_empty() or
			str(interactive_buyback_chain.get("family", "")) != "stock_buyback" or
			str(interactive_buyback_chain.get("expected_meeting_type", "")) != "rupslb" or
			interactive_buyback_chain.get("buyback_terms", {}).is_empty()
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected stock buyback debug scheduling to create an interactive RUPSLB chain with buyback terms."
			}

		var interactive_buyback_chain_store: Dictionary = RunState.get_active_corporate_action_chains()
		var interactive_buyback_live_chain: Dictionary = interactive_buyback_chain_store.get(interactive_buyback_chain_id, {}).duplicate(true)
		interactive_buyback_live_chain["approval_odds"] = 0.99
		interactive_buyback_live_chain["funding_pressure"] = 0.95
		interactive_buyback_live_chain["frontrunner_strength"] = 0.95
		interactive_buyback_live_chain["market_overpricing"] = 0.0
		interactive_buyback_live_chain["management_stance"] = "confirm"
		interactive_buyback_chain_store[interactive_buyback_chain_id] = interactive_buyback_live_chain
		RunState.set_active_corporate_action_chains(interactive_buyback_chain_store)

		GameManager.advance_day()
		await get_tree().process_frame
		var interactive_buyback_meeting_visible: bool = false
		for interactive_buyback_row_value in GameManager.get_corporate_meeting_snapshot().get("upcoming_rows", []):
			if typeof(interactive_buyback_row_value) != TYPE_DICTIONARY:
				continue
			var interactive_buyback_row: Dictionary = interactive_buyback_row_value
			if (
				str(interactive_buyback_row.get("id", "")) == interactive_buyback_meeting_id and
				str(interactive_buyback_row.get("chain_family", "")) == "stock_buyback" and
				bool(interactive_buyback_row.get("interactive_v1", false))
			):
				interactive_buyback_meeting_visible = true
				break
		if not interactive_buyback_meeting_visible:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the stock buyback RUPSLB to appear as an interactive upcoming meeting after one Advance Day."
			}

		var interactive_buyback_start_result: Dictionary = GameManager.start_corporate_meeting_session(interactive_buyback_meeting_id)
		if not bool(interactive_buyback_start_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected stock buyback RUPSLB sessions to open for shareholders."
			}
		var interactive_buyback_vote_result: Dictionary = GameManager.submit_corporate_meeting_vote(interactive_buyback_meeting_id, "", "agree")
		var interactive_buyback_vote_summary: Dictionary = interactive_buyback_vote_result.get("session", {}).get("result_summary", {})
		if not bool(interactive_buyback_vote_result.get("success", false)) or not bool(interactive_buyback_vote_summary.get("approved", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the stock buyback RUPSLB agree vote to approve the agenda."
			}

		GameManager.advance_day()
		await get_tree().process_frame
		var interactive_buyback_after_vote_chain: Dictionary = RunState.get_active_corporate_action_chains().get(interactive_buyback_chain_id, {})
		if (
			str(interactive_buyback_after_vote_chain.get("stage", "")) != "execution" or
			not bool(RunState.get_corporate_meeting_sessions().get(interactive_buyback_meeting_id, {}).get("consumed", false))
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected approved stock buyback votes to move the chain into execution on the next simulated day."
			}

		RunState.load_from_dict(interactive_test_base_state)
		game_root._refresh_all()
		await get_tree().process_frame

		var stock_buyback_company_id: String = ""
		for company_index in range(RunState.company_order.size()):
			var buyback_candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(buyback_candidate_company_id).get("has_live_chain", false)):
				continue
			var buyback_candidate_definition: Dictionary = RunState.get_effective_company_definition(buyback_candidate_company_id, false, false)
			var buyback_candidate_financials: Dictionary = buyback_candidate_definition.get("financials", {})
			if not buyback_candidate_financials.has("free_float_pct"):
				continue
			if float(buyback_candidate_financials.get("shares_outstanding", buyback_candidate_definition.get("shares_outstanding", 0.0))) <= 1000.0:
				continue
			stock_buyback_company_id = buyback_candidate_company_id
			break
		if stock_buyback_company_id.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find a chain-free company for stock buyback execution coverage."
			}
		var buyback_before_definition: Dictionary = RunState.get_effective_company_definition(stock_buyback_company_id, false, false)
		var buyback_before_financials: Dictionary = buyback_before_definition.get("financials", {})
		var buyback_shares_before: float = float(buyback_before_financials.get("shares_outstanding", buyback_before_definition.get("shares_outstanding", 0.0)))
		var buyback_free_float_before: float = float(buyback_before_financials.get("free_float_pct", 0.0))
		var buyback_force_result: Dictionary = GameManager.debug_force_stock_buyback_execution(stock_buyback_company_id)
		var buyback_chain: Dictionary = buyback_force_result.get("chain", {})
		var buyback_chain_id: String = str(buyback_chain.get("chain_id", ""))
		var buyback_terms: Dictionary = buyback_chain.get("buyback_terms", {})
		if (
			not bool(buyback_force_result.get("success", false)) or
			buyback_chain_id.is_empty() or
			str(buyback_chain.get("family", "")) != "stock_buyback" or
			int(buyback_terms.get("executed_shares", 0)) <= 0
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected stock buyback debug forcing to create an executable buyback chain with terms."
			}
		var buyback_snapshot: Dictionary = GameManager.get_company_corporate_action_snapshot(stock_buyback_company_id)
		var buyback_primary_chain: Dictionary = buyback_snapshot.get("primary_chain", {})
		var buyback_snapshot_terms: Dictionary = buyback_primary_chain.get("buyback_terms", {})
		if buyback_snapshot_terms.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the corporate-action snapshot to expose stock buyback terms."
			}

		GameManager.advance_day()
		await get_tree().process_frame
		var buyback_application_found: bool = false
		for buyback_application_value in RunState.last_day_results.get("corporate_action_applications", []):
			if typeof(buyback_application_value) != TYPE_DICTIONARY:
				continue
			var buyback_application: Dictionary = buyback_application_value
			if str(buyback_application.get("chain_id", "")) == buyback_chain_id and str(buyback_application.get("application_type", "")) == "stock_buyback":
				buyback_application_found = true
				break
		if not buyback_application_found:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected stock buyback execution to emit an application payload."
			}
		var buyback_after_definition: Dictionary = RunState.get_effective_company_definition(stock_buyback_company_id, false, false)
		var buyback_after_financials: Dictionary = buyback_after_definition.get("financials", {})
		var buyback_shares_after: float = float(buyback_after_financials.get("shares_outstanding", buyback_after_definition.get("shares_outstanding", 0.0)))
		var buyback_free_float_after: float = float(buyback_after_financials.get("free_float_pct", 0.0))
		if buyback_shares_after >= buyback_shares_before or buyback_free_float_after > buyback_free_float_before:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected stock buyback execution to retire shares and not increase free float."
			}
		var buyback_adjustment_found: bool = false
		for buyback_adjustment_value in RunState.get_company(stock_buyback_company_id).get("company_profile", {}).get("corporate_action_adjustments", []):
			if typeof(buyback_adjustment_value) == TYPE_DICTIONARY and str(buyback_adjustment_value.get("type", "")) == "stock_buyback":
				buyback_adjustment_found = true
				break
		if not buyback_adjustment_found:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected stock buyback execution to record a company share-structure adjustment."
			}

		RunState.load_from_dict(interactive_test_base_state)
		game_root._refresh_all()
		await get_tree().process_frame

		var interactive_split_company_id: String = ""
		var interactive_split_best_price: float = 0.0
		for company_index in range(RunState.company_order.size()):
			var interactive_split_candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(interactive_split_candidate_company_id).get("has_live_chain", false)):
				continue
			var interactive_split_candidate_definition: Dictionary = RunState.get_effective_company_definition(interactive_split_candidate_company_id, false, false)
			var interactive_split_candidate_financials: Dictionary = interactive_split_candidate_definition.get("financials", {})
			var interactive_split_candidate_runtime: Dictionary = RunState.get_company(interactive_split_candidate_company_id)
			var interactive_split_candidate_price: float = float(interactive_split_candidate_runtime.get("current_price", interactive_split_candidate_definition.get("base_price", 0.0)))
			if float(interactive_split_candidate_financials.get("shares_outstanding", interactive_split_candidate_definition.get("shares_outstanding", 0.0))) <= 1000.0:
				continue
			if interactive_split_candidate_price > interactive_split_best_price:
				interactive_split_best_price = interactive_split_candidate_price
				interactive_split_company_id = interactive_split_candidate_company_id
		if interactive_split_company_id.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find a chain-free company for interactive stock split RUPSLB coverage."
			}
		var interactive_split_buy_result: Dictionary = GameManager.buy_lots(interactive_split_company_id, 1)
		if not bool(interactive_split_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before the stock split RUPSLB flow."
			}
		var interactive_split_schedule_result: Dictionary = GameManager.debug_schedule_next_day_stock_split_rupslb(interactive_split_company_id)
		var interactive_split_chain: Dictionary = interactive_split_schedule_result.get("chain", {})
		var interactive_split_meeting: Dictionary = interactive_split_schedule_result.get("meeting", {})
		var interactive_split_chain_id: String = str(interactive_split_chain.get("chain_id", ""))
		var interactive_split_meeting_id: String = str(interactive_split_meeting.get("id", ""))
		if (
			not bool(interactive_split_schedule_result.get("success", false)) or
			interactive_split_chain_id.is_empty() or
			interactive_split_meeting_id.is_empty() or
			str(interactive_split_chain.get("family", "")) != "stock_split" or
			str(interactive_split_chain.get("expected_meeting_type", "")) != "rupslb" or
			interactive_split_chain.get("split_terms", {}).is_empty()
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected stock split debug scheduling to create an interactive RUPSLB chain with split terms."
			}

		var interactive_split_chain_store: Dictionary = RunState.get_active_corporate_action_chains()
		var interactive_split_live_chain: Dictionary = interactive_split_chain_store.get(interactive_split_chain_id, {}).duplicate(true)
		interactive_split_live_chain["approval_odds"] = 0.99
		interactive_split_live_chain["funding_pressure"] = 0.95
		interactive_split_live_chain["frontrunner_strength"] = 0.95
		interactive_split_live_chain["market_overpricing"] = 0.0
		interactive_split_live_chain["management_stance"] = "confirm"
		interactive_split_chain_store[interactive_split_chain_id] = interactive_split_live_chain
		RunState.set_active_corporate_action_chains(interactive_split_chain_store)

		GameManager.advance_day()
		await get_tree().process_frame
		var interactive_split_meeting_visible: bool = false
		for interactive_split_row_value in GameManager.get_corporate_meeting_snapshot().get("upcoming_rows", []):
			if typeof(interactive_split_row_value) != TYPE_DICTIONARY:
				continue
			var interactive_split_row: Dictionary = interactive_split_row_value
			if (
				str(interactive_split_row.get("id", "")) == interactive_split_meeting_id and
				str(interactive_split_row.get("chain_family", "")) == "stock_split" and
				bool(interactive_split_row.get("interactive_v1", false))
			):
				interactive_split_meeting_visible = true
				break
		if not interactive_split_meeting_visible:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the stock split RUPSLB to appear as an interactive upcoming meeting after one Advance Day."
			}

		var interactive_split_start_result: Dictionary = GameManager.start_corporate_meeting_session(interactive_split_meeting_id)
		if not bool(interactive_split_start_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected stock split RUPSLB sessions to open for shareholders."
			}
		var interactive_split_vote_result: Dictionary = GameManager.submit_corporate_meeting_vote(interactive_split_meeting_id, "", "agree")
		var interactive_split_vote_summary: Dictionary = interactive_split_vote_result.get("session", {}).get("result_summary", {})
		if not bool(interactive_split_vote_result.get("success", false)) or not bool(interactive_split_vote_summary.get("approved", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the stock split RUPSLB agree vote to approve the agenda."
			}

		GameManager.advance_day()
		await get_tree().process_frame
		var interactive_split_after_vote_chain: Dictionary = RunState.get_active_corporate_action_chains().get(interactive_split_chain_id, {})
		if (
			str(interactive_split_after_vote_chain.get("stage", "")) != "execution" or
			not bool(RunState.get_corporate_meeting_sessions().get(interactive_split_meeting_id, {}).get("consumed", false))
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected approved stock split votes to move the chain into execution on the next simulated day."
			}

		RunState.load_from_dict(interactive_test_base_state)
		game_root._refresh_all()
		await get_tree().process_frame

		var stock_split_company_id: String = ""
		var stock_split_best_price: float = 0.0
		for company_index in range(RunState.company_order.size()):
			var split_candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(split_candidate_company_id).get("has_live_chain", false)):
				continue
			var split_candidate_definition: Dictionary = RunState.get_effective_company_definition(split_candidate_company_id, false, false)
			var split_candidate_financials: Dictionary = split_candidate_definition.get("financials", {})
			var split_candidate_runtime: Dictionary = RunState.get_company(split_candidate_company_id)
			var split_candidate_price: float = float(split_candidate_runtime.get("current_price", split_candidate_definition.get("base_price", 0.0)))
			if float(split_candidate_financials.get("shares_outstanding", split_candidate_definition.get("shares_outstanding", 0.0))) <= 1000.0:
				continue
			if split_candidate_price > stock_split_best_price:
				stock_split_best_price = split_candidate_price
				stock_split_company_id = split_candidate_company_id
		if stock_split_company_id.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find a chain-free company for stock split execution coverage."
			}
		var split_before_definition: Dictionary = RunState.get_effective_company_definition(stock_split_company_id, false, false)
		var split_before_financials: Dictionary = split_before_definition.get("financials", {})
		var split_shares_before: float = float(split_before_financials.get("shares_outstanding", split_before_definition.get("shares_outstanding", 0.0)))
		var split_buy_result: Dictionary = GameManager.buy_lots(stock_split_company_id, 1)
		if not bool(split_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before stock split execution coverage."
			}
		var split_holding_before: int = int(RunState.get_holding(stock_split_company_id).get("shares", 0))
		var split_force_result: Dictionary = GameManager.debug_force_stock_split_execution(stock_split_company_id)
		var split_chain: Dictionary = split_force_result.get("chain", {})
		var split_chain_id: String = str(split_chain.get("chain_id", ""))
		var split_terms: Dictionary = split_chain.get("split_terms", {})
		var split_multiplier: float = float(split_terms.get("share_multiplier", 0.0))
		if (
			not bool(split_force_result.get("success", false)) or
			split_chain_id.is_empty() or
			str(split_chain.get("family", "")) != "stock_split" or
			split_terms.is_empty() or
			split_multiplier <= 0.0
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected stock split debug forcing to create an executable split chain with terms."
			}
		var split_snapshot: Dictionary = GameManager.get_company_corporate_action_snapshot(stock_split_company_id)
		var split_snapshot_terms: Dictionary = split_snapshot.get("primary_chain", {}).get("split_terms", {})
		if split_snapshot_terms.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the corporate-action snapshot to expose stock split terms."
			}

		GameManager.advance_day()
		await get_tree().process_frame
		var split_application: Dictionary = {}
		for split_application_value in RunState.last_day_results.get("corporate_action_applications", []):
			if typeof(split_application_value) != TYPE_DICTIONARY:
				continue
			var split_candidate_application: Dictionary = split_application_value
			if str(split_candidate_application.get("chain_id", "")) == split_chain_id and str(split_candidate_application.get("application_type", "")) == "stock_split":
				split_application = split_candidate_application.duplicate(true)
				break
		if split_application.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected stock split execution to emit an application payload."
			}
		var split_after_definition: Dictionary = RunState.get_effective_company_definition(stock_split_company_id, false, false)
		var split_after_financials: Dictionary = split_after_definition.get("financials", {})
		var split_shares_after: float = float(split_after_financials.get("shares_outstanding", split_after_definition.get("shares_outstanding", 0.0)))
		var split_expected_shares: float = float(split_application.get("new_shares_outstanding", split_shares_before * split_multiplier))
		if absf(split_shares_after - split_expected_shares) > max(1.0, split_expected_shares * 0.001):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected stock split execution to update shares outstanding by the split multiplier."
			}
		var split_holding_after: int = int(RunState.get_holding(stock_split_company_id).get("shares", 0))
		var split_expected_holding: int = int(floor(float(split_holding_before) * split_multiplier + 0.0001))
		if str(split_application.get("split_type", "split")) == "split":
			split_expected_holding = max(int(round(float(split_holding_before) * split_multiplier)), split_holding_before)
		if split_holding_after != split_expected_holding:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected stock split execution to adjust player holdings by the split multiplier."
			}
		var split_adjustment_found: bool = false
		for split_adjustment_value in RunState.get_company(stock_split_company_id).get("company_profile", {}).get("corporate_action_adjustments", []):
			if typeof(split_adjustment_value) == TYPE_DICTIONARY and str(split_adjustment_value.get("type", "")) == "stock_split":
				split_adjustment_found = true
				break
		if not split_adjustment_found:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected stock split execution to record a company share-structure adjustment."
			}
		var split_trade_found: bool = false
		for split_trade_index in range(RunState.trade_history.size() - 1, -1, -1):
			var split_trade: Dictionary = RunState.trade_history[split_trade_index]
			if str(split_trade.get("company_id", "")) == stock_split_company_id and str(split_trade.get("side", "")) in ["stock_split", "reverse_stock_split"]:
				split_trade_found = true
				break
		if not split_trade_found:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected stock split execution to record a portfolio history row."
			}

		RunState.load_from_dict(interactive_test_base_state)
		game_root._refresh_all()
		await get_tree().process_frame

		var interactive_tender_company_id: String = ""
		var interactive_tender_lot_cash: float = float(RunState.player_portfolio.get("cash", 0.0))
		for company_index in range(RunState.company_order.size()):
			var interactive_tender_candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(interactive_tender_candidate_company_id).get("has_live_chain", false)):
				continue
			var interactive_tender_candidate_definition: Dictionary = RunState.get_effective_company_definition(interactive_tender_candidate_company_id, false, false)
			var interactive_tender_candidate_financials: Dictionary = interactive_tender_candidate_definition.get("financials", {})
			var interactive_tender_candidate_runtime: Dictionary = RunState.get_company(interactive_tender_candidate_company_id)
			var interactive_tender_candidate_price: float = float(interactive_tender_candidate_runtime.get("current_price", interactive_tender_candidate_definition.get("base_price", 0.0)))
			if not interactive_tender_candidate_financials.has("free_float_pct"):
				continue
			if float(interactive_tender_candidate_financials.get("free_float_pct", 0.0)) <= 25.0:
				continue
			if float(interactive_tender_candidate_financials.get("shares_outstanding", interactive_tender_candidate_definition.get("shares_outstanding", 0.0))) <= 1000.0:
				continue
			if interactive_tender_candidate_price * float(GameManager.get_lot_size()) > interactive_tender_lot_cash:
				continue
			interactive_tender_company_id = interactive_tender_candidate_company_id
			break
		if interactive_tender_company_id.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find a chain-free company for interactive tender offer coverage."
			}
		var interactive_tender_buy_result: Dictionary = GameManager.buy_lots(interactive_tender_company_id, 1)
		if not bool(interactive_tender_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before the tender offer election flow."
			}
		var interactive_tender_holding_before: int = int(RunState.get_holding(interactive_tender_company_id).get("shares", 0))
		var interactive_tender_cash_before: float = float(RunState.player_portfolio.get("cash", 0.0))
		var interactive_tender_schedule_result: Dictionary = GameManager.debug_schedule_next_day_tender_offer_rupslb(interactive_tender_company_id)
		var interactive_tender_chain: Dictionary = interactive_tender_schedule_result.get("chain", {})
		var interactive_tender_meeting: Dictionary = interactive_tender_schedule_result.get("meeting", {})
		var interactive_tender_chain_id: String = str(interactive_tender_chain.get("chain_id", ""))
		var interactive_tender_meeting_id: String = str(interactive_tender_meeting.get("id", ""))
		if (
			not bool(interactive_tender_schedule_result.get("success", false)) or
			interactive_tender_chain_id.is_empty() or
			interactive_tender_meeting_id.is_empty() or
			str(interactive_tender_chain.get("family", "")) != "tender_offer" or
			str(interactive_tender_chain.get("expected_meeting_type", "")) != "rupslb" or
			interactive_tender_chain.get("tender_terms", {}).is_empty()
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected tender offer debug scheduling to create an interactive RUPSLB chain with tender terms."
			}
		var interactive_tender_chain_store: Dictionary = RunState.get_active_corporate_action_chains()
		var interactive_tender_live_chain: Dictionary = interactive_tender_chain_store.get(interactive_tender_chain_id, {}).duplicate(true)
		var interactive_tender_terms: Dictionary = interactive_tender_live_chain.get("tender_terms", {}).duplicate(true)
		interactive_tender_terms["aftermath_state"] = "none"
		interactive_tender_terms["new_free_float_pct"] = max(float(interactive_tender_terms.get("new_free_float_pct", 35.0)), 18.0)
		interactive_tender_live_chain["tender_terms"] = interactive_tender_terms
		interactive_tender_live_chain["approval_odds"] = 0.99
		interactive_tender_live_chain["funding_pressure"] = 0.95
		interactive_tender_live_chain["frontrunner_strength"] = 0.95
		interactive_tender_live_chain["market_overpricing"] = 0.0
		interactive_tender_live_chain["management_stance"] = "confirm"
		interactive_tender_chain_store[interactive_tender_chain_id] = interactive_tender_live_chain
		RunState.set_active_corporate_action_chains(interactive_tender_chain_store)

		GameManager.advance_day()
		await get_tree().process_frame
		var interactive_tender_meeting_visible: bool = false
		for interactive_tender_row_value in GameManager.get_corporate_meeting_snapshot().get("upcoming_rows", []):
			if typeof(interactive_tender_row_value) != TYPE_DICTIONARY:
				continue
			var interactive_tender_row: Dictionary = interactive_tender_row_value
			if (
				str(interactive_tender_row.get("id", "")) == interactive_tender_meeting_id and
				str(interactive_tender_row.get("chain_family", "")) == "tender_offer" and
				bool(interactive_tender_row.get("interactive_v1", false))
			):
				interactive_tender_meeting_visible = true
				break
		if not interactive_tender_meeting_visible:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the tender offer RUPSLB to appear as an interactive upcoming meeting after one Advance Day."
			}
		var interactive_tender_start_result: Dictionary = GameManager.start_corporate_meeting_session(interactive_tender_meeting_id)
		var interactive_tender_session_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(interactive_tender_meeting_id)
		if (
			not bool(interactive_tender_start_result.get("success", false)) or
			str(interactive_tender_session_snapshot.get("presentation", {}).get("agree_button_label", "")) != "Tender Shares" or
			str(interactive_tender_session_snapshot.get("presentation", {}).get("disagree_button_label", "")) != "Hold Shares"
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected tender offer RUPSLB sessions to expose tender-specific election labels."
			}
		var interactive_tender_vote_result: Dictionary = GameManager.submit_corporate_meeting_vote(interactive_tender_meeting_id, "", "agree")
		var interactive_tender_vote_summary: Dictionary = interactive_tender_vote_result.get("session", {}).get("result_summary", {})
		if (
			not bool(interactive_tender_vote_result.get("success", false)) or
			str(interactive_tender_vote_summary.get("result_category", "")) != "tender_election" or
			str(interactive_tender_vote_summary.get("player_tender_choice", "")) != "tender"
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected tender offer Agree to record a player tender election."
			}
		GameManager.advance_day()
		await get_tree().process_frame
		GameManager.advance_day()
		await get_tree().process_frame
		var interactive_tender_application: Dictionary = {}
		for interactive_tender_application_value in RunState.last_day_results.get("corporate_action_applications", []):
			if typeof(interactive_tender_application_value) != TYPE_DICTIONARY:
				continue
			var interactive_tender_candidate_application: Dictionary = interactive_tender_application_value
			if str(interactive_tender_candidate_application.get("chain_id", "")) == interactive_tender_chain_id and str(interactive_tender_candidate_application.get("application_type", "")) == "tender_offer":
				interactive_tender_application = interactive_tender_candidate_application.duplicate(true)
				break
		var interactive_tender_holding_after: int = int(RunState.get_holding(interactive_tender_company_id).get("shares", 0))
		var interactive_tender_cash_after: float = float(RunState.player_portfolio.get("cash", 0.0))
		if (
			interactive_tender_application.is_empty() or
			str(interactive_tender_application.get("player_tender_choice", "")) != "tender" or
			interactive_tender_holding_after >= interactive_tender_holding_before or
			interactive_tender_cash_after <= interactive_tender_cash_before
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected tender election execution to reduce held shares and pay cash."
			}

		RunState.load_from_dict(interactive_test_base_state)
		game_root._refresh_all()
		await get_tree().process_frame

		var hold_tender_company_id: String = ""
		var hold_tender_lot_cash: float = float(RunState.player_portfolio.get("cash", 0.0))
		for company_index in range(RunState.company_order.size()):
			var hold_tender_candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(hold_tender_candidate_company_id).get("has_live_chain", false)):
				continue
			var hold_tender_candidate_definition: Dictionary = RunState.get_effective_company_definition(hold_tender_candidate_company_id, false, false)
			var hold_tender_candidate_financials: Dictionary = hold_tender_candidate_definition.get("financials", {})
			var hold_tender_candidate_runtime: Dictionary = RunState.get_company(hold_tender_candidate_company_id)
			var hold_tender_candidate_price: float = float(hold_tender_candidate_runtime.get("current_price", hold_tender_candidate_definition.get("base_price", 0.0)))
			if not hold_tender_candidate_financials.has("free_float_pct"):
				continue
			if float(hold_tender_candidate_financials.get("free_float_pct", 0.0)) <= 25.0:
				continue
			if float(hold_tender_candidate_financials.get("shares_outstanding", hold_tender_candidate_definition.get("shares_outstanding", 0.0))) <= 1000.0:
				continue
			if hold_tender_candidate_price * float(GameManager.get_lot_size()) > hold_tender_lot_cash:
				continue
			hold_tender_company_id = hold_tender_candidate_company_id
			break
		if hold_tender_company_id.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find a chain-free company for hold-side tender offer coverage."
			}
		var hold_tender_buy_result: Dictionary = GameManager.buy_lots(hold_tender_company_id, 1)
		if not bool(hold_tender_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before the tender offer hold flow."
			}
		var hold_tender_holding_before: int = int(RunState.get_holding(hold_tender_company_id).get("shares", 0))
		var hold_tender_cash_before: float = float(RunState.player_portfolio.get("cash", 0.0))
		var hold_tender_schedule_result: Dictionary = GameManager.debug_schedule_next_day_tender_offer_rupslb(hold_tender_company_id)
		var hold_tender_chain: Dictionary = hold_tender_schedule_result.get("chain", {})
		var hold_tender_chain_id: String = str(hold_tender_chain.get("chain_id", ""))
		var hold_tender_meeting_id: String = str(hold_tender_schedule_result.get("meeting", {}).get("id", ""))
		if not bool(hold_tender_schedule_result.get("success", false)) or hold_tender_chain_id.is_empty() or hold_tender_meeting_id.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected hold-side tender scheduling to create a meeting and chain."
			}
		var hold_tender_chain_store: Dictionary = RunState.get_active_corporate_action_chains()
		var hold_tender_live_chain: Dictionary = hold_tender_chain_store.get(hold_tender_chain_id, {}).duplicate(true)
		var hold_tender_terms: Dictionary = hold_tender_live_chain.get("tender_terms", {}).duplicate(true)
		hold_tender_terms["aftermath_state"] = "none"
		hold_tender_terms["new_free_float_pct"] = max(float(hold_tender_terms.get("new_free_float_pct", 35.0)), 18.0)
		hold_tender_live_chain["tender_terms"] = hold_tender_terms
		hold_tender_live_chain["approval_odds"] = 0.99
		hold_tender_live_chain["funding_pressure"] = 0.95
		hold_tender_live_chain["frontrunner_strength"] = 0.95
		hold_tender_live_chain["market_overpricing"] = 0.0
		hold_tender_live_chain["management_stance"] = "confirm"
		hold_tender_chain_store[hold_tender_chain_id] = hold_tender_live_chain
		RunState.set_active_corporate_action_chains(hold_tender_chain_store)
		GameManager.advance_day()
		await get_tree().process_frame
		var hold_tender_start_result: Dictionary = GameManager.start_corporate_meeting_session(hold_tender_meeting_id)
		var hold_tender_vote_result: Dictionary = GameManager.submit_corporate_meeting_vote(hold_tender_meeting_id, "", "disagree")
		var hold_tender_vote_summary: Dictionary = hold_tender_vote_result.get("session", {}).get("result_summary", {})
		if (
			not bool(hold_tender_start_result.get("success", false)) or
			not bool(hold_tender_vote_result.get("success", false)) or
			str(hold_tender_vote_summary.get("player_tender_choice", "")) != "hold"
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected tender offer Disagree to record a player hold election."
			}
		GameManager.advance_day()
		await get_tree().process_frame
		GameManager.advance_day()
		await get_tree().process_frame
		var hold_tender_application: Dictionary = {}
		for hold_tender_application_value in RunState.last_day_results.get("corporate_action_applications", []):
			if typeof(hold_tender_application_value) != TYPE_DICTIONARY:
				continue
			var hold_tender_candidate_application: Dictionary = hold_tender_application_value
			if str(hold_tender_candidate_application.get("chain_id", "")) == hold_tender_chain_id and str(hold_tender_candidate_application.get("application_type", "")) == "tender_offer":
				hold_tender_application = hold_tender_candidate_application.duplicate(true)
				break
		var hold_tender_holding_after: int = int(RunState.get_holding(hold_tender_company_id).get("shares", 0))
		var hold_tender_cash_after: float = float(RunState.player_portfolio.get("cash", 0.0))
		if (
			hold_tender_application.is_empty() or
			str(hold_tender_application.get("player_tender_choice", "")) != "hold" or
			hold_tender_holding_after != hold_tender_holding_before or
			absf(hold_tender_cash_after - hold_tender_cash_before) > 0.01
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected hold election execution to keep player shares and cash unchanged while the offer resolves."
			}

		RunState.load_from_dict(interactive_test_base_state)
		game_root._refresh_all()
		await get_tree().process_frame

		var tender_offer_company_id: String = ""
		var tender_lot_cash: float = float(RunState.player_portfolio.get("cash", 0.0))
		for company_index in range(RunState.company_order.size()):
			var tender_candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(tender_candidate_company_id).get("has_live_chain", false)):
				continue
			var tender_candidate_definition: Dictionary = RunState.get_effective_company_definition(tender_candidate_company_id, false, false)
			var tender_candidate_financials: Dictionary = tender_candidate_definition.get("financials", {})
			var tender_candidate_runtime: Dictionary = RunState.get_company(tender_candidate_company_id)
			var tender_candidate_price: float = float(tender_candidate_runtime.get("current_price", tender_candidate_definition.get("base_price", 0.0)))
			if not tender_candidate_financials.has("free_float_pct"):
				continue
			if float(tender_candidate_financials.get("shares_outstanding", tender_candidate_definition.get("shares_outstanding", 0.0))) <= 1000.0:
				continue
			if tender_candidate_price * float(GameManager.get_lot_size()) > tender_lot_cash:
				continue
			tender_offer_company_id = tender_candidate_company_id
			break
		if tender_offer_company_id.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find a chain-free company for tender offer execution coverage."
			}
		var tender_before_definition: Dictionary = RunState.get_effective_company_definition(tender_offer_company_id, false, false)
		var tender_before_financials: Dictionary = tender_before_definition.get("financials", {})
		var tender_shares_before: float = float(tender_before_financials.get("shares_outstanding", tender_before_definition.get("shares_outstanding", 0.0)))
		var tender_free_float_before: float = float(tender_before_financials.get("free_float_pct", 0.0))
		var tender_buy_result: Dictionary = GameManager.buy_lots(tender_offer_company_id, 1)
		if not bool(tender_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before tender offer execution coverage."
			}
		var tender_holding_before: int = int(RunState.get_holding(tender_offer_company_id).get("shares", 0))
		var tender_cash_before: float = float(RunState.player_portfolio.get("cash", 0.0))
		var tender_force_result: Dictionary = GameManager.debug_force_tender_offer_execution(tender_offer_company_id, true)
		var tender_chain: Dictionary = tender_force_result.get("chain", {})
		var tender_chain_id: String = str(tender_chain.get("chain_id", ""))
		var tender_terms: Dictionary = tender_chain.get("tender_terms", {})
		if (
			not bool(tender_force_result.get("success", false)) or
			tender_chain_id.is_empty() or
			str(tender_chain.get("family", "")) != "tender_offer" or
			tender_terms.is_empty() or
			int(tender_terms.get("expected_accepted_shares", 0)) <= 0
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected tender offer debug forcing to create an executable go-private tender chain with terms."
			}
		if str(tender_terms.get("aftermath_state", "")) != "go_private_cashout":
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected forced tender offer terms to carry a go-private aftermath state."
			}
		var tender_snapshot: Dictionary = GameManager.get_company_corporate_action_snapshot(tender_offer_company_id)
		var tender_snapshot_terms: Dictionary = tender_snapshot.get("primary_chain", {}).get("tender_terms", {})
		if tender_snapshot_terms.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the corporate-action snapshot to expose tender offer terms."
			}

		GameManager.advance_day()
		await get_tree().process_frame
		var tender_application: Dictionary = {}
		for tender_application_value in RunState.last_day_results.get("corporate_action_applications", []):
			if typeof(tender_application_value) != TYPE_DICTIONARY:
				continue
			var tender_candidate_application: Dictionary = tender_application_value
			if str(tender_candidate_application.get("chain_id", "")) == tender_chain_id and str(tender_candidate_application.get("application_type", "")) == "tender_offer":
				tender_application = tender_candidate_application.duplicate(true)
				break
		if tender_application.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected tender offer execution to emit an application payload."
			}
		var tender_after_definition: Dictionary = RunState.get_effective_company_definition(tender_offer_company_id, false, false)
		var tender_after_financials: Dictionary = tender_after_definition.get("financials", {})
		var tender_shares_after: float = float(tender_after_financials.get("shares_outstanding", tender_after_definition.get("shares_outstanding", 0.0)))
		var tender_free_float_after: float = float(tender_after_financials.get("free_float_pct", 0.0))
		if absf(tender_shares_after - tender_shares_before) > max(1.0, tender_shares_before * 0.001) or tender_free_float_after > tender_free_float_before:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected tender offer execution to keep shares outstanding stable and not increase free float."
			}
		var tender_adjustment: Dictionary = {}
		for tender_adjustment_value in RunState.get_company(tender_offer_company_id).get("company_profile", {}).get("corporate_action_adjustments", []):
			if typeof(tender_adjustment_value) == TYPE_DICTIONARY and str(tender_adjustment_value.get("type", "")) == "tender_offer":
				tender_adjustment = tender_adjustment_value.duplicate(true)
				break
		if tender_adjustment.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected tender offer execution to record a company share-structure adjustment."
			}
		var tender_holding_after: int = int(RunState.get_holding(tender_offer_company_id).get("shares", 0))
		var tender_cash_after: float = float(RunState.player_portfolio.get("cash", 0.0))
		if (
			tender_holding_after != 0 or
			tender_cash_after <= tender_cash_before or
			int(tender_adjustment.get("player_tendered_shares", 0)) <= 0 or
			str(tender_adjustment.get("player_tender_status", "")) != "accepted" or
			str(tender_adjustment.get("aftermath_state", "")) != "go_private_cashout" or
			int(tender_adjustment.get("player_final_cashout_shares", 0)) <= 0 or
			str(tender_adjustment.get("player_final_cashout_status", "")) != "cashed_out"
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected go-private tender offer treatment to tender accepted shares and cash out the remaining position."
			}
		var tender_trade_found: bool = false
		var go_private_trade_found: bool = false
		for tender_trade_index in range(RunState.trade_history.size() - 1, -1, -1):
			var tender_trade: Dictionary = RunState.trade_history[tender_trade_index]
			if str(tender_trade.get("company_id", "")) == tender_offer_company_id and str(tender_trade.get("side", "")) == "tender_offer":
				tender_trade_found = true
			if str(tender_trade.get("company_id", "")) == tender_offer_company_id and str(tender_trade.get("side", "")) == "go_private_cashout":
				go_private_trade_found = true
			if tender_trade_found and go_private_trade_found:
				break
		if not tender_trade_found or not go_private_trade_found:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected tender offer execution to record tender and go-private cash-out portfolio history rows."
			}
		var tender_after_snapshot: Dictionary = GameManager.get_company_snapshot(tender_offer_company_id, false, false, false)
		if (
			str(tender_after_snapshot.get("listing_status", "")) != "go_private_cashout" or
			not bool(tender_after_snapshot.get("trade_disabled", false)) or
			str(tender_after_snapshot.get("impactability", {}).get("label", "")) != "Go-private"
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected go-private tender aftermath to mark the company as trade-disabled with a go-private tape label."
			}
		var blocked_tender_rebuy: Dictionary = GameManager.estimate_buy_lots(tender_offer_company_id, 1)
		if bool(blocked_tender_rebuy.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected completed go-private names to reject new buy estimates."
			}

		RunState.load_from_dict(interactive_test_base_state)
		game_root._refresh_all()
		await get_tree().process_frame

		var interactive_mna_company_id: String = ""
		var interactive_mna_lot_cash: float = float(RunState.player_portfolio.get("cash", 0.0))
		for company_index in range(RunState.company_order.size()):
			var interactive_mna_candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(interactive_mna_candidate_company_id).get("has_live_chain", false)):
				continue
			if int(RunState.get_holding(interactive_mna_candidate_company_id).get("shares", 0)) > 0:
				continue
			var interactive_mna_candidate_runtime: Dictionary = RunState.get_company(interactive_mna_candidate_company_id)
			var interactive_mna_candidate_profile: Dictionary = interactive_mna_candidate_runtime.get("company_profile", {})
			if bool(interactive_mna_candidate_profile.get("trade_disabled", false)):
				continue
			var interactive_mna_candidate_definition: Dictionary = RunState.get_effective_company_definition(interactive_mna_candidate_company_id, false, false)
			var interactive_mna_candidate_financials: Dictionary = interactive_mna_candidate_definition.get("financials", {})
			var interactive_mna_candidate_price: float = float(interactive_mna_candidate_runtime.get("current_price", interactive_mna_candidate_definition.get("base_price", 0.0)))
			if float(interactive_mna_candidate_financials.get("shares_outstanding", interactive_mna_candidate_definition.get("shares_outstanding", 0.0))) <= 1000.0:
				continue
			if interactive_mna_candidate_price * float(GameManager.get_lot_size()) > interactive_mna_lot_cash:
				continue
			interactive_mna_company_id = interactive_mna_candidate_company_id
			break
		if interactive_mna_company_id.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find a chain-free company for interactive strategic M&A coverage."
			}
		var interactive_mna_buy_result: Dictionary = GameManager.buy_lots(interactive_mna_company_id, 1)
		if not bool(interactive_mna_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before the strategic M&A RUPSLB flow."
			}
		var interactive_mna_holding_before: int = int(RunState.get_holding(interactive_mna_company_id).get("shares", 0))
		var interactive_mna_cash_before: float = float(RunState.player_portfolio.get("cash", 0.0))
		var interactive_mna_schedule_result: Dictionary = GameManager.debug_schedule_next_day_strategic_mna_rupslb(interactive_mna_company_id)
		var interactive_mna_chain: Dictionary = interactive_mna_schedule_result.get("chain", {})
		var interactive_mna_meeting: Dictionary = interactive_mna_schedule_result.get("meeting", {})
		var interactive_mna_chain_id: String = str(interactive_mna_chain.get("chain_id", ""))
		var interactive_mna_meeting_id: String = str(interactive_mna_meeting.get("id", ""))
		var interactive_mna_terms: Dictionary = interactive_mna_chain.get("mna_terms", {})
		if (
			not bool(interactive_mna_schedule_result.get("success", false)) or
			interactive_mna_chain_id.is_empty() or
			interactive_mna_meeting_id.is_empty() or
			str(interactive_mna_chain.get("family", "")) != "strategic_merger_acquisition" or
			str(interactive_mna_chain.get("expected_meeting_type", "")) != "rupslb" or
			interactive_mna_terms.is_empty() or
			float(interactive_mna_terms.get("cashout_price", 0.0)) <= 0.0
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected strategic M&A debug scheduling to create an interactive RUPSLB chain with cash acquisition terms."
			}
		var interactive_mna_chain_store: Dictionary = RunState.get_active_corporate_action_chains()
		var interactive_mna_live_chain: Dictionary = interactive_mna_chain_store.get(interactive_mna_chain_id, {}).duplicate(true)
		interactive_mna_live_chain["approval_odds"] = 0.99
		interactive_mna_live_chain["funding_pressure"] = 0.95
		interactive_mna_live_chain["frontrunner_strength"] = 0.95
		interactive_mna_live_chain["market_overpricing"] = 0.0
		interactive_mna_live_chain["management_stance"] = "confirm"
		interactive_mna_chain_store[interactive_mna_chain_id] = interactive_mna_live_chain
		RunState.set_active_corporate_action_chains(interactive_mna_chain_store)

		GameManager.advance_day()
		await get_tree().process_frame
		var interactive_mna_meeting_visible: bool = false
		for interactive_mna_row_value in GameManager.get_corporate_meeting_snapshot().get("upcoming_rows", []):
			if typeof(interactive_mna_row_value) != TYPE_DICTIONARY:
				continue
			var interactive_mna_row: Dictionary = interactive_mna_row_value
			if (
				str(interactive_mna_row.get("id", "")) == interactive_mna_meeting_id and
				str(interactive_mna_row.get("chain_family", "")) == "strategic_merger_acquisition" and
				bool(interactive_mna_row.get("interactive_v1", false))
			):
				interactive_mna_meeting_visible = true
				break
		if not interactive_mna_meeting_visible:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the strategic M&A RUPSLB to appear as an interactive upcoming meeting after one Advance Day."
			}
		var interactive_mna_start_result: Dictionary = GameManager.start_corporate_meeting_session(interactive_mna_meeting_id)
		var interactive_mna_session_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(interactive_mna_meeting_id)
		if (
			not bool(interactive_mna_start_result.get("success", false)) or
			str(interactive_mna_session_snapshot.get("current_stage_id", "")) != "arrival" or
			str(interactive_mna_session_snapshot.get("presentation", {}).get("stage_labels", {}).get("agenda_reveal", "")) != "Deal Terms"
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected strategic M&A RUPSLB sessions to open with deal-term presentation copy."
			}
		var interactive_mna_vote_result: Dictionary = GameManager.submit_corporate_meeting_vote(interactive_mna_meeting_id, "", "agree")
		var interactive_mna_vote_summary: Dictionary = interactive_mna_vote_result.get("session", {}).get("result_summary", {})
		if not bool(interactive_mna_vote_result.get("success", false)) or not bool(interactive_mna_vote_summary.get("approved", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the strategic M&A RUPSLB agree vote to approve the deal."
			}
		GameManager.advance_day()
		await get_tree().process_frame
		var interactive_mna_after_vote_chain: Dictionary = RunState.get_active_corporate_action_chains().get(interactive_mna_chain_id, {})
		if (
			str(interactive_mna_after_vote_chain.get("stage", "")) != "execution" or
			not bool(RunState.get_corporate_meeting_sessions().get(interactive_mna_meeting_id, {}).get("consumed", false))
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected approved strategic M&A votes to move the chain into execution on the next simulated day."
			}
		GameManager.advance_day()
		await get_tree().process_frame
		var interactive_mna_application: Dictionary = {}
		for interactive_mna_application_value in RunState.last_day_results.get("corporate_action_applications", []):
			if typeof(interactive_mna_application_value) != TYPE_DICTIONARY:
				continue
			var interactive_mna_candidate_application: Dictionary = interactive_mna_application_value
			if str(interactive_mna_candidate_application.get("chain_id", "")) == interactive_mna_chain_id and str(interactive_mna_candidate_application.get("application_type", "")) == "strategic_merger_acquisition":
				interactive_mna_application = interactive_mna_candidate_application.duplicate(true)
				break
		var interactive_mna_holding_after: int = int(RunState.get_holding(interactive_mna_company_id).get("shares", 0))
		var interactive_mna_cash_after: float = float(RunState.player_portfolio.get("cash", 0.0))
		var interactive_mna_after_snapshot: Dictionary = GameManager.get_company_snapshot(interactive_mna_company_id, false, false, false)
		if (
			interactive_mna_application.is_empty() or
			interactive_mna_holding_after != 0 or
			interactive_mna_cash_after <= interactive_mna_cash_before or
			str(interactive_mna_after_snapshot.get("listing_status", "")) != "acquired_cashout" or
			not bool(interactive_mna_after_snapshot.get("trade_disabled", false))
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected approved interactive strategic M&A execution to cash out the player and disable trading."
			}
		var interactive_mna_trade_found: bool = false
		for interactive_mna_trade_index in range(RunState.trade_history.size() - 1, -1, -1):
			var interactive_mna_trade: Dictionary = RunState.trade_history[interactive_mna_trade_index]
			if str(interactive_mna_trade.get("company_id", "")) == interactive_mna_company_id and str(interactive_mna_trade.get("side", "")) == "mna_cashout":
				interactive_mna_trade_found = true
				break
		if not interactive_mna_trade_found or interactive_mna_holding_before <= 0:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected interactive strategic M&A execution to record an M&A cash-out history row."
			}

		RunState.load_from_dict(interactive_test_base_state)
		game_root._refresh_all()
		await get_tree().process_frame

		var mna_company_id: String = ""
		var mna_lot_cash: float = float(RunState.player_portfolio.get("cash", 0.0))
		for company_index in range(RunState.company_order.size()):
			var mna_candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(mna_candidate_company_id).get("has_live_chain", false)):
				continue
			if int(RunState.get_holding(mna_candidate_company_id).get("shares", 0)) > 0:
				continue
			var mna_candidate_runtime: Dictionary = RunState.get_company(mna_candidate_company_id)
			var mna_candidate_profile: Dictionary = mna_candidate_runtime.get("company_profile", {})
			if bool(mna_candidate_profile.get("trade_disabled", false)):
				continue
			var mna_candidate_definition: Dictionary = RunState.get_effective_company_definition(mna_candidate_company_id, false, false)
			var mna_candidate_financials: Dictionary = mna_candidate_definition.get("financials", {})
			var mna_candidate_price: float = float(mna_candidate_runtime.get("current_price", mna_candidate_definition.get("base_price", 0.0)))
			if float(mna_candidate_financials.get("shares_outstanding", mna_candidate_definition.get("shares_outstanding", 0.0))) <= 1000.0:
				continue
			if mna_candidate_price * float(GameManager.get_lot_size()) > mna_lot_cash:
				continue
			mna_company_id = mna_candidate_company_id
			break
		if mna_company_id.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find a chain-free company for strategic M&A execution coverage."
			}
		var mna_before_definition: Dictionary = RunState.get_effective_company_definition(mna_company_id, false, false)
		var mna_before_financials: Dictionary = mna_before_definition.get("financials", {})
		var mna_shares_before: float = float(mna_before_financials.get("shares_outstanding", mna_before_definition.get("shares_outstanding", 0.0)))
		var mna_free_float_before: float = float(mna_before_financials.get("free_float_pct", 0.0))
		var mna_buy_result: Dictionary = GameManager.buy_lots(mna_company_id, 1)
		if not bool(mna_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before strategic M&A execution coverage."
			}
		var mna_holding_before: int = int(RunState.get_holding(mna_company_id).get("shares", 0))
		var mna_cash_before: float = float(RunState.player_portfolio.get("cash", 0.0))
		var mna_force_result: Dictionary = GameManager.debug_force_strategic_mna_execution(mna_company_id)
		var mna_chain: Dictionary = mna_force_result.get("chain", {})
		var mna_chain_id: String = str(mna_chain.get("chain_id", ""))
		var mna_terms: Dictionary = mna_chain.get("mna_terms", {})
		if (
			not bool(mna_force_result.get("success", false)) or
			mna_chain_id.is_empty() or
			str(mna_chain.get("family", "")) != "strategic_merger_acquisition" or
			mna_terms.is_empty() or
			float(mna_terms.get("cashout_price", 0.0)) <= 0.0 or
			str(mna_terms.get("consideration_type", "")) != "cash"
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected strategic M&A debug forcing to create an executable cash acquisition chain with terms."
			}
		var mna_snapshot: Dictionary = GameManager.get_company_corporate_action_snapshot(mna_company_id)
		var mna_snapshot_terms: Dictionary = mna_snapshot.get("primary_chain", {}).get("mna_terms", {})
		if mna_snapshot_terms.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the corporate-action snapshot to expose strategic M&A terms."
			}

		GameManager.advance_day()
		await get_tree().process_frame
		var mna_application: Dictionary = {}
		for mna_application_value in RunState.last_day_results.get("corporate_action_applications", []):
			if typeof(mna_application_value) != TYPE_DICTIONARY:
				continue
			var mna_candidate_application: Dictionary = mna_application_value
			if str(mna_candidate_application.get("chain_id", "")) == mna_chain_id and str(mna_candidate_application.get("application_type", "")) == "strategic_merger_acquisition":
				mna_application = mna_candidate_application.duplicate(true)
				break
		if mna_application.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected strategic M&A execution to emit an application payload."
			}
		var mna_after_definition: Dictionary = RunState.get_effective_company_definition(mna_company_id, false, false)
		var mna_after_financials: Dictionary = mna_after_definition.get("financials", {})
		var mna_shares_after: float = float(mna_after_financials.get("shares_outstanding", mna_after_definition.get("shares_outstanding", 0.0)))
		var mna_free_float_after: float = float(mna_after_financials.get("free_float_pct", 0.0))
		if absf(mna_shares_after - mna_shares_before) > max(1.0, mna_shares_before * 0.001) or absf(mna_free_float_after - mna_free_float_before) > 0.01:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected strategic M&A cash acquisition to leave share count and free float structurally unchanged before delisting."
			}
		var mna_adjustment: Dictionary = {}
		for mna_adjustment_value in RunState.get_company(mna_company_id).get("company_profile", {}).get("corporate_action_adjustments", []):
			if typeof(mna_adjustment_value) == TYPE_DICTIONARY and str(mna_adjustment_value.get("type", "")) == "strategic_merger_acquisition":
				mna_adjustment = mna_adjustment_value.duplicate(true)
				break
		if mna_adjustment.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected strategic M&A execution to record a company share-structure adjustment."
			}
		var mna_holding_after: int = int(RunState.get_holding(mna_company_id).get("shares", 0))
		var mna_cash_after: float = float(RunState.player_portfolio.get("cash", 0.0))
		if (
			mna_holding_after != 0 or
			mna_cash_after <= mna_cash_before or
			int(mna_adjustment.get("player_old_shares", 0)) != mna_holding_before or
			str(mna_adjustment.get("player_cashout_status", "")) != "cashed_out" or
			float(mna_adjustment.get("player_cash_received", 0.0)) <= 0.0
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected strategic M&A player treatment to fully cash out the held position."
			}
		var mna_trade_found: bool = false
		for mna_trade_index in range(RunState.trade_history.size() - 1, -1, -1):
			var mna_trade: Dictionary = RunState.trade_history[mna_trade_index]
			if str(mna_trade.get("company_id", "")) == mna_company_id and str(mna_trade.get("side", "")) == "mna_cashout":
				mna_trade_found = true
				break
		if not mna_trade_found:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected strategic M&A execution to record an M&A cash-out portfolio history row."
			}
		var mna_after_snapshot: Dictionary = GameManager.get_company_snapshot(mna_company_id, false, false, false)
		if (
			str(mna_after_snapshot.get("listing_status", "")) != "acquired_cashout" or
			not bool(mna_after_snapshot.get("trade_disabled", false)) or
			str(mna_after_snapshot.get("impactability", {}).get("label", "")) != "Acquired" or
			mna_after_snapshot.get("acquisition_result", {}).is_empty()
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected completed strategic M&A to mark the company as acquired and trade-disabled."
			}
		var blocked_mna_rebuy: Dictionary = GameManager.estimate_buy_lots(mna_company_id, 1)
		if bool(blocked_mna_rebuy.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected acquired names to reject new buy estimates."
			}

		RunState.load_from_dict(interactive_test_base_state)
		game_root._refresh_all()
		await get_tree().process_frame

		var interactive_backdoor_company_id: String = ""
		var interactive_backdoor_lot_cash: float = float(RunState.player_portfolio.get("cash", 0.0))
		for company_index in range(RunState.company_order.size()):
			var interactive_backdoor_candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(interactive_backdoor_candidate_company_id).get("has_live_chain", false)):
				continue
			if int(RunState.get_holding(interactive_backdoor_candidate_company_id).get("shares", 0)) > 0:
				continue
			var interactive_backdoor_candidate_runtime: Dictionary = RunState.get_company(interactive_backdoor_candidate_company_id)
			var interactive_backdoor_candidate_profile: Dictionary = interactive_backdoor_candidate_runtime.get("company_profile", {})
			if bool(interactive_backdoor_candidate_profile.get("trade_disabled", false)):
				continue
			var interactive_backdoor_candidate_definition: Dictionary = RunState.get_effective_company_definition(interactive_backdoor_candidate_company_id, false, false)
			var interactive_backdoor_candidate_financials: Dictionary = interactive_backdoor_candidate_definition.get("financials", {})
			var interactive_backdoor_candidate_price: float = float(interactive_backdoor_candidate_runtime.get("current_price", interactive_backdoor_candidate_definition.get("base_price", 0.0)))
			if float(interactive_backdoor_candidate_financials.get("shares_outstanding", interactive_backdoor_candidate_definition.get("shares_outstanding", 0.0))) <= 1000.0:
				continue
			if interactive_backdoor_candidate_price * float(GameManager.get_lot_size()) > interactive_backdoor_lot_cash:
				continue
			interactive_backdoor_company_id = interactive_backdoor_candidate_company_id
			break
		if interactive_backdoor_company_id.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find a chain-free company for interactive backdoor listing coverage."
			}
		var interactive_backdoor_before_definition: Dictionary = RunState.get_effective_company_definition(interactive_backdoor_company_id, false, false)
		var interactive_backdoor_before_financials: Dictionary = interactive_backdoor_before_definition.get("financials", {})
		var interactive_backdoor_shares_before: float = float(interactive_backdoor_before_financials.get("shares_outstanding", interactive_backdoor_before_definition.get("shares_outstanding", 0.0)))
		var interactive_backdoor_free_float_before: float = float(interactive_backdoor_before_financials.get("free_float_pct", 0.0))
		var interactive_backdoor_buy_result: Dictionary = GameManager.buy_lots(interactive_backdoor_company_id, 1)
		if not bool(interactive_backdoor_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before the backdoor listing RUPSLB flow."
			}
		var interactive_backdoor_holding_before: int = int(RunState.get_holding(interactive_backdoor_company_id).get("shares", 0))
		var interactive_backdoor_cash_before: float = float(RunState.player_portfolio.get("cash", 0.0))
		var interactive_backdoor_schedule_result: Dictionary = GameManager.debug_schedule_next_day_backdoor_listing_rupslb(interactive_backdoor_company_id)
		var interactive_backdoor_chain: Dictionary = interactive_backdoor_schedule_result.get("chain", {})
		var interactive_backdoor_meeting: Dictionary = interactive_backdoor_schedule_result.get("meeting", {})
		var interactive_backdoor_chain_id: String = str(interactive_backdoor_chain.get("chain_id", ""))
		var interactive_backdoor_meeting_id: String = str(interactive_backdoor_meeting.get("id", ""))
		var interactive_backdoor_terms: Dictionary = interactive_backdoor_chain.get("backdoor_terms", {})
		if (
			not bool(interactive_backdoor_schedule_result.get("success", false)) or
			interactive_backdoor_chain_id.is_empty() or
			interactive_backdoor_meeting_id.is_empty() or
			str(interactive_backdoor_chain.get("family", "")) != "backdoor_listing" or
			str(interactive_backdoor_chain.get("expected_meeting_type", "")) != "rupslb" or
			interactive_backdoor_terms.is_empty() or
			int(interactive_backdoor_terms.get("new_shares", 0)) <= 0 or
			str(interactive_backdoor_terms.get("post_deal_name", "")).is_empty()
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected backdoor listing debug scheduling to create an interactive RUPSLB chain with asset-injection terms."
			}
		var interactive_backdoor_chain_store: Dictionary = RunState.get_active_corporate_action_chains()
		var interactive_backdoor_live_chain: Dictionary = interactive_backdoor_chain_store.get(interactive_backdoor_chain_id, {}).duplicate(true)
		var interactive_backdoor_live_terms: Dictionary = interactive_backdoor_live_chain.get("backdoor_terms", {}).duplicate(true)
		interactive_backdoor_live_terms["follow_on_rights_hint"] = true
		interactive_backdoor_live_terms["follow_on_rights_probability"] = 1.0
		interactive_backdoor_live_chain["backdoor_terms"] = interactive_backdoor_live_terms
		interactive_backdoor_live_chain["approval_odds"] = 0.99
		interactive_backdoor_live_chain["funding_pressure"] = 0.95
		interactive_backdoor_live_chain["frontrunner_strength"] = 0.95
		interactive_backdoor_live_chain["market_overpricing"] = 0.0
		interactive_backdoor_live_chain["management_stance"] = "confirm"
		interactive_backdoor_chain_store[interactive_backdoor_chain_id] = interactive_backdoor_live_chain
		RunState.set_active_corporate_action_chains(interactive_backdoor_chain_store)
		interactive_backdoor_terms = interactive_backdoor_live_terms.duplicate(true)

		GameManager.advance_day()
		await get_tree().process_frame
		var interactive_backdoor_meeting_visible: bool = false
		for interactive_backdoor_row_value in GameManager.get_corporate_meeting_snapshot().get("upcoming_rows", []):
			if typeof(interactive_backdoor_row_value) != TYPE_DICTIONARY:
				continue
			var interactive_backdoor_row: Dictionary = interactive_backdoor_row_value
			if (
				str(interactive_backdoor_row.get("id", "")) == interactive_backdoor_meeting_id and
				str(interactive_backdoor_row.get("chain_family", "")) == "backdoor_listing" and
				bool(interactive_backdoor_row.get("interactive_v1", false))
			):
				interactive_backdoor_meeting_visible = true
				break
		if not interactive_backdoor_meeting_visible:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the backdoor listing RUPSLB to appear as an interactive upcoming meeting after one Advance Day."
			}
		var interactive_backdoor_start_result: Dictionary = GameManager.start_corporate_meeting_session(interactive_backdoor_meeting_id)
		var interactive_backdoor_session_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(interactive_backdoor_meeting_id)
		if (
			not bool(interactive_backdoor_start_result.get("success", false)) or
			str(interactive_backdoor_session_snapshot.get("current_stage_id", "")) != "arrival" or
			str(interactive_backdoor_session_snapshot.get("presentation", {}).get("stage_labels", {}).get("agenda_reveal", "")) != "Asset Injection"
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected backdoor listing RUPSLB sessions to open with asset-injection presentation copy."
			}
		var interactive_backdoor_vote_result: Dictionary = GameManager.submit_corporate_meeting_vote(interactive_backdoor_meeting_id, "", "agree")
		var interactive_backdoor_vote_summary: Dictionary = interactive_backdoor_vote_result.get("session", {}).get("result_summary", {})
		if not bool(interactive_backdoor_vote_result.get("success", false)) or not bool(interactive_backdoor_vote_summary.get("approved", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the backdoor listing RUPSLB agree vote to approve the asset injection."
			}
		GameManager.advance_day()
		await get_tree().process_frame
		var interactive_backdoor_after_vote_chain: Dictionary = RunState.get_active_corporate_action_chains().get(interactive_backdoor_chain_id, {})
		if (
			str(interactive_backdoor_after_vote_chain.get("stage", "")) != "execution" or
			not bool(RunState.get_corporate_meeting_sessions().get(interactive_backdoor_meeting_id, {}).get("consumed", false))
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected approved backdoor listing votes to move the chain into execution on the next simulated day."
			}
		GameManager.advance_day()
		await get_tree().process_frame
		var interactive_backdoor_application: Dictionary = {}
		for interactive_backdoor_application_value in RunState.last_day_results.get("corporate_action_applications", []):
			if typeof(interactive_backdoor_application_value) != TYPE_DICTIONARY:
				continue
			var interactive_backdoor_candidate_application: Dictionary = interactive_backdoor_application_value
			if str(interactive_backdoor_candidate_application.get("chain_id", "")) == interactive_backdoor_chain_id and str(interactive_backdoor_candidate_application.get("application_type", "")) == "backdoor_listing":
				interactive_backdoor_application = interactive_backdoor_candidate_application.duplicate(true)
				break
		var interactive_backdoor_after_definition: Dictionary = RunState.get_effective_company_definition(interactive_backdoor_company_id, false, false)
		var interactive_backdoor_after_financials: Dictionary = interactive_backdoor_after_definition.get("financials", {})
		var interactive_backdoor_shares_after: float = float(interactive_backdoor_after_financials.get("shares_outstanding", interactive_backdoor_after_definition.get("shares_outstanding", 0.0)))
		var interactive_backdoor_free_float_after: float = float(interactive_backdoor_after_financials.get("free_float_pct", 0.0))
		var interactive_backdoor_holding_after: int = int(RunState.get_holding(interactive_backdoor_company_id).get("shares", 0))
		var interactive_backdoor_cash_after: float = float(RunState.player_portfolio.get("cash", 0.0))
		var interactive_backdoor_after_snapshot: Dictionary = GameManager.get_company_snapshot(interactive_backdoor_company_id, false, false, false)
		if (
			interactive_backdoor_application.is_empty() or
			str(interactive_backdoor_application.get("post_deal_name", "")) != str(interactive_backdoor_terms.get("post_deal_name", "")) or
			interactive_backdoor_application.get("post_deal_identity", {}).is_empty() or
			str(interactive_backdoor_application.get("follow_on_rights_chain_id", "")).is_empty() or
			interactive_backdoor_shares_after <= interactive_backdoor_shares_before or
			interactive_backdoor_free_float_after >= interactive_backdoor_free_float_before or
			interactive_backdoor_holding_after != interactive_backdoor_holding_before or
			absf(interactive_backdoor_cash_after - interactive_backdoor_cash_before) > 0.01 or
			str(interactive_backdoor_after_snapshot.get("listing_status", "listed")) != "listed" or
			bool(interactive_backdoor_after_snapshot.get("trade_disabled", false)) or
			str(interactive_backdoor_after_snapshot.get("name", "")) != str(interactive_backdoor_terms.get("post_deal_name", "")) or
			interactive_backdoor_after_snapshot.get("backdoor_listing_result", {}).is_empty()
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected approved interactive backdoor listing execution to rewrite identity, dilute structure, preserve player shares/cash, and keep the listing tradable."
			}
		var interactive_backdoor_trade_found: bool = false
		for interactive_backdoor_trade_index in range(RunState.trade_history.size() - 1, -1, -1):
			var interactive_backdoor_trade: Dictionary = RunState.trade_history[interactive_backdoor_trade_index]
			if str(interactive_backdoor_trade.get("company_id", "")) == interactive_backdoor_company_id and str(interactive_backdoor_trade.get("side", "")) == "backdoor_listing":
				interactive_backdoor_trade_found = true
				break
		if not interactive_backdoor_trade_found:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected interactive backdoor listing execution to record a held-share history row."
			}

		RunState.load_from_dict(interactive_test_base_state)
		game_root._refresh_all()
		await get_tree().process_frame

		var interactive_ceo_company_id: String = ""
		var interactive_ceo_lot_cash: float = float(RunState.player_portfolio.get("cash", 0.0))
		for company_index in range(RunState.company_order.size()):
			var interactive_ceo_candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(interactive_ceo_candidate_company_id).get("has_live_chain", false)):
				continue
			if int(RunState.get_holding(interactive_ceo_candidate_company_id).get("shares", 0)) > 0:
				continue
			var interactive_ceo_candidate_runtime: Dictionary = RunState.get_company(interactive_ceo_candidate_company_id)
			var interactive_ceo_candidate_profile: Dictionary = interactive_ceo_candidate_runtime.get("company_profile", {})
			if bool(interactive_ceo_candidate_profile.get("trade_disabled", false)):
				continue
			var interactive_ceo_candidate_definition: Dictionary = RunState.get_effective_company_definition(interactive_ceo_candidate_company_id, false, false)
			var interactive_ceo_candidate_price: float = float(interactive_ceo_candidate_runtime.get("current_price", interactive_ceo_candidate_definition.get("base_price", 0.0)))
			if interactive_ceo_candidate_price * float(GameManager.get_lot_size()) > interactive_ceo_lot_cash:
				continue
			interactive_ceo_company_id = interactive_ceo_candidate_company_id
			break
		if interactive_ceo_company_id.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find a chain-free company for interactive CEO-change coverage."
			}
		var interactive_ceo_before_snapshot: Dictionary = GameManager.get_company_snapshot(interactive_ceo_company_id, false, false, false)
		var interactive_ceo_before_name: String = _ceo_name_from_roster(interactive_ceo_before_snapshot.get("management_roster", []))
		var interactive_ceo_buy_result: Dictionary = GameManager.buy_lots(interactive_ceo_company_id, 1)
		if not bool(interactive_ceo_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before the CEO-change RUPSLB flow."
			}
		var interactive_ceo_holding_before: int = int(RunState.get_holding(interactive_ceo_company_id).get("shares", 0))
		var interactive_ceo_cash_before: float = float(RunState.player_portfolio.get("cash", 0.0))
		var interactive_ceo_schedule_result: Dictionary = GameManager.debug_schedule_next_day_ceo_change_rupslb(interactive_ceo_company_id)
		var interactive_ceo_chain: Dictionary = interactive_ceo_schedule_result.get("chain", {})
		var interactive_ceo_meeting: Dictionary = interactive_ceo_schedule_result.get("meeting", {})
		var interactive_ceo_chain_id: String = str(interactive_ceo_chain.get("chain_id", ""))
		var interactive_ceo_meeting_id: String = str(interactive_ceo_meeting.get("id", ""))
		var interactive_ceo_terms: Dictionary = interactive_ceo_chain.get("ceo_terms", {})
		if (
			not bool(interactive_ceo_schedule_result.get("success", false)) or
			interactive_ceo_chain_id.is_empty() or
			interactive_ceo_meeting_id.is_empty() or
			str(interactive_ceo_chain.get("family", "")) != "ceo_change" or
			str(interactive_ceo_chain.get("expected_meeting_type", "")) != "rupslb" or
			interactive_ceo_terms.is_empty() or
			str(interactive_ceo_terms.get("new_ceo_name", "")).is_empty() or
			str(interactive_ceo_terms.get("new_ceo_name", "")) == interactive_ceo_before_name
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected CEO-change debug scheduling to create an interactive RUPSLB chain with replacement CEO terms."
			}
		var interactive_ceo_chain_store: Dictionary = RunState.get_active_corporate_action_chains()
		var interactive_ceo_live_chain: Dictionary = interactive_ceo_chain_store.get(interactive_ceo_chain_id, {}).duplicate(true)
		interactive_ceo_live_chain["approval_odds"] = 0.99
		interactive_ceo_live_chain["funding_pressure"] = 0.95
		interactive_ceo_live_chain["frontrunner_strength"] = 0.95
		interactive_ceo_live_chain["market_overpricing"] = 0.0
		interactive_ceo_live_chain["management_stance"] = "confirm"
		interactive_ceo_chain_store[interactive_ceo_chain_id] = interactive_ceo_live_chain
		RunState.set_active_corporate_action_chains(interactive_ceo_chain_store)

		GameManager.advance_day()
		await get_tree().process_frame
		var interactive_ceo_meeting_visible: bool = false
		for interactive_ceo_row_value in GameManager.get_corporate_meeting_snapshot().get("upcoming_rows", []):
			if typeof(interactive_ceo_row_value) != TYPE_DICTIONARY:
				continue
			var interactive_ceo_row: Dictionary = interactive_ceo_row_value
			if (
				str(interactive_ceo_row.get("id", "")) == interactive_ceo_meeting_id and
				str(interactive_ceo_row.get("chain_family", "")) == "ceo_change" and
				bool(interactive_ceo_row.get("interactive_v1", false))
			):
				interactive_ceo_meeting_visible = true
				break
		if not interactive_ceo_meeting_visible:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the CEO-change RUPSLB to appear as an interactive upcoming meeting after one Advance Day."
			}
		var interactive_ceo_start_result: Dictionary = GameManager.start_corporate_meeting_session(interactive_ceo_meeting_id)
		var interactive_ceo_session_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(interactive_ceo_meeting_id)
		if (
			not bool(interactive_ceo_start_result.get("success", false)) or
			str(interactive_ceo_session_snapshot.get("current_stage_id", "")) != "arrival" or
			str(interactive_ceo_session_snapshot.get("presentation", {}).get("stage_labels", {}).get("agenda_reveal", "")) != "Leadership Slate"
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected CEO-change RUPSLB sessions to open with leadership-slate presentation copy."
			}
		var interactive_ceo_vote_result: Dictionary = GameManager.submit_corporate_meeting_vote(interactive_ceo_meeting_id, "", "agree")
		var interactive_ceo_vote_summary: Dictionary = interactive_ceo_vote_result.get("session", {}).get("result_summary", {})
		if not bool(interactive_ceo_vote_result.get("success", false)) or not bool(interactive_ceo_vote_summary.get("approved", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the CEO-change RUPSLB agree vote to approve the leadership slate."
			}
		GameManager.advance_day()
		await get_tree().process_frame
		var interactive_ceo_after_vote_chain: Dictionary = RunState.get_active_corporate_action_chains().get(interactive_ceo_chain_id, {})
		if (
			str(interactive_ceo_after_vote_chain.get("stage", "")) != "execution" or
			not bool(RunState.get_corporate_meeting_sessions().get(interactive_ceo_meeting_id, {}).get("consumed", false))
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected approved CEO-change votes to move the chain into execution on the next simulated day."
			}
		GameManager.advance_day()
		await get_tree().process_frame
		var interactive_ceo_application: Dictionary = {}
		for interactive_ceo_application_value in RunState.last_day_results.get("corporate_action_applications", []):
			if typeof(interactive_ceo_application_value) != TYPE_DICTIONARY:
				continue
			var interactive_ceo_candidate_application: Dictionary = interactive_ceo_application_value
			if str(interactive_ceo_candidate_application.get("chain_id", "")) == interactive_ceo_chain_id and str(interactive_ceo_candidate_application.get("application_type", "")) == "ceo_change":
				interactive_ceo_application = interactive_ceo_candidate_application.duplicate(true)
				break
		var interactive_ceo_after_snapshot: Dictionary = GameManager.get_company_snapshot(interactive_ceo_company_id, false, false, false)
		var interactive_ceo_after_name: String = _ceo_name_from_roster(interactive_ceo_after_snapshot.get("management_roster", []))
		var interactive_ceo_holding_after: int = int(RunState.get_holding(interactive_ceo_company_id).get("shares", 0))
		var interactive_ceo_cash_after: float = float(RunState.player_portfolio.get("cash", 0.0))
		if (
			interactive_ceo_application.is_empty() or
			interactive_ceo_after_name != str(interactive_ceo_terms.get("new_ceo_name", "")) or
			interactive_ceo_after_name == interactive_ceo_before_name or
			interactive_ceo_after_snapshot.get("ceo_change_result", {}).is_empty() or
			interactive_ceo_holding_after != interactive_ceo_holding_before or
			absf(interactive_ceo_cash_after - interactive_ceo_cash_before) > 0.01 or
			bool(interactive_ceo_after_snapshot.get("trade_disabled", false))
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected approved interactive CEO-change execution to replace the CEO, preserve player shares/cash, and keep the listing tradable."
			}
		var interactive_ceo_trade_found: bool = false
		for interactive_ceo_trade_index in range(RunState.trade_history.size() - 1, -1, -1):
			var interactive_ceo_trade: Dictionary = RunState.trade_history[interactive_ceo_trade_index]
			if str(interactive_ceo_trade.get("company_id", "")) == interactive_ceo_company_id and str(interactive_ceo_trade.get("side", "")) == "ceo_change":
				interactive_ceo_trade_found = true
				break
		if not interactive_ceo_trade_found:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected interactive CEO-change execution to record a held-share history row."
			}

		RunState.load_from_dict(interactive_test_base_state)
		game_root._refresh_all()
		await get_tree().process_frame

		var backdoor_company_id: String = ""
		var backdoor_lot_cash: float = float(RunState.player_portfolio.get("cash", 0.0))
		for company_index in range(RunState.company_order.size()):
			var backdoor_candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(backdoor_candidate_company_id).get("has_live_chain", false)):
				continue
			if int(RunState.get_holding(backdoor_candidate_company_id).get("shares", 0)) > 0:
				continue
			var backdoor_candidate_runtime: Dictionary = RunState.get_company(backdoor_candidate_company_id)
			var backdoor_candidate_profile: Dictionary = backdoor_candidate_runtime.get("company_profile", {})
			if bool(backdoor_candidate_profile.get("trade_disabled", false)):
				continue
			var backdoor_candidate_definition: Dictionary = RunState.get_effective_company_definition(backdoor_candidate_company_id, false, false)
			var backdoor_candidate_financials: Dictionary = backdoor_candidate_definition.get("financials", {})
			var backdoor_candidate_price: float = float(backdoor_candidate_runtime.get("current_price", backdoor_candidate_definition.get("base_price", 0.0)))
			if float(backdoor_candidate_financials.get("shares_outstanding", backdoor_candidate_definition.get("shares_outstanding", 0.0))) <= 1000.0:
				continue
			if backdoor_candidate_price * float(GameManager.get_lot_size()) > backdoor_lot_cash:
				continue
			backdoor_company_id = backdoor_candidate_company_id
			break
		if backdoor_company_id.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find a chain-free company for backdoor listing execution coverage."
			}
		var backdoor_before_definition: Dictionary = RunState.get_effective_company_definition(backdoor_company_id, false, false)
		var backdoor_before_financials: Dictionary = backdoor_before_definition.get("financials", {})
		var backdoor_shares_before: float = float(backdoor_before_financials.get("shares_outstanding", backdoor_before_definition.get("shares_outstanding", 0.0)))
		var backdoor_free_float_before: float = float(backdoor_before_financials.get("free_float_pct", 0.0))
		var backdoor_buy_result: Dictionary = GameManager.buy_lots(backdoor_company_id, 1)
		if not bool(backdoor_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before backdoor listing execution coverage."
			}
		var backdoor_holding_before: int = int(RunState.get_holding(backdoor_company_id).get("shares", 0))
		var backdoor_cash_before: float = float(RunState.player_portfolio.get("cash", 0.0))
		var backdoor_force_result: Dictionary = GameManager.debug_force_backdoor_listing_execution(backdoor_company_id)
		var backdoor_chain: Dictionary = backdoor_force_result.get("chain", {})
		var backdoor_chain_id: String = str(backdoor_chain.get("chain_id", ""))
		var backdoor_terms: Dictionary = backdoor_chain.get("backdoor_terms", {})
		if (
			not bool(backdoor_force_result.get("success", false)) or
			backdoor_chain_id.is_empty() or
			str(backdoor_chain.get("family", "")) != "backdoor_listing" or
			backdoor_terms.is_empty() or
			int(backdoor_terms.get("new_shares", 0)) <= 0 or
			float(backdoor_terms.get("new_shares_outstanding", 0.0)) <= backdoor_shares_before or
			str(backdoor_terms.get("post_deal_name", "")).is_empty() or
			str(backdoor_terms.get("post_deal_sector_id", "")).is_empty() or
			float(backdoor_terms.get("silent_accumulation_pct", 0.0)) <= 0.0 or
			not bool(backdoor_terms.get("follow_on_rights_hint", false)) or
			int(backdoor_terms.get("sponsor_lockup_days", 0)) < 30 or
			int(backdoor_terms.get("sponsor_lockup_days", 0)) > 45 or
			int(backdoor_terms.get("sponsor_locked_shares", 0)) != int(backdoor_terms.get("new_shares", 0)) or
			int(backdoor_terms.get("post_deal_milestone_count", 0)) < 3 or
			backdoor_terms.get("post_deal_milestone_plan", []).is_empty()
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected backdoor listing debug forcing to create executable identity, accumulation, and dilution terms."
			}
		var backdoor_snapshot: Dictionary = GameManager.get_company_corporate_action_snapshot(backdoor_company_id)
		var backdoor_snapshot_terms: Dictionary = backdoor_snapshot.get("primary_chain", {}).get("backdoor_terms", {})
		if backdoor_snapshot_terms.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the corporate-action snapshot to expose backdoor listing terms."
			}

		GameManager.advance_day()
		await get_tree().process_frame
		var backdoor_application: Dictionary = {}
		for backdoor_application_value in RunState.last_day_results.get("corporate_action_applications", []):
			if typeof(backdoor_application_value) != TYPE_DICTIONARY:
				continue
			var backdoor_candidate_application: Dictionary = backdoor_application_value
			if str(backdoor_candidate_application.get("chain_id", "")) == backdoor_chain_id and str(backdoor_candidate_application.get("application_type", "")) == "backdoor_listing":
				backdoor_application = backdoor_candidate_application.duplicate(true)
				break
		if backdoor_application.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected backdoor listing execution to emit an application payload."
			}
		if (
			str(backdoor_application.get("post_deal_name", "")) != str(backdoor_terms.get("post_deal_name", "")) or
			str(backdoor_application.get("post_deal_sector_id", "")) != str(backdoor_terms.get("post_deal_sector_id", "")) or
			backdoor_application.get("post_deal_identity", {}).is_empty() or
			float(backdoor_application.get("silent_accumulation_pct", 0.0)) <= 0.0 or
			str(backdoor_application.get("follow_on_rights_chain_id", "")).is_empty() or
			int(backdoor_application.get("sponsor_lockup_days", 0)) < 30 or
			int(backdoor_application.get("sponsor_lockup_days", 0)) > 45 or
			int(backdoor_application.get("sponsor_unlock_day_number", 0)) <= int(backdoor_application.get("day_index", 0)) or
			int(backdoor_application.get("post_deal_first_milestone_delay_days", 0)) <= 0 or
			backdoor_application.get("post_deal_milestone_plan", []).is_empty()
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected backdoor listing application payload to carry identity rewrite and silent accumulation data."
			}
		var backdoor_after_definition: Dictionary = RunState.get_effective_company_definition(backdoor_company_id, false, false)
		var backdoor_after_financials: Dictionary = backdoor_after_definition.get("financials", {})
		var backdoor_shares_after: float = float(backdoor_after_financials.get("shares_outstanding", backdoor_after_definition.get("shares_outstanding", 0.0)))
		var backdoor_free_float_after: float = float(backdoor_after_financials.get("free_float_pct", 0.0))
		if backdoor_shares_after <= backdoor_shares_before or backdoor_free_float_after >= backdoor_free_float_before:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected backdoor listing execution to increase shares outstanding and dilute public free float."
			}
		var backdoor_adjustment: Dictionary = {}
		for backdoor_adjustment_value in RunState.get_company(backdoor_company_id).get("company_profile", {}).get("corporate_action_adjustments", []):
			if typeof(backdoor_adjustment_value) == TYPE_DICTIONARY and str(backdoor_adjustment_value.get("type", "")) == "backdoor_listing":
				backdoor_adjustment = backdoor_adjustment_value.duplicate(true)
				break
		if backdoor_adjustment.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected backdoor listing execution to record a company share-structure adjustment."
			}
		var backdoor_holding_after: int = int(RunState.get_holding(backdoor_company_id).get("shares", 0))
		var backdoor_cash_after: float = float(RunState.player_portfolio.get("cash", 0.0))
		if (
			backdoor_holding_after != backdoor_holding_before or
			absf(backdoor_cash_after - backdoor_cash_before) > 0.01 or
			int(backdoor_adjustment.get("player_shares", 0)) != backdoor_holding_before or
			str(backdoor_adjustment.get("player_treatment", "")) != "held_diluted" or
			float(backdoor_adjustment.get("player_ownership_after_pct", 0.0)) >= float(backdoor_adjustment.get("player_ownership_before_pct", 0.0))
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected backdoor listing player treatment to preserve shares and cash while diluting ownership."
			}
		var backdoor_trade_found: bool = false
		for backdoor_trade_index in range(RunState.trade_history.size() - 1, -1, -1):
			var backdoor_trade: Dictionary = RunState.trade_history[backdoor_trade_index]
			if str(backdoor_trade.get("company_id", "")) == backdoor_company_id and str(backdoor_trade.get("side", "")) == "backdoor_listing":
				backdoor_trade_found = true
				break
		if not backdoor_trade_found:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected backdoor listing execution to record a portfolio history note for held shares."
			}
		var backdoor_after_snapshot: Dictionary = GameManager.get_company_snapshot(backdoor_company_id, false, false, false)
		if (
			str(backdoor_after_snapshot.get("listing_status", "listed")) != "listed" or
			bool(backdoor_after_snapshot.get("trade_disabled", false)) or
			backdoor_after_snapshot.get("backdoor_listing_result", {}).is_empty()
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected completed backdoor listing to keep the shell listed and tradable with a profile result."
			}
		var backdoor_result_snapshot: Dictionary = backdoor_after_snapshot.get("backdoor_listing_result", {})
		var backdoor_lockup_snapshot: Dictionary = backdoor_after_snapshot.get("backdoor_sponsor_lockup", {})
		var backdoor_milestone_snapshot: Dictionary = backdoor_after_snapshot.get("backdoor_milestone_state", {})
		if (
			str(backdoor_after_snapshot.get("name", "")) != str(backdoor_terms.get("post_deal_name", "")) or
			str(backdoor_after_snapshot.get("sector_id", "")) != str(backdoor_terms.get("post_deal_sector_id", "")) or
			str(backdoor_after_snapshot.get("archetype_label", "")).is_empty() or
			backdoor_result_snapshot.get("post_deal_identity", {}).is_empty() or
			str(backdoor_result_snapshot.get("follow_on_rights_chain_id", "")).is_empty() or
			backdoor_result_snapshot.get("sponsor_lockup", {}).is_empty() or
			backdoor_lockup_snapshot.is_empty() or
			str(backdoor_lockup_snapshot.get("state", "")) != "locked" or
			int(backdoor_lockup_snapshot.get("lockup_days", 0)) < 30 or
			int(backdoor_lockup_snapshot.get("lockup_days", 0)) > 45 or
			backdoor_milestone_snapshot.is_empty() or
			str(backdoor_milestone_snapshot.get("state", "")) != "active" or
			backdoor_milestone_snapshot.get("milestone_plan", []).is_empty() or
			int(backdoor_milestone_snapshot.get("next_milestone_day_number", 0)) <= int(backdoor_application.get("day_index", 0)) or
			float(backdoor_after_snapshot.get("market_depth_context", {}).get("silent_accumulation_pct", 0.0)) <= 0.0
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected completed backdoor listing to rewrite identity, start a 30-45 day sponsor lock-up, and schedule post-deal milestones."
			}
		var backdoor_follow_on_chain_id: String = str(backdoor_result_snapshot.get("follow_on_rights_chain_id", ""))
		var linked_rights_chain: Dictionary = RunState.get_active_corporate_action_chains().get(backdoor_follow_on_chain_id, {})
		var linked_rights_terms: Dictionary = linked_rights_chain.get("rights_terms", {})
		if (
			linked_rights_chain.is_empty() or
			str(linked_rights_chain.get("family", "")) != "rights_issue" or
			not bool(linked_rights_terms.get("linked_backdoor_listing", false)) or
			str(linked_rights_terms.get("source_backdoor_chain_id", "")) != backdoor_chain_id or
			str(linked_rights_terms.get("funding_purpose", "")).is_empty() or
			float(linked_rights_terms.get("strategic_funding_unlock_pct", 0.0)) == 0.0 or
			float(linked_rights_terms.get("dilution_overhang_pct", 0.0)) <= 0.0
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected completed backdoor listing to spawn a linked follow-on rights issue chain."
			}
		var allowed_backdoor_rebuy: Dictionary = GameManager.estimate_buy_lots(backdoor_company_id, 1)
		if not bool(allowed_backdoor_rebuy.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected backdoor-listed names to remain buyable after execution."
			}

		var restructuring_company_id: String = ""
		var restructuring_lot_cash: float = float(RunState.player_portfolio.get("cash", 0.0))
		for company_index in range(RunState.company_order.size() - 1, -1, -1):
			var restructuring_candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(restructuring_candidate_company_id).get("has_live_chain", false)):
				continue
			if int(RunState.get_holding(restructuring_candidate_company_id).get("shares", 0)) > 0:
				continue
			var restructuring_candidate_runtime: Dictionary = RunState.get_company(restructuring_candidate_company_id)
			var restructuring_candidate_profile: Dictionary = restructuring_candidate_runtime.get("company_profile", {})
			if bool(restructuring_candidate_profile.get("trade_disabled", false)):
				continue
			var restructuring_candidate_definition: Dictionary = RunState.get_effective_company_definition(restructuring_candidate_company_id, false, false)
			var restructuring_candidate_financials: Dictionary = restructuring_candidate_definition.get("financials", {})
			var restructuring_candidate_price: float = float(restructuring_candidate_runtime.get("current_price", restructuring_candidate_definition.get("base_price", 0.0)))
			if float(restructuring_candidate_financials.get("shares_outstanding", restructuring_candidate_definition.get("shares_outstanding", 0.0))) <= 1000.0:
				continue
			if restructuring_candidate_price * float(GameManager.get_lot_size()) > restructuring_lot_cash:
				continue
			restructuring_company_id = restructuring_candidate_company_id
			break
		if restructuring_company_id.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to find a chain-free company for restructuring execution coverage."
			}
		var restructuring_before_definition: Dictionary = RunState.get_effective_company_definition(restructuring_company_id, false, false)
		var restructuring_before_financials: Dictionary = restructuring_before_definition.get("financials", {})
		var restructuring_shares_before: float = float(restructuring_before_financials.get("shares_outstanding", restructuring_before_definition.get("shares_outstanding", 0.0)))
		var restructuring_free_float_before: float = float(restructuring_before_financials.get("free_float_pct", 0.0))
		var restructuring_buy_result: Dictionary = GameManager.buy_lots(restructuring_company_id, 1)
		if not bool(restructuring_buy_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected to buy one lot before restructuring execution coverage."
			}
		var restructuring_holding_before: int = int(RunState.get_holding(restructuring_company_id).get("shares", 0))
		var restructuring_cash_before: float = float(RunState.player_portfolio.get("cash", 0.0))
		var restructuring_force_result: Dictionary = GameManager.debug_force_restructuring_execution(restructuring_company_id)
		var restructuring_chain: Dictionary = restructuring_force_result.get("chain", {})
		var restructuring_chain_id: String = str(restructuring_chain.get("chain_id", ""))
		var restructuring_terms: Dictionary = restructuring_chain.get("restructuring_terms", {})
		if (
			not bool(restructuring_force_result.get("success", false)) or
			restructuring_chain_id.is_empty() or
			str(restructuring_chain.get("family", "")) != "restructuring" or
			restructuring_terms.is_empty() or
			float(restructuring_terms.get("debt_reduction_pct", 0.0)) <= 0.0 or
			float(restructuring_terms.get("debt_conversion_pct", 0.0)) <= 0.0 or
			int(restructuring_terms.get("new_shares", 0)) <= 0
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected restructuring debug forcing to create executable debt relief and conversion terms."
			}
		var restructuring_snapshot: Dictionary = GameManager.get_company_corporate_action_snapshot(restructuring_company_id)
		if restructuring_snapshot.get("primary_chain", {}).get("restructuring_terms", {}).is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the corporate-action snapshot to expose restructuring terms."
			}

		GameManager.advance_day()
		await get_tree().process_frame
		var restructuring_application: Dictionary = {}
		for restructuring_application_value in RunState.last_day_results.get("corporate_action_applications", []):
			if typeof(restructuring_application_value) != TYPE_DICTIONARY:
				continue
			var restructuring_candidate_application: Dictionary = restructuring_application_value
			if str(restructuring_candidate_application.get("chain_id", "")) == restructuring_chain_id and str(restructuring_candidate_application.get("application_type", "")) == "restructuring":
				restructuring_application = restructuring_candidate_application.duplicate(true)
				break
		if restructuring_application.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected restructuring execution to emit an application payload."
			}
		var restructuring_after_definition: Dictionary = RunState.get_effective_company_definition(restructuring_company_id, false, false)
		var restructuring_after_financials: Dictionary = restructuring_after_definition.get("financials", {})
		var restructuring_shares_after: float = float(restructuring_after_financials.get("shares_outstanding", restructuring_after_definition.get("shares_outstanding", 0.0)))
		var restructuring_free_float_after: float = float(restructuring_after_financials.get("free_float_pct", 0.0))
		if restructuring_shares_after <= restructuring_shares_before or restructuring_free_float_after >= restructuring_free_float_before:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected restructuring execution to issue creditor shares and dilute public free float."
			}
		var restructuring_adjustment: Dictionary = {}
		for restructuring_adjustment_value in RunState.get_company(restructuring_company_id).get("company_profile", {}).get("corporate_action_adjustments", []):
			if typeof(restructuring_adjustment_value) == TYPE_DICTIONARY and str(restructuring_adjustment_value.get("type", "")) == "restructuring":
				restructuring_adjustment = restructuring_adjustment_value.duplicate(true)
				break
		if restructuring_adjustment.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected restructuring execution to record a company adjustment."
			}
		var restructuring_holding_after: int = int(RunState.get_holding(restructuring_company_id).get("shares", 0))
		var restructuring_cash_after: float = float(RunState.player_portfolio.get("cash", 0.0))
		if (
			restructuring_holding_after != restructuring_holding_before or
			absf(restructuring_cash_after - restructuring_cash_before) > 0.01 or
			str(restructuring_adjustment.get("player_treatment", "")) != "held_diluted" or
			float(restructuring_adjustment.get("player_ownership_after_pct", 0.0)) >= float(restructuring_adjustment.get("player_ownership_before_pct", 0.0))
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected restructuring player treatment to preserve shares and cash while diluting ownership."
			}
		var restructuring_after_snapshot: Dictionary = GameManager.get_company_snapshot(restructuring_company_id, false, false, false)
		if (
			restructuring_after_snapshot.get("restructuring_result", {}).is_empty() or
			bool(restructuring_after_snapshot.get("trade_disabled", false)) or
			str(restructuring_after_snapshot.get("market_depth_context", {}).get("restructuring_state", "")) != "watch"
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected completed restructuring to persist a watch state while keeping the stock tradable."
			}

		RunState.load_from_dict(interactive_test_base_state)
		game_root._refresh_all()
		await get_tree().process_frame

	var initial_news_snapshot: Dictionary = GameManager.get_news_snapshot()
	if _count_unlocked_rows(initial_news_snapshot.get("outlets", [])) != 1:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected News to start with only intel level 1 unlocked."
		}
	var initial_social_snapshot: Dictionary = GameManager.get_twooter_snapshot()
	var initial_social_accounts: Array = initial_social_snapshot.get("accounts", [])
	var unlocked_social_tiers: Dictionary = {}
	for social_account_value in initial_social_accounts:
		var social_account: Dictionary = social_account_value
		if bool(social_account.get("unlocked", false)):
			unlocked_social_tiers[int(social_account.get("tier", 0))] = true
	if (
		int(initial_social_snapshot.get("access_tier", 0)) != 4
		or initial_social_accounts.is_empty()
		or _count_unlocked_rows(initial_social_accounts) != initial_social_accounts.size()
		or not unlocked_social_tiers.has(1)
		or not unlocked_social_tiers.has(2)
		or not unlocked_social_tiers.has(3)
		or not unlocked_social_tiers.has(4)
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter to start with full public account access across tiers 1-4."
		}

	var twooter_legacy_base_state: Dictionary = RunState.to_save_dict()
	var twooter_legacy_state: Dictionary = twooter_legacy_base_state.duplicate(true)
	twooter_legacy_state.erase("twooter_social_state")
	RunState.load_from_dict(twooter_legacy_state)
	if (
		not RunState.get_twooter_social_state().has("account_states")
		or int(GameManager.get_twooter_snapshot().get("access_tier", 0)) != 4
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected old saves without twooter_social_state to load with full Twooter access and default social state."
		}
	RunState.load_from_dict(twooter_legacy_base_state)

	var initial_academy_snapshot: Dictionary = GameManager.get_academy_snapshot("technical", "quiz")
	if not bool(initial_academy_snapshot.get("quiz", {}).get("locked", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Technical Academy quiz to start locked."
		}

	var life_validation: String = await _validate_life_smoke(game_root, life_app_button, life_window, desktop_layer)
	if not life_validation.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": life_validation
		}

	var thesis_board_validation: String = await _validate_thesis_board_smoke(game_root, thesis_app_button, desktop_layer)
	if not thesis_board_validation.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": thesis_board_validation
		}

	academy_app_button.emit_signal("pressed")
	await get_tree().process_frame
	var academy_available: bool = GameManager.is_academy_available()
	var academy_window_missing: bool = academy_window == null
	var academy_window_visible: bool = academy_window.visible if academy_window != null else false
	var academy_app_open: bool = game_root.is_desktop_app_open("academy")
	var academy_active_app: String = str(game_root.get_active_desktop_app_id())
	var academy_label_text: String = str(academy_app_label.text if academy_app_label != null else "<missing>")
	var academy_tooltip_text: String = str(academy_app_button.tooltip_text if academy_app_button != null else "<missing>")
	if (
		academy_available or
		academy_window_missing or
		academy_window_visible or
		academy_app_open or
		academy_active_app == "academy" or
		academy_app_label == null or
		academy_label_text.find("COMING SOON") < 0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Academy icon to stay visible but release-locked as Coming Soon. available=%s window_null=%s window_visible=%s app_open=%s active=%s label=%s tooltip=%s" % [
				str(academy_available),
				str(academy_window_missing),
				str(academy_window_visible),
				str(academy_app_open),
				academy_active_app,
				academy_label_text,
				academy_tooltip_text
			]
		}

	var academy_text_block: PanelContainer = game_root._build_academy_content_block({
		"type": "text",
		"heading": "Smoke Content Block",
		"body": "Academy content blocks render without replacing the quiz/check system.\n\n| Signal | Read |\n|---|---|\n| OCF | Positive cash |\n| Debt | Controlled risk |",
		"infoboxes": [{"title": "Smoke Infobox", "body": "Nested notes render inside text cards."}],
		"images": [{"asset_path": "res://assets/academy/lessons/smoke_missing_inline_image.png", "caption": "Inline missing images fall back safely.", "alt": "Missing inline smoke image"}]
	}) as PanelContainer
	var academy_key_insights_block: PanelContainer = game_root._build_academy_content_block({
		"type": "key_insights",
		"title": "Smoke Key Insights",
		"bullets": ["Blue insight cards render.", "Bullets stay readable."]
	}) as PanelContainer
	var academy_image_block: PanelContainer = game_root._build_academy_content_block({
		"type": "image",
		"asset_path": "res://assets/academy/lessons/smoke_missing_image.png",
		"caption": "Missing images should fall back safely.",
		"alt": "Missing smoke image"
	}) as PanelContainer
	var academy_text_title: Label = academy_text_block.find_child("AcademyTextBlockTitle", true, false) as Label
	var academy_infobox_card: PanelContainer = academy_text_block.find_child("AcademyInfoboxCard", true, false) as PanelContainer
	var academy_markdown_table: PanelContainer = academy_text_block.find_child("AcademyMarkdownTable", true, false) as PanelContainer
	var academy_inline_image_placeholder: Label = academy_text_block.find_child("AcademyTextInlineImagePlaceholder", true, false) as Label
	var academy_image_placeholder: Label = academy_image_block.find_child("AcademyInlineImagePlaceholder", true, false) as Label
	var academy_content_blocks_ok: bool = (
		academy_text_block != null and
		academy_text_title != null and
		academy_text_title.get_theme_font_size("font_size") == 16 and
		academy_infobox_card != null and
		academy_markdown_table != null and
		academy_inline_image_placeholder != null and
		academy_inline_image_placeholder.text == "MISSING IMAGE" and
		academy_key_insights_block != null and
		academy_image_placeholder != null and
		academy_image_placeholder.text == "MISSING IMAGE"
	)
	academy_text_block.queue_free()
	academy_key_insights_block.queue_free()
	academy_image_block.queue_free()
	if not academy_content_blocks_ok:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Academy content_blocks to render text cards, markdown tables, inline text images, nested infoboxes, key insights, and missing-image placeholders."
		}

	var academy_quiz_option := OptionButton.new()
	academy_quiz_option.add_item("Readable answer choice")
	game_root._style_academy_quiz_option_button(academy_quiz_option)
	var academy_quiz_submit := Button.new()
	academy_quiz_submit.text = "Submit Quiz"
	game_root._style_academy_quiz_submit_button(academy_quiz_submit)
	var academy_quiz_option_style: StyleBoxFlat = academy_quiz_option.get_theme_stylebox("normal") as StyleBoxFlat
	var academy_quiz_popup_style: StyleBoxFlat = academy_quiz_option.get_popup().get_theme_stylebox("panel") as StyleBoxFlat
	var academy_quiz_submit_style: StyleBoxFlat = academy_quiz_submit.get_theme_stylebox("normal") as StyleBoxFlat
	var academy_option_font_tone: float = academy_quiz_option.get_theme_color("font_color").r + academy_quiz_option.get_theme_color("font_color").g + academy_quiz_option.get_theme_color("font_color").b
	var academy_option_fill_tone: float = academy_quiz_option_style.bg_color.r + academy_quiz_option_style.bg_color.g + academy_quiz_option_style.bg_color.b if academy_quiz_option_style != null else 0.0
	var academy_popup_fill_tone: float = academy_quiz_popup_style.bg_color.r + academy_quiz_popup_style.bg_color.g + academy_quiz_popup_style.bg_color.b if academy_quiz_popup_style != null else 0.0
	var academy_submit_font_tone: float = academy_quiz_submit.get_theme_color("font_color").r + academy_quiz_submit.get_theme_color("font_color").g + academy_quiz_submit.get_theme_color("font_color").b
	var academy_submit_fill_tone: float = academy_quiz_submit_style.bg_color.r + academy_quiz_submit_style.bg_color.g + academy_quiz_submit_style.bg_color.b if academy_quiz_submit_style != null else 3.0
	var academy_quiz_controls_ok: bool = (
		academy_quiz_option_style != null and
		academy_quiz_popup_style != null and
		academy_quiz_submit_style != null and
		academy_option_fill_tone > 2.2 and
		academy_option_font_tone < 1.3 and
		academy_popup_fill_tone > 2.4 and
		academy_submit_fill_tone < 1.3 and
		academy_submit_font_tone > 2.4
	)
	academy_quiz_option.queue_free()
	academy_quiz_submit.queue_free()
	if not academy_quiz_controls_ok:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Academy quiz dropdowns and submit buttons to use readable contrast."
		}

	var coming_soon_snapshot: Dictionary = GameManager.get_academy_snapshot("transactional", "")
	if not bool(coming_soon_snapshot.get("coming_soon", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected unavailable Academy categories to show coming-soon states."
		}

	var mindset_academy_snapshot: Dictionary = GameManager.get_academy_snapshot("mindset", "")
	if (
		bool(mindset_academy_snapshot.get("coming_soon", true)) or
		mindset_academy_snapshot.get("sections", []).size() != 14 or
		int(mindset_academy_snapshot.get("quiz", {}).get("question_count", 0)) != 5
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Mindset Academy to be playable with twelve lessons, final challenge, glossary, and five final challenge questions."
		}

	var mindset_category: Dictionary = {}
	for category_value in DataRepository.get_academy_catalog().get("categories", []):
		var category: Dictionary = category_value
		if str(category.get("id", "")) == "mindset":
			mindset_category = category
			break
	var mindset_sections: Array = mindset_category.get("sections", [])
	var first_mindset_lesson: Dictionary = mindset_sections[0] if mindset_sections.size() > 0 else {}
	var first_mindset_blocks: Array = first_mindset_lesson.get("content_blocks", [])
	var first_mindset_check: Dictionary = first_mindset_lesson.get("checks", [])[0] if not first_mindset_lesson.get("checks", []).is_empty() else {}
	var mindset_lesson_count: int = 0
	var mindset_scenario_check_count: int = 0
	var mindset_system_unlock_count: int = 0
	var mindset_visible_scenario_block_count: int = 0
	var mindset_visible_unlock_block_count: int = 0
	for section_value in mindset_sections:
		var mindset_section: Dictionary = section_value
		if str(mindset_section.get("kind", "")) != "lesson":
			continue
		mindset_lesson_count += 1
		var mindset_section_checks: Array = mindset_section.get("checks", [])
		if mindset_section_checks.size() == 1:
			var mindset_scenario_check: Dictionary = mindset_section_checks[0]
			if (
				str(mindset_scenario_check.get("title", "")) == "Scenario Check" and
				not str(mindset_scenario_check.get("scenario", "")).strip_edges().is_empty() and
				not str(mindset_scenario_check.get("question", "")).strip_edges().is_empty()
			):
				mindset_scenario_check_count += 1
		if str(mindset_section.get("system_unlocks", {}).get("steam_status", "")) == "reserved":
			mindset_system_unlock_count += 1
		for block_value in mindset_section.get("content_blocks", []):
			var mindset_block: Dictionary = block_value
			var mindset_block_heading: String = str(mindset_block.get("heading", ""))
			if mindset_block_heading.begins_with("Game Scenario"):
				mindset_visible_scenario_block_count += 1
			if mindset_block_heading == "Unlock" or mindset_block_heading == "Player Unlock":
				mindset_visible_unlock_block_count += 1
	if (
		str(mindset_category.get("source_document", "")) != "mindset_module_lesson_curriculum_and_quiz_bank.pdf" or
		str(mindset_category.get("source_extraction", "")) != "pdf_tounicode_streams" or
		first_mindset_blocks.size() < 4 or
		str(first_mindset_blocks[0].get("type", "")) != "text" or
		str(first_mindset_blocks[0].get("heading", "")) != "Learning Objective" or
		str(first_mindset_blocks[1].get("heading", "")) != "Key Concept" or
		str(first_mindset_blocks[2].get("heading", "")) != "Knowledge Card" or
		first_mindset_check.is_empty() or
		str(first_mindset_check.get("title", "")) != "Scenario Check" or
		str(first_mindset_check.get("question", "")) != "What is the best decision before taking this fast-moving trade?" or
		first_mindset_lesson.get("system_unlocks", {}).is_empty() or
		str(first_mindset_lesson.get("system_unlocks", {}).get("steam_status", "")) != "reserved" or
		mindset_lesson_count != 12 or
		mindset_scenario_check_count != 12 or
		mindset_system_unlock_count != 12 or
		mindset_visible_scenario_block_count != 0 or
		mindset_visible_unlock_block_count != 0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Mindset lessons to come from the PDF, hide unlocks as system metadata, and make every scenario its own quick check."
		}

	var locked_mindset_quiz_result: Dictionary = GameManager.submit_academy_quiz("mindset", {})
	if bool(locked_mindset_quiz_result.get("success", false)) or not bool(locked_mindset_quiz_result.get("locked", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Mindset quiz API to reject attempts before required reading is complete."
		}

	var mindset_required_section_ids: Array = []
	for required_id_value in mindset_category.get("quiz_required_section_ids", []):
		mindset_required_section_ids.append(str(required_id_value))
	if mindset_required_section_ids.size() != 12:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Mindset Academy to require twelve lesson sections before quiz unlock."
		}
	for required_section_id in mindset_required_section_ids:
		var read_mindset_result: Dictionary = GameManager.mark_academy_section_read("mindset", str(required_section_id))
		if not bool(read_mindset_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Mindset section %s to be markable as read." % str(required_section_id)
			}

	var unlocked_mindset_academy_snapshot: Dictionary = GameManager.get_academy_snapshot("mindset", "mindset_quiz")
	if bool(unlocked_mindset_academy_snapshot.get("quiz", {}).get("locked", true)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected reading required Mindset Academy sections to unlock the quiz."
		}

	var mindset_answers: Dictionary = _build_academy_answers(true, "mindset")
	var mindset_quiz_result: Dictionary = GameManager.submit_academy_quiz("mindset", mindset_answers)
	if (
		not bool(mindset_quiz_result.get("success", false)) or
		not bool(mindset_quiz_result.get("passed", false)) or
		not RunState.get_academy_progress().get("badges", []).has("mindset_basics")
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected passing the Mindset quiz to grant the Mindset Basics badge."
		}

	for mindset_glossary_query in ["FOMO", "cold money", "margin of safety"]:
		if GameManager.search_academy_glossary(str(mindset_glossary_query)).is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Academy glossary search to return Mindset term '%s'." % str(mindset_glossary_query)
			}

	var fundamental_academy_snapshot: Dictionary = GameManager.get_academy_snapshot("fundamental", "")
	if (
		bool(fundamental_academy_snapshot.get("coming_soon", true)) or
		fundamental_academy_snapshot.get("sections", []).size() != 20 or
		int(fundamental_academy_snapshot.get("quiz", {}).get("question_count", 0)) != 10
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Fundamental Academy to be playable with eighteen lessons, exam, glossary, and ten exam questions."
		}

	var fundamental_category: Dictionary = {}
	for category_value in DataRepository.get_academy_catalog().get("categories", []):
		var category: Dictionary = category_value
		if str(category.get("id", "")) == "fundamental":
			fundamental_category = category
			break
	var fundamental_sections: Array = fundamental_category.get("sections", [])
	var first_fundamental_lesson: Dictionary = fundamental_sections[0] if fundamental_sections.size() > 0 else {}
	var first_fundamental_blocks: Array = first_fundamental_lesson.get("content_blocks", [])
	var first_fundamental_check: Dictionary = first_fundamental_lesson.get("checks", [])[0] if not first_fundamental_lesson.get("checks", []).is_empty() else {}
	var fundamental_lesson_count: int = 0
	var fundamental_scenario_check_count: int = 0
	var fundamental_system_unlock_count: int = 0
	var fundamental_visible_scenario_block_count: int = 0
	var fundamental_visible_player_unlock_block_count: int = 0
	var fundamental_answer_spoiler_count: int = 0
	for section_value in fundamental_sections:
		var fundamental_section: Dictionary = section_value
		if str(fundamental_section.get("kind", "")) != "lesson":
			continue
		fundamental_lesson_count += 1
		var section_checks: Array = fundamental_section.get("checks", [])
		if section_checks.size() == 1:
			var scenario_check: Dictionary = section_checks[0]
			var scenario_text: String = str(scenario_check.get("scenario", ""))
			if (
				str(scenario_check.get("title", "")) == "Scenario Check" and
				not scenario_text.is_empty() and
				str(scenario_check.get("question", "")) != "Which statement shows whether a company earns profit during a period?"
			):
				fundamental_scenario_check_count += 1
			if scenario_text.contains("Best answer:") or scenario_text.contains("\nAnswer:"):
				fundamental_answer_spoiler_count += 1
		if str(fundamental_section.get("system_unlocks", {}).get("steam_status", "")) == "reserved":
			fundamental_system_unlock_count += 1
		for block_value in fundamental_section.get("content_blocks", []):
			var fundamental_block: Dictionary = block_value
			var block_heading: String = str(fundamental_block.get("heading", ""))
			if block_heading.begins_with("Game Scenario") or block_heading.begins_with("Boss Fight Scenario"):
				fundamental_visible_scenario_block_count += 1
			if block_heading == "Player Unlock":
				fundamental_visible_player_unlock_block_count += 1
	if (
		first_fundamental_blocks.size() < 4 or
		str(first_fundamental_blocks[0].get("type", "")) != "text" or
		str(first_fundamental_blocks[0].get("heading", "")) != "Core Concept" or
		str(first_fundamental_blocks[1].get("heading", "")) != "Learning Objectives" or
		str(first_fundamental_blocks[2].get("heading", "")) != "Key Explanation" or
		str(first_fundamental_blocks[3].get("heading", "")) == "Game Scenario" or
		str(first_fundamental_blocks[3].get("heading", "")) == "Player Unlock" or
		first_fundamental_check.is_empty() or
		str(first_fundamental_check.get("title", "")) != "Scenario Check" or
		str(first_fundamental_check.get("scenario", "")).is_empty() or
		str(first_fundamental_check.get("question", "")) != "Which company deserves deeper investigation first?" or
		first_fundamental_lesson.get("system_unlocks", {}).is_empty() or
		str(first_fundamental_lesson.get("system_unlocks", {}).get("steam_status", "")) != "reserved" or
		fundamental_lesson_count != 18 or
		fundamental_scenario_check_count != 18 or
		fundamental_system_unlock_count != 18 or
		fundamental_visible_scenario_block_count != 0 or
		fundamental_visible_player_unlock_block_count != 0 or
		fundamental_answer_spoiler_count != 0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Fundamental lessons to hide player unlocks as system metadata and make every game scenario its own spoiler-free quick check."
		}

	var locked_fundamental_quiz_result: Dictionary = GameManager.submit_academy_quiz("fundamental", {})
	if bool(locked_fundamental_quiz_result.get("success", false)) or not bool(locked_fundamental_quiz_result.get("locked", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Fundamental exam API to reject attempts before required reading is complete."
		}

	var fundamental_required_section_ids: Array = []
	for required_id_value in fundamental_category.get("quiz_required_section_ids", []):
		fundamental_required_section_ids.append(str(required_id_value))
	if fundamental_required_section_ids.size() != 18:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Fundamental Academy to require eighteen lesson sections before exam unlock."
		}
	for required_section_id in fundamental_required_section_ids:
		var read_fundamental_result: Dictionary = GameManager.mark_academy_section_read("fundamental", str(required_section_id))
		if not bool(read_fundamental_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Fundamental section %s to be markable as read." % str(required_section_id)
			}

	var unlocked_fundamental_academy_snapshot: Dictionary = GameManager.get_academy_snapshot("fundamental", "fundamental_quiz")
	if bool(unlocked_fundamental_academy_snapshot.get("quiz", {}).get("locked", true)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected reading required Fundamental Academy sections to unlock the exam."
		}

	var fundamental_answers: Dictionary = _build_academy_answers(true, "fundamental")
	var fundamental_quiz_result: Dictionary = GameManager.submit_academy_quiz("fundamental", fundamental_answers)
	if (
		not bool(fundamental_quiz_result.get("success", false)) or
		not bool(fundamental_quiz_result.get("passed", false)) or
		not RunState.get_academy_progress().get("badges", []).has("fundamental_analyst")
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected passing the Fundamental exam to grant the Fundamental Analyst badge."
		}

	for fundamental_glossary_query in ["Revenue", "OCF", "DER", "Backlog", "Related Party"]:
		if GameManager.search_academy_glossary(str(fundamental_glossary_query)).is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Academy glossary search to return Fundamental term '%s'." % str(fundamental_glossary_query)
			}

	var locked_quiz_result: Dictionary = GameManager.submit_academy_quiz("technical", {})
	if bool(locked_quiz_result.get("success", false)) or not bool(locked_quiz_result.get("locked", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Technical quiz API to reject attempts before required reading is complete."
		}

	var inline_result: Dictionary = GameManager.submit_academy_inline_check("technical", "intro", "intro_data", "price_volume")
	if not bool(inline_result.get("success", false)) or not bool(inline_result.get("correct", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Academy inline checks to accept and store correct answers."
		}

	var academy_required_section_ids: Array = []
	for category_value in DataRepository.get_academy_catalog().get("categories", []):
		var category: Dictionary = category_value
		if str(category.get("id", "")) != "technical":
			continue
		for required_id_value in category.get("quiz_required_section_ids", []):
			academy_required_section_ids.append(str(required_id_value))
	if academy_required_section_ids.is_empty():
		academy_required_section_ids = ["intro", "market_structure", "candlesticks", "patterns"]
	for required_section_id in academy_required_section_ids:
		var read_result: Dictionary = GameManager.mark_academy_section_read("technical", str(required_section_id))
		if not bool(read_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Academy section %s to be markable as read." % str(required_section_id)
			}

	var unlocked_academy_snapshot: Dictionary = GameManager.get_academy_snapshot("technical", "quiz")
	if bool(unlocked_academy_snapshot.get("quiz", {}).get("locked", true)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected reading required Technical Academy sections to unlock the Technical quiz."
		}

	var saved_academy_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(saved_academy_state)
	if bool(GameManager.get_academy_snapshot("technical", "quiz").get("quiz", {}).get("locked", true)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Academy read progress to persist through save/load."
		}

	var failing_answers: Dictionary = _build_academy_answers(false)
	var failing_quiz_result: Dictionary = GameManager.submit_academy_quiz("technical", failing_answers)
	if not bool(failing_quiz_result.get("success", false)) or bool(failing_quiz_result.get("passed", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Technical quiz to fail below 80 percent."
		}

	var passing_answers: Dictionary = _build_academy_answers(true)
	var passing_quiz_result: Dictionary = GameManager.submit_academy_quiz("technical", passing_answers)
	if (
		not bool(passing_quiz_result.get("success", false)) or
		not bool(passing_quiz_result.get("passed", false)) or
		not RunState.get_academy_progress().get("badges", []).has("technical_basics")
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected passing the Technical quiz to grant the Technical Basics badge."
		}

	var corporate_academy_snapshot: Dictionary = GameManager.get_academy_snapshot("corporate_action", "")
	if (
		bool(corporate_academy_snapshot.get("coming_soon", true)) or
		corporate_academy_snapshot.get("sections", []).size() != 6 or
		int(corporate_academy_snapshot.get("quiz", {}).get("question_count", 0)) != 5
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Corporate Action Academy to be playable with four lessons, quiz, glossary, and five quiz questions."
		}

	var locked_corporate_quiz_result: Dictionary = GameManager.submit_academy_quiz("corporate_action", {})
	if bool(locked_corporate_quiz_result.get("success", false)) or not bool(locked_corporate_quiz_result.get("locked", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Corporate Action quiz API to reject attempts before required reading is complete."
		}

	var corporate_required_section_ids: Array = []
	for category_value in DataRepository.get_academy_catalog().get("categories", []):
		var category: Dictionary = category_value
		if str(category.get("id", "")) != "corporate_action":
			continue
		for required_id_value in category.get("quiz_required_section_ids", []):
			corporate_required_section_ids.append(str(required_id_value))
	if corporate_required_section_ids.size() != 4:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Corporate Action Academy to require four lesson sections before quiz unlock."
		}
	for required_section_id in corporate_required_section_ids:
		var read_corporate_result: Dictionary = GameManager.mark_academy_section_read("corporate_action", str(required_section_id))
		if not bool(read_corporate_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Corporate Action section %s to be markable as read." % str(required_section_id)
			}

	var unlocked_corporate_academy_snapshot: Dictionary = GameManager.get_academy_snapshot("corporate_action", "quiz")
	if bool(unlocked_corporate_academy_snapshot.get("quiz", {}).get("locked", true)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected reading required Corporate Action Academy sections to unlock the quiz."
		}

	var corporate_answers: Dictionary = _build_academy_answers(true, "corporate_action")
	var corporate_quiz_result: Dictionary = GameManager.submit_academy_quiz("corporate_action", corporate_answers)
	if (
		not bool(corporate_quiz_result.get("success", false)) or
		not bool(corporate_quiz_result.get("passed", false)) or
		not RunState.get_academy_progress().get("badges", []).has("corporate_action_basics")
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected passing the Corporate Action quiz to grant the Corporate Action Basics badge."
		}

	for corporate_glossary_query in ["rupslb", "rights issue", "tender offer"]:
		if GameManager.search_academy_glossary(str(corporate_glossary_query)).is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Academy glossary search to return Corporate Action term '%s'." % str(corporate_glossary_query)
			}

	if GameManager.search_academy_glossary("support").is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Academy glossary search to return seeded technical terms."
		}

	game_root.close_desktop_app("academy")
	await get_tree().process_frame
	if not desktop_layer.visible or game_root.is_desktop_app_open("academy"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected closing the Academy desktop window to hide the app while keeping the desktop visible."
		}

	upgrades_app_button.emit_signal("pressed")
	await get_tree().process_frame
	if (
		upgrade_window == null or
		not upgrade_window.visible or
		not game_root.is_desktop_app_open("upgrades") or
		game_root.get_active_desktop_app_id() != "upgrades" or
		game_root.get_desktop_app_window_title("upgrades") != "Upgrades" or
		not _desktop_window_has_settings_brown_chrome(game_root, "UpgradesDesktopWindow") or
		upgrade_cards_vbox == null or
		upgrade_cards_vbox.get_child_count() < RunState.UPGRADE_TRACK_IDS.size()
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Upgrades icon to open a populated brown-framed shop window."
	}

	var console_saved_state: Dictionary = RunState.to_save_dict()
	var console_toggle_event: InputEventKey = InputEventKey.new()
	console_toggle_event.pressed = true
	console_toggle_event.keycode = 96
	game_root._input(console_toggle_event)
	await get_tree().process_frame
	var console_overlay: Control = game_root.find_child("ConsoleCommandOverlay", true, false) as Control
	var console_input: LineEdit = game_root.find_child("ConsoleCommandInput", true, false) as LineEdit
	if console_overlay == null or console_input == null or not console_overlay.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the backtick key to open the console command overlay."
		}

	var cash_before_console_command: float = float(RunState.player_portfolio.get("cash", 0.0))
	console_input.emit_signal("text_submitted", "cuankus")
	await get_tree().process_frame
	var expected_console_cash: float = cash_before_console_command + GameManager.CONSOLE_CASH_GRANT_AMOUNT
	if not is_equal_approx(float(RunState.player_portfolio.get("cash", 0.0)), expected_console_cash):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected console command cuankus to add Rp999.999.999.999 cash."
		}

	game_root._input(console_toggle_event)
	await get_tree().process_frame
	if console_overlay.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the backtick key to close the console command overlay."
		}

	game_root._input(console_toggle_event)
	await get_tree().process_frame
	console_input.emit_signal("text_submitted", "ordalbos")
	await get_tree().process_frame
	for upgraded_track_id in RunState.UPGRADE_TRACK_IDS:
		if RunState.get_upgrade_tier(str(upgraded_track_id)) != 1:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected console command ordalbos to max every upgrade track."
			}
	game_root._input(console_toggle_event)
	await get_tree().process_frame
	RunState.load_from_dict(console_saved_state)
	SaveManager.save_run(RunState.to_save_dict())
	game_root._refresh_all()
	await get_tree().process_frame

	SaveManager.flush_pending_save()
	var cash_before_upgrade: float = float(RunState.player_portfolio.get("cash", 0.0))
	var news_upgrade_button: Button = game_root.find_child("UpgradeBuyButton_news_content", true, false) as Button
	var upgrade_purchase_dialog: ConfirmationDialog = game_root.find_child("UpgradePurchaseDialog", true, false) as ConfirmationDialog
	if news_upgrade_button == null or upgrade_purchase_dialog == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Upgrades shop to expose a News Content buy button and confirmation dialog."
		}

	news_upgrade_button.emit_signal("pressed")
	await get_tree().process_frame
	if not upgrade_purchase_dialog.visible or RunState.get_upgrade_tier("news_content") != 4 or not is_equal_approx(float(RunState.player_portfolio.get("cash", 0.0)), cash_before_upgrade):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected pressing an upgrade button to ask for confirmation before spending cash."
		}

	var upgrade_purchase_body_label: Label = game_root.find_child("UpgradePurchaseBodyLabel", true, false) as Label
	var upgrade_purchase_content_panel: PanelContainer = game_root.find_child("UpgradePurchaseContentPanel", true, false) as PanelContainer
	var upgrade_purchase_panel_style: StyleBoxFlat = null
	if upgrade_purchase_content_panel != null:
		upgrade_purchase_panel_style = upgrade_purchase_content_panel.get_theme_stylebox("panel") as StyleBoxFlat
	var upgrade_purchase_text_color: Color = upgrade_purchase_body_label.get_theme_color("font_color") if upgrade_purchase_body_label != null else Color.WHITE
	var upgrade_purchase_text_luma: float = (upgrade_purchase_text_color.r + upgrade_purchase_text_color.g + upgrade_purchase_text_color.b) / 3.0
	var upgrade_purchase_bg_luma: float = -1.0
	if upgrade_purchase_panel_style != null:
		upgrade_purchase_bg_luma = (upgrade_purchase_panel_style.bg_color.r + upgrade_purchase_panel_style.bg_color.g + upgrade_purchase_panel_style.bg_color.b) / 3.0
	var upgrade_purchase_ok_button: Button = upgrade_purchase_dialog.get_ok_button()
	var upgrade_purchase_cancel_button: Button = upgrade_purchase_dialog.get_cancel_button()
	var upgrade_purchase_ok_style: StyleBoxFlat = upgrade_purchase_ok_button.get_theme_stylebox("normal") as StyleBoxFlat if upgrade_purchase_ok_button != null else null
	var upgrade_purchase_cancel_style: StyleBoxFlat = upgrade_purchase_cancel_button.get_theme_stylebox("normal") as StyleBoxFlat if upgrade_purchase_cancel_button != null else null
	var upgrade_purchase_ok_font_color: Color = upgrade_purchase_ok_button.get_theme_color("font_color") if upgrade_purchase_ok_button != null else Color.BLACK
	var upgrade_purchase_cancel_font_color: Color = upgrade_purchase_cancel_button.get_theme_color("font_color") if upgrade_purchase_cancel_button != null else Color.WHITE
	var upgrade_purchase_ok_font_luma: float = (upgrade_purchase_ok_font_color.r + upgrade_purchase_ok_font_color.g + upgrade_purchase_ok_font_color.b) / 3.0
	var upgrade_purchase_cancel_font_luma: float = (upgrade_purchase_cancel_font_color.r + upgrade_purchase_cancel_font_color.g + upgrade_purchase_cancel_font_color.b) / 3.0
	var upgrade_purchase_ok_bg_luma: float = (upgrade_purchase_ok_style.bg_color.r + upgrade_purchase_ok_style.bg_color.g + upgrade_purchase_ok_style.bg_color.b) / 3.0 if upgrade_purchase_ok_style != null else 1.0
	var upgrade_purchase_cancel_bg_luma: float = (upgrade_purchase_cancel_style.bg_color.r + upgrade_purchase_cancel_style.bg_color.g + upgrade_purchase_cancel_style.bg_color.b) / 3.0 if upgrade_purchase_cancel_style != null else 0.0
	if (
		upgrade_purchase_body_label == null or
		upgrade_purchase_content_panel == null or
		upgrade_purchase_panel_style == null or
		upgrade_purchase_bg_luma < 0.78 or
		upgrade_purchase_text_luma > 0.45 or
		upgrade_purchase_ok_style == null or
		upgrade_purchase_ok_bg_luma > 0.45 or
		upgrade_purchase_ok_font_luma < 0.75 or
		upgrade_purchase_cancel_style == null or
		upgrade_purchase_cancel_bg_luma < 0.65 or
		upgrade_purchase_cancel_font_luma > 0.45
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the upgrade confirmation popup to use readable desktop contrast."
		}

	upgrade_purchase_dialog.emit_signal("confirmed")
	await get_tree().process_frame
	if RunState.get_upgrade_tier("news_content") != 3:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected confirming News Content once to improve it to tier 3."
		}
	if float(RunState.player_portfolio.get("cash", 0.0)) >= cash_before_upgrade:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected buying an upgrade to spend cash."
		}
	if _count_unlocked_rows(GameManager.get_news_snapshot().get("outlets", [])) != 2:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected News Content tier 3 to unlock intel level 2."
		}
	if not SaveManager.has_pending_save():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected buying an upgrade to queue a pending autosave."
		}
	if not SaveManager.flush_pending_save() or SaveManager.has_pending_save():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the pending autosave flush to complete immediately."
		}
	var flushed_upgrade_save: Dictionary = SaveManager.load_run()
	if int(flushed_upgrade_save.get("upgrade_tiers", {}).get("news_content", 0)) != 3:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected flush_pending_save to persist the upgraded News Content tier."
		}
	var saved_upgrade_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(saved_upgrade_state)
	if RunState.get_upgrade_tier("news_content") != 3:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected upgrade tiers to persist through save/load."
		}
	if difficulty_id != GameManager.DEFAULT_DIFFICULTY_ID:
		RunState.player_portfolio["cash"] = cash_before_upgrade
		RunState.set_upgrade_tier("news_content", 4)

	if difficulty_id == GameManager.DEFAULT_DIFFICULTY_ID:
		var trading_fee_result: Dictionary = GameManager.purchase_upgrade("trading_fee")
		if not bool(trading_fee_result.get("success", false)) or GameManager.get_buy_fee_rate() >= RunState.BUY_FEE_RATE or GameManager.get_sell_fee_rate() >= RunState.SELL_FEE_RATE:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Trading Fee tier 3 to lower both buy and sell fee rates."
			}
		var fee_estimate: Dictionary = GameManager.estimate_buy_lots(str(RunState.company_order[0]), 1)
		if not is_equal_approx(float(fee_estimate.get("fee_rate", 0.0)), GameManager.get_buy_fee_rate()):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected buy estimates to use the upgraded trading fee rate."
			}

		var chart_upgrade_result: Dictionary = GameManager.purchase_upgrade("chart_indicators")
		if not bool(chart_upgrade_result.get("success", false)) or not GameManager.get_unlocked_chart_indicator_ids().has("sma_20"):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Chart Indicators tier 3 to unlock SMA 20."
			}

		var daily_action_result: Dictionary = GameManager.purchase_upgrade("daily_action_points")
		if not bool(daily_action_result.get("success", false)) or int(GameManager.get_daily_action_snapshot().get("limit", 0)) != 15:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Daily Action Points tier 3 to raise the daily limit to 15."
			}

		var twooter_result: Dictionary = GameManager.purchase_upgrade("twooter_content")
		if bool(twooter_result.get("success", false)) or int(GameManager.get_twooter_snapshot().get("access_tier", 0)) != 4:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected twooter_content to be removed from purchasable upgrades while Twooter stays full-access."
			}

		var cash_before_failed_upgrade: float = float(RunState.player_portfolio.get("cash", 0.0))
		RunState.player_portfolio["cash"] = 0.0
		var failed_upgrade_result: Dictionary = GameManager.purchase_upgrade("chart_indicators")
		RunState.player_portfolio["cash"] = cash_before_failed_upgrade
		if bool(failed_upgrade_result.get("success", false)) or RunState.get_upgrade_tier("chart_indicators") != 3:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected unaffordable upgrades to fail without improving the tier."
			}

	game_root.close_desktop_app("upgrades")
	await get_tree().process_frame
	if not desktop_layer.visible or game_root.is_desktop_app_open("upgrades"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected closing the Upgrades desktop window to hide the app while keeping the desktop visible."
		}

	var news_badge: Label = news_app_button.get_node_or_null("DesktopShortcutBadge") as Label
	var social_badge: Label = social_app_button.get_node_or_null("DesktopShortcutBadge") as Label
	var network_badge: Label = network_app_button.get_node_or_null("DesktopShortcutBadge") as Label

	news_app_button.emit_signal("pressed")
	await get_tree().process_frame
	await _wait_for_ui_animation_settle()
	if (
		news_window == null or
		not news_window.visible or
		not _desktop_window_animation_settled(game_root, "NewsBrowserDesktopWindow") or
		not game_root.is_desktop_app_open("news") or
		game_root.get_active_desktop_app_id() != "news" or
		game_root.get_desktop_app_window_title("news") != "News Browser" or
		not _desktop_window_has_settings_brown_chrome(game_root, "NewsBrowserDesktopWindow") or
		news_article_list == null or
		news_outlet_buttons == null or
		news_article_cards == null or
		news_detail_byline_label == null or
		news_detail_chips_label == null or
		news_detail_hero_frame == null or
		news_outlet_buttons.get_child_count() < 4 or
		news_article_list.item_count <= 0 or
		news_article_cards.get_child_count() <= 0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the News icon to open the brown-framed newspaper-style News app with outlet buttons, story cards, byline, and image frame."
		}

	var news_article_summary: Dictionary = news_article_list.get_item_metadata(0)
	var news_article_id: String = str(news_article_summary.get("id", ""))
	var news_article_record: Dictionary = GameManager.get_news_archive_article(news_article_id)
	if (
		news_article_record.is_empty() or
		str(news_article_record.get("author_name", "")).is_empty() or
		str(news_article_record.get("author_role", "")).is_empty() or
		str(news_article_record.get("public_section_label", "")).is_empty() or
		str(news_article_record.get("public_status_label", "")).is_empty() or
		str(news_article_record.get("public_story_angle", "")).is_empty() or
		str(news_article_record.get("public_confidence_label", "")).is_empty() or
		str(news_article_record.get("image_slot", "")).is_empty() or
		str(news_article_record.get("body", "")).split("\n\n", false).size() < 5 or
		news_detail_byline_label.text.find("By ") == -1 or
		news_detail_chips_label.text.is_empty()
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected News articles to preserve author, public label, and asset-slot metadata in the archive and detail view."
		}

	var card_headline_label: Label = game_root.find_child("NewsArticleCardHeadlineLabel", true, false) as Label
	var card_image_label: Label = game_root.find_child("NewsArticleCardImagePlaceholder", true, false) as Label
	var card_headline_color: Color = card_headline_label.get_theme_color("font_color") if card_headline_label != null else Color.WHITE
	var card_image_color: Color = card_image_label.get_theme_color("font_color") if card_image_label != null else Color.WHITE
	if (
		card_headline_label == null or
		card_image_label == null or
		((card_headline_color.r + card_headline_color.g + card_headline_color.b) / 3.0) > 0.72 or
		((card_image_color.r + card_image_color.g + card_image_color.b) / 3.0) > 0.72
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected newspaper card text and image placeholders to use readable dark colors."
		}

	var forbidden_news_terms: Array = ["source_chain_id", "chain_family", "meeting_id", "venue_type", "progress_label", "tone", "current_timeline_state", "management stance", "hidden_positioning", "formal_agenda_or_filing", "meeting_or_call"]
	var news_detail_meta_label: Label = game_root.find_child("NewsDetailMetaLabel", true, false) as Label
	var news_detail_body: RichTextLabel = game_root.find_child("NewsDetailBody", true, false) as RichTextLabel
	var news_detail_scroll: ScrollContainer = game_root.find_child("NewsDetailScroll", true, false) as ScrollContainer
	var news_detail_scroll_content: VBoxContainer = game_root.find_child("NewsDetailScrollContent", true, false) as VBoxContainer
	if (
		news_detail_scroll == null
		or news_detail_scroll_content == null
		or news_detail_body == null
		or not news_detail_scroll_content.is_ancestor_of(news_detail_body)
		or news_detail_scroll.size_flags_vertical != Control.SIZE_EXPAND_FILL
		or not news_detail_body.fit_content
		or news_detail_body.scroll_active
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the News article detail section to scroll as one full article column."
		}
	var visible_news_text: String = "%s\n%s\n%s\n%s" % [
		str(news_detail_meta_label.text if news_detail_meta_label != null else ""),
		str(news_detail_byline_label.text),
		str(news_detail_chips_label.text),
		str(news_detail_body.text if news_detail_body != null else "")
	]
	for forbidden_term in forbidden_news_terms:
		if visible_news_text.find(str(forbidden_term)) != -1:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected News detail UI to hide raw system metadata like %s." % str(forbidden_term)
			}

	var saved_news_archive_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(saved_news_archive_state)
	var reloaded_news_article: Dictionary = GameManager.get_news_archive_article(news_article_id)
	if (
		str(reloaded_news_article.get("author_name", "")) != str(news_article_record.get("author_name", "")) or
		str(reloaded_news_article.get("image_slot", "")) != str(news_article_record.get("image_slot", "")) or
		str(reloaded_news_article.get("public_story_angle", "")) != str(news_article_record.get("public_story_angle", "")) or
		str(reloaded_news_article.get("public_confidence_label", "")) != str(news_article_record.get("public_confidence_label", ""))
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected archived News author and asset-slot fields to survive save/load."
		}

	var source_leads: Array = GameManager.get_network_snapshot().get("discoveries", [])
	var has_news_source_lead: bool = false
	var news_source_lead: Dictionary = {}
	var news_source_lead_account_ids: Dictionary = {}
	for lead_value in source_leads:
		var lead: Dictionary = lead_value
		if str(lead.get("source_type", "")) == "news" and str(lead.get("source_id", "")) == news_article_id:
			has_news_source_lead = true
			if news_source_lead.is_empty():
				news_source_lead = lead
			var lead_account_id: String = str(lead.get("twooter_account_id", ""))
			if not lead_account_id.is_empty():
				news_source_lead_account_ids[lead_account_id] = true
	if not has_news_source_lead:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected at least one News article to surface a valid Network source lead."
		}
	var news_source_button: Button = game_root.find_child("NewsMeetContactButton", true, false) as Button
	var news_source_account_id: String = str(news_source_button.get_meta("twooter_account_id", "")) if news_source_button != null else ""
	var news_source_handle: String = str(news_source_button.get_meta("twooter_handle", "")) if news_source_button != null else ""
	if (
		news_source_button == null or
		not news_source_button.visible or
		news_source_button.disabled or
		news_source_account_id.is_empty() or
		not news_source_account_id.begins_with("network_") or
		news_source_handle.find("@") != 0 or
		news_source_button.text.find("Meet Source") != -1 or
		not news_source_lead_account_ids.has(news_source_account_id)
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected News source leads to expose a Twooter handle button instead of direct Meet Source."
		}
	news_source_button.emit_signal("pressed")
	await get_tree().process_frame
	await _wait_for_ui_animation_settle()
	var opened_source_profile_card: PanelContainer = game_root.find_child("SocialAccountProfileCard", true, false) as PanelContainer
	var opened_source_message_button: Button = game_root.find_child("SocialStartMessageButton", true, false) as Button
	var source_thread: Dictionary = GameManager.get_twooter_message_thread(news_source_account_id)
	var source_thread_account: Dictionary = source_thread.get("account", {}) if typeof(source_thread.get("account", {})) == TYPE_DICTIONARY else {}
	var source_social_profile: Dictionary = source_thread_account.get("social_profile", {}) if typeof(source_thread_account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var source_dialog_options: Array = source_thread.get("dialog_options", [])
	var source_first_option: Dictionary = source_dialog_options[0] if not source_dialog_options.is_empty() and typeof(source_dialog_options[0]) == TYPE_DICTIONARY else {}
	var source_first_tree_id: String = str(source_first_option.get("tree_id", ""))
	if (
		not game_root.is_desktop_app_open("social") or
		game_root.get_active_desktop_app_id() != "social" or
		opened_source_profile_card == null or
		str(opened_source_profile_card.get_meta("social_account_id", "")) != news_source_account_id or
		opened_source_message_button == null or
		str(source_social_profile.get("account_origin", "")) != "network_contact" or
		not source_first_tree_id.begins_with("network_") or
		str(source_first_option.get("player_text", "")).strip_edges().is_empty()
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the News source handle to open the matching Twooter source profile with contact-specific dialog options."
		}
	var source_loop_restore_state: Dictionary = RunState.to_save_dict()
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0
	var source_loop_contact_id: String = str(source_social_profile.get("network_contact_id", ""))
	if source_loop_contact_id.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected News-sourced Twooter accounts to keep contact id context."
		}
	var source_follow_result: Dictionary = GameManager.follow_twooter_account(news_source_account_id)
	var source_loop_thread: Dictionary = GameManager.get_twooter_message_thread(news_source_account_id)
	var source_loop_option: Dictionary = {}
	for option_value in source_loop_thread.get("dialog_options", []):
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option_row: Dictionary = option_value
		var option_action_id: String = str(option_row.get("action_id", option_row.get("id", "")))
		if option_action_id != "message_check_in" and bool(option_row.get("enabled", true)):
			source_loop_option = option_row
			break
	if source_loop_option.is_empty():
		var source_warm_state: Dictionary = RunState.get_twooter_social_state()
		var source_warm_accounts: Dictionary = source_warm_state.get("account_states", {})
		var source_warm_account_state: Dictionary = source_warm_accounts.get(news_source_account_id, {})
		source_warm_account_state["relationship"] = max(int(source_warm_account_state.get("relationship", 0)), 12)
		source_warm_accounts[news_source_account_id] = source_warm_account_state
		source_warm_state["account_states"] = source_warm_accounts
		RunState.set_twooter_social_state(source_warm_state)
		source_loop_thread = GameManager.get_twooter_message_thread(news_source_account_id)
		for option_value in source_loop_thread.get("dialog_options", []):
			if typeof(option_value) != TYPE_DICTIONARY:
				continue
			var warmed_option_row: Dictionary = option_value
			var warmed_action_id: String = str(warmed_option_row.get("action_id", warmed_option_row.get("id", "")))
			if warmed_action_id != "message_check_in" and bool(warmed_option_row.get("enabled", true)):
				source_loop_option = warmed_option_row
				break
	if source_loop_option.is_empty() or _contains_malformed_social_template_text(str(source_loop_option.get("player_text", ""))):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected News-sourced Twooter accounts to expose a usable Network-facing dialog option after enough relationship context."
		}
	var source_loop_ap_before: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var source_loop_journal_before: int = RunState.get_network_tip_journal().size()
	var source_loop_discovery_before: Dictionary = RunState.get_network_discoveries().get(source_loop_contact_id, {}).duplicate(true)
	var source_loop_result: Dictionary = GameManager.send_twooter_message(
		news_source_account_id,
		str(source_loop_option.get("action_id", "ask_source_private")),
		str(source_loop_option.get("thesis_id", "")),
		str(source_loop_option.get("player_text", ""))
	)
	var source_loop_ap_after: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var source_loop_state_after: Dictionary = RunState.get_twooter_social_state()
	var source_loop_rows: Array = source_loop_state_after.get("messages", {}).get(news_source_account_id, {}).get("rows", [])
	var source_loop_account_state: Dictionary = source_loop_state_after.get("account_states", {}).get(news_source_account_id, {})
	var source_loop_contact_runtime: Dictionary = RunState.get_network_contacts().get(source_loop_contact_id, {})
	var source_loop_discovery_after: Dictionary = RunState.get_network_discoveries().get(source_loop_contact_id, {})
	var source_loop_journal_after: int = RunState.get_network_tip_journal().size()
	var source_loop_row_texts: Array[String] = []
	for source_loop_row_value in source_loop_rows:
		if typeof(source_loop_row_value) == TYPE_DICTIONARY:
			source_loop_row_texts.append(str(source_loop_row_value.get("text", "")))
	var source_loop_visible_text: String = "%s\n%s\n%s" % [
		str(source_loop_option.get("player_text", "")),
		str(source_loop_result.get("reply_text", "")),
		"\n".join(source_loop_row_texts)
	]
	if (
		not bool(source_follow_result.get("success", false)) or
		not bool(source_loop_result.get("success", false)) or
		not bool(source_loop_result.get("network_changed", false)) or
		source_loop_ap_after <= source_loop_ap_before or
		source_loop_rows.size() < 2 or
		str(source_loop_rows[source_loop_rows.size() - 2].get("sender", "")) != "player" or
		str(source_loop_rows[source_loop_rows.size() - 1].get("sender", "")) != "account" or
		not bool(source_loop_account_state.get("following", false)) or
		not bool(source_loop_contact_runtime.get("met", false)) or
		str(source_loop_discovery_after.get("source_type", "")) != "twooter" or
		source_loop_journal_after <= source_loop_journal_before or
		source_loop_discovery_after == source_loop_discovery_before or
		_contains_malformed_social_template_text(source_loop_visible_text)
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the News -> Twooter handle -> source DM loop to spend AP, write message rows, and promote the source into Network."
		}
	RunState.load_from_dict(source_loop_restore_state)
	game_root.selected_social_account_id = ""
	game_root.selected_social_message_account_id = ""
	game_root.selected_social_feed_filter_id = "all"
	game_root.selected_social_view_id = "home"
	game_root.close_desktop_app("social")
	await get_tree().process_frame
	game_root._set_active_app("news")
	await get_tree().process_frame

	if news_article_list.item_count > 1:
		news_article_list.select(1)
		game_root._on_news_article_selected(1)
		await get_tree().process_frame
		var first_article_after_reload: String = str(news_article_list.get_item_metadata(0).get("id", ""))
		game_root._on_day_progressed(RunState.day_index + 1)
		await get_tree().process_frame
		if game_root.selected_news_article_id != first_article_after_reload:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected an open News window to reload to the latest story after day progress."
			}

	game_root.close_desktop_app("news")
	await get_tree().process_frame
	if not desktop_layer.visible or game_root.is_desktop_app_open("news"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected closing the News desktop window to hide the app while keeping the desktop visible."
		}

	var pre_badge_test_state: Dictionary = RunState.to_save_dict()
	var day_before_button_advance: int = RunState.day_index
	desktop_advance_day_button.emit_signal("pressed")
	desktop_advance_day_button.emit_signal("pressed")
	if not desktop_advance_day_button.disabled:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Advance Day button to disable immediately while processing."
		}
	var advance_disabled_text_color: Color = desktop_advance_day_button.get_theme_color("font_disabled_color")
	if ((advance_disabled_text_color.r + advance_disabled_text_color.g + advance_disabled_text_color.b) / 3.0) > 0.55:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Advance Day processing text to keep a dark, readable disabled font color."
		}
	for _frame in range(10):
		await get_tree().process_frame
	await _wait_for_ui_animation_settle()
	var daily_recap_dialog: Control = game_root.find_child("DailyRecapDialog", true, false) as Control
	var daily_recap_frame: PanelContainer = game_root.find_child("DailyRecapFrame", true, false) as PanelContainer
	var daily_recap_scrim: ColorRect = game_root.find_child("DailyRecapScrim", true, false) as ColorRect
	var daily_recap_body_label: Label = game_root.find_child("DailyRecapBodyLabel", true, false) as Label
	var daily_recap_continue_button: Button = game_root.find_child("DailyRecapContinueButton", true, false) as Button
	var daily_recap_content_panel: PanelContainer = game_root.find_child("DailyRecapContentPanel", true, false) as PanelContainer
	var daily_recap_title_bar: PanelContainer = game_root.find_child("DailyRecapTitleBar", true, false) as PanelContainer
	var recap_frame_style: StyleBoxFlat = null
	if daily_recap_frame != null:
		recap_frame_style = daily_recap_frame.get_theme_stylebox("panel") as StyleBoxFlat
	var recap_panel_style: StyleBoxFlat = null
	if daily_recap_content_panel != null:
		recap_panel_style = daily_recap_content_panel.get_theme_stylebox("panel") as StyleBoxFlat
	var recap_title_style: StyleBoxFlat = null
	if daily_recap_title_bar != null:
		recap_title_style = daily_recap_title_bar.get_theme_stylebox("panel") as StyleBoxFlat
	var recap_text_color: Color = daily_recap_body_label.get_theme_color("font_color") if daily_recap_body_label != null else Color.WHITE
	var recap_text_luma: float = (recap_text_color.r + recap_text_color.g + recap_text_color.b) / 3.0
	var recap_bg_luma: float = -1.0
	if recap_panel_style != null:
		recap_bg_luma = (recap_panel_style.bg_color.r + recap_panel_style.bg_color.g + recap_panel_style.bg_color.b) / 3.0
	if (
		RunState.day_index != day_before_button_advance + 1 or
		desktop_advance_day_button.disabled or
		desktop_advance_day_button.text != "ADVANCE DAY" or
		not _control_animation_settled(desktop_advance_day_button) or
		daily_recap_dialog == null or
		not daily_recap_dialog.visible or
		daily_recap_frame == null or
		daily_recap_continue_button == null or
		not _control_animation_settled(daily_recap_frame) or
		recap_frame_style == null or
		recap_frame_style.border_width_left != 0 or
		recap_frame_style.border_width_top != 0 or
		recap_frame_style.border_width_right != 0 or
		recap_frame_style.border_width_bottom != 0 or
		daily_recap_scrim == null or
		not is_equal_approx(daily_recap_scrim.color.a, 0.18) or
		daily_recap_body_label == null or
		daily_recap_body_label.text.find("Index Gorengan today:") == -1 or
		daily_recap_body_label.text.find("Market mood:") != -1 or
		daily_recap_body_label.text.find("Portfolio:") == -1 or
		daily_recap_body_label.text.find("Activity:") == -1 or
		daily_recap_body_label.text.find("Accumulation") != -1 or
		daily_recap_body_label.text.find("Distribution") != -1 or
		daily_recap_body_label.text.to_lower().find("zombie") != -1 or
		daily_recap_title_bar == null or
		recap_title_style == null or
		recap_title_style.bg_color != Color(0.509804, 0.231373, 0.0941176, 1) or
		daily_recap_content_panel == null or
		recap_panel_style == null or
		recap_bg_luma < 0.78 or
		recap_text_luma > 0.45
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected one guarded Advance Day press to advance once, re-enable the button, and show a useful daily recap modal."
		}
	var post_recap_saved_run: Dictionary = SaveManager.load_run()
	if SaveManager.has_pending_save() or int(post_recap_saved_run.get("day_index", -1)) != RunState.day_index:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the deferred Advance Day save to flush after the daily recap appears."
		}
	var early_special_events: Array = RunState.last_day_results.get("started_special_events", [])
	if not early_special_events.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected player-facing day 3 to stay free of forced macro special events."
		}
	var attention_director = ATTENTION_DIRECTOR_SYSTEM_SCRIPT.new()
	var day_three_attention_directives: Dictionary = attention_director.resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		2,
		GameManager.get_current_macro_state()
	)
	if bool(day_three_attention_directives.get("force_special_event", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Attention Director to keep player-facing day 3 free of forced macro events."
		}
	var day_six_attention_directives: Dictionary = attention_director.resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		5,
		GameManager.get_current_macro_state()
	)
	if (
		not bool(day_six_attention_directives.get("force_special_event", false)) or
		not bool(day_six_attention_directives.get("suppress_company_arc_start", false)) or
		not bool(day_six_attention_directives.get("suppress_market_scheduled_event", false)) or
		str(day_six_attention_directives.get("attention_tier", "")) != "headline_reserved"
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Attention Director to reserve player-facing day 6 for the first macro headline."
		}
	for director_key in ["selected_lane", "lane_scores", "difficulty_profile_id", "focus_company_ids", "focus_company_weights", "dirty_market_pressure", "market_stress_score", "best_company_attention_score"]:
		if not day_six_attention_directives.has(director_key):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Attention Director V2 directives to include internal key %s." % director_key
			}
	var attention_director_event_history: Array = RunState.event_history.duplicate(true)
	RunState.event_history = [{
		"event_id": "risk_off_headline",
		"scope": "market",
		"event_family": "macro",
		"category": "macro",
		"day_index": 11
	}]
	var digestion_attention_directives: Dictionary = attention_director.resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		12,
		GameManager.get_current_macro_state()
	)
	if (
		str(digestion_attention_directives.get("attention_tier", "")) != "digestion" or
		not bool(digestion_attention_directives.get("suppress_special_event", false)) or
		not bool(digestion_attention_directives.get("suppress_company_arc_start", false)) or
		not bool(digestion_attention_directives.get("suppress_market_scheduled_event", false))
	):
		RunState.event_history = attention_director_event_history
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Attention Director to create a digestion cooldown after a headline day."
		}
	RunState.event_history = []
	var quiet_attention_directives: Dictionary = attention_director.resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		12,
		GameManager.get_current_macro_state()
	)
	if (
		str(quiet_attention_directives.get("attention_tier", "")) != "clue_due" or
		not bool(quiet_attention_directives.get("force_company_arc_start", false)) or
		float(quiet_attention_directives.get("company_arc_probability_multiplier", 0.0)) <= 1.0 or
		float(quiet_attention_directives.get("scheduled_event_probability_multiplier", 0.0)) <= 1.0
	):
		RunState.event_history = attention_director_event_history
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Attention Director to raise clue pressure after a quiet stretch."
		}
	RunState.event_history = [{
		"event_id": "geopolitical_turmoil",
		"scope": "market",
		"event_family": "special",
		"category": "special",
		"day_index": 8
	}]
	var macro_cooldown_attention_directives: Dictionary = attention_director.resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		12,
		GameManager.get_current_macro_state()
	)
	if (
		not bool(macro_cooldown_attention_directives.get("suppress_special_event", false)) or
		float(macro_cooldown_attention_directives.get("special_event_probability_multiplier", 1.0)) != 0.0
	):
		RunState.event_history = attention_director_event_history
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Attention Director to cool down macro special events after a recent macro beat."
		}
	RunState.event_history = attention_director_event_history
	var saved_difficulty_config: Dictionary = RunState.difficulty_config.duplicate(true)
	var saved_difficulty_id: String = RunState.difficulty_id
	var saved_network_contacts: Dictionary = RunState.network_contacts.duplicate(true)
	RunState.event_history = [{
		"event_id": "earnings_beat",
		"scope": "company",
		"event_family": "company",
		"category": "company",
		"day_index": 5
	}]
	RunState.difficulty_config = GameManager.get_difficulty_config("normal")
	RunState.difficulty_id = "normal"
	var normal_day_seven_directives: Dictionary = attention_director.resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		7,
		GameManager.get_current_macro_state()
	)
	RunState.difficulty_config = GameManager.get_difficulty_config("grind")
	RunState.difficulty_id = "grind"
	var grind_day_seven_directives: Dictionary = attention_director.resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		7,
		GameManager.get_current_macro_state()
	)
	RunState.difficulty_config = GameManager.get_difficulty_config("chill")
	RunState.difficulty_id = "chill"
	var chill_day_seven_directives: Dictionary = attention_director.resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		7,
		GameManager.get_current_macro_state()
	)
	if (
		not bool(grind_day_seven_directives.get("force_company_arc_start", false)) or
		float(grind_day_seven_directives.get("company_arc_probability_multiplier", 0.0)) <= float(normal_day_seven_directives.get("company_arc_probability_multiplier", 0.0)) or
		bool(chill_day_seven_directives.get("force_company_arc_start", false))
	):
		RunState.event_history = attention_director_event_history
		RunState.difficulty_config = saved_difficulty_config
		RunState.difficulty_id = saved_difficulty_id
		RunState.network_contacts = saved_network_contacts
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Grind to raise quiet-pressure pacing earlier than Normal/Chill."
		}
	RunState.event_history = [{
		"event_id": "sector_tailwind",
		"scope": "market",
		"event_family": "macro",
		"category": "macro",
		"day_index": 8
	}]
	RunState.difficulty_config = GameManager.get_difficulty_config("normal")
	RunState.difficulty_id = "normal"
	var normal_day_ten_directives: Dictionary = attention_director.resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		10,
		GameManager.get_current_macro_state()
	)
	RunState.difficulty_config = GameManager.get_difficulty_config("chill")
	RunState.difficulty_id = "chill"
	var chill_day_ten_directives: Dictionary = attention_director.resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		10,
		GameManager.get_current_macro_state()
	)
	if str(chill_day_ten_directives.get("attention_tier", "")) != "digestion" or str(normal_day_ten_directives.get("attention_tier", "")) == "digestion":
		RunState.event_history = attention_director_event_history
		RunState.difficulty_config = saved_difficulty_config
		RunState.difficulty_id = saved_difficulty_id
		RunState.network_contacts = saved_network_contacts
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Chill to digest headlines longer than Normal."
		}
	RunState.event_history = attention_director_event_history
	RunState.difficulty_config = saved_difficulty_config
	RunState.difficulty_id = saved_difficulty_id
	var deterministic_attention_a: Dictionary = attention_director.resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		12,
		GameManager.get_current_macro_state()
	)
	var deterministic_attention_b: Dictionary = attention_director.resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		12,
		GameManager.get_current_macro_state()
	)
	if (
		deterministic_attention_a.get("focus_company_ids", []) != deterministic_attention_b.get("focus_company_ids", []) or
		deterministic_attention_a.get("focus_company_weights", {}) != deterministic_attention_b.get("focus_company_weights", {})
	):
		RunState.network_contacts = saved_network_contacts
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Attention Director focus-company weights to be deterministic for the same state."
		}
	var focus_company_ids: Array = deterministic_attention_a.get("focus_company_ids", [])
	if not focus_company_ids.is_empty():
		var focus_company_id: String = str(focus_company_ids[0])
		var focused_candidate_directives: Dictionary = {
			"focus_company_ids": [focus_company_id],
			"focus_company_weights": {focus_company_id: 2.75}
		}
		var focused_candidates: Array = COMPANY_EVENT_SYSTEM_SCRIPT.new().build_company_event_candidates(
			RunState,
			RunState.get_current_trade_date(),
			12,
			GameManager.get_current_macro_state(),
			focused_candidate_directives
		)
		var focused_candidate_found: bool = false
		for focused_candidate_value in focused_candidates:
			if typeof(focused_candidate_value) != TYPE_DICTIONARY:
				continue
			var focused_candidate: Dictionary = focused_candidate_value
			if str(focused_candidate.get("target_company_id", "")) == focus_company_id:
				focused_candidate_found = true
				break
		if not focused_candidate_found:
			RunState.network_contacts = saved_network_contacts
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected company candidates to include Attention Director focus companies."
			}
	var pre_day_twenty_dirty_directives: Dictionary = attention_director.resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		19,
		GameManager.get_current_macro_state()
	)
	if float(pre_day_twenty_dirty_directives.get("dirty_market_pressure", -1.0)) != 0.0:
		RunState.network_contacts = saved_network_contacts
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected dirty-market pressure to stay zero before day 20."
		}
	var low_visibility_difficulty: Dictionary = RunState.get_difficulty_config()
	low_visibility_difficulty["starting_cash"] = max(RunState.get_total_equity() * 2.0, 1.0)
	RunState.difficulty_config = low_visibility_difficulty
	RunState.network_contacts = {}
	var invisible_dirty_directives: Dictionary = attention_director.resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		25,
		GameManager.get_current_macro_state()
	)
	RunState.difficulty_config = saved_difficulty_config
	RunState.difficulty_id = saved_difficulty_id
	RunState.network_contacts = saved_network_contacts
	if float(invisible_dirty_directives.get("dirty_market_pressure", -1.0)) != 0.0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected dirty-market pressure to stay zero before equity or recognition eligibility."
		}
	var dirty_tip_saved_run: Dictionary = RunState.to_save_dict()
	var dirty_tip_system = DIRTY_TIP_SYSTEM_SCRIPT.new()
	var dirty_tip_company_id: String = str(RunState.company_order[0])
	var dirty_tip_directives: Dictionary = {
		"selected_lane": "dirty_market",
		"dirty_market_pressure": 1.0,
		"focus_company_ids": [dirty_tip_company_id],
		"focus_company_weights": {dirty_tip_company_id: 2.25}
	}
	var pre_day_dirty_offer: Dictionary = dirty_tip_system.resolve_day(
		RunState,
		DataRepository,
		dirty_tip_directives,
		19,
		RunState.get_current_trade_date()
	)
	if not pre_day_dirty_offer.get("offers", []).is_empty():
		RunState.load_from_dict(dirty_tip_saved_run)
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Dirty Tip offers to stay disabled before day 20."
		}
	RunState.load_from_dict(dirty_tip_saved_run)
	var dirty_tip_invisible_state: Dictionary = RunState.to_save_dict()
	RunState.network_contacts = {}
	RunState.player_portfolio["holdings"] = {}
	var invisible_offer_difficulty: Dictionary = RunState.get_difficulty_config()
	invisible_offer_difficulty["starting_cash"] = max(RunState.get_total_equity() * 4.0, 1.0)
	RunState.difficulty_config = invisible_offer_difficulty
	var invisible_dirty_offer: Dictionary = dirty_tip_system.resolve_day(
		RunState,
		DataRepository,
		dirty_tip_directives,
		25,
		RunState.get_current_trade_date()
	)
	if not invisible_dirty_offer.get("offers", []).is_empty():
		RunState.load_from_dict(dirty_tip_invisible_state)
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Dirty Tip offers to require player visibility."
		}
	RunState.load_from_dict(dirty_tip_saved_run)
	var forced_dirty_offer_result: Dictionary = GameManager.debug_force_dirty_tip_offer(dirty_tip_company_id)
	var forced_dirty_offers: Array = forced_dirty_offer_result.get("offers", [])
	if not bool(forced_dirty_offer_result.get("success", false)) or forced_dirty_offers.is_empty():
		RunState.load_from_dict(dirty_tip_saved_run)
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected debug force Dirty Tip to create an offer."
		}
	var forced_dirty_offer: Dictionary = forced_dirty_offers[0]
	var dirty_tip_dialog: Control = game_root.find_child("DirtyTipDialog", true, false) as Control
	var dirty_tip_title_label: Label = game_root.find_child("DirtyTipTitleLabel", true, false) as Label
	var dirty_tip_body_label: Label = game_root.find_child("DirtyTipBodyLabel", true, false) as Label
	var dirty_tip_accept_button: Button = game_root.find_child("DirtyTipAcceptButton", true, false) as Button
	var dirty_tip_decline_button: Button = game_root.find_child("DirtyTipDeclineButton", true, false) as Button
	var dirty_tip_report_button: Button = game_root.find_child("DirtyTipReportButton", true, false) as Button
	var dirty_tip_close_button: Button = game_root.find_child("DirtyTipCloseButton", true, false) as Button
	if dirty_tip_dialog == null or dirty_tip_title_label == null or dirty_tip_body_label == null or dirty_tip_accept_button == null or dirty_tip_decline_button == null or dirty_tip_report_button == null or dirty_tip_close_button == null:
		RunState.load_from_dict(dirty_tip_saved_run)
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Dirty Tip dialog smoke-test node names to exist."
		}
	game_root.call("_queue_dirty_tip_alerts_from_recap_snapshot", {
		"last_day_results": {
			"dirty_tip_offers": [forced_dirty_offer]
		}
	})
	game_root.call("_show_next_dirty_tip_alert")
	await get_tree().process_frame
	if not dirty_tip_dialog.visible or dirty_tip_body_label.text.strip_edges().is_empty():
		RunState.load_from_dict(dirty_tip_saved_run)
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Dirty Tip popup to render queued post-recap offers."
		}
	dirty_tip_accept_button.emit_signal("pressed")
	await get_tree().process_frame
	var accepted_dirty_request: Dictionary = RunState.get_network_requests().get(str(forced_dirty_offer.get("id", "")), {})
	if str(accepted_dirty_request.get("status", "")) != "accepted":
		RunState.load_from_dict(dirty_tip_saved_run)
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected accepting a Dirty Tip popup to activate the case."
		}
	var dirty_market_effect: Dictionary = dirty_tip_system.market_effect_for_company(RunState, dirty_tip_company_id, RunState.day_index + 1)
	if dirty_market_effect.is_empty() or float(dirty_market_effect.get("volume_multiplier", 1.0)) <= 1.0:
		RunState.load_from_dict(dirty_tip_saved_run)
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected accepted Dirty Tip cases to create hidden market pressure."
		}
	var dirty_requests: Dictionary = RunState.get_network_requests()
	accepted_dirty_request["debug_force_caught"] = true
	accepted_dirty_request["due_day_index"] = RunState.day_index
	accepted_dirty_request["active_until_day_index"] = RunState.day_index
	dirty_requests[str(accepted_dirty_request.get("id", ""))] = accepted_dirty_request.duplicate(true)
	RunState.set_network_requests(dirty_requests)
	var dirty_case_results: Array = dirty_tip_system.process_due_cases(RunState, DataRepository)
	var legal_state: Dictionary = RunState.get_player_life().get("legal_state", {})
	if dirty_case_results.is_empty() or str(dirty_case_results[0].get("status", "")) != "caught" or not bool(legal_state.get("active", false)) or int(legal_state.get("days_remaining", 0)) <= 0:
		RunState.load_from_dict(dirty_tip_saved_run)
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected caught Dirty Tip outcomes to apply a fine and legal hold."
		}
	if GameManager.get_life_action_block_reason("buy").is_empty() or not GameManager.get_life_action_block_reason("advance_day").is_empty():
		RunState.load_from_dict(dirty_tip_saved_run)
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected legal hold to block gameplay actions except Advance Day."
		}
	var dirty_network_snapshot: Dictionary = GameManager.get_network_snapshot()
	var saw_dirty_network_row: bool = false
	for row_value in dirty_network_snapshot.get("journal", []):
		if typeof(row_value) == TYPE_DICTIONARY and str(row_value.get("type", "")) == "dirty_tip":
			saw_dirty_network_row = true
			break
	if not saw_dirty_network_row:
		RunState.load_from_dict(dirty_tip_saved_run)
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Dirty Tip decisions and outcomes to render in Network journal."
		}
	var dirty_tip_save_payload: Dictionary = RunState.to_save_dict()
	if dirty_tip_save_payload.has("dirty_tip_offers") or dirty_tip_save_payload.has("dirty_tip_results"):
		RunState.load_from_dict(dirty_tip_saved_run)
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Dirty Tip data to stay inside existing save buckets."
		}
	RunState.load_from_dict(dirty_tip_saved_run)
	game_root._refresh_all()
	await get_tree().process_frame
	var suppressed_company_arc_resolution: Dictionary = COMPANY_EVENT_SYSTEM_SCRIPT.new().resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		5,
		GameManager.get_current_macro_state(),
		day_six_attention_directives
	)
	if not suppressed_company_arc_resolution.get("started_events", []).is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Attention Director to suppress new company arc starts on the reserved macro day."
		}
	var scheduled_event_test_difficulty: Dictionary = RunState.get_difficulty_config()
	scheduled_event_test_difficulty["event_interval_days"] = 1.0
	var scheduled_event_test_macro: Dictionary = GameManager.get_current_macro_state()
	scheduled_event_test_macro["market_bias"] = -0.02
	scheduled_event_test_macro["policy_action_bps"] = 25
	var suppressed_scheduled_event_value = MARKET_SIMULATOR_SCRIPT.new().call(
		"_build_daily_event_plan",
		RunState,
		RunState.get_current_trade_date(),
		{},
		-0.04,
		5,
		scheduled_event_test_difficulty,
		scheduled_event_test_macro,
		day_six_attention_directives
	)
	var suppressed_scheduled_event: Dictionary = suppressed_scheduled_event_value if typeof(suppressed_scheduled_event_value) == TYPE_DICTIONARY else {}
	if str(suppressed_scheduled_event.get("scope", "")) == "market":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Attention Director to suppress market-scope scheduled headlines on the reserved macro day."
		}
	var saved_recap_last_day_results: Dictionary = post_recap_saved_run.get("last_day_results", {})
	var forbidden_director_payload_keys: Array = ["attention_directives", "selected_lane", "lane_scores", "focus_company_weights", "dirty_market_pressure", "market_stress_score", "best_company_attention_score"]
	for forbidden_director_payload_key in forbidden_director_payload_keys:
		if RunState.last_day_results.has(forbidden_director_payload_key) or saved_recap_last_day_results.has(forbidden_director_payload_key):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Attention Director key %s to stay out of the save payload." % forbidden_director_payload_key
			}
	if RunState.last_day_results.has("attention_directives") or saved_recap_last_day_results.has("attention_directives"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Attention Director directives to stay out of the save payload."
		}
	var day_six_special_resolution: Dictionary = SPECIAL_EVENT_SYSTEM_SCRIPT.new().resolve_day(
		RunState,
		RunState.get_current_trade_date(),
		5,
		GameManager.get_current_macro_state(),
		day_six_attention_directives
	)
	var day_six_special_events: Array = day_six_special_resolution.get("started_events", [])
	if day_six_special_events.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected player-facing day 6 to trigger a random macro special event."
		}
	var early_special_event: Dictionary = day_six_special_events[0] if typeof(day_six_special_events[0]) == TYPE_DICTIONARY else {}
	if (
		early_special_event.is_empty() or
		str(early_special_event.get("scope", "")) != "market" or
		str(early_special_event.get("event_family", "")) != "special" or
		not SPECIAL_EVENT_IDS.has(str(early_special_event.get("event_id", "")))
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the day-6 macro event to be one of the special market regimes."
		}
	var macro_event_dialog: Control = game_root.find_child("MacroEventDialog", true, false) as Control
	if macro_event_dialog == null or macro_event_dialog.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Macro Events overlay to exist but stay hidden while Daily Recap is still open."
		}
	var macro_template_headline: String = str(DataRepository.get_event_definition("covid_wave").get("headline_template", ""))
	var macro_direct_headline := "Custom geopolitical headline"
	var macro_index_headline := "Index desk no changes"
	var macro_recap_snapshot: Dictionary = {
		"last_day_results": {
			"scheduled_event": {"event_id": "covid_wave", "scope": "market"},
			"started_special_events": [
				{"event_id": "geopolitical_turmoil", "scope": "market", "headline": macro_direct_headline},
				{"event_id": "sector_tailwind", "scope": "sector", "headline": "Sector alert should not show"}
			],
			"index_review_events": [
				{"event_id": "index_review_no_change", "scope": "market", "headline": macro_index_headline},
				{"event_id": "mscy_index_inclusion", "scope": "company", "headline": "Company alert should not show"}
			]
		}
	}
	game_root.call("_queue_macro_event_alerts_from_recap_snapshot", macro_recap_snapshot)
	if macro_event_dialog.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected queued Macro Events to wait until Daily Recap closes."
		}
	daily_recap_continue_button.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame
	var macro_event_title_label: Label = game_root.find_child("MacroEventTitleLabel", true, false) as Label
	var macro_event_headline_label: Label = game_root.find_child("MacroEventHeadlineLabel", true, false) as Label
	var macro_event_close_button: Button = game_root.find_child("MacroEventCloseButton", true, false) as Button
	var expected_macro_headlines: Array = [macro_template_headline, macro_direct_headline, macro_index_headline]
	for expected_index in range(expected_macro_headlines.size()):
		macro_event_dialog = game_root.find_child("MacroEventDialog", true, false) as Control
		macro_event_headline_label = game_root.find_child("MacroEventHeadlineLabel", true, false) as Label
		if (
			macro_event_dialog == null or
			not macro_event_dialog.visible or
			daily_recap_dialog.visible or
			macro_event_title_label == null or
			macro_event_title_label.text != "Macro Events" or
			macro_event_headline_label == null or
			macro_event_headline_label.text != str(expected_macro_headlines[expected_index]) or
			macro_event_close_button == null
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Macro Events alert %d to show the queued headline after Daily Recap closes." % expected_index
			}
		if expected_index == 0:
			if (
				macro_event_headline_label.visible_characters < 0 or
				macro_event_headline_label.visible_characters >= macro_event_headline_label.text.length()
			):
				game_root.queue_free()
				await get_tree().process_frame
				return {
					"success": false,
					"message": "Smoke test expected Macro Events headline text to start partially hidden for typing."
				}
			game_root.call("_on_macro_event_confirm_pressed")
			if (
				not macro_event_dialog.visible or
				macro_event_headline_label.visible_characters != macro_event_headline_label.text.length()
			):
				game_root.queue_free()
				await get_tree().process_frame
				return {
					"success": false,
					"message": "Smoke test expected confirming a typing Macro Events headline to complete the text without dismissing it."
				}
		else:
			game_root.call("_on_macro_event_confirm_pressed")
		game_root.call("_on_macro_event_confirm_pressed")
		await get_tree().process_frame
		await get_tree().process_frame
	if macro_event_dialog != null and macro_event_dialog.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected only market-scope macro events to show, with sector/company scope alerts filtered out."
		}

	var recap_snapshot: Dictionary = GameManager.get_daily_recap_snapshot()
	var recap_counts: Dictionary = recap_snapshot.get("activity_counts", {})
	var activity_snapshot: Dictionary = GameManager.get_daily_activity_snapshot()
	var cached_badge_counts: Dictionary = RunState.get_desktop_app_badge_counts()
	if (
		int(activity_snapshot.get("day_index", -1)) != RunState.day_index or
		activity_snapshot.get("activity_counts", {}) != recap_counts or
		int(cached_badge_counts.get("day_index", -1)) != RunState.day_index or
		cached_badge_counts.get("counts", {}) != recap_counts
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Daily Recap activity counts to come from the current-day cache and persist into desktop badge counts."
		}
	var current_twooter_post_count: int = GameManager.get_twooter_snapshot().get("posts", []).size()
	if int(recap_counts.get("social", -1)) != current_twooter_post_count:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected count-only Twooter activity to match the rendered Twooter post count."
		}
	var expect_news_badge: bool = int(recap_counts.get("news", 0)) > 0
	var expect_social_badge: bool = int(recap_counts.get("social", 0)) > 0
	var expect_network_badge: bool = int(recap_counts.get("network", 0)) > 0
	if (
		news_badge == null or
		social_badge == null or
		network_badge == null or
		(expect_news_badge and not news_badge.visible) or
		(expect_social_badge and not social_badge.visible) or
		(expect_network_badge and not network_badge.visible)
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected News, Twooter, and Network desktop badges to appear when current-day activity exists."
		}
	var saved_badge_state: Dictionary = RunState.to_save_dict()
	var saved_last_day_results: Dictionary = saved_badge_state.get("last_day_results", {})
	var saved_last_day_trade_date: Dictionary = saved_last_day_results.get("trade_date", {})
	if (
		saved_last_day_results.has("companies") or
		saved_last_day_results.has("corporate_meeting_calendar") or
		not saved_last_day_results.has("starting_equity") or
		saved_last_day_trade_date.is_empty()
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected last_day_results saves to keep recap context without duplicating company or meeting payloads."
		}
	var legacy_badge_state: Dictionary = saved_badge_state.duplicate(true)
	var legacy_last_day_results: Dictionary = saved_last_day_results.duplicate(true)
	legacy_last_day_results["companies"] = {"legacy": {"company_profile": {"financial_history": [1, 2, 3]}}}
	legacy_last_day_results["corporate_meeting_calendar"] = {"legacy": []}
	legacy_badge_state["last_day_results"] = legacy_last_day_results
	RunState.load_from_dict(legacy_badge_state)
	if RunState.last_day_results.has("companies") or RunState.last_day_results.has("corporate_meeting_calendar"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected legacy last_day_results payloads to be trimmed during save/load normalization."
		}
	RunState.load_from_dict(saved_badge_state)
	game_root._refresh_desktop()
	await get_tree().process_frame
	if (
		(expect_news_badge and not news_badge.visible) or
		(expect_social_badge and not social_badge.visible) or
		(expect_network_badge and not network_badge.visible)
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected desktop badge seen-day state to persist through save/load."
		}

	news_app_button.emit_signal("pressed")
	await get_tree().process_frame
	if news_badge.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected opening News to clear the News desktop badge."
		}
	game_root.close_desktop_app("news")
	await get_tree().process_frame
	RunState.load_from_dict(pre_badge_test_state)
	game_root._refresh_all()
	await get_tree().process_frame

	social_app_button.emit_signal("pressed")
	await get_tree().process_frame
	await _wait_for_ui_animation_settle()
	if social_badge.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected opening Twooter to clear the Twooter desktop badge."
		}
	if (
		social_window == null or
		not social_window.visible or
		not _desktop_window_animation_settled(game_root, "TwooterDesktopWindow") or
		not game_root.is_desktop_app_open("social") or
		game_root.get_active_desktop_app_id() != "social" or
		game_root.get_desktop_app_window_title("social") != "Twooter" or
		_desktop_window_has_settings_brown_chrome(game_root, "TwooterDesktopWindow") or
		social_feed_cards == null or
		social_feed_cards.get_child_count() <= 0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Twooter icon to open the dark social shell with populated post cards."
		}

	var social_left_sidebar: PanelContainer = game_root.find_child("SocialLeftSidebar", true, false) as PanelContainer
	var social_home_button: Button = game_root.find_child("SocialNavHomeButton", true, false) as Button
	var social_message_button: Button = game_root.find_child("SocialNavMessageButton", true, false) as Button
	var social_right_rail: VBoxContainer = game_root.find_child("SocialRightRail", true, false) as VBoxContainer
	if (
		social_left_sidebar == null or
		not social_left_sidebar.visible or
		social_home_button == null or
		social_message_button == null or
		game_root.find_child("SocialNavExploreButton", true, false) != null or
		game_root.find_child("SocialNavProfileButton", true, false) != null or
		game_root.find_child("SocialSearchPanel", true, false) != null or
		game_root.find_child("SocialSearchInput", true, false) != null or
		social_right_rail == null
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter to render only Home and Message in the left sidebar, no search panel, and a right rail."
		}

	var social_interaction_restore_state: Dictionary = RunState.to_save_dict()
	var pre_interaction_social_snapshot: Dictionary = GameManager.get_twooter_snapshot()
	var social_interaction_posts: Array = pre_interaction_social_snapshot.get("posts", [])
	if social_interaction_posts.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter interaction coverage to have at least one visible post."
		}
	var social_first_post: Dictionary = social_interaction_posts[0]
	var social_first_post_id: String = str(social_first_post.get("id", ""))
	var social_first_account_id: String = str(social_first_post.get("account_id", ""))
	var social_account_search_input: LineEdit = game_root.find_child("SocialAccountSearchInput", true, false) as LineEdit
	var search_account_id: String = ""
	var search_account_name: String = ""
	var search_handle_query: String = "@not_an_account_name"
	for account_value in pre_interaction_social_snapshot.get("accounts", []):
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var search_account: Dictionary = account_value
		var candidate_name: String = str(search_account.get("display_name", "")).strip_edges()
		if candidate_name.is_empty():
			continue
		if search_account_id.is_empty():
			search_account_id = str(search_account.get("id", ""))
			search_account_name = candidate_name
		var candidate_handle: String = str(search_account.get("handle", "")).strip_edges()
		if not candidate_handle.is_empty() and not candidate_name.to_lower().contains(candidate_handle.to_lower()):
			search_handle_query = candidate_handle
	if social_account_search_input == null or search_account_id.is_empty() or search_account_name.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter right rail to expose an account-name search input."
		}
	social_account_search_input.text = search_handle_query
	social_account_search_input.emit_signal("text_changed", search_handle_query)
	await get_tree().process_frame
	if game_root.find_child("SocialAccountSearchResultButton", true, false) != null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter account search to match account names only, not handles."
		}
	social_account_search_input.text = search_account_name
	social_account_search_input.emit_signal("text_changed", search_account_name)
	await get_tree().process_frame
	var social_account_search_result: Button = game_root.find_child("SocialAccountSearchResultButton", true, false) as Button
	if social_account_search_result == null or str(social_account_search_result.get_meta("social_account_id", "")) != search_account_id:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter account search to find accounts by display name."
		}
	social_account_search_input.text = ""
	social_account_search_input.emit_signal("text_changed", "")
	await get_tree().process_frame
	var silent_account_id: String = ""
	for account_value in pre_interaction_social_snapshot.get("accounts", []):
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var silent_account: Dictionary = account_value
		if int(silent_account.get("public_post_count", 0)) <= 0 and not str(silent_account.get("id", "")).is_empty():
			silent_account_id = str(silent_account.get("id", ""))
			break
	if silent_account_id.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected at least one Twooter account with zero visible posts for self-awareness coverage."
		}
	var self_awareness_restore_state: Dictionary = RunState.to_save_dict()
	var silent_thread: Dictionary = GameManager.get_twooter_message_thread(silent_account_id)
	for option_value in silent_thread.get("dialog_options", []):
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		if str(option_value.get("player_text", "")).to_lower().contains("your posts"):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected zero-post Twooter accounts to avoid player options praising their posts."
			}
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0
	var no_post_reply_result: Dictionary = GameManager.send_twooter_message(
		silent_account_id,
		"message_check_in",
		"",
		"Your posts are useful. I would like to compare notes without turning this into a shortcut."
	)
	var no_post_reply_text: String = str(no_post_reply_result.get("reply_text", no_post_reply_result.get("message", ""))).to_lower()
	if (
		not bool(no_post_reply_result.get("success", false)) or
		(
			not no_post_reply_text.contains("not posted") and
			not no_post_reply_text.contains("zero public posts") and
			not no_post_reply_text.contains("no public posts") and
			not no_post_reply_text.contains("imaginary posts")
		)
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected zero-post Twooter accounts to correct messages praising posts they have not made."
		}
	RunState.load_from_dict(self_awareness_restore_state)
	game_root._refresh_social()
	await get_tree().process_frame
	var missing_thesis_account_id: String = social_first_account_id
	for account_value in pre_interaction_social_snapshot.get("accounts", []):
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account_row: Dictionary = account_value
		var profile: Dictionary = account_row.get("social_profile", {}) if typeof(account_row.get("social_profile", {})) == TYPE_DICTIONARY else {}
		if str(profile.get("risk_profile", "")) != "suspicious" and not str(account_row.get("id", "")).is_empty():
			missing_thesis_account_id = str(account_row.get("id", ""))
			break
	var missing_thesis_restore_state: Dictionary = RunState.get_twooter_social_state()
	var missing_thesis_state: Dictionary = missing_thesis_restore_state.duplicate(true)
	var missing_thesis_accounts: Dictionary = missing_thesis_state.get("account_states", {})
	var missing_thesis_account_state: Dictionary = missing_thesis_accounts.get(missing_thesis_account_id, {})
	missing_thesis_account_state["relationship"] = 6
	missing_thesis_account_state["credibility"] = 0
	missing_thesis_account_state["importance"] = 0
	missing_thesis_accounts[missing_thesis_account_id] = missing_thesis_account_state
	missing_thesis_state["account_states"] = missing_thesis_accounts
	RunState.set_twooter_social_state(missing_thesis_state)
	var missing_thesis_thread: Dictionary = GameManager.get_twooter_message_thread(missing_thesis_account_id)
	var missing_thesis_guidance_found: bool = false
	for option_value in missing_thesis_thread.get("dialog_options", []):
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option_row: Dictionary = option_value
		if (
			str(option_row.get("action_id", option_row.get("id", ""))) == "share_thesis" and
			not bool(option_row.get("enabled", true)) and
			str(option_row.get("blocked_reason", "")) == "missing_thesis" and
			str(option_row.get("player_text", "")).to_lower().contains("thesis")
		):
			missing_thesis_guidance_found = true
			break
	RunState.set_twooter_social_state(missing_thesis_restore_state)
	if not missing_thesis_guidance_found:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter dialog trees to show explicit build-your-thesis guidance before thesis sharing is available."
		}
	var thesis_create_result: Dictionary = GameManager.create_thesis(
		str(RunState.company_order[0]),
		"bullish",
		"swing",
		"Twooter smoke thesis"
	)
	if (
		social_first_post_id.is_empty()
		or social_first_account_id.is_empty()
		or not bool(thesis_create_result.get("success", false))
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter interaction setup to find a post/account and create a shareable thesis."
		}
	game_root._refresh_social()
	await get_tree().process_frame
	var social_context_hint_label: Label = game_root.find_child("SocialContextHintLabel", true, false) as Label
	if social_context_hint_label != null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter cards to hide generated context summary lines."
		}
	var social_avatar_label: Label = game_root.find_child("SocialAvatarLabel", true, false) as Label
	if social_avatar_label == null or social_avatar_label.text.strip_edges().is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter cards to render account initial avatars."
		}
	if game_root.find_child("SocialSentimentRow", true, false) != null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter cards to omit bullish/bearish sentiment bars."
		}
	var social_post_action_button: Button = game_root.find_child("SocialPostActionButton", true, false) as Button
	var public_action_ap_before: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	if social_post_action_button == null or social_post_action_button.text != "Reply":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter posts to expose one Reply composer button."
		}
	var social_like_button: Button = game_root.find_child("SocialPostLikeButton", true, false) as Button
	var like_state_before: Dictionary = RunState.get_twooter_social_state()
	var like_account_before: Dictionary = like_state_before.get("account_states", {}).get(social_first_account_id, {})
	var likes_given_before: int = int(like_account_before.get("likes_given", 0))
	if social_like_button == null or social_like_button.disabled or not social_like_button.text.begins_with("Like"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter posts to expose a real Like button before the player likes a post."
		}
	social_like_button.emit_signal("pressed")
	await get_tree().process_frame
	var like_state_after: Dictionary = RunState.get_twooter_social_state()
	var like_account_after: Dictionary = like_state_after.get("account_states", {}).get(social_first_account_id, {})
	social_like_button = game_root.find_child("SocialPostLikeButton", true, false) as Button
	if (
		not like_state_after.get("liked_posts", {}).has(social_first_post_id)
		or int(like_account_after.get("likes_given", 0)) <= likes_given_before
		or float(like_account_after.get("like_relationship_progress", 0.0)) < 0.49
		or social_like_button == null
		or not social_like_button.disabled
		or not social_like_button.text.begins_with("Liked")
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected liking a Twooter post to persist liked post state, update account like count, and disable the Like button."
		}
	social_post_action_button = game_root.find_child("SocialPostActionButton", true, false) as Button
	if social_post_action_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Reply button to remain available after liking a post."
		}
	social_post_action_button.emit_signal("pressed")
	await get_tree().process_frame
	var social_reply_dialog: Control = game_root.find_child("SocialReplyComposerDialog", true, false) as Control
	var social_reply_option_button: Button = game_root.find_child("SocialReplyDialogOptionButton", true, false) as Button
	var social_reply_send_button: Button = game_root.find_child("SocialReplySendButton", true, false) as Button
	var social_reply_text_label: Label = game_root.find_child("SocialReplyComposerTextLabel", true, false) as Label
	if (
		social_reply_dialog == null or
		not social_reply_dialog.visible or
		social_reply_option_button == null or
		social_reply_send_button == null or
		not social_reply_send_button.disabled or
		social_reply_text_label == null
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter Reply to open a composer with dialog options and disabled send."
		}
	var first_public_action_id: String = str(social_reply_option_button.get_meta("action_id", ""))
	if (
		first_public_action_id.is_empty() or
		str(social_reply_option_button.get_meta("tree_id", "")).is_empty() or
		str(social_reply_option_button.get_meta("node_id", "")).is_empty() or
		str(social_reply_option_button.get_meta("option_id", "")).is_empty()
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter public reply options to expose dialog tree metadata."
		}
	social_reply_option_button.emit_signal("pressed")
	await get_tree().create_timer(1.35).timeout
	if social_reply_send_button.disabled or social_reply_text_label.text.strip_edges().is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected selecting a Twooter dialog option to typewrite reply text and enable send."
		}
	social_reply_send_button.emit_signal("pressed")
	await get_tree().process_frame
	var public_action_ap_after: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var social_reply_row: PanelContainer = game_root.find_child("SocialReplyRow", true, false) as PanelContainer
	var social_player_reply_bubble: PanelContainer = game_root.find_child("SocialPlayerReplyBubble", true, false) as PanelContainer
	var social_account_reply_bubble: PanelContainer = game_root.find_child("SocialAccountReplyBubble", true, false) as PanelContainer
	if social_reply_row == null or social_player_reply_bubble == null or social_account_reply_bubble == null or public_action_ap_after != public_action_ap_before or social_reply_dialog.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected public Twooter interaction to close composer and show player plus account replies without spending AP."
		}
	var social_account_reply_text_label: Label = game_root.find_child("SocialAccountReplyTextLabel", true, false) as Label
	if (
		social_account_reply_text_label == null or
		social_account_reply_text_label.text.to_lower().contains(" replies:") or
		social_account_reply_text_label.text.to_lower().contains(" answers:") or
		social_account_reply_text_label.text.to_lower().contains(" says:")
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter account reply bubbles to render clean response text without duplicated reply prefixes."
		}
	var social_state_after_reply: Dictionary = RunState.get_twooter_social_state()
	if social_state_after_reply.get("post_interactions", {}).is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected public Twooter interaction to persist compact post interaction state."
		}
	var account_state_after_first_reply: Dictionary = social_state_after_reply.get("account_states", {}).get(social_first_account_id, {})
	var first_reply_relationship_gain: int = int(account_state_after_first_reply.get("relationship", 0))
	var repeated_public_result: Dictionary = GameManager.interact_with_twooter_post(social_first_post_id, first_public_action_id)
	if (
		not bool(repeated_public_result.get("success", false))
		or int(repeated_public_result.get("relationship_delta", -1)) >= first_reply_relationship_gain
		or int(repeated_public_result.get("relationship_delta", -1)) < 0
		or not str(repeated_public_result.get("reply_text", "")).to_lower().contains("follow")
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected repeated same-day Twooter public interaction to have diminished gains and mention following before deeper asks."
		}
	var low_chain_interaction: Dictionary = RunState.get_twooter_social_state().get("post_interactions", {}).get(social_first_post_id, {})
	if (
		not bool(low_chain_interaction.get("concluded", false))
		or str(low_chain_interaction.get("conclusion_reason", "")) != "needs_more_stats"
		or bool(low_chain_interaction.get("followup_unlocked", false))
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected low-stat Twooter public chain to conclude after repeated replies."
		}
	var high_chain_state: Dictionary = RunState.get_twooter_social_state()
	var high_interactions: Dictionary = high_chain_state.get("post_interactions", {})
	high_interactions.erase(social_first_post_id)
	high_chain_state["post_interactions"] = high_interactions
	var high_dialog_state: Dictionary = high_chain_state.get("dialog_state", {})
	var high_dialog_posts: Dictionary = high_dialog_state.get("posts", {})
	high_dialog_posts.erase(social_first_post_id)
	high_dialog_state["posts"] = high_dialog_posts
	high_chain_state["dialog_state"] = high_dialog_state
	high_chain_state["daily_public_interactions"] = {
		"day_index": RunState.day_index,
		"account_action_counts": {}
	}
	var high_account_states: Dictionary = high_chain_state.get("account_states", {})
	var high_account_state: Dictionary = high_account_states.get(social_first_account_id, {})
	high_account_state["relationship"] = 22
	high_account_state["credibility"] = 8
	high_account_state["importance"] = 13
	high_account_states[social_first_account_id] = high_account_state
	high_chain_state["account_states"] = high_account_states
	RunState.set_twooter_social_state(high_chain_state)
	for high_reply_index in range(3):
		var high_reply_result: Dictionary = GameManager.interact_with_twooter_post(
			social_first_post_id,
			"reply_support",
			"",
			"Keeping this public reply clean for follow-up."
		)
		if not bool(high_reply_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected high-stat Twooter public chain to accept follow-up replies."
			}
	var high_chain_interaction: Dictionary = RunState.get_twooter_social_state().get("post_interactions", {}).get(social_first_post_id, {})
	if (
		not bool(high_chain_interaction.get("concluded", false))
		or str(high_chain_interaction.get("conclusion_reason", "")) != "followup_unlocked"
		or not bool(high_chain_interaction.get("followup_unlocked", false))
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected high-stat Twooter public chain to unlock follow-up."
		}
	game_root._refresh_social()
	await get_tree().process_frame
	if game_root.find_child("SocialPostFollowupButton", true, false) == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a follow-up-unlocked Twooter chain to expose a Message affordance."
		}
	var social_account_button: Button = game_root.find_child("SocialAccountNameButton", true, false) as Button
	if social_account_button == null or str(social_account_button.get_meta("social_account_id", "")).is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter account names to be clickable filters."
		}
	var filtered_account_id: String = str(social_account_button.get_meta("social_account_id", ""))
	social_account_button.emit_signal("pressed")
	await get_tree().process_frame
	var social_account_profile_card: PanelContainer = game_root.find_child("SocialAccountProfileCard", true, false) as PanelContainer
	var social_account_profile_stats: HFlowContainer = game_root.find_child("SocialAccountProfileStats", true, false) as HFlowContainer
	var social_account_profile_description_label: Label = game_root.find_child("SocialAccountProfileDescriptionLabel", true, false) as Label
	var social_account_filter_nav_row: HBoxContainer = game_root.find_child("SocialAccountFilterNavRow", true, false) as HBoxContainer
	if (
		social_account_profile_card == null
		or str(social_account_profile_card.get_meta("social_account_id", "")) != filtered_account_id
		or social_account_filter_nav_row == null
		or social_account_profile_stats == null
		or social_account_profile_stats.get_child_count() < 5
		or social_account_profile_description_label == null
		or social_account_profile_description_label.text.strip_edges().is_empty()
		or game_root.find_child("SocialAccountProfileCaresLabel", true, false) != null
		or game_root.find_child("SocialAccountProfileNextStepLabel", true, false) != null
		or game_root.find_child("SocialAccountProfileMemoryLabel", true, false) != null
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected clicking a Twooter account to open a profile card with stats and one account description."
		}
	var social_clear_button: Button = game_root.find_child("SocialAccountClearButton", true, false) as Button
	var social_start_message_button: Button = game_root.find_child("SocialStartMessageButton", true, false) as Button
	var social_account_follow_button: Button = game_root.find_child("SocialAccountFollowButton", true, false) as Button
	var social_nav_index: int = social_feed_cards.get_children().find(social_account_filter_nav_row)
	var social_profile_index: int = social_feed_cards.get_children().find(social_account_profile_card)
	if (
		social_clear_button == null
		or not social_account_filter_nav_row.is_ancestor_of(social_clear_button)
		or social_nav_index == -1
		or social_profile_index == -1
		or social_nav_index >= social_profile_index
		or social_start_message_button == null
		or social_account_follow_button == null
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected clicking a Twooter account name to show account actions and an All accounts button above the profile."
		}
	social_account_follow_button.emit_signal("pressed")
	await get_tree().process_frame
	if game_root.find_child("SocialFeedFilterFollowingButton", true, false) == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected following a Twooter account to add a Following feed tab."
		}
	social_clear_button = game_root.find_child("SocialAccountClearButton", true, false) as Button
	if social_clear_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the account filter controls to remain after following an account."
		}
	var filtered_post_count: int = 0
	for social_child in social_feed_cards.get_children():
		if str(social_child.name) != "SocialPostCard":
			continue
		filtered_post_count += 1
		if str(social_child.get_meta("social_account_id", "")) != filtered_account_id:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected a Twooter account filter to show only that account's posts."
			}
	if filtered_post_count <= 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a Twooter account filter to keep visible posts."
		}
	social_clear_button.emit_signal("pressed")
	await get_tree().process_frame
	if game_root.find_child("SocialAccountClearButton", true, false) != null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected clearing a Twooter account filter to return to the full feed."
		}
	var right_follow_row: HBoxContainer = game_root.find_child("SocialFollowRow", true, false) as HBoxContainer
	var right_follow_account_button: Button = game_root.find_child("SocialFollowAccountButton", true, false) as Button
	if (
		right_follow_row == null
		or str(right_follow_row.get_meta("social_account_id", "")).is_empty()
		or right_follow_account_button == null
		or str(right_follow_account_button.get_meta("social_account_id", "")).is_empty()
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Twooter right rail follow list to expose clickable account rows."
		}
	var right_follow_account_id: String = str(right_follow_account_button.get_meta("social_account_id", ""))
	right_follow_account_button.emit_signal("pressed")
	await get_tree().process_frame
	var right_follow_profile_card: PanelContainer = game_root.find_child("SocialAccountProfileCard", true, false) as PanelContainer
	if right_follow_profile_card == null or str(right_follow_profile_card.get_meta("social_account_id", "")) != right_follow_account_id:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected clicking a right-rail follow row to open that account profile."
		}
	social_clear_button = game_root.find_child("SocialAccountClearButton", true, false) as Button
	if social_clear_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a right-rail account profile to remain clearable."
		}
	social_clear_button.emit_signal("pressed")
	await get_tree().process_frame

	var social_thread_button: Button = game_root.find_child("SocialThreadToggleButton", true, false) as Button
	var social_thread_lines: VBoxContainer = game_root.find_child("SocialThreadLines", true, false) as VBoxContainer
	var social_card_count_before_thread_toggle: int = social_feed_cards.get_child_count()
	if social_thread_button == null or social_thread_lines == null or social_thread_lines.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter to render collapsed expandable thread cards."
		}
	social_thread_button.emit_signal("pressed")
	await get_tree().process_frame
	if not social_thread_lines.visible or social_feed_cards.get_child_count() != social_card_count_before_thread_toggle:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected expanding a Twooter thread to preserve feed order and reveal thread lines."
		}
	social_thread_button.emit_signal("pressed")
	await get_tree().process_frame
	if social_thread_lines.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter thread cards to collapse again."
		}

	social_message_button.emit_signal("pressed")
	await get_tree().process_frame
	var social_message_view: HBoxContainer = game_root.find_child("SocialMessageView", true, false) as HBoxContainer
	var legacy_social_message_actions: VBoxContainer = game_root.find_child("SocialMessageActions", true, false) as VBoxContainer
	var social_message_composer: PanelContainer = game_root.find_child("SocialMessageComposer", true, false) as PanelContainer
	var social_message_thread_scroll: ScrollContainer = game_root.find_child("SocialMessageThreadScroll", true, false) as ScrollContainer
	var social_message_rows_scroll: ScrollContainer = game_root.find_child("SocialMessageRowsScroll", true, false) as ScrollContainer
	var social_message_detail_panel: PanelContainer = game_root.find_child("SocialMessageDetailPanel", true, false) as PanelContainer
	if (
		social_message_view == null or
		not social_message_view.visible or
		legacy_social_message_actions != null or
		social_message_composer == null or
		social_message_composer.visible or
		social_message_thread_scroll == null or
		social_message_rows_scroll == null or
		social_message_detail_panel == null or
		(social_right_rail != null and social_right_rail.visible) or
		game_root.find_child("SocialMessageThreadButton", true, false) != null
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter Message view to start empty with scroll containers and no legacy action stack."
		}
	social_home_button.emit_signal("pressed")
	await get_tree().process_frame
	social_account_button = game_root.find_child("SocialAccountNameButton", true, false) as Button
	if social_account_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter Home to expose account names after leaving the empty inbox."
		}
	social_account_button.emit_signal("pressed")
	await get_tree().process_frame
	social_start_message_button = game_root.find_child("SocialStartMessageButton", true, false) as Button
	if social_start_message_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a selected Twooter account to expose a Send message action."
		}
	social_start_message_button.emit_signal("pressed")
	await get_tree().process_frame
	social_message_view = game_root.find_child("SocialMessageView", true, false) as HBoxContainer
	var social_message_options: VBoxContainer = game_root.find_child("SocialMessageComposerOptions", true, false) as VBoxContainer
	var social_message_send_button: Button = game_root.find_child("SocialMessageSendButton", true, false) as Button
	var social_message_composer_text_label: Label = game_root.find_child("SocialMessageComposerTextLabel", true, false) as Label
	social_message_detail_panel = game_root.find_child("SocialMessageDetailPanel", true, false) as PanelContainer
	var social_message_rect: Rect2 = social_message_view.get_global_rect() if social_message_view != null else Rect2()
	var social_detail_rect: Rect2 = social_message_detail_panel.get_global_rect() if social_message_detail_panel != null else Rect2()
	var social_composer_rect: Rect2 = social_message_composer.get_global_rect() if social_message_composer != null else Rect2()
	var social_rows_scroll_rect: Rect2 = social_message_rows_scroll.get_global_rect() if social_message_rows_scroll != null else Rect2()
	if (
		social_message_view == null or
		not social_message_view.visible or
		social_message_options == null or
		social_message_options.get_child_count() != 3 or
		social_message_send_button == null or
		not social_message_send_button.disabled or
		social_message_composer_text_label == null or
		social_message_detail_panel == null or
		(social_right_rail != null and social_right_rail.visible) or
		social_detail_rect.end.x > social_message_rect.end.x + 1.0 or
		social_composer_rect.end.x > social_detail_rect.end.x + 1.0 or
		social_rows_scroll_rect.end.x > social_detail_rect.end.x + 1.0 or
		game_root.find_child("SocialMessageActionConnectButton", true, false) != null
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Send message from an account to open an inline private message composer."
		}
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0
	var private_ap_before: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var network_journal_before: int = GameManager.get_network_snapshot().get("journal", []).size()
	var network_discovery_before: int = RunState.get_network_discoveries().size()
	var private_network_option_button: Button = null
	var private_option_texts_before: Array[String] = []
	var private_tree_metadata_found: bool = false
	var share_thesis_option_seen: bool = false
	for action_child in social_message_options.get_children():
		var option_button: Button = action_child as Button
		if option_button == null or not option_button.visible:
			continue
		var option_action_id: String = str(option_button.get_meta("action_id", ""))
		private_option_texts_before.append(option_button.text)
		if (
			not str(option_button.get_meta("tree_id", "")).is_empty() and
			not str(option_button.get_meta("node_id", "")).is_empty() and
			not str(option_button.get_meta("option_id", "")).is_empty()
		):
			private_tree_metadata_found = true
		if option_action_id == "share_thesis":
			share_thesis_option_seen = true
		if private_network_option_button == null and option_action_id != "message_check_in":
			private_network_option_button = option_button
		if option_action_id == "connect":
			private_network_option_button = option_button
	if private_network_option_button == null or not private_tree_metadata_found:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the private composer to include contextual dialog tree options with a Network-facing action."
		}
	private_network_option_button.emit_signal("pressed")
	await get_tree().create_timer(1.35).timeout
	if social_message_send_button.disabled or social_message_composer_text_label.text.strip_edges().is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected selecting a private dialog option to typewrite text and enable Send."
		}
	social_message_send_button.emit_signal("pressed")
	await get_tree().process_frame
	var private_ap_after: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var network_journal_after: int = GameManager.get_network_snapshot().get("journal", []).size()
	var network_discovery_after: int = RunState.get_network_discoveries().size()
	if private_ap_after <= private_ap_before or network_journal_after <= network_journal_before or network_discovery_after <= network_discovery_before:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected private Twooter connect action to spend AP and create Network journal/discovery entries."
		}
	var first_message_rows: Array = RunState.get_twooter_social_state().get("messages", {}).get(social_first_account_id, {}).get("rows", [])
	if first_message_rows.size() < 2 or str(first_message_rows[first_message_rows.size() - 2].get("sender", "")) != "player" or str(first_message_rows[first_message_rows.size() - 1].get("sender", "")) != "account":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected private Twooter send to write player/account message rows in order."
		}
	var private_cooldown_restore_state: Dictionary = RunState.to_save_dict()
	var private_cooldown_social_state: Dictionary = RunState.get_twooter_social_state()
	var private_cooldown_dialog_state: Dictionary = private_cooldown_social_state.get("dialog_state", {}) if typeof(private_cooldown_social_state.get("dialog_state", {})) == TYPE_DICTIONARY else {}
	var private_cooldown_accounts: Dictionary = private_cooldown_dialog_state.get("accounts", {}) if typeof(private_cooldown_dialog_state.get("accounts", {})) == TYPE_DICTIONARY else {}
	private_cooldown_accounts[social_first_account_id] = {
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
	private_cooldown_dialog_state["accounts"] = private_cooldown_accounts
	private_cooldown_social_state["dialog_state"] = private_cooldown_dialog_state
	RunState.set_twooter_social_state(private_cooldown_social_state)
	var private_cooldown_thread: Dictionary = GameManager.get_twooter_message_thread(social_first_account_id)
	var private_cooldown_send_result: Dictionary = GameManager.send_twooter_message(
		social_first_account_id,
		"message_check_in",
		"",
		"I am trying to reopen the same thread without new context."
	)
	game_root.selected_social_message_account_id = social_first_account_id
	social_home_button.emit_signal("pressed")
	await get_tree().process_frame
	social_message_button.emit_signal("pressed")
	await get_tree().process_frame
	var cooldown_message_options: VBoxContainer = game_root.find_child("SocialMessageComposerOptions", true, false) as VBoxContainer
	var visible_cooldown_option_count: int = 0
	if cooldown_message_options != null:
		for cooldown_option_child in cooldown_message_options.get_children():
			var cooldown_option_button: Button = cooldown_option_child as Button
			if cooldown_option_button != null and cooldown_option_button.visible:
				visible_cooldown_option_count += 1
	if (
		not private_cooldown_thread.get("dialog_options", []).is_empty() or
		bool(private_cooldown_send_result.get("success", false)) or
		visible_cooldown_option_count > 0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a cooled-down Twooter Message branch to stay paused after Home/Message navigation and reject direct sends."
		}
	RunState.load_from_dict(private_cooldown_restore_state)
	game_root.selected_social_message_account_id = social_first_account_id
	game_root.selected_social_view_id = "message"
	game_root._refresh_social()
	await get_tree().process_frame
	social_message_options = game_root.find_child("SocialMessageComposerOptions", true, false) as VBoxContainer
	var private_option_texts_after: Array[String] = []
	var share_thesis_button: Button = null
	if social_message_options != null:
		for action_child in social_message_options.get_children():
			var action_button: Button = action_child as Button
			if action_button != null and action_button.visible:
				private_option_texts_after.append(action_button.text)
			if action_button != null and str(action_button.get_meta("action_id", "")) == "share_thesis":
				share_thesis_option_seen = true
				share_thesis_button = action_button
				break
	if private_option_texts_after == private_option_texts_before:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter Message dialog options to advance after a reply."
		}
	var share_thread_before: Dictionary = RunState.get_twooter_social_state().get("messages", {}).get(social_first_account_id, {})
	var share_message_count_before: int = share_thread_before.get("rows", []).size()
	var share_credibility_before: int = int(RunState.get_twooter_social_state().get("account_states", {}).get(social_first_account_id, {}).get("credibility", 0))
	var share_ap_before: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	if not share_thesis_option_seen:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter Message dialog trees to expose a share-thesis action when an open thesis exists."
		}
	var share_result: Dictionary = GameManager.send_twooter_message(
		social_first_account_id,
		"share_thesis",
		str(thesis_create_result.get("thesis", {}).get("id", ""))
	)
	await get_tree().process_frame
	var share_state_after: Dictionary = RunState.get_twooter_social_state()
	var share_message_count_after: int = share_state_after.get("messages", {}).get(social_first_account_id, {}).get("rows", []).size()
	var share_credibility_after: int = int(share_state_after.get("account_states", {}).get(social_first_account_id, {}).get("credibility", 0))
	var share_ap_after: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	if (
		not bool(share_result.get("success", false))
		or share_ap_after <= share_ap_before
		or share_credibility_after <= share_credibility_before
		or share_message_count_after <= share_message_count_before
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected sharing a thesis through Twooter to spend AP, raise credibility, and write message rows."
		}
	RunState.load_from_dict(social_interaction_restore_state)
	game_root._refresh_all()
	await get_tree().process_frame

	game_root.close_desktop_app("social")
	await get_tree().process_frame
	if not desktop_layer.visible or game_root.is_desktop_app_open("social"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected closing the Twooter desktop window to hide the app while keeping the desktop visible."
		}

	network_app_button.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame
	await _wait_for_ui_animation_settle()
	if network_badge.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected opening Network to clear the Network desktop badge."
		}
	var network_snapshot: Dictionary = GameManager.get_network_snapshot()
	if (
		network_window == null or
		not network_window.visible or
		not _desktop_window_animation_settled(game_root, "NetworkDesktopWindow") or
		not game_root.is_desktop_app_open("network") or
		game_root.get_active_desktop_app_id() != "network" or
		game_root.get_desktop_app_window_title("network") != "Network" or
		not _desktop_window_has_settings_brown_chrome(game_root, "NetworkDesktopWindow") or
		network_contacts_list == null or
		str(network_snapshot.get("recognition", {}).get("label", "")).is_empty() or
		int(network_snapshot.get("contact_cap", 0)) <= 0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Network icon to open a brown-framed contact window with recognition data."
		}

	var network_content_host: Control = network_window.get_parent() as Control
	if network_action_row == null or network_content_host == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Network window to expose an action row inside its content host."
		}
	var network_action_rect: Rect2 = network_action_row.get_global_rect()
	var network_host_rect: Rect2 = network_content_host.get_global_rect()
	if network_action_rect.end.y > network_host_rect.end.y + 1.0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network action controls to fit inside the visible window content."
		}

	game_root.close_desktop_app("network")
	await get_tree().process_frame
	if not desktop_layer.visible or game_root.is_desktop_app_open("network"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected closing the Network desktop window to hide the app while keeping the desktop visible."
		}

	stock_app_button.emit_signal("pressed")
	await get_tree().process_frame
	await _wait_for_ui_animation_settle()
	if (
		not _desktop_window_animation_settled(game_root, "STOCKBOTDesktopWindow") or
		not game_root.is_desktop_app_open("stock") or
		game_root.get_active_desktop_app_id() != "stock" or
		game_root.get_desktop_app_window_title("stock") != "STOCKBOT" or
		_desktop_window_has_settings_brown_chrome(game_root, "STOCKBOTDesktopWindow")
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the STOCKBOT icon to keep its non-brown trading-platform frame inside the runtime desktop window manager."
		}
	if difficulty_id == GameManager.DEFAULT_DIFFICULTY_ID:
		var sma_toggle: CheckButton = game_root.find_child("IndicatorToggle_sma_20", true, false) as CheckButton
		if sma_toggle == null or sma_toggle.disabled:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected unlocked chart indicators to expose enabled chart toggles."
			}

	var tracked_company_id: String = str(RunState.company_order[0]) if not RunState.company_order.is_empty() else ""
	var secondary_company_id: String = str(RunState.company_order[1]) if RunState.company_order.size() > 1 else tracked_company_id
	var request_fail_company_id: String = str(RunState.company_order[2]) if RunState.company_order.size() > 2 else secondary_company_id
	var stock_list_tabs: TabContainer = game_root.find_child("StockListTabs", true, false) as TabContainer
	var add_watchlist_button: Button = game_root.find_child("AddWatchlistButton", true, false) as Button
	var company_list: ItemList = game_root.find_child("CompanyList", true, false) as ItemList
	var watchlist_picker_dialog: ConfirmationDialog = game_root.find_child("WatchlistPickerDialog", true, false) as ConfirmationDialog
	var watchlist_picker_list: ItemList = game_root.find_child("WatchlistPickerList", true, false) as ItemList
	if stock_list_tabs == null or add_watchlist_button == null or company_list == null or watchlist_picker_dialog == null or watchlist_picker_list == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the new watchlist tab controls in the STOCKBOT trade list."
		}

	if stock_list_tabs.current_tab != 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Watchlist to be the default active trade-list tab."
		}

	var dashboard_grid: GridContainer = game_root.find_child("DashboardGrid", true, false) as GridContainer
	var movers_tabs: TabContainer = game_root.find_child("MoversTabs", true, false) as TabContainer
	var top_broker_flow_rows: VBoxContainer = game_root.find_child("TopBrokerFlowRows", true, false) as VBoxContainer
	var work_tabs: TabContainer = game_root.find_child("WorkTabs", true, false) as TabContainer
	var calendar_week_header: GridContainer = game_root.find_child("CalendarWeekHeader", true, false) as GridContainer
	var calendar_days_grid: GridContainer = game_root.find_child("CalendarDaysGrid", true, false) as GridContainer
	var dashboard_sector_cards_grid: GridContainer = game_root.find_child("DashboardSectorCardsGrid", true, false) as GridContainer
	var dashboard_sector_detail: VBoxContainer = game_root.find_child("DashboardSectorDetail", true, false) as VBoxContainer
	var dashboard_sector_stock_rows: VBoxContainer = game_root.find_child("DashboardSectorStockRows", true, false) as VBoxContainer
	var dashboard_sector_back_button: Button = game_root.find_child("DashboardSectorBackButton", true, false) as Button
	var dashboard_index_title_label: Label = game_root.get("dashboard_index_title_label") as Label
	var dashboard_movers_title_label: Label = game_root.get("dashboard_movers_title_label") as Label
	var dashboard_calendar_title_label: Label = game_root.get("dashboard_calendar_title_label") as Label
	var dashboard_sector_title_label: Label = game_root.get("dashboard_placeholder_bottom_title_label") as Label
	var dashboard_index_smoke_state: Dictionary = {}
	if game_root.has_method("_get_dashboard_index_recap_smoke_state"):
		dashboard_index_smoke_state = game_root.call("_get_dashboard_index_recap_smoke_state")
	if (
		dashboard_grid == null or
		int(dashboard_grid.get_theme_constant("h_separation")) != 0 or
		int(dashboard_grid.get_theme_constant("v_separation")) != 0 or
		movers_tabs == null or
		movers_tabs.get_tab_count() < 3 or
		movers_tabs.get_tab_title(2) != "Broker Flow" or
		top_broker_flow_rows == null or
		work_tabs == null or
		not work_tabs.is_tab_hidden(4) or
		calendar_week_header == null or
		calendar_week_header.get_child_count() != 7 or
		calendar_days_grid == null or
		calendar_days_grid.get_child_count() < 35 or
		calendar_days_grid.get_child_count() % 7 != 0 or
		dashboard_sector_cards_grid == null or
		dashboard_sector_cards_grid.get_child_count() <= 0 or
		dashboard_sector_detail == null or
		dashboard_sector_stock_rows == null or
		dashboard_sector_back_button == null
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Dashboard movers with a Broker Flow tab, sector cards, uniform calendar grid, zero dashboard separation, and hidden Analyzer tab."
		}
	if top_broker_flow_rows.get_child_count() <= 1:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Dashboard Broker Flow tab to render aggregated broker buy/sell rows."
		}
	var broker_roster_size: int = DataRepository.get_broker_roster().size()
	if broker_roster_size > 0 and top_broker_flow_rows.get_child_count() - 1 < broker_roster_size:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Dashboard Broker Flow tab to show every broker."
		}

	var dashboard_title_labels := [
		dashboard_index_title_label,
		dashboard_movers_title_label,
		dashboard_calendar_title_label,
		dashboard_sector_title_label
	]
	for title_label_value in dashboard_title_labels:
		var title_label: Label = title_label_value
		var title_font: Font = title_label.get_theme_font("font") if title_label != null else null
		if (
			title_label == null or
			title_label.get_theme_font_size("font_size") != 16 or
			not _color_close(title_label.get_theme_color("font_color"), Color(0.92549, 0.941176, 0.956863, 1)) or
			title_font == null or
			not title_font.resource_path.ends_with("OpenSans-SemiBold.ttf")
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Dashboard section titles to use 16px semibold white text."
			}

	var dashboard_index_points_text: String = str(dashboard_index_smoke_state.get("points_text", ""))
	var dashboard_index_change_text: String = str(dashboard_index_smoke_state.get("change_text", ""))
	var dashboard_index_lot_text: String = str(dashboard_index_smoke_state.get("lot_text", ""))
	var dashboard_index_value_text: String = str(dashboard_index_smoke_state.get("value_text", ""))
	var sparkline_point_count: int = int(dashboard_index_smoke_state.get("sparkline_point_count", 0))
	if (
		dashboard_index_smoke_state.is_empty() or
		not bool(dashboard_index_smoke_state.get("recap_exists", false)) or
		dashboard_index_points_text.strip_edges().is_empty() or
		dashboard_index_points_text == "-" or
		not dashboard_index_change_text.contains("(") or
		int(dashboard_index_smoke_state.get("row_count", 0)) < 2 or
		dashboard_index_lot_text == "-" or
		dashboard_index_lot_text.is_empty() or
		dashboard_index_value_text == "-" or
		dashboard_index_value_text.is_empty() or
		sparkline_point_count <= 1 or
		bool(dashboard_index_smoke_state.get("old_date_visible", true)) or
		bool(dashboard_index_smoke_state.get("old_grid_visible", true)) or
		bool(dashboard_index_smoke_state.get("old_hint_visible", true))
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Dashboard index recap to render points, change, All Market values, a real sparkline, and hide the old index grid. Details: recap=%s points='%s' change='%s' rows=%d lot='%s' value='%s' sparkline=%d old_date_visible=%s old_grid_visible=%s old_hint_visible=%s" % [
				str(bool(dashboard_index_smoke_state.get("recap_exists", false))),
				dashboard_index_points_text,
				dashboard_index_change_text,
				int(dashboard_index_smoke_state.get("row_count", -1)),
				dashboard_index_lot_text,
				dashboard_index_value_text,
				sparkline_point_count,
				str(dashboard_index_smoke_state.get("old_date_visible", "<missing>")),
				str(dashboard_index_smoke_state.get("old_grid_visible", "<missing>")),
				str(dashboard_index_smoke_state.get("old_hint_visible", "<missing>"))
			]
		}

	var dashboard_sector_card: Control = null
	for sector_card_child in dashboard_sector_cards_grid.get_children():
		var sector_card: Control = sector_card_child as Control
		if sector_card != null and not str(sector_card.get_meta("sector_id", "")).is_empty():
			dashboard_sector_card = sector_card
			break
	if dashboard_sector_card == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Dashboard sector cards to expose clickable sector metadata."
		}
	var sector_card_click := InputEventMouseButton.new()
	sector_card_click.button_index = MOUSE_BUTTON_LEFT
	sector_card_click.pressed = true
	sector_card_click.position = dashboard_sector_card.get_global_rect().get_center()
	dashboard_sector_card.emit_signal("gui_input", sector_card_click)
	await get_tree().process_frame
	if not dashboard_sector_detail.visible or dashboard_sector_stock_rows.get_child_count() <= 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected clicking a Dashboard sector card to show that sector's stock list."
		}
	dashboard_sector_back_button.emit_signal("pressed")
	await get_tree().process_frame
	if dashboard_sector_detail.visible or dashboard_sector_cards_grid.get_child_count() <= 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Dashboard sector detail back button to restore sector cards."
		}

	var calendar_event_day_cell: Control = null
	for calendar_child in calendar_days_grid.get_children():
		var day_cell: Control = calendar_child as Control
		if day_cell != null and bool(day_cell.get_meta("has_events", false)):
			calendar_event_day_cell = day_cell
			break
	if calendar_event_day_cell == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Dashboard calendar to expose at least one clickable event day."
		}
	var calendar_click_event := InputEventMouseButton.new()
	calendar_click_event.button_index = MOUSE_BUTTON_LEFT
	calendar_click_event.pressed = true
	calendar_click_event.position = calendar_event_day_cell.get_global_rect().get_center()
	calendar_event_day_cell.emit_signal("gui_input", calendar_click_event)
	await get_tree().process_frame
	var calendar_event_popup: Control = game_root.find_child("DashboardCalendarEventPopup", true, false) as Control
	var calendar_event_body_label: Label = game_root.find_child("DashboardCalendarEventBodyLabel", true, false) as Label
	var calendar_event_close_button: Button = game_root.find_child("DashboardCalendarEventCloseButton", true, false) as Button
	if (
		calendar_event_popup == null or
		not calendar_event_popup.visible or
		calendar_event_body_label == null or
		(
			not calendar_event_body_label.text.contains("Reports") and
			not calendar_event_body_label.text.contains("Meetings")
		) or
		calendar_event_close_button == null
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected clicking a Dashboard calendar event day to open an event popup."
		}
	calendar_event_close_button.emit_signal("pressed")
	await get_tree().process_frame
	if calendar_event_popup.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Dashboard calendar event popup to close from its close button."
		}

	if not RunState.has_method("ensure_company_full_detail") or not RunState.ensure_company_full_detail(tracked_company_id):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected RunState to hydrate full company detail on demand for the selected stock."
		}
	if secondary_company_id != tracked_company_id:
		RunState.ensure_company_full_detail(secondary_company_id)
	game_root.selected_company_id = tracked_company_id
	game_root._refresh_trade_workspace()
	await get_tree().process_frame

	add_watchlist_button.emit_signal("pressed")
	await get_tree().process_frame
	if not watchlist_picker_dialog.visible or watchlist_picker_list.item_count != RunState.company_order.size():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Add Watchlist to open a picker containing every stock."
		}

	watchlist_picker_list.select(0)
	watchlist_picker_dialog.emit_signal("confirmed")
	await get_tree().process_frame
	if company_list.item_count < 1 or not RunState.is_in_watchlist(tracked_company_id):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the picker flow to add a stock into the watchlist."
		}

	stock_list_tabs.current_tab = 1
	await get_tree().process_frame
	var all_stock_add_button: Button = game_root.find_child("AllStockAddButton_%s" % secondary_company_id, true, false) as Button
	var all_stock_select_button: Button = game_root.find_child("AllStockSelectButton_%s" % tracked_company_id, true, false) as Button
	if all_stock_add_button == null or all_stock_select_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the All Stock tab to expose add and select buttons for each company row."
		}

	all_stock_add_button.emit_signal("pressed")
	await get_tree().process_frame
	if not RunState.is_in_watchlist(secondary_company_id):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the All Stock add button to immediately save a company into the watchlist."
		}

	all_stock_select_button = game_root.find_child("AllStockSelectButton_%s" % tracked_company_id, true, false) as Button
	if all_stock_select_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the All Stock selection button to still exist after the watchlist refresh."
		}

	all_stock_select_button.emit_signal("pressed")
	await get_tree().process_frame

	game_root.selected_company_id = tracked_company_id
	game_root._refresh_trade_workspace()
	await get_tree().process_frame
	var profile_meet_contact_button: Button = game_root.find_child("ProfileMeetContactButton", true, false) as Button
	if profile_meet_contact_button != null and profile_meet_contact_button.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected company Profile meet-lead controls to stay hidden."
		}
	network_snapshot = GameManager.get_network_snapshot()
	var discovered_contacts: Array = network_snapshot.get("discoveries", [])
	for discovered_value in discovered_contacts:
		var discovered_contact: Dictionary = discovered_value
		if str(discovered_contact.get("source_type", "")) != "profile":
			continue
		if str(discovered_contact.get("target_company_id", "")) != tracked_company_id:
			continue
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected opening company Profile to avoid creating profile-sourced Network leads."
		}

	game_root._refresh_network()
	await get_tree().process_frame
	var discovered_only_network_text: String = _collect_item_list_text(network_contacts_list)
	if (
		discovered_only_network_text.contains("Lead Floater") or
		discovered_only_network_text.contains("Lead Insider") or
		discovered_only_network_text.contains("Referred Insider")
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Network contacts list to hide discovered leads until the player meets them."
		}

	var profile_management_label: Label = game_root.find_child("ProfileManagementLabel", true, false) as Label
	if profile_management_label == null or not profile_management_label.text.contains("CEO") or not profile_management_label.text.contains("CFO") or not profile_management_label.text.contains("Commissioner"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected company Profile to display public management names and roles."
		}
	var profile_price_label: Label = game_root.find_child("ProfilePriceLabel", true, false) as Label
	var profile_factor_label: Label = game_root.find_child("ProfileFactorLabel", true, false) as Label
	var profile_background_body_label: Label = game_root.find_child("ProfileBackgroundBodyLabel", true, false) as Label
	var profile_shareholder_card: PanelContainer = game_root.find_child("ProfileShareholderCard", true, false) as PanelContainer
	var profile_shareholder_title_label: Label = game_root.find_child("ProfileShareholderTitleLabel", true, false) as Label
	var profile_shareholder_rows: VBoxContainer = game_root.find_child("ProfileShareholderRows", true, false) as VBoxContainer
	var profile_factor_text: String = profile_factor_label.text.to_lower() if profile_factor_label != null else ""
	if (
		profile_price_label == null or
		profile_factor_label == null or
		profile_background_body_label == null or
		profile_shareholder_card == null or
		profile_shareholder_title_label == null or
		profile_shareholder_rows == null or
		profile_price_label.visible or
		profile_factor_text.contains("quality") or
		profile_factor_text.contains("growth") or
		profile_factor_text.contains("risk") or
		profile_background_body_label.text.strip_edges().is_empty() or
		profile_shareholder_title_label.text != "Shareholders" or
		_profile_container_text(profile_shareholder_rows).contains("Type") or
		_profile_container_text(profile_shareholder_rows).contains("Location")
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected company Profile to hide raw price/score lines and render the new background/shareholder layout."
		}

	var referral_setup: Dictionary = _first_referral_setup(tracked_company_id)
	if referral_setup.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected generated insiders to have at least one connected floater referral path."
		}

	var contact_id: String = str(referral_setup.get("floater_id", ""))
	_ensure_test_contact_discovery(contact_id, tracked_company_id, "referral")
	var meet_result: Dictionary = GameManager.meet_contact(contact_id, {"source_type": "referral", "source_id": tracked_company_id})
	if not bool(meet_result.get("success", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected meeting a discovered Network contact to succeed."
		}
	if int(GameManager.get_daily_action_snapshot().get("used", 0)) <= 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected successful Network actions to spend daily action points."
		}

	game_root._refresh_network()
	await get_tree().process_frame
	var met_network_text: String = _collect_item_list_text(network_contacts_list)
	if not met_network_text.contains("Met ") or met_network_text.contains("Lead "):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Network contacts list to show met contacts without showing unmet leads."
		}

	var saved_network_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(saved_network_state)
	network_snapshot = GameManager.get_network_snapshot()
	var contact_persisted: bool = false
	for contact_value in network_snapshot.get("contacts", []):
		var contact: Dictionary = contact_value
		if str(contact.get("id", "")) == contact_id and bool(contact.get("met", false)):
			contact_persisted = true
			break
	if not contact_persisted:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected met Network contacts to persist through save/load."
		}

	var early_referral_result: Dictionary = GameManager.request_contact_referral(contact_id, tracked_company_id)
	if bool(early_referral_result.get("success", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network referral to require enough relationship before succeeding."
		}

	_set_test_contact_relationship(contact_id, 45)
	var daily_actions_before_referral: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var referral_result: Dictionary = GameManager.request_contact_referral(contact_id, tracked_company_id)
	var referred_contact_id: String = str(referral_result.get("contact_id", ""))
	if not bool(referral_result.get("success", false)) or referred_contact_id.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a connected floater to refer a company insider once relationship is high enough."
		}
	if int(GameManager.get_daily_action_snapshot().get("used", 0)) != daily_actions_before_referral + GameManager.get_network_action_cost("referral"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network referral to spend the configured referral AP cost."
		}
	var post_referral_contacts: Dictionary = RunState.get_network_contacts()
	if int(post_referral_contacts.get(contact_id, {}).get("relationship", 0)) != 35:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected successful Network referral to spend 10 relationship points."
		}
	var duplicate_referral_same_day: Dictionary = GameManager.request_contact_referral(contact_id, tracked_company_id)
	if bool(duplicate_referral_same_day.get("success", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network referrals to have a same-day soft cooldown per contact."
		}

	var meet_referred_result: Dictionary = GameManager.meet_contact(referred_contact_id, {"source_type": "referral", "source_id": contact_id})
	if not bool(meet_referred_result.get("success", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a referred company insider to be meetable."
		}
	var referred_save_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(referred_save_state)
	network_snapshot = GameManager.get_network_snapshot()
	if not _has_met_network_contact(network_snapshot, referred_contact_id):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected referred company insiders to persist through save/load after meeting."
		}

	var daily_actions_before_insider_tip: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var insider_tip_result: Dictionary = GameManager.request_contact_tip(referred_contact_id)
	if not bool(insider_tip_result.get("success", false)) or not _has_contact_arc(referred_contact_id, tracked_company_id, "tip"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected company insider tips to default to the insider's affiliated company."
		}
	if int(GameManager.get_daily_action_snapshot().get("used", 0)) != daily_actions_before_insider_tip + GameManager.get_network_action_cost("tip"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network tips to spend the configured tip AP cost."
		}
	var insider_tip_public_error: String = _validate_network_tip_public_payload(insider_tip_result, "company insider tip")
	if not insider_tip_public_error.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": insider_tip_public_error
		}

	var tip_result: Dictionary = GameManager.request_contact_tip(contact_id, secondary_company_id)
	if not bool(tip_result.get("success", false)) or not _has_contact_arc(contact_id, secondary_company_id, "tip"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected asking a Network contact for a tip to create a contact company arc."
		}
	var duplicate_tip_same_day: Dictionary = GameManager.request_contact_tip(contact_id, secondary_company_id)
	if bool(duplicate_tip_same_day.get("success", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network tips to have a same-day soft cooldown per contact."
		}
	var floater_tip_public_error: String = _validate_network_tip_public_payload(tip_result, "floater tip")
	if not floater_tip_public_error.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": floater_tip_public_error
		}
	if not _tip_journal_has_pending_public_memory():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected successful Network tips to create pending public tip-memory journal rows."
		}
	var tip_memory_save_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(tip_memory_save_state)
	if not _tip_journal_has_pending_public_memory():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network tip-memory journal rows to survive save/load."
		}

	var help_button: Button = game_root.find_child("HelpButton", true, false) as Button
	if help_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the Help navigation button in the game shell."
		}

	var help_text_label: RichTextLabel = game_root.find_child("HelpTextLabel", true, false) as RichTextLabel
	if help_text_label == null or not help_text_label.text.contains("FIRST LOOP"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Help menu to expose the FTUE first-loop copy."
		}

	var company_count: int = RunState.company_order.size()
	var expected_company_count: int = int(difficulty_config.get("company_count", 0))
	if company_count != expected_company_count:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected %d companies on %s, found %d." % [
				expected_company_count,
				difficulty_id,
				company_count
			]
		}

	var roster_validation: String = _validate_generated_roster()
	if not roster_validation.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": roster_validation
		}

	var price_diversity_validation: String = _validate_starting_price_diversity(expected_company_count)
	if not price_diversity_validation.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": price_diversity_validation
		}

	var opening_snapshot: Dictionary = GameManager.get_company_snapshot(tracked_company_id, true, true, true)
	var opening_price: float = float(opening_snapshot.get("current_price", 0.0))
	var opening_financials: Dictionary = opening_snapshot.get("financials", {})
	var opening_financial_history: Array = opening_snapshot.get("financial_history", [])
	var opening_statement_snapshot: Dictionary = opening_snapshot.get("financial_statement_snapshot", {})
	var opening_macro_state: Dictionary = GameManager.get_current_macro_state()
	var ownership_test_state: Dictionary = RunState.to_save_dict()
	RunState.active_special_events = [{
		"scope": "market",
		"start_day_index": RunState.day_index,
		"end_day_index": RunState.day_index + 1,
		"market_bias_shift": 0.0,
		"volatility_multiplier": 1.0,
		"sector_biases": {},
		"shock_profile": {}
	}]
	var shares_outstanding: float = float(opening_snapshot.get("shares_outstanding", 0.0))
	var ownership_test_shares: int = int(ceil(shares_outstanding * 0.25 / float(RunState.LOT_SIZE))) * RunState.LOT_SIZE
	if shares_outstanding <= 0.0 or ownership_test_shares <= 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected company snapshots to expose shares outstanding for ownership calculations."
		}
	RunState.player_portfolio["cash"] = float(opening_snapshot.get("current_price", 1.0)) * float(ownership_test_shares) * 2.0
	var ownership_buy_result: Dictionary = RunState.buy_company(tracked_company_id, ownership_test_shares)
	var ownership_snapshot: Dictionary = GameManager.get_company_ownership_snapshot(tracked_company_id)
	var player_flow_context: Dictionary = RunState.get_player_market_flow_context(tracked_company_id, RunState.day_index + 1)
	var player_is_listed: bool = false
	for shareholder_value in ownership_snapshot.get("shareholder_rows", []):
		var shareholder: Dictionary = shareholder_value
		if str(shareholder.get("name", "")) == "Player":
			player_is_listed = true
	if (
		not bool(ownership_buy_result.get("success", false)) or
		not bool(ownership_snapshot.get("is_major_shareholder", false)) or
		not player_is_listed or
		str(player_flow_context.get("broker_code", "")) != RunState.PLAYER_BROKER_CODE or
		float(player_flow_context.get("net_value", 0.0)) <= 0.0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected buying more than 5 percent ownership to list Player as a major shareholder and record XL buy pressure."
		}
	GameManager.simulate_opening_session(false)
	var impact_snapshot: Dictionary = GameManager.get_company_snapshot(tracked_company_id, true)
	var impact_broker_flow: Dictionary = impact_snapshot.get("broker_flow", {})
	var impact_volume_context: Dictionary = RunState.get_company(tracked_company_id).get("volume_context", {})
	var impact_market_depth: Dictionary = GameManager.get_company_market_depth_snapshot(tracked_company_id)
	var impact_player_snapshot: Dictionary = GameManager.get_player_market_impact_snapshot(tracked_company_id)
	var impact_price_bars: Array = impact_snapshot.get("price_bars", [])
	var impact_latest_bar: Dictionary = impact_price_bars[impact_price_bars.size() - 1] if not impact_price_bars.is_empty() else {}
	if (
		float(impact_volume_context.get("player_impact_ratio", 0.0)) <= 0.0 or
		not _broker_rows_contain_code(impact_broker_flow.get("buy_brokers", []), RunState.PLAYER_BROKER_CODE) or
		impact_market_depth.is_empty() or
		float(impact_market_depth.get("ask_depth_value", 0.0)) <= 0.0 or
		float(impact_player_snapshot.get("depth_impact_ratio", 0.0)) <= 0.0 or
		str(impact_latest_bar.get("limit_lock", "")) != "ara" or
		not is_equal_approx(float(impact_latest_bar.get("close", 0.0)), float(impact_snapshot.get("ara_price", 0.0))) or
		not bool(impact_latest_bar.get("locked_through_day", false))
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a large XL buy to affect market depth, lock ARA, and appear in the broker tape."
		}
	var impact_player_buy_value: float = float(impact_player_snapshot.get("buy_value", 0.0))
	if (
		_broker_tape_balance_delta(impact_broker_flow) > max(impact_player_buy_value * 0.015, 1000000.0) or
		_broker_non_player_side_value(impact_broker_flow, "sell", RunState.PLAYER_BROKER_CODE) < impact_player_buy_value * 0.92
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected large XL buys to print with visible counterparty sellers and balanced broker tape."
		}
	var impact_sell_result: Dictionary = RunState.sell_company(tracked_company_id, ownership_test_shares)
	if not bool(impact_sell_result.get("success", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the large impact position to be sellable for the ARB pressure check."
		}
	GameManager.simulate_opening_session(false)
	var sell_impact_snapshot: Dictionary = GameManager.get_company_snapshot(tracked_company_id, true)
	var sell_impact_broker_flow: Dictionary = sell_impact_snapshot.get("broker_flow", {})
	var sell_impact_player_snapshot: Dictionary = GameManager.get_player_market_impact_snapshot(tracked_company_id)
	var sell_impact_price_bars: Array = sell_impact_snapshot.get("price_bars", [])
	var sell_impact_latest_bar: Dictionary = sell_impact_price_bars[sell_impact_price_bars.size() - 1] if not sell_impact_price_bars.is_empty() else {}
	if (
		float(sell_impact_player_snapshot.get("depth_impact_ratio", 0.0)) >= 0.0 or
		not _broker_rows_contain_code(sell_impact_broker_flow.get("sell_brokers", []), RunState.PLAYER_BROKER_CODE) or
		str(sell_impact_latest_bar.get("limit_lock", "")) != "arb" or
		not is_equal_approx(float(sell_impact_latest_bar.get("close", 0.0)), float(sell_impact_snapshot.get("arb_price", 0.0))) or
		not bool(sell_impact_latest_bar.get("locked_through_day", false))
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a large XL sell to affect market depth, lock ARB, and appear in the broker tape."
		}
	var sell_player_sell_value: float = float(sell_impact_player_snapshot.get("sell_value", 0.0))
	if (
		_broker_tape_balance_delta(sell_impact_broker_flow) > max(sell_player_sell_value * 0.015, 1000000.0) or
		_broker_non_player_side_value(sell_impact_broker_flow, "buy", RunState.PLAYER_BROKER_CODE) < sell_player_sell_value * 0.92
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected large XL sells to print with visible counterparty buyers and balanced broker tape."
		}
	RunState.load_from_dict(ownership_test_state)
	game_root._refresh_all()
	await get_tree().process_frame
	var opening_trade_date_key: String = trading_calendar.to_key(RunState.get_current_trade_date())
	if opening_trade_date_key != "2020-01-03":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a fresh run to open on the next trade date after simulating the first session, found %s." % opening_trade_date_key
		}

	var opening_price_history: Array = opening_snapshot.get("price_history", [])
	if opening_price_history.size() < 2:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a fresh run to preload one trading session so opening price history already has at least two closes."
		}

	var opening_price_bars: Array = opening_snapshot.get("price_bars", [])
	if opening_price_bars.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a fresh run to expose daily OHLCV price bars for the chart system."
		}

	var indicator_catalog: Array = GameManager.get_chart_indicator_catalog()
	if indicator_catalog.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the chart system to expose an indicator catalog for future unlocks."
		}

	if opening_financials.is_empty() or float(opening_financials.get("market_cap", 0.0)) <= 0.0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected %s to expose financial stats in the company snapshot." % tracked_company_id.to_upper()
		}

	if opening_statement_snapshot.is_empty() or opening_statement_snapshot.get("income_statement", []).is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected %s to expose derived financial statements in the company snapshot." % tracked_company_id.to_upper()
		}

	if opening_statement_snapshot.get("quarterly_statements", []).size() != 40:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected %s to expose 40 quarters of derived financial statements, found %d." % [
				tracked_company_id.to_upper(),
				opening_statement_snapshot.get("quarterly_statements", []).size()
			]
		}

	if int(opening_statement_snapshot.get("statement_year", 0)) != 2019 or int(opening_statement_snapshot.get("statement_quarter", 0)) != 4:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the latest derived statement period for %s to be Q4 2019, found Q%d %d." % [
				tracked_company_id.to_upper(),
				int(opening_statement_snapshot.get("statement_quarter", 0)),
				int(opening_statement_snapshot.get("statement_year", 0))
			]
		}

	if str(opening_snapshot.get("profile_description", "")).strip_edges().is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected %s to expose a generated narrative company profile description." % tracked_company_id.to_upper()
		}

	if opening_snapshot.get("profile_tags", []).size() < 2:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected %s to expose at least two generated profile tags." % tracked_company_id.to_upper()
		}

	var opening_management_roster: Array = opening_snapshot.get("management_roster", [])
	if opening_management_roster.size() != 3 or not _has_management_roles(opening_management_roster):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected %s to generate CEO, CFO, and Commissioner management insiders." % tracked_company_id.to_upper()
	}
	for company_id_value in RunState.company_order:
		RunState.ensure_company_full_detail(str(company_id_value))
		var roster_snapshot: Dictionary = GameManager.get_company_snapshot(str(company_id_value), false, false, false)
		if roster_snapshot.get("management_roster", []).size() != 3:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected every generated company to have exactly three management insiders."
			}

	if opening_macro_state.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a generated macro state for the starting year."
		}

	if int(opening_macro_state.get("year", 0)) != 2020:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the opening macro year to be 2020, found %s." % opening_macro_state.get("year", 0)
		}

	if str(opening_macro_state.get("central_bank_stance", "")).is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the opening macro state to derive a central bank stance."
		}

	if int(opening_macro_state.get("sector_biases", {}).size()) != DataRepository.get_sector_definitions().size():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected macro sector biases to cover every sector definition."
		}

	var save_round_trip_error: String = _validate_save_round_trip(tracked_company_id, opening_snapshot, opening_macro_state, expected_company_count)
	if not save_round_trip_error.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": save_round_trip_error
		}

	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var company_snapshot: Dictionary = GameManager.get_company_snapshot(company_id)
		if str(company_snapshot.get("sector_name", "Unknown")) == "Unknown":
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected %s to resolve to a known sector name, but its sector lookup failed." % company_id.to_upper()
			}

	if opening_financial_history.size() != 10:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected %s to generate 10 years of financial history, found %d rows." % [
				tracked_company_id.to_upper(),
				opening_financial_history.size()
			]
		}

	var first_financial_year: Dictionary = opening_financial_history[0]
	var last_financial_year: Dictionary = opening_financial_history[opening_financial_history.size() - 1]
	if int(first_financial_year.get("year", 0)) != 2010 or int(last_financial_year.get("year", 0)) != 2019:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected %s financial history to span 2010-2019, found %s-%s." % [
				tracked_company_id.to_upper(),
				first_financial_year.get("year", 0),
				last_financial_year.get("year", 0)
			]
		}

	var financial_history_summary_label: Label = game_root.find_child("FinancialHistorySummaryLabel", true, false) as Label
	var financial_history_rows: VBoxContainer = game_root.find_child("FinancialHistoryRows", true, false) as VBoxContainer
	if financial_history_summary_label == null or financial_history_rows == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the generated company history table in the Trade UI."
		}

	var rendered_history_rows: int = financial_history_rows.get_child_count() - 1
	if not financial_history_summary_label.text.contains("Generated 2010-2019 history") or rendered_history_rows != 10:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the generated company history table to show the 2010-2019 history for %s." % tracked_company_id.to_upper()
		}

	var key_stats_card_names := [
		"KeyStatsCurrentValuationCard",
		"KeyStatsPerShareCard",
		"KeyStatsDividendCard",
		"KeyStatsMetricTableCard",
		"KeyStatsProfitabilityCard",
		"KeyStatsIncomeStatementCard",
		"KeyStatsBalanceSheetCard",
		"KeyStatsCashFlowStatementCard"
	]
	for key_stats_card_name in key_stats_card_names:
		if game_root.find_child(str(key_stats_card_name), true, false) == null:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the Key Stats dashboard card %s to exist." % str(key_stats_card_name)
			}

	var key_stats_dashboard_grid: GridContainer = game_root.find_child("KeyStatsDashboardGrid", true, false) as GridContainer
	var key_stats_scroll: ScrollContainer = game_root.find_child("KeyStats", true, false) as ScrollContainer
	if (
		key_stats_dashboard_grid == null or
		key_stats_dashboard_grid.columns != 3 or
		key_stats_dashboard_grid.custom_minimum_size.x < 800.0 or
		key_stats_scroll == null or
		key_stats_scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_AUTO
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Key Stats to default to the three-column dashboard layout with horizontal scrolling as the narrow-width fallback."
		}

	var key_stats_row_names := [
		"KeyStatsCurrentValuationRows",
		"KeyStatsPerShareRows",
		"KeyStatsDividendRows",
		"KeyStatsMetricTableRows",
		"KeyStatsProfitabilityRows",
		"KeyStatsIncomeStatementRows",
		"KeyStatsBalanceSheetRows",
		"KeyStatsCashFlowStatementRows"
	]
	for key_stats_rows_name in key_stats_row_names:
		var key_stats_rows: VBoxContainer = game_root.find_child(str(key_stats_rows_name), true, false) as VBoxContainer
		if key_stats_rows == null or key_stats_rows.get_child_count() <= 0:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the Key Stats dashboard row group %s to render populated rows." % str(key_stats_rows_name)
			}

	var key_stats_dividend_rows: VBoxContainer = game_root.find_child("KeyStatsDividendRows", true, false) as VBoxContainer
	var key_stats_dividend_text: String = _collect_node_text(key_stats_dividend_rows)
	if (
		key_stats_dividend_text.is_empty() or
		not key_stats_dividend_text.contains("Declared DPS") or
		not key_stats_dividend_text.contains("Payout Ratio") or
		not key_stats_dividend_text.contains("Record / Pay")
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Key Stats to expose the Dividend card with DPS, payout, and timetable rows."
		}

	var key_stats_metric_rows: VBoxContainer = game_root.find_child("KeyStatsMetricTableRows", true, false) as VBoxContainer
	var key_stats_net_income_button: Button = game_root.find_child("KeyStatsMetricNetIncomeButton", true, false) as Button
	var key_stats_eps_button: Button = game_root.find_child("KeyStatsMetricEpsButton", true, false) as Button
	var key_stats_revenue_button: Button = game_root.find_child("KeyStatsMetricRevenueButton", true, false) as Button
	if key_stats_metric_rows == null or key_stats_net_income_button == null or key_stats_eps_button == null or key_stats_revenue_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Key Stats metric table and Net Income/EPS/Revenue pills to exist."
		}

	var key_stats_net_income_text: String = _collect_node_text(key_stats_metric_rows)
	var key_stats_annualised_values: Array = _metric_table_values_for_label(key_stats_metric_rows, "Annualised")
	var key_stats_ttm_values: Array = _metric_table_values_for_label(key_stats_metric_rows, "TTM")
	if key_stats_annualised_values.is_empty() or key_stats_ttm_values.is_empty() or key_stats_annualised_values == key_stats_ttm_values:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Key Stats Annualised to be a quarter run-rate, not a duplicate of TTM."
		}
	key_stats_eps_button.emit_signal("pressed")
	await get_tree().process_frame
	var key_stats_eps_text: String = _collect_node_text(key_stats_metric_rows)
	key_stats_revenue_button.emit_signal("pressed")
	await get_tree().process_frame
	var key_stats_revenue_text: String = _collect_node_text(key_stats_metric_rows)
	if (
		key_stats_net_income_text.is_empty() or
		key_stats_eps_text == key_stats_net_income_text or
		key_stats_revenue_text == key_stats_eps_text or
		key_stats_revenue_text == key_stats_net_income_text
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected switching Key Stats EPS and Revenue pills to rebuild the center metric table."
		}

	var financials_year_helper_label: Label = game_root.find_child("FinancialsYearLabel", true, false) as Label
	var broker_summary_helper_label: Label = game_root.find_child("BrokerSummaryLabel", true, false) as Label
	var broker_meter_helper_label: Label = game_root.find_child("BrokerMeterLabel", true, false) as Label
	if (
		financials_year_helper_label == null or
		financials_year_helper_label.visible or
		not financials_year_helper_label.text.is_empty() or
		broker_summary_helper_label == null or
		broker_summary_helper_label.visible or
		not broker_summary_helper_label.text.is_empty() or
		broker_meter_helper_label == null or
		broker_meter_helper_label.visible or
		not broker_meter_helper_label.text.is_empty()
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Financials and Broker system helper text labels to stay hidden."
		}

	var income_statement_rows: VBoxContainer = game_root.find_child("IncomeStatementRows", true, false) as VBoxContainer
	var balance_sheet_rows: VBoxContainer = game_root.find_child("BalanceSheetRows", true, false) as VBoxContainer
	var cash_flow_rows: VBoxContainer = game_root.find_child("CashFlowRows", true, false) as VBoxContainer
	var financials_previous_button: Button = game_root.find_child("FinancialsPreviousButton", true, false) as Button
	var financials_next_button: Button = game_root.find_child("FinancialsNextButton", true, false) as Button
	if (
		income_statement_rows == null or
		balance_sheet_rows == null or
		cash_flow_rows == null or
		income_statement_rows.get_child_count() <= 1 or
		balance_sheet_rows.get_child_count() <= 1 or
		cash_flow_rows.get_child_count() <= 1 or
		financials_previous_button == null or
		financials_next_button == null or
		financials_previous_button.disabled or
		not financials_next_button.disabled
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the separate Financials tab rows and period navigation to remain populated."
		}

	var range_1d_button: Button = game_root.find_child("Range1DButton", true, false) as Button
	var range_3m_button: Button = game_root.find_child("Range3MButton", true, false) as Button
	var range_6m_button: Button = game_root.find_child("Range6MButton", true, false) as Button
	var range_5y_button: Button = game_root.find_child("Range5YButton", true, false) as Button
	var range_ytd_button: Button = game_root.find_child("RangeYTDButton", true, false) as Button
	var display_line_button: Button = game_root.find_child("DisplayLineButton", true, false) as Button
	var display_candle_button: Button = game_root.find_child("DisplayCandleButton", true, false) as Button
	var zoom_out_button: Button = game_root.find_child("ZoomOutButton", true, false) as Button
	var zoom_in_button: Button = game_root.find_child("ZoomInButton", true, false) as Button
	var chart_meta_label: Label = game_root.find_child("ChartMetaLabel", true, false) as Label
	if range_1d_button == null or range_3m_button == null or range_6m_button == null or range_5y_button == null or range_ytd_button == null or display_line_button == null or display_candle_button == null or zoom_out_button == null or zoom_in_button == null or chart_meta_label == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the Trade chart range, display-mode, or zoom controls."
		}

	range_1d_button.emit_signal("pressed")
	await get_tree().process_frame
	if not chart_meta_label.text.contains("1D |"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Trade chart meta row to switch to the 1D range."
		}
	if not display_candle_button.disabled:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected candle mode to be disabled on the 1D chart."
		}
	if not display_line_button.button_pressed:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the 1D chart to stay in line mode."
		}

	range_3m_button.emit_signal("pressed")
	await get_tree().process_frame
	if not chart_meta_label.text.contains("3M |"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Trade chart meta row to switch to the 3M range."
		}

	range_6m_button.emit_signal("pressed")
	await get_tree().process_frame
	if not chart_meta_label.text.contains("6M |"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Trade chart meta row to switch to the 6M range."
		}

	range_5y_button.emit_signal("pressed")
	await get_tree().process_frame
	if not chart_meta_label.text.contains("5Y |"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Trade chart meta row to switch to the 5Y range."
		}
	if display_candle_button.disabled:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected candle mode to re-enable on the 5Y chart."
		}
	if zoom_in_button.disabled:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the 5Y Trade chart to allow zooming in."
		}
	if not zoom_out_button.disabled:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected zoom-out to stay disabled before any zoom-in action."
		}

	display_candle_button.emit_signal("pressed")
	await get_tree().process_frame
	if not display_candle_button.button_pressed or display_line_button.button_pressed:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Trade chart to switch into candle mode."
		}

	display_line_button.emit_signal("pressed")
	await get_tree().process_frame
	if not display_line_button.button_pressed or display_candle_button.button_pressed:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Trade chart to switch back into line mode."
		}

	zoom_in_button.emit_signal("pressed")
	await get_tree().process_frame
	if zoom_out_button.disabled:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected zoom-out to unlock after zooming into the 5Y chart."
		}

	zoom_out_button.emit_signal("pressed")
	await get_tree().process_frame
	if not zoom_out_button.disabled:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a single zoom-out action to restore the default 5Y zoom level."
		}

	range_ytd_button.emit_signal("pressed")
	await get_tree().process_frame
	if not chart_meta_label.text.contains("YTD |"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Trade chart meta row to switch to the YTD range."
		}

	var opening_chart_1d: Dictionary = GameManager.get_company_chart_snapshot(tracked_company_id, "1d")
	if int(opening_chart_1d.get("visible_point_count", 0)) > 2:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the 1D chart range to stay compact for %s, found %d points." % [
				tracked_company_id.to_upper(),
				int(opening_chart_1d.get("visible_point_count", 0))
			]
		}
	if opening_chart_1d.get("bars", []).is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the refactored chart system to provide visible OHLCV bars for %s." % tracked_company_id.to_upper()
		}

	var opening_chart_5y: Dictionary = GameManager.get_company_chart_snapshot(tracked_company_id, "5y")
	if int(opening_chart_5y.get("visible_bar_count", 0)) < 1200:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the lazy historical chart builder to expose roughly five years of bars for %s, found %d." % [
				tracked_company_id.to_upper(),
				int(opening_chart_5y.get("visible_bar_count", 0))
			]
		}
	if int(opening_chart_5y.get("start_date", {}).get("year", 2020)) >= 2020:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the 5Y chart for %s to reach back before 2020." % tracked_company_id.to_upper()
		}

	var lot_spin_box: SpinBox = game_root.find_child("LotSpinBox", true, false) as SpinBox
	var buy_button: Button = game_root.find_child("BuyButton", true, false) as Button
	var submit_order_button: Button = game_root.find_child("SubmitOrderButton", true, false) as Button
	if lot_spin_box == null or buy_button == null or submit_order_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the stock terminal order-ticket controls needed to place an opening order."
		}

	buy_button.emit_signal("pressed")
	await get_tree().process_frame
	lot_spin_box.value = float(opening_lots)
	await get_tree().process_frame
	submit_order_button.emit_signal("pressed")
	await get_tree().process_frame

	var trade_history_after_buy: Array = GameManager.get_trade_history()
	if trade_history_after_buy.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test buy failed on %s because the dashboard buy button did not produce a trade entry." % difficulty_id
		}

	var broker_rows_vbox: VBoxContainer = game_root.find_child("BrokerRows", true, false) as VBoxContainer
	var broker_header_row: HBoxContainer = game_root.find_child("BrokerHeaderRow", true, false) as HBoxContainer
	var broker_meter_bar: ProgressBar = game_root.find_child("BrokerMeterBar", true, false) as ProgressBar
	if financial_history_summary_label == null or broker_rows_vbox == null or broker_header_row == null or broker_meter_bar == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the Key Stats or Broker widgets needed for the post-buy detail regression check."
		}

	var rendered_broker_rows_after_buy: int = broker_rows_vbox.get_child_count() - 1
	if (
		not financial_history_summary_label.text.contains("Generated 2010-2019 history") or
		rendered_broker_rows_after_buy <= 0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Key Stats history and Broker rows to stay populated after the opening buy refresh."
		}
	if not _broker_table_rows_use_expanding_halves(broker_header_row, broker_rows_vbox):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Broker table header and rows to use the full-width two-sided layout."
		}
	if (
		(broker_summary_helper_label != null and (broker_summary_helper_label.visible or not broker_summary_helper_label.text.is_empty())) or
		(broker_meter_helper_label != null and (broker_meter_helper_label.visible or not broker_meter_helper_label.text.is_empty()))
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Broker helper text to stay hidden after the opening buy refresh."
		}

	var toast_panel: PanelContainer = game_root.find_child("ToastPanel", true, false) as PanelContainer
	var toast_message_label: Label = game_root.find_child("ToastMessageLabel", true, false) as Label
	if toast_panel == null or not toast_panel.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a bottom-right order toast after buying %s." % tracked_company_id.to_upper()
		}
	if toast_message_label == null or toast_message_label.text.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the order toast to include feedback text after buying %s." % tracked_company_id.to_upper()
		}

	if trade_history_after_buy.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected at least one trade history entry after the opening buy."
		}

	var request_success_result: Dictionary = GameManager.accept_contact_request(contact_id, tracked_company_id)
	var daily_actions_before_duplicate_request: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var duplicate_request_result: Dictionary = GameManager.accept_contact_request(contact_id, tracked_company_id)
	var request_failure_result: Dictionary = GameManager.accept_contact_request(contact_id, request_fail_company_id)
	if not bool(request_success_result.get("success", false)) or not bool(request_failure_result.get("success", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network contact requests to be accepted for success and failure paths."
		}
	if int(request_success_result.get("relationship_delta_success", 0)) != 10 or int(request_success_result.get("relationship_delta_failure", 0)) != -4:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network request rewards/failures to expose the tuned relationship deltas."
		}
	if bool(duplicate_request_result.get("success", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected duplicate Network position requests on the same contact and stock to be rejected."
		}
	if int(GameManager.get_daily_action_snapshot().get("used", 0)) != daily_actions_before_duplicate_request + 1:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected duplicate Network request rejection to avoid spending extra daily action points."
		}

	for _request_day in range(3):
		GameManager.advance_day()

	if int(GameManager.get_daily_action_snapshot().get("used", 0)) != 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected daily action points to reset after advancing days."
		}

	var request_snapshot: Dictionary = GameManager.get_network_snapshot()
	if not _has_network_request_status(request_snapshot, tracked_company_id, "completed") or not _has_network_request_status(request_snapshot, request_fail_company_id, "missed"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network requests to complete when holding 1 lot and miss when not holding the target."
		}
	if not _has_contact_arc(contact_id, tracked_company_id, "request"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a completed Network request to create a contact company arc."
		}
	if not _tip_journal_has_resolved_memory():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected pending Network tip memories to resolve after several days."
		}
	if not _tip_journal_has_player_aware_memory():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected resolved Network tip memories to classify player action after the read."
		}
	if not _network_snapshot_has_last_tip_note(request_snapshot):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected resolved Network tip memories to surface as contact last-read notes."
		}
	var followup_contact_id: String = _first_followup_ready_contact_id()
	if followup_contact_id.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected at least one resolved Network tip to be ready for follow-up."
		}
	var daily_actions_before_followup: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var followup_result: Dictionary = GameManager.follow_up_contact_tip(followup_contact_id, "thank")
	if not bool(followup_result.get("success", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a resolved Network tip follow-up to succeed."
		}
	if int(GameManager.get_daily_action_snapshot().get("used", 0)) != daily_actions_before_followup + 1:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network tip follow-up to spend one daily action point."
		}
	if not _tip_journal_has_followup_memory():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network tip follow-up results to be stored in the tip journal."
		}
	var duplicate_followup_result: Dictionary = GameManager.follow_up_contact_tip(followup_contact_id, "thank")
	if bool(duplicate_followup_result.get("success", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a resolved Network tip to allow only one follow-up."
		}
	var followup_save_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(followup_save_state)
	if not _tip_journal_has_followup_memory() or not _network_snapshot_has_followup_note(GameManager.get_network_snapshot()):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network tip follow-up results to persist and surface on contacts."
		}
	if not _network_snapshot_has_tip_history_data(GameManager.get_network_snapshot()):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network contacts to expose compact tip history and reliability data."
		}
	var tip_history_label: Label = game_root.find_child("NetworkTipHistoryLabel", true, false) as Label
	if tip_history_label == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network UI to create the compact read-history label."
		}
	_inject_network_crosscheck_fixture(contact_id, referred_contact_id, tracked_company_id)
	var crosscheck_snapshot: Dictionary = GameManager.get_network_snapshot()
	if not _network_snapshot_has_crosscheck_data(crosscheck_snapshot):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network contacts to expose cross-contact read disagreement data."
		}
	var crosscheck_label: Label = game_root.find_child("NetworkCrosscheckLabel", true, false) as Label
	if crosscheck_label == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network UI to create the source cross-check label."
		}
	var source_check_button: Button = game_root.find_child("NetworkSourceCheckButton", true, false) as Button
	if source_check_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network UI to create the actionable source-check button."
		}
	var daily_actions_before_source_check: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var source_check_result: Dictionary = GameManager.ask_contact_source_check(contact_id)
	if not bool(source_check_result.get("success", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected asking about a conflicting source read to succeed."
		}
	if int(GameManager.get_daily_action_snapshot().get("used", 0)) != daily_actions_before_source_check + 1:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected asking about a source conflict to spend one daily action point."
		}
	if not _tip_journal_has_source_check_memory() or not _network_snapshot_has_source_check_answer(GameManager.get_network_snapshot()):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected source-check answers to persist in the tip journal and surface on contacts."
		}
	game_root.set("selected_network_contact_id", contact_id)
	game_root.call("_refresh_network")
	await get_tree().process_frame
	if (
		not source_check_button.visible or
		not source_check_button.disabled or
		source_check_button.text != "Conflict Asked" or
		crosscheck_label.text.find("Conflict Follow-up") < 0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected asked source conflicts to stay visible with disabled button and follow-up copy."
		}
	var post_source_check_snapshot: Dictionary = GameManager.get_network_snapshot()
	if not _network_snapshot_has_journal_data(post_source_check_snapshot):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network snapshot to expose a recent activity journal with tips, requests, referrals, follow-ups, and source checks."
		}
	var network_journal_list: ItemList = game_root.find_child("NetworkJournalList", true, false) as ItemList
	if network_journal_list == null or network_journal_list.item_count <= 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network UI to render the recent activity journal list."
		}
	var network_detail_scroll: ScrollContainer = game_root.find_child("NetworkDetailScroll", true, false) as ScrollContainer
	var network_journal_detail_label: Label = game_root.find_child("NetworkJournalDetailLabel", true, false) as Label
	if network_detail_scroll == null or network_journal_detail_label == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network detail content to be scrollable and include a Journal detail label."
		}
	var selectable_journal_index: int = -1
	for journal_item_index in range(network_journal_list.item_count):
		var journal_metadata: Variant = network_journal_list.get_item_metadata(journal_item_index)
		if typeof(journal_metadata) == TYPE_DICTIONARY:
			selectable_journal_index = journal_item_index
			break
	if selectable_journal_index < 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected grouped Network Journal rows to keep selectable item metadata below the section headers."
		}
	network_journal_list.select(selectable_journal_index)
	game_root.call("_on_network_journal_selected", selectable_journal_index)
	await get_tree().process_frame
	if not network_journal_detail_label.visible or network_journal_detail_label.text.find("Journal:") < 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected selecting a Network Journal row to show a readable Journal detail panel."
		}
	var network_journal_filter_row: HBoxContainer = game_root.find_child("NetworkJournalFilterRow", true, false) as HBoxContainer
	var network_journal_requests_filter_button: Button = game_root.find_child("NetworkJournalFilterRequestsButton", true, false) as Button
	if network_journal_filter_row == null or network_journal_requests_filter_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network Journal to expose filter buttons."
		}
	network_journal_requests_filter_button.emit_signal("pressed")
	await get_tree().process_frame
	if not network_journal_requests_filter_button.disabled:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the selected Network Journal filter button to become disabled/active."
		}
	var selectable_request_index: int = -1
	for request_item_index in range(network_requests_list.item_count):
		var request_metadata: Variant = network_requests_list.get_item_metadata(request_item_index)
		if typeof(request_metadata) == TYPE_DICTIONARY:
			selectable_request_index = request_item_index
			break
	if selectable_request_index >= 0:
		network_requests_list.select(selectable_request_index)
		game_root.call("_on_network_request_selected", selectable_request_index)
		await get_tree().process_frame
		if not network_journal_detail_label.visible or network_journal_detail_label.text.find("Request:") < 0:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected selecting a Network request row to show request detail context."
			}
	if (
		network_contacts_list.custom_minimum_size.y > 180.0 or
		network_requests_list.custom_minimum_size.y > 110.0 or
		network_journal_list.custom_minimum_size.y > 130.0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Network list column heights to stay compact enough for Contacts, Requests, and Journal."
		}
	var duplicate_source_check_result: Dictionary = GameManager.ask_contact_source_check(contact_id)
	if bool(duplicate_source_check_result.get("success", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a source conflict to allow only one ask."
		}

	for _day in range(max(days_to_advance - 3, 0)):
		GameManager.advance_day()

	var event_history: Array = GameManager.get_event_history()
	var company_framework_event_count: int = _count_company_framework_events(event_history)
	var company_arc_event_count: int = _count_company_arc_events(event_history)
	var person_event_count: int = _count_person_events(event_history)
	var special_event_count: int = _count_special_events(event_history)
	if days_to_advance >= 30 and company_framework_event_count <= 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the longer %s scenario to generate at least one structured company event, but the event log stayed generic." % difficulty_id
		}
	if days_to_advance >= 30 and company_arc_event_count <= 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the longer %s scenario to generate at least one multi-phase company arc, but none were logged." % difficulty_id
		}
	if days_to_advance >= 30 and person_event_count <= 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the longer %s scenario to generate at least one person-of-interest event, but none were logged." % difficulty_id
		}
	if days_to_advance >= 30 and special_event_count <= 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the longer %s scenario to generate at least one multi-day special event arc, but none were logged." % difficulty_id
		}
	if days_to_advance >= 30:
		var debug_toggle_event: InputEventKey = InputEventKey.new()
		debug_toggle_event.pressed = true
		debug_toggle_event.ctrl_pressed = true
		debug_toggle_event.keycode = KEY_L
		game_root._unhandled_input(debug_toggle_event)
		await get_tree().process_frame

		var debug_overlay: Control = game_root.find_child("DebugOverlay", true, false) as Control
		var upcoming_events_label: RichTextLabel = game_root.find_child("UpcomingEventsLabel", true, false) as RichTextLabel
		var current_events_label: RichTextLabel = game_root.find_child("CurrentEventsLabel", true, false) as RichTextLabel
		var special_events_label: RichTextLabel = game_root.find_child("SpecialEventsLabel", true, false) as RichTextLabel
		var person_events_label: RichTextLabel = game_root.find_child("PersonEventsLabel", true, false) as RichTextLabel
		var stock_performance_label: RichTextLabel = game_root.find_child("StockPerformanceLabel", true, false) as RichTextLabel
		var market_history_label: RichTextLabel = game_root.find_child("MarketHistoryLabel", true, false) as RichTextLabel
		if debug_overlay == null or not debug_overlay.visible:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Ctrl+L to open the debug popup during the longer %s scenario." % difficulty_id
			}
		if upcoming_events_label == null or upcoming_events_label.text.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug popup to populate upcoming company-event text."
			}
		if current_events_label == null or current_events_label.text.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug popup to populate current company-event text."
			}
		if special_events_label == null or special_events_label.text.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug popup to populate special-event text."
			}
		if person_events_label == null or person_events_label.text.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug popup to populate person-event text."
			}
		if stock_performance_label == null or stock_performance_label.text.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug popup to populate stock-performance text."
			}
		if market_history_label == null or market_history_label.text.is_empty():
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug popup to populate market performance history."
			}

	for company_id in RunState.company_order:
		var snapshot: Dictionary = GameManager.get_company_snapshot(str(company_id))
		var current_price: float = float(snapshot.get("current_price", 0.0))
		if not is_equal_approx(current_price, round(current_price)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected IDX-snapped integer last prices, found %s for %s." % [current_price, company_id]
			}
		var ara_price: float = float(snapshot.get("ara_price", current_price))
		var arb_price: float = float(snapshot.get("arb_price", current_price))
		if current_price > ara_price + 0.0001 or current_price < arb_price - 0.0001:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected %s to stay inside ARA/ARB band %s-%s, found %s." % [
					company_id,
					arb_price,
					ara_price,
					current_price
				]
			}

	var summary: Dictionary = GameManager.get_latest_summary()
	if summary.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a summary after %d days." % days_to_advance
		}

	var tracked_runtime: Dictionary = RunState.get_company(tracked_company_id)
	var tracked_history: Array = tracked_runtime.get("price_history", [])
	var down_days: int = _count_down_days(tracked_history)
	var closing_price: float = float(tracked_runtime.get("current_price", opening_price))
	var current_trade_date_key: String = trading_calendar.to_key(RunState.get_current_trade_date())
	if require_pullback and down_days <= 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected at least one down day for %s on %s, but the 30-day path stayed one-way (open=%s, close=%s)." % [
				tracked_company_id.to_upper(),
				difficulty_id,
				opening_price,
				closing_price
			]
		}

	var expected_trade_date_key: String = trading_calendar.to_key(trading_calendar.trade_date_for_index(days_to_advance + 2))
	if difficulty_id == GameManager.DEFAULT_DIFFICULTY_ID and current_trade_date_key != expected_trade_date_key:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the next trade date after the preloaded opening session plus %d more days to be %s, found %s." % [
				days_to_advance,
				expected_trade_date_key,
				current_trade_date_key
			]
		}

	var result: Dictionary = {
		"success": true,
		"equity": float(GameManager.get_portfolio_snapshot().get("equity", 0.0)),
		"summary": str(summary.get("explanation", "")),
		"down_days": down_days,
		"company_framework_event_count": company_framework_event_count,
		"company_arc_event_count": company_arc_event_count,
		"person_event_count": person_event_count,
		"special_event_count": special_event_count,
		"opening_price": opening_price,
		"closing_price": closing_price,
		"current_trade_date_key": current_trade_date_key
	}
	game_root.queue_free()
	await get_tree().process_frame
	return result


func _validate_life_smoke(game_root: Node, life_app_button: Button, life_window: Control, desktop_layer: Control) -> String:
	if life_app_button == null:
		return "Smoke test expected the Life desktop icon to exist."

	var baseline_state: Dictionary = RunState.to_save_dict()
	var legacy_state: Dictionary = baseline_state.duplicate(true)
	legacy_state.erase("player_life")
	RunState.load_from_dict(legacy_state)
	var backfilled_life: Dictionary = RunState.get_player_life()
	if str(backfilled_life.get("housing_id", "")).is_empty() or str(backfilled_life.get("lifestyle_id", "")).is_empty():
		return "Smoke test expected old saves without player_life to backfill a default Life plan."
	if (
		str(backfilled_life.get("basics_tier_id", "")) != RunState.LIFE_DEFAULT_BASICS_TIER_ID or
		int(round(float(backfilled_life.get("stress_value", -1.0)))) != int(RunState.LIFE_DEFAULT_STRESS_VALUE) or
		int(round(float(backfilled_life.get("happiness_value", -1.0)))) != int(RunState.LIFE_DEFAULT_HAPPINESS_VALUE) or
		int(backfilled_life.get("hospital_days_remaining", -1)) != 0
	):
		return "Smoke test expected old saves without player_life to backfill Life wellbeing defaults."
	var legacy_finance_state: Dictionary = baseline_state.duplicate(true)
	legacy_finance_state["save_schema_version"] = 3
	var legacy_life_state: Dictionary = legacy_finance_state.get("player_life", {}).duplicate(true)
	legacy_life_state.erase("finance")
	legacy_life_state.erase("basics_tier_id")
	legacy_life_state.erase("stress_value")
	legacy_life_state.erase("happiness_value")
	legacy_life_state.erase("burnout_risk_active")
	legacy_life_state.erase("burnout_risk_days_remaining")
	legacy_life_state.erase("hospital_days_remaining")
	legacy_life_state.erase("hospital_started_day_index")
	legacy_life_state.erase("last_hospital_trade_date")
	legacy_finance_state["player_life"] = legacy_life_state
	RunState.load_from_dict(legacy_finance_state)
	var backfilled_finance: Dictionary = RunState.get_life_finance()
	backfilled_life = RunState.get_player_life()
	if (
		not backfilled_finance.has("active_loan") or
		not backfilled_finance.has("cash_stress_active") or
		not backfilled_finance.has("bankrupt") or
		bool(backfilled_finance.get("bankrupt", false))
	):
		return "Smoke test expected v3 saves without Life finance to backfill empty loan, cash stress, and bankruptcy state."
	if (
		str(backfilled_life.get("basics_tier_id", "")) != RunState.LIFE_DEFAULT_BASICS_TIER_ID or
		int(round(float(backfilled_life.get("stress_value", -1.0)))) != int(RunState.LIFE_DEFAULT_STRESS_VALUE) or
		int(round(float(backfilled_life.get("happiness_value", -1.0)))) != int(RunState.LIFE_DEFAULT_HAPPINESS_VALUE)
	):
		return "Smoke test expected old Life saves without wellbeing fields to backfill defaults."

	RunState.load_from_dict(baseline_state)
	game_root._refresh_all()
	await get_tree().process_frame

	life_app_button.emit_signal("pressed")
	await get_tree().process_frame
	await _wait_for_ui_animation_settle()

	if life_window == null:
		life_window = game_root.find_child("LifeWindow", true, false) as Control
	var life_summary_label: Label = game_root.find_child("LifeSummaryLabel", true, false) as Label
	var life_housing_option: OptionButton = game_root.find_child("LifeHousingOption", true, false) as OptionButton
	var life_basics_slider: HSlider = game_root.find_child("LifeBasicsSlider", true, false) as HSlider
	var life_lifestyle_option: OptionButton = game_root.find_child("LifeLifestyleOption", true, false) as OptionButton
	var life_update_button: Button = game_root.find_child("LifeUpdatePlanButton", true, false) as Button
	var life_budget_rows: VBoxContainer = game_root.find_child("LifeBudgetRows", true, false) as VBoxContainer
	var life_runway_label: Label = game_root.find_child("LifeRunwayLabel", true, false) as Label
	var life_stress_label: Label = game_root.find_child("LifeStressLabel", true, false) as Label
	var life_happiness_label: Label = game_root.find_child("LifeHappinessLabel", true, false) as Label
	var life_stress_ap_penalty_label: Label = game_root.find_child("LifeStressApPenaltyLabel", true, false) as Label
	var life_basics_detail_label: Label = game_root.find_child("LifeBasicsDetailLabel", true, false) as Label
	var life_dividend_rows: VBoxContainer = game_root.find_child("LifeDividendRows", true, false) as VBoxContainer
	var life_tabs: TabContainer = game_root.find_child("LifeTabs", true, false) as TabContainer
	var life_overview_tab: Control = game_root.find_child("LifeOverviewTab", true, false) as Control
	var life_finance_tab: Control = game_root.find_child("LifeFinanceTab", true, false) as Control
	var life_finance_status_label: Label = game_root.find_child("LifeFinanceStatusLabel", true, false) as Label
	var life_emergency_loan_button: Button = game_root.find_child("LifeEmergencyLoanButton", true, false) as Button
	var life_active_loan_panel: PanelContainer = game_root.find_child("LifeActiveLoanPanel", true, false) as PanelContainer
	var life_bankruptcy_status_panel: PanelContainer = game_root.find_child("LifeBankruptcyStatusPanel", true, false) as PanelContainer
	var stress_meter_panel: Control = game_root.find_child("LifeStressMeterPanel", true, false) as Control
	var stress_meter_bar: ProgressBar = game_root.find_child("LifeStressMeterBar", true, false) as ProgressBar
	var stress_meter_title_label: Label = game_root.find_child("LifeStressMeterTitleLabel", true, false) as Label
	var hospital_overlay: Control = game_root.find_child("HospitalOverlay", true, false) as Control
	var hospital_advance_button: Button = game_root.find_child("HospitalAdvanceDayButton", true, false) as Button
	var life_snapshot: Dictionary = GameManager.get_life_snapshot()
	if (
		life_window == null or
		not life_window.visible or
		not game_root.is_desktop_app_open("life") or
		game_root.get_active_desktop_app_id() != "life" or
		game_root.get_desktop_app_window_title("life") != "Life" or
		not _desktop_window_animation_settled(game_root, "LifeDesktopWindow") or
		not _desktop_window_has_settings_brown_chrome(game_root, "LifeDesktopWindow") or
		life_summary_label == null or
		life_summary_label.text.find("Monthly outflow") == -1 or
		life_housing_option == null or
		life_housing_option.item_count < 3 or
		life_basics_slider == null or
		life_basics_slider.min_value != 0.0 or
		life_basics_slider.max_value != 3.0 or
		life_lifestyle_option == null or
		life_lifestyle_option.item_count < 3 or
		life_update_button == null or
		life_budget_rows == null or
		life_budget_rows.get_child_count() < 5 or
		life_runway_label == null or
		life_runway_label.text.is_empty() or
		life_stress_label == null or
		life_stress_label.text.is_empty() or
		life_happiness_label == null or
		life_happiness_label.text.is_empty() or
		life_stress_ap_penalty_label == null or
		life_stress_ap_penalty_label.text.is_empty() or
		life_basics_detail_label == null or
		not life_basics_detail_label.text.contains("Stress") or
		life_dividend_rows == null or
		life_tabs == null or
		life_overview_tab == null or
		life_finance_tab == null or
		life_finance_status_label == null or
		life_emergency_loan_button == null or
		life_active_loan_panel == null or
		life_bankruptcy_status_panel == null or
		stress_meter_panel == null or
		not stress_meter_panel.visible or
		stress_meter_panel.get_parent() == null or
		stress_meter_panel.get_parent().name != "DesktopVBox" or
		stress_meter_bar == null or
		float(stress_meter_bar.max_value) != 100.0 or
		stress_meter_title_label == null or
		stress_meter_title_label.text != "STRESS LEVEL" or
		hospital_overlay == null or
		hospital_advance_button == null or
		life_snapshot.is_empty() or
		not life_snapshot.has("finance") or
		not life_snapshot.has("basics_tiers") or
		life_snapshot.get("basics_tiers", []).size() != 4 or
		not life_snapshot.has("basics_tier") or
		not life_snapshot.has("stress_stage") or
		not life_snapshot.has("stress_ap_penalty") or
		float(life_snapshot.get("monthly_outflow", 0.0)) <= 0.0 or
		not life_snapshot.has("housing_options") or
		not life_snapshot.has("lifestyle_options")
	):
		return "Smoke test expected the Life icon to open a settled brown-framed cash-flow planning window with populated selectors, basics controls, stress readouts, budget rows, and runway summary."

	var starting_lifestyle_id: String = str(RunState.get_player_life().get("lifestyle_id", ""))
	var starting_basics_tier_id: String = str(RunState.get_player_life().get("basics_tier_id", ""))
	var target_lifestyle_index: int = -1
	for index in range(life_lifestyle_option.item_count):
		if str(life_lifestyle_option.get_item_metadata(index)) != starting_lifestyle_id:
			target_lifestyle_index = index
			break
	if target_lifestyle_index < 0:
		return "Smoke test expected Life to expose at least one alternate lifestyle choice."
	var basics_tiers: Array = life_snapshot.get("basics_tiers", [])
	var target_basics_index: int = -1
	var target_basics_id: String = ""
	var target_basics_cost: float = 0.0
	for basics_index in range(basics_tiers.size()):
		var tier_value: Variant = basics_tiers[basics_index]
		if typeof(tier_value) != TYPE_DICTIONARY:
			continue
		var tier: Dictionary = tier_value
		if str(tier.get("id", "")) == starting_basics_tier_id:
			continue
		target_basics_index = basics_index
		target_basics_id = str(tier.get("id", ""))
		target_basics_cost = float(tier.get("monthly_cost", 0.0))
		break
	if target_basics_index < 0 or target_basics_id.is_empty():
		return "Smoke test expected Life to expose at least one alternate Basics tier."
	var target_lifestyle_id: String = str(life_lifestyle_option.get_item_metadata(target_lifestyle_index))
	life_lifestyle_option.select(target_lifestyle_index)
	life_lifestyle_option.emit_signal("item_selected", target_lifestyle_index)
	life_basics_slider.value = float(target_basics_index)
	life_basics_slider.emit_signal("value_changed", float(target_basics_index))
	life_update_button.emit_signal("pressed")
	await get_tree().process_frame
	if str(RunState.get_player_life().get("lifestyle_id", "")) != target_lifestyle_id:
		return "Smoke test expected updating the Life plan to persist the selected lifestyle."
	if str(RunState.get_player_life().get("basics_tier_id", "")) != target_basics_id:
		return "Smoke test expected updating the Life plan to persist the selected Basics tier."
	var basics_updated_snapshot: Dictionary = GameManager.get_life_snapshot()
	if absf(float(basics_updated_snapshot.get("basic_expenses_monthly", 0.0)) - target_basics_cost) > 0.01:
		return "Smoke test expected the selected Basics tier cost to drive Life monthly outflow."
	if not SaveManager.has_pending_save():
		return "Smoke test expected updating the Life plan to queue an autosave."

	var saved_life_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(saved_life_state)
	if str(RunState.get_player_life().get("lifestyle_id", "")) != target_lifestyle_id:
		return "Smoke test expected Life plan choices to survive a RunState save/load round trip."
	if str(RunState.get_player_life().get("basics_tier_id", "")) != target_basics_id:
		return "Smoke test expected Basics tier choice to survive a RunState save/load round trip."
	if not SaveManager.flush_pending_save():
		return "Smoke test expected Life autosave flush to succeed."
	var persisted_life_state: Dictionary = SaveManager.load_run()
	if str(persisted_life_state.get("player_life", {}).get("lifestyle_id", "")) != target_lifestyle_id:
		return "Smoke test expected flushed Life saves to persist player_life to disk."
	if str(persisted_life_state.get("player_life", {}).get("basics_tier_id", "")) != target_basics_id:
		return "Smoke test expected flushed Life saves to persist player_life Basics tier to disk."

	var wellbeing_test_state: Dictionary = RunState.to_save_dict()
	var base_ap_limit: int = RunState.get_daily_action_base_limit()
	var wellbeing_life: Dictionary = RunState.get_player_life()
	wellbeing_life["stress_value"] = 65.0
	wellbeing_life["happiness_value"] = 25.0
	wellbeing_life["burnout_risk_active"] = false
	wellbeing_life["burnout_risk_days_remaining"] = 0
	wellbeing_life["hospital_days_remaining"] = 0
	RunState.set_player_life(wellbeing_life)
	game_root._refresh_all()
	await get_tree().process_frame
	stress_meter_bar = game_root.find_child("LifeStressMeterBar", true, false) as ProgressBar
	if (
		RunState.get_life_stress_ap_penalty() != 2 or
		RunState.get_daily_action_limit() != max(base_ap_limit - 2, 1) or
		stress_meter_bar == null or
		int(round(float(stress_meter_bar.value))) != 65
	):
		return "Smoke test expected stress in the 60s to apply a 2 AP pressure penalty and update the top stress meter."

	wellbeing_life = RunState.get_player_life()
	wellbeing_life["stress_value"] = 100.0
	wellbeing_life["happiness_value"] = 35.0
	wellbeing_life["burnout_risk_active"] = false
	wellbeing_life["burnout_risk_days_remaining"] = 0
	wellbeing_life["hospital_days_remaining"] = 0
	RunState.set_player_life(wellbeing_life)
	GameManager.advance_day()
	await get_tree().process_frame
	var burnout_warning_life: Dictionary = RunState.get_player_life()
	if (
		not bool(burnout_warning_life.get("burnout_risk_active", false)) or
		int(burnout_warning_life.get("burnout_risk_days_remaining", 0)) != RunState.LIFE_BURNOUT_WARNING_TRADING_DAYS or
		int(burnout_warning_life.get("hospital_days_remaining", 0)) != 0
	):
		return "Smoke test expected stress 100 to start a burnout warning countdown before hospital."

	burnout_warning_life["stress_value"] = 100.0
	burnout_warning_life["burnout_risk_active"] = true
	burnout_warning_life["burnout_risk_days_remaining"] = 1
	burnout_warning_life["hospital_days_remaining"] = 0
	RunState.set_player_life(burnout_warning_life)
	GameManager.advance_day()
	await get_tree().process_frame
	var hospital_life: Dictionary = RunState.get_player_life()
	if int(hospital_life.get("hospital_days_remaining", 0)) != RunState.LIFE_HOSPITAL_TRADING_DAYS:
		return "Smoke test expected staying at stress 100 through the warning countdown to start two hospital trading days."
	if RunState.get_daily_action_limit() != 0:
		return "Smoke test expected hospital recovery to reduce the AP limit to zero."
	var hospital_buy_result: Dictionary = GameManager.buy_lots(str(RunState.company_order[0]), 1)
	if bool(hospital_buy_result.get("success", false)) or not str(hospital_buy_result.get("message", "")).contains("Hospital recovery"):
		return "Smoke test expected hospital recovery to block trading actions."
	if not GameManager.get_life_action_block_reason("advance_day").is_empty():
		return "Smoke test expected hospital recovery to keep Advance Day available."
	game_root._refresh_all()
	await get_tree().process_frame
	hospital_overlay = game_root.find_child("HospitalOverlay", true, false) as Control
	hospital_advance_button = game_root.find_child("HospitalAdvanceDayButton", true, false) as Button
	if hospital_overlay == null or not hospital_overlay.visible or hospital_advance_button == null or hospital_advance_button.disabled:
		return "Smoke test expected hospital recovery to show a blocking overlay with only Advance Day available."

	GameManager.advance_day()
	await get_tree().process_frame
	if int(RunState.get_player_life().get("hospital_days_remaining", 0)) != 1:
		return "Smoke test expected the first hospital Advance Day to decrement remaining recovery days."
	GameManager.advance_day()
	await get_tree().process_frame
	var recovered_life: Dictionary = RunState.get_player_life()
	if (
		int(recovered_life.get("hospital_days_remaining", 0)) != 0 or
		int(round(float(recovered_life.get("stress_value", 0.0)))) != int(RunState.LIFE_HOSPITAL_RECOVERY_STRESS) or
		int(round(float(recovered_life.get("happiness_value", 0.0)))) != int(RunState.LIFE_HOSPITAL_RECOVERY_HAPPINESS) or
		RunState.get_daily_action_limit() <= 0
	):
		return "Smoke test expected hospital recovery to end after two Advance Days and reset stress/happiness to recovery values."
	game_root._refresh_all()
	await get_tree().process_frame
	hospital_overlay = game_root.find_child("HospitalOverlay", true, false) as Control
	if hospital_overlay != null and hospital_overlay.visible:
		return "Smoke test expected the hospital overlay to hide after recovery ends."

	RunState.load_from_dict(wellbeing_test_state)
	game_root._refresh_all()
	await get_tree().process_frame

	var monthly_obligation_snapshot: Dictionary = GameManager.get_life_snapshot()
	var monthly_obligation_due: float = float(monthly_obligation_snapshot.get("monthly_outflow", 0.0))
	if monthly_obligation_due <= 0.0 or not str(monthly_obligation_snapshot.get("note", "")).contains("deduct cash"):
		return "Smoke test expected Life monthly obligations to be marked as real cash deductions."
	var life_before_monthly_obligation_state: Dictionary = RunState.to_save_dict()
	var cash_before_monthly_obligation: float = float(GameManager.get_portfolio_snapshot().get("cash", 0.0))
	RunState.current_trade_date = trading_calendar.trade_date_on_or_after(2020, 1, 31)
	GameManager.advance_day()
	await get_tree().process_frame
	var cash_after_monthly_obligation: float = float(GameManager.get_portfolio_snapshot().get("cash", 0.0))
	if absf(cash_after_monthly_obligation - (cash_before_monthly_obligation - monthly_obligation_due)) > 0.01:
		return "Smoke test expected crossing into a new month to deduct the Life monthly outflow from player cash."
	var monthly_life_state: Dictionary = RunState.get_player_life()
	if str(monthly_life_state.get("last_obligation_period", "")) != "2020-02":
		return "Smoke test expected the Life state to remember the paid monthly obligation period."
	var monthly_obligation_trade_found: bool = false
	for monthly_trade_value in GameManager.get_trade_history():
		if typeof(monthly_trade_value) == TYPE_DICTIONARY and str(monthly_trade_value.get("side", "")).to_lower() == "life_obligation":
			monthly_obligation_trade_found = true
			break
	if not monthly_obligation_trade_found:
		return "Smoke test expected monthly Life obligations to appear in portfolio history."
	RunState.load_from_dict(life_before_monthly_obligation_state)
	game_root._refresh_all()
	await get_tree().process_frame

	var finance_test_base_state: Dictionary = RunState.to_save_dict()
	var finance_company_id: String = str(RunState.company_order[0])
	var finance_buy_result: Dictionary = GameManager.buy_lots(finance_company_id, 1)
	if not bool(finance_buy_result.get("success", false)):
		return "Smoke test expected buying one lot for Life Finance recovery coverage to succeed."
	var finance_company_price: float = max(float(RunState.get_company(finance_company_id).get("current_price", 0.0)), 1.0)
	var recovery_lots: int = max(int(ceil(4000000.0 / max(finance_company_price * float(GameManager.get_lot_size()), 1.0))), 1)
	var recovery_holding: Dictionary = RunState.get_holding(finance_company_id).duplicate(true)
	recovery_holding["company_id"] = finance_company_id
	recovery_holding["shares"] = max(int(recovery_holding.get("shares", 0)), GameManager.lots_to_shares(recovery_lots))
	recovery_holding["average_price"] = finance_company_price
	var recovery_holdings: Dictionary = RunState.player_portfolio.get("holdings", {}).duplicate(true)
	recovery_holdings[finance_company_id] = recovery_holding
	RunState.player_portfolio["holdings"] = recovery_holdings
	var finance_monthly_snapshot: Dictionary = GameManager.get_life_snapshot()
	var finance_monthly_due: float = float(finance_monthly_snapshot.get("monthly_outflow", 0.0))
	if finance_monthly_due <= 0.0:
		return "Smoke test expected a positive Life outflow for cash-stress coverage."
	RunState.current_trade_date = trading_calendar.trade_date_on_or_after(2020, 1, 31)
	RunState.player_portfolio["cash"] = finance_monthly_due - 100000.0
	RunState.refresh_cash_stress_state()
	GameManager.advance_day()
	await get_tree().process_frame
	var negative_finance_status: Dictionary = GameManager.get_finance_status_snapshot()
	if (
		float(negative_finance_status.get("cash", 0.0)) >= 0.0 or
		not bool(negative_finance_status.get("cash_stress_active", false)) or
		int(negative_finance_status.get("cash_stress_days_remaining", -1)) != 3
	):
		return "Smoke test expected forced Life obligation to push cash negative and start a three-trading-day grace window."
	var negative_cash_state: Dictionary = RunState.to_save_dict()
	var negative_buy_result: Dictionary = GameManager.buy_lots(finance_company_id, 1)
	var stress_sell_result: Dictionary = GameManager.sell_lots(finance_company_id, 1)
	if (
		bool(negative_buy_result.get("success", false)) or
		not str(negative_buy_result.get("message", "")).contains("Cash is negative") or
		not bool(stress_sell_result.get("success", false))
	):
		return "Smoke test expected negative cash to block buys while still allowing sell recovery."

	RunState.load_from_dict(negative_cash_state)
	game_root._refresh_all()
	await get_tree().process_frame
	life_tabs = game_root.find_child("LifeTabs", true, false) as TabContainer
	if life_tabs == null:
		return "Smoke test expected the Life tabs to remain available during cash stress."
	life_tabs.current_tab = 1
	await get_tree().process_frame
	life_finance_status_label = game_root.find_child("LifeFinanceStatusLabel", true, false) as Label
	life_emergency_loan_button = game_root.find_child("LifeEmergencyLoanButton", true, false) as Button
	if (
		life_finance_status_label == null or
		not life_finance_status_label.text.contains("Cash stress") or
		life_emergency_loan_button == null or
		life_emergency_loan_button.disabled
	):
		return "Smoke test expected Life > Finance to show cash stress and an eligible emergency loan."
	var emergency_loan_result: Dictionary = GameManager.take_emergency_loan()
	if not bool(emergency_loan_result.get("success", false)):
		return "Smoke test expected taking an eligible emergency loan to succeed."
	var loan_finance_status: Dictionary = GameManager.get_finance_status_snapshot()
	var active_loan: Dictionary = loan_finance_status.get("active_loan", {})
	if active_loan.is_empty() or float(loan_finance_status.get("cash", 0.0)) <= 0.0:
		return "Smoke test expected emergency loan proceeds to restore positive cash and create an active loan."
	var loan_save_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(loan_save_state)
	var reloaded_active_loan: Dictionary = RunState.get_life_finance().get("active_loan", {})
	if reloaded_active_loan.is_empty():
		return "Smoke test expected the active emergency loan to survive save/load normalization."

	var loan_monthly_payment: float = float(active_loan.get("monthly_payment", 0.0))
	RunState.load_from_dict(loan_save_state)
	RunState.player_portfolio["cash"] = loan_monthly_payment - 1.0
	RunState.refresh_cash_stress_state()
	var reserve_block_result: Dictionary = GameManager.buy_lots(finance_company_id, 1)
	if (
		bool(reserve_block_result.get("success", false)) or
		not str(reserve_block_result.get("message", "")).contains("loan payment reserve")
	):
		return "Smoke test expected an active loan to block exploit buying when payment reserve cash is not covered."

	RunState.load_from_dict(loan_save_state)
	RunState.current_trade_date = trading_calendar.trade_date_on_or_after(2020, 2, 28)
	GameManager.advance_day()
	await get_tree().process_frame
	var loan_payment_result: Dictionary = RunState.last_day_results.get("life_loan_payment", {})
	if loan_payment_result.is_empty() or float(loan_payment_result.get("amount", 0.0)) <= 0.0:
		return "Smoke test expected monthly loan payment to apply on the next month boundary."

	RunState.load_from_dict(negative_cash_state)
	var expired_recovery_finance: Dictionary = RunState.get_life_finance()
	expired_recovery_finance["cash_stress_deadline_day_index"] = RunState.day_index
	RunState.set_life_finance(expired_recovery_finance)
	var recovery_gate: Dictionary = GameManager.resolve_advance_day_finance_gate()
	if (
		bool(recovery_gate.get("success", false)) or
		bool(recovery_gate.get("bankrupt", false)) or
		not str(recovery_gate.get("message", "")).contains("Sell holdings")
	):
		return "Smoke test expected expired grace to block Advance Day when holdings can still cover the deficit."

	RunState.load_from_dict(negative_cash_state)
	RunState.player_portfolio["holdings"] = {}
	RunState.player_portfolio["cash"] = -2000000.0
	RunState.refresh_cash_stress_state()
	var bankruptcy_finance: Dictionary = RunState.get_life_finance()
	bankruptcy_finance["active_loan"] = {}
	bankruptcy_finance["cash_stress_deadline_day_index"] = RunState.day_index
	RunState.set_life_finance(bankruptcy_finance)
	var bankruptcy_gate: Dictionary = GameManager.resolve_advance_day_finance_gate()
	if not bool(bankruptcy_gate.get("bankrupt", false)) or not RunState.is_bankrupt():
		return "Smoke test expected bankruptcy to trigger only after expired grace with no holdings or loan recovery path."
	var bankrupt_buy_result: Dictionary = GameManager.buy_lots(finance_company_id, 1)
	var bankrupt_loan_result: Dictionary = GameManager.take_emergency_loan()
	if (
		bool(bankrupt_buy_result.get("success", false)) or
		not str(bankrupt_buy_result.get("message", "")).contains("Bankruptcy") or
		bool(bankrupt_loan_result.get("success", false))
	):
		return "Smoke test expected bankruptcy to disable trading and new emergency loans."
	game_root.call("_show_bankruptcy_overlay", bankruptcy_gate.get("bankruptcy", {}))
	await get_tree().process_frame
	var bankruptcy_overlay: Control = game_root.find_child("BankruptcyOverlay", true, false) as Control
	var bankruptcy_menu_button: Button = game_root.find_child("BankruptcyMenuButton", true, false) as Button
	var bankruptcy_restart_button: Button = game_root.find_child("BankruptcyRestartButton", true, false) as Button
	if bankruptcy_overlay == null or not bankruptcy_overlay.visible or bankruptcy_menu_button == null or bankruptcy_restart_button == null:
		return "Smoke test expected bankruptcy to show the final-state overlay with menu and restart buttons."
	bankruptcy_overlay.visible = false

	RunState.load_from_dict(finance_test_base_state)
	game_root._refresh_all()
	await get_tree().process_frame

	var dividend_company_id: String = str(RunState.company_order[0])
	var dividend_buy_result: Dictionary = GameManager.buy_lots(dividend_company_id, 1)
	if not bool(dividend_buy_result.get("success", false)):
		return "Smoke test expected buying one lot for dividend coverage to succeed."
	var dividend_schedule_result: Dictionary = GameManager.debug_schedule_next_day_cash_dividend(dividend_company_id)
	var scheduled_dividend: Dictionary = dividend_schedule_result.get("dividend", {})
	if (
		not bool(dividend_schedule_result.get("success", false)) or
		scheduled_dividend.is_empty() or
		float(scheduled_dividend.get("amount_per_share", 0.0)) <= 0.0
	):
		return "Smoke test expected debug dividend scheduling to create a cash dividend action with DPS."
	var dividend_id: String = str(scheduled_dividend.get("id", ""))
	var dividend_snapshot: Dictionary = GameManager.get_corporate_dividend_snapshot(dividend_company_id)
	if dividend_snapshot.get("upcoming_rows", []).is_empty():
		return "Smoke test expected scheduled dividends to appear in the corporate dividend snapshot."

	GameManager.advance_day()
	await get_tree().process_frame
	var life_after_dividend_approval: Dictionary = GameManager.get_life_snapshot()
	if (
		float(life_after_dividend_approval.get("declared_dividend_total_12m", 0.0)) <= 0.0 or
		life_after_dividend_approval.get("dividend_rows", []).is_empty()
	):
		return "Smoke test expected Life to use declared dividend corporate actions instead of synthetic dividend estimates."

	GameManager.advance_day()
	await get_tree().process_frame
	GameManager.advance_day()
	await get_tree().process_frame
	dividend_snapshot = GameManager.get_corporate_dividend_snapshot(dividend_company_id)
	var cash_dividend_recorded_shares: int = -1
	for recorded_cash_row_value in dividend_snapshot.get("declared_rows", []):
		if typeof(recorded_cash_row_value) != TYPE_DICTIONARY:
			continue
		var recorded_cash_row: Dictionary = recorded_cash_row_value
		if str(recorded_cash_row.get("id", "")) == dividend_id and bool(recorded_cash_row.get("shareholder_recorded", false)):
			cash_dividend_recorded_shares = int(recorded_cash_row.get("eligible_shares", 0))
			break
	if cash_dividend_recorded_shares < GameManager.get_lot_size():
		return "Smoke test expected cash dividend record-date capture to preserve the held shares."
	var cash_dividend_sell_result: Dictionary = GameManager.sell_lots(dividend_company_id, 1)
	if not bool(cash_dividend_sell_result.get("success", false)):
		return "Smoke test expected selling the dividend holding after record date to succeed."
	if int(RunState.get_holding(dividend_company_id).get("shares", 0)) >= cash_dividend_recorded_shares:
		return "Smoke test expected current shares to fall below recorded cash-dividend eligibility after selling."
	var cash_before_dividend_payment: float = float(GameManager.get_portfolio_snapshot().get("cash", 0.0))
	GameManager.advance_day()
	await get_tree().process_frame
	dividend_snapshot = GameManager.get_corporate_dividend_snapshot(dividend_company_id)
	var paid_dividend_found: bool = false
	for paid_row_value in dividend_snapshot.get("paid_rows", []):
		if typeof(paid_row_value) != TYPE_DICTIONARY:
			continue
		var paid_row: Dictionary = paid_row_value
		if str(paid_row.get("id", "")) == dividend_id and float(paid_row.get("paid_amount", 0.0)) > 0.0:
			paid_dividend_found = true
			break
	if not paid_dividend_found:
		return "Smoke test expected cash dividends to move from declared to paid state with a positive paid amount."
	if float(GameManager.get_portfolio_snapshot().get("cash", 0.0)) <= cash_before_dividend_payment:
		return "Smoke test expected paid cash dividends to credit player cash even after the record-date holder sells."
	var dividend_trade_found: bool = false
	for trade_value in GameManager.get_trade_history():
		if typeof(trade_value) == TYPE_DICTIONARY and str(trade_value.get("side", "")).to_lower() == "dividend":
			dividend_trade_found = true
			break
	if not dividend_trade_found:
		return "Smoke test expected paid dividends to appear in portfolio history."

	if int(RunState.get_holding(dividend_company_id).get("shares", 0)) < GameManager.get_lot_size():
		var stock_dividend_buy_result: Dictionary = GameManager.buy_lots(dividend_company_id, 1)
		if not bool(stock_dividend_buy_result.get("success", false)):
			return "Smoke test expected buying one lot again for stock dividend coverage to succeed."
	var stock_dividend_shares_before: int = int(RunState.get_holding(dividend_company_id).get("shares", 0))
	var stock_dividend_definition_before: Dictionary = RunState.get_effective_company_definition(dividend_company_id, false, false)
	var stock_dividend_financials_before: Dictionary = stock_dividend_definition_before.get("financials", {})
	var stock_dividend_company_shares_before: float = float(stock_dividend_financials_before.get("shares_outstanding", stock_dividend_definition_before.get("shares_outstanding", 0.0)))
	var stock_dividend_schedule_result: Dictionary = GameManager.debug_schedule_next_day_stock_dividend(dividend_company_id)
	var scheduled_stock_dividend: Dictionary = stock_dividend_schedule_result.get("dividend", {})
	var stock_dividend_ratio: float = float(scheduled_stock_dividend.get("stock_dividend_ratio", 0.0))
	if (
		not bool(stock_dividend_schedule_result.get("success", false)) or
		scheduled_stock_dividend.is_empty() or
		stock_dividend_ratio <= 0.0
	):
		return "Smoke test expected debug stock dividend scheduling to create a stock dividend action with a positive ratio."
	var stock_dividend_id: String = str(scheduled_stock_dividend.get("id", ""))
	var stock_dividend_expected_bonus: int = int(floor(float(stock_dividend_shares_before) * stock_dividend_ratio))
	if stock_dividend_expected_bonus <= 0:
		return "Smoke test expected the held dividend stock to qualify for a positive stock dividend share distribution."
	var stock_dividend_snapshot: Dictionary = GameManager.get_corporate_dividend_snapshot(dividend_company_id)
	var stock_dividend_upcoming_found: bool = false
	for stock_upcoming_value in stock_dividend_snapshot.get("upcoming_rows", []):
		if typeof(stock_upcoming_value) == TYPE_DICTIONARY and str(stock_upcoming_value.get("id", "")) == stock_dividend_id:
			stock_dividend_upcoming_found = true
			break
	if not stock_dividend_upcoming_found:
		return "Smoke test expected scheduled stock dividends to appear in the corporate dividend snapshot."

	for _stock_dividend_day_index in range(4):
		GameManager.advance_day()
		await get_tree().process_frame
	stock_dividend_snapshot = GameManager.get_corporate_dividend_snapshot(dividend_company_id)
	var paid_stock_dividend_found: bool = false
	for stock_paid_value in stock_dividend_snapshot.get("paid_rows", []):
		if typeof(stock_paid_value) != TYPE_DICTIONARY:
			continue
		var stock_paid_row: Dictionary = stock_paid_value
		if (
			str(stock_paid_row.get("id", "")) == stock_dividend_id and
			int(stock_paid_row.get("distributed_bonus_shares", 0)) >= stock_dividend_expected_bonus
		):
			paid_stock_dividend_found = true
			break
	if not paid_stock_dividend_found:
		return "Smoke test expected stock dividends to move from declared to paid state with bonus shares."
	if int(RunState.get_holding(dividend_company_id).get("shares", 0)) < stock_dividend_shares_before + stock_dividend_expected_bonus:
		return "Smoke test expected paid stock dividends to increase the player share count."
	var stock_dividend_company_shares_after: float = float(RunState.get_effective_company_definition(dividend_company_id, false, false).get("financials", {}).get("shares_outstanding", 0.0))
	if stock_dividend_company_shares_after <= stock_dividend_company_shares_before:
		return "Smoke test expected stock dividends to increase company shares outstanding."
	var stock_dividend_distribution_found: bool = false
	for stock_distribution_value in RunState.last_day_results.get("stock_dividend_distributions", []):
		if typeof(stock_distribution_value) == TYPE_DICTIONARY and str(stock_distribution_value.get("dividend_id", "")) == stock_dividend_id:
			stock_dividend_distribution_found = true
			break
	if not stock_dividend_distribution_found:
		return "Smoke test expected stock dividend payment day results to include the share distribution payload."
	var stock_dividend_trade_found: bool = false
	for stock_trade_value in GameManager.get_trade_history():
		if typeof(stock_trade_value) == TYPE_DICTIONARY and str(stock_trade_value.get("side", "")).to_lower() == "stock_dividend":
			stock_dividend_trade_found = true
			break
	if not stock_dividend_trade_found:
		return "Smoke test expected paid stock dividends to appear in portfolio history."

	game_root.close_desktop_app("life")
	await get_tree().process_frame
	if not desktop_layer.visible or game_root.is_desktop_app_open("life"):
		return "Smoke test expected closing the Life desktop window to hide the app while keeping the desktop visible."

	RunState.load_from_dict(baseline_state)
	SaveManager.save_run(RunState.to_save_dict())
	SaveManager.flush_pending_save()
	game_root._refresh_all()
	await get_tree().process_frame
	return ""


func _validate_thesis_board_smoke(game_root: Node, thesis_app_button: Button, desktop_layer: Control) -> String:
	if thesis_app_button == null:
		return "Smoke test expected the Thesis Board desktop icon to exist."
	if RunState.company_order.is_empty():
		return "Smoke test expected Thesis Board coverage to have at least one generated company."

	var baseline_state: Dictionary = RunState.to_save_dict()
	var legacy_state: Dictionary = baseline_state.duplicate(true)
	legacy_state.erase("player_theses")
	RunState.load_from_dict(legacy_state)
	if not RunState.get_player_theses().is_empty():
		return "Smoke test expected old saves without player_theses to load with an empty Thesis Board state."

	RunState.load_from_dict(baseline_state)
	game_root._refresh_all()
	await get_tree().process_frame

	var thesis_company_id: String = str(RunState.company_order[0])
	game_root._on_all_stock_selected(thesis_company_id)
	await get_tree().process_frame

	thesis_app_button.emit_signal("pressed")
	await get_tree().process_frame
	await _wait_for_ui_animation_settle()

	var thesis_window: Control = game_root.find_child("ThesisWindow", true, false) as Control
	var thesis_list: ItemList = game_root.find_child("ThesisList", true, false) as ItemList
	var thesis_company_option: OptionButton = game_root.find_child("ThesisCompanyOption", true, false) as OptionButton
	var thesis_evidence_category_option: OptionButton = game_root.find_child("ThesisEvidenceCategoryOption", true, false) as OptionButton
	var thesis_evidence_option: OptionButton = game_root.find_child("ThesisEvidenceOption", true, false) as OptionButton
	var thesis_evidence_list: ItemList = game_root.find_child("ThesisEvidenceList", true, false) as ItemList
	var thesis_evidence_discipline_label: Label = game_root.find_child("ThesisEvidenceDisciplineLabel", true, false) as Label
	var thesis_generate_report_button: Button = game_root.find_child("ThesisGenerateReportButton", true, false) as Button
	var thesis_view_paper_button: Button = game_root.find_child("ThesisViewPaperButton", true, false) as Button
	var thesis_report_panel: Control = game_root.find_child("ThesisReportPanel", true, false) as Control
	var thesis_report_overlay: Control = game_root.find_child("ThesisReportOverlay", true, false) as Control
	var thesis_report_preparing_panel: Control = game_root.find_child("ThesisReportPreparingPanel", true, false) as Control
	var thesis_report_preparing_label: Label = game_root.find_child("ThesisReportPreparingLabel", true, false) as Label
	var thesis_white_paper_panel: Control = game_root.find_child("ThesisWhitePaperPanel", true, false) as Control
	var thesis_white_paper_recommendation_label: Label = game_root.find_child("ThesisWhitePaperRecommendationLabel", true, false) as Label
	var thesis_white_paper_implied_label: Label = game_root.find_child("ThesisWhitePaperImpliedLabel", true, false) as Label
	var thesis_white_paper_sections: VBoxContainer = game_root.find_child("ThesisWhitePaperSections", true, false) as VBoxContainer
	var thesis_report_text: RichTextLabel = game_root.find_child("ThesisReportText", true, false) as RichTextLabel
	var thesis_report_close_button: Button = game_root.find_child("ThesisReportCloseButton", true, false) as Button
	var thesis_report_regenerate_button: Button = game_root.find_child("ThesisReportRegenerateButton", true, false) as Button
	var thesis_step_flow_row: HBoxContainer = game_root.find_child("ThesisStepFlowRow", true, false) as HBoxContainer
	var thesis_stance_bullish_button: Button = game_root.find_child("ThesisStanceBullishButton", true, false) as Button
	var thesis_stance_bearish_button: Button = game_root.find_child("ThesisStanceBearishButton", true, false) as Button
	var thesis_stance_income_button: Button = game_root.find_child("ThesisStanceIncomeButton", true, false) as Button
	var thesis_stance_watch_button: Button = game_root.find_child("ThesisStanceWatchButton", true, false) as Button
	var thesis_evidence_tab_fundamental_button: Button = game_root.find_child("ThesisEvidenceTabFundamentalButton", true, false) as Button
	var thesis_evidence_tab_technical_button: Button = game_root.find_child("ThesisEvidenceTabTechnicalButton", true, false) as Button
	var thesis_evidence_tab_news_button: Button = game_root.find_child("ThesisEvidenceTabNewsButton", true, false) as Button
	var thesis_evidence_tab_social_button: Button = game_root.find_child("ThesisEvidenceTabSocialButton", true, false) as Button
	var thesis_evidence_card_grid: HFlowContainer = game_root.find_child("ThesisEvidenceCardGrid", true, false) as HFlowContainer
	var thesis_evidence_chip_flow: HFlowContainer = game_root.find_child("ThesisEvidenceChipFlow", true, false) as HFlowContainer
	var thesis_sidebar_pip_row: HBoxContainer = game_root.find_child("ThesisSidebarPipRow", true, false) as HBoxContainer
	var thesis_sidebar_title_label: Label = game_root.find_child("ThesisSidebarTitleLabel", true, false) as Label
	var thesis_sidebar_meta_label: Label = game_root.find_child("ThesisSidebarMetaLabel", true, false) as Label
	var thesis_sidebar_evidence_label: Label = game_root.find_child("ThesisSidebarEvidenceLabel", true, false) as Label
	var thesis_sidebar_next_gap_label: Label = game_root.find_child("ThesisSidebarNextGapLabel", true, false) as Label
	if (
		thesis_window == null or
		not thesis_window.visible or
		not game_root.is_desktop_app_open("thesis") or
		game_root.get_active_desktop_app_id() != "thesis" or
		game_root.get_desktop_app_window_title("thesis") != "Thesis Board" or
		not _desktop_window_animation_settled(game_root, "ThesisBoardDesktopWindow") or
		not _desktop_window_has_settings_brown_chrome(game_root, "ThesisBoardDesktopWindow") or
		thesis_list == null or
		thesis_company_option == null or
		thesis_evidence_category_option == null or
		thesis_evidence_option == null or
		thesis_evidence_list == null or
		thesis_evidence_discipline_label == null or
		thesis_generate_report_button == null or
		thesis_view_paper_button == null or
		thesis_report_panel != null or
		thesis_report_overlay == null or
		thesis_report_overlay.visible or
		thesis_report_preparing_panel == null or
		thesis_report_preparing_label == null or
		thesis_white_paper_panel == null or
		thesis_white_paper_recommendation_label == null or
		thesis_white_paper_implied_label == null or
		thesis_white_paper_sections == null or
		thesis_white_paper_panel.visible or
		thesis_report_text == null or
		thesis_report_close_button == null or
		thesis_report_regenerate_button == null or
		thesis_step_flow_row == null or
		thesis_stance_bullish_button == null or
		thesis_stance_bearish_button == null or
		thesis_stance_income_button == null or
		thesis_stance_watch_button == null or
		thesis_evidence_tab_fundamental_button == null or
		thesis_evidence_tab_technical_button == null or
		thesis_evidence_tab_news_button == null or
		thesis_evidence_tab_social_button == null or
		thesis_evidence_card_grid == null or
		thesis_evidence_chip_flow == null or
		thesis_sidebar_pip_row == null or
		thesis_sidebar_title_label == null or
		thesis_sidebar_meta_label == null or
		thesis_sidebar_evidence_label == null or
		thesis_sidebar_next_gap_label == null
	):
		return "Smoke test expected the Thesis Board icon to open a settled brown-framed redesigned workflow with a hidden report overlay."

	var step_flow_text: String = _collect_node_text(thesis_step_flow_row)
	if thesis_step_flow_row.get_child_count() != 3 or step_flow_text.find("Build") == -1 or step_flow_text.find("Add Evidence") == -1 or step_flow_text.find("Review") == -1:
		return "Smoke test expected the Thesis Board redesign to render the three numbered Build, Add Evidence, and Review steps."
	var bullish_style: StyleBoxFlat = thesis_stance_bullish_button.get_theme_stylebox("normal") as StyleBoxFlat
	var bearish_style: StyleBoxFlat = thesis_stance_bearish_button.get_theme_stylebox("normal") as StyleBoxFlat
	if (
		not thesis_stance_bullish_button.button_pressed or
		bullish_style == null or
		bullish_style.bg_color.g <= bullish_style.bg_color.r or
		bearish_style == null or
		not _color_close(thesis_stance_bearish_button.get_theme_color("font_color"), Color(0.65098, 0.247059, 0.219608, 1), 0.03)
	):
		return "Smoke test expected Thesis stance selection to use color-coded segmented buttons."

	if thesis_company_option.item_count <= 0:
		return "Smoke test expected the Thesis Board company picker to render generated stocks."

	game_root._set_active_app("desktop")
	await get_tree().process_frame
	thesis_app_button.emit_signal("pressed")
	await get_tree().process_frame
	await _wait_for_ui_animation_settle()
	if game_root.get_active_desktop_app_id() != "thesis" or not _desktop_window_animation_settled(game_root, "ThesisBoardDesktopWindow"):
		return "Smoke test expected pressing an already-open Thesis Board icon to focus the app and settle its animation state."

	var pattern_fixture_validation: String = _validate_chart_pattern_fixture_states()
	if not pattern_fixture_validation.is_empty():
		return pattern_fixture_validation

	game_root._set_active_app("stock")
	await get_tree().process_frame
	await _wait_for_ui_animation_settle()
	var pattern_tool_button: Button = game_root.find_child("PatternToolButton", true, false) as Button
	var pattern_panel: Control = game_root.find_child("ChartPatternClaimPanel", true, false) as Control
	var pattern_option: OptionButton = game_root.find_child("ChartPatternOption", true, false) as OptionButton
	var pattern_feedback_label: Label = game_root.find_child("ChartPatternFeedbackLabel", true, false) as Label
	var pattern_thesis_option: OptionButton = game_root.find_child("ChartPatternThesisOption", true, false) as OptionButton
	var pattern_add_button: Button = game_root.find_child("ChartPatternAddToThesisButton", true, false) as Button
	var chart_canvas: PriceChartCanvas = game_root.find_child("ChartCanvas", true, false) as PriceChartCanvas
	if (
		pattern_tool_button == null or
		pattern_panel == null or
		pattern_option == null or
		pattern_feedback_label == null or
		pattern_thesis_option == null or
		pattern_add_button == null or
		chart_canvas == null
	):
		return "Smoke test expected STOCKBOT chart Pattern controls to exist beside the existing drawing tools."
	pattern_tool_button.emit_signal("pressed")
	await get_tree().process_frame
	if chart_canvas.get_drawing_tool() != "pattern_claim" or not pattern_panel.visible:
		return "Smoke test expected the Pattern chart tool to activate without breaking the drawing toolbar."
	chart_canvas.debug_select_pattern_region_by_offsets(0, 6)
	await get_tree().process_frame
	if pattern_feedback_label.text.is_empty() or pattern_feedback_label.text == "No pattern region marked yet.":
		return "Smoke test expected selecting two pattern anchors to produce coaching feedback."
	if not pattern_add_button.disabled:
		return "Smoke test expected Add to Thesis to stay disabled until an open thesis exists for the selected stock."

	var create_result: Dictionary = GameManager.create_thesis(thesis_company_id, "bullish", "swing", "Smoke Thesis")
	if not bool(create_result.get("success", false)):
		return "Smoke test expected GameManager.create_thesis to create a thesis for a generated stock."
	if not SaveManager.has_pending_save():
		return "Smoke test expected creating a thesis to queue an autosave."
	var thesis_id: String = str(create_result.get("thesis", {}).get("id", ""))
	if thesis_id.is_empty():
		return "Smoke test expected created theses to receive a stable id."
	await get_tree().process_frame
	if pattern_add_button.disabled:
		return "Smoke test expected Add to Thesis to enable after creating an open thesis for the selected stock."
	pattern_add_button.emit_signal("pressed")
	await get_tree().process_frame
	if not _thesis_has_pattern_evidence(thesis_id):
		return "Smoke test expected chart pattern claims to save as Price Action thesis evidence."

	var second_thesis_result: Dictionary = GameManager.create_thesis(thesis_company_id, "bullish", "position", "Smoke Thesis Alt")
	var second_thesis_id: String = str(second_thesis_result.get("thesis", {}).get("id", ""))
	if not bool(second_thesis_result.get("success", false)) or second_thesis_id.is_empty():
		return "Smoke test expected a second open thesis for chart-pattern destination picker coverage."
	await get_tree().process_frame
	if pattern_thesis_option.item_count < 2 or pattern_thesis_option.disabled:
		return "Smoke test expected multiple open theses to show an enabled chart-pattern destination picker."
	for picker_index in range(pattern_thesis_option.item_count):
		if str(pattern_thesis_option.get_item_metadata(picker_index)) == second_thesis_id:
			pattern_thesis_option.select(picker_index)
			break
	pattern_add_button.emit_signal("pressed")
	await get_tree().process_frame
	if not _thesis_has_pattern_evidence(second_thesis_id):
		return "Smoke test expected chart pattern evidence to add to the selected destination thesis."

	game_root._set_active_app("thesis")
	await get_tree().process_frame
	await _wait_for_ui_animation_settle()
	if thesis_evidence_category_option.item_count <= 0 or thesis_evidence_option.item_count <= 0:
		return "Smoke test expected the Thesis Board evidence picker to render categories and options after creating a thesis."
	if (
		thesis_sidebar_title_label.text.find("Smoke Thesis") == -1 or
		thesis_sidebar_meta_label.text.find("Bullish") == -1 or
		thesis_sidebar_evidence_label.text.find("Evidence") == -1 or
		thesis_sidebar_pip_row.get_child_count() != 5 or
		thesis_sidebar_next_gap_label.text.strip_edges().is_empty()
	):
		return "Smoke test expected the Thesis Board sidebar to summarize active thesis stance, timeframe, pips, and next evidence gap."
	var thesis_tab_buttons: Array = [
		thesis_evidence_tab_fundamental_button,
		thesis_evidence_tab_technical_button,
		thesis_evidence_tab_news_button,
		thesis_evidence_tab_social_button
	]
	for tab_button_value in thesis_tab_buttons:
		var tab_button: Button = tab_button_value
		tab_button.emit_signal("pressed")
		await get_tree().process_frame
		if thesis_evidence_card_grid.get_child_count() <= 0:
			return "Smoke test expected every Thesis evidence tab to render browsable card content."
		var tab_card_text: String = _collect_node_text(thesis_evidence_card_grid).to_lower()
		if tab_card_text.strip_edges().is_empty() or (tab_card_text.find("positive") == -1 and tab_card_text.find("negative") == -1 and tab_card_text.find("mixed") == -1):
			return "Smoke test expected Thesis evidence cards to show label, value, detail, and impact badge text."
	thesis_evidence_tab_technical_button.emit_signal("pressed")
	await get_tree().process_frame
	if _collect_node_text(thesis_evidence_chip_flow).find("Price Action") == -1:
		return "Smoke test expected chart-pattern evidence added from STOCKBOT to appear as a selected Technical chip."
	thesis_evidence_tab_fundamental_button.emit_signal("pressed")
	await get_tree().process_frame
	var first_fundamental_card: Button = null
	for card_value in thesis_evidence_card_grid.get_children():
		if card_value is Button:
			first_fundamental_card = card_value
			break
	if first_fundamental_card == null:
		return "Smoke test expected the Thesis Fundamental tab to expose clickable evidence cards."
	var thesis_card_count_before: int = RunState.get_player_thesis(thesis_id).get("evidence", []).size()
	first_fundamental_card.emit_signal("pressed")
	await get_tree().process_frame
	var thesis_rows_after_card_add: Array = RunState.get_player_thesis(thesis_id).get("evidence", [])
	if thesis_rows_after_card_add.size() <= thesis_card_count_before or thesis_evidence_chip_flow.get_child_count() <= 0:
		return "Smoke test expected clicking a Thesis evidence card to add it and update board chips immediately."
	var added_card_label: String = ""
	for evidence_value in thesis_rows_after_card_add:
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var evidence_row: Dictionary = evidence_value
		if str(evidence_row.get("source_label", "")) != "STOCKBOT Chart":
			added_card_label = str(evidence_row.get("label", ""))
			break
	var chip_remove_button: Button = null
	for chip_value in thesis_evidence_chip_flow.get_children():
		if chip_value is Button and str((chip_value as Button).text).find(added_card_label) != -1:
			chip_remove_button = chip_value
			break
	if chip_remove_button == null:
		return "Smoke test expected added Thesis evidence to render as a removable board chip."
	chip_remove_button.emit_signal("pressed")
	await get_tree().process_frame
	if RunState.get_player_thesis(thesis_id).get("evidence", []).size() >= thesis_rows_after_card_add.size():
		return "Smoke test expected clicking a Thesis board chip to remove that evidence."
	if thesis_evidence_discipline_label.text.find("Evidence discipline") == -1 or thesis_evidence_discipline_label.text.find("Price ready") == -1:
		return "Smoke test expected the Thesis Board evidence discipline strip to summarize selected evidence pillars."
	if game_root.find_child("ThesisFocusGapButton", true, false) != null:
		return "Smoke test expected the Thesis Board evidence discipline strip to stay passive without a Focus Gap shortcut."

	var evidence_snapshot: Dictionary = GameManager.get_thesis_evidence_options(thesis_company_id)
	var required_evidence_categories := ["fundamentals", "price_action", "broker_flow", "sector_macro", "news", "risk_invalidation"]
	var sector_macro_labels: Array = _thesis_evidence_option_labels(evidence_snapshot, "sector_macro")
	for macro_label_value in ["Inflation backdrop", "GDP growth", "Employment backdrop", "Policy rate", "Risk appetite", "Sector macro bias", "Active macro shock"]:
		if not sector_macro_labels.has(str(macro_label_value)):
			return "Smoke test expected Thesis Board sector/macro evidence to include %s." % str(macro_label_value)
	if sector_macro_labels.has("Macro regime"):
		return "Smoke test expected Thesis Board sector/macro evidence to use concrete macro rows instead of Macro regime."
	var added_evidence: Array = []
	for category_id_value in required_evidence_categories:
		var category_id: String = str(category_id_value)
		var evidence_option: Dictionary = _find_thesis_evidence_option(evidence_snapshot, category_id)
		if evidence_option.is_empty():
			return "Smoke test expected Thesis Board evidence options to include populated %s evidence." % category_id
		var add_result: Dictionary = GameManager.add_thesis_evidence(thesis_id, evidence_option)
		if not bool(add_result.get("success", false)):
			return "Smoke test expected adding Thesis Board %s evidence to succeed." % category_id
		added_evidence.append(evidence_option)

	var thesis_after_adds: Dictionary = RunState.get_player_thesis(thesis_id)
	var thesis_evidence_rows: Array = thesis_after_adds.get("evidence", [])
	if thesis_evidence_rows.size() < required_evidence_categories.size():
		return "Smoke test expected added Thesis Board evidence to stay on the selected thesis."
	var removed_evidence_id: String = ""
	for evidence_value in thesis_evidence_rows:
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var evidence_row: Dictionary = evidence_value
		if str(evidence_row.get("pattern_label", "")).is_empty():
			removed_evidence_id = str(evidence_row.get("id", ""))
			break
	if removed_evidence_id.is_empty():
		return "Smoke test expected a non-pattern Thesis evidence row for remove/re-add coverage."
	var remove_result: Dictionary = GameManager.remove_thesis_evidence(thesis_id, removed_evidence_id)
	if not bool(remove_result.get("success", false)):
		return "Smoke test expected removing Thesis Board evidence to succeed."
	var readd_result: Dictionary = GameManager.add_thesis_evidence(thesis_id, added_evidence[0])
	if not bool(readd_result.get("success", false)):
		return "Smoke test expected re-adding Thesis Board evidence after removal to succeed."

	await get_tree().process_frame
	if thesis_evidence_list.item_count < required_evidence_categories.size():
		return "Smoke test expected the Thesis Board selected evidence list to update after add/remove operations."
	if thesis_evidence_chip_flow.get_child_count() < required_evidence_categories.size() or _collect_node_text(thesis_evidence_chip_flow).find("Risk") == -1:
		return "Smoke test expected the Thesis Board evidence chips to update after direct add/remove operations."

	var saved_thesis_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(saved_thesis_state)
	if RunState.get_player_thesis(thesis_id).is_empty():
		return "Smoke test expected created theses to persist through a RunState save/load round trip."
	if not SaveManager.flush_pending_save():
		return "Smoke test expected Thesis Board autosave flush to succeed."
	var persisted_thesis_state: Dictionary = SaveManager.load_run()
	if not persisted_thesis_state.get("player_theses", {}).has(thesis_id):
		return "Smoke test expected flushed Thesis Board saves to persist player_theses to disk."

	if not thesis_view_paper_button.disabled:
		return "Smoke test expected Thesis Board View Paper to stay disabled before report generation."
	var thesis_report_action_cost: int = GameManager.get_thesis_report_action_cost()
	RunState.daily_actions_used = max(RunState.get_daily_action_limit() - thesis_report_action_cost + 1, 0)
	if thesis_window.has_method("refresh"):
		thesis_window.call("refresh")
	await get_tree().process_frame
	var no_ap_report_result: Dictionary = GameManager.generate_thesis_report(thesis_id)
	if bool(no_ap_report_result.get("success", false)) or not thesis_generate_report_button.disabled:
		return "Smoke test expected Thesis report generation to require 7 AP and stay disabled when AP is short."
	RunState.daily_actions_used = 0
	if thesis_window.has_method("refresh"):
		thesis_window.call("refresh")
	await get_tree().process_frame
	var thesis_ap_before_report: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	thesis_generate_report_button.emit_signal("pressed")
	await get_tree().process_frame
	if (
		not thesis_report_overlay.visible or
		not thesis_report_preparing_panel.visible or
		thesis_white_paper_panel.visible or
		thesis_report_preparing_label.text.find("Reviewing selected evidence") == -1
	):
		return "Smoke test expected clicking Generate Report to show the staged preparing overlay immediately."
	if not thesis_generate_report_button.disabled or not thesis_view_paper_button.disabled:
		return "Smoke test expected Thesis report actions to be disabled while the paper is being prepared."
	await get_tree().create_timer(1.25).timeout
	await get_tree().process_frame
	if (
		not thesis_report_overlay.visible or
		thesis_report_preparing_panel.visible or
		not thesis_white_paper_panel.visible
	):
		return "Smoke test expected the Thesis report overlay to reveal the white paper after the staged preparation."
	var thesis_after_report: Dictionary = RunState.get_player_thesis(thesis_id)
	var report: Dictionary = thesis_after_report.get("report", {})
	var thesis_ap_after_report: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	if thesis_ap_after_report < thesis_ap_before_report + thesis_report_action_cost:
		return "Smoke test expected generating a Thesis report to spend 7 AP."
	if (
		str(report.get("rating", "")).is_empty() or
		str(report.get("reasoning_grade", "")).is_empty() or
		report.get("discipline_rows", []).size() < 5 or
		report.get("target", {}).is_empty() or
		report.get("sections", []).size() < 6
	):
		return "Smoke test expected generated Thesis reports to include verdict, grade, discipline rows, target area, and analyst-style sections."
	var rating_alignment_validation: String = _validate_thesis_report_rating_alignment()
	if not rating_alignment_validation.is_empty():
		return rating_alignment_validation
	if (
		thesis_white_paper_recommendation_label.text != str(report.get("rating", "")) or
		thesis_white_paper_implied_label.text.strip_edges().is_empty() or
		thesis_white_paper_sections.get_child_count() <= 0
	):
		return "Smoke test expected the redesigned Thesis white paper to show summary recommendation, implied move, and structured thesis sections."
	var required_report_sections := [
		"Investment Thesis",
		"Valuation & Recommendation",
		"Investment Risks",
		"Catalysts / Checks",
		"Tape / Broker Flow",
		"Learning Note"
	]
	for section_title in required_report_sections:
		if not _thesis_report_has_section(report, str(section_title)):
			return "Smoke test expected generated Thesis reports to include the %s section." % str(section_title)
	var investment_thesis_section: Dictionary = _thesis_report_section(report, "Investment Thesis")
	var investment_thesis_bullets: Array = investment_thesis_section.get("bullets", [])
	var first_investment_bullet: Dictionary = investment_thesis_bullets[0] if not investment_thesis_bullets.is_empty() and typeof(investment_thesis_bullets[0]) == TYPE_DICTIONARY else {}
	if first_investment_bullet.is_empty() or str(first_investment_bullet.get("claim", "")).is_empty() or str(first_investment_bullet.get("body", "")).is_empty():
		return "Smoke test expected generated Thesis reports to use claim-led analyst bullets."

	await get_tree().process_frame
	var visible_report_text: String = thesis_report_text.text.to_lower()
	for forbidden_term_value in ["source_chain_id", "chain_family", "hidden_flag", "current_timeline_state", "formal_agenda_or_filing", "meeting_or_call"]:
		var forbidden_term: String = str(forbidden_term_value)
		if visible_report_text.find(forbidden_term) != -1:
			return "Smoke test expected Thesis report copy to avoid raw system/debug wording like %s." % forbidden_term
	if visible_report_text.find("recommendation") == -1 or visible_report_text.find("thesis quality grade") == -1 or visible_report_text.find("target area") == -1:
		return "Smoke test expected the Thesis white paper to show recommendation, thesis quality grade, and target area."
	if visible_report_text.find("player marked") == -1 or visible_report_text.find("coaching feedback") == -1:
		return "Smoke test expected the Thesis white paper to include player-led chart pattern evidence."
	if visible_report_text.find("evidence discipline") == -1 or visible_report_text.find("next check") == -1:
		return "Smoke test expected the Thesis white paper to include evidence discipline and chart-pattern next-check language."
	var raw_internal_score_regex := RegEx.new()
	raw_internal_score_regex.compile("\\b(quality|growth|risk)\\s+[0-9]")
	if raw_internal_score_regex.search(visible_report_text) != null:
		return "Smoke test expected Thesis report copy to translate quality/growth/risk scores into player-facing bands."

	thesis_report_close_button.emit_signal("pressed")
	await get_tree().process_frame
	if thesis_report_overlay.visible:
		return "Smoke test expected closing the Thesis white paper overlay to return to the board."
	if thesis_evidence_list.item_count < required_evidence_categories.size():
		return "Smoke test expected closing the Thesis white paper to preserve selected evidence state."

	var frozen_report_price: float = float(report.get("report_price", 0.0))
	var frozen_generated_day: int = int(report.get("generated_day_index", 0))
	thesis_view_paper_button.emit_signal("pressed")
	await get_tree().process_frame
	var reopened_report: Dictionary = RunState.get_player_thesis(thesis_id).get("report", {})
	if (
		not thesis_report_overlay.visible or
		not thesis_white_paper_panel.visible or
		not is_equal_approx(float(reopened_report.get("report_price", 0.0)), frozen_report_price) or
		int(reopened_report.get("generated_day_index", -1)) != frozen_generated_day
	):
		return "Smoke test expected View Paper to reopen the existing frozen Thesis report without regenerating it."

	RunState.daily_actions_used = 0
	if thesis_window.has_method("refresh"):
		thesis_window.call("refresh")
	await get_tree().process_frame
	thesis_report_regenerate_button.emit_signal("pressed")
	await get_tree().process_frame
	if (
		not thesis_report_overlay.visible or
		not thesis_report_preparing_panel.visible or
		thesis_white_paper_panel.visible or
		thesis_report_preparing_label.text.find("Reviewing selected evidence") == -1
	):
		return "Smoke test expected Regenerate to reuse the staged white-paper generation flow."
	await get_tree().create_timer(1.25).timeout
	await get_tree().process_frame
	if (
		not thesis_report_overlay.visible or
		thesis_report_preparing_panel.visible or
		not thesis_white_paper_panel.visible
	):
		return "Smoke test expected Regenerate to reveal the refreshed Thesis white paper."
	report = RunState.get_player_thesis(thesis_id).get("report", {})
	frozen_report_price = float(report.get("report_price", 0.0))
	frozen_generated_day = int(report.get("generated_day_index", 0))

	GameManager.advance_day()
	await get_tree().process_frame
	var report_after_day: Dictionary = RunState.get_player_thesis(thesis_id).get("report", {})
	if (
		not is_equal_approx(float(report_after_day.get("report_price", 0.0)), frozen_report_price) or
		int(report_after_day.get("generated_day_index", -1)) != frozen_generated_day
	):
		return "Smoke test expected generated Thesis reports to remain frozen after Advance Day until regenerated."

	var review_result: Dictionary = GameManager.refresh_thesis_review(thesis_id)
	if not bool(review_result.get("success", false)):
		return "Smoke test expected Thesis review refresh to succeed after Advance Day."
	var review: Dictionary = review_result.get("review", {})
	if str(review.get("state", "")).is_empty() or int(review.get("updated_day_index", -1)) != RunState.day_index:
		return "Smoke test expected Thesis review to update its state after Advance Day."

	game_root.close_desktop_app("thesis")
	await get_tree().process_frame
	if not desktop_layer.visible or game_root.is_desktop_app_open("thesis"):
		return "Smoke test expected closing the Thesis Board desktop window to hide the app while keeping the desktop visible."

	RunState.load_from_dict(baseline_state)
	SaveManager.save_run(RunState.to_save_dict())
	SaveManager.flush_pending_save()
	game_root._refresh_all()
	await get_tree().process_frame
	return ""


func _validate_chart_pattern_fixture_states() -> String:
	var evaluator = load("res://systems/ChartPatternSystem.gd").new()
	var fixtures: Array = [
		{
			"pattern_id": "breakout",
			"expected": "Good read",
			"bars": _chart_pattern_fixture_bars([
				{"open": 100.0, "high": 101.0, "low": 98.0, "close": 99.0, "volume": 1000},
				{"open": 99.0, "high": 102.0, "low": 98.0, "close": 100.0, "volume": 980},
				{"open": 100.0, "high": 101.5, "low": 99.0, "close": 100.5, "volume": 1010},
				{"open": 100.5, "high": 101.0, "low": 99.5, "close": 100.0, "volume": 2200},
				{"open": 100.0, "high": 103.5, "low": 100.0, "close": 102.8, "volume": 2400},
				{"open": 102.8, "high": 106.0, "low": 102.0, "close": 105.0, "volume": 2600}
			]),
			"start": 3,
			"end": 5
		},
		{
			"pattern_id": "breakout",
			"expected": "Plausible, needs confirmation",
			"bars": _chart_pattern_fixture_bars([
				{"open": 100.0, "high": 101.0, "low": 98.0, "close": 99.0, "volume": 2500},
				{"open": 99.0, "high": 102.0, "low": 98.0, "close": 100.0, "volume": 2500},
				{"open": 100.0, "high": 101.5, "low": 99.0, "close": 100.5, "volume": 2500},
				{"open": 100.5, "high": 101.0, "low": 99.5, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 103.5, "low": 100.0, "close": 102.8, "volume": 1050},
				{"open": 102.8, "high": 106.0, "low": 102.0, "close": 105.0, "volume": 1100}
			]),
			"start": 3,
			"end": 5
		},
		{
			"pattern_id": "range",
			"expected": "Weak read",
			"bars": _chart_pattern_fixture_bars([
				{"open": 100.0, "high": 120.0, "low": 92.0, "close": 106.0, "volume": 1000},
				{"open": 106.0, "high": 116.0, "low": 90.0, "close": 104.0, "volume": 1000},
				{"open": 104.0, "high": 118.0, "low": 94.0, "close": 107.0, "volume": 1000},
				{"open": 107.0, "high": 117.0, "low": 93.0, "close": 105.0, "volume": 1000}
			]),
			"start": 0,
			"end": 3
		},
		{
			"pattern_id": "breakout",
			"expected": "Contradicted",
			"bars": _chart_pattern_fixture_bars([
				{"open": 100.0, "high": 101.0, "low": 98.0, "close": 99.0, "volume": 1000},
				{"open": 99.0, "high": 102.0, "low": 98.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.5, "low": 99.0, "close": 100.5, "volume": 1000},
				{"open": 100.5, "high": 104.0, "low": 100.0, "close": 103.0, "volume": 1400},
				{"open": 103.0, "high": 103.5, "low": 98.0, "close": 99.0, "volume": 1700},
				{"open": 99.0, "high": 100.0, "low": 97.0, "close": 98.5, "volume": 1600}
			]),
			"start": 3,
			"end": 5
		},
		{
			"pattern_id": "double_bottom",
			"expected": "Good read",
			"bars": _chart_pattern_fixture_bars([
				{"open": 100.0, "high": 101.0, "low": 96.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 96.0, "low": 88.0, "close": 90.0, "volume": 1200},
				{"open": 90.0, "high": 104.0, "low": 90.0, "close": 103.0, "volume": 1500},
				{"open": 103.0, "high": 102.0, "low": 92.0, "close": 96.0, "volume": 900},
				{"open": 96.0, "high": 96.0, "low": 89.0, "close": 91.0, "volume": 1100},
				{"open": 91.0, "high": 105.0, "low": 91.0, "close": 104.0, "volume": 1800},
				{"open": 104.0, "high": 108.0, "low": 103.0, "close": 106.0, "volume": 1900},
				{"open": 106.0, "high": 110.0, "low": 106.0, "close": 108.0, "volume": 2100}
			]),
			"start": 0,
			"end": 7
		},
		{
			"pattern_id": "double_top",
			"expected": "Good read",
			"bars": _chart_pattern_fixture_bars([
				{"open": 100.0, "high": 103.0, "low": 98.0, "close": 101.0, "volume": 1000},
				{"open": 101.0, "high": 113.0, "low": 100.0, "close": 112.0, "volume": 1400},
				{"open": 112.0, "high": 112.0, "low": 96.0, "close": 98.0, "volume": 1500},
				{"open": 98.0, "high": 108.0, "low": 97.0, "close": 106.0, "volume": 1000},
				{"open": 106.0, "high": 112.0, "low": 105.0, "close": 111.0, "volume": 1300},
				{"open": 111.0, "high": 111.0, "low": 97.0, "close": 98.0, "volume": 1800},
				{"open": 98.0, "high": 99.0, "low": 94.0, "close": 95.0, "volume": 2000},
				{"open": 95.0, "high": 96.0, "low": 93.0, "close": 94.0, "volume": 2200}
			]),
			"start": 0,
			"end": 7
		},
		{
			"pattern_id": "cup_handle",
			"expected": "Good read",
			"bars": _chart_pattern_fixture_bars([
				{"open": 110.0, "high": 112.0, "low": 108.0, "close": 110.0, "volume": 1600},
				{"open": 110.0, "high": 111.0, "low": 100.0, "close": 102.0, "volume": 1200},
				{"open": 102.0, "high": 103.0, "low": 92.0, "close": 94.0, "volume": 950},
				{"open": 94.0, "high": 96.0, "low": 84.0, "close": 86.0, "volume": 850},
				{"open": 86.0, "high": 93.0, "low": 85.0, "close": 90.0, "volume": 800},
				{"open": 90.0, "high": 100.0, "low": 89.0, "close": 98.0, "volume": 1000},
				{"open": 98.0, "high": 108.0, "low": 97.0, "close": 106.0, "volume": 1250},
				{"open": 106.0, "high": 112.0, "low": 105.0, "close": 111.0, "volume": 1500},
				{"open": 111.0, "high": 111.0, "low": 101.0, "close": 104.0, "volume": 900},
				{"open": 104.0, "high": 114.0, "low": 103.0, "close": 112.0, "volume": 1900}
			]),
			"start": 0,
			"end": 9
		},
		{
			"pattern_id": "head_shoulders",
			"expected": "Good read",
			"bars": _chart_pattern_fixture_bars([
				{"open": 100.0, "high": 101.0, "low": 98.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 112.0, "low": 99.0, "close": 110.0, "volume": 1300},
				{"open": 110.0, "high": 111.0, "low": 96.0, "close": 98.0, "volume": 1200},
				{"open": 98.0, "high": 106.0, "low": 97.0, "close": 104.0, "volume": 1000},
				{"open": 104.0, "high": 105.0, "low": 96.0, "close": 99.0, "volume": 1100},
				{"open": 99.0, "high": 126.0, "low": 98.0, "close": 124.0, "volume": 1700},
				{"open": 98.0, "high": 100.0, "low": 96.0, "close": 98.0, "volume": 1600},
				{"open": 98.0, "high": 112.0, "low": 97.0, "close": 110.0, "volume": 1200},
				{"open": 110.0, "high": 113.0, "low": 98.0, "close": 111.0, "volume": 1200},
				{"open": 111.0, "high": 112.0, "low": 93.0, "close": 94.0, "volume": 1900},
				{"open": 94.0, "high": 95.0, "low": 91.0, "close": 92.0, "volume": 2200},
				{"open": 92.0, "high": 93.0, "low": 90.0, "close": 91.0, "volume": 2300}
			]),
			"start": 0,
			"end": 11
		},
		{
			"pattern_id": "inverse_head_shoulders",
			"expected": "Good read",
			"bars": _chart_pattern_fixture_bars([
				{"open": 100.0, "high": 102.0, "low": 98.0, "close": 100.0, "volume": 1200},
				{"open": 100.0, "high": 101.0, "low": 90.0, "close": 92.0, "volume": 1300},
				{"open": 92.0, "high": 103.0, "low": 91.0, "close": 103.0, "volume": 1100},
				{"open": 103.0, "high": 104.0, "low": 94.0, "close": 96.0, "volume": 1000},
				{"open": 96.0, "high": 101.0, "low": 95.0, "close": 98.0, "volume": 1000},
				{"open": 98.0, "high": 99.0, "low": 78.0, "close": 82.0, "volume": 1600},
				{"open": 103.0, "high": 104.0, "low": 100.0, "close": 103.0, "volume": 1500},
				{"open": 103.0, "high": 104.0, "low": 91.0, "close": 92.0, "volume": 1000},
				{"open": 92.0, "high": 105.0, "low": 91.0, "close": 104.0, "volume": 1500},
				{"open": 104.0, "high": 107.0, "low": 103.0, "close": 106.0, "volume": 1700},
				{"open": 106.0, "high": 109.0, "low": 105.0, "close": 108.0, "volume": 1900},
				{"open": 108.0, "high": 110.0, "low": 107.0, "close": 109.0, "volume": 2000}
			]),
			"start": 0,
			"end": 11
		},
		{
			"pattern_id": "ascending_triangle",
			"expected": "Good read",
			"bars": _chart_pattern_fixture_bars([
				{"open": 100.0, "high": 111.0, "low": 95.0, "close": 108.0, "volume": 1000},
				{"open": 108.0, "high": 110.0, "low": 97.0, "close": 102.0, "volume": 900},
				{"open": 102.0, "high": 112.0, "low": 100.0, "close": 109.0, "volume": 1100},
				{"open": 109.0, "high": 111.0, "low": 103.0, "close": 105.0, "volume": 1000},
				{"open": 105.0, "high": 112.0, "low": 106.0, "close": 110.0, "volume": 1300},
				{"open": 110.0, "high": 113.0, "low": 107.0, "close": 109.0, "volume": 1200}
			]),
			"start": 0,
			"end": 5
		},
		{
			"pattern_id": "descending_triangle",
			"expected": "Good read",
			"bars": _chart_pattern_fixture_bars([
				{"open": 110.0, "high": 112.0, "low": 94.0, "close": 97.0, "volume": 1000},
				{"open": 97.0, "high": 110.0, "low": 93.0, "close": 106.0, "volume": 900},
				{"open": 106.0, "high": 108.0, "low": 94.0, "close": 96.0, "volume": 1100},
				{"open": 96.0, "high": 105.0, "low": 93.0, "close": 101.0, "volume": 1000},
				{"open": 101.0, "high": 103.0, "low": 94.0, "close": 95.0, "volume": 1300},
				{"open": 95.0, "high": 101.0, "low": 92.0, "close": 98.0, "volume": 1400},
				{"open": 98.0, "high": 99.0, "low": 91.0, "close": 94.0, "volume": 1700}
			]),
			"start": 0,
			"end": 6
		},
		{
			"pattern_id": "bull_flag",
			"expected": "Good read",
			"bars": _chart_pattern_fixture_bars([
				{"open": 100.0, "high": 102.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 106.0, "low": 100.0, "close": 105.0, "volume": 1400},
				{"open": 105.0, "high": 111.0, "low": 104.0, "close": 110.0, "volume": 1800},
				{"open": 110.0, "high": 116.0, "low": 109.0, "close": 114.0, "volume": 2100},
				{"open": 114.0, "high": 115.0, "low": 110.0, "close": 111.0, "volume": 1100},
				{"open": 111.0, "high": 112.0, "low": 108.0, "close": 109.0, "volume": 950},
				{"open": 109.0, "high": 111.0, "low": 106.0, "close": 108.0, "volume": 900},
				{"open": 108.0, "high": 113.0, "low": 107.0, "close": 110.0, "volume": 1000},
				{"open": 110.0, "high": 115.0, "low": 109.0, "close": 112.0, "volume": 1500}
			]),
			"start": 4,
			"end": 8
		},
		{
			"pattern_id": "sma_support_bounce",
			"expected": "Good read",
			"bars": _chart_pattern_fixture_bars([
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 98.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 97.0, "close": 99.0, "volume": 1100},
				{"open": 99.0, "high": 103.0, "low": 98.0, "close": 102.0, "volume": 1400},
				{"open": 102.0, "high": 104.0, "low": 101.0, "close": 103.0, "volume": 1500},
				{"open": 103.0, "high": 104.0, "low": 102.0, "close": 103.0, "volume": 1400},
				{"open": 103.0, "high": 105.0, "low": 102.0, "close": 104.0, "volume": 1500},
				{"open": 104.0, "high": 106.0, "low": 103.0, "close": 105.0, "volume": 1600},
				{"open": 105.0, "high": 106.0, "low": 103.0, "close": 104.0, "volume": 1300},
				{"open": 104.0, "high": 106.0, "low": 103.0, "close": 104.0, "volume": 1300}
			]),
			"start": 12,
			"end": 21
		},
		{
			"pattern_id": "sma_resistance_rejection",
			"expected": "Good read",
			"bars": _chart_pattern_fixture_bars([
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 101.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 102.0, "low": 99.0, "close": 100.0, "volume": 1000},
				{"open": 100.0, "high": 103.0, "low": 99.0, "close": 101.0, "volume": 1100},
				{"open": 101.0, "high": 104.0, "low": 99.0, "close": 100.0, "volume": 1200},
				{"open": 100.0, "high": 103.0, "low": 96.0, "close": 98.0, "volume": 1500},
				{"open": 98.0, "high": 99.0, "low": 95.0, "close": 97.0, "volume": 1600},
				{"open": 97.0, "high": 98.0, "low": 95.0, "close": 97.0, "volume": 1300},
				{"open": 97.0, "high": 99.0, "low": 95.0, "close": 98.0, "volume": 1200},
				{"open": 98.0, "high": 99.0, "low": 96.0, "close": 98.0, "volume": 1100},
				{"open": 98.0, "high": 99.0, "low": 96.0, "close": 97.0, "volume": 1200},
				{"open": 97.0, "high": 98.0, "low": 95.0, "close": 97.0, "volume": 1200}
			]),
			"start": 12,
			"end": 21
		}
	]

	for fixture_value in fixtures:
		var fixture: Dictionary = fixture_value
		var bars: Array = fixture.get("bars", [])
		var result: Dictionary = evaluator.evaluate_pattern_claim({
			"company_id": "fixture",
			"ticker": "FIX",
			"range_id": "fixture",
			"range_label": "Fixture",
			"pattern_id": str(fixture.get("pattern_id", "")),
			"start_anchor": _chart_pattern_anchor_for_bar(bars, int(fixture.get("start", 0))),
			"end_anchor": _chart_pattern_anchor_for_bar(bars, int(fixture.get("end", 0))),
			"bars": bars,
			"current_price": float(bars[bars.size() - 1].get("close", 0.0)),
			"trade_date": bars[bars.size() - 1].get("trade_date", {})
		})
		if not bool(result.get("success", false)):
			return "Smoke test expected chart pattern fixture %s to evaluate successfully." % str(fixture.get("pattern_id", ""))
		if str(result.get("feedback_state", "")) != str(fixture.get("expected", "")):
			return "Smoke test expected chart pattern fixture %s to reach %s, got %s." % [
				str(fixture.get("pattern_id", "")),
				str(fixture.get("expected", "")),
				str(result.get("feedback_state", ""))
			]
	return ""


func _chart_pattern_fixture_bars(rows: Array) -> Array:
	var bars: Array = []
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		var close_value: float = float(row.get("close", row.get("open", 0.0)))
		bars.append({
			"trade_date": {
				"year": 2020,
				"month": 1,
				"day": index + 1,
				"weekday": index % 5
			},
			"open": float(row.get("open", close_value)),
			"high": float(row.get("high", close_value)),
			"low": float(row.get("low", close_value)),
			"close": close_value,
			"volume_shares": int(row.get("volume", 1000)),
			"value": close_value * float(row.get("volume", 1000))
		})
	return bars


func _chart_pattern_anchor_for_bar(bars: Array, index: int) -> Dictionary:
	if bars.is_empty():
		return {}
	var safe_index: int = clamp(index, 0, bars.size() - 1)
	var bar: Dictionary = bars[safe_index]
	var trade_date: Dictionary = bar.get("trade_date", {})
	return {
		"bar_key": "%04d-%02d-%02d" % [
			int(trade_date.get("year", 0)),
			int(trade_date.get("month", 0)),
			int(trade_date.get("day", 0))
		],
		"date_serial": int(trade_date.get("year", 0)) * 10000 + int(trade_date.get("month", 0)) * 100 + int(trade_date.get("day", 0)),
		"price": float(bar.get("close", 0.0))
	}


func _thesis_has_pattern_evidence(thesis_id: String) -> bool:
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	for evidence_value in thesis.get("evidence", []):
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = evidence_value
		if str(row.get("category", "")) == "price_action" and not str(row.get("pattern_label", "")).is_empty():
			return true
	return false


func _find_thesis_evidence_option(evidence_snapshot: Dictionary, category_id: String) -> Dictionary:
	for category_value in evidence_snapshot.get("categories", []):
		if typeof(category_value) != TYPE_DICTIONARY:
			continue
		var category: Dictionary = category_value
		if str(category.get("id", "")) != category_id:
			continue
		for option_value in category.get("options", []):
			if typeof(option_value) == TYPE_DICTIONARY:
				return option_value
	return {}


func _thesis_evidence_option_labels(evidence_snapshot: Dictionary, category_id: String) -> Array:
	var labels: Array = []
	for category_value in evidence_snapshot.get("categories", []):
		if typeof(category_value) != TYPE_DICTIONARY:
			continue
		var category: Dictionary = category_value
		if str(category.get("id", "")) != category_id:
			continue
		for option_value in category.get("options", []):
			if typeof(option_value) == TYPE_DICTIONARY:
				labels.append(str(option_value.get("label", "")))
		break
	return labels


func _thesis_report_has_section(report: Dictionary, section_title: String) -> bool:
	return not _thesis_report_section(report, section_title).is_empty()


func _thesis_report_section(report: Dictionary, section_title: String) -> Dictionary:
	for section_value in report.get("sections", []):
		if typeof(section_value) == TYPE_DICTIONARY and str(section_value.get("title", "")) == section_title:
			return section_value
	return {}


func _validate_thesis_report_rating_alignment() -> String:
	var report_system = load("res://systems/ThesisReportSystem.gd").new()
	var thesis := {
		"id": "rating_alignment_fixture",
		"company_id": "fixture",
		"stance": "bullish",
		"horizon": "swing",
		"evidence": [
			{"category": "fundamentals", "category_label": "Fundamentals", "label": "Business quality", "value": "Weak", "detail": "Quality is weak.", "impact": "mixed"},
			{"category": "financials", "category_label": "Financials", "label": "Revenue growth YoY", "value": "-8.0%", "detail": "Revenue is fading.", "impact": "mixed"},
			{"category": "valuation", "category_label": "Valuation", "label": "Current PE", "value": "24.0x", "detail": "Valuation is not cheap.", "impact": "mixed"},
			{"category": "price_action", "category_label": "Price Action", "label": "Five-bar trend", "value": "-6.0%", "detail": "Price confirms weakness.", "impact": "mixed"},
			{"category": "broker_flow", "category_label": "Broker Flow", "label": "Broker flow", "value": "Neutral", "detail": "Flow is not supportive.", "impact": "mixed"},
			{"category": "sector_macro", "category_label": "Sector / Macro", "label": "Sector macro bias", "value": "Weak", "detail": "Sector backdrop is soft.", "impact": "mixed"},
			{"category": "risk_invalidation", "category_label": "Risk / Invalidation", "label": "Price invalidation", "value": "Breaks below report price", "detail": "Risk is explicit.", "impact": "mixed"}
		]
	}
	var context := {
		"day_index": 0,
		"trade_date": {"year": 2020, "month": 1, "day": 3},
		"company": {
			"id": "fixture",
			"ticker": "FIX",
			"name": "Fixture Downtrend",
			"sector_name": "Industrial",
			"current_price": 1000.0,
			"quality_score": 35,
			"growth_score": 35,
			"risk_score": 70,
			"daily_change_pct": -0.02,
			"lots_owned": 8,
			"broker_flow": {"flow_tag": "neutral"}
		}
	}
	var report: Dictionary = report_system.build_report(thesis, context)
	if float(report.get("implied_upside_pct", 0.0)) > -0.05:
		return "Smoke test expected the Thesis rating alignment fixture to produce a meaningfully negative implied move."
	var rating: String = str(report.get("rating", ""))
	if rating in ["Hold/Watch", "Hold", "Buy", "Accumulate"]:
		return "Smoke test expected negative-upside bullish Thesis reports to avoid hold/buy-style recommendations."
	return ""


func _count_down_days(price_history: Array) -> int:
	var down_days: int = 0
	for index in range(1, price_history.size()):
		if float(price_history[index]) < float(price_history[index - 1]):
			down_days += 1
	return down_days


func _wait_for_ui_animation_settle() -> void:
	await get_tree().create_timer(0.24).timeout
	await get_tree().process_frame


func _control_animation_settled(control: Control) -> bool:
	if control == null:
		return false
	return control.scale.is_equal_approx(Vector2.ONE) and is_equal_approx(control.modulate.a, 1.0)


func _color_close(actual: Color, expected: Color, tolerance: float = 0.01) -> bool:
	return (
		absf(actual.r - expected.r) <= tolerance and
		absf(actual.g - expected.g) <= tolerance and
		absf(actual.b - expected.b) <= tolerance and
		absf(actual.a - expected.a) <= tolerance
	)


func _desktop_window_animation_settled(game_root: Node, window_name: String) -> bool:
	var window: Control = game_root.find_child(window_name, true, false) as Control
	return _control_animation_settled(window)


func _desktop_window_has_settings_brown_chrome(game_root: Node, window_name: String) -> bool:
	var window: Control = game_root.find_child(window_name, true, false) as Control
	if window == null:
		return false
	var frame: PanelContainer = window.get_node_or_null("Frame") as PanelContainer
	var title_bar: PanelContainer = window.get_node_or_null("TitleBar") as PanelContainer
	var content_host: Control = window.get_node_or_null("ContentHost") as Control
	if frame == null or title_bar == null or content_host == null:
		return false
	var brown := Color(0.509804, 0.231373, 0.0941176, 1)
	var cream := Color(1.0, 0.976471, 0.929412, 1)
	var frame_style: StyleBoxFlat = frame.get_theme_stylebox("panel") as StyleBoxFlat
	var title_style: StyleBoxFlat = title_bar.get_theme_stylebox("panel") as StyleBoxFlat
	var title_label: Label = title_bar.find_child("TitleLabel", true, false) as Label
	return (
		frame_style != null and
		title_style != null and
		title_label != null and
		_color_close(frame_style.border_color, brown) and
		frame_style.border_width_left == 2 and
		frame_style.border_width_top == 2 and
		frame_style.border_width_right == 2 and
		frame_style.border_width_bottom == 2 and
		_color_close(title_style.bg_color, brown) and
		title_style.border_width_left == 0 and
		title_style.border_width_top == 0 and
		title_style.border_width_right == 0 and
		title_style.border_width_bottom == 0 and
		_color_close(title_label.get_theme_color("font_color"), cream) and
		is_equal_approx(content_host.offset_left, 2.0) and
		is_equal_approx(content_host.offset_right, -2.0) and
		is_equal_approx(content_host.offset_bottom, -2.0)
	)


func _validate_design_system_assets() -> String:
	var ui_theme: Node = get_node_or_null("/root/UiTheme")
	if ui_theme == null:
		return "Smoke test expected UiTheme to be registered as a global autoload."
	var required_methods := [
		"color",
		"font",
		"font_size",
		"set_ui_scale",
		"get_ui_scale",
		"apply_tree_font",
		"make_stylebox",
		"style_label",
		"style_button",
		"style_tab_button",
		"style_panel",
		"style_progress_bar",
		"style_checkbox",
		"style_item_list",
		"style_option_button"
	]
	for method_name_value in required_methods:
		var method_name: String = str(method_name_value)
		if not ui_theme.has_method(method_name):
			return "Smoke test expected UiTheme to expose %s." % method_name

	if UiTheme.get_ui_scale() != "normal":
		return "Smoke test expected UiTheme default scale to be normal."
	for scale_id in ["compact", "normal", "large", "accessibility"]:
		if UiTheme.font_size("body", scale_id) <= 0:
			return "Smoke test expected UiTheme body size to resolve for %s scale." % scale_id
	if UiTheme.font_size("caption", "normal") != 12 or UiTheme.font_size("body", "normal") != 14 or UiTheme.font_size("metric", "normal") != 20:
		return "Smoke test expected UiTheme normal typography sizes to match the design system."
	if UiTheme.font("regular") == null or UiTheme.font("semibold") == null or UiTheme.font("bold") == null:
		return "Smoke test expected UiTheme to load Open Sans regular, semibold, and bold fonts."
	if not _color_close(UiTheme.color("desktop.brown"), Color(0.509804, 0.231373, 0.0941176, 1)):
		return "Smoke test expected UiTheme desktop.brown to match the official desktop token."
	if not _color_close(UiTheme.color("terminal.accent"), Color(0.560784, 0.772549, 1, 1)):
		return "Smoke test expected UiTheme terminal.accent to match the official terminal token."

	var primary_button := Button.new()
	UiTheme.style_button(primary_button, "desktop_primary")
	var primary_normal: StyleBoxFlat = primary_button.get_theme_stylebox("normal") as StyleBoxFlat
	if primary_normal == null or not _color_close(primary_normal.bg_color, UiTheme.color("desktop.gold")) or primary_normal.border_width_left != 2:
		return "Smoke test expected desktop_primary buttons to use gold fill and two-pixel desktop borders."
	if not _color_close(primary_button.get_theme_color("font_color"), UiTheme.color("desktop.text")):
		return "Smoke test expected desktop_primary buttons to use desktop text color."

	var danger_button := Button.new()
	UiTheme.style_button(danger_button, "desktop_danger")
	var danger_normal: StyleBoxFlat = danger_button.get_theme_stylebox("normal") as StyleBoxFlat
	if danger_normal == null or not _color_close(danger_button.get_theme_color("font_color"), UiTheme.color("desktop.cream")):
		return "Smoke test expected desktop_danger buttons to keep readable cream text."

	var shortcut_button := Button.new()
	UiTheme.style_button(shortcut_button, "desktop_shortcut")
	var shortcut_style: StyleBoxFlat = shortcut_button.get_theme_stylebox("normal") as StyleBoxFlat
	if shortcut_style == null or shortcut_style.border_width_left != 4 or not _color_close(shortcut_button.get_theme_color("icon_normal_color"), UiTheme.color("desktop.brown")):
		return "Smoke test expected desktop shortcut controls to keep the shared desktop tile treatment."
	var shortcut_disabled_style: StyleBoxFlat = shortcut_button.get_theme_stylebox("disabled") as StyleBoxFlat
	var shortcut_disabled_icon_color: Color = shortcut_button.get_theme_color("icon_disabled_color")
	if (
		shortcut_disabled_style == null or
		shortcut_disabled_style.bg_color.b > 0.76 or
		shortcut_disabled_style.bg_color.r < 0.82 or
		shortcut_disabled_icon_color.a > 0.6 or
		not _color_close(Color(shortcut_disabled_icon_color.r, shortcut_disabled_icon_color.g, shortcut_disabled_icon_color.b, 1), UiTheme.color("desktop.brown"))
	):
		return "Smoke test expected disabled desktop shortcuts to use muted warm desktop colors, not the dark terminal disabled fallback."

	var taskbar_button := Button.new()
	UiTheme.style_button(taskbar_button, "taskbar_launch")
	var taskbar_pressed_style: StyleBoxFlat = taskbar_button.get_theme_stylebox("pressed") as StyleBoxFlat
	if taskbar_pressed_style == null or not _color_close(taskbar_pressed_style.border_color, UiTheme.color("terminal.nav_active_border")):
		return "Smoke test expected taskbar launch controls to keep the active terminal border treatment."

	var desktop_tab_selected := Button.new()
	var desktop_tab_unselected := Button.new()
	UiTheme.style_tab_button(desktop_tab_selected, "desktop_tab", true)
	UiTheme.style_tab_button(desktop_tab_unselected, "desktop_tab", false)
	var selected_tab_style: StyleBoxFlat = desktop_tab_selected.get_theme_stylebox("normal") as StyleBoxFlat
	var unselected_tab_style: StyleBoxFlat = desktop_tab_unselected.get_theme_stylebox("normal") as StyleBoxFlat
	if selected_tab_style == null or unselected_tab_style == null or _color_close(selected_tab_style.bg_color, unselected_tab_style.bg_color):
		return "Smoke test expected desktop_tab selected and unselected styles to be visually distinct."

	var terminal_tab_selected := Button.new()
	var terminal_tab_unselected := Button.new()
	UiTheme.style_tab_button(terminal_tab_selected, "terminal_tab", true)
	UiTheme.style_tab_button(terminal_tab_unselected, "terminal_tab", false)
	var terminal_selected_style: StyleBoxFlat = terminal_tab_selected.get_theme_stylebox("normal") as StyleBoxFlat
	var terminal_unselected_style: StyleBoxFlat = terminal_tab_unselected.get_theme_stylebox("normal") as StyleBoxFlat
	if terminal_selected_style == null or terminal_unselected_style == null or _color_close(terminal_selected_style.bg_color, terminal_unselected_style.bg_color):
		return "Smoke test expected terminal_tab selected and unselected styles to be visually distinct."

	var desktop_window := PanelContainer.new()
	UiTheme.style_panel(desktop_window, "desktop_window")
	var desktop_window_style: StyleBoxFlat = desktop_window.get_theme_stylebox("panel") as StyleBoxFlat
	if desktop_window_style == null or desktop_window_style.border_width_top != 26 or not _color_close(desktop_window_style.border_color, UiTheme.color("desktop.brown")):
		return "Smoke test expected desktop_window panels to keep the brown title-border treatment."

	var progress_bar := ProgressBar.new()
	UiTheme.style_progress_bar(progress_bar, "desktop")
	var progress_background: StyleBoxFlat = progress_bar.get_theme_stylebox("background") as StyleBoxFlat
	var progress_fill: StyleBoxFlat = progress_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if progress_background == null or progress_fill == null or not _color_close(progress_fill.bg_color, UiTheme.color("desktop.olive")):
		return "Smoke test expected desktop progress bars to use UiTheme progress styles."

	var checkbox := CheckBox.new()
	UiTheme.style_checkbox(checkbox, "desktop")
	if not _color_close(checkbox.get_theme_color("font_color"), UiTheme.color("desktop.text")):
		return "Smoke test expected desktop checkboxes to use readable desktop text."

	var item_list := ItemList.new()
	UiTheme.style_item_list(item_list, "desktop")
	var item_selected_style: StyleBoxFlat = item_list.get_theme_stylebox("selected") as StyleBoxFlat
	if item_selected_style == null or not _color_close(item_list.get_theme_color("font_selected_color"), UiTheme.color("desktop.text")):
		return "Smoke test expected desktop item lists to expose selected styles and readable text."

	var option_button := OptionButton.new()
	UiTheme.style_option_button(option_button, "desktop")
	var option_normal: StyleBoxFlat = option_button.get_theme_stylebox("normal") as StyleBoxFlat
	if option_normal == null or not _color_close(option_button.get_theme_color("font_color"), UiTheme.color("desktop.text")):
		return "Smoke test expected desktop option buttons to use UiTheme styling."

	var design_doc_text: String = _read_text_file("res://docs/DESIGN_SYSTEM.md")
	var readme_text: String = _read_text_file("res://README.md")
	if design_doc_text.is_empty() or design_doc_text.find("desktop_tab") == -1 or design_doc_text.find("viewport-width font scaling") == -1:
		return "Smoke test expected docs/DESIGN_SYSTEM.md to document tabs and UI scale rules."
	if readme_text.find("docs/DESIGN_SYSTEM.md") == -1 or readme_text.find("UiTheme") == -1:
		return "Smoke test expected README.md to link the design system docs and mention UiTheme."

	return ""


func _validate_release_readiness_assets() -> String:
	if BuildInfo.get_product_name() != "Buy High Sell Low Stock Trading Simulator":
		return "Smoke test expected the player-facing product name to be Buy High Sell Low Stock Trading Simulator."
	if str(ProjectSettings.get_setting("application/config/name", "")) != "Buy High Sell Low Stock Trading Simulator":
		return "Smoke test expected project.godot application name to use the Buy High Sell Low Stock Trading Simulator name."

	var build_number: String = BuildInfo.get_build_number()
	if build_number.is_empty() or BuildInfo.get_short_display_string().find(build_number) == -1:
		return "Smoke test expected BuildInfo to expose a non-empty build number and display string."

	var steam_manager: Node = get_node_or_null("/root/SteamManager")
	if steam_manager == null:
		return "Smoke test expected SteamManager to be registered as a global autoload."
	if not steam_manager.has_method("get_runtime_info") or not steam_manager.has_method("refresh_runtime_info"):
		return "Smoke test expected SteamManager to expose Steam runtime info helpers."
	var steam_runtime_info: Variant = steam_manager.call("get_runtime_info")
	if typeof(steam_runtime_info) != TYPE_DICTIONARY:
		return "Smoke test expected SteamManager runtime info to be a dictionary."
	var steam_info: Dictionary = steam_runtime_info
	var required_steam_keys: Array = [
		"available",
		"initialized",
		"init_result",
		"app_id",
		"app_installed_depots",
		"app_languages",
		"app_owner",
		"steam_app_build_id",
		"game_language",
		"install_dir",
		"is_on_steam_deck",
		"is_on_vr",
		"is_online",
		"is_owned",
		"launch_command_line",
		"steam_id",
		"steam_username",
		"ui_language",
		"godotsteam_version",
		"status_summary"
	]
	for key_value in required_steam_keys:
		var steam_key: String = str(key_value)
		if not steam_info.has(steam_key):
			return "Smoke test expected SteamManager runtime info to include %s." % steam_key
	var expected_steam_app_id: int = int(ProjectSettings.get_setting("steam/initialization/app_id", 480))
	if int(steam_info.get("app_id", 0)) != expected_steam_app_id:
		return "Smoke test expected SteamManager to read the configured Steam app id."

	var known_issues_text: String = _read_text_file("res://docs/KNOWN_ISSUES.md")
	if (
		known_issues_text.is_empty() or
		known_issues_text.find(build_number) == -1 or
		known_issues_text.find("KI-001") == -1 or
		known_issues_text.find("Reporting Priority") == -1
	):
		return "Smoke test expected docs/KNOWN_ISSUES.md to include the current build number, issue ids, and reporting priorities."

	var bug_template_text: String = _read_text_file("res://docs/BUG_REPORT_TEMPLATE.md")
	if (
		bug_template_text.is_empty() or
		bug_template_text.find(build_number) == -1 or
		bug_template_text.find("Steps To Reproduce") == -1 or
		bug_template_text.find("Expected Result") == -1 or
		bug_template_text.find("Actual Result") == -1
	):
		return "Smoke test expected docs/BUG_REPORT_TEMPLATE.md to include build, reproduction, expected-result, and actual-result fields."

	var achievement_doc_text: String = _read_text_file("res://docs/STEAM_ACHIEVEMENT_IDS.md")
	if (
		achievement_doc_text.is_empty() or
		achievement_doc_text.find("ACH_FIRST_TRADE") == -1 or
		achievement_doc_text.find("STAT_TRADES_PLACED") == -1 or
		achievement_doc_text.find("Steamworks") == -1
	):
		return "Smoke test expected docs/STEAM_ACHIEVEMENT_IDS.md to include Steam achievement and stat API prep."

	var cloud_doc_text: String = _read_text_file("res://docs/STEAM_CLOUD_SAVE_PATHS.md")
	if (
		cloud_doc_text.is_empty() or
		cloud_doc_text.find("user://saves/slot_1.json") == -1 or
		cloud_doc_text.find("daytrader_save_config.json") == -1 or
		cloud_doc_text.find("WinAppDataRoaming") == -1
	):
		return "Smoke test expected docs/STEAM_CLOUD_SAVE_PATHS.md to document Steam Auto-Cloud save paths."

	var achievement_catalog_text: String = _read_text_file("res://data/steam/achievement_catalog.json")
	if achievement_catalog_text.is_empty():
		return "Smoke test expected data/steam/achievement_catalog.json to exist."
	var achievement_json := JSON.new()
	var achievement_parse_error: int = achievement_json.parse(achievement_catalog_text)
	if achievement_parse_error != OK:
		return "Smoke test expected data/steam/achievement_catalog.json to parse as JSON."
	if typeof(achievement_json.data) != TYPE_DICTIONARY:
		return "Smoke test expected Steam achievement catalog root to be a dictionary."
	var achievement_catalog: Dictionary = achievement_json.data
	var achievement_rows: Array = achievement_catalog.get("achievements", [])
	var stat_rows: Array = achievement_catalog.get("stats", [])
	if achievement_rows.size() < 10 or stat_rows.size() < 5:
		return "Smoke test expected Steam achievement catalog to include a useful Early Access achievement/stat set."
	var seen_achievement_api_names := {}
	var has_first_trade: bool = false
	for achievement_value in achievement_rows:
		if typeof(achievement_value) != TYPE_DICTIONARY:
			return "Smoke test expected every Steam achievement catalog row to be a dictionary."
		var achievement: Dictionary = achievement_value
		var api_name: String = str(achievement.get("api_name", "")).strip_edges()
		if not api_name.begins_with("ACH_"):
			return "Smoke test expected Steam achievement API names to begin with ACH_, found %s." % api_name
		if seen_achievement_api_names.has(api_name):
			return "Smoke test expected Steam achievement API names to be unique, found duplicate %s." % api_name
		seen_achievement_api_names[api_name] = true
		if api_name == "ACH_FIRST_TRADE":
			has_first_trade = true
			if str(achievement.get("progress_stat", "")) != "STAT_TRADES_PLACED":
				return "Smoke test expected ACH_FIRST_TRADE to use STAT_TRADES_PLACED."
	if not has_first_trade:
		return "Smoke test expected Steam achievement catalog to include ACH_FIRST_TRADE."
	var seen_stat_api_names := {}
	for stat_value in stat_rows:
		if typeof(stat_value) != TYPE_DICTIONARY:
			return "Smoke test expected every Steam stat catalog row to be a dictionary."
		var stat: Dictionary = stat_value
		var stat_api_name: String = str(stat.get("api_name", "")).strip_edges()
		if not stat_api_name.begins_with("STAT_"):
			return "Smoke test expected Steam stat API names to begin with STAT_, found %s." % stat_api_name
		if seen_stat_api_names.has(stat_api_name):
			return "Smoke test expected Steam stat API names to be unique, found duplicate %s." % stat_api_name
		seen_stat_api_names[stat_api_name] = true
	return ""


func _read_text_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file = null
	return text


func _validate_contact_network_data() -> String:
	var network_data: Dictionary = DataRepository.get_contact_network_data()
	var meeting_profile_ids := {}
	var meeting_profiles: Array = network_data.get("meeting_lead_profiles", [])
	if meeting_profiles.size() < 4:
		return "Smoke test expected meeting_lead_profiles to include at least four reusable RUPSLB lead profiles."
	for profile_value in meeting_profiles:
		if typeof(profile_value) != TYPE_DICTIONARY:
			return "Smoke test expected every meeting lead profile to be a dictionary."
		var profile: Dictionary = profile_value
		var profile_id: String = str(profile.get("id", "")).strip_edges()
		if profile_id.is_empty():
			return "Smoke test expected every meeting lead profile to have an id."
		if meeting_profile_ids.has(profile_id):
			return "Smoke test expected meeting lead profile ids to be unique, but found duplicate %s." % profile_id
		meeting_profile_ids[profile_id] = true
		if str(profile.get("tier", "")).strip_edges().is_empty():
			return "Smoke test expected meeting lead profile %s to define a tier." % profile_id
		if str(profile.get("role_label", "")).strip_edges().is_empty():
			return "Smoke test expected meeting lead profile %s to define a role_label." % profile_id
		if profile.get("category_ids", []).is_empty():
			return "Smoke test expected meeting lead profile %s to define category filters." % profile_id
		if profile.get("speech_bubbles", []).is_empty():
			return "Smoke test expected meeting lead profile %s to define speech bubbles." % profile_id
		var stage_speech_bubbles = profile.get("stage_speech_bubbles", {})
		if typeof(stage_speech_bubbles) != TYPE_DICTIONARY:
			return "Smoke test expected meeting lead profile %s to define stage speech bubbles." % profile_id
		for stage_id in ["seating", "host_intro", "agenda_reveal", "vote"]:
			if not stage_speech_bubbles.has(stage_id) or stage_speech_bubbles.get(stage_id, []).is_empty():
				return "Smoke test expected meeting lead profile %s to define %s stage speech bubbles." % [profile_id, stage_id]
		if str(profile.get("approach_prompt", "")).strip_edges().is_empty():
			return "Smoke test expected meeting lead profile %s to define an approach prompt." % profile_id
		if profile.get("success_responses", []).is_empty():
			return "Smoke test expected meeting lead profile %s to define success responses." % profile_id
		if str(profile.get("locked_copy", "")).strip_edges().is_empty():
			return "Smoke test expected meeting lead profile %s to define locked copy." % profile_id
	var seen_ids := {}
	var insider_template_roles := {}
	for contact_value in network_data.get("contacts", []):
		var contact: Dictionary = contact_value
		var contact_id: String = str(contact.get("id", "")).strip_edges()
		if contact_id.is_empty():
			return "Smoke test expected every Network contact to have an id."
		if seen_ids.has(contact_id):
			return "Smoke test expected Network contact ids to be unique, but found duplicate %s." % contact_id
		seen_ids[contact_id] = true
		var affiliation_type: String = str(contact.get("affiliation_type", "")).strip_edges()
		if affiliation_type.is_empty():
			return "Smoke test expected %s to define affiliation_type." % contact_id
		if not (affiliation_type in ["floater", "insider_template"]):
			return "Smoke test found unsupported affiliation_type %s on %s." % [affiliation_type, contact_id]
		if affiliation_type == "insider_template":
			var affiliation_role: String = str(contact.get("affiliation_role", "")).strip_edges()
			if not (affiliation_role in ["ceo", "cfo", "commissioner"]):
				return "Smoke test expected insider template %s to use ceo/cfo/commissioner affiliation_role." % contact_id
			insider_template_roles[affiliation_role] = true
		elif contact.has("affiliation_role"):
			return "Smoke test expected floater %s not to define affiliation_role." % contact_id
	for required_role in ["ceo", "cfo", "commissioner"]:
		if not insider_template_roles.has(required_role):
			return "Smoke test expected at least one %s insider template." % required_role
	return ""


func _validate_trading_calendar_extension() -> String:
	var expected_holidays := {
		"2026-03-19": "Hari Raya Nyepi 2026",
		"2028-01-26": "Imlek 2028",
		"2029-12-03": "Isra Miraj 2029",
		"2030-04-19": "Good Friday 2030",
		"2030-12-25": "Christmas 2030"
	}
	for date_key_variant in expected_holidays.keys():
		var date_key: String = str(date_key_variant)
		var parts: PackedStringArray = date_key.split("-")
		var date_info := {
			"year": int(parts[0]),
			"month": int(parts[1]),
			"day": int(parts[2]),
			"weekday": 0
		}
		if not trading_calendar.is_holiday(date_info):
			return "Smoke test expected the trading calendar to mark %s (%s) as a market holiday." % [
				str(expected_holidays[date_key_variant]),
				date_key
			]

	return ""


func _count_company_framework_events(event_history: Array) -> int:
	var match_count: int = 0
	for event_entry_value in event_history:
		var event_entry: Dictionary = event_entry_value
		if COMPANY_FRAMEWORK_EVENT_IDS.has(str(event_entry.get("event_id", ""))):
			match_count += 1
	return match_count


func _count_company_arc_events(event_history: Array) -> int:
	var match_count: int = 0
	for event_entry_value in event_history:
		var event_entry: Dictionary = event_entry_value
		if str(event_entry.get("event_family", "")) == "company_arc":
			match_count += 1
	return match_count


func _count_special_events(event_history: Array) -> int:
	var match_count: int = 0
	for event_entry_value in event_history:
		var event_entry: Dictionary = event_entry_value
		if SPECIAL_EVENT_IDS.has(str(event_entry.get("event_id", ""))):
			match_count += 1
	return match_count


func _count_person_events(event_history: Array) -> int:
	var match_count: int = 0
	for event_entry_value in event_history:
		var event_entry: Dictionary = event_entry_value
		if str(event_entry.get("event_family", "")) == "person":
			match_count += 1
	return match_count


func _has_contact_arc(contact_id: String, company_id: String, source_action: String) -> bool:
	for arc_value in GameManager.get_active_company_arcs():
		var arc: Dictionary = arc_value
		if (
			str(arc.get("event_family", "")) == "contact" and
			str(arc.get("source_contact_id", "")) == contact_id and
			str(arc.get("target_company_id", "")) == company_id and
			str(arc.get("source_action", "")) == source_action
		):
			return true
	return false


func _has_network_request_status(network_snapshot: Dictionary, company_id: String, status: String) -> bool:
	for request_value in network_snapshot.get("requests", []):
		var request: Dictionary = request_value
		if str(request.get("target_company_id", "")) == company_id and str(request.get("status", "")) == status:
			return true
	return false


func _broker_rows_contain_code(rows: Array, broker_code: String) -> bool:
	for row_value in rows:
		var row: Dictionary = row_value
		if str(row.get("code", "")) == broker_code:
			return true
	return false


func _broker_non_player_side_value(broker_flow: Dictionary, side: String, player_broker_code: String) -> float:
	var total: float = 0.0
	var value_key: String = "buy_value" if side == "buy" else "sell_value"
	for row_value in broker_flow.get("broker_rows", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("code", "")) == player_broker_code:
			continue
		total += max(float(row.get(value_key, 0.0)), 0.0)
	return total


func _broker_tape_balance_delta(broker_flow: Dictionary) -> float:
	var buy_total: float = 0.0
	var sell_total: float = 0.0
	for row_value in broker_flow.get("broker_rows", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		buy_total += max(float(row.get("buy_value", 0.0)), 0.0)
		sell_total += max(float(row.get("sell_value", 0.0)), 0.0)
	return absf(buy_total - sell_total)


func _broker_table_rows_use_expanding_halves(header_row: HBoxContainer, rows_vbox: VBoxContainer) -> bool:
	if not _broker_table_line_uses_expanding_halves(header_row):
		return false
	for child in rows_vbox.get_children():
		if child is Label:
			continue
		var row_wrap: VBoxContainer = child as VBoxContainer
		if row_wrap == null or row_wrap.get_child_count() <= 0:
			continue
		var row: HBoxContainer = row_wrap.get_child(0) as HBoxContainer
		return row != null and _broker_table_line_uses_expanding_halves(row)
	return false


func _broker_table_line_uses_expanding_halves(row: HBoxContainer) -> bool:
	if row == null or row.get_child_count() != 9:
		return false
	if not (row.get_child(4) is VSeparator):
		return false
	for child_index in range(row.get_child_count()):
		if child_index == 4:
			continue
		var label: Label = row.get_child(child_index) as Label
		if label == null:
			return false
		if label.size_flags_horizontal != Control.SIZE_EXPAND_FILL or label.size_flags_stretch_ratio <= 0.0:
			return false
	return true


func _has_met_network_contact(network_snapshot: Dictionary, contact_id: String) -> bool:
	for contact_value in network_snapshot.get("contacts", []):
		var contact: Dictionary = contact_value
		if str(contact.get("id", "")) == contact_id and bool(contact.get("met", false)):
			return true
	return false


func _network_contact_affiliation_type(contact_id: String) -> String:
	for contact_value in DataRepository.get_contact_network_data().get("contacts", []):
		if typeof(contact_value) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = contact_value
		if str(contact.get("id", "")) == contact_id:
			return str(contact.get("affiliation_type", ""))
	return ""


func _has_approached_meeting_lead(session_snapshot: Dictionary, lead_id: String) -> bool:
	for lead_value in session_snapshot.get("meeting_leads", []):
		if typeof(lead_value) != TYPE_DICTIONARY:
			continue
		var lead: Dictionary = lead_value
		if str(lead.get("lead_id", "")) == lead_id:
			return bool(lead.get("approached", false)) and not str(lead.get("response_text", "")).is_empty()
	return false


func _contains_unresolved_template_token(text: String) -> bool:
	return text.find("{") >= 0 or text.find("}") >= 0


func _contains_malformed_social_template_text(text: String) -> bool:
	var lower_text: String = text.to_lower()
	return (
		_contains_unresolved_template_token(text) or
		lower_text.find("for ,") != -1 or
		lower_text.find("for .") != -1 or
		lower_text.find("for  ") != -1
	)


func _validate_network_tip_public_payload(tip_result: Dictionary, context_label: String) -> String:
	if str(tip_result.get("public_truth_label", "")).strip_edges().is_empty():
		return "Smoke test expected %s to expose a public truth label." % context_label
	if str(tip_result.get("public_confidence_label", "")).strip_edges().is_empty():
		return "Smoke test expected %s to expose a public confidence label." % context_label
	if str(tip_result.get("public_tip_read", "")).strip_edges().is_empty():
		return "Smoke test expected %s to expose a natural public tip read." % context_label
	var visible_text: String = "%s %s %s %s %s" % [
		str(tip_result.get("message", "")),
		str(tip_result.get("intel_summary", "")),
		str(tip_result.get("public_truth_label", "")),
		str(tip_result.get("public_confidence_label", "")),
		str(tip_result.get("public_tip_read", ""))
	]
	visible_text = visible_text.to_lower()
	var forbidden_terms: Array = [
		"source_chain_id",
		"chain_family",
		"meeting_id",
		"venue_type",
		"current_timeline_state",
		"management stance",
		"hidden_positioning",
		"formal_agenda_or_filing",
		"meeting_or_call",
		"created a tip arc",
		"created a tip"
	]
	for forbidden_term_value in forbidden_terms:
		var forbidden_term: String = str(forbidden_term_value)
		if visible_text.find(forbidden_term) != -1:
			return "Smoke test expected %s to avoid raw Network/system wording like %s." % [context_label, forbidden_term]
	return ""


func _tip_journal_has_pending_public_memory() -> bool:
	for tip_value in RunState.get_network_tip_journal().values():
		var tip: Dictionary = tip_value
		if (
			str(tip.get("status", "")) == "pending" and
			not str(tip.get("truth_label", "")).is_empty() and
			not str(tip.get("confidence_label", "")).is_empty() and
			not str(tip.get("tip_read", "")).is_empty() and
			int(tip.get("resolve_day_index", 0)) > int(tip.get("created_day_index", 0))
		):
			return true
	return false


func _tip_journal_has_resolved_memory() -> bool:
	for tip_value in RunState.get_network_tip_journal().values():
		var tip: Dictionary = tip_value
		if (
			str(tip.get("status", "")) != "pending" and
			not str(tip.get("outcome_label", "")).is_empty() and
			not str(tip.get("outcome_note", "")).is_empty() and
			int(tip.get("resolved_day_index", 0)) >= int(tip.get("resolve_day_index", 0))
		):
			return true
	return false


func _tip_journal_has_player_aware_memory() -> bool:
	for tip_value in RunState.get_network_tip_journal().values():
		var tip: Dictionary = tip_value
		if (
			str(tip.get("status", "")) != "pending" and
			not str(tip.get("player_action_label", "")).is_empty() and
			not str(tip.get("player_action_note", "")).is_empty() and
			not str(tip.get("player_action_alignment", "")).is_empty() and
			str(tip.get("outcome_note", "")).find("You ") != -1
		):
			return true
	return false


func _first_followup_ready_contact_id() -> String:
	var rows: Array = []
	for tip_value in RunState.get_network_tip_journal().values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		if str(tip.get("status", "")) == "pending":
			continue
		if not str(tip.get("followup_id", "")).is_empty():
			continue
		if str(tip.get("contact_id", "")).is_empty():
			continue
		rows.append(tip)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("resolved_day_index", 0)) > int(b.get("resolved_day_index", 0))
	)
	if rows.is_empty():
		return ""
	return str(rows[0].get("contact_id", ""))


func _tip_journal_has_followup_memory() -> bool:
	for tip_value in RunState.get_network_tip_journal().values():
		var tip: Dictionary = tip_value
		if (
			not str(tip.get("followup_id", "")).is_empty() and
			not str(tip.get("followup_label", "")).is_empty() and
			not str(tip.get("followup_note", "")).is_empty() and
			int(tip.get("followup_day_index", 0)) >= int(tip.get("resolved_day_index", 0))
		):
			return true
	return false


func _network_snapshot_has_last_tip_note(network_snapshot: Dictionary) -> bool:
	for contact_value in network_snapshot.get("contacts", []):
		var contact: Dictionary = contact_value
		if not str(contact.get("last_tip_note", "")).is_empty() and not str(contact.get("last_tip_player_action_label", "")).is_empty():
			return true
	return false


func _network_snapshot_has_followup_note(network_snapshot: Dictionary) -> bool:
	for contact_value in network_snapshot.get("contacts", []):
		var contact: Dictionary = contact_value
		if (
			not str(contact.get("last_tip_followup_id", "")).is_empty() and
			not str(contact.get("last_tip_followup_note", "")).is_empty() and
			not bool(contact.get("can_follow_up_tip", true))
		):
			return true
	return false


func _network_snapshot_has_tip_history_data(network_snapshot: Dictionary) -> bool:
	for contact_value in network_snapshot.get("contacts", []):
		var contact: Dictionary = contact_value
		var history: Array = contact.get("tip_history", [])
		if (
			not history.is_empty() and
			not str(contact.get("tip_reliability_label", "")).is_empty() and
			float(contact.get("tip_reliability_score", -1.0)) >= 0.0 and
			int(contact.get("tip_resolved_count", 0)) >= history.size()
		):
			var first_row: Dictionary = history[0]
			if not str(first_row.get("target_ticker", "")).is_empty() and not str(first_row.get("outcome_label", "")).is_empty():
				return true
	return false


func _inject_network_crosscheck_fixture(contact_id: String, other_contact_id: String, company_id: String) -> void:
	var ticker: String = str(GameManager.get_company_snapshot(company_id, false, false, false).get("ticker", company_id.to_upper()))
	var journal: Dictionary = RunState.get_network_tip_journal()
	var base_day: int = RunState.day_index
	journal["smoke_crosscheck_positive"] = {
		"id": "smoke_crosscheck_positive",
		"contact_id": contact_id,
		"contact_name": "Smoke Contact A",
		"target_company_id": company_id,
		"target_ticker": ticker,
		"created_day_index": base_day,
		"resolve_day_index": base_day + 3,
		"baseline_price": 1000.0,
		"baseline_shares": 0,
		"chain_id": "smoke_crosscheck_chain",
		"truth_label": "Accumulation",
		"confidence_label": "Early but credible",
		"source_role": "research desk",
		"tip_read": "Smoke fixture constructive read.",
		"status": "pending"
	}
	journal["smoke_crosscheck_warning"] = {
		"id": "smoke_crosscheck_warning",
		"contact_id": other_contact_id,
		"contact_name": "Smoke Contact B",
		"target_company_id": company_id,
		"target_ticker": ticker,
		"created_day_index": base_day,
		"resolve_day_index": base_day + 3,
		"baseline_price": 1000.0,
		"baseline_shares": 0,
		"chain_id": "smoke_crosscheck_chain",
		"truth_label": "Retail Trap",
		"confidence_label": "Grounded read",
		"source_role": "flow desk",
		"tip_read": "Smoke fixture cautionary read.",
		"status": "pending"
	}
	RunState.set_network_tip_journal(journal)


func _network_snapshot_has_crosscheck_data(network_snapshot: Dictionary) -> bool:
	for contact_value in network_snapshot.get("contacts", []):
		var contact: Dictionary = contact_value
		var rows: Array = contact.get("cross_contact_rows", [])
		if (
			str(contact.get("cross_contact_label", "")) == "Conflicting sources" and
			not str(contact.get("cross_contact_note", "")).is_empty() and
			not rows.is_empty() and
			bool(contact.get("can_ask_source_check", false))
		):
			var first_row: Dictionary = rows[0]
			if (
				not str(first_row.get("truth_label", "")).is_empty() and
				not str(first_row.get("contact_name", "")).is_empty() and
				not str(first_row.get("source_role", "")).is_empty()
			):
				return true
	return false


func _tip_journal_has_source_check_memory() -> bool:
	for tip_value in RunState.get_network_tip_journal().values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		if not str(tip.get("source_check_note", "")).is_empty() and int(tip.get("source_check_day_index", 0)) == RunState.day_index:
			return true
	return false


func _network_snapshot_has_source_check_answer(network_snapshot: Dictionary) -> bool:
	for contact_value in network_snapshot.get("contacts", []):
		var contact: Dictionary = contact_value
		if (
			str(contact.get("cross_contact_label", "")) == "Conflicting sources" and
			bool(contact.get("has_direct_source_conflict", false)) and
			not str(contact.get("source_check_note", "")).is_empty() and
			not bool(contact.get("can_ask_source_check", true))
		):
			return true
	return false


func _network_snapshot_has_journal_data(network_snapshot: Dictionary) -> bool:
	var rows: Array = network_snapshot.get("journal", [])
	if rows.size() < 6:
		return false
	var required_types := {
		"tip": false,
		"tip_result": false,
		"followup": false,
		"source_check": false,
		"request": false,
		"referral": false
	}
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var row_type: String = str(row.get("type", ""))
		if required_types.has(row_type):
			required_types[row_type] = true
		if str(row.get("title", "")).is_empty() or str(row.get("detail", "")).is_empty():
			return false
	for is_present in required_types.values():
		if not bool(is_present):
			return false
	return true


func _first_referral_setup(company_id: String) -> Dictionary:
	var snapshot: Dictionary = GameManager.get_company_snapshot(company_id, false, false, false)
	for management_value in snapshot.get("management_roster", []):
		var management: Dictionary = management_value
		for bridge_value in management.get("connected_floaters", []):
			var bridge: Dictionary = bridge_value
			var floater_id: String = str(bridge.get("contact_id", ""))
			if int(bridge.get("score", 0)) >= 50:
				return {
					"insider_id": str(management.get("id", management.get("contact_id", ""))),
					"floater_id": floater_id,
					"score": int(bridge.get("score", 0))
				}
	return {}


func _ensure_test_contact_discovery(contact_id: String, company_id: String, source_type: String) -> void:
	var discoveries: Dictionary = RunState.get_network_discoveries()
	discoveries[contact_id] = {
		"contact_id": contact_id,
		"discovered": true,
		"source_type": source_type,
		"source_id": company_id,
		"target_company_id": company_id,
		"target_company_ids": [company_id],
		"target_sector_id": str(GameManager.get_company_snapshot(company_id, false, false, false).get("sector_id", "")),
		"day_index": RunState.day_index
	}
	RunState.set_network_discoveries(discoveries)


func _count_unlocked_rows(rows: Array) -> int:
	var count: int = 0
	for row_value in rows:
		var row: Dictionary = row_value
		if bool(row.get("unlocked", false)):
			count += 1
	return count


func _collect_node_text(root: Node) -> String:
	var parts: Array = []
	_collect_node_text_into(root, parts)
	return "\n".join(parts)


func _collect_item_list_text(item_list: ItemList) -> String:
	if item_list == null:
		return ""
	var parts: Array = []
	for item_index in range(item_list.item_count):
		parts.append(item_list.get_item_text(item_index))
	return "\n".join(parts)


func _metric_table_values_for_label(rows: VBoxContainer, row_label: String) -> Array:
	if rows == null:
		return []
	for row_node in rows.get_children():
		var labels: Array = []
		for cell_node in row_node.get_children():
			if cell_node is Label:
				labels.append((cell_node as Label).text)
		if labels.size() <= 1 or str(labels[0]) != row_label:
			continue
		var values: Array = []
		for value_index in range(1, labels.size()):
			values.append(str(labels[value_index]))
		return values
	return []


func _collect_node_text_into(node: Node, parts: Array) -> void:
	if node is Label:
		parts.append((node as Label).text)
	elif node is Button:
		parts.append((node as Button).text)
	for child in node.get_children():
		_collect_node_text_into(child, parts)


func _build_academy_answers(use_correct_answers: bool, category_id: String = "technical") -> Dictionary:
	var answers: Dictionary = {}
	var catalog: Dictionary = DataRepository.get_academy_catalog()
	for category_value in catalog.get("categories", []):
		var category: Dictionary = category_value
		if str(category.get("id", "")) != category_id:
			continue
		for question_value in category.get("quiz_questions", []):
			var question: Dictionary = question_value
			var question_id: String = str(question.get("id", ""))
			var correct_answer_id: String = str(question.get("correct_answer_id", ""))
			if use_correct_answers:
				answers[question_id] = correct_answer_id
				continue
			for option_value in question.get("options", []):
				var option: Dictionary = option_value
				var option_id: String = str(option.get("id", ""))
				if option_id != correct_answer_id:
					answers[question_id] = option_id
					break
	return answers


func _validate_floater_company_lead_limit() -> String:
	var network_data: Dictionary = DataRepository.get_contact_network_data()
	var floater_ids := {}
	for contact_value in network_data.get("contacts", []):
		var contact: Dictionary = contact_value
		if str(contact.get("affiliation_type", "floater")) == "floater":
			floater_ids[str(contact.get("id", ""))] = true
	var discoveries: Dictionary = RunState.get_network_discoveries()
	for contact_id_value in discoveries.keys():
		var contact_id: String = str(contact_id_value)
		if not floater_ids.has(contact_id):
			continue
		var discovery: Dictionary = discoveries.get(contact_id, {})
		var targets: Array = []
		for company_id_value in discovery.get("target_company_ids", []):
			var company_id: String = str(company_id_value)
			if not company_id.is_empty() and not targets.has(company_id):
				targets.append(company_id)
		var primary_company_id: String = str(discovery.get("target_company_id", ""))
		if not primary_company_id.is_empty() and not targets.has(primary_company_id):
			targets.append(primary_company_id)
		if targets.size() > 2:
			return "Smoke test expected floater %s to be an initial lead for at most 2 companies, found %d." % [contact_id, targets.size()]
	return ""


func _set_test_contact_relationship(contact_id: String, relationship: int) -> void:
	var contacts: Dictionary = RunState.get_network_contacts()
	var runtime: Dictionary = contacts.get(contact_id, {})
	runtime["contact_id"] = contact_id
	runtime["met"] = true
	runtime["relationship"] = relationship
	contacts[contact_id] = runtime
	RunState.set_network_contacts(contacts)


func _has_management_roles(management_roster: Array) -> bool:
	var roles := {}
	for management_value in management_roster:
		var management: Dictionary = management_value
		roles[str(management.get("affiliation_role", ""))] = true
	return roles.has("ceo") and roles.has("cfo") and roles.has("commissioner")


func _ceo_name_from_roster(management_roster: Array) -> String:
	for management_value in management_roster:
		if typeof(management_value) != TYPE_DICTIONARY:
			continue
		var management: Dictionary = management_value
		if str(management.get("affiliation_role", "")) == "ceo":
			return str(management.get("display_name", ""))
	return ""


func _validate_generated_roster() -> String:
	var seen_tickers := {}
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = RunState.get_effective_company_definition(company_id)
		var company_name: String = str(definition.get("name", "")).strip_edges()
		var ticker: String = str(definition.get("ticker", "")).strip_edges()
		var name_words: PackedStringArray = company_name.split(" ", false)
		if name_words.size() < 2 or name_words.size() > 3:
			return "Smoke test expected %s to have a generated 2-3 word name, found '%s'." % [
				ticker if not ticker.is_empty() else company_id.to_upper(),
				company_name
			]
		if ticker.length() != 4:
			return "Smoke test expected %s to have a 4-letter generated ticker, found '%s'." % [
				company_id.to_upper(),
				ticker
			]
		if seen_tickers.has(ticker):
			return "Smoke test expected unique generated tickers, but %s was duplicated." % ticker
		seen_tickers[ticker] = true

	return ""


func _validate_starting_price_diversity(expected_company_count: int) -> String:
	var max_price: float = 0.0
	var min_price: float = INF
	var above_5000_count: int = 0
	var above_10000_count: int = 0
	var above_20000_count: int = 0
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var snapshot: Dictionary = GameManager.get_company_snapshot(company_id)
		var current_price: float = float(snapshot.get("current_price", 0.0))
		max_price = max(max_price, current_price)
		min_price = min(min_price, current_price)
		if current_price >= 5000.0:
			above_5000_count += 1
		if current_price >= 10000.0:
			above_10000_count += 1
		if current_price >= 20000.0:
			above_20000_count += 1

	if expected_company_count >= 50 and above_5000_count <= 0:
		return "Smoke test expected larger generated rosters to include at least one opening price above Rp5.000, but the max price was %s." % String.num(max_price, 0)
	if expected_company_count >= 50 and min_price >= 300.0:
		return "Smoke test expected larger generated rosters to still include cheaper names, but the minimum opening price was %s." % String.num(min_price, 0)

	return ""


func _profile_container_text(root: Node) -> String:
	var parts: Array = []
	_collect_label_text(root, parts)
	return "\n".join(parts)


func _collect_label_text(node: Node, parts: Array) -> void:
	if node is Label:
		var label: Label = node as Label
		parts.append(label.text)
	for child in node.get_children():
		_collect_label_text(child, parts)


func _validate_save_round_trip(
	tracked_company_id: String,
	opening_snapshot: Dictionary,
	opening_macro_state: Dictionary,
	expected_company_count: int
) -> String:
	var saved_run: Dictionary = RunState.to_save_dict()
	var saved_definitions: Dictionary = saved_run.get("company_definitions", {})
	if saved_definitions.size() != expected_company_count:
		return "Smoke test expected %d generated company definitions in the save payload, found %d." % [
			expected_company_count,
			saved_definitions.size()
		]

	RunState.load_from_dict(saved_run)
	var reloaded_snapshot: Dictionary = GameManager.get_company_snapshot(tracked_company_id, true, true, true)
	var reloaded_chart_5y: Dictionary = GameManager.get_company_chart_snapshot(tracked_company_id, "5y")
	if reloaded_snapshot.is_empty():
		return "Smoke test expected %s to survive a save/load round trip, but the snapshot disappeared." % tracked_company_id.to_upper()
	if str(reloaded_snapshot.get("ticker", "")) != str(opening_snapshot.get("ticker", "")):
		return "Smoke test expected %s to keep its generated ticker after save/load, found %s." % [
			tracked_company_id.to_upper(),
			reloaded_snapshot.get("ticker", "")
		]
	if reloaded_snapshot.get("price_bars", []).is_empty():
		return "Smoke test expected %s OHLCV bars to survive a save/load round trip." % tracked_company_id.to_upper()
	var opening_management_roster: Array = opening_snapshot.get("management_roster", [])
	var reloaded_management_roster: Array = reloaded_snapshot.get("management_roster", [])
	if reloaded_management_roster.size() != 3 or opening_management_roster.is_empty():
		return "Smoke test expected %s management roster to survive a save/load round trip." % tracked_company_id.to_upper()
	if str(reloaded_management_roster[0].get("contact_id", "")) != str(opening_management_roster[0].get("contact_id", "")):
		return "Smoke test expected %s management insider ids to stay stable after save/load." % tracked_company_id.to_upper()
	if reloaded_chart_5y.is_empty() or int(reloaded_chart_5y.get("start_date", {}).get("year", 2020)) >= 2020:
		return "Smoke test expected %s to rebuild its lazy historical 5Y chart after save/load." % tracked_company_id.to_upper()
	var reloaded_macro_state: Dictionary = GameManager.get_current_macro_state()
	if reloaded_macro_state.is_empty():
		return "Smoke test expected the generated macro state to survive a save/load round trip."
	if int(reloaded_macro_state.get("year", 0)) != int(opening_macro_state.get("year", 0)):
		return "Smoke test expected the macro year to survive save/load, found %s instead of %s." % [
			reloaded_macro_state.get("year", 0),
			opening_macro_state.get("year", 0)
		]
	if int(reloaded_macro_state.get("policy_action_bps", 0)) != int(opening_macro_state.get("policy_action_bps", 0)):
		return "Smoke test expected the macro policy decision to survive save/load for year %s." % opening_macro_state.get("year", 0)

	return ""
