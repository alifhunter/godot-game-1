extends RefCounted

const STABLE_RNG = preload("res://systems/StableRng.gd")

const HARD_CATALYST_CATEGORIES := {
	"corporate_action_filing": true,
	"corporate_meeting": true,
	"corporate_action_resolution": true,
	"corporate_action_execution": true
}
const SOFT_CATALYST_CATEGORIES := {
	"corporate_action_rumor": true,
	"corporate_action_speculation": true,
	"corporate_action_clarification": true
}
const POSITIVE_PHASES := ["accumulation", "markup", "final_hype"]
const WARNING_PHASES := ["shakeout", "regulatory_chop", "distribution", "dump", "dead_cat"]
const DUMP_PHASES := ["distribution", "dump", "dead_cat"]


func resolve_pre_close_context(
	definition: Dictionary,
	runtime: Dictionary,
	active_company_arcs: Array,
	scheduled_event: Dictionary,
	report_events: Array,
	previous_close: float,
	run_seed: int,
	day_number: int
) -> Dictionary:
	var company_id: String = str(definition.get("id", ""))
	if company_id.is_empty():
		return {}
	var campaign: Dictionary = _normalize_campaign(runtime.get("gorengan_campaign", {}), definition, runtime, previous_close, run_seed, day_number)
	var catalyst_snapshot: Dictionary = _collect_catalysts(company_id, active_company_arcs, scheduled_event, report_events)
	var eligible: bool = bool(campaign.get("active", false)) or _should_start_campaign(definition, runtime, catalyst_snapshot)
	if not eligible:
		return {}

	if not bool(campaign.get("active", false)):
		campaign = _start_campaign(definition, runtime, previous_close, run_seed, day_number)

	campaign = _apply_catalyst_snapshot(campaign, catalyst_snapshot, day_number)
	campaign = _refresh_regulatory_state(campaign, previous_close, day_number)
	campaign = _resolve_phase(campaign, previous_close, day_number)
	var modifiers: Dictionary = _build_modifiers(campaign, previous_close)
	campaign["last_pre_close_day_index"] = day_number
	campaign["last_pre_close_price"] = previous_close
	return {
		"active": true,
		"campaign": campaign.duplicate(true),
		"modifiers": modifiers.duplicate(true)
	}


func apply_event_context(event_context: Dictionary, campaign_context: Dictionary) -> Dictionary:
	if campaign_context.is_empty() or not bool(campaign_context.get("active", false)):
		return event_context
	var context: Dictionary = event_context.duplicate(true)
	var campaign: Dictionary = campaign_context.get("campaign", {})
	var modifiers: Dictionary = campaign_context.get("modifiers", {})
	var event_bias: float = float(context.get("event_bias", 0.0))
	if event_bias > 0.0:
		event_bias *= float(modifiers.get("positive_event_multiplier", 1.0))
		event_bias = min(event_bias, float(modifiers.get("positive_event_cap", event_bias)))
	context["event_bias"] = clamp(event_bias + float(modifiers.get("event_bias_shift", 0.0)), -0.18, 0.18)
	context["event_volatility_multiplier"] = clamp(
		float(context.get("event_volatility_multiplier", 1.0)) * float(modifiers.get("volatility_multiplier", 1.0)),
		0.55,
		2.35
	)
	context["volume_activity_multiplier"] = clamp(
		float(context.get("volume_activity_multiplier", 1.0)) * float(modifiers.get("volume_activity_multiplier", 1.0)),
		0.35,
		5.5
	)
	context["depth_liquidity_multiplier"] = clamp(
		float(context.get("depth_liquidity_multiplier", 1.0)) * float(modifiers.get("depth_liquidity_multiplier", 1.0)),
		0.45,
		2.6
	)
	context["gorengan_campaign"] = campaign.duplicate(true)
	context["gorengan_campaign_modifiers"] = modifiers.duplicate(true)
	var hidden_flags: Array = context.get("hidden_story_flags", []).duplicate()
	for flag_value in modifiers.get("hidden_flags", []):
		var flag: String = str(flag_value)
		if not flag.is_empty() and not hidden_flags.has(flag):
			hidden_flags.append(flag)
	context["hidden_story_flags"] = hidden_flags
	var active_events: Array = context.get("active_events", []).duplicate(true)
	active_events.append(_build_campaign_event(campaign))
	context["active_events"] = active_events
	var event_tags: Array = context.get("event_tags", []).duplicate()
	var tag: String = "gorengan_%s" % str(campaign.get("phase", "campaign"))
	if not event_tags.has(tag):
		event_tags.append(tag)
	context["event_tags"] = event_tags
	return context


func finalize_day_context(campaign_context: Dictionary, previous_close: float, current_price: float, close_context: Dictionary, volume_context: Dictionary, day_number: int) -> Dictionary:
	if campaign_context.is_empty() or not bool(campaign_context.get("active", false)):
		return {}
	var campaign: Dictionary = campaign_context.get("campaign", {}).duplicate(true)
	var daily_change_pct: float = 0.0
	if previous_close > 0.0:
		daily_change_pct = (current_price - previous_close) / previous_close
	var limit_lock: String = str(close_context.get("limit_lock", volume_context.get("limit_lock", "")))
	var ara_like: bool = limit_lock == "ara" or daily_change_pct >= 0.16
	if ara_like:
		campaign["green_limit_streak"] = int(campaign.get("green_limit_streak", 0)) + 1
	else:
		campaign["green_limit_streak"] = 0 if daily_change_pct <= 0.0 else max(int(campaign.get("green_limit_streak", 0)) - 1, 0)
	var arb_like: bool = limit_lock == "arb" or daily_change_pct <= -0.12
	if arb_like:
		campaign["dump_limit_streak"] = int(campaign.get("dump_limit_streak", 0)) + 1
	else:
		campaign["dump_limit_streak"] = 0 if daily_change_pct >= 0.0 else max(int(campaign.get("dump_limit_streak", 0)) - 1, 0)
	var heat: float = float(campaign.get("regulatory_heat", 0.0))
	heat += 0.16 if ara_like else -0.035
	heat += 0.12 if daily_change_pct >= 0.10 else 0.0
	heat += 0.10 if float(campaign.get("realized_return_pct", 0.0)) >= 8.0 else 0.0
	if arb_like:
		heat += 0.06
	campaign["regulatory_heat"] = clamp(heat, 0.0, 1.0)
	campaign["retail_heat"] = clamp(float(campaign.get("retail_heat", 0.0)) + max(daily_change_pct, 0.0) * 1.7 - max(-daily_change_pct, 0.0) * 0.55, 0.0, 1.0)
	campaign["last_daily_change_pct"] = daily_change_pct
	campaign["last_limit_lock"] = limit_lock
	campaign["last_close_price"] = current_price
	campaign["last_realized_return_pct"] = _realized_return_pct(campaign, current_price)
	campaign["realized_return_pct"] = float(campaign.get("last_realized_return_pct", 0.0))
	campaign = _refresh_regulatory_state(campaign, current_price, day_number)
	campaign = _resolve_phase(campaign, current_price, day_number)
	if int(campaign.get("dump_limit_streak", 0)) >= 4 or (str(campaign.get("phase", "")) == "cooldown" and float(campaign.get("realized_return_pct", 0.0)) <= 0.35):
		campaign["active"] = false
		campaign["phase"] = "cooldown"
		campaign["wave"] = "C"
		campaign["next_needed_beat"] = "campaign cooled down"
	campaign["last_updated_day_index"] = day_number
	return campaign


func campaign_attention_context(runtime: Dictionary) -> Dictionary:
	var campaign: Dictionary = runtime.get("gorengan_campaign", {}) if typeof(runtime.get("gorengan_campaign", {})) == TYPE_DICTIONARY else {}
	if campaign.is_empty() or not bool(campaign.get("active", false)):
		return {"attention_boost": 0.0, "dirty_boost": 0.0, "focus_boost": 0.0}
	var phase: String = str(campaign.get("phase", ""))
	var heat: float = clamp(float(campaign.get("regulatory_heat", 0.0)), 0.0, 1.0)
	var retail_heat: float = clamp(float(campaign.get("retail_heat", 0.0)), 0.0, 1.0)
	var catalyst_progress: float = clamp(
		float(campaign.get("hard_catalyst_count", 0)) / max(float(campaign.get("required_hard_catalysts", 3)), 1.0),
		0.0,
		1.0
	)
	var attention_boost: float = 0.10 + catalyst_progress * 0.12 + retail_heat * 0.08
	var dirty_boost: float = 0.06 + heat * 0.16
	var focus_boost: float = 0.12 + catalyst_progress * 0.18
	if phase in POSITIVE_PHASES:
		attention_boost += 0.08
		dirty_boost += 0.04
	elif phase in WARNING_PHASES:
		attention_boost += 0.05
		dirty_boost += 0.10
		focus_boost += 0.06
	return {
		"attention_boost": clamp(attention_boost, 0.0, 0.34),
		"dirty_boost": clamp(dirty_boost, 0.0, 0.34),
		"focus_boost": clamp(focus_boost, 0.0, 0.44),
		"phase": phase,
		"wave": str(campaign.get("wave", ""))
	}


func chart_overlay_for_campaign(campaign: Dictionary) -> Dictionary:
	if campaign.is_empty() or not bool(campaign.get("active", false)):
		return {}
	var phase: String = str(campaign.get("phase", ""))
	match phase:
		"accumulation":
			return {
				"cycle_template": "operator_markup",
				"cycle_phase_bias": "accumulation_to_markup",
				"tape_regime_profile": "messy_accumulation",
				"bar_friction_profile": "operator_dirty",
				"shakeout_profile": "healthy_pullback",
				"microstructure_intensity": 0.54,
				"operator_pressure": 0.68,
				"cycle_tempo_profile": "normal_setup"
			}
		"markup":
			return {
				"cycle_template": "operator_markup",
				"cycle_phase_bias": "accumulation_to_markup",
				"tape_regime_profile": "operator_campaign",
				"bar_friction_profile": "operator_dirty",
				"shakeout_profile": "healthy_pullback",
				"microstructure_intensity": 0.72,
				"operator_pressure": 0.82,
				"cycle_tempo_profile": "fast_operator"
			}
		"final_hype":
			return {
				"cycle_template": "markup_exhaustion",
				"cycle_phase_bias": "late_markup",
				"tape_regime_profile": "operator_campaign",
				"bar_friction_profile": "operator_dirty",
				"shakeout_profile": "hard_shakeout",
				"microstructure_intensity": 0.86,
				"operator_pressure": 0.92,
				"cycle_tempo_profile": "fast_operator"
			}
		"shakeout", "regulatory_chop":
			return {
				"cycle_template": "failed_markup",
				"cycle_phase_bias": "failed_breakout",
				"tape_regime_profile": "failed_reclaim",
				"bar_friction_profile": "distribution_chop",
				"shakeout_profile": "hard_shakeout",
				"microstructure_intensity": 0.80,
				"operator_pressure": 0.76,
				"cycle_tempo_profile": "failed_setup"
			}
		"distribution", "dump", "dead_cat":
			return {
				"cycle_template": "operator_rug",
				"cycle_phase_bias": "operator_distribution",
				"tape_regime_profile": "distribution_breakdown",
				"bar_friction_profile": "distribution_chop",
				"shakeout_profile": "dead_cat" if phase == "dead_cat" else "failed_reclaim",
				"microstructure_intensity": 0.90,
				"operator_pressure": 0.90,
				"cycle_tempo_profile": "failed_setup"
			}
	return {}


func _normalize_campaign(source_value: Variant, definition: Dictionary, runtime: Dictionary, previous_close: float, run_seed: int, day_number: int) -> Dictionary:
	var source: Dictionary = source_value.duplicate(true) if typeof(source_value) == TYPE_DICTIONARY else {}
	if source.is_empty():
		return {"active": false}
	var campaign: Dictionary = source.duplicate(true)
	campaign["version"] = 1
	campaign["active"] = bool(campaign.get("active", false))
	campaign["company_id"] = str(campaign.get("company_id", definition.get("id", "")))
	campaign["ticker"] = str(campaign.get("ticker", definition.get("ticker", campaign.get("company_id", ""))))
	campaign["tier"] = _valid_tier(str(campaign.get("tier", "common")))
	campaign["phase"] = str(campaign.get("phase", "accumulation"))
	campaign["wave"] = str(campaign.get("wave", "1"))
	campaign["start_day_index"] = int(campaign.get("start_day_index", day_number))
	campaign["start_price"] = max(float(campaign.get("start_price", runtime.get("starting_price", previous_close))), 1.0)
	campaign["target_return_pct"] = max(float(campaign.get("target_return_pct", _target_return_for_tier(campaign["tier"], run_seed, campaign["company_id"], day_number))), 0.75)
	campaign["required_hard_catalysts"] = max(int(campaign.get("required_hard_catalysts", _required_catalysts_for_tier(campaign["tier"], run_seed, campaign["company_id"], day_number))), 1)
	campaign["hard_chain_ids"] = _clean_string_array(campaign.get("hard_chain_ids", []))
	campaign["soft_chain_ids"] = _clean_string_array(campaign.get("soft_chain_ids", []))
	campaign["hard_catalyst_count"] = int(campaign["hard_chain_ids"].size())
	campaign["soft_catalyst_count"] = int(campaign["soft_chain_ids"].size())
	campaign["regulatory_heat"] = clamp(float(campaign.get("regulatory_heat", 0.0)), 0.0, 1.0)
	campaign["retail_heat"] = clamp(float(campaign.get("retail_heat", 0.0)), 0.0, 1.0)
	campaign["green_limit_streak"] = max(int(campaign.get("green_limit_streak", 0)), 0)
	campaign["dump_limit_streak"] = max(int(campaign.get("dump_limit_streak", 0)), 0)
	campaign["uma_issued"] = bool(campaign.get("uma_issued", false))
	campaign["suspension_seen"] = bool(campaign.get("suspension_seen", false))
	campaign["split_required"] = bool(campaign.get("split_required", false))
	campaign["split_scheduled"] = bool(campaign.get("split_scheduled", false))
	campaign["split_executed"] = bool(campaign.get("split_executed", false))
	campaign["realized_return_pct"] = _realized_return_pct(campaign, previous_close)
	campaign["last_realized_return_pct"] = float(campaign.get("realized_return_pct", 0.0))
	campaign["next_needed_beat"] = str(campaign.get("next_needed_beat", "first rumor"))
	return campaign


func _start_campaign(definition: Dictionary, runtime: Dictionary, previous_close: float, run_seed: int, day_number: int) -> Dictionary:
	var company_id: String = str(definition.get("id", ""))
	var tier: String = _roll_tier(definition, runtime, run_seed, company_id, day_number)
	return _normalize_campaign({
		"active": true,
		"company_id": company_id,
		"ticker": str(definition.get("ticker", company_id.to_upper())),
		"tier": tier,
		"phase": "accumulation",
		"wave": "1",
		"start_day_index": day_number,
		"start_price": max(float(runtime.get("starting_price", previous_close)), 1.0),
		"target_return_pct": _target_return_for_tier(tier, run_seed, company_id, day_number),
		"required_hard_catalysts": _required_catalysts_for_tier(tier, run_seed, company_id, day_number),
		"hard_chain_ids": [],
		"soft_chain_ids": [],
		"regulatory_heat": 0.0,
		"retail_heat": 0.0,
		"green_limit_streak": 0,
		"dump_limit_streak": 0,
		"next_needed_beat": "first formal catalyst"
	}, definition, runtime, previous_close, run_seed, day_number)


func _should_start_campaign(definition: Dictionary, runtime: Dictionary, catalyst_snapshot: Dictionary) -> bool:
	if int(catalyst_snapshot.get("soft_count", 0)) > 0 or int(catalyst_snapshot.get("hard_count", 0)) > 0:
		return _is_gorengan_like(definition, runtime)
	var daily_change: float = absf(float(runtime.get("daily_change_pct", 0.0)))
	if daily_change >= 0.10 and _is_gorengan_like(definition, runtime):
		return true
	return false


func _is_gorengan_like(definition: Dictionary, runtime: Dictionary) -> bool:
	var traits: Dictionary = definition.get("generation_traits", {}) if typeof(definition.get("generation_traits", {})) == TYPE_DICTIONARY else {}
	var profile: Dictionary = runtime.get("company_profile", {}) if typeof(runtime.get("company_profile", {})) == TYPE_DICTIONARY else {}
	var runtime_traits: Dictionary = profile.get("generation_traits", {}) if typeof(profile.get("generation_traits", {})) == TYPE_DICTIONARY else {}
	for source in [traits, runtime_traits]:
		if bool(source.get("is_gorengan", false)):
			return true
		var chart_profile: Dictionary = source.get("chart_profile", {}) if typeof(source.get("chart_profile", {})) == TYPE_DICTIONARY else {}
		if str(chart_profile.get("cycle_template", "")).begins_with("operator"):
			return true
	var narrative_tags: Array = definition.get("narrative_tags", [])
	for tag_value in narrative_tags:
		var tag: String = str(tag_value).to_lower()
		if tag.contains("gorengan") or tag.contains("retail_favorite") or tag.contains("narrative_hot") or tag.contains("speculative"):
			return true
	var financials: Dictionary = definition.get("financials", {}) if typeof(definition.get("financials", {})) == TYPE_DICTIONARY else {}
	return float(financials.get("free_float_pct", 35.0)) <= 28.0 and float(definition.get("risk_score", 50.0)) >= 54.0


func _collect_catalysts(company_id: String, active_company_arcs: Array, scheduled_event: Dictionary, report_events: Array) -> Dictionary:
	var hard_ids: Array = []
	var soft_ids: Array = []
	var split_seen: bool = false
	var split_executed: bool = false
	var rows: Array = []
	rows.append_array(active_company_arcs)
	if not scheduled_event.is_empty():
		rows.append(scheduled_event)
	rows.append_array(report_events)
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("target_company_id", "")) != company_id:
			continue
		if str(row.get("source_system", "")) != "corporate_action" and str(row.get("event_family", "")) != "corporate_action" and str(row.get("event_family", "")) != "company_arc":
			continue
		var category: String = str(row.get("category", ""))
		var chain_id: String = str(row.get("source_chain_id", row.get("arc_id", "")))
		if chain_id.is_empty():
			chain_id = "%s|%s" % [str(row.get("event_id", "")), category]
		var family: String = str(row.get("chain_family", row.get("event_id", "")))
		if family == "stock_split":
			split_seen = true
			if category == "corporate_action_execution" or str(row.get("current_phase_id", "")) == "execution":
				split_executed = true
		if HARD_CATALYST_CATEGORIES.has(category):
			if not hard_ids.has(chain_id):
				hard_ids.append(chain_id)
		elif SOFT_CATALYST_CATEGORIES.has(category):
			if not soft_ids.has(chain_id):
				soft_ids.append(chain_id)
	return {
		"hard_ids": hard_ids,
		"soft_ids": soft_ids,
		"hard_count": hard_ids.size(),
		"soft_count": soft_ids.size(),
		"split_seen": split_seen,
		"split_executed": split_executed
	}


func _apply_catalyst_snapshot(campaign: Dictionary, catalyst_snapshot: Dictionary, day_number: int) -> Dictionary:
	var next: Dictionary = campaign.duplicate(true)
	var hard_ids: Array = _clean_string_array(next.get("hard_chain_ids", []))
	for id_value in catalyst_snapshot.get("hard_ids", []):
		var id: String = str(id_value)
		if not id.is_empty() and not hard_ids.has(id):
			hard_ids.append(id)
			next["last_hard_catalyst_day_index"] = day_number
	var soft_ids: Array = _clean_string_array(next.get("soft_chain_ids", []))
	for id_value in catalyst_snapshot.get("soft_ids", []):
		var id: String = str(id_value)
		if not id.is_empty() and not soft_ids.has(id):
			soft_ids.append(id)
	next["hard_chain_ids"] = hard_ids
	next["soft_chain_ids"] = soft_ids
	next["hard_catalyst_count"] = hard_ids.size()
	next["soft_catalyst_count"] = soft_ids.size()
	if bool(catalyst_snapshot.get("split_seen", false)):
		next["split_scheduled"] = true
	if bool(catalyst_snapshot.get("split_executed", false)):
		next["split_executed"] = true
		next["split_scheduled"] = true
	return next


func _refresh_regulatory_state(campaign: Dictionary, current_price: float, day_number: int) -> Dictionary:
	var next: Dictionary = campaign.duplicate(true)
	var green_streak: int = int(next.get("green_limit_streak", 0))
	var heat: float = clamp(float(next.get("regulatory_heat", 0.0)), 0.0, 1.0)
	if green_streak >= 3:
		heat = clamp(heat + 0.12, 0.0, 1.0)
	if green_streak >= 5:
		next["uma_issued"] = true
		next["uma_day_index"] = int(next.get("uma_day_index", day_number))
		heat = max(heat, 0.58)
	if green_streak >= 7:
		next["suspension_seen"] = true
		next["suspension_day_index"] = int(next.get("suspension_day_index", day_number))
		heat = max(heat, 0.74)
	var realized: float = _realized_return_pct(next, current_price)
	if realized >= 10.0 and str(next.get("tier", "common")) in ["rare", "legendary"]:
		next["split_pressure"] = true
		next["split_required"] = true
	if current_price >= 50000.0:
		next["split_pressure"] = true
	if current_price >= 100000.0:
		next["split_required"] = true
	next["regulatory_heat"] = heat
	return next


func _resolve_phase(campaign: Dictionary, current_price: float, day_number: int) -> Dictionary:
	var next: Dictionary = campaign.duplicate(true)
	var realized: float = _realized_return_pct(next, current_price)
	var target: float = max(float(next.get("target_return_pct", 3.0)), 0.75)
	var hard_count: int = int(next.get("hard_catalyst_count", 0))
	var required: int = max(int(next.get("required_hard_catalysts", 3)), 1)
	var catalyst_progress: float = clamp(float(hard_count) / float(required), 0.0, 1.0)
	var gate_locked: bool = _is_gate_locked(next, current_price, realized)
	var phase: String = "accumulation"
	var wave: String = "1"
	var next_needed: String = "formal catalyst"
	if gate_locked:
		phase = "regulatory_chop" if bool(next.get("split_required", false)) or bool(next.get("uma_issued", false)) else "shakeout"
		wave = "4" if phase == "regulatory_chop" else "2"
		next_needed = _gate_needed_beat(next, current_price, realized)
	elif realized >= target * 1.05:
		phase = "dump" if str(next.get("phase", "")) in ["distribution", "dump", "dead_cat"] else "distribution"
		wave = "A"
		next_needed = "ugly dump risk"
	elif realized >= target * 0.74 and catalyst_progress >= 1.0:
		phase = "final_hype"
		wave = "5"
		next_needed = "exit liquidity warning"
	elif catalyst_progress >= 0.55:
		phase = "markup"
		wave = "3"
		next_needed = "next corporate action beat"
	elif realized >= 0.65 or int(next.get("green_limit_streak", 0)) >= 3:
		phase = "shakeout"
		wave = "2"
		next_needed = "new hard catalyst"
	else:
		phase = "accumulation"
		wave = "1"
		next_needed = "first hard catalyst"
	if str(next.get("phase", "")) in ["distribution", "dump", "dead_cat"] and phase == "dump":
		var days_in_dump: int = day_number - int(next.get("distribution_started_day_index", day_number))
		if days_in_dump >= 5 and int(next.get("dump_limit_streak", 0)) < 2:
			phase = "dead_cat"
			wave = "B"
			next_needed = "watch dead-cat bounce"
		elif days_in_dump >= 9:
			phase = "cooldown"
			wave = "C"
			next_needed = "campaign cooled down"
	var previous_distribution_phase: bool = ["distribution", "dump", "dead_cat"].has(str(next.get("phase", "")))
	if phase in ["distribution", "dump"] and not previous_distribution_phase and int(next.get("distribution_started_day_index", -1)) < 0:
		next["distribution_started_day_index"] = day_number
	next["phase"] = phase
	next["wave"] = wave
	next["realized_return_pct"] = realized
	next["catalyst_progress"] = catalyst_progress
	next["gate_locked"] = gate_locked
	next["next_needed_beat"] = next_needed
	return next


func _build_modifiers(campaign: Dictionary, current_price: float) -> Dictionary:
	var phase: String = str(campaign.get("phase", "accumulation"))
	var realized: float = float(campaign.get("realized_return_pct", _realized_return_pct(campaign, current_price)))
	var target: float = max(float(campaign.get("target_return_pct", 3.0)), 0.75)
	var hard_count: int = int(campaign.get("hard_catalyst_count", 0))
	var required: int = max(int(campaign.get("required_hard_catalysts", 3)), 1)
	var catalyst_progress: float = clamp(float(hard_count) / float(required), 0.0, 1.0)
	var positive_multiplier: float = clamp(0.18 + catalyst_progress * 0.88, 0.05, 1.10)
	var positive_cap: float = 0.030 + catalyst_progress * 0.055
	var price_bias: float = 0.0
	var volume_multiplier: float = 1.0
	var turnover_floor_rate: float = 0.00025
	var depth_multiplier: float = 1.0
	var volatility_multiplier: float = 1.0
	var hidden_flags: Array = []
	match phase:
		"accumulation":
			price_bias = 0.002
			volume_multiplier = 1.20
			turnover_floor_rate = 0.00035
			hidden_flags.append("gorengan_accumulation")
		"markup":
			price_bias = 0.006 + catalyst_progress * 0.006
			volume_multiplier = 1.75 + catalyst_progress * 0.75
			turnover_floor_rate = 0.00085 + catalyst_progress * 0.00070
			volatility_multiplier = 1.18
			hidden_flags.append("gorengan_markup")
		"final_hype":
			price_bias = 0.004
			volume_multiplier = 2.55
			turnover_floor_rate = 0.00190
			volatility_multiplier = 1.32
			hidden_flags.append("gorengan_final_hype")
		"shakeout":
			price_bias = -0.012
			positive_multiplier = min(positive_multiplier, 0.22)
			positive_cap = min(positive_cap, 0.018)
			volume_multiplier = 2.10
			turnover_floor_rate = 0.00140
			depth_multiplier = 0.82
			volatility_multiplier = 1.28
			hidden_flags.append("gorengan_shakeout")
		"regulatory_chop":
			price_bias = -0.009
			var regulatory_positive_cap: float = 0.28
			if bool(campaign.get("split_required", false)) and not bool(campaign.get("split_scheduled", false)):
				regulatory_positive_cap = 0.16
			positive_multiplier = min(positive_multiplier, regulatory_positive_cap)
			positive_cap = min(positive_cap, 0.014)
			volume_multiplier = 2.25
			turnover_floor_rate = 0.00170
			depth_multiplier = 0.72
			volatility_multiplier = 1.36
			hidden_flags.append("gorengan_regulatory_chop")
		"distribution":
			price_bias = -0.016
			positive_multiplier = min(positive_multiplier, 0.18)
			positive_cap = min(positive_cap, 0.012)
			volume_multiplier = 3.10
			turnover_floor_rate = 0.00280
			depth_multiplier = 0.64
			volatility_multiplier = 1.48
			hidden_flags.append("smart_money_distribution")
		"dump":
			price_bias = -0.030
			positive_multiplier = min(positive_multiplier, 0.08)
			positive_cap = min(positive_cap, 0.006)
			volume_multiplier = 3.70
			turnover_floor_rate = 0.00400
			depth_multiplier = 0.56
			volatility_multiplier = 1.58
			hidden_flags.append("smart_money_distribution")
		"dead_cat":
			price_bias = -0.010
			positive_multiplier = min(positive_multiplier, 0.32)
			positive_cap = min(positive_cap, 0.022)
			volume_multiplier = 2.75
			turnover_floor_rate = 0.00240
			depth_multiplier = 0.68
			volatility_multiplier = 1.42
			hidden_flags.append("gorengan_dead_cat")
	if realized >= target * 0.85:
		positive_multiplier = min(positive_multiplier, 0.30)
	if _is_gate_locked(campaign, current_price, realized):
		positive_multiplier = min(positive_multiplier, 0.12)
		positive_cap = min(positive_cap, 0.012)
		price_bias = min(price_bias, -0.010)
	return {
		"phase": phase,
		"wave": str(campaign.get("wave", "")),
		"event_bias_shift": price_bias,
		"campaign_price_bias": price_bias,
		"positive_event_multiplier": positive_multiplier,
		"positive_event_cap": positive_cap,
		"positive_change_multiplier": positive_multiplier,
		"volume_activity_multiplier": volume_multiplier,
		"campaign_volume_multiplier": volume_multiplier,
		"campaign_turnover_floor_rate": turnover_floor_rate,
		"depth_liquidity_multiplier": depth_multiplier,
		"volatility_multiplier": volatility_multiplier,
		"hidden_flags": hidden_flags,
		"chart_overlay": chart_overlay_for_campaign(campaign)
	}


func _is_gate_locked(campaign: Dictionary, current_price: float, realized: float) -> bool:
	var hard_count: int = int(campaign.get("hard_catalyst_count", 0))
	var required: int = max(int(campaign.get("required_hard_catalysts", 3)), 1)
	var tier: String = str(campaign.get("tier", "common"))
	if realized >= 8.0 and hard_count < required:
		return true
	if realized >= 10.0 and not bool(campaign.get("uma_issued", false)):
		return true
	if realized >= 10.0 and tier in ["rare", "legendary"] and not bool(campaign.get("suspension_seen", false)):
		return true
	if realized >= 10.0 and tier in ["rare", "legendary"] and not bool(campaign.get("split_scheduled", false)) and not bool(campaign.get("split_executed", false)):
		return true
	if realized >= 10.0 and current_price >= 100000.0 and not bool(campaign.get("split_scheduled", false)) and not bool(campaign.get("split_executed", false)):
		return true
	if tier == "common" and realized >= 8.0:
		return true
	return false


func _gate_needed_beat(campaign: Dictionary, current_price: float, realized: float) -> String:
	var hard_count: int = int(campaign.get("hard_catalyst_count", 0))
	var required: int = max(int(campaign.get("required_hard_catalysts", 3)), 1)
	if realized >= 8.0 and hard_count < required:
		return "needs %d more hard CA beat(s)" % max(required - hard_count, 1)
	if realized >= 10.0 and not bool(campaign.get("uma_issued", false)):
		return "needs UMA / exchange attention"
	if realized >= 10.0 and str(campaign.get("tier", "common")) in ["rare", "legendary"] and not bool(campaign.get("suspension_seen", false)):
		return "needs suspension / reopen beat"
	if realized >= 10.0 and str(campaign.get("tier", "common")) in ["rare", "legendary"] and not bool(campaign.get("split_scheduled", false)) and not bool(campaign.get("split_executed", false)):
		return "needs stock split path"
	if current_price >= 100000.0 and not bool(campaign.get("split_scheduled", false)) and not bool(campaign.get("split_executed", false)):
		return "needs stock split path"
	return "needs cooling period"


func _build_campaign_event(campaign: Dictionary) -> Dictionary:
	var ticker: String = str(campaign.get("ticker", ""))
	var phase: String = str(campaign.get("phase", "campaign"))
	return {
		"event_id": "gorengan_campaign",
		"event_family": "company_arc",
		"scope": "company",
		"category": "gorengan_%s" % phase,
		"tone": "negative" if phase in DUMP_PHASES else "mixed",
		"target_company_id": str(campaign.get("company_id", "")),
		"target_ticker": ticker,
		"target_company_name": ticker,
		"description": "%s gorengan campaign: %s / wave %s." % [ticker, phase.replace("_", " "), str(campaign.get("wave", ""))],
		"source_system": "gorengan_campaign",
		"current_phase_id": phase,
		"current_phase_label": phase.replace("_", " ").capitalize(),
		"phase_sentiment_shift": 0.0,
		"phase_visibility": "hidden",
		"phase_hidden_flag": "gorengan_%s" % phase
	}


func _realized_return_pct(campaign: Dictionary, current_price: float) -> float:
	var start_price: float = max(float(campaign.get("start_price", current_price)), 1.0)
	return max((max(current_price, 1.0) - start_price) / start_price, -0.95)


func _roll_tier(definition: Dictionary, runtime: Dictionary, run_seed: int, company_id: String, day_number: int) -> String:
	var roll: float = STABLE_RNG.unit_float([run_seed, "gorengan_campaign_tier", company_id, day_number])
	var traits: Dictionary = definition.get("generation_traits", {}) if typeof(definition.get("generation_traits", {})) == TYPE_DICTIONARY else {}
	var profile: Dictionary = runtime.get("company_profile", {}) if typeof(runtime.get("company_profile", {})) == TYPE_DICTIONARY else {}
	var runtime_traits: Dictionary = profile.get("generation_traits", {}) if typeof(profile.get("generation_traits", {})) == TYPE_DICTIONARY else {}
	var story_heat: float = max(float(traits.get("story_heat", 0.5)), float(runtime_traits.get("story_heat", 0.5)))
	var rare_bonus: float = clamp((story_heat - 0.62) * 0.16, 0.0, 0.06)
	if roll < 0.035 + rare_bonus:
		return "legendary"
	if roll < 0.18 + rare_bonus:
		return "rare"
	return "common"


func _target_return_for_tier(tier: String, run_seed: int, company_id: String, day_number: int) -> float:
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "gorengan_campaign_target", company_id, tier, day_number])
	match _valid_tier(tier):
		"legendary":
			return rng.randf_range(30.0, 100.0)
		"rare":
			return rng.randf_range(10.0, 30.0)
		_:
			return rng.randf_range(2.0, 8.0)


func _required_catalysts_for_tier(tier: String, run_seed: int, company_id: String, day_number: int) -> int:
	match _valid_tier(tier):
		"legendary":
			return STABLE_RNG.int_between([run_seed, "gorengan_required_catalysts", company_id, tier, day_number], 7, 10)
		"rare":
			return STABLE_RNG.int_between([run_seed, "gorengan_required_catalysts", company_id, tier, day_number], 5, 7)
		_:
			return STABLE_RNG.int_between([run_seed, "gorengan_required_catalysts", company_id, tier, day_number], 3, 4)


func _valid_tier(tier: String) -> String:
	if tier in ["common", "rare", "legendary"]:
		return tier
	return "common"


func _clean_string_array(source_value: Variant) -> Array:
	var rows: Array = []
	if typeof(source_value) != TYPE_ARRAY:
		return rows
	for value in source_value:
		var text: String = str(value)
		if not text.is_empty() and not rows.has(text):
			rows.append(text)
	return rows
