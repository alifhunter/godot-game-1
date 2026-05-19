extends Node

const RUN_SEED := 516426
const TEST_CASH := 120000000000.0


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0
	_reset_cash()

	var baseline_save: Dictionary = RunState.to_save_dict()
	if not _assert_old_save_normalization(baseline_save):
		return

	RunState.load_from_dict(baseline_save)
	_reset_cash()
	if not _assert_news_and_network_lead_creation():
		return

	RunState.load_from_dict(baseline_save)
	_reset_cash()
	if not _assert_confirmed_lead_appreciation():
		return

	RunState.load_from_dict(baseline_save)
	_reset_cash()
	if not _assert_cancelled_and_delayed_leads():
		return

	print("LIFE_DEVELOPMENT_INTEL_TEST_OK")
	get_tree().quit(0)


func _assert_old_save_normalization(baseline_save: Dictionary) -> bool:
	var legacy_save: Dictionary = baseline_save.duplicate(true)
	var legacy_life: Dictionary = legacy_save.get("player_life", {}).duplicate(true)
	legacy_life.erase("development_leads")
	legacy_life["properties"] = [
		{
			"id": "legacy_property",
			"catalog_id": "kost_room",
			"location_id": "bodetabek",
			"location_label": "Bodetabek",
			"label": "Legacy Kost",
			"purchase_price": 350000000.0,
			"current_value": 350000000.0,
			"monthly_upkeep": 900000.0,
			"rent_income": 2400000.0
		}
	]
	legacy_life["development_leads"] = [
		{
			"id": "legacy_lead",
			"location_id": "jabodetabek",
			"location_label": "Jabodetabek",
			"theme": "modern_city",
			"impact_tier": "moderate",
			"source_type": "news",
			"source_id": "legacy_news",
			"source_label": "Legacy report",
			"source_note": "Legacy report mentioned Jabodetabek.",
			"reliability": 50.0,
			"clarity_level": 2,
			"due_day_index": RunState.day_index + 4,
			"resolved": false
		}
	]
	legacy_save["player_life"] = legacy_life
	RunState.load_from_dict(legacy_save)
	var normalized_life: Dictionary = RunState.get_player_life()
	var properties: Array = normalized_life.get("properties", [])
	if properties.size() != 1:
		_fail("Old saves should preserve legacy Life properties.")
		return false
	var legacy_property: Dictionary = properties[0]
	if not legacy_property.has("base_value") or not legacy_property.has("value_events") or typeof(legacy_property.get("value_events", null)) != TYPE_ARRAY:
		_fail("Old property rows should normalize base_value and value_events.")
		return false
	if str(legacy_property.get("location_id", "")) in ["bodetabek", "jabodetabek"] or str(legacy_property.get("location_label", "")).to_lower().contains("bodetabek"):
		_fail("Old property rows should migrate legacy location labels to explicit cities.")
		return false
	var development_leads: Array = normalized_life.get("development_leads", [])
	if development_leads.size() != 1:
		_fail("Old saves should preserve legacy Life development leads.")
		return false
	var legacy_lead: Dictionary = development_leads[0]
	var legacy_lead_text: String = "%s %s %s" % [
		str(legacy_lead.get("location_id", "")),
		str(legacy_lead.get("location_label", "")),
		str(legacy_lead.get("source_note", ""))
	]
	if legacy_lead_text.to_lower().contains("bodetabek") or legacy_lead_text.to_lower().contains("jabodetabek"):
		_fail("Old development leads should migrate legacy location labels and notes to explicit cities.")
		return false
	return true


func _assert_news_and_network_lead_creation() -> bool:
	var article: Dictionary = {
		"id": "life_dev_news_fixture",
		"headline": "New toll road exit and industrial estate plan enter permit watch",
		"deck": "Infrastructure planners point to a new growth corridor.",
		"body": "The government is studying a toll road exit, industrial estate, logistics access, and housing support around a secondary city.",
		"category": "infrastructure",
		"target_sector_id": "property",
		"intel_level": 1,
		"author_contact_id": "haris_construction_worker"
	}
	var news_result: Dictionary = GameManager.discover_life_development_lead_from_article(article)
	if not bool(news_result.get("success", false)):
		_fail("Expected News article to create a property development lead: %s" % str(news_result.get("message", "")))
		return false
	var low_tier_lead: Dictionary = news_result.get("lead", {})
	if int(low_tier_lead.get("clarity_level", 0)) != 1 or not str(low_tier_lead.get("source_note", "")).to_lower().contains("not been publicly named"):
		_fail("Expected low-tier News property intel to keep location and sponsor pending.")
		return false
	var low_article: Dictionary = GameManager._build_life_development_news_article("test_outlet", "Test Outlet", 1, article)
	var credibility_error: String = _property_article_credibility_error(low_article)
	if not credibility_error.is_empty():
		_fail(credibility_error)
		return false
	var duplicate_result: Dictionary = GameManager.discover_life_development_lead_from_article(article)
	if not bool(duplicate_result.get("success", false)) or not bool(duplicate_result.get("duplicate", false)):
		_fail("Expected duplicate News article lead to return the existing lead.")
		return false
	var high_article: Dictionary = article.duplicate(true)
	high_article["intel_level"] = 4
	high_article["outlet_label"] = "Ordal News"
	var high_duplicate_result: Dictionary = GameManager.discover_life_development_lead_from_article(high_article)
	var high_tier_lead: Dictionary = high_duplicate_result.get("lead", {})
	if (
		not bool(high_duplicate_result.get("success", false))
		or not bool(high_duplicate_result.get("duplicate", false))
		or int(high_tier_lead.get("clarity_level", 0)) < 4
		or not str(high_tier_lead.get("source_note", "")).to_lower().contains("public signals")
	):
		_fail("Expected higher-tier News to upgrade an existing property lead with clearer location/theme context.")
		return false
	var high_article_preview: Dictionary = GameManager._build_life_development_news_article("test_outlet", "Test Outlet", 4, high_article)
	credibility_error = _property_article_credibility_error(high_article_preview)
	if not credibility_error.is_empty():
		_fail(credibility_error)
		return false
	if _lead_count_for_source("news", "life_dev_news_fixture") != 1:
		_fail("Expected duplicate News lead to be stored only once.")
		return false

	var health_company_id: String = _first_company_in_sector("health")
	if health_company_id.is_empty():
		_fail("Expected generated roster to include at least one healthcare company.")
		return false
	var health_company_definition: Dictionary = RunState.company_definitions.get(health_company_id, {})
	var health_ticker: String = str(health_company_definition.get("ticker", health_company_id.to_upper()))
	var generic_health_article: Dictionary = {
		"id": "generic_health_move_fixture",
		"headline": "People are talking: %s draws public attention after today's move" % health_ticker,
		"deck": "A healthcare stock sees active trading after a busy session.",
		"body": "Market chatter focused on liquidity, valuation, and intraday momentum.",
		"category": "technology",
		"target_sector_id": "health",
		"target_ticker": health_ticker,
		"target_company_id": health_company_id,
		"intel_level": 1
	}
	var generic_health_result: Dictionary = GameManager.discover_life_development_lead_from_article(generic_health_article)
	if bool(generic_health_result.get("success", false)):
		_fail("Expected generic healthcare market chatter to avoid creating a property watch.")
		return false

	var health_site_article: Dictionary = generic_health_article.duplicate(true)
	health_site_article["id"] = "health_site_fixture"
	health_site_article["headline"] = "%s reviews hospital expansion and clinic site plan" % health_ticker
	health_site_article["body"] = "The company is studying a new medical campus, clinic facility, construction permit, and land site for future expansion."
	var health_site_result: Dictionary = GameManager.discover_life_development_lead_from_article(health_site_article)
	var health_site_lead: Dictionary = health_site_result.get("lead", {})
	if not bool(health_site_result.get("success", false)) or str(health_site_lead.get("theme", "")) != "hospital_university":
		_fail("Expected healthcare property watch only when the story points to hospital, clinic, campus, or facility expansion.")
		return false

	var roadmap_health_article: Dictionary = generic_health_article.duplicate(true)
	roadmap_health_article["id"] = "roadmap_health_site_fixture"
	roadmap_health_article["headline"] = "%s reviews clinic rollout and medical-campus expansion in Karawang" % health_ticker
	roadmap_health_article["body"] = "The company is studying a clinic facility, medical campus, land site, and construction permit near Karawang."
	roadmap_health_article["intel_level"] = 4
	roadmap_health_article["property_development_location_id"] = "karawang"
	roadmap_health_article["property_development_theme"] = "hospital_university"
	var roadmap_health_result: Dictionary = GameManager.discover_life_development_lead_from_article(roadmap_health_article)
	var roadmap_health_lead: Dictionary = roadmap_health_result.get("lead", {})
	if (
		not bool(roadmap_health_result.get("success", false))
		or str(roadmap_health_lead.get("location_id", "")) != "karawang"
		or str(roadmap_health_lead.get("theme", "")) != "hospital_university"
	):
		_fail("Expected roadmap healthcare expansion to seed a property watch in the explicit roadmap city.")
		return false
	var roadmap_property_article: Dictionary = GameManager._build_life_development_news_article("test_outlet", "Test Outlet", 4, roadmap_health_article)
	credibility_error = _property_article_credibility_error(roadmap_property_article)
	if not credibility_error.is_empty():
		_fail(credibility_error)
		return false
	var roadmap_visible_text: String = "%s %s %s" % [
		str(roadmap_property_article.get("headline", "")),
		str(roadmap_property_article.get("deck", "")),
		str(roadmap_property_article.get("body", ""))
	]
	if not roadmap_visible_text.contains("Karawang"):
		_fail("Expected property article copy to preserve the roadmap city.")
		return false

	var property_company_id: String = _first_company_in_sector("property")
	if property_company_id.is_empty():
		_fail("Expected generated roster to include at least one property company.")
		return false
	var contact_id := "haris_construction_worker"
	var contacts: Dictionary = RunState.get_network_contacts()
	var runtime: Dictionary = contacts.get(contact_id, {})
	runtime["contact_id"] = contact_id
	runtime["met"] = true
	runtime["relationship"] = 55
	runtime["last_tip_request_day_index"] = -999
	contacts[contact_id] = runtime
	RunState.set_network_contacts(contacts)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0
	var tip_result: Dictionary = GameManager.request_contact_tip(contact_id, property_company_id)
	if not bool(tip_result.get("success", false)):
		_fail("Expected construction contact tip to succeed: %s" % str(tip_result.get("message", "")))
		return false
	var network_lead: Dictionary = tip_result.get("development_lead", {})
	if network_lead.is_empty() or str(network_lead.get("source_type", "")) != "network" or str(network_lead.get("contact_id", "")) != contact_id:
		_fail("Expected relevant Network tip to attach a property development lead.")
		return false
	var network_snapshot: Dictionary = GameManager.get_network_snapshot()
	if _journal_type_count(network_snapshot.get("journal", []), "property_development_lead") < 2:
		_fail("Expected Network journal to expose News and Network development lead rows.")
		return false
	return true


func _assert_confirmed_lead_appreciation() -> bool:
	var lead_result: Dictionary = GameManager.debug_force_life_development_lead("bekasi", "modern_city", "major", "network", "confirmed_big")
	if not bool(lead_result.get("success", false)):
		_fail("Expected forced development lead to be created.")
		return false
	var lead_id: String = str(lead_result.get("lead", {}).get("id", ""))
	if lead_id.is_empty():
		_fail("Expected forced development lead to include an id.")
		return false
	var purchase_result: Dictionary = GameManager.purchase_life_property("terraced_house", "bekasi", false)
	if not bool(purchase_result.get("success", false)):
		_fail("Expected pre-confirmation property purchase to succeed: %s" % str(purchase_result.get("message", "")))
		return false
	var property_id: String = str(purchase_result.get("property", {}).get("id", ""))
	var purchase_price: float = float(purchase_result.get("property", {}).get("purchase_price", 0.0))
	var process_count: int = 0
	for _day in range(9):
		GameManager._advance_day_internal(false, true)
		process_count += RunState.last_day_results.get("life_development_results", []).size()
		if _lead_by_id(lead_id).get("resolved", false):
			break
	if process_count <= 0:
		_fail("Expected Advance Day to process the due property lead.")
		return false
	var resolved_lead: Dictionary = _lead_by_id(lead_id)
	if str(resolved_lead.get("outcome", "")) != "confirmed" or not bool(resolved_lead.get("public_confirmed", false)):
		_fail("Expected forced lead to resolve as public confirmed.")
		return false
	var appreciated_property: Dictionary = _property_by_id(property_id)
	if float(appreciated_property.get("current_value", 0.0)) <= purchase_price or appreciated_property.get("value_events", []).size() != 1:
		_fail("Expected pre-confirmation property to receive one appreciation event.")
		return false
	var saved_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(saved_state)
	var reloaded_property: Dictionary = _property_by_id(property_id)
	if float(reloaded_property.get("current_value", 0.0)) <= purchase_price or reloaded_property.get("value_events", []).size() != 1:
		_fail("Expected confirmed uplift to survive save/load.")
		return false

	var post_purchase: Dictionary = GameManager.purchase_life_property("kost_room", "bekasi", false)
	if not bool(post_purchase.get("success", false)):
		_fail("Expected post-confirmation property purchase to succeed.")
		return false
	var post_property: Dictionary = post_purchase.get("property", {})
	if (
		float(post_property.get("purchase_price", 0.0)) <= float(post_property.get("base_value", 0.0))
		or not post_property.get("value_events", []).is_empty()
		or not post_property.get("priced_in_lead_ids", []).has(lead_id)
	):
		_fail("Expected post-confirmation purchase to include public uplift in price without a free value event.")
		return false

	var current_value: float = float(reloaded_property.get("current_value", 0.0))
	var sale_result: Dictionary = GameManager.sell_life_property(property_id)
	if not bool(sale_result.get("success", false)):
		_fail("Expected sale of appreciated property to succeed.")
		return false
	var proceeds: float = float(sale_result.get("proceeds", 0.0))
	if absf(proceeds - current_value * 0.95) > 0.01:
		_fail("Expected sale proceeds to use current value with 95 percent haircut.")
		return false
	return true


func _assert_cancelled_and_delayed_leads() -> bool:
	var cancelled_result: Dictionary = GameManager.debug_force_life_development_lead("bandung", "toll_exit", "major", "network", "cancelled")
	if not bool(cancelled_result.get("success", false)):
		_fail("Expected cancelled development lead fixture.")
		return false
	var cancelled_lead_id: String = str(cancelled_result.get("lead", {}).get("id", ""))
	var cancelled_purchase: Dictionary = GameManager.purchase_life_property("kontrakan", "bandung", false)
	if not bool(cancelled_purchase.get("success", false)):
		_fail("Expected Bandung property purchase to succeed.")
		return false
	var cancelled_property_id: String = str(cancelled_purchase.get("property", {}).get("id", ""))
	var cancelled_price: float = float(cancelled_purchase.get("property", {}).get("purchase_price", 0.0))
	for _day in range(9):
		GameManager._advance_day_internal(false, true)
		if bool(_lead_by_id(cancelled_lead_id).get("resolved", false)):
			break
	var cancelled_lead: Dictionary = _lead_by_id(cancelled_lead_id)
	var cancelled_property: Dictionary = _property_by_id(cancelled_property_id)
	if str(cancelled_lead.get("outcome", "")) != "cancelled" or absf(float(cancelled_property.get("current_value", 0.0)) - cancelled_price) > 0.01:
		_fail("Expected cancelled lead to add no property value.")
		return false

	var delayed_result: Dictionary = GameManager.debug_force_life_development_lead("surabaya", "port_logistics", "major", "news", "delayed")
	if not bool(delayed_result.get("success", false)):
		_fail("Expected delayed development lead fixture.")
		return false
	var delayed_lead_id: String = str(delayed_result.get("lead", {}).get("id", ""))
	var delayed_due_before: int = int(delayed_result.get("lead", {}).get("due_day_index", 0))
	var delayed_purchase: Dictionary = GameManager.purchase_life_property("kost_room", "surabaya", false)
	if not bool(delayed_purchase.get("success", false)):
		_fail("Expected Surabaya property purchase to succeed.")
		return false
	var delayed_property_id: String = str(delayed_purchase.get("property", {}).get("id", ""))
	for _day in range(12):
		GameManager._advance_day_internal(false, true)
		var lead: Dictionary = _lead_by_id(delayed_lead_id)
		if str(lead.get("stage", "")) == "delayed":
			break
	var delayed_lead: Dictionary = _lead_by_id(delayed_lead_id)
	var delayed_property: Dictionary = _property_by_id(delayed_property_id)
	if (
		str(delayed_lead.get("stage", "")) != "delayed"
		or int(delayed_lead.get("due_day_index", 0)) <= delayed_due_before
		or not delayed_property.get("value_events", []).is_empty()
	):
		_fail("Expected delayed lead to extend timing without duplicate value events.")
		return false

	var monthly_before: Dictionary = GameManager.get_life_snapshot()
	if float(monthly_before.get("monthly_outflow", 0.0)) <= 0.0:
		_fail("Expected Life monthly outflow to remain active after development leads.")
		return false
	return true


func _reset_cash() -> void:
	RunState.player_portfolio["cash"] = TEST_CASH
	RunState.refresh_cash_stress_state()
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0


func _first_company_in_sector(sector_id: String) -> String:
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = RunState.company_definitions.get(company_id, {})
		if str(definition.get("sector_id", "")) == sector_id:
			return company_id
	return ""


func _lead_count_for_source(source_type: String, source_id: String) -> int:
	var count: int = 0
	for lead_value in RunState.get_player_life().get("development_leads", []):
		if typeof(lead_value) != TYPE_DICTIONARY:
			continue
		var lead: Dictionary = lead_value
		if str(lead.get("source_type", "")) == source_type and str(lead.get("source_id", "")) == source_id:
			count += 1
	return count


func _journal_type_count(rows: Array, row_type: String) -> int:
	var count: int = 0
	for row_value in rows:
		if typeof(row_value) == TYPE_DICTIONARY and str(row_value.get("type", "")) == row_type:
			count += 1
	return count


func _property_article_credibility_error(article: Dictionary) -> String:
	var visible_text: String = "%s\n%s\n%s\n%s\n%s\n%s" % [
		str(article.get("headline", "")),
		str(article.get("deck", "")),
		str(article.get("body", "")),
		str(article.get("public_status_label", "")),
		str(article.get("public_confidence_label", "")),
		str(article.get("public_continuity_phrase", ""))
	]
	var searchable_text: String = visible_text.to_lower()
	for forbidden_value in [
		"vague public hint",
		"source reliability",
		"current read",
		"unclear location",
		"development lead",
		"intel level",
		"source trail",
		"source article",
		"source story",
		"separate property angle",
		"market story",
		"original headline",
		"working read",
		"reliability",
		"bodetabek",
		"jabodetabek",
		"roadmap_id",
		"funding_gate",
		"funding readiness",
		"company_roadmap",
		"participant_role",
		"milestone_state",
		"raw statement",
		"system metadata",
		"stage of a",
		"price-bias read"
	]:
		var forbidden_term: String = str(forbidden_value)
		if searchable_text.find(forbidden_term) >= 0:
			return "Expected property article copy to avoid raw/system wording like %s." % forbidden_term
	return ""


func _lead_by_id(lead_id: String) -> Dictionary:
	for lead_value in RunState.get_player_life().get("development_leads", []):
		if typeof(lead_value) != TYPE_DICTIONARY:
			continue
		var lead: Dictionary = lead_value
		if str(lead.get("id", "")) == lead_id:
			return lead
	return {}


func _property_by_id(property_id: String) -> Dictionary:
	for property_value in RunState.get_player_life().get("properties", []):
		if typeof(property_value) != TYPE_DICTIONARY:
			continue
		var property_row: Dictionary = property_value
		if str(property_row.get("id", "")) == property_id:
			return property_row
	return {}


func _fail(message: String) -> void:
	push_error(message)
	print("LIFE_DEVELOPMENT_INTEL_TEST_FAIL: %s" % message)
	get_tree().quit(1)
