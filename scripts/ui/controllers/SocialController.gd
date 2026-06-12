extends RefCounted

const UI_THEME := preload("res://scripts/ui/UITheme.gd")

const APP_ID_SOCIAL := "social"
const DEFAULT_APP_FONT_SIZE := 14
const SOCIAL_CENTER_MARGIN_LEFT := 16
const SOCIAL_CENTER_MARGIN_TOP := 16
const SOCIAL_CENTER_MARGIN_RIGHT := 16
const SOCIAL_CENTER_MARGIN_BOTTOM := 12
const SOCIAL_SIDE_MARGIN_LEFT := 14
const SOCIAL_SIDE_MARGIN_TOP := 14
const SOCIAL_SIDE_MARGIN_RIGHT := 14
const SOCIAL_SIDE_MARGIN_BOTTOM := 14
const SOCIAL_FONT_SIZE_BUMP := 2
const SOCIAL_ACTION_BUTTON_MIN_HEIGHT := 38
const SOCIAL_ACTION_BUTTON_PAD_X := 16
const SOCIAL_ACTION_BUTTON_PAD_Y := 8
const SOCIAL_NAV_BUTTON_PAD_X := 16
const SOCIAL_NAV_BUTTON_PAD_Y := 9
const SOCIAL_FEED_FILTER_ALL := "all"
const SOCIAL_FEED_FILTER_FOLLOWING := "following"
const SOCIAL_FEED_FILTER_COMPANIES := "companies"
const SOCIAL_FEED_FILTER_SECTORS := "sectors"
const SOCIAL_FEED_FILTER_TRENDING := "trending"
const SOCIAL_FEED_FILTERS := [
	{"id": SOCIAL_FEED_FILTER_ALL, "label": "All"},
	{"id": SOCIAL_FEED_FILTER_COMPANIES, "label": "Companies"},
	{"id": SOCIAL_FEED_FILTER_SECTORS, "label": "Sectors"},
	{"id": SOCIAL_FEED_FILTER_TRENDING, "label": "Trending"}
]
const SOCIAL_TICKER_TAPE_LIMIT := 6
const COLOR_TWOOTER_PAGE := UI_THEME.COLOR_TWOOTER_PAGE
const COLOR_TWOOTER_SURFACE := UI_THEME.COLOR_TWOOTER_SURFACE
const COLOR_TWOOTER_CARD := UI_THEME.COLOR_TWOOTER_CARD
const COLOR_TWOOTER_BLUE := UI_THEME.COLOR_TWOOTER_BLUE
const COLOR_TWOOTER_BLUE_DARK := UI_THEME.COLOR_TWOOTER_BLUE_DARK
const COLOR_TWOOTER_BLUE_TINT := UI_THEME.COLOR_TWOOTER_BLUE_TINT
const COLOR_TWOOTER_BLUE_EDGE := UI_THEME.COLOR_TWOOTER_BLUE_EDGE
const COLOR_TWOOTER_TEXT := UI_THEME.COLOR_TWOOTER_TEXT
const COLOR_TWOOTER_MUTED := UI_THEME.COLOR_TWOOTER_MUTED
const COLOR_TWOOTER_FAINT := UI_THEME.COLOR_TWOOTER_FAINT
const COLOR_TWOOTER_BORDER := UI_THEME.COLOR_TWOOTER_BORDER
const COLOR_TWOOTER_LIVE := UI_THEME.COLOR_TWOOTER_LIVE

var _root = null
var social_capture_menu: PopupMenu = null
var pending_capture_payloads: Dictionary = {}
var current_social_snapshot: Dictionary = {}
var expanded_social_thread_ids: Dictionary = {}
var selected_social_account_id: String = ""
var selected_social_feed_filter_id: String = SOCIAL_FEED_FILTER_ALL
var selected_social_view_id: String = "home"
var selected_social_message_account_id: String = ""
var social_window: MarginContainer = null
var social_window_body: PanelContainer = null
var social_title_label: Label = null
var social_access_status_label: Label = null
var social_feed_summary_label: Label = null
var social_feed_scroll: ScrollContainer = null
var social_feed_cards: VBoxContainer = null
var social_live_dot: PanelContainer = null
var social_live_label: Label = null
var social_tier_indicator: HBoxContainer = null
var social_filter_scroll: ScrollContainer = null
var social_filter_chips: HBoxContainer = null
var social_ticker_tape_panel: PanelContainer = null
var social_ticker_tape_scroll: ScrollContainer = null
var social_ticker_tape: HBoxContainer = null
var social_app_shell: HBoxContainer = null
var social_left_sidebar: PanelContainer = null
var social_left_nav_buttons: Dictionary = {}
var social_center_panel: PanelContainer = null
var social_right_rail: VBoxContainer = null
var social_account_search_input: LineEdit = null
var social_account_search_results: VBoxContainer = null
var social_trending_rows: VBoxContainer = null
var social_follow_rows: VBoxContainer = null
var social_message_view: HBoxContainer = null
var social_message_thread_scroll: ScrollContainer = null
var social_message_threads: VBoxContainer = null
var social_message_detail: VBoxContainer = null
var social_message_header: VBoxContainer = null
var social_message_rows_scroll: ScrollContainer = null
var social_message_rows: VBoxContainer = null
var social_message_actions: VBoxContainer = null
var social_message_composer: PanelContainer = null
var social_message_composer_text_label: Label = null
var social_message_option_buttons: Array[Button] = []
var social_message_send_button: Button = null
var social_message_typing_tween: Tween = null
var pending_social_message_account_id: String = ""
var pending_social_message_action_id: String = ""
var pending_social_message_thesis_id: String = ""
var pending_social_message_text: String = ""
var social_reply_dialog: Control = null
var social_reply_context_label: Label = null
var social_reply_text_label: Label = null
var social_reply_option_buttons: Array[Button] = []
var social_reply_send_button: Button = null
var social_reply_cancel_button: Button = null
var social_reply_typing_tween: Tween = null
var pending_social_reply_post_id: String = ""
var pending_social_reply_action_id: String = ""
var pending_social_reply_text: String = ""
var news_meet_contact_button: Button = null


func setup(root) -> void:
	_root = root
	if _root != null:
		var capture_payloads = _root.get("pending_capture_payloads")
		if typeof(capture_payloads) == TYPE_DICTIONARY:
			pending_capture_payloads = capture_payloads
	_sync_dynamic_refs_from_root()
	_sync_state_from_root()
	_sync_root_refs()


func refresh() -> void:
	_sync_dynamic_refs_from_root()
	_sync_state_from_root()
	_refresh_social()


func ensure_ui() -> void:
	_sync_dynamic_refs_from_root()
	_ensure_social_feed_ui()


func open_account_from_news(account_id: String, contact_id: String = "") -> void:
	_sync_dynamic_refs_from_root()
	_sync_state_from_root()
	_open_social_account_from_news(account_id, contact_id)
	_sync_root_refs()


func _refresh_social() -> void:
	_sync_dynamic_refs_from_root()
	_ensure_social_feed_ui()
	current_social_snapshot = {}
	social_title_label.text = "Home" if selected_social_view_id == "home" else "Message"
	if not RunState.has_active_run():
		selected_social_account_id = ""
		selected_social_feed_filter_id = SOCIAL_FEED_FILTER_ALL
		social_access_status_label.text = "No run loaded"
		social_feed_summary_label.text = "Start a run to populate the feed."
		_refresh_social_tier_indicator(0)
		_rebuild_social_filter_chips([])
		_rebuild_social_ticker_tape([], [])
		_rebuild_social_feed_cards([])
		_rebuild_social_right_rail({})
		_rebuild_social_message_view({})
		_apply_social_view_visibility()
		_apply_font_overrides_to_subtree(social_feed_cards)
		_sync_root_refs()
		return

	current_social_snapshot = GameManager.get_twooter_snapshot()
	var all_posts: Array = current_social_snapshot.get("posts", [])
	var selected_account_name: String = _selected_social_account_name(all_posts)
	if not selected_social_account_id.is_empty() and selected_account_name.is_empty():
		selected_social_account_id = ""
	var account_posts: Array = _filtered_social_posts(all_posts)
	if selected_social_feed_filter_id.is_empty():
		selected_social_feed_filter_id = SOCIAL_FEED_FILTER_ALL
	var available_social_filter_ids: Dictionary = {}
	for filter_value in _social_feed_filters_for_posts(account_posts):
		if typeof(filter_value) == TYPE_DICTIONARY:
			available_social_filter_ids[str(filter_value.get("id", ""))] = true
	if not available_social_filter_ids.has(selected_social_feed_filter_id):
		selected_social_feed_filter_id = SOCIAL_FEED_FILTER_ALL
	var posts: Array = _filtered_social_posts_by_feed_filter(account_posts)
	social_title_label.text = "Home" if selected_social_view_id == "home" else "Message"
	social_access_status_label.text = "Live | Public chatter"
	var filter_label: String = _social_feed_filter_label(selected_social_feed_filter_id)
	if selected_social_account_id.is_empty():
		social_feed_summary_label.text = "%d of %d posts | %s | Public feed" % [posts.size(), all_posts.size(), filter_label]
	else:
		social_title_label.text = "%s" % selected_account_name if selected_social_view_id == "home" else "Message"
		social_feed_summary_label.text = "%d of %d posts | %s | %s" % [posts.size(), account_posts.size(), selected_account_name, filter_label]
	_refresh_social_tier_indicator(int(current_social_snapshot.get("access_tier", current_social_snapshot.get("tier", 1))))
	_rebuild_social_filter_chips(account_posts)
	_rebuild_social_ticker_tape(posts, all_posts)
	_rebuild_social_feed_cards(posts)
	_rebuild_social_right_rail(current_social_snapshot)
	_rebuild_social_message_view(current_social_snapshot)
	_apply_social_view_visibility()
	_apply_font_overrides_to_subtree(social_feed_cards)

func _filtered_social_posts(posts: Array) -> Array:
	if selected_social_account_id.is_empty():
		return posts
	var filtered_posts: Array = []
	for post_value in posts:
		if typeof(post_value) != TYPE_DICTIONARY:
			continue
		var post: Dictionary = post_value
		if str(post.get("account_id", "")) == selected_social_account_id:
			filtered_posts.append(post)
	return filtered_posts


func _filtered_social_posts_by_feed_filter(posts: Array) -> Array:
	if selected_social_feed_filter_id == SOCIAL_FEED_FILTER_ALL:
		return posts

	var filtered_posts: Array = []
	for post_value in posts:
		if typeof(post_value) != TYPE_DICTIONARY:
			continue
		var post: Dictionary = post_value
		if _social_post_matches_feed_filter(post, selected_social_feed_filter_id):
			filtered_posts.append(post)

	if selected_social_feed_filter_id == SOCIAL_FEED_FILTER_TRENDING and filtered_posts.is_empty() and not posts.is_empty():
		var sorted_posts: Array = posts.duplicate()
		sorted_posts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return _social_post_engagement_score(a) > _social_post_engagement_score(b)
		)
		return sorted_posts.slice(0, min(3, sorted_posts.size()))

	return filtered_posts


func _social_post_matches_feed_filter(post: Dictionary, filter_id: String) -> bool:
	if filter_id == SOCIAL_FEED_FILTER_FOLLOWING:
		return _following_social_account_lookup().has(str(post.get("account_id", "")))
	if filter_id == SOCIAL_FEED_FILTER_COMPANIES:
		return _social_post_is_company(post)
	if filter_id == SOCIAL_FEED_FILTER_SECTORS:
		return _social_post_is_sector(post)
	if filter_id == SOCIAL_FEED_FILTER_TRENDING:
		return float(post.get("priority", 0.0)) >= 2.4 or _social_post_engagement_score(post) >= 500
	return true


func _social_feed_filters_for_posts(_posts: Array) -> Array:
	var filters: Array = [{"id": SOCIAL_FEED_FILTER_ALL, "label": "All"}]
	if not _following_social_account_lookup().is_empty():
		filters.append({"id": SOCIAL_FEED_FILTER_FOLLOWING, "label": "Following"})
	for filter_value in SOCIAL_FEED_FILTERS:
		if typeof(filter_value) != TYPE_DICTIONARY:
			continue
		var filter: Dictionary = filter_value
		var filter_id: String = str(filter.get("id", ""))
		if filter_id == SOCIAL_FEED_FILTER_ALL:
			continue
		filters.append(filter.duplicate(true))
	return filters


func _following_social_account_lookup() -> Dictionary:
	var lookup: Dictionary = {}
	for account_value in current_social_snapshot.get("accounts", []):
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value
		var account_id: String = str(account.get("id", ""))
		if not account_id.is_empty() and bool(account.get("following", false)):
			lookup[account_id] = true
	return lookup


func _social_account_from_snapshot(account_id: String) -> Dictionary:
	if account_id.is_empty():
		return {}
	for account_value in current_social_snapshot.get("accounts", []):
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value
		if str(account.get("id", "")) == account_id:
			return account
	return {}


func _social_post_is_company(post: Dictionary) -> bool:
	return not str(post.get("target_ticker", "")).strip_edges().is_empty() or not str(post.get("target_company_name", "")).strip_edges().is_empty()


func _social_post_is_sector(post: Dictionary) -> bool:
	var category: String = str(post.get("category", "")).to_lower()
	var has_sector: bool = not str(post.get("sector_name", "")).strip_edges().is_empty()
	return (has_sector and not _social_post_is_company(post)) or category.contains("sector")


func _social_post_engagement_score(post: Dictionary) -> int:
	return int(post.get("likes", 0)) + int(post.get("retwoots", 0)) * 3 + int(post.get("replies", 0)) * 2


func _social_feed_filter_label(filter_id: String) -> String:
	if filter_id == SOCIAL_FEED_FILTER_FOLLOWING:
		return "Following"
	for filter_value in SOCIAL_FEED_FILTERS:
		var filter: Dictionary = filter_value
		if str(filter.get("id", "")) == filter_id:
			return str(filter.get("label", "All"))
	return "All"


func _count_social_posts_for_filter(posts: Array, filter_id: String) -> int:
	if filter_id == SOCIAL_FEED_FILTER_ALL:
		return posts.size()
	var count: int = 0
	for post_value in posts:
		if typeof(post_value) != TYPE_DICTIONARY:
			continue
		var post: Dictionary = post_value
		if _social_post_matches_feed_filter(post, filter_id):
			count += 1
	return count


func _selected_social_account_name(posts: Array) -> String:
	if selected_social_account_id.is_empty():
		return ""
	var account: Dictionary = _social_account_from_snapshot(selected_social_account_id)
	if not account.is_empty():
		var display_name: String = str(account.get("display_name", "")).strip_edges()
		if not display_name.is_empty():
			return display_name
		var handle: String = str(account.get("handle", "")).strip_edges()
		if not handle.is_empty():
			return handle
	for post_value in posts:
		if typeof(post_value) != TYPE_DICTIONARY:
			continue
		var post: Dictionary = post_value
		if str(post.get("account_id", "")) != selected_social_account_id:
			continue
		var account_name: String = str(post.get("account_name", "")).strip_edges()
		if account_name.is_empty():
			account_name = str(post.get("account_handle", "")).strip_edges()
		return account_name
	return ""


func _refresh_social_tier_indicator(_access_tier: int) -> void:
	if social_tier_indicator == null:
		return
	for child in social_tier_indicator.get_children():
		social_tier_indicator.remove_child(child)
		child.queue_free()
	social_tier_indicator.visible = false


func _on_social_nav_pressed(view_id: String) -> void:
	if view_id.is_empty() or selected_social_view_id == view_id:
		return
	selected_social_view_id = view_id
	if view_id == "message" and _should_clear_social_message_selection_on_nav():
		selected_social_message_account_id = ""
	_refresh_social()


func _should_clear_social_message_selection_on_nav() -> bool:
	if selected_social_message_account_id.is_empty():
		return false
	var social_state: Dictionary = RunState.get_twooter_social_state()
	var messages: Dictionary = social_state.get("messages", {}) if typeof(social_state.get("messages", {})) == TYPE_DICTIONARY else {}
	var thread: Dictionary = messages.get(selected_social_message_account_id, {}) if typeof(messages.get(selected_social_message_account_id, {})) == TYPE_DICTIONARY else {}
	var rows: Array = thread.get("rows", []) if typeof(thread.get("rows", [])) == TYPE_ARRAY else []
	if not rows.is_empty():
		return false
	var dialog_state: Dictionary = social_state.get("dialog_state", {}) if typeof(social_state.get("dialog_state", {})) == TYPE_DICTIONARY else {}
	var accounts: Dictionary = dialog_state.get("accounts", {}) if typeof(dialog_state.get("accounts", {})) == TYPE_DICTIONARY else {}
	var branch: Dictionary = accounts.get(selected_social_message_account_id, {}) if typeof(accounts.get(selected_social_message_account_id, {})) == TYPE_DICTIONARY else {}
	return int(branch.get("cooldown_until_day", -9999)) < RunState.day_index


func _apply_social_view_visibility() -> void:
	var is_message: bool = selected_social_view_id == "message"
	if social_filter_scroll != null:
		social_filter_scroll.visible = not is_message
	if social_ticker_tape_panel != null:
		social_ticker_tape_panel.visible = not is_message
	if social_feed_scroll != null:
		social_feed_scroll.visible = not is_message
	if social_message_view != null:
		social_message_view.visible = is_message
	if social_feed_summary_label != null:
		social_feed_summary_label.visible = not is_message
	for view_id_value in social_left_nav_buttons.keys():
		var view_id: String = str(view_id_value)
		var button: Button = social_left_nav_buttons.get(view_id) as Button
		if button != null:
			_style_social_nav_button(button, view_id == selected_social_view_id)
	if social_right_rail != null:
		social_right_rail.visible = false if is_message else get_viewport_rect().size.x >= 960.0


func _rebuild_social_right_rail(snapshot: Dictionary) -> void:
	_rebuild_social_account_search_results(snapshot)
	_clear_container(social_trending_rows)
	_clear_container(social_follow_rows)
	if social_trending_rows != null:
		var trending_rows: Array = snapshot.get("trending_rows", [])
		if trending_rows.is_empty():
			social_trending_rows.add_child(_make_social_rail_body_label("No trend rows yet."))
		for row_value in trending_rows:
			if typeof(row_value) == TYPE_DICTIONARY:
				social_trending_rows.add_child(_build_social_trending_row(row_value))
	if social_follow_rows != null:
		var follow_rows: Array = snapshot.get("who_to_follow", [])
		if follow_rows.is_empty():
			social_follow_rows.add_child(_make_social_rail_body_label("No follow suggestions."))
		for row_value in follow_rows:
			if typeof(row_value) == TYPE_DICTIONARY:
				social_follow_rows.add_child(_build_social_follow_row(row_value))


func _rebuild_social_account_search_results(snapshot: Dictionary) -> void:
	_clear_container(social_account_search_results)
	if social_account_search_input == null or social_account_search_results == null:
		return
	var query: String = social_account_search_input.text.strip_edges().to_lower()
	if query.is_empty():
		social_account_search_results.visible = false
		return
	social_account_search_results.visible = true
	var match_count: int = 0
	for account_value in snapshot.get("accounts", []):
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value
		if not _social_account_matches_name_search(account, query):
			continue
		social_account_search_results.add_child(_build_social_account_search_result(account))
		match_count += 1
		if match_count >= 5:
			break
	if match_count <= 0:
		var empty_label: Label = _make_social_rail_body_label("No account names match.")
		empty_label.name = "SocialAccountSearchEmptyLabel"
		social_account_search_results.add_child(empty_label)


func _social_account_matches_name_search(account: Dictionary, query: String) -> bool:
	if query.is_empty():
		return false
	var display_name: String = str(account.get("display_name", "")).strip_edges().to_lower()
	return not display_name.is_empty() and display_name.find(query) != -1


func _social_font_size(base_size: int) -> int:
	return base_size + SOCIAL_FONT_SIZE_BUMP


func _build_social_account_search_result(account: Dictionary) -> Button:
	var account_id: String = str(account.get("id", ""))
	var button := Button.new()
	button.name = "SocialAccountSearchResultButton"
	button.set_meta("social_account_id", account_id)
	button.text = "%s\n%s" % [
		str(account.get("display_name", "Account")),
		str(account.get("handle", ""))
	]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = "Open this account profile."
	_style_social_thread_button(button)
	button.pressed.connect(_on_social_account_pressed.bind(account_id))
	return button


func _on_social_account_search_changed(_new_text: String) -> void:
	_rebuild_social_account_search_results(current_social_snapshot)


func _on_social_account_search_submitted(_new_text: String) -> void:
	var query: String = social_account_search_input.text.strip_edges().to_lower() if social_account_search_input != null else ""
	if query.is_empty():
		return
	for account_value in current_social_snapshot.get("accounts", []):
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value
		if _social_account_matches_name_search(account, query):
			_on_social_account_pressed(str(account.get("id", "")))
			return


func _build_social_trending_row(row: Dictionary) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.name = "SocialTrendingRow"
	vbox.add_theme_constant_override("separation", 3)
	var category := Label.new()
	category.text = str(row.get("category", "Market"))
	category.add_theme_color_override("font_color", COLOR_TWOOTER_MUTED)
	_apply_font_override_to_control(category, _social_font_size(12), _get_app_font())
	vbox.add_child(category)
	var tag := Label.new()
	tag.text = str(row.get("tag", "#IDX"))
	tag.add_theme_color_override("font_color", COLOR_TWOOTER_TEXT)
	_apply_font_override_to_control(tag, _social_font_size(DEFAULT_APP_FONT_SIZE + 1), _get_dashboard_title_font())
	vbox.add_child(tag)
	var count := Label.new()
	count.text = "%d posts" % int(row.get("posts", 0))
	count.add_theme_color_override("font_color", COLOR_TWOOTER_MUTED)
	_apply_font_override_to_control(count, _social_font_size(12), _get_app_font())
	vbox.add_child(count)
	return vbox


func _build_social_follow_row(row: Dictionary) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.name = "SocialFollowRow"
	var account_id: String = str(row.get("account_id", ""))
	hbox.set_meta("social_account_id", account_id)
	hbox.add_theme_constant_override("separation", 10)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.mouse_filter = Control.MOUSE_FILTER_STOP
	hbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hbox.gui_input.connect(_on_social_follow_row_gui_input.bind(account_id))
	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(36, 36)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_twooter_panel(avatar, _social_avatar_color(account_id), COLOR_TWOOTER_BORDER, 18, 1)
	var avatar_label := Label.new()
	avatar_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_label.text = str(row.get("display_name", "?")).left(1).to_upper()
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_label.add_theme_color_override("font_color", COLOR_TWOOTER_TEXT)
	avatar.add_child(avatar_label)
	hbox.add_child(avatar)
	var account_button := Button.new()
	account_button.name = "SocialFollowAccountButton"
	account_button.set_meta("social_account_id", account_id)
	account_button.text = "%s\n%s" % [str(row.get("display_name", "Account")), str(row.get("handle", ""))]
	account_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	account_button.clip_text = true
	account_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	account_button.custom_minimum_size = Vector2(0, 42)
	account_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	account_button.tooltip_text = "Open this account profile."
	_style_social_thread_button(account_button)
	account_button.pressed.connect(_on_social_account_pressed.bind(account_id))
	hbox.add_child(account_button)
	var button := Button.new()
	button.name = "SocialFollowButton"
	button.text = "Follow"
	button.custom_minimum_size = Vector2(92, SOCIAL_ACTION_BUTTON_MIN_HEIGHT)
	_style_social_follow_cta_button(button)
	button.pressed.connect(_on_social_follow_pressed.bind(account_id))
	hbox.add_child(button)
	return hbox


func _on_social_follow_row_gui_input(event: InputEvent, account_id: String) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	_on_social_account_pressed(account_id)


func _on_social_follow_pressed(account_id: String) -> void:
	var result: Dictionary = GameManager.follow_twooter_account(account_id)
	if not bool(result.get("success", false)):
		_show_toast(str(result.get("message", "Could not follow account.")), false)
		return
	_show_toast(str(result.get("message", "Following account.")), true)
	_refresh_social()


func _rebuild_social_message_view(snapshot: Dictionary) -> void:
	_clear_container(social_message_threads)
	_clear_container(social_message_header)
	_clear_container(social_message_rows)
	if social_message_threads == null or social_message_header == null or social_message_rows == null or social_message_actions == null:
		return
	_reset_social_message_composer(false)
	var thread_rows: Array = snapshot.get("message_threads", [])
	var account_lookup: Dictionary = {}
	for account_value in snapshot.get("accounts", []):
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value
		var account_id: String = str(account.get("id", ""))
		if not account_id.is_empty():
			account_lookup[account_id] = account
	var listed_accounts: Dictionary = {}
	var first_thread_account_id := ""
	for row_value in thread_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var row_account_id: String = str(row.get("account_id", ""))
		if row_account_id.is_empty():
			continue
		if first_thread_account_id.is_empty():
			first_thread_account_id = row_account_id
		listed_accounts[row_account_id] = true
		social_message_threads.add_child(_build_social_message_thread_button(row))
	if selected_social_message_account_id.is_empty():
		selected_social_message_account_id = first_thread_account_id
	elif not account_lookup.has(selected_social_message_account_id) and not listed_accounts.has(selected_social_message_account_id):
		selected_social_message_account_id = ""
	for child in social_message_threads.get_children():
		var thread_button := child as Button
		if thread_button != null:
			_style_social_filter_button(thread_button, str(thread_button.get_meta("account_id", "")) == selected_social_message_account_id, true)
	var selected_account: Dictionary = account_lookup.get(selected_social_message_account_id, {})
	if not selected_social_message_account_id.is_empty() and not listed_accounts.has(selected_social_message_account_id) and not selected_account.is_empty():
		social_message_threads.add_child(_build_social_message_thread_button({
			"account_id": selected_social_message_account_id,
			"account_name": str(selected_account.get("display_name", "")),
			"account_handle": str(selected_account.get("handle", "")),
			"relationship_stage": str(selected_account.get("relationship_stage", "stranger")),
			"last_text": "Start a message."
		}))
	if social_message_threads.get_child_count() == 0:
		social_message_threads.add_child(_make_social_rail_body_label("No messages yet.\nOpen an account from Home to start one."))
	if selected_social_message_account_id.is_empty():
		_add_social_message_header("Messages", "Your inbox is quiet.")
		social_message_rows.add_child(_make_social_rail_body_label("Your inbox is quiet. Open a Twooter account and press Send message to start a thread."))
		return
	var thread: Dictionary = GameManager.get_twooter_message_thread(selected_social_message_account_id)
	var account_for_thread: Dictionary = thread.get("account", {})
	if account_for_thread.is_empty() and not selected_account.is_empty():
		account_for_thread = selected_account
	var header_meta: String = "%s relationship | %d credibility | %d importance" % [
		str(account_for_thread.get("relationship_stage", "stranger")).replace("_", " ").capitalize(),
		int(account_for_thread.get("credibility", 0)),
		int(account_for_thread.get("importance", 0))
	]
	_add_social_message_header(str(account_for_thread.get("display_name", "Choose a thread")), header_meta)
	for row_value in thread.get("rows", []):
		if typeof(row_value) == TYPE_DICTIONARY:
			social_message_rows.add_child(_build_social_message_bubble(row_value))
	var message_cooldown_reason: String = str(thread.get("cooldown_reason", ""))
	if not message_cooldown_reason.is_empty():
		social_message_rows.add_child(_make_social_rail_body_label(_social_dialog_cooldown_text(message_cooldown_reason)))
	if int(social_message_rows.get_child_count()) <= 0:
		social_message_rows.add_child(_make_social_rail_body_label("Start with a clean message or share a thesis."))
	_hydrate_social_message_composer(selected_social_message_account_id, thread.get("dialog_options", []))
	if social_message_rows_scroll != null:
		call_deferred("_scroll_social_message_rows_to_bottom")


func _add_social_message_header(title_text: String, subtitle_text: String) -> void:
	if social_message_header == null:
		return
	var title := Label.new()
	title.name = "SocialMessageTitleLabel"
	title.text = title_text
	title.add_theme_color_override("font_color", COLOR_TWOOTER_TEXT)
	_apply_font_override_to_control(title, _social_font_size(DEFAULT_APP_FONT_SIZE + 5), _get_dashboard_title_font())
	social_message_header.add_child(title)
	if not subtitle_text.is_empty():
		var subtitle := Label.new()
		subtitle.name = "SocialMessageSubtitleLabel"
		subtitle.text = subtitle_text
		subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		subtitle.add_theme_color_override("font_color", COLOR_TWOOTER_MUTED)
		_apply_font_override_to_control(subtitle, _social_font_size(12), _get_app_font())
		social_message_header.add_child(subtitle)


func _hydrate_social_message_composer(account_id: String, options: Array) -> void:
	_reset_social_message_composer(true)
	pending_social_message_account_id = account_id
	if social_message_composer == null:
		return
	social_message_composer.visible = true
	for option_index in range(social_message_option_buttons.size()):
		var button: Button = social_message_option_buttons[option_index]
		var option: Dictionary = options[option_index] if option_index < options.size() and typeof(options[option_index]) == TYPE_DICTIONARY else {}
		button.visible = not option.is_empty()
		button.disabled = option.is_empty() or not bool(option.get("enabled", true))
		button.clip_text = true
		button.text = str(option.get("player_text", option.get("label", "Message")))
		button.tooltip_text = str(option.get("player_text", "")) if not bool(option.get("enabled", true)) else ""
		button.set_meta("action_id", str(option.get("id", "")))
		button.set_meta("tree_id", str(option.get("tree_id", "")))
		button.set_meta("node_id", str(option.get("node_id", "")))
		button.set_meta("option_id", str(option.get("option_id", "")))
		button.set_meta("thesis_id", str(option.get("thesis_id", "")))
		button.set_meta("player_text", str(option.get("player_text", "")))
		button.set_meta("blocked_reason", str(option.get("blocked_reason", "")))
	if options.is_empty() and social_message_composer_text_label != null:
		social_message_composer_text_label.text = "No clean message options are available right now."


func _reset_social_message_composer(show_composer: bool) -> void:
	if social_message_typing_tween != null:
		social_message_typing_tween.kill()
		social_message_typing_tween = null
	pending_social_message_account_id = ""
	pending_social_message_action_id = ""
	pending_social_message_thesis_id = ""
	pending_social_message_text = ""
	if social_message_composer != null:
		social_message_composer.visible = show_composer
	if social_message_composer_text_label != null:
		social_message_composer_text_label.text = "Choose a message below."
		social_message_composer_text_label.visible_characters = social_message_composer_text_label.text.length()
	for option_button in social_message_option_buttons:
		option_button.visible = show_composer
		option_button.disabled = true
		option_button.text = ""
		option_button.tooltip_text = ""
		if option_button.has_meta("action_id"):
			option_button.remove_meta("action_id")
		if option_button.has_meta("tree_id"):
			option_button.remove_meta("tree_id")
		if option_button.has_meta("node_id"):
			option_button.remove_meta("node_id")
		if option_button.has_meta("option_id"):
			option_button.remove_meta("option_id")
		if option_button.has_meta("thesis_id"):
			option_button.remove_meta("thesis_id")
		if option_button.has_meta("player_text"):
			option_button.remove_meta("player_text")
		if option_button.has_meta("blocked_reason"):
			option_button.remove_meta("blocked_reason")
		_style_social_thread_button(option_button)
	if social_message_send_button != null:
		social_message_send_button.disabled = true


func _on_social_message_option_selected(option_index: int) -> void:
	if option_index < 0 or option_index >= social_message_option_buttons.size():
		return
	var button: Button = social_message_option_buttons[option_index]
	pending_social_message_action_id = str(button.get_meta("action_id", ""))
	pending_social_message_thesis_id = str(button.get_meta("thesis_id", ""))
	pending_social_message_text = str(button.get_meta("player_text", ""))
	if pending_social_message_account_id.is_empty():
		pending_social_message_account_id = selected_social_message_account_id
	if pending_social_message_action_id.is_empty() or pending_social_message_text.is_empty():
		return
	for option_button in social_message_option_buttons:
		_style_social_thread_button(option_button)
	_style_social_filter_button(button, true, true)
	_start_social_message_typewriter(pending_social_message_text)


func _start_social_message_typewriter(text: String) -> void:
	if social_message_typing_tween != null:
		social_message_typing_tween.kill()
		social_message_typing_tween = null
	if social_message_send_button != null:
		social_message_send_button.disabled = true
	if social_message_composer_text_label == null:
		return
	social_message_composer_text_label.text = text
	social_message_composer_text_label.visible_characters = 0
	var duration: float = clamp(float(text.length()) * 0.018, 0.28, 1.2)
	if _is_smoke_test_runtime():
		duration = 0.02
	social_message_typing_tween = create_tween()
	social_message_typing_tween.tween_property(social_message_composer_text_label, "visible_characters", text.length(), duration)
	social_message_typing_tween.finished.connect(func() -> void:
		if social_message_composer_text_label != null:
			social_message_composer_text_label.visible_characters = social_message_composer_text_label.text.length()
		if social_message_send_button != null:
			social_message_send_button.disabled = pending_social_message_action_id.is_empty()
		social_message_typing_tween = null
	)


func _is_smoke_test_runtime() -> bool:
	for arg_value in OS.get_cmdline_user_args():
		var arg: String = str(arg_value)
		if arg.begins_with("--smoke"):
			return true
	return false


func _send_social_message_composer() -> void:
	if pending_social_message_account_id.is_empty() or pending_social_message_action_id.is_empty():
		return
	if social_message_typing_tween != null:
		social_message_typing_tween.kill()
		social_message_typing_tween = null
		if social_message_composer_text_label != null:
			social_message_composer_text_label.visible_characters = social_message_composer_text_label.text.length()
	var account_id: String = pending_social_message_account_id
	var action_id: String = pending_social_message_action_id
	var thesis_id: String = pending_social_message_thesis_id
	var player_text: String = pending_social_message_text
	_reset_social_message_composer(true)
	_on_social_message_action_pressed(account_id, action_id, thesis_id, player_text)


func _scroll_social_message_rows_to_bottom() -> void:
	if social_message_rows_scroll == null:
		return
	var scrollbar := social_message_rows_scroll.get_v_scroll_bar()
	if scrollbar != null:
		scrollbar.value = scrollbar.max_value


func _build_social_message_thread_button(row: Dictionary) -> Button:
	var button := Button.new()
	button.name = "SocialMessageThreadButton"
	button.set_meta("account_id", str(row.get("account_id", "")))
	button.text = "%s\n%s" % [str(row.get("account_name", "Account")), str(row.get("last_text", ""))]
	button.custom_minimum_size = Vector2(0, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_social_filter_button(button, str(row.get("account_id", "")) == selected_social_message_account_id, true)
	button.pressed.connect(_on_social_message_thread_pressed.bind(str(row.get("account_id", ""))))
	return button


func _on_social_message_thread_pressed(account_id: String) -> void:
	selected_social_message_account_id = account_id
	_refresh_social()


func _build_social_message_bubble(row: Dictionary) -> PanelContainer:
	var bubble := PanelContainer.new()
	bubble.name = "SocialMessageBubble"
	var is_player: bool = str(row.get("sender", "")) == "player"
	_style_twooter_panel(bubble, COLOR_TWOOTER_BLUE if is_player else COLOR_TWOOTER_SURFACE, COLOR_TWOOTER_BORDER, 10, 1)
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	bubble.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	bubble.tooltip_text = "Click to add this DM to the Research Tray."
	bubble.gui_input.connect(_on_social_dm_capture_gui_input.bind(row.duplicate(true), selected_social_message_account_id))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 7)
	bubble.add_child(margin)
	var label := Label.new()
	label.name = "SocialMessagePlayerTextLabel" if is_player else "SocialMessageAccountTextLabel"
	var body_text: String = str(row.get("text", ""))
	label.text = body_text if is_player else _clean_social_account_reply_text(body_text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", COLOR_TWOOTER_PAGE if is_player else COLOR_TWOOTER_TEXT)
	_apply_font_override_to_control(label, _social_font_size(13), _get_app_font())
	margin.add_child(label)
	return bubble


func _build_social_message_action_button(account_id: String, action_id: String, label: String, thesis_id: String) -> Button:
	var button := Button.new()
	button.name = "SocialMessageAction%sButton" % action_id.capitalize()
	button.text = "%s | 1 AP" % label
	button.custom_minimum_size = Vector2(0, 34)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_social_filter_button(button, true, true)
	button.pressed.connect(_on_social_message_action_pressed.bind(account_id, action_id, thesis_id))
	return button


func _on_social_message_action_pressed(account_id: String, action_id: String, thesis_id: String = "", player_message_text: String = "") -> void:
	var result: Dictionary = GameManager.send_twooter_message(account_id, action_id, thesis_id, player_message_text)
	if not bool(result.get("success", false)):
		_show_toast(str(result.get("message", "Twooter action failed.")), false)
		return
	_show_toast(str(result.get("reply_text", result.get("message", "Message sent."))), true)
	_refresh_social()
	_refresh_network()


func _on_social_post_capture_gui_input(event: InputEvent, post: Dictionary) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or not [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT].has(mouse_event.button_index):
		return
	var payload: Dictionary = _social_post_capture_payload(post)
	if payload.is_empty():
		_show_toast("This Twooter post is not ready to capture.", false)
		return
	pending_capture_payloads["social"] = payload
	_show_social_capture_menu(mouse_event.global_position)


func _on_social_dm_capture_gui_input(event: InputEvent, row: Dictionary, account_id: String) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or not [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT].has(mouse_event.button_index):
		return
	var payload: Dictionary = _social_dm_capture_payload(row, account_id)
	if payload.is_empty():
		_show_toast("This Twooter DM is not ready to capture.", false)
		return
	pending_capture_payloads["social"] = payload
	_show_social_capture_menu(mouse_event.global_position)


func _social_post_capture_payload(post: Dictionary) -> Dictionary:
	var body_text: String = str(post.get("post_text", "")).strip_edges()
	if body_text.is_empty():
		return {}
	var account_name: String = str(post.get("account_name", post.get("account_handle", "Twooter account"))).strip_edges()
	var target_ticker: String = str(post.get("target_ticker", "")).strip_edges().to_upper()
	var target_company_id: String = _social_target_company_id(post, str(post.get("account_id", "")))
	var detail_parts: Array = [body_text]
	var thread_lines: Array = post.get("thread_lines", []) if typeof(post.get("thread_lines", [])) == TYPE_ARRAY else []
	for line_value in thread_lines.slice(0, 3):
		var line_text: String = str(line_value).strip_edges()
		if not line_text.is_empty():
			detail_parts.append(line_text)
	var label_text: String = "Twooter post: %s" % account_name
	var value_text: String = "$%s" % target_ticker if not target_ticker.is_empty() else "Public chatter"
	return {
		"source_type": "twooter_post",
		"source_label": "Twooter",
		"category": "twooter",
		"company_id": target_company_id,
		"ticker": target_ticker,
		"label": label_text,
		"value": value_text,
		"detail": " ".join(detail_parts),
		"source_id": "twooter_post_%s" % str(post.get("id", _node_token(body_text.left(48)))),
		"impact": _social_tone_to_impact(str(post.get("tone", "mixed")))
	}


func _social_dm_capture_payload(row: Dictionary, account_id: String) -> Dictionary:
	var account: Dictionary = _social_account_for_id(account_id)
	var body_text: String = str(row.get("text", "")).strip_edges()
	if body_text.is_empty():
		return {}
	if str(row.get("sender", "")) != "player":
		body_text = _clean_social_account_reply_text(body_text)
	var account_name: String = str(account.get("display_name", "Twooter DM")).strip_edges()
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var target_ticker: String = str(profile.get("target_ticker", "")).strip_edges().to_upper()
	var target_company_id: String = _social_target_company_id(profile, account_id)
	var sender_label: String = "You" if str(row.get("sender", "")) == "player" else account_name
	return {
		"source_type": "twooter_dm",
		"source_label": "Twooter DM",
		"category": "twooter",
		"company_id": target_company_id,
		"ticker": target_ticker,
		"label": "Twooter DM: %s" % account_name,
		"value": sender_label,
		"detail": body_text,
		"source_id": "twooter_dm_%s_%d_%s_%s" % [
			account_id,
			int(row.get("day_index", RunState.day_index)),
			str(row.get("action_id", "message")),
			_node_token(body_text.left(48))
		],
		"impact": "mixed"
	}


func _social_target_company_id(source: Dictionary, account_id: String = "") -> String:
	var company_id: String = str(source.get("target_company_id", source.get("company_id", ""))).strip_edges()
	if not company_id.is_empty():
		return company_id
	var ticker: String = str(source.get("target_ticker", "")).strip_edges()
	if ticker.is_empty() and not account_id.is_empty():
		var account: Dictionary = _social_account_for_id(account_id)
		var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
		ticker = str(profile.get("target_ticker", "")).strip_edges()
		company_id = str(profile.get("target_company_id", "")).strip_edges()
		if not company_id.is_empty():
			return company_id
	return _company_id_for_ticker(ticker)


func _social_account_for_id(account_id: String) -> Dictionary:
	if account_id.is_empty() or current_social_snapshot.is_empty():
		return {}
	for account_value in current_social_snapshot.get("accounts", []):
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value
		if str(account.get("id", "")) == account_id:
			return account
	return {}


func _social_tone_to_impact(tone: String) -> String:
	match tone.to_lower():
		"bullish", "positive", "constructive":
			return "positive"
		"bearish", "negative", "warning", "risk":
			return "negative"
	return "mixed"


func _company_id_for_ticker(ticker: String) -> String:
	var normalized_ticker: String = ticker.strip_edges().to_upper()
	if normalized_ticker.begins_with("$"):
		normalized_ticker = normalized_ticker.substr(1)
	if normalized_ticker.is_empty():
		return ""
	for row_value in _get_company_rows_cached():
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("ticker", "")).strip_edges().to_upper() == normalized_ticker:
			return str(row.get("id", ""))
	return ""


func _show_social_capture_menu(menu_position: Vector2) -> void:
	if social_capture_menu == null:
		social_capture_menu = PopupMenu.new()
		social_capture_menu.name = "SocialCaptureContextMenu"
		social_capture_menu.id_pressed.connect(_on_social_capture_menu_id_pressed)
		add_child(social_capture_menu)
		_sync_root_refs()
	social_capture_menu.clear()
	social_capture_menu.add_item("Add to Research Tray", 1)
	social_capture_menu.position = Vector2i(int(menu_position.x), int(menu_position.y))
	social_capture_menu.popup()


func _on_social_capture_menu_id_pressed(id: int) -> void:
	_commit_pending_capture("social", id)


func _make_social_rail_body_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", COLOR_TWOOTER_MUTED)
	_apply_font_override_to_control(label, _social_font_size(12), _get_app_font())
	return label


func _clear_container(container: Container) -> void:
	if container == null:
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _rebuild_social_filter_chips(posts: Array) -> void:
	if social_filter_chips == null:
		return
	for child in social_filter_chips.get_children():
		social_filter_chips.remove_child(child)
		child.queue_free()

	for filter_value in _social_feed_filters_for_posts(posts):
		var filter: Dictionary = filter_value
		var filter_id: String = str(filter.get("id", SOCIAL_FEED_FILTER_ALL))
		var count: int = _count_social_posts_for_filter(posts, filter_id)
		var button := Button.new()
		button.name = "SocialFeedFilter%sButton" % filter_id.capitalize()
		button.text = "%s %d" % [str(filter.get("label", "All")), count]
		button.custom_minimum_size = Vector2(82, 30)
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.tooltip_text = "Filter the Twooter feed by %s." % str(filter.get("label", "All")).to_lower()
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.disabled = filter_id != SOCIAL_FEED_FILTER_ALL and count == 0
		_style_social_filter_button(button, filter_id == selected_social_feed_filter_id, not button.disabled)
		social_filter_chips.add_child(button)
		button.pressed.connect(_on_social_feed_filter_pressed.bind(filter_id))


func _on_social_feed_filter_pressed(filter_id: String) -> void:
	if filter_id.is_empty() or filter_id == selected_social_feed_filter_id:
		return
	selected_social_feed_filter_id = filter_id
	_refresh_social()


func _rebuild_social_ticker_tape(visible_posts: Array, all_posts: Array) -> void:
	if social_ticker_tape == null:
		return
	for child in social_ticker_tape.get_children():
		social_ticker_tape.remove_child(child)
		child.queue_free()

	var ticker_rows: Array = _social_ticker_rows_from_posts(visible_posts)
	if ticker_rows.is_empty():
		ticker_rows = _social_ticker_rows_from_posts(all_posts)

	if ticker_rows.is_empty():
		var empty_label := Label.new()
		empty_label.name = "SocialTickerTapeEmptyLabel"
		empty_label.text = "No ticker chatter yet"
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", COLOR_TWOOTER_MUTED)
		_apply_font_override_to_control(empty_label, _social_font_size(12), _get_app_font())
		social_ticker_tape.add_child(empty_label)
		return

	for row_index in range(min(ticker_rows.size(), SOCIAL_TICKER_TAPE_LIMIT)):
		var row: Dictionary = ticker_rows[row_index]
		social_ticker_tape.add_child(_build_social_ticker_chip(row))


func _social_ticker_rows_from_posts(posts: Array) -> Array:
	var lookup: Dictionary = {}
	var rows: Array = []
	for post_value in posts:
		if typeof(post_value) != TYPE_DICTIONARY:
			continue
		var post: Dictionary = post_value
		var ticker: String = str(post.get("target_ticker", "")).strip_edges().to_upper()
		if ticker.is_empty() or lookup.has(ticker):
			continue
		lookup[ticker] = true
		rows.append({
			"ticker": ticker,
			"tone": str(post.get("tone", "mixed")),
			"score": _social_post_engagement_score(post)
		})
	return rows


func _build_social_ticker_chip(row: Dictionary) -> PanelContainer:
	var tone: String = str(row.get("tone", "mixed"))
	var chip := PanelContainer.new()
	chip.name = "SocialTickerChip"
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_style_social_ticker_chip(chip, tone)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	chip.add_child(margin)

	var row_box := HBoxContainer.new()
	row_box.add_theme_constant_override("separation", 5)
	margin.add_child(row_box)

	var ticker_label := Label.new()
	ticker_label.text = "$%s" % str(row.get("ticker", ""))
	ticker_label.add_theme_color_override("font_color", COLOR_TWOOTER_BLUE_DARK)
	_apply_font_override_to_control(ticker_label, _social_font_size(12), _get_dashboard_title_font())
	row_box.add_child(ticker_label)
	return chip


func _rebuild_social_feed_cards(posts: Array) -> void:
	for child in social_feed_cards.get_children():
		social_feed_cards.remove_child(child)
		child.queue_free()

	if not selected_social_account_id.is_empty():
		var all_posts: Array = current_social_snapshot.get("posts", [])
		var selected_account_name: String = _selected_social_account_name(all_posts)
		social_feed_cards.add_child(_build_social_account_filter_nav_row())
		social_feed_cards.add_child(_build_social_account_filter_card(selected_account_name, selected_social_account_id))

	if posts.is_empty():
		social_feed_cards.add_child(_build_social_empty_card())
		return

	for post_value in posts:
		var post: Dictionary = post_value
		social_feed_cards.add_child(_build_social_post_card(post))

	if social_feed_scroll.get_v_scroll_bar() != null:
		social_feed_scroll.get_v_scroll_bar().value = 0.0


func _build_social_account_filter_nav_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "SocialAccountFilterNavRow"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var clear_button: Button = Button.new()
	clear_button.name = "SocialAccountClearButton"
	clear_button.text = "All accounts"
	clear_button.tooltip_text = "Return to the full Twooter feed."
	clear_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clear_button.custom_minimum_size = Vector2(112, 32)
	_style_social_filter_button(clear_button, false, true)
	row.add_child(clear_button)
	clear_button.pressed.connect(_on_social_account_filter_cleared)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	return row


func _build_social_account_filter_card(account_name: String, account_id: String) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.name = "SocialAccountProfileCard"
	card.set_meta("social_account_id", account_id)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_social_post_card(card, "mixed")

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)

	var account: Dictionary = _social_account_from_snapshot(account_id)
	if account_name.strip_edges().is_empty():
		account_name = str(account.get("display_name", account_id))
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "SocialAccountProfileVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.name = "SocialAccountProfileHeader"
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_theme_constant_override("separation", 12)
	vbox.add_child(header_row)

	var avatar := PanelContainer.new()
	avatar.name = "SocialAccountProfileAvatar"
	avatar.custom_minimum_size = Vector2(52, 52)
	_style_twooter_panel(avatar, _social_avatar_color(account_id), COLOR_TWOOTER_BLUE_EDGE, 26, 2)
	var avatar_label := Label.new()
	avatar_label.text = account_name.left(1).to_upper()
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_label.add_theme_color_override("font_color", COLOR_TWOOTER_TEXT)
	_apply_font_override_to_control(avatar_label, _social_font_size(DEFAULT_APP_FONT_SIZE + 6), _get_dashboard_title_font())
	avatar.add_child(avatar_label)
	header_row.add_child(avatar)

	var identity_box: VBoxContainer = VBoxContainer.new()
	identity_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_box.add_theme_constant_override("separation", 4)
	header_row.add_child(identity_box)

	var title_row := HBoxContainer.new()
	title_row.name = "SocialAccountProfileTitleRow"
	title_row.add_theme_constant_override("separation", 6)
	identity_box.add_child(title_row)
	var name_label: Label = Label.new()
	name_label.name = "SocialAccountProfileNameLabel"
	name_label.text = account_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.add_theme_color_override("font_color", COLOR_TWOOTER_TEXT)
	_apply_font_override_to_control(name_label, _social_font_size(DEFAULT_APP_FONT_SIZE + 4), _get_dashboard_title_font())
	title_row.add_child(name_label)
	if bool(account.get("verified", false)):
		var verified_label := Label.new()
		verified_label.name = "SocialAccountProfileVerifiedLabel"
		verified_label.text = "Verified"
		verified_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		verified_label.add_theme_color_override("font_color", COLOR_TWOOTER_BLUE)
		_apply_font_override_to_control(verified_label, _social_font_size(11), _get_dashboard_title_font())
		title_row.add_child(verified_label)

	var handle_label: Label = Label.new()
	handle_label.name = "SocialAccountProfileHandleLabel"
	handle_label.text = "%s  |  %s" % [
		str(account.get("handle", "")),
		_social_stage_label(str(account.get("relationship_stage", "stranger")))
	]
	handle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	handle_label.add_theme_color_override("font_color", COLOR_TWOOTER_MUTED)
	_apply_font_override_to_control(handle_label, _social_font_size(12), _get_app_font())
	identity_box.add_child(handle_label)

	var role_label: Label = Label.new()
	role_label.name = "SocialAccountProfileRoleLabel"
	role_label.text = str(profile.get("role", "Public market voice"))
	role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	role_label.add_theme_color_override("font_color", COLOR_TWOOTER_TEXT)
	_apply_font_override_to_control(role_label, _social_font_size(13), _get_app_font())
	identity_box.add_child(role_label)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.name = "SocialAccountProfileActionRow"
	action_row.add_theme_constant_override("separation", 8)
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(action_row)

	var follow_button: Button = Button.new()
	follow_button.name = "SocialAccountFollowButton"
	follow_button.text = "Following" if bool(account.get("following", false)) else "Follow"
	follow_button.tooltip_text = "Follow this account and add it to the Following feed."
	follow_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	follow_button.custom_minimum_size = Vector2(112, SOCIAL_ACTION_BUTTON_MIN_HEIGHT)
	follow_button.disabled = bool(account.get("following", false))
	_style_social_filter_button(follow_button, bool(account.get("following", false)), true)
	action_row.add_child(follow_button)
	follow_button.pressed.connect(_on_social_follow_pressed.bind(account_id))

	var message_button: Button = Button.new()
	message_button.name = "SocialStartMessageButton"
	message_button.text = "Send message"
	message_button.tooltip_text = "Start a private Twooter message."
	message_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	message_button.custom_minimum_size = Vector2(148, SOCIAL_ACTION_BUTTON_MIN_HEIGHT)
	_style_social_filter_button(message_button, false, true)
	action_row.add_child(message_button)
	message_button.pressed.connect(_on_social_start_message_pressed.bind(account_id))

	var stats_row := HFlowContainer.new()
	stats_row.name = "SocialAccountProfileStats"
	stats_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_row.add_theme_constant_override("h_separation", 6)
	stats_row.add_theme_constant_override("v_separation", 6)
	vbox.add_child(stats_row)
	stats_row.add_child(_build_social_profile_stat_chip("Relationship", int(account.get("relationship", 0))))
	stats_row.add_child(_build_social_profile_stat_chip("Credibility", int(account.get("credibility", 0))))
	stats_row.add_child(_build_social_profile_stat_chip("Importance", int(account.get("importance", 0))))
	stats_row.add_child(_build_social_profile_stat_chip("Exposure", int(account.get("exposure", 0))))
	stats_row.add_child(_build_social_profile_stat_chip("Likes", int(account.get("likes_given", 0))))
	stats_row.add_child(_build_social_profile_stat_chip("Posts", int(account.get("public_post_count", 0))))

	var description_label: Label = _make_social_profile_body_label(_social_account_description_text(account))
	description_label.name = "SocialAccountProfileDescriptionLabel"
	vbox.add_child(description_label)
	return card


func _build_social_profile_stat_chip(label_text: String, value: int) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.name = "SocialAccountProfileStatChip"
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_style_twooter_panel(chip, COLOR_TWOOTER_BLUE_TINT, COLOR_TWOOTER_BORDER, 6, 1)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 5)
	chip.add_child(margin)
	var label := Label.new()
	label.text = "%s %d" % [label_text, value]
	label.add_theme_color_override("font_color", COLOR_TWOOTER_TEXT)
	_apply_font_override_to_control(label, _social_font_size(11), _get_app_font())
	margin.add_child(label)
	return chip


func _make_social_profile_body_label(text: String) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	label.add_theme_color_override("font_color", COLOR_TWOOTER_MUTED)
	_apply_font_override_to_control(label, _social_font_size(12), _get_app_font())
	return label


func _social_stage_label(stage_id: String) -> String:
	var clean_stage: String = stage_id.replace("_", " ").strip_edges()
	if clean_stage.is_empty():
		clean_stage = "stranger"
	return "%s relationship" % clean_stage.capitalize()


func _social_account_description_text(account: Dictionary) -> String:
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var description: String = str(profile.get("description", profile.get("intro", ""))).strip_edges()
	if not description.is_empty():
		return description
	var account_name: String = str(account.get("display_name", "This account")).strip_edges()
	var role: String = str(profile.get("role", "Public market voice")).strip_edges()
	var risk_profile: String = str(profile.get("risk_profile", "clean")).replace("_", " ").strip_edges()
	var voice: String = str(account.get("voice", "")).replace("_", " ").strip_edges()
	if role.is_empty():
		role = "public market voice"
	if risk_profile == "suspicious":
		return "%s is a %s. Useful for leads and crowd temperature, but treat its posts as starting points until you can verify them." % [account_name, role.to_lower()]
	if voice.contains("macro"):
		return "%s is a %s focused on broad market context, sector pressure, and the bigger forces behind daily moves." % [account_name, role.to_lower()]
	if voice.contains("funda") or voice.contains("quality") or voice.contains("value") or role.to_lower().contains("analyst"):
		return "%s is a %s who prefers written theses, public sources, and clear failure points before offering deeper feedback." % [account_name, role.to_lower()]
	return "%s is a %s who can help turn public chatter into cleaner watch items when you ask with evidence and patience." % [account_name, role.to_lower()]


func _social_account_next_step_text(account: Dictionary) -> String:
	var relationship: int = int(account.get("relationship", 0))
	var credibility: int = int(account.get("credibility", 0))
	var importance: int = int(account.get("importance", 0))
	var stage: String = str(account.get("relationship_stage", "stranger"))
	var has_shareable_thesis: bool = not current_social_snapshot.get("shareable_theses", []).is_empty()
	if not bool(account.get("following", false)) and int(account.get("interaction_count", 0)) > 0:
		return "Next: follow this account before asking for deeper reads. Likes and follow history now count as social attention."
	if relationship >= 5 and credibility < 12 and not has_shareable_thesis:
		return "Next: build an open Thesis first. Thesis-sharing and deeper review options need something concrete to inspect."
	if relationship < 5:
		return "Next: reply with useful context or send a clean intro. Early trust grows through specific, non-pushy questions."
	if stage == "stranger":
		return "Next: keep the thread useful until this account becomes familiar. Repeating the same ask will cool the branch."
	if stage == "familiar" and credibility < 7:
		return "Next: ask for sources or share a prepared Thesis to build credibility."
	if stage == "trusted":
		return "Next: trusted contacts can start surfacing room invites or higher-signal requests through Message."
	if importance >= 55:
		return "Next: this account sees you as important. Watch for inner-circle follow-ups and keep boundaries clean."
	return "Next: keep improving relationship, credibility, and importance through varied replies and private messages."


func _social_account_memory_text(account: Dictionary) -> String:
	var timeline: Array = account.get("timeline", []) if typeof(account.get("timeline", [])) == TYPE_ARRAY else []
	if timeline.is_empty():
		return "Recent memory: no direct interaction yet. Reply or send a message to start a trackable relationship."
	var latest: Dictionary = timeline[timeline.size() - 1] if typeof(timeline[timeline.size() - 1]) == TYPE_DICTIONARY else {}
	var action_label: String = _social_action_label(str(latest.get("action_id", "")))
	var body: String = str(latest.get("text", "")).strip_edges()
	if body.length() > 110:
		body = "%s..." % body.left(107)
	if body.is_empty():
		body = "Interaction recorded."
	return "Recent memory: %s - %s" % [action_label, body]


func _social_action_label(action_id: String) -> String:
	match action_id:
		"reply_support":
			return "Support"
		"reply_skeptic":
			return "Question"
		"ask_source_public", "ask_source_private":
			return "Source ask"
		"share_thesis":
			return "Thesis"
		"message_check_in":
			return "Message"
		"connect":
			return "Connect"
		"ask_tip":
			return "Clean read"
		"accept_invite":
			return "Invite"
		"respond_suspicious_request":
			return "Boundary"
		"like_post":
			return "Like"
		"follow":
			return "Follow"
	return "Interaction"


func _build_social_empty_card() -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_social_post_card(card, "mixed")

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var body: Label = Label.new()
	body.text = "No posts yet.\nAdvance the day to generate fresh chatter."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", _social_font_size(DEFAULT_APP_FONT_SIZE))
	body.add_theme_color_override("font_color", COLOR_TWOOTER_MUTED)
	margin.add_child(body)
	return card


func _build_social_post_card(post: Dictionary) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.name = "SocialPostCard"
	card.set_meta("social_account_id", str(post.get("account_id", "")))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 0)
	_style_social_post_card(card, str(post.get("tone", "mixed")))

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var card_row: HBoxContainer = HBoxContainer.new()
	card_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_row.add_theme_constant_override("separation", 12)
	margin.add_child(card_row)

	card_row.add_child(_build_social_avatar(post))

	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	card_row.add_child(content)

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_theme_constant_override("separation", 5)
	content.add_child(header_row)

	var account_button: Button = Button.new()
	account_button.name = "SocialAccountNameButton"
	account_button.set_meta("social_account_id", str(post.get("account_id", "")))
	account_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var account_name: String = str(post.get("account_name", "")).strip_edges()
	if account_name.is_empty():
		account_name = str(post.get("account_handle", "")).strip_edges()
	account_button.text = account_name
	account_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	account_button.tooltip_text = "Open this account profile and filter their posts."
	account_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_social_account_button(account_button, str(post.get("account_id", "")) == selected_social_account_id)
	header_row.add_child(account_button)
	account_button.pressed.connect(func() -> void:
		_on_social_account_pressed(str(post.get("account_id", "")))
	)

	var handle_label: Label = Label.new()
	handle_label.text = _build_social_card_meta_line(post)
	handle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	handle_label.add_theme_font_size_override("font_size", _social_font_size(12))
	handle_label.add_theme_color_override("font_color", COLOR_TWOOTER_MUTED)
	content.add_child(handle_label)

	var tag_row := HFlowContainer.new()
	tag_row.name = "SocialPostTagRow"
	tag_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag_row.add_theme_constant_override("h_separation", 5)
	tag_row.add_theme_constant_override("v_separation", 4)
	var has_tags: bool = false
	var target_ticker: String = str(post.get("target_ticker", "")).strip_edges().to_upper()
	var target_company: String = str(post.get("target_company_name", "")).strip_edges()
	var sector_name: String = str(post.get("sector_name", "")).strip_edges()
	if not target_ticker.is_empty():
		tag_row.add_child(_build_social_tag_chip("$%s" % target_ticker, "blue"))
		has_tags = true
	if not target_company.is_empty():
		tag_row.add_child(_build_social_tag_chip(target_company, "mixed"))
		has_tags = true
	elif not sector_name.is_empty():
		tag_row.add_child(_build_social_tag_chip(sector_name, "mixed"))
		has_tags = true
	var category_label: String = _social_category_label(post)
	if not category_label.is_empty():
		tag_row.add_child(_build_social_tag_chip(category_label, "blue"))
		has_tags = true
	if has_tags:
		content.add_child(tag_row)

	var body_label: Label = Label.new()
	body_label.text = str(post.get("post_text", ""))
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.mouse_filter = Control.MOUSE_FILTER_STOP
	body_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	body_label.tooltip_text = "Click to add this post to the Research Tray."
	body_label.gui_input.connect(_on_social_post_capture_gui_input.bind(post.duplicate(true)))
	body_label.add_theme_font_size_override("font_size", _social_font_size(DEFAULT_APP_FONT_SIZE + 1))
	body_label.add_theme_color_override("font_color", COLOR_TWOOTER_TEXT)
	content.add_child(body_label)

	var thread_lines: Array = post.get("thread_lines", [])
	if not thread_lines.is_empty():
		var thread_button: Button = Button.new()
		thread_button.name = "SocialThreadToggleButton"
		thread_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		thread_button.text = "Hide thread" if bool(expanded_social_thread_ids.get(str(post.get("id", "")), false)) else "Show thread"
		thread_button.tooltip_text = "Expand this Twooter thread."
		_style_social_thread_button(thread_button)
		content.add_child(thread_button)

		var thread_container: VBoxContainer = VBoxContainer.new()
		thread_container.name = "SocialThreadLines"
		thread_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		thread_container.add_theme_constant_override("separation", 5)
		thread_container.visible = bool(expanded_social_thread_ids.get(str(post.get("id", "")), false))
		content.add_child(thread_container)
		for thread_index in range(thread_lines.size()):
			var thread_line: Label = Label.new()
			thread_line.name = "SocialThreadLineLabel"
			var thread_text: String = str(thread_lines[thread_index])
			thread_line.text = thread_text if thread_text.begins_with("%d." % (thread_index + 1)) else "%d. %s" % [thread_index + 1, thread_text]
			thread_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			thread_line.add_theme_font_size_override("font_size", _social_font_size(12))
			thread_line.add_theme_color_override("font_color", COLOR_TWOOTER_BLUE_DARK)
			thread_container.add_child(thread_line)
		thread_button.pressed.connect(func() -> void:
			_on_social_thread_toggled(str(post.get("id", "")), thread_container, thread_button)
		)

	for reply_value in post.get("player_replies", []):
		if typeof(reply_value) == TYPE_DICTIONARY:
			content.add_child(_build_social_reply_row(reply_value))
	var conclusion_reason: String = str(post.get("conversation_conclusion", ""))
	if not conclusion_reason.is_empty():
		content.add_child(_build_social_conclusion_row(post))

	var options: Array = post.get("interaction_options", [])
	if bool(post.get("followup_unlocked", false)):
		var followup_button := Button.new()
		followup_button.name = "SocialPostFollowupButton"
		followup_button.text = "Message"
		followup_button.custom_minimum_size = Vector2(94, 30)
		followup_button.tooltip_text = "Continue this contact through private messages."
		_style_social_thread_button(followup_button)
		followup_button.pressed.connect(_on_social_start_message_pressed.bind(str(post.get("account_id", ""))))
		content.add_child(followup_button)
	elif bool(post.get("can_reply", true)) and not options.is_empty():
		var option_row := HBoxContainer.new()
		option_row.name = "SocialPostActionRow"
		option_row.add_theme_constant_override("separation", 8)
		option_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(option_row)
		var reply_button := Button.new()
		reply_button.name = "SocialPostActionButton"
		reply_button.text = "Reply"
		reply_button.custom_minimum_size = Vector2(86, 30)
		reply_button.tooltip_text = "Open the reply composer."
		_style_social_thread_button(reply_button)
		reply_button.pressed.connect(_open_social_reply_composer.bind(post.duplicate(true)))
		option_row.add_child(reply_button)

	var reactions_row := HBoxContainer.new()
	reactions_row.name = "SocialEngagementRow"
	reactions_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reactions_row.add_theme_constant_override("separation", 9)
	content.add_child(reactions_row)
	reactions_row.add_child(_build_social_engagement_label("Reply", int(post.get("replies", 0))))
	reactions_row.add_child(_build_social_engagement_label("Retwoot", int(post.get("retwoots", 0))))
	reactions_row.add_child(_build_social_like_button(post))

	return card


func _build_social_tag_chip(text: String, tone: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.name = "SocialPostTagChip"
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_style_social_tag_chip(chip, tone)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_bottom", 3)
	chip.add_child(margin)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", _social_font_size(11))
	label.add_theme_color_override("font_color", _social_tag_font_color(tone))
	margin.add_child(label)
	return chip


func _build_social_engagement_label(label_text: String, value: int) -> Label:
	var label := Label.new()
	label.text = "%s %d" % [label_text, value]
	label.add_theme_font_size_override("font_size", _social_font_size(11))
	label.add_theme_color_override("font_color", COLOR_TWOOTER_MUTED)
	return label


func _build_social_like_button(post: Dictionary) -> Button:
	var button := Button.new()
	button.name = "SocialPostLikeButton"
	button.text = "%s %d" % ["Liked" if bool(post.get("liked_by_player", false)) else "Like", int(post.get("likes", 0))]
	button.tooltip_text = "Like this post. Likes slowly build relationship with the account."
	button.disabled = bool(post.get("liked_by_player", false))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = Vector2(76, 24)
	_style_social_thread_button(button)
	button.pressed.connect(_on_social_post_like_pressed.bind(str(post.get("id", ""))))
	return button


func _build_social_reply_row(reply: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "SocialReplyRow"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_twooter_panel(panel, COLOR_TWOOTER_CARD, COLOR_TWOOTER_BORDER, 8, 1)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	margin.add_child(stack)
	var player_text: String = str(reply.get("player_text", "")).strip_edges()
	if not player_text.is_empty():
		stack.add_child(_build_social_reply_bubble("You", player_text, true))
	stack.add_child(_build_social_reply_bubble("", str(reply.get("reply_text", "")), false))
	return panel


func _build_social_reply_bubble(sender_label: String, body_text: String, is_player: bool) -> PanelContainer:
	var bubble := PanelContainer.new()
	bubble.name = "SocialPlayerReplyBubble" if is_player else "SocialAccountReplyBubble"
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill_color: Color = COLOR_TWOOTER_BLUE_TINT if is_player else COLOR_TWOOTER_SURFACE
	_style_twooter_panel(bubble, fill_color, COLOR_TWOOTER_BORDER, 6, 1)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 7)
	bubble.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)
	if not sender_label.strip_edges().is_empty():
		var name_label := Label.new()
		name_label.text = sender_label
		name_label.add_theme_color_override("font_color", COLOR_TWOOTER_BLUE if is_player else COLOR_TWOOTER_MUTED)
		_apply_font_override_to_control(name_label, _social_font_size(11), _get_dashboard_title_font())
		vbox.add_child(name_label)
	var label := Label.new()
	label.name = "SocialPlayerReplyTextLabel" if is_player else "SocialAccountReplyTextLabel"
	label.text = body_text if is_player else _clean_social_account_reply_text(body_text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", COLOR_TWOOTER_TEXT)
	_apply_font_override_to_control(label, _social_font_size(13), _get_app_font())
	vbox.add_child(label)
	return bubble


func _clean_social_account_reply_text(raw_text: String) -> String:
	var text: String = raw_text.strip_edges()
	if text.is_empty():
		return text
	var colon_index: int = text.find(":")
	if colon_index > 0 and colon_index < 72:
		var prefix: String = text.substr(0, colon_index).strip_edges().to_lower()
		var remainder: String = text.substr(colon_index + 1).strip_edges()
		if prefix.ends_with(" replies") or prefix.ends_with(" answers") or prefix.ends_with(" says") or remainder.begins_with("\""):
			text = remainder
	if text.length() >= 2 and text.begins_with("\"") and text.ends_with("\""):
		text = text.substr(1, text.length() - 2).strip_edges()
	return text


func _build_social_conclusion_row(post: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "SocialConversationConclusionRow"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_twooter_panel(panel, COLOR_TWOOTER_SURFACE, COLOR_TWOOTER_BORDER, 6, 1)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var label := Label.new()
	if bool(post.get("followup_unlocked", false)):
		label.text = "The public thread has enough trust to continue privately."
	elif str(post.get("cooldown_reason", "")).is_empty() == false or str(post.get("conversation_conclusion", "")) == "soft_cooldown":
		label.text = _social_dialog_cooldown_text(str(post.get("cooldown_reason", "soft_cooldown")))
	else:
		label.text = "The thread cools here. Build more relationship, credibility, and importance before pushing further."
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", COLOR_TWOOTER_MUTED)
	_apply_font_override_to_control(label, _social_font_size(12), _get_app_font())
	margin.add_child(label)
	return panel


func _social_dialog_cooldown_text(reason: String) -> String:
	if reason == "soft_cooldown":
		return "The conversation is circling. Wait for new tape, share a sharper thesis, or bring a cleaner source before pushing again."
	return "The conversation pauses here. Bring new context before continuing."


func _on_social_post_action_pressed(post_id: String, action_id: String, thesis_id: String = "", player_reply_text: String = "") -> void:
	var result: Dictionary = GameManager.interact_with_twooter_post(post_id, action_id, thesis_id, player_reply_text)
	if not bool(result.get("success", false)):
		_show_toast(str(result.get("message", "Twooter action failed.")), false)
		return
	_show_toast(str(result.get("reply_text", result.get("message", "Twooter replied."))), true)
	_refresh_social()
	_refresh_network()


func _on_social_post_like_pressed(post_id: String) -> void:
	var result: Dictionary = GameManager.like_twooter_post(post_id)
	if not bool(result.get("success", false)):
		_show_toast(str(result.get("message", "Could not like post.")), false)
		return
	_show_toast(str(result.get("message", "Post liked.")), true)
	_refresh_social()


func _ensure_social_reply_composer_dialog() -> void:
	if social_reply_dialog != null:
		return
	social_reply_dialog = Control.new()
	social_reply_dialog.name = "SocialReplyComposerDialog"
	social_reply_dialog.visible = false
	social_reply_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	social_reply_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(social_reply_dialog)

	var scrim := ColorRect.new()
	scrim.name = "SocialReplyComposerScrim"
	scrim.color = Color(0.0, 0.0, 0.0, 0.58)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	social_reply_dialog.add_child(scrim)

	var center := CenterContainer.new()
	center.name = "SocialReplyComposerCenter"
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	social_reply_dialog.add_child(center)

	var frame := PanelContainer.new()
	frame.name = "SocialReplyComposerFrame"
	frame.custom_minimum_size = Vector2(620, 360)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_twooter_panel(frame, COLOR_TWOOTER_PAGE, COLOR_TWOOTER_BLUE_EDGE, 10, 1)
	center.add_child(frame)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	frame.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "SocialReplyComposerVBox"
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	vbox.add_child(title_row)
	var title := Label.new()
	title.name = "SocialReplyComposerTitle"
	title.text = "Reply"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", COLOR_TWOOTER_TEXT)
	_apply_font_override_to_control(title, _social_font_size(DEFAULT_APP_FONT_SIZE + 5), _get_dashboard_title_font())
	title_row.add_child(title)
	var close_button := Button.new()
	close_button.name = "SocialReplyComposerCloseButton"
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(32, 26)
	_style_button(close_button, COLOR_TWOOTER_SURFACE, COLOR_TWOOTER_BORDER, COLOR_TWOOTER_TEXT, 5)
	close_button.pressed.connect(_hide_social_reply_composer)
	title_row.add_child(close_button)

	social_reply_context_label = Label.new()
	social_reply_context_label.name = "SocialReplyComposerContextLabel"
	social_reply_context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	social_reply_context_label.add_theme_color_override("font_color", COLOR_TWOOTER_MUTED)
	_apply_font_override_to_control(social_reply_context_label, _social_font_size(12), _get_app_font())
	vbox.add_child(social_reply_context_label)

	var text_panel := PanelContainer.new()
	text_panel.name = "SocialReplyComposerTextPanel"
	text_panel.custom_minimum_size = Vector2(0, 96)
	text_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_twooter_panel(text_panel, COLOR_TWOOTER_SURFACE, COLOR_TWOOTER_BORDER, 7, 1)
	vbox.add_child(text_panel)
	var text_margin := MarginContainer.new()
	text_margin.add_theme_constant_override("margin_left", 12)
	text_margin.add_theme_constant_override("margin_top", 10)
	text_margin.add_theme_constant_override("margin_right", 12)
	text_margin.add_theme_constant_override("margin_bottom", 10)
	text_panel.add_child(text_margin)
	social_reply_text_label = Label.new()
	social_reply_text_label.name = "SocialReplyComposerTextLabel"
	social_reply_text_label.text = ""
	social_reply_text_label.visible_characters = 0
	social_reply_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	social_reply_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	social_reply_text_label.add_theme_color_override("font_color", COLOR_TWOOTER_TEXT)
	_apply_font_override_to_control(social_reply_text_label, _social_font_size(DEFAULT_APP_FONT_SIZE), _get_app_font())
	text_margin.add_child(social_reply_text_label)

	var options := VBoxContainer.new()
	options.name = "SocialReplyComposerOptions"
	options.add_theme_constant_override("separation", 8)
	vbox.add_child(options)
	social_reply_option_buttons.clear()
	for option_index in range(3):
		var option_button := Button.new()
		option_button.name = "SocialReplyDialogOptionButton"
		option_button.custom_minimum_size = Vector2(0, 34)
		option_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		option_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_style_social_thread_button(option_button)
		option_button.pressed.connect(_on_social_reply_option_selected.bind(option_index))
		options.add_child(option_button)
		social_reply_option_buttons.append(option_button)

	var action_row := HBoxContainer.new()
	action_row.name = "SocialReplyComposerActionRow"
	action_row.alignment = BoxContainer.ALIGNMENT_END
	action_row.add_theme_constant_override("separation", 8)
	vbox.add_child(action_row)
	social_reply_cancel_button = Button.new()
	social_reply_cancel_button.name = "SocialReplyCancelButton"
	social_reply_cancel_button.text = "Cancel"
	social_reply_cancel_button.custom_minimum_size = Vector2(92, 34)
	_style_social_thread_button(social_reply_cancel_button)
	social_reply_cancel_button.pressed.connect(_hide_social_reply_composer)
	action_row.add_child(social_reply_cancel_button)
	social_reply_send_button = Button.new()
	social_reply_send_button.name = "SocialReplySendButton"
	social_reply_send_button.text = "Reply"
	social_reply_send_button.custom_minimum_size = Vector2(92, 34)
	social_reply_send_button.disabled = true
	_style_social_filter_button(social_reply_send_button, true, true)
	social_reply_send_button.pressed.connect(_send_social_reply_composer)
	action_row.add_child(social_reply_send_button)
	_sync_root_refs()


func _open_social_reply_composer(post: Dictionary) -> void:
	_ensure_social_reply_composer_dialog()
	pending_social_reply_post_id = str(post.get("id", ""))
	pending_social_reply_action_id = ""
	pending_social_reply_text = ""
	social_reply_context_label.text = "%s %s" % [str(post.get("account_name", "Account")), _build_social_card_meta_line(post)]
	social_reply_text_label.text = "Choose a reply below."
	social_reply_text_label.visible_characters = social_reply_text_label.text.length()
	social_reply_send_button.disabled = true
	var options: Array = post.get("reply_dialog_options", [])
	for option_index in range(social_reply_option_buttons.size()):
		var button: Button = social_reply_option_buttons[option_index]
		var option: Dictionary = options[option_index] if option_index < options.size() and typeof(options[option_index]) == TYPE_DICTIONARY else {}
		button.visible = not option.is_empty()
		button.disabled = option.is_empty() or not bool(option.get("enabled", true))
		button.text = str(option.get("player_text", option.get("label", "Reply")))
		button.tooltip_text = str(option.get("player_text", "")) if not bool(option.get("enabled", true)) else ""
		button.set_meta("action_id", str(option.get("id", "")))
		button.set_meta("tree_id", str(option.get("tree_id", "")))
		button.set_meta("node_id", str(option.get("node_id", "")))
		button.set_meta("option_id", str(option.get("option_id", "")))
		button.set_meta("player_text", str(option.get("player_text", "")))
	social_reply_dialog.visible = true


func _on_social_reply_option_selected(option_index: int) -> void:
	if option_index < 0 or option_index >= social_reply_option_buttons.size():
		return
	var button: Button = social_reply_option_buttons[option_index]
	pending_social_reply_action_id = str(button.get_meta("action_id", ""))
	pending_social_reply_text = str(button.get_meta("player_text", ""))
	if pending_social_reply_action_id.is_empty() or pending_social_reply_text.is_empty():
		return
	for option_button in social_reply_option_buttons:
		_style_social_thread_button(option_button)
	_style_social_filter_button(button, true, true)
	_start_social_reply_typewriter(pending_social_reply_text)


func _start_social_reply_typewriter(text: String) -> void:
	if social_reply_typing_tween != null:
		social_reply_typing_tween.kill()
		social_reply_typing_tween = null
	social_reply_send_button.disabled = true
	social_reply_text_label.text = text
	social_reply_text_label.visible_characters = 0
	var duration: float = clamp(float(text.length()) * 0.018, 0.28, 1.2)
	if _is_smoke_test_runtime():
		duration = 0.02
	social_reply_typing_tween = create_tween()
	social_reply_typing_tween.tween_property(social_reply_text_label, "visible_characters", text.length(), duration)
	social_reply_typing_tween.finished.connect(func() -> void:
		if social_reply_text_label != null:
			social_reply_text_label.visible_characters = social_reply_text_label.text.length()
		if social_reply_send_button != null:
			social_reply_send_button.disabled = pending_social_reply_action_id.is_empty()
		social_reply_typing_tween = null
	)


func _send_social_reply_composer() -> void:
	if pending_social_reply_post_id.is_empty() or pending_social_reply_action_id.is_empty():
		return
	if social_reply_typing_tween != null:
		social_reply_typing_tween.kill()
		social_reply_typing_tween = null
		social_reply_text_label.visible_characters = social_reply_text_label.text.length()
	var post_id: String = pending_social_reply_post_id
	var action_id: String = pending_social_reply_action_id
	var player_text: String = pending_social_reply_text
	_hide_social_reply_composer()
	_on_social_post_action_pressed(post_id, action_id, "", player_text)


func _hide_social_reply_composer() -> void:
	if social_reply_typing_tween != null:
		social_reply_typing_tween.kill()
		social_reply_typing_tween = null
	pending_social_reply_post_id = ""
	pending_social_reply_action_id = ""
	pending_social_reply_text = ""
	if social_reply_dialog != null:
		social_reply_dialog.visible = false


func _social_category_label(post: Dictionary) -> String:
	var category: String = str(post.get("category", "")).strip_edges()
	if category.is_empty():
		return ""
	return category.replace("_", " ").capitalize()


func _build_social_avatar(post: Dictionary) -> PanelContainer:
	var avatar: PanelContainer = PanelContainer.new()
	avatar.name = "SocialAvatar"
	avatar.custom_minimum_size = Vector2(40, 40)
	avatar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = _social_avatar_color(str(post.get("account_id", post.get("account_handle", ""))))
	style.border_color = COLOR_TWOOTER_BLUE_EDGE if bool(post.get("account_verified", false)) else Color(COLOR_TWOOTER_BORDER.r, COLOR_TWOOTER_BORDER.g, COLOR_TWOOTER_BORDER.b, 0.68)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left = 20
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	avatar.add_theme_stylebox_override("panel", style)

	var initial_label: Label = Label.new()
	initial_label.name = "SocialAvatarLabel"
	initial_label.custom_minimum_size = Vector2(40, 40)
	initial_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	initial_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	initial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initial_label.text = _social_avatar_initial(post)
	initial_label.add_theme_font_size_override("font_size", _social_font_size(DEFAULT_APP_FONT_SIZE + 3))
	initial_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	avatar.add_child(initial_label)
	return avatar


func _social_avatar_initial(post: Dictionary) -> String:
	var account_name: String = str(post.get("account_name", "")).strip_edges()
	if account_name.is_empty():
		account_name = str(post.get("account_handle", "")).strip_edges()
		if account_name.begins_with("@"):
			account_name = account_name.substr(1)
	if account_name.is_empty():
		return "?"
	return account_name.substr(0, 1).to_upper()


func _social_avatar_color(seed_value: String) -> Color:
	var palette: Array = [
		Color(0.109804, 0.431373, 0.709804, 1),
		Color(0.164706, 0.505882, 0.65098, 1),
		Color(0.117647, 0.470588, 0.290196, 1),
		Color(0.447059, 0.364706, 0.176471, 1),
		Color(0.168627, 0.294118, 0.54902, 1),
		Color(0.501961, 0.290196, 0.505882, 1),
		Color(0.0705882, 0.356863, 0.415686, 1),
		Color(0.635294, 0.098039, 0.164706, 1)
	]
	var rng_seed: int = 0
	for index in range(seed_value.length()):
		rng_seed = posmod(rng_seed * 33 + seed_value.unicode_at(index), 2147483647)
	return palette[posmod(rng_seed, palette.size())]


func _build_social_card_meta_line(post: Dictionary) -> String:
	var meta_parts: Array = []
	var handle: String = str(post.get("account_handle", "")).strip_edges()
	if not handle.is_empty():
		meta_parts.append(handle)
	var trade_date: Dictionary = post.get("trade_date", {})
	if not trade_date.is_empty():
		meta_parts.append(GameManager.format_trade_date(trade_date))
	if not str(post.get("visibility_label", "")).is_empty():
		meta_parts.append(str(post.get("visibility_label", "")))
	if not str(post.get("public_topic_label", "")).is_empty():
		meta_parts.append(str(post.get("public_topic_label", "")))
	if not str(post.get("public_confidence_label", "")).is_empty():
		meta_parts.append(str(post.get("public_confidence_label", "")))
	if not str(post.get("target_ticker", "")).is_empty():
		meta_parts.append(str(post.get("target_ticker", "")))
	elif not str(post.get("person_name", "")).is_empty():
		meta_parts.append(str(post.get("person_name", "")))
	elif not str(post.get("sector_name", "")).is_empty():
		meta_parts.append(str(post.get("sector_name", "")))
	return "  |  ".join(meta_parts)


func _on_social_account_pressed(account_id: String) -> void:
	if account_id.is_empty() or account_id == selected_social_account_id:
		return
	selected_social_account_id = account_id
	_refresh_social()
	_mark_guide_research_interaction()


func _on_social_account_filter_cleared() -> void:
	if selected_social_account_id.is_empty():
		return
	selected_social_account_id = ""
	_refresh_social()


func _on_social_start_message_pressed(account_id: String) -> void:
	if account_id.is_empty():
		return
	selected_social_message_account_id = account_id
	selected_social_view_id = "message"
	_refresh_social()


func _on_social_thread_toggled(post_id: String, thread_container: VBoxContainer, thread_button: Button) -> void:
	var next_visible: bool = not thread_container.visible
	thread_container.visible = next_visible
	expanded_social_thread_ids[post_id] = next_visible
	thread_button.text = "Hide thread" if next_visible else "Show thread"
	if next_visible:
		_mark_guide_research_interaction()


func _style_social_post_card(panel: PanelContainer, _tone: String) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_TWOOTER_CARD
	style.border_color = COLOR_TWOOTER_BORDER
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", style)


func _social_card_border_color(_tone: String) -> Color:
	return COLOR_TWOOTER_BORDER


func _style_twooter_ui() -> void:
	if social_window_body == null:
		return
	_style_twooter_panel(social_window_body, COLOR_TWOOTER_PAGE, COLOR_TWOOTER_BLUE_EDGE, 0, 2)
	if social_center_panel != null:
		_style_twooter_panel(social_center_panel, COLOR_TWOOTER_PAGE, COLOR_TWOOTER_BORDER, 0, 1)
	if social_left_sidebar != null:
		_style_twooter_panel(social_left_sidebar, COLOR_TWOOTER_PAGE, COLOR_TWOOTER_BORDER, 0, 1)
	if social_ticker_tape_panel != null:
		_style_twooter_panel(social_ticker_tape_panel, COLOR_TWOOTER_BLUE_TINT, COLOR_TWOOTER_BORDER, 0, 1)
	if social_live_dot != null:
		_style_twooter_panel(social_live_dot, COLOR_TWOOTER_LIVE, COLOR_TWOOTER_LIVE, 5, 1)
	if social_live_label != null:
		social_live_label.add_theme_color_override("font_color", COLOR_TWOOTER_MUTED)
		_apply_font_override_to_control(social_live_label, _social_font_size(11), _get_dashboard_title_font())
	_set_label_tone(social_title_label, COLOR_TWOOTER_TEXT)
	_apply_font_override_to_control(social_title_label, _social_font_size(DEFAULT_APP_FONT_SIZE + 8), _get_dashboard_title_font())
	_set_label_tone(social_access_status_label, COLOR_TWOOTER_MUTED)
	_apply_font_override_to_control(social_access_status_label, _social_font_size(12), _get_app_font())
	_set_label_tone(social_feed_summary_label, COLOR_TWOOTER_MUTED)
	_apply_font_override_to_control(social_feed_summary_label, _social_font_size(12), _get_app_font())
	_apply_social_view_visibility()


func _style_twooter_panel(panel: PanelContainer, fill_color: Color, border_color: Color, radius: int = 6, border_width: int = 1) -> void:
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	panel.add_theme_stylebox_override("panel", style)


func _style_social_ticker_chip(panel: PanelContainer, _tone: String) -> void:
	_style_twooter_panel(panel, COLOR_TWOOTER_CARD, COLOR_TWOOTER_BLUE_EDGE, 5, 1)


func _style_social_tag_chip(panel: PanelContainer, tone: String) -> void:
	var fill_color: Color = Color(COLOR_TWOOTER_BLUE_TINT.r, COLOR_TWOOTER_BLUE_TINT.g, COLOR_TWOOTER_BLUE_TINT.b, 0.62)
	var border_color: Color = COLOR_TWOOTER_BLUE_EDGE
	if tone == "mixed":
		fill_color = Color(COLOR_TWOOTER_SURFACE.r, COLOR_TWOOTER_SURFACE.g, COLOR_TWOOTER_SURFACE.b, 0.86)
		border_color = Color(COLOR_TWOOTER_BORDER.r, COLOR_TWOOTER_BORDER.g, COLOR_TWOOTER_BORDER.b, 0.62)
	_style_twooter_panel(panel, fill_color, border_color, 5, 1)


func _social_tag_font_color(tone: String) -> Color:
	if tone == "blue":
		return COLOR_TWOOTER_BLUE_DARK
	return COLOR_TWOOTER_MUTED


func _style_social_nav_button(button: Button, is_selected: bool) -> void:
	var fill_color: Color = COLOR_TWOOTER_SURFACE if is_selected else COLOR_TWOOTER_PAGE
	var border_color: Color = COLOR_TWOOTER_SURFACE if is_selected else COLOR_TWOOTER_PAGE
	var font_color: Color = COLOR_TWOOTER_TEXT if is_selected else COLOR_TWOOTER_MUTED
	UiTheme.style_button(
		button,
		"custom",
		{
			"fill": fill_color,
			"border": border_color,
			"font": font_color,
			"radius": 20,
			"margins": {"left": SOCIAL_NAV_BUTTON_PAD_X, "top": SOCIAL_NAV_BUTTON_PAD_Y, "right": SOCIAL_NAV_BUTTON_PAD_X, "bottom": SOCIAL_NAV_BUTTON_PAD_Y}
		}
	)
	_apply_font_override_to_control(button, _social_font_size(DEFAULT_APP_FONT_SIZE + 2), _get_dashboard_title_font())


func _style_social_thread_button(button: Button) -> void:
	UiTheme.style_button(
		button,
		"custom",
		{
			"fill": COLOR_TWOOTER_BLUE_TINT,
			"border": COLOR_TWOOTER_BORDER,
			"font": COLOR_TWOOTER_BLUE,
			"radius": 7,
			"margins": {"left": SOCIAL_ACTION_BUTTON_PAD_X, "top": SOCIAL_ACTION_BUTTON_PAD_Y, "right": SOCIAL_ACTION_BUTTON_PAD_X, "bottom": SOCIAL_ACTION_BUTTON_PAD_Y}
		}
	)
	button.custom_minimum_size = Vector2(button.custom_minimum_size.x, max(button.custom_minimum_size.y, float(SOCIAL_ACTION_BUTTON_MIN_HEIGHT)))
	_apply_font_override_to_control(button, _social_font_size(12), _get_dashboard_title_font())


func _style_social_follow_cta_button(button: Button) -> void:
	UiTheme.style_button(
		button,
		"custom",
		{
			"fill": COLOR_TWOOTER_TEXT,
			"border": COLOR_TWOOTER_TEXT,
			"font": COLOR_TWOOTER_PAGE,
			"radius": 19,
			"margins": {"left": SOCIAL_ACTION_BUTTON_PAD_X, "top": SOCIAL_ACTION_BUTTON_PAD_Y, "right": SOCIAL_ACTION_BUTTON_PAD_X, "bottom": SOCIAL_ACTION_BUTTON_PAD_Y}
		}
	)
	button.custom_minimum_size = Vector2(button.custom_minimum_size.x, max(button.custom_minimum_size.y, float(SOCIAL_ACTION_BUTTON_MIN_HEIGHT)))
	_apply_font_override_to_control(button, _social_font_size(12), _get_dashboard_title_font())


func _style_social_search_input(line_edit: LineEdit) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_TWOOTER_BLUE_TINT
	normal.border_color = COLOR_TWOOTER_BORDER
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 14
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_right = 14
	normal.corner_radius_bottom_left = 14
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var focus: StyleBoxFlat = normal.duplicate()
	focus.border_color = COLOR_TWOOTER_BLUE
	line_edit.add_theme_stylebox_override("normal", normal)
	line_edit.add_theme_stylebox_override("focus", focus)
	line_edit.add_theme_stylebox_override("read_only", normal)
	line_edit.add_theme_color_override("font_color", COLOR_TWOOTER_TEXT)
	line_edit.add_theme_color_override("font_placeholder_color", COLOR_TWOOTER_MUTED)
	line_edit.add_theme_color_override("font_uneditable_color", COLOR_TWOOTER_TEXT)
	_apply_font_override_to_control(line_edit, _social_font_size(DEFAULT_APP_FONT_SIZE), _get_app_font())

func _open_social_account_from_news(account_id: String, contact_id: String = "") -> void:
	if account_id.is_empty():
		_show_toast("No Twooter handle is available for that source yet.", false)
		return
	selected_social_view_id = "home"
	selected_social_account_id = account_id
	selected_social_feed_filter_id = SOCIAL_FEED_FILTER_ALL
	_set_active_app(APP_ID_SOCIAL)
	var account: Dictionary = _social_account_from_snapshot(account_id)
	var handle: String = str(account.get("handle", "")).strip_edges()
	if handle.is_empty() and not contact_id.is_empty():
		handle = str(news_meet_contact_button.get_meta("twooter_handle", "")).strip_edges()
	_show_toast("Opened %s on Twooter." % (handle if not handle.is_empty() else "source"), true)

func _ensure_social_feed_ui() -> void:
	_sync_dynamic_refs_from_root()
	if social_window_body == null:
		return

	var window_margin := social_window_body.get_node_or_null("SocialWindowMargin") as MarginContainer
	if window_margin != null:
		window_margin.add_theme_constant_override("margin_left", 0)
		window_margin.add_theme_constant_override("margin_top", 0)
		window_margin.add_theme_constant_override("margin_right", 0)
		window_margin.add_theme_constant_override("margin_bottom", 0)

	var window_vbox := social_feed_summary_label.get_parent() as VBoxContainer
	if window_vbox != null:
		window_vbox.add_theme_constant_override("separation", 8)
		window_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		window_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if window_margin != null and window_vbox != null and social_app_shell == null:
		social_app_shell = HBoxContainer.new()
		social_app_shell.name = "SocialAppShell"
		social_app_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_app_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		social_app_shell.add_theme_constant_override("separation", 0)
		window_margin.add_child(social_app_shell)

		var left_sidebar_margin := MarginContainer.new()
		left_sidebar_margin.name = "SocialLeftSidebarMargin"
		left_sidebar_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
		left_sidebar_margin.add_theme_constant_override("margin_left", SOCIAL_SIDE_MARGIN_LEFT)
		left_sidebar_margin.add_theme_constant_override("margin_top", SOCIAL_SIDE_MARGIN_TOP)
		left_sidebar_margin.add_theme_constant_override("margin_right", 0)
		left_sidebar_margin.add_theme_constant_override("margin_bottom", SOCIAL_SIDE_MARGIN_BOTTOM)
		social_app_shell.add_child(left_sidebar_margin)
		social_left_sidebar = _build_social_left_sidebar()
		left_sidebar_margin.add_child(social_left_sidebar)

		social_center_panel = PanelContainer.new()
		social_center_panel.name = "SocialCenterPanel"
		social_center_panel.custom_minimum_size = Vector2(540, 0)
		social_center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		social_app_shell.add_child(social_center_panel)
		var center_margin := MarginContainer.new()
		center_margin.name = "SocialCenterMargin"
		center_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		center_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
		center_margin.add_theme_constant_override("margin_left", SOCIAL_CENTER_MARGIN_LEFT)
		center_margin.add_theme_constant_override("margin_top", SOCIAL_CENTER_MARGIN_TOP)
		center_margin.add_theme_constant_override("margin_right", SOCIAL_CENTER_MARGIN_RIGHT)
		center_margin.add_theme_constant_override("margin_bottom", SOCIAL_CENTER_MARGIN_BOTTOM)
		social_center_panel.add_child(center_margin)
		var previous_parent: Node = window_vbox.get_parent()
		if previous_parent != null:
			previous_parent.remove_child(window_vbox)
		center_margin.add_child(window_vbox)

		var right_rail_margin := MarginContainer.new()
		right_rail_margin.name = "SocialRightRailMargin"
		right_rail_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
		right_rail_margin.add_theme_constant_override("margin_left", SOCIAL_SIDE_MARGIN_LEFT)
		right_rail_margin.add_theme_constant_override("margin_top", SOCIAL_SIDE_MARGIN_TOP)
		right_rail_margin.add_theme_constant_override("margin_right", SOCIAL_SIDE_MARGIN_RIGHT)
		right_rail_margin.add_theme_constant_override("margin_bottom", SOCIAL_SIDE_MARGIN_BOTTOM)
		social_app_shell.add_child(right_rail_margin)
		social_right_rail = _build_social_right_rail()
		right_rail_margin.add_child(social_right_rail)

	var header_row := social_title_label.get_parent() as HBoxContainer
	if header_row != null:
		header_row.custom_minimum_size = Vector2(0, 40)
		header_row.add_theme_constant_override("separation", 8)
		social_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_access_status_label.size_flags_horizontal = Control.SIZE_SHRINK_END
		if social_live_dot == null:
			social_live_dot = PanelContainer.new()
			social_live_dot.name = "SocialLiveDot"
			social_live_dot.custom_minimum_size = Vector2(9, 9)
			social_live_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			header_row.add_child(social_live_dot)
			header_row.move_child(social_live_dot, min(1, header_row.get_child_count() - 1))
		if social_live_label == null:
			social_live_label = Label.new()
			social_live_label.name = "SocialLiveLabel"
			social_live_label.text = "Live"
			social_live_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			header_row.add_child(social_live_label)
			header_row.move_child(social_live_label, min(2, header_row.get_child_count() - 1))
		if social_tier_indicator == null:
			social_tier_indicator = HBoxContainer.new()
			social_tier_indicator.name = "SocialTierIndicator"
			social_tier_indicator.custom_minimum_size = Vector2(54, 14)
			social_tier_indicator.size_flags_horizontal = Control.SIZE_SHRINK_END
			social_tier_indicator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			social_tier_indicator.add_theme_constant_override("separation", 3)
			header_row.add_child(social_tier_indicator)

	social_feed_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	social_feed_summary_label.clip_text = true
	social_feed_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	social_feed_scroll.follow_focus = false
	social_feed_cards.add_theme_constant_override("separation", 10)
	social_feed_cards.custom_minimum_size = Vector2(0, 0)

	if window_vbox != null and social_filter_scroll == null:
		social_filter_scroll = ScrollContainer.new()
		social_filter_scroll.name = "SocialFeedFilterScroll"
		social_filter_scroll.custom_minimum_size = Vector2(0, 38)
		social_filter_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_filter_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		window_vbox.add_child(social_filter_scroll)
		window_vbox.move_child(social_filter_scroll, window_vbox.get_children().find(social_feed_scroll))

		social_filter_chips = HBoxContainer.new()
		social_filter_chips.name = "SocialFeedFilterChips"
		social_filter_chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_filter_chips.add_theme_constant_override("separation", 10)
		social_filter_scroll.add_child(social_filter_chips)

	if window_vbox != null and social_ticker_tape_panel == null:
		social_ticker_tape_panel = PanelContainer.new()
		social_ticker_tape_panel.name = "SocialTickerTapePanel"
		social_ticker_tape_panel.custom_minimum_size = Vector2(0, 36)
		social_ticker_tape_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		window_vbox.add_child(social_ticker_tape_panel)
		window_vbox.move_child(social_ticker_tape_panel, window_vbox.get_children().find(social_feed_scroll))

		var ticker_margin := MarginContainer.new()
		ticker_margin.name = "SocialTickerTapeMargin"
		ticker_margin.add_theme_constant_override("margin_left", 8)
		ticker_margin.add_theme_constant_override("margin_top", 5)
		ticker_margin.add_theme_constant_override("margin_right", 8)
		ticker_margin.add_theme_constant_override("margin_bottom", 5)
		social_ticker_tape_panel.add_child(ticker_margin)

		social_ticker_tape_scroll = ScrollContainer.new()
		social_ticker_tape_scroll.name = "SocialTickerTapeScroll"
		social_ticker_tape_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_ticker_tape_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		ticker_margin.add_child(social_ticker_tape_scroll)

		social_ticker_tape = HBoxContainer.new()
		social_ticker_tape.name = "SocialTickerTape"
		social_ticker_tape.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_ticker_tape.add_theme_constant_override("separation", 6)
		social_ticker_tape_scroll.add_child(social_ticker_tape)

	if window_vbox != null and social_message_view == null:
		social_message_view = HBoxContainer.new()
		social_message_view.name = "SocialMessageView"
		social_message_view.custom_minimum_size = Vector2.ZERO
		social_message_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_message_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
		social_message_view.add_theme_constant_override("separation", 10)
		window_vbox.add_child(social_message_view)

		var thread_panel := PanelContainer.new()
		thread_panel.name = "SocialMessageThreadPanel"
		thread_panel.custom_minimum_size = Vector2(208, 0)
		thread_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		thread_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_style_twooter_panel(thread_panel, COLOR_TWOOTER_SURFACE, COLOR_TWOOTER_BORDER, 0, 1)
		social_message_view.add_child(thread_panel)
		var thread_margin := MarginContainer.new()
		thread_margin.add_theme_constant_override("margin_left", 10)
		thread_margin.add_theme_constant_override("margin_top", 10)
		thread_margin.add_theme_constant_override("margin_right", 10)
		thread_margin.add_theme_constant_override("margin_bottom", 10)
		thread_panel.add_child(thread_margin)
		social_message_thread_scroll = ScrollContainer.new()
		social_message_thread_scroll.name = "SocialMessageThreadScroll"
		social_message_thread_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_message_thread_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		social_message_thread_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		thread_margin.add_child(social_message_thread_scroll)
		social_message_threads = VBoxContainer.new()
		social_message_threads.name = "SocialMessageThreads"
		social_message_threads.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_message_threads.add_theme_constant_override("separation", 8)
		social_message_thread_scroll.add_child(social_message_threads)

		var detail_panel := PanelContainer.new()
		detail_panel.name = "SocialMessageDetailPanel"
		detail_panel.custom_minimum_size = Vector2.ZERO
		detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_style_twooter_panel(detail_panel, COLOR_TWOOTER_PAGE, COLOR_TWOOTER_BORDER, 0, 1)
		social_message_view.add_child(detail_panel)
		var detail_margin := MarginContainer.new()
		detail_margin.add_theme_constant_override("margin_left", 14)
		detail_margin.add_theme_constant_override("margin_top", 14)
		detail_margin.add_theme_constant_override("margin_right", 14)
		detail_margin.add_theme_constant_override("margin_bottom", 14)
		detail_panel.add_child(detail_margin)
		social_message_detail = VBoxContainer.new()
		social_message_detail.name = "SocialMessageDetail"
		social_message_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_message_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
		social_message_detail.add_theme_constant_override("separation", 12)
		detail_margin.add_child(social_message_detail)
		social_message_header = VBoxContainer.new()
		social_message_header.name = "SocialMessageHeader"
		social_message_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_message_header.add_theme_constant_override("separation", 4)
		social_message_detail.add_child(social_message_header)
		social_message_rows_scroll = ScrollContainer.new()
		social_message_rows_scroll.name = "SocialMessageRowsScroll"
		social_message_rows_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_message_rows_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		social_message_rows_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		social_message_detail.add_child(social_message_rows_scroll)
		social_message_rows = VBoxContainer.new()
		social_message_rows.name = "SocialMessageRows"
		social_message_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_message_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
		social_message_rows.add_theme_constant_override("separation", 8)
		social_message_rows_scroll.add_child(social_message_rows)
		social_message_composer = PanelContainer.new()
		social_message_composer.name = "SocialMessageComposer"
		social_message_composer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_twooter_panel(social_message_composer, COLOR_TWOOTER_CARD, COLOR_TWOOTER_BORDER, 8, 1)
		social_message_detail.add_child(social_message_composer)
		var composer_margin := MarginContainer.new()
		composer_margin.add_theme_constant_override("margin_left", 10)
		composer_margin.add_theme_constant_override("margin_top", 10)
		composer_margin.add_theme_constant_override("margin_right", 10)
		composer_margin.add_theme_constant_override("margin_bottom", 10)
		social_message_composer.add_child(composer_margin)
		var composer_vbox := VBoxContainer.new()
		composer_vbox.name = "SocialMessageComposerVBox"
		composer_vbox.add_theme_constant_override("separation", 8)
		composer_margin.add_child(composer_vbox)
		var composer_text_panel := PanelContainer.new()
		composer_text_panel.name = "SocialMessageComposerTextPanel"
		composer_text_panel.custom_minimum_size = Vector2(0, 58)
		composer_text_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_twooter_panel(composer_text_panel, COLOR_TWOOTER_SURFACE, COLOR_TWOOTER_BORDER, 6, 1)
		composer_vbox.add_child(composer_text_panel)
		var composer_text_margin := MarginContainer.new()
		composer_text_margin.add_theme_constant_override("margin_left", 10)
		composer_text_margin.add_theme_constant_override("margin_top", 8)
		composer_text_margin.add_theme_constant_override("margin_right", 10)
		composer_text_margin.add_theme_constant_override("margin_bottom", 8)
		composer_text_panel.add_child(composer_text_margin)
		social_message_composer_text_label = Label.new()
		social_message_composer_text_label.name = "SocialMessageComposerTextLabel"
		social_message_composer_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		social_message_composer_text_label.add_theme_color_override("font_color", COLOR_TWOOTER_TEXT)
		_apply_font_override_to_control(social_message_composer_text_label, _social_font_size(DEFAULT_APP_FONT_SIZE), _get_app_font())
		composer_text_margin.add_child(social_message_composer_text_label)
		social_message_actions = VBoxContainer.new()
		social_message_actions.name = "SocialMessageComposerOptions"
		social_message_actions.add_theme_constant_override("separation", 8)
		composer_vbox.add_child(social_message_actions)
		social_message_option_buttons.clear()
		for option_index in range(3):
			var option_button := Button.new()
			option_button.name = "SocialMessageDialogOptionButton"
			option_button.custom_minimum_size = Vector2(0, 34)
			option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			option_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			option_button.clip_text = true
			option_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			option_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			_style_social_thread_button(option_button)
			option_button.pressed.connect(_on_social_message_option_selected.bind(option_index))
			social_message_actions.add_child(option_button)
			social_message_option_buttons.append(option_button)
		var composer_action_row := HBoxContainer.new()
		composer_action_row.name = "SocialMessageComposerActionRow"
		composer_action_row.alignment = BoxContainer.ALIGNMENT_END
		composer_vbox.add_child(composer_action_row)
		social_message_send_button = Button.new()
		social_message_send_button.name = "SocialMessageSendButton"
		social_message_send_button.text = "Send | 1 AP"
		social_message_send_button.custom_minimum_size = Vector2(112, 34)
		social_message_send_button.disabled = true
		_style_social_filter_button(social_message_send_button, true, true)
		social_message_send_button.pressed.connect(_send_social_message_composer)
		composer_action_row.add_child(social_message_send_button)

	_style_twooter_ui()
	_sync_root_refs()


func _build_social_left_sidebar() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "SocialLeftSidebar"
	panel.custom_minimum_size = Vector2(190, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_twooter_panel(panel, COLOR_TWOOTER_PAGE, COLOR_TWOOTER_BORDER, 0, 1)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "SocialLeftSidebarVBox"
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var logo := Label.new()
	logo.name = "SocialLogoLabel"
	logo.text = "Twooter"
	logo.add_theme_color_override("font_color", COLOR_TWOOTER_TEXT)
	_apply_font_override_to_control(logo, _social_font_size(DEFAULT_APP_FONT_SIZE + 7), _get_dashboard_title_font())
	vbox.add_child(logo)

	social_left_nav_buttons.clear()
	for row in [
		{"id": "home", "label": "Home"},
		{"id": "message", "label": "Message"}
	]:
		var button := Button.new()
		button.name = "SocialNav%sButton" % str(row.get("id", "")).capitalize()
		button.text = str(row.get("label", ""))
		button.custom_minimum_size = Vector2(0, 42)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_social_nav_pressed.bind(str(row.get("id", ""))))
		vbox.add_child(button)
		social_left_nav_buttons[str(row.get("id", ""))] = button
	return panel


func _build_social_right_rail() -> VBoxContainer:
	var rail := VBoxContainer.new()
	rail.name = "SocialRightRail"
	rail.custom_minimum_size = Vector2(288, 0)
	rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rail.add_theme_constant_override("separation", 18)

	var search_card := _make_social_account_search_card()
	rail.add_child(search_card)

	var trending_card := _make_social_rail_card("SocialTrendingCard", "Trending")
	social_trending_rows = trending_card.find_child("SocialRailRows", true, false) as VBoxContainer
	rail.add_child(trending_card)

	var follow_card := _make_social_rail_card("SocialFollowCard", "Who to follow")
	social_follow_rows = follow_card.find_child("SocialRailRows", true, false) as VBoxContainer
	rail.add_child(follow_card)
	return rail


func _make_social_account_search_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "SocialAccountSearchCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_twooter_panel(card, COLOR_TWOOTER_SURFACE, COLOR_TWOOTER_BORDER, 12, 1)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "SocialAccountSearchVBox"
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	social_account_search_input = LineEdit.new()
	social_account_search_input.name = "SocialAccountSearchInput"
	social_account_search_input.placeholder_text = "Search account names"
	social_account_search_input.clear_button_enabled = true
	social_account_search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_social_search_input(social_account_search_input)
	social_account_search_input.text_changed.connect(_on_social_account_search_changed)
	social_account_search_input.text_submitted.connect(_on_social_account_search_submitted)
	vbox.add_child(social_account_search_input)
	social_account_search_results = VBoxContainer.new()
	social_account_search_results.name = "SocialAccountSearchResults"
	social_account_search_results.add_theme_constant_override("separation", 6)
	social_account_search_results.visible = false
	vbox.add_child(social_account_search_results)
	return card


func _make_social_rail_card(node_name: String, title: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = node_name
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_twooter_panel(card, COLOR_TWOOTER_SURFACE, COLOR_TWOOTER_BORDER, 12, 1)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "SocialRailVBox"
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	var label := Label.new()
	label.name = "SocialRailTitle"
	label.text = title
	label.add_theme_color_override("font_color", COLOR_TWOOTER_TEXT)
	_apply_font_override_to_control(label, _social_font_size(DEFAULT_APP_FONT_SIZE + 6), _get_dashboard_title_font())
	vbox.add_child(label)
	var rows := VBoxContainer.new()
	rows.name = "SocialRailRows"
	rows.add_theme_constant_override("separation", 10)
	vbox.add_child(rows)
	return card

func _style_social_filter_button(button: Button, is_selected: bool, is_unlocked: bool) -> void:
	var fill_color: Color = COLOR_TWOOTER_CARD if is_unlocked else Color(COLOR_TWOOTER_SURFACE.r, COLOR_TWOOTER_SURFACE.g, COLOR_TWOOTER_SURFACE.b, 0.64)
	var border_color: Color = COLOR_TWOOTER_BLUE_EDGE
	var font_color: Color = COLOR_TWOOTER_BLUE if is_unlocked else COLOR_TWOOTER_FAINT
	if is_selected:
		fill_color = COLOR_TWOOTER_BLUE
		border_color = COLOR_TWOOTER_BLUE_DARK
		font_color = COLOR_TWOOTER_PAGE
	UiTheme.style_button(
		button,
		"custom",
		{
			"fill": fill_color,
			"border": border_color,
			"font": font_color,
			"radius": 7,
			"margins": {"left": SOCIAL_ACTION_BUTTON_PAD_X, "top": SOCIAL_ACTION_BUTTON_PAD_Y, "right": SOCIAL_ACTION_BUTTON_PAD_X, "bottom": SOCIAL_ACTION_BUTTON_PAD_Y}
		}
	)
	button.custom_minimum_size = Vector2(button.custom_minimum_size.x, max(button.custom_minimum_size.y, float(SOCIAL_ACTION_BUTTON_MIN_HEIGHT)))
	_apply_font_override_to_control(button, _social_font_size(12), _get_dashboard_title_font())


func _style_social_account_button(button: Button, is_selected: bool) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.border_color = Color(0, 0, 0, 0)
	normal.set_border_width_all(0)
	normal.content_margin_left = 0
	normal.content_margin_right = 0
	normal.content_margin_top = 0
	normal.content_margin_bottom = 0

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(COLOR_TWOOTER_BLUE_TINT.r, COLOR_TWOOTER_BLUE_TINT.g, COLOR_TWOOTER_BLUE_TINT.b, 0.58)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(COLOR_TWOOTER_BLUE_EDGE.r, COLOR_TWOOTER_BLUE_EDGE.g, COLOR_TWOOTER_BLUE_EDGE.b, 0.36)

	var focus: StyleBoxFlat = pressed.duplicate()
	if is_selected:
		normal.bg_color = Color(COLOR_TWOOTER_BLUE_TINT.r, COLOR_TWOOTER_BLUE_TINT.g, COLOR_TWOOTER_BLUE_TINT.b, 0.44)

	var font_color: Color = COLOR_TWOOTER_BLUE
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", COLOR_TWOOTER_BLUE)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	_apply_font_override_to_control(button, _social_font_size(DEFAULT_APP_FONT_SIZE), _get_app_font())

func _sync_dynamic_refs_from_root() -> void:
	if _root == null:
		return
	social_capture_menu = _root.get("social_capture_menu") as PopupMenu
	social_window = _root.get("social_window") as MarginContainer
	social_window_body = _root.get("social_window_body") as PanelContainer
	social_title_label = _root.get("social_title_label") as Label
	social_access_status_label = _root.get("social_access_status_label") as Label
	social_feed_summary_label = _root.get("social_feed_summary_label") as Label
	social_feed_scroll = _root.get("social_feed_scroll") as ScrollContainer
	social_feed_cards = _root.get("social_feed_cards") as VBoxContainer
	social_live_dot = _root.get("social_live_dot") as PanelContainer
	social_live_label = _root.get("social_live_label") as Label
	social_tier_indicator = _root.get("social_tier_indicator") as HBoxContainer
	social_filter_scroll = _root.get("social_filter_scroll") as ScrollContainer
	social_filter_chips = _root.get("social_filter_chips") as HBoxContainer
	social_ticker_tape_panel = _root.get("social_ticker_tape_panel") as PanelContainer
	social_ticker_tape_scroll = _root.get("social_ticker_tape_scroll") as ScrollContainer
	social_ticker_tape = _root.get("social_ticker_tape") as HBoxContainer
	social_app_shell = _root.get("social_app_shell") as HBoxContainer
	social_left_sidebar = _root.get("social_left_sidebar") as PanelContainer
	var nav_buttons = _root.get("social_left_nav_buttons")
	social_left_nav_buttons = nav_buttons if typeof(nav_buttons) == TYPE_DICTIONARY else {}
	social_center_panel = _root.get("social_center_panel") as PanelContainer
	social_right_rail = _root.get("social_right_rail") as VBoxContainer
	social_account_search_input = _root.get("social_account_search_input") as LineEdit
	social_account_search_results = _root.get("social_account_search_results") as VBoxContainer
	social_trending_rows = _root.get("social_trending_rows") as VBoxContainer
	social_follow_rows = _root.get("social_follow_rows") as VBoxContainer
	social_message_view = _root.get("social_message_view") as HBoxContainer
	social_message_thread_scroll = _root.get("social_message_thread_scroll") as ScrollContainer
	social_message_threads = _root.get("social_message_threads") as VBoxContainer
	social_message_detail = _root.get("social_message_detail") as VBoxContainer
	social_message_header = _root.get("social_message_header") as VBoxContainer
	social_message_rows_scroll = _root.get("social_message_rows_scroll") as ScrollContainer
	social_message_rows = _root.get("social_message_rows") as VBoxContainer
	social_message_actions = _root.get("social_message_actions") as VBoxContainer
	social_message_composer = _root.get("social_message_composer") as PanelContainer
	social_message_composer_text_label = _root.get("social_message_composer_text_label") as Label
	var message_buttons = _root.get("social_message_option_buttons")
	var synced_message_buttons: Array[Button] = []
	if typeof(message_buttons) == TYPE_ARRAY:
		for button_value in message_buttons:
			var button := button_value as Button
			if button != null:
				synced_message_buttons.append(button)
	social_message_option_buttons = synced_message_buttons
	social_message_send_button = _root.get("social_message_send_button") as Button
	social_message_typing_tween = _root.get("social_message_typing_tween") as Tween
	social_reply_dialog = _root.get("social_reply_dialog") as Control
	social_reply_context_label = _root.get("social_reply_context_label") as Label
	social_reply_text_label = _root.get("social_reply_text_label") as Label
	var reply_buttons = _root.get("social_reply_option_buttons")
	var synced_reply_buttons: Array[Button] = []
	if typeof(reply_buttons) == TYPE_ARRAY:
		for button_value in reply_buttons:
			var button := button_value as Button
			if button != null:
				synced_reply_buttons.append(button)
	social_reply_option_buttons = synced_reply_buttons
	social_reply_send_button = _root.get("social_reply_send_button") as Button
	social_reply_cancel_button = _root.get("social_reply_cancel_button") as Button
	social_reply_typing_tween = _root.get("social_reply_typing_tween") as Tween
	news_meet_contact_button = _root.get("news_meet_contact_button") as Button


func _sync_state_from_root() -> void:
	# Social state is controller-owned; the shared capture dict is aliased in
	# setup(). Kept as a no-op for GameRoot call-site compat.
	pass


func _sync_root_refs() -> void:
	if _root == null:
		return
	_root.set("social_capture_menu", social_capture_menu)
	_root.set("social_window", social_window)
	_root.set("social_window_body", social_window_body)
	_root.set("social_title_label", social_title_label)
	_root.set("social_access_status_label", social_access_status_label)
	_root.set("social_feed_summary_label", social_feed_summary_label)
	_root.set("social_feed_scroll", social_feed_scroll)
	_root.set("social_feed_cards", social_feed_cards)
	_root.set("social_live_dot", social_live_dot)
	_root.set("social_live_label", social_live_label)
	_root.set("social_tier_indicator", social_tier_indicator)
	_root.set("social_filter_scroll", social_filter_scroll)
	_root.set("social_filter_chips", social_filter_chips)
	_root.set("social_ticker_tape_panel", social_ticker_tape_panel)
	_root.set("social_ticker_tape_scroll", social_ticker_tape_scroll)
	_root.set("social_ticker_tape", social_ticker_tape)
	_root.set("social_app_shell", social_app_shell)
	_root.set("social_left_sidebar", social_left_sidebar)
	_root.set("social_left_nav_buttons", social_left_nav_buttons)
	_root.set("social_center_panel", social_center_panel)
	_root.set("social_right_rail", social_right_rail)
	_root.set("social_account_search_input", social_account_search_input)
	_root.set("social_account_search_results", social_account_search_results)
	_root.set("social_trending_rows", social_trending_rows)
	_root.set("social_follow_rows", social_follow_rows)
	_root.set("social_message_view", social_message_view)
	_root.set("social_message_thread_scroll", social_message_thread_scroll)
	_root.set("social_message_threads", social_message_threads)
	_root.set("social_message_detail", social_message_detail)
	_root.set("social_message_header", social_message_header)
	_root.set("social_message_rows_scroll", social_message_rows_scroll)
	_root.set("social_message_rows", social_message_rows)
	_root.set("social_message_actions", social_message_actions)
	_root.set("social_message_composer", social_message_composer)
	_root.set("social_message_composer_text_label", social_message_composer_text_label)
	_root.set("social_message_option_buttons", social_message_option_buttons)
	_root.set("social_message_send_button", social_message_send_button)
	_root.set("social_message_typing_tween", social_message_typing_tween)
	_root.set("social_reply_dialog", social_reply_dialog)
	_root.set("social_reply_context_label", social_reply_context_label)
	_root.set("social_reply_text_label", social_reply_text_label)
	_root.set("social_reply_option_buttons", social_reply_option_buttons)
	_root.set("social_reply_send_button", social_reply_send_button)
	_root.set("social_reply_cancel_button", social_reply_cancel_button)
	_root.set("social_reply_typing_tween", social_reply_typing_tween)



func add_child(node: Node) -> void:
	if _root != null:
		_root.add_child(node)


func create_tween() -> Tween:
	if _root == null:
		return null
	return _root.create_tween()


func get_viewport_rect() -> Rect2:
	if _root == null:
		return Rect2()
	return _root.get_viewport_rect()


func _style_button(button: Button, fill_color: Color, border_color: Color, font_color: Color, radius: int = 6) -> void:
	if _root != null:
		_root.call("_style_button", button, fill_color, border_color, font_color, radius)


func _set_label_tone(label: Label, color: Color) -> void:
	if _root != null:
		_root.call("_set_label_tone", label, color)


func _apply_font_override_to_control(control: Control, font_size: int, font: Font = null) -> void:
	if _root != null:
		_root.call("_apply_font_override_to_control", control, font_size, font)


func _apply_font_overrides_to_subtree(node: Node) -> void:
	if _root != null:
		_root.call("_apply_font_overrides_to_subtree", node)


func _get_app_font() -> Font:
	if _root == null:
		return null
	return _root.call("_get_app_font") as Font


func _get_dashboard_title_font() -> Font:
	if _root == null:
		return null
	return _root.call("_get_dashboard_title_font") as Font


func _get_company_rows_cached() -> Array:
	if _root == null:
		return []
	return _root.call("_get_company_rows_cached")


func _node_token(value: String) -> String:
	if _root == null:
		return value.strip_edges().to_lower().replace(" ", "_")
	return str(_root.call("_node_token", value))


func _commit_pending_capture(kind: String, id: int) -> void:
	if _root != null:
		_root.call("_commit_pending_capture", kind, id)


func _show_toast(message: String, is_success: bool) -> void:
	if _root != null:
		_root.call("_show_toast", message, is_success)


func _set_active_app(app_id: String) -> void:
	if _root != null:
		_root.call("_set_active_app", app_id)


func _refresh_network() -> void:
	if _root != null:
		_root.call("_refresh_network")


func _mark_guide_research_interaction() -> void:
	if _root != null:
		_root.call("_mark_guide_research_interaction")
