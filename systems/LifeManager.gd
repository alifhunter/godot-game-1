extends RefCounted
class_name LifeManager
## Life-sim domain logic (life plan, wellbeing, properties, cars, development leads)
## moved out of GameManager.
## `gm` is the GameManager autoload instance (untyped to avoid a cyclic reference).


static func get_debug_life_development_generator_catalog(gm) -> Array:
	var groups: Array = []
	for group_value in gm.DEBUG_LIFE_DEVELOPMENT_GENERATOR_GROUPS:
		if typeof(group_value) == TYPE_DICTIONARY:
			groups.append(group_value.duplicate(true))
	return groups


static func debug_generate_life_development(gm, generator_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var generator: Dictionary = debug_life_development_generator_by_id(gm, generator_id)
	if generator.is_empty():
		return {"success": false, "message": "Unknown Life property-intel generator."}
	var result: Dictionary = debug_force_life_development_lead(gm,
		str(generator.get("location_id", "jakarta")),
		str(generator.get("theme", "modern_city")),
		str(generator.get("impact_tier", "major")),
		str(generator.get("source_type", "network")),
		str(generator.get("outcome_override", ""))
	)
	if not bool(result.get("success", false)):
		return result
	var lead: Dictionary = result.get("lead", {})
	return {
		"success": true,
		"message": "Generated property watch: %s / %s." % [
			str(lead.get("location_label", str(generator.get("location_id", "Jakarta")).capitalize())),
			str(lead.get("theme_label", str(generator.get("theme", "modern_city")).replace("_", " ").capitalize()))
		],
		"generator_id": generator_id,
		"generator_label": str(generator.get("label", "Life property intel")),
		"lead": lead.duplicate(true)
	}


static func debug_life_development_generator_by_id(gm, generator_id: String) -> Dictionary:
	for group_value in gm.DEBUG_LIFE_DEVELOPMENT_GENERATOR_GROUPS:
		if typeof(group_value) != TYPE_DICTIONARY:
			continue
		var group: Dictionary = group_value
		for generator_value in group.get("generators", []):
			if typeof(generator_value) != TYPE_DICTIONARY:
				continue
			var generator: Dictionary = generator_value
			if str(generator.get("id", "")) == generator_id:
				return generator.duplicate(true)
	return {}


static func get_life_action_block_reason(gm, action_id: String) -> String:
	if not RunState.has_active_run():
		return "No active run."
	var normalized_action: String = action_id.to_lower()
	var life_state: Dictionary = RunState.get_player_life()
	var legal_state: Dictionary = life_state.get("legal_state", {}) if typeof(life_state.get("legal_state", {})) == TYPE_DICTIONARY else {}
	if bool(legal_state.get("active", false)) and int(legal_state.get("days_remaining", 0)) > 0:
		if normalized_action == "advance_day":
			return ""
		return "Legal hold is active. Only Advance Day is available for %d trading day%s." % [
			int(legal_state.get("days_remaining", 0)),
			"" if int(legal_state.get("days_remaining", 0)) == 1 else "s"
		]
	if int(life_state.get("hospital_days_remaining", 0)) > 0:
		if normalized_action == "advance_day":
			return ""
		return "Hospital recovery is active. Only Advance Day is available for %d trading day%s." % [
			int(life_state.get("hospital_days_remaining", 0)),
			"" if int(life_state.get("hospital_days_remaining", 0)) == 1 else "s"
		]
	return gm.get_cash_stress_block_reason(action_id)


static func get_life_snapshot(gm) -> Dictionary:
	if not RunState.has_active_run():
		return {}

	var life_state: Dictionary = RunState.get_player_life()
	var housing: Dictionary = gm._life_option_by_id(gm.LIFE_HOUSING_OPTIONS, str(life_state.get("housing_id", "")))
	var lifestyle: Dictionary = gm._life_option_by_id(gm.LIFE_LIFESTYLE_OPTIONS, str(life_state.get("lifestyle_id", "")))
	var basics_tier: Dictionary = gm._life_basics_tier_by_id(str(life_state.get("basics_tier_id", RunState.LIFE_DEFAULT_BASICS_TIER_ID)))
	var asset_summary: Dictionary = gm._build_life_asset_summary(life_state)
	var development_leads: Array = build_life_development_lead_rows(gm, life_state)
	var property_value_events: Array = build_life_property_value_event_rows(asset_summary.get("properties", []))
	var portfolio: Dictionary = gm.get_portfolio_snapshot()
	var dividend_projection: Dictionary = build_life_dividend_projection(gm)
	var basics_cost: float = float(basics_tier.get("monthly_cost", gm.LIFE_BASIC_EXPENSES_MONTHLY))
	var monthly_extra: float = max(float(life_state.get("monthly_extra", 0.0)), 0.0)
	var monthly_outflow: float = gm._life_monthly_outflow_for_state(life_state)
	var estimated_monthly_dividends: float = float(dividend_projection.get("estimated_monthly_dividends", 0.0))
	var net_monthly: float = estimated_monthly_dividends - monthly_outflow
	var cash: float = float(portfolio.get("cash", 0.0))
	var runway_months: float = 999.0
	if monthly_outflow > 0.0:
		runway_months = cash / monthly_outflow
	var next_life_payment: Dictionary = gm._build_next_life_payment_snapshot(monthly_outflow)
	var status_label: String = "Comfortable runway"
	var finance_status: Dictionary = gm.get_finance_status_snapshot()
	var stress_stage: Dictionary = RunState.get_life_stress_stage(life_state)
	var public_image: Dictionary = build_life_public_image_snapshot(gm, portfolio, asset_summary)
	if bool(finance_status.get("bankrupt", false)):
		status_label = "Bankrupt"
	elif int(life_state.get("hospital_days_remaining", 0)) > 0:
		status_label = "Hospitalized"
	elif bool(life_state.get("burnout_risk_active", false)):
		status_label = "Burnout risk"
	elif bool(finance_status.get("cash_stress_active", false)):
		status_label = "Cash stress"
	elif runway_months < 6.0:
		status_label = "Cash pressure"
	elif runway_months < 12.0:
		status_label = "Thin runway"
	elif runway_months < 24.0:
		status_label = "Manageable runway"

	return {
		"state": life_state,
		"trade_date": gm.get_current_trade_date(),
		"cash": cash,
		"equity": float(portfolio.get("equity", 0.0)),
		"market_value": float(portfolio.get("market_value", 0.0)),
		"housing": housing,
		"basics_tier": basics_tier,
		"lifestyle": lifestyle,
		"housing_options": gm.LIFE_HOUSING_OPTIONS.duplicate(true),
		"basics_tiers": gm.LIFE_BASICS_TIERS.duplicate(true),
		"lifestyle_options": gm.LIFE_LIFESTYLE_OPTIONS.duplicate(true),
		"property_catalog": build_life_property_catalog_rows(gm),
		"car_catalog": gm.LIFE_CAR_CATALOG.duplicate(true),
		"property_locations": build_life_property_location_rows(gm),
		"properties": asset_summary.get("properties", []).duplicate(true),
		"cars": asset_summary.get("cars", []).duplicate(true),
		"development_leads": development_leads,
		"property_value_events": property_value_events,
		"primary_property": asset_summary.get("primary_property", {}).duplicate(true),
		"active_car": asset_summary.get("active_car", {}).duplicate(true),
		"public_image": public_image,
		"lifestyle_asset_value": float(asset_summary.get("asset_value", 0.0)),
		"property_value": float(asset_summary.get("property_value", 0.0)),
		"car_value": float(asset_summary.get("car_value", 0.0)),
		"rental_income": float(asset_summary.get("rental_income", 0.0)),
		"asset_upkeep": float(asset_summary.get("asset_upkeep", 0.0)),
		"property_upkeep": float(asset_summary.get("property_upkeep", 0.0)),
		"non_primary_property_upkeep": float(asset_summary.get("non_primary_property_upkeep", 0.0)),
		"car_upkeep": float(asset_summary.get("car_upkeep", 0.0)),
		"housing_cost_monthly": float(asset_summary.get("primary_residence_cost", 0.0)) if bool(asset_summary.get("owned_primary_residence", false)) else float(housing.get("monthly_cost", 0.0)),
		"net_lifestyle_cashflow": float(asset_summary.get("net_lifestyle_cashflow", 0.0)),
		"owned_primary_residence": bool(asset_summary.get("owned_primary_residence", false)),
		"basic_expenses_monthly": basics_cost,
		"monthly_extra": monthly_extra,
		"monthly_outflow": monthly_outflow,
		"next_life_payment": next_life_payment,
		"estimated_monthly_dividends": estimated_monthly_dividends,
		"estimated_annual_dividends": estimated_monthly_dividends * 12.0,
		"declared_dividend_total_12m": float(dividend_projection.get("declared_dividend_total_12m", 0.0)),
		"net_monthly": net_monthly,
		"runway_months": runway_months,
		"finance": finance_status,
		"status_label": status_label,
		"stress_value": float(life_state.get("stress_value", RunState.LIFE_DEFAULT_STRESS_VALUE)),
		"happiness_value": float(life_state.get("happiness_value", RunState.LIFE_DEFAULT_HAPPINESS_VALUE)),
		"stress_stage": stress_stage,
		"stress_ap_penalty": RunState.get_life_stress_ap_penalty(life_state),
		"burnout_risk_active": bool(life_state.get("burnout_risk_active", false)),
		"burnout_risk_days_remaining": int(life_state.get("burnout_risk_days_remaining", 0)),
		"hospital_days_remaining": int(life_state.get("hospital_days_remaining", 0)),
		"hospitalized": int(life_state.get("hospital_days_remaining", 0)) > 0,
		"dividend_rows": dividend_projection.get("rows", []).duplicate(true),
		"note": "Monthly costs and loan payments deduct cash on the first trading day of each new month. Dividends only count after corporate actions are declared."
	}


static func set_life_plan(gm, housing_id: String, lifestyle_id: String, basics_tier_id: String = "") -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var hospital_block_reason: String = get_life_action_block_reason(gm, "life_plan")
	if not hospital_block_reason.is_empty():
		return {"success": false, "message": hospital_block_reason}
	var life_state: Dictionary = RunState.get_player_life()
	var housing: Dictionary = gm._life_option_by_id(gm.LIFE_HOUSING_OPTIONS, housing_id)
	var lifestyle: Dictionary = gm._life_option_by_id(gm.LIFE_LIFESTYLE_OPTIONS, lifestyle_id)
	var basics_tier: Dictionary = gm._life_basics_tier_by_id(basics_tier_id if not basics_tier_id.is_empty() else str(life_state.get("basics_tier_id", RunState.LIFE_DEFAULT_BASICS_TIER_ID)))
	var current_outflow: float = gm._life_monthly_outflow_for_state(life_state)
	var next_outflow: float = life_monthly_outflow_for_options(gm,
		str(housing.get("id", "kost_room")),
		str(lifestyle.get("id", "balanced")),
		str(basics_tier.get("id", RunState.LIFE_DEFAULT_BASICS_TIER_ID)),
		max(float(life_state.get("monthly_extra", 0.0)), 0.0)
	)
	var finance_status: Dictionary = gm.get_finance_status_snapshot()
	if bool(finance_status.get("bankrupt", false)):
		return {"success": false, "message": "Bankruptcy has disabled Life plan changes."}
	if bool(finance_status.get("cash_stress_active", false)) and next_outflow > current_outflow + 0.0001:
		return {"success": false, "message": "Cash stress is active. Lower or maintain Life costs before increasing monthly outflow."}
	life_state["housing_id"] = str(housing.get("id", "kost_room"))
	life_state["lifestyle_id"] = str(lifestyle.get("id", "balanced"))
	life_state["basics_tier_id"] = str(basics_tier.get("id", RunState.LIFE_DEFAULT_BASICS_TIER_ID))
	life_state["updated_day_index"] = RunState.day_index
	life_state["updated_trade_date"] = gm.get_current_trade_date()
	RunState.set_player_life(life_state)
	gm._request_autosave("life_plan")
	gm.life_changed.emit()
	return {
		"success": true,
		"message": "Life plan updated.",
		"snapshot": get_life_snapshot(gm)
	}


static func process_life_development_leads(gm) -> Array:
	if not RunState.has_active_run():
		return []
	var life_state: Dictionary = RunState.get_player_life()
	var leads: Array = life_state.get("development_leads", []).duplicate(true)
	if leads.is_empty():
		return []
	var properties: Array = life_state.get("properties", []).duplicate(true)
	var results: Array = []
	var changed: bool = false
	for lead_index in range(leads.size()):
		if typeof(leads[lead_index]) != TYPE_DICTIONARY:
			continue
		var lead: Dictionary = leads[lead_index]
		if bool(lead.get("resolved", false)):
			continue
		if RunState.day_index < int(lead.get("due_day_index", RunState.day_index + 1)):
			continue
		var resolution: Dictionary = resolve_life_development_lead(gm, lead)
		var outcome: String = str(resolution.get("outcome", "cancelled"))
		var result: Dictionary = {
			"lead_id": str(lead.get("id", "")),
			"location_id": str(lead.get("location_id", "")),
			"location_label": gm._life_location_label(str(lead.get("location_id", ""))),
			"theme": str(lead.get("theme", "")),
			"theme_label": gm._life_development_theme_label(str(lead.get("theme", ""))),
			"source_type": str(lead.get("source_type", "")),
			"contact_id": str(lead.get("contact_id", "")),
			"stage": outcome,
			"outcome": outcome,
			"applied_property_ids": []
		}
		if outcome == "delayed":
			var delay_days: int = int(resolution.get("delay_days", 4))
			lead["stage"] = "delayed"
			lead["due_day_index"] = RunState.day_index + max(delay_days, 1)
			lead["delay_count"] = int(lead.get("delay_count", 0)) + 1
			lead["source_note"] = "The lead is still alive, but permits and land work are taking longer than expected."
			result["due_day_index"] = int(lead.get("due_day_index", 0))
			results.append(result)
			leads[lead_index] = lead
			changed = true
			continue
		lead["resolved"] = true
		lead["outcome"] = outcome
		lead["public_confirmed"] = outcome == "confirmed"
		lead["stage"] = "confirmed" if outcome == "confirmed" else "cancelled"
		lead["display_location_label"] = gm._life_location_label(str(lead.get("location_id", "")))
		lead["display_theme_label"] = gm._life_development_theme_label(str(lead.get("theme", "")))
		if outcome == "confirmed":
			var value_multiplier: float = max(float(resolution.get("value_multiplier", 1.0)), 1.0)
			lead["value_multiplier"] = value_multiplier
			var applied_property_ids: Array = []
			for property_index in range(properties.size()):
				if typeof(properties[property_index]) != TYPE_DICTIONARY:
					continue
				var property_row: Dictionary = properties[property_index]
				if str(property_row.get("location_id", "")) != str(lead.get("location_id", "")):
					continue
				if life_property_has_value_event(property_row, str(lead.get("id", ""))):
					continue
				var old_value: float = max(float(property_row.get("current_value", property_row.get("purchase_price", 0.0))), 0.0)
				var new_value: float = old_value * value_multiplier
				var event: Dictionary = {
					"lead_id": str(lead.get("id", "")),
					"label": "%s confirmed in %s" % [gm._life_development_theme_label(str(lead.get("theme", ""))), gm._life_location_label(str(lead.get("location_id", "")))],
					"theme": str(lead.get("theme", "")),
					"theme_label": gm._life_development_theme_label(str(lead.get("theme", ""))),
					"source_type": str(lead.get("source_type", "")),
					"outcome": "confirmed",
					"multiplier": value_multiplier,
					"old_value": old_value,
					"new_value": new_value,
					"day_index": RunState.day_index,
					"trade_date": gm.get_current_trade_date()
				}
				var value_events: Array = property_row.get("value_events", []).duplicate(true)
				value_events.append(event)
				property_row["value_events"] = value_events
				property_row["current_value"] = new_value
				properties[property_index] = property_row
				applied_property_ids.append(str(property_row.get("id", "")))
			lead["applied_property_ids"] = applied_property_ids
			result["value_multiplier"] = value_multiplier
			result["applied_property_ids"] = applied_property_ids
			result["stage"] = "confirmed"
		else:
			lead["value_multiplier"] = 1.0
			lead["source_note"] = "The lead did not survive public confirmation. No property value uplift was applied."
			result["stage"] = "cancelled"
			result["value_multiplier"] = 1.0
		results.append(result)
		leads[lead_index] = lead
		changed = true
	if changed:
		life_state["development_leads"] = leads
		life_state["properties"] = properties
		life_state["updated_day_index"] = RunState.day_index
		life_state["updated_trade_date"] = gm.get_current_trade_date()
		RunState.set_player_life(life_state)
	return results


static func debug_force_life_development_lead(gm, location_id: String, theme: String = "modern_city", impact_tier: String = "major", source_type: String = "network", outcome_override: String = "") -> Dictionary:
	var result: Dictionary = create_life_development_lead(gm,
		location_id,
		theme,
		impact_tier,
		source_type,
		"debug_%s_%s_%d" % [location_id, theme, RunState.day_index],
		"",
		88.0,
		"Forced property report",
		"",
		outcome_override,
		4
	)
	if bool(result.get("success", false)):
		gm._request_autosave("life_development_debug")
		gm.life_changed.emit()
		gm.network_changed.emit()
	return result


static func discover_life_development_lead_from_article(gm, article: Dictionary) -> Dictionary:
	var result: Dictionary = maybe_create_life_development_lead_from_news_article(gm, article)
	if bool(result.get("success", false)) and not bool(result.get("duplicate", false)):
		gm._request_autosave("life_development_news")
		gm.life_changed.emit()
		gm.network_changed.emit()
	return result


static func get_life_development_lead_for_article(gm, article: Dictionary) -> Dictionary:
	if not RunState.has_active_run() or article.is_empty():
		return {}
	var source_id: String = gm._life_development_news_source_id(article)
	if source_id.is_empty():
		return {}
	var life_state: Dictionary = RunState.get_player_life()
	for lead_value in life_state.get("development_leads", []):
		if typeof(lead_value) != TYPE_DICTIONARY:
			continue
		var lead: Dictionary = lead_value
		if str(lead.get("source_type", "")) == "news" and str(lead.get("source_id", "")) == source_id:
			return lead.duplicate(true)
	return {}


static func purchase_life_property(gm, catalog_id: String, location_id: String = "", make_primary: bool = false) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var block_reason: String = get_life_action_block_reason(gm, "buy")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var catalog: Dictionary = life_property_catalog_by_id(gm, catalog_id)
	if catalog.is_empty():
		return {"success": false, "message": "Unknown property."}
	var location: Dictionary = gm._life_location_by_id(location_id)
	var base_price: float = life_property_base_price_for_location(catalog, location)
	var price: float = life_property_price_for_location(catalog, location)
	var cash: float = float(gm.get_portfolio_snapshot().get("cash", 0.0))
	if cash + 0.0001 < price:
		return {
			"success": false,
			"reason": "insufficient_cash",
			"message": "Not enough cash for this property.",
			"required_cash": price,
			"available_cash": cash
		}
	var life_state: Dictionary = RunState.get_player_life()
	var properties: Array = life_state.get("properties", []).duplicate(true)
	var property_id: String = life_next_asset_id("property", properties)
	if make_primary:
		for index in range(properties.size()):
			if typeof(properties[index]) == TYPE_DICTIONARY:
				var existing_property: Dictionary = properties[index]
				existing_property["is_primary"] = false
				properties[index] = existing_property
	var property_row: Dictionary = {
		"id": property_id,
		"catalog_id": str(catalog.get("id", "")),
		"location_id": str(location.get("id", "jakarta")),
		"label": str(catalog.get("label", "")),
		"location_label": str(location.get("label", "Jakarta")),
		"purchase_price": price,
		"base_value": base_price,
		"current_value": price,
		"monthly_upkeep": life_property_monthly_upkeep_for_location(catalog, location),
		"rent_income": life_property_rent_for_location(catalog, location),
		"rented_out": false,
		"is_primary": make_primary,
		"stress_delta": float(catalog.get("stress_delta", 0.0)),
		"happiness_delta": float(catalog.get("happiness_delta", 0.0)),
		"status_value": float(catalog.get("status_value", 0.0)),
		"value_events": [],
		"priced_in_lead_ids": life_public_confirmed_lead_ids_for_location(str(location.get("id", "jakarta"))),
		"purchased_day_index": RunState.day_index,
		"purchased_trade_date": gm.get_current_trade_date()
	}
	properties.append(property_row)
	life_state["properties"] = properties
	life_state["updated_day_index"] = RunState.day_index
	life_state["updated_trade_date"] = gm.get_current_trade_date()
	RunState.set_player_life(life_state)
	var payment: Dictionary = RunState.apply_cash_obligation("life_property_purchase", price, {
		"company_id": "life",
		"side": "life_property_purchase",
		"asset_id": property_id,
		"asset_label": str(catalog.get("label", "")),
		"location_label": str(location.get("label", "Jakarta"))
	})
	if not bool(payment.get("success", false)):
		return payment
	gm._record_steam_progress_event("life_property_purchased", {
		"catalog_id": catalog_id,
		"location_id": str(location.get("id", "jakarta")),
		"price": price
	})
	gm._request_autosave("life_property_purchase")
	gm.life_changed.emit()
	gm.portfolio_changed.emit()
	return {
		"success": true,
		"message": "%s purchased." % str(catalog.get("label", "Property")),
		"property": property_row.duplicate(true),
		"snapshot": get_life_snapshot(gm)
	}


static func sell_life_property(gm, property_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var block_reason: String = get_life_action_block_reason(gm, "life_plan")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var life_state: Dictionary = RunState.get_player_life()
	var properties: Array = life_state.get("properties", []).duplicate(true)
	var sold_property: Dictionary = {}
	var next_properties: Array = []
	for property_value in properties:
		if typeof(property_value) != TYPE_DICTIONARY:
			continue
		var property_row: Dictionary = property_value
		if str(property_row.get("id", "")) == property_id:
			sold_property = property_row
			continue
		next_properties.append(property_row)
	if sold_property.is_empty():
		return {"success": false, "message": "Property not found."}
	var proceeds: float = max(float(sold_property.get("current_value", sold_property.get("purchase_price", 0.0))) * gm.LIFE_ASSET_SELL_MULTIPLIER, 0.0)
	life_state["properties"] = next_properties
	life_state["updated_day_index"] = RunState.day_index
	life_state["updated_trade_date"] = gm.get_current_trade_date()
	RunState.set_player_life(life_state)
	var inflow: Dictionary = RunState.apply_cash_inflow("life_property_sale", proceeds, {
		"company_id": "life",
		"side": "life_property_sale",
		"asset_id": property_id,
		"asset_label": str(sold_property.get("label", "Property"))
	})
	if not bool(inflow.get("success", false)):
		return inflow
	gm._request_autosave("life_property_sale")
	gm.life_changed.emit()
	gm.portfolio_changed.emit()
	return {
		"success": true,
		"message": "%s sold." % str(sold_property.get("label", "Property")),
		"proceeds": proceeds,
		"snapshot": get_life_snapshot(gm)
	}


static func purchase_life_car(gm, catalog_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var block_reason: String = get_life_action_block_reason(gm, "buy")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var catalog: Dictionary = life_car_catalog_by_id(gm, catalog_id)
	if catalog.is_empty():
		return {"success": false, "message": "Unknown car."}
	var price: float = max(float(catalog.get("price", 0.0)), 0.0)
	var cash: float = float(gm.get_portfolio_snapshot().get("cash", 0.0))
	if cash + 0.0001 < price:
		return {
			"success": false,
			"reason": "insufficient_cash",
			"message": "Not enough cash for this car.",
			"required_cash": price,
			"available_cash": cash
		}
	var life_state: Dictionary = RunState.get_player_life()
	var cars: Array = life_state.get("cars", []).duplicate(true)
	var car_id: String = life_next_asset_id("car", cars)
	var first_car: bool = cars.is_empty()
	var car_row: Dictionary = {
		"id": car_id,
		"catalog_id": str(catalog.get("id", "")),
		"label": str(catalog.get("label", "")),
		"purchase_price": price,
		"current_value": price,
		"monthly_upkeep": max(float(catalog.get("monthly_upkeep", 0.0)), 0.0),
		"status_value": float(catalog.get("status_value", 0.0)),
		"stress_delta": float(catalog.get("stress_delta", 0.0)),
		"happiness_delta": float(catalog.get("happiness_delta", 0.0)),
		"is_active": first_car,
		"purchased_day_index": RunState.day_index,
		"purchased_trade_date": gm.get_current_trade_date()
	}
	cars.append(car_row)
	life_state["cars"] = cars
	life_state["updated_day_index"] = RunState.day_index
	life_state["updated_trade_date"] = gm.get_current_trade_date()
	RunState.set_player_life(life_state)
	var payment: Dictionary = RunState.apply_cash_obligation("life_car_purchase", price, {
		"company_id": "life",
		"side": "life_car_purchase",
		"asset_id": car_id,
		"asset_label": str(catalog.get("label", "Car"))
	})
	if not bool(payment.get("success", false)):
		return payment
	gm._record_steam_progress_event("life_car_purchased", {
		"catalog_id": catalog_id,
		"price": price
	})
	gm._request_autosave("life_car_purchase")
	gm.life_changed.emit()
	gm.portfolio_changed.emit()
	return {
		"success": true,
		"message": "%s purchased." % str(catalog.get("label", "Car")),
		"car": car_row.duplicate(true),
		"snapshot": get_life_snapshot(gm)
	}


static func set_active_life_car(gm, car_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var block_reason: String = get_life_action_block_reason(gm, "life_plan")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var life_state: Dictionary = RunState.get_player_life()
	var cars: Array = life_state.get("cars", []).duplicate(true)
	var found: bool = false
	for index in range(cars.size()):
		if typeof(cars[index]) != TYPE_DICTIONARY:
			continue
		var car_row: Dictionary = cars[index]
		var is_target: bool = str(car_row.get("id", "")) == car_id
		car_row["is_active"] = is_target
		if is_target:
			found = true
		cars[index] = car_row
	if not found:
		return {"success": false, "message": "Car not found."}
	life_state["cars"] = cars
	life_state["updated_day_index"] = RunState.day_index
	life_state["updated_trade_date"] = gm.get_current_trade_date()
	RunState.set_player_life(life_state)
	gm._request_autosave("life_active_car")
	gm.life_changed.emit()
	return {"success": true, "message": "Active car updated.", "snapshot": get_life_snapshot(gm)}


static func sell_life_car(gm, car_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var block_reason: String = get_life_action_block_reason(gm, "life_plan")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var life_state: Dictionary = RunState.get_player_life()
	var cars: Array = life_state.get("cars", []).duplicate(true)
	var sold_car: Dictionary = {}
	var next_cars: Array = []
	for car_value in cars:
		if typeof(car_value) != TYPE_DICTIONARY:
			continue
		var car_row: Dictionary = car_value
		if str(car_row.get("id", "")) == car_id:
			sold_car = car_row
			continue
		next_cars.append(car_row)
	if sold_car.is_empty():
		return {"success": false, "message": "Car not found."}
	if bool(sold_car.get("is_active", false)) and not next_cars.is_empty() and typeof(next_cars[0]) == TYPE_DICTIONARY:
		var next_active: Dictionary = next_cars[0]
		next_active["is_active"] = true
		next_cars[0] = next_active
	var proceeds: float = max(float(sold_car.get("current_value", sold_car.get("purchase_price", 0.0))) * gm.LIFE_ASSET_SELL_MULTIPLIER, 0.0)
	life_state["cars"] = next_cars
	life_state["updated_day_index"] = RunState.day_index
	life_state["updated_trade_date"] = gm.get_current_trade_date()
	RunState.set_player_life(life_state)
	var inflow: Dictionary = RunState.apply_cash_inflow("life_car_sale", proceeds, {
		"company_id": "life",
		"side": "life_car_sale",
		"asset_id": car_id,
		"asset_label": str(sold_car.get("label", "Car"))
	})
	if not bool(inflow.get("success", false)):
		return inflow
	gm._request_autosave("life_car_sale")
	gm.life_changed.emit()
	gm.portfolio_changed.emit()
	return {
		"success": true,
		"message": "%s sold." % str(sold_car.get("label", "Car")),
		"proceeds": proceeds,
		"snapshot": get_life_snapshot(gm)
	}


static func apply_life_monthly_obligation_if_due(gm, previous_trade_date: Dictionary, current_trade_date: Dictionary) -> Dictionary:
	if previous_trade_date.is_empty() or current_trade_date.is_empty():
		return {}
	var previous_year: int = int(previous_trade_date.get("year", 0))
	var previous_month: int = int(previous_trade_date.get("month", 0))
	var current_year: int = int(current_trade_date.get("year", 0))
	var current_month: int = int(current_trade_date.get("month", 0))
	if previous_year == current_year and previous_month == current_month:
		return {}
	if current_year <= 0 or current_month <= 0:
		return {}

	var obligation: Dictionary = gm._build_life_monthly_obligation()
	var amount: float = float(obligation.get("amount", 0.0))
	if amount <= 0.0:
		return {}

	var period_id: String = "%04d-%02d" % [current_year, current_month]
	var life_state: Dictionary = RunState.get_player_life()
	if str(life_state.get("last_obligation_period", "")) == period_id:
		return {}

	obligation["period_id"] = period_id
	obligation["trade_date"] = current_trade_date.duplicate(true)
	var result: Dictionary = RunState.apply_cash_obligation("life_obligation", amount, obligation)
	if not bool(result.get("success", false)):
		return {}

	life_state = RunState.get_player_life()
	life_state["last_obligation_period"] = period_id
	life_state["last_obligation_day_index"] = RunState.day_index
	life_state["last_obligation_amount"] = amount
	life_state["last_obligation_trade_date"] = current_trade_date.duplicate(true)
	RunState.set_player_life(life_state)
	RunState.last_day_results["life_obligation"] = result.duplicate(true)
	return result


static func apply_life_loan_payment_if_due(previous_trade_date: Dictionary, current_trade_date: Dictionary) -> Dictionary:
	if previous_trade_date.is_empty() or current_trade_date.is_empty():
		return {}
	var previous_year: int = int(previous_trade_date.get("year", 0))
	var previous_month: int = int(previous_trade_date.get("month", 0))
	var current_year: int = int(current_trade_date.get("year", 0))
	var current_month: int = int(current_trade_date.get("month", 0))
	if previous_year == current_year and previous_month == current_month:
		return {}
	if current_year <= 0 or current_month <= 0:
		return {}

	var finance: Dictionary = RunState.get_life_finance()
	var active_loan: Dictionary = finance.get("active_loan", {})
	if active_loan.is_empty():
		return {}
	var period_id: String = "%04d-%02d" % [current_year, current_month]
	if str(active_loan.get("last_payment_period", "")) == period_id:
		return {}
	var amount: float = max(float(active_loan.get("monthly_payment", 0.0)), 0.0)
	if amount <= 0.0:
		return {}
	var result: Dictionary = RunState.apply_life_loan_payment(amount, {
		"period_id": period_id,
		"trade_date": current_trade_date.duplicate(true)
	})
	if not bool(result.get("success", false)):
		return {}
	RunState.last_day_results["life_loan_payment"] = result.duplicate(true)
	return result


static func apply_bank_loan_payment_if_due(previous_trade_date: Dictionary, current_trade_date: Dictionary) -> Dictionary:
	if previous_trade_date.is_empty() or current_trade_date.is_empty():
		return {}
	var previous_year: int = int(previous_trade_date.get("year", 0))
	var previous_month: int = int(previous_trade_date.get("month", 0))
	var current_year: int = int(current_trade_date.get("year", 0))
	var current_month: int = int(current_trade_date.get("month", 0))
	if previous_year == current_year and previous_month == current_month:
		return {}
	if current_year <= 0 or current_month <= 0:
		return {}

	var finance: Dictionary = RunState.get_life_finance()
	var active_bank_loan: Dictionary = finance.get("active_bank_loan", {})
	if active_bank_loan.is_empty():
		return {}
	var period_id: String = "%04d-%02d" % [current_year, current_month]
	if str(active_bank_loan.get("last_payment_period", "")) == period_id:
		return {}
	var amount: float = max(float(active_bank_loan.get("monthly_payment", 0.0)), 0.0)
	if amount <= 0.0:
		return {}
	var result: Dictionary = RunState.apply_bank_loan_payment(amount, {
		"period_id": period_id,
		"trade_date": current_trade_date.duplicate(true)
	})
	if not bool(result.get("success", false)):
		return {}
	RunState.last_day_results["life_bank_loan_payment"] = result.duplicate(true)
	return result


static func apply_life_legal_state_update() -> Dictionary:
	if not RunState.has_active_run():
		return {}
	var life_state: Dictionary = RunState.get_player_life()
	var legal_state: Dictionary = life_state.get("legal_state", {}) if typeof(life_state.get("legal_state", {})) == TYPE_DICTIONARY else {}
	if not bool(legal_state.get("active", false)) or int(legal_state.get("days_remaining", 0)) <= 0:
		return {}
	RunState.pause_cash_stress_deadline(1)
	life_state = RunState.get_player_life()
	legal_state = life_state.get("legal_state", {}) if typeof(life_state.get("legal_state", {})) == TYPE_DICTIONARY else {}
	var days_before: int = int(legal_state.get("days_remaining", 0))
	var days_remaining: int = max(days_before - 1, 0)
	legal_state["days_remaining"] = days_remaining
	legal_state["last_legal_trade_date"] = RunState.current_trade_date.duplicate(true)
	legal_state["updated_day_index"] = RunState.day_index
	if days_remaining <= 0:
		legal_state["active"] = false
		legal_state["status"] = "released"
		legal_state["released_day_index"] = RunState.day_index
	else:
		legal_state["active"] = true
		legal_state["status"] = "held"
	life_state["legal_state"] = legal_state
	RunState.set_player_life(life_state)
	var result: Dictionary = {
		"legal_hold_day_completed": true,
		"legal_hold_active": days_remaining > 0,
		"days_before": days_before,
		"days_remaining": days_remaining,
		"case_id": str(legal_state.get("case_id", "")),
		"target_company_id": str(legal_state.get("target_company_id", "")),
		"target_ticker": str(legal_state.get("target_ticker", "")),
		"status": str(legal_state.get("status", "held")),
		"trade_date": RunState.current_trade_date.duplicate(true)
	}
	RunState.last_day_results["life_legal"] = result.duplicate(true)
	return result


static func apply_life_daily_wellbeing_update(gm) -> Dictionary:
	if not RunState.has_active_run():
		return {}
	var life_state: Dictionary = RunState.get_player_life()
	var was_hospitalized: bool = int(life_state.get("hospital_days_remaining", 0)) > 0
	if was_hospitalized:
		RunState.pause_cash_stress_deadline(1)
		life_state = RunState.get_player_life()
		var remaining_days: int = max(int(life_state.get("hospital_days_remaining", 0)) - 1, 0)
		life_state["hospital_days_remaining"] = remaining_days
		life_state["last_hospital_trade_date"] = RunState.current_trade_date.duplicate(true)
		life_state["burnout_risk_active"] = false
		life_state["burnout_risk_days_remaining"] = 0
		if remaining_days <= 0:
			life_state["stress_value"] = RunState.LIFE_HOSPITAL_RECOVERY_STRESS
			life_state["happiness_value"] = RunState.LIFE_HOSPITAL_RECOVERY_HAPPINESS
			life_state["hospital_started_day_index"] = -1
		RunState.set_player_life(life_state)
		var hospital_result: Dictionary = {
			"hospitalized": remaining_days > 0,
			"hospital_day_completed": true,
			"hospital_days_remaining": remaining_days,
			"stress_value": float(life_state.get("stress_value", RunState.LIFE_DEFAULT_STRESS_VALUE)),
			"happiness_value": float(life_state.get("happiness_value", RunState.LIFE_DEFAULT_HAPPINESS_VALUE)),
			"stress_stage": RunState.get_life_stress_stage(life_state)
		}
		RunState.last_day_results["life_wellbeing"] = hospital_result.duplicate(true)
		return hospital_result

	var basics_tier: Dictionary = gm._life_basics_tier_by_id(str(life_state.get("basics_tier_id", RunState.LIFE_DEFAULT_BASICS_TIER_ID)))
	var lifestyle_id: String = str(life_state.get("lifestyle_id", "balanced"))
	var stress_delta: float = float(basics_tier.get("stress_delta", 0.0))
	var happiness_delta: float = float(basics_tier.get("happiness_delta", 0.0))
	match lifestyle_id:
		"frugal":
			stress_delta += 1.0
			happiness_delta -= 1.0
		"status":
			stress_delta -= 1.0
			happiness_delta += 1.0
	var asset_summary: Dictionary = gm._build_life_asset_summary(life_state)
	stress_delta += float(asset_summary.get("stress_delta", 0.0))
	happiness_delta += float(asset_summary.get("happiness_delta", 0.0))
	var finance_status: Dictionary = gm.get_finance_status_snapshot()
	var runway_months: float = float(finance_status.get("runway_months", 999.0))
	if bool(finance_status.get("cash_stress_active", false)):
		stress_delta += 8.0
		happiness_delta -= 4.0
	elif runway_months < 0.5:
		stress_delta += 6.0
		happiness_delta -= 3.0
	elif runway_months < 1.0:
		stress_delta += 4.0
		happiness_delta -= 2.0
	elif runway_months < 3.0:
		stress_delta += 2.0
		happiness_delta -= 1.0
	elif runway_months >= 12.0:
		stress_delta -= 1.0
		happiness_delta += 1.0

	var previous_happiness: float = float(life_state.get("happiness_value", RunState.LIFE_DEFAULT_HAPPINESS_VALUE))
	var next_happiness: float = clamp(previous_happiness + happiness_delta, 0.0, 100.0)
	if next_happiness < 30.0:
		stress_delta += 3.0
	elif next_happiness < 45.0:
		stress_delta += 1.0
	elif next_happiness >= 75.0:
		stress_delta -= 1.0
	var next_stress: float = clamp(float(life_state.get("stress_value", RunState.LIFE_DEFAULT_STRESS_VALUE)) + stress_delta, 0.0, 100.0)
	life_state["stress_value"] = next_stress
	life_state["happiness_value"] = next_happiness
	var hospital_started: bool = false
	if next_stress >= 100.0:
		if not bool(life_state.get("burnout_risk_active", false)):
			life_state["burnout_risk_active"] = true
			life_state["burnout_risk_days_remaining"] = RunState.LIFE_BURNOUT_WARNING_TRADING_DAYS
		else:
			var risk_days_remaining: int = max(int(life_state.get("burnout_risk_days_remaining", RunState.LIFE_BURNOUT_WARNING_TRADING_DAYS)) - 1, 0)
			life_state["burnout_risk_days_remaining"] = risk_days_remaining
			if risk_days_remaining <= 0:
				hospital_started = true
				life_state["hospital_days_remaining"] = RunState.LIFE_HOSPITAL_TRADING_DAYS
				life_state["hospital_started_day_index"] = RunState.day_index
				life_state["last_hospital_trade_date"] = RunState.current_trade_date.duplicate(true)
				life_state["burnout_risk_active"] = false
	else:
		life_state["burnout_risk_active"] = false
		life_state["burnout_risk_days_remaining"] = 0
	RunState.set_player_life(life_state)
	var result: Dictionary = {
		"stress_value": next_stress,
		"happiness_value": next_happiness,
		"stress_delta": stress_delta,
		"happiness_delta": happiness_delta,
		"stress_stage": RunState.get_life_stress_stage(life_state),
		"stress_ap_penalty": RunState.get_life_stress_ap_penalty(life_state),
		"burnout_risk_active": bool(life_state.get("burnout_risk_active", false)),
		"burnout_risk_days_remaining": int(life_state.get("burnout_risk_days_remaining", 0)),
		"hospital_started": hospital_started,
		"hospital_days_remaining": int(life_state.get("hospital_days_remaining", 0))
	}
	RunState.last_day_results["life_wellbeing"] = result.duplicate(true)
	return result


static func life_monthly_outflow_for_options(gm, housing_id: String, lifestyle_id: String, basics_tier_id: String = "", monthly_extra: float = 0.0) -> float:
	var life_state: Dictionary = {
		"housing_id": housing_id,
		"lifestyle_id": lifestyle_id,
		"basics_tier_id": basics_tier_id if not basics_tier_id.is_empty() else RunState.LIFE_DEFAULT_BASICS_TIER_ID,
		"monthly_extra": monthly_extra
	}
	return gm._life_monthly_outflow_for_state(life_state)


static func build_life_property_catalog_rows(gm) -> Array:
	var rows: Array = []
	for catalog_value in gm.LIFE_PROPERTY_CATALOG:
		if typeof(catalog_value) != TYPE_DICTIONARY:
			continue
		var catalog: Dictionary = catalog_value
		for location_value in gm.LIFE_PROPERTY_LOCATIONS:
			if typeof(location_value) != TYPE_DICTIONARY:
				continue
			var location: Dictionary = location_value
			var location_id: String = str(location.get("id", "jakarta"))
			var public_uplift: float = life_location_public_uplift_multiplier(location_id)
			var row: Dictionary = catalog.duplicate(true)
			row["id"] = "%s_%s" % [str(catalog.get("id", "")), location_id]
			row["catalog_id"] = str(catalog.get("id", ""))
			row["location_id"] = location_id
			row["location_label"] = str(location.get("label", "Jakarta"))
			row["base_price"] = life_property_base_price_for_location(catalog, location)
			row["price"] = life_property_price_for_location(catalog, location)
			row["monthly_upkeep"] = life_property_monthly_upkeep_for_location(catalog, location)
			row["rent_income"] = life_property_rent_for_location(catalog, location)
			row["public_uplift_multiplier"] = public_uplift
			row["public_uplift_label"] = life_public_uplift_label(public_uplift)
			row["priced_in_lead_ids"] = life_public_confirmed_lead_ids_for_location(location_id)
			rows.append(row)
	return rows


static func build_life_public_image_snapshot(gm, portfolio: Dictionary, asset_summary: Dictionary) -> Dictionary:
	var cash: float = max(float(portfolio.get("cash", 0.0)), 0.0)
	var market_value: float = max(float(portfolio.get("market_value", 0.0)), 0.0)
	var asset_value: float = max(float(asset_summary.get("asset_value", 0.0)), 0.0)
	var score: float = 0.0
	score += min(cash / 250000000.0, 20.0)
	score += min(market_value / 500000000.0, 25.0)
	score += min(asset_value / 750000000.0, 35.0)
	score += min(float(asset_summary.get("status_value", 0.0)), 35.0)
	score += gm._life_thesis_public_image_score()
	score += life_twooter_reputation_score()
	score += life_network_reputation_score()
	score = clamp(score, 0.0, 100.0)
	var title: String = "Unknown Retail"
	var next_title: String = "Emerging Operator"
	var next_score: int = 18
	if score >= 78.0:
		title = "Market Patron"
		next_title = "Peak standing"
		next_score = 100
	elif score >= 58.0:
		title = "Public Figure"
		next_title = "Market Patron"
		next_score = 78
	elif score >= 38.0:
		title = "Established Investor"
		next_title = "Public Figure"
		next_score = 58
	elif score >= 18.0:
		title = "Emerging Operator"
		next_title = "Established Investor"
		next_score = 38
	return {
		"score": score,
		"title": title,
		"next_title": next_title,
		"next_score": next_score,
		"detail": "Derived from cash, portfolio, owned properties, cars, thesis work, and social reputation."
	}


static func life_twooter_reputation_score() -> float:
	var score: float = 0.0
	var social_state: Dictionary = RunState.get_twooter_social_state()
	var account_states: Dictionary = social_state.get("account_states", {}) if typeof(social_state.get("account_states", {})) == TYPE_DICTIONARY else {}
	for account_state_value in account_states.values():
		if typeof(account_state_value) != TYPE_DICTIONARY:
			continue
		var account_state: Dictionary = account_state_value
		score += min(max(float(account_state.get("relationship", 0.0)), 0.0) / 20.0, 1.5)
		score += min(max(float(account_state.get("credibility", 0.0)), 0.0) / 15.0, 1.0)
	return min(score, 7.0)


static func life_network_reputation_score() -> float:
	var score: float = 0.0
	for contact_value in RunState.get_network_contacts().values():
		if typeof(contact_value) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = contact_value
		if not bool(contact.get("met", false)):
			continue
		score += min(max(float(contact.get("relationship", 0.0)), 0.0) / 35.0, 1.3)
	return min(score, 7.0)


static func life_property_catalog_by_id(gm, catalog_id: String) -> Dictionary:
	for catalog_value in gm.LIFE_PROPERTY_CATALOG:
		if typeof(catalog_value) != TYPE_DICTIONARY:
			continue
		var catalog: Dictionary = catalog_value
		if str(catalog.get("id", "")) == catalog_id:
			return catalog.duplicate(true)
	return {}


static func life_car_catalog_by_id(gm, catalog_id: String) -> Dictionary:
	for catalog_value in gm.LIFE_CAR_CATALOG:
		if typeof(catalog_value) != TYPE_DICTIONARY:
			continue
		var catalog: Dictionary = catalog_value
		if str(catalog.get("id", "")) == catalog_id:
			return catalog.duplicate(true)
	return {}


static func life_property_price_for_location(catalog: Dictionary, location: Dictionary) -> float:
	return life_property_base_price_for_location(catalog, location) * life_location_public_uplift_multiplier(str(location.get("id", "jakarta")))


static func life_property_base_price_for_location(catalog: Dictionary, location: Dictionary) -> float:
	return max(float(catalog.get("price", 0.0)) * max(float(location.get("market_factor", 1.0)), 0.1), 0.0)


static func life_property_monthly_upkeep_for_location(catalog: Dictionary, location: Dictionary) -> float:
	return max(float(catalog.get("monthly_upkeep", 0.0)) * max(float(location.get("market_factor", 1.0)), 0.1), 0.0)


static func life_property_rent_for_location(catalog: Dictionary, location: Dictionary) -> float:
	return max(float(catalog.get("rent_income", 0.0)) * max(float(location.get("market_factor", 1.0)), 0.1), 0.0)


static func build_life_property_location_rows(gm) -> Array:
	var rows: Array = []
	for location_value in gm.LIFE_PROPERTY_LOCATIONS:
		if typeof(location_value) != TYPE_DICTIONARY:
			continue
		var location: Dictionary = location_value.duplicate(true)
		var location_id: String = str(location.get("id", ""))
		var public_uplift: float = life_location_public_uplift_multiplier(location_id)
		location["public_uplift_multiplier"] = public_uplift
		location["public_uplift_label"] = life_public_uplift_label(public_uplift)
		location["confirmed_lead_ids"] = life_public_confirmed_lead_ids_for_location(location_id)
		rows.append(location)
	return rows


static func build_life_development_lead_rows(gm, life_state: Dictionary) -> Array:
	var rows: Array = []
	for lead_value in life_state.get("development_leads", []):
		if typeof(lead_value) != TYPE_DICTIONARY:
			continue
		var lead: Dictionary = lead_value.duplicate(true)
		var location_id: String = str(lead.get("location_id", "jakarta"))
		var theme: String = str(lead.get("theme", "modern_city"))
		lead["location_label"] = gm._life_location_label(location_id)
		lead["theme_label"] = gm._life_development_theme_label(theme)
		lead["clarity_level"] = clamp(int(lead.get("clarity_level", 4 if str(lead.get("source_type", "")) == "network" else 1)), 1, 4)
		lead["clarity_label"] = gm._life_development_clarity_label(int(lead.get("clarity_level", 1)))
		lead["display_location_label"] = life_development_display_location_label(gm, lead)
		lead["display_theme_label"] = life_development_display_theme_label(gm, lead)
		lead["impact_label"] = life_development_impact_label(gm, str(lead.get("impact_tier", "moderate")))
		lead["stage_label"] = life_development_stage_label(str(lead.get("stage", "rumor")))
		lead["timing_label"] = life_development_timing_label(lead)
		rows.append(lead)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_resolved: bool = bool(a.get("resolved", false))
		var b_resolved: bool = bool(b.get("resolved", false))
		if a_resolved != b_resolved:
			return not a_resolved
		return int(a.get("due_day_index", 0)) < int(b.get("due_day_index", 0))
	)
	return rows


static func build_life_property_value_event_rows(properties: Array) -> Array:
	var rows: Array = []
	for property_value in properties:
		if typeof(property_value) != TYPE_DICTIONARY:
			continue
		var property_row: Dictionary = property_value
		for event_value in property_row.get("value_events", []):
			if typeof(event_value) != TYPE_DICTIONARY:
				continue
			var event: Dictionary = event_value.duplicate(true)
			event["property_id"] = str(property_row.get("id", ""))
			event["property_label"] = str(property_row.get("label", "Property"))
			event["location_id"] = str(property_row.get("location_id", ""))
			event["location_label"] = str(property_row.get("location_label", ""))
			rows.append(event)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("day_index", 0)) > int(b.get("day_index", 0))
	)
	return rows


static func life_location_public_uplift_multiplier(location_id: String) -> float:
	var best_multiplier: float = 1.0
	if not RunState.has_active_run():
		return best_multiplier
	var life_state: Dictionary = RunState.get_player_life()
	for lead_value in life_state.get("development_leads", []):
		if typeof(lead_value) != TYPE_DICTIONARY:
			continue
		var lead: Dictionary = lead_value
		if str(lead.get("location_id", "")) != location_id:
			continue
		if not bool(lead.get("public_confirmed", false)) or str(lead.get("outcome", "")) != "confirmed":
			continue
		best_multiplier = max(best_multiplier, float(lead.get("value_multiplier", 1.0)))
	return best_multiplier


static func life_public_confirmed_lead_ids_for_location(location_id: String) -> Array:
	var rows: Array = []
	if not RunState.has_active_run():
		return rows
	var life_state: Dictionary = RunState.get_player_life()
	for lead_value in life_state.get("development_leads", []):
		if typeof(lead_value) != TYPE_DICTIONARY:
			continue
		var lead: Dictionary = lead_value
		if str(lead.get("location_id", "")) == location_id and bool(lead.get("public_confirmed", false)):
			rows.append(str(lead.get("id", "")))
	return rows


static func life_public_uplift_label(multiplier: float) -> String:
	if multiplier <= 1.001:
		return ""
	return "Public uplift x%.2f" % multiplier


static func life_property_has_value_event(property_row: Dictionary, lead_id: String) -> bool:
	for event_value in property_row.get("value_events", []):
		if typeof(event_value) == TYPE_DICTIONARY and str(event_value.get("lead_id", "")) == lead_id:
			return true
	return false


static func resolve_life_development_lead(gm, lead: Dictionary) -> Dictionary:
	var outcome_override: String = str(lead.get("outcome_override", "")).strip_edges()
	if not outcome_override.is_empty():
		if outcome_override == "delayed":
			return {"outcome": "delayed", "delay_days": 4}
		if outcome_override == "cancelled":
			return {"outcome": "cancelled"}
		if outcome_override == "confirmed_big":
			return {"outcome": "confirmed", "value_multiplier": life_development_multiplier(gm, lead, true)}
		return {"outcome": "confirmed", "value_multiplier": life_development_multiplier(gm, lead, false)}
	var rng: RandomNumberGenerator = gm.STABLE_RNG.rng([
		RunState.run_seed,
		"life_development_resolve",
		str(lead.get("id", "")),
		int(lead.get("due_day_index", 0)),
		int(lead.get("delay_count", 0))
	])
	var reliability: float = clamp(float(lead.get("reliability", 50.0)), 0.0, 100.0) / 100.0
	var roll: float = rng.randf()
	var delay_count: int = int(lead.get("delay_count", 0))
	if delay_count < 2 and roll > reliability and roll <= reliability + 0.18:
		return {"outcome": "delayed", "delay_days": 3 + int(rng.randi_range(0, 4))}
	if roll > reliability + 0.18:
		return {"outcome": "cancelled"}
	var big_win_chance: float = 0.08
	match str(lead.get("impact_tier", "moderate")):
		"minor":
			big_win_chance = 0.05
		"moderate":
			big_win_chance = 0.10
		"major":
			big_win_chance = 0.16
		"transformational":
			big_win_chance = 0.22
	var big_win: bool = rng.randf() < big_win_chance
	return {"outcome": "confirmed", "value_multiplier": life_development_multiplier(gm, lead, big_win)}


static func life_development_multiplier(gm, lead: Dictionary, big_win: bool) -> float:
	var tier: Dictionary = gm.LIFE_DEVELOPMENT_IMPACT_TIERS.get(str(lead.get("impact_tier", "moderate")), gm.LIFE_DEVELOPMENT_IMPACT_TIERS.get("moderate", {}))
	var multiplier: float = float(tier.get("big_win_multiplier" if big_win else "base_multiplier", 1.18))
	var reliability: float = clamp(float(lead.get("reliability", 50.0)), 0.0, 100.0)
	if not big_win:
		multiplier += clamp((reliability - 50.0) / 400.0, -0.04, 0.08)
	return max(multiplier, 1.0)


static func create_life_development_lead(
	gm,
	location_id: String,
	theme: String,
	impact_tier: String,
	source_type: String,
	source_id: String,
	contact_id: String,
	reliability: float,
	source_label: String = "",
	source_note: String = "",
	outcome_override: String = "",
	clarity_level: int = 1
) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var location: Dictionary = gm._life_location_by_id(location_id)
	var resolved_location_id: String = str(location.get("id", "jakarta"))
	var resolved_theme: String = life_development_theme_id(gm, theme)
	var resolved_impact_tier: String = life_development_impact_tier_id(gm, impact_tier)
	var dedupe_key: String = "%s|%s|%s|%s" % [resolved_location_id, resolved_theme, source_type, source_id]
	var life_state: Dictionary = RunState.get_player_life()
	var leads: Array = life_state.get("development_leads", []).duplicate(true)
	for lead_value in leads:
		if typeof(lead_value) != TYPE_DICTIONARY:
			continue
		var existing: Dictionary = lead_value
		if str(existing.get("dedupe_key", "")) == dedupe_key:
			var incoming_clarity: int = clamp(clarity_level, 1, 4)
			if incoming_clarity > int(existing.get("clarity_level", 1)):
				var existing_index: int = leads.find(lead_value)
				existing["clarity_level"] = incoming_clarity
				existing["clarity_label"] = gm._life_development_clarity_label(incoming_clarity)
				existing["source_label"] = source_label
				existing["source_note"] = source_note
				existing["reliability"] = max(float(existing.get("reliability", 0.0)), clamp(reliability, 0.0, 100.0))
				existing["stage"] = "permit_watch" if float(existing.get("reliability", 0.0)) >= 72.0 else str(existing.get("stage", "rumor"))
				existing["display_location_label"] = gm._life_location_label(str(existing.get("location_id", resolved_location_id))) if source_type != "news" or incoming_clarity >= 2 else "Location not named"
				existing["display_theme_label"] = gm._life_development_theme_label(str(existing.get("theme", resolved_theme))) if source_type != "news" or incoming_clarity >= 3 else "Project not named"
				if existing_index >= 0:
					leads[existing_index] = existing
					life_state["development_leads"] = leads
					life_state["updated_day_index"] = RunState.day_index
					life_state["updated_trade_date"] = gm.get_current_trade_date()
					RunState.set_player_life(life_state)
					gm._invalidate_news_snapshot_cache()
			return {"success": true, "duplicate": true, "message": "Property watch already tracked.", "lead": existing.duplicate(true)}
	var tier: Dictionary = gm.LIFE_DEVELOPMENT_IMPACT_TIERS.get(resolved_impact_tier, gm.LIFE_DEVELOPMENT_IMPACT_TIERS.get("moderate", {}))
	var resolve_days: int = int(tier.get("resolve_days", 7))
	if source_type == "network":
		resolve_days = max(resolve_days - 2, 2)
	elif source_type == "news":
		resolve_days += 1
	var lead_seed: int = int(gm.STABLE_RNG.seed_from_parts([RunState.run_seed, "life_development_lead", dedupe_key, RunState.day_index]) % 100000)
	var contact_name: String = ""
	if not contact_id.is_empty():
		contact_name = gm._network_contact_display_name(contact_id)
	var resolved_clarity_level: int = clamp(clarity_level, 1, 4)
	var location_label: String = str(location.get("label", "Jakarta"))
	var theme_label: String = gm._life_development_theme_label(resolved_theme)
	var lead: Dictionary = {
		"id": "dev_%s_%s_%d_%05d" % [resolved_location_id, resolved_theme, RunState.day_index, lead_seed],
		"dedupe_key": dedupe_key,
		"location_id": resolved_location_id,
		"location_label": location_label,
		"theme": resolved_theme,
		"theme_label": theme_label,
		"source_type": source_type,
		"source_id": source_id,
		"source_label": source_label,
		"source_note": source_note,
		"contact_id": contact_id,
		"contact_name": contact_name,
		"discovered_day_index": RunState.day_index,
		"discovered_trade_date": gm.get_current_trade_date(),
		"stage": "permit_watch" if reliability >= 72.0 else "rumor",
		"reliability": clamp(reliability, 0.0, 100.0),
		"clarity_level": resolved_clarity_level,
		"clarity_label": gm._life_development_clarity_label(resolved_clarity_level),
		"display_location_label": location_label if source_type != "news" or resolved_clarity_level >= 2 else "Location not named",
		"display_theme_label": theme_label if source_type != "news" or resolved_clarity_level >= 3 else "Project not named",
		"impact_tier": resolved_impact_tier,
		"due_day_index": RunState.day_index + resolve_days,
		"resolved": false,
		"outcome": "",
		"value_multiplier": 1.0,
		"public_confirmed": false,
		"applied_property_ids": [],
		"delay_count": 0,
		"outcome_override": outcome_override
	}
	leads.append(lead)
	life_state["development_leads"] = leads
	life_state["updated_day_index"] = RunState.day_index
	life_state["updated_trade_date"] = gm.get_current_trade_date()
	RunState.set_player_life(life_state)
	gm._invalidate_news_snapshot_cache()
	return {"success": true, "message": "Property watch tracked.", "lead": lead.duplicate(true)}


static func maybe_create_life_development_lead_from_news_article(gm, article: Dictionary) -> Dictionary:
	if article.is_empty():
		return {"success": false, "message": "No article."}
	if not gm._is_life_development_story_article(article) and not gm._article_can_seed_life_development(article):
		return {"success": false, "message": "Article is not tied to a property report."}
	var article_id: String = gm._life_development_news_source_id(article)
	var seed: String = "%s|%s|%s" % [article_id, str(article.get("headline", "")), str(article.get("target_sector_id", ""))]
	var location_id: String = gm._life_development_location_for_article(article, seed)
	var theme: String = gm._life_development_theme_for_article(article, seed)
	var news_intel_level: int = clamp(int(article.get("intel_level", 1)), 1, 4)
	var big_development: bool = text_mentions_big_development(str(article.get("headline", "")) + " " + str(article.get("body", "")))
	var impact_tier: String = "major" if big_development else "moderate"
	if news_intel_level <= 1 and impact_tier == "major":
		impact_tier = "moderate"
	elif news_intel_level >= 4 and big_development and text_mentions_transformational_development(str(article.get("headline", "")) + " " + str(article.get("body", ""))):
		impact_tier = "transformational"
	var reliability_by_level: Array = [0.0, 46.0, 56.0, 66.0, 76.0]
	var reliability: float = float(reliability_by_level[news_intel_level])
	return create_life_development_lead(gm,
		location_id,
		theme,
		impact_tier,
		"news",
		article_id,
		str(article.get("author_contact_id", "")),
		reliability,
		life_development_news_source_label(article, news_intel_level),
		gm._life_development_news_source_note(article, location_id, theme, news_intel_level),
		"",
		news_intel_level
	)


static func maybe_create_life_development_lead_from_network_tip(gm, contact_id: String, tip_result: Dictionary) -> Dictionary:
	var contact: Dictionary = gm._network_contact_definition_by_id(contact_id)
	if contact.is_empty() or not contact_can_seed_life_development(gm, contact):
		return {}
	var runtime: Dictionary = RunState.get_network_contacts().get(contact_id, {})
	var relationship: float = float(runtime.get("relationship", 0.0))
	var seed: String = "%s|%s|%d" % [contact_id, str(tip_result.get("target_company_id", "")), RunState.day_index]
	var location_id: String = gm._life_development_location_for_seed(seed)
	var haystack: String = "%s %s %s" % [str(contact.get("role", "")), str(contact.get("intro", "")), str(tip_result.get("tip_read", ""))]
	var theme: String = gm._life_development_theme_for_text(haystack, seed)
	var impact_tier: String = "major" if relationship >= 35.0 else "moderate"
	var reliability: float = clamp(58.0 + relationship * 0.45, 45.0, 84.0)
	return create_life_development_lead(gm,
		location_id,
		theme,
		impact_tier,
		"network",
		"%s_%d" % [contact_id, RunState.day_index],
		contact_id,
		reliability,
		"%s location read" % str(contact.get("display_name", "Network contact")),
		"%s mentioned a possible %s around %s." % [
			str(contact.get("display_name", "A contact")),
			gm._life_development_theme_label(theme).to_lower(),
			gm._life_location_label(location_id)
		],
		"",
		4
	)


static func contact_can_seed_life_development(gm, contact: Dictionary) -> bool:
	var text: String = ("%s %s" % [str(contact.get("role", "")), str(contact.get("intro", ""))]).to_lower()
	for sector_value in contact.get("sector_ids", []):
		var sector_id: String = str(sector_value)
		if sector_id == "health":
			if gm._text_mentions_health_development(text):
				return true
			continue
		if gm.LIFE_DEVELOPMENT_RELEVANT_SECTORS.has(sector_id):
			return true
	for keyword in ["construction", "infrastructure", "property", "port", "logistics", "hospital", "campus", "planning", "concession", "industrial"]:
		if text.find(keyword) >= 0:
			return true
	return false


static func life_development_news_source_label(article: Dictionary, intel_level: int) -> String:
	var outlet_label: String = str(article.get("outlet_label", "News")).strip_edges()
	if outlet_label.is_empty():
		outlet_label = "News"
	match clamp(intel_level, 1, 4):
		1:
			return "%s property follow-up" % outlet_label
		2:
			return "%s location follow-up" % outlet_label
		3:
			return "%s project follow-up" % outlet_label
		_:
			return "%s property file" % outlet_label


static func text_mentions_big_development(text: String) -> bool:
	var lower_text: String = text.to_lower()
	for keyword in ["modern city", "new city", "toll road", "port expansion", "industrial estate", "transit corridor"]:
		if lower_text.find(keyword) >= 0:
			return true
	return false


static func text_mentions_transformational_development(text: String) -> bool:
	var lower_text: String = text.to_lower()
	for keyword in ["modern city", "new city", "master-planned", "mega project", "port expansion", "industrial estate"]:
		if lower_text.find(keyword) >= 0:
			return true
	return false


static func life_development_display_location_label(gm, lead: Dictionary) -> String:
	if bool(lead.get("public_confirmed", false)) or str(lead.get("source_type", "")) != "news":
		return str(lead.get("location_label", gm._life_location_label(str(lead.get("location_id", "")))))
	if int(lead.get("clarity_level", 1)) >= 2:
		return str(lead.get("location_label", gm._life_location_label(str(lead.get("location_id", "")))))
	return "Location not named"


static func life_development_display_theme_label(gm, lead: Dictionary) -> String:
	if bool(lead.get("public_confirmed", false)) or str(lead.get("source_type", "")) != "news":
		return str(lead.get("theme_label", gm._life_development_theme_label(str(lead.get("theme", "")))))
	if int(lead.get("clarity_level", 1)) >= 3:
		return str(lead.get("theme_label", gm._life_development_theme_label(str(lead.get("theme", "")))))
	return "Project not named"


static func life_development_theme_id(gm, theme: String) -> String:
	for theme_value in gm.LIFE_DEVELOPMENT_THEMES:
		if typeof(theme_value) == TYPE_DICTIONARY and str(theme_value.get("id", "")) == theme:
			return theme
	return "modern_city"


static func life_development_impact_tier_id(gm, impact_tier: String) -> String:
	if gm.LIFE_DEVELOPMENT_IMPACT_TIERS.has(impact_tier):
		return impact_tier
	return "moderate"


static func life_development_stage_label(stage: String) -> String:
	match stage:
		"permit_watch":
			return "Permit watch"
		"confirmed":
			return "Confirmed"
		"delayed":
			return "Delayed"
		"cancelled":
			return "Cancelled"
		_:
			return "Rumor"


static func life_development_impact_label(gm, impact_tier: String) -> String:
	var tier: Dictionary = gm.LIFE_DEVELOPMENT_IMPACT_TIERS.get(impact_tier, gm.LIFE_DEVELOPMENT_IMPACT_TIERS.get("moderate", {}))
	return str(tier.get("label", impact_tier.capitalize()))


static func life_development_timing_label(lead: Dictionary) -> String:
	if bool(lead.get("resolved", false)):
		return str(lead.get("outcome", "resolved")).capitalize()
	var days: int = int(lead.get("due_day_index", RunState.day_index)) - RunState.day_index
	if days <= 0:
		return "Due now"
	return "About %d trading day%s" % [days, "" if days == 1 else "s"]


static func life_next_asset_id(prefix: String, existing_rows: Array) -> String:
	var used: Dictionary = {}
	for row_value in existing_rows:
		if typeof(row_value) == TYPE_DICTIONARY:
			used[str(row_value.get("id", ""))] = true
	var attempt: int = existing_rows.size() + 1
	while attempt < 10000:
		var candidate: String = "%s_%d_%03d" % [prefix, RunState.day_index, attempt]
		if not used.has(candidate):
			return candidate
		attempt += 1
	return "%s_%d_%d" % [prefix, RunState.day_index, Time.get_ticks_msec()]


static func build_life_dividend_projection(gm) -> Dictionary:
	var rows: Array = []
	var declared_total: float = 0.0
	var dividend_snapshot: Dictionary = gm.get_corporate_dividend_snapshot()
	var current_day_number: int = RunState.day_index + 1
	var cutoff_day_number: int = current_day_number + 252
	for row_value in dividend_snapshot.get("declared_rows", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var payment_day_number: int = int(row.get("payment_day_number", 0))
		if payment_day_number < current_day_number or payment_day_number > cutoff_day_number:
			continue
		var projected_amount: float = max(float(row.get("projected_amount", 0.0)), 0.0)
		if projected_amount <= 0.0:
			continue
		declared_total += projected_amount
		rows.append({
			"company_id": str(row.get("company_id", "")),
			"ticker": str(row.get("ticker", "")),
			"eligible_shares": int(row.get("eligible_shares", 0)),
			"amount_per_share": float(row.get("amount_per_share", 0.0)),
			"payment_day_number": payment_day_number,
			"projected_amount": projected_amount,
			"monthly_income": projected_amount / 12.0,
			"status": str(row.get("status", ""))
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("monthly_income", 0.0)) > float(b.get("monthly_income", 0.0))
	)
	return {
		"estimated_monthly_dividends": declared_total / 12.0,
		"declared_dividend_total_12m": declared_total,
		"rows": rows
	}


static func debug_force_hospital_stress(gm) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var life_state: Dictionary = RunState.get_player_life()
	if int(life_state.get("hospital_days_remaining", 0)) > 0:
		return {"success": false, "message": "Hospital recovery is already active."}
	life_state["stress_value"] = 100.0
	life_state["hospital_days_remaining"] = RunState.LIFE_HOSPITAL_TRADING_DAYS
	life_state["hospital_started_day_index"] = RunState.day_index
	life_state["last_hospital_trade_date"] = RunState.get_current_trade_date()
	life_state["burnout_risk_active"] = false
	life_state["burnout_risk_days_remaining"] = 0
	life_state["updated_day_index"] = RunState.day_index
	life_state["updated_trade_date"] = RunState.get_current_trade_date()
	RunState.set_player_life(life_state)
	var updated_life_state: Dictionary = RunState.get_player_life()
	var hospital_days: int = int(updated_life_state.get("hospital_days_remaining", 0))
	var result: Dictionary = {
		"success": true,
		"message": "Debug hospital: stress set to 100 and hospital recovery started for %d day(s)." % hospital_days,
		"hospital_started": true,
		"hospital_days_remaining": hospital_days,
		"stress_value": float(updated_life_state.get("stress_value", RunState.LIFE_DEFAULT_STRESS_VALUE)),
		"happiness_value": float(updated_life_state.get("happiness_value", RunState.LIFE_DEFAULT_HAPPINESS_VALUE)),
		"stress_stage": RunState.get_life_stress_stage(updated_life_state)
	}
	RunState.last_day_results["life_wellbeing"] = result.duplicate(true)
	gm._invalidate_daily_activity_snapshot_cache()
	gm._request_autosave("debug_force_hospital_stress")
	gm.daily_actions_changed.emit()
	gm.life_changed.emit()
	return result
