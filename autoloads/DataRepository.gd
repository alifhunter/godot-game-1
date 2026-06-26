extends Node

const COMPANY_ARCHETYPES_PATH := "res://data/companies/company_archetypes.json"
const COMPANY_WORDS_PATH := "res://data/companies/company_words.json"
const COMPANY_PROFILE_DATA_PATH := "res://data/companies/company_profile_data.json"
const COMPANY_ROADMAP_CATALOG_PATH := "res://data/companies/company_roadmap_catalog.json"
const COMPANY_UNIVERSE_CATALOG_PATH := "res://data/companies/company_universe_catalog.json"
const COMMODITY_INDICATOR_CATALOG_PATH := "res://data/macro/commodity_indicator_catalog.json"
const BROKER_ROSTER_PATH := "res://data/brokers/broker_roster.json"
const SECTORS_PATH := "res://data/sectors/sectors.json"
const EVENTS_PATH := "res://data/events/events.json"
const INDEX_REVIEW_CATALOG_PATH := "res://data/index_reviews/index_review_catalog.json"
const CORPORATE_ACTION_CATALOG_PATH := "res://data/corporate_actions/corporate_action_catalog.json"
const NEWS_FEED_DATA_PATH := "res://data/news/news_feed_data.json"
const TWOOTER_FEED_DATA_PATH := "res://data/social/twooter_feed_data.json"
const CONTACT_NETWORK_DATA_PATH := "res://data/network/contact_network_data.json"
const UPGRADE_CATALOG_PATH := "res://data/upgrades/upgrade_catalog.json"
const ACADEMY_CATALOG_PATH := "res://data/academy/academy_catalog.json"
const THESIS_CONTENT_PATH := "res://data/thesis/thesis_content.json"
const COMPANY_UNIVERSE_REQUIRED_FIELDS := [
	"id",
	"ticker",
	"name",
	"sector",
	"subsector",
	"business_summary",
	"moat_tags",
	"commodity_exposures",
	"macro_exposures",
	"price_traits",
	"relationship_hooks",
	"story_hooks"
]
const COMPANY_UNIVERSE_ARRAY_FIELDS := ["moat_tags", "relationship_hooks", "story_hooks"]
const COMPANY_UNIVERSE_EXPOSURE_FIELDS := ["commodity_exposures", "macro_exposures"]
const COMPANY_UNIVERSE_PRICE_TRAIT_FIELDS := [
	"liquidity_profile",
	"volatility_profile",
	"quality_bias",
	"growth_bias",
	"risk_bias",
	"retail_attention_bias",
	"event_sensitivity"
]

var company_archetypes = []
var company_words = {}
var company_profile_data = {}
var company_roadmap_catalog = {}
var company_universe_catalog = {}
var company_universe_validation_result = {}
var commodity_indicator_catalog = {}
var broker_roster = []
var sectors = []
var event_definitions = []
var index_review_catalog = {}
var corporate_action_catalog = {}
var news_feed_data = {}
var twooter_feed_data = {}
var contact_network_data = {}
var upgrade_catalog = {}
var academy_catalog = {}
var thesis_content = {}
var company_archetype_by_id = {}
var company_universe_by_id = {}
var broker_by_code = {}
var sector_by_id = {}
var event_by_id = {}


func _ready() -> void:
	reload_all()


func reload_all() -> void:
	company_archetypes = _load_array_json(COMPANY_ARCHETYPES_PATH)
	company_words = _load_dictionary_json(COMPANY_WORDS_PATH)
	company_profile_data = _load_dictionary_json(COMPANY_PROFILE_DATA_PATH)
	company_roadmap_catalog = _load_dictionary_json(COMPANY_ROADMAP_CATALOG_PATH)
	company_universe_catalog = _load_optional_dictionary_json(COMPANY_UNIVERSE_CATALOG_PATH)
	commodity_indicator_catalog = _load_optional_dictionary_json(COMMODITY_INDICATOR_CATALOG_PATH)
	broker_roster = _load_array_json(BROKER_ROSTER_PATH)
	sectors = _load_array_json(SECTORS_PATH)
	event_definitions = _load_array_json(EVENTS_PATH)
	index_review_catalog = _load_dictionary_json(INDEX_REVIEW_CATALOG_PATH)
	corporate_action_catalog = _load_dictionary_json(CORPORATE_ACTION_CATALOG_PATH)
	news_feed_data = _load_dictionary_json(NEWS_FEED_DATA_PATH)
	twooter_feed_data = _load_dictionary_json(TWOOTER_FEED_DATA_PATH)
	contact_network_data = _load_dictionary_json(CONTACT_NETWORK_DATA_PATH)
	upgrade_catalog = _load_dictionary_json(UPGRADE_CATALOG_PATH)
	academy_catalog = _load_dictionary_json(ACADEMY_CATALOG_PATH)
	thesis_content = _load_dictionary_json(THESIS_CONTENT_PATH)

	company_archetype_by_id.clear()
	for company_archetype in company_archetypes:
		company_archetype_by_id[str(company_archetype.get("id", ""))] = company_archetype

	sector_by_id.clear()
	for sector in sectors:
		sector_by_id[str(sector.get("id", ""))] = sector

	company_universe_by_id.clear()
	company_universe_validation_result = _validate_company_universe_catalog(company_universe_catalog)
	var company_universe_companies: Array = company_universe_catalog.get("companies", [])
	for company_value in company_universe_companies:
		if typeof(company_value) != TYPE_DICTIONARY:
			continue
		var company: Dictionary = company_value
		var company_id: String = str(company.get("id", "")).strip_edges()
		if not company_id.is_empty():
			company_universe_by_id[company_id] = company

	broker_by_code.clear()
	for broker_value in broker_roster:
		var broker: Dictionary = broker_value
		broker_by_code[str(broker.get("code", ""))] = broker

	event_by_id.clear()
	for event_definition in event_definitions:
		event_by_id[str(event_definition.get("id", ""))] = event_definition


func get_company_archetypes() -> Array:
	return company_archetypes.duplicate(true)


func get_company_definitions() -> Array:
	return get_company_archetypes()


func get_sector_definitions() -> Array:
	return sectors.duplicate(true)


func get_company_word_data() -> Dictionary:
	return company_words.duplicate(true)


func get_company_profile_data() -> Dictionary:
	return company_profile_data.duplicate(true)


func get_company_profile_data_ref() -> Dictionary:
	return company_profile_data


func get_company_roadmap_catalog() -> Dictionary:
	return company_roadmap_catalog.duplicate(true)


func get_company_roadmap_catalog_ref() -> Dictionary:
	return company_roadmap_catalog


func get_company_universe_catalog() -> Dictionary:
	return company_universe_catalog.duplicate(true)


func get_company_universe_companies() -> Array:
	return company_universe_catalog.get("companies", []).duplicate(true)


func get_company_universe_company(company_id: String) -> Dictionary:
	if not company_universe_by_id.has(company_id):
		return {}
	return company_universe_by_id[company_id].duplicate(true)


func get_company_universe_validation_result() -> Dictionary:
	return company_universe_validation_result.duplicate(true)


func get_commodity_indicator_catalog() -> Dictionary:
	return commodity_indicator_catalog.duplicate(true)


func get_commodity_indicator_definitions() -> Array:
	return commodity_indicator_catalog.get("commodities", []).duplicate(true)


func get_broker_roster() -> Array:
	return broker_roster.duplicate(true)


func get_company_name_words() -> Array:
	return company_words.get("unique_words", []).duplicate(true)


func get_event_definitions() -> Array:
	return event_definitions.duplicate(true)


func get_news_feed_data() -> Dictionary:
	return news_feed_data.duplicate(true)


func get_corporate_action_catalog() -> Dictionary:
	return corporate_action_catalog.duplicate(true)


func get_index_review_catalog() -> Dictionary:
	return index_review_catalog.duplicate(true)


func get_twooter_feed_data() -> Dictionary:
	return twooter_feed_data.duplicate(true)


func get_contact_network_data() -> Dictionary:
	return contact_network_data.duplicate(true)


func get_contact_network_data_ref() -> Dictionary:
	return contact_network_data


func get_upgrade_catalog() -> Dictionary:
	return upgrade_catalog.duplicate(true)


func get_academy_catalog() -> Dictionary:
	return academy_catalog.duplicate(true)


func get_thesis_content_catalog() -> Dictionary:
	return thesis_content.duplicate(true)


func get_company_archetype(company_id: String) -> Dictionary:
	if not company_archetype_by_id.has(company_id):
		return {}
	return company_archetype_by_id[company_id].duplicate(true)


func get_company_definition(company_id: String) -> Dictionary:
	return get_company_archetype(company_id)


func get_company_universe_definition(company_id: String) -> Dictionary:
	return get_company_universe_company(company_id)


func get_sector_definition(sector_id: String) -> Dictionary:
	if not sector_by_id.has(sector_id):
		return {}
	return sector_by_id[sector_id].duplicate(true)


func get_broker_definition(broker_code: String) -> Dictionary:
	if not broker_by_code.has(broker_code):
		return {}
	return broker_by_code[broker_code].duplicate(true)


func get_event_definition(event_id: String) -> Dictionary:
	if not event_by_id.has(event_id):
		return {}
	return event_by_id[event_id].duplicate(true)


func _load_array_json(path: String) -> Array:
	var parsed = _load_json_value(path)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Expected JSON array in %s" % path)
		return []

	return parsed.duplicate(true)


func _load_dictionary_json(path: String) -> Dictionary:
	var parsed = _load_json_value(path)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Expected JSON object in %s" % path)
		return {}

	return parsed.duplicate(true)


func _load_optional_dictionary_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Optional JSON data file is missing: %s" % path)
		return {}
	var parsed = _load_json_value(path)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Expected optional JSON object in %s" % path)
		return {}
	return parsed.duplicate(true)


func _load_json_value(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Missing JSON data file: %s" % path)
		return null

	var raw_text = FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(raw_text)
	return parsed


func _validate_company_universe_catalog(catalog: Dictionary) -> Dictionary:
	var issues: Array = []
	var companies_value: Variant = catalog.get("companies", [])
	if typeof(companies_value) != TYPE_ARRAY:
		issues.append("companies must be an array")
		return _company_universe_validation_summary(false, issues, {}, 0, 0, 0)

	var companies: Array = companies_value
	var seen_ids: Dictionary = {}
	var seen_tickers: Dictionary = {}
	var sector_counts: Dictionary = {}
	var valid_company_count: int = 0

	for company_index in range(companies.size()):
		var company_value: Variant = companies[company_index]
		if typeof(company_value) != TYPE_DICTIONARY:
			issues.append("companies[%d] must be a dictionary" % company_index)
			continue
		var company: Dictionary = company_value
		valid_company_count += 1
		_validate_company_universe_entry(company, company_index, issues, seen_ids, seen_tickers, sector_counts)

	return _company_universe_validation_summary(
		issues.is_empty(),
		issues,
		sector_counts,
		valid_company_count,
		seen_ids.size(),
		seen_tickers.size()
	)


func _validate_company_universe_entry(
	company: Dictionary,
	company_index: int,
	issues: Array,
	seen_ids: Dictionary,
	seen_tickers: Dictionary,
	sector_counts: Dictionary
) -> void:
	for required_field_value in COMPANY_UNIVERSE_REQUIRED_FIELDS:
		var required_field: String = str(required_field_value)
		if not company.has(required_field):
			issues.append("companies[%d] missing required field '%s'" % [company_index, required_field])

	var company_id: String = str(company.get("id", "")).strip_edges()
	var ticker: String = str(company.get("ticker", "")).strip_edges()
	var name: String = str(company.get("name", "")).strip_edges()
	var sector_id: String = str(company.get("sector", "")).strip_edges()
	var subsector: String = str(company.get("subsector", "")).strip_edges()
	var business_summary: String = str(company.get("business_summary", "")).strip_edges()

	if company_id.is_empty():
		issues.append("companies[%d].id is empty" % company_index)
	elif seen_ids.has(company_id):
		issues.append("companies[%d].id '%s' duplicates companies[%d]" % [company_index, company_id, int(seen_ids[company_id])])
	else:
		seen_ids[company_id] = company_index

	if ticker.is_empty():
		issues.append("companies[%d].ticker is empty" % company_index)
	elif ticker != ticker.to_upper():
		issues.append("companies[%d].ticker '%s' must be uppercase" % [company_index, ticker])
	elif seen_tickers.has(ticker):
		issues.append("companies[%d].ticker '%s' duplicates companies[%d]" % [company_index, ticker, int(seen_tickers[ticker])])
	else:
		seen_tickers[ticker] = company_index

	if name.is_empty():
		issues.append("companies[%d].name is empty" % company_index)
	if business_summary.is_empty():
		issues.append("companies[%d].business_summary is empty" % company_index)
	if subsector.is_empty():
		issues.append("companies[%d].subsector is empty" % company_index)
	elif not _is_snake_case_identifier(subsector):
		issues.append("companies[%d].subsector '%s' must be snake_case" % [company_index, subsector])

	if sector_id.is_empty():
		issues.append("companies[%d].sector is empty" % company_index)
	elif not sector_by_id.has(sector_id):
		issues.append("companies[%d].sector '%s' is unknown" % [company_index, sector_id])
	else:
		sector_counts[sector_id] = int(sector_counts.get(sector_id, 0)) + 1

	for array_field_value in COMPANY_UNIVERSE_ARRAY_FIELDS:
		var array_field: String = str(array_field_value)
		if typeof(company.get(array_field, [])) != TYPE_ARRAY:
			issues.append("companies[%d].%s must be an array" % [company_index, array_field])

	for exposure_field_value in COMPANY_UNIVERSE_EXPOSURE_FIELDS:
		var exposure_field: String = str(exposure_field_value)
		var exposure_map_value: Variant = company.get(exposure_field, {})
		if typeof(exposure_map_value) != TYPE_DICTIONARY:
			issues.append("companies[%d].%s must be a dictionary" % [company_index, exposure_field])
			continue
		_validate_company_universe_exposure_map(exposure_map_value, "companies[%d].%s" % [company_index, exposure_field], issues)

	var price_traits_value: Variant = company.get("price_traits", {})
	if typeof(price_traits_value) != TYPE_DICTIONARY:
		issues.append("companies[%d].price_traits must be a dictionary" % company_index)
	else:
		_validate_company_universe_price_traits(price_traits_value, company_index, issues)

	_validate_company_universe_relationship_hooks(company.get("relationship_hooks", []), company_index, issues)


func _validate_company_universe_exposure_map(exposure_map: Dictionary, path: String, issues: Array) -> void:
	for exposure_key_value in exposure_map.keys():
		var exposure_key: String = str(exposure_key_value)
		var exposure_value: Variant = exposure_map[exposure_key_value]
		if exposure_key.strip_edges().is_empty():
			issues.append("%s has an empty exposure key" % path)
		elif not _is_snake_case_identifier(exposure_key):
			issues.append("%s key '%s' must be snake_case" % [path, exposure_key])
		if not _is_number(exposure_value):
			issues.append("%s.%s must be numeric" % [path, exposure_key])
			continue
		var exposure: float = float(exposure_value)
		if exposure < -1.0 or exposure > 1.0:
			issues.append("%s.%s %.3f is outside -1.0..1.0" % [path, exposure_key, exposure])


func _validate_company_universe_price_traits(price_traits: Dictionary, company_index: int, issues: Array) -> void:
	for field_value in COMPANY_UNIVERSE_PRICE_TRAIT_FIELDS:
		var field: String = str(field_value)
		if not price_traits.has(field):
			issues.append("companies[%d].price_traits missing '%s'" % [company_index, field])
			continue
		if field in ["liquidity_profile", "volatility_profile"]:
			var label: String = str(price_traits.get(field, "")).strip_edges()
			if label.is_empty():
				issues.append("companies[%d].price_traits.%s is empty" % [company_index, field])
			continue
		var value: Variant = price_traits.get(field)
		if not _is_number(value):
			issues.append("companies[%d].price_traits.%s must be numeric" % [company_index, field])
			continue
		var score: float = float(value)
		if score < -1.0 or score > 1.0:
			issues.append("companies[%d].price_traits.%s %.3f is outside -1.0..1.0" % [company_index, field, score])


func _validate_company_universe_relationship_hooks(hooks_value: Variant, company_index: int, issues: Array) -> void:
	if typeof(hooks_value) != TYPE_ARRAY:
		return
	var hooks: Array = hooks_value
	for hook_index in range(hooks.size()):
		var hook_value: Variant = hooks[hook_index]
		if typeof(hook_value) != TYPE_DICTIONARY:
			issues.append("companies[%d].relationship_hooks[%d] must be a dictionary" % [company_index, hook_index])
			continue
		var hook: Dictionary = hook_value
		for field in ["type", "target_sector", "target_subsector", "visibility"]:
			if str(hook.get(field, "")).strip_edges().is_empty():
				issues.append("companies[%d].relationship_hooks[%d].%s is empty" % [company_index, hook_index, field])
		var target_sector: String = str(hook.get("target_sector", "")).strip_edges()
		if not target_sector.is_empty() and not sector_by_id.has(target_sector):
			issues.append("companies[%d].relationship_hooks[%d].target_sector '%s' is unknown" % [company_index, hook_index, target_sector])
		if not _is_number(hook.get("strength", null)):
			issues.append("companies[%d].relationship_hooks[%d].strength must be numeric" % [company_index, hook_index])
			continue
		var strength: float = float(hook.get("strength", 0.0))
		if strength < 0.0 or strength > 1.0:
			issues.append("companies[%d].relationship_hooks[%d].strength %.3f is outside 0.0..1.0" % [company_index, hook_index, strength])


func _company_universe_validation_summary(
	valid: bool,
	issues: Array,
	sector_counts: Dictionary,
	company_count: int,
	unique_ids: int,
	unique_tickers: int
) -> Dictionary:
	return {
		"valid": valid,
		"issues": issues.duplicate(true),
		"schema_version": int(company_universe_catalog.get("schema_version", 0)),
		"company_count": company_count,
		"unique_ids": unique_ids,
		"unique_tickers": unique_tickers,
		"sector_counts": sector_counts.duplicate(true)
	}


func _is_number(value: Variant) -> bool:
	var type_id: int = typeof(value)
	return type_id == TYPE_INT or type_id == TYPE_FLOAT


func _is_snake_case_identifier(value: String) -> bool:
	if value.is_empty():
		return false
	for index in range(value.length()):
		var code: int = value.unicode_at(index)
		var is_digit: bool = code >= 48 and code <= 57
		var is_lower: bool = code >= 97 and code <= 122
		var is_underscore: bool = code == 95
		if not is_digit and not is_lower and not is_underscore:
			return false
	return true
