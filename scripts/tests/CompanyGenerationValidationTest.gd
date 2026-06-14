extends Node

const COMPANY_GENERATOR_SCRIPT = preload("res://systems/CompanyGenerator.gd")


func _ready() -> void:
	var generator = COMPANY_GENERATOR_SCRIPT.new()
	var invalid_template: Dictionary = {
		"id": "bad_company",
		"ticker": "BAD",
		"name": "Bad Company",
		"sector_id": "invalid_template_sector",
		"anchors": {
			"base_price": 0.0,
			"quality": 120.0,
			"growth": 58.0,
			"risk": -4.0,
			"free_float_pct": -8.0,
			"avg_daily_value": 0.0,
			"net_profit_margin": 7.5,
			"debt_to_equity": -0.20,
			"scale_tier_rank": 9,
			"scale_market_cap_floor": 5000000000000.0,
			"scale_market_cap_ceiling": 4000000000000.0,
			"target_price_floor": 1000.0,
			"target_price_ceiling": 900.0,
			"capital_structure_style": "mystery"
		},
		"chart_profile": {
			"archetype": "moonshot",
			"chart_intent": "daydream",
			"cycle_template": "spiral",
			"fib_profile_id": "fib_unknown"
		}
	}
	var invalid_sector_definition: Dictionary = {
		"id": "invalid_sector"
	}

	var result: Dictionary = generator.call("_validate_generation_inputs", invalid_template, invalid_sector_definition, false)
	if bool(result.get("valid", true)):
		_fail("Expected invalid generation input probe to return valid=false.")
		return

	var issues: Array = result.get("issues", [])
	if issues.size() < 10:
		_fail("Expected invalid generation input probe to report multiple issues, got %d." % issues.size())
		return
	if not _issue_contains(issues, "sector_id"):
		_fail("Expected invalid generation input probe to report bad sector_id.")
		return
	if not _issue_contains(issues, "anchors.market_cap"):
		_fail("Expected invalid generation input probe to report missing market_cap.")
		return
	if not _issue_contains(issues, "anchors.base_price"):
		_fail("Expected invalid generation input probe to report bad base_price.")
		return
	if not _issue_contains(issues, "chart_profile.archetype"):
		_fail("Expected invalid generation input probe to report bad chart_profile archetype.")
		return

	print("COMPANY_GENERATION_VALIDATION_WARNING_OK %s" % JSON.stringify({
		"issue_count": issues.size(),
		"hard_fail": false
	}))
	get_tree().quit(0)


func _issue_contains(issues: Array, needle: String) -> bool:
	for issue_value in issues:
		if str(issue_value).contains(needle):
			return true
	return false


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
