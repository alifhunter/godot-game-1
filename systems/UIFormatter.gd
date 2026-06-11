class_name UIFormatter
extends RefCounted

# Single source of truth for number/currency formatting (Indonesian locale:
# "." thousands separator, "," decimal separator). These implementations were
# previously duplicated across GameManager, RunState, GameRoot, LifeWidget,
# ThesisBoardWidget and TradeWorkspaceWidget — keep them byte-identical here.


# "Rp1.234.567,89" — full grouped currency.
static func format_currency(value: float) -> String:
	return "%sRp%s" % [
		"-" if value < 0.0 else "",
		format_decimal(absf(value), 2, true)
	]


# "1.234.567,89" — grouped decimal with comma separator.
static func format_decimal(value: float, decimal_places: int = 2, use_grouping: bool = true) -> String:
	var safe_places: int = max(decimal_places, 0)
	var decimal_scale: int = 1
	for _index in range(safe_places):
		decimal_scale *= 10
	var scaled_value: int = int(round(absf(value) * float(decimal_scale)))
	var whole_value: int = int(floor(float(scaled_value) / float(decimal_scale)))
	var decimal_value: int = scaled_value % decimal_scale
	var whole_text: String = format_grouped_integer(whole_value) if use_grouping else str(whole_value)
	if safe_places <= 0:
		return whole_text
	var decimal_text: String = str(decimal_value).pad_zeros(safe_places)
	return "%s,%s" % [whole_text, decimal_text]


# "1.234.567" — dot-grouped integer.
static func format_grouped_integer(value: int) -> String:
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


# "Rp1.23T" — compact with dot decimals (String.num style).
static func format_currency_compact(value: float) -> String:
	var absolute_value: float = absf(value)
	var sign_prefix: String = "-" if value < 0.0 else ""
	if absolute_value >= 1000000000000.0:
		return "%sRp%sT" % [sign_prefix, String.num(absolute_value / 1000000000000.0, 2)]
	if absolute_value >= 1000000000.0:
		return "%sRp%sB" % [sign_prefix, String.num(absolute_value / 1000000000.0, 2)]
	if absolute_value >= 1000000.0:
		return "%sRp%sM" % [sign_prefix, String.num(absolute_value / 1000000.0, 2)]
	return "%sRp%s" % [sign_prefix, String.num(absolute_value, 2)]


# "Rp1,23T" — compact with comma decimals; falls back to full currency below 1M.
static func format_compact_currency(value: float) -> String:
	var absolute_value: float = absf(value)
	var sign_prefix: String = "-" if value < 0.0 else ""
	if absolute_value >= 1000000000000.0:
		return "%sRp%sT" % [sign_prefix, format_decimal(absolute_value / 1000000000000.0, 2, false)]
	if absolute_value >= 1000000000.0:
		return "%sRp%sB" % [sign_prefix, format_decimal(absolute_value / 1000000000.0, 2, false)]
	if absolute_value >= 1000000.0:
		return "%sRp%sM" % [sign_prefix, format_decimal(absolute_value / 1000000.0, 2, false)]
	return format_currency(value)


# "+12.34%" — signed percent from a 0..1 fraction.
static func format_percent(value: float) -> String:
	var sign_prefix: String = "+" if value > 0.0 else ""
	return "%s%s%%" % [sign_prefix, String.num(value * 100.0, 2)]
