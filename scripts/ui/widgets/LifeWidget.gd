extends MarginContainer

const LIFE_FONT_SIZE := 14
const COLOR_BG := Color(0.988235, 0.960784, 0.854902, 1)
const COLOR_PANEL := Color(1.0, 0.976471, 0.929412, 1)
const COLOR_PANEL_ALT := Color(0.972549, 0.94902, 0.847059, 1)
const COLOR_BROWN := Color(0.509804, 0.231373, 0.0941176, 1)
const COLOR_TEXT := Color(0.184314, 0.172549, 0.109804, 1)
const COLOR_MUTED := Color(0.403922, 0.380392, 0.301961, 1)
const COLOR_BORDER := Color(0.52549, 0.396078, 0.160784, 1)
const COLOR_POSITIVE := Color(0.168627, 0.423529, 0.27451, 1)
const COLOR_NEGATIVE := Color(0.607843, 0.160784, 0.145098, 1)
const COLOR_WARNING_BG := Color(0.988235, 0.858824, 0.482353, 1)
const COLOR_DANGER_BG := Color(0.521569, 0.160784, 0.141176, 1)

var snapshot: Dictionary = {}
var suppress_option_refresh: bool = false

var life_tabs: TabContainer = null
var status_label: Label = null
var summary_label: Label = null
var cash_label: Label = null
var equity_label: Label = null
var outflow_label: Label = null
var dividend_label: Label = null
var net_monthly_label: Label = null
var runway_label: Label = null
var stress_label: Label = null
var happiness_label: Label = null
var ap_penalty_label: Label = null
var public_image_label: Label = null
var asset_value_label: Label = null
var rental_income_label: Label = null
var asset_upkeep_label: Label = null
var property_intel_summary_label: Label = null
var next_payment_label: Label = null
var housing_option: OptionButton = null
var lifestyle_option: OptionButton = null
var basics_slider: HSlider = null
var basics_detail_label: Label = null
var wellbeing_detail_label: Label = null
var housing_detail_label: Label = null
var manage_properties_button: Button = null
var lifestyle_detail_label: Label = null
var update_plan_button: Button = null
var budget_rows: VBoxContainer = null
var dividend_rows: VBoxContainer = null
var note_label: Label = null
var finance_status_label: Label = null
var finance_guidance_label: Label = null
var emergency_loan_button: Button = null
var emergency_loan_terms_label: Label = null
var active_loan_panel: PanelContainer = null
var active_loan_label: Label = null
var bankruptcy_status_panel: PanelContainer = null
var bankruptcy_status_label: Label = null
var primary_property_label: Label = null
var development_intel_panel: PanelContainer = null
var development_lead_rows: VBoxContainer = null
var property_rows: VBoxContainer = null
var property_catalog_rows: VBoxContainer = null
var property_type_option: OptionButton = null
var property_location_option: OptionButton = null
var selected_property_catalog_id: String = ""
var selected_property_location_id: String = ""
var active_car_label: Label = null
var car_rows: VBoxContainer = null
var car_catalog_rows: VBoxContainer = null
var insufficient_cash_dialog: AcceptDialog = null


func _ready() -> void:
	_build_ui()
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
	_populate_basics_slider(str(state.get("basics_tier_id", "stable")))
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
	var stress_stage: Dictionary = snapshot.get("stress_stage", {})
	stress_label.text = "%d / 100 (%s)" % [int(round(float(snapshot.get("stress_value", 0.0)))), str(stress_stage.get("label", "Calm"))]
	happiness_label.text = "%d / 100" % int(round(float(snapshot.get("happiness_value", 0.0))))
	var ap_penalty: int = int(snapshot.get("stress_ap_penalty", 0))
	ap_penalty_label.text = "-%d AP" % ap_penalty if ap_penalty > 0 else "No penalty"
	var public_image: Dictionary = snapshot.get("public_image", {})
	if public_image_label != null:
		public_image_label.text = "%s (%d)" % [str(public_image.get("title", "Unknown Retail")), int(round(float(public_image.get("score", 0.0))))]
	if asset_value_label != null:
		asset_value_label.text = _format_currency(float(snapshot.get("lifestyle_asset_value", 0.0)))
	if rental_income_label != null:
		rental_income_label.text = _format_currency(float(snapshot.get("rental_income", 0.0)))
	if asset_upkeep_label != null:
		asset_upkeep_label.text = _format_currency(float(snapshot.get("asset_upkeep", 0.0)))
	summary_label.text = "Monthly outflow %s | Declared dividend avg %s | Net %s" % [
		_format_currency(float(snapshot.get("monthly_outflow", 0.0))),
		_format_currency(float(snapshot.get("estimated_monthly_dividends", 0.0))),
		_format_currency(net_monthly)
	]
	var next_payment: Dictionary = snapshot.get("next_life_payment", {})
	if next_payment.is_empty():
		next_payment_label.text = "Next Life payment: not scheduled yet."
	else:
		next_payment_label.text = "Next Life payment: %s due %s (%d trading day%s)." % [
			_format_currency(float(next_payment.get("amount", snapshot.get("monthly_outflow", 0.0)))),
			str(next_payment.get("date_text", "")),
			int(next_payment.get("due_in_trading_days", 0)),
			"" if int(next_payment.get("due_in_trading_days", 0)) == 1 else "s"
		]
		next_payment_label.add_theme_color_override("font_color", COLOR_NEGATIVE if bool(next_payment.get("warning", false)) else COLOR_MUTED)
	note_label.text = str(snapshot.get("note", ""))
	_refresh_option_details()
	_refresh_budget_rows()
	_refresh_dividend_rows()
	_refresh_properties_tab()
	_refresh_cars_tab()
	_refresh_finance_tab()


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
	next_payment_label = Label.new()
	next_payment_label.name = "LifeNextPaymentLabel"
	next_payment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(next_payment_label, COLOR_MUTED, 12)
	header_vbox.add_child(next_payment_label)

	life_tabs = TabContainer.new()
	life_tabs.name = "LifeTabs"
	life_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	life_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(life_tabs)

	var overview_tab := VBoxContainer.new()
	overview_tab.name = "LifeOverviewTab"
	overview_tab.add_theme_constant_override("separation", 10)
	overview_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overview_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	life_tabs.add_child(overview_tab)
	life_tabs.set_tab_title(life_tabs.get_tab_count() - 1, "Overview")

	var overview_scroll := ScrollContainer.new()
	overview_scroll.name = "LifeOverviewScroll"
	overview_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overview_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overview_tab.add_child(overview_scroll)
	var overview_content := VBoxContainer.new()
	overview_content.name = "LifeOverviewContent"
	overview_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overview_content.add_theme_constant_override("separation", 10)
	overview_scroll.add_child(overview_content)

	var properties_tab := VBoxContainer.new()
	properties_tab.name = "LifePropertiesTab"
	properties_tab.add_theme_constant_override("separation", 10)
	properties_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	properties_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	life_tabs.add_child(properties_tab)
	life_tabs.set_tab_title(life_tabs.get_tab_count() - 1, "Properties")

	var cars_tab := VBoxContainer.new()
	cars_tab.name = "LifeCarsTab"
	cars_tab.add_theme_constant_override("separation", 10)
	cars_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cars_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	life_tabs.add_child(cars_tab)
	life_tabs.set_tab_title(life_tabs.get_tab_count() - 1, "Cars")

	var finance_tab := VBoxContainer.new()
	finance_tab.name = "LifeFinanceTab"
	finance_tab.add_theme_constant_override("separation", 10)
	finance_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finance_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	life_tabs.add_child(finance_tab)
	life_tabs.set_tab_title(life_tabs.get_tab_count() - 1, "Finance")

	var stat_grid := GridContainer.new()
	stat_grid.name = "LifeStatGrid"
	stat_grid.columns = 4
	stat_grid.add_theme_constant_override("h_separation", 8)
	stat_grid.add_theme_constant_override("v_separation", 8)
	stat_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overview_content.add_child(stat_grid)
	cash_label = _add_stat_card(stat_grid, "Cash", "LifeCashLabel")
	equity_label = _add_stat_card(stat_grid, "Equity", "LifeEquityLabel")
	runway_label = _add_stat_card(stat_grid, "Runway", "LifeRunwayLabel")
	outflow_label = _add_stat_card(stat_grid, "Monthly outflow", "LifeMonthlyOutflowLabel")
	dividend_label = _add_stat_card(stat_grid, "Declared div avg", "LifeDividendLabel")
	net_monthly_label = _add_stat_card(stat_grid, "Net monthly", "LifeNetMonthlyLabel")
	stress_label = _add_stat_card(stat_grid, "Stress", "LifeStressLabel")
	happiness_label = _add_stat_card(stat_grid, "Happiness", "LifeHappinessLabel")
	ap_penalty_label = _add_stat_card(stat_grid, "AP pressure", "LifeStressApPenaltyLabel")
	public_image_label = _add_stat_card(stat_grid, "Public image", "LifePublicImageLabel")
	asset_value_label = _add_stat_card(stat_grid, "Lifestyle assets", "LifeAssetValueLabel")
	rental_income_label = _add_stat_card(stat_grid, "Rental income", "LifeRentalIncomeLabel")
	asset_upkeep_label = _add_stat_card(stat_grid, "Asset upkeep", "LifeAssetUpkeepLabel")

	var split := HBoxContainer.new()
	split.name = "LifeContentSplit"
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	split.add_theme_constant_override("separation", 10)
	overview_content.add_child(split)

	var plan_panel := _make_panel("LifePlanPanel")
	plan_panel.custom_minimum_size = Vector2(280, 0)
	split.add_child(plan_panel)
	var plan_vbox := _panel_vbox(plan_panel, "LifePlanVBox")
	plan_vbox.add_child(_make_title("Monthly Living Budget"))
	housing_option = OptionButton.new()
	housing_option.name = "LifeHousingOption"
	housing_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	housing_option.item_selected.connect(_on_option_changed)
	plan_vbox.add_child(housing_option)
	housing_detail_label = _make_body_label("LifeHousingDetailLabel")
	plan_vbox.add_child(housing_detail_label)
	manage_properties_button = Button.new()
	manage_properties_button.name = "LifeManagePropertiesButton"
	manage_properties_button.text = "Manage in Properties"
	manage_properties_button.visible = false
	manage_properties_button.pressed.connect(_on_manage_properties_pressed)
	plan_vbox.add_child(manage_properties_button)
	var basics_title := _make_body_label("LifeBasicsTitleLabel")
	basics_title.text = "Basics"
	_style_label(basics_title, COLOR_TEXT, 12)
	plan_vbox.add_child(basics_title)
	basics_slider = HSlider.new()
	basics_slider.name = "LifeBasicsSlider"
	basics_slider.min_value = 0.0
	basics_slider.max_value = 3.0
	basics_slider.step = 1.0
	basics_slider.tick_count = 4
	basics_slider.ticks_on_borders = true
	basics_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	basics_slider.value_changed.connect(_on_basics_slider_changed)
	plan_vbox.add_child(basics_slider)
	basics_detail_label = _make_body_label("LifeBasicsDetailLabel")
	plan_vbox.add_child(basics_detail_label)
	lifestyle_option = OptionButton.new()
	lifestyle_option.name = "LifeLifestyleOption"
	lifestyle_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lifestyle_option.item_selected.connect(_on_option_changed)
	plan_vbox.add_child(lifestyle_option)
	lifestyle_detail_label = _make_body_label("LifeLifestyleDetailLabel")
	plan_vbox.add_child(lifestyle_detail_label)
	wellbeing_detail_label = _make_body_label("LifeWellbeingDetailLabel")
	plan_vbox.add_child(wellbeing_detail_label)
	update_plan_button = Button.new()
	update_plan_button.name = "LifeUpdatePlanButton"
	update_plan_button.text = "Update Budget"
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

	_build_properties_tab(properties_tab)
	_build_cars_tab(cars_tab)
	_build_finance_tab(finance_tab)
	_style_buttons(self)
	_style_primary_buttons()


func _set_empty_state() -> void:
	status_label.text = "No active run"
	summary_label.text = "Start or load a run to use Life."
	for value_label in [cash_label, equity_label, outflow_label, dividend_label, net_monthly_label, runway_label, stress_label, happiness_label, ap_penalty_label, public_image_label, asset_value_label, rental_income_label, asset_upkeep_label]:
		if value_label != null:
			value_label.text = "-"
	if next_payment_label != null:
		next_payment_label.text = "-"
	if finance_status_label != null:
		finance_status_label.text = "Start or load a run to use Finance."
	if emergency_loan_button != null:
		emergency_loan_button.disabled = true
	if manage_properties_button != null:
		manage_properties_button.visible = false
	if property_intel_summary_label != null:
		property_intel_summary_label.visible = false
	if development_intel_panel != null:
		development_intel_panel.visible = false
	if property_type_option != null:
		property_type_option.clear()
	if property_location_option != null:
		property_location_option.clear()
	_clear_rows(budget_rows)
	_clear_rows(dividend_rows)
	_clear_rows(development_lead_rows)
	_clear_rows(property_rows)
	_clear_rows(property_catalog_rows)
	_clear_rows(car_rows)
	_clear_rows(car_catalog_rows)


func _build_properties_tab(properties_tab: VBoxContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "LifePropertiesScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	properties_tab.add_child(scroll)
	var root := VBoxContainer.new()
	root.name = "LifePropertiesRoot"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	scroll.add_child(root)

	var primary_panel := _make_panel("LifePrimaryResidencePanel")
	primary_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(primary_panel)
	var primary_vbox := _panel_vbox(primary_panel, "LifePrimaryResidenceVBox")
	primary_vbox.add_child(_make_title("Main Residence"))
	primary_property_label = _make_body_label("LifePrimaryResidenceLabel")
	primary_vbox.add_child(primary_property_label)

	var columns := HBoxContainer.new()
	columns.name = "LifePropertyColumns"
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 10)
	root.add_child(columns)

	var owned_panel := _make_panel("LifeOwnedPropertiesPanel")
	owned_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	owned_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	owned_panel.size_flags_stretch_ratio = 0.42
	columns.add_child(owned_panel)
	var owned_vbox := _panel_vbox(owned_panel, "LifeOwnedPropertiesVBox")
	owned_vbox.add_child(_make_title("Owned Properties"))
	property_rows = VBoxContainer.new()
	property_rows.name = "LifePropertyRows"
	property_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	property_rows.add_theme_constant_override("separation", 8)
	owned_vbox.add_child(property_rows)

	var catalog_panel := _make_panel("LifePropertyCatalogPanel")
	catalog_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	catalog_panel.size_flags_stretch_ratio = 0.58
	columns.add_child(catalog_panel)
	var catalog_vbox := _panel_vbox(catalog_panel, "LifePropertyCatalogVBox")
	catalog_vbox.add_child(_make_title("Buy Property"))
	var catalog_filter_row := HBoxContainer.new()
	catalog_filter_row.name = "LifePropertyCatalogFilterRow"
	catalog_filter_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog_filter_row.add_theme_constant_override("separation", 8)
	catalog_vbox.add_child(catalog_filter_row)
	property_type_option = OptionButton.new()
	property_type_option.name = "LifePropertyTypeOption"
	property_type_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	property_type_option.item_selected.connect(_on_property_filter_changed)
	catalog_filter_row.add_child(property_type_option)
	property_location_option = OptionButton.new()
	property_location_option.name = "LifePropertyLocationOption"
	property_location_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	property_location_option.item_selected.connect(_on_property_filter_changed)
	catalog_filter_row.add_child(property_location_option)
	property_catalog_rows = VBoxContainer.new()
	property_catalog_rows.name = "LifePropertyCatalogRows"
	property_catalog_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	property_catalog_rows.add_theme_constant_override("separation", 8)
	catalog_vbox.add_child(property_catalog_rows)


func _build_cars_tab(cars_tab: VBoxContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "LifeCarsScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cars_tab.add_child(scroll)
	var root := VBoxContainer.new()
	root.name = "LifeCarsRoot"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	scroll.add_child(root)

	var active_panel := _make_panel("LifeActiveCarPanel")
	active_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(active_panel)
	var active_vbox := _panel_vbox(active_panel, "LifeActiveCarVBox")
	active_vbox.add_child(_make_title("Active Car"))
	active_car_label = _make_body_label("LifeActiveCarLabel")
	active_vbox.add_child(active_car_label)

	var owned_panel := _make_panel("LifeOwnedCarsPanel")
	owned_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(owned_panel)
	var owned_vbox := _panel_vbox(owned_panel, "LifeOwnedCarsVBox")
	owned_vbox.add_child(_make_title("Owned Cars"))
	car_rows = VBoxContainer.new()
	car_rows.name = "LifeCarRows"
	car_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	car_rows.add_theme_constant_override("separation", 8)
	owned_vbox.add_child(car_rows)

	var catalog_panel := _make_panel("LifeCarCatalogPanel")
	catalog_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(catalog_panel)
	var catalog_vbox := _panel_vbox(catalog_panel, "LifeCarCatalogVBox")
	catalog_vbox.add_child(_make_title("Buy Car"))
	var catalog_note := _make_body_label("LifeCarCatalogNoteLabel")
	catalog_note.text = "Cars add comfort and public image, but every owned car adds monthly upkeep."
	catalog_vbox.add_child(catalog_note)
	car_catalog_rows = VBoxContainer.new()
	car_catalog_rows.name = "LifeCarCatalogRows"
	car_catalog_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	car_catalog_rows.add_theme_constant_override("separation", 8)
	catalog_vbox.add_child(car_catalog_rows)


func _build_finance_tab(finance_tab: VBoxContainer) -> void:
	var status_panel := _make_panel("LifeFinanceStatusPanel")
	status_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	finance_tab.add_child(status_panel)
	var status_vbox := _panel_vbox(status_panel, "LifeFinanceStatusVBox")
	status_vbox.add_child(_make_title("Finance"))
	finance_status_label = _make_body_label("LifeFinanceStatusLabel")
	status_vbox.add_child(finance_status_label)
	finance_guidance_label = _make_body_label("LifeFinanceGuidanceLabel")
	status_vbox.add_child(finance_guidance_label)

	var loan_offer_panel := _make_panel("LifeEmergencyLoanPanel")
	loan_offer_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	finance_tab.add_child(loan_offer_panel)
	var loan_offer_vbox := _panel_vbox(loan_offer_panel, "LifeEmergencyLoanVBox")
	loan_offer_vbox.add_child(_make_title("Emergency Loan"))
	emergency_loan_terms_label = _make_body_label("LifeEmergencyLoanTermsLabel")
	loan_offer_vbox.add_child(emergency_loan_terms_label)
	emergency_loan_button = Button.new()
	emergency_loan_button.name = "LifeEmergencyLoanButton"
	emergency_loan_button.text = "Take Emergency Loan"
	emergency_loan_button.pressed.connect(_on_emergency_loan_pressed)
	loan_offer_vbox.add_child(emergency_loan_button)

	active_loan_panel = _make_panel("LifeActiveLoanPanel")
	active_loan_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	finance_tab.add_child(active_loan_panel)
	var active_loan_vbox := _panel_vbox(active_loan_panel, "LifeActiveLoanVBox")
	active_loan_vbox.add_child(_make_title("Active Loan"))
	active_loan_label = _make_body_label("LifeActiveLoanLabel")
	active_loan_vbox.add_child(active_loan_label)

	bankruptcy_status_panel = _make_panel("LifeBankruptcyStatusPanel")
	bankruptcy_status_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	finance_tab.add_child(bankruptcy_status_panel)
	var bankruptcy_vbox := _panel_vbox(bankruptcy_status_panel, "LifeBankruptcyStatusVBox")
	bankruptcy_vbox.add_child(_make_title("Bankruptcy Risk"))
	bankruptcy_status_label = _make_body_label("LifeBankruptcyStatusLabel")
	bankruptcy_vbox.add_child(bankruptcy_status_label)


func _refresh_finance_tab() -> void:
	if finance_status_label == null:
		return
	var finance_status: Dictionary = snapshot.get("finance", {})
	var finance: Dictionary = finance_status.get("finance", {})
	var cash: float = float(finance_status.get("cash", snapshot.get("cash", 0.0)))
	var monthly_outflow: float = float(finance_status.get("monthly_outflow", snapshot.get("monthly_outflow", 0.0)))
	var runway_months: float = float(finance_status.get("runway_months", snapshot.get("runway_months", 999.0)))
	var active_loan: Dictionary = finance_status.get("active_loan", {})
	var bankrupt: bool = bool(finance_status.get("bankrupt", false))
	var stress_active: bool = bool(finance_status.get("cash_stress_active", false))
	var status_text: String = "Cash is stable. Runway: %s." % _format_runway(runway_months)
	var status_color: Color = COLOR_MUTED
	if bankrupt:
		status_text = "Bankrupt. Trading, new loans, upgrades, and Advance Day are disabled."
		status_color = COLOR_NEGATIVE
	elif stress_active:
		status_text = "Cash stress active: cash is %s. Grace: %d trading day%s remaining." % [
			_format_currency(cash),
			int(finance_status.get("cash_stress_days_remaining", 0)),
			"" if int(finance_status.get("cash_stress_days_remaining", 0)) == 1 else "s"
		]
		status_color = COLOR_NEGATIVE
	elif runway_months < 0.5:
		status_text = "Runway is under half a month. Emergency credit is available."
		status_color = COLOR_NEGATIVE
	elif runway_months < 3.0:
		status_text = "Runway is thin. Keep position size small."
		status_color = COLOR_BROWN
	finance_status_label.text = status_text
	_style_label(finance_status_label, status_color, 12)
	if finance_guidance_label != null:
		finance_guidance_label.text = "Recovery order: sell holdings, lower Life costs, use declared dividends, then use emergency credit only when needed."

	var loan_eligible: bool = bool(finance_status.get("loan_eligible", false))
	var proposed_amount: float = float(finance_status.get("proposed_loan_amount", 0.0))
	var payment_count: int = int(finance_status.get("loan_payment_count", 6))
	var repayment_multiplier: float = float(finance_status.get("loan_repayment_multiplier", 1.24))
	if emergency_loan_terms_label != null:
		if loan_eligible:
			emergency_loan_terms_label.text = "Offer: %s now. Repay %s across %d monthly payments." % [
				_format_currency(proposed_amount),
				_format_currency(proposed_amount * repayment_multiplier),
				payment_count
			]
		else:
			emergency_loan_terms_label.text = str(finance_status.get("loan_eligibility_reason", "Emergency loan is not available."))
	if emergency_loan_button != null:
		emergency_loan_button.disabled = not loan_eligible
		if loan_eligible:
			emergency_loan_button.text = "Take %s Loan" % _format_currency(proposed_amount)
		else:
			emergency_loan_button.text = "Emergency Loan Locked"

	if active_loan_panel != null:
		active_loan_panel.visible = not active_loan.is_empty()
	if active_loan_label != null:
		if active_loan.is_empty():
			active_loan_label.text = "No active emergency loan."
			_style_label(active_loan_label, COLOR_MUTED, 12)
		else:
			active_loan_label.text = "Principal %s | Payment %s | %d/%d payments left%s" % [
				_format_currency(float(active_loan.get("principal", 0.0))),
				_format_currency(float(active_loan.get("monthly_payment", 0.0))),
				int(active_loan.get("payments_remaining", 0)),
				int(active_loan.get("payment_count", 0)),
				" | reserve not covered" if bool(finance_status.get("loan_payment_risky", false)) else ""
			]
			_style_label(active_loan_label, COLOR_NEGATIVE if bool(finance_status.get("loan_payment_risky", false)) else COLOR_MUTED, 12)

	if bankruptcy_status_panel != null:
		bankruptcy_status_panel.visible = bankrupt or stress_active or cash < monthly_outflow
	if bankruptcy_status_label != null:
		if bankrupt:
			var bankruptcy: Dictionary = finance_status.get("bankruptcy", finance.get("bankruptcy", {}))
			bankruptcy_status_label.text = "Final cash %s | Equity %s | Reason: %s" % [
				_format_currency(float(bankruptcy.get("cash", cash))),
				_format_currency(float(bankruptcy.get("equity", snapshot.get("equity", 0.0)))),
				str(bankruptcy.get("reason", "cash stress"))
			]
			_style_label(bankruptcy_status_label, COLOR_NEGATIVE, 12)
		elif stress_active:
			bankruptcy_status_label.text = "If grace expires, Advance Day will require selling, using Finance, or bankruptcy if no recovery path exists."
			_style_label(bankruptcy_status_label, COLOR_NEGATIVE, 12)
		else:
			bankruptcy_status_label.text = "No bankruptcy risk yet. Cash below one month of costs still deserves attention."
			_style_label(bankruptcy_status_label, COLOR_MUTED, 12)


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


func _populate_basics_slider(selected_id: String) -> void:
	if basics_slider == null:
		return
	var rows: Array = snapshot.get("basics_tiers", [])
	var selected_index: int = _basics_tier_index(selected_id)
	if selected_index < 0 and not rows.is_empty():
		selected_index = _basics_tier_index("stable")
	basics_slider.set_value_no_signal(max(selected_index, 0))


func _populate_property_purchase_filters(catalog_rows: Array) -> void:
	if property_type_option == null or property_location_option == null:
		return
	var desired_catalog_id: String = _selected_option_id(property_type_option)
	if desired_catalog_id.is_empty():
		desired_catalog_id = selected_property_catalog_id
	var desired_location_id: String = _selected_option_id(property_location_option)
	if desired_location_id.is_empty():
		desired_location_id = selected_property_location_id
	var type_rows: Array = _property_type_filter_rows(catalog_rows)
	var location_rows: Array = _property_location_filter_rows(catalog_rows)
	if desired_catalog_id.is_empty() and not type_rows.is_empty():
		desired_catalog_id = str(type_rows[0].get("id", ""))
	if desired_location_id.is_empty() and not location_rows.is_empty():
		desired_location_id = str(location_rows[0].get("id", ""))
	suppress_option_refresh = true
	_populate_option(property_type_option, type_rows, desired_catalog_id)
	_populate_option(property_location_option, location_rows, desired_location_id)
	suppress_option_refresh = false
	selected_property_catalog_id = _selected_option_id(property_type_option)
	selected_property_location_id = _selected_option_id(property_location_option)


func _property_type_filter_rows(catalog_rows: Array) -> Array:
	var rows: Array = []
	var seen: Dictionary = {}
	for catalog_value in catalog_rows:
		if typeof(catalog_value) != TYPE_DICTIONARY:
			continue
		var catalog_row: Dictionary = catalog_value
		var catalog_id: String = str(catalog_row.get("catalog_id", catalog_row.get("id", "")))
		if catalog_id.is_empty() or seen.has(catalog_id):
			continue
		seen[catalog_id] = true
		rows.append({
			"id": catalog_id,
			"label": str(catalog_row.get("label", "Property"))
		})
	return rows


func _property_location_filter_rows(catalog_rows: Array) -> Array:
	var rows: Array = []
	var seen: Dictionary = {}
	for location_value in snapshot.get("property_locations", []):
		if typeof(location_value) != TYPE_DICTIONARY:
			continue
		var location: Dictionary = location_value
		var location_id: String = str(location.get("id", ""))
		if location_id.is_empty() or seen.has(location_id):
			continue
		seen[location_id] = true
		rows.append({
			"id": location_id,
			"label": str(location.get("label", "Location"))
		})
	if not rows.is_empty():
		return rows
	for catalog_value in catalog_rows:
		if typeof(catalog_value) != TYPE_DICTIONARY:
			continue
		var catalog_row: Dictionary = catalog_value
		var location_id: String = str(catalog_row.get("location_id", ""))
		if location_id.is_empty() or seen.has(location_id):
			continue
		seen[location_id] = true
		rows.append({
			"id": location_id,
			"label": str(catalog_row.get("location_label", "Location"))
		})
	return rows


func _selected_property_catalog_row(catalog_rows: Array) -> Dictionary:
	var catalog_id: String = selected_property_catalog_id
	if catalog_id.is_empty():
		catalog_id = _selected_option_id(property_type_option)
	var location_id: String = selected_property_location_id
	if location_id.is_empty():
		location_id = _selected_option_id(property_location_option)
	for catalog_value in catalog_rows:
		if typeof(catalog_value) != TYPE_DICTIONARY:
			continue
		var catalog_row: Dictionary = catalog_value
		if (
			str(catalog_row.get("catalog_id", catalog_row.get("id", ""))) == catalog_id
			and str(catalog_row.get("location_id", "")) == location_id
		):
			return catalog_row
	for catalog_value in catalog_rows:
		if typeof(catalog_value) == TYPE_DICTIONARY:
			return catalog_value
	return {}


func _refresh_option_details() -> void:
	var housing: Dictionary = _selected_option_data(snapshot.get("housing_options", []), _selected_option_id(housing_option))
	var lifestyle: Dictionary = _selected_option_data(snapshot.get("lifestyle_options", []), _selected_option_id(lifestyle_option))
	var basics_tier: Dictionary = _selected_basics_tier_data()
	var owns_primary_residence: bool = bool(snapshot.get("owned_primary_residence", false))
	if housing_option != null:
		housing_option.visible = not owns_primary_residence
	if manage_properties_button != null:
		manage_properties_button.visible = owns_primary_residence
	if housing_detail_label != null:
		if owns_primary_residence:
			var primary_property: Dictionary = snapshot.get("primary_property", {})
			housing_detail_label.text = "Primary residence: %s in %s. Upkeep %s / month." % [
				str(primary_property.get("label", "Owned residence")),
				str(primary_property.get("location_label", "Jakarta")),
				_format_currency(float(primary_property.get("monthly_upkeep", snapshot.get("housing_cost_monthly", 0.0))))
			]
		else:
			housing_detail_label.text = "Rental housing: %s / month. %s" % [
				_format_currency(float(housing.get("monthly_cost", 0.0))),
				str(housing.get("detail", ""))
			]
	if basics_detail_label != null:
		basics_detail_label.text = "%s: %s / month. Stress %+d/day | Happiness %+d/day. %s" % [
			str(basics_tier.get("label", "Stable")),
			_format_currency(float(basics_tier.get("monthly_cost", snapshot.get("basic_expenses_monthly", 0.0)))),
			int(basics_tier.get("stress_delta", 0)),
			int(basics_tier.get("happiness_delta", 0)),
			str(basics_tier.get("detail", ""))
		]
	lifestyle_detail_label.text = "%s / month. %s" % [
		_format_currency(float(lifestyle.get("monthly_cost", 0.0))),
		str(lifestyle.get("detail", ""))
	]
	if wellbeing_detail_label != null:
		var stress_stage: Dictionary = snapshot.get("stress_stage", {})
		var detail_text: String = "Stress %d/100 (%s). Happiness %d/100. AP penalty: %s." % [
			int(round(float(snapshot.get("stress_value", 0.0)))),
			str(stress_stage.get("label", "Calm")),
			int(round(float(snapshot.get("happiness_value", 0.0)))),
			"-%d" % int(snapshot.get("stress_ap_penalty", 0)) if int(snapshot.get("stress_ap_penalty", 0)) > 0 else "none"
		]
		if bool(snapshot.get("hospitalized", false)):
			detail_text += " Hospital recovery: %d trading day%s left." % [
				int(snapshot.get("hospital_days_remaining", 0)),
				"" if int(snapshot.get("hospital_days_remaining", 0)) == 1 else "s"
			]
		elif bool(snapshot.get("burnout_risk_active", false)):
			detail_text += " Burnout risk: %d trading day%s to recover before hospital." % [
				int(snapshot.get("burnout_risk_days_remaining", 0)),
				"" if int(snapshot.get("burnout_risk_days_remaining", 0)) == 1 else "s"
			]
		wellbeing_detail_label.text = detail_text


func _refresh_budget_rows() -> void:
	_clear_rows(budget_rows)
	var housing: Dictionary = snapshot.get("housing", {})
	var basics_tier: Dictionary = snapshot.get("basics_tier", {})
	var lifestyle: Dictionary = snapshot.get("lifestyle", {})
	var housing_detail: String = str(housing.get("label", ""))
	if bool(snapshot.get("owned_primary_residence", false)):
		var primary_property: Dictionary = snapshot.get("primary_property", {})
		housing_detail = "%s upkeep" % str(primary_property.get("label", "Owned residence"))
	_add_budget_row("Housing", housing_detail, float(snapshot.get("housing_cost_monthly", housing.get("monthly_cost", 0.0))), false)
	_add_budget_row("Basics", str(basics_tier.get("label", "Stable")), float(snapshot.get("basic_expenses_monthly", 0.0)), false)
	_add_budget_row("Lifestyle", str(lifestyle.get("label", "")), float(lifestyle.get("monthly_cost", 0.0)), false)
	var extra_asset_upkeep: float = float(snapshot.get("non_primary_property_upkeep", 0.0)) + float(snapshot.get("car_upkeep", 0.0))
	if extra_asset_upkeep > 0.0:
		_add_budget_row("Assets", "Investment properties and cars upkeep", extra_asset_upkeep, false)
	if float(snapshot.get("rental_income", 0.0)) > 0.0:
		_add_budget_row("Rent", "Rented properties", float(snapshot.get("rental_income", 0.0)), true)
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


func _refresh_properties_tab() -> void:
	if primary_property_label == null:
		return
	_clear_rows(property_rows)
	_clear_rows(property_catalog_rows)
	var primary_property: Dictionary = snapshot.get("primary_property", {})
	if primary_property.is_empty():
		var housing: Dictionary = snapshot.get("housing", {})
		primary_property_label.text = "No owned primary residence. Current housing plan: %s at %s / month." % [
			str(housing.get("label", "Housing")),
			_format_currency(float(housing.get("monthly_cost", 0.0)))
		]
	else:
		primary_property_label.text = "%s in %s. Upkeep %s / month. Status %+d." % [
			str(primary_property.get("label", "Owned residence")),
			str(primary_property.get("location_label", "Jakarta")),
			_format_currency(float(primary_property.get("monthly_upkeep", 0.0))),
			int(round(float(primary_property.get("status_value", 0.0))))
		]
	var properties: Array = snapshot.get("properties", [])
	if properties.is_empty():
		_add_empty_asset_label(property_rows, "No owned properties yet.")
	else:
		for property_value in properties:
			if typeof(property_value) == TYPE_DICTIONARY:
				_add_owned_property_row(property_value)
	var catalog_rows: Array = snapshot.get("property_catalog", [])
	_populate_property_purchase_filters(catalog_rows)
	var selected_catalog_row: Dictionary = _selected_property_catalog_row(catalog_rows)
	if selected_catalog_row.is_empty():
		_add_empty_asset_label(property_catalog_rows, "No property options available.")
	else:
		_add_property_catalog_row(selected_catalog_row)


func _refresh_cars_tab() -> void:
	if active_car_label == null:
		return
	_clear_rows(car_rows)
	_clear_rows(car_catalog_rows)
	var active_car: Dictionary = snapshot.get("active_car", {})
	if active_car.is_empty():
		active_car_label.text = "No active car. You can still operate without one, but cars add comfort and public image."
	else:
		active_car_label.text = "%s. Upkeep %s / month. Status %+d." % [
			str(active_car.get("label", "Active car")),
			_format_currency(float(active_car.get("monthly_upkeep", 0.0))),
			int(round(float(active_car.get("status_value", 0.0))))
		]
	var cars: Array = snapshot.get("cars", [])
	if cars.is_empty():
		_add_empty_asset_label(car_rows, "No owned cars yet.")
	else:
		for car_value in cars:
			if typeof(car_value) == TYPE_DICTIONARY:
				_add_owned_car_row(car_value)
	var catalog_rows: Array = snapshot.get("car_catalog", [])
	for catalog_value in catalog_rows:
		if typeof(catalog_value) == TYPE_DICTIONARY:
			_add_car_catalog_row(catalog_value)


func _add_development_lead_row(lead: Dictionary) -> void:
	if development_lead_rows == null:
		return
	var row := _make_asset_row(development_lead_rows, "LifeDevelopmentLeadRow%s" % str(lead.get("id", "")).replace(" ", ""))
	var status_text: String = str(lead.get("stage_label", lead.get("stage", "Rumor")))
	var clarity_text: String = str(lead.get("clarity_label", "")).strip_edges()
	var reporting_text: String = clarity_text if not clarity_text.is_empty() else "Property report"
	var multiplier_text: String = ""
	if bool(lead.get("public_confirmed", false)) and float(lead.get("value_multiplier", 1.0)) > 1.0:
		multiplier_text = " | public uplift x%.2f" % float(lead.get("value_multiplier", 1.0))
	var detail := _make_asset_detail_label(
		"%s | %s" % [
			str(lead.get("display_location_label", lead.get("location_label", "Location"))),
			str(lead.get("display_theme_label", lead.get("theme_label", "Development")))
		],
		"%s | %s | %s%s. %s" % [
			status_text,
			reporting_text,
			str(lead.get("timing_label", "")),
			multiplier_text,
			str(lead.get("source_note", lead.get("source_label", "")))
		]
	)
	row.add_child(detail)


func _add_owned_property_row(property_row: Dictionary) -> void:
	if property_rows == null:
		return
	var row := _make_asset_row(property_rows, "LifeOwnedPropertyRow%s" % str(property_row.get("id", "")).replace(" ", ""))
	var value_event_text: String = _property_value_event_text(property_row)
	var detail := _make_asset_detail_label(
		"%s%s" % [str(property_row.get("label", "Property")), " (Primary)" if bool(property_row.get("is_primary", false)) else ""],
		"%s | value %s | upkeep %s | rent %s%s%s" % [
			str(property_row.get("location_label", "Jakarta")),
			_format_currency(float(property_row.get("current_value", 0.0))),
			_format_currency(float(property_row.get("monthly_upkeep", 0.0))),
			_format_currency(float(property_row.get("rent_income", 0.0))),
			" | rented" if bool(property_row.get("rented_out", false)) else "",
			value_event_text
		]
	)
	row.add_child(detail)
	var set_primary_button := _make_asset_button("Set Primary")
	set_primary_button.disabled = bool(property_row.get("is_primary", false))
	set_primary_button.pressed.connect(_on_set_primary_property_pressed.bind(str(property_row.get("id", ""))))
	row.add_child(set_primary_button)
	var rent_button := _make_asset_button("Stop Rent" if bool(property_row.get("rented_out", false)) else "Rent Out")
	rent_button.disabled = bool(property_row.get("is_primary", false)) or float(property_row.get("rent_income", 0.0)) <= 0.0
	rent_button.pressed.connect(_on_toggle_property_rental_pressed.bind(str(property_row.get("id", "")), not bool(property_row.get("rented_out", false))))
	row.add_child(rent_button)
	var sell_button := _make_asset_button("Sell")
	sell_button.pressed.connect(_on_sell_property_pressed.bind(str(property_row.get("id", ""))))
	row.add_child(sell_button)


func _add_property_catalog_row(catalog_row: Dictionary) -> void:
	if property_catalog_rows == null:
		return
	var row := _make_asset_row(property_catalog_rows, "LifePropertyCatalogRow%s" % str(catalog_row.get("id", "")).replace(" ", ""))
	var uplift_text: String = ""
	if float(catalog_row.get("public_uplift_multiplier", 1.0)) > 1.001:
		uplift_text = " | %s" % str(catalog_row.get("public_uplift_label", "public uplift"))
	var detail := _make_asset_detail_label(
		"%s | %s" % [str(catalog_row.get("label", "Property")), str(catalog_row.get("location_label", "Jakarta"))],
		"Price %s | upkeep %s/mo | rent %s/mo | status %+d%s. %s" % [
			_format_currency(float(catalog_row.get("price", 0.0))),
			_format_currency(float(catalog_row.get("monthly_upkeep", 0.0))),
			_format_currency(float(catalog_row.get("rent_income", 0.0))),
			int(round(float(catalog_row.get("status_value", 0.0)))),
			uplift_text,
			str(catalog_row.get("detail", ""))
		]
	)
	row.add_child(detail)
	var buy_button := _make_asset_button("Buy", true)
	buy_button.pressed.connect(_on_buy_property_pressed.bind(str(catalog_row.get("catalog_id", catalog_row.get("id", ""))), str(catalog_row.get("location_id", "jakarta")), false))
	row.add_child(buy_button)
	var home_button := _make_asset_button("Buy as Home", true)
	home_button.pressed.connect(_on_buy_property_pressed.bind(str(catalog_row.get("catalog_id", catalog_row.get("id", ""))), str(catalog_row.get("location_id", "jakarta")), true))
	row.add_child(home_button)


func _add_owned_car_row(car_row: Dictionary) -> void:
	if car_rows == null:
		return
	var row := _make_asset_row(car_rows, "LifeOwnedCarRow%s" % str(car_row.get("id", "")).replace(" ", ""))
	var detail := _make_asset_detail_label(
		"%s%s" % [str(car_row.get("label", "Car")), " (Active)" if bool(car_row.get("is_active", false)) else ""],
		"value %s | upkeep %s/mo | status %+d" % [
			_format_currency(float(car_row.get("current_value", 0.0))),
			_format_currency(float(car_row.get("monthly_upkeep", 0.0))),
			int(round(float(car_row.get("status_value", 0.0))))
		]
	)
	row.add_child(detail)
	var active_button := _make_asset_button("Set Active")
	active_button.disabled = bool(car_row.get("is_active", false))
	active_button.pressed.connect(_on_set_active_car_pressed.bind(str(car_row.get("id", ""))))
	row.add_child(active_button)
	var sell_button := _make_asset_button("Sell")
	sell_button.pressed.connect(_on_sell_car_pressed.bind(str(car_row.get("id", ""))))
	row.add_child(sell_button)


func _add_car_catalog_row(catalog_row: Dictionary) -> void:
	if car_catalog_rows == null:
		return
	var row := _make_asset_row(car_catalog_rows, "LifeCarCatalogRow%s" % str(catalog_row.get("id", "")).replace(" ", ""))
	var detail := _make_asset_detail_label(
		str(catalog_row.get("label", "Car")),
		"Price %s | upkeep %s/mo | status %+d. %s" % [
			_format_currency(float(catalog_row.get("price", 0.0))),
			_format_currency(float(catalog_row.get("monthly_upkeep", 0.0))),
			int(round(float(catalog_row.get("status_value", 0.0)))),
			str(catalog_row.get("detail", ""))
		]
	)
	row.add_child(detail)
	var buy_button := _make_asset_button("Buy", true)
	buy_button.pressed.connect(_on_buy_car_pressed.bind(str(catalog_row.get("id", ""))))
	row.add_child(buy_button)


func _add_empty_asset_label(container: VBoxContainer, text: String) -> void:
	if container == null:
		return
	var label := _make_body_label("%sEmptyLabel" % container.name)
	label.text = text
	container.add_child(label)


func _property_value_event_text(property_row: Dictionary) -> String:
	var events: Array = property_row.get("value_events", [])
	if events.is_empty():
		return ""
	var latest: Dictionary = events[events.size() - 1] if typeof(events[events.size() - 1]) == TYPE_DICTIONARY else {}
	if latest.is_empty():
		return ""
	return " | %s x%.2f" % [
		str(latest.get("theme_label", latest.get("label", "development"))),
		float(latest.get("multiplier", 1.0))
	]


func _make_asset_row(container: VBoxContainer, row_name: String) -> HBoxContainer:
	var panel := _make_panel("%sPanel" % row_name)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	container.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.name = row_name
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	return row


func _make_asset_detail_label(title: String, detail: String) -> Label:
	var label := Label.new()
	label.text = "%s\n%s" % [title, detail]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(label, COLOR_TEXT, 12)
	return label


func _make_asset_button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(92, 30)
	if primary:
		_style_primary_button(button)
	else:
		_style_button(button)
	return button


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


func _on_manage_properties_pressed() -> void:
	if life_tabs == null:
		return
	for index in range(life_tabs.get_tab_count()):
		if life_tabs.get_tab_title(index) == "Properties":
			life_tabs.current_tab = index
			return


func _on_option_changed(_index: int) -> void:
	if suppress_option_refresh:
		return
	_refresh_option_details()
	status_label.text = "Unsaved plan"


func _on_basics_slider_changed(_value: float) -> void:
	if basics_slider != null:
		basics_slider.value = round(basics_slider.value)
	_on_option_changed(0)


func _on_property_filter_changed(_index: int) -> void:
	if suppress_option_refresh:
		return
	selected_property_catalog_id = _selected_option_id(property_type_option)
	selected_property_location_id = _selected_option_id(property_location_option)
	_refresh_properties_tab()


func _on_update_plan_pressed() -> void:
	var result: Dictionary = GameManager.set_life_plan(_selected_option_id(housing_option), _selected_option_id(lifestyle_option), _selected_basics_tier_id())
	status_label.text = str(result.get("message", "Life plan updated."))
	if bool(result.get("success", false)):
		refresh()


func _on_emergency_loan_pressed() -> void:
	var result: Dictionary = GameManager.take_emergency_loan()
	status_label.text = str(result.get("message", "Finance updated."))
	refresh()


func _on_buy_property_pressed(catalog_id: String, location_id: String, make_primary: bool) -> void:
	var result: Dictionary = GameManager.purchase_life_property(catalog_id, location_id, make_primary)
	status_label.text = str(result.get("message", "Property action finished."))
	if _result_is_insufficient_cash(result):
		_show_insufficient_cash_dialog(result, "property")
	refresh()


func _on_set_primary_property_pressed(property_id: String) -> void:
	var result: Dictionary = GameManager.set_primary_residence(property_id)
	status_label.text = str(result.get("message", "Primary residence updated."))
	refresh()


func _on_toggle_property_rental_pressed(property_id: String, rented_out: bool) -> void:
	var result: Dictionary = GameManager.set_property_rental(property_id, rented_out)
	status_label.text = str(result.get("message", "Property rental updated."))
	refresh()


func _on_sell_property_pressed(property_id: String) -> void:
	var result: Dictionary = GameManager.sell_life_property(property_id)
	status_label.text = str(result.get("message", "Property sale finished."))
	refresh()


func _on_buy_car_pressed(catalog_id: String) -> void:
	var result: Dictionary = GameManager.purchase_life_car(catalog_id)
	status_label.text = str(result.get("message", "Car action finished."))
	if _result_is_insufficient_cash(result):
		_show_insufficient_cash_dialog(result, "car")
	refresh()


func _on_set_active_car_pressed(car_id: String) -> void:
	var result: Dictionary = GameManager.set_active_life_car(car_id)
	status_label.text = str(result.get("message", "Active car updated."))
	refresh()


func _on_sell_car_pressed(car_id: String) -> void:
	var result: Dictionary = GameManager.sell_life_car(car_id)
	status_label.text = str(result.get("message", "Car sale finished."))
	refresh()


func _result_is_insufficient_cash(result: Dictionary) -> bool:
	return (
		not bool(result.get("success", false))
		and (
			str(result.get("reason", "")) == "insufficient_cash"
			or str(result.get("message", "")).to_lower().find("not enough cash") >= 0
		)
	)


func _show_insufficient_cash_dialog(result: Dictionary, asset_type: String) -> void:
	_ensure_insufficient_cash_dialog()
	if insufficient_cash_dialog == null:
		return
	var message: String = str(result.get("message", "Not enough cash."))
	var required_cash: float = float(result.get("required_cash", 0.0))
	var available_cash: float = float(result.get("available_cash", snapshot.get("cash", 0.0)))
	var lines: Array = [message]
	if required_cash > 0.0:
		lines.append("Needed: %s" % _format_currency(required_cash))
	if available_cash >= 0.0:
		lines.append("Available: %s" % _format_currency(available_cash))
	lines.append("Sell assets, free up cash, or choose a cheaper %s." % asset_type)
	insufficient_cash_dialog.dialog_text = "\n".join(lines)
	insufficient_cash_dialog.popup_centered(Vector2i(420, 170))


func _ensure_insufficient_cash_dialog() -> void:
	if insufficient_cash_dialog != null:
		return
	insufficient_cash_dialog = AcceptDialog.new()
	insufficient_cash_dialog.name = "LifeInsufficientCashDialog"
	insufficient_cash_dialog.title = "Not Enough Cash"
	insufficient_cash_dialog.dialog_text = "Not enough cash."
	insufficient_cash_dialog.unresizable = true
	add_child(insufficient_cash_dialog)
	insufficient_cash_dialog.add_theme_stylebox_override("panel", _make_stylebox(COLOR_PANEL, COLOR_BORDER, 1))
	insufficient_cash_dialog.add_theme_color_override("font_color", COLOR_TEXT)
	insufficient_cash_dialog.add_theme_color_override("title_color", COLOR_BROWN)
	insufficient_cash_dialog.add_theme_font_size_override("font_size", 13)
	var ok_button: Button = insufficient_cash_dialog.get_ok_button()
	if ok_button != null:
		ok_button.text = "OK"
		_style_button(ok_button)


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


func _selected_basics_tier_id() -> String:
	var rows: Array = snapshot.get("basics_tiers", [])
	if rows.is_empty():
		return "stable"
	var index: int = clampi(int(round(basics_slider.value if basics_slider != null else 0.0)), 0, rows.size() - 1)
	var row: Variant = rows[index]
	if typeof(row) == TYPE_DICTIONARY:
		var tier: Dictionary = row
		return str(tier.get("id", "stable"))
	return "stable"


func _selected_basics_tier_data() -> Dictionary:
	var rows: Array = snapshot.get("basics_tiers", [])
	var tier_id: String = _selected_basics_tier_id()
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("id", "")) == tier_id:
			return row
	return snapshot.get("basics_tier", {})


func _basics_tier_index(tier_id: String) -> int:
	var rows: Array = snapshot.get("basics_tiers", [])
	for index in range(rows.size()):
		var row_value: Variant = rows[index]
		if typeof(row_value) == TYPE_DICTIONARY:
			var row: Dictionary = row_value
			if str(row.get("id", "")) == tier_id:
				return index
	return -1


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
	label.add_theme_font_size_override("font_size", maxi(size, LIFE_FONT_SIZE))


func _style_buttons(root: Node) -> void:
	for child in root.get_children():
		if child is Button:
			_style_button(child)
		_style_buttons(child)


func _style_button(button: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL_ALT
	style.border_color = COLOR_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT)
	button.add_theme_font_size_override("font_size", LIFE_FONT_SIZE)


func _style_primary_buttons() -> void:
	_style_primary_button(update_plan_button)


func _style_primary_button(button: Button) -> void:
	if button == null:
		return
	UiTheme.style_button(button, "desktop_primary")


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
