extends Node

const CONTACT_NETWORK_SYSTEM_SCRIPT := preload("res://systems/ContactNetworkSystem.gd")

const RUN_SEED := 20260622
const CATALOG_COMPANY_COUNT := 30
const TRUSTED_CONTACT_ID := "andika_brokerage_sales"
const INNER_CONTACT_ID := "pak_gunawan_personal_lawyer"
const RECOGNITION_SEED_CONTACT_IDS := [
	"journalist_ayu_larasati",
	"budi_supply_chain",
	"andika_brokerage_sales",
	"aryo_port_ops",
	"pak_asep_coal_hauler",
	"aulia_consumer_brand",
	"bagas_fuel_station_mgr",
	"pak_bonar_cement_sales"
]
const EXPECTED_PREVIEW_HASH := "160102873"

var _network_system = CONTACT_NETWORK_SYSTEM_SCRIPT.new()


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var report: Dictionary = _build_report()
	if int(report.get("issue_count", 0)) != 0:
		_fail("Generated Network private clue issues: %s" % JSON.stringify(report.get("issues", [])))
		return
	if EXPECTED_PREVIEW_HASH != "BASELINE_PENDING" and str(report.get("hash", "")) != EXPECTED_PREVIEW_HASH:
		_fail("Generated Network private clue fingerprint changed. expected=%s actual=%s." % [
			EXPECTED_PREVIEW_HASH,
			str(report.get("hash", ""))
		])
		return

	report.erase("payload")
	print("CONTENT_SURFACE_NETWORK_PRIVATE_CLUE_OK %s" % JSON.stringify(report))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	_setup_fixed_seed_run()
	var context: Dictionary = _private_network_clue_context()
	if context.is_empty():
		return _issue_report(["no_private_network_clue"], {}, "")
	context = _force_specific_private_network_clue_fixture(context)
	var company_id: String = str(context.get("company_id", ""))
	var clue: Dictionary = context.get("clue", {}) if typeof(context.get("clue", {})) == TYPE_DICTIONARY else {}
	var target_day_index: int = int(clue.get("earliest_day_index", 0))
	RunState.day_index = target_day_index
	RunState.daily_action_day_index = target_day_index
	RunState.daily_actions_used = 0
	_seed_high_recognition_state(company_id, target_day_index)

	var trusted_result: Dictionary = _network_system.request_tip(
		RunState,
		DataRepository,
		GameManager.corporate_action_system,
		TRUSTED_CONTACT_ID,
		company_id
	)
	var inner_result: Dictionary = _network_system.request_tip(
		RunState,
		DataRepository,
		GameManager.corporate_action_system,
		INNER_CONTACT_ID,
		company_id
	)
	var trusted_journal: Dictionary = _latest_tip_for_contact(TRUSTED_CONTACT_ID)
	var inner_journal: Dictionary = _latest_tip_for_contact(INNER_CONTACT_ID)

	var issues: Array[String] = []
	_validate_generated_result("trusted", trusted_result, trusted_journal, issues)
	_validate_generated_result("inner", inner_result, inner_journal, issues)
	if str(trusted_result.get("directness", "")) == "specific":
		issues.append("trusted_stage_exposed_specific_directness")
	if str(inner_result.get("directness", "")) != "specific":
		issues.append("inner_stage_missing_specific_directness")
	if str(trusted_result.get("story_id", "")) != str(inner_result.get("story_id", "")):
		issues.append("stage_results_used_different_story")

	var payload_lines: Array[String] = [
		_result_payload("trusted", trusted_result, trusted_journal),
		_result_payload("inner", inner_result, inner_journal)
	]
	payload_lines.sort()
	var payload: String = "\n".join(payload_lines)
	return {
		"seed": RUN_SEED,
		"day_index": target_day_index,
		"company_id": company_id,
		"story_id": str(context.get("story_id", "")),
		"trusted_directness": str(trusted_result.get("directness", "")),
		"inner_directness": str(inner_result.get("directness", "")),
		"trusted_confidence": str(trusted_result.get("public_confidence_label", "")),
		"inner_confidence": str(inner_result.get("public_confidence_label", "")),
		"trusted_journal_generated": bool(trusted_journal.get("generated_content_surface", false)),
		"inner_journal_generated": bool(inner_journal.get("generated_content_surface", false)),
		"issue_count": issues.size(),
		"issues": issues,
		"hash": _stable_hash(payload),
		"payload": payload
	}


func _setup_fixed_seed_run() -> void:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = CATALOG_COMPANY_COUNT
	difficulty_config["use_company_universe_catalog"] = true
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)


func _private_network_clue_context() -> Dictionary:
	var rows: Array = []
	var dossier_state: Dictionary = RunState.get_company_story_dossier_state()
	var dossier_index: Dictionary = dossier_state.get("dossier_index", {})
	for dossier_value in dossier_index.values():
		if typeof(dossier_value) != TYPE_DICTIONARY:
			continue
		var dossier: Dictionary = dossier_value
		for clue_value in dossier.get("private_clues", []):
			if typeof(clue_value) != TYPE_DICTIONARY:
				continue
			var clue: Dictionary = clue_value
			if str(clue.get("surface_id", "")) != "network":
				continue
			if str(clue.get("visibility", "")) != "private":
				continue
			rows.append({
				"company_id": str(dossier.get("company_id", "")),
				"story_id": str(dossier.get("story_id", "")),
				"dossier": dossier.duplicate(true),
				"clue": clue.duplicate(true),
				"score": float(clue.get("reliability", 0.0)) + float(dossier.get("priority", 0.0)) * 0.1
			})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("score", 0.0)), float(b.get("score", 0.0))):
			return str(a.get("story_id", "")) < str(b.get("story_id", ""))
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	if rows.is_empty():
		return {}
	return rows[0].duplicate(true)


func _force_specific_private_network_clue_fixture(context: Dictionary) -> Dictionary:
	var story_id: String = str(context.get("story_id", ""))
	var clue: Dictionary = context.get("clue", {}) if typeof(context.get("clue", {})) == TYPE_DICTIONARY else {}
	var clue_id: String = str(clue.get("clue_id", ""))
	var dossier_state: Dictionary = RunState.get_company_story_dossier_state()
	var dossier_index: Dictionary = dossier_state.get("dossier_index", {})
	var dossier: Dictionary = dossier_index.get(story_id, {}) if typeof(dossier_index.get(story_id, {})) == TYPE_DICTIONARY else {}
	if dossier.is_empty():
		return context
	var private_clues: Array = dossier.get("private_clues", []) if typeof(dossier.get("private_clues", [])) == TYPE_ARRAY else []
	for index in range(private_clues.size()):
		if typeof(private_clues[index]) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = private_clues[index].duplicate(true)
		if str(row.get("clue_id", "")) != clue_id:
			continue
		row["directness"] = "specific"
		row["source_quality"] = "operator"
		row["reliability"] = max(float(row.get("reliability", 0.0)), 0.82)
		row["required_relationship_stage"] = "trusted"
		row["required_recognition_min"] = min(int(row.get("required_recognition_min", 70)), 70)
		private_clues[index] = row
		clue = row.duplicate(true)
		break
	dossier["private_clues"] = private_clues
	dossier_index[story_id] = dossier
	dossier_state["dossier_index"] = dossier_index
	RunState.set_company_story_dossier_state(dossier_state)
	context["clue"] = clue
	context["dossier"] = dossier.duplicate(true)
	return context


func _seed_high_recognition_state(company_id: String, day_index: int) -> void:
	RunState.player_portfolio["cash"] = 5000000.0
	var holdings: Dictionary = {}
	var seeded_holdings: int = 0
	for company_id_value in RunState.company_order:
		if seeded_holdings >= 6:
			break
		var holding_company_id: String = str(company_id_value)
		var company: Dictionary = RunState.get_company(holding_company_id)
		var current_price: float = max(float(company.get("current_price", 0.0)), 1.0)
		var shares: int = max(100, int(floor(200000000.0 / current_price / 100.0)) * 100)
		holdings[holding_company_id] = {
			"company_id": holding_company_id,
			"shares": shares,
			"average_price": current_price
		}
		seeded_holdings += 1
	RunState.player_portfolio["holdings"] = holdings

	var contacts: Dictionary = RunState.get_network_contacts()
	var discoveries: Dictionary = RunState.get_network_discoveries()
	for contact_id_value in RECOGNITION_SEED_CONTACT_IDS:
		var seed_contact_id: String = str(contact_id_value)
		var contact: Dictionary = _contact_definition(seed_contact_id)
		if contact.is_empty():
			continue
		contacts[seed_contact_id] = {
			"contact_id": seed_contact_id,
			"met": true,
			"relationship": 45,
			"met_day_index": day_index,
			"last_source_type": "content_surface_network_test"
		}
		discoveries[seed_contact_id] = _discovery_row(seed_contact_id, company_id, day_index)
	var inner_contact: Dictionary = _contact_definition(INNER_CONTACT_ID)
	if not inner_contact.is_empty():
		contacts[INNER_CONTACT_ID] = {
			"contact_id": INNER_CONTACT_ID,
			"met": true,
			"relationship": 72,
			"met_day_index": day_index,
			"last_source_type": "content_surface_network_test"
		}
		discoveries[INNER_CONTACT_ID] = _discovery_row(INNER_CONTACT_ID, company_id, day_index)
	RunState.set_network_contacts(contacts)
	RunState.set_network_discoveries(discoveries)


func _discovery_row(contact_id: String, company_id: String, day_index: int) -> Dictionary:
	return {
		"contact_id": contact_id,
		"discovered": true,
		"source_type": "content_surface_network_test",
		"source_id": "generated_network_private_clue_test",
		"target_company_id": company_id,
		"target_company_ids": [company_id],
		"lead_score": 100,
		"day_index": day_index
	}


func _contact_definition(contact_id: String) -> Dictionary:
	for contact_value in DataRepository.get_contact_network_data().get("contacts", []):
		if typeof(contact_value) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = contact_value
		if str(contact.get("id", "")) == contact_id:
			return contact.duplicate(true)
	return {}


func _validate_generated_result(label: String, result: Dictionary, journal: Dictionary, issues: Array[String]) -> void:
	if not bool(result.get("success", false)):
		issues.append("%s_result_failed" % label)
		return
	if not bool(result.get("generated_content_surface", false)):
		issues.append("%s_result_not_generated" % label)
	if str(result.get("generated_surface_id", "")) != "network":
		issues.append("%s_bad_surface" % label)
	if str(result.get("source_system_id", "")) != "company_story_dossier":
		issues.append("%s_bad_source_system" % label)
	if str(result.get("visibility", "")) != "private":
		issues.append("%s_bad_visibility" % label)
	if _string_array(result.get("source_fact_ids", [])).is_empty():
		issues.append("%s_missing_fact_ids" % label)
	if _string_array(result.get("source_clue_ids", [])).is_empty():
		issues.append("%s_missing_clue_ids" % label)
	if journal.is_empty() or not bool(journal.get("generated_content_surface", false)):
		issues.append("%s_journal_not_generated" % label)
	if _visible_copy_leaks_hidden_terms(result):
		issues.append("%s_visible_hidden_leak" % label)


func _visible_copy_leaks_hidden_terms(result: Dictionary) -> bool:
	var visible_text: String = " ".join([
		str(result.get("message", "")),
		str(result.get("public_tip_read", "")),
		str(result.get("intel_summary", ""))
	]).to_lower()
	for term in ["truth_state", "source_quality", "relationship_stage", "clue|", "fact|", "story|"]:
		if visible_text.contains(term):
			return true
	return false


func _latest_tip_for_contact(contact_id: String) -> Dictionary:
	var latest: Dictionary = {}
	for tip_value in RunState.get_network_tip_journal().values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		if str(tip.get("contact_id", "")) != contact_id:
			continue
		if latest.is_empty() or int(tip.get("created_day_index", 0)) >= int(latest.get("created_day_index", 0)):
			latest = tip.duplicate(true)
	return latest


func _result_payload(label: String, result: Dictionary, journal: Dictionary) -> String:
	return "%s|success=%s|direct=%s|confidence=%s|truth=%s|story=%s|facts=%s|clues=%s|journal=%s|text=%s" % [
		label,
		str(bool(result.get("success", false))),
		str(result.get("directness", "")),
		str(result.get("public_confidence_label", "")),
		str(result.get("public_truth_label", "")),
		str(result.get("story_id", "")),
		_array_payload(_string_array(result.get("source_fact_ids", []))),
		_array_payload(_string_array(result.get("source_clue_ids", []))),
		str(bool(journal.get("generated_content_surface", false))),
		str(result.get("public_tip_read", ""))
	]


func _issue_report(issues: Array, context: Dictionary, payload: String) -> Dictionary:
	return {
		"seed": RUN_SEED,
		"day_index": RunState.day_index,
		"company_id": str(context.get("company_id", "")),
		"story_id": str(context.get("story_id", "")),
		"issue_count": issues.size(),
		"issues": issues,
		"hash": _stable_hash(payload),
		"payload": payload
	}


func _string_array(source_value: Variant) -> Array:
	var source_array: Array = source_value if typeof(source_value) == TYPE_ARRAY else [source_value]
	var result: Array = []
	var seen: Dictionary = {}
	for item_value in source_array:
		var item: String = str(item_value).strip_edges()
		if item.is_empty() or seen.has(item):
			continue
		seen[item] = true
		result.append(item)
	return result


func _array_payload(values: Array) -> String:
	var rows: Array = []
	for value in values:
		rows.append(str(value))
	rows.sort()
	return ",".join(rows)


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int((hash_value ^ text.unicode_at(index)) * 16777619) & 0xFFFFFFFF
	return str(hash_value)


func _fail(message: String) -> void:
	push_error(message)
	print("CONTENT_SURFACE_NETWORK_PRIVATE_CLUE_FAIL %s" % message)
	get_tree().quit(1)
