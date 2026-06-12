extends RefCounted

const UI_THEME := preload("res://scripts/ui/UITheme.gd")

const COLOR_POSITIVE := UI_THEME.COLOR_POSITIVE
const COLOR_NEGATIVE := UI_THEME.COLOR_NEGATIVE
const COLOR_DESKTOP_TEXT := UI_THEME.COLOR_DESKTOP_TEXT
const COLOR_WINDOW_TEXT := UI_THEME.COLOR_WINDOW_TEXT
const COLOR_ACADEMY_CREAM := UI_THEME.COLOR_ACADEMY_CREAM
const COLOR_ACADEMY_RAIL := UI_THEME.COLOR_ACADEMY_RAIL
const COLOR_ACADEMY_BROWN := UI_THEME.COLOR_ACADEMY_BROWN
const COLOR_ACADEMY_BORDER := UI_THEME.COLOR_ACADEMY_BORDER
const COLOR_ACADEMY_GREEN := UI_THEME.COLOR_ACADEMY_GREEN
const SHOW_ACADEMY_IMAGE_PLACEHOLDERS := false

var _root = null
var current_academy_snapshot: Dictionary = {}
var selected_academy_category_id: String = "mindset"
var selected_academy_section_id: String = "survival_mindset"
var academy_quiz_option_buttons: Dictionary = {}
var academy_app_button: Button = null
var academy_app_label: Label = null
var academy_window: MarginContainer = null
var academy_window_body: PanelContainer = null
var academy_title_label: Label = null
var academy_progress_label: Label = null
var academy_category_tabs: HBoxContainer = null
var academy_section_tabs: GridContainer = null
var academy_summary_label: Label = null
var academy_section_list: ItemList = null
var academy_selection_chip_label: Label = null
var academy_lesson_title_label: Label = null
var academy_lesson_meta_label: Label = null
var academy_lesson_banner_frame: PanelContainer = null
var academy_lesson_banner_label: Label = null
var academy_lesson_scroll: ScrollContainer = null
var academy_lesson_content_vbox: VBoxContainer = null
var academy_action_row: HBoxContainer = null
var academy_mark_read_button: Button = null
var academy_next_button: Button = null
var academy_side_title_label: Label = null
var academy_side_body_label: Label = null
var academy_glossary_search_input: LineEdit = null
var academy_glossary_list: ItemList = null


func setup(root) -> void:
	_root = root
	if _root == null:
		return
	selected_academy_category_id = str(_root.get("selected_academy_category_id"))
	selected_academy_section_id = str(_root.get("selected_academy_section_id"))
	current_academy_snapshot = _root.get("current_academy_snapshot") as Dictionary
	academy_quiz_option_buttons = _root.get("academy_quiz_option_buttons") as Dictionary
	_sync_root_state()


func ensure_ui() -> void:
	if academy_window != null:
		return

	var desktop_icons_row: HBoxContainer = _root.get_node("DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow") as HBoxContainer
	var academy_tile := VBoxContainer.new()
	academy_tile.name = "AcademyAppTile"
	academy_tile.add_theme_constant_override("separation", 10)
	desktop_icons_row.add_child(academy_tile)
	var upgrades_tile: Node = desktop_icons_row.get_node_or_null("UpgradesAppTile")
	if upgrades_tile != null:
		desktop_icons_row.move_child(academy_tile, upgrades_tile.get_index())

	academy_app_button = Button.new()
	academy_app_button.name = "AcademyAppButton"
	academy_app_button.custom_minimum_size = Vector2(92, 92)
	academy_app_button.toggle_mode = true
	academy_tile.add_child(academy_app_button)

	academy_app_label = Label.new()
	academy_app_label.name = "AcademyAppLabel"
	academy_app_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	academy_app_label.text = "Academy"
	academy_app_label.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)
	academy_tile.add_child(academy_app_label)

	academy_window = MarginContainer.new()
	academy_window.name = "AcademyWindow"
	academy_window.visible = false
	academy_window.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(academy_window)
	var upgrade_window_node: Node = _root.get_node_or_null("UpgradeWindow")
	if upgrade_window_node != null:
		_root.move_child(academy_window, upgrade_window_node.get_index())

	academy_window_body = PanelContainer.new()
	academy_window_body.name = "AcademyWindowBody"
	academy_window_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	academy_window_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	academy_window.add_child(academy_window_body)

	var academy_margin := MarginContainer.new()
	academy_margin.name = "AcademyWindowMargin"
	academy_margin.add_theme_constant_override("margin_left", 14)
	academy_margin.add_theme_constant_override("margin_top", 14)
	academy_margin.add_theme_constant_override("margin_right", 14)
	academy_margin.add_theme_constant_override("margin_bottom", 14)
	academy_window_body.add_child(academy_margin)

	var academy_vbox := VBoxContainer.new()
	academy_vbox.name = "AcademyWindowVBox"
	academy_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	academy_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	academy_vbox.add_theme_constant_override("separation", 12)
	academy_margin.add_child(academy_vbox)

	var header_row := HBoxContainer.new()
	header_row.name = "AcademyHeaderRow"
	header_row.visible = false
	header_row.add_theme_constant_override("separation", 12)
	academy_vbox.add_child(header_row)

	academy_title_label = Label.new()
	academy_title_label.name = "AcademyTitleLabel"
	academy_title_label.text = "Academy"
	academy_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(academy_title_label)

	academy_progress_label = Label.new()
	academy_progress_label.name = "AcademyProgressLabel"
	academy_progress_label.text = ""
	header_row.add_child(academy_progress_label)

	academy_category_tabs = HBoxContainer.new()
	academy_category_tabs.name = "AcademyCategoryTabs"
	academy_category_tabs.add_theme_constant_override("separation", 12)
	academy_category_tabs.custom_minimum_size = Vector2(0, 38)
	academy_vbox.add_child(academy_category_tabs)

	academy_section_tabs = GridContainer.new()
	academy_section_tabs.name = "AcademySectionTabs"
	academy_section_tabs.visible = false
	academy_section_tabs.columns = 4
	academy_section_tabs.add_theme_constant_override("h_separation", 12)
	academy_section_tabs.add_theme_constant_override("v_separation", 12)
	academy_vbox.add_child(academy_section_tabs)

	academy_summary_label = Label.new()
	academy_summary_label.name = "AcademySummaryLabel"
	academy_summary_label.visible = false
	academy_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	academy_vbox.add_child(academy_summary_label)

	var content_split := HSplitContainer.new()
	content_split.name = "AcademyContentSplit"
	content_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_split.split_offset = 242
	academy_vbox.add_child(content_split)

	var list_panel := PanelContainer.new()
	list_panel.name = "AcademySectionListPanel"
	list_panel.visible = true
	list_panel.custom_minimum_size = Vector2(240, 0)
	content_split.add_child(list_panel)
	_style_panel(list_panel, COLOR_ACADEMY_RAIL, 0)
	var list_margin := MarginContainer.new()
	list_margin.add_theme_constant_override("margin_left", 0)
	list_margin.add_theme_constant_override("margin_top", 12)
	list_margin.add_theme_constant_override("margin_right", 0)
	list_margin.add_theme_constant_override("margin_bottom", 12)
	list_panel.add_child(list_margin)
	var list_vbox := VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 10)
	list_margin.add_child(list_vbox)
	var list_title := Label.new()
	list_title.name = "AcademyCoreModulesLabel"
	list_title.text = "CORE MODULES"
	list_title.add_theme_font_size_override("font_size", 11)
	list_title.add_theme_constant_override("line_spacing", 0)
	var list_title_margin := MarginContainer.new()
	list_title_margin.add_theme_constant_override("margin_left", 14)
	list_title_margin.add_theme_constant_override("margin_right", 14)
	list_title_margin.add_child(list_title)
	list_vbox.add_child(list_title_margin)
	academy_section_list = ItemList.new()
	academy_section_list.name = "AcademySectionList"
	academy_section_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	academy_section_list.fixed_column_width = 0
	academy_section_list.same_column_width = false
	academy_section_list.max_text_lines = 2
	var list_inner_margin := MarginContainer.new()
	list_inner_margin.add_theme_constant_override("margin_left", 12)
	list_inner_margin.add_theme_constant_override("margin_right", 12)
	list_inner_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_inner_margin.add_child(academy_section_list)
	list_vbox.add_child(list_inner_margin)

	var lesson_panel := PanelContainer.new()
	lesson_panel.name = "AcademyLessonPanel"
	lesson_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_split.add_child(lesson_panel)
	_style_panel(lesson_panel, COLOR_ACADEMY_CREAM, 0)
	var lesson_margin := MarginContainer.new()
	lesson_margin.add_theme_constant_override("margin_left", 26)
	lesson_margin.add_theme_constant_override("margin_top", 24)
	lesson_margin.add_theme_constant_override("margin_right", 26)
	lesson_margin.add_theme_constant_override("margin_bottom", 16)
	lesson_panel.add_child(lesson_margin)
	var lesson_vbox := VBoxContainer.new()
	lesson_vbox.add_theme_constant_override("separation", 12)
	lesson_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lesson_margin.add_child(lesson_vbox)
	academy_lesson_scroll = ScrollContainer.new()
	academy_lesson_scroll.name = "AcademyLessonScroll"
	academy_lesson_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	academy_lesson_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lesson_vbox.add_child(academy_lesson_scroll)
	var lesson_scroll_vbox := VBoxContainer.new()
	lesson_scroll_vbox.name = "AcademyLessonScrollVBox"
	lesson_scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson_scroll_vbox.add_theme_constant_override("separation", 12)
	academy_lesson_scroll.add_child(lesson_scroll_vbox)
	academy_selection_chip_label = Label.new()
	academy_selection_chip_label.name = "AcademySelectionChipLabel"
	academy_selection_chip_label.text = "CURRENT SELECTION"
	academy_selection_chip_label.add_theme_font_size_override("font_size", 10)
	academy_selection_chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	academy_selection_chip_label.custom_minimum_size = Vector2(150, 20)
	lesson_scroll_vbox.add_child(academy_selection_chip_label)
	academy_lesson_title_label = Label.new()
	academy_lesson_title_label.name = "AcademyLessonTitleLabel"
	academy_lesson_title_label.visible = true
	academy_lesson_title_label.add_theme_font_size_override("font_size", 30)
	academy_lesson_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lesson_scroll_vbox.add_child(academy_lesson_title_label)
	academy_lesson_meta_label = Label.new()
	academy_lesson_meta_label.name = "AcademyLessonMetaLabel"
	academy_lesson_meta_label.visible = true
	academy_lesson_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lesson_scroll_vbox.add_child(academy_lesson_meta_label)
	academy_lesson_banner_frame = PanelContainer.new()
	academy_lesson_banner_frame.name = "AcademyLessonBannerFrame"
	academy_lesson_banner_frame.custom_minimum_size = Vector2(0, 150)
	academy_lesson_banner_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	academy_lesson_banner_frame.visible = SHOW_ACADEMY_IMAGE_PLACEHOLDERS
	lesson_scroll_vbox.add_child(academy_lesson_banner_frame)
	_style_academy_banner_frame(academy_lesson_banner_frame)
	var banner_center := CenterContainer.new()
	academy_lesson_banner_frame.add_child(banner_center)
	academy_lesson_banner_label = Label.new()
	academy_lesson_banner_label.name = "AcademyLessonBannerLabel"
	academy_lesson_banner_label.text = "CHART MODULE"
	academy_lesson_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	academy_lesson_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	academy_lesson_banner_label.add_theme_font_size_override("font_size", 16)
	banner_center.add_child(academy_lesson_banner_label)
	academy_lesson_content_vbox = VBoxContainer.new()
	academy_lesson_content_vbox.name = "AcademyLessonContentVBox"
	academy_lesson_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	academy_lesson_content_vbox.add_theme_constant_override("separation", 10)
	lesson_scroll_vbox.add_child(academy_lesson_content_vbox)
	academy_action_row = HBoxContainer.new()
	academy_action_row.name = "AcademyActionRow"
	academy_action_row.add_theme_constant_override("separation", 10)
	lesson_vbox.add_child(academy_action_row)
	academy_mark_read_button = Button.new()
	academy_mark_read_button.name = "AcademyMarkReadButton"
	academy_mark_read_button.text = "MARK AS COMPLETE"
	academy_mark_read_button.custom_minimum_size = Vector2(170, 44)
	academy_action_row.add_child(academy_mark_read_button)
	academy_next_button = Button.new()
	academy_next_button.name = "AcademyNextButton"
	academy_next_button.text = "Next Section"
	academy_next_button.custom_minimum_size = Vector2(130, 44)
	academy_action_row.add_child(academy_next_button)

	var side_panel := PanelContainer.new()
	side_panel.name = "AcademySidePanel"
	side_panel.visible = false
	side_panel.custom_minimum_size = Vector2(260, 0)
	content_split.add_child(side_panel)
	_style_panel(side_panel, Color(0.952941, 0.94902, 0.87451, 1), 0)
	var side_margin := MarginContainer.new()
	side_margin.add_theme_constant_override("margin_left", 10)
	side_margin.add_theme_constant_override("margin_top", 10)
	side_margin.add_theme_constant_override("margin_right", 10)
	side_margin.add_theme_constant_override("margin_bottom", 10)
	side_panel.add_child(side_margin)
	var side_vbox := VBoxContainer.new()
	side_vbox.add_theme_constant_override("separation", 8)
	side_margin.add_child(side_vbox)
	academy_side_title_label = Label.new()
	academy_side_title_label.name = "AcademySideTitleLabel"
	side_vbox.add_child(academy_side_title_label)
	academy_side_body_label = Label.new()
	academy_side_body_label.name = "AcademySideBodyLabel"
	academy_side_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_vbox.add_child(academy_side_body_label)
	academy_glossary_search_input = LineEdit.new()
	academy_glossary_search_input.name = "AcademyGlossarySearchInput"
	academy_glossary_search_input.placeholder_text = "Search glossary"
	side_vbox.add_child(academy_glossary_search_input)
	academy_glossary_list = ItemList.new()
	academy_glossary_list.name = "AcademyGlossaryList"
	academy_glossary_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_vbox.add_child(academy_glossary_list)
	academy_section_list.item_selected.connect(on_section_selected)
	academy_mark_read_button.pressed.connect(on_mark_read_pressed)
	academy_next_button.pressed.connect(on_next_pressed)
	academy_glossary_search_input.text_changed.connect(on_glossary_search_changed)
	apply_text_theme()
	_style_academy_primary_button(academy_mark_read_button)
	_style_academy_primary_button(academy_next_button)
	_apply_academy_button_padding(academy_mark_read_button, 14)
	_apply_academy_button_padding(academy_next_button, 14)
	restyle_controls()
	_sync_root_refs()


func refresh() -> void:
	if academy_window == null:
		return
	current_academy_snapshot = {}
	academy_title_label.text = "Academy"
	if not RunState.has_active_run():
		academy_progress_label.text = "No run loaded"
		academy_summary_label.text = "Start a run to open Academy lessons."
		academy_section_list.clear()
		_clear_container_children(academy_category_tabs)
		_clear_container_children(academy_section_tabs)
		_clear_container_children(academy_lesson_content_vbox)
		if academy_selection_chip_label != null:
			academy_selection_chip_label.text = "NO RUN LOADED"
		if academy_lesson_banner_label != null:
			academy_lesson_banner_label.text = "ACADEMY"
		academy_lesson_title_label.text = "No lesson"
		academy_lesson_meta_label.text = ""
		academy_mark_read_button.disabled = true
		academy_next_button.disabled = true
		_apply_font_overrides_to_subtree(academy_window)
		restyle_controls()
		_sync_root_state()
		return

	current_academy_snapshot = GameManager.get_academy_snapshot(selected_academy_category_id, selected_academy_section_id)
	selected_academy_category_id = str(current_academy_snapshot.get("category_id", selected_academy_category_id))
	selected_academy_section_id = str(current_academy_snapshot.get("selected_section_id", selected_academy_section_id))
	_sync_root_state()
	academy_title_label.text = ""
	_rebuild_academy_category_tabs()
	_rebuild_academy_section_list()
	_rebuild_academy_section_tabs()
	_refresh_academy_content()
	apply_text_theme()
	_apply_font_overrides_to_subtree(academy_window)
	restyle_controls()
	_sync_root_state()


func apply_text_theme() -> void:
	if academy_window == null:
		return
	_apply_academy_text_theme_to_node(academy_window)


func _apply_academy_text_theme_to_node(node: Node) -> void:
	if node is Label:
		var label: Label = node
		label.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	elif node is RichTextLabel:
		var rich_text: RichTextLabel = node
		rich_text.add_theme_color_override("default_color", COLOR_WINDOW_TEXT)
	elif node is ItemList:
		var item_list: ItemList = node
		item_list.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
		item_list.add_theme_color_override("font_hovered_color", COLOR_WINDOW_TEXT)
		item_list.add_theme_color_override("font_selected_color", COLOR_WINDOW_TEXT)
	elif node is LineEdit:
		var line_edit: LineEdit = node
		line_edit.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
		line_edit.add_theme_color_override("font_placeholder_color", Color(0.352941, 0.309804, 0.203922, 0.78))
	elif node is OptionButton:
		var option_button: OptionButton = node
		option_button.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
		option_button.add_theme_color_override("font_hover_color", COLOR_WINDOW_TEXT)
		option_button.add_theme_color_override("font_pressed_color", COLOR_WINDOW_TEXT)
	elif node is Button:
		var button: Button = node
		button.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
		button.add_theme_color_override("font_hover_color", COLOR_WINDOW_TEXT)
		button.add_theme_color_override("font_pressed_color", COLOR_WINDOW_TEXT)
		button.add_theme_color_override("font_disabled_color", Color(0.352941, 0.309804, 0.203922, 0.62))

	for child in node.get_children():
		_apply_academy_text_theme_to_node(child)


func _rebuild_academy_category_tabs() -> void:
	_clear_container_children(academy_category_tabs)
	for category_value in current_academy_snapshot.get("categories", []):
		var category: Dictionary = category_value
		var button := Button.new()
		var category_id: String = str(category.get("id", ""))
		button.name = "AcademyCategoryButton_%s" % category_id
		button.text = str(category.get("label", category_id.capitalize())).to_upper()
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 36)
		button.set_pressed_no_signal(category_id == selected_academy_category_id)
		button.pressed.connect(on_category_pressed.bind(category_id))
		academy_category_tabs.add_child(button)
		_style_academy_category_tab(button, category_id == selected_academy_category_id)


func _style_academy_category_tab(button: Button, selected: bool) -> void:
	_style_news_tab_button(button, selected, true)


func _apply_academy_button_padding(button: Button, padding: int = 24) -> void:
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var current_style: StyleBox = button.get_theme_stylebox(style_name)
		if current_style == null or current_style is not StyleBoxFlat:
			continue
		var flat_style: StyleBoxFlat = current_style.duplicate()
		flat_style.content_margin_left = padding
		flat_style.content_margin_right = padding
		flat_style.content_margin_top = padding
		flat_style.content_margin_bottom = padding
		button.add_theme_stylebox_override(style_name, flat_style)


func _style_academy_primary_button(button: Button) -> void:
	if button == null:
		return
	UiTheme.style_button(button, "desktop_primary")


func _style_academy_selection_chip(label: Label) -> void:
	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = COLOR_ACADEMY_GREEN
	chip_style.border_color = COLOR_ACADEMY_GREEN.darkened(0.18)
	chip_style.set_border_width_all(0)
	chip_style.corner_radius_top_left = 0
	chip_style.corner_radius_top_right = 0
	chip_style.corner_radius_bottom_left = 0
	chip_style.corner_radius_bottom_right = 0
	chip_style.content_margin_left = 10
	chip_style.content_margin_right = 10
	chip_style.content_margin_top = 4
	chip_style.content_margin_bottom = 4
	label.add_theme_stylebox_override("normal", chip_style)
	label.add_theme_color_override("font_color", Color(0.247059, 0.278431, 0.117647, 1))


func _style_academy_banner_frame(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.196078, 0.156863, 0.92)
	style.border_color = Color(0.12549, 0.113725, 0.0823529, 1)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)


func _style_academy_content_block(panel: PanelContainer, fill_color: Color, border_left: int = 1) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = COLOR_ACADEMY_BORDER
	style.border_width_left = border_left
	style.border_width_top = 0 if border_left > 1 else 1
	style.border_width_right = 0 if border_left > 1 else 1
	style.border_width_bottom = 0 if border_left > 1 else 1
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)


func _style_academy_text_card(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_ACADEMY_CREAM
	style.border_color = Color(0.658824, 0.533333, 0.278431, 0.92)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)


func _style_academy_infobox_card(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.945098, 0.894118, 0.705882, 1)
	style.border_color = Color(0.658824, 0.533333, 0.278431, 0.95)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)


func _style_academy_table_card(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.968627, 0.92549, 0.760784, 1)
	style.border_color = Color(0.607843, 0.470588, 0.219608, 0.95)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)


func _style_academy_key_insights_card(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.835294, 0.898039, 0.968627, 1)
	style.border_color = Color(0.133333, 0.376471, 0.694118, 1)
	style.border_width_left = 5
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)


func _style_academy_quick_check_button(button: Button) -> void:
	_style_button(button, Color(0.945098, 0.894118, 0.705882, 1), COLOR_ACADEMY_BORDER, COLOR_WINDOW_TEXT, 0)
	_apply_academy_button_padding(button, 10)
	button.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_WINDOW_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_WINDOW_TEXT)
	button.add_theme_color_override("font_focus_color", COLOR_WINDOW_TEXT)


func _style_academy_quiz_option_button(option_button: OptionButton) -> void:
	_style_button(
		option_button,
		Color(0.980392, 0.952941, 0.807843, 1),
		Color(0.552941, 0.411765, 0.164706, 1),
		COLOR_WINDOW_TEXT,
		0
	)
	_apply_academy_button_padding(option_button, 12)
	option_button.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	option_button.add_theme_color_override("font_hover_color", COLOR_WINDOW_TEXT)
	option_button.add_theme_color_override("font_pressed_color", COLOR_WINDOW_TEXT)
	option_button.add_theme_color_override("font_focus_color", COLOR_WINDOW_TEXT)
	option_button.add_theme_color_override("font_disabled_color", Color(0.352941, 0.309804, 0.203922, 0.78))
	var popup: PopupMenu = option_button.get_popup()
	if popup == null:
		return
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.992157, 0.976471, 0.894118, 1)
	panel_style.border_color = COLOR_ACADEMY_BORDER
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 0
	panel_style.corner_radius_bottom_left = 0
	panel_style.corner_radius_bottom_right = 0
	popup.add_theme_stylebox_override("panel", panel_style)
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.894118, 0.807843, 0.560784, 1)
	hover_style.border_color = Color(0.709804, 0.607843, 0.345098, 1)
	hover_style.set_border_width_all(0)
	popup.add_theme_stylebox_override("hover", hover_style)
	popup.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	popup.add_theme_color_override("font_hover_color", COLOR_WINDOW_TEXT)
	popup.add_theme_color_override("font_accelerator_color", COLOR_WINDOW_TEXT)
	popup.add_theme_color_override("font_disabled_color", Color(0.352941, 0.309804, 0.203922, 0.62))


func _style_academy_quiz_submit_button(button: Button) -> void:
	_style_button(button, COLOR_ACADEMY_BROWN, COLOR_ACADEMY_BORDER, COLOR_ACADEMY_CREAM, 0)
	_apply_academy_button_padding(button, 18)
	button.add_theme_color_override("font_color", COLOR_ACADEMY_CREAM)
	button.add_theme_color_override("font_hover_color", COLOR_ACADEMY_CREAM)
	button.add_theme_color_override("font_pressed_color", COLOR_ACADEMY_CREAM)
	button.add_theme_color_override("font_focus_color", COLOR_ACADEMY_CREAM)


func restyle_controls() -> void:
	if academy_window_body != null:
		_style_panel(academy_window_body, COLOR_ACADEMY_CREAM, 0, 0, 0, 0, 0)
	if academy_section_list != null:
		_style_light_item_list(academy_section_list)
	if academy_glossary_list != null:
		_style_light_item_list(academy_glossary_list)
	if academy_category_tabs != null:
		for child in academy_category_tabs.get_children():
			var tab_button: Button = child as Button
			if tab_button == null:
				continue
			var tab_id: String = tab_button.name.trim_prefix("AcademyCategoryButton_")
			_style_academy_category_tab(tab_button, tab_id == selected_academy_category_id)
	if academy_section_tabs != null:
		for child in academy_section_tabs.get_children():
			var section_tab_button: Button = child as Button
			if section_tab_button == null:
				continue
			var section_tab_id: String = section_tab_button.name.trim_prefix("AcademySectionTab_")
			_style_academy_section_tab(section_tab_button, section_tab_id == selected_academy_section_id, section_tab_button.disabled)
	if academy_selection_chip_label != null:
		_style_academy_selection_chip(academy_selection_chip_label)
		academy_selection_chip_label.add_theme_font_size_override("font_size", 10)
	if academy_lesson_title_label != null:
		academy_lesson_title_label.add_theme_color_override("font_color", COLOR_ACADEMY_BROWN)
		academy_lesson_title_label.add_theme_font_size_override("font_size", 30)
	if academy_lesson_meta_label != null:
		academy_lesson_meta_label.add_theme_color_override("font_color", Color(0.25098, 0.223529, 0.156863, 1))
		academy_lesson_meta_label.add_theme_font_size_override("font_size", 14)
	if academy_lesson_banner_frame != null:
		_style_academy_banner_frame(academy_lesson_banner_frame)
	if academy_lesson_banner_label != null:
		academy_lesson_banner_label.add_theme_color_override("font_color", Color(0.898039, 0.870588, 0.745098, 1))
		academy_lesson_banner_label.add_theme_font_size_override("font_size", 16)
	if academy_mark_read_button != null:
		_style_academy_primary_button(academy_mark_read_button)
		_apply_academy_button_padding(academy_mark_read_button, 14)
	if academy_next_button != null:
		_style_academy_primary_button(academy_next_button)
		_apply_academy_button_padding(academy_next_button, 14)
	if academy_lesson_content_vbox != null:
		_restyle_academy_content_nodes(academy_lesson_content_vbox)


func _restyle_academy_content_nodes(node: Node) -> void:
	if node.name == "AcademyTextBlockTitle" and node is Label:
		var label: Label = node
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(0.129412, 0.101961, 0.058824, 1))
	if node.name == "AcademyKeyInsightsTitle" and node is Label:
		var insights_label: Label = node
		insights_label.add_theme_font_size_override("font_size", 16)
		insights_label.add_theme_color_override("font_color", Color(0.054902, 0.164706, 0.313726, 1))
	if node.name == "AcademyQuickCheckOptionButton" and node is Button:
		_style_academy_quick_check_button(node as Button)
	if String(node.name).begins_with("AcademyQuizOption_") and node is OptionButton:
		_style_academy_quiz_option_button(node as OptionButton)
	if node.name == "AcademyQuizSubmitButton" and node is Button:
		_style_academy_quiz_submit_button(node as Button)
	for child in node.get_children():
		_restyle_academy_content_nodes(child)


func _rebuild_academy_section_list() -> void:
	academy_section_list.clear()
	var sections: Array = current_academy_snapshot.get("sections", [])
	for index in range(sections.size()):
		var section: Dictionary = sections[index]
		var section_id: String = str(section.get("id", ""))
		var order: int = int(section.get("order", index + 1))
		var title: String = str(section.get("title", section.get("label", "Section")))
		var status_label: String = _academy_module_status_label(section)
		var label: String = "%d    %s\n     %s" % [order, title, status_label]
		academy_section_list.add_item(label)
		academy_section_list.set_item_metadata(index, section.duplicate(true))
		academy_section_list.set_item_disabled(index, bool(section.get("locked", false)))
		academy_section_list.set_item_custom_fg_color(index, COLOR_WINDOW_TEXT if not bool(section.get("locked", false)) else Color(0.329412, 0.313725, 0.266667, 0.78))
		academy_section_list.set_item_custom_bg_color(index, _academy_module_row_color(section, section_id == selected_academy_section_id))
		if section_id == selected_academy_section_id:
			academy_section_list.select(index)


func _academy_module_status_label(section: Dictionary) -> String:
	var kind: String = str(section.get("kind", "lesson"))
	if kind == "quiz":
		return "Quiz locked" if bool(section.get("locked", false)) else "Quiz"
	if kind == "glossary":
		return "Glossary"
	if bool(section.get("read", false)):
		return "Completed"
	return "Not learned"


func _academy_module_row_color(section: Dictionary, selected: bool) -> Color:
	if selected:
		return Color(0.87451, 0.831373, 0.666667, 1)
	if bool(section.get("read", false)):
		return Color(0.917647, 0.933333, 0.741176, 1)
	if bool(section.get("locked", false)):
		return Color(0.839216, 0.815686, 0.72549, 0.45)
	return Color(0.968627, 0.941176, 0.815686, 0.62)


func _rebuild_academy_section_tabs() -> void:
	_clear_container_children(academy_section_tabs)
	var sections: Array = current_academy_snapshot.get("sections", [])
	for section_value in sections:
		var section: Dictionary = section_value
		var section_id: String = str(section.get("id", ""))
		var selected: bool = section_id == selected_academy_section_id
		var button := Button.new()
		button.name = "AcademySectionTab_%s" % section_id
		button.custom_minimum_size = Vector2(220, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.text = _academy_section_tab_label(section, selected)
		button.disabled = bool(section.get("locked", false))
		button.set_pressed_no_signal(selected)
		button.pressed.connect(on_section_tab_pressed.bind(section_id))
		academy_section_tabs.add_child(button)
		_style_academy_section_tab(button, selected, bool(section.get("locked", false)))


func _academy_section_tab_label(section: Dictionary, selected: bool = false) -> String:
	var label: String = str(section.get("label", "Section"))
	var title: String = str(section.get("title", ""))
	var order: int = int(section.get("order", 0))
	var prefix: String = "%02d / 08 " % order if selected and order > 0 else ""
	if label.begins_with("01"):
		return "%s01 Getting to Know TA" % prefix
	if label.begins_with("02"):
		return "%s02 Market Structure" % prefix
	if label.begins_with("03"):
		return "%s03 Candlesticks" % prefix
	if label.begins_with("04"):
		return "%s04 Patterns" % prefix
	if label.begins_with("05"):
		return "%s05 Moving Average" % prefix
	if label.begins_with("06"):
		return "%s06 Framework" % prefix
	if label.begins_with("07"):
		return "%s07 Quiz" % prefix if not bool(section.get("locked", false)) else "%s07 Quiz locked" % prefix
	if label.begins_with("08"):
		return "%s08 Glossary" % prefix
	return "%s%s" % [prefix, title if not title.is_empty() else label]


func _style_academy_section_tab(button: Button, selected: bool, locked: bool) -> void:
	_style_news_tab_button(button, selected, not locked)


func _refresh_academy_content() -> void:
	var progress: Dictionary = current_academy_snapshot.get("progress", {})
	var quiz: Dictionary = current_academy_snapshot.get("quiz", {})
	academy_progress_label.text = "%d/%d sections read  |  Quiz %s  |  Best %d%%" % [
		int(progress.get("read_count", 0)),
		int(progress.get("readable_count", 0)),
		"passed" if bool(quiz.get("passed", false)) else ("locked" if bool(quiz.get("locked", true)) else "open"),
		int(quiz.get("best_score_percent", 0))
	]
	_clear_container_children(academy_lesson_content_vbox)
	academy_quiz_option_buttons.clear()

	if bool(current_academy_snapshot.get("coming_soon", false)):
		academy_summary_label.text = str(current_academy_snapshot.get("category_label", "Academy")).to_upper()
		if academy_selection_chip_label != null:
			academy_selection_chip_label.text = "TRACK PREVIEW"
		academy_lesson_title_label.text = str(current_academy_snapshot.get("category_label", "Academy"))
		academy_lesson_meta_label.text = str(current_academy_snapshot.get("coming_soon_copy", "Coming soon."))
		if academy_lesson_banner_label != null:
			academy_lesson_banner_label.text = "COMING SOON"
		academy_mark_read_button.visible = false
		academy_next_button.visible = false
		_refresh_academy_side_panel()
		return

	var section: Dictionary = current_academy_snapshot.get("selected_section", {})
	if section.is_empty():
		academy_summary_label.text = ""
		if academy_selection_chip_label != null:
			academy_selection_chip_label.text = "CHOOSE MODULE"
		academy_lesson_title_label.text = "Choose a section"
		academy_lesson_meta_label.text = ""
		if academy_lesson_banner_label != null:
			academy_lesson_banner_label.text = "ACADEMY"
		academy_mark_read_button.visible = false
		academy_next_button.visible = false
		_refresh_academy_side_panel()
		return

	var kind: String = str(section.get("kind", "lesson"))
	academy_summary_label.text = str(section.get("label", "")).to_upper()
	if academy_selection_chip_label != null:
		academy_selection_chip_label.text = _academy_selection_chip_text(section)
	academy_lesson_title_label.text = str(section.get("title", section.get("label", "Lesson")))
	academy_lesson_meta_label.text = _academy_lesson_deck(section)
	if academy_lesson_banner_label != null:
		academy_lesson_banner_label.text = _academy_banner_label_for_section(section)
	if kind == "quiz":
		_build_academy_quiz(section)
	elif kind == "glossary":
		_build_academy_glossary_section()
	else:
		_build_academy_lesson(section)

	academy_mark_read_button.visible = kind == "lesson"
	academy_mark_read_button.disabled = bool(section.get("read", false))
	academy_mark_read_button.text = "COMPLETED" if bool(section.get("read", false)) else "MARK AS COMPLETE"
	academy_next_button.visible = true
	academy_next_button.disabled = next_section_id().is_empty()
	_refresh_academy_side_panel()


func _academy_selection_chip_text(section: Dictionary) -> String:
	var kind: String = str(section.get("kind", "lesson"))
	if kind == "quiz":
		return "CURRENT SELECTION: QUIZ"
	if kind == "glossary":
		return "CURRENT SELECTION: GLOSSARY"
	var order: int = int(section.get("order", 0))
	return "CURRENT SELECTION: MODULE %d" % max(order, 1)


func _academy_lesson_deck(section: Dictionary) -> String:
	var kind: String = str(section.get("kind", "lesson"))
	if kind == "quiz":
		return "Score 80 percent or better to earn %s." % _academy_current_badge_label()
	if kind == "glossary":
		return "Search the core vocabulary used across the %s track." % _academy_current_category_label()
	var completion_signal_text: String = str(section.get("completion_signal", "")).strip_edges()
	if not completion_signal_text.is_empty():
		var softened_signal: String = completion_signal_text.substr(0, 1).to_lower() + completion_signal_text.substr(1)
		return "In this chapter, %s" % softened_signal
	return "In this chapter, build one repeatable market-reading habit."


func _academy_current_badge_label() -> String:
	var badge: Dictionary = current_academy_snapshot.get("badge", {})
	return str(badge.get("label", "the module badge"))


func _academy_current_category_label() -> String:
	return str(current_academy_snapshot.get("category_label", "Academy"))


func _academy_banner_label_for_section(section: Dictionary) -> String:
	var kind: String = str(section.get("kind", "lesson"))
	if kind == "quiz":
		return "QUIZ BOARD"
	if kind == "glossary":
		return "GLOSSARY"
	var section_id: String = str(section.get("id", ""))
	match section_id:
		"market_structure":
			return "MARKET STRUCTURE"
		"candlesticks":
			return "CANDLE STUDY"
		"patterns":
			return "PATTERN BOARD"
		"moving_average":
			return "TREND MODULE"
		"thinking_framework":
			return "ROUTINE BOARD"
		_:
			return "CHART MODULE"


func _build_academy_lesson(section: Dictionary) -> void:
	var content_blocks: Array = section.get("content_blocks", [])
	if not content_blocks.is_empty():
		for block_value in content_blocks:
			var block: Dictionary = block_value
			academy_lesson_content_vbox.add_child(_build_academy_content_block(block))
	else:
		var paragraphs: Array = []
		for page_value in section.get("pages", []):
			var page: Dictionary = page_value
			var body: String = str(page.get("body", "")).strip_edges()
			if not body.is_empty():
				paragraphs.append(body)
		if not paragraphs.is_empty():
			academy_lesson_content_vbox.add_child(_build_academy_text_block(
				_academy_lesson_card_title(section),
				"\n\n".join(paragraphs)
			))

	var stored_checks: Dictionary = RunState.get_academy_progress().get("inline_checks", {}).get(selected_academy_category_id, {}).get(str(section.get("id", "")), {})
	for check_value in section.get("checks", []):
		var check: Dictionary = check_value
		academy_lesson_content_vbox.add_child(_build_academy_check_block(str(section.get("id", "")), check, stored_checks.get(str(check.get("id", "")), {})))


func _build_academy_content_block(block: Dictionary) -> Control:
	var block_type: String = str(block.get("type", "text"))
	if block_type == "image":
		return _build_academy_image_block(
			str(block.get("asset_path", "")),
			str(block.get("caption", "")),
			str(block.get("alt", "Academy image"))
		)
	if block_type == "key_insights":
		return _build_academy_key_insights_block(
			str(block.get("title", "Key Insights")),
			block.get("bullets", [])
		)
	return _build_academy_text_block(
		str(block.get("heading", "Lesson")),
		str(block.get("body", "")),
		block.get("infoboxes", []),
		block.get("images", [])
	)


func _academy_lesson_card_title(section: Dictionary) -> String:
	var section_id: String = str(section.get("id", ""))
	if section_id == "intro":
		return "What is technical analysis?"
	if section_id == "market_structure":
		return "Read the market shape first"
	if section_id == "candlesticks":
		return "Read the fight inside each candle"
	if section_id == "patterns":
		return "Patterns need context"
	if section_id == "moving_average":
		return "Moving averages confirm, not command"
	if section_id == "thinking_framework":
		return "A repeatable routine beats guessing"
	return str(section.get("title", "Lesson"))


func _build_academy_quiz(section: Dictionary) -> void:
	var quiz: Dictionary = current_academy_snapshot.get("quiz", {})
	if bool(quiz.get("locked", true)):
		var unread_labels: Array = []
		for unread_value in quiz.get("unread_required_sections", []):
			var unread: Dictionary = unread_value
			unread_labels.append(str(unread.get("label", "")))
		academy_lesson_content_vbox.add_child(_build_academy_text_block("Locked", "Read these sections first: %s." % ", ".join(unread_labels)))
		return

	for block_value in section.get("content_blocks", []):
		var block: Dictionary = block_value
		academy_lesson_content_vbox.add_child(_build_academy_content_block(block))
	academy_lesson_content_vbox.add_child(_build_academy_text_block("Quiz", "Score 80 percent or better to earn %s. Wrong answers give feedback after submission." % _academy_current_badge_label()))
	var catalog: Dictionary = DataRepository.get_academy_catalog()
	var module_category: Dictionary = {}
	for category_value in catalog.get("categories", []):
		var category: Dictionary = category_value
		if str(category.get("id", "")) == selected_academy_category_id:
			module_category = category
			break
	for question_value in module_category.get("quiz_questions", []):
		var question: Dictionary = question_value
		var block := VBoxContainer.new()
		block.add_theme_constant_override("separation", 6)
		var prompt := Label.new()
		prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		prompt.text = "%s: %s" % [str(question.get("category", "Question")), str(question.get("prompt", ""))]
		prompt.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
		block.add_child(prompt)
		var option_button := OptionButton.new()
		option_button.name = "AcademyQuizOption_%s" % str(question.get("id", ""))
		option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option_button.custom_minimum_size = Vector2(0, 42)
		for option_value in question.get("options", []):
			var option: Dictionary = option_value
			option_button.add_item(str(option.get("label", "")))
			option_button.set_item_metadata(option_button.get_item_count() - 1, str(option.get("id", "")))
		academy_quiz_option_buttons[str(question.get("id", ""))] = option_button
		_style_academy_quiz_option_button(option_button)
		block.add_child(option_button)
		academy_lesson_content_vbox.add_child(block)

	var submit_button := Button.new()
	submit_button.name = "AcademyQuizSubmitButton"
	submit_button.text = "Submit Quiz"
	submit_button.pressed.connect(on_quiz_submit_pressed)
	academy_lesson_content_vbox.add_child(submit_button)
	_style_academy_quiz_submit_button(submit_button)


func _build_academy_glossary_section() -> void:
	academy_lesson_content_vbox.add_child(_build_academy_text_block("Searchable Glossary", "Search any technical term from this academy track."))
	var search_input := LineEdit.new()
	search_input.name = "AcademyGlossaryInlineSearchInput"
	search_input.placeholder_text = "Search glossary"
	search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	academy_lesson_content_vbox.add_child(search_input)
	var glossary_list := ItemList.new()
	glossary_list.name = "AcademyGlossaryInlineList"
	glossary_list.custom_minimum_size = Vector2(0, 260)
	glossary_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	academy_lesson_content_vbox.add_child(glossary_list)
	_populate_academy_glossary_list(glossary_list, "")
	search_input.text_changed.connect(func(new_text: String) -> void:
		_populate_academy_glossary_list(glossary_list, new_text)
	)
	_style_light_item_list(glossary_list)
	_style_line_input(search_input)


func _build_academy_text_block(title: String, body: String, infoboxes: Array = [], images: Array = []) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "AcademyTextBlock"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_academy_text_card(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	var title_label := Label.new()
	title_label.name = "AcademyTextBlockTitle"
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0.129412, 0.101961, 0.058824, 1))
	vbox.add_child(title_label)
	_add_academy_markdown_body(vbox, body)
	for image_value in images:
		var image: Dictionary = image_value
		var image_path: String = str(image.get("asset_path", "")).strip_edges()
		var image_caption: String = str(image.get("caption", "")).strip_edges()
		var image_alt: String = str(image.get("alt", "Academy image")).strip_edges()
		vbox.add_child(_build_academy_text_inline_image_block(image_path, image_caption, image_alt))
	for infobox_value in infoboxes:
		var infobox: Dictionary = infobox_value
		var infobox_title: String = str(infobox.get("title", "")).strip_edges()
		var infobox_body: String = str(infobox.get("body", "")).strip_edges()
		if infobox_title.is_empty() and infobox_body.is_empty():
			continue
		vbox.add_child(_build_academy_infobox_card(infobox_title, infobox_body))
	return panel


func _add_academy_markdown_body(vbox: VBoxContainer, body: String) -> void:
	var segments: Array = _split_academy_markdown_tables(body)
	for segment_value in segments:
		var segment: Dictionary = segment_value
		var segment_type: String = str(segment.get("type", "text"))
		if segment_type == "table":
			vbox.add_child(_build_academy_markdown_table(
				segment.get("headers", []),
				segment.get("rows", []),
				segment.get("alignments", [])
			))
			continue
		var text: String = str(segment.get("text", "")).strip_edges()
		if text.is_empty():
			continue
		var body_label := Label.new()
		body_label.name = "AcademyTextBlockBody"
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body_label.text = text
		body_label.add_theme_font_size_override("font_size", 14)
		body_label.add_theme_color_override("font_color", Color(0.352941, 0.309804, 0.203922, 1))
		vbox.add_child(body_label)


func _split_academy_markdown_tables(body: String) -> Array:
	var segments: Array = []
	var lines: PackedStringArray = body.split("\n", true)
	var text_lines: Array = []
	var line_index: int = 0
	while line_index < lines.size():
		var line: String = str(lines[line_index])
		var next_line: String = str(lines[line_index + 1]) if line_index + 1 < lines.size() else ""
		if _is_academy_markdown_table_row(line) and _is_academy_markdown_table_separator(next_line):
			_flush_academy_markdown_text_segment(segments, text_lines)
			text_lines.clear()
			var headers: Array = _parse_academy_markdown_table_row(line)
			var alignments: Array = _parse_academy_markdown_table_alignments(next_line)
			var rows: Array = []
			line_index += 2
			while line_index < lines.size() and _is_academy_markdown_table_row(str(lines[line_index])):
				rows.append(_parse_academy_markdown_table_row(str(lines[line_index])))
				line_index += 1
			segments.append({
				"type": "table",
				"headers": headers,
				"rows": rows,
				"alignments": alignments
			})
			continue
		text_lines.append(line)
		line_index += 1
	_flush_academy_markdown_text_segment(segments, text_lines)
	return segments


func _flush_academy_markdown_text_segment(segments: Array, text_lines: Array) -> void:
	var text: String = "\n".join(text_lines).strip_edges()
	if not text.is_empty():
		segments.append({"type": "text", "text": text})


func _is_academy_markdown_table_row(line: String) -> bool:
	var trimmed: String = line.strip_edges()
	return trimmed.begins_with("|") and trimmed.ends_with("|") and trimmed.count("|") >= 3


func _is_academy_markdown_table_separator(line: String) -> bool:
	if not _is_academy_markdown_table_row(line):
		return false
	var cells: Array = _parse_academy_markdown_table_row(line)
	if cells.is_empty():
		return false
	for cell_value in cells:
		var cell: String = str(cell_value).strip_edges()
		if cell.is_empty():
			return false
		for char_index in cell.length():
			var character: String = cell.substr(char_index, 1)
			if character != "-" and character != ":" and character != " ":
				return false
		if not cell.contains("-"):
			return false
	return true


func _parse_academy_markdown_table_row(line: String) -> Array:
	var trimmed: String = line.strip_edges()
	if trimmed.begins_with("|"):
		trimmed = trimmed.substr(1)
	if trimmed.ends_with("|"):
		trimmed = trimmed.substr(0, trimmed.length() - 1)
	var cells: Array = []
	for cell_value in trimmed.split("|", true):
		cells.append(str(cell_value).strip_edges())
	return cells


func _parse_academy_markdown_table_alignments(line: String) -> Array:
	var alignments: Array = []
	for cell_value in _parse_academy_markdown_table_row(line):
		var cell: String = str(cell_value).strip_edges()
		if cell.begins_with(":") and cell.ends_with(":"):
			alignments.append(HORIZONTAL_ALIGNMENT_CENTER)
		elif cell.ends_with(":"):
			alignments.append(HORIZONTAL_ALIGNMENT_RIGHT)
		else:
			alignments.append(HORIZONTAL_ALIGNMENT_LEFT)
	return alignments


func _build_academy_markdown_table(headers: Array, rows: Array, alignments: Array) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "AcademyMarkdownTable"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_academy_table_card(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)
	vbox.add_child(_build_academy_markdown_table_row(headers, alignments, true))
	for row_value in rows:
		vbox.add_child(HSeparator.new())
		vbox.add_child(_build_academy_markdown_table_row(row_value, alignments, false))
	return panel


func _build_academy_markdown_table_row(cells: Array, alignments: Array, is_header: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "AcademyMarkdownTableHeaderRow" if is_header else "AcademyMarkdownTableRow"
	row.add_theme_constant_override("separation", 8)
	var column_count: int = max(cells.size(), alignments.size())
	for cell_index in column_count:
		var cell_text: String = str(cells[cell_index]) if cell_index < cells.size() else ""
		var alignment: HorizontalAlignment = alignments[cell_index] if cell_index < alignments.size() else HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(_build_academy_markdown_table_cell(cell_text, alignment, is_header))
	return row


func _build_academy_markdown_table_cell(text: String, alignment: HorizontalAlignment, is_header: bool) -> Label:
	var label := Label.new()
	label.name = "AcademyMarkdownTableHeaderCell" if is_header else "AcademyMarkdownTableCell"
	label.custom_minimum_size = Vector2(92, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.176471, 0.129412, 0.070588, 1) if is_header else Color(0.352941, 0.309804, 0.203922, 1))
	if is_header:
		label.add_theme_color_override("font_outline_color", Color(0.980392, 0.933333, 0.741176, 0.6))
		label.add_theme_constant_override("outline_size", 1)
	return label


func _build_academy_text_inline_image_block(asset_path: String, caption: String = "", alt_text: String = "") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "AcademyTextInlineImageBlock"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_academy_content_block(panel, Color(0.258824, 0.25098, 0.196078, 1), 1)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	var image_frame := PanelContainer.new()
	image_frame.name = "AcademyTextInlineImageFrame"
	image_frame.custom_minimum_size = Vector2(0, 150)
	image_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(image_frame)
	_style_academy_banner_frame(image_frame)
	var center := CenterContainer.new()
	image_frame.add_child(center)
	var image_texture: Texture2D = null
	if not asset_path.is_empty() and ResourceLoader.exists(asset_path):
		image_texture = load(asset_path) as Texture2D
	if image_texture != null:
		var texture_rect := TextureRect.new()
		texture_rect.name = "AcademyTextInlineImageTexture"
		texture_rect.texture = image_texture
		texture_rect.custom_minimum_size = Vector2(0, 140)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.tooltip_text = alt_text
		center.add_child(texture_rect)
	else:
		var placeholder := Label.new()
		placeholder.name = "AcademyTextInlineImagePlaceholder"
		placeholder.text = "IMAGE PLACEHOLDER" if asset_path.is_empty() else "MISSING IMAGE"
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.add_theme_color_override("font_color", Color(0.898039, 0.870588, 0.745098, 1))
		center.add_child(placeholder)
	if not caption.strip_edges().is_empty():
		var caption_label := Label.new()
		caption_label.name = "AcademyTextInlineImageCaption"
		caption_label.text = caption
		caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption_label.add_theme_color_override("font_color", Color(0.898039, 0.870588, 0.745098, 1))
		vbox.add_child(caption_label)
	return panel


func _build_academy_infobox_card(title: String, body: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "AcademyInfoboxCard"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_academy_infobox_card(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	if not title.is_empty():
		var title_label := Label.new()
		title_label.text = title
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.add_theme_color_override("font_color", COLOR_ACADEMY_BROWN)
		vbox.add_child(title_label)
	if not body.is_empty():
		var body_label := Label.new()
		body_label.text = body
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body_label.add_theme_color_override("font_color", Color(0.352941, 0.309804, 0.203922, 1))
		vbox.add_child(body_label)
	return panel


func _build_academy_key_insights_block(title: String, bullets: Array) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "AcademyKeyInsightsBlock"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_academy_key_insights_card(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	var title_label := Label.new()
	title_label.name = "AcademyKeyInsightsTitle"
	title_label.text = title if not title.strip_edges().is_empty() else "Key Insights"
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_color_override("font_color", Color(0.054902, 0.164706, 0.313726, 1))
	title_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title_label)
	for bullet_value in bullets:
		var bullet_text: String = str(bullet_value).strip_edges()
		if bullet_text.is_empty():
			continue
		var bullet_label := Label.new()
		bullet_label.text = "- %s" % bullet_text
		bullet_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bullet_label.add_theme_color_override("font_color", Color(0.07451, 0.156863, 0.270588, 1))
		vbox.add_child(bullet_label)
	return panel


func _build_academy_image_block(asset_path: String, caption: String = "", alt_text: String = "") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "AcademyImageBlock"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_academy_banner_frame(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	var image_frame := PanelContainer.new()
	image_frame.name = "AcademyInlineImageFrame"
	image_frame.custom_minimum_size = Vector2(0, 190)
	image_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(image_frame)
	_style_academy_banner_frame(image_frame)
	var center := CenterContainer.new()
	image_frame.add_child(center)
	var image_texture: Texture2D = null
	if not asset_path.is_empty() and ResourceLoader.exists(asset_path):
		image_texture = load(asset_path) as Texture2D
	if image_texture != null:
		var texture_rect := TextureRect.new()
		texture_rect.name = "AcademyInlineImageTexture"
		texture_rect.texture = image_texture
		texture_rect.custom_minimum_size = Vector2(0, 180)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.tooltip_text = alt_text
		center.add_child(texture_rect)
	else:
		var placeholder := Label.new()
		placeholder.name = "AcademyInlineImagePlaceholder"
		placeholder.text = "IMAGE PLACEHOLDER" if asset_path.is_empty() else "MISSING IMAGE"
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.add_theme_color_override("font_color", Color(0.898039, 0.870588, 0.745098, 1))
		center.add_child(placeholder)
	if not caption.strip_edges().is_empty():
		var caption_label := Label.new()
		caption_label.name = "AcademyInlineImageCaption"
		caption_label.text = caption
		caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption_label.add_theme_color_override("font_color", Color(0.898039, 0.870588, 0.745098, 1))
		vbox.add_child(caption_label)
	return panel


func _build_academy_example_block(title: String, example_type: String) -> PanelContainer:
	var body: String = "Practice: %s. Run the same read on live stock charts after you finish the lesson." % example_type.replace("_", " ")
	return _build_academy_text_block(title, body)


func _build_academy_check_block(section_id: String, check: Dictionary, stored_result: Dictionary) -> PanelContainer:
	var scenario_text: String = str(check.get("scenario", "")).strip_edges()
	var question_text: String = str(check.get("question", "")).strip_edges()
	var body_text: String = question_text
	if not scenario_text.is_empty():
		body_text = "%s\n\nQuestion: %s" % [scenario_text, question_text]
	var panel := _build_academy_text_block(str(check.get("title", "Quick Check")), body_text)
	var vbox: VBoxContainer = panel.get_child(0).get_child(0) as VBoxContainer
	var options_row := HBoxContainer.new()
	options_row.add_theme_constant_override("separation", 6)
	vbox.add_child(options_row)
	for option_value in check.get("options", []):
		var option: Dictionary = option_value
		var button := Button.new()
		button.name = "AcademyQuickCheckOptionButton"
		button.text = str(option.get("label", "Answer"))
		button.pressed.connect(on_inline_check_pressed.bind(section_id, str(check.get("id", "")), str(option.get("id", ""))))
		options_row.add_child(button)
		_style_academy_quick_check_button(button)
	if not stored_result.is_empty():
		var result_label := Label.new()
		result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_label.text = "Saved answer: %s. %s" % [
			"Correct" if bool(stored_result.get("correct", false)) else "Not yet",
			str(stored_result.get("feedback", ""))
		]
		result_label.add_theme_color_override("font_color", COLOR_POSITIVE if bool(stored_result.get("correct", false)) else COLOR_NEGATIVE)
		vbox.add_child(result_label)
	return panel


func _refresh_academy_side_panel() -> void:
	var quiz: Dictionary = current_academy_snapshot.get("quiz", {})
	var badge: Dictionary = current_academy_snapshot.get("badge", {})
	academy_side_title_label.text = "Progress"
	var status_lines: Array = [
		"Quiz: %s" % ("passed" if bool(quiz.get("passed", false)) else ("locked" if bool(quiz.get("locked", true)) else "open")),
		"Attempts: %d" % int(quiz.get("attempts", 0)),
		"Best score: %d%%" % int(quiz.get("best_score_percent", 0))
	]
	if bool(current_academy_snapshot.get("progress", {}).get("badge_earned", false)):
		status_lines.append("Badge earned: %s" % str(badge.get("label", _academy_current_badge_label())))
	academy_side_body_label.text = "\n".join(status_lines)
	var show_glossary_tools: bool = not bool(current_academy_snapshot.get("coming_soon", true))
	academy_glossary_search_input.visible = show_glossary_tools
	academy_glossary_list.visible = show_glossary_tools
	refresh_glossary_results()


func refresh_glossary_results() -> void:
	if academy_glossary_list == null:
		return
	var query: String = academy_glossary_search_input.text if academy_glossary_search_input != null else ""
	_populate_academy_glossary_list(academy_glossary_list, query)


func _populate_academy_glossary_list(target_list: ItemList, query: String) -> void:
	target_list.clear()
	var rows: Array = GameManager.search_academy_glossary(query)
	if rows.is_empty():
		target_list.add_item("No matching terms.")
		target_list.set_item_disabled(0, true)
		return
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		target_list.add_item("%s - %s" % [str(row.get("term", "")), str(row.get("definition", ""))])
		target_list.set_item_metadata(index, row)


func next_section_id() -> String:
	var sections: Array = current_academy_snapshot.get("sections", [])
	for index in range(sections.size()):
		var section: Dictionary = sections[index]
		if str(section.get("id", "")) != selected_academy_section_id:
			continue
		for next_index in range(index + 1, sections.size()):
			var next_section: Dictionary = sections[next_index]
			if not bool(next_section.get("locked", false)):
				return str(next_section.get("id", ""))
	return ""


func on_category_pressed(category_id: String) -> void:
	selected_academy_category_id = category_id
	selected_academy_section_id = ""
	refresh()
	_mark_guide_academy_lesson_chosen()


func on_section_selected(index: int) -> void:
	var metadata: Variant = academy_section_list.get_item_metadata(index)
	if typeof(metadata) != TYPE_DICTIONARY:
		return
	var section: Dictionary = metadata
	if bool(section.get("locked", false)):
		return
	selected_academy_section_id = str(section.get("id", ""))
	refresh()
	_mark_guide_academy_lesson_chosen()


func on_section_tab_pressed(section_id: String) -> void:
	if section_id.is_empty():
		return
	selected_academy_section_id = section_id
	refresh()
	_mark_guide_academy_lesson_chosen()


func on_mark_read_pressed() -> void:
	var result: Dictionary = GameManager.mark_academy_section_read(selected_academy_category_id, selected_academy_section_id)
	_show_toast(str(result.get("message", "Academy updated.")), bool(result.get("success", false)))
	refresh()
	_mark_guide_academy_read_action()


func on_next_pressed() -> void:
	var next_id: String = next_section_id()
	if next_id.is_empty():
		return
	selected_academy_section_id = next_id
	refresh()
	_mark_guide_academy_lesson_chosen()


func on_inline_check_pressed(section_id: String, check_id: String, answer_id: String) -> void:
	var result: Dictionary = GameManager.submit_academy_inline_check(selected_academy_category_id, section_id, check_id, answer_id)
	_show_toast(str(result.get("feedback", result.get("message", "Answer saved."))), bool(result.get("correct", false)))
	refresh()


func on_quiz_submit_pressed() -> void:
	var answers: Dictionary = {}
	for question_id_value in academy_quiz_option_buttons.keys():
		var question_id: String = str(question_id_value)
		var option_button: OptionButton = academy_quiz_option_buttons[question_id]
		if option_button.selected >= 0:
			answers[question_id] = str(option_button.get_item_metadata(option_button.selected))
	var result: Dictionary = GameManager.submit_academy_quiz(selected_academy_category_id, answers)
	if not bool(result.get("success", false)):
		_show_toast(str(result.get("message", "Quiz could not be submitted.")), false)
		refresh()
		return
	var result_badge: Dictionary = result.get("badge", current_academy_snapshot.get("badge", {}))
	var badge_label: String = str(result_badge.get("label", _academy_current_badge_label()))
	var message: String = "Quiz score %d%%. %s" % [
		int(result.get("score_percent", 0)),
		"%s earned." % badge_label if bool(result.get("passed", false)) else "Review and try again."
	]
	_show_toast(message, bool(result.get("passed", false)))
	refresh()
	show_quiz_feedback(result.get("feedback", []), bool(result.get("passed", false)), int(result.get("score_percent", 0)))


func show_quiz_feedback(feedback_rows: Array, passed: bool, score_percent: int) -> void:
	_clear_container_children(academy_lesson_content_vbox)
	academy_lesson_content_vbox.add_child(_build_academy_text_block(
		"Quiz Result",
		"Score: %d%%. %s" % [score_percent, "Passed. %s is now earned." % _academy_current_badge_label() if passed else "Not yet. Review the feedback and retry."]
	))
	for feedback_value in feedback_rows:
		var feedback: Dictionary = feedback_value
		academy_lesson_content_vbox.add_child(_build_academy_text_block(
			"%s - %s" % [str(feedback.get("prompt", "Question")), "Correct" if bool(feedback.get("correct", false)) else "Review"],
			str(feedback.get("feedback", ""))
		))


func on_glossary_search_changed(_new_text: String) -> void:
	refresh_glossary_results()


func _sync_root_refs() -> void:
	if _root == null:
		return
	_root.set("academy_app_button", academy_app_button)
	_root.set("academy_app_label", academy_app_label)
	_root.set("academy_window", academy_window)
	_root.set("academy_window_body", academy_window_body)
	_root.set("academy_title_label", academy_title_label)
	_root.set("academy_progress_label", academy_progress_label)
	_root.set("academy_category_tabs", academy_category_tabs)
	_root.set("academy_section_tabs", academy_section_tabs)
	_root.set("academy_summary_label", academy_summary_label)
	_root.set("academy_section_list", academy_section_list)
	_root.set("academy_selection_chip_label", academy_selection_chip_label)
	_root.set("academy_lesson_title_label", academy_lesson_title_label)
	_root.set("academy_lesson_meta_label", academy_lesson_meta_label)
	_root.set("academy_lesson_banner_frame", academy_lesson_banner_frame)
	_root.set("academy_lesson_banner_label", academy_lesson_banner_label)
	_root.set("academy_lesson_scroll", academy_lesson_scroll)
	_root.set("academy_lesson_content_vbox", academy_lesson_content_vbox)
	_root.set("academy_action_row", academy_action_row)
	_root.set("academy_mark_read_button", academy_mark_read_button)
	_root.set("academy_next_button", academy_next_button)
	_root.set("academy_side_title_label", academy_side_title_label)
	_root.set("academy_side_body_label", academy_side_body_label)
	_root.set("academy_glossary_search_input", academy_glossary_search_input)
	_root.set("academy_glossary_list", academy_glossary_list)
	_sync_root_state()


func _sync_root_state() -> void:
	if _root == null:
		return
	_root.set("current_academy_snapshot", current_academy_snapshot)
	_root.set("selected_academy_category_id", selected_academy_category_id)
	_root.set("selected_academy_section_id", selected_academy_section_id)
	_root.set("academy_quiz_option_buttons", academy_quiz_option_buttons)


func _clear_container_children(container: Node) -> void:
	if _root != null:
		_root.call("_clear_container_children", container)


func _apply_font_overrides_to_subtree(node: Node) -> void:
	if _root != null:
		_root.call("_apply_font_overrides_to_subtree", node)


func _show_toast(message: String, is_success: bool) -> void:
	if _root != null:
		_root.call("_show_toast", message, is_success)


func _mark_guide_academy_lesson_chosen() -> void:
	if _root != null:
		_root.call("_mark_guide_academy_lesson_chosen")


func _mark_guide_academy_read_action() -> void:
	if _root != null:
		_root.call("_mark_guide_academy_read_action")


func _style_panel(panel: PanelContainer, fill_color: Color, corner_radius: int = 10, border_top: int = 1, border_right: int = 1, border_bottom: int = 1, border_left: int = 1) -> void:
	if _root != null:
		_root.call("_style_panel", panel, fill_color, corner_radius, border_top, border_right, border_bottom, border_left)


func _style_button(button: Button, fill_color: Color, border_color: Color, font_color: Color, corner_radius: int = 8) -> void:
	if _root != null:
		_root.call("_style_button", button, fill_color, border_color, font_color, corner_radius)


func _style_news_tab_button(button: Button, is_selected: bool, is_unlocked: bool) -> void:
	if _root != null:
		_root.call("_style_news_tab_button", button, is_selected, is_unlocked)


func _style_light_item_list(item_list: ItemList) -> void:
	if _root != null:
		_root.call("_style_light_item_list", item_list)


func _style_line_input(line_edit: LineEdit) -> void:
	if _root != null:
		_root.call("_style_line_input", line_edit)
