extends Control

const UI_THEME := preload("res://scripts/ui/UITheme.gd")

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
const ACADEMY_CONTROLLER_SCRIPT := preload("res://scripts/ui/controllers/AcademyController.gd")
const COMPANY_CONTROLLER_SCRIPT := preload("res://scripts/ui/controllers/CompanyController.gd")
const NEWS_CONTROLLER_SCRIPT := preload("res://scripts/ui/controllers/NewsController.gd")
const SOCIAL_CONTROLLER_SCRIPT := preload("res://scripts/ui/controllers/SocialController.gd")
const LIFE_CONTROLLER_SCRIPT := preload("res://scripts/ui/controllers/LifeController.gd")
const NETWORK_CONTROLLER_SCRIPT := preload("res://scripts/ui/controllers/NetworkController.gd")
const UPGRADES_CONTROLLER_SCRIPT := preload("res://scripts/ui/controllers/UpgradesController.gd")
const STOCK_CONTROLLER_SCRIPT := preload("res://scripts/ui/controllers/StockController.gd")
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
const COLOR_PANEL_BLUE := UI_THEME.COLOR_PANEL_BLUE
const COLOR_PANEL_BLUE_ALT := UI_THEME.COLOR_PANEL_BLUE_ALT
const COLOR_PANEL_GREEN := UI_THEME.COLOR_PANEL_GREEN
const COLOR_PANEL_GOLD := UI_THEME.COLOR_PANEL_GOLD
const COLOR_BORDER := UI_THEME.COLOR_BORDER
const COLOR_TEXT := UI_THEME.COLOR_TEXT
const COLOR_MUTED := UI_THEME.COLOR_MUTED
const COLOR_POSITIVE := UI_THEME.COLOR_POSITIVE
const COLOR_NEGATIVE := UI_THEME.COLOR_NEGATIVE
const COLOR_WARNING := UI_THEME.COLOR_WARNING
const COLOR_ACCENT := UI_THEME.COLOR_ACCENT
const COLOR_DESKTOP_BG := UI_THEME.COLOR_DESKTOP_BG
const COLOR_DESKTOP_TEXT := UI_THEME.COLOR_DESKTOP_TEXT
const COLOR_DESKTOP_CREAM := UI_THEME.COLOR_DESKTOP_CREAM
const COLOR_DESKTOP_PANEL := UI_THEME.COLOR_DESKTOP_PANEL
const COLOR_DESKTOP_BROWN := UI_THEME.COLOR_DESKTOP_BROWN
const COLOR_DESKTOP_OLIVE := UI_THEME.COLOR_DESKTOP_OLIVE
const COLOR_DESKTOP_GOLD := UI_THEME.COLOR_DESKTOP_GOLD
const COLOR_DESKTOP_FRAME := UI_THEME.COLOR_DESKTOP_FRAME
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
const COLOR_STOCKBOT_BASE := UI_THEME.COLOR_STOCKBOT_BASE
const COLOR_STOCKBOT_SURFACE := UI_THEME.COLOR_STOCKBOT_SURFACE
const COLOR_STOCKBOT_SURFACE_ALT := UI_THEME.COLOR_STOCKBOT_SURFACE_ALT
const COLOR_STOCKBOT_EDGE := UI_THEME.COLOR_STOCKBOT_EDGE
const COLOR_STOCKBOT_EDGE_STRONG := UI_THEME.COLOR_STOCKBOT_EDGE_STRONG
const COLOR_STOCKBOT_TEXT := UI_THEME.COLOR_STOCKBOT_TEXT
const COLOR_STOCKBOT_MUTED := UI_THEME.COLOR_STOCKBOT_MUTED
const COLOR_STOCKBOT_FAINT := UI_THEME.COLOR_STOCKBOT_FAINT
const COLOR_STOCKBOT_BLUE := UI_THEME.COLOR_STOCKBOT_BLUE
const COLOR_STOCKBOT_BLUE_TINT := UI_THEME.COLOR_STOCKBOT_BLUE_TINT
const COLOR_STOCKBOT_BLUE_EDGE := UI_THEME.COLOR_STOCKBOT_BLUE_EDGE
const COLOR_STOCKBOT_BULL := UI_THEME.COLOR_STOCKBOT_BULL
const COLOR_STOCKBOT_BULL_TINT := UI_THEME.COLOR_STOCKBOT_BULL_TINT
const COLOR_STOCKBOT_BULL_EDGE := UI_THEME.COLOR_STOCKBOT_BULL_EDGE
const COLOR_STOCKBOT_BEAR := UI_THEME.COLOR_STOCKBOT_BEAR
const COLOR_STOCKBOT_BEAR_TINT := UI_THEME.COLOR_STOCKBOT_BEAR_TINT
const COLOR_STOCKBOT_BEAR_EDGE := UI_THEME.COLOR_STOCKBOT_BEAR_EDGE
const COLOR_STOCKBOT_AMBER := UI_THEME.COLOR_STOCKBOT_AMBER
const COLOR_STOCK_WINDOW_BG := UI_THEME.COLOR_STOCK_WINDOW_BG
const COLOR_ORDER_PANEL_BG := UI_THEME.COLOR_ORDER_PANEL_BG
const COLOR_ORDER_CARD_BG := UI_THEME.COLOR_ORDER_CARD_BG
const COLOR_ORDER_INPUT_BG := UI_THEME.COLOR_ORDER_INPUT_BG
const COLOR_ORDER_BUY := UI_THEME.COLOR_ORDER_BUY
const COLOR_ORDER_BUY_BORDER := UI_THEME.COLOR_ORDER_BUY_BORDER
const COLOR_ORDER_SELL := UI_THEME.COLOR_ORDER_SELL
const COLOR_ORDER_SELL_BORDER := UI_THEME.COLOR_ORDER_SELL_BORDER
const COLOR_ORDER_METRIC_LABEL := UI_THEME.COLOR_ORDER_METRIC_LABEL
const COLOR_WINDOW_BG := UI_THEME.COLOR_WINDOW_BG
const COLOR_WINDOW_TEXT := UI_THEME.COLOR_WINDOW_TEXT
const COLOR_MARKET_PAPER_PAGE := UI_THEME.COLOR_MARKET_PAPER_PAGE
const COLOR_MARKET_PAPER_CARD := UI_THEME.COLOR_MARKET_PAPER_CARD
const COLOR_MARKET_PAPER_RAIL := UI_THEME.COLOR_MARKET_PAPER_RAIL
const COLOR_MARKET_PAPER_BORDER := UI_THEME.COLOR_MARKET_PAPER_BORDER
const COLOR_MARKET_PAPER_MUTED := UI_THEME.COLOR_MARKET_PAPER_MUTED
const COLOR_MARKET_PAPER_RED := UI_THEME.COLOR_MARKET_PAPER_RED
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
const COLOR_ACADEMY_CREAM := UI_THEME.COLOR_ACADEMY_CREAM
const COLOR_ACADEMY_PANEL := UI_THEME.COLOR_ACADEMY_PANEL
const COLOR_ACADEMY_RAIL := UI_THEME.COLOR_ACADEMY_RAIL
const COLOR_ACADEMY_BROWN := UI_THEME.COLOR_ACADEMY_BROWN
const COLOR_ACADEMY_BORDER := UI_THEME.COLOR_ACADEMY_BORDER
const COLOR_ACADEMY_GREEN := UI_THEME.COLOR_ACADEMY_GREEN
const SHOW_ACADEMY_IMAGE_PLACEHOLDERS := false
const COLOR_NAV_FILL := UI_THEME.COLOR_NAV_FILL
const COLOR_NAV_ACTIVE_FILL := UI_THEME.COLOR_NAV_ACTIVE_FILL
const COLOR_NAV_ACTIVE_BORDER := UI_THEME.COLOR_NAV_ACTIVE_BORDER
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

var selected_company_id: String = ""
var displayed_company_ids: Array = []
var watchlist_picker_company_ids: Array = []
var ftue_overlay: Control = null
var ftue_dim_top: ColorRect = null
var ftue_dim_bottom: ColorRect = null
var ftue_dim_left: ColorRect = null
var ftue_dim_right: ColorRect = null
var ftue_highlight_frame: PanelContainer = null
var ftue_card: PanelContainer = null
var ftue_title_label: Label = null
var ftue_objective_label: Label = null
var ftue_body_label: Label = null
var ftue_status_label: Label = null
var ftue_progress_label: Label = null
var ftue_hub_button: Button = null
var ftue_dismiss_button: Button = null
var ftue_skip_button: Button = null
var ftue_last_step_id: String = ""
var guide_hub_overlay: Control = null
var guide_hub_panel: PanelContainer = null
var guide_hub_flow_list: VBoxContainer = null
var guide_hub_close_button: Button = null
var guide_hub_taskbar_button: Button = null
var guide_hub_help_button: Button = null
var guide_target_name: String = ""
var guide_focus_in_progress: bool = false
var guide_active_flow_id: String = ""
var guide_watchlist_all_stock_seen: bool = false
var guide_watchlist_stock_selected: bool = false
var guide_research_interaction_seen: bool = false
var guide_fundamental_key_stats_seen: bool = false
var guide_fundamental_financials_seen: bool = false
var guide_technical_tool_action_seen: bool = false
var guide_thesis_subject_chosen: bool = false
var guide_thesis_create_action_seen: bool = false
var guide_life_plan_reviewed: bool = false
var guide_life_finance_tab_seen: bool = false
var guide_academy_lesson_chosen: bool = false
var guide_academy_read_action_seen: bool = false
var first_hour_guide_highlight_layer: Control = null
var first_hour_guide_highlight_frame: PanelContainer = null
var first_hour_guide_panel: PanelContainer = null
var first_hour_guide_title_label: Label = null
var first_hour_guide_objective_label: Label = null
var first_hour_guide_body_label: Label = null
var first_hour_guide_status_label: Label = null
var first_hour_guide_progress_label: Label = null
var first_hour_guide_skip_button: Button = null
var first_hour_guide_hide_button: Button = null
var first_hour_guide_collapsed: bool = false
var first_hour_guide_blocked_message: String = ""
var first_hour_guide_target_name: String = ""
var watchlist_picker_dialog: ConfirmationDialog = null
var watchlist_picker_list: ItemList = null
var upgrade_purchase_dialog: ConfirmationDialog = null
var upgrade_purchase_body_label: Label = null
var upgrades_controller = null
var life_controller = null
var console_overlay: Control = null
var console_panel: PanelContainer = null
var console_title_label: Label = null
var console_hint_label: Label = null
var console_input: LineEdit = null
var console_status_label: Label = null
var selected_lots: int = 1
var stock_controller = null
var active_section_id: String = "dashboard"
var active_app_id: String = APP_ID_DESKTOP
var status_message: String = "Ready."
var selected_financial_statement_index: int = -1
var selected_financial_statement_company_id: String = ""
var selected_key_stats_metric: String = KEY_STATS_METRIC_NET_INCOME
var key_stats_capture_menu: PopupMenu = null
var dashboard_sector_capture_menu: PopupMenu = null
var broker_capture_menu: PopupMenu = null
var news_capture_menu: PopupMenu = null
var profile_capture_menu: PopupMenu = null
var financial_statement_capture_menu: PopupMenu = null
var corporate_action_filter_id: String = "all"
var corporate_action_capture_menu: PopupMenu = null
var social_capture_menu: PopupMenu = null
var trade_quote_capture_menu: PopupMenu = null
# One pending research-capture payload per source kind (key stats, broker,
# social, ...). Committed and cleared by _commit_pending_capture.
var pending_capture_payloads: Dictionary = {}
var current_trade_snapshot: Dictionary = {}
var cached_company_rows: Array = []
var cached_company_row_lookup: Dictionary = {}
var has_cached_company_rows: bool = false
var all_stock_rows_dirty: bool = true
var portfolio_stock_rows_dirty: bool = true
var current_social_snapshot: Dictionary = {}
var current_network_snapshot: Dictionary = {}
var current_corporate_meeting_id: String = ""
var debug_generator_buttons: Dictionary = {}
var debug_corporate_action_buttons: Dictionary = {}
var debug_index_review_buttons: Dictionary = {}
var debug_company_roadmap_buttons: Dictionary = {}
var debug_life_development_buttons: Dictionary = {}
var debug_start_rupslb_button: Button = null
var debug_start_rupslb_status_label: Label = null
var debug_index_review_status_label: Label = null
var debug_company_control_button: Button = null
var debug_company_control_status_label: Label = null
var debug_company_roadmap_status_label: Label = null
var debug_life_development_status_label: Label = null
var debug_dirty_tip_button: Button = null
var debug_jail_button: Button = null
var debug_hospital_button: Button = null
var debug_jail_status_label: Label = null
var contact_intel_panel: PanelContainer = null
var contact_intel_option: OptionButton = null
var contact_intel_button: Button = null
var contact_intel_status_label: Label = null
var order_market_value_labels: Dictionary = {}
var order_market_name_labels: Dictionary = {}
var company_app_button: Button = null
var company_app_label: Label = null
var company_window: MarginContainer = null
var company_status_label: Label = null
var company_controlled_option: OptionButton = null
var company_detail_label: Label = null
var company_agenda_label: Label = null
var company_agenda_option: OptionButton = null
var company_request_button: Button = null
var company_controller = null
var news_controller = null
var social_controller = null
var cached_app_font: Font = null
var has_checked_app_font: bool = false
var cached_dashboard_title_font: Font = null
var has_checked_dashboard_title_font: bool = false
var defer_next_dashboard_heavy_refresh: bool = false
var dashboard_heavy_refresh_pending: bool = false
var suppress_next_portfolio_refresh: bool = false
var pending_watchlist_selected_company_id: String = ""
var pending_watchlist_target_tab: int = -1
var suppress_stock_list_tab_refresh: bool = false
var selected_dashboard_sector_id: String = ""
var active_order_side: String = "buy"
var order_ticket_collapsed: bool = false
var broker_net_mode: bool = false
var selected_broker_range_id: String = "1d"
var broker_range_buttons: Dictionary = {}
var broker_range_row: HBoxContainer = null
var trade_workspace_detail_cache_key: String = ""
var trade_workspace_profile_cache_key: String = ""
var trade_workspace_financial_history_cache_key: String = ""
var trade_workspace_key_stats_cache_key: String = ""
var trade_workspace_broker_cache_key: String = ""
var trade_workspace_corporate_action_cache_key: String = ""
var trade_workspace_statement_cache_key: String = ""
var selected_network_contact_id: String = ""
var selected_network_journal_id: String = ""
var selected_network_journal_filter: String = "all"
var network_controller = null
var academy_controller = null
var expanded_social_thread_ids: Dictionary = {}
var selected_social_account_id: String = ""
var selected_social_feed_filter_id: String = SOCIAL_FEED_FILTER_ALL
var selected_social_view_id: String = "home"
var selected_social_message_account_id: String = ""
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
@onready var network_app_button: Button = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow/NetworkAppTile/NetworkAppButton
@onready var network_app_label: Label = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow/NetworkAppTile/NetworkAppLabel
var academy_app_button: Button = null
var academy_app_label: Label = null
var thesis_app_button: Button = null
var thesis_app_label: Label = null
var life_app_button: Button = null
var life_app_label: Label = null
@onready var upgrades_app_button: Button = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow/UpgradesAppTile/UpgradesAppButton
@onready var upgrades_app_label: Label = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow/UpgradesAppTile/UpgradesAppLabel
@onready var exit_app_button: Button = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow/ExitAppTile/ExitAppButton
@onready var exit_app_label: Label = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow/ExitAppTile/ExitAppLabel
var desktop_figma_top_bar: PanelContainer = null
var desktop_figma_top_margin: MarginContainer = null
var desktop_figma_date_label: Label = null
var desktop_figma_cash_panel: PanelContainer = null
var desktop_figma_cash_label: Label = null
var desktop_advance_day_button: Button = null
var desktop_figma_canvas_panel: PanelContainer = null
var desktop_figma_canvas_margin: MarginContainer = null
var desktop_figma_canvas_content_margin: MarginContainer = null
var desktop_shortcut_grid: GridContainer = null
var desktop_bottom_nav_bar: PanelContainer = null
var desktop_bottom_nav_buttons: Dictionary = {}
var desktop_shortcut_badges: Dictionary = {}
var desktop_window_layer: Control = null
var desktop_app_windows: Dictionary = {}
var desktop_dragging_app_id: String = ""
var desktop_drag_offset: Vector2 = Vector2.ZERO
var advance_day_processing: bool = false
# Coalesced no-arg refresh signals: handlers queued in arrival order, flushed
# once at end of frame so same-frame duplicate signals refresh the UI once.
var pending_signal_refresh_handlers: Array = []
var signal_refresh_flush_scheduled: bool = false
var deferred_open_app_refresh_queue: Array = []
var deferred_open_app_refresh_scheduled: bool = false
var deferred_dashboard_refresh_after_recap: bool = false
var deferred_full_refresh_after_recap: bool = false
var advance_day_post_recap_save_flush_scheduled: bool = false
var pending_daily_recap_snapshot: Dictionary = {}
var daily_recap_dialog: Control = null
var daily_recap_body_label: Label = null
var daily_recap_continue_button: Button = null
var pending_macro_event_alerts: Array = []
var current_macro_event_alert: Dictionary = {}
var macro_event_dialog: Control = null
var macro_event_headline_label: Label = null
var macro_event_close_button: Button = null
var pending_dirty_tip_alerts: Array = []
var current_dirty_tip_alert: Dictionary = {}
var dirty_tip_dialog: Control = null
var dirty_tip_body_label: Label = null
var dirty_tip_accept_button: Button = null
var dirty_tip_decline_button: Button = null
var dirty_tip_report_button: Button = null
var dirty_tip_close_button: Button = null
var advance_day_button_tween: Tween = null
var daily_recap_tween: Tween = null
var macro_event_tween: Tween = null
var desktop_window_open_tweens: Dictionary = {}
var desktop_window_focus_tweens: Dictionary = {}
var stockbot_icon_cache: Dictionary = {}
var settings_dialog: Control = null
var settings_panel: PanelContainer = null
var settings_title_bar: PanelContainer = null
var settings_title_label: Label = null
var settings_build_label: Label = null
var settings_close_button: Button = null
var settings_current_slot_label: Label = null
var settings_last_saved_label: Label = null
var settings_autosave_checkbox: CheckBox = null
var settings_save_slots_list: ItemList = null
var settings_status_label: Label = null
var settings_save_button: Button = null
var settings_load_button: Button = null
var settings_delete_button: Button = null
var settings_exit_button: Button = null
var settings_confirm_overlay: Control = null
var settings_confirm_title_label: Label = null
var settings_confirm_body_label: Label = null
var settings_confirm_confirm_button: Button = null
var settings_confirm_cancel_button: Button = null
var pending_settings_confirm_action: String = ""
var pending_settings_confirm_slot_id: String = ""
var selected_settings_slot_id: String = ""
var bankruptcy_overlay: Control = null
var bankruptcy_body_label: Label = null
var bankruptcy_menu_button: Button = null
var bankruptcy_restart_button: Button = null
var stress_meter_panel: PanelContainer = null
var stress_meter_bar: ProgressBar = null
var stress_meter_title_label: Label = null
var stress_meter_label: Label = null
var hospital_overlay: Control = null
var hospital_body_label: Label = null
var hospital_advance_button: Button = null
var jail_overlay: Control = null
var jail_body_label: Label = null
var jail_advance_button: Button = null
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
@onready var news_meet_contact_button: Button = $NewsWindow/NewsWindowBody/NewsWindowMargin/NewsWindowVBox/NewsContentSplit/NewsDetailPanel/NewsDetailMargin/NewsDetailVBox/NewsMeetContactButton
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
@onready var social_window: MarginContainer = $SocialWindow
@onready var social_window_body: PanelContainer = $SocialWindow/SocialWindowBody
@onready var social_title_label: Label = $SocialWindow/SocialWindowBody/SocialWindowMargin/SocialWindowVBox/SocialHeaderRow/SocialTitleLabel
@onready var social_access_status_label: Label = $SocialWindow/SocialWindowBody/SocialWindowMargin/SocialWindowVBox/SocialHeaderRow/SocialAccessStatusLabel
@onready var social_feed_summary_label: Label = $SocialWindow/SocialWindowBody/SocialWindowMargin/SocialWindowVBox/SocialFeedSummaryLabel
@onready var social_feed_scroll: ScrollContainer = $SocialWindow/SocialWindowBody/SocialWindowMargin/SocialWindowVBox/SocialFeedScroll
@onready var social_feed_cards: VBoxContainer = $SocialWindow/SocialWindowBody/SocialWindowMargin/SocialWindowVBox/SocialFeedScroll/SocialFeedCards
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
@onready var network_window: MarginContainer = $NetworkWindow
@onready var network_window_body: PanelContainer = $NetworkWindow/NetworkWindowBody
@onready var network_title_label: Label = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkHeaderRow/NetworkTitleLabel
@onready var network_recognition_label: Label = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkHeaderRow/NetworkRecognitionLabel
@onready var network_summary_label: Label = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkSummaryLabel
@onready var network_list_panel: PanelContainer = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkContentSplit/NetworkListPanel
@onready var network_detail_panel: PanelContainer = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkContentSplit/NetworkDetailPanel
@onready var network_contacts_label: Label = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkContentSplit/NetworkListPanel/NetworkListMargin/NetworkListVBox/NetworkContactsLabel
@onready var network_contacts_list: ItemList = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkContentSplit/NetworkListPanel/NetworkListMargin/NetworkListVBox/NetworkContactsList
@onready var network_requests_label: Label = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkContentSplit/NetworkListPanel/NetworkListMargin/NetworkListVBox/NetworkRequestsLabel
@onready var network_requests_list: ItemList = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkContentSplit/NetworkListPanel/NetworkListMargin/NetworkListVBox/NetworkRequestsList
@onready var network_contact_name_label: Label = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkContentSplit/NetworkDetailPanel/NetworkDetailMargin/NetworkDetailVBox/NetworkContactNameLabel
@onready var network_contact_meta_label: Label = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkContentSplit/NetworkDetailPanel/NetworkDetailMargin/NetworkDetailVBox/NetworkContactMetaLabel
@onready var network_contact_body_label: Label = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkContentSplit/NetworkDetailPanel/NetworkDetailMargin/NetworkDetailVBox/NetworkContactBodyLabel
@onready var network_meet_button: Button = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkContentSplit/NetworkDetailPanel/NetworkDetailMargin/NetworkDetailVBox/NetworkActionRow/NetworkMeetButton
@onready var network_tip_button: Button = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkContentSplit/NetworkDetailPanel/NetworkDetailMargin/NetworkDetailVBox/NetworkActionRow/NetworkTipButton
@onready var network_request_button: Button = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkContentSplit/NetworkDetailPanel/NetworkDetailMargin/NetworkDetailVBox/NetworkActionRow/NetworkRequestButton
@onready var network_referral_button: Button = $NetworkWindow/NetworkWindowBody/NetworkWindowMargin/NetworkWindowVBox/NetworkContentSplit/NetworkDetailPanel/NetworkDetailMargin/NetworkDetailVBox/NetworkActionRow/NetworkReferralButton
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
var academy_window: MarginContainer = null
var academy_window_body: PanelContainer = null
var thesis_window: MarginContainer = null
var life_window: MarginContainer = null
var academy_title_label: Label = null
var academy_progress_label: Label = null
var academy_category_tabs: HBoxContainer = null
var academy_section_tabs: GridContainer = null
var academy_summary_label: Label = null
var academy_section_list: ItemList = null
var academy_selection_chip_label: Label = null
var academy_lesson_title_label: Label = null
var academy_lesson_meta_label: Label = null
var academy_lesson_banner_frame: PanelContainer = null
var academy_lesson_banner_label: Label = null
var academy_lesson_scroll: ScrollContainer = null
var academy_lesson_content_vbox: VBoxContainer = null
var academy_action_row: HBoxContainer = null
var academy_mark_read_button: Button = null
var academy_next_button: Button = null
var academy_side_title_label: Label = null
var academy_side_body_label: Label = null
var academy_glossary_search_input: LineEdit = null
var academy_glossary_list: ItemList = null
@onready var upgrade_window: MarginContainer = $UpgradeWindow
@onready var upgrade_window_body: PanelContainer = $UpgradeWindow/UpgradeWindowBody
@onready var upgrade_title_label: Label = $UpgradeWindow/UpgradeWindowBody/UpgradeWindowMargin/UpgradeWindowVBox/UpgradeHeaderRow/UpgradeTitleLabel
@onready var upgrade_cash_label: Label = $UpgradeWindow/UpgradeWindowBody/UpgradeWindowMargin/UpgradeWindowVBox/UpgradeHeaderRow/UpgradeCashLabel
@onready var upgrade_summary_label: Label = $UpgradeWindow/UpgradeWindowBody/UpgradeWindowMargin/UpgradeWindowVBox/UpgradeSummaryLabel
@onready var upgrade_cards_vbox: VBoxContainer = $UpgradeWindow/UpgradeWindowBody/UpgradeWindowMargin/UpgradeWindowVBox/UpgradeScroll/UpgradeCardsVBox
@onready var app_window_title_bar: PanelContainer = $AppWindowTitleBar
@onready var app_window_title_label: Label = $AppWindowTitleBar/AppWindowTitleMargin/AppWindowTitleRow/AppWindowTitleLabel
@onready var app_window_minimize_button: Button = $AppWindowTitleBar/AppWindowTitleMargin/AppWindowTitleRow/AppWindowMinimizeButton
@onready var app_window_close_button: Button = $AppWindowTitleBar/AppWindowTitleMargin/AppWindowTitleRow/AppWindowCloseButton
@onready var taskbar_panel: PanelContainer = $TaskbarLayer/TaskbarPanel
@onready var taskbar_layer: MarginContainer = $TaskbarLayer
@onready var taskbar_home_button: Button = $TaskbarLayer/TaskbarPanel/TaskbarMargin/TaskbarRow/TaskbarHomeButton
@onready var taskbar_stock_button: Button = $TaskbarLayer/TaskbarPanel/TaskbarMargin/TaskbarRow/TaskbarStockButton
@onready var taskbar_news_button: Button = $TaskbarLayer/TaskbarPanel/TaskbarMargin/TaskbarRow/TaskbarNewsButton
@onready var taskbar_status_label: Label = $TaskbarLayer/TaskbarPanel/TaskbarMargin/TaskbarRow/TaskbarStatusLabel
@onready var taskbar_build_label: Label = $TaskbarLayer/TaskbarPanel/TaskbarMargin/TaskbarRow/TaskbarBuildLabel
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
@onready var dashboard_index_stats_grid: GridContainer = %DashboardView/DashboardGrid/IndexPanel/IndexMargin/IndexVBox/IndexStatsGrid
@onready var dashboard_index_points_value_label: Label = %DashboardView/DashboardGrid/IndexPanel/IndexMargin/IndexVBox/IndexStatsGrid/IndexPointsValueLabel
@onready var dashboard_index_lots_value_label: Label = %DashboardView/DashboardGrid/IndexPanel/IndexMargin/IndexVBox/IndexStatsGrid/IndexLotsValueLabel
@onready var dashboard_index_value_value_label: Label = %DashboardView/DashboardGrid/IndexPanel/IndexMargin/IndexVBox/IndexStatsGrid/IndexValueValueLabel
@onready var dashboard_index_hint_label: Label = %DashboardView/DashboardGrid/IndexPanel/IndexMargin/IndexVBox/IndexHintLabel
@onready var dashboard_movers_panel: PanelContainer = %DashboardView/DashboardGrid/MoversPanel
@onready var dashboard_movers_title_label: Label = %DashboardView/DashboardGrid/MoversPanel/MoversMargin/MoversVBox/MoversTitleLabel
@onready var dashboard_movers_tabs: TabContainer = %DashboardView/DashboardGrid/MoversPanel/MoversMargin/MoversVBox/MoversTabs
@onready var dashboard_top_gainers_rows: VBoxContainer = %DashboardView/DashboardGrid/MoversPanel/MoversMargin/MoversVBox/MoversTabs/TopGainers/TopGainersRows
@onready var dashboard_top_gainers_empty_label: Label = %DashboardView/DashboardGrid/MoversPanel/MoversMargin/MoversVBox/MoversTabs/TopGainers/TopGainersRows/TopGainersEmptyLabel
@onready var dashboard_top_losers_rows: VBoxContainer = %DashboardView/DashboardGrid/MoversPanel/MoversMargin/MoversVBox/MoversTabs/TopLosers/TopLosersRows
@onready var dashboard_top_losers_empty_label: Label = %DashboardView/DashboardGrid/MoversPanel/MoversMargin/MoversVBox/MoversTabs/TopLosers/TopLosersRows/TopLosersEmptyLabel
var dashboard_top_broker_flow_rows: VBoxContainer = null
var dashboard_top_broker_flow_empty_label: Label = null
@onready var dashboard_calendar_panel: PanelContainer = %DashboardView/DashboardGrid/CalendarPanel
@onready var dashboard_calendar_title_label: Label = %DashboardView/DashboardGrid/CalendarPanel/CalendarMargin/CalendarVBox/CalendarTitleLabel
@onready var dashboard_calendar_month_label: Label = %DashboardView/DashboardGrid/CalendarPanel/CalendarMargin/CalendarVBox/CalendarMonthLabel
@onready var dashboard_calendar_week_header: GridContainer = %DashboardView/DashboardGrid/CalendarPanel/CalendarMargin/CalendarVBox/CalendarWeekHeader
@onready var dashboard_calendar_days_grid: GridContainer = %DashboardView/DashboardGrid/CalendarPanel/CalendarMargin/CalendarVBox/CalendarDaysGrid
@onready var dashboard_placeholder_bottom_panel: PanelContainer = %DashboardView/DashboardGrid/PlaceholderBottomPanel
@onready var dashboard_placeholder_bottom_title_label: Label = %DashboardView/DashboardGrid/PlaceholderBottomPanel/PlaceholderBottomMargin/PlaceholderBottomVBox/PlaceholderBottomTitleLabel
@onready var dashboard_placeholder_bottom_body_label: Label = %DashboardView/DashboardGrid/PlaceholderBottomPanel/PlaceholderBottomMargin/PlaceholderBottomVBox/PlaceholderBottomBodyLabel

@onready var trade_split: HBoxContainer = %MarketsView/TradeSplit
@onready var main_trade_split: HBoxContainer = %MarketsView/TradeSplit/MainSplit
@onready var watchlist_panel: PanelContainer = %MarketsView/TradeSplit/WatchlistPanel
@onready var work_area_panel: PanelContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel
@onready var order_ticket_toggle_button: Button = %MarketsView/TradeSplit/MainSplit/OrderTicketToggleButton
@onready var action_panel: PanelContainer = %MarketsView/TradeSplit/MainSplit/ActionPanel
@onready var stock_list_tabs: TabContainer = %MarketsView/TradeSplit/WatchlistPanel/WatchlistMargin/WatchlistVBox/StockListTabs
@onready var add_watchlist_button: Button = %MarketsView/TradeSplit/WatchlistPanel/WatchlistMargin/WatchlistVBox/StockListTabs/WatchlistTab/WatchlistActionRow/AddWatchlistButton
@onready var remove_watchlist_button: Button = %MarketsView/TradeSplit/WatchlistPanel/WatchlistMargin/WatchlistVBox/StockListTabs/WatchlistTab/WatchlistActionRow/RemoveWatchlistButton
@onready var watchlist_empty_label: Label = %MarketsView/TradeSplit/WatchlistPanel/WatchlistMargin/WatchlistVBox/StockListTabs/WatchlistTab/WatchlistEmptyLabel
@onready var company_list: ItemList = %MarketsView/TradeSplit/WatchlistPanel/WatchlistMargin/WatchlistVBox/StockListTabs/WatchlistTab/CompanyList
@onready var all_stocks_search_input: LineEdit = %MarketsView/TradeSplit/WatchlistPanel/WatchlistMargin/WatchlistVBox/StockListTabs/AllStocksTab/AllStocksSearchInput
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
@onready var corporate_actions_panel: PanelContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/CorporateActions/CorporateActionsPanel
@onready var corporate_actions_filter_option: OptionButton = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/CorporateActions/CorporateActionsPanel/CorporateActionsMargin/CorporateActionsVBox/CorporateActionsFilterRow/CorporateActionsFilterOption
@onready var corporate_actions_summary_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/CorporateActions/CorporateActionsPanel/CorporateActionsMargin/CorporateActionsVBox/CorporateActionsSummaryLabel
@onready var corporate_actions_rows_vbox: VBoxContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/CorporateActions/CorporateActionsPanel/CorporateActionsMargin/CorporateActionsVBox/CorporateActionsRows
@onready var corporate_actions_empty_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/CorporateActions/CorporateActionsPanel/CorporateActionsMargin/CorporateActionsVBox/CorporateActionsRows/CorporateActionsEmptyLabel
@onready var profile_panel: PanelContainer = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel
@onready var profile_company_name_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfileCompanyNameLabel
@onready var profile_sector_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfileSectorLabel
@onready var profile_price_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfilePriceLabel
@onready var profile_factor_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfileFactorLabel
@onready var profile_management_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfileManagementLabel
@onready var profile_shareholders_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfileShareholdersLabel
@onready var profile_tags_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfileTagsLabel
@onready var profile_description_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfileDescriptionLabel
@onready var profile_network_hint_label: Label = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfileNetworkHintLabel
@onready var profile_meet_contact_button: Button = %MarketsView/TradeSplit/MainSplit/WorkAreaPanel/WorkAreaMargin/WorkAreaVBox/WorkTabs/Profile/ProfilePanel/ProfileMargin/ProfileVBox/ProfileMeetContactButton
@onready var order_company_name_label: Label = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/HeaderVBox/MarketHeaderRow/CompanyNameLabel
@onready var selection_label: Label = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/HeaderVBox/SelectionLabel
@onready var order_price_value_label: Label = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/HeaderVBox/MarketHeaderRow/CurrentPriceLabel
@onready var order_price_change_label: Label = %MarketsView/TradeSplit/MainSplit/ActionPanel/ActionMargin/ActionVBox/HeaderVBox/MarketHeaderRow/PriceChangeLabel
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
@onready var help_title_label: Label = %HelpView/HelpPanel/HelpMargin/HelpVBox/HelpTitle
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
var dashboard_meeting_buttons: VBoxContainer = null
var dashboard_calendar_event_popup: Control = null
var dashboard_calendar_event_title_label: Label = null
var dashboard_calendar_event_body_label: Label = null
var dashboard_calendar_event_actions_vbox: VBoxContainer = null
var dashboard_calendar_event_close_button: Button = null
var dashboard_index_recap_panel: VBoxContainer = null
var dashboard_index_points_label: Label = null
var dashboard_index_change_label: Label = null
var dashboard_index_sparkline: Control = null
var dashboard_index_all_market_rows: VBoxContainer = null
var dashboard_index_all_market_lot_value_label: Label = null
var dashboard_index_all_market_value_value_label: Label = null
var dashboard_sector_cards_scroll: ScrollContainer = null
var dashboard_sector_cards_grid: GridContainer = null
var dashboard_sector_detail_vbox: VBoxContainer = null
var dashboard_sector_back_button: Button = null
var dashboard_sector_detail_title_label: Label = null
var dashboard_sector_detail_rows: VBoxContainer = null
var corporate_meeting_overlay: Control = null
var corporate_meeting_panel: PanelContainer = null
var corporate_meeting_title_label: Label = null
var corporate_meeting_meta_label: Label = null
var corporate_meeting_summary_label: Label = null
var corporate_meeting_agenda_label: Label = null
var corporate_meeting_intel_label: Label = null
var corporate_meeting_attendance_label: Label = null
var corporate_meeting_attend_button: Button = null
var corporate_meeting_close_button: Button = null
var rupslb_meeting_overlay: Control = null
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


func _ensure_stock_controller() -> void:
	if stock_controller != null:
		return
	stock_controller = STOCK_CONTROLLER_SCRIPT.new()
	stock_controller.setup(self)

func _ensure_network_controller() -> void:
	if network_controller != null:
		return
	network_controller = NETWORK_CONTROLLER_SCRIPT.new()
	network_controller.setup(self, {
		"window": network_window,
		"window_body": network_window_body,
		"title_label": network_title_label,
		"recognition_label": network_recognition_label,
		"summary_label": network_summary_label,
		"list_panel": network_list_panel,
		"detail_panel": network_detail_panel,
		"contacts_label": network_contacts_label,
		"contacts_list": network_contacts_list,
		"requests_label": network_requests_label,
		"requests_list": network_requests_list,
		"contact_name_label": network_contact_name_label,
		"contact_meta_label": network_contact_meta_label,
		"contact_body_label": network_contact_body_label,
		"meet_button": network_meet_button,
		"tip_button": network_tip_button,
		"request_button": network_request_button,
		"referral_button": network_referral_button
	})


func _ensure_upgrades_controller() -> void:
	if upgrades_controller != null:
		return
	upgrades_controller = UPGRADES_CONTROLLER_SCRIPT.new()
	upgrades_controller.setup(self, {
		"window": upgrade_window,
		"window_body": upgrade_window_body,
		"title_label": upgrade_title_label,
		"cash_label": upgrade_cash_label,
		"summary_label": upgrade_summary_label,
		"cards_vbox": upgrade_cards_vbox
	})


func _ensure_life_controller() -> void:
	if life_controller != null:
		return
	life_controller = LIFE_CONTROLLER_SCRIPT.new()
	life_controller.setup(self)


func _ensure_company_controller() -> void:
	if company_controller != null:
		return
	company_controller = COMPANY_CONTROLLER_SCRIPT.new()
	company_controller.setup(self)


func _ensure_news_controller() -> void:
	if news_controller != null:
		return
	news_controller = NEWS_CONTROLLER_SCRIPT.new()
	news_controller.setup(self)


func _ensure_social_controller() -> void:
	if social_controller != null:
		return
	social_controller = SOCIAL_CONTROLLER_SCRIPT.new()
	social_controller.setup(self)


func _ready() -> void:
	_ensure_ftue_overlay()
	_ensure_first_hour_guide_ui()
	_ensure_watchlist_picker_dialog()
	_ensure_upgrades_controller()
	_ensure_upgrade_purchase_dialog()
	_ensure_settings_dialog()
	_ensure_bankruptcy_overlay()
	_ensure_hospital_overlay()
	_ensure_jail_overlay()
	_ensure_daily_recap_dialog()
	_ensure_macro_event_dialog()
	_ensure_dirty_tip_dialog()
	_ensure_dashboard_calendar_event_popup()
	_ensure_dashboard_index_recap_ui()
	_ensure_dashboard_broker_flow_ui()
	_ensure_dashboard_sector_ui()
	_ensure_console_overlay()
	_ensure_academy_ui()
	_ensure_thesis_ui()
	_ensure_life_ui()
	_ensure_company_ui()
	_ensure_network_controller()
	_ensure_corporate_action_ui()
	_ensure_news_newspaper_ui()
	_ensure_social_feed_ui()
	_ensure_figma_desktop_ui()
	_ensure_stress_meter_ui()
	_cache_order_market_summary_labels()
	_ensure_profile_company_layout()
	_ensure_desktop_window_layer()
	_initialize_desktop_app_windows()
	_initialize_desktop_badge_seen_defaults()
	_ensure_key_stats_dashboard_ui()
	_ensure_broker_range_controls()
	_remove_financial_and_broker_helper_text()
	_style_dashboard_calendar_grid()
	_apply_visual_theme()
	_apply_compact_layout()
	_apply_trade_layout_ratios()
	_hide_toast()
	stock_list_tabs.set_tab_title(STOCK_LIST_TAB_WATCHLIST, "Watchlist")
	stock_list_tabs.set_tab_title(STOCK_LIST_TAB_ALL_STOCKS, "All Stock")
	stock_list_tabs.set_tab_title(STOCK_LIST_TAB_PORTFOLIO, "Portfolio")
	stock_app_button.pressed.connect(_set_active_app.bind(APP_ID_STOCK))
	news_app_button.pressed.connect(_set_active_app.bind(APP_ID_NEWS))
	social_app_button.pressed.connect(_set_active_app.bind(APP_ID_SOCIAL))
	network_app_button.pressed.connect(_set_active_app.bind(APP_ID_NETWORK))
	if academy_app_button != null:
		academy_app_button.pressed.connect(_on_academy_app_pressed)
	if thesis_app_button != null:
		thesis_app_button.pressed.connect(_on_thesis_app_pressed)
	if life_app_button != null:
		life_app_button.pressed.connect(_set_active_app.bind(APP_ID_LIFE))
	if company_app_button != null:
		company_app_button.pressed.connect(_set_active_app.bind(APP_ID_COMPANY))
	upgrades_app_button.pressed.connect(_set_active_app.bind(APP_ID_UPGRADES))
	exit_app_button.pressed.connect(_on_settings_app_pressed)
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
	work_tabs.tab_changed.connect(_on_work_tab_changed)
	if trade_workspace_widget.has_signal("chart_interaction"):
		trade_workspace_widget.chart_interaction.connect(_on_guide_chart_interaction)
	elif trade_workspace_widget.has_signal("chart_range_changed"):
		trade_workspace_widget.chart_range_changed.connect(_on_guide_chart_interaction)
	add_watchlist_button.pressed.connect(_on_add_watchlist_pressed)
	remove_watchlist_button.pressed.connect(_on_remove_watchlist_pressed)
	all_stocks_search_input.text_changed.connect(_on_all_stock_search_text_changed)
	financials_previous_button.pressed.connect(_on_financials_previous_pressed)
	financials_next_button.pressed.connect(_on_financials_next_pressed)
	broker_net_toggle.toggled.connect(_on_broker_net_toggled)
	_populate_corporate_action_filter()
	corporate_actions_filter_option.item_selected.connect(_on_corporate_action_filter_selected)
	company_list.item_selected.connect(_on_company_selected)
	news_article_list.item_selected.connect(_on_news_article_selected)
	news_meet_contact_button.pressed.connect(_on_news_meet_contact_pressed)
	news_detail_headline_label.mouse_filter = Control.MOUSE_FILTER_STOP
	news_detail_headline_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	news_detail_headline_label.tooltip_text = "Right-click to capture this headline."
	news_detail_headline_label.gui_input.connect(_on_news_headline_gui_input)
	news_detail_body.mouse_filter = Control.MOUSE_FILTER_STOP
	news_detail_body.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	news_detail_body.tooltip_text = "Right-click to capture article evidence."
	news_detail_body.gui_input.connect(_on_news_body_gui_input)
	news_detail_hint_label.mouse_filter = Control.MOUSE_FILTER_STOP
	news_detail_hint_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	news_detail_hint_label.tooltip_text = "Right-click to capture this source lead."
	news_detail_hint_label.gui_input.connect(_on_news_source_hint_gui_input)
	news_archive_year_option.item_selected.connect(_on_news_archive_year_selected)
	news_archive_month_option.item_selected.connect(_on_news_archive_month_selected)
	profile_meet_contact_button.pressed.connect(_on_profile_meet_contact_pressed)
	lot_spin_box.value_changed.connect(_on_lot_size_changed)
	order_ticket_toggle_button.pressed.connect(_on_order_ticket_toggle_pressed)
	buy_button.pressed.connect(_on_buy_side_pressed)
	sell_button.pressed.connect(_on_sell_side_pressed)
	submit_order_button.pressed.connect(_on_submit_order_pressed)
	get_viewport().size_changed.connect(_update_responsive_layout)
	# No-arg refresh signals are coalesced: same-frame duplicates collapse to
	# one handler run at end of frame, in arrival order (see _queue_signal_refresh).
	# Arg-carrying signals (price_formed, summary_ready, company_detail_ready)
	# stay direct — unique payloads, not double-refresh sources.
	GameManager.portfolio_changed.connect(_queue_signal_refresh.bind(_on_portfolio_changed))
	GameManager.watchlist_changed.connect(_queue_signal_refresh.bind(_on_watchlist_changed))
	GameManager.network_changed.connect(_queue_signal_refresh.bind(_on_network_changed))
	GameManager.social_changed.connect(_queue_signal_refresh.bind(_refresh_social))
	GameManager.thesis_changed.connect(_queue_signal_refresh.bind(_on_thesis_changed))
	GameManager.upgrades_changed.connect(_queue_signal_refresh.bind(_on_upgrades_changed))
	GameManager.life_changed.connect(_queue_signal_refresh.bind(_on_life_changed))
	GameManager.daily_actions_changed.connect(_queue_signal_refresh.bind(_refresh_daily_action_displays))
	GameManager.academy_changed.connect(_queue_signal_refresh.bind(_refresh_academy))
	GameManager.price_formed.connect(_on_day_progressed)
	GameManager.summary_ready.connect(_on_summary_ready)
	GameManager.company_detail_ready.connect(_on_company_detail_ready)
	SaveManager.save_status_changed.connect(_on_save_status_changed)
	stock_app_button.tooltip_text = "Open STOCKBOT."
	news_app_button.tooltip_text = "Open the event-driven news desk."
	social_app_button.tooltip_text = "Open Twooter."
	network_app_button.tooltip_text = "Open the relationship network."
	if academy_app_button != null:
		academy_app_button.tooltip_text = "Open Academy lessons." if GameManager.is_academy_available() else GameManager.get_academy_release_message()
	if thesis_app_button != null:
		thesis_app_button.tooltip_text = "Open Thesis Board."
	if life_app_button != null:
		life_app_button.tooltip_text = "Open Life planning."
	if company_app_button != null:
		company_app_button.tooltip_text = "Open Company management."
	upgrades_app_button.tooltip_text = "Open the upgrades shop."
	exit_app_button.tooltip_text = "Open Settings, save, load, or exit."
	taskbar_home_button.tooltip_text = "Return to the desktop."
	taskbar_stock_button.tooltip_text = "Open STOCKBOT."
	taskbar_news_button.tooltip_text = "Open the event-driven news desk."
	financials_previous_button.tooltip_text = "View the previous quarter."
	financials_next_button.tooltip_text = "View the next quarter."
	broker_net_toggle.tooltip_text = "Toggle net broker flow so each broker appears on only one side."
	_refresh_broker_range_buttons()
	buy_button.tooltip_text = "Switch the ticket to buy mode."
	sell_button.tooltip_text = "Switch the ticket to sell mode."
	order_ticket_toggle_button.tooltip_text = "Hide the order ticket."
	submit_order_button.tooltip_text = "Submit the active order."
	news_meet_contact_button.tooltip_text = "Meet the contact connected to this story."
	profile_meet_contact_button.visible = false
	profile_meet_contact_button.disabled = true
	profile_meet_contact_button.tooltip_text = ""
	network_meet_button.tooltip_text = "Meet the selected discovered contact."
	network_tip_button.tooltip_text = "Ask the selected contact for a market read."
	network_request_button.tooltip_text = "Accept a position request from the selected contact."
	network_referral_button.tooltip_text = "Ask a trusted floater to introduce a company insider."
	_build_debug_generator_controls()
	call_deferred("_update_responsive_layout")
	_set_active_section(active_section_id)
	_set_active_app(APP_ID_DESKTOP)
	defer_next_dashboard_heavy_refresh = true
	_refresh_all()
	_apply_global_font_size_overrides()
	call_deferred("_start_background_company_detail_hydration_after_startup")
	call_deferred("_show_ftue_if_needed")
	call_deferred("_show_first_hour_guide_if_needed")
	call_deferred("_bind_thesis_guide_controls")
	call_deferred("_bind_life_guide_tabs")
	call_deferred("_apply_academy_release_lock_state")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event
		if _is_console_toggle_key(key_event):
			_toggle_console_overlay()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				var clicked_app_id: String = _desktop_window_id_at_position(mouse_button.position)
				if not clicked_app_id.is_empty():
					_focus_desktop_app_window(clicked_app_id)
			elif not desktop_dragging_app_id.is_empty():
				desktop_dragging_app_id = ""
	if event is InputEventMouseMotion and not desktop_dragging_app_id.is_empty():
		var mouse_motion: InputEventMouseMotion = event
		_update_desktop_window_drag(mouse_motion.position)
		_refresh_ftue_overlay()
		_refresh_first_hour_guide_panel()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event
		if key_event.ctrl_pressed and key_event.keycode == KEY_L:
			if OS.is_debug_build():
				_toggle_debug_overlay()
				get_viewport().set_input_as_handled()
			return
		if console_overlay != null and console_overlay.visible and key_event.keycode == KEY_ESCAPE:
			_hide_console_overlay()
			get_viewport().set_input_as_handled()
			return
		if macro_event_dialog != null and macro_event_dialog.visible:
			if key_event.keycode == KEY_ESCAPE:
				_dismiss_current_macro_event_alert()
				get_viewport().set_input_as_handled()
				return
			if key_event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
				_on_macro_event_confirm_pressed()
				get_viewport().set_input_as_handled()
				return
		if dirty_tip_dialog != null and dirty_tip_dialog.visible:
			if key_event.keycode == KEY_ESCAPE:
				_decline_current_dirty_tip_alert()
				get_viewport().set_input_as_handled()
				return
		if settings_dialog != null and settings_dialog.visible and key_event.keycode == KEY_ESCAPE:
			if settings_confirm_overlay != null and settings_confirm_overlay.visible:
				_hide_settings_confirmation()
				get_viewport().set_input_as_handled()
				return
			_hide_settings_dialog()
			get_viewport().set_input_as_handled()
			return
		if rupslb_meeting_overlay != null and rupslb_meeting_overlay.visible and key_event.keycode == KEY_ESCAPE:
			_close_rupslb_meeting_overlay()
			get_viewport().set_input_as_handled()
			return
		if corporate_meeting_overlay != null and corporate_meeting_overlay.visible and key_event.keycode == KEY_ESCAPE:
			_close_corporate_meeting_modal()
			get_viewport().set_input_as_handled()
			return
		if dashboard_calendar_event_popup != null and dashboard_calendar_event_popup.visible and key_event.keycode == KEY_ESCAPE:
			_hide_dashboard_calendar_event_popup()
			get_viewport().set_input_as_handled()
			return
		if debug_overlay.visible and key_event.keycode == KEY_ESCAPE:
			_hide_debug_overlay()
			get_viewport().set_input_as_handled()


func _apply_compact_layout() -> void:
	sidebar_panel.custom_minimum_size = Vector2(SIDEBAR_COMPACT_WIDTH, 0)
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
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._apply_trade_layout_ratios()
	stock_controller._sync_root_refs()
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
	watchlist_panel.custom_minimum_size = Vector2(WATCHLIST_MIN_WIDTH_NARROW if content_width < 1320.0 else WATCHLIST_MIN_WIDTH_WIDE, 0)
	work_area_panel.custom_minimum_size = Vector2.ZERO
	action_panel.custom_minimum_size = Vector2.ZERO
	company_list.custom_minimum_size = Vector2(0, 300 if content_width < 1320.0 else 420)
	all_stocks_scroll.custom_minimum_size = Vector2(0, 300 if content_width < 1320.0 else 420)
	portfolio_stocks_scroll.custom_minimum_size = Vector2(0, 300 if content_width < 1320.0 else 420)
	trade_workspace_widget.set_chart_minimum_height(300 if content_width < 1320.0 else 380)
	if social_app_shell != null:
		social_feed_cards.custom_minimum_size = Vector2(0, 0)
	else:
		social_feed_cards.custom_minimum_size = Vector2(max(min(get_viewport_rect().size.x - 120.0, SOCIAL_WINDOW_MAX_WIDTH - 24.0), 280.0), 0)
	debug_panel.custom_minimum_size = Vector2(
		max(min(viewport_size.x - 48.0, 1080.0), 560.0),
		max(min(viewport_size.y - 48.0, 680.0), 460.0)
	)
	_update_desktop_figma_layout()
	_update_key_stats_dashboard_layout()
	_apply_window_layout()
	_refresh_ftue_overlay()
	_refresh_first_hour_guide_panel()


func _remove_financial_and_broker_helper_text() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._remove_financial_and_broker_helper_text()
	stock_controller._sync_root_refs()
func _ensure_broker_range_controls() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._ensure_broker_range_controls()
	stock_controller._sync_root_refs()
func _broker_range_button_name(range_id: String) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._broker_range_button_name(range_id)
	stock_controller._sync_root_refs()
	return result
func _refresh_broker_range_buttons() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_broker_range_buttons()
	stock_controller._sync_root_refs()
func _on_broker_range_pressed(range_id: String) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_broker_range_pressed(range_id)
	stock_controller._sync_root_refs()
func _style_dashboard_calendar_grid() -> void:
	if dashboard_calendar_week_header != null:
		dashboard_calendar_week_header.columns = 7
		dashboard_calendar_week_header.add_theme_constant_override("h_separation", 4)
		dashboard_calendar_week_header.add_theme_constant_override("v_separation", 4)
		for child in dashboard_calendar_week_header.get_children():
			var weekday_label: Label = child as Label
			if weekday_label == null:
				continue
			weekday_label.custom_minimum_size = Vector2(0, DASHBOARD_CALENDAR_WEEKDAY_HEIGHT)
			weekday_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			weekday_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			weekday_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_set_label_tone(weekday_label, COLOR_MUTED)
	if dashboard_calendar_days_grid != null:
		dashboard_calendar_days_grid.columns = 7
		dashboard_calendar_days_grid.add_theme_constant_override("h_separation", 4)
		dashboard_calendar_days_grid.add_theme_constant_override("v_separation", 4)
		dashboard_calendar_days_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _ensure_dashboard_index_recap_ui() -> void:
	if dashboard_index_recap_panel != null:
		return
	var index_vbox: VBoxContainer = dashboard_index_title_label.get_parent() as VBoxContainer
	if index_vbox == null:
		return

	dashboard_index_date_label.visible = false
	dashboard_index_stats_grid.visible = false
	dashboard_index_hint_label.visible = false

	dashboard_index_recap_panel = VBoxContainer.new()
	dashboard_index_recap_panel.name = "DashboardIndexRecapPanel"
	dashboard_index_recap_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_index_recap_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dashboard_index_recap_panel.add_theme_constant_override("separation", 12)
	index_vbox.add_child(dashboard_index_recap_panel)

	var top_row := HBoxContainer.new()
	top_row.name = "DashboardIndexTopRow"
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 14)
	dashboard_index_recap_panel.add_child(top_row)

	var point_stack := VBoxContainer.new()
	point_stack.name = "DashboardIndexPointStack"
	point_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	point_stack.add_theme_constant_override("separation", 2)
	top_row.add_child(point_stack)

	dashboard_index_points_label = Label.new()
	dashboard_index_points_label.name = "DashboardIndexPointsLabel"
	dashboard_index_points_label.text = "-"
	dashboard_index_points_label.clip_text = true
	point_stack.add_child(dashboard_index_points_label)

	dashboard_index_change_label = Label.new()
	dashboard_index_change_label.name = "DashboardIndexChangeLabel"
	dashboard_index_change_label.text = "-"
	dashboard_index_change_label.clip_text = true
	point_stack.add_child(dashboard_index_change_label)

	dashboard_index_sparkline = DASHBOARD_SPARKLINE_SCRIPT.new()
	dashboard_index_sparkline.name = "DashboardIndexSparkline"
	dashboard_index_sparkline.custom_minimum_size = Vector2(168, 58)
	dashboard_index_sparkline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_index_sparkline.size_flags_vertical = Control.SIZE_FILL
	top_row.add_child(dashboard_index_sparkline)

	var all_market_label := Label.new()
	all_market_label.name = "DashboardIndexAllMarketTitleLabel"
	all_market_label.text = "All Market"
	dashboard_index_recap_panel.add_child(all_market_label)

	dashboard_index_all_market_rows = VBoxContainer.new()
	dashboard_index_all_market_rows.name = "DashboardIndexAllMarketRows"
	dashboard_index_all_market_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_index_all_market_rows.add_theme_constant_override("separation", 4)
	dashboard_index_recap_panel.add_child(dashboard_index_all_market_rows)

	dashboard_index_all_market_lot_value_label = _build_dashboard_index_recap_row("Lot", "DashboardIndexAllMarketLotValueLabel")
	dashboard_index_all_market_value_value_label = _build_dashboard_index_recap_row("Value", "DashboardIndexAllMarketValueValueLabel")
	_style_dashboard_index_recap_ui()


func _build_dashboard_index_recap_row(label_text: String, value_name: String) -> Label:
	var row := HBoxContainer.new()
	row.name = "DashboardIndex%sRow" % label_text.replace(" ", "")
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	dashboard_index_all_market_rows.add_child(row)

	var caption := Label.new()
	caption.name = "DashboardIndex%sCaptionLabel" % label_text.replace(" ", "")
	caption.text = label_text
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.clip_text = true
	row.add_child(caption)

	var value_label := Label.new()
	value_label.name = value_name
	value_label.text = "-"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(116, 0)
	row.add_child(value_label)
	return value_label


func _style_dashboard_index_recap_ui() -> void:
	if dashboard_index_date_label != null:
		dashboard_index_date_label.visible = false
	if dashboard_index_stats_grid != null:
		dashboard_index_stats_grid.visible = false
	if dashboard_index_hint_label != null:
		dashboard_index_hint_label.visible = false
	if dashboard_index_recap_panel != null:
		dashboard_index_recap_panel.add_theme_constant_override("separation", 12)
	if dashboard_index_points_label != null:
		_set_label_tone(dashboard_index_points_label, COLOR_TEXT)
		dashboard_index_points_label.add_theme_font_size_override("font_size", 24)
		var title_font: Font = _get_dashboard_title_font()
		if title_font != null:
			dashboard_index_points_label.add_theme_font_override("font", title_font)
	if dashboard_index_change_label != null:
		dashboard_index_change_label.add_theme_font_size_override("font_size", 14)
	var all_market_title: Label = null
	if dashboard_index_recap_panel != null:
		all_market_title = dashboard_index_recap_panel.find_child("DashboardIndexAllMarketTitleLabel", true, false) as Label
	if all_market_title != null:
		_set_label_tone(all_market_title, COLOR_TEXT)
		all_market_title.add_theme_font_size_override("font_size", 14)
		var section_font: Font = _get_dashboard_title_font()
		if section_font != null:
			all_market_title.add_theme_font_override("font", section_font)
	if dashboard_index_all_market_rows != null:
		dashboard_index_all_market_rows.add_theme_constant_override("separation", 4)
		for row_child in dashboard_index_all_market_rows.get_children():
			var row: HBoxContainer = row_child as HBoxContainer
			if row == null:
				continue
			row.add_theme_constant_override("separation", 8)
			for child in row.get_children():
				var label: Label = child as Label
				if label == null:
					continue
				label.add_theme_font_size_override("font_size", 14)
				if str(label.name).ends_with("CaptionLabel"):
					_set_label_tone(label, COLOR_MUTED)
	if dashboard_index_sparkline != null and dashboard_index_sparkline.has_method("set_palette"):
		dashboard_index_sparkline.call("set_palette", COLOR_POSITIVE, COLOR_NEGATIVE, COLOR_WARNING, Color(COLOR_MUTED.r, COLOR_MUTED.g, COLOR_MUTED.b, 0.28))


func _style_dashboard_section_titles() -> void:
	_style_dashboard_section_title(dashboard_index_title_label)
	_style_dashboard_section_title(dashboard_movers_title_label)
	_style_dashboard_section_title(dashboard_calendar_title_label)
	_style_dashboard_section_title(dashboard_placeholder_bottom_title_label)


func _style_dashboard_section_title(label: Label) -> void:
	if label == null:
		return
	_set_label_tone(label, COLOR_TEXT)
	label.add_theme_font_size_override("font_size", DASHBOARD_SECTION_TITLE_FONT_SIZE)
	var title_font: Font = _get_dashboard_title_font()
	if title_font != null:
		label.add_theme_font_override("font", title_font)


func _ensure_dashboard_broker_flow_ui() -> void:
	if dashboard_movers_tabs == null:
		return
	var broker_scroll: ScrollContainer = dashboard_movers_tabs.get_node_or_null("TopBrokerFlow") as ScrollContainer
	if broker_scroll == null:
		broker_scroll = ScrollContainer.new()
		broker_scroll.name = "TopBrokerFlow"
		broker_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		broker_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		broker_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		dashboard_movers_tabs.add_child(broker_scroll)

	var rows: VBoxContainer = broker_scroll.get_node_or_null("TopBrokerFlowRows") as VBoxContainer
	if rows == null:
		rows = VBoxContainer.new()
		rows.name = "TopBrokerFlowRows"
		rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rows.add_theme_constant_override("separation", 4)
		broker_scroll.add_child(rows)

	var empty_label: Label = rows.get_node_or_null("TopBrokerFlowEmptyLabel") as Label
	if empty_label == null:
		empty_label = Label.new()
		empty_label.name = "TopBrokerFlowEmptyLabel"
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.text = "No broker flow this session."
		rows.add_child(empty_label)

	dashboard_top_broker_flow_rows = rows
	dashboard_top_broker_flow_empty_label = empty_label
	var broker_tab_index: int = broker_scroll.get_index()
	if broker_tab_index >= 0 and broker_tab_index < dashboard_movers_tabs.get_tab_count():
		dashboard_movers_tabs.set_tab_title(broker_tab_index, "Broker Flow")


func _ensure_key_stats_dashboard_ui() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._ensure_key_stats_dashboard_ui()
	stock_controller._sync_root_refs()
func _build_key_stats_dashboard_column(column_name: String) -> VBoxContainer:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: VBoxContainer = stock_controller._build_key_stats_dashboard_column(column_name)
	stock_controller._sync_root_refs()
	return result
func _build_key_stats_card(
	card_id: String,
	title: String,
	card_name: String,
	rows_name: String,
	parent_node: Node
) -> VBoxContainer:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: VBoxContainer = stock_controller._build_key_stats_card(card_id, title, card_name, rows_name, parent_node)
	stock_controller._sync_root_refs()
	return result
func _build_key_stats_metric_card(parent_node: Node) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._build_key_stats_metric_card(parent_node)
	stock_controller._sync_root_refs()
func _style_key_stats_dashboard_ui() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._style_key_stats_dashboard_ui()
	stock_controller._sync_root_refs()
func _style_key_stats_card_tree(node: Node) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._style_key_stats_card_tree(node)
	stock_controller._sync_root_refs()
func _update_key_stats_dashboard_layout() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._update_key_stats_dashboard_layout()
	stock_controller._sync_root_refs()
func _on_key_stats_metric_button_pressed(metric_id: String) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_key_stats_metric_button_pressed(metric_id)
	stock_controller._sync_root_refs()
func _refresh_key_stats_metric_button_styles() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_key_stats_metric_button_styles()
	stock_controller._sync_root_refs()
func _refresh_key_stats_dashboard(snapshot: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_key_stats_dashboard(snapshot)
	stock_controller._sync_root_refs()
func _refresh_key_stats_rows(card_id: String, rows: Array) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_key_stats_rows(card_id, rows)
	stock_controller._sync_root_refs()
func _refresh_key_stats_rows_in_container(container: VBoxContainer, rows: Array) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_key_stats_rows_in_container(container, rows)
	stock_controller._sync_root_refs()
func _clear_key_stats_container(container: VBoxContainer) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._clear_key_stats_container(container)
	stock_controller._sync_root_refs()
func _build_key_stats_value_row(label_text: String, value_text: String, value_color: Color = COLOR_STOCKBOT_TEXT, source_row: Dictionary = {}) -> Control:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Control = stock_controller._build_key_stats_value_row(label_text, value_text, value_color, source_row)
	stock_controller._sync_root_refs()
	return result
func _on_key_stats_value_row_gui_input(event: InputEvent, source_row: Dictionary, label_text: String, value_text: String) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_key_stats_value_row_gui_input(event, source_row, label_text, value_text)
	stock_controller._sync_root_refs()
func _show_key_stats_capture_menu(menu_position: Vector2) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._show_key_stats_capture_menu(menu_position)
	stock_controller._sync_root_refs()
func _commit_pending_capture(kind: String, id: int) -> void:
	var payload: Dictionary = pending_capture_payloads.get(kind, {})
	if id != 1 or payload.is_empty():
		return
	var result: Dictionary = GameManager.capture_research_evidence(payload.duplicate(true))
	pending_capture_payloads.erase(kind)
	_show_toast(str(result.get("message", "Research capture updated.")), bool(result.get("success", false)))


func _on_key_stats_capture_menu_id_pressed(id: int) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_key_stats_capture_menu_id_pressed(id)
	stock_controller._sync_root_refs()
func _key_stats_row_is_capturable(label_text: String, value_text: String) -> bool:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: bool = stock_controller._key_stats_row_is_capturable(label_text, value_text)
	stock_controller._sync_root_refs()
	return result
func _build_key_stats_context(snapshot: Dictionary) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._build_key_stats_context(snapshot)
	stock_controller._sync_root_refs()
	return result
func _build_key_stats_valuation_rows(context: Dictionary) -> Array:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Array = stock_controller._build_key_stats_valuation_rows(context)
	stock_controller._sync_root_refs()
	return result
func _build_key_stats_per_share_rows(context: Dictionary) -> Array:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Array = stock_controller._build_key_stats_per_share_rows(context)
	stock_controller._sync_root_refs()
	return result
func _build_key_stats_dividend_context(dividend_snapshot: Dictionary, current_price: float) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._build_key_stats_dividend_context(dividend_snapshot, current_price)
	stock_controller._sync_root_refs()
	return result
func _build_key_stats_dividend_rows(context: Dictionary) -> Array:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Array = stock_controller._build_key_stats_dividend_rows(context)
	stock_controller._sync_root_refs()
	return result
func _build_key_stats_profitability_rows(context: Dictionary) -> Array:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Array = stock_controller._build_key_stats_profitability_rows(context)
	stock_controller._sync_root_refs()
	return result
func _build_key_stats_income_statement_rows(context: Dictionary) -> Array:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Array = stock_controller._build_key_stats_income_statement_rows(context)
	stock_controller._sync_root_refs()
	return result
func _build_key_stats_balance_sheet_rows(context: Dictionary) -> Array:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Array = stock_controller._build_key_stats_balance_sheet_rows(context)
	stock_controller._sync_root_refs()
	return result
func _build_key_stats_cash_flow_rows(context: Dictionary) -> Array:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Array = stock_controller._build_key_stats_cash_flow_rows(context)
	stock_controller._sync_root_refs()
	return result
func _refresh_key_stats_metric_table(snapshot: Dictionary, context: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_key_stats_metric_table(snapshot, context)
	stock_controller._sync_root_refs()
func _build_key_stats_metric_row(
	label_text: String,
	values: Array,
	label_color: Color = COLOR_STOCKBOT_MUTED,
	value_color: Color = COLOR_STOCKBOT_TEXT,
	metric_id: String = "",
	years: Array = []
) -> Control:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Control = stock_controller._build_key_stats_metric_row(label_text, values, label_color, value_color, metric_id, years)
	stock_controller._sync_root_refs()
	return result
func _key_stats_metric_capture_payload(metric_id: String, row_label: String, value_text: String, years: Array, value_index: int) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._key_stats_metric_capture_payload(metric_id, row_label, value_text, years, value_index)
	stock_controller._sync_root_refs()
	return result
func _key_stats_metric_display_label(metric_id: String) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._key_stats_metric_display_label(metric_id)
	stock_controller._sync_root_refs()
	return result
func _on_key_stats_metric_value_gui_input(event: InputEvent, capture_payload: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_key_stats_metric_value_gui_input(event, capture_payload)
	stock_controller._sync_root_refs()
func _key_stats_year_labels(years: Array) -> Array:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Array = stock_controller._key_stats_year_labels(years)
	stock_controller._sync_root_refs()
	return result
func _key_stats_metric_values_for_quarter(
	financial_statement_snapshot: Dictionary,
	metric_id: String,
	years: Array,
	quarter: int
) -> Array:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Array = stock_controller._key_stats_metric_values_for_quarter(financial_statement_snapshot, metric_id, years, quarter)
	stock_controller._sync_root_refs()
	return result
func _key_stats_metric_values_for_annual(
	financial_statement_snapshot: Dictionary,
	financial_history: Array,
	metric_id: String,
	years: Array
) -> Array:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Array = stock_controller._key_stats_metric_values_for_annual(financial_statement_snapshot, financial_history, metric_id, years)
	stock_controller._sync_root_refs()
	return result
func _key_stats_metric_values_for_ttm(
	financial_statement_snapshot: Dictionary,
	financial_history: Array,
	metric_id: String,
	years: Array
) -> Array:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Array = stock_controller._key_stats_metric_values_for_ttm(financial_statement_snapshot, financial_history, metric_id, years)
	stock_controller._sync_root_refs()
	return result
func _key_stats_recent_years(financial_history: Array, financial_statement_snapshot: Dictionary) -> Array:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Array = stock_controller._key_stats_recent_years(financial_history, financial_statement_snapshot)
	stock_controller._sync_root_refs()
	return result
func _key_stats_metric_result_from_statement(statement: Dictionary, metric_id: String) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._key_stats_metric_result_from_statement(statement, metric_id)
	stock_controller._sync_root_refs()
	return result
func _key_stats_metric_annual_result(
	financial_statement_snapshot: Dictionary,
	financial_history: Array,
	metric_id: String,
	year: int
) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._key_stats_metric_annual_result(financial_statement_snapshot, financial_history, metric_id, year)
	stock_controller._sync_root_refs()
	return result
func _key_stats_metric_ttm_result(
	financial_statement_snapshot: Dictionary,
	financial_history: Array,
	metric_id: String,
	year: int
) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._key_stats_metric_ttm_result(financial_statement_snapshot, financial_history, metric_id, year)
	stock_controller._sync_root_refs()
	return result
func _key_stats_history_metric_result(financial_history: Array, metric_id: String, year: int) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._key_stats_history_metric_result(financial_history, metric_id, year)
	stock_controller._sync_root_refs()
	return result
func _format_key_stats_metric_result(metric_id: String, result: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var formatted_result: String = stock_controller._format_key_stats_metric_result(metric_id, result)
	stock_controller._sync_root_refs()
	return formatted_result
func _key_stats_statement_for_year_quarter(
	financial_statement_snapshot: Dictionary,
	year: int,
	quarter: int
) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._key_stats_statement_for_year_quarter(financial_statement_snapshot, year, quarter)
	stock_controller._sync_root_refs()
	return result
func _key_stats_latest_history_entry(financial_history: Array) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._key_stats_latest_history_entry(financial_history)
	stock_controller._sync_root_refs()
	return result
func _key_stats_latest_quarters(financial_statement_snapshot: Dictionary, count: int = 4) -> Array:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Array = stock_controller._key_stats_latest_quarters(financial_statement_snapshot, count)
	stock_controller._sync_root_refs()
	return result
func _key_stats_ttm_sum(
	financial_statement_snapshot: Dictionary,
	section_id: String,
	line_id: String,
	fallback_value: float
) -> float:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: float = stock_controller._key_stats_ttm_sum(financial_statement_snapshot, section_id, line_id, fallback_value)
	stock_controller._sync_root_refs()
	return result
func _key_stats_statement_value_from_period(period: Dictionary, section_id: String, line_id: String) -> float:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: float = stock_controller._key_stats_statement_value_from_period(period, section_id, line_id)
	stock_controller._sync_root_refs()
	return result
func _key_stats_statement_value(lines: Array, line_id: String) -> float:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: float = stock_controller._key_stats_statement_value(lines, line_id)
	stock_controller._sync_root_refs()
	return result
func _key_stats_period_has_statement_line(period: Dictionary, section_id: String, line_id: String) -> bool:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: bool = stock_controller._key_stats_period_has_statement_line(period, section_id, line_id)
	stock_controller._sync_root_refs()
	return result
func _first_key_stats_dividend_row(rows: Array) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._first_key_stats_dividend_row(rows)
	stock_controller._sync_root_refs()
	return result
func _first_key_stats_dividend_row_by_type(rows: Array, action_type: String) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._first_key_stats_dividend_row_by_type(rows, action_type)
	stock_controller._sync_root_refs()
	return result
func _last_key_stats_dividend_row(rows: Array) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._last_key_stats_dividend_row(rows)
	stock_controller._sync_root_refs()
	return result
func _key_stats_dividend_status_label(row: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._key_stats_dividend_status_label(row)
	stock_controller._sync_root_refs()
	return result
func _format_key_stats_dividend_timetable(record_day_number: int, payment_day_number: int, current_day_number: int) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_key_stats_dividend_timetable(record_day_number, payment_day_number, current_day_number)
	stock_controller._sync_root_refs()
	return result
func _format_key_stats_day_delta(day_number: int, current_day_number: int) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_key_stats_day_delta(day_number, current_day_number)
	stock_controller._sync_root_refs()
	return result
func _key_stats_safe_divide(numerator: float, denominator: float) -> float:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: float = stock_controller._key_stats_safe_divide(numerator, denominator)
	stock_controller._sync_root_refs()
	return result
func _format_key_stats_ratio_value(value: float, is_valid: bool = true) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_key_stats_ratio_value(value, is_valid)
	stock_controller._sync_root_refs()
	return result
func _format_key_stats_decimal_value(value: float, is_valid: bool = true) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_key_stats_decimal_value(value, is_valid)
	stock_controller._sync_root_refs()
	return result
func _format_key_stats_percent_value(value: float, is_valid: bool = true) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_key_stats_percent_value(value, is_valid)
	stock_controller._sync_root_refs()
	return result
func _format_key_stats_percent_ratio(value: float, is_valid: bool = true) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_key_stats_percent_ratio(value, is_valid)
	stock_controller._sync_root_refs()
	return result
func _format_key_stats_compact_number(value: float) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_key_stats_compact_number(value)
	stock_controller._sync_root_refs()
	return result
func _key_stats_amount_color(value: float) -> Color:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Color = stock_controller._key_stats_amount_color(value)
	stock_controller._sync_root_refs()
	return result
func _on_order_ticket_toggle_pressed() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_order_ticket_toggle_pressed()
	stock_controller._sync_root_refs()
func _refresh_order_ticket_toggle_state() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_order_ticket_toggle_state()
	stock_controller._sync_root_refs()
func _refresh_all(refresh_open_apps: bool = true) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var phase_started_at_usec: int = started_at_usec
	var log_phase_details: bool = advance_day_processing
	_invalidate_company_rows_cache()
	_refresh_desktop()
	_log_perf_phase(log_phase_details, "_refresh_all:desktop", phase_started_at_usec)
	if not RunState.has_active_run():
		status_message = "No active run. Return to menu to begin."
		selected_company_id = ""
		phase_started_at_usec = Time.get_ticks_usec()
		_refresh_header()
		_log_perf_phase(log_phase_details, "_refresh_all:header", phase_started_at_usec)
		phase_started_at_usec = Time.get_ticks_usec()
		_refresh_sidebar()
		_log_perf_phase(log_phase_details, "_refresh_all:sidebar", phase_started_at_usec)
		phase_started_at_usec = Time.get_ticks_usec()
		if refresh_open_apps:
			_refresh_open_desktop_apps(log_phase_details)
			_log_perf_phase(log_phase_details, "_refresh_all:open_apps", phase_started_at_usec)
		else:
			_log_perf_phase(log_phase_details, "_refresh_all:open_apps_deferred", phase_started_at_usec)
		phase_started_at_usec = Time.get_ticks_usec()
		if debug_overlay.visible:
			_refresh_debug_overlay()
		_log_perf_phase(log_phase_details, "_refresh_all:debug_overlay", phase_started_at_usec)
		_refresh_first_hour_guide_progress()
		_log_perf_elapsed("_refresh_all", started_at_usec)
		return

	phase_started_at_usec = Time.get_ticks_usec()
	_sync_selected_company_with_active_stock_list()
	_log_perf_phase(log_phase_details, "_refresh_all:sync_selected_stock", phase_started_at_usec)

	phase_started_at_usec = Time.get_ticks_usec()
	_refresh_header()
	_log_perf_phase(log_phase_details, "_refresh_all:header", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_refresh_sidebar()
	_log_perf_phase(log_phase_details, "_refresh_all:sidebar", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var should_refresh_dashboard: bool = not advance_day_processing
	if should_refresh_dashboard:
		_refresh_dashboard()
		_log_perf_phase(log_phase_details, "_refresh_all:dashboard", phase_started_at_usec)
	else:
		deferred_dashboard_refresh_after_recap = true
		_log_perf_phase(log_phase_details, "_refresh_all:dashboard_skipped", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	if refresh_open_apps:
		_refresh_open_desktop_apps(log_phase_details)
		_log_perf_phase(log_phase_details, "_refresh_all:open_apps", phase_started_at_usec)
	else:
		_log_perf_phase(log_phase_details, "_refresh_all:open_apps_deferred", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_refresh_portfolio()
	_log_perf_phase(log_phase_details, "_refresh_all:portfolio", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_refresh_help()
	_log_perf_phase(log_phase_details, "_refresh_all:help", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	if debug_overlay.visible:
		_refresh_debug_overlay()
	_log_perf_phase(log_phase_details, "_refresh_all:debug_overlay", phase_started_at_usec)
	_refresh_first_hour_guide_progress()
	_log_perf_elapsed("_refresh_all", started_at_usec)


func _refresh_open_desktop_apps(log_phase_details: bool = false) -> void:
	if _is_desktop_app_window_open(APP_ID_STOCK):
		var stock_started_at_usec: int = Time.get_ticks_usec()
		_refresh_markets()
		_log_perf_phase(log_phase_details, "_refresh_open_apps:stock", stock_started_at_usec)
	if _is_desktop_app_window_open(APP_ID_NEWS):
		var news_started_at_usec: int = Time.get_ticks_usec()
		_refresh_news()
		_log_perf_phase(log_phase_details, "_refresh_open_apps:news", news_started_at_usec)
	if _is_desktop_app_window_open(APP_ID_SOCIAL):
		var social_started_at_usec: int = Time.get_ticks_usec()
		_refresh_social()
		_log_perf_phase(log_phase_details, "_refresh_open_apps:social", social_started_at_usec)
	if _is_desktop_app_window_open(APP_ID_NETWORK):
		var network_started_at_usec: int = Time.get_ticks_usec()
		_refresh_network()
		_log_perf_phase(log_phase_details, "_refresh_open_apps:network", network_started_at_usec)
	if _is_desktop_app_window_open(APP_ID_ACADEMY):
		var academy_started_at_usec: int = Time.get_ticks_usec()
		_refresh_academy()
		_log_perf_phase(log_phase_details, "_refresh_open_apps:academy", academy_started_at_usec)
	if _is_desktop_app_window_open(APP_ID_THESIS):
		var thesis_started_at_usec: int = Time.get_ticks_usec()
		_refresh_thesis()
		_log_perf_phase(log_phase_details, "_refresh_open_apps:thesis", thesis_started_at_usec)
	if _is_desktop_app_window_open(APP_ID_LIFE):
		var life_started_at_usec: int = Time.get_ticks_usec()
		_refresh_life()
		_log_perf_phase(log_phase_details, "_refresh_open_apps:life", life_started_at_usec)
	if _is_desktop_app_window_open(APP_ID_COMPANY):
		var company_started_at_usec: int = Time.get_ticks_usec()
		_refresh_company()
		_log_perf_phase(log_phase_details, "_refresh_open_apps:company", company_started_at_usec)
	if _is_desktop_app_window_open(APP_ID_UPGRADES):
		var upgrades_started_at_usec: int = Time.get_ticks_usec()
		_refresh_upgrades()
		_log_perf_phase(log_phase_details, "_refresh_open_apps:upgrades", upgrades_started_at_usec)


func _queue_deferred_open_app_refresh() -> void:
	if not RunState.has_active_run():
		return
	for app_id_value in _open_desktop_app_refresh_order():
		var app_id: String = str(app_id_value)
		if not deferred_open_app_refresh_queue.has(app_id):
			deferred_open_app_refresh_queue.append(app_id)


func _schedule_deferred_open_app_refresh() -> void:
	if deferred_open_app_refresh_queue.is_empty() or deferred_open_app_refresh_scheduled:
		return
	deferred_open_app_refresh_scheduled = true
	call_deferred("_run_deferred_open_app_refresh_after_frame")


func _run_deferred_open_app_refresh_after_frame() -> void:
	await get_tree().process_frame
	deferred_open_app_refresh_scheduled = false
	if deferred_open_app_refresh_queue.is_empty():
		return
	var waiting_for_recap: bool = (
		_is_daily_recap_visible() or
		not pending_daily_recap_snapshot.is_empty() and
		daily_recap_dialog != null and
		daily_recap_body_label != null
	)
	if advance_day_processing:
		_schedule_deferred_open_app_refresh()
		return
	if waiting_for_recap:
		return
	var app_id: String = str(deferred_open_app_refresh_queue.pop_front())
	if app_id.is_empty() or not _is_desktop_app_window_open(app_id):
		_schedule_deferred_open_app_refresh()
		return
	var started_at_usec: int = Time.get_ticks_usec()
	_refresh_app_window_content(app_id)
	_refresh_desktop()
	_log_perf_elapsed("_refresh_deferred_open_app:%s" % app_id, started_at_usec)
	_schedule_deferred_open_app_refresh()


func _refresh_pending_dashboard_after_guarded_advance() -> void:
	if not deferred_dashboard_refresh_after_recap:
		return
	if advance_day_processing:
		return
	if _is_daily_recap_visible():
		return
	if not RunState.has_active_run():
		deferred_dashboard_refresh_after_recap = false
		return
	var started_at_usec: int = Time.get_ticks_usec()
	_refresh_dashboard()
	deferred_dashboard_refresh_after_recap = false
	_log_perf_elapsed("_refresh_pending_dashboard_after_guarded_advance", started_at_usec)


func _run_post_daily_recap_work(show_followup_alert: bool = false) -> void:
	await get_tree().process_frame
	var started_at_usec: int = Time.get_ticks_usec()
	if deferred_full_refresh_after_recap:
		deferred_full_refresh_after_recap = false
		deferred_dashboard_refresh_after_recap = false
		_refresh_all(false)
	else:
		_refresh_pending_dashboard_after_guarded_advance()
	_schedule_deferred_open_app_refresh()
	_schedule_advance_day_post_recap_save_flush()
	_refresh_ftue_progress()
	_refresh_first_hour_guide_progress()
	_log_perf_elapsed("_run_post_daily_recap_work", started_at_usec)
	if show_followup_alert:
		call_deferred("_show_next_macro_event_alert")


func _is_daily_recap_visible() -> bool:
	return daily_recap_dialog != null and daily_recap_dialog.visible


func _open_desktop_app_refresh_order() -> Array:
	var ordered: Array = []
	var top_app_id: String = _top_visible_desktop_window_id()
	if not top_app_id.is_empty():
		ordered.append(top_app_id)
	if active_app_id != APP_ID_DESKTOP and not ordered.has(active_app_id) and _is_desktop_app_window_open(active_app_id):
		ordered.append(active_app_id)
	for app_id in [APP_ID_STOCK, APP_ID_NEWS, APP_ID_SOCIAL, APP_ID_NETWORK, APP_ID_ACADEMY, APP_ID_THESIS, APP_ID_LIFE, APP_ID_COMPANY, APP_ID_UPGRADES]:
		if _is_desktop_app_window_open(app_id) and not ordered.has(app_id):
			ordered.append(app_id)
	return ordered


func _remove_deferred_open_app_refresh(app_id: String) -> void:
	while deferred_open_app_refresh_queue.has(app_id):
		deferred_open_app_refresh_queue.erase(app_id)


func _schedule_advance_day_post_recap_save_flush() -> void:
	if advance_day_post_recap_save_flush_scheduled:
		return
	advance_day_post_recap_save_flush_scheduled = true
	call_deferred("_flush_advance_day_save_after_recap")


func _flush_advance_day_save_after_recap() -> void:
	await get_tree().process_frame
	advance_day_post_recap_save_flush_scheduled = false
	if _is_daily_recap_visible() or not pending_daily_recap_snapshot.is_empty():
		return
	var started_at_usec: int = Time.get_ticks_usec()
	GameManager.flush_pending_save_if_needed()
	_log_perf_elapsed("_flush_advance_day_save_after_recap", started_at_usec)
	_schedule_deferred_open_app_refresh()


func _on_portfolio_changed() -> void:
	if suppress_next_portfolio_refresh:
		suppress_next_portfolio_refresh = false
		return
	var started_at_usec: int = Time.get_ticks_usec()
	_invalidate_company_rows_cache()
	_sync_selected_company_with_active_stock_list()
	_refresh_header()
	_refresh_sidebar()
	_refresh_company_list([], {}, false, true)
	_refresh_trade_workspace_holdings_state()
	_refresh_portfolio()
	_refresh_desktop()
	if active_section_id == "dashboard":
		_refresh_dashboard()
	if _is_desktop_app_window_open(APP_ID_THESIS):
		_refresh_thesis()
	if _is_desktop_app_window_open(APP_ID_LIFE):
		_refresh_life()
	if _is_desktop_app_window_open(APP_ID_COMPANY):
		_refresh_company()
	if debug_overlay.visible:
		_refresh_debug_overlay()
	_start_background_company_detail_hydration()
	_log_perf_elapsed("_on_portfolio_changed", started_at_usec)
	_refresh_ftue_progress()
	_refresh_first_hour_guide_progress()


func _on_life_changed() -> void:
	if advance_day_processing:
		if _is_desktop_app_window_open(APP_ID_LIFE):
			_queue_deferred_open_app_refresh()
		return
	_refresh_header()
	_refresh_desktop()
	if _is_desktop_app_window_open(APP_ID_LIFE):
		_refresh_life()
	if active_section_id == "dashboard":
		_refresh_dashboard()
	if debug_overlay.visible:
		_refresh_debug_overlay()


func _on_watchlist_changed() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var previous_selected_company_id: String = selected_company_id
	var target_company_id: String = pending_watchlist_selected_company_id
	var target_tab: int = pending_watchlist_target_tab
	var should_change_tab: bool = target_tab >= 0 and target_tab != stock_list_tabs.current_tab
	if not target_company_id.is_empty():
		selected_company_id = target_company_id
	_clear_watchlist_refresh_override()
	if should_change_tab:
		suppress_stock_list_tab_refresh = true
		stock_list_tabs.current_tab = target_tab
	_sync_selected_company_with_active_stock_list()
	var company_rows: Array = _get_company_rows_cached()
	var watchlist_lookup: Dictionary = _build_watchlist_lookup()
	_refresh_watchlist_rows(company_rows, watchlist_lookup)
	if _should_refresh_all_stock_rows():
		_refresh_all_stock_watchlist_button_states(watchlist_lookup)
	else:
		all_stock_rows_dirty = true
	_refresh_company_selection_state()
	if selected_company_id != previous_selected_company_id:
		_refresh_trade_workspace()
		if active_section_id == "dashboard":
			_refresh_dashboard()
		_refresh_desktop()
		if debug_overlay.visible:
			_refresh_debug_overlay()
	_start_background_company_detail_hydration()
	_log_perf_elapsed("_on_watchlist_changed", started_at_usec)
	_refresh_first_hour_guide_progress()


func _on_network_changed() -> void:
	if advance_day_processing:
		_queue_deferred_open_app_refresh()
		return
	_refresh_network()
	if _is_desktop_app_window_open(APP_ID_THESIS):
		_refresh_thesis()
	_refresh_first_hour_guide_progress()


func _on_thesis_changed() -> void:
	if _is_desktop_app_window_open(APP_ID_THESIS):
		_refresh_thesis()
	_refresh_ftue_progress()
	call_deferred("_refresh_ftue_progress")
	_refresh_first_hour_guide_progress()


func _apply_global_font_size_overrides() -> void:
	_apply_font_size_override_to_tree(self, DEFAULT_APP_FONT_SIZE, _get_app_font())
	_style_figma_desktop_ui()
	_style_dashboard_index_recap_ui()
	_style_dashboard_section_titles()
	_style_news_newspaper_ui()
	if academy_window_body != null:
		_restyle_academy_controls()
	_style_life_news_tabs()
	_style_twooter_ui()


func _apply_font_overrides_to_subtree(node: Node) -> void:
	if node == null:
		return
	_apply_font_size_override_to_tree(node, DEFAULT_APP_FONT_SIZE, _get_app_font())


func _queue_watchlist_refresh_override(company_id: String = "", target_tab: int = -1) -> void:
	pending_watchlist_selected_company_id = company_id
	pending_watchlist_target_tab = target_tab


func _clear_watchlist_refresh_override() -> void:
	pending_watchlist_selected_company_id = ""
	pending_watchlist_target_tab = -1


func _invalidate_company_rows_cache() -> void:
	cached_company_rows = []
	cached_company_row_lookup = {}
	has_cached_company_rows = false
	all_stock_rows_dirty = true
	portfolio_stock_rows_dirty = true


func _get_company_rows_cached() -> Array:
	if not has_cached_company_rows:
		cached_company_rows = GameManager.get_company_market_rows()
		cached_company_row_lookup = _build_company_row_lookup(cached_company_rows)
		has_cached_company_rows = true
	return cached_company_rows


func _get_company_row_lookup_cached() -> Dictionary:
	_get_company_rows_cached()
	return cached_company_row_lookup


func _build_company_row_lookup(company_rows: Array) -> Dictionary:
	var company_row_lookup: Dictionary = {}
	for row_value in company_rows:
		var company_row: Dictionary = row_value
		company_row_lookup[str(company_row.get("id", ""))] = company_row
	return company_row_lookup


func _suppress_next_portfolio_refresh() -> void:
	suppress_next_portfolio_refresh = true
	call_deferred("_clear_suppressed_portfolio_refresh")


func _queue_signal_refresh(handler: Callable) -> void:
	if pending_signal_refresh_handlers.has(handler):
		return
	pending_signal_refresh_handlers.append(handler)
	if signal_refresh_flush_scheduled:
		return
	signal_refresh_flush_scheduled = true
	call_deferred("_flush_signal_refreshes")


func _flush_signal_refreshes() -> void:
	signal_refresh_flush_scheduled = false
	# Handlers may emit further signals while running; swap the queue first so
	# new arrivals coalesce into the next flush instead of growing this one.
	var handlers: Array = pending_signal_refresh_handlers
	pending_signal_refresh_handlers = []
	for handler_value in handlers:
		var handler: Callable = handler_value
		if handler.is_valid():
			handler.call()


func _clear_suppressed_portfolio_refresh() -> void:
	suppress_next_portfolio_refresh = false


func _log_perf_elapsed(label: String, started_at_usec: int) -> void:
	if not OS.is_debug_build():
		return
	var elapsed_ms: float = float(Time.get_ticks_usec() - started_at_usec) / 1000.0
	print("%s %s %.2fms" % [PERF_LOG_PREFIX, label, elapsed_ms])


func _log_perf_phase(enabled: bool, label: String, started_at_usec: int) -> void:
	if not enabled:
		return
	_log_perf_elapsed(label, started_at_usec)


func _apply_font_size_override_to_tree(node: Node, font_size: int, app_font: Font = null) -> void:
	if node is Control:
		_apply_font_override_to_control(node as Control, font_size, app_font)

	for child: Node in node.get_children():
		_apply_font_size_override_to_tree(child, font_size, app_font)


func _apply_font_override_to_control(control: Control, font_size: int, app_font: Font = null) -> void:
	control.add_theme_font_size_override("font_size", font_size)
	if app_font != null:
		control.add_theme_font_override("font", app_font)
	if control is RichTextLabel:
		var rich_text: RichTextLabel = control
		rich_text.add_theme_font_size_override("normal_font_size", font_size)
		rich_text.add_theme_font_size_override("bold_font_size", font_size)
		rich_text.add_theme_font_size_override("italics_font_size", font_size)
		rich_text.add_theme_font_size_override("mono_font_size", font_size)
		if app_font != null:
			rich_text.add_theme_font_override("normal_font", app_font)
			rich_text.add_theme_font_override("bold_font", app_font)
			rich_text.add_theme_font_override("italics_font", app_font)
			rich_text.add_theme_font_override("mono_font", app_font)


func _get_app_font() -> Font:
	if has_checked_app_font:
		return cached_app_font

	has_checked_app_font = true
	for font_path_value in APP_FONT_CANDIDATE_PATHS:
		var font_path: String = str(font_path_value)
		if not ResourceLoader.exists(font_path):
			continue
		var font_resource := load(font_path)
		if font_resource is Font:
			cached_app_font = font_resource
			return cached_app_font
	return null


func _get_dashboard_title_font() -> Font:
	if has_checked_dashboard_title_font:
		return cached_dashboard_title_font

	has_checked_dashboard_title_font = true
	if ResourceLoader.exists(DASHBOARD_SECTION_TITLE_FONT_PATH):
		var font_resource := load(DASHBOARD_SECTION_TITLE_FONT_PATH)
		if font_resource is Font:
			cached_dashboard_title_font = font_resource
			return cached_dashboard_title_font
	cached_dashboard_title_font = _get_app_font()
	return cached_dashboard_title_font


func _refresh_header() -> void:
	var portfolio: Dictionary = GameManager.get_portfolio_snapshot()
	var trading_day_number: int = max(RunState.day_index + 1, 1)
	var current_trade_date: Dictionary = GameManager.get_current_trade_date()
	top_section_label.text = "DAY %d  |  %s" % [trading_day_number, GameManager.format_trade_date(current_trade_date)]
	top_day_label.text = "DAY %d  |  %s" % [trading_day_number, GameManager.format_trade_date(current_trade_date)]
	top_market_label.text = "MARKET %s" % _format_change(RunState.market_sentiment)
	top_equity_label.text = "EQUITY %s" % _format_currency(RunState.get_total_equity())
	var cash_value: float = float(portfolio.get("cash", 0.0))
	top_cash_label.text = "CASH AVAILABLE %s" % _format_currency(cash_value)
	objective_label.text = ""
	var finance_status: Dictionary = GameManager.get_finance_status_snapshot() if RunState.has_active_run() else {}
	var cash_chip_fill: Color = COLOR_STOCKBOT_SURFACE_ALT
	var cash_chip_edge: Color = COLOR_STOCKBOT_EDGE_STRONG
	var cash_chip_text: Color = COLOR_STOCKBOT_BLUE
	top_cash_label.tooltip_text = "Cash available for new orders."
	if bool(finance_status.get("bankrupt", false)):
		top_cash_label.text = "BANKRUPT | CASH %s" % _format_currency(cash_value)
		top_cash_label.tooltip_text = "Bankruptcy has disabled trading, loans, upgrades, and Advance Day."
		cash_chip_fill = COLOR_STOCKBOT_BEAR_TINT
		cash_chip_edge = COLOR_STOCKBOT_BEAR_EDGE
		cash_chip_text = COLOR_STOCKBOT_BEAR
	elif cash_value < 0.0:
		top_cash_label.tooltip_text = "Cash stress active. Sell holdings, lower Life costs, or use Life > Finance."
		cash_chip_fill = COLOR_STOCKBOT_BEAR_TINT
		cash_chip_edge = COLOR_STOCKBOT_BEAR_EDGE
		cash_chip_text = COLOR_STOCKBOT_BEAR
	elif bool(finance_status.get("loan_payment_risky", false)):
		top_cash_label.tooltip_text = "Emergency loan payment reserve is not covered."
		cash_chip_fill = Color(COLOR_STOCKBOT_AMBER.r, COLOR_STOCKBOT_AMBER.g, COLOR_STOCKBOT_AMBER.b, 0.12)
		cash_chip_edge = COLOR_STOCKBOT_AMBER
		cash_chip_text = COLOR_STOCKBOT_AMBER
	_set_label_tone(top_market_label, _color_for_change(RunState.market_sentiment))
	_set_label_tone(top_cash_label, cash_chip_text)
	_set_label_tone(top_section_label, COLOR_WARNING)
	_set_label_tone(top_day_label, COLOR_WARNING)
	_style_stockbot_label_chip(top_market_label, COLOR_STOCKBOT_BLUE_TINT, COLOR_STOCKBOT_BLUE_EDGE, _color_for_change(RunState.market_sentiment))
	_style_stockbot_label_chip(top_equity_label, COLOR_STOCKBOT_SURFACE_ALT, COLOR_STOCKBOT_EDGE_STRONG, COLOR_STOCKBOT_TEXT)
	_style_stockbot_label_chip(top_cash_label, cash_chip_fill, cash_chip_edge, cash_chip_text)
	_style_stockbot_label_chip(top_section_label, COLOR_STOCKBOT_SURFACE_ALT, COLOR_STOCKBOT_EDGE_STRONG, COLOR_STOCKBOT_AMBER)
	_refresh_stress_meter()
	_refresh_hospital_overlay()
	_refresh_jail_overlay()


func _refresh_desktop() -> void:
	_sync_desktop_app_state()
	_apply_academy_release_lock_state()
	if not RunState.has_active_run():
		desktop_title_label.text = "Gorengan OS"
		desktop_date_label.text = "No active run"
		desktop_subtitle_label.text = "Boot a run from the main menu to bring the terminal online."
		desktop_hint_label.text = "Desktop icons launch apps. STOCKBOT trades, News reads the event tape, Twooter surfaces chatter, Network manages contacts, Academy is coming soon, and Settings handles save/load."
		taskbar_status_label.text = "No active run loaded."
		_refresh_build_number_labels()
		taskbar_clock_label.text = "MENU"
		_refresh_company_app_availability()
		_refresh_figma_desktop_status()
		_refresh_desktop_notification_badges()
		return

	var current_trade_date: Dictionary = GameManager.get_current_trade_date()
	var focus_snapshot: Dictionary = GameManager.get_company_snapshot(selected_company_id)
	desktop_title_label.text = "Gorengan OS"
	desktop_date_label.text = "DAY %d  |  %s" % [
		max(RunState.day_index + 1, 1),
		GameManager.format_trade_date(current_trade_date)
	]
	desktop_subtitle_label.text = "%s session online  |  Equity %s" % [
		GameManager.get_current_difficulty_label(),
		_format_currency(RunState.get_total_equity())
	]
	desktop_hint_label.text = "STOCKBOT is live. News renders event-driven intel feeds, Twooter shows public market chatter, Network tracks contacts, Academy is coming soon, Company unlocks with majority control, and Settings handles save/load."
	taskbar_status_label.text = _append_save_status(_build_taskbar_status_text(focus_snapshot))
	_refresh_build_number_labels()
	taskbar_clock_label.text = "DAY %d  |  %s" % [
		max(RunState.day_index + 1, 1),
		GameManager.format_trade_date(current_trade_date)
	]
	_refresh_company_app_availability()
	_refresh_figma_desktop_status()
	_refresh_desktop_notification_badges()


func _refresh_build_number_labels() -> void:
	var short_build_text: String = BuildInfo.get_short_display_string()
	var full_build_text: String = BuildInfo.get_bug_report_context()
	if taskbar_build_label != null:
		taskbar_build_label.text = short_build_text
		taskbar_build_label.tooltip_text = full_build_text
	if settings_build_label != null:
		settings_build_label.text = short_build_text
		settings_build_label.tooltip_text = full_build_text


func _append_save_status(base_text: String) -> String:
	var save_status: Dictionary = SaveManager.get_runtime_save_status()
	var slot_label: String = str(save_status.get("active_slot_label", "Slot 1"))
	if not bool(save_status.get("autosave_enabled", true)):
		return "%s  |  %s autosave off" % [base_text, slot_label]
	if bool(save_status.get("pending", false)):
		return "%s  |  %s autosave pending" % [base_text, slot_label]
	if int(save_status.get("last_save_unix", 0)) > 0:
		return "%s  |  %s saved" % [base_text, slot_label]
	return base_text


func _on_save_status_changed() -> void:
	if not is_inside_tree():
		return
	_refresh_desktop()


func _refresh_news() -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._refresh_news()
	news_controller._sync_root_refs()

func _rebuild_news_outlet_buttons(outlets: Array) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._rebuild_news_outlet_buttons(outlets)
	news_controller._sync_root_refs()

func _refresh_news_archive_filters() -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._refresh_news_archive_filters()
	news_controller._sync_root_refs()

func _refresh_news_archive_month_options() -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._refresh_news_archive_month_options()
	news_controller._sync_root_refs()

func _refresh_news_article_list() -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._refresh_news_article_list()
	news_controller._sync_root_refs()

func _refresh_social() -> void:
	_ensure_social_controller()
	social_controller.refresh()
func _refresh_network() -> void:
	_ensure_network_controller()
	network_controller.refresh()


func _refresh_daily_action_displays() -> void:
	if advance_day_processing:
		_queue_deferred_open_app_refresh()
		return
	if _is_desktop_app_window_open(APP_ID_NETWORK):
		_refresh_network()
	if _is_desktop_app_window_open(APP_ID_ACADEMY):
		_refresh_academy()
	if _is_desktop_app_window_open(APP_ID_UPGRADES):
		_refresh_upgrades()


func _ensure_figma_desktop_ui() -> void:
	if desktop_figma_top_bar != null:
		return

	var desktop_shade: ColorRect = $DesktopLayer/DesktopShade
	desktop_shade.color = COLOR_DESKTOP_CREAM

	var desktop_margin: MarginContainer = $DesktopLayer/DesktopMargin
	desktop_margin.add_theme_constant_override("margin_left", 0)
	desktop_margin.add_theme_constant_override("margin_top", 0)
	desktop_margin.add_theme_constant_override("margin_right", 0)
	desktop_margin.add_theme_constant_override("margin_bottom", 0)

	var desktop_vbox: VBoxContainer = $DesktopLayer/DesktopMargin/DesktopVBox
	desktop_vbox.add_theme_constant_override("separation", 0)
	desktop_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desktop_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var header_row: Control = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopHeaderRow
	var old_icons_row: HBoxContainer = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow
	var desktop_footer_spacer: Control = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopFooterSpacer
	var desktop_spacer: Node = get_node_or_null("DesktopLayer/DesktopMargin/DesktopVBox/DesktopSpacer")
	var legacy_hidden_host: Control = desktop_layer.get_node_or_null("DesktopLegacyHidden") as Control
	if legacy_hidden_host == null:
		legacy_hidden_host = Control.new()
		legacy_hidden_host.name = "DesktopLegacyHidden"
		legacy_hidden_host.visible = false
		legacy_hidden_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		legacy_hidden_host.set_anchors_preset(Control.PRESET_FULL_RECT)
		desktop_layer.add_child(legacy_hidden_host)
	var legacy_nodes: Array[Node] = [
		header_row,
		desktop_subtitle_label,
		desktop_hint_label,
		old_icons_row,
		desktop_footer_spacer,
		desktop_spacer
	]
	for legacy_node in legacy_nodes:
		if legacy_node == null:
			continue
		if legacy_node.get_parent() != legacy_hidden_host:
			var legacy_parent: Node = legacy_node.get_parent()
			if legacy_parent != null:
				legacy_parent.remove_child(legacy_node)
			legacy_hidden_host.add_child(legacy_node)
		if legacy_node is Control:
			var legacy_control: Control = legacy_node as Control
			legacy_control.custom_minimum_size = Vector2.ZERO
			legacy_control.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			legacy_control.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		if legacy_node is CanvasItem:
			(legacy_node as CanvasItem).visible = false

	desktop_figma_top_bar = PanelContainer.new()
	desktop_figma_top_bar.name = "DesktopFigmaTopBar"
	var top_bar_height: float = float(_desktop_scaled_px(84.0, 72, 96))
	desktop_figma_top_bar.custom_minimum_size = Vector2(0, top_bar_height)
	desktop_figma_top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desktop_vbox.add_child(desktop_figma_top_bar)
	desktop_vbox.move_child(desktop_figma_top_bar, 0)

	desktop_figma_top_margin = MarginContainer.new()
	desktop_figma_top_margin.name = "DesktopFigmaTopMargin"
	desktop_figma_top_margin.add_theme_constant_override("margin_left", _desktop_scaled_px(28.0, 18, 36))
	desktop_figma_top_margin.add_theme_constant_override("margin_top", 0)
	desktop_figma_top_margin.add_theme_constant_override("margin_right", 0)
	desktop_figma_top_margin.add_theme_constant_override("margin_bottom", 0)
	desktop_figma_top_bar.add_child(desktop_figma_top_margin)

	var top_row := HBoxContainer.new()
	top_row.name = "DesktopFigmaTopRow"
	top_row.add_theme_constant_override("separation", _desktop_scaled_px(18.0, 12, 24))
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desktop_figma_top_margin.add_child(top_row)

	var date_row := HBoxContainer.new()
	date_row.name = "DesktopFigmaDateRow"
	date_row.add_theme_constant_override("separation", 10)
	date_row.alignment = BoxContainer.ALIGNMENT_CENTER
	date_row.custom_minimum_size = Vector2(float(_desktop_scaled_px(240.0, 180, 270)), 0)
	top_row.add_child(date_row)
	date_row.add_child(_make_desktop_icon_rect(str(DESKTOP_ICON_PATHS.get("date", "")), Vector2(24, 24)))

	desktop_figma_date_label = Label.new()
	desktop_figma_date_label.name = "DesktopFigmaDateLabel"
	desktop_figma_date_label.text = "NO RUN"
	desktop_figma_date_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desktop_figma_date_label.add_theme_font_size_override("font_size", 20)
	desktop_figma_date_label.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
	date_row.add_child(desktop_figma_date_label)

	var cash_spacer_left := Control.new()
	cash_spacer_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(cash_spacer_left)

	desktop_figma_cash_panel = PanelContainer.new()
	desktop_figma_cash_panel.name = "DesktopFigmaCashPanel"
	desktop_figma_cash_panel.custom_minimum_size = Vector2(
		float(_desktop_scaled_px(228.0, 180, 252)),
		float(_desktop_scaled_px(42.0, 36, 48))
	)
	top_row.add_child(desktop_figma_cash_panel)
	var cash_margin := MarginContainer.new()
	cash_margin.name = "DesktopFigmaCashMargin"
	cash_margin.add_theme_constant_override("margin_left", _desktop_scaled_px(18.0, 12, 22))
	cash_margin.add_theme_constant_override("margin_top", _desktop_scaled_px(7.0, 5, 9))
	cash_margin.add_theme_constant_override("margin_right", _desktop_scaled_px(18.0, 12, 22))
	cash_margin.add_theme_constant_override("margin_bottom", _desktop_scaled_px(7.0, 5, 9))
	desktop_figma_cash_panel.add_child(cash_margin)
	var cash_row := HBoxContainer.new()
	cash_row.name = "DesktopFigmaCashRow"
	cash_row.add_theme_constant_override("separation", _desktop_scaled_px(10.0, 8, 12))
	cash_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cash_margin.add_child(cash_row)
	cash_row.add_child(_make_desktop_icon_rect(str(DESKTOP_ICON_PATHS.get("cash", "")), Vector2(24, 24)))

	desktop_figma_cash_label = Label.new()
	desktop_figma_cash_label.name = "DesktopFigmaCashLabel"
	desktop_figma_cash_label.text = "RP 0"
	desktop_figma_cash_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desktop_figma_cash_label.add_theme_font_size_override("font_size", 20)
	desktop_figma_cash_label.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
	cash_row.add_child(desktop_figma_cash_label)

	var cash_spacer_right := Control.new()
	cash_spacer_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(cash_spacer_right)

	desktop_advance_day_button = Button.new()
	desktop_advance_day_button.name = "DesktopAdvanceDayButton"
	desktop_advance_day_button.text = "ADVANCE DAY"
	desktop_advance_day_button.custom_minimum_size = Vector2(
		float(_desktop_scaled_px(258.0, 220, 288)),
		top_bar_height
	)
	desktop_advance_day_button.icon = _desktop_texture(str(DESKTOP_ICON_PATHS.get("advance", "")))
	desktop_advance_day_button.expand_icon = false
	desktop_advance_day_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	desktop_advance_day_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	desktop_advance_day_button.add_theme_constant_override("icon_max_width", _desktop_scaled_px(30.0, 24, 34))
	desktop_advance_day_button.add_theme_constant_override("h_separation", _desktop_scaled_px(12.0, 8, 16))
	desktop_advance_day_button.tooltip_text = "Advance to the next trading day."
	desktop_advance_day_button.pressed.connect(_on_next_day_pressed)
	top_row.add_child(desktop_advance_day_button)

	desktop_figma_canvas_panel = PanelContainer.new()
	desktop_figma_canvas_panel.name = "DesktopFigmaCanvasPanel"
	desktop_figma_canvas_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desktop_figma_canvas_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desktop_figma_canvas_panel.custom_minimum_size = Vector2(0, 0)
	desktop_vbox.add_child(desktop_figma_canvas_panel)
	desktop_vbox.move_child(desktop_figma_canvas_panel, 1)

	desktop_figma_canvas_margin = MarginContainer.new()
	desktop_figma_canvas_margin.name = "DesktopFigmaCanvasMargin"
	var frame_padding: int = _desktop_scaled_px(16.0, 10, 20)
	desktop_figma_canvas_margin.add_theme_constant_override("margin_left", frame_padding)
	desktop_figma_canvas_margin.add_theme_constant_override("margin_top", frame_padding)
	desktop_figma_canvas_margin.add_theme_constant_override("margin_right", frame_padding)
	desktop_figma_canvas_margin.add_theme_constant_override("margin_bottom", frame_padding)
	desktop_figma_canvas_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desktop_figma_canvas_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desktop_figma_canvas_panel.add_child(desktop_figma_canvas_margin)

	desktop_figma_canvas_content_margin = MarginContainer.new()
	desktop_figma_canvas_content_margin.name = "DesktopFigmaCanvasContent"
	desktop_figma_canvas_content_margin.add_theme_constant_override("margin_left", _desktop_scaled_px(52.0, 28, 64))
	desktop_figma_canvas_content_margin.add_theme_constant_override("margin_top", _desktop_scaled_px(46.0, 24, 58))
	desktop_figma_canvas_content_margin.add_theme_constant_override("margin_right", _desktop_scaled_px(52.0, 28, 64))
	desktop_figma_canvas_content_margin.add_theme_constant_override("margin_bottom", _desktop_scaled_px(42.0, 20, 52))
	desktop_figma_canvas_content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desktop_figma_canvas_content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desktop_figma_canvas_margin.add_child(desktop_figma_canvas_content_margin)

	var canvas_vbox := VBoxContainer.new()
	canvas_vbox.name = "DesktopFigmaCanvasVBox"
	canvas_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_vbox.add_theme_constant_override("separation", 0)
	desktop_figma_canvas_content_margin.add_child(canvas_vbox)

	desktop_shortcut_grid = GridContainer.new()
	desktop_shortcut_grid.name = "DesktopFigmaShortcutGrid"
	desktop_shortcut_grid.columns = 8
	desktop_shortcut_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	desktop_shortcut_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	desktop_shortcut_grid.add_theme_constant_override("h_separation", _desktop_scaled_px(104.0, 68, 120))
	desktop_shortcut_grid.add_theme_constant_override("v_separation", _desktop_scaled_px(38.0, 24, 46))
	canvas_vbox.add_child(desktop_shortcut_grid)
	var canvas_spacer := Control.new()
	canvas_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_vbox.add_child(canvas_spacer)

	_reparent_desktop_shortcuts_to_figma_grid()

	_style_figma_desktop_ui()
	_update_desktop_figma_layout()


func _reparent_desktop_shortcuts_to_figma_grid() -> void:
	if desktop_shortcut_grid == null:
		return
	var shortcuts := [
		{
			"app_id": APP_ID_STOCK,
			"button": stock_app_button,
			"label": stock_app_label,
			"text": "STOCKBOT"
		},
		{
			"app_id": APP_ID_NEWS,
			"button": news_app_button,
			"label": news_app_label,
			"text": "NEWS"
		},
		{
			"app_id": APP_ID_SOCIAL,
			"button": social_app_button,
			"label": social_app_label,
			"text": "TWOOTER"
		},
		{
			"app_id": APP_ID_ACADEMY,
			"button": academy_app_button,
			"label": academy_app_label,
			"text": "ACADEMY"
		},
		{
			"app_id": APP_ID_THESIS,
			"button": thesis_app_button,
			"label": thesis_app_label,
			"text": "THESIS"
		},
		{
			"app_id": APP_ID_LIFE,
			"button": life_app_button,
			"label": life_app_label,
			"text": "LIFE"
		},
		{
			"app_id": APP_ID_COMPANY,
			"button": company_app_button,
			"label": company_app_label,
			"text": "COMPANY"
		},
		{
			"app_id": APP_ID_NETWORK,
			"button": network_app_button,
			"label": network_app_label,
			"text": "NETWORK"
		},
		{
			"app_id": APP_ID_UPGRADES,
			"button": upgrades_app_button,
			"label": upgrades_app_label,
			"text": "SHOP"
		},
		{
			"app_id": "settings",
			"button": exit_app_button,
			"label": exit_app_label,
			"text": "SETTINGS"
		}
	]

	for shortcut_value in shortcuts:
		var shortcut: Dictionary = shortcut_value
		var button: Button = shortcut.get("button", null)
		var label: Label = shortcut.get("label", null)
		if button == null or label == null:
			continue
		var tile: Control = button.get_parent() as Control
		if tile == null:
			continue
		var old_parent := tile.get_parent()
		if old_parent != desktop_shortcut_grid:
			if old_parent != null:
				old_parent.remove_child(tile)
			desktop_shortcut_grid.add_child(tile)
		tile.visible = true
		_configure_desktop_shortcut_tile(tile, button, label, str(shortcut.get("app_id", "")), str(shortcut.get("text", "")))


func _configure_desktop_shortcut_tile(tile: Control, button: Button, label: Label, app_id: String, display_text: String) -> void:
	tile.custom_minimum_size = Vector2(156, 184)
	tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if tile is VBoxContainer:
		var tile_box: VBoxContainer = tile
		tile_box.alignment = BoxContainer.ALIGNMENT_CENTER
		tile_box.add_theme_constant_override("separation", 14)

	button.text = ""
	button.custom_minimum_size = Vector2(132, 132)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.expand_icon = false
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.icon = _desktop_texture(_get_desktop_icon_path(app_id, "shortcut"))
	button.add_theme_constant_override("icon_max_width", 50)
	_style_desktop_shortcut_button(button)
	_ensure_desktop_shortcut_corner_marker(button)
	_ensure_desktop_shortcut_badge(button, app_id)

	label.text = display_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2.ZERO
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
	_style_desktop_label_plaque(label)
	if app_id == APP_ID_ACADEMY:
		_apply_academy_release_lock_state()


func _apply_academy_release_lock_state() -> void:
	if academy_app_button == null:
		return
	var academy_available: bool = GameManager.is_academy_available()
	var academy_tile: Control = academy_app_button.get_parent() as Control
	if academy_tile != null:
		academy_tile.visible = true
	if academy_window != null and not academy_available:
		academy_window.visible = false
	academy_app_button.visible = true
	academy_app_button.disabled = false
	academy_app_button.tooltip_text = "Open Academy lessons." if academy_available else GameManager.get_academy_release_message()
	academy_app_button.modulate = Color(1, 1, 1, 1) if academy_available else Color(0.74, 0.72, 0.66, 1)
	academy_app_button.set_pressed_no_signal(false if not academy_available else academy_app_button.button_pressed)
	if academy_app_label != null:
		academy_app_label.visible = true
		academy_app_label.text = "ACADEMY" if academy_available else "ACADEMY\nCOMING SOON"
		academy_app_label.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN if academy_available else Color(0.431373, 0.380392, 0.286275, 1))
		academy_app_label.add_theme_font_size_override("font_size", 15 if academy_available else 13)
	_ensure_academy_coming_soon_badge(not academy_available)
	if not academy_available and _is_desktop_app_window_open(APP_ID_ACADEMY):
		_close_desktop_app_window(APP_ID_ACADEMY)


func _ensure_academy_coming_soon_badge(is_shown: bool) -> void:
	if academy_app_button == null:
		return
	var badge: Label = academy_app_button.get_node_or_null("AcademyComingSoonBadge") as Label
	if badge == null:
		badge = Label.new()
		badge.name = "AcademyComingSoonBadge"
		badge.text = "SOON"
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 11)
		badge.add_theme_color_override("font_color", COLOR_DESKTOP_CREAM)
		badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		badge.offset_left = -54
		badge.offset_top = -30
		badge.offset_right = -8
		badge.offset_bottom = -8
		academy_app_button.add_child(badge)
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color(0.509804, 0.231373, 0.0941176, 0.94)
		badge_style.border_color = COLOR_DESKTOP_GOLD
		badge_style.set_border_width_all(1)
		badge_style.set_corner_radius_all(4)
		badge.add_theme_stylebox_override("normal", badge_style)
	badge.visible = is_shown


func _ensure_desktop_shortcut_corner_marker(button: Button) -> void:
	if button.get_node_or_null("DesktopShortcutCornerMarker") != null:
		return
	var marker := ColorRect.new()
	marker.name = "DesktopShortcutCornerMarker"
	marker.color = COLOR_DESKTOP_BROWN
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	marker.offset_left = -18
	marker.offset_top = 0
	marker.offset_right = -2
	marker.offset_bottom = 16
	button.add_child(marker)


func _ensure_desktop_shortcut_badge(button: Button, app_id: String) -> void:
	if app_id != APP_ID_NEWS and app_id != APP_ID_SOCIAL and app_id != APP_ID_NETWORK:
		return
	var badge: Label = button.get_node_or_null("DesktopShortcutBadge") as Label
	if badge == null:
		badge = Label.new()
		badge.name = "DesktopShortcutBadge"
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", COLOR_DESKTOP_CREAM)
		badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		badge.offset_left = -34
		badge.offset_top = 8
		badge.offset_right = -8
		badge.offset_bottom = 34
		button.add_child(badge)
	_style_desktop_notification_badge(badge)
	desktop_shortcut_badges[app_id] = badge


func _style_desktop_notification_badge(badge: Label) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_DESKTOP_BROWN
	style.border_color = COLOR_DESKTOP_GOLD
	style.set_border_width_all(2)
	style.corner_radius_top_left = 13
	style.corner_radius_top_right = 13
	style.corner_radius_bottom_left = 13
	style.corner_radius_bottom_right = 13
	badge.add_theme_stylebox_override("normal", style)


func _refresh_desktop_notification_badges() -> void:
	if desktop_shortcut_badges.is_empty():
		return
	var badge_snapshot: Dictionary = GameManager.get_desktop_app_badge_snapshot()
	for app_id_value in desktop_shortcut_badges.keys():
		var app_id: String = str(app_id_value)
		var badge: Label = desktop_shortcut_badges.get(app_id, null) as Label
		if badge == null:
			continue
		var badge_row: Dictionary = badge_snapshot.get(app_id, {})
		badge.visible = bool(badge_row.get("visible", false))
		badge.text = str(badge_row.get("label", "!"))


func _initialize_desktop_badge_seen_defaults() -> void:
	if not RunState.has_active_run():
		return
	var seen_days: Dictionary = RunState.get_desktop_app_seen_days()
	for app_id in [APP_ID_NEWS, APP_ID_SOCIAL, APP_ID_NETWORK]:
		if not seen_days.has(app_id):
			RunState.mark_desktop_app_seen(app_id)


func _is_badge_tracked_app(app_id: String) -> bool:
	return app_id == APP_ID_NEWS or app_id == APP_ID_SOCIAL or app_id == APP_ID_NETWORK


func _mark_desktop_app_seen_if_needed(app_id: String) -> void:
	if not _is_badge_tracked_app(app_id) or not RunState.has_active_run():
		return
	if RunState.get_desktop_app_seen_day(app_id) >= RunState.day_index:
		return
	GameManager.mark_desktop_app_seen(app_id)
	_refresh_desktop_notification_badges()


func _add_desktop_bottom_nav_button(parent: HBoxContainer, app_id: String, label_text: String, callback: Callable) -> void:
	var nav_button := Button.new()
	nav_button.name = "DesktopBottomNav%sButton" % label_text.capitalize().replace(" ", "")
	nav_button.text = label_text
	nav_button.icon = _desktop_texture(_get_desktop_icon_path(app_id, "nav"))
	nav_button.expand_icon = false
	nav_button.toggle_mode = app_id != "exit"
	nav_button.custom_minimum_size = Vector2(132, 48)
	nav_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_button.tooltip_text = "Open %s." % label_text.capitalize()
	nav_button.pressed.connect(callback)
	parent.add_child(nav_button)
	desktop_bottom_nav_buttons[app_id] = nav_button
	_style_desktop_bottom_nav_button(nav_button, false)


func _get_desktop_icon_path(app_id: String, kind: String) -> String:
	if not DESKTOP_ICON_PATHS.has(app_id):
		return ""
	var entry = DESKTOP_ICON_PATHS.get(app_id)
	if entry is Dictionary:
		return str(entry.get(kind, ""))
	return ""


func _desktop_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource := load(path)
	if resource is Texture2D:
		return resource
	return null


func _is_fullscreen_window_mode() -> bool:
	if OS.has_feature("headless"):
		return false
	var mode: int = DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func _desktop_safe_insets() -> Vector4:
	if OS.get_name() != "macOS" or not _is_fullscreen_window_mode():
		return Vector4.ZERO
	return Vector4(
		MAC_FULLSCREEN_SAFE_MARGIN_X,
		MAC_FULLSCREEN_SAFE_MARGIN_TOP,
		MAC_FULLSCREEN_SAFE_MARGIN_X,
		MAC_FULLSCREEN_SAFE_MARGIN_BOTTOM
	)


func _desktop_effective_viewport_size() -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var safe_insets: Vector4 = _desktop_safe_insets()
	return Vector2(
		max(viewport_size.x - safe_insets.x - safe_insets.z, 1.0),
		max(viewport_size.y - safe_insets.y - safe_insets.w, 1.0)
	)


func _make_desktop_icon_rect(path: String, minimum_size: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = "DesktopIcon"
	icon.texture = _desktop_texture(path)
	icon.custom_minimum_size = minimum_size
	icon.size = minimum_size
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


func _desktop_reference_scale() -> float:
	var viewport_size: Vector2 = _desktop_effective_viewport_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	var width_scale: float = viewport_size.x / DESKTOP_REFERENCE_VIEWPORT.x
	var height_scale: float = viewport_size.y / DESKTOP_REFERENCE_VIEWPORT.y
	return clamp(min(width_scale, height_scale), 0.65, 1.2)


func _desktop_scaled_px(reference_px: float, min_px: int, max_px: int) -> int:
	return clampi(int(round(reference_px * _desktop_reference_scale())), min_px, max_px)


func _update_desktop_figma_layout() -> void:
	if desktop_shortcut_grid == null:
		return
	var safe_insets: Vector4 = _desktop_safe_insets()
	var effective_viewport_width: float = _desktop_effective_viewport_size().x
	if effective_viewport_width >= 1760.0:
		desktop_shortcut_grid.columns = 7
	elif effective_viewport_width >= 1040.0:
		desktop_shortcut_grid.columns = 4
	elif effective_viewport_width >= 720.0:
		desktop_shortcut_grid.columns = 3
	else:
		desktop_shortcut_grid.columns = 2

	var desktop_margin: MarginContainer = $DesktopLayer/DesktopMargin
	desktop_margin.add_theme_constant_override("margin_left", 0)
	desktop_margin.add_theme_constant_override("margin_top", 0)
	desktop_margin.add_theme_constant_override("margin_right", 0)
	desktop_margin.add_theme_constant_override("margin_bottom", 0)

	_update_desktop_shortcut_metrics()

	var top_bar_height: float = float(_desktop_scaled_px(84.0, 72, 96))
	if desktop_figma_top_bar != null:
		desktop_figma_top_bar.custom_minimum_size = Vector2(0, top_bar_height)
	if desktop_figma_top_margin != null:
		desktop_figma_top_margin.add_theme_constant_override("margin_left", int(DESKTOP_EDGE_CONTENT_MARGIN + safe_insets.x))
		desktop_figma_top_margin.add_theme_constant_override("margin_top", int(safe_insets.y))
		desktop_figma_top_margin.add_theme_constant_override("margin_right", int(DESKTOP_EDGE_CONTENT_MARGIN + safe_insets.z))
		desktop_figma_top_margin.add_theme_constant_override("margin_bottom", 0)
	if desktop_figma_cash_panel != null:
		desktop_figma_cash_panel.custom_minimum_size = Vector2(
			float(_desktop_scaled_px(228.0, 180, 252)),
			float(_desktop_scaled_px(42.0, 36, 48))
		)
	if desktop_advance_day_button != null:
		desktop_advance_day_button.custom_minimum_size = Vector2(
			float(_desktop_scaled_px(258.0, 220, 288)),
			top_bar_height
		)
		desktop_advance_day_button.add_theme_constant_override("icon_max_width", _desktop_scaled_px(30.0, 24, 34))
		desktop_advance_day_button.add_theme_constant_override("h_separation", _desktop_scaled_px(12.0, 8, 16))

	if desktop_figma_canvas_margin != null:
		var frame_padding: int = _desktop_scaled_px(16.0, 10, 20)
		desktop_figma_canvas_margin.add_theme_constant_override("margin_left", frame_padding)
		desktop_figma_canvas_margin.add_theme_constant_override("margin_top", frame_padding)
		desktop_figma_canvas_margin.add_theme_constant_override("margin_right", frame_padding)
		desktop_figma_canvas_margin.add_theme_constant_override("margin_bottom", frame_padding)

	if desktop_figma_canvas_content_margin != null:
		var content_side_margin: int = _desktop_scaled_px(22.0, 12, 28)
		var content_top_margin: int = _desktop_scaled_px(24.0, 14, 30)
		var content_bottom_margin: int = _desktop_scaled_px(24.0, 14, 30)
		if desktop_shortcut_grid.columns >= 7:
			content_side_margin = _desktop_scaled_px(52.0, 28, 64)
			content_top_margin = _desktop_scaled_px(46.0, 24, 58)
			content_bottom_margin = _desktop_scaled_px(42.0, 20, 52)
		elif desktop_shortcut_grid.columns == 4:
			content_side_margin = _desktop_scaled_px(34.0, 20, 44)
			content_top_margin = _desktop_scaled_px(34.0, 20, 42)
			content_bottom_margin = _desktop_scaled_px(30.0, 18, 38)
		elif desktop_shortcut_grid.columns == 3:
			content_side_margin = _desktop_scaled_px(26.0, 16, 34)
			content_top_margin = _desktop_scaled_px(28.0, 18, 34)
			content_bottom_margin = _desktop_scaled_px(26.0, 16, 32)
		desktop_figma_canvas_content_margin.add_theme_constant_override("margin_left", int(content_side_margin + safe_insets.x))
		desktop_figma_canvas_content_margin.add_theme_constant_override("margin_top", int(content_top_margin))
		desktop_figma_canvas_content_margin.add_theme_constant_override("margin_right", int(content_side_margin + safe_insets.z))
		desktop_figma_canvas_content_margin.add_theme_constant_override("margin_bottom", int(content_bottom_margin + safe_insets.w))

	var h_separation: int = _desktop_scaled_px(24.0, 14, 32)
	var v_separation: int = _desktop_scaled_px(26.0, 16, 34)
	if desktop_shortcut_grid.columns >= 7:
		h_separation = _desktop_scaled_px(104.0, 68, 120)
		v_separation = _desktop_scaled_px(38.0, 24, 46)
	elif desktop_shortcut_grid.columns == 4:
		h_separation = _desktop_scaled_px(56.0, 32, 72)
		v_separation = _desktop_scaled_px(34.0, 22, 40)
	elif desktop_shortcut_grid.columns == 3:
		h_separation = _desktop_scaled_px(32.0, 20, 40)
		v_separation = _desktop_scaled_px(28.0, 18, 34)
	desktop_shortcut_grid.add_theme_constant_override("h_separation", h_separation)
	desktop_shortcut_grid.add_theme_constant_override("v_separation", v_separation)
	_apply_taskbar_safe_insets(safe_insets)


func _update_desktop_shortcut_metrics() -> void:
	if desktop_shortcut_grid == null:
		return
	var tile_size := Vector2(
		float(_desktop_scaled_px(156.0, 132, 156)),
		float(_desktop_scaled_px(184.0, 156, 184))
	)
	var button_size := Vector2(
		float(_desktop_scaled_px(132.0, 112, 132)),
		float(_desktop_scaled_px(132.0, 112, 132))
	)
	var icon_width: int = _desktop_scaled_px(50.0, 42, 50)
	var tile_separation: int = _desktop_scaled_px(14.0, 10, 14)
	for child_value in desktop_shortcut_grid.get_children():
		var tile: Control = child_value as Control
		if tile == null:
			continue
		tile.custom_minimum_size = tile_size
		if tile is VBoxContainer:
			(tile as VBoxContainer).add_theme_constant_override("separation", tile_separation)
		for tile_child_value in tile.get_children():
			var button: Button = tile_child_value as Button
			if button != null:
				button.custom_minimum_size = button_size
				button.add_theme_constant_override("icon_max_width", icon_width)


func _apply_taskbar_safe_insets(safe_insets: Vector4) -> void:
	if taskbar_layer == null:
		return
	taskbar_layer.offset_left = 18.0 + safe_insets.x
	taskbar_layer.offset_top = -70.0 - safe_insets.w
	taskbar_layer.offset_right = -18.0 - safe_insets.z
	taskbar_layer.offset_bottom = -18.0 - safe_insets.w


func _refresh_figma_desktop_status() -> void:
	if desktop_figma_date_label == null or desktop_figma_cash_label == null:
		return
	if not RunState.has_active_run():
		desktop_figma_date_label.text = "NO RUN"
		desktop_figma_cash_label.text = "RP 0"
		desktop_figma_cash_label.tooltip_text = ""
		desktop_figma_cash_label.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
		if desktop_figma_cash_panel != null:
			_style_desktop_cash_panel(desktop_figma_cash_panel)
		if desktop_advance_day_button != null:
			desktop_advance_day_button.disabled = true
			if not advance_day_processing:
				desktop_advance_day_button.text = "ADVANCE DAY"
				desktop_advance_day_button.tooltip_text = "Start or load a run before advancing."
		return
	var current_trade_date: Dictionary = GameManager.get_current_trade_date()
	var portfolio: Dictionary = GameManager.get_portfolio_snapshot()
	var finance_status: Dictionary = GameManager.get_finance_status_snapshot()
	var cash_value: float = float(portfolio.get("cash", 0.0))
	desktop_figma_date_label.text = _format_desktop_figma_date(current_trade_date).to_upper()
	desktop_figma_cash_label.text = _format_desktop_figma_cash(cash_value)
	desktop_figma_cash_label.tooltip_text = "Cash available for new orders."
	desktop_figma_cash_label.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
	if desktop_figma_cash_panel != null:
		_style_desktop_cash_panel(desktop_figma_cash_panel)
	if bool(finance_status.get("bankrupt", false)):
		desktop_figma_cash_label.text = "BANKRUPT  |  %s" % _format_desktop_figma_cash(cash_value)
		desktop_figma_cash_label.tooltip_text = "Bankruptcy has disabled trading, loans, upgrades, and Advance Day."
		desktop_figma_cash_label.add_theme_color_override("font_color", Color(0.521569, 0.160784, 0.141176, 1))
	elif cash_value < 0.0:
		desktop_figma_cash_label.tooltip_text = "Cash stress active. Sell holdings, lower Life costs, or use Life > Finance."
		desktop_figma_cash_label.add_theme_color_override("font_color", Color(0.521569, 0.160784, 0.141176, 1))
	elif bool(finance_status.get("loan_payment_risky", false)):
		desktop_figma_cash_label.tooltip_text = "Emergency loan payment reserve is not covered."
		desktop_figma_cash_label.add_theme_color_override("font_color", COLOR_DESKTOP_GOLD)
	if desktop_advance_day_button != null:
		var bankrupt: bool = bool(finance_status.get("bankrupt", false))
		desktop_advance_day_button.disabled = advance_day_processing or bankrupt
		if not advance_day_processing:
			desktop_advance_day_button.text = "BANKRUPT" if bankrupt else "ADVANCE DAY"
			var advance_block_reason: String = GameManager.get_life_action_block_reason("advance_day")
			if bankrupt:
				desktop_advance_day_button.tooltip_text = "Run ended. Use the bankruptcy overlay or Settings."
			elif not advance_block_reason.is_empty() and advance_block_reason != "BANKRUPTCY_REQUIRED":
				desktop_advance_day_button.tooltip_text = advance_block_reason
			else:
				desktop_advance_day_button.tooltip_text = "Advance to the next trading day."


func _format_desktop_figma_date(date_info: Dictionary) -> String:
	var month_index: int = int(date_info.get("month", 1)) - 1
	var month_name: String = "Jan"
	if month_index >= 0 and month_index < DASHBOARD_MONTH_NAMES.size():
		month_name = str(DASHBOARD_MONTH_NAMES[month_index])
	return "%s %d, %d" % [
		month_name,
		int(date_info.get("day", 1)),
		int(date_info.get("year", 2020))
	]


func _format_desktop_figma_cash(value: float) -> String:
	var formatted := _format_currency(value).replace("Rp", "")
	return "RP %s" % formatted


func _style_figma_desktop_ui() -> void:
	if desktop_figma_top_bar != null:
		var top_bar_style := StyleBoxFlat.new()
		top_bar_style.bg_color = COLOR_DESKTOP_CREAM
		top_bar_style.border_color = Color(COLOR_DESKTOP_FRAME.r, COLOR_DESKTOP_FRAME.g, COLOR_DESKTOP_FRAME.b, 0.95)
		top_bar_style.border_width_bottom = 4
		top_bar_style.set_corner_radius_all(0)
		top_bar_style.shadow_color = Color(0.26, 0.22, 0.15, 0.14)
		top_bar_style.shadow_size = 8
		top_bar_style.shadow_offset = Vector2(0, 6)
		desktop_figma_top_bar.add_theme_stylebox_override("panel", top_bar_style)
	if desktop_figma_date_label != null:
		desktop_figma_date_label.add_theme_font_size_override("font_size", 20)
		desktop_figma_date_label.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
	if desktop_figma_cash_panel != null:
		_style_desktop_cash_panel(desktop_figma_cash_panel)
	if desktop_figma_cash_label != null:
		desktop_figma_cash_label.add_theme_font_size_override("font_size", 20)
		desktop_figma_cash_label.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
	if desktop_figma_canvas_panel != null:
		var canvas_style := StyleBoxFlat.new()
		canvas_style.bg_color = COLOR_DESKTOP_CREAM
		canvas_style.border_color = COLOR_DESKTOP_FRAME
		canvas_style.set_border_width_all(_desktop_scaled_px(14.0, 10, 18))
		canvas_style.set_corner_radius_all(0)
		canvas_style.shadow_color = Color(0.25, 0.22, 0.16, 0.12)
		canvas_style.shadow_size = 6
		canvas_style.shadow_offset = Vector2(0, 2)
		desktop_figma_canvas_panel.add_theme_stylebox_override("panel", canvas_style)
	if desktop_bottom_nav_bar != null:
		_style_panel(desktop_bottom_nav_bar, COLOR_DESKTOP_PANEL, 0)
	if desktop_advance_day_button != null:
		_style_desktop_advance_button(desktop_advance_day_button)
	_style_desktop_shortcut_button(stock_app_button)
	_style_desktop_shortcut_button(news_app_button)
	_style_desktop_shortcut_button(social_app_button)
	if academy_app_button != null:
		_style_desktop_shortcut_button(academy_app_button)
	if thesis_app_button != null:
		_style_desktop_shortcut_button(thesis_app_button)
	if life_app_button != null:
		_style_desktop_shortcut_button(life_app_button)
	_style_desktop_shortcut_button(network_app_button)
	_style_desktop_shortcut_button(upgrades_app_button)
	_style_desktop_shortcut_button(exit_app_button)
	_style_desktop_label_plaque(stock_app_label)
	_style_desktop_label_plaque(news_app_label)
	_style_desktop_label_plaque(social_app_label)
	if academy_app_label != null:
		_style_desktop_label_plaque(academy_app_label)
	if thesis_app_label != null:
		_style_desktop_label_plaque(thesis_app_label)
	if life_app_label != null:
		_style_desktop_label_plaque(life_app_label)
	_style_desktop_label_plaque(network_app_label)
	_style_desktop_label_plaque(upgrades_app_label)
	_style_desktop_label_plaque(exit_app_label)
	for app_id in desktop_bottom_nav_buttons.keys():
		var button: Button = desktop_bottom_nav_buttons[app_id]
		_style_desktop_bottom_nav_button(button, str(app_id) == active_app_id)


func _style_desktop_cash_panel(panel: PanelContainer) -> void:
	if panel == null:
		return
	UiTheme.style_panel(panel, "desktop_cash")


func _style_desktop_shortcut_button(button: Button) -> void:
	if button == null:
		return
	UiTheme.style_button(button, "desktop_shortcut")


func _style_desktop_label_plaque(label: Label) -> void:
	if label == null:
		return
	var plaque := StyleBoxFlat.new()
	plaque.bg_color = Color(0.992157, 0.956863, 0.878431, 0.96)
	plaque.border_color = Color(COLOR_DESKTOP_BROWN.r, COLOR_DESKTOP_BROWN.g, COLOR_DESKTOP_BROWN.b, 0.12)
	plaque.set_border_width_all(1)
	plaque.set_corner_radius_all(0)
	plaque.content_margin_left = 10
	plaque.content_margin_top = 4
	plaque.content_margin_right = 10
	plaque.content_margin_bottom = 4
	label.add_theme_stylebox_override("normal", plaque)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)


func _style_desktop_advance_button(button: Button) -> void:
	if button == null:
		return
	UiTheme.style_button(button, "desktop_advance")


func _style_desktop_bottom_nav_button(button: Button, active: bool) -> void:
	if button == null:
		return
	UiTheme.style_button(button, "desktop_nav", {"selected": active})


func _ensure_desktop_window_layer() -> void:
	if desktop_window_layer != null:
		return
	desktop_window_layer = Control.new()
	desktop_window_layer.name = "DesktopWindowLayer"
	desktop_window_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	desktop_window_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(desktop_window_layer)
	var debug_overlay_node: Node = get_node_or_null("DebugOverlay")
	if debug_overlay_node != null:
		move_child(desktop_window_layer, debug_overlay_node.get_index())


func _initialize_desktop_app_windows() -> void:
	if desktop_window_layer == null or not desktop_app_windows.is_empty():
		return
	app_window_backdrop.visible = false
	app_window_title_bar.visible = false
	_register_desktop_app_window(APP_ID_STOCK, "STOCKBOT", [stock_window_container, app_content_margin])
	_register_desktop_app_window(APP_ID_NEWS, "News Browser", [news_window])
	_register_desktop_app_window(APP_ID_SOCIAL, "Twooter", [social_window])
	_register_desktop_app_window(APP_ID_NETWORK, "Network", [network_window])
	if academy_window != null:
		_register_desktop_app_window(APP_ID_ACADEMY, "Academy", [academy_window])
	if thesis_window != null:
		_register_desktop_app_window(APP_ID_THESIS, "Thesis Board", [thesis_window])
	if life_window != null:
		_register_desktop_app_window(APP_ID_LIFE, "Life", [life_window])
	if company_window != null:
		_register_desktop_app_window(APP_ID_COMPANY, "Company", [company_window])
	_register_desktop_app_window(APP_ID_UPGRADES, "Upgrades", [upgrade_window])
	_apply_desktop_window_layouts()


func _register_desktop_app_window(app_id: String, title: String, content_nodes: Array) -> void:
	if desktop_app_windows.has(app_id):
		return
	var window := Control.new()
	window.name = "%sDesktopWindow" % title.replace(" ", "")
	window.visible = false
	window.set_anchors_preset(Control.PRESET_TOP_LEFT)
	window.custom_minimum_size = _desktop_window_min_size_for_app(app_id)
	window.mouse_filter = Control.MOUSE_FILTER_PASS
	desktop_window_layer.add_child(window)

	var frame := PanelContainer.new()
	frame.name = "Frame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.add_child(frame)

	var title_bar := PanelContainer.new()
	title_bar.name = "TitleBar"
	title_bar.anchor_left = 0.0
	title_bar.anchor_right = 1.0
	var chrome_inset: int = _desktop_window_frame_inset_for_app(app_id)
	title_bar.offset_left = chrome_inset
	title_bar.offset_top = chrome_inset
	title_bar.offset_right = -chrome_inset
	title_bar.offset_bottom = DESKTOP_WINDOW_TITLE_BAR_HEIGHT
	title_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	window.add_child(title_bar)

	var title_margin := MarginContainer.new()
	title_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_margin.add_theme_constant_override("margin_left", 10)
	title_margin.add_theme_constant_override("margin_top", 6)
	title_margin.add_theme_constant_override("margin_right", 10)
	title_margin.add_theme_constant_override("margin_bottom", 6)
	title_bar.add_child(title_margin)

	var title_row := HBoxContainer.new()
	title_row.name = "TitleRow"
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_theme_constant_override("separation", 8)
	title_margin.add_child(title_row)

	var drag_handle := MarginContainer.new()
	drag_handle.name = "DragHandle"
	drag_handle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drag_handle.mouse_filter = Control.MOUSE_FILTER_STOP
	drag_handle.mouse_default_cursor_shape = Control.CURSOR_MOVE
	drag_handle.gui_input.connect(_on_desktop_window_drag_handle_gui_input.bind(app_id))
	title_row.add_child(drag_handle)

	var drag_label := Label.new()
	drag_label.name = "TitleLabel"
	drag_label.text = title
	drag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_handle.add_child(drag_label)

	var minimize_button := Button.new()
	minimize_button.name = "MinimizeButton"
	minimize_button.text = "_"
	minimize_button.custom_minimum_size = Vector2(28, 24)
	minimize_button.tooltip_text = "Hide this window."
	minimize_button.pressed.connect(_on_desktop_window_minimize_pressed.bind(app_id))
	title_row.add_child(minimize_button)

	var close_button := Button.new()
	close_button.name = "StockbotCloseButton" if app_id == APP_ID_STOCK else "CloseButton"
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(28, 24)
	close_button.tooltip_text = "Close this window."
	close_button.pressed.connect(_on_desktop_window_close_pressed.bind(app_id))
	title_row.add_child(close_button)

	var content_host := Control.new()
	content_host.name = "ContentHost"
	content_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_host.offset_left = chrome_inset
	content_host.offset_top = DESKTOP_WINDOW_TITLE_BAR_HEIGHT
	content_host.offset_right = -chrome_inset
	content_host.offset_bottom = -chrome_inset
	content_host.clip_contents = true
	content_host.mouse_filter = Control.MOUSE_FILTER_PASS
	window.add_child(content_host)

	for content_node_value in content_nodes:
		var content_node: Control = content_node_value as Control
		if content_node == null:
			continue
		_reparent_desktop_window_content(content_node, content_host)

	desktop_app_windows[app_id] = {
		"window": window,
		"frame": frame,
		"title_bar": title_bar,
		"title_label": drag_label,
		"minimize_button": minimize_button,
		"close_button": close_button,
		"content_host": content_host,
		"rect_initialized": false
	}


func _reparent_desktop_window_content(content_node: Control, host: Control) -> void:
	var previous_parent: Node = content_node.get_parent()
	if previous_parent != null:
		previous_parent.remove_child(content_node)
	host.add_child(content_node)
	content_node.visible = true
	content_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_node.offset_left = 0
	content_node.offset_top = 0
	content_node.offset_right = 0
	content_node.offset_bottom = 0
	content_node.grow_horizontal = Control.GROW_DIRECTION_END
	content_node.grow_vertical = Control.GROW_DIRECTION_END


func _desktop_window_min_size_for_app(app_id: String) -> Vector2:
	match app_id:
		APP_ID_STOCK:
			return Vector2(920, 560)
		APP_ID_NEWS:
			return Vector2(820, 560)
		APP_ID_SOCIAL:
			return Vector2(920, 560)
		APP_ID_NETWORK:
			return Vector2(780, 620)
		APP_ID_ACADEMY:
			return Vector2(860, 620)
		APP_ID_THESIS:
			return Vector2(920, 620)
		APP_ID_LIFE:
			return Vector2(860, 640)
		APP_ID_COMPANY:
			return Vector2(720, 520)
		APP_ID_UPGRADES:
			return Vector2(640, 460)
		_:
			return Vector2(DESKTOP_WINDOW_MIN_WIDTH, DESKTOP_WINDOW_MIN_HEIGHT)


func _desktop_window_work_rect() -> Rect2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var safe_insets: Vector4 = _desktop_safe_insets()
	var inset_left: float = 4.0 + safe_insets.x
	var inset_top: float = 4.0 + safe_insets.y
	var inset_right: float = 4.0 + safe_insets.z
	var inset_bottom: float = 4.0 + safe_insets.w
	return Rect2(
		Vector2(inset_left, inset_top),
		Vector2(
			max(viewport_size.x - inset_left - inset_right, 240.0),
			max(viewport_size.y - inset_top - inset_bottom, 180.0)
		)
	)


func _desktop_window_default_rect(app_id: String) -> Rect2:
	var work_rect: Rect2 = _desktop_window_work_rect()
	var window_size := _desktop_window_min_size_for_app(app_id)
	match app_id:
		APP_ID_STOCK:
			window_size.x = min(max(work_rect.size.x - 20.0, window_size.x), work_rect.size.x)
			window_size.y = min(max(work_rect.size.y - 28.0, window_size.y), work_rect.size.y)
			return Rect2(work_rect.position + Vector2(10, 10), window_size)
		APP_ID_NEWS:
			window_size.x = min(max(work_rect.size.x * 0.8, window_size.x), work_rect.size.x - 12.0)
			window_size.y = min(max(work_rect.size.y * 0.84, window_size.y), work_rect.size.y - 12.0)
			return Rect2(work_rect.position + Vector2(26, 18), window_size)
		APP_ID_SOCIAL:
			window_size.x = min(max(work_rect.size.x * 0.86, window_size.x), min(SOCIAL_WINDOW_MAX_WIDTH + 36.0, work_rect.size.x - 12.0))
			window_size.y = min(max(work_rect.size.y * 0.84, window_size.y), min(SOCIAL_WINDOW_MAX_HEIGHT + 24.0, work_rect.size.y - 12.0))
			return Rect2(work_rect.position + Vector2(24, 18), window_size)
		APP_ID_NETWORK:
			window_size.x = min(max(work_rect.size.x * 0.78, window_size.x), work_rect.size.x - 12.0)
			window_size.y = min(max(work_rect.size.y * 0.88, window_size.y), work_rect.size.y - 12.0)
			return Rect2(work_rect.position + Vector2(28, 14), window_size)
		APP_ID_ACADEMY:
			window_size.x = min(max(work_rect.size.x * 0.78, window_size.x), work_rect.size.x - 12.0)
			window_size.y = min(max(work_rect.size.y * 0.86, window_size.y), work_rect.size.y - 12.0)
			return Rect2(work_rect.position + Vector2(24, 18), window_size)
		APP_ID_THESIS:
			window_size.x = min(max(work_rect.size.x * 0.82, window_size.x), work_rect.size.x - 12.0)
			window_size.y = min(max(work_rect.size.y * 0.86, window_size.y), work_rect.size.y - 12.0)
			return Rect2(work_rect.position + Vector2(32, 22), window_size)
		APP_ID_LIFE:
			window_size.x = min(max(work_rect.size.x * 0.72, window_size.x), min(LIFE_WINDOW_MAX_WIDTH, work_rect.size.x - 12.0))
			window_size.y = min(max(work_rect.size.y * 0.88, window_size.y), work_rect.size.y - 12.0)
			var centered_x: float = max(floor((work_rect.size.x - window_size.x) * 0.5), 16.0)
			return Rect2(work_rect.position + Vector2(centered_x, 18), window_size)
		APP_ID_COMPANY:
			window_size.x = min(max(work_rect.size.x * 0.68, window_size.x), work_rect.size.x - 16.0)
			window_size.y = min(max(work_rect.size.y * 0.72, window_size.y), work_rect.size.y - 16.0)
			return Rect2(work_rect.position + Vector2(64, 36), window_size)
		APP_ID_UPGRADES:
			window_size.x = min(max(work_rect.size.x * 0.64, window_size.x), work_rect.size.x - 16.0)
			window_size.y = min(max(work_rect.size.y * 0.7, window_size.y), work_rect.size.y - 16.0)
			return Rect2(work_rect.position + Vector2(72, 48), window_size)
		_:
			window_size.x = min(window_size.x, work_rect.size.x)
			window_size.y = min(window_size.y, work_rect.size.y)
			return Rect2(work_rect.position, window_size)


func _desktop_window_initial_rect(app_id: String) -> Rect2:
	var rect: Rect2 = _desktop_window_default_rect(app_id)
	var top_app_id: String = _top_visible_desktop_window_id()
	if top_app_id.is_empty():
		return rect
	var top_meta: Dictionary = desktop_app_windows.get(top_app_id, {})
	var top_window: Control = top_meta.get("window", null) as Control
	if top_window == null:
		return rect
	rect.position = top_window.position + Vector2(56, 56)
	return _clamp_desktop_rect_to_work_area(app_id, rect)


func _apply_desktop_window_layouts() -> void:
	if desktop_window_layer == null:
		return
	_attach_content_full_rect(stock_window_container)
	_attach_content_full_rect(app_content_margin)
	app_content_margin.add_theme_constant_override("margin_left", 0)
	app_content_margin.add_theme_constant_override("margin_top", 0)
	app_content_margin.add_theme_constant_override("margin_right", 0)
	app_content_margin.add_theme_constant_override("margin_bottom", 0)
	news_window.add_theme_constant_override("margin_left", 0)
	news_window.add_theme_constant_override("margin_top", 0)
	news_window.add_theme_constant_override("margin_right", 0)
	news_window.add_theme_constant_override("margin_bottom", 0)
	social_window.add_theme_constant_override("margin_left", 0)
	social_window.add_theme_constant_override("margin_top", 0)
	social_window.add_theme_constant_override("margin_right", 0)
	social_window.add_theme_constant_override("margin_bottom", 0)
	network_window.add_theme_constant_override("margin_left", 0)
	network_window.add_theme_constant_override("margin_top", 0)
	network_window.add_theme_constant_override("margin_right", 0)
	network_window.add_theme_constant_override("margin_bottom", 0)
	if academy_window != null:
		academy_window.add_theme_constant_override("margin_left", 0)
		academy_window.add_theme_constant_override("margin_top", 0)
		academy_window.add_theme_constant_override("margin_right", 0)
		academy_window.add_theme_constant_override("margin_bottom", 0)
		_attach_content_full_rect(academy_window)
	if thesis_window != null:
		thesis_window.add_theme_constant_override("margin_left", 0)
		thesis_window.add_theme_constant_override("margin_top", 0)
		thesis_window.add_theme_constant_override("margin_right", 0)
		thesis_window.add_theme_constant_override("margin_bottom", 0)
		_attach_content_full_rect(thesis_window)
	if life_window != null:
		life_window.add_theme_constant_override("margin_left", 0)
		life_window.add_theme_constant_override("margin_top", 0)
		life_window.add_theme_constant_override("margin_right", 0)
		life_window.add_theme_constant_override("margin_bottom", 0)
		_attach_content_full_rect(life_window)
	if company_window != null:
		company_window.add_theme_constant_override("margin_left", 0)
		company_window.add_theme_constant_override("margin_top", 0)
		company_window.add_theme_constant_override("margin_right", 0)
		company_window.add_theme_constant_override("margin_bottom", 0)
		_attach_content_full_rect(company_window)
	upgrade_window.add_theme_constant_override("margin_left", 0)
	upgrade_window.add_theme_constant_override("margin_top", 0)
	upgrade_window.add_theme_constant_override("margin_right", 0)
	upgrade_window.add_theme_constant_override("margin_bottom", 0)
	_attach_content_full_rect(news_window)
	_attach_content_full_rect(social_window)
	_attach_content_full_rect(network_window)
	_attach_content_full_rect(upgrade_window)

	for app_id_value in desktop_app_windows.keys():
		var app_id: String = str(app_id_value)
		var meta: Dictionary = desktop_app_windows.get(app_id, {})
		var window: Control = meta.get("window", null) as Control
		if window == null:
			continue
		window.custom_minimum_size = _desktop_window_min_size_for_app(app_id)
		if bool(meta.get("rect_initialized", false)):
			_clamp_desktop_window_to_viewport(app_id)


func _attach_content_full_rect(content_node: Control) -> void:
	if content_node == null:
		return
	content_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_node.offset_left = 0
	content_node.offset_top = 0
	content_node.offset_right = 0
	content_node.offset_bottom = 0


func _create_ui_tween() -> Tween:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	return tween


func _center_control_pivot(control: Control) -> void:
	if control == null:
		return
	if control.size.x > 0.0 and control.size.y > 0.0:
		control.pivot_offset = control.size * 0.5


func _reset_control_animation_state(control: Control) -> void:
	if control == null:
		return
	control.scale = Vector2.ONE
	control.modulate = Color.WHITE


func _open_desktop_app_window(app_id: String) -> void:
	var meta: Dictionary = desktop_app_windows.get(app_id, {})
	if meta.is_empty():
		return
	if not bool(meta.get("rect_initialized", false)):
		_set_desktop_window_rect(app_id, _desktop_window_initial_rect(app_id))
		meta["rect_initialized"] = true
		desktop_app_windows[app_id] = meta
	var window: Control = meta.get("window", null) as Control
	if window == null:
		return
	var was_visible: bool = window.visible
	window.visible = true
	_focus_desktop_app_window(app_id)
	if not was_visible:
		_play_desktop_window_open_animation(app_id)


func _focus_desktop_app_window(app_id: String) -> void:
	var meta: Dictionary = desktop_app_windows.get(app_id, {})
	if meta.is_empty():
		return
	var window: Control = meta.get("window", null) as Control
	if window == null:
		return
	if window.get_parent() == desktop_window_layer:
		desktop_window_layer.move_child(window, desktop_window_layer.get_child_count() - 1)
	active_app_id = app_id
	_mark_desktop_app_seen_if_needed(app_id)
	if deferred_open_app_refresh_queue.has(app_id) and not advance_day_processing and pending_daily_recap_snapshot.is_empty() and not _is_daily_recap_visible():
		_remove_deferred_open_app_refresh(app_id)
		_refresh_app_window_content(app_id)
	_refresh_desktop_window_themes()
	_refresh_desktop()
	_play_desktop_window_focus_animation(app_id)
	_refresh_ftue_progress()
	_refresh_first_hour_guide_progress()


func _close_desktop_app_window(app_id: String) -> void:
	var meta: Dictionary = desktop_app_windows.get(app_id, {})
	if meta.is_empty():
		return
	var window: Control = meta.get("window", null) as Control
	if window == null:
		return
	_reset_desktop_window_animation_state(app_id)
	window.visible = false
	if desktop_dragging_app_id == app_id:
		desktop_dragging_app_id = ""
	if active_app_id == app_id:
		active_app_id = _top_visible_desktop_window_id()
		if active_app_id.is_empty():
			active_app_id = APP_ID_DESKTOP
	if active_app_id == APP_ID_DESKTOP:
		_refresh_pending_dashboard_after_guarded_advance()
	_refresh_desktop_window_themes()
	_refresh_desktop()
	_refresh_ftue_progress()
	_refresh_first_hour_guide_progress()


func _play_desktop_window_open_animation(app_id: String) -> void:
	var meta: Dictionary = desktop_app_windows.get(app_id, {})
	var window: Control = meta.get("window", null) as Control
	if window == null:
		return
	_stop_desktop_window_tween(desktop_window_open_tweens, app_id)
	_center_control_pivot(window)
	if not UI_ANIMATIONS_ENABLED:
		_reset_control_animation_state(window)
		return
	window.scale = Vector2(0.985, 0.985)
	window.modulate = Color(1, 1, 1, 0)
	var tween := _create_ui_tween()
	tween.set_parallel(true)
	desktop_window_open_tweens[app_id] = tween
	tween.tween_property(window, "scale", Vector2.ONE, UI_DESKTOP_WINDOW_OPEN_SECONDS)
	tween.tween_property(window, "modulate", Color.WHITE, UI_DESKTOP_WINDOW_OPEN_SECONDS)
	tween.finished.connect(func() -> void:
		desktop_window_open_tweens.erase(app_id)
	)


func _play_desktop_window_focus_animation(app_id: String) -> void:
	var meta: Dictionary = desktop_app_windows.get(app_id, {})
	var title_bar: Control = meta.get("title_bar", null) as Control
	if title_bar == null:
		return
	_stop_desktop_window_tween(desktop_window_focus_tweens, app_id)
	if not UI_ANIMATIONS_ENABLED:
		title_bar.modulate = Color.WHITE
		return
	title_bar.modulate = Color(1.08, 1.08, 1.08, 1)
	var tween := _create_ui_tween()
	desktop_window_focus_tweens[app_id] = tween
	tween.tween_property(title_bar, "modulate", Color.WHITE, UI_DESKTOP_WINDOW_FOCUS_SECONDS)
	tween.finished.connect(func() -> void:
		desktop_window_focus_tweens.erase(app_id)
	)


func _stop_desktop_window_tween(tweens: Dictionary, app_id: String) -> void:
	var tween: Tween = tweens.get(app_id, null) as Tween
	if tween != null:
		tween.kill()
	tweens.erase(app_id)


func _reset_desktop_window_animation_state(app_id: String) -> void:
	var meta: Dictionary = desktop_app_windows.get(app_id, {})
	if meta.is_empty():
		return
	_stop_desktop_window_tween(desktop_window_open_tweens, app_id)
	_stop_desktop_window_tween(desktop_window_focus_tweens, app_id)
	var window: Control = meta.get("window", null) as Control
	_reset_control_animation_state(window)
	var title_bar: Control = meta.get("title_bar", null) as Control
	if title_bar != null:
		title_bar.modulate = Color.WHITE


func _top_visible_desktop_window_id() -> String:
	if desktop_window_layer == null:
		return ""
	for child_index in range(desktop_window_layer.get_child_count() - 1, -1, -1):
		var child: Control = desktop_window_layer.get_child(child_index) as Control
		if child == null or not child.visible:
			continue
		for app_id_value in desktop_app_windows.keys():
			var app_id: String = str(app_id_value)
			var meta: Dictionary = desktop_app_windows.get(app_id, {})
			if meta.get("window", null) == child:
				return app_id
	return ""


func _clamp_desktop_rect_to_work_area(app_id: String, rect: Rect2) -> Rect2:
	var work_rect: Rect2 = _desktop_window_work_rect()
	var min_size: Vector2 = _desktop_window_min_size_for_app(app_id)
	var effective_min_size := Vector2(
		min(min_size.x, max(work_rect.size.x, 240.0)),
		min(min_size.y, max(work_rect.size.y, 180.0))
	)
	var clamped_size := rect.size
	clamped_size.x = clamp(clamped_size.x, effective_min_size.x, max(work_rect.size.x, effective_min_size.x))
	clamped_size.y = clamp(clamped_size.y, effective_min_size.y, max(work_rect.size.y, effective_min_size.y))
	var clamped_position := Vector2(
		clamp(rect.position.x, work_rect.position.x, max(work_rect.position.x + work_rect.size.x - clamped_size.x, work_rect.position.x)),
		clamp(rect.position.y, work_rect.position.y, max(work_rect.position.y + work_rect.size.y - clamped_size.y, work_rect.position.y))
	)
	return Rect2(clamped_position, clamped_size)


func _set_desktop_window_rect(app_id: String, rect: Rect2) -> void:
	var meta: Dictionary = desktop_app_windows.get(app_id, {})
	if meta.is_empty():
		return
	var window: Control = meta.get("window", null) as Control
	if window == null:
		return
	var clamped_rect: Rect2 = _clamp_desktop_rect_to_work_area(app_id, rect)
	window.position = clamped_rect.position
	window.size = clamped_rect.size


func _clamp_desktop_window_to_viewport(app_id: String) -> void:
	var meta: Dictionary = desktop_app_windows.get(app_id, {})
	if meta.is_empty():
		return
	var window: Control = meta.get("window", null) as Control
	if window == null:
		return
	_set_desktop_window_rect(app_id, Rect2(window.position, window.size))


func _window_fill_color_for_app(app_id: String) -> Color:
	if app_id == APP_ID_STOCK:
		return COLOR_STOCK_WINDOW_BG
	if app_id == APP_ID_THESIS or app_id == APP_ID_LIFE:
		return COLOR_ACADEMY_CREAM
	if _uses_academy_window_chrome(app_id):
		return COLOR_ACADEMY_BROWN
	if app_id == APP_ID_SOCIAL:
		return Color(0.94902, 0.956863, 0.976471, 1)
	return COLOR_WINDOW_BG


func _window_text_color_for_app(app_id: String) -> Color:
	if _uses_desktop_brown_window_frame(app_id):
		return COLOR_DESKTOP_CREAM
	return COLOR_TEXT if app_id == APP_ID_STOCK else COLOR_WINDOW_TEXT


func _desktop_window_frame_inset_for_app(app_id: String) -> int:
	return 2 if _uses_desktop_brown_window_frame(app_id) else 0


func _uses_desktop_brown_window_frame(app_id: String) -> bool:
	return _uses_academy_window_chrome(app_id)


func _uses_academy_window_chrome(app_id: String) -> bool:
	return (
		app_id == APP_ID_ACADEMY or
		app_id == APP_ID_THESIS or
		app_id == APP_ID_LIFE or
		app_id == APP_ID_COMPANY or
		app_id == APP_ID_NEWS or
		app_id == APP_ID_NETWORK or
		app_id == APP_ID_UPGRADES
	)


func _refresh_desktop_window_themes() -> void:
	for app_id_value in desktop_app_windows.keys():
		var app_id: String = str(app_id_value)
		var meta: Dictionary = desktop_app_windows.get(app_id, {})
		if meta.is_empty():
			continue
		var frame: PanelContainer = meta.get("frame", null) as PanelContainer
		var title_bar: PanelContainer = meta.get("title_bar", null) as PanelContainer
		var title_label: Label = meta.get("title_label", null) as Label
		var minimize_button: Button = meta.get("minimize_button", null) as Button
		var close_button: Button = meta.get("close_button", null) as Button
		if frame == null or title_bar == null or title_label == null or minimize_button == null or close_button == null:
			continue
		var fill_color: Color = _window_fill_color_for_app(app_id)
		var text_color: Color = _window_text_color_for_app(app_id)
		var is_active: bool = active_app_id == app_id
		var use_brown_frame: bool = _uses_desktop_brown_window_frame(app_id)
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = fill_color
		frame_style.border_color = COLOR_DESKTOP_BROWN if use_brown_frame else (COLOR_ACCENT if is_active else COLOR_BORDER)
		frame_style.set_border_width_all(2 if use_brown_frame or is_active else 1)
		frame_style.corner_radius_top_left = 8
		frame_style.corner_radius_top_right = 8
		frame_style.corner_radius_bottom_left = 8
		frame_style.corner_radius_bottom_right = 8
		frame.add_theme_stylebox_override("panel", frame_style)
		var title_fill: Color = COLOR_DESKTOP_BROWN if use_brown_frame else (fill_color.lightened(0.04) if text_color == COLOR_WINDOW_TEXT else fill_color)
		var title_border: Color = COLOR_DESKTOP_BROWN if use_brown_frame else COLOR_BORDER
		var title_border_width: int = 0 if use_brown_frame else 1
		_style_window_title_bar(title_bar, title_fill, title_border, title_border_width)
		title_label.add_theme_color_override("font_color", text_color)
		title_label.add_theme_font_size_override("font_size", STOCK_APP_FONT_SIZE if app_id == APP_ID_STOCK else DEFAULT_APP_FONT_SIZE)
		_style_button(minimize_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
		_style_button(close_button, Color(0.368627, 0.160784, 0.176471, 1), Color(0.709804, 0.34902, 0.372549, 1), COLOR_TEXT, 0)


func _is_desktop_app_window_open(app_id: String) -> bool:
	var meta: Dictionary = desktop_app_windows.get(app_id, {})
	if meta.is_empty():
		return active_app_id == app_id
	var window: Control = meta.get("window", null) as Control
	return window != null and window.visible


func is_desktop_app_open(app_id: String) -> bool:
	return _is_desktop_app_window_open(app_id.to_lower())


func get_active_desktop_app_id() -> String:
	return active_app_id


func get_desktop_app_window_title(app_id: String) -> String:
	var meta: Dictionary = desktop_app_windows.get(app_id.to_lower(), {})
	if meta.is_empty():
		return ""
	var title_label: Label = meta.get("title_label", null) as Label
	return title_label.text if title_label != null else ""


func close_desktop_app(app_id: String) -> void:
	_close_desktop_app_window(app_id.to_lower())


func is_rupslb_meeting_overlay_visible() -> bool:
	return rupslb_meeting_overlay != null and rupslb_meeting_overlay.visible


func get_rupslb_meeting_stage_id() -> String:
	if rupslb_meeting_overlay == null or not rupslb_meeting_overlay.has_method("get_current_stage_id"):
		return ""
	return str(rupslb_meeting_overlay.call("get_current_stage_id"))


func _desktop_window_id_at_position(mouse_position: Vector2) -> String:
	if desktop_window_layer == null:
		return ""
	for child_index in range(desktop_window_layer.get_child_count() - 1, -1, -1):
		var child: Control = desktop_window_layer.get_child(child_index) as Control
		if child == null or not child.visible:
			continue
		if child.get_global_rect().has_point(mouse_position):
			for app_id_value in desktop_app_windows.keys():
				var app_id: String = str(app_id_value)
				var meta: Dictionary = desktop_app_windows.get(app_id, {})
				if meta.get("window", null) == child:
					return app_id
	return ""


func _on_desktop_window_drag_handle_gui_input(event: InputEvent, app_id: String) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			var meta: Dictionary = desktop_app_windows.get(app_id, {})
			var window: Control = meta.get("window", null) as Control
			if window == null:
				return
			_focus_desktop_app_window(app_id)
			desktop_dragging_app_id = app_id
			desktop_drag_offset = mouse_button.global_position - window.global_position
			get_viewport().set_input_as_handled()


func _update_desktop_window_drag(mouse_position: Vector2) -> void:
	if desktop_dragging_app_id.is_empty():
		return
	var meta: Dictionary = desktop_app_windows.get(desktop_dragging_app_id, {})
	if meta.is_empty():
		return
	var window: Control = meta.get("window", null) as Control
	if window == null:
		return
	var next_rect := Rect2(mouse_position - desktop_drag_offset, window.size)
	_set_desktop_window_rect(desktop_dragging_app_id, next_rect)


func _on_desktop_window_minimize_pressed(app_id: String) -> void:
	_close_desktop_app_window(app_id)


func _on_desktop_window_close_pressed(app_id: String) -> void:
	_close_desktop_app_window(app_id)


func _refresh_app_window_content(app_id: String) -> void:
	if app_id == APP_ID_STOCK:
		_refresh_markets()
		call_deferred("_update_responsive_layout")
	elif app_id == APP_ID_NEWS:
		_refresh_news()
	elif app_id == APP_ID_SOCIAL:
		_refresh_social()
	elif app_id == APP_ID_NETWORK:
		_refresh_network()
	elif app_id == APP_ID_ACADEMY:
		_refresh_academy()
	elif app_id == APP_ID_THESIS:
		_refresh_thesis()
	elif app_id == APP_ID_LIFE:
		_refresh_life()
	elif app_id == APP_ID_COMPANY:
		_refresh_company()
	elif app_id == APP_ID_UPGRADES:
		_refresh_upgrades()


func _ensure_thesis_ui() -> void:
	if thesis_window != null:
		return

	var desktop_icons_row: HBoxContainer = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow
	var thesis_tile := VBoxContainer.new()
	thesis_tile.name = "ThesisAppTile"
	thesis_tile.add_theme_constant_override("separation", 10)
	desktop_icons_row.add_child(thesis_tile)
	var upgrades_tile: Node = desktop_icons_row.get_node_or_null("UpgradesAppTile")
	if upgrades_tile != null:
		desktop_icons_row.move_child(thesis_tile, upgrades_tile.get_index())

	thesis_app_button = Button.new()
	thesis_app_button.name = "ThesisAppButton"
	thesis_app_button.custom_minimum_size = Vector2(92, 92)
	thesis_app_button.toggle_mode = true
	thesis_tile.add_child(thesis_app_button)

	thesis_app_label = Label.new()
	thesis_app_label.name = "ThesisAppLabel"
	thesis_app_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thesis_app_label.text = "Thesis"
	thesis_app_label.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)
	thesis_tile.add_child(thesis_app_label)

	thesis_window = THESIS_BOARD_WIDGET_SCRIPT.new()
	thesis_window.name = "ThesisWindow"
	thesis_window.visible = false
	thesis_window.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(thesis_window)
	var upgrade_window_node: Node = get_node_or_null("UpgradeWindow")
	if upgrade_window_node != null:
		move_child(thesis_window, upgrade_window_node.get_index())


func _refresh_thesis() -> void:
	if thesis_window == null:
		return
	if thesis_window.has_method("set_selected_company_id"):
		thesis_window.call("set_selected_company_id", selected_company_id)
	if thesis_window.has_method("refresh"):
		thesis_window.call("refresh")
	_bind_thesis_guide_controls()


func _ensure_life_ui() -> void:
	_ensure_life_controller()
	life_controller.ensure_ui()


func _refresh_life() -> void:
	_ensure_life_controller()
	life_controller.refresh()


func _style_life_news_tabs() -> void:
	_ensure_life_controller()
	life_controller.style_tabs()


func _ensure_company_ui() -> void:
	_ensure_company_controller()
	company_controller.ensure_ui()


func _refresh_company_app_availability() -> void:
	_ensure_company_controller()
	company_controller.refresh_app_availability()


func _refresh_company(preferred_company_id: String = "") -> void:
	_ensure_company_controller()
	company_controller.refresh(preferred_company_id)


func _company_management_detail_text(controlled_rows: Array, candidate_rows: Array, selected_company_management_id: String, selected_options: Dictionary) -> String:
	_ensure_company_controller()
	return company_controller.company_management_detail_text(controlled_rows, candidate_rows, selected_company_management_id, selected_options)


func _selected_company_management_company_id() -> String:
	_ensure_company_controller()
	return company_controller.selected_company_id()


func _selected_company_management_action_id() -> String:
	_ensure_company_controller()
	return company_controller.selected_action_id()


func _ensure_academy_controller() -> void:
	if academy_controller != null:
		return
	academy_controller = ACADEMY_CONTROLLER_SCRIPT.new()
	academy_controller.setup(self)


func _ensure_academy_ui() -> void:
	_ensure_academy_controller()
	academy_controller.ensure_ui()


func _refresh_academy() -> void:
	_ensure_academy_controller()
	academy_controller.refresh()


func _apply_academy_text_theme() -> void:
	_ensure_academy_controller()
	academy_controller.apply_text_theme()


func _restyle_academy_controls() -> void:
	_ensure_academy_controller()
	academy_controller.restyle_controls()


func _refresh_academy_glossary_results() -> void:
	_ensure_academy_controller()
	academy_controller.refresh_glossary_results()


func _next_academy_section_id() -> String:
	_ensure_academy_controller()
	return academy_controller.next_section_id()


func _build_academy_content_block(block: Dictionary) -> Control:
	_ensure_academy_controller()
	return academy_controller.call("_build_academy_content_block", block) as Control


func _style_academy_quiz_option_button(option_button: OptionButton) -> void:
	_ensure_academy_controller()
	academy_controller.call("_style_academy_quiz_option_button", option_button)


func _style_academy_quiz_submit_button(button: Button) -> void:
	_ensure_academy_controller()
	academy_controller.call("_style_academy_quiz_submit_button", button)


func _refresh_upgrades() -> void:
	_ensure_upgrades_controller()
	upgrades_controller.refresh()


func _cache_order_market_summary_labels() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._cache_order_market_summary_labels()
	stock_controller._sync_root_refs()
func _bind_order_market_capture_labels() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._bind_order_market_capture_labels()
	stock_controller._sync_root_refs()
func _style_order_market_summary_labels() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._style_order_market_summary_labels()
	stock_controller._sync_root_refs()
func _style_order_ticker_badge() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._style_order_ticker_badge()
	stock_controller._sync_root_refs()
func _refresh_order_market_summary(snapshot: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_order_market_summary(snapshot)
	stock_controller._sync_root_refs()
func _set_order_market_value(key: String, text: String, tone: Color) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._set_order_market_value(key, text, tone)
	stock_controller._sync_root_refs()
func _on_trade_quote_label_gui_input(event: InputEvent, quote_key: String) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_trade_quote_label_gui_input(event, quote_key)
	stock_controller._sync_root_refs()
func _trade_quote_capture_payload(quote_key: String) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._trade_quote_capture_payload(quote_key)
	stock_controller._sync_root_refs()
	return result
func _trade_quote_label(quote_key: String) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._trade_quote_label(quote_key)
	stock_controller._sync_root_refs()
	return result
func _trade_quote_impact(quote_key: String, value_text: String) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._trade_quote_impact(quote_key, value_text)
	stock_controller._sync_root_refs()
	return result
func _show_trade_quote_capture_menu(menu_position: Vector2) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._show_trade_quote_capture_menu(menu_position)
	stock_controller._sync_root_refs()
func _on_trade_quote_capture_menu_id_pressed(id: int) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_trade_quote_capture_menu_id_pressed(id)
	stock_controller._sync_root_refs()
func _broker_type_side_value(broker_flow: Dictionary, broker_type: String, side: String) -> float:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: float = stock_controller._broker_type_side_value(broker_flow, broker_type, side)
	stock_controller._sync_root_refs()
	return result
func _latest_price_bar(snapshot: Dictionary) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._latest_price_bar(snapshot)
	stock_controller._sync_root_refs()
	return result
func _broker_side_value_by_type(rows: Array, broker_type: String, value_key: String) -> float:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: float = stock_controller._broker_side_value_by_type(rows, broker_type, value_key)
	stock_controller._sync_root_refs()
	return result
func _format_quote_price(value: float) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_quote_price(value)
	stock_controller._sync_root_refs()
	return result
func _format_signed_quote_delta(value: float) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_signed_quote_delta(value)
	stock_controller._sync_root_refs()
	return result
func _refresh_network_journal_filter_buttons() -> void:
	_ensure_network_controller()
	network_controller.refresh_journal_filter_buttons()


func _ensure_network_context_ui() -> void:
	_ensure_network_controller()
	network_controller.ensure_context_ui()


func _ensure_network_detail_scroll() -> void:
	_ensure_network_controller()
	network_controller.ensure_detail_scroll()


func _contact_for_context(source_type: String, source_id: String, company_id: String) -> Dictionary:
	current_network_snapshot = GameManager.get_network_snapshot()
	var rows: Array = []
	rows.append_array(current_network_snapshot.get("discoveries", []))
	rows.append_array(current_network_snapshot.get("contacts", []))
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("lead_score", 0)) > int(b.get("lead_score", 0))
	)
	for row_value in rows:
		var row: Dictionary = row_value
		if bool(row.get("met", false)):
			continue
		if not source_id.is_empty() and str(row.get("source_id", "")) == source_id and str(row.get("source_type", "")) == source_type:
			return row
	for row_value in rows:
		var row: Dictionary = row_value
		if bool(row.get("met", false)):
			continue
		if not company_id.is_empty() and str(row.get("target_company_id", "")) == company_id:
			return row
		if not company_id.is_empty() and company_id in row.get("target_company_ids", []):
			return row
	return {}


func _filtered_social_posts(posts: Array) -> Array:
	_ensure_social_controller()
	return social_controller._filtered_social_posts(posts)

func _filtered_social_posts_by_feed_filter(posts: Array) -> Array:
	_ensure_social_controller()
	return social_controller._filtered_social_posts_by_feed_filter(posts)

func _social_post_matches_feed_filter(post: Dictionary, filter_id: String) -> bool:
	_ensure_social_controller()
	return social_controller._social_post_matches_feed_filter(post, filter_id)

func _social_feed_filters_for_posts(_posts: Array) -> Array:
	_ensure_social_controller()
	return social_controller._social_feed_filters_for_posts(_posts)

func _following_social_account_lookup() -> Dictionary:
	_ensure_social_controller()
	return social_controller._following_social_account_lookup()

func _social_account_from_snapshot(account_id: String) -> Dictionary:
	_ensure_social_controller()
	return social_controller._social_account_from_snapshot(account_id)

func _social_post_is_company(post: Dictionary) -> bool:
	_ensure_social_controller()
	return social_controller._social_post_is_company(post)

func _social_post_is_sector(post: Dictionary) -> bool:
	_ensure_social_controller()
	return social_controller._social_post_is_sector(post)

func _social_post_engagement_score(post: Dictionary) -> int:
	_ensure_social_controller()
	return social_controller._social_post_engagement_score(post)

func _social_feed_filter_label(filter_id: String) -> String:
	_ensure_social_controller()
	return social_controller._social_feed_filter_label(filter_id)

func _count_social_posts_for_filter(posts: Array, filter_id: String) -> int:
	_ensure_social_controller()
	return social_controller._count_social_posts_for_filter(posts, filter_id)

func _selected_social_account_name(posts: Array) -> String:
	_ensure_social_controller()
	return social_controller._selected_social_account_name(posts)

func _refresh_social_tier_indicator(_access_tier: int) -> void:
	_ensure_social_controller()
	social_controller._refresh_social_tier_indicator(_access_tier)

func _on_social_nav_pressed(view_id: String) -> void:
	_ensure_social_controller()
	social_controller._on_social_nav_pressed(view_id)

func _should_clear_social_message_selection_on_nav() -> bool:
	_ensure_social_controller()
	return social_controller._should_clear_social_message_selection_on_nav()

func _apply_social_view_visibility() -> void:
	_ensure_social_controller()
	social_controller._apply_social_view_visibility()

func _rebuild_social_right_rail(snapshot: Dictionary) -> void:
	_ensure_social_controller()
	social_controller._rebuild_social_right_rail(snapshot)

func _rebuild_social_account_search_results(snapshot: Dictionary) -> void:
	_ensure_social_controller()
	social_controller._rebuild_social_account_search_results(snapshot)

func _social_account_matches_name_search(account: Dictionary, query: String) -> bool:
	_ensure_social_controller()
	return social_controller._social_account_matches_name_search(account, query)

func _social_font_size(base_size: int) -> int:
	_ensure_social_controller()
	return social_controller._social_font_size(base_size)

func _build_social_account_search_result(account: Dictionary) -> Button:
	_ensure_social_controller()
	return social_controller._build_social_account_search_result(account)

func _on_social_account_search_changed(_new_text: String) -> void:
	_ensure_social_controller()
	social_controller._on_social_account_search_changed(_new_text)

func _on_social_account_search_submitted(_new_text: String) -> void:
	_ensure_social_controller()
	social_controller._on_social_account_search_submitted(_new_text)

func _build_social_trending_row(row: Dictionary) -> VBoxContainer:
	_ensure_social_controller()
	return social_controller._build_social_trending_row(row)

func _build_social_follow_row(row: Dictionary) -> HBoxContainer:
	_ensure_social_controller()
	return social_controller._build_social_follow_row(row)

func _on_social_follow_row_gui_input(event: InputEvent, account_id: String) -> void:
	_ensure_social_controller()
	social_controller._on_social_follow_row_gui_input(event, account_id)

func _on_social_follow_pressed(account_id: String) -> void:
	_ensure_social_controller()
	social_controller._on_social_follow_pressed(account_id)

func _rebuild_social_message_view(snapshot: Dictionary) -> void:
	_ensure_social_controller()
	social_controller._rebuild_social_message_view(snapshot)

func _add_social_message_header(title_text: String, subtitle_text: String) -> void:
	_ensure_social_controller()
	social_controller._add_social_message_header(title_text, subtitle_text)

func _hydrate_social_message_composer(account_id: String, options: Array) -> void:
	_ensure_social_controller()
	social_controller._hydrate_social_message_composer(account_id, options)

func _reset_social_message_composer(show_composer: bool) -> void:
	_ensure_social_controller()
	social_controller._reset_social_message_composer(show_composer)

func _on_social_message_option_selected(option_index: int) -> void:
	_ensure_social_controller()
	social_controller._on_social_message_option_selected(option_index)

func _start_social_message_typewriter(text: String) -> void:
	_ensure_social_controller()
	social_controller._start_social_message_typewriter(text)

func _is_smoke_test_runtime() -> bool:
	_ensure_social_controller()
	return social_controller._is_smoke_test_runtime()

func _send_social_message_composer() -> void:
	_ensure_social_controller()
	social_controller._send_social_message_composer()

func _scroll_social_message_rows_to_bottom() -> void:
	_ensure_social_controller()
	social_controller._scroll_social_message_rows_to_bottom()

func _build_social_message_thread_button(row: Dictionary) -> Button:
	_ensure_social_controller()
	return social_controller._build_social_message_thread_button(row)

func _on_social_message_thread_pressed(account_id: String) -> void:
	_ensure_social_controller()
	social_controller._on_social_message_thread_pressed(account_id)

func _build_social_message_bubble(row: Dictionary) -> PanelContainer:
	_ensure_social_controller()
	return social_controller._build_social_message_bubble(row)

func _build_social_message_action_button(account_id: String, action_id: String, label: String, thesis_id: String) -> Button:
	_ensure_social_controller()
	return social_controller._build_social_message_action_button(account_id, action_id, label, thesis_id)

func _on_social_message_action_pressed(account_id: String, action_id: String, thesis_id: String = "", player_message_text: String = "") -> void:
	_ensure_social_controller()
	social_controller._on_social_message_action_pressed(account_id, action_id, thesis_id, player_message_text)

func _on_social_post_capture_gui_input(event: InputEvent, post: Dictionary) -> void:
	_ensure_social_controller()
	social_controller._on_social_post_capture_gui_input(event, post)

func _on_social_dm_capture_gui_input(event: InputEvent, row: Dictionary, account_id: String) -> void:
	_ensure_social_controller()
	social_controller._on_social_dm_capture_gui_input(event, row, account_id)

func _social_post_capture_payload(post: Dictionary) -> Dictionary:
	_ensure_social_controller()
	return social_controller._social_post_capture_payload(post)

func _social_dm_capture_payload(row: Dictionary, account_id: String) -> Dictionary:
	_ensure_social_controller()
	return social_controller._social_dm_capture_payload(row, account_id)

func _social_target_company_id(source: Dictionary, account_id: String = "") -> String:
	_ensure_social_controller()
	return social_controller._social_target_company_id(source, account_id)

func _social_account_for_id(account_id: String) -> Dictionary:
	_ensure_social_controller()
	return social_controller._social_account_for_id(account_id)

func _social_tone_to_impact(tone: String) -> String:
	_ensure_social_controller()
	return social_controller._social_tone_to_impact(tone)

func _company_id_for_ticker(ticker: String) -> String:
	_ensure_social_controller()
	return social_controller._company_id_for_ticker(ticker)

func _show_social_capture_menu(menu_position: Vector2) -> void:
	_ensure_social_controller()
	social_controller._show_social_capture_menu(menu_position)

func _on_social_capture_menu_id_pressed(id: int) -> void:
	_ensure_social_controller()
	social_controller._on_social_capture_menu_id_pressed(id)

func _make_social_rail_body_label(text: String) -> Label:
	_ensure_social_controller()
	return social_controller._make_social_rail_body_label(text)

func _clear_container(container: Container) -> void:
	_ensure_social_controller()
	social_controller._clear_container(container)

func _rebuild_social_filter_chips(posts: Array) -> void:
	_ensure_social_controller()
	social_controller._rebuild_social_filter_chips(posts)

func _on_social_feed_filter_pressed(filter_id: String) -> void:
	_ensure_social_controller()
	social_controller._on_social_feed_filter_pressed(filter_id)

func _rebuild_social_ticker_tape(visible_posts: Array, all_posts: Array) -> void:
	_ensure_social_controller()
	social_controller._rebuild_social_ticker_tape(visible_posts, all_posts)

func _social_ticker_rows_from_posts(posts: Array) -> Array:
	_ensure_social_controller()
	return social_controller._social_ticker_rows_from_posts(posts)

func _build_social_ticker_chip(row: Dictionary) -> PanelContainer:
	_ensure_social_controller()
	return social_controller._build_social_ticker_chip(row)

func _rebuild_social_feed_cards(posts: Array) -> void:
	_ensure_social_controller()
	social_controller._rebuild_social_feed_cards(posts)

func _build_social_account_filter_nav_row() -> HBoxContainer:
	_ensure_social_controller()
	return social_controller._build_social_account_filter_nav_row()

func _build_social_account_filter_card(account_name: String, account_id: String) -> PanelContainer:
	_ensure_social_controller()
	return social_controller._build_social_account_filter_card(account_name, account_id)

func _build_social_profile_stat_chip(label_text: String, value: int) -> PanelContainer:
	_ensure_social_controller()
	return social_controller._build_social_profile_stat_chip(label_text, value)

func _make_social_profile_body_label(text: String) -> Label:
	_ensure_social_controller()
	return social_controller._make_social_profile_body_label(text)

func _social_stage_label(stage_id: String) -> String:
	_ensure_social_controller()
	return social_controller._social_stage_label(stage_id)

func _social_account_description_text(account: Dictionary) -> String:
	_ensure_social_controller()
	return social_controller._social_account_description_text(account)

func _social_account_next_step_text(account: Dictionary) -> String:
	_ensure_social_controller()
	return social_controller._social_account_next_step_text(account)

func _social_account_memory_text(account: Dictionary) -> String:
	_ensure_social_controller()
	return social_controller._social_account_memory_text(account)

func _social_action_label(action_id: String) -> String:
	_ensure_social_controller()
	return social_controller._social_action_label(action_id)

func _build_social_empty_card() -> PanelContainer:
	_ensure_social_controller()
	return social_controller._build_social_empty_card()

func _build_social_post_card(post: Dictionary) -> PanelContainer:
	_ensure_social_controller()
	return social_controller._build_social_post_card(post)

func _build_social_tag_chip(text: String, tone: String) -> PanelContainer:
	_ensure_social_controller()
	return social_controller._build_social_tag_chip(text, tone)

func _build_social_engagement_label(label_text: String, value: int) -> Label:
	_ensure_social_controller()
	return social_controller._build_social_engagement_label(label_text, value)

func _build_social_like_button(post: Dictionary) -> Button:
	_ensure_social_controller()
	return social_controller._build_social_like_button(post)

func _build_social_reply_row(reply: Dictionary) -> PanelContainer:
	_ensure_social_controller()
	return social_controller._build_social_reply_row(reply)

func _build_social_reply_bubble(sender_label: String, body_text: String, is_player: bool) -> PanelContainer:
	_ensure_social_controller()
	return social_controller._build_social_reply_bubble(sender_label, body_text, is_player)

func _clean_social_account_reply_text(raw_text: String) -> String:
	_ensure_social_controller()
	return social_controller._clean_social_account_reply_text(raw_text)

func _build_social_conclusion_row(post: Dictionary) -> PanelContainer:
	_ensure_social_controller()
	return social_controller._build_social_conclusion_row(post)

func _social_dialog_cooldown_text(reason: String) -> String:
	_ensure_social_controller()
	return social_controller._social_dialog_cooldown_text(reason)

func _on_social_post_action_pressed(post_id: String, action_id: String, thesis_id: String = "", player_reply_text: String = "") -> void:
	_ensure_social_controller()
	social_controller._on_social_post_action_pressed(post_id, action_id, thesis_id, player_reply_text)

func _on_social_post_like_pressed(post_id: String) -> void:
	_ensure_social_controller()
	social_controller._on_social_post_like_pressed(post_id)

func _ensure_social_reply_composer_dialog() -> void:
	_ensure_social_controller()
	social_controller._ensure_social_reply_composer_dialog()

func _open_social_reply_composer(post: Dictionary) -> void:
	_ensure_social_controller()
	social_controller._open_social_reply_composer(post)

func _on_social_reply_option_selected(option_index: int) -> void:
	_ensure_social_controller()
	social_controller._on_social_reply_option_selected(option_index)

func _start_social_reply_typewriter(text: String) -> void:
	_ensure_social_controller()
	social_controller._start_social_reply_typewriter(text)

func _send_social_reply_composer() -> void:
	_ensure_social_controller()
	social_controller._send_social_reply_composer()

func _hide_social_reply_composer() -> void:
	_ensure_social_controller()
	social_controller._hide_social_reply_composer()

func _social_category_label(post: Dictionary) -> String:
	_ensure_social_controller()
	return social_controller._social_category_label(post)

func _build_social_avatar(post: Dictionary) -> PanelContainer:
	_ensure_social_controller()
	return social_controller._build_social_avatar(post)

func _social_avatar_initial(post: Dictionary) -> String:
	_ensure_social_controller()
	return social_controller._social_avatar_initial(post)

func _social_avatar_color(seed_value: String) -> Color:
	_ensure_social_controller()
	return social_controller._social_avatar_color(seed_value)

func _build_social_card_meta_line(post: Dictionary) -> String:
	_ensure_social_controller()
	return social_controller._build_social_card_meta_line(post)

func _on_social_account_pressed(account_id: String) -> void:
	_ensure_social_controller()
	social_controller._on_social_account_pressed(account_id)

func _on_social_account_filter_cleared() -> void:
	_ensure_social_controller()
	social_controller._on_social_account_filter_cleared()

func _on_social_start_message_pressed(account_id: String) -> void:
	_ensure_social_controller()
	social_controller._on_social_start_message_pressed(account_id)

func _on_social_thread_toggled(post_id: String, thread_container: VBoxContainer, thread_button: Button) -> void:
	_ensure_social_controller()
	social_controller._on_social_thread_toggled(post_id, thread_container, thread_button)

func _style_social_post_card(panel: PanelContainer, _tone: String) -> void:
	_ensure_social_controller()
	social_controller._style_social_post_card(panel, _tone)

func _social_card_border_color(_tone: String) -> Color:
	_ensure_social_controller()
	return social_controller._social_card_border_color(_tone)

func _style_twooter_ui() -> void:
	_ensure_social_controller()
	social_controller._style_twooter_ui()

func _style_twooter_panel(panel: PanelContainer, fill_color: Color, border_color: Color, radius: int = 6, border_width: int = 1) -> void:
	_ensure_social_controller()
	social_controller._style_twooter_panel(panel, fill_color, border_color, radius, border_width)

func _style_social_ticker_chip(panel: PanelContainer, _tone: String) -> void:
	_ensure_social_controller()
	social_controller._style_social_ticker_chip(panel, _tone)

func _style_social_tag_chip(panel: PanelContainer, tone: String) -> void:
	_ensure_social_controller()
	social_controller._style_social_tag_chip(panel, tone)

func _social_tag_font_color(tone: String) -> Color:
	_ensure_social_controller()
	return social_controller._social_tag_font_color(tone)

func _style_social_nav_button(button: Button, is_selected: bool) -> void:
	_ensure_social_controller()
	social_controller._style_social_nav_button(button, is_selected)

func _style_social_thread_button(button: Button) -> void:
	_ensure_social_controller()
	social_controller._style_social_thread_button(button)

func _style_social_follow_cta_button(button: Button) -> void:
	_ensure_social_controller()
	social_controller._style_social_follow_cta_button(button)

func _style_social_search_input(line_edit: LineEdit) -> void:
	_ensure_social_controller()
	social_controller._style_social_search_input(line_edit)
func _show_news_article(article: Dictionary, discover_context: bool = true) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._show_news_article(article, discover_context)
	news_controller._sync_root_refs()

func _discover_news_article_context_after_show(article: Dictionary, article_id: String) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._discover_news_article_context_after_show(article, article_id)
	news_controller._sync_root_refs()

func _reset_news_detail_scroll() -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._reset_news_detail_scroll()
	news_controller._sync_root_refs()

func _on_news_headline_gui_input(event: InputEvent) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._on_news_headline_gui_input(event)
	news_controller._sync_root_refs()

func _on_news_body_gui_input(event: InputEvent) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._on_news_body_gui_input(event)
	news_controller._sync_root_refs()

func _on_news_source_hint_gui_input(event: InputEvent) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._on_news_source_hint_gui_input(event)
	news_controller._sync_root_refs()

func _open_news_capture_menu_from_event(event: InputEvent, context: String) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._open_news_capture_menu_from_event(event, context)
	news_controller._sync_root_refs()

func _show_news_capture_menu(menu_position: Vector2, context: String) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._show_news_capture_menu(menu_position, context)
	news_controller._sync_root_refs()

func _on_news_capture_menu_id_pressed(id: int) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._on_news_capture_menu_id_pressed(id)
	news_controller._sync_root_refs()

func _build_news_capture_payload(article: Dictionary, kind: String) -> Dictionary:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: Dictionary = news_controller._build_news_capture_payload(article, kind)
	news_controller._sync_root_refs()
	return result

func _news_capture_excerpt(body: String) -> String:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: String = news_controller._news_capture_excerpt(body)
	news_controller._sync_root_refs()
	return result

func _impact_from_news_article(article: Dictionary) -> String:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: String = news_controller._impact_from_news_article(article)
	news_controller._sync_root_refs()
	return result

func _current_news_archive_article_summaries() -> Array:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: Array = news_controller._current_news_archive_article_summaries()
	news_controller._sync_root_refs()
	return result

func _build_news_article_list_line(article: Dictionary) -> String:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: String = news_controller._build_news_article_list_line(article)
	news_controller._sync_root_refs()
	return result

func _news_byline_text(article: Dictionary) -> String:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: String = news_controller._news_byline_text(article)
	news_controller._sync_root_refs()
	return result

func _news_article_status_line(article: Dictionary) -> String:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: String = news_controller._news_article_status_line(article)
	news_controller._sync_root_refs()
	return result

func _news_article_chip_line(article: Dictionary) -> String:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: String = news_controller._news_article_chip_line(article)
	news_controller._sync_root_refs()
	return result

func _news_image_slot_label(image_slot: String) -> String:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: String = news_controller._news_image_slot_label(image_slot)
	news_controller._sync_root_refs()
	return result

func _set_news_detail_hero_slot(image_slot: String) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._set_news_detail_hero_slot(image_slot)
	news_controller._sync_root_refs()

func _news_meeting_action_label(article: Dictionary) -> String:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: String = news_controller._news_meeting_action_label(article)
	news_controller._sync_root_refs()
	return result

func _corporate_meeting_open_blocked_reason(detail: Dictionary) -> String:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: String = news_controller._corporate_meeting_open_blocked_reason(detail)
	news_controller._sync_root_refs()
	return result

func _rebuild_news_article_cards(articles: Array, reset_scroll: bool = true) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._rebuild_news_article_cards(articles, reset_scroll)
	news_controller._sync_root_refs()

func _finish_news_article_cards_rebuild(generation: int, remaining_articles: Array) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._finish_news_article_cards_rebuild(generation, remaining_articles)
	news_controller._sync_root_refs()

func _news_article_cards_visible_rows(articles: Array) -> Array:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: Array = news_controller._news_article_cards_visible_rows(articles)
	news_controller._sync_root_refs()
	return result

func _restore_news_article_cards_scroll(scroll_value: float) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._restore_news_article_cards_scroll(scroll_value)
	news_controller._sync_root_refs()

func _build_news_article_card(article: Dictionary) -> PanelContainer:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: PanelContainer = news_controller._build_news_article_card(article)
	news_controller._sync_root_refs()
	return result

func _make_news_article_card_clickable(root: Control, article_id: String) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._make_news_article_card_clickable(root, article_id)
	news_controller._sync_root_refs()

func _on_news_article_card_gui_input(event: InputEvent, article_id: String) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._on_news_article_card_gui_input(event, article_id)
	news_controller._sync_root_refs()

func _news_article_card_node(article_id: String) -> PanelContainer:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: PanelContainer = news_controller._news_article_card_node(article_id)
	news_controller._sync_root_refs()
	return result

func _news_article_card_exists(article_id: String) -> bool:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: bool = news_controller._news_article_card_exists(article_id)
	news_controller._sync_root_refs()
	return result

func _restyle_news_article_cards(previous_article_id: String, next_article_id: String) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._restyle_news_article_cards(previous_article_id, next_article_id)
	news_controller._sync_root_refs()

func _on_news_article_card_pressed(article_id: String) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._on_news_article_card_pressed(article_id)
	news_controller._sync_root_refs()

func _ticker_for_company(company_id: String) -> String:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: String = news_controller._ticker_for_company(company_id)
	news_controller._sync_root_refs()
	return result

func _news_archive_month_label(month_number: int) -> String:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: String = news_controller._news_archive_month_label(month_number)
	news_controller._sync_root_refs()
	return result

func _news_color_for_tone(tone: String) -> Color:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: Color = news_controller._news_color_for_tone(tone)
	news_controller._sync_root_refs()
	return result

func _default_news_outlet_id(outlets: Array) -> String:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: String = news_controller._default_news_outlet_id(outlets)
	news_controller._sync_root_refs()
	return result

func _news_outlet_exists(outlets: Array, outlet_id: String) -> bool:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: bool = news_controller._news_outlet_exists(outlets, outlet_id)
	news_controller._sync_root_refs()
	return result

func _refresh_sidebar() -> void:
	sidebar_hint_label.text = ""
	dashboard_button.set_pressed_no_signal(active_section_id == "dashboard")
	markets_button.set_pressed_no_signal(active_section_id == "markets")
	portfolio_button.set_pressed_no_signal(active_section_id == "portfolio")
	help_button.set_pressed_no_signal(active_section_id == "help")


func _refresh_dashboard() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var phase_started_at_usec: int = started_at_usec
	var log_phase_details: bool = advance_day_processing
	if not RunState.has_active_run():
		dashboard_index_date_label.text = "No active run."
		dashboard_index_points_value_label.text = "-"
		dashboard_index_lots_value_label.text = "-"
		dashboard_index_value_value_label.text = "-"
		dashboard_index_hint_label.text = "Use New Game or Load Run to begin."
		_refresh_dashboard_index_recap({})
		dashboard_calendar_month_label.text = "-"
		_refresh_dashboard_calendar({}, {}, [], [])
		_refresh_dashboard_movers([])
		_refresh_dashboard_sector_panel([])
		_log_perf_phase(log_phase_details, "_refresh_dashboard:no_active_run", started_at_usec)
		return

	var wants_deferred_heavy_refresh: bool = defer_next_dashboard_heavy_refresh
	var index_snapshot: Dictionary = _build_dashboard_index_snapshot(not wants_deferred_heavy_refresh)
	_log_perf_phase(log_phase_details, "_refresh_dashboard:index_snapshot", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
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
	_refresh_dashboard_index_recap(index_snapshot)
	_log_perf_phase(log_phase_details, "_refresh_dashboard:index_labels", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	dashboard_calendar_month_label.text = "%s %d" % [
		DASHBOARD_MONTH_NAMES[clamp(int(trade_date.get("month", 1)) - 1, 0, DASHBOARD_MONTH_NAMES.size() - 1)],
		int(trade_date.get("year", 2020))
	]
	if wants_deferred_heavy_refresh:
		defer_next_dashboard_heavy_refresh = false
		if not dashboard_heavy_refresh_pending:
			dashboard_heavy_refresh_pending = true
			call_deferred("_refresh_dashboard_heavy_after_startup")
		_set_label_tone(dashboard_index_points_value_label, _color_for_change(float(index_snapshot.get("day_change_pct", 0.0))))
		_style_dashboard_section_titles()
		_log_perf_phase(log_phase_details, "_refresh_dashboard:deferred_heavy", phase_started_at_usec)
		_log_perf_phase(log_phase_details, "_refresh_dashboard", started_at_usec)
		return

	var use_light_market_rows: bool = advance_day_processing or deferred_dashboard_refresh_after_recap
	var company_rows: Array = GameManager.get_company_market_rows() if use_light_market_rows else _get_company_rows_cached()
	_log_perf_phase(log_phase_details, "_refresh_dashboard:company_rows", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var dashboard_event_snapshot: Dictionary = GameManager.get_dashboard_event_snapshot()
	_refresh_dashboard_calendar(
		trade_date,
		dashboard_event_snapshot.get("report_calendar_snapshot", {}),
		dashboard_event_snapshot.get("upcoming_meeting_rows", []),
		dashboard_event_snapshot.get("upcoming_index_review_rows", [])
	)
	_log_perf_phase(log_phase_details, "_refresh_dashboard:calendar", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_refresh_dashboard_movers(company_rows)
	_log_perf_phase(log_phase_details, "_refresh_dashboard:movers", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_refresh_dashboard_sector_panel(company_rows)
	_log_perf_phase(log_phase_details, "_refresh_dashboard:sectors", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_set_label_tone(dashboard_index_points_value_label, _color_for_change(float(index_snapshot.get("day_change_pct", 0.0))))
	_style_dashboard_section_titles()
	_log_perf_phase(log_phase_details, "_refresh_dashboard:tone", phase_started_at_usec)
	_log_perf_phase(log_phase_details, "_refresh_dashboard", started_at_usec)


func _refresh_dashboard_heavy_after_startup() -> void:
	if not is_inside_tree():
		dashboard_heavy_refresh_pending = false
		return
	await get_tree().process_frame
	dashboard_heavy_refresh_pending = false
	if not is_inside_tree() or not RunState.has_active_run():
		return
	_refresh_dashboard()


func _refresh_dashboard_index_recap(index_snapshot: Dictionary) -> void:
	_ensure_dashboard_index_recap_ui()
	if (
		dashboard_index_points_label == null or
		dashboard_index_change_label == null or
		dashboard_index_all_market_lot_value_label == null or
		dashboard_index_all_market_value_value_label == null
	):
		return

	var has_snapshot: bool = not index_snapshot.is_empty()
	if not has_snapshot:
		dashboard_index_points_label.text = "-"
		dashboard_index_change_label.text = "-"
		dashboard_index_all_market_lot_value_label.text = "-"
		dashboard_index_all_market_value_value_label.text = "-"
		_set_label_tone(dashboard_index_points_label, COLOR_TEXT)
		_set_label_tone(dashboard_index_change_label, COLOR_MUTED)
		_set_label_tone(dashboard_index_all_market_lot_value_label, COLOR_MUTED)
		_set_label_tone(dashboard_index_all_market_value_value_label, COLOR_MUTED)
		if dashboard_index_sparkline != null and dashboard_index_sparkline.has_method("set_points"):
			dashboard_index_sparkline.call("set_points", [])
		return

	var points: float = float(index_snapshot.get("points", 0.0))
	var point_change: float = float(index_snapshot.get("point_change", 0.0))
	var change_pct: float = float(index_snapshot.get("day_change_pct", 0.0))
	var tone_color: Color = _color_for_change(change_pct)
	dashboard_index_points_label.text = _format_decimal(points, 2, true)
	dashboard_index_change_label.text = "%s (%s)" % [
		_format_signed_decimal(point_change, 2, true),
		_format_change(change_pct)
	]
	dashboard_index_all_market_lot_value_label.text = _format_compact_lots(float(index_snapshot.get("traded_lots", 0.0)))
	dashboard_index_all_market_value_value_label.text = _format_compact_currency(float(index_snapshot.get("traded_value", 0.0)))
	_set_label_tone(dashboard_index_points_label, COLOR_TEXT)
	_set_label_tone(dashboard_index_change_label, tone_color)
	_set_label_tone(dashboard_index_all_market_lot_value_label, tone_color)
	_set_label_tone(dashboard_index_all_market_value_value_label, tone_color)
	if dashboard_index_sparkline != null:
		if dashboard_index_sparkline.has_method("set_points"):
			dashboard_index_sparkline.call("set_points", index_snapshot.get("sparkline_points", []))
		if dashboard_index_sparkline.has_method("set_line_tone"):
			dashboard_index_sparkline.call("set_line_tone", change_pct)
	_style_dashboard_index_recap_ui()


func _get_dashboard_index_recap_smoke_state() -> Dictionary:
	_ensure_dashboard_index_recap_ui()
	var sparkline_point_count: int = 0
	if dashboard_index_sparkline != null and dashboard_index_sparkline.has_method("get_point_count"):
		sparkline_point_count = int(dashboard_index_sparkline.call("get_point_count"))
	elif dashboard_index_sparkline != null:
		sparkline_point_count = int(dashboard_index_sparkline.get_meta("point_count", 0))
	return {
		"recap_exists": dashboard_index_recap_panel != null,
		"points_text": dashboard_index_points_label.text if dashboard_index_points_label != null else "",
		"change_text": dashboard_index_change_label.text if dashboard_index_change_label != null else "",
		"row_count": dashboard_index_all_market_rows.get_child_count() if dashboard_index_all_market_rows != null else 0,
		"lot_text": dashboard_index_all_market_lot_value_label.text if dashboard_index_all_market_lot_value_label != null else "",
		"value_text": dashboard_index_all_market_value_value_label.text if dashboard_index_all_market_value_value_label != null else "",
		"sparkline_point_count": sparkline_point_count,
		"old_date_visible": dashboard_index_date_label.visible if dashboard_index_date_label != null else true,
		"old_grid_visible": dashboard_index_stats_grid.visible if dashboard_index_stats_grid != null else true,
		"old_hint_visible": dashboard_index_hint_label.visible if dashboard_index_hint_label != null else true
	}


func _refresh_dashboard_meetings(rows: Array) -> void:
	if dashboard_meeting_buttons == null:
		return
	for child in dashboard_meeting_buttons.get_children():
		dashboard_meeting_buttons.remove_child(child)
		child.queue_free()
	if rows.is_empty():
		return
	var display_rows: Array = rows.slice(0, min(rows.size(), 4))
	for row_value in display_rows:
		var row: Dictionary = row_value
		var button := Button.new()
		button.text = "%s  |  %s  |  %s" % [
			str(row.get("ticker", "")),
			str(row.get("meeting_label", "Meeting")),
			GameManager.format_trade_date(row.get("trade_date", {}))
		]
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var meeting_blocked_reason: String = ""
		if (
			bool(row.get("interactive_v1", false)) and
			bool(row.get("requires_shareholder", false)) and
			not bool(row.get("attendance_eligible", true))
		):
			meeting_blocked_reason = str(row.get("attendance_blocked_reason", "Shareholder ownership is required to attend this meeting."))
		button.disabled = not meeting_blocked_reason.is_empty()
		button.tooltip_text = meeting_blocked_reason if not meeting_blocked_reason.is_empty() else str(row.get("public_summary", "Open meeting"))
		button.pressed.connect(func() -> void:
			_open_corporate_meeting_modal(str(row.get("id", "")))
		)
		dashboard_meeting_buttons.add_child(button)
		_style_button(button, COLOR_DESKTOP_PANEL, COLOR_DESKTOP_FRAME, COLOR_DESKTOP_TEXT, 0)


func _refresh_dashboard_sector_panel(company_rows: Array) -> void:
	_ensure_dashboard_sector_ui()
	dashboard_placeholder_bottom_title_label.text = "Sector Performance"
	if dashboard_meeting_buttons != null:
		dashboard_meeting_buttons.visible = false
	if dashboard_sector_cards_grid == null or dashboard_sector_detail_rows == null:
		return

	_clear_container_children(dashboard_sector_cards_grid)
	_clear_container_children(dashboard_sector_detail_rows)

	var sector_rows: Array = _build_dashboard_sector_rows(company_rows)
	if sector_rows.is_empty():
		selected_dashboard_sector_id = ""
		dashboard_placeholder_bottom_body_label.visible = true
		dashboard_placeholder_bottom_body_label.text = "No sector data."
		if dashboard_sector_cards_scroll != null:
			dashboard_sector_cards_scroll.visible = false
		if dashboard_sector_detail_vbox != null:
			dashboard_sector_detail_vbox.visible = false
		return

	dashboard_placeholder_bottom_body_label.visible = false
	var selected_row: Dictionary = _dashboard_sector_row_by_id(sector_rows, selected_dashboard_sector_id)
	if selected_dashboard_sector_id.is_empty() or selected_row.is_empty():
		selected_dashboard_sector_id = ""
		if dashboard_sector_cards_scroll != null:
			dashboard_sector_cards_scroll.visible = true
		if dashboard_sector_detail_vbox != null:
			dashboard_sector_detail_vbox.visible = false
		for row_value in sector_rows:
			var row: Dictionary = row_value
			dashboard_sector_cards_grid.add_child(_build_dashboard_sector_card(row))
		return

	if dashboard_sector_cards_scroll != null:
		dashboard_sector_cards_scroll.visible = false
	if dashboard_sector_detail_vbox != null:
		dashboard_sector_detail_vbox.visible = true
	_refresh_dashboard_sector_detail(selected_row)


func _build_dashboard_sector_rows(company_rows: Array) -> Array:
	var grouped_rows: Dictionary = {}
	for row_value in company_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var company_row: Dictionary = row_value
		var sector_id: String = str(company_row.get("sector_id", "")).strip_edges()
		if sector_id.is_empty():
			continue
		var sector_name: String = str(company_row.get("sector_name", "")).strip_edges()
		if sector_name.is_empty():
			var sector_definition: Dictionary = DataRepository.get_sector_definition(sector_id)
			sector_name = str(sector_definition.get("name", sector_id.capitalize()))
		if not grouped_rows.has(sector_id):
			grouped_rows[sector_id] = {
				"id": sector_id,
				"name": sector_name,
				"company_count": 0,
				"advancers": 0,
				"decliners": 0,
				"flat_count": 0,
				"change_sum": 0.0,
				"strongest_ticker": "",
				"strongest_change_pct": 0.0,
				"stocks": []
			}

		var sector_row: Dictionary = grouped_rows[sector_id]
		var daily_change_pct: float = float(company_row.get("daily_change_pct", 0.0))
		sector_row["company_count"] = int(sector_row.get("company_count", 0)) + 1
		sector_row["change_sum"] = float(sector_row.get("change_sum", 0.0)) + daily_change_pct
		if daily_change_pct > 0.0:
			sector_row["advancers"] = int(sector_row.get("advancers", 0)) + 1
		elif daily_change_pct < 0.0:
			sector_row["decliners"] = int(sector_row.get("decliners", 0)) + 1
		else:
			sector_row["flat_count"] = int(sector_row.get("flat_count", 0)) + 1
		if (
			str(sector_row.get("strongest_ticker", "")).is_empty() or
			absf(daily_change_pct) > absf(float(sector_row.get("strongest_change_pct", 0.0)))
		):
			sector_row["strongest_ticker"] = str(company_row.get("ticker", ""))
			sector_row["strongest_change_pct"] = daily_change_pct
		var stock_rows: Array = sector_row.get("stocks", [])
		stock_rows.append({
			"id": str(company_row.get("id", "")),
			"ticker": str(company_row.get("ticker", "")),
			"name": str(company_row.get("name", "")),
			"current_price": float(company_row.get("current_price", 0.0)),
			"daily_change_pct": daily_change_pct
		})
		sector_row["stocks"] = stock_rows
		grouped_rows[sector_id] = sector_row

	var sector_rows: Array = []
	for sector_id_value in grouped_rows.keys():
		var sector_row: Dictionary = grouped_rows[sector_id_value].duplicate(true)
		var company_count: int = int(sector_row.get("company_count", 0))
		sector_row["average_change_pct"] = 0.0
		if company_count > 0:
			sector_row["average_change_pct"] = float(sector_row.get("change_sum", 0.0)) / float(company_count)
		var stocks: Array = sector_row.get("stocks", [])
		stocks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get("daily_change_pct", 0.0)) > float(b.get("daily_change_pct", 0.0))
		)
		sector_row["stocks"] = stocks
		sector_rows.append(sector_row)
	sector_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("average_change_pct", 0.0)) > float(b.get("average_change_pct", 0.0))
	)
	return sector_rows


func _dashboard_sector_row_by_id(sector_rows: Array, sector_id: String) -> Dictionary:
	if sector_id.is_empty():
		return {}
	for row_value in sector_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("id", "")) == sector_id:
			return row
	return {}


func _build_dashboard_sector_card(row: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var sector_id: String = str(row.get("id", ""))
	panel.name = "DashboardSectorCard_%s" % sector_id
	panel.custom_minimum_size = Vector2(0, 82)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_meta("sector_id", sector_id)
	panel.set_meta("average_change_pct", float(row.get("average_change_pct", 0.0)))
	panel.tooltip_text = "%s | %d stocks | Loudest tape %s %s" % [
		str(row.get("name", "Unknown")),
		int(row.get("company_count", 0)),
		str(row.get("strongest_ticker", "n/a")),
		_format_change(float(row.get("strongest_change_pct", 0.0)))
	]
	panel.tooltip_text += "\nRight-click to capture sector context."
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.gui_input.connect(_on_dashboard_sector_card_gui_input.bind(sector_id, row.duplicate(true)))
	_style_dashboard_sector_card(panel, float(row.get("average_change_pct", 0.0)))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	vbox.add_child(top_row)

	var name_label := Label.new()
	name_label.name = "DashboardSectorCardNameLabel"
	name_label.text = str(row.get("name", "Unknown"))
	name_label.clip_text = true
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_label_tone(name_label, COLOR_TEXT)
	top_row.add_child(name_label)

	var change_label := Label.new()
	change_label.name = "DashboardSectorCardChangeLabel"
	change_label.text = _format_change(float(row.get("average_change_pct", 0.0)))
	change_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	change_label.custom_minimum_size = Vector2(76, 0)
	_set_label_tone(change_label, _color_for_change(float(row.get("average_change_pct", 0.0))))
	top_row.add_child(change_label)

	var breadth_label := Label.new()
	breadth_label.name = "DashboardSectorCardBreadthLabel"
	breadth_label.text = "%d stocks  |  %d green  |  %d red" % [
		int(row.get("company_count", 0)),
		int(row.get("advancers", 0)),
		int(row.get("decliners", 0))
	]
	breadth_label.clip_text = true
	_set_label_tone(breadth_label, COLOR_MUTED)
	vbox.add_child(breadth_label)

	var strongest_label := Label.new()
	strongest_label.name = "DashboardSectorCardStrongestLabel"
	strongest_label.text = "Loudest %s %s" % [
		str(row.get("strongest_ticker", "n/a")),
		_format_change(float(row.get("strongest_change_pct", 0.0)))
	]
	strongest_label.clip_text = true
	_set_label_tone(strongest_label, COLOR_WARNING)
	vbox.add_child(strongest_label)

	return panel


func _style_dashboard_sector_card(panel: PanelContainer, change_pct: float) -> void:
	var fill_color: Color = Color(0.0823529, 0.117647, 0.156863, 0.94)
	var border_color: Color = COLOR_BORDER
	if change_pct > 0.0005:
		fill_color = Color(0.0784314, 0.168627, 0.137255, 0.96)
		border_color = Color(COLOR_POSITIVE.r, COLOR_POSITIVE.g, COLOR_POSITIVE.b, 0.86)
	elif change_pct < -0.0005:
		fill_color = Color(0.184314, 0.0941176, 0.105882, 0.96)
		border_color = Color(COLOR_NEGATIVE.r, COLOR_NEGATIVE.g, COLOR_NEGATIVE.b, 0.86)
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)


func _refresh_dashboard_sector_detail(row: Dictionary) -> void:
	if dashboard_sector_detail_title_label == null or dashboard_sector_detail_rows == null:
		return
	dashboard_sector_detail_title_label.text = "%s  %s" % [
		str(row.get("name", "Unknown")),
		_format_change(float(row.get("average_change_pct", 0.0)))
	]
	_set_label_tone(dashboard_sector_detail_title_label, _color_for_change(float(row.get("average_change_pct", 0.0))))
	var stocks: Array = row.get("stocks", [])
	for stock_value in stocks:
		var stock: Dictionary = stock_value
		dashboard_sector_detail_rows.add_child(_build_dashboard_sector_stock_row(stock))
	if stocks.is_empty():
		var empty_label := Label.new()
		empty_label.name = "DashboardSectorStockEmptyLabel"
		empty_label.text = "No stocks in this sector."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_set_label_tone(empty_label, COLOR_MUTED)
		dashboard_sector_detail_rows.add_child(empty_label)


func _build_dashboard_sector_stock_row(stock: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.name = "DashboardSectorStockRow_%s" % str(stock.get("id", ""))
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_build_table_cell(str(stock.get("ticker", "")), 58.0, COLOR_TEXT))
	var name_label: Label = _build_table_cell(str(stock.get("name", "")), 0.0, COLOR_MUTED, true)
	row.add_child(name_label)
	row.add_child(_build_table_cell(
		_format_currency(float(stock.get("current_price", 0.0))),
		86.0,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_change(float(stock.get("daily_change_pct", 0.0))),
		72.0,
		_color_for_change(float(stock.get("daily_change_pct", 0.0))),
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	return row


func _on_dashboard_sector_card_gui_input(event: InputEvent, sector_id: String, row: Dictionary = {}) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			selected_dashboard_sector_id = sector_id
			_refresh_dashboard_sector_panel(_get_company_rows_cached())
			get_viewport().set_input_as_handled()
		elif mouse_button.button_index == MOUSE_BUTTON_RIGHT and mouse_button.pressed:
			_prepare_dashboard_sector_capture(row)
			_show_dashboard_sector_capture_menu(mouse_button.global_position)
			get_viewport().set_input_as_handled()


func _prepare_dashboard_sector_capture(row: Dictionary) -> void:
	var sector_id: String = str(row.get("id", "")).strip_edges()
	var sector_name: String = str(row.get("name", "Sector")).strip_edges()
	var average_change: float = float(row.get("average_change_pct", 0.0))
	var impact: String = "mixed"
	if average_change > 0.0005:
		impact = "positive"
	elif average_change < -0.0005:
		impact = "negative"
	var detail: String = "%d of %d stocks advanced and %d declined; loudest tape is %s %s." % [
		int(row.get("advancers", 0)),
		int(row.get("company_count", 0)),
		int(row.get("decliners", 0)),
		str(row.get("strongest_ticker", "n/a")),
		_format_change(float(row.get("strongest_change_pct", 0.0)))
	]
	pending_capture_payloads["dashboard_sector"] = {
		"source_type": "sector_macro",
		"category": "sector_macro",
		"category_label": "Sector / Macro",
		"source_label": "Stockboard Sector",
		"source_id": "stockboard_sector_%s_day_%d" % [_node_token(sector_id), RunState.day_index],
		"sector_id": sector_id,
		"sector_name": sector_name,
		"label": "%s sector breadth" % sector_name,
		"value": _format_change(average_change),
		"detail": detail,
		"impact": impact
	}


func _show_dashboard_sector_capture_menu(menu_position: Vector2) -> void:
	if dashboard_sector_capture_menu == null:
		dashboard_sector_capture_menu = PopupMenu.new()
		dashboard_sector_capture_menu.name = "DashboardSectorCaptureContextMenu"
		dashboard_sector_capture_menu.id_pressed.connect(_on_dashboard_sector_capture_menu_id_pressed)
		add_child(dashboard_sector_capture_menu)
	dashboard_sector_capture_menu.clear()
	dashboard_sector_capture_menu.add_item("Add to Research Tray", 1)
	dashboard_sector_capture_menu.position = Vector2i(int(menu_position.x), int(menu_position.y))
	dashboard_sector_capture_menu.popup()


func _on_dashboard_sector_capture_menu_id_pressed(id: int) -> void:
	_commit_pending_capture("dashboard_sector", id)


func _on_dashboard_sector_back_pressed() -> void:
	selected_dashboard_sector_id = ""
	_refresh_dashboard_sector_panel(_get_company_rows_cached())


func _build_dashboard_index_snapshot(include_sparkline: bool = true) -> Dictionary:
	var weighted_ratio_sum: float = 0.0
	var previous_weighted_ratio_sum: float = 0.0
	var weight_total: float = 0.0
	var traded_lots: float = 0.0
	var traded_value: float = 0.0
	var advancers: int = 0
	var decliners: int = 0
	var flat_count: int = 0

	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = RunState.get_company(company_id)
		if runtime.is_empty():
			continue

		var current_price: float = float(runtime.get("current_price", 0.0))
		var starting_price: float = max(float(runtime.get("starting_price", current_price)), 1.0)
		var weight: float = _dashboard_index_weight_for_runtime(runtime, current_price)
		var previous_close: float = current_price
		var price_bars: Array = runtime.get("price_bars", [])
		if not price_bars.is_empty():
			var latest_bar: Dictionary = price_bars[price_bars.size() - 1]
			current_price = float(latest_bar.get("close", current_price))
			previous_close = float(latest_bar.get("open", latest_bar.get("previous_close", current_price)))
			traded_lots += float(latest_bar.get("volume_lots", 0.0))
			traded_value += float(latest_bar.get("value", 0.0))
		elif absf(float(runtime.get("daily_change_pct", 0.0))) > 0.000001:
			previous_close = current_price / max(1.0 + float(runtime.get("daily_change_pct", 0.0)), 0.0001)
		weighted_ratio_sum += (current_price / starting_price) * weight
		previous_weighted_ratio_sum += (max(previous_close, 0.0) / starting_price) * weight
		weight_total += weight

		var daily_change_pct: float = float(runtime.get("daily_change_pct", 0.0))
		if daily_change_pct > 0.0:
			advancers += 1
		elif daily_change_pct < 0.0:
			decliners += 1
		else:
			flat_count += 1

	var points: float = 1000.0
	var previous_points: float = 1000.0
	var point_change: float = 0.0
	var day_change_pct: float = 0.0
	if weight_total > 0.0:
		points = 1000.0 * (weighted_ratio_sum / weight_total)
		previous_points = 1000.0 * (previous_weighted_ratio_sum / weight_total)
		point_change = points - previous_points
		if previous_points > 0.0:
			day_change_pct = point_change / previous_points

	return {
		"points": points,
		"previous_points": previous_points,
		"point_change": point_change,
		"traded_lots": traded_lots,
		"traded_value": traded_value,
		"advancers": advancers,
		"decliners": decliners,
		"flat_count": flat_count,
		"day_change_pct": day_change_pct,
		"sparkline_points": _build_dashboard_index_sparkline_points() if include_sparkline else []
	}


func _dashboard_index_weight_for_runtime(runtime: Dictionary, current_price: float) -> float:
	var company_profile: Dictionary = runtime.get("company_profile", {})
	var financials: Dictionary = company_profile.get("financials", {})
	return max(float(financials.get("market_cap", current_price * 1000000000.0)), current_price * 1000000.0)


func _build_dashboard_index_sparkline_points() -> Array:
	var company_series_rows: Array = []
	var max_series_size: int = 0
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = RunState.get_company(company_id)
		if runtime.is_empty():
			continue
		var close_series: Array = _dashboard_index_close_series_for_runtime(runtime)
		if close_series.size() < 2:
			continue
		var current_price: float = float(runtime.get("current_price", close_series[close_series.size() - 1]))
		var starting_price: float = max(float(runtime.get("starting_price", close_series[0])), 1.0)
		var weight: float = _dashboard_index_weight_for_runtime(runtime, current_price)
		if weight <= 0.0:
			continue
		company_series_rows.append({
			"series": close_series,
			"starting_price": starting_price,
			"weight": weight
		})
		max_series_size = max(max_series_size, close_series.size())

	var point_count: int = min(DASHBOARD_INDEX_SPARKLINE_POINT_LIMIT, max_series_size)
	if point_count < 2 or company_series_rows.is_empty():
		return []

	var points: Array = []
	for point_index in range(point_count):
		var offset_from_end: int = point_count - point_index
		var weighted_ratio_sum: float = 0.0
		var weight_total: float = 0.0
		for row_value in company_series_rows:
			var row: Dictionary = row_value
			var series: Array = row.get("series", [])
			if series.size() < offset_from_end:
				continue
			var close_value: float = float(series[series.size() - offset_from_end])
			var starting_price: float = max(float(row.get("starting_price", close_value)), 1.0)
			var weight: float = float(row.get("weight", 0.0))
			weighted_ratio_sum += (close_value / starting_price) * weight
			weight_total += weight
		if weight_total > 0.0:
			points.append(1000.0 * (weighted_ratio_sum / weight_total))
	return points


func _dashboard_index_close_series_for_runtime(runtime: Dictionary) -> Array:
	var close_series: Array = []
	var price_bars: Array = runtime.get("price_bars", [])
	if not price_bars.is_empty():
		var first_bar_value = price_bars[0]
		if typeof(first_bar_value) == TYPE_DICTIONARY:
			var first_bar: Dictionary = first_bar_value
			close_series.append(float(first_bar.get("open", runtime.get("starting_price", runtime.get("current_price", 0.0)))))
		for bar_value in price_bars:
			if typeof(bar_value) != TYPE_DICTIONARY:
				continue
			var bar: Dictionary = bar_value
			close_series.append(float(bar.get("close", runtime.get("current_price", 0.0))))
		if close_series.size() >= 2:
			return close_series

	var price_history: Array = runtime.get("price_history", [])
	for price_value in price_history:
		close_series.append(float(price_value))
	return close_series


func _refresh_dashboard_movers(company_rows: Array) -> void:
	if dashboard_movers_tabs == null:
		return
	_ensure_dashboard_broker_flow_ui()
	dashboard_movers_tabs.set_tab_title(0, "Top 15 Gainer")
	dashboard_movers_tabs.set_tab_title(1, "Top 15 Loser")
	if dashboard_movers_tabs.get_tab_count() >= 3:
		dashboard_movers_tabs.set_tab_title(2, "Broker Flow")
	_refresh_dashboard_mover_side(company_rows, true)
	_refresh_dashboard_mover_side(company_rows, false)
	_refresh_dashboard_broker_movement_rows()


func _refresh_dashboard_mover_side(company_rows: Array, wants_gainers: bool) -> void:
	var rows_container: VBoxContainer = dashboard_top_gainers_rows if wants_gainers else dashboard_top_losers_rows
	var empty_label: Label = dashboard_top_gainers_empty_label if wants_gainers else dashboard_top_losers_empty_label
	if rows_container == null or empty_label == null:
		return

	_clear_dynamic_rows(rows_container, empty_label)
	var movers: Array = []
	for row_value in company_rows:
		var company_row: Dictionary = row_value
		var change_pct: float = float(company_row.get("daily_change_pct", 0.0))
		if wants_gainers and change_pct <= 0.0:
			continue
		if not wants_gainers and change_pct >= 0.0:
			continue
		movers.append(company_row)

	movers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_change: float = float(a.get("daily_change_pct", 0.0))
		var b_change: float = float(b.get("daily_change_pct", 0.0))
		return a_change > b_change if wants_gainers else a_change < b_change
	)
	if movers.size() > DASHBOARD_MOVER_LIMIT:
		movers = movers.slice(0, DASHBOARD_MOVER_LIMIT)

	empty_label.visible = movers.is_empty()
	empty_label.text = "No gainers this session." if wants_gainers else "No losers this session."
	for mover_index in range(movers.size()):
		rows_container.add_child(_build_dashboard_mover_row(movers[mover_index], mover_index + 1))


func _refresh_dashboard_broker_movement_rows() -> void:
	if dashboard_top_broker_flow_rows == null or dashboard_top_broker_flow_empty_label == null:
		return

	_clear_dynamic_rows(dashboard_top_broker_flow_rows, dashboard_top_broker_flow_empty_label)
	var broker_rows: Array = _build_dashboard_broker_movement_rows()
	dashboard_top_broker_flow_empty_label.visible = broker_rows.is_empty()
	dashboard_top_broker_flow_empty_label.text = "No broker tape this session."
	for broker_index in range(broker_rows.size()):
		dashboard_top_broker_flow_rows.add_child(_build_dashboard_broker_movement_row(broker_rows[broker_index], broker_index + 1))


func _build_dashboard_broker_movement_rows() -> Array:
	if not RunState.has_active_run():
		return []
	var brokers_by_code: Dictionary = {}
	var broker_roster: Array = DataRepository.get_broker_roster()
	for broker_value in broker_roster:
		if broker_value is Dictionary:
			_ensure_dashboard_broker_movement_row(brokers_by_code, broker_value)
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		if company_id.is_empty():
			continue
		var runtime: Dictionary = RunState.get_company(company_id)
		var broker_flow: Dictionary = runtime.get("broker_flow", {})
		if broker_flow.is_empty():
			continue

		var all_brokers: Array = broker_flow.get("broker_rows", [])
		if not all_brokers.is_empty():
			for broker_value in all_brokers:
				if typeof(broker_value) != TYPE_DICTIONARY:
					continue
				_accumulate_dashboard_broker_activity(brokers_by_code, broker_value)
			continue

		var buy_brokers: Array = broker_flow.get("buy_brokers", [])
		for broker_value in buy_brokers:
			if typeof(broker_value) != TYPE_DICTIONARY:
				continue
			_accumulate_dashboard_broker_movement(brokers_by_code, broker_value, true)

		var sell_brokers: Array = broker_flow.get("sell_brokers", [])
		for broker_value in sell_brokers:
			if typeof(broker_value) != TYPE_DICTIONARY:
				continue
			_accumulate_dashboard_broker_movement(brokers_by_code, broker_value, false)

	var rows: Array = []
	for broker_code_value in brokers_by_code.keys():
		var broker_row: Dictionary = brokers_by_code.get(broker_code_value, {})
		var net_value: float = float(broker_row.get("buy_value", 0.0)) - float(broker_row.get("sell_value", 0.0))
		var net_lots: float = float(broker_row.get("buy_lots", 0.0)) - float(broker_row.get("sell_lots", 0.0))
		broker_row["net_value"] = net_value
		broker_row["net_lots"] = net_lots
		broker_row["gross_value"] = float(broker_row.get("buy_value", 0.0)) + float(broker_row.get("sell_value", 0.0))
		broker_row["gross_lots"] = float(broker_row.get("buy_lots", 0.0)) + float(broker_row.get("sell_lots", 0.0))
		if (
			not broker_roster.is_empty() or
			float(broker_row.get("gross_value", 0.0)) > 0.0 or
			float(broker_row.get("gross_lots", 0.0)) > 0.0
		):
			rows.append(broker_row)

	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_net_value: float = absf(float(a.get("net_value", 0.0)))
		var b_net_value: float = absf(float(b.get("net_value", 0.0)))
		if not is_equal_approx(a_net_value, b_net_value):
			return a_net_value > b_net_value
		return float(a.get("gross_value", 0.0)) > float(b.get("gross_value", 0.0))
	)
	return rows


func _accumulate_dashboard_broker_movement(brokers_by_code: Dictionary, broker_source: Dictionary, is_buy_side: bool) -> void:
	var broker_row: Dictionary = _ensure_dashboard_broker_movement_row(brokers_by_code, broker_source)
	if broker_row.is_empty():
		return
	var side_prefix: String = "buy" if is_buy_side else "sell"
	broker_row["%s_value" % side_prefix] = float(broker_row.get("%s_value" % side_prefix, 0.0)) + float(broker_source.get("value", 0.0))
	broker_row["%s_lots" % side_prefix] = float(broker_row.get("%s_lots" % side_prefix, 0.0)) + float(broker_source.get("lots", 0.0))
	brokers_by_code[str(broker_row.get("code", ""))] = broker_row


func _accumulate_dashboard_broker_activity(brokers_by_code: Dictionary, broker_source: Dictionary) -> void:
	var broker_row: Dictionary = _ensure_dashboard_broker_movement_row(brokers_by_code, broker_source)
	if broker_row.is_empty():
		return
	broker_row["buy_value"] = float(broker_row.get("buy_value", 0.0)) + float(broker_source.get("buy_value", 0.0))
	broker_row["sell_value"] = float(broker_row.get("sell_value", 0.0)) + float(broker_source.get("sell_value", 0.0))
	broker_row["buy_lots"] = float(broker_row.get("buy_lots", 0.0)) + float(broker_source.get("buy_lots", 0.0))
	broker_row["sell_lots"] = float(broker_row.get("sell_lots", 0.0)) + float(broker_source.get("sell_lots", 0.0))
	brokers_by_code[str(broker_row.get("code", ""))] = broker_row


func _ensure_dashboard_broker_movement_row(brokers_by_code: Dictionary, broker_source: Dictionary) -> Dictionary:
	var broker_code: String = str(broker_source.get("code", "")).strip_edges()
	if broker_code.is_empty():
		return {}
	var broker_row: Dictionary = brokers_by_code.get(broker_code, {})
	if broker_row.is_empty():
		broker_row = {
			"code": broker_code,
			"name": _get_dashboard_broker_name(broker_source),
			"broker_type": str(broker_source.get("broker_type", "")),
			"buy_value": 0.0,
			"sell_value": 0.0,
			"buy_lots": 0.0,
			"sell_lots": 0.0
		}
		brokers_by_code[broker_code] = broker_row
	else:
		var source_name: String = _get_dashboard_broker_name(broker_source)
		if str(broker_row.get("name", "")).is_empty() and not source_name.is_empty():
			broker_row["name"] = source_name
		if str(broker_row.get("broker_type", "")).is_empty():
			broker_row["broker_type"] = str(broker_source.get("broker_type", ""))
	return broker_row


func _get_dashboard_broker_name(broker_source: Dictionary) -> String:
	var source_name: String = str(broker_source.get("company_name", "")).strip_edges()
	if source_name.is_empty():
		source_name = str(broker_source.get("name", "")).strip_edges()
	return source_name


func _build_dashboard_mover_row(company_row: Dictionary, rank_number: int) -> Control:
	var row_wrap: VBoxContainer = VBoxContainer.new()
	row_wrap.add_theme_constant_override("separation", 4)
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	row_wrap.add_child(row)

	row.add_child(_build_table_cell("%02d" % rank_number, 30.0, COLOR_MUTED))
	row.add_child(_build_table_cell(str(company_row.get("ticker", "")), 56.0, COLOR_TEXT))
	var name_label: Label = _build_table_cell(str(company_row.get("name", "")), 0.0, COLOR_TEXT, true)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	row.add_child(_build_table_cell(
		_format_last_price(float(company_row.get("current_price", 0.0))),
		78.0,
		COLOR_TEXT,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_change(float(company_row.get("daily_change_pct", 0.0))),
		64.0,
		_color_for_change(float(company_row.get("daily_change_pct", 0.0))),
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	var separator: HSeparator = HSeparator.new()
	row_wrap.add_child(separator)
	return row_wrap


func _build_dashboard_broker_movement_row(broker_row: Dictionary, rank_number: int) -> Control:
	var row_wrap: VBoxContainer = VBoxContainer.new()
	row_wrap.add_theme_constant_override("separation", 4)
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	row_wrap.add_child(row)

	var net_value: float = float(broker_row.get("net_value", 0.0))
	var buy_lots: float = float(broker_row.get("buy_lots", 0.0))
	var sell_lots: float = float(broker_row.get("sell_lots", 0.0))
	var net_color: Color = _color_for_change(net_value)
	row_wrap.tooltip_text = "%s\nBuy %s lot(s), %s\nSell %s lot(s), %s\nNet %s lot(s), %s" % [
		str(broker_row.get("name", broker_row.get("code", ""))),
		_format_compact_lots(buy_lots),
		_format_compact_currency(float(broker_row.get("buy_value", 0.0))),
		_format_compact_lots(sell_lots),
		_format_compact_currency(float(broker_row.get("sell_value", 0.0))),
		_format_signed_compact_lots(float(broker_row.get("net_lots", 0.0))),
		_format_signed_compact_currency(net_value)
	]

	row.add_child(_build_table_cell("%02d" % rank_number, 30.0, COLOR_MUTED))
	row.add_child(_build_table_cell(str(broker_row.get("code", "")), 48.0, COLOR_TEXT))
	var name_label: Label = _build_table_cell(str(broker_row.get("name", "")), 0.0, COLOR_TEXT, true)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	row.add_child(_build_table_cell(
		_format_compact_lots(buy_lots),
		64.0,
		COLOR_POSITIVE,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_compact_lots(sell_lots),
		64.0,
		COLOR_NEGATIVE,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	row.add_child(_build_table_cell(
		_format_signed_compact_currency(net_value),
		84.0,
		net_color,
		false,
		HORIZONTAL_ALIGNMENT_RIGHT
	))
	var separator: HSeparator = HSeparator.new()
	row_wrap.add_child(separator)
	return row_wrap


func _refresh_dashboard_calendar(
	current_date: Dictionary,
	cached_report_snapshot: Dictionary = {},
	meeting_rows: Array = [],
	index_review_rows: Array = []
) -> void:
	if dashboard_calendar_days_grid == null:
		return

	_style_dashboard_calendar_grid()
	_clear_container_children(dashboard_calendar_days_grid)
	if current_date.is_empty():
		return

	var year_value: int = int(current_date.get("year", 2020))
	var month_value: int = int(current_date.get("month", 1))
	var current_day: int = int(current_date.get("day", 1))
	var report_snapshot: Dictionary = cached_report_snapshot
	if report_snapshot.is_empty():
		report_snapshot = GameManager.get_report_calendar_snapshot(year_value, month_value)
	var reports_by_day: Dictionary = report_snapshot.get("reports_by_day", {})
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
		var day_reports: Array = reports_by_day.get(str(day_value), [])
		var day_meetings: Array = _dashboard_calendar_meetings_for_day(meeting_rows, year_value, month_value, day_value)
		var day_index_reviews: Array = _dashboard_calendar_index_reviews_for_day(index_review_rows, year_value, month_value, day_value)
		dashboard_calendar_days_grid.add_child(_build_dashboard_calendar_day_cell(
			day_value,
			is_current_day,
			is_trade_day,
			day_reports,
			day_meetings,
			day_index_reviews,
			day_info
		))

	while dashboard_calendar_days_grid.get_child_count() % 7 != 0:
		dashboard_calendar_days_grid.add_child(_build_dashboard_calendar_spacer())


func _build_dashboard_calendar_spacer() -> Control:
	var spacer: PanelContainer = PanelContainer.new()
	spacer.custom_minimum_size = Vector2(0, DASHBOARD_CALENDAR_CELL_HEIGHT)
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.size_flags_vertical = Control.SIZE_FILL
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0588235, 0.0823529, 0.109804, 0.34)
	style.border_color = Color(0.141176, 0.176471, 0.215686, 0.28)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	spacer.add_theme_stylebox_override("panel", style)
	return spacer


func _dashboard_calendar_meetings_for_day(meeting_rows: Array, year_value: int, month_value: int, day_value: int) -> Array:
	var rows: Array = []
	for meeting_value in meeting_rows:
		if typeof(meeting_value) != TYPE_DICTIONARY:
			continue
		var meeting: Dictionary = meeting_value
		var trade_date: Dictionary = meeting.get("trade_date", {})
		if (
			int(trade_date.get("year", 0)) == year_value and
			int(trade_date.get("month", 0)) == month_value and
			int(trade_date.get("day", 0)) == day_value
		):
			rows.append(meeting.duplicate(true))
	return rows


func _dashboard_calendar_index_reviews_for_day(index_review_rows: Array, year_value: int, month_value: int, day_value: int) -> Array:
	var rows: Array = []
	for review_value in index_review_rows:
		if typeof(review_value) != TYPE_DICTIONARY:
			continue
		var review: Dictionary = review_value
		var trade_date: Dictionary = review.get("trade_date", {})
		if (
			int(trade_date.get("year", 0)) == year_value and
			int(trade_date.get("month", 0)) == month_value and
			int(trade_date.get("day", 0)) == day_value
		):
			rows.append(review.duplicate(true))
	return rows


func _format_calendar_event_tooltip(reports: Array, meetings: Array, index_reviews: Array) -> String:
	if reports.is_empty() and meetings.is_empty() and index_reviews.is_empty():
		return ""
	var parts: Array = []
	var report_labels: Array = []
	for report_value in reports:
		var report: Dictionary = report_value
		report_labels.append("%s %s" % [str(report.get("ticker", "")), str(report.get("period_label", ""))])
	if not report_labels.is_empty():
		parts.append("Reports: %s" % ", ".join(report_labels))
	var meeting_labels: Array = []
	for meeting_value in meetings:
		var meeting: Dictionary = meeting_value
		meeting_labels.append("%s %s" % [str(meeting.get("ticker", "")), str(meeting.get("meeting_label", "Meeting"))])
	if not meeting_labels.is_empty():
		parts.append("Meetings: %s" % ", ".join(meeting_labels))
	var index_review_labels: Array = []
	for review_value in index_reviews:
		var review: Dictionary = review_value
		index_review_labels.append("%s %s" % [str(review.get("provider_label", "Index")), str(review.get("event_type", "review")).capitalize()])
	if not index_review_labels.is_empty():
		parts.append("Index reviews: %s" % ", ".join(index_review_labels))
	return "\n".join(parts)


func _format_upcoming_report_rows(reports: Array) -> String:
	if reports.is_empty():
		return "No upcoming filings on the report calendar."
	var lines: Array = []
	var grouped_by_date: Dictionary = {}
	for report_value in reports:
		var report: Dictionary = report_value
		var date_key: String = str(report.get("date_key", ""))
		if not grouped_by_date.has(date_key):
			var report_date: Dictionary = report.get("report_date", {})
			grouped_by_date[date_key] = {
				"date": report_date.duplicate(true),
				"items": []
			}
		grouped_by_date[date_key]["items"].append("%s %s" % [
			str(report.get("ticker", "")),
			str(report.get("period_label", ""))
		])
	var date_keys: Array = grouped_by_date.keys()
	date_keys.sort()
	for date_key_value in date_keys:
		var date_key: String = str(date_key_value)
		var group: Dictionary = grouped_by_date[date_key]
		var date_info: Dictionary = group.get("date", {})
		lines.append("%s: %s" % [
			GameManager.format_trade_date(date_info),
			", ".join(group.get("items", []))
		])
	return "\n".join(lines)


func _build_dashboard_calendar_day_cell(
	day_value: int,
	is_current_day: bool,
	is_trade_day: bool,
	reports: Array = [],
	meetings: Array = [],
	index_reviews: Array = [],
	date_info: Dictionary = {}
) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "DashboardCalendarDay_%02d" % day_value
	panel.custom_minimum_size = Vector2(0, DASHBOARD_CALENDAR_CELL_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.tooltip_text = _format_calendar_event_tooltip(reports, meetings, index_reviews)
	panel.set_meta("day", day_value)
	panel.set_meta("report_count", reports.size())
	panel.set_meta("meeting_count", meetings.size())
	panel.set_meta("index_review_count", index_reviews.size())
	panel.set_meta("has_events", not reports.is_empty() or not meetings.is_empty() or not index_reviews.is_empty())
	var meeting_ids: Array = []
	for meeting_value in meetings:
		var meeting: Dictionary = meeting_value
		var meeting_id: String = str(meeting.get("id", ""))
		if not meeting_id.is_empty():
			meeting_ids.append(meeting_id)
	panel.set_meta("meeting_ids", meeting_ids)
	panel.gui_input.connect(_on_dashboard_calendar_day_cell_gui_input.bind(
		date_info.duplicate(true),
		reports.duplicate(true),
		meetings.duplicate(true),
		index_reviews.duplicate(true)
	))

	var label: Label = Label.new()
	label.text = str(day_value)
	var badges: Array = []
	if not reports.is_empty():
		badges.append("%dR" % reports.size())
	if not meetings.is_empty():
		badges.append("%dM" % meetings.size())
	if not index_reviews.is_empty():
		badges.append("%dIR" % index_reviews.size())
	if not badges.is_empty():
		label.text = "%d\n%s" % [day_value, " ".join(badges)]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)

	var fill_color: Color = Color(0.0784314, 0.109804, 0.141176, 0.85)
	var border_color: Color = Color(0.211765, 0.270588, 0.329412, 0.7)
	var text_color: Color = COLOR_TEXT
	if not is_trade_day:
		fill_color = Color(0.054902, 0.0705882, 0.0901961, 0.72)
		border_color = Color(0.141176, 0.176471, 0.215686, 0.6)
		text_color = COLOR_MUTED
	if not reports.is_empty() or not meetings.is_empty() or not index_reviews.is_empty():
		fill_color = Color(0.192157, 0.152941, 0.0823529, 0.96)
		border_color = COLOR_WARNING
		text_color = Color(1, 0.941176, 0.760784, 1)
	if reports.is_empty() and not meetings.is_empty():
		fill_color = Color(0.0901961, 0.164706, 0.168627, 0.96)
		border_color = COLOR_ACCENT
		text_color = Color(0.815686, 0.933333, 1, 1)
	if reports.is_empty() and meetings.is_empty() and not index_reviews.is_empty():
		fill_color = Color(0.121569, 0.137255, 0.207843, 0.96)
		border_color = Color(0.517647, 0.658824, 0.92549, 1)
		text_color = Color(0.858824, 0.901961, 1, 1)
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


func _on_dashboard_calendar_day_cell_gui_input(
	event: InputEvent,
	date_info: Dictionary,
	reports: Array,
	meetings: Array,
	index_reviews: Array
) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			_show_dashboard_calendar_event_popup(date_info, reports, meetings, index_reviews)
			get_viewport().set_input_as_handled()


func _show_dashboard_calendar_event_popup(date_info: Dictionary, reports: Array, meetings: Array, index_reviews: Array) -> void:
	_ensure_dashboard_calendar_event_popup()
	if dashboard_calendar_event_popup == null:
		return
	if dashboard_calendar_event_title_label != null:
		dashboard_calendar_event_title_label.text = GameManager.format_trade_date(date_info)
	if dashboard_calendar_event_body_label != null:
		dashboard_calendar_event_body_label.text = _build_dashboard_calendar_event_popup_body(reports, meetings, index_reviews)
	_refresh_dashboard_calendar_event_actions(meetings)
	dashboard_calendar_event_popup.visible = true
	dashboard_calendar_event_popup.move_to_front()


func _hide_dashboard_calendar_event_popup() -> void:
	if dashboard_calendar_event_popup != null:
		dashboard_calendar_event_popup.visible = false


func _build_dashboard_calendar_event_popup_body(reports: Array, meetings: Array, index_reviews: Array) -> String:
	var lines: Array = []
	if not reports.is_empty():
		lines.append("Reports")
		for report_value in reports:
			var report: Dictionary = report_value
			var ticker: String = str(report.get("ticker", "")).strip_edges()
			var period_label: String = str(report.get("period_label", "")).strip_edges()
			if ticker.is_empty() and period_label.is_empty():
				continue
			lines.append("- %s %s" % [ticker, period_label])
	if not meetings.is_empty():
		if not lines.is_empty():
			lines.append("")
		lines.append("Meetings")
		for meeting_value in meetings:
			var meeting: Dictionary = meeting_value
			var meeting_line: String = "- %s | %s" % [
				str(meeting.get("ticker", "")).strip_edges(),
				str(meeting.get("meeting_label", "Meeting")).strip_edges()
			]
			var summary: String = str(meeting.get("public_summary", "")).strip_edges()
			if not summary.is_empty():
				meeting_line += "\n  %s" % summary
			lines.append(meeting_line)
	if not index_reviews.is_empty():
		if not lines.is_empty():
			lines.append("")
		lines.append("Index Reviews")
		for review_value in index_reviews:
			var review: Dictionary = review_value
			var review_line: String = "- %s | %s" % [
				str(review.get("provider_label", "Index")).strip_edges(),
				str(review.get("label", "Review")).strip_edges()
			]
			var summary: String = str(review.get("public_summary", "")).strip_edges()
			if not summary.is_empty():
				review_line += "\n  %s" % summary
			lines.append(review_line)
	if lines.is_empty():
		lines.append("No scheduled events.")
	return "\n".join(lines)


func _refresh_dashboard_calendar_event_actions(meetings: Array) -> void:
	if dashboard_calendar_event_actions_vbox == null:
		return
	_clear_container_children(dashboard_calendar_event_actions_vbox)
	for meeting_value in meetings:
		if typeof(meeting_value) != TYPE_DICTIONARY:
			continue
		var meeting: Dictionary = meeting_value
		var meeting_id: String = str(meeting.get("id", ""))
		if meeting_id.is_empty():
			continue
		var button := Button.new()
		button.name = "DashboardCalendarMeetingButton_%s" % meeting_id
		button.text = "Open %s  |  %s" % [
			str(meeting.get("meeting_label", "Meeting")),
			str(meeting.get("ticker", ""))
		]
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var blocked_reason: String = ""
		if (
			bool(meeting.get("interactive_v1", false)) and
			bool(meeting.get("requires_shareholder", false)) and
			not bool(meeting.get("attendance_eligible", true))
		):
			blocked_reason = str(meeting.get("attendance_blocked_reason", "Shareholder ownership is required to attend this meeting."))
		button.disabled = not blocked_reason.is_empty()
		button.tooltip_text = blocked_reason if not blocked_reason.is_empty() else str(meeting.get("public_summary", "Open meeting"))
		button.pressed.connect(func() -> void:
			_hide_dashboard_calendar_event_popup()
			_open_corporate_meeting_modal(meeting_id)
		)
		dashboard_calendar_event_actions_vbox.add_child(button)
		_style_button(button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)


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
		floori(float(adjusted_year) / 4.0) -
		floori(float(adjusted_year) / 100.0) +
		floori(float(adjusted_year) / 400.0) +
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
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_markets()
	stock_controller._sync_root_refs()
func _refresh_after_company_selection() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_after_company_selection()
	stock_controller._sync_root_refs()
func _on_company_detail_ready(company_id: String) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_company_detail_ready(company_id)
	stock_controller._sync_root_refs()
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
	if help_title_label != null:
		help_title_label.text = ""
		help_title_label.visible = false
	if help_text_label != null:
		help_text_label.text = ""
		help_text_label.visible = false
		help_text_label.custom_minimum_size = Vector2.ZERO


func _refresh_debug_overlay() -> void:
	_update_debug_generator_buttons_enabled(RunState.has_active_run())
	_refresh_debug_company_control_controls()
	_refresh_debug_corporate_action_controls()
	_refresh_debug_index_review_controls()
	_refresh_debug_company_roadmap_controls()
	_refresh_debug_life_development_controls()
	_refresh_debug_jail_controls()
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


func _is_console_toggle_key(key_event: InputEventKey) -> bool:
	if key_event.ctrl_pressed or key_event.alt_pressed or key_event.meta_pressed:
		return false
	return (
		int(key_event.keycode) == CONSOLE_TOGGLE_KEY_CODE or
		int(key_event.physical_keycode) == CONSOLE_TOGGLE_KEY_CODE or
		int(key_event.unicode) == CONSOLE_TOGGLE_KEY_CODE
	)


func _toggle_console_overlay() -> void:
	if console_overlay != null and console_overlay.visible:
		_hide_console_overlay()
		return
	_show_console_overlay()


func _show_console_overlay() -> void:
	_ensure_console_overlay()
	if console_overlay == null:
		return
	console_overlay.visible = true
	if console_input != null:
		console_input.clear()
		console_input.grab_focus()
	if console_status_label != null:
		console_status_label.text = "Type a command, then press Enter."


func _hide_console_overlay() -> void:
	if console_input != null:
		console_input.release_focus()
	if console_overlay != null:
		console_overlay.visible = false


func _on_console_command_submitted(command_text: String) -> void:
	var trimmed_command: String = command_text.strip_edges()
	if trimmed_command.is_empty():
		if console_status_label != null:
			console_status_label.text = "No command entered."
		return

	var result: Dictionary = GameManager.execute_console_command(trimmed_command)
	var message: String = str(result.get("message", "Command processed."))
	if console_status_label != null:
		console_status_label.text = message
	if console_input != null:
		console_input.clear()
		console_input.grab_focus()
	_show_toast(message, bool(result.get("success", false)))


func _build_debug_generator_controls() -> void:
	debug_generator_buttons.clear()
	debug_corporate_action_buttons.clear()
	debug_index_review_buttons.clear()
	debug_company_roadmap_buttons.clear()
	debug_life_development_buttons.clear()
	debug_start_rupslb_button = null
	debug_start_rupslb_status_label = null
	debug_index_review_status_label = null
	debug_company_control_button = null
	debug_company_control_status_label = null
	debug_company_roadmap_status_label = null
	debug_life_development_status_label = null
	debug_dirty_tip_button = null
	debug_jail_button = null
	debug_hospital_button = null
	debug_jail_status_label = null
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
	_build_debug_company_control_controls()
	_build_debug_corporate_action_controls()
	_build_debug_index_review_controls()
	_build_debug_company_roadmap_controls()
	_build_debug_life_development_controls()
	_build_debug_jail_controls()
	_refresh_debug_company_control_controls()
	_refresh_debug_corporate_action_controls()
	_refresh_debug_index_review_controls()
	_refresh_debug_company_roadmap_controls()
	_refresh_debug_life_development_controls()
	_refresh_debug_jail_controls()


func _update_debug_generator_buttons_enabled(is_enabled: bool) -> void:
	for button_value in debug_generator_buttons.values():
		var generator_button: Button = button_value as Button
		if generator_button == null:
			continue
		generator_button.disabled = not is_enabled
	for button_value in debug_corporate_action_buttons.values():
		var corporate_button: Button = button_value as Button
		if corporate_button == null:
			continue
		corporate_button.disabled = not is_enabled
	for button_value in debug_index_review_buttons.values():
		var index_button: Button = button_value as Button
		if index_button == null:
			continue
		index_button.disabled = not is_enabled
	for button_value in debug_company_roadmap_buttons.values():
		var roadmap_button: Button = button_value as Button
		if roadmap_button == null:
			continue
		roadmap_button.disabled = not is_enabled
	for button_value in debug_life_development_buttons.values():
		var life_button: Button = button_value as Button
		if life_button == null:
			continue
		life_button.disabled = not is_enabled
	if debug_company_control_button != null:
		debug_company_control_button.disabled = not is_enabled
	if debug_dirty_tip_button != null:
		debug_dirty_tip_button.disabled = not is_enabled
	if debug_jail_button != null:
		debug_jail_button.disabled = not is_enabled
	if debug_hospital_button != null:
		debug_hospital_button.disabled = not is_enabled


func _on_debug_generate_event_pressed(event_id: String) -> void:
	var result: Dictionary = GameManager.debug_generate_event(event_id)
	_show_toast(
		str(result.get("message", "Debug event updated.")),
		bool(result.get("success", false))
	)
	if bool(result.get("success", false)):
		_refresh_all()


func _build_debug_company_control_controls() -> void:
	if debug_generator_groups == null:
		return
	var group_label := Label.new()
	group_label.name = "DebugCompanyControlLabel"
	group_label.text = "Company App Control"
	group_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	_set_label_tone(group_label, COLOR_TEXT)
	debug_generator_groups.add_child(group_label)

	var status_label := Label.new()
	status_label.name = "DebugCompanyControlStatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_label_tone(status_label, COLOR_MUTED)
	debug_generator_groups.add_child(status_label)
	debug_company_control_status_label = status_label

	var hint_label := Label.new()
	hint_label.name = "DebugCompanyControlHintLabel"
	hint_label.text = "Uses the selected STOCKBOT stock. Grants enough shares to unlock majority-control Company tools without spending cash."
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.add_theme_font_size_override("font_size", 11)
	_set_label_tone(hint_label, COLOR_MUTED)
	debug_generator_groups.add_child(hint_label)

	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	debug_generator_groups.add_child(flow)

	var action_button := Button.new()
	action_button.name = "DebugCompanyControlButton"
	action_button.custom_minimum_size = Vector2(190, 34)
	action_button.text = "Own Selected Company"
	action_button.tooltip_text = "Grant enough shares to become the controlling shareholder."
	action_button.pressed.connect(_on_debug_company_control_pressed)
	_style_button(action_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	flow.add_child(action_button)
	debug_company_control_button = action_button


func _refresh_debug_company_control_controls() -> void:
	var state: Dictionary = _debug_company_control_status_state()
	if debug_company_control_status_label != null:
		debug_company_control_status_label.text = str(state.get("status_text", "Pick a stock first."))
	if debug_company_control_button != null:
		debug_company_control_button.disabled = not bool(state.get("enabled", false))
		debug_company_control_button.text = "Open Company App" if bool(state.get("already_controlled", false)) else "Own Selected Company"
		debug_company_control_button.tooltip_text = str(state.get("tooltip_text", "Grant enough shares to become the controlling shareholder."))


func _debug_company_control_status_state() -> Dictionary:
	if not RunState.has_active_run():
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "No active run. Start or load a run first.",
			"tooltip_text": "Start or load a run first."
		}
	if selected_company_id.is_empty():
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "Target: none | Pick a stock first.",
			"tooltip_text": "Select a stock in STOCKBOT first."
		}
	var definition: Dictionary = RunState.get_effective_company_definition(selected_company_id, false, false)
	if definition.is_empty():
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "Target: none | Pick a valid stock first.",
			"tooltip_text": "Select a valid stock in STOCKBOT first."
		}
	var ticker: String = str(definition.get("ticker", selected_company_id.to_upper()))
	var ownership: Dictionary = GameManager.get_company_ownership_snapshot(selected_company_id)
	var shares_owned: int = int(ownership.get("shares_owned", 0))
	var control_required_shares: int = int(ownership.get("control_required_shares", 0))
	if control_required_shares <= 0:
		return {
			"enabled": false,
			"company_id": selected_company_id,
			"ticker": ticker,
			"status_text": "Target: %s | No share structure available." % ticker,
			"tooltip_text": "This company cannot calculate majority ownership."
		}
	if bool(ownership.get("is_control_shareholder", false)):
		return {
			"enabled": true,
			"company_id": selected_company_id,
			"ticker": ticker,
			"already_controlled": true,
			"status_text": "Target: %s | Already controlled at %.2f%%. Button opens Company." % [
				ticker,
				float(ownership.get("ownership_pct", 0.0)) * 100.0
			],
			"tooltip_text": "Open the Company app for %s." % ticker
		}
	return {
		"enabled": true,
		"company_id": selected_company_id,
		"ticker": ticker,
		"already_controlled": false,
		"status_text": "Target: %s | Own %s / need %s shares for control (%s more)." % [
			ticker,
			_format_grouped_integer(shares_owned),
			_format_grouped_integer(control_required_shares),
			_format_grouped_integer(int(ownership.get("control_shares_needed", max(control_required_shares - shares_owned, 0))))
		],
		"tooltip_text": "Grant enough shares of %s to unlock Company majority-control tools." % ticker
	}


func _on_debug_company_control_pressed() -> void:
	var state: Dictionary = _debug_company_control_status_state()
	if not bool(state.get("enabled", false)):
		_show_toast(str(state.get("status_text", "Could not grant company control.")), false)
		_refresh_debug_company_control_controls()
		return
	var company_id: String = str(state.get("company_id", ""))
	var result: Dictionary = GameManager.debug_grant_company_control(company_id)
	var success: bool = bool(result.get("success", false))
	if not success:
		_show_toast(str(result.get("message", "Could not grant company control.")), false)
		_refresh_debug_overlay()
		return
	_invalidate_company_rows_cache()
	_refresh_header()
	_refresh_sidebar()
	_refresh_company_list([], {}, false, true)
	_refresh_trade_workspace_holdings_state()
	_refresh_trade_workspace()
	_refresh_portfolio()
	_refresh_company_app_availability()
	_refresh_company(company_id)
	_refresh_desktop()
	_set_active_app(APP_ID_COMPANY)
	_refresh_company(company_id)
	_show_toast(str(result.get("message", "Company control updated.")), true)


func _build_debug_corporate_action_controls() -> void:
	if debug_generator_groups == null:
		return
	var group_label := Label.new()
	group_label.name = "DebugCorporateActionsLabel"
	group_label.text = "Corporate Action Generator"
	group_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	_set_label_tone(group_label, COLOR_TEXT)
	debug_generator_groups.add_child(group_label)

	var status_label := Label.new()
	status_label.name = "DebugStartRupslbStatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_label_tone(status_label, COLOR_MUTED)
	debug_generator_groups.add_child(status_label)
	debug_start_rupslb_status_label = status_label

	var hint_label := Label.new()
	hint_label.name = "DebugCorporateActionsHintLabel"
	hint_label.text = "Uses the selected STOCKBOT stock. RUPSLB generators queue a meeting for the next trading day; execution generators jump a chain to its execution stage."
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.add_theme_font_size_override("font_size", 11)
	_set_label_tone(hint_label, COLOR_MUTED)
	debug_generator_groups.add_child(hint_label)

	for group_value in GameManager.get_debug_corporate_action_generator_catalog():
		if typeof(group_value) != TYPE_DICTIONARY:
			continue
		var action_group: Dictionary = group_value
		var generators: Array = action_group.get("generators", [])
		if generators.is_empty():
			continue

		var subgroup_label := Label.new()
		subgroup_label.text = str(action_group.get("label", "Corporate Actions"))
		subgroup_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		subgroup_label.add_theme_font_size_override("font_size", 11)
		_set_label_tone(subgroup_label, COLOR_TEXT)
		debug_generator_groups.add_child(subgroup_label)

		var flow := HFlowContainer.new()
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		debug_generator_groups.add_child(flow)

		for generator_value in generators:
			if typeof(generator_value) != TYPE_DICTIONARY:
				continue
			var generator: Dictionary = generator_value
			var generator_id: String = str(generator.get("id", ""))
			if generator_id.is_empty():
				continue
			var action_button := Button.new()
			action_button.name = "DebugCorporateActionButton%s" % _debug_node_suffix(generator_id)
			action_button.custom_minimum_size = Vector2(170, 34)
			action_button.text = str(generator.get("label", "Corporate Action"))
			action_button.tooltip_text = str(generator.get("description", "Generate a corporate action for the selected stock."))
			action_button.pressed.connect(_on_debug_corporate_action_pressed.bind(generator_id))
			_style_button(action_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
			flow.add_child(action_button)
			debug_corporate_action_buttons[generator_id] = action_button
			if generator_id == "rights_issue_rupslb":
				action_button.name = "DebugStartRupslbButton"
				debug_start_rupslb_button = action_button


func _debug_corporate_action_generator_definition(generator_id: String) -> Dictionary:
	for group_value in GameManager.get_debug_corporate_action_generator_catalog():
		if typeof(group_value) != TYPE_DICTIONARY:
			continue
		var group: Dictionary = group_value
		for generator_value in group.get("generators", []):
			if typeof(generator_value) != TYPE_DICTIONARY:
				continue
			var generator: Dictionary = generator_value
			if str(generator.get("id", "")) == generator_id:
				return generator.duplicate(true)
	return {}


func _debug_node_suffix(raw_id: String) -> String:
	var suffix: String = ""
	for part_value in raw_id.split("_", false):
		var part: String = str(part_value)
		if part.is_empty():
			continue
		suffix += part.substr(0, 1).to_upper() + part.substr(1)
	return suffix


func _refresh_debug_corporate_action_controls() -> void:
	if debug_start_rupslb_status_label == null and debug_corporate_action_buttons.is_empty():
		return
	var state: Dictionary = _debug_rupslb_target_state()
	if debug_start_rupslb_status_label != null:
		debug_start_rupslb_status_label.text = str(state.get("status_text", "Pick a stock first."))
	for generator_id_value in debug_corporate_action_buttons.keys():
		var generator_id: String = str(generator_id_value)
		var button: Button = debug_corporate_action_buttons.get(generator_id) as Button
		if button == null:
			continue
		var button_state: Dictionary = _debug_corporate_action_target_state(generator_id)
		button.disabled = not bool(button_state.get("enabled", false))
		button.tooltip_text = str(button_state.get("tooltip_text", "Generate a corporate action for the selected stock."))


func _debug_rupslb_target_state() -> Dictionary:
	return _debug_corporate_action_target_state("rights_issue_rupslb")


func _debug_corporate_action_target_state(generator_id: String) -> Dictionary:
	var generator: Dictionary = _debug_corporate_action_generator_definition(generator_id)
	if not RunState.has_active_run():
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "No active run. Start or load a run first.",
			"tooltip_text": "Start or load a run first."
		}
	if generator.is_empty():
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "Unknown corporate-action generator.",
			"tooltip_text": "Unknown corporate-action generator."
		}
	if selected_company_id.is_empty():
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "Target: none | Pick a stock first.",
			"tooltip_text": "Select a stock in STOCKBOT first."
		}
	var definition: Dictionary = RunState.get_effective_company_definition(selected_company_id, false, false)
	if definition.is_empty():
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "Target: none | Pick a stock first.",
			"tooltip_text": "Select a valid stock in STOCKBOT first."
		}
	var ticker: String = str(definition.get("ticker", selected_company_id.to_upper()))
	var holding: Dictionary = RunState.get_holding(selected_company_id)
	var lot_size: int = max(GameManager.get_lot_size(), 1)
	var shares: int = int(holding.get("shares", 0))
	var lots_owned: int = int(floor(float(shares) / float(lot_size)))
	if bool(generator.get("requires_holding", false)) and shares < lot_size:
		return {
			"enabled": false,
			"company_id": selected_company_id,
			"ticker": ticker,
			"status_text": "Target: %s | Own at least 1 lot first." % ticker,
			"tooltip_text": "Buy at least 1 lot of %s before using this RUPSLB generator." % ticker
		}
	var corporate_action_snapshot: Dictionary = GameManager.get_company_corporate_action_snapshot(selected_company_id)
	if bool(generator.get("requires_no_live_chain", false)) and bool(corporate_action_snapshot.get("has_live_chain", false)):
		return {
			"enabled": false,
			"company_id": selected_company_id,
			"ticker": ticker,
			"status_text": "Target: %s | That company already has a live corporate action." % ticker,
			"tooltip_text": "Finish or clear the current corporate-action chain before forcing another one."
		}
	var next_trade_date: Dictionary = portfolio_trading_calendar.advance_trade_days(GameManager.get_current_trade_date(), 1)
	var mode: String = str(generator.get("mode", "rupslb"))
	var action_label: String = str(generator.get("full_label", generator.get("label", "Corporate Action")))
	var status_text: String = "Target: %s | Generates %s." % [ticker, action_label]
	var tooltip_message: String = str(generator.get("description", "Generate a corporate action for the selected stock."))
	if mode == "rupslb":
		status_text = "Target: %s | Held %d lot(s) | Schedules %s for %s." % [
			ticker,
			lots_owned,
			action_label,
			GameManager.format_trade_date(next_trade_date)
		]
	elif mode == "execution":
		status_text = "Target: %s | Forces %s into execution." % [ticker, action_label]
	elif mode == "dividend":
		status_text = "Target: %s | Schedules %s." % [ticker, action_label]
	return {
		"enabled": true,
		"company_id": selected_company_id,
		"ticker": ticker,
		"status_text": status_text,
		"tooltip_text": tooltip_message
	}


func _on_debug_start_rupslb_pressed() -> void:
	_on_debug_corporate_action_pressed("rights_issue_rupslb")


func _on_debug_corporate_action_pressed(generator_id: String) -> void:
	var state: Dictionary = _debug_corporate_action_target_state(generator_id)
	if not bool(state.get("enabled", false)):
		_show_toast(str(state.get("status_text", "Could not generate corporate action.")), false)
		_refresh_debug_corporate_action_controls()
		return
	var company_id: String = str(state.get("company_id", ""))
	var result: Dictionary = GameManager.debug_generate_corporate_action(generator_id, company_id)
	_show_toast(str(result.get("message", "Debug corporate action updated.")), bool(result.get("success", false)))
	_refresh_debug_overlay()
	if not bool(result.get("success", false)):
		return
	_refresh_dashboard()
	_refresh_news()
	_refresh_network()
	_refresh_trade_workspace()


func _build_debug_index_review_controls() -> void:
	if debug_generator_groups == null:
		return
	var group_label := Label.new()
	group_label.name = "DebugIndexReviewsLabel"
	group_label.text = "Index Review Generator"
	group_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	_set_label_tone(group_label, COLOR_TEXT)
	debug_generator_groups.add_child(group_label)

	var status_label := Label.new()
	status_label.name = "DebugIndexReviewStatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_label_tone(status_label, COLOR_MUTED)
	debug_generator_groups.add_child(status_label)
	debug_index_review_status_label = status_label

	var hint_label := Label.new()
	hint_label.name = "DebugIndexReviewsHintLabel"
	hint_label.text = "Uses the selected STOCKBOT stock. Index generators create same-day MSCY/FTSI announcements and next-day effective passive flow."
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.add_theme_font_size_override("font_size", 11)
	_set_label_tone(hint_label, COLOR_MUTED)
	debug_generator_groups.add_child(hint_label)

	for group_value in GameManager.get_debug_index_review_generator_catalog():
		if typeof(group_value) != TYPE_DICTIONARY:
			continue
		var index_group: Dictionary = group_value
		var generators: Array = index_group.get("generators", [])
		if generators.is_empty():
			continue

		var subgroup_label := Label.new()
		subgroup_label.text = str(index_group.get("label", "Index Review"))
		subgroup_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		subgroup_label.add_theme_font_size_override("font_size", 11)
		_set_label_tone(subgroup_label, COLOR_TEXT)
		debug_generator_groups.add_child(subgroup_label)

		var flow := HFlowContainer.new()
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		debug_generator_groups.add_child(flow)

		for generator_value in generators:
			if typeof(generator_value) != TYPE_DICTIONARY:
				continue
			var generator: Dictionary = generator_value
			var generator_id: String = str(generator.get("id", ""))
			if generator_id.is_empty():
				continue
			var action_button := Button.new()
			action_button.name = "DebugIndexReviewButton%s" % _debug_node_suffix(generator_id)
			action_button.custom_minimum_size = Vector2(170, 34)
			action_button.text = str(generator.get("label", "Index Review"))
			action_button.tooltip_text = str(generator.get("description", "Generate an index review event for the selected stock."))
			action_button.pressed.connect(_on_debug_index_review_pressed.bind(generator_id))
			_style_button(action_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
			flow.add_child(action_button)
			debug_index_review_buttons[generator_id] = action_button


func _debug_index_review_generator_definition(generator_id: String) -> Dictionary:
	for group_value in GameManager.get_debug_index_review_generator_catalog():
		if typeof(group_value) != TYPE_DICTIONARY:
			continue
		var group: Dictionary = group_value
		for generator_value in group.get("generators", []):
			if typeof(generator_value) != TYPE_DICTIONARY:
				continue
			var generator: Dictionary = generator_value
			if str(generator.get("id", "")) == generator_id:
				return generator.duplicate(true)
	return {}


func _refresh_debug_index_review_controls() -> void:
	if debug_index_review_status_label != null:
		debug_index_review_status_label.text = str(_debug_index_review_status_state().get("status_text", "Pick a stock first."))
	for generator_id_value in debug_index_review_buttons.keys():
		var generator_id: String = str(generator_id_value)
		var button: Button = debug_index_review_buttons.get(generator_id) as Button
		if button == null:
			continue
		var button_state: Dictionary = _debug_index_review_target_state(generator_id)
		button.disabled = not bool(button_state.get("enabled", false))
		button.tooltip_text = str(button_state.get("tooltip_text", "Generate an index review event for the selected stock."))


func _debug_index_review_status_state() -> Dictionary:
	if not RunState.has_active_run():
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "No active run. Start or load a run first."
		}
	if debug_index_review_buttons.is_empty():
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "No index-review debug providers are loaded."
		}
	if selected_company_id.is_empty():
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "Target: none | Pick a stock first."
		}
	var definition: Dictionary = RunState.get_effective_company_definition(selected_company_id, false, false)
	if definition.is_empty():
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "Target: none | Pick a valid stock first."
		}
	var ticker: String = str(definition.get("ticker", selected_company_id.to_upper()))
	var company_index_snapshot: Dictionary = GameManager.get_company_index_review_snapshot(selected_company_id)
	var status_suffix: String = str(company_index_snapshot.get("summary_label", "No MSCY/FTSI membership"))
	return {
		"enabled": true,
		"company_id": selected_company_id,
		"ticker": ticker,
		"status_text": "Target: %s | %s | Buttons force MSCY/FTSI inclusion or exclusion." % [ticker, status_suffix]
	}


func _debug_index_review_target_state(generator_id: String) -> Dictionary:
	var generator: Dictionary = _debug_index_review_generator_definition(generator_id)
	if not RunState.has_active_run():
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "No active run. Start or load a run first.",
			"tooltip_text": "Start or load a run first."
		}
	if generator.is_empty():
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "Unknown index-review generator.",
			"tooltip_text": "Unknown index-review generator."
		}
	if selected_company_id.is_empty():
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "Target: none | Pick a stock first.",
			"tooltip_text": "Select a stock in STOCKBOT first."
		}
	var definition: Dictionary = RunState.get_effective_company_definition(selected_company_id, false, false)
	if definition.is_empty():
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "Target: none | Pick a valid stock first.",
			"tooltip_text": "Select a valid stock in STOCKBOT first."
		}
	var ticker: String = str(definition.get("ticker", selected_company_id.to_upper()))
	var company_index_snapshot: Dictionary = GameManager.get_company_index_review_snapshot(selected_company_id)
	var provider_label: String = str(generator.get("label", "Index Review")).split(" ")[0]
	var status_suffix: String = str(company_index_snapshot.get("summary_label", "No MSCY/FTSI membership"))
	return {
		"enabled": true,
		"company_id": selected_company_id,
		"ticker": ticker,
		"status_text": "Target: %s | %s | %s." % [ticker, provider_label, status_suffix],
		"tooltip_text": str(generator.get("description", "Generate an index review event for the selected stock."))
	}


func _on_debug_index_review_pressed(generator_id: String) -> void:
	var state: Dictionary = _debug_index_review_target_state(generator_id)
	if not bool(state.get("enabled", false)):
		_show_toast(str(state.get("status_text", "Could not generate index review.")), false)
		_refresh_debug_index_review_controls()
		return
	var company_id: String = str(state.get("company_id", ""))
	var result: Dictionary = GameManager.debug_generate_index_review(generator_id, company_id)
	_show_toast(str(result.get("message", "Debug index review updated.")), bool(result.get("success", false)))
	_refresh_debug_overlay()
	if not bool(result.get("success", false)):
		return
	_refresh_dashboard()
	_refresh_news()
	_refresh_social()
	_refresh_trade_workspace()


func _build_debug_company_roadmap_controls() -> void:
	if debug_generator_groups == null:
		return
	var group_label := Label.new()
	group_label.name = "DebugCompanyRoadmapLabel"
	group_label.text = "Company Roadmap Generator"
	group_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	_set_label_tone(group_label, COLOR_TEXT)
	debug_generator_groups.add_child(group_label)

	var status_label := Label.new()
	status_label.name = "DebugCompanyRoadmapStatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_label_tone(status_label, COLOR_MUTED)
	debug_generator_groups.add_child(status_label)
	debug_company_roadmap_status_label = status_label

	var hint_label := Label.new()
	hint_label.name = "DebugCompanyRoadmapHintLabel"
	hint_label.text = "Uses the selected STOCKBOT stock. Roadmap generators create company-life milestones, possible finance partners, and physical project metadata for property intel."
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.add_theme_font_size_override("font_size", 11)
	_set_label_tone(hint_label, COLOR_MUTED)
	debug_generator_groups.add_child(hint_label)

	for group_value in GameManager.get_debug_company_roadmap_generator_catalog():
		if typeof(group_value) != TYPE_DICTIONARY:
			continue
		var roadmap_group: Dictionary = group_value
		var generators: Array = roadmap_group.get("generators", [])
		if generators.is_empty():
			continue

		var subgroup_label := Label.new()
		subgroup_label.text = str(roadmap_group.get("label", "Company Roadmap"))
		subgroup_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		subgroup_label.add_theme_font_size_override("font_size", 11)
		_set_label_tone(subgroup_label, COLOR_TEXT)
		debug_generator_groups.add_child(subgroup_label)

		var flow := HFlowContainer.new()
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		debug_generator_groups.add_child(flow)

		for generator_value in generators:
			if typeof(generator_value) != TYPE_DICTIONARY:
				continue
			var generator: Dictionary = generator_value
			var generator_id: String = str(generator.get("id", ""))
			if generator_id.is_empty():
				continue
			var action_button := Button.new()
			action_button.name = "DebugCompanyRoadmapButton%s" % _debug_node_suffix(generator_id)
			action_button.custom_minimum_size = Vector2(170, 34)
			action_button.text = str(generator.get("label", "Roadmap"))
			action_button.tooltip_text = str(generator.get("description", "Generate a roadmap milestone for the selected stock."))
			action_button.pressed.connect(_on_debug_company_roadmap_pressed.bind(generator_id))
			_style_button(action_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
			flow.add_child(action_button)
			debug_company_roadmap_buttons[generator_id] = action_button


func _debug_company_roadmap_generator_definition(generator_id: String) -> Dictionary:
	for group_value in GameManager.get_debug_company_roadmap_generator_catalog():
		if typeof(group_value) != TYPE_DICTIONARY:
			continue
		var group: Dictionary = group_value
		for generator_value in group.get("generators", []):
			if typeof(generator_value) != TYPE_DICTIONARY:
				continue
			var generator: Dictionary = generator_value
			if str(generator.get("id", "")) == generator_id:
				return generator.duplicate(true)
	return {}


func _refresh_debug_company_roadmap_controls() -> void:
	if debug_company_roadmap_status_label != null:
		debug_company_roadmap_status_label.text = str(_debug_company_roadmap_status_state().get("status_text", "Pick a stock first."))
	for generator_id_value in debug_company_roadmap_buttons.keys():
		var generator_id: String = str(generator_id_value)
		var button: Button = debug_company_roadmap_buttons.get(generator_id) as Button
		if button == null:
			continue
		var button_state: Dictionary = _debug_company_roadmap_target_state(generator_id)
		button.disabled = not bool(button_state.get("enabled", false))
		button.tooltip_text = str(button_state.get("tooltip_text", "Generate a roadmap milestone for the selected stock."))


func _debug_company_roadmap_status_state() -> Dictionary:
	if not RunState.has_active_run():
		return {"enabled": false, "company_id": "", "status_text": "No active run. Start or load a run first."}
	if selected_company_id.is_empty():
		return {"enabled": false, "company_id": "", "status_text": "Target: none | Pick a stock first."}
	var definition: Dictionary = RunState.get_effective_company_definition(selected_company_id, false, false)
	if definition.is_empty():
		return {"enabled": false, "company_id": "", "status_text": "Target: none | Pick a valid stock first."}
	var ticker: String = str(definition.get("ticker", selected_company_id.to_upper()))
	var roadmap_profile: Dictionary = definition.get("roadmap_profile", {})
	var priority: String = str(roadmap_profile.get("public_priority", roadmap_profile.get("primary_family_label", "roadmap priority")))
	if _debug_company_has_active_roadmap(selected_company_id):
		return {"enabled": false, "company_id": selected_company_id, "status_text": "Target: %s | Active roadmap milestone already running." % ticker}
	return {
		"enabled": true,
		"company_id": selected_company_id,
		"ticker": ticker,
		"status_text": "Target: %s | Priority: %s." % [ticker, priority]
	}


func _debug_company_roadmap_target_state(generator_id: String) -> Dictionary:
	var generator: Dictionary = _debug_company_roadmap_generator_definition(generator_id)
	var base_state: Dictionary = _debug_company_roadmap_status_state()
	if not bool(base_state.get("enabled", false)):
		return {
			"enabled": false,
			"company_id": str(base_state.get("company_id", "")),
			"status_text": str(base_state.get("status_text", "Pick a stock first.")),
			"tooltip_text": str(base_state.get("status_text", "Pick a stock first."))
		}
	if generator.is_empty():
		return {"enabled": false, "company_id": "", "status_text": "Unknown roadmap generator.", "tooltip_text": "Unknown roadmap generator."}
	var ticker: String = str(base_state.get("ticker", "stock"))
	return {
		"enabled": true,
		"company_id": str(base_state.get("company_id", selected_company_id)),
		"ticker": ticker,
		"status_text": "Target: %s | Generates %s." % [ticker, str(generator.get("full_label", generator.get("label", "roadmap milestone")))],
		"tooltip_text": str(generator.get("description", "Generate a roadmap milestone for the selected stock."))
	}


func _debug_company_has_active_roadmap(company_id: String) -> bool:
	for milestone_value in RunState.get_company_roadmap_state().get("active_milestones", {}).values():
		if typeof(milestone_value) != TYPE_DICTIONARY:
			continue
		var milestone: Dictionary = milestone_value
		if str(milestone.get("company_id", "")) == company_id or str(milestone.get("finance_company_id", "")) == company_id:
			return true
	return false


func _on_debug_company_roadmap_pressed(generator_id: String) -> void:
	var state: Dictionary = _debug_company_roadmap_target_state(generator_id)
	if not bool(state.get("enabled", false)):
		_show_toast(str(state.get("status_text", "Could not generate roadmap milestone.")), false)
		_refresh_debug_company_roadmap_controls()
		return
	var company_id: String = str(state.get("company_id", ""))
	var result: Dictionary = GameManager.debug_generate_company_roadmap(generator_id, company_id)
	_show_toast(str(result.get("message", "Debug roadmap updated.")), bool(result.get("success", false)))
	_refresh_debug_overlay()
	if not bool(result.get("success", false)):
		return
	_refresh_dashboard()
	_refresh_news()
	_refresh_network()
	_refresh_trade_workspace()


func _build_debug_life_development_controls() -> void:
	if debug_generator_groups == null:
		return
	var group_label := Label.new()
	group_label.name = "DebugLifeDevelopmentLabel"
	group_label.text = "Life Property Intel Generator"
	group_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	_set_label_tone(group_label, COLOR_TEXT)
	debug_generator_groups.add_child(group_label)

	var status_label := Label.new()
	status_label.name = "DebugLifeDevelopmentStatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_label_tone(status_label, COLOR_MUTED)
	debug_generator_groups.add_child(status_label)
	debug_life_development_status_label = status_label

	var hint_label := Label.new()
	hint_label.name = "DebugLifeDevelopmentHintLabel"
	hint_label.text = "Creates save-backed Life property watches. These are useful for checking property rows, article copy, and delayed/cancelled/confirmed outcomes."
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.add_theme_font_size_override("font_size", 11)
	_set_label_tone(hint_label, COLOR_MUTED)
	debug_generator_groups.add_child(hint_label)

	for group_value in GameManager.get_debug_life_development_generator_catalog():
		if typeof(group_value) != TYPE_DICTIONARY:
			continue
		var life_group: Dictionary = group_value
		var generators: Array = life_group.get("generators", [])
		if generators.is_empty():
			continue
		var subgroup_label := Label.new()
		subgroup_label.text = str(life_group.get("label", "Life Property Intel"))
		subgroup_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		subgroup_label.add_theme_font_size_override("font_size", 11)
		_set_label_tone(subgroup_label, COLOR_TEXT)
		debug_generator_groups.add_child(subgroup_label)
		var flow := HFlowContainer.new()
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		debug_generator_groups.add_child(flow)
		for generator_value in generators:
			if typeof(generator_value) != TYPE_DICTIONARY:
				continue
			var generator: Dictionary = generator_value
			var generator_id: String = str(generator.get("id", ""))
			if generator_id.is_empty():
				continue
			var action_button := Button.new()
			action_button.name = "DebugLifeDevelopmentButton%s" % _debug_node_suffix(generator_id)
			action_button.custom_minimum_size = Vector2(170, 34)
			action_button.text = str(generator.get("label", "Property Intel"))
			action_button.tooltip_text = str(generator.get("description", "Generate a Life property watch."))
			action_button.pressed.connect(_on_debug_life_development_pressed.bind(generator_id))
			_style_button(action_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
			flow.add_child(action_button)
			debug_life_development_buttons[generator_id] = action_button


func _refresh_debug_life_development_controls() -> void:
	var status_text: String = "Ready to generate Life property intel." if RunState.has_active_run() else "No active run. Start or load a run first."
	if debug_life_development_status_label != null:
		debug_life_development_status_label.text = status_text
	for button_value in debug_life_development_buttons.values():
		var button: Button = button_value as Button
		if button != null:
			button.disabled = not RunState.has_active_run()


func _on_debug_life_development_pressed(generator_id: String) -> void:
	if not RunState.has_active_run():
		_show_toast("No active run.", false)
		_refresh_debug_life_development_controls()
		return
	var result: Dictionary = GameManager.debug_generate_life_development(generator_id)
	_show_toast(str(result.get("message", "Debug property intel updated.")), bool(result.get("success", false)))
	_refresh_debug_overlay()
	if not bool(result.get("success", false)):
		return
	_refresh_life()
	_refresh_news()
	_refresh_network()


func _build_debug_jail_controls() -> void:
	if debug_generator_groups == null:
		return
	var group_label := Label.new()
	group_label.name = "DebugJailGeneratorLabel"
	group_label.text = "Dirty Tip / Lock State Generators"
	group_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	_set_label_tone(group_label, COLOR_TEXT)
	debug_generator_groups.add_child(group_label)

	var status_label := Label.new()
	status_label.name = "DebugJailGeneratorStatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_label_tone(status_label, COLOR_MUTED)
	debug_generator_groups.add_child(status_label)
	debug_jail_status_label = status_label

	var hint_label := Label.new()
	hint_label.name = "DebugJailGeneratorHintLabel"
	hint_label.text = "Force Dirty Tip opens the normal Market Room offer for the selected STOCKBOT stock. Force Jail resolves a caught case. Force Hospital sets stress to 100 and starts recovery."
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.add_theme_font_size_override("font_size", 11)
	_set_label_tone(hint_label, COLOR_MUTED)
	debug_generator_groups.add_child(hint_label)

	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	debug_generator_groups.add_child(flow)

	var dirty_tip_button := Button.new()
	dirty_tip_button.name = "DebugForceDirtyTipButton"
	dirty_tip_button.custom_minimum_size = Vector2(190, 34)
	dirty_tip_button.text = "Force Dirty Tip"
	dirty_tip_button.tooltip_text = "Force a Dirty Tip offer and show the Market Room modal."
	dirty_tip_button.pressed.connect(_on_debug_force_dirty_tip_pressed)
	_style_button(dirty_tip_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	flow.add_child(dirty_tip_button)
	debug_dirty_tip_button = dirty_tip_button

	var action_button := Button.new()
	action_button.name = "DebugForceJailButton"
	action_button.custom_minimum_size = Vector2(190, 34)
	action_button.text = "Force Jail"
	action_button.tooltip_text = "Force a caught Dirty Tip case and legal hold."
	action_button.pressed.connect(_on_debug_force_jail_pressed)
	_style_button(action_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	flow.add_child(action_button)
	debug_jail_button = action_button

	var hospital_button := Button.new()
	hospital_button.name = "DebugForceHospitalButton"
	hospital_button.custom_minimum_size = Vector2(190, 34)
	hospital_button.text = "Force Hospital"
	hospital_button.tooltip_text = "Set stress to 100 and start hospital recovery."
	hospital_button.pressed.connect(_on_debug_force_hospital_pressed)
	_style_button(hospital_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	flow.add_child(hospital_button)
	debug_hospital_button = hospital_button


func _refresh_debug_jail_controls() -> void:
	var dirty_tip_state: Dictionary = _debug_dirty_tip_status_state()
	var state: Dictionary = _debug_jail_status_state()
	var hospital_state: Dictionary = _debug_hospital_status_state()
	if debug_jail_status_label != null:
		debug_jail_status_label.text = "%s\n%s\n%s" % [
			str(dirty_tip_state.get("status_text", "Ready to force a Dirty Tip offer.")),
			str(state.get("status_text", "Ready to force a jail state.")),
			str(hospital_state.get("status_text", "Ready to force a hospital state."))
		]
	if debug_dirty_tip_button != null:
		debug_dirty_tip_button.disabled = not bool(dirty_tip_state.get("enabled", false))
		debug_dirty_tip_button.tooltip_text = str(dirty_tip_state.get("tooltip_text", dirty_tip_state.get("status_text", "Force a Dirty Tip offer.")))
	if debug_jail_button != null:
		debug_jail_button.disabled = not bool(state.get("enabled", false))
		debug_jail_button.tooltip_text = str(state.get("tooltip_text", state.get("status_text", "Force a jail state.")))
	if debug_hospital_button != null:
		debug_hospital_button.disabled = not bool(hospital_state.get("enabled", false))
		debug_hospital_button.tooltip_text = str(hospital_state.get("tooltip_text", hospital_state.get("status_text", "Force a hospital state.")))


func _debug_dirty_tip_status_state() -> Dictionary:
	if not RunState.has_active_run():
		return {"enabled": false, "company_id": "", "status_text": "Dirty Tip: no active run.", "tooltip_text": "Start or load a run first."}
	var life_state: Dictionary = RunState.get_player_life()
	var legal_state: Dictionary = life_state.get("legal_state", {}) if typeof(life_state.get("legal_state", {})) == TYPE_DICTIONARY else {}
	if bool(legal_state.get("active", false)) and int(legal_state.get("days_remaining", 0)) > 0:
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "Dirty Tip: legal hold already active.",
			"tooltip_text": "Advance days to clear the current legal hold before forcing a Dirty Tip."
		}
	var hospital_days: int = int(life_state.get("hospital_days_remaining", 0))
	if hospital_days > 0:
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "Dirty Tip: hospital recovery active.",
			"tooltip_text": "Advance days to clear hospital recovery before forcing a Dirty Tip."
		}
	for request_value in RunState.get_network_requests().values():
		if typeof(request_value) != TYPE_DICTIONARY:
			continue
		var request: Dictionary = request_value
		if str(request.get("request_type", "")) == "dirty_tip" and str(request.get("status", "")) in ["offered", "accepted"]:
			return {
				"enabled": false,
				"company_id": "",
				"status_text": "Dirty Tip already open: %s is %s." % [
					str(request.get("target_ticker", "target")),
					str(request.get("status", "open"))
				],
				"tooltip_text": "Resolve or advance the current Dirty Tip before forcing another."
			}
	var company_id: String = selected_company_id
	if company_id.is_empty() and not RunState.company_order.is_empty():
		company_id = str(RunState.company_order[0])
	if company_id.is_empty():
		return {"enabled": false, "company_id": "", "status_text": "Dirty Tip: no stock universe is loaded yet."}
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	if definition.is_empty():
		return {"enabled": false, "company_id": "", "status_text": "Dirty Tip: pick a valid stock first."}
	var ticker: String = str(definition.get("ticker", company_id.to_upper()))
	return {
		"enabled": true,
		"company_id": company_id,
		"ticker": ticker,
		"status_text": "Dirty Tip target: %s | Opens Market Room offer." % ticker,
		"tooltip_text": "Force a Dirty Tip offer on %s and show the Market Room modal." % ticker
	}


func _debug_jail_status_state() -> Dictionary:
	if not RunState.has_active_run():
		return {"enabled": false, "company_id": "", "status_text": "No active run. Start or load a run first."}
	var life_state: Dictionary = RunState.get_player_life()
	var legal_state: Dictionary = life_state.get("legal_state", {}) if typeof(life_state.get("legal_state", {})) == TYPE_DICTIONARY else {}
	if bool(legal_state.get("active", false)) and int(legal_state.get("days_remaining", 0)) > 0:
		return {
			"enabled": false,
			"company_id": "",
			"status_text": "Legal hold already active: %d day(s) remaining." % int(legal_state.get("days_remaining", 0)),
			"tooltip_text": "Advance days to clear the current legal hold before forcing another."
		}
	var company_id: String = selected_company_id
	if company_id.is_empty() and not RunState.company_order.is_empty():
		company_id = str(RunState.company_order[0])
	if company_id.is_empty():
		return {"enabled": false, "company_id": "", "status_text": "No stock universe is loaded yet."}
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	if definition.is_empty():
		return {"enabled": false, "company_id": "", "status_text": "Pick a valid stock first."}
	var ticker: String = str(definition.get("ticker", company_id.to_upper()))
	return {
		"enabled": true,
		"company_id": company_id,
		"ticker": ticker,
		"status_text": "Target: %s | Forces caught Dirty Tip legal hold." % ticker,
		"tooltip_text": "Force a caught Dirty Tip case on %s and apply the normal jail/legal state." % ticker
	}


func _debug_hospital_status_state() -> Dictionary:
	if not RunState.has_active_run():
		return {"enabled": false, "status_text": "Hospital: no active run.", "tooltip_text": "Start or load a run first."}
	var life_state: Dictionary = RunState.get_player_life()
	var legal_state: Dictionary = life_state.get("legal_state", {}) if typeof(life_state.get("legal_state", {})) == TYPE_DICTIONARY else {}
	if bool(legal_state.get("active", false)) and int(legal_state.get("days_remaining", 0)) > 0:
		return {
			"enabled": false,
			"status_text": "Hospital: clear the active legal hold before forcing hospital.",
			"tooltip_text": "Advance days until the legal hold is released, then force hospital."
		}
	var hospital_days: int = int(life_state.get("hospital_days_remaining", 0))
	if hospital_days > 0:
		return {
			"enabled": false,
			"status_text": "Hospital already active: %d day(s) remaining." % hospital_days,
			"tooltip_text": "Advance days to clear the current hospital recovery."
		}
	return {
		"enabled": true,
		"status_text": "Hospital: sets Stress to 100 and starts recovery.",
		"tooltip_text": "Set stress to 100 and start the hospital recovery lock screen."
	}


func _on_debug_force_dirty_tip_pressed() -> void:
	var state: Dictionary = _debug_dirty_tip_status_state()
	if not bool(state.get("enabled", false)):
		_show_toast(str(state.get("status_text", "Could not force Dirty Tip offer.")), false)
		_refresh_debug_jail_controls()
		return
	var company_id: String = str(state.get("company_id", ""))
	var result: Dictionary = GameManager.debug_force_dirty_tip_offer(company_id)
	_show_toast(str(result.get("message", "Debug Dirty Tip updated.")), bool(result.get("success", false)))
	_refresh_debug_overlay()
	if not bool(result.get("success", false)):
		return
	for offer_value in result.get("offers", []):
		if typeof(offer_value) != TYPE_DICTIONARY:
			continue
		var offer: Dictionary = offer_value
		if str(offer.get("request_type", "")) != "dirty_tip" or str(offer.get("status", "")) != "offered":
			continue
		pending_dirty_tip_alerts.append(offer.duplicate(true))
	call_deferred("_show_next_dirty_tip_alert")
	_refresh_desktop()
	_refresh_network()


func _on_debug_force_jail_pressed() -> void:
	var state: Dictionary = _debug_jail_status_state()
	if not bool(state.get("enabled", false)):
		_show_toast(str(state.get("status_text", "Could not force jail state.")), false)
		_refresh_debug_jail_controls()
		return
	var company_id: String = str(state.get("company_id", ""))
	var result: Dictionary = GameManager.debug_force_dirty_tip_jail(company_id)
	_show_toast(str(result.get("message", "Debug jail updated.")), bool(result.get("success", false)))
	_refresh_debug_overlay()
	if not bool(result.get("success", false)):
		return
	_refresh_header()
	_refresh_desktop()
	_refresh_life()
	_refresh_network()
	_refresh_portfolio()
	_refresh_trade_workspace()
	_refresh_hospital_overlay()
	_refresh_jail_overlay()


func _on_debug_force_hospital_pressed() -> void:
	var state: Dictionary = _debug_hospital_status_state()
	if not bool(state.get("enabled", false)):
		_show_toast(str(state.get("status_text", "Could not force hospital state.")), false)
		_refresh_debug_jail_controls()
		return
	var result: Dictionary = GameManager.debug_force_hospital_stress()
	_show_toast(str(result.get("message", "Debug hospital updated.")), bool(result.get("success", false)))
	_refresh_debug_overlay()
	if not bool(result.get("success", false)):
		return
	_refresh_header()
	_refresh_desktop()
	_refresh_life()
	_refresh_trade_workspace()
	_refresh_hospital_overlay()
	_refresh_jail_overlay()


func _build_contact_intel_controls() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._build_contact_intel_controls()
	stock_controller._sync_root_refs()
func _refresh_contact_intel_controls() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_contact_intel_controls()
	stock_controller._sync_root_refs()
func _selected_contact_intel_contact_id() -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._selected_contact_intel_contact_id()
	stock_controller._sync_root_refs()
	return result
func _on_contact_intel_pressed() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_contact_intel_pressed()
	stock_controller._sync_root_refs()
func _sync_selected_company_with_active_stock_list() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._sync_selected_company_with_active_stock_list()
	stock_controller._sync_root_refs()
func _build_watchlist_lookup(watchlist_company_ids: Array = []) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._build_watchlist_lookup(watchlist_company_ids)
	stock_controller._sync_root_refs()
	return result
func _refresh_company_list(
	company_rows: Array = [],
	company_row_lookup: Dictionary = {},
	refresh_all_stock_rows: bool = true,
	refresh_portfolio_sidebar: bool = true
) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_company_list(company_rows, company_row_lookup, refresh_all_stock_rows, refresh_portfolio_sidebar)
	stock_controller._sync_root_refs()
func _should_refresh_all_stock_rows() -> bool:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: bool = stock_controller._should_refresh_all_stock_rows()
	stock_controller._sync_root_refs()
	return result
func _should_refresh_portfolio_stock_rows() -> bool:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: bool = stock_controller._should_refresh_portfolio_stock_rows()
	stock_controller._sync_root_refs()
	return result
func _refresh_watchlist_rows(company_rows: Array, watchlist_lookup: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_watchlist_rows(company_rows, watchlist_lookup)
	stock_controller._sync_root_refs()
func _get_watchlist_row_metadata(item_index: int) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._get_watchlist_row_metadata(item_index)
	stock_controller._sync_root_refs()
	return result
func _style_watchlist_row_item(item_index: int, row: Dictionary, is_selected: bool) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._style_watchlist_row_item(item_index, row, is_selected)
	stock_controller._sync_root_refs()
func _refresh_all_stock_watchlist_button_states(watchlist_lookup: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_all_stock_watchlist_button_states(watchlist_lookup)
	stock_controller._sync_root_refs()
func _refresh_all_stock_rows(company_rows: Array, watchlist_lookup: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_all_stock_rows(company_rows, watchlist_lookup)
	stock_controller._sync_root_refs()
func _matches_all_stock_search(row: Dictionary, search_query: String) -> bool:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: bool = stock_controller._matches_all_stock_search(row, search_query)
	stock_controller._sync_root_refs()
	return result
func _refresh_portfolio_stock_rows(holdings: Array, company_row_lookup: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_portfolio_stock_rows(holdings, company_row_lookup)
	stock_controller._sync_root_refs()
func _refresh_company_selection_state() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_company_selection_state()
	stock_controller._sync_root_refs()
func _refresh_watchlist_action_state(watchlist_lookup: Dictionary = {}) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_watchlist_action_state(watchlist_lookup)
	stock_controller._sync_root_refs()
func _build_stock_list_line(row: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._build_stock_list_line(row)
	stock_controller._sync_root_refs()
	return result
func _get_portfolio_company_ids() -> Array:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Array = stock_controller._get_portfolio_company_ids()
	stock_controller._sync_root_refs()
	return result
func _prioritized_company_detail_ids() -> Array:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Array = stock_controller._prioritized_company_detail_ids()
	stock_controller._sync_root_refs()
	return result
func _start_background_company_detail_hydration() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._start_background_company_detail_hydration()
	stock_controller._sync_root_refs()
func _start_background_company_detail_hydration_after_startup() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._start_background_company_detail_hydration_after_startup()
	stock_controller._sync_root_refs()
func _request_selected_company_detail(priority: bool = true) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._request_selected_company_detail(priority)
	stock_controller._sync_root_refs()
func _refresh_trade_workspace() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_trade_workspace()
	stock_controller._sync_root_refs()
func _refresh_trade_workspace_holdings_state() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_trade_workspace_holdings_state()
	stock_controller._sync_root_refs()
func _apply_trade_workspace_snapshot(snapshot: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._apply_trade_workspace_snapshot(snapshot)
	stock_controller._sync_root_refs()
func _reset_trade_workspace_detail_caches() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._reset_trade_workspace_detail_caches()
	stock_controller._sync_root_refs()
func _trade_workspace_active_tab_name() -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._trade_workspace_active_tab_name()
	stock_controller._sync_root_refs()
	return result
func _refresh_visible_trade_workspace_tab() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_visible_trade_workspace_tab()
	stock_controller._sync_root_refs()
func _refresh_trade_workspace_corporate_action_timeline(force_refresh: bool = false) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_trade_workspace_corporate_action_timeline(force_refresh)
	stock_controller._sync_root_refs()
func _ensure_profile_company_layout() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._ensure_profile_company_layout()
	stock_controller._sync_root_refs()
func _build_profile_card(card_name: String) -> PanelContainer:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: PanelContainer = stock_controller._build_profile_card(card_name)
	stock_controller._sync_root_refs()
	return result
func _build_profile_title_label(text_value: String) -> Label:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Label = stock_controller._build_profile_title_label(text_value)
	stock_controller._sync_root_refs()
	return result
func _build_profile_body_label(text_value: String, color: Color) -> Label:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Label = stock_controller._build_profile_body_label(text_value, color)
	stock_controller._sync_root_refs()
	return result
func _style_profile_company_layout() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._style_profile_company_layout()
	stock_controller._sync_root_refs()
func _refresh_profile_company_layout(snapshot: Dictionary, detail_ready: bool) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_profile_company_layout(snapshot, detail_ready)
	stock_controller._sync_root_refs()
func _refresh_profile_tags(tags: Array) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_profile_tags(tags)
	stock_controller._sync_root_refs()
func _build_profile_tag_pill(tag_text: String) -> PanelContainer:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: PanelContainer = stock_controller._build_profile_tag_pill(tag_text)
	stock_controller._sync_root_refs()
	return result
func _refresh_profile_shareholder_table(snapshot: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_profile_shareholder_table(snapshot)
	stock_controller._sync_root_refs()
func _refresh_profile_management_table(snapshot: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_profile_management_table(snapshot)
	stock_controller._sync_root_refs()
func _build_profile_table_row(
	cells: Array,
	widths: Array,
	header: bool,
	right_aligned_columns: Array = [],
	capture_payload: Dictionary = {}
) -> Control:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Control = stock_controller._build_profile_table_row(cells, widths, header, right_aligned_columns, capture_payload)
	stock_controller._sync_root_refs()
	return result
func _on_profile_background_gui_input(event: InputEvent) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_profile_background_gui_input(event)
	stock_controller._sync_root_refs()
func _profile_shareholder_capture_payload(row: Dictionary, ownership_pct: float, shares_outstanding: float) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._profile_shareholder_capture_payload(row, ownership_pct, shares_outstanding)
	stock_controller._sync_root_refs()
	return result
func _profile_management_capture_payload(management: Dictionary, network_state: String) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._profile_management_capture_payload(management, network_state)
	stock_controller._sync_root_refs()
	return result
func _on_profile_capture_row_gui_input(event: InputEvent, capture_payload: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_profile_capture_row_gui_input(event, capture_payload)
	stock_controller._sync_root_refs()
func _show_profile_capture_menu(menu_position: Vector2) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._show_profile_capture_menu(menu_position)
	stock_controller._sync_root_refs()
func _on_profile_capture_menu_id_pressed(id: int) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_profile_capture_menu_id_pressed(id)
	stock_controller._sync_root_refs()
func _build_profile_empty_row(message: String) -> Control:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Control = stock_controller._build_profile_empty_row(message)
	stock_controller._sync_root_refs()
	return result
func _build_profile_background_text(snapshot: Dictionary, detail_ready: bool) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._build_profile_background_text(snapshot, detail_ready)
	stock_controller._sync_root_refs()
	return result
func _profile_scale_sentence(snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._profile_scale_sentence(snapshot)
	stock_controller._sync_root_refs()
	return result
func _profile_footprint_sentence(snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._profile_footprint_sentence(snapshot)
	stock_controller._sync_root_refs()
	return result
func _profile_clean_footprint_phrase(footprint: String) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._profile_clean_footprint_phrase(footprint)
	stock_controller._sync_root_refs()
	return result
func _profile_roadmap_sentence(snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._profile_roadmap_sentence(snapshot)
	stock_controller._sync_root_refs()
	return result
func _profile_clean_priority_phrase(priority_text: String) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._profile_clean_priority_phrase(priority_text)
	stock_controller._sync_root_refs()
	return result
func _profile_sentence_from_fragment(fragment: String) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._profile_sentence_from_fragment(fragment)
	stock_controller._sync_root_refs()
	return result
func _profile_operating_read(snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._profile_operating_read(snapshot)
	stock_controller._sync_root_refs()
	return result
func _clear_profile_container(container: Node) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._clear_profile_container(container)
	stock_controller._sync_root_refs()
func _refresh_profile_network_contact(_company_id: String) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_profile_network_contact(_company_id)
	stock_controller._sync_root_refs()
func _format_profile_management(snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_profile_management(snapshot)
	stock_controller._sync_root_refs()
	return result
func _format_profile_shareholders(snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_profile_shareholders(snapshot)
	stock_controller._sync_root_refs()
	return result
func _broker_flow_has_rows(broker_flow: Dictionary) -> bool:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: bool = stock_controller._broker_flow_has_rows(broker_flow)
	stock_controller._sync_root_refs()
	return result
func _trade_workspace_detail_snapshot_key(snapshot: Dictionary, financial_statement_snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._trade_workspace_detail_snapshot_key(snapshot, financial_statement_snapshot)
	stock_controller._sync_root_refs()
	return result
func _trade_workspace_profile_snapshot_key(snapshot: Dictionary, financial_statement_snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._trade_workspace_profile_snapshot_key(snapshot, financial_statement_snapshot)
	stock_controller._sync_root_refs()
	return result
func _trade_workspace_financial_history_snapshot_key(snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._trade_workspace_financial_history_snapshot_key(snapshot)
	stock_controller._sync_root_refs()
	return result
func _trade_workspace_key_stats_snapshot_key(snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._trade_workspace_key_stats_snapshot_key(snapshot)
	stock_controller._sync_root_refs()
	return result
func _broker_range_flow_for_snapshot(snapshot: Dictionary) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._broker_range_flow_for_snapshot(snapshot)
	stock_controller._sync_root_refs()
	return result
func _trade_workspace_broker_snapshot_key(snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._trade_workspace_broker_snapshot_key(snapshot)
	stock_controller._sync_root_refs()
	return result
func _trade_workspace_statement_snapshot_key(snapshot: Dictionary, financial_statement_snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._trade_workspace_statement_snapshot_key(snapshot, financial_statement_snapshot)
	stock_controller._sync_root_refs()
	return result
func _trade_workspace_corporate_action_snapshot_key(timeline_snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._trade_workspace_corporate_action_snapshot_key(timeline_snapshot)
	stock_controller._sync_root_refs()
	return result
func _broker_rows_signature(rows: Array) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._broker_rows_signature(rows)
	stock_controller._sync_root_refs()
	return result
func _network_state_for_contact(network_snapshot: Dictionary, contact_id: String) -> String:
	_ensure_network_controller()
	return network_controller.network_state_for_contact(network_snapshot, contact_id)


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
	var action_color: Color = COLOR_POSITIVE if side == "BUY" or side == "DIVIDEND" or side == "STOCK_DIVIDEND" else COLOR_NEGATIVE
	var qty_text: String = "%d lot(s)" % int(trade.get("lots", 0))
	if side == "DIVIDEND" or side == "STOCK_DIVIDEND":
		qty_text = "%d share(s)" % int(trade.get("shares", 0))
	elif not (side == "BUY" or side == "SELL"):
		qty_text = "-"
	var price_text: String = "-" if side.is_empty() or not (side == "BUY" or side == "SELL" or side == "DIVIDEND" or side == "STOCK_DIVIDEND") else _format_currency(float(trade.get("price_per_share", 0.0)))
	var action_text: String = side.replace("_", " ")

	row.add_child(_build_table_cell(
		"%s %s" % [action_text, str(trade.get("ticker", ""))],
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
	_apply_font_override_to_control(label, DEFAULT_APP_FONT_SIZE, _get_app_font())
	return label


func _format_trade_date_short(day_index: int) -> String:
	var date_info: Dictionary = portfolio_trading_calendar.trade_date_for_index(day_index + 1)
	var full_date: String = portfolio_trading_calendar.format_date(date_info)
	return full_date.replace(",", "")


func _refresh_summary() -> void:
	_refresh_dashboard()


func _on_dashboard_pressed() -> void:
	_set_active_section("dashboard")


func _on_academy_app_pressed() -> void:
	if not GameManager.is_academy_available():
		_show_toast(GameManager.get_academy_release_message(), false)
		_apply_academy_release_lock_state()
		return
	_set_active_app(APP_ID_ACADEMY)


func _on_thesis_app_pressed() -> void:
	_set_active_app(APP_ID_THESIS)
	call_deferred("_refresh_ftue_progress")


func _on_company_request_pressed() -> void:
	_ensure_company_controller()
	company_controller.on_request_pressed()


func _on_upgrades_changed() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	_suppress_next_portfolio_refresh()
	trade_workspace_widget.refresh_indicator_catalog()
	_refresh_header()
	_refresh_sidebar()
	_refresh_trade_workspace_holdings_state()
	_refresh_portfolio()
	_refresh_desktop()
	if _is_desktop_app_window_open(APP_ID_NEWS):
		_refresh_news()
	if _is_desktop_app_window_open(APP_ID_SOCIAL):
		_refresh_social()
	if _is_desktop_app_window_open(APP_ID_NETWORK):
		_refresh_network()
	if _is_desktop_app_window_open(APP_ID_UPGRADES):
		_refresh_upgrades()
	if debug_overlay.visible:
		_refresh_debug_overlay()
	_log_perf_elapsed("_on_upgrades_changed", started_at_usec)


func _on_academy_category_pressed(category_id: String) -> void:
	_ensure_academy_controller()
	academy_controller.on_category_pressed(category_id)


func _on_academy_section_selected(index: int) -> void:
	_ensure_academy_controller()
	academy_controller.on_section_selected(index)


func _on_academy_section_tab_pressed(section_id: String) -> void:
	_ensure_academy_controller()
	academy_controller.on_section_tab_pressed(section_id)


func _on_academy_mark_read_pressed() -> void:
	_ensure_academy_controller()
	academy_controller.on_mark_read_pressed()


func _on_academy_next_pressed() -> void:
	_ensure_academy_controller()
	academy_controller.on_next_pressed()


func _on_academy_inline_check_pressed(section_id: String, check_id: String, answer_id: String) -> void:
	_ensure_academy_controller()
	academy_controller.on_inline_check_pressed(section_id, check_id, answer_id)


func _on_academy_quiz_submit_pressed() -> void:
	_ensure_academy_controller()
	academy_controller.on_quiz_submit_pressed()


func _show_academy_quiz_feedback(feedback_rows: Array, passed: bool, score_percent: int) -> void:
	_ensure_academy_controller()
	academy_controller.show_quiz_feedback(feedback_rows, passed, score_percent)


func _on_academy_glossary_search_changed(_new_text: String) -> void:
	_ensure_academy_controller()
	academy_controller.on_glossary_search_changed(_new_text)


func _on_news_outlet_pressed(outlet_id: String) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._on_news_outlet_pressed(outlet_id)
	news_controller._sync_root_refs()

func _on_news_article_selected(index: int) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._on_news_article_selected(index)
	news_controller._sync_root_refs()

func _on_news_meet_contact_pressed() -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._on_news_meet_contact_pressed()
	news_controller._sync_root_refs()

func _open_social_account_from_news(account_id: String, contact_id: String = "") -> void:
	_ensure_social_controller()
	social_controller.open_account_from_news(account_id, contact_id)
func _on_news_open_meeting_pressed() -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._on_news_open_meeting_pressed()
	news_controller._sync_root_refs()

func _on_profile_meet_contact_pressed() -> void:
	var contact_id: String = str(profile_meet_contact_button.get_meta("contact_id", ""))
	_meet_contact_from_context(contact_id, {"source_type": "profile", "source_id": selected_company_id})


func _on_network_contact_selected(index: int) -> void:
	_ensure_network_controller()
	network_controller.on_contact_selected(index)


func _on_network_request_selected(index: int) -> void:
	_ensure_network_controller()
	network_controller.on_request_selected(index)


func _on_network_journal_selected(index: int) -> void:
	_ensure_network_controller()
	network_controller.on_journal_selected(index)


func _on_network_journal_filter_pressed(filter_id: String) -> void:
	_ensure_network_controller()
	network_controller.on_journal_filter_pressed(filter_id)


func _on_network_meet_pressed() -> void:
	_ensure_network_controller()
	network_controller.on_meet_pressed()


func _on_network_tip_pressed() -> void:
	_ensure_network_controller()
	network_controller.on_tip_pressed()


func _on_network_request_pressed() -> void:
	_ensure_network_controller()
	network_controller.on_request_pressed()


func _on_network_referral_pressed() -> void:
	_ensure_network_controller()
	network_controller.on_referral_pressed()


func _on_network_followup_selected(menu_id: int) -> void:
	_ensure_network_controller()
	network_controller.on_followup_selected(menu_id)


func _on_network_source_check_pressed() -> void:
	_ensure_network_controller()
	network_controller.on_source_check_pressed()


func _on_network_open_meeting_pressed() -> void:
	_ensure_network_controller()
	network_controller.on_open_meeting_pressed()


func _open_corporate_meeting_modal(meeting_id: String) -> void:
	if meeting_id.is_empty():
		return
	var detail: Dictionary = GameManager.get_corporate_meeting_detail(meeting_id)
	if detail.is_empty():
		_show_toast("Meeting not found.", false)
		return
	var meeting_blocked_reason: String = _corporate_meeting_open_blocked_reason(detail)
	if not meeting_blocked_reason.is_empty():
		_show_toast(meeting_blocked_reason, false)
		return
	if bool(detail.get("interactive_v1", false)):
		_open_rupslb_meeting_overlay(meeting_id)
		return
	if corporate_meeting_overlay == null:
		return
	if rupslb_meeting_overlay != null:
		rupslb_meeting_overlay.visible = false
	current_corporate_meeting_id = meeting_id
	_refresh_corporate_meeting_modal()
	corporate_meeting_overlay.visible = true
	corporate_meeting_overlay.move_to_front()


func _close_corporate_meeting_modal() -> void:
	current_corporate_meeting_id = ""
	if corporate_meeting_overlay != null:
		corporate_meeting_overlay.visible = false


func _open_rupslb_meeting_overlay(meeting_id: String) -> void:
	if meeting_id.is_empty() or rupslb_meeting_overlay == null:
		return
	current_corporate_meeting_id = meeting_id
	var result: Dictionary = GameManager.start_corporate_meeting_session(meeting_id)
	if not bool(result.get("success", false)):
		_show_toast(str(result.get("message", "Unable to open RUPSLB session.")), false)
		return
	if corporate_meeting_overlay != null:
		corporate_meeting_overlay.visible = false
	_refresh_rupslb_meeting_overlay()
	rupslb_meeting_overlay.visible = true
	rupslb_meeting_overlay.move_to_front()
	_refresh_first_hour_guide_progress()


func _close_rupslb_meeting_overlay() -> void:
	if not current_corporate_meeting_id.is_empty():
		GameManager.close_corporate_meeting_session(current_corporate_meeting_id)
	current_corporate_meeting_id = ""
	if rupslb_meeting_overlay != null:
		rupslb_meeting_overlay.visible = false
	_refresh_first_hour_guide_progress()


func _refresh_rupslb_meeting_overlay() -> void:
	if current_corporate_meeting_id.is_empty() or rupslb_meeting_overlay == null:
		return
	var snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(current_corporate_meeting_id)
	if snapshot.is_empty():
		_show_toast("Interactive RUPSLB session is no longer available.", false)
		_close_rupslb_meeting_overlay()
		return
	rupslb_meeting_overlay.call("configure", snapshot)


func _on_rupslb_stage_advance_requested(next_stage_id: String) -> void:
	if current_corporate_meeting_id.is_empty():
		return
	var result: Dictionary = GameManager.set_corporate_meeting_session_stage(current_corporate_meeting_id, next_stage_id)
	if not bool(result.get("success", false)):
		_show_toast(str(result.get("message", "Could not advance meeting stage.")), false)
		return
	_refresh_rupslb_meeting_overlay()
	_refresh_first_hour_guide_progress()


func _on_rupslb_vote_requested(vote_choice: String) -> void:
	if current_corporate_meeting_id.is_empty():
		return
	var session_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(current_corporate_meeting_id)
	var agenda_payload: Array = session_snapshot.get("agenda_payload", [])
	var agenda_id: String = ""
	if not agenda_payload.is_empty():
		agenda_id = str(agenda_payload[0].get("id", ""))
	var result: Dictionary = GameManager.submit_corporate_meeting_vote(current_corporate_meeting_id, agenda_id, vote_choice)
	_show_toast(str(result.get("message", "Vote updated.")), bool(result.get("success", false)))
	if not bool(result.get("success", false)):
		return
	_refresh_rupslb_meeting_overlay()
	_refresh_dashboard()
	_refresh_network()
	_refresh_first_hour_guide_progress()


func _on_rupslb_lead_approach_requested(lead_id: String) -> void:
	if current_corporate_meeting_id.is_empty():
		return
	var result: Dictionary = GameManager.approach_corporate_meeting_lead(current_corporate_meeting_id, lead_id)
	_show_toast(str(result.get("message", "Could not approach this attendee.")), bool(result.get("success", false)))
	_refresh_rupslb_meeting_overlay()
	if bool(result.get("success", false)):
		_refresh_network()
		_refresh_first_hour_guide_progress()


func _refresh_corporate_meeting_modal() -> void:
	if corporate_meeting_overlay == null:
		return
	var detail: Dictionary = GameManager.get_corporate_meeting_detail(current_corporate_meeting_id)
	if detail.is_empty():
		_close_corporate_meeting_modal()
		return
	var trade_date_text: String = GameManager.format_trade_date(detail.get("trade_date", {}))
	corporate_meeting_title_label.text = "%s  |  %s" % [
		str(detail.get("company_name", detail.get("ticker", "Meeting"))),
		str(detail.get("meeting_label", "Meeting"))
	]
	corporate_meeting_meta_label.text = "%s  |  %s  |  %s  |  Stance %s" % [
		str(detail.get("ticker", "")),
		trade_date_text,
		str(detail.get("family_label", "General meeting")),
		str(detail.get("management_stance", "clarify"))
	]
	corporate_meeting_summary_label.text = str(detail.get("public_summary", "No public summary yet."))
	var agenda_lines: Array = []
	for agenda_value in detail.get("agenda_payload", []):
		var agenda: Dictionary = agenda_value
		agenda_lines.append("- %s: %s" % [
			str(agenda.get("label", "Agenda")),
			str(agenda.get("description", ""))
		])
	corporate_meeting_agenda_label.text = "Agenda\n%s" % ("\n".join(agenda_lines) if not agenda_lines.is_empty() else "No agenda items published yet.")
	if corporate_meeting_intel_label != null:
		corporate_meeting_intel_label.text = ""
		corporate_meeting_intel_label.visible = false
	var attended: bool = bool(detail.get("attended", false))
	var requires_shareholder: bool = bool(detail.get("requires_shareholder", false))
	var attendance_eligible: bool = bool(detail.get("attendance_eligible", true))
	var attendance_text: String = "Attendance is open in this milestone."
	if attended:
		attendance_text = "Already marked as attended."
	elif requires_shareholder and not attendance_eligible:
		attendance_text = str(detail.get("attendance_blocked_reason", "Shareholder ownership is required to attend this meeting."))
	elif requires_shareholder:
		var record_day_number: int = int(detail.get("record_day_number", 0))
		if bool(detail.get("shareholder_recorded", false)):
			attendance_text = "Shareholder verified: %d share(s) recorded on Day %d." % [
				int(detail.get("player_shares_owned", 0)),
				record_day_number
			]
		else:
			attendance_text = "Projected eligibility: %d share(s). Registry records on Day %d." % [
				int(detail.get("player_shares_owned", 0)),
				record_day_number
			]
	corporate_meeting_attendance_label.text = "Attendance\n%s" % attendance_text
	corporate_meeting_attend_button.disabled = attended or not attendance_eligible
	corporate_meeting_attend_button.text = "Attended" if attended else ("Shareholders Only" if not attendance_eligible else "Attend")


func _on_corporate_meeting_attend_pressed() -> void:
	if current_corporate_meeting_id.is_empty():
		return
	var result: Dictionary = GameManager.attend_corporate_meeting(current_corporate_meeting_id)
	_show_toast(str(result.get("message", "Meeting updated.")), bool(result.get("success", false)))
	_refresh_corporate_meeting_modal()
	_refresh_dashboard()
	_refresh_network()


func _meet_contact_from_context(contact_id: String, source_context: Dictionary) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	if contact_id.is_empty():
		_show_toast("No contact lead is available here.", false)
		return
	var result: Dictionary = GameManager.meet_contact(contact_id, source_context)
	_show_toast(str(result.get("message", "Network updated.")), bool(result.get("success", false)))
	_log_perf_elapsed("_meet_contact_from_context", started_at_usec)


func _network_contact_target_company(contact: Dictionary) -> String:
	_ensure_network_controller()
	return network_controller.network_contact_target_company(contact)


func _on_news_archive_year_selected(index: int) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._on_news_archive_year_selected(index)
	news_controller._sync_root_refs()

func _on_news_archive_month_selected(index: int) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._on_news_archive_month_selected(index)
	news_controller._sync_root_refs()

func _on_stock_list_tab_changed(_tab_index: int) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_stock_list_tab_changed(_tab_index)
	stock_controller._sync_root_refs()
func _on_work_tab_changed(tab_index: int) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_work_tab_changed(tab_index)
	stock_controller._sync_root_refs()
func _on_guide_chart_interaction(_range_id = "") -> void:
	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	if str(snapshot.get("active_flow_id", "")) == RunState.GUIDE_FLOW_SYSTEM.FLOW_TECHNICAL:
		guide_technical_tool_action_seen = true
	_refresh_ftue_progress()


func _steam_progress_manager() -> Node:
	return get_node_or_null("/root/SteamProgressManager")


func _record_steam_stockbot_tab_view(tab_title: String) -> void:
	var progress_manager: Node = _steam_progress_manager()
	if progress_manager != null and progress_manager.has_method("record_stockbot_tab_view"):
		progress_manager.call("record_stockbot_tab_view", tab_title, selected_company_id)


func _record_steam_news_article_read(article_id: String) -> void:
	var progress_manager: Node = _steam_progress_manager()
	if progress_manager != null and progress_manager.has_method("record_news_article_read"):
		progress_manager.call("record_news_article_read", article_id)


func _bind_thesis_guide_controls() -> void:
	if thesis_window == null:
		return
	var company_option: OptionButton = thesis_window.find_child("ThesisCompanyOption", true, false) as OptionButton
	if company_option != null and not company_option.item_selected.is_connected(_on_thesis_guide_company_selected):
		company_option.item_selected.connect(_on_thesis_guide_company_selected)
	var create_button: Button = thesis_window.find_child("ThesisCreateButton", true, false) as Button
	if create_button != null and not create_button.pressed.is_connected(_mark_guide_thesis_create_action):
		create_button.pressed.connect(_mark_guide_thesis_create_action)


func _on_thesis_guide_company_selected(_index: int) -> void:
	_mark_guide_thesis_subject_chosen()


func _bind_life_guide_tabs() -> void:
	_ensure_life_controller()
	life_controller.bind_guide_tabs()


func _on_life_guide_tab_changed(_tab_index: int) -> void:
	_ensure_life_controller()
	life_controller.on_guide_tab_changed(_tab_index)


func _on_life_guide_plan_changed(_value = 0) -> void:
	_ensure_life_controller()
	life_controller.on_guide_plan_changed(_value)


func _on_add_watchlist_pressed() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_add_watchlist_pressed()
	stock_controller._sync_root_refs()
func _on_remove_watchlist_pressed() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_remove_watchlist_pressed()
	stock_controller._sync_root_refs()
func _on_watchlist_picker_confirmed() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_watchlist_picker_confirmed()
	stock_controller._sync_root_refs()
func _on_watchlist_picker_item_activated(index: int) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_watchlist_picker_item_activated(index)
	stock_controller._sync_root_refs()
func _on_all_stock_selected(company_id: String) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_all_stock_selected(company_id)
	stock_controller._sync_root_refs()
func _on_portfolio_stock_selected(company_id: String) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_portfolio_stock_selected(company_id)
	stock_controller._sync_root_refs()
func _on_add_to_watchlist_pressed(company_id: String) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_add_to_watchlist_pressed(company_id)
	stock_controller._sync_root_refs()
func _on_all_stock_search_text_changed(_new_text: String) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_all_stock_search_text_changed(_new_text)
	stock_controller._sync_root_refs()
func _on_taskbar_home_pressed() -> void:
	_set_active_app(APP_ID_DESKTOP)


func _on_taskbar_stock_pressed() -> void:
	_set_active_app(APP_ID_STOCK)


func _on_taskbar_news_pressed() -> void:
	_set_active_app(APP_ID_NEWS)


func _on_settings_app_pressed() -> void:
	_show_settings_dialog()


func _show_settings_dialog() -> void:
	if settings_dialog == null:
		return
	var started_at_usec: int = Time.get_ticks_usec()
	_hide_settings_confirmation()
	_refresh_settings_dialog()
	settings_dialog.visible = true
	settings_dialog.move_to_front()
	_refresh_ftue_progress()
	_log_perf_elapsed("_show_settings_dialog", started_at_usec)


func _hide_settings_dialog() -> void:
	_hide_settings_confirmation()
	if settings_dialog != null:
		settings_dialog.visible = false
	_refresh_ftue_progress()


func _refresh_settings_dialog(status_text: String = "") -> void:
	if settings_dialog == null or settings_save_slots_list == null:
		return
	var started_at_usec: int = Time.get_ticks_usec()
	selected_settings_slot_id = SaveManager.get_active_slot_id()
	settings_autosave_checkbox.set_pressed_no_signal(SaveManager.is_autosave_enabled())
	settings_save_slots_list.clear()
	for slot_value in SaveManager.get_save_slots(false):
		var slot: Dictionary = slot_value
		var item_index: int = settings_save_slots_list.add_item(_format_settings_slot_item(slot))
		settings_save_slots_list.set_item_metadata(item_index, str(slot.get("slot_id", "")))
		if str(slot.get("slot_id", "")) == selected_settings_slot_id:
			settings_save_slots_list.select(item_index)
	settings_save_button.disabled = not RunState.has_active_run() or selected_settings_slot_id.is_empty()
	settings_load_button.disabled = not bool(SaveManager.get_save_file_info(selected_settings_slot_id, false).get("loadable", false))
	settings_delete_button.disabled = not _settings_slot_has_file(selected_settings_slot_id)
	settings_status_label.text = status_text if not status_text.is_empty() else _settings_slot_status_text(selected_settings_slot_id)
	settings_status_label.tooltip_text = _settings_slot_path_text(selected_settings_slot_id)
	_refresh_settings_summary_labels()
	_log_perf_elapsed("_refresh_settings_dialog", started_at_usec)


func _format_settings_slot_item(slot: Dictionary) -> String:
	var label: String = str(slot.get("slot_label", "Slot"))
	var marker: String = "CURRENT - " if bool(slot.get("active", false)) else ""
	if not bool(slot.get("loadable", false)):
		if bool(slot.get("exists", false)) or bool(slot.get("backup_exists", false)):
			return "%s%s | Unreadable" % [marker, label]
		return "%s%s | Empty" % [marker, label]
	return "%s%s | Day %d | %s | %s | Equity %s" % [
		marker,
		label,
		int(slot.get("trading_day", 1)),
		str(slot.get("trade_date_text", "Unknown date")),
		str(slot.get("difficulty_label", "Normal")),
		str(slot.get("equity_text", "Rp0,00"))
	]


func _settings_slot_status_text(slot_id: String) -> String:
	var slot: Dictionary = SaveManager.get_save_file_info(slot_id, false)
	var unsaved: Dictionary = SaveManager.get_unsaved_change_summary()
	var prefix: String = "Unsaved changes pending. " if bool(unsaved.get("unsaved", false)) else ""
	if bool(slot.get("loadable", false)):
		return "%s%s selected. Last saved %s." % [
			prefix,
			str(slot.get("slot_label", "Slot")),
			str(slot.get("saved_at_text", "Unknown"))
		]
	if bool(slot.get("exists", false)) or bool(slot.get("backup_exists", false)):
		return "%s%s selected. Save data is unreadable; delete it or overwrite by saving." % [
			prefix,
			str(slot.get("slot_label", "Slot"))
		]
	return "%s%s selected. Saving will create this slot." % [
		prefix,
		str(slot.get("slot_label", "Slot"))
	]


func _settings_slot_path_text(slot_id: String) -> String:
	var slot: Dictionary = SaveManager.get_save_file_info(slot_id, false)
	if bool(slot.get("loadable", false)):
		return str(slot.get("absolute_path", ""))
	if bool(slot.get("exists", false)):
		return str(slot.get("absolute_path", ""))
	if bool(slot.get("backup_exists", false)):
		return str(slot.get("backup_absolute_path", ""))
	return str(slot.get("write_absolute_path", ""))


func _settings_slot_has_file(slot_id: String) -> bool:
	if slot_id.is_empty():
		return false
	var slot: Dictionary = SaveManager.get_save_file_info(slot_id, false)
	return bool(slot.get("exists", false)) or bool(slot.get("backup_exists", false))


func _on_settings_autosave_toggled(enabled: bool) -> void:
	SaveManager.set_autosave_enabled(enabled)
	_refresh_settings_dialog("Auto save %s." % ("enabled" if enabled else "disabled"))


func _on_settings_slot_selected(index: int) -> void:
	if index < 0:
		return
	selected_settings_slot_id = str(settings_save_slots_list.get_item_metadata(index))
	settings_save_button.disabled = not RunState.has_active_run() or selected_settings_slot_id.is_empty()
	settings_load_button.disabled = not bool(SaveManager.get_save_file_info(selected_settings_slot_id, false).get("loadable", false))
	settings_delete_button.disabled = not _settings_slot_has_file(selected_settings_slot_id)
	settings_status_label.text = _settings_slot_status_text(selected_settings_slot_id)
	settings_status_label.tooltip_text = _settings_slot_path_text(selected_settings_slot_id)
	_refresh_settings_summary_labels()


func _on_settings_slot_activated(index: int) -> void:
	_on_settings_slot_selected(index)


func _on_settings_save_pressed() -> void:
	if selected_settings_slot_id.is_empty():
		return
	SaveManager.set_active_slot_id(selected_settings_slot_id)
	var saved: bool = GameManager.save_active_run_now("manual_settings_save")
	var status_text: String = "Save failed."
	if saved:
		status_text = "Saved to %s." % str(SaveManager.get_save_file_info(selected_settings_slot_id, false).get("slot_label", "slot"))
	_refresh_settings_dialog(status_text)


func _on_settings_load_pressed() -> void:
	if selected_settings_slot_id.is_empty() or not bool(SaveManager.get_save_file_info(selected_settings_slot_id, false).get("loadable", false)):
		_refresh_settings_dialog("Choose a readable save slot first.")
		return
	_show_settings_confirmation("load", selected_settings_slot_id)


func _on_settings_delete_pressed() -> void:
	if selected_settings_slot_id.is_empty() or not _settings_slot_has_file(selected_settings_slot_id):
		_refresh_settings_dialog("Choose a save slot with data first.")
		return
	_show_settings_confirmation("delete", selected_settings_slot_id)


func _on_settings_exit_pressed() -> void:
	_show_settings_confirmation("exit", "")


func _refresh_settings_summary_labels() -> void:
	if settings_current_slot_label == null or settings_last_saved_label == null:
		return
	var active_slot: Dictionary = SaveManager.get_save_file_info(SaveManager.get_active_slot_id(), false)
	var runtime_status: Dictionary = SaveManager.get_runtime_save_status()
	settings_current_slot_label.text = "Current slot: %s" % str(active_slot.get("slot_label", "Slot 1"))
	var last_saved_text: String = str(active_slot.get("saved_at_text", "Never")) if bool(active_slot.get("loadable", false)) else "Never"
	if bool(runtime_status.get("pending", false)):
		last_saved_text = "Autosave pending"
	elif bool(runtime_status.get("unsaved", false)):
		last_saved_text = "Unsaved changes"
	settings_last_saved_label.text = "Last saved: %s" % last_saved_text


func _show_settings_confirmation(action_id: String, slot_id: String = "") -> void:
	if settings_confirm_overlay == null:
		return
	pending_settings_confirm_action = action_id
	pending_settings_confirm_slot_id = slot_id
	var unsaved: Dictionary = SaveManager.get_unsaved_change_summary()
	var has_unsaved: bool = bool(unsaved.get("unsaved", false))
	var body_lines: Array[String] = []
	var append_current_save_state := true
	if action_id == "load":
		var slot: Dictionary = SaveManager.get_save_file_info(slot_id, false)
		settings_confirm_title_label.text = "Load Save?"
		settings_confirm_confirm_button.text = "Load"
		body_lines.append("Load %s and replace the current run?" % str(slot.get("slot_label", "this slot")))
		body_lines.append("Saved run: Day %d | %s | %s" % [
			int(slot.get("trading_day", 1)),
			str(slot.get("trade_date_text", "Unknown date")),
			str(slot.get("difficulty_label", "Normal"))
		])
	elif action_id == "delete":
		var slot: Dictionary = SaveManager.get_save_file_info(slot_id, false)
		settings_confirm_title_label.text = "Delete Save?"
		settings_confirm_confirm_button.text = "Delete"
		body_lines.append("Delete %s?" % str(slot.get("slot_label", "this slot")))
		if bool(slot.get("loadable", false)):
			body_lines.append("Saved run: Day %d | %s | %s" % [
				int(slot.get("trading_day", 1)),
				str(slot.get("trade_date_text", "Unknown date")),
				str(slot.get("difficulty_label", "Normal"))
			])
		else:
			body_lines.append("This slot has an unreadable save or backup.")
		if slot_id == SaveManager.get_active_slot_id() and RunState.has_active_run():
			body_lines.append("The current run stays open in memory. Save again to recreate this slot.")
		body_lines.append("This removes the primary, backup, and temp files. This cannot be undone.")
		append_current_save_state = false
	else:
		settings_confirm_title_label.text = "Exit To Menu?"
		settings_confirm_confirm_button.text = "Exit"
		body_lines.append("Return to the main menu now?")
	if append_current_save_state and has_unsaved:
		if bool(unsaved.get("pending", false)):
			body_lines.append("Pending autosave will be flushed first.")
		else:
			body_lines.append("Unsaved changes will be discarded unless you save first.")
	elif append_current_save_state:
		body_lines.append("The current slot is saved.")
	settings_confirm_body_label.text = "\n".join(body_lines)
	settings_confirm_overlay.visible = true
	settings_confirm_overlay.move_to_front()


func _hide_settings_confirmation() -> void:
	pending_settings_confirm_action = ""
	pending_settings_confirm_slot_id = ""
	if settings_confirm_overlay != null:
		settings_confirm_overlay.visible = false


func _on_settings_confirm_cancel_pressed() -> void:
	_hide_settings_confirmation()


func _on_settings_confirm_confirm_pressed() -> void:
	var action_id: String = pending_settings_confirm_action
	var slot_id: String = pending_settings_confirm_slot_id
	_hide_settings_confirmation()
	if action_id == "load":
		if slot_id.is_empty():
			return
		if SaveManager.has_pending_save():
			GameManager.flush_pending_save_if_needed()
		_hide_settings_dialog()
		GameManager.load_run_from_save(slot_id)
	elif action_id == "delete":
		if slot_id.is_empty():
			return
		var slot_label: String = str(SaveManager.get_save_file_info(slot_id, false).get("slot_label", "Slot"))
		var deleting_active_slot: bool = slot_id == SaveManager.get_active_slot_id()
		SaveManager.delete_save(slot_id)
		var status_text := "Deleted %s." % slot_label
		if deleting_active_slot and RunState.has_active_run():
			status_text += " Current run is still open; save again to recreate the slot."
		_refresh_settings_dialog(status_text)
	elif action_id == "exit":
		if SaveManager.has_pending_save():
			GameManager.flush_pending_save_if_needed()
		_hide_settings_dialog()
		GameManager.return_to_menu()


func _show_bankruptcy_overlay(bankruptcy: Dictionary = {}) -> void:
	if bankruptcy_overlay == null:
		return
	var resolved_bankruptcy: Dictionary = bankruptcy
	if resolved_bankruptcy.is_empty():
		var finance_status: Dictionary = GameManager.get_finance_status_snapshot()
		resolved_bankruptcy = finance_status.get("bankruptcy", {})
	var trade_date: Dictionary = resolved_bankruptcy.get("trade_date", GameManager.get_current_trade_date())
	var days_survived: int = max(int(resolved_bankruptcy.get("day_index", RunState.day_index)), 0)
	bankruptcy_body_label.text = "The run has ended because cash stayed negative after the grace period and no recovery path was available.\n\nFinal day: %s\nDays survived: %d\nCash: %s\nEquity: %s\nMarket value: %s\nReason: %s" % [
		GameManager.format_trade_date(trade_date),
		days_survived,
		_format_currency(float(resolved_bankruptcy.get("cash", RunState.player_portfolio.get("cash", 0.0)))),
		_format_currency(float(resolved_bankruptcy.get("equity", RunState.get_total_equity()))),
		_format_currency(float(resolved_bankruptcy.get("market_value", RunState.get_portfolio_market_value()))),
		str(resolved_bankruptcy.get("reason", "cash stress"))
	]
	bankruptcy_overlay.visible = true
	bankruptcy_overlay.move_to_front()


func _ensure_stress_meter_ui() -> void:
	_ensure_life_controller()
	life_controller.ensure_stress_meter_ui()


func _refresh_stress_meter() -> void:
	_ensure_life_controller()
	life_controller.refresh_stress_meter()


func _stress_stage_color(stage_id: String) -> Color:
	_ensure_life_controller()
	return life_controller.stress_stage_color(stage_id)


func _on_stress_meter_gui_input(event: InputEvent) -> void:
	_ensure_life_controller()
	life_controller.on_stress_meter_gui_input(event)


func _ensure_hospital_overlay() -> void:
	_ensure_life_controller()
	life_controller.ensure_hospital_overlay()


func _refresh_hospital_overlay() -> void:
	_ensure_life_controller()
	life_controller.refresh_hospital_overlay()


func _on_hospital_advance_pressed() -> void:
	_ensure_life_controller()
	life_controller.on_hospital_advance_pressed()


func _ensure_jail_overlay() -> void:
	_ensure_life_controller()
	life_controller.ensure_jail_overlay()


func _refresh_jail_overlay() -> void:
	_ensure_life_controller()
	life_controller.refresh_jail_overlay()


func _on_jail_advance_pressed() -> void:
	_ensure_life_controller()
	life_controller.on_jail_advance_pressed()


func _on_bankruptcy_menu_pressed() -> void:
	GameManager.return_to_menu()


func _on_bankruptcy_restart_pressed() -> void:
	var difficulty_config: Dictionary = GameManager.get_current_difficulty_config()
	var difficulty_id: String = str(difficulty_config.get("id", GameManager.DEFAULT_DIFFICULTY_ID))
	GameManager.start_new_run(0, difficulty_id, false)


func _on_app_window_minimize_pressed() -> void:
	_set_active_app(APP_ID_DESKTOP)


func _on_app_window_close_pressed() -> void:
	_set_active_app(APP_ID_DESKTOP)


func _on_markets_pressed() -> void:
	_set_active_section("markets")
	_mark_guide_watchlist_all_stock_seen()


func _on_portfolio_pressed() -> void:
	_set_active_section("portfolio")


func _on_help_pressed() -> void:
	_set_active_section("help")


func _on_financials_previous_pressed() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_financials_previous_pressed()
	stock_controller._sync_root_refs()
func _on_financials_next_pressed() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_financials_next_pressed()
	stock_controller._sync_root_refs()
func _on_company_selected(index: int) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_company_selected(index)
	stock_controller._sync_root_refs()
func _on_buy_side_pressed() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_buy_side_pressed()
	stock_controller._sync_root_refs()
func _on_sell_side_pressed() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_sell_side_pressed()
	stock_controller._sync_root_refs()
func _on_submit_order_pressed() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_submit_order_pressed()
	stock_controller._sync_root_refs()
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
	if advance_day_processing:
		return
	if not RunState.has_active_run():
		return
	var finance_gate: Dictionary = GameManager.resolve_advance_day_finance_gate()
	if not bool(finance_gate.get("success", false)):
		var gate_message: String = str(finance_gate.get("message", "Advance Day is blocked."))
		status_message = gate_message
		_show_toast(gate_message, false)
		if bool(finance_gate.get("bankrupt", false)):
			_show_bankruptcy_overlay(finance_gate.get("bankruptcy", {}))
		_refresh_all(false)
		return
	var started_at_usec: int = Time.get_ticks_usec()
	advance_day_processing = true
	pending_daily_recap_snapshot = {}
	_refresh_hospital_overlay()
	_refresh_jail_overlay()
	_refresh_ftue_overlay()
	_set_advance_day_phase("Closing Market", false)
	_play_advance_day_button_feedback()
	await get_tree().process_frame
	_set_advance_day_phase("Printing News")
	await get_tree().process_frame
	_set_advance_day_phase("Updating Contacts")
	await get_tree().process_frame
	_set_advance_day_phase("Saving Run")
	await get_tree().process_frame
	var advance_result: Dictionary = GameManager.advance_day_deferred_save()
	if not bool(advance_result.get("success", true)):
		var block_message: String = str(advance_result.get("message", "Advance Day is blocked."))
		status_message = block_message
		_show_toast(block_message, false)
		if bool(advance_result.get("bankrupt", false)):
			_show_bankruptcy_overlay(advance_result.get("bankruptcy", {}))
		_finish_advance_day_processing()
		_refresh_all(false)
		_log_perf_elapsed("_on_next_day_pressed", started_at_usec)
		return
	if advance_day_processing:
		_finish_advance_day_processing()
		_schedule_advance_day_post_recap_save_flush()
	_log_perf_elapsed("_on_next_day_pressed", started_at_usec)


func _on_day_progressed(_day_index: int) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	status_message = "Market closed."
	_suppress_next_portfolio_refresh()
	if _is_desktop_app_window_open(APP_ID_NEWS):
		_ensure_news_controller()
		news_controller.reset_archive_selection()
	if advance_day_processing:
		_queue_deferred_open_app_refresh()
		deferred_dashboard_refresh_after_recap = true
		deferred_full_refresh_after_recap = true
		_invalidate_company_rows_cache()
	else:
		_refresh_all()
	_log_perf_elapsed("_on_day_progressed", started_at_usec)


func _on_summary_ready(_summary: Dictionary) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var phase_started_at_usec: int = started_at_usec
	var is_guarded_advance: bool = advance_day_processing
	if is_guarded_advance:
		_log_perf_phase(true, "_on_summary_ready:dashboard_skipped", phase_started_at_usec)
	else:
		_refresh_dashboard()
		_log_perf_phase(false, "_on_summary_ready:dashboard", phase_started_at_usec)
	if is_guarded_advance:
		phase_started_at_usec = Time.get_ticks_usec()
		pending_daily_recap_snapshot = GameManager.get_daily_recap_snapshot()
		_log_perf_phase(true, "_on_summary_ready:daily_recap_snapshot", phase_started_at_usec)
		phase_started_at_usec = Time.get_ticks_usec()
		_finish_advance_day_processing()
		_log_perf_phase(true, "_on_summary_ready:finish_processing", phase_started_at_usec)
		call_deferred("_show_daily_recap_if_pending")
		_schedule_advance_day_post_recap_save_flush()
	_log_perf_elapsed("_on_summary_ready", started_at_usec)
	_refresh_ftue_progress()
	_refresh_first_hour_guide_progress()


func _set_advance_day_phase(label: String, play_pulse: bool = true) -> void:
	status_message = label
	if desktop_advance_day_button != null:
		desktop_advance_day_button.disabled = true
		desktop_advance_day_button.text = "%s..." % label.to_upper()
		desktop_advance_day_button.tooltip_text = "Processing the next trading day."
		if play_pulse:
			_play_advance_day_phase_pulse()
	if not advance_day_processing:
		_refresh_dashboard()
	_refresh_desktop()
	_refresh_hospital_overlay()
	_refresh_jail_overlay()


func _finish_advance_day_processing() -> void:
	advance_day_processing = false
	if desktop_advance_day_button != null:
		desktop_advance_day_button.disabled = false
		desktop_advance_day_button.text = "ADVANCE DAY"
		desktop_advance_day_button.tooltip_text = "Advance to the next trading day."
		_reset_advance_day_button_animation_state()
	_refresh_desktop()
	_refresh_hospital_overlay()
	_refresh_jail_overlay()


func _show_daily_recap_if_pending() -> void:
	if pending_daily_recap_snapshot.is_empty() or daily_recap_dialog == null or daily_recap_body_label == null:
		return
	_queue_macro_event_alerts_from_recap_snapshot(pending_daily_recap_snapshot)
	_queue_dirty_tip_alerts_from_recap_snapshot(pending_daily_recap_snapshot)
	daily_recap_body_label.text = _build_daily_recap_text(pending_daily_recap_snapshot)
	pending_daily_recap_snapshot = {}
	daily_recap_dialog.visible = true
	daily_recap_dialog.move_to_front()
	_play_daily_recap_reveal()
	_schedule_advance_day_post_recap_save_flush()
	_refresh_ftue_progress()
	_refresh_first_hour_guide_progress()


func _play_advance_day_button_feedback() -> void:
	if desktop_advance_day_button == null:
		return
	if advance_day_button_tween != null:
		advance_day_button_tween.kill()
		advance_day_button_tween = null
	_center_control_pivot(desktop_advance_day_button)
	if not UI_ANIMATIONS_ENABLED:
		_reset_control_animation_state(desktop_advance_day_button)
		return
	desktop_advance_day_button.scale = Vector2.ONE
	desktop_advance_day_button.modulate = Color.WHITE
	advance_day_button_tween = _create_ui_tween()
	advance_day_button_tween.tween_property(
		desktop_advance_day_button,
		"scale",
		Vector2(0.97, 0.97),
		UI_ADVANCE_BUTTON_PRESS_SECONDS * 0.45
	)
	advance_day_button_tween.tween_property(
		desktop_advance_day_button,
		"scale",
		Vector2.ONE,
		UI_ADVANCE_BUTTON_PRESS_SECONDS * 0.55
	)


func _play_advance_day_phase_pulse() -> void:
	if desktop_advance_day_button == null:
		return
	if advance_day_button_tween != null:
		advance_day_button_tween.kill()
		advance_day_button_tween = null
	_center_control_pivot(desktop_advance_day_button)
	if not UI_ANIMATIONS_ENABLED:
		_reset_control_animation_state(desktop_advance_day_button)
		return
	desktop_advance_day_button.scale = Vector2.ONE
	desktop_advance_day_button.modulate = Color.WHITE
	advance_day_button_tween = _create_ui_tween()
	advance_day_button_tween.tween_property(
		desktop_advance_day_button,
		"scale",
		Vector2(1.012, 1.012),
		UI_ADVANCE_PHASE_PULSE_SECONDS * 0.5
	)
	advance_day_button_tween.parallel().tween_property(
		desktop_advance_day_button,
		"modulate",
		Color(1.06, 1.05, 0.92, 1),
		UI_ADVANCE_PHASE_PULSE_SECONDS * 0.5
	)
	advance_day_button_tween.tween_property(
		desktop_advance_day_button,
		"scale",
		Vector2.ONE,
		UI_ADVANCE_PHASE_PULSE_SECONDS * 0.5
	)
	advance_day_button_tween.parallel().tween_property(
		desktop_advance_day_button,
		"modulate",
		Color.WHITE,
		UI_ADVANCE_PHASE_PULSE_SECONDS * 0.5
	)


func _reset_advance_day_button_animation_state() -> void:
	if advance_day_button_tween != null:
		advance_day_button_tween.kill()
		advance_day_button_tween = null
	_reset_control_animation_state(desktop_advance_day_button)


func _play_daily_recap_reveal() -> void:
	if daily_recap_dialog == null:
		return
	if daily_recap_tween != null:
		daily_recap_tween.kill()
		daily_recap_tween = null
	var scrim: ColorRect = daily_recap_dialog.find_child("DailyRecapScrim", true, false) as ColorRect
	var frame: Control = daily_recap_dialog.find_child("DailyRecapFrame", true, false) as Control
	if scrim == null and frame == null:
		return
	if not UI_ANIMATIONS_ENABLED:
		_reset_daily_recap_animation_state()
		return
	if scrim != null:
		var start_color: Color = scrim.color
		start_color.a = 0.0
		scrim.color = start_color
	if frame != null:
		frame.modulate = Color(1, 1, 1, 0)
	daily_recap_tween = _create_ui_tween()
	daily_recap_tween.set_trans(Tween.TRANS_SINE)
	daily_recap_tween.set_parallel(true)
	if scrim != null:
		daily_recap_tween.tween_property(
			scrim,
			"color:a",
			UI_DAILY_RECAP_SCRIM_ALPHA,
			UI_DAILY_RECAP_REVEAL_SECONDS
		)
	if frame != null:
		daily_recap_tween.tween_property(
			frame,
			"modulate",
			Color.WHITE,
			UI_DAILY_RECAP_REVEAL_SECONDS
		)


func _reset_daily_recap_animation_state() -> void:
	if daily_recap_tween != null:
		daily_recap_tween.kill()
		daily_recap_tween = null
	if daily_recap_dialog == null:
		return
	var scrim: ColorRect = daily_recap_dialog.find_child("DailyRecapScrim", true, false) as ColorRect
	if scrim != null:
		var color: Color = scrim.color
		color.a = UI_DAILY_RECAP_SCRIM_ALPHA
		scrim.color = color
	var frame: Control = daily_recap_dialog.find_child("DailyRecapFrame", true, false) as Control
	_reset_control_animation_state(frame)


func _queue_macro_event_alerts_from_recap_snapshot(snapshot: Dictionary) -> void:
	pending_macro_event_alerts = _build_macro_event_alerts_from_recap_snapshot(snapshot)
	current_macro_event_alert = {}


func _build_macro_event_alerts_from_recap_snapshot(snapshot: Dictionary) -> Array:
	var alerts: Array = []
	var last_day_results: Dictionary = snapshot.get("last_day_results", {})
	_append_macro_event_alert_if_market_scope(alerts, last_day_results.get("scheduled_event", {}))
	for event_value in last_day_results.get("started_special_events", []):
		if typeof(event_value) == TYPE_DICTIONARY:
			_append_macro_event_alert_if_market_scope(alerts, event_value)
	for event_value in last_day_results.get("index_review_events", []):
		if typeof(event_value) == TYPE_DICTIONARY:
			_append_macro_event_alert_if_market_scope(alerts, event_value)
	return alerts


func _append_macro_event_alert_if_market_scope(alerts: Array, event_data: Variant) -> void:
	if typeof(event_data) != TYPE_DICTIONARY:
		return
	var event_dictionary: Dictionary = event_data
	if event_dictionary.is_empty() or str(event_dictionary.get("scope", "")) != "market":
		return
	var headline: String = _macro_event_headline_for_event(event_dictionary)
	if headline.is_empty():
		return
	alerts.append({
		"event_id": str(event_dictionary.get("event_id", "")),
		"headline": headline
	})


func _macro_event_headline_for_event(event_data: Dictionary) -> String:
	var headline: String = str(event_data.get("headline", "")).strip_edges()
	if not headline.is_empty():
		return headline
	var event_definition: Dictionary = DataRepository.get_event_definition(str(event_data.get("event_id", "")))
	headline = str(event_definition.get("headline_template", "")).strip_edges()
	if not headline.is_empty():
		return headline
	headline = str(event_data.get("description", "")).strip_edges()
	if not headline.is_empty():
		return headline
	return str(event_definition.get("description", "")).strip_edges()


func _show_next_macro_event_alert() -> void:
	if macro_event_dialog == null or macro_event_headline_label == null:
		return
	if macro_event_dialog.visible:
		return
	if pending_macro_event_alerts.is_empty():
		current_macro_event_alert = {}
		call_deferred("_show_next_dirty_tip_alert")
		return
	var next_alert: Variant = pending_macro_event_alerts.pop_front()
	if typeof(next_alert) != TYPE_DICTIONARY:
		call_deferred("_show_next_macro_event_alert")
		return
	current_macro_event_alert = next_alert
	var headline: String = str(current_macro_event_alert.get("headline", "")).strip_edges()
	if headline.is_empty():
		call_deferred("_show_next_macro_event_alert")
		return
	macro_event_headline_label.text = headline
	macro_event_headline_label.visible_characters = 0
	macro_event_dialog.visible = true
	macro_event_dialog.move_to_front()
	_play_macro_event_headline_type()


func _play_macro_event_headline_type() -> void:
	if macro_event_headline_label == null:
		return
	if macro_event_tween != null:
		macro_event_tween.kill()
		macro_event_tween = null
	var character_count: int = macro_event_headline_label.text.length()
	if character_count <= 0 or not UI_ANIMATIONS_ENABLED:
		macro_event_headline_label.visible_characters = character_count
		return
	macro_event_headline_label.visible_characters = 0
	macro_event_tween = _create_ui_tween()
	macro_event_tween.tween_property(
		macro_event_headline_label,
		"visible_characters",
		character_count,
		clamp(
			float(character_count) * UI_MACRO_EVENT_TYPE_SECONDS_PER_CHAR,
			UI_MACRO_EVENT_TYPE_MIN_SECONDS,
			UI_MACRO_EVENT_TYPE_MAX_SECONDS
		)
	)


func _on_macro_event_confirm_pressed() -> void:
	if macro_event_dialog == null or not macro_event_dialog.visible:
		return
	if _macro_event_headline_is_typing():
		_complete_macro_event_headline_type()
		return
	_dismiss_current_macro_event_alert()


func _macro_event_headline_is_typing() -> bool:
	if macro_event_headline_label == null:
		return false
	return macro_event_headline_label.visible_characters >= 0 and macro_event_headline_label.visible_characters < macro_event_headline_label.text.length()


func _complete_macro_event_headline_type() -> void:
	if macro_event_tween != null:
		macro_event_tween.kill()
		macro_event_tween = null
	if macro_event_headline_label != null:
		macro_event_headline_label.visible_characters = macro_event_headline_label.text.length()


func _dismiss_current_macro_event_alert(show_next: bool = true) -> void:
	if macro_event_tween != null:
		macro_event_tween.kill()
		macro_event_tween = null
	if macro_event_dialog != null:
		macro_event_dialog.visible = false
	if macro_event_headline_label != null:
		macro_event_headline_label.visible_characters = macro_event_headline_label.text.length()
	current_macro_event_alert = {}
	if show_next:
		if not pending_macro_event_alerts.is_empty():
			call_deferred("_show_next_macro_event_alert")
		else:
			call_deferred("_show_next_dirty_tip_alert")


func _on_macro_event_dialog_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			_on_macro_event_confirm_pressed()
			get_viewport().set_input_as_handled()


func _queue_dirty_tip_alerts_from_recap_snapshot(snapshot: Dictionary) -> void:
	pending_dirty_tip_alerts.clear()
	current_dirty_tip_alert = {}
	var last_day_results: Dictionary = snapshot.get("last_day_results", {})
	for offer_value in last_day_results.get("dirty_tip_offers", []):
		if typeof(offer_value) != TYPE_DICTIONARY:
			continue
		var offer: Dictionary = offer_value
		if str(offer.get("request_type", "")) != "dirty_tip":
			continue
		if str(offer.get("status", "")) != "offered":
			continue
		pending_dirty_tip_alerts.append(offer.duplicate(true))


func _show_next_dirty_tip_alert() -> void:
	if dirty_tip_dialog == null or dirty_tip_body_label == null:
		return
	if dirty_tip_dialog.visible:
		return
	if pending_dirty_tip_alerts.is_empty():
		current_dirty_tip_alert = {}
		return
	var next_alert: Variant = pending_dirty_tip_alerts.pop_front()
	if typeof(next_alert) != TYPE_DICTIONARY:
		call_deferred("_show_next_dirty_tip_alert")
		return
	current_dirty_tip_alert = next_alert
	dirty_tip_body_label.text = _dirty_tip_body_text(current_dirty_tip_alert)
	dirty_tip_dialog.visible = true
	dirty_tip_dialog.move_to_front()


func _dirty_tip_body_text(offer: Dictionary) -> String:
	var headline: String = str(offer.get("offer_headline", "A dirty market offer appears.")).strip_edges()
	var body: String = str(offer.get("offer_body", "")).strip_edges()
	var ticker: String = str(offer.get("target_ticker", "")).strip_edges()
	var duration: int = int(offer.get("case_days", 0))
	var lines: Array[String] = [headline]
	if not body.is_empty():
		lines.append("")
		lines.append(body)
	if not ticker.is_empty() and duration > 0:
		lines.append("")
		lines.append("The room says the window is only %d trading day%s. Getting involved may leave a trail." % [
			duration,
			"" if duration == 1 else "s"
		])
	return "\n".join(lines)


func _accept_current_dirty_tip_alert() -> void:
	_resolve_current_dirty_tip_alert("accept")


func _decline_current_dirty_tip_alert() -> void:
	_resolve_current_dirty_tip_alert("decline")


func _report_current_dirty_tip_alert() -> void:
	_resolve_current_dirty_tip_alert("report")


func _resolve_current_dirty_tip_alert(action_id: String) -> void:
	if current_dirty_tip_alert.is_empty():
		if dirty_tip_dialog != null:
			dirty_tip_dialog.visible = false
		return
	var offer_id: String = str(current_dirty_tip_alert.get("id", ""))
	var result: Dictionary = {}
	match action_id:
		"accept":
			result = GameManager.accept_dirty_tip_offer(offer_id)
		"report":
			result = GameManager.report_dirty_tip_offer(offer_id)
		_:
			result = GameManager.decline_dirty_tip_offer(offer_id)
	if dirty_tip_dialog != null:
		dirty_tip_dialog.visible = false
	current_dirty_tip_alert = {}
	if not result.is_empty():
		_show_toast(str(result.get("message", "Dirty tip updated.")), bool(result.get("success", false)))
	_refresh_desktop()
	if _is_desktop_app_window_open(APP_ID_NETWORK):
		_refresh_network()
	if not pending_dirty_tip_alerts.is_empty():
		call_deferred("_show_next_dirty_tip_alert")


func _build_daily_recap_text(snapshot: Dictionary) -> String:
	var summary: Dictionary = snapshot.get("summary", {})
	var trade_date: Dictionary = snapshot.get("trade_date", {})
	var activity_counts: Dictionary = snapshot.get("activity_counts", {})
	var daily_action: Dictionary = snapshot.get("daily_action", {})
	var lines: Array[String] = []
	lines.append("%s" % GameManager.format_trade_date(trade_date))
	lines.append("Index Gorengan today: %s" % _format_change(float(snapshot.get("market_sentiment", 0.0))))
	lines.append("Portfolio: %s | Equity %s" % [
		_format_signed_currency(float(summary.get("portfolio_delta", 0.0))),
		_format_currency(float(summary.get("portfolio_value", snapshot.get("portfolio", {}).get("equity", 0.0))))
	])
	var portfolio_attribution_lines: Array[String] = _build_daily_recap_portfolio_attribution_lines(summary)
	if not portfolio_attribution_lines.is_empty():
		lines.append("")
		lines.append("Why Portfolio Moved")
		lines.append_array(portfolio_attribution_lines)
	lines.append("")
	lines.append(_daily_recap_mover_line("Best tape", summary.get("biggest_winner", {})))
	lines.append(_daily_recap_mover_line("Weakest tape", summary.get("biggest_loser", {})))
	lines.append("")
	lines.append("Activity: News %d | Twooter %d | Network %d" % [
		int(activity_counts.get("news", 0)),
		int(activity_counts.get("social", 0)),
		int(activity_counts.get("network", 0))
	])
	lines.append("AP reset: %d / %d remaining" % [
		int(daily_action.get("remaining", 0)),
		int(daily_action.get("limit", 0))
	])
	var cash_ap_lines: Array[String] = _build_daily_recap_cash_ap_lines(snapshot)
	if not cash_ap_lines.is_empty():
		lines.append("")
		lines.append("Cash & AP")
		lines.append_array(cash_ap_lines)
	var fail_state_lines: Array[String] = _build_daily_recap_fail_state_lines(snapshot)
	if not fail_state_lines.is_empty():
		lines.append("")
		lines.append("Risk Check")
		lines.append_array(fail_state_lines)
	var guide_hint: String = _first_hour_guide_daily_recap_hint()
	if not guide_hint.is_empty():
		lines.append("")
		lines.append("Next useful step: %s" % guide_hint)
	return "\n".join(lines)


func _build_daily_recap_portfolio_attribution_lines(summary: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for row_value in summary.get("portfolio_attribution", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("- %s: %s from %s move" % [
			str(row.get("ticker", "")),
			_format_signed_currency(float(row.get("market_value_delta", 0.0))),
			_format_change(float(row.get("price_change_pct", 0.0)))
		])
		if lines.size() >= 3:
			break
	return lines


func _build_daily_recap_cash_ap_lines(snapshot: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var first_month: Dictionary = snapshot.get("first_month_balance", {})
	var last_day_results: Dictionary = snapshot.get("last_day_results", {})
	var life_obligation: Dictionary = last_day_results.get("life_obligation", {})
	if not life_obligation.is_empty():
		lines.append("Life paid %s; cash now %s." % [
			_format_currency(float(life_obligation.get("amount", 0.0))),
			_format_currency(float(life_obligation.get("cash_after", first_month.get("cash", 0.0))))
		])
	var life_loan_payment: Dictionary = last_day_results.get("life_loan_payment", {})
	if not life_loan_payment.is_empty():
		lines.append("Emergency loan paid %s; cash now %s." % [
			_format_currency(float(life_loan_payment.get("amount", 0.0))),
			_format_currency(float(life_loan_payment.get("cash_after", first_month.get("cash", 0.0))))
		])
	var next_life: Dictionary = first_month.get("next_life_payment", snapshot.get("life", {}).get("next_life_payment", {}))
	if not next_life.is_empty() and bool(next_life.get("warning", false)):
		lines.append("Next Life payment: %s due %s." % [
			_format_currency(float(next_life.get("amount", 0.0))),
			str(next_life.get("date_text", "soon"))
		])
	var daily_action: Dictionary = first_month.get("daily_action", snapshot.get("daily_action", {}))
	var remaining_ap: int = int(daily_action.get("remaining", 0))
	var limit_ap: int = int(daily_action.get("limit", 0))
	if limit_ap > 0 and remaining_ap <= 2:
		lines.append("AP pressure: %d AP left; basic trading, chart reading, Portfolio, and Dashboard review still work." % remaining_ap)
	return lines


func _build_daily_recap_fail_state_lines(snapshot: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var last_day_results: Dictionary = snapshot.get("last_day_results", {})
	var life_obligation: Dictionary = last_day_results.get("life_obligation", {})
	var life_loan_payment: Dictionary = last_day_results.get("life_loan_payment", {})
	if not life_obligation.is_empty():
		var amount: float = float(life_obligation.get("amount", 0.0))
		var cash_after: float = float(life_obligation.get("cash_after", 0.0))
		if amount > 0.0:
			lines.append("Life: paid %s monthly obligations. Cash now %s." % [
				_format_currency(amount),
				_format_currency(cash_after)
			])
			if cash_after < 0.0:
				lines.append("Cash stress: obligations pushed cash below zero. Sell holdings, lower Life costs, or keep more cash before next month.")
	if not life_loan_payment.is_empty():
		var payment_amount: float = float(life_loan_payment.get("amount", 0.0))
		var payment_cash_after: float = float(life_loan_payment.get("cash_after", 0.0))
		lines.append("Loan: paid %s emergency loan installment. Cash now %s." % [
			_format_currency(payment_amount),
			_format_currency(payment_cash_after)
		])
		if payment_cash_after < 0.0:
			lines.append("Cash stress: loan payment pushed cash below zero. Use Life > Finance or sell holdings before the grace expires.")

	var missed_requests: int = 0
	for request_result_value in last_day_results.get("network_request_results", []):
		if typeof(request_result_value) != TYPE_DICTIONARY:
			continue
		var request_result: Dictionary = request_result_value
		if not bool(request_result.get("success", false)):
			missed_requests += 1
	if missed_requests > 0:
		var request_suffix: String = "" if missed_requests == 1 else "s"
		lines.append("Network: %d request%s missed because the required holding was not met." % [missed_requests, request_suffix])

	var poor_tip_reads: int = 0
	for tip_result_value in last_day_results.get("network_tip_results", []):
		if typeof(tip_result_value) != TYPE_DICTIONARY:
			continue
		var tip_result: Dictionary = tip_result_value
		if int(tip_result.get("relationship_delta", 0)) < 0:
			poor_tip_reads += 1
	if poor_tip_reads > 0:
		var tip_suffix: String = "" if poor_tip_reads == 1 else "s"
		lines.append("Network: %d read%s hurt trust. Review the journal before acting on similar tips." % [poor_tip_reads, tip_suffix])

	var life: Dictionary = snapshot.get("life", {})
	var finance_status: Dictionary = life.get("finance", {})
	var cash: float = float(life.get("cash", 0.0))
	var monthly_outflow: float = float(life.get("monthly_outflow", 0.0))
	var runway_months: float = float(life.get("runway_months", 999.0))
	if bool(finance_status.get("bankrupt", false)):
		lines.append("Bankruptcy: the run has ended because cash stayed negative with no recovery path.")
	elif bool(finance_status.get("cash_stress_active", false)):
		lines.append("Cash stress: %d trading day%s of grace remain. Life > Finance shows recovery options." % [
			int(finance_status.get("cash_stress_days_remaining", 0)),
			"" if int(finance_status.get("cash_stress_days_remaining", 0)) == 1 else "s"
		])
	if bool(finance_status.get("loan_payment_risky", false)):
		var active_loan: Dictionary = finance_status.get("active_loan", {})
		lines.append("Loan reserve: keep cash above %s before new spending." % _format_currency(float(active_loan.get("monthly_payment", 0.0))))
	if monthly_outflow > 0.0 and cash >= 0.0 and runway_months < 3.0:
		lines.append("Runway: cash covers %.1f month(s). Keep the next trade small or raise cash." % runway_months)
	elif monthly_outflow > 0.0 and cash < monthly_outflow:
		lines.append("Runway: cash is below one month of planned Life costs.")
	return lines


func _daily_recap_mover_line(label: String, row: Dictionary) -> String:
	if row.is_empty():
		return "%s: -" % label
	return "%s: %s %s" % [
		label,
		str(row.get("ticker", "----")),
		_format_change(float(row.get("change_pct", 0.0)))
	]


func _daily_recap_market_mood(sentiment: float) -> String:
	if sentiment >= 0.015:
		return "Risk-on %s" % _format_change(sentiment)
	if sentiment <= -0.015:
		return "Defensive %s" % _format_change(sentiment)
	return "Mixed %s" % _format_change(sentiment)


func _on_lot_size_changed(value: float) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_lot_size_changed(value)
	stock_controller._sync_root_refs()
func _show_ftue_if_needed() -> void:
	_ensure_ftue_overlay()
	_refresh_ftue_progress()


func _ensure_ftue_overlay() -> void:
	if ftue_overlay != null:
		return

	ftue_overlay = Control.new()
	ftue_overlay.name = "GuideCoachmarkOverlay"
	ftue_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	ftue_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ftue_overlay.visible = false
	add_child(ftue_overlay)

	ftue_dim_top = _build_ftue_dim_rect("FtueDimTop")
	ftue_dim_bottom = _build_ftue_dim_rect("FtueDimBottom")
	ftue_dim_left = _build_ftue_dim_rect("FtueDimLeft")
	ftue_dim_right = _build_ftue_dim_rect("FtueDimRight")
	ftue_overlay.add_child(ftue_dim_top)
	ftue_overlay.add_child(ftue_dim_bottom)
	ftue_overlay.add_child(ftue_dim_left)
	ftue_overlay.add_child(ftue_dim_right)

	ftue_highlight_frame = PanelContainer.new()
	ftue_highlight_frame.name = "GuideHighlightFrame"
	ftue_highlight_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ftue_overlay.add_child(ftue_highlight_frame)

	ftue_card = PanelContainer.new()
	ftue_card.name = "GuideCoachmarkPanel"
	ftue_card.custom_minimum_size = FTUE_CARD_SIZE
	ftue_card.mouse_filter = Control.MOUSE_FILTER_STOP
	ftue_card.visible = false
	add_child(ftue_card)

	var card_margin := MarginContainer.new()
	card_margin.name = "GuideCoachmarkMargin"
	card_margin.add_theme_constant_override("margin_left", 18)
	card_margin.add_theme_constant_override("margin_top", 16)
	card_margin.add_theme_constant_override("margin_right", 18)
	card_margin.add_theme_constant_override("margin_bottom", 16)
	ftue_card.add_child(card_margin)

	var card_vbox := VBoxContainer.new()
	card_vbox.name = "GuideCoachmarkVBox"
	card_vbox.add_theme_constant_override("separation", 9)
	card_margin.add_child(card_vbox)

	ftue_title_label = Label.new()
	ftue_title_label.name = "GuideCoachmarkTitleLabel"
	ftue_title_label.text = ""
	ftue_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_vbox.add_child(ftue_title_label)

	ftue_objective_label = Label.new()
	ftue_objective_label.name = "GuideCoachmarkObjectiveLabel"
	ftue_objective_label.text = ""
	ftue_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_vbox.add_child(ftue_objective_label)

	ftue_body_label = Label.new()
	ftue_body_label.name = "GuideCoachmarkBodyLabel"
	ftue_body_label.text = ""
	ftue_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_vbox.add_child(ftue_body_label)

	ftue_status_label = Label.new()
	ftue_status_label.name = "GuideCoachmarkStatusLabel"
	ftue_status_label.text = ""
	ftue_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_vbox.add_child(ftue_status_label)

	var footer := HBoxContainer.new()
	footer.name = "GuideCoachmarkFooter"
	footer.add_theme_constant_override("separation", 8)
	card_vbox.add_child(footer)

	ftue_progress_label = Label.new()
	ftue_progress_label.name = "GuideCoachmarkProgressLabel"
	ftue_progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(ftue_progress_label)

	ftue_hub_button = Button.new()
	ftue_hub_button.name = "GuideHubButton"
	ftue_hub_button.text = "Guide Hub"
	ftue_hub_button.custom_minimum_size = Vector2(104, 34)
	ftue_hub_button.pressed.connect(_show_guide_hub)
	footer.add_child(ftue_hub_button)

	ftue_dismiss_button = Button.new()
	ftue_dismiss_button.name = "GuidePromptDismissButton"
	ftue_dismiss_button.text = "Later"
	ftue_dismiss_button.custom_minimum_size = Vector2(78, 34)
	ftue_dismiss_button.pressed.connect(_on_guide_prompt_dismiss_pressed)
	footer.add_child(ftue_dismiss_button)

	ftue_skip_button = Button.new()
	ftue_skip_button.name = "GuideCoachmarkSkipButton"
	ftue_skip_button.text = "Skip Flow"
	ftue_skip_button.custom_minimum_size = Vector2(104, 34)
	ftue_skip_button.pressed.connect(_on_ftue_skip_pressed)
	footer.add_child(ftue_skip_button)
	_ensure_guide_hub()
	_style_ftue_overlay()


func _build_ftue_dim_rect(rect_name: String) -> ColorRect:
	var dim_rect := ColorRect.new()
	dim_rect.name = rect_name
	dim_rect.color = Color(0.0, 0.0, 0.0, 0.30)
	dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return dim_rect


func _ensure_guide_hub() -> void:
	if guide_hub_overlay != null:
		_ensure_guide_hub_entry_points()
		return
	guide_hub_overlay = Control.new()
	guide_hub_overlay.name = "GuideHubOverlay"
	guide_hub_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	guide_hub_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide_hub_overlay.visible = false
	add_child(guide_hub_overlay)

	var scrim := ColorRect.new()
	scrim.name = "GuideHubScrim"
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.0, 0.0, 0.0, 0.22)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	guide_hub_overlay.add_child(scrim)

	guide_hub_panel = PanelContainer.new()
	guide_hub_panel.name = "GuideHubPanel"
	guide_hub_panel.custom_minimum_size = Vector2(720, 520)
	guide_hub_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	guide_hub_overlay.add_child(guide_hub_panel)

	var margin := MarginContainer.new()
	margin.name = "GuideHubMargin"
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	guide_hub_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "GuideHubVBox"
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.name = "GuideHubHeader"
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)
	var title := Label.new()
	title.name = "GuideHubTitleLabel"
	title.text = "Guide Hub"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
	title.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE + 6)
	header.add_child(title)
	guide_hub_close_button = Button.new()
	guide_hub_close_button.name = "GuideHubCloseButton"
	guide_hub_close_button.text = "Close"
	guide_hub_close_button.custom_minimum_size = Vector2(92, 34)
	guide_hub_close_button.pressed.connect(_hide_guide_hub)
	header.add_child(guide_hub_close_button)

	var body := Label.new()
	body.name = "GuideHubBodyLabel"
	body.text = "Start a short guide when the related system matters. Completed and skipped guides stay available for review."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)
	body.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE + 1)
	vbox.add_child(body)

	var scroll := ScrollContainer.new()
	scroll.name = "GuideHubScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	guide_hub_flow_list = VBoxContainer.new()
	guide_hub_flow_list.name = "GuideHubFlowList"
	guide_hub_flow_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guide_hub_flow_list.add_theme_constant_override("separation", 8)
	scroll.add_child(guide_hub_flow_list)

	_style_panel(guide_hub_panel, COLOR_DESKTOP_CREAM, 8)
	_style_button(guide_hub_close_button, COLOR_DESKTOP_BROWN, COLOR_ACADEMY_BORDER, COLOR_DESKTOP_CREAM, 6)
	_ensure_guide_hub_entry_points()


func _ensure_guide_hub_entry_points() -> void:
	if guide_hub_taskbar_button == null and taskbar_status_label != null:
		var taskbar_row: Control = taskbar_status_label.get_parent() as Control
		if taskbar_row != null:
			guide_hub_taskbar_button = Button.new()
			guide_hub_taskbar_button.name = "GuideHubTaskbarButton"
			guide_hub_taskbar_button.text = "Guide"
			guide_hub_taskbar_button.custom_minimum_size = Vector2(78, 32)
			guide_hub_taskbar_button.tooltip_text = "Open Guide Hub."
			guide_hub_taskbar_button.pressed.connect(_show_guide_hub)
			taskbar_row.add_child(guide_hub_taskbar_button)
			taskbar_row.move_child(guide_hub_taskbar_button, taskbar_status_label.get_index())
	if guide_hub_help_button == null and help_text_label != null:
		var help_vbox: Control = help_text_label.get_parent() as Control
		if help_vbox != null:
			guide_hub_help_button = Button.new()
			guide_hub_help_button.name = "HelpGuideHubButton"
			guide_hub_help_button.text = "Open Guide Hub"
			guide_hub_help_button.custom_minimum_size = Vector2(160, 34)
			guide_hub_help_button.tooltip_text = "Start, resume, or revisit guide flows."
			guide_hub_help_button.pressed.connect(_show_guide_hub)
			help_vbox.add_child(guide_hub_help_button)
			help_vbox.move_child(guide_hub_help_button, help_text_label.get_index())
	if guide_hub_taskbar_button != null:
		_style_button(guide_hub_taskbar_button, COLOR_DESKTOP_PANEL, COLOR_DESKTOP_FRAME, COLOR_DESKTOP_TEXT, 5)
	if guide_hub_help_button != null:
		_style_button(guide_hub_help_button, COLOR_DESKTOP_GOLD, Color(0.643137, 0.466667, 0.137255, 1), COLOR_DESKTOP_TEXT, 6)


func _show_guide_hub() -> void:
	_ensure_guide_hub()
	_refresh_guide_hub()
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_size: Vector2 = guide_hub_panel.get_combined_minimum_size()
	panel_size.x = min(max(panel_size.x, 720.0), max(viewport_size.x - 48.0, 320.0))
	panel_size.y = min(max(panel_size.y, 520.0), max(viewport_size.y - 72.0, 360.0))
	guide_hub_panel.size = panel_size
	guide_hub_panel.position = Vector2((viewport_size.x - panel_size.x) * 0.5, (viewport_size.y - panel_size.y) * 0.5)
	guide_hub_overlay.visible = true
	guide_hub_overlay.move_to_front()


func _hide_guide_hub() -> void:
	if guide_hub_overlay != null:
		guide_hub_overlay.visible = false


func _refresh_guide_hub() -> void:
	if guide_hub_flow_list == null:
		return
	_clear_node_children(guide_hub_flow_list)
	for flow_value in GameManager.get_available_guide_flows():
		if typeof(flow_value) != TYPE_DICTIONARY:
			continue
		guide_hub_flow_list.add_child(_build_guide_hub_flow_row(flow_value))


func _build_guide_hub_flow_row(flow: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "GuideHubFlow_%s" % _node_token(str(flow.get("id", "")))
	_style_panel(panel, Color(0.984314, 0.964706, 0.886275, 1), 6)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var title := Label.new()
	var flow_is_enabled: bool = bool(flow.get("enabled", true))
	var flow_status: String = str(flow.get("status", ""))
	title.text = "%s  |  %s" % [str(flow.get("label", "")), "Coming Soon" if not flow_is_enabled else flow_status.capitalize()]
	title.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
	title.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE + 2)
	copy.add_child(title)
	var body := Label.new()
	body.text = GameManager.get_academy_release_message() if not flow_is_enabled and str(flow.get("id", "")) == RunState.GUIDE_FLOW_SYSTEM.FLOW_ACADEMY else str(flow.get("description", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)
	body.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	copy.add_child(body)
	var action := Button.new()
	action.name = "GuideHubStart%sButton" % _node_token(str(flow.get("id", "")))
	action.text = "Soon" if not flow_is_enabled else ("Resume" if flow_status == "active" else ("Restart" if flow_status == "completed" else "Start"))
	action.custom_minimum_size = Vector2(96, 34)
	action.disabled = not flow_is_enabled
	action.tooltip_text = GameManager.get_academy_release_message() if not flow_is_enabled else "Start or resume this guide."
	if flow_is_enabled:
		action.pressed.connect(_on_guide_hub_flow_pressed.bind(str(flow.get("id", ""))))
	_style_button(action, COLOR_DESKTOP_GOLD, Color(0.643137, 0.466667, 0.137255, 1), COLOR_DESKTOP_TEXT, 6)
	row.add_child(action)
	return panel


func _on_guide_hub_flow_pressed(flow_id: String) -> void:
	GameManager.start_guide_flow(flow_id)
	_hide_guide_hub()
	_refresh_ftue_progress()


func _clear_node_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _node_token(value: String) -> String:
	var token := ""
	for index in range(value.length()):
		var character := value.substr(index, 1)
		if character.is_valid_identifier():
			token += character
		elif character == "_" or character == "-":
			token += "_"
	return token.capitalize().replace(" ", "")


func _style_ftue_overlay() -> void:
	if ftue_highlight_frame != null:
		var highlight_style := StyleBoxFlat.new()
		highlight_style.bg_color = Color(1.0, 0.89, 0.35, 0.08)
		highlight_style.border_color = COLOR_DESKTOP_GOLD
		highlight_style.set_border_width_all(3)
		highlight_style.set_corner_radius_all(6)
		ftue_highlight_frame.add_theme_stylebox_override("panel", highlight_style)

	if ftue_card != null:
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = COLOR_DESKTOP_CREAM
		card_style.border_color = COLOR_DESKTOP_BROWN
		card_style.set_border_width_all(2)
		card_style.set_corner_radius_all(6)
		ftue_card.add_theme_stylebox_override("panel", card_style)

	if ftue_title_label != null:
		ftue_title_label.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
		ftue_title_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE + 5)
	if ftue_objective_label != null:
		ftue_objective_label.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)
		ftue_objective_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE + 2)
	if ftue_body_label != null:
		ftue_body_label.add_theme_color_override("font_color", Color(0.282353, 0.247059, 0.160784, 1))
		ftue_body_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE + 1)
	if ftue_status_label != null:
		ftue_status_label.add_theme_color_override("font_color", Color(0.454902, 0.337255, 0.141176, 1))
		ftue_status_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	if ftue_progress_label != null:
		ftue_progress_label.add_theme_color_override("font_color", Color(0.423529, 0.337255, 0.188235, 1))
		ftue_progress_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	if ftue_hub_button != null:
		_style_button(ftue_hub_button, COLOR_DESKTOP_GOLD, Color(0.643137, 0.466667, 0.137255, 1), COLOR_DESKTOP_TEXT, 6)
	if ftue_dismiss_button != null:
		_style_button(ftue_dismiss_button, Color(0.835294, 0.819608, 0.772549, 1), Color(0.658824, 0.631373, 0.552941, 1), COLOR_WINDOW_TEXT, 6)
	if ftue_skip_button != null:
		_style_button(ftue_skip_button, COLOR_DESKTOP_BROWN, COLOR_ACADEMY_BORDER, COLOR_DESKTOP_CREAM, 6)


func _hide_ftue_overlay() -> void:
	if ftue_overlay != null:
		ftue_overlay.visible = false
	for dim_rect in [ftue_dim_top, ftue_dim_bottom, ftue_dim_left, ftue_dim_right]:
		if dim_rect != null:
			dim_rect.visible = false
	if ftue_highlight_frame != null:
		ftue_highlight_frame.visible = false
	if ftue_card != null:
		ftue_card.visible = false
	if first_hour_guide_panel != null:
		first_hour_guide_panel.visible = false
	if first_hour_guide_highlight_layer != null:
		first_hour_guide_highlight_layer.visible = false
	ftue_last_step_id = ""


func _refresh_ftue_progress() -> void:
	if guide_focus_in_progress:
		return
	if not _ensure_active_or_contextual_guide():
		_sync_guide_flow_tracking("")
		_hide_ftue_overlay()
		return

	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	_sync_guide_flow_tracking(str(snapshot.get("active_flow_id", "")))
	var active_flow_id: String = str(snapshot.get("active_flow_id", ""))
	var current_step_id: String = str(snapshot.get("active_step_id", ""))
	var advanced: bool = false
	_guide_prepare_step(snapshot)
	advanced = _guide_step_completed(snapshot)

	if advanced and GameManager.advance_guide_step(active_flow_id, current_step_id):
		call_deferred("_refresh_ftue_progress")
		_refresh_ftue_overlay()
		return

	_refresh_ftue_overlay()


func _sync_guide_flow_tracking(active_flow_id: String) -> void:
	if active_flow_id == guide_active_flow_id:
		return
	guide_active_flow_id = active_flow_id
	if active_flow_id == RunState.GUIDE_FLOW_SYSTEM.FLOW_WATCHLIST:
		guide_watchlist_all_stock_seen = false
		guide_watchlist_stock_selected = false
	if active_flow_id == RunState.GUIDE_FLOW_SYSTEM.FLOW_RESEARCH:
		guide_research_interaction_seen = false
	if active_flow_id == RunState.GUIDE_FLOW_SYSTEM.FLOW_FUNDAMENTAL:
		guide_fundamental_key_stats_seen = false
		guide_fundamental_financials_seen = false
	if active_flow_id == RunState.GUIDE_FLOW_SYSTEM.FLOW_TECHNICAL:
		guide_technical_tool_action_seen = false
	if active_flow_id == RunState.GUIDE_FLOW_SYSTEM.FLOW_THESIS:
		guide_thesis_subject_chosen = false
		guide_thesis_create_action_seen = false
	if active_flow_id == RunState.GUIDE_FLOW_SYSTEM.FLOW_LIFE_FINANCE:
		guide_life_plan_reviewed = false
		guide_life_finance_tab_seen = false
	if active_flow_id == RunState.GUIDE_FLOW_SYSTEM.FLOW_ACADEMY:
		guide_academy_lesson_chosen = false
		guide_academy_read_action_seen = false


func _refresh_ftue_overlay() -> void:
	if ftue_overlay == null:
		return
	if not GameManager.get_guide_snapshot().get("enabled", false):
		_hide_ftue_overlay()
		return

	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	var flow_id: String = str(snapshot.get("active_flow_id", ""))
	var step_id: String = str(snapshot.get("active_step_id", ""))
	if flow_id.is_empty() or step_id.is_empty() or _ftue_should_pause_for_modal(step_id):
		ftue_overlay.visible = false
		for dim_rect in [ftue_dim_top, ftue_dim_bottom, ftue_dim_left, ftue_dim_right]:
			if dim_rect != null:
				dim_rect.visible = false
		if ftue_highlight_frame != null:
			ftue_highlight_frame.visible = false
		if ftue_card != null:
			ftue_card.visible = false
		return

	var step: Dictionary = snapshot.get("step", {})
	ftue_title_label.text = str(step.get("title", snapshot.get("flow_label", "Guide")))
	ftue_objective_label.text = "Objective: %s" % str(step.get("objective", "Follow the highlighted control."))
	ftue_body_label.text = str(step.get("body", ""))
	var status_text: String = _guide_status_text(snapshot)
	if ftue_status_label != null:
		ftue_status_label.text = status_text
		ftue_status_label.visible = not status_text.is_empty()
	var step_index: int = max(int(snapshot.get("step_index", 0)), 0)
	var step_count: int = max(int(snapshot.get("step_count", 1)), 1)
	ftue_progress_label.text = "%s  |  Step %d of %d" % [str(snapshot.get("flow_short_label", "Guide")), step_index + 1, step_count]
	ftue_skip_button.text = "Done" if step_id == "handoff" else "Skip Flow"
	if ftue_dismiss_button != null:
		ftue_dismiss_button.visible = not [RunState.GUIDE_FLOW_SYSTEM.FLOW_WATCHLIST, RunState.GUIDE_FLOW_SYSTEM.FLOW_TRADE].has(flow_id)

	var target_rect: Rect2 = _guide_target_rect_for_snapshot(snapshot)
	_layout_ftue_highlight(target_rect)
	_position_ftue_card(target_rect)
	ftue_overlay.visible = true
	ftue_card.visible = true
	ftue_overlay.move_to_front()
	ftue_card.move_to_front()
	ftue_last_step_id = "%s:%s" % [flow_id, step_id]


func _ftue_should_pause_for_modal(step_id: String) -> bool:
	if daily_recap_dialog != null and daily_recap_dialog.visible:
		return step_id != "read_recap"
	if rupslb_meeting_overlay != null and rupslb_meeting_overlay.visible:
		return true
	if corporate_meeting_overlay != null and corporate_meeting_overlay.visible:
		return true
	if watchlist_picker_dialog != null and watchlist_picker_dialog.visible:
		return true
	if upgrade_purchase_dialog != null and upgrade_purchase_dialog.visible:
		return true
	if settings_dialog != null and settings_dialog.visible:
		return true
	return false


func _ensure_active_or_contextual_guide() -> bool:
	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	if not str(snapshot.get("active_flow_id", "")).is_empty():
		return true
	var context_id: String = _guide_context_id_for_current_surface()
	var prompt: Dictionary = GameManager.get_contextual_guide_prompt(context_id)
	if prompt.is_empty():
		return false
	GameManager.start_guide_flow(str(prompt.get("flow_id", "")))
	return not str(GameManager.get_guide_snapshot().get("active_flow_id", "")).is_empty()


func _guide_context_id_for_current_surface() -> String:
	if active_app_id == APP_ID_NEWS or active_app_id == APP_ID_SOCIAL:
		return "research"
	if active_app_id == APP_ID_ACADEMY and GameManager.is_academy_available():
		return "academy"
	if active_app_id == APP_ID_THESIS:
		return "thesis"
	if active_app_id == APP_ID_LIFE:
		return "life_finance"
	if active_app_id == APP_ID_STOCK:
		if _current_work_tab_title() in ["Key Stats", "Financials"]:
			return "fundamental"
		if _current_work_tab_title() == "Chart":
			return "technical"
		return "trade"
	if rupslb_meeting_overlay != null and rupslb_meeting_overlay.visible:
		return "corporate_event"
	return ""


func _guide_prepare_step(snapshot: Dictionary) -> void:
	var flow_id: String = str(snapshot.get("active_flow_id", ""))
	var step_id: String = str(snapshot.get("active_step_id", ""))
	if flow_id == RunState.GUIDE_FLOW_SYSTEM.FLOW_CORPORATE_EVENT and step_id == "schedule_event":
		var hook_result: Dictionary = GameManager.ensure_first_hour_guide_hook()
		if bool(hook_result.get("success", false)):
			return


func _guide_step_completed(snapshot: Dictionary) -> bool:
	var flow_id: String = str(snapshot.get("active_flow_id", ""))
	var step_id: String = str(snapshot.get("active_step_id", ""))
	match flow_id:
		RunState.GUIDE_FLOW_SYSTEM.FLOW_WATCHLIST:
			match step_id:
				"open_stockbot":
					return active_app_id == APP_ID_STOCK
				"open_all_stock":
					return active_app_id == APP_ID_STOCK and stock_list_tabs.current_tab == STOCK_LIST_TAB_ALL_STOCKS and guide_watchlist_all_stock_seen
				"select_stock":
					return active_app_id == APP_ID_STOCK and guide_watchlist_stock_selected and not selected_company_id.is_empty()
				"add_watchlist":
					return _guide_has_watchlist_stock()
		RunState.GUIDE_FLOW_SYSTEM.FLOW_TRADE:
			match step_id:
				"inspect_setup":
					return active_app_id == APP_ID_STOCK and not selected_company_id.is_empty() and _ftue_research_tab_viewed()
				"buy_one_lot":
					return _ftue_has_first_buy()
				"open_portfolio":
					return active_app_id == APP_ID_STOCK and active_section_id == "portfolio"
				"close_stockbot":
					return not _is_desktop_app_window_open(APP_ID_STOCK)
				"advance_day":
					return daily_recap_dialog != null and daily_recap_dialog.visible
				"read_recap":
					return RunState.day_index > 1 and (daily_recap_dialog == null or not daily_recap_dialog.visible)
		RunState.GUIDE_FLOW_SYSTEM.FLOW_RESEARCH:
			match step_id:
				"open_research_app":
					return active_app_id == APP_ID_NEWS or active_app_id == APP_ID_SOCIAL
				"inspect_context":
					return guide_research_interaction_seen
		RunState.GUIDE_FLOW_SYSTEM.FLOW_FUNDAMENTAL:
			match step_id:
				"open_key_stats":
					return active_app_id == APP_ID_STOCK and guide_fundamental_key_stats_seen
				"open_financials":
					return active_app_id == APP_ID_STOCK and guide_fundamental_key_stats_seen and _current_work_tab_title() == "Financials"
		RunState.GUIDE_FLOW_SYSTEM.FLOW_TECHNICAL:
			match step_id:
				"use_chart_tool":
					return active_app_id == APP_ID_STOCK and _current_work_tab_title() == "Chart" and guide_technical_tool_action_seen
		RunState.GUIDE_FLOW_SYSTEM.FLOW_THESIS:
			match step_id:
				"capture_evidence":
					return _guide_research_tray_count() > 0
				"open_thesis":
					return active_app_id == APP_ID_THESIS
				"create_thesis":
					return guide_thesis_create_action_seen
				"save_thesis":
					return _guide_any_open_thesis()
				"add_evidence":
					return _guide_any_thesis_evidence_count() >= 1
				"generate_or_defer":
					return _guide_any_thesis_evidence_count() >= 1
		RunState.GUIDE_FLOW_SYSTEM.FLOW_LIFE_FINANCE:
			match step_id:
				"open_life":
					return active_app_id == APP_ID_LIFE and guide_life_plan_reviewed
				"open_finance":
					return guide_life_finance_tab_seen and _guide_life_finance_tab_open()
		RunState.GUIDE_FLOW_SYSTEM.FLOW_CORPORATE_EVENT:
			match step_id:
				"schedule_event":
					return not str(GameManager.get_guide_snapshot().get("seeded_meeting_id", "")).is_empty()
				"attend_rupslb":
					return (
						_guide_meeting_is_concluded(snapshot) or
						_guide_meeting_has_passed(snapshot) or
						(
							rupslb_meeting_overlay != null and
							rupslb_meeting_overlay.visible and
							current_corporate_meeting_id == str(snapshot.get("seeded_meeting_id", ""))
						)
					)
				"approach_lead":
					return _guide_has_approached_lead(snapshot) or _guide_meeting_is_concluded(snapshot) or _guide_meeting_has_passed(snapshot)
		RunState.GUIDE_FLOW_SYSTEM.FLOW_ACADEMY:
			match step_id:
				"open_academy":
					return active_app_id == APP_ID_ACADEMY and guide_academy_lesson_chosen
				"read_lesson":
					return guide_academy_read_action_seen and _guide_current_academy_lesson_read()
	return false


func _guide_status_text(snapshot: Dictionary) -> String:
	var flow_id: String = str(snapshot.get("active_flow_id", ""))
	var step_id: String = str(snapshot.get("active_step_id", ""))
	var action_hint: String = str(snapshot.get("step", {}).get("action_hint", ""))
	var target_rect: Rect2 = _guide_target_rect_for_snapshot(snapshot, false)
	if target_rect.size.x <= 1.0 or target_rect.size.y <= 1.0:
		var required_app: String = _guide_required_app_for_step(flow_id, step_id)
		if not required_app.is_empty() and active_app_id != required_app:
			return "Open or focus %s to continue." % _guide_app_label(required_app)
		if not action_hint.is_empty():
			return "Next action: %s." % action_hint
	if not action_hint.is_empty():
		return "Next action: %s." % action_hint
	return ""


func _ftue_step_copy(step_id: String) -> Dictionary:
	match step_id:
		"welcome_desktop":
			return {
				"title": "Start With STOCKBOT",
				"objective": "Open STOCKBOT from the desktop.",
				"body": "This is where you pick a company, read its setup, and place the first small trade."
			}
		"pick_stock":
			return {
				"title": "Pick One Company",
				"objective": "Choose or confirm one stock to study.",
				"body": "Start with one name. The first loop is about learning how a setup behaves after the market closes."
			}
		"inspect_setup":
			return {
				"title": "Inspect Before Buying",
				"objective": "Open Key Stats, Financials, Broker, Corp. Action, or Profile.",
				"body": "Check at least one research view before using cash. Price alone is not a thesis."
			}
		"buy_one_lot":
			return {
				"title": "Make A Tiny First Trade",
				"objective": "Buy one small starter position.",
				"body": "Keep the first order light. One lot is enough to make the next day meaningful without overcommitting."
			}
		"advance_day":
			return {
				"title": "Let The Market Close",
				"objective": "Press Advance Day.",
				"body": "Advancing the day prints new market movement, news, portfolio changes, and the daily recap."
			}
		"read_recap":
			return {
				"title": "Read The Recap",
				"objective": "Review the day, then continue.",
				"body": "The recap connects your position with the market move. Use it to decide what to inspect next."
			}
		"next_steps":
			return {
				"title": "Your Next Loop",
				"objective": "Choose the next tool when you are ready.",
				"body": "Portfolio audits fills, Thesis records your reason, Life tracks runway, Network grows through News, referrals, and RUPSLB room leads, and Academy explains concepts when you need them."
			}
	return {
		"title": "Guided Start",
		"objective": "Follow the highlighted control.",
		"body": ""
	}


func _ftue_target_rect_for_step(step_id: String) -> Rect2:
	var target: Control = null
	match step_id:
		"welcome_desktop":
			target = stock_app_button
		"pick_stock":
			if active_app_id == APP_ID_STOCK:
				target = company_list
			else:
				target = stock_app_button
		"inspect_setup":
			target = work_tabs
		"buy_one_lot":
			target = submit_order_button if submit_order_button != null and submit_order_button.is_visible_in_tree() else buy_button
		"advance_day":
			target = desktop_advance_day_button
		"read_recap":
			target = daily_recap_continue_button if daily_recap_continue_button != null else daily_recap_dialog
	if target == null or not target.is_visible_in_tree():
		return Rect2()
	return target.get_global_rect().grow(FTUE_TARGET_PADDING)


func _guide_target_rect_for_snapshot(snapshot: Dictionary, allow_focus: bool = true) -> Rect2:
	var flow_id: String = str(snapshot.get("active_flow_id", ""))
	var step_id: String = str(snapshot.get("active_step_id", ""))
	guide_target_name = ""
	if allow_focus:
		_guide_focus_required_surface(flow_id, step_id)
	var target: Control = _guide_target_for_step(flow_id, step_id)
	if target == null or not target.is_visible_in_tree():
		return Rect2()
	if target is BaseButton and (target as BaseButton).disabled:
		return Rect2()
	var rect: Rect2 = target.get_global_rect().grow(GUIDE_TARGET_PADDING)
	var viewport_rect: Rect2 = get_viewport_rect()
	if not viewport_rect.intersects(rect):
		return Rect2()
	guide_target_name = str(target.name)
	return rect


func _guide_focus_required_surface(flow_id: String, step_id: String) -> void:
	if guide_focus_in_progress:
		return
	var required_app: String = _guide_required_app_for_step(flow_id, step_id)
	if required_app.is_empty() or required_app == active_app_id:
		return
	if _is_guide_modal_blocking_focus():
		return
	if _is_desktop_app_window_open(required_app):
		guide_focus_in_progress = true
		_focus_desktop_app_window(required_app)
		guide_focus_in_progress = false


func _is_guide_modal_blocking_focus() -> bool:
	return (
		(daily_recap_dialog != null and daily_recap_dialog.visible) or
		(rupslb_meeting_overlay != null and rupslb_meeting_overlay.visible) or
		(corporate_meeting_overlay != null and corporate_meeting_overlay.visible) or
		(settings_dialog != null and settings_dialog.visible) or
		(guide_hub_overlay != null and guide_hub_overlay.visible)
	)


func _guide_required_app_for_step(flow_id: String, step_id: String) -> String:
	match flow_id:
		RunState.GUIDE_FLOW_SYSTEM.FLOW_WATCHLIST:
			if step_id in ["open_all_stock", "select_stock", "add_watchlist"]:
				return APP_ID_STOCK
		RunState.GUIDE_FLOW_SYSTEM.FLOW_TRADE:
			if step_id in ["inspect_setup", "buy_one_lot", "open_portfolio", "close_stockbot"]:
				return APP_ID_STOCK
		RunState.GUIDE_FLOW_SYSTEM.FLOW_RESEARCH:
			if step_id == "inspect_context":
				return active_app_id if active_app_id in [APP_ID_NEWS, APP_ID_SOCIAL] else APP_ID_NEWS
		RunState.GUIDE_FLOW_SYSTEM.FLOW_FUNDAMENTAL, RunState.GUIDE_FLOW_SYSTEM.FLOW_TECHNICAL:
			return APP_ID_STOCK
		RunState.GUIDE_FLOW_SYSTEM.FLOW_THESIS:
			if step_id == "capture_evidence":
				return APP_ID_STOCK
			return APP_ID_THESIS
		RunState.GUIDE_FLOW_SYSTEM.FLOW_LIFE_FINANCE:
			return APP_ID_LIFE
		RunState.GUIDE_FLOW_SYSTEM.FLOW_ACADEMY:
			return APP_ID_ACADEMY if GameManager.is_academy_available() else ""
	return ""


func _guide_target_for_step(flow_id: String, step_id: String) -> Control:
	match flow_id:
		RunState.GUIDE_FLOW_SYSTEM.FLOW_WATCHLIST:
			match step_id:
				"open_stockbot":
					return stock_app_button if active_app_id == APP_ID_DESKTOP else null
				"open_all_stock":
					if active_app_id != APP_ID_STOCK:
						return stock_app_button
					if active_section_id != "markets":
						return markets_button
					return stock_list_tabs
				"select_stock":
					if active_app_id != APP_ID_STOCK:
						return stock_app_button
					if active_section_id != "markets":
						return markets_button
					if stock_list_tabs.current_tab == STOCK_LIST_TAB_ALL_STOCKS:
						return all_stocks_rows
					return stock_list_tabs
				"add_watchlist":
					if active_app_id != APP_ID_STOCK:
						return stock_app_button
					if active_section_id != "markets":
						return markets_button
					return _guide_all_stock_watch_column_target() if stock_list_tabs.current_tab == STOCK_LIST_TAB_ALL_STOCKS else stock_list_tabs
		RunState.GUIDE_FLOW_SYSTEM.FLOW_TRADE:
			match step_id:
				"inspect_setup":
					return work_tabs if active_app_id == APP_ID_STOCK else stock_app_button
				"buy_one_lot":
					if active_app_id != APP_ID_STOCK:
						return stock_app_button
					return submit_order_button if submit_order_button != null and submit_order_button.is_visible_in_tree() else buy_button
				"open_portfolio":
					return portfolio_button if active_app_id == APP_ID_STOCK else stock_app_button
				"close_stockbot":
					return _guide_desktop_window_close_button(APP_ID_STOCK) if active_app_id == APP_ID_STOCK else stock_app_button
				"advance_day":
					return desktop_advance_day_button
				"read_recap":
					return daily_recap_continue_button if daily_recap_continue_button != null else daily_recap_dialog
		RunState.GUIDE_FLOW_SYSTEM.FLOW_RESEARCH:
			match step_id:
				"open_research_app":
					if active_app_id == APP_ID_DESKTOP:
						return news_app_button if news_app_button != null else social_app_button
					return news_window if active_app_id == APP_ID_NEWS else social_window
				"inspect_context":
					return news_window if active_app_id == APP_ID_NEWS else social_window
		RunState.GUIDE_FLOW_SYSTEM.FLOW_FUNDAMENTAL:
			if active_app_id != APP_ID_STOCK:
				return stock_app_button
			if active_section_id != "markets":
				return markets_button
			return work_tabs
		RunState.GUIDE_FLOW_SYSTEM.FLOW_TECHNICAL:
			if active_app_id != APP_ID_STOCK:
				return stock_app_button
			if active_section_id != "markets":
				return markets_button
			if _current_work_tab_title() != "Chart":
				return work_tabs
			if step_id == "use_chart_tool":
				var chart_controls: Control = trade_workspace_widget.find_child("ChartRangeRow", true, false) as Control
				if chart_controls != null:
					return chart_controls
				var pattern_button: Control = trade_workspace_widget.find_child("PatternToolButton", true, false) as Control
				return pattern_button if pattern_button != null else work_tabs
			return work_tabs
		RunState.GUIDE_FLOW_SYSTEM.FLOW_THESIS:
			if step_id == "capture_evidence":
				if active_app_id != APP_ID_STOCK:
					return stock_app_button
				if active_section_id != "markets":
					return markets_button
				if _current_work_tab_title() != "Key Stats":
					return work_tabs
				return work_tabs
			if active_app_id != APP_ID_THESIS:
				return thesis_app_button
			if step_id == "open_thesis":
				return thesis_window
			if step_id == "create_thesis":
				return thesis_window.find_child("ThesisCreateButton", true, false) as Control
			if step_id == "save_thesis":
				var save_button: Control = thesis_window.find_child("ThesisUpdateButton", true, false) as Control
				return save_button if save_button != null and save_button.is_visible_in_tree() else thesis_window.find_child("ThesisCreateButton", true, false) as Control
			if step_id == "add_evidence":
				var attached_scroll: Control = thesis_window.find_child("ThesisAttachedEvidenceScroll", true, false) as Control
				if attached_scroll != null and attached_scroll.is_visible_in_tree():
					return attached_scroll
				return thesis_window.find_child("ThesisEvidenceCardGrid", true, false) as Control
			if step_id == "generate_or_defer":
				return thesis_window.find_child("ThesisGenerateReportButton", true, false) as Control
			return thesis_window
		RunState.GUIDE_FLOW_SYSTEM.FLOW_LIFE_FINANCE:
			if active_app_id != APP_ID_LIFE:
				return life_app_button
			if step_id == "open_life":
				var update_button: Control = life_window.find_child("LifeBasicsSlider", true, false) as Control
				if update_button == null:
					update_button = life_window.find_child("LifeUpdatePlanButton", true, false) as Control
				var runway_label: Control = life_window.find_child("LifeRunwayLabel", true, false) as Control
				return update_button if update_button != null else runway_label
			if step_id == "open_finance":
				return life_window.find_child("LifeTabs", true, false) as Control
			return life_window
		RunState.GUIDE_FLOW_SYSTEM.FLOW_CORPORATE_EVENT:
			match step_id:
				"schedule_event":
					return desktop_advance_day_button if active_app_id == APP_ID_DESKTOP else null
				"attend_rupslb":
					if rupslb_meeting_overlay != null and rupslb_meeting_overlay.visible:
						return rupslb_meeting_overlay
					if active_app_id == APP_ID_STOCK:
						return dashboard_button
					return stock_app_button if active_app_id == APP_ID_DESKTOP else null
				"approach_lead":
					return rupslb_meeting_overlay
		RunState.GUIDE_FLOW_SYSTEM.FLOW_ACADEMY:
			if not GameManager.is_academy_available():
				return null
			if active_app_id != APP_ID_ACADEMY:
				return academy_app_button
			if step_id == "open_academy":
				return academy_section_list if academy_section_list != null else academy_window
			if step_id == "read_lesson":
				return academy_mark_read_button
			return academy_window
	return null


func _guide_thesis_subject_target() -> Control:
	if thesis_window == null:
		return null
	var company_option: Control = thesis_window.find_child("ThesisCompanyOption", true, false) as Control
	if _guide_target_inside_named_parent(company_option, "ThesisBuilderPanel"):
		return company_option
	var create_button: Control = thesis_window.find_child("ThesisCreateButton", true, false) as Control
	if create_button != null and create_button.is_visible_in_tree():
		return create_button
	var builder_panel: Control = thesis_window.find_child("ThesisBuilderPanel", true, false) as Control
	return builder_panel if builder_panel != null else thesis_window


func _guide_target_inside_named_parent(target: Control, parent_name: String) -> bool:
	if target == null or not target.is_visible_in_tree():
		return false
	var parent_control: Control = null
	if thesis_window != null:
		parent_control = thesis_window.find_child(parent_name, true, false) as Control
	if parent_control == null or not parent_control.is_visible_in_tree():
		return true
	var target_rect: Rect2 = target.get_global_rect()
	var parent_rect: Rect2 = parent_control.get_global_rect().grow(8.0)
	return target_rect.size.x > 1.0 and target_rect.size.y > 1.0 and parent_rect.intersects(target_rect)


func _guide_all_stock_watch_column_target() -> Control:
	if all_stocks_rows == null:
		return stock_list_tabs
	var scroll_parent: Control = all_stocks_rows.get_parent() as Control
	return scroll_parent if scroll_parent != null else all_stocks_rows


func _guide_desktop_window_close_button(app_id: String) -> Control:
	var meta: Dictionary = desktop_app_windows.get(app_id, {})
	if meta.is_empty():
		return null
	return meta.get("close_button", null) as Control


func _mark_guide_watchlist_all_stock_seen() -> void:
	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	if str(snapshot.get("active_flow_id", "")) != RunState.GUIDE_FLOW_SYSTEM.FLOW_WATCHLIST:
		return
	if stock_list_tabs == null or stock_list_tabs.current_tab != STOCK_LIST_TAB_ALL_STOCKS:
		return
	guide_watchlist_all_stock_seen = true
	_refresh_ftue_progress()


func _mark_guide_watchlist_stock_selected() -> void:
	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	if str(snapshot.get("active_flow_id", "")) != RunState.GUIDE_FLOW_SYSTEM.FLOW_WATCHLIST:
		return
	guide_watchlist_stock_selected = true
	_refresh_ftue_progress()


func _mark_guide_research_interaction() -> void:
	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	if str(snapshot.get("active_flow_id", "")) != RunState.GUIDE_FLOW_SYSTEM.FLOW_RESEARCH:
		return
	guide_research_interaction_seen = true
	_refresh_ftue_progress()


func _mark_guide_fundamental_tab_seen(tab_index: int) -> void:
	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	if str(snapshot.get("active_flow_id", "")) != RunState.GUIDE_FLOW_SYSTEM.FLOW_FUNDAMENTAL:
		return
	if work_tabs == null or tab_index < 0 or tab_index >= work_tabs.get_tab_count():
		return
	var tab_title: String = work_tabs.get_tab_title(tab_index)
	var step_id: String = str(snapshot.get("active_step_id", ""))
	if tab_title == "Key Stats":
		guide_fundamental_key_stats_seen = true
	elif tab_title == "Financials" and step_id == "open_key_stats":
		guide_fundamental_key_stats_seen = true
	elif tab_title == "Financials":
		guide_fundamental_financials_seen = true


func _mark_guide_thesis_subject_chosen() -> void:
	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	if str(snapshot.get("active_flow_id", "")) != RunState.GUIDE_FLOW_SYSTEM.FLOW_THESIS:
		return
	guide_thesis_subject_chosen = true
	_refresh_ftue_progress()


func _mark_guide_thesis_create_action() -> void:
	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	if str(snapshot.get("active_flow_id", "")) != RunState.GUIDE_FLOW_SYSTEM.FLOW_THESIS:
		return
	guide_thesis_create_action_seen = true
	_refresh_ftue_progress()


func _mark_guide_life_plan_reviewed() -> void:
	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	if str(snapshot.get("active_flow_id", "")) != RunState.GUIDE_FLOW_SYSTEM.FLOW_LIFE_FINANCE:
		return
	guide_life_plan_reviewed = true
	_refresh_ftue_progress()


func _mark_guide_academy_lesson_chosen() -> void:
	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	if str(snapshot.get("active_flow_id", "")) != RunState.GUIDE_FLOW_SYSTEM.FLOW_ACADEMY:
		return
	guide_academy_lesson_chosen = true
	_refresh_ftue_progress()


func _mark_guide_academy_read_action() -> void:
	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	if str(snapshot.get("active_flow_id", "")) != RunState.GUIDE_FLOW_SYSTEM.FLOW_ACADEMY:
		return
	guide_academy_read_action_seen = true
	_refresh_ftue_progress()


func _guide_app_label(app_id: String) -> String:
	match app_id:
		APP_ID_STOCK:
			return "STOCKBOT"
		APP_ID_NEWS:
			return "News"
		APP_ID_SOCIAL:
			return "Twooter"
		APP_ID_NETWORK:
			return "Network"
		APP_ID_ACADEMY:
			return "Academy"
		APP_ID_THESIS:
			return "Thesis Board"
		APP_ID_LIFE:
			return "Life"
	return "the right window"


func _ftue_prepare_stock_pick() -> void:
	if active_app_id != APP_ID_STOCK or stock_list_tabs == null or not selected_company_id.is_empty():
		return
	if stock_list_tabs.current_tab == STOCK_LIST_TAB_WATCHLIST and GameManager.get_watchlist_company_ids().is_empty() and not RunState.company_order.is_empty():
		stock_list_tabs.current_tab = STOCK_LIST_TAB_ALL_STOCKS
		_sync_selected_company_with_active_stock_list()
		_refresh_company_selection_state()
		_refresh_trade_workspace()


func _layout_ftue_highlight(target_rect: Rect2) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var has_target: bool = target_rect.size.x > 1.0 and target_rect.size.y > 1.0
	for dim_rect in [ftue_dim_top, ftue_dim_bottom, ftue_dim_left, ftue_dim_right]:
		if dim_rect != null:
			dim_rect.visible = has_target
	if ftue_highlight_frame != null:
		ftue_highlight_frame.visible = has_target
	if not has_target:
		return

	var clamped_rect := Rect2(
		Vector2(
			clamp(target_rect.position.x, 0.0, viewport_size.x),
			clamp(target_rect.position.y, 0.0, viewport_size.y)
		),
		Vector2(
			clamp(target_rect.size.x, 0.0, viewport_size.x),
			clamp(target_rect.size.y, 0.0, viewport_size.y)
		)
	)
	clamped_rect.size.x = min(clamped_rect.size.x, max(viewport_size.x - clamped_rect.position.x, 0.0))
	clamped_rect.size.y = min(clamped_rect.size.y, max(viewport_size.y - clamped_rect.position.y, 0.0))
	var target_end: Vector2 = clamped_rect.position + clamped_rect.size

	ftue_dim_top.position = Vector2.ZERO
	ftue_dim_top.size = Vector2(viewport_size.x, clamped_rect.position.y)
	ftue_dim_bottom.position = Vector2(0.0, target_end.y)
	ftue_dim_bottom.size = Vector2(viewport_size.x, max(viewport_size.y - target_end.y, 0.0))
	ftue_dim_left.position = Vector2(0.0, clamped_rect.position.y)
	ftue_dim_left.size = Vector2(clamped_rect.position.x, clamped_rect.size.y)
	ftue_dim_right.position = Vector2(target_end.x, clamped_rect.position.y)
	ftue_dim_right.size = Vector2(max(viewport_size.x - target_end.x, 0.0), clamped_rect.size.y)
	ftue_highlight_frame.position = clamped_rect.position
	ftue_highlight_frame.size = clamped_rect.size


func _position_ftue_card(target_rect: Rect2) -> void:
	if ftue_card == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var card_size: Vector2 = ftue_card.get_combined_minimum_size()
	card_size.x = max(card_size.x, FTUE_CARD_SIZE.x)
	card_size.y = max(card_size.y, 150.0)
	ftue_card.size = card_size
	var card_position := Vector2(viewport_size.x - card_size.x - FTUE_CARD_MARGIN, viewport_size.y - card_size.y - FTUE_CARD_MARGIN)
	if target_rect.size.x > 1.0 and target_rect.size.y > 1.0:
		var right_position := Vector2(target_rect.end.x + FTUE_CARD_MARGIN, target_rect.position.y)
		var left_position := Vector2(target_rect.position.x - card_size.x - FTUE_CARD_MARGIN, target_rect.position.y)
		var below_position := Vector2(target_rect.position.x, target_rect.end.y + FTUE_CARD_MARGIN)
		var above_position := Vector2(target_rect.position.x, target_rect.position.y - card_size.y - FTUE_CARD_MARGIN)
		if right_position.x + card_size.x <= viewport_size.x - FTUE_CARD_MARGIN:
			card_position = right_position
		elif left_position.x >= FTUE_CARD_MARGIN:
			card_position = left_position
		elif below_position.y + card_size.y <= viewport_size.y - FTUE_CARD_MARGIN:
			card_position = below_position
		elif above_position.y >= FTUE_CARD_MARGIN:
			card_position = above_position
	card_position.x = clamp(card_position.x, FTUE_CARD_MARGIN, max(viewport_size.x - card_size.x - FTUE_CARD_MARGIN, FTUE_CARD_MARGIN))
	card_position.y = clamp(card_position.y, FTUE_CARD_MARGIN, max(viewport_size.y - card_size.y - FTUE_CARD_MARGIN, FTUE_CARD_MARGIN))
	ftue_card.position = card_position


func _ftue_research_tab_viewed() -> bool:
	if work_tabs == null:
		return false
	var current_index: int = work_tabs.current_tab
	if current_index < 0 or current_index >= work_tabs.get_tab_count():
		return false
	var tab_title: String = work_tabs.get_tab_title(current_index)
	return tab_title in ["Key Stats", "Financials", "Broker", "Corp. Action", "Profile"]


func _ftue_has_first_buy() -> bool:
	var snapshot: Dictionary = GameManager.get_ftue_snapshot()
	var start_day_index: int = int(snapshot.get("start_day_index", 0))
	for trade_value in GameManager.get_trade_history():
		var trade: Dictionary = trade_value
		if str(trade.get("side", "")) == "buy" and int(trade.get("day_index", -1)) >= start_day_index:
			return true
	return false


func _guide_has_watchlist_stock() -> bool:
	var watchlist_ids: Array = GameManager.get_watchlist_company_ids()
	if watchlist_ids.is_empty():
		return false
	if selected_company_id.is_empty():
		return true
	return watchlist_ids.has(selected_company_id)


func _current_work_tab_title() -> String:
	if work_tabs == null:
		return ""
	var index: int = work_tabs.current_tab
	if index < 0 or index >= work_tabs.get_tab_count():
		return ""
	return work_tabs.get_tab_title(index)


func _guide_chart_tool_used() -> bool:
	if trade_workspace_widget == null:
		return false
	if trade_workspace_widget.has_method("get_selected_range_id") and str(trade_workspace_widget.call("get_selected_range_id")).to_lower() != "1m":
		return true
	var pattern_panel: Control = trade_workspace_widget.find_child("ChartPatternPanel", true, false) as Control
	return pattern_panel != null and pattern_panel.visible


func _guide_any_open_thesis() -> bool:
	for thesis_value in GameManager.get_thesis_board_snapshot().get("theses", []):
		if typeof(thesis_value) != TYPE_DICTIONARY:
			continue
		var thesis: Dictionary = thesis_value
		if str(thesis.get("status", "open")) != "closed":
			return true
	return false


func _guide_research_tray_count() -> int:
	return GameManager.get_research_tray_snapshot().get("rows", []).size()


func _guide_any_thesis_evidence_count() -> int:
	var max_count: int = 0
	for thesis_value in GameManager.get_thesis_board_snapshot().get("theses", []):
		if typeof(thesis_value) != TYPE_DICTIONARY:
			continue
		var thesis: Dictionary = thesis_value
		max_count = max(max_count, thesis.get("evidence", []).size())
	return max_count


func _guide_life_finance_tab_open() -> bool:
	if active_app_id != APP_ID_LIFE or life_window == null:
		return false
	var tabs: TabContainer = life_window.find_child("LifeTabs", true, false) as TabContainer
	return tabs != null and tabs.current_tab >= 0 and tabs.current_tab < tabs.get_tab_count() and tabs.get_tab_title(tabs.current_tab) == "Finance"


func _guide_current_academy_lesson_read() -> bool:
	_ensure_academy_controller()
	var progress: Dictionary = RunState.get_academy_progress()
	var read_sections: Dictionary = progress.get("read_sections", {})
	return read_sections.get(academy_controller.selected_academy_category_id, []).has(academy_controller.selected_academy_section_id)


func _guide_has_approached_lead(snapshot: Dictionary) -> bool:
	var meeting_id: String = str(snapshot.get("seeded_meeting_id", "")).strip_edges()
	if meeting_id.is_empty():
		return false
	var session_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(meeting_id)
	for lead_value in session_snapshot.get("meeting_leads", []):
		if typeof(lead_value) != TYPE_DICTIONARY:
			continue
		var lead: Dictionary = lead_value
		if bool(lead.get("approached", false)) and not str(lead.get("response_text", "")).is_empty():
			return true
	return false


func _guide_meeting_is_concluded(snapshot: Dictionary) -> bool:
	var meeting_id: String = str(snapshot.get("seeded_meeting_id", "")).strip_edges()
	if meeting_id.is_empty():
		return false
	var session_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(meeting_id)
	if session_snapshot.is_empty():
		return false
	var session: Dictionary = session_snapshot.get("session", {})
	if bool(session.get("closed", false)):
		return true
	if str(session_snapshot.get("current_stage_id", session.get("presentation_stage", ""))) == "result":
		return true
	return not session_snapshot.get("result_summary", {}).is_empty() or not session.get("resolved_result_summary", {}).is_empty()


func _guide_meeting_has_passed(snapshot: Dictionary) -> bool:
	var meeting: Dictionary = snapshot.get("seeded_meeting", {})
	if meeting.is_empty():
		return false
	var meeting_day_number: int = int(meeting.get("trading_day_number", 0))
	if meeting_day_number <= 0:
		return false
	return meeting_day_number < int(RunState.day_index) + 1


func _on_ftue_skip_pressed() -> void:
	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	if str(snapshot.get("active_step_id", "")) == "handoff":
		GameManager.complete_guide_flow(str(snapshot.get("active_flow_id", "")))
	else:
		GameManager.skip_guide_flow(str(snapshot.get("active_flow_id", "")))
	_hide_ftue_overlay()
	_refresh_ftue_progress()


func _on_guide_prompt_dismiss_pressed() -> void:
	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	var flow_id: String = str(snapshot.get("active_flow_id", ""))
	if not flow_id.is_empty():
		GameManager.dismiss_guide_prompt(flow_id)
	_hide_ftue_overlay()


func _smoke_rect_dict(rect: Rect2) -> Dictionary:
	return {
		"x": rect.position.x,
		"y": rect.position.y,
		"width": rect.size.x,
		"height": rect.size.y
	}


func get_guide_smoke_state() -> Dictionary:
	var snapshot: Dictionary = GameManager.get_guide_snapshot()
	var card_rect: Dictionary = {}
	var highlight_rect: Dictionary = {}
	if ftue_card != null and ftue_card.visible:
		card_rect = _smoke_rect_dict(ftue_card.get_global_rect())
	if ftue_overlay != null and ftue_overlay.visible and ftue_highlight_frame != null and ftue_highlight_frame.visible:
		highlight_rect = _smoke_rect_dict(ftue_highlight_frame.get_global_rect())
	var highlight_visible: bool = ftue_overlay != null and ftue_overlay.visible and ftue_highlight_frame != null and ftue_highlight_frame.visible
	var all_stocks_scroll: Control = all_stocks_rows.get_parent() as Control if all_stocks_rows != null else null
	return {
		"overlay_exists": ftue_overlay != null,
		"visible": ftue_overlay != null and ftue_overlay.visible and ftue_card != null and ftue_card.visible,
		"current_flow_id": str(snapshot.get("active_flow_id", "")),
		"current_step_id": str(snapshot.get("active_step_id", "")),
		"completed_flow_ids": snapshot.get("completed_flow_ids", []).duplicate(),
		"skipped_flow_ids": snapshot.get("skipped_flow_ids", []).duplicate(),
		"dismissed_prompt_flow_ids": snapshot.get("dismissed_prompt_flow_ids", []).duplicate(),
		"completed_step_ids": snapshot.get("completed_step_ids", {}).duplicate(true),
		"anchor_company_id": str(snapshot.get("anchor_company_id", "")),
		"seeded_meeting_id": str(snapshot.get("seeded_meeting_id", "")),
		"seeded_chain_id": str(snapshot.get("seeded_chain_id", "")),
		"title": ftue_title_label.text if ftue_title_label != null else "",
		"objective": ftue_objective_label.text if ftue_objective_label != null else "",
		"body": ftue_body_label.text if ftue_body_label != null else "",
		"status": ftue_status_label.text if ftue_status_label != null else "",
		"progress": ftue_progress_label.text if ftue_progress_label != null else "",
		"button_text": ftue_skip_button.text if ftue_skip_button != null else "",
		"highlight_visible": highlight_visible,
		"highlight_target_name": guide_target_name,
		"highlight_rect": highlight_rect,
		"card_rect": card_rect,
		"card_min_width": ftue_card.custom_minimum_size.x if ftue_card != null else 0.0,
		"hub_button_exists": ftue_hub_button != null,
		"hub_visible": guide_hub_overlay != null and guide_hub_overlay.visible,
		"taskbar_hub_exists": guide_hub_taskbar_button != null,
		"help_hub_exists": guide_hub_help_button != null,
		"dismiss_button_exists": ftue_dismiss_button != null,
		"overlay_mouse_filter": ftue_overlay.mouse_filter if ftue_overlay != null else -1,
		"card_mouse_filter": ftue_card.mouse_filter if ftue_card != null else -1,
		"card_parent_is_overlay": ftue_card != null and ftue_overlay != null and ftue_card.get_parent() == ftue_overlay,
		"active_app_id": active_app_id,
		"active_section_id": active_section_id,
		"stock_list_tab_index": stock_list_tabs.current_tab if stock_list_tabs != null else -1,
		"stock_list_tabs_visible": stock_list_tabs.is_visible_in_tree() if stock_list_tabs != null else false,
		"stock_list_tabs_rect": _smoke_rect_dict(stock_list_tabs.get_global_rect()) if stock_list_tabs != null else {},
		"all_stocks_rows_visible": all_stocks_rows.is_visible_in_tree() if all_stocks_rows != null else false,
		"all_stocks_rows_rect": _smoke_rect_dict(all_stocks_rows.get_global_rect()) if all_stocks_rows != null else {},
		"all_stocks_scroll_visible": all_stocks_scroll.is_visible_in_tree() if all_stocks_scroll != null else false,
		"all_stocks_scroll_rect": _smoke_rect_dict(all_stocks_scroll.get_global_rect()) if all_stocks_scroll != null else {}
	}


func get_ftue_smoke_state() -> Dictionary:
	var guide_state: Dictionary = get_guide_smoke_state()
	var legacy_snapshot: Dictionary = GameManager.get_ftue_snapshot()
	guide_state["current_step_id"] = str(legacy_snapshot.get("current_step_id", guide_state.get("current_step_id", "")))
	guide_state["current_flow_id"] = str(legacy_snapshot.get("current_flow_id", guide_state.get("current_flow_id", "")))
	guide_state["completed"] = bool(legacy_snapshot.get("completed", false))
	guide_state["skipped"] = bool(legacy_snapshot.get("skipped", false))
	return guide_state


func _show_first_hour_guide_if_needed() -> void:
	_refresh_ftue_progress()


func _ensure_first_hour_guide_ui() -> void:
	if first_hour_guide_panel != null:
		return

	first_hour_guide_highlight_layer = Control.new()
	first_hour_guide_highlight_layer.name = "FirstHourGuideHighlightLayer"
	first_hour_guide_highlight_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	first_hour_guide_highlight_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	first_hour_guide_highlight_layer.visible = false
	add_child(first_hour_guide_highlight_layer)

	first_hour_guide_highlight_frame = PanelContainer.new()
	first_hour_guide_highlight_frame.name = "FirstHourGuideHighlightFrame"
	first_hour_guide_highlight_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	first_hour_guide_highlight_layer.add_child(first_hour_guide_highlight_frame)

	first_hour_guide_panel = PanelContainer.new()
	first_hour_guide_panel.name = "FirstHourGuidePanel"
	first_hour_guide_panel.custom_minimum_size = FIRST_HOUR_GUIDE_CARD_SIZE
	first_hour_guide_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	first_hour_guide_panel.visible = false
	add_child(first_hour_guide_panel)

	var margin := MarginContainer.new()
	margin.name = "FirstHourGuideMargin"
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	first_hour_guide_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "FirstHourGuideVBox"
	vbox.add_theme_constant_override("separation", 7)
	margin.add_child(vbox)

	first_hour_guide_title_label = Label.new()
	first_hour_guide_title_label.name = "FirstHourGuideTitleLabel"
	first_hour_guide_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(first_hour_guide_title_label)

	first_hour_guide_objective_label = Label.new()
	first_hour_guide_objective_label.name = "FirstHourGuideObjectiveLabel"
	first_hour_guide_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(first_hour_guide_objective_label)

	first_hour_guide_body_label = Label.new()
	first_hour_guide_body_label.name = "FirstHourGuideBodyLabel"
	first_hour_guide_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(first_hour_guide_body_label)

	first_hour_guide_status_label = Label.new()
	first_hour_guide_status_label.name = "FirstHourGuideStatusLabel"
	first_hour_guide_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(first_hour_guide_status_label)

	var footer := HBoxContainer.new()
	footer.name = "FirstHourGuideFooter"
	footer.add_theme_constant_override("separation", 8)
	vbox.add_child(footer)

	first_hour_guide_progress_label = Label.new()
	first_hour_guide_progress_label.name = "FirstHourGuideProgressLabel"
	first_hour_guide_progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(first_hour_guide_progress_label)

	first_hour_guide_hide_button = Button.new()
	first_hour_guide_hide_button.name = "FirstHourGuideHideButton"
	first_hour_guide_hide_button.text = "Hide"
	first_hour_guide_hide_button.custom_minimum_size = Vector2(66, 30)
	first_hour_guide_hide_button.pressed.connect(_on_first_hour_guide_hide_pressed)
	footer.add_child(first_hour_guide_hide_button)

	first_hour_guide_skip_button = Button.new()
	first_hour_guide_skip_button.name = "FirstHourGuideSkipButton"
	first_hour_guide_skip_button.text = "Skip"
	first_hour_guide_skip_button.custom_minimum_size = Vector2(72, 30)
	first_hour_guide_skip_button.pressed.connect(_on_first_hour_guide_skip_pressed)
	footer.add_child(first_hour_guide_skip_button)

	_style_first_hour_guide_ui()


func _style_first_hour_guide_ui() -> void:
	if first_hour_guide_highlight_frame != null:
		var highlight_style := StyleBoxFlat.new()
		highlight_style.bg_color = Color(0.972549, 0.713726, 0.0627451, 0.07)
		highlight_style.border_color = COLOR_DESKTOP_GOLD
		highlight_style.set_border_width_all(2)
		highlight_style.set_corner_radius_all(6)
		first_hour_guide_highlight_frame.add_theme_stylebox_override("panel", highlight_style)
	if first_hour_guide_panel != null:
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0.968627, 0.937255, 0.827451, 0.98)
		panel_style.border_color = COLOR_DESKTOP_FRAME
		panel_style.set_border_width_all(2)
		panel_style.set_corner_radius_all(6)
		first_hour_guide_panel.add_theme_stylebox_override("panel", panel_style)
	if first_hour_guide_title_label != null:
		first_hour_guide_title_label.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
		first_hour_guide_title_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE + 2)
	if first_hour_guide_objective_label != null:
		first_hour_guide_objective_label.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)
		first_hour_guide_objective_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	if first_hour_guide_body_label != null:
		first_hour_guide_body_label.add_theme_color_override("font_color", Color(0.282353, 0.247059, 0.160784, 1))
		first_hour_guide_body_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	if first_hour_guide_status_label != null:
		first_hour_guide_status_label.add_theme_color_override("font_color", Color(0.454902, 0.337255, 0.141176, 1))
		first_hour_guide_status_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE - 1)
	if first_hour_guide_progress_label != null:
		first_hour_guide_progress_label.add_theme_color_override("font_color", Color(0.423529, 0.337255, 0.188235, 1))
		first_hour_guide_progress_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE - 1)
	if first_hour_guide_hide_button != null:
		_style_button(first_hour_guide_hide_button, Color(0.835294, 0.819608, 0.772549, 1), Color(0.658824, 0.631373, 0.552941, 1), COLOR_WINDOW_TEXT, 6)
	if first_hour_guide_skip_button != null:
		_style_button(first_hour_guide_skip_button, COLOR_DESKTOP_BROWN, COLOR_ACADEMY_BORDER, COLOR_DESKTOP_CREAM, 6)


func _hide_first_hour_guide_ui() -> void:
	if first_hour_guide_highlight_layer != null:
		first_hour_guide_highlight_layer.visible = false
	if first_hour_guide_highlight_frame != null:
		first_hour_guide_highlight_frame.visible = false
	if first_hour_guide_panel != null:
		first_hour_guide_panel.visible = false


func _refresh_first_hour_guide_progress() -> void:
	_refresh_ftue_progress()
	return
	if not GameManager.should_show_first_hour_guide():
		_hide_first_hour_guide_ui()
		return

	var snapshot: Dictionary = GameManager.get_first_hour_guide_snapshot()
	var current_step_id: String = str(snapshot.get("current_step_id", ""))
	var advanced: bool = false
	first_hour_guide_blocked_message = ""
	match current_step_id:
		"portfolio_check":
			advanced = active_section_id == "portfolio"
		"create_thesis":
			advanced = _first_hour_guide_has_anchor_thesis(snapshot)
		"add_watchlist":
			advanced = _first_hour_guide_has_watchlist(snapshot)
		"read_market_context":
			advanced = active_app_id == APP_ID_NEWS or active_app_id == APP_ID_NETWORK
		"seeded_rupslb":
			var hook_result: Dictionary = GameManager.ensure_first_hour_guide_hook()
			advanced = bool(hook_result.get("success", false))
			if not advanced:
				first_hour_guide_blocked_message = str(hook_result.get("message", "Buy or hold one stock to unlock the first event."))
		"attend_rupslb":
			advanced = (
				_first_hour_guide_meeting_is_concluded(snapshot) or
				_first_hour_guide_meeting_has_passed(snapshot) or
				(
					rupslb_meeting_overlay != null and
					rupslb_meeting_overlay.visible and
					current_corporate_meeting_id == str(snapshot.get("seeded_meeting_id", ""))
				)
			)
		"approach_lead":
			advanced = (
				_first_hour_guide_has_approached_lead(snapshot) or
				_first_hour_guide_meeting_is_concluded(snapshot) or
				_first_hour_guide_meeting_has_passed(snapshot)
			)

	if advanced and GameManager.advance_first_hour_guide_step(current_step_id):
		call_deferred("_refresh_first_hour_guide_progress")
		_refresh_first_hour_guide_panel()
		return

	_refresh_first_hour_guide_panel()


func _refresh_first_hour_guide_panel() -> void:
	_refresh_ftue_overlay()
	return
	if first_hour_guide_panel == null:
		return
	if not GameManager.should_show_first_hour_guide() or _first_hour_guide_should_pause_for_modal():
		_hide_first_hour_guide_ui()
		return

	var snapshot: Dictionary = GameManager.get_first_hour_guide_snapshot()
	var step_id: String = str(snapshot.get("current_step_id", ""))
	var copy: Dictionary = _first_hour_guide_step_copy(step_id, snapshot)
	first_hour_guide_title_label.text = str(copy.get("title", "Loop Guide"))
	first_hour_guide_objective_label.text = "Objective: %s" % str(copy.get("objective", "Keep the loop moving."))
	first_hour_guide_body_label.text = str(copy.get("body", ""))
	first_hour_guide_status_label.text = str(copy.get("status", ""))
	var step_index: int = max(int(snapshot.get("step_index", 0)), 0)
	var step_count: int = max(int(snapshot.get("step_count", 1)), 1)
	first_hour_guide_progress_label.text = "Loop %d / %d" % [step_index + 1, step_count]
	first_hour_guide_skip_button.text = "Done" if step_id == "handoff" else "Skip"
	first_hour_guide_hide_button.text = "Show" if first_hour_guide_collapsed else "Hide"
	first_hour_guide_objective_label.visible = not first_hour_guide_collapsed
	first_hour_guide_body_label.visible = not first_hour_guide_collapsed
	first_hour_guide_status_label.visible = not first_hour_guide_collapsed and not first_hour_guide_status_label.text.is_empty()

	var target_rect: Rect2 = _first_hour_guide_target_rect_for_step(step_id, snapshot)
	_layout_first_hour_guide_highlight(target_rect)
	_position_first_hour_guide_panel()
	first_hour_guide_panel.visible = true
	first_hour_guide_panel.move_to_front()


func _first_hour_guide_should_pause_for_modal() -> bool:
	if daily_recap_dialog != null and daily_recap_dialog.visible:
		return true
	if rupslb_meeting_overlay != null and rupslb_meeting_overlay.visible:
		return true
	if corporate_meeting_overlay != null and corporate_meeting_overlay.visible:
		return true
	if watchlist_picker_dialog != null and watchlist_picker_dialog.visible:
		return true
	if upgrade_purchase_dialog != null and upgrade_purchase_dialog.visible:
		return true
	if settings_dialog != null and settings_dialog.visible:
		return true
	return false


func _first_hour_guide_step_copy(step_id: String, snapshot: Dictionary) -> Dictionary:
	var ticker: String = str(snapshot.get("anchor_ticker", "")).strip_edges()
	var ticker_text: String = ticker if not ticker.is_empty() else "your first stock"
	match step_id:
		"portfolio_check":
			var portfolio_status: String = ""
			if active_app_id == APP_ID_DESKTOP:
				portfolio_status = "Open STOCKBOT first; Portfolio is inside the left sidebar."
			elif active_app_id == APP_ID_STOCK and active_section_id != "portfolio":
				portfolio_status = "Click Portfolio in the STOCKBOT sidebar."
			return {
				"title": "Loop Guide: Portfolio",
				"objective": "Open Portfolio after the first recap.",
				"body": "Check what changed after your starter trade. The loop works better when you review position, cash, and fills before hunting the next stock.",
				"status": portfolio_status
			}
		"create_thesis":
			var thesis_status: String = ""
			if active_app_id != APP_ID_THESIS:
				thesis_status = "Capture one useful fact first if the tray is empty, then open Thesis Board."
			else:
				thesis_status = "Press Create Thesis, pick the stock, stance, and timeframe, then save the draft. The generated thesis can wait."
			return {
				"title": "Loop Guide: Thesis",
				"objective": "Turn captured evidence into a simple thesis for %s." % ticker_text,
				"body": "The new thesis flow starts from Research Tray evidence. Capture a real stat, chart read, article, or flow row, then arrange it in Thesis Board.",
				"status": thesis_status
			}
		"add_watchlist":
			var watchlist_status: String = ""
			if active_app_id != APP_ID_STOCK:
				watchlist_status = "Open STOCKBOT to add a watchlist name."
			return {
				"title": "Loop Guide: Watchlist",
				"objective": "Keep one company on watchlist.",
				"body": "The watchlist gives you a daily shortlist. Add %s or another readable stock so tomorrow has a clear starting point." % ticker_text,
				"status": watchlist_status
			}
		"read_market_context":
			var context_status: String = ""
			if active_app_id != APP_ID_DESKTOP and active_app_id != APP_ID_NEWS and active_app_id != APP_ID_NETWORK:
				context_status = "Return to the desktop, then open News or Network."
			return {
				"title": "Loop Guide: Context",
				"objective": "Open News or Network.",
				"body": "Before the next decision, check whether the tape has a story behind it. News gives public context; Network gives relationship leads.",
				"status": context_status
			}
		"seeded_rupslb":
			return {
				"title": "Loop Guide: First Event",
				"objective": "Hold one stock while the market prepares an event.",
				"body": "A low-stakes stock-split RUPSLB will be scheduled for a held stock. It teaches meeting flow without dilution pressure.",
				"status": first_hour_guide_blocked_message
			}
		"attend_rupslb":
			var meeting: Dictionary = snapshot.get("seeded_meeting", {})
			var date_text: String = GameManager.format_trade_date(meeting.get("trade_date", {})) if not meeting.is_empty() else "the next trading day"
			var attend_status: String = "Advance to %s first." % date_text
			if _first_hour_seeded_meeting_is_today(snapshot):
				attend_status = "Open STOCKBOT Dashboard, then open the guided meeting."
			return {
				"title": "Loop Guide: Attend",
				"objective": "Open the guided RUPSLB session.",
				"body": "The seeded meeting is due %s. If it is not visible today, advance the day, then open the meeting from Dashboard, News, or Network." % date_text,
				"status": attend_status
			}
		"approach_lead":
			return {
				"title": "Loop Guide: Room Lead",
				"objective": "Click one attendee and approach an available lead.",
				"body": "RUPSLB rooms now contain discoverable contacts. Pick one approachable attendee, read the micro-dialogue, and spend the meet AP when it looks useful."
			}
		"handoff":
			return {
				"title": "Loop Guide Complete",
				"objective": "Choose your next longer-term goal.",
				"body": "Useful goals: build a 3-stock watchlist, capture stronger thesis evidence, generate a thesis, read one Academy lesson, attend another RUPSLB, or grow portfolio value."
			}
	return {
		"title": "Loop Guide",
		"objective": "Keep the loop moving.",
		"body": ""
	}


func _first_hour_guide_daily_recap_hint() -> String:
	if not GameManager.should_show_first_hour_guide():
		return ""
	var snapshot: Dictionary = GameManager.get_first_hour_guide_snapshot()
	var copy: Dictionary = _first_hour_guide_step_copy(str(snapshot.get("current_step_id", "")), snapshot)
	return str(copy.get("objective", "")).strip_edges()


func _first_hour_guide_target_rect_for_step(step_id: String, snapshot: Dictionary) -> Rect2:
	var target: Control = null
	var use_parent_tile: bool = false
	first_hour_guide_target_name = ""
	match step_id:
		"portfolio_check":
			if active_app_id == APP_ID_STOCK and _is_desktop_app_window_open(APP_ID_STOCK):
				target = portfolio_button
			elif active_app_id == APP_ID_DESKTOP:
				target = stock_app_button
				use_parent_tile = true
		"create_thesis":
			if active_app_id == APP_ID_THESIS and _is_desktop_app_window_open(APP_ID_THESIS):
				if thesis_window != null:
					target = thesis_window.find_child("ThesisCreateButton", true, false) as Control
			elif active_app_id == APP_ID_DESKTOP:
				target = thesis_app_button
				use_parent_tile = true
		"add_watchlist":
			if active_app_id == APP_ID_STOCK and _is_desktop_app_window_open(APP_ID_STOCK):
				target = add_watchlist_button
			elif active_app_id == APP_ID_DESKTOP:
				target = stock_app_button
				use_parent_tile = true
		"read_market_context":
			if active_app_id == APP_ID_DESKTOP:
				target = news_app_button if news_app_button != null else network_app_button
				use_parent_tile = true
		"attend_rupslb":
			if not _first_hour_seeded_meeting_is_today(snapshot):
				target = desktop_advance_day_button
			elif active_app_id == APP_ID_STOCK and _is_desktop_app_window_open(APP_ID_STOCK):
				target = dashboard_button
			elif active_app_id == APP_ID_DESKTOP:
				target = stock_app_button
				use_parent_tile = true
	return _first_hour_guide_target_rect_for_control(target, use_parent_tile)


func _first_hour_guide_target_rect_for_control(target: Control, use_parent_tile: bool = false) -> Rect2:
	first_hour_guide_target_name = ""
	if target == null or not target.is_visible_in_tree():
		return Rect2()
	if target is BaseButton and (target as BaseButton).disabled:
		return Rect2()
	var rect_target: Control = target
	if use_parent_tile and target.get_parent() is Control:
		rect_target = target.get_parent() as Control
	first_hour_guide_target_name = str(target.name)
	return rect_target.get_global_rect().grow(FIRST_HOUR_GUIDE_TARGET_PADDING)


func _layout_first_hour_guide_highlight(target_rect: Rect2) -> void:
	if first_hour_guide_highlight_layer == null or first_hour_guide_highlight_frame == null:
		return
	var has_target: bool = target_rect.size.x > 1.0 and target_rect.size.y > 1.0
	first_hour_guide_highlight_layer.visible = has_target
	first_hour_guide_highlight_frame.visible = has_target
	if not has_target:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var clamped_rect := Rect2(
		Vector2(
			clamp(target_rect.position.x, 0.0, viewport_size.x),
			clamp(target_rect.position.y, 0.0, viewport_size.y)
		),
		target_rect.size
	)
	clamped_rect.size.x = min(clamped_rect.size.x, max(viewport_size.x - clamped_rect.position.x, 0.0))
	clamped_rect.size.y = min(clamped_rect.size.y, max(viewport_size.y - clamped_rect.position.y, 0.0))
	first_hour_guide_highlight_frame.position = clamped_rect.position
	first_hour_guide_highlight_frame.size = clamped_rect.size
	first_hour_guide_highlight_layer.move_to_front()


func _position_first_hour_guide_panel() -> void:
	if first_hour_guide_panel == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_size: Vector2 = first_hour_guide_panel.get_combined_minimum_size()
	panel_size.x = max(panel_size.x, FIRST_HOUR_GUIDE_CARD_SIZE.x)
	panel_size.y = max(panel_size.y, 64.0)
	first_hour_guide_panel.size = panel_size
	first_hour_guide_panel.position = Vector2(
		clamp(viewport_size.x - panel_size.x - FIRST_HOUR_GUIDE_CARD_MARGIN, FIRST_HOUR_GUIDE_CARD_MARGIN, max(viewport_size.x - panel_size.x - FIRST_HOUR_GUIDE_CARD_MARGIN, FIRST_HOUR_GUIDE_CARD_MARGIN)),
		clamp(viewport_size.y - panel_size.y - FIRST_HOUR_GUIDE_CARD_MARGIN, 84.0, max(viewport_size.y - panel_size.y - FIRST_HOUR_GUIDE_CARD_MARGIN, 84.0))
	)


func _first_hour_guide_has_anchor_thesis(snapshot: Dictionary) -> bool:
	var company_id: String = str(snapshot.get("anchor_company_id", "")).strip_edges()
	if company_id.is_empty():
		return false
	return not GameManager.get_open_theses_for_company(company_id).is_empty()


func _first_hour_guide_has_watchlist(snapshot: Dictionary) -> bool:
	var watchlist_ids: Array = GameManager.get_watchlist_company_ids()
	if watchlist_ids.is_empty():
		return false
	var anchor_company_id: String = str(snapshot.get("anchor_company_id", "")).strip_edges()
	return anchor_company_id.is_empty() or watchlist_ids.has(anchor_company_id) or watchlist_ids.size() > 0


func _first_hour_guide_has_approached_lead(snapshot: Dictionary) -> bool:
	var meeting_id: String = str(snapshot.get("seeded_meeting_id", "")).strip_edges()
	if meeting_id.is_empty():
		return false
	var session_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(meeting_id)
	for lead_value in session_snapshot.get("meeting_leads", []):
		if typeof(lead_value) != TYPE_DICTIONARY:
			continue
		var lead: Dictionary = lead_value
		if bool(lead.get("approached", false)) and not str(lead.get("response_text", "")).is_empty():
			return true
	return false


func _first_hour_guide_meeting_is_concluded(snapshot: Dictionary) -> bool:
	var meeting_id: String = str(snapshot.get("seeded_meeting_id", "")).strip_edges()
	if meeting_id.is_empty():
		return false
	var session_snapshot: Dictionary = GameManager.get_corporate_meeting_session_snapshot(meeting_id)
	if session_snapshot.is_empty():
		return false
	var session: Dictionary = session_snapshot.get("session", {})
	if bool(session.get("closed", false)):
		return true
	if str(session_snapshot.get("current_stage_id", session.get("presentation_stage", ""))) == "result":
		return true
	return not session_snapshot.get("result_summary", {}).is_empty() or not session.get("resolved_result_summary", {}).is_empty()


func _first_hour_guide_meeting_has_passed(snapshot: Dictionary) -> bool:
	var meeting: Dictionary = snapshot.get("seeded_meeting", {})
	if meeting.is_empty():
		return false
	var meeting_day_number: int = int(meeting.get("trading_day_number", 0))
	if meeting_day_number <= 0:
		return false
	return meeting_day_number < int(RunState.day_index) + 1


func _first_hour_seeded_meeting_is_today(snapshot: Dictionary) -> bool:
	var meeting: Dictionary = snapshot.get("seeded_meeting", {})
	if meeting.is_empty():
		return false
	return int(meeting.get("trading_day_number", -999)) == int(RunState.day_index) + 1


func _on_first_hour_guide_skip_pressed() -> void:
	var snapshot: Dictionary = GameManager.get_first_hour_guide_snapshot()
	if str(snapshot.get("current_step_id", "")) == "handoff":
		GameManager.mark_first_hour_guide_completed()
	else:
		GameManager.skip_first_hour_guide()
	_hide_first_hour_guide_ui()


func _on_first_hour_guide_hide_pressed() -> void:
	first_hour_guide_collapsed = not first_hour_guide_collapsed
	_refresh_first_hour_guide_panel()


func get_first_hour_guide_smoke_state() -> Dictionary:
	var snapshot: Dictionary = GameManager.get_first_hour_guide_snapshot()
	var guide_state: Dictionary = get_guide_smoke_state()
	var visible_as_corporate: bool = str(guide_state.get("current_flow_id", "")) == RunState.GUIDE_FLOW_SYSTEM.FLOW_CORPORATE_EVENT and bool(guide_state.get("visible", false))
	var completed_steps: Dictionary = guide_state.get("completed_step_ids", {})
	return {
		"panel_exists": ftue_card != null,
		"visible": visible_as_corporate,
		"current_step_id": str(snapshot.get("current_step_id", "")),
		"completed": bool(snapshot.get("completed", false)),
		"skipped": bool(snapshot.get("skipped", false)),
		"completed_step_ids": snapshot.get("completed_step_ids", completed_steps.get(RunState.GUIDE_FLOW_SYSTEM.FLOW_CORPORATE_EVENT, [])).duplicate(),
		"anchor_company_id": str(snapshot.get("anchor_company_id", "")),
		"seeded_meeting_id": str(snapshot.get("seeded_meeting_id", "")),
		"seeded_chain_id": str(snapshot.get("seeded_chain_id", "")),
		"title": str(guide_state.get("title", "")),
		"objective": str(guide_state.get("objective", "")),
		"status": str(guide_state.get("status", "")),
		"button_text": str(guide_state.get("button_text", "")),
		"highlight_visible": visible_as_corporate and bool(guide_state.get("highlight_visible", false)),
		"highlight_target_name": str(guide_state.get("highlight_target_name", "")) if visible_as_corporate else "",
		"highlight_rect": guide_state.get("highlight_rect", {}) if visible_as_corporate else {},
		"active_app_id": active_app_id,
		"active_section_id": active_section_id,
		"panel_mouse_filter": ftue_card.mouse_filter if ftue_card != null else -1
	}


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


func _ensure_upgrade_purchase_dialog() -> void:
	_ensure_upgrades_controller()
	upgrades_controller.ensure_purchase_dialog()


func _style_upgrade_purchase_dialog() -> void:
	_ensure_upgrades_controller()
	upgrades_controller.style_purchase_dialog()


func _ensure_bankruptcy_overlay() -> void:
	if bankruptcy_overlay != null:
		return
	bankruptcy_overlay = Control.new()
	bankruptcy_overlay.name = "BankruptcyOverlay"
	bankruptcy_overlay.visible = false
	bankruptcy_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	bankruptcy_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bankruptcy_overlay)

	var scrim := ColorRect.new()
	scrim.name = "BankruptcyScrim"
	scrim.color = Color(0.0, 0.0, 0.0, 0.42)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	bankruptcy_overlay.add_child(scrim)

	var center := CenterContainer.new()
	center.name = "BankruptcyCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bankruptcy_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "BankruptcyPanel"
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_DESKTOP_CREAM
	panel_style.border_color = Color(0.368627, 0.160784, 0.176471, 1)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.name = "BankruptcyMargin"
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "BankruptcyVBox"
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	var title := Label.new()
	title.name = "BankruptcyTitleLabel"
	title.text = "Bankruptcy"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.368627, 0.160784, 0.176471, 1))
	vbox.add_child(title)

	bankruptcy_body_label = Label.new()
	bankruptcy_body_label.name = "BankruptcyBodyLabel"
	bankruptcy_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bankruptcy_body_label.add_theme_font_size_override("font_size", 14)
	bankruptcy_body_label.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)
	vbox.add_child(bankruptcy_body_label)

	var button_row := HBoxContainer.new()
	button_row.name = "BankruptcyButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_END
	button_row.add_theme_constant_override("separation", 10)
	vbox.add_child(button_row)
	bankruptcy_menu_button = Button.new()
	bankruptcy_menu_button.name = "BankruptcyMenuButton"
	bankruptcy_menu_button.text = "Back to Menu"
	bankruptcy_menu_button.pressed.connect(_on_bankruptcy_menu_pressed)
	button_row.add_child(bankruptcy_menu_button)
	bankruptcy_restart_button = Button.new()
	bankruptcy_restart_button.name = "BankruptcyRestartButton"
	bankruptcy_restart_button.text = "Restart Run"
	bankruptcy_restart_button.pressed.connect(_on_bankruptcy_restart_pressed)
	button_row.add_child(bankruptcy_restart_button)
	_style_button(bankruptcy_menu_button, COLOR_DESKTOP_PANEL, COLOR_DESKTOP_FRAME, COLOR_DESKTOP_TEXT, 5)
	_style_button(bankruptcy_restart_button, Color(0.368627, 0.160784, 0.176471, 1), Color(0.709804, 0.34902, 0.372549, 1), COLOR_DESKTOP_CREAM, 5)


func _ensure_settings_dialog() -> void:
	if settings_dialog != null:
		return

	settings_dialog = Control.new()
	settings_dialog.name = "SettingsDialog"
	settings_dialog.visible = false
	settings_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(settings_dialog)

	var scrim := ColorRect.new()
	scrim.name = "SettingsOverlayScrim"
	scrim.color = Color(0.0, 0.0, 0.0, 0.34)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mouse_button: InputEventMouseButton = event
			if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
				_hide_settings_dialog()
	)
	settings_dialog.add_child(scrim)

	var center := CenterContainer.new()
	center.name = "SettingsOverlayCenter"
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_dialog.add_child(center)

	settings_panel = PanelContainer.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.custom_minimum_size = Vector2(640, 390)
	settings_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(settings_panel)

	var panel_vbox := VBoxContainer.new()
	panel_vbox.name = "SettingsPanelVBox"
	panel_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_vbox.add_theme_constant_override("separation", 0)
	settings_panel.add_child(panel_vbox)

	settings_title_bar = PanelContainer.new()
	settings_title_bar.name = "SettingsTitleBar"
	settings_title_bar.custom_minimum_size = Vector2(0, 40)
	settings_title_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_vbox.add_child(settings_title_bar)

	var title_margin := MarginContainer.new()
	title_margin.add_theme_constant_override("margin_left", 14)
	title_margin.add_theme_constant_override("margin_top", 4)
	title_margin.add_theme_constant_override("margin_right", 8)
	title_margin.add_theme_constant_override("margin_bottom", 4)
	settings_title_bar.add_child(title_margin)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_margin.add_child(title_row)

	settings_title_label = Label.new()
	settings_title_label.name = "SettingsTitleLabel"
	settings_title_label.text = "Settings"
	settings_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	settings_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(settings_title_label)

	settings_build_label = Label.new()
	settings_build_label.name = "SettingsBuildLabel"
	settings_build_label.text = BuildInfo.get_short_display_string()
	settings_build_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	settings_build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	settings_build_label.custom_minimum_size = Vector2(148, 0)
	title_row.add_child(settings_build_label)

	settings_close_button = Button.new()
	settings_close_button.name = "SettingsCloseButton"
	settings_close_button.text = "X"
	settings_close_button.custom_minimum_size = Vector2(34, 28)
	settings_close_button.pressed.connect(_hide_settings_dialog)
	title_row.add_child(settings_close_button)

	var dialog_margin := MarginContainer.new()
	dialog_margin.name = "SettingsBodyMargin"
	dialog_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_margin.add_theme_constant_override("margin_left", 18)
	dialog_margin.add_theme_constant_override("margin_top", 14)
	dialog_margin.add_theme_constant_override("margin_right", 18)
	dialog_margin.add_theme_constant_override("margin_bottom", 16)
	panel_vbox.add_child(dialog_margin)

	var dialog_vbox := VBoxContainer.new()
	dialog_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_vbox.add_theme_constant_override("separation", 10)
	dialog_margin.add_child(dialog_vbox)

	settings_autosave_checkbox = CheckBox.new()
	settings_autosave_checkbox.name = "SettingsAutosaveCheckBox"
	settings_autosave_checkbox.text = "Auto save"
	settings_autosave_checkbox.toggled.connect(_on_settings_autosave_toggled)
	dialog_vbox.add_child(settings_autosave_checkbox)

	var summary_row := HBoxContainer.new()
	summary_row.name = "SettingsSummaryRow"
	summary_row.add_theme_constant_override("separation", 12)
	dialog_vbox.add_child(summary_row)

	settings_current_slot_label = Label.new()
	settings_current_slot_label.name = "SettingsCurrentSlotLabel"
	settings_current_slot_label.text = "Current slot: Slot 1"
	settings_current_slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_row.add_child(settings_current_slot_label)

	settings_last_saved_label = Label.new()
	settings_last_saved_label.name = "SettingsLastSavedLabel"
	settings_last_saved_label.text = "Last saved: Never"
	settings_last_saved_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	settings_last_saved_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_row.add_child(settings_last_saved_label)

	var hint_label := Label.new()
	hint_label.name = "SettingsHintLabel"
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.text = "Choose a slot, then save, load, or delete. Loading a slot replaces the current run immediately."
	dialog_vbox.add_child(hint_label)

	settings_save_slots_list = ItemList.new()
	settings_save_slots_list.name = "SettingsSaveSlotsList"
	settings_save_slots_list.custom_minimum_size = Vector2(0, 138)
	settings_save_slots_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_save_slots_list.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	settings_save_slots_list.item_selected.connect(_on_settings_slot_selected)
	settings_save_slots_list.item_activated.connect(_on_settings_slot_activated)
	dialog_vbox.add_child(settings_save_slots_list)

	settings_status_label = Label.new()
	settings_status_label.name = "SettingsStatusLabel"
	settings_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings_status_label.custom_minimum_size = Vector2(0, 34)
	settings_status_label.text = ""
	dialog_vbox.add_child(settings_status_label)

	var button_row := HBoxContainer.new()
	button_row.name = "SettingsButtonRow"
	button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_theme_constant_override("separation", 10)
	dialog_vbox.add_child(button_row)

	var button_spacer := Control.new()
	button_spacer.name = "SettingsButtonSpacer"
	button_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_child(button_spacer)

	settings_save_button = Button.new()
	settings_save_button.name = "SettingsSaveButton"
	settings_save_button.text = "Save"
	settings_save_button.custom_minimum_size = Vector2(94, 34)
	settings_save_button.pressed.connect(_on_settings_save_pressed)
	button_row.add_child(settings_save_button)

	settings_load_button = Button.new()
	settings_load_button.name = "SettingsLoadButton"
	settings_load_button.text = "Load"
	settings_load_button.custom_minimum_size = Vector2(94, 34)
	settings_load_button.pressed.connect(_on_settings_load_pressed)
	button_row.add_child(settings_load_button)

	settings_delete_button = Button.new()
	settings_delete_button.name = "SettingsDeleteButton"
	settings_delete_button.text = "Delete"
	settings_delete_button.custom_minimum_size = Vector2(94, 34)
	settings_delete_button.pressed.connect(_on_settings_delete_pressed)
	button_row.add_child(settings_delete_button)

	settings_exit_button = Button.new()
	settings_exit_button.name = "SettingsExitButton"
	settings_exit_button.text = "Exit to Menu"
	settings_exit_button.custom_minimum_size = Vector2(124, 34)
	settings_exit_button.pressed.connect(_on_settings_exit_pressed)
	button_row.add_child(settings_exit_button)

	_build_settings_confirmation_overlay()

	_style_settings_overlay()
	_refresh_build_number_labels()


func _build_settings_confirmation_overlay() -> void:
	settings_confirm_overlay = Control.new()
	settings_confirm_overlay.name = "SettingsConfirmOverlay"
	settings_confirm_overlay.visible = false
	settings_confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_confirm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_dialog.add_child(settings_confirm_overlay)

	var scrim := ColorRect.new()
	scrim.name = "SettingsConfirmScrim"
	scrim.color = Color(0.0, 0.0, 0.0, 0.36)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_confirm_overlay.add_child(scrim)

	var center := CenterContainer.new()
	center.name = "SettingsConfirmCenter"
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_confirm_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "SettingsConfirmPanel"
	panel.custom_minimum_size = Vector2(460, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	settings_confirm_title_label = Label.new()
	settings_confirm_title_label.name = "SettingsConfirmTitleLabel"
	settings_confirm_title_label.text = "Are You Sure?"
	vbox.add_child(settings_confirm_title_label)

	settings_confirm_body_label = Label.new()
	settings_confirm_body_label.name = "SettingsConfirmBodyLabel"
	settings_confirm_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings_confirm_body_label.custom_minimum_size = Vector2(424, 92)
	vbox.add_child(settings_confirm_body_label)

	var button_row := HBoxContainer.new()
	button_row.name = "SettingsConfirmButtonRow"
	button_row.add_theme_constant_override("separation", 10)
	vbox.add_child(button_row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_child(spacer)

	settings_confirm_cancel_button = Button.new()
	settings_confirm_cancel_button.name = "SettingsConfirmCancelButton"
	settings_confirm_cancel_button.text = "Cancel"
	settings_confirm_cancel_button.custom_minimum_size = Vector2(96, 34)
	settings_confirm_cancel_button.pressed.connect(_on_settings_confirm_cancel_pressed)
	button_row.add_child(settings_confirm_cancel_button)

	settings_confirm_confirm_button = Button.new()
	settings_confirm_confirm_button.name = "SettingsConfirmConfirmButton"
	settings_confirm_confirm_button.text = "Confirm"
	settings_confirm_confirm_button.custom_minimum_size = Vector2(96, 34)
	settings_confirm_confirm_button.pressed.connect(_on_settings_confirm_confirm_pressed)
	button_row.add_child(settings_confirm_confirm_button)


func _style_settings_overlay() -> void:
	if settings_panel != null:
		UiTheme.style_panel(settings_panel, "dialog")
	if settings_title_bar != null:
		var title_style := UiTheme.make_stylebox(UiTheme.color("desktop.brown"), UiTheme.color("desktop.brown"), 0, 6)
		title_style.corner_radius_top_left = 6
		title_style.corner_radius_top_right = 6
		settings_title_bar.add_theme_stylebox_override("panel", title_style)
	if settings_title_label != null:
		settings_title_label.add_theme_color_override("font_color", UiTheme.color("desktop.cream"))
		settings_title_label.add_theme_font_override("font", UiTheme.font("semibold"))
		settings_title_label.add_theme_font_size_override("font_size", UiTheme.font_size("section"))
	if settings_build_label != null:
		settings_build_label.add_theme_color_override("font_color", UiTheme.color("desktop.cream"))
		settings_build_label.add_theme_font_size_override("font_size", UiTheme.font_size("body"))
	if settings_close_button != null:
		UiTheme.style_button(settings_close_button, "desktop_danger")
	if settings_autosave_checkbox != null:
		UiTheme.style_checkbox(settings_autosave_checkbox, "desktop")
	if settings_current_slot_label != null:
		UiTheme.style_label(settings_current_slot_label, "desktop_title")
		settings_current_slot_label.add_theme_font_size_override("font_size", UiTheme.font_size("body"))
	if settings_last_saved_label != null:
		UiTheme.style_label(settings_last_saved_label, "desktop_title")
		settings_last_saved_label.add_theme_font_size_override("font_size", UiTheme.font_size("body"))
	var hint_label: Label = null
	if settings_dialog != null:
		hint_label = settings_dialog.find_child("SettingsHintLabel", true, false) as Label
	if hint_label != null:
		UiTheme.style_label(hint_label, "desktop_body")
	if settings_save_slots_list != null:
		UiTheme.style_item_list(settings_save_slots_list, "desktop")
	if settings_status_label != null:
		settings_status_label.add_theme_color_override("font_color", Color(0.423529, 0.337255, 0.188235, 1))
		settings_status_label.add_theme_font_size_override("font_size", UiTheme.font_size("caption"))
	if settings_save_button != null:
		_style_button(settings_save_button, COLOR_DESKTOP_BROWN, COLOR_DESKTOP_BROWN.darkened(0.12), COLOR_DESKTOP_CREAM, 5)
	if settings_load_button != null:
		_style_button(settings_load_button, COLOR_DESKTOP_PANEL, COLOR_DESKTOP_FRAME, COLOR_DESKTOP_TEXT, 5)
	if settings_delete_button != null:
		_style_button(settings_delete_button, Color(0.368627, 0.160784, 0.176471, 1), Color(0.709804, 0.34902, 0.372549, 1), COLOR_DESKTOP_CREAM, 5)
	if settings_exit_button != null:
		_style_button(settings_exit_button, Color(0.368627, 0.160784, 0.176471, 1), Color(0.709804, 0.34902, 0.372549, 1), COLOR_DESKTOP_CREAM, 5)
	if settings_confirm_overlay != null:
		var confirm_panel: PanelContainer = settings_confirm_overlay.find_child("SettingsConfirmPanel", true, false) as PanelContainer
		if confirm_panel != null:
			UiTheme.style_panel(confirm_panel, "dialog")
	if settings_confirm_title_label != null:
		UiTheme.style_label(settings_confirm_title_label, "desktop_title")
	if settings_confirm_body_label != null:
		UiTheme.style_label(settings_confirm_body_label, "desktop_body")
	if settings_confirm_cancel_button != null:
		_style_button(settings_confirm_cancel_button, COLOR_DESKTOP_PANEL, COLOR_DESKTOP_FRAME, COLOR_DESKTOP_TEXT, 5)
	if settings_confirm_confirm_button != null:
		_style_button(settings_confirm_confirm_button, COLOR_DESKTOP_BROWN, COLOR_DESKTOP_BROWN.darkened(0.12), COLOR_DESKTOP_CREAM, 5)


func _ensure_daily_recap_dialog() -> void:
	if daily_recap_dialog != null:
		return

	daily_recap_dialog = Control.new()
	daily_recap_dialog.name = "DailyRecapDialog"
	daily_recap_dialog.visible = false
	daily_recap_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	daily_recap_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(daily_recap_dialog)

	var scrim := ColorRect.new()
	scrim.name = "DailyRecapScrim"
	scrim.color = Color(0.0, 0.0, 0.0, UI_DAILY_RECAP_SCRIM_ALPHA)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	daily_recap_dialog.add_child(scrim)

	var center := CenterContainer.new()
	center.name = "DailyRecapCenter"
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	daily_recap_dialog.add_child(center)

	var frame := PanelContainer.new()
	frame.name = "DailyRecapFrame"
	frame.custom_minimum_size = Vector2(640, 430)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(frame)

	var frame_vbox := VBoxContainer.new()
	frame_vbox.name = "DailyRecapFrameVBox"
	frame_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame_vbox.add_theme_constant_override("separation", 0)
	frame.add_child(frame_vbox)

	var title_bar := PanelContainer.new()
	title_bar.name = "DailyRecapTitleBar"
	title_bar.custom_minimum_size = Vector2(0, DESKTOP_WINDOW_TITLE_BAR_HEIGHT)
	title_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame_vbox.add_child(title_bar)

	var title_margin := MarginContainer.new()
	title_margin.add_theme_constant_override("margin_left", 12)
	title_margin.add_theme_constant_override("margin_top", 4)
	title_margin.add_theme_constant_override("margin_right", 8)
	title_margin.add_theme_constant_override("margin_bottom", 4)
	title_bar.add_child(title_margin)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_margin.add_child(title_row)

	var title_label := Label.new()
	title_label.name = "DailyRecapTitleLabel"
	title_label.text = "Daily Recap"
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", COLOR_TEXT)
	title_row.add_child(title_label)

	var close_button := Button.new()
	close_button.name = "DailyRecapCloseButton"
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(32, 24)
	close_button.pressed.connect(_hide_daily_recap)
	title_row.add_child(close_button)

	var body_margin := MarginContainer.new()
	body_margin.name = "DailyRecapOuterMargin"
	body_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 16)
	body_margin.add_theme_constant_override("margin_top", 16)
	body_margin.add_theme_constant_override("margin_right", 16)
	body_margin.add_theme_constant_override("margin_bottom", 14)
	frame_vbox.add_child(body_margin)

	var body_vbox := VBoxContainer.new()
	body_vbox.name = "DailyRecapBodyVBox"
	body_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_vbox.add_theme_constant_override("separation", 14)
	body_margin.add_child(body_vbox)

	var content_panel := PanelContainer.new()
	content_panel.name = "DailyRecapContentPanel"
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_vbox.add_child(content_panel)

	var content_margin := MarginContainer.new()
	content_margin.name = "DailyRecapContentMargin"
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", 22)
	content_margin.add_theme_constant_override("margin_top", 18)
	content_margin.add_theme_constant_override("margin_right", 22)
	content_margin.add_theme_constant_override("margin_bottom", 18)
	content_panel.add_child(content_margin)

	daily_recap_body_label = Label.new()
	daily_recap_body_label.name = "DailyRecapBodyLabel"
	daily_recap_body_label.custom_minimum_size = Vector2(580, 330)
	daily_recap_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	daily_recap_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	daily_recap_body_label.text = ""
	daily_recap_body_label.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	daily_recap_body_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	daily_recap_body_label.add_theme_constant_override("line_spacing", 5)
	content_margin.add_child(daily_recap_body_label)

	var action_row := HBoxContainer.new()
	action_row.name = "DailyRecapActionRow"
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	body_vbox.add_child(action_row)

	daily_recap_continue_button = Button.new()
	daily_recap_continue_button.name = "DailyRecapContinueButton"
	daily_recap_continue_button.text = "Continue"
	daily_recap_continue_button.custom_minimum_size = Vector2(112, 38)
	daily_recap_continue_button.pressed.connect(_hide_daily_recap)
	action_row.add_child(daily_recap_continue_button)
	_style_daily_recap_dialog()


func _hide_daily_recap() -> void:
	var was_visible: bool = daily_recap_dialog != null and daily_recap_dialog.visible
	if daily_recap_dialog != null:
		_reset_daily_recap_animation_state()
		daily_recap_dialog.visible = false
	call_deferred("_run_post_daily_recap_work", was_visible)


func _style_daily_recap_dialog() -> void:
	if daily_recap_dialog == null:
		return
	var frame: PanelContainer = daily_recap_dialog.get_node_or_null("DailyRecapCenter/DailyRecapFrame") as PanelContainer
	if frame != null:
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = COLOR_DESKTOP_CREAM
		frame_style.border_color = Color(COLOR_ACADEMY_BROWN.r, COLOR_ACADEMY_BROWN.g, COLOR_ACADEMY_BROWN.b, 0)
		frame_style.set_border_width_all(0)
		frame_style.set_corner_radius_all(0)
		frame.add_theme_stylebox_override("panel", frame_style)
	var title_bar: PanelContainer = daily_recap_dialog.get_node_or_null("DailyRecapCenter/DailyRecapFrame/DailyRecapFrameVBox/DailyRecapTitleBar") as PanelContainer
	if title_bar != null:
		_style_window_title_bar(title_bar, COLOR_ACADEMY_BROWN)
	var title_label: Label = daily_recap_dialog.find_child("DailyRecapTitleLabel", true, false) as Label
	if title_label != null:
		title_label.add_theme_color_override("font_color", COLOR_TEXT)
		title_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	var close_button: Button = daily_recap_dialog.find_child("DailyRecapCloseButton", true, false) as Button
	if close_button != null:
		_style_button(close_button, Color(0.368627, 0.160784, 0.176471, 1), Color(0.709804, 0.34902, 0.372549, 1), COLOR_TEXT, 0)
	if daily_recap_continue_button != null:
		_style_button(daily_recap_continue_button, COLOR_ACADEMY_BROWN, COLOR_ACADEMY_BORDER, COLOR_TEXT, 0)
		daily_recap_continue_button.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	var content_panel: PanelContainer = daily_recap_dialog.find_child("DailyRecapContentPanel", true, false) as PanelContainer
	if content_panel != null:
		_style_daily_recap_content_panel(content_panel)


func _style_daily_recap_content_panel(panel: PanelContainer) -> void:
	if panel == null:
		return
	var content_style := StyleBoxFlat.new()
	content_style.bg_color = Color(0.992157, 0.964706, 0.870588, 1)
	content_style.border_color = Color(0.52549, 0.396078, 0.160784, 0.85)
	content_style.set_border_width_all(1)
	content_style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", content_style)


func _ensure_macro_event_dialog() -> void:
	if macro_event_dialog != null:
		return

	macro_event_dialog = Control.new()
	macro_event_dialog.name = "MacroEventDialog"
	macro_event_dialog.visible = false
	macro_event_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	macro_event_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(macro_event_dialog)

	var scrim := ColorRect.new()
	scrim.name = "MacroEventScrim"
	scrim.color = Color(0.0, 0.0, 0.0, UI_DAILY_RECAP_SCRIM_ALPHA)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.gui_input.connect(_on_macro_event_dialog_gui_input)
	macro_event_dialog.add_child(scrim)

	var center := CenterContainer.new()
	center.name = "MacroEventCenter"
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	macro_event_dialog.add_child(center)

	var frame := PanelContainer.new()
	frame.name = "MacroEventFrame"
	frame.custom_minimum_size = Vector2(540, 184)
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.gui_input.connect(_on_macro_event_dialog_gui_input)
	center.add_child(frame)

	var frame_vbox := VBoxContainer.new()
	frame_vbox.name = "MacroEventFrameVBox"
	frame_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame_vbox.add_theme_constant_override("separation", 0)
	frame.add_child(frame_vbox)

	var title_bar := PanelContainer.new()
	title_bar.name = "MacroEventTitleBar"
	title_bar.custom_minimum_size = Vector2(0, DESKTOP_WINDOW_TITLE_BAR_HEIGHT)
	title_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame_vbox.add_child(title_bar)

	var title_margin := MarginContainer.new()
	title_margin.add_theme_constant_override("margin_left", 12)
	title_margin.add_theme_constant_override("margin_top", 4)
	title_margin.add_theme_constant_override("margin_right", 8)
	title_margin.add_theme_constant_override("margin_bottom", 4)
	title_bar.add_child(title_margin)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_margin.add_child(title_row)

	var title_label := Label.new()
	title_label.name = "MacroEventTitleLabel"
	title_label.text = "Macro Events"
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", COLOR_TEXT)
	title_row.add_child(title_label)

	macro_event_close_button = Button.new()
	macro_event_close_button.name = "MacroEventCloseButton"
	macro_event_close_button.text = "X"
	macro_event_close_button.custom_minimum_size = Vector2(32, 24)
	macro_event_close_button.pressed.connect(_dismiss_current_macro_event_alert)
	title_row.add_child(macro_event_close_button)

	var body_margin := MarginContainer.new()
	body_margin.name = "MacroEventOuterMargin"
	body_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 16)
	body_margin.add_theme_constant_override("margin_top", 16)
	body_margin.add_theme_constant_override("margin_right", 16)
	body_margin.add_theme_constant_override("margin_bottom", 16)
	frame_vbox.add_child(body_margin)

	var content_panel := PanelContainer.new()
	content_panel.name = "MacroEventContentPanel"
	content_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_panel.gui_input.connect(_on_macro_event_dialog_gui_input)
	body_margin.add_child(content_panel)

	var content_margin := MarginContainer.new()
	content_margin.name = "MacroEventContentMargin"
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", 22)
	content_margin.add_theme_constant_override("margin_top", 20)
	content_margin.add_theme_constant_override("margin_right", 22)
	content_margin.add_theme_constant_override("margin_bottom", 20)
	content_panel.add_child(content_margin)

	macro_event_headline_label = Label.new()
	macro_event_headline_label.name = "MacroEventHeadlineLabel"
	macro_event_headline_label.custom_minimum_size = Vector2(460, 78)
	macro_event_headline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	macro_event_headline_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	macro_event_headline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	macro_event_headline_label.text = ""
	macro_event_headline_label.visible_characters = 0
	macro_event_headline_label.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	macro_event_headline_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE + 2)
	macro_event_headline_label.add_theme_constant_override("line_spacing", 5)
	content_margin.add_child(macro_event_headline_label)

	_style_macro_event_dialog()


func _style_macro_event_dialog() -> void:
	if macro_event_dialog == null:
		return
	var frame: PanelContainer = macro_event_dialog.get_node_or_null("MacroEventCenter/MacroEventFrame") as PanelContainer
	if frame != null:
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = COLOR_DESKTOP_CREAM
		frame_style.border_color = Color(COLOR_ACADEMY_BROWN.r, COLOR_ACADEMY_BROWN.g, COLOR_ACADEMY_BROWN.b, 0)
		frame_style.set_border_width_all(0)
		frame_style.set_corner_radius_all(0)
		frame.add_theme_stylebox_override("panel", frame_style)
	var title_bar: PanelContainer = macro_event_dialog.get_node_or_null("MacroEventCenter/MacroEventFrame/MacroEventFrameVBox/MacroEventTitleBar") as PanelContainer
	if title_bar != null:
		_style_window_title_bar(title_bar, COLOR_ACADEMY_BROWN)
	var title_label: Label = macro_event_dialog.find_child("MacroEventTitleLabel", true, false) as Label
	if title_label != null:
		title_label.add_theme_color_override("font_color", COLOR_TEXT)
		title_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	if macro_event_headline_label != null:
		macro_event_headline_label.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
		macro_event_headline_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE + 2)
	if macro_event_close_button != null:
		_style_button(macro_event_close_button, Color(0.368627, 0.160784, 0.176471, 1), Color(0.709804, 0.34902, 0.372549, 1), COLOR_TEXT, 0)
	var content_panel: PanelContainer = macro_event_dialog.find_child("MacroEventContentPanel", true, false) as PanelContainer
	if content_panel != null:
		_style_daily_recap_content_panel(content_panel)


func _ensure_dirty_tip_dialog() -> void:
	if dirty_tip_dialog != null:
		return

	dirty_tip_dialog = Control.new()
	dirty_tip_dialog.name = "DirtyTipDialog"
	dirty_tip_dialog.visible = false
	dirty_tip_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	dirty_tip_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dirty_tip_dialog)

	var scrim := ColorRect.new()
	scrim.name = "DirtyTipScrim"
	scrim.color = Color(0.0, 0.0, 0.0, 0.38)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	dirty_tip_dialog.add_child(scrim)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.name = "DirtyTipCenter"
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dirty_tip_dialog.add_child(center)

	var frame := PanelContainer.new()
	frame.name = "DirtyTipFrame"
	frame.custom_minimum_size = Vector2(560, 300)
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(frame)

	var frame_vbox := VBoxContainer.new()
	frame_vbox.name = "DirtyTipFrameVBox"
	frame_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame_vbox.add_theme_constant_override("separation", 0)
	frame.add_child(frame_vbox)

	var title_bar := PanelContainer.new()
	title_bar.name = "DirtyTipTitleBar"
	title_bar.custom_minimum_size = Vector2(0, DESKTOP_WINDOW_TITLE_BAR_HEIGHT)
	title_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame_vbox.add_child(title_bar)

	var title_margin := MarginContainer.new()
	title_margin.add_theme_constant_override("margin_left", 12)
	title_margin.add_theme_constant_override("margin_top", 4)
	title_margin.add_theme_constant_override("margin_right", 8)
	title_margin.add_theme_constant_override("margin_bottom", 4)
	title_bar.add_child(title_margin)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_margin.add_child(title_row)

	var title_label := Label.new()
	title_label.name = "DirtyTipTitleLabel"
	title_label.text = "Market Room"
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_label)

	dirty_tip_close_button = Button.new()
	dirty_tip_close_button.name = "DirtyTipCloseButton"
	dirty_tip_close_button.text = "X"
	dirty_tip_close_button.custom_minimum_size = Vector2(32, 24)
	dirty_tip_close_button.pressed.connect(_decline_current_dirty_tip_alert)
	title_row.add_child(dirty_tip_close_button)

	var body_margin := MarginContainer.new()
	body_margin.name = "DirtyTipOuterMargin"
	body_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 16)
	body_margin.add_theme_constant_override("margin_top", 16)
	body_margin.add_theme_constant_override("margin_right", 16)
	body_margin.add_theme_constant_override("margin_bottom", 14)
	frame_vbox.add_child(body_margin)

	var body_vbox := VBoxContainer.new()
	body_vbox.name = "DirtyTipBodyVBox"
	body_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_vbox.add_theme_constant_override("separation", 14)
	body_margin.add_child(body_vbox)

	var content_panel := PanelContainer.new()
	content_panel.name = "DirtyTipContentPanel"
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_vbox.add_child(content_panel)

	var content_margin := MarginContainer.new()
	content_margin.name = "DirtyTipContentMargin"
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", 22)
	content_margin.add_theme_constant_override("margin_top", 18)
	content_margin.add_theme_constant_override("margin_right", 22)
	content_margin.add_theme_constant_override("margin_bottom", 18)
	content_panel.add_child(content_margin)

	dirty_tip_body_label = Label.new()
	dirty_tip_body_label.name = "DirtyTipBodyLabel"
	dirty_tip_body_label.custom_minimum_size = Vector2(500, 140)
	dirty_tip_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dirty_tip_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	dirty_tip_body_label.text = ""
	dirty_tip_body_label.add_theme_constant_override("line_spacing", 5)
	content_margin.add_child(dirty_tip_body_label)

	var action_row := HBoxContainer.new()
	action_row.name = "DirtyTipActionRow"
	action_row.alignment = BoxContainer.ALIGNMENT_END
	action_row.add_theme_constant_override("separation", 8)
	body_vbox.add_child(action_row)

	dirty_tip_report_button = Button.new()
	dirty_tip_report_button.name = "DirtyTipReportButton"
	dirty_tip_report_button.text = "Report"
	dirty_tip_report_button.custom_minimum_size = Vector2(92, 36)
	dirty_tip_report_button.pressed.connect(_report_current_dirty_tip_alert)
	action_row.add_child(dirty_tip_report_button)

	dirty_tip_decline_button = Button.new()
	dirty_tip_decline_button.name = "DirtyTipDeclineButton"
	dirty_tip_decline_button.text = "Decline"
	dirty_tip_decline_button.custom_minimum_size = Vector2(92, 36)
	dirty_tip_decline_button.pressed.connect(_decline_current_dirty_tip_alert)
	action_row.add_child(dirty_tip_decline_button)

	dirty_tip_accept_button = Button.new()
	dirty_tip_accept_button.name = "DirtyTipAcceptButton"
	dirty_tip_accept_button.text = "Accept"
	dirty_tip_accept_button.custom_minimum_size = Vector2(92, 36)
	dirty_tip_accept_button.pressed.connect(_accept_current_dirty_tip_alert)
	action_row.add_child(dirty_tip_accept_button)

	_style_dirty_tip_dialog()


func _style_dirty_tip_dialog() -> void:
	if dirty_tip_dialog == null:
		return
	var frame: PanelContainer = dirty_tip_dialog.get_node_or_null("DirtyTipCenter/DirtyTipFrame") as PanelContainer
	if frame != null:
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = COLOR_DESKTOP_CREAM
		frame_style.border_color = Color(COLOR_ACADEMY_BORDER.r, COLOR_ACADEMY_BORDER.g, COLOR_ACADEMY_BORDER.b, 0.95)
		frame_style.set_border_width_all(2)
		frame_style.set_corner_radius_all(0)
		frame.add_theme_stylebox_override("panel", frame_style)
	var scrim: ColorRect = dirty_tip_dialog.find_child("DirtyTipScrim", true, false) as ColorRect
	if scrim != null:
		scrim.color = Color(0.0, 0.0, 0.0, 0.38)
	var title_bar: PanelContainer = dirty_tip_dialog.get_node_or_null("DirtyTipCenter/DirtyTipFrame/DirtyTipFrameVBox/DirtyTipTitleBar") as PanelContainer
	if title_bar != null:
		_style_window_title_bar(title_bar, COLOR_ACADEMY_BROWN)
	var title_label: Label = dirty_tip_dialog.find_child("DirtyTipTitleLabel", true, false) as Label
	if title_label != null:
		title_label.add_theme_color_override("font_color", COLOR_TEXT)
		title_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	if dirty_tip_body_label != null:
		dirty_tip_body_label.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
		dirty_tip_body_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	if dirty_tip_close_button != null:
		_style_button(dirty_tip_close_button, Color(0.368627, 0.160784, 0.176471, 1), Color(0.709804, 0.34902, 0.372549, 1), COLOR_TEXT, 0)
	if dirty_tip_report_button != null:
		_style_button(dirty_tip_report_button, COLOR_DESKTOP_PANEL, COLOR_DESKTOP_FRAME, COLOR_DESKTOP_TEXT, 0)
	if dirty_tip_decline_button != null:
		_style_button(dirty_tip_decline_button, COLOR_DESKTOP_PANEL, COLOR_DESKTOP_FRAME, COLOR_DESKTOP_TEXT, 0)
	if dirty_tip_accept_button != null:
		_style_button(dirty_tip_accept_button, COLOR_ACADEMY_BROWN, COLOR_ACADEMY_BORDER, COLOR_TEXT, 0)
	var content_panel: PanelContainer = dirty_tip_dialog.find_child("DirtyTipContentPanel", true, false) as PanelContainer
	if content_panel != null:
		_style_daily_recap_content_panel(content_panel)


func _ensure_dashboard_calendar_event_popup() -> void:
	if dashboard_calendar_event_popup != null:
		return

	dashboard_calendar_event_popup = Control.new()
	dashboard_calendar_event_popup.name = "DashboardCalendarEventPopup"
	dashboard_calendar_event_popup.visible = false
	dashboard_calendar_event_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	dashboard_calendar_event_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dashboard_calendar_event_popup)

	var scrim := ColorRect.new()
	scrim.name = "DashboardCalendarEventScrim"
	scrim.color = Color(0.0, 0.0, 0.0, 0.34)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mouse_button: InputEventMouseButton = event
			if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
				_hide_dashboard_calendar_event_popup()
	)
	dashboard_calendar_event_popup.add_child(scrim)

	var center := CenterContainer.new()
	center.name = "DashboardCalendarEventCenter"
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dashboard_calendar_event_popup.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "DashboardCalendarEventPanel"
	panel.custom_minimum_size = Vector2(440, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "DashboardCalendarEventVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	var title_bar := PanelContainer.new()
	title_bar.name = "DashboardCalendarEventTitleBar"
	title_bar.custom_minimum_size = Vector2(0, 38)
	title_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title_bar)

	var title_margin := MarginContainer.new()
	title_margin.add_theme_constant_override("margin_left", 12)
	title_margin.add_theme_constant_override("margin_top", 4)
	title_margin.add_theme_constant_override("margin_right", 8)
	title_margin.add_theme_constant_override("margin_bottom", 4)
	title_bar.add_child(title_margin)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_margin.add_child(title_row)

	dashboard_calendar_event_title_label = Label.new()
	dashboard_calendar_event_title_label.name = "DashboardCalendarEventTitleLabel"
	dashboard_calendar_event_title_label.text = "Calendar Events"
	dashboard_calendar_event_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dashboard_calendar_event_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(dashboard_calendar_event_title_label)

	dashboard_calendar_event_close_button = Button.new()
	dashboard_calendar_event_close_button.name = "DashboardCalendarEventCloseButton"
	dashboard_calendar_event_close_button.text = "X"
	dashboard_calendar_event_close_button.custom_minimum_size = Vector2(32, 24)
	dashboard_calendar_event_close_button.pressed.connect(_hide_dashboard_calendar_event_popup)
	title_row.add_child(dashboard_calendar_event_close_button)

	var body_margin := MarginContainer.new()
	body_margin.name = "DashboardCalendarEventBodyMargin"
	body_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 16)
	body_margin.add_theme_constant_override("margin_top", 14)
	body_margin.add_theme_constant_override("margin_right", 16)
	body_margin.add_theme_constant_override("margin_bottom", 16)
	vbox.add_child(body_margin)

	var body_vbox := VBoxContainer.new()
	body_vbox.name = "DashboardCalendarEventBodyVBox"
	body_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_vbox.add_theme_constant_override("separation", 10)
	body_margin.add_child(body_vbox)

	dashboard_calendar_event_body_label = Label.new()
	dashboard_calendar_event_body_label.name = "DashboardCalendarEventBodyLabel"
	dashboard_calendar_event_body_label.custom_minimum_size = Vector2(408, 92)
	dashboard_calendar_event_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dashboard_calendar_event_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	body_vbox.add_child(dashboard_calendar_event_body_label)

	dashboard_calendar_event_actions_vbox = VBoxContainer.new()
	dashboard_calendar_event_actions_vbox.name = "DashboardCalendarEventActions"
	dashboard_calendar_event_actions_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_calendar_event_actions_vbox.add_theme_constant_override("separation", 6)
	body_vbox.add_child(dashboard_calendar_event_actions_vbox)

	_style_dashboard_calendar_event_popup()


func _style_dashboard_calendar_event_popup() -> void:
	if dashboard_calendar_event_popup == null:
		return
	var panel: PanelContainer = dashboard_calendar_event_popup.find_child("DashboardCalendarEventPanel", true, false) as PanelContainer
	if panel != null:
		_style_panel(panel, COLOR_PANEL_BLUE_ALT, 0)
	var title_bar: PanelContainer = dashboard_calendar_event_popup.find_child("DashboardCalendarEventTitleBar", true, false) as PanelContainer
	if title_bar != null:
		_style_panel(title_bar, COLOR_PANEL_BLUE, 0)
	if dashboard_calendar_event_title_label != null:
		_set_label_tone(dashboard_calendar_event_title_label, COLOR_TEXT)
		dashboard_calendar_event_title_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
	if dashboard_calendar_event_body_label != null:
		_set_label_tone(dashboard_calendar_event_body_label, COLOR_TEXT)
		dashboard_calendar_event_body_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
		dashboard_calendar_event_body_label.add_theme_constant_override("line_spacing", 4)
	if dashboard_calendar_event_actions_vbox != null:
		dashboard_calendar_event_actions_vbox.add_theme_constant_override("separation", 6)
	if dashboard_calendar_event_close_button != null:
		_style_button(
			dashboard_calendar_event_close_button,
			Color(0.368627, 0.160784, 0.176471, 1),
			Color(0.709804, 0.34902, 0.372549, 1),
			COLOR_TEXT,
			0
		)


func _ensure_dashboard_sector_ui() -> void:
	if dashboard_sector_cards_scroll != null:
		return
	var parent_vbox: VBoxContainer = dashboard_placeholder_bottom_body_label.get_parent() as VBoxContainer
	if parent_vbox == null:
		return

	dashboard_placeholder_bottom_body_label.visible = false
	dashboard_placeholder_bottom_body_label.text = ""

	dashboard_sector_cards_scroll = ScrollContainer.new()
	dashboard_sector_cards_scroll.name = "DashboardSectorCardsScroll"
	dashboard_sector_cards_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_sector_cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent_vbox.add_child(dashboard_sector_cards_scroll)

	dashboard_sector_cards_grid = GridContainer.new()
	dashboard_sector_cards_grid.name = "DashboardSectorCardsGrid"
	dashboard_sector_cards_grid.columns = 2
	dashboard_sector_cards_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_sector_cards_grid.add_theme_constant_override("h_separation", 8)
	dashboard_sector_cards_grid.add_theme_constant_override("v_separation", 8)
	dashboard_sector_cards_scroll.add_child(dashboard_sector_cards_grid)

	dashboard_sector_detail_vbox = VBoxContainer.new()
	dashboard_sector_detail_vbox.name = "DashboardSectorDetail"
	dashboard_sector_detail_vbox.visible = false
	dashboard_sector_detail_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_sector_detail_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dashboard_sector_detail_vbox.add_theme_constant_override("separation", 8)
	parent_vbox.add_child(dashboard_sector_detail_vbox)

	var detail_header := HBoxContainer.new()
	detail_header.name = "DashboardSectorDetailHeader"
	detail_header.add_theme_constant_override("separation", 8)
	dashboard_sector_detail_vbox.add_child(detail_header)

	dashboard_sector_back_button = Button.new()
	dashboard_sector_back_button.name = "DashboardSectorBackButton"
	dashboard_sector_back_button.text = "Sectors"
	dashboard_sector_back_button.custom_minimum_size = Vector2(86, 30)
	dashboard_sector_back_button.pressed.connect(_on_dashboard_sector_back_pressed)
	detail_header.add_child(dashboard_sector_back_button)

	dashboard_sector_detail_title_label = Label.new()
	dashboard_sector_detail_title_label.name = "DashboardSectorDetailTitleLabel"
	dashboard_sector_detail_title_label.clip_text = true
	dashboard_sector_detail_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_header.add_child(dashboard_sector_detail_title_label)

	var stock_scroll := ScrollContainer.new()
	stock_scroll.name = "DashboardSectorStockScroll"
	stock_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stock_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dashboard_sector_detail_vbox.add_child(stock_scroll)

	dashboard_sector_detail_rows = VBoxContainer.new()
	dashboard_sector_detail_rows.name = "DashboardSectorStockRows"
	dashboard_sector_detail_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_sector_detail_rows.add_theme_constant_override("separation", 6)
	stock_scroll.add_child(dashboard_sector_detail_rows)

	_style_dashboard_sector_ui()


func _style_dashboard_sector_ui() -> void:
	if dashboard_sector_cards_grid != null:
		dashboard_sector_cards_grid.columns = 2
		dashboard_sector_cards_grid.add_theme_constant_override("h_separation", 8)
		dashboard_sector_cards_grid.add_theme_constant_override("v_separation", 8)
	if dashboard_sector_detail_vbox != null:
		dashboard_sector_detail_vbox.add_theme_constant_override("separation", 8)
	if dashboard_sector_back_button != null:
		_style_button(dashboard_sector_back_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	if dashboard_sector_detail_title_label != null:
		_set_label_tone(dashboard_sector_detail_title_label, COLOR_TEXT)
		dashboard_sector_detail_title_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)


func _ensure_console_overlay() -> void:
	if console_overlay != null:
		return

	console_overlay = Control.new()
	console_overlay.name = "ConsoleCommandOverlay"
	console_overlay.visible = false
	console_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	console_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(console_overlay)
	console_overlay.move_to_front()

	var scrim := ColorRect.new()
	scrim.name = "ConsoleCommandScrim"
	scrim.color = Color(0, 0, 0, 0.42)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	console_overlay.add_child(scrim)

	var console_margin := MarginContainer.new()
	console_margin.name = "ConsoleCommandMargin"
	console_margin.anchor_left = 0.0
	console_margin.anchor_top = 0.0
	console_margin.anchor_right = 1.0
	console_margin.anchor_bottom = 0.0
	console_margin.offset_left = 24.0
	console_margin.offset_top = 24.0
	console_margin.offset_right = -24.0
	console_margin.offset_bottom = 186.0
	console_overlay.add_child(console_margin)

	console_panel = PanelContainer.new()
	console_panel.name = "ConsoleCommandPanel"
	console_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	console_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	console_margin.add_child(console_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.name = "ConsoleCommandPanelMargin"
	panel_margin.add_theme_constant_override("margin_left", 16)
	panel_margin.add_theme_constant_override("margin_top", 12)
	panel_margin.add_theme_constant_override("margin_right", 16)
	panel_margin.add_theme_constant_override("margin_bottom", 12)
	console_panel.add_child(panel_margin)

	var console_vbox := VBoxContainer.new()
	console_vbox.name = "ConsoleCommandVBox"
	console_vbox.add_theme_constant_override("separation", 8)
	console_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_margin.add_child(console_vbox)

	console_title_label = Label.new()
	console_title_label.name = "ConsoleCommandTitleLabel"
	console_title_label.text = "Console Command"
	console_vbox.add_child(console_title_label)

	console_hint_label = Label.new()
	console_hint_label.name = "ConsoleCommandHintLabel"
	console_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	console_hint_label.text = "` toggles console. Enter runs command. Commands: cuankus, ordalbos."
	console_vbox.add_child(console_hint_label)

	console_input = LineEdit.new()
	console_input.name = "ConsoleCommandInput"
	console_input.placeholder_text = "Type command"
	console_input.clear_button_enabled = true
	console_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	console_input.text_submitted.connect(_on_console_command_submitted)
	console_vbox.add_child(console_input)

	console_status_label = Label.new()
	console_status_label.name = "ConsoleCommandStatusLabel"
	console_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	console_status_label.text = "Type a command, then press Enter."
	console_vbox.add_child(console_status_label)


func _ensure_corporate_action_ui() -> void:
	if dashboard_meeting_buttons == null:
		dashboard_meeting_buttons = VBoxContainer.new()
		dashboard_meeting_buttons.name = "DashboardMeetingButtons"
		dashboard_meeting_buttons.visible = false
		dashboard_meeting_buttons.add_theme_constant_override("separation", 6)
		dashboard_meeting_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dashboard_placeholder_bottom_body_label.get_parent().add_child(dashboard_meeting_buttons)

	if news_open_meeting_button == null:
		news_open_meeting_button = Button.new()
		news_open_meeting_button.name = "NewsOpenMeetingButton"
		news_open_meeting_button.text = "Open Meeting"
		news_open_meeting_button.visible = false
		news_open_meeting_button.disabled = true
		news_open_meeting_button.tooltip_text = "Open the linked corporate meeting."
		news_open_meeting_button.pressed.connect(_on_news_open_meeting_pressed)
		var news_detail_vbox: VBoxContainer = news_meet_contact_button.get_parent()
		news_detail_vbox.add_child(news_open_meeting_button)
		news_detail_vbox.move_child(news_open_meeting_button, news_detail_vbox.get_children().find(news_meet_contact_button) + 1)

	_ensure_network_context_ui()


	if rupslb_meeting_overlay == null:
		rupslb_meeting_overlay = RUPSLB_MEETING_OVERLAY_SCRIPT.new()
		rupslb_meeting_overlay.name = "RupslbMeetingOverlay"
		rupslb_meeting_overlay.visible = false
		rupslb_meeting_overlay.connect("close_requested", Callable(self, "_close_rupslb_meeting_overlay"))
		rupslb_meeting_overlay.connect("stage_advance_requested", Callable(self, "_on_rupslb_stage_advance_requested"))
		rupslb_meeting_overlay.connect("vote_requested", Callable(self, "_on_rupslb_vote_requested"))
		rupslb_meeting_overlay.connect("lead_approach_requested", Callable(self, "_on_rupslb_lead_approach_requested"))
		add_child(rupslb_meeting_overlay)
		rupslb_meeting_overlay.move_to_front()

	if corporate_meeting_overlay != null:
		return

	corporate_meeting_overlay = Control.new()
	corporate_meeting_overlay.name = "CorporateMeetingOverlay"
	corporate_meeting_overlay.visible = false
	corporate_meeting_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	corporate_meeting_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(corporate_meeting_overlay)
	corporate_meeting_overlay.move_to_front()

	var scrim := ColorRect.new()
	scrim.name = "CorporateMeetingScrim"
	scrim.color = Color(0, 0, 0, 0.38)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	corporate_meeting_overlay.add_child(scrim)

	var center := CenterContainer.new()
	center.name = "CorporateMeetingCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corporate_meeting_overlay.add_child(center)

	corporate_meeting_panel = PanelContainer.new()
	corporate_meeting_panel.name = "CorporateMeetingPanel"
	corporate_meeting_panel.custom_minimum_size = Vector2(680, 420)
	center.add_child(corporate_meeting_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.name = "CorporateMeetingMargin"
	panel_margin.add_theme_constant_override("margin_left", 18)
	panel_margin.add_theme_constant_override("margin_top", 16)
	panel_margin.add_theme_constant_override("margin_right", 18)
	panel_margin.add_theme_constant_override("margin_bottom", 16)
	corporate_meeting_panel.add_child(panel_margin)

	var panel_vbox := VBoxContainer.new()
	panel_vbox.name = "CorporateMeetingVBox"
	panel_vbox.add_theme_constant_override("separation", 10)
	panel_margin.add_child(panel_vbox)

	corporate_meeting_title_label = Label.new()
	corporate_meeting_title_label.name = "CorporateMeetingTitleLabel"
	corporate_meeting_title_label.text = "Corporate Meeting"
	panel_vbox.add_child(corporate_meeting_title_label)

	corporate_meeting_meta_label = Label.new()
	corporate_meeting_meta_label.name = "CorporateMeetingMetaLabel"
	corporate_meeting_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_vbox.add_child(corporate_meeting_meta_label)

	corporate_meeting_summary_label = Label.new()
	corporate_meeting_summary_label.name = "CorporateMeetingSummaryLabel"
	corporate_meeting_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_vbox.add_child(corporate_meeting_summary_label)

	corporate_meeting_agenda_label = Label.new()
	corporate_meeting_agenda_label.name = "CorporateMeetingAgendaLabel"
	corporate_meeting_agenda_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_vbox.add_child(corporate_meeting_agenda_label)

	corporate_meeting_intel_label = Label.new()
	corporate_meeting_intel_label.name = "CorporateMeetingIntelLabel"
	corporate_meeting_intel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	corporate_meeting_intel_label.visible = false
	panel_vbox.add_child(corporate_meeting_intel_label)

	corporate_meeting_attendance_label = Label.new()
	corporate_meeting_attendance_label.name = "CorporateMeetingAttendanceLabel"
	corporate_meeting_attendance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_vbox.add_child(corporate_meeting_attendance_label)

	var button_row := HBoxContainer.new()
	button_row.name = "CorporateMeetingButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_END
	button_row.add_theme_constant_override("separation", 8)
	panel_vbox.add_child(button_row)

	corporate_meeting_attend_button = Button.new()
	corporate_meeting_attend_button.name = "CorporateMeetingAttendButton"
	corporate_meeting_attend_button.text = "Attend"
	corporate_meeting_attend_button.pressed.connect(_on_corporate_meeting_attend_pressed)
	button_row.add_child(corporate_meeting_attend_button)

	corporate_meeting_close_button = Button.new()
	corporate_meeting_close_button.name = "CorporateMeetingCloseButton"
	corporate_meeting_close_button.text = "Close"
	corporate_meeting_close_button.pressed.connect(_close_corporate_meeting_modal)
	button_row.add_child(corporate_meeting_close_button)


func _ensure_news_detail_scroll() -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._ensure_news_detail_scroll()
	news_controller._sync_root_refs()

func _ensure_news_newspaper_ui() -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._ensure_news_newspaper_ui()
	news_controller._sync_root_refs()

func _ensure_social_feed_ui() -> void:
	_ensure_social_controller()
	social_controller.ensure_ui()

func _build_social_left_sidebar() -> PanelContainer:
	_ensure_social_controller()
	return social_controller._build_social_left_sidebar()

func _build_social_right_rail() -> VBoxContainer:
	_ensure_social_controller()
	return social_controller._build_social_right_rail()

func _make_social_account_search_card() -> PanelContainer:
	_ensure_social_controller()
	return social_controller._make_social_account_search_card()

func _make_social_rail_card(node_name: String, title: String) -> PanelContainer:
	_ensure_social_controller()
	return social_controller._make_social_rail_card(node_name, title)
func _order_news_detail_nodes(detail_vbox: VBoxContainer) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._order_news_detail_nodes(detail_vbox)
	news_controller._sync_root_refs()

func _ensure_news_grunge_overlay() -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._ensure_news_grunge_overlay()
	news_controller._sync_root_refs()

func _add_news_paper_speckles(parent: Control) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._add_news_paper_speckles(parent)
	news_controller._sync_root_refs()

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
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._add_news_grunge_texture(parent, node_name, texture_id, anchor_left, anchor_top, anchor_right, anchor_bottom, offset_left, offset_top, offset_right, offset_bottom, alpha, rotation, stretch_mode)
	news_controller._sync_root_refs()

func _market_paper_texture(texture_id: String) -> Texture2D:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: Texture2D = news_controller._market_paper_texture(texture_id)
	news_controller._sync_root_refs()
	return result

func _populate_watchlist_picker() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._populate_watchlist_picker()
	stock_controller._sync_root_refs()
func _build_tutorial_text() -> String:
	return "Open the STOCKBOT app from the desktop, then pick one stock first.\n\nUse the Chart, Key Stats, Financials, Broker, Corp. Action, or Profile tabs to inspect the setup, size the order from the right-side ticket, then use the navbar to advance the day.\n\nDashboard is now overview-only, while Portfolio keeps your holdings and trade history together.\n\nDifficulty: %s." % GameManager.get_current_difficulty_label()


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
	var stock_rows: Array = _get_company_rows_cached().duplicate()
	if stock_rows.is_empty():
		return "No stock universe is loaded yet."

	var sections: Array = [
		_build_debug_pump_dump_candidate_text(stock_rows)
	]

	stock_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("ticker", "")) < str(b.get("ticker", ""))
	)

	var current_year: int = int(GameManager.get_current_trade_date().get("year", 2020))
	var lines: Array = []
	for row_value in stock_rows:
		var row: Dictionary = row_value
		var company_id: String = str(row.get("id", ""))
		var runtime: Dictionary = RunState.get_company(company_id)
		var current_price: float = float(row.get("current_price", runtime.get("current_price", 0.0)))
		var previous_close: float = float(row.get("previous_close", runtime.get("previous_close", current_price)))
		var daily_change_pct: float = float(row.get("daily_change_pct", runtime.get("daily_change_pct", 0.0)))
		if is_zero_approx(daily_change_pct) and not is_zero_approx(previous_close):
			daily_change_pct = (current_price - previous_close) / previous_close
		var starting_price: float = float(row.get("starting_price", runtime.get("starting_price", current_price)))
		var ytd_open_price: float = float(row.get("ytd_open_price", runtime.get("ytd_open_price", starting_price)))
		var since_start_pct: float = 0.0
		if not is_zero_approx(starting_price):
			since_start_pct = (current_price - starting_price) / starting_price
		var ytd_change_pct: float = 0.0
		if not is_zero_approx(ytd_open_price):
			ytd_change_pct = (current_price - ytd_open_price) / ytd_open_price
		lines.append("%s | Today %s | Start %s | %d YTD Open %s | Current %s | Since start %s | YTD %s" % [
			str(row.get("ticker", "")),
			_format_change(daily_change_pct),
			_format_currency(starting_price),
			int(row.get("ytd_reference_year", runtime.get("ytd_reference_year", current_year))),
			_format_currency(ytd_open_price),
			_format_currency(current_price),
			_format_change(since_start_pct),
			_format_change(ytd_change_pct)
		])

	sections.append("ALL STOCK PERFORMANCE\n%s" % "\n".join(lines))
	return "\n\n".join(sections)


func _build_debug_pump_dump_candidate_text(stock_rows: Array) -> String:
	var candidates: Array = []
	for row_value in stock_rows:
		var row: Dictionary = row_value
		var candidate: Dictionary = _debug_pump_dump_candidate(row)
		if candidate.is_empty():
			continue
		candidates.append(candidate)

	if candidates.is_empty():
		return "PUMP / DUMP TRAILER CANDIDATES\nNo candidate data is available yet."

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)

	var lines: Array = ["PUMP / DUMP TRAILER CANDIDATES"]
	var max_rows: int = min(candidates.size(), 12)
	for index in range(max_rows):
		var candidate: Dictionary = candidates[index]
		var row_text: String = "%d. %s | %s | Today %s | 3d %s | Broker %s | Score %s\n   Why: %s" % [
			index + 1,
			str(candidate.get("ticker", "")),
			str(candidate.get("label", "WATCH")),
			_format_change(float(candidate.get("daily_change_pct", 0.0))),
			_format_change(float(candidate.get("recent_change_pct", 0.0))),
			str(candidate.get("flow_tag", "neutral")).capitalize(),
			String.num(float(candidate.get("score", 0.0)), 1),
			_debug_join_reasons(candidate.get("reasons", []))
		]
		var campaign_line: String = str(candidate.get("campaign_line", ""))
		if not campaign_line.is_empty():
			row_text += "\n   Campaign: %s" % campaign_line
		var abnormal_line: String = str(candidate.get("abnormal_line", ""))
		if not abnormal_line.is_empty():
			row_text += "\n   Guard: %s" % abnormal_line
		lines.append(row_text)
	return "\n".join(lines)


func _debug_pump_dump_candidate(row: Dictionary) -> Dictionary:
	var company_id: String = str(row.get("id", ""))
	if company_id.is_empty():
		return {}

	var runtime: Dictionary = RunState.get_company(company_id)
	if runtime.is_empty():
		return {}

	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	var current_price: float = float(row.get("current_price", runtime.get("current_price", 0.0)))
	var previous_close: float = float(row.get("previous_close", runtime.get("previous_close", current_price)))
	var daily_change_pct: float = float(row.get("daily_change_pct", runtime.get("daily_change_pct", 0.0)))
	if is_zero_approx(daily_change_pct) and not is_zero_approx(previous_close):
		daily_change_pct = (current_price - previous_close) / previous_close
	var recent_change_pct: float = _debug_recent_price_change(runtime, current_price, 3)
	var ten_day_change_pct: float = _debug_recent_price_change(runtime, current_price, 10)

	var broker_flow: Dictionary = row.get("broker_flow", {})
	if broker_flow.is_empty():
		broker_flow = runtime.get("broker_flow", {})
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))
	var net_pressure: float = clamp(float(broker_flow.get("net_pressure", 0.0)), -1.0, 1.0)
	var action_meter_score: float = clamp(float(broker_flow.get("action_meter_score", net_pressure)), -1.0, 1.0)
	var event_context: Dictionary = _debug_active_event_context(runtime, row)
	var event_score: float = float(event_context.get("score", 0.0))
	var event_labels: Array = event_context.get("labels", [])
	var profile_context: Dictionary = _debug_profile_pump_dump_context(definition, runtime)
	var campaign_context: Dictionary = _debug_gorengan_campaign_context(runtime)
	var abnormal_context: Dictionary = _debug_abnormal_move_context(runtime)

	var pump_score: float = 0.0
	pump_score += max(daily_change_pct, 0.0) * 280.0
	pump_score += max(recent_change_pct, 0.0) * 190.0
	pump_score += max(ten_day_change_pct, 0.0) * 70.0
	pump_score += max(net_pressure, 0.0) * 18.0
	pump_score += max(action_meter_score, 0.0) * 10.0
	pump_score += max(event_score, 0.0) * 22.0
	pump_score += float(profile_context.get("pump_bonus", 0.0))
	pump_score += float(campaign_context.get("pump_bonus", 0.0))
	pump_score += float(abnormal_context.get("pump_bonus", 0.0))

	var dump_score: float = 0.0
	dump_score += max(-daily_change_pct, 0.0) * 280.0
	dump_score += max(-recent_change_pct, 0.0) * 190.0
	dump_score += max(-ten_day_change_pct, 0.0) * 70.0
	dump_score += max(-net_pressure, 0.0) * 18.0
	dump_score += max(-action_meter_score, 0.0) * 10.0
	dump_score += max(-event_score, 0.0) * 22.0
	dump_score += float(profile_context.get("dump_bonus", 0.0))
	dump_score += float(campaign_context.get("dump_bonus", 0.0))
	dump_score += float(abnormal_context.get("dump_bonus", 0.0))

	var reasons: Array = []
	if absf(daily_change_pct) >= 0.035:
		_debug_append_unique_reason(reasons, "big move today")
	if absf(recent_change_pct) >= 0.060:
		_debug_append_unique_reason(reasons, "3-day momentum")
	if absf(ten_day_change_pct) >= 0.120:
		_debug_append_unique_reason(reasons, "10-day swing")
	if flow_tag == "accumulation":
		pump_score += 10.0
		_debug_append_unique_reason(reasons, "broker accumulation")
	elif flow_tag == "distribution":
		dump_score += 10.0
		_debug_append_unique_reason(reasons, "broker distribution")
	elif absf(net_pressure) >= 0.16:
		_debug_append_unique_reason(reasons, "broker pressure %s" % _debug_signed_decimal(net_pressure))
	for event_label_value in event_labels:
		_debug_append_unique_reason(reasons, str(event_label_value))
	var profile_reason: String = str(profile_context.get("reason", ""))
	if not profile_reason.is_empty():
		_debug_append_unique_reason(reasons, profile_reason)
	var hidden_flags: Array = runtime.get("hidden_story_flags", [])
	if _debug_text_list_has(hidden_flags, ["accumulation", "stealth_interest"]):
		pump_score += 8.0
		_debug_append_unique_reason(reasons, "hidden accumulation flag")
	if _debug_text_list_has(hidden_flags, ["distribution"]):
		dump_score += 8.0
		_debug_append_unique_reason(reasons, "hidden distribution flag")
	var campaign_reason: String = str(campaign_context.get("reason", ""))
	if not campaign_reason.is_empty():
		_debug_append_unique_reason(reasons, campaign_reason)
	var abnormal_reason: String = str(abnormal_context.get("reason", ""))
	if not abnormal_reason.is_empty():
		_debug_append_unique_reason(reasons, abnormal_reason)

	var label: String = "PUMP" if pump_score >= dump_score else "DUMP"
	var score: float = max(pump_score, dump_score)
	if score < 12.0:
		label = "WATCH"
		if reasons.is_empty():
			_debug_append_unique_reason(reasons, "quiet tape; use as baseline")
	elif label == "PUMP" and recent_change_pct < -0.025 and daily_change_pct < 0.0:
		label = "DUMP"
	elif label == "DUMP" and recent_change_pct > 0.025 and daily_change_pct > 0.0:
		label = "PUMP"

	return {
		"ticker": str(row.get("ticker", definition.get("ticker", company_id.to_upper()))),
		"label": label,
		"score": score,
		"daily_change_pct": daily_change_pct,
		"recent_change_pct": recent_change_pct,
		"flow_tag": flow_tag,
		"reasons": reasons,
		"campaign_line": str(campaign_context.get("line", "")),
		"abnormal_line": str(abnormal_context.get("line", ""))
	}


func _debug_recent_price_change(runtime: Dictionary, fallback_current_price: float, lookback_days: int) -> float:
	var history_value = runtime.get("price_history", [])
	if typeof(history_value) != TYPE_ARRAY:
		return 0.0
	var price_history: Array = history_value
	if price_history.size() < 2:
		return 0.0
	var end_index: int = price_history.size() - 1
	var start_index: int = max(end_index - max(lookback_days, 1), 0)
	var start_price: float = float(price_history[start_index])
	var end_price: float = float(price_history[end_index])
	if end_price <= 0.0:
		end_price = fallback_current_price
	if is_zero_approx(start_price):
		return 0.0
	return (end_price - start_price) / start_price


func _debug_active_event_context(runtime: Dictionary, row: Dictionary) -> Dictionary:
	var score: float = 0.0
	var labels: Array = []
	var active_events_value = runtime.get("active_events", [])
	if typeof(active_events_value) == TYPE_ARRAY:
		for event_value in active_events_value:
			if typeof(event_value) != TYPE_DICTIONARY:
				continue
			var event_data: Dictionary = event_value
			var event_id: String = str(event_data.get("event_id", event_data.get("id", "")))
			var tone: String = str(event_data.get("tone", "mixed")).to_lower()
			var shift: float = float(event_data.get("sentiment_shift", event_data.get("market_bias_shift", 0.0)))
			if is_zero_approx(shift):
				if tone == "positive":
					shift = 0.012
				elif tone == "negative":
					shift = -0.012
			score += clamp(shift * 22.0, -0.8, 0.8)
			if not event_id.is_empty() and labels.size() < 2:
				labels.append(_format_debug_event_title(event_id))

	var tag_values = runtime.get("active_event_tags", row.get("event_tags", []))
	if typeof(tag_values) == TYPE_ARRAY:
		for tag_value in tag_values:
			var tag_text: String = str(tag_value).to_lower()
			if tag_text.contains("pump") or tag_text.contains("hype") or tag_text.contains("positive") or tag_text.contains("optimism"):
				score += 0.25
			if tag_text.contains("dump") or tag_text.contains("negative") or tag_text.contains("controversy") or tag_text.contains("spiral"):
				score -= 0.25
			if labels.size() < 2 and not tag_text.is_empty():
				labels.append(_format_debug_event_title(tag_text))

	if labels.is_empty() and absf(score) >= 0.18:
		labels.append("active event bias %s" % _debug_signed_decimal(score))

	return {
		"score": clamp(score, -1.0, 1.0),
		"labels": labels
	}


func _debug_profile_pump_dump_context(definition: Dictionary, runtime: Dictionary) -> Dictionary:
	var chart_profile: Dictionary = definition.get("chart_profile", {})
	var generation_traits: Dictionary = definition.get("generation_traits", {})
	if chart_profile.is_empty() and generation_traits.has("chart_profile"):
		chart_profile = generation_traits.get("chart_profile", {})
	var narrative_tags: Array = definition.get("narrative_tags", [])
	var profile_tags: Array = definition.get("profile_tags", [])
	var archetype_text: String = "%s %s %s %s" % [
		str(definition.get("archetype_id", "")),
		str(definition.get("archetype_label", "")),
		str(chart_profile.get("archetype", "")),
		str(chart_profile.get("cycle_template", ""))
	]
	var tag_values: Array = []
	tag_values.append_array(narrative_tags)
	tag_values.append_array(profile_tags)
	tag_values.append_array(runtime.get("hidden_story_flags", []))
	tag_values.append(archetype_text)

	var pump_bonus: float = 0.0
	var dump_bonus: float = 0.0
	var reason: String = ""
	if _debug_text_list_has(tag_values, ["gorengan", "operator_markup", "retail_favorite", "narrative_hot", "speculative"]):
		pump_bonus += 10.0
		dump_bonus += 8.0
		reason = "speculative/gorengan profile"
	if _debug_text_list_has(tag_values, ["operator_rug", "distribution", "distressed"]):
		dump_bonus += 11.0
		if reason.is_empty():
			reason = "distribution/rug profile"
	if _debug_text_list_has(tag_values, ["stealth_interest", "accumulation"]):
		pump_bonus += 7.0
		if reason.is_empty():
			reason = "accumulation profile"

	return {
		"pump_bonus": pump_bonus,
		"dump_bonus": dump_bonus,
		"reason": reason
	}


func _debug_abnormal_move_context(runtime: Dictionary) -> Dictionary:
	var abnormal_value = runtime.get("abnormal_move_context", {})
	if typeof(abnormal_value) != TYPE_DICTIONARY:
		return {}
	var abnormal: Dictionary = abnormal_value
	if abnormal.is_empty() or not bool(abnormal.get("active", false)):
		return {}
	var phase: String = str(abnormal.get("phase", "normal")).replace("_", " ")
	var hard_count: int = int(abnormal.get("hard_catalyst_count", 0))
	var required_count: int = int(abnormal.get("required_hard_catalysts", 0))
	var status_parts: Array = []
	if bool(abnormal.get("uma_issued", false)):
		status_parts.append("UMA")
	if bool(abnormal.get("suspension_seen", false)):
		status_parts.append("suspension")
	if bool(abnormal.get("split_scheduled", false)) or bool(abnormal.get("split_executed", false)):
		status_parts.append("split path")
	elif bool(abnormal.get("split_required", false)):
		status_parts.append("split needed")
	elif bool(abnormal.get("split_pressure", false)):
		status_parts.append("split pressure")
	var floor_days: int = int(abnormal.get("floor_days", 0))
	if floor_days > 0:
		var floor_status: String = str(abnormal.get("floor_status", "floor_watch")).replace("_", " ")
		var floor_score: float = float(abnormal.get("floor_turnaround_score", 0.0))
		status_parts.append("floor %dd %s %.2f" % [floor_days, floor_status, floor_score])
	var line: String = "%s | CA %d/%d | Since %s | YTD %s | Green streak %d" % [
		phase.capitalize(),
		hard_count,
		required_count,
		_format_change(float(abnormal.get("since_start_return", 0.0))),
		_format_change(float(abnormal.get("ytd_return", 0.0))),
		int(abnormal.get("green_limit_streak", 0))
	]
	if not status_parts.is_empty():
		line += " | %s" % ", ".join(status_parts)
	var next_needed: String = str(abnormal.get("next_needed_beat", ""))
	if not next_needed.is_empty():
		line += " | Next: %s" % next_needed
	var dump_bonus: float = 0.0
	var pump_bonus: float = 0.0
	if phase.contains("watch"):
		pump_bonus += 4.0
		dump_bonus += 4.0
	elif phase.contains("distribution") or phase.contains("split") or phase.contains("suspension") or phase.contains("chop") or phase.contains("guard"):
		dump_bonus += 12.0
	elif phase.contains("floor"):
		pump_bonus += 5.0
	var reason: String = ""
	if not next_needed.is_empty():
		reason = "guard needs %s" % next_needed
	elif not phase.is_empty():
		reason = "guard phase %s" % phase
	return {
		"line": line,
		"pump_bonus": pump_bonus,
		"dump_bonus": dump_bonus,
		"reason": reason
	}


func _debug_gorengan_campaign_context(runtime: Dictionary) -> Dictionary:
	var campaign_value = runtime.get("gorengan_campaign", {})
	if typeof(campaign_value) != TYPE_DICTIONARY:
		return {}
	var campaign: Dictionary = campaign_value
	if campaign.is_empty():
		return {}
	var phase: String = str(campaign.get("phase", ""))
	var wave: String = str(campaign.get("wave", ""))
	var tier: String = str(campaign.get("tier", "common")).capitalize()
	var realized_pct: float = float(campaign.get("realized_return_pct", campaign.get("last_realized_return_pct", 0.0)))
	var target_pct: float = float(campaign.get("target_return_pct", 0.0))
	var hard_count: int = int(campaign.get("hard_catalyst_count", 0))
	var required_count: int = max(int(campaign.get("required_hard_catalysts", 0)), 0)
	var regulatory_heat: float = float(campaign.get("regulatory_heat", 0.0))
	var status_parts: Array = []
	if bool(campaign.get("uma_issued", false)):
		status_parts.append("UMA")
	if bool(campaign.get("suspension_seen", false)):
		status_parts.append("suspension")
	if bool(campaign.get("split_scheduled", false)) or bool(campaign.get("split_executed", false)):
		status_parts.append("split path")
	elif bool(campaign.get("split_required", false)):
		status_parts.append("split needed")
	var next_needed: String = str(campaign.get("next_needed_beat", ""))
	var line: String = "%s | Wave %s %s | CA %d/%d | Return %s/%s | Heat %d%%" % [
		tier,
		wave,
		phase.replace("_", " "),
		hard_count,
		required_count,
		_format_change(realized_pct),
		_format_change(target_pct),
		int(round(regulatory_heat * 100.0))
	]
	if not status_parts.is_empty():
		line += " | %s" % ", ".join(status_parts)
	if not next_needed.is_empty():
		line += " | Next: %s" % next_needed
	var pump_bonus: float = 0.0
	var dump_bonus: float = 0.0
	if phase in ["accumulation", "markup", "final_hype"]:
		pump_bonus += 14.0
	elif phase in ["shakeout", "regulatory_chop"]:
		pump_bonus += 5.0
		dump_bonus += 8.0
	elif phase in ["distribution", "dump", "dead_cat", "cooldown"]:
		dump_bonus += 18.0
	var reason: String = ""
	if bool(campaign.get("gate_locked", false)):
		reason = "campaign gate locked"
	elif not phase.is_empty():
		reason = "campaign %s wave %s" % [phase.replace("_", " "), wave]
	return {
		"line": line,
		"pump_bonus": pump_bonus,
		"dump_bonus": dump_bonus,
		"reason": reason
	}


func _debug_text_list_has(values: Array, needles: Array) -> bool:
	for value in values:
		var value_text: String = str(value).to_lower()
		if value_text.is_empty():
			continue
		for needle_value in needles:
			var needle: String = str(needle_value).to_lower()
			if not needle.is_empty() and value_text.contains(needle):
				return true
	return false


func _debug_append_unique_reason(reasons: Array, reason: String) -> void:
	var clean_reason: String = reason.strip_edges()
	if clean_reason.is_empty() or reasons.has(clean_reason):
		return
	reasons.append(clean_reason)


func _debug_join_reasons(reasons: Array) -> String:
	if reasons.is_empty():
		return "quiet tape; use as baseline"
	var trimmed_reasons: Array = []
	var max_reasons: int = min(reasons.size(), 4)
	for index in range(max_reasons):
		trimmed_reasons.append(str(reasons[index]))
	return "; ".join(trimmed_reasons)


func _debug_signed_decimal(value: float) -> String:
	return "%+.2f" % [value]


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
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_order_controls(snapshot)
	stock_controller._sync_root_refs()
func _build_order_impact_hint(snapshot: Dictionary, active_estimate: Dictionary, side: String) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._build_order_impact_hint(snapshot, active_estimate, side)
	stock_controller._sync_root_refs()
	return result
func _selected_lots() -> int:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: int = stock_controller._selected_lots()
	stock_controller._sync_root_refs()
	return result
func _update_order_side_buttons() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._update_order_side_buttons()
	stock_controller._sync_root_refs()
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
	_refresh_first_hour_guide_progress()
	call_deferred("_refresh_ftue_progress")


func _set_active_app(app_id: String) -> void:
	var normalized_app_id: String = app_id.to_lower()
	if (
		normalized_app_id != APP_ID_STOCK and
		normalized_app_id != APP_ID_NEWS and
		normalized_app_id != APP_ID_SOCIAL and
		normalized_app_id != APP_ID_NETWORK and
		normalized_app_id != APP_ID_ACADEMY and
		normalized_app_id != APP_ID_THESIS and
		normalized_app_id != APP_ID_LIFE and
		normalized_app_id != APP_ID_COMPANY and
		normalized_app_id != APP_ID_UPGRADES
	):
		normalized_app_id = APP_ID_DESKTOP
	if normalized_app_id == APP_ID_ACADEMY and not GameManager.is_academy_available():
		_show_toast(GameManager.get_academy_release_message(), false)
		_apply_academy_release_lock_state()
		_refresh_desktop()
		return

	desktop_layer.visible = true
	app_window_backdrop.visible = false
	app_window_title_bar.visible = false
	if normalized_app_id == APP_ID_DESKTOP:
		active_app_id = APP_ID_DESKTOP
		_hide_debug_overlay()
		_hide_toast()
		_apply_window_layout()
		_apply_active_window_theme()
		_refresh_pending_dashboard_after_guarded_advance()
		_refresh_desktop()
		_refresh_ftue_progress()
		_refresh_first_hour_guide_progress()
		return

	_remove_deferred_open_app_refresh(normalized_app_id)
	_open_desktop_app_window(normalized_app_id)
	_refresh_app_window_content(normalized_app_id)
	_hide_debug_overlay()
	_hide_toast()
	_apply_window_layout()
	_apply_active_window_theme()
	_refresh_desktop()
	_refresh_ftue_progress()
	_refresh_first_hour_guide_progress()


func _apply_window_layout() -> void:
	var safe_insets: Vector4 = _desktop_safe_insets()
	var window_margin_left: float = APP_WINDOW_INSET + safe_insets.x
	var window_margin_top: float = APP_WINDOW_INSET + safe_insets.y
	var window_margin_right: float = APP_WINDOW_INSET + safe_insets.z
	var window_margin_bottom: float = APP_WINDOW_FRAME_BOTTOM_MARGIN + safe_insets.w
	var social_margin_left: float = APP_WINDOW_CONTENT_MARGIN
	var social_margin_top: float = APP_WINDOW_CONTENT_TOP_MARGIN
	var social_margin_right: float = APP_WINDOW_CONTENT_MARGIN
	var social_margin_bottom: float = APP_WINDOW_CONTENT_BOTTOM_MARGIN

	if active_app_id == APP_ID_SOCIAL:
		var viewport_size: Vector2 = get_viewport_rect().size
		var social_width_max: float = min(max(viewport_size.x - 32.0, 320.0), SOCIAL_WINDOW_MAX_WIDTH)
		var social_width_min: float = min(760.0, social_width_max)
		var social_width: float = clamp(viewport_size.x - 72.0, social_width_min, social_width_max)
		var social_height_max: float = min(max(viewport_size.y - 32.0, 360.0), SOCIAL_WINDOW_MAX_HEIGHT)
		var social_height: float = clamp(viewport_size.y - 96.0, min(SOCIAL_WINDOW_MIN_HEIGHT, social_height_max), social_height_max)
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
	top_bar_outer_margin.add_theme_constant_override("margin_left", int(safe_insets.x))
	top_bar_outer_margin.add_theme_constant_override("margin_top", int(safe_insets.y))
	top_bar_outer_margin.add_theme_constant_override("margin_right", int(safe_insets.z))
	sidebar_outer_margin.add_theme_constant_override("margin_left", int(safe_insets.x))
	sidebar_outer_margin.add_theme_constant_override("margin_top", int(safe_insets.y))
	sidebar_outer_margin.add_theme_constant_override("margin_bottom", int(safe_insets.w))
	news_window.add_theme_constant_override("margin_left", APP_WINDOW_CONTENT_MARGIN)
	news_window.add_theme_constant_override("margin_top", APP_WINDOW_CONTENT_TOP_MARGIN)
	news_window.add_theme_constant_override("margin_right", APP_WINDOW_CONTENT_MARGIN)
	news_window.add_theme_constant_override("margin_bottom", APP_WINDOW_CONTENT_BOTTOM_MARGIN)
	network_window.add_theme_constant_override("margin_left", APP_WINDOW_CONTENT_MARGIN)
	network_window.add_theme_constant_override("margin_top", APP_WINDOW_CONTENT_TOP_MARGIN)
	network_window.add_theme_constant_override("margin_right", APP_WINDOW_CONTENT_MARGIN)
	network_window.add_theme_constant_override("margin_bottom", APP_WINDOW_CONTENT_BOTTOM_MARGIN)
	if academy_window != null:
		academy_window.add_theme_constant_override("margin_left", APP_WINDOW_CONTENT_MARGIN)
		academy_window.add_theme_constant_override("margin_top", APP_WINDOW_CONTENT_TOP_MARGIN)
		academy_window.add_theme_constant_override("margin_right", APP_WINDOW_CONTENT_MARGIN)
		academy_window.add_theme_constant_override("margin_bottom", APP_WINDOW_CONTENT_BOTTOM_MARGIN)
	if thesis_window != null:
		thesis_window.add_theme_constant_override("margin_left", APP_WINDOW_CONTENT_MARGIN)
		thesis_window.add_theme_constant_override("margin_top", APP_WINDOW_CONTENT_TOP_MARGIN)
		thesis_window.add_theme_constant_override("margin_right", APP_WINDOW_CONTENT_MARGIN)
		thesis_window.add_theme_constant_override("margin_bottom", APP_WINDOW_CONTENT_BOTTOM_MARGIN)
	if life_window != null:
		life_window.add_theme_constant_override("margin_left", APP_WINDOW_CONTENT_MARGIN)
		life_window.add_theme_constant_override("margin_top", APP_WINDOW_CONTENT_TOP_MARGIN)
		life_window.add_theme_constant_override("margin_right", APP_WINDOW_CONTENT_MARGIN)
		life_window.add_theme_constant_override("margin_bottom", APP_WINDOW_CONTENT_BOTTOM_MARGIN)
	if company_window != null:
		company_window.add_theme_constant_override("margin_left", APP_WINDOW_CONTENT_MARGIN)
		company_window.add_theme_constant_override("margin_top", APP_WINDOW_CONTENT_TOP_MARGIN)
		company_window.add_theme_constant_override("margin_right", APP_WINDOW_CONTENT_MARGIN)
		company_window.add_theme_constant_override("margin_bottom", APP_WINDOW_CONTENT_BOTTOM_MARGIN)
	upgrade_window.add_theme_constant_override("margin_left", APP_WINDOW_CONTENT_MARGIN)
	upgrade_window.add_theme_constant_override("margin_top", APP_WINDOW_CONTENT_TOP_MARGIN)
	upgrade_window.add_theme_constant_override("margin_right", APP_WINDOW_CONTENT_MARGIN)
	upgrade_window.add_theme_constant_override("margin_bottom", APP_WINDOW_CONTENT_BOTTOM_MARGIN)
	social_window.add_theme_constant_override("margin_left", int(social_margin_left))
	social_window.add_theme_constant_override("margin_top", int(social_margin_top))
	social_window.add_theme_constant_override("margin_right", int(social_margin_right))
	social_window.add_theme_constant_override("margin_bottom", int(social_margin_bottom))
	app_window_title_bar.offset_left = window_margin_left
	app_window_title_bar.offset_top = window_margin_top
	app_window_title_bar.offset_right = -window_margin_right
	app_window_title_bar.offset_bottom = window_margin_top + 44.0
	var stockbot_content_margin: int = STOCKBOT_WINDOW_CONTENT_MARGIN if active_app_id == APP_ID_STOCK else APP_WINDOW_CONTENT_MARGIN
	var stockbot_bottom_margin: int = STOCKBOT_WINDOW_CONTENT_BOTTOM_MARGIN if active_app_id == APP_ID_STOCK else APP_WINDOW_CONTENT_BOTTOM_MARGIN
	stock_window_container.offset_left = stockbot_content_margin
	stock_window_container.offset_top = APP_WINDOW_CONTENT_TOP_MARGIN
	stock_window_container.offset_right = -stockbot_content_margin
	stock_window_container.offset_bottom = -stockbot_bottom_margin
	_apply_desktop_window_layouts()


func _apply_active_window_theme() -> void:
	var is_light_window: bool = active_app_id == APP_ID_NEWS or active_app_id == APP_ID_SOCIAL or active_app_id == APP_ID_NETWORK or active_app_id == APP_ID_ACADEMY or active_app_id == APP_ID_THESIS or active_app_id == APP_ID_LIFE or active_app_id == APP_ID_COMPANY or active_app_id == APP_ID_UPGRADES
	var window_fill: Color = COLOR_WINDOW_BG if is_light_window else COLOR_STOCK_WINDOW_BG
	var window_text: Color = COLOR_WINDOW_TEXT if is_light_window else COLOR_TEXT
	var app_font_size: int = STOCK_APP_FONT_SIZE if active_app_id == APP_ID_STOCK else DEFAULT_APP_FONT_SIZE
	_style_panel(app_window_panel, window_fill, 8)
	_style_window_title_bar(app_window_title_bar, window_fill)
	_style_panel(stock_window_container, COLOR_STOCK_WINDOW_BG, 0)
	if active_app_id == APP_ID_STOCK:
		_style_stockbot_panel(app_window_panel, COLOR_STOCKBOT_BASE, COLOR_STOCKBOT_BLUE_EDGE, 8, 1)
		_style_window_title_bar(app_window_title_bar, COLOR_STOCKBOT_BASE, COLOR_STOCKBOT_BLUE_EDGE, 1)
		_style_stockbot_panel(stock_window_container, COLOR_STOCKBOT_BASE, COLOR_STOCKBOT_BLUE_EDGE, 0, 1)
	app_window_title_bar.add_theme_font_size_override("font_size", app_font_size)
	_set_label_tone(app_window_title_label, window_text)
	app_window_title_label.add_theme_color_override("font_color", window_text)
	_refresh_desktop_window_themes()


func _sync_desktop_app_state() -> void:
	var stock_open: bool = _is_desktop_app_window_open(APP_ID_STOCK)
	var news_open: bool = _is_desktop_app_window_open(APP_ID_NEWS)
	var social_open: bool = _is_desktop_app_window_open(APP_ID_SOCIAL)
	var network_open: bool = _is_desktop_app_window_open(APP_ID_NETWORK)
	var academy_open: bool = _is_desktop_app_window_open(APP_ID_ACADEMY)
	var thesis_open: bool = _is_desktop_app_window_open(APP_ID_THESIS)
	var life_open: bool = _is_desktop_app_window_open(APP_ID_LIFE)
	var company_open: bool = _is_desktop_app_window_open(APP_ID_COMPANY)
	var upgrades_open: bool = _is_desktop_app_window_open(APP_ID_UPGRADES)
	stock_app_button.set_pressed_no_signal(stock_open)
	news_app_button.set_pressed_no_signal(news_open)
	social_app_button.set_pressed_no_signal(social_open)
	network_app_button.set_pressed_no_signal(network_open)
	if academy_app_button != null:
		academy_app_button.set_pressed_no_signal(academy_open)
	if thesis_app_button != null:
		thesis_app_button.set_pressed_no_signal(thesis_open)
	if life_app_button != null:
		life_app_button.set_pressed_no_signal(life_open)
	if company_app_button != null:
		company_app_button.set_pressed_no_signal(company_open)
	upgrades_app_button.set_pressed_no_signal(upgrades_open)
	taskbar_stock_button.set_pressed_no_signal(stock_open)
	taskbar_news_button.set_pressed_no_signal(news_open)
	taskbar_home_button.disabled = active_app_id == APP_ID_DESKTOP
	for app_id in desktop_bottom_nav_buttons.keys():
		var nav_button: Button = desktop_bottom_nav_buttons[app_id]
		var is_active: bool = str(app_id) == active_app_id
		if nav_button.toggle_mode:
			nav_button.set_pressed_no_signal(is_active)
		_style_desktop_bottom_nav_button(nav_button, is_active)


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
		return "Twooter open  |  Public market chatter online."
	if active_app_id == APP_ID_NETWORK:
		return "Network open  |  Contacts, recognition, and requests online."
	if active_app_id == APP_ID_ACADEMY:
		return "Academy open  |  Technical chart-reading lessons online."
	if active_app_id == APP_ID_THESIS:
		return "Thesis Board open  |  Research notes and evidence discipline online."
	if active_app_id == APP_ID_LIFE:
		return "Life open  |  Monthly cash-flow plan online."
	if active_app_id == APP_ID_COMPANY:
		return "Company open  |  Majority-control agenda tools online."
	if active_app_id == APP_ID_UPGRADES:
		return "Upgrades open  |  Spend cash to improve your desk."
	return "Desktop ready  |  Open STOCKBOT, News, Twooter, Network, Academy (Coming Soon), Thesis, Life, Company, Shop, or Settings."


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
	return "Market tone: %s\nMacro: %s\nInflation %.1f%% | GDP %.1f%% | Employment %s | Unemployment %.1f%% | Policy %.2f%% (%+d bps)\nSector breadth: %d green | %d red | %d flat | Loudest sector %s %s" % [
		_format_change(RunState.market_sentiment),
		str(macro_state.get("central_bank_stance", "hold")).capitalize(),
		float(macro_state.get("inflation_yoy", 0.0)),
		float(macro_state.get("gdp_growth", 0.0)),
		str(macro_state.get("employment_label", "Mixed")),
		float(macro_state.get("unemployment_rate", 0.0)),
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
	var action_text: String = side.replace("_", " ")
	var header: String = "Day %d | %s | %s | %d lot(s) / %d share(s)" % [
		int(trade.get("day_index", 0)),
		action_text,
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
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._build_setup_read(snapshot)
	stock_controller._sync_root_refs()
	return result
func _build_support_signals(snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._build_support_signals(snapshot)
	stock_controller._sync_root_refs()
	return result
func _build_risk_signals(snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._build_risk_signals(snapshot)
	stock_controller._sync_root_refs()
	return result
func _build_action_hint(snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._build_action_hint(snapshot)
	stock_controller._sync_root_refs()
	return result
func _build_broker_hint(snapshot: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._build_broker_hint(snapshot)
	stock_controller._sync_root_refs()
	return result
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
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._broker_actor_label(broker_flow, side)
	stock_controller._sync_root_refs()
	return result
func _watchlist_tooltip(row: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._watchlist_tooltip(row)
	stock_controller._sync_root_refs()
	return result
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
	_style_panel(dashboard_movers_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(dashboard_placeholder_bottom_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_dashboard_calendar_event_popup()
	_style_dashboard_sector_ui()
	_style_panel(news_window_body, COLOR_WINDOW_BG, 0, 0, 0, 0, 0)
	_style_panel(news_feed_panel, Color(0.952941, 0.94902, 0.87451, 1), 0)
	_style_panel(news_detail_panel, Color(0.968627, 0.964706, 0.898039, 1), 0)
	if news_detail_hero_frame != null:
		_style_news_asset_frame(news_detail_hero_frame)
	_style_news_newspaper_ui()
	_style_twooter_ui()
	_style_cream_app_panel(network_window_body, COLOR_ACADEMY_CREAM, Color(COLOR_ACADEMY_BORDER.r, COLOR_ACADEMY_BORDER.g, COLOR_ACADEMY_BORDER.b, 0.0), 0, 0)
	_style_cream_app_panel(network_list_panel, COLOR_ACADEMY_PANEL, COLOR_ACADEMY_BORDER, 4, 1)
	_style_cream_app_panel(network_detail_panel, COLOR_DESKTOP_CREAM, COLOR_ACADEMY_BORDER, 4, 1)
	if academy_window_body != null:
		_apply_academy_text_theme()
		_restyle_academy_controls()
	_style_life_news_tabs()
	_style_cream_app_panel(upgrade_window_body, COLOR_ACADEMY_CREAM, Color(COLOR_ACADEMY_BORDER.r, COLOR_ACADEMY_BORDER.g, COLOR_ACADEMY_BORDER.b, 0.0), 0, 0)
	if console_panel != null:
		_style_panel(console_panel, Color(0.0588235, 0.0823529, 0.109804, 0.98), 0)
	_style_ftue_overlay()
	_style_panel(action_panel, COLOR_ORDER_PANEL_BG, 0)
	_style_panel(order_card_panel, COLOR_ORDER_CARD_BG, 0)
	if contact_intel_panel != null:
		_style_panel(contact_intel_panel, COLOR_ORDER_CARD_BG, 0)
	_style_panel(key_stats_panel, COLOR_PANEL_BLUE, 0)
	_style_panel(financials_panel, COLOR_PANEL_BLUE, 0)
	_style_panel(broker_panel, COLOR_PANEL_BLUE, 0)
	_style_panel(analyzer_panel, COLOR_PANEL_BLUE, 0)
	_style_panel(corporate_actions_panel, COLOR_PANEL_BLUE, 0)
	_style_panel(profile_panel, COLOR_PANEL_BLUE, 0)
	_style_profile_company_layout()
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
	_style_desktop_icon_button(network_app_button)
	if academy_app_button != null:
		_style_desktop_icon_button(academy_app_button)
	if thesis_app_button != null:
		_style_desktop_icon_button(thesis_app_button)
	if life_app_button != null:
		_style_desktop_icon_button(life_app_button)
	_style_desktop_icon_button(upgrades_app_button)
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
	_style_tab_container(dashboard_movers_tabs, 0)
	_style_tab_container(debug_tabs, 0)
	_style_button(add_watchlist_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_button(remove_watchlist_button, Color(0.27451, 0.164706, 0.180392, 1), Color(0.690196, 0.34902, 0.372549, 1), COLOR_TEXT, 0)
	_style_button(buy_button, COLOR_ORDER_BUY, COLOR_ORDER_BUY_BORDER, COLOR_TEXT, 0)
	_style_button(sell_button, COLOR_ORDER_SELL, COLOR_ORDER_SELL_BORDER, COLOR_TEXT, 0)
	_style_button(order_ticket_toggle_button, Color(0.0823529, 0.117647, 0.156863, 0.96), COLOR_BORDER, COLOR_TEXT, 0)
	_style_button(submit_order_button, COLOR_ORDER_BUY, COLOR_ORDER_BUY_BORDER, COLOR_TEXT, 0)
	_style_stockbot_app_ui()
	if contact_intel_button != null:
		_style_button(contact_intel_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_key_stats_dashboard_ui()
	_style_button(app_window_minimize_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_button(app_window_close_button, Color(0.368627, 0.160784, 0.176471, 1), Color(0.709804, 0.34902, 0.372549, 1), COLOR_TEXT, 0)
	_style_button(financials_previous_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_button(financials_next_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_button(debug_close_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_cream_app_button(news_meet_contact_button, true)
	if news_open_meeting_button != null:
		_style_cream_app_button(news_open_meeting_button, true)
	_style_button(profile_meet_contact_button, Color(0.27451, 0.219608, 0.0980392, 1), Color(0.819608, 0.631373, 0.254902, 1), COLOR_TEXT, 0)
	_style_cream_app_button(network_meet_button, true)
	_style_cream_app_button(network_tip_button, true)
	_style_cream_app_button(network_request_button, true)
	_style_cream_app_button(network_referral_button, true)
	if network_followup_button != null:
		_style_cream_app_button(network_followup_button, true)
	if network_source_check_button != null:
		_style_cream_app_button(network_source_check_button, true)
	if network_open_meeting_button != null:
		_style_cream_app_button(network_open_meeting_button, true)
	if corporate_meeting_panel != null:
		_style_panel(corporate_meeting_panel, Color(0.968627, 0.964706, 0.898039, 1), 0)
	if corporate_meeting_attend_button != null:
		_style_button(corporate_meeting_attend_button, Color(0.866667, 0.807843, 0.635294, 1), Color(0.709804, 0.607843, 0.345098, 1), COLOR_WINDOW_TEXT, 0)
	if corporate_meeting_close_button != null:
		_style_button(corporate_meeting_close_button, Color(0.835294, 0.819608, 0.772549, 1), Color(0.658824, 0.631373, 0.552941, 1), COLOR_WINDOW_TEXT, 0)
	_style_light_option_button(news_archive_year_option)
	_style_light_option_button(news_archive_month_option)
	_style_item_list(company_list, 0, 0)
	_style_light_item_list(news_article_list)
	_style_light_item_list(network_contacts_list)
	_style_light_item_list(network_requests_list)
	if network_journal_list != null:
		_style_light_item_list(network_journal_list)
	_refresh_network_journal_filter_buttons()
	if watchlist_picker_list != null:
		_style_item_list(watchlist_picker_list, 0, 0)
	if console_input != null:
		_style_line_input(console_input)
	_style_line_input(all_stocks_search_input)
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
	_set_label_tone(network_app_label, COLOR_DESKTOP_TEXT)
	if academy_app_label != null:
		_set_label_tone(academy_app_label, COLOR_DESKTOP_TEXT)
	_set_label_tone(upgrades_app_label, COLOR_DESKTOP_TEXT)
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
	if news_masthead_date_label != null:
		_set_label_tone(news_masthead_date_label, Color(0.352941, 0.309804, 0.203922, 1))
	if news_detail_byline_label != null:
		_set_label_tone(news_detail_byline_label, Color(0.454902, 0.337255, 0.141176, 1))
	if news_detail_chips_label != null:
		_set_label_tone(news_detail_chips_label, Color(0.454902, 0.337255, 0.141176, 1))
	if corporate_meeting_title_label != null:
		_set_label_tone(corporate_meeting_title_label, COLOR_WINDOW_TEXT)
	if corporate_meeting_meta_label != null:
		_set_label_tone(corporate_meeting_meta_label, Color(0.352941, 0.309804, 0.203922, 1))
	if corporate_meeting_summary_label != null:
		_set_label_tone(corporate_meeting_summary_label, COLOR_WINDOW_TEXT)
	if corporate_meeting_agenda_label != null:
		_set_label_tone(corporate_meeting_agenda_label, COLOR_WINDOW_TEXT)
	if corporate_meeting_intel_label != null:
		_set_label_tone(corporate_meeting_intel_label, Color(0.352941, 0.309804, 0.203922, 1))
	if corporate_meeting_attendance_label != null:
		_set_label_tone(corporate_meeting_attendance_label, Color(0.352941, 0.309804, 0.203922, 1))
	news_detail_body.add_theme_color_override("default_color", COLOR_WINDOW_TEXT)
	news_detail_body.add_theme_color_override("font_selected_color", COLOR_WINDOW_TEXT)
	_refresh_desktop_window_themes()
	_set_label_tone(social_title_label, COLOR_TWOOTER_BLUE_DARK)
	_set_label_tone(social_access_status_label, COLOR_TWOOTER_MUTED)
	_set_label_tone(debug_generators_hint_label, COLOR_MUTED)
	_set_label_tone(social_feed_summary_label, COLOR_TWOOTER_MUTED)
	_style_twooter_ui()
	_set_label_tone(network_title_label, COLOR_WINDOW_TEXT)
	_set_label_tone(network_recognition_label, Color(0.454902, 0.337255, 0.141176, 1))
	_set_label_tone(network_summary_label, COLOR_WINDOW_TEXT)
	_set_label_tone(network_contacts_label, COLOR_WINDOW_TEXT)
	_set_label_tone(network_requests_label, COLOR_WINDOW_TEXT)
	_set_label_tone(network_contact_name_label, COLOR_WINDOW_TEXT)
	_set_label_tone(network_contact_meta_label, Color(0.352941, 0.309804, 0.203922, 1))
	_set_label_tone(network_contact_body_label, COLOR_WINDOW_TEXT)
	if network_journal_label != null:
		_set_label_tone(network_journal_label, COLOR_WINDOW_TEXT)
	if network_journal_detail_label != null:
		_set_label_tone(network_journal_detail_label, Color(0.352941, 0.309804, 0.203922, 1))
	if network_corporate_action_label != null:
		_set_label_tone(network_corporate_action_label, Color(0.352941, 0.309804, 0.203922, 1))
	if network_tip_history_label != null:
		_set_label_tone(network_tip_history_label, Color(0.352941, 0.309804, 0.203922, 1))
	if network_crosscheck_label != null:
		_set_label_tone(network_crosscheck_label, Color(0.454902, 0.337255, 0.141176, 1))
	_set_label_tone(upgrade_title_label, COLOR_WINDOW_TEXT)
	_set_label_tone(upgrade_cash_label, Color(0.454902, 0.337255, 0.141176, 1))
	_set_label_tone(upgrade_summary_label, COLOR_WINDOW_TEXT)
	if upgrade_purchase_body_label != null:
		_set_label_tone(upgrade_purchase_body_label, COLOR_DESKTOP_TEXT)
	_style_upgrade_purchase_dialog()
	if daily_recap_body_label != null:
		_set_label_tone(daily_recap_body_label, COLOR_WINDOW_TEXT)
	_style_daily_recap_dialog()
	if macro_event_headline_label != null:
		_set_label_tone(macro_event_headline_label, COLOR_WINDOW_TEXT)
	_style_macro_event_dialog()
	if dirty_tip_body_label != null:
		_set_label_tone(dirty_tip_body_label, COLOR_WINDOW_TEXT)
	_style_dirty_tip_dialog()
	if console_title_label != null:
		_set_label_tone(console_title_label, COLOR_TEXT)
	if console_hint_label != null:
		_set_label_tone(console_hint_label, COLOR_MUTED)
	if console_status_label != null:
		_set_label_tone(console_status_label, COLOR_WARNING)
	_set_label_tone(taskbar_status_label, COLOR_MUTED)
	if taskbar_build_label != null:
		_set_label_tone(taskbar_build_label, COLOR_WARNING)
	_set_label_tone(taskbar_clock_label, COLOR_WARNING)
	_set_label_tone(sidebar_intro_label, COLOR_MUTED)
	_set_label_tone(sidebar_focus_label, COLOR_ACCENT)
	_set_label_tone(sidebar_hint_label, COLOR_MUTED)
	_style_dashboard_section_titles()
	_style_dashboard_index_recap_ui()
	_set_label_tone(dashboard_index_date_label, COLOR_MUTED)
	_set_label_tone(dashboard_index_hint_label, COLOR_WARNING)
	_set_label_tone(dashboard_calendar_month_label, COLOR_ACCENT)
	_set_label_tone(dashboard_top_gainers_empty_label, COLOR_MUTED)
	_set_label_tone(dashboard_top_losers_empty_label, COLOR_MUTED)
	_set_label_tone(dashboard_placeholder_bottom_body_label, COLOR_MUTED)
	_style_order_market_summary_labels()
	_style_order_ticker_badge()
	_set_label_tone(selection_label, COLOR_TEXT)
	_set_label_tone(order_price_value_label, COLOR_TEXT)
	_set_label_tone(order_price_change_label, COLOR_TEXT)
	_set_label_tone(order_position_label, COLOR_MUTED)
	_set_label_tone(order_title_label, COLOR_TEXT)
	_set_label_tone(estimated_total_value_label, COLOR_TEXT)
	_set_label_tone(watchlist_empty_label, COLOR_MUTED)
	_set_label_tone(portfolio_stocks_empty_label, COLOR_MUTED)
	_set_label_tone(profile_tags_label, COLOR_MUTED)
	_set_label_tone(profile_management_label, COLOR_WARNING)
	_set_label_tone(profile_description_label, COLOR_TEXT)
	_set_label_tone(profile_network_hint_label, COLOR_WARNING)
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
	_set_label_tone(corporate_actions_summary_label, COLOR_MUTED)
	_set_label_tone(corporate_actions_empty_label, COLOR_MUTED)
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
	_style_figma_desktop_ui()
	_style_first_hour_guide_ui()
	_style_settings_overlay()
	_style_news_newspaper_ui()
	_style_stockbot_app_ui()
	_apply_active_window_theme()
	_refresh_financial_history_header()
	_refresh_broker_header()


func _style_desktop_icon_button(button: Button) -> void:
	if button == null:
		return
	UiTheme.style_button(button, "desktop_icon")


func _style_taskbar_launch_button(button: Button) -> void:
	if button == null:
		return
	UiTheme.style_button(button, "taskbar_launch")


func _style_window_title_bar(
	panel: PanelContainer,
	fill_color: Color,
	border_color: Color = COLOR_BORDER,
	border_width: int = 1
) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
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
	if button == null:
		return
	UiTheme.style_tab_button(button, "terminal_tab", false, {"radius": 0})


func _style_tab_container(tab_container: TabContainer, corner_radius: int = 6) -> void:
	UiTheme.style_tab_container(tab_container, "terminal", corner_radius)


func _style_button(
	button: Button,
	fill_color: Color,
	border_color: Color,
	font_color: Color,
	corner_radius: int = 8
) -> void:
	if button == null:
		return
	UiTheme.style_button(
		button,
		"custom",
		{
			"fill": fill_color,
			"border": border_color,
			"font": font_color,
			"radius": corner_radius
		}
	)


func _load_stockbot_icon(icon_id: String) -> Texture2D:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Texture2D = stock_controller._load_stockbot_icon(icon_id)
	stock_controller._sync_root_refs()
	return result
func _make_stockbot_stylebox(
	fill_color: Color,
	border_color: Color,
	corner_radius: int = 6,
	border_width: int = 1,
	content_margin: int = 0
) -> StyleBoxFlat:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: StyleBoxFlat = stock_controller._make_stockbot_stylebox(fill_color, border_color, corner_radius, border_width, content_margin)
	stock_controller._sync_root_refs()
	return result
func _set_stockbot_margins(margin_container: MarginContainer, left: int, top: int, right: int, bottom: int) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._set_stockbot_margins(margin_container, left, top, right, bottom)
	stock_controller._sync_root_refs()
func _set_stockbot_spacing(container: Container, separation: int) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._set_stockbot_spacing(container, separation)
	stock_controller._sync_root_refs()
func _style_stockbot_panel(
	panel: PanelContainer,
	fill_color: Color = COLOR_STOCKBOT_SURFACE,
	border_color: Color = COLOR_STOCKBOT_EDGE,
	corner_radius: int = 0,
	border_width: int = 1
) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._style_stockbot_panel(panel, fill_color, border_color, corner_radius, border_width)
	stock_controller._sync_root_refs()
func _style_stockbot_button(
	button: Button,
	fill_color: Color,
	border_color: Color,
	font_color: Color = COLOR_STOCKBOT_TEXT,
	corner_radius: int = 6,
	selected: bool = false
) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._style_stockbot_button(button, fill_color, border_color, font_color, corner_radius, selected)
	stock_controller._sync_root_refs()
func _style_stockbot_icon_button(
	button: Button,
	icon_id: String,
	text_value: String = "",
	tooltip_value: String = "",
	selected: bool = false,
	fill_color: Color = COLOR_STOCKBOT_SURFACE_ALT,
	border_color: Color = COLOR_STOCKBOT_EDGE
) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._style_stockbot_icon_button(button, icon_id, text_value, tooltip_value, selected, fill_color, border_color)
	stock_controller._sync_root_refs()
func _style_stockbot_label_chip(
	label: Label,
	fill_color: Color,
	border_color: Color,
	font_color: Color,
	corner_radius: int = 6
) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._style_stockbot_label_chip(label, fill_color, border_color, font_color, corner_radius)
	stock_controller._sync_root_refs()
func _apply_stockbot_compact_spacing() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._apply_stockbot_compact_spacing()
	stock_controller._sync_root_refs()
func _ensure_stockbot_detail_section_cards() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._ensure_stockbot_detail_section_cards()
	stock_controller._sync_root_refs()
func _ensure_financials_section_cards() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._ensure_financials_section_cards()
	stock_controller._sync_root_refs()
func _ensure_financials_statement_card(
	financials_vbox: VBoxContainer,
	card_name: String,
	title_name: String,
	rows_vbox: VBoxContainer,
	separator_name: String
) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._ensure_financials_statement_card(financials_vbox, card_name, title_name, rows_vbox, separator_name)
	stock_controller._sync_root_refs()
func _ensure_broker_section_cards() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._ensure_broker_section_cards()
	stock_controller._sync_root_refs()
func _build_stockbot_detail_section_card(card_name: String) -> PanelContainer:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: PanelContainer = stock_controller._build_stockbot_detail_section_card(card_name)
	stock_controller._sync_root_refs()
	return result
func _move_nodes_into_stockbot_detail_card(
	parent_vbox: VBoxContainer,
	card_name: String,
	nodes: Array,
	insert_index: int
) -> PanelContainer:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: PanelContainer = stock_controller._move_nodes_into_stockbot_detail_card(parent_vbox, card_name, nodes, insert_index)
	stock_controller._sync_root_refs()
	return result
func _style_stockbot_app_ui() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._style_stockbot_app_ui()
	stock_controller._sync_root_refs()
func _style_stockbot_static_panel_labels() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._style_stockbot_static_panel_labels()
	stock_controller._sync_root_refs()
func _style_light_option_button(option_button: OptionButton) -> void:
	UiTheme.style_option_button(option_button, "desktop")


func _style_news_newspaper_ui() -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._style_news_newspaper_ui()
	news_controller._sync_root_refs()

func _style_news_label(label: Label, color: Color, font_size: int, font_resource: Font = null) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._style_news_label(label, color, font_size, font_resource)
	news_controller._sync_root_refs()

func _style_news_panel(panel: PanelContainer, fill_color: Color, border_color: Color, border_width: int) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._style_news_panel(panel, fill_color, border_color, border_width)
	news_controller._sync_root_refs()

func _style_news_inner_panel(panel: PanelContainer, fill_color: Color) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._style_news_inner_panel(panel, fill_color)
	news_controller._sync_root_refs()

func _style_news_asset_frame(panel: PanelContainer) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._style_news_asset_frame(panel)
	news_controller._sync_root_refs()

func _style_news_article_card(card: PanelContainer, is_selected: bool) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._style_news_article_card(card, is_selected)
	news_controller._sync_root_refs()

func _style_news_outlet_button(button: Button, is_selected: bool, is_unlocked: bool) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._style_news_outlet_button(button, is_selected, is_unlocked)
	news_controller._sync_root_refs()

func _make_news_tab_stylebox(fill_color: Color, border_color: Color, is_selected: bool) -> StyleBoxFlat:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	var result: StyleBoxFlat = news_controller._make_news_tab_stylebox(fill_color, border_color, is_selected)
	news_controller._sync_root_refs()
	return result

func _style_news_tab_button(button: Button, is_selected: bool, is_unlocked: bool) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._style_news_tab_button(button, is_selected, is_unlocked)
	news_controller._sync_root_refs()

func _style_news_tab_container(tab_container: TabContainer) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._style_news_tab_container(tab_container)
	news_controller._sync_root_refs()

func _style_news_command_button(button: Button, is_primary: bool) -> void:
	_ensure_news_controller()
	news_controller._sync_dynamic_refs_from_root()
	news_controller._sync_state_from_root()
	news_controller._style_news_command_button(button, is_primary)
	news_controller._sync_root_refs()

func _style_company_action_button(button: Button, enabled: bool) -> void:
	if button == null:
		return
	var fill_color: Color = COLOR_MARKET_PAPER_RED if enabled else COLOR_MARKET_PAPER_RAIL
	var border_color: Color = COLOR_MARKET_PAPER_RED if enabled else Color(COLOR_MARKET_PAPER_BORDER.r, COLOR_MARKET_PAPER_BORDER.g, COLOR_MARKET_PAPER_BORDER.b, 0.42)
	var font_color: Color = COLOR_MARKET_PAPER_CARD if enabled else Color(COLOR_MARKET_PAPER_MUTED.r, COLOR_MARKET_PAPER_MUTED.g, COLOR_MARKET_PAPER_MUTED.b, 0.68)
	UiTheme.style_button(
		button,
		"custom",
		{
			"fill": fill_color,
			"border": border_color,
			"font": font_color,
			"hover": fill_color.lightened(0.08) if enabled else fill_color,
			"pressed": fill_color.darkened(0.08) if enabled else fill_color,
			"disabled": fill_color,
			"disabled_font": font_color,
			"radius": 4,
			"border_width": 1,
			"margins": {"left": 16, "top": 10, "right": 16, "bottom": 10},
			"size_role": "button"
		}
	)
	button.custom_minimum_size = Vector2(button.custom_minimum_size.x, max(button.custom_minimum_size.y, 42.0))
	_apply_font_override_to_control(button, DEFAULT_APP_FONT_SIZE, _get_dashboard_title_font())


func _style_social_filter_button(button: Button, is_selected: bool, is_unlocked: bool) -> void:
	_ensure_social_controller()
	social_controller._style_social_filter_button(button, is_selected, is_unlocked)

func _style_social_account_button(button: Button, is_selected: bool) -> void:
	_ensure_social_controller()
	social_controller._style_social_account_button(button, is_selected)
func _style_line_input(line_edit: LineEdit) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = COLOR_STOCKBOT_BASE
	normal.border_color = COLOR_STOCKBOT_EDGE
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 5
	normal.corner_radius_top_right = 5
	normal.corner_radius_bottom_right = 5
	normal.corner_radius_bottom_left = 5
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5

	var focus: StyleBoxFlat = normal.duplicate()
	focus.border_color = COLOR_STOCKBOT_BLUE
	focus.set_border_width_all(2)

	line_edit.add_theme_stylebox_override("normal", normal)
	line_edit.add_theme_stylebox_override("focus", focus)
	line_edit.add_theme_stylebox_override("read_only", normal)
	line_edit.add_theme_color_override("font_color", COLOR_STOCKBOT_TEXT)
	line_edit.add_theme_color_override("font_placeholder_color", COLOR_STOCKBOT_MUTED)
	line_edit.add_theme_color_override("font_uneditable_color", COLOR_STOCKBOT_TEXT)
	line_edit.alignment = HORIZONTAL_ALIGNMENT_LEFT


func _style_spin_input(spin_box: SpinBox) -> void:
	var line_edit: LineEdit = spin_box.get_line_edit()
	if line_edit != null:
		_style_line_input(line_edit)
		line_edit.placeholder_text = "Quantity"


func _refresh_submit_order_button_style() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_submit_order_button_style()
	stock_controller._sync_root_refs()
func _style_stock_list_row_button(button: Button, is_selected: bool) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._style_stock_list_row_button(button, is_selected)
	stock_controller._sync_root_refs()
func _style_cream_app_panel(
	panel: PanelContainer,
	fill_color: Color = COLOR_DESKTOP_CREAM,
	border_color: Color = COLOR_DESKTOP_FRAME,
	corner_radius: int = 4,
	border_width: int = 1
) -> void:
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	panel.add_theme_stylebox_override("panel", style)


func _style_cream_app_button(button: Button, primary: bool = false) -> void:
	if button == null:
		return
	UiTheme.style_button(button, "desktop_primary" if primary else "desktop_secondary")


func _style_network_journal_filter_button(button: Button, is_selected: bool) -> void:
	var fill_color: Color = COLOR_DESKTOP_GOLD if is_selected else COLOR_DESKTOP_CREAM
	var border_color: Color = COLOR_DESKTOP_BROWN if is_selected else COLOR_DESKTOP_FRAME
	UiTheme.style_button(
		button,
		"custom",
		{
			"fill": fill_color,
			"border": border_color,
			"font": COLOR_DESKTOP_TEXT,
			"hover": fill_color.lightened(0.08),
			"pressed": fill_color.darkened(0.08),
			"disabled": fill_color,
			"disabled_font": COLOR_DESKTOP_TEXT,
			"radius": 4,
			"border_width": 1,
			"size_role": "caption"
		}
	)


func _style_light_item_list(item_list: ItemList) -> void:
	UiTheme.style_item_list(item_list, "light")


func _style_item_list(item_list: ItemList, panel_radius: int = 8, cursor_radius: int = 6) -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_STOCKBOT_BASE
	panel_style.border_color = COLOR_STOCKBOT_EDGE
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = panel_radius
	panel_style.corner_radius_top_right = panel_radius
	panel_style.corner_radius_bottom_right = panel_radius
	panel_style.corner_radius_bottom_left = panel_radius

	var cursor_style: StyleBoxFlat = StyleBoxFlat.new()
	cursor_style.bg_color = COLOR_STOCKBOT_BLUE_TINT
	cursor_style.border_color = COLOR_STOCKBOT_BLUE
	cursor_style.set_border_width_all(1)
	cursor_style.corner_radius_top_left = cursor_radius
	cursor_style.corner_radius_top_right = cursor_radius
	cursor_style.corner_radius_bottom_right = cursor_radius
	cursor_style.corner_radius_bottom_left = cursor_radius

	item_list.add_theme_stylebox_override("panel", panel_style)
	item_list.add_theme_stylebox_override("panel_focus", panel_style)
	item_list.add_theme_stylebox_override("cursor", cursor_style)
	item_list.add_theme_stylebox_override("cursor_unfocused", cursor_style)
	item_list.add_theme_color_override("font_color", COLOR_STOCKBOT_TEXT)
	item_list.add_theme_color_override("font_selected_color", COLOR_STOCKBOT_TEXT)
	item_list.add_theme_color_override("guide_color", Color(0, 0, 0, 0))
	item_list.add_theme_constant_override("h_separation", 6)
	item_list.add_theme_constant_override("v_separation", 6)


func _format_currency(value: float) -> String:
	return UIFormatter.format_currency(value)


func _format_signed_currency(value: float) -> String:
	return "%sRp%s" % [
		"+" if value >= 0.0 else "-",
		_format_decimal(absf(value), 2, true)
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
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_financial_block(financials)
	stock_controller._sync_root_refs()
	return result
func _format_financial_history_summary(financial_history: Array, financials: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_financial_history_summary(financial_history, financials)
	stock_controller._sync_root_refs()
	return result
func _refresh_financial_history_header() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_financial_history_header()
	stock_controller._sync_root_refs()
func _refresh_financial_history_table(financial_history: Array, _financials: Dictionary, empty_text: String = "") -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_financial_history_table(financial_history, _financials, empty_text)
	stock_controller._sync_root_refs()
func _build_financial_history_row(history_entry: Dictionary) -> Control:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Control = stock_controller._build_financial_history_row(history_entry)
	stock_controller._sync_root_refs()
	return result
func _refresh_broker_header() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_broker_header()
	stock_controller._sync_root_refs()
func _refresh_broker_table(broker_flow: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_broker_table(broker_flow)
	stock_controller._sync_root_refs()
func _format_broker_range_summary(broker_flow: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_broker_range_summary(broker_flow)
	stock_controller._sync_root_refs()
	return result
func _format_broker_range_date_text(start_date_value: Variant, end_date_value: Variant) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_broker_range_date_text(start_date_value, end_date_value)
	stock_controller._sync_root_refs()
	return result
func _format_short_broker_date(date_value: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_short_broker_date(date_value)
	stock_controller._sync_root_refs()
	return result
func _populate_corporate_action_filter() -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._populate_corporate_action_filter()
	stock_controller._sync_root_refs()
func _refresh_corporate_action_timeline(timeline_snapshot: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_corporate_action_timeline(timeline_snapshot)
	stock_controller._sync_root_refs()
func _corporate_action_timeline_summary(all_rows: Array, visible_rows: Array) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._corporate_action_timeline_summary(all_rows, visible_rows)
	stock_controller._sync_root_refs()
	return result
func _build_corporate_action_timeline_card(row: Dictionary) -> Control:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Control = stock_controller._build_corporate_action_timeline_card(row)
	stock_controller._sync_root_refs()
	return result
func _corporate_action_row_tooltip(row: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._corporate_action_row_tooltip(row)
	stock_controller._sync_root_refs()
	return result
func _corporate_action_row_action_text(row: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._corporate_action_row_action_text(row)
	stock_controller._sync_root_refs()
	return result
func _corporate_action_row_is_soon(row: Dictionary) -> bool:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: bool = stock_controller._corporate_action_row_is_soon(row)
	stock_controller._sync_root_refs()
	return result
func _corporate_action_row_soon_label(row: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._corporate_action_row_soon_label(row)
	stock_controller._sync_root_refs()
	return result
func _corporate_action_next_milestone(row: Dictionary) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._corporate_action_next_milestone(row)
	stock_controller._sync_root_refs()
	return result
func _on_corporate_action_timeline_card_gui_input(event: InputEvent, row: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_corporate_action_timeline_card_gui_input(event, row)
	stock_controller._sync_root_refs()
func _show_corporate_action_capture_menu(row: Dictionary, menu_position: Vector2) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._show_corporate_action_capture_menu(row, menu_position)
	stock_controller._sync_root_refs()
func _on_corporate_action_capture_menu_id_pressed(id: int) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_corporate_action_capture_menu_id_pressed(id)
	stock_controller._sync_root_refs()
func _capture_corporate_action_row(row: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._capture_corporate_action_row(row)
	stock_controller._sync_root_refs()
func _corporate_action_capture_payload(row: Dictionary) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._corporate_action_capture_payload(row)
	stock_controller._sync_root_refs()
	return result
func _corporate_action_capture_value(row: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._corporate_action_capture_value(row)
	stock_controller._sync_root_refs()
	return result
func _corporate_action_capture_detail(row: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._corporate_action_capture_detail(row)
	stock_controller._sync_root_refs()
	return result
func _corporate_action_dividend_explanation(row: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._corporate_action_dividend_explanation(row)
	stock_controller._sync_root_refs()
	return result
func _build_corporate_action_field_cell(field: Dictionary) -> Control:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Control = stock_controller._build_corporate_action_field_cell(field)
	stock_controller._sync_root_refs()
	return result
func _corporate_action_field_value(field: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._corporate_action_field_value(field)
	stock_controller._sync_root_refs()
	return result
func _format_corporate_action_date(date_info: Variant) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_corporate_action_date(date_info)
	stock_controller._sync_root_refs()
	return result
func _on_corporate_action_filter_selected(index: int) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_corporate_action_filter_selected(index)
	stock_controller._sync_root_refs()
func _on_broker_net_toggled(toggled_on: bool) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_broker_net_toggled(toggled_on)
	stock_controller._sync_root_refs()
func _add_broker_table_side(
	row: HBoxContainer,
	code_text: String,
	value_text: String,
	lot_text: String,
	average_text: String,
	font_color: Color
) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._add_broker_table_side(row, code_text, value_text, lot_text, average_text, font_color)
	stock_controller._sync_root_refs()
func _build_broker_table_cell(
	text: String,
	minimum_width: float,
	font_color: Color,
	alignment: HorizontalAlignment,
	stretch_ratio: float
) -> Label:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Label = stock_controller._build_broker_table_cell(text, minimum_width, font_color, alignment, stretch_ratio)
	stock_controller._sync_root_refs()
	return result
func _build_broker_side_divider() -> VSeparator:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: VSeparator = stock_controller._build_broker_side_divider()
	stock_controller._sync_root_refs()
	return result
func _build_broker_table_row(buy_row: Dictionary, sell_row: Dictionary) -> Control:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Control = stock_controller._build_broker_table_row(buy_row, sell_row)
	stock_controller._sync_root_refs()
	return result
func _build_broker_table_side_control(broker_row: Dictionary, side: String) -> HBoxContainer:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: HBoxContainer = stock_controller._build_broker_table_side_control(broker_row, side)
	stock_controller._sync_root_refs()
	return result
func _on_broker_table_side_gui_input(event: InputEvent, broker_row: Dictionary, side: String) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_broker_table_side_gui_input(event, broker_row, side)
	stock_controller._sync_root_refs()
func _prepare_broker_capture(broker_row: Dictionary, side: String) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._prepare_broker_capture(broker_row, side)
	stock_controller._sync_root_refs()
func _show_broker_capture_menu(menu_position: Vector2) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._show_broker_capture_menu(menu_position)
	stock_controller._sync_root_refs()
func _on_broker_capture_menu_id_pressed(id: int) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_broker_capture_menu_id_pressed(id)
	stock_controller._sync_root_refs()
func _sync_financial_statement_selection(company_id: String, financial_statement_snapshot: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._sync_financial_statement_selection(company_id, financial_statement_snapshot)
	stock_controller._sync_root_refs()
func _shift_financial_statement_selection(offset: int) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._shift_financial_statement_selection(offset)
	stock_controller._sync_root_refs()
func _selected_statement_period(financial_statement_snapshot: Dictionary) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._selected_statement_period(financial_statement_snapshot)
	stock_controller._sync_root_refs()
	return result
func _refresh_statement_navigation(financial_statement_snapshot: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_statement_navigation(financial_statement_snapshot)
	stock_controller._sync_root_refs()
func _refresh_statement_sections(financial_statement_snapshot: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_statement_sections(financial_statement_snapshot)
	stock_controller._sync_root_refs()
func _refresh_statement_section(
	rows_vbox: VBoxContainer,
	empty_label: Label,
	lines: Array,
	section_id: String = "",
	section_label: String = "",
	period_label: String = ""
) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._refresh_statement_section(rows_vbox, empty_label, lines, section_id, section_label, period_label)
	stock_controller._sync_root_refs()
func _build_statement_row(
	line_item: Dictionary,
	section_id: String = "",
	section_label: String = "",
	period_label: String = ""
) -> Control:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Control = stock_controller._build_statement_row(line_item, section_id, section_label, period_label)
	stock_controller._sync_root_refs()
	return result
func _financial_statement_capture_payload(
	line_item: Dictionary,
	section_id: String,
	section_label: String,
	period_label: String
) -> Dictionary:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: Dictionary = stock_controller._financial_statement_capture_payload(line_item, section_id, section_label, period_label)
	stock_controller._sync_root_refs()
	return result
func _on_financial_statement_row_gui_input(event: InputEvent, capture_payload: Dictionary) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_financial_statement_row_gui_input(event, capture_payload)
	stock_controller._sync_root_refs()
func _show_financial_statement_capture_menu(menu_position: Vector2) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._show_financial_statement_capture_menu(menu_position)
	stock_controller._sync_root_refs()
func _on_financial_statement_capture_menu_id_pressed(id: int) -> void:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	stock_controller._on_financial_statement_capture_menu_id_pressed(id)
	stock_controller._sync_root_refs()
func _format_statement_value(line_item: Dictionary) -> String:
	_ensure_stock_controller()
	stock_controller._sync_dynamic_refs_from_root()
	stock_controller._sync_state_from_root()
	var result: String = stock_controller._format_statement_value(line_item)
	stock_controller._sync_root_refs()
	return result
func _format_compact_currency(value: float) -> String:
	return UIFormatter.format_compact_currency(value)


func _format_signed_compact_currency(value: float) -> String:
	if is_zero_approx(value):
		return "Rp0"
	return "%s%s" % ["+" if value > 0.0 else "", _format_compact_currency(value)]


func _format_compact_lots(value: float) -> String:
	var absolute_value: float = absf(value)
	if absolute_value >= 1000000.0:
		return "%sM" % String.num(value / 1000000.0, 1)
	if absolute_value >= 1000.0:
		return "%sK" % String.num(value / 1000.0, 1)
	return String.num(value, 1)


func _format_signed_compact_lots(value: float) -> String:
	if is_zero_approx(value):
		return "0.0"
	return "%s%s" % ["+" if value > 0.0 else "", _format_compact_lots(value)]


func _format_grouped_integer(value: int) -> String:
	return UIFormatter.format_grouped_integer(value)


func _format_percent_value(value: float) -> String:
	return "%s%%" % String.num(value, 1)


func _format_signed_percent_value(value: float) -> String:
	return "%+.1f%%" % [value]


func _format_multiple(value: float) -> String:
	return "%sx" % String.num(value, 2)


func _format_last_price(value: float) -> String:
	return "%sRp%s" % [
		"-" if value < 0.0 else "",
		_format_decimal(absf(value), 0, true)
	]


func _format_signed_decimal(value: float, decimal_places: int = 2, use_grouping: bool = true) -> String:
	return "%s%s" % [
		"+" if value >= 0.0 else "-",
		_format_decimal(absf(value), decimal_places, use_grouping)
	]


func _format_decimal(value: float, decimal_places: int = 2, use_grouping: bool = true) -> String:
	return UIFormatter.format_decimal(value, decimal_places, use_grouping)


func _join_or_default(values: Array, default_text: String) -> String:
	if values.is_empty():
		return default_text

	var parts: Array = []
	for value in values:
		parts.append(str(value))
	return ", ".join(parts)
