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
			GameManager.mark_ftue_completed()
			for _step_index in range(6):
				var guide_snapshot: Dictionary = GameManager.get_first_hour_guide_snapshot()
				if str(guide_snapshot.get("current_step_id", "")) == "seeded_rupslb":
					break
				GameManager.advance_first_hour_guide_step()
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
	var load_slots_dialog: ConfirmationDialog = main_menu.find_child("LoadSlotsDialog", true, false) as ConfirmationDialog
	var load_slots_list: ItemList = main_menu.find_child("LoadSlotsList", true, false) as ItemList
	if loading_progress_bar == null or loading_subprogress_label == null or loading_note_label == null or load_slots_dialog == null or load_slots_list == null:
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the loading screen and save-slot load dialog to expose their required nodes."
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


func _validate_ftue_flow() -> Dictionary:
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
	var settings_exit_button: Button = game_root.find_child("SettingsExitButton", true, false) as Button
	var settings_panel: PanelContainer = game_root.find_child("SettingsPanel", true, false) as PanelContainer
	var settings_current_slot_label: Label = game_root.find_child("SettingsCurrentSlotLabel", true, false) as Label
	var settings_last_saved_label: Label = game_root.find_child("SettingsLastSavedLabel", true, false) as Label
	var settings_confirm_overlay: Control = game_root.find_child("SettingsConfirmOverlay", true, false) as Control
	var settings_confirm_title_label: Label = game_root.find_child("SettingsConfirmTitleLabel", true, false) as Label
	var settings_confirm_cancel_button: Button = game_root.find_child("SettingsConfirmCancelButton", true, false) as Button
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
		settings_exit_button == null or
		settings_panel == null or
		settings_current_slot_label == null or
		settings_last_saved_label == null or
		settings_confirm_overlay == null or
		settings_confirm_title_label == null or
		settings_confirm_cancel_button == null
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Settings shortcut and save/load popup controls to exist."
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
	if settings_panel.custom_minimum_size.y > 430.0 or not settings_save_button.visible or not settings_load_button.visible or not settings_exit_button.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Settings overlay to stay compact with visible Save/Load/Exit controls."
		}
	if not settings_current_slot_label.text.contains("Current slot") or not settings_last_saved_label.text.contains("Last saved"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected Settings to show current-slot and last-saved labels."
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
		dashboard_event_snapshot.get("report_calendar_snapshot", {}).is_empty()
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the cached dashboard event snapshot to include reports, meetings, and the current report calendar."
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
			company_controlled_option.get_item_count() <= 0 or
			company_request_button.disabled
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the unlocked Company app to open with controllable company agenda controls."
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
		var debug_start_rupslb_status_label: Label = game_root.find_child("DebugStartRupslbStatusLabel", true, false) as Label
		if (
			debug_overlay == null or
			not debug_overlay.visible or
			debug_start_rupslb_button == null or
			debug_cash_dividend_button == null or
			debug_stock_split_button == null or
			debug_start_rupslb_status_label == null
		):
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected the debug overlay to expose selected-stock corporate-action generator controls."
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
		if debug_cash_dividend_button.disabled:
			game_root.queue_free()
			await get_tree().process_frame
			return {
				"success": false,
				"message": "Smoke test expected non-RUPSLB debug corporate-action generators to work for a selected stock without a held lot."
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
	var academy_category_count: int = int(DataRepository.get_academy_catalog().get("categories", []).size())
	if (
		academy_window == null or
		not academy_window.visible or
		not game_root.is_desktop_app_open("academy") or
		game_root.get_active_desktop_app_id() != "academy" or
		game_root.get_desktop_app_window_title("academy") != "Academy" or
		academy_category_tabs == null or
		academy_category_tabs.get_child_count() != academy_category_count or
		academy_section_list == null or
		academy_section_list.item_count != 8 or
		academy_banner_frame == null or
		not academy_banner_frame.visible or
		academy_action_row == null or
		not academy_action_row.visible
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Academy icon to open a lesson window with catalog categories, eight Technical sections, a banner frame, and an action row."
		}

	var academy_content_host: Control = academy_window.get_parent() as Control
	if academy_content_host == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not resolve the Academy desktop content host."
		}
	var academy_action_rect: Rect2 = academy_action_row.get_global_rect()
	var academy_host_rect: Rect2 = academy_content_host.get_global_rect()
	if academy_action_rect.end.y > academy_host_rect.end.y + 1.0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Academy action row to fit inside the visible desktop window."
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
	daily_recap_dialog.visible = false
	await get_tree().process_frame

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
		movers_tabs.get_tab_count() < 2 or
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
			"message": "Smoke test expected Dashboard movers, sector cards, uniform calendar grid, zero dashboard separation, and hidden Analyzer tab."
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

	var broker_rows_vbox: VBoxContainer = game_root.find_child("BrokerRows", true, false) as VBoxContainer
	var broker_meter_bar: ProgressBar = game_root.find_child("BrokerMeterBar", true, false) as ProgressBar
	if financial_history_summary_label == null or broker_rows_vbox == null or broker_meter_bar == null:
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
	var life_lifestyle_option: OptionButton = game_root.find_child("LifeLifestyleOption", true, false) as OptionButton
	var life_update_button: Button = game_root.find_child("LifeUpdatePlanButton", true, false) as Button
	var life_budget_rows: VBoxContainer = game_root.find_child("LifeBudgetRows", true, false) as VBoxContainer
	var life_runway_label: Label = game_root.find_child("LifeRunwayLabel", true, false) as Label
	var life_dividend_rows: VBoxContainer = game_root.find_child("LifeDividendRows", true, false) as VBoxContainer
	var life_snapshot: Dictionary = GameManager.get_life_snapshot()
	if (
		life_window == null or
		not life_window.visible or
		not game_root.is_desktop_app_open("life") or
		game_root.get_active_desktop_app_id() != "life" or
		game_root.get_desktop_app_window_title("life") != "Life" or
		not _desktop_window_animation_settled(game_root, "LifeDesktopWindow") or
		life_summary_label == null or
		life_summary_label.text.find("Monthly outflow") == -1 or
		life_housing_option == null or
		life_housing_option.item_count < 3 or
		life_lifestyle_option == null or
		life_lifestyle_option.item_count < 3 or
		life_update_button == null or
		life_budget_rows == null or
		life_budget_rows.get_child_count() < 5 or
		life_runway_label == null or
		life_runway_label.text.is_empty() or
		life_dividend_rows == null or
		life_snapshot.is_empty() or
		float(life_snapshot.get("monthly_outflow", 0.0)) <= 0.0 or
		not life_snapshot.has("housing_options") or
		not life_snapshot.has("lifestyle_options")
	):
		return "Smoke test expected the Life icon to open a settled cash-flow planning window with populated selectors, budget rows, and runway summary."

	var starting_lifestyle_id: String = str(RunState.get_player_life().get("lifestyle_id", ""))
	var target_lifestyle_index: int = -1
	for index in range(life_lifestyle_option.item_count):
		if str(life_lifestyle_option.get_item_metadata(index)) != starting_lifestyle_id:
			target_lifestyle_index = index
			break
	if target_lifestyle_index < 0:
		return "Smoke test expected Life to expose at least one alternate lifestyle choice."
	var target_lifestyle_id: String = str(life_lifestyle_option.get_item_metadata(target_lifestyle_index))
	life_lifestyle_option.select(target_lifestyle_index)
	life_lifestyle_option.emit_signal("item_selected", target_lifestyle_index)
	life_update_button.emit_signal("pressed")
	await get_tree().process_frame
	if str(RunState.get_player_life().get("lifestyle_id", "")) != target_lifestyle_id:
		return "Smoke test expected updating the Life plan to persist the selected lifestyle."
	if not SaveManager.has_pending_save():
		return "Smoke test expected updating the Life plan to queue an autosave."

	var saved_life_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(saved_life_state)
	if str(RunState.get_player_life().get("lifestyle_id", "")) != target_lifestyle_id:
		return "Smoke test expected Life plan choices to survive a RunState save/load round trip."
	if not SaveManager.flush_pending_save():
		return "Smoke test expected Life autosave flush to succeed."
	var persisted_life_state: Dictionary = SaveManager.load_run()
	if str(persisted_life_state.get("player_life", {}).get("lifestyle_id", "")) != target_lifestyle_id:
		return "Smoke test expected flushed Life saves to persist player_life to disk."

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
	var thesis_report_text: RichTextLabel = game_root.find_child("ThesisReportText", true, false) as RichTextLabel
	var thesis_report_close_button: Button = game_root.find_child("ThesisReportCloseButton", true, false) as Button
	var thesis_report_regenerate_button: Button = game_root.find_child("ThesisReportRegenerateButton", true, false) as Button
	var thesis_use_selected_button: Button = game_root.find_child("ThesisUseSelectedStockButton", true, false) as Button
	if (
		thesis_window == null or
		not thesis_window.visible or
		not game_root.is_desktop_app_open("thesis") or
		game_root.get_active_desktop_app_id() != "thesis" or
		game_root.get_desktop_app_window_title("thesis") != "Thesis Board" or
		not _desktop_window_animation_settled(game_root, "ThesisBoardDesktopWindow") or
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
		thesis_white_paper_panel.visible or
		thesis_report_text == null or
		thesis_report_close_button == null or
		thesis_report_regenerate_button == null or
		thesis_use_selected_button == null
	):
		return "Smoke test expected the Thesis Board icon to open a settled two-column window with a hidden report overlay."

	thesis_use_selected_button.emit_signal("pressed")
	await get_tree().process_frame
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
	if visible_report_text.find("recommendation") == -1 or visible_report_text.find("reasoning grade") == -1 or visible_report_text.find("target area") == -1:
		return "Smoke test expected the Thesis white paper to show recommendation, reasoning grade, and target area."
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
