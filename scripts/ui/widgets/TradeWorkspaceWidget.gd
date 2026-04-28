extends PanelContainer
class_name TradeWorkspaceWidget

signal chart_range_changed(range_id)

const COLOR_TEXT := Color(0.92549, 0.941176, 0.956863, 1)
const COLOR_MUTED := Color(0.694118, 0.756863, 0.803922, 1)
const COLOR_POSITIVE := Color(0.513726, 0.886275, 0.662745, 1)
const COLOR_NEGATIVE := Color(0.968627, 0.513726, 0.513726, 1)
const COLOR_WARNING := Color(0.980392, 0.792157, 0.392157, 1)
const COLOR_ACCENT := Color(0.560784, 0.772549, 1, 1)
const COLOR_BORDER := Color(0.333333, 0.462745, 0.580392, 0.8)

var _selected_range_id: String = "1m"
var _chart_display_mode: String = "line"
var _active_indicator_ids: Array = []
var _company_snapshot: Dictionary = {}
var _indicator_buttons: Dictionary = {}
var _drawing_tool_buttons: Dictionary = {}
var _cached_chart_key: String = ""
var _cached_chart_snapshot: Dictionary = {}
var pattern_tool_button: Button = null
var pattern_claim_panel: PanelContainer = null
var pattern_option_button: OptionButton = null
var pattern_status_label: Label = null
var pattern_feedback_label: Label = null
var pattern_thesis_option: OptionButton = null
var pattern_add_to_thesis_button: Button = null
var _last_pattern_claim: Dictionary = {}
var _pattern_thesis_rows: Array = []

@onready var work_tabs: TabContainer = $WorkAreaMargin/WorkAreaVBox/WorkTabs
@onready var chart_header_label: Label = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartHeaderLabel
@onready var chart_subheader_label: Label = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartSubheaderLabel
@onready var chart_meta_label: Label = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartMetaLabel
@onready var chart_body_row: HBoxContainer = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartBodyRow
@onready var chart_canvas: PriceChartCanvas = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartBodyRow/ChartCanvas
@onready var chart_drawing_toolbar: VBoxContainer = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartBodyRow/ChartDrawingToolbar
@onready var select_tool_button: Button = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartBodyRow/ChartDrawingToolbar/SelectToolButton
@onready var horizontal_line_tool_button: Button = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartBodyRow/ChartDrawingToolbar/HorizontalLineToolButton
@onready var trend_line_tool_button: Button = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartBodyRow/ChartDrawingToolbar/TrendLineToolButton
@onready var delete_drawing_button: Button = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartBodyRow/ChartDrawingToolbar/DeleteDrawingButton
@onready var clear_drawings_button: Button = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartBodyRow/ChartDrawingToolbar/ClearDrawingsButton
@onready var range_1d_button: Button = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartRangeRow/Range1DButton
@onready var range_1w_button: Button = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartRangeRow/Range1WButton
@onready var range_1m_button: Button = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartRangeRow/Range1MButton
@onready var range_1y_button: Button = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartRangeRow/Range1YButton
@onready var range_5y_button: Button = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartRangeRow/Range5YButton
@onready var range_ytd_button: Button = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartRangeRow/RangeYTDButton
@onready var display_line_button: Button = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartRangeRow/DisplayLineButton
@onready var display_candle_button: Button = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartRangeRow/DisplayCandleButton
@onready var zoom_out_button: Button = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartRangeRow/ZoomOutButton
@onready var zoom_in_button: Button = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartRangeRow/ZoomInButton
var indicator_row: HBoxContainer = null


func _ready() -> void:
	work_tabs.set_tab_title(0, "Chart")
	work_tabs.set_tab_title(1, "Key Stats")
	work_tabs.set_tab_title(2, "Financials")
	work_tabs.set_tab_title(3, "Broker")
	work_tabs.set_tab_title(4, "Analyzer")
	work_tabs.set_tab_title(5, "Profile")
	work_tabs.set_tab_hidden(4, true)
	_bind_chart_range_button(range_1d_button, "1d")
	_bind_chart_range_button(range_1w_button, "1w")
	_bind_chart_range_button(range_1m_button, "1m")
	_bind_chart_range_button(range_1y_button, "1y")
	_bind_chart_range_button(range_5y_button, "5y")
	_bind_chart_range_button(range_ytd_button, "ytd")
	display_line_button.pressed.connect(func() -> void:
		_on_chart_display_mode_pressed("line")
	)
	display_candle_button.pressed.connect(func() -> void:
		_on_chart_display_mode_pressed("candle")
	)
	zoom_out_button.pressed.connect(_on_zoom_out_pressed)
	zoom_in_button.pressed.connect(_on_zoom_in_pressed)
	select_tool_button.pressed.connect(_on_drawing_tool_pressed.bind("select"))
	horizontal_line_tool_button.pressed.connect(_on_drawing_tool_pressed.bind("horizontal"))
	trend_line_tool_button.pressed.connect(_on_drawing_tool_pressed.bind("trend"))
	delete_drawing_button.pressed.connect(chart_canvas.delete_selected_drawing)
	clear_drawings_button.pressed.connect(chart_canvas.clear_drawings_for_active_company)
	_drawing_tool_buttons = {
		"select": select_tool_button,
		"horizontal": horizontal_line_tool_button,
		"trend": trend_line_tool_button
	}
	_ensure_pattern_tool_controls()
	for button_value in _chart_range_button_map().values():
		_style_chart_range_button(button_value)
	_style_chart_range_button(display_line_button)
	_style_chart_range_button(display_candle_button)
	_style_chart_range_button(zoom_out_button)
	_style_chart_range_button(zoom_in_button)
	for button_value in _drawing_tool_buttons.values():
		_style_chart_range_button(button_value)
	_style_chart_range_button(delete_drawing_button)
	_style_chart_range_button(clear_drawings_button)
	select_tool_button.tooltip_text = "Select chart drawings."
	horizontal_line_tool_button.tooltip_text = "Place a horizontal price line."
	trend_line_tool_button.tooltip_text = "Draw a trend line with two clicks."
	if pattern_tool_button != null:
		pattern_tool_button.tooltip_text = "Mark a player-led chart pattern claim."
	delete_drawing_button.tooltip_text = "Delete the selected chart drawing."
	clear_drawings_button.tooltip_text = "Clear this stock's session drawings."
	if not chart_canvas.pattern_region_selected.is_connected(_on_chart_pattern_region_selected):
		chart_canvas.pattern_region_selected.connect(_on_chart_pattern_region_selected)
	if not GameManager.thesis_changed.is_connected(_on_thesis_changed):
		GameManager.thesis_changed.connect(_on_thesis_changed)
	_ensure_pattern_claim_panel()
	_ensure_indicator_row()
	chart_header_label.add_theme_color_override("font_color", COLOR_TEXT)
	chart_subheader_label.add_theme_color_override("font_color", COLOR_MUTED)
	chart_subheader_label.visible = false
	chart_meta_label.add_theme_color_override("font_color", COLOR_MUTED)
	_update_chart_range_buttons()
	_update_chart_display_mode_buttons()
	_update_drawing_tool_buttons()
	_update_zoom_buttons()
	_refresh_indicator_controls()
	_refresh_pattern_panel()


func set_company_snapshot(snapshot: Dictionary) -> void:
	var previous_company_id: String = str(_company_snapshot.get("id", ""))
	var next_company_id: String = str(snapshot.get("id", ""))
	_company_snapshot = snapshot
	chart_canvas.set_active_company_id(next_company_id)
	if previous_company_id != next_company_id or next_company_id.is_empty():
		chart_canvas.reset_zoom()
		_cached_chart_key = ""
		_cached_chart_snapshot = {}
		_last_pattern_claim.clear()
		chart_canvas.clear_pattern_claim_region()
	_refresh_chart()
	_refresh_pattern_panel()


func set_active_indicator_ids(indicator_ids: Array) -> void:
	_active_indicator_ids = indicator_ids.duplicate()
	_refresh_indicator_controls()
	_refresh_chart()


func refresh_indicator_catalog() -> void:
	_active_indicator_ids = _filter_unlocked_indicator_ids(_active_indicator_ids)
	_refresh_indicator_controls()
	_refresh_chart()


func get_selected_range_id() -> String:
	return _selected_range_id


func set_chart_minimum_height(height_value: float) -> void:
	chart_canvas.custom_minimum_size = Vector2(0, height_value)


func _refresh_chart() -> void:
	_update_chart_range_buttons()
	_ensure_valid_chart_display_mode()
	if _company_snapshot.is_empty():
		chart_header_label.text = "No stock selected"
		chart_subheader_label.text = "Choose a stock from the left list to load the work area."
		chart_meta_label.text = "%s | Chart unavailable." % GameManager.get_chart_range_label(_selected_range_id)
		chart_canvas.clear_chart()
		_cached_chart_key = ""
		_cached_chart_snapshot = {}
		_update_chart_display_mode_buttons()
		_update_zoom_buttons()
		_refresh_pattern_panel()
		return

	var chart_snapshot: Dictionary = _get_cached_chart_snapshot()
	var detail_ready: bool = str(_company_snapshot.get("detail_status", "ready")) == "ready"
	chart_header_label.text = "%s  |  %s" % [
		_company_snapshot.get("ticker", ""),
		_company_snapshot.get("name", "")
	]
	chart_subheader_label.text = "Sector %s  |  Board %s  |  Held %d lot(s)  |  Day move %s  |  View %s" % [
		_company_snapshot.get("sector_name", "Unknown"),
		str(_company_snapshot.get("listing_board", "main")).capitalize(),
		int(_company_snapshot.get("lots_owned", 0)),
		_format_change(float(_company_snapshot.get("daily_change_pct", 0.0))),
		GameManager.get_chart_range_label(_selected_range_id)
	]

	if chart_snapshot.is_empty():
		chart_meta_label.text = "%s | %s" % [
			GameManager.get_chart_range_label(_selected_range_id),
			"Loading extended history..." if not detail_ready else "Not enough price history yet."
		]
		chart_canvas.clear_chart()
		_update_chart_display_mode_buttons()
		_update_zoom_buttons()
		_refresh_pattern_panel()
		return

	chart_meta_label.text = _build_chart_meta_text(chart_snapshot)
	if not detail_ready:
		chart_meta_label.text += " | Loading extended history..."
	chart_canvas.set_chart_snapshot(_decorate_chart_snapshot(chart_snapshot))
	_update_chart_display_mode_buttons()
	_update_zoom_buttons()
	_refresh_pattern_panel()


func _get_cached_chart_snapshot() -> Dictionary:
	var chart_key: String = _build_chart_cache_key()
	if chart_key != _cached_chart_key:
		_cached_chart_key = chart_key
		_cached_chart_snapshot = GameManager.get_company_chart_snapshot(
			str(_company_snapshot.get("id", "")),
			_selected_range_id,
			_active_indicator_ids
		)
	return _cached_chart_snapshot


func _build_chart_cache_key() -> String:
	var indicator_tokens: PackedStringArray = PackedStringArray()
	for indicator_id_value in _active_indicator_ids:
		indicator_tokens.append(str(indicator_id_value))
	var company_id: String = str(_company_snapshot.get("id", ""))
	return "%s|%s|%s|%d|%s|%s|%s" % [
		company_id,
		_selected_range_id,
		",".join(indicator_tokens),
		int(RunState.day_index),
		str(_company_snapshot.get("current_price", 0.0)),
		str(_company_snapshot.get("previous_close", 0.0)),
		str(_company_snapshot.get("detail_status", "ready"))
	]


func _bind_chart_range_button(button: Button, range_id: String) -> void:
	button.pressed.connect(func() -> void:
		_on_chart_range_pressed(range_id)
	)


func _on_chart_range_pressed(range_id: String) -> void:
	_selected_range_id = str(range_id).to_lower()
	chart_canvas.reset_zoom()
	_last_pattern_claim.clear()
	chart_canvas.clear_pattern_claim_region()
	_update_chart_range_buttons()
	_refresh_chart()
	chart_range_changed.emit(_selected_range_id)


func _update_chart_range_buttons() -> void:
	var button_map: Dictionary = _chart_range_button_map()
	for range_id in button_map.keys():
		var button: Button = button_map[range_id]
		button.set_pressed_no_signal(str(range_id) == _selected_range_id)


func _update_chart_display_mode_buttons() -> void:
	_ensure_valid_chart_display_mode()
	display_line_button.set_pressed_no_signal(_chart_display_mode == "line")
	display_candle_button.set_pressed_no_signal(_chart_display_mode == "candle")
	display_line_button.disabled = false
	display_candle_button.disabled = not _can_use_candle_mode()


func _update_zoom_buttons() -> void:
	zoom_in_button.disabled = not chart_canvas.can_zoom_in()
	zoom_out_button.disabled = not chart_canvas.can_zoom_out()


func _on_chart_display_mode_pressed(display_mode: String) -> void:
	var normalized_mode: String = str(display_mode).to_lower()
	if normalized_mode == "candle" and not _can_use_candle_mode():
		_chart_display_mode = "line"
		_update_chart_display_mode_buttons()
		return
	if normalized_mode == _chart_display_mode:
		_update_chart_display_mode_buttons()
		return
	_chart_display_mode = "candle" if normalized_mode == "candle" else "line"
	_update_chart_display_mode_buttons()
	_refresh_chart()


func _ensure_valid_chart_display_mode() -> void:
	if _chart_display_mode == "candle" and not _can_use_candle_mode():
		_chart_display_mode = "line"


func _can_use_candle_mode() -> bool:
	return not _company_snapshot.is_empty() and _selected_range_id != "1d"


func _on_zoom_in_pressed() -> void:
	chart_canvas.zoom_in()
	_update_zoom_buttons()


func _on_zoom_out_pressed() -> void:
	chart_canvas.zoom_out()
	_update_zoom_buttons()


func _chart_range_button_map() -> Dictionary:
	return {
		"1d": range_1d_button,
		"1w": range_1w_button,
		"1m": range_1m_button,
		"1y": range_1y_button,
		"5y": range_5y_button,
		"ytd": range_ytd_button
	}


func _on_drawing_tool_pressed(tool_id: String) -> void:
	chart_canvas.set_drawing_tool(tool_id)
	_update_drawing_tool_buttons()
	_refresh_pattern_panel()


func _update_drawing_tool_buttons() -> void:
	var active_tool: String = chart_canvas.get_drawing_tool()
	for tool_id in _drawing_tool_buttons.keys():
		var button: Button = _drawing_tool_buttons[tool_id]
		button.set_pressed_no_signal(str(tool_id) == active_tool)


func _ensure_pattern_tool_controls() -> void:
	if pattern_tool_button != null:
		return
	pattern_tool_button = Button.new()
	pattern_tool_button.name = "PatternToolButton"
	pattern_tool_button.text = "P"
	pattern_tool_button.toggle_mode = true
	pattern_tool_button.custom_minimum_size = Vector2(42, 36)
	pattern_tool_button.pressed.connect(_on_drawing_tool_pressed.bind("pattern_claim"))
	chart_drawing_toolbar.add_child(pattern_tool_button)
	chart_drawing_toolbar.move_child(pattern_tool_button, trend_line_tool_button.get_index() + 1)
	_drawing_tool_buttons["pattern_claim"] = pattern_tool_button


func _ensure_pattern_claim_panel() -> void:
	if pattern_claim_panel != null:
		return
	pattern_claim_panel = PanelContainer.new()
	pattern_claim_panel.name = "ChartPatternClaimPanel"
	pattern_claim_panel.custom_minimum_size = Vector2(280, 0)
	pattern_claim_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pattern_claim_panel.visible = false
	_style_pattern_claim_panel(pattern_claim_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	pattern_claim_panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title_label: Label = _make_pattern_panel_label("Pattern Claim", COLOR_TEXT, 16)
	vbox.add_child(title_label)

	pattern_status_label = _make_pattern_panel_label("Choose a pattern and mark two chart points.", COLOR_MUTED, 12)
	pattern_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(pattern_status_label)

	pattern_option_button = OptionButton.new()
	pattern_option_button.name = "ChartPatternOption"
	pattern_option_button.custom_minimum_size = Vector2(0, 34)
	pattern_option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for pattern_value in GameManager.get_chart_pattern_catalog():
		if typeof(pattern_value) != TYPE_DICTIONARY:
			continue
		var pattern: Dictionary = pattern_value
		var index: int = pattern_option_button.item_count
		pattern_option_button.add_item(str(pattern.get("label", pattern.get("id", ""))))
		pattern_option_button.set_item_metadata(index, str(pattern.get("id", "")))
	pattern_option_button.item_selected.connect(_on_pattern_option_selected)
	_style_chart_range_button(pattern_option_button)
	vbox.add_child(pattern_option_button)

	pattern_feedback_label = _make_pattern_panel_label("No pattern region marked yet.", COLOR_MUTED, 12)
	pattern_feedback_label.name = "ChartPatternFeedbackLabel"
	pattern_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pattern_feedback_label.custom_minimum_size = Vector2(0, 88)
	vbox.add_child(pattern_feedback_label)

	var thesis_label: Label = _make_pattern_panel_label("Destination Thesis", COLOR_TEXT, 13)
	vbox.add_child(thesis_label)

	pattern_thesis_option = OptionButton.new()
	pattern_thesis_option.name = "ChartPatternThesisOption"
	pattern_thesis_option.custom_minimum_size = Vector2(0, 34)
	pattern_thesis_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_chart_range_button(pattern_thesis_option)
	vbox.add_child(pattern_thesis_option)

	pattern_add_to_thesis_button = Button.new()
	pattern_add_to_thesis_button.name = "ChartPatternAddToThesisButton"
	pattern_add_to_thesis_button.text = "Add to Thesis"
	pattern_add_to_thesis_button.custom_minimum_size = Vector2(0, 36)
	pattern_add_to_thesis_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pattern_add_to_thesis_button.pressed.connect(_on_add_pattern_to_thesis_pressed)
	_style_chart_range_button(pattern_add_to_thesis_button)
	vbox.add_child(pattern_add_to_thesis_button)

	chart_body_row.add_child(pattern_claim_panel)


func _refresh_pattern_panel() -> void:
	if pattern_claim_panel == null:
		return
	var active: bool = chart_canvas.get_drawing_tool() == "pattern_claim"
	pattern_claim_panel.visible = active
	if not active:
		return
	if _company_snapshot.is_empty():
		pattern_status_label.text = "Choose a stock first."
		_set_pattern_feedback("No chart loaded.", COLOR_MUTED)
		_refresh_pattern_destination_controls(false)
		return
	pattern_status_label.text = "Mark two points on the chart for %s." % str(_company_snapshot.get("ticker", "this stock"))
	if _last_pattern_claim.is_empty():
		_set_pattern_feedback("No pattern region marked yet.", COLOR_MUTED)
	else:
		_apply_pattern_feedback_text(_last_pattern_claim)
	_refresh_pattern_destination_controls(bool(_last_pattern_claim.get("success", false)))


func _on_pattern_option_selected(_index: int) -> void:
	var region: Dictionary = chart_canvas.get_pattern_claim_region()
	if region.is_empty():
		_last_pattern_claim.clear()
		_refresh_pattern_panel()
		return
	_evaluate_chart_pattern_region(region.get("start", {}), region.get("end", {}))


func _on_chart_pattern_region_selected(start_anchor: Dictionary, end_anchor: Dictionary) -> void:
	_evaluate_chart_pattern_region(start_anchor, end_anchor)


func _evaluate_chart_pattern_region(start_anchor: Dictionary, end_anchor: Dictionary) -> void:
	if _company_snapshot.is_empty():
		_last_pattern_claim = {"success": false, "message": "Choose a stock first."}
		_refresh_pattern_panel()
		return
	var pattern_id: String = _selected_pattern_id()
	if pattern_id.is_empty():
		_last_pattern_claim = {"success": false, "message": "Choose a pattern type first."}
		_refresh_pattern_panel()
		return
	_last_pattern_claim = GameManager.evaluate_chart_pattern_claim(
		str(_company_snapshot.get("id", "")),
		_selected_range_id,
		pattern_id,
		start_anchor,
		end_anchor
	)
	_refresh_pattern_panel()


func _refresh_pattern_destination_controls(has_claim: bool) -> void:
	if pattern_thesis_option == null or pattern_add_to_thesis_button == null:
		return
	pattern_thesis_option.clear()
	_pattern_thesis_rows.clear()
	var company_id: String = str(_company_snapshot.get("id", ""))
	if company_id.is_empty():
		pattern_thesis_option.add_item("No stock selected")
		pattern_thesis_option.disabled = true
		pattern_add_to_thesis_button.disabled = true
		return
	_pattern_thesis_rows = GameManager.get_open_theses_for_company(company_id)
	if _pattern_thesis_rows.is_empty():
		pattern_thesis_option.add_item("No open thesis")
		pattern_thesis_option.disabled = true
		pattern_add_to_thesis_button.disabled = true
		pattern_add_to_thesis_button.tooltip_text = "Create a thesis for this stock in Thesis Board first."
		if has_claim:
			pattern_status_label.text = "Create a thesis for this stock in Thesis Board first."
		return
	for thesis_value in _pattern_thesis_rows:
		if typeof(thesis_value) != TYPE_DICTIONARY:
			continue
		var thesis: Dictionary = thesis_value
		var index: int = pattern_thesis_option.item_count
		pattern_thesis_option.add_item("%s  |  %s" % [str(thesis.get("title", "Thesis")), str(thesis.get("stance", "")).capitalize()])
		pattern_thesis_option.set_item_metadata(index, str(thesis.get("id", "")))
	pattern_thesis_option.disabled = _pattern_thesis_rows.size() <= 1
	pattern_add_to_thesis_button.disabled = not has_claim
	pattern_add_to_thesis_button.tooltip_text = "" if has_claim else "Mark a pattern region before adding evidence."


func _on_add_pattern_to_thesis_pressed() -> void:
	if _last_pattern_claim.is_empty() or not bool(_last_pattern_claim.get("success", false)):
		_set_pattern_feedback("Complete a pattern claim first.", COLOR_WARNING)
		return
	var thesis_id: String = _selected_pattern_thesis_id()
	if thesis_id.is_empty():
		_set_pattern_feedback("Create a thesis for this stock in Thesis Board first.", COLOR_WARNING)
		return
	var result: Dictionary = GameManager.add_chart_pattern_evidence_to_thesis(thesis_id, _last_pattern_claim)
	if bool(result.get("success", false)):
		_set_pattern_feedback("Added to Thesis as Price Action evidence.", COLOR_POSITIVE)
	else:
		_set_pattern_feedback(str(result.get("message", "Could not add pattern evidence.")), COLOR_WARNING)
	_refresh_pattern_destination_controls(bool(_last_pattern_claim.get("success", false)))


func _selected_pattern_id() -> String:
	if pattern_option_button == null or pattern_option_button.item_count <= 0:
		return ""
	var selected_index: int = pattern_option_button.selected
	if selected_index < 0:
		selected_index = 0
	return str(pattern_option_button.get_item_metadata(selected_index))


func _selected_pattern_thesis_id() -> String:
	if pattern_thesis_option == null or pattern_thesis_option.item_count <= 0:
		return ""
	var selected_index: int = pattern_thesis_option.selected
	if selected_index < 0:
		selected_index = 0
	return str(pattern_thesis_option.get_item_metadata(selected_index))


func _apply_pattern_feedback_text(claim: Dictionary) -> void:
	if not bool(claim.get("success", false)):
		_set_pattern_feedback(str(claim.get("message", claim.get("detail", "Pattern read is not ready."))), COLOR_WARNING)
		return
	var state: String = str(claim.get("feedback_state", claim.get("value", "")))
	var reason: String = str(claim.get("feedback_reason", ""))
	var invalidation: String = str(claim.get("invalidation", ""))
	var text: String = "%s" % state
	if not reason.is_empty():
		text += "\n%s" % reason
	if not invalidation.is_empty():
		text += "\nInvalidation: %s" % invalidation
	_set_pattern_feedback(text, _color_for_pattern_state(state))


func _set_pattern_feedback(text: String, color: Color) -> void:
	if pattern_feedback_label == null:
		return
	pattern_feedback_label.text = text
	pattern_feedback_label.add_theme_color_override("font_color", color)


func _color_for_pattern_state(state: String) -> Color:
	match state:
		"Good read":
			return COLOR_POSITIVE
		"Plausible, needs confirmation":
			return COLOR_WARNING
		"Weak read":
			return COLOR_MUTED
		"Contradicted":
			return COLOR_NEGATIVE
	return COLOR_MUTED


func _on_thesis_changed() -> void:
	_refresh_pattern_panel()


func _make_pattern_panel_label(text: String, color: Color, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _style_pattern_claim_panel(panel: PanelContainer) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0666667, 0.0941176, 0.12549, 0.98)
	style.border_color = COLOR_BORDER
	style.set_border_width_all(1)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_right = 7
	style.corner_radius_bottom_left = 7
	panel.add_theme_stylebox_override("panel", style)


func _decorate_chart_snapshot(chart_snapshot: Dictionary) -> Dictionary:
	var decorated_snapshot: Dictionary = chart_snapshot.duplicate(true)
	decorated_snapshot["display_mode"] = _chart_display_mode
	var primary_color: Color = _color_for_change(float(chart_snapshot.get("change_pct", 0.0)))
	if primary_color == COLOR_WARNING:
		primary_color = COLOR_ACCENT

	var plot_palette := {
		"close": primary_color,
		"sma_20": Color(0.980392, 0.792157, 0.392157, 1),
		"ema_20": Color(0.854902, 0.576471, 0.964706, 1),
		"sma_50": Color(0.556863, 0.85098, 0.980392, 1),
		"rsi_14": Color(0.513726, 0.886275, 0.662745, 1)
	}
	var decorated_plots: Array = []
	for plot_value in chart_snapshot.get("plots", []):
		var plot: Dictionary = plot_value.duplicate(true)
		var plot_id: String = str(plot.get("id", ""))
		plot["color"] = plot_palette.get(plot_id, COLOR_ACCENT)
		decorated_plots.append(plot)
	decorated_snapshot["plots"] = decorated_plots
	return decorated_snapshot


func _ensure_indicator_row() -> void:
	if indicator_row != null:
		return
	var chart_tab: Control = work_tabs.get_node("Chart")
	var range_row: Control = chart_tab.get_node("ChartRangeRow")
	indicator_row = HBoxContainer.new()
	indicator_row.name = "ChartIndicatorRow"
	indicator_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	indicator_row.add_theme_constant_override("separation", 8)
	chart_tab.add_child(indicator_row)
	chart_tab.move_child(indicator_row, range_row.get_index() + 1)


func _refresh_indicator_controls() -> void:
	if indicator_row == null:
		return
	for child in indicator_row.get_children():
		indicator_row.remove_child(child)
		child.queue_free()
	_indicator_buttons.clear()

	var catalog: Array = GameManager.get_chart_indicator_catalog()
	if catalog.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Indicators locked"
		empty_label.add_theme_color_override("font_color", COLOR_MUTED)
		indicator_row.add_child(empty_label)
		return

	for indicator_value in catalog:
		var indicator: Dictionary = indicator_value
		var indicator_id: String = str(indicator.get("id", ""))
		if indicator_id.is_empty():
			continue
		var unlocked: bool = bool(indicator.get("unlocked", false))
		var button: CheckButton = CheckButton.new()
		button.name = "IndicatorToggle_%s" % indicator_id
		button.text = str(indicator.get("label", indicator_id.to_upper())) if unlocked else "%s locked" % str(indicator.get("label", indicator_id.to_upper()))
		button.disabled = not unlocked
		button.button_pressed = unlocked and _active_indicator_ids.has(indicator_id)
		button.tooltip_text = "Unlocked by Chart Indicators upgrades." if not unlocked else "Toggle %s." % str(indicator.get("label", indicator_id.to_upper()))
		button.toggled.connect(_on_indicator_toggled.bind(indicator_id))
		indicator_row.add_child(button)
		_indicator_buttons[indicator_id] = button


func _on_indicator_toggled(is_pressed: bool, indicator_id: String) -> void:
	if is_pressed:
		if not _active_indicator_ids.has(indicator_id):
			_active_indicator_ids.append(indicator_id)
	else:
		_active_indicator_ids.erase(indicator_id)
	_active_indicator_ids = _filter_unlocked_indicator_ids(_active_indicator_ids)
	_refresh_chart()


func _filter_unlocked_indicator_ids(indicator_ids: Array) -> Array:
	var unlocked_lookup: Dictionary = {}
	for indicator_value in GameManager.get_chart_indicator_catalog():
		var indicator: Dictionary = indicator_value
		if bool(indicator.get("unlocked", false)):
			unlocked_lookup[str(indicator.get("id", ""))] = true
	var filtered: Array = []
	for indicator_id_value in indicator_ids:
		var indicator_id: String = str(indicator_id_value)
		if unlocked_lookup.has(indicator_id) and not filtered.has(indicator_id):
			filtered.append(indicator_id)
	return filtered


func _style_chart_range_button(button: Button) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.0823529, 0.117647, 0.156863, 0.92)
	normal.border_color = COLOR_BORDER
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 7
	normal.corner_radius_top_right = 7
	normal.corner_radius_bottom_right = 7
	normal.corner_radius_bottom_left = 7
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.1)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(0.215686, 0.34902, 0.482353, 0.98)
	pressed.border_color = Color(0.690196, 0.87451, 1, 1)
	pressed.set_border_width_all(2)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", pressed)
	button.add_theme_color_override("font_color", COLOR_MUTED)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", Color(0.972549, 0.988235, 1, 1))
	button.add_theme_color_override("font_focus_color", Color(0.972549, 0.988235, 1, 1))


func _build_chart_meta_text(chart_snapshot: Dictionary) -> String:
	var start_date_text: String = GameManager.format_trade_date(chart_snapshot.get("start_date", {}))
	var end_date_text: String = GameManager.format_trade_date(chart_snapshot.get("end_date", {}))
	var enabled_indicator_count: int = int(chart_snapshot.get("enabled_indicator_ids", []).size())
	var indicator_text: String = "Indicators %d" % enabled_indicator_count if enabled_indicator_count > 0 else "Indicators locked"
	return "%s | %d bars | %s -> %s | Low %s | High %s | Start %s | Last %s | Move %s | Since start %s | YTD %s | %s" % [
		str(chart_snapshot.get("range_label", GameManager.get_chart_range_label(_selected_range_id))),
		int(chart_snapshot.get("visible_bar_count", 0)),
		start_date_text,
		end_date_text,
		_format_currency(float(chart_snapshot.get("low_price", 0.0))),
		_format_currency(float(chart_snapshot.get("high_price", 0.0))),
		_format_currency(float(chart_snapshot.get("start_price", 0.0))),
		_format_currency(float(chart_snapshot.get("end_price", 0.0))),
		_format_change(float(chart_snapshot.get("change_pct", 0.0))),
		_format_change(float(_company_snapshot.get("since_start_pct", 0.0))),
		_format_change(float(_company_snapshot.get("ytd_change_pct", 0.0))),
		indicator_text
	]


func _color_for_change(change_pct: float) -> Color:
	if change_pct > 0.0005:
		return COLOR_POSITIVE
	if change_pct < -0.0005:
		return COLOR_NEGATIVE
	return COLOR_WARNING


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


func _format_change(change_pct: float) -> String:
	return "%+.2f%%" % [change_pct * 100.0]
