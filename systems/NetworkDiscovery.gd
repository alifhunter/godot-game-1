extends RefCounted

const STABLE_RNG = preload("res://systems/StableRng.gd")
const MEETING_LEAD_TIER_ORDER := {
	"open": 0,
	"low": 1,
	"mid": 2,
	"high": 3
}


static func discovery_limit_for_source(source_type: String, company_count: int) -> int:
	if source_type == "profile":
		return max(company_count, 1)
	if source_type == "news":
		return max(company_count, 1)
	return 3


static func floater_discovery_score(contact: Dictionary, company_id: String, sector_id: String, category: String, source_type: String) -> float:
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


static func meeting_profile_matches_contact(profile: Dictionary, contact: Dictionary, sector_id: String) -> bool:
	var contact_categories: Array = contact.get("categories", [])
	var profile_categories: Array = profile.get("category_ids", [])
	var has_category_match: bool = profile_categories.is_empty()
	for category_value in profile_categories:
		if str(category_value) in contact_categories:
			has_category_match = true
			break
	var sector_match: bool = (not sector_id.is_empty()) and (sector_id in contact.get("sector_ids", []))
	if bool(profile.get("sector_match_required", false)) and not sector_match:
		return false
	return has_category_match or sector_match


static func meeting_lead_contact_score(run_state, contact: Dictionary, profile: Dictionary, company_id: String, sector_id: String) -> float:
	var score: float = 0.0
	if not sector_id.is_empty() and sector_id in contact.get("sector_ids", []):
		score += 60.0
	for category_value in profile.get("category_ids", []):
		if str(category_value) in contact.get("categories", []):
			score += 18.0
	score += clamp(float(contact.get("reliability", 0.55)), 0.0, 1.0) * 12.0
	score += max(0.0, 55.0 - float(contact.get("recognition_required", 0))) * 0.08
	if bool(run_state.get_network_contacts().get(str(contact.get("id", "")), {}).get("met", false)):
		score -= 18.0
	score += float(STABLE_RNG.seed_from_parts([company_id, str(profile.get("id", "")), str(contact.get("id", "")), "meeting_lead"]) % 1000) / 1000.0
	return score


static func meeting_lead_tier_rank(tier_id: String) -> int:
	return int(MEETING_LEAD_TIER_ORDER.get(tier_id, 99))


static func sentiment_for_contact(contact: Dictionary, action: String) -> float:
	var reliability: float = clamp(float(contact.get("reliability", 0.6)), 0.25, 0.95)
	var direction: float = -1.0 if str(contact.get("tone", "mixed")) == "negative" else 1.0
	if str(contact.get("tone", "mixed")) == "mixed":
		direction = 1.0 if action == "request" else 0.72
	return direction * lerp(0.009, 0.022, reliability)


static func contact_arc_description(contact: Dictionary, ticker: String, action: String) -> String:
	var verb: String = "tip" if action == "tip" else "request"
	return "%s gave you a %s tied to %s." % [str(contact.get("display_name", "A contact")), verb, ticker]
