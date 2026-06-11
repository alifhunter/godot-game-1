class_name CompanyProfile
extends RefCounted

# Canonical schema for a generated company profile. This class is the single
# source of truth for which keys a profile may carry; RunState iterates KEYS
# when building profile views and overlaying profiles onto definitions.
const KEYS := [
	"name",
	"sector_id",
	"base_price",
	"quality_score",
	"growth_score",
	"risk_score",
	"base_volatility",
	"financials",
	"financial_history",
	"financial_statement_snapshot",
	"quarterly_filing_history",
	"generation_traits",
	"shares_outstanding",
	"detail_status",
	"profile_seed",
	"profile_scale_version",
	"archetype_id",
	"archetype_label",
	"company_size_id",
	"company_size_label",
	"company_age",
	"founded_year",
	"employee_count",
	"profile_revenue",
	"profile_revenue_value",
	"profile_revenue_unit",
	"profile_description",
	"profile_tags",
	"management_roster",
	"location_profile",
	"roadmap_profile",
	"post_deal_identity"
]

# Profiles are sparse: a key absent from the source dict must stay absent so
# overlays don't clobber definition values. _data holds only present keys.
var _data: Dictionary = {}


static func from_dict(d: Dictionary) -> CompanyProfile:
	var profile := CompanyProfile.new()
	for key_value in KEYS:
		var key: String = str(key_value)
		if d.has(key):
			var value = d[key]
			profile._data[key] = value.duplicate(true) if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY else value
	return profile


func to_dict() -> Dictionary:
	return _data.duplicate(true)


func has_field(key: String) -> bool:
	return _data.has(key)


func get_field(key: String, default_value = null):
	return _data.get(key, default_value)


func set_field(key: String, value) -> void:
	if not KEYS.has(key):
		push_warning("CompanyProfile.set_field: '%s' is not a known profile key" % key)
		return
	_data[key] = value


# ─── Typed convenience accessors for the hot scalar fields ───────────────────

func company_name() -> String:
	return str(_data.get("name", ""))


func sector_id() -> String:
	return str(_data.get("sector_id", ""))


func base_price() -> float:
	return float(_data.get("base_price", 0.0))


func quality_score() -> float:
	return float(_data.get("quality_score", 50.0))


func growth_score() -> float:
	return float(_data.get("growth_score", 50.0))


func risk_score() -> float:
	return float(_data.get("risk_score", 50.0))


func base_volatility() -> float:
	return float(_data.get("base_volatility", 0.0))


func generation_traits() -> Dictionary:
	var value = _data.get("generation_traits", {})
	return value if typeof(value) == TYPE_DICTIONARY else {}


func financials() -> Dictionary:
	var value = _data.get("financials", {})
	return value if typeof(value) == TYPE_DICTIONARY else {}
