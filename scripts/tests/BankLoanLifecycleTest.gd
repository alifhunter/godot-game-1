extends Node

const BANK_LOAN_SYSTEM = preload("res://systems/BankLoanSystem.gd")
const RUN_SEED := 20260624


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	RunState.player_portfolio["cash"] = 10000000.0
	RunState.player_portfolio["holdings"] = {}
	RunState.refresh_cash_stress_state()

	var baseline_finance: Dictionary = RunState.get_life_finance()
	if not baseline_finance.has("active_bank_loan"):
		_fail("Life finance defaults should include active_bank_loan.")
		return
	if not baseline_finance.get("active_bank_loan", {}).is_empty():
		_fail("New runs should start with no active regular bank loan.")
		return
	if not _assert_legacy_bank_loan_backfill():
		return
	if not _assert_malformed_bank_loan_cleanup():
		return

	var offer: Dictionary = _build_test_offer()
	if offer.is_empty():
		return
	var principal: float = float(offer.get("default_principal", 0.0))
	if principal <= 0.0:
		_fail("Expected test offer to provide positive default principal: %s" % JSON.stringify(offer))
		return
	var cash_before: float = float(RunState.player_portfolio.get("cash", 0.0))
	var start_result: Dictionary = RunState.apply_bank_loan_proceeds(str(offer.get("offer_id", "")), principal, offer)
	if not bool(start_result.get("success", false)):
		_fail("Expected regular bank loan to start: %s" % JSON.stringify(start_result))
		return
	var cash_after_start: float = float(RunState.player_portfolio.get("cash", 0.0))
	if absf(cash_after_start - (cash_before + principal)) > 0.01:
		_fail("Expected bank loan proceeds to increase cash by principal.")
		return
	var active_bank_loan: Dictionary = RunState.get_active_bank_loan()
	if active_bank_loan.is_empty():
		_fail("Expected active_bank_loan after proceeds.")
		return
	if not RunState.get_life_finance().get("active_loan", {}).is_empty():
		_fail("Regular bank loan should not populate emergency active_loan.")
		return
	if str(active_bank_loan.get("type", "")) != "regular_bank_loan":
		_fail("Expected active bank loan type regular_bank_loan: %s" % JSON.stringify(active_bank_loan))
		return
	if str(active_bank_loan.get("lender_id", "")) != "bank_nusantara_raya":
		_fail("Expected lender identity to persist on active bank loan: %s" % JSON.stringify(active_bank_loan))
		return
	if float(active_bank_loan.get("monthly_payment", 0.0)) <= 0.0:
		_fail("Expected active bank loan to compute monthly payment.")
		return

	var duplicate_result: Dictionary = RunState.apply_bank_loan_proceeds(str(offer.get("offer_id", "")), principal, offer)
	if bool(duplicate_result.get("success", false)):
		_fail("Expected second regular bank loan to be blocked while one is active.")
		return

	var saved_state: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(saved_state)
	var reloaded_bank_loan: Dictionary = RunState.get_active_bank_loan()
	if reloaded_bank_loan.is_empty():
		_fail("Expected active bank loan to survive save/load.")
		return
	if str(reloaded_bank_loan.get("lender_ticker", "")) != str(offer.get("lender_ticker", "")):
		_fail("Expected lender ticker to survive save/load: %s" % JSON.stringify(reloaded_bank_loan))
		return

	var payments_before: int = int(reloaded_bank_loan.get("payments_remaining", 0))
	var monthly_payment: float = float(reloaded_bank_loan.get("monthly_payment", 0.0))

	var finance_status: Dictionary = GameManager.get_finance_status_snapshot()
	if finance_status.get("active_bank_loan", {}).is_empty():
		_fail("Expected finance snapshot to expose active_bank_loan.")
		return
	if finance_status.get("bank_loan_next_payment", {}).is_empty():
		_fail("Expected finance snapshot to expose next bank loan payment.")
		return
	if absf(float(finance_status.get("total_required_loan_reserve", 0.0)) - monthly_payment) > 0.01:
		_fail("Expected total_required_loan_reserve to equal bank loan monthly payment before emergency loans.")
		return

	RunState.load_from_dict(saved_state)
	RunState.player_portfolio["cash"] = monthly_payment - 1.0
	RunState.refresh_cash_stress_state()
	var buy_company_id: String = str(RunState.company_order[0])
	RunState.add_to_watchlist(buy_company_id)
	var reserve_block_result: Dictionary = GameManager.buy_lots(buy_company_id, 1)
	if (
		bool(reserve_block_result.get("success", false)) or
		not str(reserve_block_result.get("message", "")).contains("loan payment reserve")
	):
		_fail("Expected active bank loan to block buys when combined reserve is not covered: %s" % JSON.stringify(reserve_block_result))
		return

	RunState.load_from_dict(saved_state)
	var previous_trade_date: Dictionary = RunState.current_trade_date.duplicate(true)
	RunState.current_trade_date = RunState.trading_calendar.trade_date_on_or_after(2020, 2, 3)
	var auto_payment_result: Dictionary = LifeManager.apply_bank_loan_payment_if_due(previous_trade_date, RunState.current_trade_date)
	if not bool(auto_payment_result.get("success", false)):
		_fail("Expected bank loan monthly hook to apply on month boundary: %s" % JSON.stringify(auto_payment_result))
		return
	if RunState.last_day_results.get("life_bank_loan_payment", {}).is_empty():
		_fail("Expected monthly bank loan hook to populate life_bank_loan_payment result.")
		return
	if int(RunState.get_active_bank_loan().get("payments_remaining", 0)) != payments_before - 1:
		_fail("Expected monthly bank loan hook to decrement payments remaining.")
		return

	RunState.load_from_dict(saved_state)
	var cash_before_payment: float = float(RunState.player_portfolio.get("cash", 0.0))
	var payment_result: Dictionary = RunState.apply_bank_loan_payment(monthly_payment, {"period_id": "2020-02"})
	if not bool(payment_result.get("success", false)):
		_fail("Expected bank loan payment to apply: %s" % JSON.stringify(payment_result))
		return
	if bool(payment_result.get("loan_completed", false)):
		_fail("First bank loan payment should not complete the loan.")
		return
	var after_payment_loan: Dictionary = RunState.get_active_bank_loan()
	if int(after_payment_loan.get("payments_remaining", 0)) != payments_before - 1:
		_fail("Expected one fewer payment remaining after scheduled bank loan payment.")
		return
	if absf(float(RunState.player_portfolio.get("cash", 0.0)) - (cash_before_payment - monthly_payment)) > 0.01:
		_fail("Expected bank loan payment to reduce cash by payment amount.")
		return
	if absf(float(after_payment_loan.get("amount_paid", 0.0)) - monthly_payment) > 0.01:
		_fail("Expected active bank loan amount_paid to increase.")
		return

	var period_index: int = 3
	while not RunState.get_active_bank_loan().is_empty():
		var loan: Dictionary = RunState.get_active_bank_loan()
		var loop_payment: float = float(loan.get("monthly_payment", 0.0))
		var loop_result: Dictionary = RunState.apply_bank_loan_payment(loop_payment, {"period_id": "2020-%02d" % period_index})
		if not bool(loop_result.get("success", false)):
			_fail("Expected looped bank loan payment to apply: %s" % JSON.stringify(loop_result))
			return
		period_index += 1
		if period_index > 20:
			_fail("Bank loan did not complete within expected payment count.")
			return
	if not RunState.get_active_bank_loan().is_empty():
		_fail("Expected active bank loan to clear after final payment.")
		return

	var finance_after_completion: Dictionary = RunState.get_life_finance()
	if not _assert_history_has(finance_after_completion, "bank_loan_started"):
		return
	if not _assert_history_has(finance_after_completion, "bank_loan_payment"):
		return
	if not _assert_history_has(finance_after_completion, "bank_loan_paid"):
		return

	var bankrupt_finance: Dictionary = RunState.get_life_finance()
	bankrupt_finance["bankrupt"] = true
	RunState.set_life_finance(bankrupt_finance)
	var bankrupt_result: Dictionary = RunState.apply_bank_loan_proceeds(str(offer.get("offer_id", "")), principal, offer)
	if bool(bankrupt_result.get("success", false)):
		_fail("Expected bankrupt run to reject regular bank loan.")
		return

	print("BANK_LOAN_LIFECYCLE_OK %s" % JSON.stringify({
		"principal": principal,
		"monthly_payment": monthly_payment,
		"payments": payments_before,
		"lender": str(offer.get("lender_ticker", ""))
	}))
	get_tree().quit(0)


func _build_test_offer() -> Dictionary:
	var selected_companies: Array = [
		{
			"id": "bank_nusantara_raya",
			"ticker": "BNRY",
			"name": "Bank Nusantara Raya",
			"sector": "finance",
			"subsector": "large_bank"
		},
		{
			"id": "payment_wallet",
			"ticker": "PYWT",
			"name": "Payment Wallet",
			"sector": "finance",
			"subsector": "digital_payments"
		}
	]
	var offers: Array = BANK_LOAN_SYSTEM.build_lender_offers(selected_companies, {
		"run_seed": RUN_SEED,
		"difficulty_id": "grind"
	}, {
		"cash": float(RunState.player_portfolio.get("cash", 0.0)),
		"equity": 120000000.0,
		"monthly_outflow": 6000000.0,
		"bankrupt": false,
		"active_bank_loan": {}
	})
	if offers.size() != 1:
		_fail("Expected exactly one bank loan offer from fixture, got %d." % offers.size())
		return {}
	var offer: Dictionary = offers[0]
	if not bool(offer.get("eligible", false)):
		_fail("Expected fixture offer to be eligible: %s" % JSON.stringify(offer))
		return {}
	return offer


func _assert_legacy_bank_loan_backfill() -> bool:
	var baseline_save: Dictionary = RunState.to_save_dict()
	var legacy_save: Dictionary = baseline_save.duplicate(true)
	var legacy_life: Dictionary = legacy_save.get("player_life", {}).duplicate(true)
	var legacy_finance: Dictionary = legacy_life.get("finance", {}).duplicate(true)
	legacy_finance.erase("active_bank_loan")
	legacy_life["finance"] = legacy_finance
	legacy_save["player_life"] = legacy_life
	RunState.load_from_dict(legacy_save)
	var normalized_finance: Dictionary = RunState.get_life_finance()
	if not normalized_finance.has("active_bank_loan"):
		_fail("Legacy save should backfill active_bank_loan.")
		return false
	if not normalized_finance.get("active_bank_loan", {}).is_empty():
		_fail("Legacy save should backfill empty active_bank_loan.")
		return false
	RunState.load_from_dict(baseline_save)
	return true


func _assert_malformed_bank_loan_cleanup() -> bool:
	var baseline_save: Dictionary = RunState.to_save_dict()
	var malformed_save: Dictionary = baseline_save.duplicate(true)
	var life: Dictionary = malformed_save.get("player_life", {}).duplicate(true)
	var finance: Dictionary = life.get("finance", {}).duplicate(true)
	finance["active_bank_loan"] = {
		"principal": 1000000.0,
		"payment_count": 3,
		"payments_remaining": 3
	}
	life["finance"] = finance
	malformed_save["player_life"] = life
	RunState.load_from_dict(malformed_save)
	if not RunState.get_active_bank_loan().is_empty():
		_fail("Malformed bank loan without lender_id should normalize away.")
		return false

	var paid_save: Dictionary = baseline_save.duplicate(true)
	life = paid_save.get("player_life", {}).duplicate(true)
	finance = life.get("finance", {}).duplicate(true)
	finance["active_bank_loan"] = {
		"state": "paid",
		"lender_id": "bank_nusantara_raya",
		"principal": 1000000.0,
		"payment_count": 3,
		"payments_remaining": 0
	}
	life["finance"] = finance
	paid_save["player_life"] = life
	RunState.load_from_dict(paid_save)
	if not RunState.get_active_bank_loan().is_empty():
		_fail("Paid bank loan should normalize away from active_bank_loan.")
		return false
	RunState.load_from_dict(baseline_save)
	return true


func _assert_history_has(finance: Dictionary, row_type: String) -> bool:
	for row_value in finance.get("finance_history", []):
		if typeof(row_value) == TYPE_DICTIONARY and str(row_value.get("type", "")) == row_type:
			return true
	_fail("Expected finance_history to include '%s': %s" % [row_type, JSON.stringify(finance.get("finance_history", []))])
	return false


func _fail(message: String) -> void:
	push_error(message)
	print("BANK_LOAN_LIFECYCLE_FAIL: %s" % message)
	get_tree().quit(1)
