class_name LifeStateSystem
extends RefCounted

# Pure life-simulation dictionary logic extracted from the RunState autoload.
# The `player_life` state itself stays in RunState (so the save format is
# unchanged); these static helpers only build, normalize and mutate the life
# dictionaries. Run context (day_index, run_seed, trade_date, cash) is always
# passed in explicitly.

const STABLE_RNG = preload("res://systems/StableRng.gd")

const CASH_STRESS_GRACE_TRADING_DAYS := 3
const EMERGENCY_LOAN_PAYMENT_COUNT := 6
const EMERGENCY_LOAN_REPAYMENT_MULTIPLIER := 1.24
const MAX_LIFE_FINANCE_HISTORY := 24
const LIFE_BASICS_TIER_IDS := ["bare", "lean", "stable", "comfortable"]
const LIFE_DEFAULT_BASICS_TIER_ID := "stable"
const LIFE_DEFAULT_STRESS_VALUE := 20.0
const LIFE_DEFAULT_HAPPINESS_VALUE := 65.0
const LIFE_BURNOUT_WARNING_TRADING_DAYS := 2
const LIFE_HOSPITAL_TRADING_DAYS := 2
const LIFE_LEGAL_HOLD_MAX_TRADING_DAYS := 5
const LEGACY_BODETABEK_LIFE_LOCATION_IDS := ["bogor", "depok", "tangerang", "bekasi", "karawang"]


static func default_life_state(day_index: int) -> Dictionary:
	return {
		"housing_id": "kost_room",
		"lifestyle_id": "balanced",
		"basics_tier_id": LIFE_DEFAULT_BASICS_TIER_ID,
		"monthly_extra": 0.0,
		"properties": [],
		"cars": [],
		"development_leads": [],
		"stress_value": LIFE_DEFAULT_STRESS_VALUE,
		"happiness_value": LIFE_DEFAULT_HAPPINESS_VALUE,
		"burnout_risk_active": false,
		"burnout_risk_days_remaining": 0,
		"hospital_days_remaining": 0,
		"hospital_started_day_index": -1,
		"last_hospital_trade_date": {},
		"legal_state": default_life_legal_state(),
		"updated_day_index": day_index,
		"last_obligation_period": "",
		"last_obligation_day_index": -1,
		"last_obligation_amount": 0.0,
		"finance": default_life_finance_state()
}


static func default_life_legal_state() -> Dictionary:
	return {
		"active": false,
		"status": "clear",
		"days_remaining": 0,
		"case_id": "",
		"target_company_id": "",
		"target_ticker": "",
		"started_day_index": -1,
		"release_day_index": -1,
		"released_day_index": -1,
		"fine_amount": 0.0,
		"reason": ""
	}


static func default_life_finance_state() -> Dictionary:
	return {
		"cash_stress_active": false,
		"cash_stress_started_day_index": -1,
		"cash_stress_deadline_day_index": -1,
		"cash_stress_started_cash": 0.0,
		"cash_stress_started_trade_date": {},
		"current_cash_deficit": 0.0,
		"last_cash_stress_resolved_day_index": -1,
		"last_cash_stress_resolved_trade_date": {},
		"active_loan": {},
		"active_bank_loan": {},
		"finance_history": [],
		"bankrupt": false,
		"bankruptcy": {}
	}


static func normalize_life_state(source_life: Variant, day_index: int, run_seed: int) -> Dictionary:
	var normalized: Dictionary = default_life_state(day_index)
	if typeof(source_life) != TYPE_DICTIONARY:
		return normalized

	var source: Dictionary = source_life
	var housing_id: String = str(source.get("housing_id", normalized.get("housing_id", "")))
	if not (housing_id in ["family_home", "kost_room", "apartment"]):
		housing_id = str(normalized.get("housing_id", "kost_room"))
	var lifestyle_id: String = str(source.get("lifestyle_id", normalized.get("lifestyle_id", "")))
	if not (lifestyle_id in ["frugal", "balanced", "status"]):
		lifestyle_id = str(normalized.get("lifestyle_id", "balanced"))
	var basics_tier_id: String = str(source.get("basics_tier_id", normalized.get("basics_tier_id", "")))
	if not (basics_tier_id in LIFE_BASICS_TIER_IDS):
		basics_tier_id = str(normalized.get("basics_tier_id", LIFE_DEFAULT_BASICS_TIER_ID))
	normalized["housing_id"] = housing_id
	normalized["lifestyle_id"] = lifestyle_id
	normalized["basics_tier_id"] = basics_tier_id
	normalized["monthly_extra"] = max(float(source.get("monthly_extra", 0.0)), 0.0)
	normalized["properties"] = normalize_life_properties(source.get("properties", []), day_index, run_seed)
	normalized["cars"] = normalize_life_cars(source.get("cars", []), day_index)
	normalized["development_leads"] = normalize_life_development_leads(source.get("development_leads", []), day_index, run_seed)
	normalized["stress_value"] = clamp(float(source.get("stress_value", LIFE_DEFAULT_STRESS_VALUE)), 0.0, 100.0)
	normalized["happiness_value"] = clamp(float(source.get("happiness_value", LIFE_DEFAULT_HAPPINESS_VALUE)), 0.0, 100.0)
	normalized["burnout_risk_active"] = bool(source.get("burnout_risk_active", false))
	normalized["burnout_risk_days_remaining"] = clampi(int(source.get("burnout_risk_days_remaining", 0)), 0, LIFE_BURNOUT_WARNING_TRADING_DAYS)
	normalized["hospital_days_remaining"] = clampi(int(source.get("hospital_days_remaining", 0)), 0, LIFE_HOSPITAL_TRADING_DAYS)
	normalized["hospital_started_day_index"] = int(source.get("hospital_started_day_index", -1))
	if int(normalized.get("hospital_days_remaining", 0)) > 0:
		normalized["burnout_risk_active"] = false
		normalized["burnout_risk_days_remaining"] = 0
	else:
		normalized["hospital_started_day_index"] = -1
		if not bool(normalized.get("burnout_risk_active", false)):
			normalized["burnout_risk_days_remaining"] = 0
	normalized["updated_day_index"] = max(int(source.get("updated_day_index", day_index)), 0)
	normalized["last_obligation_period"] = str(source.get("last_obligation_period", ""))
	normalized["last_obligation_day_index"] = int(source.get("last_obligation_day_index", -1))
	normalized["last_obligation_amount"] = max(float(source.get("last_obligation_amount", 0.0)), 0.0)
	if source.has("updated_trade_date") and typeof(source.get("updated_trade_date")) == TYPE_DICTIONARY:
		normalized["updated_trade_date"] = source.get("updated_trade_date", {}).duplicate(true)
	if source.has("last_obligation_trade_date") and typeof(source.get("last_obligation_trade_date")) == TYPE_DICTIONARY:
		normalized["last_obligation_trade_date"] = source.get("last_obligation_trade_date", {}).duplicate(true)
	if source.has("last_hospital_trade_date") and typeof(source.get("last_hospital_trade_date")) == TYPE_DICTIONARY:
		normalized["last_hospital_trade_date"] = source.get("last_hospital_trade_date", {}).duplicate(true)
	normalized["legal_state"] = normalize_life_legal_state(source.get("legal_state", {}))
	normalized["finance"] = normalize_life_finance_state(source.get("finance", {}), day_index)
	return normalized


static func normalize_life_location_id(location_id: String, run_seed: int, seed_key: String = "") -> String:
	var normalized_location_id: String = location_id.strip_edges().to_lower()
	if normalized_location_id == "bodetabek" or normalized_location_id == "jabodetabek":
		var index: int = int(STABLE_RNG.seed_from_parts([run_seed, "legacy_life_location", seed_key, normalized_location_id]) % LEGACY_BODETABEK_LIFE_LOCATION_IDS.size())
		return str(LEGACY_BODETABEK_LIFE_LOCATION_IDS[index])
	if normalized_location_id == "bali":
		return "denpasar"
	if normalized_location_id.is_empty():
		return "jakarta"
	return normalized_location_id


static func life_location_label_for_normalized_id(location_id: String, fallback_label: String = "") -> String:
	var clean_fallback: String = fallback_label.strip_edges()
	if clean_fallback.to_lower().find("bodetabek") < 0 and clean_fallback.to_lower().find("jabodetabek") < 0 and not clean_fallback.is_empty():
		return clean_fallback
	match location_id:
		"bogor":
			return "Bogor"
		"depok":
			return "Depok"
		"tangerang":
			return "Tangerang"
		"bekasi":
			return "Bekasi"
		"karawang":
			return "Karawang"
		"bandung":
			return "Bandung"
		"surabaya":
			return "Surabaya"
		"bali":
			return "Bali"
		"denpasar":
			return "Denpasar"
	return "Jakarta" if location_id.is_empty() or location_id == "jakarta" else location_id.replace("_", " ").capitalize()


static func sanitize_legacy_life_location_text(text_value: String, location_id: String) -> String:
	var clean_text: String = text_value.strip_edges()
	if clean_text.is_empty():
		return ""
	var location_label: String = life_location_label_for_normalized_id(location_id)
	for legacy_label in ["Jabodetabek", "jabodetabek", "Bodetabek", "bodetabek"]:
		clean_text = clean_text.replace(str(legacy_label), location_label)
	return clean_text


static func normalize_life_properties(source_properties: Variant, day_index: int, run_seed: int) -> Array:
	var rows: Array = []
	if typeof(source_properties) != TYPE_ARRAY:
		return rows
	var saw_primary: bool = false
	for property_value in source_properties:
		if typeof(property_value) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = property_value
		var property_id: String = str(source.get("id", ""))
		if property_id.is_empty():
			property_id = "property_%d_%d" % [int(source.get("purchased_day_index", day_index)), rows.size()]
		var current_value: float = max(float(source.get("current_value", source.get("purchase_price", 0.0))), 0.0)
		var purchase_price: float = max(float(source.get("purchase_price", current_value)), 0.0)
		var base_value: float = max(float(source.get("base_value", purchase_price if purchase_price > 0.0 else current_value)), 0.0)
		var is_primary: bool = bool(source.get("is_primary", false)) and not saw_primary
		var location_id: String = normalize_life_location_id(str(source.get("location_id", "jakarta")), run_seed, property_id)
		if is_primary:
			saw_primary = true
		rows.append({
			"id": property_id,
			"catalog_id": str(source.get("catalog_id", "")),
			"location_id": location_id,
			"label": str(source.get("label", "")),
			"location_label": life_location_label_for_normalized_id(location_id, str(source.get("location_label", ""))),
			"purchase_price": purchase_price,
			"base_value": base_value,
			"current_value": current_value,
			"monthly_upkeep": max(float(source.get("monthly_upkeep", 0.0)), 0.0),
			"rent_income": max(float(source.get("rent_income", 0.0)), 0.0),
			"rented_out": bool(source.get("rented_out", false)) and not is_primary,
			"is_primary": is_primary,
			"stress_delta": float(source.get("stress_delta", 0.0)),
			"happiness_delta": float(source.get("happiness_delta", 0.0)),
			"status_value": max(float(source.get("status_value", 0.0)), 0.0),
			"value_events": normalize_life_property_value_events(source.get("value_events", []), day_index),
			"priced_in_lead_ids": normalize_string_array(source.get("priced_in_lead_ids", [])),
			"purchased_day_index": int(source.get("purchased_day_index", day_index)),
			"purchased_trade_date": source.get("purchased_trade_date", {}).duplicate(true) if typeof(source.get("purchased_trade_date", {})) == TYPE_DICTIONARY else {}
		})
	return rows


static func normalize_life_property_value_events(source_events: Variant, day_index: int) -> Array:
	var rows: Array = []
	if typeof(source_events) != TYPE_ARRAY:
		return rows
	for event_value in source_events:
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = event_value
		var lead_id: String = str(source.get("lead_id", ""))
		if lead_id.is_empty():
			continue
		rows.append({
			"lead_id": lead_id,
			"label": str(source.get("label", "")),
			"theme": str(source.get("theme", "")),
			"theme_label": str(source.get("theme_label", "")),
			"source_type": str(source.get("source_type", "")),
			"outcome": str(source.get("outcome", "")),
			"multiplier": max(float(source.get("multiplier", 1.0)), 0.0),
			"old_value": max(float(source.get("old_value", 0.0)), 0.0),
			"new_value": max(float(source.get("new_value", 0.0)), 0.0),
			"day_index": int(source.get("day_index", day_index)),
			"trade_date": source.get("trade_date", {}).duplicate(true) if typeof(source.get("trade_date", {})) == TYPE_DICTIONARY else {}
		})
	return rows


static func normalize_life_development_leads(source_leads: Variant, day_index: int, run_seed: int) -> Array:
	var rows: Array = []
	if typeof(source_leads) != TYPE_ARRAY:
		return rows
	var seen: Dictionary = {}
	for lead_value in source_leads:
		if typeof(lead_value) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = lead_value
		var lead_id: String = str(source.get("id", ""))
		if lead_id.is_empty():
			lead_id = "development_%d_%d" % [int(source.get("discovered_day_index", day_index)), rows.size()]
		if seen.has(lead_id):
			continue
		seen[lead_id] = true
		var stage: String = str(source.get("stage", "rumor"))
		if not (stage in ["rumor", "permit_watch", "confirmed", "delayed", "cancelled"]):
			stage = "rumor"
		var outcome: String = str(source.get("outcome", ""))
		if outcome.is_empty() and bool(source.get("resolved", false)):
			outcome = stage
		var clarity_level: int = clamp(int(source.get("clarity_level", 4 if str(source.get("source_type", "")) == "network" else 1)), 1, 4)
		var location_id: String = normalize_life_location_id(str(source.get("location_id", "jakarta")), run_seed, lead_id)
		rows.append({
			"id": lead_id,
			"dedupe_key": str(source.get("dedupe_key", "")),
			"location_id": location_id,
			"location_label": life_location_label_for_normalized_id(location_id, str(source.get("location_label", ""))),
			"theme": str(source.get("theme", "modern_city")),
			"theme_label": str(source.get("theme_label", "")),
			"source_type": str(source.get("source_type", "")),
			"source_id": str(source.get("source_id", "")),
			"source_label": sanitize_legacy_life_location_text(str(source.get("source_label", "")), location_id),
			"source_note": sanitize_legacy_life_location_text(str(source.get("source_note", "")), location_id),
			"contact_id": str(source.get("contact_id", "")),
			"contact_name": str(source.get("contact_name", "")),
			"discovered_day_index": int(source.get("discovered_day_index", day_index)),
			"discovered_trade_date": source.get("discovered_trade_date", {}).duplicate(true) if typeof(source.get("discovered_trade_date", {})) == TYPE_DICTIONARY else {},
			"stage": stage,
			"reliability": clamp(float(source.get("reliability", 50.0)), 0.0, 100.0),
			"clarity_level": clarity_level,
			"clarity_label": str(source.get("clarity_label", "")),
			"display_location_label": sanitize_legacy_life_location_text(str(source.get("display_location_label", "")), location_id),
			"display_theme_label": str(source.get("display_theme_label", "")),
			"impact_tier": str(source.get("impact_tier", "moderate")),
			"due_day_index": int(source.get("due_day_index", int(source.get("discovered_day_index", day_index)) + 5)),
			"resolved": bool(source.get("resolved", false)),
			"outcome": outcome,
			"value_multiplier": max(float(source.get("value_multiplier", 1.0)), 0.0),
			"public_confirmed": bool(source.get("public_confirmed", false)),
			"applied_property_ids": normalize_string_array(source.get("applied_property_ids", [])),
			"delay_count": max(int(source.get("delay_count", 0)), 0),
			"outcome_override": str(source.get("outcome_override", ""))
		})
	return rows


static func normalize_string_array(source_values: Variant) -> Array:
	var rows: Array = []
	if typeof(source_values) != TYPE_ARRAY:
		return rows
	var seen: Dictionary = {}
	for value in source_values:
		var text: String = str(value).strip_edges()
		if text.is_empty() or seen.has(text):
			continue
		seen[text] = true
		rows.append(text)
	return rows


static func normalize_life_cars(source_cars: Variant, day_index: int) -> Array:
	var rows: Array = []
	if typeof(source_cars) != TYPE_ARRAY:
		return rows
	var saw_active: bool = false
	for car_value in source_cars:
		if typeof(car_value) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = car_value
		var car_id: String = str(source.get("id", ""))
		if car_id.is_empty():
			car_id = "car_%d_%d" % [int(source.get("purchased_day_index", day_index)), rows.size()]
		var current_value: float = max(float(source.get("current_value", source.get("purchase_price", 0.0))), 0.0)
		var is_active: bool = bool(source.get("is_active", false)) and not saw_active
		if is_active:
			saw_active = true
		rows.append({
			"id": car_id,
			"catalog_id": str(source.get("catalog_id", "")),
			"label": str(source.get("label", "")),
			"purchase_price": max(float(source.get("purchase_price", current_value)), 0.0),
			"current_value": current_value,
			"monthly_upkeep": max(float(source.get("monthly_upkeep", 0.0)), 0.0),
			"status_value": max(float(source.get("status_value", 0.0)), 0.0),
			"stress_delta": float(source.get("stress_delta", 0.0)),
			"happiness_delta": float(source.get("happiness_delta", 0.0)),
			"is_active": is_active,
			"purchased_day_index": int(source.get("purchased_day_index", day_index)),
			"purchased_trade_date": source.get("purchased_trade_date", {}).duplicate(true) if typeof(source.get("purchased_trade_date", {})) == TYPE_DICTIONARY else {}
		})
	return rows


static func normalize_life_legal_state(source_legal: Variant) -> Dictionary:
	var normalized: Dictionary = default_life_legal_state()
	if typeof(source_legal) != TYPE_DICTIONARY:
		return normalized
	var source: Dictionary = source_legal
	normalized["active"] = bool(source.get("active", false))
	normalized["status"] = str(source.get("status", "held" if normalized.get("active", false) else "clear"))
	normalized["days_remaining"] = clampi(int(source.get("days_remaining", 0)), 0, LIFE_LEGAL_HOLD_MAX_TRADING_DAYS)
	normalized["case_id"] = str(source.get("case_id", ""))
	normalized["target_company_id"] = str(source.get("target_company_id", ""))
	normalized["target_ticker"] = str(source.get("target_ticker", ""))
	normalized["started_day_index"] = int(source.get("started_day_index", -1))
	normalized["release_day_index"] = int(source.get("release_day_index", -1))
	normalized["released_day_index"] = int(source.get("released_day_index", -1))
	normalized["fine_amount"] = max(float(source.get("fine_amount", 0.0)), 0.0)
	normalized["reason"] = str(source.get("reason", ""))
	if int(normalized.get("days_remaining", 0)) <= 0:
		normalized["active"] = false
		if str(normalized.get("status", "")) == "held":
			normalized["status"] = "released"
	else:
		normalized["active"] = true
		if str(normalized.get("status", "")).is_empty() or str(normalized.get("status", "")) == "clear":
			normalized["status"] = "held"
	return normalized


static func normalize_life_finance_state(source_finance: Variant, day_index: int) -> Dictionary:
	var normalized: Dictionary = default_life_finance_state()
	if typeof(source_finance) != TYPE_DICTIONARY:
		return normalized

	var source: Dictionary = source_finance
	normalized["cash_stress_active"] = bool(source.get("cash_stress_active", false))
	normalized["cash_stress_started_day_index"] = int(source.get("cash_stress_started_day_index", -1))
	normalized["cash_stress_deadline_day_index"] = int(source.get("cash_stress_deadline_day_index", -1))
	normalized["cash_stress_started_cash"] = float(source.get("cash_stress_started_cash", 0.0))
	normalized["current_cash_deficit"] = max(float(source.get("current_cash_deficit", 0.0)), 0.0)
	normalized["last_cash_stress_resolved_day_index"] = int(source.get("last_cash_stress_resolved_day_index", -1))
	normalized["bankrupt"] = bool(source.get("bankrupt", false))
	if typeof(source.get("cash_stress_started_trade_date", {})) == TYPE_DICTIONARY:
		normalized["cash_stress_started_trade_date"] = source.get("cash_stress_started_trade_date", {}).duplicate(true)
	if typeof(source.get("last_cash_stress_resolved_trade_date", {})) == TYPE_DICTIONARY:
		normalized["last_cash_stress_resolved_trade_date"] = source.get("last_cash_stress_resolved_trade_date", {}).duplicate(true)
	if typeof(source.get("active_loan", {})) == TYPE_DICTIONARY:
		normalized["active_loan"] = normalize_life_loan(source.get("active_loan", {}), day_index)
	if typeof(source.get("active_bank_loan", {})) == TYPE_DICTIONARY:
		normalized["active_bank_loan"] = normalize_life_bank_loan(source.get("active_bank_loan", {}), day_index)
	if typeof(source.get("bankruptcy", {})) == TYPE_DICTIONARY:
		normalized["bankruptcy"] = source.get("bankruptcy", {}).duplicate(true)
	var history: Array = []
	if typeof(source.get("finance_history", [])) == TYPE_ARRAY:
		for history_value in source.get("finance_history", []):
			if typeof(history_value) == TYPE_DICTIONARY:
				history.append(history_value.duplicate(true))
	if history.size() > MAX_LIFE_FINANCE_HISTORY:
		history = history.slice(history.size() - MAX_LIFE_FINANCE_HISTORY, history.size())
	normalized["finance_history"] = history
	if not bool(normalized.get("cash_stress_active", false)):
		normalized["cash_stress_started_day_index"] = -1
		normalized["cash_stress_deadline_day_index"] = -1
		normalized["cash_stress_started_cash"] = 0.0
		normalized["cash_stress_started_trade_date"] = {}
	return normalized


static func normalize_life_loan(source_loan: Variant, day_index: int) -> Dictionary:
	if typeof(source_loan) != TYPE_DICTIONARY:
		return {}
	var source: Dictionary = source_loan
	if source.is_empty():
		return {}
	var principal: float = max(float(source.get("principal", 0.0)), 0.0)
	var payment_count: int = max(int(source.get("payment_count", EMERGENCY_LOAN_PAYMENT_COUNT)), 1)
	var total_repayment: float = max(float(source.get("total_repayment", principal * EMERGENCY_LOAN_REPAYMENT_MULTIPLIER)), principal)
	var monthly_payment: float = max(float(source.get("monthly_payment", total_repayment / float(payment_count))), 0.0)
	var loan: Dictionary = {
		"id": str(source.get("id", "")),
		"state": str(source.get("state", "active")),
		"principal": principal,
		"total_repayment": total_repayment,
		"monthly_payment": monthly_payment,
		"payment_count": payment_count,
		"payments_remaining": clampi(int(source.get("payments_remaining", payment_count)), 0, payment_count),
		"amount_paid": max(float(source.get("amount_paid", 0.0)), 0.0),
		"repayment_multiplier": max(float(source.get("repayment_multiplier", EMERGENCY_LOAN_REPAYMENT_MULTIPLIER)), 1.0),
		"started_day_index": int(source.get("started_day_index", day_index)),
		"last_payment_period": str(source.get("last_payment_period", ""))
	}
	if typeof(source.get("started_trade_date", {})) == TYPE_DICTIONARY:
		loan["started_trade_date"] = source.get("started_trade_date", {}).duplicate(true)
	if source.has("last_payment_day_index"):
		loan["last_payment_day_index"] = int(source.get("last_payment_day_index", -1))
	if typeof(source.get("last_payment_trade_date", {})) == TYPE_DICTIONARY:
		loan["last_payment_trade_date"] = source.get("last_payment_trade_date", {}).duplicate(true)
	if source.has("completed_day_index"):
		loan["completed_day_index"] = int(source.get("completed_day_index", -1))
	if typeof(source.get("completed_trade_date", {})) == TYPE_DICTIONARY:
		loan["completed_trade_date"] = source.get("completed_trade_date", {}).duplicate(true)
	if principal <= 0.0 or int(loan.get("payments_remaining", 0)) <= 0:
		return {}
	return loan


static func normalize_life_bank_loan(source_loan: Variant, day_index: int) -> Dictionary:
	if typeof(source_loan) != TYPE_DICTIONARY:
		return {}
	var source: Dictionary = source_loan
	if source.is_empty():
		return {}
	var state: String = str(source.get("state", "active"))
	if state == "paid" or state == "completed" or state == "closed":
		return {}
	var lender_id: String = str(source.get("lender_id", "")).strip_edges()
	if lender_id.is_empty():
		return {}
	var principal: float = max(float(source.get("principal", 0.0)), 0.0)
	var repayment_multiplier: float = max(float(source.get("repayment_multiplier", 1.0)), 1.0)
	var payment_count: int = max(int(source.get("payment_count", 1)), 1)
	var total_repayment: float = max(float(source.get("total_repayment", principal * repayment_multiplier)), principal)
	var monthly_payment: float = max(float(source.get("monthly_payment", total_repayment / float(payment_count))), 0.0)
	var loan: Dictionary = {
		"id": str(source.get("id", "")),
		"type": "regular_bank_loan",
		"state": "active",
		"offer_id": str(source.get("offer_id", "")),
		"lender_id": lender_id,
		"lender_ticker": str(source.get("lender_ticker", "")),
		"lender_name": str(source.get("lender_name", "")),
		"lender_subsector": str(source.get("lender_subsector", "")),
		"risk_tier": str(source.get("risk_tier", "")),
		"principal": principal,
		"total_repayment": total_repayment,
		"monthly_payment": monthly_payment,
		"payment_count": payment_count,
		"payments_remaining": clampi(int(source.get("payments_remaining", payment_count)), 0, payment_count),
		"amount_paid": max(float(source.get("amount_paid", 0.0)), 0.0),
		"repayment_multiplier": repayment_multiplier,
		"started_day_index": int(source.get("started_day_index", source.get("start_day_index", day_index))),
		"last_payment_period": str(source.get("last_payment_period", ""))
	}
	if loan.get("id", "") == "":
		loan["id"] = "bank_loan_%d_%s_%d" % [
			int(loan.get("started_day_index", day_index)),
			lender_id,
			int(round(principal))
		]
	if typeof(source.get("started_trade_date", source.get("start_trade_date", {}))) == TYPE_DICTIONARY:
		loan["started_trade_date"] = source.get("started_trade_date", source.get("start_trade_date", {})).duplicate(true)
	if source.has("last_payment_day_index"):
		loan["last_payment_day_index"] = int(source.get("last_payment_day_index", -1))
	if typeof(source.get("last_payment_trade_date", {})) == TYPE_DICTIONARY:
		loan["last_payment_trade_date"] = source.get("last_payment_trade_date", {}).duplicate(true)
	if source.has("completed_day_index"):
		loan["completed_day_index"] = int(source.get("completed_day_index", -1))
	if typeof(source.get("completed_trade_date", {})) == TYPE_DICTIONARY:
		loan["completed_trade_date"] = source.get("completed_trade_date", {}).duplicate(true)
	if principal <= 0.0 or int(loan.get("payments_remaining", 0)) <= 0:
		return {}
	return loan


static func append_life_finance_history(finance: Dictionary, row: Dictionary) -> void:
	var history: Array = finance.get("finance_history", [])
	if typeof(history) != TYPE_ARRAY:
		history = []
	history.append(row.duplicate(true))
	if history.size() > MAX_LIFE_FINANCE_HISTORY:
		history = history.slice(history.size() - MAX_LIFE_FINANCE_HISTORY, history.size())
	finance["finance_history"] = history


static func stress_ap_penalty(life_state: Dictionary) -> int:
	var stress_value: float = float(life_state.get("stress_value", LIFE_DEFAULT_STRESS_VALUE))
	if stress_value >= 100.0:
		return 4
	if stress_value >= 80.0:
		return 3
	if stress_value >= 60.0:
		return 2
	if stress_value >= 40.0:
		return 1
	return 0


static func stress_stage(life_state: Dictionary) -> Dictionary:
	var stress_value: float = float(life_state.get("stress_value", LIFE_DEFAULT_STRESS_VALUE))
	if int(life_state.get("hospital_days_remaining", 0)) > 0:
		return {"id": "hospital", "label": "Hospitalized", "severity": 5}
	if bool(life_state.get("burnout_risk_active", false)):
		return {"id": "burnout_risk", "label": "Burnout Risk", "severity": 4}
	if stress_value >= 80.0:
		return {"id": "strained", "label": "Strained", "severity": 3}
	if stress_value >= 60.0:
		return {"id": "stressed", "label": "Stressed", "severity": 2}
	if stress_value >= 40.0:
		return {"id": "tense", "label": "Tense", "severity": 1}
	return {"id": "calm", "label": "Calm", "severity": 0}


static func update_cash_stress(finance: Dictionary, cash: float, day_index: int, trade_date: Dictionary) -> void:
	if cash < 0.0:
		if not bool(finance.get("cash_stress_active", false)):
			finance["cash_stress_active"] = true
			finance["cash_stress_started_day_index"] = day_index
			finance["cash_stress_deadline_day_index"] = day_index + CASH_STRESS_GRACE_TRADING_DAYS
			finance["cash_stress_started_cash"] = cash
			finance["cash_stress_started_trade_date"] = trade_date.duplicate(true)
		finance["current_cash_deficit"] = absf(cash)
	else:
		if bool(finance.get("cash_stress_active", false)):
			finance["last_cash_stress_resolved_day_index"] = day_index
			finance["last_cash_stress_resolved_trade_date"] = trade_date.duplicate(true)
		finance["cash_stress_active"] = false
		finance["cash_stress_started_day_index"] = -1
		finance["cash_stress_deadline_day_index"] = -1
		finance["cash_stress_started_cash"] = 0.0
		finance["cash_stress_started_trade_date"] = {}
		finance["current_cash_deficit"] = 0.0


static func start_emergency_loan(finance: Dictionary, principal: float, detail: Dictionary, day_index: int, trade_date: Dictionary) -> Dictionary:
	var payment_count: int = max(int(detail.get("payment_count", EMERGENCY_LOAN_PAYMENT_COUNT)), 1)
	var repayment_multiplier: float = max(float(detail.get("repayment_multiplier", EMERGENCY_LOAN_REPAYMENT_MULTIPLIER)), 1.0)
	var total_repayment: float = max(float(detail.get("total_repayment", principal * repayment_multiplier)), principal)
	var monthly_payment: float = max(float(detail.get("monthly_payment", total_repayment / float(payment_count))), 0.0)
	var loan_id: String = "life_loan_%d_%d" % [day_index, int(round(principal))]
	var loan: Dictionary = {
		"id": loan_id,
		"state": "active",
		"principal": principal,
		"total_repayment": total_repayment,
		"monthly_payment": monthly_payment,
		"payment_count": payment_count,
		"payments_remaining": payment_count,
		"amount_paid": 0.0,
		"repayment_multiplier": repayment_multiplier,
		"started_day_index": day_index,
		"started_trade_date": trade_date.duplicate(true),
		"last_payment_period": ""
	}
	finance["active_loan"] = loan
	append_life_finance_history(finance, {
		"type": "loan_started",
		"loan_id": loan_id,
		"amount": principal,
		"day_index": day_index,
		"trade_date": trade_date.duplicate(true)
	})
	return loan


static func start_bank_loan(finance: Dictionary, offer_id: String, principal: float, detail: Dictionary, day_index: int, trade_date: Dictionary) -> Dictionary:
	var normalized_principal: float = max(principal, 0.0)
	var payment_count: int = max(int(detail.get("payment_count", 1)), 1)
	var repayment_multiplier: float = max(float(detail.get("repayment_multiplier", 1.0)), 1.0)
	var total_repayment: float = max(float(detail.get("total_repayment", normalized_principal * repayment_multiplier)), normalized_principal)
	var monthly_payment: float = max(float(detail.get("monthly_payment", total_repayment / float(payment_count))), 0.0)
	var lender_id: String = str(detail.get("lender_id", "")).strip_edges()
	var loan_id: String = "bank_loan_%d_%s_%d" % [day_index, lender_id, int(round(normalized_principal))]
	var loan: Dictionary = {
		"id": loan_id,
		"type": "regular_bank_loan",
		"state": "active",
		"offer_id": offer_id,
		"lender_id": lender_id,
		"lender_ticker": str(detail.get("lender_ticker", "")),
		"lender_name": str(detail.get("lender_name", "")),
		"lender_subsector": str(detail.get("lender_subsector", "")),
		"risk_tier": str(detail.get("risk_tier", "")),
		"principal": normalized_principal,
		"total_repayment": total_repayment,
		"monthly_payment": monthly_payment,
		"payment_count": payment_count,
		"payments_remaining": payment_count,
		"amount_paid": 0.0,
		"repayment_multiplier": repayment_multiplier,
		"started_day_index": day_index,
		"started_trade_date": trade_date.duplicate(true),
		"last_payment_period": ""
	}
	finance["active_bank_loan"] = loan
	append_life_finance_history(finance, {
		"type": "bank_loan_started",
		"loan_id": loan_id,
		"offer_id": offer_id,
		"lender_id": lender_id,
		"lender_ticker": str(detail.get("lender_ticker", "")),
		"amount": normalized_principal,
		"day_index": day_index,
		"trade_date": trade_date.duplicate(true)
	})
	return loan
