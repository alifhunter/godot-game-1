extends Node

const COMPANY_ARCHETYPES_PATH := "res://data/companies/company_archetypes.json"
const COMPANY_WORDS_PATH := "res://data/companies/company_words.json"
const COMPANY_PROFILE_DATA_PATH := "res://data/companies/company_profile_data.json"
const BROKER_ROSTER_PATH := "res://data/brokers/broker_roster.json"
const SECTORS_PATH := "res://data/sectors/sectors.json"
const EVENTS_PATH := "res://data/events/events.json"
const CORPORATE_ACTION_CATALOG_PATH := "res://data/corporate_actions/corporate_action_catalog.json"
const NEWS_FEED_DATA_PATH := "res://data/news/news_feed_data.json"
const TWOOTER_FEED_DATA_PATH := "res://data/social/twooter_feed_data.json"
const CONTACT_NETWORK_DATA_PATH := "res://data/network/contact_network_data.json"
const UPGRADE_CATALOG_PATH := "res://data/upgrades/upgrade_catalog.json"
const ACADEMY_CATALOG_PATH := "res://data/academy/academy_catalog.json"

var company_archetypes = []
var company_words = {}
var company_profile_data = {}
var broker_roster = []
var sectors = []
var event_definitions = []
var corporate_action_catalog = {}
var news_feed_data = {}
var twooter_feed_data = {}
var contact_network_data = {}
var upgrade_catalog = {}
var academy_catalog = {}
var company_archetype_by_id = {}
var broker_by_code = {}
var sector_by_id = {}
var event_by_id = {}


func _ready() -> void:
	reload_all()


func reload_all() -> void:
	company_archetypes = _load_array_json(COMPANY_ARCHETYPES_PATH)
	company_words = _load_dictionary_json(COMPANY_WORDS_PATH)
	company_profile_data = _load_dictionary_json(COMPANY_PROFILE_DATA_PATH)
	broker_roster = _load_array_json(BROKER_ROSTER_PATH)
	sectors = _load_array_json(SECTORS_PATH)
	event_definitions = _load_array_json(EVENTS_PATH)
	corporate_action_catalog = _load_dictionary_json(CORPORATE_ACTION_CATALOG_PATH)
	news_feed_data = _load_dictionary_json(NEWS_FEED_DATA_PATH)
	twooter_feed_data = _load_dictionary_json(TWOOTER_FEED_DATA_PATH)
	contact_network_data = _load_dictionary_json(CONTACT_NETWORK_DATA_PATH)
	upgrade_catalog = _load_dictionary_json(UPGRADE_CATALOG_PATH)
	academy_catalog = _load_dictionary_json(ACADEMY_CATALOG_PATH)

	company_archetype_by_id.clear()
	for company_archetype in company_archetypes:
		company_archetype_by_id[str(company_archetype.get("id", ""))] = company_archetype

	sector_by_id.clear()
	for sector in sectors:
		sector_by_id[str(sector.get("id", ""))] = sector

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


func get_company_archetype(company_id: String) -> Dictionary:
	if not company_archetype_by_id.has(company_id):
		return {}
	return company_archetype_by_id[company_id].duplicate(true)


func get_company_definition(company_id: String) -> Dictionary:
	return get_company_archetype(company_id)


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


func _load_json_value(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Missing JSON data file: %s" % path)
		return null

	var raw_text = FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(raw_text)
	return parsed
