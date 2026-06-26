extends Node

const FINANCIAL_STATEMENT_LAYER = preload("res://systems/FinancialStatementLayer.gd")

const EXPECTED_HASH := "1824588069"


func _ready() -> void:
	var customer_report: Dictionary = _run_customer_contract_case()
	if not customer_report.get("success", false):
		_fail(str(customer_report.get("message", "customer contract note case failed")))
		return

	var proceeds_report: Dictionary = _run_use_of_proceeds_case()
	if not proceeds_report.get("success", false):
		_fail(str(proceeds_report.get("message", "use-of-proceeds note case failed")))
		return

	var repeated_customer_report: Dictionary = _run_customer_contract_case()
	var repeated_proceeds_report: Dictionary = _run_use_of_proceeds_case()
	if str(customer_report.get("payload", "")) != str(repeated_customer_report.get("payload", "")):
		_fail("Customer contract note payload changed across repeated fixed input runs.")
		return
	if str(proceeds_report.get("payload", "")) != str(repeated_proceeds_report.get("payload", "")):
		_fail("Use-of-proceeds note payload changed across repeated fixed input runs.")
		return

	var payload: String = "%s\n%s" % [
		str(customer_report.get("payload", "")),
		str(proceeds_report.get("payload", ""))
	]
	var hash: String = _stable_hash(payload)
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Financial statement disclosure hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("FINANCIAL_STATEMENT_LAYER_DISCLOSURE_OK %s" % JSON.stringify({
		"hash": hash,
		"customer_case": customer_report.get("summary", {}),
		"proceeds_case": proceeds_report.get("summary", {})
	}))
	get_tree().quit(0)


func _run_customer_contract_case() -> Dictionary:
	var statement: Dictionary = _base_statement()
	var dossier: Dictionary = {
		"story_id": "story|testco|contract_win|disclosure_a",
		"company_id": "testco",
		"truth_state": "real",
		"priority": 0.88,
		"cause_facts": [
			{"fact_id": "fact|story|testco|contract_win|disclosure_a|customer", "fact_type": "company_trait", "source_id": "contract_win"}
		],
		"financial_effects": [
			{
				"effect_id": "effect|story|testco|contract_win|disclosure_a|revenue",
				"metric_id": "revenue",
				"statement_section": "income_statement",
				"direction": "up",
				"magnitude_band": "large",
				"persistence": "durable",
				"confidence": 0.86,
				"note_type": "customer_contract"
			},
			{
				"effect_id": "effect|story|testco|contract_win|disclosure_a|backlog",
				"metric_id": "backlog",
				"statement_section": "operating_metrics",
				"direction": "up",
				"magnitude_band": "moderate",
				"persistence": "temporary",
				"confidence": 0.72,
				"note_type": "customer_contract"
			}
		],
		"statement_clues": [
			{
				"clue_id": "clue|story|testco|contract_win|disclosure_a|statement|01",
				"fact_ids": ["fact|story|testco|contract_win|disclosure_a|customer"],
				"surface_id": "statement_note",
				"metric_ids": ["revenue", "backlog"],
				"disclosure_quality": "clear"
			}
		]
	}
	var adjusted: Dictionary = FINANCIAL_STATEMENT_LAYER.apply_story_effects_to_statement(
		statement,
		[dossier],
		{"revenue": 4000.0},
		{
			"company_id": "testco",
			"ticker": "TEST",
			"sector_id": "industrial",
			"filing_day_index": 80,
			"relationship_access_level": "inner_circle"
		}
	)
	var notes: Array = _variant_array(adjusted.get("notes", []))
	if notes.size() != 1:
		return _case_fail("Expected one grouped customer-contract note, got %d." % notes.size())
	var note: Dictionary = notes[0]
	var note_check: Dictionary = _validate_note(
		adjusted,
		note,
		"customer_contract",
		["backlog", "revenue"],
		["effect|story|testco|contract_win|disclosure_a|backlog", "effect|story|testco|contract_win|disclosure_a|revenue"],
		["fact|story|testco|contract_win|disclosure_a|customer"],
		["clue|story|testco|contract_win|disclosure_a|statement|01"]
	)
	if not note_check.get("success", false):
		return note_check
	if str(note.get("disclosure_quality", "")) != "clear":
		return _case_fail("Expected clear customer disclosure quality.")
	if str(note.get("detail_level", "")) != "high":
		return _case_fail("Expected inner-circle access to produce high detail level.")
	if str(note.get("summary", "")).find("customer demand") < 0:
		return _case_fail("Expected customer note summary to explain demand clue.")
	if _json_contains_hidden_truth(adjusted):
		return _case_fail("Customer disclosure statement leaked hidden truth metadata.")
	return _case_ok({
		"note_count": notes.size(),
		"quality": note.get("disclosure_quality", ""),
		"detail": note.get("detail_level", ""),
		"importance": note.get("importance", 0.0)
	}, _statement_payload(adjusted))


func _run_use_of_proceeds_case() -> Dictionary:
	var statement: Dictionary = _base_statement()
	statement["balance_sheet"].append({"id": "cash", "label": "Cash and equivalents", "value": 220.0, "format": "currency"})
	var dossier: Dictionary = {
		"story_id": "story|testco|corporate_action_use_of_proceeds|disclosure_b",
		"company_id": "testco",
		"truth_state": "delayed",
		"priority": 0.74,
		"cause_facts": [
			{"fact_id": "fact|story|testco|corporate_action|disclosure_b|placement", "fact_type": "corporate_action", "source_id": "private_placement"}
		],
		"financial_effects": [
			{
				"effect_id": "effect|story|testco|corporate_action|disclosure_b|cash",
				"metric_id": "cash",
				"statement_section": "balance_sheet",
				"direction": "up",
				"magnitude_band": "moderate",
				"persistence": "temporary",
				"confidence": 0.82,
				"note_type": "use_of_proceeds"
			},
			{
				"effect_id": "effect|story|testco|corporate_action|disclosure_b|capex",
				"metric_id": "capex",
				"statement_section": "cash_flow",
				"direction": "up",
				"magnitude_band": "small",
				"persistence": "durable",
				"confidence": 0.70,
				"note_type": "use_of_proceeds"
			}
		],
		"statement_clues": [
			{
				"clue_id": "clue|story|testco|corporate_action|disclosure_b|statement|01",
				"fact_ids": ["fact|story|testco|corporate_action|disclosure_b|placement"],
				"surface_id": "statement_note",
				"metric_ids": ["cash", "capex"],
				"disclosure_quality": "partial"
			}
		]
	}
	var adjusted: Dictionary = FINANCIAL_STATEMENT_LAYER.apply_story_effects_to_statement(
		statement,
		[dossier],
		{"revenue": 4000.0},
		{"company_id": "testco", "ticker": "TEST", "sector_id": "industrial", "filing_day_index": 92}
	)
	var notes: Array = _variant_array(adjusted.get("notes", []))
	if notes.size() != 1:
		return _case_fail("Expected one use-of-proceeds note, got %d." % notes.size())
	var note: Dictionary = notes[0]
	var note_check: Dictionary = _validate_note(
		adjusted,
		note,
		"use_of_proceeds",
		["capex", "cash"],
		["effect|story|testco|corporate_action|disclosure_b|capex", "effect|story|testco|corporate_action|disclosure_b|cash"],
		["fact|story|testco|corporate_action|disclosure_b|placement"],
		["clue|story|testco|corporate_action|disclosure_b|statement|01"]
	)
	if not note_check.get("success", false):
		return note_check
	if str(note.get("disclosure_quality", "")) != "partial":
		return _case_fail("Expected public use-of-proceeds disclosure to stay partial.")
	if not _string_array(note.get("explain_tags", [])).has("post_corporate_action"):
		return _case_fail("Expected use-of-proceeds note to carry post-corporate-action tag.")
	if str(note.get("summary", "")).find("proceeds") < 0:
		return _case_fail("Expected use-of-proceeds summary to mention proceeds.")
	if _json_contains_hidden_truth(adjusted):
		return _case_fail("Use-of-proceeds disclosure statement leaked hidden truth metadata.")
	return _case_ok({
		"note_count": notes.size(),
		"quality": note.get("disclosure_quality", ""),
		"tags": _string_array(note.get("explain_tags", [])),
		"importance": note.get("importance", 0.0)
	}, _statement_payload(adjusted))


func _validate_note(
	statement: Dictionary,
	note: Dictionary,
	expected_note_type: String,
	expected_metric_ids: Array,
	expected_effect_ids: Array,
	expected_fact_ids: Array,
	expected_clue_ids: Array
) -> Dictionary:
	if str(note.get("note_type", "")) != expected_note_type:
		return _case_fail("Expected note type %s, got %s." % [expected_note_type, str(note.get("note_type", ""))])
	if _string_array(note.get("metric_ids", [])) != _string_array(expected_metric_ids):
		return _case_fail("Note metric ids did not match expected structured facts.")
	if _string_array(note.get("effect_ids", [])) != _string_array(expected_effect_ids):
		return _case_fail("Note effect ids did not match expected structured facts.")
	if _string_array(note.get("fact_ids", [])) != _string_array(expected_fact_ids):
		return _case_fail("Note fact ids did not match expected structured facts.")
	if _string_array(note.get("clue_ids", [])) != _string_array(expected_clue_ids):
		return _case_fail("Note clue ids did not match expected structured facts.")
	if str(note.get("summary", "")).strip_edges().is_empty():
		return _case_fail("Expected note summary text.")
	var note_id: String = str(note.get("note_id", ""))
	if note_id.is_empty():
		return _case_fail("Expected stable note id.")
	for adjustment_value in _variant_array(statement.get("story_adjustments", [])):
		if typeof(adjustment_value) != TYPE_DICTIONARY:
			continue
		var adjustment: Dictionary = adjustment_value
		if expected_effect_ids.has(str(adjustment.get("effect_id", ""))) and str(adjustment.get("note_id", "")) != note_id:
			return _case_fail("Adjustment %s did not point back to generated note." % str(adjustment.get("effect_id", "")))
	var traceability: Dictionary = statement.get("traceability", {})
	if not _string_array(traceability.get("generated_note_ids", [])).has(note_id):
		return _case_fail("Traceability did not include generated note id.")
	return _case_ok({}, "")


func _base_statement() -> Dictionary:
	return {
		"statement_year": 2020,
		"statement_quarter": 2,
		"statement_period_label": "Q2 2020",
		"income_statement": [
			{"id": "revenue", "label": "Total revenue", "value": 1000.0, "format": "currency"},
			{"id": "gross_profit", "label": "Gross profit", "value": 320.0, "format": "currency"},
			{"id": "operating_income", "label": "Income from operations", "value": 160.0, "format": "currency"},
			{"id": "net_income", "label": "Net income for the period", "value": 90.0, "format": "currency"}
		],
		"balance_sheet": [
			{"id": "current_assets", "label": "Current assets", "value": 620.0, "format": "currency"},
			{"id": "total_assets", "label": "Total assets", "value": 1800.0, "format": "currency"},
			{"id": "total_liabilities", "label": "Total liabilities", "value": 720.0, "format": "currency"},
			{"id": "equity", "label": "Equity", "value": 1080.0, "format": "currency"},
			{"id": "shares_outstanding", "label": "Shares outstanding", "value": 1000000.0, "format": "shares"}
		],
		"cash_flow": [
			{"id": "cash_from_operating", "label": "Cash from operating", "value": 120.0, "format": "currency"},
			{"id": "cash_from_investing", "label": "Cash from investing", "value": -180.0, "format": "currency"},
			{"id": "cash_from_financing", "label": "Cash from financing", "value": 30.0, "format": "currency"}
		]
	}


func _statement_payload(statement: Dictionary) -> String:
	var rows: Array[String] = []
	rows.append("statement_id=%s" % str(statement.get("statement_id", "")))
	for note_value in _variant_array(statement.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		rows.append("note:%s:%s:%s:%s:%s:%s:%s:%s" % [
			str(note.get("note_id", "")),
			str(note.get("note_type", "")),
			str(note.get("disclosure_quality", "")),
			str(note.get("detail_level", "")),
			snappedf(float(note.get("importance", 0.0)), 0.001),
			"|".join(_string_array(note.get("metric_ids", []))),
			"|".join(_string_array(note.get("effect_ids", []))),
			str(note.get("summary", ""))
		])
	for adjustment_value in _variant_array(statement.get("story_adjustments", [])):
		if typeof(adjustment_value) != TYPE_DICTIONARY:
			continue
		var adjustment: Dictionary = adjustment_value
		rows.append("adjustment:%s:%s:%s:%s" % [
			str(adjustment.get("adjustment_id", "")),
			str(adjustment.get("effect_id", "")),
			str(adjustment.get("note_id", "")),
			snappedf(float(adjustment.get("applied_delta_amount", 0.0)), 0.001)
		])
	return "\n".join(rows)


func _json_contains_hidden_truth(statement: Dictionary) -> bool:
	var text: String = JSON.stringify(statement).to_lower()
	for token in ["truth_state", "fraud_risk", "overhyped", "uncertain"]:
		if text.find(token) >= 0:
			return true
	return false


func _case_ok(summary: Dictionary, payload: String) -> Dictionary:
	return {"success": true, "summary": summary, "payload": payload}


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
		hash_value = int((hash_value ^ text.unicode_at(index)) * 16777619)
		hash_value = hash_value % 2147483647
		if hash_value < 0:
			hash_value += 2147483647
	return str(hash_value)


func _fail(message: String) -> void:
	push_error(message)
	print("FINANCIAL_STATEMENT_LAYER_DISCLOSURE_FAIL: %s" % message)
	get_tree().quit(1)
