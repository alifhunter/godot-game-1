extends Node

const ANNUAL_FILING_DOCUMENT = preload("res://systems/AnnualFilingDocument.gd")

const EXPECTED_HASH := "1287721463"


func _ready() -> void:
	var report: Dictionary = _build_report()
	if not bool(report.get("success", false)):
		_fail(str(report.get("message", "annual filing story-note contract failed")))
		return
	var repeat_report: Dictionary = _build_report()
	if not bool(repeat_report.get("success", false)):
		_fail(str(repeat_report.get("message", "repeated annual filing story-note contract failed")))
		return
	if str(report.get("payload", "")) != str(repeat_report.get("payload", "")):
		_fail("Annual filing story-note contract payload changed across repeated runs.")
		return

	var hash: String = _stable_hash(str(report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual filing story-note contract hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_FILING_STORY_NOTE_CONTRACT_OK %s" % JSON.stringify({
		"hash": hash,
		"schema_hash": str(report.get("schema_hash", "")),
		"story_type_count": int(report.get("story_type_count", 0)),
		"container_count": int(report.get("container_count", 0)),
		"fixture_count": int(report.get("fixture_count", 0))
	}))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	var summary: Dictionary = ANNUAL_FILING_DOCUMENT.story_note_fact_contract_summary()
	if int(summary.get("story_note_fact_schema_version", 0)) != 1:
		return _case_fail("Expected story-note fact schema version 1.")
	if str(summary.get("story_note_fact_status", "")) != "task1_story_note_contract_ready":
		return _case_fail("Expected Task 1 story-note fact status.")
	if bool(summary.get("visible_prose_generated", true)):
		return _case_fail("Story-note contract must not generate visible prose.")

	var required_fields: Array = _string_array(summary.get("required_fields", []))
	for field_id in [
		"fact_id",
		"company_id",
		"story_type",
		"note_container",
		"counterparty_id",
		"counterparty_name",
		"agreement_type",
		"effective_date",
		"term_months",
		"term_text",
		"amount",
		"currency",
		"source_system",
		"source_ids",
		"visibility_level",
		"capture_group"
	]:
		if not required_fields.has(field_id):
			return _case_fail("Missing required story-note field: %s." % field_id)

	var story_types: Array = _string_array(summary.get("story_types", []))
	for story_type in [
		"dealership_agreement",
		"supply_or_offtake_agreement",
		"bank_facility",
		"bank_guarantee",
		"lease_or_land_right",
		"government_subsidy",
		"project_contract",
		"segment_expansion",
		"related_party_transaction",
		"subsidiary_commitment",
		"subsequent_event"
	]:
		if not story_types.has(story_type):
			return _case_fail("Missing story type: %s." % story_type)

	var container_definitions: Dictionary = summary.get("note_containers", {}) if typeof(summary.get("note_containers", {})) == TYPE_DICTIONARY else {}
	for container_id in [
		"significant_agreements",
		"commitments_contingencies",
		"bank_facilities_guarantees",
		"segment_operations",
		"government_pricing_subsidies",
		"subsidiaries_leases",
		"related_parties",
		"project_construction",
		"customers_suppliers",
		"subsequent_events",
		"accounting_policies"
	]:
		if not container_definitions.has(container_id):
			return _case_fail("Missing note container definition: %s." % container_id)

	for profile_id in ["bank", "industrial_trading", "default_general"]:
		var allowlist: Array = ANNUAL_FILING_DOCUMENT.story_note_allowed_containers_for_profile(profile_id)
		if allowlist.is_empty():
			return _case_fail("Expected non-empty story-note allowlist for profile %s." % profile_id)
		for container_value in allowlist:
			var container_id: String = str(container_value).strip_edges()
			if not container_definitions.has(container_id):
				return _case_fail("Profile %s allows undefined container %s." % [profile_id, container_id])

	var type_definitions: Dictionary = ANNUAL_FILING_DOCUMENT.story_note_fact_story_type_definitions()
	for story_type in story_types:
		var definition: Dictionary = type_definitions.get(story_type, {}) if typeof(type_definitions.get(story_type, {})) == TYPE_DICTIONARY else {}
		var allowed_containers: Array = _string_array(definition.get("allowed_note_containers", []))
		if allowed_containers.is_empty():
			return _case_fail("Expected allowed containers for story type %s." % story_type)
		for container_value in allowed_containers:
			var container_id: String = str(container_value).strip_edges()
			if not container_definitions.has(container_id):
				return _case_fail("Story type %s allows undefined container %s." % [story_type, container_id])

	var fixtures: Array = _fixtures()
	var fixture_payload: Array[String] = []
	for fixture_value in fixtures:
		var fixture: Dictionary = fixture_value
		var profile_id: String = str(fixture.get("profile_id", "default_general"))
		var fact: Dictionary = ANNUAL_FILING_DOCUMENT.normalize_story_note_fact(fixture)
		var errors: Array = ANNUAL_FILING_DOCUMENT.validate_story_note_fact(fact, profile_id)
		if not errors.is_empty():
			return _case_fail("Fixture %s failed validation: %s." % [str(fact.get("fact_id", "")), ", ".join(_string_array(errors))])
		if _string_array(fact.get("source_ids", [])).is_empty():
			return _case_fail("Fixture %s has no traceable source ids." % str(fact.get("fact_id", "")))
		var allowed_for_type: Array = ANNUAL_FILING_DOCUMENT.story_note_allowed_containers_for_story_type(str(fact.get("story_type", "")), profile_id)
		if not allowed_for_type.has(str(fact.get("note_container", ""))):
			return _case_fail("Fixture %s does not map to an allowed note container." % str(fact.get("fact_id", "")))
		for visible_field in ["visible_text", "paragraph", "body", "rendered_text"]:
			if fact.has(visible_field):
				return _case_fail("Fixture %s generated visible prose field %s." % [str(fact.get("fact_id", "")), visible_field])
		fixture_payload.append(_fact_payload(fact, profile_id))
	fixture_payload.sort()

	return {
		"success": true,
		"payload": "\n".join([
			"contract_hash=%s" % str(summary.get("schema_hash", "")),
			"required=%s" % "|".join(required_fields),
			"story_types=%s" % "|".join(story_types),
			"containers=%s" % "|".join(_sorted_keys(container_definitions)),
			"fixtures=%s" % "\n".join(fixture_payload)
		]),
		"schema_hash": str(summary.get("schema_hash", "")),
		"story_type_count": story_types.size(),
		"container_count": container_definitions.size(),
		"fixture_count": fixtures.size()
	}


func _fixtures() -> Array:
	return [
		{
			"profile_id": "industrial_trading",
			"fact_id": "story_fact|akra|dealership|asahimas|2019",
			"company_id": "akra_sample",
			"story_type": "dealership_agreement",
			"note_container": "significant_agreements",
			"counterparty_id": "asahimas_chemical",
			"counterparty_name": "Asahimas Chemical",
			"agreement_type": "dealership agreement",
			"effective_date": "2019-01-01",
			"term_months": 12,
			"term_text": "one-year term, renewable annually unless terminated by written notice",
			"amount": 32000000.0,
			"currency": "IDR",
			"source_system": "company_story_dossier",
			"source_ids": ["story|dealership|akra_sample", "relationship|supplier|asahimas_chemical"],
			"visibility_level": "filing_note",
			"capture_group": "annual_filing_story_note"
		},
		{
			"profile_id": "industrial_trading",
			"fact_id": "story_fact|akra|bank_guarantee|mandiri|2019",
			"company_id": "akra_sample",
			"story_type": "bank_guarantee",
			"note_container": "bank_facilities_guarantees",
			"counterparty_id": "bank_mandiri",
			"counterparty_name": "Bank Mandiri",
			"agreement_type": "bank guarantee",
			"effective_date": "2019-02-15",
			"term_months": 12,
			"term_text": "held while the related dealership agreement remains effective",
			"amount": 32000000.0,
			"currency": "IDR",
			"source_system": "financial_statement_layer",
			"source_ids": ["annual_note|guarantee|akra_sample", "bank_facility|mandiri|akra_sample"],
			"visibility_level": "filing_note",
			"capture_group": "annual_filing_story_note"
		},
		{
			"profile_id": "bank",
			"fact_id": "story_fact|bori|facility|trade|2019",
			"company_id": "bank_orang_indonesia",
			"story_type": "bank_facility",
			"note_container": "bank_facilities_guarantees",
			"counterparty_id": "corporate_trade_customer",
			"counterparty_name": "Corporate Trade Customer",
			"agreement_type": "trade finance facility",
			"effective_date": "2019-03-28",
			"term_months": 24,
			"term_text": "facility availability reviewed periodically",
			"amount": 120000000.0,
			"currency": "IDR",
			"source_system": "company_relationship_graph",
			"source_ids": ["relationship|bank|trade_customer", "story|trade_finance_growth|bori"],
			"visibility_level": "filing_note",
			"capture_group": "annual_filing_story_note"
		},
		{
			"profile_id": "industrial_trading",
			"fact_id": "story_fact|energy|subsidy|ministry|2019",
			"company_id": "energy_distribution_sample",
			"story_type": "government_subsidy",
			"note_container": "government_pricing_subsidies",
			"counterparty_id": "ministry_of_finance",
			"counterparty_name": "Ministry of Finance",
			"agreement_type": "subsidized selling price reimbursement",
			"effective_date": "2019-01-01",
			"term_months": 0,
			"term_text": "recognized when claims are approved under applicable regulation",
			"amount": 1752754788.0,
			"currency": "IDR",
			"source_system": "content_surface_generation",
			"source_ids": ["macro|subsidized_fuel|2019", "annual_note|subsidy_claim|energy_distribution_sample"],
			"visibility_level": "filing_note",
			"capture_group": "annual_filing_story_note"
		},
		{
			"profile_id": "default_general",
			"fact_id": "story_fact|generic|subsequent|approval|2019",
			"company_id": "generic_company_sample",
			"story_type": "subsequent_event",
			"note_container": "subsequent_events",
			"counterparty_id": "",
			"counterparty_name": "",
			"agreement_type": "post-year-end approval",
			"effective_date": "2020-01-20",
			"term_months": 0,
			"term_text": "",
			"amount": 0.0,
			"currency": "",
			"source_system": "living_company_arc",
			"source_ids": ["arc|post_year_approval|generic_company_sample"],
			"visibility_level": "filing_note",
			"capture_group": "annual_filing_story_note"
		}
	]


func _fact_payload(fact: Dictionary, profile_id: String) -> String:
	return "%s|%s|%s|%s|%s|%s|%s|%s" % [
		profile_id,
		str(fact.get("fact_id", "")),
		str(fact.get("company_id", "")),
		str(fact.get("story_type", "")),
		str(fact.get("note_container", "")),
		str(fact.get("source_system", "")),
		"|".join(_string_array(fact.get("source_ids", []))),
		str(fact.get("capture_group", ""))
	]


func _sorted_keys(source: Dictionary) -> Array:
	var rows: Array = []
	for key_value in source.keys():
		var key: String = str(key_value).strip_edges()
		if not key.is_empty():
			rows.append(key)
	rows.sort()
	return rows


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


func _case_fail(message: String) -> Dictionary:
	return {"success": false, "message": message}


func _fail(message: String) -> void:
	print("ANNUAL_FILING_STORY_NOTE_CONTRACT_FAIL: %s" % message)
	get_tree().quit(1)
