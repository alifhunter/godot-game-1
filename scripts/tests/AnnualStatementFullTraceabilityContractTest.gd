extends Node

const RUN_SEED := 20260618
const EXPECTED_NOTE_COUNT := 14
const EXPECTED_TRACE_HASH := "1974201801"
const CONTRACT_STORY_KEY := "customer_contract"
const CAPEX_STORY_KEY := "capex_expansion"
const DEBT_STORY_KEY := "debt_refinancing"
const LIVING_ARC_KEY := "roadmap_arc_r2_5"
const CHAIN_SUFFIX := "rights_capex_r2_5"
const ROADMAP_SUFFIX := "expansion_r2_5"
const CORPORATE_EVENT_ID := "corporate_action_filing"
const ROADMAP_EVENT_ID := "roadmap_development"

const TRACE_SOURCE_KEYS := [
	"post_start_source_story_ids",
	"post_start_source_effect_ids",
	"post_start_source_fact_ids",
	"post_start_source_clue_ids",
	"post_start_source_disclosure_packet_ids",
	"post_start_source_disclosure_placement_ids",
	"post_start_source_disclosure_section_ids",
	"post_start_source_living_arc_ids",
	"post_start_source_corporate_action_ids",
	"post_start_source_event_ids",
	"post_start_source_event_ref_ids",
	"post_start_source_roadmap_ids"
]

const NOTE_SOURCE_KEYS := [
	"source_story_ids",
	"source_effect_ids",
	"effect_ids",
	"fact_ids",
	"clue_ids",
	"source_disclosure_packet_ids",
	"source_disclosure_placement_ids",
	"source_disclosure_section_ids",
	"source_living_arc_ids",
	"source_corporate_action_ids",
	"source_event_ids",
	"source_event_ref_ids",
	"source_roadmap_ids",
	"story_source_refs",
	"disclosure_packet_refs",
	"living_arc_refs",
	"corporate_action_refs",
	"event_refs",
	"roadmap_refs",
	"story_id",
	"effect_id",
	"fact_id",
	"clue_id"
]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var result: Dictionary = _run_case()
	if not bool(result.get("success", false)):
		_fail(str(result.get("message", "annual statement full traceability contract failed")))
		return

	print("ANNUAL_STATEMENT_FULL_TRACEABILITY_CONTRACT_OK %s" % JSON.stringify(result.get("summary", {})))
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
	var story_ids: Dictionary = {
		CONTRACT_STORY_KEY: "story|%s|%s|r2_5" % [company_id, CONTRACT_STORY_KEY],
		CAPEX_STORY_KEY: "story|%s|%s|r2_5" % [company_id, CAPEX_STORY_KEY],
		DEBT_STORY_KEY: "story|%s|%s|r2_5" % [company_id, DEBT_STORY_KEY]
	}
	var living_arc_id: String = "arc|%s|%s" % [company_id, LIVING_ARC_KEY]
	var chain_id: String = "chain|%s|%s" % [company_id, CHAIN_SUFFIX]
	var roadmap_id: String = "roadmap|%s|%s" % [company_id, ROADMAP_SUFFIX]

	_seed_story_source_state(company_id, ticker, story_ids)
	_seed_living_arc_state(company_id, living_arc_id)
	_seed_action_event_roadmap_state(company_id, ticker, company_name, chain_id, roadmap_id)

	if not RunState.ensure_company_full_detail(company_id):
		return _case_fail("Could not hydrate full detail for %s." % company_id)
	RunState.refresh_annual_statement_post_start_enrichment(company_id)

	var annual: Dictionary = _annual_for_company(company_id)
	if annual.is_empty():
		return _case_fail("Expected annual statement after hydration.")

	var contract_result: Dictionary = _assert_full_traceability_contract(annual, story_ids, living_arc_id, chain_id, roadmap_id)
	if not bool(contract_result.get("success", false)):
		return contract_result

	var mirror_result: Dictionary = _assert_mirror_preserved(company_id, annual)
	if not bool(mirror_result.get("success", false)):
		return mirror_result

	var first_payload: String = _traceability_payload(annual)
	var trace_hash: String = _stable_hash(first_payload)
	if EXPECTED_TRACE_HASH != "BASELINE_PENDING" and trace_hash != EXPECTED_TRACE_HASH:
		return _case_fail("Expected traceability hash %s, got %s." % [EXPECTED_TRACE_HASH, trace_hash])

	RunState.refresh_annual_statement_post_start_enrichment(company_id)
	RunState.refresh_annual_statement_post_start_enrichment(company_id)
	var refreshed_payload: String = _traceability_payload(_annual_for_company(company_id))
	if first_payload != refreshed_payload:
		return _case_fail("Full traceability payload changed after repeated refreshes.")

	var save_payload: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(save_payload)
	var loaded_annual: Dictionary = _annual_for_company(company_id)
	if first_payload != _traceability_payload(loaded_annual):
		return _case_fail("Full traceability payload changed after save/load. %s" % _payload_diff_summary(first_payload, _traceability_payload(loaded_annual)))

	var stripped_snapshot: Dictionary = _strip_snapshot_source_fields(_snapshot_for_company(company_id))
	if not _write_snapshot_for_company(company_id, stripped_snapshot):
		return _case_fail("Could not write stripped legacy-style annual statement snapshot.")
	var stripped_annual: Dictionary = _annual_for_company(company_id)
	if not _source_fields_empty(stripped_annual):
		return _case_fail("Legacy-style stripped annual statement still had enriched source fields.")

	var stripped_save: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(stripped_save)
	RunState.refresh_annual_statement_post_start_enrichment(company_id)
	var repaired_annual: Dictionary = _annual_for_company(company_id)
	var repaired_result: Dictionary = _assert_full_traceability_contract(repaired_annual, story_ids, living_arc_id, chain_id, roadmap_id)
	if not bool(repaired_result.get("success", false)):
		return repaired_result
	if first_payload != _traceability_payload(repaired_annual):
		return _case_fail("Legacy-style annual statement repair did not restore the expected traceability payload. %s" % _payload_diff_summary(first_payload, _traceability_payload(repaired_annual)))

	return {
		"success": true,
		"summary": {
			"company_id": company_id,
			"hash": trace_hash,
			"note_count": _variant_array(annual.get("notes", [])).size(),
			"story_count": story_ids.size(),
			"chain_id": chain_id,
			"roadmap_id": roadmap_id
		}
	}


func _seed_story_source_state(company_id: String, ticker: String, story_ids: Dictionary) -> void:
	var contract_story_id: String = str(story_ids.get(CONTRACT_STORY_KEY, ""))
	var capex_story_id: String = str(story_ids.get(CAPEX_STORY_KEY, ""))
	var debt_story_id: String = str(story_ids.get(DEBT_STORY_KEY, ""))
	var dossiers: Dictionary = {
		contract_story_id: _build_dossier(
			company_id,
			ticker,
			contract_story_id,
			"customer_contract",
			"customer_contract",
			["revenue", "backlog", "customer_concentration"]
		),
		capex_story_id: _build_dossier(
			company_id,
			ticker,
			capex_story_id,
			"capex_expansion",
			"capex_progress",
			["capex", "property_plant_equipment", "purchase_of_ppe"]
		),
		debt_story_id: _build_dossier(
			company_id,
			ticker,
			debt_story_id,
			"balance_sheet_stress",
			"debt_maturity",
			["debt", "short_term_borrowings", "long_term_borrowings"]
		)
	}
	var active_story_ids: Array = [contract_story_id, capex_story_id, debt_story_id]
	RunState.set_company_story_dossier_state({
		"schema_version": 1,
		"generated": true,
		"run_seed": RUN_SEED,
		"generated_day_index": RunState.day_index,
		"dossier_index": dossiers,
		"company_story_ids": {company_id: active_story_ids},
		"active_story_ids": active_story_ids,
		"resolved_story_ids": [],
		"recent_resolved_stories": [],
		"story_counts_by_archetype": {},
		"story_counts_by_truth": {}
	})


func _build_dossier(
	company_id: String,
	ticker: String,
	story_id: String,
	archetype_id: String,
	note_type: String,
	metric_ids: Array
) -> Dictionary:
	var fact_id: String = "fact|%s|primary" % story_id
	var effect_rows: Array = []
	var clue_rows: Array = []
	var effect_ids: Array = []
	var clue_ids: Array = []
	for metric_id_value in metric_ids:
		var metric_id: String = str(metric_id_value)
		var effect_id: String = "effect|%s|%s" % [story_id, metric_id]
		var clue_id: String = "clue|%s|%s" % [story_id, metric_id]
		effect_ids.append(effect_id)
		clue_ids.append(clue_id)
		effect_rows.append({
			"effect_id": effect_id,
			"metric_id": metric_id,
			"statement_section": "annual_notes",
			"direction": "positive",
			"magnitude_band": "medium",
			"timing": "current_year",
			"persistence": "multi_period",
			"confidence": 0.8,
			"truth_states": ["real"],
			"note_type": note_type,
			"explain_tags": [archetype_id, note_type]
		})
		clue_rows.append({
			"clue_id": clue_id,
			"surface_id": "annual_statement_note",
			"visibility": "filing",
			"earliest_day_index": 0,
			"latest_day_index": 225,
			"reliability": 0.8,
			"text_key": "r2_5_%s_%s" % [archetype_id, metric_id],
			"note_type": note_type,
			"metric_ids": [metric_id],
			"fact_ids": [fact_id]
		})
	return {
		"schema_version": 1,
		"story_id": story_id,
		"company_id": company_id,
		"ticker": ticker,
		"archetype_id": archetype_id,
		"story_family": "r2_5_statement_source",
		"hook_id": archetype_id,
		"truth_state": "real",
		"public_status": "reported",
		"stage_id": "filing_hint",
		"priority": 0.8,
		"confidence": 0.8,
		"started_day_index": 0,
		"expected_resolution_day_index": 90,
		"resolved_day_index": -1,
		"outcome_state": "",
		"cause_facts": [{
			"fact_id": fact_id,
			"fact_type": archetype_id,
			"source_id": "r2_5_test",
			"direction": "positive",
			"strength": 0.8,
			"confidence": 0.8,
			"related_company_ids": [company_id],
			"tags": [archetype_id, note_type]
		}],
		"timeline": [],
		"financial_effects": effect_rows,
		"price_effects": {},
		"public_clues": [],
		"private_clues": [],
		"statement_clues": clue_rows,
		"thesis_hooks": [],
		"resolution_conditions": [],
		"traceability": {
			"seed_parts": ["r2_5", company_id, archetype_id],
			"source_company_hook_ids": [archetype_id],
			"source_fact_ids": [fact_id],
			"generated_surface_ids": [],
			"evidence_ids": clue_ids,
			"price_effect_ids": [],
			"statement_effect_ids": effect_ids
		}
	}


func _seed_living_arc_state(company_id: String, living_arc_id: String) -> void:
	var active_arc: Dictionary = {
		"arc_id": living_arc_id,
		"target_company_id": company_id,
		"company_id": company_id,
		"source_system": "company_roadmap",
		"event_family": "company_roadmap",
		"category": "roadmap_project",
		"event_id": "roadmap_expansion_funding",
		"tone": "positive",
		"start_day_index": 3,
		"end_day_index": 100,
		"current_phase_id": "execution_window",
		"current_phase_label": "Execution window",
		"story_tags": ["roadmap_physical_project", "capex_expansion", "funding_need", "customer_contract_follow_through"]
	}
	RunState.active_company_arcs = [active_arc]
	RunState.sync_living_company_arcs_for_day(RunState.day_index, RunState.active_company_arcs, false)


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
			"meeting_id": "meeting|%s|r2_5" % company_id,
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
			"meeting_id": "meeting|%s|r2_5" % company_id,
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


func _assert_full_traceability_contract(
	annual: Dictionary,
	story_ids: Dictionary,
	living_arc_id: String,
	chain_id: String,
	roadmap_id: String
) -> Dictionary:
	if _variant_array(annual.get("notes", [])).size() != EXPECTED_NOTE_COUNT:
		return _case_fail("Expected %d annual notes." % EXPECTED_NOTE_COUNT)

	var contract_story_id: String = str(story_ids.get(CONTRACT_STORY_KEY, ""))
	var capex_story_id: String = str(story_ids.get(CAPEX_STORY_KEY, ""))
	var debt_story_id: String = str(story_ids.get(DEBT_STORY_KEY, ""))

	var traceability: Dictionary = annual.get("traceability", {}) if typeof(annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	for story_id_value in story_ids.values():
		var story_id: String = str(story_id_value)
		if not _string_array(traceability.get("post_start_source_story_ids", [])).has(story_id):
			return _case_fail("Expected statement traceability to include story %s." % story_id)
	if not _string_array(traceability.get("post_start_source_living_arc_ids", [])).has(living_arc_id):
		return _case_fail("Expected statement traceability to include living arc %s." % living_arc_id)
	if not _string_array(traceability.get("post_start_source_corporate_action_ids", [])).has(chain_id):
		return _case_fail("Expected statement traceability to include corporate action %s." % chain_id)
	if not _string_array(traceability.get("post_start_source_event_ids", [])).has(CORPORATE_EVENT_ID):
		return _case_fail("Expected statement traceability to include corporate action event.")
	if not _string_array(traceability.get("post_start_source_event_ids", [])).has(ROADMAP_EVENT_ID):
		return _case_fail("Expected statement traceability to include roadmap event.")
	if _string_array(traceability.get("post_start_source_event_ref_ids", [])).is_empty():
		return _case_fail("Expected statement traceability to include generated event ref ids.")
	if not _string_array(traceability.get("post_start_source_roadmap_ids", [])).has(roadmap_id):
		return _case_fail("Expected statement traceability to include roadmap %s." % roadmap_id)

	for story_id_value in story_ids.values():
		var effect_prefix: String = "effect|%s|" % str(story_id_value)
		if not _array_has_prefix(_string_array(traceability.get("post_start_source_effect_ids", [])), effect_prefix):
			return _case_fail("Expected statement traceability to include effects for %s." % str(story_id_value))
		var clue_prefix: String = "clue|%s|" % str(story_id_value)
		if not _array_has_prefix(_string_array(traceability.get("post_start_source_clue_ids", [])), clue_prefix):
			return _case_fail("Expected statement traceability to include clues for %s." % str(story_id_value))
		var fact_id: String = "fact|%s|primary" % str(story_id_value)
		if not _string_array(traceability.get("post_start_source_fact_ids", [])).has(fact_id):
			return _case_fail("Expected statement traceability to include fact %s." % fact_id)
		var packet_prefix: String = "packet|%s|" % str(story_id_value)
		if not _array_has_prefix(_string_array(traceability.get("post_start_source_disclosure_packet_ids", [])), packet_prefix):
			return _case_fail("Expected statement traceability to include disclosure packets for %s." % str(story_id_value))
		var placement_prefix: String = "placement|%s|" % str(story_id_value)
		if not _array_has_prefix(_string_array(traceability.get("post_start_source_disclosure_placement_ids", [])), placement_prefix):
			return _case_fail("Expected statement traceability to include disclosure placements for %s." % str(story_id_value))
	if _string_array(traceability.get("post_start_source_disclosure_section_ids", [])).is_empty():
		return _case_fail("Expected statement traceability to include disclosure section ids.")

	var checks: Array = [
		["revenue", "source_story_ids", contract_story_id],
		["revenue", "story_source_refs", contract_story_id],
		["property_plant_and_equipment", "source_story_ids", capex_story_id],
		["property_plant_and_equipment", "source_living_arc_ids", living_arc_id],
		["property_plant_and_equipment", "source_roadmap_ids", roadmap_id],
		["property_plant_and_equipment", "source_event_ids", ROADMAP_EVENT_ID],
		["debt_and_borrowings", "source_story_ids", debt_story_id],
		["debt_and_borrowings", "source_living_arc_ids", living_arc_id],
		["debt_and_borrowings", "source_corporate_action_ids", chain_id],
		["cash_flow_information", "source_corporate_action_ids", chain_id],
		["cash_flow_information", "source_roadmap_ids", roadmap_id],
		["segment_information", "source_story_ids", contract_story_id],
		["segment_information", "source_roadmap_ids", roadmap_id],
		["commitments_contingencies_and_subsequent_events", "source_story_ids", contract_story_id],
		["commitments_contingencies_and_subsequent_events", "source_story_ids", capex_story_id],
		["commitments_contingencies_and_subsequent_events", "source_story_ids", debt_story_id],
		["commitments_contingencies_and_subsequent_events", "source_living_arc_ids", living_arc_id],
		["commitments_contingencies_and_subsequent_events", "source_corporate_action_ids", chain_id],
		["commitments_contingencies_and_subsequent_events", "source_event_ids", CORPORATE_EVENT_ID],
		["commitments_contingencies_and_subsequent_events", "source_event_ids", ROADMAP_EVENT_ID],
		["commitments_contingencies_and_subsequent_events", "source_roadmap_ids", roadmap_id]
	]
	for check_value in checks:
		var check: Array = check_value
		var note_type: String = str(check[0])
		var field: String = str(check[1])
		var expected_id: String = str(check[2])
		var note: Dictionary = _note_by_type(annual, note_type)
		if note.is_empty():
			return _case_fail("Missing annual note type %s." % note_type)
		if field == "story_source_refs":
			if not _ref_array_has_id(note.get(field, []), "story_id", expected_id):
				return _case_fail("Expected %s to include story ref %s." % [note_type, expected_id])
		elif not _string_array(note.get(field, [])).has(expected_id):
			return _case_fail("Expected %s.%s to include %s. actual=%s" % [
				note_type,
				field,
				expected_id,
				JSON.stringify(_string_array(note.get(field, [])))
			])
		if note_type != "basis_of_preparation" and field != "story_source_refs":
			if field.begins_with("source_") and _variant_array(note.get(_ref_field_for_source_field(field), [])).is_empty():
				return _case_fail("Expected %s to include refs for %s." % [note_type, field])
		if not _string_array(note.get("source_story_ids", [])).is_empty():
			if _string_array(note.get("source_disclosure_packet_ids", [])).is_empty():
				return _case_fail("Expected %s to include disclosure packet ids." % note_type)
			if _variant_array(note.get("disclosure_packet_refs", [])).is_empty():
				return _case_fail("Expected %s to include disclosure packet refs." % note_type)

	var basis_note: Dictionary = _note_by_type(annual, "basis_of_preparation")
	if basis_note.is_empty():
		return _case_fail("Missing basis of preparation note.")
	for field_value in ["source_story_ids", "source_disclosure_packet_ids", "source_disclosure_placement_ids", "source_disclosure_section_ids", "source_living_arc_ids", "source_corporate_action_ids", "source_event_ids", "source_event_ref_ids", "source_roadmap_ids"]:
		var field_name: String = str(field_value)
		if not _string_array(basis_note.get(field_name, [])).is_empty():
			return _case_fail("Basis note should not receive %s." % field_name)
	for ref_field_value in ["story_source_refs", "disclosure_packet_refs", "living_arc_refs", "corporate_action_refs", "event_refs", "roadmap_refs"]:
		var ref_field_name: String = str(ref_field_value)
		if not _variant_array(basis_note.get(ref_field_name, [])).is_empty():
			return _case_fail("Basis note should not receive %s." % ref_field_name)

	return _case_ok()


func _assert_mirror_preserved(company_id: String, annual: Dictionary) -> Dictionary:
	var snapshot: Dictionary = _snapshot_for_company(company_id)
	var annual_statements: Array = _variant_array(snapshot.get("annual_statements", []))
	if annual_statements.is_empty():
		return _case_fail("Expected annual statements mirror array.")
	var mirror: Dictionary = annual_statements[0] if typeof(annual_statements[0]) == TYPE_DICTIONARY else {}
	if mirror.is_empty():
		return _case_fail("Expected annual statements mirror dictionary.")
	if _traceability_payload(mirror) != _traceability_payload(annual):
		return _case_fail("Expected annual statements mirror to preserve enriched traceability.")
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


func _annual_for_company(company_id: String) -> Dictionary:
	return _annual_from_snapshot(_snapshot_for_company(company_id))


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


func _strip_snapshot_source_fields(snapshot: Dictionary) -> Dictionary:
	var stripped: Dictionary = snapshot.duplicate(true)
	var annual_value = stripped.get("annual_statement", {})
	if typeof(annual_value) == TYPE_DICTIONARY:
		stripped["annual_statement"] = _strip_annual_source_fields(annual_value)
	var annual_statements: Array = []
	for statement_value in _variant_array(stripped.get("annual_statements", [])):
		if typeof(statement_value) == TYPE_DICTIONARY:
			annual_statements.append(_strip_annual_source_fields(statement_value))
		else:
			annual_statements.append(statement_value)
	stripped["annual_statements"] = annual_statements
	return stripped


func _strip_annual_source_fields(annual_value: Dictionary) -> Dictionary:
	var annual: Dictionary = annual_value.duplicate(true)
	annual.erase("post_start_traceability")
	var traceability: Dictionary = annual.get("traceability", {}) if typeof(annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	traceability = traceability.duplicate(true)
	traceability.erase("post_start_enrichment_passes")
	traceability.erase("post_start_available_source_system_ids")
	for key_value in TRACE_SOURCE_KEYS:
		traceability.erase(str(key_value))
	annual["traceability"] = traceability
	var notes: Array = []
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			notes.append(note_value)
			continue
		var note: Dictionary = note_value.duplicate(true)
		note.erase("post_start_traceability")
		for key_value in NOTE_SOURCE_KEYS:
			note.erase(str(key_value))
		notes.append(note)
	annual["notes"] = notes
	return annual


func _source_fields_empty(annual: Dictionary) -> bool:
	var traceability: Dictionary = annual.get("traceability", {}) if typeof(annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	for key_value in TRACE_SOURCE_KEYS:
		if not _string_array(traceability.get(str(key_value), [])).is_empty():
			return false
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		for key_value in NOTE_SOURCE_KEYS:
			var key: String = str(key_value)
			if key.ends_with("_refs"):
				if not _variant_array(note.get(key, [])).is_empty():
					return false
			elif note.has(key):
				var value = note.get(key)
				if typeof(value) == TYPE_ARRAY and not _string_array(value).is_empty():
					return false
				if typeof(value) == TYPE_STRING and not str(value).strip_edges().is_empty():
					return false
	return true


func _note_by_type(annual: Dictionary, note_type: String) -> Dictionary:
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		if str(note.get("note_type", "")) == note_type:
			return note.duplicate(true)
	return {}


func _traceability_payload(annual: Dictionary) -> String:
	var lines: Array[String] = []
	var traceability: Dictionary = annual.get("traceability", {}) if typeof(annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	for key_value in TRACE_SOURCE_KEYS:
		var key: String = str(key_value)
		lines.append("trace:%s:%s" % [key, "|".join(_string_array(traceability.get(key, [])))])
	var notes: Array = _variant_array(annual.get("notes", []))
	notes.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("note_number", 0)) < int(right.get("note_number", 0))
	)
	for note_value in notes:
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		var note_id: String = str(note.get("note_id", ""))
		lines.append("note:%02d:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [
			int(note.get("note_number", 0)),
			note_id,
			str(note.get("note_type", "")),
			"|".join(_string_array(note.get("source_story_ids", []))),
			"|".join(_string_array(note.get("source_effect_ids", []))),
			"|".join(_string_array(note.get("fact_ids", []))),
			"|".join(_string_array(note.get("clue_ids", []))),
			"|".join(_string_array(note.get("source_disclosure_packet_ids", []))),
			"|".join(_string_array(note.get("source_disclosure_placement_ids", []))),
			"|".join(_string_array(note.get("source_disclosure_section_ids", []))),
			"|".join(_string_array(note.get("source_living_arc_ids", []))),
			"|".join(_string_array(note.get("source_corporate_action_ids", []))),
			"|".join(_string_array(note.get("source_event_ids", []))),
			"|".join(_string_array(note.get("source_event_ref_ids", []))),
			"|".join(_string_array(note.get("source_roadmap_ids", [])))
		])
		lines.append_array(_ref_payload_lines("story_ref", note_id, note.get("story_source_refs", []), ["story_id", "note_type", "metric_ids", "fact_ids", "effect_ids", "clue_ids", "source_disclosure_packet_ids"]))
		lines.append_array(_ref_payload_lines("disclosure_packet_ref", note_id, note.get("disclosure_packet_refs", []), ["packet_id", "placement_id", "section_id", "annual_statement_note_type", "subtlety", "packet_role", "render_priority"]))
		lines.append_array(_ref_payload_lines("living_arc_ref", note_id, note.get("living_arc_refs", []), ["arc_id", "source_status", "source_system", "arc_type", "phase_id", "story_tags"]))
		lines.append_array(_ref_payload_lines("corporate_action_ref", note_id, note.get("corporate_action_refs", []), ["action_id", "source_status", "family", "category", "stage", "roadmap_id", "funding_purpose", "day_index"]))
		lines.append_array(_ref_payload_lines("event_ref", note_id, note.get("event_refs", []), ["event_ref_id", "event_id", "event_family", "category", "source_chain_id", "roadmap_id", "day_index"]))
		lines.append_array(_ref_payload_lines("roadmap_ref", note_id, note.get("roadmap_refs", []), ["roadmap_id", "source_status", "participant_role", "family_id", "funding_outcome", "corporate_chain_id", "physical_project"]))
	lines.sort()
	return "\n".join(lines)


func _ref_payload_lines(prefix: String, note_id: String, source_value: Variant, keys: Array) -> Array[String]:
	var lines: Array[String] = []
	for row_value in _variant_array(source_value):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var parts: Array[String] = [prefix, note_id]
		for key_value in keys:
			var key: String = str(key_value)
			var value = row.get(key, "")
			if typeof(value) == TYPE_ARRAY:
				parts.append("|".join(_string_array(value)))
			elif typeof(value) == TYPE_BOOL:
				parts.append("true" if bool(value) else "false")
			else:
				parts.append(str(value))
		lines.append(":".join(parts))
	lines.sort()
	return lines


func _ref_field_for_source_field(field: String) -> String:
	match field:
		"source_story_ids":
			return "story_source_refs"
		"source_disclosure_packet_ids", "source_disclosure_placement_ids", "source_disclosure_section_ids":
			return "disclosure_packet_refs"
		"source_living_arc_ids":
			return "living_arc_refs"
		"source_corporate_action_ids":
			return "corporate_action_refs"
		"source_event_ids", "source_event_ref_ids":
			return "event_refs"
		"source_roadmap_ids":
			return "roadmap_refs"
		_:
			return ""


func _array_has_prefix(rows: Array, prefix: String) -> bool:
	for row_value in rows:
		if str(row_value).begins_with(prefix):
			return true
	return false


func _ref_array_has_id(source_value: Variant, id_key: String, expected_id: String) -> bool:
	for row_value in _variant_array(source_value):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get(id_key, "")) == expected_id:
			return true
	return false


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


func _stable_hash(text: String) -> String:
	var hash: int = 5381
	for index in range(text.length()):
		hash = int(((hash << 5) + hash + text.unicode_at(index)) & 0x7fffffff)
	return str(hash)


func _payload_diff_summary(left: String, right: String) -> String:
	var left_lines: PackedStringArray = left.split("\n", false)
	var right_lines: PackedStringArray = right.split("\n", false)
	var max_count: int = max(left_lines.size(), right_lines.size())
	for index in range(max_count):
		var left_line: String = left_lines[index] if index < left_lines.size() else "<missing>"
		var right_line: String = right_lines[index] if index < right_lines.size() else "<missing>"
		if left_line != right_line:
			return "first_diff=%d before=%s after=%s before_hash=%s after_hash=%s" % [
				index,
				left_line,
				right_line,
				_stable_hash(left),
				_stable_hash(right)
			]
	return "before_hash=%s after_hash=%s" % [_stable_hash(left), _stable_hash(right)]


func _case_ok() -> Dictionary:
	return {"success": true}


func _case_fail(message: String) -> Dictionary:
	return {"success": false, "message": message}


func _fail(message: String) -> void:
	push_error(message)
	print("ANNUAL_STATEMENT_FULL_TRACEABILITY_CONTRACT_FAIL: %s" % message)
	get_tree().quit(1)
