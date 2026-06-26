extends Node

const BANK_LOAN_SYSTEM = preload("res://systems/BankLoanSystem.gd")
const RUN_SEED := 20260624


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var grind_config: Dictionary = GameManager.get_difficulty_config("grind")
	var company_definitions: Array = _company_definitions_with_bank_lender(GameManager.build_company_roster(RUN_SEED, grind_config))
	RunState.setup_new_run(RUN_SEED, company_definitions, grind_config, false)
	RunState.player_portfolio["cash"] = float(grind_config.get("starting_cash", 10000000.0))
	RunState.player_portfolio["holdings"] = {}
	RunState.refresh_cash_stress_state()

	var finance_status: Dictionary = GameManager.get_finance_status_snapshot()
	var grind_offers: Array = finance_status.get("bank_loan_offers", [])
	if grind_offers.is_empty():
		_fail("Expected fixed grind probe to expose at least one bank-loan offer.")
		return
	var selected_offer: Dictionary = _first_eligible_offer(grind_offers)
	if selected_offer.is_empty():
		_fail("Expected fixed grind probe to expose an eligible bank-loan offer: %s" % JSON.stringify(grind_offers))
		return

	var starting_cash: float = float(grind_config.get("starting_cash", 10000000.0))
	var monthly_outflow: float = float(finance_status.get("monthly_outflow", 0.0))
	var max_principal: float = float(selected_offer.get("max_principal", 0.0))
	var default_principal: float = float(selected_offer.get("default_principal", 0.0))
	var payment_burden_at_max: float = float(selected_offer.get("payment_burden_pct_at_max", 0.0))
	if max_principal < starting_cash * 0.60:
		_fail("Expected grind bank-loan max to be useful versus starting cash: %s" % JSON.stringify(selected_offer))
		return
	if default_principal <= 0.0 or default_principal > max_principal + 0.0001:
		_fail("Expected default principal to remain positive and inside slider bounds: %s" % JSON.stringify(selected_offer))
		return
	if max_principal > default_principal + 0.0001 and max_principal - default_principal < float(selected_offer.get("step_size", 1.0)) - 0.0001:
		_fail("Expected slider to preserve meaningful room above default principal: %s" % JSON.stringify(selected_offer))
		return
	if monthly_outflow <= 0.0:
		_fail("Expected grind probe to have monthly outflow for burden checks.")
		return
	if payment_burden_at_max < 0.08 or payment_burden_at_max > 0.24:
		_fail("Expected max bank-loan payment burden to be visible but bounded, got %.3f in %s." % [payment_burden_at_max, JSON.stringify(selected_offer)])
		return

	var normal_offers: Array = BANK_LOAN_SYSTEM.build_lender_offers(company_definitions, {
		"run_seed": RUN_SEED,
		"difficulty_id": "normal"
	}, {
		"cash": float(finance_status.get("cash", 0.0)),
		"equity": float(finance_status.get("equity", 0.0)),
		"monthly_outflow": monthly_outflow,
		"bankrupt": false,
		"active_bank_loan": {}
	})
	var matching_normal_offer: Dictionary = _find_offer(normal_offers, str(selected_offer.get("lender_id", "")))
	if matching_normal_offer.is_empty():
		_fail("Expected matching normal-mode offer for selected lender.")
		return
	if max_principal <= float(matching_normal_offer.get("max_principal", 0.0)):
		_fail("Expected grind cap to exceed normal cap for same lender: grind=%s normal=%s" % [
			JSON.stringify(selected_offer),
			JSON.stringify(matching_normal_offer)
		])
		return

	var take_result: Dictionary = GameManager.take_bank_loan(str(selected_offer.get("offer_id", "")), max_principal)
	if not bool(take_result.get("success", false)):
		_fail("Expected fixed grind probe to take max bank loan: %s" % JSON.stringify(take_result))
		return
	var active_bank_loan: Dictionary = RunState.get_active_bank_loan()
	if active_bank_loan.is_empty():
		_fail("Expected active bank loan after balance probe borrow.")
		return
	var next_finance_status: Dictionary = GameManager.get_finance_status_snapshot()
	var bank_next_payment: Dictionary = next_finance_status.get("bank_loan_next_payment", {})
	var monthly_payment: float = float(active_bank_loan.get("monthly_payment", 0.0))
	if bank_next_payment.is_empty():
		_fail("Expected finance snapshot to expose next bank-loan payment after borrow.")
		return
	if absf(float(next_finance_status.get("total_required_loan_reserve", 0.0)) - monthly_payment) > 0.01:
		_fail("Expected total required loan reserve to equal active bank-loan monthly payment.")
		return
	if monthly_payment / monthly_outflow < 0.08:
		_fail("Expected active max loan to create visible monthly drag.")
		return

	print("BANK_LOAN_BALANCE_PROBE_OK %s" % JSON.stringify({
		"lender": str(active_bank_loan.get("lender_ticker", "")),
		"max_principal": max_principal,
		"default_principal": default_principal,
		"monthly_payment": monthly_payment,
		"burden_at_max": payment_burden_at_max,
		"monthly_outflow": monthly_outflow
	}))
	get_tree().quit(0)


func _company_definitions_with_bank_lender(company_definitions: Array) -> Array:
	for company_value in company_definitions:
		if typeof(company_value) == TYPE_DICTIONARY and BANK_LOAN_SYSTEM.is_bank_lender(company_value):
			return company_definitions
	var known_ids: Dictionary = {}
	for company_value in company_definitions:
		if typeof(company_value) == TYPE_DICTIONARY:
			known_ids[str(company_value.get("id", ""))] = true
	for catalog_value in DataRepository.get_company_universe_companies():
		if typeof(catalog_value) != TYPE_DICTIONARY:
			continue
		var catalog_company: Dictionary = catalog_value
		if known_ids.has(str(catalog_company.get("id", ""))):
			continue
		if BANK_LOAN_SYSTEM.is_bank_lender(catalog_company):
			company_definitions.append(catalog_company.duplicate(true))
			return company_definitions
	return company_definitions


func _first_eligible_offer(offers: Array) -> Dictionary:
	for offer_value in offers:
		if typeof(offer_value) != TYPE_DICTIONARY:
			continue
		var offer: Dictionary = offer_value
		if bool(offer.get("eligible", false)):
			return offer
	return {}


func _find_offer(offers: Array, lender_id: String) -> Dictionary:
	for offer_value in offers:
		if typeof(offer_value) != TYPE_DICTIONARY:
			continue
		var offer: Dictionary = offer_value
		if str(offer.get("lender_id", "")) == lender_id:
			return offer
	return {}


func _fail(message: String) -> void:
	push_error(message)
	print("BANK_LOAN_BALANCE_PROBE_FAIL %s" % message)
	get_tree().quit(1)
