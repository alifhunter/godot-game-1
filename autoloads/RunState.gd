extends Node

const STABLE_RNG = preload("res://systems/StableRng.gd")
const SAVE_SCHEMA_VERSION := 2
const SAVE_FORMAT_ID := "daytrader_single_run"
const LOT_SIZE := 100
const PLAYER_BROKER_CODE := "XL"
const PLAYER_BROKER_NAME := "PT. Sobat Loser"
const PLAYER_MARKET_FLOW_DECAY_DAYS := 3
const MAX_PLAYER_MARKET_FLOW_ENTRIES := 96
const BUY_FEE_RATE := 0.0015
const SELL_FEE_RATE := 0.0025
const DEFAULT_UPGRADE_TIER := 4
const UPGRADE_TRACK_IDS := [
	"trading_fee",
	"news_content",
	"twooter_content",
	"chart_indicators",
	"daily_action_points"
]
const TRADING_FEE_BY_TIER := {
	4: {"buy_fee_rate": 0.0015, "sell_fee_rate": 0.0025},
	3: {"buy_fee_rate": 0.0013, "sell_fee_rate": 0.0022},
	2: {"buy_fee_rate": 0.0011, "sell_fee_rate": 0.0019},
	1: {"buy_fee_rate": 0.0009, "sell_fee_rate": 0.0016}
}
const DAILY_ACTION_LIMIT_BY_TIER := {
	4: 10,
	3: 15,
	2: 20,
	1: 25
}
const MAX_TRADE_HISTORY := 64
const MAX_EVENT_HISTORY := 160
const MAX_MARKET_HISTORY := 512
const MAX_PRICE_BARS_HISTORY := 1600
const CHART_HISTORY_VISIBLE_BARS := 1260
const REPORT_CALENDAR_END_YEAR := 2030
const APPLY_DAY_PERF_LOG_PREFIX := "[perf][apply]"
const REPORT_MONTH_BY_QUARTER := {
	1: 1,
	2: 4,
	3: 7,
	4: 10
}
const STARTUP_PERF_LOG_PREFIX := "[perf][startup]"
const COMPANY_DETAIL_PERSISTENCE_PERSISTENT := "persistent"
const COMPANY_DETAIL_PERSISTENCE_EPHEMERAL := "ephemeral"
const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")
const COMPANY_PROFILE_KEYS := [
	"name",
	"sector_id",
	"base_price",
	"quality_score",
	"growth_score",
	"risk_score",
	"base_volatility",
	"financials",
	"financial_history",
	"financial_statement_snapshot",
	"generation_traits",
	"shares_outstanding",
	"detail_status",
	"profile_seed",
	"archetype_id",
	"archetype_label",
	"company_size_id",
	"company_size_label",
	"company_age",
	"founded_year",
	"employee_count",
	"profile_revenue",
	"profile_revenue_value",
	"profile_revenue_unit",
	"profile_description",
	"profile_tags",
	"management_roster",
	"post_deal_identity"
]
const DEFAULT_DIFFICULTY_CONFIG := {
	"id": "normal",
	"label": "Normal",
	"starting_cash": 100000000.0,
	"company_count": 30,
	"market_swing_range": 0.035,
	"volatility_multiplier": 1.0,
	"event_interval_days": 10.0,
	"broker_impact_multiplier": 1.0,
	"daily_move_cap": 0.12,
	"volatility_label": "Normal",
	"event_label": "Every 10 Days"
}
const FTUE_STEP_IDS := [
	"welcome_desktop",
	"pick_stock",
	"inspect_setup",
	"buy_one_lot",
	"advance_day",
	"read_recap",
	"next_steps"
]
const FTUE_FIRST_STEP_ID := "welcome_desktop"
const FTUE_FINAL_STEP_ID := "next_steps"
const FIRST_HOUR_GUIDE_STEP_IDS := [
	"portfolio_check",
	"create_thesis",
	"add_watchlist",
	"read_market_context",
	"seeded_rupslb",
	"attend_rupslb",
	"approach_lead",
	"handoff"
]
const FIRST_HOUR_GUIDE_FIRST_STEP_ID := "portfolio_check"
const FIRST_HOUR_GUIDE_FINAL_STEP_ID := "handoff"

var run_seed = 0
var day_index = 0
var market_sentiment = 0.0
var companies = {}
var company_definitions = {}
var company_order = []
var watchlist_company_ids = []
var player_portfolio = {}
var daily_summary = {}
var last_day_results = {}
var last_equity_value = 0.0
var trade_history = []
var player_market_flows = {}
var event_history = []
var market_history = []
var active_company_arcs = []
var active_special_events = []
var active_corporate_action_chains = {}
var corporate_meeting_calendar = {}
var corporate_action_intel = {}
var corporate_dividend_calendar = {}
var attended_meetings = {}
var corporate_meeting_sessions = {}
var shareholder_registry = {}
var news_archive_index = {}
var news_archive_articles = {}
var desktop_app_seen_days = {}
var desktop_app_badge_counts = {}
var network_contacts = {}
var network_discoveries = {}
var network_requests = {}
var network_tip_journal = {}
var player_theses = {}
var player_life = {}
var upgrade_tiers = {}
var daily_action_day_index = 0
var daily_actions_used = 0
var academy_progress = {}
var quarterly_report_calendar = {}
var yearly_macro_states = {}
var historical_chart_bar_cache = {}
var company_detail_hydration_queue = []
var company_detail_hydration_lookup = {}
var difficulty_id = "normal"
var difficulty_config = DEFAULT_DIFFICULTY_CONFIG.duplicate(true)
var tutorial_enabled = false
var tutorial_shown = false
var ftue_enabled = false
var ftue_completed = false
var ftue_skipped = false
var ftue_current_step_id = ""
var ftue_completed_step_ids = []
var ftue_start_day_index = 0
var first_hour_guide_enabled = false
var first_hour_guide_completed = false
var first_hour_guide_skipped = false
var first_hour_guide_current_step_id = ""
var first_hour_guide_completed_step_ids = []
var first_hour_guide_start_day_index = 0
var first_hour_guide_anchor_company_id = ""
var first_hour_guide_seeded_meeting_id = ""
var first_hour_guide_seeded_chain_id = ""
var current_trade_date = {}
var trading_calendar = preload("res://systems/TradingCalendar.gd").new()
var company_generator = preload("res://systems/CompanyGenerator.gd").new()
var macro_state_system = preload("res://systems/MacroStateSystem.gd").new()


func _ready() -> void:
	reset()


func reset() -> void:
	run_seed = 0
	day_index = 0
	market_sentiment = 0.0
	companies = {}
	company_definitions = {}
	company_order = []
	watchlist_company_ids = []
	player_portfolio = {
		"cash": 0.0,
		"holdings": {},
		"realized_pnl": 0.0
	}
	daily_summary = {}
	last_day_results = {}
	last_equity_value = 0.0
	trade_history = []
	player_market_flows = {}
	event_history = []
	market_history = []
	active_company_arcs = []
	active_special_events = []
	active_corporate_action_chains = {}
	corporate_meeting_calendar = {}
	corporate_action_intel = {}
	corporate_dividend_calendar = {}
	attended_meetings = {}
	corporate_meeting_sessions = {}
	shareholder_registry = {}
	news_archive_index = {}
	news_archive_articles = {}
	desktop_app_seen_days = {}
	desktop_app_badge_counts = {}
	network_contacts = {}
	network_discoveries = {}
	network_requests = {}
	network_tip_journal = {}
	player_theses = {}
	player_life = _default_life_state()
	upgrade_tiers = _default_upgrade_tiers()
	daily_action_day_index = 0
	daily_actions_used = 0
	academy_progress = _default_academy_progress()
	quarterly_report_calendar = {}
	yearly_macro_states = {}
	historical_chart_bar_cache = {}
	company_detail_hydration_queue = []
	company_detail_hydration_lookup = {}
	difficulty_id = str(DEFAULT_DIFFICULTY_CONFIG.get("id", "normal"))
	difficulty_config = DEFAULT_DIFFICULTY_CONFIG.duplicate(true)
	tutorial_enabled = false
	tutorial_shown = false
	ftue_enabled = false
	ftue_completed = false
	ftue_skipped = false
	ftue_current_step_id = ""
	ftue_completed_step_ids = []
	ftue_start_day_index = 0
	first_hour_guide_enabled = false
	first_hour_guide_completed = false
	first_hour_guide_skipped = false
	first_hour_guide_current_step_id = ""
	first_hour_guide_completed_step_ids = []
	first_hour_guide_start_day_index = 0
	first_hour_guide_anchor_company_id = ""
	first_hour_guide_seeded_meeting_id = ""
	first_hour_guide_seeded_chain_id = ""
	current_trade_date = trading_calendar.start_date()


func has_active_run() -> bool:
	return not company_order.is_empty()


func setup_new_run(
	new_run_seed: int,
	run_company_definitions: Array,
	new_difficulty_config: Dictionary,
	wants_tutorial: bool
) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	_initialize_new_run_state(new_run_seed, new_difficulty_config, wants_tutorial)
	for definition_value in run_company_definitions:
		_add_company_to_new_run(definition_value)
	_finalize_new_run_setup()
	_log_startup_perf_elapsed("setup_new_run", started_at_usec, " companies=%d" % company_order.size())


func setup_new_run_batched(
	new_run_seed: int,
	run_company_definitions: Array,
	new_difficulty_config: Dictionary,
	wants_tutorial: bool,
	progress_callback: Callable = Callable(),
	batch_size: int = 5,
	detail_callback: Callable = Callable()
) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	_initialize_new_run_state(new_run_seed, new_difficulty_config, wants_tutorial)
	var total_company_count: int = run_company_definitions.size()
	var effective_batch_size: int = _effective_new_run_batch_size(total_company_count, batch_size)
	var processed_company_count: int = 0
	if total_company_count <= 0:
		if progress_callback.is_valid():
			progress_callback.call(0, 0)
		_finalize_new_run_setup()
		_log_startup_perf_elapsed("setup_new_run_batched", started_at_usec, " companies=0")
		return

	while processed_company_count < total_company_count:
		var batch_started_at_usec: int = Time.get_ticks_usec()
		var batch_end_index: int = min(processed_company_count + effective_batch_size, total_company_count)
		var batch_company_count: int = batch_end_index - processed_company_count
		var batch_company_ids: Array = []
		for definition_index in range(processed_company_count, batch_end_index):
			var definition: Dictionary = run_company_definitions[definition_index]
			_add_company_to_new_run(definition)
			batch_company_ids.append(str(definition.get("id", "")))
		processed_company_count = batch_end_index
		if progress_callback.is_valid():
			progress_callback.call(processed_company_count, total_company_count)
		if detail_callback.is_valid():
			detail_callback.call(processed_company_count, total_company_count, batch_company_ids)
		_log_startup_perf_elapsed(
			"new_run_financial_batch",
			batch_started_at_usec,
			" companies=%d/%d batch_size=%d" % [processed_company_count, total_company_count, batch_company_count]
		)
		if processed_company_count < total_company_count:
			await get_tree().process_frame

	_finalize_new_run_setup()
	_log_startup_perf_elapsed("setup_new_run_batched", started_at_usec, " companies=%d" % company_order.size())


func _initialize_new_run_state(
	new_run_seed: int,
	new_difficulty_config: Dictionary,
	wants_tutorial: bool
) -> void:
	reset()
	run_seed = new_run_seed
	difficulty_config = new_difficulty_config.duplicate(true)
	if difficulty_config.is_empty():
		difficulty_config = DEFAULT_DIFFICULTY_CONFIG.duplicate(true)

	difficulty_id = str(difficulty_config.get("id", "normal"))
	tutorial_enabled = wants_tutorial
	tutorial_shown = false
	ftue_enabled = wants_tutorial
	ftue_completed = false
	ftue_skipped = false
	ftue_current_step_id = FTUE_FIRST_STEP_ID if wants_tutorial else ""
	ftue_completed_step_ids = []
	ftue_start_day_index = day_index
	first_hour_guide_enabled = wants_tutorial
	first_hour_guide_completed = false
	first_hour_guide_skipped = false
	first_hour_guide_current_step_id = ""
	first_hour_guide_completed_step_ids = []
	first_hour_guide_start_day_index = day_index
	first_hour_guide_anchor_company_id = ""
	first_hour_guide_seeded_meeting_id = ""
	first_hour_guide_seeded_chain_id = ""
	current_trade_date = trading_calendar.start_date()
	player_portfolio["cash"] = float(difficulty_config.get("starting_cash", DEFAULT_DIFFICULTY_CONFIG.get("starting_cash", 0.0)))
	_ensure_macro_state_for_year(int(current_trade_date.get("year", 2020)))


func _add_company_to_new_run(definition_value: Dictionary) -> void:
	var base_definition: Dictionary = definition_value.duplicate(true)
	var company_id: String = str(base_definition.get("id", ""))
	if company_id.is_empty():
		return

	self.company_definitions[company_id] = base_definition
	var sector_definition: Dictionary = DataRepository.get_sector_definition(str(base_definition.get("sector_id", "")))
	var company_profile: Dictionary = company_generator.generate_company_profile_core(base_definition, sector_definition, run_seed)
	var effective_definition: Dictionary = _apply_company_profile_to_definition(base_definition, company_profile)
	var base_price: float = IDX_PRICE_RULES.normalize_last_price(float(effective_definition.get("base_price", 0.0)))
	company_order.append(company_id)
	companies[company_id] = {
		"company_id": company_id,
		"current_price": base_price,
		"previous_close": base_price,
		"starting_price": base_price,
		"ytd_open_price": base_price,
		"ytd_reference_year": int(current_trade_date.get("year", 2020)),
		"price_history": [base_price],
		"price_bars": [],
		"sentiment": 0.0,
		"active_event_tags": [],
		"active_events": [],
		"hidden_story_flags": _seed_hidden_story_flags(base_definition),
		"broker_flow": _empty_broker_flow(),
		"daily_change_pct": 0.0,
		"market_depth_context": {},
		"player_market_impact": {},
		"company_profile": company_profile
	}


func _finalize_new_run_setup() -> void:
	last_equity_value = get_total_equity()
	quarterly_report_calendar = _build_quarterly_report_calendar()


func _effective_new_run_batch_size(total_company_count: int, requested_batch_size: int) -> int:
	if total_company_count <= 0:
		return 1
	var safe_requested_batch_size: int = requested_batch_size
	if safe_requested_batch_size <= 0:
		safe_requested_batch_size = 5
	if total_company_count <= 20 and safe_requested_batch_size <= 5:
		return 10
	return max(safe_requested_batch_size, 1)


func _should_log_startup_perf() -> bool:
	return OS.is_debug_build()


func _should_log_apply_day_perf() -> bool:
	return OS.is_debug_build()


func _log_startup_perf_elapsed(label: String, started_at_usec: int, extra: String = "") -> void:
	if not _should_log_startup_perf():
		return
	var elapsed_msec: float = max(float(Time.get_ticks_usec() - started_at_usec) / 1000.0, 0.0)
	if extra.is_empty():
		print("%s %s %.2fms" % [STARTUP_PERF_LOG_PREFIX, label, elapsed_msec])
		return
	print("%s %s %.2fms%s" % [STARTUP_PERF_LOG_PREFIX, label, elapsed_msec, extra])


func _log_apply_day_perf_elapsed(enabled: bool, label: String, started_at_usec: int, extra: String = "") -> void:
	if not enabled:
		return
	var elapsed_msec: float = max(float(Time.get_ticks_usec() - started_at_usec) / 1000.0, 0.0)
	if extra.is_empty():
		print("%s %s %.2fms" % [APPLY_DAY_PERF_LOG_PREFIX, label, elapsed_msec])
		return
	print("%s %s %.2fms%s" % [APPLY_DAY_PERF_LOG_PREFIX, label, elapsed_msec, extra])


func load_from_dict(data: Dictionary) -> void:
	var started_at_usec: int = Time.get_ticks_usec()
	var phase_started_at_usec: int = started_at_usec
	reset()
	run_seed = int(data.get("seed", 0))
	day_index = int(data.get("day_index", 0))
	market_sentiment = float(data.get("market_sentiment", 0.0))
	last_equity_value = float(data.get("last_equity_value", 0.0))
	daily_summary = data.get("daily_summary", {}).duplicate(true)
	last_day_results = _build_last_day_results_save_payload(data.get("last_day_results", {}))
	trade_history = data.get("trade_history", []).duplicate(true)
	player_market_flows = data.get("player_market_flows", {}).duplicate(true)
	event_history = data.get("event_history", []).duplicate(true)
	market_history = data.get("market_history", []).duplicate(true)
	active_company_arcs = data.get("active_company_arcs", []).duplicate(true)
	active_special_events = data.get("active_special_events", []).duplicate(true)
	active_corporate_action_chains = data.get("active_corporate_action_chains", {}).duplicate(true)
	corporate_meeting_calendar = data.get("corporate_meeting_calendar", {}).duplicate(true)
	corporate_action_intel = data.get("corporate_action_intel", {}).duplicate(true)
	corporate_dividend_calendar = data.get("corporate_dividend_calendar", {}).duplicate(true)
	attended_meetings = data.get("attended_meetings", {}).duplicate(true)
	corporate_meeting_sessions = data.get("corporate_meeting_sessions", {}).duplicate(true)
	shareholder_registry = data.get("shareholder_registry", {}).duplicate(true)
	news_archive_index = data.get("news_archive_index", {}).duplicate(true)
	news_archive_articles = data.get("news_archive_articles", {}).duplicate(true)
	desktop_app_seen_days = data.get("desktop_app_seen_days", {}).duplicate(true)
	desktop_app_badge_counts = data.get("desktop_app_badge_counts", {}).duplicate(true)
	network_contacts = data.get("network_contacts", {}).duplicate(true)
	network_discoveries = data.get("network_discoveries", {}).duplicate(true)
	network_requests = data.get("network_requests", {}).duplicate(true)
	network_tip_journal = data.get("network_tip_journal", {}).duplicate(true)
	player_theses = _normalize_player_theses(data.get("player_theses", {}))
	player_life = _normalize_life_state(data.get("player_life", {}))
	upgrade_tiers = _normalize_upgrade_tiers(data.get("upgrade_tiers", {}))
	daily_action_day_index = int(data.get("daily_action_day_index", day_index))
	daily_actions_used = max(int(data.get("daily_actions_used", 0)), 0)
	_sync_daily_action_day()
	academy_progress = _normalize_academy_progress(data.get("academy_progress", {}))
	quarterly_report_calendar = data.get("quarterly_report_calendar", {}).duplicate(true)
	yearly_macro_states = data.get("yearly_macro_states", {}).duplicate(true)
	difficulty_id = str(data.get("difficulty_id", "normal"))
	difficulty_config = data.get("difficulty_config", {}).duplicate(true)
	if difficulty_config.is_empty():
		difficulty_config = DEFAULT_DIFFICULTY_CONFIG.duplicate(true)
		difficulty_config["id"] = difficulty_id

	difficulty_id = str(difficulty_config.get("id", difficulty_id))
	tutorial_enabled = bool(data.get("tutorial_enabled", false))
	tutorial_shown = bool(data.get("tutorial_shown", false))
	_load_ftue_state(data)
	_load_first_hour_guide_state(data)
	current_trade_date = data.get("current_trade_date", {}).duplicate(true)
	if current_trade_date.is_empty():
		current_trade_date = trading_calendar.trade_date_for_index(day_index + 1)
	_ensure_macro_state_for_year(int(current_trade_date.get("year", 2020)))
	_log_startup_perf_elapsed("load_from_dict:base_state", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()

	for company_id in data.get("company_definitions", {}).keys():
		company_definitions[str(company_id)] = data["company_definitions"][company_id].duplicate(true)
	_log_startup_perf_elapsed("load_from_dict:company_definitions", phase_started_at_usec, " companies=%d" % company_definitions.size())
	phase_started_at_usec = Time.get_ticks_usec()

	for company_id in data.get("company_order", []):
		company_order.append(str(company_id))

	for company_id_value in data.get("watchlist_company_ids", []):
		var company_id: String = str(company_id_value)
		if company_id.is_empty() or watchlist_company_ids.has(company_id):
			continue
		watchlist_company_ids.append(company_id)
	_log_startup_perf_elapsed("load_from_dict:company_order_watchlist", phase_started_at_usec, " order=%d watchlist=%d" % [company_order.size(), watchlist_company_ids.size()])
	phase_started_at_usec = Time.get_ticks_usec()

	for company_id in data.get("companies", {}).keys():
		companies[str(company_id)] = _normalize_company_runtime(data["companies"][company_id].duplicate(true))
	_log_startup_perf_elapsed("load_from_dict:companies", phase_started_at_usec, " companies=%d" % companies.size())
	phase_started_at_usec = Time.get_ticks_usec()

	player_portfolio = data.get("player_portfolio", {
		"cash": 0.0,
		"holdings": {},
		"realized_pnl": 0.0
	}).duplicate(true)
	if quarterly_report_calendar.is_empty() and not company_order.is_empty():
		quarterly_report_calendar = _build_quarterly_report_calendar()
	_log_startup_perf_elapsed("load_from_dict:portfolio_reports", phase_started_at_usec)
	_log_startup_perf_elapsed("load_from_dict", started_at_usec, " companies=%d" % companies.size())


func to_save_dict() -> Dictionary:
	return {
		"save_schema_version": SAVE_SCHEMA_VERSION,
		"save_format_id": SAVE_FORMAT_ID,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"saved_at_text": Time.get_datetime_string_from_system(false, true),
		"save_engine_version": str(Engine.get_version_info().get("string", "")),
		"seed": run_seed,
		"day_index": day_index,
		"market_sentiment": market_sentiment,
		"companies": _build_companies_save_payload(),
		"company_definitions": company_definitions.duplicate(true),
		"company_order": company_order.duplicate(),
		"watchlist_company_ids": watchlist_company_ids.duplicate(),
		"player_portfolio": player_portfolio.duplicate(true),
		"daily_summary": daily_summary.duplicate(true),
		"last_day_results": _build_last_day_results_save_payload(last_day_results),
		"last_equity_value": last_equity_value,
		"trade_history": trade_history.duplicate(true),
		"player_market_flows": player_market_flows.duplicate(true),
		"event_history": event_history.duplicate(true),
		"market_history": market_history.duplicate(true),
		"active_company_arcs": active_company_arcs.duplicate(true),
		"active_special_events": active_special_events.duplicate(true),
		"active_corporate_action_chains": active_corporate_action_chains.duplicate(true),
		"corporate_meeting_calendar": corporate_meeting_calendar.duplicate(true),
		"corporate_action_intel": corporate_action_intel.duplicate(true),
		"corporate_dividend_calendar": corporate_dividend_calendar.duplicate(true),
		"attended_meetings": attended_meetings.duplicate(true),
		"corporate_meeting_sessions": corporate_meeting_sessions.duplicate(true),
		"shareholder_registry": shareholder_registry.duplicate(true),
		"news_archive_index": news_archive_index.duplicate(true),
		"news_archive_articles": news_archive_articles.duplicate(true),
		"desktop_app_seen_days": desktop_app_seen_days.duplicate(true),
		"desktop_app_badge_counts": desktop_app_badge_counts.duplicate(true),
		"network_contacts": network_contacts.duplicate(true),
		"network_discoveries": network_discoveries.duplicate(true),
		"network_requests": network_requests.duplicate(true),
		"network_tip_journal": network_tip_journal.duplicate(true),
		"player_theses": _normalize_player_theses(player_theses),
		"player_life": get_player_life(),
		"upgrade_tiers": get_upgrade_tiers(),
		"daily_action_day_index": daily_action_day_index,
		"daily_actions_used": daily_actions_used,
		"academy_progress": get_academy_progress(),
		"quarterly_report_calendar": quarterly_report_calendar.duplicate(true),
		"yearly_macro_states": yearly_macro_states.duplicate(true),
		"difficulty_id": difficulty_id,
		"difficulty_config": difficulty_config.duplicate(true),
		"tutorial_enabled": tutorial_enabled,
		"tutorial_shown": tutorial_shown,
		"ftue_enabled": ftue_enabled,
		"ftue_completed": ftue_completed,
		"ftue_skipped": ftue_skipped,
		"ftue_current_step_id": ftue_current_step_id,
		"ftue_completed_step_ids": ftue_completed_step_ids.duplicate(),
		"ftue_start_day_index": ftue_start_day_index,
		"first_hour_guide_enabled": first_hour_guide_enabled,
		"first_hour_guide_completed": first_hour_guide_completed,
		"first_hour_guide_skipped": first_hour_guide_skipped,
		"first_hour_guide_current_step_id": first_hour_guide_current_step_id,
		"first_hour_guide_completed_step_ids": first_hour_guide_completed_step_ids.duplicate(),
		"first_hour_guide_start_day_index": first_hour_guide_start_day_index,
		"first_hour_guide_anchor_company_id": first_hour_guide_anchor_company_id,
		"first_hour_guide_seeded_meeting_id": first_hour_guide_seeded_meeting_id,
		"first_hour_guide_seeded_chain_id": first_hour_guide_seeded_chain_id,
		"current_trade_date": current_trade_date.duplicate(true)
	}


func get_company(company_id: String) -> Dictionary:
	if not companies.has(company_id):
		return {}
	return companies[company_id]


func get_company_detail_status(company_id: String) -> String:
	var company: Dictionary = get_company(company_id)
	if company.is_empty():
		return ""
	var company_profile: Dictionary = company.get("company_profile", {})
	if company_profile.is_empty():
		return ""
	return str(company_profile.get("detail_status", "ready"))


func ensure_company_core_profile(company_id: String) -> bool:
	if company_id.is_empty() or not companies.has(company_id):
		return false
	var runtime: Dictionary = companies[company_id].duplicate(true)
	var company_profile: Dictionary = runtime.get("company_profile", {})
	if not company_profile.is_empty():
		return true
	var template: Dictionary = _get_base_company_definition(company_id)
	if template.is_empty():
		return false
	var sector_definition: Dictionary = DataRepository.get_sector_definition(str(template.get("sector_id", "")))
	company_profile = company_generator.generate_company_profile_core(template, sector_definition, run_seed)
	runtime["company_profile"] = company_profile
	companies[company_id] = runtime
	return true


func ensure_company_full_detail(company_id: String, persist_detail: bool = true) -> bool:
	if company_id.is_empty() or not companies.has(company_id):
		return false
	if not ensure_company_core_profile(company_id):
		return false
	var runtime: Dictionary = companies[company_id].duplicate(true)
	var company_profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	if company_profile.is_empty():
		return false
	if str(company_profile.get("detail_status", "ready")) == "ready":
		if persist_detail and str(company_profile.get("detail_persistence", COMPANY_DETAIL_PERSISTENCE_PERSISTENT)) != COMPANY_DETAIL_PERSISTENCE_PERSISTENT:
			company_profile["detail_persistence"] = COMPANY_DETAIL_PERSISTENCE_PERSISTENT
			runtime["company_profile"] = company_profile
			companies[company_id] = runtime
		return true
	var template: Dictionary = _get_base_company_definition(company_id)
	if template.is_empty():
		return false
	var sector_definition: Dictionary = DataRepository.get_sector_definition(str(template.get("sector_id", "")))
	company_profile["detail_status"] = "hydrating"
	runtime["company_profile"] = company_profile
	companies[company_id] = runtime
	var hydrated_profile: Dictionary = company_generator.hydrate_company_profile_detail(
		company_profile,
		template,
		sector_definition,
		run_seed
	)
	hydrated_profile["detail_status"] = "ready"
	hydrated_profile["detail_persistence"] = COMPANY_DETAIL_PERSISTENCE_PERSISTENT if persist_detail else COMPANY_DETAIL_PERSISTENCE_EPHEMERAL
	runtime["company_profile"] = _normalize_company_profile(hydrated_profile)
	companies[company_id] = runtime
	historical_chart_bar_cache.erase(company_id)
	company_detail_hydration_lookup.erase(company_id)
	var queued_index: int = company_detail_hydration_queue.find(company_id)
	if queued_index >= 0:
		company_detail_hydration_queue.remove_at(queued_index)
	return true


func _build_companies_save_payload() -> Dictionary:
	var save_companies: Dictionary = {}
	for company_id_value in companies.keys():
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = companies[company_id_value].duplicate(true)
		var company_profile: Dictionary = runtime.get("company_profile", {})
		if typeof(company_profile) == TYPE_DICTIONARY:
			runtime["company_profile"] = _build_company_profile_save_payload(company_profile)
		save_companies[company_id] = runtime
	return save_companies


func _build_company_profile_save_payload(company_profile: Dictionary) -> Dictionary:
	var save_profile: Dictionary = company_profile.duplicate(true)
	if str(save_profile.get("detail_persistence", COMPANY_DETAIL_PERSISTENCE_PERSISTENT)) != COMPANY_DETAIL_PERSISTENCE_EPHEMERAL:
		return save_profile

	save_profile["detail_status"] = "cold"
	save_profile.erase("detail_persistence")
	save_profile.erase("financial_history")
	save_profile.erase("financial_statement_snapshot")
	save_profile.erase("management_roster")
	return save_profile


func _build_last_day_results_save_payload(source_results: Variant) -> Dictionary:
	if typeof(source_results) != TYPE_DICTIONARY:
		return {}

	var source: Dictionary = source_results
	if source.is_empty():
		return {}

	var save_results: Dictionary = {
		"day_number": int(source.get("day_number", day_index)),
		"trade_date": source.get("trade_date", {}).duplicate(true),
		"market_sentiment": float(source.get("market_sentiment", market_sentiment)),
		"starting_equity": float(source.get("starting_equity", last_equity_value)),
		"scheduled_event": source.get("scheduled_event", {}).duplicate(true),
		"report_events": source.get("report_events", []).duplicate(true),
		"started_company_arcs": source.get("started_company_arcs", []).duplicate(true),
		"company_arc_phase_events": source.get("company_arc_phase_events", []).duplicate(true),
		"corporate_action_events": source.get("corporate_action_events", []).duplicate(true),
		"dividend_payments": source.get("dividend_payments", []).duplicate(true),
		"stock_dividend_distributions": source.get("stock_dividend_distributions", []).duplicate(true),
		"corporate_action_applications": source.get("corporate_action_applications", []).duplicate(true),
		"started_special_events": source.get("started_special_events", []).duplicate(true),
		"life_obligation": source.get("life_obligation", {}).duplicate(true),
		"network_request_results": source.get("network_request_results", []).duplicate(true),
		"network_tip_results": source.get("network_tip_results", []).duplicate(true)
	}
	return save_results


func queue_company_detail_hydration(company_id: String, priority: bool = false) -> void:
	if company_id.is_empty() or not companies.has(company_id):
		return
	if not ensure_company_core_profile(company_id):
		return
	var runtime: Dictionary = companies[company_id].duplicate(true)
	var company_profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	if company_profile.is_empty():
		return
	var current_status: String = str(company_profile.get("detail_status", "ready"))
	if current_status == "ready" or current_status == "hydrating":
		return
	company_profile["detail_status"] = "queued"
	runtime["company_profile"] = company_profile
	companies[company_id] = runtime
	if company_detail_hydration_lookup.has(company_id):
		if priority:
			var existing_index: int = company_detail_hydration_queue.find(company_id)
			if existing_index > 0:
				company_detail_hydration_queue.remove_at(existing_index)
				company_detail_hydration_queue.push_front(company_id)
		return
	company_detail_hydration_lookup[company_id] = true
	if priority:
		company_detail_hydration_queue.push_front(company_id)
	else:
		company_detail_hydration_queue.append(company_id)


func has_pending_company_detail_hydration() -> bool:
	return not company_detail_hydration_queue.is_empty()


func dequeue_company_detail_hydration() -> String:
	while not company_detail_hydration_queue.is_empty():
		var company_id: String = str(company_detail_hydration_queue.pop_front())
		company_detail_hydration_lookup.erase(company_id)
		if company_id.is_empty() or not companies.has(company_id):
			continue
		var runtime: Dictionary = companies[company_id].duplicate(true)
		var company_profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
		if company_profile.is_empty():
			continue
		var detail_status: String = str(company_profile.get("detail_status", "ready"))
		if detail_status == "ready":
			continue
		company_profile["detail_status"] = "hydrating"
		runtime["company_profile"] = company_profile
		companies[company_id] = runtime
		return company_id
	return ""


func get_company_chart_bars(company_id: String) -> Array:
	var runtime: Dictionary = get_company(company_id)
	if runtime.is_empty():
		return []

	var runtime_bars: Array = runtime.get("price_bars", []).duplicate(true)
	if runtime_bars.size() >= CHART_HISTORY_VISIBLE_BARS:
		return runtime_bars.slice(
			runtime_bars.size() - CHART_HISTORY_VISIBLE_BARS,
			runtime_bars.size()
		)

	var historical_bars: Array = _get_historical_chart_bars(company_id, runtime, runtime_bars)
	if historical_bars.is_empty():
		return runtime_bars

	var combined_bars: Array = historical_bars.duplicate(true)
	combined_bars.append_array(runtime_bars)
	if combined_bars.size() > CHART_HISTORY_VISIBLE_BARS:
		combined_bars = combined_bars.slice(
			combined_bars.size() - CHART_HISTORY_VISIBLE_BARS,
			combined_bars.size()
		)
	return combined_bars


func get_company_profile(
	company_id: String,
	include_financial_history: bool = true,
	include_statement_history: bool = true
) -> Dictionary:
	var company: Dictionary = get_company(company_id)
	if company.is_empty():
		return {}
	return _build_company_profile_view(
		company.get("company_profile", {}),
		include_financial_history,
		include_statement_history
	)


func get_effective_company_definition(
	company_id: String,
	include_financial_history: bool = true,
	include_statement_history: bool = true
) -> Dictionary:
	var definition: Dictionary = _get_base_company_definition(company_id)
	if definition.is_empty():
		return {}
	return _apply_company_profile_to_definition(
		definition,
		get_company_profile(company_id, include_financial_history, include_statement_history)
	)


func get_effective_company_definitions() -> Array:
	var definitions: Array = []
	for company_id in company_order:
		var definition: Dictionary = get_effective_company_definition(str(company_id))
		if not definition.is_empty():
			definitions.append(definition)
	return definitions


func get_previous_close(company_id: String) -> float:
	var company = get_company(company_id)
	if company.is_empty():
		return 0.0

	var price_history: Array = company.get("price_history", [])
	if price_history.size() >= 2:
		return IDX_PRICE_RULES.normalize_last_price(float(price_history[price_history.size() - 2]))

	return IDX_PRICE_RULES.normalize_last_price(float(company.get("previous_close", company.get("current_price", 0.0))))


func get_holding(company_id: String) -> Dictionary:
	var holdings: Dictionary = player_portfolio.get("holdings", {})
	if not holdings.has(company_id):
		return {}
	return holdings[company_id]


func get_watchlist_company_ids() -> Array:
	var normalized_ids: Array = []
	for company_id_value in watchlist_company_ids:
		var company_id: String = str(company_id_value)
		if company_id.is_empty() or normalized_ids.has(company_id) or not companies.has(company_id):
			continue
		normalized_ids.append(company_id)
	return normalized_ids


func is_in_watchlist(company_id: String) -> bool:
	return get_watchlist_company_ids().has(company_id)


func add_to_watchlist(company_id: String) -> Dictionary:
	if not companies.has(company_id):
		return {"success": false, "message": "Unknown company selection."}
	if is_in_watchlist(company_id):
		return {"success": false, "message": "%s is already in the watchlist." % str(get_effective_company_definition(company_id).get("ticker", company_id.to_upper()))}

	watchlist_company_ids.append(company_id)
	var ticker: String = str(get_effective_company_definition(company_id).get("ticker", company_id.to_upper()))
	return {
		"success": true,
		"message": "%s added to the watchlist." % ticker
	}


func remove_from_watchlist(company_id: String) -> Dictionary:
	if not companies.has(company_id):
		return {"success": false, "message": "Unknown company selection."}
	if not is_in_watchlist(company_id):
		return {"success": false, "message": "%s is not in the watchlist." % str(get_effective_company_definition(company_id).get("ticker", company_id.to_upper()))}

	watchlist_company_ids.erase(company_id)
	var ticker: String = str(get_effective_company_definition(company_id).get("ticker", company_id.to_upper()))
	return {
		"success": true,
		"message": "%s removed from the watchlist." % ticker
	}


func buy_company(company_id: String, shares: int) -> Dictionary:
	if not companies.has(company_id):
		return {"success": false, "message": "Unknown company selection."}
	if shares <= 0:
		return {"success": false, "message": "Share count must be positive."}
	var trade_block_message: String = _company_trade_block_message(company_id)
	if not trade_block_message.is_empty():
		return {"success": false, "message": trade_block_message}

	var estimate: Dictionary = estimate_buy_order(company_id, shares)
	if not bool(estimate.get("success", false)):
		return estimate

	var total_cost = float(estimate.get("total_cost", 0.0))
	var fee = float(estimate.get("fee", 0.0))
	var cash_available = float(player_portfolio.get("cash", 0.0))

	if total_cost > cash_available + 0.0001:
		return {
			"success": false,
			"message": "Not enough cash. Order costs %s, cash is %s. Shortfall: %s. Lower quantity or free up cash first." % [
				_format_currency(total_cost),
				_format_currency(cash_available),
				_format_currency(total_cost - cash_available)
			]
		}

	var holdings: Dictionary = player_portfolio.get("holdings", {})
	var holding: Dictionary = holdings.get(company_id, {
		"company_id": company_id,
		"shares": 0,
		"average_price": 0.0
	})
	var current_shares = int(holding.get("shares", 0))
	var current_average = float(holding.get("average_price", 0.0))
	var new_share_total = current_shares + shares
	var new_average = 0.0

	if new_share_total > 0:
		new_average = ((current_average * current_shares) + total_cost) / float(new_share_total)

	holding["shares"] = new_share_total
	holding["average_price"] = new_average
	holdings[company_id] = holding
	player_portfolio["holdings"] = holdings
	player_portfolio["cash"] = cash_available - total_cost
	_record_trade(
		company_id,
		"buy",
		estimate,
		0.0,
		-total_cost,
		float(player_portfolio.get("cash", 0.0))
	)
	_record_player_market_flow(company_id, "buy", estimate)

	return {
		"success": true,
		"message": "Bought %d lot(s) / %d share(s) of %s for %s including %s fee." % [
			int(estimate.get("lots", 0)),
			shares,
			company_id.to_upper(),
			_format_currency(total_cost),
			_format_currency(fee)
		]
	}


func sell_company(company_id: String, shares: int) -> Dictionary:
	if not companies.has(company_id):
		return {"success": false, "message": "Unknown company selection."}
	if shares <= 0:
		return {"success": false, "message": "Share count must be positive."}
	var trade_block_message: String = _company_trade_block_message(company_id)
	if not trade_block_message.is_empty():
		return {"success": false, "message": trade_block_message}

	var holdings: Dictionary = player_portfolio.get("holdings", {})
	if not holdings.has(company_id):
		return {"success": false, "message": "You do not own that position yet. Switch to Buy, or select a holding you already have."}

	var holding: Dictionary = holdings[company_id]
	var current_shares = int(holding.get("shares", 0))
	if shares > current_shares:
		return {
			"success": false,
			"message": "Not enough shares to sell. You tried to sell %d share(s), but only own %d." % [
				shares,
				current_shares
			]
		}

	var estimate: Dictionary = estimate_sell_order(company_id, shares)
	if not bool(estimate.get("success", false)):
		return estimate

	var fee = float(estimate.get("fee", 0.0))
	var net_proceeds = float(estimate.get("net_proceeds", 0.0))
	var average_price = float(holding.get("average_price", 0.0))
	var realized_pnl = net_proceeds - (average_price * shares)
	var remaining_shares = current_shares - shares

	if remaining_shares <= 0:
		holdings.erase(company_id)
	else:
		holding["shares"] = remaining_shares
		holdings[company_id] = holding

	player_portfolio["holdings"] = holdings
	player_portfolio["cash"] = float(player_portfolio.get("cash", 0.0)) + net_proceeds
	player_portfolio["realized_pnl"] = float(player_portfolio.get("realized_pnl", 0.0)) + realized_pnl
	_record_trade(
		company_id,
		"sell",
		estimate,
		realized_pnl,
		net_proceeds,
		float(player_portfolio.get("cash", 0.0))
	)
	_record_player_market_flow(company_id, "sell", estimate)

	return {
		"success": true,
		"message": "Sold %d lot(s) / %d share(s) of %s for %s after %s fee." % [
			int(estimate.get("lots", 0)),
			shares,
			company_id.to_upper(),
			_format_currency(net_proceeds),
			_format_currency(fee)
		]
	}


func get_portfolio_market_value() -> float:
	var total = 0.0
	var holdings: Dictionary = player_portfolio.get("holdings", {})

	for company_id in holdings.keys():
		if not companies.has(company_id):
			continue

		var holding: Dictionary = holdings[company_id]
		var shares = int(holding.get("shares", 0))
		var current_price = float(companies[company_id].get("current_price", 0.0))
		total += shares * current_price

	return total


func get_total_equity() -> float:
	return float(player_portfolio.get("cash", 0.0)) + get_portfolio_market_value()


func apply_day_result(day_result: Dictionary) -> void:
	var log_apply_perf: bool = _should_log_apply_day_perf()
	var total_started_at_usec: int = Time.get_ticks_usec()
	var phase_started_at_usec: int = total_started_at_usec
	day_index += 1
	daily_action_day_index = day_index
	daily_actions_used = 0
	market_sentiment = float(day_result.get("market_sentiment", market_sentiment))
	last_day_results = _build_last_day_results_save_payload(day_result)
	_log_apply_day_perf_elapsed(log_apply_perf, "basic_state", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var previous_trade_date: Dictionary = current_trade_date.duplicate(true)
	_record_event(day_result.get("scheduled_event", {}), day_result.get("trade_date", {}), int(day_result.get("day_number", day_index)))
	for report_event_value in day_result.get("report_events", []):
		_record_event(report_event_value, day_result.get("trade_date", {}), int(day_result.get("day_number", day_index)))
	for company_arc_value in day_result.get("started_company_arcs", []):
		_record_event(company_arc_value, day_result.get("trade_date", {}), int(day_result.get("day_number", day_index)))
	for company_arc_phase_value in day_result.get("company_arc_phase_events", []):
		_record_event(company_arc_phase_value, day_result.get("trade_date", {}), int(day_result.get("day_number", day_index)))
	for special_event_value in day_result.get("started_special_events", []):
		_record_event(special_event_value, day_result.get("trade_date", {}), int(day_result.get("day_number", day_index)))
	for corporate_event_value in day_result.get("corporate_action_events", []):
		_record_event(corporate_event_value, day_result.get("trade_date", {}), int(day_result.get("day_number", day_index)))
	_log_apply_day_perf_elapsed(log_apply_perf, "record_events", phase_started_at_usec, " events=%d" % event_history.size())
	phase_started_at_usec = Time.get_ticks_usec()
	active_company_arcs = day_result.get("active_company_arcs", []).duplicate(true)
	active_special_events = day_result.get("active_special_events", []).duplicate(true)
	active_corporate_action_chains = day_result.get("active_corporate_action_chains", {}).duplicate(true)
	corporate_meeting_calendar = day_result.get("corporate_meeting_calendar", {}).duplicate(true)
	corporate_action_intel = day_result.get("corporate_action_intel", {}).duplicate(true)
	corporate_dividend_calendar = day_result.get("corporate_dividend_calendar", corporate_dividend_calendar).duplicate(true)
	attended_meetings = day_result.get("attended_meetings", {}).duplicate(true)
	corporate_meeting_sessions = day_result.get("corporate_meeting_sessions", {}).duplicate(true)
	shareholder_registry = day_result.get("shareholder_registry", shareholder_registry).duplicate(true)
	_apply_dividend_payments(day_result.get("dividend_payments", []))
	_log_apply_day_perf_elapsed(log_apply_perf, "active_state_payloads", phase_started_at_usec)

	phase_started_at_usec = Time.get_ticks_usec()
	var applied_company_count: int = 0
	for company_id in day_result.get("companies", {}).keys():
		companies[str(company_id)] = _normalize_day_result_company_runtime(day_result["companies"][company_id])
		applied_company_count += 1
	_apply_corporate_action_applications(day_result.get("corporate_action_applications", []))
	_apply_stock_dividend_distributions(day_result.get("stock_dividend_distributions", []))
	_log_apply_day_perf_elapsed(log_apply_perf, "normalize_companies", phase_started_at_usec, " companies=%d" % applied_company_count)

	phase_started_at_usec = Time.get_ticks_usec()
	current_trade_date = trading_calendar.next_trade_date(current_trade_date)
	var previous_year: int = int(previous_trade_date.get("year", 2020))
	var current_year: int = int(current_trade_date.get("year", previous_year))
	if current_year != previous_year:
		_reset_ytd_open_prices_for_year(current_year)
	_ensure_macro_state_for_year(current_year)
	_prune_player_market_flows(day_index)
	_log_apply_day_perf_elapsed(log_apply_perf, "calendar_and_prune", phase_started_at_usec)
	_log_apply_day_perf_elapsed(log_apply_perf, "total", total_started_at_usec, " companies=%d" % applied_company_count)


func set_daily_summary(summary: Dictionary) -> void:
	daily_summary = summary.duplicate(true)
	_record_market_history(summary)
	last_equity_value = get_total_equity()


func get_desktop_app_seen_day(app_id: String) -> int:
	var normalized_app_id: String = app_id.strip_edges().to_lower()
	if normalized_app_id.is_empty():
		return day_index
	return int(desktop_app_seen_days.get(normalized_app_id, day_index))


func mark_desktop_app_seen(app_id: String, seen_day_index: int = -1) -> void:
	var normalized_app_id: String = app_id.strip_edges().to_lower()
	if normalized_app_id.is_empty():
		return
	var resolved_day_index: int = day_index if seen_day_index < 0 else seen_day_index
	desktop_app_seen_days[normalized_app_id] = resolved_day_index


func get_desktop_app_seen_days() -> Dictionary:
	return desktop_app_seen_days.duplicate(true)


func set_desktop_app_badge_counts(activity_counts: Dictionary, badge_day_index: int = -1) -> void:
	var resolved_day_index: int = day_index if badge_day_index < 0 else badge_day_index
	desktop_app_badge_counts = {
		"day_index": resolved_day_index,
		"counts": {
			"news": max(int(activity_counts.get("news", 0)), 0),
			"social": max(int(activity_counts.get("social", 0)), 0),
			"network": max(int(activity_counts.get("network", 0)), 0)
		}
	}


func get_desktop_app_badge_counts() -> Dictionary:
	if desktop_app_badge_counts.is_empty():
		return {
			"day_index": day_index,
			"counts": {
				"news": 0,
				"social": 0,
				"network": 0
			}
		}
	var badge_day_index: int = int(desktop_app_badge_counts.get("day_index", day_index))
	var counts: Dictionary = desktop_app_badge_counts.get("counts", {}).duplicate(true)
	return {
		"day_index": badge_day_index,
		"counts": {
			"news": max(int(counts.get("news", 0)), 0),
			"social": max(int(counts.get("social", 0)), 0),
			"network": max(int(counts.get("network", 0)), 0)
		}
	}


func get_difficulty_config() -> Dictionary:
	return difficulty_config.duplicate(true)


func get_current_trade_date() -> Dictionary:
	return current_trade_date.duplicate(true)


func get_current_macro_state() -> Dictionary:
	return get_macro_state_for_year(int(current_trade_date.get("year", 2020)))


func get_macro_state_for_year(year: int) -> Dictionary:
	_ensure_macro_state_for_year(year)
	var year_key: String = str(year)
	if not yearly_macro_states.has(year_key):
		return {}
	return yearly_macro_states[year_key].duplicate(true)


func get_macro_state_history() -> Array:
	var year_keys: Array = yearly_macro_states.keys()
	year_keys.sort()
	var history: Array = []
	for year_key_value in year_keys:
		history.append(yearly_macro_states[str(year_key_value)].duplicate(true))
	return history


func get_next_trade_date() -> Dictionary:
	return trading_calendar.next_trade_date(current_trade_date)


func get_quarterly_report_calendar() -> Dictionary:
	if quarterly_report_calendar.is_empty() and not company_order.is_empty():
		quarterly_report_calendar = _build_quarterly_report_calendar()
	return quarterly_report_calendar.duplicate(true)


func get_quarterly_reports_for_date(date_info: Dictionary) -> Array:
	var date_key: String = trading_calendar.to_key(date_info)
	return _reports_for_date_key(date_key)


func get_quarterly_report_events_for_day_number(trading_day_number: int, trade_date: Dictionary) -> Array:
	var reports: Array = get_quarterly_reports_for_date(trade_date)
	var events: Array = []
	for report_value in reports:
		var report: Dictionary = report_value
		events.append(_build_quarterly_report_event(report, trading_day_number, trade_date))
	return events


func get_report_calendar_month(year_value: int, month_value: int) -> Dictionary:
	var reports_by_day: Dictionary = {}
	var reports: Array = []
	if quarterly_report_calendar.is_empty() and not company_order.is_empty():
		quarterly_report_calendar = _build_quarterly_report_calendar()
	var month_prefix: String = "%04d-%02d-" % [year_value, month_value]
	for date_key_value in quarterly_report_calendar.keys():
		var date_key: String = str(date_key_value)
		if not date_key.begins_with(month_prefix):
			continue
		var day_value: int = int(date_key.substr(8, 2))
		var day_key: String = str(day_value)
		if not reports_by_day.has(day_key):
			reports_by_day[day_key] = []
		var date_reports: Array = quarterly_report_calendar.get(date_key, [])
		for report_value in date_reports:
			var report: Dictionary = report_value
			var report_row: Dictionary = report.duplicate(true)
			reports_by_day[day_key].append(report_row)
			reports.append(report_row)
	reports.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("trading_day_number", 0)) == int(b.get("trading_day_number", 0)):
			return str(a.get("ticker", "")) < str(b.get("ticker", ""))
		return int(a.get("trading_day_number", 0)) < int(b.get("trading_day_number", 0))
	)
	return {
		"year": year_value,
		"month": month_value,
		"reports_by_day": reports_by_day,
		"reports": reports
	}


func get_upcoming_quarterly_reports(limit: int = 8) -> Array:
	var reports: Array = []
	var current_key: String = trading_calendar.to_key(current_trade_date)
	if quarterly_report_calendar.is_empty() and not company_order.is_empty():
		quarterly_report_calendar = _build_quarterly_report_calendar()
	var date_keys: Array = quarterly_report_calendar.keys()
	date_keys.sort()
	for date_key_value in date_keys:
		var date_key: String = str(date_key_value)
		if date_key < current_key:
			continue
		var date_reports: Array = quarterly_report_calendar.get(date_key, [])
		for report_value in date_reports:
			var report: Dictionary = report_value
			reports.append(report.duplicate(true))
			if limit > 0 and reports.size() >= limit:
				return reports
	return reports


func get_trade_history() -> Array:
	return trade_history.duplicate(true)


func apply_cash_obligation(obligation_id: String, amount: float, detail: Dictionary = {}) -> Dictionary:
	var normalized_amount: float = max(amount, 0.0)
	if normalized_amount <= 0.0:
		return {"success": false, "message": "No cash obligation to apply."}

	var cash_before: float = float(player_portfolio.get("cash", 0.0))
	var cash_after: float = cash_before - normalized_amount
	player_portfolio["cash"] = cash_after
	var company_id: String = str(detail.get("company_id", "life"))
	var side: String = str(detail.get("side", obligation_id))
	_record_trade(
		company_id,
		side,
		{
			"lots": 0,
			"shares": 0,
			"price_per_share": 0.0,
			"gross_value": normalized_amount,
			"fee_rate": 0.0,
			"fee": 0.0
		},
		0.0,
		-normalized_amount,
		cash_after
	)

	return {
		"success": true,
		"obligation_id": obligation_id,
		"amount": normalized_amount,
		"cash_before": cash_before,
		"cash_after": cash_after,
		"day_index": day_index,
		"trade_date": current_trade_date.duplicate(true),
		"detail": detail.duplicate(true)
	}


func get_player_market_flow_context(company_id: String, target_day_index: int) -> Dictionary:
	_prune_player_market_flows(target_day_index)
	var flow_entries: Array = player_market_flows.get(company_id, [])
	var buy_value: float = 0.0
	var sell_value: float = 0.0
	var buy_shares: float = 0.0
	var sell_shares: float = 0.0
	var buy_free_float_pct: float = 0.0
	var sell_free_float_pct: float = 0.0
	var buy_ownership_pct: float = 0.0
	var sell_ownership_pct: float = 0.0
	var max_single_trade_free_float_pct: float = 0.0
	var max_single_trade_ownership_pct: float = 0.0
	var active_entries: int = 0
	for flow_value in flow_entries:
		var flow: Dictionary = flow_value
		var source_day_index: int = int(flow.get("day_index", day_index))
		var age: int = target_day_index - source_day_index
		if age <= 0 or age > PLAYER_MARKET_FLOW_DECAY_DAYS:
			continue
		var weight: float = _player_flow_decay_weight(age)
		var side: String = str(flow.get("side", ""))
		var gross_value: float = float(flow.get("gross_value", 0.0)) * weight
		var shares: float = float(flow.get("shares", 0.0)) * weight
		var weighted_free_float_pct: float = float(flow.get("trade_free_float_pct", 0.0)) * weight
		var weighted_ownership_pct: float = float(flow.get("trade_ownership_pct", 0.0)) * weight
		if side == "buy":
			buy_value += gross_value
			buy_shares += shares
			buy_free_float_pct += weighted_free_float_pct
			buy_ownership_pct += weighted_ownership_pct
		elif side == "sell":
			sell_value += gross_value
			sell_shares += shares
			sell_free_float_pct += weighted_free_float_pct
			sell_ownership_pct += weighted_ownership_pct
		max_single_trade_free_float_pct = max(max_single_trade_free_float_pct, float(flow.get("trade_free_float_pct", 0.0)) * weight)
		max_single_trade_ownership_pct = max(max_single_trade_ownership_pct, float(flow.get("trade_ownership_pct", 0.0)) * weight)
		active_entries += 1
	return {
		"broker_code": PLAYER_BROKER_CODE,
		"broker_name": PLAYER_BROKER_NAME,
		"buy_value": buy_value,
		"sell_value": sell_value,
		"net_value": buy_value - sell_value,
		"buy_shares": buy_shares,
		"sell_shares": sell_shares,
		"net_shares": buy_shares - sell_shares,
		"buy_free_float_pct": buy_free_float_pct,
		"sell_free_float_pct": sell_free_float_pct,
		"net_free_float_pct": buy_free_float_pct - sell_free_float_pct,
		"gross_free_float_pct": buy_free_float_pct + sell_free_float_pct,
		"buy_ownership_pct": buy_ownership_pct,
		"sell_ownership_pct": sell_ownership_pct,
		"net_ownership_pct": buy_ownership_pct - sell_ownership_pct,
		"max_single_trade_free_float_pct": max_single_trade_free_float_pct,
		"max_single_trade_ownership_pct": max_single_trade_ownership_pct,
		"active_entries": active_entries,
		"decay_days": PLAYER_MARKET_FLOW_DECAY_DAYS
	}


func get_event_history() -> Array:
	return event_history.duplicate(true)


func get_market_history() -> Array:
	return market_history.duplicate(true)


func get_active_company_arcs() -> Array:
	return active_company_arcs.duplicate(true)


func get_active_special_events() -> Array:
	return active_special_events.duplicate(true)


func get_active_corporate_action_chains() -> Dictionary:
	return active_corporate_action_chains.duplicate(true)


func set_active_corporate_action_chains(next_chains: Dictionary) -> void:
	active_corporate_action_chains = next_chains.duplicate(true)


func get_corporate_meeting_calendar() -> Dictionary:
	return corporate_meeting_calendar.duplicate(true)


func set_corporate_meeting_calendar(next_calendar: Dictionary) -> void:
	corporate_meeting_calendar = next_calendar.duplicate(true)


func get_corporate_action_intel() -> Dictionary:
	return corporate_action_intel.duplicate(true)


func set_corporate_action_intel(next_intel: Dictionary) -> void:
	corporate_action_intel = next_intel.duplicate(true)


func get_corporate_dividend_calendar() -> Dictionary:
	return corporate_dividend_calendar.duplicate(true)


func set_corporate_dividend_calendar(next_calendar: Dictionary) -> void:
	corporate_dividend_calendar = next_calendar.duplicate(true)


func get_attended_meetings() -> Dictionary:
	return attended_meetings.duplicate(true)


func set_attended_meetings(next_attended_meetings: Dictionary) -> void:
	attended_meetings = next_attended_meetings.duplicate(true)


func get_corporate_meeting_sessions() -> Dictionary:
	return corporate_meeting_sessions.duplicate(true)


func set_corporate_meeting_sessions(next_sessions: Dictionary) -> void:
	corporate_meeting_sessions = next_sessions.duplicate(true)


func get_shareholder_registry() -> Dictionary:
	return shareholder_registry.duplicate(true)


func set_shareholder_registry(next_registry: Dictionary) -> void:
	shareholder_registry = next_registry.duplicate(true)


func get_network_contacts() -> Dictionary:
	return network_contacts.duplicate(true)


func set_network_contacts(next_contacts: Dictionary) -> void:
	network_contacts = next_contacts.duplicate(true)


func get_network_discoveries() -> Dictionary:
	return network_discoveries.duplicate(true)


func set_network_discoveries(next_discoveries: Dictionary) -> void:
	network_discoveries = next_discoveries.duplicate(true)


func get_network_requests() -> Dictionary:
	return network_requests.duplicate(true)


func set_network_requests(next_requests: Dictionary) -> void:
	network_requests = next_requests.duplicate(true)


func get_network_tip_journal() -> Dictionary:
	return network_tip_journal.duplicate(true)


func set_network_tip_journal(next_tip_journal: Dictionary) -> void:
	network_tip_journal = next_tip_journal.duplicate(true)


func get_player_theses() -> Dictionary:
	player_theses = _normalize_player_theses(player_theses)
	return player_theses.duplicate(true)


func get_player_thesis(thesis_id: String) -> Dictionary:
	player_theses = _normalize_player_theses(player_theses)
	if thesis_id.is_empty() or not player_theses.has(thesis_id):
		return {}
	return player_theses[thesis_id].duplicate(true)


func set_player_thesis(thesis: Dictionary) -> void:
	var thesis_id: String = str(thesis.get("id", ""))
	if thesis_id.is_empty():
		return
	player_theses = _normalize_player_theses(player_theses)
	player_theses[thesis_id] = _normalize_player_thesis(thesis)


func set_player_theses(next_theses: Dictionary) -> void:
	player_theses = _normalize_player_theses(next_theses)


func get_player_life() -> Dictionary:
	player_life = _normalize_life_state(player_life)
	return player_life.duplicate(true)


func set_player_life(next_life: Dictionary) -> void:
	player_life = _normalize_life_state(next_life)


func get_academy_progress() -> Dictionary:
	academy_progress = _normalize_academy_progress(academy_progress)
	return academy_progress.duplicate(true)


func set_academy_progress(next_progress: Dictionary) -> void:
	academy_progress = _normalize_academy_progress(next_progress)


func get_upgrade_tiers() -> Dictionary:
	upgrade_tiers = _normalize_upgrade_tiers(upgrade_tiers)
	return upgrade_tiers.duplicate(true)


func get_upgrade_tier(track_id: String) -> int:
	upgrade_tiers = _normalize_upgrade_tiers(upgrade_tiers)
	return int(upgrade_tiers.get(track_id, DEFAULT_UPGRADE_TIER))


func set_upgrade_tier(track_id: String, tier: int) -> void:
	if not (track_id in UPGRADE_TRACK_IDS):
		return
	upgrade_tiers[track_id] = clamp(tier, 1, DEFAULT_UPGRADE_TIER)


func get_effective_buy_fee_rate() -> float:
	var tier: int = get_upgrade_tier("trading_fee")
	return float(TRADING_FEE_BY_TIER.get(tier, TRADING_FEE_BY_TIER[DEFAULT_UPGRADE_TIER]).get("buy_fee_rate", BUY_FEE_RATE))


func get_effective_sell_fee_rate() -> float:
	var tier: int = get_upgrade_tier("trading_fee")
	return float(TRADING_FEE_BY_TIER.get(tier, TRADING_FEE_BY_TIER[DEFAULT_UPGRADE_TIER]).get("sell_fee_rate", SELL_FEE_RATE))


func get_daily_action_limit() -> int:
	var tier: int = get_upgrade_tier("daily_action_points")
	return int(DAILY_ACTION_LIMIT_BY_TIER.get(tier, DAILY_ACTION_LIMIT_BY_TIER[DEFAULT_UPGRADE_TIER]))


func get_daily_action_snapshot() -> Dictionary:
	_sync_daily_action_day()
	var limit: int = get_daily_action_limit()
	return {
		"day_index": daily_action_day_index,
		"used": daily_actions_used,
		"limit": limit,
		"remaining": max(limit - daily_actions_used, 0),
		"tier": get_upgrade_tier("daily_action_points")
	}


func can_spend_daily_action(cost: int = 1) -> bool:
	var snapshot: Dictionary = get_daily_action_snapshot()
	return int(snapshot.get("remaining", 0)) >= max(cost, 0)


func spend_daily_action(cost: int = 1) -> Dictionary:
	_sync_daily_action_day()
	var resolved_cost: int = max(cost, 0)
	var limit: int = get_daily_action_limit()
	if daily_actions_used + resolved_cost > limit:
		return {
			"success": false,
			"message": "No daily action points left.",
			"snapshot": get_daily_action_snapshot()
		}
	daily_actions_used += resolved_cost
	return {
		"success": true,
		"message": "Daily action spent.",
		"snapshot": get_daily_action_snapshot()
	}


func add_network_company_arc(arc_data: Dictionary) -> void:
	if arc_data.is_empty():
		return
	active_company_arcs.append(arc_data.duplicate(true))
	_append_company_arc_to_companies(arc_data)


func record_news_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return

	var outlet_label_lookup: Dictionary = {}
	for outlet_value in snapshot.get("outlets", []):
		var outlet: Dictionary = outlet_value
		outlet_label_lookup[str(outlet.get("id", ""))] = str(outlet.get("label", "News"))

	var feeds: Dictionary = snapshot.get("feeds", {})
	for outlet_id_value in feeds.keys():
		var outlet_id: String = str(outlet_id_value)
		var feed: Dictionary = feeds.get(outlet_id, {})
		var outlet_label: String = str(feed.get("outlet_label", outlet_label_lookup.get(outlet_id, "News")))
		for article_value in feed.get("articles", []):
			var article: Dictionary = article_value
			_upsert_news_archive_article(outlet_id, outlet_label, article)


func get_news_archive_years(outlet_id: String) -> Array:
	var outlet_bucket: Dictionary = news_archive_index.get(outlet_id, {})
	var years_bucket: Dictionary = outlet_bucket.get("years", {})
	var years: Array = []
	for year_key_value in years_bucket.keys():
		years.append(int(year_key_value))
	years.sort()
	years.reverse()
	return years


func get_news_archive_months(outlet_id: String, year: int) -> Array:
	var outlet_bucket: Dictionary = news_archive_index.get(outlet_id, {})
	var year_bucket: Dictionary = outlet_bucket.get("years", {}).get(str(year), {})
	var months_bucket: Dictionary = year_bucket.get("months", {})
	var months: Array = []
	for month_key_value in months_bucket.keys():
		months.append(int(month_key_value))
	months.sort()
	months.reverse()
	return months


func get_news_archive_article_summaries(outlet_id: String, year: int, month: int) -> Array:
	var outlet_bucket: Dictionary = news_archive_index.get(outlet_id, {})
	var year_bucket: Dictionary = outlet_bucket.get("years", {}).get(str(year), {})
	var month_bucket: Dictionary = year_bucket.get("months", {}).get(str(month), {})
	return month_bucket.get("articles", []).duplicate(true)


func get_news_archive_article(article_id: String) -> Dictionary:
	return news_archive_articles.get(article_id, {}).duplicate(true)


func debug_add_recorded_event(event_data: Dictionary) -> void:
	if event_data.is_empty():
		return

	var resolved_trade_date: Dictionary = current_trade_date.duplicate(true)
	var resolved_day_index: int = max(day_index, 1)
	_record_event(event_data, resolved_trade_date, resolved_day_index)
	_append_event_to_companies(event_data)


func debug_add_special_event(event_data: Dictionary) -> void:
	if event_data.is_empty():
		return

	active_special_events.append(event_data.duplicate(true))
	var resolved_trade_date: Dictionary = current_trade_date.duplicate(true)
	var resolved_day_index: int = max(day_index, 1)
	_record_event(event_data, resolved_trade_date, resolved_day_index)
	_append_event_to_companies(event_data)


func debug_add_company_arc(arc_data: Dictionary, start_event: Dictionary) -> void:
	if arc_data.is_empty():
		return

	active_company_arcs.append(arc_data.duplicate(true))
	if not start_event.is_empty():
		var resolved_trade_date: Dictionary = current_trade_date.duplicate(true)
		var resolved_day_index: int = max(day_index, 1)
		_record_event(start_event, resolved_trade_date, resolved_day_index)
	_append_company_arc_to_companies(arc_data)


func estimate_buy_order(company_id: String, shares: int) -> Dictionary:
	return _estimate_order(company_id, shares, true)


func estimate_sell_order(company_id: String, shares: int) -> Dictionary:
	return _estimate_order(company_id, shares, false)


func should_show_tutorial() -> bool:
	return should_show_ftue()


func mark_tutorial_shown() -> void:
	tutorial_shown = true
	if ftue_enabled and not ftue_completed and not ftue_skipped:
		mark_ftue_completed()


func should_show_ftue() -> bool:
	return ftue_enabled and not ftue_completed and not ftue_skipped and not ftue_current_step_id.is_empty()


func get_ftue_snapshot() -> Dictionary:
	var step_index: int = FTUE_STEP_IDS.find(ftue_current_step_id)
	return {
		"enabled": ftue_enabled,
		"completed": ftue_completed,
		"skipped": ftue_skipped,
		"current_step_id": ftue_current_step_id,
		"completed_step_ids": ftue_completed_step_ids.duplicate(),
		"start_day_index": ftue_start_day_index,
		"step_index": step_index,
		"step_count": FTUE_STEP_IDS.size()
	}


func advance_ftue_step(step_id: String = "") -> bool:
	if not should_show_ftue():
		return false
	var current_step_id: String = ftue_current_step_id
	if not step_id.is_empty() and step_id != current_step_id:
		return false
	if not ftue_completed_step_ids.has(current_step_id):
		ftue_completed_step_ids.append(current_step_id)
	if current_step_id == FTUE_FINAL_STEP_ID:
		mark_ftue_completed()
		return true
	var current_index: int = FTUE_STEP_IDS.find(current_step_id)
	if current_index < 0 or current_index >= FTUE_STEP_IDS.size() - 1:
		mark_ftue_completed()
		return true
	ftue_current_step_id = str(FTUE_STEP_IDS[current_index + 1])
	return true


func skip_ftue() -> bool:
	if not ftue_enabled or ftue_completed or ftue_skipped:
		return false
	ftue_skipped = true
	ftue_current_step_id = ""
	tutorial_shown = true
	if first_hour_guide_enabled and not first_hour_guide_completed:
		first_hour_guide_skipped = true
		first_hour_guide_current_step_id = ""
	return true


func mark_ftue_completed() -> bool:
	if not ftue_enabled or ftue_completed:
		return false
	ftue_completed = true
	ftue_current_step_id = ""
	tutorial_shown = true
	_start_first_hour_guide_if_needed()
	return true


func should_show_first_hour_guide() -> bool:
	return (
		first_hour_guide_enabled and
		not first_hour_guide_completed and
		not first_hour_guide_skipped and
		not first_hour_guide_current_step_id.is_empty()
	)


func get_first_hour_guide_snapshot() -> Dictionary:
	var step_index: int = FIRST_HOUR_GUIDE_STEP_IDS.find(first_hour_guide_current_step_id)
	return {
		"enabled": first_hour_guide_enabled,
		"completed": first_hour_guide_completed,
		"skipped": first_hour_guide_skipped,
		"current_step_id": first_hour_guide_current_step_id,
		"completed_step_ids": first_hour_guide_completed_step_ids.duplicate(),
		"start_day_index": first_hour_guide_start_day_index,
		"step_index": step_index,
		"step_count": FIRST_HOUR_GUIDE_STEP_IDS.size(),
		"anchor_company_id": first_hour_guide_anchor_company_id,
		"seeded_meeting_id": first_hour_guide_seeded_meeting_id,
		"seeded_chain_id": first_hour_guide_seeded_chain_id
	}


func advance_first_hour_guide_step(step_id: String = "") -> bool:
	if not should_show_first_hour_guide():
		return false
	var current_step_id: String = first_hour_guide_current_step_id
	if not step_id.is_empty() and step_id != current_step_id:
		return false
	if not first_hour_guide_completed_step_ids.has(current_step_id):
		first_hour_guide_completed_step_ids.append(current_step_id)
	if current_step_id == FIRST_HOUR_GUIDE_FINAL_STEP_ID:
		mark_first_hour_guide_completed()
		return true
	var current_index: int = FIRST_HOUR_GUIDE_STEP_IDS.find(current_step_id)
	if current_index < 0 or current_index >= FIRST_HOUR_GUIDE_STEP_IDS.size() - 1:
		mark_first_hour_guide_completed()
		return true
	first_hour_guide_current_step_id = str(FIRST_HOUR_GUIDE_STEP_IDS[current_index + 1])
	return true


func skip_first_hour_guide() -> bool:
	if not first_hour_guide_enabled or first_hour_guide_completed or first_hour_guide_skipped:
		return false
	first_hour_guide_skipped = true
	first_hour_guide_current_step_id = ""
	return true


func mark_first_hour_guide_completed() -> bool:
	if not first_hour_guide_enabled or first_hour_guide_completed:
		return false
	first_hour_guide_completed = true
	first_hour_guide_current_step_id = ""
	return true


func set_first_hour_guide_anchor_company_id(company_id: String) -> bool:
	var normalized_company_id: String = company_id.strip_edges()
	if normalized_company_id == first_hour_guide_anchor_company_id:
		return false
	first_hour_guide_anchor_company_id = normalized_company_id
	return true


func set_first_hour_guide_seeded_hook(chain_id: String, meeting_id: String) -> bool:
	var normalized_chain_id: String = chain_id.strip_edges()
	var normalized_meeting_id: String = meeting_id.strip_edges()
	if normalized_chain_id == first_hour_guide_seeded_chain_id and normalized_meeting_id == first_hour_guide_seeded_meeting_id:
		return false
	first_hour_guide_seeded_chain_id = normalized_chain_id
	first_hour_guide_seeded_meeting_id = normalized_meeting_id
	return true


func _load_ftue_state(data: Dictionary) -> void:
	if data.has("ftue_enabled"):
		ftue_enabled = bool(data.get("ftue_enabled", false))
		ftue_completed = bool(data.get("ftue_completed", false))
		ftue_skipped = bool(data.get("ftue_skipped", false))
		ftue_current_step_id = str(data.get("ftue_current_step_id", ""))
		ftue_completed_step_ids = _normalize_ftue_completed_step_ids(data.get("ftue_completed_step_ids", []))
		ftue_start_day_index = max(int(data.get("ftue_start_day_index", day_index)), 0)
	else:
		ftue_enabled = tutorial_enabled
		ftue_completed = tutorial_shown
		ftue_skipped = false
		ftue_current_step_id = "" if tutorial_shown or not tutorial_enabled else FTUE_FIRST_STEP_ID
		ftue_completed_step_ids = []
		ftue_start_day_index = day_index

	if not ftue_enabled:
		ftue_completed = false
		ftue_skipped = false
		ftue_current_step_id = ""
		ftue_completed_step_ids = []
		return
	if ftue_completed or ftue_skipped:
		ftue_current_step_id = ""
		tutorial_shown = true
		return
	if not FTUE_STEP_IDS.has(ftue_current_step_id):
		ftue_current_step_id = FTUE_FIRST_STEP_ID


func _load_first_hour_guide_state(data: Dictionary) -> void:
	if not data.has("first_hour_guide_enabled"):
		first_hour_guide_enabled = false
		first_hour_guide_completed = false
		first_hour_guide_skipped = false
		first_hour_guide_current_step_id = ""
		first_hour_guide_completed_step_ids = []
		first_hour_guide_start_day_index = day_index
		first_hour_guide_anchor_company_id = ""
		first_hour_guide_seeded_meeting_id = ""
		first_hour_guide_seeded_chain_id = ""
		return

	first_hour_guide_enabled = bool(data.get("first_hour_guide_enabled", false))
	first_hour_guide_completed = bool(data.get("first_hour_guide_completed", false))
	first_hour_guide_skipped = bool(data.get("first_hour_guide_skipped", false))
	first_hour_guide_current_step_id = str(data.get("first_hour_guide_current_step_id", ""))
	first_hour_guide_completed_step_ids = _normalize_first_hour_guide_completed_step_ids(data.get("first_hour_guide_completed_step_ids", []))
	first_hour_guide_start_day_index = max(int(data.get("first_hour_guide_start_day_index", day_index)), 0)
	first_hour_guide_anchor_company_id = str(data.get("first_hour_guide_anchor_company_id", "")).strip_edges()
	first_hour_guide_seeded_meeting_id = str(data.get("first_hour_guide_seeded_meeting_id", "")).strip_edges()
	first_hour_guide_seeded_chain_id = str(data.get("first_hour_guide_seeded_chain_id", "")).strip_edges()

	if not first_hour_guide_enabled:
		first_hour_guide_completed = false
		first_hour_guide_skipped = false
		first_hour_guide_current_step_id = ""
		first_hour_guide_completed_step_ids = []
		first_hour_guide_anchor_company_id = ""
		first_hour_guide_seeded_meeting_id = ""
		first_hour_guide_seeded_chain_id = ""
		return
	if first_hour_guide_completed or first_hour_guide_skipped:
		first_hour_guide_current_step_id = ""
		return
	if first_hour_guide_current_step_id.is_empty():
		return
	if not FIRST_HOUR_GUIDE_STEP_IDS.has(first_hour_guide_current_step_id):
		first_hour_guide_current_step_id = FIRST_HOUR_GUIDE_FIRST_STEP_ID


func _normalize_ftue_completed_step_ids(source_ids: Variant) -> Array:
	var normalized: Array = []
	if typeof(source_ids) != TYPE_ARRAY:
		return normalized
	for step_id_value in source_ids:
		var step_id: String = str(step_id_value)
		if step_id.is_empty() or not FTUE_STEP_IDS.has(step_id) or normalized.has(step_id):
			continue
		normalized.append(step_id)
	return normalized


func _normalize_first_hour_guide_completed_step_ids(source_ids: Variant) -> Array:
	var normalized: Array = []
	if typeof(source_ids) != TYPE_ARRAY:
		return normalized
	for step_id_value in source_ids:
		var step_id: String = str(step_id_value)
		if step_id.is_empty() or not FIRST_HOUR_GUIDE_STEP_IDS.has(step_id) or normalized.has(step_id):
			continue
		normalized.append(step_id)
	return normalized


func _start_first_hour_guide_if_needed() -> void:
	if (
		not first_hour_guide_enabled or
		first_hour_guide_completed or
		first_hour_guide_skipped or
		not first_hour_guide_current_step_id.is_empty()
	):
		return
	first_hour_guide_current_step_id = FIRST_HOUR_GUIDE_FIRST_STEP_ID
	first_hour_guide_start_day_index = day_index
	first_hour_guide_anchor_company_id = _choose_first_hour_guide_anchor_company_id()


func _choose_first_hour_guide_anchor_company_id() -> String:
	for trade_value in trade_history:
		if typeof(trade_value) != TYPE_DICTIONARY:
			continue
		var trade: Dictionary = trade_value
		var company_id: String = str(trade.get("company_id", "")).strip_edges()
		if (
			str(trade.get("side", "")) == "buy" and
			not company_id.is_empty() and
			companies.has(company_id) and
			int(get_holding(company_id).get("shares", 0)) >= LOT_SIZE
		):
			return company_id
	var holdings: Dictionary = player_portfolio.get("holdings", {})
	for company_id_value in holdings.keys():
		var company_id: String = str(company_id_value).strip_edges()
		if not company_id.is_empty() and companies.has(company_id) and int(get_holding(company_id).get("shares", 0)) >= LOT_SIZE:
			return company_id
	return ""


func _seed_hidden_story_flags(definition: Dictionary) -> Array:
	var hidden_flags = []
	for narrative_tag in definition.get("narrative_tags", []):
		if str(narrative_tag) in ["stealth_interest", "institution_quality", "supportive_balance_sheet"]:
			hidden_flags.append(str(narrative_tag))
	return hidden_flags


func _default_upgrade_tiers() -> Dictionary:
	var defaults: Dictionary = {}
	for track_id_value in UPGRADE_TRACK_IDS:
		defaults[str(track_id_value)] = DEFAULT_UPGRADE_TIER
	return defaults


func _normalize_upgrade_tiers(source_tiers: Dictionary) -> Dictionary:
	var normalized: Dictionary = _default_upgrade_tiers()
	for track_id_value in UPGRADE_TRACK_IDS:
		var track_id: String = str(track_id_value)
		normalized[track_id] = clamp(int(source_tiers.get(track_id, DEFAULT_UPGRADE_TIER)), 1, DEFAULT_UPGRADE_TIER)
	return normalized


func _default_academy_progress() -> Dictionary:
	return {
		"read_sections": {},
		"inline_checks": {},
		"quiz_attempts": {},
		"quiz_best_score": {},
		"quiz_passed": {},
		"badges": [],
		"completed_modules": [],
		"last_category_id": "technical",
		"last_section_id": "intro"
	}


func _normalize_academy_progress(source_progress: Variant) -> Dictionary:
	var normalized: Dictionary = _default_academy_progress()
	if typeof(source_progress) != TYPE_DICTIONARY:
		return normalized

	var source: Dictionary = source_progress
	var read_sections: Variant = source.get("read_sections", {})
	if typeof(read_sections) == TYPE_DICTIONARY:
		normalized["read_sections"] = read_sections.duplicate(true)
	var inline_checks: Variant = source.get("inline_checks", {})
	if typeof(inline_checks) == TYPE_DICTIONARY:
		normalized["inline_checks"] = inline_checks.duplicate(true)
	var quiz_attempts: Variant = source.get("quiz_attempts", {})
	if typeof(quiz_attempts) == TYPE_DICTIONARY:
		normalized["quiz_attempts"] = quiz_attempts.duplicate(true)
	var quiz_best_score: Variant = source.get("quiz_best_score", {})
	if typeof(quiz_best_score) == TYPE_DICTIONARY:
		normalized["quiz_best_score"] = quiz_best_score.duplicate(true)
	var quiz_passed: Variant = source.get("quiz_passed", {})
	if typeof(quiz_passed) == TYPE_DICTIONARY:
		normalized["quiz_passed"] = quiz_passed.duplicate(true)
	normalized["badges"] = _normalize_unique_string_array(source.get("badges", []))
	normalized["completed_modules"] = _normalize_unique_string_array(source.get("completed_modules", []))
	normalized["last_category_id"] = str(source.get("last_category_id", "technical"))
	normalized["last_section_id"] = str(source.get("last_section_id", "intro"))
	return normalized


func _default_life_state() -> Dictionary:
	return {
		"housing_id": "kost_room",
		"lifestyle_id": "balanced",
		"monthly_extra": 0.0,
		"updated_day_index": day_index,
		"last_obligation_period": "",
		"last_obligation_day_index": -1,
		"last_obligation_amount": 0.0
	}


func _normalize_life_state(source_life: Variant) -> Dictionary:
	var normalized: Dictionary = _default_life_state()
	if typeof(source_life) != TYPE_DICTIONARY:
		return normalized

	var source: Dictionary = source_life
	var housing_id: String = str(source.get("housing_id", normalized.get("housing_id", "")))
	if not (housing_id in ["family_home", "kost_room", "apartment"]):
		housing_id = str(normalized.get("housing_id", "kost_room"))
	var lifestyle_id: String = str(source.get("lifestyle_id", normalized.get("lifestyle_id", "")))
	if not (lifestyle_id in ["frugal", "balanced", "status"]):
		lifestyle_id = str(normalized.get("lifestyle_id", "balanced"))
	normalized["housing_id"] = housing_id
	normalized["lifestyle_id"] = lifestyle_id
	normalized["monthly_extra"] = max(float(source.get("monthly_extra", 0.0)), 0.0)
	normalized["updated_day_index"] = max(int(source.get("updated_day_index", day_index)), 0)
	normalized["last_obligation_period"] = str(source.get("last_obligation_period", ""))
	normalized["last_obligation_day_index"] = int(source.get("last_obligation_day_index", -1))
	normalized["last_obligation_amount"] = max(float(source.get("last_obligation_amount", 0.0)), 0.0)
	if source.has("updated_trade_date") and typeof(source.get("updated_trade_date")) == TYPE_DICTIONARY:
		normalized["updated_trade_date"] = source.get("updated_trade_date", {}).duplicate(true)
	if source.has("last_obligation_trade_date") and typeof(source.get("last_obligation_trade_date")) == TYPE_DICTIONARY:
		normalized["last_obligation_trade_date"] = source.get("last_obligation_trade_date", {}).duplicate(true)
	return normalized


func _normalize_player_theses(source_theses: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if typeof(source_theses) != TYPE_DICTIONARY:
		return normalized
	var source: Dictionary = source_theses
	for thesis_id_value in source.keys():
		var thesis_id: String = str(thesis_id_value)
		if thesis_id.is_empty() or typeof(source.get(thesis_id_value)) != TYPE_DICTIONARY:
			continue
		var thesis: Dictionary = _normalize_player_thesis(source.get(thesis_id_value, {}))
		if str(thesis.get("id", "")).is_empty():
			thesis["id"] = thesis_id
		normalized[str(thesis.get("id", thesis_id))] = thesis
	return normalized


func _normalize_player_thesis(source_thesis: Variant) -> Dictionary:
	var source: Dictionary = source_thesis if typeof(source_thesis) == TYPE_DICTIONARY else {}
	var thesis_id: String = str(source.get("id", ""))
	var evidence: Array = []
	for evidence_value in source.get("evidence", []):
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = evidence_value
		var evidence_id: String = str(row.get("id", ""))
		if evidence_id.is_empty():
			evidence_id = "evidence_%03d" % evidence.size()
		var normalized_row: Dictionary = {
			"id": evidence_id,
			"category": str(row.get("category", "")),
			"category_label": str(row.get("category_label", "")),
			"label": str(row.get("label", "")),
			"value": str(row.get("value", "")),
			"detail": str(row.get("detail", "")),
			"source_label": str(row.get("source_label", "")),
			"impact": str(row.get("impact", "mixed")),
			"day_index": int(row.get("day_index", day_index))
		}
		for key_value in [
			"company_id",
			"ticker",
			"pattern_id",
			"pattern_label",
			"feedback_state",
			"feedback_reason",
			"invalidation",
			"next_check",
			"chart_range",
			"chart_range_label",
			"region_label"
		]:
			var key: String = str(key_value)
			if row.has(key):
				normalized_row[key] = str(row.get(key, ""))
		for key_value in ["start_price", "end_price", "current_price"]:
			var key: String = str(key_value)
			if row.has(key):
				normalized_row[key] = float(row.get(key, 0.0))
		for key_value in ["start_anchor", "end_anchor", "start_date", "end_date", "report_date"]:
			var key: String = str(key_value)
			if typeof(row.get(key, {})) == TYPE_DICTIONARY:
				normalized_row[key] = row.get(key, {}).duplicate(true)
		evidence.append(normalized_row)
	return {
		"id": thesis_id,
		"company_id": str(source.get("company_id", "")),
		"ticker": str(source.get("ticker", "")),
		"company_name": str(source.get("company_name", "")),
		"title": str(source.get("title", "")),
		"stance": str(source.get("stance", "bullish")),
		"horizon": str(source.get("horizon", "swing")),
		"status": str(source.get("status", "open")),
		"created_day_index": int(source.get("created_day_index", day_index)),
		"created_trade_date": source.get("created_trade_date", {}).duplicate(true) if typeof(source.get("created_trade_date", {})) == TYPE_DICTIONARY else {},
		"updated_day_index": int(source.get("updated_day_index", day_index)),
		"evidence": evidence,
		"report": source.get("report", {}).duplicate(true) if typeof(source.get("report", {})) == TYPE_DICTIONARY else {},
		"review": source.get("review", {}).duplicate(true) if typeof(source.get("review", {})) == TYPE_DICTIONARY else {}
	}


func _normalize_unique_string_array(source_values: Variant) -> Array:
	var normalized: Array = []
	if typeof(source_values) != TYPE_ARRAY:
		return normalized
	for value in source_values:
		var normalized_value: String = str(value)
		if normalized_value.is_empty() or normalized.has(normalized_value):
			continue
		normalized.append(normalized_value)
	return normalized


func _sync_daily_action_day() -> void:
	if daily_action_day_index == day_index:
		return
	daily_action_day_index = day_index
	daily_actions_used = 0


func _empty_broker_flow() -> Dictionary:
	return {
		"retail_net": 0.0,
		"foreign_net": 0.0,
		"institution_net": 0.0,
		"bandar_net": 0.0,
		"zombie_net": 0.0,
		"net_pressure": 0.0,
		"smart_money_pressure": 0.0,
		"dominant_buyer": "balanced",
		"dominant_seller": "balanced",
		"dominant_buy_broker_code": "",
		"dominant_buy_broker_name": "",
		"dominant_buy_broker_type": "",
		"dominant_sell_broker_code": "",
		"dominant_sell_broker_name": "",
		"dominant_sell_broker_type": "",
		"flow_tag": "neutral",
		"action_meter_score": 0.0,
		"action_meter_label": "Neutral",
		"buy_brokers": [],
		"sell_brokers": [],
		"broker_type_totals": {},
		"net_buy_brokers": [],
		"net_sell_brokers": []
	}


func _record_trade(
	company_id: String,
	side: String,
	estimate: Dictionary,
	realized_pnl: float,
	net_cash_impact: float,
	cash_after: float
) -> void:
	var entry: Dictionary = {
		"day_index": day_index,
		"company_id": company_id,
		"side": side,
		"lots": int(estimate.get("lots", 0)),
		"shares": int(estimate.get("shares", 0)),
		"broker_code": PLAYER_BROKER_CODE,
		"broker_name": PLAYER_BROKER_NAME,
		"price_per_share": float(estimate.get("price_per_share", 0.0)),
		"gross_value": float(estimate.get("gross_value", 0.0)),
		"fee_rate": float(estimate.get("fee_rate", 0.0)),
		"fee": float(estimate.get("fee", 0.0)),
		"net_cash_impact": net_cash_impact,
		"cash_after": cash_after,
		"realized_pnl": realized_pnl
	}

	trade_history.append(entry)
	if trade_history.size() > MAX_TRADE_HISTORY:
		trade_history = trade_history.slice(trade_history.size() - MAX_TRADE_HISTORY, trade_history.size())


func _apply_dividend_payments(payments: Array) -> void:
	if payments.is_empty():
		return
	for payment_value in payments:
		if typeof(payment_value) != TYPE_DICTIONARY:
			continue
		var payment: Dictionary = payment_value
		var amount: float = float(payment.get("amount", 0.0))
		if amount <= 0.0:
			continue
		var cash_before: float = float(player_portfolio.get("cash", 0.0))
		var cash_after: float = cash_before + amount
		player_portfolio["cash"] = cash_after
		var shares: int = int(payment.get("shares", 0))
		var amount_per_share: float = float(payment.get("amount_per_share", 0.0))
		_record_trade(
			str(payment.get("company_id", "")),
			"dividend",
			{
				"lots": int(floor(float(shares) / float(LOT_SIZE))),
				"shares": shares,
				"price_per_share": amount_per_share,
				"gross_value": amount,
				"fee_rate": 0.0,
				"fee": 0.0
			},
			0.0,
			amount,
			cash_after
		)


func _apply_corporate_action_applications(applications: Array) -> void:
	if applications.is_empty():
		return
	for application_value in applications:
		if typeof(application_value) != TYPE_DICTIONARY:
			continue
		var application: Dictionary = application_value
		match str(application.get("application_type", "")):
			"rights_issue":
				_apply_rights_issue_application(application)
			"private_placement":
				_apply_private_placement_application(application)
			"restructuring":
				_apply_restructuring_application(application)
			"stock_buyback":
				_apply_stock_buyback_application(application)
			"stock_split":
				_apply_stock_split_application(application)
			"tender_offer":
				_apply_tender_offer_application(application)
			"strategic_merger_acquisition":
				_apply_strategic_mna_application(application)
			"backdoor_listing":
				_apply_backdoor_listing_application(application)
			"ceo_change":
				_apply_ceo_change_application(application)
			"backdoor_lockup_update":
				_apply_backdoor_lockup_update_application(application)
			"backdoor_milestone_update":
				_apply_backdoor_milestone_update_application(application)


func _apply_rights_issue_application(application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not companies.has(company_id):
		return
	var new_shares: float = max(float(application.get("new_shares", 0.0)), 0.0)
	if new_shares <= 0.0:
		return
	var definition: Dictionary = get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var gross_proceeds: float = max(float(application.get("gross_proceeds", 0.0)), 0.0)
	var new_shares_outstanding: float = max(float(application.get("new_shares_outstanding", old_shares_outstanding + new_shares)), 1.0)
	var theoretical_price: float = float(application.get("theoretical_ex_rights_price", 0.0))
	if theoretical_price <= 0.0:
		theoretical_price = (old_price * old_shares_outstanding + gross_proceeds) / new_shares_outstanding
	var max_down: float = clamp(float(application.get("maximum_price_adjustment_down_pct", 0.35)), 0.0, 0.9)
	var max_up: float = clamp(float(application.get("maximum_price_adjustment_up_pct", 0.08)), 0.0, 0.5)
	var price_factor: float = clamp(theoretical_price / old_price, 1.0 - max_down, 1.0 + max_up)
	if bool(application.get("linked_backdoor_listing", false)):
		var strategic_unlock_pct: float = clamp(float(application.get("strategic_funding_unlock_pct", 0.0)), -0.3, 0.3)
		var dilution_overhang_pct: float = clamp(float(application.get("dilution_overhang_pct", application.get("entitlement_ratio", 0.0))), 0.0, 1.0)
		var linked_price_factor: float = 1.0 + strategic_unlock_pct - dilution_overhang_pct * 0.22
		price_factor = clamp(price_factor * linked_price_factor, 1.0 - max_down, 1.0 + max_up)
	var new_price: float = _apply_company_price_factor(company_id, price_factor, false)
	var free_float_pct: float = float(financials.get("free_float_pct", 35.0))
	var player_record_shares: int = max(int(application.get("player_record_shares", 0)), 0)
	var player_entitled_shares: int = max(int(application.get("player_entitled_shares", 0)), 0)
	var exercise_price: float = max(float(application.get("exercise_price", 0.0)), 0.0)
	var exercise_cost: float = round(float(player_entitled_shares) * exercise_price * 100.0) / 100.0
	var player_status: String = "not_eligible"
	var player_exercised_shares: int = 0
	if player_entitled_shares > 0:
		if exercise_cost <= float(player_portfolio.get("cash", 0.0)) + 0.0001:
			player_status = "exercised"
			player_exercised_shares = player_entitled_shares
		else:
			player_status = "lapsed_insufficient_cash"
	_set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		free_float_pct,
		{
			"type": "rights_issue",
			"chain_id": str(application.get("chain_id", "")),
			"meeting_id": str(application.get("meeting_id", "")),
			"ratio_numerator": int(application.get("ratio_numerator", 1)),
			"ratio_denominator": int(application.get("ratio_denominator", 1)),
			"entitlement_ratio": float(application.get("entitlement_ratio", 0.0)),
			"new_shares": new_shares,
			"exercise_price": exercise_price,
			"gross_proceeds": gross_proceeds,
			"discount_pct": float(application.get("discount_pct", 0.0)),
			"theoretical_ex_rights_price": theoretical_price,
			"old_shares_outstanding": old_shares_outstanding,
			"new_shares_outstanding": new_shares_outstanding,
			"player_record_shares": player_record_shares,
			"player_entitled_shares": player_entitled_shares,
			"player_exercised_shares": player_exercised_shares,
			"player_rights_status": player_status,
			"player_exercise_cost": exercise_cost,
			"linked_backdoor_listing": bool(application.get("linked_backdoor_listing", false)),
			"source_backdoor_chain_id": str(application.get("source_backdoor_chain_id", "")),
			"source_backdoor_application_day": int(application.get("source_backdoor_application_day", 0)),
			"incoming_asset_label": str(application.get("incoming_asset_label", "")),
			"sponsor_label": str(application.get("sponsor_label", "")),
			"post_deal_name": str(application.get("post_deal_name", "")),
			"post_deal_sector_id": str(application.get("post_deal_sector_id", "")),
			"post_deal_sector_name": str(application.get("post_deal_sector_name", "")),
			"funding_purpose": str(application.get("funding_purpose", "")),
			"funding_unlock_score": float(application.get("funding_unlock_score", 0.0)),
			"strategic_funding_unlock_pct": float(application.get("strategic_funding_unlock_pct", 0.0)),
			"dilution_overhang_pct": float(application.get("dilution_overhang_pct", 0.0)),
			"funding_status": str(application.get("funding_status", "")),
			"resolved_price_factor": price_factor,
			"day_index": int(application.get("day_index", day_index))
		}
	)
	_apply_player_rights_issue_entitlement(
		company_id,
		player_entitled_shares,
		exercise_price,
		exercise_cost,
		player_status
	)


func _apply_player_rights_issue_entitlement(
	company_id: String,
	entitled_shares: int,
	exercise_price: float,
	exercise_cost: float,
	status: String
) -> void:
	if company_id.is_empty() or entitled_shares <= 0:
		return
	if status == "exercised":
		var holdings: Dictionary = player_portfolio.get("holdings", {})
		var holding: Dictionary = holdings.get(company_id, {
			"company_id": company_id,
			"shares": 0,
			"average_price": 0.0
		})
		var current_shares: int = max(int(holding.get("shares", 0)), 0)
		var current_average: float = float(holding.get("average_price", 0.0))
		var new_share_total: int = current_shares + entitled_shares
		if new_share_total > 0:
			holding["shares"] = new_share_total
			holding["average_price"] = ((current_average * float(current_shares)) + exercise_cost) / float(new_share_total)
			holdings[company_id] = holding
			player_portfolio["holdings"] = holdings
		var cash_after: float = float(player_portfolio.get("cash", 0.0)) - exercise_cost
		player_portfolio["cash"] = cash_after
		_record_trade(
			company_id,
			"rights_issue_exercise",
			{
				"lots": int(floor(float(entitled_shares) / float(LOT_SIZE))),
				"shares": entitled_shares,
				"price_per_share": exercise_price,
				"gross_value": exercise_cost,
				"fee_rate": 0.0,
				"fee": 0.0
			},
			0.0,
			-exercise_cost,
			cash_after
		)
		return
	_record_trade(
		company_id,
		"rights_issue_lapsed",
		{
			"lots": int(floor(float(entitled_shares) / float(LOT_SIZE))),
			"shares": entitled_shares,
			"price_per_share": exercise_price,
			"gross_value": exercise_cost,
			"fee_rate": 0.0,
			"fee": 0.0
		},
		0.0,
		0.0,
		float(player_portfolio.get("cash", 0.0))
	)


func _apply_private_placement_application(application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not companies.has(company_id):
		return
	var new_shares: float = max(float(application.get("new_shares", 0.0)), 0.0)
	if new_shares <= 0.0:
		return
	var definition: Dictionary = get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var gross_proceeds: float = max(float(application.get("gross_proceeds", 0.0)), 0.0)
	var new_shares_outstanding: float = old_shares_outstanding + new_shares
	var theoretical_price: float = (old_price * old_shares_outstanding + gross_proceeds) / new_shares_outstanding
	var price_factor: float = clamp(theoretical_price / old_price, 0.65, 1.15)
	var new_price: float = _apply_company_price_factor(company_id, price_factor, false)
	var old_free_float_pct: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, 0.02, 0.95)
	var new_free_float_pct: float = clamp((old_shares_outstanding * old_free_float_pct) / new_shares_outstanding, 0.02, 0.95) * 100.0
	_set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		new_free_float_pct,
		{
			"type": "private_placement",
			"chain_id": str(application.get("chain_id", "")),
			"new_shares": new_shares,
			"issue_price": float(application.get("issue_price", 0.0)),
			"gross_proceeds": gross_proceeds,
			"discount_pct": float(application.get("discount_pct", 0.0)),
			"investor_label": str(application.get("investor_label", "")),
			"day_index": int(application.get("day_index", day_index))
		}
	)


func _apply_restructuring_application(application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not companies.has(company_id):
		return
	var definition: Dictionary = get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var new_shares: float = max(float(application.get("new_shares", 0.0)), 0.0)
	var new_shares_outstanding: float = max(float(application.get("new_shares_outstanding", old_shares_outstanding + new_shares)), 1.0)
	var price_adjustment_pct: float = clamp(float(application.get("price_adjustment_pct", 0.0)), -0.35, 0.35)
	var new_price: float = _apply_company_price_factor(company_id, 1.0 + price_adjustment_pct, false)
	var new_free_float_pct: float = clamp(float(application.get("new_free_float_pct", financials.get("free_float_pct", 35.0))), 0.0, 100.0)
	var player_result: Dictionary = _record_player_restructuring_note(
		company_id,
		new_price,
		old_shares_outstanding,
		new_shares_outstanding
	)
	_set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		new_free_float_pct,
		{
			"type": "restructuring",
			"chain_id": str(application.get("chain_id", "")),
			"plan_type": str(application.get("plan_type", "debt_workout")),
			"plan_label": str(application.get("plan_label", "Debt workout")),
			"debt_reduction_pct": float(application.get("debt_reduction_pct", 0.0)),
			"debt_conversion_pct": float(application.get("debt_conversion_pct", 0.0)),
			"asset_sale_value": float(application.get("asset_sale_value", 0.0)),
			"creditor_support_score": float(application.get("creditor_support_score", 0.0)),
			"credibility_score": float(application.get("credibility_score", 0.0)),
			"distress_score": float(application.get("distress_score", 0.0)),
			"stress_overhang_pct": float(application.get("stress_overhang_pct", 0.0)),
			"suspension_risk_pct": float(application.get("suspension_risk_pct", 0.0)),
			"price_adjustment_pct": price_adjustment_pct,
			"old_price": old_price,
			"new_price": new_price,
			"old_shares_outstanding": old_shares_outstanding,
			"new_shares": new_shares,
			"new_shares_outstanding": new_shares_outstanding,
			"old_free_float_pct": float(application.get("old_free_float_pct", financials.get("free_float_pct", 35.0))),
			"new_free_float_pct": new_free_float_pct,
			"player_shares": int(player_result.get("shares", 0)),
			"player_ownership_before_pct": float(player_result.get("ownership_before_pct", 0.0)),
			"player_ownership_after_pct": float(player_result.get("ownership_after_pct", 0.0)),
			"player_treatment": str(player_result.get("status", "not_held")),
			"day_index": int(application.get("day_index", day_index))
		}
	)
	_apply_company_restructuring_state(company_id, application, player_result)


func _record_player_restructuring_note(
	company_id: String,
	new_price: float,
	old_shares_outstanding: float,
	new_shares_outstanding: float
) -> Dictionary:
	var holdings: Dictionary = player_portfolio.get("holdings", {})
	if not holdings.has(company_id):
		return {"status": "not_held"}
	var holding: Dictionary = holdings.get(company_id, {}).duplicate(true)
	var shares: int = max(int(holding.get("shares", 0)), 0)
	if shares <= 0:
		return {"status": "not_held"}
	var ownership_before_pct: float = float(shares) / max(old_shares_outstanding, 1.0) * 100.0
	var ownership_after_pct: float = float(shares) / max(new_shares_outstanding, 1.0) * 100.0
	_record_trade(
		company_id,
		"restructuring",
		{
			"lots": int(floor(float(shares) / float(LOT_SIZE))),
			"shares": shares,
			"price_per_share": new_price,
			"gross_value": 0.0,
			"fee_rate": 0.0,
			"fee": 0.0,
			"ownership_before_pct": ownership_before_pct,
			"ownership_after_pct": ownership_after_pct
		},
		0.0,
		0.0,
		float(player_portfolio.get("cash", 0.0))
	)
	return {
		"status": "held_diluted",
		"shares": shares,
		"ownership_before_pct": ownership_before_pct,
		"ownership_after_pct": ownership_after_pct
	}


func _apply_company_restructuring_state(company_id: String, application: Dictionary, player_result: Dictionary) -> void:
	if company_id.is_empty() or not companies.has(company_id):
		return
	var runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var trade_date_value = application.get("trade_date", {})
	var trade_date: Dictionary = trade_date_value.duplicate(true) if typeof(trade_date_value) == TYPE_DICTIONARY else {}
	var credibility_score: float = clamp(float(application.get("credibility_score", 0.0)), 0.0, 1.0)
	var distress_score: float = clamp(float(application.get("distress_score", 0.0)), 0.0, 1.0)
	var stress_overhang_pct: float = clamp(float(application.get("stress_overhang_pct", 0.0)), 0.0, 1.0)
	var restructuring_result: Dictionary = {
		"state": "watch",
		"chain_id": str(application.get("chain_id", "")),
		"day_index": int(application.get("day_index", day_index)),
		"trade_date": trade_date,
		"plan_type": str(application.get("plan_type", "debt_workout")),
		"plan_label": str(application.get("plan_label", "Debt workout")),
		"plan_description": str(application.get("plan_description", "")),
		"debt_reduction_pct": float(application.get("debt_reduction_pct", 0.0)),
		"debt_conversion_pct": float(application.get("debt_conversion_pct", 0.0)),
		"asset_sale_value": float(application.get("asset_sale_value", 0.0)),
		"creditor_support_score": float(application.get("creditor_support_score", 0.0)),
		"credibility_score": credibility_score,
		"distress_score": distress_score,
		"stress_overhang_pct": stress_overhang_pct,
		"suspension_risk_pct": float(application.get("suspension_risk_pct", 0.0)),
		"liquidity_penalty_multiplier": float(application.get("liquidity_penalty_multiplier", 1.0)),
		"volatility_event_multiplier": float(application.get("volatility_event_multiplier", 1.45)),
		"price_adjustment_pct": float(application.get("price_adjustment_pct", 0.0)),
		"player_shares": int(player_result.get("shares", 0)),
		"player_ownership_before_pct": float(player_result.get("ownership_before_pct", 0.0)),
		"player_ownership_after_pct": float(player_result.get("ownership_after_pct", 0.0)),
		"player_treatment": str(player_result.get("status", "not_held"))
	}
	profile["restructuring_result"] = restructuring_result
	profile["liquidity_penalty_multiplier"] = min(
		float(profile.get("liquidity_penalty_multiplier", 1.0)),
		clamp(float(application.get("liquidity_penalty_multiplier", 1.0)), 0.05, 1.0)
	)
	profile["volatility_event_multiplier"] = max(
		float(profile.get("volatility_event_multiplier", 1.0)),
		clamp(float(application.get("volatility_event_multiplier", 1.45)), 1.0, 3.0)
	)
	var traits: Dictionary = profile.get("generation_traits", {}).duplicate(true)
	traits["balance_sheet_strength"] = clamp(float(traits.get("balance_sheet_strength", 0.5)) + float(application.get("debt_reduction_pct", 0.0)) * 0.22 - stress_overhang_pct * 0.08, 0.0, 1.0)
	traits["execution_consistency"] = clamp(float(traits.get("execution_consistency", 0.5)) + (credibility_score - 0.5) * 0.12, 0.0, 1.0)
	traits["story_heat"] = clamp(float(traits.get("story_heat", 0.5)) + 0.08 + stress_overhang_pct * 0.10, 0.0, 1.0)
	profile["generation_traits"] = traits
	profile["risk_score"] = clamp(int(profile.get("risk_score", 50)) + int(round(distress_score * 10.0 + stress_overhang_pct * 16.0 - credibility_score * 8.0)), 1, 99)
	runtime["company_profile"] = profile
	var depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	if not depth_context.is_empty():
		depth_context["restructuring_state"] = "watch"
		depth_context["restructuring_stress_overhang_pct"] = stress_overhang_pct
		depth_context["liquidity_penalty_multiplier"] = min(float(depth_context.get("liquidity_penalty_multiplier", 1.0)), float(profile.get("liquidity_penalty_multiplier", 1.0)))
		depth_context["volatility_event_multiplier"] = max(float(depth_context.get("volatility_event_multiplier", 1.0)), float(profile.get("volatility_event_multiplier", 1.0)))
		depth_context["ask_depth_value"] = max(float(depth_context.get("ask_depth_value", 0.0)) * (1.0 + stress_overhang_pct * 1.10), 1.0)
		depth_context["bid_depth_value"] = max(float(depth_context.get("bid_depth_value", 0.0)) * clamp(1.0 - stress_overhang_pct * 0.24, 0.58, 1.0), 1.0)
		depth_context["synthetic_daily_value"] = max(float(depth_context.get("synthetic_daily_value", 0.0)) * (1.0 + stress_overhang_pct * 0.36), 1.0)
		runtime["market_depth_context"] = depth_context
	companies[company_id] = runtime


func _apply_stock_buyback_application(application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not companies.has(company_id):
		return
	var executed_shares: float = max(float(application.get("executed_shares", application.get("shares_retired", 0.0))), 0.0)
	if executed_shares <= 0.0:
		return
	var definition: Dictionary = get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	executed_shares = min(executed_shares, max(old_shares_outstanding - 1.0, 0.0))
	if executed_shares <= 0.0:
		return
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var old_free_float_pct: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, 0.02, 0.95)
	var old_free_float_shares: float = max(old_shares_outstanding * old_free_float_pct, 1.0)
	var new_shares_outstanding: float = max(float(application.get("new_shares_outstanding", old_shares_outstanding - executed_shares)), 1.0)
	var new_free_float_pct: float = float(application.get("new_free_float_pct", 0.0))
	if new_free_float_pct <= 0.0:
		var new_free_float_shares: float = max(old_free_float_shares - executed_shares, 1.0)
		new_free_float_pct = clamp(new_free_float_shares / new_shares_outstanding, 0.02, 0.95) * 100.0
	var repurchase_pct: float = clamp(executed_shares / old_shares_outstanding, 0.0, 0.35)
	var premium_pct: float = max(float(application.get("premium_pct", 0.0)), 0.0)
	var price_support_per_pct: float = max(float(application.get("price_support_per_pct", 1.6)), 0.0)
	var maximum_price_support_pct: float = clamp(float(application.get("maximum_price_support_pct", 0.18)), 0.0, 0.5)
	var price_support_pct: float = min(repurchase_pct * price_support_per_pct + premium_pct * 0.25, maximum_price_support_pct)
	var new_price: float = _apply_company_price_factor(company_id, 1.0 + price_support_pct, false)
	_set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		new_free_float_pct,
		{
			"type": "stock_buyback",
			"chain_id": str(application.get("chain_id", "")),
			"authorized_shares": int(application.get("authorized_shares", 0)),
			"executed_shares": int(round(executed_shares)),
			"shares_retired": int(round(executed_shares)),
			"buyback_price": float(application.get("buyback_price", old_price)),
			"buyback_budget": float(application.get("buyback_budget", 0.0)),
			"premium_pct": premium_pct,
			"price_support_pct": price_support_pct,
			"old_shares_outstanding": old_shares_outstanding,
			"new_shares_outstanding": new_shares_outstanding,
			"old_free_float_pct": old_free_float_pct * 100.0,
			"new_free_float_pct": new_free_float_pct,
			"day_index": int(application.get("day_index", day_index))
		}
	)


func _apply_tender_offer_application(application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not companies.has(company_id):
		return
	var accepted_shares: float = max(float(application.get("accepted_shares", 0.0)), 0.0)
	if accepted_shares <= 0.0:
		return
	var definition: Dictionary = get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var old_free_float_pct: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, 0.02, 0.95)
	var old_free_float_shares: float = max(old_shares_outstanding * old_free_float_pct, 1.0)
	accepted_shares = min(accepted_shares, max(old_free_float_shares - 1.0, 0.0))
	if accepted_shares <= 0.0:
		return
	var new_shares_outstanding: float = max(float(application.get("new_shares_outstanding", old_shares_outstanding)), 1.0)
	var new_free_float_pct: float = float(application.get("new_free_float_pct", 0.0))
	if new_free_float_pct <= 0.0:
		var new_free_float_shares: float = max(old_free_float_shares - accepted_shares, 1.0)
		new_free_float_pct = clamp(new_free_float_shares / new_shares_outstanding, 0.02, 0.95) * 100.0
	new_free_float_pct = min(new_free_float_pct, old_free_float_pct * 100.0)
	var premium_pct: float = max(float(application.get("premium_pct", 0.0)), 0.0)
	var price_support_per_pct: float = max(float(application.get("price_support_per_pct", 1.2)), 0.0)
	var maximum_price_support_pct: float = clamp(float(application.get("maximum_price_support_pct", 0.22)), 0.0, 0.6)
	var price_support_pct: float = clamp(float(application.get("price_support_pct", 0.0)), 0.0, maximum_price_support_pct)
	if price_support_pct <= 0.0:
		price_support_pct = min((accepted_shares / old_shares_outstanding) * price_support_per_pct + premium_pct * 0.35, maximum_price_support_pct)
	var new_price: float = _apply_company_price_factor(company_id, 1.0 + price_support_pct, false)
	var player_result: Dictionary = _apply_player_tender_offer(
		company_id,
		float(application.get("acceptance_ratio", 0.0)),
		float(application.get("offer_price", old_price)),
		str(application.get("player_tender_choice", "auto_prorata"))
	)
	var aftermath_result: Dictionary = _build_tender_offer_aftermath_result(application, new_free_float_pct)
	var player_cashout_result: Dictionary = {}
	if str(aftermath_result.get("state", "none")) == "go_private_cashout":
		player_cashout_result = _apply_player_go_private_cashout(
			company_id,
			float(aftermath_result.get("final_cashout_price", application.get("offer_price", old_price)))
		)
	_set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		new_free_float_pct,
		{
			"type": "tender_offer",
			"chain_id": str(application.get("chain_id", "")),
			"offer_type": str(application.get("offer_type", "voluntary_tender_offer")),
			"offeror_label": str(application.get("offeror_label", "strategic acquirer")),
			"player_tender_choice": str(application.get("player_tender_choice", "auto_prorata")),
			"offer_shares": int(application.get("offer_shares", accepted_shares)),
			"accepted_shares": int(round(accepted_shares)),
			"offer_price": float(application.get("offer_price", old_price)),
			"premium_pct": premium_pct,
			"acceptance_ratio": float(application.get("acceptance_ratio", 0.0)),
			"tender_budget": float(application.get("tender_budget", 0.0)),
			"price_support_pct": price_support_pct,
			"old_price": old_price,
			"new_price": new_price,
			"old_shares_outstanding": old_shares_outstanding,
			"new_shares_outstanding": new_shares_outstanding,
			"old_free_float_pct": old_free_float_pct * 100.0,
			"new_free_float_pct": new_free_float_pct,
			"player_old_shares": int(player_result.get("old_shares", 0)),
			"player_tendered_shares": int(player_result.get("tendered_shares", 0)),
			"player_remaining_shares": int(player_result.get("remaining_shares", 0)),
			"player_cash_received": float(player_result.get("cash_received", 0.0)),
			"player_tender_status": str(player_result.get("status", "not_held")),
			"aftermath_state": str(aftermath_result.get("state", "none")),
			"public_float_warning_pct": float(application.get("public_float_warning_pct", 12.0)),
			"go_private_trigger_pct": float(application.get("go_private_trigger_pct", 5.0)),
			"liquidity_penalty_multiplier": float(aftermath_result.get("liquidity_penalty_multiplier", 1.0)),
			"volatility_event_multiplier": float(aftermath_result.get("volatility_event_multiplier", 1.0)),
			"final_cashout_price": float(aftermath_result.get("final_cashout_price", 0.0)),
			"player_final_cashout_shares": int(player_cashout_result.get("shares", 0)),
			"player_final_cashout_cash": float(player_cashout_result.get("cash_received", 0.0)),
			"player_final_cashout_status": str(player_cashout_result.get("status", "not_applicable")),
			"day_index": int(application.get("day_index", day_index))
		}
	)
	_apply_tender_offer_aftermath_state(company_id, application, aftermath_result)


func _apply_player_tender_offer(
	company_id: String,
	acceptance_ratio: float,
	offer_price: float,
	player_tender_choice: String = "auto_prorata"
) -> Dictionary:
	var holdings: Dictionary = player_portfolio.get("holdings", {})
	if not holdings.has(company_id):
		return {"status": "not_held"}
	var holding: Dictionary = holdings.get(company_id, {}).duplicate(true)
	var old_shares: int = max(int(holding.get("shares", 0)), 0)
	if old_shares <= 0:
		return {"status": "not_held"}
	var normalized_choice: String = player_tender_choice.strip_edges().to_lower()
	var tender_ratio: float = clamp(acceptance_ratio, 0.0, 1.0)
	if normalized_choice in ["hold", "observe"]:
		tender_ratio = 0.0
	elif normalized_choice == "tender":
		tender_ratio = clamp(acceptance_ratio, 0.0, 1.0)
	var tendered_shares: int = int(floor(float(old_shares) * tender_ratio))
	tendered_shares = clamp(tendered_shares, 0, old_shares)
	if tendered_shares <= 0:
		return {
			"status": "held_by_choice" if normalized_choice in ["hold", "observe"] else "held_no_acceptance",
			"player_tender_choice": normalized_choice,
			"old_shares": old_shares,
			"tendered_shares": 0,
			"remaining_shares": old_shares,
			"cash_received": 0.0
		}
	var remaining_shares: int = old_shares - tendered_shares
	if remaining_shares > 0:
		holding["shares"] = remaining_shares
		holdings[company_id] = holding
	else:
		holdings.erase(company_id)
	player_portfolio["holdings"] = holdings
	var cash_received: float = round(float(tendered_shares) * max(offer_price, 0.0) * 100.0) / 100.0
	var cash_after: float = float(player_portfolio.get("cash", 0.0)) + cash_received
	player_portfolio["cash"] = cash_after
	var average_price: float = float(holding.get("average_price", 0.0))
	var realized_pnl: float = cash_received - float(tendered_shares) * average_price
	player_portfolio["realized_pnl"] = float(player_portfolio.get("realized_pnl", 0.0)) + realized_pnl
	_record_trade(
		company_id,
		"tender_offer",
		{
			"lots": int(floor(float(tendered_shares) / float(LOT_SIZE))),
			"shares": tendered_shares,
			"price_per_share": offer_price,
			"gross_value": cash_received,
			"fee_rate": 0.0,
			"fee": 0.0
		},
		realized_pnl,
		cash_received,
		cash_after
	)
	return {
		"status": "accepted",
		"player_tender_choice": normalized_choice,
		"old_shares": old_shares,
		"tendered_shares": tendered_shares,
		"remaining_shares": remaining_shares,
		"cash_received": cash_received,
		"realized_pnl": realized_pnl
	}


func _build_tender_offer_aftermath_result(application: Dictionary, new_free_float_pct: float) -> Dictionary:
	var state: String = str(application.get("aftermath_state", "none"))
	if state.is_empty() or state == "none":
		var warning_pct: float = clamp(float(application.get("public_float_warning_pct", 12.0)), 0.1, 95.0)
		var go_private_pct: float = clamp(float(application.get("go_private_trigger_pct", 5.0)), 0.1, warning_pct)
		if new_free_float_pct <= go_private_pct:
			state = "go_private_cashout"
		elif new_free_float_pct <= warning_pct:
			state = "public_float_warning"
		else:
			state = "none"
	var final_cashout_price: float = float(application.get("final_cashout_price", application.get("offer_price", 0.0)))
	return {
		"state": state,
		"liquidity_penalty_multiplier": clamp(float(application.get("liquidity_penalty_multiplier", 1.0 if state == "none" else 0.35)), 0.05, 1.0),
		"volatility_event_multiplier": clamp(float(application.get("volatility_event_multiplier", 1.0 if state == "none" else 1.35)), 1.0, 3.0),
		"final_cashout_price": final_cashout_price
	}


func _apply_player_go_private_cashout(company_id: String, cashout_price: float) -> Dictionary:
	var holdings: Dictionary = player_portfolio.get("holdings", {})
	if not holdings.has(company_id):
		return {"status": "not_held"}
	var holding: Dictionary = holdings.get(company_id, {}).duplicate(true)
	var shares: int = max(int(holding.get("shares", 0)), 0)
	if shares <= 0:
		return {"status": "not_held"}
	var safe_price: float = max(cashout_price, 0.0)
	var cash_received: float = round(float(shares) * safe_price * 100.0) / 100.0
	var average_price: float = float(holding.get("average_price", 0.0))
	var realized_pnl: float = cash_received - float(shares) * average_price
	holdings.erase(company_id)
	player_portfolio["holdings"] = holdings
	var cash_after: float = float(player_portfolio.get("cash", 0.0)) + cash_received
	player_portfolio["cash"] = cash_after
	player_portfolio["realized_pnl"] = float(player_portfolio.get("realized_pnl", 0.0)) + realized_pnl
	_record_trade(
		company_id,
		"go_private_cashout",
		{
			"lots": int(floor(float(shares) / float(LOT_SIZE))),
			"shares": shares,
			"price_per_share": safe_price,
			"gross_value": cash_received,
			"fee_rate": 0.0,
			"fee": 0.0
		},
		realized_pnl,
		cash_received,
		cash_after
	)
	return {
		"status": "cashed_out",
		"shares": shares,
		"cash_received": cash_received,
		"realized_pnl": realized_pnl
	}


func _apply_tender_offer_aftermath_state(company_id: String, application: Dictionary, aftermath_result: Dictionary) -> void:
	var state: String = str(aftermath_result.get("state", "none"))
	if state == "none" or company_id.is_empty() or not companies.has(company_id):
		return
	var runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var listing_label: String = "Public float warning"
	if state == "go_private_cashout":
		listing_label = "Go-private completed"
	profile["listing_status"] = state
	profile["listing_status_label"] = listing_label
	profile["trade_disabled"] = state == "go_private_cashout"
	profile["liquidity_penalty_multiplier"] = float(aftermath_result.get("liquidity_penalty_multiplier", 0.35))
	profile["volatility_event_multiplier"] = float(aftermath_result.get("volatility_event_multiplier", 1.35))
	profile["delisting_watch"] = {
		"state": state,
		"label": listing_label,
		"chain_id": str(application.get("chain_id", "")),
		"trigger_source": "tender_offer",
		"day_index": int(application.get("day_index", day_index)),
		"old_free_float_pct": float(application.get("old_free_float_pct", 0.0)),
		"new_free_float_pct": float(application.get("new_free_float_pct", 0.0)),
		"public_float_warning_pct": float(application.get("public_float_warning_pct", 12.0)),
		"go_private_trigger_pct": float(application.get("go_private_trigger_pct", 5.0)),
		"liquidity_penalty_multiplier": float(aftermath_result.get("liquidity_penalty_multiplier", 0.35)),
		"volatility_event_multiplier": float(aftermath_result.get("volatility_event_multiplier", 1.35)),
		"final_cashout_price": float(aftermath_result.get("final_cashout_price", 0.0))
	}
	runtime["company_profile"] = profile
	var depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	if not depth_context.is_empty():
		var liquidity_penalty: float = clamp(float(aftermath_result.get("liquidity_penalty_multiplier", 0.35)), 0.05, 1.0)
		depth_context["delisting_watch_state"] = state
		depth_context["liquidity_penalty_multiplier"] = liquidity_penalty
		depth_context["synthetic_daily_value"] = max(float(depth_context.get("synthetic_daily_value", 0.0)) * liquidity_penalty, 1.0)
		depth_context["ask_depth_value"] = max(float(depth_context.get("ask_depth_value", 0.0)) * liquidity_penalty, 1.0)
		depth_context["bid_depth_value"] = max(float(depth_context.get("bid_depth_value", 0.0)) * liquidity_penalty, 1.0)
		depth_context["float_tightness"] = max(float(depth_context.get("float_tightness", 0.0)), 0.92)
		runtime["market_depth_context"] = depth_context
	companies[company_id] = runtime


func _apply_strategic_mna_application(application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not companies.has(company_id):
		return
	var cashout_price: float = max(float(application.get("cashout_price", 0.0)), 0.0)
	if cashout_price <= 0.0:
		return
	var definition: Dictionary = get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var new_shares_outstanding: float = max(float(application.get("new_shares_outstanding", old_shares_outstanding)), 1.0)
	var new_free_float_pct: float = float(application.get("new_free_float_pct", financials.get("free_float_pct", 35.0)))
	var price_factor: float = cashout_price / old_price
	var new_price: float = _apply_company_price_factor(company_id, price_factor, false)
	var player_result: Dictionary = _apply_player_acquisition_cashout(company_id, cashout_price)
	_set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		new_free_float_pct,
		{
			"type": "strategic_merger_acquisition",
			"chain_id": str(application.get("chain_id", "")),
			"deal_type": str(application.get("deal_type", "cash_acquisition")),
			"consideration_type": str(application.get("consideration_type", "cash")),
			"acquirer_company_id": str(application.get("acquirer_company_id", "")),
			"acquirer_ticker": str(application.get("acquirer_ticker", "")),
			"acquirer_name": str(application.get("acquirer_name", "")),
			"acquirer_label": str(application.get("acquirer_label", "strategic acquirer")),
			"offer_premium_pct": float(application.get("offer_premium_pct", 0.0)),
			"completion_cashout_premium_pct": float(application.get("completion_cashout_premium_pct", 0.0)),
			"total_premium_pct": float(application.get("total_premium_pct", 0.0)),
			"cashout_price": cashout_price,
			"reference_price": float(application.get("reference_price", old_price)),
			"equity_value": float(application.get("equity_value", 0.0)),
			"synergy_score": float(application.get("synergy_score", 0.0)),
			"price_support_pct": float(application.get("price_support_pct", 0.0)),
			"old_price": old_price,
			"new_price": new_price,
			"old_shares_outstanding": old_shares_outstanding,
			"new_shares_outstanding": new_shares_outstanding,
			"old_free_float_pct": float(application.get("old_free_float_pct", financials.get("free_float_pct", 35.0))),
			"new_free_float_pct": new_free_float_pct,
			"listing_status_after": str(application.get("listing_status_after", "acquired_cashout")),
			"player_old_shares": int(player_result.get("shares", 0)),
			"player_cash_received": float(player_result.get("cash_received", 0.0)),
			"player_cashout_status": str(player_result.get("status", "not_held")),
			"day_index": int(application.get("day_index", day_index))
		}
	)
	_apply_company_acquisition_state(company_id, application, player_result)


func _apply_player_acquisition_cashout(company_id: String, cashout_price: float) -> Dictionary:
	var holdings: Dictionary = player_portfolio.get("holdings", {})
	if not holdings.has(company_id):
		return {"status": "not_held"}
	var holding: Dictionary = holdings.get(company_id, {}).duplicate(true)
	var shares: int = max(int(holding.get("shares", 0)), 0)
	if shares <= 0:
		return {"status": "not_held"}
	var safe_price: float = max(cashout_price, 0.0)
	var cash_received: float = round(float(shares) * safe_price * 100.0) / 100.0
	var average_price: float = float(holding.get("average_price", 0.0))
	var realized_pnl: float = cash_received - float(shares) * average_price
	holdings.erase(company_id)
	player_portfolio["holdings"] = holdings
	var cash_after: float = float(player_portfolio.get("cash", 0.0)) + cash_received
	player_portfolio["cash"] = cash_after
	player_portfolio["realized_pnl"] = float(player_portfolio.get("realized_pnl", 0.0)) + realized_pnl
	_record_trade(
		company_id,
		"mna_cashout",
		{
			"lots": int(floor(float(shares) / float(LOT_SIZE))),
			"shares": shares,
			"price_per_share": safe_price,
			"gross_value": cash_received,
			"fee_rate": 0.0,
			"fee": 0.0
		},
		realized_pnl,
		cash_received,
		cash_after
	)
	return {
		"status": "cashed_out",
		"shares": shares,
		"cash_received": cash_received,
		"realized_pnl": realized_pnl
	}


func _apply_company_acquisition_state(company_id: String, application: Dictionary, player_result: Dictionary) -> void:
	if company_id.is_empty() or not companies.has(company_id):
		return
	var runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var trade_date_value = application.get("trade_date", {})
	var trade_date: Dictionary = trade_date_value.duplicate(true) if typeof(trade_date_value) == TYPE_DICTIONARY else {}
	var acquisition_result: Dictionary = {
		"state": "acquired_cashout",
		"label": "Acquired / cashed out",
		"chain_id": str(application.get("chain_id", "")),
		"day_index": int(application.get("day_index", day_index)),
		"trade_date": trade_date,
		"deal_type": str(application.get("deal_type", "cash_acquisition")),
		"consideration_type": str(application.get("consideration_type", "cash")),
		"acquirer_company_id": str(application.get("acquirer_company_id", "")),
		"acquirer_ticker": str(application.get("acquirer_ticker", "")),
		"acquirer_name": str(application.get("acquirer_name", "")),
		"acquirer_label": str(application.get("acquirer_label", "strategic acquirer")),
		"cashout_price": float(application.get("cashout_price", 0.0)),
		"total_premium_pct": float(application.get("total_premium_pct", 0.0)),
		"synergy_score": float(application.get("synergy_score", 0.0)),
		"player_cashout_shares": int(player_result.get("shares", 0)),
		"player_cashout_cash": float(player_result.get("cash_received", 0.0)),
		"player_cashout_status": str(player_result.get("status", "not_held"))
	}
	profile["listing_status"] = "acquired_cashout"
	profile["listing_status_label"] = "Acquired / cashed out"
	profile["trade_disabled"] = true
	profile["acquisition_result"] = acquisition_result
	if profile.has("delisting_watch"):
		profile.erase("delisting_watch")
	runtime["company_profile"] = profile
	var depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	if not depth_context.is_empty():
		depth_context["acquisition_state"] = "acquired_cashout"
		depth_context["synthetic_daily_value"] = 1.0
		depth_context["ask_depth_value"] = 1.0
		depth_context["bid_depth_value"] = 1.0
		depth_context["free_float_value"] = 1.0
		runtime["market_depth_context"] = depth_context
	companies[company_id] = runtime


func _apply_backdoor_listing_application(application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not companies.has(company_id):
		return
	var new_shares: float = max(float(application.get("new_shares", 0.0)), 0.0)
	if new_shares <= 0.0:
		return
	var definition: Dictionary = get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var new_shares_outstanding: float = max(float(application.get("new_shares_outstanding", old_shares_outstanding + new_shares)), 1.0)
	var new_free_float_pct: float = float(application.get("new_free_float_pct", financials.get("free_float_pct", 35.0)))
	var target_price: float = float(application.get("post_deal_price", 0.0))
	if target_price <= 0.0:
		target_price = old_price * (1.0 + float(application.get("price_reprice_pct", 0.0)))
	target_price = max(target_price, 1.0)
	var new_price: float = _apply_company_price_factor(company_id, target_price / old_price, false)
	var player_result: Dictionary = _record_player_backdoor_listing_note(
		company_id,
		new_price,
		old_shares_outstanding,
		new_shares_outstanding
	)
	var post_deal_identity_value = application.get("post_deal_identity", {})
	var post_deal_identity: Dictionary = post_deal_identity_value.duplicate(true) if typeof(post_deal_identity_value) == TYPE_DICTIONARY else {}
	var post_deal_tags: Array = application.get("post_deal_tags", []).duplicate()
	_set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		new_free_float_pct,
		{
			"type": "backdoor_listing",
			"chain_id": str(application.get("chain_id", "")),
			"deal_type": str(application.get("deal_type", "reverse_takeover")),
			"consideration_type": str(application.get("consideration_type", "share_issue")),
			"incoming_asset_label": str(application.get("incoming_asset_label", "private operating business")),
			"sponsor_label": str(application.get("sponsor_label", "private operating company")),
			"post_deal_name": str(application.get("post_deal_name", "")),
			"post_deal_sector_id": str(application.get("post_deal_sector_id", "")),
			"post_deal_sector_name": str(application.get("post_deal_sector_name", "")),
			"post_deal_archetype_label": str(application.get("post_deal_archetype_label", "")),
			"post_deal_description": str(application.get("post_deal_description", "")),
			"post_deal_tags": post_deal_tags.duplicate(),
			"post_deal_identity": post_deal_identity.duplicate(true),
			"target_control_pct": float(application.get("target_control_pct", 0.0)),
			"incoming_control_pct": float(application.get("incoming_control_pct", 0.0)),
			"issue_premium_pct": float(application.get("issue_premium_pct", 0.0)),
			"asset_quality_score": float(application.get("asset_quality_score", 0.0)),
			"valuation_recognition_pct": float(application.get("valuation_recognition_pct", 1.0)),
			"new_shares": int(round(new_shares)),
			"issue_price": float(application.get("issue_price", 0.0)),
			"injected_asset_value": float(application.get("injected_asset_value", 0.0)),
			"recognized_asset_value": float(application.get("recognized_asset_value", 0.0)),
			"old_market_cap": float(application.get("old_market_cap", old_price * old_shares_outstanding)),
			"post_deal_market_cap": new_price * new_shares_outstanding,
			"old_price": old_price,
			"new_price": new_price,
			"theoretical_post_price": float(application.get("theoretical_post_price", 0.0)),
			"price_reprice_pct": (new_price - old_price) / old_price,
			"silent_accumulation_pct": float(application.get("silent_accumulation_pct", 0.0)),
			"silent_accumulation_days": int(application.get("silent_accumulation_days", 0)),
			"silent_accumulation_shares": int(application.get("silent_accumulation_shares", 0)),
			"silent_accumulation_value": float(application.get("silent_accumulation_value", 0.0)),
			"accumulation_price_support_pct": float(application.get("accumulation_price_support_pct", 0.0)),
			"follow_on_rights_hint": bool(application.get("follow_on_rights_hint", false)),
			"follow_on_rights_chain_id": str(application.get("follow_on_rights_chain_id", "")),
			"follow_on_rights_probability": float(application.get("follow_on_rights_probability", 0.0)),
			"follow_on_rights_purpose": str(application.get("follow_on_rights_purpose", "")),
			"sponsor_lockup_days": int(application.get("sponsor_lockup_days", 30)),
			"sponsor_unlock_warning_lead_days": int(application.get("sponsor_unlock_warning_lead_days", 5)),
			"sponsor_locked_shares": int(application.get("sponsor_locked_shares", new_shares)),
			"sponsor_lockup_start_day_number": int(application.get("sponsor_lockup_start_day_number", application.get("day_index", day_index))),
			"sponsor_unlock_day_number": int(application.get("sponsor_unlock_day_number", int(application.get("day_index", day_index)) + int(application.get("sponsor_lockup_days", 30)))),
			"sponsor_unlock_warning_day_number": int(application.get("sponsor_unlock_warning_day_number", int(application.get("day_index", day_index)) + max(int(application.get("sponsor_lockup_days", 30)) - int(application.get("sponsor_unlock_warning_lead_days", 5)), 1))),
			"sponsor_behavior": str(application.get("sponsor_behavior", "gradual_distribution")),
			"sponsor_overhang_pressure_pct": float(application.get("sponsor_overhang_pressure_pct", 0.18)),
			"old_shares_outstanding": old_shares_outstanding,
			"new_shares_outstanding": new_shares_outstanding,
			"dilution_pct": float(application.get("dilution_pct", 0.0)),
			"old_free_float_pct": float(application.get("old_free_float_pct", financials.get("free_float_pct", 35.0))),
			"new_free_float_pct": new_free_float_pct,
			"player_shares": int(player_result.get("shares", 0)),
			"player_ownership_before_pct": float(player_result.get("ownership_before_pct", 0.0)),
			"player_ownership_after_pct": float(player_result.get("ownership_after_pct", 0.0)),
			"player_treatment": str(player_result.get("status", "not_held")),
			"day_index": int(application.get("day_index", day_index))
		}
	)
	_apply_company_backdoor_listing_state(company_id, application, player_result)


func _record_player_backdoor_listing_note(
	company_id: String,
	new_price: float,
	old_shares_outstanding: float,
	new_shares_outstanding: float
) -> Dictionary:
	var holdings: Dictionary = player_portfolio.get("holdings", {})
	if not holdings.has(company_id):
		return {"status": "not_held"}
	var holding: Dictionary = holdings.get(company_id, {}).duplicate(true)
	var shares: int = max(int(holding.get("shares", 0)), 0)
	if shares <= 0:
		return {"status": "not_held"}
	var ownership_before_pct: float = float(shares) / max(old_shares_outstanding, 1.0) * 100.0
	var ownership_after_pct: float = float(shares) / max(new_shares_outstanding, 1.0) * 100.0
	_record_trade(
		company_id,
		"backdoor_listing",
		{
			"lots": int(floor(float(shares) / float(LOT_SIZE))),
			"shares": shares,
			"price_per_share": new_price,
			"gross_value": 0.0,
			"fee_rate": 0.0,
			"fee": 0.0,
			"ownership_before_pct": ownership_before_pct,
			"ownership_after_pct": ownership_after_pct
		},
		0.0,
		0.0,
		float(player_portfolio.get("cash", 0.0))
	)
	return {
		"status": "held_diluted",
		"shares": shares,
		"ownership_before_pct": ownership_before_pct,
		"ownership_after_pct": ownership_after_pct
	}


func _apply_company_backdoor_listing_state(company_id: String, application: Dictionary, player_result: Dictionary) -> void:
	if company_id.is_empty() or not companies.has(company_id):
		return
	var runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var trade_date_value = application.get("trade_date", {})
	var trade_date: Dictionary = trade_date_value.duplicate(true) if typeof(trade_date_value) == TYPE_DICTIONARY else {}
	var volatility_multiplier: float = clamp(float(application.get("volatility_event_multiplier", 1.45)), 1.0, 3.0)
	var asset_quality_score: float = clamp(float(application.get("asset_quality_score", 0.0)), 0.0, 1.0)
	var silent_accumulation_pct: float = clamp(float(application.get("silent_accumulation_pct", 0.0)), 0.0, 1.0)
	var accumulation_support_pct: float = clamp(float(application.get("accumulation_price_support_pct", 0.0)), 0.0, 1.0)
	var post_deal_name: String = str(application.get("post_deal_name", "")).strip_edges()
	var post_deal_sector_id: String = str(application.get("post_deal_sector_id", "")).strip_edges()
	var post_deal_sector_name: String = str(application.get("post_deal_sector_name", "")).strip_edges()
	var post_deal_archetype_label: String = str(application.get("post_deal_archetype_label", "")).strip_edges()
	var post_deal_description: String = str(application.get("post_deal_description", "")).strip_edges()
	var post_deal_tags: Array = []
	for tag_value in application.get("post_deal_tags", []):
		var tag: String = str(tag_value).strip_edges()
		if tag.is_empty():
			continue
		post_deal_tags.append(tag)
	var identity_value = application.get("post_deal_identity", {})
	var post_deal_identity: Dictionary = identity_value.duplicate(true) if typeof(identity_value) == TYPE_DICTIONARY else {}
	if post_deal_identity.is_empty():
		post_deal_identity = {
			"post_deal_name": post_deal_name,
			"post_deal_sector_id": post_deal_sector_id,
			"post_deal_sector_name": post_deal_sector_name,
			"post_deal_archetype_label": post_deal_archetype_label,
			"post_deal_description": post_deal_description,
			"post_deal_tags": post_deal_tags.duplicate(),
			"ticker_unchanged": true
		}
	var sponsor_lockup_start_day_number: int = int(application.get("sponsor_lockup_start_day_number", application.get("day_index", day_index)))
	var sponsor_lockup_days: int = int(application.get("sponsor_lockup_days", 30))
	var sponsor_unlock_day_number: int = int(application.get("sponsor_unlock_day_number", sponsor_lockup_start_day_number + sponsor_lockup_days))
	var sponsor_warning_day_number: int = int(application.get("sponsor_unlock_warning_day_number", max(sponsor_unlock_day_number - int(application.get("sponsor_unlock_warning_lead_days", 5)), sponsor_lockup_start_day_number + 1)))
	var sponsor_locked_shares: int = int(application.get("sponsor_locked_shares", application.get("new_shares", 0)))
	var sponsor_lockup: Dictionary = {
		"state": "locked",
		"source_backdoor_chain_id": str(application.get("chain_id", "")),
		"sponsor_label": str(application.get("sponsor_label", "private operating company")),
		"locked_shares": sponsor_locked_shares,
		"lockup_start_day_number": sponsor_lockup_start_day_number,
		"lockup_days": sponsor_lockup_days,
		"unlock_day_number": sponsor_unlock_day_number,
		"warning_day_number": sponsor_warning_day_number,
		"warning_lead_days": int(application.get("sponsor_unlock_warning_lead_days", 5)),
		"sponsor_behavior": str(application.get("sponsor_behavior", "gradual_distribution")),
		"overhang_pressure_pct": float(application.get("sponsor_overhang_pressure_pct", 0.18)),
		"warning_announced": false,
		"unlock_processed": false,
		"extension_used": false
	}
	var milestone_plan: Array = application.get("post_deal_milestone_plan", []).duplicate(true)
	var first_milestone_delay_days: int = max(int(application.get("post_deal_first_milestone_delay_days", 6)), 1)
	var milestone_gap_days: int = max(int(application.get("post_deal_milestone_gap_days", 9)), 1)
	var backdoor_milestone_state: Dictionary = {
		"state": "active",
		"source_backdoor_chain_id": str(application.get("chain_id", "")),
		"company_id": company_id,
		"sponsor_label": str(application.get("sponsor_label", "private operating company")),
		"incoming_asset_label": str(application.get("incoming_asset_label", "private operating business")),
		"post_deal_name": post_deal_name,
		"post_deal_sector_id": post_deal_sector_id,
		"asset_quality_score": asset_quality_score,
		"capital_intensity": float(application.get("post_deal_capital_intensity", 0.75)),
		"story_heat": float(application.get("post_deal_story_heat", 0.8)),
		"milestone_plan": milestone_plan,
		"milestone_count": int(application.get("post_deal_milestone_count", milestone_plan.size())),
		"current_milestone_index": 0,
		"completed_milestones": 0,
		"delay_count": 0,
		"setback_count": 0,
		"started_day_number": int(application.get("day_index", day_index)),
		"next_milestone_day_number": int(application.get("day_index", day_index)) + first_milestone_delay_days,
		"default_gap_days": milestone_gap_days,
		"last_result_state": "",
		"last_phase_label": ""
	}
	var backdoor_result: Dictionary = {
		"state": "completed",
		"chain_id": str(application.get("chain_id", "")),
		"day_index": int(application.get("day_index", day_index)),
		"trade_date": trade_date,
		"deal_type": str(application.get("deal_type", "reverse_takeover")),
		"consideration_type": str(application.get("consideration_type", "share_issue")),
		"incoming_asset_label": str(application.get("incoming_asset_label", "private operating business")),
		"sponsor_label": str(application.get("sponsor_label", "private operating company")),
		"post_deal_name": post_deal_name,
		"post_deal_sector_id": post_deal_sector_id,
		"post_deal_sector_name": post_deal_sector_name,
		"post_deal_archetype_label": post_deal_archetype_label,
		"post_deal_description": post_deal_description,
		"post_deal_tags": post_deal_tags.duplicate(),
		"post_deal_identity": post_deal_identity.duplicate(true),
		"incoming_control_pct": float(application.get("incoming_control_pct", 0.0)),
		"new_shares": int(application.get("new_shares", 0)),
		"issue_price": float(application.get("issue_price", 0.0)),
		"injected_asset_value": float(application.get("injected_asset_value", 0.0)),
		"asset_quality_score": asset_quality_score,
		"price_reprice_pct": float(application.get("price_reprice_pct", 0.0)),
		"silent_accumulation_pct": silent_accumulation_pct,
		"silent_accumulation_days": int(application.get("silent_accumulation_days", 0)),
		"silent_accumulation_shares": int(application.get("silent_accumulation_shares", 0)),
		"silent_accumulation_value": float(application.get("silent_accumulation_value", 0.0)),
		"accumulation_price_support_pct": accumulation_support_pct,
		"follow_on_rights_hint": bool(application.get("follow_on_rights_hint", false)),
		"follow_on_rights_chain_id": str(application.get("follow_on_rights_chain_id", "")),
		"follow_on_rights_probability": float(application.get("follow_on_rights_probability", 0.0)),
		"follow_on_rights_purpose": str(application.get("follow_on_rights_purpose", "")),
		"sponsor_lockup": sponsor_lockup.duplicate(true),
		"milestone_state": backdoor_milestone_state.duplicate(true),
		"volatility_event_multiplier": volatility_multiplier,
		"player_shares": int(player_result.get("shares", 0)),
		"player_ownership_before_pct": float(player_result.get("ownership_before_pct", 0.0)),
		"player_ownership_after_pct": float(player_result.get("ownership_after_pct", 0.0)),
		"player_treatment": str(player_result.get("status", "not_held"))
	}
	if not post_deal_name.is_empty():
		profile["name"] = post_deal_name
	if not post_deal_sector_id.is_empty():
		profile["sector_id"] = post_deal_sector_id
	if not post_deal_archetype_label.is_empty():
		profile["archetype_label"] = post_deal_archetype_label
	if not post_deal_description.is_empty():
		profile["profile_description"] = post_deal_description
	if not post_deal_tags.is_empty():
		profile["profile_tags"] = post_deal_tags.duplicate()
	profile["post_deal_identity"] = post_deal_identity.duplicate(true)
	profile["backdoor_sponsor_lockup"] = sponsor_lockup.duplicate(true)
	profile["backdoor_milestone_state"] = backdoor_milestone_state.duplicate(true)
	var traits: Dictionary = profile.get("generation_traits", {}).duplicate(true)
	traits["story_heat"] = max(float(traits.get("story_heat", 0.5)), clamp(float(application.get("post_deal_story_heat", 0.8)) + asset_quality_score * 0.05, 0.0, 0.96))
	traits["liquidity_profile"] = max(float(traits.get("liquidity_profile", 0.5)), clamp(float(application.get("post_deal_liquidity_profile", 0.62)) + silent_accumulation_pct * 0.28, 0.0, 0.92))
	traits["capital_intensity"] = max(float(traits.get("capital_intensity", 0.5)), clamp(float(application.get("post_deal_capital_intensity", 0.75)), 0.0, 0.98))
	traits["backdoor_listing_heat"] = clamp(0.62 + asset_quality_score * 0.22 + silent_accumulation_pct * 0.44, 0.0, 1.0)
	profile["generation_traits"] = traits
	profile["quality_score"] = max(int(profile.get("quality_score", 0)), int(round(48.0 + asset_quality_score * 35.0)))
	profile["growth_score"] = max(int(profile.get("growth_score", 0)), int(round(56.0 + asset_quality_score * 34.0)))
	profile["risk_score"] = max(int(profile.get("risk_score", 0)), int(round(54.0 + (1.0 - asset_quality_score) * 24.0 + silent_accumulation_pct * 20.0)))
	profile["base_volatility"] = max(
		float(profile.get("base_volatility", 0.025)),
		clamp(0.028 + (volatility_multiplier - 1.0) * 0.018 + silent_accumulation_pct * 0.06, 0.025, 0.068)
	)
	var financials: Dictionary = profile.get("financials", {}).duplicate(true)
	if not financials.is_empty():
		var post_market_cap: float = max(float(application.get("post_deal_market_cap", financials.get("market_cap", 0.0))), 0.0)
		var current_avg_daily_value: float = max(float(financials.get("avg_daily_value", 0.0)), 0.0)
		var story_adv_floor: float = post_market_cap * clamp(0.00042 + silent_accumulation_pct * 0.0022 + asset_quality_score * 0.00036, 0.00036, 0.0026)
		financials["avg_daily_value"] = max(current_avg_daily_value, story_adv_floor)
		financials["revenue_growth_yoy"] = max(float(financials.get("revenue_growth_yoy", 0.0)), 8.0 + asset_quality_score * 28.0)
		financials["earnings_growth_yoy"] = max(float(financials.get("earnings_growth_yoy", -100.0)), -4.0 + asset_quality_score * 24.0)
		profile["financials"] = financials
	profile["backdoor_listing_result"] = backdoor_result
	profile["volatility_event_multiplier"] = max(float(profile.get("volatility_event_multiplier", 1.0)), volatility_multiplier)
	runtime["company_profile"] = profile
	var depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	if not depth_context.is_empty():
		depth_context["backdoor_listing_state"] = "completed"
		depth_context["volatility_event_multiplier"] = volatility_multiplier
		depth_context["asset_injection_state"] = "completed"
		depth_context["post_deal_sector_id"] = post_deal_sector_id
		depth_context["sponsor_lockup_state"] = "locked"
		depth_context["sponsor_locked_shares"] = sponsor_locked_shares
		depth_context["sponsor_unlock_day_number"] = sponsor_unlock_day_number
		depth_context["backdoor_milestone_state"] = "active"
		depth_context["backdoor_next_milestone_day_number"] = int(backdoor_milestone_state.get("next_milestone_day_number", 0))
		depth_context["silent_accumulation_pct"] = silent_accumulation_pct
		depth_context["silent_accumulation_shares"] = int(application.get("silent_accumulation_shares", 0))
		depth_context["accumulation_price_support_pct"] = accumulation_support_pct
		depth_context["float_tightness"] = max(float(depth_context.get("float_tightness", 0.0)), 0.72 + silent_accumulation_pct * 0.32)
		var liquidity_lift: float = clamp(1.0 + silent_accumulation_pct * 3.2 + asset_quality_score * 0.38 + accumulation_support_pct * 1.6, 1.0, 2.35)
		for depth_value_key in ["synthetic_daily_value", "ask_depth_value", "bid_depth_value"]:
			if depth_context.has(depth_value_key):
				depth_context[depth_value_key] = max(float(depth_context.get(depth_value_key, 0.0)) * liquidity_lift, 1.0)
		runtime["market_depth_context"] = depth_context
	companies[company_id] = runtime


func _apply_backdoor_lockup_update_application(application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not companies.has(company_id):
		return
	var runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var lockup: Dictionary = profile.get("backdoor_sponsor_lockup", {}).duplicate(true)
	if lockup.is_empty():
		return
	var action_type: String = str(application.get("action_type", "warning"))
	lockup["last_update_day_number"] = int(application.get("day_index", day_index))
	lockup["last_action_type"] = action_type
	lockup["active_overhang_pressure_pct"] = float(application.get("sell_pressure_pct", lockup.get("overhang_pressure_pct", 0.0)))
	lockup["impact_until_day_number"] = int(application.get("impact_until_day_number", application.get("day_index", day_index)))
	if action_type == "warning":
		lockup["state"] = "warning"
		lockup["warning_announced"] = true
	elif action_type == "extension":
		lockup["state"] = "extended"
		lockup["warning_announced"] = false
		lockup["extension_used"] = true
		lockup["extension_days"] = int(application.get("extension_days", 0))
		lockup["unlock_day_number"] = int(application.get("unlock_day_number", lockup.get("unlock_day_number", 0)))
		lockup["warning_day_number"] = max(int(lockup.get("unlock_day_number", 0)) - int(lockup.get("warning_lead_days", 5)), int(application.get("day_index", day_index)) + 1)
	elif action_type == "unlock":
		lockup["unlock_processed"] = true
		lockup["state"] = "unlocked_%s" % str(application.get("sponsor_behavior", "gradual_distribution"))
		lockup["unlock_day_number"] = int(application.get("unlock_day_number", lockup.get("unlock_day_number", 0)))
	profile["backdoor_sponsor_lockup"] = lockup.duplicate(true)
	var backdoor_result: Dictionary = profile.get("backdoor_listing_result", {}).duplicate(true)
	if not backdoor_result.is_empty():
		backdoor_result["sponsor_lockup"] = lockup.duplicate(true)
		profile["backdoor_listing_result"] = backdoor_result
	var sell_pressure_pct: float = clamp(float(application.get("sell_pressure_pct", 0.0)), 0.0, 1.0)
	if action_type == "extension":
		profile["volatility_event_multiplier"] = max(float(profile.get("volatility_event_multiplier", 1.0)), 1.16)
	else:
		profile["volatility_event_multiplier"] = max(float(profile.get("volatility_event_multiplier", 1.0)), clamp(1.18 + sell_pressure_pct * 1.45, 1.0, 2.4))
	runtime["company_profile"] = profile
	var depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	if not depth_context.is_empty():
		depth_context["sponsor_lockup_state"] = str(lockup.get("state", ""))
		depth_context["sponsor_locked_shares"] = int(application.get("locked_shares", lockup.get("locked_shares", 0)))
		depth_context["sponsor_locked_shares_pct"] = float(application.get("locked_shares_pct", 0.0))
		depth_context["sponsor_unlock_day_number"] = int(lockup.get("unlock_day_number", 0))
		depth_context["sponsor_overhang_pressure_pct"] = sell_pressure_pct
		depth_context["sponsor_overhang_impact_until_day_number"] = int(lockup.get("impact_until_day_number", day_index))
		if action_type == "extension":
			depth_context["ask_depth_value"] = max(float(depth_context.get("ask_depth_value", 0.0)) * 1.04, 1.0)
			depth_context["bid_depth_value"] = max(float(depth_context.get("bid_depth_value", 0.0)) * 1.06, 1.0)
		else:
			depth_context["ask_depth_value"] = max(float(depth_context.get("ask_depth_value", 0.0)) * (1.0 + sell_pressure_pct * 1.65), 1.0)
			depth_context["bid_depth_value"] = max(float(depth_context.get("bid_depth_value", 0.0)) * clamp(1.0 - sell_pressure_pct * 0.38, 0.52, 1.0), 1.0)
			depth_context["synthetic_daily_value"] = max(float(depth_context.get("synthetic_daily_value", 0.0)) * (1.0 + sell_pressure_pct * 0.65), 1.0)
		runtime["market_depth_context"] = depth_context
	companies[company_id] = runtime


func _apply_backdoor_milestone_update_application(application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not companies.has(company_id):
		return
	var runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var milestone_state: Dictionary = profile.get("backdoor_milestone_state", {}).duplicate(true)
	if milestone_state.is_empty():
		return
	var result_state: String = str(application.get("result_state", "delayed"))
	var price_adjustment_pct: float = clamp(float(application.get("price_adjustment_pct", 0.0)), -0.30, 0.30)
	if absf(price_adjustment_pct) > 0.0001:
		_apply_company_price_factor(company_id, 1.0 + price_adjustment_pct, false)
		runtime = companies.get(company_id, {}).duplicate(true)
		profile = runtime.get("company_profile", {}).duplicate(true)
		milestone_state = profile.get("backdoor_milestone_state", {}).duplicate(true)
	milestone_state["last_update_day_number"] = int(application.get("day_index", day_index))
	milestone_state["last_result_state"] = result_state
	milestone_state["last_phase_id"] = str(application.get("phase_id", ""))
	milestone_state["last_phase_label"] = str(application.get("phase_label", ""))
	milestone_state["last_price_adjustment_pct"] = price_adjustment_pct
	milestone_state["last_volatility_event_multiplier"] = float(application.get("volatility_event_multiplier", 1.0))
	milestone_state["completed_milestones"] = int(application.get("completed_milestones", milestone_state.get("completed_milestones", 0)))
	milestone_state["delay_count"] = int(application.get("delay_count", milestone_state.get("delay_count", 0)))
	milestone_state["setback_count"] = int(application.get("setback_count", milestone_state.get("setback_count", 0)))
	milestone_state["current_milestone_index"] = int(application.get("next_milestone_index", milestone_state.get("current_milestone_index", 0)))
	milestone_state["next_milestone_day_number"] = int(application.get("next_milestone_day_number", 0))
	milestone_state["impact_until_day_number"] = int(application.get("impact_until_day_number", application.get("day_index", day_index)))
	if bool(application.get("plan_complete", false)):
		milestone_state["state"] = "completed" if int(milestone_state.get("setback_count", 0)) <= 0 else "impaired"
	elif result_state == "delayed":
		milestone_state["state"] = "delayed"
	elif result_state == "setback":
		milestone_state["state"] = "active_with_setback"
	else:
		milestone_state["state"] = "active"
	profile["backdoor_milestone_state"] = milestone_state.duplicate(true)
	var backdoor_result: Dictionary = profile.get("backdoor_listing_result", {}).duplicate(true)
	if not backdoor_result.is_empty():
		backdoor_result["milestone_state"] = milestone_state.duplicate(true)
		profile["backdoor_listing_result"] = backdoor_result
	profile["volatility_event_multiplier"] = max(
		float(profile.get("volatility_event_multiplier", 1.0)),
		clamp(float(application.get("volatility_event_multiplier", 1.0)), 1.0, 3.0)
	)
	var traits: Dictionary = profile.get("generation_traits", {}).duplicate(true)
	if result_state == "delivered":
		traits["story_heat"] = clamp(float(traits.get("story_heat", 0.5)) + 0.06, 0.0, 1.0)
		traits["execution_consistency"] = clamp(float(traits.get("execution_consistency", 0.5)) + 0.04, 0.0, 1.0)
		traits["liquidity_profile"] = clamp(float(traits.get("liquidity_profile", 0.5)) + 0.03, 0.0, 1.0)
	elif result_state == "setback":
		traits["execution_consistency"] = clamp(float(traits.get("execution_consistency", 0.5)) - 0.07, 0.0, 1.0)
		traits["story_heat"] = clamp(float(traits.get("story_heat", 0.5)) + 0.04, 0.0, 1.0)
	else:
		traits["execution_consistency"] = clamp(float(traits.get("execution_consistency", 0.5)) - 0.03, 0.0, 1.0)
	profile["generation_traits"] = traits
	var adjustments: Array = profile.get("corporate_action_adjustments", []).duplicate(true)
	adjustments.append({
		"type": "backdoor_milestone",
		"chain_id": str(application.get("chain_id", "")),
		"phase_id": str(application.get("phase_id", "")),
		"phase_label": str(application.get("phase_label", "")),
		"result_state": result_state,
		"price_adjustment_pct": price_adjustment_pct,
		"completed_milestones": int(milestone_state.get("completed_milestones", 0)),
		"setback_count": int(milestone_state.get("setback_count", 0)),
		"delay_count": int(milestone_state.get("delay_count", 0)),
		"day_index": int(application.get("day_index", day_index))
	})
	if adjustments.size() > 24:
		adjustments = adjustments.slice(adjustments.size() - 24, adjustments.size())
	profile["corporate_action_adjustments"] = adjustments
	runtime["company_profile"] = profile
	var depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	if not depth_context.is_empty():
		depth_context["backdoor_milestone_state"] = str(milestone_state.get("state", ""))
		depth_context["backdoor_last_milestone_result"] = result_state
		depth_context["backdoor_last_milestone_label"] = str(application.get("phase_label", ""))
		depth_context["backdoor_next_milestone_day_number"] = int(milestone_state.get("next_milestone_day_number", 0))
		depth_context["volatility_event_multiplier"] = max(float(depth_context.get("volatility_event_multiplier", 1.0)), float(profile.get("volatility_event_multiplier", 1.0)))
		if result_state == "delivered":
			depth_context["bid_depth_value"] = max(float(depth_context.get("bid_depth_value", 0.0)) * 1.08, 1.0)
			depth_context["ask_depth_value"] = max(float(depth_context.get("ask_depth_value", 0.0)) * 0.96, 1.0)
		else:
			var pressure: float = absf(price_adjustment_pct)
			depth_context["ask_depth_value"] = max(float(depth_context.get("ask_depth_value", 0.0)) * (1.0 + pressure * 4.2), 1.0)
			depth_context["bid_depth_value"] = max(float(depth_context.get("bid_depth_value", 0.0)) * clamp(1.0 - pressure * 2.1, 0.60, 1.0), 1.0)
			depth_context["synthetic_daily_value"] = max(float(depth_context.get("synthetic_daily_value", 0.0)) * (1.0 + pressure * 1.6), 1.0)
		runtime["market_depth_context"] = depth_context
	companies[company_id] = runtime


func _apply_ceo_change_application(application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not companies.has(company_id):
		return
	var new_ceo_name: String = str(application.get("new_ceo_name", ""))
	if new_ceo_name.is_empty():
		return
	var definition: Dictionary = get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var management_roster: Array = profile.get("management_roster", definition.get("management_roster", [])).duplicate(true)
	var previous_ceo_name: String = str(application.get("current_ceo_name", ""))
	var replaced_ceo: bool = false
	for management_index in range(management_roster.size()):
		if typeof(management_roster[management_index]) != TYPE_DICTIONARY:
			continue
		var management: Dictionary = management_roster[management_index].duplicate(true)
		if str(management.get("affiliation_role", "")) != "ceo":
			continue
		if previous_ceo_name.is_empty():
			previous_ceo_name = str(management.get("display_name", ""))
		management["previous_display_name"] = str(management.get("display_name", ""))
		management["display_name"] = new_ceo_name
		management["contact_id"] = "insider_%s_ceo_%d" % [company_id, int(application.get("day_index", day_index))]
		management["id"] = str(management.get("contact_id", ""))
		management["role"] = "CEO"
		management["role_label"] = "CEO"
		management["tone"] = "constructive"
		management["intro"] = "%s serves as CEO at %s after a shareholder-approved leadership reset focused on %s." % [
			new_ceo_name,
			str(definition.get("name", company_id.to_upper())),
			str(application.get("mandate", "execution reset"))
		]
		management_roster[management_index] = management
		replaced_ceo = true
		break
	if not replaced_ceo:
		management_roster.insert(0, {
			"contact_id": "insider_%s_ceo_%d" % [company_id, int(application.get("day_index", day_index))],
			"id": "insider_%s_ceo_%d" % [company_id, int(application.get("day_index", day_index))],
			"display_name": new_ceo_name,
			"affiliation_type": "insider",
			"affiliation_role": "ceo",
			"company_id": company_id,
			"affiliated_company_id": company_id,
			"sector_id": str(definition.get("sector_id", "")),
			"role": "CEO",
			"role_label": "CEO",
			"recognition_required": 50,
			"base_relationship": 18,
			"reliability": 0.68,
			"tone": "constructive",
			"intro": "%s serves as CEO at %s after a shareholder-approved leadership reset." % [
				new_ceo_name,
				str(definition.get("name", company_id.to_upper()))
			]
		})
	profile["management_roster"] = management_roster
	var price_reaction_pct: float = clamp(float(application.get("price_reaction_pct", 0.0)), -0.5, 0.5)
	var new_price: float = _apply_company_price_factor(company_id, 1.0 + price_reaction_pct, false)
	runtime = companies.get(company_id, {}).duplicate(true)
	profile = runtime.get("company_profile", {}).duplicate(true)
	profile["management_roster"] = management_roster
	var traits: Dictionary = profile.get("generation_traits", {}).duplicate(true)
	traits["execution_consistency"] = clamp(float(traits.get("execution_consistency", 0.5)) + float(application.get("execution_consistency_delta", 0.0)), 0.0, 1.0)
	traits["story_heat"] = clamp(float(traits.get("story_heat", 0.5)) + absf(price_reaction_pct) * 0.8 + 0.04, 0.0, 1.0)
	profile["generation_traits"] = traits
	profile["growth_score"] = clamp(int(profile.get("growth_score", definition.get("growth_score", 50))) + int(round(float(application.get("growth_score_delta", 0.0)) * 100.0)), 1, 99)
	profile["risk_score"] = clamp(int(profile.get("risk_score", definition.get("risk_score", 50))) + int(round(float(application.get("risk_score_delta", 0.0)) * 100.0)), 1, 99)
	profile["quality_score"] = clamp(int(profile.get("quality_score", definition.get("quality_score", 50))) + int(round(float(application.get("governance_confidence_delta", 0.0)) * 60.0)), 1, 99)
	profile["volatility_event_multiplier"] = max(
		float(profile.get("volatility_event_multiplier", 1.0)),
		clamp(float(application.get("volatility_event_multiplier", 1.18)), 1.0, 3.0)
	)
	var ceo_result: Dictionary = {
		"type": "ceo_change",
		"chain_id": str(application.get("chain_id", "")),
		"meeting_id": str(application.get("meeting_id", "")),
		"previous_ceo_name": previous_ceo_name,
		"new_ceo_name": new_ceo_name,
		"incoming_profile_label": str(application.get("incoming_profile_label", "")),
		"mandate": str(application.get("mandate", "")),
		"governance_confidence_delta": float(application.get("governance_confidence_delta", 0.0)),
		"price_reaction_pct": price_reaction_pct,
		"new_price": new_price,
		"day_index": int(application.get("day_index", day_index))
	}
	profile["ceo_change_result"] = ceo_result
	var adjustments: Array = profile.get("corporate_action_adjustments", []).duplicate(true)
	adjustments.append(ceo_result.duplicate(true))
	if adjustments.size() > 24:
		adjustments = adjustments.slice(adjustments.size() - 24, adjustments.size())
	profile["corporate_action_adjustments"] = adjustments
	runtime["company_profile"] = profile
	var depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	if not depth_context.is_empty():
		depth_context["ceo_change_state"] = "completed"
		depth_context["ceo_change_price_reaction_pct"] = price_reaction_pct
		depth_context["volatility_event_multiplier"] = max(float(depth_context.get("volatility_event_multiplier", 1.0)), float(profile.get("volatility_event_multiplier", 1.0)))
		depth_context["bid_depth_value"] = max(float(depth_context.get("bid_depth_value", 0.0)) * (1.0 + max(price_reaction_pct, 0.0) * 1.4), 1.0)
		depth_context["ask_depth_value"] = max(float(depth_context.get("ask_depth_value", 0.0)) * (1.0 + max(-price_reaction_pct, 0.0) * 1.6), 1.0)
		runtime["market_depth_context"] = depth_context
	companies[company_id] = runtime
	var held_shares: int = int(get_holding(company_id).get("shares", 0))
	if held_shares > 0:
		_record_trade(
			company_id,
			"ceo_change",
			{
				"lots": int(floor(float(held_shares) / float(LOT_SIZE))),
				"shares": held_shares,
				"price_per_share": new_price,
				"gross_value": 0.0,
				"fee_rate": 0.0,
				"fee": 0.0
			},
			0.0,
			0.0,
			float(player_portfolio.get("cash", 0.0))
		)


func _apply_stock_split_application(application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not companies.has(company_id):
		return
	var share_multiplier: float = max(float(application.get("share_multiplier", 0.0)), 0.0001)
	var price_factor: float = float(application.get("price_factor", 1.0 / share_multiplier))
	if price_factor <= 0.0:
		price_factor = 1.0 / share_multiplier
	var definition: Dictionary = get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var new_shares_outstanding: float = max(float(application.get("new_shares_outstanding", round(old_shares_outstanding * share_multiplier))), 1.0)
	var new_price: float = _apply_company_price_factor(company_id, price_factor, true)
	var sentiment_price_adjustment_pct: float = clamp(float(application.get("sentiment_price_adjustment_pct", 0.0)), -0.25, 0.25)
	if absf(sentiment_price_adjustment_pct) > 0.0001:
		new_price = _apply_company_price_factor(company_id, 1.0 + sentiment_price_adjustment_pct, false)
	var split_type: String = str(application.get("split_type", "split"))
	var player_result: Dictionary = _apply_player_stock_split(company_id, share_multiplier, new_price, split_type)
	_set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		float(application.get("new_free_float_pct", financials.get("free_float_pct", 35.0))),
		{
			"type": "stock_split",
			"chain_id": str(application.get("chain_id", "")),
			"split_type": split_type,
			"ratio_numerator": int(application.get("ratio_numerator", 1)),
			"ratio_denominator": int(application.get("ratio_denominator", 1)),
			"share_multiplier": share_multiplier,
			"price_factor": price_factor,
			"sentiment_price_adjustment_pct": sentiment_price_adjustment_pct,
			"old_price": old_price,
			"new_price": new_price,
			"theoretical_ex_split_price": float(application.get("theoretical_ex_split_price", 0.0)),
			"old_shares_outstanding": old_shares_outstanding,
			"new_shares_outstanding": new_shares_outstanding,
			"player_old_shares": int(player_result.get("old_shares", 0)),
			"player_new_shares": int(player_result.get("new_shares", 0)),
			"player_cash_in_lieu": float(player_result.get("cash_in_lieu", 0.0)),
			"day_index": int(application.get("day_index", day_index))
		}
	)


func _apply_player_stock_split(company_id: String, share_multiplier: float, new_price: float, split_type: String) -> Dictionary:
	var holdings: Dictionary = player_portfolio.get("holdings", {})
	if not holdings.has(company_id):
		return {}
	var holding: Dictionary = holdings.get(company_id, {}).duplicate(true)
	var old_shares: int = max(int(holding.get("shares", 0)), 0)
	if old_shares <= 0:
		return {}
	var raw_new_shares: float = float(old_shares) * max(share_multiplier, 0.0001)
	var new_shares: int = int(floor(raw_new_shares + 0.0001))
	if split_type == "split":
		new_shares = max(int(round(raw_new_shares)), old_shares)
	var fractional_shares: float = max(raw_new_shares - float(new_shares), 0.0)
	var cash_in_lieu: float = round(fractional_shares * max(new_price, 0.0) * 100.0) / 100.0
	var old_average: float = float(holding.get("average_price", 0.0))
	if new_shares > 0:
		holding["shares"] = new_shares
		holding["average_price"] = old_average / max(share_multiplier, 0.0001)
		holdings[company_id] = holding
	else:
		holdings.erase(company_id)
	player_portfolio["holdings"] = holdings
	if cash_in_lieu > 0.0:
		player_portfolio["cash"] = float(player_portfolio.get("cash", 0.0)) + cash_in_lieu
	var history_side: String = "reverse_stock_split" if split_type == "reverse_split" else "stock_split"
	_record_trade(
		company_id,
		history_side,
		{
			"lots": int(floor(float(new_shares) / float(LOT_SIZE))),
			"shares": new_shares,
			"price_per_share": new_price,
			"gross_value": cash_in_lieu,
			"fee_rate": 0.0,
			"fee": 0.0
		},
		0.0,
		cash_in_lieu,
		float(player_portfolio.get("cash", 0.0))
	)
	return {
		"old_shares": old_shares,
		"new_shares": new_shares,
		"fractional_shares": fractional_shares,
		"cash_in_lieu": cash_in_lieu
	}


func _apply_stock_dividend_distributions(distributions: Array) -> void:
	if distributions.is_empty():
		return
	for distribution_value in distributions:
		if typeof(distribution_value) != TYPE_DICTIONARY:
			continue
		var distribution: Dictionary = distribution_value
		var company_id: String = str(distribution.get("company_id", ""))
		var ratio: float = max(float(distribution.get("stock_dividend_ratio", 0.0)), 0.0)
		if company_id.is_empty() or not companies.has(company_id) or ratio <= 0.0:
			continue
		var bonus_shares: int = max(int(distribution.get("bonus_shares", 0)), 0)
		if bonus_shares > 0:
			var holdings: Dictionary = player_portfolio.get("holdings", {})
			var holding: Dictionary = holdings.get(company_id, {
				"company_id": company_id,
				"shares": 0,
				"average_price": 0.0
			})
			var current_shares: int = max(int(holding.get("shares", 0)), 0)
			var current_average: float = float(holding.get("average_price", 0.0))
			var new_share_total: int = current_shares + bonus_shares
			if new_share_total > 0:
				holding["shares"] = new_share_total
				holding["average_price"] = (current_average * float(current_shares)) / float(new_share_total)
				holdings[company_id] = holding
				player_portfolio["holdings"] = holdings
				_record_trade(
					company_id,
					"stock_dividend",
					{
						"lots": int(floor(float(bonus_shares) / float(LOT_SIZE))),
						"shares": bonus_shares,
						"price_per_share": float(companies.get(company_id, {}).get("current_price", 0.0)),
						"gross_value": 0.0,
						"fee_rate": 0.0,
						"fee": 0.0
					},
					0.0,
					0.0,
					float(player_portfolio.get("cash", 0.0))
				)
		var definition: Dictionary = get_effective_company_definition(company_id, false, false)
		var financials: Dictionary = definition.get("financials", {})
		var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
		var new_shares_outstanding: float = old_shares_outstanding * (1.0 + ratio)
		var new_price: float = _apply_company_price_factor(company_id, 1.0 / (1.0 + ratio), true)
		_set_company_share_structure(
			company_id,
			new_shares_outstanding,
			new_price * new_shares_outstanding,
			float(financials.get("free_float_pct", 35.0)),
			{
				"type": "stock_dividend",
				"dividend_id": str(distribution.get("dividend_id", "")),
				"stock_dividend_ratio": ratio,
				"bonus_shares": bonus_shares,
				"day_index": int(distribution.get("day_index", day_index))
			}
		)


func _apply_company_price_factor(company_id: String, price_factor: float, adjust_history: bool) -> float:
	if company_id.is_empty() or not companies.has(company_id):
		return 0.0
	var runtime: Dictionary = companies[company_id].duplicate(true)
	var safe_factor: float = clamp(price_factor, 0.05, 20.0)
	var current_price: float = IDX_PRICE_RULES.normalize_last_price(float(runtime.get("current_price", 0.0)) * safe_factor)
	runtime["current_price"] = current_price
	runtime["previous_close"] = IDX_PRICE_RULES.normalize_last_price(float(runtime.get("previous_close", current_price)) * safe_factor) if adjust_history else float(runtime.get("previous_close", current_price))
	var price_history: Array = runtime.get("price_history", []).duplicate()
	if adjust_history:
		for price_index in range(price_history.size()):
			price_history[price_index] = IDX_PRICE_RULES.normalize_last_price(float(price_history[price_index]) * safe_factor)
	elif not price_history.is_empty():
		price_history[price_history.size() - 1] = current_price
	runtime["price_history"] = price_history
	var price_bars: Array = runtime.get("price_bars", []).duplicate(true)
	if adjust_history:
		for bar_index in range(price_bars.size()):
			price_bars[bar_index] = _scale_price_bar(price_bars[bar_index], safe_factor)
	elif not price_bars.is_empty():
		price_bars[price_bars.size() - 1] = _scale_price_bar(price_bars[price_bars.size() - 1], safe_factor)
	runtime["price_bars"] = price_bars
	companies[company_id] = runtime
	return current_price


func _scale_price_bar(bar_value: Variant, price_factor: float) -> Variant:
	if typeof(bar_value) != TYPE_DICTIONARY:
		return bar_value
	var bar: Dictionary = bar_value.duplicate(true)
	for price_key in ["open", "high", "low", "close"]:
		if bar.has(price_key):
			bar[price_key] = IDX_PRICE_RULES.normalize_last_price(float(bar.get(price_key, 0.0)) * price_factor)
	return bar


func _set_company_share_structure(
	company_id: String,
	shares_outstanding: float,
	market_cap: float,
	free_float_pct: float,
	adjustment: Dictionary
) -> void:
	if company_id.is_empty() or not companies.has(company_id):
		return
	var runtime: Dictionary = companies[company_id].duplicate(true)
	var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var financials: Dictionary = get_effective_company_definition(company_id, false, false).get("financials", {}).duplicate(true)
	if not profile.get("financials", {}).is_empty():
		financials = profile.get("financials", {}).duplicate(true)
	financials["shares_outstanding"] = max(shares_outstanding, 1.0)
	financials["market_cap"] = max(market_cap, 0.0)
	financials["free_float_pct"] = clamp(free_float_pct, 0.0, 100.0)
	profile["shares_outstanding"] = max(shares_outstanding, 1.0)
	profile["financials"] = financials
	var adjustments: Array = profile.get("corporate_action_adjustments", []).duplicate(true)
	adjustments.append(adjustment.duplicate(true))
	if adjustments.size() > 24:
		adjustments = adjustments.slice(adjustments.size() - 24, adjustments.size())
	profile["corporate_action_adjustments"] = adjustments
	runtime["company_profile"] = profile
	var depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	if not depth_context.is_empty():
		depth_context["shares_outstanding"] = max(shares_outstanding, 1.0)
		var free_float_ratio: float = clamp(free_float_pct / 100.0, 0.0, 1.0)
		depth_context["free_float_ratio"] = free_float_ratio
		depth_context["free_float_shares"] = max(shares_outstanding * free_float_ratio, 1.0)
		depth_context["free_float_value"] = max(depth_context["free_float_shares"] * float(runtime.get("current_price", 0.0)), 1.0)
		runtime["market_depth_context"] = depth_context
	companies[company_id] = runtime


func _record_player_market_flow(company_id: String, side: String, estimate: Dictionary) -> void:
	if company_id.is_empty():
		return
	var definition: Dictionary = get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = get_company(company_id)
	var current_price: float = max(float(runtime.get("current_price", definition.get("base_price", estimate.get("price_per_share", 1.0)))), 1.0)
	var financials: Dictionary = definition.get("financials", {})
	var market_cap: float = max(float(financials.get("market_cap", current_price * 1000000000.0)), current_price * 1000000.0)
	var shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", market_cap / current_price))), 1.0)
	var free_float_ratio: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, 0.07, 0.85)
	var free_float_shares: float = max(shares_outstanding * free_float_ratio, 1.0)
	var trade_shares: float = max(float(estimate.get("shares", 0)), 0.0)
	var gross_value: float = float(estimate.get("gross_value", 0.0))
	var holdings: Dictionary = player_portfolio.get("holdings", {})
	var holding: Dictionary = holdings.get(company_id, {})
	var player_shares_after: float = float(holding.get("shares", 0))
	var flow_entries: Array = player_market_flows.get(company_id, [])
	flow_entries.append({
		"day_index": day_index,
		"trade_date": current_trade_date.duplicate(true),
		"company_id": company_id,
		"side": side,
		"broker_code": PLAYER_BROKER_CODE,
		"broker_name": PLAYER_BROKER_NAME,
		"shares": int(estimate.get("shares", 0)),
		"lots": int(estimate.get("lots", 0)),
		"price_per_share": float(estimate.get("price_per_share", 0.0)),
		"gross_value": gross_value,
		"market_cap": market_cap,
		"shares_outstanding": shares_outstanding,
		"free_float_ratio": free_float_ratio,
		"free_float_shares": free_float_shares,
		"trade_ownership_pct": trade_shares / shares_outstanding,
		"trade_free_float_pct": trade_shares / free_float_shares,
		"trade_market_cap_pct": gross_value / max(market_cap, 1.0),
		"player_ownership_pct_after": player_shares_after / shares_outstanding,
		"player_free_float_pct_after": player_shares_after / free_float_shares,
		"impact_intent": "accumulate" if side == "buy" else "distribute"
	})
	if flow_entries.size() > MAX_PLAYER_MARKET_FLOW_ENTRIES:
		flow_entries = flow_entries.slice(flow_entries.size() - MAX_PLAYER_MARKET_FLOW_ENTRIES, flow_entries.size())
	player_market_flows[company_id] = flow_entries
	_prune_player_market_flows(day_index)


func _prune_player_market_flows(reference_day_index: int) -> void:
	var company_ids: Array = player_market_flows.keys()
	for company_id_value in company_ids:
		var company_id: String = str(company_id_value)
		var kept_entries: Array = []
		for flow_value in player_market_flows.get(company_id, []):
			var flow: Dictionary = flow_value
			var age: int = reference_day_index - int(flow.get("day_index", reference_day_index))
			if age <= PLAYER_MARKET_FLOW_DECAY_DAYS:
				kept_entries.append(flow.duplicate(true))
		if kept_entries.is_empty():
			player_market_flows.erase(company_id)
		else:
			player_market_flows[company_id] = kept_entries


func _player_flow_decay_weight(age: int) -> float:
	match age:
		1:
			return 1.0
		2:
			return 0.55
		3:
			return 0.25
	return 0.0


func _build_quarterly_report_calendar() -> Dictionary:
	var calendar: Dictionary = {}
	if company_order.is_empty():
		return calendar

	var trade_days_by_month: Dictionary = _build_report_trade_days_by_month(REPORT_CALENDAR_END_YEAR)
	for year_value in range(int(trading_calendar.start_date().get("year", 2020)), REPORT_CALENDAR_END_YEAR + 1):
		for quarter_value in REPORT_MONTH_BY_QUARTER.keys():
			var report_month: int = int(REPORT_MONTH_BY_QUARTER[quarter_value])
			var month_key: String = _report_month_key(year_value, report_month)
			var trade_days: Array = trade_days_by_month.get(month_key, [])
			if trade_days.is_empty():
				continue
			var ordered_company_ids: Array = _company_ids_for_report_quarter(year_value, int(quarter_value))
			var company_count: int = max(ordered_company_ids.size(), 1)
			for company_index in range(ordered_company_ids.size()):
				var company_id: String = str(ordered_company_ids[company_index])
				var day_slot: int = int(floor((float(company_index) + 0.5) * float(trade_days.size()) / float(company_count)))
				day_slot = clamp(day_slot, 0, trade_days.size() - 1)
				var day_info: Dictionary = trade_days[day_slot]
				var date_key: String = str(day_info.get("date_key", ""))
				if date_key.is_empty():
					continue
				if not calendar.has(date_key):
					calendar[date_key] = []
				calendar[date_key].append(_build_quarterly_report_record(
					company_id,
					year_value,
					int(quarter_value),
					day_info
				))

	for date_key_value in calendar.keys():
		var date_key: String = str(date_key_value)
		var reports: Array = calendar.get(date_key, [])
		reports.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return str(a.get("ticker", "")) < str(b.get("ticker", ""))
		)
		calendar[date_key] = reports
	return calendar


func _build_report_trade_days_by_month(end_year: int) -> Dictionary:
	var grouped_days: Dictionary = {}
	var trade_date: Dictionary = trading_calendar.start_date()
	var trading_day_number: int = 1
	while int(trade_date.get("year", 2020)) <= end_year:
		var year_value: int = int(trade_date.get("year", 2020))
		var month_value: int = int(trade_date.get("month", 1))
		if REPORT_MONTH_BY_QUARTER.values().has(month_value) and trading_day_number >= 2:
			var month_key: String = _report_month_key(year_value, month_value)
			if not grouped_days.has(month_key):
				grouped_days[month_key] = []
			grouped_days[month_key].append({
				"date": trade_date.duplicate(true),
				"date_key": trading_calendar.to_key(trade_date),
				"trading_day_number": trading_day_number
			})
		trade_date = trading_calendar.next_trade_date(trade_date)
		trading_day_number += 1
	return grouped_days


func _company_ids_for_report_quarter(year_value: int, quarter_value: int) -> Array:
	var ordered_ids: Array = company_order.duplicate()
	ordered_ids.sort_custom(func(a, b) -> bool:
		var a_seed: int = STABLE_RNG.seed_from_parts([run_seed, "report_order", year_value, quarter_value, str(a)])
		var b_seed: int = STABLE_RNG.seed_from_parts([run_seed, "report_order", year_value, quarter_value, str(b)])
		if a_seed == b_seed:
			return str(a) < str(b)
		return a_seed < b_seed
	)
	return ordered_ids


func _build_quarterly_report_record(company_id: String, year_value: int, quarter_value: int, day_info: Dictionary) -> Dictionary:
	var definition: Dictionary = get_effective_company_definition(company_id, false, false)
	var report_date: Dictionary = day_info.get("date", {}).duplicate(true)
	return {
		"id": "%s_q%d_%d" % [company_id, quarter_value, year_value],
		"company_id": company_id,
		"ticker": str(definition.get("ticker", company_id.to_upper())),
		"company_name": str(definition.get("name", company_id.to_upper())),
		"year": year_value,
		"quarter": quarter_value,
		"period_label": "Q%d %d" % [quarter_value, year_value],
		"report_date": report_date,
		"date_key": str(day_info.get("date_key", "")),
		"trading_day_number": int(day_info.get("trading_day_number", 0))
	}


func _build_quarterly_report_event(report: Dictionary, trading_day_number: int, trade_date: Dictionary) -> Dictionary:
	var company_id: String = str(report.get("company_id", ""))
	var definition: Dictionary = get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = get_company(company_id)
	if definition.is_empty() or runtime.is_empty():
		return {}

	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "report_event", company_id, str(report.get("id", ""))])
	var quality: float = float(definition.get("quality_score", 50.0))
	var growth: float = float(definition.get("growth_score", 50.0))
	var risk: float = float(definition.get("risk_score", 50.0))
	var recent_sentiment: float = float(runtime.get("daily_change_pct", runtime.get("sentiment", 0.0)))
	var surprise_score: float = (
		(quality - 50.0) * 0.55 +
		(growth - 50.0) * 0.35 -
		(risk - 50.0) * 0.42 -
		recent_sentiment * 180.0 +
		rng.randf_range(-18.0, 18.0)
	)
	var event_id: String = "earnings_beat" if surprise_score >= 0.0 else "earnings_miss"
	var event_definition: Dictionary = DataRepository.get_event_definition(event_id)
	var ticker: String = str(definition.get("ticker", company_id.to_upper()))
	var company_name: String = str(definition.get("name", ticker))
	var period_label: String = str(report.get("period_label", "Q%d %d" % [
		int(report.get("quarter", 1)),
		int(report.get("year", int(trade_date.get("year", 2020))))
	]))
	var tone: String = str(event_definition.get("tone", "positive" if event_id == "earnings_beat" else "negative"))
	return {
		"event_id": event_id,
		"scope": "company",
		"event_family": "company",
		"category": "earnings",
		"tone": tone,
		"target_company_id": company_id,
		"target_ticker": ticker,
		"target_name": company_name,
		"headline": "%s files %s %s" % [ticker, period_label, "above expectations" if event_id == "earnings_beat" else "below expectations"],
		"summary": "%s files its %s report %s expectations." % [company_name, period_label, "above" if event_id == "earnings_beat" else "below"],
		"description": str(event_definition.get("description", "")),
		"sentiment_shift": float(event_definition.get("sentiment_shift", 0.0)),
		"broker_bias": str(event_definition.get("broker_bias", "")),
		"quarterly_report": true,
		"report_id": str(report.get("id", "")),
		"report_period_label": period_label,
		"report_date": trade_date.duplicate(true),
		"day_index": trading_day_number
	}


func _reports_for_date_key(date_key: String) -> Array:
	if quarterly_report_calendar.is_empty() and not company_order.is_empty():
		quarterly_report_calendar = _build_quarterly_report_calendar()
	var reports: Array = quarterly_report_calendar.get(date_key, [])
	return reports.duplicate(true)


func _report_month_key(year_value: int, month_value: int) -> String:
	return "%04d-%02d" % [year_value, month_value]


func _date_from_key(date_key: String) -> Dictionary:
	var parts: PackedStringArray = date_key.split("-")
	if parts.size() < 3:
		return {}
	return {
		"year": int(parts[0]),
		"month": int(parts[1]),
		"day": int(parts[2])
	}


func _record_event(event_data: Dictionary, trade_date: Dictionary, resolved_day_index: int) -> void:
	if event_data.is_empty():
		return

	var event_definition: Dictionary = DataRepository.get_event_definition(str(event_data.get("event_id", "")))
	var entry: Dictionary = event_data.duplicate(true)
	entry["day_index"] = resolved_day_index
	entry["trade_date"] = trade_date.duplicate(true)
	entry["scope"] = str(entry.get("scope", event_definition.get("scope", "")))
	entry["event_family"] = str(entry.get("event_family", event_definition.get("event_family", "")))
	entry["category"] = str(entry.get("category", event_definition.get("category", "")))
	entry["tone"] = str(entry.get("tone", event_definition.get("tone", "")))
	entry["description"] = str(entry.get("description", event_definition.get("description", "")))
	event_history.append(entry)
	if event_history.size() > MAX_EVENT_HISTORY:
		event_history = event_history.slice(event_history.size() - MAX_EVENT_HISTORY, event_history.size())


func _record_market_history(summary: Dictionary) -> void:
	if summary.is_empty():
		return

	var advancers: int = 0
	var decliners: int = 0
	var average_change_pct_sum: float = 0.0
	var company_count: int = 0
	for runtime_value in companies.values():
		var runtime: Dictionary = runtime_value
		var daily_change_pct: float = float(runtime.get("daily_change_pct", 0.0))
		average_change_pct_sum += daily_change_pct
		company_count += 1
		if daily_change_pct > 0.0:
			advancers += 1
		elif daily_change_pct < 0.0:
			decliners += 1

	var average_change_pct: float = 0.0
	if company_count > 0:
		average_change_pct = average_change_pct_sum / float(company_count)

	var history_entry: Dictionary = {
		"day_index": int(summary.get("day_index", day_index)),
		"trade_date": last_day_results.get("trade_date", {}).duplicate(true),
		"market_sentiment": market_sentiment,
		"average_change_pct": average_change_pct,
		"advancers": advancers,
		"decliners": decliners,
		"flat_count": max(company_count - advancers - decliners, 0),
		"company_count": company_count,
		"equity": get_total_equity(),
		"portfolio_delta": float(summary.get("portfolio_delta", 0.0)),
		"biggest_winner": summary.get("biggest_winner", {}).duplicate(true),
		"biggest_loser": summary.get("biggest_loser", {}).duplicate(true)
	}

	if not market_history.is_empty() and int(market_history[market_history.size() - 1].get("day_index", -1)) == int(history_entry.get("day_index", -2)):
		market_history[market_history.size() - 1] = history_entry
	else:
		market_history.append(history_entry)

	if market_history.size() > MAX_MARKET_HISTORY:
		market_history = market_history.slice(market_history.size() - MAX_MARKET_HISTORY, market_history.size())


func _upsert_news_archive_article(outlet_id: String, outlet_label: String, article: Dictionary) -> void:
	if article.is_empty():
		return

	var trade_date: Dictionary = article.get("trade_date", {}).duplicate(true)
	var year_number: int = int(trade_date.get("year", 0))
	var month_number: int = int(trade_date.get("month", 0))
	if year_number <= 0 or month_number <= 0:
		return

	var source_article_id: String = str(article.get("id", ""))
	var archive_article_id: String = "%s|%d|%s" % [
		outlet_id,
		int(article.get("day_index", -1)),
		source_article_id
	]
	var article_record: Dictionary = {
		"id": archive_article_id,
		"source_article_id": source_article_id,
		"outlet_id": outlet_id,
		"outlet_label": outlet_label,
		"headline": str(article.get("headline", "")),
		"deck": str(article.get("deck", "")),
		"body": str(article.get("body", "")),
		"trade_date": trade_date,
		"day_index": int(article.get("day_index", -1)),
		"target_company_id": str(article.get("target_company_id", "")),
		"target_ticker": str(article.get("target_ticker", "")),
		"target_company_name": str(article.get("target_company_name", "")),
		"target_sector_id": str(article.get("target_sector_id", "")),
		"tone": str(article.get("tone", "")),
		"category": str(article.get("category", "")),
		"event_family": str(article.get("event_family", "")),
		"source_chain_id": str(article.get("source_chain_id", "")),
		"chain_family": str(article.get("chain_family", "")),
		"meeting_id": str(article.get("meeting_id", "")),
		"venue_type": str(article.get("venue_type", "")),
		"author_id": str(article.get("author_id", "")),
		"author_name": str(article.get("author_name", "")),
		"author_role": str(article.get("author_role", "")),
		"author_contact_id": str(article.get("author_contact_id", "")),
		"public_section_label": str(article.get("public_section_label", "")),
		"public_status_label": str(article.get("public_status_label", "")),
		"outlet_logo_asset": str(article.get("outlet_logo_asset", "")),
		"author_portrait_asset": str(article.get("author_portrait_asset", "")),
		"article_image_asset": str(article.get("article_image_asset", "")),
		"image_slot": str(article.get("image_slot", "")),
		"public_story_angle": str(article.get("public_story_angle", "")),
		"public_confidence_label": str(article.get("public_confidence_label", "")),
		"public_continuity_phrase": str(article.get("public_continuity_phrase", ""))
	}
	news_archive_articles[archive_article_id] = article_record

	var summary_entry: Dictionary = {
		"id": archive_article_id,
		"headline": str(article_record.get("headline", "")),
		"deck": str(article_record.get("deck", "")),
		"trade_date": trade_date.duplicate(true),
		"day_index": int(article_record.get("day_index", -1)),
		"meeting_id": str(article_record.get("meeting_id", "")),
		"venue_type": str(article_record.get("venue_type", "")),
		"target_company_id": str(article_record.get("target_company_id", "")),
		"target_ticker": str(article_record.get("target_ticker", "")),
		"chain_family": str(article_record.get("chain_family", "")),
		"author_name": str(article_record.get("author_name", "")),
		"author_role": str(article_record.get("author_role", "")),
		"public_section_label": str(article_record.get("public_section_label", "")),
		"public_status_label": str(article_record.get("public_status_label", "")),
		"article_image_asset": str(article_record.get("article_image_asset", "")),
		"image_slot": str(article_record.get("image_slot", "")),
		"public_story_angle": str(article_record.get("public_story_angle", "")),
		"public_confidence_label": str(article_record.get("public_confidence_label", "")),
		"public_continuity_phrase": str(article_record.get("public_continuity_phrase", ""))
	}

	var outlet_bucket: Dictionary = news_archive_index.get(outlet_id, {
		"outlet_label": outlet_label,
		"years": {}
	}).duplicate(true)
	outlet_bucket["outlet_label"] = outlet_label

	var years_bucket: Dictionary = outlet_bucket.get("years", {}).duplicate(true)
	var year_key: String = str(year_number)
	var year_bucket: Dictionary = years_bucket.get(year_key, {
		"year": year_number,
		"months": {}
	}).duplicate(true)

	var months_bucket: Dictionary = year_bucket.get("months", {}).duplicate(true)
	var month_key: String = str(month_number)
	var month_bucket: Dictionary = months_bucket.get(month_key, {
		"month": month_number,
		"articles": []
	}).duplicate(true)

	var article_summaries: Array = month_bucket.get("articles", []).duplicate(true)
	var replaced: bool = false
	for article_index in range(article_summaries.size()):
		var existing_summary: Dictionary = article_summaries[article_index]
		if str(existing_summary.get("id", "")) == archive_article_id:
			article_summaries[article_index] = summary_entry
			replaced = true
			break
	if not replaced:
		article_summaries.append(summary_entry)

	article_summaries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("day_index", -1)) == int(b.get("day_index", -1)):
			return str(a.get("headline", "")) < str(b.get("headline", ""))
		return int(a.get("day_index", -1)) > int(b.get("day_index", -1))
	)

	month_bucket["articles"] = article_summaries
	months_bucket[month_key] = month_bucket
	year_bucket["months"] = months_bucket
	years_bucket[year_key] = year_bucket
	outlet_bucket["years"] = years_bucket
	news_archive_index[outlet_id] = outlet_bucket


func _append_event_to_companies(event_data: Dictionary) -> void:
	var event_id: String = str(event_data.get("event_id", ""))
	if event_id.is_empty():
		return

	for company_id_value in company_order:
		var company_id: String = str(company_id_value)
		if not companies.has(company_id):
			continue

		var definition: Dictionary = get_effective_company_definition(company_id, false, false)
		if definition.is_empty():
			continue

		if not _event_applies_to_company(event_data, company_id, str(definition.get("sector_id", ""))):
			continue

		var runtime: Dictionary = companies[company_id].duplicate(true)
		var active_events: Array = runtime.get("active_events", []).duplicate(true)
		if not _active_event_exists(active_events, event_data):
			active_events.append(event_data.duplicate(true))
		runtime["active_events"] = active_events

		var active_event_tags: Array = runtime.get("active_event_tags", []).duplicate()
		if not active_event_tags.has(event_id):
			active_event_tags.append(event_id)
		runtime["active_event_tags"] = active_event_tags
		companies[company_id] = runtime


func _append_company_arc_to_companies(arc_data: Dictionary) -> void:
	var company_id: String = str(arc_data.get("target_company_id", ""))
	if company_id.is_empty() or not companies.has(company_id):
		return

	var runtime: Dictionary = companies[company_id].duplicate(true)
	var hidden_story_flags: Array = runtime.get("hidden_story_flags", []).duplicate()
	var phase_visibility: String = str(arc_data.get("phase_visibility", "hidden"))
	if phase_visibility == "hidden":
		var hidden_flag: String = str(arc_data.get("phase_hidden_flag", arc_data.get("hidden_story_flag", "")))
		if not hidden_flag.is_empty() and not hidden_story_flags.has(hidden_flag):
			hidden_story_flags.append(hidden_flag)
		runtime["hidden_story_flags"] = hidden_story_flags
		companies[company_id] = runtime
		return

	runtime["hidden_story_flags"] = hidden_story_flags
	companies[company_id] = runtime
	var visible_arc: Dictionary = arc_data.duplicate(true)
	visible_arc["sentiment_shift"] = float(arc_data.get("phase_sentiment_shift", 0.0))
	_append_event_to_companies(visible_arc)


func _event_applies_to_company(event_data: Dictionary, company_id: String, sector_id: String) -> bool:
	if event_data.is_empty():
		return false

	var scope: String = str(event_data.get("scope", "company"))
	if scope == "market":
		return true
	if scope == "sector":
		var target_sector_id: String = str(event_data.get("target_sector_id", ""))
		if not target_sector_id.is_empty():
			return target_sector_id == sector_id
		return sector_id in event_data.get("affected_sector_ids", [])
	return str(event_data.get("target_company_id", "")) == company_id


func _active_event_exists(active_events: Array, event_data: Dictionary) -> bool:
	var event_id: String = str(event_data.get("event_id", ""))
	var target_company_id: String = str(event_data.get("target_company_id", ""))
	var target_sector_id: String = str(event_data.get("target_sector_id", ""))
	var headline: String = str(event_data.get("headline", ""))
	var arc_id: String = str(event_data.get("arc_id", ""))

	for active_event_value in active_events:
		var active_event: Dictionary = active_event_value
		if str(active_event.get("event_id", "")) != event_id:
			continue
		if str(active_event.get("arc_id", "")) == arc_id and not arc_id.is_empty():
			return true
		if str(active_event.get("target_company_id", "")) != target_company_id:
			continue
		if str(active_event.get("target_sector_id", "")) != target_sector_id:
			continue
		if str(active_event.get("headline", "")) == headline:
			return true

	return false


func _normalize_company_runtime(runtime: Dictionary) -> Dictionary:
	var normalized_runtime: Dictionary = runtime.duplicate(true)
	normalized_runtime["current_price"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_runtime.get("current_price", 0.0)))
	normalized_runtime["previous_close"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_runtime.get("previous_close", normalized_runtime.get("current_price", 0.0))))
	normalized_runtime["starting_price"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_runtime.get("starting_price", normalized_runtime.get("current_price", 0.0))))
	normalized_runtime["ytd_open_price"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_runtime.get("ytd_open_price", normalized_runtime.get("starting_price", normalized_runtime.get("current_price", 0.0)))))
	normalized_runtime["ytd_reference_year"] = int(normalized_runtime.get("ytd_reference_year", int(current_trade_date.get("year", 2020))))
	normalized_runtime["price_history"] = _normalize_price_history(normalized_runtime.get("price_history", []))
	normalized_runtime["price_bars"] = _normalize_price_bars(
		normalized_runtime.get("price_bars", []),
		normalized_runtime.get("price_history", [])
	)
	if normalized_runtime["price_history"].is_empty() and not normalized_runtime["price_bars"].is_empty():
		normalized_runtime["price_history"] = _rebuild_price_history_from_bars(normalized_runtime["price_bars"])
	normalized_runtime["company_profile"] = _normalize_company_profile(normalized_runtime.get("company_profile", {}))
	normalized_runtime["active_events"] = normalized_runtime.get("active_events", []).duplicate(true)
	normalized_runtime["market_depth_context"] = normalized_runtime.get("market_depth_context", {}).duplicate(true)
	normalized_runtime["player_market_impact"] = normalized_runtime.get("player_market_impact", {}).duplicate(true)
	return normalized_runtime


func _normalize_day_result_company_runtime(runtime: Dictionary) -> Dictionary:
	var normalized_runtime: Dictionary = runtime.duplicate()
	normalized_runtime["current_price"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_runtime.get("current_price", 0.0)))
	normalized_runtime["previous_close"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_runtime.get("previous_close", normalized_runtime.get("current_price", 0.0))))
	normalized_runtime["starting_price"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_runtime.get("starting_price", normalized_runtime.get("current_price", 0.0))))
	normalized_runtime["ytd_open_price"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_runtime.get("ytd_open_price", normalized_runtime.get("starting_price", normalized_runtime.get("current_price", 0.0)))))
	normalized_runtime["ytd_reference_year"] = int(normalized_runtime.get("ytd_reference_year", int(current_trade_date.get("year", 2020))))
	normalized_runtime["price_history"] = _normalize_day_result_price_history(normalized_runtime.get("price_history", []))
	normalized_runtime["price_bars"] = _normalize_day_result_price_bars(
		normalized_runtime.get("price_bars", []),
		normalized_runtime.get("price_history", [])
	)
	if normalized_runtime["price_history"].is_empty() and not normalized_runtime["price_bars"].is_empty():
		normalized_runtime["price_history"] = _rebuild_price_history_from_bars(normalized_runtime["price_bars"])
	var company_profile_value = normalized_runtime.get("company_profile", {})
	normalized_runtime["company_profile"] = company_profile_value if typeof(company_profile_value) == TYPE_DICTIONARY else {}
	normalized_runtime["active_event_tags"] = normalized_runtime.get("active_event_tags", []).duplicate()
	normalized_runtime["active_events"] = normalized_runtime.get("active_events", []).duplicate(true)
	normalized_runtime["hidden_story_flags"] = normalized_runtime.get("hidden_story_flags", []).duplicate()
	normalized_runtime["ar_limits"] = normalized_runtime.get("ar_limits", {}).duplicate(true)
	normalized_runtime["volume_context"] = normalized_runtime.get("volume_context", {}).duplicate(true)
	normalized_runtime["market_depth_context"] = normalized_runtime.get("market_depth_context", {}).duplicate(true)
	normalized_runtime["player_market_impact"] = normalized_runtime.get("player_market_impact", {}).duplicate(true)
	return normalized_runtime


func _normalize_price_history(price_history: Array) -> Array:
	var normalized_history: Array = []
	for price in price_history:
		normalized_history.append(IDX_PRICE_RULES.normalize_last_price(float(price)))
	return normalized_history


func _normalize_day_result_price_history(price_history_value: Variant) -> Array:
	if typeof(price_history_value) != TYPE_ARRAY:
		return []
	var normalized_history: Array = price_history_value.duplicate()
	if normalized_history.is_empty():
		return []
	var latest_index: int = normalized_history.size() - 1
	normalized_history[latest_index] = IDX_PRICE_RULES.normalize_last_price(float(normalized_history[latest_index]))
	return normalized_history


func _normalize_price_bars(price_bars: Array, price_history: Array) -> Array:
	var normalized_bars: Array = []
	for bar_value in price_bars:
		if typeof(bar_value) != TYPE_DICTIONARY:
			continue
		normalized_bars.append(_normalize_price_bar(bar_value.duplicate(true)))

	if normalized_bars.is_empty():
		normalized_bars = _rebuild_price_bars_from_history(price_history)

	if normalized_bars.size() > MAX_PRICE_BARS_HISTORY:
		normalized_bars = normalized_bars.slice(
			normalized_bars.size() - MAX_PRICE_BARS_HISTORY,
			normalized_bars.size()
		)
	return normalized_bars


func _normalize_day_result_price_bars(price_bars_value: Variant, price_history: Array) -> Array:
	if typeof(price_bars_value) != TYPE_ARRAY:
		return _rebuild_price_bars_from_history(price_history)
	var normalized_bars: Array = price_bars_value.duplicate()
	if normalized_bars.is_empty():
		return _rebuild_price_bars_from_history(price_history)
	if normalized_bars.size() > MAX_PRICE_BARS_HISTORY:
		normalized_bars = normalized_bars.slice(
			normalized_bars.size() - MAX_PRICE_BARS_HISTORY,
			normalized_bars.size()
		)

	var latest_index: int = normalized_bars.size() - 1
	var latest_bar_value = normalized_bars[latest_index]
	if typeof(latest_bar_value) != TYPE_DICTIONARY:
		return _normalize_price_bars(price_bars_value, price_history)
	normalized_bars[latest_index] = _normalize_price_bar(latest_bar_value.duplicate(true))
	return normalized_bars


func _normalize_price_bar(bar: Dictionary) -> Dictionary:
	var trade_date_value = bar.get("trade_date", {})
	var trade_date: Dictionary = trade_date_value.duplicate(true) if typeof(trade_date_value) == TYPE_DICTIONARY else {}
	var normalized_bar: Dictionary = {
		"trade_date": trade_date,
		"open": IDX_PRICE_RULES.normalize_last_price(float(bar.get("open", 0.0))),
		"high": IDX_PRICE_RULES.normalize_last_price(float(bar.get("high", bar.get("open", 0.0)))),
		"low": IDX_PRICE_RULES.normalize_last_price(float(bar.get("low", bar.get("open", 0.0)))),
		"close": IDX_PRICE_RULES.normalize_last_price(float(bar.get("close", bar.get("open", 0.0)))),
		"volume_shares": max(int(bar.get("volume_shares", 0)), 0),
		"value": max(float(bar.get("value", 0.0)), 0.0)
	}
	normalized_bar["high"] = max(
		float(normalized_bar.get("high", 0.0)),
		float(normalized_bar.get("open", 0.0)),
		float(normalized_bar.get("close", 0.0))
	)
	normalized_bar["low"] = min(
		float(normalized_bar.get("low", 0.0)),
		float(normalized_bar.get("open", 0.0)),
		float(normalized_bar.get("close", 0.0))
	)
	normalized_bar["volume_lots"] = int(floor(float(normalized_bar.get("volume_shares", 0)) / float(LOT_SIZE)))
	if is_zero_approx(float(normalized_bar.get("value", 0.0))):
		normalized_bar["value"] = float(normalized_bar.get("close", 0.0)) * float(normalized_bar.get("volume_shares", 0))
	for optional_key in [
		"limit_lock",
		"limit_source",
		"impact_side",
		"player_broker_code"
	]:
		if bar.has(optional_key):
			normalized_bar[optional_key] = str(bar.get(optional_key, ""))
	for optional_bool_key in ["locked_through_day"]:
		if bar.has(optional_bool_key):
			normalized_bar[optional_bool_key] = bool(bar.get(optional_bool_key, false))
	for optional_float_key in [
		"player_impact_ratio",
		"player_liquidity_consumed",
		"player_free_float_pct",
		"ask_depth_value",
		"bid_depth_value"
	]:
		if bar.has(optional_float_key):
			normalized_bar[optional_float_key] = float(bar.get(optional_float_key, 0.0))
	return normalized_bar


func _rebuild_price_bars_from_history(price_history: Array) -> Array:
	var normalized_history: Array = _normalize_price_history(price_history)
	if normalized_history.size() < 2:
		return []

	var rebuilt_bars: Array = []
	var start_history_index: int = max(normalized_history.size() - MAX_PRICE_BARS_HISTORY, 1)
	for history_index in range(start_history_index, normalized_history.size()):
		var previous_close: float = float(normalized_history[history_index - 1])
		var current_close: float = float(normalized_history[history_index])
		rebuilt_bars.append(_normalize_price_bar({
			"trade_date": trading_calendar.trade_date_for_index(history_index),
			"open": previous_close,
			"high": max(previous_close, current_close),
			"low": min(previous_close, current_close),
			"close": current_close,
			"volume_shares": 0,
			"value": 0.0
		}))
	return rebuilt_bars


func _rebuild_price_history_from_bars(price_bars: Array) -> Array:
	if price_bars.is_empty():
		return []

	var history: Array = [float(price_bars[0].get("open", 0.0))]
	for bar_value in price_bars:
		var bar: Dictionary = bar_value
		history.append(float(bar.get("close", 0.0)))
	return _normalize_price_history(history)


func _normalize_company_profile(company_profile: Dictionary) -> Dictionary:
	var normalized_profile: Dictionary = company_profile.duplicate(true)
	if normalized_profile.is_empty():
		return {}

	normalized_profile["base_price"] = IDX_PRICE_RULES.normalize_last_price(float(normalized_profile.get("base_price", 0.0)))
	var detail_status: String = str(normalized_profile.get("detail_status", "ready"))
	if detail_status == "hydrating":
		detail_status = "cold"
	if not ["cold", "queued", "ready"].has(detail_status):
		detail_status = "ready"
	normalized_profile["detail_status"] = detail_status
	var detail_persistence: String = str(normalized_profile.get(
		"detail_persistence",
		COMPANY_DETAIL_PERSISTENCE_PERSISTENT if detail_status == "ready" else ""
	))
	if detail_status != "ready":
		detail_persistence = ""
	elif not [COMPANY_DETAIL_PERSISTENCE_PERSISTENT, COMPANY_DETAIL_PERSISTENCE_EPHEMERAL].has(detail_persistence):
		detail_persistence = COMPANY_DETAIL_PERSISTENCE_PERSISTENT
	normalized_profile["detail_persistence"] = detail_persistence
	normalized_profile["profile_seed"] = int(normalized_profile.get("profile_seed", 0))
	if normalized_profile.has("name"):
		normalized_profile["name"] = str(normalized_profile.get("name", ""))
	if normalized_profile.has("sector_id"):
		normalized_profile["sector_id"] = str(normalized_profile.get("sector_id", ""))
	normalized_profile["company_size_id"] = int(normalized_profile.get("company_size_id", 0))
	normalized_profile["company_age"] = int(normalized_profile.get("company_age", 0))
	normalized_profile["founded_year"] = int(normalized_profile.get("founded_year", 0))
	normalized_profile["employee_count"] = int(normalized_profile.get("employee_count", 0))
	normalized_profile["profile_revenue"] = float(normalized_profile.get("profile_revenue", 0.0))
	normalized_profile["profile_revenue_value"] = float(normalized_profile.get("profile_revenue_value", 0.0))
	normalized_profile["archetype_id"] = str(normalized_profile.get("archetype_id", ""))
	normalized_profile["archetype_label"] = str(normalized_profile.get("archetype_label", ""))
	normalized_profile["company_size_label"] = str(normalized_profile.get("company_size_label", ""))
	normalized_profile["profile_revenue_unit"] = str(normalized_profile.get("profile_revenue_unit", ""))
	normalized_profile["profile_description"] = str(normalized_profile.get("profile_description", ""))
	var profile_tags: Array = []
	for tag_value in normalized_profile.get("profile_tags", []):
		var tag: String = str(tag_value).strip_edges()
		if tag.is_empty():
			continue
		profile_tags.append(tag)
	normalized_profile["profile_tags"] = profile_tags
	var management_roster: Array = []
	for management_value in normalized_profile.get("management_roster", []):
		if typeof(management_value) != TYPE_DICTIONARY:
			continue
		var management_contact: Dictionary = management_value.duplicate(true)
		management_contact["contact_id"] = str(management_contact.get("contact_id", management_contact.get("id", "")))
		management_contact["id"] = str(management_contact.get("id", management_contact.get("contact_id", "")))
		management_contact["display_name"] = str(management_contact.get("display_name", ""))
		management_contact["affiliation_type"] = str(management_contact.get("affiliation_type", "insider"))
		management_contact["affiliation_role"] = str(management_contact.get("affiliation_role", ""))
		management_contact["company_id"] = str(management_contact.get("company_id", ""))
		management_contact["affiliated_company_id"] = str(management_contact.get("affiliated_company_id", management_contact.get("company_id", "")))
		management_contact["sector_id"] = str(management_contact.get("sector_id", ""))
		management_contact["template_contact_id"] = str(management_contact.get("template_contact_id", ""))
		management_contact["role"] = str(management_contact.get("role", management_contact.get("role_label", "")))
		management_contact["role_label"] = str(management_contact.get("role_label", management_contact.get("role", "")))
		management_contact["recognition_required"] = int(management_contact.get("recognition_required", 50))
		management_contact["base_relationship"] = int(management_contact.get("base_relationship", 18))
		management_contact["reliability"] = float(management_contact.get("reliability", 0.68))
		management_contact["tone"] = str(management_contact.get("tone", "mixed"))
		management_contact["intro"] = str(management_contact.get("intro", ""))
		management_roster.append(management_contact)
	normalized_profile["management_roster"] = management_roster
	if normalized_profile.has("post_deal_identity"):
		var identity_value = normalized_profile.get("post_deal_identity", {})
		normalized_profile["post_deal_identity"] = identity_value.duplicate(true) if typeof(identity_value) == TYPE_DICTIONARY else {}
	var financial_history: Array = []
	for history_entry_value in normalized_profile.get("financial_history", []):
		var history_entry: Dictionary = history_entry_value.duplicate(true)
		if history_entry.has("implied_share_price"):
			history_entry["implied_share_price"] = IDX_PRICE_RULES.normalize_last_price(float(history_entry.get("implied_share_price", 0.0)))
		financial_history.append(history_entry)
	normalized_profile["financial_history"] = financial_history
	normalized_profile["financial_statement_snapshot"] = normalized_profile.get("financial_statement_snapshot", {}).duplicate(true)
	return normalized_profile


func _get_historical_chart_bars(company_id: String, runtime: Dictionary, runtime_bars: Array) -> Array:
	if historical_chart_bar_cache.has(company_id):
		return historical_chart_bar_cache[company_id].duplicate(true)

	var required_bars: int = max(CHART_HISTORY_VISIBLE_BARS - runtime_bars.size(), 0)
	if required_bars <= 0:
		return []

	var historical_end_date: Dictionary = _historical_chart_end_date(runtime_bars)
	if historical_end_date.is_empty():
		return []

	var company_profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	if company_profile.is_empty():
		return []

	var generated_bars: Array = company_generator.build_historical_chart_bars(
		company_profile,
		_build_historical_trade_dates(historical_end_date, required_bars),
		_historical_chart_end_close(runtime, runtime_bars),
		run_seed,
		company_id
	)
	var normalized_bars: Array = _normalize_price_bars(generated_bars, [])
	historical_chart_bar_cache[company_id] = normalized_bars
	return normalized_bars.duplicate(true)


func _historical_chart_end_date(runtime_bars: Array) -> Dictionary:
	if not runtime_bars.is_empty():
		return trading_calendar.previous_trade_date(
			runtime_bars[0].get("trade_date", current_trade_date)
		)
	return trading_calendar.previous_trade_date(current_trade_date)


func _historical_chart_end_close(runtime: Dictionary, runtime_bars: Array) -> float:
	if not runtime_bars.is_empty():
		return IDX_PRICE_RULES.normalize_last_price(float(
			runtime_bars[0].get("open", runtime.get("starting_price", runtime.get("current_price", 0.0)))
		))
	return IDX_PRICE_RULES.normalize_last_price(float(
		runtime.get("starting_price", runtime.get("current_price", 0.0))
	))


func _build_historical_trade_dates(end_date: Dictionary, bar_count: int) -> Array:
	var dates: Array = []
	if bar_count <= 0:
		return dates

	var cursor: Dictionary = end_date.duplicate(true)
	for bar_index in range(bar_count):
		dates.append(cursor.duplicate(true))
		if bar_index < bar_count - 1:
			cursor = trading_calendar.previous_trade_date(cursor)
	dates.reverse()
	return dates


func _build_company_profile_view(
	company_profile: Dictionary,
	include_financial_history: bool,
	include_statement_history: bool
) -> Dictionary:
	if company_profile.is_empty():
		return {}

	var profile_view: Dictionary = {}
	for profile_key_value in COMPANY_PROFILE_KEYS:
		var profile_key: String = str(profile_key_value)
		if not company_profile.has(profile_key):
			continue
		if profile_key == "financial_history":
			if include_financial_history:
				profile_view[profile_key] = company_profile.get(profile_key, []).duplicate(true)
			continue
		if profile_key == "financial_statement_snapshot":
			profile_view[profile_key] = _build_statement_snapshot_view(
				company_profile.get(profile_key, {}),
				include_statement_history
			)
			continue

		var profile_value = company_profile.get(profile_key)
		match typeof(profile_value):
			TYPE_DICTIONARY, TYPE_ARRAY:
				profile_view[profile_key] = profile_value.duplicate(true)
			_:
				profile_view[profile_key] = profile_value
	return profile_view


func _build_statement_snapshot_view(
	statement_snapshot: Dictionary,
	include_statement_history: bool
) -> Dictionary:
	if statement_snapshot.is_empty():
		return {}

	var snapshot_view: Dictionary = {}
	var passthrough_keys: Array = [
		"statement_year",
		"statement_quarter",
		"statement_period_label",
		"statement_scope",
		"quarterly_statement_count",
		"history_start_period_label",
		"history_end_period_label"
	]
	for snapshot_key_value in passthrough_keys:
		var snapshot_key: String = str(snapshot_key_value)
		if statement_snapshot.has(snapshot_key):
			snapshot_view[snapshot_key] = statement_snapshot[snapshot_key]

	snapshot_view["income_statement"] = statement_snapshot.get("income_statement", []).duplicate(true)
	snapshot_view["balance_sheet"] = statement_snapshot.get("balance_sheet", []).duplicate(true)
	snapshot_view["cash_flow"] = statement_snapshot.get("cash_flow", []).duplicate(true)
	if include_statement_history:
		snapshot_view["quarterly_statements"] = statement_snapshot.get("quarterly_statements", []).duplicate(true)
	return snapshot_view


func _reset_ytd_open_prices_for_year(year: int) -> void:
	for company_id_value in companies.keys():
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = companies[company_id].duplicate(true)
		var current_price: float = IDX_PRICE_RULES.normalize_last_price(float(runtime.get("current_price", 0.0)))
		runtime["ytd_open_price"] = current_price
		runtime["ytd_reference_year"] = year
		companies[company_id] = runtime


func _ensure_macro_state_for_year(year: int) -> void:
	var safe_year: int = max(year, 2020)
	var year_key: String = str(safe_year)
	if yearly_macro_states.has(year_key):
		return

	var previous_state: Dictionary = {}
	if safe_year > 2020:
		_ensure_macro_state_for_year(safe_year - 1)
		previous_state = yearly_macro_states.get(str(safe_year - 1), {}).duplicate(true)

	yearly_macro_states[year_key] = macro_state_system.build_year_state(
		run_seed,
		safe_year,
		DataRepository.get_sector_definitions(),
		previous_state
	)


func _ensure_company_profiles() -> void:
	for company_id_value in company_order:
		var company_id: String = str(company_id_value)
		ensure_company_core_profile(company_id)


func _get_base_company_definition(company_id: String) -> Dictionary:
	if company_definitions.has(company_id):
		return company_definitions[company_id].duplicate(true)
	return DataRepository.get_company_archetype(company_id)


func _apply_company_profile_to_definition(definition: Dictionary, company_profile: Dictionary) -> Dictionary:
	var effective_definition: Dictionary = definition.duplicate(true)
	for profile_key_value in COMPANY_PROFILE_KEYS:
		var profile_key: String = str(profile_key_value)
		if company_profile.has(profile_key):
			effective_definition[profile_key] = company_profile[profile_key]
	return effective_definition


func _company_trade_block_message(company_id: String) -> String:
	if not companies.has(company_id):
		return ""
	var runtime: Dictionary = companies.get(company_id, {})
	var profile_value = runtime.get("company_profile", {})
	if typeof(profile_value) != TYPE_DICTIONARY:
		return ""
	var profile: Dictionary = profile_value
	if profile.is_empty():
		return ""
	if bool(profile.get("trade_disabled", false)):
		var listing_label: String = str(profile.get("listing_status_label", "Trading disabled"))
		if listing_label.is_empty():
			listing_label = "Trading disabled"
		return "%s; public trading is no longer available." % listing_label
	return ""


func _estimate_order(company_id: String, shares: int, is_buy: bool) -> Dictionary:
	if not companies.has(company_id):
		return {"success": false, "message": "Unknown company selection."}
	if shares <= 0:
		return {"success": false, "message": "Share count must be positive."}
	var trade_block_message: String = _company_trade_block_message(company_id)
	if not trade_block_message.is_empty():
		return {"success": false, "message": trade_block_message}

	var current_price = float(companies[company_id].get("current_price", 0.0))
	var gross_value: float = current_price * shares
	var fee_rate: float = get_effective_buy_fee_rate() if is_buy else get_effective_sell_fee_rate()
	var fee: float = gross_value * fee_rate
	var lots: int = int(round(float(shares) / float(LOT_SIZE)))
	var result: Dictionary = {
		"success": true,
		"shares": shares,
		"lots": lots,
		"price_per_share": current_price,
		"gross_value": gross_value,
		"fee_rate": fee_rate,
		"fee": fee
	}

	if is_buy:
		result["total_cost"] = gross_value + fee
	else:
		result["net_proceeds"] = gross_value - fee

	return result


func _format_currency(value: float) -> String:
	return "%sRp%s" % [
		"-" if value < 0.0 else "",
		_format_decimal(absf(value), 2, true)
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
