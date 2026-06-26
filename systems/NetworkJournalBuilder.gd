extends RefCounted

const TRADING_CALENDAR_SCRIPT := preload("res://systems/TradingCalendar.gd")

const MAX_NETWORK_JOURNAL_ROWS := 18
const TRUTH_LABEL_NETWORK_READ := "Network Read"
const OUTCOME_LABEL_STILL_PENDING := "Still pending"
const TIP_STATUS_PENDING := "pending"
const TIP_STATUS_RESOLVED := "resolved"
const JOURNAL_STATUS_RECORDED := "recorded"
const DISCOVERY_STATUS_DISCOVERED := "discovered"
const REQUEST_STATUS_COMPLETED := "completed"
const REQUEST_STATUS_MISSED := "missed"
const DIRTY_TIP_STATUS_OFFERED := "offered"
const DIRTY_TIP_STATUS_CAUGHT := "caught"
const DIRTY_TIP_STATUS_RESOLVED_CLEAN := "resolved_clean"
const MEETING_LEAD_STATUS_MET := "met"
const REQUEST_TYPE_DIRTY_TIP := "dirty_tip"
const TIP_JOURNAL_TYPE_TWOOTER_SOCIAL := "twooter_social"
const MEETING_LEAD_SOURCE_TYPE := "meeting_lead"
const JOURNAL_ROW_TYPE_TWOOTER := "twooter"
const JOURNAL_ROW_TYPE_TIP := "tip"
const JOURNAL_ROW_TYPE_TIP_RESULT := "tip_result"
const JOURNAL_ROW_TYPE_FOLLOWUP := "followup"
const JOURNAL_ROW_TYPE_SOURCE_CHECK := "source_check"
const JOURNAL_ROW_TYPE_SOCIAL_REACTION := "social_reaction"
const JOURNAL_ROW_TYPE_PROPERTY_DEVELOPMENT_LEAD := "property_development_lead"
const JOURNAL_ROW_TYPE_REQUEST := "request"
const JOURNAL_ROW_TYPE_DIRTY_TIP := "dirty_tip"
const JOURNAL_ROW_TYPE_REFERRAL := "referral"
const JOURNAL_ROW_TYPE_MEETING_LEAD := "meeting_lead"
const JOURNAL_ROW_TYPE_TWOOTER_DISCOVERY := "twooter_discovery"
const JOURNAL_SORT_KEY_DIRTY_TIP_OFFERED := "dirty_tip:offered"
const JOURNAL_SORT_KEY_DIRTY_TIP_DECISION := "dirty_tip:decision"
const JOURNAL_SORT_KEY_DIRTY_TIP_RESULT := "dirty_tip:result"
const JOURNAL_SORT_DAY_MULTIPLIER := 10
const JOURNAL_SORT_OFFSET := {
	JOURNAL_ROW_TYPE_TIP: 1,
	JOURNAL_ROW_TYPE_TWOOTER_DISCOVERY: 2,
	JOURNAL_SORT_KEY_DIRTY_TIP_OFFERED: 2,
	JOURNAL_ROW_TYPE_TWOOTER: 3,
	JOURNAL_ROW_TYPE_REQUEST: 3,
	JOURNAL_ROW_TYPE_TIP_RESULT: 4,
	JOURNAL_ROW_TYPE_REFERRAL: 5,
	JOURNAL_ROW_TYPE_MEETING_LEAD: 5,
	JOURNAL_SORT_KEY_DIRTY_TIP_DECISION: 5,
	JOURNAL_ROW_TYPE_FOLLOWUP: 6,
	JOURNAL_ROW_TYPE_SOURCE_CHECK: 7,
	JOURNAL_ROW_TYPE_PROPERTY_DEVELOPMENT_LEAD: 8,
	JOURNAL_SORT_KEY_DIRTY_TIP_RESULT: 8,
	JOURNAL_ROW_TYPE_SOCIAL_REACTION: 9
}
const JOURNAL_ROW_CONFIG := {
	JOURNAL_ROW_TYPE_TWOOTER: {
		"type": JOURNAL_ROW_TYPE_TWOOTER,
		"id_suffix": "twooter",
		"day_keys": ["created_day_index"],
		"sort_key": JOURNAL_ROW_TYPE_TWOOTER,
		"contact_name_default": "Twooter contact",
		"status_default": JOURNAL_STATUS_RECORDED,
		"title_method": "_journal_title_twooter",
		"detail_method": "_journal_detail_twooter"
	},
	JOURNAL_ROW_TYPE_TIP: {
		"type": JOURNAL_ROW_TYPE_TIP,
		"id_suffix": "tip",
		"day_keys": ["created_day_index"],
		"sort_key": JOURNAL_ROW_TYPE_TIP,
		"contact_name_default": "Contact",
		"status_default": TIP_STATUS_PENDING,
		"title_method": "_journal_title_tip",
		"detail_method": "_journal_detail_tip"
	},
	JOURNAL_ROW_TYPE_TIP_RESULT: {
		"type": JOURNAL_ROW_TYPE_TIP_RESULT,
		"id_suffix": "resolved",
		"day_keys": ["resolved_day_index", "created_day_index"],
		"sort_key": JOURNAL_ROW_TYPE_TIP_RESULT,
		"contact_name_default": "Contact",
		"status_default": TIP_STATUS_RESOLVED,
		"title_method": "_journal_title_tip_result",
		"detail_method": "_journal_detail_tip_result"
	},
	JOURNAL_ROW_TYPE_FOLLOWUP: {
		"type": JOURNAL_ROW_TYPE_FOLLOWUP,
		"id_suffix": "followup",
		"day_keys": ["followup_day_index", "resolved_day_index", "created_day_index"],
		"sort_key": JOURNAL_ROW_TYPE_FOLLOWUP,
		"contact_name_default": "Contact",
		"status_method": "_journal_status_recorded",
		"title_method": "_journal_title_followup",
		"detail_method": "_journal_detail_followup"
	},
	JOURNAL_ROW_TYPE_SOURCE_CHECK: {
		"type": JOURNAL_ROW_TYPE_SOURCE_CHECK,
		"id_suffix": "source_check",
		"day_keys": ["source_check_day_index", "created_day_index"],
		"sort_key": JOURNAL_ROW_TYPE_SOURCE_CHECK,
		"contact_name_default": "Contact",
		"status_method": "_journal_status_recorded",
		"title_method": "_journal_title_source_check",
		"detail_method": "_journal_detail_source_check"
	},
	JOURNAL_ROW_TYPE_SOCIAL_REACTION: {
		"type": JOURNAL_ROW_TYPE_SOCIAL_REACTION,
		"id_suffix": "social_reaction",
		"day_keys": ["reaction_day_index", "resolved_day_index", "created_day_index"],
		"sort_key": JOURNAL_ROW_TYPE_SOCIAL_REACTION,
		"contact_name_default": "Contact",
		"status_method": "_journal_status_recorded",
		"title_method": "_journal_title_social_reaction",
		"detail_method": "_journal_detail_social_reaction"
	},
	JOURNAL_ROW_TYPE_PROPERTY_DEVELOPMENT_LEAD: {
		"type": JOURNAL_ROW_TYPE_PROPERTY_DEVELOPMENT_LEAD,
		"id_suffix": "property_development",
		"day_keys": ["discovered_day_index"],
		"sort_key": JOURNAL_ROW_TYPE_PROPERTY_DEVELOPMENT_LEAD,
		"status_method": "_journal_status_property_development",
		"title_method": "_journal_title_property_development",
		"detail_method": "_journal_detail_property_development"
	},
	JOURNAL_ROW_TYPE_REQUEST: {
		"type": JOURNAL_ROW_TYPE_REQUEST,
		"id_suffix": "request",
		"day_keys": ["_journal_day_index"],
		"sort_key": JOURNAL_ROW_TYPE_REQUEST,
		"contact_name_key": "_journal_contact_name",
		"target_ticker_key": "_journal_target_ticker",
		"status_default": TIP_STATUS_PENDING,
		"title_method": "_journal_title_request",
		"detail_method": "_journal_detail_request"
	},
	JOURNAL_SORT_KEY_DIRTY_TIP_OFFERED: {
		"type": JOURNAL_ROW_TYPE_DIRTY_TIP,
		"id_suffix": "offered",
		"day_keys": ["created_day_index"],
		"sort_key": JOURNAL_SORT_KEY_DIRTY_TIP_OFFERED,
		"contact_name_default": "Operator Room",
		"status_default": DIRTY_TIP_STATUS_OFFERED,
		"title_method": "_journal_title_dirty_tip_offered",
		"detail_method": "_journal_detail_dirty_tip_offered"
	},
	JOURNAL_SORT_KEY_DIRTY_TIP_DECISION: {
		"type": JOURNAL_ROW_TYPE_DIRTY_TIP,
		"id_suffix": "decision",
		"day_keys": ["decision_day_index", "created_day_index"],
		"sort_key": JOURNAL_SORT_KEY_DIRTY_TIP_DECISION,
		"contact_name_default": "Operator Room",
		"status_method": "_journal_status_dirty_tip_decision",
		"title_method": "_journal_title_dirty_tip_decision",
		"detail_method": "_journal_detail_dirty_tip_decision"
	},
	JOURNAL_SORT_KEY_DIRTY_TIP_RESULT: {
		"type": JOURNAL_ROW_TYPE_DIRTY_TIP,
		"id_suffix": "result",
		"day_keys": ["resolved_day_index", "completed_day_index", "created_day_index"],
		"sort_key": JOURNAL_SORT_KEY_DIRTY_TIP_RESULT,
		"contact_name_default": "Operator Room",
		"status_default": DIRTY_TIP_STATUS_RESOLVED_CLEAN,
		"title_method": "_journal_title_dirty_tip_result",
		"detail_method": "_journal_detail_dirty_tip_result"
	},
	JOURNAL_ROW_TYPE_REFERRAL: {
		"type": JOURNAL_ROW_TYPE_REFERRAL,
		"id_source_key": "contact_id",
		"id_suffix": "referral",
		"day_keys": ["day_index"],
		"sort_key": JOURNAL_ROW_TYPE_REFERRAL,
		"contact_name_key": "_journal_contact_name",
		"target_ticker_key": "_journal_target_ticker",
		"status_default": DISCOVERY_STATUS_DISCOVERED,
		"title_method": "_journal_title_referral",
		"detail_method": "_journal_detail_referral"
	},
	JOURNAL_ROW_TYPE_MEETING_LEAD: {
		"type": JOURNAL_ROW_TYPE_MEETING_LEAD,
		"id_method": "_journal_id_meeting_lead",
		"day_keys": ["day_index"],
		"sort_key": JOURNAL_ROW_TYPE_MEETING_LEAD,
		"contact_name_key": "_journal_contact_name",
		"target_ticker_key": "_journal_target_ticker",
		"status_default": MEETING_LEAD_STATUS_MET,
		"title_method": "_journal_title_meeting_lead",
		"detail_method": "_journal_detail_meeting_lead"
	},
	JOURNAL_ROW_TYPE_TWOOTER_DISCOVERY: {
		"type": JOURNAL_ROW_TYPE_TWOOTER_DISCOVERY,
		"id_source_key": "contact_id",
		"id_suffix": "twooter_discovery",
		"day_keys": ["day_index"],
		"sort_key": JOURNAL_ROW_TYPE_TWOOTER_DISCOVERY,
		"contact_name_key": "_journal_contact_name",
		"status_default": DISCOVERY_STATUS_DISCOVERED,
		"title_method": "_journal_title_twooter_discovery",
		"detail_method": "_journal_detail_twooter_discovery"
	}
}


static func network_journal_rows(run_state, data_repository, requests: Dictionary, discoveries: Dictionary, contact_display_name_callback: Callable, company_ticker_callback: Callable) -> Array:
	var rows: Array = []
	for tip_value in run_state.get_network_tip_journal().values():
		if typeof(tip_value) != TYPE_DICTIONARY:
			continue
		var tip: Dictionary = tip_value
		if str(tip.get("journal_type", "")) == TIP_JOURNAL_TYPE_TWOOTER_SOCIAL:
			rows.append(network_twooter_journal_row(tip))
			if bool(tip.get("reaction_sent", false)):
				rows.append(network_social_reaction_journal_row(tip))
			continue
		rows.append(network_tip_journal_row(tip))
		if str(tip.get("status", TIP_STATUS_PENDING)) != TIP_STATUS_PENDING:
			rows.append(network_tip_resolution_journal_row(tip))
		if not str(tip.get("followup_note", "")).is_empty():
			rows.append(network_tip_followup_journal_row(tip))
		if not str(tip.get("source_check_note", "")).is_empty():
			rows.append(network_source_check_journal_row(tip))
		if bool(tip.get("reaction_sent", false)):
			rows.append(network_social_reaction_journal_row(tip))
	for request_value in requests.values():
		if typeof(request_value) != TYPE_DICTIONARY:
			continue
		var request: Dictionary = request_value
		if str(request.get("request_type", "")) == REQUEST_TYPE_DIRTY_TIP:
			rows.append(network_dirty_tip_journal_row(request))
			if not str(request.get("decision", "")).is_empty():
				rows.append(network_dirty_tip_decision_journal_row(request))
			if int(request.get("resolved_day_index", -1)) >= 0:
				rows.append(network_dirty_tip_result_journal_row(request))
			continue
		rows.append(network_request_journal_row(run_state, data_repository, request, contact_display_name_callback, company_ticker_callback))
	for discovery_value in discoveries.values():
		if typeof(discovery_value) != TYPE_DICTIONARY:
			continue
		var discovery: Dictionary = discovery_value
		if str(discovery.get("source_type", "")) == "referral":
			rows.append(network_referral_journal_row(run_state, data_repository, discovery, contact_display_name_callback, company_ticker_callback))
		if str(discovery.get("source_type", "")) == MEETING_LEAD_SOURCE_TYPE:
			rows.append(network_meeting_lead_journal_row(run_state, data_repository, discovery, contact_display_name_callback, company_ticker_callback))
		if str(discovery.get("source_type", "")) == "twooter":
			rows.append(network_twooter_discovery_journal_row(run_state, data_repository, discovery, contact_display_name_callback))
	var life_state: Dictionary = run_state.get_player_life()
	for lead_value in life_state.get("development_leads", []):
		if typeof(lead_value) == TYPE_DICTIONARY:
			rows.append(network_property_development_lead_journal_row(lead_value))
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_sort: int = int(a.get("sort_index", journal_sort_index(int(a.get("day_index", 0)), "")))
		var b_sort: int = int(b.get("sort_index", journal_sort_index(int(b.get("day_index", 0)), "")))
		if a_sort == b_sort:
			return str(a.get("id", "")) > str(b.get("id", ""))
		return a_sort > b_sort
	)
	if rows.size() > MAX_NETWORK_JOURNAL_ROWS:
		rows = rows.slice(0, MAX_NETWORK_JOURNAL_ROWS)
	return rows


static func journal_sort_index(day_index: int, sort_key: String) -> int:
	return day_index * JOURNAL_SORT_DAY_MULTIPLIER + int(JOURNAL_SORT_OFFSET.get(sort_key, 0))


static func journal_row(config_key: String, source: Dictionary) -> Dictionary:
	var config: Dictionary = JOURNAL_ROW_CONFIG.get(config_key, {})
	var row_type: String = str(config.get("type", config_key))
	var day_index: int = journal_day_index(source, config)
	var row: Dictionary = {
		"id": journal_id(source, config),
		"type": row_type,
		"day_index": day_index,
		"sort_index": journal_sort_index(day_index, str(config.get("sort_key", row_type))),
		"contact_id": str(source.get(str(config.get("contact_id_key", "contact_id")), "")),
		"contact_name": str(source.get(str(config.get("contact_name_key", "contact_name")), config.get("contact_name_default", ""))),
		"target_company_id": str(source.get(str(config.get("target_company_id_key", "target_company_id")), "")),
		"target_ticker": str(source.get(str(config.get("target_ticker_key", "target_ticker")), "")),
		"status": journal_status(source, config),
		"title": journal_call_text(str(config.get("title_method", "")), source),
		"detail": journal_call_text(str(config.get("detail_method", "")), source),
		"source_label": str(source.get("source_label", "")),
		"access_label": journal_access_label(source),
		"referred_by_contact_id": str(source.get("referred_by_contact_id", source.get("source_id", ""))),
		"referred_by_contact_name": journal_referred_by_contact_name(source),
		"referral_day_index": journal_referral_day_index(source),
		"dialog_outcome": str(source.get("dialog_outcome", "")),
		"dialog_outcome_label": str(source.get("dialog_outcome_label", "")),
		"direct_tip_direction": journal_direct_tip_field(source, "direction"),
		"direct_tip_entry_timing": journal_direct_tip_field(source, "entry_timing"),
		"direct_tip_hold_period": journal_direct_tip_field(source, "hold_period"),
		"direct_tip_risk_note": journal_direct_tip_field(source, "risk_note"),
		"direct_tip_confidence_label": journal_direct_tip_field(source, "confidence_label")
	}
	_copy_generated_surface_metadata(row, source)
	return row


static func _copy_generated_surface_metadata(target: Dictionary, source: Dictionary) -> void:
	for key_value in [
		"generated_content_surface",
		"generated_surface_id",
		"generated_scope_id",
		"source_system_id",
		"story_id",
		"story_family",
		"archetype_id",
		"public_status",
		"stage_id",
		"visibility",
		"detail_level",
		"reliability",
		"leak_risk",
		"source_fact_ids",
		"source_clue_ids",
		"source_company_ids",
		"source_sector_ids",
		"source_event_ids",
		"source_quality",
		"directness",
		"original_directness",
		"required_relationship_stage",
		"required_recognition_min",
		"network_relationship",
		"recognition_score"
	]:
		var key: String = str(key_value)
		if source.has(key):
			target[key] = source.get(key)
	if str(target.get("surface_id", "")).strip_edges().is_empty() and not str(target.get("generated_surface_id", "")).strip_edges().is_empty():
		target["surface_id"] = str(target.get("generated_surface_id", "")).strip_edges()


static func journal_day_index(source: Dictionary, config: Dictionary) -> int:
	var day_keys: Array = config.get("day_keys", []) if typeof(config.get("day_keys", [])) == TYPE_ARRAY else []
	for day_key_value in day_keys:
		var day_key: String = str(day_key_value)
		if source.has(day_key):
			return int(source.get(day_key, 0))
	return 0


static func journal_id(source: Dictionary, config: Dictionary) -> String:
	var id_method: String = str(config.get("id_method", ""))
	if not id_method.is_empty():
		match id_method:
			"_journal_id_meeting_lead":
				return journal_id_meeting_lead(source)
	var id_source_key: String = str(config.get("id_source_key", "id"))
	var source_id: String = str(source.get(id_source_key, ""))
	var id_suffix: String = str(config.get("id_suffix", ""))
	if id_suffix.is_empty():
		return source_id
	return "%s:%s" % [source_id, id_suffix]


static func journal_status(source: Dictionary, config: Dictionary) -> String:
	var status_method: String = str(config.get("status_method", ""))
	if not status_method.is_empty():
		match status_method:
			"_journal_status_recorded":
				return journal_status_recorded(source)
			"_journal_status_property_development":
				return journal_status_property_development(source)
			"_journal_status_dirty_tip_decision":
				return journal_status_dirty_tip_decision(source)
	return str(source.get(str(config.get("status_key", "status")), config.get("status_default", "")))


static func journal_access_label(source: Dictionary) -> String:
	var explicit_label: String = str(source.get("_journal_access_label", source.get("access_label", ""))).strip_edges()
	if not explicit_label.is_empty():
		return explicit_label
	if str(source.get("source_type", "")).strip_edges().to_lower() != "referral":
		return ""
	var privacy_gate: String = str(source.get("privacy_gate", "")).strip_edges()
	if privacy_gate == "inner_circle" or bool(source.get("referral_required", false)):
		return "Inner-circle contact"
	return "Private referral"


static func journal_referred_by_contact_name(source: Dictionary) -> String:
	return str(source.get("_journal_source_name", source.get("referred_by_contact_name", ""))).strip_edges()


static func journal_referral_day_index(source: Dictionary) -> int:
	if source.has("referral_day_index"):
		return int(source.get("referral_day_index", -9999))
	if str(source.get("source_type", "")).strip_edges().to_lower() == "referral":
		return int(source.get("day_index", -9999))
	return -9999


static func journal_direct_tip_field(source: Dictionary, field_name: String) -> String:
	var source_key: String = "direct_tip_%s" % field_name
	var explicit_value: String = str(source.get(source_key, "")).strip_edges()
	if not explicit_value.is_empty():
		return explicit_value
	var payload_value: Variant = source.get("direct_tip_payload", {})
	if typeof(payload_value) != TYPE_DICTIONARY:
		return ""
	var payload: Dictionary = payload_value
	return str(payload.get(field_name, "")).strip_edges()


static func journal_direct_tip_payload(source: Dictionary) -> Dictionary:
	var payload_value: Variant = source.get("direct_tip_payload", {})
	if typeof(payload_value) == TYPE_DICTIONARY:
		return payload_value
	return {}


static func journal_is_direct_tip(source: Dictionary) -> bool:
	return bool(source.get("dialog_outcome_direct_tip_recorded", false)) or str(source.get("dialog_outcome", "")) == "direct_tip"


static func journal_status_recorded(_source: Dictionary) -> String:
	return JOURNAL_STATUS_RECORDED


static func journal_call_text(method_name: String, source: Dictionary) -> String:
	match method_name:
		"_journal_title_twooter":
			return journal_title_twooter(source)
		"_journal_detail_twooter":
			return journal_detail_twooter(source)
		"_journal_title_tip":
			return journal_title_tip(source)
		"_journal_detail_tip":
			return journal_detail_tip(source)
		"_journal_title_tip_result":
			return journal_title_tip_result(source)
		"_journal_detail_tip_result":
			return journal_detail_tip_result(source)
		"_journal_title_followup":
			return journal_title_followup(source)
		"_journal_detail_followup":
			return journal_detail_followup(source)
		"_journal_title_source_check":
			return journal_title_source_check(source)
		"_journal_detail_source_check":
			return journal_detail_source_check(source)
		"_journal_title_social_reaction":
			return journal_title_social_reaction(source)
		"_journal_detail_social_reaction":
			return journal_detail_social_reaction(source)
		"_journal_title_property_development":
			return journal_title_property_development(source)
		"_journal_detail_property_development":
			return journal_detail_property_development(source)
		"_journal_title_request":
			return journal_title_request(source)
		"_journal_detail_request":
			return journal_detail_request(source)
		"_journal_title_dirty_tip_offered":
			return journal_title_dirty_tip_offered(source)
		"_journal_detail_dirty_tip_offered":
			return journal_detail_dirty_tip_offered(source)
		"_journal_title_dirty_tip_decision":
			return journal_title_dirty_tip_decision(source)
		"_journal_detail_dirty_tip_decision":
			return journal_detail_dirty_tip_decision(source)
		"_journal_title_dirty_tip_result":
			return journal_title_dirty_tip_result(source)
		"_journal_detail_dirty_tip_result":
			return journal_detail_dirty_tip_result(source)
		"_journal_title_referral":
			return journal_title_referral(source)
		"_journal_detail_referral":
			return journal_detail_referral(source)
		"_journal_title_meeting_lead":
			return journal_title_meeting_lead(source)
		"_journal_detail_meeting_lead":
			return journal_detail_meeting_lead(source)
		"_journal_title_twooter_discovery":
			return journal_title_twooter_discovery(source)
		"_journal_detail_twooter_discovery":
			return journal_detail_twooter_discovery(source)
	return ""


static func network_twooter_journal_row(tip: Dictionary) -> Dictionary:
	return journal_row(JOURNAL_ROW_TYPE_TWOOTER, tip)


static func journal_title_twooter(tip: Dictionary) -> String:
	var ticker: String = str(tip.get("target_ticker", ""))
	if journal_is_direct_tip(tip):
		return "Twooter | Inner-circle Direct Read%s" % (" | %s" % ticker if not ticker.is_empty() else "")
	var action_label: String = str(tip.get("truth_label", "Twooter"))
	var outcome_label: String = str(tip.get("dialog_outcome_label", "")).strip_edges()
	if not outcome_label.is_empty():
		action_label = outcome_label
	return "Twooter | %s%s" % [action_label, " | %s" % ticker if not ticker.is_empty() else ""]


static func journal_detail_twooter(tip: Dictionary) -> String:
	if journal_is_direct_tip(tip):
		return journal_detail_direct_tip(tip)
	var source_label: String = str(tip.get("source_label", "Twooter")).strip_edges()
	var source_note: String = str(tip.get("source_note", "")).strip_edges()
	var detail: String = str(tip.get("tip_read", ""))
	var outcome_note: String = str(tip.get("dialog_outcome_note", "")).strip_edges()
	var confidence_label: String = str(tip.get("confidence_label", "")).strip_edges()
	if not source_note.is_empty():
		detail = "%s %s" % [source_note, detail]
	elif not source_label.is_empty():
		detail = "%s. %s" % [source_label, detail]
	if not outcome_note.is_empty():
		detail = "%s %s" % [detail.strip_edges(), outcome_note]
	if not confidence_label.is_empty() and confidence_label != "social":
		detail = "%s (%s)" % [detail.strip_edges(), confidence_label]
	return detail.strip_edges()


static func journal_detail_direct_tip(tip: Dictionary) -> String:
	var payload: Dictionary = journal_direct_tip_payload(tip)
	var ticker: String = str(payload.get("ticker", tip.get("target_ticker", ""))).strip_edges().to_upper()
	var direction_label: String = str(payload.get("direction_label", journal_direct_tip_field(tip, "direction"))).strip_edges()
	if direction_label.is_empty():
		direction_label = "Read"
	var entry_timing: String = journal_direct_tip_field(tip, "entry_timing")
	var hold_period: String = journal_direct_tip_field(tip, "hold_period")
	var confidence_label: String = journal_direct_tip_field(tip, "confidence_label")
	var risk_note: String = journal_direct_tip_field(tip, "risk_note")
	var boundary_note: String = str(payload.get("public_boundary_note", "")).strip_edges()
	var read_parts: Array = []
	var direction_line: String = direction_label
	if not ticker.is_empty():
		direction_line = "%s %s" % [direction_label, ticker]
	read_parts.append(direction_line)
	if not entry_timing.is_empty():
		read_parts.append(entry_timing)
	if not hold_period.is_empty():
		read_parts.append("hold %s" % hold_period)
	var lines: Array = ["Inner-circle direct read: %s." % ", ".join(read_parts)]
	if not confidence_label.is_empty():
		lines.append("Confidence: %s." % confidence_label)
	if not risk_note.is_empty():
		lines.append("Risk: %s." % risk_note)
	if not boundary_note.is_empty():
		lines.append("Boundary: %s." % boundary_note)
	return " ".join(lines).strip_edges()


static func network_tip_journal_row(tip: Dictionary) -> Dictionary:
	return journal_row(JOURNAL_ROW_TYPE_TIP, tip)


static func journal_title_tip(tip: Dictionary) -> String:
	var ticker: String = str(tip.get("target_ticker", ""))
	var read_label: String = str(tip.get("truth_label", TRUTH_LABEL_NETWORK_READ))
	return "Tip | %s | %s" % [ticker, read_label]


static func journal_detail_tip(tip: Dictionary) -> String:
	return "%s gave a %s read. %s" % [
		str(tip.get("contact_name", "Contact")),
		str(tip.get("confidence_label", "soft")),
		str(tip.get("tip_read", ""))
	]


static func network_tip_resolution_journal_row(tip: Dictionary) -> Dictionary:
	return journal_row(JOURNAL_ROW_TYPE_TIP_RESULT, tip)


static func journal_title_tip_result(tip: Dictionary) -> String:
	return "Tip Result | %s | %s" % [
		str(tip.get("target_ticker", "")),
		str(tip.get("outcome_label", OUTCOME_LABEL_STILL_PENDING))
	]


static func journal_detail_tip_result(tip: Dictionary) -> String:
	return "%s | %s" % [
		str(tip.get("outcome_note", "")),
		str(tip.get("player_action_label", "No action"))
	]


static func network_tip_followup_journal_row(tip: Dictionary) -> Dictionary:
	return journal_row(JOURNAL_ROW_TYPE_FOLLOWUP, tip)


static func journal_title_followup(tip: Dictionary) -> String:
	return "Follow-up | %s | %s" % [
		str(tip.get("target_ticker", "")),
		str(tip.get("followup_label", "Follow-up"))
	]


static func journal_detail_followup(tip: Dictionary) -> String:
	return str(tip.get("followup_note", ""))


static func network_source_check_journal_row(tip: Dictionary) -> Dictionary:
	return journal_row(JOURNAL_ROW_TYPE_SOURCE_CHECK, tip)


static func journal_title_source_check(tip: Dictionary) -> String:
	return "Source Check | %s | %s" % [
		str(tip.get("target_ticker", "")),
		str(tip.get("source_check_peer_contact_name", "conflict"))
	]


static func journal_detail_source_check(tip: Dictionary) -> String:
	return str(tip.get("source_check_note", ""))


static func network_social_reaction_journal_row(tip: Dictionary) -> Dictionary:
	return journal_row(JOURNAL_ROW_TYPE_SOCIAL_REACTION, tip)


static func journal_title_social_reaction(tip: Dictionary) -> String:
	var ticker: String = str(tip.get("target_ticker", ""))
	var title_suffix: String = " | %s" % ticker if not ticker.is_empty() else ""
	return "Follow-up DM%s | %s" % [title_suffix, str(tip.get("reaction_label", "Reaction"))]


static func journal_detail_social_reaction(tip: Dictionary) -> String:
	var handle: String = str(tip.get("reaction_twooter_handle", tip.get("twooter_handle", ""))).strip_edges()
	var detail: String = str(tip.get("reaction_note", ""))
	if not handle.is_empty():
		detail = "%s: %s" % [handle, detail]
	return detail.strip_edges()


static func network_property_development_lead_journal_row(lead: Dictionary) -> Dictionary:
	return journal_row(JOURNAL_ROW_TYPE_PROPERTY_DEVELOPMENT_LEAD, lead)


static func journal_property_development_status_text(lead: Dictionary) -> String:
	var stage: String = str(lead.get("stage", "rumor"))
	var status_text: String = stage.capitalize()
	if bool(lead.get("resolved", false)):
		status_text = str(lead.get("outcome", stage)).capitalize()
	return status_text


static func journal_status_property_development(lead: Dictionary) -> String:
	return journal_property_development_status_text(lead).to_lower()


static func journal_title_property_development(lead: Dictionary) -> String:
	var location_label: String = str(lead.get("display_location_label", lead.get("location_label", lead.get("location_id", "Location"))))
	var status_text: String = journal_property_development_status_text(lead)
	return "Property Intel | %s | %s" % [location_label, status_text]


static func journal_detail_property_development(lead: Dictionary) -> String:
	var location_label: String = str(lead.get("display_location_label", lead.get("location_label", lead.get("location_id", "Location"))))
	var theme_label: String = str(lead.get("display_theme_label", lead.get("theme_label", lead.get("theme", "Development")))).capitalize()
	var detail: String = str(lead.get("source_note", "")).strip_edges()
	if detail.is_empty():
		detail = "%s development intel is being tracked for %s." % [theme_label, location_label]
	var clarity_label: String = str(lead.get("clarity_label", "")).strip_edges()
	if not clarity_label.is_empty():
		detail = "%s %s" % [clarity_label + ".", detail]
	return detail


static func network_request_journal_row(run_state, data_repository, request: Dictionary, contact_display_name_callback: Callable, company_ticker_callback: Callable) -> Dictionary:
	var contact_id: String = str(request.get("contact_id", ""))
	var company_id: String = str(request.get("target_company_id", ""))
	var status: String = str(request.get("status", TIP_STATUS_PENDING))
	var day_index: int = int(request.get("completed_day_index", request.get("created_day_index", 0))) if status != TIP_STATUS_PENDING else int(request.get("created_day_index", 0))
	var contact_name: String = str(contact_display_name_callback.call(run_state, data_repository, contact_id))
	var ticker: String = str(company_ticker_callback.call(run_state, company_id))
	var due_date_text: String = request_due_date_text(request)
	var detail: String = "Due date unknown."
	if due_date_text != "the due date":
		detail = "Due %s." % due_date_text
	if status == REQUEST_STATUS_COMPLETED:
		detail = "Completed after you held at least 1 lot."
	elif status == REQUEST_STATUS_MISSED:
		detail = "Missed because you did not hold the requested target."
	var row_source: Dictionary = request.duplicate(false)
	row_source["_journal_day_index"] = day_index
	row_source["_journal_contact_name"] = contact_name
	row_source["_journal_target_ticker"] = ticker
	row_source["_journal_request_detail"] = detail
	return journal_row(JOURNAL_ROW_TYPE_REQUEST, row_source)


static func journal_title_request(request: Dictionary) -> String:
	return "Request | %s | %s" % [
		str(request.get("_journal_target_ticker", "")),
		str(request.get("status", TIP_STATUS_PENDING)).capitalize()
	]


static func journal_detail_request(request: Dictionary) -> String:
	return "%s | %s" % [
		str(request.get("_journal_contact_name", "")),
		str(request.get("_journal_request_detail", ""))
	]


static func network_dirty_tip_journal_row(request: Dictionary) -> Dictionary:
	return journal_row(JOURNAL_SORT_KEY_DIRTY_TIP_OFFERED, request)


static func journal_title_dirty_tip_offered(request: Dictionary) -> String:
	var ticker: String = str(request.get("target_ticker", ""))
	return "Dirty Tip | %s | Offered" % ticker


static func journal_detail_dirty_tip_offered(request: Dictionary) -> String:
	return str(request.get("journal_detail", request.get("offer_body", "")))


static func network_dirty_tip_decision_journal_row(request: Dictionary) -> Dictionary:
	return journal_row(JOURNAL_SORT_KEY_DIRTY_TIP_DECISION, request)


static func journal_status_dirty_tip_decision(request: Dictionary) -> String:
	return str(request.get("decision", request.get("status", "")))


static func journal_title_dirty_tip_decision(request: Dictionary) -> String:
	var ticker: String = str(request.get("target_ticker", ""))
	var status: String = journal_status_dirty_tip_decision(request)
	return "Dirty Tip | %s | %s" % [ticker, status.capitalize()]


static func journal_detail_dirty_tip_decision(request: Dictionary) -> String:
	var status: String = journal_status_dirty_tip_decision(request)
	var detail: String = str(request.get("journal_detail", request.get("outcome_note", "")))
	if detail.is_empty():
		match status:
			"accepted":
				detail = "You accepted the room approach."
			"reported":
				detail = "You reported the approach."
			_:
				detail = "You declined the approach."
	return detail


static func network_dirty_tip_result_journal_row(request: Dictionary) -> Dictionary:
	return journal_row(JOURNAL_SORT_KEY_DIRTY_TIP_RESULT, request)


static func journal_title_dirty_tip_result(request: Dictionary) -> String:
	var ticker: String = str(request.get("target_ticker", ""))
	var status: String = str(request.get("status", DIRTY_TIP_STATUS_RESOLVED_CLEAN))
	return "Dirty Tip | %s | %s" % [ticker, str(request.get("outcome_label", status.capitalize()))]


static func journal_detail_dirty_tip_result(request: Dictionary) -> String:
	var status: String = str(request.get("status", DIRTY_TIP_STATUS_RESOLVED_CLEAN))
	var detail: String = str(request.get("outcome_note", ""))
	if status == DIRTY_TIP_STATUS_CAUGHT:
		detail = "%s Fine: Rp%.0f. Legal hold: %d trading day(s)." % [
			detail,
			float(request.get("fine_amount", 0.0)),
			int(request.get("legal_days", 0))
		]
	return detail


static func request_due_date_text(request: Dictionary) -> String:
	var due_day_index: int = int(request.get("due_day_index", 0))
	if due_day_index <= 0:
		return "the due date"
	var trading_calendar = TRADING_CALENDAR_SCRIPT.new()
	var date_info: Dictionary = trading_calendar.trade_date_for_index(max(due_day_index, 1))
	var month_names := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var month_index: int = clamp(int(date_info.get("month", 1)) - 1, 0, month_names.size() - 1)
	return "%s %d, %d" % [
		month_names[month_index],
		int(date_info.get("day", 1)),
		int(date_info.get("year", 2020))
	]


static func network_referral_journal_row(run_state, data_repository, discovery: Dictionary, contact_display_name_callback: Callable, company_ticker_callback: Callable) -> Dictionary:
	var referred_contact_id: String = str(discovery.get("contact_id", ""))
	var source_contact_id: String = str(discovery.get("referred_by_contact_id", discovery.get("source_id", "")))
	var referred_name: String = str(contact_display_name_callback.call(run_state, data_repository, referred_contact_id))
	var source_name: String = str(contact_display_name_callback.call(run_state, data_repository, source_contact_id))
	var company_id: String = str(discovery.get("target_company_id", ""))
	var row_source: Dictionary = discovery.duplicate(false)
	row_source["_journal_contact_name"] = referred_name
	row_source["_journal_source_name"] = source_name
	row_source["_journal_target_ticker"] = str(company_ticker_callback.call(run_state, company_id))
	row_source["_journal_access_label"] = journal_access_label(discovery)
	return journal_row(JOURNAL_ROW_TYPE_REFERRAL, row_source)


static func journal_title_referral(discovery: Dictionary) -> String:
	var access_label: String = journal_access_label(discovery)
	if access_label.is_empty():
		access_label = "Private referral"
	return "Referral | %s | %s" % [
		access_label,
		str(discovery.get("_journal_contact_name", ""))
	]


static func journal_detail_referral(discovery: Dictionary) -> String:
	var source_name: String = str(discovery.get("_journal_source_name", "Contact"))
	var day_index: int = journal_referral_day_index(discovery)
	var access_label: String = journal_access_label(discovery)
	if access_label.is_empty():
		access_label = "Private referral"
	var detail: String = "%s introduced this lead." % source_name
	if day_index >= 0:
		detail = "%s Day %d." % [detail, day_index]
	detail = "%s Access: %s." % [detail, access_label]
	var ticker: String = str(discovery.get("_journal_target_ticker", "")).strip_edges()
	if not ticker.is_empty():
		detail = "%s Context: %s." % [detail, ticker]
	return detail


static func network_meeting_lead_journal_row(run_state, data_repository, discovery: Dictionary, contact_display_name_callback: Callable, company_ticker_callback: Callable) -> Dictionary:
	var contact_id: String = str(discovery.get("contact_id", ""))
	var company_id: String = str(discovery.get("target_company_id", ""))
	var contact_name: String = str(contact_display_name_callback.call(run_state, data_repository, contact_id))
	var ticker: String = str(company_ticker_callback.call(run_state, company_id))
	var row_source: Dictionary = discovery.duplicate(false)
	row_source["_journal_contact_name"] = contact_name
	row_source["_journal_target_ticker"] = ticker
	return journal_row(JOURNAL_ROW_TYPE_MEETING_LEAD, row_source)


static func journal_id_meeting_lead(discovery: Dictionary) -> String:
	return "%s:meeting_lead:%s" % [
		str(discovery.get("contact_id", "")),
		str(discovery.get("meeting_id", ""))
	]


static func journal_title_meeting_lead(discovery: Dictionary) -> String:
	return "RUPSLB Lead | %s" % str(discovery.get("_journal_contact_name", ""))


static func journal_detail_meeting_lead(discovery: Dictionary) -> String:
	return "Met during the %s meeting room." % str(discovery.get("_journal_target_ticker", ""))


static func network_twooter_discovery_journal_row(run_state, data_repository, discovery: Dictionary, contact_display_name_callback: Callable) -> Dictionary:
	var contact_id: String = str(discovery.get("contact_id", ""))
	var row_source: Dictionary = discovery.duplicate(false)
	row_source["_journal_contact_name"] = str(contact_display_name_callback.call(run_state, data_repository, contact_id))
	return journal_row(JOURNAL_ROW_TYPE_TWOOTER_DISCOVERY, row_source)


static func journal_title_twooter_discovery(discovery: Dictionary) -> String:
	var ticker: String = str(discovery.get("target_ticker", ""))
	var source_label: String = str(discovery.get("source_label", "Twooter Contact")).strip_edges()
	return "%s%s" % [source_label, " | %s" % ticker if not ticker.is_empty() else ""]


static func journal_detail_twooter_discovery(discovery: Dictionary) -> String:
	var source_note: String = str(discovery.get("source_note", "")).strip_edges()
	if source_note.is_empty():
		source_note = "A Twooter exchange became a tracked Network contact."
	return source_note
