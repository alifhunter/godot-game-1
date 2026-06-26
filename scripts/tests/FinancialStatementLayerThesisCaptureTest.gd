extends Node

const RUN_SEED := 516226
const R2_4_CHAIN_SUFFIX := "rights_capex_r2_4"
const R2_4_ROADMAP_SUFFIX := "expansion_r2_4"
const R2_4_CORPORATE_EVENT_ID := "corporate_action_filing"
const R2_4_ROADMAP_EVENT_ID := "roadmap_development"
const R2_4_ANNUAL_NOTE_TYPE := "commitments_contingencies_and_subsequent_events"


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0

	var company_id: String = str(RunState.company_order[0])
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	var ticker: String = str(definition.get("ticker", company_id.to_upper()))
	var company_name: String = str(definition.get("name", ticker))
	var r2_4_chain_id: String = "chain|%s|%s" % [company_id, R2_4_CHAIN_SUFFIX]
	var r2_4_roadmap_id: String = "roadmap|%s|%s" % [company_id, R2_4_ROADMAP_SUFFIX]
	_seed_r2_4_annual_note_provenance(company_id, ticker, company_name, r2_4_chain_id, r2_4_roadmap_id)

	if not RunState.ensure_company_full_detail(company_id):
		_fail("Expected company full detail for annual statement capture.")
		return
	var annual_statement: Dictionary = _annual_statement(company_id)
	if annual_statement.is_empty():
		_fail("Expected annual consolidated statement for thesis capture.")
		return
	var thesis_result: Dictionary = GameManager.create_thesis(company_id, "bullish", "position", "Statement Capture Thesis")
	if not bool(thesis_result.get("success", false)):
		_fail("Expected thesis creation to succeed.")
		return
	var thesis_id: String = str(thesis_result.get("thesis", {}).get("id", ""))

	var statement_payload: Dictionary = _statement_line_payload(company_id)
	var statement_capture: Dictionary = GameManager.capture_research_evidence(statement_payload)
	if not bool(statement_capture.get("success", false)):
		_fail("Expected statement line capture to succeed: %s" % str(statement_capture.get("message", "")))
		return
	var statement_evidence: Dictionary = statement_capture.get("evidence", {})
	if str(statement_evidence.get("category", "")) != "financials" or str(statement_evidence.get("source_label", "")) != "Financials":
		_fail("Expected statement line capture to normalize as Financials evidence.")
		return
	if not _evidence_has_statement_line_contract(statement_evidence):
		return

	var duplicate_capture: Dictionary = GameManager.capture_research_evidence(statement_payload)
	if not bool(duplicate_capture.get("success", false)) or str(duplicate_capture.get("message", "")) != "Already in Research Tray.":
		_fail("Expected duplicate statement line capture to reuse Research Tray row.")
		return

	var statement_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(statement_evidence.get("id", "")), "support")
	if not bool(statement_attach.get("success", false)):
		_fail("Expected statement line evidence to attach to thesis.")
		return
	if not _evidence_has_statement_line_contract(statement_attach.get("evidence", {})):
		return

	var note_payload: Dictionary = _statement_note_payload(company_id)
	var note_capture: Dictionary = GameManager.capture_research_evidence(note_payload)
	if not bool(note_capture.get("success", false)):
		_fail("Expected statement note capture to succeed: %s" % str(note_capture.get("message", "")))
		return
	var note_evidence: Dictionary = note_capture.get("evidence", {})
	if not _evidence_has_statement_note_contract(note_evidence):
		return

	var note_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(note_evidence.get("id", "")), "contradiction")
	if not bool(note_attach.get("success", false)):
		_fail("Expected statement note evidence to attach to thesis.")
		return
	if not _evidence_has_statement_note_contract(note_attach.get("evidence", {})):
		return

	var direct_add: Dictionary = GameManager.add_thesis_evidence(thesis_id, note_payload.merged({"interpretation": "watch"}, true))
	if not bool(direct_add.get("success", false)):
		_fail("Expected direct thesis evidence add to preserve statement note contract.")
		return
	if not _evidence_has_statement_note_contract(direct_add.get("evidence", {})):
		return

	var annual_line_payload: Dictionary = _annual_statement_line_payload(company_id, annual_statement)
	var annual_line_capture: Dictionary = GameManager.capture_research_evidence(annual_line_payload)
	if not bool(annual_line_capture.get("success", false)):
		_fail("Expected annual statement line capture to succeed: %s" % str(annual_line_capture.get("message", "")))
		return
	if str(annual_line_capture.get("message", "")) == "Already in Research Tray.":
		_fail("Expected annual statement line capture to stay distinct from quarterly statement evidence.")
		return
	var annual_line_evidence: Dictionary = annual_line_capture.get("evidence", {})
	if not _evidence_has_annual_statement_line_contract(annual_line_evidence, annual_statement):
		return
	var annual_line_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(annual_line_evidence.get("id", "")), "support")
	if not bool(annual_line_attach.get("success", false)):
		_fail("Expected annual statement line evidence to attach to thesis.")
		return
	if not _evidence_has_annual_statement_line_contract(annual_line_attach.get("evidence", {}), annual_statement):
		return

	var annual_note_payload: Dictionary = _annual_statement_note_payload(company_id, annual_statement)
	var annual_note_capture: Dictionary = GameManager.capture_research_evidence(annual_note_payload)
	if not bool(annual_note_capture.get("success", false)):
		_fail("Expected annual statement note capture to succeed: %s" % str(annual_note_capture.get("message", "")))
		return
	if str(annual_note_capture.get("message", "")) == "Already in Research Tray.":
		_fail("Expected annual statement note capture to stay distinct from quarterly statement notes.")
		return
	var annual_note_evidence: Dictionary = annual_note_capture.get("evidence", {})
	if not _evidence_has_annual_statement_note_contract(annual_note_evidence, annual_statement):
		return
	if not _evidence_has_r2_4_annual_note_provenance(annual_note_evidence, r2_4_chain_id, r2_4_roadmap_id):
		return
	var annual_note_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(annual_note_evidence.get("id", "")), "support")
	if not bool(annual_note_attach.get("success", false)):
		_fail("Expected annual statement note evidence to attach to thesis.")
		return
	if not _evidence_has_annual_statement_note_contract(annual_note_attach.get("evidence", {}), annual_statement):
		return
	if not _evidence_has_r2_4_annual_note_provenance(annual_note_attach.get("evidence", {}), r2_4_chain_id, r2_4_roadmap_id):
		return
	var annual_note_direct_add: Dictionary = GameManager.add_thesis_evidence(thesis_id, annual_note_payload.merged({"interpretation": "support"}, true))
	if not bool(annual_note_direct_add.get("success", false)):
		_fail("Expected direct annual note add to preserve enriched provenance.")
		return
	if not _evidence_has_r2_4_annual_note_provenance(annual_note_direct_add.get("evidence", {}), r2_4_chain_id, r2_4_roadmap_id):
		return

	var annual_note_paragraph_payload: Dictionary = _annual_statement_note_paragraph_payload(company_id, annual_statement)
	var annual_note_paragraph_capture: Dictionary = GameManager.capture_research_evidence(annual_note_paragraph_payload)
	if not bool(annual_note_paragraph_capture.get("success", false)):
		_fail("Expected annual statement note paragraph capture to succeed: %s" % str(annual_note_paragraph_capture.get("message", "")))
		return
	if str(annual_note_paragraph_capture.get("message", "")) == "Already in Research Tray.":
		_fail("Expected annual statement note paragraph capture to stay distinct from full note evidence.")
		return
	var annual_note_paragraph_evidence: Dictionary = annual_note_paragraph_capture.get("evidence", {})
	if not _evidence_has_annual_statement_note_paragraph_contract(annual_note_paragraph_evidence, annual_statement):
		return
	if not _evidence_has_r2_4_annual_note_provenance(annual_note_paragraph_evidence, r2_4_chain_id, r2_4_roadmap_id):
		return
	var annual_note_paragraph_attach: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(annual_note_paragraph_evidence.get("id", "")), "support")
	if not bool(annual_note_paragraph_attach.get("success", false)):
		_fail("Expected annual statement note paragraph evidence to attach to thesis.")
		return
	if not _evidence_has_annual_statement_note_paragraph_contract(annual_note_paragraph_attach.get("evidence", {}), annual_statement):
		return
	var annual_note_paragraph_direct_add: Dictionary = GameManager.add_thesis_evidence(thesis_id, annual_note_paragraph_payload.merged({"interpretation": "support"}, true))
	if not bool(annual_note_paragraph_direct_add.get("success", false)):
		_fail("Expected direct annual note paragraph add to preserve paragraph provenance.")
		return
	if not _evidence_has_annual_statement_note_paragraph_contract(annual_note_paragraph_direct_add.get("evidence", {}), annual_statement):
		return

	var save_payload: Dictionary = RunState.to_save_dict()
	for row_key in save_payload.get("thesis_research_tray", {}).keys():
		if typeof(save_payload["thesis_research_tray"].get(row_key)) == TYPE_DICTIONARY:
			save_payload["thesis_research_tray"][row_key].erase("dedupe_key")
	RunState.load_from_dict(save_payload)
	var loaded_statement_evidence: Dictionary = RunState.get_research_evidence(str(statement_evidence.get("id", "")))
	if not _evidence_has_statement_line_contract(loaded_statement_evidence):
		return
	if str(loaded_statement_evidence.get("dedupe_key", "")).find("statement|testco|2020|q2") < 0:
		_fail("Expected old-save dedupe repair to include statement id.")
		return
	var loaded_note_evidence: Dictionary = RunState.get_research_evidence(str(note_evidence.get("id", "")))
	if not _evidence_has_statement_note_contract(loaded_note_evidence):
		return
	if str(loaded_note_evidence.get("dedupe_key", "")).find("note|statement|testco|2020|q2|customer_contract|01") < 0:
		_fail("Expected old-save dedupe repair to include note id.")
		return
	var loaded_annual_line_evidence: Dictionary = RunState.get_research_evidence(str(annual_line_evidence.get("id", "")))
	if not _evidence_has_annual_statement_line_contract(loaded_annual_line_evidence, annual_statement):
		return
	if str(loaded_annual_line_evidence.get("dedupe_key", "")).find("annual_statement|") < 0:
		_fail("Expected old-save dedupe repair to include annual statement id.")
		return
	var loaded_annual_note_evidence: Dictionary = RunState.get_research_evidence(str(annual_note_evidence.get("id", "")))
	if not _evidence_has_annual_statement_note_contract(loaded_annual_note_evidence, annual_statement):
		return
	if not _evidence_has_r2_4_annual_note_provenance(loaded_annual_note_evidence, r2_4_chain_id, r2_4_roadmap_id):
		return
	if str(loaded_annual_note_evidence.get("dedupe_key", "")).find("annual_note|") < 0:
		_fail("Expected old-save dedupe repair to include annual note id.")
		return
	var loaded_annual_note_paragraph_evidence: Dictionary = RunState.get_research_evidence(str(annual_note_paragraph_evidence.get("id", "")))
	if not _evidence_has_annual_statement_note_paragraph_contract(loaded_annual_note_paragraph_evidence, annual_statement):
		return
	if str(loaded_annual_note_paragraph_evidence.get("dedupe_key", "")).find("annual_note_paragraph") < 0:
		_fail("Expected old-save dedupe repair to include annual note paragraph source id.")
		return

	var loaded_thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	var loaded_rows: Array = _variant_array(loaded_thesis.get("evidence", []))
	var found_line: bool = false
	var found_note: bool = false
	var found_annual_line: bool = false
	var found_annual_note: bool = false
	var found_annual_note_paragraph: bool = false
	var found_annual_note_with_r2_4_provenance: bool = false
	for row_value in loaded_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("line_id", "")) == "line|statement|testco|2020|q2|income_statement|revenue":
			found_line = true
		if str(row.get("note_id", "")) == "note|statement|testco|2020|q2|customer_contract|01":
			found_note = true
		if str(row.get("line_id", "")) == str(annual_line_evidence.get("line_id", "")):
			found_annual_line = true
		if str(row.get("note_id", "")) == str(annual_note_evidence.get("note_id", "")):
			found_annual_note = true
			if _row_has_r2_4_annual_note_provenance(row, r2_4_chain_id, r2_4_roadmap_id):
				found_annual_note_with_r2_4_provenance = true
		if str(row.get("note_paragraph_id", "")) == str(annual_note_paragraph_evidence.get("note_paragraph_id", "")):
			found_annual_note_paragraph = true
	if not found_line or not found_note or not found_annual_line or not found_annual_note or not found_annual_note_paragraph:
		_fail("Expected save/load to preserve attached quarterly and annual statement provenance.")
		return
	if not found_annual_note_with_r2_4_provenance:
		_fail("Expected save/load to preserve attached annual note action/event/roadmap provenance.")
		return

	print("FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK")
	get_tree().quit(0)


func _seed_r2_4_annual_note_provenance(company_id: String, ticker: String, company_name: String, chain_id: String, roadmap_id: String) -> void:
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
			"meeting_id": "meeting|%s|r2_4" % company_id,
			"created_day_index": 5,
			"rights_terms": {
				"funding_purpose": "expansion_capex",
				"use_of_proceeds": "roadmap_project"
			}
		}
	})
	RunState.event_history = [
		{
			"event_id": R2_4_CORPORATE_EVENT_ID,
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
			"meeting_id": "meeting|%s|r2_4" % company_id,
			"day_index": 6
		},
		{
			"event_id": R2_4_ROADMAP_EVENT_ID,
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


func _statement_line_payload(company_id: String) -> Dictionary:
	return {
		"source_type": "financial_statement",
		"category": "financials",
		"company_id": company_id,
		"label": "Total revenue",
		"value": "Rp1.18B",
		"detail": "Total revenue line from Income Statement (Q2 2020).",
		"source_id": "financial_statement_%s_income_q2_2020_revenue" % company_id,
		"statement_id": "statement|testco|2020|q2",
		"statement_period_label": "Q2 2020",
		"statement_scope": "quarterly",
		"statement_year": "2020",
		"statement_quarter": "2",
		"filing_day_index": "80",
		"statement_section": "income_statement",
		"statement_section_label": "Income Statement",
		"line_id": "line|statement|testco|2020|q2|income_statement|revenue",
		"statement_line_id": "line|statement|testco|2020|q2|income_statement|revenue",
		"line_item_id": "revenue",
		"metric_id": "revenue",
		"metric_ids": ["revenue"],
		"story_id": "story|testco|contract_win|case_a",
		"effect_id": "effect|story|testco|contract_win|case_a|revenue",
		"fact_id": "fact|story|testco|contract_win|case_a|customer",
		"clue_id": "clue|story|testco|contract_win|case_a|statement|01",
		"source_story_ids": ["story|testco|contract_win|case_a"],
		"source_effect_ids": ["effect|story|testco|contract_win|case_a|revenue"],
		"fact_ids": ["fact|story|testco|contract_win|case_a|customer"],
		"clue_ids": ["clue|story|testco|contract_win|case_a|statement|01"],
		"effect_ids": ["effect|story|testco|contract_win|case_a|revenue"],
		"statement_value_format": "currency",
		"raw_value": 1180.0,
		"vocabulary_tags": ["financial_statement", "filing", "income_statement", "revenue"]
	}


func _statement_note_payload(company_id: String) -> Dictionary:
	return {
		"source_type": "financial_statement",
		"category": "financials",
		"company_id": company_id,
		"label": "Customer Contract",
		"value": "Clear / High",
		"detail": "Revenue and backlog disclosures point to customer demand (Q2 2020).",
		"source_id": "financial_statement_note_%s_q2_2020_customer_contract" % company_id,
		"statement_id": "statement|testco|2020|q2",
		"statement_period_label": "Q2 2020",
		"statement_scope": "quarterly",
		"statement_year": "2020",
		"statement_quarter": "2",
		"filing_day_index": "80",
		"statement_section": "notes",
		"statement_section_label": "Notes & MD&A",
		"note_id": "note|statement|testco|2020|q2|customer_contract|01",
		"note_type": "customer_contract",
		"note_title_key": "customer_contract_title",
		"note_text_key": "customer_contract_clear_high_positive",
		"disclosure_quality": "clear",
		"detail_level": "high",
		"access_level": "inner_circle",
		"source_quality": "clear",
		"story_id": "story|testco|contract_win|case_a",
		"metric_id": "revenue",
		"effect_id": "effect|story|testco|contract_win|case_a|revenue",
		"clue_id": "clue|story|testco|contract_win|case_a|statement|01",
		"fact_id": "fact|story|testco|contract_win|case_a|customer",
		"metric_ids": ["backlog", "revenue"],
		"effect_ids": [
			"effect|story|testco|contract_win|case_a|backlog",
			"effect|story|testco|contract_win|case_a|revenue"
		],
		"clue_ids": ["clue|story|testco|contract_win|case_a|statement|01"],
		"fact_ids": ["fact|story|testco|contract_win|case_a|customer"],
		"source_statement_sections": ["income_statement", "operating_metrics"],
		"explain_tags": ["customer_contract"],
		"raw_value": 0.86,
		"importance": 0.86,
		"direction": "positive",
		"tone": "positive",
		"vocabulary_tags": ["financial_statement", "filing", "notes", "revenue", "customer_contract"]
	}


func _annual_statement(company_id: String) -> Dictionary:
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, true, true)
	var snapshot: Dictionary = definition.get("financial_statement_snapshot", {}) if typeof(definition.get("financial_statement_snapshot", {})) == TYPE_DICTIONARY else {}
	var annual: Dictionary = snapshot.get("annual_statement", {}) if typeof(snapshot.get("annual_statement", {})) == TYPE_DICTIONARY else {}
	return annual.duplicate(true)


func _annual_statement_line_payload(company_id: String, annual: Dictionary) -> Dictionary:
	var line_item: Dictionary = _annual_line(annual, "profit_or_loss_and_oci", "revenue")
	var statement_id: String = str(annual.get("statement_id", ""))
	var period_label: String = str(annual.get("statement_period_label", "FY2019"))
	return {
		"source_type": "financial_statement",
		"category": "financials",
		"company_id": company_id,
		"label": str(line_item.get("label", "Revenue")),
		"value": "Annual revenue",
		"detail": "Revenue line from annual consolidated statement (%s)." % period_label,
		"source_id": "financial_statement_%s_annual_revenue_%s" % [company_id, _token(statement_id)],
		"statement_id": statement_id,
		"statement_period_label": period_label,
		"statement_scope": "annual",
		"statement_consolidated": true,
		"statement_year": str(annual.get("statement_year", annual.get("fiscal_year", ""))),
		"statement_quarter": "",
		"filing_day_index": "",
		"statement_section": "profit_or_loss_and_oci",
		"statement_section_label": "Consolidated Statement of Profit or Loss and Other Comprehensive Income",
		"line_id": str(line_item.get("line_id", "")),
		"statement_line_id": str(line_item.get("line_id", "")),
		"line_item_id": str(line_item.get("id", "")),
		"metric_id": str(line_item.get("metric_id", "")),
		"metric_ids": [str(line_item.get("metric_id", ""))],
		"statement_value_format": str(line_item.get("format", "currency")),
		"raw_value": float(line_item.get("value", 0.0)),
		"vocabulary_tags": ["financial_statement", "filing", "annual", "consolidated", "revenue"]
	}


func _annual_statement_note_payload(company_id: String, annual: Dictionary) -> Dictionary:
	var note: Dictionary = _annual_note_by_type(annual, R2_4_ANNUAL_NOTE_TYPE)
	var statement_id: String = str(annual.get("statement_id", ""))
	var period_label: String = str(annual.get("statement_period_label", "FY2019"))
	return {
		"source_type": "financial_statement",
		"category": "financials",
		"company_id": company_id,
		"label": str(note.get("title", "Revenue")),
		"value": "Clear / Annual",
		"detail": "%s (%s)." % [str(note.get("summary", "")), period_label],
		"source_id": "financial_statement_note_%s_annual_%s" % [company_id, _token(str(note.get("note_id", "")))],
		"statement_id": statement_id,
		"statement_period_label": period_label,
		"statement_scope": "annual",
		"statement_consolidated": true,
		"statement_year": str(annual.get("statement_year", annual.get("fiscal_year", ""))),
		"statement_quarter": "",
		"filing_day_index": "",
		"statement_section": "notes",
		"statement_section_label": "Notes to the Consolidated Financial Statements",
		"note_id": str(note.get("note_id", "")),
		"note_type": str(note.get("note_type", "")),
		"note_title_key": str(note.get("title_key", "")),
		"note_text_key": str(note.get("text_key", "")),
		"disclosure_quality": str(note.get("disclosure_quality", "")),
		"detail_level": str(note.get("detail_level", "")),
		"access_level": str(note.get("access_level", "")),
		"source_quality": str(note.get("disclosure_quality", "")),
		"metric_id": str(note.get("metric_id", "")),
		"metric_ids": _string_array(note.get("metric_ids", [])),
		"effect_ids": _string_array(note.get("effect_ids", [])),
		"clue_ids": _string_array(note.get("clue_ids", [])),
		"fact_ids": _string_array(note.get("fact_ids", [])),
		"source_story_ids": _string_array(note.get("source_story_ids", [])),
		"source_effect_ids": _string_array(note.get("source_effect_ids", [])),
		"source_disclosure_packet_ids": _string_array(note.get("source_disclosure_packet_ids", [])),
		"source_disclosure_placement_ids": _string_array(note.get("source_disclosure_placement_ids", [])),
		"source_disclosure_section_ids": _string_array(note.get("source_disclosure_section_ids", [])),
		"source_living_arc_ids": _string_array(note.get("source_living_arc_ids", [])),
		"source_corporate_action_ids": _string_array(note.get("source_corporate_action_ids", [])),
		"source_event_ids": _string_array(note.get("source_event_ids", [])),
		"source_event_ref_ids": _string_array(note.get("source_event_ref_ids", [])),
		"source_roadmap_ids": _string_array(note.get("source_roadmap_ids", [])),
		"source_statement_sections": _string_array(note.get("source_statement_sections", [])),
		"story_source_refs": _variant_array(note.get("story_source_refs", [])),
		"disclosure_packet_refs": _variant_array(note.get("disclosure_packet_refs", [])),
		"living_arc_refs": _variant_array(note.get("living_arc_refs", [])),
		"corporate_action_refs": _variant_array(note.get("corporate_action_refs", [])),
		"event_refs": _variant_array(note.get("event_refs", [])),
		"roadmap_refs": _variant_array(note.get("roadmap_refs", [])),
		"explain_tags": _string_array(note.get("explain_tags", [])),
		"raw_value": float(note.get("importance", 0.0)),
		"importance": float(note.get("importance", 0.0)),
		"direction": str(note.get("tone", "")),
		"tone": str(note.get("tone", "")),
		"vocabulary_tags": ["financial_statement", "filing", "annual", "consolidated", "notes", "revenue"]
	}

func _annual_statement_note_paragraph_payload(company_id: String, annual: Dictionary) -> Dictionary:
	var note: Dictionary = _annual_note_by_type(annual, R2_4_ANNUAL_NOTE_TYPE)
	var payload: Dictionary = _annual_statement_note_payload(company_id, annual)
	var paragraph: Dictionary = _annual_note_first_paragraph(note)
	var paragraph_index: int = int(paragraph.get("paragraph_index", 1))
	var paragraph_text: String = str(paragraph.get("text", "")).strip_edges()
	payload["label"] = "Note %d paragraph %d" % [int(note.get("note_number", 0)), paragraph_index]
	payload["value"] = paragraph_text
	payload["detail"] = "Paragraph %d from %s (%s)." % [
		paragraph_index,
		str(note.get("title", "")),
		str(annual.get("statement_period_label", "FY2019"))
	]
	payload["source_id"] = "financial_statement_annual_note_paragraph_%s_%s_%02d" % [
		company_id,
		_token(str(note.get("note_id", ""))),
		paragraph_index
	]
	payload["capture_level"] = "note_paragraph"
	payload["note_paragraph_id"] = str(paragraph.get("paragraph_id", ""))
	payload["note_paragraph_index"] = str(paragraph_index)
	payload["note_paragraph_role"] = str(paragraph.get("paragraph_role", ""))
	payload["note_paragraph_text"] = paragraph_text
	for text_key_value in [
		"surface_id",
		"story_id",
		"disclosure_packet_id",
		"disclosure_placement_id",
		"disclosure_section_id",
		"disclosure_section_label",
		"disclosure_subtlety",
		"disclosure_reader_effort",
		"disclosure_evidence_density",
		"disclosure_fragment_role",
		"disclosure_packet_role"
	]:
		var text_key: String = str(text_key_value)
		if paragraph.has(text_key):
			payload[text_key] = str(paragraph.get(text_key, ""))
	for array_key_value in [
		"metric_ids",
		"effect_ids",
		"clue_ids",
		"fact_ids",
		"source_story_ids",
		"source_effect_ids",
		"source_disclosure_packet_ids",
		"source_disclosure_placement_ids",
		"source_disclosure_section_ids",
		"disclosure_packet_refs"
	]:
		var array_key: String = str(array_key_value)
		if typeof(paragraph.get(array_key, [])) == TYPE_ARRAY:
			payload[array_key] = paragraph.get(array_key, []).duplicate(true)
	return payload


func _evidence_has_statement_line_contract(row: Dictionary) -> bool:
	if str(row.get("statement_id", "")) != "statement|testco|2020|q2":
		_fail("Expected statement line evidence to preserve statement_id.")
		return false
	if str(row.get("statement_period_label", "")) != "Q2 2020":
		_fail("Expected statement line evidence to preserve statement_period_label.")
		return false
	if str(row.get("statement_section", "")) != "income_statement":
		_fail("Expected statement line evidence to preserve statement_section.")
		return false
	if str(row.get("line_id", "")) != "line|statement|testco|2020|q2|income_statement|revenue":
		_fail("Expected statement line evidence to preserve line_id.")
		return false
	if str(row.get("metric_id", "")) != "revenue":
		_fail("Expected statement line evidence to preserve metric_id.")
		return false
	if not _string_array(row.get("source_effect_ids", [])).has("effect|story|testco|contract_win|case_a|revenue"):
		_fail("Expected statement line evidence to preserve source_effect_ids.")
		return false
	if not is_equal_approx(float(row.get("raw_value", 0.0)), 1180.0):
		_fail("Expected statement line evidence to preserve raw_value.")
		return false
	return true


func _evidence_has_statement_note_contract(row: Dictionary) -> bool:
	if str(row.get("note_id", "")) != "note|statement|testco|2020|q2|customer_contract|01":
		_fail("Expected statement note evidence to preserve note_id.")
		return false
	if str(row.get("note_type", "")) != "customer_contract":
		_fail("Expected statement note evidence to preserve note_type.")
		return false
	if str(row.get("disclosure_quality", "")) != "clear" or str(row.get("detail_level", "")) != "high":
		_fail("Expected statement note evidence to preserve disclosure quality and detail.")
		return false
	if not _string_array(row.get("metric_ids", [])).has("backlog") or not _string_array(row.get("metric_ids", [])).has("revenue"):
		_fail("Expected statement note evidence to preserve metric_ids.")
		return false
	if not _string_array(row.get("effect_ids", [])).has("effect|story|testco|contract_win|case_a|backlog"):
		_fail("Expected statement note evidence to preserve effect_ids.")
		return false
	if not _string_array(row.get("clue_ids", [])).has("clue|story|testco|contract_win|case_a|statement|01"):
		_fail("Expected statement note evidence to preserve clue_ids.")
		return false
	if not _string_array(row.get("source_statement_sections", [])).has("operating_metrics"):
		_fail("Expected statement note evidence to preserve source_statement_sections.")
		return false
	if not is_equal_approx(float(row.get("importance", 0.0)), 0.86):
		_fail("Expected statement note evidence to preserve importance.")
		return false
	return true


func _evidence_has_annual_statement_line_contract(row: Dictionary, annual: Dictionary) -> bool:
	if str(row.get("statement_id", "")) != str(annual.get("statement_id", "")):
		_fail("Expected annual statement line evidence to preserve annual statement_id.")
		return false
	if str(row.get("statement_scope", "")) != "annual" or not bool(row.get("statement_consolidated", false)):
		_fail("Expected annual statement line evidence to preserve annual consolidated scope.")
		return false
	if str(row.get("statement_period_label", "")) != str(annual.get("statement_period_label", "")):
		_fail("Expected annual statement line evidence to preserve FY period label.")
		return false
	if str(row.get("statement_section", "")) != "profit_or_loss_and_oci":
		_fail("Expected annual statement line evidence to preserve annual section id.")
		return false
	if not str(row.get("line_id", "")).begins_with("line|annual_statement|"):
		_fail("Expected annual statement line evidence to use annual line id.")
		return false
	if str(row.get("metric_id", "")) != "revenue":
		_fail("Expected annual statement line evidence to preserve revenue metric.")
		return false
	if not is_equal_approx(float(row.get("raw_value", 0.0)), _annual_line_value(annual, "profit_or_loss_and_oci", "revenue")):
		_fail("Expected annual statement line evidence to preserve raw annual value.")
		return false
	return true


func _evidence_has_annual_statement_note_contract(row: Dictionary, annual: Dictionary) -> bool:
	var note: Dictionary = _annual_note_by_type(annual, R2_4_ANNUAL_NOTE_TYPE)
	if str(row.get("note_id", "")) != str(note.get("note_id", "")):
		_fail("Expected annual statement note evidence to preserve annual note_id.")
		return false
	if str(row.get("statement_scope", "")) != "annual" or not bool(row.get("statement_consolidated", false)):
		_fail("Expected annual statement note evidence to preserve annual consolidated scope.")
		return false
	if str(row.get("statement_section", "")) != "notes":
		_fail("Expected annual statement note evidence to preserve notes section.")
		return false
	if str(row.get("note_type", "")) != R2_4_ANNUAL_NOTE_TYPE:
		_fail("Expected annual statement note evidence to preserve annual note_type.")
		return false
	if str(row.get("detail_level", "")) != "annual" or str(row.get("access_level", "")) != "public":
		_fail("Expected annual statement note evidence to preserve annual/public detail.")
		return false
	if not _string_array(row.get("source_statement_sections", [])).has("notes"):
		_fail("Expected annual statement note evidence to preserve annual source statement section.")
		return false
	if float(row.get("importance", 0.0)) <= 0.0:
		_fail("Expected annual statement note evidence to preserve importance.")
		return false
	if not _string_array(row.get("source_story_ids", [])).is_empty():
		if _string_array(row.get("source_disclosure_packet_ids", [])).is_empty():
			_fail("Expected annual statement note evidence to preserve disclosure packet ids.")
			return false
		if _string_array(row.get("source_disclosure_placement_ids", [])).is_empty():
			_fail("Expected annual statement note evidence to preserve disclosure placement ids.")
			return false
		if _string_array(row.get("source_disclosure_section_ids", [])).is_empty():
			_fail("Expected annual statement note evidence to preserve disclosure section ids.")
			return false
		if _variant_array(row.get("disclosure_packet_refs", [])).is_empty():
			_fail("Expected annual statement note evidence to preserve disclosure packet refs.")
			return false
	return true

func _evidence_has_annual_statement_note_paragraph_contract(row: Dictionary, annual: Dictionary) -> bool:
	if not _evidence_has_annual_statement_note_contract(row, annual):
		return false
	var note: Dictionary = _annual_note_by_type(annual, R2_4_ANNUAL_NOTE_TYPE)
	var paragraph: Dictionary = _annual_note_first_paragraph(note)
	if str(row.get("capture_level", "")) != "note_paragraph":
		_fail("Expected annual statement note paragraph evidence to preserve capture_level.")
		return false
	if str(row.get("note_paragraph_id", "")) != str(paragraph.get("paragraph_id", "")):
		_fail("Expected annual statement note paragraph evidence to preserve paragraph id.")
		return false
	if str(row.get("note_paragraph_index", "")) != str(paragraph.get("paragraph_index", "")):
		_fail("Expected annual statement note paragraph evidence to preserve paragraph index.")
		return false
	if str(row.get("note_paragraph_role", "")) != str(paragraph.get("paragraph_role", "")):
		_fail("Expected annual statement note paragraph evidence to preserve paragraph role.")
		return false
	if str(row.get("value", "")).strip_edges() != str(paragraph.get("text", "")).strip_edges():
		_fail("Expected annual statement note paragraph evidence value to match paragraph text.")
		return false
	if str(row.get("note_paragraph_text", "")).strip_edges() != str(paragraph.get("text", "")).strip_edges():
		_fail("Expected annual statement note paragraph evidence to preserve paragraph text.")
		return false
	if str(paragraph.get("paragraph_role", "")) == "disclosure_packet":
		if _string_array(row.get("source_disclosure_packet_ids", [])) != _string_array(paragraph.get("source_disclosure_packet_ids", [])):
			_fail("Expected annual statement packet paragraph evidence to preserve packet ids.")
			return false
		if str(row.get("disclosure_subtlety", "")) != str(paragraph.get("disclosure_subtlety", "")):
			_fail("Expected annual statement packet paragraph evidence to preserve subtlety.")
			return false
		if _variant_array(row.get("disclosure_packet_refs", [])).is_empty():
			_fail("Expected annual statement packet paragraph evidence to preserve packet refs.")
			return false
	return true


func _evidence_has_r2_4_annual_note_provenance(row: Dictionary, chain_id: String, roadmap_id: String) -> bool:
	if not _row_has_r2_4_annual_note_provenance(row, chain_id, roadmap_id):
		_fail("Expected annual note evidence to preserve action/event/roadmap provenance: %s" % JSON.stringify({
			"source_corporate_action_ids": _string_array(row.get("source_corporate_action_ids", [])),
			"source_event_ids": _string_array(row.get("source_event_ids", [])),
			"source_event_ref_ids": _string_array(row.get("source_event_ref_ids", [])),
			"source_roadmap_ids": _string_array(row.get("source_roadmap_ids", [])),
			"corporate_action_ref_count": _variant_array(row.get("corporate_action_refs", [])).size(),
			"event_ref_count": _variant_array(row.get("event_refs", [])).size(),
			"roadmap_ref_count": _variant_array(row.get("roadmap_refs", [])).size()
		}))
		return false
	return true


func _row_has_r2_4_annual_note_provenance(row: Dictionary, chain_id: String, roadmap_id: String) -> bool:
	if not _string_array(row.get("source_corporate_action_ids", [])).has(chain_id):
		return false
	if not _string_array(row.get("source_event_ids", [])).has(R2_4_CORPORATE_EVENT_ID):
		return false
	if not _string_array(row.get("source_event_ids", [])).has(R2_4_ROADMAP_EVENT_ID):
		return false
	if _string_array(row.get("source_event_ref_ids", [])).is_empty():
		return false
	if not _string_array(row.get("source_roadmap_ids", [])).has(roadmap_id):
		return false
	if _variant_array(row.get("corporate_action_refs", [])).is_empty():
		return false
	if _variant_array(row.get("event_refs", [])).is_empty():
		return false
	if _variant_array(row.get("roadmap_refs", [])).is_empty():
		return false
	return true


func _annual_line(annual: Dictionary, section_id: String, line_id: String) -> Dictionary:
	for line_value in _variant_array(annual.get(section_id, [])):
		if typeof(line_value) != TYPE_DICTIONARY:
			continue
		var line: Dictionary = line_value
		if str(line.get("id", "")) == line_id or str(line.get("metric_id", "")) == line_id:
			return line.duplicate(true)
	return {}


func _annual_line_value(annual: Dictionary, section_id: String, line_id: String) -> float:
	return float(_annual_line(annual, section_id, line_id).get("value", 0.0))


func _annual_note_by_type(annual: Dictionary, note_type: String) -> Dictionary:
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		if str(note.get("note_type", "")) == note_type:
			return note.duplicate(true)
	return {}


func _annual_note_first_paragraph(note: Dictionary) -> Dictionary:
	for paragraph_value in _variant_array(note.get("body_paragraphs", [])):
		if typeof(paragraph_value) != TYPE_DICTIONARY:
			continue
		var paragraph: Dictionary = paragraph_value
		if str(paragraph.get("paragraph_role", "")) == "disclosure_packet":
			return paragraph.duplicate(true)
	for paragraph_value in _variant_array(note.get("body_paragraphs", [])):
		if typeof(paragraph_value) == TYPE_DICTIONARY:
			return paragraph_value.duplicate(true)
	return {}


func _token(value: String) -> String:
	return value.strip_edges().to_lower().replace("|", "_").replace(" ", "_")


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


func _fail(message: String) -> void:
	push_error(message)
	print("FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_FAIL: %s" % message)
	get_tree().quit(1)
