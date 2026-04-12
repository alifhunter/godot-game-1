extends Control

const SECTION_ORDER := ["dashboard", "markets", "portfolio", "help"]
const APP_ID_DESKTOP := "desktop"
const APP_ID_STOCK := "stock"
const APP_ID_NEWS := "news"
const APP_ID_SOCIAL := "social"
const STOCK_APP_FONT_SIZE := 12
const DEFAULT_APP_FONT_SIZE := 12
const TRADE_LEFT_SECTION_RATIO := 1.0
const TRADE_CENTER_SECTION_RATIO := 2.0
const TRADE_RIGHT_SECTION_RATIO := 1.0
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
const COLOR_DESKTOP_BG := Color(0.909804, 0.909804, 0.803922, 1)
const COLOR_DESKTOP_TEXT := Color(0.184314, 0.172549, 0.109804, 1)
const COLOR_STOCK_WINDOW_BG := Color(0.0901961, 0.129412, 0.164706, 0.98)
const COLOR_ORDER_PANEL_BG := Color(0.0901961, 0.129412, 0.164706, 0.98)
const COLOR_ORDER_CARD_BG := Color(0.109804, 0.14902, 0.184314, 0.98)
const COLOR_ORDER_INPUT_BG := Color(0.0901961, 0.129412, 0.164706, 0.98)
const COLOR_ORDER_BUY := Color(0.117647, 0.32549, 0.239216, 1)
const COLOR_ORDER_BUY_BORDER := Color(0.309804, 0.631373, 0.486275, 1)
const COLOR_ORDER_SELL := Color(0.27451, 0.164706, 0.180392, 1)
const COLOR_ORDER_SELL_BORDER := Color(0.690196, 0.34902, 0.372549, 1)
const COLOR_WINDOW_BG := Color(0.909804, 0.909804, 0.803922, 1)
const COLOR_WINDOW_TEXT := Color(0.184314, 0.172549, 0.109804, 1)
const COLOR_NAV_FILL := Color(0.126, 0.188, 0.251, 1)
const COLOR_NAV_ACTIVE_FILL := Color(0.219608, 0.439216, 0.65098, 1)
const COLOR_NAV_ACTIVE_BORDER := Color(0.690196, 0.87451, 1, 1)
const TOAST_DURATION_SECONDS := 5.0
const SHOW_DASHBOARD_DESK_PANEL := false
const SHOW_DASHBOARD_BALANCE_BLOCK := false
const SHOW_DASHBOARD_BROKER_READ := false
const SHOW_DASHBOARD_REVIEW := false
const STOCK_LIST_TAB_WATCHLIST := 0
const STOCK_LIST_TAB_ALL_STOCKS := 1
const STOCK_LIST_TAB_PORTFOLIO := 2
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
const FINANCIAL_HISTORY_YEAR_WIDTH := 48.0
const FINANCIAL_HISTORY_REVENUE_WIDTH := 84.0
const FINANCIAL_HISTORY_NET_INCOME_WIDTH := 84.0
const FINANCIAL_HISTORY_MARGIN_WIDTH := 62.0
const FINANCIAL_HISTORY_ROE_WIDTH := 52.0
const FINANCIAL_HISTORY_DEBT_WIDTH := 50.0
const FINANCIAL_HISTORY_PRICE_WIDTH := 72.0
const BROKER_CODE_WIDTH := 42.0
const BROKER_VALUE_WIDTH := 76.0
const BROKER_LOT_WIDTH := 62.0
const BROKER_AVERAGE_WIDTH := 70.0
const STATEMENT_LABEL_WIDTH := 286.0
const STATEMENT_VALUE_WIDTH := 148.0
const APP_WINDOW_INSET := 20
const APP_WINDOW_CONTENT_MARGIN := 20
const APP_WINDOW_CONTENT_TOP_MARGIN := 64
const APP_WINDOW_CONTENT_BOTTOM_MARGIN := 20
const APP_WINDOW_FRAME_BOTTOM_MARGIN := 20
const APP_WINDOW_INNER_PADDING := 0
const SOCIAL_WINDOW_MAX_WIDTH := 460.0
const SOCIAL_WINDOW_MAX_HEIGHT := 780.0
const SOCIAL_WINDOW_MIN_HEIGHT := 520.0
const PROTOTYPE_NEWS_INTEL_LEVEL := 4
const PROTOTYPE_TWOOTER_ACCESS_TIER := 4
const DASHBOARD_WEEKDAY_NAMES := ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
const DASHBOARD_MONTH_NAMES := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

var selected_company_id: String = ""
var displayed_company_ids: Array = []
var watchlist_picker_company_ids: Array = []
var tutorial_dialog: AcceptDialog = null
var watchlist_picker_dialog: ConfirmationDialog = null
var watchlist_picker_list: ItemList = null
var selected_lots: int = 1
var active_section_id: String = "dashboard"
var active_app_id: String = APP_ID_DESKTOP
var status_message: String = "Ready."
var selected_financial_statement_index: int = -1
var selected_financial_statement_company_id: String = ""
var current_trade_snapshot: Dictionary = {}
var current_news_snapshot: Dictionary = {}
var current_social_snapshot: Dictionary = {}
var debug_generator_buttons: Dictionary = {}
var active_order_side: String = "buy"
var broker_net_mode: bool = false
var selected_news_outlet_id: String = ""
var selected_news_archive_year: int = 0
var selected_news_archive_month: int = 0
var selected_news_article_id: String = ""
var portfolio_trading_calendar = preload("res://systems/TradingCalendar.gd").new()

@onready var desktop_layer: Control = $DesktopLayer
@onready var desktop_title_label: Label = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopHeaderRow/DesktopTitleLabel
@onready var desktop_date_label: Label = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopHeaderRow/DesktopDateLabel
@onready var desktop_subtitle_label: Label = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopSubtitleLabel
@onready var desktop_hint_label: Label = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopHintLabel
@onready var stock_app_button: Button = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow/StockAppTile/StockAppButton
@onready var stock_app_label: Label = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow/StockAppTile/StockAppLabel
@onready var news_app_button: Button = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow/NewsAppTile/NewsAppButton
@onready var news_app_label: Label = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow/NewsAppTile/NewsAppLabel
@onready var social_app_button: Button = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow/SocialAppTile/SocialAppButton
@onready var social_app_label: Label = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow/SocialAppTile/SocialAppLabel
@onready var exit_app_button: Button = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow/ExitAppTile/ExitAppButton
@onready var exit_app_label: Label = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow/ExitAppTile/ExitAppLabel
@onready var app_window_backdrop: Control = $AppWindowBackdrop
@onready var app_window_margin: MarginContainer = $AppWindowBackdrop/AppWindowMargin
@onready var app_window_panel: PanelContainer = $AppWindowBackdrop/AppWindowMargin/AppWindowPanel
@onready var stock_window_container: PanelContainer = $StockWindowContainer
@onready var app_content_margin: MarginContainer = $Margin
@onready var news_window: MarginContainer = $NewsWindow
@onready var news_window_body: PanelContainer = $NewsWindow/NewsWindowBody
@onready var news_title_label: Label = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsHeaderRow/NewsTitleLabel
@onready var news_intel_status_label: Label = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsHeaderRow/NewsIntelStatusLabel
@onready var news_outlet_buttons: HBoxContainer = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsOutletButtons
@onready var news_feed_panel: PanelContainer = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsContentSplit/NewsFeedPanel
@onready var news_feed_summary_label: Label = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsContentSplit/NewsFeedPanel/NewsFeedMargin/NewsFeedVBox/NewsFeedSummaryLabel
@onready var news_archive_year_label: Label = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsContentSplit/NewsFeedPanel/NewsFeedMargin/NewsFeedVBox/NewsArchiveFiltersRow/NewsArchiveYearLabel
@onready var news_archive_year_option: OptionButton = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsContentSplit/NewsFeedPanel/NewsFeedMargin/NewsFeedVBox/NewsArchiveFiltersRow/NewsArchiveYearOption
@onready var news_archive_month_label: Label = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsContentSplit/NewsFeedPanel/NewsFeedMargin/NewsFeedVBox/NewsArchiveFiltersRow/NewsArchiveMonthLabel
@onready var news_archive_month_option: OptionButton = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsContentSplit/NewsFeedPanel/NewsFeedMargin/NewsFeedVBox/NewsArchiveFiltersRow/NewsArchiveMonthOption
@onready var news_article_list: ItemList = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsContentSplit/NewsFeedPanel/NewsFeedMargin/NewsFeedVBox/NewsArticleList
@onready var news_detail_panel: PanelContainer = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsContentSplit/NewsDetailPanel
@onready var news_detail_outlet_label: Label = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsContentSplit/NewsDetailPanel/NewsDetailMargin/NewsDetailVBox/NewsDetailOutletLabel
@onready var news_detail_headline_label: Label = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsContentSplit/NewsDetailPanel/NewsDetailMargin/NewsDetailVBox/NewsDetailHeadlineLabel
@onready var news_detail_deck_label: Label = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsContentSplit/NewsDetailPanel/NewsDetailMargin/NewsDetailVBox/NewsDetailDeckLabel
@onready var news_detail_meta_label: Label = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsContentSplit/NewsDetailPanel/NewsDetailMargin/NewsDetailVBox/NewsDetailMetaLabel
@onready var news_detail_body: RichTextLabel = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsContentSplit/NewsDetailPanel/NewsDetailMargin/NewsDetailVBox/NewsDetailBody
@onready var news_detail_hint_label: Label = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsContentSplit/NewsDetailPanel/NewsDetailMargin/NewsDetailVBox/NewsDetailHintLabel
@onready var social_window: MarginContainer = $SocialWindow
@onready var social_window_body: PanelContainer = $SocialWindow/SocialWindowBody
@onready var social_title_label: Label = $SocialWindow/SocialWindowBody/SocialWindowMargin/SocialWindowVBox/SocialHeaderRow/SocialTitleLabel
@onready var social_access_status_label: Label = $SocialWindow/SocialWindowBody/SocialWindowMargin/SocialWindowVBox/SocialHeaderRow/SocialAccessStatusLabel
@onready var social_feed_summary_label: Label = $SocialWindow/SocialWindowBody/SocialWindowMargin/SocialWindowVBox/SocialFeedSummaryLabel
@onready var social_feed_scroll: ScrollContainer = $SocialWindow/SocialWindowBody/SocialWindowMargin/SocialWindowVBox/SocialFeedScroll
@onready var social_feed_cards: VBoxContainer = $SocialWindow/SocialWindowBody/SocialWindowMargin/SocialWindowVBox/SocialFeedScroll/SocialFeedCards
@onready var app_window_title_bar: PanelContainer = $AppWindowTitleBar
@onready var app_window_title_label: Label = $AppWindowTitleBar/AppWindowTitleMargin/AppWindowTitleRow/AppWindowTitleLabel
@onready var app_window_minimize_button: Button = $AppWindowTitleBar/AppWindowTitleMargin/AppWindowTitleRow/AppWindowMinimizeButton
@onready var app_window_close_button: Button = $AppWindowTitleBar/AppWindowTitleMargin/AppWindowTitleRow/AppWindowCloseButton
@onready var taskbar_panel: PanelContainer = $TaskbarLayer/TaskbarPanel
@onready var taskbar_home_button: Button = $TaskbarLayer/TaskbarPanel/TaskbarMargin/TaskbarRow/TaskbarHomeButton
@onready var taskbar_stock_button: Button = $TaskbarLayer/TaskbarPanel/TaskbarMargin/TaskbarRow/TaskbarStockButton
@onready var taskbar_news_button: Button = $TaskbarLayer/TaskbarPanel/TaskbarMargin/TaskbarRow/TaskbarNewsButton
@onready var taskbar_status_label: Label = $TaskbarLayer/TaskbarPanel/TaskbarMargin/TaskbarRow/TaskbarStatusLabel
@onready var taskbar_clock_label: Label = $TaskbarLayer/TaskbarPanel/TaskbarMargin/TaskbarRow/TaskbarClockLabel
@onready var top_bar_outer_margin: MarginContainer = $Margin/RootVBox/TopBarOuterMargin
@onready var sidebar_panel: PanelContainer = $Margin/RootVBox/ShellHBox/SidebarOuterMargin/SidebarPanel
@onready var sidebar_outer_margin: MarginContainer = $Margin/RootVBox/ShellHBox/SidebarOuterMargin
@onready var top_bar_panel: PanelContainer = $Margin/RootVBox/TopBarOuterMargin/TopBarPanel
@onready var dashboard_button: Button = $Margin/RootVBox/ShellHBox/SidebarOuterMargin/SidebarPanel/SidebarMargin/SidebarVBox/NavigationButtons/DashboardButton
@onready var markets_button: Button = $Margin/RootVBox/ShellHBox/SidebarOuterMargin/SidebarPanel/SidebarMargin/SidebarVBox/NavigationButtons/MarketsButton
@onready var portfolio_button: Button = $Margin/RootVBox/ShellHBox/SidebarOuterMargin/SidebarPanel/SidebarMargin/SidebarVBox/NavigationButtons/PortfolioButton
@onready var help_button: Button = $Margin/RootVBox/ShellHBox/SidebarOuterMargin/SidebarPanel/SidebarMargin/SidebarVBox/NavigationButtons/HelpButton
@onready var sidebar_intro_label: Label = $Margin/RootVBox/ShellHBox/SidebarOuterMargin/SidebarPanel/SidebarMargin/SidebarVBox/SidebarIntroLabel
@onready var sidebar_focus_label: Label = $Margin/RootVBox/ShellHBox/SidebarOuterMargin/SidebarPanel/SidebarMargin/SidebarVBox/SidebarFocusLabel
@onready var sidebar_hint_label: Label = $Margin/RootVBox/ShellHBox/SidebarOuterMargin/SidebarPanel/SidebarMargin/SidebarVBox/SidebarHintLabel
@onready var content_tabs: TabContainer = $Margin/RootVBox/ShellHBox/MainVBox/ContentTabs
@onready var top_section_label: Label = $Margin/RootVBox/TopBarOuterMargin/TopBarPanel/TopBarMargin/TopBarVBox/TitleRow/TopSectionLabel
@onready var advance_day_button: Button = $Margin/RootVBox/TopBarOuterMargin/TopBarPanel/TopBarMargin/TopBarVBox/TitleRow/AdvanceDayButton
@onready var top_day_label: Label = $Margin/RootVBox/TopBarOuterMargin/TopBarPanel/TopBarMargin/TopBarVBox/StatsFlow/TopDayLabel
@onready var top_market_label: Label = $Margin/RootVBox/TopBarOuterMargin/TopBarPanel/TopBarMargin/TopBarVBox/TitleRow/TopMarketLabel
@onready var top_equity_label: Label = $Margin/RootVBox/TopBarOuterMargin/TopBarPanel/TopBarMargin/TopBarVBox/TitleRow/TopEquityLabel
@onready var top_cash_label: Label = $Margin/RootVBox/TopBarOuterMargin/TopBarPanel/TopBarMargin/TopBarVBox/TitleRow/TopCashLabel
@onready var objective_label: Label = $Margin/RootVBox/TopBarOuterMargin/TopBarPanel/TopBarMargin/TopBarVBox/ObjectiveLabel
@onready var subtitle_label: Label = $Margin/RootVBox/TopBarOuterMargin/TopBarPanel/TopBarMargin/TopBarVBox/TitleRow/TitleWrap/SubtitleLabel

@onready var dashboard_grid: GridContainer = %DashboardView/DashboardGrid
@onready var dashboard_index_panel: PanelContainer = %DashboardView/DashboardGrid/IndexPanel
@onready var dashboard_index_title_label: Label = %DashboardView/DashboardGrid/IndexPanel/IndexMargin/IndexVBox/IndexTitleLabel
@onready var dashboard_index_date_label: Label = %DashboardView/DashboardGrid/IndexPanel/IndexMargin/IndexVBox/IndexDateLabel
@onready var dashboard_index_points_value_label: Label = %DashboardView/DashboardGrid/IndexPanel/IndexMargin/IndexVBox/IndexStatsGrid/IndexPointsValueLabel
@onready var dashboard_index_lots_value_label: Label = %DashboardView/DashboardGrid/IndexPanel/IndexMargin/IndexVBox/IndexStatsGrid/IndexLotsValueLabel
@onready var dashboard_index_value_value_label: Label = %DashboardView/DashboardGrid/IndexPanel/IndexMargin/IndexVBox/IndexStatsGrid/IndexValueValueLabel
@onready var dashboard_index_hint_label: Label = %DashboardView/DashboardGrid/IndexPanel/IndexMargin/IndexVBox/IndexHintLabel
@onready var dashboard_placeholder_top_panel: PanelContainer = %DashboardView/DashboardGrid/PlaceholderTopPanel
@onready var dashboard_placeholder_top_body_label: Label = %DashboardView/DashboardGrid/PlaceholderTopPanel/PlaceholderTopMargin/PlaceholderTopVBox/PlaceholderTopBodyLabel
@onready var dashboard_calendar_panel: PanelContainer = %DashboardView/DashboardGrid/CalendarPanel
@onready var dashboard_calendar_month_label: Label = %DashboardView/DashboardGrid/CalendarPanel/CalendarMargin/CalendarVBox/CalendarMonthLabel
@onready var dashboard_calendar_days_grid: GridContainer = %DashboardView/DashboardGrid/CalendarPanel/CalendarMargin/CalendarVBox/CalendarDaysGrid
@onready var dashboard_placeholder_bottom_panel: PanelContainer = %DashboardView/DashboardGrid/PlaceholderBottomPanel
@onready var dashboard_placeholder_bottom_body_label: Label = %DashboardView/DashboardGrid/PlaceholderBottomPanel/PlaceholderBottomMargin/PlaceholderBottomVBox/PlaceholderBottomBodyLabel

@onready var trade_split: HBoxContainer = %MarketsView/TradeSplit
@onready var main_trade_split: HBoxContainer = %MarketsView/TradeSplit/MainSplit
@onready var watchlist_panel: PanelContainer = %MarketsView/TradeSplit/WatchlistPanel
@onready var work_area_panel: PanelContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel
@onready var action_panel: PanelContainer = %MarketsView/TradeSplit/MainSplit/ActionPanel
@onready var stock_list_tabs: TabContainer = %MarketsView/TradeSplit/WatchlistPanel/WatchlistMargin/WatchlistVBox/StockListTabs
@onready var add_watchlist_button: Button = %MarketsView/TradeSplit/WatchlistPanel/WatchlistMargin/WatchlistVBox/StockListTabs/WatchlistTab/AddWatchlistButton
@onready var watchlist_empty_label: Label = %MarketsView/TradeSplit/WatchlistPanel/WatchlistMargin/WatchlistVBox/StockListTabs/WatchlistTab/WatchlistEmptyLabel
@onready var company_list: ItemList = %MarketsView/TradeSplit/WatchlistPanel/WatchlistMargin/WatchlistVBox/StockListTabs/WatchlistTab/CompanyList
@onready var all_stocks_scroll: ScrollContainer = %MarketsView/TradeSplit/WatchlistPanel/WatchlistMargin/WatchlistVBox/StockListTabs/AllStocksTab/AllStocksScroll
@onready var all_stocks_rows: VBoxContainer = %MarketsView/TradeSplit/WatchlistPanel/WatchlistMargin/WatchlistVBox/StockListTabs/AllStocksTab/AllStocksScroll/AllStocksRows
@onready var portfolio_stocks_scroll: ScrollContainer = %MarketsView/TradeSplit/WatchlistPanel/WatchlistMargin/WatchlistVBox/StockListTabs/PortfolioTab/PortfolioScroll
@onready var portfolio_stocks_rows: VBoxContainer = %MarketsView/TradeSplit/WatchlistPanel/WatchlistMargin/WatchlistVBox/StockListTabs/PortfolioTab/PortfolioScroll/PortfolioRows
@onready var portfolio_stocks_empty_label: Label = %MarketsView/TradeSplit/WatchlistPanel/WatchlistMargin/WatchlistVBox/StockListTabs/PortfolioTab/PortfolioScroll/PortfolioRows/PortfolioEmptyLabel
@onready var trade_workspace_widget = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel
@onready var work_tabs: TabContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs
@onready var key_stats_panel: PanelContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/KeyStats/KeyStatsPanel
@onready var key_stats_financial_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/KeyStats/KeyStatsPanel/KeyStatsMargin/KeyStatsVBox/KeyStatsFinancialLabel
@onready var financial_history_summary_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/KeyStats/KeyStatsPanel/KeyStatsMargin/KeyStatsVBox/FinancialHistorySummaryLabel
@onready var financial_history_header_row: HBoxContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/KeyStats/KeyStatsPanel/KeyStatsMargin/KeyStatsVBox/FinancialHistoryTable/FinancialHistoryHeaderRow
@onready var financial_history_rows_vbox: VBoxContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/KeyStats/KeyStatsPanel/KeyStatsMargin/KeyStatsVBox/FinancialHistoryTable/FinancialHistoryRows
@onready var financial_history_empty_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/KeyStats/KeyStatsPanel/KeyStatsMargin/KeyStatsVBox/FinancialHistoryTable/FinancialHistoryRows/FinancialHistoryEmptyLabel
@onready var financials_panel: PanelContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Financials/FinancialsPanel
@onready var financials_year_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Financials/FinancialsPanel/FinancialsMargin/FinancialsVBox/FinancialsYearLabel
@onready var financials_previous_button: Button = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Financials/FinancialsPanel/FinancialsMargin/FinancialsVBox/FinancialsPeriodRow/FinancialsPreviousButton
@onready var financials_period_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Financials/FinancialsPanel/FinancialsMargin/FinancialsVBox/FinancialsPeriodRow/FinancialsPeriodLabel
@onready var financials_next_button: Button = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Financials/FinancialsPanel/FinancialsMargin/FinancialsVBox/FinancialsPeriodRow/FinancialsNextButton
@onready var income_statement_rows_vbox: VBoxContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Financials/FinancialsPanel/FinancialsMargin/FinancialsVBox/IncomeStatementRows
@onready var income_statement_empty_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Financials/FinancialsPanel/FinancialsMargin/FinancialsVBox/IncomeStatementRows/IncomeStatementEmptyLabel
@onready var balance_sheet_rows_vbox: VBoxContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Financials/FinancialsPanel/FinancialsMargin/FinancialsVBox/BalanceSheetRows
@onready var balance_sheet_empty_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Financials/FinancialsPanel/FinancialsMargin/FinancialsVBox/BalanceSheetRows/BalanceSheetEmptyLabel
@onready var cash_flow_rows_vbox: VBoxContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Financials/FinancialsPanel/FinancialsMargin/FinancialsVBox/CashFlowRows
@onready var cash_flow_empty_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Financials/FinancialsPanel/FinancialsMargin/FinancialsVBox/CashFlowRows/CashFlowEmptyLabel
@onready var broker_panel: PanelContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Broker/BrokerPanel
@onready var broker_summary_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Broker/BrokerPanel/BrokerMargin/BrokerVBox/BrokerSummaryLabel
@onready var broker_meter_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Broker/BrokerPanel/BrokerMargin/BrokerVBox/BrokerMeterLabel
@onready var broker_meter_bar: ProgressBar = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Broker/BrokerPanel/BrokerMargin/BrokerVBox/BrokerMeterBar
@onready var broker_scale_left_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Broker/BrokerPanel/BrokerMargin/BrokerVBox/BrokerScaleRow/BrokerScaleLeftLabel
@onready var broker_scale_mid_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Broker/BrokerPanel/BrokerMargin/BrokerVBox/BrokerScaleRow/BrokerScaleMidLabel
@onready var broker_scale_right_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Broker/BrokerPanel/BrokerMargin/BrokerVBox/BrokerScaleRow/BrokerScaleRightLabel
@onready var broker_net_toggle: CheckButton = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Broker/BrokerPanel/BrokerMargin/BrokerVBox/BrokerControlsRow/BrokerNetToggle
@onready var broker_header_row: HBoxContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Broker/BrokerPanel/BrokerMargin/BrokerVBox/BrokerHeaderRow
@onready var broker_rows_vbox: VBoxContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Broker/BrokerPanel/BrokerMargin/BrokerVBox/BrokerRows
@onready var broker_empty_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Broker/BrokerPanel/BrokerMargin/BrokerVBox/BrokerRows/BrokerEmptyLabel
@onready var analyzer_panel: PanelContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Analyzer/AnalyzerPanel
@onready var analyzer_setup_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Analyzer/AnalyzerPanel/AnalyzerMargin/AnalyzerVBox/AnalyzerSetupLabel
@onready var analyzer_support_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Analyzer/AnalyzerPanel/AnalyzerMargin/AnalyzerVBox/AnalyzerSupportLabel
@onready var analyzer_risk_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Analyzer/AnalyzerPanel/AnalyzerMargin/AnalyzerVBox/AnalyzerRiskLabel
@onready var analyzer_event_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Analyzer/AnalyzerPanel/AnalyzerMargin/AnalyzerVBox/AnalyzerEventLabel
@onready var analyzer_history_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Analyzer/AnalyzerPanel/AnalyzerMargin/AnalyzerVBox/AnalyzerHistoryLabel
@onready var profile_panel: PanelContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel
@onready var profile_company_name_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfileCompanyNameLabel
@onready var profile_sector_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfileSectorLabel
@onready var profile_price_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfilePriceLabel
@onready var profile_factor_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfileFactorLabel
@onready var profile_tags_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfileTagsLabel
@onready var profile_description_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfileDescriptionLabel
@onready var order_company_name_label: Label = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/HeaderVBox/CompanyNameLabel
@onready var selection_label: Label = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/HeaderVBox/SelectionLabel
@onready var order_price_value_label: Label = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/HeaderVBox/QuoteRow/PriceBlock/CurrentPriceLabel
@onready var order_price_change_label: Label = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/HeaderVBox/QuoteRow/PriceBlock/PriceChangeLabel
@onready var order_position_label: Label = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/PositionLabel
@onready var order_card_panel: PanelContainer = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/OrderCard
@onready var order_title_label: Label = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/OrderCard/OrderCardMargin/OrderCardVBox/OrderTitleRow/OrderTitleLabel
@onready var lot_spin_box: SpinBox = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/OrderCard/OrderCardMargin/OrderCardVBox/LotSpinBox
@onready var order_price_line_edit: LineEdit = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/OrderCard/OrderCardMargin/OrderCardVBox/PriceLineEdit
@onready var estimated_total_value_label: Label = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/OrderCard/OrderCardMargin/OrderCardVBox/EstimatedTotalValueLabel
@onready var buy_button: Button = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/TradeButtonRow/BuyButton
@onready var sell_button: Button = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/TradeButtonRow/SellButton
@onready var submit_order_button: Button = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/OrderCard/OrderCardMargin/OrderCardVBox/SubmitOrderButton

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
@onready var debug_overlay: Control = $DebugOverlay
@onready var debug_panel: PanelContainer = $DebugOverlay/DebugCenter/DebugPanel
@onready var debug_close_button: Button = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugHeaderRow/DebugCloseButton
@onready var debug_hint_label: Label = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugHintLabel
@onready var debug_tabs: TabContainer = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs
@onready var upcoming_events_panel: PanelContainer = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Upcoming
@onready var current_events_panel: PanelContainer = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Current
@onready var special_events_panel: PanelContainer = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Special
@onready var person_events_panel: PanelContainer = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Person
@onready var generic_events_panel: PanelContainer = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Generic
@onready var debug_generators_panel: PanelContainer = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Generators
@onready var stock_performance_panel: PanelContainer = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Stocks
@onready var market_history_panel: PanelContainer = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Market
@onready var upcoming_events_label: RichTextLabel = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Upcoming/UpcomingMargin/UpcomingVBox/UpcomingEventsLabel
@onready var current_events_label: RichTextLabel = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Current/CurrentMargin/CurrentVBox/CurrentEventsLabel
@onready var special_events_label: RichTextLabel = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Special/SpecialMargin/SpecialVBox/SpecialEventsLabel
@onready var person_events_label: RichTextLabel = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Person/PeopleMargin/PeopleVBox/PersonEventsLabel
@onready var generic_events_label: RichTextLabel = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Generic/GenericMargin/GenericVBox/GenericEventsLabel
@onready var debug_generators_hint_label: Label = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Generators/GeneratorsMargin/GeneratorsVBox/GeneratorsHintLabel
@onready var debug_generator_groups: VBoxContainer = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Generators/GeneratorsMargin/GeneratorsVBox/GeneratorsScroll/GeneratorGroupsVBox
@onready var stock_performance_label: RichTextLabel = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Stocks/StocksMargin/StocksVBox/StockPerformanceLabel
@onready var market_history_label: RichTextLabel = $DebugOverlay/DebugCenter/DebugPanel/DebugMargin/DebugVBox/DebugTabs/Market/MarketHistoryMargin/MarketHistoryVBox/MarketHistoryLabel
@onready var toast_overlay: MarginContainer = $ToastOverlay
@onready var toast_panel: PanelContainer = $ToastOverlay/ToastPanel
@onready var toast_message_label: Label = $ToastOverlay/ToastPanel/ToastMargin/ToastHBox/ToastMessageLabel
@onready var toast_close_button: Button = $ToastOverlay/ToastPanel/ToastMargin/ToastHBox/ToastCloseButton
@onready var toast_timer: Timer = $ToastTimer


func _ready() -> void:
	_ensure_tutorial_dialog()
	_ensure_watchlist_picker_dialog()
	_apply_visual_theme()
	_apply_compact_layout()
	_apply_trade_layout_ratios()
	_hide_toast()
	stock_list_tabs.set_tab_title(STOCK_LIST_TAB_WATCHLIST, "Watchlist")
	stock_list_tabs.set_tab_title(STOCK_LIST_TAB_ALL_STOCKS, "All Stock")
	stock_list_tabs.set_tab_title(STOCK_LIST_TAB_PORTFOLIO, "Portfolio")
	stock_app_button.pressed.connect(_on_stock_app_pressed)
	news_app_button.pressed.connect(_on_news_app_pressed)
	social_app_button.pressed.connect(_on_social_app_pressed)
	exit_app_button.pressed.connect(_on_exit_app_pressed)
	taskbar_home_button.pressed.connect(_on_taskbar_home_pressed)
	taskbar_stock_button.pressed.connect(_on_taskbar_stock_pressed)
	taskbar_news_button.pressed.connect(_on_taskbar_news_pressed)
	app_window_minimize_button.pressed.connect(_on_app_window_minimize_pressed)
	app_window_close_button.pressed.connect(_on_app_window_close_pressed)
	dashboard_button.pressed.connect(_on_dashboard_pressed)
	markets_button.pressed.connect(_on_markets_pressed)
	portfolio_button.pressed.connect(_on_portfolio_pressed)
	help_button.pressed.connect(_on_help_pressed)
	debug_close_button.pressed.connect(_hide_debug_overlay)
	toast_close_button.pressed.connect(_on_toast_close_pressed)
	toast_timer.timeout.connect(_hide_toast)
	stock_list_tabs.tab_changed.connect(_on_stock_list_tab_changed)
	add_watchlist_button.pressed.connect(_on_add_watchlist_pressed)
	financials_previous_button.pressed.connect(_on_financials_previous_pressed)
	financials_next_button.pressed.connect(_on_financials_next_pressed)
	broker_net_toggle.toggled.connect(_on_broker_net_toggled)
	company_list.item_selected.connect(_on_company_selected)
	news_article_list.item_selected.connect(_on_news_article_selected)
	news_archive_year_option.item_selected.connect(_on_news_archive_year_selected)
	news_archive_month_option.item_selected.connect(_on_news_archive_month_selected)
	lot_spin_box.value_changed.connect(_on_lot_size_changed)
	buy_button.pressed.connect(_on_buy_side_pressed)
	sell_button.pressed.connect(_on_sell_side_pressed)
	submit_order_button.pressed.connect(_on_submit_order_pressed)
	advance_day_button.pressed.connect(_on_next_day_pressed)
	get_viewport().size_changed.connect(_update_responsive_layout)
	GameManager.portfolio_changed.connect(_refresh_all)
	GameManager.watchlist_changed.connect(_refresh_all)
	GameManager.price_formed.connect(_on_day_progressed)
	GameManager.summary_ready.connect(_on_summary_ready)
	stock_app_button.tooltip_text = "Open STOCKBOT."
	news_app_button.tooltip_text = "Open the event-driven news desk."
	social_app_button.tooltip_text = "Open the mobile-style social feed."
	exit_app_button.tooltip_text = "Return to the main menu."
	taskbar_home_button.tooltip_text = "Return to the desktop."
	taskbar_stock_button.tooltip_text = "Open STOCKBOT."
	taskbar_news_button.tooltip_text = "Open the event-driven news desk."
	financials_previous_button.tooltip_text = "View the previous quarter."
	financials_next_button.tooltip_text = "View the next quarter."
	broker_net_toggle.tooltip_text = "Toggle net broker flow so each broker appears on only one side."
	buy_button.tooltip_text = "Switch the ticket to buy mode."
	sell_button.tooltip_text = "Switch the ticket to sell mode."
	submit_order_button.tooltip_text = "Submit the active order."
	_build_debug_generator_controls()
	call_deferred("_update_responsive_layout")
	_set_active_section(active_section_id)
	_set_active_app(APP_ID_DESKTOP)
	_refresh_all()
	call_deferred("_show_tutorial_if_needed")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event
		if key_event.ctrl_pressed and key_event.keycode == KEY_L:
			_toggle_debug_overlay()
			get_viewport().set_input_as_handled()
			return
		if debug_overlay.visible and key_event.keycode == KEY_ESCAPE:
			_hide_debug_overlay()
			get_viewport().set_input_as_handled()


func _apply_compact_layout() -> void:
	sidebar_intro_label.visible = false
	sidebar_focus_label.visible = false
	sidebar_hint_label.visible = false
	subtitle_label.visible = false
	news_intel_status_label.visible = false
	news_feed_summary_label.visible = false
	news_detail_deck_label.visible = false
	news_detail_hint_label.visible = false
	top_day_label.visible = false
	objective_label.visible = false


func _apply_trade_layout_ratios() -> void:
	trade_split.add_theme_constant_override("separation", 0)
	main_trade_split.add_theme_constant_override("separation", 0)
	watchlist_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	watchlist_panel.size_flags_stretch_ratio = TRADE_LEFT_SECTION_RATIO
	main_trade_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_trade_split.size_flags_stretch_ratio = TRADE_CENTER_SECTION_RATIO + TRADE_RIGHT_SECTION_RATIO
	work_area_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	work_area_panel.size_flags_stretch_ratio = TRADE_CENTER_SECTION_RATIO
	action_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_panel.size_flags_stretch_ratio = TRADE_RIGHT_SECTION_RATIO


func _apply_dashboard_perk_visibility() -> void:
	pass


func _update_responsive_layout() -> void:
	var content_width: float = content_tabs.get_rect().size.x
	if content_width <= 0.0:
		content_width = get_viewport_rect().size.x - 320.0
	var viewport_size: Vector2 = get_viewport_rect().size

	portfolio_grid.columns = 2 if content_width >= 1100.0 else 1
	portfolio_summary_grid.columns = 4 if content_width >= 1200.0 else 2
	_apply_trade_layout_ratios()
	watchlist_panel.custom_minimum_size = Vector2.ZERO
	work_area_panel.custom_minimum_size = Vector2.ZERO
	action_panel.custom_minimum_size = Vector2.ZERO
	company_list.custom_minimum_size = Vector2(0, 300 if content_width < 1320.0 else 420)
	all_stocks_scroll.custom_minimum_size = Vector2(0, 300 if content_width < 1320.0 else 420)
	portfolio_stocks_scroll.custom_minimum_size = Vector2(0, 300 if content_width < 1320.0 else 420)
	trade_workspace_widget.set_chart_minimum_height(300 if content_width < 1320.0 else 380)
	social_feed_cards.custom_minimum_size = Vector2(max(min(get_viewport_rect().size.x - 120.0, SOCIAL_WINDOW_MAX_WIDTH - 24.0), 280.0), 0)
	debug_panel.custom_minimum_size = Vector2(
		max(min(viewport_size.x - 48.0, 1080.0), 560.0),
		max(min(viewport_size.y - 48.0, 680.0), 460.0)
	)
	_apply_window_layout()


func _refresh_all() -> void:
	_refresh_desktop()
	if not RunState.has_active_run():
		status_message = "No active run. Return to menu to begin."
		selected_company_id = ""
		_refresh_header()
		_refresh_sidebar()
		_refresh_news()
		_refresh_social()
		_refresh_markets()
		_refresh_debug_overlay()
		_apply_global_font_size_overrides()
		return

	_sync_selected_company_with_active_stock_list()

	_refresh_header()
	_refresh_sidebar()
	_refresh_news()
	_refresh_social()
	_refresh_dashboard()
	_refresh_markets()
	_refresh_portfolio()
	_refresh_help()
	_refresh_debug_overlay()
	_apply_global_font_size_overrides()


func _apply_global_font_size_overrides() -> void:
	_apply_font_size_override_to_tree(self, DEFAULT_APP_FONT_SIZE)


func _apply_font_size_override_to_tree(node: Node, font_size: int) -> void:
	if node is Control:
		var control: Control = node
		control.add_theme_font_size_override("font_size", font_size)
		if control is RichTextLabel:
			var rich_text: RichTextLabel = control
			rich_text.add_theme_font_size_override("normal_font_size", font_size)
			rich_text.add_theme_font_size_override("bold_font_size", font_size)
			rich_text.add_theme_font_size_override("italics_font_size", font_size)
			rich_text.add_theme_font_size_override("mono_font_size", font_size)

	for child: Node in node.get_children():
		_apply_font_size_override_to_tree(child, font_size)


func _refresh_header() -> void:
	var portfolio: Dictionary = GameManager.get_portfolio_snapshot()
	var trading_day_number: int = max(RunState.day_index + 1, 1)
	var current_trade_date: Dictionary = GameManager.get_current_trade_date()
	top_section_label.text = "DAY %d  |  %s" % [trading_day_number, GameManager.format_trade_date(current_trade_date)]
	top_day_label.text = "DAY %d  |  %s" % [trading_day_number, GameManager.format_trade_date(current_trade_date)]
	top_market_label.text = "MARKET %s" % _format_change(RunState.market_sentiment)
	top_equity_label.text = "EQUITY %s" % _format_currency(RunState.get_total_equity())
	top_cash_label.text = "CASH AVAILABLE %s" % _format_currency(float(portfolio.get("cash", 0.0)))
	objective_label.text = ""
	advance_day_button.disabled = not RunState.has_active_run()
	advance_day_button.text = "Advance Day"
	_set_label_tone(top_market_label, _color_for_change(RunState.market_sentiment))
	_set_label_tone(top_cash_label, COLOR_ACCENT)
	_set_label_tone(top_section_label, COLOR_WARNING)
	_set_label_tone(top_day_label, COLOR_WARNING)


func _refresh_desktop() -> void:
	_sync_desktop_app_state()
	if not RunState.has_active_run():
		desktop_title_label.text = "Daytrader OS"
		desktop_date_label.text = "No active run"
		desktop_subtitle_label.text = "Boot a run from the main menu to bring the terminal online."
		desktop_hint_label.text = "Desktop icons launch apps. STOCKBOT trades, News reads the event tape, and Twooter surfaces tiered account chatter."
		taskbar_status_label.text = "No active run loaded."
		taskbar_clock_label.text = "MENU"
		return

	var current_trade_date: Dictionary = GameManager.get_current_trade_date()
	var focus_snapshot: Dictionary = GameManager.get_company_snapshot(selected_company_id)
	desktop_title_label.text = "Daytrader OS"
	desktop_date_label.text = "DAY %d  |  %s" % [
		max(RunState.day_index + 1, 1),
		GameManager.format_trade_date(current_trade_date)
	]
	desktop_subtitle_label.text = "%s session online  |  Equity %s" % [
		GameManager.get_current_difficulty_label(),
		_format_currency(RunState.get_total_equity())
	]
	desktop_hint_label.text = "STOCKBOT is live. News renders event-driven intel feeds, and Twooter now shows tiered social chatter from unlocked accounts."
	taskbar_status_label.text = _build_taskbar_status_text(focus_snapshot)
	taskbar_clock_label.text = "DAY %d  |  %s" % [
		max(RunState.day_index + 1, 1),
		GameManager.format_trade_date(current_trade_date)
	]


func _refresh_news() -> void:
	current_news_snapshot = {}
	news_title_label.text = "News"
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
		_show_news_article({})
		return

	current_news_snapshot = GameManager.get_news_snapshot(PROTOTYPE_NEWS_INTEL_LEVEL)
	var outlets: Array = current_news_snapshot.get("outlets", [])
	if selected_news_outlet_id.is_empty() or not _news_outlet_exists(outlets, selected_news_outlet_id):
		selected_news_outlet_id = _default_news_outlet_id(outlets)
		selected_news_archive_year = 0
		selected_news_archive_month = 0
		selected_news_article_id = ""

	news_intel_status_label.text = ""
	_rebuild_news_outlet_buttons(outlets)
	_refresh_news_archive_filters()
	_refresh_news_article_list()


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
		button.pressed.connect(_on_news_outlet_pressed.bind(outlet_id))
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
	news_article_list.clear()
	var articles: Array = _current_news_archive_article_summaries()
	news_feed_summary_label.text = ""

	for article_value in articles:
		var article: Dictionary = article_value
		var line: String = _build_news_article_list_line(article)
		news_article_list.add_item(line)
		var item_index: int = news_article_list.item_count - 1
		news_article_list.set_item_tooltip(item_index, "")

	var selected_index: int = -1
	for article_index in range(articles.size()):
		if str(articles[article_index].get("id", "")) == selected_news_article_id:
			selected_index = article_index
			break

	if selected_index == -1 and not articles.is_empty():
		selected_index = 0
		selected_news_article_id = str(articles[0].get("id", ""))

	if selected_index >= 0:
		news_article_list.select(selected_index)
		_show_news_article(GameManager.get_news_archive_article(selected_news_article_id))
	else:
		selected_news_article_id = ""
		_show_news_article({})


func _refresh_social() -> void:
	current_social_snapshot = {}
	social_title_label.text = "Twooter"
	if not RunState.has_active_run():
		social_access_status_label.text = "No run loaded"
		social_feed_summary_label.text = "Start a run to populate the mobile-style social feed."
		_rebuild_social_feed_cards([])
		return

	current_social_snapshot = GameManager.get_twooter_snapshot(PROTOTYPE_TWOOTER_ACCESS_TIER)
	var posts: Array = current_social_snapshot.get("posts", [])
	social_access_status_label.text = "Prototype %s access active" % str(current_social_snapshot.get("tier_label", "Tier 4"))
	social_feed_summary_label.text = "%d post(s)  |  Mobile feed view\nHigher access tiers unlock more credible or more market-moving accounts." % posts.size()
	_rebuild_social_feed_cards(posts)


func _rebuild_social_feed_cards(posts: Array) -> void:
	for child in social_feed_cards.get_children():
		social_feed_cards.remove_child(child)
		child.queue_free()

	if posts.is_empty():
		social_feed_cards.add_child(_build_social_empty_card())
		return

	for post_value in posts:
		var post: Dictionary = post_value
		social_feed_cards.add_child(_build_social_post_card(post))

	if social_feed_scroll.get_v_scroll_bar() != null:
		social_feed_scroll.get_v_scroll_bar().value = 0.0


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
	body.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	body.add_theme_color_override("font_color", Color(0.25098, 0.309804, 0.388235, 1))
	margin.add_child(body)
	return card


func _build_social_post_card(post: Dictionary) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 128)
	_style_social_post_card(card, str(post.get("tone", "mixed")))

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_theme_constant_override("separation", 8)
	content.add_child(header_row)

	var account_label: Label = Label.new()
	account_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	account_label.text = "%s%s" % [
		str(post.get("account_name", "")),
		" [verified]" if bool(post.get("account_verified", false)) else ""
	]
	account_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	account_label.add_theme_color_override("font_color", Color(0.0862745, 0.129412, 0.196078, 1))
	header_row.add_child(account_label)

	var meta_badge_label: Label = Label.new()
	meta_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta_badge_label.text = "Tier %d" % int(post.get("account_tier", 1))
	meta_badge_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	meta_badge_label.add_theme_color_override("font_color", Color(0.254902, 0.4, 0.639216, 1))
	header_row.add_child(meta_badge_label)

	var handle_label: Label = Label.new()
	handle_label.text = str(post.get("account_handle", ""))
	handle_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	handle_label.add_theme_color_override("font_color", Color(0.360784, 0.454902, 0.603922, 1))
	content.add_child(handle_label)

	var body_label: Label = Label.new()
	body_label.text = str(post.get("post_text", ""))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	body_label.add_theme_color_override("font_color", Color(0.0627451, 0.0862745, 0.117647, 1))
	content.add_child(body_label)

	var meta_line: String = _build_social_card_meta_line(post)
	if not meta_line.is_empty():
		var meta_label: Label = Label.new()
		meta_label.text = meta_line
		meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		meta_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
		meta_label.add_theme_color_override("font_color", Color(0.254902, 0.34902, 0.454902, 1))
		content.add_child(meta_label)

	var context_hint: String = str(post.get("context_hint", ""))
	if not context_hint.is_empty():
		var context_label: Label = Label.new()
		context_label.text = context_hint
		context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		context_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
		context_label.add_theme_color_override("font_color", Color(0.345098, 0.384314, 0.458824, 1))
		content.add_child(context_label)

	var reactions_label: Label = Label.new()
	reactions_label.text = "%d likes  |  %d replies  |  %d retwoots" % [
		int(post.get("likes", 0)),
		int(post.get("replies", 0)),
		int(post.get("retwoots", 0))
	]
	reactions_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	reactions_label.add_theme_color_override("font_color", Color(0.317647, 0.403922, 0.537255, 1))
	content.add_child(reactions_label)

	return card


func _build_social_card_meta_line(post: Dictionary) -> String:
	var meta_parts: Array = []
	var trade_date: Dictionary = post.get("trade_date", {})
	if not trade_date.is_empty():
		meta_parts.append(GameManager.format_trade_date(trade_date))
	if not str(post.get("visibility_label", "")).is_empty():
		meta_parts.append(str(post.get("visibility_label", "")))
	if not str(post.get("target_ticker", "")).is_empty():
		meta_parts.append(str(post.get("target_ticker", "")))
	elif not str(post.get("person_name", "")).is_empty():
		meta_parts.append(str(post.get("person_name", "")))
	elif not str(post.get("sector_name", "")).is_empty():
		meta_parts.append(str(post.get("sector_name", "")))
	if not str(post.get("category", "")).is_empty():
		meta_parts.append(_titleize_snake_case(str(post.get("category", ""))))
	return "  |  ".join(meta_parts)


func _style_social_post_card(panel: PanelContainer, tone: String) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.964706, 0.972549, 0.992157, 1)
	style.border_color = _social_card_border_color(tone)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	panel.add_theme_stylebox_override("panel", style)


func _social_card_border_color(tone: String) -> Color:
	if tone == "positive":
		return Color(0.333333, 0.607843, 0.470588, 1)
	if tone == "negative":
		return Color(0.709804, 0.403922, 0.423529, 1)
	return Color(0.556863, 0.647059, 0.776471, 1)


func _show_news_article(article: Dictionary) -> void:
	if article.is_empty():
		news_detail_outlet_label.text = ""
		news_detail_headline_label.text = "No article selected."
		news_detail_deck_label.text = ""
		news_detail_meta_label.text = ""
		news_detail_body.text = "Choose a story from the list."
		news_detail_hint_label.text = ""
		return

	var trade_date: Dictionary = article.get("trade_date", {})
	var trade_date_text: String = ""
	if not trade_date.is_empty():
		trade_date_text = GameManager.format_trade_date(trade_date)

	news_detail_outlet_label.text = str(article.get("outlet_label", "News"))
	news_detail_headline_label.text = str(article.get("headline", ""))
	news_detail_deck_label.text = ""
	news_detail_meta_label.text = trade_date_text
	news_detail_body.text = str(article.get("body", ""))
	news_detail_hint_label.text = ""


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


func _refresh_sidebar() -> void:
	sidebar_hint_label.text = ""
	dashboard_button.set_pressed_no_signal(active_section_id == "dashboard")
	markets_button.set_pressed_no_signal(active_section_id == "markets")
	portfolio_button.set_pressed_no_signal(active_section_id == "portfolio")
	help_button.set_pressed_no_signal(active_section_id == "help")


func _refresh_dashboard() -> void:
	if not RunState.has_active_run():
		dashboard_index_date_label.text = "No active run."
		dashboard_index_points_value_label.text = "-"
		dashboard_index_lots_value_label.text = "-"
		dashboard_index_value_value_label.text = "-"
		dashboard_index_hint_label.text = "Use New Game or Load Run to begin."
		dashboard_calendar_month_label.text = "-"
		_refresh_dashboard_calendar({})
		dashboard_placeholder_top_body_label.text = "Empty for now."
		dashboard_placeholder_bottom_body_label.text = "Empty for now."
		return

	var index_snapshot: Dictionary = _build_dashboard_index_snapshot()
	var trade_date: Dictionary = GameManager.get_current_trade_date()
	var trading_day_number: int = max(RunState.day_index + 1, 1)
	dashboard_index_date_label.text = "Day %d  |  %s" % [
		trading_day_number,
		GameManager.format_trade_date(trade_date)
	]
	dashboard_index_points_value_label.text = _format_grouped_integer(int(round(float(index_snapshot.get("points", 0.0)))))
	dashboard_index_lots_value_label.text = _format_compact_lots(float(index_snapshot.get("traded_lots", 0.0)))
	dashboard_index_value_value_label.text = _format_compact_currency(float(index_snapshot.get("traded_value", 0.0)))
	dashboard_index_hint_label.text = "Breadth %d green | %d red | %d flat | Market tone %s" % [
		int(index_snapshot.get("advancers", 0)),
		int(index_snapshot.get("decliners", 0)),
		int(index_snapshot.get("flat_count", 0)),
		_format_change(RunState.market_sentiment)
	]
	dashboard_calendar_month_label.text = "%s %d" % [
		DASHBOARD_MONTH_NAMES[clamp(int(trade_date.get("month", 1)) - 1, 0, DASHBOARD_MONTH_NAMES.size() - 1)],
		int(trade_date.get("year", 2020))
	]
	_refresh_dashboard_calendar(trade_date)
	dashboard_placeholder_top_body_label.text = "Empty for now."
	dashboard_placeholder_bottom_body_label.text = "Empty for now."
	_set_label_tone(dashboard_index_points_value_label, _color_for_change(float(index_snapshot.get("day_change_pct", 0.0))))


func _build_dashboard_index_snapshot() -> Dictionary:
	var weighted_ratio_sum: float = 0.0
	var weight_total: float = 0.0
	var traded_lots: float = 0.0
	var traded_value: float = 0.0
	var advancers: int = 0
	var decliners: int = 0
	var flat_count: int = 0
	var weighted_day_change_sum: float = 0.0

	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = RunState.get_company(company_id)
		if runtime.is_empty():
			continue

		var current_price: float = float(runtime.get("current_price", 0.0))
		var starting_price: float = max(float(runtime.get("starting_price", current_price)), 1.0)
		var company_profile: Dictionary = runtime.get("company_profile", {})
		var financials: Dictionary = company_profile.get("financials", {})
		var weight: float = max(float(financials.get("market_cap", current_price * 1000000000.0)), current_price * 1000000.0)
		weighted_ratio_sum += (current_price / starting_price) * weight
		weight_total += weight

		var daily_change_pct: float = float(runtime.get("daily_change_pct", 0.0))
		weighted_day_change_sum += daily_change_pct * weight
		if daily_change_pct > 0.0:
			advancers += 1
		elif daily_change_pct < 0.0:
			decliners += 1
		else:
			flat_count += 1

		var price_bars: Array = runtime.get("price_bars", [])
		if not price_bars.is_empty():
			var latest_bar: Dictionary = price_bars[price_bars.size() - 1]
			traded_lots += float(latest_bar.get("volume_lots", 0.0))
			traded_value += float(latest_bar.get("value", 0.0))

	var points: float = 1000.0
	var day_change_pct: float = 0.0
	if weight_total > 0.0:
		points = 1000.0 * (weighted_ratio_sum / weight_total)
		day_change_pct = weighted_day_change_sum / weight_total

	return {
		"points": points,
		"traded_lots": traded_lots,
		"traded_value": traded_value,
		"advancers": advancers,
		"decliners": decliners,
		"flat_count": flat_count,
		"day_change_pct": day_change_pct
	}


func _refresh_dashboard_calendar(current_date: Dictionary) -> void:
	if dashboard_calendar_days_grid == null:
		return

	_clear_container_children(dashboard_calendar_days_grid)
	if current_date.is_empty():
		return

	var year_value: int = int(current_date.get("year", 2020))
	var month_value: int = int(current_date.get("month", 1))
	var current_day: int = int(current_date.get("day", 1))
	var first_weekday: int = _weekday_for_date(year_value, month_value, 1)
	var days_in_month: int = _days_in_month(year_value, month_value)

	for _index in range(first_weekday):
		dashboard_calendar_days_grid.add_child(_build_dashboard_calendar_spacer())

	for day_value in range(1, days_in_month + 1):
		var weekday_value: int = _weekday_for_date(year_value, month_value, day_value)
		var day_info: Dictionary = {
			"year": year_value,
			"month": month_value,
			"day": day_value,
			"weekday": weekday_value
		}
		var is_current_day: bool = day_value == current_day
		var is_trade_day: bool = weekday_value < 5 and not portfolio_trading_calendar.is_holiday(day_info)
		dashboard_calendar_days_grid.add_child(_build_dashboard_calendar_day_cell(day_value, is_current_day, is_trade_day))

	while dashboard_calendar_days_grid.get_child_count() % 7 != 0:
		dashboard_calendar_days_grid.add_child(_build_dashboard_calendar_spacer())


func _build_dashboard_calendar_spacer() -> Control:
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 28)
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer


func _build_dashboard_calendar_day_cell(day_value: int, is_current_day: bool, is_trade_day: bool) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 28)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = str(day_value)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)

	var fill_color: Color = Color(0.0784314, 0.109804, 0.141176, 0.85)
	var border_color: Color = Color(0.211765, 0.270588, 0.329412, 0.7)
	var text_color: Color = COLOR_TEXT
	if not is_trade_day:
		fill_color = Color(0.054902, 0.0705882, 0.0901961, 0.72)
		border_color = Color(0.141176, 0.176471, 0.215686, 0.6)
		text_color = COLOR_MUTED
	if is_current_day:
		fill_color = Color(0.219608, 0.439216, 0.65098, 0.92)
		border_color = COLOR_NAV_ACTIVE_BORDER
		text_color = Color(1, 1, 1, 1)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	panel.add_theme_stylebox_override("panel", style)
	_set_label_tone(label, text_color)
	return panel


func _clear_container_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _weekday_for_date(year_value: int, month_value: int, day_value: int) -> int:
	var month_offsets: Array = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
	var adjusted_year: int = year_value
	if month_value < 3:
		adjusted_year -= 1
	var sunday_based: int = int(posmod(
		adjusted_year +
		int(adjusted_year / 4) -
		int(adjusted_year / 100) +
		int(adjusted_year / 400) +
		int(month_offsets[month_value - 1]) +
		day_value,
		7
	))
	return int(posmod(sunday_based + 6, 7))


func _days_in_month(year_value: int, month_value: int) -> int:
	if month_value in [1, 3, 5, 7, 8, 10, 12]:
		return 31
	if month_value == 2:
		return 29 if _is_leap_year(year_value) else 28
	return 30


func _is_leap_year(year_value: int) -> bool:
	if year_value % 400 == 0:
		return true
	if year_value % 100 == 0:
		return false
	return year_value % 4 == 0


func _refresh_markets() -> void:
	_refresh_company_list()
	_refresh_trade_workspace()


func _refresh_after_company_selection() -> void:
	_refresh_company_selection_state()
	_refresh_trade_workspace()
	_refresh_dashboard()
	_refresh_desktop()
	if debug_overlay.visible:
		_refresh_debug_overlay()


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


func _refresh_debug_overlay() -> void:
	_update_debug_generator_buttons_enabled(RunState.has_active_run())
	if not RunState.has_active_run():
		upcoming_events_label.text = "No active run."
		current_events_label.text = "No active run."
		special_events_label.text = "No active run."
		person_events_label.text = "No active run."
		generic_events_label.text = "No active run."
		stock_performance_label.text = "No active run."
		market_history_label.text = "No active run."
		return

	upcoming_events_label.text = _build_debug_upcoming_events_text()
	current_events_label.text = _build_debug_current_events_text()
	special_events_label.text = _build_debug_special_events_text()
	person_events_label.text = _build_debug_person_events_text()
	generic_events_label.text = _build_debug_generic_events_text()
	stock_performance_label.text = _build_debug_stock_performance_text()
	market_history_label.text = _build_debug_market_history_text()


func _toggle_debug_overlay() -> void:
	if debug_overlay.visible:
		_hide_debug_overlay()
		return
	_show_debug_overlay()


func _show_debug_overlay() -> void:
	_refresh_debug_overlay()
	debug_overlay.visible = true


func _hide_debug_overlay() -> void:
	debug_overlay.visible = false


func _build_debug_generator_controls() -> void:
	debug_generator_buttons.clear()
	for child in debug_generator_groups.get_children():
		child.queue_free()

	for group_value in GameManager.get_debug_event_generator_catalog():
		var group: Dictionary = group_value
		var event_entries: Array = group.get("events", [])
		if event_entries.is_empty():
			continue

		var group_label: Label = Label.new()
		group_label.text = str(group.get("label", ""))
		group_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		group_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
		_set_label_tone(group_label, COLOR_TEXT)
		debug_generator_groups.add_child(group_label)

		var flow: HFlowContainer = HFlowContainer.new()
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		debug_generator_groups.add_child(flow)

		for event_entry_value in event_entries:
			var event_entry: Dictionary = event_entry_value
			var event_id: String = str(event_entry.get("event_id", ""))
			if event_id.is_empty():
				continue

			var generator_button: Button = Button.new()
			generator_button.custom_minimum_size = Vector2(170, 34)
			generator_button.text = _format_debug_event_title(event_id)
			generator_button.tooltip_text = str(event_entry.get("description", ""))
			generator_button.pressed.connect(_on_debug_generate_event_pressed.bind(event_id))
			_style_button(generator_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
			flow.add_child(generator_button)
			debug_generator_buttons[event_id] = generator_button

	_update_debug_generator_buttons_enabled(RunState.has_active_run())


func _update_debug_generator_buttons_enabled(is_enabled: bool) -> void:
	for button_value in debug_generator_buttons.values():
		var generator_button: Button = button_value as Button
		if generator_button == null:
			continue
		generator_button.disabled = not is_enabled


func _on_debug_generate_event_pressed(event_id: String) -> void:
	var result: Dictionary = GameManager.debug_generate_event(event_id)
	_show_toast(
		str(result.get("message", "Debug event updated.")),
		bool(result.get("success", false))
	)
	if bool(result.get("success", false)):
		_refresh_all()


func _sync_selected_company_with_active_stock_list() -> void:
	var watchlist_ids: Array = GameManager.get_watchlist_company_ids()
	var holdings_ids: Array = _get_portfolio_company_ids()
	if selected_company_id.is_empty():
		if stock_list_tabs.current_tab == STOCK_LIST_TAB_WATCHLIST:
			selected_company_id = str(watchlist_ids[0]) if not watchlist_ids.is_empty() else ""
		elif stock_list_tabs.current_tab == STOCK_LIST_TAB_PORTFOLIO:
			selected_company_id = str(holdings_ids[0]) if not holdings_ids.is_empty() else ""
		elif not RunState.company_order.is_empty():
			selected_company_id = str(RunState.company_order[0])
		return

	if RunState.get_company(selected_company_id).is_empty():
		selected_company_id = ""
		_sync_selected_company_with_active_stock_list()
		return

	if stock_list_tabs.current_tab == STOCK_LIST_TAB_WATCHLIST and not watchlist_ids.has(selected_company_id):
		selected_company_id = str(watchlist_ids[0]) if not watchlist_ids.is_empty() else ""
	elif stock_list_tabs.current_tab == STOCK_LIST_TAB_PORTFOLIO and not holdings_ids.has(selected_company_id):
		selected_company_id = str(holdings_ids[0]) if not holdings_ids.is_empty() else ""


func _refresh_company_list() -> void:
	displayed_company_ids.clear()
	company_list.clear()
	var company_rows: Array = GameManager.get_company_rows()
	var company_row_lookup: Dictionary = {}
	for row_value in company_rows:
		var company_row: Dictionary = row_value
		company_row_lookup[str(company_row.get("id", ""))] = company_row
	var watchlist_company_ids: Array = GameManager.get_watchlist_company_ids()
	var watchlist_lookup: Dictionary = {}
	for company_id_value in watchlist_company_ids:
		watchlist_lookup[str(company_id_value)] = true

	for row_value in company_rows:
		var row: Dictionary = row_value
		var company_id: String = str(row.get("id", ""))
		if not watchlist_lookup.has(company_id):
			continue
		displayed_company_ids.append(company_id)
		var change_pct: float = float(row.get("daily_change_pct", 0.0))
		var broker_flow: Dictionary = row.get("broker_flow", {})
		var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))
		var line: String = _build_stock_list_line(row)
		company_list.add_item(line)
		var item_index: int = company_list.item_count - 1
		company_list.set_item_tooltip(item_index, _watchlist_tooltip(row))
		company_list.set_item_custom_fg_color(item_index, _color_for_change(change_pct))
		company_list.set_item_custom_bg_color(item_index, _color_for_flow_bg(flow_tag))

	var selected_index: int = displayed_company_ids.find(selected_company_id)
	if stock_list_tabs.current_tab == STOCK_LIST_TAB_WATCHLIST and selected_index == -1 and not displayed_company_ids.is_empty():
		selected_company_id = str(displayed_company_ids[0])
		selected_index = 0

	if selected_index >= 0:
		company_list.select(selected_index)
	watchlist_empty_label.visible = displayed_company_ids.is_empty()
	_refresh_all_stock_rows(company_rows, watchlist_lookup)
	_refresh_portfolio_stock_rows(GameManager.get_portfolio_snapshot().get("holdings", []), company_row_lookup)


func _refresh_all_stock_rows(company_rows: Array, watchlist_lookup: Dictionary) -> void:
	for child in all_stocks_rows.get_children():
		all_stocks_rows.remove_child(child)
		child.queue_free()

	for row_value in company_rows:
		var row: Dictionary = row_value
		var company_id: String = str(row.get("id", ""))
		var line: String = _build_stock_list_line(row)
		var is_selected: bool = company_id == selected_company_id
		var is_in_watchlist: bool = watchlist_lookup.has(company_id)

		var row_box: HBoxContainer = HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 0)
		row_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_box.name = "AllStockRow_%s" % company_id

		var select_button: Button = Button.new()
		select_button.name = "AllStockSelectButton_%s" % company_id
		select_button.text = line
		select_button.tooltip_text = _watchlist_tooltip(row)
		select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select_button.custom_minimum_size = Vector2(0, 40)
		_style_stock_list_row_button(select_button, is_selected)
		select_button.pressed.connect(_on_all_stock_selected.bind(company_id))
		row_box.add_child(select_button)

		var add_button: Button = Button.new()
		add_button.name = "AllStockAddButton_%s" % company_id
		add_button.custom_minimum_size = Vector2(84, 36)
		add_button.text = "Added" if is_in_watchlist else "Add"
		add_button.disabled = is_in_watchlist
		_style_button(
			add_button,
			Color(0.164706, 0.215686, 0.278431, 1) if is_in_watchlist else Color(0.117647, 0.32549, 0.239216, 1),
			COLOR_BORDER,
			COLOR_TEXT,
			0
		)
		if not is_in_watchlist:
			add_button.pressed.connect(_on_add_to_watchlist_pressed.bind(company_id))
		row_box.add_child(add_button)

		all_stocks_rows.add_child(row_box)


func _refresh_portfolio_stock_rows(holdings: Array, company_row_lookup: Dictionary) -> void:
	for child in portfolio_stocks_rows.get_children():
		if child == portfolio_stocks_empty_label:
			continue
		portfolio_stocks_rows.remove_child(child)
		child.queue_free()

	var has_holdings: bool = false
	for holding_value in holdings:
		var holding: Dictionary = holding_value
		var company_id: String = str(holding.get("company_id", ""))
		if company_id.is_empty():
			continue
		var row: Dictionary = company_row_lookup.get(company_id, {})
		if row.is_empty():
			continue

		has_holdings = true
		var lots_owned: int = int(holding.get("lots", 0))
		var line: String = "%s  |  %d lot(s)" % [_build_stock_list_line(row), lots_owned]
		var select_button: Button = Button.new()
		select_button.name = "PortfolioSelectButton_%s" % company_id
		select_button.text = line
		select_button.tooltip_text = _watchlist_tooltip(row)
		select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select_button.custom_minimum_size = Vector2(0, 40)
		_style_stock_list_row_button(select_button, company_id == selected_company_id)
		select_button.pressed.connect(_on_portfolio_stock_selected.bind(company_id))
		portfolio_stocks_rows.add_child(select_button)

	portfolio_stocks_empty_label.visible = not has_holdings


func _refresh_company_selection_state() -> void:
	var selected_index: int = displayed_company_ids.find(selected_company_id)
	if selected_index >= 0:
		company_list.select(selected_index)
	else:
		company_list.deselect_all()

	for row_box_value in all_stocks_rows.get_children():
		if row_box_value is not HBoxContainer:
			continue
		var row_box: HBoxContainer = row_box_value
		var company_id: String = str(row_box.name).trim_prefix("AllStockRow_")
		var select_button: Button = row_box.get_node_or_null("AllStockSelectButton_%s" % company_id) as Button
		if select_button == null:
			continue
		_style_stock_list_row_button(select_button, company_id == selected_company_id)

	for child in portfolio_stocks_rows.get_children():
		if child == portfolio_stocks_empty_label or child is not Button:
			continue
		var portfolio_button: Button = child
		var company_id: String = str(portfolio_button.name).trim_prefix("PortfolioSelectButton_")
		_style_stock_list_row_button(portfolio_button, company_id == selected_company_id)


func _build_stock_list_line(row: Dictionary) -> String:
	return "%s  %s  %s" % [
		row.get("ticker", ""),
		_format_currency(float(row.get("current_price", 0.0))),
		_format_change(float(row.get("daily_change_pct", 0.0)))
	]


func _get_portfolio_company_ids() -> Array:
	var company_ids: Array = []
	var holdings: Array = GameManager.get_portfolio_snapshot().get("holdings", [])
	for holding_value in holdings:
		var holding: Dictionary = holding_value
		var company_id: String = str(holding.get("company_id", ""))
		if company_id.is_empty():
			continue
		company_ids.append(company_id)
	return company_ids


func _refresh_trade_workspace() -> void:
	var snapshot: Dictionary = GameManager.get_company_snapshot(selected_company_id, true, true, true)
	current_trade_snapshot = snapshot
	trade_workspace_widget.set_company_snapshot(snapshot)
	if snapshot.is_empty():
		current_trade_snapshot = {}
		selected_financial_statement_company_id = ""
		selected_financial_statement_index = -1
		active_order_side = "buy"
		order_company_name_label.text = "NO SELECTION"
		selection_label.text = "-"
		order_price_value_label.text = "Rp 0.00"
		order_price_change_label.text = "+Rp 0.00  |  +0.00%"
		order_position_label.text = "Pick a stock first so the order ticket can price the trade."
		order_title_label.text = "Buy Order"
		order_price_line_edit.text = ""
		estimated_total_value_label.text = "Rp 0.00"
		buy_button.disabled = true
		sell_button.disabled = true
		submit_order_button.disabled = true
		submit_order_button.text = "Submit Buy Order"
		_set_label_tone(order_price_change_label, COLOR_MUTED)
		_set_label_tone(estimated_total_value_label, COLOR_MUTED)
		_update_order_side_buttons()
		profile_company_name_label.text = "No selection"
		profile_sector_label.text = "Sector:"
		profile_price_label.text = "Price:"
		profile_factor_label.text = "Company profile:"
		profile_tags_label.text = "Tags:"
		profile_description_label.text = "Description:"
		key_stats_financial_label.text = "Financials:"
		financials_year_label.text = "Derived financial statements unavailable."
		financials_period_label.text = "Viewing latest available period."
		broker_summary_label.text = "Broker tape unavailable."
		broker_meter_label.text = "Broker Action: Neutral"
		broker_meter_bar.value = 50.0
		analyzer_setup_label.text = "Setup read:"
		analyzer_support_label.text = "Supportive signals:"
		analyzer_risk_label.text = "Risk signals:"
		analyzer_event_label.text = "Visible inputs:"
		analyzer_history_label.text = "Recent closes:"
		financial_history_summary_label.text = "Generated history unavailable."
		_refresh_financial_history_table([], {})
		_refresh_broker_table({})
		_refresh_statement_sections({})
		_set_label_tone(profile_price_label, COLOR_TEXT)
		return

	var financial_statement_snapshot: Dictionary = snapshot.get("financial_statement_snapshot", {})
	_sync_financial_statement_selection(str(snapshot.get("id", "")), financial_statement_snapshot)
	lot_spin_box.set_value_no_signal(float(_selected_lots()))
	profile_company_name_label.text = "%s  |  %s" % [snapshot.get("ticker", ""), snapshot.get("name", "")]
	profile_sector_label.text = "Sector: %s  |  Archetype: %s  |  Size: %s  |  Board: %s" % [
		snapshot.get("sector_name", "Unknown"),
		str(snapshot.get("archetype_label", "Unclassified")),
		str(snapshot.get("company_size_label", "Unknown")),
		str(snapshot.get("listing_board", "main")).capitalize()
	]
	profile_price_label.text = "Price now: %s  |  Previous close: %s  |  Daily move: %s" % [
		_format_currency(float(snapshot.get("current_price", 0.0))),
		_format_currency(float(snapshot.get("previous_close", 0.0))),
		_format_change(float(snapshot.get("daily_change_pct", 0.0)))
	]
	profile_factor_label.text = "Company profile: quality %d  |  growth %d  |  risk %d  |  founded %d  |  age %dy  |  employees %s  |  revenue %s" % [
		int(snapshot.get("quality_score", 0)),
		int(snapshot.get("growth_score", 0)),
		int(snapshot.get("risk_score", 0)),
		int(snapshot.get("founded_year", 0)),
		int(snapshot.get("company_age", 0)),
		_format_grouped_integer(int(snapshot.get("employee_count", 0))),
		_format_compact_currency(float(snapshot.get("profile_revenue", 0.0)))
	]
	profile_tags_label.text = "Tags: %s" % _join_or_default(snapshot.get("profile_tags", []), "none")
	profile_description_label.text = "Description: %s" % str(snapshot.get(
		"profile_description",
		"No generated profile description for this company."
	))
	key_stats_financial_label.text = "Financials:\n%s" % _format_financial_block(snapshot.get("financials", {}))
	financials_year_label.text = _format_statement_year_label(financial_statement_snapshot)
	analyzer_setup_label.text = "Setup read:\n%s" % _build_setup_read(snapshot)
	analyzer_support_label.text = "Supportive signals:\n%s" % _build_support_signals(snapshot)
	analyzer_risk_label.text = "Risk signals:\n%s" % _build_risk_signals(snapshot)
	analyzer_event_label.text = "Visible inputs:\nEvent tags: %s\nNarratives: %s" % [
		_join_or_default(snapshot.get("event_tags", []), "none today"),
		_join_or_default(snapshot.get("narrative_tags", []), "none")
	]
	analyzer_history_label.text = "Recent closes:\n%s" % _format_history(snapshot.get("price_history", []))
	financial_history_summary_label.text = _format_financial_history_summary(
		snapshot.get("financial_history", []),
		snapshot.get("financials", {})
	)
	_refresh_financial_history_table(
		snapshot.get("financial_history", []),
		snapshot.get("financials", {})
	)
	_refresh_broker_table(snapshot.get("broker_flow", {}))
	_refresh_statement_sections(financial_statement_snapshot)
	_refresh_order_controls(snapshot)
	_set_label_tone(profile_price_label, _color_for_change(float(snapshot.get("daily_change_pct", 0.0))))


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
	_refresh_dashboard()


func _on_dashboard_pressed() -> void:
	_set_active_section("dashboard")


func _on_stock_app_pressed() -> void:
	_set_active_app(APP_ID_STOCK)


func _on_news_app_pressed() -> void:
	_set_active_app(APP_ID_NEWS)


func _on_social_app_pressed() -> void:
	_set_active_app(APP_ID_SOCIAL)


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
	selected_news_article_id = str(articles[index].get("id", ""))
	_show_news_article(GameManager.get_news_archive_article(selected_news_article_id))


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


func _on_stock_list_tab_changed(_tab_index: int) -> void:
	_sync_selected_company_with_active_stock_list()
	_refresh_markets()
	_refresh_dashboard()
	_refresh_desktop()
	if debug_overlay.visible:
		_refresh_debug_overlay()


func _on_add_watchlist_pressed() -> void:
	if not RunState.has_active_run():
		return

	_populate_watchlist_picker()
	watchlist_picker_dialog.popup_centered(Vector2i(720, 520))


func _on_watchlist_picker_confirmed() -> void:
	if watchlist_picker_list == null:
		return

	var selected_items: PackedInt32Array = watchlist_picker_list.get_selected_items()
	if selected_items.is_empty():
		_show_toast("Pick a stock first.", false)
		return

	var selected_index: int = int(selected_items[0])
	if selected_index < 0 or selected_index >= watchlist_picker_company_ids.size():
		_show_toast("Pick a valid stock first.", false)
		return

	var company_id: String = str(watchlist_picker_company_ids[selected_index])
	var result: Dictionary = GameManager.add_company_to_watchlist(company_id)
	_show_toast(str(result.get("message", "Watchlist updated.")), bool(result.get("success", false)))
	if bool(result.get("success", false)):
		if watchlist_picker_dialog != null:
			watchlist_picker_dialog.hide()
		selected_company_id = company_id
		stock_list_tabs.current_tab = STOCK_LIST_TAB_WATCHLIST
		_refresh_all()


func _on_watchlist_picker_item_activated(index: int) -> void:
	if watchlist_picker_list == null:
		return
	watchlist_picker_list.select(index)
	_on_watchlist_picker_confirmed()
	if watchlist_picker_dialog != null:
		watchlist_picker_dialog.hide()


func _on_all_stock_selected(company_id: String) -> void:
	selected_company_id = company_id
	_refresh_after_company_selection()


func _on_portfolio_stock_selected(company_id: String) -> void:
	selected_company_id = company_id
	_refresh_after_company_selection()


func _on_add_to_watchlist_pressed(company_id: String) -> void:
	var result: Dictionary = GameManager.add_company_to_watchlist(company_id)
	_show_toast(str(result.get("message", "Watchlist updated.")), bool(result.get("success", false)))
	if bool(result.get("success", false)):
		selected_company_id = company_id
		_refresh_all()


func _on_taskbar_home_pressed() -> void:
	_set_active_app(APP_ID_DESKTOP)


func _on_taskbar_stock_pressed() -> void:
	_set_active_app(APP_ID_STOCK)


func _on_taskbar_news_pressed() -> void:
	_set_active_app(APP_ID_NEWS)


func _on_exit_app_pressed() -> void:
	GameManager.return_to_menu()


func _on_app_window_minimize_pressed() -> void:
	_set_active_app(APP_ID_DESKTOP)


func _on_app_window_close_pressed() -> void:
	_set_active_app(APP_ID_DESKTOP)


func _on_markets_pressed() -> void:
	_set_active_section("markets")


func _on_portfolio_pressed() -> void:
	_set_active_section("portfolio")


func _on_help_pressed() -> void:
	_set_active_section("help")


func _on_financials_previous_pressed() -> void:
	_shift_financial_statement_selection(-1)


func _on_financials_next_pressed() -> void:
	_shift_financial_statement_selection(1)


func _on_company_selected(index: int) -> void:
	if index < 0 or index >= displayed_company_ids.size():
		return

	selected_company_id = str(displayed_company_ids[index])
	_refresh_after_company_selection()


func _on_buy_side_pressed() -> void:
	active_order_side = "buy"
	_update_order_side_buttons()
	if not current_trade_snapshot.is_empty():
		_refresh_order_controls(current_trade_snapshot)


func _on_sell_side_pressed() -> void:
	active_order_side = "sell"
	_update_order_side_buttons()
	if not current_trade_snapshot.is_empty():
		_refresh_order_controls(current_trade_snapshot)


func _on_submit_order_pressed() -> void:
	var result: Dictionary = {}
	if active_order_side == "sell":
		result = GameManager.sell_lots(selected_company_id, _selected_lots())
	else:
		result = GameManager.buy_lots(selected_company_id, _selected_lots())
	status_message = str(result.get("message", "Order finished."))
	_show_toast(status_message, bool(result.get("success", false)))
	_refresh_all()


func _show_toast(message: String, is_success: bool) -> void:
	if message.is_empty():
		return

	toast_message_label.text = message
	_apply_toast_theme(is_success)
	toast_overlay.visible = true
	toast_panel.visible = true
	toast_timer.stop()
	toast_timer.start(TOAST_DURATION_SECONDS)


func _hide_toast() -> void:
	toast_timer.stop()
	toast_panel.visible = false
	toast_overlay.visible = false


func _on_toast_close_pressed() -> void:
	_hide_toast()


func _on_next_day_pressed() -> void:
	status_message = "Advancing day..."
	_refresh_dashboard()
	GameManager.advance_day()


func _on_day_progressed(_day_index: int) -> void:
	status_message = "Market closed."
	_refresh_all()


func _on_summary_ready(_summary: Dictionary) -> void:
	_refresh_dashboard()


func _on_lot_size_changed(value: float) -> void:
	selected_lots = max(int(round(value)), 1)
	_refresh_sidebar()
	_refresh_markets()


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


func _ensure_watchlist_picker_dialog() -> void:
	if watchlist_picker_dialog != null:
		return

	watchlist_picker_dialog = ConfirmationDialog.new()
	watchlist_picker_dialog.name = "WatchlistPickerDialog"
	watchlist_picker_dialog.title = "Add to Watchlist"
	add_child(watchlist_picker_dialog)
	watchlist_picker_dialog.confirmed.connect(_on_watchlist_picker_confirmed)
	watchlist_picker_dialog.get_ok_button().text = "Add"

	var picker_margin: MarginContainer = MarginContainer.new()
	picker_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	picker_margin.add_theme_constant_override("margin_left", 16)
	picker_margin.add_theme_constant_override("margin_top", 16)
	picker_margin.add_theme_constant_override("margin_right", 16)
	picker_margin.add_theme_constant_override("margin_bottom", 16)
	watchlist_picker_dialog.add_child(picker_margin)

	watchlist_picker_list = ItemList.new()
	watchlist_picker_list.name = "WatchlistPickerList"
	watchlist_picker_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	watchlist_picker_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	watchlist_picker_list.custom_minimum_size = Vector2(640, 360)
	watchlist_picker_list.item_activated.connect(_on_watchlist_picker_item_activated)
	picker_margin.add_child(watchlist_picker_list)


func _populate_watchlist_picker() -> void:
	if watchlist_picker_list == null:
		return

	watchlist_picker_company_ids.clear()
	watchlist_picker_list.clear()
	var watchlist_lookup: Dictionary = {}
	for company_id_value in GameManager.get_watchlist_company_ids():
		watchlist_lookup[str(company_id_value)] = true

	for row_value in GameManager.get_company_rows():
		var row: Dictionary = row_value
		var company_id: String = str(row.get("id", ""))
		var item_text: String = _build_stock_list_line(row)
		watchlist_picker_company_ids.append(company_id)
		watchlist_picker_list.add_item(item_text)
		var item_index: int = watchlist_picker_list.item_count - 1
		watchlist_picker_list.set_item_tooltip(item_index, _watchlist_tooltip(row))
		if watchlist_lookup.has(company_id):
			watchlist_picker_list.set_item_disabled(item_index, true)

	if watchlist_picker_list.item_count > 0:
		for item_index in range(watchlist_picker_list.item_count):
			if watchlist_picker_list.is_item_disabled(item_index):
				continue
			watchlist_picker_list.select(item_index)
			break


func _build_tutorial_text() -> String:
	return "Open the STOCKBOT app from the desktop, then pick one stock first.\n\nUse the Chart, Key Stats, Financials, Broker, Analyzer, or Profile tabs to inspect the setup, size the order from the right-side ticket, then use the navbar to advance the day.\n\nDashboard is now overview-only, while Portfolio keeps your holdings and trade history together.\n\nDifficulty: %s." % GameManager.get_current_difficulty_label()


func _build_help_text() -> String:
	return "OVERVIEW\nThe game screen is split into modular views so you can move sections around more easily later.\nSidebar sections now swap self-contained views instead of one giant screen.\n\nOBJECTIVE\nFind the clearest setup, size lightly, then learn from the close.\n\nSECTIONS\n%s\n\n%s\n\n%s\n\nWORKFLOW\n1. Start on Dashboard for the market overview.\n2. Open Trade and choose a stock.\n3. Use Chart, Key Stats, Financials, Broker, Analyzer, or Profile to inspect it.\n4. Size the order from the right-side ticket.\n5. Advance the day.\n\nNOTES\nUse sector context to decide whether a stock is moving with its group or fighting it.\nNewest fills appear first in Trade History so you can audit lots, fees, cash impact, and realized P/L.\n\nCURRENT DIFFICULTY\n%s" % [
		_sidebar_hint_for_section("dashboard"),
		_sidebar_hint_for_section("markets"),
		_sidebar_hint_for_section("portfolio"),
		GameManager.get_current_difficulty_label()
	]


func _build_debug_upcoming_events_text() -> String:
	var lines: Array = []
	for arc_value in GameManager.get_active_company_arcs():
		var arc: Dictionary = arc_value
		if str(arc.get("phase_visibility", "visible")) != "hidden":
			continue

		var next_phase: Dictionary = _next_visible_arc_phase(arc)
		var next_phase_label: String = str(next_phase.get("label", "Visible move"))
		var next_phase_day: int = int(next_phase.get("start_run_day", int(arc.get("phase_end_offset", 1)) + int(arc.get("start_day_index", 1))))
		var next_phase_date: Dictionary = portfolio_trading_calendar.trade_date_for_index(max(next_phase_day, 1))
		lines.append("%s | %s\nHidden phase: %s (%d/%d)\nNext visible: %s around %s\nTone: %s | Arc ends around %s" % [
			str(arc.get("target_ticker", "")),
			_format_debug_event_title(str(arc.get("event_id", ""))),
			str(arc.get("current_phase_label", "Accumulation")),
			int(arc.get("phase_day_index", 1)),
			int(arc.get("phase_duration_days", 1)),
			next_phase_label,
			GameManager.format_trade_date(next_phase_date),
			str(arc.get("tone", "mixed")).capitalize(),
			GameManager.format_trade_date(portfolio_trading_calendar.trade_date_for_index(max(int(arc.get("end_day_index", 1)), 1)))
		])

	if lines.is_empty():
		return "No hidden buildup or rumor arcs right now."

	return "\n\n".join(lines)


func _build_debug_current_events_text() -> String:
	var lines: Array = []
	for arc_value in GameManager.get_active_company_arcs():
		var arc: Dictionary = arc_value
		if str(arc.get("phase_visibility", "visible")) == "hidden":
			continue

		lines.append("%s | %s\nCurrent phase: %s (%d/%d)\nStarted: %s | Ends around %s\nTone: %s | Bias: %s" % [
			str(arc.get("target_ticker", "")),
			_format_debug_event_title(str(arc.get("event_id", ""))),
			str(arc.get("current_phase_label", "Live")),
			int(arc.get("phase_day_index", 1)),
			int(arc.get("phase_duration_days", 1)),
			GameManager.format_trade_date(portfolio_trading_calendar.trade_date_for_index(max(int(arc.get("start_day_index", 1)), 1))),
			GameManager.format_trade_date(portfolio_trading_calendar.trade_date_for_index(max(int(arc.get("end_day_index", 1)), 1))),
			str(arc.get("tone", "mixed")).capitalize(),
			_format_change(float(arc.get("phase_sentiment_shift", 0.0)))
		])

	if lines.is_empty():
		return "No visible company arcs are active right now."

	return "\n\n".join(lines)


func _build_debug_special_events_text() -> String:
	var sections: Array = []
	var active_special_events: Array = GameManager.get_active_special_events()
	if not active_special_events.is_empty():
		var active_lines: Array = []
		for event_value in active_special_events:
			var event_data: Dictionary = event_value
			var start_date: Dictionary = event_data.get("trade_date", {}).duplicate(true)
			var end_date: Dictionary = portfolio_trading_calendar.trade_date_for_index(max(int(event_data.get("end_day_index", 1)), 1))
			active_lines.append("%s\nWindow: %s to %s | %d day(s) left\nSectors: %s\nBias: %s | Vol x%s\n%s" % [
				str(event_data.get("headline", _format_debug_event_title(str(event_data.get("event_id", ""))))),
				GameManager.format_trade_date(start_date),
				GameManager.format_trade_date(end_date),
				max(int(event_data.get("end_day_index", 0)) - RunState.day_index, 0),
				_format_debug_sector_targets(
					event_data.get("affected_sector_ids", []).duplicate(),
					event_data.get("sector_biases", {}).duplicate(true)
				),
				_format_change(float(event_data.get("market_bias_shift", 0.0))),
				String.num(float(event_data.get("volatility_multiplier", 1.0)), 2),
				_debug_event_detail_text(event_data)
			])
		sections.append("ACTIVE SPECIAL ARCS\n%s" % "\n\n".join(active_lines))

	var recent_lines: Array = []
	for event_value in _recent_event_history_by_family("special", 8):
		var event_data: Dictionary = event_value
		recent_lines.append("Day %d | %s\nHeadline: %s\nDate: %s | Tone: %s" % [
			int(event_data.get("day_index", 0)),
			_format_debug_event_title(str(event_data.get("event_id", ""))),
			str(event_data.get("headline", event_data.get("description", ""))),
			GameManager.format_trade_date(event_data.get("trade_date", {})),
			str(event_data.get("tone", "mixed")).capitalize()
		])
	if not recent_lines.is_empty():
		sections.append("RECENT SPECIAL LOG\n%s" % "\n\n".join(recent_lines))

	if sections.is_empty():
		return "No special-event arcs are active or logged yet."

	return "\n\n".join(sections)


func _build_debug_person_events_text() -> String:
	var recent_person_events: Array = _recent_event_history_by_family("person", 12)
	if recent_person_events.is_empty():
		return "No person-of-interest events have hit the tape yet."

	var lines: Array = []
	for event_value in recent_person_events:
		var event_data: Dictionary = event_value
		lines.append("Day %d | %s\n%s\nTarget: %s | Date: %s | Tone: %s" % [
			int(event_data.get("day_index", 0)),
			str(event_data.get("person_name", "Person of Interest")),
			str(event_data.get("headline", _format_debug_event_title(str(event_data.get("event_id", ""))))),
			_format_debug_scope_target(event_data),
			GameManager.format_trade_date(event_data.get("trade_date", {})),
			str(event_data.get("tone", "mixed")).capitalize()
		])

	return "\n\n".join(lines)


func _build_debug_generic_events_text() -> String:
	var sections: Array = []

	var recent_market_events: Array = _recent_event_history_by_family("market", 12)
	if not recent_market_events.is_empty():
		var market_lines: Array = []
		for event_value in recent_market_events:
			var event_data: Dictionary = event_value
			market_lines.append("Day %d | %s\nHeadline: %s\nTarget: %s | Date: %s | Tone: %s" % [
				int(event_data.get("day_index", 0)),
				_format_debug_event_title(str(event_data.get("event_id", ""))),
				str(event_data.get("headline", event_data.get("description", ""))),
				_format_debug_scope_target(event_data),
				GameManager.format_trade_date(event_data.get("trade_date", {})),
				str(event_data.get("tone", "mixed")).capitalize()
			])
		sections.append("MARKET EVENTS\n%s" % "\n\n".join(market_lines))

	var recent_company_events: Array = _recent_event_history_by_family("company", 12)
	if not recent_company_events.is_empty():
		var company_lines: Array = []
		for event_value in recent_company_events:
			var event_data: Dictionary = event_value
			company_lines.append("Day %d | %s\nHeadline: %s\nTarget: %s | Date: %s | Tone: %s" % [
				int(event_data.get("day_index", 0)),
				_format_debug_event_title(str(event_data.get("event_id", ""))),
				str(event_data.get("headline", event_data.get("description", ""))),
				_format_debug_scope_target(event_data),
				GameManager.format_trade_date(event_data.get("trade_date", {})),
				str(event_data.get("tone", "mixed")).capitalize()
			])
		sections.append("COMPANY EVENTS\n%s" % "\n\n".join(company_lines))

	if sections.is_empty():
		return "No generic market or one-day company events are logged yet."

	return "\n\n".join(sections)


func _build_debug_stock_performance_text() -> String:
	var stock_rows: Array = GameManager.get_company_rows()
	if stock_rows.is_empty():
		return "No stock universe is loaded yet."

	stock_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("ticker", "")) < str(b.get("ticker", ""))
	)

	var current_year: int = int(GameManager.get_current_trade_date().get("year", 2020))
	var lines: Array = []
	for row_value in stock_rows:
		var row: Dictionary = row_value
		lines.append("%s | Start %s | %d YTD Open %s | Current %s | Since start %s | YTD %s" % [
			str(row.get("ticker", "")),
			_format_currency(float(row.get("starting_price", 0.0))),
			int(row.get("ytd_reference_year", current_year)),
			_format_currency(float(row.get("ytd_open_price", 0.0))),
			_format_currency(float(row.get("current_price", 0.0))),
			_format_change(float(row.get("since_start_pct", 0.0))),
			_format_change(float(row.get("ytd_change_pct", 0.0)))
		])

	return "\n".join(lines)


func _build_debug_market_history_text() -> String:
	var history: Array = GameManager.get_market_history()
	if history.is_empty():
		return "No market closes recorded yet. Advance the first day to build history."

	var lines: Array = []
	for history_value in history:
		var entry: Dictionary = history_value
		var winner: Dictionary = entry.get("biggest_winner", {})
		var loser: Dictionary = entry.get("biggest_loser", {})
		var trade_date: Dictionary = entry.get("trade_date", {})
		lines.append("Day %d | %s | Market %s | Avg %s | A/D/F %d/%d/%d | Best %s %s | Worst %s %s" % [
			int(entry.get("day_index", 0)),
			GameManager.format_trade_date(trade_date),
			_format_change(float(entry.get("market_sentiment", 0.0))),
			_format_change(float(entry.get("average_change_pct", 0.0))),
			int(entry.get("advancers", 0)),
			int(entry.get("decliners", 0)),
			int(entry.get("flat_count", 0)),
			str(winner.get("ticker", "n/a")),
			_format_change(float(winner.get("change_pct", 0.0))),
			str(loser.get("ticker", "n/a")),
			_format_change(float(loser.get("change_pct", 0.0)))
		])

	return "\n".join(lines)


func _recent_event_history_by_family(event_family: String, limit: int = 10) -> Array:
	var matches: Array = []
	var history: Array = GameManager.get_event_history()
	for index in range(history.size() - 1, -1, -1):
		var entry: Dictionary = history[index]
		if str(entry.get("event_family", "")) != event_family:
			continue
		matches.append(entry)
		if matches.size() >= limit:
			break
	return matches


func _format_debug_scope_target(event_data: Dictionary) -> String:
	var scope: String = str(event_data.get("scope", "market"))
	if scope == "company":
		var ticker: String = str(event_data.get("target_ticker", event_data.get("target_company_id", "")))
		var company_name: String = str(event_data.get("target_company_name", ""))
		if company_name.is_empty():
			return ticker
		return "%s (%s)" % [ticker, company_name]
	if scope == "sector":
		return _format_debug_sector_targets([str(event_data.get("target_sector_id", ""))], {})
	return "Market-wide"


func _format_debug_sector_targets(affected_sector_ids: Array, sector_biases: Dictionary = {}) -> String:
	var sector_ids: Array = []
	for sector_id_value in affected_sector_ids:
		var sector_id: String = str(sector_id_value)
		if sector_id.is_empty() or sector_ids.has(sector_id):
			continue
		sector_ids.append(sector_id)
	if sector_ids.is_empty():
		for sector_id_value in sector_biases.keys():
			var sector_id: String = str(sector_id_value)
			if sector_id.is_empty() or sector_ids.has(sector_id):
				continue
			sector_ids.append(sector_id)
	if sector_ids.is_empty():
		return "Market-wide"

	var sector_names: Array = []
	for sector_id_value in sector_ids:
		var sector_id: String = str(sector_id_value)
		var sector_definition: Dictionary = DataRepository.get_sector_definition(sector_id)
		sector_names.append(str(sector_definition.get("name", sector_id.capitalize())))
	return ", ".join(sector_names)


func _debug_event_detail_text(event_data: Dictionary) -> String:
	var detail_text: String = str(event_data.get("headline_detail", ""))
	if detail_text.is_empty():
		detail_text = str(event_data.get("description", ""))
	return detail_text


func _next_visible_arc_phase(arc: Dictionary) -> Dictionary:
	var phase_schedule: Array = arc.get("phase_schedule", []).duplicate(true)
	var current_phase_id: String = str(arc.get("current_phase_id", ""))
	var running_total: int = 0
	var current_phase_index: int = -1

	for phase_index in range(phase_schedule.size()):
		var phase: Dictionary = phase_schedule[phase_index]
		if str(phase.get("id", "")) == current_phase_id:
			current_phase_index = phase_index
			break

	if current_phase_index == -1:
		return {}

	running_total = 0
	for phase_index in range(phase_schedule.size()):
		var phase: Dictionary = phase_schedule[phase_index]
		var duration_days: int = max(int(phase.get("duration_days", 1)), 1)
		var phase_start_offset: int = running_total + 1
		var phase_end_offset: int = running_total + duration_days
		if phase_index > current_phase_index and str(phase.get("visibility", "visible")) != "hidden":
			var next_phase: Dictionary = phase.duplicate(true)
			next_phase["start_offset"] = phase_start_offset
			next_phase["end_offset"] = phase_end_offset
			next_phase["start_run_day"] = int(arc.get("start_day_index", 1)) + phase_start_offset - 1
			return next_phase
		running_total = phase_end_offset

	return {}


func _format_debug_event_title(event_id: String) -> String:
	if event_id.is_empty():
		return "Unknown Event"

	var words: PackedStringArray = event_id.split("_", false)
	var parts: Array = []
	for word_value in words:
		var word: String = str(word_value)
		if word.is_empty():
			continue
		parts.append(word.capitalize())
	return " ".join(parts)


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
	var current_price: float = float(snapshot.get("current_price", 0.0))
	var previous_close: float = float(snapshot.get("previous_close", current_price))
	var price_change_value: float = current_price - previous_close
	var active_estimate: Dictionary = sell_estimate if active_order_side == "sell" else buy_estimate
	var estimated_total: float = float(active_estimate.get("net_proceeds", 0.0)) if active_order_side == "sell" else float(active_estimate.get("total_cost", 0.0))
	var can_submit: bool = can_sell if active_order_side == "sell" else can_buy

	order_company_name_label.text = str(snapshot.get("name", "No selection")).to_upper()
	selection_label.text = str(snapshot.get("ticker", "-"))
	order_price_value_label.text = _format_currency(current_price)
	order_price_change_label.text = "%s  |  %s" % [
		_format_signed_currency(price_change_value),
		_format_change(float(snapshot.get("daily_change_pct", 0.0)))
	]
	order_position_label.text = "Held %d lot(s) / %d share(s)  |  Cash %s  |  %d lot(s) = %d share(s)" % [
		lots_owned,
		shares_owned,
		_format_currency(available_cash),
		current_lots,
		requested_shares
	]
	if odd_lot_remainder > 0:
		order_position_label.text += "  |  Odd lot %d share(s)" % odd_lot_remainder

	order_title_label.text = "Sell Order" if active_order_side == "sell" else "Buy Order"
	order_price_line_edit.text = _format_currency(current_price)
	estimated_total_value_label.text = _format_currency(estimated_total)
	submit_order_button.text = "Submit Sell Order" if active_order_side == "sell" else "Submit Buy Order"
	submit_order_button.disabled = not can_submit
	buy_button.disabled = false
	sell_button.disabled = false
	_refresh_submit_order_button_style()
	_update_order_side_buttons()
	_set_label_tone(order_price_change_label, _color_for_change(float(snapshot.get("daily_change_pct", 0.0))))
	_set_label_tone(estimated_total_value_label, COLOR_TEXT if can_submit else COLOR_MUTED)


func _selected_lots() -> int:
	return max(selected_lots, 1)


func _update_order_side_buttons() -> void:
	buy_button.set_pressed_no_signal(active_order_side == "buy")
	sell_button.set_pressed_no_signal(active_order_side == "sell")
	_refresh_submit_order_button_style()


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


func _set_active_app(app_id: String) -> void:
	var normalized_app_id: String = app_id.to_lower()
	if normalized_app_id != APP_ID_STOCK and normalized_app_id != APP_ID_NEWS and normalized_app_id != APP_ID_SOCIAL:
		normalized_app_id = APP_ID_DESKTOP

	active_app_id = normalized_app_id
	desktop_layer.visible = true
	app_window_backdrop.visible = active_app_id != APP_ID_DESKTOP
	app_window_title_bar.visible = active_app_id != APP_ID_DESKTOP
	stock_window_container.visible = active_app_id == APP_ID_STOCK
	app_content_margin.visible = active_app_id == APP_ID_STOCK
	news_window.visible = active_app_id == APP_ID_NEWS
	social_window.visible = active_app_id == APP_ID_SOCIAL

	if active_app_id == APP_ID_STOCK:
		app_window_title_label.text = "STOCKBOT"
		call_deferred("_update_responsive_layout")
	elif active_app_id == APP_ID_NEWS:
		app_window_title_label.text = "News Browser"
		_refresh_news()
		_hide_debug_overlay()
		_hide_toast()
	elif active_app_id == APP_ID_SOCIAL:
		app_window_title_label.text = "Twooter"
		_refresh_social()
		_hide_debug_overlay()
		_hide_toast()
	else:
		app_window_title_label.text = ""
		_hide_debug_overlay()
		_hide_toast()

	_apply_window_layout()
	_apply_active_window_theme()
	_refresh_desktop()


func _apply_window_layout() -> void:
	var window_margin_left: float = APP_WINDOW_INSET
	var window_margin_top: float = APP_WINDOW_INSET
	var window_margin_right: float = APP_WINDOW_INSET
	var window_margin_bottom: float = APP_WINDOW_FRAME_BOTTOM_MARGIN
	var social_margin_left: float = APP_WINDOW_CONTENT_MARGIN
	var social_margin_top: float = APP_WINDOW_CONTENT_TOP_MARGIN
	var social_margin_right: float = APP_WINDOW_CONTENT_MARGIN
	var social_margin_bottom: float = APP_WINDOW_CONTENT_BOTTOM_MARGIN

	if active_app_id == APP_ID_SOCIAL:
		var viewport_size: Vector2 = get_viewport_rect().size
		var social_width: float = clamp(viewport_size.x - 72.0, 340.0, SOCIAL_WINDOW_MAX_WIDTH)
		var social_height: float = clamp(viewport_size.y - 96.0, SOCIAL_WINDOW_MIN_HEIGHT, SOCIAL_WINDOW_MAX_HEIGHT)
		window_margin_left = max(floor((viewport_size.x - social_width) * 0.5), 16.0)
		window_margin_right = max(viewport_size.x - window_margin_left - social_width, 16.0)
		window_margin_top = max(floor((viewport_size.y - social_height) * 0.5), 16.0)
		window_margin_bottom = max(viewport_size.y - window_margin_top - social_height, 16.0)
		social_margin_left = window_margin_left + 8.0
		social_margin_top = window_margin_top + 48.0
		social_margin_right = window_margin_right + 8.0
		social_margin_bottom = window_margin_bottom + 8.0

	app_window_margin.add_theme_constant_override("margin_left", int(window_margin_left))
	app_window_margin.add_theme_constant_override("margin_top", int(window_margin_top))
	app_window_margin.add_theme_constant_override("margin_right", int(window_margin_right))
	app_window_margin.add_theme_constant_override("margin_bottom", int(window_margin_bottom))
	app_content_margin.offset_left = APP_WINDOW_CONTENT_MARGIN
	app_content_margin.offset_top = APP_WINDOW_CONTENT_TOP_MARGIN
	app_content_margin.offset_right = -APP_WINDOW_CONTENT_MARGIN
	app_content_margin.offset_bottom = -APP_WINDOW_CONTENT_BOTTOM_MARGIN
	app_content_margin.add_theme_constant_override("margin_left", APP_WINDOW_INNER_PADDING)
	app_content_margin.add_theme_constant_override("margin_top", APP_WINDOW_INNER_PADDING)
	app_content_margin.add_theme_constant_override("margin_right", APP_WINDOW_INNER_PADDING)
	app_content_margin.add_theme_constant_override("margin_bottom", APP_WINDOW_INNER_PADDING)
	top_bar_outer_margin.add_theme_constant_override("margin_left", 0)
	top_bar_outer_margin.add_theme_constant_override("margin_top", 0)
	top_bar_outer_margin.add_theme_constant_override("margin_right", 0)
	sidebar_outer_margin.add_theme_constant_override("margin_left", 0)
	sidebar_outer_margin.add_theme_constant_override("margin_top", 0)
	sidebar_outer_margin.add_theme_constant_override("margin_bottom", 0)
	news_window.add_theme_constant_override("margin_left", APP_WINDOW_CONTENT_MARGIN)
	news_window.add_theme_constant_override("margin_top", APP_WINDOW_CONTENT_TOP_MARGIN)
	news_window.add_theme_constant_override("margin_right", APP_WINDOW_CONTENT_MARGIN)
	news_window.add_theme_constant_override("margin_bottom", APP_WINDOW_CONTENT_BOTTOM_MARGIN)
	social_window.add_theme_constant_override("margin_left", int(social_margin_left))
	social_window.add_theme_constant_override("margin_top", int(social_margin_top))
	social_window.add_theme_constant_override("margin_right", int(social_margin_right))
	social_window.add_theme_constant_override("margin_bottom", int(social_margin_bottom))
	app_window_title_bar.offset_left = window_margin_left
	app_window_title_bar.offset_top = window_margin_top
	app_window_title_bar.offset_right = -window_margin_right
	app_window_title_bar.offset_bottom = window_margin_top + 44.0
	stock_window_container.offset_left = APP_WINDOW_CONTENT_MARGIN
	stock_window_container.offset_top = APP_WINDOW_CONTENT_TOP_MARGIN
	stock_window_container.offset_right = -APP_WINDOW_CONTENT_MARGIN
	stock_window_container.offset_bottom = -APP_WINDOW_CONTENT_BOTTOM_MARGIN


func _apply_active_window_theme() -> void:
	var is_light_window: bool = active_app_id == APP_ID_NEWS or active_app_id == APP_ID_SOCIAL
	var window_fill: Color = COLOR_WINDOW_BG if is_light_window else COLOR_STOCK_WINDOW_BG
	var window_text: Color = COLOR_WINDOW_TEXT if is_light_window else COLOR_TEXT
	var app_font_size: int = STOCK_APP_FONT_SIZE if active_app_id == APP_ID_STOCK else DEFAULT_APP_FONT_SIZE
	_style_panel(app_window_panel, window_fill, 8)
	_style_window_title_bar(app_window_title_bar, window_fill)
	_style_panel(stock_window_container, COLOR_STOCK_WINDOW_BG, 0)
	app_window_title_bar.add_theme_font_size_override("font_size", app_font_size)
	_set_label_tone(app_window_title_label, window_text)
	app_window_title_label.add_theme_color_override("font_color", window_text)


func _sync_desktop_app_state() -> void:
	var stock_active: bool = active_app_id == APP_ID_STOCK
	var news_active: bool = active_app_id == APP_ID_NEWS
	var social_active: bool = active_app_id == APP_ID_SOCIAL
	stock_app_button.set_pressed_no_signal(stock_active)
	news_app_button.set_pressed_no_signal(news_active)
	social_app_button.set_pressed_no_signal(social_active)
	taskbar_stock_button.set_pressed_no_signal(stock_active)
	taskbar_news_button.set_pressed_no_signal(news_active)
	taskbar_home_button.disabled = active_app_id == APP_ID_DESKTOP


func _build_taskbar_status_text(focus_snapshot: Dictionary) -> String:
	if active_app_id == APP_ID_STOCK:
		if focus_snapshot.is_empty():
			return "STOCKBOT running."
		return "STOCKBOT live  |  Focus %s @ %s  |  Market %s" % [
			str(focus_snapshot.get("ticker", "")),
			_format_currency(float(focus_snapshot.get("current_price", 0.0))),
			_format_change(RunState.market_sentiment)
		]
	if active_app_id == APP_ID_NEWS:
		return "News browser open  |  Event-driven intel feed online."
	if active_app_id == APP_ID_SOCIAL:
		return "Twooter open  |  Tiered social feed online."
	return "Desktop ready  |  Open STOCKBOT to trade, News to browse intel, or Twooter to scan social chatter."


func _section_label(section_id: String) -> String:
	if section_id == "markets":
		return "Trade"
	if section_id == "portfolio":
		return "Portfolio"
	if section_id == "help":
		return "Help"
	return "Dashboard"


func _sidebar_hint_for_section(section_id: String) -> String:
	if section_id == "markets":
		return "Trade keeps the stock list, chart workspace, and order ticket together so you can inspect and execute without bouncing between sections."
	if section_id == "portfolio":
		return "Portfolio keeps positions and trade history in one place so you can review exposure, fees, and realized P/L."
	return "Dashboard is now overview-only, giving you the tape, macro, portfolio, and event context before you drill into Trade."


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


func _build_market_overview_text(macro_state: Dictionary, sector_rows: Array) -> String:
	var positive_sectors: int = 0
	var negative_sectors: int = 0
	var strongest_sector_name: String = "n/a"
	var strongest_sector_move: float = 0.0
	var strongest_sector_found: bool = false

	for row_value in sector_rows:
		var row: Dictionary = row_value
		var average_change_pct: float = float(row.get("average_change_pct", 0.0))
		if average_change_pct > 0.0:
			positive_sectors += 1
		elif average_change_pct < 0.0:
			negative_sectors += 1

		if not strongest_sector_found or abs(average_change_pct) > abs(strongest_sector_move):
			strongest_sector_found = true
			strongest_sector_name = str(row.get("name", "Unknown"))
			strongest_sector_move = average_change_pct

	var flat_sectors: int = max(sector_rows.size() - positive_sectors - negative_sectors, 0)
	return "Market tone: %s\nMacro: %s\nInflation %.1f%% | GDP %.1f%% | Employment %.1f%% | Policy %.2f%% (%+d bps)\nSector breadth: %d green | %d red | %d flat | Loudest sector %s %s" % [
		_format_change(RunState.market_sentiment),
		str(macro_state.get("central_bank_stance", "hold")).capitalize(),
		float(macro_state.get("inflation_rate", 0.0)),
		float(macro_state.get("gdp_growth", 0.0)),
		float(macro_state.get("employment_rate", 0.0)),
		float(macro_state.get("policy_rate", 0.0)),
		int(macro_state.get("policy_action_bps", 0)),
		positive_sectors,
		negative_sectors,
		flat_sectors,
		strongest_sector_name,
		_format_change(strongest_sector_move)
	]


func _build_dashboard_portfolio_text(portfolio: Dictionary) -> String:
	var unrealized_pnl_pct: float = float(portfolio.get("unrealized_pnl_pct", 0.0))
	return "Portfolio: Equity %s | Cash %s | Invested %s\nOpen P&L %s (%s)\n%s" % [
		_format_currency(float(portfolio.get("equity", 0.0))),
		_format_currency(float(portfolio.get("cash", 0.0))),
		_format_currency(float(portfolio.get("invested_cost", 0.0))),
		_format_signed_currency(float(portfolio.get("unrealized_pnl", 0.0))),
		_format_change(unrealized_pnl_pct),
		_build_portfolio_prompt(portfolio)
	]


func _build_dashboard_focus_text(snapshot: Dictionary) -> String:
	if snapshot.is_empty():
		return "Focus: none selected.\nOpen Trade and choose a stock from the list."

	var summary: Dictionary = GameManager.get_latest_summary()
	var summary_line: String = "No close summary yet."
	if not summary.is_empty():
		summary_line = str(summary.get("explanation", "No close summary yet."))

	return "Focus: %s | %s | %s\n%s\nLatest close read: %s" % [
		str(snapshot.get("ticker", "")),
		_format_currency(float(snapshot.get("current_price", 0.0))),
		_format_change(float(snapshot.get("daily_change_pct", 0.0))),
		_build_setup_read(snapshot),
		summary_line
	]


func _build_special_overview_text(active_special_events: Array) -> String:
	if active_special_events.is_empty():
		return "Live events: no active special regime.\nPerson and company arcs may still be influencing individual names behind the scenes."

	var lines: Array = ["Live events:"]
	for event_value in active_special_events:
		var event_data: Dictionary = event_value
		lines.append("- %s | phase %s | impact %s" % [
			_format_debug_event_title(str(event_data.get("event_id", ""))),
			str(event_data.get("current_phase_id", "live")).replace("_", " "),
			_format_change(float(event_data.get("market_bias_shift", 0.0)))
		])
	return "\n".join(lines)


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
	var dominant_buy_actor: String = _broker_actor_label(broker_flow, "buy")
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
	if dominant_buyer in ["foreign", "institution", "bandar", "zombie"]:
		signals.append("- cleaner buyer profile: %s" % dominant_buy_actor)
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
	var dominant_sell_actor: String = _broker_actor_label(broker_flow, "sell")
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
	if dominant_seller in ["retail", "foreign", "institution", "bandar", "zombie"] and dominant_seller != "balanced":
		risks.append("- active selling from %s" % dominant_sell_actor)
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
	var dominant_buy_actor: String = _broker_actor_label(broker_flow, "buy")
	var dominant_sell_actor: String = _broker_actor_label(broker_flow, "sell")

	if shares_owned > 0 and flow_tag == "distribution":
		return "You already hold %d lot(s). Decide whether today's selling pressure weakens your original thesis." % lots_owned
	if shares_owned > 0:
		return "You already have exposure. Use the lot selector to scale deliberately, not just because price moved."
	if flow_tag == "accumulation" and dominant_buyer != "balanced":
		return "%s is currently the strongest buyer. Start small and let the fee-aware preview define your first lot." % dominant_buy_actor
	if dominant_seller != "balanced":
		return "%s is leaning on this tape. Waiting is a valid decision." % dominant_sell_actor
	return "No position yet. Use this panel to size a deliberate first lot."


func _build_broker_hint(snapshot: Dictionary) -> String:
	var broker_flow: Dictionary = snapshot.get("broker_flow", {})
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))
	var dominant_buy_actor: String = _broker_actor_label(broker_flow, "buy")
	var dominant_sell_actor: String = _broker_actor_label(broker_flow, "sell")

	if flow_tag == "accumulation":
		return "Read: %s is supporting the tape, so ask whether price action agrees or is still lagging." % dominant_buy_actor
	if flow_tag == "distribution":
		return "Read: %s is the main seller, so ask whether weakness is temporary or the thesis is breaking." % dominant_sell_actor
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


func _titleize_snake_case(value: String) -> String:
	var words: PackedStringArray = value.split("_", false)
	var parts: Array = []
	for word_value in words:
		var word: String = str(word_value)
		if word.is_empty():
			continue
		parts.append(word.capitalize())
	return " ".join(parts)


func _broker_actor_label(broker_flow: Dictionary, side: String) -> String:
	var normalized_side: String = side.to_lower()
	var broker_code_key: String = "dominant_buy_broker_code" if normalized_side == "buy" else "dominant_sell_broker_code"
	var broker_type_key: String = "dominant_buy_broker_type" if normalized_side == "buy" else "dominant_sell_broker_type"
	var fallback_key: String = "dominant_buyer" if normalized_side == "buy" else "dominant_seller"
	var broker_code: String = str(broker_flow.get(broker_code_key, ""))
	if not broker_code.is_empty():
		return broker_code
	var fallback_value: String = str(broker_flow.get(broker_type_key, broker_flow.get(fallback_key, "balanced")))
	if fallback_value.is_empty() or fallback_value == "balanced":
		return "Balanced"
	return fallback_value.capitalize()


func _watchlist_tooltip(row: Dictionary) -> String:
	var broker_flow: Dictionary = row.get("broker_flow", {})
	return "%s\nSector: %s\nHeld: %d lot(s) / %d share(s)\nBuyer: %s\nSeller: %s\nTape: %s" % [
		row.get("name", row.get("ticker", "")),
		row.get("sector_name", "Unknown"),
		int(row.get("lots_owned", 0)),
		int(row.get("shares_owned", 0)),
		_broker_actor_label(broker_flow, "buy"),
		_broker_actor_label(broker_flow, "sell"),
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
	_style_panel(app_window_panel, COLOR_STOCK_WINDOW_BG, 8)
	_style_window_title_bar(app_window_title_bar, COLOR_STOCK_WINDOW_BG)
	_style_panel(stock_window_container, COLOR_STOCK_WINDOW_BG, 0)
	_style_panel(taskbar_panel, Color(0.0588235, 0.0823529, 0.109804, 0.96), 14)
	_style_panel(sidebar_panel, COLOR_PANEL_BLUE_ALT, 0, 0, 1, 1, 1)
	_style_panel(top_bar_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(dashboard_index_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(dashboard_calendar_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(dashboard_placeholder_top_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(dashboard_placeholder_bottom_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(news_window_body, COLOR_WINDOW_BG, 0)
	_style_panel(news_feed_panel, Color(0.952941, 0.94902, 0.87451, 1), 0)
	_style_panel(news_detail_panel, Color(0.968627, 0.964706, 0.898039, 1), 0)
	_style_panel(social_window_body, Color(0.94902, 0.956863, 0.976471, 1), 0)
	_style_panel(action_panel, COLOR_ORDER_PANEL_BG, 0)
	_style_panel(order_card_panel, COLOR_ORDER_CARD_BG, 0)
	_style_panel(key_stats_panel, COLOR_PANEL_BLUE, 0)
	_style_panel(financials_panel, COLOR_PANEL_BLUE, 0)
	_style_panel(broker_panel, COLOR_PANEL_BLUE, 0)
	_style_panel(analyzer_panel, COLOR_PANEL_BLUE, 0)
	_style_panel(profile_panel, COLOR_PANEL_BLUE, 0)
	_style_panel(watchlist_panel, COLOR_PANEL_BLUE, 0)
	_style_panel(work_area_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(portfolio_summary_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(portfolio_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(trade_history_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(help_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(debug_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(upcoming_events_panel, COLOR_PANEL_BLUE, 0)
	_style_panel(current_events_panel, COLOR_PANEL_BLUE, 0)
	_style_panel(special_events_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(person_events_panel, COLOR_PANEL_BLUE, 0)
	_style_panel(generic_events_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(debug_generators_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(stock_performance_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(market_history_panel, COLOR_PANEL_BLUE_ALT, 0)
	_apply_toast_theme(true)
	_style_desktop_icon_button(stock_app_button)
	_style_desktop_icon_button(news_app_button)
	_style_desktop_icon_button(social_app_button)
	_style_desktop_icon_button(exit_app_button)
	_style_button(taskbar_home_button, Color(0.117647, 0.168627, 0.223529, 1), COLOR_BORDER, COLOR_TEXT)
	_style_taskbar_launch_button(taskbar_stock_button)
	_style_taskbar_launch_button(taskbar_news_button)
	_style_navigation_button(dashboard_button)
	_style_navigation_button(markets_button)
	_style_navigation_button(portfolio_button)
	_style_navigation_button(help_button)
	_style_tab_container(stock_list_tabs, 0)
	_style_tab_container(work_tabs, 0)
	_style_tab_container(debug_tabs, 0)
	_style_button(add_watchlist_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_button(advance_day_button, Color(0.27451, 0.219608, 0.0980392, 1), Color(0.819608, 0.631373, 0.254902, 1), COLOR_TEXT, 0)
	_style_button(buy_button, COLOR_ORDER_BUY, COLOR_ORDER_BUY_BORDER, COLOR_TEXT, 0)
	_style_button(sell_button, COLOR_ORDER_SELL, COLOR_ORDER_SELL_BORDER, COLOR_TEXT, 0)
	_style_button(submit_order_button, COLOR_ORDER_BUY, COLOR_ORDER_BUY_BORDER, COLOR_TEXT, 0)
	_style_button(app_window_minimize_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_button(app_window_close_button, Color(0.368627, 0.160784, 0.176471, 1), Color(0.709804, 0.34902, 0.372549, 1), COLOR_TEXT, 0)
	_style_button(financials_previous_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_button(financials_next_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_button(debug_close_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_light_option_button(news_archive_year_option)
	_style_light_option_button(news_archive_month_option)
	_style_item_list(company_list, 0, 0)
	_style_light_item_list(news_article_list)
	if watchlist_picker_list != null:
		_style_item_list(watchlist_picker_list, 0, 0)
	_style_line_input(order_price_line_edit)
	_style_spin_input(lot_spin_box)
	_set_label_tone(objective_label, COLOR_MUTED)
	_set_label_tone(desktop_title_label, COLOR_DESKTOP_TEXT)
	_set_label_tone(desktop_date_label, COLOR_DESKTOP_TEXT)
	_set_label_tone(desktop_subtitle_label, COLOR_DESKTOP_TEXT)
	_set_label_tone(desktop_hint_label, COLOR_DESKTOP_TEXT)
	_set_label_tone(stock_app_label, COLOR_DESKTOP_TEXT)
	_set_label_tone(news_app_label, COLOR_DESKTOP_TEXT)
	_set_label_tone(social_app_label, COLOR_DESKTOP_TEXT)
	_set_label_tone(exit_app_label, COLOR_DESKTOP_TEXT)
	_set_label_tone(app_window_title_label, COLOR_TEXT)
	_set_label_tone(news_title_label, COLOR_WINDOW_TEXT)
	_set_label_tone(news_intel_status_label, Color(0.454902, 0.337255, 0.141176, 1))
	_set_label_tone(news_feed_summary_label, COLOR_WINDOW_TEXT)
	_set_label_tone(news_archive_year_label, COLOR_WINDOW_TEXT)
	_set_label_tone(news_archive_month_label, COLOR_WINDOW_TEXT)
	_set_label_tone(news_detail_outlet_label, Color(0.454902, 0.337255, 0.141176, 1))
	_set_label_tone(news_detail_headline_label, COLOR_WINDOW_TEXT)
	_set_label_tone(news_detail_deck_label, COLOR_WINDOW_TEXT)
	_set_label_tone(news_detail_meta_label, Color(0.352941, 0.309804, 0.203922, 1))
	_set_label_tone(news_detail_hint_label, Color(0.352941, 0.309804, 0.203922, 1))
	news_detail_body.add_theme_color_override("default_color", COLOR_WINDOW_TEXT)
	news_detail_body.add_theme_color_override("font_selected_color", COLOR_WINDOW_TEXT)
	_set_label_tone(social_title_label, Color(0.121569, 0.160784, 0.258824, 1))
	_set_label_tone(social_access_status_label, Color(0.196078, 0.301961, 0.486275, 1))
	_set_label_tone(debug_generators_hint_label, COLOR_MUTED)
	_set_label_tone(social_feed_summary_label, Color(0.121569, 0.160784, 0.258824, 1))
	_set_label_tone(taskbar_status_label, COLOR_MUTED)
	_set_label_tone(taskbar_clock_label, COLOR_WARNING)
	_set_label_tone(sidebar_intro_label, COLOR_MUTED)
	_set_label_tone(sidebar_focus_label, COLOR_ACCENT)
	_set_label_tone(sidebar_hint_label, COLOR_MUTED)
	_set_label_tone(dashboard_index_title_label, COLOR_ACCENT)
	_set_label_tone(dashboard_index_date_label, COLOR_MUTED)
	_set_label_tone(dashboard_index_hint_label, COLOR_WARNING)
	_set_label_tone(dashboard_calendar_month_label, COLOR_ACCENT)
	_set_label_tone(dashboard_placeholder_top_body_label, COLOR_MUTED)
	_set_label_tone(dashboard_placeholder_bottom_body_label, COLOR_MUTED)
	_set_label_tone(order_company_name_label, COLOR_MUTED)
	_set_label_tone(selection_label, COLOR_TEXT)
	_set_label_tone(order_price_value_label, COLOR_TEXT)
	_set_label_tone(order_price_change_label, COLOR_TEXT)
	_set_label_tone(order_position_label, COLOR_MUTED)
	_set_label_tone(order_title_label, COLOR_TEXT)
	_set_label_tone(estimated_total_value_label, COLOR_TEXT)
	_set_label_tone(watchlist_empty_label, COLOR_MUTED)
	_set_label_tone(portfolio_stocks_empty_label, COLOR_MUTED)
	_set_label_tone(profile_tags_label, COLOR_MUTED)
	_set_label_tone(profile_description_label, COLOR_TEXT)
	_set_label_tone(balance_value_label, COLOR_TEXT)
	_set_label_tone(invested_value_label, COLOR_TEXT)
	_set_label_tone(equity_value_label, COLOR_TEXT)
	_set_label_tone(holdings_empty_label, COLOR_MUTED)
	_set_label_tone(trade_history_empty_label, COLOR_MUTED)
	_set_label_tone(debug_hint_label, COLOR_MUTED)
	_set_label_tone(key_stats_financial_label, COLOR_MUTED)
	_set_label_tone(financial_history_summary_label, COLOR_MUTED)
	_set_label_tone(financial_history_empty_label, COLOR_MUTED)
	_set_label_tone(financials_year_label, COLOR_MUTED)
	_set_label_tone(financials_period_label, COLOR_WARNING)
	_set_label_tone(income_statement_empty_label, COLOR_MUTED)
	_set_label_tone(balance_sheet_empty_label, COLOR_MUTED)
	_set_label_tone(cash_flow_empty_label, COLOR_MUTED)
	_set_label_tone(broker_summary_label, COLOR_MUTED)
	_set_label_tone(broker_meter_label, COLOR_WARNING)
	_set_label_tone(broker_empty_label, COLOR_MUTED)
	_set_label_tone(broker_scale_left_label, COLOR_NEGATIVE)
	_set_label_tone(broker_scale_mid_label, COLOR_MUTED)
	_set_label_tone(broker_scale_right_label, COLOR_POSITIVE)
	_set_label_tone(analyzer_support_label, COLOR_POSITIVE)
	_set_label_tone(analyzer_risk_label, COLOR_NEGATIVE)
	help_text_label.add_theme_color_override("default_color", COLOR_TEXT)
	help_text_label.add_theme_color_override("font_selected_color", COLOR_TEXT)
	upcoming_events_label.add_theme_color_override("default_color", COLOR_TEXT)
	upcoming_events_label.add_theme_color_override("font_selected_color", COLOR_TEXT)
	current_events_label.add_theme_color_override("default_color", COLOR_TEXT)
	current_events_label.add_theme_color_override("font_selected_color", COLOR_TEXT)
	special_events_label.add_theme_color_override("default_color", COLOR_TEXT)
	special_events_label.add_theme_color_override("font_selected_color", COLOR_TEXT)
	person_events_label.add_theme_color_override("default_color", COLOR_TEXT)
	person_events_label.add_theme_color_override("font_selected_color", COLOR_TEXT)
	stock_performance_label.add_theme_color_override("default_color", COLOR_TEXT)
	stock_performance_label.add_theme_color_override("font_selected_color", COLOR_TEXT)
	market_history_label.add_theme_color_override("default_color", COLOR_TEXT)
	market_history_label.add_theme_color_override("font_selected_color", COLOR_TEXT)
	toast_message_label.add_theme_color_override("font_color", COLOR_TEXT)
	_apply_active_window_theme()
	_refresh_financial_history_header()
	_refresh_broker_header()


func _style_desktop_icon_button(button: Button) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.0156863, 0.0156863, 0.0196078, 1)
	normal.border_color = COLOR_BORDER
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 0
	normal.corner_radius_top_right = 0
	normal.corner_radius_bottom_right = 0
	normal.corner_radius_bottom_left = 0

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.0784314, 0.0941176, 0.117647, 1)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(0.164706, 0.215686, 0.278431, 1)
	pressed.border_color = COLOR_ACCENT
	pressed.set_border_width_all(2)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", pressed)
	button.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))


func _style_taskbar_launch_button(button: Button) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.101961, 0.141176, 0.180392, 1)
	normal.border_color = COLOR_BORDER
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_right = 6
	normal.corner_radius_bottom_left = 6

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.14902, 0.211765, 0.27451, 1)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = COLOR_NAV_ACTIVE_FILL
	pressed.border_color = COLOR_NAV_ACTIVE_BORDER
	pressed.set_border_width_all(2)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", pressed)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT)
	button.add_theme_color_override("font_focus_color", COLOR_TEXT)


func _style_window_title_bar(panel: PanelContainer, fill_color: Color) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = COLOR_BORDER
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", style)


func _style_panel(
	panel: PanelContainer,
	fill_color: Color,
	corner_radius: int = 10,
	border_top: int = 1,
	border_right: int = 1,
	border_bottom: int = 1,
	border_left: int = 1
) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = COLOR_BORDER
	style.border_width_top = border_top
	style.border_width_right = border_right
	style.border_width_bottom = border_bottom
	style.border_width_left = border_left
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", style)


func _style_broker_meter(fill_color: Color) -> void:
	if broker_meter_bar == null:
		return

	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = Color(0.0823529, 0.117647, 0.156863, 0.92)
	background.border_color = COLOR_BORDER
	background.set_border_width_all(1)
	background.corner_radius_top_left = 0
	background.corner_radius_top_right = 0
	background.corner_radius_bottom_right = 0
	background.corner_radius_bottom_left = 0

	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 0
	fill.corner_radius_top_right = 0
	fill.corner_radius_bottom_right = 0
	fill.corner_radius_bottom_left = 0

	broker_meter_bar.add_theme_stylebox_override("background", background)
	broker_meter_bar.add_theme_stylebox_override("fill", fill)


func _apply_toast_theme(is_success: bool) -> void:
	var panel_color: Color = COLOR_PANEL_GREEN if is_success else Color(0.243137, 0.133333, 0.141176, 0.96)
	var button_color: Color = panel_color.darkened(0.08)
	_style_panel(toast_panel, panel_color, 0)
	_style_button(toast_close_button, button_color, COLOR_BORDER, COLOR_TEXT, 0)


func _style_navigation_button(button: Button) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = COLOR_NAV_FILL
	normal.border_color = COLOR_BORDER
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 0
	normal.corner_radius_top_right = 0
	normal.corner_radius_bottom_right = 0
	normal.corner_radius_bottom_left = 0

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = COLOR_NAV_FILL.lightened(0.08)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = COLOR_NAV_ACTIVE_FILL
	pressed.border_color = COLOR_NAV_ACTIVE_BORDER
	pressed.set_border_width_all(2)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", pressed)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", Color(0.972549, 0.988235, 1, 1))
	button.add_theme_color_override("font_focus_color", Color(0.972549, 0.988235, 1, 1))


func _style_tab_container(tab_container: TabContainer, corner_radius: int = 6) -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0588235, 0.0823529, 0.109804, 0.35)
	panel_style.set_border_width_all(0)

	var tab_normal: StyleBoxFlat = StyleBoxFlat.new()
	tab_normal.bg_color = Color(0.0823529, 0.117647, 0.156863, 0.9)
	tab_normal.border_color = COLOR_BORDER
	tab_normal.set_border_width_all(1)
	tab_normal.corner_radius_top_left = corner_radius
	tab_normal.corner_radius_top_right = corner_radius
	tab_normal.corner_radius_bottom_left = corner_radius
	tab_normal.corner_radius_bottom_right = corner_radius
	tab_normal.content_margin_left = 12
	tab_normal.content_margin_right = 12
	tab_normal.content_margin_top = 6
	tab_normal.content_margin_bottom = 6

	var tab_selected: StyleBoxFlat = tab_normal.duplicate()
	tab_selected.bg_color = Color(0.184314, 0.247059, 0.309804, 0.98)
	tab_selected.border_color = COLOR_ACCENT
	tab_selected.set_border_width_all(2)

	var tab_hover: StyleBoxFlat = tab_normal.duplicate()
	tab_hover.bg_color = Color(0.117647, 0.168627, 0.223529, 1)

	tab_container.add_theme_stylebox_override("panel", panel_style)
	tab_container.add_theme_stylebox_override("tab_unselected", tab_normal)
	tab_container.add_theme_stylebox_override("tab_selected", tab_selected)
	tab_container.add_theme_stylebox_override("tab_hovered", tab_hover)
	tab_container.add_theme_color_override("font_selected_color", COLOR_TEXT)
	tab_container.add_theme_color_override("font_unselected_color", COLOR_MUTED)
	tab_container.add_theme_color_override("font_hovered_color", COLOR_TEXT)


func _style_button(
	button: Button,
	fill_color: Color,
	border_color: Color,
	font_color: Color,
	corner_radius: int = 8
) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = fill_color
	normal.border_color = border_color
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = corner_radius
	normal.corner_radius_top_right = corner_radius
	normal.corner_radius_bottom_right = corner_radius
	normal.corner_radius_bottom_left = corner_radius

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


func _style_light_option_button(option_button: OptionButton) -> void:
	_style_button(
		option_button,
		Color(0.909804, 0.87451, 0.737255, 1),
		Color(0.52549, 0.396078, 0.160784, 1),
		COLOR_WINDOW_TEXT,
		0
	)
	var popup: PopupMenu = option_button.get_popup()
	if popup == null:
		return

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.980392, 0.976471, 0.921569, 1)
	panel_style.border_color = Color(0.572549, 0.482353, 0.309804, 0.9)
	panel_style.set_border_width_all(1)
	popup.add_theme_stylebox_override("panel", panel_style)
	popup.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	popup.add_theme_color_override("font_hover_color", COLOR_WINDOW_TEXT)
	popup.add_theme_color_override("font_disabled_color", Color(0.541176, 0.494118, 0.396078, 1))


func _style_news_outlet_button(button: Button, is_selected: bool, is_unlocked: bool) -> void:
	var fill_color: Color = Color(0.87451, 0.843137, 0.705882, 1) if is_unlocked else Color(0.85098, 0.835294, 0.772549, 1)
	var border_color: Color = Color(0.47451, 0.384314, 0.227451, 1)
	var font_color: Color = COLOR_WINDOW_TEXT if is_unlocked else Color(0.541176, 0.494118, 0.396078, 1)
	if is_selected:
		fill_color = Color(0.772549, 0.694118, 0.447059, 1)
		border_color = Color(0.52549, 0.396078, 0.160784, 1)
		font_color = Color(0.184314, 0.14902, 0.0705882, 1)
	_style_button(button, fill_color, border_color, font_color, 0)


func _style_social_filter_button(button: Button, is_selected: bool, is_unlocked: bool) -> void:
	var fill_color: Color = Color(0.85098, 0.890196, 0.964706, 1) if is_unlocked else Color(0.85098, 0.866667, 0.901961, 1)
	var border_color: Color = Color(0.337255, 0.443137, 0.647059, 1)
	var font_color: Color = Color(0.0941176, 0.113725, 0.160784, 1) if is_unlocked else Color(0.423529, 0.470588, 0.560784, 1)
	if is_selected:
		fill_color = Color(0.572549, 0.713726, 0.929412, 1)
		border_color = Color(0.254902, 0.4, 0.639216, 1)
		font_color = Color(0.0470588, 0.0745098, 0.117647, 1)
	_style_button(button, fill_color, border_color, font_color, 0)


func _style_line_input(line_edit: LineEdit) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = COLOR_ORDER_INPUT_BG
	normal.border_color = COLOR_BORDER
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 0
	normal.corner_radius_top_right = 0
	normal.corner_radius_bottom_right = 0
	normal.corner_radius_bottom_left = 0
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var focus: StyleBoxFlat = normal.duplicate()
	focus.border_color = COLOR_ORDER_BUY_BORDER
	focus.set_border_width_all(2)

	line_edit.add_theme_stylebox_override("normal", normal)
	line_edit.add_theme_stylebox_override("focus", focus)
	line_edit.add_theme_stylebox_override("read_only", normal)
	line_edit.add_theme_color_override("font_color", COLOR_TEXT)
	line_edit.add_theme_color_override("font_placeholder_color", COLOR_MUTED)
	line_edit.add_theme_color_override("font_uneditable_color", COLOR_TEXT)
	line_edit.alignment = HORIZONTAL_ALIGNMENT_LEFT


func _style_spin_input(spin_box: SpinBox) -> void:
	var line_edit: LineEdit = spin_box.get_line_edit()
	if line_edit != null:
		_style_line_input(line_edit)
		line_edit.placeholder_text = "Quantity"


func _refresh_submit_order_button_style() -> void:
	if active_order_side == "sell":
		_style_button(submit_order_button, COLOR_ORDER_SELL, COLOR_ORDER_SELL_BORDER, COLOR_TEXT, 0)
	else:
		_style_button(submit_order_button, COLOR_ORDER_BUY, COLOR_ORDER_BUY_BORDER, COLOR_TEXT, 0)


func _style_stock_list_row_button(button: Button, is_selected: bool) -> void:
	var fill_color: Color = COLOR_NAV_ACTIVE_FILL if is_selected else Color(0.0823529, 0.117647, 0.156863, 0.98)
	var border_color: Color = COLOR_NAV_ACTIVE_BORDER if is_selected else COLOR_BORDER
	_style_button(button, fill_color, border_color, COLOR_TEXT, 0)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT


func _style_light_item_list(item_list: ItemList) -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.980392, 0.976471, 0.921569, 1)
	panel_style.border_color = Color(0.572549, 0.482353, 0.309804, 0.8)
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 0
	panel_style.corner_radius_bottom_right = 0
	panel_style.corner_radius_bottom_left = 0

	var cursor_style: StyleBoxFlat = StyleBoxFlat.new()
	cursor_style.bg_color = Color(0.835294, 0.764706, 0.529412, 0.52)
	cursor_style.border_color = Color(0.52549, 0.396078, 0.160784, 1)
	cursor_style.set_border_width_all(1)
	cursor_style.corner_radius_top_left = 0
	cursor_style.corner_radius_top_right = 0
	cursor_style.corner_radius_bottom_right = 0
	cursor_style.corner_radius_bottom_left = 0

	item_list.add_theme_stylebox_override("panel", panel_style)
	item_list.add_theme_stylebox_override("panel_focus", panel_style)
	item_list.add_theme_stylebox_override("cursor", cursor_style)
	item_list.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	item_list.add_theme_color_override("font_selected_color", COLOR_WINDOW_TEXT)


func _style_item_list(item_list: ItemList, panel_radius: int = 8, cursor_radius: int = 6) -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0588235, 0.0823529, 0.109804, 0.98)
	panel_style.border_color = COLOR_BORDER
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = panel_radius
	panel_style.corner_radius_top_right = panel_radius
	panel_style.corner_radius_bottom_right = panel_radius
	panel_style.corner_radius_bottom_left = panel_radius

	var cursor_style: StyleBoxFlat = StyleBoxFlat.new()
	cursor_style.bg_color = Color(0.239216, 0.407843, 0.572549, 0.7)
	cursor_style.border_color = COLOR_ACCENT
	cursor_style.set_border_width_all(1)
	cursor_style.corner_radius_top_left = cursor_radius
	cursor_style.corner_radius_top_right = cursor_radius
	cursor_style.corner_radius_bottom_right = cursor_radius
	cursor_style.corner_radius_bottom_left = cursor_radius

	item_list.add_theme_stylebox_override("panel", panel_style)
	item_list.add_theme_stylebox_override("panel_focus", panel_style)
	item_list.add_theme_stylebox_override("cursor", cursor_style)
	item_list.add_theme_stylebox_override("cursor_unfocused", cursor_style)
	item_list.add_theme_color_override("font_color", COLOR_TEXT)
	item_list.add_theme_color_override("font_selected_color", COLOR_TEXT)
	item_list.add_theme_color_override("guide_color", Color(0, 0, 0, 0))
	item_list.add_theme_constant_override("h_separation", 6)
	item_list.add_theme_constant_override("v_separation", 6)


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


func _format_financial_history_summary(financial_history: Array, financials: Dictionary) -> String:
	if financial_history.is_empty():
		return "Generated history unavailable for this run."

	var first_year: Dictionary = financial_history[0]
	var last_year: Dictionary = financial_history[financial_history.size() - 1]
	var start_year: int = int(first_year.get("year", financials.get("history_start_year", 0)))
	var end_year: int = int(last_year.get("year", financials.get("history_end_year", start_year)))
	return "Generated %d-%d history  |  Rev CAGR %s  |  Earn CAGR %s  |  Implied price %s -> %s" % [
		start_year,
		end_year,
		_format_signed_percent_value(float(financials.get("revenue_cagr_10y", 0.0))),
		_format_signed_percent_value(float(financials.get("earnings_cagr_10y", 0.0))),
		_format_last_price(float(first_year.get("implied_share_price", 0.0))),
		_format_last_price(float(last_year.get("implied_share_price", 0.0)))
	]


func _refresh_financial_history_header() -> void:
	if financial_history_header_row == null:
		return
	if financial_history_header_row.get_child_count() > 0:
		return

	financial_history_header_row.add_child(_build_table_cell(
		"Year",
		FINANCIAL_HISTORY_YEAR_WIDTH,
		COLOR_WARNING
	))
	financial_history_header_row.add_child(_build_table_cell(
		"Revenue",
		FINANCIAL_HISTORY_REVENUE_WIDTH,
		COLOR_WARNING,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	financial_history_header_row.add_child(_build_table_cell(
		"NI",
		FINANCIAL_HISTORY_NET_INCOME_WIDTH,
		COLOR_WARNING,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	financial_history_header_row.add_child(_build_table_cell(
		"Margin",
		FINANCIAL_HISTORY_MARGIN_WIDTH,
		COLOR_WARNING,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	financial_history_header_row.add_child(_build_table_cell(
		"ROE",
		FINANCIAL_HISTORY_ROE_WIDTH,
		COLOR_WARNING,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	financial_history_header_row.add_child(_build_table_cell(
		"D/E",
		FINANCIAL_HISTORY_DEBT_WIDTH,
		COLOR_WARNING,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	financial_history_header_row.add_child(_build_table_cell(
		"Price",
		FINANCIAL_HISTORY_PRICE_WIDTH,
		COLOR_WARNING,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))


func _refresh_financial_history_table(financial_history: Array, _financials: Dictionary) -> void:
	if financial_history_rows_vbox == null or financial_history_empty_label == null:
		return

	_clear_dynamic_rows(financial_history_rows_vbox, financial_history_empty_label)
	financial_history_empty_label.visible = financial_history.is_empty()
	if financial_history.is_empty():
		financial_history_empty_label.text = "Generated history unavailable."
		return

	for history_index in range(financial_history.size() - 1, -1, -1):
		var history_entry: Dictionary = financial_history[history_index]
		financial_history_rows_vbox.add_child(_build_financial_history_row(history_entry))


func _build_financial_history_row(history_entry: Dictionary) -> Control:
	var row_wrap: VBoxContainer = VBoxContainer.new()
	row_wrap.add_theme_constant_override("separation", 4)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row_wrap.add_child(row)

	row.add_child(_build_table_cell(
		str(int(history_entry.get("year", 0))),
		FINANCIAL_HISTORY_YEAR_WIDTH,
		COLOR_TEXT
	))
	row.add_child(_build_table_cell(
		_format_compact_currency(float(history_entry.get("revenue", 0.0))),
		FINANCIAL_HISTORY_REVENUE_WIDTH,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_compact_currency(float(history_entry.get("net_income", 0.0))),
		FINANCIAL_HISTORY_NET_INCOME_WIDTH,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_percent_value(float(history_entry.get("net_profit_margin", 0.0))),
		FINANCIAL_HISTORY_MARGIN_WIDTH,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_percent_value(float(history_entry.get("roe", 0.0))),
		FINANCIAL_HISTORY_ROE_WIDTH,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_multiple(float(history_entry.get("debt_to_equity", 0.0))),
		FINANCIAL_HISTORY_DEBT_WIDTH,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_last_price(float(history_entry.get("implied_share_price", 0.0))),
		FINANCIAL_HISTORY_PRICE_WIDTH,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))

	var separator: HSeparator = HSeparator.new()
	row_wrap.add_child(separator)
	return row_wrap


func _refresh_broker_header() -> void:
	if broker_header_row == null:
		return

	for child in broker_header_row.get_children():
		broker_header_row.remove_child(child)
		child.queue_free()

	if broker_net_mode:
		broker_header_row.add_child(_build_table_cell("Net Buy", BROKER_CODE_WIDTH, COLOR_POSITIVE))
		broker_header_row.add_child(_build_table_cell("N.Val", BROKER_VALUE_WIDTH, COLOR_POSITIVE, false, HORIZONTAL_ALIGNMENT_RIGHT))
		broker_header_row.add_child(_build_table_cell("N.Lot", BROKER_LOT_WIDTH, COLOR_POSITIVE, false, HORIZONTAL_ALIGNMENT_RIGHT))
		broker_header_row.add_child(_build_table_cell("N.Avg", BROKER_AVERAGE_WIDTH, COLOR_POSITIVE, false, HORIZONTAL_ALIGNMENT_RIGHT))
		broker_header_row.add_child(_build_table_cell("Net Sell", BROKER_CODE_WIDTH, COLOR_NEGATIVE))
		broker_header_row.add_child(_build_table_cell("N.Val", BROKER_VALUE_WIDTH, COLOR_NEGATIVE, false, HORIZONTAL_ALIGNMENT_RIGHT))
		broker_header_row.add_child(_build_table_cell("N.Lot", BROKER_LOT_WIDTH, COLOR_NEGATIVE, false, HORIZONTAL_ALIGNMENT_RIGHT))
		broker_header_row.add_child(_build_table_cell("N.Avg", BROKER_AVERAGE_WIDTH, COLOR_NEGATIVE, false, HORIZONTAL_ALIGNMENT_RIGHT))
	else:
		broker_header_row.add_child(_build_table_cell("Buy", BROKER_CODE_WIDTH, COLOR_POSITIVE))
		broker_header_row.add_child(_build_table_cell("B.Val", BROKER_VALUE_WIDTH, COLOR_POSITIVE, false, HORIZONTAL_ALIGNMENT_RIGHT))
		broker_header_row.add_child(_build_table_cell("B.Lot", BROKER_LOT_WIDTH, COLOR_POSITIVE, false, HORIZONTAL_ALIGNMENT_RIGHT))
		broker_header_row.add_child(_build_table_cell("B.Avg", BROKER_AVERAGE_WIDTH, COLOR_POSITIVE, false, HORIZONTAL_ALIGNMENT_RIGHT))
		broker_header_row.add_child(_build_table_cell("Sell", BROKER_CODE_WIDTH, COLOR_NEGATIVE))
		broker_header_row.add_child(_build_table_cell("S.Val", BROKER_VALUE_WIDTH, COLOR_NEGATIVE, false, HORIZONTAL_ALIGNMENT_RIGHT))
		broker_header_row.add_child(_build_table_cell("S.Lot", BROKER_LOT_WIDTH, COLOR_NEGATIVE, false, HORIZONTAL_ALIGNMENT_RIGHT))
		broker_header_row.add_child(_build_table_cell("S.Avg", BROKER_AVERAGE_WIDTH, COLOR_NEGATIVE, false, HORIZONTAL_ALIGNMENT_RIGHT))


func _refresh_broker_table(broker_flow: Dictionary) -> void:
	if broker_rows_vbox == null or broker_empty_label == null:
		return

	_clear_dynamic_rows(broker_rows_vbox, broker_empty_label)
	var buy_brokers: Array = broker_flow.get("net_buy_brokers", []) if broker_net_mode else broker_flow.get("buy_brokers", [])
	var sell_brokers: Array = broker_flow.get("net_sell_brokers", []) if broker_net_mode else broker_flow.get("sell_brokers", [])
	var row_count: int = max(buy_brokers.size(), sell_brokers.size())
	broker_empty_label.visible = row_count == 0
	if row_count == 0:
		broker_summary_label.text = "Broker tape unavailable."
		broker_meter_label.text = "Broker Action: Neutral"
		broker_meter_bar.value = 50.0
		_style_broker_meter(Color(0.603922, 0.623529, 0.662745, 0.92))
		return

	var dominant_buy_text: String = _broker_side_display_label(
		str(broker_flow.get("dominant_buy_broker_code", "")),
		str(broker_flow.get("dominant_buy_broker_name", "")),
		str(broker_flow.get("dominant_buy_broker_type", ""))
	)
	var dominant_sell_text: String = _broker_side_display_label(
		str(broker_flow.get("dominant_sell_broker_code", "")),
		str(broker_flow.get("dominant_sell_broker_name", "")),
		str(broker_flow.get("dominant_sell_broker_type", ""))
	)
	var action_meter_score: float = float(broker_flow.get("action_meter_score", 0.0))
	var action_meter_label: String = str(broker_flow.get("action_meter_label", "Neutral"))
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))
	var view_label: String = "Net" if broker_net_mode else "Split"
	broker_summary_label.text = "Lead buyer: %s  |  Lead seller: %s  |  Tape: %s  |  View: %s" % [
		dominant_buy_text,
		dominant_sell_text,
		_flow_badge(flow_tag),
		view_label
	]
	broker_meter_label.text = "Broker Action: %s  |  Aggregate flow %s  |  Smart money %s" % [
		action_meter_label,
		_format_change(float(broker_flow.get("net_pressure", 0.0))),
		_format_change(float(broker_flow.get("smart_money_pressure", 0.0)))
	]
	broker_meter_bar.value = clamp((action_meter_score + 1.0) * 50.0, 0.0, 100.0)
	_style_broker_meter(_color_for_flow(flow_tag))

	for row_index in range(row_count):
		var buy_row: Dictionary = buy_brokers[row_index] if row_index < buy_brokers.size() else {}
		var sell_row: Dictionary = sell_brokers[row_index] if row_index < sell_brokers.size() else {}
		broker_rows_vbox.add_child(_build_broker_table_row(buy_row, sell_row))


func _on_broker_net_toggled(toggled_on: bool) -> void:
	broker_net_mode = toggled_on
	_refresh_broker_header()
	if current_trade_snapshot.is_empty():
		_refresh_broker_table({})
	else:
		_refresh_broker_table(current_trade_snapshot.get("broker_flow", {}))


func _build_broker_table_row(buy_row: Dictionary, sell_row: Dictionary) -> Control:
	var row_wrap: VBoxContainer = VBoxContainer.new()
	row_wrap.add_theme_constant_override("separation", 4)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row_wrap.add_child(row)

	row.add_child(_build_table_cell(
		str(buy_row.get("code", "-")),
		BROKER_CODE_WIDTH,
		COLOR_POSITIVE if not buy_row.is_empty() else COLOR_MUTED
	))
	row.add_child(_build_table_cell(
		_format_compact_currency(float(buy_row.get("value", 0.0))) if not buy_row.is_empty() else "-",
		BROKER_VALUE_WIDTH,
		COLOR_POSITIVE if not buy_row.is_empty() else COLOR_MUTED,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_compact_lots(float(buy_row.get("lots", 0.0))) if not buy_row.is_empty() else "-",
		BROKER_LOT_WIDTH,
		COLOR_POSITIVE if not buy_row.is_empty() else COLOR_MUTED,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_last_price(float(buy_row.get("avg_price", 0.0))) if not buy_row.is_empty() else "-",
		BROKER_AVERAGE_WIDTH,
		COLOR_POSITIVE if not buy_row.is_empty() else COLOR_MUTED,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		str(sell_row.get("code", "-")),
		BROKER_CODE_WIDTH,
		COLOR_NEGATIVE if not sell_row.is_empty() else COLOR_MUTED
	))
	row.add_child(_build_table_cell(
		_format_compact_currency(float(sell_row.get("value", 0.0))) if not sell_row.is_empty() else "-",
		BROKER_VALUE_WIDTH,
		COLOR_NEGATIVE if not sell_row.is_empty() else COLOR_MUTED,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_compact_lots(float(sell_row.get("lots", 0.0))) if not sell_row.is_empty() else "-",
		BROKER_LOT_WIDTH,
		COLOR_NEGATIVE if not sell_row.is_empty() else COLOR_MUTED,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_last_price(float(sell_row.get("avg_price", 0.0))) if not sell_row.is_empty() else "-",
		BROKER_AVERAGE_WIDTH,
		COLOR_NEGATIVE if not sell_row.is_empty() else COLOR_MUTED,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))

	var separator: HSeparator = HSeparator.new()
	row_wrap.add_child(separator)
	return row_wrap


func _broker_side_display_label(broker_code: String, broker_name: String, broker_type: String) -> String:
	if broker_code.is_empty():
		return str(broker_type).capitalize() if not broker_type.is_empty() else "Balanced"
	var short_name: String = broker_name
	if short_name.begins_with("PT. "):
		short_name = short_name.trim_prefix("PT. ")
	return "%s (%s)" % [broker_code, short_name if not short_name.is_empty() else broker_type.capitalize()]


func _format_statement_year_label(financial_statement_snapshot: Dictionary) -> String:
	if financial_statement_snapshot.is_empty():
		return "Derived financial statements unavailable."

	var quarterly_statements: Array = financial_statement_snapshot.get("quarterly_statements", [])
	if quarterly_statements.is_empty():
		return "Derived %s statements  |  simplified learning model built from the generated company history." % str(
			financial_statement_snapshot.get("statement_period_label", "latest")
		)

	return "%d derived quarters  |  %s -> %s  |  simplified learning model built from generated company history." % [
		quarterly_statements.size(),
		str(financial_statement_snapshot.get("history_start_period_label", "Q1 2010")),
		str(financial_statement_snapshot.get("history_end_period_label", "Q4 2019"))
	]


func _sync_financial_statement_selection(company_id: String, financial_statement_snapshot: Dictionary) -> void:
	var quarterly_statements: Array = financial_statement_snapshot.get("quarterly_statements", [])
	if company_id != selected_financial_statement_company_id:
		selected_financial_statement_company_id = company_id
		selected_financial_statement_index = quarterly_statements.size() - 1

	if quarterly_statements.is_empty():
		selected_financial_statement_index = -1
		return

	selected_financial_statement_index = clampi(
		selected_financial_statement_index,
		0,
		quarterly_statements.size() - 1
	)


func _shift_financial_statement_selection(offset: int) -> void:
	if selected_company_id.is_empty():
		return

	var financial_statement_snapshot: Dictionary = current_trade_snapshot.get("financial_statement_snapshot", {})
	var quarterly_statements: Array = financial_statement_snapshot.get("quarterly_statements", [])
	if quarterly_statements.is_empty():
		return

	_sync_financial_statement_selection(selected_company_id, financial_statement_snapshot)
	selected_financial_statement_index = clampi(
		selected_financial_statement_index + offset,
		0,
		quarterly_statements.size() - 1
	)
	financials_year_label.text = _format_statement_year_label(financial_statement_snapshot)
	_refresh_statement_sections(financial_statement_snapshot)


func _selected_statement_period(financial_statement_snapshot: Dictionary) -> Dictionary:
	var quarterly_statements: Array = financial_statement_snapshot.get("quarterly_statements", [])
	if quarterly_statements.is_empty():
		return financial_statement_snapshot

	var safe_index: int = quarterly_statements.size() - 1
	if selected_financial_statement_index >= 0:
		safe_index = clampi(selected_financial_statement_index, 0, quarterly_statements.size() - 1)
	return quarterly_statements[safe_index]


func _refresh_statement_navigation(financial_statement_snapshot: Dictionary) -> void:
	if financials_period_label == null or financials_previous_button == null or financials_next_button == null:
		return

	var quarterly_statements: Array = financial_statement_snapshot.get("quarterly_statements", [])
	if quarterly_statements.is_empty():
		financials_period_label.text = "Viewing latest available period."
		financials_previous_button.disabled = true
		financials_next_button.disabled = true
		return

	var selected_period: Dictionary = _selected_statement_period(financial_statement_snapshot)
	var selected_position: int = clampi(selected_financial_statement_index, 0, quarterly_statements.size() - 1)
	financials_period_label.text = "Viewing %s  |  %d / %d" % [
		str(selected_period.get("statement_period_label", "latest")),
		selected_position + 1,
		quarterly_statements.size()
	]
	financials_previous_button.disabled = selected_position <= 0
	financials_next_button.disabled = selected_position >= quarterly_statements.size() - 1


func _refresh_statement_sections(financial_statement_snapshot: Dictionary) -> void:
	_refresh_statement_navigation(financial_statement_snapshot)
	if financial_statement_snapshot.is_empty():
		_refresh_statement_section(income_statement_rows_vbox, income_statement_empty_label, [])
		_refresh_statement_section(balance_sheet_rows_vbox, balance_sheet_empty_label, [])
		_refresh_statement_section(cash_flow_rows_vbox, cash_flow_empty_label, [])
		return

	var selected_period: Dictionary = _selected_statement_period(financial_statement_snapshot)
	_refresh_statement_section(
		income_statement_rows_vbox,
		income_statement_empty_label,
		selected_period.get("income_statement", [])
	)
	_refresh_statement_section(
		balance_sheet_rows_vbox,
		balance_sheet_empty_label,
		selected_period.get("balance_sheet", [])
	)
	_refresh_statement_section(
		cash_flow_rows_vbox,
		cash_flow_empty_label,
		selected_period.get("cash_flow", [])
	)


func _refresh_statement_section(rows_vbox: VBoxContainer, empty_label: Label, lines: Array) -> void:
	if rows_vbox == null or empty_label == null:
		return

	_clear_dynamic_rows(rows_vbox, empty_label)
	empty_label.visible = lines.is_empty()
	if lines.is_empty():
		return

	for line_value in lines:
		var line_item: Dictionary = line_value
		rows_vbox.add_child(_build_statement_row(line_item))


func _build_statement_row(line_item: Dictionary) -> Control:
	var row_wrap: VBoxContainer = VBoxContainer.new()
	row_wrap.add_theme_constant_override("separation", 4)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row_wrap.add_child(row)

	row.add_child(_build_table_cell(
		str(line_item.get("label", "")),
		STATEMENT_LABEL_WIDTH,
		COLOR_TEXT,
		true
	))
	row.add_child(_build_table_cell(
		_format_statement_value(line_item),
		STATEMENT_VALUE_WIDTH,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))

	var separator: HSeparator = HSeparator.new()
	row_wrap.add_child(separator)
	return row_wrap


func _format_statement_value(line_item: Dictionary) -> String:
	var line_format: String = str(line_item.get("format", "currency"))
	var value: float = float(line_item.get("value", 0.0))
	if line_format == "shares":
		return _format_grouped_integer(int(round(value)))
	return _format_compact_currency(value)


func _format_compact_currency(value: float) -> String:
	var absolute_value: float = absf(value)
	if absolute_value >= 1000000000000.0:
		return "Rp %sT" % String.num(value / 1000000000000.0, 2)
	if absolute_value >= 1000000000.0:
		return "Rp %sB" % String.num(value / 1000000000.0, 2)
	if absolute_value >= 1000000.0:
		return "Rp %sM" % String.num(value / 1000000.0, 2)
	return _format_currency(value)


func _format_compact_lots(value: float) -> String:
	var absolute_value: float = absf(value)
	if absolute_value >= 1000000.0:
		return "%sM" % String.num(value / 1000000.0, 1)
	if absolute_value >= 1000.0:
		return "%sK" % String.num(value / 1000.0, 1)
	return String.num(value, 1)


func _format_grouped_integer(value: int) -> String:
	var negative: bool = value < 0
	var digits: String = str(abs(value))
	var groups: Array = []
	while digits.length() > 3:
		groups.push_front(digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	if not digits.is_empty():
		groups.push_front(digits)
	var grouped_value: String = ",".join(groups)
	if grouped_value.is_empty():
		grouped_value = "0"
	return "-%s" % grouped_value if negative else grouped_value


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
