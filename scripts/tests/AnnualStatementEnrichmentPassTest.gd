extends Node

const RUN_SEED := 20260617
const EXPECTED_NOTE_COUNT := 14
const PASS_ID := "r2_1_post_start_traceability_contract"
const SOURCE_ID := "annual_statement_post_start_enrichment"
const EXPECTED_SOURCE_SYSTEM_IDS := [
	"company_story_dossier",
	"living_company_arc",
	"corporate_action",
	"event_history",
	"company_roadmap"
]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var result: Dictionary = _run_case()
	if not bool(result.get("success", false)):
		_fail(str(result.get("message", "annual statement enrichment pass failed")))
		return

	print("ANNUAL_STATEMENT_ENRICHMENT_PASS_OK %s" % JSON.stringify(result.get("summary", {})))
	get_tree().quit(0)


func _run_case() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	if RunState.company_order.is_empty():
		return _case_fail("Expected generated company order.")
	var company_id: String = str(RunState.company_order[0])
	if not RunState.ensure_company_full_detail(company_id):
		return _case_fail("Could not hydrate full detail for %s." % company_id)

	var first_snapshot: Dictionary = _snapshot_for_company(company_id)
	var first_annual: Dictionary = _annual_from_snapshot(first_snapshot)
	var validation: Dictionary = _validate_enriched_annual(first_snapshot, first_annual)
	if not bool(validation.get("success", false)):
		return validation
	var first_payload: String = _enrichment_payload(first_annual)

	var first_refresh_count: int = RunState.refresh_annual_statement_post_start_enrichment(company_id)
	var second_refresh_count: int = RunState.refresh_annual_statement_post_start_enrichment(company_id)
	var refreshed_annual: Dictionary = _annual_from_snapshot(_snapshot_for_company(company_id))
	var refreshed_payload: String = _enrichment_payload(refreshed_annual)
	if first_payload != refreshed_payload:
		return _case_fail("Annual enrichment payload changed after repeated enrichment.")

	var stripped_snapshot: Dictionary = _strip_snapshot_enrichment(_snapshot_for_company(company_id))
	if not _write_snapshot_for_company(company_id, stripped_snapshot):
		return _case_fail("Could not write stripped legacy-style annual statement snapshot.")
	var stripped_annual: Dictionary = _annual_from_snapshot(_snapshot_for_company(company_id))
	if stripped_annual.has("post_start_traceability"):
		return _case_fail("Legacy-style stripped annual statement still had post-start traceability.")

	var save_payload: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(save_payload)
	var loaded_snapshot: Dictionary = _snapshot_for_company(company_id)
	var loaded_annual: Dictionary = _annual_from_snapshot(loaded_snapshot)
	var loaded_validation: Dictionary = _validate_enriched_annual(loaded_snapshot, loaded_annual)
	if not bool(loaded_validation.get("success", false)):
		return loaded_validation
	var loaded_payload: String = _enrichment_payload(loaded_annual)
	RunState.refresh_annual_statement_post_start_enrichment(company_id)
	RunState.refresh_annual_statement_post_start_enrichment(company_id)
	var loaded_refreshed_payload: String = _enrichment_payload(_annual_from_snapshot(_snapshot_for_company(company_id)))
	if loaded_payload != loaded_refreshed_payload:
		return _case_fail("Loaded annual enrichment payload changed after repeated repair refreshes.")

	return {
		"success": true,
		"summary": {
			"company_id": company_id,
			"first_refresh_count": first_refresh_count,
			"second_refresh_count": second_refresh_count,
			"note_count": _variant_array(loaded_annual.get("notes", [])).size(),
			"source_system_count": EXPECTED_SOURCE_SYSTEM_IDS.size()
		}
	}


func _validate_enriched_annual(snapshot: Dictionary, annual: Dictionary) -> Dictionary:
	if annual.is_empty():
		return _case_fail("Expected annual statement.")
	var enrichment: Dictionary = annual.get("post_start_traceability", {}) if typeof(annual.get("post_start_traceability", {})) == TYPE_DICTIONARY else {}
	if enrichment.is_empty():
		return _case_fail("Expected statement-level post-start traceability.")
	if int(enrichment.get("schema_version", 0)) != 1:
		return _case_fail("Expected post-start traceability schema version 1.")
	if str(enrichment.get("source_system_id", "")) != SOURCE_ID:
		return _case_fail("Expected post-start traceability source id.")
	if str(enrichment.get("pass_id", "")) != PASS_ID:
		return _case_fail("Expected R2.1 enrichment pass id.")
	if str(enrichment.get("source_mapping_status", "")) != "ready_for_live_source_mapping":
		return _case_fail("Expected ready source mapping status.")
	if _string_array(enrichment.get("available_source_system_ids", [])) != _string_array(EXPECTED_SOURCE_SYSTEM_IDS):
		return _case_fail("Expected canonical available source systems.")

	var traceability: Dictionary = annual.get("traceability", {}) if typeof(annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	if not _variant_array(traceability.get("post_start_enrichment_passes", [])).has(PASS_ID):
		return _case_fail("Expected statement traceability to include R2.1 pass id.")
	if _string_array(traceability.get("post_start_available_source_system_ids", [])) != _string_array(EXPECTED_SOURCE_SYSTEM_IDS):
		return _case_fail("Expected statement traceability source system ids.")

	var notes: Array = _variant_array(annual.get("notes", []))
	if notes.size() != EXPECTED_NOTE_COUNT:
		return _case_fail("Expected %d annual generated notes, got %d." % [EXPECTED_NOTE_COUNT, notes.size()])
	for note_value in notes:
		if typeof(note_value) != TYPE_DICTIONARY:
			return _case_fail("Expected note dictionaries.")
		var note: Dictionary = note_value
		var note_enrichment: Dictionary = note.get("post_start_traceability", {}) if typeof(note.get("post_start_traceability", {})) == TYPE_DICTIONARY else {}
		if str(note_enrichment.get("pass_id", "")) != PASS_ID:
			return _case_fail("Expected generated annual note %s to include R2.1 pass id." % str(note.get("note_id", "")))
		if _string_array(note_enrichment.get("available_source_system_ids", [])) != _string_array(EXPECTED_SOURCE_SYSTEM_IDS):
			return _case_fail("Expected generated annual note %s to include source systems." % str(note.get("note_id", "")))

	var annual_statements: Array = _variant_array(snapshot.get("annual_statements", []))
	if annual_statements.is_empty():
		return _case_fail("Expected annual statements mirror array.")
	var mirror: Dictionary = annual_statements[0] if typeof(annual_statements[0]) == TYPE_DICTIONARY else {}
	var mirror_enrichment: Dictionary = mirror.get("post_start_traceability", {}) if typeof(mirror.get("post_start_traceability", {})) == TYPE_DICTIONARY else {}
	if str(mirror_enrichment.get("pass_id", "")) != PASS_ID:
		return _case_fail("Expected annual statements mirror to include R2.1 pass id.")
	return _case_ok()


func _snapshot_for_company(company_id: String) -> Dictionary:
	var runtime_value = RunState.companies.get(company_id, {})
	if typeof(runtime_value) != TYPE_DICTIONARY:
		return {}
	var profile_value = runtime_value.get("company_profile", {})
	if typeof(profile_value) != TYPE_DICTIONARY:
		return {}
	var snapshot_value = profile_value.get("financial_statement_snapshot", {})
	if typeof(snapshot_value) != TYPE_DICTIONARY:
		return {}
	return snapshot_value.duplicate(true)


func _annual_from_snapshot(snapshot: Dictionary) -> Dictionary:
	var annual_value = snapshot.get("annual_statement", {})
	if typeof(annual_value) != TYPE_DICTIONARY:
		return {}
	return annual_value.duplicate(true)


func _write_snapshot_for_company(company_id: String, snapshot: Dictionary) -> bool:
	var runtime_value = RunState.companies.get(company_id, {})
	if typeof(runtime_value) != TYPE_DICTIONARY:
		return false
	var runtime: Dictionary = runtime_value.duplicate(true)
	var profile_value = runtime.get("company_profile", {})
	if typeof(profile_value) != TYPE_DICTIONARY:
		return false
	var profile: Dictionary = profile_value.duplicate(true)
	profile["financial_statement_snapshot"] = snapshot.duplicate(true)
	runtime["company_profile"] = profile
	RunState.companies[company_id] = runtime
	return true


func _strip_snapshot_enrichment(snapshot: Dictionary) -> Dictionary:
	var stripped: Dictionary = snapshot.duplicate(true)
	var annual_value = stripped.get("annual_statement", {})
	if typeof(annual_value) == TYPE_DICTIONARY:
		stripped["annual_statement"] = _strip_annual_enrichment(annual_value)
	var annual_statements: Array = []
	for statement_value in _variant_array(stripped.get("annual_statements", [])):
		if typeof(statement_value) == TYPE_DICTIONARY:
			annual_statements.append(_strip_annual_enrichment(statement_value))
		else:
			annual_statements.append(statement_value)
	stripped["annual_statements"] = annual_statements
	return stripped


func _strip_annual_enrichment(annual_value: Dictionary) -> Dictionary:
	var annual: Dictionary = annual_value.duplicate(true)
	annual.erase("post_start_traceability")
	var traceability: Dictionary = annual.get("traceability", {}) if typeof(annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	traceability = traceability.duplicate(true)
	traceability.erase("post_start_enrichment_passes")
	traceability.erase("post_start_available_source_system_ids")
	annual["traceability"] = traceability
	var notes: Array = []
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			notes.append(note_value)
			continue
		var note: Dictionary = note_value.duplicate(true)
		note.erase("post_start_traceability")
		notes.append(note)
	annual["notes"] = notes
	return annual


func _enrichment_payload(annual: Dictionary) -> String:
	var lines: Array[String] = []
	var enrichment: Dictionary = annual.get("post_start_traceability", {}) if typeof(annual.get("post_start_traceability", {})) == TYPE_DICTIONARY else {}
	lines.append("statement:%s:%s:%s" % [
		str(enrichment.get("source_system_id", "")),
		str(enrichment.get("pass_id", "")),
		"|".join(_string_array(enrichment.get("available_source_system_ids", [])))
	])
	var ready: Dictionary = enrichment.get("source_state_ready", {}) if typeof(enrichment.get("source_state_ready", {})) == TYPE_DICTIONARY else {}
	for source_system_id in EXPECTED_SOURCE_SYSTEM_IDS:
		lines.append("ready:%s:%s" % [str(source_system_id), str(ready.get(source_system_id, false))])
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		var note_enrichment: Dictionary = note.get("post_start_traceability", {}) if typeof(note.get("post_start_traceability", {})) == TYPE_DICTIONARY else {}
		lines.append("note:%02d:%s:%s:%s" % [
			int(note.get("note_number", 0)),
			str(note.get("note_type", "")),
			str(note_enrichment.get("pass_id", "")),
			"|".join(_string_array(note_enrichment.get("available_source_system_ids", [])))
		])
	return "\n".join(lines)


func _variant_array(source_value: Variant) -> Array:
	if typeof(source_value) == TYPE_ARRAY:
		return source_value.duplicate(true)
	return []


func _string_array(source_value: Variant) -> Array:
	var result: Array = []
	for item_value in _variant_array(source_value):
		var text: String = str(item_value).strip_edges()
		if text.is_empty() or result.has(text):
			continue
		result.append(text)
	result.sort()
	return result


func _case_ok() -> Dictionary:
	return {"success": true}


func _case_fail(message: String) -> Dictionary:
	return {"success": false, "message": message}


func _fail(message: String) -> void:
	push_error(message)
	print("ANNUAL_STATEMENT_ENRICHMENT_PASS_FAIL: %s" % message)
	get_tree().quit(1)
