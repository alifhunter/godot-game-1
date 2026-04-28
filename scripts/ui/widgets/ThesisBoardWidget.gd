extends MarginContainer

const COLOR_BG := Color(0.909804, 0.909804, 0.803922, 1)
const COLOR_PANEL := Color(0.972549, 0.94902, 0.847059, 1)
const COLOR_PANEL_ALT := Color(0.952941, 0.94902, 0.87451, 1)
const COLOR_BROWN := Color(0.509804, 0.231373, 0.0941176, 1)
const COLOR_TEXT := Color(0.184314, 0.172549, 0.109804, 1)
const COLOR_MUTED := Color(0.403922, 0.380392, 0.301961, 1)
const COLOR_BORDER := Color(0.52549, 0.396078, 0.160784, 1)
const COLOR_PAPER := Color(0.992157, 0.988235, 0.956863, 1)
const REPORT_PREPARE_STEP_SECONDS := 0.34
const REPORT_PREPARE_LINES := [
	"Reviewing selected evidence...",
	"Checking valuation, tape, and risk...",
	"Formatting research note..."
]
const EVIDENCE_DISCIPLINE_PILLARS := [
	{"id": "anchor", "label": "Anchor", "categories": ["fundamentals", "financials", "valuation"], "focus_category": "fundamentals"},
	{"id": "price", "label": "Price", "categories": ["price_action"], "focus_category": "price_action"},
	{"id": "tape", "label": "Tape", "categories": ["broker_flow"], "focus_category": "broker_flow"},
	{"id": "catalyst", "label": "Catalyst", "categories": ["sector_macro", "news", "twooter", "network_intel", "corporate_events"], "focus_category": "sector_macro"},
	{"id": "risk", "label": "Invalidation", "categories": ["risk_invalidation"], "focus_category": "risk_invalidation"}
]

var selected_external_company_id: String = ""
var selected_thesis_id: String = ""
var board_snapshot: Dictionary = {}
var evidence_snapshot: Dictionary = {}
var suppress_thesis_changed_refresh: bool = false

var status_label: Label = null
var thesis_list: ItemList = null
var company_option: OptionButton = null
var title_edit: LineEdit = null
var stance_option: OptionButton = null
var horizon_option: OptionButton = null
var use_selected_stock_button: Button = null
var create_button: Button = null
var update_button: Button = null
var evidence_category_option: OptionButton = null
var evidence_option: OptionButton = null
var evidence_detail_label: Label = null
var evidence_discipline_label: Label = null
var add_evidence_button: Button = null
var selected_evidence_list: ItemList = null
var remove_evidence_button: Button = null
var generate_report_button: Button = null
var view_paper_button: Button = null
var refresh_review_button: Button = null
var close_thesis_button: Button = null
var review_state_label: Label = null
var report_overlay: Control = null
var report_preparing_panel: PanelContainer = null
var report_preparing_label: Label = null
var report_prepare_close_button: Button = null
var thesis_white_paper_panel: PanelContainer = null
var report_header_label: Label = null
var report_meta_label: Label = null
var report_badge_label: Label = null
var report_text: RichTextLabel = null
var report_footer_label: Label = null
var report_close_button: Button = null
var report_regenerate_button: Button = null
var report_refresh_review_button: Button = null
var report_generation_running: bool = false


func _ready() -> void:
	_build_ui()
	if not GameManager.thesis_changed.is_connected(_on_thesis_changed):
		GameManager.thesis_changed.connect(_on_thesis_changed)
	refresh()


func set_selected_company_id(company_id: String) -> void:
	selected_external_company_id = company_id


func _input(event: InputEvent) -> void:
	if (
		event is InputEventKey and
		event.pressed and
		not event.echo and
		event.keycode == KEY_ESCAPE and
		report_overlay != null and
		report_overlay.visible and
		not report_generation_running
	):
		_hide_report_overlay()
		get_viewport().set_input_as_handled()


func refresh() -> void:
	if thesis_list == null:
		return
	board_snapshot = GameManager.get_thesis_board_snapshot()
	_refresh_company_options()
	_refresh_thesis_list()
	_refresh_selected_thesis()


func _build_ui() -> void:
	name = "ThesisWindow"
	add_theme_constant_override("margin_left", 0)
	add_theme_constant_override("margin_top", 0)
	add_theme_constant_override("margin_right", 0)
	add_theme_constant_override("margin_bottom", 0)

	var root := HBoxContainer.new()
	root.name = "ThesisRootSplit"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var left_panel := _make_panel("ThesisListPanel")
	left_panel.custom_minimum_size = Vector2(260, 0)
	root.add_child(left_panel)
	var left_vbox := _panel_vbox(left_panel, "ThesisListVBox")
	left_vbox.add_child(_make_title("Thesis Board"))

	status_label = Label.new()
	status_label.name = "ThesisStatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.text = "Create a thesis, add evidence, then generate a research note."
	_style_label(status_label, COLOR_MUTED, 12)
	left_vbox.add_child(status_label)

	thesis_list = ItemList.new()
	thesis_list.name = "ThesisList"
	thesis_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	thesis_list.item_selected.connect(_on_thesis_selected)
	left_vbox.add_child(thesis_list)

	var center_panel := _make_panel("ThesisBuilderPanel")
	center_panel.custom_minimum_size = Vector2(380, 0)
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(center_panel)
	var center_vbox := _panel_vbox(center_panel, "ThesisBuilderVBox")
	center_vbox.add_child(_make_title("Build Thesis"))

	company_option = OptionButton.new()
	company_option.name = "ThesisCompanyOption"
	center_vbox.add_child(company_option)

	title_edit = LineEdit.new()
	title_edit.name = "ThesisTitleEdit"
	title_edit.placeholder_text = "Thesis title"
	center_vbox.add_child(title_edit)

	var meta_row := HBoxContainer.new()
	meta_row.name = "ThesisMetaRow"
	meta_row.add_theme_constant_override("separation", 8)
	center_vbox.add_child(meta_row)
	stance_option = OptionButton.new()
	stance_option.name = "ThesisStanceOption"
	_add_option_items(stance_option, [
		{"id": "bullish", "label": "Bullish"},
		{"id": "bearish", "label": "Bearish"},
		{"id": "income", "label": "Income"},
		{"id": "watch", "label": "Watch"}
	])
	meta_row.add_child(stance_option)
	horizon_option = OptionButton.new()
	horizon_option.name = "ThesisHorizonOption"
	_add_option_items(horizon_option, [
		{"id": "swing", "label": "Swing"},
		{"id": "position", "label": "Position"},
		{"id": "income", "label": "Income"},
		{"id": "event", "label": "Event"}
	])
	meta_row.add_child(horizon_option)

	var create_row := HBoxContainer.new()
	create_row.name = "ThesisCreateRow"
	create_row.add_theme_constant_override("separation", 8)
	center_vbox.add_child(create_row)
	use_selected_stock_button = Button.new()
	use_selected_stock_button.name = "ThesisUseSelectedStockButton"
	use_selected_stock_button.text = "Use selected STOCKBOT stock"
	use_selected_stock_button.pressed.connect(_on_use_selected_stock_pressed)
	create_row.add_child(use_selected_stock_button)
	create_button = Button.new()
	create_button.name = "ThesisCreateButton"
	create_button.text = "Create"
	create_button.pressed.connect(_on_create_thesis_pressed)
	create_row.add_child(create_button)
	update_button = Button.new()
	update_button.name = "ThesisUpdateButton"
	update_button.text = "Update"
	update_button.pressed.connect(_on_update_thesis_pressed)
	create_row.add_child(update_button)

	center_vbox.add_child(_make_title("Evidence"))
	evidence_discipline_label = Label.new()
	evidence_discipline_label.name = "ThesisEvidenceDisciplineLabel"
	evidence_discipline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	evidence_discipline_label.custom_minimum_size = Vector2(0, 58)
	evidence_discipline_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(evidence_discipline_label, COLOR_MUTED, 12)
	center_vbox.add_child(evidence_discipline_label)

	evidence_category_option = OptionButton.new()
	evidence_category_option.name = "ThesisEvidenceCategoryOption"
	evidence_category_option.item_selected.connect(_on_evidence_category_selected)
	center_vbox.add_child(evidence_category_option)

	evidence_option = OptionButton.new()
	evidence_option.name = "ThesisEvidenceOption"
	evidence_option.item_selected.connect(_on_evidence_option_selected)
	center_vbox.add_child(evidence_option)

	evidence_detail_label = Label.new()
	evidence_detail_label.name = "ThesisEvidenceDetailLabel"
	evidence_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	evidence_detail_label.custom_minimum_size = Vector2(0, 60)
	_style_label(evidence_detail_label, COLOR_MUTED, 12)
	center_vbox.add_child(evidence_detail_label)

	add_evidence_button = Button.new()
	add_evidence_button.name = "ThesisAddEvidenceButton"
	add_evidence_button.text = "Add Evidence"
	add_evidence_button.pressed.connect(_on_add_evidence_pressed)
	center_vbox.add_child(add_evidence_button)

	selected_evidence_list = ItemList.new()
	selected_evidence_list.name = "ThesisEvidenceList"
	selected_evidence_list.custom_minimum_size = Vector2(0, 150)
	selected_evidence_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_vbox.add_child(selected_evidence_list)

	var evidence_actions := HBoxContainer.new()
	evidence_actions.name = "ThesisEvidenceActions"
	evidence_actions.add_theme_constant_override("separation", 8)
	center_vbox.add_child(evidence_actions)
	remove_evidence_button = Button.new()
	remove_evidence_button.name = "ThesisRemoveEvidenceButton"
	remove_evidence_button.text = "Remove Selected"
	remove_evidence_button.pressed.connect(_on_remove_evidence_pressed)
	evidence_actions.add_child(remove_evidence_button)
	generate_report_button = Button.new()
	generate_report_button.name = "ThesisGenerateReportButton"
	generate_report_button.text = "Generate Report"
	generate_report_button.pressed.connect(_on_generate_report_pressed)
	evidence_actions.add_child(generate_report_button)

	center_vbox.add_child(_make_title("Report Status"))
	review_state_label = Label.new()
	review_state_label.name = "ThesisReviewStateLabel"
	review_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	review_state_label.custom_minimum_size = Vector2(0, 54)
	_style_label(review_state_label, COLOR_MUTED, 12)
	center_vbox.add_child(review_state_label)

	var report_actions := HBoxContainer.new()
	report_actions.name = "ThesisReportActions"
	report_actions.add_theme_constant_override("separation", 8)
	center_vbox.add_child(report_actions)
	view_paper_button = Button.new()
	view_paper_button.name = "ThesisViewPaperButton"
	view_paper_button.text = "View Paper"
	view_paper_button.pressed.connect(_on_view_paper_pressed)
	report_actions.add_child(view_paper_button)
	refresh_review_button = Button.new()
	refresh_review_button.name = "ThesisRefreshReviewButton"
	refresh_review_button.text = "Refresh Review"
	refresh_review_button.pressed.connect(_on_refresh_review_pressed)
	report_actions.add_child(refresh_review_button)
	close_thesis_button = Button.new()
	close_thesis_button.name = "ThesisCloseButton"
	close_thesis_button.text = "Close Thesis"
	close_thesis_button.pressed.connect(_on_close_thesis_pressed)
	report_actions.add_child(close_thesis_button)

	_build_report_overlay()
	_style_buttons(self)


func _build_report_overlay() -> void:
	report_overlay = Control.new()
	report_overlay.name = "ThesisReportOverlay"
	report_overlay.visible = false
	report_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	report_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(report_overlay)
	report_overlay.move_to_front()

	var scrim := ColorRect.new()
	scrim.name = "ThesisReportScrim"
	scrim.color = Color(0.0, 0.0, 0.0, 0.38)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	report_overlay.add_child(scrim)

	var overlay_margin := MarginContainer.new()
	overlay_margin.name = "ThesisReportOverlayMargin"
	overlay_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_margin.add_theme_constant_override("margin_left", 28)
	overlay_margin.add_theme_constant_override("margin_top", 28)
	overlay_margin.add_theme_constant_override("margin_right", 28)
	overlay_margin.add_theme_constant_override("margin_bottom", 28)
	report_overlay.add_child(overlay_margin)

	var center := CenterContainer.new()
	center.name = "ThesisReportOverlayCenter"
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_margin.add_child(center)

	report_preparing_panel = PanelContainer.new()
	report_preparing_panel.name = "ThesisReportPreparingPanel"
	report_preparing_panel.custom_minimum_size = Vector2(440, 170)
	report_preparing_panel.visible = false
	report_preparing_panel.add_theme_stylebox_override("panel", _make_stylebox(COLOR_PANEL, COLOR_BORDER, 1))
	center.add_child(report_preparing_panel)

	var preparing_margin := MarginContainer.new()
	preparing_margin.add_theme_constant_override("margin_left", 22)
	preparing_margin.add_theme_constant_override("margin_top", 20)
	preparing_margin.add_theme_constant_override("margin_right", 22)
	preparing_margin.add_theme_constant_override("margin_bottom", 20)
	report_preparing_panel.add_child(preparing_margin)

	var preparing_vbox := VBoxContainer.new()
	preparing_vbox.add_theme_constant_override("separation", 12)
	preparing_margin.add_child(preparing_vbox)
	var preparing_title := _make_title("Preparing Thesis Report")
	preparing_vbox.add_child(preparing_title)
	report_preparing_label = Label.new()
	report_preparing_label.name = "ThesisReportPreparingLabel"
	report_preparing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	report_preparing_label.text = REPORT_PREPARE_LINES[0]
	_style_label(report_preparing_label, COLOR_TEXT, 14)
	preparing_vbox.add_child(report_preparing_label)
	report_prepare_close_button = Button.new()
	report_prepare_close_button.name = "ThesisReportPrepareCloseButton"
	report_prepare_close_button.text = "Close"
	report_prepare_close_button.visible = false
	report_prepare_close_button.pressed.connect(_hide_report_overlay)
	preparing_vbox.add_child(report_prepare_close_button)

	thesis_white_paper_panel = PanelContainer.new()
	thesis_white_paper_panel.name = "ThesisWhitePaperPanel"
	thesis_white_paper_panel.custom_minimum_size = Vector2(780, 600)
	thesis_white_paper_panel.visible = false
	thesis_white_paper_panel.add_theme_stylebox_override("panel", _make_stylebox(COLOR_PAPER, Color(0.58, 0.52, 0.40, 1), 1))
	center.add_child(thesis_white_paper_panel)

	var paper_margin := MarginContainer.new()
	paper_margin.add_theme_constant_override("margin_left", 28)
	paper_margin.add_theme_constant_override("margin_top", 24)
	paper_margin.add_theme_constant_override("margin_right", 28)
	paper_margin.add_theme_constant_override("margin_bottom", 20)
	thesis_white_paper_panel.add_child(paper_margin)

	var paper_vbox := VBoxContainer.new()
	paper_vbox.name = "ThesisWhitePaperVBox"
	paper_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paper_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	paper_vbox.add_theme_constant_override("separation", 10)
	paper_margin.add_child(paper_vbox)

	var paper_header := HBoxContainer.new()
	paper_header.name = "ThesisWhitePaperHeader"
	paper_header.add_theme_constant_override("separation", 12)
	paper_vbox.add_child(paper_header)
	var header_copy := VBoxContainer.new()
	header_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paper_header.add_child(header_copy)
	report_badge_label = Label.new()
	report_badge_label.name = "ThesisWhitePaperBadgeLabel"
	report_badge_label.text = "WHITE PAPER  |  Generated Research Note"
	_style_label(report_badge_label, COLOR_BROWN, 11)
	header_copy.add_child(report_badge_label)
	report_header_label = Label.new()
	report_header_label.name = "ThesisWhitePaperHeaderLabel"
	report_header_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(report_header_label, COLOR_TEXT, 18)
	header_copy.add_child(report_header_label)
	report_meta_label = Label.new()
	report_meta_label.name = "ThesisWhitePaperMetaLabel"
	report_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(report_meta_label, COLOR_MUTED, 12)
	header_copy.add_child(report_meta_label)

	var overlay_actions := HBoxContainer.new()
	overlay_actions.name = "ThesisWhitePaperActions"
	overlay_actions.add_theme_constant_override("separation", 8)
	paper_header.add_child(overlay_actions)
	report_refresh_review_button = Button.new()
	report_refresh_review_button.name = "ThesisReportOverlayRefreshReviewButton"
	report_refresh_review_button.text = "Refresh Review"
	report_refresh_review_button.pressed.connect(_on_refresh_review_pressed)
	overlay_actions.add_child(report_refresh_review_button)
	report_regenerate_button = Button.new()
	report_regenerate_button.name = "ThesisReportRegenerateButton"
	report_regenerate_button.text = "Regenerate"
	report_regenerate_button.pressed.connect(_on_regenerate_report_pressed)
	overlay_actions.add_child(report_regenerate_button)
	report_close_button = Button.new()
	report_close_button.name = "ThesisReportCloseButton"
	report_close_button.text = "Close"
	report_close_button.pressed.connect(_hide_report_overlay)
	overlay_actions.add_child(report_close_button)

	var divider := ColorRect.new()
	divider.name = "ThesisWhitePaperDivider"
	divider.color = Color(0.72, 0.66, 0.50, 1)
	divider.custom_minimum_size = Vector2(0, 1)
	paper_vbox.add_child(divider)

	var report_scroll := ScrollContainer.new()
	report_scroll.name = "ThesisReportScroll"
	report_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	paper_vbox.add_child(report_scroll)
	report_text = RichTextLabel.new()
	report_text.name = "ThesisReportText"
	report_text.fit_content = true
	report_text.scroll_active = false
	report_text.selection_enabled = true
	report_text.bbcode_enabled = true
	_style_rich_text(report_text)
	report_scroll.add_child(report_text)

	report_footer_label = Label.new()
	report_footer_label.name = "ThesisWhitePaperFooterLabel"
	report_footer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(report_footer_label, COLOR_MUTED, 11)
	paper_vbox.add_child(report_footer_label)


func _refresh_company_options() -> void:
	var previous_company_id: String = _selected_company_id()
	company_option.clear()
	for company_value in board_snapshot.get("companies", []):
		if typeof(company_value) != TYPE_DICTIONARY:
			continue
		var company: Dictionary = company_value
		var index: int = company_option.item_count
		company_option.add_item("%s  %s" % [str(company.get("ticker", "")), str(company.get("name", ""))])
		company_option.set_item_metadata(index, str(company.get("id", "")))
	var target_company_id: String = previous_company_id
	if target_company_id.is_empty():
		target_company_id = selected_external_company_id
	_select_company_option(target_company_id)


func _refresh_thesis_list() -> void:
	var previous_id: String = selected_thesis_id
	thesis_list.clear()
	for thesis_value in board_snapshot.get("theses", []):
		if typeof(thesis_value) != TYPE_DICTIONARY:
			continue
		var thesis: Dictionary = thesis_value
		var index: int = thesis_list.item_count
		var status_suffix: String = "closed" if str(thesis.get("status", "open")) == "closed" else "%d evidence" % int(thesis.get("evidence_count", 0))
		thesis_list.add_item("%s\n%s | %s" % [str(thesis.get("title", "Untitled thesis")), str(thesis.get("ticker", "")), status_suffix])
		thesis_list.set_item_metadata(index, str(thesis.get("id", "")))
		if str(thesis.get("id", "")) == previous_id:
			thesis_list.select(index)
	if selected_thesis_id.is_empty() and thesis_list.item_count > 0:
		thesis_list.select(0)
		selected_thesis_id = str(thesis_list.get_item_metadata(0))


func _refresh_selected_thesis() -> void:
	var thesis: Dictionary = _selected_thesis()
	var has_thesis: bool = not thesis.is_empty()
	var has_report: bool = has_thesis and not thesis.get("report", {}).is_empty()
	update_button.disabled = not has_thesis or report_generation_running
	add_evidence_button.disabled = not has_thesis or report_generation_running
	remove_evidence_button.disabled = not has_thesis or report_generation_running
	generate_report_button.disabled = not has_thesis or report_generation_running
	view_paper_button.disabled = not has_report or report_generation_running
	refresh_review_button.disabled = not has_report or report_generation_running
	close_thesis_button.disabled = not has_thesis or report_generation_running
	if report_refresh_review_button != null:
		report_refresh_review_button.disabled = not has_report or report_generation_running
	if report_regenerate_button != null:
		report_regenerate_button.disabled = not has_thesis or report_generation_running
	if report_close_button != null:
		report_close_button.disabled = report_generation_running
	if not has_thesis:
		if report_text != null:
			report_text.text = ""
		review_state_label.text = "No active review."
		selected_evidence_list.clear()
		evidence_category_option.clear()
		evidence_option.clear()
		evidence_detail_label.text = ""
		_refresh_evidence_discipline({})
		if report_overlay != null and report_overlay.visible and not report_generation_running:
			_hide_report_overlay()
		return

	selected_thesis_id = str(thesis.get("id", ""))
	if (
		not thesis.get("report", {}).is_empty() and
		int(thesis.get("review", {}).get("updated_day_index", -1)) < int(board_snapshot.get("day_index", 0)) and
		not suppress_thesis_changed_refresh
	):
		suppress_thesis_changed_refresh = true
		GameManager.refresh_thesis_review(selected_thesis_id)
		suppress_thesis_changed_refresh = false
		board_snapshot = GameManager.get_thesis_board_snapshot()
		thesis = _selected_thesis()
	_select_company_option(str(thesis.get("company_id", "")))
	title_edit.text = str(thesis.get("title", ""))
	_select_option_by_id(stance_option, str(thesis.get("stance", "bullish")))
	_select_option_by_id(horizon_option, str(thesis.get("horizon", "swing")))
	_refresh_evidence_options(str(thesis.get("company_id", "")))
	_refresh_selected_evidence(thesis)
	_refresh_evidence_discipline(thesis)
	_refresh_report(thesis)


func _refresh_evidence_options(company_id: String) -> void:
	evidence_snapshot = GameManager.get_thesis_evidence_options(company_id)
	evidence_category_option.clear()
	for category_value in evidence_snapshot.get("categories", []):
		if typeof(category_value) != TYPE_DICTIONARY:
			continue
		var category: Dictionary = category_value
		var index: int = evidence_category_option.item_count
		evidence_category_option.add_item(str(category.get("label", category.get("id", ""))))
		evidence_category_option.set_item_metadata(index, category.duplicate(true))
	_refresh_evidence_option_picker()


func _refresh_evidence_option_picker() -> void:
	evidence_option.clear()
	var category: Dictionary = _selected_category()
	for option_value in category.get("options", []):
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		var index: int = evidence_option.item_count
		evidence_option.add_item("%s  |  %s" % [str(option.get("label", "")), str(option.get("value", ""))])
		evidence_option.set_item_metadata(index, option.duplicate(true))
	_refresh_evidence_detail()


func _refresh_evidence_detail() -> void:
	var option: Dictionary = _selected_evidence_option()
	if option.is_empty():
		evidence_detail_label.text = "No evidence option available."
		return
	evidence_detail_label.text = "%s\nImpact: %s" % [
		str(option.get("detail", "")),
		str(option.get("impact", "mixed")).capitalize()
	]


func _refresh_selected_evidence(thesis: Dictionary) -> void:
	selected_evidence_list.clear()
	for evidence_value in thesis.get("evidence", []):
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = evidence_value
		var index: int = selected_evidence_list.item_count
		selected_evidence_list.add_item("%s: %s  |  %s" % [str(row.get("category_label", row.get("category", ""))), str(row.get("label", "")), str(row.get("value", ""))])
		selected_evidence_list.set_item_metadata(index, str(row.get("id", "")))


func _refresh_evidence_discipline(thesis: Dictionary) -> void:
	if evidence_discipline_label == null:
		return
	if thesis.is_empty():
		evidence_discipline_label.text = "Evidence discipline: no active thesis."
		return

	var rows: Array = _evidence_discipline_rows(thesis)
	var complete_count: int = 0
	var row_labels: Array = []
	for row_value in rows:
		var row: Dictionary = row_value
		var complete: bool = bool(row.get("complete", false))
		if complete:
			complete_count += 1
		row_labels.append("%s %s" % [str(row.get("label", "")), "ready" if complete else "missing"])

	var next_gap: Dictionary = _next_evidence_gap(thesis)
	var next_line: String = "Core mix complete"
	if not next_gap.is_empty():
		next_line = "Next gap: %s" % str(next_gap.get("label", "Evidence"))
	evidence_discipline_label.text = "Evidence discipline: %d/%d pillars\n%s\n%s" % [
		complete_count,
		rows.size(),
		" | ".join(row_labels),
		next_line
	]


func _refresh_report(thesis: Dictionary) -> void:
	var review: Dictionary = thesis.get("review", {})
	if review.is_empty():
		review_state_label.text = "Review: generate a report first.\nThe white paper will freeze the current evidence, price, and date."
	else:
		review_state_label.text = "Review: %s\n%s" % [str(review.get("state", "Needs Review")), str(review.get("summary", ""))]
	if thesis_white_paper_panel != null and thesis_white_paper_panel.visible:
		_populate_white_paper(thesis)


func _run_report_generation_flow() -> void:
	if selected_thesis_id.is_empty() or report_generation_running:
		return
	var target_thesis_id: String = selected_thesis_id
	report_generation_running = true
	_refresh_selected_thesis()
	_show_report_preparing(REPORT_PREPARE_LINES[0])
	await get_tree().create_timer(REPORT_PREPARE_STEP_SECONDS).timeout
	if not report_generation_running:
		return
	_show_report_preparing(REPORT_PREPARE_LINES[1])
	var result: Dictionary = {}
	suppress_thesis_changed_refresh = true
	result = GameManager.generate_thesis_report(target_thesis_id)
	suppress_thesis_changed_refresh = false
	_set_status(str(result.get("message", "")))
	await get_tree().create_timer(REPORT_PREPARE_STEP_SECONDS).timeout
	if not report_generation_running:
		return
	_show_report_preparing(REPORT_PREPARE_LINES[2])
	await get_tree().create_timer(REPORT_PREPARE_STEP_SECONDS).timeout
	selected_thesis_id = target_thesis_id
	board_snapshot = GameManager.get_thesis_board_snapshot()
	report_generation_running = false
	_refresh_thesis_list()
	_refresh_selected_thesis()
	if bool(result.get("success", false)):
		_show_white_paper(_selected_thesis())
	else:
		_show_report_error(str(result.get("message", "Could not generate report.")))


func _show_report_preparing(message: String) -> void:
	if report_overlay == null:
		return
	report_overlay.visible = true
	report_overlay.move_to_front()
	if report_preparing_panel != null:
		report_preparing_panel.visible = true
	if thesis_white_paper_panel != null:
		thesis_white_paper_panel.visible = false
	if report_preparing_label != null:
		report_preparing_label.text = message
	if report_prepare_close_button != null:
		report_prepare_close_button.visible = false


func _show_report_error(message: String) -> void:
	_show_report_preparing("Report generation failed.\n\n%s" % message)
	report_generation_running = false
	if report_prepare_close_button != null:
		report_prepare_close_button.visible = true
	_refresh_selected_thesis()


func _show_white_paper(thesis: Dictionary) -> void:
	if thesis.is_empty() or thesis.get("report", {}).is_empty():
		_set_status("Generate a report before viewing the white paper.")
		return
	if report_overlay == null:
		return
	report_overlay.visible = true
	report_overlay.move_to_front()
	if report_preparing_panel != null:
		report_preparing_panel.visible = false
	if thesis_white_paper_panel != null:
		thesis_white_paper_panel.visible = true
	_populate_white_paper(thesis)
	_refresh_selected_thesis()


func _populate_white_paper(thesis: Dictionary) -> void:
	var report: Dictionary = thesis.get("report", {})
	if report.is_empty():
		return
	if report_header_label != null:
		report_header_label.text = "%s - %s" % [str(report.get("ticker", "")), str(report.get("company_name", ""))]
	if report_meta_label != null:
		report_meta_label.text = "%s  |  %s  |  %s  |  Recommendation: %s" % [
			str(report.get("generated_date_label", "")),
			str(report.get("sector_name", "")),
			str(report.get("horizon", "")).capitalize(),
			str(report.get("rating", ""))
		]
	if report_badge_label != null:
		report_badge_label.text = "WHITE PAPER  |  Generated Research Note"
	if report_text != null:
		report_text.text = _format_report_text(thesis)
	if report_footer_label != null:
		report_footer_label.text = "Frozen at %s on day %d. Report price %s." % [
			str(report.get("generated_date_label", "")),
			int(report.get("generated_day_index", 0)),
			_format_currency(float(report.get("report_price", 0.0)))
		]


func _hide_report_overlay() -> void:
	if report_generation_running:
		return
	if report_overlay != null:
		report_overlay.visible = false


func _format_report_text(thesis: Dictionary) -> String:
	var report: Dictionary = thesis.get("report", {})
	if report.is_empty():
		return "No generated report yet.\n\nAdd evidence, then press Generate Report. The report will freeze the current price, date, evidence, and recommendation."
	var lines: Array = []
	lines.append("[b]%s - %s[/b]" % [_bbcode_escape(str(report.get("ticker", ""))), _bbcode_escape(str(report.get("company_name", "")))])
	lines.append("[color=#665f4d]%s | %s | %s[/color]" % [_bbcode_escape(str(report.get("generated_date_label", ""))), _bbcode_escape(str(report.get("sector_name", ""))), _bbcode_escape(str(report.get("horizon", "")).capitalize())])
	lines.append("")
	lines.append("[b]Recommendation:[/b] %s" % _bbcode_escape(str(report.get("rating", ""))))
	lines.append("[b]Reasoning Grade:[/b] %s" % _bbcode_escape(str(report.get("reasoning_grade", ""))))
	lines.append("[b]Report Price:[/b] %s" % _bbcode_escape(_format_currency(float(report.get("report_price", 0.0)))))
	lines.append("[b]Target Area:[/b] %s" % _bbcode_escape(str(report.get("target", {}).get("label", ""))))
	lines.append("[b]Implied Move:[/b] %s" % _bbcode_escape(_format_percent(float(report.get("implied_upside_pct", 0.0)))))
	lines.append("")
	for section_value in report.get("sections", []):
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		lines.append("[u][b]%s[/b][/u]" % _bbcode_escape(str(section.get("title", "")).to_upper()))
		var bullets: Array = section.get("bullets", [])
		if not bullets.is_empty():
			for bullet_value in bullets:
				if typeof(bullet_value) != TYPE_DICTIONARY:
					continue
				var bullet: Dictionary = bullet_value
				lines.append("- [b]%s.[/b] %s" % [
					_bbcode_escape(str(bullet.get("claim", ""))),
					_bbcode_escape(str(bullet.get("body", "")))
				])
		else:
			lines.append(_bbcode_escape(str(section.get("body", ""))))
		lines.append("")
	return "\n".join(lines)


func _bbcode_escape(value: String) -> String:
	return value.replace("[", "(").replace("]", ")")


func _on_thesis_changed() -> void:
	if suppress_thesis_changed_refresh:
		return
	refresh()


func _on_thesis_selected(index: int) -> void:
	selected_thesis_id = str(thesis_list.get_item_metadata(index))
	_refresh_selected_thesis()


func _on_use_selected_stock_pressed() -> void:
	if selected_external_company_id.is_empty():
		_set_status("No STOCKBOT stock is selected yet.")
		return
	_select_company_option(selected_external_company_id)
	_set_status("Selected stock loaded into the Thesis form.")


func _on_create_thesis_pressed() -> void:
	var result: Dictionary = GameManager.create_thesis(_selected_company_id(), _selected_option_id(stance_option), _selected_option_id(horizon_option), title_edit.text)
	_set_status(str(result.get("message", "")))
	if bool(result.get("success", false)):
		selected_thesis_id = str(result.get("thesis", {}).get("id", ""))
		refresh()


func _on_update_thesis_pressed() -> void:
	if selected_thesis_id.is_empty():
		return
	var result: Dictionary = GameManager.update_thesis_meta(selected_thesis_id, {
		"title": title_edit.text,
		"stance": _selected_option_id(stance_option),
		"horizon": _selected_option_id(horizon_option)
	})
	_set_status(str(result.get("message", "")))


func _on_evidence_category_selected(_index: int) -> void:
	_refresh_evidence_option_picker()


func _on_evidence_option_selected(_index: int) -> void:
	_refresh_evidence_detail()


func _on_add_evidence_pressed() -> void:
	if selected_thesis_id.is_empty():
		return
	var result: Dictionary = GameManager.add_thesis_evidence(selected_thesis_id, _selected_evidence_option())
	_set_status(str(result.get("message", "")))


func _on_remove_evidence_pressed() -> void:
	if selected_thesis_id.is_empty() or selected_evidence_list.get_selected_items().is_empty():
		return
	var index: int = int(selected_evidence_list.get_selected_items()[0])
	var result: Dictionary = GameManager.remove_thesis_evidence(selected_thesis_id, str(selected_evidence_list.get_item_metadata(index)))
	_set_status(str(result.get("message", "")))


func _on_generate_report_pressed() -> void:
	if selected_thesis_id.is_empty():
		return
	_run_report_generation_flow()


func _on_view_paper_pressed() -> void:
	_show_white_paper(_selected_thesis())


func _on_regenerate_report_pressed() -> void:
	if selected_thesis_id.is_empty():
		return
	_run_report_generation_flow()


func _on_refresh_review_pressed() -> void:
	if selected_thesis_id.is_empty():
		return
	var result: Dictionary = GameManager.refresh_thesis_review(selected_thesis_id)
	_set_status(str(result.get("message", "")))


func _on_close_thesis_pressed() -> void:
	if selected_thesis_id.is_empty():
		return
	var result: Dictionary = GameManager.close_thesis(selected_thesis_id)
	_set_status(str(result.get("message", "")))


func _selected_thesis() -> Dictionary:
	for thesis_value in board_snapshot.get("theses", []):
		if typeof(thesis_value) == TYPE_DICTIONARY and str(thesis_value.get("id", "")) == selected_thesis_id:
			return thesis_value
	return {}


func _selected_company_id() -> String:
	if company_option == null or company_option.item_count <= 0:
		return ""
	var selected_index: int = company_option.selected
	if selected_index < 0:
		selected_index = 0
	return str(company_option.get_item_metadata(selected_index))


func _selected_category() -> Dictionary:
	if evidence_category_option == null or evidence_category_option.item_count <= 0:
		return {}
	var selected_index: int = max(evidence_category_option.selected, 0)
	return evidence_category_option.get_item_metadata(selected_index)


func _selected_evidence_option() -> Dictionary:
	if evidence_option == null or evidence_option.item_count <= 0:
		return {}
	var selected_index: int = max(evidence_option.selected, 0)
	return evidence_option.get_item_metadata(selected_index)


func _selected_option_id(option: OptionButton) -> String:
	if option == null or option.item_count <= 0:
		return ""
	var selected_index: int = max(option.selected, 0)
	return str(option.get_item_metadata(selected_index))


func _select_company_option(company_id: String) -> void:
	if company_id.is_empty() or company_option == null:
		return
	for index in range(company_option.item_count):
		if str(company_option.get_item_metadata(index)) == company_id:
			company_option.select(index)
			return


func _select_option_by_id(option: OptionButton, option_id: String) -> void:
	if option == null:
		return
	for index in range(option.item_count):
		if str(option.get_item_metadata(index)) == option_id:
			option.select(index)
			return


func _evidence_discipline_rows(thesis: Dictionary) -> Array:
	var categories: Dictionary = _thesis_category_lookup(thesis)
	var rows: Array = []
	for pillar_value in EVIDENCE_DISCIPLINE_PILLARS:
		var pillar: Dictionary = pillar_value
		rows.append({
			"id": str(pillar.get("id", "")),
			"label": str(pillar.get("label", "")),
			"focus_category": str(pillar.get("focus_category", "")),
			"complete": _pillar_complete(categories, pillar.get("categories", []))
		})
	return rows


func _next_evidence_gap(thesis: Dictionary) -> Dictionary:
	for row_value in _evidence_discipline_rows(thesis):
		var row: Dictionary = row_value
		if not bool(row.get("complete", false)):
			return row
	return {}


func _thesis_category_lookup(thesis: Dictionary) -> Dictionary:
	var categories: Dictionary = {}
	for evidence_value in thesis.get("evidence", []):
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = evidence_value
		var category: String = str(row.get("category", ""))
		if not category.is_empty():
			categories[category] = true
	return categories


func _pillar_complete(categories: Dictionary, category_ids: Array) -> bool:
	for category_id_value in category_ids:
		if categories.has(str(category_id_value)):
			return true
	return false


func _add_option_items(option: OptionButton, items: Array) -> void:
	for item_value in items:
		var item: Dictionary = item_value
		var index: int = option.item_count
		option.add_item(str(item.get("label", "")))
		option.set_item_metadata(index, str(item.get("id", "")))


func _set_status(text: String) -> void:
	status_label.text = text


func _make_panel(panel_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
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
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = box_name
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	return vbox


func _make_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	_style_label(label, COLOR_BROWN, 16)
	return label


func _style_label(label: Label, color: Color, size: int) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)


func _style_rich_text(text_node: RichTextLabel) -> void:
	text_node.add_theme_color_override("default_color", COLOR_TEXT)
	text_node.add_theme_font_size_override("normal_font_size", 12)
	text_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_node.size_flags_vertical = Control.SIZE_EXPAND_FILL


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


func _format_currency(value: float) -> String:
	var sign_prefix: String = "-" if value < 0.0 else ""
	var abs_value: float = abs(value)
	if abs_value >= 1000000000000.0:
		return "%sRp%sT" % [sign_prefix, String.num(abs_value / 1000000000000.0, 2)]
	if abs_value >= 1000000000.0:
		return "%sRp%sB" % [sign_prefix, String.num(abs_value / 1000000000.0, 2)]
	if abs_value >= 1000000.0:
		return "%sRp%sM" % [sign_prefix, String.num(abs_value / 1000000.0, 2)]
	return "%sRp%s" % [sign_prefix, String.num(abs_value, 2)]


func _format_percent(value: float) -> String:
	var sign_prefix: String = "+" if value > 0.0 else ""
	return "%s%s%%" % [sign_prefix, String.num(value * 100.0, 2)]
