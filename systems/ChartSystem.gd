extends RefCounted

const RANGE_DEFINITIONS := {
	"1d": {"id": "1d", "label": "1D", "trading_days": 1},
	"1w": {"id": "1w", "label": "1W", "trading_days": 5},
	"1m": {"id": "1m", "label": "1M", "trading_days": 21},
	"3m": {"id": "3m", "label": "3M", "trading_days": 63},
	"6m": {"id": "6m", "label": "6M", "trading_days": 126},
	"1y": {"id": "1y", "label": "1Y", "trading_days": 252},
	"5y": {"id": "5y", "label": "5Y", "trading_days": 1260},
	"ytd": {"id": "ytd", "label": "YTD", "mode": "ytd"}
}

const INDICATOR_CATALOG := {
	"sma_3": {
		"id": "sma_3",
		"label": "SMA 3",
		"plot_kind": "overlay",
		"calculation": "sma",
		"lookback": 3,
		"track_id": "technical_basics",
		"perk_id": "indicator_sma_3",
		"sort_order": 3
	},
	"sma_5": {
		"id": "sma_5",
		"label": "SMA 5",
		"plot_kind": "overlay",
		"calculation": "sma",
		"lookback": 5,
		"track_id": "technical_basics",
		"perk_id": "indicator_sma_5",
		"sort_order": 5
	},
	"sma_10": {
		"id": "sma_10",
		"label": "SMA 10",
		"plot_kind": "overlay",
		"calculation": "sma",
		"lookback": 10,
		"track_id": "technical_basics",
		"perk_id": "indicator_sma_10",
		"sort_order": 10
	},
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
	"sma_60": {
		"id": "sma_60",
		"label": "SMA 60",
		"plot_kind": "overlay",
		"calculation": "sma",
		"lookback": 60,
		"track_id": "trend_structure",
		"perk_id": "indicator_sma_60",
		"sort_order": 60
	},
	"sma_100": {
		"id": "sma_100",
		"label": "SMA 100",
		"plot_kind": "overlay",
		"calculation": "sma",
		"lookback": 100,
		"track_id": "trend_structure",
		"perk_id": "indicator_sma_100",
		"sort_order": 100
	},
	"sma_200": {
		"id": "sma_200",
		"label": "SMA 200",
		"plot_kind": "overlay",
		"calculation": "sma",
		"lookback": 200,
		"track_id": "trend_structure",
		"perk_id": "indicator_sma_200",
		"sort_order": 200
	},
	"ema_20": {
		"id": "ema_20",
		"label": "EMA 20",
		"plot_kind": "overlay",
		"calculation": "ema",
		"lookback": 20,
		"track_id": "momentum_read",
		"perk_id": "indicator_ema_20",
		"sort_order": 210
	},
	"sma_50": {
		"id": "sma_50",
		"label": "SMA 50",
		"plot_kind": "overlay",
		"calculation": "sma",
		"lookback": 50,
		"track_id": "trend_structure",
		"perk_id": "indicator_sma_50",
		"sort_order": 50
	},
	"rsi_14": {
		"id": "rsi_14",
		"label": "RSI 14",
		"plot_kind": "panel",
		"panel_group": "rsi",
		"scale_mode": "bounded_0_100",
		"calculation": "rsi",
		"lookback": 14,
		"track_id": "momentum_read",
		"perk_id": "indicator_rsi_14",
		"sort_order": 220
	},
	"macd_12_26_9": {
		"id": "macd_12_26_9",
		"label": "MACD 12/26/9",
		"plot_kind": "panel",
		"panel_group": "macd",
		"scale_mode": "zero_symmetric",
		"calculation": "macd",
		"fast_lookback": 12,
		"slow_lookback": 26,
		"signal_lookback": 9,
		"track_id": "momentum_read",
		"perk_id": "indicator_macd_12_26_9",
		"sort_order": 230
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
	var first_display_bar: Dictionary = display_bars[0]
	var start_price: float = float(first_display_bar.get("open", first_display_bar.get("close", 0.0)))
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

	var indicator_source_bars: Array = _build_display_bars(full_bars, normalized_range_id)
	var indicator_snapshots: Array = _build_indicator_snapshots(indicator_source_bars, enabled_indicator_ids, primary_values.size())
	var technical_signals: Array = _build_technical_signals(display_bars)
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
		var subplots: Array = indicator_snapshot.get("subplots", [])
		if not subplots.is_empty():
			for subplot_value in subplots:
				if typeof(subplot_value) != TYPE_DICTIONARY:
					continue
				plots.append(subplot_value.duplicate(true))
			continue
		var plot_kind: String = str(indicator_snapshot.get("plot_kind", "overlay"))
		if plot_kind != "overlay" and plot_kind != "panel":
			continue
		plots.append({
			"id": str(indicator_snapshot.get("id", "")),
			"label": str(indicator_snapshot.get("label", "")),
			"plot_kind": plot_kind,
			"panel_group": str(indicator_snapshot.get("panel_group", "")),
			"scale_mode": str(indicator_snapshot.get("scale_mode", "")),
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
		"technical_signals": technical_signals,
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
	var order: Array = ["1d", "1w", "1m", "3m", "6m", "1y", "5y", "ytd"]
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

	var values: Array = []
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
		elif calculation == "macd":
			var macd_data: Dictionary = _build_macd(
				close_values,
				int(definition.get("fast_lookback", 12)),
				int(definition.get("slow_lookback", 26)),
				int(definition.get("signal_lookback", 9))
			)
			var macd_values: Array = _align_indicator_values(macd_data.get("macd_values", []), render_point_count)
			var signal_values: Array = _align_indicator_values(macd_data.get("signal_values", []), render_point_count)
			var histogram_values: Array = _align_indicator_values(macd_data.get("histogram_values", []), render_point_count)
			snapshots.append({
				"id": indicator_id,
				"label": str(definition.get("label", indicator_id.to_upper())),
				"plot_kind": str(definition.get("plot_kind", "panel")),
				"panel_group": str(definition.get("panel_group", "macd")),
				"scale_mode": str(definition.get("scale_mode", "zero_symmetric")),
				"values": histogram_values.duplicate(),
				"macd_values": macd_values,
				"signal_values": signal_values,
				"histogram_values": histogram_values,
				"subplots": [
					{
						"id": "macd_12_26_9_histogram",
						"label": "Histogram",
						"plot_kind": "panel",
						"panel_group": "macd",
						"scale_mode": "zero_symmetric",
						"style": "histogram",
						"fill": false,
						"values": histogram_values,
						"line_width": 1.0
					},
					{
						"id": "macd_12_26_9",
						"label": "MACD",
						"plot_kind": "panel",
						"panel_group": "macd",
						"scale_mode": "zero_symmetric",
						"style": "line",
						"fill": false,
						"values": macd_values,
						"line_width": 1.45
					},
					{
						"id": "macd_12_26_9_signal",
						"label": "Signal",
						"plot_kind": "panel",
						"panel_group": "macd",
						"scale_mode": "zero_symmetric",
						"style": "line",
						"fill": false,
						"values": signal_values,
						"line_width": 1.25
					}
				]
			})
			continue
		snapshots.append({
			"id": indicator_id,
			"label": str(definition.get("label", indicator_id.to_upper())),
			"plot_kind": str(definition.get("plot_kind", "overlay")),
			"panel_group": str(definition.get("panel_group", "")),
			"scale_mode": str(definition.get("scale_mode", "")),
			"values": values
		})

	return snapshots


func _align_indicator_values(source_values: Array, render_point_count: int) -> Array:
	var aligned_values: Array = []
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
		if not _is_numeric(values[index]) or not _is_numeric(values[index - 1]):
			gains.append(0.0)
			losses.append(0.0)
			continue
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


func build_technical_signal_summary_from_bars(price_bars: Array, range_id: String = "3m") -> Dictionary:
	var full_bars: Array = _normalize_bars(price_bars)
	if full_bars.is_empty():
		return {"signals": [], "score": 0.0}
	var normalized_range_id: String = _normalize_range_id(range_id)
	var visible_bars: Array = _slice_visible_bars(full_bars, normalized_range_id)
	var display_bars: Array = _build_display_bars(visible_bars, normalized_range_id)
	var signals: Array = _build_technical_signals(display_bars)
	return {
		"signals": signals,
		"score": _technical_signal_score(signals)
	}


func build_technical_signals_from_series(
	close_values: Array,
	rsi_values: Array = [],
	macd_values: Array = [],
	trade_dates: Array = []
) -> Array:
	var safe_close_values: Array = []
	for close_value in close_values:
		if _is_numeric(close_value):
			safe_close_values.append(float(close_value))
		else:
			safe_close_values.append(null)
	var resolved_rsi_values: Array = rsi_values.duplicate()
	if resolved_rsi_values.is_empty():
		resolved_rsi_values = _build_rsi(safe_close_values, 14)
	var resolved_macd_values: Array = macd_values.duplicate()
	if resolved_macd_values.is_empty():
		resolved_macd_values = _build_macd(safe_close_values, 12, 26, 9).get("histogram_values", [])

	var signals: Array = []
	_append_indicator_structure_signals(signals, safe_close_values, resolved_rsi_values, trade_dates, "rsi_14")
	_append_indicator_structure_signals(signals, safe_close_values, resolved_macd_values, trade_dates, "macd_12_26_9")
	signals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("strength", 0.0)), float(b.get("strength", 0.0))):
			return str(a.get("indicator_id", "")) < str(b.get("indicator_id", ""))
		return float(a.get("strength", 0.0)) > float(b.get("strength", 0.0))
	)
	return signals


func _build_technical_signals(display_bars: Array) -> Array:
	var close_values: Array = []
	var trade_dates: Array = []
	for bar_value in display_bars:
		if typeof(bar_value) != TYPE_DICTIONARY:
			continue
		var bar: Dictionary = bar_value
		close_values.append(float(bar.get("close", 0.0)))
		trade_dates.append(bar.get("trade_date", {}).duplicate(true))
	return build_technical_signals_from_series(close_values, [], [], trade_dates)


func _build_macd(values: Array, fast_lookback: int, slow_lookback: int, signal_lookback: int) -> Dictionary:
	var fast_ema_values: Array = _build_ema_raw(values, fast_lookback)
	var slow_ema_values: Array = _build_ema_raw(values, slow_lookback)
	var macd_values: Array = []
	var valid_macd_values: Array = []
	for index in range(values.size()):
		if index + 1 < slow_lookback or not _is_numeric(fast_ema_values[index]) or not _is_numeric(slow_ema_values[index]):
			macd_values.append(null)
			valid_macd_values.append(null)
			continue
		var macd_value: float = float(fast_ema_values[index]) - float(slow_ema_values[index])
		macd_values.append(macd_value)
		valid_macd_values.append(macd_value)

	var compact_macd_values: Array = []
	for macd_value in valid_macd_values:
		if _is_numeric(macd_value):
			compact_macd_values.append(float(macd_value))
	var compact_signal_values: Array = _build_ema_raw(compact_macd_values, signal_lookback)
	var signal_values: Array = []
	var histogram_values: Array = []
	var compact_index: int = 0
	for index in range(macd_values.size()):
		if not _is_numeric(macd_values[index]):
			signal_values.append(null)
			histogram_values.append(null)
			continue
		var signal_value = compact_signal_values[compact_index] if compact_index < compact_signal_values.size() else null
		compact_index += 1
		if compact_index < signal_lookback or not _is_numeric(signal_value):
			signal_values.append(null)
			histogram_values.append(null)
			continue
		signal_values.append(float(signal_value))
		histogram_values.append(float(macd_values[index]) - float(signal_value))
	return {
		"macd_values": macd_values,
		"signal_values": signal_values,
		"histogram_values": histogram_values
	}


func _build_ema_raw(values: Array, lookback: int) -> Array:
	var output: Array = []
	if values.is_empty() or lookback <= 0:
		return output
	var multiplier: float = 2.0 / float(lookback + 1)
	var ema_value: float = 0.0
	var has_ema: bool = false
	for index in range(values.size()):
		if not _is_numeric(values[index]):
			output.append(null)
			continue
		var value: float = float(values[index])
		if not has_ema:
			ema_value = value
			has_ema = true
		else:
			ema_value = ((value - ema_value) * multiplier) + ema_value
		output.append(ema_value)
	return output


func _append_indicator_structure_signals(
	signals: Array,
	close_values: Array,
	indicator_values: Array,
	trade_dates: Array,
	indicator_id: String
) -> void:
	var low_pair: Array = _pivot_pair(close_values, indicator_values, true)
	if low_pair.size() == 2:
		var first_low_index: int = int(low_pair[0])
		var second_low_index: int = int(low_pair[1])
		var first_price_low: float = float(close_values[first_low_index])
		var second_price_low: float = float(close_values[second_low_index])
		var first_indicator_low: float = float(indicator_values[first_low_index])
		var second_indicator_low: float = float(indicator_values[second_low_index])
		if second_price_low < first_price_low * 0.998 and second_indicator_low > first_indicator_low:
			signals.append(_technical_signal("bullish_divergence", indicator_id, first_low_index, second_low_index, trade_dates, _signal_strength(first_price_low, second_price_low, first_indicator_low, second_indicator_low)))
		elif second_price_low < first_price_low * 0.998 and second_indicator_low < first_indicator_low:
			signals.append(_technical_signal("bearish_convergence", indicator_id, first_low_index, second_low_index, trade_dates, _signal_strength(first_price_low, second_price_low, first_indicator_low, second_indicator_low)))

	var high_pair: Array = _pivot_pair(close_values, indicator_values, false)
	if high_pair.size() == 2:
		var first_high_index: int = int(high_pair[0])
		var second_high_index: int = int(high_pair[1])
		var first_price_high: float = float(close_values[first_high_index])
		var second_price_high: float = float(close_values[second_high_index])
		var first_indicator_high: float = float(indicator_values[first_high_index])
		var second_indicator_high: float = float(indicator_values[second_high_index])
		if second_price_high > first_price_high * 1.002 and second_indicator_high < first_indicator_high:
			signals.append(_technical_signal("bearish_divergence", indicator_id, first_high_index, second_high_index, trade_dates, _signal_strength(first_price_high, second_price_high, first_indicator_high, second_indicator_high)))
		elif second_price_high > first_price_high * 1.002 and second_indicator_high > first_indicator_high:
			signals.append(_technical_signal("bullish_convergence", indicator_id, first_high_index, second_high_index, trade_dates, _signal_strength(first_price_high, second_price_high, first_indicator_high, second_indicator_high)))


func _pivot_pair(price_values: Array, indicator_values: Array, wants_low: bool) -> Array:
	var pivots: Array = _swing_indexes(price_values, wants_low)
	var filtered: Array = []
	for pivot_value in pivots:
		var pivot_index: int = int(pivot_value)
		if pivot_index >= 0 and pivot_index < indicator_values.size() and _is_numeric(indicator_values[pivot_index]):
			filtered.append(pivot_index)
	if filtered.size() >= 2:
		return [filtered[filtered.size() - 2], filtered[filtered.size() - 1]]
	return _half_extreme_pair(price_values, indicator_values, wants_low)


func _swing_indexes(values: Array, wants_low: bool) -> Array:
	var indexes: Array = []
	if values.size() < 3:
		return indexes
	for index in range(1, values.size() - 1):
		if not _is_numeric(values[index - 1]) or not _is_numeric(values[index]) or not _is_numeric(values[index + 1]):
			continue
		var previous_value: float = float(values[index - 1])
		var current_value: float = float(values[index])
		var next_value: float = float(values[index + 1])
		if wants_low and current_value <= previous_value and current_value <= next_value:
			indexes.append(index)
		elif not wants_low and current_value >= previous_value and current_value >= next_value:
			indexes.append(index)
	return indexes


func _half_extreme_pair(price_values: Array, indicator_values: Array, wants_low: bool) -> Array:
	if price_values.size() < 6:
		return []
	var middle_index: int = int(floor(float(price_values.size()) * 0.5))
	var first_index: int = _extreme_index(price_values, indicator_values, 0, middle_index, wants_low)
	var second_index: int = _extreme_index(price_values, indicator_values, middle_index, price_values.size(), wants_low)
	if first_index < 0 or second_index < 0 or first_index == second_index:
		return []
	return [first_index, second_index]


func _extreme_index(price_values: Array, indicator_values: Array, start_index: int, end_index: int, wants_low: bool) -> int:
	var found_index: int = -1
	var found_value: float = 0.0
	for index in range(max(start_index, 0), min(end_index, price_values.size())):
		if index >= indicator_values.size() or not _is_numeric(price_values[index]) or not _is_numeric(indicator_values[index]):
			continue
		var value: float = float(price_values[index])
		if found_index < 0 or (wants_low and value < found_value) or (not wants_low and value > found_value):
			found_index = index
			found_value = value
	return found_index


func _technical_signal(
	signal_type: String,
	indicator_id: String,
	start_index: int,
	end_index: int,
	trade_dates: Array,
	strength: float
) -> Dictionary:
	return {
		"signal_type": signal_type,
		"indicator_id": indicator_id,
		"strength": snappedf(clamp(strength, 0.0, 1.0), 0.001),
		"start_bar_index": start_index,
		"end_bar_index": end_index,
		"start_date": trade_dates[start_index].duplicate(true) if start_index >= 0 and start_index < trade_dates.size() and typeof(trade_dates[start_index]) == TYPE_DICTIONARY else {},
		"end_date": trade_dates[end_index].duplicate(true) if end_index >= 0 and end_index < trade_dates.size() and typeof(trade_dates[end_index]) == TYPE_DICTIONARY else {}
	}


func _signal_strength(first_price: float, second_price: float, first_indicator: float, second_indicator: float) -> float:
	var price_delta: float = absf(second_price - first_price) / max(absf(first_price), 1.0)
	var indicator_delta: float = absf(second_indicator - first_indicator) / max(absf(first_indicator), 1.0)
	return clamp((price_delta * 8.0) + (indicator_delta * 1.4), 0.18, 1.0)


func _technical_signal_score(signals: Array) -> float:
	var score: float = 0.0
	for signal_value in signals:
		if typeof(signal_value) != TYPE_DICTIONARY:
			continue
		var signal_row: Dictionary = signal_value
		var signal_type: String = str(signal_row.get("signal_type", ""))
		var strength: float = float(signal_row.get("strength", 0.0))
		if signal_type.ends_with("divergence"):
			score = max(score, strength)
		elif signal_type.ends_with("convergence"):
			score = max(score, strength * 0.72)
	return clamp(score, 0.0, 1.0)


func _is_numeric(value) -> bool:
	return typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT
