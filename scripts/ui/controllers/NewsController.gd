extends RefCounted

const DEFAULT_APP_FONT_SIZE := 14
const COLOR_WINDOW_TEXT := Color(0.184314, 0.172549, 0.109804, 1)
const COLOR_MARKET_PAPER_PAGE := Color(0.988235, 0.960784, 0.854902, 1)
const COLOR_MARKET_PAPER_CARD := Color(1.0, 0.976471, 0.929412, 1)
const COLOR_MARKET_PAPER_RAIL := Color(0.917647, 0.878431, 0.721569, 1)
const COLOR_MARKET_PAPER_BORDER := Color(0.52549, 0.396078, 0.160784, 1)
const COLOR_MARKET_PAPER_MUTED := Color(0.352941, 0.309804, 0.203922, 1)
const COLOR_MARKET_PAPER_RED := Color(0.545098, 0.101961, 0.101961, 1)
const NEWS_ARTICLE_CARD_LIMIT := 8
const NEWS_ARTICLE_INITIAL_CARD_LIMIT := 3
const NEWS_ARTICLE_CARD_CLICK_DRAG_THRESHOLD := 10.0
const SHOW_NEWS_IMAGE_PLACEHOLDERS := false
const MARKET_PAPER_GRUNGE_TEXTURES := {
	"coffee": "res://assets/market_papers/grunge/coffee_stain.png",
	"fold_horizontal": "res://assets/market_papers/grunge/fold_horizontal.png",
	"fold_vertical": "res://assets/market_papers/grunge/fold_vertical.png",
	"smudge_01": "res://assets/market_papers/grunge/smudge_01.png",
	"smudge_02": "res://assets/market_papers/grunge/smudge_02.png",
	"smudge_03": "res://assets/market_papers/grunge/smudge_03.png",
	"smudge_04": "res://assets/market_papers/grunge/smudge_04.png",
	"stamp_open": "res://assets/market_papers/grunge/stamp_open.png",
	"stamp_trader": "res://assets/market_papers/grunge/stamp_trader_edition.png"
}
const DASHBOARD_MONTH_NAMES := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

var _root = null
var news_capture_menu: PopupMenu = null
var pending_capture_payloads: Dictionary = {}
var current_news_snapshot: Dictionary = {}
var selected_news_outlet_id: String = ""
var selected_news_archive_year: int = 0
var selected_news_archive_month: int = 0
var selected_news_article_id: String = ""
var news_article_cards_generation: int = 0
var news_article_card_press_positions: Dictionary = {}
var news_window: MarginContainer = null
var news_window_body: PanelContainer = null
var news_title_label: Label = null
var news_intel_status_label: Label = null
var news_outlet_buttons: HBoxContainer = null
var news_feed_panel: PanelContainer = null
var news_feed_summary_label: Label = null
var news_archive_year_label: Label = null
var news_archive_year_option: OptionButton = null
var news_archive_month_label: Label = null
var news_archive_month_option: OptionButton = null
var news_article_list: ItemList = null
var news_detail_panel: PanelContainer = null
var news_detail_outlet_label: Label = null
var news_detail_headline_label: Label = null
var news_detail_deck_label: Label = null
var news_detail_meta_label: Label = null
var news_detail_body: RichTextLabel = null
var news_detail_hint_label: Label = null
var news_meet_contact_button: Button = null
var news_masthead_panel: PanelContainer = null
var news_masthead_issue_box: PanelContainer = null
var news_masthead_issue_label: Label = null
var news_masthead_issue_number_label: Label = null
var news_masthead_title_label: Label = null
var news_masthead_tagline_label: Label = null
var news_masthead_date_block_label: Label = null
var news_masthead_date_label: Label = null
var news_masthead_price_label: Label = null
var news_masthead_rule_container: VBoxContainer = null
var news_source_tab_rule: ColorRect = null
var news_article_cards_scroll: ScrollContainer = null
var news_article_cards: VBoxContainer = null
var news_detail_scroll: ScrollContainer = null
var news_detail_scroll_content: VBoxContainer = null
var news_detail_hero_frame: PanelContainer = null
var news_detail_photo_caption_label: Label = null
var news_detail_byline_label: Label = null
var news_detail_chips_label: Label = null
var news_detail_action_row: HBoxContainer = null
var news_open_meeting_button: Button = null
var news_grunge_overlay: Control = null


func setup(root) -> void:
	_root = root
	_sync_dynamic_refs_from_root()
	_sync_state_from_root()
	_sync_root_refs()


func refresh() -> void:
	_sync_dynamic_refs_from_root()
	_sync_state_from_root()
	_refresh_news()
	_sync_root_refs()


func ensure_detail_scroll() -> void:
	_sync_dynamic_refs_from_root()
	_ensure_news_detail_scroll()
	_sync_root_refs()


func ensure_ui() -> void:
	_sync_dynamic_refs_from_root()
	_ensure_news_newspaper_ui()
	_sync_root_refs()


func _refresh_news() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var phase_started_at_usec: int = started_at_usec
	current_news_snapshot = {}
	news_title_label.text = "The Market Papers"
	if not RunState.has_active_run():
		selected_news_outlet_id = ""
		selected_news_archive_year = 0
		selected_news_archive_month = 0
		selected_news_article_id = ""
		_rebuild_news_outlet_buttons([])
		_refresh_news_archive_filters()
		news_intel_status_label.text = ""
		news_feed_summary_label.text = ""
		news_article_list.clear()
		_rebuild_news_article_cards([])
		if news_masthead_date_label != null:
			news_masthead_date_label.text = ""
		if news_masthead_issue_number_label != null:
			news_masthead_issue_number_label.text = "No. 0000"
		_show_news_article({})
		_apply_font_overrides_to_subtree(news_outlet_buttons)
		_log_perf_elapsed("_refresh_news:no_active_run", started_at_usec)
		return

	current_news_snapshot = GameManager.get_news_snapshot()
	_log_perf_phase(true, "_refresh_news:snapshot", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var outlets: Array = current_news_snapshot.get("outlets", [])
	if selected_news_outlet_id.is_empty() or not _news_outlet_exists(outlets, selected_news_outlet_id):
		selected_news_outlet_id = _default_news_outlet_id(outlets)
		selected_news_archive_year = 0
		selected_news_archive_month = 0
		selected_news_article_id = ""

	var current_trade_date: Dictionary = GameManager.get_current_trade_date()
	if news_masthead_date_label != null:
		news_masthead_date_label.text = GameManager.format_trade_date(current_trade_date)
	if news_masthead_issue_number_label != null:
		news_masthead_issue_number_label.text = "No. %04d" % max(RunState.day_index + 1, 1)
	news_intel_status_label.text = ""
	_rebuild_news_outlet_buttons(outlets)
	_log_perf_phase(true, "_refresh_news:outlets", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_refresh_news_archive_filters()
	_log_perf_phase(true, "_refresh_news:archive_filters", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_refresh_news_article_list()
	_log_perf_phase(true, "_refresh_news:article_list", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_apply_font_overrides_to_subtree(news_outlet_buttons)
	_log_perf_phase(true, "_refresh_news:fonts", phase_started_at_usec)
	_log_perf_elapsed("_refresh_news", started_at_usec)
func _rebuild_news_outlet_buttons(outlets: Array) -> void:
	for child in news_outlet_buttons.get_children():
		news_outlet_buttons.remove_child(child)
		child.queue_free()

	for outlet_value in outlets:
		var outlet: Dictionary = outlet_value
		var outlet_id: String = str(outlet.get("id", ""))
		var button: Button = Button.new()
		var unlocked: bool = bool(outlet.get("unlocked", true))
		button.name = "NewsOutletButton_%s" % outlet_id
		button.text = str(outlet.get("label", outlet_id))
		button.toggle_mode = true
		button.disabled = not unlocked
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 36)
		button.tooltip_text = ""
		_style_news_outlet_button(button, outlet_id == selected_news_outlet_id, unlocked)
		button.pressed.connect(_root._on_news_outlet_pressed.bind(outlet_id))
		news_outlet_buttons.add_child(button)
func _refresh_news_archive_filters() -> void:
	news_archive_year_option.clear()
	news_archive_month_option.clear()

	var years: Array = []
	if not selected_news_outlet_id.is_empty():
		years = GameManager.get_news_archive_years(selected_news_outlet_id)

	if years.is_empty():
		selected_news_archive_year = 0
		selected_news_archive_month = 0
		news_archive_year_option.disabled = true
		news_archive_month_option.disabled = true
		return

	news_archive_year_option.disabled = false
	if not years.has(selected_news_archive_year):
		selected_news_archive_year = int(years[0])

	var selected_year_index: int = 0
	for year_index in range(years.size()):
		var year_number: int = int(years[year_index])
		news_archive_year_option.add_item(str(year_number))
		if year_number == selected_news_archive_year:
			selected_year_index = year_index
	news_archive_year_option.select(selected_year_index)
	_refresh_news_archive_month_options()
func _refresh_news_archive_month_options() -> void:
	news_archive_month_option.clear()

	var months: Array = []
	if not selected_news_outlet_id.is_empty() and selected_news_archive_year > 0:
		months = GameManager.get_news_archive_months(selected_news_outlet_id, selected_news_archive_year)

	if months.is_empty():
		selected_news_archive_month = 0
		news_archive_month_option.disabled = true
		return

	news_archive_month_option.disabled = false
	if not months.has(selected_news_archive_month):
		selected_news_archive_month = int(months[0])

	var selected_month_index: int = 0
	for month_index in range(months.size()):
		var month_number: int = int(months[month_index])
		news_archive_month_option.add_item(_news_archive_month_label(month_number))
		if month_number == selected_news_archive_month:
			selected_month_index = month_index
	news_archive_month_option.select(selected_month_index)
func _refresh_news_article_list() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var phase_started_at_usec: int = started_at_usec
	news_article_list.clear()
	var articles: Array = _current_news_archive_article_summaries()
	_log_perf_phase(true, "_refresh_news_article_list:summaries", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var feed: Dictionary = current_news_snapshot.get("feeds", {}).get(selected_news_outlet_id, {})
	var feed_tagline: String = str(feed.get("tagline", "")).strip_edges()
	news_feed_summary_label.text = "ARCHIVE" if feed_tagline.is_empty() else "ARCHIVE  ·  %s" % feed_tagline

	for article_value in articles:
		var article: Dictionary = article_value
		var line: String = _build_news_article_list_line(article)
		news_article_list.add_item(line)
		var item_index: int = news_article_list.item_count - 1
		news_article_list.set_item_tooltip(item_index, "")
		news_article_list.set_item_metadata(item_index, article)
	_log_perf_phase(true, "_refresh_news_article_list:item_list", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()

	var selected_index: int = -1
	for article_index in range(articles.size()):
		if str(articles[article_index].get("id", "")) == selected_news_article_id:
			selected_index = article_index
			break

	if selected_index == -1 and not articles.is_empty():
		selected_index = 0
		selected_news_article_id = str(articles[0].get("id", ""))

	_rebuild_news_article_cards(articles)
	_log_perf_phase(true, "_refresh_news_article_list:cards", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	if selected_index >= 0:
		news_article_list.select(selected_index)
		_show_news_article(GameManager.get_news_archive_article(selected_news_article_id))
	else:
		selected_news_article_id = ""
		_show_news_article({})
	_log_perf_phase(true, "_refresh_news_article_list:show_article", phase_started_at_usec)
	_log_perf_elapsed("_refresh_news_article_list", started_at_usec)
func _show_news_article(article: Dictionary, discover_context: bool = true) -> void:
	if article.is_empty():
		news_detail_outlet_label.text = ""
		news_detail_headline_label.text = "No article selected."
		news_detail_deck_label.text = ""
		news_detail_meta_label.text = ""
		if news_detail_byline_label != null:
			news_detail_byline_label.text = ""
		if news_detail_chips_label != null:
			news_detail_chips_label.text = ""
		if news_detail_photo_caption_label != null:
			news_detail_photo_caption_label.text = ""
		_set_news_detail_hero_slot("")
		news_detail_body.text = "Choose a story from the list."
		news_detail_hint_label.text = ""
		news_detail_hint_label.visible = false
		news_meet_contact_button.visible = false
		news_meet_contact_button.disabled = true
		news_meet_contact_button.set_meta("contact_id", "")
		news_meet_contact_button.set_meta("twooter_account_id", "")
		news_meet_contact_button.set_meta("twooter_handle", "")
		if news_open_meeting_button != null:
			news_open_meeting_button.visible = false
			news_open_meeting_button.disabled = true
			news_open_meeting_button.set_meta("meeting_id", "")
		_reset_news_detail_scroll()
		return

	var trade_date: Dictionary = article.get("trade_date", {})
	var trade_date_text: String = ""
	if not trade_date.is_empty():
		trade_date_text = GameManager.format_trade_date(trade_date)

	news_detail_outlet_label.text = "FROM · %s" % str(article.get("outlet_label", "News")).to_upper()
	news_detail_headline_label.text = str(article.get("headline", ""))
	news_detail_deck_label.text = str(article.get("deck", ""))
	news_detail_meta_label.text = trade_date_text
	if news_detail_byline_label != null:
		news_detail_byline_label.text = _news_byline_text(article)
	if news_detail_chips_label != null:
		news_detail_chips_label.text = _news_article_chip_line(article)
	if news_detail_photo_caption_label != null:
		news_detail_photo_caption_label.text = "Photo: Bursa archive · %s treatment." % _news_image_slot_label(str(article.get("image_slot", "brief"))).to_lower()
	_set_news_detail_hero_slot(str(article.get("image_slot", "brief")))
	news_detail_body.text = str(article.get("body", ""))
	if discover_context:
		call_deferred("_discover_news_article_context_after_show", article.duplicate(true), str(article.get("id", "")))
	var contact: Dictionary = {}
	if not discover_context:
		contact = _contact_for_context("news", str(article.get("id", "")), str(article.get("target_company_id", "")))
	var twooter_account_id: String = str(contact.get("twooter_account_id", ""))
	var twooter_handle: String = str(contact.get("twooter_handle", "")).strip_edges()
	news_meet_contact_button.visible = not contact.is_empty() and not twooter_account_id.is_empty()
	news_meet_contact_button.disabled = contact.is_empty() or twooter_account_id.is_empty()
	news_meet_contact_button.text = "View %s on Twooter" % twooter_handle if not twooter_handle.is_empty() else "View Source on Twooter"
	news_meet_contact_button.tooltip_text = "Open this source's Twooter profile."
	news_meet_contact_button.set_meta("contact_id", str(contact.get("id", "")))
	news_meet_contact_button.set_meta("twooter_account_id", twooter_account_id)
	news_meet_contact_button.set_meta("twooter_handle", twooter_handle)
	if news_open_meeting_button != null:
		var meeting_id: String = str(article.get("meeting_id", ""))
		var meeting_detail: Dictionary = GameManager.get_corporate_meeting_detail(meeting_id) if not meeting_id.is_empty() else {}
		var meeting_blocked_reason: String = _corporate_meeting_open_blocked_reason(meeting_detail)
		news_open_meeting_button.visible = not meeting_id.is_empty()
		news_open_meeting_button.disabled = meeting_id.is_empty() or not meeting_blocked_reason.is_empty()
		news_open_meeting_button.text = "Shareholders Only" if not meeting_blocked_reason.is_empty() else (_news_meeting_action_label(article) if not meeting_id.is_empty() else "View Notice")
		news_open_meeting_button.tooltip_text = meeting_blocked_reason if not meeting_blocked_reason.is_empty() else "Open the linked corporate meeting."
		news_open_meeting_button.set_meta("meeting_id", meeting_id)
	var detail_hints: Array = []
	if not contact.is_empty():
		var handle_label: String = twooter_handle if not twooter_handle.is_empty() else "Twooter handle pending"
		news_detail_hint_label.text = "TWOOTER SOURCE\n%s · %s" % [
			str(contact.get("display_name", "")),
			handle_label
		]
		news_detail_hint_label.visible = true
		detail_hints.append(news_detail_hint_label.text)
	else:
		news_detail_hint_label.text = ""
		news_detail_hint_label.visible = false
	news_detail_hint_label.text = "\n\n".join(detail_hints)
	news_detail_hint_label.visible = not detail_hints.is_empty()
	_reset_news_detail_scroll()
func _discover_news_article_context_after_show(article: Dictionary, article_id: String) -> void:
	if article.is_empty():
		return
	for _frame_index in range(4):
		await get_tree().process_frame
		if selected_news_article_id != article_id:
			return
	var discovered: Array = GameManager.discover_network_contacts_from_article(article)
	if str(article.get("id", "")) != article_id or selected_news_article_id != article_id:
		return
	var contact: Dictionary = _contact_for_context("news", article_id, str(article.get("target_company_id", "")))
	if discovered.is_empty() and contact.is_empty() and not bool(article.get("is_property_development_story", false)) and str(article.get("category", "")) != "property_development":
		return
	_show_news_article(GameManager.get_news_archive_article(selected_news_article_id), false)
func _reset_news_detail_scroll() -> void:
	if news_detail_scroll == null:
		return
	var scroll_bar := news_detail_scroll.get_v_scroll_bar()
	if scroll_bar == null:
		return
	scroll_bar.value = 0.0
func _on_news_headline_gui_input(event: InputEvent) -> void:
	_open_news_capture_menu_from_event(event, "headline")
func _on_news_body_gui_input(event: InputEvent) -> void:
	_open_news_capture_menu_from_event(event, "article")
func _on_news_source_hint_gui_input(event: InputEvent) -> void:
	_open_news_capture_menu_from_event(event, "source")
func _open_news_capture_menu_from_event(event: InputEvent, context: String) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_RIGHT:
		return
	var article: Dictionary = GameManager.get_news_archive_article(selected_news_article_id)
	if article.is_empty():
		return
	pending_capture_payloads["news_article"] = article.duplicate(true)
	_show_news_capture_menu(mouse_event.global_position, context)
	get_viewport().set_input_as_handled()
func _show_news_capture_menu(global_position: Vector2, context: String) -> void:
	if news_capture_menu == null:
		news_capture_menu = PopupMenu.new()
		news_capture_menu.name = "NewsCaptureContextMenu"
		news_capture_menu.id_pressed.connect(_on_news_capture_menu_id_pressed)
		add_child(news_capture_menu)
	news_capture_menu.clear()
	match context:
		"headline":
			news_capture_menu.add_item("Add Headline to Research Tray", 1)
			news_capture_menu.add_item("Add Headline + Article to Research Tray", 3)
		"article":
			news_capture_menu.add_item("Add Article to Research Tray", 2)
			news_capture_menu.add_item("Add Headline + Article to Research Tray", 3)
		"source":
			news_capture_menu.add_item("Add Source Lead to Research Tray", 4)
		_:
			news_capture_menu.add_item("Add Headline to Research Tray", 1)
			news_capture_menu.add_item("Add Article to Research Tray", 2)
			news_capture_menu.add_item("Add Source Lead to Research Tray", 4)
	news_capture_menu.position = Vector2i(int(global_position.x), int(global_position.y))
	news_capture_menu.popup()
func _on_news_capture_menu_id_pressed(id: int) -> void:
	var pending_article: Dictionary = pending_capture_payloads.get("news_article", {})
	if pending_article.is_empty():
		return
	var kind: String = ""
	match id:
		1:
			kind = "headline"
		2:
			kind = "article"
		3:
			kind = "headline_article"
		4:
			kind = "source_lead"
		_:
			return
	var payload: Dictionary = _build_news_capture_payload(pending_article, kind)
	pending_capture_payloads.erase("news_article")
	if payload.is_empty():
		_show_toast("Nothing to capture from this article.", false)
		return
	var result: Dictionary = GameManager.capture_research_evidence(payload)
	_show_toast(str(result.get("message", "Research capture updated.")), bool(result.get("success", false)))
func _build_news_capture_payload(article: Dictionary, kind: String) -> Dictionary:
	var article_id: String = str(article.get("id", selected_news_article_id)).strip_edges()
	var headline: String = str(article.get("headline", "News article")).strip_edges()
	var deck: String = str(article.get("deck", "")).strip_edges()
	var body: String = str(article.get("body", "")).strip_edges()
	var target_company_id: String = str(article.get("target_company_id", "")).strip_edges()
	var target_ticker: String = str(article.get("target_ticker", "")).strip_edges()
	var source_id: String = "news_%s_%s" % [kind, _node_token(article_id)]
	var impact: String = _impact_from_news_article(article)
	var source_label: String = str(article.get("outlet_label", "News")).strip_edges()
	if source_label.is_empty():
		source_label = "News"
	match kind:
		"headline":
			return {
				"source_type": "news_article",
				"category": "news",
				"category_label": "News",
				"source_label": "%s Headline" % source_label,
				"source_id": source_id,
				"company_id": target_company_id,
				"label": "Headline: %s" % headline,
				"value": headline,
				"detail": deck if not deck.is_empty() else _news_article_status_line(article),
				"impact": impact
			}
		"article":
			return {
				"source_type": "news_article",
				"category": "news",
				"category_label": "News",
				"source_label": "%s Article" % source_label,
				"source_id": source_id,
				"company_id": target_company_id,
				"label": "Article: %s" % headline,
				"value": deck if not deck.is_empty() else headline,
				"detail": _news_capture_excerpt(body),
				"impact": impact
			}
		"headline_article":
			var combined_detail: String = deck
			var body_excerpt: String = _news_capture_excerpt(body)
			if not body_excerpt.is_empty():
				combined_detail = "%s %s" % [combined_detail, body_excerpt] if not combined_detail.is_empty() else body_excerpt
			return {
				"source_type": "news_article",
				"category": "news",
				"category_label": "News",
				"source_label": "%s Headline + Article" % source_label,
				"source_id": source_id,
				"company_id": target_company_id,
				"ticker": target_ticker,
				"label": "Headline + article: %s" % headline,
				"value": headline,
				"detail": combined_detail,
				"impact": impact
			}
		"source_lead":
			var contact: Dictionary = _contact_for_context("news", article_id, target_company_id)
			var handle: String = str(contact.get("twooter_handle", "")).strip_edges()
			var display_name: String = str(contact.get("display_name", "")).strip_edges()
			if display_name.is_empty():
				display_name = str(article.get("author_name", "News source")).strip_edges()
			if display_name.is_empty():
				display_name = "News source"
			var value_text: String = handle if not handle.is_empty() else _news_byline_text(article)
			return {
				"source_type": "network_journal",
				"category": "network_intel",
				"category_label": "Network Intel",
				"source_label": "News Source Lead",
				"source_id": source_id,
				"company_id": target_company_id,
				"ticker": target_ticker,
				"label": "Source lead: %s" % display_name,
				"value": value_text,
				"detail": "This source is connected to the article \"%s\"." % headline,
				"impact": "mixed"
			}
	return {}
func _news_capture_excerpt(body: String) -> String:
	var text: String = body.strip_edges().replace("\n", " ")
	while text.find("  ") != -1:
		text = text.replace("  ", " ")
	if text.length() > 280:
		text = "%s..." % text.left(277).strip_edges()
	return text
func _impact_from_news_article(article: Dictionary) -> String:
	var tone: String = str(article.get("tone", article.get("public_status_label", ""))).to_lower()
	if tone.find("positive") != -1 or tone.find("bull") != -1 or tone.find("constructive") != -1 or tone.find("tailwind") != -1:
		return "positive"
	if tone.find("negative") != -1 or tone.find("bear") != -1 or tone.find("risk") != -1 or tone.find("headwind") != -1:
		return "negative"
	return "mixed"
func _current_news_archive_article_summaries() -> Array:
	if selected_news_outlet_id.is_empty() or selected_news_archive_year <= 0 or selected_news_archive_month <= 0:
		return []
	return GameManager.get_news_archive_article_summaries(
		selected_news_outlet_id,
		selected_news_archive_year,
		selected_news_archive_month
	)
func _build_news_article_list_line(article: Dictionary) -> String:
	return str(article.get("headline", ""))
func _news_byline_text(article: Dictionary) -> String:
	var author_name: String = str(article.get("author_name", "News Desk"))
	var author_role: String = str(article.get("author_role", "Reporter"))
	if author_name.is_empty():
		author_name = "News Desk"
	if author_role.is_empty():
		return "By %s" % author_name
	return "By %s, %s" % [author_name, author_role]
func _news_article_status_line(article: Dictionary) -> String:
	var parts: Array = []
	var section_label: String = str(article.get("public_section_label", ""))
	var status_label: String = str(article.get("public_status_label", ""))
	if not section_label.is_empty():
		parts.append(section_label)
	if not status_label.is_empty():
		parts.append(status_label)
	var trade_date: Dictionary = article.get("trade_date", {})
	if not trade_date.is_empty():
		parts.append(GameManager.format_trade_date(trade_date))
	return "  ·  ".join(parts)
func _news_article_chip_line(article: Dictionary) -> String:
	var chips: Array = []
	var section_label: String = str(article.get("public_section_label", ""))
	var status_label: String = str(article.get("public_status_label", ""))
	var target_ticker: String = str(article.get("target_ticker", ""))
	if not section_label.is_empty():
		chips.append(section_label)
	if not status_label.is_empty():
		chips.append(status_label)
	if not target_ticker.is_empty():
		chips.append(target_ticker)
	return "  ·  ".join(chips)
func _news_image_slot_label(image_slot: String) -> String:
	match image_slot:
		"boardroom":
			return "BOARDROOM IMAGE"
		"market":
			return "MARKET PHOTO"
		"company":
			return "COMPANY IMAGE"
		_:
			return "ARTICLE IMAGE"
func _set_news_detail_hero_slot(image_slot: String) -> void:
	if news_detail_hero_frame == null:
		return
	news_detail_hero_frame.visible = SHOW_NEWS_IMAGE_PLACEHOLDERS
	if news_detail_photo_caption_label != null:
		news_detail_photo_caption_label.visible = SHOW_NEWS_IMAGE_PLACEHOLDERS
	if not SHOW_NEWS_IMAGE_PLACEHOLDERS:
		return
	var placeholder: Label = news_detail_hero_frame.get_node_or_null("NewsDetailHeroPlaceholder") as Label
	if placeholder != null:
		placeholder.text = _news_image_slot_label(image_slot)
func _news_meeting_action_label(article: Dictionary) -> String:
	var venue_type: String = str(article.get("venue_type", ""))
	if venue_type == "rupslb":
		return "Attend RUPSLB"
	if venue_type == "annual_rups":
		return "View Meeting Notice"
	if venue_type == "earnings_call":
		return "Read Call Notice"
	return "View Meeting Notice"
func _corporate_meeting_open_blocked_reason(detail: Dictionary) -> String:
	if detail.is_empty():
		return "Meeting not found."
	if (
		bool(detail.get("interactive_v1", false)) and
		bool(detail.get("requires_shareholder", false)) and
		not bool(detail.get("attendance_eligible", true))
	):
		return str(detail.get("attendance_blocked_reason", "Shareholder ownership is required to attend this meeting."))
	return ""
func _rebuild_news_article_cards(articles: Array, reset_scroll: bool = true) -> void:
	if news_article_cards == null:
		return
	news_article_cards_generation += 1
	news_article_card_press_positions.clear()
	var generation: int = news_article_cards_generation
	var previous_scroll_value: float = 0.0
	if news_article_cards_scroll != null and news_article_cards_scroll.get_v_scroll_bar() != null:
		previous_scroll_value = news_article_cards_scroll.get_v_scroll_bar().value
	for child in news_article_cards.get_children():
		news_article_cards.remove_child(child)
		child.queue_free()
	if articles.is_empty():
		var empty_label := Label.new()
		empty_label.name = "NewsArticleCardsEmptyLabel"
		empty_label.text = "No stories filed for this issue yet."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		news_article_cards.add_child(empty_label)
		return
	var card_articles: Array = _news_article_cards_visible_rows(articles)
	var immediate_count: int = card_articles.size()
	if reset_scroll and card_articles.size() > NEWS_ARTICLE_INITIAL_CARD_LIMIT:
		immediate_count = NEWS_ARTICLE_INITIAL_CARD_LIMIT
	for article_index in range(immediate_count):
		var article_value = card_articles[article_index]
		var article: Dictionary = article_value
		news_article_cards.add_child(_build_news_article_card(article))
	if immediate_count < card_articles.size():
		var remaining_articles: Array = card_articles.slice(immediate_count, card_articles.size())
		call_deferred("_finish_news_article_cards_rebuild", generation, remaining_articles)
	if news_article_cards_scroll != null and news_article_cards_scroll.get_v_scroll_bar() != null:
		var next_scroll_value: float = 0.0 if reset_scroll else previous_scroll_value
		news_article_cards_scroll.get_v_scroll_bar().value = next_scroll_value
		if not reset_scroll:
			call_deferred("_restore_news_article_cards_scroll", next_scroll_value)
func _finish_news_article_cards_rebuild(generation: int, remaining_articles: Array) -> void:
	for _frame_index in range(4):
		await get_tree().process_frame
		if generation != news_article_cards_generation:
			return
	if news_article_cards == null or generation != news_article_cards_generation:
		return
	for article_value in remaining_articles:
		if typeof(article_value) != TYPE_DICTIONARY:
			continue
		var article: Dictionary = article_value
		news_article_cards.add_child(_build_news_article_card(article))
func _news_article_cards_visible_rows(articles: Array) -> Array:
	if articles.size() <= NEWS_ARTICLE_CARD_LIMIT:
		return articles
	var rows: Array = articles.slice(0, NEWS_ARTICLE_CARD_LIMIT)
	if selected_news_article_id.is_empty():
		return rows
	for article_value in rows:
		if typeof(article_value) == TYPE_DICTIONARY and str(article_value.get("id", "")) == selected_news_article_id:
			return rows
	for article_value in articles:
		if typeof(article_value) == TYPE_DICTIONARY and str(article_value.get("id", "")) == selected_news_article_id:
			rows.append(article_value)
			return rows
	return rows
func _restore_news_article_cards_scroll(scroll_value: float) -> void:
	if news_article_cards_scroll == null:
		return
	var scroll_bar := news_article_cards_scroll.get_v_scroll_bar()
	if scroll_bar == null:
		return
	scroll_bar.value = clamp(scroll_value, scroll_bar.min_value, scroll_bar.max_value)
func _build_news_article_card(article: Dictionary) -> PanelContainer:
	var article_id: String = str(article.get("id", ""))
	var is_selected: bool = article_id == selected_news_article_id
	var card := PanelContainer.new()
	card.name = "NewsArticleCard_%s" % article_id.replace("|", "_")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_news_article_card(card, is_selected)

	var margin := MarginContainer.new()
	margin.name = "NewsArticleCardMargin"
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 9)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "NewsArticleCardVBox"
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	var stamp_slot := Control.new()
	stamp_slot.name = "NewsArticleCardStampSlot"
	stamp_slot.custom_minimum_size = Vector2(0, 24)
	stamp_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(stamp_slot)
	if is_selected:
		var stamp_rect := TextureRect.new()
		stamp_rect.name = "NewsArticleCardOpenStamp"
		stamp_rect.texture = _market_paper_texture("stamp_open")
		stamp_rect.custom_minimum_size = Vector2(110, 28)
		stamp_rect.size = Vector2(110, 28)
		stamp_rect.position = Vector2(-4, 0)
		stamp_rect.modulate = Color(1, 1, 1, 0.88)
		stamp_rect.rotation_degrees = -7.0
		stamp_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stamp_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stamp_slot.add_child(stamp_rect)

	var inner_panel := PanelContainer.new()
	inner_panel.name = "NewsArticleCardInnerPanel"
	inner_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_news_inner_panel(inner_panel, COLOR_MARKET_PAPER_CARD)
	vbox.add_child(inner_panel)

	var inner_margin := MarginContainer.new()
	inner_margin.name = "NewsArticleCardInnerMargin"
	inner_margin.add_theme_constant_override("margin_left", 9)
	inner_margin.add_theme_constant_override("margin_top", 9)
	inner_margin.add_theme_constant_override("margin_right", 9)
	inner_margin.add_theme_constant_override("margin_bottom", 9)
	inner_panel.add_child(inner_margin)

	var inner_vbox := VBoxContainer.new()
	inner_vbox.name = "NewsArticleCardInnerVBox"
	inner_vbox.add_theme_constant_override("separation", 8)
	inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_margin.add_child(inner_vbox)

	var top_row := HBoxContainer.new()
	top_row.name = "NewsArticleCardTopRow"
	top_row.add_theme_constant_override("separation", 10)
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_vbox.add_child(top_row)

	var image_frame := PanelContainer.new()
	image_frame.name = "NewsArticleCardImageFrame"
	image_frame.custom_minimum_size = Vector2(112, 82)
	image_frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	image_frame.visible = SHOW_NEWS_IMAGE_PLACEHOLDERS
	_style_news_asset_frame(image_frame)
	top_row.add_child(image_frame)
	var image_label := Label.new()
	image_label.name = "NewsArticleCardImagePlaceholder"
	image_label.text = _news_image_slot_label(str(article.get("image_slot", "brief")))
	image_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	image_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_set_label_tone(image_label, Color(0.454902, 0.337255, 0.141176, 1))
	_apply_font_override_to_control(image_label, 10, _get_app_font())
	image_frame.add_child(image_label)

	var text_vbox := VBoxContainer.new()
	text_vbox.name = "NewsArticleCardTextVBox"
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 5)
	top_row.add_child(text_vbox)

	var status_label := Label.new()
	status_label.name = "NewsArticleCardStatusLabel"
	status_label.text = _news_article_status_line(article).to_upper()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_tone(status_label, COLOR_MARKET_PAPER_RED)
	_apply_font_override_to_control(status_label, 11, _get_dashboard_title_font())
	text_vbox.add_child(status_label)

	var headline_label := Label.new()
	headline_label.name = "NewsArticleCardHeadlineLabel"
	headline_label.text = str(article.get("headline", ""))
	headline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font_override_to_control(headline_label, 15, _get_dashboard_title_font())
	_set_label_tone(headline_label, COLOR_WINDOW_TEXT)
	text_vbox.add_child(headline_label)

	var deck_label := Label.new()
	deck_label.name = "NewsArticleCardDeckLabel"
	deck_label.text = str(article.get("deck", ""))
	deck_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_tone(deck_label, Color(0.352941, 0.309804, 0.203922, 1))
	inner_vbox.add_child(deck_label)

	var byline_rule := ColorRect.new()
	byline_rule.name = "NewsArticleCardBylineRule"
	byline_rule.color = Color(COLOR_MARKET_PAPER_BORDER.r, COLOR_MARKET_PAPER_BORDER.g, COLOR_MARKET_PAPER_BORDER.b, 0.55)
	byline_rule.custom_minimum_size = Vector2(0, 1)
	inner_vbox.add_child(byline_rule)

	var byline_label := Label.new()
	byline_label.name = "NewsArticleCardBylineLabel"
	byline_label.text = _news_byline_text(article)
	byline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_tone(byline_label, Color(0.454902, 0.337255, 0.141176, 1))
	inner_vbox.add_child(byline_label)

	var read_button := Button.new()
	read_button.name = "NewsArticleCardReadButton"
	read_button.text = "READ STORY"
	read_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	read_button.pressed.connect(_root._on_news_article_card_pressed.bind(article_id))
	_style_news_command_button(read_button, is_selected)
	vbox.add_child(read_button)
	_make_news_article_card_clickable(card, article_id)
	return card
func _make_news_article_card_clickable(root: Control, article_id: String) -> void:
	if root == null or article_id.is_empty():
		return
	var stack: Array = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if not (node is Control):
			continue
		var control: Control = node as Control
		if control is BaseButton:
			continue
		control.mouse_filter = Control.MOUSE_FILTER_PASS
		control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		control.tooltip_text = "Read story."
		control.gui_input.connect(_root._on_news_article_card_gui_input.bind(article_id))
		for child in control.get_children():
			stack.append(child)
func _on_news_article_card_gui_input(event: InputEvent, article_id: String) -> void:
	if article_id.is_empty() or not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		news_article_card_press_positions[article_id] = mouse_event.position
		return
	var start_position: Vector2 = mouse_event.position
	var stored_position: Variant = news_article_card_press_positions.get(article_id)
	if stored_position is Vector2:
		start_position = stored_position
	news_article_card_press_positions.erase(article_id)
	if start_position.distance_to(mouse_event.position) > NEWS_ARTICLE_CARD_CLICK_DRAG_THRESHOLD:
		return
	_on_news_article_card_pressed(article_id)
	get_viewport().set_input_as_handled()
func _news_article_card_node(article_id: String) -> PanelContainer:
	if news_article_cards == null or article_id.is_empty():
		return null
	var node_name: String = "NewsArticleCard_%s" % article_id.replace("|", "_")
	return news_article_cards.get_node_or_null(node_name) as PanelContainer
func _news_article_card_exists(article_id: String) -> bool:
	return _news_article_card_node(article_id) != null
func _restyle_news_article_cards(previous_article_id: String, next_article_id: String) -> void:
	for article_id in [previous_article_id, next_article_id]:
		var card: PanelContainer = _news_article_card_node(str(article_id))
		if card == null:
			continue
		var is_selected: bool = str(article_id) == next_article_id
		_style_news_article_card(card, is_selected)
		var read_button: Button = card.find_child("NewsArticleCardReadButton", true, false) as Button
		if read_button != null:
			_style_news_command_button(read_button, is_selected)
		var stamp_slot: Control = card.find_child("NewsArticleCardStampSlot", true, false) as Control
		if stamp_slot == null:
			continue
		for child in stamp_slot.get_children():
			stamp_slot.remove_child(child)
			child.queue_free()
		if is_selected:
			var stamp_rect := TextureRect.new()
			stamp_rect.name = "NewsArticleCardOpenStamp"
			stamp_rect.texture = _market_paper_texture("stamp_open")
			stamp_rect.custom_minimum_size = Vector2(110, 28)
			stamp_rect.size = Vector2(110, 28)
			stamp_rect.position = Vector2(-4, 0)
			stamp_rect.modulate = Color(1, 1, 1, 0.88)
			stamp_rect.rotation_degrees = -7.0
			stamp_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			stamp_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			stamp_slot.add_child(stamp_rect)
func _on_news_article_card_pressed(article_id: String) -> void:
	if article_id.is_empty():
		return
	var previous_article_id: String = selected_news_article_id
	selected_news_article_id = article_id
	var articles: Array = _current_news_archive_article_summaries()
	for article_index in range(articles.size()):
		if str(articles[article_index].get("id", "")) == article_id:
			news_article_list.select(article_index)
			break
	if _news_article_card_exists(article_id):
		_restyle_news_article_cards(previous_article_id, article_id)
	else:
		_rebuild_news_article_cards(articles, false)
	_show_news_article(GameManager.get_news_archive_article(selected_news_article_id))
	_record_steam_news_article_read(selected_news_article_id)
	_mark_guide_research_interaction()
func _ticker_for_company(company_id: String) -> String:
	if company_id.is_empty():
		return "-"
	var snapshot: Dictionary = GameManager.get_company_snapshot(company_id)
	return str(snapshot.get("ticker", company_id.to_upper()))
func _news_archive_month_label(month_number: int) -> String:
	return DASHBOARD_MONTH_NAMES[clamp(month_number - 1, 0, DASHBOARD_MONTH_NAMES.size() - 1)]
func _news_color_for_tone(tone: String) -> Color:
	if tone == "positive":
		return Color(0.156863, 0.364706, 0.247059, 1)
	if tone == "negative":
		return Color(0.494118, 0.184314, 0.184314, 1)
	return Color(0.301961, 0.247059, 0.121569, 1)
func _default_news_outlet_id(outlets: Array) -> String:
	for outlet_value in outlets:
		var outlet: Dictionary = outlet_value
		if bool(outlet.get("unlocked", true)):
			return str(outlet.get("id", ""))
	return ""
func _news_outlet_exists(outlets: Array, outlet_id: String) -> bool:
	for outlet_value in outlets:
		var outlet: Dictionary = outlet_value
		if str(outlet.get("id", "")) == outlet_id:
			return true
	return false
func _on_news_outlet_pressed(outlet_id: String) -> void:
	selected_news_outlet_id = outlet_id
	selected_news_archive_year = 0
	selected_news_archive_month = 0
	selected_news_article_id = ""
	_rebuild_news_outlet_buttons(current_news_snapshot.get("outlets", []))
	_refresh_news_archive_filters()
	_refresh_news_article_list()
func _on_news_article_selected(index: int) -> void:
	var articles: Array = _current_news_archive_article_summaries()
	if index < 0 or index >= articles.size():
		return
	var previous_article_id: String = selected_news_article_id
	selected_news_article_id = str(articles[index].get("id", ""))
	if _news_article_card_exists(selected_news_article_id):
		_restyle_news_article_cards(previous_article_id, selected_news_article_id)
	else:
		_rebuild_news_article_cards(articles, false)
	_show_news_article(GameManager.get_news_archive_article(selected_news_article_id))
	_record_steam_news_article_read(selected_news_article_id)
	_mark_guide_research_interaction()
func _on_news_meet_contact_pressed() -> void:
	var contact_id: String = str(news_meet_contact_button.get_meta("contact_id", ""))
	var account_id: String = str(news_meet_contact_button.get_meta("twooter_account_id", ""))
	_open_social_account_from_news(account_id, contact_id)
	_mark_guide_research_interaction()
func _on_news_open_meeting_pressed() -> void:
	if news_open_meeting_button == null:
		return
	_open_corporate_meeting_modal(str(news_open_meeting_button.get_meta("meeting_id", "")))
	_mark_guide_research_interaction()
func _on_news_archive_year_selected(index: int) -> void:
	if index < 0 or index >= news_archive_year_option.item_count:
		return
	selected_news_archive_year = int(news_archive_year_option.get_item_text(index))
	selected_news_archive_month = 0
	selected_news_article_id = ""
	_refresh_news_archive_month_options()
	_refresh_news_article_list()
func _on_news_archive_month_selected(index: int) -> void:
	if index < 0 or index >= news_archive_month_option.item_count:
		return
	selected_news_archive_month = clamp(index + 1, 1, 12)
	var months: Array = GameManager.get_news_archive_months(selected_news_outlet_id, selected_news_archive_year)
	if index < months.size():
		selected_news_archive_month = int(months[index])
	selected_news_article_id = ""
	_refresh_news_article_list()
func _ensure_news_detail_scroll() -> void:
	if news_detail_scroll_content != null and news_detail_body.get_parent() == news_detail_scroll_content:
		return
	var detail_vbox: VBoxContainer = news_detail_headline_label.get_parent() as VBoxContainer
	if detail_vbox == null:
		return

	news_detail_scroll = ScrollContainer.new()
	news_detail_scroll.name = "NewsDetailScroll"
	news_detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	news_detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	news_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	news_detail_scroll.follow_focus = true
	detail_vbox.add_child(news_detail_scroll)
	detail_vbox.move_child(news_detail_scroll, 0)

	news_detail_scroll_content = VBoxContainer.new()
	news_detail_scroll_content.name = "NewsDetailScrollContent"
	news_detail_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	news_detail_scroll_content.add_theme_constant_override("separation", 9)
	news_detail_scroll.add_child(news_detail_scroll_content)

	var children_to_move: Array = []
	for child_value in detail_vbox.get_children():
		var child: Node = child_value
		if child == news_detail_scroll:
			continue
		children_to_move.append(child)
	for child_value in children_to_move:
		var child: Node = child_value
		detail_vbox.remove_child(child)
		news_detail_scroll_content.add_child(child)

	news_detail_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	news_detail_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	news_detail_body.custom_minimum_size = Vector2.ZERO
	news_detail_body.fit_content = true
	news_detail_body.scroll_active = false
	news_detail_body.scroll_following = false
func _ensure_news_newspaper_ui() -> void:
	news_title_label.text = "The Market Papers"
	news_intel_status_label.visible = false
	news_feed_summary_label.visible = true
	news_feed_summary_label.text = "Select a publication and story."
	news_detail_deck_label.visible = true
	news_detail_hint_label.visible = false
	news_article_list.visible = false
	news_article_list.custom_minimum_size = Vector2.ZERO

	var header_row: HBoxContainer = news_title_label.get_parent()
	header_row.visible = false

	var window_vbox: VBoxContainer = news_outlet_buttons.get_parent()
	if news_masthead_panel == null:
		news_masthead_panel = PanelContainer.new()
		news_masthead_panel.name = "NewsMastheadPanel"
		news_masthead_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		window_vbox.add_child(news_masthead_panel)
		window_vbox.move_child(news_masthead_panel, window_vbox.get_children().find(news_outlet_buttons))

		var masthead_margin := MarginContainer.new()
		masthead_margin.name = "NewsMastheadMargin"
		masthead_margin.add_theme_constant_override("margin_left", 14)
		masthead_margin.add_theme_constant_override("margin_top", 10)
		masthead_margin.add_theme_constant_override("margin_right", 14)
		masthead_margin.add_theme_constant_override("margin_bottom", 10)
		news_masthead_panel.add_child(masthead_margin)

		var masthead_row := HBoxContainer.new()
		masthead_row.name = "NewsMastheadRow"
		masthead_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		masthead_row.add_theme_constant_override("separation", 16)
		masthead_margin.add_child(masthead_row)

		news_masthead_issue_box = PanelContainer.new()
		news_masthead_issue_box.name = "NewsMastheadIssueBox"
		news_masthead_issue_box.custom_minimum_size = Vector2(118, 58)
		news_masthead_issue_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		masthead_row.add_child(news_masthead_issue_box)

		var issue_vbox := VBoxContainer.new()
		issue_vbox.name = "NewsMastheadIssueVBox"
		issue_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		issue_vbox.add_theme_constant_override("separation", 2)
		news_masthead_issue_box.add_child(issue_vbox)
		news_masthead_issue_label = Label.new()
		news_masthead_issue_label.name = "NewsMastheadIssueLabel"
		news_masthead_issue_label.text = "ISSUE"
		news_masthead_issue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		issue_vbox.add_child(news_masthead_issue_label)
		news_masthead_issue_number_label = Label.new()
		news_masthead_issue_number_label.name = "NewsMastheadIssueNumberLabel"
		news_masthead_issue_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		issue_vbox.add_child(news_masthead_issue_number_label)

		var title_block := VBoxContainer.new()
		title_block.name = "NewsMastheadTitleBlock"
		title_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_block.alignment = BoxContainer.ALIGNMENT_CENTER
		title_block.add_theme_constant_override("separation", 3)
		masthead_row.add_child(title_block)
		news_masthead_title_label = Label.new()
		news_masthead_title_label.name = "NewsMastheadTitleLabel"
		news_masthead_title_label.text = "The Market Papers"
		news_masthead_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		news_masthead_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_block.add_child(news_masthead_title_label)
		news_masthead_tagline_label = Label.new()
		news_masthead_tagline_label.name = "NewsMastheadTaglineLabel"
		news_masthead_tagline_label.text = "DAILY CAPITAL MARKETS JOURNAL"
		news_masthead_tagline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_block.add_child(news_masthead_tagline_label)

		var date_block := VBoxContainer.new()
		date_block.name = "NewsMastheadDateBlock"
		date_block.custom_minimum_size = Vector2(160, 58)
		date_block.alignment = BoxContainer.ALIGNMENT_CENTER
		date_block.add_theme_constant_override("separation", 2)
		masthead_row.add_child(date_block)
		news_masthead_date_block_label = Label.new()
		news_masthead_date_block_label.name = "NewsMastheadDateBlockLabel"
		news_masthead_date_block_label.text = "TODAY'S EDITION"
		news_masthead_date_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		date_block.add_child(news_masthead_date_block_label)
		news_masthead_date_label = Label.new()
		news_masthead_date_label.name = "NewsMastheadDateLabel"
		news_masthead_date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		date_block.add_child(news_masthead_date_label)
		news_masthead_price_label = Label.new()
		news_masthead_price_label.name = "NewsMastheadPriceLabel"
		news_masthead_price_label.text = "Cover price · Rp 5.000"
		news_masthead_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		date_block.add_child(news_masthead_price_label)

	if news_masthead_rule_container == null:
		news_masthead_rule_container = VBoxContainer.new()
		news_masthead_rule_container.name = "NewsMastheadRule"
		news_masthead_rule_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		news_masthead_rule_container.add_theme_constant_override("separation", 3)
		window_vbox.add_child(news_masthead_rule_container)
		window_vbox.move_child(news_masthead_rule_container, window_vbox.get_children().find(news_outlet_buttons))
		var rule_top := ColorRect.new()
		rule_top.name = "NewsMastheadRuleTop"
		rule_top.custom_minimum_size = Vector2(0, 3)
		news_masthead_rule_container.add_child(rule_top)
		var rule_bottom := ColorRect.new()
		rule_bottom.name = "NewsMastheadRuleBottom"
		rule_bottom.custom_minimum_size = Vector2(0, 1)
		news_masthead_rule_container.add_child(rule_bottom)

	if news_source_tab_rule == null:
		news_source_tab_rule = ColorRect.new()
		news_source_tab_rule.name = "NewsSourceTabRule"
		news_source_tab_rule.custom_minimum_size = Vector2(0, 1)
		window_vbox.add_child(news_source_tab_rule)
		window_vbox.move_child(news_source_tab_rule, window_vbox.get_children().find(news_outlet_buttons) + 1)

	_ensure_news_grunge_overlay()

	var feed_vbox: VBoxContainer = news_article_list.get_parent()
	if news_article_cards_scroll == null:
		news_article_cards_scroll = ScrollContainer.new()
		news_article_cards_scroll.name = "NewsArticleCardsScroll"
		news_article_cards_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		news_article_cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		news_article_cards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		feed_vbox.add_child(news_article_cards_scroll)
		feed_vbox.move_child(news_article_cards_scroll, feed_vbox.get_children().find(news_article_list))
		news_article_cards = VBoxContainer.new()
		news_article_cards.name = "NewsArticleCards"
		news_article_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		news_article_cards.add_theme_constant_override("separation", 14)
		news_article_cards_scroll.add_child(news_article_cards)

	var detail_vbox: VBoxContainer = news_detail_headline_label.get_parent()
	if news_detail_hero_frame == null:
		news_detail_hero_frame = PanelContainer.new()
		news_detail_hero_frame.name = "NewsDetailHeroFrame"
		news_detail_hero_frame.custom_minimum_size = Vector2(0, 138)
		news_detail_hero_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		news_detail_hero_frame.visible = SHOW_NEWS_IMAGE_PLACEHOLDERS
		detail_vbox.add_child(news_detail_hero_frame)
		var hero_label := Label.new()
		hero_label.name = "NewsDetailHeroPlaceholder"
		hero_label.text = "IMAGE SLOT"
		hero_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hero_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		news_detail_hero_frame.add_child(hero_label)
	if news_detail_photo_caption_label == null:
		news_detail_photo_caption_label = Label.new()
		news_detail_photo_caption_label.name = "NewsDetailPhotoCaptionLabel"
		news_detail_photo_caption_label.visible = SHOW_NEWS_IMAGE_PLACEHOLDERS
		news_detail_photo_caption_label.text = "Photo: Bursa archive · trading floor activity."
		news_detail_photo_caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_vbox.add_child(news_detail_photo_caption_label)
	if news_detail_byline_label == null:
		news_detail_byline_label = Label.new()
		news_detail_byline_label.name = "NewsDetailBylineLabel"
		news_detail_byline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_vbox.add_child(news_detail_byline_label)
	if news_detail_chips_label == null:
		news_detail_chips_label = Label.new()
		news_detail_chips_label.name = "NewsDetailChipsLabel"
		news_detail_chips_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_vbox.add_child(news_detail_chips_label)
	if news_detail_action_row == null:
		news_detail_action_row = HBoxContainer.new()
		news_detail_action_row.name = "NewsDetailActionRow"
		news_detail_action_row.add_theme_constant_override("separation", 10)
		detail_vbox.add_child(news_detail_action_row)
	if news_meet_contact_button.get_parent() != news_detail_action_row:
		news_meet_contact_button.reparent(news_detail_action_row)
	if news_open_meeting_button != null and news_open_meeting_button.get_parent() != news_detail_action_row:
		news_open_meeting_button.reparent(news_detail_action_row)
	_ensure_news_detail_scroll()
	var detail_content: VBoxContainer = news_detail_scroll_content if news_detail_scroll_content != null else detail_vbox
	_order_news_detail_nodes(detail_content)
	_style_news_newspaper_ui()
func _order_news_detail_nodes(detail_vbox: VBoxContainer) -> void:
	var ordered_nodes: Array = [
		news_detail_outlet_label,
		news_detail_chips_label,
		news_detail_headline_label,
		news_detail_deck_label,
		news_detail_byline_label,
		news_detail_meta_label,
		news_detail_hero_frame,
		news_detail_photo_caption_label,
		news_detail_body,
		news_detail_hint_label,
		news_detail_action_row
	]
	var insert_index: int = 0
	for node_value in ordered_nodes:
		var node: Node = node_value
		if node == null or node.get_parent() != detail_vbox:
			continue
		detail_vbox.move_child(node, insert_index)
		insert_index += 1
func _ensure_news_grunge_overlay() -> void:
	if news_grunge_overlay != null:
		return
	news_grunge_overlay = Control.new()
	news_grunge_overlay.name = "NewsGrungeOverlay"
	news_grunge_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	news_grunge_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	news_grunge_overlay.z_index = 12
	news_window_body.add_child(news_grunge_overlay)
	_add_news_paper_speckles(news_grunge_overlay)
	_add_news_grunge_texture(news_grunge_overlay, "NewsFoldVertical", "fold_vertical", 0.5, 0.0, 0.5, 1.0, -17.0, 0.0, 17.0, 0.0, 0.16, 0.0, TextureRect.STRETCH_SCALE)
	_add_news_grunge_texture(news_grunge_overlay, "NewsFoldHorizontal", "fold_horizontal", 0.0, 0.38, 1.0, 0.38, 0.0, -12.0, 0.0, 12.0, 0.10, 0.0, TextureRect.STRETCH_SCALE)
	_add_news_grunge_texture(news_grunge_overlay, "NewsCoffeeStain", "coffee", 0.52, 1.0, 0.52, 1.0, -72.0, -174.0, 168.0, 6.0, 0.24, 0.0, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_add_news_grunge_texture(news_grunge_overlay, "NewsTraderEditionStamp", "stamp_trader", 1.0, 0.0, 1.0, 0.0, -146.0, 94.0, -34.0, 206.0, 0.32, -14.0, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_add_news_grunge_texture(news_grunge_overlay, "NewsSmudgeOne", "smudge_01", 0.64, 0.29, 0.64, 0.29, 0.0, 0.0, 44.0, 28.0, 0.24, -10.0, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_add_news_grunge_texture(news_grunge_overlay, "NewsSmudgeTwo", "smudge_02", 0.34, 0.52, 0.34, 0.52, 0.0, 0.0, 38.0, 24.0, 0.20, 13.0, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_add_news_grunge_texture(news_grunge_overlay, "NewsSmudgeThree", "smudge_03", 0.79, 0.73, 0.79, 0.73, 0.0, 0.0, 36.0, 22.0, 0.18, -18.0, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_add_news_grunge_texture(news_grunge_overlay, "NewsSmudgeFour", "smudge_04", 0.23, 0.78, 0.23, 0.78, 0.0, 0.0, 32.0, 20.0, 0.18, 8.0, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
func _add_news_paper_speckles(parent: Control) -> void:
	for speck_index in range(72):
		var speck := ColorRect.new()
		speck.name = "NewsPaperSpeckle_%02d" % speck_index
		speck.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var x_ratio: float = float((speck_index * 37 + 11) % 101) / 101.0
		var y_ratio: float = float((speck_index * 53 + 7) % 97) / 97.0
		speck.anchor_left = x_ratio
		speck.anchor_right = x_ratio
		speck.anchor_top = y_ratio
		speck.anchor_bottom = y_ratio
		var speck_size: float = 1.0 + float(speck_index % 3)
		speck.offset_left = 0.0
		speck.offset_top = 0.0
		speck.offset_right = speck_size
		speck.offset_bottom = speck_size
		speck.color = Color(COLOR_MARKET_PAPER_MUTED.r, COLOR_MARKET_PAPER_MUTED.g, COLOR_MARKET_PAPER_MUTED.b, 0.055)
		parent.add_child(speck)
func _add_news_grunge_texture(
	parent: Control,
	node_name: String,
	texture_id: String,
	anchor_left: float,
	anchor_top: float,
	anchor_right: float,
	anchor_bottom: float,
	offset_left: float,
	offset_top: float,
	offset_right: float,
	offset_bottom: float,
	alpha: float,
	rotation: float,
	stretch_mode: int
) -> void:
	var texture: Texture2D = _market_paper_texture(texture_id)
	if texture == null:
		return
	var texture_rect := TextureRect.new()
	texture_rect.name = node_name
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.texture = texture
	texture_rect.anchor_left = anchor_left
	texture_rect.anchor_top = anchor_top
	texture_rect.anchor_right = anchor_right
	texture_rect.anchor_bottom = anchor_bottom
	texture_rect.offset_left = offset_left
	texture_rect.offset_top = offset_top
	texture_rect.offset_right = offset_right
	texture_rect.offset_bottom = offset_bottom
	texture_rect.modulate = Color(1, 1, 1, alpha)
	texture_rect.rotation_degrees = rotation
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = stretch_mode
	parent.add_child(texture_rect)
func _market_paper_texture(texture_id: String) -> Texture2D:
	var path: String = str(MARKET_PAPER_GRUNGE_TEXTURES.get(texture_id, ""))
	if path.is_empty():
		return null
	return _desktop_texture(path)
func _style_news_newspaper_ui() -> void:
	_style_news_panel(news_window_body, COLOR_MARKET_PAPER_PAGE, Color(COLOR_MARKET_PAPER_BORDER.r, COLOR_MARKET_PAPER_BORDER.g, COLOR_MARKET_PAPER_BORDER.b, 0.0), 0)
	_style_news_panel(news_masthead_panel, Color(COLOR_MARKET_PAPER_PAGE.r, COLOR_MARKET_PAPER_PAGE.g, COLOR_MARKET_PAPER_PAGE.b, 0.0), Color(COLOR_MARKET_PAPER_BORDER.r, COLOR_MARKET_PAPER_BORDER.g, COLOR_MARKET_PAPER_BORDER.b, 0.0), 0)
	_style_news_panel(news_feed_panel, Color(0.972549, 0.94902, 0.847059, 1), COLOR_MARKET_PAPER_BORDER, 1)
	_style_news_panel(news_detail_panel, COLOR_MARKET_PAPER_CARD, COLOR_MARKET_PAPER_BORDER, 1)
	_style_news_inner_panel(news_masthead_issue_box, Color(COLOR_MARKET_PAPER_PAGE.r, COLOR_MARKET_PAPER_PAGE.g, COLOR_MARKET_PAPER_PAGE.b, 0.34))

	var news_window_margin := news_window_body.get_node_or_null("NewsWindowMargin") as MarginContainer
	if news_window_margin != null:
		news_window_margin.add_theme_constant_override("margin_left", 18)
		news_window_margin.add_theme_constant_override("margin_top", 16)
		news_window_margin.add_theme_constant_override("margin_right", 18)
		news_window_margin.add_theme_constant_override("margin_bottom", 16)
	var news_window_vbox := news_outlet_buttons.get_parent() as VBoxContainer
	if news_window_vbox != null:
		news_window_vbox.add_theme_constant_override("separation", 12)
	news_outlet_buttons.add_theme_constant_override("separation", 12)
	var content_split := news_feed_panel.get_parent() as HSplitContainer
	if content_split != null:
		content_split.split_offset = 430
	news_feed_panel.custom_minimum_size = Vector2(370, 0)
	news_feed_summary_label.add_theme_color_override("font_color", COLOR_MARKET_PAPER_RED)
	_apply_font_override_to_control(news_feed_summary_label, 12, _get_dashboard_title_font())
	_apply_font_override_to_control(news_archive_year_label, 13, _get_app_font())
	_apply_font_override_to_control(news_archive_month_label, 13, _get_app_font())
	_style_light_option_button(news_archive_year_option)
	_style_light_option_button(news_archive_month_option)

	if news_masthead_rule_container != null:
		for child in news_masthead_rule_container.get_children():
			if child is ColorRect:
				var rule: ColorRect = child
				rule.color = COLOR_MARKET_PAPER_RED
	if news_source_tab_rule != null:
		news_source_tab_rule.color = Color(COLOR_MARKET_PAPER_BORDER.r, COLOR_MARKET_PAPER_BORDER.g, COLOR_MARKET_PAPER_BORDER.b, 0.74)

	_style_news_label(news_masthead_issue_label, COLOR_WINDOW_TEXT, 10, _get_dashboard_title_font())
	_style_news_label(news_masthead_issue_number_label, COLOR_MARKET_PAPER_RED, 18, _get_dashboard_title_font())
	_style_news_label(news_masthead_title_label, COLOR_WINDOW_TEXT, 32, _get_dashboard_title_font())
	_style_news_label(news_masthead_tagline_label, COLOR_MARKET_PAPER_MUTED, 11, _get_app_font())
	_style_news_label(news_masthead_date_block_label, COLOR_WINDOW_TEXT, 10, _get_dashboard_title_font())
	_style_news_label(news_masthead_date_label, COLOR_WINDOW_TEXT, 15, _get_dashboard_title_font())
	_style_news_label(news_masthead_price_label, COLOR_MARKET_PAPER_MUTED, 11, _get_app_font())

	_style_news_label(news_detail_outlet_label, COLOR_MARKET_PAPER_RED, 12, _get_dashboard_title_font())
	_style_news_label(news_detail_chips_label, COLOR_MARKET_PAPER_RED, 12, _get_dashboard_title_font())
	_style_news_label(news_detail_headline_label, COLOR_WINDOW_TEXT, 24, _get_dashboard_title_font())
	_style_news_label(news_detail_deck_label, COLOR_MARKET_PAPER_MUTED, 15, _get_app_font())
	_style_news_label(news_detail_byline_label, COLOR_WINDOW_TEXT, 13, _get_app_font())
	_style_news_label(news_detail_meta_label, COLOR_MARKET_PAPER_MUTED, 12, _get_app_font())
	_style_news_label(news_detail_photo_caption_label, COLOR_MARKET_PAPER_MUTED, 12, _get_app_font())
	_style_news_label(news_detail_hint_label, COLOR_MARKET_PAPER_MUTED, 12, _get_app_font())
	if news_detail_hero_frame != null:
		_style_news_asset_frame(news_detail_hero_frame)
	news_detail_body.add_theme_color_override("default_color", COLOR_WINDOW_TEXT)
	news_detail_body.add_theme_color_override("font_selected_color", COLOR_WINDOW_TEXT)
	_apply_font_override_to_control(news_detail_body, 14, _get_app_font())
	if news_meet_contact_button != null:
		_style_news_command_button(news_meet_contact_button, true)
	if news_open_meeting_button != null:
		_style_news_command_button(news_open_meeting_button, true)
func _style_news_label(label: Label, color: Color, font_size: int, font_resource: Font = null) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", color)
	_apply_font_override_to_control(label, font_size, font_resource)
func _style_news_panel(panel: PanelContainer, fill_color: Color, border_color: Color, border_width: int) -> void:
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", style)
func _style_news_inner_panel(panel: PanelContainer, fill_color: Color) -> void:
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = Color(COLOR_MARKET_PAPER_BORDER.r, COLOR_MARKET_PAPER_BORDER.g, COLOR_MARKET_PAPER_BORDER.b, 0.78)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	panel.add_theme_stylebox_override("panel", style)
func _style_news_asset_frame(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_MARKET_PAPER_RAIL
	style.border_color = Color(COLOR_MARKET_PAPER_BORDER.r, COLOR_MARKET_PAPER_BORDER.g, COLOR_MARKET_PAPER_BORDER.b, 0.85)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	panel.add_theme_stylebox_override("panel", style)
func _style_news_article_card(card: PanelContainer, is_selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_MARKET_PAPER_CARD if is_selected else Color(0.972549, 0.94902, 0.847059, 1)
	style.border_color = COLOR_MARKET_PAPER_RED if is_selected else Color(COLOR_MARKET_PAPER_BORDER.r, COLOR_MARKET_PAPER_BORDER.g, COLOR_MARKET_PAPER_BORDER.b, 0.76)
	style.set_border_width_all(2 if is_selected else 1)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	card.add_theme_stylebox_override("panel", style)
func _style_news_outlet_button(button: Button, is_selected: bool, is_unlocked: bool) -> void:
	_style_news_tab_button(button, is_selected, is_unlocked)
func _make_news_tab_stylebox(fill_color: Color, border_color: Color, is_selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 5 if is_selected else 1
	style.border_width_bottom = 0 if is_selected else 1
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 11 if is_selected else 14
	style.content_margin_bottom = 14
	return style
func _style_news_tab_button(button: Button, is_selected: bool, is_unlocked: bool) -> void:
	var fill_color: Color = COLOR_MARKET_PAPER_RAIL if is_unlocked else Color(0.85098, 0.835294, 0.772549, 1)
	var border_color: Color = Color(COLOR_MARKET_PAPER_BORDER.r, COLOR_MARKET_PAPER_BORDER.g, COLOR_MARKET_PAPER_BORDER.b, 0.86)
	var font_color: Color = COLOR_WINDOW_TEXT if is_unlocked else Color(0.541176, 0.494118, 0.396078, 1)
	if is_selected:
		fill_color = COLOR_MARKET_PAPER_CARD
		border_color = COLOR_MARKET_PAPER_RED
		font_color = Color(0.184314, 0.14902, 0.0705882, 1)
	var normal := _make_news_tab_stylebox(fill_color, border_color, is_selected)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_disabled_color", Color(font_color.r, font_color.g, font_color.b, 0.54))
	_apply_font_override_to_control(button, 15, _get_dashboard_title_font())
func _style_news_tab_container(tab_container: TabContainer) -> void:
	if tab_container == null:
		return
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(COLOR_MARKET_PAPER_PAGE.r, COLOR_MARKET_PAPER_PAGE.g, COLOR_MARKET_PAPER_PAGE.b, 0.0)
	panel_style.border_color = Color(COLOR_MARKET_PAPER_BORDER.r, COLOR_MARKET_PAPER_BORDER.g, COLOR_MARKET_PAPER_BORDER.b, 0.0)
	panel_style.set_border_width_all(0)
	panel_style.set_corner_radius_all(0)
	var unselected := _make_news_tab_stylebox(COLOR_MARKET_PAPER_RAIL, Color(COLOR_MARKET_PAPER_BORDER.r, COLOR_MARKET_PAPER_BORDER.g, COLOR_MARKET_PAPER_BORDER.b, 0.86), false)
	var selected := _make_news_tab_stylebox(COLOR_MARKET_PAPER_CARD, COLOR_MARKET_PAPER_RED, true)
	var disabled := _make_news_tab_stylebox(Color(0.85098, 0.835294, 0.772549, 1), Color(COLOR_MARKET_PAPER_BORDER.r, COLOR_MARKET_PAPER_BORDER.g, COLOR_MARKET_PAPER_BORDER.b, 0.42), false)
	tab_container.add_theme_stylebox_override("panel", panel_style)
	tab_container.add_theme_stylebox_override("tab_unselected", unselected)
	tab_container.add_theme_stylebox_override("tab_selected", selected)
	tab_container.add_theme_stylebox_override("tab_hovered", unselected)
	tab_container.add_theme_stylebox_override("tab_disabled", disabled)
	tab_container.add_theme_stylebox_override("tab_focus", selected)
	tab_container.add_theme_color_override("font_selected_color", Color(0.184314, 0.14902, 0.0705882, 1))
	tab_container.add_theme_color_override("font_unselected_color", COLOR_WINDOW_TEXT)
	tab_container.add_theme_color_override("font_hovered_color", COLOR_WINDOW_TEXT)
	tab_container.add_theme_color_override("font_disabled_color", Color(0.541176, 0.494118, 0.396078, 0.54))
	tab_container.add_theme_constant_override("side_margin", 0)
	tab_container.add_theme_constant_override("icon_separation", 6)
	_apply_font_override_to_control(tab_container, 15, _get_dashboard_title_font())
func _style_news_command_button(button: Button, is_primary: bool) -> void:
	if button == null:
		return
	UiTheme.style_button(button, "desktop_primary" if is_primary else "desktop_secondary")


func _sync_dynamic_refs_from_root() -> void:
	if _root == null:
		return
	news_capture_menu = _root.get("news_capture_menu") as PopupMenu
	news_window = _root.get("news_window") as MarginContainer
	news_window_body = _root.get("news_window_body") as PanelContainer
	news_title_label = _root.get("news_title_label") as Label
	news_intel_status_label = _root.get("news_intel_status_label") as Label
	news_outlet_buttons = _root.get("news_outlet_buttons") as HBoxContainer
	news_feed_panel = _root.get("news_feed_panel") as PanelContainer
	news_feed_summary_label = _root.get("news_feed_summary_label") as Label
	news_archive_year_label = _root.get("news_archive_year_label") as Label
	news_archive_year_option = _root.get("news_archive_year_option") as OptionButton
	news_archive_month_label = _root.get("news_archive_month_label") as Label
	news_archive_month_option = _root.get("news_archive_month_option") as OptionButton
	news_article_list = _root.get("news_article_list") as ItemList
	news_detail_panel = _root.get("news_detail_panel") as PanelContainer
	news_detail_outlet_label = _root.get("news_detail_outlet_label") as Label
	news_detail_headline_label = _root.get("news_detail_headline_label") as Label
	news_detail_deck_label = _root.get("news_detail_deck_label") as Label
	news_detail_meta_label = _root.get("news_detail_meta_label") as Label
	news_detail_body = _root.get("news_detail_body") as RichTextLabel
	news_detail_hint_label = _root.get("news_detail_hint_label") as Label
	news_meet_contact_button = _root.get("news_meet_contact_button") as Button
	news_masthead_panel = _root.get("news_masthead_panel") as PanelContainer
	news_masthead_issue_box = _root.get("news_masthead_issue_box") as PanelContainer
	news_masthead_issue_label = _root.get("news_masthead_issue_label") as Label
	news_masthead_issue_number_label = _root.get("news_masthead_issue_number_label") as Label
	news_masthead_title_label = _root.get("news_masthead_title_label") as Label
	news_masthead_tagline_label = _root.get("news_masthead_tagline_label") as Label
	news_masthead_date_block_label = _root.get("news_masthead_date_block_label") as Label
	news_masthead_date_label = _root.get("news_masthead_date_label") as Label
	news_masthead_price_label = _root.get("news_masthead_price_label") as Label
	news_masthead_rule_container = _root.get("news_masthead_rule_container") as VBoxContainer
	news_source_tab_rule = _root.get("news_source_tab_rule") as ColorRect
	news_article_cards_scroll = _root.get("news_article_cards_scroll") as ScrollContainer
	news_article_cards = _root.get("news_article_cards") as VBoxContainer
	news_detail_scroll = _root.get("news_detail_scroll") as ScrollContainer
	news_detail_scroll_content = _root.get("news_detail_scroll_content") as VBoxContainer
	news_detail_hero_frame = _root.get("news_detail_hero_frame") as PanelContainer
	news_detail_photo_caption_label = _root.get("news_detail_photo_caption_label") as Label
	news_detail_byline_label = _root.get("news_detail_byline_label") as Label
	news_detail_chips_label = _root.get("news_detail_chips_label") as Label
	news_detail_action_row = _root.get("news_detail_action_row") as HBoxContainer
	news_open_meeting_button = _root.get("news_open_meeting_button") as Button
	news_grunge_overlay = _root.get("news_grunge_overlay") as Control


func _sync_state_from_root() -> void:
	if _root == null:
		return
	var capture_payloads = _root.get("pending_capture_payloads")
	pending_capture_payloads = capture_payloads if typeof(capture_payloads) == TYPE_DICTIONARY else {}
	var snapshot = _root.get("current_news_snapshot")
	current_news_snapshot = snapshot if typeof(snapshot) == TYPE_DICTIONARY else {}
	selected_news_outlet_id = str(_root.get("selected_news_outlet_id"))
	selected_news_archive_year = int(_root.get("selected_news_archive_year"))
	selected_news_archive_month = int(_root.get("selected_news_archive_month"))
	selected_news_article_id = str(_root.get("selected_news_article_id"))
	news_article_cards_generation = int(_root.get("news_article_cards_generation"))
	var press_positions = _root.get("news_article_card_press_positions")
	news_article_card_press_positions = press_positions if typeof(press_positions) == TYPE_DICTIONARY else {}


func _sync_root_refs() -> void:
	if _root == null:
		return
	_root.set("news_capture_menu", news_capture_menu)
	_root.set("news_window", news_window)
	_root.set("news_window_body", news_window_body)
	_root.set("news_title_label", news_title_label)
	_root.set("news_intel_status_label", news_intel_status_label)
	_root.set("news_outlet_buttons", news_outlet_buttons)
	_root.set("news_feed_panel", news_feed_panel)
	_root.set("news_feed_summary_label", news_feed_summary_label)
	_root.set("news_archive_year_label", news_archive_year_label)
	_root.set("news_archive_year_option", news_archive_year_option)
	_root.set("news_archive_month_label", news_archive_month_label)
	_root.set("news_archive_month_option", news_archive_month_option)
	_root.set("news_article_list", news_article_list)
	_root.set("news_detail_panel", news_detail_panel)
	_root.set("news_detail_outlet_label", news_detail_outlet_label)
	_root.set("news_detail_headline_label", news_detail_headline_label)
	_root.set("news_detail_deck_label", news_detail_deck_label)
	_root.set("news_detail_meta_label", news_detail_meta_label)
	_root.set("news_detail_body", news_detail_body)
	_root.set("news_detail_hint_label", news_detail_hint_label)
	_root.set("news_meet_contact_button", news_meet_contact_button)
	_root.set("news_masthead_panel", news_masthead_panel)
	_root.set("news_masthead_issue_box", news_masthead_issue_box)
	_root.set("news_masthead_issue_label", news_masthead_issue_label)
	_root.set("news_masthead_issue_number_label", news_masthead_issue_number_label)
	_root.set("news_masthead_title_label", news_masthead_title_label)
	_root.set("news_masthead_tagline_label", news_masthead_tagline_label)
	_root.set("news_masthead_date_block_label", news_masthead_date_block_label)
	_root.set("news_masthead_date_label", news_masthead_date_label)
	_root.set("news_masthead_price_label", news_masthead_price_label)
	_root.set("news_masthead_rule_container", news_masthead_rule_container)
	_root.set("news_source_tab_rule", news_source_tab_rule)
	_root.set("news_article_cards_scroll", news_article_cards_scroll)
	_root.set("news_article_cards", news_article_cards)
	_root.set("news_detail_scroll", news_detail_scroll)
	_root.set("news_detail_scroll_content", news_detail_scroll_content)
	_root.set("news_detail_hero_frame", news_detail_hero_frame)
	_root.set("news_detail_photo_caption_label", news_detail_photo_caption_label)
	_root.set("news_detail_byline_label", news_detail_byline_label)
	_root.set("news_detail_chips_label", news_detail_chips_label)
	_root.set("news_detail_action_row", news_detail_action_row)
	_root.set("news_open_meeting_button", news_open_meeting_button)
	_root.set("news_grunge_overlay", news_grunge_overlay)
	_sync_root_state()


func _sync_root_state() -> void:
	if _root == null:
		return
	_root.set("pending_capture_payloads", pending_capture_payloads)
	_root.set("current_news_snapshot", current_news_snapshot)
	_root.set("selected_news_outlet_id", selected_news_outlet_id)
	_root.set("selected_news_archive_year", selected_news_archive_year)
	_root.set("selected_news_archive_month", selected_news_archive_month)
	_root.set("selected_news_article_id", selected_news_article_id)
	_root.set("news_article_cards_generation", news_article_cards_generation)
	_root.set("news_article_card_press_positions", news_article_card_press_positions)


func add_child(node: Node) -> void:
	if _root != null:
		_root.add_child(node)


func get_tree() -> SceneTree:
	if _root == null:
		return null
	return _root.get_tree()


func get_viewport() -> Viewport:
	if _root == null:
		return null
	return _root.get_viewport()


func _style_light_option_button(option_button: OptionButton) -> void:
	UiTheme.style_option_button(option_button, "desktop")


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


func _node_token(value: String) -> String:
	if _root == null:
		return value.strip_edges().to_lower().replace(" ", "_")
	return str(_root.call("_node_token", value))


func _contact_for_context(source_type: String, source_id: String, company_id: String = "") -> Dictionary:
	if _root == null:
		return {}
	return _root.call("_contact_for_context", source_type, source_id, company_id)


func _open_social_account_from_news(account_id: String, contact_id: String = "") -> void:
	if _root != null:
		_root.call("_open_social_account_from_news", account_id, contact_id)


func _open_corporate_meeting_modal(meeting_id: String) -> void:
	if _root != null:
		_root.call("_open_corporate_meeting_modal", meeting_id)


func _mark_guide_research_interaction() -> void:
	if _root != null:
		_root.call("_mark_guide_research_interaction")


func _record_steam_news_article_read(article_id: String) -> void:
	if _root != null:
		_root.call("_record_steam_news_article_read", article_id)


func _show_toast(message: String, is_success: bool) -> void:
	if _root != null:
		_root.call("_show_toast", message, is_success)


func _log_perf_elapsed(label: String, started_at_usec: int) -> void:
	if _root != null:
		_root.call("_log_perf_elapsed", label, started_at_usec)


func _log_perf_phase(enabled: bool, label: String, started_at_usec: int) -> void:
	if _root != null:
		_root.call("_log_perf_phase", enabled, label, started_at_usec)


func _desktop_texture(path: String) -> Texture2D:
	if _root == null:
		return null
	return _root.call("_desktop_texture", path) as Texture2D
