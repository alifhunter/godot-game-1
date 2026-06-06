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
	var report: Dictionary = _run_audit(seed, difficulty_id, trading_days)
	print("%s%s" % [REPORT_PREFIX, JSON.stringify(report)])
	get_tree().quit(0 if bool(report.get("success", false)) else 1)


func _run_audit(seed: int, difficulty_id: String, trading_days: int) -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(difficulty_id)
	difficulty_id = str(difficulty_config.get("id", difficulty_id))
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
	var days_completed: int = max(int(counters.get("days_completed", 0)), 1)
	return {
		"success": true,
		"seed": seed,
		"difficulty_id": difficulty_id,
		"difficulty_label": str(difficulty_config.get("label", difficulty_id.capitalize())),
		"requested_trading_days": trading_days,
		"days_completed": int(counters.get("days_completed", 0)),
		"final_day_index": RunState.day_index,
		"final_trade_date": RunState.get_current_trade_date(),
		"company_count": RunState.company_order.size(),
		"stocks": stock_report,
		"events": {
			"counters": counters,
			"event_family_counts": event_family_counts,
			"event_id_counts": event_id_counts,
			"corporate_category_counts": corporate_category_counts,
			"special_event_id_counts": special_event_id_counts
		},
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


func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())


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
