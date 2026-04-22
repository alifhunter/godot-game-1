extends RefCounted

const RANGE_DEFINITIONS := {
	"1d": {"id": "1d", "label": "1D", "trading_days": 1},
	"1w": {"id": "1w", "label": "1W", "trading_days": 5},
	"1m": {"id": "1m", "label": "1M", "trading_days": 21},
	"1y": {"id": "1y", "label": "1Y", "trading_days": 252},
	"5y": {"id": "5y", "label": "5Y", "trading_days": 1260},
	"ytd": {"id": "ytd", "label": "YTD", "mode": "ytd"}
}

const INDICATOR_CATALOG := {
	"sma_20": {
		"id": "sma_20",
		"label": "SMA 20",
		"plot_kind": "overlay",
		"calculation": "sma",
		"lookback": 20,
		"track_id": "technical_basics",
		"perk_id": "indicator_sma_20",
		"sort_order": 20
	},
	"ema_20": {
		"id": "ema_20",
		"label": "EMA 20",
		"plot_kind": "overlay",
		"calculation": "ema",
		"lookback": 20,
		"track_id": "momentum_read",
		"perk_id": "indicator_ema_20",
		"sort_order": 30
	},
	"sma_50": {
		"id": "sma_50",
		"label": "SMA 50",
		"plot_kind": "overlay",
		"calculation": "sma",
		"lookback": 50,
		"track_id": "trend_structure",
		"perk_id": "indicator_sma_50",
		"sort_order": 40
	},
	"rsi_14": {
		"id": "rsi_14",
		"label": "RSI 14",
		"plot_kind": "panel",
		"calculation": "rsi",
		"lookback": 14,
		"track_id": "momentum_read",
		"perk_id": "indicator_rsi_14",
		"sort_order": 50
	}
}


func get_range_label(range_id: String) -> String:
	var normalized_range_id: String = _normalize_range_id(range_id)
	return str(RANGE_DEFINITIONS[normalized_range_id].get("label", normalized_range_id.to_upper()))


func get_available_ranges() -> Array:
	var ranges: Array = []
	for range_id in RANGE_DEFINITIONS.keys():
		ranges.append(RANGE_DEFINITIONS[range_id].duplicate(true))
	ranges.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var left_index: int = _range_sort_index(str(a.get("id", "")))
		var right_index: int = _range_sort_index(str(b.get("id", "")))
		return left_index < right_index
	)
	return ranges


func get_indicator_catalog() -> Array:
	var indicators: Array = []
	for indicator_id in INDICATOR_CATALOG.keys():
		indicators.append(INDICATOR_CATALOG[indicator_id].duplicate(true))
	indicators.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0))
	)
	return indicators


func build_company_chart_snapshot(
	runtime: Dictionary,
	range_id: String = "1m",
	enabled_indicator_ids: Array = []
) -> Dictionary:
	return build_chart_snapshot_from_bars(runtime.get("price_bars", []), range_id, enabled_indicator_ids)


func build_chart_snapshot_from_bars(
	price_bars: Array,
	range_id: String = "1m",
	enabled_indicator_ids: Array = []
) -> Dictionary:
	var full_bars: Array = _normalize_bars(price_bars)
	if full_bars.is_empty():
		return {}

	var normalized_range_id: String = _normalize_range_id(range_id)
	var visible_bars: Array = _slice_visible_bars(full_bars, normalized_range_id)
	if visible_bars.is_empty():
		return {}

	var display_bars: Array = _build_display_bars(visible_bars, normalized_range_id)
	if display_bars.is_empty():
		return {}

	var primary_values: Array = _build_primary_values(display_bars)
	var start_price: float = float(primary_values[0]) if not primary_values.is_empty() else 0.0
	var end_price: float = float(primary_values[primary_values.size() - 1]) if not primary_values.is_empty() else 0.0
	var low_price: float = float(visible_bars[0].get("low", start_price))
	var high_price: float = float(visible_bars[0].get("high", start_price))
	for bar_value in visible_bars:
		var bar: Dictionary = bar_value
		low_price = min(low_price, float(bar.get("low", low_price)))
		high_price = max(high_price, float(bar.get("high", high_price)))

	var change_pct: float = 0.0
	if not is_zero_approx(start_price):
		change_pct = (end_price - start_price) / start_price

	var indicator_snapshots: Array = _build_indicator_snapshots(display_bars, enabled_indicator_ids, primary_values.size())
	var latest_bar: Dictionary = display_bars[display_bars.size() - 1]
	var plots: Array = [{
		"id": "close",
		"label": "Close",
		"plot_kind": "price",
		"style": "line",
		"fill": true,
		"values": primary_values.duplicate(),
		"line_width": 2.5
	}]
	for indicator_value in indicator_snapshots:
		var indicator_snapshot: Dictionary = indicator_value
		var plot_kind: String = str(indicator_snapshot.get("plot_kind", "overlay"))
		if plot_kind != "overlay" and plot_kind != "panel":
			continue
		plots.append({
			"id": str(indicator_snapshot.get("id", "")),
			"label": str(indicator_snapshot.get("label", "")),
			"plot_kind": plot_kind,
			"style": "line",
			"fill": false,
			"values": indicator_snapshot.get("values", []).duplicate(),
			"line_width": 1.6
		})

	return {
		"range_id": normalized_range_id,
		"range_label": get_range_label(normalized_range_id),
		"display_mode": "line",
		"bars": display_bars.duplicate(true),
		"plots": plots,
		"indicator_snapshots": indicator_snapshots,
		"enabled_indicator_ids": _normalize_indicator_ids(enabled_indicator_ids),
		"baseline_value": start_price,
		"start_price": start_price,
		"end_price": end_price,
		"low_price": low_price,
		"high_price": high_price,
		"change_pct": change_pct,
		"visible_bar_count": visible_bars.size(),
		"display_bar_count": display_bars.size(),
		"visible_point_count": primary_values.size(),
		"full_bar_count": full_bars.size(),
		"start_date": visible_bars[0].get("trade_date", {}).duplicate(true),
		"end_date": visible_bars[visible_bars.size() - 1].get("trade_date", {}).duplicate(true),
		"latest_limit_lock": str(latest_bar.get("limit_lock", "")),
		"latest_limit_source": str(latest_bar.get("limit_source", "")),
		"latest_player_impact_ratio": float(latest_bar.get("player_impact_ratio", 0.0)),
		"latest_player_liquidity_consumed": float(latest_bar.get("player_liquidity_consumed", 0.0))
	}


func _normalize_range_id(range_id: String) -> String:
	var normalized_range_id: String = str(range_id).to_lower()
	if not RANGE_DEFINITIONS.has(normalized_range_id):
		return "1m"
	return normalized_range_id


func _range_sort_index(range_id: String) -> int:
	var order: Array = ["1d", "1w", "1m", "1y", "5y", "ytd"]
	return order.find(str(range_id).to_lower())


func _normalize_bars(price_bars: Array) -> Array:
	var normalized_bars: Array = []
	for bar_value in price_bars:
		if typeof(bar_value) != TYPE_DICTIONARY:
			continue
		normalized_bars.append(bar_value.duplicate(true))
	return normalized_bars


func _slice_visible_bars(full_bars: Array, range_id: String) -> Array:
	if full_bars.is_empty():
		return []

	var range_definition: Dictionary = RANGE_DEFINITIONS[_normalize_range_id(range_id)]
	if str(range_definition.get("mode", "")) == "ytd":
		var latest_year: int = int(full_bars[full_bars.size() - 1].get("trade_date", {}).get("year", 2020))
		var ytd_start_index: int = 0
		for bar_index in range(full_bars.size()):
			var trade_date: Dictionary = full_bars[bar_index].get("trade_date", {})
			if int(trade_date.get("year", 0)) == latest_year:
				ytd_start_index = bar_index
				break
		return full_bars.slice(ytd_start_index, full_bars.size())

	var visible_bar_count: int = int(range_definition.get("trading_days", full_bars.size()))
	var start_index: int = max(full_bars.size() - visible_bar_count, 0)
	return full_bars.slice(start_index, full_bars.size())


func _build_display_bars(visible_bars: Array, range_id: String) -> Array:
	if visible_bars.is_empty():
		return []

	var normalized_range_id: String = _normalize_range_id(range_id)
	if normalized_range_id == "5y":
		return _aggregate_bars_by_month(visible_bars)
	if normalized_range_id == "1y":
		return _aggregate_bars_by_week(visible_bars)
	return visible_bars.duplicate(true)


func _aggregate_bars_by_month(visible_bars: Array) -> Array:
	var aggregated_bars: Array = []
	var current_group: Array = []
	var current_key: String = ""
	for bar_value in visible_bars:
		var bar: Dictionary = bar_value
		var trade_date: Dictionary = bar.get("trade_date", {})
		var month_key: String = "%04d-%02d" % [
			int(trade_date.get("year", 0)),
			int(trade_date.get("month", 0))
		]
		if month_key != current_key and not current_group.is_empty():
			aggregated_bars.append(_aggregate_bar_group(current_group))
			current_group.clear()
		current_key = month_key
		current_group.append(bar)
	if not current_group.is_empty():
		aggregated_bars.append(_aggregate_bar_group(current_group))
	return aggregated_bars


func _aggregate_bars_by_week(visible_bars: Array) -> Array:
	var aggregated_bars: Array = []
	var current_group: Array = []
	var previous_weekday: int = -1
	for bar_value in visible_bars:
		var bar: Dictionary = bar_value
		var trade_date: Dictionary = bar.get("trade_date", {})
		var weekday_value: int = int(trade_date.get("weekday", previous_weekday))
		if not current_group.is_empty() and weekday_value <= previous_weekday:
			aggregated_bars.append(_aggregate_bar_group(current_group))
			current_group.clear()
		current_group.append(bar)
		previous_weekday = weekday_value
	if not current_group.is_empty():
		aggregated_bars.append(_aggregate_bar_group(current_group))
	return aggregated_bars


func _aggregate_bar_group(bar_group: Array) -> Dictionary:
	if bar_group.is_empty():
		return {}

	var first_bar: Dictionary = bar_group[0]
	var last_bar: Dictionary = bar_group[bar_group.size() - 1]
	var open_price: float = float(first_bar.get("open", first_bar.get("close", 0.0)))
	var close_price: float = float(last_bar.get("close", open_price))
	var high_price: float = max(
		float(first_bar.get("high", open_price)),
		open_price,
		close_price
	)
	var low_price: float = min(
		float(first_bar.get("low", open_price)),
		open_price,
		close_price
	)
	var total_volume_shares: int = 0
	var total_value: float = 0.0
	var latest_limit_lock: String = ""
	var latest_limit_source: String = ""
	var latest_impact_side: String = ""
	var max_player_impact_ratio: float = 0.0
	var max_player_liquidity_consumed: float = 0.0
	for bar_value in bar_group:
		var bar: Dictionary = bar_value
		high_price = max(high_price, float(bar.get("high", close_price)))
		low_price = min(low_price, float(bar.get("low", close_price)))
		total_volume_shares += int(bar.get("volume_shares", 0))
		total_value += float(bar.get("value", float(bar.get("close", 0.0)) * float(bar.get("volume_shares", 0))))
		if not str(bar.get("limit_lock", "")).is_empty():
			latest_limit_lock = str(bar.get("limit_lock", ""))
			latest_limit_source = str(bar.get("limit_source", ""))
			latest_impact_side = str(bar.get("impact_side", ""))
		var player_impact_ratio: float = float(bar.get("player_impact_ratio", 0.0))
		if absf(player_impact_ratio) > absf(max_player_impact_ratio):
			max_player_impact_ratio = player_impact_ratio
		max_player_liquidity_consumed = max(max_player_liquidity_consumed, float(bar.get("player_liquidity_consumed", 0.0)))

	var aggregated_bar: Dictionary = {
		"trade_date": last_bar.get("trade_date", {}).duplicate(true),
		"open": open_price,
		"high": high_price,
		"low": low_price,
		"close": close_price,
		"volume_shares": total_volume_shares,
		"volume_lots": int(floor(float(total_volume_shares) / 100.0)),
		"value": total_value
	}
	if not latest_limit_lock.is_empty():
		aggregated_bar["limit_lock"] = latest_limit_lock
		aggregated_bar["limit_source"] = latest_limit_source
		aggregated_bar["impact_side"] = latest_impact_side
		aggregated_bar["locked_through_day"] = true
	if not is_zero_approx(max_player_impact_ratio):
		aggregated_bar["player_impact_ratio"] = max_player_impact_ratio
		aggregated_bar["player_liquidity_consumed"] = max_player_liquidity_consumed
	return aggregated_bar


func _build_primary_values(visible_bars: Array) -> Array:
	if visible_bars.is_empty():
		return []

	var values: Array = [float(visible_bars[0].get("open", visible_bars[0].get("close", 0.0)))]
	for bar_value in visible_bars:
		var bar: Dictionary = bar_value
		values.append(float(bar.get("close", 0.0)))
	return values


func _normalize_indicator_ids(enabled_indicator_ids: Array) -> Array:
	var normalized_ids: Array = []
	for indicator_id_value in enabled_indicator_ids:
		var indicator_id: String = str(indicator_id_value).to_lower()
		if INDICATOR_CATALOG.has(indicator_id):
			normalized_ids.append(indicator_id)
	return normalized_ids


func _build_indicator_snapshots(visible_bars: Array, enabled_indicator_ids: Array, render_point_count: int) -> Array:
	var snapshots: Array = []
	var close_values: Array = []
	for bar_value in visible_bars:
		var bar: Dictionary = bar_value
		close_values.append(float(bar.get("close", 0.0)))

	for indicator_id_value in _normalize_indicator_ids(enabled_indicator_ids):
		var indicator_id: String = str(indicator_id_value)
		var definition: Dictionary = INDICATOR_CATALOG[indicator_id]
		var values: Array = []
		var calculation: String = str(definition.get("calculation", ""))
		var lookback: int = int(definition.get("lookback", 0))
		if calculation == "sma":
			values = _align_indicator_values(_build_sma(close_values, lookback), render_point_count)
		elif calculation == "ema":
			values = _align_indicator_values(_build_ema(close_values, lookback), render_point_count)
		elif calculation == "rsi":
			values = _align_indicator_values(_build_rsi(close_values, lookback), render_point_count)
		snapshots.append({
			"id": indicator_id,
			"label": str(definition.get("label", indicator_id.to_upper())),
			"plot_kind": str(definition.get("plot_kind", "overlay")),
			"values": values
		})

	return snapshots


func _align_indicator_values(source_values: Array, render_point_count: int) -> Array:
	var aligned_values: Array = [null]
	for value in source_values:
		aligned_values.append(value)
	while aligned_values.size() < render_point_count:
		aligned_values.append(null)
	if aligned_values.size() > render_point_count:
		aligned_values = aligned_values.slice(aligned_values.size() - render_point_count, aligned_values.size())
	return aligned_values


func _build_sma(values: Array, lookback: int) -> Array:
	var output: Array = []
	if lookback <= 0:
		return output
	for index in range(values.size()):
		if index + 1 < lookback:
			output.append(null)
			continue
		var sum: float = 0.0
		for source_index in range(index - lookback + 1, index + 1):
			sum += float(values[source_index])
		output.append(sum / float(lookback))
	return output


func _build_ema(values: Array, lookback: int) -> Array:
	var output: Array = []
	if values.is_empty() or lookback <= 0:
		return output
	var multiplier: float = 2.0 / float(lookback + 1)
	var ema_value: float = float(values[0])
	for index in range(values.size()):
		var value: float = float(values[index])
		if index == 0:
			ema_value = value
		else:
			ema_value = ((value - ema_value) * multiplier) + ema_value
		if index + 1 < lookback:
			output.append(null)
		else:
			output.append(ema_value)
	return output


func _build_rsi(values: Array, lookback: int) -> Array:
	var output: Array = []
	if values.size() < 2 or lookback <= 0:
		return output

	var gains: Array = []
	var losses: Array = []
	for index in range(1, values.size()):
		var change: float = float(values[index]) - float(values[index - 1])
		gains.append(max(change, 0.0))
		losses.append(absf(min(change, 0.0)))

	for index in range(values.size()):
		if index == 0 or index < lookback:
			output.append(null)
			continue
		var gain_sum: float = 0.0
		var loss_sum: float = 0.0
		for source_index in range(index - lookback, index):
			gain_sum += float(gains[source_index])
			loss_sum += float(losses[source_index])
		var average_gain: float = gain_sum / float(lookback)
		var average_loss: float = loss_sum / float(lookback)
		if is_zero_approx(average_loss):
			output.append(100.0)
			continue
		var rs: float = average_gain / average_loss
		output.append(100.0 - (100.0 / (1.0 + rs)))
	return output
