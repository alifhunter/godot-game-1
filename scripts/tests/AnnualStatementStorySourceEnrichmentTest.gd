extends Node

const RUN_SEED := 20260617
const CONTRACT_STORY_KEY := "customer_contract"
const CAPEX_STORY_KEY := "capex_expansion"
const DEBT_STORY_KEY := "debt_refinancing"
const LIVING_ARC_KEY := "roadmap_arc"
const HIDDEN_PACKET_KEYS := ["truth_state", "disclosure_quality", "reliability", "confidence", "source_quality"]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var result: Dictionary = _run_case()
	if not bool(result.get("success", false)):
		_fail(str(result.get("message", "annual statement story-source enrichment failed")))
		return

	print("ANNUAL_STATEMENT_STORY_SOURCE_ENRICHMENT_OK %s" % JSON.stringify(result.get("summary", {})))
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
	var story_ids: Dictionary = {
		CONTRACT_STORY_KEY: "story|%s|%s|r2_2" % [company_id, CONTRACT_STORY_KEY],
		CAPEX_STORY_KEY: "story|%s|%s|r2_2" % [company_id, CAPEX_STORY_KEY],
		DEBT_STORY_KEY: "story|%s|%s|r2_2" % [company_id, DEBT_STORY_KEY]
	}
	var living_arc_id: String = "arc|%s|%s|r2_2" % [company_id, LIVING_ARC_KEY]

	_seed_story_source_state(company_id, ticker, story_ids)
	_seed_living_arc_state(company_id, living_arc_id)

	if not RunState.ensure_company_full_detail(company_id):
		return _case_fail("Could not hydrate full detail for %s." % company_id)
	RunState.refresh_annual_statement_post_start_enrichment(company_id)

	var annual: Dictionary = _annual_for_company(company_id)
	if annual.is_empty():
		return _case_fail("Expected annual statement after hydration.")

	var assertions: Dictionary = _assert_story_and_arc_sources(annual, story_ids, living_arc_id)
	if not bool(assertions.get("success", false)):
		return assertions

	var first_payload: String = _source_payload(annual)
	RunState.refresh_annual_statement_post_start_enrichment(company_id)
	RunState.refresh_annual_statement_post_start_enrichment(company_id)
	var refreshed_payload: String = _source_payload(_annual_for_company(company_id))
	if first_payload != refreshed_payload:
		return _case_fail("Annual story-source enrichment changed after repeated refreshes.")

	return {
		"success": true,
		"summary": {
			"company_id": company_id,
			"story_count": story_ids.size(),
			"living_arc_id": living_arc_id,
			"note_count": _variant_array(annual.get("notes", [])).size()
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
			"text_key": "r2_2_%s_%s" % [archetype_id, metric_id],
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
		"story_family": "r2_2_statement_source",
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
			"source_id": "r2_2_test",
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
			"seed_parts": ["r2_2", company_id, archetype_id],
			"source_company_hook_ids": [archetype_id],
			"source_fact_ids": [fact_id],
			"generated_surface_ids": [],
			"evidence_ids": clue_ids,
			"price_effect_ids": [],
			"statement_effect_ids": effect_ids
		}
	}


func _seed_living_arc_state(company_id: String, living_arc_id: String) -> void:
	var state: Dictionary = RunState.get_company_living_arc_state(company_id)
	state["active_arc_id"] = living_arc_id
	state["active_source_system"] = "company_roadmap"
	state["active_arc_type"] = "roadmap_project"
	state["active_event_id"] = "roadmap_expansion_funding"
	state["active_tone"] = "positive"
	state["active_arc_started_day"] = 3
	state["active_arc_expected_end_day"] = 100
	state["active_phase_id"] = "execution_window"
	state["active_phase_label"] = "Execution window"
	state["eligibility_tags"] = ["roadmap_physical_project", "capex_expansion", "funding_need"]
	RunState.set_company_living_arc_state(company_id, state)


func _assert_story_and_arc_sources(annual: Dictionary, story_ids: Dictionary, living_arc_id: String) -> Dictionary:
	var contract_story_id: String = str(story_ids.get(CONTRACT_STORY_KEY, ""))
	var capex_story_id: String = str(story_ids.get(CAPEX_STORY_KEY, ""))
	var debt_story_id: String = str(story_ids.get(DEBT_STORY_KEY, ""))
	var checks: Array = [
		["revenue", contract_story_id, "revenue note should preserve contract story source"],
		["property_plant_and_equipment", capex_story_id, "PPE note should preserve capex story source"],
		["debt_and_borrowings", debt_story_id, "debt note should preserve debt story source"],
		["segment_information", contract_story_id, "segment note should preserve operating story source"],
		["commitments_contingencies_and_subsequent_events", contract_story_id, "commitments note should preserve contract story source"],
		["commitments_contingencies_and_subsequent_events", capex_story_id, "commitments note should preserve capex story source"],
		["commitments_contingencies_and_subsequent_events", debt_story_id, "commitments note should preserve debt story source"]
	]
	for check in checks:
		var note: Dictionary = _note_by_type(annual, str(check[0]))
		if note.is_empty():
			return _case_fail("Missing annual note type %s." % str(check[0]))
		var story_id: String = str(check[1])
		if not _string_array(note.get("source_story_ids", [])).has(story_id):
			return _case_fail("%s. Actual source_story_ids=%s" % [
				str(check[2]),
				JSON.stringify(_string_array(note.get("source_story_ids", [])))
			])
		if _string_array(note.get("fact_ids", [])).is_empty():
			return _case_fail("Expected fact ids for note %s." % str(check[0]))
		if _string_array(note.get("source_effect_ids", [])).is_empty():
			return _case_fail("Expected effect ids for note %s." % str(check[0]))
		if _string_array(note.get("clue_ids", [])).is_empty():
			return _case_fail("Expected clue ids for note %s." % str(check[0]))
		if _variant_array(note.get("story_source_refs", [])).is_empty():
			return _case_fail("Expected story source refs for note %s." % str(check[0]))
		if _string_array(note.get("source_disclosure_packet_ids", [])).is_empty():
			return _case_fail("Expected disclosure packet ids for note %s." % str(check[0]))
		if _string_array(note.get("source_disclosure_placement_ids", [])).is_empty():
			return _case_fail("Expected disclosure placement ids for note %s." % str(check[0]))
		if _string_array(note.get("source_disclosure_section_ids", [])).is_empty():
			return _case_fail("Expected disclosure section ids for note %s." % str(check[0]))
		var packet_refs: Array = _variant_array(note.get("disclosure_packet_refs", []))
		if packet_refs.is_empty():
			return _case_fail("Expected disclosure packet refs for note %s." % str(check[0]))
		for packet_ref_value in packet_refs:
			if typeof(packet_ref_value) != TYPE_DICTIONARY:
				return _case_fail("Expected disclosure packet ref dictionary for note %s." % str(check[0]))
			var packet_ref: Dictionary = packet_ref_value
			for hidden_key in HIDDEN_PACKET_KEYS:
				if packet_ref.has(hidden_key):
					return _case_fail("Disclosure packet ref leaked hidden key %s on note %s." % [hidden_key, str(check[0])])

	for arc_note_type in ["property_plant_and_equipment", "debt_and_borrowings", "cash_flow_information", "commitments_contingencies_and_subsequent_events"]:
		var arc_note: Dictionary = _note_by_type(annual, arc_note_type)
		if arc_note.is_empty():
			return _case_fail("Missing annual note type %s for living arc." % arc_note_type)
		if not _string_array(arc_note.get("source_living_arc_ids", [])).has(living_arc_id):
			return _case_fail("Expected living arc id on annual note %s." % arc_note_type)
		if _variant_array(arc_note.get("living_arc_refs", [])).is_empty():
			return _case_fail("Expected living arc refs on annual note %s." % arc_note_type)

	var basis_note: Dictionary = _note_by_type(annual, "basis_of_preparation")
	if basis_note.is_empty():
		return _case_fail("Missing basis of preparation note.")
	if not _string_array(basis_note.get("source_story_ids", [])).is_empty():
		return _case_fail("Basis note should not receive unrelated story sources.")
	if str(basis_note.get("summary", "")).strip_edges().is_empty():
		return _case_fail("Basis note should remain a valid deterministic note.")

	var traceability: Dictionary = annual.get("traceability", {}) if typeof(annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	for story_id_value in story_ids.values():
		var story_id: String = str(story_id_value)
		if not _string_array(traceability.get("post_start_source_story_ids", [])).has(story_id):
			return _case_fail("Expected statement traceability to include story %s." % story_id)
	if _string_array(traceability.get("post_start_source_disclosure_packet_ids", [])).is_empty():
		return _case_fail("Expected statement traceability to include disclosure packet ids.")
	if _string_array(traceability.get("post_start_source_disclosure_placement_ids", [])).is_empty():
		return _case_fail("Expected statement traceability to include disclosure placement ids.")
	if _string_array(traceability.get("post_start_source_disclosure_section_ids", [])).is_empty():
		return _case_fail("Expected statement traceability to include disclosure section ids.")
	if not _string_array(traceability.get("post_start_source_living_arc_ids", [])).has(living_arc_id):
		return _case_fail("Expected statement traceability to include living arc %s." % living_arc_id)
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
	lines.append("stories:%s" % "|".join(_string_array(traceability.get("post_start_source_story_ids", []))))
	lines.append("packets:%s" % "|".join(_string_array(traceability.get("post_start_source_disclosure_packet_ids", []))))
	lines.append("placements:%s" % "|".join(_string_array(traceability.get("post_start_source_disclosure_placement_ids", []))))
	lines.append("sections:%s" % "|".join(_string_array(traceability.get("post_start_source_disclosure_section_ids", []))))
	lines.append("arcs:%s" % "|".join(_string_array(traceability.get("post_start_source_living_arc_ids", []))))
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		lines.append("note:%s:%s:%s:%s:%s:%s:%s" % [
			str(note.get("note_type", "")),
			"|".join(_string_array(note.get("source_story_ids", []))),
			"|".join(_string_array(note.get("source_effect_ids", []))),
			"|".join(_string_array(note.get("fact_ids", []))),
			"|".join(_string_array(note.get("clue_ids", []))),
			"|".join(_string_array(note.get("source_disclosure_packet_ids", []))),
			"|".join(_string_array(note.get("source_living_arc_ids", [])))
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
	print("ANNUAL_STATEMENT_STORY_SOURCE_ENRICHMENT_FAIL: %s" % message)
	get_tree().quit(1)
