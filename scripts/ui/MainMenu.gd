extends Control

const SCREEN_HOME := "home"
const SCREEN_DIFFICULTY := "difficulty"
const SCREEN_LOADING := "loading"
const UI_FONT_SIZE := 12
const DIFFICULTY_SELECTOR_WIDTH_RATIO := 0.9
const DIFFICULTY_SELECTOR_COMPACT_WIDTH := 720.0
const APP_FONT_CANDIDATE_PATHS := [
	"res://assets/fonts/app_font.ttf",
	"res://assets/fonts/app_font.otf",
	"res://assets/fonts/OpenSans-Regular.ttf"
]

var cached_app_font: Font = null
var has_checked_app_font: bool = false

@onready var home_screen: Control = $Margin/ScreenRoot/HomeScreen
@onready var difficulty_screen: Control = $Margin/ScreenRoot/DifficultyScreen
@onready var loading_screen: Control = $Margin/ScreenRoot/LoadingScreen
@onready var status_label: Label = $Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/ActionCard/ActionMargin/ActionVBox/StatusLabel
@onready var load_button: Button = $Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/ActionCard/ActionMargin/ActionVBox/ButtonColumn/LoadButton
@onready var difficulty_selector_card: PanelContainer = $Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard
@onready var difficulty_card_grid: GridContainer = $Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard/SelectorMargin/SelectorVBox/DifficultyCardGrid
@onready var selection_detail_label: Label = $Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard/SelectorMargin/SelectorVBox/SelectionDetailLabel
@onready var tutorial_checkbox: CheckBox = $Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard/SelectorMargin/SelectorVBox/TutorialCheckBox
@onready var continue_button: Button = $Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard/SelectorMargin/SelectorVBox/FooterRow/ContinueButton
@onready var loading_title_label: Label = $Margin/ScreenRoot/LoadingScreen/CenterContent/LoadingCard/LoadingMargin/LoadingVBox/LoadingTitleLabel
@onready var loading_stage_label: Label = $Margin/ScreenRoot/LoadingScreen/CenterContent/LoadingCard/LoadingMargin/LoadingVBox/LoadingStageLabel
@onready var loading_body_label: Label = $Margin/ScreenRoot/LoadingScreen/CenterContent/LoadingCard/LoadingMargin/LoadingVBox/LoadingBodyLabel
@onready var loading_progress_bar: ProgressBar = $Margin/ScreenRoot/LoadingScreen/CenterContent/LoadingCard/LoadingMargin/LoadingVBox/LoadingProgressBar
@onready var loading_step_label: Label = $Margin/ScreenRoot/LoadingScreen/CenterContent/LoadingCard/LoadingMargin/LoadingVBox/LoadingStepLabel
@onready var loading_subprogress_label: Label = $Margin/ScreenRoot/LoadingScreen/CenterContent/LoadingCard/LoadingMargin/LoadingVBox/LoadingSubprogressLabel
@onready var loading_note_label: Label = $Margin/ScreenRoot/LoadingScreen/CenterContent/LoadingCard/LoadingMargin/LoadingVBox/LoadingNoteLabel

var difficulty_button_group := ButtonGroup.new()
var difficulty_card_buttons: Dictionary = {}
var selected_difficulty_id := ""
var selected_load_slot_id := ""
var load_slots_dialog: ConfirmationDialog = null
var load_slots_list: ItemList = null
var load_slots_hint_label: Label = null


func _ready() -> void:
	$Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/ActionCard/ActionMargin/ActionVBox/ButtonColumn/NewGameButton.pressed.connect(_on_new_game_pressed)
	load_button.pressed.connect(_on_load_pressed)
	$Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/ActionCard/ActionMargin/ActionVBox/ButtonColumn/QuitButton.pressed.connect(_on_quit_pressed)
	$Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard/SelectorMargin/SelectorVBox/FooterRow/BackButton.pressed.connect(_on_back_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	GameManager.run_loading_started.connect(_on_run_loading_started)
	GameManager.run_loading_progress.connect(_on_run_loading_progress)
	GameManager.run_loading_detail_updated.connect(_on_run_loading_detail_updated)
	GameManager.run_loading_finished.connect(_on_run_loading_finished)
	get_viewport().size_changed.connect(_update_difficulty_selector_size)
	_ensure_load_slots_dialog()
	_populate_difficulty_cards()
	tutorial_checkbox.button_pressed = true
	_refresh_load_state()
	_set_screen(SCREEN_HOME)
	_clear_selected_difficulty()
	_apply_global_font_size_overrides()
	_update_difficulty_selector_size()


func _refresh_load_state() -> void:
	var save_info: Dictionary = _first_visible_save_info()
	load_button.disabled = not SaveManager.has_any_loadable_save()
	if bool(save_info.get("loadable", false)):
		status_label.text = _build_save_available_text(save_info)
	elif bool(save_info.get("exists", false)) or bool(save_info.get("backup_exists", false)):
		status_label.text = _build_save_unreadable_text(save_info)
	else:
		status_label.text = "No saved run yet. Start a new game to choose a market difficulty and build the first watchlist.\nFirst save slot: %s" % str(save_info.get("write_absolute_path", save_info.get("absolute_path", "")))


func _on_new_game_pressed() -> void:
	_clear_selected_difficulty()
	_set_screen(SCREEN_DIFFICULTY)


func _on_load_pressed() -> void:
	if not SaveManager.has_any_loadable_save():
		status_label.text = "No readable save file was found, so a fresh run is safer."
		_refresh_load_state()
		return

	_show_load_slots_dialog()


func _on_quit_pressed() -> void:
	GameManager.quit_game()


func _on_back_pressed() -> void:
	_set_screen(SCREEN_HOME)
	_refresh_load_state()


func _on_continue_pressed() -> void:
	if selected_difficulty_id.is_empty():
		return

	_prepare_loading_screen(selected_difficulty_id)
	_set_screen(SCREEN_LOADING)
	await GameManager.start_new_run_with_loading(0, selected_difficulty_id, tutorial_checkbox.button_pressed)


func _populate_difficulty_cards() -> void:
	difficulty_card_buttons.clear()
	for child in difficulty_card_grid.get_children():
		child.queue_free()

	for difficulty_config_value in GameManager.get_difficulty_options():
		var difficulty_config: Dictionary = difficulty_config_value
		var difficulty_id: String = str(difficulty_config.get("id", GameManager.DEFAULT_DIFFICULTY_ID))
		var card_button := Button.new()
		card_button.name = "%sCardButton" % difficulty_id.capitalize()
		card_button.custom_minimum_size = Vector2(0, 176)
		card_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_button.toggle_mode = true
		card_button.button_group = difficulty_button_group
		card_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card_button.clip_text = true
		card_button.text = _build_difficulty_card_text(difficulty_config)
		card_button.pressed.connect(_on_difficulty_card_pressed.bind(difficulty_id))
		difficulty_card_grid.add_child(card_button)
		difficulty_card_buttons[difficulty_id] = card_button


func _update_difficulty_selector_size() -> void:
	if difficulty_selector_card == null:
		return
	var viewport_width: float = get_viewport_rect().size.x
	var available_width: float = difficulty_screen.size.x if difficulty_screen != null and difficulty_screen.size.x > 0.0 else viewport_width
	var target_width: float = floor(min(viewport_width * DIFFICULTY_SELECTOR_WIDTH_RATIO, available_width))
	difficulty_selector_card.custom_minimum_size.x = target_width
	difficulty_selector_card.size.x = target_width
	if difficulty_card_grid != null:
		difficulty_card_grid.columns = 1 if target_width < DIFFICULTY_SELECTOR_COMPACT_WIDTH else 3


func _build_difficulty_card_text(difficulty_config: Dictionary) -> String:
	return "%s\n\nCash: %s\nCompanies: %d\nVolatility: %s\nEvents: every %d day(s)" % [
		str(difficulty_config.get("label", "Normal")),
		_format_currency(float(difficulty_config.get("starting_cash", 0.0))),
		int(difficulty_config.get("company_count", 0)),
		str(difficulty_config.get("volatility_label", "Normal")),
		int(difficulty_config.get("event_interval_days", 30.0))
	]


func _on_difficulty_card_pressed(difficulty_id: String) -> void:
	selected_difficulty_id = difficulty_id
	_update_selection_detail()


func _update_selection_detail() -> void:
	if selected_difficulty_id.is_empty():
		selection_detail_label.text = "Pick one difficulty card to preview bankroll size, company count, and market intensity before you continue."
		continue_button.disabled = true
		return

	var difficulty_config: Dictionary = GameManager.get_difficulty_config(selected_difficulty_id)
	selection_detail_label.text = "%s run selected.\nCash: %s  |  Companies: %d  |  Volatility: %s  |  Event pace: about once every %d day(s)." % [
		str(difficulty_config.get("label", "Normal")),
		_format_currency(float(difficulty_config.get("starting_cash", 0.0))),
		int(difficulty_config.get("company_count", 0)),
		str(difficulty_config.get("volatility_label", "Normal")),
		int(difficulty_config.get("event_interval_days", 30.0))
	]
	continue_button.disabled = false


func _clear_selected_difficulty() -> void:
	selected_difficulty_id = ""
	for card_button_value in difficulty_card_buttons.values():
		var card_button: Button = card_button_value
		card_button.set_pressed_no_signal(false)
	_update_selection_detail()


func _prepare_loading_screen(difficulty_id: String) -> void:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(difficulty_id)
	loading_title_label.text = "Starting %s run" % str(difficulty_config.get("label", "Normal"))
	loading_stage_label.text = "Preparing market seed"
	loading_body_label.text = "Building %d procedural companies, their core market data, and the opening market state." % int(difficulty_config.get("company_count", 0))
	loading_step_label.text = "Step 1/%d" % max(GameManager.NEW_RUN_LOADING_STEPS.size(), 1)
	loading_progress_bar.value = 0.0
	loading_subprogress_label.text = ""
	loading_note_label.text = "Desktop entry comes first. Full company detail can finish in the background after the market opens."


func _prepare_load_screen(slot_id: String = "") -> void:
	var save_info: Dictionary = SaveManager.get_save_file_info(slot_id)
	loading_title_label.text = "Loading saved run"
	loading_stage_label.text = "Reading save file"
	loading_body_label.text = "Restoring Day %d (%s), portfolio, watchlist, and current trading day." % [
		int(save_info.get("trading_day", 1)),
		str(save_info.get("trade_date_text", "Unknown date"))
	]
	loading_step_label.text = "Step 1/%d" % max(GameManager.LOAD_RUN_LOADING_STEPS.size(), 1)
	loading_progress_bar.value = 0.0
	loading_subprogress_label.text = ""
	loading_note_label.text = "%s: %s" % [
		str(save_info.get("storage_label", "Save file")),
		str(save_info.get("absolute_path", ""))
	]


func _ensure_load_slots_dialog() -> void:
	if load_slots_dialog != null:
		return
	load_slots_dialog = ConfirmationDialog.new()
	load_slots_dialog.name = "LoadSlotsDialog"
	load_slots_dialog.title = "Load Run"
	load_slots_dialog.confirmed.connect(_on_load_slots_confirmed)
	add_child(load_slots_dialog)
	load_slots_dialog.get_ok_button().text = "Load"
	load_slots_dialog.get_cancel_button().text = "Cancel"

	var dialog_margin := MarginContainer.new()
	dialog_margin.add_theme_constant_override("margin_left", 16)
	dialog_margin.add_theme_constant_override("margin_top", 16)
	dialog_margin.add_theme_constant_override("margin_right", 16)
	dialog_margin.add_theme_constant_override("margin_bottom", 16)
	load_slots_dialog.add_child(dialog_margin)

	var dialog_vbox := VBoxContainer.new()
	dialog_vbox.custom_minimum_size = Vector2(720, 360)
	dialog_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_vbox.add_theme_constant_override("separation", 10)
	dialog_margin.add_child(dialog_vbox)

	load_slots_hint_label = Label.new()
	load_slots_hint_label.name = "LoadSlotsHintLabel"
	load_slots_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	load_slots_hint_label.text = "Choose a save slot to restore."
	dialog_vbox.add_child(load_slots_hint_label)

	load_slots_list = ItemList.new()
	load_slots_list.name = "LoadSlotsList"
	load_slots_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_slots_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	load_slots_list.item_selected.connect(_on_load_slot_selected)
	load_slots_list.item_activated.connect(_on_load_slot_activated)
	dialog_vbox.add_child(load_slots_list)


func _show_load_slots_dialog() -> void:
	_populate_load_slots_list()
	load_slots_dialog.popup_centered()


func _populate_load_slots_list() -> void:
	selected_load_slot_id = ""
	load_slots_list.clear()
	var first_selectable_index: int = -1
	for slot_value in SaveManager.get_save_slots():
		var slot: Dictionary = slot_value
		var loadable: bool = bool(slot.get("loadable", false))
		var item_index: int = load_slots_list.add_item(_format_save_slot_list_item(slot))
		load_slots_list.set_item_metadata(item_index, str(slot.get("slot_id", "")))
		load_slots_list.set_item_disabled(item_index, not loadable)
		if loadable and first_selectable_index < 0:
			first_selectable_index = item_index
	if first_selectable_index >= 0:
		load_slots_list.select(first_selectable_index)
		selected_load_slot_id = str(load_slots_list.get_item_metadata(first_selectable_index))
	load_slots_dialog.get_ok_button().disabled = selected_load_slot_id.is_empty()


func _format_save_slot_list_item(slot: Dictionary) -> String:
	if not bool(slot.get("loadable", false)):
		return "%s | Empty" % str(slot.get("slot_label", "Slot"))
	return "%s%s | Day %d | %s | %s | Equity %s" % [
		str(slot.get("slot_label", "Slot")),
		" (current)" if bool(slot.get("active", false)) else "",
		int(slot.get("trading_day", 1)),
		str(slot.get("trade_date_text", "Unknown date")),
		str(slot.get("difficulty_label", "Normal")),
		str(slot.get("equity_text", "Rp0,00"))
	]


func _on_load_slot_selected(index: int) -> void:
	if index < 0 or load_slots_list.is_item_disabled(index):
		selected_load_slot_id = ""
	else:
		selected_load_slot_id = str(load_slots_list.get_item_metadata(index))
	load_slots_dialog.get_ok_button().disabled = selected_load_slot_id.is_empty()


func _on_load_slot_activated(index: int) -> void:
	_on_load_slot_selected(index)
	if selected_load_slot_id.is_empty():
		return
	load_slots_dialog.hide()
	await _load_selected_slot()


func _on_load_slots_confirmed() -> void:
	await _load_selected_slot()


func _load_selected_slot() -> void:
	if selected_load_slot_id.is_empty():
		return
	SaveManager.set_active_slot_id(selected_load_slot_id)
	_prepare_load_screen(selected_load_slot_id)
	_set_screen(SCREEN_LOADING)
	var load_succeeded: bool = await GameManager.load_run_from_save_with_loading(selected_load_slot_id)
	if not is_inside_tree():
		return
	if not load_succeeded:
		_set_screen(SCREEN_HOME)
		status_label.text = "The selected save slot could not be loaded. Start a new run or inspect the save path shown below."
		_refresh_load_state()


func _first_visible_save_info() -> Dictionary:
	var active_info: Dictionary = SaveManager.get_save_file_info()
	if bool(active_info.get("loadable", false)):
		return active_info
	for slot_value in SaveManager.get_save_slots():
		var slot: Dictionary = slot_value
		if bool(slot.get("loadable", false)):
			return slot
	return active_info


func _build_save_available_text(save_info: Dictionary) -> String:
	var recovery_note: String = "Recovered backup available. " if bool(save_info.get("recovered_from_backup", false)) else ""
	var schema_text: String = "Legacy save" if int(save_info.get("schema_version", 0)) <= 0 else "Save v%d" % int(save_info.get("schema_version", 0))
	return "%sSaved run found (%s).\nDay %d | %s | %s | %d companies\nEquity %s | Cash %s | Last saved %s\nFile: %s" % [
		recovery_note,
		schema_text,
		int(save_info.get("trading_day", 1)),
		str(save_info.get("trade_date_text", "Unknown date")),
		str(save_info.get("difficulty_label", "Normal")),
		int(save_info.get("company_count", 0)),
		str(save_info.get("equity_text", "Rp0,00")),
		str(save_info.get("cash_text", "Rp0,00")),
		str(save_info.get("saved_at_text", "Unknown")),
		str(save_info.get("absolute_path", ""))
	]


func _build_save_unreadable_text(save_info: Dictionary) -> String:
	return "A save file exists, but it is not readable yet.\n%s\nPrimary: %s\nBackup: %s" % [
		str(save_info.get("load_error", "Save JSON could not be parsed.")),
		str(save_info.get("absolute_path", "")),
		str(save_info.get("backup_absolute_path", ""))
	]


func _on_run_loading_started(difficulty_id: String) -> void:
	if not is_inside_tree():
		return

	_prepare_loading_screen(difficulty_id)


func _on_run_loading_progress(
	stage_id: String,
	stage_label: String,
	stage_index: int,
	stage_count: int,
	progress_ratio: float
) -> void:
	if not is_inside_tree():
		return

	loading_stage_label.text = stage_label
	loading_step_label.text = "Step %d/%d" % [stage_index, max(stage_count, 1)]
	loading_progress_bar.value = clamp(progress_ratio, 0.0, 1.0) * 100.0
	loading_body_label.text = _loading_body_for_stage(stage_id)
	if stage_id == "financials":
		loading_note_label.text = _loading_note_for_stage(stage_id)
	elif stage_id != "financials":
		loading_subprogress_label.text = ""
		loading_note_label.text = _loading_note_for_stage(stage_id)


func _on_run_loading_detail_updated(subprogress_text: String, log_lines: Array) -> void:
	if not is_inside_tree():
		return

	loading_subprogress_label.text = subprogress_text
	var normalized_lines: Array = []
	for line_value in log_lines:
		var line: String = str(line_value).strip_edges()
		if line.is_empty():
			continue
		normalized_lines.append(line)
	if subprogress_text.is_empty() and normalized_lines.is_empty():
		return
	loading_note_label.text = "\n".join(normalized_lines) if not normalized_lines.is_empty() else _loading_note_for_stage("financials")


func _loading_body_for_stage(stage_id: String) -> String:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(selected_difficulty_id)
	var company_count: int = int(difficulty_config.get("company_count", 0))
	match stage_id:
		"load_save":
			return "Reading the saved market state from disk so the roster, prices, and event history can be restored."
		"restore_state":
			return "Restoring the portfolio, watchlist, calendar day, and generated company data from the save file."
		"corporate_actions":
			return "Preparing RUPS schedules, dividend dates, shareholder record dates, and corporate-action agendas."
		"load_launch":
			return "Opening the trading desk and handing control back to the saved run."
		"seed":
			return "Locking the run seed, trade calendar, and bankroll rules before generation starts."
		"companies":
			return "Creating %d company identities, tickers, sector assignments, and listing boards for the new roster." % company_count
		"financials":
			return "Creating market-ready fundamentals, scores, traits, and opening prices for the new roster. Full company detail can finish after the desktop opens."
		"opening_day":
			return "Simulating the first trading session so the market opens with live price changes instead of flat starting quotes."
		"save":
			return "Saving the freshly generated run so the roster survives reloads."
		"launch":
			return "Opening the market desk and handing control to the player."
		_:
			return "Preparing the next market screen."


func _loading_note_for_stage(stage_id: String) -> String:
	match stage_id:
		"financials":
			return "Preparing core market data first so the desktop can open sooner."
		"corporate_actions":
			return "Only the near-term corporate calendar is prepared now; later years fill in as the run advances."
		"save":
			return "Writing the new run to disk before control returns to the desktop."
		"launch", "load_launch":
			return "Handing control to the trading desk."
		_:
			return "Larger rosters can take a moment, especially on Grind where 50 companies are generated."


func _on_run_loading_finished() -> void:
	if not is_inside_tree():
		return

	loading_progress_bar.value = 100.0


func _set_screen(screen_id: String) -> void:
	home_screen.visible = screen_id == SCREEN_HOME
	difficulty_screen.visible = screen_id == SCREEN_DIFFICULTY
	loading_screen.visible = screen_id == SCREEN_LOADING


func _apply_global_font_size_overrides() -> void:
	_apply_font_size_override_to_tree(self, UI_FONT_SIZE, _get_app_font())


func _apply_font_size_override_to_tree(node: Node, font_size: int, app_font: Font = null) -> void:
	if node is Control:
		_apply_font_override_to_control(node as Control, font_size, app_font)

	for child: Node in node.get_children():
		_apply_font_size_override_to_tree(child, font_size, app_font)


func _apply_font_override_to_control(control: Control, font_size: int, app_font: Font = null) -> void:
	control.add_theme_font_size_override("font_size", font_size)
	if app_font != null:
		control.add_theme_font_override("font", app_font)
	if control is RichTextLabel:
		var rich_text: RichTextLabel = control
		rich_text.add_theme_font_size_override("normal_font_size", font_size)
		rich_text.add_theme_font_size_override("bold_font_size", font_size)
		rich_text.add_theme_font_size_override("italics_font_size", font_size)
		rich_text.add_theme_font_size_override("mono_font_size", font_size)
		if app_font != null:
			rich_text.add_theme_font_override("normal_font", app_font)
			rich_text.add_theme_font_override("bold_font", app_font)
			rich_text.add_theme_font_override("italics_font", app_font)
			rich_text.add_theme_font_override("mono_font", app_font)


func _get_app_font() -> Font:
	if has_checked_app_font:
		return cached_app_font

	has_checked_app_font = true
	for font_path_value in APP_FONT_CANDIDATE_PATHS:
		var font_path: String = str(font_path_value)
		if not ResourceLoader.exists(font_path):
			continue
		var font_resource := load(font_path)
		if font_resource is Font:
			cached_app_font = font_resource
			return cached_app_font
	return null


func _format_currency(value: float) -> String:
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
