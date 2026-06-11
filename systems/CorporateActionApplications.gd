extends RefCounted
class_name CorporateActionApplications
## Corporate-action application bodies moved out of RunState.
## `state` is the RunState autoload instance (untyped to avoid a cyclic reference).


static func apply_rights_issue_application(state, application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not state.companies.has(company_id):
		return
	var new_shares: float = max(float(application.get("new_shares", 0.0)), 0.0)
	if new_shares <= 0.0:
		return
	var definition: Dictionary = state.get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = state.companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var gross_proceeds: float = max(float(application.get("gross_proceeds", 0.0)), 0.0)
	var new_shares_outstanding: float = max(float(application.get("new_shares_outstanding", old_shares_outstanding + new_shares)), 1.0)
	var theoretical_price: float = float(application.get("theoretical_ex_rights_price", 0.0))
	if theoretical_price <= 0.0:
		theoretical_price = (old_price * old_shares_outstanding + gross_proceeds) / new_shares_outstanding
	var max_down: float = clamp(float(application.get("maximum_price_adjustment_down_pct", 0.35)), 0.0, 0.9)
	var max_up: float = clamp(float(application.get("maximum_price_adjustment_up_pct", 0.08)), 0.0, 0.5)
	var price_factor: float = clamp(theoretical_price / old_price, 1.0 - max_down, 1.0 + max_up)
	if bool(application.get("linked_backdoor_listing", false)):
		var strategic_unlock_pct: float = clamp(float(application.get("strategic_funding_unlock_pct", 0.0)), -0.3, 0.3)
		var dilution_overhang_pct: float = clamp(float(application.get("dilution_overhang_pct", application.get("entitlement_ratio", 0.0))), 0.0, 1.0)
		var linked_price_factor: float = 1.0 + strategic_unlock_pct - dilution_overhang_pct * 0.22
		price_factor = clamp(price_factor * linked_price_factor, 1.0 - max_down, 1.0 + max_up)
	var new_price: float = state._apply_company_price_factor(company_id, price_factor, false)
	var free_float_pct: float = float(financials.get("free_float_pct", 35.0))
	var player_record_shares: int = max(int(application.get("player_record_shares", 0)), 0)
	var player_entitled_shares: int = max(int(application.get("player_entitled_shares", 0)), 0)
	var exercise_price: float = max(float(application.get("exercise_price", 0.0)), 0.0)
	var exercise_cost: float = round(float(player_entitled_shares) * exercise_price * 100.0) / 100.0
	var player_status: String = "not_eligible"
	var player_exercised_shares: int = 0
	if player_entitled_shares > 0:
		if exercise_cost <= float(state.player_portfolio.get("cash", 0.0)) + 0.0001:
			player_status = "exercised"
			player_exercised_shares = player_entitled_shares
		else:
			player_status = "lapsed_insufficient_cash"
	state._set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		free_float_pct,
		{
			"type": "rights_issue",
			"chain_id": str(application.get("chain_id", "")),
			"meeting_id": str(application.get("meeting_id", "")),
			"ratio_numerator": int(application.get("ratio_numerator", 1)),
			"ratio_denominator": int(application.get("ratio_denominator", 1)),
			"entitlement_ratio": float(application.get("entitlement_ratio", 0.0)),
			"new_shares": new_shares,
			"exercise_price": exercise_price,
			"gross_proceeds": gross_proceeds,
			"discount_pct": float(application.get("discount_pct", 0.0)),
			"theoretical_ex_rights_price": theoretical_price,
			"old_shares_outstanding": old_shares_outstanding,
			"new_shares_outstanding": new_shares_outstanding,
			"player_record_shares": player_record_shares,
			"player_entitled_shares": player_entitled_shares,
			"player_exercised_shares": player_exercised_shares,
			"player_rights_status": player_status,
			"player_exercise_cost": exercise_cost,
			"linked_backdoor_listing": bool(application.get("linked_backdoor_listing", false)),
			"source_backdoor_chain_id": str(application.get("source_backdoor_chain_id", "")),
			"source_backdoor_application_day": int(application.get("source_backdoor_application_day", 0)),
			"incoming_asset_label": str(application.get("incoming_asset_label", "")),
			"sponsor_label": str(application.get("sponsor_label", "")),
			"post_deal_name": str(application.get("post_deal_name", "")),
			"post_deal_sector_id": str(application.get("post_deal_sector_id", "")),
			"post_deal_sector_name": str(application.get("post_deal_sector_name", "")),
			"funding_purpose": str(application.get("funding_purpose", "")),
			"funding_unlock_score": float(application.get("funding_unlock_score", 0.0)),
			"strategic_funding_unlock_pct": float(application.get("strategic_funding_unlock_pct", 0.0)),
			"dilution_overhang_pct": float(application.get("dilution_overhang_pct", 0.0)),
			"funding_status": str(application.get("funding_status", "")),
			"resolved_price_factor": price_factor,
			"day_index": int(application.get("day_index", state.day_index))
		}
	)
	state._apply_player_rights_issue_entitlement(
		company_id,
		player_entitled_shares,
		exercise_price,
		exercise_cost,
		player_status
	)


static func apply_private_placement_application(state, application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not state.companies.has(company_id):
		return
	var new_shares: float = max(float(application.get("new_shares", 0.0)), 0.0)
	if new_shares <= 0.0:
		return
	var definition: Dictionary = state.get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = state.companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var gross_proceeds: float = max(float(application.get("gross_proceeds", 0.0)), 0.0)
	var new_shares_outstanding: float = old_shares_outstanding + new_shares
	var theoretical_price: float = (old_price * old_shares_outstanding + gross_proceeds) / new_shares_outstanding
	var price_factor: float = clamp(theoretical_price / old_price, 0.65, 1.15)
	var new_price: float = state._apply_company_price_factor(company_id, price_factor, false)
	var old_free_float_pct: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, 0.02, 0.95)
	var new_free_float_pct: float = clamp((old_shares_outstanding * old_free_float_pct) / new_shares_outstanding, 0.02, 0.95) * 100.0
	state._set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		new_free_float_pct,
		{
			"type": "private_placement",
			"chain_id": str(application.get("chain_id", "")),
			"new_shares": new_shares,
			"issue_price": float(application.get("issue_price", 0.0)),
			"gross_proceeds": gross_proceeds,
			"discount_pct": float(application.get("discount_pct", 0.0)),
			"investor_label": str(application.get("investor_label", "")),
			"day_index": int(application.get("day_index", state.day_index))
		}
	)


static func apply_restructuring_application(state, application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not state.companies.has(company_id):
		return
	var definition: Dictionary = state.get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = state.companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var new_shares: float = max(float(application.get("new_shares", 0.0)), 0.0)
	var new_shares_outstanding: float = max(float(application.get("new_shares_outstanding", old_shares_outstanding + new_shares)), 1.0)
	var price_adjustment_pct: float = clamp(float(application.get("price_adjustment_pct", 0.0)), -0.35, 0.35)
	var new_price: float = state._apply_company_price_factor(company_id, 1.0 + price_adjustment_pct, false)
	var new_free_float_pct: float = clamp(float(application.get("new_free_float_pct", financials.get("free_float_pct", 35.0))), 0.0, 100.0)
	var player_result: Dictionary = state._record_player_restructuring_note(
		company_id,
		new_price,
		old_shares_outstanding,
		new_shares_outstanding
	)
	state._set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		new_free_float_pct,
		{
			"type": "restructuring",
			"chain_id": str(application.get("chain_id", "")),
			"plan_type": str(application.get("plan_type", "debt_workout")),
			"plan_label": str(application.get("plan_label", "Debt workout")),
			"debt_reduction_pct": float(application.get("debt_reduction_pct", 0.0)),
			"debt_conversion_pct": float(application.get("debt_conversion_pct", 0.0)),
			"asset_sale_value": float(application.get("asset_sale_value", 0.0)),
			"creditor_support_score": float(application.get("creditor_support_score", 0.0)),
			"credibility_score": float(application.get("credibility_score", 0.0)),
			"distress_score": float(application.get("distress_score", 0.0)),
			"stress_overhang_pct": float(application.get("stress_overhang_pct", 0.0)),
			"suspension_risk_pct": float(application.get("suspension_risk_pct", 0.0)),
			"price_adjustment_pct": price_adjustment_pct,
			"old_price": old_price,
			"new_price": new_price,
			"old_shares_outstanding": old_shares_outstanding,
			"new_shares": new_shares,
			"new_shares_outstanding": new_shares_outstanding,
			"old_free_float_pct": float(application.get("old_free_float_pct", financials.get("free_float_pct", 35.0))),
			"new_free_float_pct": new_free_float_pct,
			"player_shares": int(player_result.get("shares", 0)),
			"player_ownership_before_pct": float(player_result.get("ownership_before_pct", 0.0)),
			"player_ownership_after_pct": float(player_result.get("ownership_after_pct", 0.0)),
			"player_treatment": str(player_result.get("status", "not_held")),
			"day_index": int(application.get("day_index", state.day_index))
		}
	)
	state._apply_company_restructuring_state(company_id, application, player_result)


static func apply_stock_buyback_application(state, application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not state.companies.has(company_id):
		return
	var executed_shares: float = max(float(application.get("executed_shares", application.get("shares_retired", 0.0))), 0.0)
	if executed_shares <= 0.0:
		return
	var definition: Dictionary = state.get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = state.companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	executed_shares = min(executed_shares, max(old_shares_outstanding - 1.0, 0.0))
	if executed_shares <= 0.0:
		return
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var old_free_float_pct: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, 0.02, 0.95)
	var old_free_float_shares: float = max(old_shares_outstanding * old_free_float_pct, 1.0)
	var new_shares_outstanding: float = max(float(application.get("new_shares_outstanding", old_shares_outstanding - executed_shares)), 1.0)
	var new_free_float_pct: float = float(application.get("new_free_float_pct", 0.0))
	if new_free_float_pct <= 0.0:
		var new_free_float_shares: float = max(old_free_float_shares - executed_shares, 1.0)
		new_free_float_pct = clamp(new_free_float_shares / new_shares_outstanding, 0.02, 0.95) * 100.0
	var repurchase_pct: float = clamp(executed_shares / old_shares_outstanding, 0.0, 0.35)
	var premium_pct: float = max(float(application.get("premium_pct", 0.0)), 0.0)
	var price_support_per_pct: float = max(float(application.get("price_support_per_pct", 1.6)), 0.0)
	var maximum_price_support_pct: float = clamp(float(application.get("maximum_price_support_pct", 0.18)), 0.0, 0.5)
	var price_support_pct: float = min(repurchase_pct * price_support_per_pct + premium_pct * 0.25, maximum_price_support_pct)
	var new_price: float = state._apply_company_price_factor(company_id, 1.0 + price_support_pct, false)
	state._set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		new_free_float_pct,
		{
			"type": "stock_buyback",
			"chain_id": str(application.get("chain_id", "")),
			"authorized_shares": int(application.get("authorized_shares", 0)),
			"executed_shares": int(round(executed_shares)),
			"shares_retired": int(round(executed_shares)),
			"buyback_price": float(application.get("buyback_price", old_price)),
			"buyback_budget": float(application.get("buyback_budget", 0.0)),
			"premium_pct": premium_pct,
			"price_support_pct": price_support_pct,
			"old_shares_outstanding": old_shares_outstanding,
			"new_shares_outstanding": new_shares_outstanding,
			"old_free_float_pct": old_free_float_pct * 100.0,
			"new_free_float_pct": new_free_float_pct,
			"day_index": int(application.get("day_index", state.day_index))
		}
	)


static func apply_tender_offer_application(state, application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not state.companies.has(company_id):
		return
	var accepted_shares: float = max(float(application.get("accepted_shares", 0.0)), 0.0)
	if accepted_shares <= 0.0:
		return
	var definition: Dictionary = state.get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = state.companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var old_free_float_pct: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, 0.02, 0.95)
	var old_free_float_shares: float = max(old_shares_outstanding * old_free_float_pct, 1.0)
	accepted_shares = min(accepted_shares, max(old_free_float_shares - 1.0, 0.0))
	if accepted_shares <= 0.0:
		return
	var new_shares_outstanding: float = max(float(application.get("new_shares_outstanding", old_shares_outstanding)), 1.0)
	var new_free_float_pct: float = float(application.get("new_free_float_pct", 0.0))
	if new_free_float_pct <= 0.0:
		var new_free_float_shares: float = max(old_free_float_shares - accepted_shares, 1.0)
		new_free_float_pct = clamp(new_free_float_shares / new_shares_outstanding, 0.02, 0.95) * 100.0
	new_free_float_pct = min(new_free_float_pct, old_free_float_pct * 100.0)
	var premium_pct: float = max(float(application.get("premium_pct", 0.0)), 0.0)
	var price_support_per_pct: float = max(float(application.get("price_support_per_pct", 1.2)), 0.0)
	var maximum_price_support_pct: float = clamp(float(application.get("maximum_price_support_pct", 0.22)), 0.0, 0.6)
	var price_support_pct: float = clamp(float(application.get("price_support_pct", 0.0)), 0.0, maximum_price_support_pct)
	if price_support_pct <= 0.0:
		price_support_pct = min((accepted_shares / old_shares_outstanding) * price_support_per_pct + premium_pct * 0.35, maximum_price_support_pct)
	var new_price: float = state._apply_company_price_factor(company_id, 1.0 + price_support_pct, false)
	var player_result: Dictionary = state._apply_player_tender_offer(
		company_id,
		float(application.get("acceptance_ratio", 0.0)),
		float(application.get("offer_price", old_price)),
		str(application.get("player_tender_choice", "auto_prorata"))
	)
	var aftermath_result: Dictionary = state._build_tender_offer_aftermath_result(application, new_free_float_pct)
	var player_cashout_result: Dictionary = {}
	if str(aftermath_result.get("state", "none")) == "go_private_cashout":
		player_cashout_result = state._apply_player_go_private_cashout(
			company_id,
			float(aftermath_result.get("final_cashout_price", application.get("offer_price", old_price)))
		)
	state._set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		new_free_float_pct,
		{
			"type": "tender_offer",
			"chain_id": str(application.get("chain_id", "")),
			"offer_type": str(application.get("offer_type", "voluntary_tender_offer")),
			"offeror_label": str(application.get("offeror_label", "strategic acquirer")),
			"player_tender_choice": str(application.get("player_tender_choice", "auto_prorata")),
			"offer_shares": int(application.get("offer_shares", accepted_shares)),
			"accepted_shares": int(round(accepted_shares)),
			"offer_price": float(application.get("offer_price", old_price)),
			"premium_pct": premium_pct,
			"acceptance_ratio": float(application.get("acceptance_ratio", 0.0)),
			"tender_budget": float(application.get("tender_budget", 0.0)),
			"price_support_pct": price_support_pct,
			"old_price": old_price,
			"new_price": new_price,
			"old_shares_outstanding": old_shares_outstanding,
			"new_shares_outstanding": new_shares_outstanding,
			"old_free_float_pct": old_free_float_pct * 100.0,
			"new_free_float_pct": new_free_float_pct,
			"player_old_shares": int(player_result.get("old_shares", 0)),
			"player_tendered_shares": int(player_result.get("tendered_shares", 0)),
			"player_remaining_shares": int(player_result.get("remaining_shares", 0)),
			"player_cash_received": float(player_result.get("cash_received", 0.0)),
			"player_tender_status": str(player_result.get("status", "not_held")),
			"aftermath_state": str(aftermath_result.get("state", "none")),
			"public_float_warning_pct": float(application.get("public_float_warning_pct", 12.0)),
			"go_private_trigger_pct": float(application.get("go_private_trigger_pct", 5.0)),
			"liquidity_penalty_multiplier": float(aftermath_result.get("liquidity_penalty_multiplier", 1.0)),
			"volatility_event_multiplier": float(aftermath_result.get("volatility_event_multiplier", 1.0)),
			"final_cashout_price": float(aftermath_result.get("final_cashout_price", 0.0)),
			"player_final_cashout_shares": int(player_cashout_result.get("shares", 0)),
			"player_final_cashout_cash": float(player_cashout_result.get("cash_received", 0.0)),
			"player_final_cashout_status": str(player_cashout_result.get("status", "not_applicable")),
			"day_index": int(application.get("day_index", state.day_index))
		}
	)
	state._apply_tender_offer_aftermath_state(company_id, application, aftermath_result)


static func apply_strategic_mna_application(state, application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not state.companies.has(company_id):
		return
	var cashout_price: float = max(float(application.get("cashout_price", 0.0)), 0.0)
	if cashout_price <= 0.0:
		return
	var definition: Dictionary = state.get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = state.companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var new_shares_outstanding: float = max(float(application.get("new_shares_outstanding", old_shares_outstanding)), 1.0)
	var new_free_float_pct: float = float(application.get("new_free_float_pct", financials.get("free_float_pct", 35.0)))
	var price_factor: float = cashout_price / old_price
	var new_price: float = state._apply_company_price_factor(company_id, price_factor, false)
	var player_result: Dictionary = state._apply_player_acquisition_cashout(company_id, cashout_price)
	state._set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		new_free_float_pct,
		{
			"type": "strategic_merger_acquisition",
			"chain_id": str(application.get("chain_id", "")),
			"deal_type": str(application.get("deal_type", "cash_acquisition")),
			"consideration_type": str(application.get("consideration_type", "cash")),
			"acquirer_company_id": str(application.get("acquirer_company_id", "")),
			"acquirer_ticker": str(application.get("acquirer_ticker", "")),
			"acquirer_name": str(application.get("acquirer_name", "")),
			"acquirer_label": str(application.get("acquirer_label", "strategic acquirer")),
			"offer_premium_pct": float(application.get("offer_premium_pct", 0.0)),
			"completion_cashout_premium_pct": float(application.get("completion_cashout_premium_pct", 0.0)),
			"total_premium_pct": float(application.get("total_premium_pct", 0.0)),
			"cashout_price": cashout_price,
			"reference_price": float(application.get("reference_price", old_price)),
			"equity_value": float(application.get("equity_value", 0.0)),
			"synergy_score": float(application.get("synergy_score", 0.0)),
			"price_support_pct": float(application.get("price_support_pct", 0.0)),
			"old_price": old_price,
			"new_price": new_price,
			"old_shares_outstanding": old_shares_outstanding,
			"new_shares_outstanding": new_shares_outstanding,
			"old_free_float_pct": float(application.get("old_free_float_pct", financials.get("free_float_pct", 35.0))),
			"new_free_float_pct": new_free_float_pct,
			"listing_status_after": str(application.get("listing_status_after", "acquired_cashout")),
			"player_old_shares": int(player_result.get("shares", 0)),
			"player_cash_received": float(player_result.get("cash_received", 0.0)),
			"player_cashout_status": str(player_result.get("status", "not_held")),
			"day_index": int(application.get("day_index", state.day_index))
		}
	)
	state._apply_company_acquisition_state(company_id, application, player_result)


static func apply_backdoor_listing_application(state, application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not state.companies.has(company_id):
		return
	var new_shares: float = max(float(application.get("new_shares", 0.0)), 0.0)
	if new_shares <= 0.0:
		return
	var definition: Dictionary = state.get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = state.companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var new_shares_outstanding: float = max(float(application.get("new_shares_outstanding", old_shares_outstanding + new_shares)), 1.0)
	var new_free_float_pct: float = float(application.get("new_free_float_pct", financials.get("free_float_pct", 35.0)))
	var target_price: float = float(application.get("post_deal_price", 0.0))
	if target_price <= 0.0:
		target_price = old_price * (1.0 + float(application.get("price_reprice_pct", 0.0)))
	target_price = max(target_price, 1.0)
	var new_price: float = state._apply_company_price_factor(company_id, target_price / old_price, false)
	var player_result: Dictionary = state._record_player_backdoor_listing_note(
		company_id,
		new_price,
		old_shares_outstanding,
		new_shares_outstanding
	)
	var post_deal_identity_value = application.get("post_deal_identity", {})
	var post_deal_identity: Dictionary = post_deal_identity_value.duplicate(true) if typeof(post_deal_identity_value) == TYPE_DICTIONARY else {}
	var post_deal_tags: Array = application.get("post_deal_tags", []).duplicate()
	state._set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		new_free_float_pct,
		{
			"type": "backdoor_listing",
			"chain_id": str(application.get("chain_id", "")),
			"deal_type": str(application.get("deal_type", "reverse_takeover")),
			"consideration_type": str(application.get("consideration_type", "share_issue")),
			"incoming_asset_label": str(application.get("incoming_asset_label", "private operating business")),
			"sponsor_label": str(application.get("sponsor_label", "private operating company")),
			"post_deal_name": str(application.get("post_deal_name", "")),
			"post_deal_sector_id": str(application.get("post_deal_sector_id", "")),
			"post_deal_sector_name": str(application.get("post_deal_sector_name", "")),
			"post_deal_archetype_label": str(application.get("post_deal_archetype_label", "")),
			"post_deal_description": str(application.get("post_deal_description", "")),
			"post_deal_tags": post_deal_tags.duplicate(),
			"post_deal_identity": post_deal_identity.duplicate(true),
			"target_control_pct": float(application.get("target_control_pct", 0.0)),
			"incoming_control_pct": float(application.get("incoming_control_pct", 0.0)),
			"issue_premium_pct": float(application.get("issue_premium_pct", 0.0)),
			"asset_quality_score": float(application.get("asset_quality_score", 0.0)),
			"valuation_recognition_pct": float(application.get("valuation_recognition_pct", 1.0)),
			"new_shares": int(round(new_shares)),
			"issue_price": float(application.get("issue_price", 0.0)),
			"injected_asset_value": float(application.get("injected_asset_value", 0.0)),
			"recognized_asset_value": float(application.get("recognized_asset_value", 0.0)),
			"old_market_cap": float(application.get("old_market_cap", old_price * old_shares_outstanding)),
			"post_deal_market_cap": new_price * new_shares_outstanding,
			"old_price": old_price,
			"new_price": new_price,
			"theoretical_post_price": float(application.get("theoretical_post_price", 0.0)),
			"price_reprice_pct": (new_price - old_price) / old_price,
			"silent_accumulation_pct": float(application.get("silent_accumulation_pct", 0.0)),
			"silent_accumulation_days": int(application.get("silent_accumulation_days", 0)),
			"silent_accumulation_shares": int(application.get("silent_accumulation_shares", 0)),
			"silent_accumulation_value": float(application.get("silent_accumulation_value", 0.0)),
			"accumulation_price_support_pct": float(application.get("accumulation_price_support_pct", 0.0)),
			"follow_on_rights_hint": bool(application.get("follow_on_rights_hint", false)),
			"follow_on_rights_chain_id": str(application.get("follow_on_rights_chain_id", "")),
			"follow_on_rights_probability": float(application.get("follow_on_rights_probability", 0.0)),
			"follow_on_rights_purpose": str(application.get("follow_on_rights_purpose", "")),
			"sponsor_lockup_days": int(application.get("sponsor_lockup_days", 30)),
			"sponsor_unlock_warning_lead_days": int(application.get("sponsor_unlock_warning_lead_days", 5)),
			"sponsor_locked_shares": int(application.get("sponsor_locked_shares", new_shares)),
			"sponsor_lockup_start_day_number": int(application.get("sponsor_lockup_start_day_number", application.get("day_index", state.day_index))),
			"sponsor_unlock_day_number": int(application.get("sponsor_unlock_day_number", int(application.get("day_index", state.day_index)) + int(application.get("sponsor_lockup_days", 30)))),
			"sponsor_unlock_warning_day_number": int(application.get("sponsor_unlock_warning_day_number", int(application.get("day_index", state.day_index)) + max(int(application.get("sponsor_lockup_days", 30)) - int(application.get("sponsor_unlock_warning_lead_days", 5)), 1))),
			"sponsor_behavior": str(application.get("sponsor_behavior", "gradual_distribution")),
			"sponsor_overhang_pressure_pct": float(application.get("sponsor_overhang_pressure_pct", 0.18)),
			"old_shares_outstanding": old_shares_outstanding,
			"new_shares_outstanding": new_shares_outstanding,
			"dilution_pct": float(application.get("dilution_pct", 0.0)),
			"old_free_float_pct": float(application.get("old_free_float_pct", financials.get("free_float_pct", 35.0))),
			"new_free_float_pct": new_free_float_pct,
			"player_shares": int(player_result.get("shares", 0)),
			"player_ownership_before_pct": float(player_result.get("ownership_before_pct", 0.0)),
			"player_ownership_after_pct": float(player_result.get("ownership_after_pct", 0.0)),
			"player_treatment": str(player_result.get("status", "not_held")),
			"day_index": int(application.get("day_index", state.day_index))
		}
	)
	apply_company_backdoor_listing_state(state, company_id, application, player_result)


static func apply_company_backdoor_listing_state(state, company_id: String, application: Dictionary, player_result: Dictionary) -> void:
	if company_id.is_empty() or not state.companies.has(company_id):
		return
	var runtime: Dictionary = state.companies.get(company_id, {}).duplicate(true)
	var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var trade_date_value = application.get("trade_date", {})
	var trade_date: Dictionary = trade_date_value.duplicate(true) if typeof(trade_date_value) == TYPE_DICTIONARY else {}
	var volatility_multiplier: float = clamp(float(application.get("volatility_event_multiplier", 1.45)), 1.0, 3.0)
	var asset_quality_score: float = clamp(float(application.get("asset_quality_score", 0.0)), 0.0, 1.0)
	var silent_accumulation_pct: float = clamp(float(application.get("silent_accumulation_pct", 0.0)), 0.0, 1.0)
	var accumulation_support_pct: float = clamp(float(application.get("accumulation_price_support_pct", 0.0)), 0.0, 1.0)
	var post_deal_name: String = str(application.get("post_deal_name", "")).strip_edges()
	var post_deal_sector_id: String = str(application.get("post_deal_sector_id", "")).strip_edges()
	var post_deal_sector_name: String = str(application.get("post_deal_sector_name", "")).strip_edges()
	var post_deal_archetype_label: String = str(application.get("post_deal_archetype_label", "")).strip_edges()
	var post_deal_description: String = str(application.get("post_deal_description", "")).strip_edges()
	var post_deal_tags: Array = []
	for tag_value in application.get("post_deal_tags", []):
		var tag: String = str(tag_value).strip_edges()
		if tag.is_empty():
			continue
		post_deal_tags.append(tag)
	var identity_value = application.get("post_deal_identity", {})
	var post_deal_identity: Dictionary = identity_value.duplicate(true) if typeof(identity_value) == TYPE_DICTIONARY else {}
	if post_deal_identity.is_empty():
		post_deal_identity = {
			"post_deal_name": post_deal_name,
			"post_deal_sector_id": post_deal_sector_id,
			"post_deal_sector_name": post_deal_sector_name,
			"post_deal_archetype_label": post_deal_archetype_label,
			"post_deal_description": post_deal_description,
			"post_deal_tags": post_deal_tags.duplicate(),
			"ticker_unchanged": true
		}
	var sponsor_lockup_start_day_number: int = int(application.get("sponsor_lockup_start_day_number", application.get("day_index", state.day_index)))
	var sponsor_lockup_days: int = int(application.get("sponsor_lockup_days", 30))
	var sponsor_unlock_day_number: int = int(application.get("sponsor_unlock_day_number", sponsor_lockup_start_day_number + sponsor_lockup_days))
	var sponsor_warning_day_number: int = int(application.get("sponsor_unlock_warning_day_number", max(sponsor_unlock_day_number - int(application.get("sponsor_unlock_warning_lead_days", 5)), sponsor_lockup_start_day_number + 1)))
	var sponsor_locked_shares: int = int(application.get("sponsor_locked_shares", application.get("new_shares", 0)))
	var sponsor_lockup: Dictionary = {
		"state": "locked",
		"source_backdoor_chain_id": str(application.get("chain_id", "")),
		"sponsor_label": str(application.get("sponsor_label", "private operating company")),
		"locked_shares": sponsor_locked_shares,
		"lockup_start_day_number": sponsor_lockup_start_day_number,
		"lockup_days": sponsor_lockup_days,
		"unlock_day_number": sponsor_unlock_day_number,
		"warning_day_number": sponsor_warning_day_number,
		"warning_lead_days": int(application.get("sponsor_unlock_warning_lead_days", 5)),
		"sponsor_behavior": str(application.get("sponsor_behavior", "gradual_distribution")),
		"overhang_pressure_pct": float(application.get("sponsor_overhang_pressure_pct", 0.18)),
		"warning_announced": false,
		"unlock_processed": false,
		"extension_used": false
	}
	var milestone_plan: Array = application.get("post_deal_milestone_plan", []).duplicate(true)
	var first_milestone_delay_days: int = max(int(application.get("post_deal_first_milestone_delay_days", 6)), 1)
	var milestone_gap_days: int = max(int(application.get("post_deal_milestone_gap_days", 9)), 1)
	var backdoor_milestone_state: Dictionary = {
		"state": "active",
		"source_backdoor_chain_id": str(application.get("chain_id", "")),
		"company_id": company_id,
		"sponsor_label": str(application.get("sponsor_label", "private operating company")),
		"incoming_asset_label": str(application.get("incoming_asset_label", "private operating business")),
		"post_deal_name": post_deal_name,
		"post_deal_sector_id": post_deal_sector_id,
		"asset_quality_score": asset_quality_score,
		"capital_intensity": float(application.get("post_deal_capital_intensity", 0.75)),
		"story_heat": float(application.get("post_deal_story_heat", 0.8)),
		"milestone_plan": milestone_plan,
		"milestone_count": int(application.get("post_deal_milestone_count", milestone_plan.size())),
		"current_milestone_index": 0,
		"completed_milestones": 0,
		"delay_count": 0,
		"setback_count": 0,
		"started_day_number": int(application.get("day_index", state.day_index)),
		"next_milestone_day_number": int(application.get("day_index", state.day_index)) + first_milestone_delay_days,
		"default_gap_days": milestone_gap_days,
		"last_result_state": "",
		"last_phase_label": ""
	}
	var backdoor_result: Dictionary = {
		"state": "completed",
		"chain_id": str(application.get("chain_id", "")),
		"day_index": int(application.get("day_index", state.day_index)),
		"trade_date": trade_date,
		"deal_type": str(application.get("deal_type", "reverse_takeover")),
		"consideration_type": str(application.get("consideration_type", "share_issue")),
		"incoming_asset_label": str(application.get("incoming_asset_label", "private operating business")),
		"sponsor_label": str(application.get("sponsor_label", "private operating company")),
		"post_deal_name": post_deal_name,
		"post_deal_sector_id": post_deal_sector_id,
		"post_deal_sector_name": post_deal_sector_name,
		"post_deal_archetype_label": post_deal_archetype_label,
		"post_deal_description": post_deal_description,
		"post_deal_tags": post_deal_tags.duplicate(),
		"post_deal_identity": post_deal_identity.duplicate(true),
		"incoming_control_pct": float(application.get("incoming_control_pct", 0.0)),
		"new_shares": int(application.get("new_shares", 0)),
		"issue_price": float(application.get("issue_price", 0.0)),
		"injected_asset_value": float(application.get("injected_asset_value", 0.0)),
		"asset_quality_score": asset_quality_score,
		"price_reprice_pct": float(application.get("price_reprice_pct", 0.0)),
		"silent_accumulation_pct": silent_accumulation_pct,
		"silent_accumulation_days": int(application.get("silent_accumulation_days", 0)),
		"silent_accumulation_shares": int(application.get("silent_accumulation_shares", 0)),
		"silent_accumulation_value": float(application.get("silent_accumulation_value", 0.0)),
		"accumulation_price_support_pct": accumulation_support_pct,
		"follow_on_rights_hint": bool(application.get("follow_on_rights_hint", false)),
		"follow_on_rights_chain_id": str(application.get("follow_on_rights_chain_id", "")),
		"follow_on_rights_probability": float(application.get("follow_on_rights_probability", 0.0)),
		"follow_on_rights_purpose": str(application.get("follow_on_rights_purpose", "")),
		"sponsor_lockup": sponsor_lockup.duplicate(true),
		"milestone_state": backdoor_milestone_state.duplicate(true),
		"volatility_event_multiplier": volatility_multiplier,
		"player_shares": int(player_result.get("shares", 0)),
		"player_ownership_before_pct": float(player_result.get("ownership_before_pct", 0.0)),
		"player_ownership_after_pct": float(player_result.get("ownership_after_pct", 0.0)),
		"player_treatment": str(player_result.get("status", "not_held"))
	}
	if not post_deal_name.is_empty():
		profile["name"] = post_deal_name
	if not post_deal_sector_id.is_empty():
		profile["sector_id"] = post_deal_sector_id
	if not post_deal_archetype_label.is_empty():
		profile["archetype_label"] = post_deal_archetype_label
	if not post_deal_description.is_empty():
		profile["profile_description"] = post_deal_description
	if not post_deal_tags.is_empty():
		profile["profile_tags"] = post_deal_tags.duplicate()
	profile["post_deal_identity"] = post_deal_identity.duplicate(true)
	profile["backdoor_sponsor_lockup"] = sponsor_lockup.duplicate(true)
	profile["backdoor_milestone_state"] = backdoor_milestone_state.duplicate(true)
	var traits: Dictionary = profile.get("generation_traits", {}).duplicate(true)
	traits["story_heat"] = max(float(traits.get("story_heat", 0.5)), clamp(float(application.get("post_deal_story_heat", 0.8)) + asset_quality_score * 0.05, 0.0, 0.96))
	traits["liquidity_profile"] = max(float(traits.get("liquidity_profile", 0.5)), clamp(float(application.get("post_deal_liquidity_profile", 0.62)) + silent_accumulation_pct * 0.28, 0.0, 0.92))
	traits["capital_intensity"] = max(float(traits.get("capital_intensity", 0.5)), clamp(float(application.get("post_deal_capital_intensity", 0.75)), 0.0, 0.98))
	traits["backdoor_listing_heat"] = clamp(0.62 + asset_quality_score * 0.22 + silent_accumulation_pct * 0.44, 0.0, 1.0)
	profile["generation_traits"] = traits
	profile["quality_score"] = max(int(profile.get("quality_score", 0)), int(round(48.0 + asset_quality_score * 35.0)))
	profile["growth_score"] = max(int(profile.get("growth_score", 0)), int(round(56.0 + asset_quality_score * 34.0)))
	profile["risk_score"] = max(int(profile.get("risk_score", 0)), int(round(54.0 + (1.0 - asset_quality_score) * 24.0 + silent_accumulation_pct * 20.0)))
	profile["base_volatility"] = max(
		float(profile.get("base_volatility", 0.025)),
		clamp(0.028 + (volatility_multiplier - 1.0) * 0.018 + silent_accumulation_pct * 0.06, 0.025, 0.068)
	)
	var financials: Dictionary = profile.get("financials", {}).duplicate(true)
	if not financials.is_empty():
		var post_market_cap: float = max(float(application.get("post_deal_market_cap", financials.get("market_cap", 0.0))), 0.0)
		var current_avg_daily_value: float = max(float(financials.get("avg_daily_value", 0.0)), 0.0)
		var story_adv_floor: float = post_market_cap * clamp(0.00042 + silent_accumulation_pct * 0.0022 + asset_quality_score * 0.00036, 0.00036, 0.0026)
		financials["avg_daily_value"] = max(current_avg_daily_value, story_adv_floor)
		financials["revenue_growth_yoy"] = max(float(financials.get("revenue_growth_yoy", 0.0)), 8.0 + asset_quality_score * 28.0)
		financials["earnings_growth_yoy"] = max(float(financials.get("earnings_growth_yoy", -100.0)), -4.0 + asset_quality_score * 24.0)
		profile["financials"] = financials
	profile["backdoor_listing_result"] = backdoor_result
	profile["volatility_event_multiplier"] = max(float(profile.get("volatility_event_multiplier", 1.0)), volatility_multiplier)
	runtime["company_profile"] = profile
	var depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	if not depth_context.is_empty():
		depth_context["backdoor_listing_state"] = "completed"
		depth_context["volatility_event_multiplier"] = volatility_multiplier
		depth_context["asset_injection_state"] = "completed"
		depth_context["post_deal_sector_id"] = post_deal_sector_id
		depth_context["sponsor_lockup_state"] = "locked"
		depth_context["sponsor_locked_shares"] = sponsor_locked_shares
		depth_context["sponsor_unlock_day_number"] = sponsor_unlock_day_number
		depth_context["backdoor_milestone_state"] = "active"
		depth_context["backdoor_next_milestone_day_number"] = int(backdoor_milestone_state.get("next_milestone_day_number", 0))
		depth_context["silent_accumulation_pct"] = silent_accumulation_pct
		depth_context["silent_accumulation_shares"] = int(application.get("silent_accumulation_shares", 0))
		depth_context["accumulation_price_support_pct"] = accumulation_support_pct
		depth_context["float_tightness"] = max(float(depth_context.get("float_tightness", 0.0)), 0.72 + silent_accumulation_pct * 0.32)
		var liquidity_lift: float = clamp(1.0 + silent_accumulation_pct * 3.2 + asset_quality_score * 0.38 + accumulation_support_pct * 1.6, 1.0, 2.35)
		for depth_value_key in ["synthetic_daily_value", "ask_depth_value", "bid_depth_value"]:
			if depth_context.has(depth_value_key):
				depth_context[depth_value_key] = max(float(depth_context.get(depth_value_key, 0.0)) * liquidity_lift, 1.0)
		runtime["market_depth_context"] = depth_context
	state.companies[company_id] = runtime


static func apply_backdoor_lockup_update_application(state, application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not state.companies.has(company_id):
		return
	var runtime: Dictionary = state.companies.get(company_id, {}).duplicate(true)
	var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var lockup: Dictionary = profile.get("backdoor_sponsor_lockup", {}).duplicate(true)
	if lockup.is_empty():
		return
	var action_type: String = str(application.get("action_type", "warning"))
	lockup["last_update_day_number"] = int(application.get("day_index", state.day_index))
	lockup["last_action_type"] = action_type
	lockup["active_overhang_pressure_pct"] = float(application.get("sell_pressure_pct", lockup.get("overhang_pressure_pct", 0.0)))
	lockup["impact_until_day_number"] = int(application.get("impact_until_day_number", application.get("day_index", state.day_index)))
	if action_type == "warning":
		lockup["state"] = "warning"
		lockup["warning_announced"] = true
	elif action_type == "extension":
		lockup["state"] = "extended"
		lockup["warning_announced"] = false
		lockup["extension_used"] = true
		lockup["extension_days"] = int(application.get("extension_days", 0))
		lockup["unlock_day_number"] = int(application.get("unlock_day_number", lockup.get("unlock_day_number", 0)))
		lockup["warning_day_number"] = max(int(lockup.get("unlock_day_number", 0)) - int(lockup.get("warning_lead_days", 5)), int(application.get("day_index", state.day_index)) + 1)
	elif action_type == "unlock":
		lockup["unlock_processed"] = true
		lockup["state"] = "unlocked_%s" % str(application.get("sponsor_behavior", "gradual_distribution"))
		lockup["unlock_day_number"] = int(application.get("unlock_day_number", lockup.get("unlock_day_number", 0)))
	profile["backdoor_sponsor_lockup"] = lockup.duplicate(true)
	var backdoor_result: Dictionary = profile.get("backdoor_listing_result", {}).duplicate(true)
	if not backdoor_result.is_empty():
		backdoor_result["sponsor_lockup"] = lockup.duplicate(true)
		profile["backdoor_listing_result"] = backdoor_result
	var sell_pressure_pct: float = clamp(float(application.get("sell_pressure_pct", 0.0)), 0.0, 1.0)
	if action_type == "extension":
		profile["volatility_event_multiplier"] = max(float(profile.get("volatility_event_multiplier", 1.0)), 1.16)
	else:
		profile["volatility_event_multiplier"] = max(float(profile.get("volatility_event_multiplier", 1.0)), clamp(1.18 + sell_pressure_pct * 1.45, 1.0, 2.4))
	runtime["company_profile"] = profile
	var depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	if not depth_context.is_empty():
		depth_context["sponsor_lockup_state"] = str(lockup.get("state", ""))
		depth_context["sponsor_locked_shares"] = int(application.get("locked_shares", lockup.get("locked_shares", 0)))
		depth_context["sponsor_locked_shares_pct"] = float(application.get("locked_shares_pct", 0.0))
		depth_context["sponsor_unlock_day_number"] = int(lockup.get("unlock_day_number", 0))
		depth_context["sponsor_overhang_pressure_pct"] = sell_pressure_pct
		depth_context["sponsor_overhang_impact_until_day_number"] = int(lockup.get("impact_until_day_number", state.day_index))
		if action_type == "extension":
			depth_context["ask_depth_value"] = max(float(depth_context.get("ask_depth_value", 0.0)) * 1.04, 1.0)
			depth_context["bid_depth_value"] = max(float(depth_context.get("bid_depth_value", 0.0)) * 1.06, 1.0)
		else:
			depth_context["ask_depth_value"] = max(float(depth_context.get("ask_depth_value", 0.0)) * (1.0 + sell_pressure_pct * 1.65), 1.0)
			depth_context["bid_depth_value"] = max(float(depth_context.get("bid_depth_value", 0.0)) * clamp(1.0 - sell_pressure_pct * 0.38, 0.52, 1.0), 1.0)
			depth_context["synthetic_daily_value"] = max(float(depth_context.get("synthetic_daily_value", 0.0)) * (1.0 + sell_pressure_pct * 0.65), 1.0)
		runtime["market_depth_context"] = depth_context
	state.companies[company_id] = runtime


static func apply_backdoor_milestone_update_application(state, application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not state.companies.has(company_id):
		return
	var runtime: Dictionary = state.companies.get(company_id, {}).duplicate(true)
	var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var milestone_state: Dictionary = profile.get("backdoor_milestone_state", {}).duplicate(true)
	if milestone_state.is_empty():
		return
	var result_state: String = str(application.get("result_state", "delayed"))
	var price_adjustment_pct: float = clamp(float(application.get("price_adjustment_pct", 0.0)), -0.30, 0.30)
	if absf(price_adjustment_pct) > 0.0001:
		state._apply_company_price_factor(company_id, 1.0 + price_adjustment_pct, false)
		runtime = state.companies.get(company_id, {}).duplicate(true)
		profile = runtime.get("company_profile", {}).duplicate(true)
		milestone_state = profile.get("backdoor_milestone_state", {}).duplicate(true)
	milestone_state["last_update_day_number"] = int(application.get("day_index", state.day_index))
	milestone_state["last_result_state"] = result_state
	milestone_state["last_phase_id"] = str(application.get("phase_id", ""))
	milestone_state["last_phase_label"] = str(application.get("phase_label", ""))
	milestone_state["last_price_adjustment_pct"] = price_adjustment_pct
	milestone_state["last_volatility_event_multiplier"] = float(application.get("volatility_event_multiplier", 1.0))
	milestone_state["completed_milestones"] = int(application.get("completed_milestones", milestone_state.get("completed_milestones", 0)))
	milestone_state["delay_count"] = int(application.get("delay_count", milestone_state.get("delay_count", 0)))
	milestone_state["setback_count"] = int(application.get("setback_count", milestone_state.get("setback_count", 0)))
	milestone_state["current_milestone_index"] = int(application.get("next_milestone_index", milestone_state.get("current_milestone_index", 0)))
	milestone_state["next_milestone_day_number"] = int(application.get("next_milestone_day_number", 0))
	milestone_state["impact_until_day_number"] = int(application.get("impact_until_day_number", application.get("day_index", state.day_index)))
	if bool(application.get("plan_complete", false)):
		milestone_state["state"] = "completed" if int(milestone_state.get("setback_count", 0)) <= 0 else "impaired"
	elif result_state == "delayed":
		milestone_state["state"] = "delayed"
	elif result_state == "setback":
		milestone_state["state"] = "active_with_setback"
	else:
		milestone_state["state"] = "active"
	profile["backdoor_milestone_state"] = milestone_state.duplicate(true)
	var backdoor_result: Dictionary = profile.get("backdoor_listing_result", {}).duplicate(true)
	if not backdoor_result.is_empty():
		backdoor_result["milestone_state"] = milestone_state.duplicate(true)
		profile["backdoor_listing_result"] = backdoor_result
	profile["volatility_event_multiplier"] = max(
		float(profile.get("volatility_event_multiplier", 1.0)),
		clamp(float(application.get("volatility_event_multiplier", 1.0)), 1.0, 3.0)
	)
	var traits: Dictionary = profile.get("generation_traits", {}).duplicate(true)
	if result_state == "delivered":
		traits["story_heat"] = clamp(float(traits.get("story_heat", 0.5)) + 0.06, 0.0, 1.0)
		traits["execution_consistency"] = clamp(float(traits.get("execution_consistency", 0.5)) + 0.04, 0.0, 1.0)
		traits["liquidity_profile"] = clamp(float(traits.get("liquidity_profile", 0.5)) + 0.03, 0.0, 1.0)
	elif result_state == "setback":
		traits["execution_consistency"] = clamp(float(traits.get("execution_consistency", 0.5)) - 0.07, 0.0, 1.0)
		traits["story_heat"] = clamp(float(traits.get("story_heat", 0.5)) + 0.04, 0.0, 1.0)
	else:
		traits["execution_consistency"] = clamp(float(traits.get("execution_consistency", 0.5)) - 0.03, 0.0, 1.0)
	profile["generation_traits"] = traits
	var adjustments: Array = profile.get("corporate_action_adjustments", []).duplicate(true)
	adjustments.append({
		"type": "backdoor_milestone",
		"chain_id": str(application.get("chain_id", "")),
		"phase_id": str(application.get("phase_id", "")),
		"phase_label": str(application.get("phase_label", "")),
		"result_state": result_state,
		"price_adjustment_pct": price_adjustment_pct,
		"completed_milestones": int(milestone_state.get("completed_milestones", 0)),
		"setback_count": int(milestone_state.get("setback_count", 0)),
		"delay_count": int(milestone_state.get("delay_count", 0)),
		"day_index": int(application.get("day_index", state.day_index))
	})
	if adjustments.size() > 24:
		adjustments = adjustments.slice(adjustments.size() - 24, adjustments.size())
	profile["corporate_action_adjustments"] = adjustments
	runtime["company_profile"] = profile
	var depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	if not depth_context.is_empty():
		depth_context["backdoor_milestone_state"] = str(milestone_state.get("state", ""))
		depth_context["backdoor_last_milestone_result"] = result_state
		depth_context["backdoor_last_milestone_label"] = str(application.get("phase_label", ""))
		depth_context["backdoor_next_milestone_day_number"] = int(milestone_state.get("next_milestone_day_number", 0))
		depth_context["volatility_event_multiplier"] = max(float(depth_context.get("volatility_event_multiplier", 1.0)), float(profile.get("volatility_event_multiplier", 1.0)))
		if result_state == "delivered":
			depth_context["bid_depth_value"] = max(float(depth_context.get("bid_depth_value", 0.0)) * 1.08, 1.0)
			depth_context["ask_depth_value"] = max(float(depth_context.get("ask_depth_value", 0.0)) * 0.96, 1.0)
		else:
			var pressure: float = absf(price_adjustment_pct)
			depth_context["ask_depth_value"] = max(float(depth_context.get("ask_depth_value", 0.0)) * (1.0 + pressure * 4.2), 1.0)
			depth_context["bid_depth_value"] = max(float(depth_context.get("bid_depth_value", 0.0)) * clamp(1.0 - pressure * 2.1, 0.60, 1.0), 1.0)
			depth_context["synthetic_daily_value"] = max(float(depth_context.get("synthetic_daily_value", 0.0)) * (1.0 + pressure * 1.6), 1.0)
		runtime["market_depth_context"] = depth_context
	state.companies[company_id] = runtime


static func apply_ceo_change_application(state, application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not state.companies.has(company_id):
		return
	var new_ceo_name: String = str(application.get("new_ceo_name", ""))
	if new_ceo_name.is_empty():
		return
	var definition: Dictionary = state.get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = state.companies.get(company_id, {}).duplicate(true)
	var profile: Dictionary = runtime.get("company_profile", {}).duplicate(true)
	var management_roster: Array = profile.get("management_roster", definition.get("management_roster", [])).duplicate(true)
	var previous_ceo_name: String = str(application.get("current_ceo_name", ""))
	var replaced_ceo: bool = false
	for management_index in range(management_roster.size()):
		if typeof(management_roster[management_index]) != TYPE_DICTIONARY:
			continue
		var management: Dictionary = management_roster[management_index].duplicate(true)
		if str(management.get("affiliation_role", "")) != "ceo":
			continue
		if previous_ceo_name.is_empty():
			previous_ceo_name = str(management.get("display_name", ""))
		management["previous_display_name"] = str(management.get("display_name", ""))
		management["display_name"] = new_ceo_name
		management["contact_id"] = "insider_%s_ceo_%d" % [company_id, int(application.get("day_index", state.day_index))]
		management["id"] = str(management.get("contact_id", ""))
		management["role"] = "CEO"
		management["role_label"] = "CEO"
		management["tone"] = "constructive"
		management["intro"] = "%s serves as CEO at %s after a shareholder-approved leadership reset focused on %s." % [
			new_ceo_name,
			str(definition.get("name", company_id.to_upper())),
			str(application.get("mandate", "execution reset"))
		]
		management_roster[management_index] = management
		replaced_ceo = true
		break
	if not replaced_ceo:
		management_roster.insert(0, {
			"contact_id": "insider_%s_ceo_%d" % [company_id, int(application.get("day_index", state.day_index))],
			"id": "insider_%s_ceo_%d" % [company_id, int(application.get("day_index", state.day_index))],
			"display_name": new_ceo_name,
			"affiliation_type": "insider",
			"affiliation_role": "ceo",
			"company_id": company_id,
			"affiliated_company_id": company_id,
			"sector_id": str(definition.get("sector_id", "")),
			"role": "CEO",
			"role_label": "CEO",
			"recognition_required": 50,
			"base_relationship": 18,
			"reliability": 0.68,
			"tone": "constructive",
			"intro": "%s serves as CEO at %s after a shareholder-approved leadership reset." % [
				new_ceo_name,
				str(definition.get("name", company_id.to_upper()))
			]
		})
	profile["management_roster"] = management_roster
	var price_reaction_pct: float = clamp(float(application.get("price_reaction_pct", 0.0)), -0.5, 0.5)
	var new_price: float = state._apply_company_price_factor(company_id, 1.0 + price_reaction_pct, false)
	runtime = state.companies.get(company_id, {}).duplicate(true)
	profile = runtime.get("company_profile", {}).duplicate(true)
	profile["management_roster"] = management_roster
	var traits: Dictionary = profile.get("generation_traits", {}).duplicate(true)
	traits["execution_consistency"] = clamp(float(traits.get("execution_consistency", 0.5)) + float(application.get("execution_consistency_delta", 0.0)), 0.0, 1.0)
	traits["story_heat"] = clamp(float(traits.get("story_heat", 0.5)) + absf(price_reaction_pct) * 0.8 + 0.04, 0.0, 1.0)
	profile["generation_traits"] = traits
	profile["growth_score"] = clamp(int(profile.get("growth_score", definition.get("growth_score", 50))) + int(round(float(application.get("growth_score_delta", 0.0)) * 100.0)), 1, 99)
	profile["risk_score"] = clamp(int(profile.get("risk_score", definition.get("risk_score", 50))) + int(round(float(application.get("risk_score_delta", 0.0)) * 100.0)), 1, 99)
	profile["quality_score"] = clamp(int(profile.get("quality_score", definition.get("quality_score", 50))) + int(round(float(application.get("governance_confidence_delta", 0.0)) * 60.0)), 1, 99)
	profile["volatility_event_multiplier"] = max(
		float(profile.get("volatility_event_multiplier", 1.0)),
		clamp(float(application.get("volatility_event_multiplier", 1.18)), 1.0, 3.0)
	)
	var ceo_result: Dictionary = {
		"type": "ceo_change",
		"chain_id": str(application.get("chain_id", "")),
		"meeting_id": str(application.get("meeting_id", "")),
		"previous_ceo_name": previous_ceo_name,
		"new_ceo_name": new_ceo_name,
		"incoming_profile_label": str(application.get("incoming_profile_label", "")),
		"mandate": str(application.get("mandate", "")),
		"governance_confidence_delta": float(application.get("governance_confidence_delta", 0.0)),
		"price_reaction_pct": price_reaction_pct,
		"new_price": new_price,
		"day_index": int(application.get("day_index", state.day_index))
	}
	profile["ceo_change_result"] = ceo_result
	var adjustments: Array = profile.get("corporate_action_adjustments", []).duplicate(true)
	adjustments.append(ceo_result.duplicate(true))
	if adjustments.size() > 24:
		adjustments = adjustments.slice(adjustments.size() - 24, adjustments.size())
	profile["corporate_action_adjustments"] = adjustments
	runtime["company_profile"] = profile
	var depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	if not depth_context.is_empty():
		depth_context["ceo_change_state"] = "completed"
		depth_context["ceo_change_price_reaction_pct"] = price_reaction_pct
		depth_context["volatility_event_multiplier"] = max(float(depth_context.get("volatility_event_multiplier", 1.0)), float(profile.get("volatility_event_multiplier", 1.0)))
		depth_context["bid_depth_value"] = max(float(depth_context.get("bid_depth_value", 0.0)) * (1.0 + max(price_reaction_pct, 0.0) * 1.4), 1.0)
		depth_context["ask_depth_value"] = max(float(depth_context.get("ask_depth_value", 0.0)) * (1.0 + max(-price_reaction_pct, 0.0) * 1.6), 1.0)
		runtime["market_depth_context"] = depth_context
	state.companies[company_id] = runtime
	var held_shares: int = int(state.get_holding(company_id).get("shares", 0))
	if held_shares > 0:
		state._record_trade(
			company_id,
			"ceo_change",
			{
				"lots": int(floor(float(held_shares) / float(state.LOT_SIZE))),
				"shares": held_shares,
				"price_per_share": new_price,
				"gross_value": 0.0,
				"fee_rate": 0.0,
				"fee": 0.0
			},
			0.0,
			0.0,
			float(state.player_portfolio.get("cash", 0.0))
		)


static func apply_stock_split_application(state, application: Dictionary) -> void:
	var company_id: String = str(application.get("company_id", ""))
	if company_id.is_empty() or not state.companies.has(company_id):
		return
	var share_multiplier: float = max(float(application.get("share_multiplier", 0.0)), 0.0001)
	var price_factor: float = float(application.get("price_factor", 1.0 / share_multiplier))
	if price_factor <= 0.0:
		price_factor = 1.0 / share_multiplier
	var definition: Dictionary = state.get_effective_company_definition(company_id, false, false)
	var runtime: Dictionary = state.companies.get(company_id, {}).duplicate(true)
	var financials: Dictionary = definition.get("financials", {})
	var old_shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
	var old_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var new_shares_outstanding: float = max(float(application.get("new_shares_outstanding", round(old_shares_outstanding * share_multiplier))), 1.0)
	var new_price: float = state._apply_company_price_factor(company_id, price_factor, true)
	var sentiment_price_adjustment_pct: float = clamp(float(application.get("sentiment_price_adjustment_pct", 0.0)), -0.25, 0.25)
	if absf(sentiment_price_adjustment_pct) > 0.0001:
		new_price = state._apply_company_price_factor(company_id, 1.0 + sentiment_price_adjustment_pct, false)
	var split_type: String = str(application.get("split_type", "split"))
	var player_result: Dictionary = apply_player_stock_split(state, company_id, share_multiplier, new_price, split_type)
	state._set_company_share_structure(
		company_id,
		new_shares_outstanding,
		new_price * new_shares_outstanding,
		float(application.get("new_free_float_pct", financials.get("free_float_pct", 35.0))),
		{
			"type": "stock_split",
			"chain_id": str(application.get("chain_id", "")),
			"split_type": split_type,
			"ratio_numerator": int(application.get("ratio_numerator", 1)),
			"ratio_denominator": int(application.get("ratio_denominator", 1)),
			"share_multiplier": share_multiplier,
			"price_factor": price_factor,
			"sentiment_price_adjustment_pct": sentiment_price_adjustment_pct,
			"old_price": old_price,
			"new_price": new_price,
			"theoretical_ex_split_price": float(application.get("theoretical_ex_split_price", 0.0)),
			"old_shares_outstanding": old_shares_outstanding,
			"new_shares_outstanding": new_shares_outstanding,
			"player_old_shares": int(player_result.get("old_shares", 0)),
			"player_new_shares": int(player_result.get("new_shares", 0)),
			"player_cash_in_lieu": float(player_result.get("cash_in_lieu", 0.0)),
			"day_index": int(application.get("day_index", state.day_index))
		}
	)


static func apply_player_stock_split(state, company_id: String, share_multiplier: float, new_price: float, split_type: String) -> Dictionary:
	var holdings: Dictionary = state.player_portfolio.get("holdings", {})
	if not holdings.has(company_id):
		return {}
	var holding: Dictionary = holdings.get(company_id, {}).duplicate(true)
	var old_shares: int = max(int(holding.get("shares", 0)), 0)
	if old_shares <= 0:
		return {}
	var raw_new_shares: float = float(old_shares) * max(share_multiplier, 0.0001)
	var new_shares: int = int(floor(raw_new_shares + 0.0001))
	if split_type == "split":
		new_shares = max(int(round(raw_new_shares)), old_shares)
	var fractional_shares: float = max(raw_new_shares - float(new_shares), 0.0)
	var cash_in_lieu: float = round(fractional_shares * max(new_price, 0.0) * 100.0) / 100.0
	var old_average: float = float(holding.get("average_price", 0.0))
	if new_shares > 0:
		holding["shares"] = new_shares
		holding["average_price"] = old_average / max(share_multiplier, 0.0001)
		holdings[company_id] = holding
	else:
		holdings.erase(company_id)
	state.player_portfolio["holdings"] = holdings
	if cash_in_lieu > 0.0:
		state.player_portfolio["cash"] = float(state.player_portfolio.get("cash", 0.0)) + cash_in_lieu
	var history_side: String = "reverse_stock_split" if split_type == "reverse_split" else "stock_split"
	state._record_trade(
		company_id,
		history_side,
		{
			"lots": int(floor(float(new_shares) / float(state.LOT_SIZE))),
			"shares": new_shares,
			"price_per_share": new_price,
			"gross_value": cash_in_lieu,
			"fee_rate": 0.0,
			"fee": 0.0
		},
		0.0,
		cash_in_lieu,
		float(state.player_portfolio.get("cash", 0.0))
	)
	return {
		"old_shares": old_shares,
		"new_shares": new_shares,
		"fractional_shares": fractional_shares,
		"cash_in_lieu": cash_in_lieu
	}
