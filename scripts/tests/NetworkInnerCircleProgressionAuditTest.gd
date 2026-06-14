extends Node

const RUN_SEED := 706136
const DAY_INDEX := 8
const HIGH_CONTACT_ID := "pak_gunawan_personal_lawyer"
const BRIDGE_CONTACT_ID := "pak_budihardjo_energy_dir"
const HIGH_CONTACT_REQUIRED_RECOGNITION := 95
const INNER_CIRCLE_REFERRAL_ROLE := "inner_circle"
const EXPECTED_AUDIT_HASH := "1825575415"
const TWOOTER_INTERACTION_SYSTEM_SCRIPT := preload("res://systems/TwooterInteractionSystem.gd")
const EXPECTED_STAGE_TREE_IDS := {
	"stranger": "network_stranger_source",
	"familiar": "network_familiar_source",
	"trusted": "network_trusted_source",
	"inner_circle_candidate": "network_inner_circle_source"
}
const LOW_CONTACT_IDS := [
	"journalist_ayu_larasati",
	"budi_supply_chain",
	"andika_brokerage_sales",
	"aryo_port_ops",
	"pak_asep_coal_hauler",
	"aulia_consumer_brand",
	"bagas_fuel_station_mgr",
	"pak_bonar_cement_sales"
]
const STAGE_FIXTURES := [
	{
		"stage": "stranger",
		"relationship": 4,
		"credibility": 4,
		"importance": 4
	},
	{
		"stage": "familiar",
		"relationship": 18,
		"credibility": 12,
		"importance": 12
	},
	{
		"stage": "trusted",
		"relationship": 45,
		"credibility": 20,
		"importance": 30
	},
	{
		"stage": "inner_circle_candidate",
		"relationship": 72,
		"exposure": 36,
		"credibility": 48,
		"importance": 58
	}
]

var _interaction_system = TWOOTER_INTERACTION_SYSTEM_SCRIPT.new()


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	RunState.day_index = DAY_INDEX
	RunState.daily_action_day_index = DAY_INDEX
	RunState.daily_actions_used = 0

	var high_contact: Dictionary = _contact_definition(HIGH_CONTACT_ID)
	if high_contact.is_empty():
		_fail("Inner-circle baseline missing contact definition: %s." % HIGH_CONTACT_ID)
		return
	if int(high_contact.get("recognition_required", 0)) < HIGH_CONTACT_REQUIRED_RECOGNITION:
		_fail("Inner-circle baseline target no longer requires high recognition.")
		return
	var target_company: Dictionary = _company_context_for_contact(high_contact)
	if target_company.is_empty():
		_fail("Inner-circle baseline expected at least one generated target company.")
		return

	var stage_rows: Array = _stage_dialog_rows()
	if stage_rows.size() != STAGE_FIXTURES.size():
		_fail("Expected %d stage dialog rows, got %d." % [STAGE_FIXTURES.size(), stage_rows.size()])
		return
	if not _stage_rows_have_distinct_options(stage_rows):
		_fail("Expected Network stage dialog option sets to differ by stage, rows=%s." % JSON.stringify(stage_rows))
		return
	var exposure: Dictionary = _high_recognition_exposure_report(high_contact, target_company)
	if bool(exposure.get("after_exposed", false)):
		_fail("High-recognition contact should remain hidden from public News/source discovery after Task 2 gate.")
		return
	if not bool(exposure.get("referral_success", false)):
		_fail("Expected eligible bridge contact to create private inner-circle referral, exposure=%s." % JSON.stringify(exposure))
		return
	if str(exposure.get("referral_contact_id", "")) != HIGH_CONTACT_ID or str(exposure.get("referral_source_type", "")) != "referral":
		_fail("Inner-circle referral did not unlock expected contact/provenance, exposure=%s." % JSON.stringify(exposure))
		return
	var payload: Dictionary = {
		"seed": RUN_SEED,
		"day_index": DAY_INDEX,
		"stage_rows": stage_rows,
		"high_recognition_exposure": exposure
	}
	var canonical_payload: String = JSON.stringify(payload)
	var audit_hash: String = _stable_hash(canonical_payload)
	if EXPECTED_AUDIT_HASH == "BASELINE_PENDING":
		print("NETWORK_INNER_CIRCLE_BASELINE hash=%s payload=%s" % [audit_hash, canonical_payload])
		_fail("Set EXPECTED_AUDIT_HASH in NetworkInnerCircleProgressionAuditTest.gd.")
		return
	if audit_hash != EXPECTED_AUDIT_HASH:
		_fail("Network inner-circle progression baseline drifted. expected=%s actual=%s payload=%s" % [EXPECTED_AUDIT_HASH, audit_hash, canonical_payload])
		return

	print("NETWORK_INNER_CIRCLE_BASELINE_OK hash=%s stages=%d high_after_exposed=%s high_before_exposed=%s" % [
		audit_hash,
		stage_rows.size(),
		str(bool(exposure.get("after_exposed", false))),
		str(bool(exposure.get("before_exposed", false)))
	])
	get_tree().quit(0)


func _stage_dialog_rows() -> Array:
	var rows: Array = []
	var feed_data: Dictionary = DataRepository.get_twooter_feed_data()
	for fixture_value: Variant in STAGE_FIXTURES:
		if typeof(fixture_value) != TYPE_DICTIONARY:
			continue
		var fixture: Dictionary = fixture_value
		var stage: String = str(fixture.get("stage", ""))
		var account: Dictionary = _network_account(stage)
		var account_state: Dictionary = _account_state(
			int(fixture.get("relationship", 0)),
			int(fixture.get("credibility", 0)),
			int(fixture.get("importance", 0)),
			int(fixture.get("exposure", 25))
		)
		if str(account_state.get("relationship_stage", "")) != stage:
			_fail("Stage fixture '%s' produced relationship stage '%s'." % [stage, str(account_state.get("relationship_stage", ""))])
			return rows
		var thread: Dictionary = _interaction_system.get_message_thread(
			_social_state_for_account(account, account_state),
			[account],
			str(account.get("id", "")),
			DAY_INDEX,
			[],
			feed_data,
			_daily_action()
		)
		var options: Array = _dialog_option_audit_rows(thread.get("dialog_options", []) if typeof(thread.get("dialog_options", [])) == TYPE_ARRAY else [])
		if options.is_empty():
			_fail("Expected stage '%s' to expose private dialog options." % stage)
			return rows
		var tree_id: String = str(options[0].get("tree_id", ""))
		var node_id: String = str(options[0].get("node_id", ""))
		if tree_id != str(EXPECTED_STAGE_TREE_IDS.get(stage, "")):
			_fail("Expected stage '%s' to route to '%s', got '%s'." % [stage, str(EXPECTED_STAGE_TREE_IDS.get(stage, "")), tree_id])
			return rows
		var authored_option_count: int = _authored_option_count(feed_data, tree_id, node_id)
		if options.size() < 3 or _enabled_option_count(options) < 3 or authored_option_count < 4:
			_fail("Expected stage '%s' to expose at least 3 enabled options and author at least 4, visible=%d enabled=%d authored=%d." % [stage, options.size(), _enabled_option_count(options), authored_option_count])
			return rows
		rows.append({
			"stage": stage,
			"relationship": int(account_state.get("relationship", 0)),
			"credibility": int(account_state.get("credibility", 0)),
			"importance": int(account_state.get("importance", 0)),
			"tree_id": tree_id,
			"node_id": node_id,
			"option_count": options.size(),
			"enabled_count": _enabled_option_count(options),
			"authored_option_count": authored_option_count,
			"option_ids": _option_ids(options),
			"options": options
		})
	return rows


func _high_recognition_exposure_report(high_contact: Dictionary, target_company: Dictionary) -> Dictionary:
	var low_recognition: Dictionary = GameManager.get_network_snapshot().get("recognition", {})
	var blocked_rows: Array = GameManager.discover_network_contacts_from_article(_article_for_high_contact(target_company, high_contact, "baseline_blocked"))
	var before_exposed: bool = _contains_contact(blocked_rows, HIGH_CONTACT_ID) or RunState.get_network_discoveries().has(HIGH_CONTACT_ID)
	_seed_high_recognition_state(target_company)
	var high_recognition: Dictionary = GameManager.get_network_snapshot().get("recognition", {})
	var discovered_rows: Array = GameManager.discover_network_contacts_from_article(_article_for_high_contact(target_company, high_contact, "baseline_public_after_recognition"))
	var after_exposed: bool = _contains_contact(discovered_rows, HIGH_CONTACT_ID) or RunState.get_network_discoveries().has(HIGH_CONTACT_ID)
	_seed_inner_circle_bridge_state(BRIDGE_CONTACT_ID, target_company)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0
	var referral_result: Dictionary = GameManager.request_contact_referral(BRIDGE_CONTACT_ID, str(target_company.get("id", "")), INNER_CIRCLE_REFERRAL_ROLE)
	var referral_row: Dictionary = _network_row(HIGH_CONTACT_ID, "discoveries")
	return {
		"contact_id": HIGH_CONTACT_ID,
		"contact_name": str(high_contact.get("display_name", "")),
		"recognition_required": int(high_contact.get("recognition_required", 0)),
		"target_ticker": str(target_company.get("ticker", "")),
		"target_sector_id": str(target_company.get("sector_id", "")),
		"before_recognition": _recognition_report(low_recognition),
		"before_rows": _lead_ids(blocked_rows),
		"before_exposed": before_exposed,
		"after_recognition": _recognition_report(high_recognition),
		"after_rows": _lead_ids(discovered_rows),
		"after_exposed": after_exposed,
		"referral_bridge_contact_id": BRIDGE_CONTACT_ID,
		"referral_success": bool(referral_result.get("success", false)),
		"referral_contact_id": str(referral_result.get("contact_id", "")),
		"referral_type": str(referral_result.get("referral_type", "")),
		"referral_connection_score": int(referral_result.get("connection_score", 0)),
		"referral_can_meet": bool(referral_row.get("can_meet", false)),
		"referral_source_type": str(referral_row.get("source_type", "")),
		"referral_source_id": str(referral_row.get("source_id", "")),
		"referral_referred_by_contact_id": str(referral_row.get("referred_by_contact_id", "")),
		"referral_privacy_gate": str(referral_row.get("privacy_gate", "")),
		"referral_required": bool(referral_row.get("referral_required", false))
	}


func _network_account(stage: String) -> Dictionary:
	var account_id: String = "inner_circle_baseline_%s" % stage
	return {
		"id": account_id,
		"display_name": "Baseline %s Source" % stage.capitalize(),
		"handle": "@%s" % account_id,
		"tier": 4,
		"verified": false,
		"voice": "evidence",
		"public_post_count": 0,
		"social_profile": {
			"role": "Network source fixture",
			"intro": "Synthetic Network source for inner-circle progression baseline.",
			"description": "Synthetic Network source for inner-circle progression baseline.",
			"risk_profile": "clean",
			"account_origin": "network_contact",
			"network_source": true,
			"network_contact_id": "baseline_contact_%s" % stage,
			"dialog_trees": ["network_source_followup", "network_relationship_probe", "source_check"],
			"target_company_id": "baseline_company",
			"target_ticker": "BASE",
			"target_company_name": "Baseline Company"
		}
	}


func _account_state(relationship: int, credibility: int, importance: int, exposure: int = 25) -> Dictionary:
	return {
		"relationship": relationship,
		"exposure": exposure,
		"credibility": credibility,
		"importance": importance,
		"relationship_stage": _expected_stage(relationship, credibility, importance),
		"following": true,
		"connected": false,
		"likes_given": 3,
		"last_like_day_index": DAY_INDEX - 1,
		"interaction_count": 3,
		"last_interaction_day_index": DAY_INDEX - 1,
		"like_relationship_progress": 0.0,
		"unfollowed_ask_count": 0,
		"last_unfollowed_ask_day_index": -1,
		"timeline": []
	}


func _expected_stage(relationship: int, credibility: int, importance: int) -> String:
	if relationship >= 70 and credibility >= 45 and importance >= 55:
		return "inner_circle_candidate"
	if relationship >= 45:
		return "trusted"
	if relationship >= 18:
		return "familiar"
	return "stranger"


func _social_state_for_account(account: Dictionary, account_state: Dictionary) -> Dictionary:
	var account_id: String = str(account.get("id", ""))
	return {
		"account_states": {
			account_id: account_state
		},
		"post_interactions": {},
		"liked_posts": {},
		"messages": {},
		"network_contact_definitions": {},
		"dialog_state": {
			"accounts": {},
			"posts": {}
		},
		"daily_public_interactions": {
			"day_index": DAY_INDEX,
			"account_action_counts": {}
		}
	}


func _daily_action() -> Dictionary:
	return {
		"day_index": DAY_INDEX,
		"used": 0,
		"remaining": 99,
		"limit": 99
	}


func _dialog_option_audit_rows(source_options: Array) -> Array:
	var rows: Array = []
	for option_value: Variant in source_options:
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		rows.append({
			"option_id": str(option.get("option_id", option.get("id", ""))),
			"action_id": str(option.get("action_id", option.get("id", ""))),
			"label": str(option.get("label", "")),
			"tree_id": str(option.get("tree_id", "")),
			"node_id": str(option.get("node_id", "")),
			"enabled": bool(option.get("enabled", true)),
			"blocked_reason": str(option.get("blocked_reason", "")),
			"player_text": str(option.get("player_text", ""))
		})
	return rows


func _enabled_option_count(options: Array) -> int:
	var count: int = 0
	for option_value: Variant in options:
		if typeof(option_value) == TYPE_DICTIONARY and bool(option_value.get("enabled", true)):
			count += 1
	return count


func _option_ids(options: Array) -> Array:
	var rows: Array = []
	for option_value: Variant in options:
		if typeof(option_value) == TYPE_DICTIONARY:
			rows.append(str(option_value.get("option_id", "")))
	return rows


func _authored_option_count(feed_data: Dictionary, tree_id: String, node_id: String) -> int:
	var trees: Dictionary = feed_data.get("dialog_trees", {}) if typeof(feed_data.get("dialog_trees", {})) == TYPE_DICTIONARY else {}
	var tree: Dictionary = trees.get(tree_id, {}) if typeof(trees.get(tree_id, {})) == TYPE_DICTIONARY else {}
	var nodes: Dictionary = tree.get("nodes", {}) if typeof(tree.get("nodes", {})) == TYPE_DICTIONARY else {}
	var node: Dictionary = nodes.get(node_id, {}) if typeof(nodes.get(node_id, {})) == TYPE_DICTIONARY else {}
	var options: Array = node.get("options", []) if typeof(node.get("options", [])) == TYPE_ARRAY else []
	return options.size()


func _stage_rows_have_distinct_options(stage_rows: Array) -> bool:
	var signatures: Dictionary = {}
	for row_value: Variant in stage_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var signature: String = JSON.stringify(row.get("option_ids", []) if typeof(row.get("option_ids", [])) == TYPE_ARRAY else [])
		if signature.is_empty() or signatures.has(signature):
			return false
		signatures[signature] = true
	return signatures.size() == stage_rows.size()


func _seed_high_recognition_state(target_company: Dictionary) -> void:
	RunState.player_portfolio["cash"] = 5000000.0
	var holdings: Dictionary = {}
	var seeded_holdings: int = 0
	for company_id_value: Variant in RunState.company_order:
		if seeded_holdings >= 6:
			break
		var company_id: String = str(company_id_value)
		var company: Dictionary = RunState.get_company(company_id)
		var current_price: float = max(float(company.get("current_price", 0.0)), 1.0)
		var shares: int = max(100, int(floor(200000000.0 / current_price / 100.0)) * 100)
		holdings[company_id] = {
			"company_id": company_id,
			"shares": shares,
			"average_price": current_price
		}
		seeded_holdings += 1
	RunState.player_portfolio["holdings"] = holdings

	var contacts: Dictionary = RunState.get_network_contacts()
	var discoveries: Dictionary = RunState.get_network_discoveries()
	for contact_id_value: Variant in LOW_CONTACT_IDS:
		var contact_id: String = str(contact_id_value)
		var contact: Dictionary = _contact_definition(contact_id)
		if contact.is_empty():
			continue
		contacts[contact_id] = {
			"contact_id": contact_id,
			"met": true,
			"relationship": max(int(contact.get("base_relationship", 25)), 45),
			"met_day_index": RunState.day_index,
			"last_source_type": "recognition_seed"
		}
		discoveries[contact_id] = _discovery_row(contact_id, "recognition_seed", "inner_circle_baseline_seed", target_company)
	RunState.set_network_contacts(contacts)
	RunState.set_network_discoveries(discoveries)


func _seed_inner_circle_bridge_state(contact_id: String, target_company: Dictionary) -> void:
	var contact: Dictionary = _contact_definition(contact_id)
	if contact.is_empty():
		return
	var contacts: Dictionary = RunState.get_network_contacts()
	var discoveries: Dictionary = RunState.get_network_discoveries()
	contacts[contact_id] = {
		"contact_id": contact_id,
		"met": true,
		"relationship": 62,
		"met_day_index": RunState.day_index,
		"last_source_type": "recognition_seed",
		"last_tip_label": "Useful read",
		"last_tip_day_index": RunState.day_index - 1
	}
	discoveries[contact_id] = _discovery_row(contact_id, "recognition_seed", "inner_circle_bridge_seed", target_company)
	RunState.set_network_contacts(contacts)
	RunState.set_network_discoveries(discoveries)


func _article_for_high_contact(target_company: Dictionary, high_contact: Dictionary, suffix: String) -> Dictionary:
	var contact_sector_ids: Array = high_contact.get("sector_ids", []) if typeof(high_contact.get("sector_ids", [])) == TYPE_ARRAY else []
	var target_sector_id: String = str(target_company.get("sector_id", ""))
	var company_id: String = str(target_company.get("id", ""))
	if not (target_sector_id in contact_sector_ids):
		target_sector_id = ""
		company_id = ""
	return {
		"id": "inner_circle_baseline_%s_%d" % [suffix, RunState.day_index],
		"category": "mna",
		"target_company_id": company_id,
		"target_sector_id": target_sector_id,
		"author_contact_id": HIGH_CONTACT_ID,
		"title": "Inner-circle baseline owner-family legal signal",
		"summary": "%s is attached to a controlling-shareholder legal read." % str(high_contact.get("display_name", "A source"))
	}


func _company_context_for_contact(contact: Dictionary) -> Dictionary:
	var sector_ids: Array = contact.get("sector_ids", []) if typeof(contact.get("sector_ids", [])) == TYPE_ARRAY else []
	for company_id_value: Variant in RunState.company_order:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		if str(definition.get("sector_id", "")) in sector_ids:
			return _company_context(company_id)
	if not RunState.company_order.is_empty():
		return _company_context(str(RunState.company_order[0]))
	return {}


func _company_context(company_id: String) -> Dictionary:
	var company: Dictionary = RunState.get_company(company_id)
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	return {
		"id": company_id,
		"ticker": str(definition.get("ticker", company_id.to_upper())),
		"sector_id": str(definition.get("sector_id", "")),
		"current_price": float(company.get("current_price", 0.0))
	}


func _network_row(contact_id: String, bucket_name: String) -> Dictionary:
	var snapshot: Dictionary = GameManager.get_network_snapshot()
	for row_value: Variant in snapshot.get(bucket_name, []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("id", row.get("contact_id", ""))) == contact_id:
			return row
	return {}


func _discovery_row(contact_id: String, source_type: String, source_id: String, target_company: Dictionary) -> Dictionary:
	return {
		"contact_id": contact_id,
		"discovered": true,
		"source_type": source_type,
		"source_id": source_id,
		"target_company_id": str(target_company.get("id", "")),
		"target_company_ids": [str(target_company.get("id", ""))],
		"target_ticker": str(target_company.get("ticker", "")),
		"target_sector_id": str(target_company.get("sector_id", "")),
		"lead_score": 96,
		"day_index": RunState.day_index
	}


func _contains_contact(rows: Array, contact_id: String) -> bool:
	for row_value: Variant in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("id", row.get("contact_id", ""))) == contact_id:
			return true
	return false


func _lead_ids(rows: Array) -> Array:
	var ids: Array = []
	for row_value: Variant in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		ids.append(str(row.get("id", row.get("contact_id", ""))))
	ids.sort()
	return ids


func _contact_definition(contact_id: String) -> Dictionary:
	for contact_value: Variant in DataRepository.get_contact_network_data().get("contacts", []):
		if typeof(contact_value) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = contact_value
		if str(contact.get("id", "")) == contact_id:
			return contact.duplicate(true)
	return {}


func _recognition_report(recognition: Dictionary) -> Dictionary:
	return {
		"score": _round_to(float(recognition.get("score", 0.0)), 2),
		"label": str(recognition.get("label", "")),
		"tier_index": int(recognition.get("tier_index", 0)),
		"contact_cap": int(recognition.get("contact_cap", 0)),
		"equity_score": _round_to(float(recognition.get("equity_score", 0.0)), 2),
		"ownership_score": _round_to(float(recognition.get("ownership_score", 0.0)), 2),
		"contact_score": _round_to(float(recognition.get("contact_score", 0.0)), 2)
	}


func _round_to(value: float, digits: int) -> float:
	var scale: float = pow(10.0, float(digits))
	return round(value * scale) / scale


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
	get_tree().quit(1)
