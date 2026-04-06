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

@onready var work_tabs: TabContainer = $WorkAreaMargin/WorkAreaVBox/WorkTabs
@onready var chart_header_label: Label = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartHeaderLabel
@onready var chart_subheader_label: Label = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartSubheaderLabel
@onready var chart_meta_label: Label = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartMetaLabel
@onready var chart_canvas: PriceChartCanvas = $WorkAreaMargin/WorkAreaVBox/WorkTabs/Chart/ChartCanvas
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


func _ready() -> void:
	work_tabs.set_tab_title(0, "Chart")
	work_tabs.set_tab_title(1, "Key Stats")
	work_tabs.set_tab_title(2, "Financials")
	work_tabs.set_tab_title(3, "Analyzer")
	work_tabs.set_tab_title(4, "Profile")
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
	for button_value in _chart_range_button_map().values():
		_style_chart_range_button(button_value)
	_style_chart_range_button(display_line_button)
	_style_chart_range_button(display_candle_button)
	_style_chart_range_button(zoom_out_button)
	_style_chart_range_button(zoom_in_button)
	chart_header_label.add_theme_color_override("font_color", COLOR_TEXT)
	chart_subheader_label.add_theme_color_override("font_color", COLOR_MUTED)
	chart_subheader_label.visible = false
	chart_meta_label.add_theme_color_override("font_color", COLOR_MUTED)
	_update_chart_range_buttons()
	_update_chart_display_mode_buttons()
	_update_zoom_buttons()


func set_company_snapshot(snapshot: Dictionary) -> void:
	var previous_company_id: String = str(_company_snapshot.get("id", ""))
	var next_company_id: String = str(snapshot.get("id", ""))
	_company_snapshot = snapshot
	if previous_company_id != next_company_id or next_company_id.is_empty():
		chart_canvas.reset_zoom()
	_refresh_chart()


func set_active_indicator_ids(indicator_ids: Array) -> void:
	_active_indicator_ids = indicator_ids.duplicate()
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
		_update_chart_display_mode_buttons()
		_update_zoom_buttons()
		return

	var chart_snapshot: Dictionary = GameManager.get_company_chart_snapshot(
		str(_company_snapshot.get("id", "")),
		_selected_range_id,
		_active_indicator_ids
	)
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
		chart_meta_label.text = "%s | Not enough price history yet." % GameManager.get_chart_range_label(_selected_range_id)
		chart_canvas.clear_chart()
		_update_chart_display_mode_buttons()
		_update_zoom_buttons()
		return

	chart_meta_label.text = _build_chart_meta_text(chart_snapshot)
	chart_canvas.set_chart_snapshot(_decorate_chart_snapshot(chart_snapshot))
	_update_chart_display_mode_buttons()
	_update_zoom_buttons()


func _bind_chart_range_button(button: Button, range_id: String) -> void:
	button.pressed.connect(func() -> void:
		_on_chart_range_pressed(range_id)
	)


func _on_chart_range_pressed(range_id: String) -> void:
	_selected_range_id = str(range_id).to_lower()
	chart_canvas.reset_zoom()
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
		"sma_50": Color(0.556863, 0.85098, 0.980392, 1)
	}
	var decorated_plots: Array = []
	for plot_value in chart_snapshot.get("plots", []):
		var plot: Dictionary = plot_value.duplicate(true)
		var plot_id: String = str(plot.get("id", ""))
		plot["color"] = plot_palette.get(plot_id, COLOR_ACCENT)
		decorated_plots.append(plot)
	decorated_snapshot["plots"] = decorated_plots
	return decorated_snapshot


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
	return "Rp %s" % String.num(value, 2)


func _format_change(change_pct: float) -> String:
	return "%+.2f%%" % [change_pct * 100.0]
