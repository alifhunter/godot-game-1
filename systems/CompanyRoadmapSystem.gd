extends RefCounted

const STABLE_RNG = preload("res://systems/StableRng.gd")

const LEGACY_LOCATION_REDIRECTS := {
	"bodetabek": ["bogor", "depok", "tangerang", "bekasi", "karawang"],
	"jabodetabek": ["jakarta", "bogor", "depok", "tangerang", "bekasi", "karawang"]
}
const DEFAULT_LOCATION_ID := "jakarta"
const DEFAULT_ROADMAP_FAMILY_ID := "channel_rollout"
const SOURCE_SYSTEM_ID := "company_roadmap"
const START_DAY := 7
const ACTIVE_CAP_BY_DIFFICULTY := {
	"chill": 1,
	"normal": 2,
	"grind": 3
}
const FIRST_MONTH_NORMAL_CAP := 1
const FIRST_MONTH_CAP_UNTIL_DAY := 22
const FUNDING_SCALE_RATIO := {
	"low": 0.035,
	"moderate": 0.075,
	"high": 0.16,
	"transformational": 0.32
}
const MILESTONE_DURATION_BY_SCALE := {
	"low": 3,
	"moderate": 4,
	"high": 5,
	"transformational": 6
}


func build_location_profile(template: Dictionary, sector_definition: Dictionary, traits: Dictionary, financials: Dictionary, run_seed: int) -> Dictionary:
	var company_id: String = str(template.get("id", "company"))
	var sector_id: String = str(sector_definition.get("id", template.get("sector_id", "")))
	var catalog: Dictionary = DataRepository.get_company_roadmap_catalog_ref()
	var locations: Array = catalog.get("locations", [])
	if locations.is_empty():
		return {
			"hq_location_id": DEFAULT_LOCATION_ID,
			"hq_location_label": "Jakarta",
			"operating_city_ids": [DEFAULT_LOCATION_ID],
			"operating_city_labels": ["Jakarta"],
			"public_footprint": "Based in Jakarta, with a focused Indonesian operating footprint."
		}

	var target_tags: Array = catalog.get("sector_location_tags", {}).get(sector_id, ["consumer"])
	var scored_locations: Array = []
	for location_value in locations:
		if typeof(location_value) != TYPE_DICTIONARY:
			continue
		var location: Dictionary = location_value
		var score: float = 1.0
		var location_tags: Array = location.get("tags", [])
		for tag_value in target_tags:
			if location_tags.has(str(tag_value)):
				score += 2.0
		score += float(location.get("market_factor", 1.0)) * 0.8
		score += float(traits.get("scale", 0.5)) * (0.8 if location_tags.has("hq") else 0.25)
		score += float(STABLE_RNG.seed_from_parts([run_seed, "location_noise", company_id, str(location.get("id", ""))]) % 1000) / 1000.0
		scored_locations.append({"location": location, "score": score})
	scored_locations.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)

	var hq: Dictionary = scored_locations[0].get("location", {}).duplicate(true)
	var operating_ids: Array = [str(hq.get("id", DEFAULT_LOCATION_ID))]
	var operating_labels: Array = [str(hq.get("label", "Jakarta"))]
	var desired_city_count: int = 1
	var scale: float = float(traits.get("scale", 0.5))
	if scale >= 0.68 or float(financials.get("market_cap", 0.0)) >= 3000000000000.0:
		desired_city_count = 3
	elif scale >= 0.42:
		desired_city_count = 2
	for scored_value in scored_locations:
		if operating_ids.size() >= desired_city_count:
			break
		var location: Dictionary = scored_value.get("location", {})
		var location_id: String = str(location.get("id", ""))
		if location_id.is_empty() or operating_ids.has(location_id):
			continue
		operating_ids.append(location_id)
		operating_labels.append(str(location.get("label", location_id.capitalize())))

	return {
		"hq_location_id": str(hq.get("id", DEFAULT_LOCATION_ID)),
		"hq_location_label": str(hq.get("label", "Jakarta")),
		"operating_city_ids": operating_ids,
		"operating_city_labels": operating_labels,
		"public_footprint": _build_public_footprint(str(hq.get("label", "Jakarta")), operating_labels)
	}


func build_roadmap_profile(template: Dictionary, sector_definition: Dictionary, traits: Dictionary, financials: Dictionary, location_profile: Dictionary, run_seed: int) -> Dictionary:
	var company_id: String = str(template.get("id", "company"))
	var sector_id: String = str(sector_definition.get("id", template.get("sector_id", "")))
	var families: Array = _roadmap_families_for_sector(sector_id)
	if families.is_empty():
		families = _roadmap_families_for_sector("consumer")
	if families.is_empty():
		return {
			"primary_family_id": DEFAULT_ROADMAP_FAMILY_ID,
			"primary_family_label": "Channel rollout",
			"public_priority": "Channel rollout",
			"milestone_family_ids": [DEFAULT_ROADMAP_FAMILY_ID],
			"milestone_family_labels": ["Channel rollout"],
			"funding_scale": "moderate",
			"physical_project": false,
			"property_development_location_id": "",
			"property_development_theme": "",
			"roadmap_seed": int(STABLE_RNG.seed_from_parts([run_seed, "roadmap", company_id]))
		}

	var location_tags: Array = _location_tags(str(location_profile.get("hq_location_id", DEFAULT_LOCATION_ID)))
	var scored_families: Array = []
	for family_value in families:
		if typeof(family_value) != TYPE_DICTIONARY:
			continue
		var family: Dictionary = family_value
		var score: float = 1.0
		for tag_value in family.get("location_tags", []):
			if location_tags.has(str(tag_value)):
				score += 1.6
		score += float(family.get("positive_bias", 0.1)) * 4.0
		score += float(traits.get("growth", 0.5)) * 0.5
		score += float(STABLE_RNG.seed_from_parts([run_seed, "roadmap_family_noise", company_id, str(family.get("id", ""))]) % 1000) / 1000.0
		scored_families.append({"family": family, "score": score})
	scored_families.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)

	var milestone_ids: Array = []
	var milestone_labels: Array = []
	for scored_value in scored_families:
		if milestone_ids.size() >= 3:
			break
		var family: Dictionary = scored_value.get("family", {})
		var family_id: String = str(family.get("id", ""))
		if family_id.is_empty() or milestone_ids.has(family_id):
			continue
		milestone_ids.append(family_id)
		milestone_labels.append(str(family.get("label", family_id.capitalize())))

	var primary_family: Dictionary = scored_families[0].get("family", {}).duplicate(true)
	var physical: bool = bool(primary_family.get("physical", false))
	return {
		"primary_family_id": str(primary_family.get("id", DEFAULT_ROADMAP_FAMILY_ID)),
		"primary_family_label": str(primary_family.get("label", "Roadmap project")),
		"public_priority": str(primary_family.get("priority_label", primary_family.get("label", "Roadmap project"))),
		"public_priority_detail": _build_public_priority_detail(primary_family, location_profile),
		"milestone_family_ids": milestone_ids,
		"milestone_family_labels": milestone_labels,
		"funding_scale": str(primary_family.get("funding_scale", "moderate")),
		"physical_project": physical,
		"property_development_location_id": str(location_profile.get("hq_location_id", DEFAULT_LOCATION_ID)) if physical else "",
		"property_development_theme": str(primary_family.get("property_theme", "")) if physical else "",
		"roadmap_seed": int(STABLE_RNG.seed_from_parts([run_seed, "roadmap", company_id]))
	}


func ensure_company_life_profile(company_profile: Dictionary, template: Dictionary, sector_definition: Dictionary, run_seed: int) -> Dictionary:
	var normalized: Dictionary = company_profile.duplicate(true)
	var traits: Dictionary = normalized.get("generation_traits", {}).duplicate(true)
	var financials: Dictionary = normalized.get("financials", {}).duplicate(true)
	var location_profile: Dictionary = normalize_location_profile(normalized.get("location_profile", {}))
	if location_profile.is_empty():
		location_profile = build_location_profile(template, sector_definition, traits, financials, run_seed)
	normalized["location_profile"] = location_profile
	var roadmap_profile: Dictionary = normalize_roadmap_profile(normalized.get("roadmap_profile", {}), location_profile)
	if roadmap_profile.is_empty():
		roadmap_profile = build_roadmap_profile(template, sector_definition, traits, financials, location_profile, run_seed)
	normalized["roadmap_profile"] = roadmap_profile
	return normalized


func normalize_location_profile(source_value: Variant) -> Dictionary:
	if typeof(source_value) != TYPE_DICTIONARY:
		return {}
	var source: Dictionary = source_value
	var hq_id: String = normalize_location_id(str(source.get("hq_location_id", source.get("location_id", ""))), "profile")
	if hq_id.is_empty():
		return {}
	var hq_label: String = _location_label(hq_id)
	var operating_ids: Array = []
	for city_value in source.get("operating_city_ids", []):
		var city_id: String = normalize_location_id(str(city_value), "profile")
		if city_id.is_empty() or operating_ids.has(city_id):
			continue
		operating_ids.append(city_id)
	if operating_ids.is_empty():
		operating_ids.append(hq_id)
	var operating_labels: Array = []
	for city_id_value in operating_ids:
		operating_labels.append(_location_label(str(city_id_value)))
	return {
		"hq_location_id": hq_id,
		"hq_location_label": hq_label,
		"operating_city_ids": operating_ids,
		"operating_city_labels": operating_labels,
		"public_footprint": str(source.get("public_footprint", _build_public_footprint(hq_label, operating_labels)))
	}


func normalize_roadmap_profile(source_value: Variant, location_profile: Dictionary = {}) -> Dictionary:
	if typeof(source_value) != TYPE_DICTIONARY:
		return {}
	var source: Dictionary = source_value
	var primary_family_id: String = str(source.get("primary_family_id", "")).strip_edges()
	if primary_family_id.is_empty():
		return {}
	var milestone_ids: Array = []
	for family_id_value in source.get("milestone_family_ids", []):
		var family_id: String = str(family_id_value).strip_edges()
		if family_id.is_empty() or milestone_ids.has(family_id):
			continue
		milestone_ids.append(family_id)
	if milestone_ids.is_empty():
		milestone_ids.append(primary_family_id)
	var milestone_labels: Array = []
	for label_value in source.get("milestone_family_labels", []):
		var label: String = str(label_value).strip_edges()
		if not label.is_empty():
			milestone_labels.append(label)
	var property_location_id: String = normalize_location_id(str(source.get("property_development_location_id", "")), "roadmap")
	if property_location_id.is_empty() and bool(source.get("physical_project", false)):
		property_location_id = str(location_profile.get("hq_location_id", ""))
	return {
		"primary_family_id": primary_family_id,
		"primary_family_label": str(source.get("primary_family_label", primary_family_id.replace("_", " ").capitalize())),
		"public_priority": str(source.get("public_priority", source.get("primary_family_label", primary_family_id.replace("_", " ").capitalize()))),
		"public_priority_detail": str(source.get("public_priority_detail", "")),
		"milestone_family_ids": milestone_ids,
		"milestone_family_labels": milestone_labels,
		"funding_scale": str(source.get("funding_scale", "moderate")),
		"physical_project": bool(source.get("physical_project", false)),
		"property_development_location_id": property_location_id,
		"property_development_theme": str(source.get("property_development_theme", "")),
		"roadmap_seed": int(source.get("roadmap_seed", 0))
	}


func normalize_location_id(location_id: String, seed_key: String = "") -> String:
	var normalized_id: String = location_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return ""
	if LEGACY_LOCATION_REDIRECTS.has(normalized_id):
		var redirects: Array = LEGACY_LOCATION_REDIRECTS.get(normalized_id, [])
		if redirects.is_empty():
			return DEFAULT_LOCATION_ID
		var index: int = int(STABLE_RNG.seed_from_parts(["legacy_location", seed_key, normalized_id]) % redirects.size())
		return str(redirects[index])
	return normalized_id


func normalize_state(source_value: Variant) -> Dictionary:
	var normalized: Dictionary = {
		"active_milestones": {},
		"resolved_milestones": {},
		"company_cooldowns": {},
		"last_spawn_day_index": -999
	}
	if typeof(source_value) != TYPE_DICTIONARY:
		return normalized
	var source: Dictionary = source_value
	for milestone_id_value in source.get("active_milestones", {}).keys():
		var milestone: Dictionary = _normalize_milestone(source.get("active_milestones", {}).get(milestone_id_value, {}))
		if not milestone.is_empty():
			normalized["active_milestones"][str(milestone.get("id", milestone_id_value))] = milestone
	for milestone_id_value in source.get("resolved_milestones", {}).keys():
		var milestone: Dictionary = _normalize_milestone(source.get("resolved_milestones", {}).get(milestone_id_value, {}))
		if not milestone.is_empty():
			normalized["resolved_milestones"][str(milestone.get("id", milestone_id_value))] = milestone
	for company_id_value in source.get("company_cooldowns", {}).keys():
		var company_id: String = str(company_id_value)
		if company_id.is_empty():
			continue
		normalized["company_cooldowns"][company_id] = int(source.get("company_cooldowns", {}).get(company_id_value, 0))
	normalized["last_spawn_day_index"] = int(source.get("last_spawn_day_index", -999))
	return normalized


func resolve_day(run_state, data_repository, corporate_action_system, trade_date: Dictionary, day_number: int, macro_state: Dictionary, corporate_action_resolution: Dictionary = {}) -> Dictionary:
	var state: Dictionary = normalize_state(run_state.get_company_roadmap_state())
	var active_milestones: Dictionary = state.get("active_milestones", {}).duplicate(true)
	var resolved_milestones: Dictionary = state.get("resolved_milestones", {}).duplicate(true)
	for milestone_id_value in active_milestones.keys():
		var milestone: Dictionary = active_milestones.get(milestone_id_value, {})
		if int(milestone.get("end_day_index", day_number)) >= day_number:
			continue
		milestone["resolved_day_index"] = day_number
		resolved_milestones[str(milestone_id_value)] = milestone
		active_milestones.erase(milestone_id_value)

	var chains: Dictionary = corporate_action_resolution.get("active_corporate_action_chains", run_state.get_active_corporate_action_chains()).duplicate(true)
	var calendar: Dictionary = corporate_action_resolution.get("corporate_meeting_calendar", run_state.get_corporate_meeting_calendar()).duplicate(true)
	var events: Array = []
	var corporate_events: Array = []
	var active_arcs: Array = []
	for milestone_value in active_milestones.values():
		var milestone: Dictionary = milestone_value
		active_arcs.append_array(_build_arcs_for_milestone(run_state, milestone, trade_date, day_number))

	if _should_spawn_milestone(run_state, day_number, active_milestones):
		var candidate: Dictionary = _pick_spawn_candidate(run_state, day_number, macro_state, active_milestones, chains)
		if not candidate.is_empty():
			var build_result: Dictionary = _build_milestone_from_candidate(
				run_state,
				data_repository,
				corporate_action_system,
				candidate,
				trade_date,
				day_number,
				chains,
				calendar
			)
			var milestone: Dictionary = build_result.get("milestone", {})
			if not milestone.is_empty():
				active_milestones[str(milestone.get("id", ""))] = milestone
				state["last_spawn_day_index"] = day_number
				var cooldowns: Dictionary = state.get("company_cooldowns", {}).duplicate(true)
				cooldowns[str(milestone.get("company_id", ""))] = day_number + 24
				state["company_cooldowns"] = cooldowns
				events.append(_build_event_for_milestone(run_state, milestone, trade_date, day_number))
				active_arcs.append_array(_build_arcs_for_milestone(run_state, milestone, trade_date, day_number))
			chains = build_result.get("active_corporate_action_chains", chains).duplicate(true)
			calendar = build_result.get("corporate_meeting_calendar", calendar).duplicate(true)
			corporate_events.append_array(build_result.get("corporate_action_events", []))

	state["active_milestones"] = active_milestones
	state["resolved_milestones"] = resolved_milestones
	return {
		"company_roadmap_state": state,
		"active_company_arcs": active_arcs,
		"started_events": events,
		"corporate_action_events": corporate_events,
		"active_corporate_action_chains": chains,
		"corporate_meeting_calendar": calendar,
		"blocked_company_ids": _blocked_company_ids_from_milestones(active_milestones)
	}


func debug_evaluate_funding(run_state, company_id: String, family: Dictionary, excluded_company_ids: Array = []) -> Dictionary:
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, true, true)
	var runtime: Dictionary = run_state.get_company(company_id)
	if definition.is_empty() or runtime.is_empty():
		return {"outcome": "cancelled", "reason": "missing_company"}
	return _evaluate_funding(run_state, definition, runtime, family, {}, excluded_company_ids, -1)


func debug_select_finance_partner(run_state, company_id: String, excluded_company_ids: Array = []) -> Dictionary:
	var partner_id: String = _select_finance_partner(run_state, company_id, {}, excluded_company_ids, -1)
	if partner_id.is_empty():
		return {}
	return run_state.get_effective_company_definition(partner_id, false, false)


func debug_force_milestone(run_state, data_repository, corporate_action_system, company_id: String, generator_id: String, trade_date: Dictionary, day_number: int) -> Dictionary:
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, true, true)
	if definition.is_empty():
		return {"success": false, "message": "Pick a valid stock first."}
	var sector_id: String = str(definition.get("sector_id", ""))
	var roadmap_profile: Dictionary = definition.get("roadmap_profile", {})
	var family: Dictionary = _debug_family_for_generator(sector_id, roadmap_profile, generator_id)
	if family.is_empty():
		return {"success": false, "message": "No compatible roadmap family is available for that stock."}
	var state: Dictionary = normalize_state(run_state.get_company_roadmap_state())
	var active_milestones: Dictionary = state.get("active_milestones", {}).duplicate(true)
	for milestone_value in active_milestones.values():
		if typeof(milestone_value) != TYPE_DICTIONARY:
			continue
		var active_milestone: Dictionary = milestone_value
		if str(active_milestone.get("company_id", "")) == company_id or str(active_milestone.get("finance_company_id", "")) == company_id:
			return {"success": false, "message": "%s already has an active roadmap milestone." % str(definition.get("ticker", company_id.to_upper()))}
	var chains: Dictionary = run_state.get_active_corporate_action_chains()
	var calendar: Dictionary = run_state.get_corporate_meeting_calendar()
	var build_result: Dictionary = _build_milestone_from_candidate(
		run_state,
		data_repository,
		corporate_action_system,
		{
			"company_id": company_id,
			"family": family
		},
		trade_date,
		day_number,
		chains,
		calendar
	)
	var milestone: Dictionary = build_result.get("milestone", {})
	if milestone.is_empty():
		return {"success": false, "message": "Could not build a roadmap milestone for that stock."}
	active_milestones[str(milestone.get("id", ""))] = milestone
	state["active_milestones"] = active_milestones
	state["last_spawn_day_index"] = day_number
	var cooldowns: Dictionary = state.get("company_cooldowns", {}).duplicate(true)
	cooldowns[company_id] = day_number + 24
	state["company_cooldowns"] = cooldowns
	var started_event: Dictionary = _build_event_for_milestone(run_state, milestone, trade_date, day_number)
	return {
		"success": true,
		"company_roadmap_state": state,
		"milestone": milestone,
		"started_event": started_event,
		"active_company_arcs": _build_arcs_for_milestone(run_state, milestone, trade_date, day_number),
		"corporate_action_events": build_result.get("corporate_action_events", []).duplicate(true),
		"active_corporate_action_chains": build_result.get("active_corporate_action_chains", chains).duplicate(true),
		"corporate_meeting_calendar": build_result.get("corporate_meeting_calendar", calendar).duplicate(true)
	}


func roadmap_family_for_profile(roadmap_profile: Dictionary, sector_id: String) -> Dictionary:
	var family_id: String = str(roadmap_profile.get("primary_family_id", ""))
	return _roadmap_family_by_id(sector_id, family_id)


func _build_public_footprint(hq_label: String, operating_labels: Array) -> String:
	if operating_labels.size() <= 1:
		return "Based in %s, with a focused Indonesian operating footprint." % hq_label
	var secondary_labels: Array = []
	for label_value in operating_labels:
		var label: String = str(label_value)
		if label == hq_label:
			continue
		secondary_labels.append(label)
	return "Based in %s, with operations around %s." % [hq_label, ", ".join(secondary_labels)]


func _build_public_priority_detail(family: Dictionary, location_profile: Dictionary) -> String:
	var location_label: String = str(location_profile.get("hq_location_label", "Jakarta"))
	var project_label: String = str(family.get("project_label", family.get("label", "project")))
	if bool(family.get("physical", false)):
		return "a %s around %s" % [project_label, location_label]
	return "%s across its Indonesian operating base" % project_label


func _should_spawn_milestone(run_state, day_number: int, active_milestones: Dictionary) -> bool:
	if day_number < START_DAY:
		return false
	var difficulty_config: Dictionary = run_state.get_difficulty_config()
	var difficulty_id: String = str(difficulty_config.get("id", "normal"))
	var cap: int = int(ACTIVE_CAP_BY_DIFFICULTY.get(difficulty_id, ACTIVE_CAP_BY_DIFFICULTY["normal"]))
	if difficulty_id == "normal" and day_number <= FIRST_MONTH_CAP_UNTIL_DAY:
		cap = min(cap, FIRST_MONTH_NORMAL_CAP)
	if active_milestones.size() >= cap:
		return false
	var event_interval_days: float = max(float(difficulty_config.get("event_interval_days", 10.0)), 1.0)
	var cadence: int = int(clamp(round(event_interval_days * 1.25), 8, 24))
	var cadence_offset: int = int(STABLE_RNG.seed_from_parts([run_state.run_seed, "roadmap_cadence_offset"]) % cadence)
	if int(posmod(day_number + cadence_offset, cadence)) == 0:
		return true
	var rng: RandomNumberGenerator = STABLE_RNG.rng([run_state.run_seed, "roadmap_spawn_roll", day_number])
	return rng.randf() < clamp(1.0 / max(event_interval_days * 3.2, 24.0), 0.0, 0.18)


func _pick_spawn_candidate(run_state, day_number: int, macro_state: Dictionary, active_milestones: Dictionary, chains: Dictionary) -> Dictionary:
	var blocked_company_ids: Array = _blocked_company_ids_from_milestones(active_milestones)
	var cooldowns: Dictionary = normalize_state(run_state.get_company_roadmap_state()).get("company_cooldowns", {})
	var candidates: Array = []
	for company_id_value in run_state.company_order:
		var company_id: String = str(company_id_value)
		if company_id.is_empty() or blocked_company_ids.has(company_id):
			continue
		if int(cooldowns.get(company_id, -999)) > day_number:
			continue
		if run_state.has_method("is_company_living_arc_available") and not run_state.is_company_living_arc_available(company_id, SOURCE_SYSTEM_ID, "roadmap", day_number):
			continue
		if _company_has_live_chain(chains, company_id):
			continue
		var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
		var runtime: Dictionary = run_state.get_company(company_id)
		if definition.is_empty() or runtime.is_empty():
			continue
		var roadmap_profile: Dictionary = definition.get("roadmap_profile", {})
		var sector_id: String = str(definition.get("sector_id", ""))
		var family: Dictionary = roadmap_family_for_profile(roadmap_profile, sector_id)
		if family.is_empty():
			continue
		var traits: Dictionary = runtime.get("company_profile", {}).get("generation_traits", {})
		var score: float = float(traits.get("story_heat", 0.5)) * 0.42 + float(traits.get("growth", 0.5)) * 0.18
		score += float(definition.get("growth_score", 50.0)) / 100.0 * 0.18
		score += float(family.get("positive_bias", 0.1))
		score += float(macro_state.get("risk_appetite", 0.5)) * 0.08
		score += _living_roadmap_score_adjustment(run_state, company_id, family, macro_state)
		score += float(STABLE_RNG.seed_from_parts([run_state.run_seed, "roadmap_candidate", day_number, company_id]) % 1000) / 10000.0
		candidates.append({"company_id": company_id, "family": family, "score": score})
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	return candidates[0].duplicate(true)


func _living_roadmap_score_adjustment(run_state, company_id: String, family: Dictionary, macro_state: Dictionary) -> float:
	if not run_state.has_method("get_company_living_arc_state"):
		return 0.0
	var living_state: Dictionary = run_state.get_company_living_arc_state(company_id)
	var tags: Array = living_state.get("eligibility_tags", [])
	var adjustment: float = 0.0
	if tags.has("high_story_heat"):
		adjustment += 0.035
	if tags.has("growth_story_candidate"):
		adjustment += 0.035
	if tags.has("funding_need") and str(family.get("funding_scale", "")) in ["high", "transformational"]:
		adjustment += 0.040
	if tags.has("roadmap_physical_project") and bool(family.get("physical", false)):
		adjustment += 0.035
	if tags.has("strong_balance_sheet") and str(family.get("funding_scale", "")) in ["high", "transformational"]:
		adjustment += 0.020
	if tags.has("weak_balance_sheet") and str(family.get("funding_scale", "")) in ["high", "transformational"]:
		adjustment -= 0.040
	if tags.has("recent:company_roadmap") or tags.has("recent:roadmap"):
		adjustment -= 0.080
	if _tags_overlap_commodity(tags, macro_state.get("commodity_leaders", [])):
		adjustment += 0.025
	if _tags_overlap_commodity(tags, macro_state.get("commodity_laggards", [])):
		adjustment -= 0.015
	return adjustment


func _tags_overlap_commodity(tags: Array, commodity_ids: Variant) -> bool:
	if typeof(commodity_ids) != TYPE_ARRAY:
		return false
	for commodity_id_value in commodity_ids:
		var commodity_id: String = str(commodity_id_value).strip_edges().to_lower()
		if commodity_id.is_empty():
			continue
		if tags.has("commodity:%s" % commodity_id) or tags.has("commodity_positive:%s" % commodity_id) or tags.has("commodity_negative:%s" % commodity_id):
			return true
	return false


func _build_milestone_from_candidate(run_state, data_repository, corporate_action_system, candidate: Dictionary, trade_date: Dictionary, day_number: int, chains: Dictionary, calendar: Dictionary) -> Dictionary:
	var company_id: String = str(candidate.get("company_id", ""))
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, true, true)
	var runtime: Dictionary = run_state.get_company(company_id)
	var family: Dictionary = candidate.get("family", {}).duplicate(true)
	if definition.is_empty() or runtime.is_empty() or family.is_empty():
		return {}
	var funding: Dictionary = _evaluate_funding(run_state, definition, runtime, family, chains, [], day_number)
	var outcome: String = str(funding.get("outcome", "self_funded"))
	var corporate_action_events: Array = []
	var chain_id: String = ""
	if outcome == "needs_corporate_action":
		var family_id: String = _corporate_action_family_for_funding(family)
		var schedule_result: Dictionary = corporate_action_system.schedule_roadmap_chain(
			run_state,
			data_repository,
			company_id,
			family_id,
			day_number,
			trade_date,
			{
				"roadmap_family_label": str(family.get("label", "")),
				"project_label": str(family.get("project_label", family.get("label", "")))
			},
			chains,
			calendar
		)
		if bool(schedule_result.get("success", false)):
			chains = schedule_result.get("active_corporate_action_chains", chains).duplicate(true)
			calendar = schedule_result.get("corporate_meeting_calendar", calendar).duplicate(true)
			corporate_action_events.append_array(schedule_result.get("events", []))
			chain_id = str(schedule_result.get("chain", {}).get("chain_id", ""))
		else:
			outcome = "delayed"

	var location_profile: Dictionary = definition.get("location_profile", {})
	var roadmap_profile: Dictionary = definition.get("roadmap_profile", {})
	var physical: bool = bool(family.get("physical", roadmap_profile.get("physical_project", false)))
	var location_id: String = str(roadmap_profile.get("property_development_location_id", location_profile.get("hq_location_id", DEFAULT_LOCATION_ID))) if physical else ""
	location_id = normalize_location_id(location_id, "%s|%s" % [company_id, str(family.get("id", ""))])
	var location_label: String = _location_label(location_id)
	var funding_outcome: String = outcome
	var duration_days: int = int(MILESTONE_DURATION_BY_SCALE.get(str(family.get("funding_scale", "moderate")), 4))
	var milestone_id: String = "roadmap|%s|%s|%d" % [company_id, str(family.get("id", "project")), day_number]
	var tone: String = _tone_for_funding_outcome(funding_outcome)
	var milestone: Dictionary = {
		"id": milestone_id,
		"company_id": company_id,
		"ticker": str(definition.get("ticker", company_id.to_upper())),
		"company_name": str(definition.get("name", company_id.to_upper())),
		"sector_id": str(definition.get("sector_id", "")),
		"family_id": str(family.get("id", "")),
		"family_label": str(family.get("label", "Roadmap project")),
		"priority_label": str(family.get("priority_label", family.get("label", "Roadmap project"))),
		"project_label": str(family.get("project_label", family.get("label", "project"))),
		"funding_scale": str(family.get("funding_scale", "moderate")),
		"funding_outcome": funding_outcome,
		"finance_company_id": str(funding.get("finance_company_id", "")),
		"finance_company_name": str(funding.get("finance_company_name", "")),
		"finance_ticker": str(funding.get("finance_ticker", "")),
		"corporate_chain_id": chain_id,
		"physical_project": physical,
		"location_id": location_id,
		"location_label": location_label,
		"property_theme": str(family.get("property_theme", "")) if physical else "",
		"project_cost": float(funding.get("project_cost", 0.0)),
		"funding_capacity": float(funding.get("funding_capacity", 0.0)),
		"start_day_index": day_number,
		"end_day_index": day_number + duration_days - 1,
		"duration_days": duration_days,
		"tone": tone,
		"sentiment_shift": _sentiment_for_milestone(family, funding_outcome),
		"volatility_multiplier": _volatility_for_milestone(funding_outcome),
		"headline": _milestone_headline(definition, family, funding_outcome, location_label),
		"summary": _milestone_summary(definition, family, funding_outcome, location_label, funding)
	}
	return {
		"milestone": milestone,
		"active_corporate_action_chains": chains,
		"corporate_meeting_calendar": calendar,
		"corporate_action_events": corporate_action_events
	}


func _evaluate_funding(run_state, definition: Dictionary, runtime: Dictionary, family: Dictionary, chains: Dictionary = {}, excluded_company_ids: Array = [], day_number: int = -1) -> Dictionary:
	var financials: Dictionary = definition.get("financials", {})
	var profile: Dictionary = runtime.get("company_profile", {})
	var traits: Dictionary = profile.get("generation_traits", {})
	var project_cost: float = _estimate_project_cost(financials, family)
	var funding_capacity: float = _estimate_funding_capacity(definition, traits)
	var debt_to_equity: float = max(float(financials.get("debt_to_equity", 0.0)), 0.0)
	var routes: Array = family.get("funding_routes", ["self", "loan"])
	if routes.has("self") and funding_capacity >= project_cost:
		return {
			"outcome": "self_funded",
			"project_cost": project_cost,
			"funding_capacity": funding_capacity
		}
	if routes.has("loan") and debt_to_equity <= 1.55:
		var partner_id: String = _select_finance_partner(run_state, str(definition.get("id", "")), chains, excluded_company_ids, day_number)
		if not partner_id.is_empty():
			var partner_definition: Dictionary = run_state.get_effective_company_definition(partner_id, false, false)
			return {
				"outcome": "needs_financing",
				"project_cost": project_cost,
				"funding_capacity": funding_capacity,
				"finance_company_id": partner_id,
				"finance_company_name": str(partner_definition.get("name", partner_id.to_upper())),
				"finance_ticker": str(partner_definition.get("ticker", partner_id.to_upper()))
			}
	if (routes.has("rights_issue") or routes.has("private_placement")) and not _company_has_live_chain(chains, str(definition.get("id", ""))):
		return {
			"outcome": "needs_corporate_action",
			"project_cost": project_cost,
			"funding_capacity": funding_capacity
		}
	var delay_roll: int = int(STABLE_RNG.seed_from_parts([str(definition.get("id", "")), str(family.get("id", "")), "delay_or_cancel"]) % 100)
	return {
		"outcome": "delayed" if delay_roll >= 24 else "cancelled",
		"project_cost": project_cost,
		"funding_capacity": funding_capacity
	}


func _estimate_project_cost(financials: Dictionary, family: Dictionary) -> float:
	var market_cap: float = max(float(financials.get("market_cap", 0.0)), 100000000000.0)
	var revenue: float = max(float(financials.get("revenue", 0.0)), market_cap * 0.18)
	var ratio: float = float(FUNDING_SCALE_RATIO.get(str(family.get("funding_scale", "moderate")), FUNDING_SCALE_RATIO["moderate"]))
	return max((market_cap * ratio * 0.55) + (revenue * ratio * 0.45), 10000000000.0)


func _estimate_funding_capacity(definition: Dictionary, traits: Dictionary) -> float:
	var financials: Dictionary = definition.get("financials", {})
	var statement_snapshot: Dictionary = definition.get("financial_statement_snapshot", {})
	var market_cap: float = max(float(financials.get("market_cap", 0.0)), 100000000000.0)
	var revenue: float = max(float(financials.get("revenue", 0.0)), market_cap * 0.18)
	var net_income: float = max(float(financials.get("net_income", 0.0)), 0.0)
	var margin: float = max(float(financials.get("net_profit_margin", 0.0)) / 100.0, 0.0)
	var debt_to_equity: float = max(float(financials.get("debt_to_equity", 0.0)), 0.0)
	var balance_strength: float = clamp(float(traits.get("balance_sheet_strength", 0.5)), 0.0, 1.0)
	var cash_proxy: float = _cash_proxy_from_statement(statement_snapshot)
	if cash_proxy <= 0.0:
		cash_proxy = revenue * clamp(0.035 + margin * 0.7 + balance_strength * 0.08, 0.025, 0.24)
	var borrowing_room: float = market_cap * clamp(0.04 + balance_strength * 0.16 - max(debt_to_equity - 0.7, 0.0) * 0.055, 0.0, 0.18)
	var earnings_capacity: float = net_income * clamp(2.0 + balance_strength * 2.2, 1.0, 4.2)
	return max(cash_proxy + borrowing_room + earnings_capacity, 0.0)


func _cash_proxy_from_statement(statement_snapshot: Dictionary) -> float:
	for row_value in statement_snapshot.get("balance_sheet", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var row_id: String = str(row.get("id", row.get("metric_id", ""))).to_lower()
		if row_id == "cash" or row_id == "cash_and_equivalents" or row_id == "cash_equivalent":
			return max(float(row.get("value", row.get("amount", 0.0))), 0.0)
	return 0.0


func _select_finance_partner(run_state, primary_company_id: String, chains: Dictionary = {}, excluded_company_ids: Array = [], day_number: int = -1) -> String:
	var candidates: Array = []
	var resolved_day_number: int = max(day_number, int(run_state.day_index))
	for company_id_value in run_state.company_order:
		var company_id: String = str(company_id_value)
		if company_id.is_empty() or company_id == primary_company_id or excluded_company_ids.has(company_id):
			continue
		if _company_has_live_chain(chains, company_id):
			continue
		if run_state.has_method("is_company_living_arc_available") and not run_state.is_company_living_arc_available(company_id, SOURCE_SYSTEM_ID, "roadmap_financing_partner", resolved_day_number):
			continue
		var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
		if str(definition.get("sector_id", "")) != "finance":
			continue
		var financials: Dictionary = definition.get("financials", {})
		var score: float = 0.0
		score += float(definition.get("quality_score", 50.0)) / 100.0 * 0.36
		score += clamp(float(financials.get("market_cap", 0.0)) / 4000000000000.0, 0.0, 1.0) * 0.26
		score += clamp(float(financials.get("roe", 0.0)) / 18.0, 0.0, 1.0) * 0.16
		score += clamp(1.5 - float(financials.get("debt_to_equity", 0.0)), 0.0, 1.5) / 1.5 * 0.18
		score += float(STABLE_RNG.seed_from_parts([run_state.run_seed, "finance_partner", primary_company_id, company_id]) % 1000) / 10000.0
		if score >= 0.34:
			candidates.append({"company_id": company_id, "score": score})
	if candidates.is_empty():
		return ""
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	return str(candidates[0].get("company_id", ""))


func _build_arcs_for_milestone(run_state, milestone: Dictionary, trade_date: Dictionary, day_number: int) -> Array:
	var arcs: Array = []
	var primary_arc: Dictionary = _build_arc(run_state, milestone, trade_date, day_number, false)
	if not primary_arc.is_empty():
		arcs.append(primary_arc)
	if not str(milestone.get("finance_company_id", "")).is_empty():
		var finance_arc: Dictionary = _build_arc(run_state, milestone, trade_date, day_number, true)
		if not finance_arc.is_empty():
			arcs.append(finance_arc)
	return arcs


func _build_arc(run_state, milestone: Dictionary, trade_date: Dictionary, day_number: int, finance_side: bool) -> Dictionary:
	var target_company_id: String = str(milestone.get("finance_company_id", "")) if finance_side else str(milestone.get("company_id", ""))
	if target_company_id.is_empty():
		return {}
	var definition: Dictionary = run_state.get_effective_company_definition(target_company_id, false, false)
	if definition.is_empty():
		return {}
	var elapsed_days: int = max(day_number - int(milestone.get("start_day_index", day_number)) + 1, 1)
	var duration_days: int = max(int(milestone.get("duration_days", 1)), 1)
	var visibility: String = "visible" if elapsed_days >= 2 else "hidden"
	var sentiment_shift: float = float(milestone.get("sentiment_shift", 0.0))
	if finance_side:
		sentiment_shift = clamp(absf(sentiment_shift) * 0.32, 0.015, 0.08)
	var description: String = _finance_arc_summary(milestone) if finance_side else str(milestone.get("summary", "Roadmap story is moving through the market."))
	var category: String = "roadmap_financing" if finance_side else ("roadmap_development" if bool(milestone.get("physical_project", false)) else "roadmap_strategy")
	var arc_id: String = "%s|finance" % str(milestone.get("id", "")) if finance_side else str(milestone.get("id", ""))
	var arc: Dictionary = {
		"arc_id": arc_id,
		"event_id": "roadmap_financing_partner" if finance_side else "roadmap_%s" % str(milestone.get("family_id", "project")),
		"event_family": "company_roadmap",
		"scope": "company",
		"category": category,
		"tone": "positive" if finance_side else str(milestone.get("tone", "mixed")),
		"target_company_id": target_company_id,
		"target_sector_id": str(definition.get("sector_id", "")),
		"target_ticker": str(definition.get("ticker", target_company_id.to_upper())),
		"target_company_name": str(definition.get("name", target_company_id.to_upper())),
		"headline": _finance_arc_headline(milestone) if finance_side else str(milestone.get("headline", "")),
		"summary": description,
		"description": description,
		"source_system": SOURCE_SYSTEM_ID,
		"current_phase_id": _phase_id_for_elapsed(elapsed_days, duration_days),
		"current_phase_label": _phase_label_for_elapsed(elapsed_days, duration_days),
		"phase_day_index": elapsed_days,
		"phase_duration_days": duration_days,
		"phase_sentiment_shift": sentiment_shift,
		"phase_volatility_multiplier": float(milestone.get("volatility_multiplier", 1.08)),
		"phase_visibility": visibility,
		"phase_hidden_flag": "roadmap_funding_watch" if finance_side else "roadmap_site_watch",
		"start_day_index": int(milestone.get("start_day_index", day_number)),
		"end_day_index": int(milestone.get("end_day_index", day_number)),
		"day_index": day_number,
		"trade_date": trade_date.duplicate(true)
	}
	if bool(milestone.get("physical_project", false)) and not finance_side:
		arc["property_development_location_id"] = str(milestone.get("location_id", ""))
		arc["property_development_location_label"] = str(milestone.get("location_label", ""))
		arc["property_development_theme"] = str(milestone.get("property_theme", ""))
		arc["property_development_theme_label"] = str(milestone.get("property_theme", "")).replace("_", " ").capitalize()
	return arc


func _build_event_for_milestone(run_state, milestone: Dictionary, trade_date: Dictionary, day_number: int) -> Dictionary:
	var arc: Dictionary = _build_arc(run_state, milestone, trade_date, day_number, false)
	arc["phase_visibility"] = "visible"
	arc["current_phase_id"] = "public_watch"
	arc["current_phase_label"] = "Public watch"
	return arc


func _blocked_company_ids_from_milestones(active_milestones: Dictionary) -> Array:
	var ids: Array = []
	for milestone_value in active_milestones.values():
		if typeof(milestone_value) != TYPE_DICTIONARY:
			continue
		var milestone: Dictionary = milestone_value
		for company_id_value in [milestone.get("company_id", ""), milestone.get("finance_company_id", "")]:
			var company_id: String = str(company_id_value)
			if not company_id.is_empty() and not ids.has(company_id):
				ids.append(company_id)
	return ids


func _normalize_milestone(source_value: Variant) -> Dictionary:
	if typeof(source_value) != TYPE_DICTIONARY:
		return {}
	var source: Dictionary = source_value
	var milestone_id: String = str(source.get("id", ""))
	var company_id: String = str(source.get("company_id", ""))
	if milestone_id.is_empty() or company_id.is_empty():
		return {}
	return source.duplicate(true)


func _roadmap_families_for_sector(sector_id: String) -> Array:
	return DataRepository.get_company_roadmap_catalog_ref().get("sector_roadmaps", {}).get(sector_id, [])


func _roadmap_family_by_id(sector_id: String, family_id: String) -> Dictionary:
	for family_value in _roadmap_families_for_sector(sector_id):
		if typeof(family_value) != TYPE_DICTIONARY:
			continue
		var family: Dictionary = family_value
		if str(family.get("id", "")) == family_id:
			return family.duplicate(true)
	return {}


func _debug_family_for_generator(sector_id: String, roadmap_profile: Dictionary, generator_id: String) -> Dictionary:
	var primary_family: Dictionary = roadmap_family_for_profile(roadmap_profile, sector_id)
	if primary_family.is_empty():
		for family_value in _roadmap_families_for_sector(sector_id):
			if typeof(family_value) == TYPE_DICTIONARY:
				primary_family = family_value.duplicate(true)
				break
	if primary_family.is_empty():
		return {}
	if generator_id == "roadmap_physical":
		for family_value in _roadmap_families_for_sector(sector_id):
			if typeof(family_value) != TYPE_DICTIONARY:
				continue
			var physical_family: Dictionary = family_value
			if bool(physical_family.get("physical", false)):
				return physical_family.duplicate(true)
		return {}
	if generator_id == "roadmap_financing":
		var financing_family: Dictionary = primary_family.duplicate(true)
		financing_family["funding_scale"] = "transformational"
		financing_family["funding_routes"] = ["loan", "rights_issue"]
		return financing_family
	if generator_id == "roadmap_corporate_funding":
		var corporate_family: Dictionary = primary_family.duplicate(true)
		corporate_family["funding_scale"] = "transformational"
		corporate_family["funding_routes"] = ["rights_issue"]
		return corporate_family
	return primary_family


func _location_tags(location_id: String) -> Array:
	for location_value in DataRepository.get_company_roadmap_catalog_ref().get("locations", []):
		if typeof(location_value) != TYPE_DICTIONARY:
			continue
		var location: Dictionary = location_value
		if str(location.get("id", "")) == location_id:
			return location.get("tags", []).duplicate()
	return []


func _location_label(location_id: String) -> String:
	for location_value in DataRepository.get_company_roadmap_catalog_ref().get("locations", []):
		if typeof(location_value) != TYPE_DICTIONARY:
			continue
		var location: Dictionary = location_value
		if str(location.get("id", "")) == location_id:
			return str(location.get("label", location_id.capitalize()))
	return "Jakarta" if location_id.is_empty() else location_id.replace("_", " ").capitalize()


func _company_has_live_chain(chains: Dictionary, company_id: String) -> bool:
	for chain_value in chains.values():
		if typeof(chain_value) != TYPE_DICTIONARY:
			continue
		var chain: Dictionary = chain_value
		if str(chain.get("company_id", "")) != company_id:
			continue
		if str(chain.get("status", "active")) == "active" and str(chain.get("outcome_state", "")) != "completed":
			return true
	return false


func _corporate_action_family_for_funding(family: Dictionary) -> String:
	var routes: Array = family.get("funding_routes", [])
	if routes.has("private_placement"):
		return "private_placement"
	if routes.has("rights_issue"):
		return "rights_issue"
	return "rights_issue"


func _tone_for_funding_outcome(outcome: String) -> String:
	match outcome:
		"self_funded", "needs_financing":
			return "positive"
		"needs_corporate_action", "delayed":
			return "mixed"
		"cancelled":
			return "negative"
	return "mixed"


func _sentiment_for_milestone(family: Dictionary, outcome: String) -> float:
	var base: float = float(family.get("positive_bias", 0.1))
	match outcome:
		"self_funded":
			return clamp(base, 0.04, 0.18)
		"needs_financing":
			return clamp(base * 0.82, 0.035, 0.15)
		"needs_corporate_action":
			return clamp(base * 0.35, -0.02, 0.08)
		"delayed":
			return -0.045
		"cancelled":
			return -0.12
	return 0.0


func _volatility_for_milestone(outcome: String) -> float:
	match outcome:
		"self_funded":
			return 1.09
		"needs_financing":
			return 1.14
		"needs_corporate_action":
			return 1.2
		"delayed", "cancelled":
			return 1.16
	return 1.08


func _milestone_headline(definition: Dictionary, family: Dictionary, outcome: String, location_label: String) -> String:
	var ticker: String = str(definition.get("ticker", definition.get("id", ""))).to_upper()
	var project_label: String = str(family.get("project_label", family.get("label", "roadmap project")))
	if outcome == "needs_financing":
		return "%s seeks financing support for %s plan" % [ticker, project_label]
	if outcome == "needs_corporate_action":
		return "%s funding track opens around %s plan" % [ticker, project_label]
	if outcome == "delayed":
		return "%s roadmap timing stretches on %s plan" % [ticker, project_label]
	if outcome == "cancelled":
		return "%s pulls back from %s plan" % [ticker, project_label]
	if bool(family.get("physical", false)):
		return "%s puts %s plan on watch in %s" % [ticker, project_label, location_label]
	return "%s advances %s roadmap" % [ticker, project_label]


func _milestone_summary(definition: Dictionary, family: Dictionary, outcome: String, location_label: String, funding: Dictionary) -> String:
	var company_name: String = str(definition.get("name", definition.get("ticker", "The company")))
	var project_label: String = str(family.get("project_label", family.get("label", "roadmap project")))
	var location_phrase: String = " around %s" % location_label if bool(family.get("physical", false)) else ""
	match outcome:
		"self_funded":
			return "%s is moving a %s%s with enough internal funding capacity for the first stage." % [company_name, project_label, location_phrase]
		"needs_financing":
			return "%s is moving a %s%s with financing support from %s." % [company_name, project_label, location_phrase, str(funding.get("finance_company_name", "a finance partner"))]
		"needs_corporate_action":
			return "%s is preparing a funding route for a %s%s, so filings and meeting notices matter more than market chatter." % [company_name, project_label, location_phrase]
		"delayed":
			return "%s still has the %s%s on its roadmap, but funding and execution timing are not clean yet." % [company_name, project_label, location_phrase]
		"cancelled":
			return "%s has stepped back from the %s%s after the funding read weakened." % [company_name, project_label, location_phrase]
	return "%s is drawing attention around a %s%s." % [company_name, project_label, location_phrase]


func _finance_arc_headline(milestone: Dictionary) -> String:
	return "%s linked to financing talks for %s" % [
		str(milestone.get("finance_ticker", "Finance name")),
		str(milestone.get("ticker", "issuer"))
	]


func _finance_arc_summary(milestone: Dictionary) -> String:
	return "%s is being watched as a possible financing partner for %s's %s." % [
		str(milestone.get("finance_company_name", "A finance company")),
		str(milestone.get("ticker", "the issuer")),
		str(milestone.get("project_label", "roadmap project"))
	]


func _phase_id_for_elapsed(elapsed_days: int, duration_days: int) -> String:
	if elapsed_days <= 1:
		return "early_watch"
	if elapsed_days >= duration_days:
		return "market_digest"
	return "public_watch"


func _phase_label_for_elapsed(elapsed_days: int, duration_days: int) -> String:
	if elapsed_days <= 1:
		return "Early watch"
	if elapsed_days >= duration_days:
		return "Market digest"
	return "Public watch"
