extends Node

const ANNUAL_FILING_DOCUMENT = preload("res://systems/AnnualFilingDocument.gd")

const RUN_SEED := 20260624
const EXPECTED_HASH := "487832935"
const REQUIRED_ROLES := [
	"agreement_lead",
	"facility_detail",
	"commitment_detail",
	"segment_context",
	"subsequent_event"
]
const REQUIRED_TEXT_SHAPES := [
	"renewed or terminated",
	"sub-limits",
	"bank guarantee",
	"construction period",
	"subsidized or reimbursable",
	"related party",
	"after the reporting date"
]
const REQUIRED_COUNTERPARTY_TERMS := [
	"Asahimas Chemical",
	"SPBU Operators",
	"Bank Danamon",
	"Jakarta Land Authority",
	"Ministry of Finance",
	"Energy Equity Epic"
]
const REQUIRED_CONCRETE_TERMS := [
	"2019",
	"IDR"
]
const FORBIDDEN_RECOMMENDATION_LANGUAGE := [
	" buy ",
	" sell ",
	" hold ",
	"target price",
	"upside",
	"downside",
	"recommendation",
	"should buy",
	"should sell"
]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_report()
	if not bool(first_report.get("success", false)):
		_fail(str(first_report.get("message", "annual filing story note renderer failed")))
		return
	var second_report: Dictionary = _build_report()
	if not bool(second_report.get("success", false)):
		_fail(str(second_report.get("message", "repeated annual filing story note renderer failed")))
		return
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Annual filing story note renderer payload changed across repeated runs.")
		return

	var hash: String = _stable_hash(str(first_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual filing story note renderer hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_FILING_STORY_NOTE_RENDERER_OK %s" % JSON.stringify({
		"hash": hash,
		"fact_count": int(first_report.get("fact_count", 0)),
		"prose_count": int(first_report.get("prose_count", 0)),
		"visible_story_paragraph_count": int(first_report.get("visible_story_paragraph_count", 0)),
		"story_note_prose_hash": str(first_report.get("story_note_prose_hash", ""))
	}))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	var annual: Dictionary = _annual_statement()
	var facts: Array = _story_facts()
	var schema_rows: Array = ANNUAL_FILING_DOCUMENT.build_filing_section_schema(annual, "industrial_trading")
	var prose_rows: Array = ANNUAL_FILING_DOCUMENT.build_story_note_prose_packets(
		facts,
		annual,
		schema_rows,
		"industrial_trading",
		{
			"sector_style_id": "energy",
			"max_story_note_prose_packets_per_section": 4
		}
	)
	var prose_errors: Array = ANNUAL_FILING_DOCUMENT.validate_story_note_prose_packets(prose_rows)
	if not prose_errors.is_empty():
		return _case_fail("Story note prose validation failed: %s." % ", ".join(_string_array(prose_errors)))
	var validation: Dictionary = _validate_prose_rows(prose_rows)
	if not bool(validation.get("success", false)):
		return validation

	var contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(
		annual,
		RUN_SEED,
		str(annual.get("company_id", "")),
		{
			"filing_profile_id": "industrial_trading",
			"sector_style_id": "energy",
			"company_name": str(annual.get("company_name", "")),
			"min_story_note_fact_packets": 0
		}
	)
	contract["story_note_fact_packets"] = facts
	contract["story_note_fact_packet_hash"] = ANNUAL_FILING_DOCUMENT.story_note_fact_packet_hash(facts)
	contract["story_note_prose_packets"] = prose_rows
	contract["story_note_prose_hash"] = ANNUAL_FILING_DOCUMENT.story_note_prose_hash(prose_rows)
	contract["story_note_prose_count"] = prose_rows.size()
	var visible_document: Dictionary = ANNUAL_FILING_DOCUMENT.build_visible_filing_document(annual, contract, {"sector_style_id": "energy"})
	validation = _validate_visible_story_notes(visible_document)
	if not bool(validation.get("success", false)):
		return validation
	var control_validation: Dictionary = _validate_bank_facility_absent_without_source(annual, facts)
	if not bool(control_validation.get("success", false)):
		return control_validation

	return {
		"success": true,
		"payload": _payload(prose_rows, visible_document),
		"fact_count": facts.size(),
		"prose_count": prose_rows.size(),
		"visible_story_paragraph_count": int(validation.get("visible_story_paragraph_count", 0)),
		"story_note_prose_hash": ANNUAL_FILING_DOCUMENT.story_note_prose_hash(prose_rows)
	}


func _validate_prose_rows(prose_rows: Array) -> Dictionary:
	if prose_rows.size() < 8:
		return _case_fail("Expected at least 8 story-note prose rows.")
	var role_counts: Dictionary = {}
	var text_blob: String = ""
	var seen_by_section: Dictionary = {}
	for row_value in prose_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			return _case_fail("Expected story-note prose row dictionaries.")
		var row: Dictionary = row_value
		var text: String = str(row.get("visible_text", "")).strip_edges()
		var lower_text: String = text.to_lower()
		var section_id: String = str(row.get("filing_section_id", "")).strip_edges()
		var role: String = str(row.get("paragraph_role", "")).strip_edges()
		if text.is_empty():
			return _case_fail("Expected story-note prose visible text.")
		if not ANNUAL_FILING_DOCUMENT.story_note_prose_roles().has(role):
			return _case_fail("Unknown story-note prose role %s." % role)
		for phrase in ANNUAL_FILING_DOCUMENT.story_note_prose_forbidden_phrases():
			if lower_text.find(str(phrase)) != -1:
				return _case_fail("Story-note prose retained forbidden phrase: %s." % str(phrase))
		for hidden_token in ["story|", "packet|", "placement|", "truth_state", "source_quality", "confidence"]:
			if lower_text.find(hidden_token) != -1:
				return _case_fail("Story-note prose leaked hidden token %s." % hidden_token)
		for recommendation_value in FORBIDDEN_RECOMMENDATION_LANGUAGE:
			var recommendation: String = str(recommendation_value)
			if (" %s " % lower_text).find(recommendation) != -1:
				return _case_fail("Story-note prose leaked recommendation language: %s." % recommendation.strip_edges())
		var section_seen: Dictionary = seen_by_section.get(section_id, {}) if typeof(seen_by_section.get(section_id, {})) == TYPE_DICTIONARY else {}
		if section_seen.has(lower_text):
			return _case_fail("Story-note prose repeated paragraph in %s." % section_id)
		section_seen[lower_text] = true
		seen_by_section[section_id] = section_seen
		role_counts[role] = int(role_counts.get(role, 0)) + 1
		text_blob += "\n" + lower_text
	for required_role in REQUIRED_ROLES:
		if int(role_counts.get(required_role, 0)) <= 0:
			return _case_fail("Missing story-note prose role %s." % str(required_role))
	for required_shape in REQUIRED_TEXT_SHAPES:
		if text_blob.find(str(required_shape)) == -1:
			return _case_fail("Missing story-note prose shape: %s." % str(required_shape))
	for counterparty_value in REQUIRED_COUNTERPARTY_TERMS:
		var counterparty: String = str(counterparty_value).to_lower()
		if text_blob.find(counterparty) == -1:
			return _case_fail("Missing concrete story-note counterparty: %s." % str(counterparty_value))
	for concrete_value in REQUIRED_CONCRETE_TERMS:
		var concrete: String = str(concrete_value).to_lower()
		if text_blob.find(concrete) == -1:
			return _case_fail("Missing concrete story-note date/amount/term marker: %s." % str(concrete_value))
	if text_blob.find("agreement") == -1 or text_blob.find("facility") == -1:
		return _case_fail("Story-note prose should read as agreement/facility disclosure, not evidence-card copy.")
	if text_blob.find("guarantee") == -1 or text_blob.find("required") == -1:
		return _case_fail("Commitments story-note prose should include obligation or guarantee language.")
	if text_blob.find("segment") == -1 or text_blob.find("revenue") == -1:
		return _case_fail("Segment story-note prose should include segment operating context.")
	return _case_ok()


func _validate_visible_story_notes(visible_document: Dictionary) -> Dictionary:
	var story_paragraph_count: int = 0
	var sections: Array = _variant_array(visible_document.get("visible_filing_sections", []))
	if sections.is_empty():
		return _case_fail("Expected visible filing sections.")
	for section_value in sections:
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		var title: String = str(section.get("title", "")).to_lower()
		if title.begins_with("notes -"):
			return _case_fail("Visible note title retained Notes prefix.")
		var seen_text: Dictionary = {}
		for paragraph_value in _variant_array(section.get("paragraphs", [])):
			if typeof(paragraph_value) != TYPE_DICTIONARY:
				continue
			var paragraph: Dictionary = paragraph_value
			var text: String = str(paragraph.get("text", "")).strip_edges()
			var text_key: String = text.to_lower()
			if seen_text.has(text_key):
				return _case_fail("Visible story note repeated paragraph: %s." % text)
			seen_text[text_key] = true
			if ANNUAL_FILING_DOCUMENT.story_note_prose_roles().has(str(paragraph.get("paragraph_role", ""))):
				story_paragraph_count += 1
				if _string_array(paragraph.get("source_story_note_fact_ids", [])).is_empty():
					return _case_fail("Visible story-note paragraph lost fact source ids.")
				for recommendation_value in FORBIDDEN_RECOMMENDATION_LANGUAGE:
					var recommendation: String = str(recommendation_value)
					if (" %s " % text_key).find(recommendation) != -1:
						return _case_fail("Visible story-note paragraph leaked recommendation language: %s." % recommendation.strip_edges())
	if story_paragraph_count < 4:
		return _case_fail("Expected at least 4 visible story-note paragraphs.")
	return {"success": true, "visible_story_paragraph_count": story_paragraph_count}


func _validate_bank_facility_absent_without_source(annual: Dictionary, facts: Array) -> Dictionary:
	var no_facility_facts: Array = []
	for fact_value in facts:
		if typeof(fact_value) != TYPE_DICTIONARY:
			continue
		var fact: Dictionary = fact_value
		if str(fact.get("story_type", "")) == "bank_facility":
			continue
		no_facility_facts.append(fact.duplicate(true))
	var schema_rows: Array = ANNUAL_FILING_DOCUMENT.build_filing_section_schema(annual, "industrial_trading")
	var prose_rows: Array = ANNUAL_FILING_DOCUMENT.build_story_note_prose_packets(
		no_facility_facts,
		annual,
		schema_rows,
		"industrial_trading",
		{
			"sector_style_id": "energy",
			"max_story_note_prose_packets_per_section": 4
		}
	)
	var control_text: String = ""
	for row_value in prose_rows:
		if typeof(row_value) == TYPE_DICTIONARY:
			control_text += "\n" + str(row_value.get("visible_text", "")).to_lower()
	if control_text.find("sub-limits") != -1 or control_text.find("omnibus trade facility") != -1:
		return _case_fail("Bank-facility prose appeared without a bank_facility source fact.")
	return _case_ok()


func _story_facts() -> Array:
	var base: Dictionary = {
		"company_id": "fixture_energy",
		"visibility_level": "filing_note",
		"capture_group": "annual_filing_story_note",
		"source_system": "renderer_fixture"
	}
	return [
		_fact(base, "fixture|dealership", "dealership_agreement", "significant_agreements", "Asahimas Chemical", "dealership agreement", "2019-03-28", 12, "", 0.0, ["fixture|source|dealership"]),
		_fact(base, "fixture|supply", "supply_or_offtake_agreement", "customers_suppliers", "SPBU Operators", "operator sales agreement", "2019-04-11", 180, "", 0.0, ["fixture|source|operators"]),
		_fact(base, "fixture|facility", "bank_facility", "bank_facilities_guarantees", "Bank Danamon", "omnibus trade facility", "2019-05-17", 12, "", 120000000000.0, ["fixture|source|facility"]),
		_fact(base, "fixture|guarantee", "bank_guarantee", "commitments_contingencies", "Asahimas Chemical", "dealership agreement", "2019-06-03", 12, "", 32000000000.0, ["fixture|source|guarantee"]),
		_fact(base, "fixture|lease", "lease_or_land_right", "subsidiaries_leases", "Jakarta Land Authority", "long-term land lease agreement", "2019-07-09", 240, "", 184847871000.0, ["fixture|source|lease"]),
		_fact(base, "fixture|subsidy", "government_subsidy", "government_pricing_subsidies", "Ministry of Finance", "government reimbursement arrangement", "2019-08-20", 0, "", 1752754788.0, ["fixture|source|subsidy"]),
		_fact(base, "fixture|project", "project_contract", "project_construction", "Energy Equity Epic", "booster compression plant rental project contract", "2019-09-18", 80, "", 72000000000.0, ["fixture|source|project"]),
		_fact(base, "fixture|segment", "segment_expansion", "segment_operations", "", "oil and gas properties segment operation", "2019-10-01", 0, "", 0.0, ["fixture|source|segment"]),
		_fact(base, "fixture|related", "related_party_transaction", "related_parties", "APR Subsidiary", "related party transaction", "2019-10-14", 0, "", 48000000000.0, ["fixture|source|related"]),
		_fact(base, "fixture|subsequent", "subsequent_event", "subsequent_events", "", "post-year-end project approval", "2020-01-15", 0, "", 0.0, ["fixture|source|subsequent"])
	]


func _fact(
	base: Dictionary,
	fact_id: String,
	story_type: String,
	note_container: String,
	counterparty_name: String,
	agreement_type: String,
	effective_date: String,
	term_months: int,
	term_text: String,
	amount: float,
	source_ids: Array
) -> Dictionary:
	var row: Dictionary = base.duplicate(true)
	row["fact_id"] = fact_id
	row["story_type"] = story_type
	row["note_container"] = note_container
	row["counterparty_id"] = "counterparty|%s" % counterparty_name.to_lower().replace(" ", "_") if not counterparty_name.is_empty() else ""
	row["counterparty_name"] = counterparty_name
	row["agreement_type"] = agreement_type
	row["effective_date"] = effective_date
	row["term_months"] = term_months
	row["term_text"] = term_text
	row["amount"] = amount
	row["currency"] = "IDR"
	row["source_ids"] = source_ids
	return ANNUAL_FILING_DOCUMENT.normalize_story_note_fact(row)


func _annual_statement() -> Dictionary:
	var statement_id: String = "annual_statement|story_note_renderer|fixture_energy|2019"
	return {
		"statement_id": statement_id,
		"company_id": "fixture_energy",
		"ticker": "FNRG",
		"company_name": "Fixture Energy",
		"fiscal_year": 2019,
		"comparative_year": 2018,
		"statement_scope": "annual",
		"consolidated": true,
		"statement_period_label": "FY2019",
		"currency": "IDR",
		"financial_position": [
			_line(statement_id, "financial_position", "cash", "Cash and cash equivalents", 140000000.0),
			_line(statement_id, "financial_position", "debt", "Debt and borrowings", 320000000.0),
			_line(statement_id, "financial_position", "property_plant_equipment", "Property, plant and equipment", 510000000.0),
			_line(statement_id, "financial_position", "right_of_use_assets", "Right-of-use assets", 85000000.0),
			_line(statement_id, "financial_position", "current_liabilities", "Current liabilities", 210000000.0)
		],
		"profit_or_loss_and_oci": [
			_line(statement_id, "profit_or_loss_and_oci", "revenue", "Revenue", 920000000.0),
			_line(statement_id, "profit_or_loss_and_oci", "gross_profit", "Gross profit", 310000000.0)
		],
		"cash_flows": [
			_line(statement_id, "cash_flows", "purchase_of_property_plant_equipment", "Purchase of property, plant and equipment", -72000000.0)
		],
		"notes": []
	}


func _line(statement_id: String, section_id: String, metric_id: String, label: String, value: float) -> Dictionary:
	return {
		"id": metric_id,
		"line_id": "line|%s|%s|%s" % [statement_id, section_id, metric_id],
		"section_id": section_id,
		"metric_id": metric_id,
		"label": label,
		"value": value,
		"format": "currency"
	}


func _payload(prose_rows: Array, visible_document: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("prose_hash=%s" % ANNUAL_FILING_DOCUMENT.story_note_prose_hash(prose_rows))
	lines.append("roles=%s" % _dict_payload(ANNUAL_FILING_DOCUMENT.story_note_prose_summary(prose_rows).get("role_counts", {})))
	lines.append("sections=%s" % _dict_payload(ANNUAL_FILING_DOCUMENT.story_note_prose_summary(prose_rows).get("section_counts", {})))
	for row_value in prose_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("row:%s:%s:%s:%s:%s" % [
			str(row.get("filing_section_id", "")),
			str(row.get("paragraph_role", "")),
			str(row.get("template_type", "")),
			"|".join(_string_array(row.get("source_story_note_fact_ids", []))),
			str(row.get("visible_text", ""))
		])
	lines.append("visible_hash=%s" % str(visible_document.get("visible_filing_hash", "")))
	lines.append("visible_sources=%s" % _dict_payload(visible_document.get("visible_generation_sources", {})))
	return "\n".join(lines)


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
	print("ANNUAL_FILING_STORY_NOTE_RENDERER_FAIL: %s" % message)
	push_error(message)
	get_tree().quit(1)
