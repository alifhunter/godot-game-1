extends Node

const ANNUAL_FILING_DOCUMENT = preload("res://systems/AnnualFilingDocument.gd")

const RUN_SEED := 20260621
const EXPECTED_HASH := "1373663978"
const REQUIRED_TEMPLATE_TYPES := [
	"company_information",
	"accounting_policies",
	"estimates_and_judgments",
	"receivables",
	"bank_cash_reserves",
	"bank_loans",
	"bank_funding",
	"bank_capital",
	"bank_credit_risk",
	"bank_liquidity_risk",
	"bank_regulatory",
	"inventories",
	"ppe_capex",
	"borrowings",
	"revenue",
	"segment",
	"related_party",
	"commitments",
	"risk_management",
	"subsequent_events"
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
		_fail(str(first_report.get("message", "annual filing prose library failed")))
		return
	var second_report: Dictionary = _build_report()
	if not bool(second_report.get("success", false)):
		_fail(str(second_report.get("message", "repeated annual filing prose library failed")))
		return
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Annual filing prose payload changed across repeated fixed-seed runs.")
		return

	var hash: String = _stable_hash(str(first_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual filing prose library hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_FILING_PROSE_LIBRARY_OK %s" % JSON.stringify({
		"hash": hash,
		"company_id": str(first_report.get("company_id", "")),
		"fiscal_year": int(first_report.get("fiscal_year", 0)),
		"prose_hash": str(first_report.get("prose_hash", "")),
		"prose_count": int(first_report.get("prose_count", 0)),
		"boilerplate_count": int(first_report.get("boilerplate_count", 0)),
		"footprint_prose_count": int(first_report.get("footprint_prose_count", 0))
	}))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	if RunState.company_order.is_empty():
		return _case_fail("Expected generated company order.")

	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		if not RunState.ensure_company_full_detail(company_id):
			continue
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, true, true)
		var snapshot: Dictionary = definition.get("financial_statement_snapshot", {}) if typeof(definition.get("financial_statement_snapshot", {})) == TYPE_DICTIONARY else {}
		var annual: Dictionary = snapshot.get("annual_statement", {}) if typeof(snapshot.get("annual_statement", {})) == TYPE_DICTIONARY else {}
		if annual.is_empty():
			continue
		var options: Dictionary = {
			"ticker": str(definition.get("ticker", "")),
			"company_name": str(definition.get("name", "")),
			"sector_style_id": str(definition.get("sector_id", "generic_annual_filing"))
		}
		var contract: Dictionary = ANNUAL_FILING_DOCUMENT.build_request_contract(annual, int(RunState.run_seed), company_id, options)
		var prose_rows: Array = _variant_array(contract.get("filing_prose_packets", []))
		var footprints: Array = _variant_array(contract.get("accounting_footprint_packets", []))
		if prose_rows.is_empty() or footprints.is_empty():
			continue
		var validation: Dictionary = _validate_contract(contract, annual, options)
		if not bool(validation.get("success", false)):
			return validation
		return {
			"success": true,
			"payload": _payload(contract),
			"company_id": company_id,
			"fiscal_year": int(contract.get("fiscal_year", 0)),
			"prose_hash": str(contract.get("filing_prose_hash", "")),
			"prose_count": prose_rows.size(),
			"boilerplate_count": int(validation.get("boilerplate_count", 0)),
			"footprint_prose_count": int(validation.get("footprint_prose_count", 0))
		}
	return _case_fail("Expected at least one company with annual filing prose packets.")


func _validate_contract(contract: Dictionary, annual: Dictionary, options: Dictionary) -> Dictionary:
	if int(contract.get("filing_prose_schema_version", 0)) != 1:
		return _case_fail("Expected filing prose schema version 1.")
	if str(contract.get("filing_prose_status", "")) != "task4_prose_library_ready":
		return _case_fail("Expected Task 4 filing prose status.")
	if str(contract.get("filing_prose_hash", "")).strip_edges().is_empty():
		return _case_fail("Expected filing prose hash.")
	var helper_hash: String = ANNUAL_FILING_DOCUMENT.filing_prose_hash(
		annual,
		_variant_array(contract.get("filing_section_schema", [])),
		_variant_array(contract.get("accounting_footprint_packets", [])),
		str(options.get("sector_style_id", "generic_annual_filing"))
	)
	if str(contract.get("filing_prose_hash", "")) != helper_hash:
		return _case_fail("Filing prose hash helper mismatch.")

	var template_definitions: Dictionary = ANNUAL_FILING_DOCUMENT.filing_prose_template_definitions()
	for template_type in REQUIRED_TEMPLATE_TYPES:
		if not template_definitions.has(template_type):
			return _case_fail("Missing filing prose template type %s." % str(template_type))

	var styles: Dictionary = ANNUAL_FILING_DOCUMENT.sector_style_vocabulary_definitions()
	if not styles.has("generic_annual_filing"):
		return _case_fail("Missing generic annual filing prose style.")
	if not styles.has("trading_logistics_industrial_estate"):
		return _case_fail("Missing trading/logistics/industrial-estate prose style.")

	var prose_rows: Array = _variant_array(contract.get("filing_prose_packets", []))
	var boilerplate_count: int = 0
	var footprint_prose_count: int = 0
	var quantified_count: int = 0
	var amount_text_count: int = 0
	var low_or_none_count: int = 0
	for row_value in prose_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			return _case_fail("Expected prose rows to be dictionaries.")
		var row: Dictionary = row_value
		var visible_text: String = str(row.get("visible_text", "")).strip_edges()
		if visible_text.is_empty():
			return _case_fail("Expected prose visible text.")
		var lower_text: String = visible_text.to_lower()
		for token in HIDDEN_VISIBLE_TOKENS:
			if lower_text.contains(str(token)):
				return _case_fail("Filing prose visible text leaked hidden token %s." % str(token))
		for phrase in FORBIDDEN_GENERIC_PHRASES:
			if lower_text.contains(str(phrase)):
				return _case_fail("Filing prose retained forbidden generic phrase: %s." % str(phrase))
		if bool(row.get("visible_truth_labels_allowed", true)):
			return _case_fail("Filing prose should not allow visible truth labels.")
		if bool(row.get("hidden_source_ids_visible", true)):
			return _case_fail("Filing prose should not show hidden source ids.")
		var role: String = str(row.get("paragraph_role", ""))
		if role == "routine_boilerplate" or role == "accounting_policy" or role == "estimate_context":
			boilerplate_count += 1
		if not _string_array(row.get("source_footprint_ids", [])).is_empty():
			footprint_prose_count += 1
		if role == "quantified_footprint":
			quantified_count += 1
			if _has_digit(lower_text):
				amount_text_count += 1
		if str(row.get("clue_density", "")) in ["none", "low"]:
			low_or_none_count += 1
	if boilerplate_count <= 0:
		return _case_fail("Expected routine boilerplate prose.")
	if footprint_prose_count <= 0:
		return _case_fail("Expected footprint-linked prose.")
	if quantified_count <= 0 or amount_text_count <= 0:
		return _case_fail("Expected quantified footprint prose with amount text.")
	if low_or_none_count <= 0:
		return _case_fail("Expected low-clue or no-clue prose.")
	return {
		"success": true,
		"boilerplate_count": boilerplate_count,
		"footprint_prose_count": footprint_prose_count
	}


func _payload(contract: Dictionary) -> String:
	var prose_rows: Array = _variant_array(contract.get("filing_prose_packets", []))
	var lines: Array[String] = []
	lines.append("status=%s:%s:%s" % [
		str(contract.get("filing_prose_schema_version", "")),
		str(contract.get("filing_prose_status", "")),
		str(contract.get("filing_prose_hash", ""))
	])
	lines.append("roles=%s" % _dict_payload(contract.get("filing_prose_role_counts", {})))
	lines.append("sections=%s" % _dict_payload(contract.get("filing_prose_section_counts", {})))
	for row_value in prose_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("row:%d:%s:%s:%s:%s:%s:%s:%s:%s" % [
			int(row.get("paragraph_order", 0)),
			str(row.get("filing_section_id", "")),
			str(row.get("template_type", "")),
			str(row.get("paragraph_role", "")),
			str(row.get("clue_density", "")),
			str(row.get("boilerplate_density", "")),
			"|".join(_string_array(row.get("source_footprint_ids", []))),
			"|".join(_string_array(row.get("source_disclosure_packet_ids", []))),
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


func _has_digit(text: String) -> bool:
	for index in range(text.length()):
		var code: int = text.unicode_at(index)
		if code >= 48 and code <= 57:
			return true
	return false


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int(hash_value ^ text.unicode_at(index))
		hash_value = int((hash_value * 16777619) & 0x7fffffff)
	return str(hash_value)


func _case_fail(message: String) -> Dictionary:
	return {"success": false, "message": message}


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
