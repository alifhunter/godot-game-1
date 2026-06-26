extends Node

const ANNUAL_FILING_DOCUMENT = preload("res://systems/AnnualFilingDocument.gd")
const COMPANY_STORY_DOSSIER = preload("res://systems/CompanyStoryDossierSystem.gd")

const EXPECTED_HASH := "1089345055"
const RUN_SEED := 20260624


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var report: Dictionary = _build_report()
	if not bool(report.get("success", false)):
		_fail(str(report.get("message", "annual filing story fact packet test failed")))
		return
	var repeat_report: Dictionary = _build_report()
	if not bool(repeat_report.get("success", false)):
		_fail(str(repeat_report.get("message", "repeated annual filing story fact packet test failed")))
		return
	if str(report.get("payload", "")) != str(repeat_report.get("payload", "")):
		_fail("Annual filing story fact packet payload changed across repeated runs.")
		return

	var hash: String = _stable_hash(str(report.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual filing story fact packet hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_FILING_STORY_FACT_PACKET_OK %s" % JSON.stringify({
		"hash": hash,
		"sample_count": int(report.get("sample_count", 0)),
		"packet_count": int(report.get("packet_count", 0)),
		"source_systems": report.get("source_systems", [])
	}))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	var bank_company: Dictionary = _catalog_company("bank_orang_indonesia")
	var industrial_company: Dictionary = _catalog_company("alat_berat_mandiri")
	var energy_company: Dictionary = _catalog_company("energi_surya_hijau")
	var counterparty_a: Dictionary = _catalog_company("pelabuhan_nusa")
	var counterparty_b: Dictionary = _catalog_company("kencana_migas")
	if bank_company.is_empty() or industrial_company.is_empty() or energy_company.is_empty() or counterparty_a.is_empty() or counterparty_b.is_empty():
		return _case_fail("Expected fixed company-universe samples for story fact packet test.")

	var samples: Array = [
		{
			"label": "bank",
			"profile_id": "bank",
			"company": bank_company,
			"annual": _annual_statement(bank_company),
			"context": _source_context(bank_company, counterparty_a, "customer", "balance_sheet_stress", "corporate_action_filing")
		},
		{
			"label": "industrial",
			"profile_id": "industrial_trading",
			"company": industrial_company,
			"annual": _annual_statement(industrial_company),
			"context": _source_context(industrial_company, counterparty_a, "customer", "contract_win", "relationship_event")
		},
		{
			"label": "energy",
			"profile_id": "industrial_trading",
			"company": energy_company,
			"annual": _annual_statement(energy_company),
			"context": _source_context(energy_company, counterparty_b, "partner", "capex_expansion", "roadmap_milestone")
		}
	]

	var payload_lines: Array[String] = []
	var all_source_systems: Array = []
	var total_packets: int = 0
	for sample_value in samples:
		var sample: Dictionary = sample_value
		var company: Dictionary = sample.get("company", {})
		var profile_id: String = str(sample.get("profile_id", "default_general"))
		var packets: Array = ANNUAL_FILING_DOCUMENT.build_story_note_fact_packets(
			company,
			sample.get("annual", {}),
			sample.get("context", {}),
			{
				"filing_profile_id": profile_id,
				"fiscal_year": 2019,
				"min_story_note_fact_packets": 3,
				"max_story_note_fact_packets": 20
			}
		)
		var validation: Dictionary = _validate_packets(str(sample.get("label", "")), packets, profile_id)
		if not bool(validation.get("success", false)):
			return validation
		total_packets += packets.size()
		all_source_systems = _append_source_systems(all_source_systems, packets)
		payload_lines.append(_sample_payload(str(sample.get("label", "")), profile_id, packets))

	var fallback_packets: Array = ANNUAL_FILING_DOCUMENT.build_story_note_fact_packets(
		energy_company,
		_annual_statement(energy_company),
		{},
		{
			"filing_profile_id": "industrial_trading",
			"fiscal_year": 2019,
			"min_story_note_fact_packets": 3,
			"max_story_note_fact_packets": 6
		}
	)
	var fallback_validation: Dictionary = _validate_packets("fallback_only", fallback_packets, "industrial_trading")
	if not bool(fallback_validation.get("success", false)):
		return fallback_validation
	if not _source_systems(fallback_packets).has("company_universe_catalog"):
		return _case_fail("Expected fallback-only sample to include company_universe_catalog source facts.")
	total_packets += fallback_packets.size()
	all_source_systems = _append_source_systems(all_source_systems, fallback_packets)
	payload_lines.append(_sample_payload("fallback_only", "industrial_trading", fallback_packets))

	for required_source in ["annual_statement_builder", "company_relationship_graph", "company_story_dossier", "company_universe_catalog"]:
		if not all_source_systems.has(required_source):
			return _case_fail("Expected source system %s in story fact packets." % required_source)

	return {
		"success": true,
		"payload": "\n".join(payload_lines),
		"sample_count": samples.size() + 1,
		"packet_count": total_packets,
		"source_systems": all_source_systems
	}


func _validate_packets(label: String, packets: Array, profile_id: String) -> Dictionary:
	if packets.size() < 3:
		return _case_fail("%s expected at least 3 story fact packets." % label)
	var errors: Array = ANNUAL_FILING_DOCUMENT.validate_story_note_fact_packet_set(packets, profile_id)
	if not errors.is_empty():
		return _case_fail("%s packet validation failed: %s." % [label, ", ".join(_string_array(errors))])
	for packet_value in packets:
		if typeof(packet_value) != TYPE_DICTIONARY:
			return _case_fail("%s has non-dictionary packet." % label)
		var packet: Dictionary = packet_value
		if _string_array(packet.get("source_ids", [])).is_empty():
			return _case_fail("%s packet %s has no source ids." % [label, str(packet.get("fact_id", ""))])
		var allowed_containers: Array = ANNUAL_FILING_DOCUMENT.story_note_allowed_containers_for_story_type(str(packet.get("story_type", "")), profile_id)
		if not allowed_containers.has(str(packet.get("note_container", ""))):
			return _case_fail("%s packet %s is not in an allowed note container." % [label, str(packet.get("fact_id", ""))])
		for visible_field in ["visible_text", "paragraph", "body", "rendered_text"]:
			if packet.has(visible_field):
				return _case_fail("%s packet %s generated visible prose field %s." % [label, str(packet.get("fact_id", "")), visible_field])
	if label == "bank" and not _story_types(packets).has("bank_facility"):
		return _case_fail("Bank sample expected a bank_facility fact.")
	if label == "industrial" and not (_story_types(packets).has("supply_or_offtake_agreement") or _story_types(packets).has("project_contract")):
		return _case_fail("Industrial sample expected a commercial agreement fact.")
	if label == "energy" and not (_story_types(packets).has("segment_expansion") or _story_types(packets).has("project_contract")):
		return _case_fail("Energy sample expected project or segment story facts.")
	return _case_ok()


func _source_context(company: Dictionary, counterparty: Dictionary, relationship_type: String, archetype_id: String, runtime_kind: String) -> Dictionary:
	var dossier_system = COMPANY_STORY_DOSSIER.new()
	var dossier: Dictionary = dossier_system.generate_company_dossier(
		RUN_SEED,
		company,
		{},
		0,
		{
			"slot_index": 0,
			"candidate": {
				"archetype_id": archetype_id,
				"hook_id": "%s_fixture_hook" % archetype_id,
				"score": 5.4
			}
		}
	)
	var edge_id: String = "edge|%s|%s|%s" % [str(company.get("id", "")), str(counterparty.get("id", "")), relationship_type]
	var edge: Dictionary = {
		"edge_id": edge_id,
		"source_company_id": str(company.get("id", "")),
		"target_company_id": str(counterparty.get("id", "")),
		"relationship_type": relationship_type,
		"strength": 0.72,
		"confidence": 0.81,
		"visibility": "semi_public",
		"source_fact_ids": ["relationship_fact|%s" % edge_id]
	}
	var relationship_event: Dictionary = {
		"arc_id": "relationship_graph|42|%s|fixture" % str(company.get("id", "")),
		"target_company_id": str(company.get("id", "")),
		"counterparty_company_id": str(counterparty.get("id", "")),
		"counterparty_company_name": str(counterparty.get("name", "")),
		"relationship_event_id": "relationship|42|%s|fixture" % edge_id,
		"relationship_edge_id": edge_id,
		"relationship_type": relationship_type,
		"category": "relationship_%s" % runtime_kind,
		"event_date": "2019-09-18"
	}
	return {
		"company_definitions": [company, counterparty],
		"company_dossiers": [dossier],
		"relationship_edges": [edge],
		"relationship_events": [relationship_event],
		"active_company_arcs": [
			{
				"arc_id": "arc|%s|%s" % [str(company.get("id", "")), runtime_kind],
				"target_company_id": str(company.get("id", "")),
				"source_system": "company_roadmap",
				"category": runtime_kind,
				"event_date": "2019-11-12"
			}
		],
		"corporate_action_events": [
			{
				"event_id": "corporate_action_filing",
				"event_family": "corporate_action",
				"target_company_id": str(company.get("id", "")),
				"category": "corporate_action_filing",
				"event_date": "2019-12-05"
			}
		],
		"roadmap_milestones": [
			{
				"milestone_id": "milestone|%s|%s" % [str(company.get("id", "")), runtime_kind],
				"company_id": str(company.get("id", "")),
				"milestone_family": runtime_kind,
				"event_date": "2019-10-01"
			}
		]
	}


func _annual_statement(company: Dictionary) -> Dictionary:
	var company_id: String = str(company.get("id", "fixture_company"))
	var statement_id: String = "annual_statement|story_fact_packet|%s|2019" % company_id
	return {
		"statement_id": statement_id,
		"company_id": company_id,
		"ticker": str(company.get("ticker", "")),
		"company_name": str(company.get("name", "")),
		"fiscal_year": 2019,
		"comparative_year": 2018,
		"statement_scope": "annual",
		"consolidated": true,
		"statement_period_label": "FY2019",
		"currency": "IDR",
		"financial_position": [
			_line(statement_id, "financial_position", "cash", "Cash and cash equivalents", 140000000.0),
			_line(statement_id, "financial_position", "debt", "Debt and borrowings", 320000000.0),
			_line(statement_id, "financial_position", "property_plant_equipment", "Property, plant and equipment", 510000000.0),
			_line(statement_id, "financial_position", "right_of_use_assets", "Right-of-use assets", 85000000.0),
			_line(statement_id, "financial_position", "current_liabilities", "Current liabilities", 210000000.0)
		],
		"profit_or_loss_and_oci": [
			_line(statement_id, "profit_or_loss_and_oci", "revenue", "Revenue", 920000000.0),
			_line(statement_id, "profit_or_loss_and_oci", "gross_profit", "Gross profit", 310000000.0)
		],
		"cash_flows": [
			_line(statement_id, "cash_flows", "purchase_of_property_plant_equipment", "Purchase of property, plant and equipment", -72000000.0)
		],
		"notes": [
			{
				"note_id": "annual_note|%s|06_segment_information" % statement_id,
				"note_type": "segment_information",
				"source_ids": ["annual_note|segment|%s" % company_id],
				"source_story_ids": ["story|%s|segment" % company_id],
				"source_disclosure_packet_ids": ["packet|%s|segment" % company_id]
			},
			{
				"note_id": "annual_note|%s|11_debt_and_borrowings" % statement_id,
				"note_type": "debt_and_borrowings",
				"source_ids": ["annual_note|debt|%s" % company_id],
				"source_story_ids": ["story|%s|debt" % company_id]
			},
			{
				"note_id": "annual_note|%s|14_commitments" % statement_id,
				"note_type": "commitments_contingencies_and_subsequent_events",
				"source_ids": ["annual_note|commitment|%s" % company_id],
				"source_story_ids": ["story|%s|commitment" % company_id]
			}
		]
	}


func _line(statement_id: String, section_id: String, metric_id: String, label: String, value: float) -> Dictionary:
	return {
		"id": metric_id,
		"line_id": "line|%s|%s|%s" % [statement_id, section_id, metric_id],
		"section_id": section_id,
		"metric_id": metric_id,
		"label": label,
		"value": value,
		"format": "currency"
	}


func _catalog_company(company_id: String) -> Dictionary:
	var company: Dictionary = DataRepository.get_company_universe_company(company_id)
	if company.is_empty():
		return {}
	if not company.has("sector_id"):
		company["sector_id"] = str(company.get("sector", ""))
	if not company.has("subsector_id"):
		company["subsector_id"] = str(company.get("subsector", ""))
	return company


func _sample_payload(label: String, profile_id: String, packets: Array) -> String:
	var lines: Array[String] = []
	lines.append("sample=%s:%s:%s:%s" % [
		label,
		profile_id,
		packets.size(),
		ANNUAL_FILING_DOCUMENT.story_note_fact_packet_hash(packets)
	])
	for packet_value in packets:
		if typeof(packet_value) != TYPE_DICTIONARY:
			continue
		var packet: Dictionary = packet_value
		lines.append("%s|%s|%s|%s|%s|%s" % [
			str(packet.get("fact_id", "")),
			str(packet.get("story_type", "")),
			str(packet.get("note_container", "")),
			str(packet.get("source_system", "")),
			"|".join(_string_array(packet.get("source_ids", []))),
			str(packet.get("counterparty_id", ""))
		])
	return "\n".join(lines)


func _append_source_systems(source_systems: Array, packets: Array) -> Array:
	var rows: Array = source_systems.duplicate(true)
	for source_system in _source_systems(packets):
		if not rows.has(source_system):
			rows.append(source_system)
	rows.sort()
	return rows


func _source_systems(packets: Array) -> Array:
	var rows: Array = []
	for packet_value in packets:
		if typeof(packet_value) != TYPE_DICTIONARY:
			continue
		var source_system: String = str(packet_value.get("source_system", "")).strip_edges()
		if not source_system.is_empty() and not rows.has(source_system):
			rows.append(source_system)
	rows.sort()
	return rows


func _story_types(packets: Array) -> Array:
	var rows: Array = []
	for packet_value in packets:
		if typeof(packet_value) != TYPE_DICTIONARY:
			continue
		var story_type: String = str(packet_value.get("story_type", "")).strip_edges()
		if not story_type.is_empty() and not rows.has(story_type):
			rows.append(story_type)
	rows.sort()
	return rows


func _string_array(source_value: Variant) -> Array:
	var result: Array = []
	if typeof(source_value) != TYPE_ARRAY:
		return result
	for item_value in source_value:
		var text: String = str(item_value).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	result.sort()
	return result


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int(hash_value ^ text.unicode_at(index))
		hash_value = int((hash_value * 16777619) & 0x7fffffff)
	return str(hash_value)


func _case_ok() -> Dictionary:
	return {"success": true}


func _case_fail(message: String) -> Dictionary:
	return {"success": false, "message": message}


func _fail(message: String) -> void:
	print("ANNUAL_FILING_STORY_FACT_PACKET_FAIL: %s" % message)
	get_tree().quit(1)
