extends Node

const ANNUAL_FILING_DOCUMENT = preload("res://systems/AnnualFilingDocument.gd")

const EXPECTED_HASH := "552737853"


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var report: Dictionary = _build_report()
	if not bool(report.get("success", false)):
		_fail(str(report.get("message", "annual filing profile contract failed")))
		return
	var repeat_report: Dictionary = _build_report()
	if not bool(repeat_report.get("success", false)):
		_fail(str(repeat_report.get("message", "repeated annual filing profile contract failed")))
		return
	if str(report.get("payload", "")) != str(repeat_report.get("payload", "")):
		_fail("Annual filing profile contract payload changed across repeated runs.")
		return

	var hash: String = _stable_hash(str(report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual filing profile contract hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_FILING_PROFILE_CONTRACT_OK %s" % JSON.stringify({
		"hash": hash,
		"bank_profile": str(report.get("bank_profile", "")),
		"industrial_profile": str(report.get("industrial_profile", "")),
		"default_profile": str(report.get("default_profile", "")),
		"profile_version": str(report.get("profile_version", ""))
	}))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	var bank_company: Dictionary = DataRepository.get_company_universe_company("bank_orang_indonesia")
	var industrial_company: Dictionary = DataRepository.get_company_universe_company("alat_berat_mandiri")
	var non_bank_finance_company: Dictionary = DataRepository.get_company_universe_company("multi_finance_sejahtera")
	if bank_company.is_empty() or industrial_company.is_empty() or non_bank_finance_company.is_empty():
		return _case_fail("Expected catalog companies for filing profile contract.")

	var bank_options: Dictionary = _options_from_company(bank_company)
	var industrial_options: Dictionary = _options_from_company(industrial_company)
	var non_bank_finance_options: Dictionary = _options_from_company(non_bank_finance_company)
	var unknown_options: Dictionary = {
		"company_id": "unknown_profile_company",
		"ticker": "UNKN",
		"company_name": "Unknown Profile Company",
		"sector_id": "mystery",
		"subsector_id": "unclassified",
		"business_summary": "Holding company with no profile-specific filing indicators."
	}

	var bank_profile: Dictionary = ANNUAL_FILING_DOCUMENT.select_filing_profile({}, bank_options)
	var industrial_profile: Dictionary = ANNUAL_FILING_DOCUMENT.select_filing_profile({}, industrial_options)
	var non_bank_finance_profile: Dictionary = ANNUAL_FILING_DOCUMENT.select_filing_profile({}, non_bank_finance_options)
	var unknown_profile: Dictionary = ANNUAL_FILING_DOCUMENT.select_filing_profile({}, unknown_options)
	if str(bank_profile.get("profile_id", "")) != "bank":
		return _case_fail("Expected bank_orang_indonesia to resolve bank filing profile.")
	if str(industrial_profile.get("profile_id", "")) != "industrial_trading":
		return _case_fail("Expected alat_berat_mandiri to resolve industrial_trading filing profile.")
	if str(non_bank_finance_profile.get("profile_id", "")) != "default_general":
		return _case_fail("Expected non-bank finance company to remain default_general until a finance profile exists.")
	if str(unknown_profile.get("profile_id", "")) != "default_general":
		return _case_fail("Expected unknown/malformed company to resolve default_general filing profile.")

	var annual: Dictionary = _minimal_annual_statement("bank_orang_indonesia")
	var bank_contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(annual, 20260624, "bank_orang_indonesia", bank_options)
	var repeated_bank_contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(annual, 20260624, "bank_orang_indonesia", bank_options)
	if str(bank_contract.get("cache_key", "")) != str(repeated_bank_contract.get("cache_key", "")):
		return _case_fail("Expected repeated bank profile cache key to stay deterministic.")
	var contract_validation: Dictionary = _validate_profile_contract(bank_contract, "bank")
	if not bool(contract_validation.get("success", false)):
		return contract_validation

	var override_options: Dictionary = bank_options.duplicate(true)
	override_options["filing_profile_id"] = "industrial_trading"
	var override_contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(annual, 20260624, "bank_orang_indonesia", override_options)
	if str(override_contract.get("filing_profile_id", "")) != "industrial_trading":
		return _case_fail("Expected explicit filing profile override to use industrial_trading.")
	if str(override_contract.get("cache_key", "")) == str(bank_contract.get("cache_key", "")):
		return _case_fail("Expected filing profile id to change annual filing cache key.")
	var bank_document: Dictionary = ANNUAL_FILING_DOCUMENT.build_document_from_statement(annual, 20260624, "bank_orang_indonesia", bank_options)
	var override_document: Dictionary = ANNUAL_FILING_DOCUMENT.build_document_from_statement(annual, 20260624, "bank_orang_indonesia", override_options)
	if ANNUAL_FILING_DOCUMENT.document_hash(bank_document) == ANNUAL_FILING_DOCUMENT.document_hash(override_document):
		return _case_fail("Expected filing profile id to change annual filing document hash.")

	return {
		"success": true,
		"payload": _payload(bank_profile, industrial_profile, non_bank_finance_profile, unknown_profile, bank_contract, override_contract, bank_document, override_document),
		"bank_profile": str(bank_profile.get("profile_id", "")),
		"industrial_profile": str(industrial_profile.get("profile_id", "")),
		"default_profile": str(unknown_profile.get("profile_id", "")),
		"profile_version": str(bank_profile.get("profile_version", ""))
	}


func _validate_profile_contract(contract: Dictionary, expected_profile_id: String) -> Dictionary:
	if contract.is_empty():
		return _case_fail("Expected annual filing profile contract.")
	if int(contract.get("filing_profile_schema_version", 0)) != 1:
		return _case_fail("Expected filing profile schema version 1.")
	if str(contract.get("filing_profile_status", "")) != "task2_profile_contract_ready":
		return _case_fail("Expected Task 2 filing profile status.")
	if str(contract.get("filing_profile_id", "")) != expected_profile_id:
		return _case_fail("Expected filing profile id %s." % expected_profile_id)
	if str(contract.get("filing_profile_version", "")) != "annual_filing_profile_r1":
		return _case_fail("Expected filing profile version annual_filing_profile_r1.")
	var profile_selection: Dictionary = contract.get("filing_profile_selection", {}) if typeof(contract.get("filing_profile_selection", {})) == TYPE_DICTIONARY else {}
	if str(profile_selection.get("profile_id", "")) != expected_profile_id:
		return _case_fail("Expected filing profile selection row to preserve profile id.")
	var selection_context: Dictionary = profile_selection.get("selection_context", {}) if typeof(profile_selection.get("selection_context", {})) == TYPE_DICTIONARY else {}
	if str(selection_context.get("sector_id", "")).is_empty() or str(selection_context.get("subsector_id", "")).is_empty():
		return _case_fail("Expected filing profile selection context to preserve sector and subsector.")
	var key_parts: Dictionary = contract.get("cache_key_parts", {}) if typeof(contract.get("cache_key_parts", {})) == TYPE_DICTIONARY else {}
	if str(key_parts.get("filing_profile_id", "")) != expected_profile_id:
		return _case_fail("Expected cache key parts to include filing profile id.")
	if str(key_parts.get("filing_profile_version", "")) != "annual_filing_profile_r1":
		return _case_fail("Expected cache key parts to include filing profile version.")
	var invalidation_fields: Array = _string_array(contract.get("invalidation_fields", []))
	for required_field in ["filing_profile_id", "filing_profile_version"]:
		if not invalidation_fields.has(required_field):
			return _case_fail("Expected invalidation fields to include %s." % required_field)
	return _case_ok()


func _options_from_company(company: Dictionary) -> Dictionary:
	return {
		"company_id": str(company.get("id", "")),
		"ticker": str(company.get("ticker", "")),
		"company_name": str(company.get("name", "")),
		"sector_style_id": str(company.get("sector", "")),
		"sector_id": str(company.get("sector", "")),
		"subsector_id": str(company.get("subsector", "")),
		"business_summary": str(company.get("business_summary", "")),
		"moat_tags": _variant_array(company.get("moat_tags", [])),
		"story_hooks": _variant_array(company.get("story_hooks", []))
	}


func _minimal_annual_statement(company_id: String) -> Dictionary:
	return {
		"statement_id": "annual_statement|profile_contract|%s|2019" % company_id,
		"company_id": company_id,
		"fiscal_year": 2019,
		"comparative_year": 2018,
		"statement_scope": "annual",
		"consolidated": true,
		"statement_period_label": "FY2019",
		"page_size_hint": "A4",
		"audit_status": "audited",
		"annual_report_section_map": [],
		"table_of_contents": [],
		"financial_position": [],
		"profit_or_loss_and_oci": [],
		"changes_in_equity": [],
		"cash_flows": [],
		"notes": [],
		"note_index": [],
		"traceability": {}
	}


func _payload(
	bank_profile: Dictionary,
	industrial_profile: Dictionary,
	non_bank_finance_profile: Dictionary,
	unknown_profile: Dictionary,
	bank_contract: Dictionary,
	override_contract: Dictionary,
	bank_document: Dictionary,
	override_document: Dictionary
) -> String:
	var lines: Array[String] = []
	lines.append("bank=%s:%s:%s" % [
		str(bank_profile.get("profile_id", "")),
		str(bank_profile.get("profile_version", "")),
		str(bank_profile.get("selection_reason", ""))
	])
	lines.append("industrial=%s:%s:%s" % [
		str(industrial_profile.get("profile_id", "")),
		str(industrial_profile.get("profile_version", "")),
		str(industrial_profile.get("selection_reason", ""))
	])
	lines.append("non_bank_finance=%s:%s:%s" % [
		str(non_bank_finance_profile.get("profile_id", "")),
		str(non_bank_finance_profile.get("profile_version", "")),
		str(non_bank_finance_profile.get("selection_reason", ""))
	])
	lines.append("unknown=%s:%s:%s" % [
		str(unknown_profile.get("profile_id", "")),
		str(unknown_profile.get("profile_version", "")),
		str(unknown_profile.get("selection_reason", ""))
	])
	lines.append("bank_cache=%s" % str(bank_contract.get("cache_key", "")))
	lines.append("override_cache=%s" % str(override_contract.get("cache_key", "")))
	lines.append("bank_doc_hash=%s" % ANNUAL_FILING_DOCUMENT.document_hash(bank_document))
	lines.append("override_doc_hash=%s" % ANNUAL_FILING_DOCUMENT.document_hash(override_document))
	return "\n".join(lines)


func _variant_array(source_value: Variant) -> Array:
	if typeof(source_value) == TYPE_ARRAY:
		return source_value.duplicate(true)
	return []


func _string_array(source_value: Variant) -> Array:
	var result: Array = []
	if typeof(source_value) != TYPE_ARRAY:
		return result
	for item_value in source_value:
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
	print("ANNUAL_FILING_PROFILE_CONTRACT_FAIL: %s" % message)
	get_tree().quit(1)
