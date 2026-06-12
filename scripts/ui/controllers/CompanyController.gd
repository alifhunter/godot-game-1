extends RefCounted

const UI_THEME := preload("res://scripts/ui/UITheme.gd")

const COLOR_DESKTOP_TEXT := UI_THEME.COLOR_DESKTOP_TEXT
const COLOR_ACADEMY_CREAM := UI_THEME.COLOR_ACADEMY_CREAM
const COLOR_WINDOW_TEXT := UI_THEME.COLOR_WINDOW_TEXT
const DEFAULT_APP_FONT_SIZE := 14

var _root = null
var company_app_button: Button = null
var company_app_label: Label = null
var company_window: MarginContainer = null
var company_status_label: Label = null
var company_controlled_option: OptionButton = null
var company_detail_label: Label = null
var company_agenda_label: Label = null
var company_agenda_option: OptionButton = null
var company_request_button: Button = null
var company_management_snapshot: Dictionary = {}


func setup(root) -> void:
	_root = root
	_sync_dynamic_refs_from_root()
	_sync_root_refs()


func ensure_ui() -> void:
	_sync_dynamic_refs_from_root()
	if company_window != null:
		_sync_root_refs()
		return

	var desktop_icons_row: HBoxContainer = _root.get_node("DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow")
	var company_tile := VBoxContainer.new()
	company_tile.name = "CompanyAppTile"
	company_tile.add_theme_constant_override("separation", 10)
	desktop_icons_row.add_child(company_tile)
	var upgrades_tile: Node = desktop_icons_row.get_node_or_null("UpgradesAppTile")
	if upgrades_tile != null:
		desktop_icons_row.move_child(company_tile, upgrades_tile.get_index())

	company_app_button = Button.new()
	company_app_button.name = "CompanyAppButton"
	company_app_button.custom_minimum_size = Vector2(92, 92)
	company_app_button.toggle_mode = true
	company_tile.add_child(company_app_button)

	company_app_label = Label.new()
	company_app_label.name = "CompanyAppLabel"
	company_app_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	company_app_label.text = "Company"
	company_app_label.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)
	company_tile.add_child(company_app_label)

	company_window = MarginContainer.new()
	company_window.name = "CompanyWindow"
	company_window.visible = false
	company_window.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(company_window)
	var upgrade_window_node: Node = _root.get_node_or_null("UpgradeWindow")
	if upgrade_window_node != null:
		_root.move_child(company_window, upgrade_window_node.get_index())

	var body := PanelContainer.new()
	body.name = "CompanyWindowBody"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(body, COLOR_ACADEMY_CREAM, 0, 0, 0, 0, 0)
	company_window.add_child(body)

	var margin := MarginContainer.new()
	margin.name = "CompanyWindowMargin"
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	body.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "CompanyWindowVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.name = "CompanyTitleLabel"
	title.text = "Company Control"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	vbox.add_child(title)

	company_status_label = Label.new()
	company_status_label.name = "CompanyStatusLabel"
	company_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	company_status_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	company_status_label.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	vbox.add_child(company_status_label)

	company_controlled_option = OptionButton.new()
	company_controlled_option.name = "CompanyControlledOption"
	company_controlled_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	company_controlled_option.item_selected.connect(on_controlled_company_selected)
	_style_light_option_button(company_controlled_option)
	vbox.add_child(company_controlled_option)

	company_detail_label = Label.new()
	company_detail_label.name = "CompanyDetailLabel"
	company_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	company_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	company_detail_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	company_detail_label.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	vbox.add_child(company_detail_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	company_agenda_label = Label.new()
	company_agenda_label.name = "CompanyAgendaLabel"
	company_agenda_label.text = "RUPSLB agenda"
	company_agenda_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	company_agenda_label.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	vbox.add_child(company_agenda_label)

	company_agenda_option = OptionButton.new()
	company_agenda_option.name = "CompanyAgendaOption"
	company_agenda_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_light_option_button(company_agenda_option)
	vbox.add_child(company_agenda_option)

	company_request_button = Button.new()
	company_request_button.name = "CompanyRequestButton"
	company_request_button.text = "Set Agenda"
	company_request_button.custom_minimum_size = Vector2(0, 42)
	company_request_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	company_request_button.tooltip_text = "Use majority ownership to set a company-direction agenda."
	company_request_button.pressed.connect(on_request_pressed)
	_style_company_action_button(company_request_button, true)
	vbox.add_child(company_request_button)

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(bottom_spacer)
	_sync_root_refs()


func refresh_app_availability() -> void:
	_sync_dynamic_refs_from_root()
	if company_app_button == null:
		return
	var snapshot: Dictionary = GameManager.get_company_management_snapshot()
	var unlocked: bool = bool(snapshot.get("unlocked", false))
	company_app_button.disabled = false
	company_app_button.tooltip_text = "Open Company." if unlocked else str(snapshot.get("status_text", "You have no company yet."))
	if company_app_label != null:
		company_app_label.modulate = Color.WHITE


func refresh(preferred_company_id: String = "") -> void:
	_sync_dynamic_refs_from_root()
	if company_window == null:
		return
	var previous_company_id: String = preferred_company_id if not preferred_company_id.is_empty() else selected_company_id()
	company_management_snapshot = GameManager.get_company_management_snapshot(previous_company_id)
	var controlled_rows: Array = company_management_snapshot.get("controlled_rows", [])
	var candidate_rows: Array = company_management_snapshot.get("candidate_rows", [])
	var selected_company_management_id: String = str(company_management_snapshot.get("selected_company_id", ""))
	var selected_options: Dictionary = company_management_snapshot.get("selected_options", {})
	var has_company: bool = not controlled_rows.is_empty()

	if company_status_label != null:
		company_status_label.text = str(company_management_snapshot.get("status_text", "You have no company yet."))
	if company_controlled_option != null:
		company_controlled_option.clear()
		company_controlled_option.visible = has_company
		var selected_index: int = 0
		for row_index in range(controlled_rows.size()):
			if typeof(controlled_rows[row_index]) != TYPE_DICTIONARY:
				continue
			var row: Dictionary = controlled_rows[row_index]
			var company_id: String = str(row.get("company_id", ""))
			company_controlled_option.add_item("%s  |  %.2f%%" % [
				str(row.get("ticker", company_id.to_upper())),
				float(row.get("ownership_pct", 0.0)) * 100.0
			])
			var item_index: int = company_controlled_option.get_item_count() - 1
			company_controlled_option.set_item_metadata(item_index, company_id)
			if company_id == selected_company_management_id:
				selected_index = item_index
		if company_controlled_option.get_item_count() > 0:
			company_controlled_option.select(clamp(selected_index, 0, company_controlled_option.get_item_count() - 1))
		company_controlled_option.disabled = company_controlled_option.get_item_count() <= 0

	if company_detail_label != null:
		company_detail_label.text = company_management_detail_text(controlled_rows, candidate_rows, selected_company_management_id, selected_options)
	if company_agenda_label != null:
		company_agenda_label.visible = has_company

	var previous_action_id: String = selected_action_id()
	if company_agenda_option != null:
		company_agenda_option.clear()
		company_agenda_option.visible = has_company
		var rows: Array = selected_options.get("rows", [])
		var selected_action_index: int = 0
		for row_index in range(rows.size()):
			if typeof(rows[row_index]) != TYPE_DICTIONARY:
				continue
			var action_row: Dictionary = rows[row_index]
			var action_id: String = str(action_row.get("id", ""))
			company_agenda_option.add_item(str(action_row.get("label", "Agenda")))
			var item_index: int = company_agenda_option.get_item_count() - 1
			company_agenda_option.set_item_metadata(item_index, action_id)
			if action_id == previous_action_id:
				selected_action_index = item_index
		if company_agenda_option.get_item_count() > 0:
			company_agenda_option.select(clamp(selected_action_index, 0, company_agenda_option.get_item_count() - 1))
		company_agenda_option.disabled = not bool(selected_options.get("enabled", false)) or company_agenda_option.get_item_count() <= 0

	if company_request_button != null:
		var enabled: bool = bool(selected_options.get("enabled", false)) and company_agenda_option != null and company_agenda_option.get_item_count() > 0
		company_request_button.disabled = not enabled
		company_request_button.visible = has_company
		company_request_button.tooltip_text = str(selected_options.get("tooltip_text", "Use majority ownership to set a company-direction agenda."))
		_style_company_action_button(company_request_button, enabled)
	refresh_app_availability()


func company_management_detail_text(controlled_rows: Array, _candidate_rows: Array, selected_company_management_id: String, selected_options: Dictionary) -> String:
	for row_value in controlled_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("company_id", "")) != selected_company_management_id:
			continue
		return "%s - %s\nOwned %s share(s), %.2f%% of outstanding. Control threshold: %s share(s).\n%s" % [
			str(row.get("ticker", "")),
			str(row.get("name", "")),
			_format_grouped_integer(int(row.get("shares_owned", 0))),
			float(row.get("ownership_pct", 0.0)) * 100.0,
			_format_grouped_integer(int(row.get("control_required_shares", 0))),
			str(selected_options.get("status_text", "Pick an agenda."))
		]
	return "You have no company yet."


func selected_company_id() -> String:
	if company_controlled_option == null or company_controlled_option.get_item_count() <= 0:
		return str(company_management_snapshot.get("selected_company_id", ""))
	var selected_index: int = company_controlled_option.selected
	if selected_index < 0 or selected_index >= company_controlled_option.get_item_count():
		return str(company_management_snapshot.get("selected_company_id", ""))
	return str(company_controlled_option.get_item_metadata(selected_index))


func selected_action_id() -> String:
	if company_agenda_option == null or company_agenda_option.get_item_count() <= 0:
		return ""
	var selected_index: int = company_agenda_option.selected
	if selected_index < 0 or selected_index >= company_agenda_option.get_item_count():
		return ""
	return str(company_agenda_option.get_item_metadata(selected_index))


func on_controlled_company_selected(_index: int) -> void:
	refresh()


func on_request_pressed() -> void:
	var company_id: String = selected_company_id()
	var action_id: String = selected_action_id()
	var result: Dictionary = GameManager.request_governance_control_action(company_id, action_id)
	_show_toast(str(result.get("message", "Could not set company agenda.")), bool(result.get("success", false)))
	refresh()
	_refresh_desktop()
	if not bool(result.get("success", false)):
		return
	_refresh_dashboard()
	_refresh_news()
	_refresh_network()
	_refresh_trade_workspace()


func _sync_dynamic_refs_from_root() -> void:
	if _root == null:
		return
	company_app_button = _root.get("company_app_button") as Button
	company_app_label = _root.get("company_app_label") as Label
	company_window = _root.get("company_window") as MarginContainer
	company_status_label = _root.get("company_status_label") as Label
	company_controlled_option = _root.get("company_controlled_option") as OptionButton
	company_detail_label = _root.get("company_detail_label") as Label
	company_agenda_label = _root.get("company_agenda_label") as Label
	company_agenda_option = _root.get("company_agenda_option") as OptionButton
	company_request_button = _root.get("company_request_button") as Button


func _sync_root_refs() -> void:
	if _root == null:
		return
	_root.set("company_app_button", company_app_button)
	_root.set("company_app_label", company_app_label)
	_root.set("company_window", company_window)
	_root.set("company_status_label", company_status_label)
	_root.set("company_controlled_option", company_controlled_option)
	_root.set("company_detail_label", company_detail_label)
	_root.set("company_agenda_label", company_agenda_label)
	_root.set("company_agenda_option", company_agenda_option)
	_root.set("company_request_button", company_request_button)


func _style_panel(panel: PanelContainer, fill_color: Color, corner_radius: int = 10, border_top: int = 1, border_right: int = 1, border_bottom: int = 1, border_left: int = 1) -> void:
	if _root != null:
		_root.call("_style_panel", panel, fill_color, corner_radius, border_top, border_right, border_bottom, border_left)


func _style_light_option_button(option_button: OptionButton) -> void:
	if _root != null:
		_root.call("_style_light_option_button", option_button)


func _style_company_action_button(button: Button, enabled: bool) -> void:
	if _root != null:
		_root.call("_style_company_action_button", button, enabled)


func _format_grouped_integer(value: int) -> String:
	if _root == null:
		return str(value)
	return str(_root.call("_format_grouped_integer", value))


func _show_toast(message: String, is_success: bool) -> void:
	if _root != null:
		_root.call("_show_toast", message, is_success)


func _refresh_desktop() -> void:
	if _root != null:
		_root.call("_refresh_desktop")


func _refresh_dashboard() -> void:
	if _root != null:
		_root.call("_refresh_dashboard")


func _refresh_news() -> void:
	if _root != null:
		_root.call("_refresh_news")


func _refresh_network() -> void:
	if _root != null:
		_root.call("_refresh_network")


func _refresh_trade_workspace() -> void:
	if _root != null:
		_root.call("_refresh_trade_workspace")
