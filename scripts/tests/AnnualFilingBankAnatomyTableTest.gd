extends Node

const ANNUAL_FILING_DOCUMENT = preload("res://systems/AnnualFilingDocument.gd")

const RUN_SEED := 20260624
const EXPECTED_HASH := "1058182282"
const EXPECTED_BANK_SECTION_IDS := [
	"cover",
	"table_of_contents",
	"financial_position",
	"profit_or_loss_and_oci",
	"changes_in_equity",
	"cash_flows",
	"note_bank_company_information",
	"note_bank_accounting_policies",
	"note_bank_cash_reserves",
	"note_bank_placements",
	"note_bank_securities",
	"note_bank_loans_financing",
	"note_bank_allowance_impairment",
	"note_bank_deposits",
	"note_bank_temporary_syirkah_funds",
	"note_bank_interest_income",
	"note_bank_related_parties",
	"note_bank_capital_adequacy",
	"note_bank_credit_risk",
	"note_bank_liquidity_risk",
	"note_bank_regulatory_compliance"
]
const REQUIRED_BANK_TABLE_SECTIONS := [
	"note_bank_cash_reserves",
	"note_bank_placements",
	"note_bank_securities",
	"note_bank_loans_financing",
	"note_bank_allowance_impairment",
	"note_bank_deposits",
	"note_bank_interest_income",
	"note_bank_capital_adequacy",
	"note_bank_credit_risk",
	"note_bank_liquidity_risk",
	"note_bank_regulatory_compliance"
]
const FORBIDDEN_INDUSTRIAL_SECTION_IDS := [
	"note_inventories",
	"note_ppe_investments",
	"note_revenue_expenses_tax_equity",
	"note_financial_assets_receivables",
	"note_liabilities_borrowings",
	"note_segment_information"
]
const REQUIRED_VISIBLE_TERMS := [
	"loans",
	"deposits",
	"allowance",
	"impairment",
	"credit risk",
	"capital adequacy",
	"liquidity risk",
	"stage 1",
	"stage 2",
	"stage 3"
]
const FORBIDDEN_BANK_TABLE_TERMS := [
	"inventor",
	"gross profit",
	"property, plant",
	"ppe",
	"cost of revenue"
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
		_fail(str(first_report.get("message", "annual filing bank anatomy/table test failed")))
		return
	var second_report: Dictionary = _build_report()
	if not bool(second_report.get("success", false)):
		_fail(str(second_report.get("message", "repeated annual filing bank anatomy/table test failed")))
		return
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Annual filing bank anatomy/table payload changed across repeated fixed-seed runs.")
		return

	var hash: String = _stable_hash(str(first_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual filing bank anatomy/table hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_FILING_BANK_ANATOMY_TABLE_OK %s" % JSON.stringify({
		"hash": hash,
		"company_id": str(first_report.get("company_id", "")),
		"profile": str(first_report.get("profile", "")),
		"section_count": int(first_report.get("section_count", 0)),
		"table_count": int(first_report.get("table_count", 0)),
		"table_row_count": int(first_report.get("table_row_count", 0)),
		"visible_filing_hash": str(first_report.get("visible_filing_hash", ""))
	}))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config = difficulty_config.duplicate(true)
	difficulty_config["use_company_universe_catalog"] = true
	difficulty_config["company_count"] = max(70, int(difficulty_config.get("company_count", 30)))
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	if company_definitions.is_empty():
		return _case_fail("Expected catalog company definitions.")
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	var bank_company_id: String = _first_bank_profile_company_id()
	if bank_company_id.is_empty():
		return _case_fail("Expected catalog roster to include a bank annual filing profile.")
	if not RunState.ensure_company_full_detail(bank_company_id):
		return _case_fail("Could not hydrate full bank detail for %s." % bank_company_id)
	var definition: Dictionary = RunState.get_effective_company_definition(bank_company_id, true, true)
	if definition.is_empty():
		return _case_fail("Expected effective bank definition.")
	var snapshot: Dictionary = definition.get("financial_statement_snapshot", {}) if typeof(definition.get("financial_statement_snapshot", {})) == TYPE_DICTIONARY else {}
	var annual: Dictionary = snapshot.get("annual_statement", {}) if typeof(snapshot.get("annual_statement", {})) == TYPE_DICTIONARY else {}
	if annual.is_empty():
		return _case_fail("Expected annual statement for %s." % bank_company_id)
	var options: Dictionary = _options_from_definition(definition, bank_company_id)
	var contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(annual, int(RunState.run_seed), bank_company_id, options)
	var document: Dictionary = ANNUAL_FILING_DOCUMENT.build_document_from_statement(annual, int(RunState.run_seed), bank_company_id, options)
	var validation: Dictionary = _validate_bank_document(contract, document)
	if not bool(validation.get("success", false)):
		return validation
	return {
		"success": true,
		"payload": _payload(contract, document),
		"company_id": bank_company_id,
		"profile": str(contract.get("filing_profile_id", "")),
		"section_count": int(document.get("visible_filing_section_count", 0)),
		"table_count": int(document.get("visible_filing_table_count", 0)),
		"table_row_count": _table_row_count(_variant_array(document.get("visible_filing_sections", []))),
		"visible_filing_hash": str(document.get("visible_filing_hash", ""))
	}


func _first_bank_profile_company_id() -> String:
	for id_value in RunState.company_order:
		var company_id: String = str(id_value)
		if not RunState.ensure_company_full_detail(company_id):
			return ""
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, true, true)
		var snapshot: Dictionary = definition.get("financial_statement_snapshot", {}) if typeof(definition.get("financial_statement_snapshot", {})) == TYPE_DICTIONARY else {}
		var annual: Dictionary = snapshot.get("annual_statement", {}) if typeof(snapshot.get("annual_statement", {})) == TYPE_DICTIONARY else {}
		if annual.is_empty():
			continue
		var options: Dictionary = _options_from_definition(definition, company_id)
		var contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(annual, int(RunState.run_seed), company_id, options)
		if str(contract.get("filing_profile_id", "")) == "bank":
			return company_id
	return ""


func _validate_bank_document(contract: Dictionary, document: Dictionary) -> Dictionary:
	if contract.is_empty() or document.is_empty():
		return _case_fail("Expected annual filing contract and visible document.")
	if str(contract.get("filing_profile_id", "")) != "bank":
		return _case_fail("Expected bank filing profile.")
	if str(document.get("filing_profile_id", "")) != "bank":
		return _case_fail("Expected visible document to preserve bank filing profile.")
	var section_order: Array = _string_array(document.get("visible_filing_section_order", []))
	if section_order != EXPECTED_BANK_SECTION_IDS:
		return _case_fail("Bank filing section order changed: %s" % "|".join(section_order))
	for forbidden_section_id in FORBIDDEN_INDUSTRIAL_SECTION_IDS:
		if section_order.has(str(forbidden_section_id)):
			return _case_fail("Bank filing should not render industrial note section %s." % str(forbidden_section_id))
	if int(document.get("visible_filing_section_count", 0)) != EXPECTED_BANK_SECTION_IDS.size():
		return _case_fail("Expected %d bank filing sections." % EXPECTED_BANK_SECTION_IDS.size())
	if int(document.get("visible_filing_table_count", 0)) < 8:
		return _case_fail("Expected at least 8 bank compact tables.")
	var table_row_count: int = _table_row_count(_variant_array(document.get("visible_filing_sections", [])))
	if table_row_count < 20:
		return _case_fail("Expected at least 20 bank compact table rows.")
	if int(document.get("visible_filing_table_row_count", 0)) != table_row_count:
		return _case_fail("Bank visible filing table row count metadata mismatch.")
	if int(document.get("visible_filing_display_block_count", 0)) <= 0:
		return _case_fail("Expected bank visible filing display blocks.")
	var balance: Dictionary = document.get("visible_filing_profile_balance", {}) if typeof(document.get("visible_filing_profile_balance", {})) == TYPE_DICTIONARY else {}
	if str(balance.get("filing_profile_id", "")) != "bank" or not bool(balance.get("target_met", false)):
		return _case_fail("Expected bank filing profile balance target to be met.")
	if float(balance.get("actual_table_to_note_prose_ratio", 0.0)) < float(balance.get("target_table_to_note_prose_ratio", 1.0)):
		return _case_fail("Expected bank filing table/prose ratio to meet target.")
	var sections_by_id: Dictionary = document.get("visible_filing_sections_by_id", {}) if typeof(document.get("visible_filing_sections_by_id", {})) == TYPE_DICTIONARY else {}
	for required_section in REQUIRED_BANK_TABLE_SECTIONS:
		if not sections_by_id.has(str(required_section)):
			return _case_fail("Bank filing missing required section %s." % str(required_section))
		var section: Dictionary = sections_by_id.get(str(required_section), {}) if typeof(sections_by_id.get(str(required_section), {})) == TYPE_DICTIONARY else {}
		if _variant_array(section.get("compact_tables", [])).is_empty():
			return _case_fail("Bank filing section %s should contain compact tables." % str(required_section))
		var block_validation: Dictionary = _validate_display_blocks(section)
		if not bool(block_validation.get("success", false)):
			return block_validation
		var source_validation: Dictionary = _validate_table_rows_source_backed(section)
		if not bool(source_validation.get("success", false)):
			return source_validation
	var visible_text: String = _visible_text(document).to_lower()
	for required_term in REQUIRED_VISIBLE_TERMS:
		if visible_text.find(str(required_term)) == -1:
			return _case_fail("Bank filing missing visible bank term '%s'." % str(required_term))
	for hidden_token in HIDDEN_VISIBLE_TOKENS:
		if visible_text.find(str(hidden_token).to_lower()) != -1:
			return _case_fail("Bank filing leaked hidden token %s." % str(hidden_token))
	for phrase in FORBIDDEN_GENERIC_PHRASES:
		if visible_text.find(str(phrase)) != -1:
			return _case_fail("Bank filing retained forbidden generic phrase: %s." % str(phrase))
	var table_text: String = _visible_table_text(document).to_lower()
	for forbidden_term in FORBIDDEN_BANK_TABLE_TERMS:
		if table_text.find(str(forbidden_term)) != -1:
			return _case_fail("Bank compact table leaked incompatible industrial term '%s'." % str(forbidden_term))
	var first_visible_hash: String = str(document.get("visible_filing_hash", ""))
	if first_visible_hash.is_empty() or first_visible_hash != ANNUAL_FILING_DOCUMENT.visible_filing_hash(document):
		return _case_fail("Bank visible filing hash helper mismatch.")
	return _case_ok()


func _validate_display_blocks(section: Dictionary) -> Dictionary:
	var content_count: int = _variant_array(section.get("paragraphs", [])).size() + _variant_array(section.get("compact_tables", [])).size() + _variant_array(section.get("cross_references", [])).size()
	var blocks: Array = _variant_array(section.get("display_blocks", []))
	if content_count > 0 and blocks.is_empty():
		return _case_fail("Bank section %s has content but no display blocks." % str(section.get("section_id", "")))
	if content_count != blocks.size():
		return _case_fail("Bank section %s display block count mismatch." % str(section.get("section_id", "")))
	var last_rank: int = -1
	for block_value in blocks:
		if typeof(block_value) != TYPE_DICTIONARY:
			return _case_fail("Expected bank display block dictionaries.")
		var block: Dictionary = block_value
		var rank: int = _display_block_rank(str(block.get("block_type", "")))
		if rank < last_rank:
			return _case_fail("Bank section %s display blocks are not table-first." % str(section.get("section_id", "")))
		last_rank = rank
	if not _variant_array(section.get("compact_tables", [])).is_empty():
		var first_block: Dictionary = blocks[0] if blocks.size() > 0 and typeof(blocks[0]) == TYPE_DICTIONARY else {}
		if str(first_block.get("block_type", "")) != "compact_table":
			return _case_fail("Bank section %s should render compact tables first." % str(section.get("section_id", "")))
	return _case_ok()


func _validate_table_rows_source_backed(section: Dictionary) -> Dictionary:
	for table_value in _variant_array(section.get("compact_tables", [])):
		if typeof(table_value) != TYPE_DICTIONARY:
			return _case_fail("Expected bank compact table dictionaries.")
		var table: Dictionary = table_value
		for row_value in _variant_array(table.get("rows", [])):
			if typeof(row_value) != TYPE_DICTIONARY:
				return _case_fail("Expected bank compact table row dictionaries.")
			var row: Dictionary = row_value
			if str(row.get("caption", "")).strip_edges().is_empty() or str(row.get("fy_value", "")).strip_edges().is_empty():
				return _case_fail("Expected bank table rows to carry neutral visible caption/value.")
			if not str(row.get("related_note", "")).strip_edges().is_empty():
				return _case_fail("Expected bank table rows not to expose related-note metadata.")
			if str(row.get("fy_value", "")).find("million_idr") != -1:
				return _case_fail("Expected bank table rows not to expose raw unit tokens.")
			if _string_array(row.get("source_footprint_ids", [])).is_empty() and _string_array(row.get("statement_line_ids", [])).is_empty():
				return _case_fail("Expected bank table rows to stay source-backed.")
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


func _options_from_definition(definition: Dictionary, fallback_company_id: String) -> Dictionary:
	return {
		"company_id": str(definition.get("id", fallback_company_id)),
		"ticker": str(definition.get("ticker", "")),
		"company_name": str(definition.get("name", "")),
		"sector_style_id": str(definition.get("sector_id", definition.get("sector", ""))),
		"sector_id": str(definition.get("sector_id", definition.get("sector", ""))),
		"subsector_id": str(definition.get("subsector_id", definition.get("subsector", ""))),
		"business_summary": str(definition.get("business_summary", "")),
		"moat_tags": _variant_array(definition.get("moat_tags", [])),
		"story_hooks": _variant_array(definition.get("story_hooks", []))
	}


func _payload(contract: Dictionary, document: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("profile=%s:%s" % [str(contract.get("filing_profile_id", "")), str(contract.get("filing_profile_version", ""))])
	lines.append("schema_hash=%s" % str(contract.get("filing_schema_hash", "")))
	lines.append("footprint_hash=%s" % str(contract.get("accounting_footprint_hash", "")))
	lines.append("prose_hash=%s" % str(contract.get("filing_prose_hash", "")))
	lines.append("visible_hash=%s" % str(document.get("visible_filing_hash", "")))
	lines.append("document_hash=%s" % ANNUAL_FILING_DOCUMENT.document_hash(document))
	var balance: Dictionary = document.get("visible_filing_profile_balance", {}) if typeof(document.get("visible_filing_profile_balance", {})) == TYPE_DICTIONARY else {}
	lines.append("counts=%d:%d:%d:%d:%d:%d" % [
		int(document.get("visible_filing_section_count", 0)),
		int(document.get("visible_filing_paragraph_count", 0)),
		int(document.get("visible_filing_table_count", 0)),
		int(document.get("visible_filing_table_row_count", 0)),
		int(document.get("visible_filing_display_block_count", 0)),
		_table_row_count(_variant_array(document.get("visible_filing_sections", [])))
	])
	lines.append("assembly=%s" % "|".join(_string_array(document.get("visible_filing_assembly_priority", []))))
	lines.append("balance=%s:%s:%s:%s:%s" % [
		str(balance.get("filing_profile_id", "")),
		str(balance.get("target_met", "")),
		String.num(float(balance.get("actual_table_to_note_prose_ratio", 0.0)), 3),
		String.num(float(balance.get("target_table_to_note_prose_ratio", 0.0)), 3),
		int(balance.get("display_block_count", 0))
	])
	lines.append("sections=%s" % "|".join(_string_array(document.get("visible_filing_section_order", []))))
	lines.append("tables=%s" % _table_payload(_variant_array(document.get("visible_filing_sections", []))))
	return "\n".join(lines)


func _table_payload(sections: Array) -> String:
	var rows: Array[String] = []
	for section_value in sections:
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		for table_value in _variant_array(section.get("compact_tables", [])):
			if typeof(table_value) != TYPE_DICTIONARY:
				continue
			var table: Dictionary = table_value
			rows.append("%s:%s:%s" % [
				str(section.get("section_id", "")),
				str(table.get("title", "")),
				_table_rows_payload(_variant_array(table.get("rows", [])))
			])
	return ";".join(rows)


func _table_rows_payload(rows: Array) -> String:
	var parts: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		parts.append("%s=%s" % [str(row.get("caption", "")), str(row.get("fy_value", ""))])
	return "|".join(parts)


func _visible_text(document: Dictionary) -> String:
	var parts: Array[String] = []
	for section_value in _variant_array(document.get("visible_filing_sections", [])):
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		parts.append(str(section.get("title", "")))
		parts.append(str(section.get("localized_title", "")))
		for paragraph_value in _variant_array(section.get("paragraphs", [])):
			if typeof(paragraph_value) == TYPE_DICTIONARY:
				parts.append(str(paragraph_value.get("text", "")))
		for reference_value in _variant_array(section.get("cross_references", [])):
			if typeof(reference_value) == TYPE_DICTIONARY:
				parts.append(str(reference_value.get("display_text", "")))
		for table_value in _variant_array(section.get("compact_tables", [])):
			if typeof(table_value) != TYPE_DICTIONARY:
				continue
			var table: Dictionary = table_value
			parts.append(str(table.get("title", "")))
			for row_value in _variant_array(table.get("rows", [])):
				if typeof(row_value) == TYPE_DICTIONARY:
					parts.append(str(row_value.get("caption", "")))
					parts.append(str(row_value.get("fy_value", "")))
					parts.append(str(row_value.get("related_note", "")))
	return "\n".join(parts)


func _visible_table_text(document: Dictionary) -> String:
	var parts: Array[String] = []
	for section_value in _variant_array(document.get("visible_filing_sections", [])):
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		for table_value in _variant_array(section.get("compact_tables", [])):
			if typeof(table_value) != TYPE_DICTIONARY:
				continue
			var table: Dictionary = table_value
			parts.append(str(table.get("title", "")))
			for row_value in _variant_array(table.get("rows", [])):
				if typeof(row_value) == TYPE_DICTIONARY:
					parts.append(str(row_value.get("caption", "")))
					parts.append(str(row_value.get("fy_value", "")))
					parts.append(str(row_value.get("related_note", "")))
	return "\n".join(parts)


func _table_row_count(sections: Array) -> int:
	var count: int = 0
	for section_value in sections:
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		for table_value in _variant_array(section_value.get("compact_tables", [])):
			if typeof(table_value) == TYPE_DICTIONARY:
				count += _variant_array(table_value.get("rows", [])).size()
	return count


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
	print("ANNUAL_FILING_BANK_ANATOMY_TABLE_FAIL: %s" % message)
	get_tree().quit(1)
