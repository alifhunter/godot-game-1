extends Node

const ANNUAL_FILING_DOCUMENT = preload("res://systems/AnnualFilingDocument.gd")

const RUN_SEED := 20260621
const EXPECTED_HASH := "1869439697"
const MAX_CONTRACT_USEC := 1000000
const MAX_FIRST_BUILD_USEC := 1000000
const MAX_CACHE_HIT_USEC := 250000
const MAX_VISIBLE_DOCUMENT_CHARS := 1000000
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
const REQUIRED_VISIBLE_SECTION_IDS := [
	"cover",
	"financial_position",
	"profit_or_loss_and_oci",
	"changes_in_equity",
	"cash_flows",
	"note_segment_information"
]
const PRIMARY_PAGE_LABELS := {
	"financial_position": "1-3",
	"profit_or_loss_and_oci": "4-5",
	"changes_in_equity": "6-7",
	"cash_flows": "8-9"
}
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
		_fail(str(first_report.get("message", "annual filing regression guard failed")))
		return
	var second_report: Dictionary = _build_report()
	if not bool(second_report.get("success", false)):
		_fail(str(second_report.get("message", "repeated annual filing regression guard failed")))
		return
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Annual filing regression guard payload changed across repeated fixed-seed runs.")
		return

	var hash: String = _stable_hash(str(first_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual filing regression guard hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_FILING_REGRESSION_GUARD_OK %s" % JSON.stringify({
		"hash": hash,
		"company_id": str(first_report.get("company_id", "")),
		"fiscal_year": int(first_report.get("fiscal_year", 0)),
		"visible_filing_hash": str(first_report.get("visible_filing_hash", "")),
		"document_chars": int(first_report.get("document_chars", 0)),
		"contract_ms": String.num(float(first_report.get("contract_usec", 0)) / 1000.0, 2),
		"first_build_ms": String.num(float(first_report.get("first_build_usec", 0)) / 1000.0, 2),
		"cache_hit_ms": String.num(float(first_report.get("cache_hit_usec", 0)) / 1000.0, 2)
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
	if _run_state_contains_derived_filing():
		return _case_fail("RunState should not contain derived annual filing display data before request.")

	var options: Dictionary = {
		"ticker": str(definition.get("ticker", "")),
		"company_name": str(definition.get("name", "")),
		"sector_style_id": str(definition.get("sector_id", "generic_annual_filing")),
		"sector_id": str(definition.get("sector_id", definition.get("sector", ""))),
		"subsector_id": str(definition.get("subsector_id", definition.get("subsector", ""))),
		"business_summary": str(definition.get("business_summary", "")),
		"moat_tags": _variant_array(definition.get("moat_tags", [])),
		"story_hooks": _variant_array(definition.get("story_hooks", []))
	}
	var contract_started_at: int = Time.get_ticks_usec()
	var contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(annual, int(RunState.run_seed), company_id, options)
	var contract_usec: int = Time.get_ticks_usec() - contract_started_at
	var contract_validation: Dictionary = _validate_contract_only(contract, annual)
	if not bool(contract_validation.get("success", false)):
		return contract_validation
	if contract_usec > MAX_CONTRACT_USEC:
		return _case_fail("Annual filing request contract exceeded guardrail: %dus." % contract_usec)

	var cache: Dictionary = {}
	var first_started_at: int = Time.get_ticks_usec()
	var first_document: Dictionary = ANNUAL_FILING_DOCUMENT.get_or_build_document(cache, annual, int(RunState.run_seed), company_id, options)
	var first_build_usec: int = Time.get_ticks_usec() - first_started_at
	if first_build_usec > MAX_FIRST_BUILD_USEC:
		return _case_fail("Annual filing first generated document exceeded guardrail: %dus." % first_build_usec)
	var first_validation: Dictionary = _validate_visible_document(first_document, annual, "miss_built")
	if not bool(first_validation.get("success", false)):
		return first_validation
	if cache.size() != 1:
		return _case_fail("Expected exactly one annual filing document in runtime cache after first build.")

	var second_started_at: int = Time.get_ticks_usec()
	var second_document: Dictionary = ANNUAL_FILING_DOCUMENT.get_or_build_document(cache, annual, int(RunState.run_seed), company_id, options)
	var cache_hit_usec: int = Time.get_ticks_usec() - second_started_at
	if cache_hit_usec > MAX_CACHE_HIT_USEC:
		return _case_fail("Annual filing cache hit exceeded guardrail: %dus." % cache_hit_usec)
	var second_validation: Dictionary = _validate_visible_document(second_document, annual, "hit")
	if not bool(second_validation.get("success", false)):
		return second_validation
	if not bool(second_document.get("cache_hit", false)):
		return _case_fail("Second annual filing request should be a cache hit.")
	if str(second_document.get("cache_key", "")) != str(first_document.get("cache_key", "")):
		return _case_fail("Annual filing cache key changed between miss and hit.")
	if ANNUAL_FILING_DOCUMENT.document_hash(second_document) != ANNUAL_FILING_DOCUMENT.document_hash(first_document):
		return _case_fail("Annual filing document hash changed between miss and hit.")
	if str(second_document.get("visible_filing_hash", "")) != str(first_document.get("visible_filing_hash", "")):
		return _case_fail("Visible filing hash changed between miss and hit.")
	if _run_state_contains_derived_filing():
		return _case_fail("RunState should not save/cache derived annual filing display data after request.")

	var changed_source: Dictionary = annual.duplicate(true)
	var changed_traceability: Dictionary = changed_source.get("traceability", {}) if typeof(changed_source.get("traceability", {})) == TYPE_DICTIONARY else {}
	changed_traceability = changed_traceability.duplicate(true)
	changed_traceability["disclosure_packet_render_visible_paragraph_count"] = int(changed_traceability.get("disclosure_packet_render_visible_paragraph_count", 0)) + 1
	changed_source["traceability"] = changed_traceability
	var changed_contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(changed_source, int(RunState.run_seed), company_id, options)
	if str(changed_contract.get("cache_key", "")) == str(contract.get("cache_key", "")):
		return _case_fail("Annual filing cache key should change when source state changes.")

	var document_chars: int = JSON.stringify(first_document).length()
	if document_chars <= 0 or document_chars > MAX_VISIBLE_DOCUMENT_CHARS:
		return _case_fail("Annual filing generated document size guardrail failed: %d chars." % document_chars)

	return {
		"success": true,
		"payload": _payload(contract, first_document, second_document, document_chars),
		"company_id": company_id,
		"fiscal_year": int(first_document.get("fiscal_year", 0)),
		"visible_filing_hash": str(first_document.get("visible_filing_hash", "")),
		"document_chars": document_chars,
		"contract_usec": contract_usec,
		"first_build_usec": first_build_usec,
		"cache_hit_usec": cache_hit_usec
	}


func _validate_contract_only(contract: Dictionary, annual: Dictionary) -> Dictionary:
	if contract.is_empty():
		return _case_fail("Expected annual filing request contract.")
	if str(contract.get("generation_timing", "")) != "lazy_on_request":
		return _case_fail("Expected lazy-on-request generation timing.")
	if str(contract.get("cache_owner", "")) != "in_memory_runtime":
		return _case_fail("Expected in-memory runtime cache owner.")
	if bool(contract.get("saved_cache_allowed", true)):
		return _case_fail("Annual filing contract should not allow saved cache.")
	if contract.has("visible_filing_sections") or bool(contract.get("visible_document_generated", false)):
		return _case_fail("Request contract should not materialize visible annual filing sections.")
	if str(contract.get("full_filing_generation_status", "")) != "contract_only_until_task_5":
		return _case_fail("Request contract should remain contract-only before generated document request.")
	if str(contract.get("source_statement_id", "")) != str(annual.get("statement_id", "")):
		return _case_fail("Annual filing contract source statement id mismatch.")
	if int(contract.get("filing_profile_schema_version", 0)) != 1:
		return _case_fail("Expected annual filing profile schema version 1.")
	if str(contract.get("filing_profile_status", "")) != "task2_profile_contract_ready":
		return _case_fail("Expected Task 2 annual filing profile status.")
	if str(contract.get("filing_profile_id", "")).strip_edges().is_empty():
		return _case_fail("Expected annual filing profile id.")
	if str(contract.get("filing_profile_version", "")).strip_edges().is_empty():
		return _case_fail("Expected annual filing profile version.")
	var key_parts: Dictionary = contract.get("cache_key_parts", {}) if typeof(contract.get("cache_key_parts", {})) == TYPE_DICTIONARY else {}
	for required_key in ["run_seed", "company_id", "fiscal_year", "filing_version", "language_id", "sector_style_id", "filing_profile_id", "filing_profile_version", "source_state_hash", "filing_schema_hash", "accounting_footprint_hash", "filing_prose_hash"]:
		if not key_parts.has(required_key):
			return _case_fail("Annual filing cache key parts missing %s." % str(required_key))
	return _validate_anatomy_rows(_variant_array(contract.get("filing_section_schema", [])), _variant_array(contract.get("filing_table_of_contents", [])))


func _validate_visible_document(document: Dictionary, annual: Dictionary, expected_cache_status: String) -> Dictionary:
	if document.is_empty():
		return _case_fail("Expected annual filing generated document.")
	if str(document.get("cache_status", "")) != expected_cache_status:
		return _case_fail("Expected annual filing cache status %s." % expected_cache_status)
	if str(document.get("display_source", "")) != "visible_filing_document":
		return _case_fail("Expected annual filing visible display source.")
	if not bool(document.get("visible_document_generated", false)) or not bool(document.get("visible_sections_materialized", false)):
		return _case_fail("Expected annual filing visible sections to be materialized.")
	if str(document.get("full_filing_generation_status", "")) != "task5_visible_filing_generated":
		return _case_fail("Expected generated filing status from Task 5.")
	if str(document.get("visible_filing_hash", "")) != ANNUAL_FILING_DOCUMENT.visible_filing_hash(document):
		return _case_fail("Visible filing hash helper mismatch.")
	if str(document.get("source_statement_id", "")) != str(annual.get("statement_id", "")):
		return _case_fail("Generated annual filing source statement id mismatch.")
	var section_order: Array = _string_array(document.get("visible_filing_section_order", []))
	for required_section in REQUIRED_VISIBLE_SECTION_IDS:
		if not section_order.has(required_section):
			return _case_fail("Generated compact annual filing missing visible section %s." % required_section)
	if int(document.get("visible_filing_section_count", 0)) < 8 or int(document.get("visible_filing_section_count", 0)) > 16:
		return _case_fail("Expected compact visible annual filing section count, got %d." % int(document.get("visible_filing_section_count", 0)))
	if int(document.get("visible_filing_paragraph_count", 0)) < 8 or int(document.get("visible_filing_paragraph_count", 0)) > 60:
		return _case_fail("Annual filing paragraph count outside guardrail: %d." % int(document.get("visible_filing_paragraph_count", 0)))
	if int(document.get("visible_filing_table_count", 0)) < 3 or int(document.get("visible_filing_table_count", 0)) > 12:
		return _case_fail("Annual filing compact table count outside guardrail: %d." % int(document.get("visible_filing_table_count", 0)))
	if int(document.get("visible_filing_cross_reference_count", 0)) != 0:
		return _case_fail("Annual filing cross-reference blocks should stay hidden from reader output.")
	if int(document.get("visible_filing_display_block_count", 0)) <= 0:
		return _case_fail("Expected annual filing display blocks.")
	var balance: Dictionary = document.get("visible_filing_profile_balance", {}) if typeof(document.get("visible_filing_profile_balance", {})) == TYPE_DICTIONARY else {}
	if balance.is_empty() or not bool(balance.get("target_met", false)):
		return _case_fail("Annual filing profile balance target was not met.")
	if int(balance.get("story_note_paragraph_count", 0)) <= 0:
		return _case_fail("Expected generated compact annual filing to include story-bearing note paragraphs.")
	var report_map: Array = _variant_array(document.get("annual_report_section_map", []))
	if report_map.size() != int(document.get("visible_filing_section_count", 0)) - 1:
		return _case_fail("Expected generated report map to omit only the table-of-contents section.")
	var sections_by_id: Dictionary = document.get("visible_filing_sections_by_id", {}) if typeof(document.get("visible_filing_sections_by_id", {})) == TYPE_DICTIONARY else {}
	for required_section in REQUIRED_VISIBLE_SECTION_IDS:
		if not sections_by_id.has(required_section):
			return _case_fail("Generated annual filing missing required section %s." % required_section)
	var financial_position: Dictionary = sections_by_id.get("financial_position", {}) if typeof(sections_by_id.get("financial_position", {})) == TYPE_DICTIONARY else {}
	if _variant_array(financial_position.get("statement_rows", [])).is_empty():
		return _case_fail("Generated annual filing should include statement rows.")
	var sources: Dictionary = document.get("visible_generation_sources", {}) if typeof(document.get("visible_generation_sources", {})) == TYPE_DICTIONARY else {}
	if str(sources.get("generation_mode", "")) != "on_button_request" or bool(sources.get("saved_to_run_state", true)):
		return _case_fail("Generated annual filing source metadata should stay lazy and unsaved.")
	return _validate_visible_sections(_variant_array(document.get("visible_filing_sections", [])))


func _validate_anatomy_rows(schema: Array, toc: Array) -> Dictionary:
	if _section_ids(schema) != EXPECTED_SECTION_IDS:
		return _case_fail("Annual filing anatomy schema order changed.")
	if _section_ids(toc) != EXPECTED_SECTION_IDS:
		return _case_fail("Annual filing table-of-contents order changed.")
	var front_matter_count: int = 0
	var primary_count: int = 0
	var note_count: int = 0
	for row_value in schema:
		if typeof(row_value) != TYPE_DICTIONARY:
			return _case_fail("Expected annual filing anatomy rows to be dictionaries.")
		var row: Dictionary = row_value
		match str(row.get("document_part", "")):
			"front_matter":
				front_matter_count += 1
			"primary_statement":
				primary_count += 1
			"notes":
				note_count += 1
		var section_id: String = str(row.get("section_id", ""))
		if PRIMARY_PAGE_LABELS.has(section_id) and str(row.get("page_label", "")) != str(PRIMARY_PAGE_LABELS.get(section_id, "")):
			return _case_fail("Annual filing primary statement page label changed for %s." % section_id)
	if front_matter_count != 4 or primary_count != 4 or note_count != 12:
		return _case_fail("Annual filing anatomy part counts changed.")
	return _case_ok()


func _validate_visible_sections(sections: Array) -> Dictionary:
	if sections.size() < 8 or sections.size() > 16:
		return _case_fail("Expected compact generated annual filing sections, got %d." % sections.size())
	for section_value in sections:
		if typeof(section_value) != TYPE_DICTIONARY:
			return _case_fail("Expected annual filing visible sections to be dictionaries.")
		var section: Dictionary = section_value
		var section_id: String = str(section.get("section_id", ""))
		var lower_title: String = str(section.get("title", "")).to_lower()
		var localized_title: String = str(section.get("localized_title", "")).strip_edges()
		if not localized_title.is_empty():
			return _case_fail("Annual filing should not expose localized title: %s" % localized_title)
		if str(section.get("document_part", "")) == "notes" and lower_title.begins_with("notes -"):
			return _case_fail("Annual filing visible note section title should not keep Notes prefix: %s" % str(section.get("title", "")))
		var seen_paragraph_text: Dictionary = {}
		for token in HIDDEN_VISIBLE_TOKENS:
			if lower_title.contains(str(token)):
				return _case_fail("Annual filing visible title leaked hidden token %s." % str(token))
		var block_validation: Dictionary = _validate_display_blocks(section)
		if not bool(block_validation.get("success", false)):
			return block_validation
		for paragraph_value in _variant_array(section.get("paragraphs", [])):
			if typeof(paragraph_value) != TYPE_DICTIONARY:
				return _case_fail("Expected annual filing paragraphs to be dictionaries.")
			var text: String = str(paragraph_value.get("text", "")).strip_edges()
			if text.is_empty():
				return _case_fail("Expected annual filing paragraph text.")
			var lower_text: String = text.to_lower()
			if seen_paragraph_text.has(lower_text):
				return _case_fail("Annual filing section %s repeated paragraph text: %s" % [section_id, text])
			seen_paragraph_text[lower_text] = true
			for token in HIDDEN_VISIBLE_TOKENS:
				if lower_text.contains(str(token)):
					return _case_fail("Annual filing paragraph leaked hidden token %s." % str(token))
			for phrase in FORBIDDEN_GENERIC_PHRASES:
				if lower_text.contains(str(phrase)):
					return _case_fail("Annual filing paragraph retained forbidden generic phrase: %s." % str(phrase))
		for table_value in _variant_array(section.get("compact_tables", [])):
			if typeof(table_value) != TYPE_DICTIONARY:
				return _case_fail("Expected annual filing compact table dictionaries.")
			var table: Dictionary = table_value
			if str(table.get("title", "")).strip_edges().is_empty() or _variant_array(table.get("rows", [])).is_empty():
				return _case_fail("Expected annual filing compact tables to have titles and rows.")
			var seen_table_rows: Dictionary = {}
			for row_value in _variant_array(table.get("rows", [])):
				if typeof(row_value) != TYPE_DICTIONARY:
					return _case_fail("Expected annual filing compact table row dictionaries.")
				var table_row: Dictionary = row_value
				if not str(table_row.get("related_note", "")).strip_edges().is_empty():
					return _case_fail("Annual filing table rows should not expose related-note metadata.")
				if str(table_row.get("fy_value", "")).find("million_idr") != -1:
					return _case_fail("Annual filing table row leaked raw unit token.")
				if str(table_row.get("fy_value", "")).strip_edges().length() > 14:
					return _case_fail("Annual filing table row value was not compact: %s." % str(table_row.get("fy_value", "")))
				var row_key: String = "%s|%s|%s" % [
					str(table_row.get("caption", "")).strip_edges().to_lower(),
					str(table_row.get("fy_value", "")).strip_edges().to_lower(),
					str(table_row.get("related_note", "")).strip_edges().to_lower()
				]
				if seen_table_rows.has(row_key):
					return _case_fail("Annual filing section %s repeated compact table row: %s" % [section_id, row_key])
				seen_table_rows[row_key] = true
		var seen_reference_text: Dictionary = {}
		for ref_value in _variant_array(section.get("cross_references", [])):
			if typeof(ref_value) != TYPE_DICTIONARY:
				return _case_fail("Expected annual filing cross-reference dictionaries.")
			var ref: Dictionary = ref_value
			var display_text: String = str(ref.get("display_text", "")).strip_edges()
			if display_text.is_empty():
				return _case_fail("Expected annual filing cross-reference display text.")
			var display_key: String = display_text.to_lower()
			if seen_reference_text.has(display_key):
				return _case_fail("Annual filing section %s repeated cross-reference text: %s" % [section_id, display_text])
			for phrase in FORBIDDEN_GENERIC_PHRASES:
				if display_key.contains(str(phrase)):
					return _case_fail("Annual filing cross-reference retained forbidden generic phrase: %s." % str(phrase))
			seen_reference_text[display_key] = true
	return _case_ok()


func _validate_display_blocks(section: Dictionary) -> Dictionary:
	var content_count: int = _variant_array(section.get("paragraphs", [])).size() + _variant_array(section.get("compact_tables", [])).size() + _variant_array(section.get("cross_references", [])).size()
	var blocks: Array = _variant_array(section.get("display_blocks", []))
	if content_count > 0 and blocks.is_empty():
		return _case_fail("Annual filing section %s has content but no display blocks." % str(section.get("section_id", "")))
	if content_count != blocks.size():
		return _case_fail("Annual filing section %s display block count mismatch." % str(section.get("section_id", "")))
	var last_rank: int = -1
	for block_value in blocks:
		if typeof(block_value) != TYPE_DICTIONARY:
			return _case_fail("Expected annual filing display block dictionaries.")
		var block: Dictionary = block_value
		var rank: int = _display_block_rank(str(block.get("block_type", "")))
		if rank < last_rank:
			return _case_fail("Annual filing section %s display blocks are not table-first." % str(section.get("section_id", "")))
		last_rank = rank
	if not _variant_array(section.get("compact_tables", [])).is_empty():
		var first_block: Dictionary = blocks[0] if blocks.size() > 0 and typeof(blocks[0]) == TYPE_DICTIONARY else {}
		if str(first_block.get("block_type", "")) != "compact_table":
			return _case_fail("Annual filing section %s should render compact tables first." % str(section.get("section_id", "")))
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


func _payload(contract: Dictionary, first_document: Dictionary, second_document: Dictionary, document_chars: int) -> String:
	var lines: Array[String] = []
	lines.append("cache_key=%s" % str(contract.get("cache_key", "")))
	lines.append("source_hash=%s" % str(contract.get("source_state_hash", "")))
	lines.append("schema_hash=%s" % str(contract.get("filing_schema_hash", "")))
	lines.append("footprint_hash=%s" % str(contract.get("accounting_footprint_hash", "")))
	lines.append("prose_hash=%s" % str(contract.get("filing_prose_hash", "")))
	lines.append("first=%s:%s:%s" % [
		str(first_document.get("cache_status", "")),
		str(first_document.get("display_source", "")),
		str(first_document.get("visible_filing_hash", ""))
	])
	lines.append("second=%s:%s:%s" % [
		str(second_document.get("cache_status", "")),
		str(second_document.get("display_source", "")),
		str(second_document.get("visible_filing_hash", ""))
	])
	lines.append("document_hash=%s" % ANNUAL_FILING_DOCUMENT.document_hash(first_document))
	lines.append("visible_hash=%s" % str(first_document.get("visible_filing_hash", "")))
	var balance: Dictionary = first_document.get("visible_filing_profile_balance", {}) if typeof(first_document.get("visible_filing_profile_balance", {})) == TYPE_DICTIONARY else {}
	lines.append("counts=%d:%d:%d:%d:%d:%d:%d" % [
		int(first_document.get("visible_filing_section_count", 0)),
		int(first_document.get("visible_filing_paragraph_count", 0)),
		int(first_document.get("visible_filing_table_count", 0)),
		int(first_document.get("visible_filing_table_row_count", 0)),
		int(first_document.get("visible_filing_cross_reference_count", 0)),
		int(first_document.get("visible_filing_display_block_count", 0)),
		_variant_array(first_document.get("annual_report_section_map", [])).size()
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
	lines.append("toc_pages=%s" % _toc_page_payload(_variant_array(contract.get("filing_table_of_contents", []))))
	lines.append("sources=%s" % _dict_payload(first_document.get("visible_generation_sources", {})))
	lines.append("document_chars=%d" % document_chars)
	return "\n".join(lines)


func _toc_page_payload(toc: Array) -> String:
	var rows: Array[String] = []
	for row_value in toc:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		rows.append("%s=%s" % [str(row.get("section_id", "")), str(row.get("page_label", ""))])
	return "|".join(rows)


func _section_ids(rows: Array) -> Array:
	var result: Array = []
	for row_value in rows:
		if typeof(row_value) == TYPE_DICTIONARY:
			result.append(str(row_value.get("section_id", "")))
	return result


func _run_state_contains_derived_filing() -> bool:
	var save_text: String = JSON.stringify(RunState.to_save_dict())
	return save_text.contains("annual_filing_document") or save_text.contains("annual_filing_reader_r1") or save_text.contains("visible_filing")


func _dict_payload(source_value: Variant) -> String:
	if typeof(source_value) != TYPE_DICTIONARY:
		return ""
	var source: Dictionary = source_value
	var keys: Array = source.keys()
	keys.sort()
	var rows: Array[String] = []
	for key_value in keys:
		var key: String = str(key_value)
		var value = source.get(key_value)
		if typeof(value) == TYPE_ARRAY:
			rows.append("%s=[%s]" % [key, "|".join(_string_array(value))])
		else:
			rows.append("%s=%s" % [key, str(value)])
	return ";".join(rows)


func _string_array(source_value: Variant) -> Array:
	var result: Array = []
	for item_value in _variant_array(source_value):
		var text: String = str(item_value).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	return result


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


func _case_ok() -> Dictionary:
	return {"success": true}


func _case_fail(message: String) -> Dictionary:
	return {
		"success": false,
		"message": message
	}


func _fail(message: String) -> void:
	push_error(message)
	print("ANNUAL_FILING_REGRESSION_GUARD_FAIL: %s" % message)
	get_tree().quit(1)
