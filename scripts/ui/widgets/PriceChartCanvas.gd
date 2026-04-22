extends Control
class_name PriceChartCanvas

const CHART_BACKGROUND := Color(0.0431373, 0.0588235, 0.0862745, 0.98)
const CHART_BORDER := Color(0.184314, 0.247059, 0.309804, 0.95)
const GRID_COLOR := Color(0.172549, 0.223529, 0.282353, 0.55)
const BASELINE_COLOR := Color(0.560784, 0.772549, 1, 0.45)
const AXIS_TEXT_COLOR := Color(0.807843, 0.85098, 0.909804, 0.92)
const AXIS_LINE_COLOR := Color(0.231373, 0.290196, 0.356863, 0.9)
const CANDLE_UP_COLOR := Color(0.513726, 0.886275, 0.662745, 0.98)
const CANDLE_DOWN_COLOR := Color(0.968627, 0.513726, 0.513726, 0.98)
const CROSSHAIR_COLOR := Color(0.819608, 0.890196, 0.984314, 0.45)
const HOVER_PANEL_FILL := Color(0.0705882, 0.105882, 0.145098, 0.94)
const HOVER_PANEL_BORDER := Color(0.333333, 0.462745, 0.580392, 0.92)
const HOVER_PANEL_TEXT := Color(0.956863, 0.976471, 1, 1)
const PLOT_MARGIN_LEFT := 16.0
const PLOT_MARGIN_TOP := 14.0
const PLOT_MARGIN_RIGHT := 76.0
const PLOT_MARGIN_BOTTOM := 34.0
const AXIS_FONT_SIZE := 11
const Y_TICK_COUNT := 5
const X_TICK_COUNT := 6
const VOLUME_PANEL_RATIO := 0.22
const VOLUME_PANEL_MIN_HEIGHT := 52.0
const VOLUME_PANEL_MAX_HEIGHT := 88.0
const VOLUME_PANEL_GAP := 12.0
const VOLUME_BAR_ALPHA := 0.62
const INDICATOR_PANEL_HEIGHT := 64.0
const INDICATOR_PANEL_GAP := 10.0
const ZOOM_FRACTIONS := [1.0, 0.75, 0.5, 0.33, 0.2, 0.125]
const MONTH_NAMES := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

var _plots: Array = []
var _baseline_value: float = 0.0
var _bars: Array = []
var _range_id: String = "1m"
var _display_mode: String = "line"
var _zoom_level_index: int = 0
var _hover_active: bool = false
var _hover_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	mouse_exited.connect(_clear_hover_state)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hover_active = true
		_hover_position = (event as InputEventMouseMotion).position
		queue_redraw()
	elif event is InputEventMouseButton:
		_hover_active = true
		_hover_position = (event as InputEventMouseButton).position
		queue_redraw()


func set_chart_series(series: Array, baseline_value: float, line_color: Color) -> void:
	set_chart_snapshot({
		"baseline_value": baseline_value,
		"plots": [{
			"id": "close",
			"plot_kind": "price",
			"style": "line",
			"fill": true,
			"color": line_color,
			"values": series.duplicate(),
			"line_width": 2.5
		}]
	})


func set_chart_snapshot(chart_snapshot: Dictionary) -> void:
	_plots.clear()
	_baseline_value = float(chart_snapshot.get("baseline_value", 0.0))
	_bars = chart_snapshot.get("bars", []).duplicate(true)
	_range_id = str(chart_snapshot.get("range_id", "1m")).to_lower()
	_display_mode = str(chart_snapshot.get("display_mode", "line")).to_lower()
	for plot_value in chart_snapshot.get("plots", []):
		if typeof(plot_value) != TYPE_DICTIONARY:
			continue
		_plots.append(plot_value.duplicate(true))
	queue_redraw()


func clear_chart() -> void:
	_plots.clear()
	_baseline_value = 0.0
	_bars.clear()
	_range_id = "1m"
	_display_mode = "line"
	_zoom_level_index = 0
	_clear_hover_state()
	queue_redraw()


func _draw() -> void:
	var outer_rect := Rect2(Vector2.ZERO, size)
	draw_rect(outer_rect, CHART_BACKGROUND, true)
	draw_rect(outer_rect, CHART_BORDER, false, 1.0)

	var plot_rect := Rect2(
		Vector2(PLOT_MARGIN_LEFT, PLOT_MARGIN_TOP),
		size - Vector2(PLOT_MARGIN_LEFT + PLOT_MARGIN_RIGHT, PLOT_MARGIN_TOP + PLOT_MARGIN_BOTTOM)
	)
	if plot_rect.size.x <= 0.0 or plot_rect.size.y <= 0.0:
		return

	if _plots.is_empty():
		return

	var visible_context: Dictionary = _build_visible_context()
	var visible_bars: Array = visible_context.get("bars", [])
	var visible_plots: Array = visible_context.get("plots", [])
	if visible_plots.is_empty():
		return
	var price_plots: Array = _plots_for_kind(visible_plots, false)
	var panel_plots: Array = _plots_for_kind(visible_plots, true)
	if price_plots.is_empty():
		return

	var bounds: Dictionary = _resolve_plot_bounds(price_plots, visible_bars)
	if bool(bounds.get("empty", true)):
		return
	var min_value: float = float(bounds.get("min", 0.0))
	var max_value: float = float(bounds.get("max", 0.0))
	var layout: Dictionary = _build_chart_layout(plot_rect, visible_bars, not panel_plots.is_empty())
	var price_rect: Rect2 = layout.get("price_rect", plot_rect)
	var indicator_rect: Rect2 = layout.get("indicator_rect", Rect2())
	var volume_rect: Rect2 = layout.get("volume_rect", Rect2())
	var x_axis_rect: Rect2 = volume_rect if volume_rect.size.y > 0.0 else price_rect
	if x_axis_rect == price_rect and indicator_rect.size.y > 0.0:
		x_axis_rect = indicator_rect
	var grid_rect := Rect2(
		price_rect.position,
		Vector2(price_rect.size.x, max(x_axis_rect.end.y - price_rect.position.y, price_rect.size.y))
	)

	if is_equal_approx(min_value, max_value):
		var single_value_padding: float = max(abs(min_value) * 0.05, 1.0)
		min_value -= single_value_padding
		max_value += single_value_padding
	else:
		var padding: float = (max_value - min_value) * 0.12
		min_value -= padding
		max_value += padding

	_draw_y_axis(price_rect, min_value, max_value)
	_draw_x_axis(x_axis_rect, visible_bars, grid_rect)
	if volume_rect.size.y > 0.0:
		_draw_volume_bars(visible_bars, volume_rect)
	if indicator_rect.size.y > 0.0:
		_draw_indicator_panel(panel_plots, indicator_rect)

	if not is_zero_approx(_baseline_value):
		var baseline_y: float = _value_to_plot_y(_baseline_value, min_value, max_value, price_rect)
		draw_line(
			Vector2(price_rect.position.x, baseline_y),
			Vector2(price_rect.end.x, baseline_y),
			BASELINE_COLOR,
			1.0
		)

	if _display_mode == "candle":
		_draw_candlesticks(visible_bars, price_rect, min_value, max_value)

	for plot_index in range(price_plots.size()):
		var plot: Dictionary = price_plots[plot_index]
		var plot_id: String = str(plot.get("id", ""))
		if _display_mode == "candle" and plot_id == "close":
			continue
		_draw_plot(plot, price_rect, min_value, max_value, _display_mode != "candle" and plot_id == "close")

	_draw_hover_overlay(price_rect, visible_bars, min_value, max_value, grid_rect, x_axis_rect)


func _value_to_plot_y(value: float, min_value: float, max_value: float, plot_rect: Rect2) -> float:
	var normalized: float = 0.5
	if not is_equal_approx(max_value, min_value):
		normalized = clamp((value - min_value) / (max_value - min_value), 0.0, 1.0)
	return plot_rect.end.y - (normalized * plot_rect.size.y)


func _plot_y_to_value(y_position: float, min_value: float, max_value: float, plot_rect: Rect2) -> float:
	if is_equal_approx(max_value, min_value):
		return min_value
	var normalized: float = clamp((plot_rect.end.y - y_position) / max(plot_rect.size.y, 1.0), 0.0, 1.0)
	return lerp(min_value, max_value, normalized)


func _resolve_plot_bounds(plots: Array, bars: Array) -> Dictionary:
	var has_value: bool = false
	var min_value: float = 0.0
	var max_value: float = 0.0
	if _display_mode == "candle":
		for bar_value in bars:
			var bar: Dictionary = bar_value
			var high_value: float = float(bar.get("high", bar.get("close", 0.0)))
			var low_value: float = float(bar.get("low", bar.get("close", 0.0)))
			if not has_value:
				has_value = true
				min_value = low_value
				max_value = high_value
			else:
				min_value = min(min_value, low_value)
				max_value = max(max_value, high_value)
	for plot_value in plots:
		var plot: Dictionary = plot_value
		for value_variant in plot.get("values", []):
			if typeof(value_variant) != TYPE_FLOAT and typeof(value_variant) != TYPE_INT:
				continue
			var point_value: float = float(value_variant)
			if not has_value:
				has_value = true
				min_value = point_value
				max_value = point_value
			else:
				min_value = min(min_value, point_value)
				max_value = max(max_value, point_value)

	return {
		"empty": not has_value,
		"min": min_value,
		"max": max_value
	}


func _build_chart_layout(plot_rect: Rect2, visible_bars: Array, has_indicator_panel: bool = false) -> Dictionary:
	var price_rect: Rect2 = plot_rect
	var indicator_rect := Rect2()
	var volume_rect := Rect2()
	var used_bottom_height: float = 0.0
	var bottom_cursor: float = plot_rect.end.y

	if _has_visible_volume(visible_bars):
		var volume_height: float = clamp(
			plot_rect.size.y * VOLUME_PANEL_RATIO,
			VOLUME_PANEL_MIN_HEIGHT,
			VOLUME_PANEL_MAX_HEIGHT
		)
		volume_rect = Rect2(
			Vector2(plot_rect.position.x, bottom_cursor - volume_height),
			Vector2(plot_rect.size.x, volume_height)
		)
		bottom_cursor = volume_rect.position.y - VOLUME_PANEL_GAP
		used_bottom_height += volume_height + VOLUME_PANEL_GAP

	if has_indicator_panel:
		var panel_height: float = min(INDICATOR_PANEL_HEIGHT, max(plot_rect.size.y - used_bottom_height - 100.0, 0.0))
		if panel_height >= 40.0:
			indicator_rect = Rect2(
				Vector2(plot_rect.position.x, bottom_cursor - panel_height),
				Vector2(plot_rect.size.x, panel_height)
			)
			bottom_cursor = indicator_rect.position.y - INDICATOR_PANEL_GAP
			used_bottom_height += panel_height + INDICATOR_PANEL_GAP

	var price_height: float = bottom_cursor - plot_rect.position.y
	if price_height < 90.0:
		return {
			"price_rect": price_rect,
			"indicator_rect": Rect2(),
			"volume_rect": volume_rect
		}

	price_rect = Rect2(plot_rect.position, Vector2(plot_rect.size.x, price_height))
	return {
		"price_rect": price_rect,
		"indicator_rect": indicator_rect,
		"volume_rect": volume_rect
	}


func _has_visible_volume(visible_bars: Array) -> bool:
	for bar_value in visible_bars:
		if typeof(bar_value) != TYPE_DICTIONARY:
			continue
		var bar: Dictionary = bar_value
		if int(bar.get("volume_shares", 0)) > 0:
			return true
	return false


func _draw_candlesticks(visible_bars: Array, plot_rect: Rect2, min_value: float, max_value: float) -> void:
	if visible_bars.is_empty():
		return

	var bar_count: int = visible_bars.size()
	var slot_width: float = plot_rect.size.x / float(max(bar_count, 1))
	var candle_width: float = clamp(slot_width * 0.62, 3.0, 18.0)
	for bar_index in range(bar_count):
		var bar: Dictionary = visible_bars[bar_index]
		var open_price: float = float(bar.get("open", bar.get("close", 0.0)))
		var close_price: float = float(bar.get("close", open_price))
		var high_price: float = float(bar.get("high", max(open_price, close_price)))
		var low_price: float = float(bar.get("low", min(open_price, close_price)))
		var center_x: float = plot_rect.position.x + (slot_width * (float(bar_index) + 0.5))
		var high_y: float = _value_to_plot_y(high_price, min_value, max_value, plot_rect)
		var low_y: float = _value_to_plot_y(low_price, min_value, max_value, plot_rect)
		var open_y: float = _value_to_plot_y(open_price, min_value, max_value, plot_rect)
		var close_y: float = _value_to_plot_y(close_price, min_value, max_value, plot_rect)
		var candle_color: Color = CANDLE_UP_COLOR if close_price >= open_price else CANDLE_DOWN_COLOR

		draw_line(
			Vector2(center_x, high_y),
			Vector2(center_x, low_y),
			candle_color,
			1.2
		)

		var body_top: float = min(open_y, close_y)
		var body_height: float = max(absf(close_y - open_y), 1.5)
		var body_rect := Rect2(
			Vector2(center_x - (candle_width * 0.5), body_top),
			Vector2(candle_width, body_height)
		)
		draw_rect(body_rect, candle_color, true)
		draw_rect(body_rect, candle_color.darkened(0.18), false, 1.0)


func _draw_volume_bars(visible_bars: Array, volume_rect: Rect2) -> void:
	if visible_bars.is_empty() or volume_rect.size.y <= 0.0:
		return

	var max_volume: int = 0
	for bar_value in visible_bars:
		if typeof(bar_value) != TYPE_DICTIONARY:
			continue
		var bar: Dictionary = bar_value
		max_volume = max(max_volume, int(bar.get("volume_shares", 0)))
	if max_volume <= 0:
		return

	draw_line(
		Vector2(volume_rect.position.x, volume_rect.position.y),
		Vector2(volume_rect.end.x, volume_rect.position.y),
		AXIS_LINE_COLOR,
		1.0
	)
	draw_line(
		Vector2(volume_rect.position.x, volume_rect.position.y + volume_rect.size.y * 0.5),
		Vector2(volume_rect.end.x, volume_rect.position.y + volume_rect.size.y * 0.5),
		Color(GRID_COLOR.r, GRID_COLOR.g, GRID_COLOR.b, 0.34),
		1.0
	)

	var bar_count: int = visible_bars.size()
	var slot_width: float = volume_rect.size.x / float(max(bar_count, 1))
	var bar_width: float = clamp(slot_width * 0.62, 1.0, 16.0)
	var drawable_height: float = max(volume_rect.size.y - 4.0, 1.0)
	for bar_index in range(bar_count):
		var bar: Dictionary = visible_bars[bar_index]
		var volume_shares: int = int(bar.get("volume_shares", 0))
		if volume_shares <= 0:
			continue

		var open_price: float = float(bar.get("open", bar.get("close", 0.0)))
		var close_price: float = float(bar.get("close", open_price))
		var base_color: Color = CANDLE_UP_COLOR if close_price >= open_price else CANDLE_DOWN_COLOR
		var volume_color := Color(base_color.r, base_color.g, base_color.b, VOLUME_BAR_ALPHA)
		var volume_ratio: float = clamp(float(volume_shares) / float(max_volume), 0.0, 1.0)
		var bar_height: float = max(volume_ratio * drawable_height, 1.0)
		var center_x: float = volume_rect.position.x + (slot_width * (float(bar_index) + 0.5))
		var bar_rect := Rect2(
			Vector2(center_x - (bar_width * 0.5), volume_rect.end.y - bar_height),
			Vector2(bar_width, bar_height)
		)
		draw_rect(bar_rect, volume_color, true)


func _draw_indicator_panel(panel_plots: Array, panel_rect: Rect2) -> void:
	if panel_plots.is_empty() or panel_rect.size.y <= 0.0:
		return

	draw_rect(panel_rect, Color(CHART_BACKGROUND.r, CHART_BACKGROUND.g, CHART_BACKGROUND.b, 0.55), true)
	draw_line(panel_rect.position, Vector2(panel_rect.end.x, panel_rect.position.y), AXIS_LINE_COLOR, 1.0)
	for guide_value in [30.0, 50.0, 70.0]:
		var guide_y: float = _value_to_plot_y(guide_value, 0.0, 100.0, panel_rect)
		draw_line(
			Vector2(panel_rect.position.x, guide_y),
			Vector2(panel_rect.end.x, guide_y),
			Color(GRID_COLOR.r, GRID_COLOR.g, GRID_COLOR.b, 0.42),
			1.0
		)
	for plot_value in panel_plots:
		var plot: Dictionary = plot_value
		_draw_plot(plot, panel_rect, 0.0, 100.0, false)


func _draw_hover_overlay(
	plot_rect: Rect2,
	visible_bars: Array,
	min_value: float,
	max_value: float,
	interaction_rect: Rect2,
	date_axis_rect: Rect2
) -> void:
	var hover_state: Dictionary = _build_hover_state(interaction_rect, plot_rect, visible_bars, min_value, max_value)
	if hover_state.is_empty():
		return

	var font: Font = _get_chart_font()
	if font == null:
		return

	var crosshair_x: float = float(hover_state.get("x", plot_rect.position.x))
	var crosshair_y: float = float(hover_state.get("y", plot_rect.position.y))
	if bool(hover_state.get("pointer_in_price", true)):
		draw_line(
			Vector2(plot_rect.position.x, crosshair_y),
			Vector2(plot_rect.end.x, crosshair_y),
			CROSSHAIR_COLOR,
			1.0
		)
	draw_line(
		Vector2(crosshair_x, interaction_rect.position.y),
		Vector2(crosshair_x, interaction_rect.end.y),
		CROSSHAIR_COLOR,
		1.0
	)

	var hovered_bar: Dictionary = hover_state.get("bar", {})
	var close_price: float = float(hovered_bar.get("close", 0.0))
	var close_y: float = _value_to_plot_y(close_price, min_value, max_value, plot_rect)
	var candle_color: Color = CANDLE_UP_COLOR if close_price >= float(hovered_bar.get("open", close_price)) else CANDLE_DOWN_COLOR
	draw_circle(Vector2(crosshair_x, close_y), 3.5, candle_color)

	if bool(hover_state.get("pointer_in_price", true)):
		_draw_hover_price_label(font, hover_state, plot_rect)
	_draw_hover_date_label(font, hover_state, date_axis_rect)
	_draw_hover_info_panel(font, hover_state, plot_rect)


func _draw_plot(plot: Dictionary, plot_rect: Rect2, min_value: float, max_value: float, draw_last_point: bool) -> void:
	var values: Array = plot.get("values", []).duplicate()
	if values.is_empty():
		return

	var line_color: Color = plot.get("color", Color(0.560784, 0.772549, 1, 1))
	var line_width: float = float(plot.get("line_width", 2.0))
	var segments: Array = _build_plot_segments(values, plot_rect, min_value, max_value)
	for segment_value in segments:
		var segment: PackedVector2Array = segment_value
		if segment.size() >= 2:
			if bool(plot.get("fill", false)):
				var fill_points: PackedVector2Array = segment.duplicate()
				fill_points.append(Vector2(segment[segment.size() - 1].x, plot_rect.end.y))
				fill_points.append(Vector2(segment[0].x, plot_rect.end.y))
				draw_colored_polygon(fill_points, Color(line_color.r, line_color.g, line_color.b, 0.14))
			draw_polyline(segment, line_color, line_width, true)
		if draw_last_point and segment.size() >= 1:
			draw_circle(segment[segment.size() - 1], 4.0, line_color)


func _build_plot_segments(values: Array, plot_rect: Rect2, min_value: float, max_value: float) -> Array:
	var segments: Array = []
	var current_segment: PackedVector2Array = PackedVector2Array()
	var last_index: int = max(values.size() - 1, 1)
	for index in range(values.size()):
		var value_variant = values[index]
		if typeof(value_variant) != TYPE_FLOAT and typeof(value_variant) != TYPE_INT:
			if current_segment.size() >= 1:
				segments.append(current_segment)
			current_segment = PackedVector2Array()
			continue

		var x_position: float = plot_rect.position.x + (plot_rect.size.x * float(index) / float(last_index))
		var y_position: float = _value_to_plot_y(float(value_variant), min_value, max_value, plot_rect)
		current_segment.append(Vector2(x_position, y_position))
	if current_segment.size() >= 1:
		segments.append(current_segment)
	return segments


func _plots_for_kind(plots: Array, wants_panel: bool) -> Array:
	var filtered: Array = []
	for plot_value in plots:
		var plot: Dictionary = plot_value
		var is_panel: bool = str(plot.get("plot_kind", "")) == "panel"
		if is_panel == wants_panel:
			filtered.append(plot)
	return filtered


func _build_hover_state(
	interaction_rect: Rect2,
	price_rect: Rect2,
	visible_bars: Array,
	min_value: float,
	max_value: float
) -> Dictionary:
	if not _hover_active or visible_bars.is_empty() or not interaction_rect.has_point(_hover_position):
		return {}

	var bar_count: int = visible_bars.size()
	var slot_width: float = interaction_rect.size.x / float(max(bar_count, 1))
	if slot_width <= 0.0:
		return {}

	var relative_x: float = clamp(_hover_position.x - interaction_rect.position.x, 0.0, max(interaction_rect.size.x - 0.001, 0.0))
	var bar_index: int = clamp(int(floor(relative_x / slot_width)), 0, bar_count - 1)
	var crosshair_x: float = interaction_rect.position.x + (slot_width * (float(bar_index) + 0.5))
	var crosshair_y: float = clamp(_hover_position.y, price_rect.position.y, price_rect.end.y)
	var hovered_bar: Dictionary = visible_bars[bar_index]
	return {
		"index": bar_index,
		"bar": hovered_bar,
		"x": crosshair_x,
		"y": crosshair_y,
		"pointer_in_price": price_rect.has_point(_hover_position),
		"hover_price": _plot_y_to_value(crosshair_y, min_value, max_value, price_rect)
	}


func _draw_hover_price_label(font: Font, hover_state: Dictionary, plot_rect: Rect2) -> void:
	var label_text: String = _format_axis_price(float(hover_state.get("hover_price", 0.0)))
	var label_rect := Rect2(
		Vector2(plot_rect.end.x + 4, float(hover_state.get("y", plot_rect.position.y)) - 10),
		Vector2(PLOT_MARGIN_RIGHT - 8, 20)
	)
	draw_rect(label_rect, HOVER_PANEL_FILL, true)
	draw_rect(label_rect, HOVER_PANEL_BORDER, false, 1.0)
	draw_string(
		font,
		label_rect.position + Vector2(6, 13),
		label_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		label_rect.size.x - 12,
		AXIS_FONT_SIZE,
		HOVER_PANEL_TEXT
	)


func _draw_hover_date_label(font: Font, hover_state: Dictionary, plot_rect: Rect2) -> void:
	var hovered_bar: Dictionary = hover_state.get("bar", {})
	var trade_date: Dictionary = hovered_bar.get("trade_date", {})
	var label_text: String = _format_hover_date(trade_date)
	if label_text.is_empty():
		return

	var label_width: float = 86.0 if _range_id == "5y" else 94.0
	var label_x: float = clamp(
		float(hover_state.get("x", plot_rect.position.x)) - (label_width * 0.5),
		plot_rect.position.x,
		plot_rect.end.x - label_width
	)
	var label_rect := Rect2(
		Vector2(label_x, plot_rect.end.y + 4),
		Vector2(label_width, 22)
	)
	draw_rect(label_rect, HOVER_PANEL_FILL, true)
	draw_rect(label_rect, HOVER_PANEL_BORDER, false, 1.0)
	draw_string(
		font,
		label_rect.position + Vector2(6, 14),
		label_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		label_rect.size.x - 12,
		AXIS_FONT_SIZE,
		HOVER_PANEL_TEXT
	)


func _draw_hover_info_panel(font: Font, hover_state: Dictionary, plot_rect: Rect2) -> void:
	var hovered_bar: Dictionary = hover_state.get("bar", {})
	var open_price: float = float(hovered_bar.get("open", hovered_bar.get("close", 0.0)))
	var high_price: float = float(hovered_bar.get("high", open_price))
	var low_price: float = float(hovered_bar.get("low", open_price))
	var close_price: float = float(hovered_bar.get("close", open_price))
	var volume_text: String = _format_volume(int(hovered_bar.get("volume_shares", 0)))
	var limit_lock: String = str(hovered_bar.get("limit_lock", "")).to_upper()
	var info_rect := Rect2(
		plot_rect.position + Vector2(10, 10),
		Vector2(min(plot_rect.size.x - 20.0, 278.0), 56.0 if not limit_lock.is_empty() else 40.0)
	)
	draw_rect(info_rect, HOVER_PANEL_FILL, true)
	draw_rect(info_rect, HOVER_PANEL_BORDER, false, 1.0)

	var date_text: String = _format_hover_date(hovered_bar.get("trade_date", {}))
	var change_pct: float = 0.0
	if not is_zero_approx(open_price):
		change_pct = (close_price - open_price) / open_price
	var change_color: Color = CANDLE_UP_COLOR if change_pct >= 0.0 else CANDLE_DOWN_COLOR
	var line_one: String = "%s  O %s  H %s" % [
		date_text,
		_format_axis_price(open_price),
		_format_axis_price(high_price)
	]
	var line_two: String = "L %s  C %s  %s  Vol %s" % [
		_format_axis_price(low_price),
		_format_axis_price(close_price),
		_format_change_pct(change_pct),
		volume_text
	]
	draw_string(
		font,
		info_rect.position + Vector2(8, 13),
		line_one,
		HORIZONTAL_ALIGNMENT_LEFT,
		info_rect.size.x - 16,
		AXIS_FONT_SIZE,
		HOVER_PANEL_TEXT
	)
	draw_string(
		font,
		info_rect.position + Vector2(8, 28),
		line_two,
		HORIZONTAL_ALIGNMENT_LEFT,
		info_rect.size.x - 16,
		AXIS_FONT_SIZE,
		change_color
	)
	if not limit_lock.is_empty():
		var source_text: String = str(hovered_bar.get("limit_source", "")).replace("_", " ").capitalize()
		var line_three: String = "%s lock%s" % [
			limit_lock,
			"  " + source_text if not source_text.is_empty() else ""
		]
		draw_string(
			font,
			info_rect.position + Vector2(8, 43),
			line_three,
			HORIZONTAL_ALIGNMENT_LEFT,
			info_rect.size.x - 16,
			AXIS_FONT_SIZE,
			HOVER_PANEL_TEXT
		)


func zoom_in() -> void:
	if _bars.is_empty():
		return

	var current_count: int = _visible_bar_count_for_zoom_index(_bars.size(), _zoom_level_index)
	for next_index in range(_zoom_level_index + 1, ZOOM_FRACTIONS.size()):
		var next_count: int = _visible_bar_count_for_zoom_index(_bars.size(), next_index)
		if next_count < current_count:
			_zoom_level_index = next_index
			queue_redraw()
			return


func zoom_out() -> void:
	if _zoom_level_index <= 0:
		return
	_zoom_level_index -= 1
	queue_redraw()


func reset_zoom() -> void:
	if _zoom_level_index == 0:
		return
	_zoom_level_index = 0
	queue_redraw()


func can_zoom_in() -> bool:
	if _bars.is_empty():
		return false
	var current_count: int = _visible_bar_count_for_zoom_index(_bars.size(), _zoom_level_index)
	for next_index in range(_zoom_level_index + 1, ZOOM_FRACTIONS.size()):
		if _visible_bar_count_for_zoom_index(_bars.size(), next_index) < current_count:
			return true
	return false


func can_zoom_out() -> bool:
	return _zoom_level_index > 0


func _build_visible_context() -> Dictionary:
	var visible_plots: Array = []
	if _bars.is_empty():
		for plot_value in _plots:
			visible_plots.append(plot_value.duplicate(true))
		return {
			"bars": [],
			"plots": visible_plots
		}

	var full_bar_count: int = _bars.size()
	var visible_bar_count: int = _visible_bar_count_for_zoom_index(full_bar_count, _zoom_level_index)
	var start_bar_index: int = max(full_bar_count - visible_bar_count, 0)
	var visible_bars: Array = _bars.slice(start_bar_index, full_bar_count)
	for plot_value in _plots:
		var plot: Dictionary = plot_value.duplicate(true)
		var values: Array = plot.get("values", [])
		var slice_end_index: int = min(start_bar_index + visible_bar_count + 1, values.size())
		plot["values"] = values.slice(start_bar_index, slice_end_index)
		visible_plots.append(plot)
	return {
		"bars": visible_bars,
		"plots": visible_plots
	}


func _visible_bar_count_for_zoom_index(full_bar_count: int, zoom_level_index: int) -> int:
	if full_bar_count <= 0:
		return 0
	var safe_zoom_index: int = clamp(zoom_level_index, 0, ZOOM_FRACTIONS.size() - 1)
	return clamp(int(ceili(float(full_bar_count) * float(ZOOM_FRACTIONS[safe_zoom_index]))), 1, full_bar_count)


func _draw_y_axis(plot_rect: Rect2, min_value: float, max_value: float) -> void:
	var font: Font = _get_chart_font()
	if font == null:
		return

	var axis_x: float = plot_rect.end.x
	draw_line(
		Vector2(axis_x, plot_rect.position.y),
		Vector2(axis_x, plot_rect.end.y),
		AXIS_LINE_COLOR,
		1.0
	)

	for tick_index in range(Y_TICK_COUNT):
		var ratio: float = float(tick_index) / float(max(Y_TICK_COUNT - 1, 1))
		var tick_value: float = lerp(max_value, min_value, ratio)
		var y_position: float = _value_to_plot_y(tick_value, min_value, max_value, plot_rect)
		draw_line(
			Vector2(plot_rect.position.x, y_position),
			Vector2(plot_rect.end.x, y_position),
			GRID_COLOR,
			1.0
		)
		var label_rect := Rect2(
			Vector2(plot_rect.end.x + 8, y_position - 8),
			Vector2(PLOT_MARGIN_RIGHT - 12, 16)
		)
		draw_string(
			font,
			label_rect.position + Vector2(0, 10),
			_format_axis_price(tick_value),
			HORIZONTAL_ALIGNMENT_LEFT,
			label_rect.size.x,
			AXIS_FONT_SIZE,
			AXIS_TEXT_COLOR
		)


func _draw_x_axis(plot_rect: Rect2, visible_bars: Array, grid_rect: Rect2) -> void:
	var font: Font = _get_chart_font()
	if font == null or visible_bars.is_empty():
		return

	var axis_y: float = plot_rect.end.y
	draw_line(
		Vector2(plot_rect.position.x, axis_y),
		Vector2(plot_rect.end.x, axis_y),
		AXIS_LINE_COLOR,
		1.0
	)

	var tick_indexes: Array = _build_x_tick_indexes(visible_bars)
	for tick_index_value in tick_indexes:
		var bar_index: int = int(tick_index_value)
		var bar_midpoint_ratio: float = (float(bar_index) + 0.5) / float(max(visible_bars.size(), 1))
		var x_position: float = plot_rect.position.x + (plot_rect.size.x * bar_midpoint_ratio)
		draw_line(
			Vector2(x_position, grid_rect.position.y),
			Vector2(x_position, grid_rect.end.y),
			GRID_COLOR,
			1.0
		)
		var trade_date: Dictionary = visible_bars[bar_index].get("trade_date", {})
		var label_rect := Rect2(
			Vector2(x_position - 28, plot_rect.end.y + 6),
			Vector2(56, PLOT_MARGIN_BOTTOM - 8)
		)
		draw_string(
			font,
			label_rect.position + Vector2(0, 10),
			_format_axis_date(trade_date),
			HORIZONTAL_ALIGNMENT_CENTER,
			label_rect.size.x,
			AXIS_FONT_SIZE,
			AXIS_TEXT_COLOR
		)


func _build_x_tick_indexes(visible_bars: Array) -> Array:
	var bar_count: int = visible_bars.size()
	if bar_count <= 0:
		return []
	if bar_count == 1:
		return [0]

	if _range_id == "5y":
		return _build_year_tick_indexes(visible_bars)
	if _range_id == "1y":
		return _build_month_tick_indexes(visible_bars)
	if _range_id == "1m":
		return _build_week_tick_indexes(visible_bars)

	var tick_indexes: Array = []
	for tick_slot in range(X_TICK_COUNT):
		var ratio: float = float(tick_slot) / float(max(X_TICK_COUNT - 1, 1))
		var tick_index: int = clamp(int(round(ratio * float(bar_count - 1))), 0, bar_count - 1)
		if tick_indexes.has(tick_index):
			continue
		tick_indexes.append(tick_index)
	if tick_indexes.is_empty():
		tick_indexes.append(bar_count - 1)
	return tick_indexes


func _build_year_tick_indexes(visible_bars: Array) -> Array:
	var tick_indexes: Array = []
	var previous_year: int = -1
	for bar_index in range(visible_bars.size()):
		var trade_date: Dictionary = visible_bars[bar_index].get("trade_date", {})
		var year_value: int = int(trade_date.get("year", 0))
		if year_value != previous_year:
			tick_indexes.append(bar_index)
			previous_year = year_value
	if tick_indexes.is_empty():
		tick_indexes.append(0)
	return tick_indexes


func _build_month_tick_indexes(visible_bars: Array) -> Array:
	var tick_indexes: Array = []
	var previous_key: String = ""
	for bar_index in range(visible_bars.size()):
		var trade_date: Dictionary = visible_bars[bar_index].get("trade_date", {})
		var month_key: String = "%04d-%02d" % [
			int(trade_date.get("year", 0)),
			int(trade_date.get("month", 0))
		]
		if month_key != previous_key:
			tick_indexes.append(bar_index)
			previous_key = month_key
	if tick_indexes.is_empty():
		tick_indexes.append(0)
	return _thin_tick_indexes(tick_indexes, 6)


func _build_week_tick_indexes(visible_bars: Array) -> Array:
	var tick_indexes: Array = []
	var first_weekday: int = int(visible_bars[0].get("trade_date", {}).get("weekday", 0))
	if first_weekday == 0:
		tick_indexes.append(0)
	var previous_weekday: int = first_weekday
	for bar_index in range(1, visible_bars.size()):
		var trade_date: Dictionary = visible_bars[bar_index].get("trade_date", {})
		var weekday_value: int = int(trade_date.get("weekday", previous_weekday))
		if weekday_value <= previous_weekday:
			tick_indexes.append(bar_index)
		previous_weekday = weekday_value
	if tick_indexes.is_empty():
		tick_indexes.append(0)
	return tick_indexes


func _thin_tick_indexes(candidate_indexes: Array, target_count: int) -> Array:
	if candidate_indexes.size() <= target_count:
		return candidate_indexes
	var thinned_indexes: Array = []
	for tick_slot in range(target_count):
		var ratio: float = float(tick_slot) / float(max(target_count - 1, 1))
		var candidate_index: int = clamp(
			int(round(ratio * float(candidate_indexes.size() - 1))),
			0,
			candidate_indexes.size() - 1
		)
		var tick_index: int = int(candidate_indexes[candidate_index])
		if thinned_indexes.has(tick_index):
			continue
		thinned_indexes.append(tick_index)
	if thinned_indexes.is_empty():
		thinned_indexes.append(int(candidate_indexes[0]))
	return thinned_indexes


func _get_chart_font() -> Font:
	var font: Font = get_theme_default_font()
	if font == null:
		font = ThemeDB.fallback_font
	return font


func _format_axis_price(value: float) -> String:
	var rounded_value: int = int(round(value))
	var sign_prefix: String = "-" if rounded_value < 0 else ""
	var digits: String = str(abs(rounded_value))
	var groups: Array = []
	while digits.length() > 3:
		groups.insert(0, digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	groups.insert(0, digits)
	return sign_prefix + ".".join(groups)


func _format_axis_date(trade_date: Dictionary) -> String:
	if trade_date.is_empty():
		return ""
	var month_index: int = clamp(int(trade_date.get("month", 1)) - 1, 0, MONTH_NAMES.size() - 1)
	if _range_id == "5y":
		return str(int(trade_date.get("year", 2020)))
	if _range_id == "1y":
		return MONTH_NAMES[month_index]
	if _range_id == "1m":
		return "%02d" % [int(trade_date.get("day", 1))]
	if _range_id in ["1d", "1w"]:
		return "%02d %s" % [int(trade_date.get("day", 1)), MONTH_NAMES[month_index]]
	var year_two_digits: int = int(trade_date.get("year", 2020)) % 100
	return "%s %02d" % [MONTH_NAMES[month_index], year_two_digits]


func _format_hover_date(trade_date: Dictionary) -> String:
	if trade_date.is_empty():
		return ""
	if _range_id == "5y":
		return "%s %d" % [
			MONTH_NAMES[clamp(int(trade_date.get("month", 1)) - 1, 0, MONTH_NAMES.size() - 1)],
			int(trade_date.get("year", 2020))
		]
	return "%02d %s %d" % [
		int(trade_date.get("day", 1)),
		MONTH_NAMES[clamp(int(trade_date.get("month", 1)) - 1, 0, MONTH_NAMES.size() - 1)],
		int(trade_date.get("year", 2020))
	]


func _format_volume(volume_shares: int) -> String:
	if volume_shares >= 1000000000:
		return "%sB" % String.num(float(volume_shares) / 1000000000.0, 2)
	if volume_shares >= 1000000:
		return "%sM" % String.num(float(volume_shares) / 1000000.0, 1)
	if volume_shares >= 1000:
		return "%sK" % String.num(float(volume_shares) / 1000.0, 1)
	return str(volume_shares)


func _format_change_pct(change_pct: float) -> String:
	return "%+.2f%%" % [change_pct * 100.0]


func _clear_hover_state() -> void:
	if not _hover_active:
		return
	_hover_active = false
	queue_redraw()
