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

var trading_calendar = preload("res://systems/TradingCalendar.gd").new()


func _ready() -> void:
	DataRepository.reload_all()
	var calendar_validation: String = _validate_trading_calendar_extension()
	if not calendar_validation.is_empty():
		push_error(calendar_validation)
		get_tree().quit(1)
		return

	var menu_result: Dictionary = await _validate_main_menu_flow()
	if not bool(menu_result.get("success", false)):
		push_error(str(menu_result.get("message", "Main menu smoke test failed.")))
		get_tree().quit(1)
		return

	var normal_result: Dictionary = await _run_scenario(424242, GameManager.DEFAULT_DIFFICULTY_ID, 10, 1, false)
	if not bool(normal_result.get("success", false)):
		push_error(str(normal_result.get("message", "Smoke test failed.")))
		get_tree().quit(1)
		return

	var hardcore_result: Dictionary = await _run_scenario(987654, "hardcore", 30, 10, true)
	if not bool(hardcore_result.get("success", false)):
		push_error(str(hardcore_result.get("message", "Hardcore smoke test failed.")))
		get_tree().quit(1)
		return

	var smoke_line: String = "SMOKE_OK normal_equity=%s hardcore_equity=%s hardcore_down_days=%d summary=%s" % [
		String.num(float(normal_result.get("equity", 0.0)), 2),
		String.num(float(hardcore_result.get("equity", 0.0)), 2),
		int(hardcore_result.get("down_days", 0)),
		str(normal_result.get("summary", ""))
	]
	print(smoke_line)
	var result_file = FileAccess.open("user://smoke_test_result.txt", FileAccess.WRITE)
	if result_file != null:
		result_file.store_string(smoke_line)
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()


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
	if difficulty_card_grid == null or difficulty_card_grid.get_child_count() != 4:
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the difficulty selector to render four difficulty cards."
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
	if loading_progress_bar == null:
		main_menu.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the loading screen to expose a progress bar node."
		}

	main_menu.queue_free()
	await get_tree().process_frame
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
	var taskbar_stock_button: Button = game_root.find_child("TaskbarStockButton", true, false) as Button
	var taskbar_news_button: Button = game_root.find_child("TaskbarNewsButton", true, false) as Button
	var app_window_title_label: Label = game_root.find_child("AppWindowTitleLabel", true, false) as Label
	var app_window_close_button: Button = game_root.find_child("AppWindowCloseButton", true, false) as Button
	var news_window: Control = game_root.find_child("NewsWindow", true, false) as Control
	var news_article_list: ItemList = game_root.find_child("NewsArticleList", true, false) as ItemList
	var news_outlet_buttons: HBoxContainer = game_root.find_child("NewsOutletButtons", true, false) as HBoxContainer
	var social_window: Control = game_root.find_child("SocialWindow", true, false) as Control
	var social_feed_cards: VBoxContainer = game_root.find_child("SocialFeedCards", true, false) as VBoxContainer
	if desktop_layer == null or not desktop_layer.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected GameRoot to open on the new desktop layer before the trading app is launched."
		}

	if stock_app_button == null or news_app_button == null or social_app_button == null or taskbar_stock_button == null or taskbar_news_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the prototype desktop icons and taskbar launch buttons."
		}

	if app_window_title_label == null or app_window_close_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the faux app window to expose a title bar and close button."
		}

	news_app_button.emit_signal("pressed")
	await get_tree().process_frame
	if (
		news_window == null or
		not news_window.visible or
		app_window_title_label.text != "News Browser" or
		news_article_list == null or
		news_outlet_buttons == null or
		news_outlet_buttons.get_child_count() < 4 or
		news_article_list.item_count <= 0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the News icon to open the event-driven news desk with outlet buttons and populated stories."
		}

	app_window_close_button.emit_signal("pressed")
	await get_tree().process_frame
	if not desktop_layer.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected closing an app window to return the player to the desktop."
		}

	social_app_button.emit_signal("pressed")
	await get_tree().process_frame
	if (
		social_window == null or
		not social_window.visible or
		app_window_title_label.text != "Twooter" or
		social_feed_cards == null or
		social_feed_cards.get_child_count() <= 0
	):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the Twooter icon to open the simplified mobile-style social feed with populated post cards."
		}

	app_window_close_button.emit_signal("pressed")
	await get_tree().process_frame
	if not desktop_layer.visible:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected closing the Twooter window to return the player to the desktop."
		}

	stock_app_button.emit_signal("pressed")
	await get_tree().process_frame
	if app_window_title_label.text != "STOCKBOT":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the STOCKBOT icon to open the trading platform inside the faux app window."
		}

	var tracked_company_id: String = str(RunState.company_order[0]) if not RunState.company_order.is_empty() else ""
	var secondary_company_id: String = str(RunState.company_order[1]) if RunState.company_order.size() > 1 else tracked_company_id
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

	var financial_history_label: RichTextLabel = game_root.find_child("FinancialHistoryLabel", true, false) as RichTextLabel
	if financial_history_label == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the generated company history panel in the dashboard UI."
		}

	var financial_history_text: String = financial_history_label.text
	if not financial_history_text.contains("GENERATED 2010-2019 HISTORY") or not financial_history_text.contains("2019 |"):
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the generated company history panel to show the 2010-2019 history for %s." % tracked_company_id.to_upper()
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

	for _day in range(days_to_advance):
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

	if difficulty_id == GameManager.DEFAULT_DIFFICULTY_ID and current_trade_date_key != "2020-01-17":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the next trade date after the preloaded opening session plus 10 more days to be 2020-01-17, found %s." % current_trade_date_key
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
		return "Smoke test expected larger generated rosters to include at least one opening price above Rp 5,000, but the max price was %s." % String.num(max_price, 0)
	if expected_company_count >= 100 and above_10000_count <= 0:
		return "Smoke test expected Hardcore-sized rosters to include at least one opening price above Rp 10,000, but only found %d." % above_10000_count
	if expected_company_count >= 100 and above_20000_count <= 0:
		return "Smoke test expected Hardcore-sized rosters to include at least one opening price above Rp 20,000, but the max price was %s." % String.num(max_price, 0)
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
