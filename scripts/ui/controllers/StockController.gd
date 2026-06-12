extends RefCounted

const SECTION_ORDER := ["dashboard", "markets", "portfolio", "help"]
const APP_ID_DESKTOP := "desktop"
const APP_ID_STOCK := "stock"
const APP_ID_NEWS := "news"
const APP_ID_SOCIAL := "social"
const APP_ID_NETWORK := "network"
const APP_ID_ACADEMY := "academy"
const APP_ID_UPGRADES := "upgrades"
const APP_ID_THESIS := "thesis"
const APP_ID_LIFE := "life"
const APP_ID_COMPANY := "company"
const STOCK_APP_FONT_SIZE := 14
const DEFAULT_APP_FONT_SIZE := 14
const APP_FONT_CANDIDATE_PATHS := [
	"res://assets/fonts/app_font.ttf",
	"res://assets/fonts/app_font.otf",
	"res://assets/fonts/OpenSans-Regular.ttf"
]
const SIDEBAR_COMPACT_WIDTH := 160.0
const TRADE_LEFT_SECTION_RATIO := 0.72
const TRADE_CENTER_SECTION_RATIO := 2.42
const TRADE_RIGHT_SECTION_RATIO := 1.0
const ORDER_TICKET_TOGGLE_WIDTH := 28.0
const WATCHLIST_MIN_WIDTH_NARROW := 220.0
const WATCHLIST_MIN_WIDTH_WIDE := 260.0
const KEY_STATS_DASHBOARD_DESKTOP_WIDTH := 804.0
const KEY_STATS_DASHBOARD_TWO_COLUMN_WIDTH := 540.0
const STOCK_LIST_ADD_BUTTON_WIDTH := 72.0
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
const COLOR_DESKTOP_CREAM := Color(1.0, 0.976471, 0.929412, 1)
const COLOR_DESKTOP_PANEL := Color(0.945098, 0.909804, 0.803922, 1)
const COLOR_DESKTOP_BROWN := Color(0.509804, 0.231373, 0.0941176, 1)
const COLOR_DESKTOP_OLIVE := Color(0.247059, 0.278431, 0.117647, 1)
const COLOR_DESKTOP_GOLD := Color(0.972549, 0.713726, 0.0627451, 1)
const COLOR_DESKTOP_FRAME := Color(0.729412, 0.694118, 0.603922, 1)
const DESKTOP_REFERENCE_VIEWPORT := Vector2(1920.0, 1080.0)
const DESKTOP_EDGE_CONTENT_MARGIN := 28.0
const MAC_FULLSCREEN_SAFE_MARGIN_X := 36.0
const MAC_FULLSCREEN_SAFE_MARGIN_TOP := 20.0
const MAC_FULLSCREEN_SAFE_MARGIN_BOTTOM := 18.0
const DESKTOP_ICON_PATHS := {
	"stock": {
		"shortcut": "res://assets/ui/desktop/stockbot_shortcut.svg",
		"nav": "res://assets/ui/desktop/stockbot_nav.svg"
	},
	"news": {
		"shortcut": "res://assets/ui/desktop/news_shortcut.svg",
		"nav": "res://assets/ui/desktop/news_nav.svg"
	},
	"social": {
		"shortcut": "res://assets/ui/desktop/twooter_shortcut.svg",
		"nav": "res://assets/ui/desktop/twooter_nav.svg"
	},
	"academy": {
		"shortcut": "res://assets/ui/desktop/academy_shortcut.svg",
		"nav": "res://assets/ui/desktop/academy_nav.svg"
	},
	"network": {
		"shortcut": "res://assets/ui/desktop/network_shortcut.svg",
		"nav": "res://assets/ui/desktop/network_nav.svg"
	},
	"upgrades": {
		"shortcut": "res://assets/ui/desktop/shop_shortcut.svg",
		"nav": "res://assets/ui/desktop/shop_nav.svg"
	},
	"thesis": {
		"shortcut": "res://assets/ui/desktop/thesis_shortcut.svg",
		"nav": "res://assets/ui/desktop/thesis_nav.svg"
	},
	"life": {
		"shortcut": "res://assets/ui/desktop/life_shortcut.svg",
		"nav": "res://assets/ui/desktop/life_nav.svg"
	},
	"company": {
		"shortcut": "res://assets/ui/desktop/thesis_shortcut.svg",
		"nav": "res://assets/ui/desktop/thesis_nav.svg"
	},
	"exit": {
		"shortcut": "res://assets/ui/desktop/exit_shortcut.svg",
		"nav": "res://assets/ui/desktop/exit_nav.svg"
	},
	"settings": {
		"shortcut": "res://assets/ui/desktop/settings_shortcut.svg",
		"nav": "res://assets/ui/desktop/settings_nav.svg"
	},
	"date": "res://assets/ui/desktop/date_icon.svg",
	"cash": "res://assets/ui/desktop/cash_icon.svg",
	"advance": "res://assets/ui/desktop/advance_icon.svg"
}
const STOCKBOT_ICON_PATHS := {
	"calendar": "res://assets/icons/calendar-event.svg",
	"chart": "res://assets/icons/chart-candle.svg",
	"check": "res://assets/icons/check.svg",
	"chevron_down": "res://assets/icons/chevron-down.svg",
	"chevron_up": "res://assets/icons/chevron-up.svg",
	"dots": "res://assets/icons/dots.svg",
	"eraser": "res://assets/icons/eraser.svg",
	"line": "res://assets/icons/line.svg",
	"line_dashed": "res://assets/icons/line-dashed.svg",
	"lock": "res://assets/icons/lock.svg",
	"minus": "res://assets/icons/minus.svg",
	"pencil": "res://assets/icons/pencil.svg",
	"plus": "res://assets/icons/plus.svg",
	"pointer": "res://assets/icons/pointer.svg",
	"search": "res://assets/icons/search.svg",
	"shopping_cart": "res://assets/icons/shopping-cart.svg",
	"trash": "res://assets/icons/trash.svg",
	"trending_up": "res://assets/icons/trending-up.svg",
	"x": "res://assets/icons/x.svg"
}
const COLOR_STOCKBOT_BASE := Color(0.0431373, 0.0745098, 0.113725, 0.99)
const COLOR_STOCKBOT_SURFACE := Color(0.0745098, 0.113725, 0.168627, 0.99)
const COLOR_STOCKBOT_SURFACE_ALT := Color(0.101961, 0.145098, 0.219608, 0.99)
const COLOR_STOCKBOT_EDGE := Color(0.164706, 0.219608, 0.317647, 0.95)
const COLOR_STOCKBOT_EDGE_STRONG := Color(0.239216, 0.317647, 0.439216, 1)
const COLOR_STOCKBOT_TEXT := Color(0.901961, 0.929412, 0.968627, 1)
const COLOR_STOCKBOT_MUTED := Color(0.545098, 0.611765, 0.701961, 1)
const COLOR_STOCKBOT_FAINT := Color(0.360784, 0.431373, 0.537255, 1)
const COLOR_STOCKBOT_BLUE := Color(0.113725, 0.631373, 0.94902, 1)
const COLOR_STOCKBOT_BLUE_TINT := Color(0.0901961, 0.196078, 0.286275, 0.95)
const COLOR_STOCKBOT_BLUE_EDGE := Color(0.121569, 0.254902, 0.388235, 1)
const COLOR_STOCKBOT_BULL := Color(0.0901961, 0.768627, 0.419608, 1)
const COLOR_STOCKBOT_BULL_TINT := Color(0.054902, 0.164706, 0.105882, 0.95)
const COLOR_STOCKBOT_BULL_EDGE := Color(0.0862745, 0.262745, 0.164706, 1)
const COLOR_STOCKBOT_BEAR := Color(0.94902, 0.235294, 0.352941, 1)
const COLOR_STOCKBOT_BEAR_TINT := Color(0.172549, 0.0588235, 0.0901961, 0.95)
const COLOR_STOCKBOT_BEAR_EDGE := Color(0.352941, 0.121569, 0.164706, 1)
const COLOR_STOCKBOT_AMBER := Color(0.941176, 0.717647, 0.239216, 1)
const COLOR_STOCK_WINDOW_BG := Color(0.0901961, 0.129412, 0.164706, 0.98)
const COLOR_ORDER_PANEL_BG := Color(0.0901961, 0.129412, 0.164706, 0.98)
const COLOR_ORDER_CARD_BG := Color(0.109804, 0.14902, 0.184314, 0.98)
const COLOR_ORDER_INPUT_BG := Color(0.0901961, 0.129412, 0.164706, 0.98)
const COLOR_ORDER_BUY := Color(0.117647, 0.32549, 0.239216, 1)
const COLOR_ORDER_BUY_BORDER := Color(0.309804, 0.631373, 0.486275, 1)
const COLOR_ORDER_SELL := Color(0.27451, 0.164706, 0.180392, 1)
const COLOR_ORDER_SELL_BORDER := Color(0.690196, 0.34902, 0.372549, 1)
const COLOR_ORDER_METRIC_LABEL := Color(0.792157, 0.866667, 0.929412, 1)
const COLOR_WINDOW_BG := Color(0.909804, 0.909804, 0.803922, 1)
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
const COLOR_ACADEMY_CREAM := Color(0.988235, 0.960784, 0.854902, 1)
const COLOR_ACADEMY_PANEL := Color(0.972549, 0.94902, 0.847059, 1)
const COLOR_ACADEMY_RAIL := Color(0.917647, 0.878431, 0.721569, 1)
const COLOR_ACADEMY_BROWN := Color(0.509804, 0.231373, 0.0941176, 1)
const COLOR_ACADEMY_BORDER := Color(0.52549, 0.396078, 0.160784, 1)
const COLOR_ACADEMY_GREEN := Color(0.811765, 0.886275, 0.529412, 1)
const SHOW_ACADEMY_IMAGE_PLACEHOLDERS := false
const COLOR_NAV_FILL := Color(0.126, 0.188, 0.251, 1)
const COLOR_NAV_ACTIVE_FILL := Color(0.219608, 0.439216, 0.65098, 1)
const COLOR_NAV_ACTIVE_BORDER := Color(0.690196, 0.87451, 1, 1)
const TOAST_DURATION_SECONDS := 5.0
const UI_ANIMATIONS_ENABLED := true
const UI_ADVANCE_BUTTON_PRESS_SECONDS := 0.09
const UI_ADVANCE_PHASE_PULSE_SECONDS := 0.12
const UI_DAILY_RECAP_REVEAL_SECONDS := 0.22
const UI_DESKTOP_WINDOW_OPEN_SECONDS := 0.14
const UI_DESKTOP_WINDOW_FOCUS_SECONDS := 0.10
const UI_DAILY_RECAP_SCRIM_ALPHA := 0.18
const UI_MACRO_EVENT_TYPE_SECONDS_PER_CHAR := 0.032
const UI_MACRO_EVENT_TYPE_MIN_SECONDS := 0.18
const UI_MACRO_EVENT_TYPE_MAX_SECONDS := 1.65
const GUIDE_CARD_SIZE := Vector2(520.0, 0.0)
const GUIDE_CARD_MARGIN := 18.0
const GUIDE_TARGET_PADDING := 10.0
const FTUE_CARD_SIZE := GUIDE_CARD_SIZE
const FTUE_CARD_MARGIN := GUIDE_CARD_MARGIN
const FTUE_TARGET_PADDING := GUIDE_TARGET_PADDING
const FIRST_HOUR_GUIDE_CARD_SIZE := Vector2(360.0, 0.0)
const FIRST_HOUR_GUIDE_CARD_MARGIN := 18.0
const FIRST_HOUR_GUIDE_TARGET_PADDING := 6.0
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
const BROKER_SIDE_DIVIDER_WIDTH := 28.0
const BROKER_CODE_RATIO := 0.72
const BROKER_VALUE_RATIO := 1.52
const BROKER_LOT_RATIO := 1.0
const BROKER_AVERAGE_RATIO := 1.1
const STATEMENT_LABEL_WIDTH := 286.0
const STATEMENT_VALUE_WIDTH := 148.0
const APP_WINDOW_INSET := 20
const APP_WINDOW_CONTENT_MARGIN := 20
const APP_WINDOW_CONTENT_TOP_MARGIN := 64
const APP_WINDOW_CONTENT_BOTTOM_MARGIN := 20
const APP_WINDOW_FRAME_BOTTOM_MARGIN := 20
const APP_WINDOW_INNER_PADDING := 0
const STOCKBOT_WINDOW_CONTENT_MARGIN := 8
const STOCKBOT_WINDOW_CONTENT_BOTTOM_MARGIN := 8
const DESKTOP_WINDOW_TITLE_BAR_HEIGHT := 40.0
const DESKTOP_WINDOW_MIN_WIDTH := 360.0
const DESKTOP_WINDOW_MIN_HEIGHT := 260.0
const SOCIAL_WINDOW_MAX_WIDTH := 1220.0
const SOCIAL_WINDOW_MAX_HEIGHT := 820.0
const SOCIAL_WINDOW_MIN_HEIGHT := 560.0
const LIFE_WINDOW_MAX_WIDTH := 1180.0
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
const COLOR_TWOOTER_PAGE := Color(0.0, 0.0, 0.0, 1)
const COLOR_TWOOTER_SURFACE := Color(0.086275, 0.094118, 0.105882, 1)
const COLOR_TWOOTER_CARD := Color(0.0, 0.0, 0.0, 1)
const COLOR_TWOOTER_BLUE := Color(0.113725, 0.631373, 0.94902, 1)
const COLOR_TWOOTER_BLUE_DARK := Color(0.0, 0.596078, 1.0, 1)
const COLOR_TWOOTER_BLUE_TINT := Color(0.12549, 0.14902, 0.176471, 1)
const COLOR_TWOOTER_BLUE_EDGE := Color(0.156863, 0.180392, 0.207843, 1)
const COLOR_TWOOTER_TEXT := Color(0.937255, 0.94902, 0.960784, 1)
const COLOR_TWOOTER_MUTED := Color(0.513725, 0.568627, 0.627451, 1)
const COLOR_TWOOTER_FAINT := Color(0.372549, 0.415686, 0.470588, 1)
const COLOR_TWOOTER_BORDER := Color(0.176471, 0.196078, 0.223529, 1)
const COLOR_TWOOTER_LIVE := Color(0.0, 0.792157, 0.533333, 1)
const DASHBOARD_MOVER_LIMIT := 15
const DASHBOARD_WEEKDAY_NAMES := ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
const DASHBOARD_MONTH_NAMES := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const DASHBOARD_CALENDAR_CELL_HEIGHT := 46.0
const DASHBOARD_CALENDAR_WEEKDAY_HEIGHT := 24.0
const DASHBOARD_SECTION_TITLE_FONT_SIZE := 16
const DASHBOARD_SECTION_TITLE_FONT_PATH := "res://assets/fonts/OpenSans-SemiBold.ttf"
const DASHBOARD_INDEX_SPARKLINE_POINT_LIMIT := 40
const CONSOLE_TOGGLE_KEY_CODE := 96
const PERF_LOG_PREFIX := "[perf][ui]"
const KEY_STATS_METRIC_NET_INCOME := "net_income"
const KEY_STATS_METRIC_EPS := "eps"
const KEY_STATS_METRIC_REVENUE := "revenue"
const KEY_STATS_YEAR_COLUMN_LIMIT := 3
const KEY_STATS_ROW_VALUE_WIDTH := 116.0
const KEY_STATS_METRIC_LABEL_WIDTH := 78.0
const KEY_STATS_METRIC_VALUE_WIDTH := 74.0
const RUPSLB_MEETING_OVERLAY_SCRIPT = preload("res://scripts/ui/widgets/RupslbMeetingOverlay.gd")
const DASHBOARD_SPARKLINE_SCRIPT = preload("res://scripts/ui/widgets/DashboardSparklineCanvas.gd")
const THESIS_BOARD_WIDGET_SCRIPT = preload("res://scripts/ui/widgets/ThesisBoardWidget.gd")

var _root = null
var selected_company_id: String = ""
var displayed_company_ids: Array = []
var watchlist_picker_company_ids: Array = []
var selected_lots: int = 1
var selected_financial_statement_index: int = -1
var selected_financial_statement_company_id: String = ""
var selected_key_stats_metric: String = KEY_STATS_METRIC_NET_INCOME
var key_stats_capture_menu: PopupMenu = null
var broker_capture_menu: PopupMenu = null
var profile_capture_menu: PopupMenu = null
var financial_statement_capture_menu: PopupMenu = null
var corporate_action_filter_id: String = "all"
var corporate_action_capture_menu: PopupMenu = null
var trade_quote_capture_menu: PopupMenu = null
var pending_capture_payloads: Dictionary = {}
var current_trade_snapshot: Dictionary = {}
var all_stock_rows_dirty: bool = true
var portfolio_stock_rows_dirty: bool = true
var order_market_value_labels: Dictionary = {}
var order_market_name_labels: Dictionary = {}
var pending_watchlist_selected_company_id: String = ""
var pending_watchlist_target_tab: int = -1
var suppress_stock_list_tab_refresh: bool = false
var active_order_side: String = "buy"
var order_ticket_collapsed: bool = false
var broker_net_mode: bool = false
var selected_broker_range_id: String = "1d"
var broker_range_buttons: Dictionary = {}
var broker_range_row: HBoxContainer = null
var stockbot_icon_cache: Dictionary = {}
var trade_workspace_detail_cache_key: String = ""
var trade_workspace_profile_cache_key: String = ""
var trade_workspace_financial_history_cache_key: String = ""
var trade_workspace_key_stats_cache_key: String = ""
var trade_workspace_broker_cache_key: String = ""
var trade_workspace_corporate_action_cache_key: String = ""
var trade_workspace_statement_cache_key: String = ""
var status_message: String = "Ready."
var stock_window_container: PanelContainer = null
var app_content_margin: MarginContainer = null
var top_bar_panel: PanelContainer = null
var sidebar_panel: PanelContainer = null
var content_tabs: TabContainer = null
var top_section_label: Label = null
var top_market_label: Label = null
var top_equity_label: Label = null
var top_cash_label: Label = null
var trade_split: HBoxContainer = null
var main_trade_split: HBoxContainer = null
var watchlist_panel: PanelContainer = null
var work_area_panel: PanelContainer = null
var order_ticket_toggle_button: Button = null
var action_panel: PanelContainer = null
var stock_list_tabs: TabContainer = null
var add_watchlist_button: Button = null
var remove_watchlist_button: Button = null
var watchlist_empty_label: Label = null
var company_list: ItemList = null
var all_stocks_search_input: LineEdit = null
var all_stocks_scroll: ScrollContainer = null
var all_stocks_rows: VBoxContainer = null
var portfolio_stocks_scroll: ScrollContainer = null
var portfolio_stocks_rows: VBoxContainer = null
var portfolio_stocks_empty_label: Label = null
var trade_workspace_widget = null
var work_tabs: TabContainer = null
var key_stats_panel: PanelContainer = null
var key_stats_financial_label: Label = null
var financial_history_summary_label: Label = null
var financial_history_header_row: HBoxContainer = null
var financial_history_rows_vbox: VBoxContainer = null
var financial_history_empty_label: Label = null
var financials_panel: PanelContainer = null
var financials_year_label: Label = null
var financials_previous_button: Button = null
var financials_period_label: Label = null
var financials_next_button: Button = null
var income_statement_rows_vbox: VBoxContainer = null
var income_statement_empty_label: Label = null
var balance_sheet_rows_vbox: VBoxContainer = null
var balance_sheet_empty_label: Label = null
var cash_flow_rows_vbox: VBoxContainer = null
var cash_flow_empty_label: Label = null
var broker_panel: PanelContainer = null
var broker_summary_label: Label = null
var broker_meter_label: Label = null
var broker_meter_bar: ProgressBar = null
var broker_scale_left_label: Label = null
var broker_scale_mid_label: Label = null
var broker_scale_right_label: Label = null
var broker_net_toggle: CheckButton = null
var broker_header_row: HBoxContainer = null
var broker_rows_vbox: VBoxContainer = null
var broker_empty_label: Label = null
var analyzer_panel: PanelContainer = null
var analyzer_setup_label: Label = null
var analyzer_support_label: Label = null
var analyzer_risk_label: Label = null
var analyzer_event_label: Label = null
var analyzer_history_label: Label = null
var corporate_actions_panel: PanelContainer = null
var corporate_actions_filter_option: OptionButton = null
var corporate_actions_summary_label: Label = null
var corporate_actions_rows_vbox: VBoxContainer = null
var corporate_actions_empty_label: Label = null
var profile_panel: PanelContainer = null
var profile_company_name_label: Label = null
var profile_sector_label: Label = null
var profile_price_label: Label = null
var profile_factor_label: Label = null
var profile_management_label: Label = null
var profile_shareholders_label: Label = null
var profile_tags_label: Label = null
var profile_description_label: Label = null
var profile_network_hint_label: Label = null
var profile_meet_contact_button: Button = null
var order_company_name_label: Label = null
var selection_label: Label = null
var order_price_value_label: Label = null
var order_price_change_label: Label = null
var order_position_label: Label = null
var order_card_panel: PanelContainer = null
var order_title_label: Label = null
var lot_spin_box: SpinBox = null
var order_price_line_edit: LineEdit = null
var estimated_total_value_label: Label = null
var buy_button: Button = null
var sell_button: Button = null
var submit_order_button: Button = null
var debug_overlay: Control = null
var watchlist_picker_dialog: ConfirmationDialog = null
var watchlist_picker_list: ItemList = null
var key_stats_dashboard_grid: GridContainer = null
var key_stats_dashboard_columns: Dictionary = {}
var key_stats_card_rows: Dictionary = {}
var key_stats_metric_buttons: Dictionary = {}
var key_stats_metric_table_rows: VBoxContainer = null
var key_stats_metric_footer_rows: VBoxContainer = null
var profile_background_card: PanelContainer = null
var profile_background_title_label: Label = null
var profile_background_meta_label: Label = null
var profile_background_body_label: Label = null
var profile_tags_flow: HFlowContainer = null
var profile_shareholder_card: PanelContainer = null
var profile_shareholder_title_label: Label = null
var profile_shareholder_updated_label: Label = null
var profile_shareholder_rows: VBoxContainer = null
var profile_management_card: PanelContainer = null
var profile_management_title_label: Label = null
var profile_management_rows: VBoxContainer = null
var contact_intel_panel: PanelContainer = null
var contact_intel_option: OptionButton = null
var contact_intel_button: Button = null
var contact_intel_status_label: Label = null

func setup(root) -> void:
	_root = root
	_sync_dynamic_refs_from_root()
	_sync_state_from_root()
	_sync_root_refs()

func _apply_trade_layout_ratios() -> void:
	trade_split.add_theme_constant_override("separation", 4)
	main_trade_split.add_theme_constant_override("separation", 4)
	watchlist_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	watchlist_panel.size_flags_stretch_ratio = TRADE_LEFT_SECTION_RATIO
	main_trade_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_trade_split.size_flags_stretch_ratio = TRADE_CENTER_SECTION_RATIO + TRADE_RIGHT_SECTION_RATIO
	work_area_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	order_ticket_toggle_button.custom_minimum_size = Vector2(ORDER_TICKET_TOGGLE_WIDTH, 0)
	order_ticket_toggle_button.visible = true
	if order_ticket_collapsed:
		work_area_panel.size_flags_stretch_ratio = TRADE_CENTER_SECTION_RATIO + TRADE_RIGHT_SECTION_RATIO
		action_panel.visible = false
		action_panel.size_flags_horizontal = Control.SIZE_FILL
		action_panel.size_flags_stretch_ratio = 0.0
	else:
		work_area_panel.size_flags_stretch_ratio = TRADE_CENTER_SECTION_RATIO
		action_panel.visible = true
		action_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_panel.size_flags_stretch_ratio = TRADE_RIGHT_SECTION_RATIO
	_refresh_order_ticket_toggle_state()

func _remove_financial_and_broker_helper_text() -> void:
	if financials_year_label != null:
		financials_year_label.text = ""
		financials_year_label.visible = false
	if broker_summary_label != null:
		broker_summary_label.text = ""
		broker_summary_label.visible = false
	if broker_meter_label != null:
		broker_meter_label.text = ""
		broker_meter_label.visible = false

func _ensure_broker_range_controls() -> void:
	if broker_net_toggle == null:
		return
	var controls_row: HBoxContainer = broker_net_toggle.get_parent() as HBoxContainer
	if controls_row == null:
		return
	broker_range_row = controls_row.get_node_or_null("BrokerRangeRow") as HBoxContainer
	if broker_range_row == null:
		broker_range_row = HBoxContainer.new()
		broker_range_row.name = "BrokerRangeRow"
		broker_range_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		broker_range_row.add_theme_constant_override("separation", 4)
		controls_row.add_child(broker_range_row)
		controls_row.move_child(broker_range_row, 0)
	broker_range_buttons.clear()
	for range_value in GameManager.get_broker_range_catalog():
		if typeof(range_value) != TYPE_DICTIONARY:
			continue
		var range_definition: Dictionary = range_value
		var range_id: String = str(range_definition.get("id", ""))
		if range_id.is_empty():
			continue
		var button_name: String = _broker_range_button_name(range_id)
		var button: Button = broker_range_row.get_node_or_null(button_name) as Button
		if button == null:
			button = Button.new()
			button.name = button_name
			button.text = str(range_definition.get("label", range_id.to_upper()))
			button.toggle_mode = true
			button.custom_minimum_size = Vector2(40, 28)
			button.focus_mode = Control.FOCUS_NONE
			button.tooltip_text = "Show %s broker flow." % str(range_definition.get("label", range_id.to_upper()))
			button.pressed.connect(_root._on_broker_range_pressed.bind(range_id))
			broker_range_row.add_child(button)
		broker_range_buttons[range_id] = button
	_refresh_broker_range_buttons()

func _broker_range_button_name(range_id: String) -> String:
	return "BrokerRange%sButton" % range_id.to_upper()

func _refresh_broker_range_buttons() -> void:
	for range_id_value in broker_range_buttons.keys():
		var range_id: String = str(range_id_value)
		var button: Button = broker_range_buttons.get(range_id, null) as Button
		if button == null:
			continue
		var is_selected: bool = range_id == selected_broker_range_id
		button.set_pressed_no_signal(is_selected)
		UiTheme.style_tab_button(button, "terminal_tab", is_selected, {"radius": 0})
		_apply_font_override_to_control(button, 12, _get_app_font())

func _on_broker_range_pressed(range_id: String) -> void:
	if range_id.is_empty():
		return
	selected_broker_range_id = range_id
	_refresh_broker_range_buttons()
	if current_trade_snapshot.is_empty():
		_refresh_broker_table({})
		trade_workspace_broker_cache_key = ""
		return
	var broker_flow: Dictionary = _broker_range_flow_for_snapshot(current_trade_snapshot)
	_refresh_broker_table(broker_flow)
	trade_workspace_broker_cache_key = _trade_workspace_broker_snapshot_key(current_trade_snapshot)

func _ensure_key_stats_dashboard_ui() -> void:
	if key_stats_dashboard_grid != null:
		return
	if key_stats_panel == null:
		return
	var key_stats_vbox: VBoxContainer = key_stats_panel.get_node_or_null("KeyStatsMargin/KeyStatsVBox") as VBoxContainer
	if key_stats_vbox == null:
		return
	var key_stats_scroll: ScrollContainer = key_stats_panel.get_parent() as ScrollContainer
	if key_stats_scroll != null:
		key_stats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var old_title: Control = key_stats_vbox.get_node_or_null("KeyStatsTitle") as Control
	if old_title != null:
		old_title.visible = false
	key_stats_financial_label.visible = false
	financial_history_summary_label.visible = false
	var financial_history_table: Control = key_stats_vbox.get_node_or_null("FinancialHistoryTable") as Control
	if financial_history_table != null:
		financial_history_table.visible = false

	key_stats_dashboard_grid = GridContainer.new()
	key_stats_dashboard_grid.name = "KeyStatsDashboardGrid"
	key_stats_dashboard_grid.columns = 3
	key_stats_dashboard_grid.custom_minimum_size = Vector2(KEY_STATS_DASHBOARD_DESKTOP_WIDTH, 0)
	key_stats_dashboard_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_stats_dashboard_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	key_stats_dashboard_grid.add_theme_constant_override("h_separation", 12)
	key_stats_dashboard_grid.add_theme_constant_override("v_separation", 12)
	key_stats_vbox.add_child(key_stats_dashboard_grid)

	var left_column: VBoxContainer = _build_key_stats_dashboard_column("KeyStatsLeftColumn")
	var center_column: VBoxContainer = _build_key_stats_dashboard_column("KeyStatsCenterColumn")
	var right_column: VBoxContainer = _build_key_stats_dashboard_column("KeyStatsRightColumn")
	key_stats_dashboard_columns = {
		"left": left_column,
		"center": center_column,
		"right": right_column
	}

	_build_key_stats_card("current_valuation", "Current Valuation", "KeyStatsCurrentValuationCard", "KeyStatsCurrentValuationRows", left_column)
	_build_key_stats_card("per_share", "Per Share", "KeyStatsPerShareCard", "KeyStatsPerShareRows", left_column)
	_build_key_stats_card("dividend", "Dividend", "KeyStatsDividendCard", "KeyStatsDividendRows", left_column)
	_build_key_stats_metric_card(center_column)
	_build_key_stats_card("profitability", "Profitability", "KeyStatsProfitabilityCard", "KeyStatsProfitabilityRows", center_column)
	_build_key_stats_card("income_statement", "Income Statement", "KeyStatsIncomeStatementCard", "KeyStatsIncomeStatementRows", right_column)
	_build_key_stats_card("balance_sheet", "Balance Sheet", "KeyStatsBalanceSheetCard", "KeyStatsBalanceSheetRows", right_column)
	_build_key_stats_card("cash_flow", "Cash Flow Statement", "KeyStatsCashFlowStatementCard", "KeyStatsCashFlowStatementRows", right_column)
	_style_key_stats_dashboard_ui()
	_update_key_stats_dashboard_layout()
	_refresh_key_stats_dashboard({})

func _build_key_stats_dashboard_column(column_name: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.name = column_name
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_FILL
	column.add_theme_constant_override("separation", 12)
	key_stats_dashboard_grid.add_child(column)
	return column

func _build_key_stats_card(
	card_id: String,
	title: String,
	card_name: String,
	rows_name: String,
	parent_node: Node
) -> VBoxContainer:
	var card: PanelContainer = PanelContainer.new()
	card.name = card_name
	card.custom_minimum_size = Vector2(250, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_FILL
	parent_node.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 7)
	margin.add_child(vbox)

	var title_label := Label.new()
	title_label.name = "%sTitle" % card_name
	title_label.text = title
	title_label.add_theme_color_override("font_color", COLOR_STOCKBOT_TEXT)
	title_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE + 2)
	vbox.add_child(title_label)

	var separator := HSeparator.new()
	vbox.add_child(separator)

	var rows := VBoxContainer.new()
	rows.name = rows_name
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 5)
	vbox.add_child(rows)
	key_stats_card_rows[card_id] = rows
	return rows

func _build_key_stats_metric_card(parent_node: Node) -> void:
	var card: PanelContainer = PanelContainer.new()
	card.name = "KeyStatsMetricTableCard"
	card.custom_minimum_size = Vector2(280, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent_node.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 7)
	margin.add_child(vbox)

	var button_row := HBoxContainer.new()
	button_row.name = "KeyStatsMetricPillRow"
	button_row.add_theme_constant_override("separation", 6)
	vbox.add_child(button_row)

	var metrics := [
		{"id": KEY_STATS_METRIC_NET_INCOME, "label": "Net Income", "name": "KeyStatsMetricNetIncomeButton"},
		{"id": KEY_STATS_METRIC_EPS, "label": "EPS", "name": "KeyStatsMetricEpsButton"},
		{"id": KEY_STATS_METRIC_REVENUE, "label": "Revenue", "name": "KeyStatsMetricRevenueButton"}
	]
	for metric_value in metrics:
		var metric: Dictionary = metric_value
		var button := Button.new()
		button.name = str(metric.get("name", ""))
		button.text = str(metric.get("label", ""))
		button.custom_minimum_size = Vector2(72, 32)
		button.pressed.connect(_root._on_key_stats_metric_button_pressed.bind(str(metric.get("id", ""))))
		button_row.add_child(button)
		key_stats_metric_buttons[str(metric.get("id", ""))] = button

	var separator := HSeparator.new()
	vbox.add_child(separator)

	key_stats_metric_table_rows = VBoxContainer.new()
	key_stats_metric_table_rows.name = "KeyStatsMetricTableRows"
	key_stats_metric_table_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_stats_metric_table_rows.add_theme_constant_override("separation", 5)
	vbox.add_child(key_stats_metric_table_rows)

	var footer_separator := HSeparator.new()
	vbox.add_child(footer_separator)

	key_stats_metric_footer_rows = VBoxContainer.new()
	key_stats_metric_footer_rows.name = "KeyStatsMetricFooterRows"
	key_stats_metric_footer_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_stats_metric_footer_rows.add_theme_constant_override("separation", 5)
	vbox.add_child(key_stats_metric_footer_rows)

func _style_key_stats_dashboard_ui() -> void:
	if key_stats_dashboard_grid == null:
		return
	_style_key_stats_card_tree(key_stats_dashboard_grid)
	_refresh_key_stats_metric_button_styles()

func _style_key_stats_card_tree(node: Node) -> void:
	for child in node.get_children():
		var card: PanelContainer = child as PanelContainer
		if card != null:
			_style_stockbot_panel(card, COLOR_STOCKBOT_SURFACE_ALT, COLOR_STOCKBOT_EDGE, 6, 1)
		_style_key_stats_card_tree(child)

func _update_key_stats_dashboard_layout() -> void:
	if key_stats_dashboard_grid == null:
		return
	var viewport_width: float = get_viewport_rect().size.x
	var content_width: float = 0.0
	if work_area_panel != null:
		content_width = work_area_panel.get_rect().size.x
	content_width = max(content_width, viewport_width - 520.0)
	if viewport_width >= 1200.0 or content_width >= KEY_STATS_DASHBOARD_DESKTOP_WIDTH:
		key_stats_dashboard_grid.columns = 3
		key_stats_dashboard_grid.custom_minimum_size = Vector2(KEY_STATS_DASHBOARD_DESKTOP_WIDTH, 0)
	elif content_width >= KEY_STATS_DASHBOARD_TWO_COLUMN_WIDTH:
		key_stats_dashboard_grid.columns = 2
		key_stats_dashboard_grid.custom_minimum_size = Vector2.ZERO
	else:
		key_stats_dashboard_grid.columns = 1
		key_stats_dashboard_grid.custom_minimum_size = Vector2.ZERO

func _on_key_stats_metric_button_pressed(metric_id: String) -> void:
	if metric_id.is_empty() or selected_key_stats_metric == metric_id:
		return
	selected_key_stats_metric = metric_id
	_refresh_key_stats_metric_button_styles()
	_refresh_key_stats_dashboard(current_trade_snapshot)
	trade_workspace_key_stats_cache_key = _trade_workspace_key_stats_snapshot_key(current_trade_snapshot)

func _refresh_key_stats_metric_button_styles() -> void:
	for metric_id_value in key_stats_metric_buttons.keys():
		var metric_id: String = str(metric_id_value)
		var button: Button = key_stats_metric_buttons.get(metric_id, null) as Button
		if button == null:
			continue
		UiTheme.style_tab_button(button, "terminal_tab", metric_id == selected_key_stats_metric, {"radius": 0})

func _refresh_key_stats_dashboard(snapshot: Dictionary) -> void:
	if key_stats_dashboard_grid == null:
		return

	if snapshot.is_empty():
		var empty_rows: Array = [{"label": "Status", "value": "Pick a stock"}]
		_refresh_key_stats_rows("current_valuation", empty_rows)
		_refresh_key_stats_rows("per_share", empty_rows)
		_refresh_key_stats_rows("dividend", empty_rows)
		_refresh_key_stats_rows("profitability", empty_rows)
		_refresh_key_stats_rows("income_statement", empty_rows)
		_refresh_key_stats_rows("balance_sheet", empty_rows)
		_refresh_key_stats_rows("cash_flow", empty_rows)
		_refresh_key_stats_metric_table({}, {})
		return

	var context: Dictionary = _build_key_stats_context(snapshot)
	_refresh_key_stats_rows("current_valuation", _build_key_stats_valuation_rows(context))
	_refresh_key_stats_rows("per_share", _build_key_stats_per_share_rows(context))
	_refresh_key_stats_rows("dividend", _build_key_stats_dividend_rows(context))
	_refresh_key_stats_rows("profitability", _build_key_stats_profitability_rows(context))
	_refresh_key_stats_rows("income_statement", _build_key_stats_income_statement_rows(context))
	_refresh_key_stats_rows("balance_sheet", _build_key_stats_balance_sheet_rows(context))
	_refresh_key_stats_rows("cash_flow", _build_key_stats_cash_flow_rows(context))
	_refresh_key_stats_metric_table(snapshot, context)

func _refresh_key_stats_rows(card_id: String, rows: Array) -> void:
	var container: VBoxContainer = key_stats_card_rows.get(card_id, null) as VBoxContainer
	if container == null:
		return
	_refresh_key_stats_rows_in_container(container, rows)

func _refresh_key_stats_rows_in_container(container: VBoxContainer, rows: Array) -> void:
	_clear_key_stats_container(container)
	for row_value in rows:
		var row: Dictionary = row_value
		container.add_child(_build_key_stats_value_row(
			str(row.get("label", "")),
			str(row.get("value", "-")),
			row.get("color", COLOR_STOCKBOT_TEXT),
			row
		))

func _clear_key_stats_container(container: VBoxContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _build_key_stats_value_row(label_text: String, value_text: String, value_color: Color = COLOR_STOCKBOT_TEXT, source_row: Dictionary = {}) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	var capturable: bool = _key_stats_row_is_capturable(label_text, value_text)
	row.tooltip_text = "Click to open research actions." if capturable else ""
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if capturable else Control.CURSOR_ARROW
	row.gui_input.connect(_root._on_key_stats_value_row_gui_input.bind(source_row.duplicate(true), label_text, value_text))

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", COLOR_STOCKBOT_MUTED)
	_apply_font_override_to_control(label, DEFAULT_APP_FONT_SIZE, _get_app_font())
	row.add_child(label)

	var value := Label.new()
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.text = value_text
	value.custom_minimum_size = Vector2(KEY_STATS_ROW_VALUE_WIDTH, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.clip_text = true
	value.add_theme_color_override("font_color", value_color)
	_apply_font_override_to_control(value, DEFAULT_APP_FONT_SIZE, _get_app_font())
	row.add_child(value)
	return row

func _on_key_stats_value_row_gui_input(event: InputEvent, source_row: Dictionary, label_text: String, value_text: String) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or not [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT].has(mouse_event.button_index):
		return
	if not _key_stats_row_is_capturable(label_text, value_text):
		return
	if selected_company_id.is_empty():
		_show_toast("Pick a stock before capturing research.", false)
		return
	var capture_payload: Dictionary = {
		"source_type": "key_stats",
		"company_id": selected_company_id,
		"label": label_text,
		"value": value_text,
		"detail": str(source_row.get("detail", "")),
		"source_id": _node_token(label_text)
	}
	if source_row.has("category"):
		capture_payload["category"] = str(source_row.get("category", ""))
	if source_row.has("raw_value"):
		capture_payload["raw_value"] = float(source_row.get("raw_value", 0.0))
	pending_capture_payloads["key_stats"] = capture_payload
	_show_key_stats_capture_menu(mouse_event.global_position)

func _show_key_stats_capture_menu(menu_position: Vector2) -> void:
	if key_stats_capture_menu == null:
		key_stats_capture_menu = PopupMenu.new()
		key_stats_capture_menu.name = "KeyStatsCaptureContextMenu"
		key_stats_capture_menu.id_pressed.connect(_root._on_key_stats_capture_menu_id_pressed)
		add_child(key_stats_capture_menu)
	key_stats_capture_menu.clear()
	key_stats_capture_menu.add_item("Add to Research Tray", 1)
	key_stats_capture_menu.position = Vector2i(int(menu_position.x), int(menu_position.y))
	key_stats_capture_menu.popup()

func _on_key_stats_capture_menu_id_pressed(id: int) -> void:
	_commit_pending_capture("key_stats", id)

func _key_stats_row_is_capturable(label_text: String, value_text: String) -> bool:
	if selected_company_id.is_empty():
		return false
	var label_lower: String = label_text.to_lower()
	if label_lower in ["status", "period"] or label_lower.begins_with("q"):
		return false
	var value_clean: String = value_text.strip_edges()
	if value_clean.is_empty() or value_clean == "-" or value_clean.to_lower() in ["n/a", "na"]:
		return false
	if label_lower.find("record / pay") != -1:
		return false
	return true

func _build_key_stats_context(snapshot: Dictionary) -> Dictionary:
	var financials: Dictionary = snapshot.get("financials", {})
	var financial_history: Array = snapshot.get("financial_history", [])
	var financial_statement_snapshot: Dictionary = snapshot.get("financial_statement_snapshot", {})
	var selected_period: Dictionary = {}
	if not financial_statement_snapshot.is_empty():
		selected_period = _selected_statement_period(financial_statement_snapshot)
	var latest_quarters: Array = _key_stats_latest_quarters(financial_statement_snapshot, 4)
	if selected_period.is_empty() and not latest_quarters.is_empty():
		selected_period = latest_quarters[0]

	var latest_history: Dictionary = _key_stats_latest_history_entry(financial_history)
	var current_price: float = max(float(snapshot.get("current_price", snapshot.get("previous_close", 0.0))), 0.0)
	var shares_outstanding: float = max(float(financials.get("shares_outstanding", snapshot.get("shares_outstanding", 0.0))), 0.0)
	var statement_shares: float = _key_stats_statement_value_from_period(selected_period, "balance_sheet", "shares_outstanding")
	if shares_outstanding <= 0.0 and statement_shares > 0.0:
		shares_outstanding = statement_shares

	var market_cap: float = max(float(financials.get("market_cap", 0.0)), 0.0)
	if market_cap <= 0.0 and shares_outstanding > 0.0 and current_price > 0.0:
		market_cap = current_price * shares_outstanding

	var revenue_ttm: float = _key_stats_ttm_sum(financial_statement_snapshot, "income_statement", "revenue", float(financials.get("revenue", latest_history.get("revenue", 0.0))))
	var net_income_ttm: float = _key_stats_ttm_sum(financial_statement_snapshot, "income_statement", "net_income", float(financials.get("net_income", latest_history.get("net_income", 0.0))))
	var gross_profit_ttm: float = _key_stats_ttm_sum(financial_statement_snapshot, "income_statement", "gross_profit", max(revenue_ttm * 0.25, net_income_ttm))
	var operating_income_ttm: float = _key_stats_ttm_sum(financial_statement_snapshot, "income_statement", "operating_income", net_income_ttm * 1.18)
	var income_before_tax_ttm: float = _key_stats_ttm_sum(financial_statement_snapshot, "income_statement", "income_before_tax", net_income_ttm * 1.22)
	var ebitda_ttm: float = operating_income_ttm + max(revenue_ttm * 0.035, 0.0)

	var current_assets: float = _key_stats_statement_value_from_period(selected_period, "balance_sheet", "current_assets")
	var total_assets: float = _key_stats_statement_value_from_period(selected_period, "balance_sheet", "total_assets")
	var current_liabilities: float = _key_stats_statement_value_from_period(selected_period, "balance_sheet", "current_liabilities")
	var total_liabilities: float = _key_stats_statement_value_from_period(selected_period, "balance_sheet", "total_liabilities")
	var equity: float = _key_stats_statement_value_from_period(selected_period, "balance_sheet", "equity")
	var estimated_cash: float = current_assets * 0.18 if current_assets > 0.0 else revenue_ttm * 0.025
	var working_capital: float = current_assets - current_liabilities

	var cash_from_operating_ttm: float = _key_stats_ttm_sum(financial_statement_snapshot, "cash_flow", "cash_from_operating", max(net_income_ttm + (revenue_ttm * 0.025), 0.0))
	var cash_from_investing_ttm: float = _key_stats_ttm_sum(financial_statement_snapshot, "cash_flow", "cash_from_investing", -max(revenue_ttm * 0.08, 0.0))
	var cash_from_financing_ttm: float = _key_stats_ttm_sum(financial_statement_snapshot, "cash_flow", "cash_from_financing", 0.0)
	var capital_expenditure_ttm: float = max(-cash_from_investing_ttm, 0.0)
	var free_cash_flow_ttm: float = cash_from_operating_ttm - capital_expenditure_ttm
	var enterprise_value: float = max(market_cap + total_liabilities - estimated_cash, 0.0)

	var selected_revenue_q: float = _key_stats_statement_value_from_period(selected_period, "income_statement", "revenue")
	var selected_gross_profit_q: float = _key_stats_statement_value_from_period(selected_period, "income_statement", "gross_profit")
	var selected_operating_income_q: float = _key_stats_statement_value_from_period(selected_period, "income_statement", "operating_income")
	var selected_net_income_q: float = _key_stats_statement_value_from_period(selected_period, "income_statement", "net_income")
	if selected_revenue_q <= 0.0:
		selected_revenue_q = revenue_ttm / 4.0
	if selected_gross_profit_q <= 0.0:
		selected_gross_profit_q = gross_profit_ttm / 4.0
	if is_zero_approx(selected_operating_income_q):
		selected_operating_income_q = operating_income_ttm / 4.0
	if is_zero_approx(selected_net_income_q):
		selected_net_income_q = net_income_ttm / 4.0

	var eps_ttm: float = _key_stats_safe_divide(net_income_ttm, shares_outstanding)
	var eps_annualised: float = _key_stats_safe_divide(selected_net_income_q * 4.0, shares_outstanding)
	var revenue_per_share: float = _key_stats_safe_divide(revenue_ttm, shares_outstanding)
	var cash_per_share: float = _key_stats_safe_divide(estimated_cash, shares_outstanding)
	var book_value_per_share: float = _key_stats_safe_divide(equity, shares_outstanding)
	var operating_cashflow_per_share: float = _key_stats_safe_divide(cash_from_operating_ttm, shares_outstanding)
	var free_cashflow_per_share: float = _key_stats_safe_divide(free_cash_flow_ttm, shares_outstanding)
	var company_id: String = str(snapshot.get("id", ""))
	var dividend_context: Dictionary = _build_key_stats_dividend_context(
		GameManager.get_corporate_dividend_snapshot(company_id) if not company_id.is_empty() else {},
		current_price
	)

	return {
		"company_id": company_id,
		"financials": financials,
		"financial_history": financial_history,
		"financial_statement_snapshot": financial_statement_snapshot,
		"dividend_context": dividend_context,
		"selected_period": selected_period,
		"current_price": current_price,
		"shares_outstanding": shares_outstanding,
		"market_cap": market_cap,
		"revenue_ttm": revenue_ttm,
		"net_income_ttm": net_income_ttm,
		"gross_profit_ttm": gross_profit_ttm,
		"operating_income_ttm": operating_income_ttm,
		"income_before_tax_ttm": income_before_tax_ttm,
		"ebitda_ttm": ebitda_ttm,
		"current_assets": current_assets,
		"total_assets": total_assets,
		"current_liabilities": current_liabilities,
		"total_liabilities": total_liabilities,
		"equity": equity,
		"estimated_cash": estimated_cash,
		"working_capital": working_capital,
		"cash_from_operating_ttm": cash_from_operating_ttm,
		"cash_from_investing_ttm": cash_from_investing_ttm,
		"cash_from_financing_ttm": cash_from_financing_ttm,
		"capital_expenditure_ttm": capital_expenditure_ttm,
		"free_cash_flow_ttm": free_cash_flow_ttm,
		"enterprise_value": enterprise_value,
		"selected_revenue_q": selected_revenue_q,
		"selected_gross_profit_q": selected_gross_profit_q,
		"selected_operating_income_q": selected_operating_income_q,
		"selected_net_income_q": selected_net_income_q,
		"eps_ttm": eps_ttm,
		"eps_annualised": eps_annualised,
		"revenue_per_share": revenue_per_share,
		"cash_per_share": cash_per_share,
		"book_value_per_share": book_value_per_share,
		"operating_cashflow_per_share": operating_cashflow_per_share,
		"free_cashflow_per_share": free_cashflow_per_share
	}

func _build_key_stats_valuation_rows(context: Dictionary) -> Array:
	var financials: Dictionary = context.get("financials", {})
	var current_price: float = float(context.get("current_price", 0.0))
	var market_cap: float = float(context.get("market_cap", 0.0))
	var net_income_ttm: float = float(context.get("net_income_ttm", 0.0))
	var revenue_ttm: float = float(context.get("revenue_ttm", 0.0))
	var equity: float = float(context.get("equity", 0.0))
	var cash_from_operating_ttm: float = float(context.get("cash_from_operating_ttm", 0.0))
	var free_cash_flow_ttm: float = float(context.get("free_cash_flow_ttm", 0.0))
	var operating_income_ttm: float = float(context.get("operating_income_ttm", 0.0))
	var ebitda_ttm: float = float(context.get("ebitda_ttm", 0.0))
	var enterprise_value: float = float(context.get("enterprise_value", 0.0))
	var eps_ttm: float = float(context.get("eps_ttm", 0.0))
	var eps_annualised: float = float(context.get("eps_annualised", 0.0))
	var earnings_growth: float = float(financials.get("earnings_growth_yoy", 0.0))
	var earnings_cagr: float = float(financials.get("earnings_cagr_10y", earnings_growth))
	var forward_net_income: float = net_income_ttm * max(1.0 + (earnings_growth / 100.0), 0.05)
	var pe_ttm: float = _key_stats_safe_divide(current_price, eps_ttm)
	var forward_pe: float = _key_stats_safe_divide(market_cap, forward_net_income)
	return [
		{"label": "Current PE Ratio (Annualised)", "value": _format_key_stats_ratio_value(_key_stats_safe_divide(current_price, eps_annualised), eps_annualised > 0.0)},
		{"label": "Current PE Ratio (TTM)", "value": _format_key_stats_ratio_value(pe_ttm, eps_ttm > 0.0)},
		{"label": "Forward PE Ratio", "value": _format_key_stats_ratio_value(forward_pe, forward_net_income > 0.0)},
		{"label": "Earnings Yield (TTM)", "value": _format_key_stats_percent_ratio(_key_stats_safe_divide(net_income_ttm, market_cap), market_cap > 0.0)},
		{"label": "Current Price to Sales (TTM)", "value": _format_key_stats_ratio_value(_key_stats_safe_divide(market_cap, revenue_ttm), revenue_ttm > 0.0)},
		{"label": "Current Price to Book Value", "value": _format_key_stats_ratio_value(_key_stats_safe_divide(market_cap, equity), equity > 0.0)},
		{"label": "Current Price To Cashflow (TTM)", "value": _format_key_stats_ratio_value(_key_stats_safe_divide(market_cap, cash_from_operating_ttm), cash_from_operating_ttm > 0.0)},
		{"label": "Current Price To Free Cashflow (TTM)", "value": _format_key_stats_ratio_value(_key_stats_safe_divide(market_cap, free_cash_flow_ttm), free_cash_flow_ttm > 0.0)},
		{"label": "EV to EBIT (TTM)", "value": _format_key_stats_ratio_value(_key_stats_safe_divide(enterprise_value, operating_income_ttm), operating_income_ttm > 0.0)},
		{"label": "EV to EBITDA (TTM)", "value": _format_key_stats_ratio_value(_key_stats_safe_divide(enterprise_value, ebitda_ttm), ebitda_ttm > 0.0)},
		{"label": "PEG Ratio", "value": _format_key_stats_ratio_value(_key_stats_safe_divide(pe_ttm, earnings_growth), earnings_growth > 0.0 and pe_ttm > 0.0)},
		{"label": "PEG Ratio (3yr)", "value": _format_key_stats_ratio_value(_key_stats_safe_divide(pe_ttm, earnings_cagr), earnings_cagr > 0.0 and pe_ttm > 0.0)},
		{"label": "PEG (Forward)", "value": _format_key_stats_ratio_value(_key_stats_safe_divide(forward_pe, max(earnings_growth + 2.0, 0.0)), earnings_growth > -2.0 and forward_pe > 0.0)}
	]

func _build_key_stats_per_share_rows(context: Dictionary) -> Array:
	return [
		{"label": "Current EPS (TTM)", "value": _format_key_stats_decimal_value(float(context.get("eps_ttm", 0.0)), float(context.get("shares_outstanding", 0.0)) > 0.0)},
		{"label": "Current EPS (Annualised)", "value": _format_key_stats_decimal_value(float(context.get("eps_annualised", 0.0)), float(context.get("shares_outstanding", 0.0)) > 0.0)},
		{"label": "Revenue Per Share (TTM)", "value": _format_key_stats_decimal_value(float(context.get("revenue_per_share", 0.0)), float(context.get("shares_outstanding", 0.0)) > 0.0)},
		{"label": "Cash Per Share (Quarter)", "value": _format_key_stats_decimal_value(float(context.get("cash_per_share", 0.0)), float(context.get("shares_outstanding", 0.0)) > 0.0)},
		{"label": "Book Value Per Share", "value": _format_key_stats_decimal_value(float(context.get("book_value_per_share", 0.0)), float(context.get("shares_outstanding", 0.0)) > 0.0)},
		{"label": "Operating Cashflow Per Share (TTM)", "value": _format_key_stats_decimal_value(float(context.get("operating_cashflow_per_share", 0.0)), float(context.get("shares_outstanding", 0.0)) > 0.0)},
		{"label": "Free Cashflow Per Share (TTM)", "value": _format_key_stats_decimal_value(float(context.get("free_cashflow_per_share", 0.0)), float(context.get("shares_outstanding", 0.0)) > 0.0)}
	]

func _build_key_stats_dividend_context(dividend_snapshot: Dictionary, current_price: float) -> Dictionary:
	var current_day_number: int = RunState.day_index + 1
	var declared_rows: Array = dividend_snapshot.get("declared_rows", [])
	var upcoming_rows: Array = dividend_snapshot.get("upcoming_rows", [])
	var declared_cash_row: Dictionary = _first_key_stats_dividend_row_by_type(declared_rows, "cash_dividend")
	var next_cash_row: Dictionary = declared_cash_row
	if next_cash_row.is_empty():
		next_cash_row = _first_key_stats_dividend_row_by_type(upcoming_rows, "cash_dividend")
	var declared_stock_row: Dictionary = _first_key_stats_dividend_row_by_type(declared_rows, "stock_dividend")
	var next_stock_row: Dictionary = declared_stock_row
	if next_stock_row.is_empty():
		next_stock_row = _first_key_stats_dividend_row_by_type(upcoming_rows, "stock_dividend")
	var next_row: Dictionary = next_cash_row if not next_cash_row.is_empty() else next_stock_row
	var paid_row: Dictionary = _last_key_stats_dividend_row(dividend_snapshot.get("paid_rows", []))
	var basis_row: Dictionary = next_row if not next_row.is_empty() else paid_row
	var next_dps: float = float(next_cash_row.get("amount_per_share", 0.0)) if not next_cash_row.is_empty() else 0.0
	return {
		"status": _key_stats_dividend_status_label(next_row),
		"has_declared": not declared_cash_row.is_empty(),
		"declared_dps": float(declared_cash_row.get("amount_per_share", 0.0)) if not declared_cash_row.is_empty() else 0.0,
		"next_dps": next_dps,
		"next_yield": _key_stats_safe_divide(next_dps, current_price),
		"payout_ratio": float(basis_row.get("payout_ratio", 0.0)) if not basis_row.is_empty() else 0.0,
		"record_day_number": int(next_cash_row.get("record_day_number", 0)) if not next_cash_row.is_empty() else 0,
		"payment_day_number": int(next_cash_row.get("payment_day_number", 0)) if not next_cash_row.is_empty() else 0,
		"eligible_shares": int(next_cash_row.get("eligible_shares", 0)) if not next_cash_row.is_empty() else 0,
		"projected_amount": float(next_cash_row.get("projected_amount", 0.0)) if not next_cash_row.is_empty() else 0.0,
		"stock_ratio": float(next_stock_row.get("stock_dividend_ratio", 0.0)) if not next_stock_row.is_empty() else 0.0,
		"stock_bonus_estimate": int(next_stock_row.get("projected_bonus_shares", 0)) if not next_stock_row.is_empty() else 0,
		"stock_payment_day_number": int(next_stock_row.get("payment_day_number", 0)) if not next_stock_row.is_empty() else 0,
		"last_paid_dps": float(paid_row.get("amount_per_share", 0.0)) if not paid_row.is_empty() else 0.0,
		"current_day_number": current_day_number
	}

func _build_key_stats_dividend_rows(context: Dictionary) -> Array:
	var dividend_context: Dictionary = context.get("dividend_context", {})
	var current_day_number: int = int(dividend_context.get("current_day_number", RunState.day_index + 1))
	var has_declared: bool = bool(dividend_context.get("has_declared", false))
	var next_dps: float = float(dividend_context.get("next_dps", 0.0))
	var payout_ratio: float = float(dividend_context.get("payout_ratio", 0.0))
	var projected_amount: float = float(dividend_context.get("projected_amount", 0.0))
	var stock_ratio: float = float(dividend_context.get("stock_ratio", 0.0))
	var stock_bonus_estimate: int = int(dividend_context.get("stock_bonus_estimate", 0))
	return [
		{"label": "Status", "value": str(dividend_context.get("status", "No scheduled"))},
		{"label": "Declared DPS", "value": _format_currency(float(dividend_context.get("declared_dps", 0.0))) if has_declared else "-"},
		{"label": "Next DPS", "value": _format_currency(next_dps) if next_dps > 0.0 else "-"},
		{"label": "Next Yield", "value": _format_key_stats_percent_ratio(float(dividend_context.get("next_yield", 0.0)), next_dps > 0.0)},
		{"label": "Payout Ratio", "value": _format_key_stats_percent_ratio(payout_ratio, payout_ratio > 0.0)},
		{"label": "Record / Pay", "value": _format_key_stats_dividend_timetable(
			int(dividend_context.get("record_day_number", 0)),
			int(dividend_context.get("payment_day_number", 0)),
			current_day_number
		)},
		{"label": "Stock Ratio", "value": _format_key_stats_percent_ratio(stock_ratio, stock_ratio > 0.0)},
		{"label": "Stock Est.", "value": "%d share(s)" % stock_bonus_estimate if stock_ratio > 0.0 else "-"},
		{"label": "Your Est.", "value": _format_currency(projected_amount) if next_dps > 0.0 else "-", "color": COLOR_POSITIVE if projected_amount > 0.0 else COLOR_MUTED},
		{"label": "Last Paid DPS", "value": _format_currency(float(dividend_context.get("last_paid_dps", 0.0))) if float(dividend_context.get("last_paid_dps", 0.0)) > 0.0 else "-"}
	]

func _build_key_stats_profitability_rows(context: Dictionary) -> Array:
	var financials: Dictionary = context.get("financials", {})
	var selected_revenue_q: float = float(context.get("selected_revenue_q", 0.0))
	var selected_gross_profit_q: float = float(context.get("selected_gross_profit_q", 0.0))
	var selected_operating_income_q: float = float(context.get("selected_operating_income_q", 0.0))
	var selected_net_income_q: float = float(context.get("selected_net_income_q", 0.0))
	var net_income_ttm: float = float(context.get("net_income_ttm", 0.0))
	var revenue_ttm: float = float(context.get("revenue_ttm", 0.0))
	var total_assets: float = float(context.get("total_assets", 0.0))
	var equity: float = float(context.get("equity", 0.0))
	var total_liabilities: float = float(context.get("total_liabilities", 0.0))
	var computed_roe: float = _key_stats_safe_divide(net_income_ttm, equity) * 100.0
	var roe_value: float = float(financials.get("roe", computed_roe))
	var debt_to_equity: float = float(financials.get("debt_to_equity", _key_stats_safe_divide(total_liabilities, equity)))
	return [
		{"label": "Gross Profit Margin (Quarter)", "value": _format_key_stats_percent_ratio(_key_stats_safe_divide(selected_gross_profit_q, selected_revenue_q), selected_revenue_q > 0.0)},
		{"label": "Operating Profit Margin (Quarter)", "value": _format_key_stats_percent_ratio(_key_stats_safe_divide(selected_operating_income_q, selected_revenue_q), selected_revenue_q > 0.0)},
		{"label": "Net Profit Margin (Quarter)", "value": _format_key_stats_percent_ratio(_key_stats_safe_divide(selected_net_income_q, selected_revenue_q), selected_revenue_q > 0.0)},
		{"label": "ROE (Annualised)", "value": _format_key_stats_percent_value(roe_value, equity > 0.0 or financials.has("roe"))},
		{"label": "Asset Turnover (TTM)", "value": _format_key_stats_ratio_value(_key_stats_safe_divide(revenue_ttm, total_assets), total_assets > 0.0)},
		{"label": "Debt To Equity", "value": _format_key_stats_ratio_value(debt_to_equity, equity > 0.0 or financials.has("debt_to_equity"))}
	]

func _build_key_stats_income_statement_rows(context: Dictionary) -> Array:
	return [
		{"label": "Revenue (TTM)", "value": _format_compact_currency(float(context.get("revenue_ttm", 0.0)))},
		{"label": "Gross Profit (TTM)", "value": _format_compact_currency(float(context.get("gross_profit_ttm", 0.0)))},
		{"label": "EBITDA (TTM)", "value": _format_compact_currency(float(context.get("ebitda_ttm", 0.0)))},
		{"label": "Net Income (TTM)", "value": _format_compact_currency(float(context.get("net_income_ttm", 0.0))), "color": _key_stats_amount_color(float(context.get("net_income_ttm", 0.0)))}
	]

func _build_key_stats_balance_sheet_rows(context: Dictionary) -> Array:
	var equity: float = float(context.get("equity", 0.0))
	return [
		{"label": "Cash (Quarter)", "value": _format_compact_currency(float(context.get("estimated_cash", 0.0)))},
		{"label": "Total Assets (Quarter)", "value": _format_compact_currency(float(context.get("total_assets", 0.0)))},
		{"label": "Total Liabilities (Quarter)", "value": _format_compact_currency(float(context.get("total_liabilities", 0.0)))},
		{"label": "Working Capital (Quarter)", "value": _format_compact_currency(float(context.get("working_capital", 0.0))), "color": _key_stats_amount_color(float(context.get("working_capital", 0.0)))},
		{"label": "Common Equity", "value": _format_compact_currency(equity * 0.998)},
		{"label": "Total Equity", "value": _format_compact_currency(equity)}
	]

func _build_key_stats_cash_flow_rows(context: Dictionary) -> Array:
	return [
		{"label": "Cash From Operations (TTM)", "value": _format_compact_currency(float(context.get("cash_from_operating_ttm", 0.0))), "color": _key_stats_amount_color(float(context.get("cash_from_operating_ttm", 0.0)))},
		{"label": "Cash From Investing (TTM)", "value": _format_compact_currency(float(context.get("cash_from_investing_ttm", 0.0))), "color": _key_stats_amount_color(float(context.get("cash_from_investing_ttm", 0.0)))},
		{"label": "Cash From Financing (TTM)", "value": _format_compact_currency(float(context.get("cash_from_financing_ttm", 0.0))), "color": _key_stats_amount_color(float(context.get("cash_from_financing_ttm", 0.0)))},
		{"label": "Capital Expenditure (TTM)", "value": _format_compact_currency(float(context.get("capital_expenditure_ttm", 0.0)))},
		{"label": "Free Cash Flow (TTM)", "value": _format_compact_currency(float(context.get("free_cash_flow_ttm", 0.0))), "color": _key_stats_amount_color(float(context.get("free_cash_flow_ttm", 0.0)))}
	]

func _refresh_key_stats_metric_table(snapshot: Dictionary, context: Dictionary) -> void:
	if key_stats_metric_table_rows == null or key_stats_metric_footer_rows == null:
		return
	_clear_key_stats_container(key_stats_metric_table_rows)
	_clear_key_stats_container(key_stats_metric_footer_rows)

	if snapshot.is_empty() or context.is_empty():
		key_stats_metric_table_rows.add_child(_build_key_stats_value_row("Period", "-"))
		key_stats_metric_footer_rows.add_child(_build_key_stats_value_row("Market Cap", "-"))
		return

	var financial_history: Array = context.get("financial_history", [])
	var financial_statement_snapshot: Dictionary = context.get("financial_statement_snapshot", {})
	var years: Array = _key_stats_recent_years(financial_history, financial_statement_snapshot)
	key_stats_metric_table_rows.add_child(_build_key_stats_metric_row("Period", _key_stats_year_labels(years), COLOR_STOCKBOT_AMBER, COLOR_STOCKBOT_AMBER))
	for quarter in range(1, 5):
		key_stats_metric_table_rows.add_child(_build_key_stats_metric_row(
			"Q%d" % quarter,
			_key_stats_metric_values_for_quarter(financial_statement_snapshot, selected_key_stats_metric, years, quarter),
			COLOR_STOCKBOT_MUTED,
			COLOR_STOCKBOT_TEXT,
			selected_key_stats_metric,
			years
		))
	key_stats_metric_table_rows.add_child(_build_key_stats_metric_row(
		"Annualised",
		_key_stats_metric_values_for_annual(financial_statement_snapshot, financial_history, selected_key_stats_metric, years),
		COLOR_STOCKBOT_MUTED,
		COLOR_STOCKBOT_TEXT,
		selected_key_stats_metric,
		years
	))
	key_stats_metric_table_rows.add_child(_build_key_stats_metric_row(
		"TTM",
		_key_stats_metric_values_for_ttm(financial_statement_snapshot, financial_history, selected_key_stats_metric, years),
		COLOR_STOCKBOT_MUTED,
		COLOR_STOCKBOT_TEXT,
		selected_key_stats_metric,
		years
	))

	key_stats_metric_footer_rows.add_child(_build_key_stats_value_row("Market Cap", _format_compact_currency(float(context.get("market_cap", 0.0)))))
	key_stats_metric_footer_rows.add_child(_build_key_stats_value_row("Enterprise Value", _format_compact_currency(float(context.get("enterprise_value", 0.0)))))
	key_stats_metric_footer_rows.add_child(_build_key_stats_value_row("Current Share Outstanding", _format_key_stats_compact_number(float(context.get("shares_outstanding", 0.0)))))
	var financials: Dictionary = context.get("financials", {})
	key_stats_metric_footer_rows.add_child(_build_key_stats_value_row("Free Float", _format_key_stats_percent_value(float(financials.get("free_float_pct", 0.0)), financials.has("free_float_pct"))))

func _build_key_stats_metric_row(
	label_text: String,
	values: Array,
	label_color: Color = COLOR_STOCKBOT_MUTED,
	value_color: Color = COLOR_STOCKBOT_TEXT,
	metric_id: String = "",
	years: Array = []
) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(KEY_STATS_METRIC_LABEL_WIDTH, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", label_color)
	_apply_font_override_to_control(label, DEFAULT_APP_FONT_SIZE, _get_app_font())
	row.add_child(label)

	for value_index in range(values.size()):
		var value_text = values[value_index]
		var value := Label.new()
		value.text = str(value_text)
		value.custom_minimum_size = Vector2(KEY_STATS_METRIC_VALUE_WIDTH, 0)
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value.clip_text = true
		value.add_theme_color_override("font_color", value_color)
		_apply_font_override_to_control(value, DEFAULT_APP_FONT_SIZE, _get_app_font())
		var payload: Dictionary = _key_stats_metric_capture_payload(metric_id, label_text, value.text, years, value_index)
		if not payload.is_empty():
			value.mouse_filter = Control.MOUSE_FILTER_STOP
			value.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			value.tooltip_text = "Click to add this metric value to the Research Tray."
			value.gui_input.connect(_root._on_key_stats_metric_value_gui_input.bind(payload))
		row.add_child(value)
	return row

func _key_stats_metric_capture_payload(metric_id: String, row_label: String, value_text: String, years: Array, value_index: int) -> Dictionary:
	if selected_company_id.is_empty() or metric_id.is_empty():
		return {}
	var clean_value: String = value_text.strip_edges()
	if clean_value.is_empty() or clean_value == "-":
		return {}
	var year_label: String = ""
	if value_index >= 0 and value_index < years.size():
		year_label = str(int(years[value_index]))
	var metric_label: String = _key_stats_metric_display_label(metric_id)
	var label_parts: Array = [metric_label, row_label]
	if not year_label.is_empty():
		label_parts.append(year_label)
	var label_text: String = " ".join(label_parts)
	return {
		"source_type": "key_stats",
		"category": "financials",
		"company_id": selected_company_id,
		"label": label_text,
		"value": clean_value,
		"detail": "%s captured from the Key Stats metric table." % label_text,
		"source_id": "key_stats_metric_%s_%s_%s_%s" % [
			selected_company_id,
			metric_id,
			_node_token(row_label),
			_node_token(year_label)
		]
	}

func _key_stats_metric_display_label(metric_id: String) -> String:
	match metric_id:
		KEY_STATS_METRIC_EPS:
			return "EPS"
		KEY_STATS_METRIC_REVENUE:
			return "Revenue"
		_:
			return "Net Income"

func _on_key_stats_metric_value_gui_input(event: InputEvent, capture_payload: Dictionary) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or not [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT].has(mouse_event.button_index):
		return
	if capture_payload.is_empty():
		return
	pending_capture_payloads["key_stats"] = capture_payload.duplicate(true)
	_show_key_stats_capture_menu(mouse_event.global_position)

func _key_stats_year_labels(years: Array) -> Array:
	var labels: Array = []
	for year_value in years:
		labels.append(str(int(year_value)))
	while labels.size() < KEY_STATS_YEAR_COLUMN_LIMIT:
		labels.append("-")
	return labels

func _key_stats_metric_values_for_quarter(
	financial_statement_snapshot: Dictionary,
	metric_id: String,
	years: Array,
	quarter: int
) -> Array:
	var values: Array = []
	for year_value in years:
		var statement: Dictionary = _key_stats_statement_for_year_quarter(financial_statement_snapshot, int(year_value), quarter)
		values.append(_format_key_stats_metric_result(metric_id, _key_stats_metric_result_from_statement(statement, metric_id)))
	while values.size() < KEY_STATS_YEAR_COLUMN_LIMIT:
		values.append("-")
	return values

func _key_stats_metric_values_for_annual(
	financial_statement_snapshot: Dictionary,
	financial_history: Array,
	metric_id: String,
	years: Array
) -> Array:
	var values: Array = []
	for year_value in years:
		values.append(_format_key_stats_metric_result(metric_id, _key_stats_metric_annual_result(financial_statement_snapshot, financial_history, metric_id, int(year_value))))
	while values.size() < KEY_STATS_YEAR_COLUMN_LIMIT:
		values.append("-")
	return values

func _key_stats_metric_values_for_ttm(
	financial_statement_snapshot: Dictionary,
	financial_history: Array,
	metric_id: String,
	years: Array
) -> Array:
	var values: Array = []
	for year_value in years:
		values.append(_format_key_stats_metric_result(metric_id, _key_stats_metric_ttm_result(financial_statement_snapshot, financial_history, metric_id, int(year_value))))
	while values.size() < KEY_STATS_YEAR_COLUMN_LIMIT:
		values.append("-")
	return values

func _key_stats_recent_years(financial_history: Array, financial_statement_snapshot: Dictionary) -> Array:
	var seen_years: Dictionary = {}
	for statement_value in financial_statement_snapshot.get("quarterly_statements", []):
		if typeof(statement_value) != TYPE_DICTIONARY:
			continue
		var statement: Dictionary = statement_value
		var year: int = int(statement.get("statement_year", 0))
		if year > 0:
			seen_years[year] = true
	if seen_years.is_empty():
		for history_value in financial_history:
			if typeof(history_value) != TYPE_DICTIONARY:
				continue
			var history_entry: Dictionary = history_value
			var year_from_history: int = int(history_entry.get("year", 0))
			if year_from_history > 0:
				seen_years[year_from_history] = true

	var years: Array = []
	for year_key in seen_years.keys():
		years.append(int(year_key))
	years.sort()

	var recent_years: Array = []
	for year_index in range(years.size() - 1, -1, -1):
		recent_years.append(int(years[year_index]))
		if recent_years.size() >= KEY_STATS_YEAR_COLUMN_LIMIT:
			break
	return recent_years

func _key_stats_metric_result_from_statement(statement: Dictionary, metric_id: String) -> Dictionary:
	if statement.is_empty():
		return {"valid": false, "value": 0.0}
	if metric_id == KEY_STATS_METRIC_EPS:
		var net_income: float = _key_stats_statement_value_from_period(statement, "income_statement", "net_income")
		var shares_outstanding: float = _key_stats_statement_value_from_period(statement, "balance_sheet", "shares_outstanding")
		return {"valid": shares_outstanding > 0.0, "value": _key_stats_safe_divide(net_income, shares_outstanding)}
	if metric_id == KEY_STATS_METRIC_REVENUE:
		return {
			"valid": _key_stats_period_has_statement_line(statement, "income_statement", "revenue"),
			"value": _key_stats_statement_value_from_period(statement, "income_statement", "revenue")
		}
	return {
		"valid": _key_stats_period_has_statement_line(statement, "income_statement", "net_income"),
		"value": _key_stats_statement_value_from_period(statement, "income_statement", "net_income")
	}

func _key_stats_metric_annual_result(
	financial_statement_snapshot: Dictionary,
	financial_history: Array,
	metric_id: String,
	year: int
) -> Dictionary:
	for quarter in range(4, 0, -1):
		var statement: Dictionary = _key_stats_statement_for_year_quarter(financial_statement_snapshot, year, quarter)
		var result: Dictionary = _key_stats_metric_result_from_statement(statement, metric_id)
		if bool(result.get("valid", false)):
			return {"valid": true, "value": float(result.get("value", 0.0)) * 4.0}
	return _key_stats_history_metric_result(financial_history, metric_id, year)

func _key_stats_metric_ttm_result(
	financial_statement_snapshot: Dictionary,
	financial_history: Array,
	metric_id: String,
	year: int
) -> Dictionary:
	var quarterly_statements: Array = financial_statement_snapshot.get("quarterly_statements", [])
	var end_index: int = -1
	for statement_index in range(quarterly_statements.size()):
		var statement: Dictionary = quarterly_statements[statement_index]
		if int(statement.get("statement_year", 0)) != year:
			continue
		end_index = statement_index
		if int(statement.get("statement_quarter", 0)) == 4:
			break
	if end_index < 0:
		return _key_stats_history_metric_result(financial_history, metric_id, year)

	var total: float = 0.0
	var valid_count: int = 0
	var start_index: int = max(end_index - 3, 0)
	for statement_index in range(start_index, end_index + 1):
		var result: Dictionary = _key_stats_metric_result_from_statement(quarterly_statements[statement_index], metric_id)
		if bool(result.get("valid", false)):
			total += float(result.get("value", 0.0))
			valid_count += 1
	if valid_count > 0:
		return {"valid": true, "value": total}
	return _key_stats_history_metric_result(financial_history, metric_id, year)

func _key_stats_history_metric_result(financial_history: Array, metric_id: String, year: int) -> Dictionary:
	for history_value in financial_history:
		if typeof(history_value) != TYPE_DICTIONARY:
			continue
		var history_entry: Dictionary = history_value
		if int(history_entry.get("year", 0)) != year:
			continue
		if metric_id == KEY_STATS_METRIC_REVENUE:
			return {"valid": history_entry.has("revenue"), "value": float(history_entry.get("revenue", 0.0))}
		if metric_id == KEY_STATS_METRIC_EPS:
			var shares_outstanding: float = float(history_entry.get("shares_outstanding", 0.0))
			return {
				"valid": shares_outstanding > 0.0 and history_entry.has("net_income"),
				"value": _key_stats_safe_divide(float(history_entry.get("net_income", 0.0)), shares_outstanding)
			}
		return {"valid": history_entry.has("net_income"), "value": float(history_entry.get("net_income", 0.0))}
	return {"valid": false, "value": 0.0}

func _format_key_stats_metric_result(metric_id: String, result: Dictionary) -> String:
	if not bool(result.get("valid", false)):
		return "-"
	var value: float = float(result.get("value", 0.0))
	if metric_id == KEY_STATS_METRIC_EPS:
		return _format_decimal(value, 2, true)
	return _format_compact_currency(value)

func _key_stats_statement_for_year_quarter(
	financial_statement_snapshot: Dictionary,
	year: int,
	quarter: int
) -> Dictionary:
	for statement_value in financial_statement_snapshot.get("quarterly_statements", []):
		if typeof(statement_value) != TYPE_DICTIONARY:
			continue
		var statement: Dictionary = statement_value
		if int(statement.get("statement_year", 0)) == year and int(statement.get("statement_quarter", 0)) == quarter:
			return statement
	return {}

func _key_stats_latest_history_entry(financial_history: Array) -> Dictionary:
	if financial_history.is_empty():
		return {}
	for history_index in range(financial_history.size() - 1, -1, -1):
		if typeof(financial_history[history_index]) == TYPE_DICTIONARY:
			return financial_history[history_index]
	return {}

func _key_stats_latest_quarters(financial_statement_snapshot: Dictionary, count: int = 4) -> Array:
	var quarterly_statements: Array = financial_statement_snapshot.get("quarterly_statements", [])
	if quarterly_statements.is_empty():
		return []

	var end_index: int = quarterly_statements.size() - 1
	if selected_financial_statement_index >= 0:
		end_index = clampi(selected_financial_statement_index, 0, quarterly_statements.size() - 1)
	var start_index: int = max(end_index - max(count - 1, 0), 0)
	var periods: Array = []
	for statement_index in range(end_index, start_index - 1, -1):
		periods.append(quarterly_statements[statement_index])
	return periods

func _key_stats_ttm_sum(
	financial_statement_snapshot: Dictionary,
	section_id: String,
	line_id: String,
	fallback_value: float
) -> float:
	var latest_quarters: Array = _key_stats_latest_quarters(financial_statement_snapshot, 4)
	if latest_quarters.size() < 4:
		return fallback_value
	var total: float = 0.0
	var found_count: int = 0
	for period_value in latest_quarters:
		if typeof(period_value) != TYPE_DICTIONARY:
			continue
		var period: Dictionary = period_value
		if not _key_stats_period_has_statement_line(period, section_id, line_id):
			continue
		total += _key_stats_statement_value_from_period(period, section_id, line_id)
		found_count += 1
	return total if found_count > 0 else fallback_value

func _key_stats_statement_value_from_period(period: Dictionary, section_id: String, line_id: String) -> float:
	if period.is_empty():
		return 0.0
	return _key_stats_statement_value(period.get(section_id, []), line_id)

func _key_stats_statement_value(lines: Array, line_id: String) -> float:
	for line_value in lines:
		if typeof(line_value) != TYPE_DICTIONARY:
			continue
		var line_item: Dictionary = line_value
		if str(line_item.get("id", "")) == line_id:
			return float(line_item.get("value", 0.0))
	return 0.0

func _key_stats_period_has_statement_line(period: Dictionary, section_id: String, line_id: String) -> bool:
	if period.is_empty():
		return false
	var lines: Array = period.get(section_id, [])
	for line_value in lines:
		if typeof(line_value) != TYPE_DICTIONARY:
			continue
		var line_item: Dictionary = line_value
		if str(line_item.get("id", "")) == line_id:
			return true
	return false

func _first_key_stats_dividend_row(rows: Array) -> Dictionary:
	for row_value in rows:
		if typeof(row_value) == TYPE_DICTIONARY:
			return row_value
	return {}

func _first_key_stats_dividend_row_by_type(rows: Array, action_type: String) -> Dictionary:
	for row_value in rows:
		if typeof(row_value) == TYPE_DICTIONARY and str(row_value.get("action_type", "")) == action_type:
			return row_value
	return {}

func _last_key_stats_dividend_row(rows: Array) -> Dictionary:
	for row_index in range(rows.size() - 1, -1, -1):
		if typeof(rows[row_index]) == TYPE_DICTIONARY:
			return rows[row_index]
	return {}

func _key_stats_dividend_status_label(row: Dictionary) -> String:
	if row.is_empty():
		return "No scheduled"
	match str(row.get("status", "scheduled")):
		"approved":
			return "Declared"
		"ex_date":
			return "Ex-date"
		"recorded":
			return "Recorded"
		"paid":
			return "Paid"
		_:
			return "Proposed"

func _format_key_stats_dividend_timetable(record_day_number: int, payment_day_number: int, current_day_number: int) -> String:
	if record_day_number <= 0 and payment_day_number <= 0:
		return "-"
	return "%s / %s" % [
		_format_key_stats_day_delta(record_day_number, current_day_number),
		_format_key_stats_day_delta(payment_day_number, current_day_number)
	]

func _format_key_stats_day_delta(day_number: int, current_day_number: int) -> String:
	if day_number <= 0:
		return "-"
	var delta: int = day_number - current_day_number
	if delta == 0:
		return "Today"
	if delta > 0:
		return "D+%d" % delta
	return "D%d" % delta

func _key_stats_safe_divide(numerator: float, denominator: float) -> float:
	if is_zero_approx(denominator):
		return 0.0
	return numerator / denominator

func _format_key_stats_ratio_value(value: float, is_valid: bool = true) -> String:
	if not is_valid:
		return "-"
	return _format_decimal(value, 2, false)

func _format_key_stats_decimal_value(value: float, is_valid: bool = true) -> String:
	if not is_valid:
		return "-"
	return _format_decimal(value, 2, true)

func _format_key_stats_percent_value(value: float, is_valid: bool = true) -> String:
	if not is_valid:
		return "-"
	return _format_percent_value(value)

func _format_key_stats_percent_ratio(value: float, is_valid: bool = true) -> String:
	if not is_valid:
		return "-"
	return _format_percent_value(value * 100.0)

func _format_key_stats_compact_number(value: float) -> String:
	var absolute_value: float = absf(value)
	if absolute_value >= 1000000000.0:
		return "%s%sB" % ["-" if value < 0.0 else "", _format_decimal(absolute_value / 1000000000.0, 2, false)]
	if absolute_value >= 1000000.0:
		return "%s%sM" % ["-" if value < 0.0 else "", _format_decimal(absolute_value / 1000000.0, 2, false)]
	if absolute_value >= 1000.0:
		return "%s%sK" % ["-" if value < 0.0 else "", _format_decimal(absolute_value / 1000.0, 2, false)]
	return _format_decimal(value, 0, true)

func _key_stats_amount_color(value: float) -> Color:
	if value < 0.0:
		return COLOR_NEGATIVE
	if value > 0.0:
		return COLOR_POSITIVE
	return COLOR_TEXT

func _on_order_ticket_toggle_pressed() -> void:
	order_ticket_collapsed = not order_ticket_collapsed
	_apply_trade_layout_ratios()
	main_trade_split.queue_sort()

func _refresh_order_ticket_toggle_state() -> void:
	if order_ticket_toggle_button == null:
		return
	order_ticket_toggle_button.text = ""
	order_ticket_toggle_button.icon = _load_stockbot_icon("chevron_up" if order_ticket_collapsed else "chevron_down")
	order_ticket_toggle_button.expand_icon = true
	order_ticket_toggle_button.tooltip_text = "Show the order ticket." if order_ticket_collapsed else "Hide the order ticket."
	_style_stockbot_icon_button(
		order_ticket_toggle_button,
		"chevron_up" if order_ticket_collapsed else "chevron_down",
		"",
		order_ticket_toggle_button.tooltip_text,
		false,
		COLOR_STOCKBOT_SURFACE_ALT,
		COLOR_STOCKBOT_EDGE_STRONG
	)

func _cache_order_market_summary_labels() -> void:
	order_market_value_labels = {
		"open": find_child("OpenValueLabel", true, false) as Label,
		"high": find_child("HighValueLabel", true, false) as Label,
		"low": find_child("LowValueLabel", true, false) as Label,
		"prev": find_child("PrevValueLabel", true, false) as Label,
		"ara": find_child("ARAValueLabel", true, false) as Label,
		"arb": find_child("ARBValueLabel", true, false) as Label,
		"lot": find_child("LotValueLabel", true, false) as Label,
		"val": find_child("ValValueLabel", true, false) as Label,
		"avg": find_child("AvgValueLabel", true, false) as Label,
		"f_buy": find_child("FBuyValueLabel", true, false) as Label,
		"f_sell": find_child("FSellValueLabel", true, false) as Label,
		"depth": find_child("DepthValueLabel", true, false) as Label
	}
	order_market_name_labels = {
		"open": find_child("OpenLabel", true, false) as Label,
		"high": find_child("HighLabel", true, false) as Label,
		"low": find_child("LowLabel", true, false) as Label,
		"prev": find_child("PrevLabel", true, false) as Label,
		"ara": find_child("ARALabel", true, false) as Label,
		"arb": find_child("ARBLabel", true, false) as Label,
		"lot": find_child("LotLabel", true, false) as Label,
		"val": find_child("ValLabel", true, false) as Label,
		"avg": find_child("AvgLabel", true, false) as Label,
		"f_buy": find_child("FBuyLabel", true, false) as Label,
		"f_sell": find_child("FSellLabel", true, false) as Label,
		"depth": find_child("DepthLabel", true, false) as Label
	}
	_bind_order_market_capture_labels()

func _bind_order_market_capture_labels() -> void:
	for key_value in order_market_value_labels.keys():
		var key: String = str(key_value)
		var label: Label = order_market_value_labels.get(key, null) as Label
		if label == null:
			continue
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		label.tooltip_text = "Click to add this quote item to the Research Tray."
		label.gui_input.connect(_root._on_trade_quote_label_gui_input.bind(key))
	for header_label_value in [order_price_value_label, order_price_change_label]:
		var header_label: Label = header_label_value as Label
		if header_label == null:
			continue
		header_label.mouse_filter = Control.MOUSE_FILTER_STOP
		header_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		header_label.tooltip_text = "Click to add this quote item to the Research Tray."
	if order_price_value_label != null:
		order_price_value_label.gui_input.connect(_root._on_trade_quote_label_gui_input.bind("current_price"))
	if order_price_change_label != null:
		order_price_change_label.gui_input.connect(_root._on_trade_quote_label_gui_input.bind("daily_change"))

func _style_order_market_summary_labels() -> void:
	for label_value in order_market_name_labels.values():
		var label: Label = label_value as Label
		if label == null:
			continue
		_set_label_tone(label, COLOR_STOCKBOT_MUTED)
		label.custom_minimum_size = Vector2(42.0, 0.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.modulate = Color.WHITE
		label.clip_text = true
		label.add_theme_font_size_override("font_size", 11)
	for label_value in order_market_value_labels.values():
		var label: Label = label_value as Label
		if label == null:
			continue
		label.add_theme_stylebox_override("normal", _make_stockbot_stylebox(COLOR_STOCKBOT_BASE, COLOR_STOCKBOT_EDGE, 4, 1, 4))
		label.clip_text = true
		label.add_theme_font_size_override("font_size", 11)

func _style_order_ticker_badge() -> void:
	if order_company_name_label == null:
		return
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = COLOR_STOCKBOT_BLUE_TINT
	badge_style.border_color = COLOR_STOCKBOT_BLUE
	badge_style.set_border_width_all(1)
	badge_style.corner_radius_top_left = 5
	badge_style.corner_radius_top_right = 5
	badge_style.corner_radius_bottom_left = 5
	badge_style.corner_radius_bottom_right = 5
	badge_style.content_margin_left = 6
	badge_style.content_margin_right = 6
	badge_style.content_margin_top = 2
	badge_style.content_margin_bottom = 2
	order_company_name_label.add_theme_stylebox_override("normal", badge_style)
	_set_label_tone(order_company_name_label, COLOR_STOCKBOT_BLUE)
	order_company_name_label.clip_text = true
	order_company_name_label.add_theme_font_size_override("font_size", STOCK_APP_FONT_SIZE)

func _refresh_order_market_summary(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		for key_value in order_market_value_labels.keys():
			_set_order_market_value(str(key_value), "-", COLOR_STOCKBOT_MUTED)
		return

	var current_price: float = float(snapshot.get("current_price", 0.0))
	var previous_close: float = float(snapshot.get("previous_close", current_price))
	var latest_bar: Dictionary = _latest_price_bar(snapshot)
	var open_price: float = float(latest_bar.get("open", previous_close))
	var high_price: float = float(latest_bar.get("high", max(open_price, current_price)))
	var low_price: float = float(latest_bar.get("low", min(open_price, current_price)))
	var volume_shares: float = max(float(latest_bar.get("volume_shares", 0.0)), 0.0)
	var volume_lots: float = max(float(latest_bar.get("volume_lots", volume_shares / float(GameManager.get_lot_size()))), 0.0)
	var traded_value: float = max(float(latest_bar.get("value", 0.0)), 0.0)
	if traded_value <= 0.0 and volume_shares > 0.0:
		traded_value = current_price * volume_shares
	var avg_price: float = traded_value / volume_shares if volume_shares > 0.0 else current_price
	var broker_flow: Dictionary = snapshot.get("broker_flow", {})
	var impactability: Dictionary = snapshot.get("impactability", {})

	_set_order_market_value("open", _format_quote_price(open_price), COLOR_STOCKBOT_AMBER)
	_set_order_market_value("high", _format_quote_price(high_price), COLOR_STOCKBOT_BULL)
	_set_order_market_value("low", _format_quote_price(low_price), COLOR_STOCKBOT_BEAR)
	_set_order_market_value("prev", _format_quote_price(previous_close), COLOR_STOCKBOT_AMBER)
	_set_order_market_value("ara", _format_quote_price(float(snapshot.get("ara_price", current_price))), COLOR_STOCKBOT_TEXT)
	_set_order_market_value("arb", _format_quote_price(float(snapshot.get("arb_price", current_price))), COLOR_STOCKBOT_MUTED)
	_set_order_market_value("lot", _format_compact_lots(volume_lots), COLOR_STOCKBOT_MUTED)
	_set_order_market_value("val", _format_compact_currency(traded_value), COLOR_STOCKBOT_MUTED)
	_set_order_market_value("avg", _format_quote_price(avg_price), COLOR_STOCKBOT_AMBER)
	_set_order_market_value("f_buy", _format_compact_currency(_broker_type_side_value(broker_flow, "foreign", "buy")), COLOR_STOCKBOT_BULL)
	_set_order_market_value("f_sell", _format_compact_currency(_broker_type_side_value(broker_flow, "foreign", "sell")), COLOR_STOCKBOT_BEAR)
	_set_order_market_value("depth", _format_compact_currency(float(impactability.get("visible_depth_value", 0.0))), COLOR_STOCKBOT_BLUE)

func _set_order_market_value(key: String, text: String, tone: Color) -> void:
	var value_label: Label = order_market_value_labels.get(key, null) as Label
	if value_label == null:
		return
	value_label.text = text
	_set_label_tone(value_label, tone)

func _on_trade_quote_label_gui_input(event: InputEvent, quote_key: String) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or not [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT].has(mouse_event.button_index):
		return
	if selected_company_id.is_empty() or current_trade_snapshot.is_empty():
		_show_toast("Pick a stock before capturing research.", false)
		return
	var payload: Dictionary = _trade_quote_capture_payload(quote_key)
	if payload.is_empty():
		_show_toast("This quote item is not ready yet.", false)
		return
	pending_capture_payloads["trade_quote"] = payload
	_show_trade_quote_capture_menu(mouse_event.global_position)

func _trade_quote_capture_payload(quote_key: String) -> Dictionary:
	var key: String = quote_key.strip_edges().to_lower()
	var label_text: String = _trade_quote_label(key)
	if label_text.is_empty():
		return {}
	var value_text: String = ""
	if key == "current_price":
		value_text = str(order_price_value_label.text).strip_edges() if order_price_value_label != null else ""
	elif key == "daily_change":
		value_text = str(order_price_change_label.text).strip_edges() if order_price_change_label != null else ""
	else:
		var value_label: Label = order_market_value_labels.get(key, null) as Label
		value_text = str(value_label.text).strip_edges() if value_label != null else ""
	if value_text.is_empty() or value_text == "-":
		return {}
	var category: String = "broker_flow" if ["f_buy", "f_sell"].has(key) else "price_action"
	var detail: String = "%s captured from the STOCKBOT trade panel for %s." % [
		label_text,
		str(current_trade_snapshot.get("ticker", selected_company_id)).to_upper()
	]
	return {
		"source_type": "trade_quote",
		"source_label": "STOCKBOT Quote",
		"category": category,
		"company_id": selected_company_id,
		"label": label_text,
		"value": value_text,
		"detail": detail,
		"source_id": "trade_quote_%s_%s" % [selected_company_id, key],
		"impact": _trade_quote_impact(key, value_text)
	}

func _trade_quote_label(quote_key: String) -> String:
	match quote_key:
		"current_price":
			return "Current price"
		"daily_change":
			return "Daily change"
		"open":
			return "Open price"
		"high":
			return "Day high"
		"low":
			return "Day low"
		"prev":
			return "Previous close"
		"ara":
			return "ARA limit"
		"arb":
			return "ARB limit"
		"lot":
			return "Traded lot"
		"val":
			return "Traded value"
		"avg":
			return "Average trade price"
		"f_buy":
			return "Foreign buy value"
		"f_sell":
			return "Foreign sell value"
		"depth":
			return "Visible depth"
	return quote_key.replace("_", " ").capitalize()

func _trade_quote_impact(quote_key: String, value_text: String) -> String:
	var key: String = quote_key.to_lower()
	var lower_value: String = value_text.to_lower()
	if key == "f_buy":
		return "positive"
	if key == "f_sell":
		return "negative"
	if key == "daily_change":
		if lower_value.find("-") != -1:
			return "negative"
		if lower_value.find("+") != -1:
			return "positive"
	return "mixed"

func _show_trade_quote_capture_menu(menu_position: Vector2) -> void:
	if trade_quote_capture_menu == null:
		trade_quote_capture_menu = PopupMenu.new()
		trade_quote_capture_menu.name = "TradeQuoteCaptureContextMenu"
		trade_quote_capture_menu.id_pressed.connect(_root._on_trade_quote_capture_menu_id_pressed)
		add_child(trade_quote_capture_menu)
	trade_quote_capture_menu.clear()
	trade_quote_capture_menu.add_item("Add to Research Tray", 1)
	trade_quote_capture_menu.position = Vector2i(int(menu_position.x), int(menu_position.y))
	trade_quote_capture_menu.popup()

func _on_trade_quote_capture_menu_id_pressed(id: int) -> void:
	_commit_pending_capture("trade_quote", id)

func _broker_type_side_value(broker_flow: Dictionary, broker_type: String, side: String) -> float:
	var normalized_side: String = "sell" if side == "sell" else "buy"
	var value_key: String = "%s_value" % normalized_side
	var type_totals: Dictionary = broker_flow.get("broker_type_totals", {})
	var type_total: Dictionary = type_totals.get(broker_type, {}) if typeof(type_totals) == TYPE_DICTIONARY else {}
	var typed_value: float = max(float(type_total.get(value_key, 0.0)), 0.0)
	if typed_value > 0.0:
		return typed_value

	var rows_key: String = "%s_brokers" % normalized_side
	return _broker_side_value_by_type(broker_flow.get(rows_key, []), broker_type, "value")

func _latest_price_bar(snapshot: Dictionary) -> Dictionary:
	var price_bars: Array = snapshot.get("price_bars", [])
	if price_bars.is_empty():
		return {}
	var latest_bar = price_bars[price_bars.size() - 1]
	if typeof(latest_bar) == TYPE_DICTIONARY:
		return latest_bar
	return {}

func _broker_side_value_by_type(rows: Array, broker_type: String, value_key: String) -> float:
	var total: float = 0.0
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("broker_type", "")) != broker_type:
			continue
		total += max(float(row.get(value_key, row.get("value", 0.0))), 0.0)
	return total

func _format_quote_price(value: float) -> String:
	return _format_grouped_integer(int(round(value)))

func _format_signed_quote_delta(value: float) -> String:
	var sign_prefix: String = "+" if value >= 0.0 else "-"
	return "%s%s" % [sign_prefix, _format_grouped_integer(int(round(absf(value))))]

func _refresh_markets() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var phase_started_at_usec: int = started_at_usec
	var company_rows: Array = _get_company_rows_cached()
	var company_row_lookup: Dictionary = _get_company_row_lookup_cached()
	_log_perf_phase(true, "_refresh_markets:rows", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_refresh_company_list(company_rows, company_row_lookup)
	_log_perf_phase(true, "_refresh_markets:company_list", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_refresh_trade_workspace()
	_log_perf_phase(true, "_refresh_markets:workspace", phase_started_at_usec)
	_log_perf_elapsed("_refresh_markets", started_at_usec)

func _refresh_after_company_selection() -> void:
	_refresh_company_selection_state()
	_refresh_trade_workspace()
	_refresh_dashboard()
	_refresh_desktop()
	if _is_desktop_app_window_open(APP_ID_THESIS):
		_refresh_thesis()
	if debug_overlay.visible:
		_refresh_debug_overlay()
	_refresh_ftue_progress()
	_refresh_first_hour_guide_progress()

func _on_company_detail_ready(company_id: String) -> void:
	if company_id.is_empty():
		return
	if company_id == selected_company_id:
		_refresh_trade_workspace()
	if debug_overlay.visible:
		_refresh_debug_overlay()

func _build_contact_intel_controls() -> void:
	if contact_intel_panel != null:
		contact_intel_panel.visible = false

func _refresh_contact_intel_controls() -> void:
	if contact_intel_option == null or contact_intel_button == null or contact_intel_status_label == null:
		return
	var previous_contact_id: String = _selected_contact_intel_contact_id()
	var state: Dictionary = GameManager.get_stock_contact_tip_options(selected_company_id)
	var rows: Array = state.get("rows", [])
	contact_intel_option.clear()
	var selected_index: int = 0
	for row_index in range(rows.size()):
		if typeof(rows[row_index]) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = rows[row_index]
		contact_intel_option.add_item(str(row.get("label", "Contact")))
		var item_index: int = contact_intel_option.get_item_count() - 1
		var contact_id: String = str(row.get("id", ""))
		contact_intel_option.set_item_metadata(item_index, contact_id)
		if contact_id == previous_contact_id:
			selected_index = item_index
	if contact_intel_option.get_item_count() > 0:
		contact_intel_option.select(clamp(selected_index, 0, contact_intel_option.get_item_count() - 1))
	var enabled: bool = bool(state.get("enabled", false)) and contact_intel_option.get_item_count() > 0
	contact_intel_option.disabled = not enabled
	contact_intel_button.disabled = not enabled
	contact_intel_button.tooltip_text = str(state.get("tooltip_text", "Ask a Network contact for a market read."))
	contact_intel_status_label.text = str(state.get("status_text", "Pick a stock first."))

func _selected_contact_intel_contact_id() -> String:
	if contact_intel_option == null or contact_intel_option.get_item_count() <= 0:
		return ""
	var selected_index: int = contact_intel_option.selected
	if selected_index < 0 or selected_index >= contact_intel_option.get_item_count():
		return ""
	var metadata = contact_intel_option.get_item_metadata(selected_index)
	return str(metadata)

func _on_contact_intel_pressed() -> void:
	var contact_id: String = _selected_contact_intel_contact_id()
	var result: Dictionary = GameManager.ask_stock_contact_tip(selected_company_id, contact_id)
	_show_toast(str(result.get("message", "Could not ask contact.")), bool(result.get("success", false)))
	_refresh_contact_intel_controls()
	if not bool(result.get("success", false)):
		return
	_refresh_network()
	_refresh_trade_workspace()

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

func _build_watchlist_lookup(watchlist_company_ids: Array = []) -> Dictionary:
	if watchlist_company_ids.is_empty():
		watchlist_company_ids = GameManager.get_watchlist_company_ids()
	var watchlist_lookup: Dictionary = {}
	for company_id_value in watchlist_company_ids:
		watchlist_lookup[str(company_id_value)] = true
	return watchlist_lookup

func _refresh_company_list(
	company_rows: Array = [],
	company_row_lookup: Dictionary = {},
	refresh_all_stock_rows: bool = true,
	refresh_portfolio_sidebar: bool = true
) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var phase_started_at_usec: int = started_at_usec
	if company_rows.is_empty() and RunState.has_active_run():
		company_rows = _get_company_rows_cached()
	if company_row_lookup.is_empty() and not company_rows.is_empty():
		company_row_lookup = _build_company_row_lookup(company_rows)
	var watchlist_lookup: Dictionary = _build_watchlist_lookup()
	_refresh_watchlist_rows(company_rows, watchlist_lookup)
	_log_perf_phase(true, "_refresh_company_list:watchlist", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	if refresh_all_stock_rows:
		if _should_refresh_all_stock_rows():
			_refresh_all_stock_rows(company_rows, watchlist_lookup)
			all_stock_rows_dirty = false
		else:
			all_stock_rows_dirty = true
	_log_perf_phase(true, "_refresh_company_list:all_stock", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	if refresh_portfolio_sidebar:
		if _should_refresh_portfolio_stock_rows():
			_refresh_portfolio_stock_rows(GameManager.get_portfolio_snapshot().get("holdings", []), company_row_lookup)
			portfolio_stock_rows_dirty = false
		else:
			portfolio_stock_rows_dirty = true
	_log_perf_phase(true, "_refresh_company_list:portfolio", phase_started_at_usec)
	_log_perf_elapsed("_refresh_company_list", started_at_usec)

func _should_refresh_all_stock_rows() -> bool:
	return stock_list_tabs.current_tab == STOCK_LIST_TAB_ALL_STOCKS

func _should_refresh_portfolio_stock_rows() -> bool:
	return stock_list_tabs.current_tab == STOCK_LIST_TAB_PORTFOLIO

func _refresh_watchlist_rows(company_rows: Array, watchlist_lookup: Dictionary) -> void:
	displayed_company_ids.clear()
	company_list.clear()
	for row_value in company_rows:
		var row: Dictionary = row_value
		var company_id: String = str(row.get("id", ""))
		if not watchlist_lookup.has(company_id):
			continue
		displayed_company_ids.append(company_id)
		var line: String = _build_stock_list_line(row)
		company_list.add_item(line)
		var item_index: int = company_list.item_count - 1
		company_list.set_item_metadata(item_index, row)
		company_list.set_item_tooltip(item_index, _watchlist_tooltip(row))
		_style_watchlist_row_item(item_index, row, false)

	var selected_index: int = displayed_company_ids.find(selected_company_id)
	if stock_list_tabs.current_tab == STOCK_LIST_TAB_WATCHLIST and selected_index == -1 and not displayed_company_ids.is_empty():
		selected_company_id = str(displayed_company_ids[0])
		selected_index = 0

	if selected_index >= 0:
		var selected_row: Dictionary = _get_watchlist_row_metadata(selected_index)
		_style_watchlist_row_item(selected_index, selected_row, true)
		company_list.select(selected_index)
	watchlist_empty_label.visible = displayed_company_ids.is_empty()
	_refresh_watchlist_action_state(watchlist_lookup)

func _get_watchlist_row_metadata(item_index: int) -> Dictionary:
	if company_list == null or item_index < 0 or item_index >= company_list.item_count:
		return {}
	var metadata = company_list.get_item_metadata(item_index)
	if metadata is Dictionary:
		return metadata
	return {}

func _style_watchlist_row_item(item_index: int, row: Dictionary, is_selected: bool) -> void:
	if company_list == null or item_index < 0 or item_index >= company_list.item_count:
		return
	var broker_flow: Dictionary = row.get("broker_flow", {})
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))
	var change_pct: float = float(row.get("daily_change_pct", 0.0))
	company_list.set_item_icon(item_index, null)
	company_list.set_item_custom_fg_color(item_index, COLOR_STOCKBOT_TEXT if is_selected else _color_for_change(change_pct))
	company_list.set_item_custom_bg_color(item_index, COLOR_STOCKBOT_BLUE_TINT if is_selected else _color_for_flow_bg(flow_tag))

func _refresh_all_stock_watchlist_button_states(watchlist_lookup: Dictionary) -> void:
	for row_box_value in all_stocks_rows.get_children():
		if row_box_value is not HBoxContainer:
			continue
		var row_box: HBoxContainer = row_box_value
		var company_id: String = str(row_box.name).trim_prefix("AllStockRow_")
		var add_button: Button = row_box.get_node_or_null("AllStockAddButton_%s" % company_id) as Button
		if add_button == null:
			continue
		var is_in_watchlist: bool = watchlist_lookup.has(company_id)
		add_button.text = "" if is_in_watchlist else "Watch"
		add_button.icon = _load_stockbot_icon("check" if is_in_watchlist else "plus")
		add_button.expand_icon = is_in_watchlist
		add_button.disabled = is_in_watchlist
		_style_stockbot_button(
			add_button,
			COLOR_STOCKBOT_SURFACE_ALT if is_in_watchlist else COLOR_STOCKBOT_BULL_TINT,
			COLOR_STOCKBOT_EDGE if is_in_watchlist else COLOR_STOCKBOT_BULL_EDGE,
			COLOR_STOCKBOT_TEXT,
			4
		)
		var add_callable: Callable = Callable(_root, "_on_add_to_watchlist_pressed").bind(company_id)
		if not is_in_watchlist and not add_button.pressed.is_connected(add_callable):
			add_button.pressed.connect(add_callable)

func _refresh_all_stock_rows(company_rows: Array, watchlist_lookup: Dictionary) -> void:
	for child in all_stocks_rows.get_children():
		all_stocks_rows.remove_child(child)
		child.queue_free()

	var search_query: String = ""
	if all_stocks_search_input != null:
		search_query = all_stocks_search_input.text.strip_edges().to_lower()
	var has_visible_rows: bool = false
	for row_value in company_rows:
		var row: Dictionary = row_value
		if not _matches_all_stock_search(row, search_query):
			continue

		has_visible_rows = true
		var company_id: String = str(row.get("id", ""))
		var line: String = _build_stock_list_line(row)
		var is_selected: bool = company_id == selected_company_id
		var is_in_watchlist: bool = watchlist_lookup.has(company_id)

		var row_box: HBoxContainer = HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 0)
		row_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_box.name = "AllStockRow_%s" % company_id

		var selected_stripe: ColorRect = ColorRect.new()
		selected_stripe.name = "AllStockSelectedStripe_%s" % company_id
		selected_stripe.custom_minimum_size = Vector2(4, 42)
		selected_stripe.color = COLOR_STOCKBOT_BLUE if is_selected else Color(COLOR_STOCKBOT_EDGE.r, COLOR_STOCKBOT_EDGE.g, COLOR_STOCKBOT_EDGE.b, 0.25)
		row_box.add_child(selected_stripe)

		var select_button: Button = Button.new()
		select_button.name = "AllStockSelectButton_%s" % company_id
		select_button.text = line
		select_button.tooltip_text = _watchlist_tooltip(row)
		select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select_button.custom_minimum_size = Vector2(0, 42)
		_style_stock_list_row_button(select_button, is_selected)
		select_button.pressed.connect(_root._on_all_stock_selected.bind(company_id))
		row_box.add_child(select_button)

		var add_button: Button = Button.new()
		add_button.name = "AllStockAddButton_%s" % company_id
		add_button.custom_minimum_size = Vector2(STOCK_LIST_ADD_BUTTON_WIDTH, 42)
		add_button.text = "" if is_in_watchlist else "Watch"
		add_button.icon = _load_stockbot_icon("check" if is_in_watchlist else "plus")
		add_button.expand_icon = is_in_watchlist
		add_button.disabled = is_in_watchlist
		_style_stockbot_button(
			add_button,
			COLOR_STOCKBOT_SURFACE_ALT if is_in_watchlist else COLOR_STOCKBOT_BULL_TINT,
			COLOR_STOCKBOT_EDGE if is_in_watchlist else COLOR_STOCKBOT_BULL_EDGE,
			COLOR_STOCKBOT_TEXT,
			4
		)
		if not is_in_watchlist:
			add_button.pressed.connect(_root._on_add_to_watchlist_pressed.bind(company_id))
		row_box.add_child(add_button)

		all_stocks_rows.add_child(row_box)

	if not has_visible_rows and not search_query.is_empty():
		var empty_label: Label = Label.new()
		empty_label.name = "AllStocksSearchEmptyLabel"
		empty_label.text = "No stocks match \"%s\"." % all_stocks_search_input.text.strip_edges()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_color_override("font_color", COLOR_MUTED)
		_apply_font_override_to_control(empty_label, DEFAULT_APP_FONT_SIZE, _get_app_font())
		all_stocks_rows.add_child(empty_label)
	_apply_font_overrides_to_subtree(all_stocks_rows)

func _matches_all_stock_search(row: Dictionary, search_query: String) -> bool:
	if search_query.is_empty():
		return true

	var searchable_text: String = "%s %s %s" % [
		str(row.get("ticker", "")),
		str(row.get("name", "")),
		str(row.get("sector_name", ""))
	]
	return searchable_text.to_lower().find(search_query) != -1

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
		select_button.pressed.connect(_root._on_portfolio_stock_selected.bind(company_id))
		portfolio_stocks_rows.add_child(select_button)

	portfolio_stocks_empty_label.visible = not has_holdings
	_apply_font_overrides_to_subtree(portfolio_stocks_rows)

func _refresh_company_selection_state() -> void:
	var selected_index: int = displayed_company_ids.find(selected_company_id)
	for item_index in range(company_list.item_count):
		var row: Dictionary = _get_watchlist_row_metadata(item_index)
		_style_watchlist_row_item(item_index, row, item_index == selected_index)
	if selected_index >= 0:
		company_list.select(selected_index)
	else:
		company_list.deselect_all()
	_refresh_watchlist_action_state()

	for row_box_value in all_stocks_rows.get_children():
		if row_box_value is not HBoxContainer:
			continue
		var row_box: HBoxContainer = row_box_value
		var company_id: String = str(row_box.name).trim_prefix("AllStockRow_")
		var selected_stripe: ColorRect = row_box.get_node_or_null("AllStockSelectedStripe_%s" % company_id) as ColorRect
		if selected_stripe != null:
			selected_stripe.color = COLOR_STOCKBOT_BLUE if company_id == selected_company_id else Color(COLOR_STOCKBOT_EDGE.r, COLOR_STOCKBOT_EDGE.g, COLOR_STOCKBOT_EDGE.b, 0.25)
		var select_button: Button = row_box.get_node_or_null("AllStockSelectButton_%s" % company_id) as Button
		if select_button == null:
			continue
		_style_stock_list_row_button(select_button, company_id == selected_company_id)

	for child in portfolio_stocks_rows.get_children():
		if child == portfolio_stocks_empty_label or child is not Button:
			continue
		var portfolio_row_button: Button = child
		var company_id: String = str(portfolio_row_button.name).trim_prefix("PortfolioSelectButton_")
		_style_stock_list_row_button(portfolio_row_button, company_id == selected_company_id)

func _refresh_watchlist_action_state(watchlist_lookup: Dictionary = {}) -> void:
	if remove_watchlist_button == null:
		return
	if watchlist_lookup.is_empty():
		for company_id_value in GameManager.get_watchlist_company_ids():
			watchlist_lookup[str(company_id_value)] = true
	remove_watchlist_button.disabled = selected_company_id.is_empty() or not watchlist_lookup.has(selected_company_id)

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

func _prioritized_company_detail_ids() -> Array:
	var prioritized_ids: Array = []
	var seen_ids: Dictionary = {}
	var candidate_ids: Array = []
	if not selected_company_id.is_empty():
		candidate_ids.append(selected_company_id)
	candidate_ids.append_array(_get_portfolio_company_ids())
	candidate_ids.append_array(GameManager.get_watchlist_company_ids())
	for company_id_value in candidate_ids:
		var company_id: String = str(company_id_value)
		if company_id.is_empty() or seen_ids.has(company_id):
			continue
		seen_ids[company_id] = true
		prioritized_ids.append(company_id)
	return prioritized_ids

func _start_background_company_detail_hydration() -> void:
	if not RunState.has_active_run():
		return
	GameManager.start_background_company_detail_hydration(_prioritized_company_detail_ids())

func _start_background_company_detail_hydration_after_startup() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_start_background_company_detail_hydration()

func _request_selected_company_detail(priority: bool = true) -> void:
	if selected_company_id.is_empty():
		return
	if str(RunState.get_company_detail_status(selected_company_id)) == "ready":
		return
	var priority_ids: Array = [selected_company_id] if priority else []
	GameManager.start_background_company_detail_hydration(priority_ids)

func _refresh_trade_workspace() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var phase_started_at_usec: int = started_at_usec
	_request_selected_company_detail()
	_log_perf_phase(true, "_refresh_trade_workspace:request_detail", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var snapshot: Dictionary = GameManager.get_company_snapshot(selected_company_id, true, true, true)
	_log_perf_phase(true, "_refresh_trade_workspace:snapshot", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_apply_trade_workspace_snapshot(snapshot)
	_log_perf_phase(true, "_refresh_trade_workspace:apply", phase_started_at_usec)
	_log_perf_elapsed("_refresh_trade_workspace", started_at_usec)

func _refresh_trade_workspace_holdings_state() -> void:
	if selected_company_id.is_empty():
		_apply_trade_workspace_snapshot({})
		return
	if current_trade_snapshot.is_empty() or str(current_trade_snapshot.get("id", "")) != selected_company_id:
		_refresh_trade_workspace()
		return

	var holdings_snapshot: Dictionary = GameManager.get_company_snapshot(selected_company_id, false, false, false)
	if holdings_snapshot.is_empty():
		_refresh_trade_workspace()
		return
	if (
		current_trade_snapshot.get("financial_history", []).is_empty() or
		current_trade_snapshot.get("financial_statement_snapshot", {}).get("quarterly_statements", []).is_empty() or
		not _broker_flow_has_rows(current_trade_snapshot.get("broker_flow", {}))
	):
		_refresh_trade_workspace()
		return

	var merged_snapshot: Dictionary = current_trade_snapshot.duplicate()
	for key_value in holdings_snapshot.keys():
		var key: String = str(key_value)
		if key == "financial_history" or key == "financial_statement_snapshot" or key == "broker_flow":
			continue
		merged_snapshot[key] = holdings_snapshot[key]
	_apply_trade_workspace_snapshot(merged_snapshot)

func _apply_trade_workspace_snapshot(snapshot: Dictionary) -> void:
	var previous_company_id: String = str(current_trade_snapshot.get("id", ""))
	var next_company_id: String = str(snapshot.get("id", ""))
	var active_tab_name: String = _trade_workspace_active_tab_name()
	var refresh_chart_now: bool = snapshot.is_empty() or previous_company_id != next_company_id or active_tab_name == "Chart"
	current_trade_snapshot = snapshot
	if previous_company_id != next_company_id:
		_reset_trade_workspace_detail_caches()
	trade_workspace_widget.set_company_snapshot(snapshot, refresh_chart_now)
	if snapshot.is_empty():
		current_trade_snapshot = {}
		_reset_trade_workspace_detail_caches()
		selected_financial_statement_company_id = ""
		selected_financial_statement_index = -1
		active_order_side = "buy"
		order_company_name_label.text = "-"
		selection_label.text = "-"
		selection_label.visible = false
		order_price_value_label.text = "0"
		order_price_change_label.text = "+0 (+0.00%)"
		order_position_label.text = ""
		order_position_label.visible = false
		_refresh_order_market_summary({})
		order_title_label.text = "Buy Order"
		order_price_line_edit.text = ""
		estimated_total_value_label.text = _format_currency(0.0)
		buy_button.disabled = true
		sell_button.disabled = true
		submit_order_button.disabled = true
		submit_order_button.text = "Submit Buy Order"
		_set_label_tone(order_price_change_label, COLOR_MUTED)
		_set_label_tone(estimated_total_value_label, COLOR_MUTED)
		_update_order_side_buttons()
		profile_company_name_label.text = "No selection"
		profile_sector_label.text = "Sector:"
		profile_price_label.text = ""
		profile_price_label.visible = false
		profile_factor_label.text = ""
		profile_management_label.text = "Management:"
		profile_shareholders_label.text = "Shareholders:"
		profile_tags_label.text = "Tags:"
		profile_description_label.text = "Description:"
		_refresh_profile_company_layout({}, false)
		profile_network_hint_label.text = ""
		profile_network_hint_label.visible = false
		profile_meet_contact_button.visible = false
		profile_meet_contact_button.disabled = true
		profile_meet_contact_button.set_meta("contact_id", "")
		key_stats_financial_label.text = "Financials:"
		financials_year_label.text = ""
		financials_year_label.visible = false
		financials_period_label.text = "Viewing latest available period."
		broker_summary_label.text = ""
		broker_summary_label.visible = false
		broker_meter_label.text = ""
		broker_meter_label.visible = false
		broker_meter_bar.value = 50.0
		analyzer_setup_label.text = "Setup read:"
		analyzer_support_label.text = "Supportive signals:"
		analyzer_risk_label.text = "Risk signals:"
		analyzer_event_label.text = "Visible inputs:"
		analyzer_history_label.text = "Recent closes:"
		financial_history_summary_label.text = "Generated history unavailable."
		_refresh_financial_history_table([], {})
		_refresh_key_stats_dashboard({})
		_refresh_broker_table({})
		_refresh_corporate_action_timeline({})
		_refresh_statement_sections({})
		_refresh_contact_intel_controls()
		return

	var detail_status: String = str(snapshot.get("detail_status", "ready"))
	var detail_ready: bool = detail_status == "ready"
	var financial_statement_snapshot: Dictionary = snapshot.get("financial_statement_snapshot", {}) if detail_ready else {}
	if (
		selected_financial_statement_company_id != next_company_id or
		selected_financial_statement_index < 0
	):
		_sync_financial_statement_selection(str(snapshot.get("id", "")), financial_statement_snapshot)
	var next_profile_cache_key: String = _trade_workspace_profile_snapshot_key(snapshot, financial_statement_snapshot)
	var next_financial_history_cache_key: String = _trade_workspace_financial_history_snapshot_key(snapshot)
	var next_key_stats_cache_key: String = _trade_workspace_key_stats_snapshot_key(snapshot)
	var next_broker_cache_key: String = _trade_workspace_broker_snapshot_key(snapshot)
	var next_statement_cache_key: String = _trade_workspace_statement_snapshot_key(snapshot, financial_statement_snapshot)
	var refresh_profile_panels: bool = next_profile_cache_key != trade_workspace_profile_cache_key
	var refresh_financial_history_panel: bool = next_financial_history_cache_key != trade_workspace_financial_history_cache_key
	var refresh_key_stats_panel: bool = (
		next_key_stats_cache_key != trade_workspace_key_stats_cache_key and
		(active_tab_name == "KeyStats" or trade_workspace_key_stats_cache_key.is_empty())
	)
	var refresh_broker_panel: bool = next_broker_cache_key != trade_workspace_broker_cache_key
	var refresh_statement_panel: bool = next_statement_cache_key != trade_workspace_statement_cache_key
	lot_spin_box.set_value_no_signal(float(_selected_lots()))
	profile_company_name_label.text = "%s  |  %s" % [snapshot.get("ticker", ""), snapshot.get("name", "")]
	profile_sector_label.text = "Sector: %s  |  Archetype: %s  |  Size: %s  |  Board: %s" % [
		snapshot.get("sector_name", "Unknown"),
		str(snapshot.get("archetype_label", "Unclassified")),
		str(snapshot.get("company_size_label", "Unknown")),
		str(snapshot.get("listing_board", "main")).capitalize()
	]
	profile_price_label.text = ""
	profile_price_label.visible = false
	var profile_background_text: String = _build_profile_background_text(snapshot, detail_ready)
	if detail_ready:
		profile_factor_label.text = "Company profile: founded %d  |  age %dy  |  employees %s  |  revenue %s" % [
			int(snapshot.get("founded_year", 0)),
			int(snapshot.get("company_age", 0)),
			_format_grouped_integer(int(snapshot.get("employee_count", 0))),
			_format_compact_currency(float(snapshot.get("profile_revenue", 0.0)))
		]
		profile_tags_label.text = "Tags: %s" % _join_or_default(snapshot.get("profile_tags", []), "none")
	else:
		profile_factor_label.text = "Company profile: preparing company profile..."
		profile_tags_label.text = "Tags: preparing company tags..."
	profile_management_label.text = _format_profile_management(snapshot)
	profile_shareholders_label.text = _format_profile_shareholders(snapshot)
	profile_description_label.text = "Description: %s" % profile_background_text
	if refresh_profile_panels:
		trade_workspace_profile_cache_key = next_profile_cache_key
		_refresh_profile_company_layout(snapshot, detail_ready)
		_refresh_profile_network_contact(str(snapshot.get("id", "")))
	key_stats_financial_label.text = "Financials:\n%s" % _format_financial_block(snapshot.get("financials", {}))
	financials_year_label.text = ""
	financials_year_label.visible = false
	analyzer_setup_label.text = "Setup read:\n%s" % _build_setup_read(snapshot)
	analyzer_support_label.text = "Supportive signals:\n%s" % _build_support_signals(snapshot)
	analyzer_risk_label.text = "Risk signals:\n%s" % _build_risk_signals(snapshot)
	analyzer_event_label.text = "Visible inputs:\nEvent tags: %s\nNarratives: %s" % [
		_join_or_default(snapshot.get("event_tags", []), "none today"),
		_join_or_default(snapshot.get("narrative_tags", []), "none")
	]
	analyzer_history_label.text = "Recent closes:\n%s" % _format_history(snapshot.get("price_history", []))
	financial_history_summary_label.text = (
		_format_financial_history_summary(snapshot.get("financial_history", []), snapshot.get("financials", {}))
		if detail_ready
		else "Generating company detail..."
	)
	if refresh_financial_history_panel:
		trade_workspace_financial_history_cache_key = next_financial_history_cache_key
		_refresh_financial_history_table(
			snapshot.get("financial_history", []),
			snapshot.get("financials", {}),
			"Generating company detail..." if not detail_ready else ""
		)
	if refresh_key_stats_panel:
		trade_workspace_key_stats_cache_key = next_key_stats_cache_key
		_refresh_key_stats_dashboard(snapshot if detail_ready else {})
	if refresh_broker_panel:
		trade_workspace_broker_cache_key = next_broker_cache_key
		_refresh_broker_table(_broker_range_flow_for_snapshot(snapshot))
	if active_tab_name == "CorporateActions":
		_refresh_trade_workspace_corporate_action_timeline(true)
	if refresh_statement_panel:
		trade_workspace_statement_cache_key = next_statement_cache_key
		_refresh_statement_sections(financial_statement_snapshot)
	if not detail_ready:
		financials_period_label.text = "Detailed quarterly statements will appear once the company profile finishes generating."
	_refresh_order_controls(snapshot)

func _reset_trade_workspace_detail_caches() -> void:
	trade_workspace_detail_cache_key = ""
	trade_workspace_profile_cache_key = ""
	trade_workspace_financial_history_cache_key = ""
	trade_workspace_key_stats_cache_key = ""
	trade_workspace_broker_cache_key = ""
	trade_workspace_corporate_action_cache_key = ""
	trade_workspace_statement_cache_key = ""

func _trade_workspace_active_tab_name() -> String:
	if work_tabs == null:
		return ""
	var tab_index: int = int(work_tabs.current_tab)
	if tab_index < 0 or tab_index >= work_tabs.get_child_count():
		return ""
	var tab_control := work_tabs.get_child(tab_index)
	return str(tab_control.name) if tab_control != null else ""

func _refresh_visible_trade_workspace_tab() -> void:
	if current_trade_snapshot.is_empty():
		return
	var active_tab_name: String = _trade_workspace_active_tab_name()
	var detail_ready: bool = str(current_trade_snapshot.get("detail_status", "ready")) == "ready"
	var financial_statement_snapshot: Dictionary = current_trade_snapshot.get("financial_statement_snapshot", {}) if detail_ready else {}
	match active_tab_name:
		"Chart":
			trade_workspace_widget.set_company_snapshot(current_trade_snapshot, true)
		"KeyStats":
			var next_key_stats_cache_key: String = _trade_workspace_key_stats_snapshot_key(current_trade_snapshot)
			if next_key_stats_cache_key != trade_workspace_key_stats_cache_key:
				trade_workspace_key_stats_cache_key = next_key_stats_cache_key
				_refresh_key_stats_dashboard(current_trade_snapshot if detail_ready else {})
			var next_financial_history_cache_key: String = _trade_workspace_financial_history_snapshot_key(current_trade_snapshot)
			if next_financial_history_cache_key != trade_workspace_financial_history_cache_key:
				trade_workspace_financial_history_cache_key = next_financial_history_cache_key
				_refresh_financial_history_table(
					current_trade_snapshot.get("financial_history", []),
					current_trade_snapshot.get("financials", {}),
					"Generating company detail..." if not detail_ready else ""
				)
		"Financials":
			_sync_financial_statement_selection(str(current_trade_snapshot.get("id", "")), financial_statement_snapshot)
			var next_statement_cache_key: String = _trade_workspace_statement_snapshot_key(current_trade_snapshot, financial_statement_snapshot)
			if next_statement_cache_key != trade_workspace_statement_cache_key:
				trade_workspace_statement_cache_key = next_statement_cache_key
				_refresh_statement_sections(financial_statement_snapshot)
		"Broker":
			var next_broker_cache_key: String = _trade_workspace_broker_snapshot_key(current_trade_snapshot)
			if next_broker_cache_key != trade_workspace_broker_cache_key:
				trade_workspace_broker_cache_key = next_broker_cache_key
				_refresh_broker_table(_broker_range_flow_for_snapshot(current_trade_snapshot))
		"CorporateActions":
			_refresh_trade_workspace_corporate_action_timeline(true)
		"Profile":
			var next_profile_cache_key: String = _trade_workspace_profile_snapshot_key(current_trade_snapshot, financial_statement_snapshot)
			if next_profile_cache_key != trade_workspace_profile_cache_key:
				trade_workspace_profile_cache_key = next_profile_cache_key
				_refresh_profile_company_layout(current_trade_snapshot, detail_ready)
				_refresh_profile_network_contact(str(current_trade_snapshot.get("id", "")))

func _refresh_trade_workspace_corporate_action_timeline(force_refresh: bool = false) -> void:
	if current_trade_snapshot.is_empty():
		_refresh_corporate_action_timeline({})
		trade_workspace_corporate_action_cache_key = ""
		return
	var timeline_snapshot: Dictionary = GameManager.get_company_corporate_action_timeline(str(current_trade_snapshot.get("id", "")))
	var next_corporate_action_cache_key: String = _trade_workspace_corporate_action_snapshot_key(timeline_snapshot)
	if force_refresh or next_corporate_action_cache_key != trade_workspace_corporate_action_cache_key:
		trade_workspace_corporate_action_cache_key = next_corporate_action_cache_key
		_refresh_corporate_action_timeline(timeline_snapshot)

func _ensure_profile_company_layout() -> void:
	if profile_background_card != null:
		return
	var profile_vbox: VBoxContainer = profile_description_label.get_parent() as VBoxContainer
	if profile_vbox == null:
		return

	var legacy_nodes: Array = [
		profile_vbox.get_node_or_null("ProfileTitle"),
		profile_company_name_label,
		profile_sector_label,
		profile_price_label,
		profile_factor_label,
		profile_management_label,
		profile_shareholders_label,
		profile_tags_label,
		profile_description_label,
		profile_network_hint_label,
		profile_meet_contact_button
	]
	for node_value in legacy_nodes:
		var node: Control = node_value as Control
		if node != null:
			node.visible = false

	profile_background_card = _build_profile_card("ProfileBackgroundCard")
	var background_vbox: VBoxContainer = profile_background_card.get_meta("content_vbox") as VBoxContainer
	profile_background_title_label = _build_profile_title_label("Company Background")
	profile_background_title_label.name = "ProfileBackgroundTitleLabel"
	background_vbox.add_child(profile_background_title_label)
	profile_background_meta_label = _build_profile_body_label("", COLOR_MUTED)
	profile_background_meta_label.name = "ProfileBackgroundMetaLabel"
	background_vbox.add_child(profile_background_meta_label)
	profile_background_body_label = _build_profile_body_label("", COLOR_TEXT)
	profile_background_body_label.name = "ProfileBackgroundBodyLabel"
	profile_background_body_label.mouse_filter = Control.MOUSE_FILTER_STOP
	profile_background_body_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	profile_background_body_label.tooltip_text = "Click to open research actions."
	profile_background_body_label.gui_input.connect(_root._on_profile_background_gui_input)
	background_vbox.add_child(profile_background_body_label)
	profile_tags_flow = HFlowContainer.new()
	profile_tags_flow.name = "ProfileTagsFlow"
	profile_tags_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_tags_flow.add_theme_constant_override("h_separation", 6)
	profile_tags_flow.add_theme_constant_override("v_separation", 6)
	background_vbox.add_child(profile_tags_flow)
	profile_vbox.add_child(profile_background_card)

	profile_shareholder_card = _build_profile_card("ProfileShareholderCard")
	var shareholder_vbox: VBoxContainer = profile_shareholder_card.get_meta("content_vbox") as VBoxContainer
	var shareholder_header := HBoxContainer.new()
	shareholder_header.name = "ProfileShareholderHeader"
	shareholder_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shareholder_header.add_theme_constant_override("separation", 8)
	profile_shareholder_title_label = _build_profile_title_label("Shareholders")
	profile_shareholder_title_label.name = "ProfileShareholderTitleLabel"
	shareholder_header.add_child(profile_shareholder_title_label)
	var shareholder_spacer := Control.new()
	shareholder_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shareholder_header.add_child(shareholder_spacer)
	profile_shareholder_updated_label = _build_profile_body_label("", COLOR_MUTED)
	profile_shareholder_updated_label.name = "ProfileShareholderUpdatedLabel"
	profile_shareholder_updated_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shareholder_header.add_child(profile_shareholder_updated_label)
	shareholder_vbox.add_child(shareholder_header)
	profile_shareholder_rows = VBoxContainer.new()
	profile_shareholder_rows.name = "ProfileShareholderRows"
	profile_shareholder_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_shareholder_rows.add_theme_constant_override("separation", 0)
	shareholder_vbox.add_child(profile_shareholder_rows)
	profile_vbox.add_child(profile_shareholder_card)

	profile_management_card = _build_profile_card("ProfileManagementCard")
	var management_vbox: VBoxContainer = profile_management_card.get_meta("content_vbox") as VBoxContainer
	profile_management_title_label = _build_profile_title_label("Management")
	profile_management_title_label.name = "ProfileManagementTitleLabel"
	management_vbox.add_child(profile_management_title_label)
	profile_management_rows = VBoxContainer.new()
	profile_management_rows.name = "ProfileManagementRows"
	profile_management_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_management_rows.add_theme_constant_override("separation", 0)
	management_vbox.add_child(profile_management_rows)
	profile_vbox.add_child(profile_management_card)
	_style_profile_company_layout()

func _build_profile_card(card_name: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = card_name
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.name = "%sMargin" % card_name
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)
	var content_vbox := VBoxContainer.new()
	content_vbox.name = "%sVBox" % card_name
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(content_vbox)
	card.set_meta("content_vbox", content_vbox)
	return card

func _build_profile_title_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE + 2)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	_apply_font_override_to_control(label, DEFAULT_APP_FONT_SIZE + 2, _get_app_font())
	return label

func _build_profile_body_label(text_value: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	_apply_font_override_to_control(label, DEFAULT_APP_FONT_SIZE, _get_app_font())
	return label

func _style_profile_company_layout() -> void:
	for card_value in [profile_background_card, profile_shareholder_card, profile_management_card]:
		var card: PanelContainer = card_value as PanelContainer
		if card != null:
			_style_stockbot_panel(card, COLOR_STOCKBOT_SURFACE_ALT, COLOR_STOCKBOT_EDGE, 6, 1)
	for label_value in [profile_background_title_label, profile_shareholder_title_label, profile_management_title_label]:
		var label: Label = label_value as Label
		if label != null:
			_set_label_tone(label, COLOR_STOCKBOT_TEXT)
	for label_value in [profile_background_meta_label, profile_shareholder_updated_label]:
		var label: Label = label_value as Label
		if label != null:
			_set_label_tone(label, COLOR_STOCKBOT_MUTED)
	if profile_background_body_label != null:
		_set_label_tone(profile_background_body_label, COLOR_STOCKBOT_TEXT)

func _refresh_profile_company_layout(snapshot: Dictionary, detail_ready: bool) -> void:
	_ensure_profile_company_layout()
	if profile_background_card == null:
		return
	if snapshot.is_empty():
		profile_background_title_label.text = "Company Background"
		profile_background_meta_label.text = "Select a company to view public background, tags, shareholders, and management."
		profile_background_body_label.text = ""
		profile_background_body_label.tooltip_text = ""
		_refresh_profile_tags([])
		_refresh_profile_shareholder_table({})
		_refresh_profile_management_table({})
		return

	profile_background_title_label.text = "Company Background"
	var index_snapshot: Dictionary = snapshot.get("index_review", {})
	var meta_parts: Array = [
		str(snapshot.get("ticker", "")),
		str(snapshot.get("sector_name", "Unknown")),
		str(snapshot.get("archetype_label", "Unclassified")),
		"%s board" % str(snapshot.get("listing_board", "main")).capitalize()
	]
	var index_summary: String = str(index_snapshot.get("summary_label", "")).strip_edges()
	if not index_summary.is_empty():
		meta_parts.append(index_summary)
	profile_background_meta_label.text = " | ".join(meta_parts)
	profile_background_body_label.text = _build_profile_background_text(snapshot, detail_ready)
	profile_background_body_label.tooltip_text = "Click to add this company background to the Research Tray." if detail_ready else ""
	var profile_tags: Array = snapshot.get("profile_tags", []).duplicate() if detail_ready else []
	for membership_label_value in index_snapshot.get("membership_labels", []):
		var membership_label: String = str(membership_label_value).strip_edges()
		if not membership_label.is_empty():
			profile_tags.append("%s member" % membership_label)
	for candidate_label_value in index_snapshot.get("candidate_labels", []):
		var candidate_label: String = str(candidate_label_value).strip_edges()
		if not candidate_label.is_empty():
			profile_tags.append(candidate_label)
	_refresh_profile_tags(profile_tags)
	_refresh_profile_shareholder_table(snapshot)
	_refresh_profile_management_table(snapshot)

func _refresh_profile_tags(tags: Array) -> void:
	if profile_tags_flow == null:
		return
	_clear_profile_container(profile_tags_flow)
	for tag_value in tags:
		var tag_text: String = str(tag_value).strip_edges()
		if tag_text.is_empty():
			continue
		profile_tags_flow.add_child(_build_profile_tag_pill(tag_text))

func _build_profile_tag_pill(tag_text: String) -> PanelContainer:
	var pill := PanelContainer.new()
	var style := _make_stockbot_stylebox(COLOR_STOCKBOT_BLUE_TINT, COLOR_STOCKBOT_BLUE_EDGE, 6, 1, 6)
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	pill.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = tag_text if tag_text.contains("MSCY") or tag_text.contains("FTSI") else tag_text.replace("_", " ").capitalize()
	label.add_theme_color_override("font_color", COLOR_STOCKBOT_BLUE)
	label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	_apply_font_override_to_control(label, DEFAULT_APP_FONT_SIZE, _get_app_font())
	pill.add_child(label)
	return pill

func _refresh_profile_shareholder_table(snapshot: Dictionary) -> void:
	if profile_shareholder_rows == null:
		return
	_clear_profile_container(profile_shareholder_rows)
	var updated_date: String = GameManager.format_trade_date(RunState.get_current_trade_date()) if RunState.has_active_run() else "-"
	profile_shareholder_updated_label.text = "Updated %s" % updated_date
	profile_shareholder_rows.add_child(_build_profile_table_row(
		["Name", "Total Shares", "Percentage"],
		[240.0, 136.0, 92.0],
		true,
		[1, 2]
	))
	var rows: Array = snapshot.get("shareholder_rows", [])
	var shares_outstanding: float = max(float(snapshot.get("shares_outstanding", 0.0)), 0.0)
	var added_count: int = 0
	for row_value in rows:
		var row: Dictionary = row_value
		var ownership_pct: float = float(row.get("ownership_pct", 0.0))
		if ownership_pct <= 0.0:
			continue
		profile_shareholder_rows.add_child(_build_profile_table_row(
			[
				str(row.get("name", "")),
				_format_grouped_integer(int(round(shares_outstanding * ownership_pct))),
				_format_percent_value(ownership_pct * 100.0)
			],
			[240.0, 136.0, 92.0],
			false,
			[1, 2],
			_profile_shareholder_capture_payload(row, ownership_pct, shares_outstanding)
		))
		added_count += 1
	if added_count == 0:
		profile_shareholder_rows.add_child(_build_profile_empty_row("No shareholder breakdown is visible yet."))

func _refresh_profile_management_table(snapshot: Dictionary) -> void:
	if profile_management_rows == null:
		return
	_clear_profile_container(profile_management_rows)
	profile_management_rows.add_child(_build_profile_table_row(
		["Role", "Name", "Public Status"],
		[140.0, 220.0, 130.0],
		true,
		[]
	))
	if str(snapshot.get("detail_status", "ready")) != "ready":
		profile_management_rows.add_child(_build_profile_empty_row("Preparing company roster..."))
		return
	var roster: Array = snapshot.get("management_roster", [])
	if roster.is_empty():
		profile_management_rows.add_child(_build_profile_empty_row("Management roster has not been generated for this company."))
		return
	var network_snapshot: Dictionary = GameManager.get_network_snapshot()
	for management_value in roster:
		if typeof(management_value) != TYPE_DICTIONARY:
			continue
		var management: Dictionary = management_value
		var contact_id: String = str(management.get("id", management.get("contact_id", "")))
		profile_management_rows.add_child(_build_profile_table_row(
			[
				str(management.get("role_label", management.get("role", "Management"))),
				str(management.get("display_name", "")),
				_network_state_for_contact(network_snapshot, contact_id).capitalize()
			],
			[140.0, 220.0, 130.0],
			false,
			[],
			_profile_management_capture_payload(management, _network_state_for_contact(network_snapshot, contact_id))
		))

func _build_profile_table_row(
	cells: Array,
	widths: Array,
	header: bool,
	right_aligned_columns: Array = [],
	capture_payload: Dictionary = {}
) -> Control:
	var row := HBoxContainer.new()
	row.name = "ProfileTableHeaderRow" if header else "ProfileTableRow"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	if not capture_payload.is_empty():
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.tooltip_text = "Click to open research actions."
		row.gui_input.connect(_root._on_profile_capture_row_gui_input.bind(capture_payload.duplicate(true)))
	for index in range(cells.size()):
		var width: float = float(widths[index]) if index < widths.size() else 90.0
		var alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_RIGHT if right_aligned_columns.has(index) else HORIZONTAL_ALIGNMENT_LEFT
		var color: Color = COLOR_STOCKBOT_AMBER if header else (COLOR_STOCKBOT_MUTED if index == 0 else COLOR_STOCKBOT_TEXT)
		var expand: bool = index == 0
		var cell: Label = _build_table_cell(str(cells[index]), width, color, expand, alignment)
		if not capture_payload.is_empty():
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(cell)
	return row

func _on_profile_background_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or not [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT].has(mouse_event.button_index):
		return
	if selected_company_id.is_empty() or current_trade_snapshot.is_empty():
		_show_toast("Pick a stock before capturing research.", false)
		return
	var body: String = str(profile_background_body_label.text).strip_edges() if profile_background_body_label != null else ""
	if body.is_empty() or body.to_lower().begins_with("preparing"):
		_show_toast("Company background is not ready yet.", false)
		return
	var ticker: String = str(current_trade_snapshot.get("ticker", selected_company_id)).strip_edges()
	pending_capture_payloads["profile"] = {
		"source_type": "company_profile",
		"category": "fundamentals",
		"company_id": selected_company_id,
		"label": "Business description",
		"value": ticker,
		"detail": body,
		"source_id": "profile_description_%s" % selected_company_id
	}
	_show_profile_capture_menu(mouse_event.global_position)

func _profile_shareholder_capture_payload(row: Dictionary, ownership_pct: float, shares_outstanding: float) -> Dictionary:
	if selected_company_id.is_empty():
		return {}
	var holder_name: String = str(row.get("name", "")).strip_edges()
	if holder_name.is_empty():
		return {}
	var label: String = "Free float" if holder_name.to_lower().find("public float") != -1 else "%s ownership" % holder_name
	var percent_text: String = _format_percent_value(ownership_pct * 100.0)
	var shares_text: String = _format_grouped_integer(int(round(shares_outstanding * ownership_pct)))
	var role: String = str(row.get("role", "shareholder")).strip_edges()
	var detail: String = "%s holds %s of shares outstanding (%s share(s))." % [
		holder_name,
		percent_text,
		shares_text
	]
	if not role.is_empty():
		detail += " Public role: %s." % role
	if holder_name.to_lower().find("public float") != -1:
		detail += " Free float shapes liquidity, crowding, and how easily larger orders can move the tape."
	return {
		"source_type": "company_profile",
		"category": "ownership",
		"company_id": selected_company_id,
		"label": label,
		"value": percent_text,
		"detail": detail,
		"source_id": "profile_shareholder_%s_%s" % [selected_company_id, _node_token(holder_name)]
	}

func _profile_management_capture_payload(management: Dictionary, network_state: String) -> Dictionary:
	if selected_company_id.is_empty():
		return {}
	var display_name: String = str(management.get("display_name", "")).strip_edges()
	if display_name.is_empty():
		return {}
	var role_label: String = str(management.get("role_label", management.get("role", "Management"))).strip_edges()
	if role_label.is_empty():
		role_label = "Management"
	var intro: String = str(management.get("intro", "")).strip_edges()
	var tone: String = str(management.get("tone", "")).strip_edges()
	var reliability: float = float(management.get("reliability", 0.0))
	var detail_parts: Array = []
	if not intro.is_empty():
		detail_parts.append(intro)
	if not tone.is_empty():
		detail_parts.append("Public tone: %s." % tone)
	if reliability > 0.0:
		var track_record_label: String = "strong" if reliability >= 0.72 else ("mixed" if reliability >= 0.54 else "limited")
		detail_parts.append("Public track record: %s." % track_record_label)
	if not network_state.strip_edges().is_empty():
		detail_parts.append("Contact status: %s." % network_state.capitalize())
	return {
		"source_type": "company_profile",
		"category": "management",
		"company_id": selected_company_id,
		"label": "%s: %s" % [role_label, display_name],
		"value": role_label,
		"detail": " ".join(detail_parts),
		"source_id": "profile_management_%s_%s" % [
			selected_company_id,
			_node_token(str(management.get("id", management.get("contact_id", display_name))))
		]
	}

func _on_profile_capture_row_gui_input(event: InputEvent, capture_payload: Dictionary) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or not [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT].has(mouse_event.button_index):
		return
	if capture_payload.is_empty():
		return
	pending_capture_payloads["profile"] = capture_payload.duplicate(true)
	_show_profile_capture_menu(mouse_event.global_position)

func _show_profile_capture_menu(menu_position: Vector2) -> void:
	if profile_capture_menu == null:
		profile_capture_menu = PopupMenu.new()
		profile_capture_menu.name = "ProfileCaptureContextMenu"
		profile_capture_menu.id_pressed.connect(_root._on_profile_capture_menu_id_pressed)
		add_child(profile_capture_menu)
	profile_capture_menu.clear()
	profile_capture_menu.add_item("Add to Research Tray", 1)
	profile_capture_menu.position = Vector2i(int(menu_position.x), int(menu_position.y))
	profile_capture_menu.popup()

func _on_profile_capture_menu_id_pressed(id: int) -> void:
	_commit_pending_capture("profile", id)

func _build_profile_empty_row(message: String) -> Control:
	var row_wrap := VBoxContainer.new()
	var label := _build_profile_body_label(message, COLOR_MUTED)
	row_wrap.add_child(label)
	return row_wrap

func _build_profile_background_text(snapshot: Dictionary, detail_ready: bool) -> String:
	if not detail_ready:
		return "Preparing company background..."
	var company_name: String = str(snapshot.get("name", "This company"))
	var founded_year: int = int(snapshot.get("founded_year", 0))
	var sector_name: String = str(snapshot.get("sector_name", "its sector"))
	var archetype_label: String = str(snapshot.get("archetype_label", "listed company"))
	var description: String = str(snapshot.get("profile_description", "")).strip_edges()
	var intro: String = "%s is a %s listing in %s." % [company_name, archetype_label, sector_name]
	if founded_year > 0:
		intro = "%s was founded in %d and operates as a %s listing in %s." % [
			company_name,
			founded_year,
			archetype_label,
			sector_name
		]
	var scale_sentence: String = _profile_scale_sentence(snapshot)
	var read_sentence: String = " %s" % _profile_operating_read(snapshot)
	var footprint_sentence: String = _profile_footprint_sentence(snapshot)
	var roadmap_sentence: String = _profile_roadmap_sentence(snapshot)
	if description.is_empty():
		return "%s%s%s%s%s" % [intro, scale_sentence, footprint_sentence, roadmap_sentence, read_sentence]
	return "%s %s%s%s%s%s" % [intro, description, scale_sentence, footprint_sentence, roadmap_sentence, read_sentence]

func _profile_scale_sentence(snapshot: Dictionary) -> String:
	var employee_count: int = int(snapshot.get("employee_count", 0))
	var profile_revenue: float = float(snapshot.get("profile_revenue", 0.0))
	if employee_count > 0 and profile_revenue > 0.0:
		return " It employs about %s people and generates roughly %s in annual revenue." % [
			_format_grouped_integer(employee_count),
			_format_compact_currency(profile_revenue)
		]
	if employee_count > 0:
		return " It employs about %s people." % _format_grouped_integer(employee_count)
	if profile_revenue > 0.0:
		return " It generates roughly %s in annual revenue." % _format_compact_currency(profile_revenue)
	return ""

func _profile_footprint_sentence(snapshot: Dictionary) -> String:
	var location_profile: Dictionary = snapshot.get("location_profile", {})
	if location_profile.is_empty():
		return ""
	var footprint: String = str(location_profile.get("public_footprint", "")).strip_edges()
	if not footprint.is_empty():
		return _profile_sentence_from_fragment(_profile_clean_footprint_phrase(footprint))
	var hq_label: String = str(location_profile.get("hq_location_label", "")).strip_edges()
	if hq_label.is_empty():
		return ""
	return " Based in %s." % hq_label

func _profile_clean_footprint_phrase(footprint: String) -> String:
	var phrase: String = footprint.strip_edges()
	if phrase.begins_with("Headquartered in "):
		phrase = "Based in %s" % phrase.substr("Headquartered in ".length())
	phrase = phrase.replace(" with operating exposure around ", ", with operations around ")
	phrase = phrase.replace(" with a focused Indonesian operating footprint", ", with a focused Indonesian operating footprint")
	return phrase

func _profile_roadmap_sentence(snapshot: Dictionary) -> String:
	var roadmap_profile: Dictionary = snapshot.get("roadmap_profile", {})
	if roadmap_profile.is_empty():
		return ""
	var priority: String = str(roadmap_profile.get("public_priority", "")).strip_edges()
	if priority.is_empty():
		return ""
	var detail: String = str(roadmap_profile.get("public_priority_detail", "")).strip_edges()
	var phrase: String = _profile_clean_priority_phrase(detail if not detail.is_empty() else priority)
	if phrase.is_empty():
		return ""
	return " Management is focused on %s." % phrase

func _profile_clean_priority_phrase(priority_text: String) -> String:
	var phrase: String = priority_text.strip_edges()
	if phrase.begins_with("Public roadmap focus:"):
		phrase = phrase.substr("Public roadmap focus:".length()).strip_edges()
	if phrase.ends_with("."):
		phrase = phrase.substr(0, phrase.length() - 1).strip_edges()
	phrase = phrase.replace(" tied to the company's Indonesian operating base", " across its Indonesian operating base")
	phrase = phrase.replace(" tied to its Indonesian operating base", " across its Indonesian operating base")
	return phrase

func _profile_sentence_from_fragment(fragment: String) -> String:
	var sentence: String = fragment.strip_edges()
	if sentence.is_empty():
		return ""
	if not sentence.ends_with(".") and not sentence.ends_with("!") and not sentence.ends_with("?"):
		sentence += "."
	return " %s" % sentence

func _profile_operating_read(snapshot: Dictionary) -> String:
	var quality: int = int(snapshot.get("quality_score", 0))
	var growth: int = int(snapshot.get("growth_score", 0))
	var risk: int = int(snapshot.get("risk_score", 0))
	var execution_read: String = "the operating base still needs confirmation"
	if quality >= 70:
		execution_read = "the operating base looks durable"
	elif quality >= 58:
		execution_read = "the operating base looks serviceable"
	elif quality <= 45:
		execution_read = "the operating base looks fragile"
	var expansion_read: String = "expansion signals look steady"
	if growth >= 68:
		expansion_read = "expansion signals look active"
	elif growth <= 45:
		expansion_read = "expansion signals look muted"
	var uncertainty_read: String = "uncertainty should still be checked against filings and tape"
	if risk >= 65:
		uncertainty_read = "uncertainty demands tighter confirmation before sizing up"
	elif risk <= 35:
		uncertainty_read = "uncertainty looks relatively contained"
	return "At a glance, %s, %s, and %s." % [
		execution_read,
		expansion_read,
		uncertainty_read
	]

func _clear_profile_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _refresh_profile_network_contact(_company_id: String) -> void:
	profile_network_hint_label.text = ""
	profile_network_hint_label.visible = false
	profile_meet_contact_button.visible = false
	profile_meet_contact_button.disabled = true
	profile_meet_contact_button.text = "Meet Contact"
	profile_meet_contact_button.set_meta("contact_id", "")
	return

func _format_profile_management(snapshot: Dictionary) -> String:
	if str(snapshot.get("detail_status", "ready")) != "ready":
		return "Management: preparing company roster..."
	var roster: Array = snapshot.get("management_roster", [])
	if roster.is_empty():
		return "Management: not generated for this company yet."
	var network_snapshot: Dictionary = GameManager.get_network_snapshot()
	var lines: Array = ["Management:"]
	for management_value in roster:
		if typeof(management_value) != TYPE_DICTIONARY:
			continue
		var management: Dictionary = management_value
		var contact_id: String = str(management.get("id", management.get("contact_id", "")))
		lines.append("%s: %s (%s)" % [
			str(management.get("role_label", management.get("role", "Management"))),
			str(management.get("display_name", "")),
			_network_state_for_contact(network_snapshot, contact_id)
		])
	return "\n".join(lines)

func _format_profile_shareholders(snapshot: Dictionary) -> String:
	var rows: Array = snapshot.get("shareholder_rows", [])
	var player_ownership_pct: float = float(snapshot.get("ownership_pct", 0.0))
	var lines: Array = ["Shareholders:"]
	for row_value in rows:
		var row: Dictionary = row_value
		lines.append("%s: %s ownership (%s)" % [
			str(row.get("name", "")),
			_format_percent_value(float(row.get("ownership_pct", 0.0)) * 100.0),
			str(row.get("role", "holder"))
		])
	if player_ownership_pct > 0.0 and not bool(snapshot.get("is_major_shareholder", false)):
		lines.append("Player: %s ownership" % _format_percent_value(player_ownership_pct * 100.0))
	return "\n".join(lines)

func _broker_flow_has_rows(broker_flow: Dictionary) -> bool:
	return (
		not broker_flow.get("buy_brokers", []).is_empty() or
		not broker_flow.get("sell_brokers", []).is_empty() or
		not broker_flow.get("net_buy_brokers", []).is_empty() or
		not broker_flow.get("net_sell_brokers", []).is_empty()
	)

func _trade_workspace_detail_snapshot_key(snapshot: Dictionary, financial_statement_snapshot: Dictionary) -> String:
	if snapshot.is_empty():
		return ""
	var broker_flow: Dictionary = snapshot.get("broker_flow", {})
	var financial_history: Array = snapshot.get("financial_history", [])
	var quarterly_statements: Array = financial_statement_snapshot.get("quarterly_statements", [])
	var buy_brokers: Array = broker_flow.get("buy_brokers", [])
	var sell_brokers: Array = broker_flow.get("sell_brokers", [])
	var net_buy_brokers: Array = broker_flow.get("net_buy_brokers", [])
	var net_sell_brokers: Array = broker_flow.get("net_sell_brokers", [])
	return "%s|%s|%d|%d|%d|%d|%d|%d|%s|%s|%s" % [
		str(snapshot.get("id", "")),
		str(snapshot.get("detail_status", "ready")),
		RunState.day_index,
		financial_history.size(),
		quarterly_statements.size(),
		buy_brokers.size(),
		sell_brokers.size(),
		net_buy_brokers.size() + net_sell_brokers.size(),
		str(broker_flow.get("flow_tag", "")),
		str(broker_flow.get("dominant_buy_broker_code", "")),
		str(broker_flow.get("dominant_sell_broker_code", ""))
	]

func _trade_workspace_profile_snapshot_key(snapshot: Dictionary, financial_statement_snapshot: Dictionary) -> String:
	if snapshot.is_empty():
		return ""
	var quarterly_statements: Array = financial_statement_snapshot.get("quarterly_statements", [])
	var financial_history: Array = snapshot.get("financial_history", [])
	var profile_tags: Array = snapshot.get("profile_tags", [])
	var shareholder_rows: Array = snapshot.get("shareholder_rows", [])
	var management_rows: Array = snapshot.get("management_roster", [])
	var location_profile: Dictionary = snapshot.get("location_profile", {})
	var roadmap_profile: Dictionary = snapshot.get("roadmap_profile", {})
	return "%s|%s|%d|%d|%d|%d|%d|%d|%s|%s|%s" % [
		str(snapshot.get("id", "")),
		str(snapshot.get("detail_status", "ready")),
		profile_tags.size(),
		shareholder_rows.size(),
		management_rows.size(),
		str(snapshot.get("profile_description", "")).length(),
		financial_history.size(),
		quarterly_statements.size(),
		str(location_profile.get("hq_location_id", "")),
		str(roadmap_profile.get("primary_family_id", "")),
		str(roadmap_profile.get("public_priority", "")).length()
	]

func _trade_workspace_financial_history_snapshot_key(snapshot: Dictionary) -> String:
	if snapshot.is_empty():
		return ""
	var financial_history: Array = snapshot.get("financial_history", [])
	var financials: Dictionary = snapshot.get("financials", {})
	return "%s|%s|%d|%s|%s" % [
		str(snapshot.get("id", "")),
		str(snapshot.get("detail_status", "ready")),
		financial_history.size(),
		str(financials.get("history_start_year", "")),
		str(financials.get("history_end_year", ""))
	]

func _trade_workspace_key_stats_snapshot_key(snapshot: Dictionary) -> String:
	if snapshot.is_empty():
		return ""
	var financials: Dictionary = snapshot.get("financials", {})
	return "%s|%s|%d|%s|%s|%s|%s|%s|%s|%s|%s" % [
		str(snapshot.get("id", "")),
		str(snapshot.get("detail_status", "ready")),
		RunState.day_index,
		str(snapshot.get("current_price", "")),
		str(snapshot.get("previous_close", "")),
		str(snapshot.get("daily_change_pct", "")),
		str(financials.get("market_cap", "")),
		str(financials.get("net_income", "")),
		str(financials.get("revenue", "")),
		str(financials.get("eps", "")),
		selected_key_stats_metric
	]

func _broker_range_flow_for_snapshot(snapshot: Dictionary) -> Dictionary:
	if snapshot.is_empty():
		return {}
	var company_id: String = str(snapshot.get("id", ""))
	if company_id.is_empty():
		return {}
	var range_flow: Dictionary = GameManager.get_company_broker_flow_snapshot(company_id, selected_broker_range_id)
	if range_flow.is_empty():
		return snapshot.get("broker_flow", {}).duplicate(true) if typeof(snapshot.get("broker_flow", {})) == TYPE_DICTIONARY else {}
	return range_flow

func _trade_workspace_broker_snapshot_key(snapshot: Dictionary) -> String:
	if snapshot.is_empty():
		return ""
	var broker_flow: Dictionary = _broker_range_flow_for_snapshot(snapshot)
	return "%s|%d|%s|%s|%s|%s|%s|%s|%s|%s|%d|%s|%s" % [
		str(snapshot.get("id", "")),
		RunState.day_index,
		str(broker_net_mode),
		selected_broker_range_id,
		str(broker_flow.get("flow_tag", "")),
		str(broker_flow.get("action_meter_score", "")),
		str(broker_flow.get("dominant_buy_broker_code", "")),
		str(broker_flow.get("dominant_sell_broker_code", "")),
		_broker_rows_signature(broker_flow.get("net_buy_brokers", []) if broker_net_mode else broker_flow.get("buy_brokers", [])),
		_broker_rows_signature(broker_flow.get("net_sell_brokers", []) if broker_net_mode else broker_flow.get("sell_brokers", [])),
		int(broker_flow.get("range_day_count", 0)),
		str(broker_flow.get("history_mode", "")),
		str(broker_flow.get("broker_trade_value", ""))
	]

func _trade_workspace_statement_snapshot_key(snapshot: Dictionary, financial_statement_snapshot: Dictionary) -> String:
	if snapshot.is_empty():
		return ""
	var quarterly_statements: Array = financial_statement_snapshot.get("quarterly_statements", [])
	var selected_period: Dictionary = _selected_statement_period(financial_statement_snapshot) if not financial_statement_snapshot.is_empty() else {}
	return "%s|%s|%d|%d|%s" % [
		str(snapshot.get("id", "")),
		str(snapshot.get("detail_status", "ready")),
		quarterly_statements.size(),
		selected_financial_statement_index,
		str(selected_period.get("statement_period_label", selected_period.get("period_label", "")))
	]

func _trade_workspace_corporate_action_snapshot_key(timeline_snapshot: Dictionary) -> String:
	if timeline_snapshot.is_empty():
		return ""
	var rows: Array = timeline_snapshot.get("rows", [])
	var first_row_id: String = ""
	var last_row_id: String = ""
	if not rows.is_empty() and typeof(rows.front()) == TYPE_DICTIONARY:
		var first_row: Dictionary = rows.front()
		first_row_id = str(first_row.get("id", first_row.get("source_id", "")))
	if not rows.is_empty() and typeof(rows.back()) == TYPE_DICTIONARY:
		var last_row: Dictionary = rows.back()
		last_row_id = str(last_row.get("id", last_row.get("source_id", "")))
	return "%s|%d|%d|%s|%s|%s" % [
		str(timeline_snapshot.get("company_id", "")),
		RunState.day_index,
		rows.size(),
		first_row_id,
		last_row_id,
		corporate_action_filter_id
	]

func _broker_rows_signature(rows: Array) -> String:
	var total_value: float = 0.0
	var total_lots: float = 0.0
	var first_code: String = ""
	var last_code: String = ""
	for row_index in range(rows.size()):
		if typeof(rows[row_index]) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = rows[row_index]
		if first_code.is_empty():
			first_code = str(row.get("code", ""))
		last_code = str(row.get("code", last_code))
		total_value += float(row.get("value", 0.0))
		total_lots += float(row.get("lots", 0.0))
	return "%d|%s|%s|%.0f|%.0f" % [rows.size(), first_code, last_code, total_value, total_lots]

func _populate_watchlist_picker() -> void:
	if watchlist_picker_list == null:
		return

	watchlist_picker_company_ids.clear()
	watchlist_picker_list.clear()
	var watchlist_lookup: Dictionary = {}
	for company_id_value in GameManager.get_watchlist_company_ids():
		watchlist_lookup[str(company_id_value)] = true

	for row_value in _get_company_rows_cached():
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

func _on_stock_list_tab_changed(_tab_index: int) -> void:
	if suppress_stock_list_tab_refresh:
		suppress_stock_list_tab_refresh = false
		return
	var started_at_usec: int = Time.get_ticks_usec()
	var previous_selected_company_id: String = selected_company_id
	_sync_selected_company_with_active_stock_list()
	if stock_list_tabs.current_tab == STOCK_LIST_TAB_ALL_STOCKS and all_stock_rows_dirty:
		_refresh_all_stock_rows(_get_company_rows_cached(), _build_watchlist_lookup())
		all_stock_rows_dirty = false
	elif stock_list_tabs.current_tab == STOCK_LIST_TAB_PORTFOLIO and portfolio_stock_rows_dirty:
		_refresh_portfolio_stock_rows(GameManager.get_portfolio_snapshot().get("holdings", []), _get_company_row_lookup_cached())
		portfolio_stock_rows_dirty = false
	_refresh_company_selection_state()
	if selected_company_id != previous_selected_company_id:
		_refresh_trade_workspace()
		_refresh_dashboard()
		_refresh_desktop()
		if debug_overlay.visible:
			_refresh_debug_overlay()
		_start_background_company_detail_hydration()
	_log_perf_elapsed("_on_stock_list_tab_changed", started_at_usec)
	_mark_guide_watchlist_all_stock_seen()
	_refresh_ftue_progress()

func _on_work_tab_changed(tab_index: int) -> void:
	_refresh_visible_trade_workspace_tab()
	_record_steam_stockbot_tab_view(_current_work_tab_title())
	_mark_guide_fundamental_tab_seen(tab_index)
	_refresh_ftue_progress()
	_refresh_first_hour_guide_progress()

func _on_add_watchlist_pressed() -> void:
	if not RunState.has_active_run():
		return

	_populate_watchlist_picker()
	watchlist_picker_dialog.popup_centered(Vector2i(720, 520))

func _on_remove_watchlist_pressed() -> void:
	if selected_company_id.is_empty():
		_show_toast("Pick a watchlist stock first.", false)
		return

	var removed_company_id: String = selected_company_id
	var result: Dictionary = GameManager.remove_company_from_watchlist(removed_company_id)
	_show_toast(str(result.get("message", "Watchlist updated.")), bool(result.get("success", false)))
	if not bool(result.get("success", false)):
		return

func _on_watchlist_picker_confirmed() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
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
	_queue_watchlist_refresh_override(company_id, STOCK_LIST_TAB_WATCHLIST)
	var result: Dictionary = GameManager.add_company_to_watchlist(company_id)
	if not bool(result.get("success", false)):
		_clear_watchlist_refresh_override()
	_show_toast(str(result.get("message", "Watchlist updated.")), bool(result.get("success", false)))
	if bool(result.get("success", false)):
		if watchlist_picker_dialog != null:
			watchlist_picker_dialog.hide()
		_refresh_first_hour_guide_progress()
	_log_perf_elapsed("_on_watchlist_picker_confirmed", started_at_usec)

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
	_mark_guide_watchlist_stock_selected()

func _on_portfolio_stock_selected(company_id: String) -> void:
	selected_company_id = company_id
	_refresh_after_company_selection()

func _on_add_to_watchlist_pressed(company_id: String) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var result: Dictionary = GameManager.add_company_to_watchlist(company_id)
	_show_toast(str(result.get("message", "Watchlist updated.")), bool(result.get("success", false)))
	if bool(result.get("success", false)):
		_refresh_first_hour_guide_progress()
	_log_perf_elapsed("_on_add_to_watchlist_pressed", started_at_usec)

func _on_all_stock_search_text_changed(_new_text: String) -> void:
	_refresh_company_list(_get_company_rows_cached(), _get_company_row_lookup_cached(), true, false)
	all_stock_rows_dirty = false

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
	_refresh_ftue_overlay()

func _on_sell_side_pressed() -> void:
	active_order_side = "sell"
	_update_order_side_buttons()
	if not current_trade_snapshot.is_empty():
		_refresh_order_controls(current_trade_snapshot)
	_refresh_ftue_overlay()

func _on_submit_order_pressed() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var result: Dictionary = {}
	if active_order_side == "sell":
		result = GameManager.sell_lots(selected_company_id, _selected_lots())
	else:
		result = GameManager.buy_lots(selected_company_id, _selected_lots())
	status_message = str(result.get("message", "Order finished."))
	_show_toast(status_message, bool(result.get("success", false)))
	if bool(result.get("success", false)):
		_refresh_ftue_progress()
		_refresh_first_hour_guide_progress()
	_log_perf_elapsed("_on_submit_order_pressed", started_at_usec)

func _on_lot_size_changed(value: float) -> void:
	selected_lots = max(int(round(value)), 1)
	_refresh_sidebar()
	if not current_trade_snapshot.is_empty():
		_refresh_order_controls(current_trade_snapshot)
	_refresh_ftue_overlay()

func _refresh_order_controls(snapshot: Dictionary) -> void:
	var current_lots: int = _selected_lots()
	var lot_size: int = GameManager.get_lot_size()
	var shares_owned: int = int(snapshot.get("shares_owned", 0))
	var buy_estimate: Dictionary = GameManager.estimate_buy_lots(selected_company_id, current_lots)
	var sell_estimate: Dictionary = GameManager.estimate_sell_lots(selected_company_id, current_lots)
	var portfolio: Dictionary = GameManager.get_portfolio_snapshot()
	var available_cash: float = float(portfolio.get("cash", 0.0))
	var max_sellable_lots: int = int(floor(float(shares_owned) / float(lot_size)))
	var buy_total_cost: float = float(buy_estimate.get("total_cost", 0.0))
	var buy_block_reason: String = GameManager.get_life_action_block_reason("buy") if RunState.has_active_run() else ""
	var sell_block_reason: String = GameManager.get_life_action_block_reason("sell") if RunState.has_active_run() else ""
	var can_buy: bool = bool(buy_estimate.get("success", false)) and buy_total_cost <= available_cash + 0.0001
	var can_sell: bool = bool(sell_estimate.get("success", false)) and max_sellable_lots >= current_lots
	if not buy_block_reason.is_empty():
		can_buy = false
	if not sell_block_reason.is_empty():
		can_sell = false
	var current_price: float = float(snapshot.get("current_price", 0.0))
	var previous_close: float = float(snapshot.get("previous_close", current_price))
	var price_change_value: float = current_price - previous_close
	var active_estimate: Dictionary = sell_estimate if active_order_side == "sell" else buy_estimate
	var estimated_total: float = float(active_estimate.get("net_proceeds", 0.0)) if active_order_side == "sell" else float(active_estimate.get("total_cost", 0.0))
	var can_submit: bool = can_sell if active_order_side == "sell" else can_buy
	var active_block_reason: String = sell_block_reason if active_order_side == "sell" else buy_block_reason
	var impactability: Dictionary = snapshot.get("impactability", {})
	var order_impact_hint: Dictionary = _build_order_impact_hint(snapshot, active_estimate, active_order_side)

	order_company_name_label.text = str(snapshot.get("ticker", "-")).to_upper()
	selection_label.text = str(snapshot.get("name", ""))
	selection_label.visible = false
	order_price_value_label.text = _format_quote_price(current_price)
	order_price_change_label.text = "%s (%s)" % [
		_format_signed_quote_delta(price_change_value),
		_format_change(float(snapshot.get("daily_change_pct", 0.0)))
	]
	order_position_label.text = ""
	order_position_label.tooltip_text = ""
	order_position_label.visible = false
	_refresh_order_market_summary(snapshot)

	order_title_label.text = "Sell Order" if active_order_side == "sell" else "Buy Order"
	order_price_line_edit.text = _format_currency(current_price)
	estimated_total_value_label.text = _format_currency(estimated_total)
	if not str(order_impact_hint.get("label", "")).is_empty():
		estimated_total_value_label.text += "  |  %s" % str(order_impact_hint.get("label", ""))
	if not active_block_reason.is_empty():
		estimated_total_value_label.text += "  |  Blocked"
	estimated_total_value_label.tooltip_text = active_block_reason if not active_block_reason.is_empty() else str(order_impact_hint.get("detail", impactability.get("detail", "")))
	submit_order_button.text = "Submit Sell Order" if active_order_side == "sell" else "Submit Buy Order"
	submit_order_button.disabled = not can_submit
	buy_button.disabled = not sell_block_reason.is_empty() and not buy_block_reason.is_empty()
	sell_button.disabled = buy_button.disabled
	submit_order_button.tooltip_text = active_block_reason if not active_block_reason.is_empty() else "Submit the active order."
	_refresh_submit_order_button_style()
	_update_order_side_buttons()
	_set_label_tone(order_price_change_label, _color_for_change(float(snapshot.get("daily_change_pct", 0.0))))
	var estimate_tone: Color = COLOR_TEXT if can_submit else COLOR_MUTED
	if can_submit and str(order_impact_hint.get("tone", "")) == "warning":
		estimate_tone = COLOR_WARNING
	_set_label_tone(estimated_total_value_label, estimate_tone)
	_refresh_contact_intel_controls()

func _build_order_impact_hint(snapshot: Dictionary, active_estimate: Dictionary, side: String) -> Dictionary:
	var impactability: Dictionary = snapshot.get("impactability", {})
	if impactability.is_empty():
		return {}

	var order_value: float = float(active_estimate.get("net_proceeds", 0.0)) if side == "sell" else float(active_estimate.get("total_cost", 0.0))
	if order_value <= 0.0:
		return {}

	var depth_key: String = "bid_depth_value" if side == "sell" else "ask_depth_value"
	var side_depth_value: float = max(float(impactability.get(depth_key, 0.0)), 0.0)
	if side_depth_value <= 0.0:
		side_depth_value = max(float(impactability.get("visible_depth_value", 0.0)), float(impactability.get("avg_daily_value", 1.0)))
	var depth_ratio: float = order_value / max(side_depth_value, 1.0)
	var adv_ratio: float = order_value / max(float(impactability.get("avg_daily_value", 1.0)), 1.0)
	var float_ratio: float = order_value / max(float(impactability.get("free_float_value", 1.0)), 1.0)
	var side_text: String = "bid" if side == "sell" else "ask"
	var detail: String = "Order is %.2fx %s depth, %.2fx ADV, %.2f%% of free-float value." % [
		depth_ratio,
		side_text,
		adv_ratio,
		float_ratio * 100.0
	]
	if depth_ratio >= 1.0 or float_ratio >= 0.006:
		return {
			"label": "Large vs depth",
			"tone": "warning",
			"detail": detail
		}
	if depth_ratio >= 0.35 or adv_ratio >= 0.20:
		return {
			"label": "Visible flow",
			"tone": "warning",
			"detail": detail
		}
	return {
		"label": "",
		"tone": str(impactability.get("tone", "")),
		"detail": detail
	}

func _selected_lots() -> int:
	return max(selected_lots, 1)

func _update_order_side_buttons() -> void:
	buy_button.set_pressed_no_signal(active_order_side == "buy")
	sell_button.set_pressed_no_signal(active_order_side == "sell")
	_style_stockbot_button(buy_button, COLOR_STOCKBOT_BULL_TINT, COLOR_STOCKBOT_BULL_EDGE, COLOR_STOCKBOT_TEXT, 6, active_order_side == "buy")
	_style_stockbot_button(sell_button, COLOR_STOCKBOT_BEAR_TINT, COLOR_STOCKBOT_BEAR_EDGE, COLOR_STOCKBOT_TEXT, 6, active_order_side == "sell")
	_refresh_submit_order_button_style()

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

func _load_stockbot_icon(icon_id: String) -> Texture2D:
	if stockbot_icon_cache.has(icon_id):
		return stockbot_icon_cache.get(icon_id, null) as Texture2D
	var icon_path: String = str(STOCKBOT_ICON_PATHS.get(icon_id, ""))
	if icon_path.is_empty():
		return null
	if not ResourceLoader.exists(icon_path) and not FileAccess.file_exists(icon_path):
		return null
	var icon_resource := load(icon_path)
	if icon_resource is Texture2D:
		var texture := icon_resource as Texture2D
		stockbot_icon_cache[icon_id] = texture
		return texture
	return null

func _make_stockbot_stylebox(
	fill_color: Color,
	border_color: Color,
	corner_radius: int = 6,
	border_width: int = 1,
	content_margin: int = 0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	return style

func _set_stockbot_margins(margin_container: MarginContainer, left: int, top: int, right: int, bottom: int) -> void:
	if margin_container == null:
		return
	margin_container.add_theme_constant_override("margin_left", left)
	margin_container.add_theme_constant_override("margin_top", top)
	margin_container.add_theme_constant_override("margin_right", right)
	margin_container.add_theme_constant_override("margin_bottom", bottom)

func _set_stockbot_spacing(container: Container, separation: int) -> void:
	if container == null:
		return
	container.add_theme_constant_override("separation", separation)
	container.add_theme_constant_override("h_separation", separation)
	container.add_theme_constant_override("v_separation", separation)

func _style_stockbot_panel(
	panel: PanelContainer,
	fill_color: Color = COLOR_STOCKBOT_SURFACE,
	border_color: Color = COLOR_STOCKBOT_EDGE,
	corner_radius: int = 0,
	border_width: int = 1
) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", _make_stockbot_stylebox(fill_color, border_color, corner_radius, border_width))

func _style_stockbot_button(
	button: Button,
	fill_color: Color,
	border_color: Color,
	font_color: Color = COLOR_STOCKBOT_TEXT,
	corner_radius: int = 6,
	selected: bool = false
) -> void:
	if button == null:
		return
	var normal := _make_stockbot_stylebox(fill_color, border_color, corner_radius, 1, 3 if button.text.is_empty() else 6)
	var hover := normal.duplicate()
	hover.bg_color = fill_color.lightened(0.08)
	var pressed := normal.duplicate()
	pressed.bg_color = COLOR_STOCKBOT_BLUE_TINT if selected else fill_color.darkened(0.08)
	pressed.border_color = COLOR_STOCKBOT_BLUE if selected else border_color.lightened(0.12)
	pressed.set_border_width_all(2 if selected else 1)
	var disabled := normal.duplicate()
	disabled.bg_color = Color(fill_color.r, fill_color.g, fill_color.b, 0.45)
	disabled.border_color = Color(border_color.r, border_color.g, border_color.b, 0.42)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", COLOR_STOCKBOT_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_STOCKBOT_TEXT)
	button.add_theme_color_override("font_focus_color", COLOR_STOCKBOT_TEXT)
	button.add_theme_color_override("font_disabled_color", Color(COLOR_STOCKBOT_MUTED.r, COLOR_STOCKBOT_MUTED.g, COLOR_STOCKBOT_MUTED.b, 0.58))
	button.add_theme_color_override("icon_normal_color", font_color)
	button.add_theme_color_override("icon_hover_color", COLOR_STOCKBOT_TEXT)
	button.add_theme_color_override("icon_pressed_color", COLOR_STOCKBOT_TEXT)
	button.add_theme_color_override("icon_focus_color", COLOR_STOCKBOT_TEXT)
	button.add_theme_color_override("icon_hover_pressed_color", COLOR_STOCKBOT_TEXT)
	button.add_theme_color_override("icon_disabled_color", Color(COLOR_STOCKBOT_MUTED.r, COLOR_STOCKBOT_MUTED.g, COLOR_STOCKBOT_MUTED.b, 0.58))

func _style_stockbot_icon_button(
	button: Button,
	icon_id: String,
	text_value: String = "",
	tooltip_value: String = "",
	selected: bool = false,
	fill_color: Color = COLOR_STOCKBOT_SURFACE_ALT,
	border_color: Color = COLOR_STOCKBOT_EDGE
) -> void:
	if button == null:
		return
	button.icon = _load_stockbot_icon(icon_id)
	button.text = text_value
	button.tooltip_text = tooltip_value
	button.expand_icon = text_value.is_empty()
	button.add_theme_constant_override("h_separation", 7)
	button.add_theme_constant_override("icon_max_width", 22)
	_style_stockbot_button(button, fill_color, border_color, COLOR_STOCKBOT_TEXT, 6, selected)

func _style_stockbot_label_chip(
	label: Label,
	fill_color: Color,
	border_color: Color,
	font_color: Color,
	corner_radius: int = 6
) -> void:
	if label == null:
		return
	label.add_theme_stylebox_override("normal", _make_stockbot_stylebox(fill_color, border_color, corner_radius, 1, 7))
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_font_size_override("font_size", 12)

func _apply_stockbot_compact_spacing() -> void:
	_set_stockbot_margins(top_bar_panel.get_node_or_null("TopBarMargin") as MarginContainer, 8, 6, 8, 6)
	_set_stockbot_spacing(top_bar_panel.get_node_or_null("TopBarMargin/TopBarVBox") as Container, 4)
	_set_stockbot_spacing(top_bar_panel.get_node_or_null("TopBarMargin/TopBarVBox/TitleRow") as Container, 8)
	_set_stockbot_margins(watchlist_panel.get_node_or_null("WatchlistMargin") as MarginContainer, 6, 6, 6, 6)
	_set_stockbot_spacing(stock_list_tabs.get_node_or_null("WatchlistTab/WatchlistActionRow") as Container, 6)
	_set_stockbot_spacing(stock_list_tabs.get_node_or_null("WatchlistTab") as Container, 6)
	_set_stockbot_spacing(stock_list_tabs.get_node_or_null("AllStocksTab") as Container, 6)
	_set_stockbot_spacing(all_stocks_rows, 0)
	_set_stockbot_spacing(portfolio_stocks_rows, 0)
	_set_stockbot_margins(action_panel.get_node_or_null("ActionMargin") as MarginContainer, 8, 8, 8, 8)
	_set_stockbot_spacing(action_panel.get_node_or_null("ActionMargin/ActionVBox") as Container, 8)
	_set_stockbot_spacing(action_panel.get_node_or_null("ActionMargin/ActionVBox/HeaderVBox") as Container, 5)
	_set_stockbot_spacing(action_panel.get_node_or_null("ActionMargin/ActionVBox/HeaderVBox/MarketHeaderRow") as Container, 6)
	_set_stockbot_spacing(action_panel.get_node_or_null("ActionMargin/ActionVBox/HeaderVBox/MarketStatGrid") as Container, 4)
	_set_stockbot_spacing(action_panel.get_node_or_null("ActionMargin/ActionVBox/TradeButtonRow") as Container, 6)
	_set_stockbot_margins(order_card_panel.get_node_or_null("OrderCardMargin") as MarginContainer, 9, 9, 9, 9)
	_set_stockbot_spacing(order_card_panel.get_node_or_null("OrderCardMargin/OrderCardVBox") as Container, 7)

func _ensure_stockbot_detail_section_cards() -> void:
	_ensure_financials_section_cards()
	_ensure_broker_section_cards()

func _ensure_financials_section_cards() -> void:
	if financials_panel == null:
		return
	var financials_vbox: VBoxContainer = financials_panel.get_node_or_null("FinancialsMargin/FinancialsVBox") as VBoxContainer
	if financials_vbox == null:
		return
	_set_stockbot_spacing(financials_vbox, 10)
	_ensure_financials_statement_card(
		financials_vbox,
		"IncomeStatementCard",
		"IncomeStatementTitle",
		income_statement_rows_vbox,
		"IncomeStatementSeparator"
	)
	_ensure_financials_statement_card(
		financials_vbox,
		"BalanceSheetCard",
		"BalanceSheetTitle",
		balance_sheet_rows_vbox,
		"BalanceSheetSeparator"
	)
	_ensure_financials_statement_card(
		financials_vbox,
		"CashFlowCard",
		"CashFlowTitle",
		cash_flow_rows_vbox,
		""
	)

func _ensure_financials_statement_card(
	financials_vbox: VBoxContainer,
	card_name: String,
	title_name: String,
	rows_vbox: VBoxContainer,
	separator_name: String
) -> void:
	if financials_vbox == null or rows_vbox == null:
		return
	var existing_card: PanelContainer = financials_vbox.get_node_or_null(card_name) as PanelContainer
	if existing_card != null:
		_style_stockbot_panel(existing_card, COLOR_STOCKBOT_SURFACE_ALT, COLOR_STOCKBOT_EDGE, 6, 1)
		return
	var title_node: Control = financials_vbox.get_node_or_null(title_name) as Control
	if title_node == null:
		return
	if not separator_name.is_empty():
		var separator: Control = financials_vbox.get_node_or_null(separator_name) as Control
		if separator != null:
			separator.visible = false
	var insert_index: int = title_node.get_index()
	_move_nodes_into_stockbot_detail_card(financials_vbox, card_name, [title_node, rows_vbox], insert_index)

func _ensure_broker_section_cards() -> void:
	if broker_panel == null:
		return
	var broker_vbox: VBoxContainer = broker_panel.get_node_or_null("BrokerMargin/BrokerVBox") as VBoxContainer
	if broker_vbox == null:
		return
	_ensure_broker_range_controls()
	_set_stockbot_spacing(broker_vbox, 10)
	var scale_row: Control = null
	if broker_scale_left_label != null:
		scale_row = broker_scale_left_label.get_parent() as Control
	var controls_row: Control = null
	if broker_net_toggle != null:
		controls_row = broker_net_toggle.get_parent() as Control
	var read_insert_index: int = broker_vbox.get_child_count()
	for node_value in [broker_summary_label, broker_meter_label, broker_meter_bar, scale_row, controls_row]:
		var node: Control = node_value as Control
		if node != null and node.get_parent() == broker_vbox:
			read_insert_index = node.get_index()
			break
	_move_nodes_into_stockbot_detail_card(
		broker_vbox,
		"BrokerReadCard",
		[broker_summary_label, broker_meter_label, broker_meter_bar, scale_row, controls_row],
		read_insert_index
	)
	var separator: Control = broker_vbox.get_node_or_null("BrokerSeparator") as Control
	if separator != null:
		separator.visible = false
	var tape_insert_index: int = broker_header_row.get_index() if broker_header_row != null and broker_header_row.get_parent() == broker_vbox else broker_vbox.get_child_count()
	_move_nodes_into_stockbot_detail_card(
		broker_vbox,
		"BrokerTapeCard",
		[broker_header_row, broker_rows_vbox],
		tape_insert_index
	)

func _build_stockbot_detail_section_card(card_name: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = card_name
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_stockbot_panel(card, COLOR_STOCKBOT_SURFACE_ALT, COLOR_STOCKBOT_EDGE, 6, 1)
	var margin := MarginContainer.new()
	margin.name = "%sMargin" % card_name
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	var content_vbox := VBoxContainer.new()
	content_vbox.name = "%sVBox" % card_name
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(content_vbox)
	card.set_meta("content_vbox", content_vbox)
	return card

func _move_nodes_into_stockbot_detail_card(
	parent_vbox: VBoxContainer,
	card_name: String,
	nodes: Array,
	insert_index: int
) -> PanelContainer:
	var existing_card: PanelContainer = parent_vbox.get_node_or_null(card_name) as PanelContainer
	if existing_card != null:
		_style_stockbot_panel(existing_card, COLOR_STOCKBOT_SURFACE_ALT, COLOR_STOCKBOT_EDGE, 6, 1)
		return existing_card
	var card: PanelContainer = _build_stockbot_detail_section_card(card_name)
	parent_vbox.add_child(card)
	parent_vbox.move_child(card, clampi(insert_index, 0, parent_vbox.get_child_count() - 1))
	var content_vbox: VBoxContainer = card.get_meta("content_vbox") as VBoxContainer
	for node_value in nodes:
		var node: Control = node_value as Control
		if node == null:
			continue
		if node.get_parent() == content_vbox:
			continue
		var current_parent: Node = node.get_parent()
		if current_parent != null:
			current_parent.remove_child(node)
		content_vbox.add_child(node)
	return card

func _style_stockbot_app_ui() -> void:
	_apply_stockbot_compact_spacing()
	_style_stockbot_panel(stock_window_container, COLOR_STOCKBOT_BASE, COLOR_STOCKBOT_BLUE_EDGE, 0, 1)
	_style_stockbot_panel(top_bar_panel, COLOR_STOCKBOT_BASE, COLOR_STOCKBOT_BLUE_EDGE, 0, 0)
	_style_stockbot_panel(sidebar_panel, COLOR_STOCKBOT_BASE, COLOR_STOCKBOT_EDGE, 0, 0)
	_style_stockbot_panel(watchlist_panel, COLOR_STOCKBOT_SURFACE, COLOR_STOCKBOT_EDGE, 0, 1)
	_style_stockbot_panel(work_area_panel, COLOR_STOCKBOT_BASE, COLOR_STOCKBOT_EDGE, 0, 1)
	_style_stockbot_panel(action_panel, COLOR_STOCKBOT_SURFACE, COLOR_STOCKBOT_EDGE, 0, 1)
	_style_stockbot_panel(order_card_panel, COLOR_STOCKBOT_BASE, COLOR_STOCKBOT_EDGE_STRONG, 6, 1)
	_style_stockbot_panel(key_stats_panel, COLOR_STOCKBOT_SURFACE, COLOR_STOCKBOT_EDGE, 6, 1)
	_style_stockbot_panel(financials_panel, COLOR_STOCKBOT_SURFACE, COLOR_STOCKBOT_EDGE, 6, 1)
	_style_stockbot_panel(broker_panel, COLOR_STOCKBOT_SURFACE, COLOR_STOCKBOT_EDGE, 6, 1)
	_style_stockbot_panel(analyzer_panel, COLOR_STOCKBOT_SURFACE, COLOR_STOCKBOT_EDGE, 6, 1)
	_style_stockbot_panel(corporate_actions_panel, COLOR_STOCKBOT_SURFACE, COLOR_STOCKBOT_EDGE, 6, 1)
	_style_stockbot_panel(profile_panel, COLOR_STOCKBOT_SURFACE, COLOR_STOCKBOT_EDGE, 6, 1)
	_ensure_stockbot_detail_section_cards()
	_style_stockbot_static_panel_labels()

	_style_stockbot_label_chip(top_market_label, COLOR_STOCKBOT_BLUE_TINT, COLOR_STOCKBOT_BLUE_EDGE, _color_for_change(RunState.market_sentiment))
	_style_stockbot_label_chip(top_equity_label, COLOR_STOCKBOT_SURFACE_ALT, COLOR_STOCKBOT_EDGE_STRONG, COLOR_STOCKBOT_TEXT)
	_style_stockbot_label_chip(top_cash_label, COLOR_STOCKBOT_SURFACE_ALT, COLOR_STOCKBOT_EDGE_STRONG, COLOR_STOCKBOT_BLUE)
	_style_stockbot_label_chip(top_section_label, COLOR_STOCKBOT_SURFACE_ALT, COLOR_STOCKBOT_EDGE_STRONG, COLOR_STOCKBOT_AMBER)

	_style_tab_container(stock_list_tabs, 0)
	_style_tab_container(work_tabs, 0)
	_refresh_broker_range_buttons()
	_style_stockbot_icon_button(add_watchlist_button, "plus", "Watch", "Add the selected stock to your watchlist.", false, COLOR_STOCKBOT_BLUE_TINT, COLOR_STOCKBOT_BLUE_EDGE)
	_style_stockbot_icon_button(remove_watchlist_button, "trash", "Remove", "Remove the selected stock from your watchlist.", false, COLOR_STOCKBOT_BEAR_TINT, COLOR_STOCKBOT_BEAR_EDGE)
	_style_stockbot_icon_button(
		order_ticket_toggle_button,
		"chevron_up" if order_ticket_collapsed else "chevron_down",
		"",
		"Show the order ticket." if order_ticket_collapsed else "Hide the order ticket.",
		false,
		COLOR_STOCKBOT_SURFACE_ALT,
		COLOR_STOCKBOT_EDGE_STRONG
	)
	_style_stockbot_icon_button(
		submit_order_button,
		"shopping_cart",
		"Submit Sell Order" if active_order_side == "sell" else "Submit Buy Order",
		"Submit the current order.",
		false,
		COLOR_STOCKBOT_BEAR_TINT if active_order_side == "sell" else COLOR_STOCKBOT_BULL_TINT,
		COLOR_STOCKBOT_BEAR_EDGE if active_order_side == "sell" else COLOR_STOCKBOT_BULL_EDGE
	)
	_style_stockbot_button(financials_previous_button, COLOR_STOCKBOT_SURFACE_ALT, COLOR_STOCKBOT_EDGE_STRONG, COLOR_STOCKBOT_TEXT, 5)
	_style_stockbot_button(financials_next_button, COLOR_STOCKBOT_SURFACE_ALT, COLOR_STOCKBOT_EDGE_STRONG, COLOR_STOCKBOT_TEXT, 5)
	if corporate_actions_filter_option != null:
		corporate_actions_filter_option.add_theme_color_override("font_color", COLOR_STOCKBOT_TEXT)
		corporate_actions_filter_option.add_theme_color_override("font_hover_color", COLOR_STOCKBOT_TEXT)
		corporate_actions_filter_option.add_theme_color_override("font_pressed_color", COLOR_STOCKBOT_TEXT)
	_style_stockbot_button(buy_button, COLOR_STOCKBOT_BULL_TINT, COLOR_STOCKBOT_BULL_EDGE, COLOR_STOCKBOT_TEXT, 6, active_order_side == "buy")
	_style_stockbot_button(sell_button, COLOR_STOCKBOT_BEAR_TINT, COLOR_STOCKBOT_BEAR_EDGE, COLOR_STOCKBOT_TEXT, 6, active_order_side == "sell")
	order_price_value_label.add_theme_font_size_override("font_size", 22)
	order_price_change_label.add_theme_font_size_override("font_size", 12)
	order_title_label.add_theme_font_size_override("font_size", 13)
	estimated_total_value_label.add_theme_stylebox_override("normal", _make_stockbot_stylebox(COLOR_STOCKBOT_SURFACE_ALT, COLOR_STOCKBOT_EDGE_STRONG, 5, 1, 6))
	estimated_total_value_label.add_theme_font_size_override("font_size", 13)
	all_stocks_search_input.placeholder_text = "Search ticker, company, sector"
	_style_line_input(all_stocks_search_input)
	_style_line_input(order_price_line_edit)
	_style_spin_input(lot_spin_box)
	_style_item_list(company_list, 0, 0)

func _style_stockbot_static_panel_labels() -> void:
	if stock_window_container == null:
		return
	for label_name in [
		"FinancialsTitle",
		"IncomeStatementTitle",
		"BalanceSheetTitle",
		"CashFlowTitle",
		"BrokerTitle",
		"ProfileTitle"
	]:
		var title_label: Label = stock_window_container.find_child(label_name, true, false) as Label
		if title_label == null:
			continue
		_set_label_tone(title_label, COLOR_STOCKBOT_TEXT)
		_apply_font_override_to_control(title_label, DEFAULT_APP_FONT_SIZE + 2, _get_dashboard_title_font())
	for label_name in [
		"FinancialsYearLabel",
		"FinancialsPeriodLabel",
		"BrokerScaleLeftLabel",
		"BrokerScaleMidLabel",
		"BrokerScaleRightLabel"
	]:
		var body_label: Label = stock_window_container.find_child(label_name, true, false) as Label
		if body_label == null:
			continue
		_set_label_tone(body_label, COLOR_STOCKBOT_MUTED)
		_apply_font_override_to_control(body_label, DEFAULT_APP_FONT_SIZE, _get_app_font())

func _refresh_submit_order_button_style() -> void:
	if submit_order_button == null:
		return
	submit_order_button.icon = _load_stockbot_icon("shopping_cart")
	submit_order_button.expand_icon = false
	if active_order_side == "sell":
		_style_stockbot_button(submit_order_button, COLOR_STOCKBOT_BEAR_TINT, COLOR_STOCKBOT_BEAR_EDGE, COLOR_STOCKBOT_TEXT, 6)
	else:
		_style_stockbot_button(submit_order_button, COLOR_STOCKBOT_BULL_TINT, COLOR_STOCKBOT_BULL_EDGE, COLOR_STOCKBOT_TEXT, 6)

func _style_stock_list_row_button(button: Button, is_selected: bool) -> void:
	var fill_color: Color = COLOR_STOCKBOT_BLUE_TINT if is_selected else COLOR_STOCKBOT_BASE
	var border_color: Color = COLOR_STOCKBOT_BLUE if is_selected else COLOR_STOCKBOT_EDGE
	_style_stockbot_button(button, fill_color, border_color, COLOR_STOCKBOT_TEXT, 4, is_selected)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 12)

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

func _refresh_financial_history_table(financial_history: Array, _financials: Dictionary, empty_text: String = "") -> void:
	if financial_history_rows_vbox == null or financial_history_empty_label == null:
		return

	_clear_dynamic_rows(financial_history_rows_vbox, financial_history_empty_label)
	financial_history_empty_label.visible = financial_history.is_empty()
	if financial_history.is_empty():
		financial_history_empty_label.text = empty_text if not empty_text.is_empty() else "Generated history unavailable."
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
	broker_header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if broker_net_mode:
		_add_broker_table_side(broker_header_row, "Net Buy", "N.Val", "N.Lot", "N.Avg", COLOR_POSITIVE)
		broker_header_row.add_child(_build_broker_side_divider())
		_add_broker_table_side(broker_header_row, "Net Sell", "N.Val", "N.Lot", "N.Avg", COLOR_NEGATIVE)
	else:
		_add_broker_table_side(broker_header_row, "Buy", "B.Val", "B.Lot", "B.Avg", COLOR_POSITIVE)
		broker_header_row.add_child(_build_broker_side_divider())
		_add_broker_table_side(broker_header_row, "Sell", "S.Val", "S.Lot", "S.Avg", COLOR_NEGATIVE)

func _refresh_broker_table(broker_flow: Dictionary) -> void:
	if broker_rows_vbox == null or broker_empty_label == null:
		return

	_clear_dynamic_rows(broker_rows_vbox, broker_empty_label)
	var buy_brokers: Array = broker_flow.get("net_buy_brokers", []) if broker_net_mode else broker_flow.get("buy_brokers", [])
	var sell_brokers: Array = broker_flow.get("net_sell_brokers", []) if broker_net_mode else broker_flow.get("sell_brokers", [])
	var row_count: int = max(buy_brokers.size(), sell_brokers.size())
	broker_empty_label.visible = row_count == 0
	if row_count == 0:
		broker_summary_label.text = ""
		broker_summary_label.visible = false
		broker_meter_label.text = ""
		broker_meter_label.visible = false
		broker_meter_bar.value = 50.0
		_style_broker_meter(Color(0.603922, 0.623529, 0.662745, 0.92))
		return

	var action_meter_score: float = float(broker_flow.get("action_meter_score", 0.0))
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))
	var summary_text: String = _format_broker_range_summary(broker_flow)
	broker_summary_label.text = summary_text
	broker_summary_label.visible = not summary_text.is_empty()
	var meter_text: String = str(broker_flow.get("action_meter_label", "")).strip_edges()
	broker_meter_label.text = meter_text
	broker_meter_label.visible = not meter_text.is_empty()
	broker_meter_bar.value = clamp((action_meter_score + 1.0) * 50.0, 0.0, 100.0)
	_style_broker_meter(_color_for_flow(flow_tag))

	for row_index in range(row_count):
		var buy_row: Dictionary = buy_brokers[row_index] if row_index < buy_brokers.size() else {}
		var sell_row: Dictionary = sell_brokers[row_index] if row_index < sell_brokers.size() else {}
		broker_rows_vbox.add_child(_build_broker_table_row(buy_row, sell_row))

func _format_broker_range_summary(broker_flow: Dictionary) -> String:
	if broker_flow.is_empty():
		return ""
	var range_label: String = str(broker_flow.get("range_label", "1D"))
	var day_count: int = int(broker_flow.get("range_day_count", 1))
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral")).capitalize()
	var traded_value: float = max(float(broker_flow.get("broker_trade_value", 0.0)), 0.0)
	var date_text: String = _format_broker_range_date_text(
		broker_flow.get("history_start_date", {}),
		broker_flow.get("history_end_date", {})
	)
	var parts: Array = [
		range_label,
		"%d session%s" % [max(day_count, 1), "" if day_count == 1 else "s"],
		flow_tag
	]
	if traded_value > 0.0:
		parts.append("Value %s" % _format_compact_currency(traded_value))
	if not date_text.is_empty():
		parts.append(date_text)
	return " | ".join(parts)

func _format_broker_range_date_text(start_date_value: Variant, end_date_value: Variant) -> String:
	if typeof(start_date_value) != TYPE_DICTIONARY or typeof(end_date_value) != TYPE_DICTIONARY:
		return ""
	var start_date: Dictionary = start_date_value
	var end_date: Dictionary = end_date_value
	if start_date.is_empty() or end_date.is_empty():
		return ""
	var start_text: String = _format_short_broker_date(start_date)
	var end_text: String = _format_short_broker_date(end_date)
	if start_text.is_empty() or end_text.is_empty():
		return ""
	if start_text == end_text:
		return start_text
	return "%s-%s" % [start_text, end_text]

func _format_short_broker_date(date_value: Dictionary) -> String:
	if date_value.is_empty():
		return ""
	var month_names: Array = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var month_index: int = clampi(int(date_value.get("month", 1)) - 1, 0, month_names.size() - 1)
	return "%02d %s" % [int(date_value.get("day", 0)), str(month_names[month_index])]

func _populate_corporate_action_filter() -> void:
	if corporate_actions_filter_option == null:
		return
	corporate_actions_filter_option.clear()
	var filter_rows: Array = [
		{"id": "all", "label": "All"},
		{"id": "dividends", "label": "Dividends"},
		{"id": "meetings", "label": "Meetings"},
		{"id": "events", "label": "Events"}
	]
	for filter_index in range(filter_rows.size()):
		var row: Dictionary = filter_rows[filter_index]
		corporate_actions_filter_option.add_item(str(row.get("label", "")))
		corporate_actions_filter_option.set_item_metadata(filter_index, str(row.get("id", "all")))
	corporate_actions_filter_option.select(0)
	corporate_action_filter_id = "all"

func _refresh_corporate_action_timeline(timeline_snapshot: Dictionary) -> void:
	if corporate_actions_rows_vbox == null or corporate_actions_empty_label == null:
		return
	_clear_dynamic_rows(corporate_actions_rows_vbox, corporate_actions_empty_label)
	var all_rows: Array = timeline_snapshot.get("rows", [])
	var visible_rows: Array = []
	for row_value in all_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if corporate_action_filter_id != "all" and str(row.get("filter", "")) != corporate_action_filter_id:
			continue
		visible_rows.append(row)
	var no_selection: bool = timeline_snapshot.is_empty()
	corporate_actions_empty_label.visible = visible_rows.is_empty()
	if no_selection:
		corporate_actions_empty_label.text = "Select a stock to see its corporate action timeline."
		corporate_actions_summary_label.text = "No stock selected."
		return
	corporate_actions_empty_label.text = "No matching corporate actions for this filter."
	corporate_actions_summary_label.text = _corporate_action_timeline_summary(all_rows, visible_rows)
	for row in visible_rows:
		corporate_actions_rows_vbox.add_child(_build_corporate_action_timeline_card(row))

func _corporate_action_timeline_summary(all_rows: Array, visible_rows: Array) -> String:
	if all_rows.is_empty():
		return "No filed or scheduled corporate action is visible for this company yet."
	var dividend_count: int = 0
	var meeting_count: int = 0
	var event_count: int = 0
	for row_value in all_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		match str(row.get("filter", "")):
			"dividends":
				dividend_count += 1
			"meetings":
				meeting_count += 1
			"events":
				event_count += 1
	return "%d visible row(s). Dividends %d | Meetings %d | Events %d." % [
		visible_rows.size(),
		dividend_count,
		meeting_count,
		event_count
	]

func _build_corporate_action_timeline_card(row: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "CorporateActionTimelineCard"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.tooltip_text = _corporate_action_row_tooltip(row)
	panel.gui_input.connect(_root._on_corporate_action_timeline_card_gui_input.bind(row.duplicate(true)))
	var is_soon: bool = _corporate_action_row_is_soon(row)
	var edge_color: Color = COLOR_STOCKBOT_AMBER if is_soon else COLOR_STOCKBOT_EDGE
	_style_stockbot_panel(panel, COLOR_STOCKBOT_SURFACE_ALT, edge_color, 6, 1)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)
	var type_label := Label.new()
	var soon_label: String = _corporate_action_row_soon_label(row)
	type_label.text = str(row.get("type_label", "Corporate Action")) if soon_label.is_empty() else "%s | %s" % [
		str(row.get("type_label", "Corporate Action")),
		soon_label
	]
	_set_label_tone(type_label, COLOR_STOCKBOT_AMBER)
	_apply_font_override_to_control(type_label, 13, _get_dashboard_title_font())
	header.add_child(type_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var status_label := Label.new()
	var date_text: String = _format_corporate_action_date(row.get("trade_date", {}))
	status_label.text = "%s | %s" % [str(row.get("status_label", "Visible")), date_text]
	_set_label_tone(status_label, COLOR_STOCKBOT_MUTED)
	_apply_font_override_to_control(status_label, 12, _get_app_font())
	header.add_child(status_label)

	var title_label := Label.new()
	title_label.text = str(row.get("title", "Corporate action"))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_tone(title_label, COLOR_STOCKBOT_TEXT)
	_apply_font_override_to_control(title_label, 14, _get_dashboard_title_font())
	vbox.add_child(title_label)
	var summary_text: String = str(row.get("summary", "")).strip_edges()
	if not summary_text.is_empty():
		var summary_label := Label.new()
		summary_label.text = summary_text
		summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_set_label_tone(summary_label, COLOR_STOCKBOT_MUTED)
		_apply_font_override_to_control(summary_label, 12, _get_app_font())
		vbox.add_child(summary_label)

	var fields: Array = row.get("fields", [])
	if not fields.is_empty():
		var field_grid := GridContainer.new()
		field_grid.name = "CorporateActionTimelineFieldGrid"
		field_grid.columns = 4
		field_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		field_grid.add_theme_constant_override("h_separation", 12)
		field_grid.add_theme_constant_override("v_separation", 8)
		vbox.add_child(field_grid)
		for field_value in fields:
			if typeof(field_value) == TYPE_DICTIONARY:
				field_grid.add_child(_build_corporate_action_field_cell(field_value))
	var action_label := Label.new()
	action_label.text = _corporate_action_row_action_text(row)
	action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_tone(action_label, COLOR_STOCKBOT_FAINT)
	_apply_font_override_to_control(action_label, 11, _get_app_font())
	vbox.add_child(action_label)
	return panel

func _corporate_action_row_tooltip(row: Dictionary) -> String:
	match str(row.get("row_type", "")):
		"meeting":
			return "Click to open the meeting notice. Right-click to add this row to Research Tray."
		"dividend":
			return "Click to inspect dividend eligibility. Right-click to add this row to Research Tray."
		_:
			return "Click or right-click to add this corporate action to Research Tray."

func _corporate_action_row_action_text(row: Dictionary) -> String:
	match str(row.get("row_type", "")):
		"meeting":
			return "Click: open meeting notice. Right-click: add to Research Tray."
		"dividend":
			return "Click: explain eligibility. Right-click: add to Research Tray."
		_:
			return "Click: add to Research Tray."

func _corporate_action_row_is_soon(row: Dictionary) -> bool:
	var row_type: String = str(row.get("row_type", ""))
	if not (row_type in ["meeting", "dividend"]):
		return false
	var current_day_number: int = max(int(row.get("current_day_number", 0)), 1)
	var next_milestone: Dictionary = _corporate_action_next_milestone(row)
	var milestone_day: int = int(next_milestone.get("day", 0))
	if milestone_day <= 0:
		return false
	return milestone_day >= current_day_number and milestone_day <= current_day_number + 5

func _corporate_action_row_soon_label(row: Dictionary) -> String:
	if not _corporate_action_row_is_soon(row):
		return ""
	var current_day_number: int = max(int(row.get("current_day_number", 0)), 1)
	var next_milestone: Dictionary = _corporate_action_next_milestone(row)
	var label: String = str(next_milestone.get("label", "Action")).strip_edges()
	var milestone_day: int = int(next_milestone.get("day", 0))
	if milestone_day <= current_day_number:
		return "%s Today" % label
	return "%s Soon" % label

func _corporate_action_next_milestone(row: Dictionary) -> Dictionary:
	var current_day_number: int = max(int(row.get("current_day_number", 0)), 1)
	var candidates: Array = []
	match str(row.get("row_type", "")):
		"dividend":
			candidates = [
				{"label": "Ex", "day": int(row.get("ex_day_number", 0))},
				{"label": "Record", "day": int(row.get("record_day_number", 0))},
				{"label": "Payment", "day": int(row.get("payment_day_number", row.get("sort_day", 0)))}
			]
		"meeting":
			candidates = [
				{"label": "Meeting", "day": int(row.get("sort_day", 0))}
			]
	var best: Dictionary = {}
	for candidate_value in candidates:
		if typeof(candidate_value) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = candidate_value
		var candidate_day: int = int(candidate.get("day", 0))
		if candidate_day < current_day_number:
			continue
		if best.is_empty() or candidate_day < int(best.get("day", 0)):
			best = candidate.duplicate(true)
	return best

func _on_corporate_action_timeline_card_gui_input(event: InputEvent, row: Dictionary) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		_show_corporate_action_capture_menu(row, mouse_event.global_position)
		get_viewport().set_input_as_handled()
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	match str(row.get("row_type", "")):
		"meeting":
			_open_corporate_meeting_modal(str(row.get("meeting_id", row.get("source_id", ""))))
		"dividend":
			_show_toast(_corporate_action_dividend_explanation(row), true)
		_:
			_capture_corporate_action_row(row)
	get_viewport().set_input_as_handled()

func _show_corporate_action_capture_menu(row: Dictionary, menu_position: Vector2) -> void:
	var payload: Dictionary = _corporate_action_capture_payload(row)
	if payload.is_empty():
		_show_toast("Nothing to capture from this corporate action.", false)
		return
	pending_capture_payloads["corporate_action"] = payload
	if corporate_action_capture_menu == null:
		corporate_action_capture_menu = PopupMenu.new()
		corporate_action_capture_menu.name = "CorporateActionCaptureContextMenu"
		corporate_action_capture_menu.id_pressed.connect(_root._on_corporate_action_capture_menu_id_pressed)
		add_child(corporate_action_capture_menu)
	corporate_action_capture_menu.clear()
	corporate_action_capture_menu.add_item("Add to Research Tray", 1)
	corporate_action_capture_menu.position = Vector2i(int(menu_position.x), int(menu_position.y))
	corporate_action_capture_menu.popup()

func _on_corporate_action_capture_menu_id_pressed(id: int) -> void:
	_commit_pending_capture("corporate_action", id)

func _capture_corporate_action_row(row: Dictionary) -> void:
	var payload: Dictionary = _corporate_action_capture_payload(row)
	if payload.is_empty():
		_show_toast("Nothing to capture from this corporate action.", false)
		return
	var result: Dictionary = GameManager.capture_research_evidence(payload)
	_show_toast(str(result.get("message", "Research capture updated.")), bool(result.get("success", false)))

func _corporate_action_capture_payload(row: Dictionary) -> Dictionary:
	var row_type: String = str(row.get("row_type", "event")).strip_edges()
	var company_id: String = str(row.get("company_id", selected_company_id)).strip_edges()
	if company_id.is_empty():
		return {}
	var title: String = str(row.get("title", row.get("type_label", "Corporate action"))).strip_edges()
	var type_label: String = str(row.get("type_label", "Corporate Action")).strip_edges()
	var source_id: String = str(row.get("source_id", row.get("id", ""))).strip_edges()
	var source_token: String = "%s_%s" % [row_type, _node_token(source_id if not source_id.is_empty() else str(row.get("id", title)))]
	var value_text: String = _corporate_action_capture_value(row)
	return {
		"source_type": "corporate_event",
		"category": "corporate_events",
		"category_label": "Corporate Events",
		"source_label": "STOCKBOT Corp. Action",
		"source_id": source_token,
		"company_id": company_id,
		"ticker": str(row.get("ticker", "")),
		"label": "%s: %s" % [type_label, title],
		"value": value_text if not value_text.is_empty() else str(row.get("status_label", "")),
		"detail": _corporate_action_capture_detail(row),
		"impact": str(row.get("impact", "mixed"))
	}

func _corporate_action_capture_value(row: Dictionary) -> String:
	match str(row.get("row_type", "")):
		"dividend":
			return str(row.get("amount_text", row.get("title", "")))
		"meeting":
			return _format_corporate_action_date(row.get("trade_date", {}))
		_:
			return str(row.get("status_label", row.get("title", ""))).strip_edges()

func _corporate_action_capture_detail(row: Dictionary) -> String:
	var parts: Array = []
	var summary_text: String = str(row.get("summary", "")).strip_edges()
	if not summary_text.is_empty():
		parts.append(summary_text)
	var field_parts: Array = []
	for field_value in row.get("fields", []):
		if typeof(field_value) != TYPE_DICTIONARY:
			continue
		var field: Dictionary = field_value
		var label_text: String = str(field.get("label", "")).strip_edges()
		var value_text: String = _corporate_action_field_value(field).strip_edges()
		if label_text.is_empty() or value_text.is_empty() or value_text == "-":
			continue
		field_parts.append("%s: %s" % [label_text, value_text])
	if not field_parts.is_empty():
		parts.append(" | ".join(field_parts))
	return " ".join(parts)

func _corporate_action_dividend_explanation(row: Dictionary) -> String:
	var ticker: String = str(row.get("ticker", selected_company_id.to_upper())).strip_edges()
	var eligible_shares: int = max(int(row.get("eligible_shares", 0)), 0)
	var current_shares: int = max(int(row.get("current_shares_owned", 0)), 0)
	var payment_date: String = _format_corporate_action_date(row.get("payment_trade_date", row.get("trade_date", {})))
	var record_date: String = _format_corporate_action_date(row.get("record_trade_date", {}))
	var is_stock_dividend: bool = str(row.get("action_type", "")) == "stock_dividend"
	if bool(row.get("shareholder_recorded", false)):
		if eligible_shares <= 0:
			return "%s dividend: no eligible shares were recorded on %s." % [ticker, record_date]
		if is_stock_dividend:
			return "%s dividend: %d eligible share(s) recorded. Expected bonus: %d share(s) on %s." % [
				ticker,
				eligible_shares,
				int(row.get("projected_bonus_shares", 0)),
				payment_date
			]
		return "%s dividend: %d eligible share(s) recorded. Expected cash: %s on %s." % [
			ticker,
			eligible_shares,
			_format_compact_currency(float(row.get("projected_amount", 0.0))),
			payment_date
		]
	if bool(row.get("shareholder_record_pending", false)):
		if current_shares <= 0:
			return "%s dividend: no projected eligible shares yet. Recording date is %s." % [ticker, record_date]
		return "%s dividend: projected from current holding of %d share(s). Recording date is %s; payment is %s." % [
			ticker,
			current_shares,
			record_date,
			payment_date
		]
	return "%s dividend timetable is visible. Recording date: %s. Payment date: %s." % [
		ticker,
		record_date,
		payment_date
	]

func _build_corporate_action_field_cell(field: Dictionary) -> Control:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	var label := Label.new()
	label.text = str(field.get("label", "Field"))
	label.clip_text = true
	_set_label_tone(label, COLOR_STOCKBOT_MUTED)
	_apply_font_override_to_control(label, 11, _get_app_font())
	vbox.add_child(label)
	var value := Label.new()
	value.text = _corporate_action_field_value(field)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_tone(value, COLOR_STOCKBOT_TEXT)
	_apply_font_override_to_control(value, 12, _get_dashboard_title_font())
	vbox.add_child(value)
	return vbox

func _corporate_action_field_value(field: Dictionary) -> String:
	if field.has("date") and typeof(field.get("date", {})) == TYPE_DICTIONARY:
		return _format_corporate_action_date(field.get("date", {}))
	var value_text: String = str(field.get("value", "")).strip_edges()
	return value_text if not value_text.is_empty() else "-"

func _format_corporate_action_date(date_info: Variant) -> String:
	if typeof(date_info) != TYPE_DICTIONARY:
		return "-"
	var date_dict: Dictionary = date_info
	if date_dict.is_empty():
		return "-"
	var full_text: String = GameManager.format_trade_date(date_dict)
	var comma_index: int = full_text.find(", ")
	if comma_index >= 0:
		return full_text.substr(comma_index + 2)
	return full_text

func _on_corporate_action_filter_selected(index: int) -> void:
	if corporate_actions_filter_option == null:
		return
	var metadata = corporate_actions_filter_option.get_item_metadata(index)
	corporate_action_filter_id = str(metadata) if metadata != null else "all"
	if current_trade_snapshot.is_empty():
		_refresh_corporate_action_timeline({})
		trade_workspace_corporate_action_cache_key = ""
		return
	_refresh_trade_workspace_corporate_action_timeline(true)

func _on_broker_net_toggled(toggled_on: bool) -> void:
	broker_net_mode = toggled_on
	_refresh_broker_header()
	if current_trade_snapshot.is_empty():
		_refresh_broker_table({})
	else:
		_refresh_broker_table(_broker_range_flow_for_snapshot(current_trade_snapshot))
		trade_workspace_broker_cache_key = _trade_workspace_broker_snapshot_key(current_trade_snapshot)

func _add_broker_table_side(
	row: HBoxContainer,
	code_text: String,
	value_text: String,
	lot_text: String,
	average_text: String,
	font_color: Color
) -> void:
	row.add_child(_build_broker_table_cell(code_text, BROKER_CODE_WIDTH, font_color, HORIZONTAL_ALIGNMENT_LEFT, BROKER_CODE_RATIO))
	row.add_child(_build_broker_table_cell(value_text, BROKER_VALUE_WIDTH, font_color, HORIZONTAL_ALIGNMENT_RIGHT, BROKER_VALUE_RATIO))
	row.add_child(_build_broker_table_cell(lot_text, BROKER_LOT_WIDTH, font_color, HORIZONTAL_ALIGNMENT_RIGHT, BROKER_LOT_RATIO))
	row.add_child(_build_broker_table_cell(average_text, BROKER_AVERAGE_WIDTH, font_color, HORIZONTAL_ALIGNMENT_RIGHT, BROKER_AVERAGE_RATIO))

func _build_broker_table_cell(
	text: String,
	minimum_width: float,
	font_color: Color,
	alignment: HorizontalAlignment,
	stretch_ratio: float
) -> Label:
	var label: Label = _build_table_cell(text, minimum_width, font_color, true, alignment)
	label.size_flags_stretch_ratio = stretch_ratio
	return label

func _build_broker_side_divider() -> VSeparator:
	var divider := VSeparator.new()
	divider.custom_minimum_size = Vector2(BROKER_SIDE_DIVIDER_WIDTH, 0.0)
	divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return divider

func _build_broker_table_row(buy_row: Dictionary, sell_row: Dictionary) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var buy_side := _build_broker_table_side_control(buy_row, "buy")
	row.add_child(buy_side)
	row.add_child(_build_broker_side_divider())
	var sell_side := _build_broker_table_side_control(sell_row, "sell")
	row.add_child(sell_side)
	return row

func _build_broker_table_side_control(broker_row: Dictionary, side: String) -> HBoxContainer:
	var side_row := HBoxContainer.new()
	side_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_row.size_flags_stretch_ratio = 1.0
	side_row.add_theme_constant_override("separation", 8)
	side_row.mouse_filter = Control.MOUSE_FILTER_STOP
	var has_broker: bool = not broker_row.is_empty()
	var is_buy_side: bool = str(side).to_lower() == "buy"
	side_row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if has_broker else Control.CURSOR_ARROW
	side_row.tooltip_text = "Right-click to capture this %s-side broker row." % ("buy" if is_buy_side else "sell") if has_broker else ""
	if has_broker:
		side_row.gui_input.connect(_root._on_broker_table_side_gui_input.bind(broker_row.duplicate(true), "buy" if is_buy_side else "sell"))
	_add_broker_table_side(
		side_row,
		str(broker_row.get("code", "-")),
		_format_compact_currency(float(broker_row.get("value", 0.0))) if has_broker else "-",
		_format_compact_lots(float(broker_row.get("lots", 0.0))) if has_broker else "-",
		_format_last_price(float(broker_row.get("avg_price", 0.0))) if has_broker else "-",
		COLOR_POSITIVE if has_broker and is_buy_side else (COLOR_NEGATIVE if has_broker else COLOR_MUTED)
	)
	return side_row

func _on_broker_table_side_gui_input(event: InputEvent, broker_row: Dictionary, side: String) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_RIGHT:
		return
	if selected_company_id.is_empty():
		_show_toast("Pick a stock before capturing broker research.", false)
		return
	_prepare_broker_capture(broker_row, side)
	_show_broker_capture_menu(mouse_event.global_position)
	get_viewport().set_input_as_handled()

func _prepare_broker_capture(broker_row: Dictionary, side: String) -> void:
	var normalized_side: String = "sell" if str(side).to_lower() == "sell" else "buy"
	var broker_code: String = str(broker_row.get("code", "")).strip_edges()
	var broker_name: String = str(broker_row.get("company_name", broker_row.get("name", broker_code))).strip_edges()
	var side_label: String = "Buy-side" if normalized_side == "buy" else "Sell-side"
	var value_text: String = _format_compact_currency(float(broker_row.get("value", 0.0)))
	var lots_text: String = _format_compact_lots(float(broker_row.get("lots", 0.0)))
	var avg_text: String = _format_last_price(float(broker_row.get("avg_price", 0.0)))
	var range_label: String = "1D"
	var broker_flow: Dictionary = _broker_range_flow_for_snapshot(current_trade_snapshot)
	if not broker_flow.is_empty():
		range_label = str(broker_flow.get("range_label", range_label))
	var impact: String = "positive" if normalized_side == "buy" else "negative"
	var detail: String = "%s %s printed %s across %s lot(s) at an average price of %s in the %s broker range." % [
		side_label,
		broker_code,
		value_text,
		lots_text,
		avg_text,
		range_label
	]
	if not broker_name.is_empty() and broker_name != broker_code:
		detail += " Broker name: %s." % broker_name
	pending_capture_payloads["broker"] = {
		"source_type": "broker_summary",
		"category": "broker_flow",
		"category_label": "Broker Flow",
		"source_label": "STOCKBOT Broker",
		"source_id": "stockbot_broker_%s_%s_%s_%s_day_%d" % [selected_company_id, normalized_side, _node_token(broker_code), _node_token(selected_broker_range_id), RunState.day_index],
		"company_id": selected_company_id,
		"label": "%s broker %s %s" % [side_label, broker_code, range_label],
		"value": "%s | %s lot(s) | avg %s" % [value_text, lots_text, avg_text],
		"detail": detail,
		"impact": impact
	}

func _show_broker_capture_menu(menu_position: Vector2) -> void:
	if broker_capture_menu == null:
		broker_capture_menu = PopupMenu.new()
		broker_capture_menu.name = "BrokerCaptureContextMenu"
		broker_capture_menu.id_pressed.connect(_root._on_broker_capture_menu_id_pressed)
		add_child(broker_capture_menu)
	broker_capture_menu.clear()
	broker_capture_menu.add_item("Add to Research Tray", 1)
	broker_capture_menu.position = Vector2i(int(menu_position.x), int(menu_position.y))
	broker_capture_menu.popup()

func _on_broker_capture_menu_id_pressed(id: int) -> void:
	_commit_pending_capture("broker", id)

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
	financials_year_label.text = ""
	financials_year_label.visible = false
	_refresh_statement_sections(financial_statement_snapshot)
	trade_workspace_statement_cache_key = _trade_workspace_statement_snapshot_key(current_trade_snapshot, financial_statement_snapshot)
	_refresh_key_stats_dashboard(current_trade_snapshot)
	trade_workspace_key_stats_cache_key = _trade_workspace_key_stats_snapshot_key(current_trade_snapshot)

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
		_refresh_statement_section(income_statement_rows_vbox, income_statement_empty_label, [], "income_statement", "Income Statement", "")
		_refresh_statement_section(balance_sheet_rows_vbox, balance_sheet_empty_label, [], "balance_sheet", "Balance Sheet", "")
		_refresh_statement_section(cash_flow_rows_vbox, cash_flow_empty_label, [], "cash_flow", "Cash Flow", "")
		return

	var selected_period: Dictionary = _selected_statement_period(financial_statement_snapshot)
	var period_label: String = str(selected_period.get("statement_period_label", selected_period.get("period_label", "latest"))).strip_edges()
	_refresh_statement_section(
		income_statement_rows_vbox,
		income_statement_empty_label,
		selected_period.get("income_statement", []),
		"income_statement",
		"Income Statement",
		period_label
	)
	_refresh_statement_section(
		balance_sheet_rows_vbox,
		balance_sheet_empty_label,
		selected_period.get("balance_sheet", []),
		"balance_sheet",
		"Balance Sheet",
		period_label
	)
	_refresh_statement_section(
		cash_flow_rows_vbox,
		cash_flow_empty_label,
		selected_period.get("cash_flow", []),
		"cash_flow",
		"Cash Flow",
		period_label
	)

func _refresh_statement_section(
	rows_vbox: VBoxContainer,
	empty_label: Label,
	lines: Array,
	section_id: String = "",
	section_label: String = "",
	period_label: String = ""
) -> void:
	if rows_vbox == null or empty_label == null:
		return

	_clear_dynamic_rows(rows_vbox, empty_label)
	empty_label.visible = lines.is_empty()
	if lines.is_empty():
		return

	for line_value in lines:
		var line_item: Dictionary = line_value
		rows_vbox.add_child(_build_statement_row(line_item, section_id, section_label, period_label))

func _build_statement_row(
	line_item: Dictionary,
	section_id: String = "",
	section_label: String = "",
	period_label: String = ""
) -> Control:
	var capture_payload: Dictionary = _financial_statement_capture_payload(line_item, section_id, section_label, period_label)
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	if not capture_payload.is_empty():
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.tooltip_text = "Click to open research actions."
		row.gui_input.connect(_root._on_financial_statement_row_gui_input.bind(capture_payload.duplicate(true)))

	var label_cell: Label = _build_table_cell(
		str(line_item.get("label", "")),
		STATEMENT_LABEL_WIDTH,
		COLOR_STOCKBOT_MUTED,
		true
	)
	var value_cell: Label = _build_table_cell(
		_format_statement_value(line_item),
		STATEMENT_VALUE_WIDTH,
		COLOR_STOCKBOT_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	)
	if not capture_payload.is_empty():
		label_cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		value_cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label_cell)
	row.add_child(value_cell)
	return row

func _financial_statement_capture_payload(
	line_item: Dictionary,
	section_id: String,
	section_label: String,
	period_label: String
) -> Dictionary:
	if selected_company_id.is_empty():
		return {}
	var label_text: String = str(line_item.get("label", "")).strip_edges()
	if label_text.is_empty():
		return {}
	var value_text: String = _format_statement_value(line_item)
	if value_text.strip_edges().is_empty() or value_text.strip_edges() == "-":
		return {}
	var resolved_section_id: String = section_id.strip_edges().to_lower()
	if resolved_section_id == "cash flow":
		resolved_section_id = "cash_flow"
	var resolved_section_label: String = section_label.strip_edges()
	if resolved_section_label.is_empty():
		resolved_section_label = resolved_section_id.replace("_", " ").capitalize()
	var resolved_period: String = period_label.strip_edges()
	if resolved_period.is_empty():
		resolved_period = "latest"
	var detail: String = "%s line from %s (%s)." % [label_text, resolved_section_label, resolved_period]
	return {
		"source_type": "financial_statement",
		"category": "financials",
		"company_id": selected_company_id,
		"label": label_text,
		"value": value_text,
		"detail": detail,
		"source_id": "financial_statement_%s_%s_%s_%s" % [
			selected_company_id,
			resolved_section_id,
			_node_token(resolved_period),
			_node_token(label_text)
		],
		"raw_value": float(line_item.get("value", 0.0))
	}

func _on_financial_statement_row_gui_input(event: InputEvent, capture_payload: Dictionary) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or not [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT].has(mouse_event.button_index):
		return
	pending_capture_payloads["financial_statement"] = capture_payload.duplicate(true)
	_show_financial_statement_capture_menu(mouse_event.global_position)

func _show_financial_statement_capture_menu(menu_position: Vector2) -> void:
	if financial_statement_capture_menu == null:
		financial_statement_capture_menu = PopupMenu.new()
		financial_statement_capture_menu.name = "FinancialStatementCaptureContextMenu"
		financial_statement_capture_menu.id_pressed.connect(_root._on_financial_statement_capture_menu_id_pressed)
		add_child(financial_statement_capture_menu)
	financial_statement_capture_menu.clear()
	financial_statement_capture_menu.add_item("Add to Research Tray", 1)
	financial_statement_capture_menu.position = Vector2i(int(menu_position.x), int(menu_position.y))
	financial_statement_capture_menu.popup()

func _on_financial_statement_capture_menu_id_pressed(id: int) -> void:
	_commit_pending_capture("financial_statement", id)

func _format_statement_value(line_item: Dictionary) -> String:
	var line_format: String = str(line_item.get("format", "currency"))
	var value: float = float(line_item.get("value", 0.0))
	if line_format == "shares":
		return _format_grouped_integer(int(round(value)))
	return _format_compact_currency(value)

func _sync_dynamic_refs_from_root() -> void:
	if _root == null:
		return
	stock_window_container = _root.get("stock_window_container") as PanelContainer
	app_content_margin = _root.get("app_content_margin") as MarginContainer
	top_bar_panel = _root.get("top_bar_panel") as PanelContainer
	sidebar_panel = _root.get("sidebar_panel") as PanelContainer
	content_tabs = _root.get("content_tabs") as TabContainer
	top_section_label = _root.get("top_section_label") as Label
	top_market_label = _root.get("top_market_label") as Label
	top_equity_label = _root.get("top_equity_label") as Label
	top_cash_label = _root.get("top_cash_label") as Label
	trade_split = _root.get("trade_split") as HBoxContainer
	main_trade_split = _root.get("main_trade_split") as HBoxContainer
	watchlist_panel = _root.get("watchlist_panel") as PanelContainer
	work_area_panel = _root.get("work_area_panel") as PanelContainer
	order_ticket_toggle_button = _root.get("order_ticket_toggle_button") as Button
	action_panel = _root.get("action_panel") as PanelContainer
	stock_list_tabs = _root.get("stock_list_tabs") as TabContainer
	add_watchlist_button = _root.get("add_watchlist_button") as Button
	remove_watchlist_button = _root.get("remove_watchlist_button") as Button
	watchlist_empty_label = _root.get("watchlist_empty_label") as Label
	company_list = _root.get("company_list") as ItemList
	all_stocks_search_input = _root.get("all_stocks_search_input") as LineEdit
	all_stocks_scroll = _root.get("all_stocks_scroll") as ScrollContainer
	all_stocks_rows = _root.get("all_stocks_rows") as VBoxContainer
	portfolio_stocks_scroll = _root.get("portfolio_stocks_scroll") as ScrollContainer
	portfolio_stocks_rows = _root.get("portfolio_stocks_rows") as VBoxContainer
	portfolio_stocks_empty_label = _root.get("portfolio_stocks_empty_label") as Label
	trade_workspace_widget = _root.get("trade_workspace_widget")
	work_tabs = _root.get("work_tabs") as TabContainer
	key_stats_panel = _root.get("key_stats_panel") as PanelContainer
	key_stats_financial_label = _root.get("key_stats_financial_label") as Label
	financial_history_summary_label = _root.get("financial_history_summary_label") as Label
	financial_history_header_row = _root.get("financial_history_header_row") as HBoxContainer
	financial_history_rows_vbox = _root.get("financial_history_rows_vbox") as VBoxContainer
	financial_history_empty_label = _root.get("financial_history_empty_label") as Label
	financials_panel = _root.get("financials_panel") as PanelContainer
	financials_year_label = _root.get("financials_year_label") as Label
	financials_previous_button = _root.get("financials_previous_button") as Button
	financials_period_label = _root.get("financials_period_label") as Label
	financials_next_button = _root.get("financials_next_button") as Button
	income_statement_rows_vbox = _root.get("income_statement_rows_vbox") as VBoxContainer
	income_statement_empty_label = _root.get("income_statement_empty_label") as Label
	balance_sheet_rows_vbox = _root.get("balance_sheet_rows_vbox") as VBoxContainer
	balance_sheet_empty_label = _root.get("balance_sheet_empty_label") as Label
	cash_flow_rows_vbox = _root.get("cash_flow_rows_vbox") as VBoxContainer
	cash_flow_empty_label = _root.get("cash_flow_empty_label") as Label
	broker_panel = _root.get("broker_panel") as PanelContainer
	broker_summary_label = _root.get("broker_summary_label") as Label
	broker_meter_label = _root.get("broker_meter_label") as Label
	broker_meter_bar = _root.get("broker_meter_bar") as ProgressBar
	broker_scale_left_label = _root.get("broker_scale_left_label") as Label
	broker_scale_mid_label = _root.get("broker_scale_mid_label") as Label
	broker_scale_right_label = _root.get("broker_scale_right_label") as Label
	broker_net_toggle = _root.get("broker_net_toggle") as CheckButton
	broker_header_row = _root.get("broker_header_row") as HBoxContainer
	broker_rows_vbox = _root.get("broker_rows_vbox") as VBoxContainer
	broker_empty_label = _root.get("broker_empty_label") as Label
	analyzer_panel = _root.get("analyzer_panel") as PanelContainer
	analyzer_setup_label = _root.get("analyzer_setup_label") as Label
	analyzer_support_label = _root.get("analyzer_support_label") as Label
	analyzer_risk_label = _root.get("analyzer_risk_label") as Label
	analyzer_event_label = _root.get("analyzer_event_label") as Label
	analyzer_history_label = _root.get("analyzer_history_label") as Label
	corporate_actions_panel = _root.get("corporate_actions_panel") as PanelContainer
	corporate_actions_filter_option = _root.get("corporate_actions_filter_option") as OptionButton
	corporate_actions_summary_label = _root.get("corporate_actions_summary_label") as Label
	corporate_actions_rows_vbox = _root.get("corporate_actions_rows_vbox") as VBoxContainer
	corporate_actions_empty_label = _root.get("corporate_actions_empty_label") as Label
	profile_panel = _root.get("profile_panel") as PanelContainer
	profile_company_name_label = _root.get("profile_company_name_label") as Label
	profile_sector_label = _root.get("profile_sector_label") as Label
	profile_price_label = _root.get("profile_price_label") as Label
	profile_factor_label = _root.get("profile_factor_label") as Label
	profile_management_label = _root.get("profile_management_label") as Label
	profile_shareholders_label = _root.get("profile_shareholders_label") as Label
	profile_tags_label = _root.get("profile_tags_label") as Label
	profile_description_label = _root.get("profile_description_label") as Label
	profile_network_hint_label = _root.get("profile_network_hint_label") as Label
	profile_meet_contact_button = _root.get("profile_meet_contact_button") as Button
	order_company_name_label = _root.get("order_company_name_label") as Label
	selection_label = _root.get("selection_label") as Label
	order_price_value_label = _root.get("order_price_value_label") as Label
	order_price_change_label = _root.get("order_price_change_label") as Label
	order_position_label = _root.get("order_position_label") as Label
	order_card_panel = _root.get("order_card_panel") as PanelContainer
	order_title_label = _root.get("order_title_label") as Label
	lot_spin_box = _root.get("lot_spin_box") as SpinBox
	order_price_line_edit = _root.get("order_price_line_edit") as LineEdit
	estimated_total_value_label = _root.get("estimated_total_value_label") as Label
	buy_button = _root.get("buy_button") as Button
	sell_button = _root.get("sell_button") as Button
	submit_order_button = _root.get("submit_order_button") as Button
	debug_overlay = _root.get("debug_overlay") as Control
	watchlist_picker_dialog = _root.get("watchlist_picker_dialog") as ConfirmationDialog
	watchlist_picker_list = _root.get("watchlist_picker_list") as ItemList
	key_stats_dashboard_grid = _root.get("key_stats_dashboard_grid") as GridContainer
	var key_stats_dashboard_columns_value = _root.get("key_stats_dashboard_columns")
	key_stats_dashboard_columns = key_stats_dashboard_columns_value if typeof(key_stats_dashboard_columns_value) == TYPE_DICTIONARY else {}
	var key_stats_card_rows_value = _root.get("key_stats_card_rows")
	key_stats_card_rows = key_stats_card_rows_value if typeof(key_stats_card_rows_value) == TYPE_DICTIONARY else {}
	var key_stats_metric_buttons_value = _root.get("key_stats_metric_buttons")
	key_stats_metric_buttons = key_stats_metric_buttons_value if typeof(key_stats_metric_buttons_value) == TYPE_DICTIONARY else {}
	key_stats_metric_table_rows = _root.get("key_stats_metric_table_rows") as VBoxContainer
	key_stats_metric_footer_rows = _root.get("key_stats_metric_footer_rows") as VBoxContainer
	profile_background_card = _root.get("profile_background_card") as PanelContainer
	profile_background_title_label = _root.get("profile_background_title_label") as Label
	profile_background_meta_label = _root.get("profile_background_meta_label") as Label
	profile_background_body_label = _root.get("profile_background_body_label") as Label
	profile_tags_flow = _root.get("profile_tags_flow") as HFlowContainer
	profile_shareholder_card = _root.get("profile_shareholder_card") as PanelContainer
	profile_shareholder_title_label = _root.get("profile_shareholder_title_label") as Label
	profile_shareholder_updated_label = _root.get("profile_shareholder_updated_label") as Label
	profile_shareholder_rows = _root.get("profile_shareholder_rows") as VBoxContainer
	profile_management_card = _root.get("profile_management_card") as PanelContainer
	profile_management_title_label = _root.get("profile_management_title_label") as Label
	profile_management_rows = _root.get("profile_management_rows") as VBoxContainer
	contact_intel_panel = _root.get("contact_intel_panel") as PanelContainer
	contact_intel_option = _root.get("contact_intel_option") as OptionButton
	contact_intel_button = _root.get("contact_intel_button") as Button
	contact_intel_status_label = _root.get("contact_intel_status_label") as Label


func _sync_state_from_root() -> void:
	if _root == null:
		return
	selected_company_id = str(_root.get("selected_company_id"))
	var displayed_company_ids_value = _root.get("displayed_company_ids")
	displayed_company_ids = displayed_company_ids_value if typeof(displayed_company_ids_value) == TYPE_ARRAY else []
	var watchlist_picker_company_ids_value = _root.get("watchlist_picker_company_ids")
	watchlist_picker_company_ids = watchlist_picker_company_ids_value if typeof(watchlist_picker_company_ids_value) == TYPE_ARRAY else []
	selected_lots = int(_root.get("selected_lots"))
	selected_financial_statement_index = int(_root.get("selected_financial_statement_index"))
	selected_financial_statement_company_id = str(_root.get("selected_financial_statement_company_id"))
	selected_key_stats_metric = str(_root.get("selected_key_stats_metric"))
	key_stats_capture_menu = _root.get("key_stats_capture_menu") as PopupMenu
	broker_capture_menu = _root.get("broker_capture_menu") as PopupMenu
	profile_capture_menu = _root.get("profile_capture_menu") as PopupMenu
	financial_statement_capture_menu = _root.get("financial_statement_capture_menu") as PopupMenu
	corporate_action_filter_id = str(_root.get("corporate_action_filter_id"))
	corporate_action_capture_menu = _root.get("corporate_action_capture_menu") as PopupMenu
	trade_quote_capture_menu = _root.get("trade_quote_capture_menu") as PopupMenu
	var pending_capture_payloads_value = _root.get("pending_capture_payloads")
	pending_capture_payloads = pending_capture_payloads_value if typeof(pending_capture_payloads_value) == TYPE_DICTIONARY else {}
	var current_trade_snapshot_value = _root.get("current_trade_snapshot")
	current_trade_snapshot = current_trade_snapshot_value if typeof(current_trade_snapshot_value) == TYPE_DICTIONARY else {}
	all_stock_rows_dirty = bool(_root.get("all_stock_rows_dirty"))
	portfolio_stock_rows_dirty = bool(_root.get("portfolio_stock_rows_dirty"))
	var order_market_value_labels_value = _root.get("order_market_value_labels")
	order_market_value_labels = order_market_value_labels_value if typeof(order_market_value_labels_value) == TYPE_DICTIONARY else {}
	var order_market_name_labels_value = _root.get("order_market_name_labels")
	order_market_name_labels = order_market_name_labels_value if typeof(order_market_name_labels_value) == TYPE_DICTIONARY else {}
	pending_watchlist_selected_company_id = str(_root.get("pending_watchlist_selected_company_id"))
	pending_watchlist_target_tab = int(_root.get("pending_watchlist_target_tab"))
	suppress_stock_list_tab_refresh = bool(_root.get("suppress_stock_list_tab_refresh"))
	active_order_side = str(_root.get("active_order_side"))
	order_ticket_collapsed = bool(_root.get("order_ticket_collapsed"))
	broker_net_mode = bool(_root.get("broker_net_mode"))
	selected_broker_range_id = str(_root.get("selected_broker_range_id"))
	var broker_range_buttons_value = _root.get("broker_range_buttons")
	broker_range_buttons = broker_range_buttons_value if typeof(broker_range_buttons_value) == TYPE_DICTIONARY else {}
	broker_range_row = _root.get("broker_range_row")
	var stockbot_icon_cache_value = _root.get("stockbot_icon_cache")
	stockbot_icon_cache = stockbot_icon_cache_value if typeof(stockbot_icon_cache_value) == TYPE_DICTIONARY else {}
	trade_workspace_detail_cache_key = str(_root.get("trade_workspace_detail_cache_key"))
	trade_workspace_profile_cache_key = str(_root.get("trade_workspace_profile_cache_key"))
	trade_workspace_financial_history_cache_key = str(_root.get("trade_workspace_financial_history_cache_key"))
	trade_workspace_key_stats_cache_key = str(_root.get("trade_workspace_key_stats_cache_key"))
	trade_workspace_broker_cache_key = str(_root.get("trade_workspace_broker_cache_key"))
	trade_workspace_corporate_action_cache_key = str(_root.get("trade_workspace_corporate_action_cache_key"))
	trade_workspace_statement_cache_key = str(_root.get("trade_workspace_statement_cache_key"))
	status_message = str(_root.get("status_message"))


func _sync_root_refs() -> void:
	if _root == null:
		return
	_root.set("stock_window_container", stock_window_container)
	_root.set("app_content_margin", app_content_margin)
	_root.set("top_bar_panel", top_bar_panel)
	_root.set("sidebar_panel", sidebar_panel)
	_root.set("content_tabs", content_tabs)
	_root.set("top_section_label", top_section_label)
	_root.set("top_market_label", top_market_label)
	_root.set("top_equity_label", top_equity_label)
	_root.set("top_cash_label", top_cash_label)
	_root.set("trade_split", trade_split)
	_root.set("main_trade_split", main_trade_split)
	_root.set("watchlist_panel", watchlist_panel)
	_root.set("work_area_panel", work_area_panel)
	_root.set("order_ticket_toggle_button", order_ticket_toggle_button)
	_root.set("action_panel", action_panel)
	_root.set("stock_list_tabs", stock_list_tabs)
	_root.set("add_watchlist_button", add_watchlist_button)
	_root.set("remove_watchlist_button", remove_watchlist_button)
	_root.set("watchlist_empty_label", watchlist_empty_label)
	_root.set("company_list", company_list)
	_root.set("all_stocks_search_input", all_stocks_search_input)
	_root.set("all_stocks_scroll", all_stocks_scroll)
	_root.set("all_stocks_rows", all_stocks_rows)
	_root.set("portfolio_stocks_scroll", portfolio_stocks_scroll)
	_root.set("portfolio_stocks_rows", portfolio_stocks_rows)
	_root.set("portfolio_stocks_empty_label", portfolio_stocks_empty_label)
	_root.set("trade_workspace_widget", trade_workspace_widget)
	_root.set("work_tabs", work_tabs)
	_root.set("key_stats_panel", key_stats_panel)
	_root.set("key_stats_financial_label", key_stats_financial_label)
	_root.set("financial_history_summary_label", financial_history_summary_label)
	_root.set("financial_history_header_row", financial_history_header_row)
	_root.set("financial_history_rows_vbox", financial_history_rows_vbox)
	_root.set("financial_history_empty_label", financial_history_empty_label)
	_root.set("financials_panel", financials_panel)
	_root.set("financials_year_label", financials_year_label)
	_root.set("financials_previous_button", financials_previous_button)
	_root.set("financials_period_label", financials_period_label)
	_root.set("financials_next_button", financials_next_button)
	_root.set("income_statement_rows_vbox", income_statement_rows_vbox)
	_root.set("income_statement_empty_label", income_statement_empty_label)
	_root.set("balance_sheet_rows_vbox", balance_sheet_rows_vbox)
	_root.set("balance_sheet_empty_label", balance_sheet_empty_label)
	_root.set("cash_flow_rows_vbox", cash_flow_rows_vbox)
	_root.set("cash_flow_empty_label", cash_flow_empty_label)
	_root.set("broker_panel", broker_panel)
	_root.set("broker_summary_label", broker_summary_label)
	_root.set("broker_meter_label", broker_meter_label)
	_root.set("broker_meter_bar", broker_meter_bar)
	_root.set("broker_scale_left_label", broker_scale_left_label)
	_root.set("broker_scale_mid_label", broker_scale_mid_label)
	_root.set("broker_scale_right_label", broker_scale_right_label)
	_root.set("broker_net_toggle", broker_net_toggle)
	_root.set("broker_header_row", broker_header_row)
	_root.set("broker_rows_vbox", broker_rows_vbox)
	_root.set("broker_empty_label", broker_empty_label)
	_root.set("analyzer_panel", analyzer_panel)
	_root.set("analyzer_setup_label", analyzer_setup_label)
	_root.set("analyzer_support_label", analyzer_support_label)
	_root.set("analyzer_risk_label", analyzer_risk_label)
	_root.set("analyzer_event_label", analyzer_event_label)
	_root.set("analyzer_history_label", analyzer_history_label)
	_root.set("corporate_actions_panel", corporate_actions_panel)
	_root.set("corporate_actions_filter_option", corporate_actions_filter_option)
	_root.set("corporate_actions_summary_label", corporate_actions_summary_label)
	_root.set("corporate_actions_rows_vbox", corporate_actions_rows_vbox)
	_root.set("corporate_actions_empty_label", corporate_actions_empty_label)
	_root.set("profile_panel", profile_panel)
	_root.set("profile_company_name_label", profile_company_name_label)
	_root.set("profile_sector_label", profile_sector_label)
	_root.set("profile_price_label", profile_price_label)
	_root.set("profile_factor_label", profile_factor_label)
	_root.set("profile_management_label", profile_management_label)
	_root.set("profile_shareholders_label", profile_shareholders_label)
	_root.set("profile_tags_label", profile_tags_label)
	_root.set("profile_description_label", profile_description_label)
	_root.set("profile_network_hint_label", profile_network_hint_label)
	_root.set("profile_meet_contact_button", profile_meet_contact_button)
	_root.set("order_company_name_label", order_company_name_label)
	_root.set("selection_label", selection_label)
	_root.set("order_price_value_label", order_price_value_label)
	_root.set("order_price_change_label", order_price_change_label)
	_root.set("order_position_label", order_position_label)
	_root.set("order_card_panel", order_card_panel)
	_root.set("order_title_label", order_title_label)
	_root.set("lot_spin_box", lot_spin_box)
	_root.set("order_price_line_edit", order_price_line_edit)
	_root.set("estimated_total_value_label", estimated_total_value_label)
	_root.set("buy_button", buy_button)
	_root.set("sell_button", sell_button)
	_root.set("submit_order_button", submit_order_button)
	_root.set("debug_overlay", debug_overlay)
	_root.set("watchlist_picker_dialog", watchlist_picker_dialog)
	_root.set("watchlist_picker_list", watchlist_picker_list)
	_root.set("key_stats_dashboard_grid", key_stats_dashboard_grid)
	_root.set("key_stats_dashboard_columns", key_stats_dashboard_columns)
	_root.set("key_stats_card_rows", key_stats_card_rows)
	_root.set("key_stats_metric_buttons", key_stats_metric_buttons)
	_root.set("key_stats_metric_table_rows", key_stats_metric_table_rows)
	_root.set("key_stats_metric_footer_rows", key_stats_metric_footer_rows)
	_root.set("profile_background_card", profile_background_card)
	_root.set("profile_background_title_label", profile_background_title_label)
	_root.set("profile_background_meta_label", profile_background_meta_label)
	_root.set("profile_background_body_label", profile_background_body_label)
	_root.set("profile_tags_flow", profile_tags_flow)
	_root.set("profile_shareholder_card", profile_shareholder_card)
	_root.set("profile_shareholder_title_label", profile_shareholder_title_label)
	_root.set("profile_shareholder_updated_label", profile_shareholder_updated_label)
	_root.set("profile_shareholder_rows", profile_shareholder_rows)
	_root.set("profile_management_card", profile_management_card)
	_root.set("profile_management_title_label", profile_management_title_label)
	_root.set("profile_management_rows", profile_management_rows)
	_root.set("contact_intel_panel", contact_intel_panel)
	_root.set("contact_intel_option", contact_intel_option)
	_root.set("contact_intel_button", contact_intel_button)
	_root.set("contact_intel_status_label", contact_intel_status_label)
	_sync_root_state()


func _sync_root_state() -> void:
	if _root == null:
		return
	_root.set("selected_company_id", selected_company_id)
	_root.set("displayed_company_ids", displayed_company_ids)
	_root.set("watchlist_picker_company_ids", watchlist_picker_company_ids)
	_root.set("selected_lots", selected_lots)
	_root.set("selected_financial_statement_index", selected_financial_statement_index)
	_root.set("selected_financial_statement_company_id", selected_financial_statement_company_id)
	_root.set("selected_key_stats_metric", selected_key_stats_metric)
	_root.set("key_stats_capture_menu", key_stats_capture_menu)
	_root.set("broker_capture_menu", broker_capture_menu)
	_root.set("profile_capture_menu", profile_capture_menu)
	_root.set("financial_statement_capture_menu", financial_statement_capture_menu)
	_root.set("corporate_action_filter_id", corporate_action_filter_id)
	_root.set("corporate_action_capture_menu", corporate_action_capture_menu)
	_root.set("trade_quote_capture_menu", trade_quote_capture_menu)
	_root.set("pending_capture_payloads", pending_capture_payloads)
	_root.set("current_trade_snapshot", current_trade_snapshot)
	_root.set("all_stock_rows_dirty", all_stock_rows_dirty)
	_root.set("portfolio_stock_rows_dirty", portfolio_stock_rows_dirty)
	_root.set("order_market_value_labels", order_market_value_labels)
	_root.set("order_market_name_labels", order_market_name_labels)
	_root.set("pending_watchlist_selected_company_id", pending_watchlist_selected_company_id)
	_root.set("pending_watchlist_target_tab", pending_watchlist_target_tab)
	_root.set("suppress_stock_list_tab_refresh", suppress_stock_list_tab_refresh)
	_root.set("active_order_side", active_order_side)
	_root.set("order_ticket_collapsed", order_ticket_collapsed)
	_root.set("broker_net_mode", broker_net_mode)
	_root.set("selected_broker_range_id", selected_broker_range_id)
	_root.set("broker_range_buttons", broker_range_buttons)
	_root.set("broker_range_row", broker_range_row)
	_root.set("stockbot_icon_cache", stockbot_icon_cache)
	_root.set("trade_workspace_detail_cache_key", trade_workspace_detail_cache_key)
	_root.set("trade_workspace_profile_cache_key", trade_workspace_profile_cache_key)
	_root.set("trade_workspace_financial_history_cache_key", trade_workspace_financial_history_cache_key)
	_root.set("trade_workspace_key_stats_cache_key", trade_workspace_key_stats_cache_key)
	_root.set("trade_workspace_broker_cache_key", trade_workspace_broker_cache_key)
	_root.set("trade_workspace_corporate_action_cache_key", trade_workspace_corporate_action_cache_key)
	_root.set("trade_workspace_statement_cache_key", trade_workspace_statement_cache_key)
	_root.set("status_message", status_message)


func add_child(node: Node) -> void:
	if _root != null:
		_root.add_child(node)


func find_child(pattern: String, recursive: bool = true, owned: bool = true) -> Node:
	if _root == null:
		return null
	return _root.find_child(pattern, recursive, owned)


func get_tree() -> SceneTree:
	if _root == null:
		return null
	return _root.get_tree()


func get_viewport() -> Viewport:
	if _root == null:
		return null
	return _root.get_viewport()


func get_viewport_rect() -> Rect2:
	if _root == null:
		return Rect2()
	return _root.get_viewport_rect()


func is_inside_tree() -> bool:
	return _root != null and _root.is_inside_tree()


func _call_root_void(method_name: String, args: Array = []) -> void:
	if _root != null:
		_root.callv(method_name, args)


func _call_root(method_name: String, args: Array = []):
	if _root == null:
		return null
	return _root.callv(method_name, args)


func _queue_watchlist_refresh_override(company_id: String = "", target_tab: int = -1) -> void:
	_call_root_void("_queue_watchlist_refresh_override", [company_id, target_tab])


func _clear_watchlist_refresh_override() -> void:
	_call_root_void("_clear_watchlist_refresh_override")


func _invalidate_company_rows_cache() -> void:
	_call_root_void("_invalidate_company_rows_cache")


func _get_company_rows_cached() -> Array:
	var result = _call_root("_get_company_rows_cached")
	return result if typeof(result) == TYPE_ARRAY else []


func _get_company_row_lookup_cached() -> Dictionary:
	var result = _call_root("_get_company_row_lookup_cached")
	return result if typeof(result) == TYPE_DICTIONARY else {}


func _build_company_row_lookup(company_rows: Array) -> Dictionary:
	var result = _call_root("_build_company_row_lookup", [company_rows])
	return result if typeof(result) == TYPE_DICTIONARY else {}


func _refresh_dashboard() -> void:
	_call_root_void("_refresh_dashboard")


func _refresh_desktop() -> void:
	_call_root_void("_refresh_desktop")


func _refresh_debug_overlay() -> void:
	_call_root_void("_refresh_debug_overlay")


func _refresh_ftue_progress() -> void:
	_call_root_void("_refresh_ftue_progress")


func _refresh_ftue_overlay() -> void:
	_call_root_void("_refresh_ftue_overlay")


func _refresh_first_hour_guide_progress() -> void:
	_call_root_void("_refresh_first_hour_guide_progress")


func _refresh_thesis() -> void:
	_call_root_void("_refresh_thesis")


func _refresh_company_app_availability() -> void:
	_call_root_void("_refresh_company_app_availability")


func _refresh_company(preferred_company_id: String = "") -> void:
	_call_root_void("_refresh_company", [preferred_company_id])


func _refresh_network() -> void:
	_call_root_void("_refresh_network")


func _refresh_portfolio() -> void:
	_call_root_void("_refresh_portfolio")


func _refresh_header() -> void:
	_call_root_void("_refresh_header")


func _refresh_sidebar() -> void:
	_call_root_void("_refresh_sidebar")


func _is_desktop_app_window_open(app_id: String) -> bool:
	return bool(_call_root("_is_desktop_app_window_open", [app_id]))


func _record_steam_stockbot_tab_view(tab_title: String) -> void:
	_call_root_void("_record_steam_stockbot_tab_view", [tab_title])


func _current_work_tab_title() -> String:
	return str(_call_root("_current_work_tab_title"))


func _mark_guide_watchlist_all_stock_seen() -> void:
	_call_root_void("_mark_guide_watchlist_all_stock_seen")


func _mark_guide_watchlist_stock_selected() -> void:
	_call_root_void("_mark_guide_watchlist_stock_selected")


func _mark_guide_fundamental_tab_seen(tab_index: int) -> void:
	_call_root_void("_mark_guide_fundamental_tab_seen", [tab_index])


func _mark_guide_research_interaction() -> void:
	_call_root_void("_mark_guide_research_interaction")


func _show_toast(message: String, is_success: bool) -> void:
	_call_root_void("_show_toast", [message, is_success])


func _commit_pending_capture(kind: String, id: int) -> void:
	_call_root_void("_commit_pending_capture", [kind, id])


func _open_corporate_meeting_modal(meeting_id: String) -> void:
	_call_root_void("_open_corporate_meeting_modal", [meeting_id])


func _network_state_for_contact(network_snapshot: Dictionary, contact_id: String) -> String:
	return str(_call_root("_network_state_for_contact", [network_snapshot, contact_id]))


func _node_token(value: String) -> String:
	return str(_call_root("_node_token", [value]))


func _clear_dynamic_rows(container: VBoxContainer, preserved_node: Node) -> void:
	_call_root_void("_clear_dynamic_rows", [container, preserved_node])


func _build_table_cell(text: String, minimum_width: float, font_color: Color, expand: bool = false, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	return _call_root("_build_table_cell", [text, minimum_width, font_color, expand, alignment]) as Label


func _set_label_tone(label: Label, color: Color) -> void:
	_call_root_void("_set_label_tone", [label, color])


func _apply_font_override_to_control(control: Control, font_size: int, font: Font = null) -> void:
	_call_root_void("_apply_font_override_to_control", [control, font_size, font])


func _apply_font_overrides_to_subtree(node: Node) -> void:
	_call_root_void("_apply_font_overrides_to_subtree", [node])


func _get_app_font() -> Font:
	return _call_root("_get_app_font") as Font


func _get_dashboard_title_font() -> Font:
	return _call_root("_get_dashboard_title_font") as Font


func _style_line_input(line_edit: LineEdit) -> void:
	_call_root_void("_style_line_input", [line_edit])


func _style_spin_input(spin_box: SpinBox) -> void:
	_call_root_void("_style_spin_input", [spin_box])


func _style_item_list(item_list: ItemList, panel_radius: int = 8, cursor_radius: int = 6) -> void:
	_call_root_void("_style_item_list", [item_list, panel_radius, cursor_radius])


func _style_tab_container(tab_container: TabContainer, corner_radius: int = 6) -> void:
	_call_root_void("_style_tab_container", [tab_container, corner_radius])


func _style_broker_meter(fill_color: Color) -> void:
	_call_root_void("_style_broker_meter", [fill_color])


func _style_panel(panel: PanelContainer, fill_color: Color = COLOR_PANEL_BLUE, border_color: Color = COLOR_BORDER, corner_radius: int = 8) -> void:
	_call_root_void("_style_panel", [panel, fill_color, border_color, corner_radius])


func _style_button(button: Button, fill_color: Color = COLOR_PANEL_BLUE_ALT, border_color: Color = COLOR_BORDER, font_color: Color = COLOR_TEXT) -> void:
	_call_root_void("_style_button", [button, fill_color, border_color, font_color])


func _style_light_option_button(option_button: OptionButton) -> void:
	_call_root_void("_style_light_option_button", [option_button])


func _color_for_change(change_pct: float) -> Color:
	var value = _call_root("_color_for_change", [change_pct])
	return value if typeof(value) == TYPE_COLOR else COLOR_MUTED


func _flow_badge(flow_tag: String) -> String:
	return str(_call_root("_flow_badge", [flow_tag]))


func _color_for_flow(flow_tag: String) -> Color:
	var value = _call_root("_color_for_flow", [flow_tag])
	return value if typeof(value) == TYPE_COLOR else COLOR_MUTED


func _color_for_flow_bg(flow_tag: String) -> Color:
	var value = _call_root("_color_for_flow_bg", [flow_tag])
	return value if typeof(value) == TYPE_COLOR else Color.TRANSPARENT


func _format_currency(value: float) -> String:
	return str(_call_root("_format_currency", [value]))


func _format_signed_currency(value: float) -> String:
	return str(_call_root("_format_signed_currency", [value]))


func _format_change(change_pct: float) -> String:
	return str(_call_root("_format_change", [change_pct]))


func _format_history(price_history: Array) -> String:
	return str(_call_root("_format_history", [price_history]))


func _format_compact_currency(value: float) -> String:
	return str(_call_root("_format_compact_currency", [value]))


func _format_signed_compact_currency(value: float) -> String:
	return str(_call_root("_format_signed_compact_currency", [value]))


func _format_compact_lots(value: float) -> String:
	return str(_call_root("_format_compact_lots", [value]))


func _format_signed_compact_lots(value: float) -> String:
	return str(_call_root("_format_signed_compact_lots", [value]))


func _format_grouped_integer(value: int) -> String:
	return str(_call_root("_format_grouped_integer", [value]))


func _format_percent_value(value: float) -> String:
	return str(_call_root("_format_percent_value", [value]))


func _format_signed_percent_value(value: float) -> String:
	return str(_call_root("_format_signed_percent_value", [value]))


func _format_multiple(value: float) -> String:
	return str(_call_root("_format_multiple", [value]))


func _format_last_price(value: float) -> String:
	return str(_call_root("_format_last_price", [value]))


func _format_signed_decimal(value: float, decimal_places: int = 2, use_grouping: bool = true) -> String:
	return str(_call_root("_format_signed_decimal", [value, decimal_places, use_grouping]))


func _format_decimal(value: float, decimal_places: int = 2, use_grouping: bool = true) -> String:
	return str(_call_root("_format_decimal", [value, decimal_places, use_grouping]))


func _join_or_default(values: Array, default_text: String) -> String:
	return str(_call_root("_join_or_default", [values, default_text]))


func _log_perf_elapsed(label: String, started_at_usec: int) -> void:
	_call_root_void("_log_perf_elapsed", [label, started_at_usec])


func _log_perf_phase(enabled: bool, label: String, started_at_usec: int) -> void:
	_call_root_void("_log_perf_phase", [enabled, label, started_at_usec])
