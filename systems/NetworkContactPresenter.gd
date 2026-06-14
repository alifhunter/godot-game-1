extends RefCounted


static func contact_row(contact: Dictionary, runtime: Dictionary, discovery: Dictionary, recognition: Dictionary, twooter_account_prefix: String) -> Dictionary:
	var affiliation_type: String = str(contact.get("affiliation_type", "floater"))
	var affiliated_company_id: String = str(contact.get("affiliated_company_id", contact.get("company_id", "")))
	var target_company_ids: Array = contact_company_targets(discovery)
	var primary_target_company_id: String = str(discovery.get("target_company_id", affiliated_company_id))
	if primary_target_company_id.is_empty() and not target_company_ids.is_empty():
		primary_target_company_id = str(target_company_ids[0])
	var twooter_account: Dictionary = contact_twooter_account(contact, {}, null, twooter_account_prefix)
	var twooter_profile: Dictionary = twooter_account.get("social_profile", {}) if typeof(twooter_account.get("social_profile", {})) == TYPE_DICTIONARY else {}
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
		"source_label": str(discovery.get("source_label", contact.get("source_label", ""))),
		"source_note": str(discovery.get("source_note", contact.get("source_note", ""))),
		"twooter_origin": str(discovery.get("twooter_origin", contact.get("twooter_origin", ""))),
		"source_only": bool(discovery.get("source_only", contact.get("source_only", false))),
		"referred_by_contact_id": str(discovery.get("referred_by_contact_id", "")),
		"referred_by_contact_name": "",
		"referral_day_index": int(discovery.get("referral_day_index", -9999)),
		"referral_day_label": "",
		"referral_required": bool(discovery.get("referral_required", false)),
		"privacy_gate": str(discovery.get("privacy_gate", "")),
		"access_label": "",
		"provenance_label": "",
		"referral_note": "",
		"connection_score": int(discovery.get("connection_score", 0)),
		"target_company_id": primary_target_company_id,
		"target_company_ids": target_company_ids,
		"target_sector_id": str(discovery.get("target_sector_id", contact.get("sector_id", ""))),
		"sector_ids": contact.get("sector_ids", []).duplicate(true),
		"categories": contact.get("categories", []).duplicate(true),
		"has_twooter_account": not str(twooter_account.get("id", "")).is_empty(),
		"twooter_account_id": str(twooter_account.get("id", "")),
		"twooter_handle": str(twooter_account.get("handle", "")),
		"twooter_display_name": str(twooter_account.get("display_name", "")),
		"twooter_bio": str(twooter_profile.get("description", "")),
		"lead_score": int(discovery.get("lead_score", 0)),
		"last_tip_status": str(runtime.get("last_tip_status", "")),
		"last_tip_label": str(runtime.get("last_tip_label", "")),
		"last_tip_note": str(runtime.get("last_tip_note", "")),
		"last_tip_player_action_label": str(runtime.get("last_tip_player_action_label", "")),
		"last_tip_player_action_alignment": str(runtime.get("last_tip_player_action_alignment", "")),
		"last_tip_day_index": int(runtime.get("last_tip_day_index", 0)),
		"last_tip_request_day_index": int(runtime.get("last_tip_request_day_index", -9999)),
		"last_referral_day_index": int(runtime.get("last_referral_day_index", -9999)),
		"last_tip_followup_id": str(runtime.get("last_tip_followup_id", "")),
		"last_tip_followup_label": str(runtime.get("last_tip_followup_label", "")),
		"last_tip_followup_note": str(runtime.get("last_tip_followup_note", "")),
		"last_reaction_label": str(runtime.get("last_reaction_label", "")),
		"last_reaction_note": str(runtime.get("last_reaction_note", "")),
		"last_reaction_day_index": int(runtime.get("last_reaction_day_index", 0)),
		"last_reaction_twooter_account_id": str(runtime.get("last_reaction_twooter_account_id", "")),
		"last_reaction_twooter_handle": str(runtime.get("last_reaction_twooter_handle", "")),
		"last_development_lead_id": "",
		"last_development_lead_label": "",
		"last_development_lead_note": "",
		"last_development_lead_location": "",
		"last_development_lead_day_index": 0,
		"can_follow_up_tip": false,
		"tip_followup_options": [],
		"tip_history": [],
		"tip_reliability_label": "No track record yet",
		"tip_reliability_score": 50.0,
		"tip_resolved_count": 0,
		"tip_useful_count": 0,
		"tip_missed_count": 0,
		"cross_contact_label": "",
		"cross_contact_note": "",
		"cross_contact_rows": [],
		"has_direct_source_conflict": false,
		"can_ask_source_check": false,
		"source_check_label": "",
		"source_check_note": "",
		"source_check_day_index": 0
	}


static func contact_twooter_account(contact: Dictionary, discovery: Dictionary = {}, run_state = null, twooter_account_prefix: String = "network_") -> Dictionary:
	var contact_id: String = str(contact.get("id", contact.get("contact_id", "")))
	if contact_id.is_empty():
		return {}
	var sector_ids: Array = contact_string_array(contact.get("sector_ids", []))
	var categories: Array = contact_string_array(contact.get("categories", []))
	var first_sector_id: String = str(sector_ids[0]) if not sector_ids.is_empty() else str(contact.get("sector_id", ""))
	var target_company_id: String = contact_twooter_target_company_id(contact, discovery)
	var target_ticker: String = str(discovery.get("target_ticker", "")).strip_edges().to_upper()
	if target_ticker.is_empty() and run_state != null and not target_company_id.is_empty():
		target_ticker = company_ticker(run_state, target_company_id)
	var target_company_name: String = ""
	if run_state != null and not target_company_id.is_empty():
		var target_definition: Dictionary = run_state.get_effective_company_definition(target_company_id, false, false)
		target_company_name = str(target_definition.get("name", target_ticker))
	var profile: Dictionary = {
		"role": str(contact.get("role", "Network contact")),
		"intro": str(contact.get("intro", "A market contact you can approach through Twooter before they become part of your Network.")),
		"description": contact_twooter_description(contact),
		"account_origin": "network_contact",
		"network_source": true,
		"affiliation_role": str(contact.get("affiliation_role", contact.get("affiliation_type", "network"))),
		"risk_profile": contact_twooter_risk_profile(contact),
		"contact_reliability": float(contact.get("reliability", 0.5)),
		"recognition_required": int(contact.get("recognition_required", 0)),
		"contact_tone": str(contact.get("tone", "mixed")),
		"follow_weight": contact_twooter_follow_weight(contact),
		"network_contact_id": contact_id,
		"sector_id": first_sector_id,
		"sector_ids": sector_ids,
		"categories": categories,
		"target_company_id": target_company_id,
		"target_ticker": target_ticker,
		"target_company_name": target_company_name,
		"dialog_trees": contact_twooter_dialog_trees(contact)
	}
	return {
		"id": contact_twooter_account_id(contact, twooter_account_prefix),
		"display_name": str(contact.get("display_name", contact_id)),
		"handle": contact_twooter_handle(contact),
		"tier": 1,
		"verified": contact_twooter_verified(contact),
		"voice": contact_twooter_voice(contact),
		"social_profile": profile
	}


static func contact_twooter_account_id(contact: Dictionary, twooter_account_prefix: String = "network_") -> String:
	var explicit_id: String = str(contact.get("twooter_account_id", "")).strip_edges()
	if not explicit_id.is_empty():
		return explicit_id
	var contact_id: String = str(contact.get("id", contact.get("contact_id", "contact"))).strip_edges()
	return "%s%s" % [twooter_account_prefix, slug_text(contact_id, true)]


static func contact_twooter_handle(contact: Dictionary) -> String:
	var explicit_handle: String = str(contact.get("twooter_handle", "")).strip_edges()
	if not explicit_handle.is_empty():
		return explicit_handle if explicit_handle.begins_with("@") else "@%s" % explicit_handle
	var handle_seed: String = str(contact.get("display_name", contact.get("id", "contact"))).strip_edges()
	var slug: String = slug_text(handle_seed, false)
	if slug.is_empty():
		slug = slug_text(str(contact.get("id", "contact")), false)
	if slug.is_empty():
		slug = "contact"
	return "@%s" % slug.left(24)


static func contact_twooter_target_company_id(contact: Dictionary, discovery: Dictionary) -> String:
	var target_company_id: String = str(discovery.get("target_company_id", "")).strip_edges()
	if target_company_id.is_empty():
		var target_company_ids: Array = contact_company_targets(discovery)
		if not target_company_ids.is_empty():
			target_company_id = str(target_company_ids[0])
	if target_company_id.is_empty():
		target_company_id = str(contact.get("affiliated_company_id", contact.get("company_id", ""))).strip_edges()
	return target_company_id


static func contact_twooter_description(contact: Dictionary) -> String:
	var role: String = str(contact.get("role", "market contact")).strip_edges()
	var intro: String = str(contact.get("intro", "")).strip_edges()
	var reliability: float = float(contact.get("reliability", 0.5))
	var tone: String = str(contact.get("tone", "mixed")).strip_edges()
	var risk_label: String = "clean"
	if reliability < 0.48:
		risk_label = "noisy"
	elif tone == "negative" or tone == "aggressive":
		risk_label = "guarded"
	var lines: Array = []
	if not role.is_empty():
		lines.append("%s with a %s source profile." % [role, risk_label])
	if not intro.is_empty():
		lines.append(intro)
	lines.append("Start through Twooter: follow, like useful posts, then send a specific message before this source becomes a Network contact.")
	return " ".join(lines)


static func contact_twooter_dialog_trees(contact: Dictionary) -> Array:
	var affiliation_type: String = str(contact.get("affiliation_type", "floater"))
	var role: String = str(contact.get("role", "")).to_lower()
	var risk_profile: String = contact_twooter_risk_profile(contact)
	if affiliation_type == "insider":
		return ["network_insider_boundary", "network_source_followup", "source_check"]
	if risk_profile == "suspicious":
		return ["network_guarded_source", "suspicious_boundary", "source_check"]
	if role.contains("reporter") or role.contains("writer") or role.contains("columnist"):
		return ["network_source_followup", "network_relationship_probe", "source_check"]
	if role.contains("analyst"):
		return ["network_source_followup", "network_relationship_probe", "thesis_review"]
	return ["network_source_followup", "network_relationship_probe", "source_check"]


static func contact_twooter_risk_profile(contact: Dictionary) -> String:
	var reliability: float = float(contact.get("reliability", 0.5))
	var tone: String = str(contact.get("tone", "mixed"))
	if tone == "suspicious" or tone == "dirty":
		return "suspicious"
	if reliability < 0.48:
		return "noisy"
	return "clean"


static func contact_twooter_follow_weight(contact: Dictionary) -> int:
	var reliability_bonus: int = int(round(clamp(float(contact.get("reliability", 0.5)), 0.0, 1.0) * 12.0))
	var recognition_penalty: int = int(round(float(contact.get("recognition_required", 0)) / 12.0))
	var affiliation_type: String = str(contact.get("affiliation_type", "floater"))
	var affiliation_bonus: int = 4 if affiliation_type == "insider" else 0
	return clampi(12 + reliability_bonus + affiliation_bonus - recognition_penalty, 4, 32)


static func contact_twooter_verified(contact: Dictionary) -> bool:
	var role: String = str(contact.get("role", "")).to_lower()
	return role.contains("reporter") or role.contains("writer") or role.contains("columnist") or role.contains("analyst")


static func contact_twooter_voice(contact: Dictionary) -> String:
	var role: String = str(contact.get("role", "")).to_lower()
	var categories: Array = contact_string_array(contact.get("categories", []))
	if role.contains("macro") or categories.has("macro_shock") or categories.has("policy_post"):
		return "macro_classroom"
	if role.contains("reporter") or role.contains("writer") or role.contains("columnist"):
		return "market_diary"
	if role.contains("analyst") or categories.has("earnings"):
		return "funda_thread"
	if categories.has("rumor"):
		return "bandar_alert"
	return "market_diary"


static func contact_string_array(source: Variant) -> Array:
	var rows: Array = []
	if typeof(source) != TYPE_ARRAY:
		return rows
	for value in source:
		var text: String = str(value).strip_edges()
		if not text.is_empty() and not rows.has(text):
			rows.append(text)
	return rows


static func slug_text(value: String, keep_separator: bool) -> String:
	var source: String = value.to_lower().strip_edges()
	var parts: Array = []
	var last_was_separator: bool = false
	for index in range(source.length()):
		var code: int = source.unicode_at(index)
		var is_alnum: bool = (code >= 48 and code <= 57) or (code >= 97 and code <= 122)
		if is_alnum:
			parts.append(source.substr(index, 1))
			last_was_separator = false
		elif keep_separator and (code == 32 or code == 45 or code == 95 or code == 46) and not last_was_separator and not parts.is_empty():
			parts.append("_")
			last_was_separator = true
	var slug: String = "".join(parts).strip_edges()
	while slug.ends_with("_"):
		slug = slug.left(slug.length() - 1)
	if slug.is_empty():
		return "contact"
	return slug


static func contact_company_targets(discovery: Dictionary) -> Array:
	var targets: Array = []
	for company_id_value in discovery.get("target_company_ids", []):
		var company_id: String = str(company_id_value)
		if not company_id.is_empty() and not targets.has(company_id):
			targets.append(company_id)
	var primary_company_id: String = str(discovery.get("target_company_id", ""))
	if not primary_company_id.is_empty() and not targets.has(primary_company_id):
		targets.append(primary_company_id)
	return targets


static func can_add_company_lead(discovery: Dictionary, company_id: String, max_company_leads_per_floater: int) -> bool:
	if company_id.is_empty():
		return true
	var targets: Array = contact_company_targets(discovery)
	return (not targets.has(company_id)) and targets.size() < max_company_leads_per_floater


static func company_ticker(run_state, company_id: String) -> String:
	if company_id.is_empty():
		return ""
	var company: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	return str(company.get("ticker", company_id)).to_upper()
