extends Node

const RUN_SEED := 20260621
const EXPECTED_HASH := "2037575392"
const EXPECTED_SECTION_IDS := [
	"financial_position",
	"profit_or_loss_and_oci",
	"changes_in_equity",
	"cash_flows",
	"notes"
]
const EXPECTED_PAGE_LABELS := {
	"financial_position": "1-3",
	"profit_or_loss_and_oci": "4-5",
	"changes_in_equity": "6-7",
	"cash_flows": "8-9",
	"notes": "10-140"
}
const EXPECTED_NOTE_COUNT := 14


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_report()
	if not bool(first_report.get("success", false)):
		_fail(str(first_report.get("message", "annual report document contract failed")))
		return
	var second_report: Dictionary = _build_report()
	if not bool(second_report.get("success", false)):
		_fail(str(second_report.get("message", "repeated annual report document contract failed")))
		return
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Annual report document contract payload changed across repeated fixed-seed runs.")
		return

	var hash: String = _stable_hash(str(first_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual report document contract hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_REPORT_DOCUMENT_CONTRACT_OK %s" % JSON.stringify({
		"hash": hash,
		"company_id": str(first_report.get("company_id", "")),
		"fiscal_year": int(first_report.get("fiscal_year", 0)),
		"section_count": int(first_report.get("section_count", 0)),
		"note_count": int(first_report.get("note_count", 0))
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
	var validation: Dictionary = _validate_contract(snapshot, annual)
	if not bool(validation.get("success", false)):
		return validation
	return {
		"success": true,
		"payload": _contract_payload(company_id, annual, snapshot),
		"company_id": company_id,
		"fiscal_year": int(annual.get("fiscal_year", 0)),
		"section_count": _variant_array(annual.get("annual_report_section_map", [])).size(),
		"note_count": _variant_array(annual.get("note_index", [])).size()
	}


func _validate_contract(snapshot: Dictionary, annual: Dictionary) -> Dictionary:
	if annual.is_empty():
		return _case_fail("Expected annual statement.")
	var contract: Dictionary = annual.get("document_reading_contract", {}) if typeof(annual.get("document_reading_contract", {})) == TYPE_DICTIONARY else {}
	if contract.is_empty():
		return _case_fail("Expected document_reading_contract.")
	if int(contract.get("schema_version", 0)) != 1:
		return _case_fail("Expected document reading contract schema version 1.")
	if str(contract.get("document_reader_status", "")) != "r3_1_contract_ready":
		return _case_fail("Expected R3.1 contract-ready status.")
	if str(contract.get("page_size_hint", "")) != "A4":
		return _case_fail("Expected A4 page size hint.")
	if str(contract.get("statement_scope", "")) != "annual" or not bool(contract.get("consolidated", false)):
		return _case_fail("Expected annual consolidated document contract.")
	if _string_array(contract.get("section_order", [])) != _string_array(EXPECTED_SECTION_IDS):
		return _case_fail("Document contract section order changed.")
	if _string_array(contract.get("readable_section_ids", [])) != _string_array(["financial_position", "profit_or_loss_and_oci", "changes_in_equity", "cash_flows", "notes"]):
		return _case_fail("Readable statement section contract changed.")
	if not _variant_array(contract.get("compact_until_revision_section_ids", [])).is_empty():
		return _case_fail("Compact section contract changed.")

	var cross_reference: Dictionary = contract.get("cross_reference_behavior", {}) if typeof(contract.get("cross_reference_behavior", {})) == TYPE_DICTIONARY else {}
	if not bool(cross_reference.get("enabled", false)):
		return _case_fail("Expected cross-reference behavior to be enabled.")
	if str(cross_reference.get("source", "")) != "disclosure_packet_refs":
		return _case_fail("Expected disclosure_packet_refs cross-reference source.")
	if bool(cross_reference.get("hidden_truth_labels_visible", true)):
		return _case_fail("Hidden truth labels must not be visible in cross references.")

	var capture_behavior: Dictionary = contract.get("capture_behavior", {}) if typeof(contract.get("capture_behavior", {})) == TYPE_DICTIONARY else {}
	var statement_rows: Dictionary = capture_behavior.get("statement_rows", {}) if typeof(capture_behavior.get("statement_rows", {})) == TYPE_DICTIONARY else {}
	var note_paragraphs: Dictionary = capture_behavior.get("note_paragraphs", {}) if typeof(capture_behavior.get("note_paragraphs", {})) == TYPE_DICTIONARY else {}
	if str(statement_rows.get("capture_level", "")) != "line_item":
		return _case_fail("Expected line-item capture level for statement rows.")
	if str(note_paragraphs.get("capture_level", "")) != "note_paragraph":
		return _case_fail("Expected note-paragraph capture level for notes.")
	if not _string_array(note_paragraphs.get("preserve_fields", [])).has("source_disclosure_packet_ids"):
		return _case_fail("Expected note capture contract to preserve disclosure packet ids.")

	var section_map: Array = _variant_array(annual.get("annual_report_section_map", []))
	var toc_rows: Array = _variant_array(annual.get("table_of_contents", []))
	if section_map.size() != EXPECTED_SECTION_IDS.size():
		return _case_fail("Expected %d annual report section map rows." % EXPECTED_SECTION_IDS.size())
	if toc_rows.size() != EXPECTED_SECTION_IDS.size():
		return _case_fail("Expected %d table-of-contents rows." % EXPECTED_SECTION_IDS.size())
	for index in range(EXPECTED_SECTION_IDS.size()):
		var expected_section_id: String = str(EXPECTED_SECTION_IDS[index])
		var section: Dictionary = section_map[index] if typeof(section_map[index]) == TYPE_DICTIONARY else {}
		var toc: Dictionary = toc_rows[index] if typeof(toc_rows[index]) == TYPE_DICTIONARY else {}
		if str(section.get("section_id", "")) != expected_section_id:
			return _case_fail("Section map order changed at index %d." % index)
		if str(toc.get("section_id", "")) != expected_section_id:
			return _case_fail("Table of contents order changed at index %d." % index)
		if str(toc.get("page_label", "")) != str(EXPECTED_PAGE_LABELS.get(expected_section_id, "")):
			return _case_fail("Unexpected page label for %s: %s." % [expected_section_id, str(toc.get("page_label", ""))])
		if str(section.get("source_array", "")).is_empty():
			return _case_fail("Missing source array for %s." % expected_section_id)
		if str(section.get("title", "")).strip_edges().is_empty() or str(section.get("localized_title", "")).strip_edges().is_empty():
			return _case_fail("Missing bilingual section title for %s." % expected_section_id)

	if _variant_array(annual.get("note_index", [])).size() != EXPECTED_NOTE_COUNT:
		return _case_fail("Expected %d note-index rows." % EXPECTED_NOTE_COUNT)
	for note_index_value in _variant_array(annual.get("note_index", [])):
		if typeof(note_index_value) != TYPE_DICTIONARY:
			return _case_fail("Expected note-index dictionaries.")
		var note_index: Dictionary = note_index_value
		var note_number: int = int(note_index.get("note_number", 0))
		if note_number <= 0 or note_number > EXPECTED_NOTE_COUNT:
			return _case_fail("Unexpected note number %d." % note_number)

	for quarterly_value in _variant_array(snapshot.get("quarterly_statements", [])):
		if typeof(quarterly_value) == TYPE_DICTIONARY:
			var quarterly: Dictionary = quarterly_value
			if quarterly.has("document_reading_contract") or quarterly.has("annual_report_section_map") or quarterly.has("table_of_contents"):
				return _case_fail("Quarterly statement unexpectedly received annual document-reader fields.")
	return _case_ok()


func _contract_payload(company_id: String, annual: Dictionary, snapshot: Dictionary) -> String:
	var lines: Array[String] = []
	var contract: Dictionary = annual.get("document_reading_contract", {}) if typeof(annual.get("document_reading_contract", {})) == TYPE_DICTIONARY else {}
	lines.append("company=%s" % company_id)
	lines.append("statement=%s" % str(annual.get("statement_id", "")))
	lines.append("contract=%s:%s:%s" % [
		str(contract.get("contract_id", "")),
		str(contract.get("document_reader_status", "")),
		"|".join(_string_array(contract.get("section_order", [])))
	])
	for row_value in _variant_array(annual.get("table_of_contents", [])):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("toc:%s:%s:%s:%s:%s" % [
			str(row.get("section_number", "")),
			str(row.get("section_id", "")),
			str(row.get("title", "")),
			str(row.get("localized_title", "")),
			str(row.get("page_label", ""))
		])
	for row_value in _variant_array(annual.get("annual_report_section_map", [])):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("section:%s:%s:%s:%s:%s" % [
			str(row.get("section_id", "")),
			str(row.get("section_number", "")),
			str(row.get("source_array", "")),
			str(row.get("read_mode", "")),
			str(row.get("capture_mode", ""))
		])
	lines.append("readable=%s" % "|".join(_string_array(contract.get("readable_section_ids", []))))
	lines.append("compact=%s" % "|".join(_string_array(contract.get("compact_until_revision_section_ids", []))))
	lines.append("note_count=%d" % _variant_array(annual.get("note_index", [])).size())
	lines.append("quarterly_contract_fields=%d" % _quarterly_contract_field_count(snapshot))
	return "\n".join(lines)


func _quarterly_contract_field_count(snapshot: Dictionary) -> int:
	var count: int = 0
	for quarterly_value in _variant_array(snapshot.get("quarterly_statements", [])):
		if typeof(quarterly_value) != TYPE_DICTIONARY:
			continue
		var quarterly: Dictionary = quarterly_value
		for key in ["document_reading_contract", "annual_report_section_map", "table_of_contents"]:
			if quarterly.has(key):
				count += 1
	return count


func _case_ok() -> Dictionary:
	return {"success": true}


func _case_fail(message: String) -> Dictionary:
	return {"success": false, "message": message}


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


func _fail(message: String) -> void:
	push_error(message)
	print("ANNUAL_REPORT_DOCUMENT_CONTRACT_FAIL: %s" % message)
	get_tree().quit(1)
