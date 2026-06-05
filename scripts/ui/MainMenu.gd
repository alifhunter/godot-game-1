extends Control

const SCREEN_HOME := "home"
const SCREEN_DIFFICULTY := "difficulty"
const SCREEN_LOADING := "loading"
const UI_FONT_SIZE := 12
const DIFFICULTY_SELECTOR_WIDTH_RATIO := 0.78
const DIFFICULTY_SELECTOR_MAX_WIDTH := 1040.0
const DIFFICULTY_SELECTOR_COMPACT_WIDTH := 1040.0
const DIFFICULTY_PLAN_GRID_MAX_WIDTH := 992.0
const DIFFICULTY_PLAN_CARD_WIDTH := 320.0
const DIFFICULTY_PLAN_CARD_HEIGHT := 230.0
const LOAD_SLOTS_DIALOG_WIDTH := 760.0
const LOAD_SLOTS_LIST_HEIGHT := 160.0
const LOAD_SLOT_DELETE_DIALOG_SIZE := Vector2i(540, 230)
const DISCLAIMER_SPLASH_ENABLED := true
const DISCLAIMER_SPLASH_TEXT := "The Game is a fictional stock-trading simulation. It is designed for\nentertainment and learning. It is not financial, investment, tax, legal, or\nprofessional advice.\n\nCompanies, tickers, events, prices, news, social posts, financial statements,\nand market outcomes in the Game are fictional or procedurally generated unless\nexplicitly stated otherwise. Do not make real financial decisions based on the\nGame."
const DISCLAIMER_STATIC_HOLD_DURATION := 4.5
const COLOR_DESKTOP_BG := Color(0.909804, 0.909804, 0.803922, 1)
const COLOR_DESKTOP_PANEL := Color(0.945098, 0.909804, 0.803922, 1)
const COLOR_DESKTOP_CREAM := Color(1.0, 0.976471, 0.929412, 1)
const COLOR_DESKTOP_BROWN := Color(0.509804, 0.231373, 0.0941176, 1)
const COLOR_DESKTOP_TEXT := Color(0.184314, 0.172549, 0.109804, 1)
const COLOR_DESKTOP_MUTED := Color(0.352941, 0.337255, 0.239216, 1)
const COLOR_DESKTOP_FRAME := Color(0.729412, 0.694118, 0.603922, 1)
const COLOR_DESKTOP_GOLD := Color(0.972549, 0.713726, 0.0627451, 1)
const COLOR_DESKTOP_OLIVE := Color(0.247059, 0.278431, 0.117647, 1)
const COLOR_DESKTOP_GREEN := Color(0.176471, 0.439216, 0.231373, 1)
const COLOR_WINDOW_SHADOW := Color(0.251, 0.188, 0.102, 0.18)
const APP_FONT_CANDIDATE_PATHS := [
	"res://assets/fonts/app_font.ttf",
	"res://assets/fonts/app_font.otf",
	"res://assets/fonts/OpenSans-Regular.ttf"
]

static var disclaimer_splash_shown_this_boot := false

var cached_app_font: Font = null
var has_checked_app_font: bool = false

@onready var home_screen: Control = $Margin/ScreenRoot/HomeScreen
@onready var difficulty_screen: Control = $Margin/ScreenRoot/DifficultyScreen
@onready var loading_screen: Control = $Margin/ScreenRoot/LoadingScreen
@onready var background_rect: ColorRect = $Background
@onready var action_card: PanelContainer = $Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/ActionCard
@onready var home_logo_texture: TextureRect = $Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/LogoTexture
@onready var action_title_label: Label = $Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/ActionCard/ActionMargin/ActionVBox/StartTitle
@onready var main_menu_build_label: Label = $Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/ActionCard/ActionMargin/ActionVBox/MainMenuBuildLabel
@onready var status_label: Label = $Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/ActionCard/ActionMargin/ActionVBox/StatusLabel
@onready var flow_title_label: Label = $Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/ActionCard/ActionMargin/ActionVBox/FlowTitle
@onready var flow_label: Label = $Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/ActionCard/ActionMargin/ActionVBox/FlowLabel
@onready var new_game_button: Button = $Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/ActionCard/ActionMargin/ActionVBox/ButtonColumn/NewGameButton
@onready var load_button: Button = $Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/ActionCard/ActionMargin/ActionVBox/ButtonColumn/LoadButton
@onready var quit_button: Button = $Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/ActionCard/ActionMargin/ActionVBox/ButtonColumn/QuitButton
@onready var difficulty_selector_card: PanelContainer = $Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard
@onready var difficulty_eyebrow_label: Label = $Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard/SelectorMargin/SelectorVBox/EyebrowLabel
@onready var difficulty_title_label: Label = $Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard/SelectorMargin/SelectorVBox/TitleLabel
@onready var difficulty_body_label: Label = $Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard/SelectorMargin/SelectorVBox/BodyLabel
@onready var difficulty_card_grid: GridContainer = $Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard/SelectorMargin/SelectorVBox/DifficultyCardGrid
@onready var selection_detail_label: Label = $Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard/SelectorMargin/SelectorVBox/SelectionDetailLabel
@onready var tutorial_checkbox: CheckBox = $Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard/SelectorMargin/SelectorVBox/TutorialCheckBox
@onready var continue_button: Button = $Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard/SelectorMargin/SelectorVBox/FooterRow/ContinueButton
@onready var loading_eyebrow_label: Label = $Margin/ScreenRoot/LoadingScreen/CenterContent/LoadingCard/LoadingMargin/LoadingVBox/EyebrowLabel
@onready var loading_title_label: Label = $Margin/ScreenRoot/LoadingScreen/CenterContent/LoadingCard/LoadingMargin/LoadingVBox/LoadingTitleLabel
@onready var loading_stage_label: Label = $Margin/ScreenRoot/LoadingScreen/CenterContent/LoadingCard/LoadingMargin/LoadingVBox/LoadingStageLabel
@onready var loading_body_label: Label = $Margin/ScreenRoot/LoadingScreen/CenterContent/LoadingCard/LoadingMargin/LoadingVBox/LoadingBodyLabel
@onready var loading_progress_bar: ProgressBar = $Margin/ScreenRoot/LoadingScreen/CenterContent/LoadingCard/LoadingMargin/LoadingVBox/LoadingProgressBar
@onready var loading_step_label: Label = $Margin/ScreenRoot/LoadingScreen/CenterContent/LoadingCard/LoadingMargin/LoadingVBox/LoadingStepLabel
@onready var loading_subprogress_label: Label = $Margin/ScreenRoot/LoadingScreen/CenterContent/LoadingCard/LoadingMargin/LoadingVBox/LoadingSubprogressLabel
@onready var loading_note_label: Label = $Margin/ScreenRoot/LoadingScreen/CenterContent/LoadingCard/LoadingMargin/LoadingVBox/LoadingNoteLabel
@onready var disclaimer_splash_overlay: Control = $DisclaimerSplashOverlay
@onready var disclaimer_splash_vbox: VBoxContainer = $DisclaimerSplashOverlay/DisclaimerMargin/DisclaimerCenter/DisclaimerVBox
@onready var disclaimer_splash_label: Label = $DisclaimerSplashOverlay/DisclaimerMargin/DisclaimerCenter/DisclaimerVBox/DisclaimerTextLabel

var difficulty_button_group := ButtonGroup.new()
var difficulty_card_buttons: Dictionary = {}
var selected_difficulty_id := ""
var selected_load_slot_id := ""
var delete_load_slot_id := ""
var load_slots_dialog: Control = null
var load_slots_window_panel: PanelContainer = null
var load_slots_title_bar: PanelContainer = null
var load_slots_title_label: Label = null
var load_slots_close_button: Button = null
var load_slots_body_panel: PanelContainer = null
var load_slots_list: ItemList = null
var load_slots_hint_label: Label = null
var load_slots_load_button: Button = null
var load_slots_cancel_button: Button = null
var load_slots_delete_button: Button = null
var load_slot_delete_dialog: ConfirmationDialog = null
var load_slot_delete_body_label: Label = null


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_button.pressed.connect(_on_load_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	$Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard/SelectorMargin/SelectorVBox/FooterRow/BackButton.pressed.connect(_on_back_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	GameManager.run_loading_started.connect(_on_run_loading_started)
	GameManager.run_loading_progress.connect(_on_run_loading_progress)
	GameManager.run_loading_detail_updated.connect(_on_run_loading_detail_updated)
	GameManager.run_loading_finished.connect(_on_run_loading_finished)
	get_viewport().size_changed.connect(_update_difficulty_selector_size)
	get_viewport().size_changed.connect(_update_disclaimer_splash_size)
	_ensure_load_slots_dialog()
	_populate_difficulty_cards()
	tutorial_checkbox.button_pressed = true
	_refresh_load_state()
	_set_screen(SCREEN_HOME)
	_clear_selected_difficulty()
	_apply_global_font_size_overrides()
	_apply_desktop_startup_style()
	_update_difficulty_selector_size()
	_update_disclaimer_splash_size()
	_maybe_start_disclaimer_splash()


func _exit_tree() -> void:
	_set_fishbowl_disclaimer_splash_active(false)


func _refresh_load_state() -> void:
	var save_info: Dictionary = _first_visible_save_info()
	load_button.disabled = not SaveManager.has_any_save()
	if bool(save_info.get("loadable", false)):
		status_label.text = _build_save_available_text(save_info)
	elif bool(save_info.get("exists", false)) or bool(save_info.get("backup_exists", false)):
		status_label.text = _build_save_unreadable_text(save_info)
	else:
		status_label.text = "No saved run yet.\nReady for a fresh market session."


func _on_new_game_pressed() -> void:
	_clear_selected_difficulty()
	_set_screen(SCREEN_DIFFICULTY)


func _on_load_pressed() -> void:
	if not SaveManager.has_any_save():
		status_label.text = "No save slot was found.\nStart a new run from the desktop."
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

	difficulty_card_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for difficulty_config_value in GameManager.get_difficulty_options():
		var difficulty_config: Dictionary = difficulty_config_value
		var difficulty_id: String = str(difficulty_config.get("id", GameManager.DEFAULT_DIFFICULTY_ID))
		var card_button := Button.new()
		card_button.name = "%sCardButton" % difficulty_id.capitalize()
		card_button.custom_minimum_size = Vector2(DIFFICULTY_PLAN_CARD_WIDTH, DIFFICULTY_PLAN_CARD_HEIGHT)
		card_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_button.toggle_mode = true
		card_button.button_group = difficulty_button_group
		card_button.clip_text = true
		card_button.text = ""
		_build_difficulty_plan_card_content(card_button, difficulty_config)
		_style_difficulty_card_button(card_button)
		card_button.pressed.connect(_on_difficulty_card_pressed.bind(difficulty_id))
		difficulty_card_grid.add_child(card_button)
		difficulty_card_buttons[difficulty_id] = card_button


func _update_difficulty_selector_size() -> void:
	if difficulty_selector_card == null:
		return
	var viewport_width: float = get_viewport_rect().size.x
	var available_width: float = difficulty_screen.size.x if difficulty_screen != null and difficulty_screen.size.x > 0.0 else viewport_width
	var target_width: float = floor(min(viewport_width * DIFFICULTY_SELECTOR_WIDTH_RATIO, available_width, DIFFICULTY_SELECTOR_MAX_WIDTH))
	difficulty_selector_card.custom_minimum_size.x = target_width
	difficulty_selector_card.size.x = target_width
	if difficulty_card_grid != null:
		var use_single_column: bool = target_width < DIFFICULTY_SELECTOR_COMPACT_WIDTH
		difficulty_card_grid.columns = 1 if use_single_column else 3
		var grid_width: float = min(target_width - 48.0, DIFFICULTY_PLAN_CARD_WIDTH if use_single_column else DIFFICULTY_PLAN_GRID_MAX_WIDTH)
		difficulty_card_grid.custom_minimum_size.x = max(grid_width, DIFFICULTY_PLAN_CARD_WIDTH)
		for card_button_value in difficulty_card_buttons.values():
			var card_button: Button = card_button_value
			card_button.custom_minimum_size.x = min(DIFFICULTY_PLAN_CARD_WIDTH, grid_width)


func _build_difficulty_card_text(difficulty_config: Dictionary) -> String:
	return "%s\n\nCash: %s\nCompanies: %d\nVolatility: %s\nEvents: every %d day(s)" % [
		str(difficulty_config.get("label", "Normal")),
		_format_currency(float(difficulty_config.get("starting_cash", 0.0))),
		int(difficulty_config.get("company_count", 0)),
		str(difficulty_config.get("volatility_label", "Normal")),
		int(difficulty_config.get("event_interval_days", 30.0))
	]


func _build_difficulty_plan_card_content(card_button: Button, difficulty_config: Dictionary) -> void:
	var root_margin := MarginContainer.new()
	root_margin.name = "DifficultyCardContent"
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.offset_left = 10
	root_margin.offset_top = 10
	root_margin.offset_right = -10
	root_margin.offset_bottom = -10
	root_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_button.add_child(root_margin)

	var content_vbox := VBoxContainer.new()
	content_vbox.name = "DifficultyCardVBox"
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 12)
	content_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_margin.add_child(content_vbox)

	var banner := PanelContainer.new()
	banner.name = "DifficultyCardBanner"
	banner.custom_minimum_size = Vector2(0, 48)
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(banner)

	var banner_margin := MarginContainer.new()
	banner_margin.name = "DifficultyCardBannerMargin"
	banner_margin.add_theme_constant_override("margin_left", 8)
	banner_margin.add_theme_constant_override("margin_top", 6)
	banner_margin.add_theme_constant_override("margin_right", 8)
	banner_margin.add_theme_constant_override("margin_bottom", 6)
	banner_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(banner_margin)

	var title_label := Label.new()
	title_label.name = "DifficultyCardTitle"
	title_label.text = str(difficulty_config.get("label", "Normal"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_margin.add_child(title_label)

	var metrics_vbox := VBoxContainer.new()
	metrics_vbox.name = "DifficultyCardMetrics"
	metrics_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metrics_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	metrics_vbox.add_theme_constant_override("separation", 8)
	metrics_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(metrics_vbox)

	_add_difficulty_metric_row(metrics_vbox, "Cash", _format_currency(float(difficulty_config.get("starting_cash", 0.0))))
	_add_difficulty_metric_row(metrics_vbox, "Companies", str(int(difficulty_config.get("company_count", 0))))
	_add_difficulty_metric_row(metrics_vbox, "Volatility", str(difficulty_config.get("volatility_label", "Normal")))
	_add_difficulty_metric_row(metrics_vbox, "Events", "Every %d day(s)" % int(difficulty_config.get("event_interval_days", 30.0)))


func _add_difficulty_metric_row(parent: VBoxContainer, label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	row.name = "%sMetricRow" % label_text.replace(" ", "")
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)

	var metric_label := Label.new()
	metric_label.name = "MetricLabel"
	metric_label.text = label_text
	metric_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metric_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(metric_label)

	var value_label := Label.new()
	value_label.name = "MetricValue"
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(value_label)


func _on_difficulty_card_pressed(difficulty_id: String) -> void:
	selected_difficulty_id = difficulty_id
	_refresh_difficulty_card_selection()
	_update_selection_detail()


func _update_selection_detail() -> void:
	if selected_difficulty_id.is_empty():
		selection_detail_label.text = ""
		selection_detail_label.visible = false
		continue_button.disabled = true
		return

	selection_detail_label.text = ""
	selection_detail_label.visible = false
	continue_button.disabled = false


func _clear_selected_difficulty() -> void:
	selected_difficulty_id = ""
	for card_button_value in difficulty_card_buttons.values():
		var card_button: Button = card_button_value
		card_button.set_pressed_no_signal(false)
	_refresh_difficulty_card_selection()
	_update_selection_detail()


func _refresh_difficulty_card_selection() -> void:
	for difficulty_id_value in difficulty_card_buttons.keys():
		var difficulty_id := str(difficulty_id_value)
		var card_button: Button = difficulty_card_buttons[difficulty_id]
		card_button.set_pressed_no_signal(difficulty_id == selected_difficulty_id)
		_style_difficulty_card_button(card_button)


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
	var save_info: Dictionary = SaveManager.get_save_file_info(slot_id, false)
	loading_title_label.text = "Loading saved run"
	loading_stage_label.text = "Reading save file"
	loading_body_label.text = "Restoring Day %d (%s), portfolio, watchlist, and current trading day." % [
		int(save_info.get("trading_day", 1)),
		str(save_info.get("trade_date_text", "Unknown date"))
	]
	loading_step_label.text = "Step 1/%d" % max(GameManager.LOAD_RUN_LOADING_STEPS.size(), 1)
	loading_progress_bar.value = 0.0
	loading_subprogress_label.text = ""
	loading_note_label.text = "Restoring the selected save slot."


func _ensure_load_slots_dialog() -> void:
	if load_slots_dialog != null:
		return
	load_slots_dialog = Control.new()
	load_slots_dialog.name = "LoadSlotsDialog"
	load_slots_dialog.visible = false
	load_slots_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	load_slots_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(load_slots_dialog)

	var center := CenterContainer.new()
	center.name = "LoadSlotsCenter"
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	load_slots_dialog.add_child(center)

	load_slots_window_panel = PanelContainer.new()
	load_slots_window_panel.name = "LoadSlotsWindowPanel"
	load_slots_window_panel.custom_minimum_size = Vector2(LOAD_SLOTS_DIALOG_WIDTH, 0)
	load_slots_window_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	load_slots_window_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(load_slots_window_panel)

	var window_vbox := VBoxContainer.new()
	window_vbox.name = "LoadSlotsWindowVBox"
	window_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	window_vbox.add_theme_constant_override("separation", 0)
	load_slots_window_panel.add_child(window_vbox)

	load_slots_title_bar = PanelContainer.new()
	load_slots_title_bar.name = "LoadSlotsTitleBar"
	load_slots_title_bar.custom_minimum_size = Vector2(0, 40)
	load_slots_title_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	window_vbox.add_child(load_slots_title_bar)

	var title_margin := MarginContainer.new()
	title_margin.add_theme_constant_override("margin_left", 14)
	title_margin.add_theme_constant_override("margin_top", 4)
	title_margin.add_theme_constant_override("margin_right", 8)
	title_margin.add_theme_constant_override("margin_bottom", 4)
	load_slots_title_bar.add_child(title_margin)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_margin.add_child(title_row)

	var title_left_spacer := Control.new()
	title_left_spacer.custom_minimum_size = Vector2(32, 0)
	title_row.add_child(title_left_spacer)

	load_slots_title_label = Label.new()
	load_slots_title_label.name = "LoadSlotsTitleLabel"
	load_slots_title_label.text = "Load Run"
	load_slots_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	load_slots_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	load_slots_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(load_slots_title_label)

	load_slots_close_button = Button.new()
	load_slots_close_button.name = "LoadSlotsCloseButton"
	load_slots_close_button.text = "X"
	load_slots_close_button.custom_minimum_size = Vector2(32, 26)
	load_slots_close_button.pressed.connect(_hide_load_slots_dialog)
	title_row.add_child(load_slots_close_button)

	load_slots_body_panel = PanelContainer.new()
	load_slots_body_panel.name = "LoadSlotsBodyPanel"
	load_slots_body_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	window_vbox.add_child(load_slots_body_panel)

	var dialog_margin := MarginContainer.new()
	dialog_margin.name = "LoadSlotsContentMargin"
	dialog_margin.add_theme_constant_override("margin_left", 18)
	dialog_margin.add_theme_constant_override("margin_top", 14)
	dialog_margin.add_theme_constant_override("margin_right", 18)
	dialog_margin.add_theme_constant_override("margin_bottom", 14)
	load_slots_body_panel.add_child(dialog_margin)

	var dialog_vbox := VBoxContainer.new()
	dialog_vbox.name = "LoadSlotsContentVBox"
	dialog_vbox.custom_minimum_size = Vector2(0, 0)
	dialog_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	dialog_vbox.add_theme_constant_override("separation", 10)
	dialog_margin.add_child(dialog_vbox)

	load_slots_hint_label = Label.new()
	load_slots_hint_label.name = "LoadSlotsHintLabel"
	load_slots_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	load_slots_hint_label.text = "Choose a save slot to restore or delete."
	dialog_vbox.add_child(load_slots_hint_label)

	load_slots_list = ItemList.new()
	load_slots_list.name = "LoadSlotsList"
	load_slots_list.custom_minimum_size = Vector2(0, LOAD_SLOTS_LIST_HEIGHT)
	load_slots_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_slots_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	load_slots_list.item_selected.connect(_on_load_slot_selected)
	load_slots_list.item_activated.connect(_on_load_slot_activated)
	dialog_vbox.add_child(load_slots_list)

	var action_row := HBoxContainer.new()
	action_row.name = "LoadSlotsActionRow"
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_theme_constant_override("separation", 8)
	dialog_vbox.add_child(action_row)

	load_slots_delete_button = Button.new()
	load_slots_delete_button.name = "LoadSlotsDeleteButton"
	load_slots_delete_button.text = "Delete"
	load_slots_delete_button.pressed.connect(_on_load_slot_delete_pressed)
	action_row.add_child(load_slots_delete_button)

	var action_spacer := Control.new()
	action_spacer.name = "LoadSlotsActionSpacer"
	action_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(action_spacer)

	load_slots_cancel_button = Button.new()
	load_slots_cancel_button.name = "LoadSlotsCancelButton"
	load_slots_cancel_button.text = "Cancel"
	load_slots_cancel_button.pressed.connect(_hide_load_slots_dialog)
	action_row.add_child(load_slots_cancel_button)

	load_slots_load_button = Button.new()
	load_slots_load_button.name = "LoadSlotsLoadButton"
	load_slots_load_button.text = "Load"
	load_slots_load_button.pressed.connect(_on_load_slots_confirmed)
	action_row.add_child(load_slots_load_button)

	load_slot_delete_dialog = ConfirmationDialog.new()
	load_slot_delete_dialog.name = "LoadSlotDeleteDialog"
	load_slot_delete_dialog.title = "Delete Save?"
	load_slot_delete_dialog.confirmed.connect(_on_load_slot_delete_confirmed)
	add_child(load_slot_delete_dialog)
	load_slot_delete_dialog.get_ok_button().text = "Delete"
	load_slot_delete_dialog.get_cancel_button().text = "Cancel"

	var delete_margin := MarginContainer.new()
	delete_margin.add_theme_constant_override("margin_left", 16)
	delete_margin.add_theme_constant_override("margin_top", 14)
	delete_margin.add_theme_constant_override("margin_right", 16)
	delete_margin.add_theme_constant_override("margin_bottom", 14)
	load_slot_delete_dialog.add_child(delete_margin)

	load_slot_delete_body_label = Label.new()
	load_slot_delete_body_label.name = "LoadSlotDeleteBodyLabel"
	load_slot_delete_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	load_slot_delete_body_label.custom_minimum_size = Vector2(460, 96)
	delete_margin.add_child(load_slot_delete_body_label)

	_style_load_slot_dialogs()


func _show_load_slots_dialog() -> void:
	_populate_load_slots_list()
	load_slots_dialog.show()
	load_slots_dialog.move_to_front()


func _hide_load_slots_dialog() -> void:
	if load_slots_dialog != null:
		load_slots_dialog.hide()


func _populate_load_slots_list() -> void:
	selected_load_slot_id = ""
	load_slots_list.clear()
	var first_selectable_index: int = -1
	for slot_value in SaveManager.get_save_slots():
		var slot: Dictionary = slot_value
		var loadable: bool = bool(slot.get("loadable", false))
		var has_file: bool = bool(slot.get("exists", false)) or bool(slot.get("backup_exists", false))
		var selectable: bool = loadable or has_file
		var item_index: int = load_slots_list.add_item(_format_save_slot_list_item(slot))
		load_slots_list.set_item_metadata(item_index, str(slot.get("slot_id", "")))
		load_slots_list.set_item_disabled(item_index, not selectable)
		_style_load_slot_item(item_index, slot, selectable)
		if selectable and first_selectable_index < 0:
			first_selectable_index = item_index
	if first_selectable_index >= 0:
		load_slots_list.select(first_selectable_index)
		selected_load_slot_id = str(load_slots_list.get_item_metadata(first_selectable_index))
	_refresh_load_slots_dialog_buttons()


func _format_save_slot_list_item(slot: Dictionary) -> String:
	if not bool(slot.get("loadable", false)):
		if bool(slot.get("exists", false)) or bool(slot.get("backup_exists", false)):
			var load_error: String = str(slot.get("load_error", "")).strip_edges()
			if load_error.is_empty():
				load_error = "save data is unreadable"
			return "%s | Unreadable - %s" % [
				str(slot.get("slot_label", "Slot")),
				load_error
			]
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
	_refresh_load_slots_dialog_buttons()


func _on_load_slot_activated(index: int) -> void:
	_on_load_slot_selected(index)
	if selected_load_slot_id.is_empty() or not SaveManager.has_loadable_save(selected_load_slot_id):
		return
	_hide_load_slots_dialog()
	await _load_selected_slot()


func _on_load_slots_confirmed() -> void:
	_hide_load_slots_dialog()
	await _load_selected_slot()


func _load_selected_slot() -> void:
	if selected_load_slot_id.is_empty() or not SaveManager.has_loadable_save(selected_load_slot_id):
		return
	SaveManager.set_active_slot_id(selected_load_slot_id)
	_prepare_load_screen(selected_load_slot_id)
	_set_screen(SCREEN_LOADING)
	var load_succeeded: bool = await GameManager.load_run_from_save_with_loading(selected_load_slot_id)
	if not is_inside_tree():
		return
	if not load_succeeded:
		_set_screen(SCREEN_HOME)
		status_label.text = "The selected save slot could not be loaded.\nStart a new run or choose a different slot."
		_refresh_load_state()


func _refresh_load_slots_dialog_buttons() -> void:
	if load_slots_dialog == null:
		return
	var slot: Dictionary = SaveManager.get_save_file_info(selected_load_slot_id)
	var loadable: bool = not selected_load_slot_id.is_empty() and bool(slot.get("loadable", false))
	var has_file: bool = not selected_load_slot_id.is_empty() and (bool(slot.get("exists", false)) or bool(slot.get("backup_exists", false)))
	if load_slots_load_button != null:
		load_slots_load_button.disabled = not loadable
	if load_slots_delete_button != null:
		load_slots_delete_button.disabled = not has_file


func _on_load_slot_delete_pressed() -> void:
	if selected_load_slot_id.is_empty():
		return
	var slot: Dictionary = SaveManager.get_save_file_info(selected_load_slot_id)
	if not bool(slot.get("exists", false)) and not bool(slot.get("backup_exists", false)):
		_refresh_load_slots_dialog_buttons()
		return
	delete_load_slot_id = selected_load_slot_id
	if load_slot_delete_body_label != null:
		load_slot_delete_body_label.text = _build_load_slot_delete_text(slot)
	load_slot_delete_dialog.popup_centered(LOAD_SLOT_DELETE_DIALOG_SIZE)


func _on_load_slot_delete_confirmed() -> void:
	if delete_load_slot_id.is_empty():
		return
	var slot_label: String = str(SaveManager.get_save_file_info(delete_load_slot_id).get("slot_label", "Slot"))
	SaveManager.delete_save(delete_load_slot_id)
	delete_load_slot_id = ""
	_populate_load_slots_list()
	_refresh_load_state()
	status_label.text = "Deleted %s.\nStart a new run or choose another save slot." % slot_label
	if load_slots_dialog != null and not SaveManager.has_any_save():
		load_slots_dialog.hide()


func _build_load_slot_delete_text(slot: Dictionary) -> String:
	var body_lines: Array[String] = []
	body_lines.append("Delete %s?" % str(slot.get("slot_label", "this slot")))
	if bool(slot.get("loadable", false)):
		body_lines.append("Saved run: Day %d | %s | %s" % [
			int(slot.get("trading_day", 1)),
			str(slot.get("trade_date_text", "Unknown date")),
			str(slot.get("difficulty_label", "Normal"))
		])
	else:
		body_lines.append("This slot has an unreadable save or backup.")
	body_lines.append("This removes the primary, backup, and temp files for the slot. This cannot be undone.")
	return "\n".join(body_lines)


func _first_visible_save_info() -> Dictionary:
	var active_info: Dictionary = SaveManager.get_save_file_info("", false)
	if bool(active_info.get("loadable", false)):
		return active_info
	for slot_value in SaveManager.get_save_slots():
		var slot: Dictionary = slot_value
		if bool(slot.get("loadable", false)):
			return slot
	for slot_value in SaveManager.get_save_slots():
		var slot: Dictionary = slot_value
		if bool(slot.get("exists", false)) or bool(slot.get("backup_exists", false)):
			return slot
	return active_info


func _build_save_available_text(save_info: Dictionary) -> String:
	var recovery_note: String = "Recovered backup available. " if bool(save_info.get("recovered_from_backup", false)) else ""
	return "%sSaved run found.\nDay %d | %s | %s | %d companies\nEquity %s | Cash %s | Last saved %s" % [
		recovery_note,
		int(save_info.get("trading_day", 1)),
		str(save_info.get("trade_date_text", "Unknown date")),
		str(save_info.get("difficulty_label", "Normal")),
		int(save_info.get("company_count", 0)),
		str(save_info.get("equity_text", "Rp0,00")),
		str(save_info.get("cash_text", "Rp0,00")),
		str(save_info.get("saved_at_text", "Unknown"))
	]


func _build_save_unreadable_text(_save_info: Dictionary) -> String:
	return "A save slot exists, but it is not readable.\nChoose another slot or start a new run."


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
	loading_note_label.text = _loading_note_for_stage("financials")


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


func _maybe_start_disclaimer_splash() -> void:
	if not DISCLAIMER_SPLASH_ENABLED:
		_discard_disclaimer_splash()
		return
	if disclaimer_splash_shown_this_boot:
		_discard_disclaimer_splash()
		return
	disclaimer_splash_shown_this_boot = true
	_start_disclaimer_splash()


func _start_disclaimer_splash() -> void:
	if disclaimer_splash_overlay == null or disclaimer_splash_label == null:
		return
	_set_fishbowl_disclaimer_splash_active(true)
	disclaimer_splash_overlay.visible = true
	disclaimer_splash_overlay.modulate = Color.WHITE
	disclaimer_splash_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	disclaimer_splash_label.text = DISCLAIMER_SPLASH_TEXT
	disclaimer_splash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	disclaimer_splash_label.visible_characters = -1
	_show_static_disclaimer_splash()


func _show_static_disclaimer_splash() -> void:
	await get_tree().process_frame
	if disclaimer_splash_overlay == null or disclaimer_splash_label == null:
		return

	await get_tree().create_timer(DISCLAIMER_STATIC_HOLD_DURATION).timeout
	if disclaimer_splash_overlay == null:
		return

	disclaimer_splash_overlay.queue_free()
	disclaimer_splash_overlay = null
	disclaimer_splash_vbox = null
	disclaimer_splash_label = null
	_set_fishbowl_disclaimer_splash_active(false)


func _discard_disclaimer_splash() -> void:
	if disclaimer_splash_overlay != null:
		disclaimer_splash_overlay.queue_free()
	disclaimer_splash_overlay = null
	disclaimer_splash_vbox = null
	disclaimer_splash_label = null
	_set_fishbowl_disclaimer_splash_active(false)


func _update_disclaimer_splash_size() -> void:
	if disclaimer_splash_vbox == null or disclaimer_splash_label == null:
		return
	var viewport_width: float = get_viewport_rect().size.x
	var text_width: float = clamp(viewport_width - 192.0, 320.0, 1040.0)
	disclaimer_splash_vbox.custom_minimum_size.x = text_width
	disclaimer_splash_label.add_theme_font_size_override("font_size", 18 if text_width < 640.0 else 22)


func _set_fishbowl_disclaimer_splash_active(active: bool) -> void:
	var fishbowl_overlay: Node = get_node_or_null("/root/FishbowlOverlay")
	if fishbowl_overlay != null and fishbowl_overlay.has_method("set_disclaimer_splash_active"):
		fishbowl_overlay.call("set_disclaimer_splash_active", active)


func _set_screen(screen_id: String) -> void:
	home_screen.visible = screen_id == SCREEN_HOME
	difficulty_screen.visible = screen_id == SCREEN_DIFFICULTY
	loading_screen.visible = screen_id == SCREEN_LOADING


func _apply_desktop_startup_style() -> void:
	if background_rect != null:
		background_rect.color = UiTheme.color("desktop.bg")
	if home_logo_texture != null:
		home_logo_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		home_logo_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		home_logo_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_title_label.text = "GORENGAN: STOCK TRADING SIMULATOR"
	action_title_label.visible = false
	main_menu_build_label.text = "%s / Build %s" % [BuildInfo.get_version_string(), BuildInfo.get_build_number()]
	main_menu_build_label.tooltip_text = BuildInfo.get_bug_report_context()
	flow_title_label.text = "SESSION"
	flow_title_label.visible = false
	flow_label.text = "STOCKBOT  |  NEWS  |  NETWORK  |  ACADEMY  |  LIFE"
	flow_label.visible = false
	status_label.visible = false
	new_game_button.text = "NEW RUN"
	load_button.text = "LOAD SLOT"
	quit_button.text = "POWER OFF"

	_style_desktop_window(action_card)
	_style_desktop_window(difficulty_selector_card)
	var loading_card: PanelContainer = loading_screen.find_child("LoadingCard", true, false) as PanelContainer
	if loading_card != null:
		_style_desktop_window(loading_card)

	for label_value: Label in [action_title_label, flow_title_label, difficulty_eyebrow_label, difficulty_title_label, loading_eyebrow_label, loading_title_label]:
		_style_title_label(label_value)
	for label_value: Label in [status_label, flow_label, difficulty_body_label, selection_detail_label, loading_body_label, loading_step_label, loading_subprogress_label, loading_note_label]:
		_style_body_label(label_value)
	if main_menu_build_label != null:
		UiTheme.style_label(main_menu_build_label, "desktop_muted")
	for label_value: Label in [loading_stage_label]:
		_style_body_label(label_value)

	_style_button(new_game_button, true)
	_style_button(load_button, false)
	_style_button(quit_button, false)
	_style_button(continue_button, true)
	_style_load_slot_dialogs()
	var back_button: Button = difficulty_selector_card.find_child("BackButton", true, false) as Button
	if back_button != null:
		_style_button(back_button, false)
	for card_button_value in difficulty_card_buttons.values():
		var card_button: Button = card_button_value
		_style_difficulty_card_button(card_button)
	_refresh_difficulty_card_selection()
	_style_progress_bar(loading_progress_bar)
	_style_checkbox(tutorial_checkbox)


func _style_desktop_window(panel: PanelContainer) -> void:
	if panel == null:
		return
	UiTheme.style_panel(panel, "desktop_window")


func _style_button(button: Button, primary: bool) -> void:
	if button == null:
		return
	UiTheme.style_button(button, "desktop_primary" if primary else "desktop_secondary")


func _style_danger_button(button: Button) -> void:
	if button == null:
		return
	UiTheme.style_button(button, "desktop_danger")


func _style_dialog_action_button(button: Button, variant: String) -> void:
	if button == null:
		return
	match variant:
		"primary":
			_style_button(button, true)
		"danger":
			_style_danger_button(button)
		_:
			_style_button(button, false)
	button.custom_minimum_size = Vector2(116, 38)
	button.add_theme_font_size_override("font_size", 14)


func _style_load_slots_item_list() -> void:
	if load_slots_list == null:
		return
	var panel_style := UiTheme.make_stylebox(COLOR_DESKTOP_CREAM, COLOR_DESKTOP_FRAME, 1, 4, {"left": 6, "right": 6, "top": 6, "bottom": 6})
	var cursor_style := UiTheme.make_stylebox(Color(COLOR_DESKTOP_GOLD.r, COLOR_DESKTOP_GOLD.g, COLOR_DESKTOP_GOLD.b, 0.74), COLOR_DESKTOP_BROWN, 2, 4)
	var hover_style := UiTheme.make_stylebox(Color(1.0, 0.941176, 0.760784, 0.48), COLOR_DESKTOP_FRAME, 1, 4)
	load_slots_list.add_theme_stylebox_override("panel", panel_style)
	load_slots_list.add_theme_stylebox_override("panel_focus", panel_style)
	load_slots_list.add_theme_stylebox_override("focus", panel_style)
	load_slots_list.add_theme_stylebox_override("cursor", cursor_style)
	load_slots_list.add_theme_stylebox_override("cursor_unfocused", cursor_style)
	load_slots_list.add_theme_stylebox_override("selected", cursor_style)
	load_slots_list.add_theme_stylebox_override("selected_focus", cursor_style)
	load_slots_list.add_theme_stylebox_override("hovered", hover_style)
	load_slots_list.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)
	load_slots_list.add_theme_color_override("font_hovered_color", COLOR_DESKTOP_TEXT)
	load_slots_list.add_theme_color_override("font_selected_color", COLOR_DESKTOP_TEXT)
	load_slots_list.add_theme_color_override("font_hovered_selected_color", COLOR_DESKTOP_TEXT)
	load_slots_list.add_theme_color_override("font_disabled_color", Color(0.431373, 0.392157, 0.282353, 1))
	load_slots_list.add_theme_color_override("guide_color", Color(0, 0, 0, 0))
	load_slots_list.add_theme_constant_override("h_separation", 8)
	load_slots_list.add_theme_constant_override("v_separation", 8)
	var app_font := _get_app_font()
	if app_font != null:
		load_slots_list.add_theme_font_override("font", app_font)
	load_slots_list.add_theme_font_size_override("font_size", 15)


func _style_load_slot_item(item_index: int, slot: Dictionary, selectable: bool) -> void:
	if load_slots_list == null:
		return
	if bool(slot.get("loadable", false)):
		load_slots_list.set_item_custom_fg_color(item_index, COLOR_DESKTOP_TEXT)
		if bool(slot.get("active", false)):
			load_slots_list.set_item_custom_bg_color(item_index, Color(COLOR_DESKTOP_GOLD.r, COLOR_DESKTOP_GOLD.g, COLOR_DESKTOP_GOLD.b, 0.18))
	elif bool(slot.get("exists", false)) or bool(slot.get("backup_exists", false)):
		load_slots_list.set_item_custom_fg_color(item_index, COLOR_DESKTOP_BROWN)
		load_slots_list.set_item_custom_bg_color(item_index, Color(0.956863, 0.760784, 0.521569, 0.16))
	elif not selectable:
		load_slots_list.set_item_custom_fg_color(item_index, Color(0.431373, 0.392157, 0.282353, 1))


func _style_load_slot_dialogs() -> void:
	if load_slots_window_panel != null:
		load_slots_window_panel.add_theme_stylebox_override(
			"panel",
			UiTheme.make_stylebox(Color(0.207843, 0.2, 0.184314, 1), Color(0.207843, 0.2, 0.184314, 1), 0, 5)
		)
	if load_slots_title_bar != null:
		load_slots_title_bar.add_theme_stylebox_override(
			"panel",
			UiTheme.make_stylebox(Color(0.207843, 0.2, 0.184314, 1), Color(0.207843, 0.2, 0.184314, 1), 0, 5)
		)
	if load_slots_body_panel != null:
		load_slots_body_panel.add_theme_stylebox_override(
			"panel",
			UiTheme.make_stylebox(COLOR_DESKTOP_CREAM, COLOR_DESKTOP_BROWN, 2, 5)
		)
	if load_slots_title_label != null:
		load_slots_title_label.add_theme_font_override("font", UiTheme.font("bold"))
		load_slots_title_label.add_theme_font_size_override("font_size", 16)
		load_slots_title_label.add_theme_color_override("font_color", COLOR_DESKTOP_CREAM)
	if load_slots_close_button != null:
		UiTheme.style_button(load_slots_close_button, "window_control")
		load_slots_close_button.custom_minimum_size = Vector2(32, 26)
		load_slots_close_button.add_theme_font_size_override("font_size", 14)

	if load_slot_delete_dialog != null:
		UiTheme.style_panel(load_slot_delete_dialog, "dialog")
		load_slot_delete_dialog.add_theme_color_override("title_color", COLOR_DESKTOP_CREAM)
		load_slot_delete_dialog.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)

	if load_slots_hint_label != null:
		_style_body_label(load_slots_hint_label)
		load_slots_hint_label.add_theme_color_override("font_color", COLOR_DESKTOP_MUTED)
		load_slots_hint_label.add_theme_font_size_override("font_size", 15)
	if load_slot_delete_body_label != null:
		_style_body_label(load_slot_delete_body_label)
	if load_slots_list != null:
		_style_load_slots_item_list()

	if load_slots_delete_button != null:
		_style_dialog_action_button(load_slots_delete_button, "danger")
	if load_slots_cancel_button != null:
		_style_dialog_action_button(load_slots_cancel_button, "secondary")
	if load_slots_load_button != null:
		_style_dialog_action_button(load_slots_load_button, "primary")
	if load_slot_delete_dialog != null:
		_style_dialog_action_button(load_slot_delete_dialog.get_ok_button(), "danger")
		_style_dialog_action_button(load_slot_delete_dialog.get_cancel_button(), "secondary")


func _style_difficulty_card_button(button: Button) -> void:
	if button == null:
		return
	UiTheme.style_button(button, "desktop_card_selectable", {"selected": button.button_pressed})
	var selected: bool = button.button_pressed
	var banner: PanelContainer = button.find_child("DifficultyCardBanner", true, false) as PanelContainer
	if banner != null:
		UiTheme.style_panel(banner, "desktop_card_banner", {"selected": selected})
	var title_label: Label = button.find_child("DifficultyCardTitle", true, false) as Label
	if title_label != null:
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_override("font", UiTheme.font("bold"))
		title_label.add_theme_font_size_override("font_size", UiTheme.font_size("title") + 2)
		title_label.add_theme_color_override("font_color", UiTheme.color("desktop.cream") if selected else UiTheme.color("desktop.brown"))
	var metrics_vbox: VBoxContainer = button.find_child("DifficultyCardMetrics", true, false) as VBoxContainer
	if metrics_vbox == null:
		return
	for row_node: Node in metrics_vbox.get_children():
		if not row_node is HBoxContainer:
			continue
		var row: HBoxContainer = row_node
		var metric_label: Label = row.find_child("MetricLabel", false, false) as Label
		var metric_value: Label = row.find_child("MetricValue", false, false) as Label
		if metric_label != null:
			metric_label.add_theme_font_override("font", UiTheme.font("semibold"))
			metric_label.add_theme_font_size_override("font_size", UiTheme.font_size("body"))
			metric_label.add_theme_color_override("font_color", UiTheme.color("desktop.cream") if selected else UiTheme.color("desktop.muted"))
		if metric_value != null:
			metric_value.add_theme_font_override("font", UiTheme.font("semibold"))
			metric_value.add_theme_font_size_override("font_size", UiTheme.font_size("body"))
			metric_value.add_theme_color_override("font_color", UiTheme.color("desktop.cream") if selected else UiTheme.color("desktop.text"))


func _style_title_label(label: Label) -> void:
	if label == null:
		return
	UiTheme.style_label(label, "desktop_title")


func _style_body_label(label: Label) -> void:
	if label == null:
		return
	UiTheme.style_label(label, "desktop_body")


func _style_progress_bar(progress_bar: ProgressBar) -> void:
	if progress_bar == null:
		return
	UiTheme.style_progress_bar(progress_bar, "desktop")


func _style_checkbox(checkbox: CheckBox) -> void:
	if checkbox == null:
		return
	UiTheme.style_checkbox(checkbox, "desktop")


func _apply_global_font_size_overrides() -> void:
	UiTheme.apply_tree_font(self, "body")


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
