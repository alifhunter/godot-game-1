extends Node

const COMPANY_STORY_DOSSIER_SYSTEM = preload("res://systems/CompanyStoryDossierSystem.gd")
const THESIS_EVIDENCE_CAPTURE_SYSTEM = preload("res://systems/ThesisEvidenceCaptureSystem.gd")

const RUN_SEED := 20260615
const CATALOG_COMPANY_COUNT := 30
const EXPECTED_DOSSIER_COUNT := 30
const EXPECTED_FIXTURE_HASH := "623183840"
const EXPECTED_ANNUAL_NOTE_COUNT := 14
const HIDDEN_DISCLOSURE_KEYS := ["truth_state", "disclosure_quality", "reliability", "confidence", "source_quality"]
const VALID_PACKET_ROLES := [
	"primary_evidence",
	"anchor_evidence",
	"supporting_evidence",
	"cross_reference_evidence",
	"challenge_evidence",
	"absence_evidence"
]


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var first_report: Dictionary = _build_report()
	var second_report: Dictionary = _build_report()
	if str(first_report.get("payload", "")) != str(second_report.get("payload", "")):
		_fail("Company story dossier financial statement fixture payload was not stable across repeated fixed-seed runs.")
		return
	if str(first_report.get("hash", "")) != str(second_report.get("hash", "")):
		_fail("Company story dossier financial statement fixture hash was not stable across repeated fixed-seed runs.")
		return
	if int(first_report.get("dossier_count", 0)) != EXPECTED_DOSSIER_COUNT:
		_fail("Expected %d dossiers, got %d." % [EXPECTED_DOSSIER_COUNT, int(first_report.get("dossier_count", 0))])
		return
	if int(first_report.get("issue_count", 0)) != 0:
		_fail("Expected zero financial statement fixture issues, got %d: %s" % [
			int(first_report.get("issue_count", 0)),
			JSON.stringify(first_report.get("issues", []))
		])
		return
	if EXPECTED_FIXTURE_HASH != "BASELINE_PENDING" and str(first_report.get("hash", "")) != EXPECTED_FIXTURE_HASH:
		_fail("Company story dossier financial statement fixture hash changed. expected=%s actual=%s." % [
			EXPECTED_FIXTURE_HASH,
			str(first_report.get("hash", ""))
		])
		return

	first_report.erase("payload")
	print("COMPANY_STORY_DOSSIER_FINANCIAL_STATEMENT_FIXTURE_OK %s" % JSON.stringify(first_report))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	_setup_fixed_seed_run()
	var state: Dictionary = RunState.get_company_story_dossier_state()
	var issues: Array[String] = []
	var disclosure_report: Dictionary = _validate_disclosure_contract(state, issues)
	var annual_report: Dictionary = _validate_annual_statement_fixture(state, issues)
	var payload: String = "%s\n%s" % [
		str(disclosure_report.get("payload", "")),
		str(annual_report.get("payload", ""))
	]
	return {
		"seed": RUN_SEED,
		"dossier_count": int(disclosure_report.get("dossier_count", 0)),
		"placement_count": int(disclosure_report.get("placement_count", 0)),
		"packet_count": int(disclosure_report.get("packet_count", 0)),
		"section_count": int(disclosure_report.get("section_count", 0)),
		"subtlety_count": int(disclosure_report.get("subtlety_count", 0)),
		"fixture_company_id": str(annual_report.get("company_id", "")),
		"fixture_note_packet_ref_count": int(annual_report.get("note_packet_ref_count", 0)),
		"hash": _stable_hash(payload),
		"issue_count": issues.size(),
		"issues": issues,
		"payload": payload
	}


func _setup_fixed_seed_run() -> void:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = CATALOG_COMPANY_COUNT
	difficulty_config["use_company_universe_catalog"] = true
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0


func _validate_disclosure_contract(state: Dictionary, issues: Array[String]) -> Dictionary:
	var dossier_index: Dictionary = state.get("dossier_index", {}) if typeof(state.get("dossier_index", {})) == TYPE_DICTIONARY else {}
	var story_ids: Array = dossier_index.keys()
	story_ids.sort()
	var section_definitions: Dictionary = _section_definitions()
	var valid_subtleties: Array = _valid_subtleties()
	var placement_count: int = 0
	var packet_count: int = 0
	var section_counts: Dictionary = {}
	var subtlety_counts: Dictionary = {}
	var packet_role_counts: Dictionary = {}
	var payload_lines: Array[String] = []

	for story_id_value in story_ids:
		var story_id: String = str(story_id_value)
		var dossier: Dictionary = dossier_index.get(story_id, {}) if typeof(dossier_index.get(story_id, {})) == TYPE_DICTIONARY else {}
		if dossier.is_empty():
			issues.append("missing_dossier:%s" % story_id)
			continue
		var company_id: String = str(dossier.get("company_id", ""))
		var placements: Array = _variant_array(dossier.get("disclosure_placements", []))
		var packets: Array = _variant_array(dossier.get("disclosure_packets", []))
		var placement_ids: Array = _ids_from_rows(placements, "placement_id")
		var packet_ids: Array = _ids_from_rows(packets, "packet_id")
		var section_ids: Array = _ids_from_rows(packets, "section_id")
		placement_count += placements.size()
		packet_count += packets.size()

		if company_id.is_empty():
			issues.append("missing_company:%s" % story_id)
		if placements.is_empty():
			issues.append("missing_placements:%s" % story_id)
		if packets.is_empty():
			issues.append("missing_packets:%s" % story_id)
		if placements.size() != packets.size():
			issues.append("placement_packet_count_mismatch:%s:%d:%d" % [story_id, placements.size(), packets.size()])

		var fact_ids: Array = _ids_from_rows(dossier.get("cause_facts", []), "fact_id")
		var effect_ids: Array = _ids_from_rows(dossier.get("financial_effects", []), "effect_id")
		var clue_ids: Array = []
		clue_ids.append_array(_ids_from_rows(dossier.get("public_clues", []), "clue_id"))
		clue_ids.append_array(_ids_from_rows(dossier.get("private_clues", []), "clue_id"))
		clue_ids.append_array(_ids_from_rows(dossier.get("statement_clues", []), "clue_id"))
		clue_ids = _string_array(clue_ids)

		_validate_placements(story_id, placements, section_definitions, valid_subtleties, issues)
		_validate_packets(story_id, company_id, packets, placement_ids, section_definitions, valid_subtleties, fact_ids, effect_ids, clue_ids, issues)
		_validate_traceability(story_id, dossier, placement_ids, packet_ids, section_ids, issues)

		for packet_value in packets:
			if typeof(packet_value) != TYPE_DICTIONARY:
				continue
			var packet: Dictionary = packet_value
			_increment(section_counts, str(packet.get("section_id", "")))
			_increment(subtlety_counts, str(packet.get("subtlety", "")))
			_increment(packet_role_counts, str(packet.get("packet_role", "")))

		payload_lines.append("story:%s:%s:%s:%s:%s" % [
			story_id,
			company_id,
			_array_payload(placement_ids),
			_array_payload(packet_ids),
			_array_payload(section_ids)
		])

	for subtlety_value in valid_subtleties:
		var subtlety: String = str(subtlety_value)
		if int(subtlety_counts.get(subtlety, 0)) <= 0:
			issues.append("missing_subtlety_band:%s" % subtlety)

	payload_lines.append(_count_payload_line("section_counts", section_counts))
	payload_lines.append(_count_payload_line("subtlety_counts", subtlety_counts))
	payload_lines.append(_count_payload_line("packet_role_counts", packet_role_counts))
	return {
		"dossier_count": story_ids.size(),
		"placement_count": placement_count,
		"packet_count": packet_count,
		"section_count": section_counts.keys().size(),
		"subtlety_count": subtlety_counts.keys().size(),
		"payload": "\n".join(payload_lines)
	}


func _validate_placements(
	story_id: String,
	placements: Array,
	section_definitions: Dictionary,
	valid_subtleties: Array,
	issues: Array[String]
) -> void:
	for placement_value in placements:
		if typeof(placement_value) != TYPE_DICTIONARY:
			issues.append("bad_placement:%s" % story_id)
			continue
		var placement: Dictionary = placement_value
		var placement_id: String = str(placement.get("placement_id", ""))
		var section_id: String = str(placement.get("section_id", ""))
		var annual_note_type: String = str(placement.get("annual_statement_note_type", ""))
		if placement_id.is_empty():
			issues.append("empty_placement_id:%s" % story_id)
		if str(placement.get("story_id", "")) != story_id:
			issues.append("placement_story_mismatch:%s:%s" % [story_id, placement_id])
		if not section_definitions.has(section_id):
			issues.append("invalid_placement_section:%s:%s" % [story_id, section_id])
		elif annual_note_type != str(section_definitions.get(section_id, {}).get("annual_statement_note_type", "")):
			issues.append("placement_note_type_mismatch:%s:%s:%s" % [story_id, section_id, annual_note_type])
		if not valid_subtleties.has(str(placement.get("subtlety", ""))):
			issues.append("invalid_placement_subtlety:%s:%s" % [story_id, str(placement.get("subtlety", ""))])
		_validate_no_hidden_keys("placement", story_id, placement, issues)


func _validate_packets(
	story_id: String,
	company_id: String,
	packets: Array,
	placement_ids: Array,
	section_definitions: Dictionary,
	valid_subtleties: Array,
	fact_ids: Array,
	effect_ids: Array,
	clue_ids: Array,
	issues: Array[String]
) -> void:
	for packet_value in packets:
		if typeof(packet_value) != TYPE_DICTIONARY:
			issues.append("bad_packet:%s" % story_id)
			continue
		var packet: Dictionary = packet_value
		var packet_id: String = str(packet.get("packet_id", ""))
		var placement_id: String = str(packet.get("placement_id", ""))
		var section_id: String = str(packet.get("section_id", ""))
		var annual_note_type: String = str(packet.get("annual_statement_note_type", ""))
		if packet_id.is_empty():
			issues.append("empty_packet_id:%s" % story_id)
		if str(packet.get("story_id", "")) != story_id:
			issues.append("packet_story_mismatch:%s:%s" % [story_id, packet_id])
		if not placement_ids.has(placement_id):
			issues.append("packet_missing_placement:%s:%s:%s" % [story_id, packet_id, placement_id])
		if not section_definitions.has(section_id):
			issues.append("invalid_packet_section:%s:%s" % [story_id, section_id])
		elif annual_note_type != str(section_definitions.get(section_id, {}).get("annual_statement_note_type", "")):
			issues.append("packet_note_type_mismatch:%s:%s:%s" % [story_id, section_id, annual_note_type])
		if not valid_subtleties.has(str(packet.get("subtlety", ""))):
			issues.append("invalid_packet_subtlety:%s:%s" % [story_id, str(packet.get("subtlety", ""))])
		if not VALID_PACKET_ROLES.has(str(packet.get("packet_role", ""))):
			issues.append("invalid_packet_role:%s:%s" % [story_id, str(packet.get("packet_role", ""))])
		_validate_ref_ids("packet_fact", story_id, packet_id, packet.get("fact_ids", []), fact_ids, issues)
		_validate_ref_ids("packet_effect", story_id, packet_id, packet.get("effect_ids", []), effect_ids, issues)
		_validate_ref_ids("packet_clue", story_id, packet_id, packet.get("clue_ids", []), clue_ids, issues)
		_validate_cross_sections(story_id, packet_id, packet.get("cross_reference_section_ids", []), section_definitions, issues)
		_validate_no_hidden_keys("packet", story_id, packet, issues)
		_validate_packet_lookup(story_id, company_id, packet, issues)


func _validate_traceability(
	story_id: String,
	dossier: Dictionary,
	placement_ids: Array,
	packet_ids: Array,
	section_ids: Array,
	issues: Array[String]
) -> void:
	var traceability: Dictionary = dossier.get("traceability", {}) if typeof(dossier.get("traceability", {})) == TYPE_DICTIONARY else {}
	if _array_payload(traceability.get("disclosure_placement_ids", [])) != _array_payload(placement_ids):
		issues.append("traceability_placement_mismatch:%s" % story_id)
	if _array_payload(traceability.get("disclosure_packet_ids", [])) != _array_payload(packet_ids):
		issues.append("traceability_packet_mismatch:%s" % story_id)
	if _array_payload(traceability.get("disclosure_section_ids", [])) != _array_payload(section_ids):
		issues.append("traceability_section_mismatch:%s" % story_id)


func _validate_packet_lookup(story_id: String, company_id: String, packet: Dictionary, issues: Array[String]) -> void:
	var packet_id: String = str(packet.get("packet_id", ""))
	var section_id: String = str(packet.get("section_id", ""))
	if not _rows_contain_id(RunState.get_company_story_disclosure_packets(story_id, section_id), "packet_id", packet_id):
		issues.append("story_section_packet_lookup_missing:%s:%s:%s" % [story_id, section_id, packet_id])
	if not _rows_contain_id(RunState.get_company_story_disclosure_packets_for_company(company_id, section_id), "packet_id", packet_id):
		issues.append("company_section_packet_lookup_missing:%s:%s:%s" % [company_id, section_id, packet_id])
	if not _rows_contain_id(RunState.get_company_story_disclosure_placements(story_id, section_id), "placement_id", str(packet.get("placement_id", ""))):
		issues.append("story_section_placement_lookup_missing:%s:%s:%s" % [story_id, section_id, str(packet.get("placement_id", ""))])
	if not _rows_contain_id(RunState.get_company_story_disclosure_placements_for_company(company_id, section_id), "placement_id", str(packet.get("placement_id", ""))):
		issues.append("company_section_placement_lookup_missing:%s:%s:%s" % [company_id, section_id, str(packet.get("placement_id", ""))])


func _validate_annual_statement_fixture(state: Dictionary, issues: Array[String]) -> Dictionary:
	var company_story_ids: Dictionary = state.get("company_story_ids", {}) if typeof(state.get("company_story_ids", {})) == TYPE_DICTIONARY else {}
	var company_ids: Array = company_story_ids.keys()
	company_ids.sort()
	var fixture_company_id: String = ""
	var fixture_annual: Dictionary = {}
	var fixture_ref_count: int = 0
	for company_id_value in company_ids:
		var company_id: String = str(company_id_value)
		if not RunState.ensure_company_full_detail(company_id):
			issues.append("annual_hydration_failed:%s" % company_id)
			continue
		RunState.refresh_annual_statement_post_start_enrichment(company_id)
		var annual: Dictionary = _annual_for_company(company_id)
		var ref_count: int = _annual_packet_ref_count(annual)
		if ref_count > 0:
			fixture_ref_count = ref_count
			fixture_company_id = company_id
			fixture_annual = annual
			break
	if fixture_company_id.is_empty() or fixture_annual.is_empty():
		issues.append("no_annual_statement_packet_fixture")
		return {"company_id": "", "note_packet_ref_count": 0, "payload": ""}

	if _variant_array(fixture_annual.get("notes", [])).size() != EXPECTED_ANNUAL_NOTE_COUNT:
		issues.append("annual_note_count:%s:%d" % [fixture_company_id, _variant_array(fixture_annual.get("notes", [])).size()])
	var traceability: Dictionary = fixture_annual.get("traceability", {}) if typeof(fixture_annual.get("traceability", {})) == TYPE_DICTIONARY else {}
	if _string_array(traceability.get("post_start_source_disclosure_packet_ids", [])).is_empty():
		issues.append("annual_trace_missing_packet_ids:%s" % fixture_company_id)
	if _string_array(traceability.get("post_start_source_disclosure_placement_ids", [])).is_empty():
		issues.append("annual_trace_missing_placement_ids:%s" % fixture_company_id)
	if _string_array(traceability.get("post_start_source_disclosure_section_ids", [])).is_empty():
		issues.append("annual_trace_missing_section_ids:%s" % fixture_company_id)

	var capture_system = THESIS_EVIDENCE_CAPTURE_SYSTEM.new()
	var payload_lines: Array[String] = ["annual_company:%s" % fixture_company_id]
	for note_value in _variant_array(fixture_annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		var packet_refs: Array = _variant_array(note.get("disclosure_packet_refs", []))
		if packet_refs.is_empty():
			continue
		_validate_annual_note_packet_refs(fixture_company_id, note, issues)
		var normalized_evidence: Dictionary = capture_system.normalize_capture(_capture_payload_for_note(fixture_company_id, note))
		_validate_normalized_evidence(fixture_company_id, note, normalized_evidence, issues)
		payload_lines.append(_annual_note_payload_line(note))

	if fixture_ref_count <= 0:
		issues.append("annual_note_packet_refs_empty:%s" % fixture_company_id)
	payload_lines.append("annual_trace_packets:%s" % _array_payload(traceability.get("post_start_source_disclosure_packet_ids", [])))
	payload_lines.append("annual_trace_sections:%s" % _array_payload(traceability.get("post_start_source_disclosure_section_ids", [])))
	return {
		"company_id": fixture_company_id,
		"note_packet_ref_count": fixture_ref_count,
		"payload": "\n".join(payload_lines)
	}


func _validate_annual_note_packet_refs(company_id: String, note: Dictionary, issues: Array[String]) -> void:
	var note_type: String = str(note.get("note_type", ""))
	var packet_ids: Array = _string_array(note.get("source_disclosure_packet_ids", []))
	var placement_ids: Array = _string_array(note.get("source_disclosure_placement_ids", []))
	var section_ids: Array = _string_array(note.get("source_disclosure_section_ids", []))
	var story_ids: Array = _string_array(note.get("source_story_ids", []))
	for ref_value in _variant_array(note.get("disclosure_packet_refs", [])):
		if typeof(ref_value) != TYPE_DICTIONARY:
			issues.append("annual_bad_packet_ref:%s:%s" % [company_id, note_type])
			continue
		var ref: Dictionary = ref_value
		var packet_id: String = str(ref.get("packet_id", ""))
		var placement_id: String = str(ref.get("placement_id", ""))
		var section_id: String = str(ref.get("section_id", ""))
		var story_id: String = str(ref.get("story_id", ""))
		if not packet_ids.has(packet_id):
			issues.append("annual_note_missing_packet_id:%s:%s:%s" % [company_id, note_type, packet_id])
		if not placement_ids.has(placement_id):
			issues.append("annual_note_missing_placement_id:%s:%s:%s" % [company_id, note_type, placement_id])
		if not section_ids.has(section_id):
			issues.append("annual_note_missing_section_id:%s:%s:%s" % [company_id, note_type, section_id])
		if not story_ids.has(story_id):
			issues.append("annual_note_missing_story_id:%s:%s:%s" % [company_id, note_type, story_id])
		if _string_array(ref.get("fact_ids", [])).is_empty():
			issues.append("annual_packet_ref_missing_fact:%s:%s:%s" % [company_id, note_type, packet_id])
		if _string_array(ref.get("effect_ids", [])).is_empty():
			issues.append("annual_packet_ref_missing_effect:%s:%s:%s" % [company_id, note_type, packet_id])
		if _string_array(ref.get("clue_ids", [])).is_empty():
			issues.append("annual_packet_ref_missing_clue:%s:%s:%s" % [company_id, note_type, packet_id])
		if not _rows_contain_id(RunState.get_company_story_disclosure_packets_for_company(company_id, section_id), "packet_id", packet_id):
			issues.append("annual_packet_ref_not_resolved_by_section:%s:%s:%s" % [company_id, section_id, packet_id])
		_validate_no_hidden_keys("annual_packet_ref", story_id, ref, issues)


func _validate_normalized_evidence(company_id: String, note: Dictionary, evidence: Dictionary, issues: Array[String]) -> void:
	var note_type: String = str(note.get("note_type", ""))
	for key_value in [
		"source_disclosure_packet_ids",
		"source_disclosure_placement_ids",
		"source_disclosure_section_ids",
		"disclosure_packet_refs",
		"source_story_ids",
		"fact_ids",
		"effect_ids",
		"clue_ids"
	]:
		var key: String = str(key_value)
		if _array_payload(evidence.get(key, [])) != _array_payload(note.get(key, [])):
			issues.append("normalized_evidence_mismatch:%s:%s:%s" % [company_id, note_type, key])
	for ref_value in _variant_array(evidence.get("disclosure_packet_refs", [])):
		if typeof(ref_value) == TYPE_DICTIONARY:
			_validate_no_hidden_keys("normalized_packet_ref", str(ref_value.get("story_id", "")), ref_value, issues)


func _capture_payload_for_note(company_id: String, note: Dictionary) -> Dictionary:
	return {
		"source_type": "financial_statement",
		"category": "financials",
		"company_id": company_id,
		"label": str(note.get("title", note.get("note_id", "annual note"))),
		"value": str(note.get("disclosure_quality", "partial")),
		"detail": str(note.get("summary", "")),
		"source_id": "fixture_%s_%s" % [company_id, str(note.get("note_id", note.get("note_type", "note")))],
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


func _annual_note_payload_line(note: Dictionary) -> String:
	var ref_parts: Array[String] = []
	for ref_value in _variant_array(note.get("disclosure_packet_refs", [])):
		if typeof(ref_value) != TYPE_DICTIONARY:
			continue
		var ref: Dictionary = ref_value
		ref_parts.append("%s:%s:%s:%s" % [
			str(ref.get("packet_id", "")),
			str(ref.get("section_id", "")),
			str(ref.get("subtlety", "")),
			str(ref.get("packet_role", ""))
		])
	ref_parts.sort()
	return "note:%s:%s:%s:%s:%s" % [
		str(note.get("note_type", "")),
		_array_payload(note.get("source_story_ids", [])),
		_array_payload(note.get("source_disclosure_packet_ids", [])),
		_array_payload(note.get("source_disclosure_section_ids", [])),
		"|".join(ref_parts)
	]


func _annual_packet_ref_count(annual: Dictionary) -> int:
	var count: int = 0
	for note_value in _variant_array(annual.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		count += _variant_array(note_value.get("disclosure_packet_refs", [])).size()
	return count


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


func _section_definitions() -> Dictionary:
	var dossier_system = COMPANY_STORY_DOSSIER_SYSTEM.new()
	return dossier_system.disclosure_section_definitions()


func _valid_subtleties() -> Array:
	var dossier_system = COMPANY_STORY_DOSSIER_SYSTEM.new()
	return dossier_system.disclosure_subtlety_bands()


func _validate_ref_ids(label: String, story_id: String, packet_id: String, source_ids: Variant, valid_ids: Array, issues: Array[String]) -> void:
	var ids: Array = _string_array(source_ids)
	if ids.is_empty():
		issues.append("%s_empty:%s:%s" % [label, story_id, packet_id])
		return
	for id_value in ids:
		var id: String = str(id_value)
		if not valid_ids.has(id):
			issues.append("%s_missing:%s:%s:%s" % [label, story_id, packet_id, id])


func _validate_cross_sections(story_id: String, packet_id: String, source_ids: Variant, section_definitions: Dictionary, issues: Array[String]) -> void:
	for section_value in _string_array(source_ids):
		var section_id: String = str(section_value)
		if not section_definitions.has(section_id):
			issues.append("invalid_cross_section:%s:%s:%s" % [story_id, packet_id, section_id])


func _validate_no_hidden_keys(label: String, story_id: String, row: Dictionary, issues: Array[String]) -> void:
	for hidden_key in HIDDEN_DISCLOSURE_KEYS:
		if row.has(hidden_key):
			issues.append("%s_hidden_key:%s:%s" % [label, story_id, hidden_key])


func _rows_contain_id(rows: Array, id_key: String, expected_id: String) -> bool:
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		if str(row_value.get(id_key, "")) == expected_id:
			return true
	return false


func _ids_from_rows(rows_value: Variant, id_key: String) -> Array:
	var result: Array = []
	for row_value in _variant_array(rows_value):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var text: String = str(row_value.get(id_key, "")).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	result.sort()
	return result


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


func _array_payload(source_value: Variant) -> String:
	return "|".join(_string_array(source_value))


func _count_payload_line(label: String, counts: Dictionary) -> String:
	var parts: Array[String] = []
	var keys: Array = counts.keys()
	keys.sort()
	for key_value in keys:
		var key: String = str(key_value)
		parts.append("%s=%d" % [key, int(counts.get(key, 0))])
	return "%s:%s" % [label, "|".join(parts)]


func _increment(counts: Dictionary, key: String) -> void:
	var normalized: String = key.strip_edges()
	if normalized.is_empty():
		return
	counts[normalized] = int(counts.get(normalized, 0)) + 1


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int(hash_value ^ text.unicode_at(index))
		hash_value = int((hash_value * 16777619) & 0x7fffffff)
	return str(hash_value)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
