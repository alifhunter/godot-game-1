extends RefCounted

const LOT_SIZE := 100
const REFERRAL_RELATIONSHIP_THRESHOLD := 45
const REFERRAL_RELATIONSHIP_COST := 10
const REFERRAL_CONNECTION_THRESHOLD := 50
const MAX_COMPANY_LEADS_PER_FLOATER := 2


func build_snapshot(run_state, data_repository) -> Dictionary:
	var contacts: Dictionary = run_state.get_network_contacts()
	var discoveries: Dictionary = run_state.get_network_discoveries()
	var requests: Dictionary = run_state.get_network_requests()
	var recognition: Dictionary = build_recognition_snapshot(run_state)
	var contact_rows: Array = []
	var discovered_rows: Array = []

	for contact_value in data_repository.get_contact_network_data().get("contacts", []):
		var contact: Dictionary = contact_value
		var contact_id: String = str(contact.get("id", ""))
		if contact_id.is_empty():
			continue
		if str(contact.get("affiliation_type", "floater")) == "insider_template":
			continue
		var runtime: Dictionary = contacts.get(contact_id, {})
		var discovery: Dictionary = discoveries.get(contact_id, {})
		var row: Dictionary = _contact_row(contact, runtime, discovery, recognition)
		if bool(runtime.get("met", false)):
			contact_rows.append(row)
		elif bool(discovery.get("discovered", false)):
			discovered_rows.append(row)

	var generated_contact_ids := {}
	for contact_id_value in contacts.keys():
		var contact_id: String = str(contact_id_value)
		if contact_id.begins_with("insider_"):
			generated_contact_ids[contact_id] = true
	for contact_id_value in discoveries.keys():
		var contact_id: String = str(contact_id_value)
		if contact_id.begins_with("insider_"):
			generated_contact_ids[contact_id] = true
	for generated_contact_id_value in generated_contact_ids.keys():
		var generated_contact_id: String = str(generated_contact_id_value)
		var generated_contact: Dictionary = _contact_definition(run_state, data_repository, generated_contact_id)
		if generated_contact.is_empty():
			continue
		var runtime: Dictionary = contacts.get(generated_contact_id, {})
		var discovery: Dictionary = discoveries.get(generated_contact_id, {})
		var row: Dictionary = _contact_row(generated_contact, runtime, discovery, recognition)
		if bool(runtime.get("met", false)):
			contact_rows.append(row)
		elif bool(discovery.get("discovered", false)):
			discovered_rows.append(row)

	contact_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("display_name", "")) < str(b.get("display_name", ""))
	)
	discovered_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("display_name", "")) < str(b.get("display_name", ""))
	)

	return {
		"recognition": recognition,
		"contacts": contact_rows,
		"discoveries": discovered_rows,
		"requests": _request_rows(requests),
		"met_count": contact_rows.size(),
		"contact_cap": int(recognition.get("contact_cap", 2))
	}


func build_recognition_snapshot(run_state) -> Dictionary:
	var starting_cash: float = max(float(run_state.get_difficulty_config().get("starting_cash", 1.0)), 1.0)
	var equity: float = max(run_state.get_total_equity(), 0.0)
	var equity_ratio: float = clamp((equity - starting_cash) / starting_cash, 0.0, 1.0)
	var equity_score: float = equity_ratio * 40.0

	var holdings: Dictionary = run_state.player_portfolio.get("holdings", {})
	var held_company_count: int = 0
	for holding_value in holdings.values():
		var holding: Dictionary = holding_value
		if int(holding.get("shares", 0)) >= LOT_SIZE:
			held_company_count += 1
	var exposure_ratio: float = 0.0
	if equity > 0.0:
		exposure_ratio = clamp(run_state.get_portfolio_market_value() / equity, 0.0, 1.0)
	var ownership_score: float = clamp(float(held_company_count) / 6.0, 0.0, 1.0) * 15.0 + exposure_ratio * 15.0

	var met_count: int = 0
	for runtime_value in run_state.get_network_contacts().values():
		var runtime: Dictionary = runtime_value
		if bool(runtime.get("met", false)):
			met_count += 1
	var contact_score: float = clamp(float(met_count) / 8.0, 0.0, 1.0) * 30.0
	var score: float = clamp(equity_score + ownership_score + contact_score, 0.0, 100.0)
	var tier: Dictionary = _recognition_tier(score)
	return {
		"score": score,
		"label": str(tier.get("label", "Unknown")),
		"tier_index": int(tier.get("tier_index", 0)),
		"contact_cap": int(tier.get("contact_cap", 2)),
		"equity_score": equity_score,
		"ownership_score": ownership_score,
		"contact_score": contact_score
	}


func discover_from_article(run_state, data_repository, article: Dictionary) -> Array:
	var company_id: String = str(article.get("target_company_id", ""))
	var sector_id: String = str(article.get("target_sector_id", ""))
	return _discover_matching_contacts(
		run_state,
		data_repository,
		company_id,
		sector_id,
		str(article.get("category", "")),
		"news",
		str(article.get("id", "")),
		true
	)


func discover_for_company(run_state, data_repository, company_id: String) -> Array:
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	if definition.is_empty():
		return []
	return _discover_matching_contacts(
		run_state,
		data_repository,
		company_id,
		str(definition.get("sector_id", "")),
		"company",
		"profile",
		company_id,
		false
	)


func meet_contact(run_state, data_repository, contact_id: String, source_context: Dictionary = {}) -> Dictionary:
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	if contact.is_empty():
		return {"success": false, "message": "Unknown contact."}
	var recognition: Dictionary = build_recognition_snapshot(run_state)
	var contacts: Dictionary = run_state.get_network_contacts()
	var discoveries: Dictionary = run_state.get_network_discoveries()
	var runtime: Dictionary = contacts.get(contact_id, {})
	if bool(runtime.get("met", false)):
		return {"success": false, "message": "%s is already in your network." % str(contact.get("display_name", "Contact"))}
	if not bool(discoveries.get(contact_id, {}).get("discovered", false)):
		return {"success": false, "message": "You have not discovered that contact yet."}
	var has_warm_referral: bool = str(discoveries.get(contact_id, {}).get("source_type", "")) == "referral"
	if not has_warm_referral and int(recognition.get("score", 0)) < int(contact.get("recognition_required", 0)):
		return {"success": false, "message": "Your recognition is not high enough yet."}
	var met_count: int = 0
	for runtime_value in contacts.values():
		var existing_runtime: Dictionary = runtime_value
		if bool(existing_runtime.get("met", false)):
			met_count += 1
	if met_count >= int(recognition.get("contact_cap", 2)):
		return {"success": false, "message": "Your network is full for this recognition tier."}

	runtime["contact_id"] = contact_id
	runtime["met"] = true
	runtime["relationship"] = int(contact.get("base_relationship", data_repository.get_contact_network_data().get("relationship_default", 25)))
	runtime["met_day_index"] = run_state.day_index
	runtime["last_source_type"] = str(source_context.get("source_type", "network"))
	contacts[contact_id] = runtime
	run_state.set_network_contacts(contacts)
	return {"success": true, "message": "Met %s." % str(contact.get("display_name", "Contact")), "contact": runtime.duplicate(true)}


func request_tip(run_state, data_repository, contact_id: String, company_id: String = "") -> Dictionary:
	var resolved_company_id: String = _resolve_target_company_id(run_state, data_repository, contact_id, company_id)
	var build_result: Dictionary = _build_and_store_contact_arc(run_state, data_repository, contact_id, resolved_company_id, "tip")
	if not bool(build_result.get("success", false)):
		return build_result
	_adjust_relationship(run_state, contact_id, -2)
	return build_result


func accept_request(run_state, data_repository, contact_id: String, company_id: String = "") -> Dictionary:
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	if contact.is_empty():
		return {"success": false, "message": "Unknown contact."}
	if not _is_met(run_state, contact_id):
		return {"success": false, "message": "Meet this contact first."}
	var resolved_company_id: String = _resolve_target_company_id(run_state, data_repository, contact_id, company_id)
	if resolved_company_id.is_empty():
		return {"success": false, "message": "No target company is available for that request."}
	if _has_pending_request(run_state, contact_id, resolved_company_id):
		return {"success": false, "message": "%s already has a pending position request on that stock." % str(contact.get("display_name", "Contact"))}
	var request_id: String = "%s|%s|%d" % [contact_id, resolved_company_id, run_state.day_index]
	var requests: Dictionary = run_state.get_network_requests()
	requests[request_id] = {
		"id": request_id,
		"contact_id": contact_id,
		"target_company_id": resolved_company_id,
		"status": "pending",
		"created_day_index": run_state.day_index,
		"due_day_index": run_state.day_index + 3,
		"relationship_delta_success": 8,
		"relationship_delta_failure": -6
	}
	run_state.set_network_requests(requests)
	return {"success": true, "message": "%s gave you a position request." % str(contact.get("display_name", "Contact")), "request_id": request_id}


func request_referral(run_state, data_repository, contact_id: String, company_id: String = "", affiliation_role: String = "") -> Dictionary:
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	if contact.is_empty():
		return {"success": false, "message": "Unknown contact."}
	if str(contact.get("affiliation_type", "floater")) != "floater":
		return {"success": false, "message": "Only floaters can introduce company insiders."}
	if not _is_met(run_state, contact_id):
		return {"success": false, "message": "Meet this contact first."}
	var relationship: int = int(run_state.get_network_contacts().get(contact_id, {}).get("relationship", 0))
	if relationship < REFERRAL_RELATIONSHIP_THRESHOLD:
		return {"success": false, "message": "Relationship must reach %d before asking for referrals." % REFERRAL_RELATIONSHIP_THRESHOLD}

	var target_company_id: String = company_id
	if target_company_id.is_empty():
		target_company_id = _resolve_target_company_id(run_state, data_repository, contact_id, company_id)
	var insider: Dictionary = _best_referral_insider(run_state, contact_id, target_company_id, affiliation_role)
	if insider.is_empty():
		return {"success": false, "message": "No connected insider referral is available for that company."}

	var insider_id: String = str(insider.get("id", insider.get("contact_id", "")))
	var connection_score: int = _connection_score_for_floater(insider, contact_id)
	if connection_score < REFERRAL_CONNECTION_THRESHOLD:
		return {"success": false, "message": "This contact is not close enough to that insider."}

	var discoveries: Dictionary = run_state.get_network_discoveries()
	discoveries[insider_id] = {
		"contact_id": insider_id,
		"discovered": true,
		"source_type": "referral",
		"source_id": contact_id,
		"referred_by_contact_id": contact_id,
		"target_company_id": str(insider.get("affiliated_company_id", insider.get("company_id", ""))),
		"target_company_ids": [str(insider.get("affiliated_company_id", insider.get("company_id", "")))],
		"target_sector_id": str(insider.get("sector_id", "")),
		"connection_score": connection_score,
		"day_index": run_state.day_index
	}
	run_state.set_network_discoveries(discoveries)
	_adjust_relationship(run_state, contact_id, -REFERRAL_RELATIONSHIP_COST)
	return {
		"success": true,
		"message": "%s introduced you to %s." % [
			str(contact.get("display_name", "Contact")),
			str(insider.get("display_name", "an insider"))
		],
		"contact_id": insider_id
	}


func process_due_requests(run_state, data_repository) -> Array:
	var requests: Dictionary = run_state.get_network_requests()
	var results: Array = []
	for request_id_value in requests.keys():
		var request_id: String = str(request_id_value)
		var request: Dictionary = requests.get(request_id, {})
		if str(request.get("status", "")) != "pending":
			continue
		if int(request.get("due_day_index", 0)) > run_state.day_index:
			continue

		var contact_id: String = str(request.get("contact_id", ""))
		var company_id: String = str(request.get("target_company_id", ""))
		if _has_at_least_one_lot(run_state, company_id):
			if _has_active_contact_arc(run_state, contact_id, company_id):
				requests[request_id] = request
				continue
			var arc_result: Dictionary = _build_and_store_contact_arc(run_state, data_repository, contact_id, company_id, "request")
			if not bool(arc_result.get("success", false)):
				requests[request_id] = request
				continue
			request["status"] = "completed"
			request["completed_day_index"] = run_state.day_index
			_adjust_relationship(run_state, contact_id, int(request.get("relationship_delta_success", 8)))
			results.append(arc_result)
		else:
			request["status"] = "missed"
			request["completed_day_index"] = run_state.day_index
			_adjust_relationship(run_state, contact_id, int(request.get("relationship_delta_failure", -6)))
			results.append({"success": false, "message": "Network request missed.", "request_id": request_id})
		requests[request_id] = request
	run_state.set_network_requests(requests)
	return results


func _discover_matching_contacts(
	run_state,
	data_repository,
	company_id: String,
	sector_id: String,
	category: String,
	source_type: String,
	source_id: String,
	include_insiders: bool
) -> Array:
	var network_data: Dictionary = data_repository.get_contact_network_data()
	var recognition: Dictionary = build_recognition_snapshot(run_state)
	var discoveries: Dictionary = run_state.get_network_discoveries()
	var contacts: Dictionary = run_state.get_network_contacts()
	var discovered: Array = []
	var discovery_limit: int = _discovery_limit_for_source(source_type, run_state)
	if include_insiders and not company_id.is_empty():
		_discover_company_insiders(run_state, company_id, category, source_type, source_id, recognition, discoveries, contacts, discovered, discovery_limit)
	if discovered.size() >= discovery_limit:
		run_state.set_network_discoveries(discoveries)
		return discovered
	var candidates: Array = []
	for contact_value in network_data.get("contacts", []):
		var contact: Dictionary = contact_value
		if str(contact.get("affiliation_type", "floater")) != "floater":
			continue
		var contact_id: String = str(contact.get("id", ""))
		if contact_id.is_empty() or bool(contacts.get(contact_id, {}).get("met", false)):
			continue
		if not _can_add_company_lead(discoveries.get(contact_id, {}), company_id):
			continue
		if int(recognition.get("score", 0)) < int(contact.get("recognition_required", 0)):
			continue
		var lead_score: float = _floater_discovery_score(contact, company_id, sector_id, category, source_type)
		if lead_score < 0.0:
			continue
		candidates.append({"contact": contact, "score": lead_score})

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	for candidate_value in candidates:
		var candidate: Dictionary = candidate_value
		var contact: Dictionary = candidate.get("contact", {})
		var contact_id: String = str(contact.get("id", ""))
		var discovery: Dictionary = discoveries.get(contact_id, {})
		var target_company_ids: Array = _contact_company_targets(discovery)
		if not company_id.is_empty() and not target_company_ids.has(company_id):
			target_company_ids.append(company_id)
		discovery["contact_id"] = contact_id
		discovery["discovered"] = true
		discovery["source_type"] = source_type
		discovery["source_id"] = source_id
		discovery["target_company_id"] = company_id if not company_id.is_empty() else str(discovery.get("target_company_id", ""))
		discovery["target_company_ids"] = target_company_ids
		discovery["target_sector_id"] = sector_id
		discovery["lead_score"] = int(round(float(candidate.get("score", 0.0))))
		discovery["day_index"] = run_state.day_index
		discoveries[contact_id] = discovery
		discovered.append(_contact_row(contact, contacts.get(contact_id, {}), discovery, recognition))
		if discovered.size() >= discovery_limit:
			break
	run_state.set_network_discoveries(discoveries)
	return discovered


func _discovery_limit_for_source(source_type: String, run_state) -> int:
	if source_type == "profile":
		return max(run_state.company_order.size(), 1)
	if source_type == "news":
		return max(run_state.company_order.size(), 1)
	return 3


func _floater_discovery_score(contact: Dictionary, company_id: String, sector_id: String, category: String, source_type: String) -> float:
	var sector_match: bool = (not sector_id.is_empty()) and (sector_id in contact.get("sector_ids", []))
	var category_match: bool = (not category.is_empty()) and (category in contact.get("categories", []))
	var company_targeted: bool = not company_id.is_empty()
	if company_targeted and not sector_match:
		return -1.0
	if not company_targeted and not category_match:
		return -1.0
	if not sector_match and not category_match:
		return -1.0

	var score: float = 0.0
	if sector_match:
		score += 65.0
	if category_match:
		score += (5.0 if category == "company" else 30.0)
	if source_type == "profile":
		score += 8.0
	score += clamp(float(contact.get("reliability", 0.5)), 0.0, 1.0) * 10.0
	score += max(0.0, 50.0 - float(contact.get("recognition_required", 0))) * 0.1
	return score


func _discover_company_insiders(
	run_state,
	company_id: String,
	category: String,
	source_type: String,
	source_id: String,
	recognition: Dictionary,
	discoveries: Dictionary,
	contacts: Dictionary,
	discovered: Array,
	discovery_limit: int
) -> void:
	var roster: Array = _management_roster_for_company(run_state, company_id)
	for insider_value in roster:
		var insider: Dictionary = insider_value
		var insider_id: String = str(insider.get("id", insider.get("contact_id", "")))
		if insider_id.is_empty() or bool(contacts.get(insider_id, {}).get("met", false)):
			continue
		if bool(discoveries.get(insider_id, {}).get("discovered", false)):
			continue
		if int(recognition.get("score", 0)) < int(insider.get("recognition_required", 0)):
			continue
		if not category.is_empty() and not (category in insider.get("categories", [])):
			continue
		var discovery: Dictionary = {
			"contact_id": insider_id,
			"discovered": true,
			"source_type": source_type,
			"source_id": source_id,
			"target_company_id": company_id,
			"target_company_ids": [company_id],
			"target_sector_id": str(insider.get("sector_id", "")),
			"lead_score": 100,
			"day_index": run_state.day_index
		}
		discoveries[insider_id] = discovery
		discovered.append(_contact_row(insider, contacts.get(insider_id, {}), discovery, recognition))
		if discovered.size() >= discovery_limit:
			return


func _build_and_store_contact_arc(run_state, data_repository, contact_id: String, company_id: String, action: String) -> Dictionary:
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	if contact.is_empty():
		return {"success": false, "message": "Unknown contact."}
	if not _is_met(run_state, contact_id):
		return {"success": false, "message": "Meet this contact first."}
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	if definition.is_empty():
		return {"success": false, "message": "No target company is available."}
	if _has_active_contact_arc(run_state, contact_id, company_id):
		return {"success": false, "message": "That contact already has an active read on this stock."}

	var start_day: int = run_state.day_index + 1
	var tone: String = str(contact.get("tone", "mixed"))
	var sentiment: float = _sentiment_for_contact(contact, action)
	var target_ticker: String = str(definition.get("ticker", company_id.to_upper()))
	var arc: Dictionary = {
		"arc_id": "contact_%s_%s_%s_%d" % [action, contact_id, company_id, start_day],
		"scope": "company",
		"event_id": "contact_%s" % action,
		"event_family": "contact",
		"category": "network",
		"tone": tone,
		"target_company_id": company_id,
		"target_sector_id": str(definition.get("sector_id", "")),
		"target_ticker": target_ticker,
		"target_company_name": str(definition.get("name", target_ticker)),
		"trade_date": run_state.get_current_trade_date(),
		"description": _contact_arc_description(contact, target_ticker, action),
		"broker_bias": "institution",
		"source_contact_id": contact_id,
		"source_contact_name": str(contact.get("display_name", "")),
		"source_action": action,
		"phase_schedule": [
			{"id": "hidden_whisper", "label": "Hidden whisper", "duration_days": 1, "sentiment_shift": sentiment * 0.55, "volatility_multiplier": 1.12, "visibility": "hidden", "hidden_flag": "contact_whisper"},
			{"id": "visible_reaction", "label": "Visible reaction", "duration_days": 2, "sentiment_shift": sentiment, "volatility_multiplier": 1.22, "visibility": "visible", "hidden_flag": ""},
			{"id": "digestion", "label": "Digestion", "duration_days": 2, "sentiment_shift": sentiment * -0.28, "volatility_multiplier": 0.95, "visibility": "visible", "hidden_flag": ""}
		],
		"duration_days": 5,
		"start_day_index": start_day,
		"end_day_index": start_day + 4,
		"hidden_story_flag": "contact_whisper"
	}
	run_state.add_network_company_arc(arc)
	return {"success": true, "message": "%s created a %s arc on %s." % [str(contact.get("display_name", "Contact")), action, target_ticker], "arc": arc}


func _all_contact_definitions(run_state, data_repository) -> Array:
	var definitions: Array = []
	for contact_value in data_repository.get_contact_network_data().get("contacts", []):
		var contact: Dictionary = contact_value
		definitions.append(contact.duplicate(true))
	definitions.append_array(_generated_insider_definitions(run_state))
	return definitions


func _generated_insider_definitions(run_state) -> Array:
	var insiders: Array = []
	for company_id_value in run_state.company_order:
		var company_id: String = str(company_id_value)
		insiders.append_array(_management_roster_for_company(run_state, company_id))
	return insiders


func _management_roster_for_company(run_state, company_id: String) -> Array:
	var profile: Dictionary = run_state.get_company_profile(company_id, false, false)
	var rows: Array = []
	for row_value in profile.get("management_roster", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value.duplicate(true)
		var contact_id: String = str(row.get("id", row.get("contact_id", "")))
		if contact_id.is_empty():
			contact_id = "insider_%s_%s" % [company_id, str(row.get("affiliation_role", "management"))]
		row["id"] = contact_id
		row["contact_id"] = contact_id
		row["affiliation_type"] = "insider"
		row["affiliated_company_id"] = str(row.get("affiliated_company_id", row.get("company_id", company_id)))
		row["company_id"] = str(row.get("company_id", company_id))
		rows.append(row)
	return rows


func _best_referral_insider(run_state, floater_id: String, company_id: String, affiliation_role: String) -> Dictionary:
	var discoveries: Dictionary = run_state.get_network_discoveries()
	var contacts: Dictionary = run_state.get_network_contacts()
	var candidates: Array = []
	for insider_value in _management_roster_for_company(run_state, company_id):
		var insider: Dictionary = insider_value
		var insider_id: String = str(insider.get("id", insider.get("contact_id", "")))
		if insider_id.is_empty():
			continue
		if not affiliation_role.is_empty() and str(insider.get("affiliation_role", "")) != affiliation_role:
			continue
		if bool(contacts.get(insider_id, {}).get("met", false)) or bool(discoveries.get(insider_id, {}).get("discovered", false)):
			continue
		var score: int = _connection_score_for_floater(insider, floater_id)
		candidates.append({"insider": insider, "score": score})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)
	if candidates.is_empty():
		return {}
	return candidates[0].get("insider", {}).duplicate(true)


func _connection_score_for_floater(insider: Dictionary, floater_id: String) -> int:
	for bridge_value in insider.get("connected_floaters", []):
		if typeof(bridge_value) != TYPE_DICTIONARY:
			continue
		var bridge: Dictionary = bridge_value
		if str(bridge.get("contact_id", "")) == floater_id:
			return int(bridge.get("score", 0))
	return 0


func _contact_definition(run_state, data_repository, contact_id: String) -> Dictionary:
	for contact_value in data_repository.get_contact_network_data().get("contacts", []):
		var contact: Dictionary = contact_value
		if str(contact.get("id", "")) == contact_id:
			return contact.duplicate(true)
	for insider_value in _generated_insider_definitions(run_state):
		var insider: Dictionary = insider_value
		if str(insider.get("id", insider.get("contact_id", ""))) == contact_id:
			return insider.duplicate(true)
	return {}


func _contact_row(contact: Dictionary, runtime: Dictionary, discovery: Dictionary, recognition: Dictionary) -> Dictionary:
	var affiliation_type: String = str(contact.get("affiliation_type", "floater"))
	var affiliated_company_id: String = str(contact.get("affiliated_company_id", contact.get("company_id", "")))
	var target_company_ids: Array = _contact_company_targets(discovery)
	var primary_target_company_id: String = str(discovery.get("target_company_id", affiliated_company_id))
	if primary_target_company_id.is_empty() and not target_company_ids.is_empty():
		primary_target_company_id = str(target_company_ids[0])
	return {
		"id": str(contact.get("id", "")),
		"display_name": str(contact.get("display_name", "")),
		"role": str(contact.get("role", "")),
		"intro": str(contact.get("intro", "")),
		"affiliation_type": affiliation_type,
		"affiliation_role": str(contact.get("affiliation_role", "")),
		"affiliated_company_id": affiliated_company_id,
		"company_id": affiliated_company_id,
		"template_contact_id": str(contact.get("template_contact_id", "")),
		"relationship": int(runtime.get("relationship", 0)),
		"met": bool(runtime.get("met", false)),
		"discovered": bool(discovery.get("discovered", false)),
		"can_meet": bool(discovery.get("discovered", false)) and not bool(runtime.get("met", false)) and (str(discovery.get("source_type", "")) == "referral" or int(recognition.get("score", 0)) >= int(contact.get("recognition_required", 0))),
		"recognition_required": int(contact.get("recognition_required", 0)),
		"source_type": str(discovery.get("source_type", "")),
		"source_id": str(discovery.get("source_id", "")),
		"referred_by_contact_id": str(discovery.get("referred_by_contact_id", "")),
		"connection_score": int(discovery.get("connection_score", 0)),
		"target_company_id": primary_target_company_id,
		"target_company_ids": target_company_ids,
		"target_sector_id": str(discovery.get("target_sector_id", contact.get("sector_id", ""))),
		"sector_ids": contact.get("sector_ids", []).duplicate(true),
		"categories": contact.get("categories", []).duplicate(true),
		"lead_score": int(discovery.get("lead_score", 0))
	}


func _contact_company_targets(discovery: Dictionary) -> Array:
	var targets: Array = []
	for company_id_value in discovery.get("target_company_ids", []):
		var company_id: String = str(company_id_value)
		if not company_id.is_empty() and not targets.has(company_id):
			targets.append(company_id)
	var primary_company_id: String = str(discovery.get("target_company_id", ""))
	if not primary_company_id.is_empty() and not targets.has(primary_company_id):
		targets.append(primary_company_id)
	return targets


func _can_add_company_lead(discovery: Dictionary, company_id: String) -> bool:
	if company_id.is_empty():
		return true
	var targets: Array = _contact_company_targets(discovery)
	return (not targets.has(company_id)) and targets.size() < MAX_COMPANY_LEADS_PER_FLOATER


func _request_rows(requests: Dictionary) -> Array:
	var rows: Array = []
	for request_value in requests.values():
		var request: Dictionary = request_value
		rows.append(request.duplicate(true))
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("due_day_index", 0)) < int(b.get("due_day_index", 0))
	)
	return rows


func _recognition_tier(score: float) -> Dictionary:
	if score >= 85.0:
		return {"label": "Market Name", "tier_index": 4, "contact_cap": 12}
	if score >= 65.0:
		return {"label": "Connected Player", "tier_index": 3, "contact_cap": 8}
	if score >= 40.0:
		return {"label": "Known Trader", "tier_index": 2, "contact_cap": 5}
	if score >= 20.0:
		return {"label": "Retail Regular", "tier_index": 1, "contact_cap": 3}
	return {"label": "Unknown", "tier_index": 0, "contact_cap": 2}


func _is_met(run_state, contact_id: String) -> bool:
	return bool(run_state.get_network_contacts().get(contact_id, {}).get("met", false))


func _resolve_target_company_id(run_state, data_repository, contact_id: String, company_id: String) -> String:
	if not company_id.is_empty():
		return company_id
	var contact: Dictionary = _contact_definition(run_state, data_repository, contact_id)
	var affiliated_company_id: String = str(contact.get("affiliated_company_id", contact.get("company_id", "")))
	if not affiliated_company_id.is_empty():
		return affiliated_company_id
	var discovery: Dictionary = run_state.get_network_discoveries().get(contact_id, {})
	var discovered_company_id: String = str(discovery.get("target_company_id", ""))
	if not discovered_company_id.is_empty():
		return discovered_company_id
	return str(run_state.company_order[0]) if not run_state.company_order.is_empty() else ""


func _has_active_contact_arc(run_state, contact_id: String, company_id: String) -> bool:
	for arc_value in run_state.get_active_company_arcs():
		var arc: Dictionary = arc_value
		if str(arc.get("source_contact_id", "")) == contact_id and str(arc.get("target_company_id", "")) == company_id:
			return true
	return false


func _has_pending_request(run_state, contact_id: String, company_id: String) -> bool:
	for request_value in run_state.get_network_requests().values():
		var request: Dictionary = request_value
		if str(request.get("status", "")) != "pending":
			continue
		if str(request.get("contact_id", "")) != contact_id:
			continue
		if str(request.get("target_company_id", "")) != company_id:
			continue
		return true
	return false


func _has_at_least_one_lot(run_state, company_id: String) -> bool:
	return int(run_state.get_holding(company_id).get("shares", 0)) >= LOT_SIZE


func _adjust_relationship(run_state, contact_id: String, delta: int) -> void:
	var contacts: Dictionary = run_state.get_network_contacts()
	var runtime: Dictionary = contacts.get(contact_id, {})
	runtime["relationship"] = clampi(int(runtime.get("relationship", 25)) + delta, 0, 100)
	contacts[contact_id] = runtime
	run_state.set_network_contacts(contacts)


func _sentiment_for_contact(contact: Dictionary, action: String) -> float:
	var reliability: float = clamp(float(contact.get("reliability", 0.6)), 0.25, 0.95)
	var direction: float = -1.0 if str(contact.get("tone", "mixed")) == "negative" else 1.0
	if str(contact.get("tone", "mixed")) == "mixed":
		direction = 1.0 if action == "request" else 0.72
	return direction * lerp(0.009, 0.022, reliability)


func _contact_arc_description(contact: Dictionary, ticker: String, action: String) -> String:
	var verb: String = "tip" if action == "tip" else "request"
	return "%s gave you a %s tied to %s." % [str(contact.get("display_name", "A contact")), verb, ticker]
