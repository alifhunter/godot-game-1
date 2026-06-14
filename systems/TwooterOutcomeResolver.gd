extends RefCounted

const DIALOG_OUTCOME_SOURCE_CREDIBILITY_DELTA := 1
const DIALOG_OUTCOME_CLEAN_READ_RELATIONSHIP_PROGRESS := 0.5
const DIALOG_OUTCOME_BOUNDARY_EXPOSURE_DELTA := -1
const DIALOG_OUTCOME_NETWORK_SOURCE_QUALITY_DELTA := 1
const DIALOG_OUTCOME_THESIS_CREDIBILITY_DELTA := 1
const DIALOG_OUTCOME_EVENT_RELATIONSHIP_DELTA := 1
const DIALOG_OUTCOME_LABELS := {
	"source_check": "Source checked",
	"clean_read": "Clean read",
	"direct_tip": "Direct tip",
	"contact_discovery": "Contact discovered",
	"thesis_response": "Thesis response",
	"event_invite": "Event invite",
	"suspicious_boundary": "Clean boundary"
}


static func outcome_effect(outcome: String, account: Dictionary, gain_multiplier: float, thesis: Dictionary = {}) -> Dictionary:
	if outcome.is_empty() or gain_multiplier <= 0.0:
		return {}
	match outcome:
		"source_check":
			var source_quality_delta: int = 0
			if is_network_source_account(account):
				source_quality_delta = int(round(float(DIALOG_OUTCOME_NETWORK_SOURCE_QUALITY_DELTA) * gain_multiplier))
			return {
				"credibility_delta": int(round(float(DIALOG_OUTCOME_SOURCE_CREDIBILITY_DELTA) * gain_multiplier)),
				"network_source_quality_delta": source_quality_delta
			}
		"clean_read":
			return {
				"relationship_progress_delta": float(DIALOG_OUTCOME_CLEAN_READ_RELATIONSHIP_PROGRESS) * gain_multiplier
			}
		"direct_tip":
			return {
				"relationship_progress_delta": float(DIALOG_OUTCOME_CLEAN_READ_RELATIONSHIP_PROGRESS) * gain_multiplier
			}
		"suspicious_boundary":
			return {
				"exposure_delta": int(round(float(DIALOG_OUTCOME_BOUNDARY_EXPOSURE_DELTA) * gain_multiplier))
			}
		"contact_discovery":
			var contact_delta: int = int(round(float(DIALOG_OUTCOME_NETWORK_SOURCE_QUALITY_DELTA) * gain_multiplier))
			if is_network_source_account(account):
				return {
					"network_source_quality_delta": contact_delta,
					"contact_discovery_delta": contact_delta
				}
			return {"contact_discovery_delta": contact_delta}
		"thesis_response":
			if thesis.is_empty():
				return {}
			return {
				"credibility_delta": int(round(float(DIALOG_OUTCOME_THESIS_CREDIBILITY_DELTA) * gain_multiplier)),
				"thesis_response_recorded": true
			}
		"event_invite":
			return {
				"relationship_delta": int(round(float(DIALOG_OUTCOME_EVENT_RELATIONSHIP_DELTA) * gain_multiplier)),
				"event_invite_unlocked": true
			}
	return {}


static func outcome_label(outcome: String) -> String:
	if DIALOG_OUTCOME_LABELS.has(outcome):
		return str(DIALOG_OUTCOME_LABELS.get(outcome, ""))
	return ""


static func outcome_timeline_note(outcome: String, outcome_effect: Dictionary) -> String:
	match outcome:
		"source_check":
			if int(outcome_effect.get("credibility_delta", 0)) > 0:
				return "Source check: credibility improved."
			return "Source check logged."
		"clean_read":
			if float(outcome_effect.get("relationship_progress_delta", 0.0)) > 0.0:
				return "Clean read: relationship progress banked."
			return "Clean read logged."
		"direct_tip":
			if bool(outcome_effect.get("direct_tip_recorded", false)):
				return "Direct tip: inner-circle read recorded."
			return "Direct tip requested."
		"contact_discovery":
			if int(outcome_effect.get("network_source_quality_delta", 0)) > 0:
				return "Contact discovery: Network lead quality improved."
			return "Contact discovery recorded."
		"thesis_response":
			if int(outcome_effect.get("credibility_delta", 0)) > 0:
				return "Thesis response: credibility improved."
			return "Thesis response recorded."
		"event_invite":
			if bool(outcome_effect.get("event_invite_unlocked", false)):
				return "Event invite: room opportunity logged."
			return "Event invite path opened."
		"suspicious_boundary":
			if int(outcome_effect.get("exposure_delta", 0)) < 0:
				return "Boundary kept clean: exposure reduced."
			return "Boundary kept clean."
	return ""


static func timeline_text_with_dialog_outcome(text: String, outcome: String, outcome_effect: Dictionary) -> String:
	var clean_text: String = text.strip_edges()
	var note: String = outcome_timeline_note(outcome, outcome_effect)
	if note.is_empty():
		return clean_text
	if clean_text.is_empty():
		return note
	return "%s %s" % [clean_text, note]


static func network_dialog_confidence_label(action_id: String, outcome: String, outcome_effect: Dictionary) -> String:
	if outcome == "source_check" and int(outcome_effect.get("network_source_quality_delta", 0)) > 0:
		return "source checked"
	if outcome == "suspicious_boundary":
		return "clean boundary"
	if outcome == "clean_read":
		return "clean read"
	if outcome == "direct_tip":
		return "inner-circle direct read"
	if outcome == "contact_discovery":
		return "contact discovered"
	if outcome == "thesis_response":
		return "thesis reviewed" if int(outcome_effect.get("credibility_delta", 0)) > 0 else "thesis logged"
	if outcome == "event_invite":
		return "room invite"
	if action_id == "ask_source_private":
		return "source ask"
	return "social"


static func is_network_source_account(account: Dictionary) -> bool:
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	return bool(profile.get("network_source", false)) or str(profile.get("account_origin", "")) == "network_contact"
