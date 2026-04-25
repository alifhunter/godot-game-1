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

var trading_calendar = preload("res://systems/TradingCalendar.gd").new()
var batched_setup_progress_calls := 0
var batched_setup_progress_done := 0
var batched_setup_progress_total := 0


func _ready() -> void:
	var smoke_mode: String = _get_smoke_mode()
	DataRepository.reload_all()
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
	if new_game_button == null:
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the New Game button in the main menu."
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

	var selector_card: PanelContainer = main_menu.find_child("SelectorCard", true, false) as PanelContainer
	var maximum_selector_width: float = get_viewport().get_visible_rect().size.x * 0.9 + 1.0
	if selector_card == null or selector_card.custom_minimum_size.x > maximum_selector_width or selector_card.get_global_rect().size.x > maximum_selector_width:
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the difficulty selector card to fit within 90 percent of the screen width."
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

	var loading_progress_bar: ProgressBar = main_menu.find_child("LoadingProgressBar", true, false) as ProgressBar
	var loading_subprogress_label: Label = main_menu.find_child("LoadingSubprogressLabel", true, false) as Label
	var loading_note_label: Label = main_menu.find_child("LoadingNoteLabel", true, false) as Label
	if loading_progress_bar == null or loading_subprogress_label == null or loading_note_label == null:
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the loading screen to expose progress, subprogress, and rolling-note nodes."
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

	return {"success": true}


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
	var upgrades_app_button: Button = game_root.find_child("UpgradesAppButton", true, false) as Button
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
	var network_requests_list: ItemList = game_root.find_child("NetworkRequestsList", true, false) as ItemList
	var academy_window: Control = game_root.find_child("AcademyWindow", true, false) as Control
	var academy_category_tabs: HBoxContainer = game_root.find_child("AcademyCategoryTabs", true, false) as HBoxContainer
	var academy_section_list: ItemList = game_root.find_child("AcademySectionList", true, false) as ItemList
	var upgrade_window: Control = game_root.find_child("UpgradeWindow", true, false) as Control
	var upgrade_cards_vbox: VBoxContainer = game_root.find_child("UpgradeCardsVBox", true, false) as VBoxContainer
	if desktop_layer == null or not desktop_layer.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected GameRoot to open on the new desktop layer before the trading app is launched."
		}

	if stock_app_button == null or news_app_button == null or social_app_button == null or network_app_button == null or academy_app_button == null or upgrades_app_button == null or taskbar_stock_button == null or taskbar_news_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the prototype desktop icons, Academy icon, Upgrades icon, and taskbar launch buttons."
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
	var attend_meeting_result: Dictionary = GameManager.attend_corporate_meeting(opening_meeting_id)
	if not bool(attend_meeting_result.get("success", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected corporate meeting attendance to be markable in v1."
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
			not GameManager.has_method("debug_schedule_next_day_rights_issue_rupslb") or
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

		var rupslb_candidate_ids: Array = []
		for company_index in range(RunState.company_order.size() - 1, -1, -1):
			var candidate_company_id: String = str(RunState.company_order[company_index])
			if bool(GameManager.get_company_corporate_action_snapshot(candidate_company_id).get("has_live_chain", false)):
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

		var observer_company_id: String = str(rupslb_candidate_ids[0])
		var eligible_company_id: String = str(rupslb_candidate_ids[1])

		var forced_observer_result: Dictionary = GameManager.debug_force_rights_issue_rupslb(observer_company_id)
		if not bool(forced_observer_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug helper to force a same-day observer RUPSLB meeting."
			}
		var observer_meeting_id: String = str(forced_observer_result.get("meeting", {}).get("id", ""))
		var observer_start_result: Dictionary = GameManager.start_corporate_meeting_session(observer_meeting_id)
		var observer_session_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(observer_meeting_id)
		if (
			not bool(observer_start_result.get("success", false)) or
			observer_session_snapshot.is_empty() or
			bool(observer_session_snapshot.get("session", {}).get("voting_eligible", true))
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected a zero-position player to attend the forced RUPSLB only as an observer."
			}
		var observer_agenda_id: String = ""
		var observer_agenda_payload: Array = observer_session_snapshot.get("agenda_payload", [])
		if not observer_agenda_payload.is_empty():
			observer_agenda_id = str(observer_agenda_payload[0].get("id", ""))
		var observer_illegal_vote_result: Dictionary = GameManager.submit_corporate_meeting_vote(observer_meeting_id, observer_agenda_id, "agree")
		if bool(observer_illegal_vote_result.get("success", false)):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected observer-only RUPSLB sessions to reject agree/disagree votes without share ownership."
			}
		var observer_abstain_result: Dictionary = GameManager.submit_corporate_meeting_vote(observer_meeting_id, observer_agenda_id, "abstain")
		if (
			not bool(observer_abstain_result.get("success", false)) or
			GameManager.get_corporate_meeting_session_snapshot(observer_meeting_id).get("result_summary", {}).is_empty()
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected observer-only RUPSLB sessions to resolve through an abstain path."
			}
		GameManager.close_corporate_meeting_session(observer_meeting_id)

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
		var debug_start_rupslb_status_label: Label = game_root.find_child("DebugStartRupslbStatusLabel", true, false) as Label
		if (
			debug_overlay == null or
			not debug_overlay.visible or
			debug_start_rupslb_button == null or
			debug_start_rupslb_status_label == null
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug overlay to expose a Start RUPSLB control."
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

		var dashboard_meeting_buttons: VBoxContainer = game_root.find_child("DashboardMeetingButtons", true, false) as VBoxContainer
		var scheduled_dashboard_button: Button = null
		if dashboard_meeting_buttons != null:
			for child in dashboard_meeting_buttons.get_children():
				var meeting_button: Button = child as Button
				if meeting_button == null:
					continue
				if meeting_button.text.find(debug_target_ticker) != -1 and meeting_button.text.find("RUPSLB") != -1:
					scheduled_dashboard_button = meeting_button
					break
		if scheduled_dashboard_button == null:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the queued debug RUPSLB meeting to surface in the dashboard meeting buttons on the next day."
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

	var initial_news_snapshot: Dictionary = GameManager.get_news_snapshot()
	if _count_unlocked_rows(initial_news_snapshot.get("outlets", [])) != 1:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected News to start with only intel level 1 unlocked."
		}
	var initial_social_snapshot: Dictionary = GameManager.get_twooter_snapshot()
	if int(initial_social_snapshot.get("access_tier", 0)) != 1:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Twooter to start at access tier 1."
		}

	var initial_academy_snapshot: Dictionary = GameManager.get_academy_snapshot("technical", "quiz")
	if not bool(initial_academy_snapshot.get("quiz", {}).get("locked", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Technical Academy quiz to start locked."
		}

	academy_app_button.emit_signal("pressed")
	await get_tree().process_frame
	if (
		academy_window == null or
		not academy_window.visible or
		not game_root.is_desktop_app_open("academy") or
		game_root.get_active_desktop_app_id() != "academy" or
		game_root.get_desktop_app_window_title("academy") != "Academy" or
		academy_category_tabs == null or
		academy_category_tabs.get_child_count() != 4 or
		academy_section_list == null or
		academy_section_list.item_count != 8
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Academy icon to open a lesson window with four categories and eight Technical sections."
		}

	var coming_soon_snapshot: Dictionary = GameManager.get_academy_snapshot("mindset", "")
	if not bool(coming_soon_snapshot.get("coming_soon", false)):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected non-Technical Academy categories to show coming-soon states."
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

	for required_section_id in ["intro", "market_structure", "candlesticks", "patterns"]:
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
			"message": "Smoke test expected reading Intro, Market Structure, Candlesticks, and Patterns to unlock the Technical quiz."
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
		upgrade_cards_vbox == null or
		upgrade_cards_vbox.get_child_count() < RunState.UPGRADE_TRACK_IDS.size()
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Upgrades icon to open a populated shop window."
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
		if not bool(twooter_result.get("success", false)) or int(GameManager.get_twooter_snapshot().get("access_tier", 0)) != 2:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected Twooter Content tier 3 to unlock access tier 2."
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

	news_app_button.emit_signal("pressed")
	await get_tree().process_frame
	if (
		news_window == null or
		not news_window.visible or
		not game_root.is_desktop_app_open("news") or
		game_root.get_active_desktop_app_id() != "news" or
		game_root.get_desktop_app_window_title("news") != "News Browser" or
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
			"message": "Smoke test expected the News icon to open the newspaper-style News app with outlet buttons, story cards, byline, and image frame."
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
	for lead_value in source_leads:
		var lead: Dictionary = lead_value
		if str(lead.get("source_type", "")) == "news" and str(lead.get("source_id", "")) == news_article_id:
			has_news_source_lead = true
			break
	if not has_news_source_lead:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected at least one News article to surface a valid Network source lead."
		}

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

	social_app_button.emit_signal("pressed")
	await get_tree().process_frame
	if (
		social_window == null or
		not social_window.visible or
		not game_root.is_desktop_app_open("social") or
		game_root.get_active_desktop_app_id() != "social" or
		game_root.get_desktop_app_window_title("social") != "Twooter" or
		social_feed_cards == null or
		social_feed_cards.get_child_count() <= 0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Twooter icon to open the simplified mobile-style social feed with populated post cards."
		}

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
	var network_snapshot: Dictionary = GameManager.get_network_snapshot()
	if (
		network_window == null or
		not network_window.visible or
		not game_root.is_desktop_app_open("network") or
		game_root.get_active_desktop_app_id() != "network" or
		game_root.get_desktop_app_window_title("network") != "Network" or
		network_contacts_list == null or
		str(network_snapshot.get("recognition", {}).get("label", "")).is_empty() or
		int(network_snapshot.get("contact_cap", 0)) <= 0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Network icon to open a contact window with recognition data."
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
	if (
		not game_root.is_desktop_app_open("stock") or
		game_root.get_active_desktop_app_id() != "stock" or
		game_root.get_desktop_app_window_title("stock") != "STOCKBOT"
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the STOCKBOT icon to open the trading platform inside the runtime desktop window manager."
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
	var work_tabs: TabContainer = game_root.find_child("WorkTabs", true, false) as TabContainer
	var upcoming_reports_label: Label = game_root.find_child("PlaceholderBottomBodyLabel", true, false) as Label
	if (
		dashboard_grid == null or
		int(dashboard_grid.get_theme_constant("h_separation")) != 0 or
		int(dashboard_grid.get_theme_constant("v_separation")) != 0 or
		movers_tabs == null or
		movers_tabs.get_tab_count() < 2 or
		work_tabs == null or
		not work_tabs.is_tab_hidden(4) or
		upcoming_reports_label == null or
		not upcoming_reports_label.text.contains("Q1 2020")
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Dashboard movers, report calendar text, zero dashboard separation, and hidden Analyzer tab."
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

	GameManager.discover_network_contacts_for_company(tracked_company_id)
	network_snapshot = GameManager.get_network_snapshot()
	var discovered_contacts: Array = network_snapshot.get("discoveries", [])
	if discovered_contacts.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected company Profile discovery to expose at least one Network contact."
		}
	var tracked_sector_id: String = str(GameManager.get_company_snapshot(tracked_company_id).get("sector_id", ""))
	var tracked_profile_leads: int = 0
	for discovered_value in discovered_contacts:
		var discovered_contact: Dictionary = discovered_value
		if str(discovered_contact.get("source_type", "")) != "profile":
			continue
		if str(discovered_contact.get("target_company_id", "")) != tracked_company_id:
			continue
		tracked_profile_leads += 1
		if not (tracked_sector_id in discovered_contact.get("sector_ids", [])):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected company Profile Network leads to match the company's sector."
			}
	if tracked_profile_leads <= 0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected company Profile Network discovery to produce at least one matching lead."
		}

	for company_index in range(min(RunState.company_order.size(), 8)):
		GameManager.discover_network_contacts_for_company(str(RunState.company_order[company_index]))
	var lead_limit_validation: String = _validate_floater_company_lead_limit()
	if not lead_limit_validation.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": lead_limit_validation
		}

	var profile_management_label: Label = game_root.find_child("ProfileManagementLabel", true, false) as Label
	if profile_management_label == null or not profile_management_label.text.contains("CEO") or not profile_management_label.text.contains("CFO") or not profile_management_label.text.contains("Commissioner"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected company Profile to display public management names and roles."
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
	var meet_result: Dictionary = GameManager.meet_contact(contact_id, {"source_type": "profile", "source_id": tracked_company_id})
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
	var referral_result: Dictionary = GameManager.request_contact_referral(contact_id, tracked_company_id)
	var referred_contact_id: String = str(referral_result.get("contact_id", ""))
	if not bool(referral_result.get("success", false)) or referred_contact_id.is_empty():
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected a connected floater to refer a company insider once relationship is high enough."
		}
	var post_referral_contacts: Dictionary = RunState.get_network_contacts()
	if int(post_referral_contacts.get(contact_id, {}).get("relationship", 0)) != 35:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected successful Network referral to spend 10 relationship points."
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

	var insider_tip_result: Dictionary = GameManager.request_contact_tip(referred_contact_id)
	if not bool(insider_tip_result.get("success", false)) or not _has_contact_arc(referred_contact_id, tracked_company_id, "tip"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected company insider tips to default to the insider's affiliated company."
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
	if help_text_label == null or not help_text_label.text.contains("WORKFLOW"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Help menu to expose the moved workflow copy."
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
	var shares_outstanding: float = float(opening_snapshot.get("shares_outstanding", 0.0))
	var ownership_test_shares: int = int(ceil(shares_outstanding * 0.051 / float(RunState.LOT_SIZE))) * RunState.LOT_SIZE
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

	var range_1d_button: Button = game_root.find_child("Range1DButton", true, false) as Button
	var range_5y_button: Button = game_root.find_child("Range5YButton", true, false) as Button
	var range_ytd_button: Button = game_root.find_child("RangeYTDButton", true, false) as Button
	var display_line_button: Button = game_root.find_child("DisplayLineButton", true, false) as Button
	var display_candle_button: Button = game_root.find_child("DisplayCandleButton", true, false) as Button
	var zoom_out_button: Button = game_root.find_child("ZoomOutButton", true, false) as Button
	var zoom_in_button: Button = game_root.find_child("ZoomInButton", true, false) as Button
	var chart_meta_label: Label = game_root.find_child("ChartMetaLabel", true, false) as Label
	if range_1d_button == null or range_5y_button == null or range_ytd_button == null or display_line_button == null or display_candle_button == null or zoom_out_button == null or zoom_in_button == null or chart_meta_label == null:
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

	var broker_summary_label: Label = game_root.find_child("BrokerSummaryLabel", true, false) as Label
	var broker_rows_vbox: VBoxContainer = game_root.find_child("BrokerRows", true, false) as VBoxContainer
	if financial_history_summary_label == null or broker_summary_label == null or broker_rows_vbox == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the Key Stats or Broker widgets needed for the post-buy detail regression check."
		}

	var rendered_broker_rows_after_buy: int = broker_rows_vbox.get_child_count() - 1
	if (
		not financial_history_summary_label.text.contains("Generated 2010-2019 history") or
		not broker_summary_label.text.contains("Lead buyer:") or
		rendered_broker_rows_after_buy <= 0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Key Stats history and Broker rows to stay populated after the opening buy refresh."
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


func _count_down_days(price_history: Array) -> int:
	var down_days: int = 0
	for index in range(1, price_history.size()):
		if float(price_history[index]) < float(price_history[index - 1]):
			down_days += 1
	return down_days


func _validate_contact_network_data() -> String:
	var network_data: Dictionary = DataRepository.get_contact_network_data()
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


func _has_met_network_contact(network_snapshot: Dictionary, contact_id: String) -> bool:
	for contact_value in network_snapshot.get("contacts", []):
		var contact: Dictionary = contact_value
		if str(contact.get("id", "")) == contact_id and bool(contact.get("met", false)):
			return true
	return false


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


func _build_academy_answers(use_correct_answers: bool) -> Dictionary:
	var answers: Dictionary = {}
	var catalog: Dictionary = DataRepository.get_academy_catalog()
	for category_value in catalog.get("categories", []):
		var category: Dictionary = category_value
		if str(category.get("id", "")) != "technical":
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
