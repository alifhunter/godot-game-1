extends Control

const SECTION_ORDER := ["dashboard", "markets", "portfolio", "help"]
const COLOR_PANEL_BLUE := Color(0.109804, 0.14902, 0.184314, 0.94)
const COLOR_PANEL_BLUE_ALT := Color(0.0901961, 0.129412, 0.164706, 0.96)
const COLOR_PANEL_GREEN := Color(0.0862745, 0.152941, 0.133333, 0.95)
const COLOR_PANEL_GOLD := Color(0.192157, 0.152941, 0.0823529, 0.95)
const COLOR_BORDER := Color(0.333333, 0.462745, 0.580392, 0.8)
const COLOR_TEXT := Color(0.92549, 0.941176, 0.956863, 1)
const COLOR_MUTED := Color(0.694118, 0.756863, 0.803922, 1)
const COLOR_POSITIVE := Color(0.513726, 0.886275, 0.662745, 1)
const COLOR_NEGATIVE := Color(0.968627, 0.513726, 0.513726, 1)
const COLOR_WARNING := Color(0.980392, 0.792157, 0.392157, 1)
const COLOR_ACCENT := Color(0.560784, 0.772549, 1, 1)
const TOAST_DURATION_SECONDS := 5.0
const HOLDINGS_TICKER_WIDTH := 90.0
const HOLDINGS_PRICE_WIDTH := 120.0
const HOLDINGS_AVERAGE_WIDTH := 110.0
const HOLDINGS_LOT_WIDTH := 80.0
const HOLDINGS_INVESTED_WIDTH := 120.0
const HOLDINGS_PNL_WIDTH := 120.0
const HOLDINGS_PERCENT_WIDTH := 80.0
const HISTORY_ACTION_WIDTH := 150.0
const HISTORY_AMOUNT_WIDTH := 120.0
const HISTORY_QTY_WIDTH := 70.0
const HISTORY_PRICE_WIDTH := 90.0
const HISTORY_DATE_WIDTH := 110.0

var selected_company_id: String = ""
var displayed_company_ids: Array = []
var tutorial_dialog: AcceptDialog = null
var selected_lots: int = 1
var active_section_id: String = "dashboard"
var status_message: String = "Ready."
var portfolio_trading_calendar = preload("res://systems/TradingCalendar.gd").new()

@onready var sidebar_panel: PanelContainer = $Margin/RootVBox/ShellHBox/SidebarPanel
@onready var top_bar_panel: PanelContainer = $Margin/RootVBox/TopBarPanel
@onready var dashboard_button: Button = $Margin/RootVBox/ShellHBox/SidebarPanel/SidebarMargin/SidebarVBox/NavigationButtons/DashboardButton
@onready var markets_button: Button = $Margin/RootVBox/ShellHBox/SidebarPanel/SidebarMargin/SidebarVBox/NavigationButtons/MarketsButton
@onready var portfolio_button: Button = $Margin/RootVBox/ShellHBox/SidebarPanel/SidebarMargin/SidebarVBox/NavigationButtons/PortfolioButton
@onready var help_button: Button = $Margin/RootVBox/ShellHBox/SidebarPanel/SidebarMargin/SidebarVBox/NavigationButtons/HelpButton
@onready var back_to_menu_button: Button = $Margin/RootVBox/ShellHBox/SidebarPanel/SidebarMargin/SidebarVBox/BackToMenuButton
@onready var sidebar_intro_label: Label = $Margin/RootVBox/ShellHBox/SidebarPanel/SidebarMargin/SidebarVBox/SidebarIntroLabel
@onready var sidebar_focus_label: Label = $Margin/RootVBox/ShellHBox/SidebarPanel/SidebarMargin/SidebarVBox/SidebarFocusLabel
@onready var sidebar_hint_label: Label = $Margin/RootVBox/ShellHBox/SidebarPanel/SidebarMargin/SidebarVBox/SidebarHintLabel
@onready var content_tabs: TabContainer = $Margin/RootVBox/ShellHBox/MainVBox/ContentTabs
@onready var top_section_label: Label = $Margin/RootVBox/TopBarPanel/TopBarMargin/TopBarVBox/TitleRow/TopSectionLabel
@onready var advance_day_button: Button = $Margin/RootVBox/TopBarPanel/TopBarMargin/TopBarVBox/TitleRow/AdvanceDayButton
@onready var top_day_label: Label = $Margin/RootVBox/TopBarPanel/TopBarMargin/TopBarVBox/StatsFlow/TopDayLabel
@onready var top_market_label: Label = $Margin/RootVBox/TopBarPanel/TopBarMargin/TopBarVBox/StatsFlow/TopMarketLabel
@onready var top_equity_label: Label = $Margin/RootVBox/TopBarPanel/TopBarMargin/TopBarVBox/StatsFlow/TopEquityLabel
@onready var top_focus_label: Label = $Margin/RootVBox/TopBarPanel/TopBarMargin/TopBarVBox/StatsFlow/TopFocusLabel
@onready var objective_label: Label = $Margin/RootVBox/TopBarPanel/TopBarMargin/TopBarVBox/ObjectiveLabel
@onready var subtitle_label: Label = $Margin/RootVBox/TopBarPanel/TopBarMargin/TopBarVBox/TitleRow/TitleWrap/SubtitleLabel

@onready var dashboard_grid: GridContainer = %DashboardView/Scroll/ContentGrid
@onready var desk_panel: PanelContainer = %DashboardView/Scroll/ContentGrid/DeskPanel
@onready var action_panel: PanelContainer = %DashboardView/Scroll/ContentGrid/ActionPanel
@onready var detail_panel: PanelContainer = %DashboardView/Scroll/ContentGrid/DetailPanel
@onready var broker_panel: PanelContainer = %DashboardView/Scroll/ContentGrid/BrokerPanel
@onready var summary_panel: PanelContainer = %DashboardView/Scroll/ContentGrid/SummaryPanel
@onready var day_label: Label = %DashboardView/Scroll/ContentGrid/DeskPanel/DeskMargin/DeskVBox/DayLabel
@onready var cash_label: Label = %DashboardView/Scroll/ContentGrid/DeskPanel/DeskMargin/DeskVBox/CashLabel
@onready var equity_label: Label = %DashboardView/Scroll/ContentGrid/DeskPanel/DeskMargin/DeskVBox/EquityLabel
@onready var status_label: Label = %DashboardView/Scroll/ContentGrid/DeskPanel/DeskMargin/DeskVBox/StatusLabel
@onready var guide_label: Label = %DashboardView/Scroll/ContentGrid/DeskPanel/DeskMargin/DeskVBox/GuideLabel
@onready var selection_label: Label = %DashboardView/Scroll/ContentGrid/ActionPanel/ActionMargin/ActionVBox/SelectionLabel
@onready var action_hint_label: Label = %DashboardView/Scroll/ContentGrid/ActionPanel/ActionMargin/ActionVBox/ActionHintLabel
@onready var trade_rule_label: Label = %DashboardView/Scroll/ContentGrid/ActionPanel/ActionMargin/ActionVBox/TradeRuleLabel
@onready var lot_spin_box: SpinBox = %DashboardView/Scroll/ContentGrid/ActionPanel/ActionMargin/ActionVBox/SizingRow/LotSpinBox
@onready var order_preview_label: Label = %DashboardView/Scroll/ContentGrid/ActionPanel/ActionMargin/ActionVBox/OrderPreviewLabel
@onready var buy_button: Button = %DashboardView/Scroll/ContentGrid/ActionPanel/ActionMargin/ActionVBox/TradeButtonRow/BuyButton
@onready var sell_button: Button = %DashboardView/Scroll/ContentGrid/ActionPanel/ActionMargin/ActionVBox/TradeButtonRow/SellButton
@onready var company_name_label: Label = %DashboardView/Scroll/ContentGrid/DetailPanel/DetailMargin/DetailVBox/CompanyNameLabel
@onready var sector_label: Label = %DashboardView/Scroll/ContentGrid/DetailPanel/DetailMargin/DetailVBox/SectorLabel
@onready var price_label: Label = %DashboardView/Scroll/ContentGrid/DetailPanel/DetailMargin/DetailVBox/PriceLabel
@onready var factor_label: Label = %DashboardView/Scroll/ContentGrid/DetailPanel/DetailMargin/DetailVBox/FactorLabel
@onready var financial_label: Label = %DashboardView/Scroll/ContentGrid/DetailPanel/DetailMargin/DetailVBox/FinancialLabel
@onready var setup_label: Label = %DashboardView/Scroll/ContentGrid/DetailPanel/DetailMargin/DetailVBox/SetupLabel
@onready var support_label: Label = %DashboardView/Scroll/ContentGrid/DetailPanel/DetailMargin/DetailVBox/SupportLabel
@onready var risk_label: Label = %DashboardView/Scroll/ContentGrid/DetailPanel/DetailMargin/DetailVBox/RiskLabel
@onready var event_label: Label = %DashboardView/Scroll/ContentGrid/DetailPanel/DetailMargin/DetailVBox/EventLabel
@onready var history_label: Label = %DashboardView/Scroll/ContentGrid/DetailPanel/DetailMargin/DetailVBox/HistoryLabel
@onready var financial_history_label: RichTextLabel = %DashboardView/Scroll/ContentGrid/DetailPanel/DetailMargin/DetailVBox/FinancialHistoryLabel
@onready var broker_pressure_label: Label = %DashboardView/Scroll/ContentGrid/BrokerPanel/BrokerMargin/BrokerVBox/BrokerPressureLabel
@onready var broker_label: Label = %DashboardView/Scroll/ContentGrid/BrokerPanel/BrokerMargin/BrokerVBox/BrokerLabel
@onready var broker_hint_label: Label = %DashboardView/Scroll/ContentGrid/BrokerPanel/BrokerMargin/BrokerVBox/BrokerHintLabel
@onready var review_headline_label: Label = %DashboardView/Scroll/ContentGrid/SummaryPanel/SummaryMargin/SummaryVBox/ReviewHeadlineLabel
@onready var summary_label: Label = %DashboardView/Scroll/ContentGrid/SummaryPanel/SummaryMargin/SummaryVBox/SummaryLabel
@onready var movers_label: Label = %DashboardView/Scroll/ContentGrid/SummaryPanel/SummaryMargin/SummaryVBox/MoversLabel
@onready var reflection_label: Label = %DashboardView/Scroll/ContentGrid/SummaryPanel/SummaryMargin/SummaryVBox/ReflectionLabel

@onready var markets_grid: GridContainer = %MarketsView/Scroll/ContentGrid
@onready var watchlist_panel: PanelContainer = %MarketsView/Scroll/ContentGrid/WatchlistPanel
@onready var sector_panel: PanelContainer = %MarketsView/Scroll/ContentGrid/SectorPanel
@onready var watchlist_hint_label: Label = %MarketsView/Scroll/ContentGrid/WatchlistPanel/WatchlistMargin/WatchlistVBox/WatchlistHintLabel
@onready var selected_market_label: Label = %MarketsView/Scroll/ContentGrid/WatchlistPanel/WatchlistMargin/WatchlistVBox/SelectedMarketLabel
@onready var watchlist_summary_label: Label = %MarketsView/Scroll/ContentGrid/WatchlistPanel/WatchlistMargin/WatchlistVBox/WatchlistSummaryLabel
@onready var company_list: ItemList = %MarketsView/Scroll/ContentGrid/WatchlistPanel/WatchlistMargin/WatchlistVBox/CompanyList
@onready var market_hint_label: Label = %MarketsView/Scroll/ContentGrid/SectorPanel/SectorMargin/SectorVBox/MarketHintLabel
@onready var sector_summary_label: Label = %MarketsView/Scroll/ContentGrid/SectorPanel/SectorMargin/SectorVBox/SectorSummaryLabel
@onready var sector_list_label: Label = %MarketsView/Scroll/ContentGrid/SectorPanel/SectorMargin/SectorVBox/SectorListLabel

@onready var portfolio_grid: GridContainer = %PortfolioView/Scroll/ContentVBox/ContentGrid
@onready var portfolio_summary_panel: PanelContainer = %PortfolioView/Scroll/ContentVBox/SummaryPanel
@onready var portfolio_summary_grid: GridContainer = %PortfolioView/Scroll/ContentVBox/SummaryPanel/SummaryMargin/SummaryGrid
@onready var portfolio_panel: PanelContainer = %PortfolioView/Scroll/ContentVBox/ContentGrid/PortfolioPanel
@onready var trade_history_panel: PanelContainer = %PortfolioView/Scroll/ContentVBox/ContentGrid/TradeHistoryPanel
@onready var balance_value_label: Label = %PortfolioView/Scroll/ContentVBox/SummaryPanel/SummaryMargin/SummaryGrid/BalanceCard/BalanceValueLabel
@onready var invested_value_label: Label = %PortfolioView/Scroll/ContentVBox/SummaryPanel/SummaryMargin/SummaryGrid/InvestedCard/InvestedValueLabel
@onready var pnl_value_label: Label = %PortfolioView/Scroll/ContentVBox/SummaryPanel/SummaryMargin/SummaryGrid/PnLCard/PnLValueLabel
@onready var equity_value_label: Label = %PortfolioView/Scroll/ContentVBox/SummaryPanel/SummaryMargin/SummaryGrid/EquityCard/EquityValueLabel
@onready var holdings_rows_vbox: VBoxContainer = %PortfolioView/Scroll/ContentVBox/ContentGrid/PortfolioPanel/PortfolioMargin/PortfolioVBox/HoldingsScroll/HoldingsTableVBox/HoldingsRowsVBox
@onready var holdings_empty_label: Label = %PortfolioView/Scroll/ContentVBox/ContentGrid/PortfolioPanel/PortfolioMargin/PortfolioVBox/HoldingsScroll/HoldingsTableVBox/HoldingsRowsVBox/HoldingsEmptyLabel
@onready var trade_history_rows_vbox: VBoxContainer = %PortfolioView/Scroll/ContentVBox/ContentGrid/TradeHistoryPanel/TradeHistoryMargin/TradeHistoryVBox/TradeHistoryScroll/TradeHistoryTableVBox/TradeHistoryRowsVBox
@onready var trade_history_empty_label: Label = %PortfolioView/Scroll/ContentVBox/ContentGrid/TradeHistoryPanel/TradeHistoryMargin/TradeHistoryVBox/TradeHistoryScroll/TradeHistoryTableVBox/TradeHistoryRowsVBox/TradeHistoryEmptyLabel

@onready var help_panel: PanelContainer = %HelpView/HelpPanel
@onready var help_text_label: RichTextLabel = %HelpView/HelpPanel/HelpMargin/HelpVBox/HelpTextLabel
@onready var toast_panel: PanelContainer = $ToastOverlay/ToastPanel
@onready var toast_message_label: Label = $ToastOverlay/ToastPanel/ToastMargin/ToastHBox/ToastMessageLabel
@onready var toast_close_button: Button = $ToastOverlay/ToastPanel/ToastMargin/ToastHBox/ToastCloseButton
@onready var toast_timer: Timer = $ToastTimer


func _ready() -> void:
	_ensure_tutorial_dialog()
	_apply_visual_theme()
	_apply_compact_layout()
	dashboard_button.pressed.connect(_on_dashboard_pressed)
	markets_button.pressed.connect(_on_markets_pressed)
	portfolio_button.pressed.connect(_on_portfolio_pressed)
	help_button.pressed.connect(_on_help_pressed)
	back_to_menu_button.pressed.connect(_on_menu_pressed)
	toast_close_button.pressed.connect(_on_toast_close_pressed)
	toast_timer.timeout.connect(_hide_toast)
	company_list.item_selected.connect(_on_company_selected)
	lot_spin_box.value_changed.connect(_on_lot_size_changed)
	buy_button.pressed.connect(_on_buy_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	advance_day_button.pressed.connect(_on_next_day_pressed)
	get_viewport().size_changed.connect(_update_responsive_layout)
	GameManager.portfolio_changed.connect(_refresh_all)
	GameManager.price_formed.connect(_on_day_progressed)
	GameManager.summary_ready.connect(_on_summary_ready)
	call_deferred("_update_responsive_layout")
	day_label.visible = false
	_set_active_section(active_section_id)
	_refresh_all()
	call_deferred("_show_tutorial_if_needed")


func _apply_compact_layout() -> void:
	sidebar_intro_label.visible = false
	sidebar_focus_label.visible = false
	sidebar_hint_label.visible = false
	subtitle_label.visible = false
	objective_label.visible = false
	status_label.visible = false
	guide_label.visible = false
	watchlist_hint_label.visible = false
	market_hint_label.visible = false


func _update_responsive_layout() -> void:
	var content_width: float = content_tabs.get_rect().size.x
	if content_width <= 0.0:
		content_width = get_viewport_rect().size.x - 320.0

	dashboard_grid.columns = 2 if content_width >= 1280.0 else 1
	markets_grid.columns = 2 if content_width >= 1100.0 else 1
	portfolio_grid.columns = 2 if content_width >= 1100.0 else 1
	portfolio_summary_grid.columns = 4 if content_width >= 1200.0 else 2
	company_list.custom_minimum_size = Vector2(0, 260 if markets_grid.columns == 1 else 360)


func _refresh_all() -> void:
	if not RunState.has_active_run():
		status_message = "No active run. Return to menu to begin."
		_refresh_header()
		_refresh_sidebar()
		return

	if selected_company_id.is_empty() or RunState.get_company(selected_company_id).is_empty():
		selected_company_id = str(RunState.company_order[0])

	_refresh_header()
	_refresh_sidebar()
	_refresh_dashboard()
	_refresh_markets()
	_refresh_portfolio()
	_refresh_help()


func _refresh_header() -> void:
	var focus_snapshot: Dictionary = GameManager.get_company_snapshot(selected_company_id)
	var trading_day_number: int = max(RunState.day_index + 1, 1)
	var current_trade_date: Dictionary = GameManager.get_current_trade_date()
	top_section_label.text = _section_label(active_section_id)
	top_day_label.text = "DAY %d  |  %s" % [trading_day_number, GameManager.format_trade_date(current_trade_date)]
	top_market_label.text = "MARKET %s" % _format_change(RunState.market_sentiment)
	top_equity_label.text = "EQUITY %s" % _format_currency(RunState.get_total_equity())
	if focus_snapshot.is_empty():
		top_focus_label.text = "FOCUS -"
	else:
		top_focus_label.text = "FOCUS %s @ %s" % [
			str(focus_snapshot.get("ticker", "")),
			_format_currency(float(focus_snapshot.get("current_price", 0.0)))
		]
	objective_label.text = ""
	advance_day_button.disabled = not RunState.has_active_run()
	advance_day_button.text = "Advance Day"
	_set_label_tone(top_market_label, _color_for_change(RunState.market_sentiment))
	_set_label_tone(top_focus_label, COLOR_ACCENT)
	_set_label_tone(top_section_label, COLOR_WARNING)
	_set_label_tone(top_day_label, COLOR_WARNING)


func _refresh_sidebar() -> void:
	sidebar_hint_label.text = ""
	dashboard_button.set_pressed_no_signal(active_section_id == "dashboard")
	markets_button.set_pressed_no_signal(active_section_id == "markets")
	portfolio_button.set_pressed_no_signal(active_section_id == "portfolio")
	help_button.set_pressed_no_signal(active_section_id == "help")


func _refresh_dashboard() -> void:
	var snapshot: Dictionary = GameManager.get_company_snapshot(selected_company_id)
	if snapshot.is_empty():
		status_label.text = "No stock selected."
		financial_history_label.text = "Generated history unavailable."
		return

	lot_spin_box.set_value_no_signal(float(_selected_lots()))
	cash_label.text = "Available cash: %s" % _format_currency(float(RunState.player_portfolio.get("cash", 0.0)))
	equity_label.text = "Total equity: %s" % _format_currency(RunState.get_total_equity())
	status_label.text = status_message
	guide_label.text = ""
	action_hint_label.text = _build_action_hint(snapshot)
	company_name_label.text = "%s  |  %s" % [snapshot.get("ticker", ""), snapshot.get("name", "")]
	sector_label.text = "Sector: %s" % snapshot.get("sector_name", "Unknown")
	price_label.text = "Price now: %s  |  Daily move: %s" % [
		_format_currency(float(snapshot.get("current_price", 0.0))),
		_format_change(float(snapshot.get("daily_change_pct", 0.0)))
	]
	factor_label.text = "Company profile: quality %d  |  growth %d  |  risk %d  |  board %s  |  tick Rp %.0f  |  held %d lot(s) / %d share(s)" % [
		int(snapshot.get("quality_score", 0)),
		int(snapshot.get("growth_score", 0)),
		int(snapshot.get("risk_score", 0)),
		str(snapshot.get("listing_board", "main")).capitalize(),
		float(snapshot.get("tick_size", 1.0)),
		int(snapshot.get("lots_owned", 0)),
		int(snapshot.get("shares_owned", 0))
	]
	financial_label.text = "Financials:\n%s" % _format_financial_block(snapshot.get("financials", {}))
	setup_label.text = "Setup read:\n%s" % _build_setup_read(snapshot)
	support_label.text = "Supportive signals:\n%s" % _build_support_signals(snapshot)
	risk_label.text = "Risk signals:\n%s" % _build_risk_signals(snapshot)
	event_label.text = "Visible inputs:\nEvent tags: %s\nNarratives: %s" % [
		_join_or_default(snapshot.get("event_tags", []), "none today"),
		_join_or_default(snapshot.get("narrative_tags", []), "none")
	]
	history_label.text = "Recent closes:\n%s" % _format_history(snapshot.get("price_history", []))
	financial_history_label.text = _format_financial_history_block(
		snapshot.get("financial_history", []),
		snapshot.get("financials", {})
	)

	var broker_flow: Dictionary = snapshot.get("broker_flow", {})
	broker_pressure_label.text = "Pressure read: %s  |  Buyer: %s  |  Seller: %s" % [
		str(broker_flow.get("flow_tag", "neutral")).capitalize(),
		str(broker_flow.get("dominant_buyer", "balanced")).capitalize(),
		str(broker_flow.get("dominant_seller", "balanced")).capitalize()
	]
	broker_label.text = "Net reads:\nRetail %+.0f  |  Foreign %+.0f\nInstitution %+.0f  |  Zombie %+.0f\n\nDominant buyer: %s\nDominant seller: %s\nTape label: %s" % [
		float(broker_flow.get("retail_net", 0.0)),
		float(broker_flow.get("foreign_net", 0.0)),
		float(broker_flow.get("institution_net", 0.0)),
		float(broker_flow.get("zombie_net", 0.0)),
		str(broker_flow.get("dominant_buyer", "balanced")).capitalize(),
		str(broker_flow.get("dominant_seller", "balanced")).capitalize(),
		str(broker_flow.get("flow_tag", "neutral")).capitalize()
	]
	broker_hint_label.text = _build_broker_hint(snapshot)
	_refresh_order_controls(snapshot)
	_refresh_summary()
	_set_label_tone(price_label, _color_for_change(float(snapshot.get("daily_change_pct", 0.0))))
	_set_label_tone(broker_pressure_label, _color_for_flow(str(broker_flow.get("flow_tag", "neutral"))))


func _refresh_markets() -> void:
	_refresh_company_list()
	_refresh_sector_list()


func _refresh_portfolio() -> void:
	var portfolio: Dictionary = GameManager.get_portfolio_snapshot()
	var cash_value: float = float(portfolio.get("cash", 0.0))
	var invested_cost: float = float(portfolio.get("invested_cost", 0.0))
	var unrealized_pnl: float = float(portfolio.get("unrealized_pnl", 0.0))
	var unrealized_pnl_pct: float = float(portfolio.get("unrealized_pnl_pct", 0.0))
	var equity_value: float = float(portfolio.get("equity", 0.0))

	balance_value_label.text = _format_currency(cash_value)
	invested_value_label.text = _format_currency(invested_cost)
	pnl_value_label.text = "%s (%s)" % [
		_format_signed_currency(unrealized_pnl),
		_format_change(unrealized_pnl_pct)
	]
	equity_value_label.text = _format_currency(equity_value)
	_set_label_tone(pnl_value_label, _color_for_change(unrealized_pnl_pct))

	_refresh_holdings_rows(portfolio.get("holdings", []))
	_refresh_trade_history()


func _refresh_help() -> void:
	help_text_label.text = _build_help_text()


func _refresh_company_list() -> void:
	displayed_company_ids.clear()
	company_list.clear()
	var advancers: int = 0
	var decliners: int = 0
	var strongest_flow_ticker: String = ""
	var strongest_flow_value: float = -INF

	for row_value in GameManager.get_company_rows():
		var row: Dictionary = row_value
		displayed_company_ids.append(str(row.get("id", "")))
		var change_pct: float = float(row.get("daily_change_pct", 0.0))
		var broker_flow: Dictionary = row.get("broker_flow", {})
		var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))
		var flow_badge: String = _flow_badge(flow_tag)
		var line: String = "%s  %s  %s  %s" % [
			row.get("ticker", ""),
			_format_currency(float(row.get("current_price", 0.0))),
			_format_change(change_pct),
			flow_badge
		]
		company_list.add_item(line)
		var item_index: int = company_list.item_count - 1
		company_list.set_item_tooltip(item_index, _watchlist_tooltip(row))
		company_list.set_item_custom_fg_color(item_index, _color_for_change(change_pct))
		company_list.set_item_custom_bg_color(item_index, _color_for_flow_bg(flow_tag))

		if change_pct > 0.0:
			advancers += 1
		elif change_pct < 0.0:
			decliners += 1

		var net_pressure: float = abs(float(broker_flow.get("net_pressure", 0.0)))
		if net_pressure > strongest_flow_value:
			strongest_flow_value = net_pressure
			strongest_flow_ticker = str(row.get("ticker", ""))

	var selected_index: int = displayed_company_ids.find(selected_company_id)
	if selected_index == -1 and not displayed_company_ids.is_empty():
		selected_company_id = str(displayed_company_ids[0])
		selected_index = 0

	if selected_index >= 0:
		company_list.select(selected_index)

	var flat_count: int = max(displayed_company_ids.size() - advancers - decliners, 0)
	watchlist_summary_label.text = "Advancers: %d  |  Decliners: %d  |  Flat: %d  |  Strongest tape: %s" % [
		advancers,
		decliners,
		flat_count,
		strongest_flow_ticker if not strongest_flow_ticker.is_empty() else "n/a"
	]

	var focus_snapshot: Dictionary = GameManager.get_company_snapshot(selected_company_id)
	if focus_snapshot.is_empty():
		selected_market_label.text = "Current focus: none selected."
	else:
		selected_market_label.text = "Current focus: %s | %s | %s" % [
			str(focus_snapshot.get("ticker", "")),
			_format_currency(float(focus_snapshot.get("current_price", 0.0))),
			_format_change(float(focus_snapshot.get("daily_change_pct", 0.0)))
		]
		_set_label_tone(selected_market_label, _color_for_change(float(focus_snapshot.get("daily_change_pct", 0.0))))


func _refresh_sector_list() -> void:
	var sector_rows: Array = GameManager.get_sector_rows()
	if sector_rows.is_empty():
		sector_summary_label.text = "Sector summary unavailable."
		sector_list_label.text = "No sector data available."
		return

	var positive_sectors: int = 0
	var negative_sectors: int = 0
	var strongest_sector_name: String = ""
	var strongest_sector_value: float = -INF
	var blocks: Array = []

	for row_value in sector_rows:
		var row: Dictionary = row_value
		var average_change_pct: float = float(row.get("average_change_pct", 0.0))
		if average_change_pct > 0.0:
			positive_sectors += 1
		elif average_change_pct < 0.0:
			negative_sectors += 1

		var magnitude: float = abs(average_change_pct)
		if magnitude > strongest_sector_value:
			strongest_sector_value = magnitude
			strongest_sector_name = str(row.get("name", ""))

		blocks.append(_format_sector_block(row))

	var flat_sectors: int = max(sector_rows.size() - positive_sectors - negative_sectors, 0)
	sector_summary_label.text = "Green sectors: %d  |  Red sectors: %d  |  Flat sectors: %d  |  Loudest tape: %s" % [
		positive_sectors,
		negative_sectors,
		flat_sectors,
		strongest_sector_name if not strongest_sector_name.is_empty() else "n/a"
	]
	sector_list_label.text = "\n\n".join(blocks)


func _refresh_trade_history() -> void:
	var trades: Array = GameManager.get_trade_history()
	_clear_dynamic_rows(trade_history_rows_vbox, trade_history_empty_label)
	trade_history_empty_label.visible = trades.is_empty()
	if trades.is_empty():
		trade_history_empty_label.text = "No trades yet."
		return

	for trade_value in trades:
		var trade: Dictionary = trade_value
		trade_history_rows_vbox.add_child(_build_trade_history_row(trade))


func _refresh_holdings_rows(holdings: Array) -> void:
	_clear_dynamic_rows(holdings_rows_vbox, holdings_empty_label)
	holdings_empty_label.visible = holdings.is_empty()
	if holdings.is_empty():
		holdings_empty_label.text = "No open positions yet."
		return

	for holding_value in holdings:
		var holding: Dictionary = holding_value
		holdings_rows_vbox.add_child(_build_holding_row(holding))


func _clear_dynamic_rows(container: VBoxContainer, preserved_node: Node) -> void:
	for child in container.get_children():
		if child == preserved_node:
			continue
		container.remove_child(child)
		child.queue_free()


func _build_holding_row(holding: Dictionary) -> Control:
	var row_wrap: VBoxContainer = VBoxContainer.new()
	row_wrap.add_theme_constant_override("separation", 6)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row_wrap.add_child(row)

	var ticker_label: Label = _build_table_cell(
		str(holding.get("ticker", "")),
		HOLDINGS_TICKER_WIDTH,
		COLOR_TEXT
	)
	row.add_child(ticker_label)
	row.add_child(_build_table_cell(
		_format_currency(float(holding.get("current_price", 0.0))),
		HOLDINGS_PRICE_WIDTH,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_currency(float(holding.get("average_price", 0.0))),
		HOLDINGS_AVERAGE_WIDTH,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		str(int(holding.get("lots", 0))),
		HOLDINGS_LOT_WIDTH,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_currency(float(holding.get("invested_cost", 0.0))),
		HOLDINGS_INVESTED_WIDTH,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	var pnl_pct: float = float(holding.get("unrealized_pnl_pct", 0.0))
	var pnl_color: Color = _color_for_change(pnl_pct)
	row.add_child(_build_table_cell(
		_format_signed_currency(float(holding.get("unrealized_pnl", 0.0))),
		HOLDINGS_PNL_WIDTH,
		pnl_color,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_change(pnl_pct),
		HOLDINGS_PERCENT_WIDTH,
		pnl_color,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))

	var separator: HSeparator = HSeparator.new()
	row_wrap.add_child(separator)
	return row_wrap


func _build_trade_history_row(trade: Dictionary) -> Control:
	var row_wrap: VBoxContainer = VBoxContainer.new()
	row_wrap.add_theme_constant_override("separation", 6)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row_wrap.add_child(row)

	var side: String = str(trade.get("side", "")).to_upper()
	var action_color: Color = COLOR_POSITIVE if side == "BUY" else COLOR_NEGATIVE
	var qty_text: String = "%d lot(s)" % int(trade.get("lots", 0))
	var price_text: String = "-" if side.is_empty() else _format_currency(float(trade.get("price_per_share", 0.0)))

	row.add_child(_build_table_cell(
		"%s %s" % [side, str(trade.get("ticker", ""))],
		HISTORY_ACTION_WIDTH,
		action_color
	))
	row.add_child(_build_table_cell(
		_format_signed_currency(float(trade.get("net_cash_impact", 0.0))),
		HISTORY_AMOUNT_WIDTH,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		qty_text,
		HISTORY_QTY_WIDTH,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		price_text,
		HISTORY_PRICE_WIDTH,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_trade_date_short(int(trade.get("day_index", 0))),
		HISTORY_DATE_WIDTH,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))

	var separator: HSeparator = HSeparator.new()
	row_wrap.add_child(separator)
	return row_wrap


func _build_table_cell(
	text: String,
	minimum_width: float,
	font_color: Color,
	expand: bool = false,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(minimum_width, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL if expand else Control.SIZE_FILL
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = text
	label.clip_text = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_color_override("font_color", font_color)
	return label


func _format_trade_date_short(day_index: int) -> String:
	var date_info: Dictionary = portfolio_trading_calendar.trade_date_for_index(day_index + 1)
	var full_date: String = portfolio_trading_calendar.format_date(date_info)
	return full_date.replace(",", "")


func _refresh_summary() -> void:
	var summary: Dictionary = GameManager.get_latest_summary()
	if summary.is_empty():
		review_headline_label.text = "Review headline: Waiting for the first close."
		summary_label.text = "No closing summary yet.\nAdvance the first day to see the market review."
		movers_label.text = "Top movers, best accumulation, and heaviest distribution will appear after the close."
		reflection_label.text = "Tomorrow's prompt: pick one stock you want to understand better before risking more capital."
		return

	var headline: String = _build_review_headline(summary)
	review_headline_label.text = "Review headline: %s" % headline
	summary_label.text = "Day %d close:\nPortfolio move: %s\n\n%s" % [
		int(summary.get("day_index", 0)),
		_format_signed_currency(float(summary.get("portfolio_delta", 0.0))),
		str(summary.get("explanation", ""))
	]

	var mover_lines: Array = []
	var winner: Dictionary = summary.get("biggest_winner", {})
	var loser: Dictionary = summary.get("biggest_loser", {})
	if not winner.is_empty():
		mover_lines.append("Best gainer: %s %s" % [winner.get("ticker", ""), _format_change(float(winner.get("change_pct", 0.0)))])
	if not loser.is_empty():
		mover_lines.append("Weakest name: %s %s" % [loser.get("ticker", ""), _format_change(float(loser.get("change_pct", 0.0)))])

	for row_value in summary.get("top_movers", []):
		var row: Dictionary = row_value
		mover_lines.append("Mover: %s %s" % [row.get("ticker", ""), _format_change(float(row.get("change_pct", 0.0)))])

	var best_accumulation: Dictionary = summary.get("best_accumulation", {})
	if not best_accumulation.is_empty():
		mover_lines.append("Cleanest accumulation: %s" % best_accumulation.get("ticker", ""))

	var heaviest_distribution: Dictionary = summary.get("heaviest_distribution", {})
	if not heaviest_distribution.is_empty():
		mover_lines.append("Heaviest distribution: %s" % heaviest_distribution.get("ticker", ""))

	movers_label.text = "\n".join(mover_lines)
	reflection_label.text = _build_reflection_prompt(summary)
	_set_label_tone(
		review_headline_label,
		_color_for_change(float(summary.get("portfolio_delta", 0.0)) / max(float(summary.get("portfolio_value", 1.0)), 1.0))
	)


func _on_dashboard_pressed() -> void:
	_set_active_section("dashboard")


func _on_markets_pressed() -> void:
	_set_active_section("markets")


func _on_portfolio_pressed() -> void:
	_set_active_section("portfolio")


func _on_help_pressed() -> void:
	_set_active_section("help")


func _on_company_selected(index: int) -> void:
	if index < 0 or index >= displayed_company_ids.size():
		return

	selected_company_id = str(displayed_company_ids[index])
	_refresh_all()


func _on_buy_pressed() -> void:
	var result: Dictionary = GameManager.buy_lots(selected_company_id, _selected_lots())
	status_message = str(result.get("message", "Order finished."))
	_show_toast(status_message, bool(result.get("success", false)))
	_refresh_all()


func _on_sell_pressed() -> void:
	var result: Dictionary = GameManager.sell_lots(selected_company_id, _selected_lots())
	status_message = str(result.get("message", "Order finished."))
	_show_toast(status_message, bool(result.get("success", false)))
	_refresh_all()


func _show_toast(message: String, is_success: bool) -> void:
	if message.is_empty():
		return

	toast_message_label.text = message
	_apply_toast_theme(is_success)
	toast_panel.visible = true
	toast_timer.stop()
	toast_timer.start(TOAST_DURATION_SECONDS)


func _hide_toast() -> void:
	toast_timer.stop()
	toast_panel.visible = false


func _on_toast_close_pressed() -> void:
	_hide_toast()


func _on_next_day_pressed() -> void:
	status_message = "Advancing day..."
	_refresh_dashboard()
	GameManager.advance_day()


func _on_menu_pressed() -> void:
	GameManager.return_to_menu()


func _on_day_progressed(_day_index: int) -> void:
	status_message = "Market closed."
	_refresh_all()


func _on_summary_ready(_summary: Dictionary) -> void:
	_refresh_summary()


func _on_lot_size_changed(value: float) -> void:
	selected_lots = max(int(round(value)), 1)
	_refresh_sidebar()
	_refresh_dashboard()


func _show_tutorial_if_needed() -> void:
	if not GameManager.should_show_tutorial():
		return

	if tutorial_dialog == null:
		return

	tutorial_dialog.dialog_text = _build_tutorial_text()
	tutorial_dialog.popup_centered()
	GameManager.mark_tutorial_shown()


func _ensure_tutorial_dialog() -> void:
	if tutorial_dialog != null:
		return

	tutorial_dialog = AcceptDialog.new()
	tutorial_dialog.title = "Quick Tutorial"
	tutorial_dialog.dialog_text = ""
	add_child(tutorial_dialog)


func _build_tutorial_text() -> String:
	return "Open Markets and pick one stock first.\n\nThen return to Dashboard to read the setup, check the broker flow, size the order in lots, and use the navbar to advance the day.\n\nPortfolio keeps your holdings and trade history together.\n\nDifficulty: %s." % GameManager.get_current_difficulty_label()


func _build_help_text() -> String:
	return "OVERVIEW\nThe game screen is split into modular views so you can move sections around more easily later.\nSidebar sections now swap self-contained views instead of one giant screen.\n\nOBJECTIVE\nFind the clearest setup, size lightly, then learn from the close.\n\nSECTIONS\n%s\n\n%s\n\n%s\n\nWORKFLOW\n1. Open Markets and choose a stock.\n2. Return to Dashboard to read the setup.\n3. Size the order in lots.\n4. Advance the day.\n5. Review the close.\n\nNOTES\nUse sector context to decide whether a stock is moving with its group or fighting it.\nNewest fills appear first in Trade History so you can audit lots, fees, cash impact, and realized P/L.\n\nCURRENT DIFFICULTY\n%s" % [
		_sidebar_hint_for_section("dashboard"),
		_sidebar_hint_for_section("markets"),
		_sidebar_hint_for_section("portfolio"),
		GameManager.get_current_difficulty_label()
	]


func _refresh_order_controls(snapshot: Dictionary) -> void:
	var current_lots: int = _selected_lots()
	var lot_size: int = GameManager.get_lot_size()
	var requested_shares: int = GameManager.lots_to_shares(current_lots)
	var shares_owned: int = int(snapshot.get("shares_owned", 0))
	var lots_owned: int = int(snapshot.get("lots_owned", 0))
	var odd_lot_remainder: int = int(snapshot.get("odd_lot_remainder", 0))
	var buy_estimate: Dictionary = GameManager.estimate_buy_lots(selected_company_id, current_lots)
	var sell_estimate: Dictionary = GameManager.estimate_sell_lots(selected_company_id, current_lots)
	var portfolio: Dictionary = GameManager.get_portfolio_snapshot()
	var available_cash: float = float(portfolio.get("cash", 0.0))
	var max_sellable_lots: int = int(floor(float(shares_owned) / float(lot_size)))
	var buy_total_cost: float = float(buy_estimate.get("total_cost", 0.0))
	var can_buy: bool = bool(buy_estimate.get("success", false)) and buy_total_cost <= available_cash + 0.0001
	var can_sell: bool = bool(sell_estimate.get("success", false)) and max_sellable_lots >= current_lots

	trade_rule_label.text = "1 lot = %d shares | Tick Rp %.0f | ARA %s (%s) | ARB %s (%s) | Buy fee %s | Sell fee %s" % [
		lot_size,
		float(snapshot.get("tick_size", 1.0)),
		_format_currency(float(snapshot.get("ara_price", 0.0))),
		str(snapshot.get("ara_label", "")),
		_format_currency(float(snapshot.get("arb_price", 0.0))),
		str(snapshot.get("arb_label", "")),
		_format_rate(GameManager.get_buy_fee_rate()),
		_format_rate(GameManager.get_sell_fee_rate())
	]
	buy_button.text = "Buy %d Lot%s" % [current_lots, "" if current_lots == 1 else "s"]
	sell_button.text = "Sell %d Lot%s" % [current_lots, "" if current_lots == 1 else "s"]
	buy_button.disabled = not can_buy
	sell_button.disabled = not can_sell
	selection_label.text = "Selected: %s at %s | Held: %d lot(s) / %d share(s)" % [
		snapshot.get("ticker", ""),
		_format_currency(float(snapshot.get("current_price", 0.0))),
		lots_owned,
		shares_owned
	]

	var preview_lines: Array = [
		"Order preview:",
		"%d lot(s) = %d share(s)" % [current_lots, requested_shares],
		"Buy total: %s (gross %s + fee %s)" % [
			_format_currency(float(buy_estimate.get("total_cost", 0.0))),
			_format_currency(float(buy_estimate.get("gross_value", 0.0))),
			_format_currency(float(buy_estimate.get("fee", 0.0)))
		],
		"Sell net: %s (gross %s - fee %s)" % [
			_format_currency(float(sell_estimate.get("net_proceeds", 0.0))),
			_format_currency(float(sell_estimate.get("gross_value", 0.0))),
			_format_currency(float(sell_estimate.get("fee", 0.0)))
		],
		"Cash after buy: %s" % _format_currency(available_cash - buy_total_cost),
		"Sellable lots right now: %d" % max_sellable_lots
	]
	if odd_lot_remainder > 0:
		preview_lines.append("Legacy odd-lot remainder: %d share(s)." % odd_lot_remainder)

	order_preview_label.text = "\n".join(preview_lines)


func _selected_lots() -> int:
	return max(selected_lots, 1)


func _set_active_section(section_id: String) -> void:
	var normalized_section_id: String = section_id.to_lower()
	if not SECTION_ORDER.has(normalized_section_id):
		normalized_section_id = "dashboard"

	active_section_id = normalized_section_id
	var tab_index: int = SECTION_ORDER.find(active_section_id)
	if tab_index < 0:
		tab_index = 0
	content_tabs.current_tab = tab_index
	_refresh_sidebar()
	_refresh_header()


func _section_label(section_id: String) -> String:
	if section_id == "markets":
		return "Markets"
	if section_id == "portfolio":
		return "Portfolio"
	if section_id == "help":
		return "Help"
	return "Dashboard"


func _sidebar_hint_for_section(section_id: String) -> String:
	if section_id == "markets":
		return "Markets keeps the stock list and sector tape together so you can scan, compare, and pick the next focus name."
	if section_id == "portfolio":
		return "Portfolio keeps positions and trade history in one place so you can review exposure, fees, and realized P/L."
	return "Dashboard keeps the active read together: selected company, broker flow, order sizing, and end-of-day review."


func _format_sector_block(row: Dictionary) -> String:
	return "%s\nTrend bias %s  |  Avg day move %s  |  Vol bias %s\nAdvancers %d  |  Decliners %d  |  Strongest tape %s %s %s" % [
		str(row.get("name", "Unknown")),
		_format_change(float(row.get("trend_bias", 0.0))),
		_format_change(float(row.get("average_change_pct", 0.0))),
		_format_change(float(row.get("volatility_bias", 0.0))),
		int(row.get("advancers", 0)),
		int(row.get("decliners", 0)),
		str(row.get("strongest_ticker", "n/a")),
		_format_change(float(row.get("strongest_change_pct", 0.0))),
		_flow_badge(str(row.get("strongest_flow_tag", "neutral")))
	]


func _format_trade_entry(trade: Dictionary) -> String:
	var side: String = str(trade.get("side", "")).to_upper()
	var header: String = "Day %d | %s | %s | %d lot(s) / %d share(s)" % [
		int(trade.get("day_index", 0)),
		side,
		str(trade.get("ticker", "")),
		int(trade.get("lots", 0)),
		int(trade.get("shares", 0))
	]
	var value_line: String = "@ %s | Gross %s | Fee %s" % [
		_format_currency(float(trade.get("price_per_share", 0.0))),
		_format_currency(float(trade.get("gross_value", 0.0))),
		_format_currency(float(trade.get("fee", 0.0)))
	]
	var cash_line: String = "Cash impact %s | Cash after %s" % [
		_format_signed_currency(float(trade.get("net_cash_impact", 0.0))),
		_format_currency(float(trade.get("cash_after", 0.0)))
	]

	if side == "SELL":
		return "%s\n%s\n%s | Realized %s" % [
			header,
			value_line,
			cash_line,
			_format_signed_currency(float(trade.get("realized_pnl", 0.0)))
		]

	return "%s\n%s\n%s" % [
		header,
		value_line,
		cash_line
	]


func _build_setup_read(snapshot: Dictionary) -> String:
	var quality: int = int(snapshot.get("quality_score", 0))
	var growth: int = int(snapshot.get("growth_score", 0))
	var risk: int = int(snapshot.get("risk_score", 0))
	var daily_change: float = float(snapshot.get("daily_change_pct", 0.0))
	var broker_flow: Dictionary = snapshot.get("broker_flow", {})
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))

	var quality_read: String = "middle-quality name"
	if quality >= 70:
		quality_read = "higher-quality name"
	elif quality <= 55:
		quality_read = "more speculative name"

	var growth_read: String = "with balanced growth"
	if growth >= 68:
		growth_read = "with stronger growth appeal"
	elif growth <= 55:
		growth_read = "with slower growth expectations"

	var risk_read: String = "and controlled risk"
	if risk >= 58:
		risk_read = "but elevated risk"
	elif risk <= 35:
		risk_read = "and relatively contained risk"

	var tape_read: String = "The tape is still waiting for conviction."
	if daily_change > 0.025:
		tape_read = "The tape is already pressing higher."
	elif daily_change < -0.025:
		tape_read = "The tape is under visible pressure."

	var flow_read: String = "Broker flow is not clearly committed yet."
	if flow_tag == "accumulation":
		flow_read = "Broker flow is leaning toward accumulation."
	elif flow_tag == "distribution":
		flow_read = "Broker flow is leaning toward distribution."

	return "%s %s %s. %s %s" % [quality_read.capitalize(), growth_read, risk_read, tape_read, flow_read]


func _build_support_signals(snapshot: Dictionary) -> String:
	var signals: Array = []
	var quality: int = int(snapshot.get("quality_score", 0))
	var growth: int = int(snapshot.get("growth_score", 0))
	var risk: int = int(snapshot.get("risk_score", 0))
	var daily_change: float = float(snapshot.get("daily_change_pct", 0.0))
	var broker_flow: Dictionary = snapshot.get("broker_flow", {})
	var financials: Dictionary = snapshot.get("financials", {})
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))
	var dominant_buyer: String = str(broker_flow.get("dominant_buyer", "balanced"))
	var revenue_growth_yoy: float = float(financials.get("revenue_growth_yoy", 0.0))
	var earnings_growth_yoy: float = float(financials.get("earnings_growth_yoy", 0.0))
	var net_profit_margin: float = float(financials.get("net_profit_margin", 0.0))
	var roe: float = float(financials.get("roe", 0.0))
	var debt_to_equity: float = float(financials.get("debt_to_equity", 0.0))

	if quality >= 68:
		signals.append("- stronger company quality")
	if growth >= 65:
		signals.append("- healthy growth profile")
	if risk <= 35:
		signals.append("- lower relative risk")
	if daily_change > 0.015:
		signals.append("- price already confirms strength")
	if flow_tag == "accumulation":
		signals.append("- broker flow leans supportive")
	if dominant_buyer in ["foreign", "institution", "zombie"]:
		signals.append("- cleaner buyer profile: %s" % dominant_buyer)
	if revenue_growth_yoy >= 12.0:
		signals.append("- revenue is still growing at a healthy clip")
	if earnings_growth_yoy >= 10.0:
		signals.append("- earnings are compounding, not just sales")
	if net_profit_margin >= 8.0:
		signals.append("- margins still show decent operating quality")
	if roe >= 14.0:
		signals.append("- return on equity supports the quality read")
	if debt_to_equity <= 0.5:
		signals.append("- balance sheet leverage stays manageable")

	if signals.is_empty():
		signals.append("- no obvious support edge yet")

	return "\n".join(signals)


func _build_risk_signals(snapshot: Dictionary) -> String:
	var risks: Array = []
	var quality: int = int(snapshot.get("quality_score", 0))
	var growth: int = int(snapshot.get("growth_score", 0))
	var risk_score: int = int(snapshot.get("risk_score", 0))
	var daily_change: float = float(snapshot.get("daily_change_pct", 0.0))
	var broker_flow: Dictionary = snapshot.get("broker_flow", {})
	var financials: Dictionary = snapshot.get("financials", {})
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))
	var dominant_seller: String = str(broker_flow.get("dominant_seller", "balanced"))
	var earnings_growth_yoy: float = float(financials.get("earnings_growth_yoy", 0.0))
	var net_profit_margin: float = float(financials.get("net_profit_margin", 0.0))
	var roe: float = float(financials.get("roe", 0.0))
	var debt_to_equity: float = float(financials.get("debt_to_equity", 0.0))

	if quality <= 55:
		risks.append("- lower company quality")
	if growth <= 55:
		risks.append("- slower growth profile")
	if risk_score >= 58:
		risks.append("- elevated risk score")
	if daily_change < -0.015:
		risks.append("- price is already under pressure")
	if flow_tag == "distribution":
		risks.append("- broker flow leans defensive")
	if dominant_seller in ["retail", "foreign", "institution", "zombie"] and dominant_seller != "balanced":
		risks.append("- active selling from %s" % dominant_seller)
	if earnings_growth_yoy < 0.0:
		risks.append("- earnings are shrinking despite the story")
	if net_profit_margin < 3.0:
		risks.append("- thin margins leave less room for mistakes")
	if roe < 8.0:
		risks.append("- return on equity still looks weak")
	if debt_to_equity >= 1.0:
		risks.append("- leverage is starting to look heavy")

	if risks.is_empty():
		risks.append("- no major red flags at first glance")

	return "\n".join(risks)


func _build_action_hint(snapshot: Dictionary) -> String:
	var shares_owned: int = int(snapshot.get("shares_owned", 0))
	var lots_owned: int = int(snapshot.get("lots_owned", 0))
	var broker_flow: Dictionary = snapshot.get("broker_flow", {})
	var dominant_buyer: String = str(broker_flow.get("dominant_buyer", "balanced"))
	var dominant_seller: String = str(broker_flow.get("dominant_seller", "balanced"))
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))

	if shares_owned > 0 and flow_tag == "distribution":
		return "You already hold %d lot(s). Decide whether today's selling pressure weakens your original thesis." % lots_owned
	if shares_owned > 0:
		return "You already have exposure. Use the lot selector to scale deliberately, not just because price moved."
	if flow_tag == "accumulation" and dominant_buyer != "balanced":
		return "%s is currently the strongest buyer. Start small and let the fee-aware preview define your first lot." % dominant_buyer.capitalize()
	if dominant_seller != "balanced":
		return "%s is leaning on this tape. Waiting is a valid decision." % dominant_seller.capitalize()
	return "No position yet. Use this panel to size a deliberate first lot."


func _build_broker_hint(snapshot: Dictionary) -> String:
	var broker_flow: Dictionary = snapshot.get("broker_flow", {})
	var dominant_buyer: String = str(broker_flow.get("dominant_buyer", "balanced"))
	var dominant_seller: String = str(broker_flow.get("dominant_seller", "balanced"))
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))

	if flow_tag == "accumulation":
		return "Read: %s is supporting the tape, so ask whether price action agrees or is still lagging." % dominant_buyer.capitalize()
	if flow_tag == "distribution":
		return "Read: %s is the main seller, so ask whether weakness is temporary or the thesis is breaking." % dominant_seller.capitalize()
	return "Read: mixed broker behavior. Treat this as a lower-conviction setup unless the company story is especially strong."


func _build_reflection_prompt(summary: Dictionary) -> String:
	var best_accumulation: Dictionary = summary.get("best_accumulation", {})
	var heaviest_distribution: Dictionary = summary.get("heaviest_distribution", {})

	if not best_accumulation.is_empty():
		return "Tomorrow's prompt: compare your position against %s and ask why that accumulation looked cleaner." % best_accumulation.get("ticker", "")
	if not heaviest_distribution.is_empty():
		return "Tomorrow's prompt: review why %s drew the heaviest distribution and whether that weakness was visible earlier." % heaviest_distribution.get("ticker", "")
	return "Tomorrow's prompt: pick one clue you trusted today and check whether the close confirmed it."


func _build_portfolio_prompt(portfolio: Dictionary) -> String:
	var cash: float = float(portfolio.get("cash", 0.0))
	var market_value: float = float(portfolio.get("market_value", 0.0))
	var equity: float = float(portfolio.get("equity", 1.0))
	var exposure_ratio: float = 0.0
	if equity > 0.0:
		exposure_ratio = market_value / equity

	if market_value <= 0.0:
		return "You are flat. Pick one setup worth learning from rather than spraying small bets."
	if exposure_ratio < 0.35:
		return "You still have plenty of dry powder. You can stay patient if no setup looks clean."
	if exposure_ratio > 0.75:
		return "You are heavily exposed. Protect capital if the next read turns defensive."
	if cash > market_value:
		return "Cash still outweighs exposure. Keep that flexibility unless conviction improves."
	return "Exposure is balanced. Focus on whether your open thesis is strengthening or weakening."


func _build_review_headline(summary: Dictionary) -> String:
	var portfolio_delta: float = float(summary.get("portfolio_delta", 0.0))
	var best_accumulation: Dictionary = summary.get("best_accumulation", {})
	var heaviest_distribution: Dictionary = summary.get("heaviest_distribution", {})

	if portfolio_delta > 0.0 and not best_accumulation.is_empty():
		return "Constructive close with visible support under %s." % best_accumulation.get("ticker", "")
	if portfolio_delta < 0.0 and not heaviest_distribution.is_empty():
		return "Defensive close as distribution dominated %s." % heaviest_distribution.get("ticker", "")
	if portfolio_delta > 0.0:
		return "Green close, but check whether that gain came from a repeatable read."
	if portfolio_delta < 0.0:
		return "Red close. Review whether the warning signs were visible before the move."
	return "Flat close. The next edge comes from reading signal quality, not just activity."


func _watchlist_tooltip(row: Dictionary) -> String:
	var broker_flow: Dictionary = row.get("broker_flow", {})
	return "%s\nSector: %s\nHeld: %d lot(s) / %d share(s)\nBuyer: %s\nSeller: %s\nTape: %s" % [
		row.get("name", row.get("ticker", "")),
		row.get("sector_name", "Unknown"),
		int(row.get("lots_owned", 0)),
		int(row.get("shares_owned", 0)),
		str(broker_flow.get("dominant_buyer", "balanced")).capitalize(),
		str(broker_flow.get("dominant_seller", "balanced")).capitalize(),
		str(broker_flow.get("flow_tag", "neutral")).capitalize()
	]


func _flow_badge(flow_tag: String) -> String:
	if flow_tag == "accumulation":
		return "[ACC]"
	if flow_tag == "distribution":
		return "[DIST]"
	return "[MIX]"


func _color_for_flow(flow_tag: String) -> Color:
	if flow_tag == "accumulation":
		return COLOR_POSITIVE
	if flow_tag == "distribution":
		return COLOR_NEGATIVE
	return COLOR_WARNING


func _color_for_flow_bg(flow_tag: String) -> Color:
	if flow_tag == "accumulation":
		return Color(0.105882, 0.203922, 0.168627, 0.65)
	if flow_tag == "distribution":
		return Color(0.243137, 0.133333, 0.141176, 0.65)
	return Color(0.180392, 0.164706, 0.109804, 0.55)


func _color_for_change(change_pct: float) -> Color:
	if change_pct > 0.0005:
		return COLOR_POSITIVE
	if change_pct < -0.0005:
		return COLOR_NEGATIVE
	return COLOR_WARNING


func _set_label_tone(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)


func _apply_visual_theme() -> void:
	_style_panel(sidebar_panel, COLOR_PANEL_BLUE_ALT)
	_style_panel(top_bar_panel, COLOR_PANEL_BLUE_ALT)
	_style_panel(desk_panel, COLOR_PANEL_BLUE_ALT)
	_style_panel(action_panel, COLOR_PANEL_GREEN)
	_style_panel(detail_panel, COLOR_PANEL_BLUE)
	_style_panel(broker_panel, COLOR_PANEL_BLUE_ALT)
	_style_panel(summary_panel, COLOR_PANEL_GOLD)
	_style_panel(watchlist_panel, COLOR_PANEL_BLUE)
	_style_panel(sector_panel, COLOR_PANEL_BLUE_ALT)
	_style_panel(portfolio_summary_panel, COLOR_PANEL_BLUE_ALT)
	_style_panel(portfolio_panel, COLOR_PANEL_BLUE_ALT)
	_style_panel(trade_history_panel, COLOR_PANEL_BLUE_ALT)
	_style_panel(help_panel, COLOR_PANEL_BLUE_ALT)
	_apply_toast_theme(true)
	_style_button(dashboard_button, Color(0.126, 0.188, 0.251, 1), COLOR_BORDER, COLOR_TEXT)
	_style_button(markets_button, Color(0.126, 0.188, 0.251, 1), COLOR_BORDER, COLOR_TEXT)
	_style_button(portfolio_button, Color(0.126, 0.188, 0.251, 1), COLOR_BORDER, COLOR_TEXT)
	_style_button(help_button, Color(0.126, 0.188, 0.251, 1), COLOR_BORDER, COLOR_TEXT)
	_style_button(back_to_menu_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT)
	_style_button(advance_day_button, Color(0.27451, 0.219608, 0.0980392, 1), Color(0.819608, 0.631373, 0.254902, 1), COLOR_TEXT)
	_style_button(buy_button, Color(0.117647, 0.32549, 0.239216, 1), Color(0.321569, 0.588235, 0.470588, 1), COLOR_TEXT)
	_style_button(sell_button, Color(0.368627, 0.160784, 0.176471, 1), Color(0.709804, 0.34902, 0.372549, 1), COLOR_TEXT)
	_style_item_list()
	_set_label_tone(objective_label, COLOR_MUTED)
	_set_label_tone(sidebar_intro_label, COLOR_MUTED)
	_set_label_tone(sidebar_focus_label, COLOR_ACCENT)
	_set_label_tone(sidebar_hint_label, COLOR_MUTED)
	_set_label_tone(status_label, COLOR_ACCENT)
	_set_label_tone(action_hint_label, COLOR_MUTED)
	_set_label_tone(trade_rule_label, COLOR_WARNING)
	_set_label_tone(order_preview_label, COLOR_TEXT)
	_set_label_tone(watchlist_summary_label, COLOR_MUTED)
	_set_label_tone(market_hint_label, COLOR_MUTED)
	_set_label_tone(sector_summary_label, COLOR_MUTED)
	_set_label_tone(broker_hint_label, COLOR_MUTED)
	_set_label_tone(balance_value_label, COLOR_TEXT)
	_set_label_tone(invested_value_label, COLOR_TEXT)
	_set_label_tone(equity_value_label, COLOR_TEXT)
	_set_label_tone(holdings_empty_label, COLOR_MUTED)
	_set_label_tone(trade_history_empty_label, COLOR_MUTED)
	_set_label_tone(reflection_label, COLOR_MUTED)
	_set_label_tone(financial_label, COLOR_MUTED)
	_set_label_tone(support_label, COLOR_POSITIVE)
	_set_label_tone(risk_label, COLOR_NEGATIVE)
	help_text_label.add_theme_color_override("default_color", COLOR_TEXT)
	help_text_label.add_theme_color_override("font_selected_color", COLOR_TEXT)
	financial_history_label.add_theme_color_override("default_color", COLOR_TEXT)
	financial_history_label.add_theme_color_override("font_selected_color", COLOR_TEXT)
	toast_message_label.add_theme_color_override("font_color", COLOR_TEXT)


func _style_panel(panel: PanelContainer, fill_color: Color) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = COLOR_BORDER
	style.set_border_width_all(1)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", style)


func _apply_toast_theme(is_success: bool) -> void:
	var panel_color: Color = COLOR_PANEL_GREEN if is_success else Color(0.243137, 0.133333, 0.141176, 0.96)
	var button_color: Color = panel_color.darkened(0.08)
	_style_panel(toast_panel, panel_color)
	_style_button(toast_close_button, button_color, COLOR_BORDER, COLOR_TEXT)


func _style_button(button: Button, fill_color: Color, border_color: Color, font_color: Color) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = fill_color
	normal.border_color = border_color
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_right = 8
	normal.corner_radius_bottom_left = 8

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = fill_color.lightened(0.1)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = fill_color.darkened(0.08)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", pressed)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)


func _style_item_list() -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0588235, 0.0823529, 0.109804, 0.98)
	panel_style.border_color = COLOR_BORDER
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8

	var cursor_style: StyleBoxFlat = StyleBoxFlat.new()
	cursor_style.bg_color = Color(0.239216, 0.407843, 0.572549, 0.7)
	cursor_style.border_color = COLOR_ACCENT
	cursor_style.set_border_width_all(1)
	cursor_style.corner_radius_top_left = 6
	cursor_style.corner_radius_top_right = 6
	cursor_style.corner_radius_bottom_right = 6
	cursor_style.corner_radius_bottom_left = 6

	company_list.add_theme_stylebox_override("panel", panel_style)
	company_list.add_theme_stylebox_override("panel_focus", panel_style)
	company_list.add_theme_stylebox_override("cursor", cursor_style)
	company_list.add_theme_stylebox_override("cursor_unfocused", cursor_style)
	company_list.add_theme_color_override("font_color", COLOR_TEXT)
	company_list.add_theme_color_override("font_selected_color", COLOR_TEXT)
	company_list.add_theme_color_override("guide_color", Color(0, 0, 0, 0))
	company_list.add_theme_constant_override("h_separation", 6)
	company_list.add_theme_constant_override("v_separation", 6)


func _format_currency(value: float) -> String:
	return "Rp %s" % String.num(value, 2)


func _format_signed_currency(value: float) -> String:
	return "%sRp %s" % [
		"+" if value >= 0.0 else "-",
		String.num(absf(value), 2)
	]


func _format_change(change_pct: float) -> String:
	return "%+.2f%%" % [change_pct * 100.0]


func _format_rate(rate: float) -> String:
	return "%.2f%%" % [rate * 100.0]


func _format_history(price_history: Array) -> String:
	var trimmed_history: Array = price_history.slice(max(price_history.size() - 6, 0), price_history.size())
	var parts: Array = []
	for price in trimmed_history:
		parts.append(String.num(float(price), 2))
	return " -> ".join(parts)


func _format_financial_block(financials: Dictionary) -> String:
	if financials.is_empty():
		return "No financial snapshot yet."

	var history_years: int = int(financials.get("history_years", 0))
	var history_start_year: int = int(financials.get("history_start_year", 0))
	var history_end_year: int = int(financials.get("history_end_year", 0))
	var history_line: String = ""
	if history_years > 0:
		history_line = "\n%dY history %d-%d  |  Rev CAGR %s  |  Earn CAGR %s" % [
			history_years,
			history_start_year,
			history_end_year,
			_format_signed_percent_value(float(financials.get("revenue_cagr_10y", 0.0))),
			_format_signed_percent_value(float(financials.get("earnings_cagr_10y", 0.0)))
		]

	return "MCap %s  |  Free float %s  |  ADV %s\nRevenue growth %s  |  Earnings growth %s\nNet margin %s  |  ROE %s  |  D/E %s%s" % [
		_format_compact_currency(float(financials.get("market_cap", 0.0))),
		_format_percent_value(float(financials.get("free_float_pct", 0.0))),
		_format_compact_currency(float(financials.get("avg_daily_value", 0.0))),
		_format_signed_percent_value(float(financials.get("revenue_growth_yoy", 0.0))),
		_format_signed_percent_value(float(financials.get("earnings_growth_yoy", 0.0))),
		_format_percent_value(float(financials.get("net_profit_margin", 0.0))),
		_format_percent_value(float(financials.get("roe", 0.0))),
		_format_multiple(float(financials.get("debt_to_equity", 0.0))),
		history_line
	]


func _format_financial_history_block(financial_history: Array, financials: Dictionary) -> String:
	if financial_history.is_empty():
		return "Generated history unavailable for this run."

	var first_year: Dictionary = financial_history[0]
	var last_year: Dictionary = financial_history[financial_history.size() - 1]
	var start_year: int = int(first_year.get("year", financials.get("history_start_year", 0)))
	var end_year: int = int(last_year.get("year", financials.get("history_end_year", start_year)))
	var lines: Array = [
		"GENERATED %d-%d HISTORY" % [start_year, end_year],
		"Rev CAGR %s  |  Earn CAGR %s  |  Implied price %s -> %s" % [
			_format_signed_percent_value(float(financials.get("revenue_cagr_10y", 0.0))),
			_format_signed_percent_value(float(financials.get("earnings_cagr_10y", 0.0))),
			_format_last_price(float(first_year.get("implied_share_price", 0.0))),
			_format_last_price(float(last_year.get("implied_share_price", 0.0)))
		]
	]

	for history_entry_value in financial_history:
		var history_entry: Dictionary = history_entry_value
		lines.append("")
		lines.append("%d | Rev %s | NI %s | Px %s" % [
			int(history_entry.get("year", 0)),
			_format_compact_currency(float(history_entry.get("revenue", 0.0))),
			_format_compact_currency(float(history_entry.get("net_income", 0.0))),
			_format_last_price(float(history_entry.get("implied_share_price", 0.0)))
		])
		lines.append("Margin %s | ROE %s | D/E %s | Earn YoY %s" % [
			_format_percent_value(float(history_entry.get("net_profit_margin", 0.0))),
			_format_percent_value(float(history_entry.get("roe", 0.0))),
			_format_multiple(float(history_entry.get("debt_to_equity", 0.0))),
			_format_signed_percent_value(float(history_entry.get("earnings_growth_yoy", 0.0)))
		])

	return "\n".join(lines)


func _format_compact_currency(value: float) -> String:
	var absolute_value: float = absf(value)
	if absolute_value >= 1000000000000.0:
		return "Rp %sT" % String.num(value / 1000000000000.0, 2)
	if absolute_value >= 1000000000.0:
		return "Rp %sB" % String.num(value / 1000000000.0, 2)
	if absolute_value >= 1000000.0:
		return "Rp %sM" % String.num(value / 1000000.0, 2)
	return _format_currency(value)


func _format_percent_value(value: float) -> String:
	return "%s%%" % String.num(value, 1)


func _format_signed_percent_value(value: float) -> String:
	return "%+.1f%%" % [value]


func _format_multiple(value: float) -> String:
	return "%sx" % String.num(value, 2)


func _format_last_price(value: float) -> String:
	return "Rp %s" % String.num(value, 0)


func _join_or_default(values: Array, default_text: String) -> String:
	if values.is_empty():
		return default_text

	var parts: Array = []
	for value in values:
		parts.append(str(value))
	return ", ".join(parts)
