extends Node

const RUN_SEED := 20260614
const CEO_CHANGE_DAY := 42
const OLD_CEO_RELATIONSHIP := 67
const NEW_CEO_NAME := "Nadia Santoso"
const CORPORATE_ACTION_APPLICATIONS_SCRIPT := preload("res://systems/CorporateActionApplications.gd")
const CONTACT_NETWORK_SYSTEM_SCRIPT := preload("res://systems/ContactNetworkSystem.gd")

var _network = CONTACT_NETWORK_SYSTEM_SCRIPT.new()


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)

	var company_id: String = str(RunState.company_order[0]) if not RunState.company_order.is_empty() else ""
	if company_id.is_empty():
		_fail("Expected company generation to produce at least one company.")
		return
	if not RunState.ensure_company_full_detail(company_id):
		_fail("Could not hydrate company detail for CEO identity test.")
		return

	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	var profile: Dictionary = RunState.get_company_profile(company_id, false, false)
	var old_ceo: Dictionary = _active_ceo_row(profile)
	if old_ceo.is_empty():
		_fail("Expected hydrated company profile to contain an active CEO row.")
		return
	var old_contact_id: String = str(old_ceo.get("id", old_ceo.get("contact_id", "")))
	var old_ceo_name: String = str(old_ceo.get("display_name", ""))
	if old_contact_id.is_empty() or old_ceo_name.is_empty():
		_fail("Expected active CEO row to have contact id and display name.")
		return

	_seed_met_old_ceo(old_contact_id, company_id)
	RunState.day_index = CEO_CHANGE_DAY
	CORPORATE_ACTION_APPLICATIONS_SCRIPT.apply_ceo_change_application(RunState, {
		"company_id": company_id,
		"current_ceo_name": old_ceo_name,
		"new_ceo_name": NEW_CEO_NAME,
		"incoming_profile_label": "operator CEO",
		"mandate": "execution reset",
		"price_reaction_pct": 0.0,
		"execution_consistency_delta": 0.0,
		"growth_score_delta": 0.0,
		"risk_score_delta": 0.0,
		"governance_confidence_delta": 0.0,
		"volatility_event_multiplier": 1.0,
		"day_index": CEO_CHANGE_DAY
	})

	var new_contact_id: String = "insider_%s_ceo_%d" % [company_id, CEO_CHANGE_DAY]
	profile = RunState.get_company_profile(company_id, false, false)
	_assert_saved_roster_identity(profile, old_contact_id, old_ceo_name, new_contact_id)
	_assert_network_runtime_identity(old_contact_id, new_contact_id)
	_assert_generated_contact_definitions(company_id, old_contact_id, old_ceo_name, new_contact_id)
	_assert_company_snapshot_identity(company_id, old_contact_id, old_ceo_name, new_contact_id)

	var snapshot: Dictionary = _network.build_snapshot(RunState, DataRepository)
	var old_snapshot_row: Dictionary = _row_by_id(snapshot.get("contacts", []), old_contact_id)
	if old_snapshot_row.is_empty():
		_fail("Expected departed old CEO to remain visible as a met Network contact.")
		return
	if str(old_snapshot_row.get("affiliation_type", "")) != "free_agent":
		_fail("Expected old CEO Network row to be free_agent, got %s." % str(old_snapshot_row.get("affiliation_type", "")))
		return
	if not _row_by_id(snapshot.get("contacts", []), new_contact_id).is_empty() or not _row_by_id(snapshot.get("discoveries", []), new_contact_id).is_empty():
		_fail("Expected new CEO to start undiscovered/unmet after identity split.")
		return

	print("COMPANY_CEO_CHANGE_IDENTITY_OK %s" % JSON.stringify({
		"company_id": company_id,
		"ticker": str(definition.get("ticker", "")),
		"old_ceo_id": old_contact_id,
		"old_ceo_name": old_ceo_name,
		"old_affiliation_type": str(old_snapshot_row.get("affiliation_type", "")),
		"new_ceo_id": new_contact_id,
		"new_ceo_name": NEW_CEO_NAME,
		"old_relationship": OLD_CEO_RELATIONSHIP,
		"day_index": CEO_CHANGE_DAY
	}))
	get_tree().quit(0)


func _seed_met_old_ceo(old_contact_id: String, company_id: String) -> void:
	var contacts: Dictionary = RunState.get_network_contacts()
	contacts[old_contact_id] = {
		"contact_id": old_contact_id,
		"met": true,
		"relationship": OLD_CEO_RELATIONSHIP,
		"last_met_day_index": 7
	}
	RunState.set_network_contacts(contacts)

	var discoveries: Dictionary = RunState.get_network_discoveries()
	discoveries[old_contact_id] = {
		"contact_id": old_contact_id,
		"discovered": true,
		"source_type": "identity_test",
		"source_id": "pre_ceo_change",
		"target_company_id": company_id,
		"target_company_ids": [company_id],
		"day_index": 7
	}
	RunState.set_network_discoveries(discoveries)


func _assert_saved_roster_identity(profile: Dictionary, old_contact_id: String, old_ceo_name: String, new_contact_id: String) -> void:
	var old_row: Dictionary = _roster_row_by_id(profile, old_contact_id)
	var new_row: Dictionary = _roster_row_by_id(profile, new_contact_id)
	if old_row.is_empty():
		_fail("Expected saved management roster to preserve old CEO row.")
		return
	if new_row.is_empty():
		_fail("Expected saved management roster to add fresh new CEO row.")
		return
	if str(old_row.get("display_name", "")) != old_ceo_name:
		_fail("Expected old CEO row to keep old name, got %s." % str(old_row.get("display_name", "")))
		return
	if str(old_row.get("affiliation_type", "")) != "free_agent" or str(old_row.get("affiliation_role", "")) != "former_ceo":
		_fail("Expected old CEO saved row to become free_agent/former_ceo, got %s/%s." % [
			str(old_row.get("affiliation_type", "")),
			str(old_row.get("affiliation_role", ""))
		])
		return
	if not bool(old_row.get("departed", false)):
		_fail("Expected old CEO saved row to be marked departed.")
		return
	if str(new_row.get("display_name", "")) != NEW_CEO_NAME:
		_fail("Expected new CEO row to use incoming name, got %s." % str(new_row.get("display_name", "")))
		return
	if str(new_row.get("affiliation_type", "")) != "insider" or str(new_row.get("affiliation_role", "")) != "ceo":
		_fail("Expected new CEO saved row to become insider/ceo, got %s/%s." % [
			str(new_row.get("affiliation_type", "")),
			str(new_row.get("affiliation_role", ""))
		])
		return


func _assert_network_runtime_identity(old_contact_id: String, new_contact_id: String) -> void:
	var contacts: Dictionary = RunState.get_network_contacts()
	var old_runtime: Dictionary = contacts.get(old_contact_id, {})
	if not bool(old_runtime.get("met", false)) or int(old_runtime.get("relationship", 0)) != OLD_CEO_RELATIONSHIP:
		_fail("Expected old CEO runtime relationship to remain attached to old id, got %s." % JSON.stringify(old_runtime))
		return
	var new_runtime: Dictionary = contacts.get(new_contact_id, {})
	if bool(new_runtime.get("met", false)):
		_fail("Expected new CEO runtime to start unmet, got %s." % JSON.stringify(new_runtime))
		return

	var discoveries: Dictionary = RunState.get_network_discoveries()
	if not bool(discoveries.get(old_contact_id, {}).get("discovered", false)):
		_fail("Expected old CEO discovery state to remain attached to old id.")
		return
	if bool(discoveries.get(new_contact_id, {}).get("discovered", false)):
		_fail("Expected new CEO discovery state to start fresh.")
		return


func _assert_generated_contact_definitions(company_id: String, old_contact_id: String, old_ceo_name: String, new_contact_id: String) -> void:
	var old_definition: Dictionary = _network.call("_contact_definition", RunState, DataRepository, old_contact_id)
	var new_definition: Dictionary = _network.call("_contact_definition", RunState, DataRepository, new_contact_id)
	if old_definition.is_empty():
		_fail("Expected old CEO generated contact definition to remain addressable.")
		return
	if new_definition.is_empty():
		_fail("Expected new CEO generated contact definition to be addressable.")
		return
	if str(old_definition.get("display_name", "")) != old_ceo_name or str(old_definition.get("affiliation_type", "")) != "free_agent":
		_fail("Expected old CEO generated definition to be old free agent, got %s." % JSON.stringify(old_definition))
		return
	if str(new_definition.get("display_name", "")) != NEW_CEO_NAME or str(new_definition.get("affiliation_type", "")) != "insider":
		_fail("Expected new CEO generated definition to be fresh insider, got %s." % JSON.stringify(new_definition))
		return

	var generated_rows: Array = _network.call("_management_roster_for_company", RunState, company_id)
	var old_generated_row: Dictionary = _row_by_id(generated_rows, old_contact_id)
	var new_generated_row: Dictionary = _row_by_id(generated_rows, new_contact_id)
	if str(old_generated_row.get("affiliation_type", "")) != "free_agent":
		_fail("Expected generated roster projection to preserve old CEO free_agent affiliation.")
		return
	if str(new_generated_row.get("affiliation_type", "")) != "insider":
		_fail("Expected generated roster projection to preserve new CEO insider affiliation.")
		return


func _assert_company_snapshot_identity(company_id: String, old_contact_id: String, old_ceo_name: String, new_contact_id: String) -> void:
	var snapshot: Dictionary = GameManager.get_company_snapshot(company_id, false, false, false)
	var roster: Array = snapshot.get("management_roster", [])
	var old_rows: Array = _rows_by_id(roster, old_contact_id)
	var new_rows: Array = _rows_by_id(roster, new_contact_id)
	if old_rows.size() != 1 or new_rows.size() != 1:
		_fail("Expected GameManager snapshot to contain one old CEO and one new CEO row, got old=%d new=%d." % [old_rows.size(), new_rows.size()])
		return
	var old_row: Dictionary = old_rows[0]
	var new_row: Dictionary = new_rows[0]
	if str(old_row.get("display_name", "")) != old_ceo_name or str(old_row.get("affiliation_type", "")) != "free_agent":
		_fail("Expected GameManager old CEO snapshot row to remain old free agent, got %s." % JSON.stringify(old_row))
		return
	if str(new_row.get("display_name", "")) != NEW_CEO_NAME or str(new_row.get("affiliation_type", "")) != "insider":
		_fail("Expected GameManager new CEO snapshot row to be fresh insider, got %s." % JSON.stringify(new_row))
		return


func _active_ceo_row(profile: Dictionary) -> Dictionary:
	for row_value in profile.get("management_roster", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("affiliation_role", "")) == "ceo" and str(row.get("affiliation_type", "insider")) == "insider":
			return row.duplicate(true)
	return {}


func _roster_row_by_id(profile: Dictionary, contact_id: String) -> Dictionary:
	return _row_by_id(profile.get("management_roster", []), contact_id)


func _row_by_id(rows: Array, contact_id: String) -> Dictionary:
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("id", row.get("contact_id", ""))) == contact_id:
			return row.duplicate(true)
	return {}


func _rows_by_id(rows: Array, contact_id: String) -> Array:
	var matches: Array = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("id", row.get("contact_id", ""))) == contact_id:
			matches.append(row.duplicate(true))
	return matches


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
