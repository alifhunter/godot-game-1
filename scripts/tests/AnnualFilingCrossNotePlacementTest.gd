extends Node

const ANNUAL_FILING_DOCUMENT = preload("res://systems/AnnualFilingDocument.gd")

const RUN_SEED := 20260624
const EXPECTED_HASH := "1769549668"


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_report()
	if not bool(first_report.get("success", false)):
		_fail(str(first_report.get("message", "annual filing cross-note placement failed")))
		return
	var second_report: Dictionary = _build_report()
	if not bool(second_report.get("success", false)):
		_fail(str(second_report.get("message", "repeated annual filing cross-note placement failed")))
		return
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Annual filing cross-note placement payload changed across repeated runs.")
		return

	var hash: String = _stable_hash(str(first_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual filing cross-note placement hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_FILING_CROSS_NOTE_PLACEMENT_OK %s" % JSON.stringify({
		"hash": hash,
		"placement_count": int(first_report.get("placement_count", 0)),
		"prose_count": int(first_report.get("prose_count", 0)),
		"multi_section_fact_count": int(first_report.get("multi_section_fact_count", 0)),
		"placement_hash": str(first_report.get("placement_hash", "")),
		"prose_hash": str(first_report.get("prose_hash", ""))
	}))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	var annual: Dictionary = _annual_statement()
	var facts: Array = _story_facts()
	var schema_rows: Array = ANNUAL_FILING_DOCUMENT.build_filing_section_schema(annual, "industrial_trading")
	var placement_plan: Array = ANNUAL_FILING_DOCUMENT.build_story_note_placement_plan(
		facts,
		annual,
		schema_rows,
		"industrial_trading",
		{
			"sector_style_id": "energy",
			"max_story_note_placements_per_fact": 3
		}
	)
	var placement_errors: Array = ANNUAL_FILING_DOCUMENT.validate_story_note_placement_plan(placement_plan)
	if not placement_errors.is_empty():
		return _case_fail("Story-note placement validation failed: %s." % ", ".join(_string_array(placement_errors)))
	var placement_validation: Dictionary = _validate_placement_plan(placement_plan)
	if not bool(placement_validation.get("success", false)):
		return placement_validation

	var prose_rows: Array = ANNUAL_FILING_DOCUMENT.build_story_note_prose_packets(
		facts,
		annual,
		schema_rows,
		"industrial_trading",
		{
			"sector_style_id": "energy",
			"story_note_placement_plan": placement_plan,
			"max_story_note_prose_packets_per_section": 8
		}
	)
	var prose_errors: Array = ANNUAL_FILING_DOCUMENT.validate_story_note_prose_packets(prose_rows)
	if not prose_errors.is_empty():
		return _case_fail("Story-note prose validation failed: %s." % ", ".join(_string_array(prose_errors)))
	var prose_validation: Dictionary = _validate_prose_rows(prose_rows)
	if not bool(prose_validation.get("success", false)):
		return prose_validation

	return {
		"success": true,
		"payload": _payload(placement_plan, prose_rows),
		"placement_count": placement_plan.size(),
		"prose_count": prose_rows.size(),
		"multi_section_fact_count": int(placement_validation.get("multi_section_fact_count", 0)),
		"placement_hash": ANNUAL_FILING_DOCUMENT.story_note_placement_plan_hash(placement_plan),
		"prose_hash": ANNUAL_FILING_DOCUMENT.story_note_prose_hash(prose_rows)
	}


func _validate_placement_plan(placement_plan: Array) -> Dictionary:
	if placement_plan.size() < 9:
		return _case_fail("Expected at least 9 placement rows.")
	var role_counts: Dictionary = {}
	var sections_by_fact: Dictionary = {}
	for row_value in placement_plan:
		if typeof(row_value) != TYPE_DICTIONARY:
			return _case_fail("Expected placement row dictionaries.")
		var row: Dictionary = row_value
		var placement_role: String = str(row.get("placement_role", "")).strip_edges()
		var section_id: String = str(row.get("filing_section_id", "")).strip_edges()
		role_counts[placement_role] = int(role_counts.get(placement_role, 0)) + 1
		for fact_id_value in _string_array(row.get("source_story_note_fact_ids", [])):
			var fact_id: String = str(fact_id_value).strip_edges()
			var sections: Array = _string_array(sections_by_fact.get(fact_id, []))
			if not sections.has(section_id):
				sections.append(section_id)
			sections_by_fact[fact_id] = sections
	if int(role_counts.get("primary_note", 0)) <= 0:
		return _case_fail("Missing primary placement rows.")
	if int(role_counts.get("secondary_note", 0)) <= 0:
		return _case_fail("Missing secondary placement rows.")
	if int(role_counts.get("policy_or_risk_echo", 0)) <= 0:
		return _case_fail("Missing policy or risk echo placement rows.")
	var multi_section_fact_count: int = 0
	for fact_id_value in sections_by_fact.keys():
		var section_count: int = _string_array(sections_by_fact.get(fact_id_value, [])).size()
		if section_count >= 2:
			multi_section_fact_count += 1
	if multi_section_fact_count <= 0:
		return _case_fail("Expected at least one material fact to span two or more sections.")
	return {"success": true, "multi_section_fact_count": multi_section_fact_count}


func _validate_prose_rows(prose_rows: Array) -> Dictionary:
	var text_seen: Dictionary = {}
	var text_blob: String = ""
	for row_value in prose_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			return _case_fail("Expected prose row dictionaries.")
		var row: Dictionary = row_value
		var text: String = str(row.get("visible_text", "")).strip_edges()
		var lower_text: String = text.to_lower()
		if text.is_empty():
			return _case_fail("Expected visible prose text.")
		for hidden_token in ["story|", "packet|", "placement|", "truth_state", "source_quality", "confidence"]:
			if lower_text.find(hidden_token) != -1:
				return _case_fail("Story-note placement prose leaked hidden token %s." % hidden_token)
		if text_seen.has(lower_text):
			return _case_fail("Scattered story-note prose repeated paragraph: %s." % text)
		text_seen[lower_text] = true
		text_blob += "\n" + lower_text
	if text_blob.find("this agreement is supported by a bank guarantee issued by") == -1:
		return _case_fail("Missing cross-note bank guarantee phrasing.")
	if text_blob.find("revenue from the related operating segment") == -1:
		return _case_fail("Missing cross-note segment revenue phrasing.")
	return _case_ok()


func _story_facts() -> Array:
	var base: Dictionary = {
		"company_id": "fixture_energy",
		"visibility_level": "filing_note",
		"capture_group": "annual_filing_story_note",
		"source_system": "cross_note_fixture"
	}
	return [
		_fact(base, "fixture|dealership", "dealership_agreement", "significant_agreements", "Asahimas Chemical", "dealership agreement", "2019-03-28", 12, 0.0, ["fixture|source|dealership"]),
		_fact(base, "fixture|facility", "bank_facility", "bank_facilities_guarantees", "Bank Danamon", "omnibus trade facility", "2019-05-17", 12, 120000000000.0, ["fixture|source|facility"]),
		_fact(base, "fixture|guarantee", "bank_guarantee", "commitments_contingencies", "Asahimas Chemical", "dealership agreement", "2019-06-03", 12, 32000000000.0, ["fixture|source|guarantee"]),
		_fact(base, "fixture|subsidy", "government_subsidy", "government_pricing_subsidies", "Ministry of Finance", "government reimbursement arrangement", "2019-08-20", 0, 1752754788.0, ["fixture|source|subsidy"]),
		_fact(base, "fixture|project", "project_contract", "project_construction", "Energy Equity Epic", "booster compression plant rental project contract", "2019-09-18", 80, 72000000000.0, ["fixture|source|project"])
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
	row["term_text"] = ""
	row["amount"] = amount
	row["currency"] = "IDR"
	row["source_ids"] = source_ids
	return ANNUAL_FILING_DOCUMENT.normalize_story_note_fact(row)


func _annual_statement() -> Dictionary:
	var statement_id: String = "annual_statement|cross_note|fixture_energy|2019"
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
			_line(statement_id, "financial_position", "property_plant_equipment", "Property, plant and equipment", 510000000.0)
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


func _payload(placement_plan: Array, prose_rows: Array) -> String:
	var lines: Array[String] = []
	lines.append("placement_hash=%s" % ANNUAL_FILING_DOCUMENT.story_note_placement_plan_hash(placement_plan))
	lines.append("placement_summary=%s" % _dict_payload(ANNUAL_FILING_DOCUMENT.story_note_placement_plan_summary(placement_plan).get("role_counts", {})))
	lines.append("prose_hash=%s" % ANNUAL_FILING_DOCUMENT.story_note_prose_hash(prose_rows))
	lines.append("prose_sections=%s" % _dict_payload(ANNUAL_FILING_DOCUMENT.story_note_prose_summary(prose_rows).get("section_counts", {})))
	for row_value in placement_plan:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("placement:%s:%s:%s:%s" % [
			str(row.get("placement_role", "")),
			str(row.get("filing_section_id", "")),
			str(row.get("paragraph_role", "")),
			"|".join(_string_array(row.get("source_story_note_fact_ids", [])))
		])
	for row_value in prose_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("prose:%s:%s:%s:%s" % [
			str(row.get("filing_section_id", "")),
			str(row.get("story_note_placement_role", "")),
			str(row.get("paragraph_role", "")),
			str(row.get("visible_text", ""))
		])
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
	print("ANNUAL_FILING_CROSS_NOTE_PLACEMENT_FAIL: %s" % message)
	push_error(message)
	get_tree().quit(1)
