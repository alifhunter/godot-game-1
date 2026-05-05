extends RefCounted

const STATE_GOOD := "Good read"
const STATE_PLAUSIBLE := "Plausible, needs confirmation"
const STATE_WEAK := "Weak read"
const STATE_CONTRADICTED := "Contradicted"

const PATTERNS := [
	{"id": "range", "label": "Range / Consolidation"},
	{"id": "breakout", "label": "Breakout"},
	{"id": "breakout_retest", "label": "Breakout Retest"},
	{"id": "breakdown", "label": "Breakdown"},
	{"id": "failed_breakout", "label": "Failed Breakout"},
	{"id": "pullback_support", "label": "Pullback to Support"},
	{"id": "higher_lows", "label": "Higher Lows"},
	{"id": "lower_highs", "label": "Lower Highs"},
	{"id": "double_bottom", "label": "Double Bottom"},
	{"id": "double_top", "label": "Double Top"},
	{"id": "cup_handle", "label": "Cup and Handle"},
	{"id": "head_shoulders", "label": "Head and Shoulders"},
	{"id": "inverse_head_shoulders", "label": "Inverse Head and Shoulders"},
	{"id": "ascending_triangle", "label": "Ascending Triangle"},
	{"id": "descending_triangle", "label": "Descending Triangle"},
	{"id": "bull_flag", "label": "Bull Flag"},
	{"id": "sma_support_bounce", "label": "SMA Support Bounce"},
	{"id": "sma_resistance_rejection", "label": "SMA Resistance Rejection"},
	{"id": "volume_confirmation", "label": "Volume Confirmation"}
]


func get_pattern_catalog() -> Array:
	return PATTERNS.duplicate(true)


func evaluate_pattern_claim(context: Dictionary) -> Dictionary:
	var bars: Array = _normalized_bars(context.get("bars", []))
	if bars.size() < 3:
		return _failure("Not enough visible bars to evaluate this pattern claim.")

	var pattern_id: String = _normalize_pattern_id(str(context.get("pattern_id", "")))
	if pattern_id.is_empty():
		return _failure("Choose a valid pattern type first.")

	var start_index: int = _bar_index_for_anchor(context.get("start_anchor", {}), bars)
	var end_index: int = _bar_index_for_anchor(context.get("end_anchor", {}), bars)
	if start_index < 0 or end_index < 0:
		return _failure("The marked region no longer matches the visible chart bars.")
	if start_index > end_index:
		var swap_index: int = start_index
		start_index = end_index
		end_index = swap_index

	var selected_bars: Array = bars.slice(start_index, end_index + 1)
	if selected_bars.size() < 3:
		return _failure("Mark at least three bars so the coaching read has enough structure.")

	var previous_bars: Array = bars.slice(max(start_index - 12, 0), start_index)
	var metrics: Dictionary = _build_metrics(selected_bars, previous_bars)
	var feedback: Dictionary = _feedback_for_pattern(pattern_id, metrics)
	var pattern_label: String = _pattern_label(pattern_id)
	var feedback_state: String = str(feedback.get("state", STATE_WEAK))
	var reason: String = str(feedback.get("reason", "The marked region needs more confirmation."))
	var invalidation: String = str(feedback.get("invalidation", "Recheck if price breaks the marked structure."))
	var next_check: String = str(feedback.get("next_check", _next_check_for_state(feedback_state)))
	var region_label: String = _region_label(selected_bars)
	var source_label: String = "STOCKBOT Chart"
	var ticker: String = str(context.get("ticker", context.get("company_id", "")))
	var range_label: String = str(context.get("range_label", context.get("range_id", ""))).to_upper()
	var detail: String = "Player marked %s on %s%s. Feedback reads %s because %s Next check: %s Invalidation: %s" % [
		pattern_label,
		region_label,
		" (%s)" % range_label if not range_label.is_empty() else "",
		feedback_state,
		reason,
		next_check,
		invalidation
	]
	return {
		"success": true,
		"category": "price_action",
		"category_label": "Price Action",
		"label": "Player pattern: %s" % pattern_label,
		"value": feedback_state,
		"detail": detail,
		"source_label": source_label,
		"impact": str(feedback.get("impact", "mixed")),
		"company_id": str(context.get("company_id", "")),
		"ticker": ticker,
		"pattern_id": pattern_id,
		"pattern_label": pattern_label,
		"feedback_state": feedback_state,
		"feedback_reason": reason,
		"invalidation": invalidation,
		"next_check": next_check,
		"chart_range": str(context.get("range_id", "")),
		"chart_range_label": range_label,
		"region_label": region_label,
		"start_anchor": context.get("start_anchor", {}).duplicate(true) if typeof(context.get("start_anchor", {})) == TYPE_DICTIONARY else {},
		"end_anchor": context.get("end_anchor", {}).duplicate(true) if typeof(context.get("end_anchor", {})) == TYPE_DICTIONARY else {},
		"start_date": selected_bars[0].get("trade_date", {}).duplicate(true),
		"end_date": selected_bars[selected_bars.size() - 1].get("trade_date", {}).duplicate(true),
		"start_price": float(selected_bars[0].get("close", 0.0)),
		"end_price": float(selected_bars[selected_bars.size() - 1].get("close", 0.0)),
		"current_price": float(context.get("current_price", selected_bars[selected_bars.size() - 1].get("close", 0.0))),
		"report_date": context.get("trade_date", {}).duplicate(true) if typeof(context.get("trade_date", {})) == TYPE_DICTIONARY else {}
	}


func _feedback_for_pattern(pattern_id: String, metrics: Dictionary) -> Dictionary:
	match pattern_id:
		"range":
			return _feedback_range(metrics)
		"breakout":
			return _feedback_breakout(metrics)
		"breakout_retest":
			return _feedback_breakout_retest(metrics)
		"breakdown":
			return _feedback_breakdown(metrics)
		"failed_breakout":
			return _feedback_failed_breakout(metrics)
		"pullback_support":
			return _feedback_pullback_support(metrics)
		"higher_lows":
			return _feedback_higher_lows(metrics)
		"lower_highs":
			return _feedback_lower_highs(metrics)
		"double_bottom":
			return _feedback_double_bottom(metrics)
		"double_top":
			return _feedback_double_top(metrics)
		"cup_handle":
			return _feedback_cup_handle(metrics)
		"head_shoulders":
			return _feedback_head_shoulders(metrics)
		"inverse_head_shoulders":
			return _feedback_inverse_head_shoulders(metrics)
		"ascending_triangle":
			return _feedback_ascending_triangle(metrics)
		"descending_triangle":
			return _feedback_descending_triangle(metrics)
		"bull_flag":
			return _feedback_bull_flag(metrics)
		"sma_support_bounce":
			return _feedback_sma_support_bounce(metrics)
		"sma_resistance_rejection":
			return _feedback_sma_resistance_rejection(metrics)
		"volume_confirmation":
			return _feedback_volume_confirmation(metrics)
	return _state(STATE_WEAK, "Unknown pattern type.", "Choose a pattern type that matches the marked region.", "mixed")


func _feedback_range(metrics: Dictionary) -> Dictionary:
	var range_width: float = float(metrics.get("range_width_pct", 1.0))
	var close_position: float = float(metrics.get("close_position", 0.5))
	var move_pct: float = absf(float(metrics.get("move_pct", 0.0)))
	if range_width <= 0.08 and close_position >= 0.18 and close_position <= 0.82:
		return _state(STATE_GOOD, "price stayed inside a tight band and did not resolve strongly.", "Breakout above the range high or breakdown below the range low changes the read.", "mixed")
	if range_width <= 0.14 and move_pct <= 0.08:
		return _state(STATE_PLAUSIBLE, "price is compressing, but the range is still a bit wide.", "A close outside the marked range should force a review.", "mixed")
	if close_position > 0.92 or close_position < 0.08:
		return _state(STATE_CONTRADICTED, "the latest close is already pressing outside the marked range.", "Use the range only if price returns inside it.", "negative")
	return _state(STATE_WEAK, "the selected region does not show a clean consolidation.", "Wait for a tighter band or clearer support/resistance edges.", "mixed")


func _feedback_breakout(metrics: Dictionary) -> Dictionary:
	var prior_high: float = float(metrics.get("prior_high", 0.0))
	var selected_high: float = float(metrics.get("selected_high", 0.0))
	var last_close: float = float(metrics.get("last_close", 0.0))
	var move_pct: float = float(metrics.get("move_pct", 0.0))
	var volume_ratio: float = float(metrics.get("volume_ratio", 0.0))
	if prior_high > 0.0 and last_close >= prior_high * 1.01 and move_pct > 0.015:
		if volume_ratio >= 1.2:
			return _state(STATE_GOOD, "price cleared the prior range and volume expanded versus the recent baseline.", "A close back below the prior range high weakens the breakout.", "positive")
		return _state(STATE_PLAUSIBLE, "price cleared the prior range, but volume confirmation is still modest.", "A close back below the prior range high weakens the breakout.", "positive")
	if selected_high >= prior_high * 1.005 and last_close < prior_high:
		return _state(STATE_CONTRADICTED, "price poked above resistance but failed to close through it.", "Treat it as failed unless price reclaims the marked high.", "negative")
	if move_pct > 0.0:
		return _state(STATE_WEAK, "price is rising, but it has not clearly cleared the prior range.", "Wait for a close above the marked resistance.", "mixed")
	return _state(STATE_CONTRADICTED, "the selected region moved against a bullish breakout claim.", "Do not call it a breakout unless price retakes resistance.", "negative")


func _feedback_failed_breakout(metrics: Dictionary) -> Dictionary:
	var prior_high: float = float(metrics.get("prior_high", 0.0))
	var selected_high: float = float(metrics.get("selected_high", 0.0))
	var last_close: float = float(metrics.get("last_close", 0.0))
	var first_close: float = float(metrics.get("first_close", 0.0))
	if prior_high > 0.0 and selected_high >= prior_high * 1.01 and last_close <= prior_high * 0.995:
		return _state(STATE_GOOD, "price broke above the prior range but closed back below it.", "A strong reclaim above the marked high invalidates the failed-breakout read.", "negative")
	if prior_high > 0.0 and selected_high >= prior_high and last_close < selected_high and last_close <= first_close:
		return _state(STATE_PLAUSIBLE, "there was an upside attempt followed by fading closes, but the failure is not decisive yet.", "A close above the marked high cancels this warning.", "negative")
	if prior_high > 0.0 and last_close >= prior_high * 1.01:
		return _state(STATE_CONTRADICTED, "price is still holding above the prior range.", "Only revisit this if price loses the breakout level.", "positive")
	return _state(STATE_WEAK, "the marked area does not show a clear breakout attempt first.", "Mark the failed push and the close back inside the range.", "mixed")


func _feedback_pullback_support(metrics: Dictionary) -> Dictionary:
	var prior_low: float = float(metrics.get("prior_low", 0.0))
	var selected_low: float = float(metrics.get("selected_low", 0.0))
	var last_close: float = float(metrics.get("last_close", 0.0))
	var first_close: float = float(metrics.get("first_close", 0.0))
	if prior_low <= 0.0:
		prior_low = selected_low
	var touched_support: bool = selected_low <= prior_low * 1.03 and selected_low >= prior_low * 0.94
	if touched_support and last_close >= selected_low * 1.03 and last_close >= first_close * 0.98:
		return _state(STATE_GOOD, "price tested the support area and rebounded from the marked low.", "A close below the support low breaks the pullback thesis.", "positive")
	if touched_support and last_close >= prior_low:
		return _state(STATE_PLAUSIBLE, "price is holding the support area, but the rebound is still early.", "A decisive close below support should stop the setup.", "positive")
	if last_close < prior_low * 0.98:
		return _state(STATE_CONTRADICTED, "price closed below the support level instead of holding it.", "Do not treat this as support unless price reclaims the level.", "negative")
	return _state(STATE_WEAK, "the marked lows are not close enough to a support reference.", "Mark the test of support and the first rebound attempt.", "mixed")


func _feedback_higher_lows(metrics: Dictionary) -> Dictionary:
	var higher_low_count: int = int(metrics.get("higher_low_count", 0))
	var move_pct: float = float(metrics.get("move_pct", 0.0))
	var lower_low_break: bool = bool(metrics.get("lower_low_break", false))
	if higher_low_count >= 2 and move_pct >= -0.01:
		return _state(STATE_GOOD, "the marked lows are stepping upward while price holds its structure.", "A new low below the marked sequence weakens the pattern.", "positive")
	if higher_low_count >= 1 and not lower_low_break:
		return _state(STATE_PLAUSIBLE, "there is at least one higher low, but the sequence is still young.", "Wait for another higher low or a push through resistance.", "positive")
	if lower_low_break:
		return _state(STATE_CONTRADICTED, "the latest low undercut the sequence instead of stepping higher.", "The read improves only if price rebuilds above that low.", "negative")
	return _state(STATE_WEAK, "the selected region does not yet show enough rising lows.", "Mark at least two swing lows that step upward.", "mixed")


func _feedback_lower_highs(metrics: Dictionary) -> Dictionary:
	var lower_high_count: int = int(metrics.get("lower_high_count", 0))
	var move_pct: float = float(metrics.get("move_pct", 0.0))
	var higher_high_break: bool = bool(metrics.get("higher_high_break", false))
	if lower_high_count >= 2 and move_pct <= 0.01:
		return _state(STATE_GOOD, "the marked highs are stepping downward and price has not reclaimed the sequence.", "A close above the marked high sequence weakens the bearish read.", "negative")
	if lower_high_count >= 1 and not higher_high_break:
		return _state(STATE_PLAUSIBLE, "there is at least one lower high, but the sequence needs more confirmation.", "Wait for another lower high or a breakdown through support.", "negative")
	if higher_high_break:
		return _state(STATE_CONTRADICTED, "price broke above the prior high instead of respecting lower highs.", "Do not use this read unless price fails again below resistance.", "positive")
	return _state(STATE_WEAK, "the selected region does not yet show enough falling highs.", "Mark at least two swing highs that step downward.", "mixed")


func _feedback_breakout_retest(metrics: Dictionary) -> Dictionary:
	var prior_high: float = float(metrics.get("prior_high", 0.0))
	var selected_low: float = float(metrics.get("selected_low", 0.0))
	var last_close: float = float(metrics.get("last_close", 0.0))
	var volume_ratio: float = float(metrics.get("volume_ratio", 0.0))
	if prior_high > 0.0 and selected_low <= prior_high * 1.035 and selected_low >= prior_high * 0.965 and last_close >= prior_high * 1.01:
		if volume_ratio >= 1.12:
			return _state(STATE_GOOD, "price retested the breakout area and reclaimed it with better activity.", "A close back below the retest low weakens the breakout retest.", "positive")
		return _state(STATE_PLAUSIBLE, "price retested the breakout area, but volume support is still modest.", "A close back below the retest low weakens the breakout retest.", "positive")
	if prior_high > 0.0 and last_close < prior_high * 0.985:
		return _state(STATE_CONTRADICTED, "price lost the breakout area instead of holding the retest.", "Only revisit this if price reclaims the breakout level.", "negative")
	return _state(STATE_WEAK, "the marked region does not clearly retest a prior breakout level.", "Mark the pullback into old resistance and the rebound from that area.", "mixed")


func _feedback_breakdown(metrics: Dictionary) -> Dictionary:
	var prior_low: float = float(metrics.get("prior_low", 0.0))
	var selected_low: float = float(metrics.get("selected_low", 0.0))
	var last_close: float = float(metrics.get("last_close", 0.0))
	var move_pct: float = float(metrics.get("move_pct", 0.0))
	var volume_ratio: float = float(metrics.get("volume_ratio", 0.0))
	if prior_low > 0.0 and last_close <= prior_low * 0.985 and selected_low < prior_low:
		if volume_ratio >= 1.2:
			return _state(STATE_GOOD, "price closed below prior support and volume expanded on the move.", "A strong reclaim above broken support cancels the breakdown read.", "negative")
		return _state(STATE_PLAUSIBLE, "price broke support, but volume confirmation is still only moderate.", "A reclaim above broken support cancels the breakdown read.", "negative")
	if move_pct < -0.02:
		return _state(STATE_WEAK, "price is falling, but the marked region does not clearly break prior support.", "Mark the support area and the close below it.", "mixed")
	return _state(STATE_CONTRADICTED, "the selected region does not move like a support breakdown.", "Do not call breakdown until price closes below support.", "positive")


func _feedback_double_bottom(metrics: Dictionary) -> Dictionary:
	var bars: Array = metrics.get("selected_bars", [])
	if bars.size() < 6:
		return _state(STATE_WEAK, "a double bottom needs more bars to show two tests and a neckline.", "Mark both lows plus the neckline recovery.", "mixed")
	var left: Array = _bar_slice_fraction(bars, 0.0, 0.45)
	var right: Array = _bar_slice_fraction(bars, 0.45, 1.0)
	var left_low: float = _lowest_low(left)
	var right_low: float = _lowest_low(right)
	var last_close: float = _last_close(bars)
	var neckline: float = _highest_high(_bar_slice_fraction(bars, 0.20, 0.72))
	var lows_match: bool = _near_ratio(left_low, right_low, 0.065)
	if lows_match and last_close >= neckline * 1.01:
		return _state(STATE_GOOD, "both lows held near the same area and price reclaimed the neckline.", "A close below the second low breaks the double-bottom read.", "positive")
	if lows_match and last_close >= max(left_low, right_low) * 1.05:
		return _state(STATE_PLAUSIBLE, "two similar lows are visible, but the neckline reclaim still needs confirmation.", "A close below the second low breaks the setup.", "positive")
	if last_close < min(left_low, right_low) * 0.985:
		return _state(STATE_CONTRADICTED, "price undercut the base instead of holding the second low.", "Wait for price to rebuild above the failed low.", "negative")
	return _state(STATE_WEAK, "the marked lows are not similar enough for a clean double bottom.", "Mark two lows at a similar level with a rebound between them.", "mixed")


func _feedback_double_top(metrics: Dictionary) -> Dictionary:
	var bars: Array = metrics.get("selected_bars", [])
	if bars.size() < 6:
		return _state(STATE_WEAK, "a double top needs more bars to show two peaks and a neckline.", "Mark both highs plus the support break.", "mixed")
	var left: Array = _bar_slice_fraction(bars, 0.0, 0.45)
	var right: Array = _bar_slice_fraction(bars, 0.45, 1.0)
	var left_high: float = _highest_high(left)
	var right_high: float = _highest_high(right)
	var neckline: float = _lowest_low(_bar_slice_fraction(bars, 0.20, 0.72))
	var last_close: float = _last_close(bars)
	var highs_match: bool = _near_ratio(left_high, right_high, 0.060)
	if highs_match and last_close <= neckline * 0.99:
		return _state(STATE_GOOD, "both highs failed near the same area and price lost the neckline.", "A close above the second top cancels the double-top warning.", "negative")
	if highs_match and last_close < min(left_high, right_high) * 0.95:
		return _state(STATE_PLAUSIBLE, "two similar highs are visible, but the support break is not decisive yet.", "A close above the second top cancels the warning.", "negative")
	if last_close > max(left_high, right_high) * 1.01:
		return _state(STATE_CONTRADICTED, "price broke above the top instead of rejecting it.", "Only revisit this if the breakout fails.", "positive")
	return _state(STATE_WEAK, "the marked highs are not similar enough for a clean double top.", "Mark two highs at a similar level with a pullback between them.", "mixed")


func _feedback_cup_handle(metrics: Dictionary) -> Dictionary:
	var bars: Array = metrics.get("selected_bars", [])
	if bars.size() < 8:
		return _state(STATE_WEAK, "a cup and handle needs enough bars for the rounded base and handle.", "Mark the cup, handle, and breakout attempt together.", "mixed")
	var first_close: float = _first_close(bars)
	var middle_low: float = _lowest_low(_bar_slice_fraction(bars, 0.18, 0.62))
	var right_high: float = _highest_high(_bar_slice_fraction(bars, 0.58, 0.86))
	var handle_low: float = _lowest_low(_bar_slice_fraction(bars, 0.72, 0.94))
	var last_close: float = _last_close(bars)
	var cup_depth: float = (first_close - middle_low) / max(first_close, 1.0)
	var handle_depth: float = (right_high - handle_low) / max(right_high, 1.0)
	if cup_depth >= 0.08 and cup_depth <= 0.38 and handle_depth <= 0.16 and last_close >= right_high * 0.995:
		return _state(STATE_GOOD, "price formed a rounded recovery, built a smaller handle, and returned to the rim.", "A close below the handle low weakens the cup-and-handle read.", "positive")
	if cup_depth >= 0.06 and handle_depth <= 0.22 and last_close >= first_close * 0.96:
		return _state(STATE_PLAUSIBLE, "the rounded recovery is visible, but the handle or breakout still needs confirmation.", "A close below the handle low weakens the setup.", "positive")
	if last_close < middle_low * 1.04:
		return _state(STATE_CONTRADICTED, "price is still near the bottom of the cup instead of recovering.", "Wait for the right side and handle to form.", "negative")
	return _state(STATE_WEAK, "the marked region does not show a clear cup and handle.", "Look for rounded recovery followed by a smaller pullback.", "mixed")


func _feedback_head_shoulders(metrics: Dictionary) -> Dictionary:
	var bars: Array = metrics.get("selected_bars", [])
	if bars.size() < 7:
		return _state(STATE_WEAK, "head and shoulders needs enough bars for left shoulder, head, right shoulder, and neckline.", "Mark the full topping structure.", "mixed")
	var left_high: float = _highest_high(_bar_slice_fraction(bars, 0.00, 0.34))
	var head_high: float = _highest_high(_bar_slice_fraction(bars, 0.28, 0.62))
	var right_high: float = _highest_high(_bar_slice_fraction(bars, 0.56, 0.86))
	var neckline: float = _lowest_low(_bar_slice_fraction(bars, 0.24, 0.78))
	var last_close: float = _last_close(bars)
	if head_high > left_high * 1.035 and head_high > right_high * 1.035 and _near_ratio(left_high, right_high, 0.12) and last_close < neckline * 0.995:
		return _state(STATE_GOOD, "the head stands above both shoulders and price broke the neckline.", "A reclaim above the right shoulder weakens the topping read.", "negative")
	if head_high > left_high and head_high > right_high and last_close < right_high:
		return _state(STATE_PLAUSIBLE, "the topping shape is visible, but the neckline break needs more proof.", "A reclaim above the right shoulder weakens the read.", "negative")
	return _state(STATE_WEAK, "the marked region does not show a clear head above two shoulders.", "Mark the left shoulder, head, right shoulder, and neckline.", "mixed")


func _feedback_inverse_head_shoulders(metrics: Dictionary) -> Dictionary:
	var bars: Array = metrics.get("selected_bars", [])
	if bars.size() < 7:
		return _state(STATE_WEAK, "inverse head and shoulders needs enough bars for both shoulders, head, and neckline.", "Mark the full bottoming structure.", "mixed")
	var left_low: float = _lowest_low(_bar_slice_fraction(bars, 0.00, 0.34))
	var head_low: float = _lowest_low(_bar_slice_fraction(bars, 0.28, 0.62))
	var right_low: float = _lowest_low(_bar_slice_fraction(bars, 0.56, 0.86))
	var neckline: float = _highest_high(_bar_slice_fraction(bars, 0.24, 0.78))
	var last_close: float = _last_close(bars)
	if head_low < left_low * 0.965 and head_low < right_low * 0.965 and _near_ratio(left_low, right_low, 0.12) and last_close > neckline * 1.005:
		return _state(STATE_GOOD, "the head undercut both shoulders and price reclaimed the neckline.", "A close below the right shoulder low weakens the bottoming read.", "positive")
	if head_low < left_low and head_low < right_low and last_close > right_low:
		return _state(STATE_PLAUSIBLE, "the bottoming shape is visible, but the neckline reclaim needs more proof.", "A close below the right shoulder low weakens the read.", "positive")
	return _state(STATE_WEAK, "the marked region does not show a clear inverse head and shoulders.", "Mark the left shoulder, deeper head, right shoulder, and neckline.", "mixed")


func _feedback_ascending_triangle(metrics: Dictionary) -> Dictionary:
	var bars: Array = metrics.get("selected_bars", [])
	var higher_low_count: int = int(metrics.get("higher_low_count", 0))
	var top_range: float = _highest_high(bars) - _highest_high(_bar_slice_fraction(bars, 0.0, 0.5))
	var top_reference: float = max(_highest_high(bars), 1.0)
	var last_close: float = _last_close(bars)
	if higher_low_count >= 2 and absf(top_range) / top_reference <= 0.055 and last_close >= _highest_high(bars) * 0.96:
		return _state(STATE_GOOD, "lows are rising while sellers defend a similar resistance area.", "A close below the latest higher low breaks the triangle read.", "positive")
	if higher_low_count >= 1:
		return _state(STATE_PLAUSIBLE, "the lows are starting to rise, but the resistance line still needs cleaner tests.", "A close below the latest higher low weakens the setup.", "positive")
	return _state(STATE_WEAK, "the marked region does not show enough rising lows for an ascending triangle.", "Mark a flat resistance area with higher lows underneath.", "mixed")


func _feedback_descending_triangle(metrics: Dictionary) -> Dictionary:
	var bars: Array = metrics.get("selected_bars", [])
	var lower_high_count: int = int(metrics.get("lower_high_count", 0))
	var bottom_range: float = _lowest_low(bars) - _lowest_low(_bar_slice_fraction(bars, 0.0, 0.5))
	var bottom_reference: float = max(_lowest_low(bars), 1.0)
	var last_close: float = _last_close(bars)
	if lower_high_count >= 2 and absf(bottom_range) / bottom_reference <= 0.055 and last_close <= _lowest_low(bars) * 1.06:
		return _state(STATE_GOOD, "highs are falling while buyers defend a similar support area.", "A close above the latest lower high breaks the bearish triangle read.", "negative")
	if lower_high_count >= 1:
		return _state(STATE_PLAUSIBLE, "the highs are starting to fall, but the support line still needs cleaner tests.", "A close above the latest lower high weakens the warning.", "negative")
	return _state(STATE_WEAK, "the marked region does not show enough falling highs for a descending triangle.", "Mark a flat support area with lower highs pressing into it.", "mixed")


func _feedback_bull_flag(metrics: Dictionary) -> Dictionary:
	var previous_bars: Array = metrics.get("previous_bars", [])
	var selected_bars: Array = metrics.get("selected_bars", [])
	var prior_move: float = _move_pct(previous_bars)
	var flag_move: float = float(metrics.get("move_pct", 0.0))
	var range_width: float = float(metrics.get("range_width_pct", 1.0))
	var last_close: float = float(metrics.get("last_close", 0.0))
	if prior_move >= 0.045 and flag_move >= -0.055 and flag_move <= 0.025 and range_width <= 0.16:
		if last_close >= _highest_high(selected_bars) * 0.96:
			return _state(STATE_GOOD, "a strong prior move cooled into a controlled flag near the highs.", "A close below the flag low breaks the continuation read.", "positive")
		return _state(STATE_PLAUSIBLE, "the prior move and controlled pullback fit a flag, but breakout is not confirmed.", "A close below the flag low breaks the setup.", "positive")
	if flag_move < -0.09:
		return _state(STATE_CONTRADICTED, "the pullback is too deep for a healthy bull flag.", "Wait for price to rebuild a tighter flag.", "negative")
	return _state(STATE_WEAK, "the marked region lacks a strong pole or controlled flag.", "Mark the pause after a sharp advance.", "mixed")


func _feedback_sma_support_bounce(metrics: Dictionary) -> Dictionary:
	var bars: Array = metrics.get("selected_bars", [])
	var all_bars: Array = metrics.get("previous_bars", []) + bars
	var sma_value: float = _sma_from_bars(all_bars, 20)
	var selected_low: float = float(metrics.get("selected_low", 0.0))
	var last_close: float = float(metrics.get("last_close", 0.0))
	if sma_value > 0.0 and selected_low <= sma_value * 1.035 and selected_low >= sma_value * 0.94 and last_close >= sma_value * 1.01:
		return _state(STATE_GOOD, "price tested the SMA area and bounced back above it.", "A close below the marked SMA-test low breaks the support read.", "positive")
	if sma_value > 0.0 and last_close >= sma_value:
		return _state(STATE_PLAUSIBLE, "price is holding around the SMA, but the bounce still needs stronger follow-through.", "A close below the SMA-test low weakens the read.", "positive")
	if sma_value > 0.0 and last_close < sma_value * 0.97:
		return _state(STATE_CONTRADICTED, "price lost the SMA instead of bouncing from it.", "Do not use the SMA as support until price reclaims it.", "negative")
	return _state(STATE_WEAK, "there is not enough SMA context for a support-bounce claim.", "Use a longer region or turn on an SMA that price has been respecting.", "mixed")


func _feedback_sma_resistance_rejection(metrics: Dictionary) -> Dictionary:
	var bars: Array = metrics.get("selected_bars", [])
	var all_bars: Array = metrics.get("previous_bars", []) + bars
	var sma_value: float = _sma_from_bars(all_bars, 20)
	var selected_high: float = float(metrics.get("selected_high", 0.0))
	var last_close: float = float(metrics.get("last_close", 0.0))
	if sma_value > 0.0 and selected_high >= sma_value * 0.965 and selected_high <= sma_value * 1.07 and last_close <= sma_value * 0.99:
		return _state(STATE_GOOD, "price rallied into the SMA area and rejected below it.", "A close above the marked rejection high cancels the resistance read.", "negative")
	if sma_value > 0.0 and last_close <= sma_value:
		return _state(STATE_PLAUSIBLE, "price is still below the SMA, but the rejection needs cleaner follow-through.", "A close above the rejection high weakens the warning.", "negative")
	if sma_value > 0.0 and last_close > sma_value * 1.03:
		return _state(STATE_CONTRADICTED, "price reclaimed the SMA instead of rejecting from it.", "Only revisit this if price loses the SMA again.", "positive")
	return _state(STATE_WEAK, "there is not enough SMA context for a resistance-rejection claim.", "Use a longer region or turn on an SMA that price has been respecting.", "mixed")


func _feedback_volume_confirmation(metrics: Dictionary) -> Dictionary:
	var volume_ratio: float = float(metrics.get("volume_ratio", 0.0))
	var move_pct: float = float(metrics.get("move_pct", 0.0))
	if volume_ratio <= 0.0:
		return _state(STATE_WEAK, "volume data is not available for this region.", "Use price structure first, then revisit volume when the chart has volume bars.", "mixed")
	if volume_ratio >= 1.5 and absf(move_pct) >= 0.015:
		var direction_text: String = "upside" if move_pct > 0.0 else "downside"
		var impact: String = "positive" if move_pct > 0.0 else "negative"
		return _state(STATE_GOOD, "volume expanded strongly with a clear %s price move." % direction_text, "A high-volume reversal in the opposite direction cancels the confirmation.", impact)
	if volume_ratio >= 1.2:
		return _state(STATE_PLAUSIBLE, "volume is above average, but price follow-through is not decisive yet.", "Look for the next close to confirm direction.", "mixed")
	if absf(move_pct) >= 0.03 and volume_ratio < 0.8:
		return _state(STATE_CONTRADICTED, "price moved without matching volume support.", "Wait for volume to expand before calling it confirmation.", "mixed")
	return _state(STATE_WEAK, "volume is near normal, so it does not add much evidence yet.", "Look for volume at least 20% above recent average.", "mixed")


func _bar_slice_fraction(bars: Array, start_fraction: float, end_fraction: float) -> Array:
	if bars.is_empty():
		return []
	var start_index: int = clamp(int(floor(float(bars.size()) * start_fraction)), 0, bars.size() - 1)
	var end_index: int = clamp(int(ceil(float(bars.size()) * end_fraction)), start_index + 1, bars.size())
	return bars.slice(start_index, end_index)


func _first_close(bars: Array) -> float:
	if bars.is_empty():
		return 0.0
	var bar: Dictionary = bars[0]
	return float(bar.get("close", bar.get("open", 0.0)))


func _last_close(bars: Array) -> float:
	if bars.is_empty():
		return 0.0
	var bar: Dictionary = bars[bars.size() - 1]
	return float(bar.get("close", bar.get("open", 0.0)))


func _lowest_low(bars: Array) -> float:
	if bars.is_empty():
		return 0.0
	var first_bar: Dictionary = bars[0]
	var value: float = float(first_bar.get("low", first_bar.get("close", 0.0)))
	for bar_value in bars:
		var bar: Dictionary = bar_value
		value = min(value, float(bar.get("low", bar.get("close", value))))
	return value


func _highest_high(bars: Array) -> float:
	if bars.is_empty():
		return 0.0
	var first_bar: Dictionary = bars[0]
	var value: float = float(first_bar.get("high", first_bar.get("close", 0.0)))
	for bar_value in bars:
		var bar: Dictionary = bar_value
		value = max(value, float(bar.get("high", bar.get("close", value))))
	return value


func _near_ratio(left_value: float, right_value: float, tolerance: float) -> bool:
	var ratio_reference: float = max(min(absf(left_value), absf(right_value)), 1.0)
	return absf(left_value - right_value) / ratio_reference <= tolerance


func _move_pct(bars: Array) -> float:
	if bars.size() < 2:
		return 0.0
	var first_value: float = _first_close(bars)
	if is_zero_approx(first_value):
		return 0.0
	return (_last_close(bars) - first_value) / first_value


func _sma_from_bars(bars: Array, period: int) -> float:
	if period <= 0 or bars.size() < period:
		return 0.0
	var total: float = 0.0
	for bar_index in range(bars.size() - period, bars.size()):
		var bar: Dictionary = bars[bar_index]
		total += float(bar.get("close", bar.get("open", 0.0)))
	return total / float(period)


func _build_metrics(selected_bars: Array, previous_bars: Array) -> Dictionary:
	var first_bar: Dictionary = selected_bars[0]
	var last_bar: Dictionary = selected_bars[selected_bars.size() - 1]
	var first_close: float = max(float(first_bar.get("close", first_bar.get("open", 0.0))), 0.0)
	var last_close: float = max(float(last_bar.get("close", first_close)), 0.0)
	var selected_high: float = first_close
	var selected_low: float = first_close
	for bar_value in selected_bars:
		var bar: Dictionary = bar_value
		selected_high = max(selected_high, float(bar.get("high", bar.get("close", first_close))))
		selected_low = min(selected_low, float(bar.get("low", bar.get("close", first_close))))

	var prior_high: float = selected_high
	var prior_low: float = selected_low
	if not previous_bars.is_empty():
		prior_high = float(previous_bars[0].get("high", previous_bars[0].get("close", first_close)))
		prior_low = float(previous_bars[0].get("low", previous_bars[0].get("close", first_close)))
		for previous_value in previous_bars:
			var previous_bar: Dictionary = previous_value
			prior_high = max(prior_high, float(previous_bar.get("high", previous_bar.get("close", first_close))))
			prior_low = min(prior_low, float(previous_bar.get("low", previous_bar.get("close", first_close))))

	var selected_mid: float = max((selected_high + selected_low) * 0.5, 0.0001)
	var range_width_pct: float = (selected_high - selected_low) / selected_mid
	var close_position: float = clamp((last_close - selected_low) / max(selected_high - selected_low, 0.0001), 0.0, 1.0)
	var move_pct: float = 0.0
	if first_close > 0.0:
		move_pct = (last_close - first_close) / first_close

	return {
		"first_close": first_close,
		"last_close": last_close,
		"selected_high": selected_high,
		"selected_low": selected_low,
		"prior_high": prior_high,
		"prior_low": prior_low,
		"range_width_pct": range_width_pct,
		"close_position": close_position,
		"move_pct": move_pct,
		"volume_ratio": _volume_ratio(selected_bars, previous_bars),
		"higher_low_count": _higher_low_count(selected_bars),
		"lower_high_count": _lower_high_count(selected_bars),
		"lower_low_break": _has_lower_low_break(selected_bars),
		"higher_high_break": _has_higher_high_break(selected_bars),
		"selected_bars": selected_bars.duplicate(true),
		"previous_bars": previous_bars.duplicate(true)
	}


func _higher_low_count(bars: Array) -> int:
	var count: int = 0
	var previous_low: float = float(bars[0].get("low", bars[0].get("close", 0.0)))
	for index in range(1, bars.size()):
		var low_value: float = float(bars[index].get("low", bars[index].get("close", 0.0)))
		if low_value > previous_low * 1.002:
			count += 1
		previous_low = low_value
	return count


func _lower_high_count(bars: Array) -> int:
	var count: int = 0
	var previous_high: float = float(bars[0].get("high", bars[0].get("close", 0.0)))
	for index in range(1, bars.size()):
		var high_value: float = float(bars[index].get("high", bars[index].get("close", 0.0)))
		if high_value < previous_high * 0.998:
			count += 1
		previous_high = high_value
	return count


func _has_lower_low_break(bars: Array) -> bool:
	if bars.size() < 2:
		return false
	var latest_low: float = float(bars[bars.size() - 1].get("low", bars[bars.size() - 1].get("close", 0.0)))
	for index in range(0, bars.size() - 1):
		var low_value: float = float(bars[index].get("low", bars[index].get("close", 0.0)))
		if latest_low < low_value * 0.995:
			return true
	return false


func _has_higher_high_break(bars: Array) -> bool:
	if bars.size() < 2:
		return false
	var latest_high: float = float(bars[bars.size() - 1].get("high", bars[bars.size() - 1].get("close", 0.0)))
	for index in range(0, bars.size() - 1):
		var high_value: float = float(bars[index].get("high", bars[index].get("close", 0.0)))
		if latest_high > high_value * 1.005:
			return true
	return false


func _volume_ratio(selected_bars: Array, previous_bars: Array) -> float:
	var selected_avg: float = _average_volume(selected_bars)
	if selected_avg <= 0.0:
		return 0.0
	var previous_avg: float = _average_volume(previous_bars)
	if previous_avg <= 0.0:
		previous_avg = selected_avg
	return selected_avg / max(previous_avg, 1.0)


func _average_volume(bars: Array) -> float:
	var total: float = 0.0
	var count: int = 0
	for bar_value in bars:
		if typeof(bar_value) != TYPE_DICTIONARY:
			continue
		var bar: Dictionary = bar_value
		var volume_value: float = float(bar.get("volume_shares", 0.0))
		if volume_value <= 0.0:
			volume_value = float(bar.get("value", 0.0))
		if volume_value <= 0.0:
			continue
		total += volume_value
		count += 1
	return total / float(count) if count > 0 else 0.0


func _normalized_bars(source_bars: Variant) -> Array:
	var rows: Array = []
	if typeof(source_bars) != TYPE_ARRAY:
		return rows
	for bar_value in source_bars:
		if typeof(bar_value) != TYPE_DICTIONARY:
			continue
		rows.append(bar_value.duplicate(true))
	return rows


func _bar_index_for_anchor(anchor_value: Variant, bars: Array) -> int:
	if typeof(anchor_value) != TYPE_DICTIONARY:
		return -1
	var anchor: Dictionary = anchor_value
	var target_key: String = str(anchor.get("bar_key", ""))
	if not target_key.is_empty():
		for index in range(bars.size()):
			if _bar_key_from_bar(bars[index], index) == target_key:
				return index

	var target_serial: int = int(anchor.get("date_serial", 0))
	if target_serial > 0:
		var best_index: int = 0
		var best_distance: int = 2147483647
		for index in range(bars.size()):
			var serial_value: int = _date_serial_from_trade_date(bars[index].get("trade_date", {}))
			if serial_value <= 0:
				continue
			var distance: int = absi(serial_value - target_serial)
			if distance < best_distance:
				best_distance = distance
				best_index = index
		return best_index
	return -1


func _bar_key_from_bar(bar: Dictionary, fallback_index: int) -> String:
	var trade_date: Dictionary = bar.get("trade_date", {})
	if not trade_date.is_empty():
		return "%04d-%02d-%02d" % [
			int(trade_date.get("year", 0)),
			int(trade_date.get("month", 0)),
			int(trade_date.get("day", 0))
		]
	return "index:%d" % fallback_index


func _date_serial_from_trade_date(trade_date: Dictionary) -> int:
	if trade_date.is_empty():
		return 0
	return int(trade_date.get("year", 0)) * 10000 + int(trade_date.get("month", 0)) * 100 + int(trade_date.get("day", 0))


func _normalize_pattern_id(pattern_id: String) -> String:
	var normalized: String = pattern_id.to_lower().strip_edges()
	for pattern_value in PATTERNS:
		var pattern: Dictionary = pattern_value
		if str(pattern.get("id", "")) == normalized:
			return normalized
	return ""


func _pattern_label(pattern_id: String) -> String:
	for pattern_value in PATTERNS:
		var pattern: Dictionary = pattern_value
		if str(pattern.get("id", "")) == pattern_id:
			return str(pattern.get("label", pattern_id.capitalize()))
	return pattern_id.capitalize()


func _region_label(bars: Array) -> String:
	if bars.is_empty():
		return "the marked region"
	var start_label: String = _format_trade_date(bars[0].get("trade_date", {}))
	var end_label: String = _format_trade_date(bars[bars.size() - 1].get("trade_date", {}))
	if start_label.is_empty() and end_label.is_empty():
		return "the marked region"
	if start_label == end_label:
		return start_label
	return "%s - %s" % [start_label, end_label]


func _format_trade_date(trade_date: Dictionary) -> String:
	if trade_date.is_empty():
		return ""
	return "%04d-%02d-%02d" % [
		int(trade_date.get("year", 0)),
		int(trade_date.get("month", 0)),
		int(trade_date.get("day", 0))
	]


func _state(state: String, reason: String, invalidation: String, impact: String) -> Dictionary:
	return {
		"state": state,
		"reason": reason,
		"invalidation": invalidation,
		"impact": impact
	}


func _failure(message: String) -> Dictionary:
	return {
		"success": false,
		"message": message,
		"feedback_state": STATE_WEAK,
		"detail": message
	}


func _next_check_for_state(state: String) -> String:
	match state:
		STATE_GOOD:
			return "Watch whether the next close respects the marked structure."
		STATE_PLAUSIBLE:
			return "Wait for one more close or volume confirmation before treating it as support."
		STATE_WEAK:
			return "Use the mark as a question and look for a cleaner structure."
		STATE_CONTRADICTED:
			return "Do not use this as confirmation unless price rebuilds the marked level."
	return "Recheck after the next close."
