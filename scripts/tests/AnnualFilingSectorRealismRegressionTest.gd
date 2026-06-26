extends Node

const ANNUAL_FILING_DOCUMENT = preload("res://systems/AnnualFilingDocument.gd")

const RUN_SEED := 20260624
const EXPECTED_HASH := "634098613"

const REQUIRED_BANK_SECTION_IDS := [
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

const REQUIRED_INDUSTRIAL_SECTION_IDS := [
	"note_inventories",
	"note_revenue_expenses_tax_equity",
	"note_segment_information",
	"note_commitments_contingencies",
	"note_financial_risk_management"
]

const INDUSTRIAL_TABLE_SECTIONS := [
	"note_inventories",
	"note_revenue_expenses_tax_equity",
	"note_segment_information",
	"note_financial_risk_management"
]

const BANK_ONLY_PREFIX := "note_bank_"
const MIN_BANK_TABLE_COUNT := 8
const MIN_BANK_TABLE_ROWS := 20
const MIN_INDUSTRIAL_TABLE_COUNT := 0
const MAX_BANK_PARAGRAPHS := 70
const MAX_INDUSTRIAL_PARAGRAPHS := 70

const REQUIRED_BANK_VISIBLE_TERMS := [
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

const REQUIRED_INDUSTRIAL_VISIBLE_TERMS := [
	"segment",
	"inventor",
	"commitment",
	"risk management",
	"revenue"
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
	"trade answer"
]

const FORBIDDEN_GENERIC_PHRASES := [
	"catatan",
	"laporan",
	"million_idr",
	"related note classifications",
	"note classifications",
	"classifications connect",
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
		_fail(str(first_report.get("message", "annual filing sector realism regression failed")))
		return
	var second_report: Dictionary = _build_report()
	if not bool(second_report.get("success", false)):
		_fail(str(second_report.get("message", "repeated annual filing sector realism regression failed")))
		return
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Annual filing sector realism payload changed across repeated fixed-seed runs.")
		return

	var hash: String = _stable_hash(str(first_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual filing sector realism hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_FILING_SECTOR_REALISM_REGRESSION_OK %s" % JSON.stringify({
		"hash": hash,
		"bank_company_id": str(first_report.get("bank_company_id", "")),
		"bank_visible_hash": str(first_report.get("bank_visible_hash", "")),
		"bank_table_count": int(first_report.get("bank_table_count", 0)),
		"bank_table_row_count": int(first_report.get("bank_table_row_count", 0)),
		"industrial_company_id": str(first_report.get("industrial_company_id", "")),
		"industrial_visible_hash": str(first_report.get("industrial_visible_hash", "")),
		"industrial_table_count": int(first_report.get("industrial_table_count", 0)),
		"industrial_table_row_count": int(first_report.get("industrial_table_row_count", 0))
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
	var bank_report: Dictionary = _build_first_company_document_for_profile("bank")
	if not bool(bank_report.get("success", false)):
		return bank_report
	var industrial_report: Dictionary = _build_first_company_document_for_profile("industrial_trading")
	if not bool(industrial_report.get("success", false)):
		return industrial_report

	var bank_validation: Dictionary = _validate_bank_document(bank_report.get("contract", {}), bank_report.get("document", {}))
	if not bool(bank_validation.get("success", false)):
		return bank_validation
	var industrial_validation: Dictionary = _validate_industrial_document(industrial_report.get("contract", {}), industrial_report.get("document", {}))
	if not bool(industrial_validation.get("success", false)):
		return industrial_validation

	var bank_document: Dictionary = bank_report.get("document", {})
	var industrial_document: Dictionary = industrial_report.get("document", {})
	return {
		"success": true,
		"payload": _payload(bank_report, industrial_report),
		"bank_company_id": str(bank_report.get("company_id", "")),
		"bank_visible_hash": str(bank_document.get("visible_filing_hash", "")),
		"bank_table_count": int(bank_document.get("visible_filing_table_count", 0)),
		"bank_table_row_count": _table_row_count(_variant_array(bank_document.get("visible_filing_sections", []))),
		"industrial_company_id": str(industrial_report.get("company_id", "")),
		"industrial_visible_hash": str(industrial_document.get("visible_filing_hash", "")),
		"industrial_table_count": int(industrial_document.get("visible_filing_table_count", 0)),
		"industrial_table_row_count": _table_row_count(_variant_array(industrial_document.get("visible_filing_sections", [])))
	}


func _build_first_company_document_for_profile(profile_id: String) -> Dictionary:
	for id_value in RunState.company_order:
		var company_id: String = str(id_value)
		var report: Dictionary = _build_company_document(company_id)
		if not bool(report.get("success", false)):
			return report
		var contract: Dictionary = _dictionary(report.get("contract", {}))
		if str(contract.get("filing_profile_id", "")) == profile_id:
			return report
	return _case_fail("Expected catalog roster to include a %s annual filing profile." % profile_id)


func _build_company_document(company_id: String) -> Dictionary:
	if not RunState.company_order.has(company_id):
		return _case_fail("Expected catalog roster to include %s." % company_id)
	if not RunState.ensure_company_full_detail(company_id):
		return _case_fail("Could not hydrate full detail for %s." % company_id)
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, true, true)
	if definition.is_empty():
		return _case_fail("Expected effective company definition for %s." % company_id)
	var snapshot: Dictionary = definition.get("financial_statement_snapshot", {}) if typeof(definition.get("financial_statement_snapshot", {})) == TYPE_DICTIONARY else {}
	var annual: Dictionary = snapshot.get("annual_statement", {}) if typeof(snapshot.get("annual_statement", {})) == TYPE_DICTIONARY else {}
	if annual.is_empty():
		return _case_fail("Expected annual statement for %s." % company_id)
	var options: Dictionary = _options_from_definition(definition, company_id)
	var contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(annual, int(RunState.run_seed), company_id, options)
	var document: Dictionary = ANNUAL_FILING_DOCUMENT.build_document_from_statement(annual, int(RunState.run_seed), company_id, options)
	if contract.is_empty() or document.is_empty():
		return _case_fail("Expected contract and document for %s." % company_id)
	return {
		"success": true,
		"company_id": company_id,
		"definition": definition,
		"contract": contract,
		"document": document
	}


func _validate_bank_document(contract: Dictionary, document: Dictionary) -> Dictionary:
	if str(contract.get("filing_profile_id", "")) != "bank" or str(document.get("filing_profile_id", "")) != "bank":
		return _case_fail("Expected bank profile for generated bank representative.")
	var section_order: Array = _string_array(document.get("visible_filing_section_order", []))
	if section_order != REQUIRED_BANK_SECTION_IDS:
		return _case_fail("Bank filing section order changed: %s" % "|".join(section_order))
	var paragraphs: int = int(document.get("visible_filing_paragraph_count", 0))
	if paragraphs <= 0 or paragraphs > MAX_BANK_PARAGRAPHS:
		return _case_fail("Bank filing paragraph count outside guardrail: %d." % paragraphs)
	if int(document.get("visible_filing_table_count", 0)) < MIN_BANK_TABLE_COUNT:
		return _case_fail("Bank filing should remain table-heavy.")
	if _table_row_count(_variant_array(document.get("visible_filing_sections", []))) < MIN_BANK_TABLE_ROWS:
		return _case_fail("Bank filing should contain source-backed bank table rows.")
	var sections_by_id: Dictionary = _dictionary(document.get("visible_filing_sections_by_id", {}))
	for required_section_value in REQUIRED_BANK_TABLE_SECTIONS:
		var required_section: String = str(required_section_value)
		if not sections_by_id.has(required_section):
			return _case_fail("Bank filing missing required section %s." % required_section)
		var section: Dictionary = _dictionary(sections_by_id.get(required_section, {}))
		if _variant_array(section.get("compact_tables", [])).is_empty():
			return _case_fail("Bank section %s should contain compact tables." % required_section)
		var block_validation: Dictionary = _validate_display_blocks(section)
		if not bool(block_validation.get("success", false)):
			return block_validation
	var text_validation: Dictionary = _validate_common_visible_text(document, "Bank")
	if not bool(text_validation.get("success", false)):
		return text_validation
	var visible_text: String = _visible_text(document).to_lower()
	for term_value in REQUIRED_BANK_VISIBLE_TERMS:
		var term: String = str(term_value)
		if visible_text.find(term) == -1:
			return _case_fail("Bank filing missing required visible term '%s'." % term)
	return _case_ok()


func _validate_industrial_document(contract: Dictionary, document: Dictionary) -> Dictionary:
	if str(contract.get("filing_profile_id", "")) != "industrial_trading" or str(document.get("filing_profile_id", "")) != "industrial_trading":
		return _case_fail("Expected industrial/trading profile for generated industrial representative.")
	var section_order: Array = _string_array(document.get("visible_filing_section_order", []))
	for section_id_value in section_order:
		var section_id: String = str(section_id_value)
		if section_id.begins_with(BANK_ONLY_PREFIX):
			return _case_fail("Industrial filing should not include bank-only section %s." % section_id)
	for required_section_value in REQUIRED_INDUSTRIAL_SECTION_IDS:
		var required_section: String = str(required_section_value)
		if not section_order.has(required_section):
			return _case_fail("Industrial filing missing required section %s. order=%s" % [
				required_section,
				"|".join(section_order)
			])
	var paragraphs: int = int(document.get("visible_filing_paragraph_count", 0))
	if paragraphs <= 0 or paragraphs > MAX_INDUSTRIAL_PARAGRAPHS:
		return _case_fail("Industrial filing paragraph count outside guardrail: %d." % paragraphs)
	if int(document.get("visible_filing_table_count", 0)) < MIN_INDUSTRIAL_TABLE_COUNT:
		return _case_fail("Industrial filing should retain core compact tables.")
	var sections_by_id: Dictionary = _dictionary(document.get("visible_filing_sections_by_id", {}))
	for required_table_section_value in INDUSTRIAL_TABLE_SECTIONS:
		var required_table_section: String = str(required_table_section_value)
		var section: Dictionary = _dictionary(sections_by_id.get(required_table_section, {}))
		if section.is_empty():
			return _case_fail("Industrial filing missing table-capable section %s." % required_table_section)
		if _variant_array(section.get("compact_tables", [])).is_empty() and _variant_array(section.get("paragraphs", [])).is_empty():
			return _case_fail("Industrial section %s should expose visible note content." % required_table_section)
		var block_validation: Dictionary = _validate_display_blocks(section)
		if not bool(block_validation.get("success", false)):
			return block_validation
	var text_validation: Dictionary = _validate_common_visible_text(document, "Industrial")
	if not bool(text_validation.get("success", false)):
		return text_validation
	var visible_text: String = _visible_text(document).to_lower()
	for term_value in REQUIRED_INDUSTRIAL_VISIBLE_TERMS:
		var term: String = str(term_value)
		if visible_text.find(term) == -1:
			return _case_fail("Industrial filing missing required visible term '%s'." % term)
	return _case_ok()


func _validate_common_visible_text(document: Dictionary, label: String) -> Dictionary:
	var visible_text: String = _visible_text(document).to_lower()
	if int(document.get("visible_filing_cross_reference_count", 0)) != 0:
		return _case_fail("%s filing should not expose cross-reference/classification blocks." % label)
	for token_value in HIDDEN_VISIBLE_TOKENS:
		var token: String = str(token_value).to_lower()
		if visible_text.find(token) != -1:
			return _case_fail("%s filing leaked hidden token %s." % [label, token])
	for phrase_value in FORBIDDEN_GENERIC_PHRASES:
		var phrase: String = str(phrase_value).to_lower()
		if visible_text.find(phrase) != -1:
			return _case_fail("%s filing retained generic filler phrase: %s." % [label, phrase])
	var duplicate_count: int = _duplicate_paragraph_count(document)
	if duplicate_count > 0:
		return _case_fail("%s filing repeated paragraph text %d time(s)." % [label, duplicate_count])
	for section_value in _variant_array(document.get("visible_filing_sections", [])):
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		var title: String = str(section.get("title", ""))
		var localized_title: String = str(section.get("localized_title", "")).strip_edges()
		if not localized_title.is_empty():
			return _case_fail("%s filing should not expose localized section title: %s." % [label, localized_title])
		if str(section.get("document_part", "")) == "notes" and title.to_lower().begins_with("notes -"):
			return _case_fail("%s note section title should not keep Notes prefix: %s." % [label, title])
		for table_value in _variant_array(section.get("compact_tables", [])):
			if typeof(table_value) != TYPE_DICTIONARY:
				continue
			var table: Dictionary = table_value
			for row_value in _variant_array(table.get("rows", [])):
				if typeof(row_value) != TYPE_DICTIONARY:
					continue
				var row: Dictionary = row_value
				if not str(row.get("related_note", "")).strip_edges().is_empty():
					return _case_fail("%s filing table row should not expose related-note metadata." % label)
				if str(row.get("fy_value", "")).find("million_idr") != -1:
					return _case_fail("%s filing table row leaked raw unit token." % label)
	if str(document.get("visible_filing_hash", "")) != ANNUAL_FILING_DOCUMENT.visible_filing_hash(document):
		return _case_fail("%s visible filing hash helper mismatch." % label)
	return _case_ok()


func _validate_display_blocks(section: Dictionary) -> Dictionary:
	var content_count: int = (
		_variant_array(section.get("paragraphs", [])).size()
		+ _variant_array(section.get("compact_tables", [])).size()
		+ _variant_array(section.get("cross_references", [])).size()
	)
	var blocks: Array = _variant_array(section.get("display_blocks", []))
	if content_count > 0 and blocks.is_empty():
		return _case_fail("Section %s has content but no display blocks." % str(section.get("section_id", "")))
	if content_count != blocks.size():
		return _case_fail("Section %s display block count mismatch." % str(section.get("section_id", "")))
	var last_rank: int = -1
	for block_value in blocks:
		if typeof(block_value) != TYPE_DICTIONARY:
			return _case_fail("Expected display block dictionaries.")
		var block: Dictionary = block_value
		var rank: int = _display_block_rank(str(block.get("block_type", "")))
		if rank < last_rank:
			return _case_fail("Section %s display blocks are not table-first." % str(section.get("section_id", "")))
		last_rank = rank
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


func _payload(bank_report: Dictionary, industrial_report: Dictionary) -> String:
	var bank_document: Dictionary = _dictionary(bank_report.get("document", {}))
	var bank_contract: Dictionary = _dictionary(bank_report.get("contract", {}))
	var industrial_document: Dictionary = _dictionary(industrial_report.get("document", {}))
	var industrial_contract: Dictionary = _dictionary(industrial_report.get("contract", {}))
	var lines: Array[String] = []
	lines.append(_document_snapshot_payload("bank", bank_contract, bank_document))
	lines.append(_document_snapshot_payload("industrial", industrial_contract, industrial_document))
	return "\n".join(lines)


func _document_snapshot_payload(label: String, contract: Dictionary, document: Dictionary) -> String:
	var sections: Array = _variant_array(document.get("visible_filing_sections", []))
	return "%s profile=%s:%s schema=%s footprint=%s prose=%s visible=%s document=%s counts=%d:%d:%d:%d:%d duplicate=%d sections=%s tables=%s" % [
		label,
		str(contract.get("filing_profile_id", "")),
		str(contract.get("filing_profile_version", "")),
		str(contract.get("filing_schema_hash", "")),
		str(contract.get("accounting_footprint_hash", "")),
		str(contract.get("filing_prose_hash", "")),
		str(document.get("visible_filing_hash", "")),
		ANNUAL_FILING_DOCUMENT.document_hash(document),
		int(document.get("visible_filing_section_count", 0)),
		int(document.get("visible_filing_paragraph_count", 0)),
		int(document.get("visible_filing_table_count", 0)),
		int(document.get("visible_filing_table_row_count", 0)),
		int(document.get("visible_filing_display_block_count", 0)),
		_duplicate_paragraph_count(document),
		"|".join(_string_array(document.get("visible_filing_section_order", []))),
		_table_payload(sections)
	]


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
			rows.append("%s:%s:%d" % [
				str(section.get("section_id", "")),
				str(table.get("title", "")),
				_variant_array(table.get("rows", [])).size()
			])
	return ";".join(rows)


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


func _duplicate_paragraph_count(document: Dictionary) -> int:
	var seen: Dictionary = {}
	var duplicates: int = 0
	for section_value in _variant_array(document.get("visible_filing_sections", [])):
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		for paragraph_value in _variant_array(section.get("paragraphs", [])):
			if typeof(paragraph_value) != TYPE_DICTIONARY:
				continue
			var text: String = str(paragraph_value.get("text", "")).strip_edges().to_lower()
			if text.is_empty():
				continue
			if seen.has(text):
				duplicates += 1
			seen[text] = true
	return duplicates


func _table_row_count(sections: Array) -> int:
	var count: int = 0
	for section_value in sections:
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		for table_value in _variant_array(section.get("compact_tables", [])):
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


func _dictionary(source_value: Variant) -> Dictionary:
	if typeof(source_value) == TYPE_DICTIONARY:
		return source_value.duplicate(true)
	return {}


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
	print("ANNUAL_FILING_SECTOR_REALISM_REGRESSION_FAIL: %s" % message)
	get_tree().quit(1)
