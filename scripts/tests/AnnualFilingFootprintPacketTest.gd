extends Node

const ANNUAL_FILING_DOCUMENT = preload("res://systems/AnnualFilingDocument.gd")

const RUN_SEED := 20260621
const EXPECTED_HASH := "1020530100"
const REQUIRED_FOOTPRINT_TYPES := [
	"numeric_movement",
	"statement_row_note_reference",
	"note_paragraph",
	"compact_table_row",
	"cross_note_reference",
	"auditor_risk_focus",
	"segment_movement",
	"risk_management_language",
	"subsequent_event_language"
]
const REQUIRED_CORE_TYPES := [
	"numeric_movement",
	"statement_row_note_reference",
	"note_paragraph",
	"compact_table_row",
	"cross_note_reference"
]
const REQUIRED_ROW_FIELDS := [
	"footprint_id",
	"footprint_type",
	"filing_section_id",
	"source_disclosure_packet_id",
	"source_disclosure_placement_id",
	"story_id",
	"archetype_id",
	"visible_label",
	"neutral_caption",
	"evidence_capture_mode",
	"story_exposure",
	"reveals_trade_answer",
	"traceability_mode"
]
const HIDDEN_VISIBLE_TOKENS := [
	"truth_state",
	"fraud_risk",
	"overhyped",
	"story|",
	"packet|",
	"placement|",
	"source_quality",
	"disclosure_quality",
	"confidence"
]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_report()
	if not bool(first_report.get("success", false)):
		_fail(str(first_report.get("message", "annual filing footprint packet failed")))
		return
	var second_report: Dictionary = _build_report()
	if not bool(second_report.get("success", false)):
		_fail(str(second_report.get("message", "repeated annual filing footprint packet failed")))
		return
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Annual filing footprint packet payload changed across repeated fixed-seed runs.")
		return

	var hash: String = _stable_hash(str(first_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual filing footprint packet hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_FILING_FOOTPRINT_PACKET_OK %s" % JSON.stringify({
		"hash": hash,
		"company_id": str(first_report.get("company_id", "")),
		"fiscal_year": int(first_report.get("fiscal_year", 0)),
		"footprint_hash": str(first_report.get("footprint_hash", "")),
		"footprint_count": int(first_report.get("footprint_count", 0)),
		"story_count": int(first_report.get("story_count", 0))
	}))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	if RunState.company_order.is_empty():
		return _case_fail("Expected generated company order.")

	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		if not RunState.ensure_company_full_detail(company_id):
			continue
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, true, true)
		var snapshot: Dictionary = definition.get("financial_statement_snapshot", {}) if typeof(definition.get("financial_statement_snapshot", {})) == TYPE_DICTIONARY else {}
		var annual: Dictionary = snapshot.get("annual_statement", {}) if typeof(snapshot.get("annual_statement", {})) == TYPE_DICTIONARY else {}
		if annual.is_empty():
			continue
		var options: Dictionary = {
			"ticker": str(definition.get("ticker", "")),
			"company_name": str(definition.get("name", "")),
			"sector_style_id": str(definition.get("sector_id", "generic_annual_filing"))
		}
		var contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(annual, int(RunState.run_seed), company_id, options)
		var footprints: Array = _variant_array(contract.get("accounting_footprint_packets", []))
		if footprints.is_empty():
			continue
		var validation: Dictionary = _validate_contract(contract, annual)
		if not bool(validation.get("success", false)):
			return validation
		return {
			"success": true,
			"payload": _payload(contract),
			"company_id": company_id,
			"fiscal_year": int(contract.get("fiscal_year", 0)),
			"footprint_hash": str(contract.get("accounting_footprint_hash", "")),
			"footprint_count": footprints.size(),
			"story_count": _story_ids(footprints).size()
		}
	return _case_fail("Expected at least one company with accounting footprint packets.")


func _validate_contract(contract: Dictionary, annual: Dictionary) -> Dictionary:
	if int(contract.get("accounting_footprint_schema_version", 0)) != 1:
		return _case_fail("Expected accounting footprint schema version 1.")
	if str(contract.get("accounting_footprint_status", "")) != "task3_accounting_footprints_ready":
		return _case_fail("Expected accounting footprint Task 3 status.")
	if str(contract.get("accounting_footprint_hash", "")).strip_edges().is_empty():
		return _case_fail("Expected accounting footprint hash.")
	if str(contract.get("accounting_footprint_hash", "")) != ANNUAL_FILING_DOCUMENT.accounting_footprint_hash(annual, _variant_array(contract.get("filing_section_schema", []))):
		return _case_fail("Accounting footprint hash helper mismatch.")

	var definitions: Dictionary = ANNUAL_FILING_DOCUMENT.accounting_footprint_type_definitions()
	for footprint_type in REQUIRED_FOOTPRINT_TYPES:
		if not definitions.has(footprint_type):
			return _case_fail("Missing footprint type definition %s." % footprint_type)
		var definition: Dictionary = definitions.get(footprint_type, {}) if typeof(definitions.get(footprint_type, {})) == TYPE_DICTIONARY else {}
		if str(definition.get("visible_label", "")).strip_edges().is_empty():
			return _case_fail("Footprint type %s missing visible label." % footprint_type)
		if str(definition.get("evidence_capture_mode", "")).strip_edges().is_empty():
			return _case_fail("Footprint type %s missing capture mode." % footprint_type)

	var footprints: Array = _variant_array(contract.get("accounting_footprint_packets", []))
	if footprints.is_empty():
		return _case_fail("Expected accounting footprint packets.")
	var type_counts: Dictionary = _type_counts(footprints)
	for footprint_type in REQUIRED_CORE_TYPES:
		if int(type_counts.get(footprint_type, 0)) <= 0:
			return _case_fail("Expected core footprint type %s." % footprint_type)

	var story_type_counts: Dictionary = _story_type_counts(footprints)
	var max_story_type_count: int = 0
	for story_id in story_type_counts.keys():
		max_story_type_count = max(max_story_type_count, _variant_array(story_type_counts.get(story_id, [])).size())
	if max_story_type_count < 4:
		return _case_fail("Expected one fixed-seed story to appear across at least four footprint types.")

	var saw_indirect_or_buried: bool = false
	for row_value in footprints:
		if typeof(row_value) != TYPE_DICTIONARY:
			return _case_fail("Expected footprint rows to be dictionaries.")
		var row: Dictionary = row_value
		for required_field in REQUIRED_ROW_FIELDS:
			if not row.has(str(required_field)):
				return _case_fail("Footprint row missing %s." % str(required_field))
		if bool(row.get("reveals_trade_answer", true)):
			return _case_fail("Footprint row should not reveal a trade answer.")
		if str(row.get("traceability_mode", "")) != "internal_source_ids_only":
			return _case_fail("Footprint row traceability mode changed.")
		var exposure: String = str(row.get("story_exposure", ""))
		var subtlety: String = str(row.get("subtlety", ""))
		if exposure == "complete" and subtlety != "direct":
			return _case_fail("Non-direct footprint should not expose the complete story.")
		if exposure == "fragment" and subtlety in ["implied", "buried", "conflicting", "missing"]:
			saw_indirect_or_buried = true
		for visible_field in ["visible_label", "neutral_caption"]:
			var visible_text: String = str(row.get(visible_field, "")).to_lower()
			for token in HIDDEN_VISIBLE_TOKENS:
				if visible_text.contains(str(token)):
					return _case_fail("Footprint visible field leaked hidden token %s." % str(token))
	if not saw_indirect_or_buried:
		return _case_fail("Expected at least one indirect or buried footprint fragment.")
	return _case_ok()


func _payload(contract: Dictionary) -> String:
	var footprints: Array = _variant_array(contract.get("accounting_footprint_packets", []))
	var lines: Array[String] = []
	lines.append("status=%s:%s:%s" % [
		str(contract.get("accounting_footprint_schema_version", "")),
		str(contract.get("accounting_footprint_status", "")),
		str(contract.get("accounting_footprint_hash", ""))
	])
	lines.append("types=%s" % _type_counts_payload(_type_counts(footprints)))
	lines.append("stories=%s" % _story_type_counts_payload(_story_type_counts(footprints)))
	lines.append("rows=%s" % _footprint_rows_payload(footprints))
	return "\n".join(lines)


func _footprint_rows_payload(footprints: Array) -> String:
	var lines: Array[String] = []
	for row_value in footprints:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("%d:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [
			int(row.get("footprint_order", 0)),
			str(row.get("footprint_type", "")),
			str(row.get("footprint_pattern_id", "")),
			str(row.get("filing_section_id", "")),
			str(row.get("source_disclosure_packet_id", "")),
			str(row.get("source_disclosure_placement_id", "")),
			str(row.get("story_id", "")),
			str(row.get("archetype_id", "")),
			str(row.get("source_note_type", "")),
			"|".join(_string_array(row.get("metric_ids", []))),
			"|".join(_string_array(row.get("statement_line_ids", []))),
			str(row.get("story_exposure", ""))
		])
	return ";".join(lines)


func _type_counts(footprints: Array) -> Dictionary:
	var counts: Dictionary = {}
	for row_value in footprints:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var footprint_type: String = str(row.get("footprint_type", "")).strip_edges()
		if footprint_type.is_empty():
			continue
		counts[footprint_type] = int(counts.get(footprint_type, 0)) + 1
	return counts


func _story_type_counts(footprints: Array) -> Dictionary:
	var counts: Dictionary = {}
	for row_value in footprints:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var story_id: String = str(row.get("story_id", "")).strip_edges()
		var footprint_type: String = str(row.get("footprint_type", "")).strip_edges()
		if story_id.is_empty() or footprint_type.is_empty():
			continue
		var types: Array = _variant_array(counts.get(story_id, []))
		if not types.has(footprint_type):
			types.append(footprint_type)
		counts[story_id] = types
	return counts


func _story_ids(footprints: Array) -> Array:
	var ids: Array = []
	for row_value in footprints:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var story_id: String = str(row.get("story_id", "")).strip_edges()
		if not story_id.is_empty() and not ids.has(story_id):
			ids.append(story_id)
	ids.sort()
	return ids


func _type_counts_payload(counts: Dictionary) -> String:
	var keys: Array = counts.keys()
	keys.sort()
	var rows: Array[String] = []
	for key in keys:
		rows.append("%s=%d" % [str(key), int(counts.get(key, 0))])
	return ";".join(rows)


func _story_type_counts_payload(counts: Dictionary) -> String:
	var keys: Array = counts.keys()
	keys.sort()
	var rows: Array[String] = []
	for key in keys:
		rows.append("%s=%s" % [str(key), "|".join(_string_array(counts.get(key, [])))])
	return ";".join(rows)


func _variant_array(source_value: Variant) -> Array:
	if typeof(source_value) == TYPE_ARRAY:
		return source_value.duplicate(true)
	return []


func _string_array(source_value: Variant) -> Array:
	var result: Array = []
	for item_value in _variant_array(source_value):
		var text: String = str(item_value).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	result.sort()
	return result


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int(hash_value ^ text.unicode_at(index))
		hash_value = int((hash_value * 16777619) & 0x7fffffff)
	return str(hash_value)


func _case_ok() -> Dictionary:
	return {"success": true}


func _case_fail(message: String) -> Dictionary:
	return {"success": false, "message": message}


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
