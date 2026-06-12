extends RefCounted

const UI_THEME := preload("res://scripts/ui/UITheme.gd")

const APP_ID_LIFE := "life"
const LIFE_WIDGET_SCRIPT = preload("res://scripts/ui/widgets/LifeWidget.gd")
const COLOR_DESKTOP_TEXT := UI_THEME.COLOR_DESKTOP_TEXT
const COLOR_DESKTOP_CREAM := UI_THEME.COLOR_DESKTOP_CREAM
const COLOR_DESKTOP_BROWN := UI_THEME.COLOR_DESKTOP_BROWN
const COLOR_DESKTOP_FRAME := UI_THEME.COLOR_DESKTOP_FRAME

var _root = null
var life_app_button: Button = null
var life_app_label: Label = null
var life_window: MarginContainer = null
var stress_meter_panel: PanelContainer = null
var stress_meter_bar: ProgressBar = null
var stress_meter_title_label: Label = null
var stress_meter_label: Label = null
var hospital_overlay: Control = null
var hospital_body_label: Label = null
var hospital_advance_button: Button = null
var jail_overlay: Control = null
var jail_body_label: Label = null
var jail_advance_button: Button = null


func setup(root) -> void:
	_root = root
	_sync_dynamic_refs_from_root()
	_sync_root_refs()


func ensure_ui() -> void:
	_sync_dynamic_refs_from_root()
	if life_window != null:
		_sync_root_refs()
		return

	var desktop_icons_row: HBoxContainer = _root.get_node("DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow")
	var life_tile := VBoxContainer.new()
	life_tile.name = "LifeAppTile"
	life_tile.add_theme_constant_override("separation", 10)
	desktop_icons_row.add_child(life_tile)
	var upgrades_tile: Node = desktop_icons_row.get_node_or_null("UpgradesAppTile")
	if upgrades_tile != null:
		desktop_icons_row.move_child(life_tile, upgrades_tile.get_index())

	life_app_button = Button.new()
	life_app_button.name = "LifeAppButton"
	life_app_button.custom_minimum_size = Vector2(92, 92)
	life_app_button.toggle_mode = true
	life_tile.add_child(life_app_button)

	life_app_label = Label.new()
	life_app_label.name = "LifeAppLabel"
	life_app_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	life_app_label.text = "Life"
	life_app_label.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)
	life_tile.add_child(life_app_label)

	life_window = LIFE_WIDGET_SCRIPT.new()
	life_window.name = "LifeWindow"
	life_window.visible = false
	life_window.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(life_window)
	var upgrade_window_node: Node = _root.get_node_or_null("UpgradeWindow")
	if upgrade_window_node != null:
		_root.move_child(life_window, upgrade_window_node.get_index())
	_sync_root_refs()
	_root.call_deferred("_style_life_news_tabs")


func refresh() -> void:
	_sync_dynamic_refs_from_root()
	if life_window == null:
		return
	if life_window.has_method("refresh"):
		life_window.call("refresh")
	style_tabs()


func style_tabs() -> void:
	_sync_dynamic_refs_from_root()
	if life_window == null:
		return
	var tabs := life_window.find_child("LifeTabs", true, false) as TabContainer
	_style_news_tab_container(tabs)


func bind_guide_tabs() -> void:
	_sync_dynamic_refs_from_root()
	if life_window == null:
		return
	style_tabs()
	var tabs: TabContainer = life_window.find_child("LifeTabs", true, false) as TabContainer
	if tabs != null and not tabs.tab_changed.is_connected(on_guide_tab_changed):
		tabs.tab_changed.connect(on_guide_tab_changed)
	var housing_option: OptionButton = life_window.find_child("LifeHousingOption", true, false) as OptionButton
	if housing_option != null and not housing_option.item_selected.is_connected(on_guide_plan_changed):
		housing_option.item_selected.connect(on_guide_plan_changed)
	var lifestyle_option: OptionButton = life_window.find_child("LifeLifestyleOption", true, false) as OptionButton
	if lifestyle_option != null and not lifestyle_option.item_selected.is_connected(on_guide_plan_changed):
		lifestyle_option.item_selected.connect(on_guide_plan_changed)
	var basics_slider: HSlider = life_window.find_child("LifeBasicsSlider", true, false) as HSlider
	if basics_slider != null and not basics_slider.value_changed.is_connected(on_guide_plan_changed):
		basics_slider.value_changed.connect(on_guide_plan_changed)
	var update_button: Button = life_window.find_child("LifeUpdatePlanButton", true, false) as Button
	if update_button != null and not update_button.pressed.is_connected(_mark_guide_life_plan_reviewed):
		update_button.pressed.connect(_mark_guide_life_plan_reviewed)


func on_guide_tab_changed(_tab_index: int) -> void:
	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	if str(snapshot.get("active_flow_id", "")) == RunState.GUIDE_FLOW_SYSTEM.FLOW_LIFE_FINANCE:
		var tabs: TabContainer = null
		if life_window != null:
			tabs = life_window.find_child("LifeTabs", true, false) as TabContainer
		if tabs != null and _tab_index >= 0 and _tab_index < tabs.get_tab_count() and tabs.get_tab_title(_tab_index) == "Finance":
			if _root != null:
				_root.set("guide_life_finance_tab_seen", true)
	_refresh_ftue_progress()


func on_guide_plan_changed(_value = 0) -> void:
	_mark_guide_life_plan_reviewed()


func ensure_stress_meter_ui() -> void:
	_sync_dynamic_refs_from_root()
	if stress_meter_panel != null:
		_sync_root_refs()
		return
	var desktop_vbox: VBoxContainer = _root.get_node("DesktopLayer/DesktopMargin/DesktopVBox") as VBoxContainer
	if desktop_vbox == null or _root.get("desktop_figma_top_bar") == null:
		return
	stress_meter_panel = PanelContainer.new()
	stress_meter_panel.name = "LifeStressMeterPanel"
	stress_meter_panel.custom_minimum_size = Vector2(0, 16)
	stress_meter_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stress_meter_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	stress_meter_panel.gui_input.connect(on_stress_meter_gui_input)
	desktop_vbox.add_child(stress_meter_panel)
	desktop_vbox.move_child(stress_meter_panel, min(1, desktop_vbox.get_child_count() - 1))

	var margin := MarginContainer.new()
	margin.name = "LifeStressMeterMargin"
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	stress_meter_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "LifeStressMeterRow"
	row.custom_minimum_size = Vector2(0, 16)
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(row)

	stress_meter_title_label = Label.new()
	stress_meter_title_label.name = "LifeStressMeterTitleLabel"
	stress_meter_title_label.text = "STRESS LEVEL"
	stress_meter_title_label.custom_minimum_size = Vector2(140, 16)
	stress_meter_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stress_meter_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stress_meter_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stress_meter_title_label.add_theme_font_size_override("font_size", 10)
	stress_meter_title_label.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
	row.add_child(stress_meter_title_label)

	stress_meter_bar = ProgressBar.new()
	stress_meter_bar.name = "LifeStressMeterBar"
	stress_meter_bar.min_value = 0.0
	stress_meter_bar.max_value = 100.0
	stress_meter_bar.show_percentage = false
	stress_meter_bar.custom_minimum_size = Vector2(0, 8)
	stress_meter_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stress_meter_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stress_meter_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(stress_meter_bar)

	stress_meter_label = Label.new()
	stress_meter_label.name = "LifeStressMeterLabel"
	stress_meter_label.custom_minimum_size = Vector2(126, 16)
	stress_meter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stress_meter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stress_meter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stress_meter_label.add_theme_font_size_override("font_size", 10)
	stress_meter_label.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
	row.add_child(stress_meter_label)
	_sync_root_refs()
	refresh_stress_meter()


func refresh_stress_meter() -> void:
	_sync_dynamic_refs_from_root()
	if stress_meter_panel == null or stress_meter_bar == null:
		return
	if not RunState.has_active_run():
		stress_meter_panel.visible = false
		return
	stress_meter_panel.visible = true
	var life_state: Dictionary = RunState.get_player_life()
	var stress_value: float = float(life_state.get("stress_value", RunState.LIFE_DEFAULT_STRESS_VALUE))
	var stage: Dictionary = RunState.get_life_stress_stage(life_state)
	var stage_id: String = str(stage.get("id", "calm"))
	var fill_color: Color = stress_stage_color(stage_id)
	stress_meter_bar.value = stress_value
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(COLOR_DESKTOP_FRAME.r, COLOR_DESKTOP_FRAME.g, COLOR_DESKTOP_FRAME.b, 0.18)
	bg_style.border_color = Color(COLOR_DESKTOP_BROWN.r, COLOR_DESKTOP_BROWN.g, COLOR_DESKTOP_BROWN.b, 0.0)
	bg_style.set_border_width_all(0)
	bg_style.set_corner_radius_all(0)
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color(COLOR_DESKTOP_FRAME.r, COLOR_DESKTOP_FRAME.g, COLOR_DESKTOP_FRAME.b, 0.34)
	track_style.border_color = Color(COLOR_DESKTOP_BROWN.r, COLOR_DESKTOP_BROWN.g, COLOR_DESKTOP_BROWN.b, 0.22)
	track_style.set_border_width_all(1)
	track_style.set_corner_radius_all(0)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.border_color = Color(fill_color.r, fill_color.g, fill_color.b, 0.0)
	fill_style.set_corner_radius_all(0)
	stress_meter_panel.add_theme_stylebox_override("panel", bg_style)
	stress_meter_bar.add_theme_stylebox_override("background", track_style)
	stress_meter_bar.add_theme_stylebox_override("fill", fill_style)
	if stress_meter_title_label != null:
		stress_meter_title_label.text = "STRESS LEVEL"
		stress_meter_title_label.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
	var ap_penalty: int = RunState.get_life_stress_ap_penalty(life_state)
	var hospital_days: int = int(life_state.get("hospital_days_remaining", 0))
	var risk_days: int = int(life_state.get("burnout_risk_days_remaining", 0))
	var tooltip: String = "Stress %d/100: %s. AP penalty: %s." % [
		int(round(stress_value)),
		str(stage.get("label", "Calm")),
		"-%d" % ap_penalty if ap_penalty > 0 else "none"
	]
	if hospital_days > 0:
		tooltip += " Hospital recovery: %d trading day%s remaining." % [hospital_days, "" if hospital_days == 1 else "s"]
	elif bool(life_state.get("burnout_risk_active", false)):
		tooltip += " Burnout risk: %d trading day%s to recover before hospital." % [risk_days, "" if risk_days == 1 else "s"]
	stress_meter_panel.tooltip_text = tooltip
	if stress_meter_label != null:
		stress_meter_label.visible = true
		stress_meter_label.text = "%d/100 %s" % [
			int(round(stress_value)),
			str(stage.get("label", "Stress"))
		]


func stress_stage_color(stage_id: String) -> Color:
	match stage_id:
		"hospital":
			return Color(0.34, 0.05, 0.06, 1)
		"burnout_risk":
			return Color(0.74, 0.08, 0.06, 1)
		"strained":
			return Color(0.92, 0.30, 0.12, 1)
		"stressed":
			return Color(0.95, 0.62, 0.10, 1)
		"tense":
			return Color(0.82, 0.74, 0.22, 1)
		_:
			return Color(0.22, 0.62, 0.32, 1)


func on_stress_meter_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_set_active_app(APP_ID_LIFE)
			if _root != null:
				_root.get_viewport().set_input_as_handled()


func ensure_hospital_overlay() -> void:
	_sync_dynamic_refs_from_root()
	if hospital_overlay != null:
		_sync_root_refs()
		return
	hospital_overlay = Control.new()
	hospital_overlay.name = "HospitalOverlay"
	hospital_overlay.visible = false
	hospital_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hospital_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(hospital_overlay)
	var scrim := ColorRect.new()
	scrim.name = "HospitalOverlayScrim"
	scrim.color = Color(0.06, 0.04, 0.03, 0.78)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	hospital_overlay.add_child(scrim)
	var center := CenterContainer.new()
	center.name = "HospitalOverlayCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	hospital_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "HospitalOverlayPanel"
	panel.custom_minimum_size = Vector2(520, 260)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_DESKTOP_CREAM
	panel_style.border_color = COLOR_DESKTOP_BROWN
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	var title := Label.new()
	title.text = "Hospital Recovery"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
	vbox.add_child(title)
	hospital_body_label = Label.new()
	hospital_body_label.name = "HospitalBodyLabel"
	hospital_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hospital_body_label.add_theme_font_size_override("font_size", 14)
	hospital_body_label.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)
	vbox.add_child(hospital_body_label)
	hospital_advance_button = Button.new()
	hospital_advance_button.name = "HospitalAdvanceDayButton"
	hospital_advance_button.text = "ADVANCE DAY"
	hospital_advance_button.custom_minimum_size = Vector2(220, 42)
	hospital_advance_button.pressed.connect(on_hospital_advance_pressed)
	vbox.add_child(hospital_advance_button)
	_style_button(hospital_advance_button, COLOR_DESKTOP_BROWN, COLOR_DESKTOP_BROWN, COLOR_DESKTOP_CREAM, 5)
	_sync_root_refs()


func refresh_hospital_overlay() -> void:
	_sync_dynamic_refs_from_root()
	if hospital_overlay == null:
		return
	var hospital_days: int = 0
	if RunState.has_active_run():
		hospital_days = int(RunState.get_player_life().get("hospital_days_remaining", 0))
	hospital_overlay.visible = hospital_days > 0
	if hospital_days <= 0:
		return
	hospital_overlay.move_to_front()
	if hospital_body_label != null:
		hospital_body_label.text = "Stress hit full burnout. You are in hospital recovery for %d more trading day%s.\n\nAll apps are paused. Advance Day to recover." % [
			hospital_days,
			"" if hospital_days == 1 else "s"
		]
	if hospital_advance_button != null:
		hospital_advance_button.disabled = _is_advance_day_processing()
		hospital_advance_button.text = "ADVANCING..." if _is_advance_day_processing() else "ADVANCE DAY"


func on_hospital_advance_pressed() -> void:
	_on_next_day_pressed()


func ensure_jail_overlay() -> void:
	_sync_dynamic_refs_from_root()
	if jail_overlay != null:
		_sync_root_refs()
		return
	jail_overlay = Control.new()
	jail_overlay.name = "JailOverlay"
	jail_overlay.visible = false
	jail_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	jail_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(jail_overlay)
	var scrim := ColorRect.new()
	scrim.name = "JailOverlayScrim"
	scrim.color = Color(0.04, 0.04, 0.04, 0.80)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	jail_overlay.add_child(scrim)
	var center := CenterContainer.new()
	center.name = "JailOverlayCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	jail_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "JailOverlayPanel"
	panel.custom_minimum_size = Vector2(520, 260)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_DESKTOP_CREAM
	panel_style.border_color = COLOR_DESKTOP_BROWN
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	var title := Label.new()
	title.text = "Jail"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
	vbox.add_child(title)
	jail_body_label = Label.new()
	jail_body_label.name = "JailBodyLabel"
	jail_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	jail_body_label.add_theme_font_size_override("font_size", 14)
	jail_body_label.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)
	vbox.add_child(jail_body_label)
	jail_advance_button = Button.new()
	jail_advance_button.name = "JailAdvanceDayButton"
	jail_advance_button.text = "ADVANCE DAY"
	jail_advance_button.custom_minimum_size = Vector2(220, 42)
	jail_advance_button.pressed.connect(on_jail_advance_pressed)
	vbox.add_child(jail_advance_button)
	_style_button(jail_advance_button, COLOR_DESKTOP_BROWN, COLOR_DESKTOP_BROWN, COLOR_DESKTOP_CREAM, 5)
	_sync_root_refs()


func refresh_jail_overlay() -> void:
	_sync_dynamic_refs_from_root()
	if jail_overlay == null:
		return
	var legal_state: Dictionary = {}
	if RunState.has_active_run():
		var life_state: Dictionary = RunState.get_player_life()
		legal_state = life_state.get("legal_state", {}) if typeof(life_state.get("legal_state", {})) == TYPE_DICTIONARY else {}
	var legal_days: int = int(legal_state.get("days_remaining", 0))
	var legal_active: bool = bool(legal_state.get("active", false)) and legal_days > 0
	jail_overlay.visible = legal_active
	if not legal_active:
		return
	jail_overlay.move_to_front()
	if jail_body_label != null:
		var ticker: String = str(legal_state.get("target_ticker", "")).strip_edges()
		if ticker.is_empty():
			ticker = "the dirty tip"
		var fine_amount: float = float(legal_state.get("fine_amount", 0.0))
		var fine_text: String = ""
		if fine_amount > 0.0:
			fine_text = "\nFine paid: %s." % _format_currency(fine_amount)
		jail_body_label.text = "The dirty-tip trail around %s got traced back to you. You are in legal hold for %d more trading day%s.\n\nAll apps are paused. Advance Day to serve the hold.%s" % [
			ticker,
			legal_days,
			"" if legal_days == 1 else "s",
			fine_text
		]
	if jail_advance_button != null:
		jail_advance_button.disabled = _is_advance_day_processing()
		jail_advance_button.text = "ADVANCING..." if _is_advance_day_processing() else "ADVANCE DAY"


func on_jail_advance_pressed() -> void:
	_on_next_day_pressed()


func _sync_dynamic_refs_from_root() -> void:
	if _root == null:
		return
	life_app_button = _root.get("life_app_button") as Button
	life_app_label = _root.get("life_app_label") as Label
	life_window = _root.get("life_window") as MarginContainer
	stress_meter_panel = _root.get("stress_meter_panel") as PanelContainer
	stress_meter_bar = _root.get("stress_meter_bar") as ProgressBar
	stress_meter_title_label = _root.get("stress_meter_title_label") as Label
	stress_meter_label = _root.get("stress_meter_label") as Label
	hospital_overlay = _root.get("hospital_overlay") as Control
	hospital_body_label = _root.get("hospital_body_label") as Label
	hospital_advance_button = _root.get("hospital_advance_button") as Button
	jail_overlay = _root.get("jail_overlay") as Control
	jail_body_label = _root.get("jail_body_label") as Label
	jail_advance_button = _root.get("jail_advance_button") as Button


func _sync_root_refs() -> void:
	if _root == null:
		return
	_root.set("life_app_button", life_app_button)
	_root.set("life_app_label", life_app_label)
	_root.set("life_window", life_window)
	_root.set("stress_meter_panel", stress_meter_panel)
	_root.set("stress_meter_bar", stress_meter_bar)
	_root.set("stress_meter_title_label", stress_meter_title_label)
	_root.set("stress_meter_label", stress_meter_label)
	_root.set("hospital_overlay", hospital_overlay)
	_root.set("hospital_body_label", hospital_body_label)
	_root.set("hospital_advance_button", hospital_advance_button)
	_root.set("jail_overlay", jail_overlay)
	_root.set("jail_body_label", jail_body_label)
	_root.set("jail_advance_button", jail_advance_button)


func _is_advance_day_processing() -> bool:
	if _root == null:
		return false
	return bool(_root.get("advance_day_processing"))


func _style_news_tab_container(tab_container: TabContainer) -> void:
	if _root != null:
		_root.call("_style_news_tab_container", tab_container)


func _style_button(button: Button, fill_color: Color, border_color: Color, text_color: Color, corner_radius: int = 0) -> void:
	if _root != null:
		_root.call("_style_button", button, fill_color, border_color, text_color, corner_radius)


func _set_active_app(app_id: String) -> void:
	if _root != null:
		_root.call("_set_active_app", app_id)


func _on_next_day_pressed() -> void:
	if _root != null:
		_root.call("_on_next_day_pressed")


func _format_currency(value: float) -> String:
	if _root == null:
		return str(value)
	return str(_root.call("_format_currency", value))


func _refresh_ftue_progress() -> void:
	if _root != null:
		_root.call("_refresh_ftue_progress")


func _mark_guide_life_plan_reviewed() -> void:
	if _root != null:
		_root.call("_mark_guide_life_plan_reviewed")
