extends Node

const ANNUAL_FILING_DOCUMENT = preload("res://systems/AnnualFilingDocument.gd")

const RUN_SEED := 20260621
const EXPECTED_HASH := "633579782"
const HIDDEN_VISIBLE_TOKENS := [
	"truth_state",
	"fraud_risk",
	"overhyped",
	"story|",
	"packet|",
	"placement|",
	"source_quality",
	"disclosure_quality",
	"confidence",
	"trade answer",
	"catatan",
	"laporan",
	"million_idr",
	"related note classifications",
	"note classifications",
	"classifications connect"
]
const FORBIDDEN_GENERIC_PHRASES := [
	"describes the recognition and movement",
	"same basis as the consolidated statements",
	"supporting schedule includes",
	"the note presentation should be read together",
	"this disclosure should be read together"
]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_report()
	if not bool(first_report.get("success", false)):
		_fail(str(first_report.get("message", "annual filing visible generation failed")))
		return
	var second_report: Dictionary = _build_report()
	if not bool(second_report.get("success", false)):
		_fail(str(second_report.get("message", "repeated annual filing visible generation failed")))
		return
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Annual filing visible generation payload changed across repeated fixed-seed runs.")
		return

	var hash: String = _stable_hash(str(first_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual filing visible generation hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_FILING_VISIBLE_GENERATION_OK %s" % JSON.stringify({
		"hash": hash,
		"company_id": str(first_report.get("company_id", "")),
		"fiscal_year": int(first_report.get("fiscal_year", 0)),
		"visible_filing_hash": str(first_report.get("visible_filing_hash", "")),
		"section_count": int(first_report.get("section_count", 0)),
		"paragraph_count": int(first_report.get("paragraph_count", 0)),
		"table_count": int(first_report.get("table_count", 0)),
		"cross_reference_count": int(first_report.get("cross_reference_count", 0))
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
	if _run_state_contains_filing_document():
		return _case_fail("RunState should not contain a derived annual filing document before request.")

	var options: Dictionary = {
		"ticker": str(definition.get("ticker", "")),
		"company_name": str(definition.get("name", "")),
		"sector_style_id": str(definition.get("sector_id", "generic_annual_filing"))
	}
	var contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(annual, int(RunState.run_seed), company_id, options)
	if contract.is_empty():
		return _case_fail("Expected annual filing request contract.")
	if bool(contract.get("visible_document_generated", false)):
		return _case_fail("Request contract should not materialize visible filing sections.")
	if contract.has("visible_filing_sections"):
		return _case_fail("Request contract should not carry visible filing sections.")

	var cache: Dictionary = {}
	var first_document: Dictionary = ANNUAL_FILING_DOCUMENT.get_or_build_document(cache, annual, int(RunState.run_seed), company_id, options)
	var validation: Dictionary = _validate_visible_document(first_document, annual, "miss_built")
	if not bool(validation.get("success", false)):
		return validation
	if cache.size() != 1:
		return _case_fail("Expected one cached visible filing document after first request.")
	var first_hash: String = ANNUAL_FILING_DOCUMENT.document_hash(first_document)
	var second_document: Dictionary = ANNUAL_FILING_DOCUMENT.get_or_build_document(cache, annual, int(RunState.run_seed), company_id, options)
	validation = _validate_visible_document(second_document, annual, "hit")
	if not bool(validation.get("success", false)):
		return validation
	if not bool(second_document.get("cache_hit", false)):
		return _case_fail("Second visible filing request should be a cache hit.")
	if str(second_document.get("cache_key", "")) != str(first_document.get("cache_key", "")):
		return _case_fail("Visible filing cache key changed between first and second request.")
	if ANNUAL_FILING_DOCUMENT.document_hash(second_document) != first_hash:
		return _case_fail("Visible filing document hash changed between cache miss and hit.")
	if str(second_document.get("visible_filing_hash", "")) != str(first_document.get("visible_filing_hash", "")):
		return _case_fail("Visible filing content hash changed between cache miss and hit.")
	if _run_state_contains_filing_document():
		return _case_fail("RunState should not save/cache derived visible annual filing documents after request.")

	return {
		"success": true,
		"payload": _payload(first_document, second_document),
		"company_id": company_id,
		"fiscal_year": int(first_document.get("fiscal_year", 0)),
		"visible_filing_hash": str(first_document.get("visible_filing_hash", "")),
		"section_count": int(first_document.get("visible_filing_section_count", 0)),
		"paragraph_count": int(first_document.get("visible_filing_paragraph_count", 0)),
		"table_count": int(first_document.get("visible_filing_table_count", 0)),
		"cross_reference_count": int(first_document.get("visible_filing_cross_reference_count", 0))
	}


func _validate_visible_document(document: Dictionary, annual: Dictionary, expected_cache_status: String) -> Dictionary:
	if document.is_empty():
		return _case_fail("Expected visible annual filing document.")
	if str(document.get("cache_status", "")) != expected_cache_status:
		return _case_fail("Expected visible filing cache status %s." % expected_cache_status)
	if str(document.get("display_source", "")) != "visible_filing_document":
		return _case_fail("Expected visible filing display source.")
	if not bool(document.get("visible_document_generated", false)):
		return _case_fail("Expected visible annual filing document to be generated.")
	if not bool(document.get("visible_sections_materialized", false)):
		return _case_fail("Expected visible annual filing sections to be materialized.")
	if str(document.get("full_filing_generation_status", "")) != "task5_visible_filing_generated":
		return _case_fail("Expected Task 5 visible filing generation status.")
	if int(document.get("visible_filing_schema_version", 0)) != 1:
		return _case_fail("Expected visible filing schema version 1.")
	if str(document.get("visible_filing_status", "")) != "task5_visible_filing_ready":
		return _case_fail("Expected Task 5 visible filing status.")
	if str(document.get("visible_filing_hash", "")).strip_edges().is_empty():
		return _case_fail("Expected visible filing hash.")
	if str(document.get("visible_filing_hash", "")) != ANNUAL_FILING_DOCUMENT.visible_filing_hash(document):
		return _case_fail("Visible filing hash helper mismatch.")
	var sections: Array = _variant_array(document.get("visible_filing_sections", []))
	if sections.size() < 8 or sections.size() > 16:
		return _case_fail("Expected compact story-led annual filing section materialization, got %d sections." % sections.size())
	var report_map: Array = _variant_array(document.get("annual_report_section_map", []))
	if report_map.size() != sections.size() - 1:
		return _case_fail("Expected report map to omit only the generated table-of-contents section.")
	var section_order: Array = _string_array(document.get("visible_filing_section_order", []))
	for required_section in ["cover", "financial_position", "profit_or_loss_and_oci", "changes_in_equity", "cash_flows", "note_segment_information"]:
		if not section_order.has(required_section):
			return _case_fail("Visible filing missing required section %s." % required_section)
	var sections_by_id: Dictionary = document.get("visible_filing_sections_by_id", {}) if typeof(document.get("visible_filing_sections_by_id", {})) == TYPE_DICTIONARY else {}
	if not sections_by_id.has("cover") or not sections_by_id.has("note_segment_information"):
		return _case_fail("Expected visible filing section lookup.")
	var financial_position: Dictionary = sections_by_id.get("financial_position", {}) if typeof(sections_by_id.get("financial_position", {})) == TYPE_DICTIONARY else {}
	if _variant_array(financial_position.get("statement_rows", [])).is_empty():
		return _case_fail("Expected primary statement rows in visible filing document.")
	if int(document.get("visible_filing_paragraph_count", 0)) <= 0:
		return _case_fail("Expected visible filing paragraphs.")
	if int(document.get("visible_filing_table_count", 0)) <= 0:
		return _case_fail("Expected visible filing compact tables.")
	if int(document.get("visible_filing_cross_reference_count", 0)) != 0:
		return _case_fail("Expected visible filing cross references to stay hidden from reader output.")
	if int(document.get("visible_filing_display_block_count", 0)) <= 0:
		return _case_fail("Expected visible filing display blocks.")
	var balance: Dictionary = document.get("visible_filing_profile_balance", {}) if typeof(document.get("visible_filing_profile_balance", {})) == TYPE_DICTIONARY else {}
	if balance.is_empty() or not bool(balance.get("target_met", false)):
		return _case_fail("Expected visible filing profile balance target to be met.")
	if int(balance.get("story_note_paragraph_count", 0)) <= 0:
		return _case_fail("Expected compact visible filing to include story-bearing note paragraphs.")
	if _string_array(document.get("visible_filing_assembly_priority", [])) != ["statement_rows", "compact_table", "comparative_movement", "cross_reference", "formal_lead_in", "limited_prose"]:
		return _case_fail("Expected visible filing assembly priority contract.")
	var sources: Dictionary = document.get("visible_generation_sources", {}) if typeof(document.get("visible_generation_sources", {})) == TYPE_DICTIONARY else {}
	if str(sources.get("generation_mode", "")) != "on_button_request":
		return _case_fail("Expected visible filing generation source mode.")
	if bool(sources.get("saved_to_run_state", true)):
		return _case_fail("Visible filing generation sources should report no RunState save.")
	if str(document.get("source_statement_id", "")) != str(annual.get("statement_id", "")):
		return _case_fail("Visible filing source statement id changed.")
	var source_statement: Dictionary = document.get("source_annual_statement", {}) if typeof(document.get("source_annual_statement", {})) == TYPE_DICTIONARY else {}
	if source_statement.is_empty():
		return _case_fail("Visible filing document should retain source annual statement for traceability.")
	return _validate_visible_text(sections)


func _validate_visible_text(sections: Array) -> Dictionary:
	for section_value in sections:
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		var title_text: String = str(section.get("title", "")).to_lower()
		var localized_title: String = str(section.get("localized_title", "")).strip_edges()
		var section_id: String = str(section.get("section_id", ""))
		if not localized_title.is_empty():
			return _case_fail("Visible filing should not expose localized title: %s" % localized_title)
		if str(section.get("document_part", "")) == "notes" and title_text.begins_with("notes -"):
			return _case_fail("Visible filing note section title should not keep Notes prefix: %s" % str(section.get("title", "")))
		var seen_paragraph_text: Dictionary = {}
		for token in HIDDEN_VISIBLE_TOKENS:
			if title_text.contains(str(token)):
				return _case_fail("Visible filing section title leaked hidden token %s." % str(token))
		var block_validation: Dictionary = _validate_display_blocks(section)
		if not bool(block_validation.get("success", false)):
			return block_validation
		for paragraph_value in _variant_array(section.get("paragraphs", [])):
			if typeof(paragraph_value) != TYPE_DICTIONARY:
				continue
			var paragraph: Dictionary = paragraph_value
			var text: String = str(paragraph.get("text", "")).strip_edges()
			if text.is_empty():
				return _case_fail("Expected visible filing paragraph text.")
			var text_key: String = text.to_lower()
			if seen_paragraph_text.has(text_key):
				return _case_fail("Visible filing section %s repeated paragraph text: %s" % [section_id, text])
			seen_paragraph_text[text_key] = true
			var lower_text: String = text.to_lower()
			for token in HIDDEN_VISIBLE_TOKENS:
				if lower_text.contains(str(token)):
					return _case_fail("Visible filing paragraph leaked hidden token %s." % str(token))
			for phrase in FORBIDDEN_GENERIC_PHRASES:
				if lower_text.contains(str(phrase)):
					return _case_fail("Visible filing paragraph retained forbidden generic phrase: %s." % str(phrase))
		var seen_reference_text: Dictionary = {}
		for reference_value in _variant_array(section.get("cross_references", [])):
			if typeof(reference_value) != TYPE_DICTIONARY:
				continue
			var reference: Dictionary = reference_value
			var display_text: String = str(reference.get("display_text", "")).strip_edges()
			if display_text.is_empty():
				return _case_fail("Expected visible filing cross-reference text.")
			var reference_key: String = display_text.to_lower()
			if seen_reference_text.has(reference_key):
				return _case_fail("Visible filing section %s repeated cross-reference text: %s" % [section_id, display_text])
			for phrase in FORBIDDEN_GENERIC_PHRASES:
				if reference_key.contains(str(phrase)):
					return _case_fail("Visible filing cross-reference retained forbidden generic phrase: %s." % str(phrase))
			seen_reference_text[reference_key] = true
		var seen_table_rows: Dictionary = {}
		for table_value in _variant_array(section.get("compact_tables", [])):
			if typeof(table_value) != TYPE_DICTIONARY:
				continue
			var table: Dictionary = table_value
			for row_value in _variant_array(table.get("rows", [])):
				if typeof(row_value) != TYPE_DICTIONARY:
					continue
				var table_row: Dictionary = row_value
				if not str(table_row.get("related_note", "")).strip_edges().is_empty():
					return _case_fail("Visible filing table rows should not expose related-note metadata.")
				if str(table_row.get("fy_value", "")).find("million_idr") != -1:
					return _case_fail("Visible filing table row leaked raw unit token.")
				var row_key: String = "%s|%s|%s" % [
					str(table_row.get("caption", "")).strip_edges().to_lower(),
					str(table_row.get("fy_value", "")).strip_edges().to_lower(),
					str(table_row.get("related_note", "")).strip_edges().to_lower()
				]
				if seen_table_rows.has(row_key):
					return _case_fail("Visible filing section %s repeated table row: %s" % [section_id, row_key])
				seen_table_rows[row_key] = true
	return _case_ok()


func _validate_display_blocks(section: Dictionary) -> Dictionary:
	var content_count: int = _variant_array(section.get("paragraphs", [])).size() + _variant_array(section.get("compact_tables", [])).size() + _variant_array(section.get("cross_references", [])).size()
	var blocks: Array = _variant_array(section.get("display_blocks", []))
	if content_count > 0 and blocks.is_empty():
		return _case_fail("Visible filing section %s has content but no display blocks." % str(section.get("section_id", "")))
	if content_count != blocks.size():
		return _case_fail("Visible filing section %s display block count mismatch." % str(section.get("section_id", "")))
	var last_rank: int = -1
	for block_value in blocks:
		if typeof(block_value) != TYPE_DICTIONARY:
			return _case_fail("Expected display block dictionaries.")
		var block: Dictionary = block_value
		var block_type: String = str(block.get("block_type", "")).strip_edges()
		var rank: int = _display_block_rank(block_type)
		if rank < last_rank:
			return _case_fail("Visible filing section %s display blocks are not table-first." % str(section.get("section_id", "")))
		last_rank = rank
	if not _variant_array(section.get("compact_tables", [])).is_empty():
		var first_block: Dictionary = blocks[0] if blocks.size() > 0 and typeof(blocks[0]) == TYPE_DICTIONARY else {}
		if str(first_block.get("block_type", "")) != "compact_table":
			return _case_fail("Visible filing section %s should render compact tables first." % str(section.get("section_id", "")))
	return _case_ok()


func _display_block_rank(block_type: String) -> int:
	match block_type:
		"compact_table":
			return 0
		"cross_reference":
			return 1
		"paragraph":
			return 2
	return 99


func _payload(first_document: Dictionary, second_document: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("first=%s:%s:%s:%s" % [
		str(first_document.get("cache_status", "")),
		str(first_document.get("display_source", "")),
		str(first_document.get("visible_document_generated", "")),
		str(first_document.get("full_filing_generation_status", ""))
	])
	lines.append("second=%s:%s:%s:%s" % [
		str(second_document.get("cache_status", "")),
		str(second_document.get("display_source", "")),
		str(second_document.get("visible_document_generated", "")),
		str(second_document.get("full_filing_generation_status", ""))
	])
	lines.append("visible_hash=%s" % str(first_document.get("visible_filing_hash", "")))
	lines.append("doc_hash=%s" % ANNUAL_FILING_DOCUMENT.document_hash(first_document))
	var balance: Dictionary = first_document.get("visible_filing_profile_balance", {}) if typeof(first_document.get("visible_filing_profile_balance", {})) == TYPE_DICTIONARY else {}
	lines.append("counts=%d:%d:%d:%d:%d:%d" % [
		int(first_document.get("visible_filing_section_count", 0)),
		int(first_document.get("visible_filing_paragraph_count", 0)),
		int(first_document.get("visible_filing_table_count", 0)),
		int(first_document.get("visible_filing_table_row_count", 0)),
		int(first_document.get("visible_filing_display_block_count", 0)),
		int(first_document.get("visible_filing_cross_reference_count", 0))
	])
	lines.append("assembly=%s" % "|".join(_string_array(first_document.get("visible_filing_assembly_priority", []))))
	lines.append("balance=%s:%s:%s:%s:%s" % [
		str(balance.get("filing_profile_id", "")),
		str(balance.get("target_met", "")),
		String.num(float(balance.get("actual_table_to_note_prose_ratio", 0.0)), 3),
		String.num(float(balance.get("target_table_to_note_prose_ratio", 0.0)), 3),
		int(balance.get("display_block_count", 0))
	])
	lines.append("sections=%s" % "|".join(_string_array(first_document.get("visible_filing_section_order", []))))
	lines.append("report_map_count=%d" % _variant_array(first_document.get("annual_report_section_map", [])).size())
	lines.append("sources=%s" % _dict_payload(first_document.get("visible_generation_sources", {})))
	return "\n".join(lines)


func _run_state_contains_filing_document() -> bool:
	var save_text: String = JSON.stringify(RunState.to_save_dict())
	return save_text.contains("annual_filing_document") or save_text.contains("annual_filing_reader_r1") or save_text.contains("visible_filing")


func _case_ok() -> Dictionary:
	return {"success": true}


func _case_fail(message: String) -> Dictionary:
	return {
		"success": false,
		"message": message
	}


func _fail(message: String) -> void:
	push_error(message)
	print("ANNUAL_FILING_VISIBLE_GENERATION_FAIL: %s" % message)
	get_tree().quit(1)


func _dict_payload(source_value: Variant) -> String:
	if typeof(source_value) != TYPE_DICTIONARY:
		return ""
	var source: Dictionary = source_value
	var keys: Array = source.keys()
	keys.sort()
	var lines: Array[String] = []
	for key_value in keys:
		var key: String = str(key_value)
		var value = source.get(key, "")
		if typeof(value) == TYPE_ARRAY:
			lines.append("%s=[%s]" % [key, "|".join(_string_array(value))])
		else:
			lines.append("%s=%s" % [key, str(value)])
	return ";".join(lines)


func _string_array(source_value: Variant) -> Array:
	var rows: Array = []
	for item_value in _variant_array(source_value):
		var text: String = str(item_value).strip_edges()
		if not text.is_empty() and not rows.has(text):
			rows.append(text)
	return rows


func _variant_array(source_value: Variant) -> Array:
	if typeof(source_value) == TYPE_ARRAY:
		return source_value.duplicate(true)
	return []


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int(hash_value ^ text.unicode_at(index))
		hash_value = int((hash_value * 16777619) & 0x7fffffff)
	return str(hash_value)
