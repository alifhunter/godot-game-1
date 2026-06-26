extends Node

const EXPECTED_COMPANY_COUNT := 100


func _ready() -> void:
	DataRepository.reload_all()
	var validation: Dictionary = DataRepository.get_company_universe_validation_result()
	if not bool(validation.get("valid", false)):
		_fail("Company universe catalog validation failed: %s" % JSON.stringify(validation.get("issues", [])))
		return

	var companies: Array = DataRepository.get_company_universe_companies()
	if companies.size() != EXPECTED_COMPANY_COUNT:
		_fail("Expected %d company universe entries, got %d." % [EXPECTED_COMPANY_COUNT, companies.size()])
		return
	if int(validation.get("company_count", 0)) != EXPECTED_COMPANY_COUNT:
		_fail("Expected validation company_count=%d, got %d." % [
			EXPECTED_COMPANY_COUNT,
			int(validation.get("company_count", 0))
		])
		return
	if int(validation.get("unique_ids", 0)) != EXPECTED_COMPANY_COUNT:
		_fail("Expected validation unique_ids=%d, got %d." % [
			EXPECTED_COMPANY_COUNT,
			int(validation.get("unique_ids", 0))
		])
		return
	if int(validation.get("unique_tickers", 0)) != EXPECTED_COMPANY_COUNT:
		_fail("Expected validation unique_tickers=%d, got %d." % [
			EXPECTED_COMPANY_COUNT,
			int(validation.get("unique_tickers", 0))
		])
		return
	if int(validation.get("schema_version", 0)) != 1:
		_fail("Expected schema_version=1, got %d." % int(validation.get("schema_version", 0)))
		return

	var sector_counts: Dictionary = validation.get("sector_counts", {})
	if sector_counts.size() < 10:
		_fail("Expected at least 10 sectors in company universe catalog, got %d." % sector_counts.size())
		return
	for sector_id_value in sector_counts.keys():
		var sector_id: String = str(sector_id_value)
		if DataRepository.get_sector_definition(sector_id).is_empty():
			_fail("Catalog validation returned unknown sector '%s'." % sector_id)
			return

	var sawit: Dictionary = DataRepository.get_company_universe_company("sawit_bumi_raya")
	if sawit.is_empty():
		_fail("Expected to find sawit_bumi_raya in company universe catalog.")
		return
	if str(sawit.get("sector", "")) != "noncyclical":
		_fail("Expected sawit_bumi_raya sector noncyclical, got '%s'." % str(sawit.get("sector", "")))
		return
	var commodity_exposures: Dictionary = sawit.get("commodity_exposures", {})
	if float(commodity_exposures.get("cpo", 0.0)) <= 0.0:
		_fail("Expected sawit_bumi_raya to have positive CPO exposure.")
		return

	var copy_probe: Array = DataRepository.get_company_universe_companies()
	if copy_probe.is_empty():
		_fail("Company universe copy probe returned empty companies.")
		return
	var first_company: Dictionary = copy_probe[0]
	first_company["name"] = "MUTATED COPY"
	var fresh_copy: Array = DataRepository.get_company_universe_companies()
	var fresh_first: Dictionary = fresh_copy[0]
	if str(fresh_first.get("name", "")) == "MUTATED COPY":
		_fail("Company universe accessor returned mutable internal state.")
		return

	print("COMPANY_UNIVERSE_CATALOG_VALIDATION_OK %s" % JSON.stringify({
		"companies": companies.size(),
		"schema_version": validation.get("schema_version", 0),
		"sectors": sector_counts.size(),
		"sample_id": sawit.get("id", "")
	}))
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	print("COMPANY_UNIVERSE_CATALOG_VALIDATION_FAIL: %s" % message)
	get_tree().quit(1)
