extends Node

const THESIS_EVIDENCE_CAPTURE_SYSTEM = preload("res://systems/ThesisEvidenceCaptureSystem.gd")

const RUN_SEED := 20260615
const CATALOG_COMPANY_COUNT := 30
const EXPECTED_HASH := "36249412"
const EXPECTED_NOTE_COUNT := 14
const EXPECTED_BODY_SCHEMA_VERSION := 1
const EXPECTED_BODY_STATUS := "r3_3_filing_note_body_ready"
const EXPECTED_PACKET_RENDER_STATUS := "r3_5_story_dossier_packets_consumed"
const VALID_SUBTLETIES := ["direct", "implied", "buried", "conflicting", "missing"]
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

	var first_report: Dictionary = _build_report()
	if not bool(first_report.get("success", false)):
		_fail(str(first_report.get("message", "annual filing note body test failed")))
		return
	var second_report: Dictionary = _build_report()
	if not bool(second_report.get("success", false)):
		_fail(str(second_report.get("message", "repeated annual filing note body test failed")))
		return
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Annual filing note body payload changed across repeated fixed-seed runs.")
		return

	var hash: String = _stable_hash(str(first_report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual filing note body hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_STATEMENT_FILING_NOTE_BODY_OK %s" % JSON.stringify({
		"hash": hash,
		"company_id": str(first_report.get("company_id", "")),
		"note_count": int(first_report.get("note_count", 0)),
		"body_count": int(first_report.get("body_count", 0)),
		"packet_ref_count": int(first_report.get("packet_ref_count", 0)),
		"packet_paragraph_count": int(first_report.get("packet_paragraph_count", 0)),
		"cross_reference_count": int(first_report.get("cross_reference_count", 0))
	}))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = CATALOG_COMPANY_COUNT
	difficulty_config["use_company_universe_catalog"] = true
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0

	var selected: Dictionary = _first_annual_with_packet_refs()
	if not bool(selected.get("success", false)):
		return selected
	var company_id: String = str(selected.get("company_id", ""))
	var annual: Dictionary = selected.get("annual", {}) if typeof(selected.get("annual", {})) == TYPE_DICTIONARY else {}
	var validation: Dictionary = _validate_annual(company_id, annual)
	if not bool(validation.get("success", false)):
		return validation
	var payload: String = _body_payload(company_id, annual)
	return {
		"success": true,
		"company_id": company_id,
		"payload": payload,
		"note_count": _variant_array(annual.get("notes", [])).size(),
		"body_count": _filing_body_count(annual),
		"packet_ref_count": _packet_ref_count(annual),
		"packet_paragraph_count": _packet_paragraph_count(annual),
		"cross_reference_count": _cross_reference_count(annual)
	}


func _first_annual_with_packet_refs() -> Dictionary:
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		if not RunState.ensure_company_full_detail(company_id):
			continue
		RunState.refresh_annual_statement_post_start_enrichment(company_id)
		var annual: Dictionary = _annual_for_company(company_id)
		if annual.is_empty():
			continue
		if _packet_ref_count(annual) > 0:
			return {"success": true, "company_id": company_id, "annual": annual}
	return _case_fail("Expected at least one company annual statement with disclosure packet refs.")


func _validate_annual(company_id: String, annual: Dictionary) -> Dictionary:
	var notes: Array = _variant_array(annual.get("notes", []))
	if notes.size() != EXPECTED_NOTE_COUNT:
		return _case_fail("Expected %d notes, got %d." % [EXPECTED_NOTE_COUNT, notes.size()])
	var traceability: Dictionary = annual.get("traceability", {}) if typeof(annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	if int(traceability.get("filing_note_body_schema_version", 0)) != EXPECTED_BODY_SCHEMA_VERSION:
		return _case_fail("Expected statement traceability filing body schema version.")
	if str(traceability.get("filing_note_body_status", "")) != EXPECTED_BODY_STATUS:
		return _case_fail("Expected statement traceability filing body status.")
	if _variant_array(traceability.get("filing_note_body_note_ids", [])).size() != EXPECTED_NOTE_COUNT:
		return _case_fail("Expected traceability to list all note body ids.")
	if int(traceability.get("filing_note_body_cross_reference_count", 0)) <= 0:
		return _case_fail("Expected statement traceability cross-reference count.")
	if int(traceability.get("disclosure_packet_render_schema_version", 0)) != 1:
		return _case_fail("Expected disclosure packet render schema version.")
	if str(traceability.get("disclosure_packet_render_status", "")) != EXPECTED_PACKET_RENDER_STATUS:
		return _case_fail("Expected disclosure packet render status.")
	if _variant_array(traceability.get("disclosure_packet_render_packet_ids", [])).is_empty():
		return _case_fail("Expected disclosure packet render packet ids.")
	if _variant_array(traceability.get("disclosure_packet_render_story_ids", [])).is_empty():
		return _case_fail("Expected disclosure packet render story ids.")
	if int(traceability.get("disclosure_packet_render_visible_paragraph_count", 0)) <= 0:
		return _case_fail("Expected disclosure packet render visible paragraphs.")

	var contract: Dictionary = annual.get("document_reading_contract", {}) if typeof(annual.get("document_reading_contract", {})) == TYPE_DICTIONARY else {}
	if not _string_array(contract.get("readable_section_ids", [])).has("notes"):
		return _case_fail("Expected notes to be readable after R3.3.")
	if not _variant_array(contract.get("compact_until_revision_section_ids", [])).is_empty():
		return _case_fail("Expected no compact-until-revision sections after R3.3.")

	var capture_system = THESIS_EVIDENCE_CAPTURE_SYSTEM.new()
	var saw_packet_note: bool = false
	var saw_packet_paragraph: bool = false
	var saw_cross_reference: bool = false
	var saw_compact_table: bool = false
	for note_value in notes:
		if typeof(note_value) != TYPE_DICTIONARY:
			return _case_fail("Expected note dictionaries.")
		var note: Dictionary = note_value
		var body: Dictionary = note.get("filing_note_body", {}) if typeof(note.get("filing_note_body", {})) == TYPE_DICTIONARY else {}
		if int(body.get("schema_version", 0)) != EXPECTED_BODY_SCHEMA_VERSION:
			return _case_fail("Expected filing body schema version on %s." % str(note.get("note_type", "")))
		if str(body.get("body_status", "")) != EXPECTED_BODY_STATUS:
			return _case_fail("Expected filing body status on %s." % str(note.get("note_type", "")))
		if str(body.get("disclosure_packet_render_status", "")) != EXPECTED_PACKET_RENDER_STATUS:
			return _case_fail("Expected disclosure packet render status on %s." % str(note.get("note_type", "")))
		if bool(body.get("hidden_source_ids_visible", true)):
			return _case_fail("Hidden source ids must not be visible for %s." % str(note.get("note_type", "")))
		if _variant_array(note.get("body_paragraphs", [])).size() < 2:
			return _case_fail("Expected note body paragraphs for %s." % str(note.get("note_type", "")))
		var visible_text: String = _visible_note_text(note)
		if visible_text.strip_edges().is_empty():
			return _case_fail("Expected visible body text for %s." % str(note.get("note_type", "")))
		for hidden_token in HIDDEN_VISIBLE_TOKENS:
			if visible_text.contains(str(hidden_token)):
				return _case_fail("Visible note text leaked hidden token %s in %s." % [str(hidden_token), str(note.get("note_type", ""))])
		saw_cross_reference = saw_cross_reference or not _variant_array(note.get("cross_note_references", [])).is_empty()
		saw_compact_table = saw_compact_table or not _variant_array(note.get("compact_tables", [])).is_empty()
		for ref_value in _variant_array(note.get("cross_note_references", [])):
			if typeof(ref_value) != TYPE_DICTIONARY:
				return _case_fail("Expected cross-note reference dictionaries.")
			var ref: Dictionary = ref_value
			if str(ref.get("target_note_type", "")).strip_edges().is_empty() or int(ref.get("target_note_number", 0)) <= 0:
				return _case_fail("Expected cross-note target metadata.")
			if JSON.stringify(ref).contains("story|") or JSON.stringify(ref).contains("packet|"):
				return _case_fail("Cross-note reference leaked source ids.")
		if not _variant_array(note.get("disclosure_packet_refs", [])).is_empty():
			saw_packet_note = true
			var packet_paragraphs: Array = _packet_paragraphs(note)
			if packet_paragraphs.is_empty():
				return _case_fail("Expected visible disclosure packet paragraphs for %s." % str(note.get("note_type", "")))
			for paragraph_value in packet_paragraphs:
				if typeof(paragraph_value) != TYPE_DICTIONARY:
					return _case_fail("Expected packet paragraph dictionaries.")
				var paragraph: Dictionary = paragraph_value
				saw_packet_paragraph = true
				var paragraph_text: String = str(paragraph.get("text", ""))
				for hidden_token in HIDDEN_VISIBLE_TOKENS:
					if paragraph_text.contains(str(hidden_token)):
						return _case_fail("Visible packet paragraph leaked hidden token %s in %s." % [str(hidden_token), str(note.get("note_type", ""))])
				if not VALID_SUBTLETIES.has(str(paragraph.get("disclosure_subtlety", ""))):
					return _case_fail("Expected packet paragraph subtlety metadata for %s." % str(note.get("note_type", "")))
				if _string_array(paragraph.get("source_disclosure_packet_ids", [])).is_empty():
					return _case_fail("Expected packet paragraph source packet ids for %s." % str(note.get("note_type", "")))
				if _variant_array(paragraph.get("disclosure_packet_refs", [])).is_empty():
					return _case_fail("Expected packet paragraph disclosure packet refs for %s." % str(note.get("note_type", "")))
				var normalized_paragraph_evidence: Dictionary = capture_system.normalize_capture(_capture_payload_for_packet_paragraph(company_id, note, paragraph))
				if _array_payload(normalized_paragraph_evidence.get("source_disclosure_packet_ids", [])) != _array_payload(paragraph.get("source_disclosure_packet_ids", [])):
					return _case_fail("Packet paragraph capture did not preserve packet ids for %s." % str(note.get("note_type", "")))
				if str(normalized_paragraph_evidence.get("disclosure_subtlety", "")) != str(paragraph.get("disclosure_subtlety", "")):
					return _case_fail("Packet paragraph capture did not preserve subtlety for %s." % str(note.get("note_type", "")))
			var normalized_evidence: Dictionary = capture_system.normalize_capture(_capture_payload_for_note(company_id, note))
			if _array_payload(normalized_evidence.get("source_disclosure_packet_ids", [])) != _array_payload(note.get("source_disclosure_packet_ids", [])):
				return _case_fail("Capture did not preserve packet ids for %s." % str(note.get("note_type", "")))
			if _variant_array(normalized_evidence.get("disclosure_packet_refs", [])).is_empty():
				return _case_fail("Capture did not preserve packet refs for %s." % str(note.get("note_type", "")))
	if not saw_packet_note:
		return _case_fail("Expected at least one note with disclosure packet refs.")
	if not saw_packet_paragraph:
		return _case_fail("Expected at least one disclosure packet paragraph.")
	if not saw_cross_reference:
		return _case_fail("Expected at least one note with cross-note references.")
	if not saw_compact_table:
		return _case_fail("Expected at least one compact table.")
	return _case_ok()


func _capture_payload_for_note(company_id: String, note: Dictionary) -> Dictionary:
	return {
		"source_type": "financial_statement",
		"category": "financials",
		"company_id": company_id,
		"label": str(note.get("title", note.get("note_id", "annual note"))),
		"value": str(note.get("disclosure_quality", "partial")),
		"detail": str(note.get("body_text", note.get("summary", ""))),
		"source_id": "r3_3_%s_%s" % [company_id, str(note.get("note_id", note.get("note_type", "note")))],
		"statement_section": "notes",
		"note_id": str(note.get("note_id", "")),
		"note_type": str(note.get("note_type", "")),
		"source_story_ids": _string_array(note.get("source_story_ids", [])),
		"source_effect_ids": _string_array(note.get("source_effect_ids", [])),
		"source_disclosure_packet_ids": _string_array(note.get("source_disclosure_packet_ids", [])),
		"source_disclosure_placement_ids": _string_array(note.get("source_disclosure_placement_ids", [])),
		"source_disclosure_section_ids": _string_array(note.get("source_disclosure_section_ids", [])),
		"fact_ids": _string_array(note.get("fact_ids", [])),
		"effect_ids": _string_array(note.get("effect_ids", [])),
		"clue_ids": _string_array(note.get("clue_ids", [])),
		"story_source_refs": _variant_array(note.get("story_source_refs", [])),
		"disclosure_packet_refs": _variant_array(note.get("disclosure_packet_refs", []))
	}


func _capture_payload_for_packet_paragraph(company_id: String, note: Dictionary, paragraph: Dictionary) -> Dictionary:
	var payload: Dictionary = _capture_payload_for_note(company_id, note)
	payload["source_id"] = "%s_%s" % [str(payload.get("source_id", "r3_5_packet_paragraph")), str(paragraph.get("paragraph_index", "0"))]
	payload["label"] = "Note %d packet paragraph %d" % [int(note.get("note_number", 0)), int(paragraph.get("paragraph_index", 0))]
	payload["value"] = str(paragraph.get("text", ""))
	payload["detail"] = str(paragraph.get("text", ""))
	payload["capture_level"] = "note_paragraph"
	payload["note_paragraph_id"] = str(paragraph.get("paragraph_id", ""))
	payload["note_paragraph_index"] = str(paragraph.get("paragraph_index", ""))
	payload["note_paragraph_role"] = str(paragraph.get("paragraph_role", ""))
	payload["note_paragraph_text"] = str(paragraph.get("text", ""))
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


func _body_payload(company_id: String, annual: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("company=%s" % company_id)
	var traceability: Dictionary = annual.get("traceability", {}) if typeof(annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	lines.append("trace:%s:%d:%s" % [
		str(traceability.get("filing_note_body_status", "")),
		int(traceability.get("filing_note_body_cross_reference_count", 0)),
		"|".join(_string_array(traceability.get("filing_note_body_note_ids", [])))
	])
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		var body: Dictionary = note.get("filing_note_body", {}) if typeof(note.get("filing_note_body", {})) == TYPE_DICTIONARY else {}
		lines.append("note:%02d:%s:%s:%d:%d:%d" % [
			int(note.get("note_number", 0)),
			str(note.get("note_type", "")),
			str(body.get("body_status", "")),
			_variant_array(note.get("body_paragraphs", [])).size(),
			_variant_array(note.get("compact_tables", [])).size(),
			_variant_array(note.get("cross_note_references", [])).size()
		])
		for paragraph_value in _variant_array(note.get("body_paragraphs", [])):
			if typeof(paragraph_value) == TYPE_DICTIONARY:
				var paragraph: Dictionary = paragraph_value
				lines.append("paragraph:%s:%s:%s" % [
					str(note.get("note_type", "")),
					str(paragraph.get("paragraph_role", "")),
					str(paragraph.get("text", ""))
				])
				if str(paragraph.get("paragraph_role", "")) == "disclosure_packet":
					lines.append("packet_paragraph:%s:%s:%s:%s:%s" % [
						str(note.get("note_type", "")),
						str(paragraph.get("disclosure_subtlety", "")),
						str(paragraph.get("disclosure_section_id", "")),
						"|".join(_string_array(paragraph.get("source_disclosure_packet_ids", []))),
						"|".join(_string_array(paragraph.get("metric_ids", [])))
					])
		for table_value in _variant_array(note.get("compact_tables", [])):
			if typeof(table_value) != TYPE_DICTIONARY:
				continue
			var table: Dictionary = table_value
			lines.append("table:%s:%s:%d" % [
				str(note.get("note_type", "")),
				str(table.get("title", "")),
				_variant_array(table.get("rows", [])).size()
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
	return "\n".join(lines)


func _visible_note_text(note: Dictionary) -> String:
	var parts: Array[String] = []
	parts.append(str(note.get("body_text", "")))
	parts.append(str(note.get("visible_cross_reference_text", "")))
	for paragraph_value in _variant_array(note.get("body_paragraphs", [])):
		if typeof(paragraph_value) == TYPE_DICTIONARY:
			var paragraph: Dictionary = paragraph_value
			parts.append(str(paragraph.get("text", "")))
	for table_value in _variant_array(note.get("compact_tables", [])):
		if typeof(table_value) != TYPE_DICTIONARY:
			continue
		var table: Dictionary = table_value
		parts.append(str(table.get("title", "")))
		for row_value in _variant_array(table.get("rows", [])):
			if typeof(row_value) == TYPE_DICTIONARY:
				var row: Dictionary = row_value
				parts.append(str(row.get("caption", "")))
				parts.append(str(row.get("fy_value", "")))
				parts.append(str(row.get("related_note", "")))
	for ref_value in _variant_array(note.get("cross_note_references", [])):
		if typeof(ref_value) == TYPE_DICTIONARY:
			var ref: Dictionary = ref_value
			parts.append(str(ref.get("display_text", "")))
			parts.append(str(ref.get("reason", "")))
	return "\n".join(parts)


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


func _filing_body_count(annual: Dictionary) -> int:
	var count: int = 0
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) == TYPE_DICTIONARY:
			var note: Dictionary = note_value
			if typeof(note.get("filing_note_body", {})) == TYPE_DICTIONARY:
				count += 1
	return count


func _packet_paragraph_count(annual: Dictionary) -> int:
	var count: int = 0
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		count += _packet_paragraphs(note_value).size()
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


func _packet_ref_count(annual: Dictionary) -> int:
	var count: int = 0
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) == TYPE_DICTIONARY:
			var note: Dictionary = note_value
			count += _variant_array(note.get("disclosure_packet_refs", [])).size()
	return count


func _cross_reference_count(annual: Dictionary) -> int:
	var count: int = 0
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) == TYPE_DICTIONARY:
			var note: Dictionary = note_value
			count += _variant_array(note.get("cross_note_references", [])).size()
	return count


func _array_payload(source_value: Variant) -> String:
	return "|".join(_string_array(source_value))


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
	print("ANNUAL_STATEMENT_FILING_NOTE_BODY_FAIL: %s" % message)
	get_tree().quit(1)
