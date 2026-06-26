extends Node

const THESIS_EVIDENCE_CAPTURE_SYSTEM = preload("res://systems/ThesisEvidenceCaptureSystem.gd")

const RUN_SEED := 20260621
const CATALOG_COMPANY_COUNT := 30
const EXPECTED_HASH := "906899410"
const EXPECTED_NOTE_COUNT := 14
const EXPECTED_SECTION_IDS := [
	"financial_position",
	"profit_or_loss_and_oci",
	"changes_in_equity",
	"cash_flows",
	"notes"
]
const EXPECTED_PAGE_LABELS := {
	"financial_position": "1-3",
	"profit_or_loss_and_oci": "4-5",
	"changes_in_equity": "6-7",
	"cash_flows": "8-9",
	"notes": "10-140"
}
const EXPECTED_PACKET_RENDER_STATUS := "r3_5_story_dossier_packets_consumed"
const HIDDEN_VISIBLE_TOKENS := [
	"truth_state",
	"fraud_risk",
	"overhyped",
	"story|",
	"packet|",
	"placement|",
	"source_quality",
	"disclosure_quality"
]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_case()
	if not bool(first_report.get("success", false)):
		_fail(str(first_report.get("message", "annual report fidelity capture test failed")))
		return
	var second_report: Dictionary = _build_case()
	if not bool(second_report.get("success", false)):
		_fail(str(second_report.get("message", "repeated annual report fidelity capture test failed")))
		return
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Annual report fidelity payload changed across repeated fixed-seed runs.")
		return

	var hash: String = _stable_hash(str(first_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual report fidelity capture hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	var capture_result: Dictionary = _run_capture_case(str(second_report.get("company_id", "")), second_report.get("annual", {}))
	if not bool(capture_result.get("success", false)):
		_fail(str(capture_result.get("message", "annual report capture case failed")))
		return

	print("ANNUAL_REPORT_FIDELITY_CAPTURE_OK %s" % JSON.stringify({
		"hash": hash,
		"company_id": str(second_report.get("company_id", "")),
		"packet_paragraph_count": int(second_report.get("packet_paragraph_count", 0)),
		"cross_reference_count": int(second_report.get("cross_reference_count", 0)),
		"multi_section_story_count": int(second_report.get("multi_section_story_count", 0)),
		"capture_count": int(capture_result.get("capture_count", 0))
	}))
	get_tree().quit(0)


func _build_case() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = CATALOG_COMPANY_COUNT
	difficulty_config["use_company_universe_catalog"] = true
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0

	var selected: Dictionary = _first_annual_with_fidelity_requirements()
	if not bool(selected.get("success", false)):
		return selected
	var company_id: String = str(selected.get("company_id", ""))
	var annual: Dictionary = selected.get("annual", {}) if typeof(selected.get("annual", {})) == TYPE_DICTIONARY else {}
	var validation: Dictionary = _validate_annual_report(company_id, annual)
	if not bool(validation.get("success", false)):
		return validation
	return {
		"success": true,
		"company_id": company_id,
		"annual": annual,
		"payload": _fidelity_payload(company_id, annual),
		"packet_paragraph_count": _packet_paragraph_count(annual),
		"cross_reference_count": _cross_reference_count(annual),
		"multi_section_story_count": _multi_section_story_count(annual)
	}


func _first_annual_with_fidelity_requirements() -> Dictionary:
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		if not RunState.ensure_company_full_detail(company_id):
			continue
		RunState.refresh_annual_statement_post_start_enrichment(company_id)
		var annual: Dictionary = _annual_for_company(company_id)
		if annual.is_empty():
			continue
		if (
			_packet_ref_count(annual) > 0 and
			_packet_paragraph_count(annual) > 0 and
			_cross_reference_count(annual) > 0 and
			_multi_section_story_count(annual) > 0
		):
			return {"success": true, "company_id": company_id, "annual": annual}
	return _case_fail("Expected at least one fixed-seed company with packet paragraphs, cross references, and multi-section story placement.")


func _validate_annual_report(company_id: String, annual: Dictionary) -> Dictionary:
	if company_id.strip_edges().is_empty() or annual.is_empty():
		return _case_fail("Expected selected annual statement.")
	var contract: Dictionary = annual.get("document_reading_contract", {}) if typeof(annual.get("document_reading_contract", {})) == TYPE_DICTIONARY else {}
	if str(contract.get("page_size_hint", "")) != "A4":
		return _case_fail("Expected A4 annual report contract.")
	if _string_array(contract.get("section_order", [])) != _string_array(EXPECTED_SECTION_IDS):
		return _case_fail("Annual report section order changed.")
	if _string_array(contract.get("readable_section_ids", [])) != _string_array(EXPECTED_SECTION_IDS):
		return _case_fail("Annual report readable sections changed.")
	if not _variant_array(contract.get("compact_until_revision_section_ids", [])).is_empty():
		return _case_fail("Annual report should not have compact R3 sections.")

	var toc_rows: Array = _variant_array(annual.get("table_of_contents", []))
	if toc_rows.size() != EXPECTED_SECTION_IDS.size():
		return _case_fail("Expected %d annual report TOC rows." % EXPECTED_SECTION_IDS.size())
	for index in range(EXPECTED_SECTION_IDS.size()):
		var expected_section_id: String = str(EXPECTED_SECTION_IDS[index])
		var toc: Dictionary = toc_rows[index] if typeof(toc_rows[index]) == TYPE_DICTIONARY else {}
		if str(toc.get("section_id", "")) != expected_section_id:
			return _case_fail("TOC order changed at index %d." % index)
		if str(toc.get("page_label", "")) != str(EXPECTED_PAGE_LABELS.get(expected_section_id, "")):
			return _case_fail("TOC page label changed for %s." % expected_section_id)

	if _variant_array(annual.get("notes", [])).size() != EXPECTED_NOTE_COUNT:
		return _case_fail("Expected %d annual notes." % EXPECTED_NOTE_COUNT)
	var traceability: Dictionary = annual.get("traceability", {}) if typeof(annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	if str(traceability.get("disclosure_packet_render_status", "")) != EXPECTED_PACKET_RENDER_STATUS:
		return _case_fail("Expected R3.5 packet render traceability status.")
	if int(traceability.get("disclosure_packet_render_visible_paragraph_count", 0)) <= 0:
		return _case_fail("Expected visible packet paragraph count in traceability.")
	if _packet_ref_count(annual) <= 0 or _packet_paragraph_count(annual) <= 0:
		return _case_fail("Expected packet refs and packet paragraphs.")
	if _cross_reference_count(annual) <= 0:
		return _case_fail("Expected cross-note references.")
	if _multi_section_story_count(annual) <= 0:
		return _case_fail("Expected at least one story across multiple annual report sections.")

	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			return _case_fail("Expected note dictionaries.")
		var note: Dictionary = note_value
		var visible_text: String = _visible_note_text(note)
		for hidden_token in HIDDEN_VISIBLE_TOKENS:
			if visible_text.contains(str(hidden_token)):
				return _case_fail("Visible annual report note leaked hidden token %s." % str(hidden_token))
		var packet_ids: Array = _packet_ids_for_note(note)
		if not packet_ids.is_empty():
			var paragraph_packet_ids: Array = []
			for paragraph_value in _packet_paragraphs(note):
				if typeof(paragraph_value) == TYPE_DICTIONARY:
					paragraph_packet_ids.append_array(_string_array(paragraph_value.get("source_disclosure_packet_ids", [])))
			for packet_id_value in packet_ids:
				if not paragraph_packet_ids.has(str(packet_id_value)):
					return _case_fail("Packet %s was mapped to a note but not rendered as a paragraph." % str(packet_id_value))
		for ref_value in _variant_array(note.get("cross_note_references", [])):
			if typeof(ref_value) != TYPE_DICTIONARY:
				return _case_fail("Expected cross-note reference dictionaries.")
			var ref: Dictionary = ref_value
			if int(ref.get("target_note_number", 0)) <= 0 or str(ref.get("target_note_type", "")).strip_edges().is_empty():
				return _case_fail("Expected cross-note reference target metadata.")
			if _visible_cross_reference_text(ref).strip_edges().is_empty():
				return _case_fail("Expected visible cross-note reference display text.")
	return _case_ok()


func _run_capture_case(company_id: String, annual_value: Variant) -> Dictionary:
	var annual: Dictionary = annual_value if typeof(annual_value) == TYPE_DICTIONARY else {}
	if annual.is_empty():
		return _case_fail("Expected annual statement for capture case.")
	var thesis_result: Dictionary = GameManager.create_thesis(company_id, "bullish", "position", "Annual Report Fidelity Capture")
	if not bool(thesis_result.get("success", false)):
		return _case_fail("Expected thesis creation to succeed.")
	var thesis_id: String = str(thesis_result.get("thesis", {}).get("id", ""))

	var line_payload: Dictionary = _statement_row_capture_payload(company_id, annual)
	var paragraph_selection: Dictionary = _first_packet_paragraph_selection(annual)
	if not bool(paragraph_selection.get("success", false)):
		return paragraph_selection
	var paragraph_payload: Dictionary = _note_paragraph_capture_payload(company_id, annual, paragraph_selection)
	var reference_selection: Dictionary = _first_cross_reference_selection(annual)
	if not bool(reference_selection.get("success", false)):
		return reference_selection
	var reference_payload: Dictionary = _cross_reference_capture_payload(company_id, annual, reference_selection)
	var capture_rows: Array = [
		{"payload": line_payload, "kind": "statement_row"},
		{"payload": paragraph_payload, "kind": "note_paragraph"},
		{"payload": reference_payload, "kind": "cross_note_reference"}
	]
	var captured_ids: Array = []
	for row_value in capture_rows:
		var row: Dictionary = row_value
		var payload: Dictionary = row.get("payload", {}) if typeof(row.get("payload", {})) == TYPE_DICTIONARY else {}
		var kind: String = str(row.get("kind", ""))
		var normalized: Dictionary = THESIS_EVIDENCE_CAPTURE_SYSTEM.new().normalize_capture(payload)
		var normalized_result: Dictionary = _validate_capture_row(kind, normalized, annual, paragraph_selection, reference_selection)
		if not bool(normalized_result.get("success", false)):
			return normalized_result
		var capture_result: Dictionary = GameManager.capture_research_evidence(payload)
		if not bool(capture_result.get("success", false)):
			return _case_fail("Expected %s evidence capture to succeed: %s" % [kind, str(capture_result.get("message", ""))])
		var evidence: Dictionary = capture_result.get("evidence", {}) if typeof(capture_result.get("evidence", {})) == TYPE_DICTIONARY else {}
		var evidence_result: Dictionary = _validate_capture_row(kind, evidence, annual, paragraph_selection, reference_selection)
		if not bool(evidence_result.get("success", false)):
			return evidence_result
		captured_ids.append(str(evidence.get("id", "")))
		var attach_result: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(evidence.get("id", "")), "support")
		if not bool(attach_result.get("success", false)):
			return _case_fail("Expected %s evidence to attach to thesis." % kind)
		var attach_validation: Dictionary = _validate_capture_row(kind, attach_result.get("evidence", {}), annual, paragraph_selection, reference_selection)
		if not bool(attach_validation.get("success", false)):
			return attach_validation

	var direct_add: Dictionary = GameManager.add_thesis_evidence(thesis_id, reference_payload.merged({"interpretation": "support"}, true))
	if not bool(direct_add.get("success", false)):
		return _case_fail("Expected direct cross-reference evidence add to succeed.")
	var direct_validation: Dictionary = _validate_capture_row("cross_note_reference", direct_add.get("evidence", {}), annual, paragraph_selection, reference_selection)
	if not bool(direct_validation.get("success", false)):
		return direct_validation

	var save_payload: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(save_payload)
	for captured_id_value in captured_ids:
		var loaded_evidence: Dictionary = RunState.get_research_evidence(str(captured_id_value))
		if loaded_evidence.is_empty():
			return _case_fail("Expected captured evidence %s after save/load." % str(captured_id_value))
	var loaded_thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if loaded_thesis.is_empty():
		return _case_fail("Expected thesis after save/load.")
	var found_cross_reference: bool = false
	for evidence_value in _variant_array(loaded_thesis.get("evidence", [])):
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var evidence: Dictionary = evidence_value
		if str(evidence.get("capture_level", "")) == "cross_note_reference":
			found_cross_reference = true
			var loaded_validation: Dictionary = _validate_capture_row("cross_note_reference", evidence, annual, paragraph_selection, reference_selection)
			if not bool(loaded_validation.get("success", false)):
				return loaded_validation
	if not found_cross_reference:
		return _case_fail("Expected attached/direct cross-reference evidence after save/load.")
	return {"success": true, "capture_count": capture_rows.size()}


func _validate_capture_row(kind: String, row_value: Variant, annual: Dictionary, paragraph_selection: Dictionary, reference_selection: Dictionary) -> Dictionary:
	var row: Dictionary = row_value if typeof(row_value) == TYPE_DICTIONARY else {}
	if row.is_empty():
		return _case_fail("Expected %s capture row." % kind)
	if str(row.get("statement_scope", "")) != "annual" or not bool(row.get("statement_consolidated", false)):
		return _case_fail("Expected %s capture to preserve annual consolidated scope." % kind)
	if str(row.get("statement_id", "")) != str(annual.get("statement_id", "")):
		return _case_fail("Expected %s capture to preserve annual statement id." % kind)
	match kind:
		"statement_row":
			if str(row.get("statement_section", "")) != "profit_or_loss_and_oci" or str(row.get("metric_id", "")) != "revenue":
				return _case_fail("Expected statement-row capture to preserve revenue section metadata.")
			if not str(row.get("line_id", "")).begins_with("line|annual_statement|"):
				return _case_fail("Expected statement-row capture to preserve annual line id.")
			if not is_equal_approx(float(row.get("raw_value", 0.0)), _annual_line_value(annual, "profit_or_loss_and_oci", "revenue")):
				return _case_fail("Expected statement-row capture to preserve raw annual value.")
		"note_paragraph":
			var paragraph: Dictionary = paragraph_selection.get("paragraph", {}) if typeof(paragraph_selection.get("paragraph", {})) == TYPE_DICTIONARY else {}
			if str(row.get("capture_level", "")) != "note_paragraph":
				return _case_fail("Expected note paragraph capture_level.")
			if str(row.get("note_paragraph_id", "")) != str(paragraph.get("paragraph_id", "")):
				return _case_fail("Expected note paragraph capture to preserve paragraph id.")
			if str(row.get("note_paragraph_role", "")) != "disclosure_packet":
				return _case_fail("Expected packet paragraph capture to preserve paragraph role.")
			if str(row.get("note_paragraph_text", "")).strip_edges() != str(paragraph.get("text", "")).strip_edges():
				return _case_fail("Expected packet paragraph capture to preserve visible paragraph text.")
			if _string_array(row.get("source_disclosure_packet_ids", [])) != _string_array(paragraph.get("source_disclosure_packet_ids", [])):
				return _case_fail("Expected packet paragraph capture to preserve packet ids.")
			if str(row.get("disclosure_subtlety", "")) != str(paragraph.get("disclosure_subtlety", "")):
				return _case_fail("Expected packet paragraph capture to preserve subtlety.")
			if _variant_array(row.get("disclosure_packet_refs", [])).is_empty():
				return _case_fail("Expected packet paragraph capture to preserve packet refs.")
		"cross_note_reference":
			var reference: Dictionary = reference_selection.get("reference", {}) if typeof(reference_selection.get("reference", {})) == TYPE_DICTIONARY else {}
			if str(row.get("capture_level", "")) != "cross_note_reference":
				return _case_fail("Expected cross-note capture_level.")
			if str(row.get("cross_reference_target_note_type", "")) != str(reference.get("target_note_type", "")):
				return _case_fail("Expected cross-note capture to preserve target note type.")
			if str(row.get("cross_reference_target_note_number", "")) != str(reference.get("target_note_number", "")):
				return _case_fail("Expected cross-note capture to preserve target note number.")
			if str(row.get("cross_reference_display_text", "")) != _visible_cross_reference_text(reference):
				return _case_fail("Expected cross-note capture to preserve display text.")
			if str(row.get("cross_reference_reason", "")) != str(reference.get("reason", "")):
				return _case_fail("Expected cross-note capture to preserve reason.")
	return _case_ok()


func _statement_row_capture_payload(company_id: String, annual: Dictionary) -> Dictionary:
	var line_item: Dictionary = _annual_line(annual, "profit_or_loss_and_oci", "revenue")
	return {
		"source_type": "financial_statement",
		"category": "financials",
		"company_id": company_id,
		"label": str(line_item.get("label", "Revenue")),
		"value": "Annual revenue",
		"detail": "Revenue line from annual consolidated statement (%s)." % str(annual.get("statement_period_label", "FY2019")),
		"source_id": "r3_6_statement_row_%s_%s" % [company_id, _token(str(line_item.get("line_id", "")))],
		"statement_id": str(annual.get("statement_id", "")),
		"statement_period_label": str(annual.get("statement_period_label", "FY2019")),
		"statement_scope": "annual",
		"statement_consolidated": true,
		"statement_year": str(annual.get("statement_year", annual.get("fiscal_year", ""))),
		"statement_quarter": "",
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


func _note_paragraph_capture_payload(company_id: String, annual: Dictionary, selection: Dictionary) -> Dictionary:
	var note: Dictionary = selection.get("note", {}) if typeof(selection.get("note", {})) == TYPE_DICTIONARY else {}
	var paragraph: Dictionary = selection.get("paragraph", {}) if typeof(selection.get("paragraph", {})) == TYPE_DICTIONARY else {}
	var payload: Dictionary = _note_capture_payload(company_id, annual, note)
	var paragraph_index: int = int(paragraph.get("paragraph_index", 1))
	var paragraph_text: String = str(paragraph.get("text", "")).strip_edges()
	payload["label"] = "Note %d packet paragraph %d" % [int(note.get("note_number", 0)), paragraph_index]
	payload["value"] = paragraph_text
	payload["detail"] = paragraph_text
	payload["source_id"] = "r3_6_packet_paragraph_%s_%s_%02d" % [company_id, _token(str(note.get("note_id", ""))), paragraph_index]
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


func _cross_reference_capture_payload(company_id: String, annual: Dictionary, selection: Dictionary) -> Dictionary:
	var note: Dictionary = selection.get("note", {}) if typeof(selection.get("note", {})) == TYPE_DICTIONARY else {}
	var ref: Dictionary = selection.get("reference", {}) if typeof(selection.get("reference", {})) == TYPE_DICTIONARY else {}
	var payload: Dictionary = _note_capture_payload(company_id, annual, note)
	var reference_index: int = max(int(selection.get("reference_index", 1)), 1)
	var display_text: String = _visible_cross_reference_text(ref)
	payload["label"] = "Note %d cross-reference %d" % [int(note.get("note_number", 0)), reference_index]
	payload["value"] = display_text
	payload["detail"] = str(ref.get("reason", "related annual report disclosure"))
	payload["source_id"] = "r3_6_cross_reference_%s_%s_%02d" % [company_id, _token(str(note.get("note_id", ""))), reference_index]
	payload["capture_level"] = "cross_note_reference"
	payload["cross_reference_target_note_type"] = str(ref.get("target_note_type", ""))
	payload["cross_reference_target_note_number"] = str(ref.get("target_note_number", ""))
	payload["cross_reference_target_title"] = str(ref.get("target_title", ""))
	payload["cross_reference_reason"] = str(ref.get("reason", ""))
	payload["cross_reference_display_text"] = display_text
	return payload


func _note_capture_payload(company_id: String, annual: Dictionary, note: Dictionary) -> Dictionary:
	var tone: String = str(note.get("tone", "neutral"))
	var metric_ids: Array = _string_array(note.get("metric_ids", []))
	return {
		"source_type": "financial_statement",
		"category": "financials",
		"company_id": company_id,
		"label": str(note.get("title", note.get("note_id", "annual note"))),
		"value": str(note.get("disclosure_quality", "partial")),
		"detail": str(note.get("body_text", note.get("summary", ""))),
		"source_id": "r3_6_note_%s_%s" % [company_id, _token(str(note.get("note_id", "")))],
		"statement_id": str(annual.get("statement_id", "")),
		"statement_period_label": str(annual.get("statement_period_label", "FY2019")),
		"statement_scope": "annual",
		"statement_consolidated": true,
		"statement_year": str(annual.get("statement_year", annual.get("fiscal_year", ""))),
		"statement_quarter": "",
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
		"metric_id": str(metric_ids[0]) if not metric_ids.is_empty() else str(note.get("metric_id", "")),
		"metric_ids": metric_ids,
		"effect_ids": _string_array(note.get("effect_ids", [])),
		"clue_ids": _string_array(note.get("clue_ids", [])),
		"fact_ids": _string_array(note.get("fact_ids", [])),
		"source_story_ids": _string_array(note.get("source_story_ids", [])),
		"source_effect_ids": _string_array(note.get("source_effect_ids", [])),
		"source_disclosure_packet_ids": _string_array(note.get("source_disclosure_packet_ids", [])),
		"source_disclosure_placement_ids": _string_array(note.get("source_disclosure_placement_ids", [])),
		"source_disclosure_section_ids": _string_array(note.get("source_disclosure_section_ids", [])),
		"source_statement_sections": _string_array(note.get("source_statement_sections", [])),
		"story_source_refs": _variant_array(note.get("story_source_refs", [])),
		"disclosure_packet_refs": _variant_array(note.get("disclosure_packet_refs", [])),
		"explain_tags": _string_array(note.get("explain_tags", [])),
		"raw_value": float(note.get("importance", 0.0)),
		"importance": float(note.get("importance", 0.0)),
		"direction": tone,
		"tone": tone,
		"vocabulary_tags": ["financial_statement", "filing", "annual", "consolidated", "notes"]
	}


func _fidelity_payload(company_id: String, annual: Dictionary) -> String:
	var lines: Array[String] = []
	var traceability: Dictionary = annual.get("traceability", {}) if typeof(annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	lines.append("company=%s" % company_id)
	lines.append("statement=%s:%s" % [str(annual.get("statement_id", "")), str(annual.get("statement_period_label", ""))])
	lines.append("trace=%s:%d:%d" % [
		str(traceability.get("disclosure_packet_render_status", "")),
		int(traceability.get("disclosure_packet_render_visible_paragraph_count", 0)),
		int(traceability.get("filing_note_body_cross_reference_count", 0))
	])
	for row_value in _variant_array(annual.get("table_of_contents", [])):
		if typeof(row_value) == TYPE_DICTIONARY:
			var row: Dictionary = row_value
			lines.append("toc:%s:%s:%s" % [
				str(row.get("section_id", "")),
				str(row.get("page_label", "")),
				str(row.get("title", ""))
			])
	lines.append("line:revenue:%s" % _float_token(_annual_line_value(annual, "profit_or_loss_and_oci", "revenue")))
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		lines.append("note:%02d:%s:%d:%d:%d" % [
			int(note.get("note_number", 0)),
			str(note.get("note_type", "")),
			_variant_array(note.get("body_paragraphs", [])).size(),
			_packet_paragraphs(note).size(),
			_variant_array(note.get("cross_note_references", [])).size()
		])
		for paragraph_value in _packet_paragraphs(note):
			if typeof(paragraph_value) == TYPE_DICTIONARY:
				var paragraph: Dictionary = paragraph_value
				lines.append("packet:%s:%s:%s:%s:%s:%s" % [
					str(note.get("note_type", "")),
					str(paragraph.get("story_id", "")),
					str(paragraph.get("disclosure_packet_id", "")),
					str(paragraph.get("disclosure_section_id", "")),
					str(paragraph.get("disclosure_subtlety", "")),
					"|".join(_string_array(paragraph.get("metric_ids", [])))
				])
		for ref_value in _variant_array(note.get("cross_note_references", [])):
			if typeof(ref_value) == TYPE_DICTIONARY:
				var ref: Dictionary = ref_value
				lines.append("ref:%s:%02d:%s:%s" % [
					str(note.get("note_type", "")),
					int(ref.get("target_note_number", 0)),
					str(ref.get("target_note_type", "")),
					str(ref.get("reason", ""))
				])
	lines.append("multi_section_story_count=%d" % _multi_section_story_count(annual))
	return "\n".join(lines)


func _first_packet_paragraph_selection(annual: Dictionary) -> Dictionary:
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		for paragraph_value in _packet_paragraphs(note):
			if typeof(paragraph_value) == TYPE_DICTIONARY:
				return {"success": true, "note": note.duplicate(true), "paragraph": paragraph_value.duplicate(true)}
	return _case_fail("Expected packet paragraph selection.")


func _first_cross_reference_selection(annual: Dictionary) -> Dictionary:
	var fallback: Dictionary = {}
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		var references: Array = _variant_array(note.get("cross_note_references", []))
		for index in range(references.size()):
			if typeof(references[index]) != TYPE_DICTIONARY:
				continue
			var selected: Dictionary = {
				"success": true,
				"note": note.duplicate(true),
				"reference": references[index].duplicate(true),
				"reference_index": index + 1
			}
			if not _string_array(note.get("source_disclosure_packet_ids", [])).is_empty():
				return selected
			if fallback.is_empty():
				fallback = selected
	if not fallback.is_empty():
		return fallback
	return _case_fail("Expected cross-reference selection.")


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


func _packet_ref_count(annual: Dictionary) -> int:
	var count: int = 0
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) == TYPE_DICTIONARY:
			count += _packet_ids_for_note(note_value).size()
	return count


func _packet_paragraph_count(annual: Dictionary) -> int:
	var count: int = 0
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) == TYPE_DICTIONARY:
			count += _packet_paragraphs(note_value).size()
	return count


func _cross_reference_count(annual: Dictionary) -> int:
	var count: int = 0
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) == TYPE_DICTIONARY:
			count += _variant_array(note_value.get("cross_note_references", [])).size()
	return count


func _multi_section_story_count(annual: Dictionary) -> int:
	var story_sections: Dictionary = {}
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		for paragraph_value in _packet_paragraphs(note_value):
			if typeof(paragraph_value) != TYPE_DICTIONARY:
				continue
			var paragraph: Dictionary = paragraph_value
			var story_id: String = str(paragraph.get("story_id", "")).strip_edges()
			var section_id: String = str(paragraph.get("disclosure_section_id", "")).strip_edges()
			if story_id.is_empty() or section_id.is_empty():
				continue
			if not story_sections.has(story_id):
				story_sections[story_id] = []
			if not story_sections[story_id].has(section_id):
				story_sections[story_id].append(section_id)
	var count: int = 0
	for story_id_value in story_sections.keys():
		if _variant_array(story_sections.get(story_id_value, [])).size() >= 2:
			count += 1
	return count


func _packet_paragraphs(note: Dictionary) -> Array:
	var rows: Array = []
	for paragraph_value in _variant_array(note.get("body_paragraphs", [])):
		if typeof(paragraph_value) != TYPE_DICTIONARY:
			continue
		var paragraph: Dictionary = paragraph_value
		if str(paragraph.get("paragraph_role", "")) == "disclosure_packet":
			rows.append(paragraph.duplicate(true))
	return rows


func _packet_ids_for_note(note: Dictionary) -> Array:
	var packet_ids: Array = _string_array(note.get("source_disclosure_packet_ids", []))
	for ref_value in _variant_array(note.get("disclosure_packet_refs", [])):
		if typeof(ref_value) != TYPE_DICTIONARY:
			continue
		var ref: Dictionary = ref_value
		var packet_id: String = str(ref.get("packet_id", ref.get("disclosure_packet_id", ""))).strip_edges()
		if not packet_id.is_empty() and not packet_ids.has(packet_id):
			packet_ids.append(packet_id)
	packet_ids.sort()
	return packet_ids


func _visible_note_text(note: Dictionary) -> String:
	var parts: Array[String] = []
	parts.append(str(note.get("body_text", "")))
	parts.append(str(note.get("visible_cross_reference_text", "")))
	for paragraph_value in _variant_array(note.get("body_paragraphs", [])):
		if typeof(paragraph_value) == TYPE_DICTIONARY:
			parts.append(str(paragraph_value.get("text", "")))
	for ref_value in _variant_array(note.get("cross_note_references", [])):
		if typeof(ref_value) == TYPE_DICTIONARY:
			parts.append(_visible_cross_reference_text(ref_value))
			parts.append(str(ref_value.get("reason", "")))
	return "\n".join(parts)


func _visible_cross_reference_text(ref: Dictionary) -> String:
	var display_text: String = str(ref.get("display_text", "")).strip_edges()
	if not display_text.is_empty():
		return display_text
	return "See Note %d - %s." % [
		int(ref.get("target_note_number", 0)),
		str(ref.get("target_title", ref.get("target_note_type", ""))).strip_edges()
	]


func _float_token(value: float) -> String:
	return "%.4f" % value


func _token(value: String) -> String:
	return value.strip_edges().to_lower().replace("|", "_").replace(" ", "_").replace("/", "_")


func _case_ok() -> Dictionary:
	return {"success": true}


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
	print("ANNUAL_REPORT_FIDELITY_CAPTURE_FAIL: %s" % message)
	get_tree().quit(1)
