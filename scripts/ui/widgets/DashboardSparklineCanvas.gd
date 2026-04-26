extends Control
class_name DashboardSparklineCanvas

const DEFAULT_POSITIVE_COLOR := Color(0.513726, 0.886275, 0.662745, 1)
const DEFAULT_NEGATIVE_COLOR := Color(0.968627, 0.513726, 0.513726, 1)
const DEFAULT_NEUTRAL_COLOR := Color(0.980392, 0.792157, 0.392157, 1)
const DEFAULT_GUIDE_COLOR := Color(0.694118, 0.756863, 0.803922, 0.28)
const SPARKLINE_PADDING := 4.0

var _points: Array = []
var _line_color: Color = DEFAULT_NEUTRAL_COLOR
var _positive_color: Color = DEFAULT_POSITIVE_COLOR
var _negative_color: Color = DEFAULT_NEGATIVE_COLOR
var _neutral_color: Color = DEFAULT_NEUTRAL_COLOR
var _guide_color: Color = DEFAULT_GUIDE_COLOR


func set_palette(positive_color: Color, negative_color: Color, neutral_color: Color, guide_color: Color) -> void:
	_positive_color = positive_color
	_negative_color = negative_color
	_neutral_color = neutral_color
	_guide_color = guide_color
	_update_line_color_from_points()
	queue_redraw()


func set_points(values: Array) -> void:
	_points = []
	for value in values:
		_points.append(float(value))
	set_meta("point_count", _points.size())
	_update_line_color_from_points()
	queue_redraw()


func set_line_tone(change_pct: float) -> void:
	if change_pct > 0.0005:
		_line_color = _positive_color
	elif change_pct < -0.0005:
		_line_color = _negative_color
	else:
		_line_color = _neutral_color
	queue_redraw()


func get_point_count() -> int:
	return _points.size()


func _update_line_color_from_points() -> void:
	if _points.size() < 2:
		_line_color = _neutral_color
		return
	var first_value: float = float(_points[0])
	var last_value: float = float(_points[_points.size() - 1])
	if last_value > first_value + 0.0005:
		_line_color = _positive_color
	elif last_value < first_value - 0.0005:
		_line_color = _negative_color
	else:
		_line_color = _neutral_color


func _draw() -> void:
	var draw_rect: Rect2 = Rect2(Vector2.ZERO, size)
	if draw_rect.size.x <= 1.0 or draw_rect.size.y <= 1.0:
		return
	_draw_guide(draw_rect)
	if _points.size() < 2:
		return

	var minimum_value: float = float(_points[0])
	var maximum_value: float = minimum_value
	for point_value in _points:
		var value: float = float(point_value)
		minimum_value = min(minimum_value, value)
		maximum_value = max(maximum_value, value)
	if is_equal_approx(minimum_value, maximum_value):
		minimum_value -= 1.0
		maximum_value += 1.0

	var usable_rect: Rect2 = draw_rect.grow(-SPARKLINE_PADDING)
	var value_span: float = max(maximum_value - minimum_value, 0.0001)
	var polyline := PackedVector2Array()
	for point_index in range(_points.size()):
		var x_ratio: float = float(point_index) / float(max(_points.size() - 1, 1))
		var y_ratio: float = (float(_points[point_index]) - minimum_value) / value_span
		polyline.append(Vector2(
			usable_rect.position.x + x_ratio * usable_rect.size.x,
			usable_rect.position.y + (1.0 - y_ratio) * usable_rect.size.y
		))
	draw_polyline(polyline, _line_color, 1.6, true)


func _draw_guide(draw_rect: Rect2) -> void:
	var y: float = draw_rect.position.y + SPARKLINE_PADDING
	var start_x: float = draw_rect.position.x + SPARKLINE_PADDING
	var end_x: float = draw_rect.end.x - SPARKLINE_PADDING
	var dash_width := 4.0
	var gap_width := 5.0
	var x := start_x
	while x < end_x:
		draw_line(Vector2(x, y), Vector2(min(x + dash_width, end_x), y), _guide_color, 1.0)
		x += dash_width + gap_width
