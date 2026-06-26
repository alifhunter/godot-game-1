extends Node

const ANNUAL_FILING_DOCUMENT = preload("res://systems/AnnualFilingDocument.gd")

const RUN_SEED := 20260621
const EXPECTED_HASH := "111806429"


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_report()
	if not bool(first_report.get("success", false)):
		_fail(str(first_report.get("message", "annual filing lazy contract failed")))
		return
	var second_report: Dictionary = _build_report()
	if not bool(second_report.get("success", false)):
		_fail(str(second_report.get("message", "repeated annual filing lazy contract failed")))
		return
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Annual filing lazy contract payload changed across repeated fixed-seed runs.")
		return

	var hash: String = _stable_hash(str(first_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual filing lazy contract hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_FILING_LAZY_CONTRACT_OK %s" % JSON.stringify({
		"hash": hash,
		"company_id": str(first_report.get("company_id", "")),
		"fiscal_year": int(first_report.get("fiscal_year", 0)),
		"cache_key": str(first_report.get("cache_key", "")),
		"source_state_hash": str(first_report.get("source_state_hash", "")),
		"filing_schema_hash": str(first_report.get("filing_schema_hash", "")),
		"accounting_footprint_hash": str(first_report.get("accounting_footprint_hash", "")),
		"filing_prose_hash": str(first_report.get("filing_prose_hash", ""))
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
		return _case_fail("RunState should not contain a derived annual filing document before click/request.")

	var options: Dictionary = {
		"ticker": str(definition.get("ticker", "")),
		"company_name": str(definition.get("name", "")),
		"sector_style_id": str(definition.get("sector_id", "generic_annual_filing")),
		"sector_id": str(definition.get("sector_id", definition.get("sector", ""))),
		"subsector_id": str(definition.get("subsector_id", definition.get("subsector", ""))),
		"business_summary": str(definition.get("business_summary", "")),
		"moat_tags": _variant_array(definition.get("moat_tags", [])),
		"story_hooks": _variant_array(definition.get("story_hooks", [])),
		"max_story_note_fact_packets": 50
	}
	var contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(annual, int(RunState.run_seed), company_id, options)
	var validation: Dictionary = _validate_contract(contract, annual, company_id)
	if not bool(validation.get("success", false)):
		return validation

	var cache: Dictionary = {}
	var first_document: Dictionary = ANNUAL_FILING_DOCUMENT.get_or_build_document(cache, annual, int(RunState.run_seed), company_id, options)
	if first_document.is_empty():
		return _case_fail("Expected first annual filing document request to build a document.")
	if bool(first_document.get("cache_hit", true)):
		return _case_fail("First annual filing document request should be a cache miss.")
	if str(first_document.get("cache_status", "")) != "miss_built":
		return _case_fail("First annual filing document request should report miss_built.")
	if cache.size() != 1:
		return _case_fail("Expected one cached annual filing document after first request.")
	var second_document: Dictionary = ANNUAL_FILING_DOCUMENT.get_or_build_document(cache, annual, int(RunState.run_seed), company_id, options)
	if not bool(second_document.get("cache_hit", false)):
		return _case_fail("Second annual filing document request should be a cache hit.")
	if str(second_document.get("cache_key", "")) != str(first_document.get("cache_key", "")):
		return _case_fail("Annual filing cache key changed between first and second request.")
	if ANNUAL_FILING_DOCUMENT.document_hash(first_document) != ANNUAL_FILING_DOCUMENT.document_hash(second_document):
		return _case_fail("Annual filing document contract hash changed between cache miss and hit.")
	var source_statement: Dictionary = second_document.get("source_annual_statement", {}) if typeof(second_document.get("source_annual_statement", {})) == TYPE_DICTIONARY else {}
	if source_statement.is_empty():
		return _case_fail("Cached annual filing document should preserve the source annual statement for the current reader.")
	if str(source_statement.get("statement_id", "")) != str(annual.get("statement_id", "")):
		return _case_fail("Cached annual filing source statement id changed.")

	var changed_annual: Dictionary = annual.duplicate(true)
	changed_annual["fiscal_year"] = int(annual.get("fiscal_year", 0)) + 1
	var changed_contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(changed_annual, int(RunState.run_seed), company_id, options)
	if str(changed_contract.get("cache_key", "")) == str(contract.get("cache_key", "")):
		return _case_fail("Annual filing cache key should change when fiscal year changes.")

	var changed_source: Dictionary = annual.duplicate(true)
	var changed_traceability: Dictionary = changed_source.get("traceability", {}) if typeof(changed_source.get("traceability", {})) == TYPE_DICTIONARY else {}
	changed_traceability = changed_traceability.duplicate(true)
	changed_traceability["disclosure_packet_render_visible_paragraph_count"] = int(changed_traceability.get("disclosure_packet_render_visible_paragraph_count", 0)) + 1
	changed_source["traceability"] = changed_traceability
	var changed_source_contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(changed_source, int(RunState.run_seed), company_id, options)
	if str(changed_source_contract.get("cache_key", "")) == str(contract.get("cache_key", "")):
		return _case_fail("Annual filing cache key should change when source state hash changes.")
	var changed_story_options: Dictionary = options.duplicate(true)
	changed_story_options["story_note_source_context"] = {
		"company_events": [
			{
				"event_id": "fixture_story_note_runtime_project",
				"target_company_id": company_id,
				"counterparty_company_id": "fixture_runtime_counterparty",
				"counterparty_company_name": "Fixture Runtime Counterparty",
				"category": "project_construction",
				"event_date": "2019-10-21",
				"amount": 9876543210.0,
				"currency": "IDR",
				"source_ids": ["fixture_story_note_runtime_project"]
			}
		]
	}
	var changed_story_contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(annual, int(RunState.run_seed), company_id, changed_story_options)
	if str(changed_story_contract.get("story_note_fact_packet_hash", "")) == str(contract.get("story_note_fact_packet_hash", "")):
		return _case_fail("Annual filing story-note fact hash should change when source story-note fact inputs change.")
	if str(changed_story_contract.get("cache_key", "")) == str(contract.get("cache_key", "")):
		return _case_fail("Annual filing cache key should change when story-note fact packets change.")
	if _run_state_contains_filing_document():
		return _case_fail("RunState should not save/cache derived annual filing documents after request.")

	return {
		"success": true,
		"payload": _payload(contract, first_document, second_document),
		"company_id": company_id,
		"fiscal_year": int(contract.get("fiscal_year", 0)),
		"cache_key": str(contract.get("cache_key", "")),
		"source_state_hash": str(contract.get("source_state_hash", "")),
		"filing_schema_hash": str(contract.get("filing_schema_hash", "")),
		"accounting_footprint_hash": str(contract.get("accounting_footprint_hash", "")),
		"filing_prose_hash": str(contract.get("filing_prose_hash", ""))
	}


func _validate_contract(contract: Dictionary, annual: Dictionary, company_id: String) -> Dictionary:
	if contract.is_empty():
		return _case_fail("Expected annual filing request contract.")
	if int(contract.get("schema_version", 0)) != 1:
		return _case_fail("Expected annual filing schema version 1.")
	if str(contract.get("document_type", "")) != "annual_filing":
		return _case_fail("Expected annual filing document type.")
	if str(contract.get("document_status", "")) != "r1_lazy_contract_ready":
		return _case_fail("Expected R1 lazy contract-ready status.")
	if str(contract.get("generation_timing", "")) != "lazy_on_request":
		return _case_fail("Expected lazy-on-request generation timing.")
	if str(contract.get("cache_owner", "")) != "in_memory_runtime":
		return _case_fail("Expected in-memory runtime cache owner.")
	if bool(contract.get("saved_cache_allowed", true)):
		return _case_fail("Saved annual filing cache should not be allowed in Task 1.")
	if str(contract.get("company_id", "")) != company_id:
		return _case_fail("Annual filing contract company id mismatch.")
	if int(contract.get("fiscal_year", 0)) != int(annual.get("fiscal_year", 0)):
		return _case_fail("Annual filing contract fiscal year mismatch.")
	if str(contract.get("source_statement_id", "")) != str(annual.get("statement_id", "")):
		return _case_fail("Annual filing contract source statement id mismatch.")
	if str(contract.get("cache_key", "")).strip_edges().is_empty():
		return _case_fail("Expected annual filing cache key.")
	if str(contract.get("source_state_hash", "")).strip_edges().is_empty():
		return _case_fail("Expected annual filing source state hash.")
	if str(contract.get("filing_schema_hash", "")).strip_edges().is_empty():
		return _case_fail("Expected annual filing schema hash.")
	if str(contract.get("accounting_footprint_hash", "")).strip_edges().is_empty():
		return _case_fail("Expected annual filing accounting footprint hash.")
	if str(contract.get("filing_prose_hash", "")).strip_edges().is_empty():
		return _case_fail("Expected annual filing prose hash.")
	if int(contract.get("filing_profile_schema_version", 0)) != 1:
		return _case_fail("Expected annual filing profile schema version 1.")
	if str(contract.get("filing_profile_status", "")) != "task2_profile_contract_ready":
		return _case_fail("Expected Task 2 filing profile status.")
	if str(contract.get("filing_profile_id", "")).strip_edges().is_empty():
		return _case_fail("Expected annual filing profile id.")
	if str(contract.get("filing_profile_version", "")).strip_edges().is_empty():
		return _case_fail("Expected annual filing profile version.")
	if int(contract.get("filing_anatomy_schema_version", 0)) != 1:
		return _case_fail("Expected annual filing anatomy schema version 1.")
	if str(contract.get("filing_anatomy_status", "")) != "r2_anatomy_schema_ready":
		return _case_fail("Expected R2 filing anatomy status.")
	if int(contract.get("accounting_footprint_schema_version", 0)) != 1:
		return _case_fail("Expected annual filing accounting footprint schema version 1.")
	if str(contract.get("accounting_footprint_status", "")) != "task3_accounting_footprints_ready":
		return _case_fail("Expected Task 3 accounting footprint status.")
	if int(contract.get("filing_prose_schema_version", 0)) != 1:
		return _case_fail("Expected annual filing prose schema version 1.")
	if str(contract.get("filing_prose_status", "")) != "task4_prose_library_ready":
		return _case_fail("Expected Task 4 filing prose status.")
	var key_parts: Dictionary = contract.get("cache_key_parts", {}) if typeof(contract.get("cache_key_parts", {})) == TYPE_DICTIONARY else {}
	for required_key in ["run_seed", "company_id", "fiscal_year", "filing_version", "language_id", "sector_style_id", "filing_profile_id", "filing_profile_version", "source_state_hash", "filing_schema_hash", "accounting_footprint_hash", "filing_prose_hash", "story_note_fact_packet_hash", "story_note_placement_plan_hash", "story_note_prose_hash"]:
		if not key_parts.has(required_key):
			return _case_fail("Annual filing cache key parts missing %s." % required_key)
	var invalidation_fields: Array = _string_array(contract.get("invalidation_fields", []))
	for required_field in ["fiscal_year", "filing_version", "language_id", "sector_style_id", "filing_profile_id", "filing_profile_version", "source_state_hash", "filing_schema_hash", "accounting_footprint_hash", "filing_prose_hash", "story_note_fact_packet_hash", "story_note_placement_plan_hash", "story_note_prose_hash"]:
		if not invalidation_fields.has(required_field):
			return _case_fail("Annual filing invalidation fields missing %s." % required_field)
	return _case_ok()


func _payload(contract: Dictionary, first_document: Dictionary, second_document: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("contract_status=%s" % str(contract.get("document_status", "")))
	lines.append("generation=%s" % str(contract.get("generation_timing", "")))
	lines.append("cache_owner=%s" % str(contract.get("cache_owner", "")))
	lines.append("cache_key=%s" % str(contract.get("cache_key", "")))
	lines.append("source_hash=%s" % str(contract.get("source_state_hash", "")))
	lines.append("filing_schema_hash=%s" % str(contract.get("filing_schema_hash", "")))
	lines.append("accounting_footprint_hash=%s" % str(contract.get("accounting_footprint_hash", "")))
	lines.append("filing_prose_hash=%s" % str(contract.get("filing_prose_hash", "")))
	lines.append("filing_profile=%s:%s:%s" % [
		str(contract.get("filing_profile_schema_version", "")),
		str(contract.get("filing_profile_id", "")),
		str(contract.get("filing_profile_version", ""))
	])
	lines.append("filing_anatomy=%s:%s" % [
		str(contract.get("filing_anatomy_schema_version", "")),
		str(contract.get("filing_anatomy_status", ""))
	])
	lines.append("accounting_footprints=%s:%s:%d" % [
		str(contract.get("accounting_footprint_schema_version", "")),
		str(contract.get("accounting_footprint_status", "")),
		_variant_array(contract.get("accounting_footprint_packets", [])).size()
	])
	lines.append("filing_prose=%s:%s:%d" % [
		str(contract.get("filing_prose_schema_version", "")),
		str(contract.get("filing_prose_status", "")),
		_variant_array(contract.get("filing_prose_packets", [])).size()
	])
	lines.append("key_parts=%s" % _dict_payload(contract.get("cache_key_parts", {})))
	lines.append("invalidates=%s" % "|".join(_string_array(contract.get("invalidation_fields", []))))
	lines.append("first=%s:%s:%s" % [
		str(first_document.get("cache_status", "")),
		str(first_document.get("visible_document_generated", "")),
		str(first_document.get("full_filing_generation_status", ""))
	])
	lines.append("second=%s:%s:%s" % [
		str(second_document.get("cache_status", "")),
		str(second_document.get("visible_document_generated", "")),
		str(second_document.get("full_filing_generation_status", ""))
	])
	lines.append("doc_hash=%s" % ANNUAL_FILING_DOCUMENT.document_hash(first_document))
	return "\n".join(lines)


func _run_state_contains_filing_document() -> bool:
	var save_text: String = JSON.stringify(RunState.to_save_dict())
	return save_text.contains("annual_filing_document") or save_text.contains("annual_filing_reader_r1")


func _dict_payload(source_value: Variant) -> String:
	if typeof(source_value) != TYPE_DICTIONARY:
		return ""
	var source: Dictionary = source_value
	var keys: Array = source.keys()
	keys.sort()
	var lines: Array[String] = []
	for key_value in keys:
		lines.append("%s=%s" % [str(key_value), str(source.get(key_value))])
	return ";".join(lines)


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
	return {"success": false, "message": message}


func _fail(message: String) -> void:
	push_error(message)
	print("ANNUAL_FILING_LAZY_CONTRACT_FAIL: %s" % message)
	get_tree().quit(1)
