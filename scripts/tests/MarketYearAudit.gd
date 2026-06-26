extends Node

const DEFAULT_AUDIT_SEED := 20260606
const DEFAULT_AUDIT_DIFFICULTY := "grind"
const DEFAULT_AUDIT_TRADING_DAYS := 252
const REPORT_PREFIX := "MARKET_YEAR_AUDIT "
const DUMP_PHASES := ["distribution", "dump", "dead_cat", "cooldown"]


func _ready() -> void:
	DataRepository.reload_all()
	var args: Array = OS.get_cmdline_user_args()
	var seed: int = _arg_int(args, "--audit-seed", DEFAULT_AUDIT_SEED)
	var difficulty_id: String = _arg_string(args, "--audit-difficulty", DEFAULT_AUDIT_DIFFICULTY)
	var trading_days: int = _arg_int(args, "--audit-days", DEFAULT_AUDIT_TRADING_DAYS)
	var use_catalog: bool = _arg_bool(args, "--audit-use-catalog", false)
	var company_count_override: int = _arg_int(args, "--audit-company-count", 0)
	var compact_report: bool = _arg_bool(args, "--audit-compact-report", false)
	var audit_started_at_usec: int = Time.get_ticks_usec()
	var report: Dictionary = _run_audit(seed, difficulty_id, trading_days, use_catalog, company_count_override)
	report["audit_elapsed_msec"] = float(Time.get_ticks_usec() - audit_started_at_usec) / 1000.0
	if compact_report:
		report = _compact_audit_report(report)
	print("%s%s" % [REPORT_PREFIX, JSON.stringify(report)])
	get_tree().quit(0 if bool(report.get("success", false)) else 1)


func _run_audit(seed: int, difficulty_id: String, trading_days: int, use_catalog: bool = false, company_count_override: int = 0) -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(difficulty_id)
	difficulty_id = str(difficulty_config.get("id", difficulty_id))
	if company_count_override > 0:
		difficulty_config["company_count"] = company_count_override
	if use_catalog:
		difficulty_config["use_company_universe_catalog"] = true
	var company_definitions: Array = GameManager.build_company_roster(seed, difficulty_config)
	RunState.setup_new_run(seed, company_definitions, difficulty_config, false)
	var audit_cash_floor: float = max(float(difficulty_config.get("starting_cash", 0.0)), 1.0)
	_maintain_audit_cash_floor(audit_cash_floor)

	var initial_prices: Dictionary = _initial_price_lookup()
	var counters: Dictionary = _default_counters()
	var event_id_counts: Dictionary = {}
	var event_family_counts: Dictionary = {}
	var corporate_category_counts: Dictionary = {}
	var special_event_id_counts: Dictionary = {}
	var campaign_tracker: Dictionary = {}
	var total_market_value: float = 0.0
	var total_gorengan_value: float = 0.0
	var max_market_value: Dictionary = {"day_index": 0, "value": 0.0}
	var max_gorengan_value: Dictionary = {"day_index": 0, "value": 0.0}
	var price_exposure_tracker: Dictionary = _default_price_exposure_tracker()

	for _day_offset in range(max(trading_days, 0)):
		var advance_result: Dictionary = GameManager.simulate_opening_session(false)
		if advance_result.has("success") and not bool(advance_result.get("success", false)):
			return {
				"success": false,
				"message": str(advance_result.get("message", "Advance day failed.")),
				"days_completed": int(counters.get("days_completed", 0))
			}
		var day_result: Dictionary = advance_result.get("day_result", {})
		if day_result.is_empty():
			return {
				"success": false,
				"message": "Advance day returned no day_result.",
				"days_completed": int(counters.get("days_completed", 0))
			}
		_maintain_audit_cash_floor(audit_cash_floor)

		counters["days_completed"] = int(counters.get("days_completed", 0)) + 1
		_collect_day_counts(
			day_result,
			counters,
			event_id_counts,
			event_family_counts,
			corporate_category_counts,
			special_event_id_counts
		)
		_collect_quarterly_filing_counts(RunState.last_day_results, counters)
		_collect_campaign_state(campaign_tracker)
		_collect_abnormal_move_counts(counters)
		_collect_price_exposure_state(price_exposure_tracker)
		var value_snapshot: Dictionary = _daily_value_snapshot()
		total_market_value += float(value_snapshot.get("market_value", 0.0))
		total_gorengan_value += float(value_snapshot.get("gorengan_value", 0.0))
		if float(value_snapshot.get("market_value", 0.0)) > float(max_market_value.get("value", 0.0)):
			max_market_value = {
				"day_index": RunState.day_index,
				"value": float(value_snapshot.get("market_value", 0.0))
			}
		if float(value_snapshot.get("gorengan_value", 0.0)) > float(max_gorengan_value.get("value", 0.0)):
			max_gorengan_value = {
				"day_index": RunState.day_index,
				"value": float(value_snapshot.get("gorengan_value", 0.0))
			}

	var stock_report: Dictionary = _build_stock_report(initial_prices)
	var campaign_report: Dictionary = _build_campaign_report(campaign_tracker)
	var price_exposure_report: Dictionary = _build_price_exposure_report(price_exposure_tracker, initial_prices)
	var days_completed: int = max(int(counters.get("days_completed", 0)), 1)
	return {
		"success": true,
		"seed": seed,
		"difficulty_id": difficulty_id,
		"difficulty_label": str(difficulty_config.get("label", difficulty_id.capitalize())),
		"use_company_universe_catalog": bool(difficulty_config.get("use_company_universe_catalog", false)),
		"requested_trading_days": trading_days,
		"days_completed": int(counters.get("days_completed", 0)),
		"final_day_index": RunState.day_index,
		"final_trade_date": RunState.get_current_trade_date(),
		"company_count": RunState.company_order.size(),
		"portfolio": _portfolio_report(),
		"stocks": stock_report,
		"events": {
			"counters": counters,
			"event_family_counts": event_family_counts,
			"event_id_counts": event_id_counts,
			"corporate_category_counts": corporate_category_counts,
			"special_event_id_counts": special_event_id_counts
		},
		"price_exposure": price_exposure_report,
		"gorengan_campaigns": campaign_report,
		"turnover": {
			"avg_market_value_per_day": total_market_value / float(days_completed),
			"avg_gorengan_value_per_day": total_gorengan_value / float(days_completed),
			"max_market_value_day": max_market_value,
			"max_gorengan_value_day": max_gorengan_value
		}
	}


func _default_counters() -> Dictionary:
	return {
		"days_completed": 0,
		"scheduled_events": 0,
		"scheduled_market_macro_events": 0,
		"scheduled_sector_events": 0,
		"scheduled_company_events": 0,
		"scheduled_person_events": 0,
		"company_events": 0,
		"quarterly_report_events": 0,
		"quarterly_filings_applied": 0,
		"quarterly_earnings_beats": 0,
		"quarterly_earnings_misses": 0,
		"quarterly_positive_surprises": 0,
		"quarterly_negative_surprises": 0,
		"quarterly_revenue_growth_reports": 0,
		"quarterly_revenue_decline_reports": 0,
		"quarterly_margin_positive_reports": 0,
		"company_arc_events": 0,
		"company_roadmap_events": 0,
		"corporate_action_events": 0,
		"corporate_action_hard_events": 0,
		"corporate_action_rumor_soft_events": 0,
		"index_review_events": 0,
		"special_events": 0,
		"policy_parody_events": 0,
		"dirty_tip_offers": 0,
		"dirty_tip_results": 0,
		"dirty_tip_caught": 0,
		"dirty_tip_clean": 0,
		"legal_hold_starts": 0,
		"legal_hold_days": 0,
		"hospital_starts": 0,
		"hospital_days": 0,
		"life_obligations": 0,
		"life_loan_payments": 0,
		"bankruptcies": 0,
		"network_request_results": 0,
		"network_tip_results": 0,
		"life_development_results": 0,
		"abnormal_move_stock_days": 0,
		"abnormal_move_guarded_bars": 0,
		"abnormal_move_uma_stock_days": 0,
		"abnormal_move_suspension_stock_days": 0,
		"abnormal_move_split_required_stock_days": 0,
		"abnormal_move_distribution_guard_stock_days": 0,
		"abnormal_move_floor_stabilizer_stock_days": 0,
		"floor_turnaround_candidate_stock_days": 0,
		"floor_zombie_stock_days": 0,
		"abnormal_move_max_green_streak": 0
	}


func _collect_day_counts(
	day_result: Dictionary,
	counters: Dictionary,
	event_id_counts: Dictionary,
	event_family_counts: Dictionary,
	corporate_category_counts: Dictionary,
	special_event_id_counts: Dictionary
) -> void:
	var scheduled_event: Dictionary = day_result.get("scheduled_event", {})
	if not scheduled_event.is_empty():
		_count_event(scheduled_event, event_id_counts, event_family_counts)
		counters["scheduled_events"] = int(counters.get("scheduled_events", 0)) + 1
		var scheduled_family: String = str(scheduled_event.get("event_family", ""))
		var scheduled_scope: String = str(scheduled_event.get("scope", ""))
		var scheduled_category: String = str(scheduled_event.get("category", ""))
		if scheduled_family == "market" and (scheduled_scope == "market" or scheduled_category.find("macro") >= 0):
			counters["scheduled_market_macro_events"] = int(counters.get("scheduled_market_macro_events", 0)) + 1
		elif scheduled_scope == "sector":
			counters["scheduled_sector_events"] = int(counters.get("scheduled_sector_events", 0)) + 1
		elif scheduled_family == "company":
			counters["scheduled_company_events"] = int(counters.get("scheduled_company_events", 0)) + 1
		elif scheduled_family == "person":
			counters["scheduled_person_events"] = int(counters.get("scheduled_person_events", 0)) + 1

	for event_value in day_result.get("report_events", []):
		if typeof(event_value) == TYPE_DICTIONARY:
			var report_event: Dictionary = event_value
			counters["company_events"] = int(counters.get("company_events", 0)) + 1
			if bool(report_event.get("quarterly_report", false)):
				counters["quarterly_report_events"] = int(counters.get("quarterly_report_events", 0)) + 1
				if str(report_event.get("event_id", "")) == "earnings_beat":
					counters["quarterly_earnings_beats"] = int(counters.get("quarterly_earnings_beats", 0)) + 1
				elif str(report_event.get("event_id", "")) == "earnings_miss":
					counters["quarterly_earnings_misses"] = int(counters.get("quarterly_earnings_misses", 0)) + 1
				var filing_value = report_event.get("quarterly_filing", {})
				if typeof(filing_value) == TYPE_DICTIONARY:
					var filing: Dictionary = filing_value
					if float(filing.get("surprise_score", 0.0)) >= 0.0:
						counters["quarterly_positive_surprises"] = int(counters.get("quarterly_positive_surprises", 0)) + 1
					else:
						counters["quarterly_negative_surprises"] = int(counters.get("quarterly_negative_surprises", 0)) + 1
					if float(filing.get("revenue_growth_yoy", 0.0)) >= 0.0:
						counters["quarterly_revenue_growth_reports"] = int(counters.get("quarterly_revenue_growth_reports", 0)) + 1
					else:
						counters["quarterly_revenue_decline_reports"] = int(counters.get("quarterly_revenue_decline_reports", 0)) + 1
					if float(filing.get("net_profit_margin", 0.0)) > 0.0:
						counters["quarterly_margin_positive_reports"] = int(counters.get("quarterly_margin_positive_reports", 0)) + 1
			_count_event(report_event, event_id_counts, event_family_counts)

	_count_event_array(day_result.get("started_company_arcs", []), "company_arc_events", counters, event_id_counts, event_family_counts)
	_count_event_array(day_result.get("company_arc_phase_events", []), "company_arc_events", counters, event_id_counts, event_family_counts)
	_count_event_array(day_result.get("company_roadmap_events", []), "company_roadmap_events", counters, event_id_counts, event_family_counts)
	_count_event_array(day_result.get("index_review_events", []), "index_review_events", counters, event_id_counts, event_family_counts)

	for event_value in day_result.get("corporate_action_events", []):
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_value
		counters["corporate_action_events"] = int(counters.get("corporate_action_events", 0)) + 1
		_count_event(event, event_id_counts, event_family_counts)
		var category: String = str(event.get("category", ""))
		_increment(corporate_category_counts, category)
		if category in ["corporate_action_filing", "corporate_action_resolution", "corporate_action_execution"]:
			counters["corporate_action_hard_events"] = int(counters.get("corporate_action_hard_events", 0)) + 1
		elif category in ["corporate_action_rumor", "corporate_action_speculation", "corporate_action_clarification"]:
			counters["corporate_action_rumor_soft_events"] = int(counters.get("corporate_action_rumor_soft_events", 0)) + 1

	for event_value in day_result.get("started_special_events", []):
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_value
		counters["special_events"] = int(counters.get("special_events", 0)) + 1
		if str(event.get("shock_class", "")) == "policy_parody" or str(event.get("event_id", "")).begins_with("policy_"):
			counters["policy_parody_events"] = int(counters.get("policy_parody_events", 0)) + 1
		_count_event(event, event_id_counts, event_family_counts)
		_increment(special_event_id_counts, str(event.get("event_id", "")))

	var dirty_tip_offers: Array = day_result.get("dirty_tip_offers", [])
	counters["dirty_tip_offers"] = int(counters.get("dirty_tip_offers", 0)) + dirty_tip_offers.size()
	for result_value in day_result.get("dirty_tip_results", []):
		if typeof(result_value) != TYPE_DICTIONARY:
			continue
		var result: Dictionary = result_value
		counters["dirty_tip_results"] = int(counters.get("dirty_tip_results", 0)) + 1
		if str(result.get("status", "")) == "caught":
			counters["dirty_tip_caught"] = int(counters.get("dirty_tip_caught", 0)) + 1
			counters["legal_hold_starts"] = int(counters.get("legal_hold_starts", 0)) + 1
		elif str(result.get("status", "")) == "clean":
			counters["dirty_tip_clean"] = int(counters.get("dirty_tip_clean", 0)) + 1

	var life_legal: Dictionary = day_result.get("life_legal", {})
	if not life_legal.is_empty() and bool(life_legal.get("legal_hold_active", false)):
		counters["legal_hold_days"] = int(counters.get("legal_hold_days", 0)) + 1
	var life_wellbeing: Dictionary = day_result.get("life_wellbeing", {})
	if not life_wellbeing.is_empty():
		if bool(life_wellbeing.get("hospital_started", false)):
			counters["hospital_starts"] = int(counters.get("hospital_starts", 0)) + 1
		if int(life_wellbeing.get("hospital_days_remaining", 0)) > 0:
			counters["hospital_days"] = int(counters.get("hospital_days", 0)) + 1
	if not day_result.get("life_obligation", {}).is_empty():
		counters["life_obligations"] = int(counters.get("life_obligations", 0)) + 1
	if not day_result.get("life_loan_payment", {}).is_empty():
		counters["life_loan_payments"] = int(counters.get("life_loan_payments", 0)) + 1
	if not day_result.get("bankruptcy", {}).is_empty():
		counters["bankruptcies"] = int(counters.get("bankruptcies", 0)) + 1
	counters["network_request_results"] = int(counters.get("network_request_results", 0)) + day_result.get("network_request_results", []).size()
	counters["network_tip_results"] = int(counters.get("network_tip_results", 0)) + day_result.get("network_tip_results", []).size()
	counters["life_development_results"] = int(counters.get("life_development_results", 0)) + day_result.get("life_development_results", []).size()


func _collect_quarterly_filing_counts(last_day_results: Dictionary, counters: Dictionary) -> void:
	var filings: Array = last_day_results.get("quarterly_statement_filings", [])
	counters["quarterly_filings_applied"] = int(counters.get("quarterly_filings_applied", 0)) + filings.size()


func _collect_campaign_state(campaign_tracker: Dictionary) -> void:
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = RunState.get_company(company_id)
		var campaign_value = runtime.get("gorengan_campaign", {})
		if typeof(campaign_value) != TYPE_DICTIONARY:
			continue
		var campaign: Dictionary = campaign_value
		if campaign.is_empty():
			continue
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		var tracker: Dictionary = campaign_tracker.get(company_id, {})
		if tracker.is_empty():
			tracker = {
				"company_id": company_id,
				"ticker": str(definition.get("ticker", company_id.to_upper())),
				"name": str(definition.get("name", "")),
				"tier": str(campaign.get("tier", "common")),
				"start_day_index": int(campaign.get("start_day_index", RunState.day_index)),
				"start_price": float(campaign.get("start_price", runtime.get("starting_price", 0.0))),
				"target_return_pct": float(campaign.get("target_return_pct", 0.0)) * 100.0,
				"required_hard_catalysts": int(campaign.get("required_hard_catalysts", 0)),
				"days_active": 0,
				"max_realized_return_pct": -100.0,
				"last_realized_return_pct": 0.0,
				"phase": "",
				"wave": "",
				"phases_seen": [],
				"waves_seen": [],
				"max_hard_catalysts": 0,
				"max_soft_catalysts": 0,
				"uma_issued": false,
				"suspension_seen": false,
				"split_required": false,
				"split_scheduled": false,
				"split_executed": false,
				"gate_locked": false,
				"next_needed_beat": ""
			}
		tracker["days_active"] = int(tracker.get("days_active", 0)) + 1
		tracker["phase"] = str(campaign.get("phase", ""))
		tracker["wave"] = str(campaign.get("wave", ""))
		tracker["last_realized_return_pct"] = float(campaign.get("realized_return_pct", 0.0)) * 100.0
		tracker["max_realized_return_pct"] = max(float(tracker.get("max_realized_return_pct", -100.0)), float(tracker.get("last_realized_return_pct", 0.0)))
		tracker["max_hard_catalysts"] = max(int(tracker.get("max_hard_catalysts", 0)), int(campaign.get("hard_catalyst_count", 0)))
		tracker["max_soft_catalysts"] = max(int(tracker.get("max_soft_catalysts", 0)), int(campaign.get("soft_catalyst_count", 0)))
		tracker["uma_issued"] = bool(tracker.get("uma_issued", false)) or bool(campaign.get("uma_issued", false))
		tracker["suspension_seen"] = bool(tracker.get("suspension_seen", false)) or bool(campaign.get("suspension_seen", false))
		tracker["split_required"] = bool(tracker.get("split_required", false)) or bool(campaign.get("split_required", false))
		tracker["split_scheduled"] = bool(tracker.get("split_scheduled", false)) or bool(campaign.get("split_scheduled", false))
		tracker["split_executed"] = bool(tracker.get("split_executed", false)) or bool(campaign.get("split_executed", false))
		tracker["gate_locked"] = bool(campaign.get("gate_locked", false))
		tracker["next_needed_beat"] = str(campaign.get("next_needed_beat", ""))
		_append_unique(tracker["phases_seen"], str(campaign.get("phase", "")))
		_append_unique(tracker["waves_seen"], str(campaign.get("wave", "")))
		campaign_tracker[company_id] = tracker


func _collect_abnormal_move_counts(counters: Dictionary) -> void:
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = RunState.get_company(company_id)
		var abnormal_value = runtime.get("abnormal_move_context", {})
		if typeof(abnormal_value) != TYPE_DICTIONARY:
			continue
		var abnormal: Dictionary = abnormal_value
		if abnormal.is_empty() or not bool(abnormal.get("active", false)):
			continue
		counters["abnormal_move_stock_days"] = int(counters.get("abnormal_move_stock_days", 0)) + 1
		counters["abnormal_move_max_green_streak"] = max(
			int(counters.get("abnormal_move_max_green_streak", 0)),
			int(abnormal.get("green_limit_streak", 0))
		)
		if bool(abnormal.get("uma_issued", false)):
			counters["abnormal_move_uma_stock_days"] = int(counters.get("abnormal_move_uma_stock_days", 0)) + 1
		if bool(abnormal.get("suspension_seen", false)):
			counters["abnormal_move_suspension_stock_days"] = int(counters.get("abnormal_move_suspension_stock_days", 0)) + 1
		if bool(abnormal.get("split_required", false)):
			counters["abnormal_move_split_required_stock_days"] = int(counters.get("abnormal_move_split_required_stock_days", 0)) + 1
		var flags: Array = abnormal.get("flags", []) if typeof(abnormal.get("flags", [])) == TYPE_ARRAY else []
		if flags.has("abnormal_distribution_guard") or flags.has("abnormal_extreme_without_split"):
			counters["abnormal_move_distribution_guard_stock_days"] = int(counters.get("abnormal_move_distribution_guard_stock_days", 0)) + 1
		if flags.has("abnormal_deep_drawdown_stabilizer") or flags.has("abnormal_floor_stabilizer") or flags.has("abnormal_floor_board"):
			counters["abnormal_move_floor_stabilizer_stock_days"] = int(counters.get("abnormal_move_floor_stabilizer_stock_days", 0)) + 1
		if flags.has("abnormal_floor_turnaround_candidate") or str(abnormal.get("floor_status", "")) == "turnaround_candidate":
			counters["floor_turnaround_candidate_stock_days"] = int(counters.get("floor_turnaround_candidate_stock_days", 0)) + 1
		if flags.has("abnormal_floor_zombie") or str(abnormal.get("floor_status", "")) == "floor_zombie":
			counters["floor_zombie_stock_days"] = int(counters.get("floor_zombie_stock_days", 0)) + 1
		var latest_bar: Dictionary = _latest_bar(runtime)
		if bool(latest_bar.get("abnormal_move_guarded", false)):
			counters["abnormal_move_guarded_bars"] = int(counters.get("abnormal_move_guarded_bars", 0)) + 1


func _build_campaign_report(campaign_tracker: Dictionary) -> Dictionary:
	var rows: Array = []
	var by_tier: Dictionary = {}
	var successful_count: int = 0
	var dump_seen_count: int = 0
	for tracker_value in campaign_tracker.values():
		if typeof(tracker_value) != TYPE_DICTIONARY:
			continue
		var tracker: Dictionary = tracker_value.duplicate(true)
		var tier: String = str(tracker.get("tier", "common"))
		if not by_tier.has(tier):
			by_tier[tier] = {"started": 0, "successful": 0, "dump_seen": 0}
		by_tier[tier]["started"] = int(by_tier[tier].get("started", 0)) + 1
		var phases_seen: Array = tracker.get("phases_seen", [])
		var dump_seen: bool = false
		for phase_value in phases_seen:
			if DUMP_PHASES.has(str(phase_value)):
				dump_seen = true
				break
		var successful: bool = float(tracker.get("max_realized_return_pct", -100.0)) >= 200.0 and dump_seen
		tracker["successful"] = successful
		tracker["dump_seen"] = dump_seen
		if successful:
			successful_count += 1
			by_tier[tier]["successful"] = int(by_tier[tier].get("successful", 0)) + 1
		if dump_seen:
			dump_seen_count += 1
			by_tier[tier]["dump_seen"] = int(by_tier[tier].get("dump_seen", 0)) + 1
		rows.append(tracker)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("max_realized_return_pct", -100.0)) > float(b.get("max_realized_return_pct", -100.0))
	)
	return {
		"started": rows.size(),
		"successful_executed": successful_count,
		"dump_seen": dump_seen_count,
		"by_tier": by_tier,
		"top_campaigns": rows.slice(0, min(rows.size(), 8))
	}


func _build_stock_report(initial_prices: Dictionary) -> Dictionary:
	var rows: Array = []
	var returns: Array = []
	var decliner_final_prices: Array = []
	var advancers: int = 0
	var decliners: int = 0
	var final_at_floor: int = 0
	var floor_turnaround_candidates: int = 0
	var floor_zombies: int = 0
	var over_200: int = 0
	var over_800: int = 0
	var over_1000: int = 0
	var over_100k: int = 0
	var over_1m: int = 0
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = RunState.get_company(company_id)
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		var start_price: float = max(float(initial_prices.get(company_id, runtime.get("starting_price", 0.0))), 1.0)
		var final_price: float = float(runtime.get("current_price", start_price))
		var return_pct: float = ((final_price - start_price) / start_price) * 100.0
		var price_history: Array = runtime.get("price_history", [])
		var high_price: float = _max_price(price_history, start_price)
		var low_price: float = _min_price(price_history, start_price)
		var high_return_pct: float = ((high_price - start_price) / start_price) * 100.0
		var final_from_high_pct: float = ((final_price - high_price) / high_price) * 100.0 if high_price > 0.0 else 0.0
		var latest_bar: Dictionary = _latest_bar(runtime)
		var campaign: Dictionary = runtime.get("gorengan_campaign", {}) if typeof(runtime.get("gorengan_campaign", {})) == TYPE_DICTIONARY else {}
		var abnormal: Dictionary = runtime.get("abnormal_move_context", {}) if typeof(runtime.get("abnormal_move_context", {})) == TYPE_DICTIONARY else {}
		var financials: Dictionary = definition.get("financials", {}) if typeof(definition.get("financials", {})) == TYPE_DICTIONARY else {}
		var statement_snapshot: Dictionary = definition.get("financial_statement_snapshot", {}) if typeof(definition.get("financial_statement_snapshot", {})) == TYPE_DICTIONARY else {}
		var row: Dictionary = {
			"company_id": company_id,
			"ticker": str(definition.get("ticker", company_id.to_upper())),
			"name": str(definition.get("name", "")),
			"sector_id": str(definition.get("sector_id", "")),
			"start_price": start_price,
			"final_price": final_price,
			"return_pct": return_pct,
			"high_price": high_price,
			"low_price": low_price,
			"high_return_pct": high_return_pct,
			"final_from_high_pct": final_from_high_pct,
			"last_day_value": float(latest_bar.get("value", 0.0)),
			"last_daily_change_pct": float(runtime.get("daily_change_pct", 0.0)) * 100.0,
			"gorengan_tier": str(campaign.get("tier", "")),
			"gorengan_phase": str(campaign.get("phase", "")),
			"gorengan_wave": str(campaign.get("wave", "")),
			"abnormal_phase": str(abnormal.get("phase", "")),
			"abnormal_next_needed_beat": str(abnormal.get("next_needed_beat", "")),
			"floor_days": int(abnormal.get("floor_days", 0)),
			"floor_status": str(abnormal.get("floor_status", "")),
			"floor_turnaround_score": float(abnormal.get("floor_turnaround_score", 0.0)),
			"floor_turnaround_eligible": bool(abnormal.get("floor_turnaround_eligible", false)),
			"latest_statement_period": str(financials.get("latest_statement_period", statement_snapshot.get("statement_period_label", ""))),
			"revenue_growth_yoy": float(financials.get("revenue_growth_yoy", 0.0)),
			"earnings_growth_yoy": float(financials.get("earnings_growth_yoy", 0.0)),
			"net_profit_margin": float(financials.get("net_profit_margin", 0.0)),
			"quality_score": int(definition.get("quality_score", 0)),
			"growth_score": int(definition.get("growth_score", 0)),
			"risk_score": int(definition.get("risk_score", 0))
		}
		rows.append(row)
		returns.append(return_pct)
		if return_pct > 0.0:
			advancers += 1
		elif return_pct < 0.0:
			decliners += 1
			decliner_final_prices.append(final_price)
		if final_price <= 50.001:
			final_at_floor += 1
		if str(abnormal.get("floor_status", "")) == "turnaround_candidate":
			floor_turnaround_candidates += 1
		elif str(abnormal.get("floor_status", "")) == "floor_zombie":
			floor_zombies += 1
		if return_pct >= 200.0:
			over_200 += 1
		if return_pct >= 800.0:
			over_800 += 1
		if return_pct >= 1000.0:
			over_1000 += 1
		if final_price >= 100000.0:
			over_100k += 1
		if final_price >= 1000000.0:
			over_1m += 1
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("return_pct", 0.0)) > float(b.get("return_pct", 0.0))
	)
	return {
		"advancers": advancers,
		"decliners": decliners,
		"flat": max(rows.size() - advancers - decliners, 0),
		"average_return_pct": _average(returns),
		"median_return_pct": _median(returns),
		"decliner_average_final_price": _average(decliner_final_prices),
		"decliner_median_final_price": _median(decliner_final_prices),
		"final_price_at_floor_count": final_at_floor,
		"floor_turnaround_candidate_count": floor_turnaround_candidates,
		"floor_zombie_count": floor_zombies,
		"over_200_pct_count": over_200,
		"over_800_pct_count": over_800,
		"over_1000_pct_count": over_1000,
		"final_price_over_100k_count": over_100k,
		"final_price_over_1m_count": over_1m,
		"best_stock": rows[0] if not rows.is_empty() else {},
		"top_10": rows.slice(0, min(rows.size(), 10)),
		"bottom_5": rows.slice(max(rows.size() - 5, 0), rows.size())
	}


func _default_price_exposure_tracker() -> Dictionary:
	return {
		"active_stock_days": 0,
		"positive_drift_days": 0,
		"negative_drift_days": 0,
		"flat_drift_days": 0,
		"total_drift": 0.0,
		"total_abs_drift": 0.0,
		"total_confidence": 0.0,
		"total_volatility_multiplier": 0.0,
		"total_volume_multiplier": 0.0,
		"by_company": {}
	}


func _collect_price_exposure_state(tracker: Dictionary) -> void:
	var by_company: Dictionary = tracker.get("by_company", {})
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = RunState.get_company(company_id)
		var context_value = runtime.get("price_exposure_context", {})
		if typeof(context_value) != TYPE_DICTIONARY:
			continue
		var context: Dictionary = context_value
		var rows: Array = context.get("exposure_rows", []) if typeof(context.get("exposure_rows", [])) == TYPE_ARRAY else []
		if rows.is_empty():
			continue
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		var drift: float = clamp(float(context.get("exposure_drift_adjustment", 0.0)), -0.004, 0.004)
		var abs_drift: float = absf(drift)
		var confidence: float = clamp(float(context.get("exposure_confidence", 0.0)), 0.0, 1.0)
		var volatility_multiplier: float = clamp(float(context.get("exposure_volatility_multiplier", 1.0)), 0.90, 1.16)
		var volume_multiplier: float = clamp(float(context.get("exposure_volume_multiplier", 1.0)), 0.92, 1.22)
		tracker["active_stock_days"] = int(tracker.get("active_stock_days", 0)) + 1
		tracker["total_drift"] = float(tracker.get("total_drift", 0.0)) + drift
		tracker["total_abs_drift"] = float(tracker.get("total_abs_drift", 0.0)) + abs_drift
		tracker["total_confidence"] = float(tracker.get("total_confidence", 0.0)) + confidence
		tracker["total_volatility_multiplier"] = float(tracker.get("total_volatility_multiplier", 0.0)) + volatility_multiplier
		tracker["total_volume_multiplier"] = float(tracker.get("total_volume_multiplier", 0.0)) + volume_multiplier
		if drift > 0.000001:
			tracker["positive_drift_days"] = int(tracker.get("positive_drift_days", 0)) + 1
		elif drift < -0.000001:
			tracker["negative_drift_days"] = int(tracker.get("negative_drift_days", 0)) + 1
		else:
			tracker["flat_drift_days"] = int(tracker.get("flat_drift_days", 0)) + 1

		var company_row: Dictionary = by_company.get(company_id, {})
		if company_row.is_empty():
			company_row = {
				"company_id": company_id,
				"ticker": str(definition.get("ticker", company_id.to_upper())),
				"name": str(definition.get("name", "")),
				"sector_id": str(definition.get("sector_id", "")),
				"days": 0,
				"positive_days": 0,
				"negative_days": 0,
				"total_drift": 0.0,
				"total_abs_drift": 0.0,
				"total_confidence": 0.0,
				"max_abs_drift": 0.0,
				"last_summary": "",
				"last_rows": []
			}
		company_row["days"] = int(company_row.get("days", 0)) + 1
		company_row["total_drift"] = float(company_row.get("total_drift", 0.0)) + drift
		company_row["total_abs_drift"] = float(company_row.get("total_abs_drift", 0.0)) + abs_drift
		company_row["total_confidence"] = float(company_row.get("total_confidence", 0.0)) + confidence
		company_row["max_abs_drift"] = max(float(company_row.get("max_abs_drift", 0.0)), abs_drift)
		company_row["last_summary"] = str(context.get("exposure_summary", ""))
		company_row["last_rows"] = _compact_exposure_rows(rows, 3)
		if drift > 0.000001:
			company_row["positive_days"] = int(company_row.get("positive_days", 0)) + 1
		elif drift < -0.000001:
			company_row["negative_days"] = int(company_row.get("negative_days", 0)) + 1
		by_company[company_id] = company_row
	tracker["by_company"] = by_company


func _build_price_exposure_report(tracker: Dictionary, initial_prices: Dictionary) -> Dictionary:
	var active_stock_days: int = int(tracker.get("active_stock_days", 0))
	var company_rows: Array = []
	var positive_exposure_returns: Array = []
	var negative_exposure_returns: Array = []
	var by_company: Dictionary = tracker.get("by_company", {})
	for company_row_value in by_company.values():
		if typeof(company_row_value) != TYPE_DICTIONARY:
			continue
		var company_row: Dictionary = company_row_value.duplicate(true)
		var days: int = max(int(company_row.get("days", 0)), 1)
		var company_id: String = str(company_row.get("company_id", ""))
		var runtime: Dictionary = RunState.get_company(company_id)
		var start_price: float = max(float(initial_prices.get(company_id, runtime.get("starting_price", 0.0))), 1.0)
		var final_price: float = float(runtime.get("current_price", start_price))
		var return_pct: float = ((final_price - start_price) / start_price) * 100.0
		var avg_drift: float = float(company_row.get("total_drift", 0.0)) / float(days)
		company_row["avg_drift_bps"] = avg_drift * 10000.0
		company_row["avg_abs_drift_bps"] = (float(company_row.get("total_abs_drift", 0.0)) / float(days)) * 10000.0
		company_row["avg_confidence"] = float(company_row.get("total_confidence", 0.0)) / float(days)
		company_row["final_return_pct"] = return_pct
		company_row["final_price"] = final_price
		company_rows.append(company_row)
		if avg_drift > 0.0:
			positive_exposure_returns.append(return_pct)
		elif avg_drift < 0.0:
			negative_exposure_returns.append(return_pct)

	var top_tailwinds: Array = company_rows.duplicate(true)
	top_tailwinds.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_score: float = float(left.get("avg_drift_bps", 0.0))
		var right_score: float = float(right.get("avg_drift_bps", 0.0))
		if is_equal_approx(left_score, right_score):
			return str(left.get("company_id", "")) < str(right.get("company_id", ""))
		return left_score > right_score
	)
	var top_headwinds: Array = company_rows.duplicate(true)
	top_headwinds.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_score: float = float(left.get("avg_drift_bps", 0.0))
		var right_score: float = float(right.get("avg_drift_bps", 0.0))
		if is_equal_approx(left_score, right_score):
			return str(left.get("company_id", "")) < str(right.get("company_id", ""))
		return left_score < right_score
	)
	var highest_confidence: Array = company_rows.duplicate(true)
	highest_confidence.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_score: float = float(left.get("avg_confidence", 0.0))
		var right_score: float = float(right.get("avg_confidence", 0.0))
		if is_equal_approx(left_score, right_score):
			return str(left.get("company_id", "")) < str(right.get("company_id", ""))
		return left_score > right_score
	)

	return {
		"active_stock_days": active_stock_days,
		"positive_drift_days": int(tracker.get("positive_drift_days", 0)),
		"negative_drift_days": int(tracker.get("negative_drift_days", 0)),
		"flat_drift_days": int(tracker.get("flat_drift_days", 0)),
		"avg_drift_bps": _safe_average_total(float(tracker.get("total_drift", 0.0)) * 10000.0, active_stock_days),
		"avg_abs_drift_bps": _safe_average_total(float(tracker.get("total_abs_drift", 0.0)) * 10000.0, active_stock_days),
		"avg_confidence": _safe_average_total(float(tracker.get("total_confidence", 0.0)), active_stock_days),
		"avg_volatility_multiplier": _safe_average_total(float(tracker.get("total_volatility_multiplier", 0.0)), active_stock_days),
		"avg_volume_multiplier": _safe_average_total(float(tracker.get("total_volume_multiplier", 0.0)), active_stock_days),
		"positive_exposure_avg_return_pct": _average(positive_exposure_returns),
		"negative_exposure_avg_return_pct": _average(negative_exposure_returns),
		"top_tailwinds": _trim_company_rows(top_tailwinds, 8),
		"top_headwinds": _trim_company_rows(top_headwinds, 8),
		"highest_confidence": _trim_company_rows(highest_confidence, 8)
	}


func _compact_exposure_rows(rows: Array, limit: int) -> Array:
	var output: Array = []
	for row_value in rows:
		if output.size() >= limit:
			break
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		output.append({
			"source_type": str(row.get("source_type", "")),
			"id": str(row.get("id", "")),
			"label": str(row.get("label", "")),
			"exposure": float(row.get("exposure", 0.0)),
			"signal": float(row.get("signal", 0.0)),
			"contribution": float(row.get("contribution", 0.0))
		})
	return output


func _trim_company_rows(rows: Array, limit: int) -> Array:
	var output: Array = []
	for row_value in rows:
		if output.size() >= limit:
			break
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		output.append({
			"company_id": str(row.get("company_id", "")),
			"ticker": str(row.get("ticker", "")),
			"name": str(row.get("name", "")),
			"sector_id": str(row.get("sector_id", "")),
			"days": int(row.get("days", 0)),
			"avg_drift_bps": float(row.get("avg_drift_bps", 0.0)),
			"avg_abs_drift_bps": float(row.get("avg_abs_drift_bps", 0.0)),
			"avg_confidence": float(row.get("avg_confidence", 0.0)),
			"final_return_pct": float(row.get("final_return_pct", 0.0)),
			"final_price": float(row.get("final_price", 0.0)),
			"last_summary": str(row.get("last_summary", "")),
			"last_rows": row.get("last_rows", []).duplicate(true)
		})
	return output


func _daily_value_snapshot() -> Dictionary:
	var market_value: float = 0.0
	var gorengan_value: float = 0.0
	for company_id_value in RunState.company_order:
		var runtime: Dictionary = RunState.get_company(str(company_id_value))
		var latest_bar: Dictionary = _latest_bar(runtime)
		var value: float = max(float(latest_bar.get("value", 0.0)), 0.0)
		market_value += value
		var campaign_value = runtime.get("gorengan_campaign", {})
		if typeof(campaign_value) == TYPE_DICTIONARY and not Dictionary(campaign_value).is_empty():
			gorengan_value += value
	return {
		"market_value": market_value,
		"gorengan_value": gorengan_value
	}


func _portfolio_report() -> Dictionary:
	var holdings: Dictionary = RunState.player_portfolio.get("holdings", {})
	return {
		"cash": float(RunState.player_portfolio.get("cash", 0.0)),
		"market_value": RunState.get_portfolio_market_value(),
		"equity": RunState.get_total_equity(),
		"holdings_count": holdings.size(),
		"realized_pnl": float(RunState.player_portfolio.get("realized_pnl", 0.0))
	}


func _compact_audit_report(report: Dictionary) -> Dictionary:
	if not bool(report.get("success", false)):
		return report
	var stocks: Dictionary = report.get("stocks", {})
	var events: Dictionary = report.get("events", {})
	var counters: Dictionary = events.get("counters", {})
	var bottom_rows: Array = stocks.get("bottom_5", [])
	var worst_stock: Dictionary = {}
	if not bottom_rows.is_empty() and typeof(bottom_rows[bottom_rows.size() - 1]) == TYPE_DICTIONARY:
		worst_stock = bottom_rows[bottom_rows.size() - 1]
	var price_exposure: Dictionary = report.get("price_exposure", {})
	return {
		"success": true,
		"seed": int(report.get("seed", 0)),
		"difficulty_id": str(report.get("difficulty_id", "")),
		"difficulty_label": str(report.get("difficulty_label", "")),
		"use_company_universe_catalog": bool(report.get("use_company_universe_catalog", false)),
		"requested_trading_days": int(report.get("requested_trading_days", 0)),
		"days_completed": int(report.get("days_completed", 0)),
		"final_day_index": int(report.get("final_day_index", 0)),
		"final_trade_date": report.get("final_trade_date", {}),
		"company_count": int(report.get("company_count", 0)),
		"audit_elapsed_msec": float(report.get("audit_elapsed_msec", 0.0)),
		"portfolio": report.get("portfolio", {}),
		"stocks": {
			"advancers": int(stocks.get("advancers", 0)),
			"decliners": int(stocks.get("decliners", 0)),
			"flat": int(stocks.get("flat", 0)),
			"average_return_pct": float(stocks.get("average_return_pct", 0.0)),
			"median_return_pct": float(stocks.get("median_return_pct", 0.0)),
			"decliner_average_final_price": float(stocks.get("decliner_average_final_price", 0.0)),
			"decliner_median_final_price": float(stocks.get("decliner_median_final_price", 0.0)),
			"final_price_at_floor_count": int(stocks.get("final_price_at_floor_count", 0)),
			"floor_turnaround_candidate_count": int(stocks.get("floor_turnaround_candidate_count", 0)),
			"floor_zombie_count": int(stocks.get("floor_zombie_count", 0)),
			"over_200_pct_count": int(stocks.get("over_200_pct_count", 0)),
			"over_800_pct_count": int(stocks.get("over_800_pct_count", 0)),
			"over_1000_pct_count": int(stocks.get("over_1000_pct_count", 0)),
			"final_price_over_100k_count": int(stocks.get("final_price_over_100k_count", 0)),
			"final_price_over_1m_count": int(stocks.get("final_price_over_1m_count", 0)),
			"best_stock": _compact_stock_row(stocks.get("best_stock", {})),
			"worst_stock": _compact_stock_row(worst_stock),
			"top_5": _compact_stock_rows(stocks.get("top_10", []), 5),
			"bottom_5": _compact_stock_rows(bottom_rows, 5)
		},
		"events": {
			"counters": counters,
			"event_family_counts": events.get("event_family_counts", {}),
			"corporate_category_counts": events.get("corporate_category_counts", {}),
			"special_event_id_counts": events.get("special_event_id_counts", {}),
			"top_event_id_counts": _top_count_rows(events.get("event_id_counts", {}), 12)
		},
		"gorengan_campaigns": _compact_gorengan_report(report.get("gorengan_campaigns", {})),
		"price_exposure": {
			"active_stock_days": int(price_exposure.get("active_stock_days", 0)),
			"positive_drift_days": int(price_exposure.get("positive_drift_days", 0)),
			"negative_drift_days": int(price_exposure.get("negative_drift_days", 0)),
			"flat_drift_days": int(price_exposure.get("flat_drift_days", 0)),
			"avg_drift_bps": float(price_exposure.get("avg_drift_bps", 0.0)),
			"avg_abs_drift_bps": float(price_exposure.get("avg_abs_drift_bps", 0.0)),
			"avg_confidence": float(price_exposure.get("avg_confidence", 0.0)),
			"avg_volatility_multiplier": float(price_exposure.get("avg_volatility_multiplier", 0.0)),
			"avg_volume_multiplier": float(price_exposure.get("avg_volume_multiplier", 0.0)),
			"positive_exposure_avg_return_pct": float(price_exposure.get("positive_exposure_avg_return_pct", 0.0)),
			"negative_exposure_avg_return_pct": float(price_exposure.get("negative_exposure_avg_return_pct", 0.0)),
			"top_tailwinds": _compact_exposure_company_rows(price_exposure.get("top_tailwinds", []), 5),
			"top_headwinds": _compact_exposure_company_rows(price_exposure.get("top_headwinds", []), 5),
			"highest_confidence": _compact_exposure_company_rows(price_exposure.get("highest_confidence", []), 5)
		},
		"turnover": report.get("turnover", {})
	}


func _compact_stock_rows(rows: Array, limit: int) -> Array:
	var output: Array = []
	for row_value in rows:
		if output.size() >= limit:
			break
		if typeof(row_value) == TYPE_DICTIONARY:
			output.append(_compact_stock_row(row_value))
	return output


func _compact_stock_row(row_value) -> Dictionary:
	if typeof(row_value) != TYPE_DICTIONARY:
		return {}
	var row: Dictionary = row_value
	return {
		"company_id": str(row.get("company_id", "")),
		"ticker": str(row.get("ticker", "")),
		"name": str(row.get("name", "")),
		"sector_id": str(row.get("sector_id", "")),
		"start_price": float(row.get("start_price", 0.0)),
		"final_price": float(row.get("final_price", 0.0)),
		"return_pct": float(row.get("return_pct", 0.0)),
		"high_return_pct": float(row.get("high_return_pct", 0.0)),
		"final_from_high_pct": float(row.get("final_from_high_pct", 0.0)),
		"last_daily_change_pct": float(row.get("last_daily_change_pct", 0.0)),
		"last_day_value": float(row.get("last_day_value", 0.0)),
		"gorengan_tier": str(row.get("gorengan_tier", "")),
		"gorengan_phase": str(row.get("gorengan_phase", "")),
		"gorengan_wave": str(row.get("gorengan_wave", "")),
		"abnormal_phase": str(row.get("abnormal_phase", "")),
		"floor_status": str(row.get("floor_status", "")),
		"latest_statement_period": str(row.get("latest_statement_period", "")),
		"quality_score": int(row.get("quality_score", 0)),
		"growth_score": int(row.get("growth_score", 0)),
		"risk_score": int(row.get("risk_score", 0))
	}


func _compact_exposure_company_rows(rows: Array, limit: int) -> Array:
	var output: Array = []
	for row_value in rows:
		if output.size() >= limit:
			break
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		output.append({
			"company_id": str(row.get("company_id", "")),
			"ticker": str(row.get("ticker", "")),
			"name": str(row.get("name", "")),
			"sector_id": str(row.get("sector_id", "")),
			"days": int(row.get("days", 0)),
			"avg_drift_bps": float(row.get("avg_drift_bps", 0.0)),
			"avg_abs_drift_bps": float(row.get("avg_abs_drift_bps", 0.0)),
			"avg_confidence": float(row.get("avg_confidence", 0.0)),
			"final_return_pct": float(row.get("final_return_pct", 0.0)),
			"final_price": float(row.get("final_price", 0.0)),
			"last_summary": str(row.get("last_summary", ""))
		})
	return output


func _compact_gorengan_report(report_value) -> Dictionary:
	if typeof(report_value) != TYPE_DICTIONARY:
		return {}
	var report: Dictionary = report_value
	var top_campaigns: Array = []
	for campaign_value in report.get("top_campaigns", []):
		if top_campaigns.size() >= 5:
			break
		if typeof(campaign_value) != TYPE_DICTIONARY:
			continue
		var campaign: Dictionary = campaign_value
		top_campaigns.append({
			"company_id": str(campaign.get("company_id", "")),
			"ticker": str(campaign.get("ticker", "")),
			"name": str(campaign.get("name", "")),
			"tier": str(campaign.get("tier", "")),
			"phase": str(campaign.get("phase", "")),
			"wave": str(campaign.get("wave", "")),
			"days_active": int(campaign.get("days_active", 0)),
			"max_realized_return_pct": float(campaign.get("max_realized_return_pct", 0.0)),
			"last_realized_return_pct": float(campaign.get("last_realized_return_pct", 0.0)),
			"target_return_pct": float(campaign.get("target_return_pct", 0.0)),
			"required_hard_catalysts": int(campaign.get("required_hard_catalysts", 0)),
			"max_hard_catalysts": int(campaign.get("max_hard_catalysts", 0)),
			"max_soft_catalysts": int(campaign.get("max_soft_catalysts", 0)),
			"dump_seen": bool(campaign.get("dump_seen", false)),
			"successful": bool(campaign.get("successful", false))
		})
	return {
		"started": int(report.get("started", 0)),
		"successful_executed": int(report.get("successful_executed", 0)),
		"dump_seen": int(report.get("dump_seen", 0)),
		"by_tier": report.get("by_tier", {}),
		"top_campaigns": top_campaigns
	}


func _top_count_rows(counts_value, limit: int) -> Array:
	if typeof(counts_value) != TYPE_DICTIONARY:
		return []
	var rows: Array = []
	for key in Dictionary(counts_value).keys():
		rows.append({"id": str(key), "count": int(Dictionary(counts_value).get(key, 0))})
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_count: int = int(left.get("count", 0))
		var right_count: int = int(right.get("count", 0))
		if left_count == right_count:
			return str(left.get("id", "")) < str(right.get("id", ""))
		return left_count > right_count
	)
	return rows.slice(0, min(rows.size(), limit))


func _latest_bar(runtime: Dictionary) -> Dictionary:
	var bars: Array = runtime.get("price_bars", [])
	if bars.is_empty() or typeof(bars[bars.size() - 1]) != TYPE_DICTIONARY:
		return {}
	return bars[bars.size() - 1]


func _initial_price_lookup() -> Dictionary:
	var prices: Dictionary = {}
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = RunState.get_company(company_id)
		prices[company_id] = float(runtime.get("starting_price", runtime.get("current_price", 0.0)))
	return prices


func _maintain_audit_cash_floor(cash_floor: float) -> void:
	var portfolio: Dictionary = RunState.player_portfolio.duplicate(true)
	portfolio["cash"] = max(float(portfolio.get("cash", 0.0)), cash_floor)
	RunState.player_portfolio = portfolio


func _count_event_array(
	events: Array,
	counter_key: String,
	counters: Dictionary,
	event_id_counts: Dictionary,
	event_family_counts: Dictionary
) -> void:
	for event_value in events:
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		counters[counter_key] = int(counters.get(counter_key, 0)) + 1
		_count_event(event_value, event_id_counts, event_family_counts)


func _count_event(event_value: Dictionary, event_id_counts: Dictionary, event_family_counts: Dictionary) -> void:
	_increment(event_id_counts, str(event_value.get("event_id", "")))
	_increment(event_family_counts, str(event_value.get("event_family", "")))


func _increment(counts: Dictionary, key: String) -> void:
	var resolved_key: String = key
	if resolved_key.is_empty():
		resolved_key = "<blank>"
	counts[resolved_key] = int(counts.get(resolved_key, 0)) + 1


func _append_unique(values: Array, value: String) -> void:
	if value.is_empty() or values.has(value):
		return
	values.append(value)


func _arg_string(args: Array, key: String, fallback: String) -> String:
	var index: int = args.find(key)
	if index >= 0 and index + 1 < args.size():
		var value: String = str(args[index + 1]).strip_edges()
		if not value.is_empty():
			return value
	for arg_value in args:
		var arg: String = str(arg_value)
		if arg.begins_with("%s=" % key):
			var value: String = arg.substr(key.length() + 1).strip_edges()
			if not value.is_empty():
				return value
	return fallback


func _arg_int(args: Array, key: String, fallback: int) -> int:
	return int(_arg_string(args, key, str(fallback)))


func _arg_bool(args: Array, key: String, fallback: bool) -> bool:
	var index: int = args.find(key)
	if index >= 0:
		if index + 1 < args.size():
			var next_value: String = str(args[index + 1]).strip_edges().to_lower()
			if next_value in ["true", "1", "yes", "on"]:
				return true
			if next_value in ["false", "0", "no", "off"]:
				return false
		return true
	for arg_value in args:
		var arg: String = str(arg_value)
		if arg.begins_with("%s=" % key):
			var value: String = arg.substr(key.length() + 1).strip_edges().to_lower()
			if value in ["true", "1", "yes", "on"]:
				return true
			if value in ["false", "0", "no", "off"]:
				return false
	return fallback


func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())


func _safe_average_total(total: float, count: int) -> float:
	if count <= 0:
		return 0.0
	return total / float(count)


func _median(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var sorted_values: Array = values.duplicate()
	sorted_values.sort()
	var middle: int = sorted_values.size() / 2
	if sorted_values.size() % 2 == 0:
		return (float(sorted_values[middle - 1]) + float(sorted_values[middle])) * 0.5
	return float(sorted_values[middle])


func _max_price(values: Array, fallback: float) -> float:
	var result: float = fallback
	for value in values:
		result = max(result, float(value))
	return result


func _min_price(values: Array, fallback: float) -> float:
	var result: float = fallback
	for value in values:
		result = min(result, float(value))
	return result
