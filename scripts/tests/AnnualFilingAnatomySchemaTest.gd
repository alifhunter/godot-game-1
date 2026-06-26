extends Node

const ANNUAL_FILING_DOCUMENT = preload("res://systems/AnnualFilingDocument.gd")

const RUN_SEED := 20260621
const EXPECTED_HASH := "1117466486"
const EXPECTED_SECTION_IDS := [
	"cover",
	"directors_statement",
	"independent_auditor_report",
	"table_of_contents",
	"financial_position",
	"profit_or_loss_and_oci",
	"changes_in_equity",
	"cash_flows",
	"note_company_information",
	"note_accounting_policies",
	"note_financial_assets_receivables",
	"note_inventories",
	"note_ppe_investments",
	"note_liabilities_borrowings",
	"note_revenue_expenses_tax_equity",
	"note_related_parties",
	"note_segment_information",
	"note_commitments_contingencies",
	"note_financial_risk_management",
	"note_non_cash_subsequent_events"
]
const PRIMARY_PAGE_LABELS := {
	"financial_position": "1-3",
	"profit_or_loss_and_oci": "4-5",
	"changes_in_equity": "6-7",
	"cash_flows": "8-9"
}
const REQUIRED_SECTION_FIELDS := [
	"section_id",
	"filing_title",
	"localized_title",
	"page_label",
	"document_part",
	"clue_density",
	"boilerplate_density",
	"evidence_capture_mode",
	"virtual_page_group",
	"supports_capture"
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
		_fail(str(first_report.get("message", "annual filing anatomy schema failed")))
		return
	var second_report: Dictionary = _build_report()
	if not bool(second_report.get("success", false)):
		_fail(str(second_report.get("message", "repeated annual filing anatomy schema failed")))
		return
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Annual filing anatomy schema payload changed across repeated fixed-seed runs.")
		return

	var hash: String = _stable_hash(str(first_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual filing anatomy schema hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_FILING_ANATOMY_SCHEMA_OK %s" % JSON.stringify({
		"hash": hash,
		"company_id": str(first_report.get("company_id", "")),
		"fiscal_year": int(first_report.get("fiscal_year", 0)),
		"section_count": int(first_report.get("section_count", 0)),
		"filing_schema_hash": str(first_report.get("filing_schema_hash", ""))
	}))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	if RunState.company_order.is_empty():
		return _case_fail("Expected generated company order.")
	var company_id: String = str(RunState.company_order[0])
	if not RunState.ensure_company_full_detail(company_id):
		return _case_fail("Could not hydrate full detail for %s." % company_id)
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, true, true)
	var snapshot: Dictionary = definition.get("financial_statement_snapshot", {}) if typeof(definition.get("financial_statement_snapshot", {})) == TYPE_DICTIONARY else {}
	var annual: Dictionary = snapshot.get("annual_statement", {}) if typeof(snapshot.get("annual_statement", {})) == TYPE_DICTIONARY else {}
	if annual.is_empty():
		return _case_fail("Expected annual statement after hydration.")
	var options: Dictionary = {
		"ticker": str(definition.get("ticker", "")),
		"company_name": str(definition.get("name", "")),
		"sector_style_id": str(definition.get("sector_id", "generic_annual_filing"))
	}
	var contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(annual, int(RunState.run_seed), company_id, options)
	var document: Dictionary = ANNUAL_FILING_DOCUMENT.build_document_from_statement(annual, int(RunState.run_seed), company_id, options)
	var validation: Dictionary = _validate_contract(contract, document, annual)
	if not bool(validation.get("success", false)):
		return validation
	return {
		"success": true,
		"payload": _payload(contract, document),
		"company_id": company_id,
		"fiscal_year": int(contract.get("fiscal_year", 0)),
		"section_count": _variant_array(contract.get("filing_section_schema", [])).size(),
		"filing_schema_hash": str(contract.get("filing_schema_hash", ""))
	}


func _validate_contract(contract: Dictionary, document: Dictionary, annual: Dictionary) -> Dictionary:
	if contract.is_empty():
		return _case_fail("Expected annual filing request contract.")
	if document.is_empty():
		return _case_fail("Expected annual filing document.")
	if int(contract.get("filing_anatomy_schema_version", 0)) != 1:
		return _case_fail("Expected annual filing anatomy schema version 1.")
	if str(contract.get("filing_anatomy_status", "")) != "r2_anatomy_schema_ready":
		return _case_fail("Expected R2 anatomy schema-ready status.")
	if str(contract.get("filing_schema_hash", "")).strip_edges().is_empty():
		return _case_fail("Expected filing schema hash.")
	if str(contract.get("filing_schema_hash", "")) != ANNUAL_FILING_DOCUMENT.filing_schema_hash(annual):
		return _case_fail("Filing schema hash helper mismatch.")

	var schema: Array = _variant_array(contract.get("filing_section_schema", []))
	var toc: Array = _variant_array(contract.get("filing_table_of_contents", []))
	var r3_map: Array = _variant_array(contract.get("r3_source_section_map", []))
	if schema.size() != EXPECTED_SECTION_IDS.size():
		return _case_fail("Expected %d filing anatomy sections." % EXPECTED_SECTION_IDS.size())
	if toc.size() != EXPECTED_SECTION_IDS.size():
		return _case_fail("Expected %d filing table-of-contents rows." % EXPECTED_SECTION_IDS.size())
	if _section_ids(schema) != EXPECTED_SECTION_IDS:
		return _case_fail("Filing anatomy section order changed.")
	if _section_ids(toc) != EXPECTED_SECTION_IDS:
		return _case_fail("Filing table-of-contents order changed.")

	var part_counts: Dictionary = {}
	for index in range(schema.size()):
		var section: Dictionary = schema[index] if typeof(schema[index]) == TYPE_DICTIONARY else {}
		var toc_row: Dictionary = toc[index] if typeof(toc[index]) == TYPE_DICTIONARY else {}
		for required_field in REQUIRED_SECTION_FIELDS:
			if not section.has(str(required_field)):
				return _case_fail("Filing section %s missing metadata %s." % [str(section.get("section_id", "")), str(required_field)])
		if int(section.get("section_order", 0)) != index + 1:
			return _case_fail("Filing section order metadata changed for %s." % str(section.get("section_id", "")))
		if int(toc_row.get("section_order", 0)) != index + 1:
			return _case_fail("Filing table-of-contents order metadata changed for %s." % str(toc_row.get("section_id", "")))
		if str(section.get("page_label", "")) != str(toc_row.get("page_label", "")):
			return _case_fail("Filing table-of-contents page label mismatch for %s." % str(section.get("section_id", "")))
		var document_part: String = str(section.get("document_part", ""))
		part_counts[document_part] = int(part_counts.get(document_part, 0)) + 1
		var section_id: String = str(section.get("section_id", ""))
		if PRIMARY_PAGE_LABELS.has(section_id) and str(section.get("page_label", "")) != str(PRIMARY_PAGE_LABELS.get(section_id, "")):
			return _case_fail("Unexpected primary statement page label for %s." % section_id)

	if int(part_counts.get("front_matter", 0)) != 4:
		return _case_fail("Expected four front-matter filing sections.")
	if int(part_counts.get("primary_statement", 0)) != 4:
		return _case_fail("Expected four primary statement filing sections.")
	if int(part_counts.get("notes", 0)) != 12:
		return _case_fail("Expected twelve filing note groups.")

	var title_validation: Dictionary = _validate_visible_titles(schema, toc)
	if not bool(title_validation.get("success", false)):
		return title_validation

	var r3_validation: Dictionary = _validate_r3_map(r3_map)
	if not bool(r3_validation.get("success", false)):
		return r3_validation

	var document_schema: Array = _variant_array(document.get("filing_section_schema", []))
	if _section_ids(document_schema) != EXPECTED_SECTION_IDS:
		return _case_fail("Annual filing document did not preserve anatomy schema.")
	return _case_ok()


func _validate_visible_titles(schema: Array, toc: Array) -> Dictionary:
	for row_value in schema + toc:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		for field in ["filing_title", "localized_title", "page_label"]:
			var visible_text: String = str(row.get(field, "")).to_lower()
			for token in HIDDEN_VISIBLE_TOKENS:
				if visible_text.contains(str(token)):
					return _case_fail("Visible filing title metadata leaked hidden token %s." % str(token))
	return _case_ok()


func _validate_r3_map(r3_map: Array) -> Dictionary:
	var groups: Dictionary = {}
	for row_value in r3_map:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		groups[str(row.get("source_section_id", ""))] = row
	for required_source in ["front_matter", "financial_position", "profit_or_loss_and_oci", "changes_in_equity", "cash_flows", "notes"]:
		if not groups.has(required_source):
			return _case_fail("R3 source map missing %s." % required_source)

	var front_matter: Dictionary = groups.get("front_matter", {})
	if str(front_matter.get("mapping_role", "")) != "front_matter":
		return _case_fail("Front-matter source map role changed.")
	if _string_array(front_matter.get("filing_section_ids", [])) != _string_array(["cover", "directors_statement", "independent_auditor_report", "table_of_contents"]):
		return _case_fail("Front-matter source map sections changed.")

	for direct_source in ["financial_position", "profit_or_loss_and_oci", "changes_in_equity", "cash_flows"]:
		var direct_group: Dictionary = groups.get(direct_source, {})
		if str(direct_group.get("mapping_role", "")) != "direct_statement":
			return _case_fail("Direct statement source map role changed for %s." % direct_source)
		if _string_array(direct_group.get("filing_section_ids", [])) != [direct_source]:
			return _case_fail("Direct statement source map target changed for %s." % direct_source)

	var notes: Dictionary = groups.get("notes", {})
	if str(notes.get("mapping_role", "")) != "expanded_note_groups":
		return _case_fail("Notes source map role changed.")
	if _string_array(notes.get("filing_section_ids", [])).size() != 12:
		return _case_fail("Notes source map should expand to twelve filing note groups.")
	var note_filters: Array = _string_array(notes.get("note_type_filters", []))
	for required_note_type in ["segment_information", "trade_receivables", "inventories", "debt_and_borrowings", "commitments_contingencies_and_subsequent_events"]:
		if not note_filters.has(required_note_type):
			return _case_fail("Notes source map missing note filter %s." % required_note_type)
	return _case_ok()


func _payload(contract: Dictionary, document: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("schema=%s:%s:%s" % [
		str(contract.get("filing_anatomy_schema_version", "")),
		str(contract.get("filing_anatomy_status", "")),
		str(contract.get("filing_schema_hash", ""))
	])
	lines.append("sections=%s" % _sections_payload(contract.get("filing_section_schema", [])))
	lines.append("toc=%s" % _toc_payload(contract.get("filing_table_of_contents", [])))
	lines.append("r3=%s" % _r3_map_payload(contract.get("r3_source_section_map", [])))
	lines.append("document_schema=%s" % "|".join(_section_ids(_variant_array(document.get("filing_section_schema", [])))))
	return "\n".join(lines)


func _sections_payload(source_value: Variant) -> String:
	var lines: Array[String] = []
	for row_value in _variant_array(source_value):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("%d:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [
			int(row.get("section_order", 0)),
			str(row.get("section_id", "")),
			str(row.get("document_part", "")),
			str(row.get("page_label", "")),
			str(row.get("read_mode", "")),
			str(row.get("clue_density", "")),
			str(row.get("boilerplate_density", "")),
			str(row.get("evidence_capture_mode", "")),
			str(row.get("virtual_page_group", "")),
			str(row.get("source_section_id", "")),
			"|".join(_string_array(row.get("source_note_types", [])))
		])
	return ";".join(lines)


func _toc_payload(source_value: Variant) -> String:
	var lines: Array[String] = []
	for row_value in _variant_array(source_value):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("%d:%s:%s:%s:%s" % [
			int(row.get("section_order", 0)),
			str(row.get("section_id", "")),
			str(row.get("document_part", "")),
			str(row.get("page_label", "")),
			str(row.get("virtual_page_group", ""))
		])
	return ";".join(lines)


func _r3_map_payload(source_value: Variant) -> String:
	var rows: Array = _variant_array(source_value)
	rows.sort_custom(func(a: Variant, b: Variant) -> bool:
		var left: String = str(a.get("source_section_id", "")) if typeof(a) == TYPE_DICTIONARY else ""
		var right: String = str(b.get("source_section_id", "")) if typeof(b) == TYPE_DICTIONARY else ""
		return left < right
	)
	var lines: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("%s:%s:%s:%s:%s" % [
			str(row.get("source_section_id", "")),
			str(row.get("mapping_role", "")),
			"|".join(_string_array(row.get("filing_section_ids", []))),
			"|".join(_string_array(row.get("source_arrays", []))),
			"|".join(_string_array(row.get("note_type_filters", [])))
		])
	return ";".join(lines)


func _section_ids(rows: Array) -> Array:
	var result: Array = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		result.append(str(row.get("section_id", "")))
	return result


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
