extends RefCounted

const SCHEMA_VERSION := 1
const SOURCE_SYSTEM_ID := "financial_statement_layer"
const DEFAULT_MAX_STORY_ADJUSTMENTS := 6

const OPERATING_METRIC_IDS := [
	"production_volume",
	"sales_volume",
	"backlog",
	"customer_concentration",
	"customer_count",
	"capacity_utilization",
	"same_store_sales",
	"arpu",
	"occupancy",
	"loan_growth",
	"npl_ratio",
	"commodity_realization_price"
]


static func apply_story_effects_to_statement(
	statement: Dictionary,
	dossiers: Array,
	financial_context: Dictionary = {},
	options: Dictionary = {}
) -> Dictionary:
	var result: Dictionary = statement.duplicate(true)
	var company_id: String = str(options.get("company_id", result.get("company_id", ""))).strip_edges()
	if company_id.is_empty():
		company_id = _first_company_id_from_dossiers(dossiers)
	var statement_id: String = _statement_id(result, company_id)
	var candidate_effects: Array = _candidate_effects_for_statement(dossiers, company_id, options)
	if candidate_effects.is_empty():
		return result

	_ensure_statement_metadata(result, statement_id, company_id, options)
	var adjustments: Array = _variant_array(result.get("story_adjustments", []))
	var traceability: Dictionary = result.get("traceability", {}) if typeof(result.get("traceability", {})) == TYPE_DICTIONARY else {}
	var dossiers_by_story_id: Dictionary = _dossiers_by_story_id(dossiers)
	var max_adjustments: int = max(1, int(options.get("max_story_adjustments", DEFAULT_MAX_STORY_ADJUSTMENTS)))
	var applied_count: int = 0

	for effect_row_value in candidate_effects:
		if applied_count >= max_adjustments:
			break
		if typeof(effect_row_value) != TYPE_DICTIONARY:
			continue
		var effect_row: Dictionary = effect_row_value
		var dossier: Dictionary = effect_row.get("dossier", {})
		var effect: Dictionary = effect_row.get("effect", {})
		var adjustment: Dictionary = _apply_effect(result, statement_id, dossier, effect, financial_context)
		if adjustment.is_empty():
			continue
		adjustments.append(adjustment)
		_merge_statement_traceability(traceability, adjustment, dossier)
		applied_count += 1

	if applied_count <= 0:
		return statement.duplicate(true)

	_generate_statement_notes(result, statement_id, company_id, adjustments, dossiers_by_story_id, traceability, options)
	result["story_adjustments"] = adjustments
	result["traceability"] = traceability
	return result


static func _apply_effect(
	statement: Dictionary,
	statement_id: String,
	dossier: Dictionary,
	effect: Dictionary,
	financial_context: Dictionary
) -> Dictionary:
	var story_id: String = str(dossier.get("story_id", "")).strip_edges()
	var effect_id: String = str(effect.get("effect_id", "")).strip_edges()
	var metric_id: String = str(effect.get("metric_id", "")).strip_edges()
	if story_id.is_empty() or effect_id.is_empty() or metric_id.is_empty():
		return {}

	var direction: String = str(effect.get("direction", "mixed"))
	var sign: float = _direction_sign(direction)
	if is_zero_approx(sign):
		return {}
	var section_id: String = _section_for_metric(metric_id, str(effect.get("statement_section", "")))
	var line_id: String = _line_id_for_metric(metric_id)
	var base_revenue: float = max(max(
		_statement_entry_value(statement, "income_statement", "revenue"),
		float(financial_context.get("revenue", 0.0)) / 4.0
	), 1.0)
	var basis: float = _basis_for_metric(statement, section_id, line_id, metric_id, base_revenue)
	var magnitude_pct: float = _magnitude_pct(str(effect.get("magnitude_band", "moderate")))
	var confidence_factor: float = clamp(float(effect.get("confidence", 0.65)), 0.35, 0.95)
	var raw_delta: float = sign * basis * magnitude_pct * confidence_factor * _metric_weight(metric_id)
	var delta: float = _bounded_delta(raw_delta, metric_id, basis, base_revenue)
	if is_zero_approx(delta):
		return {}

	var before_value: float = _statement_entry_value(statement, section_id, line_id)
	if is_zero_approx(before_value) and not _metric_can_be_negative(metric_id):
		before_value = max(_default_line_value(metric_id, base_revenue), 0.0)
		_upsert_statement_line(statement, statement_id, section_id, line_id, _label_for_metric(metric_id), before_value, metric_id, story_id, effect_id)
	var after_value: float = before_value + delta
	if not _metric_can_be_negative(metric_id):
		after_value = max(after_value, 0.0)
	_upsert_statement_line(statement, statement_id, section_id, line_id, _label_for_metric(metric_id), after_value, metric_id, story_id, effect_id)
	_apply_secondary_statement_links(statement, statement_id, metric_id, delta, story_id, effect_id, base_revenue)

	var clue_ids: Array = _statement_clue_ids_for_effect(dossier, effect)
	var adjustment_id: String = "adjustment|%s|%s" % [statement_id, effect_id]
	return {
		"adjustment_id": adjustment_id,
		"statement_id": statement_id,
		"story_id": story_id,
		"effect_id": effect_id,
		"metric_id": metric_id,
		"statement_section": section_id,
		"direction": direction,
		"magnitude_band": str(effect.get("magnitude_band", "moderate")),
		"applied_delta_pct": snappedf(delta / max(absf(basis), 1.0), 0.0001),
		"applied_delta_amount": snappedf(delta, 0.001),
		"before_value": snappedf(before_value, 0.001),
		"after_value": snappedf(after_value, 0.001),
		"persistence": str(effect.get("persistence", "")),
		"note_type": str(effect.get("note_type", "")),
		"note_id": "",
		"fact_ids": _fact_ids(dossier.get("cause_facts", [])),
		"clue_ids": clue_ids
	}


static func _ensure_statement_metadata(statement: Dictionary, statement_id: String, company_id: String, options: Dictionary) -> void:
	statement["schema_version"] = int(statement.get("schema_version", SCHEMA_VERSION))
	statement["source_system_id"] = str(statement.get("source_system_id", SOURCE_SYSTEM_ID))
	statement["statement_id"] = statement_id
	if company_id.strip_edges() != "":
		statement["company_id"] = company_id
	if not statement.has("ticker") and options.has("ticker"):
		statement["ticker"] = str(options.get("ticker", ""))
	if not statement.has("sector_id") and options.has("sector_id"):
		statement["sector_id"] = str(options.get("sector_id", ""))
	if not statement.has("statement_scope"):
		statement["statement_scope"] = "quarterly"
	if not statement.has("filing_day_index") and options.has("filing_day_index"):
		statement["filing_day_index"] = int(options.get("filing_day_index", 0))
	if not statement.has("report_date") and options.has("report_date"):
		var report_date_value = options.get("report_date", {})
		statement["report_date"] = report_date_value.duplicate(true) if typeof(report_date_value) == TYPE_DICTIONARY else {}
	if not statement.has("currency"):
		statement["currency"] = str(options.get("currency", "IDR"))
	if not statement.has("unit"):
		statement["unit"] = str(options.get("unit", "million_idr"))
	if not statement.has("audit_status"):
		statement["audit_status"] = "unaudited"
	if not statement.has("restated"):
		statement["restated"] = false
	if not statement.has("amended"):
		statement["amended"] = false
	if not statement.has("notes"):
		statement["notes"] = []
	if not statement.has("story_adjustments"):
		statement["story_adjustments"] = []
	if not statement.has("traceability"):
		statement["traceability"] = {}


static func _generate_statement_notes(
	statement: Dictionary,
	statement_id: String,
	company_id: String,
	adjustments: Array,
	dossiers_by_story_id: Dictionary,
	traceability: Dictionary,
	options: Dictionary
) -> void:
	var groups: Dictionary = {}
	var group_keys: Array = []
	for adjustment_index in range(adjustments.size()):
		if typeof(adjustments[adjustment_index]) != TYPE_DICTIONARY:
			continue
		var adjustment: Dictionary = adjustments[adjustment_index]
		var story_id: String = str(adjustment.get("story_id", "")).strip_edges()
		if story_id.is_empty():
			continue
		var note_type: String = _note_type_for_adjustment(adjustment)
		var group_key: String = "%s\n%s" % [story_id, note_type]
		if not groups.has(group_key):
			groups[group_key] = {
				"story_id": story_id,
				"note_type": note_type,
				"adjustment_indexes": []
			}
			group_keys.append(group_key)
		var group: Dictionary = groups[group_key]
		var adjustment_indexes: Array = _variant_array(group.get("adjustment_indexes", []))
		adjustment_indexes.append(adjustment_index)
		group["adjustment_indexes"] = adjustment_indexes
		groups[group_key] = group

	if group_keys.is_empty():
		return

	group_keys.sort()
	var notes: Array = _variant_array(statement.get("notes", []))
	var next_sequence_by_type: Dictionary = _next_note_sequence_by_type(notes)
	for group_key in group_keys:
		var group: Dictionary = groups[group_key]
		var note_type: String = str(group.get("note_type", "story_note"))
		var next_sequence: int = int(next_sequence_by_type.get(note_type, 1))
		var note_id: String = _unique_note_id(statement_id, note_type, next_sequence, notes)
		next_sequence_by_type[note_type] = next_sequence + 1

		var story_id: String = str(group.get("story_id", ""))
		var dossier: Dictionary = dossiers_by_story_id.get(story_id, {})
		var note: Dictionary = _build_statement_note(
			note_id,
			statement_id,
			company_id,
			group,
			adjustments,
			dossier,
			options
		)
		if note.is_empty():
			continue
		notes.append(note)
		traceability["generated_note_ids"] = _append_unique_string(traceability.get("generated_note_ids", []), note_id)
		for adjustment_index in _variant_array(group.get("adjustment_indexes", [])):
			var index: int = int(adjustment_index)
			if index < 0 or index >= adjustments.size() or typeof(adjustments[index]) != TYPE_DICTIONARY:
				continue
			var adjustment: Dictionary = adjustments[index]
			adjustment["note_id"] = note_id
			adjustments[index] = adjustment

	statement["notes"] = notes


static func _build_statement_note(
	note_id: String,
	statement_id: String,
	company_id: String,
	group: Dictionary,
	adjustments: Array,
	dossier: Dictionary,
	options: Dictionary
) -> Dictionary:
	var note_type: String = str(group.get("note_type", "story_note")).strip_edges()
	if note_type.is_empty():
		note_type = "story_note"
	var story_id: String = str(group.get("story_id", "")).strip_edges()
	var metric_ids: Array = []
	var effect_ids: Array = []
	var fact_ids: Array = []
	var clue_ids: Array = []
	var section_ids: Array = []
	var directions: Array = []
	var max_abs_delta_pct: float = 0.0

	for adjustment_index in _variant_array(group.get("adjustment_indexes", [])):
		var index: int = int(adjustment_index)
		if index < 0 or index >= adjustments.size() or typeof(adjustments[index]) != TYPE_DICTIONARY:
			continue
		var adjustment: Dictionary = adjustments[index]
		metric_ids = _append_unique_string(metric_ids, str(adjustment.get("metric_id", "")))
		effect_ids = _append_unique_string(effect_ids, str(adjustment.get("effect_id", "")))
		section_ids = _append_unique_string(section_ids, str(adjustment.get("statement_section", "")))
		directions = _append_unique_string(directions, str(adjustment.get("direction", "")))
		max_abs_delta_pct = max(max_abs_delta_pct, absf(float(adjustment.get("applied_delta_pct", 0.0))))
		for fact_id in _string_array(adjustment.get("fact_ids", [])):
			fact_ids = _append_unique_string(fact_ids, fact_id)
		for clue_id in _string_array(adjustment.get("clue_ids", [])):
			clue_ids = _append_unique_string(clue_ids, clue_id)

	if fact_ids.is_empty():
		for fact_id in _fact_ids(dossier.get("cause_facts", [])):
			fact_ids = _append_unique_string(fact_ids, fact_id)
	metric_ids.sort()
	effect_ids.sort()
	fact_ids.sort()
	clue_ids.sort()
	section_ids.sort()

	var access_level: String = _normalized_access_level(str(options.get("relationship_access_level", options.get("statement_access_level", "public"))))
	var disclosure_quality: String = _disclosure_quality_for_note(dossier, metric_ids, clue_ids, access_level)
	var detail_level: String = _note_detail_level(disclosure_quality, access_level)
	var tone: String = _tone_for_directions(directions)
	var contradiction: bool = disclosure_quality == "contradictory" or note_type == "statement_contradiction"
	return {
		"note_id": note_id,
		"statement_id": statement_id,
		"company_id": company_id,
		"note_type": note_type,
		"title_key": "%s_title" % note_type,
		"title": _title_for_note_type(note_type),
		"text_key": "%s_%s_%s_%s" % [note_type, disclosure_quality, detail_level, tone],
		"summary": _note_summary(note_type, metric_ids, disclosure_quality, tone, detail_level),
		"statement_section": "notes",
		"source_statement_sections": section_ids,
		"metric_ids": metric_ids,
		"story_id": story_id,
		"fact_ids": fact_ids,
		"effect_ids": effect_ids,
		"clue_ids": clue_ids,
		"disclosure_quality": disclosure_quality,
		"detail_level": detail_level,
		"access_level": access_level,
		"tone": tone,
		"visibility": "filing",
		"importance": _note_importance(max_abs_delta_pct, disclosure_quality, access_level, contradiction),
		"contradiction": contradiction,
		"explain_tags": _note_explain_tags(note_type, disclosure_quality, contradiction)
	}


static func _candidate_effects_for_statement(dossiers: Array, company_id: String, options: Dictionary) -> Array:
	var rows: Array = []
	for dossier_value in dossiers:
		if typeof(dossier_value) != TYPE_DICTIONARY:
			continue
		var dossier: Dictionary = dossier_value
		if not company_id.is_empty() and str(dossier.get("company_id", "")) != company_id:
			continue
		if bool(options.get("respect_statement_clue_window", false)) and not _dossier_in_statement_window(dossier, int(options.get("filing_day_index", -1))):
			continue
		for effect_value in _variant_array(dossier.get("financial_effects", [])):
			if typeof(effect_value) != TYPE_DICTIONARY:
				continue
			var effect: Dictionary = effect_value
			rows.append({
				"dossier": dossier,
				"effect": effect,
				"priority": float(dossier.get("priority", 0.0)) + float(effect.get("confidence", 0.0))
			})
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if is_equal_approx(float(left.get("priority", 0.0)), float(right.get("priority", 0.0))):
			var left_effect: Dictionary = left.get("effect", {})
			var right_effect: Dictionary = right.get("effect", {})
			return str(left_effect.get("effect_id", "")) < str(right_effect.get("effect_id", ""))
		return float(left.get("priority", 0.0)) > float(right.get("priority", 0.0))
	)
	return rows


static func _dossier_in_statement_window(dossier: Dictionary, filing_day_index: int) -> bool:
	if filing_day_index < 0:
		return true
	var clues: Array = _variant_array(dossier.get("statement_clues", []))
	if clues.is_empty():
		return true
	for clue_value in clues:
		if typeof(clue_value) != TYPE_DICTIONARY:
			continue
		var clue: Dictionary = clue_value
		var earliest: int = int(clue.get("earliest_day_index", 0))
		var latest: int = int(clue.get("latest_day_index", earliest))
		if filing_day_index >= earliest and filing_day_index <= latest:
			return true
	return false


static func _apply_secondary_statement_links(statement: Dictionary, statement_id: String, metric_id: String, delta: float, story_id: String, effect_id: String, base_revenue: float) -> void:
	match metric_id:
		"revenue":
			_add_delta_to_line(statement, statement_id, "income_statement", "gross_profit", "Gross profit", delta * 0.34, "gross_profit", story_id, effect_id)
			_add_delta_to_line(statement, statement_id, "income_statement", "operating_income", "Income from operations", delta * 0.16, "operating_income", story_id, effect_id)
			_add_delta_to_line(statement, statement_id, "income_statement", "net_income", "Net income for the period", delta * 0.08, "net_income", story_id, effect_id)
		"gross_margin":
			_add_delta_to_line(statement, statement_id, "income_statement", "net_income", "Net income for the period", delta * 0.30, "net_income", story_id, effect_id)
		"operating_margin":
			_add_delta_to_line(statement, statement_id, "income_statement", "net_income", "Net income for the period", delta * 0.42, "net_income", story_id, effect_id)
		"debt":
			_add_delta_to_line(statement, statement_id, "balance_sheet", "total_liabilities", "Total liabilities", delta, "total_liabilities", story_id, effect_id)
		"cash":
			_add_delta_to_line(statement, statement_id, "balance_sheet", "current_assets", "Current assets", delta, "current_assets", story_id, effect_id)
			_add_delta_to_line(statement, statement_id, "balance_sheet", "total_assets", "Total assets", delta, "total_assets", story_id, effect_id)
		"capex":
			_add_delta_to_line(statement, statement_id, "cash_flow", "cash_from_investing", "Cash from investing", -delta, "cash_from_investing", story_id, effect_id, true)
		"working_capital":
			_add_delta_to_line(statement, statement_id, "balance_sheet", "current_assets", "Current assets", delta, "current_assets", story_id, effect_id)
		"inventory", "receivables":
			_add_delta_to_line(statement, statement_id, "balance_sheet", "current_assets", "Current assets", max(delta, -base_revenue * 0.08), "current_assets", story_id, effect_id)


static func _add_delta_to_line(
	statement: Dictionary,
	statement_id: String,
	section_id: String,
	line_id: String,
	label: String,
	delta: float,
	metric_id: String,
	story_id: String,
	effect_id: String,
	allow_negative: bool = false
) -> void:
	if is_zero_approx(delta):
		return
	var before_value: float = _statement_entry_value(statement, section_id, line_id)
	var after_value: float = before_value + delta
	if not allow_negative:
		after_value = max(after_value, 0.0)
	_upsert_statement_line(statement, statement_id, section_id, line_id, label, after_value, metric_id, story_id, effect_id)


static func _upsert_statement_line(
	statement: Dictionary,
	statement_id: String,
	section_id: String,
	line_id: String,
	label: String,
	value: float,
	metric_id: String,
	story_id: String,
	effect_id: String
) -> void:
	var rows: Array = _variant_array(statement.get(section_id, []))
	var found: bool = false
	for index in range(rows.size()):
		if typeof(rows[index]) != TYPE_DICTIONARY:
			continue
		var line: Dictionary = rows[index]
		if str(line.get("id", line.get("metric_id", ""))) != line_id and str(line.get("metric_id", "")) != metric_id:
			continue
		line["id"] = str(line.get("id", line_id))
		line["line_id"] = str(line.get("line_id", "line|%s|%s|%s" % [statement_id, section_id, line_id]))
		line["section_id"] = section_id
		line["metric_id"] = metric_id
		line["label"] = str(line.get("label", label))
		line["value"] = snappedf(value, 0.001)
		line["source_story_ids"] = _append_unique_string(line.get("source_story_ids", []), story_id)
		line["source_effect_ids"] = _append_unique_string(line.get("source_effect_ids", []), effect_id)
		rows[index] = line
		found = true
		break
	if not found:
		rows.append({
			"id": line_id,
			"line_id": "line|%s|%s|%s" % [statement_id, section_id, line_id],
			"section_id": section_id,
			"metric_id": metric_id,
			"label": label,
			"value": snappedf(value, 0.001),
			"format": "currency" if section_id != "operating_metrics" else "number",
			"source_story_ids": _append_unique_string([], story_id),
			"source_effect_ids": _append_unique_string([], effect_id)
		})
	statement[section_id] = rows


static func _merge_statement_traceability(traceability: Dictionary, adjustment: Dictionary, dossier: Dictionary) -> void:
	traceability["source_statement_ids"] = _append_unique_string(traceability.get("source_statement_ids", []), str(adjustment.get("statement_id", "")))
	traceability["source_story_ids"] = _append_unique_string(traceability.get("source_story_ids", []), str(adjustment.get("story_id", "")))
	traceability["source_effect_ids"] = _append_unique_string(traceability.get("source_effect_ids", []), str(adjustment.get("effect_id", "")))
	traceability["generated_adjustment_ids"] = _append_unique_string(traceability.get("generated_adjustment_ids", []), str(adjustment.get("adjustment_id", "")))
	for fact_id in _fact_ids(dossier.get("cause_facts", [])):
		traceability["source_fact_ids"] = _append_unique_string(traceability.get("source_fact_ids", []), fact_id)
	for clue_id in _string_array(adjustment.get("clue_ids", [])):
		traceability["source_clue_ids"] = _append_unique_string(traceability.get("source_clue_ids", []), clue_id)


static func _dossiers_by_story_id(dossiers: Array) -> Dictionary:
	var result: Dictionary = {}
	for dossier_value in dossiers:
		if typeof(dossier_value) != TYPE_DICTIONARY:
			continue
		var dossier: Dictionary = dossier_value
		var story_id: String = str(dossier.get("story_id", "")).strip_edges()
		if not story_id.is_empty():
			result[story_id] = dossier
	return result


static func _note_type_for_adjustment(adjustment: Dictionary) -> String:
	var note_type: String = str(adjustment.get("note_type", "")).strip_edges()
	if not note_type.is_empty():
		return note_type
	match str(adjustment.get("metric_id", "")):
		"capex":
			return "capex_progress"
		"cash", "debt":
			return "liquidity"
		"inventory":
			return "inventory"
		"receivables":
			return "receivables"
		"working_capital":
			return "working_capital"
		"gross_margin", "operating_margin", "net_margin":
			return "margin_movement"
		"backlog":
			return "backlog_contract"
		"customer_concentration":
			return "customer_concentration"
		_:
			return "management_outlook"


static func _next_note_sequence_by_type(notes: Array) -> Dictionary:
	var result: Dictionary = {}
	for note_value in notes:
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		var note_type: String = str(note.get("note_type", "story_note"))
		result[note_type] = int(result.get(note_type, 1)) + 1
	return result


static func _unique_note_id(statement_id: String, note_type: String, sequence: int, notes: Array) -> String:
	var clean_note_type: String = _safe_note_token(note_type)
	var current_sequence: int = max(1, sequence)
	var candidate: String = "note|%s|%s|%02d" % [statement_id, clean_note_type, current_sequence]
	while _note_id_exists(notes, candidate):
		current_sequence += 1
		candidate = "note|%s|%s|%02d" % [statement_id, clean_note_type, current_sequence]
	return candidate


static func _note_id_exists(notes: Array, note_id: String) -> bool:
	for note_value in notes:
		if typeof(note_value) == TYPE_DICTIONARY and str(note_value.get("note_id", "")) == note_id:
			return true
	return false


static func _disclosure_quality_for_note(dossier: Dictionary, metric_ids: Array, clue_ids: Array, access_level: String) -> String:
	var quality: String = ""
	for clue_value in _variant_array(dossier.get("statement_clues", [])):
		if typeof(clue_value) != TYPE_DICTIONARY:
			continue
		var clue: Dictionary = clue_value
		var clue_id: String = str(clue.get("clue_id", ""))
		var clue_metric_ids: Array = _string_array(clue.get("metric_ids", []))
		if (not clue_ids.has(clue_id)) and (not _arrays_intersect(metric_ids, clue_metric_ids)):
			continue
		var next_quality: String = _normalized_disclosure_quality(str(clue.get("disclosure_quality", "")))
		if quality.is_empty() or _disclosure_quality_rank(next_quality) < _disclosure_quality_rank(quality):
			quality = next_quality

	if quality.is_empty():
		quality = _disclosure_quality_from_truth_state(str(dossier.get("truth_state", "")))
	return _access_adjusted_disclosure_quality(quality, access_level)


static func _normalized_disclosure_quality(quality: String) -> String:
	match quality:
		"clear", "partial", "weak", "contradictory":
			return quality
		"direct", "specific":
			return "clear"
		"limited", "vague":
			return "weak"
		_:
			return "partial"


static func _disclosure_quality_rank(quality: String) -> int:
	match quality:
		"contradictory":
			return 0
		"weak":
			return 1
		"partial":
			return 2
		"clear":
			return 3
		_:
			return 2


static func _disclosure_quality_from_truth_state(truth_state: String) -> String:
	match truth_state:
		"real":
			return "clear"
		"delayed":
			return "partial"
		"failed":
			return "weak"
		"fraud_risk", "overhyped":
			return "contradictory"
		_:
			return "partial"


static func _access_adjusted_disclosure_quality(quality: String, access_level: String) -> String:
	if quality == "contradictory":
		return quality
	var access_rank: int = _access_rank(access_level)
	if access_rank >= 3 and quality == "partial":
		return "clear"
	if access_rank >= 2 and quality == "weak":
		return "partial"
	return quality


static func _normalized_access_level(access_level: String) -> String:
	match access_level:
		"recognized", "trusted", "inner_circle":
			return access_level
		_:
			return "public"


static func _access_rank(access_level: String) -> int:
	match access_level:
		"inner_circle":
			return 3
		"trusted":
			return 2
		"recognized":
			return 1
		_:
			return 0


static func _note_detail_level(disclosure_quality: String, access_level: String) -> String:
	if disclosure_quality == "contradictory":
		return "challenge"
	if _access_rank(access_level) >= 3:
		return "high"
	if _access_rank(access_level) >= 1:
		return "medium"
	return "public"


static func _tone_for_directions(directions: Array) -> String:
	var has_up: bool = false
	var has_down: bool = false
	for direction in _string_array(directions):
		match direction:
			"up", "positive", "increase":
				has_up = true
			"down", "negative", "decrease":
				has_down = true
	if has_up and not has_down:
		return "positive"
	if has_down and not has_up:
		return "negative"
	return "mixed"


static func _note_importance(max_abs_delta_pct: float, disclosure_quality: String, access_level: String, contradiction: bool) -> float:
	var quality_bonus: float = 0.08
	match disclosure_quality:
		"clear":
			quality_bonus = 0.14
		"weak":
			quality_bonus = 0.05
		"contradictory":
			quality_bonus = 0.20
	var access_bonus: float = 0.03 * float(_access_rank(access_level))
	var contradiction_bonus: float = 0.12 if contradiction else 0.0
	return snappedf(clamp(0.18 + min(max_abs_delta_pct * 2.5, 0.44) + quality_bonus + access_bonus + contradiction_bonus, 0.0, 1.0), 0.001)


static func _note_explain_tags(note_type: String, disclosure_quality: String, contradiction: bool) -> Array:
	var result: Array = ["filing_note", note_type, disclosure_quality]
	if contradiction:
		result.append("challenge_claim")
	if note_type == "use_of_proceeds":
		result.append("post_corporate_action")
	return result


static func _note_summary(note_type: String, metric_ids: Array, disclosure_quality: String, tone: String, detail_level: String) -> String:
	var metrics: String = _metric_phrase(metric_ids)
	var clarity: String = _clarity_phrase(disclosure_quality, detail_level)
	if disclosure_quality == "contradictory" or note_type == "statement_contradiction":
		return "The filing note does not fully line up with the story around %s; %s." % [metrics, clarity]
	match note_type:
		"use_of_proceeds":
			return "Management links proceeds use to %s; %s." % [metrics, clarity]
		"capex_progress":
			return "Management discusses project spending and progress through %s; %s." % [metrics, clarity]
		"customer_contract", "customer_concentration", "backlog_contract":
			return "Management connects customer demand to %s; %s." % [metrics, clarity]
		"margin_movement", "input_cost_pressure":
			return "Management explains margin movement through %s; %s." % [metrics, clarity]
		"debt_change", "debt_maturity", "liquidity":
			return "Management frames funding and liquidity through %s; %s." % [metrics, clarity]
		"turnaround_progress":
			return "Management describes execution progress through %s; %s." % [metrics, clarity]
		"commodity_realization":
			return "Management ties realized commodity pricing to %s; %s." % [metrics, clarity]
		"inventory", "receivables", "working_capital":
			return "Management discusses working-capital movement through %s; %s." % [metrics, clarity]
		"related_party", "governance", "governance_note":
			return "Management discloses governance-sensitive items around %s; %s." % [metrics, clarity]
		_:
			return "Management commentary points to %s with a %s tone; %s." % [metrics, tone, clarity]


static func _metric_phrase(metric_ids: Array) -> String:
	var labels: Array = []
	for metric_id in _string_array(metric_ids):
		labels.append(_label_for_metric(metric_id).to_lower())
	if labels.is_empty():
		return "the affected statement lines"
	if labels.size() == 1:
		return str(labels[0])
	if labels.size() == 2:
		return "%s and %s" % [labels[0], labels[1]]
	return "%s, %s, and %s" % [labels[0], labels[1], labels[2]]


static func _clarity_phrase(disclosure_quality: String, detail_level: String) -> String:
	match disclosure_quality:
		"clear":
			if detail_level == "high":
				return "the link is direct enough to compare timing, amount, and follow-through"
			return "the link is direct enough to compare against the statement lines"
		"weak":
			return "the wording stays broad, so the player should verify it against related lines"
		"contradictory":
			return "treat it as a challenge signal and inspect the related statement lines"
		_:
			if detail_level in ["medium", "high"]:
				return "the note gives usable clues, but still needs a line-item cross-check"
			return "the note gives partial clues and still needs interpretation"


static func _title_for_note_type(note_type: String) -> String:
	match note_type:
		"use_of_proceeds":
			return "Use of proceeds"
		"capex_progress":
			return "Capex progress"
		"customer_contract":
			return "Customer contract"
		"customer_concentration":
			return "Customer concentration"
		"backlog_contract":
			return "Backlog contract"
		"margin_movement":
			return "Margin movement"
		"debt_change", "debt_maturity":
			return "Debt and liquidity"
		"statement_contradiction":
			return "Statement contradiction"
		"turnaround_progress":
			return "Turnaround progress"
		"governance_note":
			return "Governance note"
		_:
			return note_type.replace("_", " ").capitalize()


static func _safe_note_token(value: String) -> String:
	var result: String = value.strip_edges().to_lower()
	if result.is_empty():
		return "story_note"
	result = result.replace(" ", "_").replace("|", "_").replace("/", "_").replace("\\", "_")
	return result


static func _arrays_intersect(left: Array, right: Array) -> bool:
	if left.is_empty() or right.is_empty():
		return false
	for item in left:
		if right.has(item):
			return true
	return false


static func _statement_id(statement: Dictionary, company_id: String) -> String:
	var existing: String = str(statement.get("statement_id", "")).strip_edges()
	if not existing.is_empty():
		return existing
	var safe_company_id: String = company_id if not company_id.is_empty() else "unknown_company"
	return "statement|%s|%d|Q%d" % [
		safe_company_id,
		int(statement.get("statement_year", 0)),
		int(statement.get("statement_quarter", 0))
	]


static func _first_company_id_from_dossiers(dossiers: Array) -> String:
	for dossier_value in dossiers:
		if typeof(dossier_value) == TYPE_DICTIONARY:
			var company_id: String = str(dossier_value.get("company_id", "")).strip_edges()
			if not company_id.is_empty():
				return company_id
	return ""


static func _section_for_metric(metric_id: String, fallback_section: String) -> String:
	if metric_id in OPERATING_METRIC_IDS:
		return "operating_metrics"
	if fallback_section in ["income_statement", "balance_sheet", "cash_flow", "operating_metrics"]:
		return fallback_section
	match metric_id:
		"revenue", "gross_profit", "gross_margin", "operating_income", "operating_margin", "net_income", "net_margin":
			return "income_statement"
		"cash", "receivables", "inventory", "debt", "working_capital":
			return "balance_sheet"
		"capex", "free_cash_flow":
			return "cash_flow"
		_:
			return "operating_metrics"


static func _line_id_for_metric(metric_id: String) -> String:
	match metric_id:
		"gross_margin":
			return "gross_profit"
		"operating_margin":
			return "operating_income"
		"net_margin":
			return "net_income"
		"debt":
			return "debt"
		_:
			return metric_id


static func _label_for_metric(metric_id: String) -> String:
	match metric_id:
		"gross_margin":
			return "Gross profit"
		"operating_margin":
			return "Income from operations"
		"net_margin":
			return "Net income for the period"
		"cash":
			return "Cash and equivalents"
		"debt":
			return "Debt"
		"capex":
			return "Capital expenditure"
		"working_capital":
			return "Working capital"
		"customer_concentration":
			return "Customer concentration"
		"production_volume":
			return "Production volume"
		_:
			return metric_id.replace("_", " ").capitalize()


static func _basis_for_metric(statement: Dictionary, section_id: String, line_id: String, metric_id: String, base_revenue: float) -> float:
	var current_value: float = absf(_statement_entry_value(statement, section_id, line_id))
	if current_value > 0.0:
		return current_value
	match metric_id:
		"revenue":
			return base_revenue
		"gross_margin", "operating_margin", "net_margin", "net_income":
			return base_revenue
		"cash", "debt", "working_capital":
			return base_revenue * 0.35
		"capex":
			return base_revenue * 0.12
		"inventory", "receivables":
			return base_revenue * 0.20
		"backlog":
			return base_revenue * 0.70
		"customer_concentration":
			return 100.0
		"production_volume", "sales_volume":
			return 100.0
		_:
			return max(base_revenue * 0.10, 1.0)


static func _default_line_value(metric_id: String, base_revenue: float) -> float:
	match metric_id:
		"capex":
			return base_revenue * 0.09
		"cash":
			return base_revenue * 0.18
		"debt":
			return base_revenue * 0.22
		"inventory", "receivables":
			return base_revenue * 0.14
		"working_capital":
			return base_revenue * 0.10
		"customer_concentration":
			return 35.0
		"production_volume", "sales_volume":
			return 100.0
		"backlog":
			return base_revenue * 0.45
		_:
			return 0.0


static func _magnitude_pct(magnitude_band: String) -> float:
	match magnitude_band:
		"small":
			return 0.025
		"large":
			return 0.12
		"transformational":
			return 0.22
		_:
			return 0.06


static func _metric_weight(metric_id: String) -> float:
	match metric_id:
		"gross_margin", "operating_margin", "net_margin":
			return 0.48
		"net_income":
			return 0.55
		"capex", "cash", "debt", "working_capital":
			return 0.75
		"inventory", "receivables":
			return 0.62
		"customer_concentration":
			return 0.30
		"production_volume", "sales_volume":
			return 0.80
		_:
			return 1.0


static func _bounded_delta(raw_delta: float, metric_id: String, basis: float, base_revenue: float) -> float:
	var basis_cap: float = max(absf(basis) * 0.35, 1.0)
	var revenue_cap: float = max(base_revenue * 0.18, 1.0)
	match metric_id:
		"revenue":
			revenue_cap = max(base_revenue * 0.18, 1.0)
		"gross_margin", "operating_margin", "net_margin", "net_income":
			revenue_cap = max(base_revenue * 0.10, 1.0)
		"debt", "cash", "working_capital":
			revenue_cap = max(base_revenue * 0.16, 1.0)
		"capex":
			revenue_cap = max(base_revenue * 0.12, 1.0)
		"customer_concentration":
			revenue_cap = 18.0
		"production_volume", "sales_volume":
			revenue_cap = 28.0
	return snappedf(clamp(raw_delta, -min(basis_cap, revenue_cap), min(basis_cap, revenue_cap)), 0.001)


static func _direction_sign(direction: String) -> float:
	match direction:
		"up", "positive", "increase":
			return 1.0
		"down", "negative", "decrease":
			return -1.0
		_:
			return 0.0


static func _metric_can_be_negative(metric_id: String) -> bool:
	return metric_id in ["net_income", "net_margin", "operating_margin", "cash_from_investing", "free_cash_flow", "net_change_cash"]


static func _statement_entry_value(statement: Dictionary, section_key: String, line_id: String) -> float:
	for line_value in _variant_array(statement.get(section_key, [])):
		if typeof(line_value) != TYPE_DICTIONARY:
			continue
		var line: Dictionary = line_value
		if str(line.get("id", "")) == line_id or str(line.get("metric_id", "")) == line_id:
			return float(line.get("value", 0.0))
	return 0.0


static func _statement_clue_ids_for_effect(dossier: Dictionary, effect: Dictionary) -> Array:
	var metric_id: String = str(effect.get("metric_id", ""))
	var result: Array = []
	for clue_value in _variant_array(dossier.get("statement_clues", [])):
		if typeof(clue_value) != TYPE_DICTIONARY:
			continue
		var clue: Dictionary = clue_value
		var metric_ids: Array = _string_array(clue.get("metric_ids", []))
		if metric_ids.is_empty() or metric_ids.has(metric_id):
			result = _append_unique_string(result, str(clue.get("clue_id", "")))
	return result


static func _fact_ids(facts_value: Variant) -> Array:
	var result: Array = []
	for fact_value in _variant_array(facts_value):
		if typeof(fact_value) != TYPE_DICTIONARY:
			continue
		result = _append_unique_string(result, str(fact_value.get("fact_id", "")))
	return result


static func _append_unique_string(source_value: Variant, next_value: String) -> Array:
	var result: Array = _string_array(source_value)
	var clean: String = next_value.strip_edges()
	if not clean.is_empty() and not result.has(clean):
		result.append(clean)
	return result


static func _string_array(source_value: Variant) -> Array:
	var result: Array = []
	for item_value in _variant_array(source_value):
		var text: String = str(item_value).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	return result


static func _variant_array(source_value: Variant) -> Array:
	if typeof(source_value) == TYPE_ARRAY:
		return source_value.duplicate(true)
	return []
