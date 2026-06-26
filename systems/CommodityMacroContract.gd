extends RefCounted

const THESIS_VOCABULARY_SCRIPT = preload("res://systems/ThesisVocabulary.gd")
const SOURCE_TYPE := "commodity_macro"
const SOURCE_LABEL := "Macro Commodities"
const DEFAULT_EVIDENCE_LIMIT := 4
const DEFAULT_SUMMARY_LIMIT := 5


func build_summary(macro_state: Dictionary, sector_id: String = "", limit: int = DEFAULT_SUMMARY_LIMIT) -> Dictionary:
	var normalized_sector_id: String = sector_id.strip_edges()
	var indicators: Dictionary = macro_state.get("commodity_indicators", {})
	var rows: Array = _indicator_rows(indicators, normalized_sector_id)
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_score: float = absf(float(left.get("ytd_move", 0.0)))
		var right_score: float = absf(float(right.get("ytd_move", 0.0)))
		if is_equal_approx(left_score, right_score):
			return str(left.get("id", "")) < str(right.get("id", ""))
		return left_score > right_score
	)
	return {
		"year": int(macro_state.get("year", 0)),
		"sector_id": normalized_sector_id,
		"regime_counts": macro_state.get("commodity_regime_counts", {}).duplicate(true),
		"leaders": _rows_for_ids(indicators, macro_state.get("commodity_leaders", []), normalized_sector_id),
		"laggards": _rows_for_ids(indicators, macro_state.get("commodity_laggards", []), normalized_sector_id),
		"sector_relevant": _cap_rows(rows, limit)
	}


func build_evidence_rows(macro_state: Dictionary, context: Dictionary = {}, limit: int = DEFAULT_EVIDENCE_LIMIT) -> Array:
	var indicators: Dictionary = macro_state.get("commodity_indicators", {})
	var sector_id: String = str(context.get("sector_id", "")).strip_edges()
	var exposures: Dictionary = context.get("commodity_exposures", {}) if typeof(context.get("commodity_exposures", {})) == TYPE_DICTIONARY else {}
	var candidates: Array = []
	for commodity_id_value in indicators.keys():
		var commodity_id: String = str(commodity_id_value)
		var indicator: Dictionary = indicators.get(commodity_id, {})
		var related_sectors: Array = indicator.get("related_sectors", []) if typeof(indicator.get("related_sectors", [])) == TYPE_ARRAY else []
		var has_exposure: bool = exposures.has(commodity_id)
		var sector_related: bool = not sector_id.is_empty() and related_sectors.has(sector_id)
		if not has_exposure and not sector_related and not sector_id.is_empty():
			continue
		var exposure: float = float(exposures.get(commodity_id, 0.0))
		var ytd_move: float = float(indicator.get("ytd_move", 0.0))
		var priority: float = absf(exposure) * 3.0 + absf(ytd_move) / 12.0 + _regime_priority(str(indicator.get("regime", "neutral")))
		if not has_exposure and sector_related:
			priority *= 0.72
		if sector_id.is_empty():
			priority = absf(ytd_move) / 10.0 + _regime_priority(str(indicator.get("regime", "neutral")))
		candidates.append({
			"id": commodity_id,
			"priority": priority,
			"indicator": indicator,
			"exposure": exposure,
			"has_exposure": has_exposure,
			"sector_related": sector_related
		})
	candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_priority: float = float(left.get("priority", 0.0))
		var right_priority: float = float(right.get("priority", 0.0))
		if is_equal_approx(left_priority, right_priority):
			return str(left.get("id", "")) < str(right.get("id", ""))
		return left_priority > right_priority
	)
	var rows: Array = []
	for candidate_value in candidates:
		if rows.size() >= limit:
			break
		var candidate: Dictionary = candidate_value
		rows.append(_evidence_row(
			macro_state,
			candidate.get("indicator", {}),
			context,
			float(candidate.get("exposure", 0.0)),
			bool(candidate.get("has_exposure", false)),
			bool(candidate.get("sector_related", false))
		))
	return rows


func _indicator_rows(indicators: Dictionary, sector_id: String) -> Array:
	var rows: Array = []
	for commodity_id_value in indicators.keys():
		var commodity_id: String = str(commodity_id_value)
		var indicator: Dictionary = indicators.get(commodity_id, {})
		var related_sectors: Array = indicator.get("related_sectors", []) if typeof(indicator.get("related_sectors", [])) == TYPE_ARRAY else []
		if not sector_id.is_empty() and not related_sectors.has(sector_id):
			continue
		rows.append(_compact_indicator_row(indicator))
	return rows


func _rows_for_ids(indicators: Dictionary, ids: Array, sector_id: String) -> Array:
	var rows: Array = []
	for commodity_id_value in ids:
		var commodity_id: String = str(commodity_id_value)
		if not indicators.has(commodity_id):
			continue
		var indicator: Dictionary = indicators.get(commodity_id, {})
		var related_sectors: Array = indicator.get("related_sectors", []) if typeof(indicator.get("related_sectors", [])) == TYPE_ARRAY else []
		if not sector_id.is_empty() and not related_sectors.has(sector_id):
			continue
		rows.append(_compact_indicator_row(indicator))
	return rows


func _compact_indicator_row(indicator: Dictionary) -> Dictionary:
	return {
		"id": str(indicator.get("id", "")),
		"display_name": str(indicator.get("display_name", indicator.get("id", ""))),
		"category": str(indicator.get("category", "other")),
		"level": float(indicator.get("level", 100.0)),
		"direction": str(indicator.get("direction", "flat")),
		"regime": str(indicator.get("regime", "neutral")),
		"ytd_move": float(indicator.get("ytd_move", 0.0)),
		"driver_score": float(indicator.get("driver_score", 0.0)),
		"related_sectors": _array_copy(indicator.get("related_sectors", [])),
		"story_tags": _array_copy(indicator.get("story_tags", []))
	}


func _evidence_row(
	macro_state: Dictionary,
	indicator: Dictionary,
	context: Dictionary,
	exposure: float,
	has_exposure: bool,
	sector_related: bool
) -> Dictionary:
	var commodity_id: String = str(indicator.get("id", ""))
	var commodity_name: String = str(indicator.get("display_name", commodity_id))
	var ytd_move: float = float(indicator.get("ytd_move", 0.0))
	var regime: String = str(indicator.get("regime", "neutral"))
	var direction: String = str(indicator.get("direction", "flat"))
	var sector_id: String = str(context.get("sector_id", "")).strip_edges()
	var company_id: String = str(context.get("company_id", context.get("id", ""))).strip_edges()
	var source_suffix: String = company_id if not company_id.is_empty() else (sector_id if not sector_id.is_empty() else "market")
	return {
		"company_id": company_id,
		"ticker": str(context.get("ticker", "")),
		"company_name": str(context.get("company_name", context.get("name", ""))),
		"sector_id": sector_id,
		"sector_name": str(context.get("sector_name", "")),
		"category": THESIS_VOCABULARY_SCRIPT.CATEGORY_SECTOR_MACRO,
		"category_label": THESIS_VOCABULARY_SCRIPT.category_label(THESIS_VOCABULARY_SCRIPT.CATEGORY_SECTOR_MACRO),
		"label": "%s commodity regime" % commodity_name,
		"value": "%s / %s / %s" % [regime.capitalize(), direction, _signed_percent(ytd_move)],
		"detail": _evidence_detail(commodity_name, regime, direction, ytd_move, exposure, has_exposure, sector_related),
		"source_type": SOURCE_TYPE,
		"source_label": SOURCE_LABEL,
		"source_id": "commodity_macro_%s_%s_%s" % [str(macro_state.get("year", 0)), commodity_id, source_suffix],
		"impact": _impact_for_indicator(indicator, exposure, has_exposure),
		"commodity_id": commodity_id,
		"commodity_name": commodity_name,
		"commodity_category": str(indicator.get("category", "other")),
		"commodity_regime": regime,
		"commodity_direction": direction,
		"commodity_level": float(indicator.get("level", 100.0)),
		"commodity_ytd_move": ytd_move,
		"commodity_driver_score": float(indicator.get("driver_score", 0.0)),
		"commodity_exposure": exposure,
		"commodity_has_direct_exposure": has_exposure,
		"commodity_sector_related": sector_related,
		"related_sectors": _array_copy(indicator.get("related_sectors", [])),
		"story_tags": _array_copy(indicator.get("story_tags", []))
	}


func _evidence_detail(
	commodity_name: String,
	regime: String,
	direction: String,
	ytd_move: float,
	exposure: float,
	has_exposure: bool,
	sector_related: bool
) -> String:
	var relationship: String = "sector-related macro context"
	if has_exposure:
		relationship = "direct positive exposure" if exposure >= 0.0 else "direct input-cost / inverse exposure"
	elif sector_related:
		relationship = "related sector context"
	return "%s is %s and %s with %s YTD move; treat it as %s, not a direct trade signal." % [
		commodity_name,
		regime,
		direction,
		_signed_percent(ytd_move),
		relationship
	]


func _impact_for_indicator(indicator: Dictionary, exposure: float, has_exposure: bool) -> String:
	var ytd_move: float = float(indicator.get("ytd_move", 0.0))
	var regime_score: float = _regime_direction_score(str(indicator.get("regime", "neutral")))
	var directional_score: float = ytd_move + regime_score
	var exposure_sign: float = 1.0
	if has_exposure and exposure < 0.0:
		exposure_sign = -1.0
	var score: float = directional_score * exposure_sign
	if score >= 4.0:
		return THESIS_VOCABULARY_SCRIPT.IMPACT_POSITIVE
	if score <= -4.0:
		return THESIS_VOCABULARY_SCRIPT.IMPACT_NEGATIVE
	return THESIS_VOCABULARY_SCRIPT.IMPACT_MIXED


func _regime_direction_score(regime: String) -> float:
	match regime:
		"bull":
			return 8.0
		"firm":
			return 4.0
		"soft":
			return -4.0
		"bear":
			return -8.0
		_:
			return 0.0


func _regime_priority(regime: String) -> float:
	return absf(_regime_direction_score(regime)) / 4.0


func _cap_rows(rows: Array, limit: int) -> Array:
	var capped: Array = []
	for row_value in rows:
		if capped.size() >= limit:
			break
		if typeof(row_value) == TYPE_DICTIONARY:
			capped.append(row_value)
	return capped


func _array_copy(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value.duplicate(true)
	return []


func _signed_percent(value: float) -> String:
	var prefix: String = "+" if value > 0.0 else ""
	return "%s%s%%" % [prefix, String.num(value, 1)]
