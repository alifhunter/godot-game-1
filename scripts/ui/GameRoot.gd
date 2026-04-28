extends Control

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
const NETWORK_FOLLOWUP_ACTIONS := {
	0: "thank",
	1: "ask_why",
	2: "challenge"
}
const STOCK_APP_FONT_SIZE := 12
const DEFAULT_APP_FONT_SIZE := 12
const APP_FONT_CANDIDATE_PATHS := [
	"res://assets/fonts/app_font.ttf",
	"res://assets/fonts/app_font.otf",
	"res://assets/fonts/OpenSans-Regular.ttf"
]
const TRADE_LEFT_SECTION_RATIO := 1.0
const TRADE_CENTER_SECTION_RATIO := 2.0
const TRADE_RIGHT_SECTION_RATIO := 1.0
const ORDER_TICKET_TOGGLE_WIDTH := 28.0
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
	"exit": {
		"shortcut": "res://assets/ui/desktop/exit_shortcut.svg",
		"nav": "res://assets/ui/desktop/exit_nav.svg"
	},
	"date": "res://assets/ui/desktop/date_icon.svg",
	"cash": "res://assets/ui/desktop/cash_icon.svg",
	"advance": "res://assets/ui/desktop/advance_icon.svg"
}
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
const COLOR_ACADEMY_CREAM := Color(0.988235, 0.960784, 0.854902, 1)
const COLOR_ACADEMY_PANEL := Color(0.972549, 0.94902, 0.847059, 1)
const COLOR_ACADEMY_RAIL := Color(0.917647, 0.878431, 0.721569, 1)
const COLOR_ACADEMY_BROWN := Color(0.509804, 0.231373, 0.0941176, 1)
const COLOR_ACADEMY_BORDER := Color(0.52549, 0.396078, 0.160784, 1)
const COLOR_ACADEMY_GREEN := Color(0.811765, 0.886275, 0.529412, 1)
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
const DESKTOP_WINDOW_TITLE_BAR_HEIGHT := 40.0
const DESKTOP_WINDOW_MIN_WIDTH := 360.0
const DESKTOP_WINDOW_MIN_HEIGHT := 260.0
const SOCIAL_WINDOW_MAX_WIDTH := 460.0
const SOCIAL_WINDOW_MAX_HEIGHT := 780.0
const SOCIAL_WINDOW_MIN_HEIGHT := 520.0
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
const LIFE_WIDGET_SCRIPT = preload("res://scripts/ui/widgets/LifeWidget.gd")

var selected_company_id: String = ""
var displayed_company_ids: Array = []
var watchlist_picker_company_ids: Array = []
var tutorial_dialog: AcceptDialog = null
var watchlist_picker_dialog: ConfirmationDialog = null
var watchlist_picker_list: ItemList = null
var upgrade_purchase_dialog: ConfirmationDialog = null
var upgrade_purchase_body_label: Label = null
var pending_upgrade_track_id: String = ""
var console_overlay: Control = null
var console_panel: PanelContainer = null
var console_title_label: Label = null
var console_hint_label: Label = null
var console_input: LineEdit = null
var console_status_label: Label = null
var selected_lots: int = 1
var active_section_id: String = "dashboard"
var active_app_id: String = APP_ID_DESKTOP
var status_message: String = "Ready."
var selected_financial_statement_index: int = -1
var selected_financial_statement_company_id: String = ""
var selected_key_stats_metric: String = KEY_STATS_METRIC_NET_INCOME
var current_trade_snapshot: Dictionary = {}
var cached_company_rows: Array = []
var cached_company_row_lookup: Dictionary = {}
var has_cached_company_rows: bool = false
var current_news_snapshot: Dictionary = {}
var current_social_snapshot: Dictionary = {}
var current_network_snapshot: Dictionary = {}
var current_academy_snapshot: Dictionary = {}
var current_corporate_meeting_id: String = ""
var debug_generator_buttons: Dictionary = {}
var debug_start_rupslb_button: Button = null
var debug_start_rupslb_status_label: Label = null
var cached_app_font: Font = null
var has_checked_app_font: bool = false
var cached_dashboard_title_font: Font = null
var has_checked_dashboard_title_font: bool = false
var suppress_next_portfolio_refresh: bool = false
var pending_watchlist_selected_company_id: String = ""
var pending_watchlist_target_tab: int = -1
var suppress_stock_list_tab_refresh: bool = false
var selected_dashboard_sector_id: String = ""
var active_order_side: String = "buy"
var order_ticket_collapsed: bool = false
var broker_net_mode: bool = false
var selected_news_outlet_id: String = ""
var selected_news_archive_year: int = 0
var selected_news_archive_month: int = 0
var selected_news_article_id: String = ""
var selected_network_contact_id: String = ""
var selected_network_journal_id: String = ""
var selected_network_journal_filter: String = "all"
var selected_academy_category_id: String = "technical"
var selected_academy_section_id: String = "intro"
var academy_quiz_option_buttons: Dictionary = {}
var expanded_social_thread_ids: Dictionary = {}
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
var deferred_open_app_refresh_queue: Array = []
var deferred_open_app_refresh_scheduled: bool = false
var advance_day_post_recap_save_flush_scheduled: bool = false
var pending_daily_recap_snapshot: Dictionary = {}
var daily_recap_dialog: Control = null
var daily_recap_body_label: Label = null
var daily_recap_continue_button: Button = null
var advance_day_button_tween: Tween = null
var daily_recap_tween: Tween = null
var desktop_window_open_tweens: Dictionary = {}
var desktop_window_focus_tweens: Dictionary = {}
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
var news_masthead_logo_frame: PanelContainer = null
var news_masthead_date_label: Label = null
var news_article_cards_scroll: ScrollContainer = null
var news_article_cards: VBoxContainer = null
var news_detail_hero_frame: PanelContainer = null
var news_detail_byline_label: Label = null
var news_detail_chips_label: Label = null
var news_detail_action_row: HBoxContainer = null
var news_open_meeting_button: Button = null
@onready var social_window: MarginContainer = $SocialWindow
@onready var social_window_body: PanelContainer = $SocialWindow/SocialWindowBody
@onready var social_title_label: Label = $SocialWindow/SocialWindowBody/SocialWindowMargin/SocialWindowVBox/SocialHeaderRow/SocialTitleLabel
@onready var social_access_status_label: Label = $SocialWindow/SocialWindowBody/SocialWindowMargin/SocialWindowVBox/SocialHeaderRow/SocialAccessStatusLabel
@onready var social_feed_summary_label: Label = $SocialWindow/SocialWindowBody/SocialWindowMargin/SocialWindowVBox/SocialFeedSummaryLabel
@onready var social_feed_scroll: ScrollContainer = $SocialWindow/SocialWindowBody/SocialWindowMargin/SocialWindowVBox/SocialFeedScroll
@onready var social_feed_cards: VBoxContainer = $SocialWindow/SocialWindowBody/SocialWindowMargin/SocialWindowVBox/SocialFeedScroll/SocialFeedCards
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


func _ready() -> void:
	_ensure_tutorial_dialog()
	_ensure_watchlist_picker_dialog()
	_ensure_upgrade_purchase_dialog()
	_ensure_daily_recap_dialog()
	_ensure_dashboard_calendar_event_popup()
	_ensure_dashboard_index_recap_ui()
	_ensure_dashboard_sector_ui()
	_ensure_console_overlay()
	_ensure_academy_ui()
	_ensure_thesis_ui()
	_ensure_life_ui()
	_ensure_corporate_action_ui()
	_ensure_news_newspaper_ui()
	_ensure_figma_desktop_ui()
	_ensure_desktop_window_layer()
	_initialize_desktop_app_windows()
	_initialize_desktop_badge_seen_defaults()
	_ensure_key_stats_dashboard_ui()
	_remove_financial_and_broker_helper_text()
	_style_dashboard_calendar_grid()
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
	network_app_button.pressed.connect(_on_network_app_pressed)
	if academy_app_button != null:
		academy_app_button.pressed.connect(_on_academy_app_pressed)
	if thesis_app_button != null:
		thesis_app_button.pressed.connect(_on_thesis_app_pressed)
	if life_app_button != null:
		life_app_button.pressed.connect(_on_life_app_pressed)
	upgrades_app_button.pressed.connect(_on_upgrades_app_pressed)
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
	remove_watchlist_button.pressed.connect(_on_remove_watchlist_pressed)
	all_stocks_search_input.text_changed.connect(_on_all_stock_search_text_changed)
	financials_previous_button.pressed.connect(_on_financials_previous_pressed)
	financials_next_button.pressed.connect(_on_financials_next_pressed)
	broker_net_toggle.toggled.connect(_on_broker_net_toggled)
	company_list.item_selected.connect(_on_company_selected)
	news_article_list.item_selected.connect(_on_news_article_selected)
	news_meet_contact_button.pressed.connect(_on_news_meet_contact_pressed)
	news_archive_year_option.item_selected.connect(_on_news_archive_year_selected)
	news_archive_month_option.item_selected.connect(_on_news_archive_month_selected)
	network_contacts_list.item_selected.connect(_on_network_contact_selected)
	network_requests_list.item_selected.connect(_on_network_request_selected)
	if network_journal_list != null:
		network_journal_list.item_selected.connect(_on_network_journal_selected)
	if academy_section_list != null:
		academy_section_list.item_selected.connect(_on_academy_section_selected)
	if academy_mark_read_button != null:
		academy_mark_read_button.pressed.connect(_on_academy_mark_read_pressed)
	if academy_next_button != null:
		academy_next_button.pressed.connect(_on_academy_next_pressed)
	if academy_glossary_search_input != null:
		academy_glossary_search_input.text_changed.connect(_on_academy_glossary_search_changed)
	network_meet_button.pressed.connect(_on_network_meet_pressed)
	network_tip_button.pressed.connect(_on_network_tip_pressed)
	network_request_button.pressed.connect(_on_network_request_pressed)
	network_referral_button.pressed.connect(_on_network_referral_pressed)
	profile_meet_contact_button.pressed.connect(_on_profile_meet_contact_pressed)
	lot_spin_box.value_changed.connect(_on_lot_size_changed)
	order_ticket_toggle_button.pressed.connect(_on_order_ticket_toggle_pressed)
	buy_button.pressed.connect(_on_buy_side_pressed)
	sell_button.pressed.connect(_on_sell_side_pressed)
	submit_order_button.pressed.connect(_on_submit_order_pressed)
	get_viewport().size_changed.connect(_update_responsive_layout)
	GameManager.portfolio_changed.connect(_on_portfolio_changed)
	GameManager.watchlist_changed.connect(_on_watchlist_changed)
	GameManager.network_changed.connect(_on_network_changed)
	GameManager.upgrades_changed.connect(_on_upgrades_changed)
	GameManager.daily_actions_changed.connect(_refresh_daily_action_displays)
	GameManager.academy_changed.connect(_refresh_academy)
	GameManager.price_formed.connect(_on_day_progressed)
	GameManager.summary_ready.connect(_on_summary_ready)
	GameManager.company_detail_ready.connect(_on_company_detail_ready)
	stock_app_button.tooltip_text = "Open STOCKBOT."
	news_app_button.tooltip_text = "Open the event-driven news desk."
	social_app_button.tooltip_text = "Open the mobile-style social feed."
	network_app_button.tooltip_text = "Open the relationship network."
	if academy_app_button != null:
		academy_app_button.tooltip_text = "Open Academy lessons."
	if thesis_app_button != null:
		thesis_app_button.tooltip_text = "Open Thesis Board."
	if life_app_button != null:
		life_app_button.tooltip_text = "Open Life planning."
	upgrades_app_button.tooltip_text = "Open the upgrades shop."
	exit_app_button.tooltip_text = "Return to the main menu."
	taskbar_home_button.tooltip_text = "Return to the desktop."
	taskbar_stock_button.tooltip_text = "Open STOCKBOT."
	taskbar_news_button.tooltip_text = "Open the event-driven news desk."
	financials_previous_button.tooltip_text = "View the previous quarter."
	financials_next_button.tooltip_text = "View the next quarter."
	broker_net_toggle.tooltip_text = "Toggle net broker flow so each broker appears on only one side."
	buy_button.tooltip_text = "Switch the ticket to buy mode."
	sell_button.tooltip_text = "Switch the ticket to sell mode."
	order_ticket_toggle_button.tooltip_text = "Hide the order ticket."
	submit_order_button.tooltip_text = "Submit the active order."
	news_meet_contact_button.tooltip_text = "Meet the contact connected to this story."
	profile_meet_contact_button.tooltip_text = "Meet a contact connected to this company."
	network_meet_button.tooltip_text = "Meet the selected discovered contact."
	network_tip_button.tooltip_text = "Ask the selected contact for a market read."
	network_request_button.tooltip_text = "Accept a position request from the selected contact."
	network_referral_button.tooltip_text = "Ask a trusted floater to introduce a company insider."
	_build_debug_generator_controls()
	call_deferred("_update_responsive_layout")
	_set_active_section(active_section_id)
	_set_active_app(APP_ID_DESKTOP)
	_refresh_all()
	_apply_global_font_size_overrides()
	call_deferred("_start_background_company_detail_hydration")
	call_deferred("_show_tutorial_if_needed")


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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event
		if key_event.ctrl_pressed and key_event.keycode == KEY_L:
			_toggle_debug_overlay()
			get_viewport().set_input_as_handled()
			return
		if console_overlay != null and console_overlay.visible and key_event.keycode == KEY_ESCAPE:
			_hide_console_overlay()
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
	_update_desktop_figma_layout()
	_update_key_stats_dashboard_layout()
	_apply_window_layout()


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


func _ensure_key_stats_dashboard_ui() -> void:
	if key_stats_dashboard_grid != null:
		return
	if key_stats_panel == null:
		return
	var key_stats_vbox: VBoxContainer = key_stats_panel.get_node_or_null("KeyStatsMargin/KeyStatsVBox") as VBoxContainer
	if key_stats_vbox == null:
		return
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
	title_label.add_theme_color_override("font_color", COLOR_TEXT)
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
		button.custom_minimum_size = Vector2(72, 30)
		button.pressed.connect(_on_key_stats_metric_button_pressed.bind(str(metric.get("id", ""))))
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
			_style_panel(card, COLOR_PANEL_BLUE_ALT, 0)
		_style_key_stats_card_tree(child)


func _update_key_stats_dashboard_layout() -> void:
	if key_stats_dashboard_grid == null:
		return
	var content_width: float = work_area_panel.get_rect().size.x
	if content_width <= 0.0:
		content_width = get_viewport_rect().size.x - 520.0
	if content_width >= 940.0:
		key_stats_dashboard_grid.columns = 3
	elif content_width >= 620.0:
		key_stats_dashboard_grid.columns = 2
	else:
		key_stats_dashboard_grid.columns = 1


func _on_key_stats_metric_button_pressed(metric_id: String) -> void:
	if metric_id.is_empty() or selected_key_stats_metric == metric_id:
		return
	selected_key_stats_metric = metric_id
	_refresh_key_stats_metric_button_styles()
	_refresh_key_stats_dashboard(current_trade_snapshot)


func _refresh_key_stats_metric_button_styles() -> void:
	for metric_id_value in key_stats_metric_buttons.keys():
		var metric_id: String = str(metric_id_value)
		var button: Button = key_stats_metric_buttons.get(metric_id, null) as Button
		if button == null:
			continue
		if metric_id == selected_key_stats_metric:
			_style_button(button, COLOR_NAV_ACTIVE_FILL, COLOR_ACCENT, COLOR_TEXT, 0)
		else:
			_style_button(button, Color(0.0823529, 0.117647, 0.156863, 0.98), COLOR_BORDER, COLOR_MUTED, 0)


func _refresh_key_stats_dashboard(snapshot: Dictionary) -> void:
	if key_stats_dashboard_grid == null:
		return

	if snapshot.is_empty():
		var empty_rows: Array = [{"label": "Status", "value": "Pick a stock"}]
		_refresh_key_stats_rows("current_valuation", empty_rows)
		_refresh_key_stats_rows("per_share", empty_rows)
		_refresh_key_stats_rows("profitability", empty_rows)
		_refresh_key_stats_rows("income_statement", empty_rows)
		_refresh_key_stats_rows("balance_sheet", empty_rows)
		_refresh_key_stats_rows("cash_flow", empty_rows)
		_refresh_key_stats_metric_table({}, {})
		return

	var context: Dictionary = _build_key_stats_context(snapshot)
	_refresh_key_stats_rows("current_valuation", _build_key_stats_valuation_rows(context))
	_refresh_key_stats_rows("per_share", _build_key_stats_per_share_rows(context))
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
			row.get("color", COLOR_TEXT)
		))


func _clear_key_stats_container(container: VBoxContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _build_key_stats_value_row(label_text: String, value_text: String, value_color: Color = COLOR_TEXT) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", COLOR_MUTED)
	_apply_font_override_to_control(label, DEFAULT_APP_FONT_SIZE, _get_app_font())
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.custom_minimum_size = Vector2(KEY_STATS_ROW_VALUE_WIDTH, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.clip_text = true
	value.add_theme_color_override("font_color", value_color)
	_apply_font_override_to_control(value, DEFAULT_APP_FONT_SIZE, _get_app_font())
	row.add_child(value)
	return row


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

	return {
		"financials": financials,
		"financial_history": financial_history,
		"financial_statement_snapshot": financial_statement_snapshot,
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
	key_stats_metric_table_rows.add_child(_build_key_stats_metric_row("Period", _key_stats_year_labels(years), COLOR_WARNING, COLOR_WARNING))
	for quarter in range(1, 5):
		key_stats_metric_table_rows.add_child(_build_key_stats_metric_row(
			"Q%d" % quarter,
			_key_stats_metric_values_for_quarter(financial_statement_snapshot, selected_key_stats_metric, years, quarter)
		))
	key_stats_metric_table_rows.add_child(_build_key_stats_metric_row(
		"Annualised",
		_key_stats_metric_values_for_annual(financial_statement_snapshot, financial_history, selected_key_stats_metric, years)
	))
	key_stats_metric_table_rows.add_child(_build_key_stats_metric_row(
		"TTM",
		_key_stats_metric_values_for_ttm(financial_statement_snapshot, financial_history, selected_key_stats_metric, years)
	))

	key_stats_metric_footer_rows.add_child(_build_key_stats_value_row("Market Cap", _format_compact_currency(float(context.get("market_cap", 0.0)))))
	key_stats_metric_footer_rows.add_child(_build_key_stats_value_row("Enterprise Value", _format_compact_currency(float(context.get("enterprise_value", 0.0)))))
	key_stats_metric_footer_rows.add_child(_build_key_stats_value_row("Current Share Outstanding", _format_key_stats_compact_number(float(context.get("shares_outstanding", 0.0)))))
	var financials: Dictionary = context.get("financials", {})
	key_stats_metric_footer_rows.add_child(_build_key_stats_value_row("Free Float", _format_key_stats_percent_value(float(financials.get("free_float_pct", 0.0)), financials.has("free_float_pct"))))


func _build_key_stats_metric_row(
	label_text: String,
	values: Array,
	label_color: Color = COLOR_MUTED,
	value_color: Color = COLOR_TEXT
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

	for value_text in values:
		var value := Label.new()
		value.text = str(value_text)
		value.custom_minimum_size = Vector2(KEY_STATS_METRIC_VALUE_WIDTH, 0)
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value.clip_text = true
		value.add_theme_color_override("font_color", value_color)
		_apply_font_override_to_control(value, DEFAULT_APP_FONT_SIZE, _get_app_font())
		row.add_child(value)
	return row


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
	var total: float = 0.0
	var valid_count: int = 0
	for quarter in range(1, 5):
		var statement: Dictionary = _key_stats_statement_for_year_quarter(financial_statement_snapshot, year, quarter)
		var result: Dictionary = _key_stats_metric_result_from_statement(statement, metric_id)
		if bool(result.get("valid", false)):
			total += float(result.get("value", 0.0))
			valid_count += 1
	if valid_count > 0:
		return {"valid": true, "value": total}
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
	order_ticket_toggle_button.text = "<" if order_ticket_collapsed else ">"
	order_ticket_toggle_button.tooltip_text = "Show the order ticket." if order_ticket_collapsed else "Hide the order ticket."


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
		_refresh_debug_overlay()
		_log_perf_phase(log_phase_details, "_refresh_all:debug_overlay", phase_started_at_usec)
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
	_refresh_dashboard()
	_log_perf_phase(log_phase_details, "_refresh_all:dashboard", phase_started_at_usec)
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
	_refresh_debug_overlay()
	_log_perf_phase(log_phase_details, "_refresh_all:debug_overlay", phase_started_at_usec)
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
		not pending_daily_recap_snapshot.is_empty() and
		daily_recap_dialog != null and
		daily_recap_body_label != null
	)
	if advance_day_processing or waiting_for_recap:
		_schedule_deferred_open_app_refresh()
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


func _open_desktop_app_refresh_order() -> Array:
	var ordered: Array = []
	var top_app_id: String = _top_visible_desktop_window_id()
	if not top_app_id.is_empty():
		ordered.append(top_app_id)
	if active_app_id != APP_ID_DESKTOP and not ordered.has(active_app_id) and _is_desktop_app_window_open(active_app_id):
		ordered.append(active_app_id)
	for app_id in [APP_ID_STOCK, APP_ID_NEWS, APP_ID_SOCIAL, APP_ID_NETWORK, APP_ID_ACADEMY, APP_ID_THESIS, APP_ID_LIFE, APP_ID_UPGRADES]:
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
	if debug_overlay.visible:
		_refresh_debug_overlay()
	_start_background_company_detail_hydration()
	_log_perf_elapsed("_on_portfolio_changed", started_at_usec)


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
	_refresh_all_stock_watchlist_button_states(watchlist_lookup)
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


func _on_network_changed() -> void:
	if advance_day_processing:
		_queue_deferred_open_app_refresh()
		return
	_refresh_network()
	if _is_desktop_app_window_open(APP_ID_THESIS):
		_refresh_thesis()


func _apply_global_font_size_overrides() -> void:
	_apply_font_size_override_to_tree(self, DEFAULT_APP_FONT_SIZE, _get_app_font())
	_style_figma_desktop_ui()
	_style_dashboard_index_recap_ui()
	_style_dashboard_section_titles()


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


func _get_company_rows_cached() -> Array:
	if not has_cached_company_rows:
		cached_company_rows = GameManager.get_company_rows()
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
	top_cash_label.text = "CASH AVAILABLE %s" % _format_currency(float(portfolio.get("cash", 0.0)))
	objective_label.text = ""
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
		desktop_hint_label.text = "Desktop icons launch apps. STOCKBOT trades, News reads the event tape, Twooter surfaces chatter, Network manages contacts, Academy teaches chart reading, and Upgrades improves the desk."
		taskbar_status_label.text = "No active run loaded."
		taskbar_clock_label.text = "MENU"
		_refresh_figma_desktop_status()
		_refresh_desktop_notification_badges()
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
	desktop_hint_label.text = "STOCKBOT is live. News renders event-driven intel feeds, Twooter shows tiered social chatter, Network tracks contacts, Academy teaches technical routines, and Upgrades spends cash on desk improvements."
	taskbar_status_label.text = _build_taskbar_status_text(focus_snapshot)
	taskbar_clock_label.text = "DAY %d  |  %s" % [
		max(RunState.day_index + 1, 1),
		GameManager.format_trade_date(current_trade_date)
	]
	_refresh_figma_desktop_status()
	_refresh_desktop_notification_badges()


func _refresh_news() -> void:
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
		_show_news_article({})
		_apply_font_overrides_to_subtree(news_outlet_buttons)
		return

	current_news_snapshot = GameManager.get_news_snapshot()
	var outlets: Array = current_news_snapshot.get("outlets", [])
	if selected_news_outlet_id.is_empty() or not _news_outlet_exists(outlets, selected_news_outlet_id):
		selected_news_outlet_id = _default_news_outlet_id(outlets)
		selected_news_archive_year = 0
		selected_news_archive_month = 0
		selected_news_article_id = ""

	var current_trade_date: Dictionary = GameManager.get_current_trade_date()
	if news_masthead_date_label != null:
		news_masthead_date_label.text = GameManager.format_trade_date(current_trade_date)
	news_intel_status_label.text = ""
	_rebuild_news_outlet_buttons(outlets)
	_refresh_news_archive_filters()
	_refresh_news_article_list()
	_apply_font_overrides_to_subtree(news_outlet_buttons)


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
	var feed: Dictionary = current_news_snapshot.get("feeds", {}).get(selected_news_outlet_id, {})
	news_feed_summary_label.text = str(feed.get("tagline", ""))

	for article_value in articles:
		var article: Dictionary = article_value
		var line: String = _build_news_article_list_line(article)
		news_article_list.add_item(line)
		var item_index: int = news_article_list.item_count - 1
		news_article_list.set_item_tooltip(item_index, "")
		news_article_list.set_item_metadata(item_index, article.duplicate(true))
	_rebuild_news_article_cards(articles)

	var selected_index: int = -1
	for article_index in range(articles.size()):
		if str(articles[article_index].get("id", "")) == selected_news_article_id:
			selected_index = article_index
			break

	if selected_index == -1 and not articles.is_empty():
		selected_index = 0
		selected_news_article_id = str(articles[0].get("id", ""))

	_rebuild_news_article_cards(articles)
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
		_apply_font_overrides_to_subtree(social_feed_cards)
		return

	current_social_snapshot = GameManager.get_twooter_snapshot()
	var posts: Array = current_social_snapshot.get("posts", [])
	social_access_status_label.text = "%s access active" % str(current_social_snapshot.get("tier_label", "Tier 1"))
	social_feed_summary_label.text = "%d post(s)  |  Mobile feed view\nHigher access tiers unlock more credible or more market-moving accounts." % posts.size()
	_rebuild_social_feed_cards(posts)
	_apply_font_overrides_to_subtree(social_feed_cards)


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
	network_summary_label.text = "%d / %d contacts met  |  AP %d/%d  |  Contacts are discovered through News and company Profile pages." % [
		int(current_network_snapshot.get("met_count", 0)),
		int(current_network_snapshot.get("contact_cap", 2)),
		int(action_snapshot.get("remaining", 0)),
		int(action_snapshot.get("limit", 10))
	]
	_rebuild_network_contact_list()
	_rebuild_network_request_list()
	_rebuild_network_journal_list()
	_log_perf_elapsed("_refresh_network", started_at_usec)


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
			"app_id": "exit",
			"button": exit_app_button,
			"label": exit_app_label,
			"text": "EXIT"
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
	var viewport_size: Vector2 = get_viewport_rect().size
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
	var viewport_width: float = get_viewport_rect().size.x
	if viewport_width >= 1500.0:
		desktop_shortcut_grid.columns = 7
	elif viewport_width >= 1040.0:
		desktop_shortcut_grid.columns = 4
	elif viewport_width >= 720.0:
		desktop_shortcut_grid.columns = 3
	else:
		desktop_shortcut_grid.columns = 2

	var desktop_margin: MarginContainer = $DesktopLayer/DesktopMargin
	desktop_margin.add_theme_constant_override("margin_left", 0)
	desktop_margin.add_theme_constant_override("margin_top", 0)
	desktop_margin.add_theme_constant_override("margin_right", 0)
	desktop_margin.add_theme_constant_override("margin_bottom", 0)

	var top_bar_height: float = float(_desktop_scaled_px(84.0, 72, 96))
	if desktop_figma_top_bar != null:
		desktop_figma_top_bar.custom_minimum_size = Vector2(0, top_bar_height)
	if desktop_figma_top_margin != null:
		desktop_figma_top_margin.add_theme_constant_override("margin_left", _desktop_scaled_px(28.0, 18, 36))
		desktop_figma_top_margin.add_theme_constant_override("margin_top", 0)
		desktop_figma_top_margin.add_theme_constant_override("margin_right", 0)
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
		desktop_figma_canvas_content_margin.add_theme_constant_override("margin_left", content_side_margin)
		desktop_figma_canvas_content_margin.add_theme_constant_override("margin_top", content_top_margin)
		desktop_figma_canvas_content_margin.add_theme_constant_override("margin_right", content_side_margin)
		desktop_figma_canvas_content_margin.add_theme_constant_override("margin_bottom", content_bottom_margin)

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


func _refresh_figma_desktop_status() -> void:
	if desktop_figma_date_label == null or desktop_figma_cash_label == null:
		return
	if not RunState.has_active_run():
		desktop_figma_date_label.text = "NO RUN"
		desktop_figma_cash_label.text = "RP 0"
		if desktop_advance_day_button != null:
			desktop_advance_day_button.disabled = true
			if not advance_day_processing:
				desktop_advance_day_button.text = "ADVANCE DAY"
		return
	var current_trade_date: Dictionary = GameManager.get_current_trade_date()
	var portfolio: Dictionary = GameManager.get_portfolio_snapshot()
	desktop_figma_date_label.text = _format_desktop_figma_date(current_trade_date).to_upper()
	desktop_figma_cash_label.text = _format_desktop_figma_cash(float(portfolio.get("cash", 0.0)))
	if desktop_advance_day_button != null:
		desktop_advance_day_button.disabled = advance_day_processing
		if not advance_day_processing:
			desktop_advance_day_button.text = "ADVANCE DAY"


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
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.956863, 0.913725, 0.780392, 1)
	style.border_color = Color(COLOR_DESKTOP_BROWN.r, COLOR_DESKTOP_BROWN.g, COLOR_DESKTOP_BROWN.b, 0.12)
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)


func _style_desktop_shortcut_button(button: Button) -> void:
	if button == null:
		return
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_DESKTOP_PANEL
	normal.border_color = Color(0.870588, 0.788235, 0.647059, 1)
	normal.set_border_width_all(4)
	normal.set_corner_radius_all(0)
	normal.shadow_color = Color(0.24, 0.22, 0.15, 0.18)
	normal.shadow_size = 0
	normal.shadow_offset = Vector2(5, 5)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.992157, 0.941176, 0.760784, 1)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.882353, 0.831373, 0.65098, 1)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", pressed)
	button.add_theme_color_override("icon_normal_color", COLOR_DESKTOP_BROWN)
	button.add_theme_color_override("icon_hover_color", COLOR_DESKTOP_BROWN)
	button.add_theme_color_override("icon_pressed_color", COLOR_DESKTOP_BROWN)


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
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_DESKTOP_GOLD
	normal.border_color = COLOR_DESKTOP_GOLD
	normal.set_border_width_all(0)
	normal.set_corner_radius_all(0)
	normal.content_margin_left = 24
	normal.content_margin_right = 22
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color(1.0, 0.792157, 0.168627, 1)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.862745, 0.580392, 0.0392157, 1)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.937255, 0.752941, 0.211765, 1)
	disabled.border_color = Color(0.937255, 0.752941, 0.211765, 1)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_DESKTOP_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_DESKTOP_TEXT)
	button.add_theme_color_override("font_disabled_color", COLOR_DESKTOP_TEXT)
	button.add_theme_color_override("font_focus_color", COLOR_DESKTOP_TEXT)
	button.add_theme_color_override("icon_normal_color", COLOR_DESKTOP_TEXT)
	button.add_theme_color_override("icon_hover_color", COLOR_DESKTOP_TEXT)
	button.add_theme_color_override("icon_pressed_color", COLOR_DESKTOP_TEXT)
	button.add_theme_color_override("icon_disabled_color", COLOR_DESKTOP_TEXT)
	button.add_theme_color_override("icon_focus_color", COLOR_DESKTOP_TEXT)
	button.add_theme_font_size_override("font_size", 18)


func _style_desktop_bottom_nav_button(button: Button, active: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.984314, 0.94902, 0.835294, 1) if active else COLOR_DESKTOP_PANEL
	normal.border_color = COLOR_DESKTOP_BROWN if active else Color(COLOR_DESKTOP_BROWN.r, COLOR_DESKTOP_BROWN.g, COLOR_DESKTOP_BROWN.b, 0.28)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.992157, 0.941176, 0.760784, 1)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", COLOR_DESKTOP_BROWN)
	button.add_theme_color_override("font_hover_color", COLOR_DESKTOP_BROWN)
	button.add_theme_color_override("font_pressed_color", COLOR_DESKTOP_BROWN)
	button.add_theme_color_override("icon_normal_color", COLOR_DESKTOP_BROWN)
	button.add_theme_color_override("icon_hover_color", COLOR_DESKTOP_BROWN)
	button.add_theme_color_override("icon_pressed_color", COLOR_DESKTOP_BROWN)
	button.add_theme_font_size_override("font_size", 12)


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
	title_bar.offset_left = 0
	title_bar.offset_top = 0
	title_bar.offset_right = 0
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
	close_button.name = "CloseButton"
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(28, 24)
	close_button.tooltip_text = "Close this window."
	close_button.pressed.connect(_on_desktop_window_close_pressed.bind(app_id))
	title_row.add_child(close_button)

	var content_host := Control.new()
	content_host.name = "ContentHost"
	content_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_host.offset_top = DESKTOP_WINDOW_TITLE_BAR_HEIGHT
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
			return Vector2(380, 520)
		APP_ID_NETWORK:
			return Vector2(780, 620)
		APP_ID_ACADEMY:
			return Vector2(860, 620)
		APP_ID_THESIS:
			return Vector2(920, 620)
		APP_ID_LIFE:
			return Vector2(780, 560)
		APP_ID_UPGRADES:
			return Vector2(640, 460)
		_:
			return Vector2(DESKTOP_WINDOW_MIN_WIDTH, DESKTOP_WINDOW_MIN_HEIGHT)


func _desktop_window_work_rect() -> Rect2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var inset_left: float = 4.0
	var inset_top: float = 4.0
	var inset_right: float = 4.0
	var inset_bottom: float = 4.0
	return Rect2(
		Vector2(inset_left, inset_top),
		Vector2(
			max(viewport_size.x - inset_left - inset_right, 240.0),
			max(viewport_size.y - inset_top - inset_bottom, 180.0)
		)
	)


func _desktop_window_default_rect(app_id: String) -> Rect2:
	var work_rect: Rect2 = _desktop_window_work_rect()
	var size := _desktop_window_min_size_for_app(app_id)
	match app_id:
		APP_ID_STOCK:
			size.x = min(max(work_rect.size.x - 20.0, size.x), work_rect.size.x)
			size.y = min(max(work_rect.size.y - 28.0, size.y), work_rect.size.y)
			return Rect2(work_rect.position + Vector2(10, 10), size)
		APP_ID_NEWS:
			size.x = min(max(work_rect.size.x * 0.8, size.x), work_rect.size.x - 12.0)
			size.y = min(max(work_rect.size.y * 0.84, size.y), work_rect.size.y - 12.0)
			return Rect2(work_rect.position + Vector2(26, 18), size)
		APP_ID_SOCIAL:
			size.x = clamp(work_rect.size.x * 0.34, size.x, min(SOCIAL_WINDOW_MAX_WIDTH + 36.0, work_rect.size.x))
			size.y = clamp(work_rect.size.y * 0.78, size.y, min(SOCIAL_WINDOW_MAX_HEIGHT + 24.0, work_rect.size.y))
			return Rect2(
				Vector2(max(work_rect.position.x + work_rect.size.x - size.x - 18.0, work_rect.position.x), work_rect.position.y + 14.0),
				size
			)
		APP_ID_NETWORK:
			size.x = min(max(work_rect.size.x * 0.78, size.x), work_rect.size.x - 12.0)
			size.y = min(max(work_rect.size.y * 0.88, size.y), work_rect.size.y - 12.0)
			return Rect2(work_rect.position + Vector2(28, 14), size)
		APP_ID_ACADEMY:
			size.x = min(max(work_rect.size.x * 0.78, size.x), work_rect.size.x - 12.0)
			size.y = min(max(work_rect.size.y * 0.86, size.y), work_rect.size.y - 12.0)
			return Rect2(work_rect.position + Vector2(24, 18), size)
		APP_ID_THESIS:
			size.x = min(max(work_rect.size.x * 0.82, size.x), work_rect.size.x - 12.0)
			size.y = min(max(work_rect.size.y * 0.86, size.y), work_rect.size.y - 12.0)
			return Rect2(work_rect.position + Vector2(32, 22), size)
		APP_ID_LIFE:
			size.x = min(max(work_rect.size.x * 0.72, size.x), work_rect.size.x - 16.0)
			size.y = min(max(work_rect.size.y * 0.74, size.y), work_rect.size.y - 16.0)
			return Rect2(work_rect.position + Vector2(52, 40), size)
		APP_ID_UPGRADES:
			size.x = min(max(work_rect.size.x * 0.64, size.x), work_rect.size.x - 16.0)
			size.y = min(max(work_rect.size.y * 0.7, size.y), work_rect.size.y - 16.0)
			return Rect2(work_rect.position + Vector2(72, 48), size)
		_:
			size.x = min(size.x, work_rect.size.x)
			size.y = min(size.y, work_rect.size.y)
			return Rect2(work_rect.position, size)


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
	if deferred_open_app_refresh_queue.has(app_id) and not advance_day_processing and pending_daily_recap_snapshot.is_empty():
		_remove_deferred_open_app_refresh(app_id)
		_refresh_app_window_content(app_id)
	_refresh_desktop_window_themes()
	_refresh_desktop()
	_play_desktop_window_focus_animation(app_id)


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
	_refresh_desktop_window_themes()
	_refresh_desktop()


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
	if _uses_academy_window_chrome(app_id):
		return COLOR_ACADEMY_BROWN
	if app_id == APP_ID_SOCIAL:
		return Color(0.94902, 0.956863, 0.976471, 1)
	return COLOR_WINDOW_BG


func _window_text_color_for_app(app_id: String) -> Color:
	return COLOR_TEXT if app_id == APP_ID_STOCK or _uses_academy_window_chrome(app_id) else COLOR_WINDOW_TEXT


func _uses_academy_window_chrome(app_id: String) -> bool:
	return (
		app_id == APP_ID_ACADEMY or
		app_id == APP_ID_THESIS or
		app_id == APP_ID_LIFE or
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
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = fill_color
		frame_style.border_color = COLOR_ACCENT if is_active else COLOR_BORDER
		frame_style.set_border_width_all(2 if is_active else 1)
		frame_style.corner_radius_top_left = 8
		frame_style.corner_radius_top_right = 8
		frame_style.corner_radius_bottom_left = 8
		frame_style.corner_radius_bottom_right = 8
		frame.add_theme_stylebox_override("panel", frame_style)
		var title_fill: Color = fill_color.lightened(0.04) if text_color == COLOR_WINDOW_TEXT else fill_color
		_style_window_title_bar(title_bar, title_fill)
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


func _ensure_life_ui() -> void:
	if life_window != null:
		return

	var desktop_icons_row: HBoxContainer = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow
	var life_tile := VBoxContainer.new()
	life_tile.name = "LifeAppTile"
	life_tile.add_theme_constant_override("separation", 10)
	desktop_icons_row.add_child(life_tile)
	var upgrades_tile: Node = desktop_icons_row.get_node_or_null("UpgradesAppTile")
	if upgrades_tile != null:
		desktop_icons_row.move_child(life_tile, upgrades_tile.get_index())

	life_app_button = Button.new()
	life_app_button.name = "LifeAppButton"
	life_app_button.custom_minimum_size = Vector2(92, 92)
	life_app_button.toggle_mode = true
	life_tile.add_child(life_app_button)

	life_app_label = Label.new()
	life_app_label.name = "LifeAppLabel"
	life_app_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	life_app_label.text = "Life"
	life_app_label.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)
	life_tile.add_child(life_app_label)

	life_window = LIFE_WIDGET_SCRIPT.new()
	life_window.name = "LifeWindow"
	life_window.visible = false
	life_window.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(life_window)
	var upgrade_window_node: Node = get_node_or_null("UpgradeWindow")
	if upgrade_window_node != null:
		move_child(life_window, upgrade_window_node.get_index())


func _refresh_life() -> void:
	if life_window == null:
		return
	if life_window.has_method("refresh"):
		life_window.call("refresh")


func _ensure_academy_ui() -> void:
	if academy_window != null:
		return

	var desktop_icons_row: HBoxContainer = $DesktopLayer/DesktopMargin/DesktopVBox/DesktopIconsRow
	var academy_tile := VBoxContainer.new()
	academy_tile.name = "AcademyAppTile"
	academy_tile.add_theme_constant_override("separation", 10)
	desktop_icons_row.add_child(academy_tile)
	var upgrades_tile: Node = desktop_icons_row.get_node_or_null("UpgradesAppTile")
	if upgrades_tile != null:
		desktop_icons_row.move_child(academy_tile, upgrades_tile.get_index())

	academy_app_button = Button.new()
	academy_app_button.name = "AcademyAppButton"
	academy_app_button.custom_minimum_size = Vector2(92, 92)
	academy_app_button.toggle_mode = true
	academy_tile.add_child(academy_app_button)

	academy_app_label = Label.new()
	academy_app_label.name = "AcademyAppLabel"
	academy_app_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	academy_app_label.text = "Academy"
	academy_app_label.add_theme_color_override("font_color", COLOR_DESKTOP_TEXT)
	academy_tile.add_child(academy_app_label)

	academy_window = MarginContainer.new()
	academy_window.name = "AcademyWindow"
	academy_window.visible = false
	academy_window.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(academy_window)
	var upgrade_window_node: Node = get_node_or_null("UpgradeWindow")
	if upgrade_window_node != null:
		move_child(academy_window, upgrade_window_node.get_index())

	academy_window_body = PanelContainer.new()
	academy_window_body.name = "AcademyWindowBody"
	academy_window_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	academy_window_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	academy_window.add_child(academy_window_body)

	var academy_margin := MarginContainer.new()
	academy_margin.name = "AcademyWindowMargin"
	academy_margin.add_theme_constant_override("margin_left", 14)
	academy_margin.add_theme_constant_override("margin_top", 14)
	academy_margin.add_theme_constant_override("margin_right", 14)
	academy_margin.add_theme_constant_override("margin_bottom", 14)
	academy_window_body.add_child(academy_margin)

	var academy_vbox := VBoxContainer.new()
	academy_vbox.name = "AcademyWindowVBox"
	academy_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	academy_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	academy_vbox.add_theme_constant_override("separation", 12)
	academy_margin.add_child(academy_vbox)

	var header_row := HBoxContainer.new()
	header_row.name = "AcademyHeaderRow"
	header_row.visible = false
	header_row.add_theme_constant_override("separation", 12)
	academy_vbox.add_child(header_row)

	academy_title_label = Label.new()
	academy_title_label.name = "AcademyTitleLabel"
	academy_title_label.text = "Academy"
	academy_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(academy_title_label)

	academy_progress_label = Label.new()
	academy_progress_label.name = "AcademyProgressLabel"
	academy_progress_label.text = ""
	header_row.add_child(academy_progress_label)

	academy_category_tabs = HBoxContainer.new()
	academy_category_tabs.name = "AcademyCategoryTabs"
	academy_category_tabs.add_theme_constant_override("separation", 0)
	academy_category_tabs.custom_minimum_size = Vector2(0, 38)
	academy_vbox.add_child(academy_category_tabs)

	academy_section_tabs = GridContainer.new()
	academy_section_tabs.name = "AcademySectionTabs"
	academy_section_tabs.visible = false
	academy_section_tabs.columns = 4
	academy_section_tabs.add_theme_constant_override("h_separation", 8)
	academy_section_tabs.add_theme_constant_override("v_separation", 8)
	academy_vbox.add_child(academy_section_tabs)

	academy_summary_label = Label.new()
	academy_summary_label.name = "AcademySummaryLabel"
	academy_summary_label.visible = false
	academy_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	academy_vbox.add_child(academy_summary_label)

	var content_split := HSplitContainer.new()
	content_split.name = "AcademyContentSplit"
	content_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_split.split_offset = 242
	academy_vbox.add_child(content_split)

	var list_panel := PanelContainer.new()
	list_panel.name = "AcademySectionListPanel"
	list_panel.visible = true
	list_panel.custom_minimum_size = Vector2(240, 0)
	content_split.add_child(list_panel)
	_style_panel(list_panel, COLOR_ACADEMY_RAIL, 0)
	var list_margin := MarginContainer.new()
	list_margin.add_theme_constant_override("margin_left", 0)
	list_margin.add_theme_constant_override("margin_top", 12)
	list_margin.add_theme_constant_override("margin_right", 0)
	list_margin.add_theme_constant_override("margin_bottom", 12)
	list_panel.add_child(list_margin)
	var list_vbox := VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 10)
	list_margin.add_child(list_vbox)
	var list_title := Label.new()
	list_title.name = "AcademyCoreModulesLabel"
	list_title.text = "CORE MODULES"
	list_title.add_theme_font_size_override("font_size", 11)
	list_title.add_theme_constant_override("line_spacing", 0)
	var list_title_margin := MarginContainer.new()
	list_title_margin.add_theme_constant_override("margin_left", 14)
	list_title_margin.add_theme_constant_override("margin_right", 14)
	list_title_margin.add_child(list_title)
	list_vbox.add_child(list_title_margin)
	academy_section_list = ItemList.new()
	academy_section_list.name = "AcademySectionList"
	academy_section_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	academy_section_list.fixed_column_width = 0
	academy_section_list.same_column_width = false
	academy_section_list.max_text_lines = 2
	var list_inner_margin := MarginContainer.new()
	list_inner_margin.add_theme_constant_override("margin_left", 12)
	list_inner_margin.add_theme_constant_override("margin_right", 12)
	list_inner_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_inner_margin.add_child(academy_section_list)
	list_vbox.add_child(list_inner_margin)

	var lesson_panel := PanelContainer.new()
	lesson_panel.name = "AcademyLessonPanel"
	lesson_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_split.add_child(lesson_panel)
	_style_panel(lesson_panel, COLOR_ACADEMY_CREAM, 0)
	var lesson_margin := MarginContainer.new()
	lesson_margin.add_theme_constant_override("margin_left", 26)
	lesson_margin.add_theme_constant_override("margin_top", 24)
	lesson_margin.add_theme_constant_override("margin_right", 26)
	lesson_margin.add_theme_constant_override("margin_bottom", 16)
	lesson_panel.add_child(lesson_margin)
	var lesson_vbox := VBoxContainer.new()
	lesson_vbox.add_theme_constant_override("separation", 12)
	lesson_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lesson_margin.add_child(lesson_vbox)
	academy_lesson_scroll = ScrollContainer.new()
	academy_lesson_scroll.name = "AcademyLessonScroll"
	academy_lesson_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	academy_lesson_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lesson_vbox.add_child(academy_lesson_scroll)
	var lesson_scroll_vbox := VBoxContainer.new()
	lesson_scroll_vbox.name = "AcademyLessonScrollVBox"
	lesson_scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson_scroll_vbox.add_theme_constant_override("separation", 12)
	academy_lesson_scroll.add_child(lesson_scroll_vbox)
	academy_selection_chip_label = Label.new()
	academy_selection_chip_label.name = "AcademySelectionChipLabel"
	academy_selection_chip_label.text = "CURRENT SELECTION"
	academy_selection_chip_label.add_theme_font_size_override("font_size", 10)
	academy_selection_chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	academy_selection_chip_label.custom_minimum_size = Vector2(150, 20)
	lesson_scroll_vbox.add_child(academy_selection_chip_label)
	academy_lesson_title_label = Label.new()
	academy_lesson_title_label.name = "AcademyLessonTitleLabel"
	academy_lesson_title_label.visible = true
	academy_lesson_title_label.add_theme_font_size_override("font_size", 30)
	academy_lesson_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lesson_scroll_vbox.add_child(academy_lesson_title_label)
	academy_lesson_meta_label = Label.new()
	academy_lesson_meta_label.name = "AcademyLessonMetaLabel"
	academy_lesson_meta_label.visible = true
	academy_lesson_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lesson_scroll_vbox.add_child(academy_lesson_meta_label)
	academy_lesson_banner_frame = PanelContainer.new()
	academy_lesson_banner_frame.name = "AcademyLessonBannerFrame"
	academy_lesson_banner_frame.custom_minimum_size = Vector2(0, 150)
	academy_lesson_banner_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson_scroll_vbox.add_child(academy_lesson_banner_frame)
	_style_academy_banner_frame(academy_lesson_banner_frame)
	var banner_center := CenterContainer.new()
	academy_lesson_banner_frame.add_child(banner_center)
	academy_lesson_banner_label = Label.new()
	academy_lesson_banner_label.name = "AcademyLessonBannerLabel"
	academy_lesson_banner_label.text = "CHART MODULE"
	academy_lesson_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	academy_lesson_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	academy_lesson_banner_label.add_theme_font_size_override("font_size", 16)
	banner_center.add_child(academy_lesson_banner_label)
	academy_lesson_content_vbox = VBoxContainer.new()
	academy_lesson_content_vbox.name = "AcademyLessonContentVBox"
	academy_lesson_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	academy_lesson_content_vbox.add_theme_constant_override("separation", 10)
	lesson_scroll_vbox.add_child(academy_lesson_content_vbox)
	academy_action_row = HBoxContainer.new()
	academy_action_row.name = "AcademyActionRow"
	academy_action_row.add_theme_constant_override("separation", 10)
	lesson_vbox.add_child(academy_action_row)
	academy_mark_read_button = Button.new()
	academy_mark_read_button.name = "AcademyMarkReadButton"
	academy_mark_read_button.text = "MARK AS COMPLETE"
	academy_mark_read_button.custom_minimum_size = Vector2(170, 44)
	academy_action_row.add_child(academy_mark_read_button)
	academy_next_button = Button.new()
	academy_next_button.name = "AcademyNextButton"
	academy_next_button.text = "Next Section"
	academy_next_button.custom_minimum_size = Vector2(130, 44)
	academy_action_row.add_child(academy_next_button)

	var side_panel := PanelContainer.new()
	side_panel.name = "AcademySidePanel"
	side_panel.visible = false
	side_panel.custom_minimum_size = Vector2(260, 0)
	content_split.add_child(side_panel)
	_style_panel(side_panel, Color(0.952941, 0.94902, 0.87451, 1), 0)
	var side_margin := MarginContainer.new()
	side_margin.add_theme_constant_override("margin_left", 10)
	side_margin.add_theme_constant_override("margin_top", 10)
	side_margin.add_theme_constant_override("margin_right", 10)
	side_margin.add_theme_constant_override("margin_bottom", 10)
	side_panel.add_child(side_margin)
	var side_vbox := VBoxContainer.new()
	side_vbox.add_theme_constant_override("separation", 8)
	side_margin.add_child(side_vbox)
	academy_side_title_label = Label.new()
	academy_side_title_label.name = "AcademySideTitleLabel"
	side_vbox.add_child(academy_side_title_label)
	academy_side_body_label = Label.new()
	academy_side_body_label.name = "AcademySideBodyLabel"
	academy_side_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_vbox.add_child(academy_side_body_label)
	academy_glossary_search_input = LineEdit.new()
	academy_glossary_search_input.name = "AcademyGlossarySearchInput"
	academy_glossary_search_input.placeholder_text = "Search glossary"
	side_vbox.add_child(academy_glossary_search_input)
	academy_glossary_list = ItemList.new()
	academy_glossary_list.name = "AcademyGlossaryList"
	academy_glossary_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_vbox.add_child(academy_glossary_list)
	_apply_academy_text_theme()
	_style_academy_primary_button(academy_mark_read_button)
	_style_button(academy_next_button, Color(0.894118, 0.85098, 0.678431, 1), COLOR_ACADEMY_BORDER, COLOR_WINDOW_TEXT, 0)
	_apply_academy_button_padding(academy_mark_read_button, 14)
	_apply_academy_button_padding(academy_next_button, 14)
	_restyle_academy_controls()


func _refresh_academy() -> void:
	if academy_window == null:
		return
	current_academy_snapshot = {}
	academy_title_label.text = "Academy"
	if not RunState.has_active_run():
		academy_progress_label.text = "No run loaded"
		academy_summary_label.text = "Start a run to open Academy lessons."
		academy_section_list.clear()
		_clear_container_children(academy_category_tabs)
		_clear_container_children(academy_section_tabs)
		_clear_container_children(academy_lesson_content_vbox)
		if academy_selection_chip_label != null:
			academy_selection_chip_label.text = "NO RUN LOADED"
		if academy_lesson_banner_label != null:
			academy_lesson_banner_label.text = "ACADEMY"
		academy_lesson_title_label.text = "No lesson"
		academy_lesson_meta_label.text = ""
		academy_mark_read_button.disabled = true
		academy_next_button.disabled = true
		_apply_font_overrides_to_subtree(academy_window)
		_restyle_academy_controls()
		return

	current_academy_snapshot = GameManager.get_academy_snapshot(selected_academy_category_id, selected_academy_section_id)
	selected_academy_category_id = str(current_academy_snapshot.get("category_id", selected_academy_category_id))
	selected_academy_section_id = str(current_academy_snapshot.get("selected_section_id", selected_academy_section_id))
	academy_title_label.text = ""
	_rebuild_academy_category_tabs()
	_rebuild_academy_section_list()
	_rebuild_academy_section_tabs()
	_refresh_academy_content()
	_apply_academy_text_theme()
	_apply_font_overrides_to_subtree(academy_window)
	_restyle_academy_controls()


func _apply_academy_text_theme() -> void:
	if academy_window == null:
		return
	_apply_academy_text_theme_to_node(academy_window)


func _apply_academy_text_theme_to_node(node: Node) -> void:
	if node is Label:
		var label: Label = node
		label.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	elif node is RichTextLabel:
		var rich_text: RichTextLabel = node
		rich_text.add_theme_color_override("default_color", COLOR_WINDOW_TEXT)
	elif node is ItemList:
		var item_list: ItemList = node
		item_list.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
		item_list.add_theme_color_override("font_hovered_color", COLOR_WINDOW_TEXT)
		item_list.add_theme_color_override("font_selected_color", COLOR_WINDOW_TEXT)
	elif node is LineEdit:
		var line_edit: LineEdit = node
		line_edit.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
		line_edit.add_theme_color_override("font_placeholder_color", Color(0.352941, 0.309804, 0.203922, 0.78))
	elif node is OptionButton:
		var option_button: OptionButton = node
		option_button.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
		option_button.add_theme_color_override("font_hover_color", COLOR_WINDOW_TEXT)
		option_button.add_theme_color_override("font_pressed_color", COLOR_WINDOW_TEXT)
	elif node is Button:
		var button: Button = node
		button.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
		button.add_theme_color_override("font_hover_color", COLOR_WINDOW_TEXT)
		button.add_theme_color_override("font_pressed_color", COLOR_WINDOW_TEXT)
		button.add_theme_color_override("font_disabled_color", Color(0.352941, 0.309804, 0.203922, 0.62))

	for child in node.get_children():
		_apply_academy_text_theme_to_node(child)


func _rebuild_academy_category_tabs() -> void:
	_clear_container_children(academy_category_tabs)
	for category_value in current_academy_snapshot.get("categories", []):
		var category: Dictionary = category_value
		var button := Button.new()
		var category_id: String = str(category.get("id", ""))
		button.name = "AcademyCategoryButton_%s" % category_id
		button.text = str(category.get("label", category_id.capitalize())).to_upper()
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 36)
		button.set_pressed_no_signal(category_id == selected_academy_category_id)
		button.pressed.connect(_on_academy_category_pressed.bind(category_id))
		academy_category_tabs.add_child(button)
		_style_academy_category_tab(button, category_id == selected_academy_category_id)


func _style_academy_category_tab(button: Button, selected: bool) -> void:
	var fill: Color = COLOR_ACADEMY_CREAM
	var border: Color = COLOR_ACADEMY_BORDER
	var font_color: Color = COLOR_ACADEMY_BROWN
	if selected:
		fill = COLOR_ACADEMY_BROWN
		border = COLOR_ACADEMY_BROWN.darkened(0.22)
		font_color = COLOR_TEXT
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = fill
	normal.border_color = border
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 0
	normal.corner_radius_top_right = 0
	normal.corner_radius_bottom_left = 0
	normal.corner_radius_bottom_right = 0
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = fill.lightened(0.05)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = fill.darkened(0.04)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", pressed)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)


func _apply_academy_button_padding(button: Button, padding: int = 24) -> void:
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var current_style: StyleBox = button.get_theme_stylebox(style_name)
		if current_style == null or current_style is not StyleBoxFlat:
			continue
		var flat_style: StyleBoxFlat = current_style.duplicate()
		flat_style.content_margin_left = padding
		flat_style.content_margin_right = padding
		flat_style.content_margin_top = padding
		flat_style.content_margin_bottom = padding
		button.add_theme_stylebox_override(style_name, flat_style)


func _style_academy_primary_button(button: Button) -> void:
	_style_button(button, COLOR_ACADEMY_BROWN, COLOR_ACADEMY_BROWN.darkened(0.22), COLOR_TEXT, 0)
	var normal_style: StyleBoxFlat = button.get_theme_stylebox("normal") as StyleBoxFlat
	if normal_style != null:
		var disabled_style: StyleBoxFlat = normal_style.duplicate()
		disabled_style.bg_color = COLOR_ACADEMY_BROWN.lightened(0.24)
		disabled_style.border_color = COLOR_ACADEMY_BROWN.darkened(0.12)
		button.add_theme_stylebox_override("disabled", disabled_style)
	button.add_theme_color_override("font_disabled_color", Color(1.0, 0.976471, 0.929412, 0.78))


func _style_academy_selection_chip(label: Label) -> void:
	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = COLOR_ACADEMY_GREEN
	chip_style.border_color = COLOR_ACADEMY_GREEN.darkened(0.18)
	chip_style.set_border_width_all(0)
	chip_style.corner_radius_top_left = 0
	chip_style.corner_radius_top_right = 0
	chip_style.corner_radius_bottom_left = 0
	chip_style.corner_radius_bottom_right = 0
	chip_style.content_margin_left = 10
	chip_style.content_margin_right = 10
	chip_style.content_margin_top = 4
	chip_style.content_margin_bottom = 4
	label.add_theme_stylebox_override("normal", chip_style)
	label.add_theme_color_override("font_color", Color(0.247059, 0.278431, 0.117647, 1))


func _style_academy_banner_frame(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.196078, 0.156863, 0.92)
	style.border_color = Color(0.12549, 0.113725, 0.0823529, 1)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)


func _style_academy_content_block(panel: PanelContainer, fill_color: Color, border_left: int = 1) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = COLOR_ACADEMY_BORDER
	style.border_width_left = border_left
	style.border_width_top = 0 if border_left > 1 else 1
	style.border_width_right = 0 if border_left > 1 else 1
	style.border_width_bottom = 0 if border_left > 1 else 1
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)


func _style_academy_text_card(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_ACADEMY_CREAM
	style.border_color = Color(0.658824, 0.533333, 0.278431, 0.92)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)


func _style_academy_infobox_card(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.945098, 0.894118, 0.705882, 1)
	style.border_color = Color(0.658824, 0.533333, 0.278431, 0.95)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)


func _style_academy_key_insights_card(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.835294, 0.898039, 0.968627, 1)
	style.border_color = Color(0.133333, 0.376471, 0.694118, 1)
	style.border_width_left = 5
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)


func _style_academy_quick_check_button(button: Button) -> void:
	_style_button(button, Color(0.945098, 0.894118, 0.705882, 1), COLOR_ACADEMY_BORDER, COLOR_WINDOW_TEXT, 0)
	_apply_academy_button_padding(button, 10)
	button.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_WINDOW_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_WINDOW_TEXT)
	button.add_theme_color_override("font_focus_color", COLOR_WINDOW_TEXT)


func _restyle_academy_controls() -> void:
	if academy_window_body != null:
		_style_panel(academy_window_body, COLOR_ACADEMY_CREAM, 0)
	if academy_section_list != null:
		_style_light_item_list(academy_section_list)
	if academy_glossary_list != null:
		_style_light_item_list(academy_glossary_list)
	if academy_category_tabs != null:
		for child in academy_category_tabs.get_children():
			var tab_button: Button = child as Button
			if tab_button == null:
				continue
			var tab_id: String = tab_button.name.trim_prefix("AcademyCategoryButton_")
			_style_academy_category_tab(tab_button, tab_id == selected_academy_category_id)
	if academy_selection_chip_label != null:
		_style_academy_selection_chip(academy_selection_chip_label)
		academy_selection_chip_label.add_theme_font_size_override("font_size", 10)
	if academy_lesson_title_label != null:
		academy_lesson_title_label.add_theme_color_override("font_color", COLOR_ACADEMY_BROWN)
		academy_lesson_title_label.add_theme_font_size_override("font_size", 30)
	if academy_lesson_meta_label != null:
		academy_lesson_meta_label.add_theme_color_override("font_color", Color(0.25098, 0.223529, 0.156863, 1))
		academy_lesson_meta_label.add_theme_font_size_override("font_size", 14)
	if academy_lesson_banner_frame != null:
		_style_academy_banner_frame(academy_lesson_banner_frame)
	if academy_lesson_banner_label != null:
		academy_lesson_banner_label.add_theme_color_override("font_color", Color(0.898039, 0.870588, 0.745098, 1))
		academy_lesson_banner_label.add_theme_font_size_override("font_size", 16)
	if academy_mark_read_button != null:
		_style_academy_primary_button(academy_mark_read_button)
		_apply_academy_button_padding(academy_mark_read_button, 14)
	if academy_next_button != null:
		_style_button(academy_next_button, Color(0.894118, 0.85098, 0.678431, 1), COLOR_ACADEMY_BORDER, COLOR_WINDOW_TEXT, 0)
		_apply_academy_button_padding(academy_next_button, 14)
	if academy_lesson_content_vbox != null:
		_restyle_academy_content_nodes(academy_lesson_content_vbox)


func _restyle_academy_content_nodes(node: Node) -> void:
	if node.name == "AcademyTextBlockTitle" and node is Label:
		var label: Label = node
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(0.129412, 0.101961, 0.058824, 1))
	if node.name == "AcademyKeyInsightsTitle" and node is Label:
		var insights_label: Label = node
		insights_label.add_theme_font_size_override("font_size", 16)
		insights_label.add_theme_color_override("font_color", Color(0.054902, 0.164706, 0.313726, 1))
	if node.name == "AcademyQuickCheckOptionButton" and node is Button:
		_style_academy_quick_check_button(node as Button)
	for child in node.get_children():
		_restyle_academy_content_nodes(child)


func _rebuild_academy_section_list() -> void:
	academy_section_list.clear()
	var sections: Array = current_academy_snapshot.get("sections", [])
	for index in range(sections.size()):
		var section: Dictionary = sections[index]
		var section_id: String = str(section.get("id", ""))
		var order: int = int(section.get("order", index + 1))
		var title: String = str(section.get("title", section.get("label", "Section")))
		var status_label: String = _academy_module_status_label(section)
		var label: String = "%d    %s\n     %s" % [order, title, status_label]
		academy_section_list.add_item(label)
		academy_section_list.set_item_metadata(index, section.duplicate(true))
		academy_section_list.set_item_disabled(index, bool(section.get("locked", false)))
		academy_section_list.set_item_custom_fg_color(index, COLOR_WINDOW_TEXT if not bool(section.get("locked", false)) else Color(0.329412, 0.313725, 0.266667, 0.78))
		academy_section_list.set_item_custom_bg_color(index, _academy_module_row_color(section, section_id == selected_academy_section_id))
		if section_id == selected_academy_section_id:
			academy_section_list.select(index)


func _academy_module_status_label(section: Dictionary) -> String:
	var kind: String = str(section.get("kind", "lesson"))
	if kind == "quiz":
		return "Quiz locked" if bool(section.get("locked", false)) else "Quiz"
	if kind == "glossary":
		return "Glossary"
	if bool(section.get("read", false)):
		return "Completed"
	return "Not learned"


func _academy_module_row_color(section: Dictionary, selected: bool) -> Color:
	if selected:
		return Color(0.87451, 0.831373, 0.666667, 1)
	if bool(section.get("read", false)):
		return Color(0.917647, 0.933333, 0.741176, 1)
	if bool(section.get("locked", false)):
		return Color(0.839216, 0.815686, 0.72549, 0.45)
	return Color(0.968627, 0.941176, 0.815686, 0.62)


func _rebuild_academy_section_tabs() -> void:
	_clear_container_children(academy_section_tabs)
	var sections: Array = current_academy_snapshot.get("sections", [])
	for section_value in sections:
		var section: Dictionary = section_value
		var section_id: String = str(section.get("id", ""))
		var selected: bool = section_id == selected_academy_section_id
		var button := Button.new()
		button.name = "AcademySectionTab_%s" % section_id
		button.custom_minimum_size = Vector2(220, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.text = _academy_section_tab_label(section, selected)
		button.disabled = bool(section.get("locked", false))
		button.set_pressed_no_signal(selected)
		button.pressed.connect(_on_academy_section_tab_pressed.bind(section_id))
		academy_section_tabs.add_child(button)
		_style_academy_section_tab(button, selected, bool(section.get("locked", false)))


func _academy_section_tab_label(section: Dictionary, selected: bool = false) -> String:
	var label: String = str(section.get("label", "Section"))
	var title: String = str(section.get("title", ""))
	var order: int = int(section.get("order", 0))
	var prefix: String = "%02d / 08 " % order if selected and order > 0 else ""
	if label.begins_with("01"):
		return "%s01 Getting to Know TA" % prefix
	if label.begins_with("02"):
		return "%s02 Market Structure" % prefix
	if label.begins_with("03"):
		return "%s03 Candlesticks" % prefix
	if label.begins_with("04"):
		return "%s04 Patterns" % prefix
	if label.begins_with("05"):
		return "%s05 Moving Average" % prefix
	if label.begins_with("06"):
		return "%s06 Framework" % prefix
	if label.begins_with("07"):
		return "%s07 Quiz" % prefix if not bool(section.get("locked", false)) else "%s07 Quiz locked" % prefix
	if label.begins_with("08"):
		return "%s08 Glossary" % prefix
	return "%s%s" % [prefix, title if not title.is_empty() else label]


func _style_academy_section_tab(button: Button, selected: bool, locked: bool) -> void:
	var fill: Color = Color(0.968627, 0.964706, 0.898039, 1)
	var border: Color = COLOR_BORDER
	if selected:
		fill = Color(0.811765, 0.858824, 0.65098, 1)
		border = Color(0.117647, 0.32549, 0.239216, 1)
	elif locked:
		fill = Color(0.909804, 0.909804, 0.803922, 0.55)
		border = Color(0.454902, 0.337255, 0.141176, 0.5)
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = fill
	normal.border_color = border
	normal.set_border_width_all(1 if not selected else 2)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.content_margin_left = 24
	normal.content_margin_right = 24
	normal.content_margin_top = 24
	normal.content_margin_bottom = 24
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = fill.lightened(0.06)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = fill.darkened(0.04)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_WINDOW_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_WINDOW_TEXT)
	button.add_theme_color_override("font_disabled_color", Color(0.352941, 0.309804, 0.203922, 0.62))


func _refresh_academy_content() -> void:
	var progress: Dictionary = current_academy_snapshot.get("progress", {})
	var quiz: Dictionary = current_academy_snapshot.get("quiz", {})
	academy_progress_label.text = "%d/%d sections read  |  Quiz %s  |  Best %d%%" % [
		int(progress.get("read_count", 0)),
		int(progress.get("readable_count", 0)),
		"passed" if bool(quiz.get("passed", false)) else ("locked" if bool(quiz.get("locked", true)) else "open"),
		int(quiz.get("best_score_percent", 0))
	]
	_clear_container_children(academy_lesson_content_vbox)
	academy_quiz_option_buttons.clear()

	if bool(current_academy_snapshot.get("coming_soon", false)):
		academy_summary_label.text = str(current_academy_snapshot.get("category_label", "Academy")).to_upper()
		if academy_selection_chip_label != null:
			academy_selection_chip_label.text = "TRACK PREVIEW"
		academy_lesson_title_label.text = str(current_academy_snapshot.get("category_label", "Academy"))
		academy_lesson_meta_label.text = str(current_academy_snapshot.get("coming_soon_copy", "Coming soon."))
		if academy_lesson_banner_label != null:
			academy_lesson_banner_label.text = "COMING SOON"
		academy_mark_read_button.visible = false
		academy_next_button.visible = false
		_refresh_academy_side_panel()
		return

	var section: Dictionary = current_academy_snapshot.get("selected_section", {})
	if section.is_empty():
		academy_summary_label.text = ""
		if academy_selection_chip_label != null:
			academy_selection_chip_label.text = "CHOOSE MODULE"
		academy_lesson_title_label.text = "Choose a section"
		academy_lesson_meta_label.text = ""
		if academy_lesson_banner_label != null:
			academy_lesson_banner_label.text = "ACADEMY"
		academy_mark_read_button.visible = false
		academy_next_button.visible = false
		_refresh_academy_side_panel()
		return

	var kind: String = str(section.get("kind", "lesson"))
	academy_summary_label.text = str(section.get("label", "")).to_upper()
	if academy_selection_chip_label != null:
		academy_selection_chip_label.text = _academy_selection_chip_text(section)
	academy_lesson_title_label.text = str(section.get("title", section.get("label", "Lesson")))
	academy_lesson_meta_label.text = _academy_lesson_deck(section)
	if academy_lesson_banner_label != null:
		academy_lesson_banner_label.text = _academy_banner_label_for_section(section)
	if kind == "quiz":
		_build_academy_quiz(section)
	elif kind == "glossary":
		_build_academy_glossary_section()
	else:
		_build_academy_lesson(section)

	academy_mark_read_button.visible = kind == "lesson"
	academy_mark_read_button.disabled = bool(section.get("read", false))
	academy_mark_read_button.text = "COMPLETED" if bool(section.get("read", false)) else "MARK AS COMPLETE"
	academy_next_button.visible = true
	academy_next_button.disabled = _next_academy_section_id().is_empty()
	_refresh_academy_side_panel()


func _academy_selection_chip_text(section: Dictionary) -> String:
	var kind: String = str(section.get("kind", "lesson"))
	if kind == "quiz":
		return "CURRENT SELECTION: QUIZ"
	if kind == "glossary":
		return "CURRENT SELECTION: GLOSSARY"
	var order: int = int(section.get("order", 0))
	return "CURRENT SELECTION: MODULE %d" % max(order, 1)


func _academy_lesson_deck(section: Dictionary) -> String:
	var kind: String = str(section.get("kind", "lesson"))
	if kind == "quiz":
		return "Score 80 percent or better to earn Technical Basics."
	if kind == "glossary":
		return "Search the core vocabulary used across the Technical track."
	var completion_signal_text: String = str(section.get("completion_signal", "")).strip_edges()
	if not completion_signal_text.is_empty():
		var softened_signal: String = completion_signal_text.substr(0, 1).to_lower() + completion_signal_text.substr(1)
		return "In this chapter, %s" % softened_signal
	return "In this chapter, build one repeatable market-reading habit."


func _academy_banner_label_for_section(section: Dictionary) -> String:
	var kind: String = str(section.get("kind", "lesson"))
	if kind == "quiz":
		return "QUIZ BOARD"
	if kind == "glossary":
		return "GLOSSARY"
	var section_id: String = str(section.get("id", ""))
	match section_id:
		"market_structure":
			return "MARKET STRUCTURE"
		"candlesticks":
			return "CANDLE STUDY"
		"patterns":
			return "PATTERN BOARD"
		"moving_average":
			return "TREND MODULE"
		"thinking_framework":
			return "ROUTINE BOARD"
		_:
			return "CHART MODULE"


func _build_academy_lesson(section: Dictionary) -> void:
	var content_blocks: Array = section.get("content_blocks", [])
	if not content_blocks.is_empty():
		for block_value in content_blocks:
			var block: Dictionary = block_value
			academy_lesson_content_vbox.add_child(_build_academy_content_block(block))
	else:
		var paragraphs: Array = []
		for page_value in section.get("pages", []):
			var page: Dictionary = page_value
			var body: String = str(page.get("body", "")).strip_edges()
			if not body.is_empty():
				paragraphs.append(body)
		if not paragraphs.is_empty():
			academy_lesson_content_vbox.add_child(_build_academy_text_block(
				_academy_lesson_card_title(section),
				"\n\n".join(paragraphs)
			))

	var stored_checks: Dictionary = RunState.get_academy_progress().get("inline_checks", {}).get(selected_academy_category_id, {}).get(str(section.get("id", "")), {})
	for check_value in section.get("checks", []):
		var check: Dictionary = check_value
		academy_lesson_content_vbox.add_child(_build_academy_check_block(str(section.get("id", "")), check, stored_checks.get(str(check.get("id", "")), {})))


func _build_academy_content_block(block: Dictionary) -> Control:
	var block_type: String = str(block.get("type", "text"))
	if block_type == "image":
		return _build_academy_image_block(
			str(block.get("asset_path", "")),
			str(block.get("caption", "")),
			str(block.get("alt", "Academy image"))
		)
	if block_type == "key_insights":
		return _build_academy_key_insights_block(
			str(block.get("title", "Key Insights")),
			block.get("bullets", [])
		)
	return _build_academy_text_block(
		str(block.get("heading", "Lesson")),
		str(block.get("body", "")),
		block.get("infoboxes", []),
		block.get("images", [])
	)


func _academy_lesson_card_title(section: Dictionary) -> String:
	var section_id: String = str(section.get("id", ""))
	if section_id == "intro":
		return "What is technical analysis?"
	if section_id == "market_structure":
		return "Read the market shape first"
	if section_id == "candlesticks":
		return "Read the fight inside each candle"
	if section_id == "patterns":
		return "Patterns need context"
	if section_id == "moving_average":
		return "Moving averages confirm, not command"
	if section_id == "thinking_framework":
		return "A repeatable routine beats guessing"
	return str(section.get("title", "Lesson"))


func _build_academy_quiz(_section: Dictionary) -> void:
	var quiz: Dictionary = current_academy_snapshot.get("quiz", {})
	if bool(quiz.get("locked", true)):
		var unread_labels: Array = []
		for unread_value in quiz.get("unread_required_sections", []):
			var unread: Dictionary = unread_value
			unread_labels.append(str(unread.get("label", "")))
		academy_lesson_content_vbox.add_child(_build_academy_text_block("Locked", "Read these sections first: %s." % ", ".join(unread_labels)))
		return

	academy_lesson_content_vbox.add_child(_build_academy_text_block("Quiz", "Score 80 percent or better to earn Technical Basics. Wrong answers give feedback after submission."))
	var catalog: Dictionary = DataRepository.get_academy_catalog()
	var technical_category: Dictionary = {}
	for category_value in catalog.get("categories", []):
		var category: Dictionary = category_value
		if str(category.get("id", "")) == selected_academy_category_id:
			technical_category = category
			break
	for question_value in technical_category.get("quiz_questions", []):
		var question: Dictionary = question_value
		var block := VBoxContainer.new()
		block.add_theme_constant_override("separation", 6)
		var prompt := Label.new()
		prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		prompt.text = "%s: %s" % [str(question.get("category", "Question")), str(question.get("prompt", ""))]
		prompt.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
		block.add_child(prompt)
		var option_button := OptionButton.new()
		option_button.name = "AcademyQuizOption_%s" % str(question.get("id", ""))
		for option_value in question.get("options", []):
			var option: Dictionary = option_value
			option_button.add_item(str(option.get("label", "")))
			option_button.set_item_metadata(option_button.get_item_count() - 1, str(option.get("id", "")))
		academy_quiz_option_buttons[str(question.get("id", ""))] = option_button
		block.add_child(option_button)
		academy_lesson_content_vbox.add_child(block)

	var submit_button := Button.new()
	submit_button.name = "AcademyQuizSubmitButton"
	submit_button.text = "Submit Quiz"
	submit_button.pressed.connect(_on_academy_quiz_submit_pressed)
	academy_lesson_content_vbox.add_child(submit_button)
	_style_button(submit_button, Color(0.27451, 0.219608, 0.0980392, 1), Color(0.819608, 0.631373, 0.254902, 1), COLOR_TEXT, 0)
	_apply_academy_button_padding(submit_button)


func _build_academy_glossary_section() -> void:
	academy_lesson_content_vbox.add_child(_build_academy_text_block("Searchable Glossary", "Search any technical term from this academy track."))
	var search_input := LineEdit.new()
	search_input.name = "AcademyGlossaryInlineSearchInput"
	search_input.placeholder_text = "Search glossary"
	search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	academy_lesson_content_vbox.add_child(search_input)
	var glossary_list := ItemList.new()
	glossary_list.name = "AcademyGlossaryInlineList"
	glossary_list.custom_minimum_size = Vector2(0, 260)
	glossary_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	academy_lesson_content_vbox.add_child(glossary_list)
	_populate_academy_glossary_list(glossary_list, "")
	search_input.text_changed.connect(func(new_text: String) -> void:
		_populate_academy_glossary_list(glossary_list, new_text)
	)
	_style_light_item_list(glossary_list)
	_style_line_input(search_input)


func _build_academy_text_block(title: String, body: String, infoboxes: Array = [], images: Array = []) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "AcademyTextBlock"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_academy_text_card(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	var title_label := Label.new()
	title_label.name = "AcademyTextBlockTitle"
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0.129412, 0.101961, 0.058824, 1))
	vbox.add_child(title_label)
	var body_label := Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.text = body
	body_label.add_theme_font_size_override("font_size", 14)
	body_label.add_theme_color_override("font_color", Color(0.352941, 0.309804, 0.203922, 1))
	vbox.add_child(body_label)
	for image_value in images:
		var image: Dictionary = image_value
		var image_path: String = str(image.get("asset_path", "")).strip_edges()
		var image_caption: String = str(image.get("caption", "")).strip_edges()
		var image_alt: String = str(image.get("alt", "Academy image")).strip_edges()
		vbox.add_child(_build_academy_text_inline_image_block(image_path, image_caption, image_alt))
	for infobox_value in infoboxes:
		var infobox: Dictionary = infobox_value
		var infobox_title: String = str(infobox.get("title", "")).strip_edges()
		var infobox_body: String = str(infobox.get("body", "")).strip_edges()
		if infobox_title.is_empty() and infobox_body.is_empty():
			continue
		vbox.add_child(_build_academy_infobox_card(infobox_title, infobox_body))
	return panel


func _build_academy_text_inline_image_block(asset_path: String, caption: String = "", alt_text: String = "") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "AcademyTextInlineImageBlock"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_academy_content_block(panel, Color(0.258824, 0.25098, 0.196078, 1), 1)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	var image_frame := PanelContainer.new()
	image_frame.name = "AcademyTextInlineImageFrame"
	image_frame.custom_minimum_size = Vector2(0, 150)
	image_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(image_frame)
	_style_academy_banner_frame(image_frame)
	var center := CenterContainer.new()
	image_frame.add_child(center)
	var image_texture: Texture2D = null
	if not asset_path.is_empty() and ResourceLoader.exists(asset_path):
		image_texture = load(asset_path) as Texture2D
	if image_texture != null:
		var texture_rect := TextureRect.new()
		texture_rect.name = "AcademyTextInlineImageTexture"
		texture_rect.texture = image_texture
		texture_rect.custom_minimum_size = Vector2(0, 140)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.tooltip_text = alt_text
		center.add_child(texture_rect)
	else:
		var placeholder := Label.new()
		placeholder.name = "AcademyTextInlineImagePlaceholder"
		placeholder.text = "IMAGE PLACEHOLDER" if asset_path.is_empty() else "MISSING IMAGE"
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.add_theme_color_override("font_color", Color(0.898039, 0.870588, 0.745098, 1))
		center.add_child(placeholder)
	if not caption.strip_edges().is_empty():
		var caption_label := Label.new()
		caption_label.name = "AcademyTextInlineImageCaption"
		caption_label.text = caption
		caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption_label.add_theme_color_override("font_color", Color(0.898039, 0.870588, 0.745098, 1))
		vbox.add_child(caption_label)
	return panel


func _build_academy_infobox_card(title: String, body: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "AcademyInfoboxCard"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_academy_infobox_card(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	if not title.is_empty():
		var title_label := Label.new()
		title_label.text = title
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.add_theme_color_override("font_color", COLOR_ACADEMY_BROWN)
		vbox.add_child(title_label)
	if not body.is_empty():
		var body_label := Label.new()
		body_label.text = body
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body_label.add_theme_color_override("font_color", Color(0.352941, 0.309804, 0.203922, 1))
		vbox.add_child(body_label)
	return panel


func _build_academy_key_insights_block(title: String, bullets: Array) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "AcademyKeyInsightsBlock"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_academy_key_insights_card(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	var title_label := Label.new()
	title_label.name = "AcademyKeyInsightsTitle"
	title_label.text = title if not title.strip_edges().is_empty() else "Key Insights"
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_color_override("font_color", Color(0.054902, 0.164706, 0.313726, 1))
	title_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title_label)
	for bullet_value in bullets:
		var bullet_text: String = str(bullet_value).strip_edges()
		if bullet_text.is_empty():
			continue
		var bullet_label := Label.new()
		bullet_label.text = "- %s" % bullet_text
		bullet_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bullet_label.add_theme_color_override("font_color", Color(0.07451, 0.156863, 0.270588, 1))
		vbox.add_child(bullet_label)
	return panel


func _build_academy_image_block(asset_path: String, caption: String = "", alt_text: String = "") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "AcademyImageBlock"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_academy_banner_frame(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	var image_frame := PanelContainer.new()
	image_frame.name = "AcademyInlineImageFrame"
	image_frame.custom_minimum_size = Vector2(0, 190)
	image_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(image_frame)
	_style_academy_banner_frame(image_frame)
	var center := CenterContainer.new()
	image_frame.add_child(center)
	var image_texture: Texture2D = null
	if not asset_path.is_empty() and ResourceLoader.exists(asset_path):
		image_texture = load(asset_path) as Texture2D
	if image_texture != null:
		var texture_rect := TextureRect.new()
		texture_rect.name = "AcademyInlineImageTexture"
		texture_rect.texture = image_texture
		texture_rect.custom_minimum_size = Vector2(0, 180)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.tooltip_text = alt_text
		center.add_child(texture_rect)
	else:
		var placeholder := Label.new()
		placeholder.name = "AcademyInlineImagePlaceholder"
		placeholder.text = "IMAGE PLACEHOLDER" if asset_path.is_empty() else "MISSING IMAGE"
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.add_theme_color_override("font_color", Color(0.898039, 0.870588, 0.745098, 1))
		center.add_child(placeholder)
	if not caption.strip_edges().is_empty():
		var caption_label := Label.new()
		caption_label.name = "AcademyInlineImageCaption"
		caption_label.text = caption
		caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption_label.add_theme_color_override("font_color", Color(0.898039, 0.870588, 0.745098, 1))
		vbox.add_child(caption_label)
	return panel


func _build_academy_example_block(title: String, example_type: String) -> PanelContainer:
	var body: String = "Practice: %s. Run the same read on live stock charts after you finish the lesson." % example_type.replace("_", " ")
	return _build_academy_text_block(title, body)


func _build_academy_check_block(section_id: String, check: Dictionary, stored_result: Dictionary) -> PanelContainer:
	var panel := _build_academy_text_block("Quick Check", str(check.get("question", "")))
	var vbox: VBoxContainer = panel.get_child(0).get_child(0) as VBoxContainer
	var options_row := HBoxContainer.new()
	options_row.add_theme_constant_override("separation", 6)
	vbox.add_child(options_row)
	for option_value in check.get("options", []):
		var option: Dictionary = option_value
		var button := Button.new()
		button.name = "AcademyQuickCheckOptionButton"
		button.text = str(option.get("label", "Answer"))
		button.pressed.connect(_on_academy_inline_check_pressed.bind(section_id, str(check.get("id", "")), str(option.get("id", ""))))
		options_row.add_child(button)
		_style_academy_quick_check_button(button)
	if not stored_result.is_empty():
		var result_label := Label.new()
		result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_label.text = "Saved answer: %s. %s" % [
			"Correct" if bool(stored_result.get("correct", false)) else "Not yet",
			str(stored_result.get("feedback", ""))
		]
		result_label.add_theme_color_override("font_color", COLOR_POSITIVE if bool(stored_result.get("correct", false)) else COLOR_NEGATIVE)
		vbox.add_child(result_label)
	return panel


func _refresh_academy_side_panel() -> void:
	var quiz: Dictionary = current_academy_snapshot.get("quiz", {})
	var badge: Dictionary = current_academy_snapshot.get("badge", {})
	academy_side_title_label.text = "Progress"
	var status_lines: Array = [
		"Quiz: %s" % ("passed" if bool(quiz.get("passed", false)) else ("locked" if bool(quiz.get("locked", true)) else "open")),
		"Attempts: %d" % int(quiz.get("attempts", 0)),
		"Best score: %d%%" % int(quiz.get("best_score_percent", 0))
	]
	if bool(current_academy_snapshot.get("progress", {}).get("badge_earned", false)):
		status_lines.append("Badge earned: %s" % str(badge.get("label", "Technical Basics")))
	academy_side_body_label.text = "\n".join(status_lines)
	academy_glossary_search_input.visible = selected_academy_category_id == "technical"
	academy_glossary_list.visible = selected_academy_category_id == "technical"
	_refresh_academy_glossary_results()


func _refresh_academy_glossary_results() -> void:
	if academy_glossary_list == null:
		return
	var query: String = academy_glossary_search_input.text if academy_glossary_search_input != null else ""
	_populate_academy_glossary_list(academy_glossary_list, query)


func _populate_academy_glossary_list(target_list: ItemList, query: String) -> void:
	target_list.clear()
	var rows: Array = GameManager.search_academy_glossary(query)
	if rows.is_empty():
		target_list.add_item("No matching terms.")
		target_list.set_item_disabled(0, true)
		return
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		target_list.add_item("%s - %s" % [str(row.get("term", "")), str(row.get("definition", ""))])
		target_list.set_item_metadata(index, row)


func _next_academy_section_id() -> String:
	var sections: Array = current_academy_snapshot.get("sections", [])
	for index in range(sections.size()):
		var section: Dictionary = sections[index]
		if str(section.get("id", "")) != selected_academy_section_id:
			continue
		for next_index in range(index + 1, sections.size()):
			var next_section: Dictionary = sections[next_index]
			if not bool(next_section.get("locked", false)):
				return str(next_section.get("id", ""))
	return ""


func _refresh_upgrades() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	if upgrade_cards_vbox == null:
		return
	for child in upgrade_cards_vbox.get_children():
		upgrade_cards_vbox.remove_child(child)
		child.queue_free()

	upgrade_title_label.text = "Upgrades"
	if not RunState.has_active_run():
		upgrade_cash_label.text = "No run loaded"
		upgrade_summary_label.text = "Start a run to buy upgrades."
		_apply_font_overrides_to_subtree(upgrade_window)
		_log_perf_elapsed("_refresh_upgrades", started_at_usec)
		return

	var snapshot: Dictionary = GameManager.get_upgrade_shop_snapshot()
	var action_snapshot: Dictionary = snapshot.get("daily_action", {})
	upgrade_cash_label.text = "Cash %s" % _format_currency(float(snapshot.get("cash", 0.0)))
	upgrade_summary_label.text = "Network AP %d/%d today. Upgrades are paid from available cash." % [
		int(action_snapshot.get("remaining", 0)),
		int(action_snapshot.get("limit", 10))
	]

	for track_value in snapshot.get("tracks", []):
		var track: Dictionary = track_value
		upgrade_cards_vbox.add_child(_build_upgrade_card(track))
	_apply_font_overrides_to_subtree(upgrade_cards_vbox)
	_log_perf_elapsed("_refresh_upgrades", started_at_usec)


func _build_upgrade_card(track: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "UpgradeCard_%s" % str(track.get("id", ""))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(panel, Color(0.968627, 0.964706, 0.898039, 1), 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 4)
	row.add_child(copy)

	var title := Label.new()
	title.text = "%s  |  Tier %d" % [str(track.get("label", "Upgrade")), int(track.get("tier", 4))]
	title.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	copy.add_child(title)

	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = "%s\nCurrent: %s" % [
		str(track.get("description", "")),
		str(track.get("effect_label", ""))
	]
	body.add_theme_color_override("font_color", Color(0.352941, 0.309804, 0.203922, 1))
	copy.add_child(body)

	var purchase_button := Button.new()
	purchase_button.name = "UpgradeBuyButton_%s" % str(track.get("id", ""))
	purchase_button.custom_minimum_size = Vector2(190, 44)
	if bool(track.get("maxed", false)):
		purchase_button.text = "Max Tier"
		purchase_button.disabled = true
	else:
		purchase_button.text = "Buy Tier %d\n%s" % [
			int(track.get("next_tier", 0)),
			_format_currency(float(track.get("next_cost", 0.0)))
		]
		purchase_button.disabled = not bool(track.get("can_purchase", false))
		purchase_button.tooltip_text = "Next: %s" % str(track.get("next_effect_label", ""))
		purchase_button.pressed.connect(_on_upgrade_purchase_pressed.bind(str(track.get("id", ""))))
	row.add_child(purchase_button)
	_style_button(purchase_button, Color(0.27451, 0.219608, 0.0980392, 1), Color(0.819608, 0.631373, 0.254902, 1), COLOR_TEXT, 0)
	return panel


func _upgrade_track_from_snapshot(snapshot: Dictionary, track_id: String) -> Dictionary:
	for track_value in snapshot.get("tracks", []):
		var track: Dictionary = track_value
		if str(track.get("id", "")) == track_id:
			return track
	return {}


func _rebuild_network_contact_list() -> void:
	network_contacts_list.clear()
	var rows: Array = []
	rows.append_array(current_network_snapshot.get("contacts", []))
	if rows.is_empty():
		selected_network_contact_id = ""
		network_contacts_list.add_item("No contacts yet. Meet a lead from News or a company Profile first.")
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
		network_requests_list.add_item("%s  |  %s  |  due day %d" % [
			str(request.get("status", "pending")).capitalize(),
			_ticker_for_company(str(request.get("target_company_id", ""))),
			int(request.get("due_day_index", 0))
		])
		network_requests_list.set_item_metadata(network_requests_list.item_count - 1, request.duplicate(true))
	if requests.is_empty():
		network_requests_list.add_item("No active requests.")
		network_requests_list.set_item_disabled(0, true)


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
		"request":
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
	var title_prefix: String = "Request" if row_type == "request" else "Journal"
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
	var detail: String = "Due day %d. Hold at least 1 lot of %s by the due day to complete this request." % [
		int(request.get("due_day_index", 0)),
		ticker
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
		network_contact_body_label.text = "Explore the world more. Read News, open company Profile pages, and follow referrals to discover people before they appear here."
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
	network_contact_meta_label.text = "%s  |  Relationship %d  |  Required recognition %d  |  Source %s" % [
		affiliation_label,
		int(contact.get("relationship", 0)),
		int(contact.get("recognition_required", 0)),
		str(contact.get("source_type", "network"))
	]
	var contact_body_text: String = str(contact.get("intro", ""))
	var last_tip_note: String = str(contact.get("last_tip_note", ""))
	if not last_tip_note.is_empty():
		contact_body_text += "\n\n%s" % last_tip_note
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
		if not company_id.is_empty() and str(row.get("target_company_id", "")) == company_id:
			return row
		if not company_id.is_empty() and company_id in row.get("target_company_ids", []):
			return row
	return {}


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
		context_label.name = "SocialContextHintLabel"
		context_label.text = context_hint
		context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		context_label.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
		context_label.add_theme_color_override("font_color", Color(0.345098, 0.384314, 0.458824, 1))
		content.add_child(context_label)

	var thread_lines: Array = post.get("thread_lines", [])
	if not thread_lines.is_empty():
		var thread_button: Button = Button.new()
		thread_button.name = "SocialThreadToggleButton"
		thread_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		thread_button.text = "Hide Thread" if bool(expanded_social_thread_ids.get(str(post.get("id", "")), false)) else "Thread"
		thread_button.tooltip_text = "Expand this Twooter thread."
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
			thread_line.add_theme_font_size_override("font_size", DEFAULT_APP_FONT_SIZE)
			thread_line.add_theme_color_override("font_color", Color(0.094118, 0.141176, 0.207843, 1))
			thread_container.add_child(thread_line)
		thread_button.pressed.connect(func() -> void:
			_on_social_thread_toggled(str(post.get("id", "")), thread_container, thread_button)
		)

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


func _on_social_thread_toggled(post_id: String, thread_container: VBoxContainer, thread_button: Button) -> void:
	var next_visible: bool = not thread_container.visible
	thread_container.visible = next_visible
	expanded_social_thread_ids[post_id] = next_visible
	thread_button.text = "Hide Thread" if next_visible else "Thread"


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
		if news_detail_byline_label != null:
			news_detail_byline_label.text = ""
		if news_detail_chips_label != null:
			news_detail_chips_label.text = ""
		_set_news_detail_hero_slot("")
		news_detail_body.text = "Choose a story from the list."
		news_detail_hint_label.text = ""
		news_detail_hint_label.visible = false
		news_meet_contact_button.visible = false
		news_meet_contact_button.disabled = true
		news_meet_contact_button.set_meta("contact_id", "")
		if news_open_meeting_button != null:
			news_open_meeting_button.visible = false
			news_open_meeting_button.disabled = true
			news_open_meeting_button.set_meta("meeting_id", "")
		return

	var trade_date: Dictionary = article.get("trade_date", {})
	var trade_date_text: String = ""
	if not trade_date.is_empty():
		trade_date_text = GameManager.format_trade_date(trade_date)

	news_detail_outlet_label.text = str(article.get("outlet_label", "News"))
	news_detail_headline_label.text = str(article.get("headline", ""))
	news_detail_deck_label.text = str(article.get("deck", ""))
	news_detail_meta_label.text = trade_date_text
	if news_detail_byline_label != null:
		news_detail_byline_label.text = _news_byline_text(article)
	if news_detail_chips_label != null:
		news_detail_chips_label.text = _news_article_chip_line(article)
	_set_news_detail_hero_slot(str(article.get("image_slot", "brief")))
	news_detail_body.text = str(article.get("body", ""))
	GameManager.discover_network_contacts_from_article(article)
	var contact: Dictionary = _contact_for_context("news", str(article.get("id", "")), str(article.get("target_company_id", "")))
	news_meet_contact_button.visible = not contact.is_empty()
	news_meet_contact_button.disabled = contact.is_empty() or not bool(contact.get("can_meet", false))
	news_meet_contact_button.text = "Meet Source" if not contact.is_empty() else "Meet Source"
	news_meet_contact_button.set_meta("contact_id", str(contact.get("id", "")))
	if news_open_meeting_button != null:
		var meeting_id: String = str(article.get("meeting_id", ""))
		var meeting_detail: Dictionary = GameManager.get_corporate_meeting_detail(meeting_id) if not meeting_id.is_empty() else {}
		var meeting_blocked_reason: String = _corporate_meeting_open_blocked_reason(meeting_detail)
		news_open_meeting_button.visible = not meeting_id.is_empty()
		news_open_meeting_button.disabled = meeting_id.is_empty() or not meeting_blocked_reason.is_empty()
		news_open_meeting_button.text = "Shareholders Only" if not meeting_blocked_reason.is_empty() else (_news_meeting_action_label(article) if not meeting_id.is_empty() else "View Notice")
		news_open_meeting_button.tooltip_text = meeting_blocked_reason if not meeting_blocked_reason.is_empty() else "Open the linked corporate meeting."
		news_open_meeting_button.set_meta("meeting_id", meeting_id)
	if not contact.is_empty():
		news_detail_hint_label.text = "Source lead: %s, %s." % [
			str(contact.get("display_name", "")),
			str(contact.get("role", ""))
		]
		news_detail_hint_label.visible = true
	else:
		news_detail_hint_label.text = ""
		news_detail_hint_label.visible = false


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
	return "  |  ".join(parts)


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
	return "  /  ".join(chips)


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


func _rebuild_news_article_cards(articles: Array) -> void:
	if news_article_cards == null:
		return
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
	for article_value in articles:
		var article: Dictionary = article_value
		news_article_cards.add_child(_build_news_article_card(article))
	if news_article_cards_scroll != null and news_article_cards_scroll.get_v_scroll_bar() != null:
		news_article_cards_scroll.get_v_scroll_bar().value = 0.0


func _build_news_article_card(article: Dictionary) -> PanelContainer:
	var article_id: String = str(article.get("id", ""))
	var card := PanelContainer.new()
	card.name = "NewsArticleCard_%s" % article_id.replace("|", "_")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_news_article_card(card, article_id == selected_news_article_id)

	var margin := MarginContainer.new()
	margin.name = "NewsArticleCardMargin"
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "NewsArticleCardVBox"
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	var image_frame := PanelContainer.new()
	image_frame.name = "NewsArticleCardImageFrame"
	image_frame.custom_minimum_size = Vector2(0, 64)
	image_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_news_asset_frame(image_frame)
	vbox.add_child(image_frame)
	var image_label := Label.new()
	image_label.name = "NewsArticleCardImagePlaceholder"
	image_label.text = _news_image_slot_label(str(article.get("image_slot", "brief")))
	image_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	image_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_set_label_tone(image_label, Color(0.454902, 0.337255, 0.141176, 1))
	image_frame.add_child(image_label)

	var status_label := Label.new()
	status_label.name = "NewsArticleCardStatusLabel"
	status_label.text = _news_article_status_line(article)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_tone(status_label, Color(0.454902, 0.337255, 0.141176, 1))
	vbox.add_child(status_label)

	var headline_label := Label.new()
	headline_label.name = "NewsArticleCardHeadlineLabel"
	headline_label.text = str(article.get("headline", ""))
	headline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font_override_to_control(headline_label, 15, _get_app_font())
	_set_label_tone(headline_label, COLOR_WINDOW_TEXT)
	vbox.add_child(headline_label)

	var deck_label := Label.new()
	deck_label.name = "NewsArticleCardDeckLabel"
	deck_label.text = str(article.get("deck", ""))
	deck_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_tone(deck_label, Color(0.352941, 0.309804, 0.203922, 1))
	vbox.add_child(deck_label)

	var byline_label := Label.new()
	byline_label.name = "NewsArticleCardBylineLabel"
	byline_label.text = _news_byline_text(article)
	byline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_tone(byline_label, Color(0.454902, 0.337255, 0.141176, 1))
	vbox.add_child(byline_label)

	var read_button := Button.new()
	read_button.name = "NewsArticleCardReadButton"
	read_button.text = "Read Story"
	read_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	read_button.pressed.connect(_on_news_article_card_pressed.bind(article_id))
	_style_button(read_button, Color(0.866667, 0.807843, 0.635294, 1), Color(0.709804, 0.607843, 0.345098, 1), COLOR_WINDOW_TEXT, 0)
	vbox.add_child(read_button)
	return card


func _on_news_article_card_pressed(article_id: String) -> void:
	if article_id.is_empty():
		return
	selected_news_article_id = article_id
	var articles: Array = _current_news_archive_article_summaries()
	for article_index in range(articles.size()):
		if str(articles[article_index].get("id", "")) == article_id:
			news_article_list.select(article_index)
			break
	_rebuild_news_article_cards(articles)
	_show_news_article(GameManager.get_news_archive_article(selected_news_article_id))


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
		_refresh_dashboard_calendar({})
		_refresh_dashboard_movers([])
		_refresh_dashboard_sector_panel([])
		_log_perf_phase(log_phase_details, "_refresh_dashboard:no_active_run", started_at_usec)
		return

	var index_snapshot: Dictionary = _build_dashboard_index_snapshot()
	_log_perf_phase(log_phase_details, "_refresh_dashboard:index_snapshot", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var company_rows: Array = _get_company_rows_cached()
	_log_perf_phase(log_phase_details, "_refresh_dashboard:company_rows", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var trade_date: Dictionary = GameManager.get_current_trade_date()
	var dashboard_event_snapshot: Dictionary = GameManager.get_dashboard_event_snapshot()
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
	_refresh_dashboard_calendar(
		trade_date,
		dashboard_event_snapshot.get("report_calendar_snapshot", {}),
		dashboard_event_snapshot.get("upcoming_meeting_rows", [])
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
	panel.gui_input.connect(_on_dashboard_sector_card_gui_input.bind(sector_id))
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


func _on_dashboard_sector_card_gui_input(event: InputEvent, sector_id: String) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			selected_dashboard_sector_id = sector_id
			_refresh_dashboard_sector_panel(_get_company_rows_cached())
			get_viewport().set_input_as_handled()


func _on_dashboard_sector_back_pressed() -> void:
	selected_dashboard_sector_id = ""
	_refresh_dashboard_sector_panel(_get_company_rows_cached())


func _build_dashboard_index_snapshot() -> Dictionary:
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
		"sparkline_points": _build_dashboard_index_sparkline_points()
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
	dashboard_movers_tabs.set_tab_title(0, "Top 15 Gainer")
	dashboard_movers_tabs.set_tab_title(1, "Top 15 Loser")
	_refresh_dashboard_mover_side(company_rows, true)
	_refresh_dashboard_mover_side(company_rows, false)


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


func _refresh_dashboard_calendar(
	current_date: Dictionary,
	cached_report_snapshot: Dictionary = {},
	meeting_rows: Array = []
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
		dashboard_calendar_days_grid.add_child(_build_dashboard_calendar_day_cell(
			day_value,
			is_current_day,
			is_trade_day,
			day_reports,
			day_meetings,
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


func _format_calendar_event_tooltip(reports: Array, meetings: Array) -> String:
	if reports.is_empty() and meetings.is_empty():
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
	date_info: Dictionary = {}
) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "DashboardCalendarDay_%02d" % day_value
	panel.custom_minimum_size = Vector2(0, DASHBOARD_CALENDAR_CELL_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.tooltip_text = _format_calendar_event_tooltip(reports, meetings)
	panel.set_meta("day", day_value)
	panel.set_meta("report_count", reports.size())
	panel.set_meta("meeting_count", meetings.size())
	panel.set_meta("has_events", not reports.is_empty() or not meetings.is_empty())
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
		meetings.duplicate(true)
	))

	var label: Label = Label.new()
	label.text = str(day_value)
	var badges: Array = []
	if not reports.is_empty():
		badges.append("%dR" % reports.size())
	if not meetings.is_empty():
		badges.append("%dM" % meetings.size())
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
	if not reports.is_empty() or not meetings.is_empty():
		fill_color = Color(0.192157, 0.152941, 0.0823529, 0.96)
		border_color = COLOR_WARNING
		text_color = Color(1, 0.941176, 0.760784, 1)
	if reports.is_empty() and not meetings.is_empty():
		fill_color = Color(0.0901961, 0.164706, 0.168627, 0.96)
		border_color = COLOR_ACCENT
		text_color = Color(0.815686, 0.933333, 1, 1)
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
	meetings: Array
) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			_show_dashboard_calendar_event_popup(date_info, reports, meetings)
			get_viewport().set_input_as_handled()


func _show_dashboard_calendar_event_popup(date_info: Dictionary, reports: Array, meetings: Array) -> void:
	_ensure_dashboard_calendar_event_popup()
	if dashboard_calendar_event_popup == null:
		return
	if dashboard_calendar_event_title_label != null:
		dashboard_calendar_event_title_label.text = GameManager.format_trade_date(date_info)
	if dashboard_calendar_event_body_label != null:
		dashboard_calendar_event_body_label.text = _build_dashboard_calendar_event_popup_body(reports, meetings)
	_refresh_dashboard_calendar_event_actions(meetings)
	dashboard_calendar_event_popup.visible = true
	dashboard_calendar_event_popup.move_to_front()


func _hide_dashboard_calendar_event_popup() -> void:
	if dashboard_calendar_event_popup != null:
		dashboard_calendar_event_popup.visible = false


func _build_dashboard_calendar_event_popup_body(reports: Array, meetings: Array) -> String:
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
	var started_at_usec: int = Time.get_ticks_usec()
	var company_rows: Array = _get_company_rows_cached()
	var company_row_lookup: Dictionary = _get_company_row_lookup_cached()
	_refresh_company_list(company_rows, company_row_lookup)
	_refresh_trade_workspace()
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


func _on_company_detail_ready(company_id: String) -> void:
	if company_id.is_empty():
		return
	if company_id == selected_company_id:
		_refresh_trade_workspace()
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
	_refresh_debug_corporate_action_controls()
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
	debug_start_rupslb_button = null
	debug_start_rupslb_status_label = null
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
	_build_debug_corporate_action_controls()
	_refresh_debug_corporate_action_controls()


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


func _build_debug_corporate_action_controls() -> void:
	if debug_generator_groups == null:
		return
	var group_label := Label.new()
	group_label.name = "DebugCorporateActionsLabel"
	group_label.text = "Corporate Actions"
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

	var action_button := Button.new()
	action_button.name = "DebugStartRupslbButton"
	action_button.custom_minimum_size = Vector2(170, 34)
	action_button.text = "Start RUPSLB"
	action_button.pressed.connect(_on_debug_start_rupslb_pressed)
	_style_button(action_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	debug_generator_groups.add_child(action_button)
	debug_start_rupslb_button = action_button


func _refresh_debug_corporate_action_controls() -> void:
	if debug_start_rupslb_button == null or debug_start_rupslb_status_label == null:
		return
	var state: Dictionary = _debug_rupslb_target_state()
	debug_start_rupslb_button.disabled = not bool(state.get("enabled", false))
	debug_start_rupslb_button.tooltip_text = str(state.get("tooltip_text", "Schedule a next-day rights issue RUPSLB for the selected held stock."))
	debug_start_rupslb_status_label.text = str(state.get("status_text", "Pick a stock first."))


func _debug_rupslb_target_state() -> Dictionary:
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
			"status_text": "Target: none | Pick a stock first.",
			"tooltip_text": "Select a valid stock in STOCKBOT first."
		}
	var ticker: String = str(definition.get("ticker", selected_company_id.to_upper()))
	var holding: Dictionary = RunState.get_holding(selected_company_id)
	var lot_size: int = max(GameManager.get_lot_size(), 1)
	var shares: int = int(holding.get("shares", 0))
	var lots_owned: int = int(floor(float(shares) / float(lot_size)))
	if shares < lot_size:
		return {
			"enabled": false,
			"company_id": selected_company_id,
			"ticker": ticker,
			"status_text": "Target: %s | Own at least 1 lot first." % ticker,
			"tooltip_text": "Buy at least 1 lot of %s before scheduling the debug RUPSLB." % ticker
		}
	var corporate_action_snapshot: Dictionary = GameManager.get_company_corporate_action_snapshot(selected_company_id)
	if bool(corporate_action_snapshot.get("has_live_chain", false)):
		return {
			"enabled": false,
			"company_id": selected_company_id,
			"ticker": ticker,
			"status_text": "Target: %s | That company already has a live corporate action." % ticker,
			"tooltip_text": "Finish or clear the current corporate-action chain before forcing another one."
		}
	var next_trade_date: Dictionary = portfolio_trading_calendar.advance_trade_days(GameManager.get_current_trade_date(), 1)
	return {
		"enabled": true,
		"company_id": selected_company_id,
		"ticker": ticker,
		"status_text": "Target: %s | Held %d lot(s) | Schedules RUPSLB for %s." % [
			ticker,
			lots_owned,
			GameManager.format_trade_date(next_trade_date)
		],
		"tooltip_text": "Schedule a next-day rights issue RUPSLB for %s." % ticker
	}


func _on_debug_start_rupslb_pressed() -> void:
	var state: Dictionary = _debug_rupslb_target_state()
	if not bool(state.get("enabled", false)):
		_show_toast(str(state.get("status_text", "Could not schedule RUPSLB.")), false)
		_refresh_debug_corporate_action_controls()
		return
	var company_id: String = str(state.get("company_id", ""))
	var result: Dictionary = GameManager.debug_schedule_next_day_rights_issue_rupslb(company_id)
	_show_toast(str(result.get("message", "Debug corporate action updated.")), bool(result.get("success", false)))
	_refresh_debug_overlay()
	if not bool(result.get("success", false)):
		return
	_refresh_dashboard()
	_refresh_news()
	_refresh_network()


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
	if company_rows.is_empty() and RunState.has_active_run():
		company_rows = _get_company_rows_cached()
	if company_row_lookup.is_empty() and not company_rows.is_empty():
		company_row_lookup = _build_company_row_lookup(company_rows)
	var watchlist_lookup: Dictionary = _build_watchlist_lookup()
	_refresh_watchlist_rows(company_rows, watchlist_lookup)
	if refresh_all_stock_rows:
		_refresh_all_stock_rows(company_rows, watchlist_lookup)
	if refresh_portfolio_sidebar:
		_refresh_portfolio_stock_rows(GameManager.get_portfolio_snapshot().get("holdings", []), company_row_lookup)


func _refresh_watchlist_rows(company_rows: Array, watchlist_lookup: Dictionary) -> void:
	displayed_company_ids.clear()
	company_list.clear()
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
	_refresh_watchlist_action_state(watchlist_lookup)


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
		add_button.text = "Added" if is_in_watchlist else "Add"
		add_button.disabled = is_in_watchlist
		_style_button(
			add_button,
			Color(0.164706, 0.215686, 0.278431, 1) if is_in_watchlist else Color(0.117647, 0.32549, 0.239216, 1),
			COLOR_BORDER,
			COLOR_TEXT,
			0
		)
		var add_callable: Callable = Callable(self, "_on_add_to_watchlist_pressed").bind(company_id)
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
		select_button.pressed.connect(_on_portfolio_stock_selected.bind(company_id))
		portfolio_stocks_rows.add_child(select_button)

	portfolio_stocks_empty_label.visible = not has_holdings
	_apply_font_overrides_to_subtree(portfolio_stocks_rows)


func _refresh_company_selection_state() -> void:
	var selected_index: int = displayed_company_ids.find(selected_company_id)
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


func _request_selected_company_detail(priority: bool = true) -> void:
	if selected_company_id.is_empty():
		return
	if str(RunState.get_company_detail_status(selected_company_id)) == "ready":
		return
	var priority_ids: Array = [selected_company_id] if priority else []
	GameManager.start_background_company_detail_hydration(priority_ids)


func _refresh_trade_workspace() -> void:
	_request_selected_company_detail()
	var snapshot: Dictionary = GameManager.get_company_snapshot(selected_company_id, true, true, true)
	_apply_trade_workspace_snapshot(snapshot)


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
	current_trade_snapshot = snapshot
	trade_workspace_widget.set_company_snapshot(snapshot)
	if snapshot.is_empty():
		current_trade_snapshot = {}
		selected_financial_statement_company_id = ""
		selected_financial_statement_index = -1
		active_order_side = "buy"
		order_company_name_label.text = "NO SELECTION"
		selection_label.text = "-"
		order_price_value_label.text = _format_currency(0.0)
		order_price_change_label.text = "%s  |  +0.00%%" % _format_signed_currency(0.0)
		order_position_label.text = "Pick a stock first so the order ticket can price the trade."
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
		profile_price_label.text = "Price:"
		profile_factor_label.text = "Company profile:"
		profile_management_label.text = "Management:"
		profile_shareholders_label.text = "Major Shareholders:"
		profile_tags_label.text = "Tags:"
		profile_description_label.text = "Description:"
		profile_network_hint_label.text = ""
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
		_refresh_statement_sections({})
		_set_label_tone(profile_price_label, COLOR_TEXT)
		return

	var detail_status: String = str(snapshot.get("detail_status", "ready"))
	var detail_ready: bool = detail_status == "ready"
	var financial_statement_snapshot: Dictionary = snapshot.get("financial_statement_snapshot", {}) if detail_ready else {}
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
	if detail_ready:
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
	else:
		profile_factor_label.text = "Company profile: preparing company profile..."
		profile_tags_label.text = "Tags: preparing company tags..."
	profile_management_label.text = _format_profile_management(snapshot)
	profile_shareholders_label.text = _format_profile_shareholders(snapshot)
	profile_description_label.text = "Description: %s" % (
		str(snapshot.get("profile_description", "No generated profile description for this company."))
		if detail_ready
		else "Preparing company profile..."
	)
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
	_refresh_financial_history_table(
		snapshot.get("financial_history", []),
		snapshot.get("financials", {}),
		"Generating company detail..." if not detail_ready else ""
	)
	_refresh_key_stats_dashboard(snapshot if detail_ready else {})
	_refresh_broker_table(snapshot.get("broker_flow", {}))
	_refresh_statement_sections(financial_statement_snapshot)
	if not detail_ready:
		financials_period_label.text = "Detailed quarterly statements will appear once the company profile finishes generating."
	_refresh_order_controls(snapshot)
	_set_label_tone(profile_price_label, _color_for_change(float(snapshot.get("daily_change_pct", 0.0))))


func _refresh_profile_network_contact(company_id: String) -> void:
	if company_id.is_empty():
		profile_network_hint_label.text = ""
		profile_meet_contact_button.visible = false
		profile_meet_contact_button.disabled = true
		profile_meet_contact_button.set_meta("contact_id", "")
		return

	GameManager.discover_network_contacts_for_company(company_id)
	var contact: Dictionary = _contact_for_context("profile", company_id, company_id)
	profile_meet_contact_button.visible = not contact.is_empty()
	profile_meet_contact_button.disabled = contact.is_empty() or not bool(contact.get("can_meet", false))
	profile_meet_contact_button.text = "Meet %s" % str(contact.get("display_name", "Contact")) if not contact.is_empty() else "Meet Contact"
	profile_meet_contact_button.set_meta("contact_id", str(contact.get("id", "")))
	if contact.is_empty():
		profile_network_hint_label.text = "Network: no contact lead from this profile yet."
	else:
		profile_network_hint_label.text = "Network lead: %s, %s." % [
			str(contact.get("display_name", "")),
			str(contact.get("role", ""))
		]


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
	var lines: Array = ["Major Shareholders:"]
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


func _on_stock_app_pressed() -> void:
	_set_active_app(APP_ID_STOCK)


func _on_news_app_pressed() -> void:
	_set_active_app(APP_ID_NEWS)


func _on_social_app_pressed() -> void:
	_set_active_app(APP_ID_SOCIAL)


func _on_network_app_pressed() -> void:
	_set_active_app(APP_ID_NETWORK)


func _on_academy_app_pressed() -> void:
	_set_active_app(APP_ID_ACADEMY)


func _on_thesis_app_pressed() -> void:
	_set_active_app(APP_ID_THESIS)


func _on_life_app_pressed() -> void:
	_set_active_app(APP_ID_LIFE)


func _on_upgrades_app_pressed() -> void:
	_set_active_app(APP_ID_UPGRADES)


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
	selected_academy_category_id = category_id
	selected_academy_section_id = ""
	_refresh_academy()


func _on_academy_section_selected(index: int) -> void:
	var metadata: Variant = academy_section_list.get_item_metadata(index)
	if typeof(metadata) != TYPE_DICTIONARY:
		return
	var section: Dictionary = metadata
	if bool(section.get("locked", false)):
		return
	selected_academy_section_id = str(section.get("id", ""))
	_refresh_academy()


func _on_academy_section_tab_pressed(section_id: String) -> void:
	if section_id.is_empty():
		return
	selected_academy_section_id = section_id
	_refresh_academy()


func _on_academy_mark_read_pressed() -> void:
	var result: Dictionary = GameManager.mark_academy_section_read(selected_academy_category_id, selected_academy_section_id)
	_show_toast(str(result.get("message", "Academy updated.")), bool(result.get("success", false)))
	_refresh_academy()


func _on_academy_next_pressed() -> void:
	var next_section_id: String = _next_academy_section_id()
	if next_section_id.is_empty():
		return
	selected_academy_section_id = next_section_id
	_refresh_academy()


func _on_academy_inline_check_pressed(section_id: String, check_id: String, answer_id: String) -> void:
	var result: Dictionary = GameManager.submit_academy_inline_check(selected_academy_category_id, section_id, check_id, answer_id)
	_show_toast(str(result.get("feedback", result.get("message", "Answer saved."))), bool(result.get("correct", false)))
	_refresh_academy()


func _on_academy_quiz_submit_pressed() -> void:
	var answers: Dictionary = {}
	for question_id_value in academy_quiz_option_buttons.keys():
		var question_id: String = str(question_id_value)
		var option_button: OptionButton = academy_quiz_option_buttons[question_id]
		if option_button.selected >= 0:
			answers[question_id] = str(option_button.get_item_metadata(option_button.selected))
	var result: Dictionary = GameManager.submit_academy_quiz(selected_academy_category_id, answers)
	if not bool(result.get("success", false)):
		_show_toast(str(result.get("message", "Quiz could not be submitted.")), false)
		_refresh_academy()
		return
	var message: String = "Quiz score %d%%. %s" % [
		int(result.get("score_percent", 0)),
		"Technical Basics earned." if bool(result.get("passed", false)) else "Review and try again."
	]
	_show_toast(message, bool(result.get("passed", false)))
	_refresh_academy()
	_show_academy_quiz_feedback(result.get("feedback", []), bool(result.get("passed", false)), int(result.get("score_percent", 0)))


func _show_academy_quiz_feedback(feedback_rows: Array, passed: bool, score_percent: int) -> void:
	_clear_container_children(academy_lesson_content_vbox)
	academy_lesson_content_vbox.add_child(_build_academy_text_block(
		"Quiz Result",
		"Score: %d%%. %s" % [score_percent, "Passed. Technical Basics is now earned." if passed else "Not yet. Review the feedback and retry."]
	))
	for feedback_value in feedback_rows:
		var feedback: Dictionary = feedback_value
		academy_lesson_content_vbox.add_child(_build_academy_text_block(
			"%s - %s" % [str(feedback.get("prompt", "Question")), "Correct" if bool(feedback.get("correct", false)) else "Review"],
			str(feedback.get("feedback", ""))
		))


func _on_academy_glossary_search_changed(_new_text: String) -> void:
	_refresh_academy_glossary_results()


func _on_upgrade_purchase_pressed(track_id: String) -> void:
	_ensure_upgrade_purchase_dialog()
	var snapshot: Dictionary = GameManager.get_upgrade_shop_snapshot()
	var track: Dictionary = _upgrade_track_from_snapshot(snapshot, track_id)
	if track.is_empty():
		_show_toast("Upgrade track not found.", false)
		_refresh_upgrades()
		return
	if bool(track.get("maxed", false)):
		_show_toast("%s is already tier 1." % str(track.get("label", "Upgrade")), false)
		_refresh_upgrades()
		return
	if not bool(track.get("can_purchase", false)):
		_show_toast(
			"Need %s for %s." % [
				_format_currency(float(track.get("next_cost", 0.0))),
				str(track.get("label", "this upgrade"))
			],
			false
		)
		_refresh_upgrades()
		return

	pending_upgrade_track_id = track_id
	var cost: float = float(track.get("next_cost", 0.0))
	var cash: float = float(snapshot.get("cash", 0.0))
	upgrade_purchase_body_label.text = "Buy %s Tier %d?\n\nCurrent: Tier %d - %s\nNext: Tier %d - %s\nCost: %s\nCash after purchase: %s" % [
		str(track.get("label", "Upgrade")),
		int(track.get("next_tier", 0)),
		int(track.get("tier", 4)),
		str(track.get("effect_label", "")),
		int(track.get("next_tier", 0)),
		str(track.get("next_effect_label", "")),
		_format_currency(cost),
		_format_currency(cash - cost)
	]
	upgrade_purchase_dialog.popup_centered(Vector2i(560, 260))


func _on_upgrade_purchase_confirmed() -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	if pending_upgrade_track_id.is_empty():
		_show_toast("No upgrade selected.", false)
		return

	var track_id: String = pending_upgrade_track_id
	pending_upgrade_track_id = ""
	var result: Dictionary = GameManager.purchase_upgrade(track_id)
	if upgrade_purchase_dialog != null:
		upgrade_purchase_dialog.hide()
	_show_toast(str(result.get("message", "Upgrade updated.")), bool(result.get("success", false)))
	_log_perf_elapsed("_on_upgrade_purchase_confirmed", started_at_usec)


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
	_rebuild_news_article_cards(articles)
	_show_news_article(GameManager.get_news_archive_article(selected_news_article_id))


func _on_news_meet_contact_pressed() -> void:
	var contact_id: String = str(news_meet_contact_button.get_meta("contact_id", ""))
	_meet_contact_from_context(contact_id, {"source_type": "news", "source_id": selected_news_article_id})


func _on_news_open_meeting_pressed() -> void:
	if news_open_meeting_button == null:
		return
	_open_corporate_meeting_modal(str(news_open_meeting_button.get_meta("meeting_id", "")))


func _on_profile_meet_contact_pressed() -> void:
	var contact_id: String = str(profile_meet_contact_button.get_meta("contact_id", ""))
	_meet_contact_from_context(contact_id, {"source_type": "profile", "source_id": selected_company_id})


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


func _close_rupslb_meeting_overlay() -> void:
	if not current_corporate_meeting_id.is_empty():
		GameManager.close_corporate_meeting_session(current_corporate_meeting_id)
	current_corporate_meeting_id = ""
	if rupslb_meeting_overlay != null:
		rupslb_meeting_overlay.visible = false


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
	var intel: Dictionary = detail.get("intel", {})
	var intel_text: String = "No private intel recorded yet."
	if not intel.is_empty():
		intel_text = _format_corporate_intel_text(intel)
	corporate_meeting_intel_label.text = "Private Intel\n%s" % intel_text
	var attended: bool = bool(detail.get("attended", false))
	var requires_shareholder: bool = bool(detail.get("requires_shareholder", false))
	var attendance_eligible: bool = bool(detail.get("attendance_eligible", true))
	var attendance_text: String = "Attendance is open in this milestone."
	if attended:
		attendance_text = "Already marked as attended."
	elif requires_shareholder and not attendance_eligible:
		attendance_text = str(detail.get("attendance_blocked_reason", "Shareholder ownership is required to attend this meeting."))
	elif requires_shareholder:
		attendance_text = "Shareholder verified: %d share(s) held." % int(detail.get("player_shares_owned", 0))
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


func _format_corporate_intel_text(intel: Dictionary) -> String:
	var lines: Array = []
	var family_id: String = str(intel.get("family", ""))
	if not family_id.is_empty():
		lines.append("Family: %s" % family_id.replace("_", " ").capitalize())
	var truth_level: String = str(intel.get("best_known_truth_level", intel.get("truth_level", "")))
	if not truth_level.is_empty():
		lines.append("Truth: %s" % truth_level)
	var state: String = str(intel.get("best_known_current_timeline_state", intel.get("current_timeline_state", "")))
	if not state.is_empty():
		lines.append("State: %s" % state.replace("_", " "))
	var stance: String = str(intel.get("best_known_management_stance", intel.get("management_stance", "")))
	if not stance.is_empty():
		lines.append("Management: %s" % stance)
	var next_step: String = str(intel.get("best_known_next_expected_step", intel.get("next_expected_step", "")))
	if not next_step.is_empty():
		lines.append("Next: %s" % next_step)
	return "\n".join(lines)


func _meet_contact_from_context(contact_id: String, source_context: Dictionary) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	if contact_id.is_empty():
		_show_toast("No contact lead is available here.", false)
		return
	var result: Dictionary = GameManager.meet_contact(contact_id, source_context)
	_show_toast(str(result.get("message", "Network updated.")), bool(result.get("success", false)))
	_log_perf_elapsed("_meet_contact_from_context", started_at_usec)


func _network_contact_target_company(contact: Dictionary) -> String:
	var target_company_id: String = str(contact.get("target_company_id", ""))
	if not target_company_id.is_empty():
		return target_company_id
	var affiliated_company_id: String = str(contact.get("affiliated_company_id", contact.get("company_id", "")))
	if not affiliated_company_id.is_empty():
		return affiliated_company_id
	return selected_company_id


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
	if suppress_stock_list_tab_refresh:
		suppress_stock_list_tab_refresh = false
		return
	var started_at_usec: int = Time.get_ticks_usec()
	var previous_selected_company_id: String = selected_company_id
	_sync_selected_company_with_active_stock_list()
	_refresh_company_selection_state()
	if selected_company_id != previous_selected_company_id:
		_refresh_trade_workspace()
		_refresh_dashboard()
		_refresh_desktop()
		if debug_overlay.visible:
			_refresh_debug_overlay()
		_start_background_company_detail_hydration()
	_log_perf_elapsed("_on_stock_list_tab_changed", started_at_usec)


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


func _on_portfolio_stock_selected(company_id: String) -> void:
	selected_company_id = company_id
	_refresh_after_company_selection()


func _on_add_to_watchlist_pressed(company_id: String) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var result: Dictionary = GameManager.add_company_to_watchlist(company_id)
	_show_toast(str(result.get("message", "Watchlist updated.")), bool(result.get("success", false)))
	_log_perf_elapsed("_on_add_to_watchlist_pressed", started_at_usec)


func _on_all_stock_search_text_changed(_new_text: String) -> void:
	_refresh_company_list(_get_company_rows_cached(), _get_company_row_lookup_cached(), true, false)


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
	var started_at_usec: int = Time.get_ticks_usec()
	var result: Dictionary = {}
	if active_order_side == "sell":
		result = GameManager.sell_lots(selected_company_id, _selected_lots())
	else:
		result = GameManager.buy_lots(selected_company_id, _selected_lots())
	status_message = str(result.get("message", "Order finished."))
	_show_toast(status_message, bool(result.get("success", false)))
	_log_perf_elapsed("_on_submit_order_pressed", started_at_usec)


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
	var started_at_usec: int = Time.get_ticks_usec()
	advance_day_processing = true
	pending_daily_recap_snapshot = {}
	_set_advance_day_phase("Closing Market", false)
	_play_advance_day_button_feedback()
	await get_tree().process_frame
	_set_advance_day_phase("Printing News")
	await get_tree().process_frame
	_set_advance_day_phase("Updating Contacts")
	await get_tree().process_frame
	_set_advance_day_phase("Saving Run")
	await get_tree().process_frame
	GameManager.advance_day_deferred_save()
	if advance_day_processing:
		_finish_advance_day_processing()
		_schedule_advance_day_post_recap_save_flush()
	_log_perf_elapsed("_on_next_day_pressed", started_at_usec)


func _on_day_progressed(_day_index: int) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	status_message = "Market closed."
	_suppress_next_portfolio_refresh()
	if _is_desktop_app_window_open(APP_ID_NEWS):
		selected_news_archive_year = 0
		selected_news_archive_month = 0
		selected_news_article_id = ""
	if advance_day_processing:
		_queue_deferred_open_app_refresh()
		_refresh_all(false)
	else:
		_refresh_all()
	_log_perf_elapsed("_on_day_progressed", started_at_usec)


func _on_summary_ready(_summary: Dictionary) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var phase_started_at_usec: int = started_at_usec
	_refresh_dashboard()
	_log_perf_phase(advance_day_processing, "_on_summary_ready:dashboard", phase_started_at_usec)
	if advance_day_processing:
		phase_started_at_usec = Time.get_ticks_usec()
		pending_daily_recap_snapshot = GameManager.get_daily_recap_snapshot()
		_log_perf_phase(true, "_on_summary_ready:daily_recap_snapshot", phase_started_at_usec)
		phase_started_at_usec = Time.get_ticks_usec()
		_finish_advance_day_processing()
		_log_perf_phase(true, "_on_summary_ready:finish_processing", phase_started_at_usec)
		call_deferred("_show_daily_recap_if_pending")
		_schedule_advance_day_post_recap_save_flush()
	_log_perf_elapsed("_on_summary_ready", started_at_usec)


func _set_advance_day_phase(label: String, play_pulse: bool = true) -> void:
	status_message = label
	if desktop_advance_day_button != null:
		desktop_advance_day_button.disabled = true
		desktop_advance_day_button.text = "%s..." % label.to_upper()
		desktop_advance_day_button.tooltip_text = "Processing the next trading day."
		if play_pulse:
			_play_advance_day_phase_pulse()
	_refresh_dashboard()
	_refresh_desktop()


func _finish_advance_day_processing() -> void:
	advance_day_processing = false
	if desktop_advance_day_button != null:
		desktop_advance_day_button.disabled = false
		desktop_advance_day_button.text = "ADVANCE DAY"
		desktop_advance_day_button.tooltip_text = "Advance to the next trading day."
		_reset_advance_day_button_animation_state()
	_refresh_desktop()


func _show_daily_recap_if_pending() -> void:
	if pending_daily_recap_snapshot.is_empty() or daily_recap_dialog == null or daily_recap_body_label == null:
		return
	daily_recap_body_label.text = _build_daily_recap_text(pending_daily_recap_snapshot)
	pending_daily_recap_snapshot = {}
	daily_recap_dialog.visible = true
	daily_recap_dialog.move_to_front()
	_play_daily_recap_reveal()
	_schedule_advance_day_post_recap_save_flush()


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
	return "\n".join(lines)


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
	selected_lots = max(int(round(value)), 1)
	_refresh_sidebar()
	if not current_trade_snapshot.is_empty():
		_refresh_order_controls(current_trade_snapshot)


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


func _ensure_upgrade_purchase_dialog() -> void:
	if upgrade_purchase_dialog != null:
		return

	upgrade_purchase_dialog = ConfirmationDialog.new()
	upgrade_purchase_dialog.name = "UpgradePurchaseDialog"
	upgrade_purchase_dialog.title = "Confirm Upgrade"
	add_child(upgrade_purchase_dialog)
	upgrade_purchase_dialog.confirmed.connect(_on_upgrade_purchase_confirmed)
	upgrade_purchase_dialog.get_ok_button().text = "Buy Upgrade"
	upgrade_purchase_dialog.get_cancel_button().text = "Cancel"

	var dialog_margin: MarginContainer = MarginContainer.new()
	dialog_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_margin.add_theme_constant_override("margin_left", 18)
	dialog_margin.add_theme_constant_override("margin_top", 18)
	dialog_margin.add_theme_constant_override("margin_right", 18)
	dialog_margin.add_theme_constant_override("margin_bottom", 18)
	upgrade_purchase_dialog.add_child(dialog_margin)

	upgrade_purchase_body_label = Label.new()
	upgrade_purchase_body_label.name = "UpgradePurchaseBodyLabel"
	upgrade_purchase_body_label.custom_minimum_size = Vector2(500, 150)
	upgrade_purchase_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrade_purchase_body_label.text = ""
	upgrade_purchase_body_label.add_theme_color_override("font_color", COLOR_WINDOW_TEXT)
	dialog_margin.add_child(upgrade_purchase_body_label)


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
	if daily_recap_dialog != null:
		_reset_daily_recap_animation_state()
		daily_recap_dialog.visible = false


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
		network_open_meeting_button.pressed.connect(_on_network_open_meeting_pressed)
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
		network_followup_button.get_popup().id_pressed.connect(_on_network_followup_selected)
		var network_action_row: HBoxContainer = network_meet_button.get_parent()
		network_action_row.add_child(network_followup_button)

	if network_source_check_button == null:
		network_source_check_button = Button.new()
		network_source_check_button.name = "NetworkSourceCheckButton"
		network_source_check_button.text = "Ask About Conflict"
		network_source_check_button.visible = false
		network_source_check_button.disabled = true
		network_source_check_button.tooltip_text = "Ask this contact why another source disagrees."
		network_source_check_button.pressed.connect(_on_network_source_check_pressed)
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
			filter_button.pressed.connect(_on_network_journal_filter_pressed.bind(filter_id))
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

	if rupslb_meeting_overlay == null:
		rupslb_meeting_overlay = RUPSLB_MEETING_OVERLAY_SCRIPT.new()
		rupslb_meeting_overlay.name = "RupslbMeetingOverlay"
		rupslb_meeting_overlay.visible = false
		rupslb_meeting_overlay.connect("close_requested", Callable(self, "_close_rupslb_meeting_overlay"))
		rupslb_meeting_overlay.connect("stage_advance_requested", Callable(self, "_on_rupslb_stage_advance_requested"))
		rupslb_meeting_overlay.connect("vote_requested", Callable(self, "_on_rupslb_vote_requested"))
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
	if news_masthead_logo_frame == null:
		news_masthead_logo_frame = PanelContainer.new()
		news_masthead_logo_frame.name = "NewsMastheadLogoFrame"
		news_masthead_logo_frame.custom_minimum_size = Vector2(74, 44)
		header_row.add_child(news_masthead_logo_frame)
		header_row.move_child(news_masthead_logo_frame, 0)
		var logo_label := Label.new()
		logo_label.name = "NewsMastheadLogoPlaceholder"
		logo_label.text = "LOGO"
		logo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		logo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		news_masthead_logo_frame.add_child(logo_label)
	if news_masthead_date_label == null:
		news_masthead_date_label = Label.new()
		news_masthead_date_label.name = "NewsMastheadDateLabel"
		news_masthead_date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		news_masthead_date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_row.add_child(news_masthead_date_label)

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
		news_article_cards.add_theme_constant_override("separation", 10)
		news_article_cards_scroll.add_child(news_article_cards)

	var detail_vbox: VBoxContainer = news_detail_headline_label.get_parent()
	if news_detail_hero_frame == null:
		news_detail_hero_frame = PanelContainer.new()
		news_detail_hero_frame.name = "NewsDetailHeroFrame"
		news_detail_hero_frame.custom_minimum_size = Vector2(0, 136)
		news_detail_hero_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail_vbox.add_child(news_detail_hero_frame)
		detail_vbox.move_child(news_detail_hero_frame, detail_vbox.get_children().find(news_detail_headline_label))
		var hero_label := Label.new()
		hero_label.name = "NewsDetailHeroPlaceholder"
		hero_label.text = "IMAGE SLOT"
		hero_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hero_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		news_detail_hero_frame.add_child(hero_label)
	if news_detail_byline_label == null:
		news_detail_byline_label = Label.new()
		news_detail_byline_label.name = "NewsDetailBylineLabel"
		news_detail_byline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_vbox.add_child(news_detail_byline_label)
		detail_vbox.move_child(news_detail_byline_label, detail_vbox.get_children().find(news_detail_meta_label))
	if news_detail_chips_label == null:
		news_detail_chips_label = Label.new()
		news_detail_chips_label.name = "NewsDetailChipsLabel"
		news_detail_chips_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_vbox.add_child(news_detail_chips_label)
		detail_vbox.move_child(news_detail_chips_label, detail_vbox.get_children().find(news_detail_body))
	if news_detail_action_row == null:
		news_detail_action_row = HBoxContainer.new()
		news_detail_action_row.name = "NewsDetailActionRow"
		news_detail_action_row.add_theme_constant_override("separation", 8)
		detail_vbox.add_child(news_detail_action_row)
		detail_vbox.move_child(news_detail_action_row, detail_vbox.get_children().find(news_meet_contact_button))
	if news_meet_contact_button.get_parent() != news_detail_action_row:
		news_meet_contact_button.reparent(news_detail_action_row)
	if news_open_meeting_button != null and news_open_meeting_button.get_parent() != news_detail_action_row:
		news_open_meeting_button.reparent(news_detail_action_row)


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


func _build_tutorial_text() -> String:
	return "Open the STOCKBOT app from the desktop, then pick one stock first.\n\nUse the Chart, Key Stats, Financials, Broker, or Profile tabs to inspect the setup, size the order from the right-side ticket, then use the navbar to advance the day.\n\nDashboard is now overview-only, while Portfolio keeps your holdings and trade history together.\n\nDifficulty: %s." % GameManager.get_current_difficulty_label()


func _build_help_text() -> String:
	return "OVERVIEW\nThe game screen is split into modular views so you can move sections around more easily later.\nSidebar sections now swap self-contained views instead of one giant screen.\n\nOBJECTIVE\nFind the clearest setup, size lightly, then learn from the close.\n\nSECTIONS\n%s\n\n%s\n\n%s\n\nWORKFLOW\n1. Start on Dashboard for the market overview.\n2. Open Trade and choose a stock.\n3. Use Chart, Key Stats, Financials, Broker, or Profile to inspect it.\n4. Size the order from the right-side ticket.\n5. Advance the day.\n\nNOTES\nUse sector context to decide whether a stock is moving with its group or fighting it.\nNewest fills appear first in Trade History so you can audit lots, fees, cash impact, and realized P/L.\n\nCURRENT DIFFICULTY\n%s" % [
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
	var stock_rows: Array = _get_company_rows_cached().duplicate()
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
	if (
		normalized_app_id != APP_ID_STOCK and
		normalized_app_id != APP_ID_NEWS and
		normalized_app_id != APP_ID_SOCIAL and
		normalized_app_id != APP_ID_NETWORK and
		normalized_app_id != APP_ID_ACADEMY and
		normalized_app_id != APP_ID_THESIS and
		normalized_app_id != APP_ID_LIFE and
		normalized_app_id != APP_ID_UPGRADES
	):
		normalized_app_id = APP_ID_DESKTOP

	desktop_layer.visible = true
	app_window_backdrop.visible = false
	app_window_title_bar.visible = false
	if normalized_app_id == APP_ID_DESKTOP:
		active_app_id = APP_ID_DESKTOP
		_hide_debug_overlay()
		_hide_toast()
		_apply_window_layout()
		_apply_active_window_theme()
		_refresh_desktop()
		return

	_remove_deferred_open_app_refresh(normalized_app_id)
	_open_desktop_app_window(normalized_app_id)
	_refresh_app_window_content(normalized_app_id)
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
	stock_window_container.offset_left = APP_WINDOW_CONTENT_MARGIN
	stock_window_container.offset_top = APP_WINDOW_CONTENT_TOP_MARGIN
	stock_window_container.offset_right = -APP_WINDOW_CONTENT_MARGIN
	stock_window_container.offset_bottom = -APP_WINDOW_CONTENT_BOTTOM_MARGIN
	_apply_desktop_window_layouts()


func _apply_active_window_theme() -> void:
	var is_light_window: bool = active_app_id == APP_ID_NEWS or active_app_id == APP_ID_SOCIAL or active_app_id == APP_ID_NETWORK or active_app_id == APP_ID_ACADEMY or active_app_id == APP_ID_THESIS or active_app_id == APP_ID_LIFE or active_app_id == APP_ID_UPGRADES
	var window_fill: Color = COLOR_WINDOW_BG if is_light_window else COLOR_STOCK_WINDOW_BG
	var window_text: Color = COLOR_WINDOW_TEXT if is_light_window else COLOR_TEXT
	var app_font_size: int = STOCK_APP_FONT_SIZE if active_app_id == APP_ID_STOCK else DEFAULT_APP_FONT_SIZE
	_style_panel(app_window_panel, window_fill, 8)
	_style_window_title_bar(app_window_title_bar, window_fill)
	_style_panel(stock_window_container, COLOR_STOCK_WINDOW_BG, 0)
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
		return "Twooter open  |  Tiered social feed online."
	if active_app_id == APP_ID_NETWORK:
		return "Network open  |  Contacts, recognition, and requests online."
	if active_app_id == APP_ID_ACADEMY:
		return "Academy open  |  Technical chart-reading lessons online."
	if active_app_id == APP_ID_THESIS:
		return "Thesis Board open  |  Research notes and evidence discipline online."
	if active_app_id == APP_ID_LIFE:
		return "Life open  |  Monthly cash-flow plan online."
	if active_app_id == APP_ID_UPGRADES:
		return "Upgrades open  |  Spend cash to improve your desk."
	return "Desktop ready  |  Open STOCKBOT, News, Twooter, Network, Academy, Thesis, Life, or Upgrades."


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
	_style_panel(dashboard_movers_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_panel(dashboard_placeholder_bottom_panel, COLOR_PANEL_BLUE_ALT, 0)
	_style_dashboard_calendar_event_popup()
	_style_dashboard_sector_ui()
	_style_panel(news_window_body, COLOR_WINDOW_BG, 0)
	_style_panel(news_feed_panel, Color(0.952941, 0.94902, 0.87451, 1), 0)
	_style_panel(news_detail_panel, Color(0.968627, 0.964706, 0.898039, 1), 0)
	if news_masthead_logo_frame != null:
		_style_news_asset_frame(news_masthead_logo_frame)
	if news_detail_hero_frame != null:
		_style_news_asset_frame(news_detail_hero_frame)
	_style_panel(social_window_body, Color(0.94902, 0.956863, 0.976471, 1), 0)
	_style_panel(network_window_body, COLOR_WINDOW_BG, 0)
	_style_panel(network_list_panel, Color(0.952941, 0.94902, 0.87451, 1), 0)
	_style_panel(network_detail_panel, Color(0.968627, 0.964706, 0.898039, 1), 0)
	if academy_window_body != null:
		_restyle_academy_controls()
		_apply_academy_text_theme()
	_style_panel(upgrade_window_body, COLOR_WINDOW_BG, 0)
	if console_panel != null:
		_style_panel(console_panel, Color(0.0588235, 0.0823529, 0.109804, 0.98), 0)
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
	_style_key_stats_dashboard_ui()
	_style_button(app_window_minimize_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_button(app_window_close_button, Color(0.368627, 0.160784, 0.176471, 1), Color(0.709804, 0.34902, 0.372549, 1), COLOR_TEXT, 0)
	_style_button(financials_previous_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_button(financials_next_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_button(debug_close_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_button(news_meet_contact_button, Color(0.27451, 0.219608, 0.0980392, 1), Color(0.819608, 0.631373, 0.254902, 1), COLOR_TEXT, 0)
	if news_open_meeting_button != null:
		_style_button(news_open_meeting_button, Color(0.866667, 0.807843, 0.635294, 1), Color(0.709804, 0.607843, 0.345098, 1), COLOR_WINDOW_TEXT, 0)
	_style_button(profile_meet_contact_button, Color(0.27451, 0.219608, 0.0980392, 1), Color(0.819608, 0.631373, 0.254902, 1), COLOR_TEXT, 0)
	_style_button(network_meet_button, Color(0.27451, 0.219608, 0.0980392, 1), Color(0.819608, 0.631373, 0.254902, 1), COLOR_TEXT, 0)
	_style_button(network_tip_button, Color(0.117647, 0.32549, 0.239216, 1), COLOR_ORDER_BUY_BORDER, COLOR_TEXT, 0)
	_style_button(network_request_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	_style_button(network_referral_button, Color(0.27451, 0.219608, 0.0980392, 1), Color(0.819608, 0.631373, 0.254902, 1), COLOR_TEXT, 0)
	if network_followup_button != null:
		_style_button(network_followup_button, Color(0.164706, 0.215686, 0.278431, 1), COLOR_BORDER, COLOR_TEXT, 0)
	if network_source_check_button != null:
		_style_button(network_source_check_button, Color(0.192157, 0.152941, 0.0823529, 1), Color(0.819608, 0.631373, 0.254902, 1), COLOR_TEXT, 0)
	if network_open_meeting_button != null:
		_style_button(network_open_meeting_button, Color(0.866667, 0.807843, 0.635294, 1), Color(0.709804, 0.607843, 0.345098, 1), COLOR_WINDOW_TEXT, 0)
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
	_set_label_tone(social_title_label, Color(0.121569, 0.160784, 0.258824, 1))
	_set_label_tone(social_access_status_label, Color(0.196078, 0.301961, 0.486275, 1))
	_set_label_tone(debug_generators_hint_label, COLOR_MUTED)
	_set_label_tone(social_feed_summary_label, Color(0.121569, 0.160784, 0.258824, 1))
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
		_set_label_tone(upgrade_purchase_body_label, COLOR_WINDOW_TEXT)
	if daily_recap_body_label != null:
		_set_label_tone(daily_recap_body_label, COLOR_WINDOW_TEXT)
	_style_daily_recap_dialog()
	if console_title_label != null:
		_set_label_tone(console_title_label, COLOR_TEXT)
	if console_hint_label != null:
		_set_label_tone(console_hint_label, COLOR_MUTED)
	if console_status_label != null:
		_set_label_tone(console_status_label, COLOR_WARNING)
	_set_label_tone(taskbar_status_label, COLOR_MUTED)
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
	_apply_font_override_to_control(button, DEFAULT_APP_FONT_SIZE, _get_app_font())


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


func _style_news_asset_frame(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.894118, 0.870588, 0.745098, 1)
	style.border_color = Color(0.572549, 0.482353, 0.309804, 0.85)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	panel.add_theme_stylebox_override("panel", style)


func _style_news_article_card(card: PanelContainer, is_selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.984314, 0.964706, 0.882353, 1) if is_selected else Color(0.960784, 0.941176, 0.839216, 1)
	style.border_color = Color(0.47451, 0.384314, 0.227451, 1) if is_selected else Color(0.658824, 0.588235, 0.427451, 0.75)
	style.set_border_width_all(2 if is_selected else 1)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	card.add_theme_stylebox_override("panel", style)


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


func _style_network_journal_filter_button(button: Button, is_selected: bool) -> void:
	var fill_color: Color = Color(0.835294, 0.764706, 0.529412, 0.82) if is_selected else Color(0.952941, 0.94902, 0.87451, 1)
	var border_color: Color = Color(0.52549, 0.396078, 0.160784, 1) if is_selected else Color(0.572549, 0.482353, 0.309804, 0.8)
	_style_button(button, fill_color, border_color, COLOR_WINDOW_TEXT, 0)


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
	item_list.add_theme_color_override("font_hovered_color", COLOR_WINDOW_TEXT)
	item_list.add_theme_color_override("font_selected_color", COLOR_WINDOW_TEXT)
	item_list.add_theme_color_override("font_hovered_selected_color", COLOR_WINDOW_TEXT)
	item_list.add_theme_color_override("font_disabled_color", Color(0.352941, 0.309804, 0.203922, 0.82))
	item_list.add_theme_color_override("guide_color", Color(0, 0, 0, 0))


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
	return "%sRp%s" % [
		"-" if value < 0.0 else "",
		_format_decimal(absf(value), 2, true)
	]


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
		broker_summary_label.text = ""
		broker_summary_label.visible = false
		broker_meter_label.text = ""
		broker_meter_label.visible = false
		broker_meter_bar.value = 50.0
		_style_broker_meter(Color(0.603922, 0.623529, 0.662745, 0.92))
		return

	var action_meter_score: float = float(broker_flow.get("action_meter_score", 0.0))
	var flow_tag: String = str(broker_flow.get("flow_tag", "neutral"))
	broker_summary_label.text = ""
	broker_summary_label.visible = false
	broker_meter_label.text = ""
	broker_meter_label.visible = false
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
	_refresh_key_stats_dashboard(current_trade_snapshot)


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
		return "%sRp%sT" % [
			"-" if value < 0.0 else "",
			_format_decimal(absf(value) / 1000000000000.0, 2, false)
		]
	if absolute_value >= 1000000000.0:
		return "%sRp%sB" % [
			"-" if value < 0.0 else "",
			_format_decimal(absf(value) / 1000000000.0, 2, false)
		]
	if absolute_value >= 1000000.0:
		return "%sRp%sM" % [
			"-" if value < 0.0 else "",
			_format_decimal(absf(value) / 1000000.0, 2, false)
		]
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
	var grouped_value: String = ".".join(groups)
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
	var safe_places: int = max(decimal_places, 0)
	var decimal_scale: int = 1
	for _index in range(safe_places):
		decimal_scale *= 10
	var scaled_value: int = int(round(absf(value) * float(decimal_scale)))
	var whole_value: int = int(floor(float(scaled_value) / float(decimal_scale)))
	var decimal_value: int = scaled_value % decimal_scale
	var whole_text: String = _format_grouped_integer(whole_value) if use_grouping else str(whole_value)
	if safe_places <= 0:
		return whole_text
	var decimal_text: String = str(decimal_value)
	while decimal_text.length() < safe_places:
		decimal_text = "0" + decimal_text
	return "%s,%s" % [whole_text, decimal_text]


func _join_or_default(values: Array, default_text: String) -> String:
	if values.is_empty():
		return default_text

	var parts: Array = []
	for value in values:
		parts.append(str(value))
	return ", ".join(parts)
