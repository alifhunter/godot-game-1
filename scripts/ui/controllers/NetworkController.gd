extends RefCounted

const UI_THEME := preload("res://scripts/ui/UITheme.gd")

const NETWORK_FOLLOWUP_ACTIONS := {
	0: "thank",
	1: "ask_why",
	2: "challenge"
}
const COLOR_WINDOW_TEXT := UI_THEME.COLOR_WINDOW_TEXT

var portfolio_trading_calendar = preload("res://systems/TradingCalendar.gd").new()
var _root = null
var current_network_snapshot: Dictionary = {}
var selected_network_contact_id: String = ""
var selected_network_journal_id: String = ""
var selected_network_journal_filter: String = "all"
var selected_company_id: String = ""
var network_window: MarginContainer = null
var network_window_body: PanelContainer = null
var network_title_label: Label = null
var network_recognition_label: Label = null
var network_summary_label: Label = null
var network_list_panel: PanelContainer = null
var network_detail_panel: PanelContainer = null
var network_contacts_label: Label = null
var network_contacts_list: ItemList = null
var network_requests_label: Label = null
var network_requests_list: ItemList = null
var network_contact_name_label: Label = null
var network_contact_meta_label: Label = null
var network_contact_body_label: Label = null
var network_meet_button: Button = null
var network_tip_button: Button = null
var network_request_button: Button = null
var network_referral_button: Button = null
var network_corporate_action_label: Label = null
var network_open_meeting_button: Button = null
var network_followup_button: MenuButton = null
var network_tip_history_label: Label = null
var network_crosscheck_label: Label = null
var network_source_check_button: Button = null
var network_journal_label: Label = null
var network_journal_filter_row: HBoxContainer = null
var network_journal_filter_buttons: Dictionary = {}
var network_journal_list: ItemList = null
var network_detail_scroll: ScrollContainer = null
var network_detail_scroll_content: VBoxContainer = null
var network_journal_detail_label: Label = null


func setup(root, refs: Dictionary) -> void:
	_root = root
	network_window = refs.get("window", null) as MarginContainer
	network_window_body = refs.get("window_body", null) as PanelContainer
	network_title_label = refs.get("title_label", null) as Label
	network_recognition_label = refs.get("recognition_label", null) as Label
	network_summary_label = refs.get("summary_label", null) as Label
	network_list_panel = refs.get("list_panel", null) as PanelContainer
	network_detail_panel = refs.get("detail_panel", null) as PanelContainer
	network_contacts_label = refs.get("contacts_label", null) as Label
	network_contacts_list = refs.get("contacts_list", null) as ItemList
	network_requests_label = refs.get("requests_label", null) as Label
	network_requests_list = refs.get("requests_list", null) as ItemList
	network_contact_name_label = refs.get("contact_name_label", null) as Label
	network_contact_meta_label = refs.get("contact_meta_label", null) as Label
	network_contact_body_label = refs.get("contact_body_label", null) as Label
	network_meet_button = refs.get("meet_button", null) as Button
	network_tip_button = refs.get("tip_button", null) as Button
	network_request_button = refs.get("request_button", null) as Button
	network_referral_button = refs.get("referral_button", null) as Button
	_sync_from_root_state()
	_sync_dynamic_refs_from_root()
	_connect_network_signals()
	_sync_root_refs()


func refresh() -> void:
	_sync_from_root_state()
	_refresh_network()


func ensure_context_ui() -> void:
	_sync_dynamic_refs_from_root()
	if network_corporate_action_label == null:
		network_corporate_action_label = Label.new()
		network_corporate_action_label.name = "NetworkCorporateActionLabel"
		network_corporate_action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		network_corporate_action_label.visible = false
		var network_detail_vbox: VBoxContainer = network_contact_body_label.get_parent()
		var action_row: HBoxContainer = network_meet_button.get_parent()
		network_detail_vbox.add_child(network_corporate_action_label)
		network_detail_vbox.move_child(network_corporate_action_label, network_detail_vbox.get_children().find(action_row))

	if network_tip_history_label == null:
		network_tip_history_label = Label.new()
		network_tip_history_label.name = "NetworkTipHistoryLabel"
		network_tip_history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		network_tip_history_label.visible = false
		var network_detail_vbox: VBoxContainer = network_contact_body_label.get_parent()
		var action_row: HBoxContainer = network_meet_button.get_parent()
		network_detail_vbox.add_child(network_tip_history_label)
		network_detail_vbox.move_child(network_tip_history_label, network_detail_vbox.get_children().find(action_row))

	if network_crosscheck_label == null:
		network_crosscheck_label = Label.new()
		network_crosscheck_label.name = "NetworkCrosscheckLabel"
		network_crosscheck_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		network_crosscheck_label.visible = false
		var network_detail_vbox: VBoxContainer = network_contact_body_label.get_parent()
		var action_row: HBoxContainer = network_meet_button.get_parent()
		network_detail_vbox.add_child(network_crosscheck_label)
		network_detail_vbox.move_child(network_crosscheck_label, network_detail_vbox.get_children().find(action_row))

	if network_open_meeting_button == null:
		network_open_meeting_button = Button.new()
		network_open_meeting_button.name = "NetworkOpenMeetingButton"
		network_open_meeting_button.text = "Open Meeting"
		network_open_meeting_button.visible = false
		network_open_meeting_button.disabled = true
		network_open_meeting_button.tooltip_text = "Open the linked corporate meeting."
		network_open_meeting_button.pressed.connect(on_open_meeting_pressed)
		var network_detail_vbox: VBoxContainer = network_contact_body_label.get_parent()
		var action_row: HBoxContainer = network_meet_button.get_parent()
		network_detail_vbox.add_child(network_open_meeting_button)
		network_detail_vbox.move_child(network_open_meeting_button, network_detail_vbox.get_children().find(action_row))

	if network_followup_button == null:
		network_followup_button = MenuButton.new()
		network_followup_button.name = "NetworkFollowupButton"
		network_followup_button.text = "Follow Up"
		network_followup_button.visible = false
		network_followup_button.disabled = true
		network_followup_button.tooltip_text = "Follow up on the latest resolved contact read."
		network_followup_button.get_popup().id_pressed.connect(on_followup_selected)
		var network_action_row: HBoxContainer = network_meet_button.get_parent()
		network_action_row.add_child(network_followup_button)

	if network_source_check_button == null:
		network_source_check_button = Button.new()
		network_source_check_button.name = "NetworkSourceCheckButton"
		network_source_check_button.text = "Ask About Conflict"
		network_source_check_button.visible = false
		network_source_check_button.disabled = true
		network_source_check_button.tooltip_text = "Ask this contact why another source disagrees."
		network_source_check_button.pressed.connect(on_source_check_pressed)
		var network_action_row: HBoxContainer = network_meet_button.get_parent()
		network_action_row.add_child(network_source_check_button)

	if network_journal_detail_label == null:
		network_journal_detail_label = Label.new()
		network_journal_detail_label.name = "NetworkJournalDetailLabel"
		network_journal_detail_label.visible = false
		network_journal_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		network_journal_detail_label.text = ""
		var network_detail_vbox: VBoxContainer = network_contact_body_label.get_parent()
		var action_row: HBoxContainer = network_meet_button.get_parent()
		network_detail_vbox.add_child(network_journal_detail_label)
		network_detail_vbox.move_child(network_journal_detail_label, network_detail_vbox.get_children().find(action_row))

	if network_journal_list == null:
		var network_list_vbox: VBoxContainer = network_requests_list.get_parent()
		network_contacts_list.custom_minimum_size = Vector2(0, 132)
		network_requests_list.custom_minimum_size = Vector2(0, 76)
		network_journal_label = Label.new()
		network_journal_label.name = "NetworkJournalLabel"
		network_journal_label.text = "Journal"
		network_list_vbox.add_child(network_journal_label)

		network_journal_filter_row = HBoxContainer.new()
		network_journal_filter_row.name = "NetworkJournalFilterRow"
		network_journal_filter_row.add_theme_constant_override("separation", 4)
		network_list_vbox.add_child(network_journal_filter_row)
		for filter_value in [
			{"id": "all", "label": "All"},
			{"id": "tips", "label": "Tips"},
			{"id": "requests", "label": "Req"},
			{"id": "referrals", "label": "Refs"},
			{"id": "source_checks", "label": "Checks"}
		]:
			var filter_id: String = str(filter_value.get("id", "all"))
			var filter_button := Button.new()
			filter_button.name = "NetworkJournalFilter%sButton" % filter_id.capitalize().replace("_", "")
			filter_button.text = str(filter_value.get("label", filter_id.capitalize()))
			filter_button.custom_minimum_size = Vector2(42, 24)
			filter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			filter_button.tooltip_text = "Show %s journal rows." % str(filter_value.get("label", filter_id))
			filter_button.pressed.connect(on_journal_filter_pressed.bind(filter_id))
			network_journal_filter_buttons[filter_id] = filter_button
			network_journal_filter_row.add_child(filter_button)

		network_journal_list = ItemList.new()
		network_journal_list.name = "NetworkJournalList"
		network_journal_list.custom_minimum_size = Vector2(0, 88)
		network_journal_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		network_journal_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		network_journal_list.tooltip_text = "Recent tips, requests, referrals, follow-ups, and source checks."
		network_journal_list.allow_reselect = true
		network_list_vbox.add_child(network_journal_list)

	_ensure_network_detail_scroll()
	_connect_network_signals()
	_sync_root_refs()


func ensure_detail_scroll() -> void:
	_ensure_network_detail_scroll()
	_sync_root_refs()


func rebuild_contact_list() -> void:
	_rebuild_network_contact_list()


func rebuild_request_list() -> void:
	_rebuild_network_request_list()


func rebuild_journal_list() -> void:
	_rebuild_network_journal_list()


func refresh_journal_filter_buttons() -> void:
	_refresh_network_journal_filter_buttons()


func network_state_for_contact(network_snapshot: Dictionary, contact_id: String) -> String:
	return _network_state_for_contact(network_snapshot, contact_id)


func network_contact_target_company(contact: Dictionary) -> String:
	_sync_from_root_state()
	return _network_contact_target_company(contact)


func on_contact_selected(index: int) -> void:
	_on_network_contact_selected(index)


func on_request_selected(index: int) -> void:
	_on_network_request_selected(index)


func on_journal_selected(index: int) -> void:
	_on_network_journal_selected(index)


func on_journal_filter_pressed(filter_id: String) -> void:
	_on_network_journal_filter_pressed(filter_id)


func on_meet_pressed() -> void:
	_on_network_meet_pressed()


func on_tip_pressed() -> void:
	_on_network_tip_pressed()


func on_request_pressed() -> void:
	_on_network_request_pressed()


func on_referral_pressed() -> void:
	_on_network_referral_pressed()


func on_followup_selected(menu_id: int) -> void:
	_on_network_followup_selected(menu_id)


func on_source_check_pressed() -> void:
	_on_network_source_check_pressed()


func on_open_meeting_pressed() -> void:
	_on_network_open_meeting_pressed()


func _connect_network_signals() -> void:
	if network_contacts_list != null:
		_connect_signal_once(network_contacts_list.item_selected, Callable(self, "on_contact_selected"))
	if network_requests_list != null:
		_connect_signal_once(network_requests_list.item_selected, Callable(self, "on_request_selected"))
	if network_journal_list != null:
		_connect_signal_once(network_journal_list.item_selected, Callable(self, "on_journal_selected"))
	if network_meet_button != null:
		_connect_signal_once(network_meet_button.pressed, Callable(self, "on_meet_pressed"))
	if network_tip_button != null:
		_connect_signal_once(network_tip_button.pressed, Callable(self, "on_tip_pressed"))
	if network_request_button != null:
		_connect_signal_once(network_request_button.pressed, Callable(self, "on_request_pressed"))
	if network_referral_button != null:
		_connect_signal_once(network_referral_button.pressed, Callable(self, "on_referral_pressed"))
	if network_open_meeting_button != null:
		_connect_signal_once(network_open_meeting_button.pressed, Callable(self, "on_open_meeting_pressed"))
	if network_followup_button != null:
		_connect_signal_once(network_followup_button.get_popup().id_pressed, Callable(self, "on_followup_selected"))
	if network_source_check_button != null:
		_connect_signal_once(network_source_check_button.pressed, Callable(self, "on_source_check_pressed"))


func _connect_signal_once(signal_object: Signal, handler: Callable) -> void:
	if not signal_object.is_connected(handler):
		signal_object.connect(handler)


func _sync_from_root_state() -> void:
	# Network-domain state is controller-owned; only the Stock-owned selected
	# company id still syncs down (until StockController owns it end-to-end).
	if _root == null:
		return
	selected_company_id = str(_root.get("selected_company_id"))
	if selected_network_journal_filter.is_empty():
		selected_network_journal_filter = "all"


func _sync_dynamic_refs_from_root() -> void:
	if _root == null:
		return
	network_corporate_action_label = _root.get("network_corporate_action_label") as Label
	network_open_meeting_button = _root.get("network_open_meeting_button") as Button
	network_followup_button = _root.get("network_followup_button") as MenuButton
	network_tip_history_label = _root.get("network_tip_history_label") as Label
	network_crosscheck_label = _root.get("network_crosscheck_label") as Label
	network_source_check_button = _root.get("network_source_check_button") as Button
	network_journal_label = _root.get("network_journal_label") as Label
	var root_filter_buttons: Variant = _root.get("network_journal_filter_buttons")
	if typeof(root_filter_buttons) == TYPE_DICTIONARY:
		network_journal_filter_buttons = root_filter_buttons as Dictionary
	network_journal_list = _root.get("network_journal_list") as ItemList
	network_detail_scroll = _root.get("network_detail_scroll") as ScrollContainer
	network_detail_scroll_content = _root.get("network_detail_scroll_content") as VBoxContainer
	network_journal_detail_label = _root.get("network_journal_detail_label") as Label



func _sync_root_refs() -> void:
	if _root == null:
		return
	_root.set("network_corporate_action_label", network_corporate_action_label)
	_root.set("network_open_meeting_button", network_open_meeting_button)
	_root.set("network_followup_button", network_followup_button)
	_root.set("network_tip_history_label", network_tip_history_label)
	_root.set("network_crosscheck_label", network_crosscheck_label)
	_root.set("network_source_check_button", network_source_check_button)
	_root.set("network_journal_label", network_journal_label)
	_root.set("network_journal_filter_row", network_journal_filter_row)
	_root.set("network_journal_filter_buttons", network_journal_filter_buttons)
	_root.set("network_journal_list", network_journal_list)
	_root.set("network_detail_scroll", network_detail_scroll)
	_root.set("network_detail_scroll_content", network_detail_scroll_content)
	_root.set("network_journal_detail_label", network_journal_detail_label)


func _refresh_network() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	current_network_snapshot = {}
	network_title_label.text = "Network"
	if not RunState.has_active_run():
		selected_network_contact_id = ""
		network_recognition_label.text = "Recognition: Unknown"
		network_summary_label.text = "Start a run to meet market contacts."
		network_contacts_list.clear()
		network_requests_list.clear()
		if network_journal_list != null:
			network_journal_list.clear()
		_show_network_contact({})
		_log_perf_elapsed("_refresh_network", started_at_usec)
		return

	current_network_snapshot = GameManager.get_network_snapshot()
	var recognition: Dictionary = current_network_snapshot.get("recognition", {})
	network_recognition_label.text = "Recognition: %s (%d)" % [
		str(recognition.get("label", "Unknown")),
		int(round(float(recognition.get("score", 0.0))))
	]
	var action_snapshot: Dictionary = GameManager.get_daily_action_snapshot()
	network_summary_label.text = "%d / %d contacts met  |  AP %d/%d  |  Contacts are discovered through News, referrals, and RUPSLB rooms." % [
		int(current_network_snapshot.get("met_count", 0)),
		int(current_network_snapshot.get("contact_cap", 2)),
		int(action_snapshot.get("remaining", 0)),
		int(action_snapshot.get("limit", 10))
	]
	_rebuild_network_contact_list()
	_rebuild_network_request_list()
	_rebuild_network_journal_list()
	_log_perf_elapsed("_refresh_network", started_at_usec)

func _rebuild_network_contact_list() -> void:
	network_contacts_list.clear()
	var rows: Array = []
	rows.append_array(current_network_snapshot.get("contacts", []))
	if rows.is_empty():
		selected_network_contact_id = ""
		network_contacts_list.add_item("No contacts yet. Meet a lead from News, referrals, or an RUPSLB room first.")
		network_contacts_list.set_item_disabled(0, true)
		_show_network_contact({})
		return

	var selected_index: int = -1
	for row_index in range(rows.size()):
		var row: Dictionary = rows[row_index]
		var affiliation_label: String = "Insider" if str(row.get("affiliation_type", "floater")) == "insider" else "Floater"
		var prefix: String = "Met %s" % affiliation_label if bool(row.get("met", false)) else "Lead %s" % affiliation_label
		if str(row.get("source_type", "")) == "referral" and not bool(row.get("met", false)):
			prefix = "Referred Insider"
		var display_role: String = str(row.get("role", ""))
		var twooter_handle: String = str(row.get("twooter_handle", "")).strip_edges()
		if not twooter_handle.is_empty():
			display_role += " | %s" % twooter_handle
		var last_tip_label: String = str(row.get("last_tip_label", ""))
		if not last_tip_label.is_empty():
			display_role += " | %s" % last_tip_label
		network_contacts_list.add_item("%s  |  %s - %s" % [
			prefix,
			str(row.get("display_name", "")),
			display_role
		])
		var item_index: int = network_contacts_list.item_count - 1
		network_contacts_list.set_item_metadata(item_index, row.duplicate(true))
		if str(row.get("id", "")) == selected_network_contact_id:
			selected_index = item_index

	if selected_index == -1:
		selected_index = 0
		selected_network_contact_id = str(rows[0].get("id", ""))
	network_contacts_list.select(selected_index)
	_show_network_contact(rows[selected_index])

func _rebuild_network_request_list() -> void:
	network_requests_list.clear()
	var requests: Array = current_network_snapshot.get("requests", [])
	for request_value in requests:
		var request: Dictionary = request_value
		network_requests_list.add_item("%s  |  %s  |  %s" % [
			str(request.get("status", "pending")).capitalize(),
			_ticker_for_company(str(request.get("target_company_id", ""))),
			_network_request_due_label(request)
		])
		network_requests_list.set_item_metadata(network_requests_list.item_count - 1, request.duplicate(true))
	if requests.is_empty():
		network_requests_list.add_item("No active requests.")
		network_requests_list.set_item_disabled(0, true)

func _network_request_due_label(request: Dictionary) -> String:
	if str(request.get("request_type", "")) == "dirty_tip":
		match str(request.get("status", "")):
			"offered":
				return "Awaiting decision"
			"accepted":
				return "Active until day %d" % int(request.get("active_until_day_index", request.get("due_day_index", 0)))
			"reported":
				return "Reported"
			"declined":
				return "Declined"
			"caught":
				return "Caught"
			"resolved_clean":
				return "Resolved"
			"expired":
				return "Expired"
	var due_date_text: String = _network_request_due_date_text(request)
	if due_date_text.is_empty():
		return "Due date unknown"
	return "Due %s" % due_date_text

func _network_request_due_date_text(request: Dictionary) -> String:
	var due_day_index: int = int(request.get("due_day_index", 0))
	if due_day_index <= 0:
		return ""
	var date_info: Dictionary = portfolio_trading_calendar.trade_date_for_index(max(due_day_index, 1))
	var month_names := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var month_index: int = clamp(int(date_info.get("month", 1)) - 1, 0, month_names.size() - 1)
	return "%s %d, %d" % [
		month_names[month_index],
		int(date_info.get("day", 1)),
		int(date_info.get("year", 2020))
	]

func _rebuild_network_journal_list() -> void:
	if network_journal_list == null:
		return
	network_journal_list.clear()
	var rows: Array = current_network_snapshot.get("journal", [])
	var selected_item_index: int = -1
	var selected_contact: Dictionary = _selected_network_contact_for_journal_context()
	var grouped_rows: Dictionary = {
		"tips": [],
		"requests": [],
		"referrals": [],
		"source_checks": []
	}
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var group_key: String = _network_journal_group_key(str(row.get("type", "")))
		if not grouped_rows.has(group_key):
			group_key = "tips"
		if selected_network_journal_filter != "all" and selected_network_journal_filter != group_key:
			continue
		var rows_for_group: Array = grouped_rows.get(group_key, [])
		rows_for_group.append(row)
		grouped_rows[group_key] = rows_for_group
	for group_key in ["tips", "requests", "referrals", "source_checks"]:
		var group_rows: Array = grouped_rows.get(group_key, [])
		if group_rows.is_empty():
			continue
		network_journal_list.add_item(_network_journal_group_label(group_key))
		var header_index: int = network_journal_list.item_count - 1
		network_journal_list.set_item_disabled(header_index, true)
		network_journal_list.set_item_custom_fg_color(header_index, Color(0.454902, 0.337255, 0.141176, 1))
		network_journal_list.set_item_custom_bg_color(header_index, Color(0.866667, 0.807843, 0.635294, 0.58))
		for row_value in group_rows:
			var row: Dictionary = row_value
			var line: String = "D%d  |  %s" % [
				int(row.get("day_index", 0)),
				str(row.get("title", "Network note"))
			]
			var detail: String = str(row.get("detail", ""))
			if not detail.is_empty():
				line += "  -  %s" % detail
			if line.length() > 150:
				line = line.substr(0, 147) + "..."
			network_journal_list.add_item(line)
			var item_index: int = network_journal_list.item_count - 1
			network_journal_list.set_item_metadata(item_index, row.duplicate(true))
			if _network_journal_row_matches_contact(row, selected_contact):
				network_journal_list.set_item_custom_bg_color(item_index, Color(0.835294, 0.764706, 0.529412, 0.30))
				network_journal_list.set_item_custom_fg_color(item_index, COLOR_WINDOW_TEXT)
			if str(row.get("id", "")) == selected_network_journal_id:
				selected_item_index = item_index
	if rows.is_empty():
		network_journal_list.add_item("No journal entries yet.")
		network_journal_list.set_item_disabled(0, true)
		selected_network_journal_id = ""
		_show_network_journal_detail({})
	elif network_journal_list.item_count <= 0:
		network_journal_list.add_item("No journal entries for this filter.")
		network_journal_list.set_item_disabled(0, true)
		selected_network_journal_id = ""
		_show_network_journal_detail({})
	elif selected_item_index >= 0:
		network_journal_list.select(selected_item_index)
		var selected_metadata: Variant = network_journal_list.get_item_metadata(selected_item_index)
		if typeof(selected_metadata) == TYPE_DICTIONARY:
			_show_network_journal_detail(selected_metadata)
	elif not selected_network_journal_id.is_empty():
		selected_network_journal_id = ""
		_show_network_journal_detail({})

func _selected_network_contact_for_journal_context() -> Dictionary:
	if selected_network_contact_id.is_empty():
		return {}
	for row_value in current_network_snapshot.get("contacts", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("id", "")) == selected_network_contact_id:
			return row
	for row_value in current_network_snapshot.get("discoveries", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("id", "")) == selected_network_contact_id:
			return row
	return {}

func _network_journal_row_matches_contact(row: Dictionary, contact: Dictionary) -> bool:
	if contact.is_empty():
		return false
	if not str(row.get("contact_id", "")).is_empty() and str(row.get("contact_id", "")) == str(contact.get("id", "")):
		return true
	var row_company_id: String = str(row.get("target_company_id", ""))
	if not row_company_id.is_empty() and row_company_id == _network_contact_target_company(contact):
		return true
	var row_ticker: String = str(row.get("target_ticker", ""))
	return not row_ticker.is_empty() and row_ticker == _ticker_for_company(_network_contact_target_company(contact))

func _network_journal_group_key(row_type: String) -> String:
	match row_type:
		"request", "dirty_tip":
			return "requests"
		"referral":
			return "referrals"
		"source_check":
			return "source_checks"
		_:
			return "tips"

func _network_journal_group_label(group_key: String) -> String:
	match group_key:
		"requests":
			return "Requests"
		"referrals":
			return "Referrals"
		"source_checks":
			return "Source Checks"
		_:
			return "Tips"

func _refresh_network_journal_filter_buttons() -> void:
	for filter_id_value in network_journal_filter_buttons.keys():
		var filter_id: String = str(filter_id_value)
		var button: Button = network_journal_filter_buttons.get(filter_id, null) as Button
		if button == null:
			continue
		var is_selected: bool = filter_id == selected_network_journal_filter
		button.disabled = is_selected
		_style_network_journal_filter_button(button, is_selected)

func _show_network_journal_detail(row: Dictionary) -> void:
	if network_journal_detail_label == null:
		return
	if row.is_empty():
		network_journal_detail_label.visible = false
		network_journal_detail_label.text = ""
		return
	var row_type: String = str(row.get("type", "tip"))
	var title_prefix: String = "Request" if row_type == "request" else "Market Room" if row_type == "dirty_tip" else "Journal"
	var lines: Array = [
		"%s: %s" % [title_prefix, str(row.get("title", "Network note"))],
		"Day %d  |  %s  |  %s" % [
			int(row.get("day_index", 0)),
			_network_journal_group_label(_network_journal_group_key(row_type)),
			str(row.get("status", "recorded")).capitalize()
		]
	]
	var contact_name: String = str(row.get("contact_name", ""))
	if not contact_name.is_empty():
		lines.append("Contact: %s" % contact_name)
	var ticker: String = str(row.get("target_ticker", ""))
	if not ticker.is_empty():
		lines.append("Ticker: %s" % ticker)
	var detail: String = str(row.get("detail", ""))
	if not detail.is_empty():
		lines.append("")
		lines.append(detail)
	network_journal_detail_label.text = "\n".join(lines)
	network_journal_detail_label.visible = true

func _network_request_detail_row(request: Dictionary) -> Dictionary:
	if str(request.get("request_type", "")) == "dirty_tip":
		var dirty_ticker: String = str(request.get("target_ticker", _ticker_for_company(str(request.get("target_company_id", "")))))
		var dirty_status: String = str(request.get("status", "offered"))
		var dirty_detail: String = str(request.get("offer_body", request.get("journal_detail", "")))
		if dirty_status in ["accepted", "resolved_clean", "caught", "expired", "reported", "declined"]:
			dirty_detail = str(request.get("outcome_note", request.get("journal_detail", dirty_detail)))
		if dirty_status == "accepted":
			dirty_detail = "Accepted. Active until day %d. %s" % [
				int(request.get("active_until_day_index", request.get("due_day_index", 0))),
				str(request.get("offer_body", ""))
			]
		return {
			"id": "%s:dirty_tip_detail" % str(request.get("id", "")),
			"type": "dirty_tip",
			"day_index": int(request.get("created_day_index", current_network_snapshot.get("day_index", 0))),
			"contact_id": str(request.get("contact_id", "")),
			"contact_name": str(request.get("contact_name", "Operator Room")),
			"target_company_id": str(request.get("target_company_id", "")),
			"target_ticker": dirty_ticker,
			"status": dirty_status,
			"title": "Dirty Tip | %s | %s" % [dirty_ticker, dirty_status.capitalize()],
			"detail": "%s | %s" % [str(request.get("contact_name", "Operator Room")), dirty_detail]
		}
	var target_company_id: String = str(request.get("target_company_id", ""))
	var ticker: String = _ticker_for_company(target_company_id)
	var status: String = str(request.get("status", "pending"))
	var contact_name: String = str(request.get("contact_name", "Contact"))
	if contact_name == "Contact":
		for contact_value in current_network_snapshot.get("contacts", []):
			if typeof(contact_value) != TYPE_DICTIONARY:
				continue
			var contact: Dictionary = contact_value
			if str(contact.get("id", "")) == str(request.get("contact_id", "")):
				contact_name = str(contact.get("display_name", "Contact"))
				break
	var detail: String = "%s. Hold at least 1 lot of %s by %s to complete this request." % [
		_network_request_due_label(request),
		ticker,
		_network_request_due_date_text(request)
	]
	if status == "completed":
		detail = "Completed after you held at least 1 lot of %s." % ticker
	elif status == "missed":
		detail = "Missed because you did not hold the requested target."
	return {
		"id": "%s:request_detail" % str(request.get("id", "")),
		"type": "request",
		"day_index": int(request.get("created_day_index", current_network_snapshot.get("day_index", 0))),
		"contact_id": str(request.get("contact_id", "")),
		"contact_name": contact_name,
		"target_company_id": target_company_id,
		"target_ticker": ticker,
		"status": status,
		"title": "Request | %s | %s" % [ticker, status.capitalize()],
		"detail": "%s | %s" % [contact_name, detail]
	}

func _show_network_contact(contact: Dictionary) -> void:
	if contact.is_empty():
		network_contact_name_label.text = "No leads yet."
		network_contact_meta_label.text = ""
		network_contact_body_label.text = "Explore the world more. Read News, follow referrals, and approach RUPSLB room leads to discover people before they appear here."
		if network_corporate_action_label != null:
			network_corporate_action_label.visible = false
			network_corporate_action_label.text = ""
		if network_open_meeting_button != null:
			network_open_meeting_button.visible = false
			network_open_meeting_button.disabled = true
			network_open_meeting_button.set_meta("meeting_id", "")
		if network_followup_button != null:
			network_followup_button.visible = false
			network_followup_button.disabled = true
		if network_source_check_button != null:
			network_source_check_button.visible = false
			network_source_check_button.disabled = true
		if network_tip_history_label != null:
			network_tip_history_label.visible = false
			network_tip_history_label.text = ""
		if network_crosscheck_label != null:
			network_crosscheck_label.visible = false
			network_crosscheck_label.text = ""
		network_meet_button.disabled = true
		network_tip_button.disabled = true
		network_request_button.disabled = true
		network_referral_button.disabled = true
		return

	var is_met: bool = bool(contact.get("met", false))
	var affiliation_type: String = str(contact.get("affiliation_type", "floater"))
	network_contact_name_label.text = "%s  |  %s" % [
		str(contact.get("display_name", "")),
		str(contact.get("role", ""))
	]
	var affiliation_label: String = "Floater"
	var affiliated_company_id: String = str(contact.get("affiliated_company_id", contact.get("company_id", "")))
	if affiliation_type == "insider":
		affiliation_label = "Insider at %s" % _ticker_for_company(affiliated_company_id)
	elif str(contact.get("source_type", "")) == "referral":
		affiliation_label = "Referred lead"
	var source_type_label: String = _network_source_type_label(str(contact.get("source_type", "network")))
	var network_meta_parts: Array = [
		affiliation_label,
		"Relationship %d" % int(contact.get("relationship", 0)),
		"Required recognition %d" % int(contact.get("recognition_required", 0)),
		"Discovered via %s" % source_type_label
	]
	var contact_twooter_handle: String = str(contact.get("twooter_handle", "")).strip_edges()
	if not contact_twooter_handle.is_empty():
		network_meta_parts.append("Twooter %s" % contact_twooter_handle)
	network_contact_meta_label.text = "  |  ".join(network_meta_parts)
	var contact_body_text: String = str(contact.get("intro", ""))
	var last_tip_note: String = str(contact.get("last_tip_note", ""))
	if not last_tip_note.is_empty():
		contact_body_text += "\n\n%s" % last_tip_note
	var reaction_note: String = str(contact.get("last_reaction_note", ""))
	if not reaction_note.is_empty():
		contact_body_text += "\n\nLatest DM: %s" % reaction_note
	var followup_note: String = str(contact.get("last_tip_followup_note", ""))
	if not followup_note.is_empty():
		contact_body_text += "\n%s" % followup_note
	network_contact_body_label.text = contact_body_text
	_update_network_tip_history_panel(contact)
	_update_network_crosscheck_panel(contact)
	var remaining_ap: int = int(GameManager.get_daily_action_snapshot().get("remaining", 0))
	var referral_company_id: String = selected_company_id
	if referral_company_id.is_empty():
		referral_company_id = _network_contact_target_company(contact)
	var tip_cooldown_active: bool = int(contact.get("last_tip_request_day_index", -9999)) == RunState.day_index
	var referral_cooldown_active: bool = int(contact.get("last_referral_day_index", -9999)) == RunState.day_index
	network_meet_button.text = "Meet (%d AP)" % GameManager.get_network_action_cost("meet")
	network_tip_button.text = "Ask Tip (%d AP)" % GameManager.get_network_action_cost("tip")
	network_request_button.text = "Accept Request (%d AP)" % GameManager.get_network_action_cost("request")
	network_referral_button.text = "Ask Referral (%d AP)" % GameManager.get_network_action_cost("referral")
	network_meet_button.disabled = is_met or not bool(contact.get("can_meet", false)) or remaining_ap < GameManager.get_network_action_cost("meet")
	network_tip_button.disabled = not is_met or tip_cooldown_active or remaining_ap < GameManager.get_network_action_cost("tip")
	network_tip_button.tooltip_text = "Already asked this contact for a read today." if tip_cooldown_active else "Ask for a fresh market read."
	network_request_button.disabled = not is_met or remaining_ap < GameManager.get_network_action_cost("request")
	network_referral_button.disabled = not (is_met and affiliation_type == "floater" and not referral_company_id.is_empty() and not referral_cooldown_active and remaining_ap >= GameManager.get_network_action_cost("referral"))
	network_referral_button.tooltip_text = "Already asked this contact for an introduction today." if referral_cooldown_active else "Ask this contact to introduce a connected insider."
	_update_network_followup_button(contact, is_met, remaining_ap)
	_update_network_source_check_button(contact, is_met, remaining_ap)
	if remaining_ap < GameManager.get_network_action_cost("meet") and not is_met:
		network_meet_button.disabled = true
	var company_snapshot: Dictionary = GameManager.get_company_corporate_action_snapshot(_network_contact_target_company(contact))
	var primary_chain: Dictionary = company_snapshot.get("primary_chain", {})
	var meeting_id: String = str(primary_chain.get("meeting_id", ""))
	if meeting_id.is_empty():
		var upcoming_meetings: Array = company_snapshot.get("upcoming_meetings", [])
		if not upcoming_meetings.is_empty():
			meeting_id = str(upcoming_meetings[0].get("id", ""))
	if network_corporate_action_label != null:
		var action_text: String = ""
		if not primary_chain.is_empty():
			action_text = str(primary_chain.get("public_summary", ""))
			var intel_summary: String = str(primary_chain.get("intel_summary", ""))
			if not intel_summary.is_empty():
				action_text += "\nIntel: %s" % intel_summary
		elif not company_snapshot.get("upcoming_meetings", []).is_empty():
			action_text = str(company_snapshot.get("upcoming_meetings", [])[0].get("public_summary", ""))
		network_corporate_action_label.text = action_text
		network_corporate_action_label.visible = not action_text.is_empty()
	if network_open_meeting_button != null:
		var meeting_detail: Dictionary = GameManager.get_corporate_meeting_detail(meeting_id) if not meeting_id.is_empty() else {}
		var meeting_blocked_reason: String = _corporate_meeting_open_blocked_reason(meeting_detail)
		network_open_meeting_button.visible = not meeting_id.is_empty()
		network_open_meeting_button.disabled = meeting_id.is_empty() or not meeting_blocked_reason.is_empty()
		network_open_meeting_button.text = "Shareholders Only" if not meeting_blocked_reason.is_empty() else "Open Meeting"
		network_open_meeting_button.tooltip_text = meeting_blocked_reason if not meeting_blocked_reason.is_empty() else "Open the linked corporate meeting."
		network_open_meeting_button.set_meta("meeting_id", meeting_id)

func _current_network_contact() -> Dictionary:
	if network_contacts_list.item_count <= 0:
		return {}
	var selected_items: PackedInt32Array = network_contacts_list.get_selected_items()
	if selected_items.is_empty():
		return {}
	var item_index: int = selected_items[0]
	var metadata: Variant = network_contacts_list.get_item_metadata(item_index)
	if typeof(metadata) == TYPE_DICTIONARY:
		var row: Dictionary = metadata
		return row
	return {}

func _network_source_type_label(source_type: String) -> String:
	match source_type.strip_edges().to_lower():
		"news":
			return "News lead"
		"twooter":
			return "Twooter lead"
		"referral":
			return "Referral"
		"meeting":
			return "Meeting room"
		"manual":
			return "Manual note"
		"debug":
			return "Test lead"
		_:
			return "Network lead"

func _update_network_followup_button(contact: Dictionary, is_met: bool, remaining_ap: int) -> void:
	if network_followup_button == null:
		return
	var options: Array = contact.get("tip_followup_options", [])
	var can_follow_up: bool = is_met and bool(contact.get("can_follow_up_tip", false)) and not options.is_empty()
	network_followup_button.visible = can_follow_up
	network_followup_button.text = "Follow Up (%d AP)" % GameManager.get_network_action_cost("followup")
	network_followup_button.disabled = not can_follow_up or remaining_ap < GameManager.get_network_action_cost("followup")
	var popup: PopupMenu = network_followup_button.get_popup()
	popup.clear()
	for option_value in options:
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		var followup_id: String = str(option.get("id", ""))
		var menu_id: int = _network_followup_menu_id(followup_id)
		if menu_id < 0:
			continue
		popup.add_item(str(option.get("label", followup_id.capitalize())), menu_id)
	network_followup_button.tooltip_text = "Follow up on the selected contact's latest resolved read."

func _update_network_source_check_button(contact: Dictionary, is_met: bool, remaining_ap: int) -> void:
	if network_source_check_button == null:
		return
	var has_direct_conflict: bool = bool(contact.get("has_direct_source_conflict", false))
	var can_ask: bool = is_met and bool(contact.get("can_ask_source_check", false))
	var has_answer: bool = not str(contact.get("source_check_note", "")).is_empty()
	network_source_check_button.visible = is_met and has_direct_conflict
	network_source_check_button.disabled = not can_ask or remaining_ap < GameManager.get_network_action_cost("source_check")
	if has_answer:
		network_source_check_button.text = "Conflict Asked"
		network_source_check_button.disabled = true
		network_source_check_button.tooltip_text = "This conflict already has a follow-up answer in the Source Cross-Check panel."
	elif remaining_ap < GameManager.get_network_action_cost("source_check"):
		network_source_check_button.text = "Ask About Conflict (%d AP)" % GameManager.get_network_action_cost("source_check")
		network_source_check_button.tooltip_text = "No daily action points left."
	else:
		network_source_check_button.text = "Ask About Conflict (%d AP)" % GameManager.get_network_action_cost("source_check")
		network_source_check_button.tooltip_text = "Spend 1 action point to ask this contact why another source disagrees."

func _network_followup_menu_id(followup_id: String) -> int:
	for menu_id_value in NETWORK_FOLLOWUP_ACTIONS.keys():
		var menu_id: int = int(menu_id_value)
		if str(NETWORK_FOLLOWUP_ACTIONS.get(menu_id, "")) == followup_id:
			return menu_id
	return -1

func _update_network_tip_history_panel(contact: Dictionary) -> void:
	if network_tip_history_label == null:
		return
	var history_text: String = _network_tip_history_text(contact)
	network_tip_history_label.text = history_text
	network_tip_history_label.visible = not history_text.is_empty()

func _network_tip_history_text(contact: Dictionary) -> String:
	var rows: Array = contact.get("tip_history", [])
	if rows.is_empty():
		return ""
	var useful_count: int = int(contact.get("tip_useful_count", 0))
	var resolved_count: int = int(contact.get("tip_resolved_count", rows.size()))
	var missed_count: int = int(contact.get("tip_missed_count", 0))
	var header: String = "Read History | %s | %d/%d useful" % [
		str(contact.get("tip_reliability_label", "Mixed record")),
		useful_count,
		resolved_count
	]
	if missed_count > 0:
		header += " | %d missed" % missed_count
	var lines: Array = [header]
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var line: String = "- %s: %s" % [
			str(row.get("target_ticker", "")),
			str(row.get("outcome_label", "Read"))
		]
		var player_action: String = str(row.get("player_action_label", ""))
		if not player_action.is_empty():
			line += " | %s" % player_action
		var followup_label: String = str(row.get("followup_label", ""))
		if not followup_label.is_empty():
			line += " | %s" % followup_label
		lines.append(line)
	return "\n".join(lines)

func _update_network_crosscheck_panel(contact: Dictionary) -> void:
	if network_crosscheck_label == null:
		return
	var crosscheck_text: String = _network_crosscheck_text(contact)
	network_crosscheck_label.text = crosscheck_text
	network_crosscheck_label.visible = not crosscheck_text.is_empty()

func _network_crosscheck_text(contact: Dictionary) -> String:
	var label: String = str(contact.get("cross_contact_label", ""))
	var note: String = str(contact.get("cross_contact_note", ""))
	if label.is_empty() or note.is_empty():
		return ""
	var lines: Array = ["Source Cross-Check | %s" % label, note]
	for row_value in contact.get("cross_contact_rows", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var source_role: String = str(row.get("source_role", ""))
		var contact_label: String = str(row.get("contact_name", "Another contact"))
		if not source_role.is_empty():
			contact_label += " (%s)" % source_role
		var line: String = "- %s: %s" % [
			contact_label,
			str(row.get("truth_label", "different read"))
		]
		var confidence_label: String = str(row.get("confidence_label", ""))
		if not confidence_label.is_empty():
			line += " | %s" % confidence_label
		lines.append(line)
	var source_check_note: String = str(contact.get("source_check_note", ""))
	if not source_check_note.is_empty():
		lines.append("Conflict Follow-up | %s" % source_check_note)
	return "\n".join(lines)

func _network_state_for_contact(network_snapshot: Dictionary, contact_id: String) -> String:
	for contact_value in network_snapshot.get("contacts", []):
		var contact: Dictionary = contact_value
		if str(contact.get("id", "")) == contact_id and bool(contact.get("met", false)):
			return "met"
	for discovery_value in network_snapshot.get("discoveries", []):
		var discovery: Dictionary = discovery_value
		if str(discovery.get("id", "")) == contact_id:
			return "discovered"
	return "public"

func _on_network_contact_selected(index: int) -> void:
	var metadata: Variant = network_contacts_list.get_item_metadata(index)
	if typeof(metadata) != TYPE_DICTIONARY:
		return
	var contact: Dictionary = metadata
	selected_network_contact_id = str(contact.get("id", ""))
	selected_network_journal_id = ""
	if network_journal_list != null:
		network_journal_list.deselect_all()
	_show_network_journal_detail({})
	_show_network_contact(contact)
	_rebuild_network_journal_list()

func _on_network_request_selected(index: int) -> void:
	var metadata: Variant = network_requests_list.get_item_metadata(index)
	if typeof(metadata) != TYPE_DICTIONARY:
		return
	var request: Dictionary = metadata
	selected_network_journal_id = ""
	if network_journal_list != null:
		network_journal_list.deselect_all()
	_show_network_journal_detail(_network_request_detail_row(request))

func _on_network_journal_selected(index: int) -> void:
	if network_journal_list == null:
		return
	var metadata: Variant = network_journal_list.get_item_metadata(index)
	if typeof(metadata) != TYPE_DICTIONARY:
		return
	var row: Dictionary = metadata
	selected_network_journal_id = str(row.get("id", ""))
	_show_network_journal_detail(row)

func _on_network_journal_filter_pressed(filter_id: String) -> void:
	selected_network_journal_filter = filter_id
	selected_network_journal_id = ""
	_refresh_network_journal_filter_buttons()
	_rebuild_network_journal_list()

func _on_network_meet_pressed() -> void:
	var contact: Dictionary = _current_network_contact()
	_meet_contact_from_context(str(contact.get("id", "")), {"source_type": "network"})

func _on_network_tip_pressed() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var contact: Dictionary = _current_network_contact()
	var company_id: String = _network_contact_target_company(contact)
	var result: Dictionary = GameManager.request_contact_tip(str(contact.get("id", "")), company_id)
	_show_toast(str(result.get("message", "Network tip updated.")), bool(result.get("success", false)))
	_log_perf_elapsed("_on_network_tip_pressed", started_at_usec)

func _on_network_request_pressed() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var contact: Dictionary = _current_network_contact()
	var company_id: String = _network_contact_target_company(contact)
	var result: Dictionary = GameManager.accept_contact_request(str(contact.get("id", "")), company_id)
	_show_toast(str(result.get("message", "Network request updated.")), bool(result.get("success", false)))
	_log_perf_elapsed("_on_network_request_pressed", started_at_usec)

func _on_network_referral_pressed() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var contact: Dictionary = _current_network_contact()
	var company_id: String = selected_company_id
	if company_id.is_empty():
		company_id = _network_contact_target_company(contact)
	var result: Dictionary = GameManager.request_contact_referral(str(contact.get("id", "")), company_id)
	_show_toast(str(result.get("message", "Network referral updated.")), bool(result.get("success", false)))
	_log_perf_elapsed("_on_network_referral_pressed", started_at_usec)

func _on_network_followup_selected(menu_id: int) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var followup_id: String = str(NETWORK_FOLLOWUP_ACTIONS.get(menu_id, ""))
	if followup_id.is_empty():
		return
	var contact: Dictionary = _current_network_contact()
	var result: Dictionary = GameManager.follow_up_contact_tip(str(contact.get("id", "")), followup_id)
	_show_toast(str(result.get("message", "Network follow-up updated.")), bool(result.get("success", false)))
	_log_perf_elapsed("_on_network_followup_selected", started_at_usec)

func _on_network_source_check_pressed() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var contact: Dictionary = _current_network_contact()
	var result: Dictionary = GameManager.ask_contact_source_check(str(contact.get("id", "")))
	_show_toast(str(result.get("message", "Source check updated.")), bool(result.get("success", false)))
	_log_perf_elapsed("_on_network_source_check_pressed", started_at_usec)

func _on_network_open_meeting_pressed() -> void:
	if network_open_meeting_button == null:
		return
	_open_corporate_meeting_modal(str(network_open_meeting_button.get_meta("meeting_id", "")))

func _network_contact_target_company(contact: Dictionary) -> String:
	var target_company_id: String = str(contact.get("target_company_id", ""))
	if not target_company_id.is_empty():
		return target_company_id
	var affiliated_company_id: String = str(contact.get("affiliated_company_id", contact.get("company_id", "")))
	if not affiliated_company_id.is_empty():
		return affiliated_company_id
	return selected_company_id

func _ensure_network_detail_scroll() -> void:
	if network_detail_scroll != null:
		return
	var detail_vbox: VBoxContainer = network_contact_body_label.get_parent()
	var action_row: HBoxContainer = network_meet_button.get_parent()
	if detail_vbox == null or action_row == null or action_row.get_parent() != detail_vbox:
		return

	network_detail_scroll = ScrollContainer.new()
	network_detail_scroll.name = "NetworkDetailScroll"
	network_detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	network_detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	network_detail_scroll.follow_focus = true
	detail_vbox.add_child(network_detail_scroll)
	detail_vbox.move_child(network_detail_scroll, 0)

	network_detail_scroll_content = VBoxContainer.new()
	network_detail_scroll_content.name = "NetworkDetailScrollContent"
	network_detail_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	network_detail_scroll_content.add_theme_constant_override("separation", 10)
	network_detail_scroll.add_child(network_detail_scroll_content)

	var children_to_move: Array = []
	for child_value in detail_vbox.get_children():
		var child: Node = child_value
		if child == network_detail_scroll or child == action_row:
			continue
		children_to_move.append(child)
	for child_value in children_to_move:
		var child: Node = child_value
		detail_vbox.remove_child(child)
		network_detail_scroll_content.add_child(child)


func _ticker_for_company(company_id: String) -> String:
	if _root == null:
		return company_id
	return str(_root.call("_ticker_for_company", company_id))


func _corporate_meeting_open_blocked_reason(detail: Dictionary) -> String:
	if _root == null:
		return ""
	return str(_root.call("_corporate_meeting_open_blocked_reason", detail))


func _meet_contact_from_context(contact_id: String, source_context: Dictionary) -> void:
	if _root != null:
		_root.call("_meet_contact_from_context", contact_id, source_context)


func _open_corporate_meeting_modal(meeting_id: String) -> void:
	if _root != null:
		_root.call("_open_corporate_meeting_modal", meeting_id)


func _show_toast(message: String, is_success: bool) -> void:
	if _root != null:
		_root.call("_show_toast", message, is_success)


func _log_perf_elapsed(label: String, started_at_usec: int) -> void:
	if _root != null:
		_root.call("_log_perf_elapsed", label, started_at_usec)


func _style_network_journal_filter_button(button: Button, is_selected: bool) -> void:
	if _root != null:
		_root.call("_style_network_journal_filter_button", button, is_selected)
