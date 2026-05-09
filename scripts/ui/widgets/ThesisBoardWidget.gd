extends MarginContainer

const COLOR_BG := Color(0.909804, 0.909804, 0.803922, 1)
const COLOR_PANEL := Color(0.972549, 0.94902, 0.847059, 1)
const COLOR_PANEL_ALT := Color(0.952941, 0.94902, 0.87451, 1)
const COLOR_BROWN := Color(0.509804, 0.231373, 0.0941176, 1)
const COLOR_TEXT := Color(0.184314, 0.172549, 0.109804, 1)
const COLOR_MUTED := Color(0.403922, 0.380392, 0.301961, 1)
const COLOR_BORDER := Color(0.52549, 0.396078, 0.160784, 1)
const COLOR_PAPER := Color(0.992157, 0.988235, 0.956863, 1)
const COLOR_MARKET_PAPER_CARD := Color(1.0, 0.976471, 0.929412, 1)
const COLOR_MARKET_PAPER_RAIL := Color(0.917647, 0.878431, 0.721569, 1)
const COLOR_MARKET_PAPER_BORDER := Color(0.52549, 0.396078, 0.160784, 1)
const COLOR_MARKET_PAPER_RED := Color(0.545098, 0.101961, 0.101961, 1)
const COLOR_POSITIVE := Color(0.184314, 0.482353, 0.298039, 1)
const COLOR_NEGATIVE := Color(0.65098, 0.247059, 0.219608, 1)
const COLOR_WARNING := Color(0.72549, 0.470588, 0.117647, 1)
const COLOR_REPORT_MAROON := Color(0.498039, 0.156863, 0.094118, 1)
const COLOR_REPORT_GOLD := Color(0.784314, 0.627451, 0.25098, 1)
const COLOR_REPORT_CREAM := Color(0.964706, 0.941176, 0.878431, 1)
const COLOR_REPORT_CREAM_ALT := Color(0.929412, 0.894118, 0.8, 1)
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
const STANCE_OPTIONS := [
	{"id": "bullish", "label": "Bullish"},
	{"id": "bearish", "label": "Bearish"},
	{"id": "income", "label": "Income"},
	{"id": "watch", "label": "Watch"}
]
const HORIZON_OPTIONS := [
	{"id": "swing", "label": "Swing"},
	{"id": "position", "label": "Position"},
	{"id": "income", "label": "Income"},
	{"id": "event", "label": "Event"}
]
const EVIDENCE_TABS := [
	{"id": "fundamental", "label": "Fundamental", "categories": ["fundamentals", "financials", "valuation", "ownership", "risk_invalidation"]},
	{"id": "technical", "label": "Technical", "categories": ["price_action", "broker_flow", "sector_macro"]},
	{"id": "news", "label": "News", "categories": ["news", "corporate_events", "network_intel"]},
	{"id": "social", "label": "Social", "categories": ["twooter"]}
]

var selected_external_company_id: String = ""
var selected_thesis_id: String = ""
var selected_stance_id: String = "bullish"
var selected_evidence_tab_id: String = "fundamental"
var board_snapshot: Dictionary = {}
var evidence_snapshot: Dictionary = {}
var suppress_thesis_changed_refresh: bool = false
var stance_buttons: Dictionary = {}
var evidence_tab_buttons: Dictionary = {}
var rendered_evidence_cards: Dictionary = {}

var status_label: Label = null
var sidebar_title_label: Label = null
var sidebar_meta_label: Label = null
var sidebar_evidence_label: Label = null
var sidebar_next_gap_label: Label = null
var sidebar_pip_row: HBoxContainer = null
var thesis_list: ItemList = null
var company_option: OptionButton = null
var title_edit: LineEdit = null
var stance_option: OptionButton = null
var horizon_option: OptionButton = null
var create_button: Button = null
var update_button: Button = null
var evidence_category_option: OptionButton = null
var evidence_option: OptionButton = null
var evidence_detail_label: Label = null
var evidence_discipline_label: Label = null
var evidence_card_grid: HFlowContainer = null
var evidence_chip_flow: HFlowContainer = null
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
var report_date_label: Label = null
var report_horizon_tag_label: Label = null
var report_stance_tag_label: Label = null
var report_recommendation_badge: PanelContainer = null
var report_recommendation_label: Label = null
var report_recommendation_sub_label: Label = null
var report_grade_ring_label: Label = null
var report_grade_title_label: Label = null
var report_grade_sub_label: Label = null
var report_implied_label: Label = null
var report_implied_sub_label: Label = null
var report_price_current_label: Label = null
var report_target_low_label: Label = null
var report_target_mid_label: Label = null
var report_target_high_label: Label = null
var report_investment_summary_label: Label = null
var report_sections_container: VBoxContainer = null
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

	sidebar_title_label = Label.new()
	sidebar_title_label.name = "ThesisSidebarTitleLabel"
	sidebar_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(sidebar_title_label, COLOR_TEXT, 16)
	left_vbox.add_child(sidebar_title_label)

	sidebar_meta_label = Label.new()
	sidebar_meta_label.name = "ThesisSidebarMetaLabel"
	sidebar_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(sidebar_meta_label, COLOR_MUTED, 12)
	left_vbox.add_child(sidebar_meta_label)

	sidebar_evidence_label = Label.new()
	sidebar_evidence_label.name = "ThesisSidebarEvidenceLabel"
	sidebar_evidence_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(sidebar_evidence_label, COLOR_TEXT, 13)
	left_vbox.add_child(sidebar_evidence_label)

	sidebar_pip_row = HBoxContainer.new()
	sidebar_pip_row.name = "ThesisSidebarPipRow"
	sidebar_pip_row.add_theme_constant_override("separation", 5)
	left_vbox.add_child(sidebar_pip_row)

	sidebar_next_gap_label = Label.new()
	sidebar_next_gap_label.name = "ThesisSidebarNextGapLabel"
	sidebar_next_gap_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(sidebar_next_gap_label, COLOR_MUTED, 12)
	left_vbox.add_child(sidebar_next_gap_label)

	thesis_list = ItemList.new()
	thesis_list.name = "ThesisList"
	thesis_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	thesis_list.item_selected.connect(_on_thesis_selected)
	left_vbox.add_child(thesis_list)

	var center_panel := _make_panel("ThesisBuilderPanel")
	center_panel.custom_minimum_size = Vector2(380, 0)
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(center_panel)
	var center_margin := MarginContainer.new()
	center_margin.name = "ThesisBuilderMargin"
	center_margin.add_theme_constant_override("margin_left", 12)
	center_margin.add_theme_constant_override("margin_top", 12)
	center_margin.add_theme_constant_override("margin_right", 12)
	center_margin.add_theme_constant_override("margin_bottom", 12)
	center_panel.add_child(center_margin)
	var center_scroll := ScrollContainer.new()
	center_scroll.name = "ThesisBuilderScroll"
	center_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	center_margin.add_child(center_scroll)
	var center_vbox := VBoxContainer.new()
	center_vbox.name = "ThesisBuilderVBox"
	center_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	center_vbox.add_theme_constant_override("separation", 8)
	center_scroll.add_child(center_vbox)
	center_vbox.add_child(_make_step_flow_row())
	center_vbox.add_child(_make_title("1 Build"))

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
	stance_option.visible = false
	_add_option_items(stance_option, STANCE_OPTIONS)
	meta_row.add_child(stance_option)
	var stance_row := HBoxContainer.new()
	stance_row.name = "ThesisStanceButtonRow"
	stance_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stance_row.add_theme_constant_override("separation", 6)
	meta_row.add_child(stance_row)
	for stance_value in STANCE_OPTIONS:
		var stance: Dictionary = stance_value
		var stance_button: Button = _make_stance_button(str(stance.get("id", "")), str(stance.get("label", "")))
		stance_row.add_child(stance_button)
		stance_buttons[str(stance.get("id", ""))] = stance_button
	horizon_option = OptionButton.new()
	horizon_option.name = "ThesisHorizonOption"
	_add_option_items(horizon_option, HORIZON_OPTIONS)
	meta_row.add_child(horizon_option)

	var create_row := HBoxContainer.new()
	create_row.name = "ThesisCreateRow"
	create_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_row.add_theme_constant_override("separation", 8)
	center_vbox.add_child(create_row)
	create_button = Button.new()
	create_button.name = "ThesisCreateButton"
	create_button.text = "Create"
	create_button.custom_minimum_size = Vector2(96, 34)
	create_button.pressed.connect(_on_create_thesis_pressed)
	create_row.add_child(create_button)
	update_button = Button.new()
	update_button.name = "ThesisUpdateButton"
	update_button.text = "Update"
	update_button.custom_minimum_size = Vector2(96, 34)
	update_button.pressed.connect(_on_update_thesis_pressed)
	create_row.add_child(update_button)

	center_vbox.add_child(_make_title("2 Add Evidence"))
	evidence_discipline_label = Label.new()
	evidence_discipline_label.name = "ThesisEvidenceDisciplineLabel"
	evidence_discipline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	evidence_discipline_label.custom_minimum_size = Vector2(0, 58)
	evidence_discipline_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(evidence_discipline_label, COLOR_MUTED, 12)
	center_vbox.add_child(evidence_discipline_label)

	var evidence_tab_row := HBoxContainer.new()
	evidence_tab_row.name = "ThesisEvidenceTabRow"
	evidence_tab_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	evidence_tab_row.add_theme_constant_override("separation", 12)
	center_vbox.add_child(evidence_tab_row)
	for tab_value in EVIDENCE_TABS:
		var tab: Dictionary = tab_value
		var tab_button: Button = _make_evidence_tab_button(str(tab.get("id", "")), str(tab.get("label", "")))
		evidence_tab_row.add_child(tab_button)
		evidence_tab_buttons[str(tab.get("id", ""))] = tab_button

	evidence_card_grid = HFlowContainer.new()
	evidence_card_grid.name = "ThesisEvidenceCardGrid"
	evidence_card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	evidence_card_grid.add_theme_constant_override("h_separation", 8)
	evidence_card_grid.add_theme_constant_override("v_separation", 8)
	center_vbox.add_child(evidence_card_grid)

	var chip_title := Label.new()
	chip_title.name = "ThesisEvidenceChipTitle"
	chip_title.text = "Board Chips"
	_style_label(chip_title, COLOR_BROWN, 14)
	center_vbox.add_child(chip_title)

	evidence_chip_flow = HFlowContainer.new()
	evidence_chip_flow.name = "ThesisEvidenceChipFlow"
	evidence_chip_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	evidence_chip_flow.add_theme_constant_override("h_separation", 6)
	evidence_chip_flow.add_theme_constant_override("v_separation", 6)
	center_vbox.add_child(evidence_chip_flow)

	evidence_category_option = OptionButton.new()
	evidence_category_option.name = "ThesisEvidenceCategoryOption"
	evidence_category_option.visible = false
	evidence_category_option.item_selected.connect(_on_evidence_category_selected)
	center_vbox.add_child(evidence_category_option)

	evidence_option = OptionButton.new()
	evidence_option.name = "ThesisEvidenceOption"
	evidence_option.visible = false
	evidence_option.item_selected.connect(_on_evidence_option_selected)
	center_vbox.add_child(evidence_option)

	evidence_detail_label = Label.new()
	evidence_detail_label.name = "ThesisEvidenceDetailLabel"
	evidence_detail_label.visible = false
	evidence_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	evidence_detail_label.custom_minimum_size = Vector2(0, 60)
	_style_label(evidence_detail_label, COLOR_MUTED, 12)
	center_vbox.add_child(evidence_detail_label)

	add_evidence_button = Button.new()
	add_evidence_button.name = "ThesisAddEvidenceButton"
	add_evidence_button.text = "Add Evidence"
	add_evidence_button.visible = false
	add_evidence_button.pressed.connect(_on_add_evidence_pressed)
	center_vbox.add_child(add_evidence_button)

	selected_evidence_list = ItemList.new()
	selected_evidence_list.name = "ThesisEvidenceList"
	selected_evidence_list.visible = false
	selected_evidence_list.custom_minimum_size = Vector2(0, 150)
	selected_evidence_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_vbox.add_child(selected_evidence_list)

	var evidence_actions := HBoxContainer.new()
	evidence_actions.name = "ThesisEvidenceActions"
	evidence_actions.visible = false
	evidence_actions.add_theme_constant_override("separation", 8)
	center_vbox.add_child(evidence_actions)
	remove_evidence_button = Button.new()
	remove_evidence_button.name = "ThesisRemoveEvidenceButton"
	remove_evidence_button.text = "Remove Selected"
	remove_evidence_button.pressed.connect(_on_remove_evidence_pressed)
	evidence_actions.add_child(remove_evidence_button)

	center_vbox.add_child(_make_title("3 Review"))
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
	generate_report_button = Button.new()
	generate_report_button.name = "ThesisGenerateReportButton"
	generate_report_button.text = "Generate Report (%d AP)" % GameManager.get_thesis_report_action_cost()
	generate_report_button.pressed.connect(_on_generate_report_pressed)
	report_actions.add_child(generate_report_button)
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
	thesis_white_paper_panel.custom_minimum_size = Vector2(860, 650)
	thesis_white_paper_panel.visible = false
	thesis_white_paper_panel.add_theme_stylebox_override("panel", _make_stylebox(_theme_color("desktop.cream", COLOR_REPORT_CREAM), _theme_color("desktop.frame", Color(0.70, 0.63, 0.46, 1)), 1))
	center.add_child(thesis_white_paper_panel)

	var page_scroll := ScrollContainer.new()
	page_scroll.name = "ThesisWhitePaperPageScroll"
	page_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	thesis_white_paper_panel.add_child(page_scroll)

	var paper_vbox := VBoxContainer.new()
	paper_vbox.name = "ThesisWhitePaperVBox"
	paper_vbox.custom_minimum_size = Vector2(820, 0)
	paper_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paper_vbox.add_theme_constant_override("separation", 0)
	page_scroll.add_child(paper_vbox)

	var masthead := PanelContainer.new()
	masthead.name = "ThesisWhitePaperMasthead"
	masthead.add_theme_stylebox_override("panel", _make_stylebox(_theme_color("desktop.brown", COLOR_REPORT_MAROON), _theme_color("desktop.brown", COLOR_REPORT_MAROON), 0))
	paper_vbox.add_child(masthead)
	var mast_vbox := VBoxContainer.new()
	mast_vbox.name = "ThesisWhitePaperMastheadVBox"
	mast_vbox.add_theme_constant_override("separation", 0)
	masthead.add_child(mast_vbox)

	var mast_top := HBoxContainer.new()
	mast_top.name = "ThesisWhitePaperMastTop"
	mast_top.add_theme_constant_override("separation", 10)
	mast_vbox.add_child(mast_top)
	var mast_top_margin := MarginContainer.new()
	mast_top_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mast_top_margin.add_theme_constant_override("margin_left", 18)
	mast_top_margin.add_theme_constant_override("margin_top", 9)
	mast_top_margin.add_theme_constant_override("margin_right", 18)
	mast_top_margin.add_theme_constant_override("margin_bottom", 8)
	mast_top.add_child(mast_top_margin)
	var mast_top_row := HBoxContainer.new()
	mast_top_row.add_theme_constant_override("separation", 12)
	mast_top_margin.add_child(mast_top_row)
	var mast_copy := VBoxContainer.new()
	mast_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mast_copy.add_theme_constant_override("separation", 0)
	mast_top_row.add_child(mast_copy)
	report_badge_label = Label.new()
	report_badge_label.name = "ThesisWhitePaperBadgeLabel"
	report_badge_label.text = "GENERATED RESEARCH NOTE"
	_style_label(report_badge_label, Color(0.78, 0.63, 0.25, 0.72), 9)
	mast_copy.add_child(report_badge_label)
	var mast_type_label := Label.new()
	mast_type_label.name = "ThesisWhitePaperTypeLabel"
	mast_type_label.text = "WHITE PAPER"
	_style_label(mast_type_label, COLOR_REPORT_GOLD.lightened(0.12), 12)
	mast_copy.add_child(mast_type_label)

	var overlay_actions := HBoxContainer.new()
	overlay_actions.name = "ThesisWhitePaperActions"
	overlay_actions.add_theme_constant_override("separation", 6)
	mast_top_row.add_child(overlay_actions)
	report_refresh_review_button = Button.new()
	report_refresh_review_button.name = "ThesisReportOverlayRefreshReviewButton"
	report_refresh_review_button.text = "Refresh Review"
	report_refresh_review_button.custom_minimum_size = Vector2(128, 34)
	report_refresh_review_button.set_meta("skip_thesis_style", true)
	report_refresh_review_button.pressed.connect(_on_refresh_review_pressed)
	_style_report_action_button(report_refresh_review_button, "outline")
	overlay_actions.add_child(report_refresh_review_button)
	report_regenerate_button = Button.new()
	report_regenerate_button.name = "ThesisReportRegenerateButton"
	report_regenerate_button.text = "Regenerate (%d AP)" % GameManager.get_thesis_report_action_cost()
	report_regenerate_button.custom_minimum_size = Vector2(142, 34)
	report_regenerate_button.set_meta("skip_thesis_style", true)
	report_regenerate_button.pressed.connect(_on_regenerate_report_pressed)
	_style_report_action_button(report_regenerate_button, "gold")
	overlay_actions.add_child(report_regenerate_button)
	report_close_button = Button.new()
	report_close_button.name = "ThesisReportCloseButton"
	report_close_button.text = "X"
	report_close_button.custom_minimum_size = Vector2(38, 30)
	report_close_button.set_meta("skip_thesis_style", true)
	report_close_button.pressed.connect(_hide_report_overlay)
	_style_report_action_button(report_close_button, "quiet")
	overlay_actions.add_child(report_close_button)

	var mast_rule := ColorRect.new()
	mast_rule.name = "ThesisWhitePaperMastRule"
	mast_rule.color = Color(COLOR_REPORT_GOLD.r, COLOR_REPORT_GOLD.g, COLOR_REPORT_GOLD.b, 0.28)
	mast_rule.custom_minimum_size = Vector2(0, 1)
	mast_vbox.add_child(mast_rule)

	var mast_body_margin := MarginContainer.new()
	mast_body_margin.add_theme_constant_override("margin_left", 18)
	mast_body_margin.add_theme_constant_override("margin_top", 13)
	mast_body_margin.add_theme_constant_override("margin_right", 18)
	mast_body_margin.add_theme_constant_override("margin_bottom", 14)
	mast_vbox.add_child(mast_body_margin)
	var mast_body := HBoxContainer.new()
	mast_body.name = "ThesisWhitePaperMastBody"
	mast_body.add_theme_constant_override("separation", 12)
	mast_body_margin.add_child(mast_body)
	var stock_copy := VBoxContainer.new()
	stock_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stock_copy.add_theme_constant_override("separation", 0)
	mast_body.add_child(stock_copy)
	report_header_label = Label.new()
	report_header_label.name = "ThesisWhitePaperHeaderLabel"
	report_header_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(report_header_label, Color.WHITE, 28)
	stock_copy.add_child(report_header_label)
	report_meta_label = Label.new()
	report_meta_label.name = "ThesisWhitePaperMetaLabel"
	report_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(report_meta_label, Color(1.0, 1.0, 1.0, 0.72), 13)
	stock_copy.add_child(report_meta_label)

	var mast_side := VBoxContainer.new()
	mast_side.alignment = BoxContainer.ALIGNMENT_END
	mast_side.add_theme_constant_override("separation", 5)
	mast_body.add_child(mast_side)
	report_date_label = Label.new()
	report_date_label.name = "ThesisWhitePaperDateLabel"
	report_date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_label(report_date_label, Color(COLOR_REPORT_GOLD.r, COLOR_REPORT_GOLD.g, COLOR_REPORT_GOLD.b, 0.82), 10)
	mast_side.add_child(report_date_label)
	var tag_row := HBoxContainer.new()
	tag_row.name = "ThesisWhitePaperTagRow"
	tag_row.add_theme_constant_override("separation", 5)
	mast_side.add_child(tag_row)
	report_horizon_tag_label = _make_report_tag_label("Swing")
	tag_row.add_child(report_horizon_tag_label)
	report_stance_tag_label = _make_report_tag_label("Bullish")
	tag_row.add_child(report_stance_tag_label)

	var gold_rule := ColorRect.new()
	gold_rule.name = "ThesisWhitePaperGoldRule"
	gold_rule.color = COLOR_REPORT_GOLD
	gold_rule.custom_minimum_size = Vector2(0, 3)
	paper_vbox.add_child(gold_rule)

	var summary_row := HBoxContainer.new()
	summary_row.name = "ThesisWhitePaperSummaryRow"
	summary_row.custom_minimum_size = Vector2(0, 112)
	summary_row.add_theme_constant_override("separation", 0)
	paper_vbox.add_child(summary_row)
	var recommendation_cell_wrap := _make_report_summary_cell("Recommendation")
	summary_row.add_child(recommendation_cell_wrap)
	var recommendation_cell := recommendation_cell_wrap.get_node("Inner") as VBoxContainer
	report_recommendation_badge = PanelContainer.new()
	report_recommendation_badge.name = "ThesisWhitePaperRecommendationBadge"
	report_recommendation_badge.custom_minimum_size = Vector2(0, 28)
	recommendation_cell.add_child(report_recommendation_badge)
	report_recommendation_label = Label.new()
	report_recommendation_label.name = "ThesisWhitePaperRecommendationLabel"
	report_recommendation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	report_recommendation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(report_recommendation_label, COLOR_TEXT, 13)
	report_recommendation_badge.add_child(report_recommendation_label)
	report_recommendation_sub_label = Label.new()
	report_recommendation_sub_label.name = "ThesisWhitePaperRecommendationSubLabel"
	report_recommendation_sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(report_recommendation_sub_label, COLOR_MUTED, 11)
	recommendation_cell.add_child(report_recommendation_sub_label)

	var grade_cell_wrap := _make_report_summary_cell("Thesis Quality Grade")
	summary_row.add_child(grade_cell_wrap)
	var grade_cell := grade_cell_wrap.get_node("Inner") as VBoxContainer
	var grade_row := HBoxContainer.new()
	grade_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grade_row.add_theme_constant_override("separation", 10)
	grade_cell.add_child(grade_row)
	var grade_ring := PanelContainer.new()
	grade_ring.custom_minimum_size = Vector2(46, 46)
	grade_ring.add_theme_stylebox_override("panel", _make_rounded_stylebox(COLOR_REPORT_CREAM, COLOR_REPORT_MAROON.lightened(0.15), 2, 19))
	grade_row.add_child(grade_ring)
	report_grade_ring_label = Label.new()
	report_grade_ring_label.name = "ThesisWhitePaperGradeRingLabel"
	report_grade_ring_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	report_grade_ring_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(report_grade_ring_label, COLOR_REPORT_MAROON.lightened(0.15), 16)
	grade_ring.add_child(report_grade_ring_label)
	var grade_copy := VBoxContainer.new()
	grade_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grade_copy.add_theme_constant_override("separation", 0)
	grade_row.add_child(grade_copy)
	report_grade_title_label = Label.new()
	report_grade_title_label.name = "ThesisWhitePaperGradeTitleLabel"
	_style_label(report_grade_title_label, COLOR_REPORT_MAROON.lightened(0.12), 13)
	grade_copy.add_child(report_grade_title_label)
	report_grade_sub_label = Label.new()
	report_grade_sub_label.name = "ThesisWhitePaperGradeSubLabel"
	report_grade_sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(report_grade_sub_label, COLOR_MUTED, 11)
	grade_copy.add_child(report_grade_sub_label)

	var implied_cell_wrap := _make_report_summary_cell("Implied Move")
	summary_row.add_child(implied_cell_wrap)
	var implied_cell := implied_cell_wrap.get_node("Inner") as VBoxContainer
	report_implied_label = Label.new()
	report_implied_label.name = "ThesisWhitePaperImpliedLabel"
	_style_label(report_implied_label, COLOR_POSITIVE, 22)
	implied_cell.add_child(report_implied_label)
	report_implied_sub_label = Label.new()
	report_implied_sub_label.name = "ThesisWhitePaperImpliedSubLabel"
	report_implied_sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(report_implied_sub_label, COLOR_MUTED, 11)
	implied_cell.add_child(report_implied_sub_label)

	var price_panel := PanelContainer.new()
	price_panel.name = "ThesisWhitePaperPricePanel"
	price_panel.add_theme_stylebox_override("panel", _make_stylebox(_theme_color("desktop.panel", COLOR_REPORT_CREAM_ALT), _theme_color("desktop.frame", Color(0.78, 0.70, 0.52, 1)), 0))
	paper_vbox.add_child(price_panel)
	var price_margin := MarginContainer.new()
	price_margin.add_theme_constant_override("margin_left", 18)
	price_margin.add_theme_constant_override("margin_top", 13)
	price_margin.add_theme_constant_override("margin_right", 18)
	price_margin.add_theme_constant_override("margin_bottom", 14)
	price_panel.add_child(price_margin)
	var price_vbox := VBoxContainer.new()
	price_vbox.add_theme_constant_override("separation", 10)
	price_margin.add_child(price_vbox)
	var price_title := _make_report_caption_label("Price Target Range")
	price_vbox.add_child(price_title)
	var price_row := HBoxContainer.new()
	price_row.add_theme_constant_override("separation", 12)
	price_vbox.add_child(price_row)
	var price_key := _make_report_caption_label("Current Price")
	price_key.custom_minimum_size = Vector2(100, 0)
	price_row.add_child(price_key)
	report_price_current_label = Label.new()
	report_price_current_label.name = "ThesisWhitePaperCurrentPriceLabel"
	report_price_current_label.custom_minimum_size = Vector2(88, 0)
	_style_label(report_price_current_label, COLOR_TEXT, 15)
	price_row.add_child(report_price_current_label)
	price_row.add_child(_make_report_badge_label("Report Price", COLOR_POSITIVE))
	var range_cards := HBoxContainer.new()
	range_cards.name = "ThesisWhitePaperRangeCards"
	range_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	range_cards.add_theme_constant_override("separation", 8)
	price_vbox.add_child(range_cards)
	report_target_low_label = _make_report_range_card_label()
	report_target_mid_label = _make_report_range_card_label()
	report_target_high_label = _make_report_range_card_label()
	range_cards.add_child(report_target_low_label)
	range_cards.add_child(report_target_mid_label)
	range_cards.add_child(report_target_high_label)
	var summary_panel := PanelContainer.new()
	summary_panel.name = "ThesisWhitePaperInvestmentSummary"
	summary_panel.add_theme_stylebox_override(
		"panel",
		_make_padded_rounded_stylebox(
			_theme_color("desktop.cream", COLOR_REPORT_CREAM),
			_theme_color("desktop.frame", Color(0.78, 0.70, 0.52, 1)),
			1,
			3,
			{"left": 12, "top": 9, "right": 12, "bottom": 9}
		)
	)
	price_vbox.add_child(summary_panel)
	report_investment_summary_label = Label.new()
	report_investment_summary_label.name = "ThesisWhitePaperInvestmentSummaryLabel"
	report_investment_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	report_investment_summary_label.add_theme_constant_override("line_spacing", 2)
	_style_label(report_investment_summary_label, COLOR_TEXT, 13)
	summary_panel.add_child(report_investment_summary_label)

	var body_margin := MarginContainer.new()
	body_margin.name = "ThesisWhitePaperBodyMargin"
	body_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 18)
	body_margin.add_theme_constant_override("margin_top", 16)
	body_margin.add_theme_constant_override("margin_right", 18)
	body_margin.add_theme_constant_override("margin_bottom", 16)
	paper_vbox.add_child(body_margin)
	report_sections_container = VBoxContainer.new()
	report_sections_container.name = "ThesisWhitePaperSections"
	report_sections_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_sections_container.add_theme_constant_override("separation", 0)
	body_margin.add_child(report_sections_container)

	var footer_panel := PanelContainer.new()
	footer_panel.name = "ThesisWhitePaperFooterPanel"
	footer_panel.add_theme_stylebox_override("panel", _make_stylebox(COLOR_REPORT_CREAM_ALT, COLOR_REPORT_MAROON, 2))
	paper_vbox.add_child(footer_panel)
	var footer_margin := MarginContainer.new()
	footer_margin.add_theme_constant_override("margin_left", 18)
	footer_margin.add_theme_constant_override("margin_top", 9)
	footer_margin.add_theme_constant_override("margin_right", 18)
	footer_margin.add_theme_constant_override("margin_bottom", 9)
	footer_panel.add_child(footer_margin)
	report_footer_label = Label.new()
	report_footer_label.name = "ThesisWhitePaperFooterLabel"
	report_footer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(report_footer_label, COLOR_MUTED, 11)
	footer_margin.add_child(report_footer_label)

	report_text = RichTextLabel.new()
	report_text.name = "ThesisReportText"
	report_text.visible = false
	report_text.fit_content = true
	report_text.scroll_active = false
	report_text.selection_enabled = true
	report_text.bbcode_enabled = true
	_style_rich_text(report_text)
	paper_vbox.add_child(report_text)


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
	var report_action_cost: int = GameManager.get_thesis_report_action_cost()
	var remaining_ap: int = int(GameManager.get_daily_action_snapshot().get("remaining", 0))
	var can_generate_report: bool = has_thesis and not report_generation_running and remaining_ap >= report_action_cost
	update_button.disabled = not has_thesis or report_generation_running
	add_evidence_button.disabled = not has_thesis or report_generation_running
	remove_evidence_button.disabled = not has_thesis or report_generation_running
	generate_report_button.text = "Generate Report (%d AP)" % report_action_cost
	generate_report_button.disabled = not can_generate_report
	generate_report_button.tooltip_text = "Need %d AP to generate a Thesis report." % report_action_cost if remaining_ap < report_action_cost else "Generate a frozen research note."
	view_paper_button.disabled = not has_report or report_generation_running
	refresh_review_button.disabled = not has_report or report_generation_running
	close_thesis_button.disabled = not has_thesis or report_generation_running
	if report_refresh_review_button != null:
		report_refresh_review_button.disabled = not has_report or report_generation_running
	if report_regenerate_button != null:
		report_regenerate_button.text = "Regenerate (%d AP)" % report_action_cost
		report_regenerate_button.disabled = not can_generate_report
		report_regenerate_button.tooltip_text = "Need %d AP to regenerate this Thesis report." % report_action_cost if remaining_ap < report_action_cost else "Regenerate the frozen report with current evidence."
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
		_refresh_evidence_cards({})
		_refresh_evidence_chips({})
		_refresh_live_sidebar({})
		_refresh_stance_buttons()
		_refresh_evidence_tab_buttons()
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
	selected_stance_id = str(thesis.get("stance", "bullish"))
	_select_option_by_id(stance_option, selected_stance_id)
	_select_option_by_id(horizon_option, str(thesis.get("horizon", "swing")))
	_refresh_evidence_options(str(thesis.get("company_id", "")))
	_refresh_selected_evidence(thesis)
	_refresh_evidence_discipline(thesis)
	_refresh_stance_buttons()
	_refresh_evidence_tab_buttons()
	_refresh_evidence_cards(thesis)
	_refresh_evidence_chips(thesis)
	_refresh_live_sidebar(thesis)
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
	_refresh_evidence_tab_buttons()


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


func _refresh_evidence_cards(thesis: Dictionary) -> void:
	if evidence_card_grid == null:
		return
	_clear_children(evidence_card_grid)
	rendered_evidence_cards.clear()
	if thesis.is_empty():
		evidence_card_grid.add_child(_make_empty_evidence_label("Create a thesis first, then browse evidence cards here."))
		return
	var options: Array = _flatten_evidence_options_for_tab(selected_evidence_tab_id)
	if options.is_empty():
		evidence_card_grid.add_child(_make_empty_evidence_label("No current data in this evidence tab."))
		return
	for option_value in options:
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		var option_key: String = _evidence_option_key(option)
		if option_key.is_empty():
			continue
		rendered_evidence_cards[option_key] = option.duplicate(true)
		evidence_card_grid.add_child(_build_evidence_card(option, thesis))


func _refresh_evidence_chips(thesis: Dictionary) -> void:
	if evidence_chip_flow == null:
		return
	_clear_children(evidence_chip_flow)
	if thesis.is_empty():
		evidence_chip_flow.add_child(_make_empty_evidence_label("No active thesis."))
		return
	var evidence_rows: Array = thesis.get("evidence", [])
	if evidence_rows.is_empty():
		evidence_chip_flow.add_child(_make_empty_evidence_label("No evidence added yet."))
		return
	for evidence_value in evidence_rows:
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		evidence_chip_flow.add_child(_build_evidence_chip(evidence_value))


func _refresh_live_sidebar(thesis: Dictionary) -> void:
	if sidebar_title_label == null:
		return
	if thesis.is_empty():
		sidebar_title_label.text = "No Active Thesis"
		sidebar_meta_label.text = "Pick a stock and create a thesis."
		sidebar_evidence_label.text = "Evidence 0/5"
		sidebar_next_gap_label.text = "Next: build the opening claim."
		_refresh_sidebar_pips({})
		return

	sidebar_title_label.text = "%s\n%s" % [str(thesis.get("title", "Untitled thesis")), str(thesis.get("ticker", ""))]
	sidebar_meta_label.text = "%s | %s" % [
		str(thesis.get("stance", "watch")).capitalize(),
		str(thesis.get("horizon", "swing")).capitalize()
	]
	var rows: Array = _evidence_discipline_rows(thesis)
	var complete_count: int = 0
	for row_value in rows:
		if typeof(row_value) == TYPE_DICTIONARY and bool(row_value.get("complete", false)):
			complete_count += 1
	sidebar_evidence_label.text = "Evidence %d/%d" % [complete_count, rows.size()]
	var next_gap: Dictionary = _next_evidence_gap(thesis)
	sidebar_next_gap_label.text = "Next: %s evidence" % str(next_gap.get("label", "review the thesis")) if not next_gap.is_empty() else "Ready for review."
	_refresh_sidebar_pips(thesis)


func _refresh_sidebar_pips(thesis: Dictionary) -> void:
	if sidebar_pip_row == null:
		return
	_clear_children(sidebar_pip_row)
	var rows: Array = _evidence_discipline_rows(thesis) if not thesis.is_empty() else EVIDENCE_DISCIPLINE_PILLARS
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var complete: bool = bool(row.get("complete", false)) if row.has("complete") else false
		var pip := PanelContainer.new()
		pip.name = "ThesisSidebarPip%s" % _node_token(str(row.get("label", row.get("id", ""))))
		pip.custom_minimum_size = Vector2(42, 22)
		pip.tooltip_text = "%s evidence" % str(row.get("label", "Evidence"))
		pip.add_theme_stylebox_override("panel", _make_rounded_stylebox(
			COLOR_POSITIVE if complete else COLOR_PANEL_ALT,
			COLOR_POSITIVE if complete else Color(0.70, 0.63, 0.46, 1),
			1,
			8
		))
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text = str(row.get("label", "?")).substr(0, 1).to_upper()
		_style_label(label, COLOR_BG if complete else COLOR_MUTED, 11)
		pip.add_child(label)
		sidebar_pip_row.add_child(pip)


func _refresh_stance_buttons() -> void:
	for stance_id_value in stance_buttons.keys():
		var stance_id: String = str(stance_id_value)
		var button := stance_buttons.get(stance_id) as Button
		if button == null:
			continue
		var selected: bool = stance_id == selected_stance_id
		button.set_pressed_no_signal(selected)
		_style_segment_button(button, _stance_color(stance_id), selected)


func _refresh_evidence_tab_buttons() -> void:
	for tab_id_value in evidence_tab_buttons.keys():
		var tab_id: String = str(tab_id_value)
		var button := evidence_tab_buttons.get(tab_id) as Button
		if button == null:
			continue
		var selected: bool = tab_id == selected_evidence_tab_id
		button.set_pressed_no_signal(selected)
		_style_evidence_tab_button(button, selected, true)


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
		report_header_label.text = str(report.get("ticker", ""))
	if report_meta_label != null:
		report_meta_label.text = "%s - %s" % [str(report.get("company_name", "")), str(report.get("sector_name", ""))]
	if report_badge_label != null:
		report_badge_label.text = "GENERATED RESEARCH NOTE"
	if report_date_label != null:
		report_date_label.text = "%s // DAY %d" % [str(report.get("generated_date_label", "")).to_upper(), int(report.get("generated_day_index", 0)) + 1]
	if report_horizon_tag_label != null:
		report_horizon_tag_label.text = str(report.get("horizon", "")).capitalize()
	if report_stance_tag_label != null:
		report_stance_tag_label.text = str(report.get("stance", "")).capitalize()
	var rating: String = str(report.get("rating", ""))
	var implied_move: float = float(report.get("implied_upside_pct", 0.0))
	var rating_color: Color = _report_rating_color(rating, implied_move)
	if report_recommendation_badge != null:
		report_recommendation_badge.add_theme_stylebox_override("panel", _make_rounded_stylebox(_report_rating_bg_color(rating, implied_move), rating_color, 1, 0))
	if report_recommendation_label != null:
		report_recommendation_label.text = rating
		_style_label(report_recommendation_label, rating_color, 13)
	if report_recommendation_sub_label != null:
		report_recommendation_sub_label.text = _report_recommendation_subcopy(report)
	if report_grade_ring_label != null:
		report_grade_ring_label.text = str(report.get("reasoning_grade", ""))
	if report_grade_title_label != null:
		report_grade_title_label.text = _report_grade_title(str(report.get("reasoning_grade", "")))
	if report_grade_sub_label != null:
		report_grade_sub_label.text = _report_grade_subcopy(str(report.get("reasoning_grade", "")))
	if report_implied_label != null:
		report_implied_label.text = _format_percent(implied_move)
		_style_label(report_implied_label, _report_move_color(implied_move), 22)
	if report_implied_sub_label != null:
		report_implied_sub_label.text = "Report price %s" % _format_currency(float(report.get("report_price", 0.0)))
	if report_price_current_label != null:
		report_price_current_label.text = _format_currency(float(report.get("report_price", 0.0)))
	var target: Dictionary = report.get("target", {})
	if report_target_low_label != null:
		report_target_low_label.text = "REPORT PRICE\n%s" % _format_currency(float(report.get("report_price", 0.0)))
		report_target_low_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_report_range_card_label(report_target_low_label, COLOR_MUTED)
	if report_target_mid_label != null:
		report_target_mid_label.text = "LOW TARGET\n%s" % _format_currency(float(target.get("low", 0.0)))
		report_target_mid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_report_range_card_label(report_target_mid_label, _report_move_color(implied_move))
	if report_target_high_label != null:
		report_target_high_label.text = "HIGH TARGET\n%s" % _format_currency(float(target.get("high", 0.0)))
		report_target_high_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_report_range_card_label(report_target_high_label, _report_move_color(implied_move))
	if report_investment_summary_label != null:
		report_investment_summary_label.text = _investment_summary_for_report(report)
	_populate_white_paper_sections(report)
	if report_text != null:
		report_text.text = _format_report_text(thesis)
	if report_footer_label != null:
		report_footer_label.text = "THESIS BOARD // %s // FROZEN %s\nReport price %s - Day %d snapshot" % [
			str(report.get("ticker", "")),
			str(report.get("generated_date_label", "")),
			_format_currency(float(report.get("report_price", 0.0))),
			int(report.get("generated_day_index", 0)) + 1
		]


func _populate_white_paper_sections(report: Dictionary) -> void:
	if report_sections_container == null:
		return
	_clear_children(report_sections_container)
	for section_value in report.get("sections", []):
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		var section_title: String = str(section.get("title", "Investment Thesis"))
		report_sections_container.add_child(_make_report_section_rule(section_title))
		var bullets: Array = section.get("bullets", [])
		if bullets.is_empty():
			report_sections_container.add_child(_make_report_thesis_item(section_title, str(section.get("body", "")), _report_pills_for_text(section_title, str(section.get("body", "")), report)))
			continue
		for bullet_value in bullets:
			if typeof(bullet_value) != TYPE_DICTIONARY:
				continue
			var bullet: Dictionary = bullet_value
			var claim: String = str(bullet.get("claim", section_title))
			var body: String = str(bullet.get("body", ""))
			report_sections_container.add_child(_make_report_thesis_item(claim, body, _report_pills_for_text(claim, body, report)))


func _make_report_section_rule(title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "ThesisWhitePaperSectionRule%s" % _node_token(title)
	row.add_theme_constant_override("separation", 0)
	row.custom_minimum_size = Vector2(0, 28)
	var title_label := _make_report_caption_label(title)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(title_label, COLOR_REPORT_MAROON.lightened(0.12), 10)
	row.add_child(title_label)
	return row


func _make_report_thesis_item(key: String, body: String, pills: Array) -> VBoxContainer:
	var wrap := VBoxContainer.new()
	wrap.name = "ThesisWhitePaperItem%s" % _node_token(key)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 0)
	wrap.add_child(row)
	var key_margin := MarginContainer.new()
	key_margin.custom_minimum_size = Vector2(128, 0)
	key_margin.add_theme_constant_override("margin_left", 0)
	key_margin.add_theme_constant_override("margin_top", 7)
	key_margin.add_theme_constant_override("margin_right", 10)
	key_margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(key_margin)
	var key_label := Label.new()
	key_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	key_label.text = key.to_upper()
	_style_label(key_label, COLOR_MUTED, 10)
	key_margin.add_child(key_label)
	var separator := ColorRect.new()
	separator.color = Color(0.78, 0.70, 0.52, 1)
	separator.custom_minimum_size = Vector2(1, 0)
	row.add_child(separator)
	var value_margin := MarginContainer.new()
	value_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_margin.add_theme_constant_override("margin_left", 14)
	value_margin.add_theme_constant_override("margin_top", 7)
	value_margin.add_theme_constant_override("margin_right", 0)
	value_margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(value_margin)
	var value_vbox := VBoxContainer.new()
	value_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_vbox.add_theme_constant_override("separation", 5)
	value_margin.add_child(value_vbox)
	var body_label := Label.new()
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.text = body
	body_label.add_theme_constant_override("line_spacing", 2)
	_style_label(body_label, COLOR_TEXT, 13)
	value_vbox.add_child(body_label)
	var pill_row := HFlowContainer.new()
	pill_row.add_theme_constant_override("h_separation", 4)
	pill_row.add_theme_constant_override("v_separation", 4)
	value_vbox.add_child(pill_row)
	for pill_value in pills:
		if typeof(pill_value) != TYPE_DICTIONARY:
			continue
		var pill: Dictionary = pill_value
		pill_row.add_child(_make_report_pill(str(pill.get("text", "")), str(pill.get("tone", "neutral"))))
	var bottom_rule := ColorRect.new()
	bottom_rule.color = Color(0.87, 0.82, 0.70, 1)
	bottom_rule.custom_minimum_size = Vector2(0, 1)
	wrap.add_child(bottom_rule)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	wrap.add_child(spacer)
	return wrap


func _report_pills_for_text(key: String, body: String, report: Dictionary) -> Array:
	var rows: Array = []
	var key_lower: String = key.to_lower()
	var body_lower: String = body.to_lower()
	if key_lower.find("valuation") != -1 or body_lower.find("target") != -1 or body_lower.find("implied") != -1:
		rows.append({"text": _format_percent(float(report.get("implied_upside_pct", 0.0))), "tone": _report_tone_for_move(float(report.get("implied_upside_pct", 0.0)))})
	if body_lower.find("avoid") != -1 or body_lower.find("risk") != -1 or body_lower.find("negative") != -1 or body_lower.find("downside") != -1 or body_lower.find("distribution") != -1:
		rows.append({"text": "Risk Check", "tone": "negative"})
	elif body_lower.find("support") != -1 or body_lower.find("confirmed") != -1 or body_lower.find("complete") != -1 or body_lower.find("buy") != -1 or body_lower.find("accumulate") != -1:
		rows.append({"text": "Support", "tone": "positive"})
	else:
		rows.append({"text": "Monitor", "tone": "neutral"})
	if key_lower.find("recommendation") != -1 or body_lower.find(str(report.get("rating", "")).to_lower()) != -1:
		rows.append({"text": str(report.get("rating", "")), "tone": _report_tone_for_rating(str(report.get("rating", "")), float(report.get("implied_upside_pct", 0.0)))})
	return rows


func _make_report_summary_cell(title: String) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.name = "ThesisWhitePaperSummary%s" % _node_token(title)
	margin.custom_minimum_size = Vector2(248, 108)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	var inner := VBoxContainer.new()
	inner.name = "Inner"
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 5)
	margin.add_child(inner)
	inner.add_child(_make_report_caption_label(title))
	return margin


func _make_report_caption_label(text: String) -> Label:
	var label := Label.new()
	label.text = text.to_upper()
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style_label(label, COLOR_MUTED, 9)
	return label


func _make_report_tag_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(74, 24)
	label.add_theme_stylebox_override(
		"normal",
		_make_padded_rounded_stylebox(
			Color(0, 0, 0, 0),
			Color(COLOR_REPORT_GOLD.r, COLOR_REPORT_GOLD.g, COLOR_REPORT_GOLD.b, 0.36),
			1,
			0,
			{"left": 8, "top": 3, "right": 8, "bottom": 3}
		)
	)
	_style_label(label, Color(COLOR_REPORT_GOLD.r, COLOR_REPORT_GOLD.g, COLOR_REPORT_GOLD.b, 0.86), 10)
	return label


func _make_report_badge_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(104, 26)
	label.add_theme_stylebox_override(
		"normal",
		_make_padded_rounded_stylebox(
			Color(color.r, color.g, color.b, 0.12),
			color,
			1,
			0,
			{"left": 10, "top": 4, "right": 10, "bottom": 4}
		)
	)
	_style_label(label, color, 10)
	return label


func _make_report_pill(text: String, tone: String) -> PanelContainer:
	var color: Color = _report_tone_color(tone)
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _make_rounded_stylebox(Color(color.r, color.g, color.b, 0.12), Color(color.r, color.g, color.b, 0.36), 1, 0))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 4)
	pill.add_child(margin)
	var label := Label.new()
	label.text = text
	_style_label(label, color, 10)
	margin.add_child(label)
	return pill


func _make_report_range_dot(color: Color) -> CenterContainer:
	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(18, 18)
	var dot := PanelContainer.new()
	dot.custom_minimum_size = Vector2(10, 10)
	dot.add_theme_stylebox_override("panel", _make_rounded_stylebox(color, COLOR_REPORT_CREAM_ALT, 1, 5))
	center.add_child(dot)
	return center


func _make_report_range_line(color: Color) -> ColorRect:
	var line := ColorRect.new()
	line.color = color
	line.custom_minimum_size = Vector2(0, 3)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return line


func _make_report_range_card_label() -> Label:
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(190, 54)
	label.add_theme_constant_override("line_spacing", 2)
	_style_report_range_card_label(label, COLOR_MUTED)
	return label


func _style_report_range_card_label(label: Label, color: Color) -> void:
	var fill: Color = _theme_color("desktop.cream", COLOR_REPORT_CREAM)
	var border: Color = _theme_color("desktop.frame", Color(0.78, 0.70, 0.52, 1))
	label.add_theme_stylebox_override(
		"normal",
		_make_padded_rounded_stylebox(
			fill,
			border,
			1,
			3,
			{"left": 10, "top": 7, "right": 10, "bottom": 7}
		)
	)
	_style_label(label, color, 12)


func _style_report_action_button(button: Button, variant: String) -> void:
	var cream: Color = _theme_color("desktop.cream", COLOR_REPORT_CREAM)
	var gold: Color = _theme_color("desktop.gold", COLOR_REPORT_GOLD)
	var brown: Color = _theme_color("desktop.brown", COLOR_REPORT_MAROON)
	var text_color: Color = _theme_color("desktop.text", COLOR_TEXT)
	var bg: Color = Color(0, 0, 0, 0)
	var border: Color = Color(gold.r, gold.g, gold.b, 0.62)
	var font: Color = cream
	if variant == "gold":
		bg = gold
		border = gold
		font = text_color
	elif variant == "quiet":
		border = Color(gold.r, gold.g, gold.b, 0.36)
		font = cream
	button.add_theme_stylebox_override("normal", _make_rounded_stylebox(bg, border, 1, 4))
	button.add_theme_stylebox_override("hover", _make_rounded_stylebox(bg.lightened(0.08), border.lightened(0.15), 1, 4))
	button.add_theme_stylebox_override("pressed", _make_rounded_stylebox(bg.darkened(0.08), border, 1, 4))
	button.add_theme_stylebox_override("disabled", _make_rounded_stylebox(Color(brown.r, brown.g, brown.b, 0.18), Color(border.r, border.g, border.b, 0.40), 1, 4))
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font.lightened(0.15))
	button.add_theme_color_override("font_pressed_color", font)
	button.add_theme_color_override("font_disabled_color", Color(cream.r, cream.g, cream.b, 0.74))
	button.add_theme_font_size_override("font_size", _theme_font_size("button", 14))


func _report_recommendation_subcopy(report: Dictionary) -> String:
	var rating: String = str(report.get("rating", ""))
	var implied: float = float(report.get("implied_upside_pct", 0.0))
	match rating:
		"Buy":
			return "Conviction supports buying now."
		"Accumulate":
			return "Build gradually; avoid chasing spikes."
		"Hold":
			return "Existing holders can monitor risk."
		"Watchlist":
			return "No buy yet; wait for a cleaner setup."
		"Trade Only":
			return "Short-term setup only; keep size tight."
		"Dividend Hold":
			return "Income case can be held with risk checks."
		"Avoid":
			return "Downside or evidence risk outweighs entry."
	if implied < 0.0:
		return "Target sits below report price."
	return "Monitor for entry signal."


func _investment_summary_for_report(report: Dictionary) -> String:
	var target: Dictionary = report.get("target", {})
	var rating: String = str(report.get("rating", ""))
	var stance: String = str(report.get("stance", "")).capitalize()
	var horizon: String = str(report.get("horizon", "")).capitalize()
	var implied: float = float(report.get("implied_upside_pct", 0.0))
	var setup_note := _report_recommendation_subcopy(report)
	return "Investment summary: %s is a %s thesis over a %s horizon. Recommendation is %s, with a report price of %s, target range of %s - %s, and implied midpoint move of %s. %s" % [
		str(report.get("ticker", "")),
		stance,
		horizon,
		rating,
		_format_currency(float(report.get("report_price", 0.0))),
		_format_currency(float(target.get("low", 0.0))),
		_format_currency(float(target.get("high", 0.0))),
		_format_percent(implied),
		setup_note
	]


func _report_grade_title(grade: String) -> String:
	match grade:
		"A":
			return "Strong"
		"B":
			return "Good"
		"C":
			return "Developing"
		"D":
			return "Thin"
		_:
			return "Weak"


func _report_grade_subcopy(grade: String) -> String:
	match grade:
		"A":
			return "Well-supported thesis"
		"B":
			return "Good support, some gaps"
		"C":
			return "Needs cleaner evidence"
		"D":
			return "Thin evidence base"
		_:
			return "Weak or conflicted thesis"


func _report_rating_color(rating: String, implied: float) -> Color:
	return _report_tone_color(_report_tone_for_rating(rating, implied))


func _report_rating_bg_color(rating: String, implied: float) -> Color:
	var color: Color = _report_rating_color(rating, implied)
	return Color(color.r, color.g, color.b, 0.12)


func _report_move_color(value: float) -> Color:
	return COLOR_POSITIVE if value >= 0.0 else COLOR_NEGATIVE


func _report_tone_for_move(value: float) -> String:
	if value >= 0.04:
		return "positive"
	if value <= -0.03:
		return "negative"
	return "neutral"


func _report_tone_for_rating(rating: String, implied: float) -> String:
	match rating:
		"Buy", "Accumulate", "Dividend Hold":
			return "positive"
		"Avoid":
			return "negative"
		_:
			return _report_tone_for_move(implied)


func _report_tone_color(tone: String) -> Color:
	match tone:
		"positive":
			return COLOR_POSITIVE
		"negative":
			return COLOR_NEGATIVE
		_:
			return COLOR_WARNING


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
	lines.append("[b]Thesis Quality Grade:[/b] %s" % _bbcode_escape(str(report.get("reasoning_grade", ""))))
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


func _on_create_thesis_pressed() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	suppress_thesis_changed_refresh = true
	var result: Dictionary = GameManager.create_thesis(_selected_company_id(), selected_stance_id, _selected_option_id(horizon_option), title_edit.text)
	suppress_thesis_changed_refresh = false
	_set_status(str(result.get("message", "")))
	if bool(result.get("success", false)):
		selected_thesis_id = str(result.get("thesis", {}).get("id", ""))
		refresh()
	_log_perf_elapsed("_on_create_thesis_pressed", started_at_usec)


func _on_update_thesis_pressed() -> void:
	if selected_thesis_id.is_empty():
		return
	suppress_thesis_changed_refresh = true
	var result: Dictionary = GameManager.update_thesis_meta(selected_thesis_id, {
		"title": title_edit.text,
		"stance": selected_stance_id,
		"horizon": _selected_option_id(horizon_option)
	})
	suppress_thesis_changed_refresh = false
	_set_status(str(result.get("message", "")))
	if bool(result.get("success", false)):
		refresh()


func _on_evidence_category_selected(_index: int) -> void:
	_refresh_evidence_option_picker()


func _on_evidence_option_selected(_index: int) -> void:
	_refresh_evidence_detail()


func _on_add_evidence_pressed() -> void:
	if selected_thesis_id.is_empty():
		return
	suppress_thesis_changed_refresh = true
	var result: Dictionary = GameManager.add_thesis_evidence(selected_thesis_id, _selected_evidence_option())
	suppress_thesis_changed_refresh = false
	_set_status(str(result.get("message", "")))
	if bool(result.get("success", false)):
		refresh()


func _on_remove_evidence_pressed() -> void:
	if selected_thesis_id.is_empty() or selected_evidence_list.get_selected_items().is_empty():
		return
	var index: int = int(selected_evidence_list.get_selected_items()[0])
	suppress_thesis_changed_refresh = true
	var result: Dictionary = GameManager.remove_thesis_evidence(selected_thesis_id, str(selected_evidence_list.get_item_metadata(index)))
	suppress_thesis_changed_refresh = false
	_set_status(str(result.get("message", "")))
	if bool(result.get("success", false)):
		refresh()


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
	suppress_thesis_changed_refresh = true
	var result: Dictionary = GameManager.refresh_thesis_review(selected_thesis_id)
	suppress_thesis_changed_refresh = false
	_set_status(str(result.get("message", "")))
	if bool(result.get("success", false)):
		refresh()


func _on_close_thesis_pressed() -> void:
	if selected_thesis_id.is_empty():
		return
	suppress_thesis_changed_refresh = true
	var result: Dictionary = GameManager.close_thesis(selected_thesis_id)
	suppress_thesis_changed_refresh = false
	_set_status(str(result.get("message", "")))
	if bool(result.get("success", false)):
		refresh()


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


func _make_step_flow_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "ThesisStepFlowRow"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	row.add_child(_make_step_card("1", "Build", "Pick stock, stance, and timeframe."))
	row.add_child(_make_step_card("2", "Add Evidence", "Choose cards that support or challenge the idea."))
	row.add_child(_make_step_card("3", "Review", "Generate and revisit the paper."))
	return row


func _make_step_card(number: String, title: String, detail: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 68)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_rounded_stylebox(COLOR_PANEL_ALT, Color(0.70, 0.63, 0.46, 1), 1, 4))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	var badge_panel := PanelContainer.new()
	badge_panel.custom_minimum_size = Vector2(24, 24)
	badge_panel.add_theme_stylebox_override("panel", _make_rounded_stylebox(COLOR_BROWN, COLOR_BROWN, 1, 12))
	row.add_child(badge_panel)
	var badge := Label.new()
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.text = number
	_style_label(badge, COLOR_BG, 12)
	badge_panel.add_child(badge)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	row.add_child(copy)
	var title_label := Label.new()
	title_label.text = title
	_style_label(title_label, COLOR_BROWN, 14)
	copy.add_child(title_label)
	var detail_label := Label.new()
	detail_label.text = detail
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(detail_label, COLOR_MUTED, 11)
	copy.add_child(detail_label)
	return panel


func _make_stance_button(stance_id: String, label: String) -> Button:
	var button := Button.new()
	button.name = "ThesisStance%sButton" % _node_token(label)
	button.text = label
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(86, 34)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.set_meta("skip_thesis_style", true)
	button.pressed.connect(_on_stance_button_pressed.bind(stance_id))
	_style_segment_button(button, _stance_color(stance_id), stance_id == selected_stance_id)
	return button


func _make_evidence_tab_button(tab_id: String, label: String) -> Button:
	var button := Button.new()
	button.name = "ThesisEvidenceTab%sButton" % _node_token(label)
	button.text = label
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(96, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.set_meta("skip_thesis_style", true)
	button.pressed.connect(_on_evidence_tab_pressed.bind(tab_id))
	_style_evidence_tab_button(button, tab_id == selected_evidence_tab_id, true)
	return button


func _make_empty_evidence_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(260, 40)
	_style_label(label, COLOR_MUTED, 12)
	return label


func _build_evidence_card(option: Dictionary, thesis: Dictionary) -> Button:
	var option_key: String = _evidence_option_key(option)
	var selected_row: Dictionary = _selected_evidence_for_option(thesis, option)
	var is_selected: bool = not selected_row.is_empty()
	var impact: String = str(option.get("impact", "mixed"))
	var button := Button.new()
	button.name = "ThesisEvidenceCard%s" % _node_token(option_key)
	button.text = ""
	button.toggle_mode = true
	button.button_pressed = is_selected
	button.custom_minimum_size = Vector2(258, 142)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.set_meta("skip_thesis_style", true)
	button.pressed.connect(_on_evidence_card_pressed.bind(option_key))
	_style_evidence_card_button(button, is_selected, impact)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 9)
	button.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var source_label := Label.new()
	source_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	source_label.text = str(option.get("source_label", option.get("category_label", option.get("category", "Evidence")))).to_upper()
	source_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style_label(source_label, COLOR_MUTED, 10)
	vbox.add_child(source_label)

	var title_label := Label.new()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = str(option.get("label", "Evidence"))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(title_label, COLOR_TEXT, 14)
	vbox.add_child(title_label)

	var value_row := HBoxContainer.new()
	value_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_row.add_theme_constant_override("separation", 6)
	vbox.add_child(value_row)
	var value_label := Label.new()
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.text = str(option.get("value", "No current data"))
	value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style_label(value_label, _impact_color(impact), 13)
	value_row.add_child(value_label)
	var impact_badge := PanelContainer.new()
	impact_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	impact_badge.custom_minimum_size = Vector2(64, 22)
	impact_badge.add_theme_stylebox_override("panel", _make_rounded_stylebox(_impact_color(impact), _impact_color(impact), 1, 11))
	value_row.add_child(impact_badge)
	var impact_label := Label.new()
	impact_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	impact_label.text = impact.capitalize()
	impact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	impact_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(impact_label, COLOR_BG, 10)
	impact_badge.add_child(impact_label)

	var detail_label := Label.new()
	detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.text = str(option.get("detail", "No current context."))
	_style_label(detail_label, COLOR_MUTED, 11)
	vbox.add_child(detail_label)
	return button


func _build_evidence_chip(row: Dictionary) -> Button:
	var evidence_id: String = str(row.get("id", ""))
	var impact: String = str(row.get("impact", "mixed"))
	var chip := Button.new()
	chip.name = "ThesisEvidenceChip%s" % _node_token(evidence_id)
	chip.text = "%s: %s  x" % [str(row.get("category_label", row.get("category", "Evidence"))), str(row.get("label", ""))]
	chip.tooltip_text = str(row.get("detail", "Click to remove this evidence."))
	chip.custom_minimum_size = Vector2(0, 28)
	chip.set_meta("skip_thesis_style", true)
	chip.pressed.connect(_on_evidence_chip_remove_pressed.bind(evidence_id))
	_style_chip_button(chip, impact)
	return chip


func _on_stance_button_pressed(stance_id: String) -> void:
	selected_stance_id = stance_id
	_select_option_by_id(stance_option, selected_stance_id)
	_refresh_stance_buttons()
	if not selected_thesis_id.is_empty():
		_set_status("Stance set to %s. Press Update to save it." % stance_id.capitalize())


func _on_evidence_tab_pressed(tab_id: String) -> void:
	selected_evidence_tab_id = tab_id
	_refresh_evidence_tab_buttons()
	_refresh_evidence_cards(_selected_thesis())


func _on_evidence_card_pressed(option_key: String) -> void:
	if selected_thesis_id.is_empty():
		_set_status("Create a thesis before adding evidence.")
		_refresh_evidence_cards({})
		return
	var option: Dictionary = rendered_evidence_cards.get(option_key, {})
	if option.is_empty():
		_set_status("This evidence card is no longer available.")
		_refresh_evidence_cards(_selected_thesis())
		return
	var thesis: Dictionary = _selected_thesis()
	var selected_row: Dictionary = _selected_evidence_for_option(thesis, option)
	var result: Dictionary = {}
	suppress_thesis_changed_refresh = true
	if selected_row.is_empty():
		result = GameManager.add_thesis_evidence(selected_thesis_id, option)
	else:
		result = GameManager.remove_thesis_evidence(selected_thesis_id, str(selected_row.get("id", "")))
	suppress_thesis_changed_refresh = false
	_set_status(str(result.get("message", "")))
	if bool(result.get("success", false)):
		refresh()
	else:
		_refresh_evidence_cards(_selected_thesis())


func _on_evidence_chip_remove_pressed(evidence_id: String) -> void:
	if selected_thesis_id.is_empty() or evidence_id.is_empty():
		return
	suppress_thesis_changed_refresh = true
	var result: Dictionary = GameManager.remove_thesis_evidence(selected_thesis_id, evidence_id)
	suppress_thesis_changed_refresh = false
	_set_status(str(result.get("message", "")))
	if bool(result.get("success", false)):
		refresh()


func _flatten_evidence_options_for_tab(tab_id: String) -> Array:
	var category_ids: Array = _categories_for_evidence_tab(tab_id)
	var rows: Array = []
	for category_value in evidence_snapshot.get("categories", []):
		if typeof(category_value) != TYPE_DICTIONARY:
			continue
		var category: Dictionary = category_value
		var category_id: String = str(category.get("id", ""))
		for option_value in category.get("options", []):
			if typeof(option_value) != TYPE_DICTIONARY:
				continue
			var option: Dictionary = option_value
			var option_category: String = str(option.get("category", category_id))
			if category_ids.has(category_id) or category_ids.has(option_category):
				var normalized_option: Dictionary = option.duplicate(true)
				if str(normalized_option.get("category_label", "")).is_empty():
					normalized_option["category_label"] = str(category.get("label", option_category.capitalize()))
				rows.append(normalized_option)
	return rows


func _categories_for_evidence_tab(tab_id: String) -> Array:
	for tab_value in EVIDENCE_TABS:
		if typeof(tab_value) != TYPE_DICTIONARY:
			continue
		var tab: Dictionary = tab_value
		if str(tab.get("id", "")) == tab_id:
			return tab.get("categories", [])
	return []


func _selected_evidence_for_option(thesis: Dictionary, option: Dictionary) -> Dictionary:
	var option_key: String = _evidence_option_key(option)
	for evidence_value in thesis.get("evidence", []):
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = evidence_value
		if _evidence_option_key(row) == option_key:
			return row
	return {}


func _evidence_option_key(row: Dictionary) -> String:
	var category: String = str(row.get("category", ""))
	var label: String = str(row.get("label", ""))
	if category.is_empty() or label.is_empty():
		return ""
	return "%s|%s|%s|%s" % [
		category,
		str(row.get("source_label", "")),
		label,
		str(row.get("value", ""))
	]


func _stance_color(stance_id: String) -> Color:
	match stance_id:
		"bullish":
			return COLOR_POSITIVE
		"bearish":
			return COLOR_NEGATIVE
		"income":
			return COLOR_WARNING
		_:
			return COLOR_BROWN


func _impact_color(impact: String) -> Color:
	match impact.to_lower():
		"positive":
			return COLOR_POSITIVE
		"negative":
			return COLOR_NEGATIVE
		_:
			return COLOR_WARNING


func _style_segment_button(button: Button, accent: Color, selected: bool) -> void:
	var normal_bg: Color = accent if selected else COLOR_PAPER
	var hover_bg: Color = accent.lightened(0.10) if selected else COLOR_PANEL_ALT
	var pressed_bg: Color = accent.darkened(0.07)
	button.add_theme_stylebox_override("normal", _make_rounded_stylebox(normal_bg, accent, 1, 4))
	button.add_theme_stylebox_override("hover", _make_rounded_stylebox(hover_bg, accent, 1, 4))
	button.add_theme_stylebox_override("pressed", _make_rounded_stylebox(pressed_bg, accent, 1, 4))
	button.add_theme_stylebox_override("disabled", _make_rounded_stylebox(COLOR_PANEL_ALT, Color(0.73, 0.67, 0.53, 1), 1, 4))
	button.add_theme_color_override("font_color", COLOR_BG if selected else accent)
	button.add_theme_color_override("font_hover_color", COLOR_BG if selected else accent)
	button.add_theme_color_override("font_pressed_color", COLOR_BG)
	button.add_theme_color_override("font_disabled_color", COLOR_MUTED)


func _style_evidence_tab_button(button: Button, is_selected: bool, is_unlocked: bool) -> void:
	var fill_color: Color = COLOR_MARKET_PAPER_RAIL if is_unlocked else Color(0.85098, 0.835294, 0.772549, 1)
	var border_color: Color = Color(COLOR_MARKET_PAPER_BORDER.r, COLOR_MARKET_PAPER_BORDER.g, COLOR_MARKET_PAPER_BORDER.b, 0.86)
	var font_color: Color = COLOR_TEXT if is_unlocked else Color(0.541176, 0.494118, 0.396078, 1)
	if is_selected:
		fill_color = COLOR_MARKET_PAPER_CARD
		border_color = COLOR_MARKET_PAPER_RED
		font_color = Color(0.184314, 0.14902, 0.0705882, 1)
	var normal := StyleBoxFlat.new()
	normal.bg_color = fill_color
	normal.border_color = border_color
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 5 if is_selected else 1
	normal.border_width_bottom = 0 if is_selected else 1
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 11 if is_selected else 14
	normal.content_margin_bottom = 14
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
	button.add_theme_font_size_override("font_size", 15)


func _style_evidence_card_button(button: Button, selected: bool, impact: String) -> void:
	var accent: Color = COLOR_POSITIVE if selected else _impact_color(impact)
	var bg: Color = Color(0.984314, 0.972549, 0.917647, 1)
	var selected_bg: Color = Color(0.894118, 0.956863, 0.894118, 1)
	button.add_theme_stylebox_override("normal", _make_rounded_stylebox(selected_bg if selected else bg, accent if selected else Color(0.68, 0.61, 0.45, 1), 2 if selected else 1, 4))
	button.add_theme_stylebox_override("hover", _make_rounded_stylebox((selected_bg if selected else bg).lightened(0.03), accent, 2, 4))
	button.add_theme_stylebox_override("pressed", _make_rounded_stylebox(selected_bg.darkened(0.03), COLOR_POSITIVE, 2, 4))
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT)


func _style_chip_button(chip: Button, impact: String) -> void:
	var accent: Color = _impact_color(impact)
	chip.add_theme_stylebox_override("normal", _make_rounded_stylebox(COLOR_PANEL_ALT, accent, 1, 12))
	chip.add_theme_stylebox_override("hover", _make_rounded_stylebox(COLOR_PAPER, accent, 1, 12))
	chip.add_theme_stylebox_override("pressed", _make_rounded_stylebox(accent, accent, 1, 12))
	chip.add_theme_color_override("font_color", COLOR_TEXT)
	chip.add_theme_color_override("font_hover_color", COLOR_TEXT)
	chip.add_theme_color_override("font_pressed_color", COLOR_BG)
	chip.add_theme_font_size_override("font_size", 11)


func _make_rounded_stylebox(bg_color: Color, border_color: Color, border_width: int = 1, radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _make_padded_rounded_stylebox(bg_color: Color, border_color: Color, border_width: int = 1, radius: int = 4, margins: Dictionary = {}) -> StyleBoxFlat:
	var style := _make_rounded_stylebox(bg_color, border_color, border_width, radius)
	if margins.has("left"):
		style.content_margin_left = float(margins.get("left"))
	if margins.has("top"):
		style.content_margin_top = float(margins.get("top"))
	if margins.has("right"):
		style.content_margin_right = float(margins.get("right"))
	if margins.has("bottom"):
		style.content_margin_bottom = float(margins.get("bottom"))
	return style


func _theme_color(token: String, fallback: Color) -> Color:
	if not is_inside_tree():
		return fallback
	var theme = get_node_or_null("/root/UiTheme")
	if theme != null and theme.has_method("color"):
		return theme.color(token)
	return fallback


func _theme_font_size(role: String, fallback: int) -> int:
	if not is_inside_tree():
		return fallback
	var theme = get_node_or_null("/root/UiTheme")
	if theme != null and theme.has_method("font_size"):
		return int(theme.font_size(role))
	return fallback


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _node_token(value: String) -> String:
	var token := ""
	for index in range(value.length()):
		var character: String = value.substr(index, 1)
		if character.is_valid_identifier() or character.is_valid_int():
			token += character
	if token.is_empty():
		token = "Node"
	return token.substr(0, 48)


func _set_status(text: String) -> void:
	status_label.text = text


func _log_perf_elapsed(label: String, started_at_usec: int) -> void:
	if not OS.is_debug_build():
		return
	var elapsed_ms: float = float(Time.get_ticks_usec() - started_at_usec) / 1000.0
	print("[perf][ui] %s %.2fms" % [label, elapsed_ms])


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
		if child is Button and not bool(child.get_meta("skip_thesis_style", false)):
			_style_button(child)
		_style_buttons(child)


func _style_button(button: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BROWN
	style.border_color = COLOR_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	var hover := style.duplicate()
	hover.bg_color = COLOR_BROWN.lightened(0.06)
	var pressed := style.duplicate()
	pressed.bg_color = COLOR_BROWN.darkened(0.07)
	var disabled := style.duplicate()
	disabled.bg_color = Color(COLOR_BROWN.r, COLOR_BROWN.g, COLOR_BROWN.b, 0.28)
	disabled.border_color = Color(COLOR_BORDER.r, COLOR_BORDER.g, COLOR_BORDER.b, 0.38)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", COLOR_BG)
	button.add_theme_color_override("font_hover_color", COLOR_BG)
	button.add_theme_color_override("font_pressed_color", COLOR_BG)
	button.add_theme_color_override("font_disabled_color", Color(COLOR_BG.r, COLOR_BG.g, COLOR_BG.b, 0.60))
	button.add_theme_font_size_override("font_size", _theme_font_size("button", 14))


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
