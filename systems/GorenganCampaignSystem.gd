extends RefCounted

const STABLE_RNG = preload("res://systems/StableRng.gd")

# ARA/ARB detection thresholds
const CAMPAIGN_ARA_CHANGE_THRESHOLD := 0.16    # daily change pct that counts as ARA-like
const CAMPAIGN_ARB_CHANGE_THRESHOLD := -0.12   # daily change pct that counts as ARB-like
const CAMPAIGN_STRONG_UP_THRESHOLD := 0.10     # change pct that adds extra regulatory heat

# Regulatory heat deltas per day
const CAMPAIGN_HEAT_ARA_ADD := 0.16            # heat gained on an ARA-like day
const CAMPAIGN_HEAT_GREEN_DECAY := -0.035      # heat lost on any non-ARA green/flat day
const CAMPAIGN_HEAT_STRONG_UP_ADD := 0.12      # extra heat when daily move >= strong-up threshold
const CAMPAIGN_HEAT_HIGH_RETURN_ADD := 0.10    # extra heat when realized return >= high-return threshold
const CAMPAIGN_HEAT_HIGH_RETURN_THRESHOLD := 8.0  # realized return % that triggers extra heat
const CAMPAIGN_HEAT_ARB_ADD := 0.06            # heat gained on an ARB-like day

# Retail heat deltas
const CAMPAIGN_RETAIL_HEAT_UP_SCALE := 1.7    # retail heat gains faster on up days
const CAMPAIGN_RETAIL_HEAT_DOWN_SCALE := 0.55 # retail heat decays slower on down days

# Cooldown conditions
const CAMPAIGN_DUMP_STREAK_COOLDOWN := 4       # consecutive ARB-like days that force campaign end
const CAMPAIGN_COOLDOWN_RETURN_FLOOR := 0.35   # realized return below which cooldown phase ends campaign

# Attention boosts
const CAMPAIGN_ATTENTION_BASE := 0.10
const CAMPAIGN_DIRTY_BASE := 0.06
const CAMPAIGN_FOCUS_BASE := 0.12
const CAMPAIGN_ATTENTION_CATALYST_SCALE := 0.12
const CAMPAIGN_DIRTY_HEAT_SCALE := 0.16
const CAMPAIGN_FOCUS_CATALYST_SCALE := 0.18
const CAMPAIGN_ATTENTION_RETAIL_SCALE := 0.08
const CAMPAIGN_ATTENTION_POSITIVE_BONUS := 0.08
const CAMPAIGN_ATTENTION_WARNING_BONUS := 0.05
const CAMPAIGN_DIRTY_POSITIVE_BONUS := 0.04
const CAMPAIGN_DIRTY_WARNING_BONUS := 0.10
const CAMPAIGN_FOCUS_WARNING_BONUS := 0.06
const CAMPAIGN_ATTENTION_MAX := 0.34
const CAMPAIGN_DIRTY_MAX := 0.34
const CAMPAIGN_FOCUS_MAX := 0.44

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
	var state: CampaignState = _normalize_campaign(runtime.get("gorengan_campaign", {}), definition, runtime, previous_close, run_seed, day_number)
	var catalyst_snapshot: Dictionary = _collect_catalysts(company_id, active_company_arcs, scheduled_event, report_events)
	var eligible: bool = state.active or _should_start_campaign(definition, runtime, catalyst_snapshot)
	if not eligible:
		return {}

	if not state.active:
		state = _start_campaign(definition, runtime, previous_close, run_seed, day_number)

	_apply_catalyst_snapshot(state, catalyst_snapshot, day_number)
	_refresh_regulatory_state(state, previous_close, day_number)
	_resolve_phase(state, previous_close, day_number)
	var modifiers: Dictionary = _build_modifiers(state, previous_close)
	state.last_pre_close_day_index = day_number
	state.last_pre_close_price = previous_close
	return {
		"active": true,
		"campaign": state.to_dict(),
		"modifiers": modifiers
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
	active_events.append(_build_campaign_event(CampaignState.from_dict(campaign)))
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
	var state: CampaignState = CampaignState.from_dict(campaign_context.get("campaign", {}))
	var daily_change_pct: float = 0.0
	if previous_close > 0.0:
		daily_change_pct = (current_price - previous_close) / previous_close
	var limit_lock: String = str(close_context.get("limit_lock", volume_context.get("limit_lock", "")))
	var ara_like: bool = limit_lock == "ara" or daily_change_pct >= CAMPAIGN_ARA_CHANGE_THRESHOLD
	if ara_like:
		state.green_limit_streak += 1
	else:
		state.green_limit_streak = 0 if daily_change_pct <= 0.0 else max(state.green_limit_streak - 1, 0)
	var arb_like: bool = limit_lock == "arb" or daily_change_pct <= CAMPAIGN_ARB_CHANGE_THRESHOLD
	if arb_like:
		state.dump_limit_streak += 1
	else:
		state.dump_limit_streak = 0 if daily_change_pct >= 0.0 else max(state.dump_limit_streak - 1, 0)
	var heat: float = state.regulatory_heat
	heat += CAMPAIGN_HEAT_ARA_ADD if ara_like else CAMPAIGN_HEAT_GREEN_DECAY
	heat += CAMPAIGN_HEAT_STRONG_UP_ADD if daily_change_pct >= CAMPAIGN_STRONG_UP_THRESHOLD else 0.0
	heat += CAMPAIGN_HEAT_HIGH_RETURN_ADD if state.realized_return_pct >= CAMPAIGN_HEAT_HIGH_RETURN_THRESHOLD else 0.0
	if arb_like:
		heat += CAMPAIGN_HEAT_ARB_ADD
	state.regulatory_heat = clamp(heat, 0.0, 1.0)
	state.retail_heat = clamp(state.retail_heat + max(daily_change_pct, 0.0) * CAMPAIGN_RETAIL_HEAT_UP_SCALE - max(-daily_change_pct, 0.0) * CAMPAIGN_RETAIL_HEAT_DOWN_SCALE, 0.0, 1.0)
	state.last_daily_change_pct = daily_change_pct
	state.last_limit_lock = limit_lock
	state.last_close_price = current_price
	state.last_realized_return_pct = _realized_return_pct(state, current_price)
	state.realized_return_pct = state.last_realized_return_pct
	_refresh_regulatory_state(state, current_price, day_number)
	_resolve_phase(state, current_price, day_number)
	# Deactivate if _resolve_phase concluded cooldown, or if a cooldown phase has no return left to defend.
	var in_cooldown: bool = state.phase == "cooldown"
	var return_exhausted: bool = state.realized_return_pct <= CAMPAIGN_COOLDOWN_RETURN_FLOOR
	if in_cooldown and return_exhausted:
		state.active = false
	state.last_updated_day_index = day_number
	return state.to_dict()


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
	var attention_boost: float = CAMPAIGN_ATTENTION_BASE + catalyst_progress * CAMPAIGN_ATTENTION_CATALYST_SCALE + retail_heat * CAMPAIGN_ATTENTION_RETAIL_SCALE
	var dirty_boost: float = CAMPAIGN_DIRTY_BASE + heat * CAMPAIGN_DIRTY_HEAT_SCALE
	var focus_boost: float = CAMPAIGN_FOCUS_BASE + catalyst_progress * CAMPAIGN_FOCUS_CATALYST_SCALE
	if phase in POSITIVE_PHASES:
		attention_boost += CAMPAIGN_ATTENTION_POSITIVE_BONUS
		dirty_boost += CAMPAIGN_DIRTY_POSITIVE_BONUS
	elif phase in WARNING_PHASES:
		attention_boost += CAMPAIGN_ATTENTION_WARNING_BONUS
		dirty_boost += CAMPAIGN_DIRTY_WARNING_BONUS
		focus_boost += CAMPAIGN_FOCUS_WARNING_BONUS
	return {
		"attention_boost": clamp(attention_boost, 0.0, CAMPAIGN_ATTENTION_MAX),
		"dirty_boost": clamp(dirty_boost, 0.0, CAMPAIGN_DIRTY_MAX),
		"focus_boost": clamp(focus_boost, 0.0, CAMPAIGN_FOCUS_MAX),
		"phase": phase,
		"wave": str(campaign.get("wave", ""))
	}


func chart_overlay_for_campaign(campaign: Dictionary) -> Dictionary:
	if campaign.is_empty() or not bool(campaign.get("active", false)):
		return {}
	return _chart_overlay_for_phase(str(campaign.get("phase", "")))


func _chart_overlay_for_phase(phase: String) -> Dictionary:
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


func _normalize_campaign(source_value: Variant, definition: Dictionary, runtime: Dictionary, previous_close: float, run_seed: int, day_number: int) -> CampaignState:
	var source: Dictionary = source_value if typeof(source_value) == TYPE_DICTIONARY else {}
	if source.is_empty():
		return CampaignState.new()
	var state: CampaignState = CampaignState.from_dict(source)
	if state.company_id.is_empty():
		state.company_id = str(definition.get("id", ""))
	if state.ticker.is_empty():
		state.ticker = str(definition.get("ticker", state.company_id))
	if not source.has("start_day_index"):
		state.start_day_index = day_number
	if not source.has("start_price"):
		state.start_price = max(float(runtime.get("starting_price", previous_close)), 1.0)
	if not source.has("target_return_pct"):
		state.target_return_pct = max(_target_return_for_tier(state.tier, run_seed, state.company_id, day_number), 0.75)
	if not source.has("required_hard_catalysts"):
		state.required_hard_catalysts = max(_required_catalysts_for_tier(state.tier, run_seed, state.company_id, day_number), 1)
	state.realized_return_pct = _realized_return_pct(state, previous_close)
	state.last_realized_return_pct = state.realized_return_pct
	return state


func _start_campaign(definition: Dictionary, runtime: Dictionary, previous_close: float, run_seed: int, day_number: int) -> CampaignState:
	var company_id: String = str(definition.get("id", ""))
	var tier: String = _roll_tier(definition, runtime, run_seed, company_id, day_number)
	var state: CampaignState = CampaignState.new()
	state.active = true
	state.company_id = company_id
	state.ticker = str(definition.get("ticker", company_id.to_upper()))
	state.tier = _valid_tier(tier)
	state.phase = "accumulation"
	state.wave = "1"
	state.start_day_index = day_number
	state.start_price = max(float(runtime.get("starting_price", previous_close)), 1.0)
	state.target_return_pct = max(_target_return_for_tier(tier, run_seed, company_id, day_number), 0.75)
	state.required_hard_catalysts = max(_required_catalysts_for_tier(tier, run_seed, company_id, day_number), 1)
	state.next_needed_beat = "first formal catalyst"
	state.realized_return_pct = _realized_return_pct(state, previous_close)
	state.last_realized_return_pct = state.realized_return_pct
	return state


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


func _apply_catalyst_snapshot(state: CampaignState, catalyst_snapshot: Dictionary, day_number: int) -> void:
	var hard_ids: Array = _clean_string_array(state.hard_chain_ids)
	for id_value in catalyst_snapshot.get("hard_ids", []):
		var id: String = str(id_value)
		if not id.is_empty() and not hard_ids.has(id):
			hard_ids.append(id)
			state.last_hard_catalyst_day_index = day_number
	var soft_ids: Array = _clean_string_array(state.soft_chain_ids)
	for id_value in catalyst_snapshot.get("soft_ids", []):
		var id: String = str(id_value)
		if not id.is_empty() and not soft_ids.has(id):
			soft_ids.append(id)
	state.hard_chain_ids = hard_ids
	state.soft_chain_ids = soft_ids
	state.hard_catalyst_count = hard_ids.size()
	state.soft_catalyst_count = soft_ids.size()
	if bool(catalyst_snapshot.get("split_seen", false)):
		state.split_scheduled = true
	if bool(catalyst_snapshot.get("split_executed", false)):
		state.split_executed = true
		state.split_scheduled = true


func _refresh_regulatory_state(state: CampaignState, current_price: float, day_number: int) -> void:
	var heat: float = clamp(state.regulatory_heat, 0.0, 1.0)
	if state.green_limit_streak >= 3:
		heat = clamp(heat + 0.12, 0.0, 1.0)
	if state.green_limit_streak >= 5:
		state.uma_issued = true
		if state.uma_day_index < 0:
			state.uma_day_index = day_number
		heat = max(heat, 0.58)
	if state.green_limit_streak >= 7:
		state.suspension_seen = true
		if state.suspension_day_index < 0:
			state.suspension_day_index = day_number
		heat = max(heat, 0.74)
	var realized: float = _realized_return_pct(state, current_price)
	if realized >= 10.0 and state.tier in ["rare", "legendary"]:
		state.split_pressure = true
		state.split_required = true
	if current_price >= 50000.0:
		state.split_pressure = true
	if current_price >= 100000.0:
		state.split_required = true
	state.regulatory_heat = heat


func _resolve_phase(state: CampaignState, current_price: float, day_number: int) -> void:
	var realized: float = _realized_return_pct(state, current_price)
	var target: float = max(state.target_return_pct, 0.75)
	var hard_count: int = state.hard_catalyst_count
	var required: int = max(state.required_hard_catalysts, 1)
	var catalyst_progress: float = clamp(float(hard_count) / float(required), 0.0, 1.0)
	var gate_locked: bool = _is_gate_locked(state, current_price, realized)
	var phase: String = "accumulation"
	var wave: String = "1"
	var next_needed: String = "formal catalyst"
	if gate_locked:
		phase = "regulatory_chop" if state.split_required or state.uma_issued else "shakeout"
		wave = "4" if phase == "regulatory_chop" else "2"
		next_needed = _gate_needed_beat(state, current_price, realized)
	elif realized >= target * 1.05:
		phase = "dump" if state.phase in ["distribution", "dump", "dead_cat"] else "distribution"
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
	elif realized >= 0.65 or state.green_limit_streak >= 3:
		phase = "shakeout"
		wave = "2"
		next_needed = "new hard catalyst"
	else:
		phase = "accumulation"
		wave = "1"
		next_needed = "first hard catalyst"
	if state.phase in ["distribution", "dump", "dead_cat"] and phase == "dump":
		var dist_start: int = state.distribution_started_day_index if state.distribution_started_day_index >= 0 else day_number
		var days_in_dump: int = day_number - dist_start
		if days_in_dump >= 5 and state.dump_limit_streak < 2:
			phase = "dead_cat"
			wave = "B"
			next_needed = "watch dead-cat bounce"
		elif days_in_dump >= 9:
			phase = "cooldown"
			wave = "C"
			next_needed = "campaign cooled down"
	var previous_distribution_phase: bool = ["distribution", "dump", "dead_cat"].has(state.phase)
	if phase in ["distribution", "dump"] and not previous_distribution_phase and state.distribution_started_day_index < 0:
		state.distribution_started_day_index = day_number
	# Momentum-based force-cooldown: consecutive ARB days override all other phase logic.
	# This is the only other place (besides the time-based path above) that triggers cooldown.
	if state.dump_limit_streak >= CAMPAIGN_DUMP_STREAK_COOLDOWN:
		phase = "cooldown"
		wave = "C"
		next_needed = "campaign cooled down (dump streak)"
	state.phase = phase
	state.wave = wave
	state.realized_return_pct = realized
	state.catalyst_progress = catalyst_progress
	state.gate_locked = gate_locked
	state.next_needed_beat = next_needed


func _build_modifiers(state: CampaignState, current_price: float) -> Dictionary:
	var phase: String = state.phase
	var realized: float = state.realized_return_pct if state.realized_return_pct != 0.0 else _realized_return_pct(state, current_price)
	var target: float = max(state.target_return_pct, 0.75)
	var hard_count: int = state.hard_catalyst_count
	var required: int = max(state.required_hard_catalysts, 1)
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
			if state.split_required and not state.split_scheduled:
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
	if _is_gate_locked(state, current_price, realized):
		positive_multiplier = min(positive_multiplier, 0.12)
		positive_cap = min(positive_cap, 0.012)
		price_bias = min(price_bias, -0.010)
	return {
		"phase": phase,
		"wave": state.wave,
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
		"chart_overlay": _chart_overlay_for_phase(state.phase) if state.active else {}
	}


func _is_gate_locked(state: CampaignState, current_price: float, realized: float) -> bool:
	var hard_count: int = state.hard_catalyst_count
	var required: int = max(state.required_hard_catalysts, 1)
	if realized >= 8.0 and hard_count < required:
		return true
	if realized >= 10.0 and not state.uma_issued:
		return true
	if realized >= 10.0 and state.tier in ["rare", "legendary"] and not state.suspension_seen:
		return true
	if realized >= 10.0 and state.tier in ["rare", "legendary"] and not state.split_scheduled and not state.split_executed:
		return true
	if realized >= 10.0 and current_price >= 100000.0 and not state.split_scheduled and not state.split_executed:
		return true
	if state.tier == "common" and realized >= 8.0:
		return true
	return false


func _gate_needed_beat(state: CampaignState, current_price: float, realized: float) -> String:
	var hard_count: int = state.hard_catalyst_count
	var required: int = max(state.required_hard_catalysts, 1)
	if realized >= 8.0 and hard_count < required:
		return "needs %d more hard CA beat(s)" % max(required - hard_count, 1)
	if realized >= 10.0 and not state.uma_issued:
		return "needs UMA / exchange attention"
	if realized >= 10.0 and state.tier in ["rare", "legendary"] and not state.suspension_seen:
		return "needs suspension / reopen beat"
	if realized >= 10.0 and state.tier in ["rare", "legendary"] and not state.split_scheduled and not state.split_executed:
		return "needs stock split path"
	if current_price >= 100000.0 and not state.split_scheduled and not state.split_executed:
		return "needs stock split path"
	return "needs cooling period"


func _build_campaign_event(state: CampaignState) -> Dictionary:
	var phase: String = state.phase
	return {
		"event_id": "gorengan_campaign",
		"event_family": "company_arc",
		"scope": "company",
		"category": "gorengan_%s" % phase,
		"tone": "negative" if phase in DUMP_PHASES else "mixed",
		"target_company_id": state.company_id,
		"target_ticker": state.ticker,
		"target_company_name": state.ticker,
		"description": "%s gorengan campaign: %s / wave %s." % [state.ticker, phase.replace("_", " "), state.wave],
		"source_system": "gorengan_campaign",
		"current_phase_id": phase,
		"current_phase_label": phase.replace("_", " ").capitalize(),
		"phase_sentiment_shift": 0.0,
		"phase_visibility": "hidden",
		"phase_hidden_flag": "gorengan_%s" % phase
	}


func _realized_return_pct(state: CampaignState, current_price: float) -> float:
	var sp: float = max(state.start_price, 1.0)
	return max((max(current_price, 1.0) - sp) / sp, -0.95)


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
