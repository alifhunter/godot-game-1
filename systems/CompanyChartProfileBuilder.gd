extends RefCounted

const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")
const STABLE_RNG = preload("res://systems/StableRng.gd")


static func build_profile(
	source,
	template: Dictionary,
	sector_profile: Dictionary,
	traits: Dictionary,
	run_seed: int,
	company_id: String
) -> Dictionary:
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_seed, "chart_profile", company_id])
	var narrative_tags: Array = template.get("narrative_tags", [])
	var story_heat: float = clamp(float(traits.get("story_heat", 0.5)), 0.0, 1.0)
	var float_tightness: float = clamp(float(traits.get("float_tightness", 0.5)), 0.0, 1.0)
	var liquidity_profile: float = clamp(float(traits.get("liquidity_profile", 0.5)), 0.0, 1.0)
	var quality_core: float = clamp(float(traits.get("balance_sheet_strength", 0.5)), 0.0, 1.0)
	var growth_engine: float = clamp(float(traits.get("growth_engine", 0.5)), 0.0, 1.0)
	var cyclicality: float = clamp(float(traits.get("cyclicality", sector_profile.get("cyclicality", 0.5))), 0.0, 1.0)
	var execution_consistency: float = clamp(float(traits.get("execution_consistency", 0.5)), 0.0, 1.0)

	var archetype: String = str(source.call(
		"_chart_archetype_for",
		narrative_tags,
		story_heat,
		float_tightness,
		liquidity_profile,
		quality_core,
		growth_engine,
		cyclicality,
		execution_consistency,
		rng
	))
	var bias: String = str(source.call("_chart_bias_for", archetype, rng))
	var sma_behavior: String = str(source.call("_chart_sma_behavior_for", archetype, bias, rng))
	var preferred_sma_period: int = int(source.call("_chart_preferred_sma_period_for", archetype, rng))
	var pattern_selection: Dictionary = source.call("_chart_pattern_selection_for", archetype, bias, rng)
	var primary_pattern: String = str(pattern_selection.get("primary_pattern", "messy_range"))
	var pattern_variant: String = str(pattern_selection.get("pattern_variant", "standard"))
	var supporting_patterns: Array = pattern_selection.get("supporting_patterns", [])

	var volatility_style: String = str(source.call("_chart_volatility_style", archetype, cyclicality, story_heat, rng))
	var chart_intent: String = str(source.call(
		"_chart_intent_for",
		archetype,
		bias,
		quality_core,
		growth_engine,
		story_heat,
		float_tightness,
		cyclicality,
		rng
	))
	var pattern_timeframe: String = str(source.call("_chart_pattern_timeframe_for", chart_intent, archetype, bias, rng))
	var gap_profile: Dictionary = source.call(
		"_chart_gap_profile_for",
		chart_intent,
		archetype,
		bias,
		volatility_style,
		story_heat,
		float_tightness,
		quality_core,
		rng
	)
	var operator_pressure: float = float(source.call(
		"_chart_operator_pressure_for_profile",
		archetype,
		bias,
		narrative_tags,
		story_heat,
		float_tightness,
		liquidity_profile
	))
	var cycle_template: String = str(source.call(
		"_chart_cycle_template_for",
		archetype,
		bias,
		operator_pressure,
		story_heat,
		float_tightness,
		rng
	))
	var fib_profile_id: String = str(source.call("_chart_fib_profile_for", cycle_template, operator_pressure, rng))
	var cycle_strength: float = float(source.call("_chart_cycle_strength_for", cycle_template, operator_pressure, story_heat, float_tightness, rng))
	var cycle_tempo_profile: String = str(source.call("_chart_tempo_profile_for", archetype, bias, narrative_tags, cycle_template, operator_pressure, story_heat, liquidity_profile, quality_core, rng))
	var shakeout_profile: String = str(source.call("_chart_shakeout_profile_for", cycle_template, cycle_tempo_profile, operator_pressure, story_heat, float_tightness, rng))
	var microstructure_intensity: float = float(source.call("_chart_microstructure_intensity_for", cycle_template, cycle_tempo_profile, shakeout_profile, cycle_strength, operator_pressure, story_heat, float_tightness, liquidity_profile, rng))
	var setup_duration_bias: float = float(source.call("_chart_setup_duration_bias_for", cycle_tempo_profile, cycle_template, liquidity_profile, operator_pressure, rng))
	var bar_friction_profile: String = str(source.call("_chart_bar_friction_profile_for", archetype, bias, narrative_tags, cycle_template, cycle_tempo_profile, operator_pressure, story_heat, liquidity_profile, float_tightness, rng))
	var microleg_frequency_bias: float = float(source.call("_chart_microleg_frequency_bias_for", bar_friction_profile, cycle_tempo_profile, operator_pressure, story_heat, liquidity_profile, float_tightness, rng))
	var wick_noise_intensity: float = float(source.call("_chart_wick_noise_intensity_for", bar_friction_profile, operator_pressure, story_heat, float_tightness, liquidity_profile, rng))
	var volume_disagreement_rate: float = float(source.call("_chart_volume_disagreement_rate_for", bar_friction_profile, operator_pressure, story_heat, liquidity_profile, rng))
	var tape_regime_profile: String = str(source.call(
		"_chart_tape_regime_profile_for",
		archetype,
		bias,
		cycle_template,
		cycle_tempo_profile,
		bar_friction_profile,
		operator_pressure,
		story_heat,
		liquidity_profile,
		float_tightness,
		rng
	))
	var regime_block_intensity: float = float(source.call(
		"_chart_regime_block_intensity_for",
		tape_regime_profile,
		cycle_strength,
		microstructure_intensity,
		operator_pressure,
		story_heat,
		liquidity_profile,
		rng
	))
	var regime_tempo_bias: float = float(source.call(
		"_chart_regime_tempo_bias_for",
		tape_regime_profile,
		cycle_tempo_profile,
		setup_duration_bias,
		operator_pressure,
		liquidity_profile,
		rng
	))

	return {
		"archetype": archetype,
		"bias": bias,
		"chart_intent": chart_intent,
		"pattern_timeframe": pattern_timeframe,
		"sma_behavior": sma_behavior,
		"preferred_sma_period": preferred_sma_period,
		"primary_pattern": primary_pattern,
		"pattern_variant": pattern_variant,
		"supporting_patterns": supporting_patterns,
		"clarity": rng.randf_range(0.58, 0.84),
		"volatility_style": volatility_style,
		"volume_behavior": str(source.call("_chart_volume_behavior", archetype, bias)),
		"gap_style": str(gap_profile.get("gap_style", "none")),
		"gap_bias": str(gap_profile.get("gap_bias", "mixed")),
		"gap_frequency": str(gap_profile.get("gap_frequency", "rare")),
		"gap_followthrough": str(gap_profile.get("gap_followthrough", "fill")),
		"cycle_template": cycle_template,
		"cycle_strength": cycle_strength,
		"cycle_phase_bias": str(source.call("_chart_cycle_phase_bias", cycle_template)),
		"operator_pressure": operator_pressure,
		"fib_profile_id": fib_profile_id,
		"cycle_fib_ratios": source.call("_chart_fib_ratios_for_profile", fib_profile_id),
		"cycle_tempo_profile": cycle_tempo_profile,
		"microstructure_intensity": microstructure_intensity,
		"setup_duration_bias": setup_duration_bias,
		"shakeout_profile": shakeout_profile,
		"bar_friction_profile": bar_friction_profile,
		"microleg_frequency_bias": microleg_frequency_bias,
		"wick_noise_intensity": wick_noise_intensity,
		"volume_disagreement_rate": volume_disagreement_rate,
		"tape_regime_profile": tape_regime_profile,
		"regime_block_intensity": regime_block_intensity,
		"regime_tempo_bias": regime_tempo_bias
	}


static func apply_to_historical_bars(
	source,
	source_bars: Array,
	chart_profile: Dictionary,
	run_seed: int,
	company_id: String,
	end_price: float
) -> Array:
	if source_bars.size() < 12:
		return source_bars

	var normalized_end_price: float = IDX_PRICE_RULES.normalize_last_price(max(end_price, 1.0))
	var start_price: float = float(source.call("_chart_history_start_price", chart_profile, normalized_end_price, run_seed, company_id))
	var anchors: Array = source.call("_chart_shape_anchors", chart_profile)
	var pattern_window: Dictionary = source.call("_chart_pattern_timeframe_window", chart_profile, source_bars.size())
	var closes: Array = []
	var reshaped_bars: Array = []
	var previous_close: float = start_price
	var body_mismatch_direction: int = 0
	var body_mismatch_count: int = 0
	var volatility_style: String = str(chart_profile.get("volatility_style", "normal"))
	var clarity: float = clamp(float(chart_profile.get("clarity", 0.68)), 0.35, 0.92)
	var noise_scale: float = float(source.call("_chart_noise_scale", volatility_style)) * lerp(1.20, 0.58, clarity)
	var trend_log_start: float = log(max(start_price, 1.0))
	var trend_log_end: float = log(max(normalized_end_price, 1.0))

	for bar_index in range(source_bars.size()):
		var source_bar: Dictionary = source_bars[bar_index]
		var close_context: Dictionary = source.call(
			"_chart_historical_close_context",
			chart_profile,
			anchors,
			pattern_window,
			trend_log_start,
			trend_log_end,
			noise_scale,
			bar_index,
			source_bars.size(),
			previous_close,
			closes,
			run_seed,
			company_id,
			start_price,
			normalized_end_price
		)
		var progress: float = float(close_context.get("progress", 0.0))
		var micro_context: Dictionary = close_context.get("micro_context", {})
		var regime_context: Dictionary = close_context.get("regime_context", {})
		var friction_context: Dictionary = close_context.get("friction_context", {})
		var close_price: float = float(close_context.get("close", previous_close))
		var open_price: float = float(close_context.get("open", previous_close))
		var gap_ratio: float = float(close_context.get("gap_ratio", 0.0))
		var ar_limits: Dictionary = close_context.get("ar_limits", {})
		var remaining_bars: int = int(close_context.get("remaining_bars", 0))
		var body_context: Dictionary = source.call(
			"_chart_reconcile_historical_body_intent",
			chart_profile,
			micro_context,
			regime_context,
			friction_context,
			previous_close,
			open_price,
			close_price,
			normalized_end_price,
			remaining_bars,
			ar_limits,
			gap_ratio,
			bar_index,
			run_seed,
			company_id,
			body_mismatch_direction,
			body_mismatch_count
		)
		open_price = float(body_context.get("open", open_price))
		close_price = float(body_context.get("close", close_price))
		var intended_body_direction: int = int(body_context.get("intended_direction", 0))
		var actual_body_direction: int = int(source.call("_chart_direction_for_delta", close_price - open_price))
		if intended_body_direction != 0 and actual_body_direction != 0 and actual_body_direction != intended_body_direction:
			if body_mismatch_direction == intended_body_direction:
				body_mismatch_count += 1
			else:
				body_mismatch_direction = intended_body_direction
				body_mismatch_count = 1
		else:
			body_mismatch_direction = 0
			body_mismatch_count = 0
		var range_prices: Dictionary = source.call(
			"_chart_historical_range_prices",
			chart_profile,
			micro_context,
			regime_context,
			friction_context,
			open_price,
			close_price,
			intended_body_direction,
			actual_body_direction,
			run_seed,
			company_id,
			bar_index,
			ar_limits
		)
		var high_price: float = float(range_prices.get("high", close_price))
		var low_price: float = float(range_prices.get("low", close_price))

		var baseline_value: float = max(float(source_bar.get("value", 0.0)), close_price * 1000.0)
		var volume_fields: Dictionary = source.call(
			"_chart_historical_volume_fields",
			chart_profile,
			micro_context,
			regime_context,
			friction_context,
			progress,
			gap_ratio,
			baseline_value,
			open_price,
			close_price,
			run_seed,
			company_id,
			bar_index
		)
		var volume_shares: int = int(volume_fields.get("volume_shares", 0))
		var bar_value: float = float(volume_fields.get("value", close_price * float(volume_shares)))
		reshaped_bars.append({
			"trade_date": source_bar.get("trade_date", {}).duplicate(true),
			"open": open_price,
			"high": high_price,
			"low": low_price,
			"close": close_price,
			"volume_shares": volume_shares,
			"value": bar_value
		})
		closes.append(close_price)
		previous_close = close_price

	return reshaped_bars


static func shape_anchors(source, chart_profile: Dictionary) -> Array:
	var cycle_anchors: Array = source.call("_chart_cycle_shape_anchors", chart_profile)
	if not cycle_anchors.is_empty():
		return cycle_anchors
	return source.call(
		"_chart_pattern_shape_anchors",
		str(chart_profile.get("primary_pattern", "messy_range")),
		str(chart_profile.get("pattern_variant", "standard"))
	)
