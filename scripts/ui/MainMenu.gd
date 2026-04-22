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

var difficulty_button_group := ButtonGroup.new()
var difficulty_card_buttons: Dictionary = {}
var selected_difficulty_id := ""


func _ready() -> void:
	$Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/ActionCard/ActionMargin/ActionVBox/ButtonColumn/NewGameButton.pressed.connect(_on_new_game_pressed)
	load_button.pressed.connect(_on_load_pressed)
	$Margin/ScreenRoot/HomeScreen/CenterContent/MainRow/ActionCard/ActionMargin/ActionVBox/ButtonColumn/QuitButton.pressed.connect(_on_quit_pressed)
	$Margin/ScreenRoot/DifficultyScreen/CenterContent/SelectorCard/SelectorMargin/SelectorVBox/FooterRow/BackButton.pressed.connect(_on_back_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	GameManager.run_loading_started.connect(_on_run_loading_started)
	GameManager.run_loading_progress.connect(_on_run_loading_progress)
	GameManager.run_loading_finished.connect(_on_run_loading_finished)
	get_viewport().size_changed.connect(_update_difficulty_selector_size)
	_populate_difficulty_cards()
	tutorial_checkbox.button_pressed = true
	_refresh_load_state()
	_set_screen(SCREEN_HOME)
	_clear_selected_difficulty()
	_apply_global_font_size_overrides()
	_update_difficulty_selector_size()


func _refresh_load_state() -> void:
	load_button.disabled = not SaveManager.has_save()
	if SaveManager.has_save():
		status_label.text = "A previous run is available. Load it now or start a fresh market from the difficulty selector."
	else:
		status_label.text = "No saved run yet. Start a new game to choose a market difficulty and build the first watchlist."


func _on_new_game_pressed() -> void:
	_clear_selected_difficulty()
	_set_screen(SCREEN_DIFFICULTY)


func _on_load_pressed() -> void:
	if not SaveManager.has_save():
		status_label.text = "No save file was found, so a fresh run is safer."
		_refresh_load_state()
		return

	_prepare_load_screen()
	_set_screen(SCREEN_LOADING)
	var load_succeeded: bool = await GameManager.load_run_from_save_with_loading()
	if not is_inside_tree():
		return
	if not load_succeeded:
		_set_screen(SCREEN_HOME)
		status_label.text = "No save file was found, so a fresh run is safer."
		_refresh_load_state()


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
	loading_body_label.text = "Building %d procedural companies, their financial profiles, and the opening market state." % int(difficulty_config.get("company_count", 0))
	loading_step_label.text = "Step 1/%d" % max(GameManager.NEW_RUN_LOADING_STEPS.size(), 1)
	loading_progress_bar.value = 0.0


func _prepare_load_screen() -> void:
	loading_title_label.text = "Loading saved run"
	loading_stage_label.text = "Reading save file"
	loading_body_label.text = "Restoring the saved market state, portfolio, watchlist, and current trading day."
	loading_step_label.text = "Step 1/%d" % max(GameManager.LOAD_RUN_LOADING_STEPS.size(), 1)
	loading_progress_bar.value = 0.0


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


func _loading_body_for_stage(stage_id: String) -> String:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(selected_difficulty_id)
	var company_count: int = int(difficulty_config.get("company_count", 0))
	match stage_id:
		"load_save":
			return "Reading the saved market state from disk so the roster, prices, and event history can be restored."
		"restore_state":
			return "Restoring the portfolio, watchlist, calendar day, and generated company data from the save file."
		"load_launch":
			return "Opening the trading desk and handing control back to the saved run."
		"seed":
			return "Locking the run seed, trade calendar, and bankroll rules before generation starts."
		"companies":
			return "Creating %d company identities with randomized names, tickers, sectors, and exchange boards." % company_count
		"financials":
			return "Creating company financials, ten-year histories, quality scores, and opening prices for the new roster."
		"opening_day":
			return "Simulating the first trading session so the market opens with live price changes instead of flat starting quotes."
		"save":
			return "Saving the freshly generated run so the roster survives reloads."
		"launch":
			return "Opening the market desk and handing control to the player."
		_:
			return "Preparing the next market screen."


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
