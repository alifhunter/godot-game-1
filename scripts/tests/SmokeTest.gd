extends Node

var trading_calendar = preload("res://systems/TradingCalendar.gd").new()


func _ready() -> void:
	DataRepository.reload_all()
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
	var game_root = load("res://scenes/game/GameRoot.tscn").instantiate()
	add_child(game_root)
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

	var tracked_company_id: String = str(RunState.company_order[0])
	var opening_snapshot: Dictionary = GameManager.get_company_snapshot(tracked_company_id)
	var opening_price: float = float(opening_snapshot.get("current_price", 0.0))
	var opening_financials: Dictionary = opening_snapshot.get("financials", {})
	var opening_financial_history: Array = opening_snapshot.get("financial_history", [])
	var opening_trade_date_key: String = trading_calendar.to_key(RunState.get_current_trade_date())
	if opening_trade_date_key != "2020-01-02":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the first trading day to be 2020-01-02, found %s." % opening_trade_date_key
		}

	if opening_financials.is_empty() or float(opening_financials.get("market_cap", 0.0)) <= 0.0:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected %s to expose financial stats in the company snapshot." % tracked_company_id.to_upper()
		}

	var save_round_trip_error: String = _validate_save_round_trip(tracked_company_id, opening_snapshot, expected_company_count)
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

	var lot_spin_box: SpinBox = game_root.find_child("LotSpinBox", true, false) as SpinBox
	var buy_button: Button = game_root.find_child("BuyButton", true, false) as Button
	if lot_spin_box == null or buy_button == null:
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test could not find the dashboard trade controls needed to place an opening order."
		}

	lot_spin_box.value = float(opening_lots)
	await get_tree().process_frame
	buy_button.emit_signal("pressed")
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

	if difficulty_id == GameManager.DEFAULT_DIFFICULTY_ID and current_trade_date_key != "2020-01-16":
		game_root.queue_free()
		await get_tree().process_frame
		return {
			"success": false,
			"message": "Smoke test expected the next trade date after 10 days to be 2020-01-16, found %s." % current_trade_date_key
		}

	var result: Dictionary = {
		"success": true,
		"equity": float(GameManager.get_portfolio_snapshot().get("equity", 0.0)),
		"summary": str(summary.get("explanation", "")),
		"down_days": down_days,
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


func _validate_save_round_trip(tracked_company_id: String, opening_snapshot: Dictionary, expected_company_count: int) -> String:
	var saved_run: Dictionary = RunState.to_save_dict()
	var saved_definitions: Dictionary = saved_run.get("company_definitions", {})
	if saved_definitions.size() != expected_company_count:
		return "Smoke test expected %d generated company definitions in the save payload, found %d." % [
			expected_company_count,
			saved_definitions.size()
		]

	RunState.load_from_dict(saved_run)
	var reloaded_snapshot: Dictionary = GameManager.get_company_snapshot(tracked_company_id)
	if reloaded_snapshot.is_empty():
		return "Smoke test expected %s to survive a save/load round trip, but the snapshot disappeared." % tracked_company_id.to_upper()
	if str(reloaded_snapshot.get("ticker", "")) != str(opening_snapshot.get("ticker", "")):
		return "Smoke test expected %s to keep its generated ticker after save/load, found %s." % [
			tracked_company_id.to_upper(),
			reloaded_snapshot.get("ticker", "")
		]

	return ""
