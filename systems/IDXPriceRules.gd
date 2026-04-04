extends RefCounted

const BOARD_MAIN_GROUP := ["main", "new_economy", "development", "etf", "dire"]
const BOARD_ACCELERATION_GROUP := ["acceleration", "watchlist"]


static func tick_size_for_reference_price(last_price: float) -> float:
	var normalized_last_price: float = normalize_last_price(last_price)
	if normalized_last_price < 200.0:
		return 1.0
	if normalized_last_price < 500.0:
		return 2.0
	if normalized_last_price < 2000.0:
		return 5.0
	if normalized_last_price < 5000.0:
		return 10.0
	return 25.0


static func snap_price_for_day(raw_price: float, reference_price: float) -> float:
	var safe_reference: float = normalize_last_price(reference_price)
	var tick_size: float = tick_size_for_reference_price(safe_reference)
	var snapped_delta: float = snappedf(raw_price - safe_reference, tick_size)
	return max(1.0, safe_reference + snapped_delta)


static func auto_rejection_limits(reference_price: float, listing_board: String = "main") -> Dictionary:
	var safe_reference: float = normalize_last_price(reference_price)
	var board_key: String = _normalize_board(listing_board)
	var ar_rule: Dictionary = _auto_rejection_rule_for_price(safe_reference, board_key)
	var upper_raw: float = _resolve_rule_target(safe_reference, ar_rule, "upper")
	var lower_raw: float = max(1.0, _resolve_rule_target(safe_reference, ar_rule, "lower"))

	return {
		"reference_price": safe_reference,
		"listing_board": board_key,
		"upper_raw": upper_raw,
		"lower_raw": lower_raw,
		"upper_price": snap_down_to_tick_for_day(upper_raw, safe_reference),
		"lower_price": snap_up_to_tick_for_day(lower_raw, safe_reference),
		"upper_label": str(ar_rule.get("upper_label", "")),
		"lower_label": str(ar_rule.get("lower_label", ""))
	}


static func snap_down_to_tick_for_day(raw_price: float, reference_price: float) -> float:
	var safe_reference: float = normalize_last_price(reference_price)
	var tick_size: float = tick_size_for_reference_price(safe_reference)
	var steps: float = floor((raw_price - safe_reference) / tick_size)
	return max(1.0, safe_reference + (steps * tick_size))


static func snap_up_to_tick_for_day(raw_price: float, reference_price: float) -> float:
	var safe_reference: float = normalize_last_price(reference_price)
	var tick_size: float = tick_size_for_reference_price(safe_reference)
	var steps: float = ceil((raw_price - safe_reference) / tick_size)
	return max(1.0, safe_reference + (steps * tick_size))


static func normalize_last_price(price: float) -> float:
	return max(1.0, round(price))


static func _normalize_board(listing_board: String) -> String:
	var board_key: String = listing_board.to_lower()
	if board_key.is_empty():
		return "main"
	return board_key


static func _auto_rejection_rule_for_price(reference_price: float, board_key: String) -> Dictionary:
	if board_key in BOARD_ACCELERATION_GROUP:
		if reference_price <= 10.0:
			return {
				"upper_mode": "absolute",
				"upper_value": 1.0,
				"upper_label": "+Rp1",
				"lower_mode": "absolute",
				"lower_value": 1.0,
				"lower_label": "-Rp1"
			}
		return {
			"upper_mode": "percent",
			"upper_value": 0.10,
			"upper_label": "+10%",
			"lower_mode": "percent",
			"lower_value": 0.10,
			"lower_label": "-10%"
		}

	if board_key == "dinfra":
		return {
			"upper_mode": "percent",
			"upper_value": 0.10,
			"upper_label": "+10%",
			"lower_mode": "percent",
			"lower_value": 0.10,
			"lower_label": "-10%"
		}

	if reference_price <= 200.0:
		return {
			"upper_mode": "percent",
			"upper_value": 0.35,
			"upper_label": "+35%",
			"lower_mode": "percent",
			"lower_value": 0.15,
			"lower_label": "-15%"
		}
	if reference_price <= 5000.0:
		return {
			"upper_mode": "percent",
			"upper_value": 0.25,
			"upper_label": "+25%",
			"lower_mode": "percent",
			"lower_value": 0.15,
			"lower_label": "-15%"
		}
	return {
		"upper_mode": "percent",
		"upper_value": 0.20,
		"upper_label": "+20%",
		"lower_mode": "percent",
		"lower_value": 0.15,
		"lower_label": "-15%"
	}


static func _resolve_rule_target(reference_price: float, rule: Dictionary, side: String) -> float:
	var mode: String = str(rule.get("%s_mode" % side, "percent"))
	var value: float = float(rule.get("%s_value" % side, 0.0))
	if mode == "absolute":
		return reference_price + value if side == "upper" else reference_price - value
	return reference_price * (1.0 + value) if side == "upper" else reference_price * (1.0 - value)
