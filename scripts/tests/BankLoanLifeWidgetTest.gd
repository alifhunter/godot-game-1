extends Node

const LIFE_WIDGET_SCRIPT = preload("res://scripts/ui/widgets/LifeWidget.gd")
const BANK_LOAN_SYSTEM = preload("res://systems/BankLoanSystem.gd")
const RUN_SEED := 20260624


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config("grind")
	var company_definitions: Array = _company_definitions_with_bank_lender(GameManager.build_company_roster(RUN_SEED, difficulty_config))
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	RunState.player_portfolio["cash"] = 100000000.0
	RunState.player_portfolio["holdings"] = {}
	RunState.refresh_cash_stress_state()

	var finance_status: Dictionary = GameManager.get_finance_status_snapshot()
	var offers: Array = finance_status.get("bank_loan_offers", [])
	if offers.is_empty():
		_fail("Expected at least one regular bank-loan offer in UI test roster.")
		return

	var widget: Control = LIFE_WIDGET_SCRIPT.new()
	add_child(widget)
	await get_tree().process_frame
	widget.refresh()
	await get_tree().process_frame

	var panel: PanelContainer = widget.find_child("LifeBankLoanPanel", true, false) as PanelContainer
	var lender_selector: OptionButton = widget.find_child("LifeBankLoanLenderSelector", true, false) as OptionButton
	var amount_slider: HSlider = widget.find_child("LifeBankLoanAmountSlider", true, false) as HSlider
	var amount_label: Label = widget.find_child("LifeBankLoanAmountLabel", true, false) as Label
	var terms_label: Label = widget.find_child("LifeBankLoanTermsLabel", true, false) as Label
	var take_button: Button = widget.find_child("LifeBankLoanButton", true, false) as Button
	var active_panel: PanelContainer = widget.find_child("LifeActiveBankLoanPanel", true, false) as PanelContainer
	var active_label: Label = widget.find_child("LifeActiveBankLoanLabel", true, false) as Label
	if (
		panel == null or
		lender_selector == null or
		amount_slider == null or
		amount_label == null or
		terms_label == null or
		take_button == null or
		active_panel == null or
		active_label == null
	):
		_fail("Expected Life Finance bank-loan panel, selector, slider, labels, button, and active panel.")
		return
	if lender_selector.item_count <= 0:
		_fail("Expected bank-loan lender selector to list current-run lenders.")
		return
	if not amount_slider.editable:
		_fail("Expected bank-loan amount slider to be editable before borrowing.")
		return
	if take_button.disabled:
		_fail("Expected Take Bank Loan button to be enabled before borrowing: %s" % terms_label.text)
		return
	if not active_panel.visible:
		# The panel starts hidden until a regular bank loan is active.
		pass
	else:
		_fail("Expected active regular bank-loan panel to start hidden.")
		return

	var selected_offer: Dictionary = _offer_for_selector(offers, lender_selector)
	if selected_offer.is_empty():
		_fail("Expected selected UI lender to map to a bank-loan offer.")
		return
	var selected_amount: float = float(selected_offer.get("min_principal", amount_slider.value))
	amount_slider.value = selected_amount
	await get_tree().process_frame
	if not amount_label.text.contains("Amount"):
		_fail("Expected bank-loan amount label to update from slider.")
		return

	take_button.emit_signal("pressed")
	await get_tree().process_frame
	var active_bank_loan: Dictionary = RunState.get_active_bank_loan()
	if active_bank_loan.is_empty():
		_fail("Expected UI button to create active regular bank loan.")
		return
	widget.refresh()
	await get_tree().process_frame
	if not active_panel.visible:
		_fail("Expected active regular bank-loan panel to become visible after borrowing.")
		return
	if not active_label.text.contains(str(active_bank_loan.get("lender_ticker", ""))):
		_fail("Expected active bank-loan panel to show lender ticker: %s" % active_label.text)
		return
	if not take_button.disabled:
		_fail("Expected Take Bank Loan button to lock after borrowing.")
		return

	print("BANK_LOAN_LIFE_WIDGET_OK %s" % JSON.stringify({
		"lender": str(active_bank_loan.get("lender_ticker", "")),
		"principal": float(active_bank_loan.get("principal", 0.0)),
		"monthly_payment": float(active_bank_loan.get("monthly_payment", 0.0))
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


func _offer_for_selector(offers: Array, selector: OptionButton) -> Dictionary:
	var offer_id: String = ""
	if selector != null and selector.item_count > 0:
		offer_id = str(selector.get_item_metadata(max(selector.selected, 0)))
	for offer_value in offers:
		if typeof(offer_value) != TYPE_DICTIONARY:
			continue
		var offer: Dictionary = offer_value
		if str(offer.get("offer_id", "")) == offer_id:
			return offer
	return {}


func _fail(message: String) -> void:
	push_error(message)
	print("BANK_LOAN_LIFE_WIDGET_FAIL %s" % message)
	get_tree().quit(1)
