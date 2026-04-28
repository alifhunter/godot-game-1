extends MarginContainer

const COLOR_BG := Color(0.909804, 0.909804, 0.803922, 1)
const COLOR_PANEL := Color(0.972549, 0.94902, 0.847059, 1)
const COLOR_PANEL_ALT := Color(0.952941, 0.94902, 0.87451, 1)
const COLOR_BROWN := Color(0.509804, 0.231373, 0.0941176, 1)
const COLOR_TEXT := Color(0.184314, 0.172549, 0.109804, 1)
const COLOR_MUTED := Color(0.403922, 0.380392, 0.301961, 1)
const COLOR_BORDER := Color(0.52549, 0.396078, 0.160784, 1)
const COLOR_POSITIVE := Color(0.168627, 0.423529, 0.27451, 1)
const COLOR_NEGATIVE := Color(0.607843, 0.160784, 0.145098, 1)

var snapshot: Dictionary = {}
var suppress_option_refresh: bool = false

var status_label: Label = null
var summary_label: Label = null
var cash_label: Label = null
var equity_label: Label = null
var outflow_label: Label = null
var dividend_label: Label = null
var net_monthly_label: Label = null
var runway_label: Label = null
var housing_option: OptionButton = null
var lifestyle_option: OptionButton = null
var housing_detail_label: Label = null
var lifestyle_detail_label: Label = null
var update_plan_button: Button = null
var budget_rows: VBoxContainer = null
var dividend_rows: VBoxContainer = null
var note_label: Label = null


func _ready() -> void:
	_build_ui()
	if not GameManager.life_changed.is_connected(_on_life_changed):
		GameManager.life_changed.connect(_on_life_changed)
	refresh()


func refresh() -> void:
	if summary_label == null:
		return
	snapshot = GameManager.get_life_snapshot()
	if snapshot.is_empty():
		_set_empty_state()
		return

	var state: Dictionary = snapshot.get("state", {})
	suppress_option_refresh = true
	_populate_option(housing_option, snapshot.get("housing_options", []), str(state.get("housing_id", "")))
	_populate_option(lifestyle_option, snapshot.get("lifestyle_options", []), str(state.get("lifestyle_id", "")))
	suppress_option_refresh = false

	status_label.text = str(snapshot.get("status_label", "Runway ready"))
	cash_label.text = _format_currency(float(snapshot.get("cash", 0.0)))
	equity_label.text = _format_currency(float(snapshot.get("equity", 0.0)))
	outflow_label.text = _format_currency(float(snapshot.get("monthly_outflow", 0.0)))
	dividend_label.text = _format_currency(float(snapshot.get("estimated_monthly_dividends", 0.0)))
	var net_monthly: float = float(snapshot.get("net_monthly", 0.0))
	net_monthly_label.text = _format_currency(net_monthly)
	net_monthly_label.add_theme_color_override("font_color", COLOR_POSITIVE if net_monthly >= 0.0 else COLOR_NEGATIVE)
	runway_label.text = _format_runway(float(snapshot.get("runway_months", 0.0)))
	summary_label.text = "Monthly outflow %s | Declared dividend avg %s | Net %s" % [
		_format_currency(float(snapshot.get("monthly_outflow", 0.0))),
		_format_currency(float(snapshot.get("estimated_monthly_dividends", 0.0))),
		_format_currency(net_monthly)
	]
	note_label.text = str(snapshot.get("note", ""))
	_refresh_option_details()
	_refresh_budget_rows()
	_refresh_dividend_rows()


func _build_ui() -> void:
	name = "LifeWindow"
	add_theme_constant_override("margin_left", 0)
	add_theme_constant_override("margin_top", 0)
	add_theme_constant_override("margin_right", 0)
	add_theme_constant_override("margin_bottom", 0)

	var root := VBoxContainer.new()
	root.name = "LifeRoot"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var header_panel := _make_panel("LifeHeaderPanel")
	header_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(header_panel)
	var header_vbox := _panel_vbox(header_panel, "LifeHeaderVBox")
	header_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var header_row := HBoxContainer.new()
	header_row.name = "LifeHeaderRow"
	header_row.add_theme_constant_override("separation", 10)
	header_vbox.add_child(header_row)
	var title_label := _make_title("Life")
	header_row.add_child(title_label)
	status_label = Label.new()
	status_label.name = "LifeStatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(status_label, COLOR_MUTED, 12)
	header_row.add_child(status_label)
	summary_label = Label.new()
	summary_label.name = "LifeSummaryLabel"
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(summary_label, COLOR_MUTED, 12)
	header_vbox.add_child(summary_label)

	var stat_grid := GridContainer.new()
	stat_grid.name = "LifeStatGrid"
	stat_grid.columns = 3
	stat_grid.add_theme_constant_override("h_separation", 8)
	stat_grid.add_theme_constant_override("v_separation", 8)
	root.add_child(stat_grid)
	cash_label = _add_stat_card(stat_grid, "Cash", "LifeCashLabel")
	equity_label = _add_stat_card(stat_grid, "Equity", "LifeEquityLabel")
	runway_label = _add_stat_card(stat_grid, "Runway", "LifeRunwayLabel")
	outflow_label = _add_stat_card(stat_grid, "Monthly outflow", "LifeMonthlyOutflowLabel")
	dividend_label = _add_stat_card(stat_grid, "Declared div avg", "LifeDividendLabel")
	net_monthly_label = _add_stat_card(stat_grid, "Net monthly", "LifeNetMonthlyLabel")

	var split := HBoxContainer.new()
	split.name = "LifeContentSplit"
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 10)
	root.add_child(split)

	var plan_panel := _make_panel("LifePlanPanel")
	plan_panel.custom_minimum_size = Vector2(280, 0)
	split.add_child(plan_panel)
	var plan_vbox := _panel_vbox(plan_panel, "LifePlanVBox")
	plan_vbox.add_child(_make_title("Plan"))
	housing_option = OptionButton.new()
	housing_option.name = "LifeHousingOption"
	housing_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	housing_option.item_selected.connect(_on_option_changed)
	plan_vbox.add_child(housing_option)
	housing_detail_label = _make_body_label("LifeHousingDetailLabel")
	plan_vbox.add_child(housing_detail_label)
	lifestyle_option = OptionButton.new()
	lifestyle_option.name = "LifeLifestyleOption"
	lifestyle_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lifestyle_option.item_selected.connect(_on_option_changed)
	plan_vbox.add_child(lifestyle_option)
	lifestyle_detail_label = _make_body_label("LifeLifestyleDetailLabel")
	plan_vbox.add_child(lifestyle_detail_label)
	update_plan_button = Button.new()
	update_plan_button.name = "LifeUpdatePlanButton"
	update_plan_button.text = "Update Plan"
	update_plan_button.pressed.connect(_on_update_plan_pressed)
	plan_vbox.add_child(update_plan_button)
	note_label = _make_body_label("LifeNoteLabel")
	plan_vbox.add_child(note_label)

	var budget_panel := _make_panel("LifeBudgetPanel")
	budget_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(budget_panel)
	var budget_vbox := _panel_vbox(budget_panel, "LifeBudgetVBox")
	budget_vbox.add_child(_make_title("Monthly Cash Flow"))
	budget_rows = VBoxContainer.new()
	budget_rows.name = "LifeBudgetRows"
	budget_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	budget_rows.add_theme_constant_override("separation", 6)
	budget_vbox.add_child(budget_rows)
	budget_vbox.add_child(_make_title("Portfolio Income"))
	var dividend_scroll := ScrollContainer.new()
	dividend_scroll.name = "LifeDividendScroll"
	dividend_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dividend_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	budget_vbox.add_child(dividend_scroll)
	dividend_rows = VBoxContainer.new()
	dividend_rows.name = "LifeDividendRows"
	dividend_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dividend_rows.add_theme_constant_override("separation", 6)
	dividend_scroll.add_child(dividend_rows)

	_style_buttons(self)


func _set_empty_state() -> void:
	status_label.text = "No active run"
	summary_label.text = "Start or load a run to use Life."
	for value_label in [cash_label, equity_label, outflow_label, dividend_label, net_monthly_label, runway_label]:
		if value_label != null:
			value_label.text = "-"
	_clear_rows(budget_rows)
	_clear_rows(dividend_rows)


func _populate_option(option: OptionButton, rows: Array, selected_id: String) -> void:
	if option == null:
		return
	option.clear()
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var index: int = option.item_count
		option.add_item(str(row.get("label", "")))
		option.set_item_metadata(index, str(row.get("id", "")))
		if str(row.get("id", "")) == selected_id:
			option.select(index)
	if option.item_count > 0 and option.selected < 0:
		option.select(0)


func _refresh_option_details() -> void:
	var housing: Dictionary = _selected_option_data(snapshot.get("housing_options", []), _selected_option_id(housing_option))
	var lifestyle: Dictionary = _selected_option_data(snapshot.get("lifestyle_options", []), _selected_option_id(lifestyle_option))
	housing_detail_label.text = "%s / month. %s" % [
		_format_currency(float(housing.get("monthly_cost", 0.0))),
		str(housing.get("detail", ""))
	]
	lifestyle_detail_label.text = "%s / month. %s" % [
		_format_currency(float(lifestyle.get("monthly_cost", 0.0))),
		str(lifestyle.get("detail", ""))
	]


func _refresh_budget_rows() -> void:
	_clear_rows(budget_rows)
	var housing: Dictionary = snapshot.get("housing", {})
	var lifestyle: Dictionary = snapshot.get("lifestyle", {})
	_add_budget_row("Housing", str(housing.get("label", "")), float(housing.get("monthly_cost", 0.0)), false)
	_add_budget_row("Basics", "Food, transport, phone, and utilities", float(snapshot.get("basic_expenses_monthly", 0.0)), false)
	_add_budget_row("Lifestyle", str(lifestyle.get("label", "")), float(lifestyle.get("monthly_cost", 0.0)), false)
	if float(snapshot.get("monthly_extra", 0.0)) > 0.0:
		_add_budget_row("Extra", "Manual buffer", float(snapshot.get("monthly_extra", 0.0)), false)
	_add_budget_row("Dividends", "Declared average from corporate actions", float(snapshot.get("estimated_monthly_dividends", 0.0)), true)
	_add_budget_row("Net", "Monthly gap after dividends", float(snapshot.get("net_monthly", 0.0)), true)


func _refresh_dividend_rows() -> void:
	_clear_rows(dividend_rows)
	var rows: Array = snapshot.get("dividend_rows", [])
	if rows.is_empty():
		var empty_label := _make_body_label("LifeDividendEmptyLabel")
		empty_label.text = "No declared dividends for current holdings yet."
		dividend_rows.add_child(empty_label)
		return
	var shown_count: int = 0
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		_add_dividend_row(
			str(row.get("ticker", "")),
			int(row.get("eligible_shares", 0)),
			float(row.get("amount_per_share", 0.0)),
			float(row.get("projected_amount", 0.0)),
			float(row.get("monthly_income", 0.0))
		)
		shown_count += 1
		if shown_count >= 6:
			break


func _add_budget_row(label_text: String, detail_text: String, value: float, income_row: bool) -> void:
	if budget_rows == null:
		return
	var row := HBoxContainer.new()
	row.name = "LifeBudgetRow%s" % label_text.replace(" ", "")
	row.add_theme_constant_override("separation", 8)
	budget_rows.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(108, 0)
	_style_label(label, COLOR_TEXT, 12)
	row.add_child(label)
	var detail := Label.new()
	detail.text = detail_text
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(detail, COLOR_MUTED, 12)
	row.add_child(detail)
	var value_label := Label.new()
	value_label.text = _format_currency(value)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(110, 0)
	var value_color: Color = COLOR_TEXT
	if income_row and value >= 0.0:
		value_color = COLOR_POSITIVE
	elif value < 0.0:
		value_color = COLOR_NEGATIVE
	_style_label(value_label, value_color, 12)
	row.add_child(value_label)


func _add_dividend_row(ticker: String, eligible_shares: int, amount_per_share: float, projected_amount: float, monthly_income: float) -> void:
	var row := HBoxContainer.new()
	row.name = "LifeDividendRow%s" % ticker
	row.add_theme_constant_override("separation", 8)
	dividend_rows.add_child(row)
	var ticker_label := Label.new()
	ticker_label.text = ticker
	ticker_label.custom_minimum_size = Vector2(64, 0)
	_style_label(ticker_label, COLOR_TEXT, 12)
	row.add_child(ticker_label)
	var detail_label := Label.new()
	detail_label.text = "%d shares x %s DPS = %s declared" % [eligible_shares, _format_currency(amount_per_share), _format_currency(projected_amount)]
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(detail_label, COLOR_MUTED, 12)
	row.add_child(detail_label)
	var income_label := Label.new()
	income_label.text = _format_currency(monthly_income)
	income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	income_label.custom_minimum_size = Vector2(110, 0)
	_style_label(income_label, COLOR_POSITIVE, 12)
	row.add_child(income_label)


func _on_option_changed(_index: int) -> void:
	if suppress_option_refresh:
		return
	_refresh_option_details()
	status_label.text = "Unsaved plan"


func _on_update_plan_pressed() -> void:
	var result: Dictionary = GameManager.set_life_plan(_selected_option_id(housing_option), _selected_option_id(lifestyle_option))
	status_label.text = str(result.get("message", "Life plan updated."))
	if bool(result.get("success", false)):
		refresh()


func _on_life_changed() -> void:
	refresh()


func _selected_option_id(option: OptionButton) -> String:
	if option == null or option.item_count <= 0:
		return ""
	var selected_index: int = max(option.selected, 0)
	return str(option.get_item_metadata(selected_index))


func _selected_option_data(rows: Array, option_id: String) -> Dictionary:
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("id", "")) == option_id:
			return row
	if rows.is_empty() or typeof(rows[0]) != TYPE_DICTIONARY:
		return {}
	return rows[0]


func _add_stat_card(grid: GridContainer, label_text: String, value_name: String) -> Label:
	var panel := _make_panel("%sPanel" % value_name)
	panel.custom_minimum_size = Vector2(180, 58)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(panel)
	var vbox := _panel_vbox(panel, "%sVBox" % value_name)
	vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var label := Label.new()
	label.text = label_text
	_style_label(label, COLOR_MUTED, 11)
	vbox.add_child(label)
	var value_label := Label.new()
	value_label.name = value_name
	value_label.text = "-"
	_style_label(value_label, COLOR_TEXT, 15)
	vbox.add_child(value_label)
	return value_label


func _make_panel(panel_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_stylebox(COLOR_PANEL, COLOR_BORDER, 1))
	return panel


func _make_stylebox(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(0)
	return style


func _panel_vbox(panel: PanelContainer, box_name: String) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.name = "%sMargin" % box_name
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = box_name
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 7)
	margin.add_child(vbox)
	return vbox


func _make_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	_style_label(label, COLOR_BROWN, 16)
	return label


func _make_body_label(label_name: String) -> Label:
	var label := Label.new()
	label.name = label_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(label, COLOR_MUTED, 12)
	return label


func _style_label(label: Label, color: Color, size: int) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)


func _style_buttons(root: Node) -> void:
	for child in root.get_children():
		if child is Button:
			_style_button(child)
		_style_buttons(child)


func _style_button(button: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BROWN
	style.border_color = COLOR_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override("font_color", COLOR_BG)
	button.add_theme_color_override("font_hover_color", COLOR_BG)
	button.add_theme_color_override("font_pressed_color", COLOR_BG)


func _clear_rows(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _format_runway(months: float) -> String:
	if months >= 120.0:
		return "10y+"
	if months >= 24.0:
		return "%s years" % String.num(months / 12.0, 1)
	return "%s months" % String.num(max(months, 0.0), 1)


func _format_currency(value: float) -> String:
	var sign: String = "-" if value < 0.0 else ""
	var abs_value: float = abs(value)
	if abs_value >= 1000000000000.0:
		return "%sRp%sT" % [sign, String.num(abs_value / 1000000000000.0, 2)]
	if abs_value >= 1000000000.0:
		return "%sRp%sB" % [sign, String.num(abs_value / 1000000000.0, 2)]
	if abs_value >= 1000000.0:
		return "%sRp%sM" % [sign, String.num(abs_value / 1000000.0, 2)]
	return "%sRp%s" % [sign, String.num(abs_value, 2)]


func _format_percent(value: float) -> String:
	var sign: String = "+" if value > 0.0 else ""
	return "%s%s%%" % [sign, String.num(value * 100.0, 2)]
