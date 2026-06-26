extends Node

const RUN_SEED := 20260618
const CHAIN_SUFFIX := "rights_capex_r2_3"
const ROADMAP_SUFFIX := "expansion_r2_3"
const CORPORATE_EVENT_ID := "corporate_action_filing"
const ROADMAP_EVENT_ID := "roadmap_development"


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var result: Dictionary = _run_case()
	if not bool(result.get("success", false)):
		_fail(str(result.get("message", "annual statement action/event/roadmap enrichment failed")))
		return

	print("ANNUAL_STATEMENT_ACTION_EVENT_ROADMAP_ENRICHMENT_OK %s" % JSON.stringify(result.get("summary", {})))
	get_tree().quit(0)


func _run_case() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	if RunState.company_order.is_empty():
		return _case_fail("Expected generated company order.")

	var company_id: String = str(RunState.company_order[0])
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	var ticker: String = str(definition.get("ticker", company_id.to_upper()))
	var company_name: String = str(definition.get("name", ticker))
	var chain_id: String = "chain|%s|%s" % [company_id, CHAIN_SUFFIX]
	var roadmap_id: String = "roadmap|%s|%s" % [company_id, ROADMAP_SUFFIX]

	_seed_action_event_roadmap_state(company_id, ticker, company_name, chain_id, roadmap_id)

	if not RunState.ensure_company_full_detail(company_id):
		return _case_fail("Could not hydrate full detail for %s." % company_id)
	RunState.refresh_annual_statement_post_start_enrichment(company_id)

	var annual: Dictionary = _annual_for_company(company_id)
	if annual.is_empty():
		return _case_fail("Expected annual statement after hydration.")

	var assertions: Dictionary = _assert_sources(annual, chain_id, roadmap_id)
	if not bool(assertions.get("success", false)):
		return assertions

	var first_payload: String = _source_payload(annual)
	RunState.refresh_annual_statement_post_start_enrichment(company_id)
	RunState.refresh_annual_statement_post_start_enrichment(company_id)
	var refreshed_payload: String = _source_payload(_annual_for_company(company_id))
	if first_payload != refreshed_payload:
		return _case_fail("Annual action/event/roadmap enrichment changed after repeated refreshes.")

	return {
		"success": true,
		"summary": {
			"company_id": company_id,
			"chain_id": chain_id,
			"roadmap_id": roadmap_id,
			"note_count": _variant_array(annual.get("notes", [])).size()
		}
	}


func _seed_action_event_roadmap_state(company_id: String, ticker: String, company_name: String, chain_id: String, roadmap_id: String) -> void:
	RunState.set_active_corporate_action_chains({
		chain_id: {
			"chain_id": chain_id,
			"company_id": company_id,
			"target_company_id": company_id,
			"target_ticker": ticker,
			"target_company_name": company_name,
			"family": "rights_issue",
			"family_id": "rights_issue",
			"family_label": "Rights Issue",
			"category": "corporate_action_filing",
			"stage": "formal_agenda_or_filing",
			"status": "active",
			"request_source": "company_roadmap",
			"roadmap_id": roadmap_id,
			"meeting_id": "meeting|%s|r2_3" % company_id,
			"created_day_index": 5,
			"rights_terms": {
				"funding_purpose": "expansion_capex",
				"use_of_proceeds": "roadmap_project"
			}
		}
	})
	RunState.event_history = [
		{
			"event_id": CORPORATE_EVENT_ID,
			"event_family": "corporate_action",
			"scope": "company",
			"category": "corporate_action_filing",
			"tone": "positive",
			"company_id": company_id,
			"target_company_id": company_id,
			"target_ticker": ticker,
			"target_company_name": company_name,
			"source_chain_id": chain_id,
			"chain_family": "rights_issue",
			"meeting_id": "meeting|%s|r2_3" % company_id,
			"day_index": 6
		},
		{
			"event_id": ROADMAP_EVENT_ID,
			"event_family": "company_roadmap",
			"scope": "company",
			"category": "roadmap_development",
			"tone": "positive",
			"company_id": company_id,
			"target_company_id": company_id,
			"target_ticker": ticker,
			"target_company_name": company_name,
			"arc_id": roadmap_id,
			"day_index": 7
		}
	]
	RunState.set_company_roadmap_state({
		"active_milestones": {
			roadmap_id: {
				"id": roadmap_id,
				"company_id": company_id,
				"ticker": ticker,
				"company_name": company_name,
				"sector_id": str(RunState.get_effective_company_definition(company_id, false, false).get("sector_id", "")),
				"family_id": "capex_expansion",
				"family_label": "Capacity Expansion",
				"priority_label": "Capacity expansion",
				"project_label": "new processing capacity project",
				"funding_scale": "large",
				"funding_outcome": "needs_corporate_action",
				"corporate_chain_id": chain_id,
				"physical_project": true,
				"location_id": "jakarta",
				"location_label": "Jakarta",
				"property_theme": "processing_facility",
				"project_cost": 125000.0,
				"funding_capacity": 48000.0,
				"start_day_index": 5,
				"end_day_index": 30,
				"duration_days": 26,
				"tone": "positive",
				"sentiment_shift": 0.035,
				"volatility_multiplier": 1.2,
				"headline": "%s starts capacity expansion plan" % ticker,
				"summary": "%s requires external funding for a physical expansion project." % company_name
			}
		},
		"resolved_milestones": {},
		"company_cooldowns": {company_id: 30},
		"last_spawn_day_index": 5
	})


func _assert_sources(annual: Dictionary, chain_id: String, roadmap_id: String) -> Dictionary:
	for note_type in ["equity_and_dividends", "debt_and_borrowings", "cash_flow_information", "commitments_contingencies_and_subsequent_events"]:
		var note: Dictionary = _note_by_type(annual, note_type)
		if note.is_empty():
			return _case_fail("Missing annual note type %s." % note_type)
		if not _string_array(note.get("source_corporate_action_ids", [])).has(chain_id):
			return _case_fail("Expected corporate action id on %s. actual=%s" % [
				note_type,
				JSON.stringify(_string_array(note.get("source_corporate_action_ids", [])))
			])
		if _variant_array(note.get("corporate_action_refs", [])).is_empty():
			return _case_fail("Expected corporate action refs on %s." % note_type)

	for note_type in ["property_plant_and_equipment", "segment_information", "cash_flow_information", "commitments_contingencies_and_subsequent_events"]:
		var note: Dictionary = _note_by_type(annual, note_type)
		if note.is_empty():
			return _case_fail("Missing annual note type %s." % note_type)
		if not _string_array(note.get("source_roadmap_ids", [])).has(roadmap_id):
			return _case_fail("Expected roadmap id on %s. actual=%s" % [
				note_type,
				JSON.stringify(_string_array(note.get("source_roadmap_ids", [])))
			])
		if _variant_array(note.get("roadmap_refs", [])).is_empty():
			return _case_fail("Expected roadmap refs on %s." % note_type)

	for event_check in [
		["equity_and_dividends", CORPORATE_EVENT_ID],
		["property_plant_and_equipment", ROADMAP_EVENT_ID],
		["segment_information", ROADMAP_EVENT_ID],
		["commitments_contingencies_and_subsequent_events", CORPORATE_EVENT_ID],
		["commitments_contingencies_and_subsequent_events", ROADMAP_EVENT_ID]
	]:
		var note: Dictionary = _note_by_type(annual, str(event_check[0]))
		if note.is_empty():
			return _case_fail("Missing annual note type %s for event check." % str(event_check[0]))
		if not _string_array(note.get("source_event_ids", [])).has(str(event_check[1])):
			return _case_fail("Expected event id %s on %s. actual=%s" % [
				str(event_check[1]),
				str(event_check[0]),
				JSON.stringify(_string_array(note.get("source_event_ids", [])))
			])
		if _variant_array(note.get("event_refs", [])).is_empty():
			return _case_fail("Expected event refs on %s." % str(event_check[0]))

	var basis_note: Dictionary = _note_by_type(annual, "basis_of_preparation")
	if basis_note.is_empty():
		return _case_fail("Missing basis of preparation note.")
	if not _string_array(basis_note.get("source_corporate_action_ids", [])).is_empty():
		return _case_fail("Basis note should not receive corporate action sources.")
	if not _string_array(basis_note.get("source_event_ids", [])).is_empty():
		return _case_fail("Basis note should not receive event sources.")
	if not _string_array(basis_note.get("source_roadmap_ids", [])).is_empty():
		return _case_fail("Basis note should not receive roadmap sources.")

	var traceability: Dictionary = annual.get("traceability", {}) if typeof(annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	if not _string_array(traceability.get("post_start_source_corporate_action_ids", [])).has(chain_id):
		return _case_fail("Expected statement traceability to include corporate action %s." % chain_id)
	if not _string_array(traceability.get("post_start_source_event_ids", [])).has(CORPORATE_EVENT_ID):
		return _case_fail("Expected statement traceability to include corporate event id.")
	if not _string_array(traceability.get("post_start_source_event_ids", [])).has(ROADMAP_EVENT_ID):
		return _case_fail("Expected statement traceability to include roadmap event id.")
	if _string_array(traceability.get("post_start_source_event_ref_ids", [])).is_empty():
		return _case_fail("Expected statement traceability to include event ref ids.")
	if not _string_array(traceability.get("post_start_source_roadmap_ids", [])).has(roadmap_id):
		return _case_fail("Expected statement traceability to include roadmap %s." % roadmap_id)
	return _case_ok()


func _annual_for_company(company_id: String) -> Dictionary:
	var runtime_value = RunState.companies.get(company_id, {})
	if typeof(runtime_value) != TYPE_DICTIONARY:
		return {}
	var profile_value = runtime_value.get("company_profile", {})
	if typeof(profile_value) != TYPE_DICTIONARY:
		return {}
	var snapshot_value = profile_value.get("financial_statement_snapshot", {})
	if typeof(snapshot_value) != TYPE_DICTIONARY:
		return {}
	var annual_value = snapshot_value.get("annual_statement", {})
	if typeof(annual_value) != TYPE_DICTIONARY:
		return {}
	return annual_value.duplicate(true)


func _note_by_type(annual: Dictionary, note_type: String) -> Dictionary:
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		if str(note.get("note_type", "")) == note_type:
			return note.duplicate(true)
	return {}


func _source_payload(annual: Dictionary) -> String:
	var lines: Array[String] = []
	var traceability: Dictionary = annual.get("traceability", {}) if typeof(annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	lines.append("actions:%s" % "|".join(_string_array(traceability.get("post_start_source_corporate_action_ids", []))))
	lines.append("events:%s" % "|".join(_string_array(traceability.get("post_start_source_event_ids", []))))
	lines.append("event_refs:%s" % "|".join(_string_array(traceability.get("post_start_source_event_ref_ids", []))))
	lines.append("roadmaps:%s" % "|".join(_string_array(traceability.get("post_start_source_roadmap_ids", []))))
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		lines.append("note:%s:%s:%s:%s:%s" % [
			str(note.get("note_type", "")),
			"|".join(_string_array(note.get("source_corporate_action_ids", []))),
			"|".join(_string_array(note.get("source_event_ids", []))),
			"|".join(_string_array(note.get("source_event_ref_ids", []))),
			"|".join(_string_array(note.get("source_roadmap_ids", [])))
		])
	lines.sort()
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
	print("ANNUAL_STATEMENT_ACTION_EVENT_ROADMAP_ENRICHMENT_FAIL: %s" % message)
	get_tree().quit(1)
