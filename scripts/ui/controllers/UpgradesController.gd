extends RefCounted

const COLOR_WINDOW_TEXT := Color(0.184314, 0.172549, 0.109804, 1)
const COLOR_DESKTOP_CREAM := Color(1.0, 0.976471, 0.929412, 1)
const COLOR_DESKTOP_PANEL := Color(0.945098, 0.909804, 0.803922, 1)
const COLOR_DESKTOP_BROWN := Color(0.509804, 0.231373, 0.0941176, 1)
const COLOR_DESKTOP_FRAME := Color(0.729412, 0.694118, 0.603922, 1)
const COLOR_DESKTOP_TEXT := Color(0.184314, 0.172549, 0.109804, 1)
const COLOR_ACADEMY_BORDER := Color(0.52549, 0.396078, 0.160784, 1)

var _root = null
var _upgrade_window: MarginContainer = null
var _upgrade_window_body: PanelContainer = null
var _upgrade_title_label: Label = null
var _upgrade_cash_label: Label = null
var _upgrade_summary_label: Label = null
var _upgrade_cards_vbox: VBoxContainer = null
var _upgrade_purchase_dialog: ConfirmationDialog = null
var _upgrade_purchase_body_label: Label = null
var _pending_upgrade_track_id: String = ""


func setup(root, refs: Dictionary) -> void:
	_root = root
	_upgrade_window = refs.get("window", null) as MarginContainer
	_upgrade_window_body = refs.get("window_body", null) as PanelContainer
	_upgrade_title_label = refs.get("title_label", null) as Label
	_upgrade_cash_label = refs.get("cash_label", null) as Label
	_upgrade_summary_label = refs.get("summary_label", null) as Label
	_upgrade_cards_vbox = refs.get("cards_vbox", null) as VBoxContainer
	if _root != null:
		_upgrade_purchase_dialog = _root.get("upgrade_purchase_dialog") as ConfirmationDialog
		_upgrade_purchase_body_label = _root.get("upgrade_purchase_body_label") as Label


func refresh() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	if _upgrade_cards_vbox == null:
		return
	for child: Node in _upgrade_cards_vbox.get_children():
		_upgrade_cards_vbox.remove_child(child)
		child.queue_free()

	_upgrade_title_label.text = "Upgrades"
	if not RunState.has_active_run():
		_upgrade_cash_label.text = "No run loaded"
		_upgrade_summary_label.text = "Start a run to buy upgrades."
		_apply_font_overrides(_upgrade_window)
		_log_perf_elapsed("_refresh_upgrades", started_at_usec)
		return

	var snapshot: Dictionary = GameManager.get_upgrade_shop_snapshot()
	var action_snapshot: Dictionary = snapshot.get("daily_action", {})
	var upgrade_block_reason: String = ""
	for track_value: Variant in snapshot.get("tracks", []):
		if typeof(track_value) == TYPE_DICTIONARY:
			var block_track: Dictionary = track_value
			upgrade_block_reason = str(block_track.get("block_reason", ""))
			if not upgrade_block_reason.is_empty():
				break
	_upgrade_cash_label.text = "Cash %s" % _format_currency(float(snapshot.get("cash", 0.0)))
	if not upgrade_block_reason.is_empty():
		_upgrade_summary_label.text = upgrade_block_reason
	else:
		_upgrade_summary_label.text = "Network AP %d/%d today. Upgrades are paid from available cash." % [
			int(action_snapshot.get("remaining", 0)),
			int(action_snapshot.get("limit", 10))
		]

	for track_value: Variant in snapshot.get("tracks", []):
		if typeof(track_value) != TYPE_DICTIONARY:
			continue
		var track: Dictionary = track_value
		_upgrade_cards_vbox.add_child(_build_upgrade_card(track))
	_apply_font_overrides(_upgrade_cards_vbox)
	_log_perf_elapsed("_refresh_upgrades", started_at_usec)


func ensure_purchase_dialog() -> void:
	if _upgrade_purchase_dialog != null:
		_sync_root_dialog_refs()
		return
	if _root == null:
		return

	_upgrade_purchase_dialog = ConfirmationDialog.new()
	_upgrade_purchase_dialog.name = "UpgradePurchaseDialog"
	_upgrade_purchase_dialog.title = "Confirm Upgrade"
	_root.add_child(_upgrade_purchase_dialog)
	_upgrade_purchase_dialog.confirmed.connect(_on_upgrade_purchase_confirmed)
	_upgrade_purchase_dialog.get_ok_button().text = "Buy Upgrade"
	_upgrade_purchase_dialog.get_cancel_button().text = "Cancel"

	var content_panel: PanelContainer = PanelContainer.new()
	content_panel.name = "UpgradePurchaseContentPanel"
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_upgrade_purchase_dialog.add_child(content_panel)

	var dialog_margin: MarginContainer = MarginContainer.new()
	dialog_margin.name = "UpgradePurchaseContentMargin"
	dialog_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_margin.add_theme_constant_override("margin_left", 18)
	dialog_margin.add_theme_constant_override("margin_top", 18)
	dialog_margin.add_theme_constant_override("margin_right", 18)
	dialog_margin.add_theme_constant_override("margin_bottom", 18)
	content_panel.add_child(dialog_margin)

	_upgrade_purchase_body_label = Label.new()
	_upgrade_purchase_body_label.name = "UpgradePurchaseBodyLabel"
	_upgrade_purchase_body_label.custom_minimum_size = Vector2(500, 150)
	_upgrade_purchase_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_upgrade_purchase_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_upgrade_purchase_body_label.text = ""
	dialog_margin.add_child(_upgrade_purchase_body_label)
	_sync_root_dialog_refs()
	style_purchase_dialog()


func style_purchase_dialog() -> void:
	if _upgrade_purchase_dialog == null:
		return

	UiTheme.style_panel(_upgrade_purchase_dialog, "dialog")
	var dialog_style: StyleBoxFlat = _upgrade_purchase_dialog.get_theme_stylebox("panel") as StyleBoxFlat
	if dialog_style == null:
		dialog_style = UiTheme.make_stylebox(UiTheme.color("desktop.cream"), UiTheme.color("desktop.brown"), 2, 6)
	_upgrade_purchase_dialog.add_theme_stylebox_override("panel", dialog_style)
	_upgrade_purchase_dialog.add_theme_stylebox_override("embedded_border", dialog_style)
	_upgrade_purchase_dialog.add_theme_stylebox_override("embedded_unfocused_border", dialog_style)
	_upgrade_purchase_dialog.add_theme_color_override("font_color", UiTheme.color("desktop.text"))
	_upgrade_purchase_dialog.add_theme_color_override("title_color", UiTheme.color("desktop.brown"))
	_upgrade_purchase_dialog.add_theme_font_size_override("font_size", UiTheme.font_size("body"))

	var content_panel: PanelContainer = _upgrade_purchase_dialog.find_child("UpgradePurchaseContentPanel", true, false) as PanelContainer
	if content_panel != null:
		var content_style := StyleBoxFlat.new()
		content_style.bg_color = Color(0.992157, 0.964706, 0.870588, 1)
		content_style.border_color = Color(0.52549, 0.396078, 0.160784, 0.85)
		content_style.set_border_width_all(1)
		content_style.set_corner_radius_all(0)
		content_panel.add_theme_stylebox_override("panel", content_style)

	if _upgrade_purchase_body_label != null:
		UiTheme.style_label(_upgrade_purchase_body_label, "desktop_body")
		_upgrade_purchase_body_label.add_theme_constant_override("line_spacing", 5)

	var ok_button: Button = _upgrade_purchase_dialog.get_ok_button()
	if ok_button != null:
		_style_button(ok_button, COLOR_DESKTOP_BROWN, COLOR_DESKTOP_BROWN.darkened(0.12), COLOR_DESKTOP_CREAM, 5)
	var cancel_button: Button = _upgrade_purchase_dialog.get_cancel_button()
	if cancel_button != null:
		_style_button(cancel_button, COLOR_DESKTOP_PANEL, COLOR_DESKTOP_FRAME, COLOR_DESKTOP_TEXT, 5)


func _build_upgrade_card(track: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "UpgradeCard_%s" % str(track.get("id", ""))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_cream_app_panel(panel, COLOR_DESKTOP_CREAM, COLOR_ACADEMY_BORDER, 4, 1)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 4)
	row.add_child(copy)

	var title := Label.new()
	title.text = "%s  |  Tier %d" % [str(track.get("label", "Upgrade")), int(track.get("tier", 4))]
	title.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	copy.add_child(title)

	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = "%s\nCurrent: %s" % [
		str(track.get("description", "")),
		str(track.get("effect_label", ""))
	]
	body.add_theme_color_override("font_color", Color(0.352941, 0.309804, 0.203922, 1))
	copy.add_child(body)

	var purchase_button := Button.new()
	purchase_button.name = "UpgradeBuyButton_%s" % str(track.get("id", ""))
	purchase_button.custom_minimum_size = Vector2(190, 44)
	if bool(track.get("maxed", false)):
		purchase_button.text = "Max Tier"
		purchase_button.disabled = true
	else:
		purchase_button.text = "Buy Tier %d\n%s" % [
			int(track.get("next_tier", 0)),
			_format_currency(float(track.get("next_cost", 0.0)))
		]
		purchase_button.disabled = not bool(track.get("can_purchase", false))
		var block_reason: String = str(track.get("block_reason", ""))
		purchase_button.tooltip_text = block_reason if not block_reason.is_empty() else "Next: %s" % str(track.get("next_effect_label", ""))
		purchase_button.pressed.connect(_on_upgrade_purchase_pressed.bind(str(track.get("id", ""))))
	row.add_child(purchase_button)
	_style_cream_app_button(purchase_button, not purchase_button.disabled)
	return panel


func _upgrade_track_from_snapshot(snapshot: Dictionary, track_id: String) -> Dictionary:
	for track_value: Variant in snapshot.get("tracks", []):
		if typeof(track_value) != TYPE_DICTIONARY:
			continue
		var track: Dictionary = track_value
		if str(track.get("id", "")) == track_id:
			return track
	return {}


func _on_upgrade_purchase_pressed(track_id: String) -> void:
	ensure_purchase_dialog()
	var snapshot: Dictionary = GameManager.get_upgrade_shop_snapshot()
	var track: Dictionary = _upgrade_track_from_snapshot(snapshot, track_id)
	if track.is_empty():
		_show_toast("Upgrade track not found.", false)
		refresh()
		return
	if bool(track.get("maxed", false)):
		_show_toast("%s is already tier 1." % str(track.get("label", "Upgrade")), false)
		refresh()
		return
	if not bool(track.get("can_purchase", false)):
		_show_toast(
			"Need %s for %s." % [
				_format_currency(float(track.get("next_cost", 0.0))),
				str(track.get("label", "this upgrade"))
			],
			false
		)
		refresh()
		return

	_pending_upgrade_track_id = track_id
	var cost: float = float(track.get("next_cost", 0.0))
	var cash: float = float(snapshot.get("cash", 0.0))
	_upgrade_purchase_body_label.text = "Buy %s Tier %d?\n\nCurrent: Tier %d - %s\nNext: Tier %d - %s\nCost: %s\nCash after purchase: %s" % [
		str(track.get("label", "Upgrade")),
		int(track.get("next_tier", 0)),
		int(track.get("tier", 4)),
		str(track.get("effect_label", "")),
		int(track.get("next_tier", 0)),
		str(track.get("next_effect_label", "")),
		_format_currency(cost),
		_format_currency(cash - cost)
	]
	style_purchase_dialog()
	_upgrade_purchase_dialog.popup_centered(Vector2i(560, 260))


func _on_upgrade_purchase_confirmed() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	if _pending_upgrade_track_id.is_empty():
		_show_toast("No upgrade selected.", false)
		return

	var track_id: String = _pending_upgrade_track_id
	_pending_upgrade_track_id = ""
	var result: Dictionary = GameManager.purchase_upgrade(track_id)
	if _upgrade_purchase_dialog != null:
		_upgrade_purchase_dialog.hide()
	_show_toast(str(result.get("message", "Upgrade updated.")), bool(result.get("success", false)))
	_log_perf_elapsed("_on_upgrade_purchase_confirmed", started_at_usec)


func _sync_root_dialog_refs() -> void:
	if _root == null:
		return
	_root.set("upgrade_purchase_dialog", _upgrade_purchase_dialog)
	_root.set("upgrade_purchase_body_label", _upgrade_purchase_body_label)


func _format_currency(value: float) -> String:
	if _root == null:
		return "%.2f" % value
	return str(_root.call("_format_currency", value))


func _show_toast(message: String, success: bool) -> void:
	if _root != null:
		_root.call("_show_toast", message, success)


func _apply_font_overrides(target: Node) -> void:
	if _root != null and target != null:
		_root.call("_apply_font_overrides_to_subtree", target)


func _log_perf_elapsed(label: String, started_at_usec: int) -> void:
	if _root != null:
		_root.call("_log_perf_elapsed", label, started_at_usec)


func _style_cream_app_panel(panel: PanelContainer, fill_color: Color, border_color: Color, corner_radius: int = 0, border_width: int = 0) -> void:
	if _root != null:
		_root.call("_style_cream_app_panel", panel, fill_color, border_color, corner_radius, border_width)


func _style_cream_app_button(button: Button, enabled: bool) -> void:
	if _root != null:
		_root.call("_style_cream_app_button", button, enabled)


func _style_button(button: Button, fill_color: Color, border_color: Color, text_color: Color, corner_radius: int = 0) -> void:
	if _root != null:
		_root.call("_style_button", button, fill_color, border_color, text_color, corner_radius)
