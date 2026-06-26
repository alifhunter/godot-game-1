extends Node

const BANK_LOAN_SYSTEM = preload("res://systems/BankLoanSystem.gd")
const RUN_SEED := 20260624


func _ready() -> void:
	var selected_companies: Array = [
		{
			"id": "payment_wallet",
			"ticker": "PYWT",
			"name": "Payment Wallet",
			"sector": "finance",
			"subsector": "digital_payments"
		},
		{
			"id": "bank_digital_karya",
			"ticker": "BDGK",
			"name": "Bank Digital Karya",
			"sector": "finance",
			"subsector": "digital_bank"
		},
		{
			"id": "cloud_vendor",
			"ticker": "CLDV",
			"name": "Cloud Vendor",
			"sector": "tech",
			"subsector": "cloud_infrastructure"
		},
		{
			"id": "bank_nusantara_raya",
			"ticker": "BNRY",
			"name": "Bank Nusantara Raya",
			"sector": "finance",
			"subsector": "large_bank"
		},
		{
			"id": "multi_finance_sejahtera",
			"ticker": "MFSJ",
			"name": "Multi Finance Sejahtera",
			"sector": "finance",
			"subsector": "consumer_finance"
		},
		{
			"id": "bank_desa_sejahtera",
			"ticker": "BDSJ",
			"name": "Bank Desa Sejahtera",
			"sector_id": "finance",
			"subsector": "small_bank"
		},
		{
			"id": "asuransi_nusa",
			"ticker": "ASRN",
			"name": "Asuransi Nusa",
			"sector": "finance",
			"subsector": "insurance"
		},
		{
			"id": "bank_orang_indonesia",
			"ticker": "BOID",
			"name": "Bank Orang Indonesia",
			"sector": "finance",
			"subsector": "banking"
		}
	]
	var run_context: Dictionary = {
		"run_seed": RUN_SEED,
		"difficulty_id": "grind"
	}
	var finance_snapshot: Dictionary = {
		"cash": 5000000.0,
		"equity": 120000000.0,
		"monthly_outflow": 6000000.0,
		"bankrupt": false,
		"active_bank_loan": {}
	}

	if not BANK_LOAN_SYSTEM.is_bank_lender(selected_companies[3]):
		_fail("Expected large bank to be recognized as lender.")
		return
	if not BANK_LOAN_SYSTEM.is_bank_lender(selected_companies[5]):
		_fail("Expected sector_id finance small bank to be recognized as lender.")
		return
	if BANK_LOAN_SYSTEM.is_bank_lender(selected_companies[0]):
		_fail("Digital payments company should not be a regular bank lender.")
		return
	if BANK_LOAN_SYSTEM.is_bank_lender(selected_companies[4]):
		_fail("Consumer finance company should not be a regular bank lender in the first pass.")
		return
	if BANK_LOAN_SYSTEM.is_bank_lender(selected_companies[6]):
		_fail("Insurance company should not be a regular bank lender.")
		return

	var offers: Array = BANK_LOAN_SYSTEM.build_lender_offers(selected_companies, run_context, finance_snapshot)
	var repeated_offers: Array = BANK_LOAN_SYSTEM.build_lender_offers(selected_companies, run_context, finance_snapshot)
	if JSON.stringify(offers) != JSON.stringify(repeated_offers):
		_fail("Expected offer contract to be deterministic for repeated fixed inputs.")
		return
	if offers.size() != 4:
		_fail("Expected four bank lender offers, got %d: %s" % [offers.size(), JSON.stringify(offers)])
		return
	var offer_ids: Array = _offer_lender_ids(offers)
	var expected_order: Array = ["bank_nusantara_raya", "bank_orang_indonesia", "bank_digital_karya", "bank_desa_sejahtera"]
	if JSON.stringify(offer_ids) != JSON.stringify(expected_order):
		_fail("Unexpected deterministic offer order. Expected %s, got %s." % [
			JSON.stringify(expected_order),
			JSON.stringify(offer_ids)
		])
		return
	if not _assert_no_offer(offers, "payment_wallet"):
		return
	if not _assert_no_offer(offers, "multi_finance_sejahtera"):
		return
	if not _assert_no_offer(offers, "asuransi_nusa"):
		return

	var large_offer: Dictionary = _find_offer(offers, "bank_nusantara_raya")
	var digital_offer: Dictionary = _find_offer(offers, "bank_digital_karya")
	var small_offer: Dictionary = _find_offer(offers, "bank_desa_sejahtera")
	if large_offer.is_empty() or digital_offer.is_empty() or small_offer.is_empty():
		_fail("Expected large, digital, and small bank offers to exist.")
		return
	if not bool(large_offer.get("eligible", false)):
		_fail("Expected large bank offer to be eligible: %s" % JSON.stringify(large_offer))
		return
	if float(large_offer.get("max_principal", 0.0)) <= float(digital_offer.get("max_principal", 0.0)):
		_fail("Expected large bank max principal to exceed digital bank max principal: %s vs %s" % [
			JSON.stringify(large_offer),
			JSON.stringify(digital_offer)
		])
		return
	if float(large_offer.get("repayment_multiplier", 0.0)) >= float(digital_offer.get("repayment_multiplier", 0.0)):
		_fail("Expected large bank repayment multiplier to be lower than digital bank.")
		return
	if float(small_offer.get("repayment_multiplier", 0.0)) <= float(digital_offer.get("repayment_multiplier", 0.0)):
		_fail("Expected small bank repayment multiplier to be higher than digital bank.")
		return
	if int(digital_offer.get("payment_count", 0)) != 6:
		_fail("Expected digital bank payment count to use subtype terms: %s" % JSON.stringify(digital_offer))
		return
	if not str(digital_offer.get("monthly_rate_label", "")).begins_with("Simple monthly rate"):
		_fail("Expected monthly rate label on digital bank offer.")
		return
	if float(large_offer.get("default_principal", 0.0)) < float(large_offer.get("min_principal", 0.0)):
		_fail("Default principal should not be below min principal.")
		return
	if float(large_offer.get("default_principal", 0.0)) > float(large_offer.get("max_principal", 0.0)):
		_fail("Default principal should not exceed max principal.")
		return

	var bankrupt_offers: Array = BANK_LOAN_SYSTEM.build_lender_offers(selected_companies, run_context, {
		"equity": 120000000.0,
		"monthly_outflow": 6000000.0,
		"bankrupt": true,
		"active_bank_loan": {}
	})
	if not _assert_all_disabled_with_reason(bankrupt_offers, "Bankrupt"):
		return

	var active_loan_offers: Array = BANK_LOAN_SYSTEM.build_lender_offers(selected_companies, run_context, {
		"equity": 120000000.0,
		"monthly_outflow": 6000000.0,
		"bankrupt": false,
		"active_bank_loan": {"id": "existing_bank_loan"}
	})
	if not _assert_all_disabled_with_reason(active_loan_offers, "already active"):
		return

	var low_cap_offers: Array = BANK_LOAN_SYSTEM.build_lender_offers([selected_companies[3]], run_context, {
		"equity": 500000.0,
		"monthly_outflow": 0.0,
		"bankrupt": false,
		"active_bank_loan": {}
	})
	if low_cap_offers.size() != 1:
		_fail("Expected low-cap fixture to return one disabled offer.")
		return
	if bool(low_cap_offers[0].get("eligible", true)):
		_fail("Expected low-cap offer to be disabled: %s" % JSON.stringify(low_cap_offers[0]))
		return
	if str(low_cap_offers[0].get("disabled_reason", "")).find("Current equity") < 0:
		_fail("Expected low-cap disabled reason to mention equity/outflow: %s" % JSON.stringify(low_cap_offers[0]))
		return

	print("BANK_LOAN_OFFER_CONTRACT_OK %s" % JSON.stringify({
		"offer_count": offers.size(),
		"lenders": offer_ids,
		"large_max": float(large_offer.get("max_principal", 0.0)),
		"digital_max": float(digital_offer.get("max_principal", 0.0)),
		"small_multiplier": float(small_offer.get("repayment_multiplier", 0.0))
	}))
	get_tree().quit(0)


func _offer_lender_ids(offers: Array) -> Array:
	var ids: Array = []
	for offer_value in offers:
		if typeof(offer_value) == TYPE_DICTIONARY:
			ids.append(str(offer_value.get("lender_id", "")))
	return ids


func _find_offer(offers: Array, lender_id: String) -> Dictionary:
	for offer_value in offers:
		if typeof(offer_value) != TYPE_DICTIONARY:
			continue
		var offer: Dictionary = offer_value
		if str(offer.get("lender_id", "")) == lender_id:
			return offer
	return {}


func _assert_no_offer(offers: Array, lender_id: String) -> bool:
	var offer: Dictionary = _find_offer(offers, lender_id)
	if not offer.is_empty():
		_fail("Expected no bank-loan offer for '%s', got %s." % [lender_id, JSON.stringify(offer)])
		return false
	return true


func _assert_all_disabled_with_reason(offers: Array, expected_text: String) -> bool:
	if offers.is_empty():
		_fail("Expected disabled offers, got none.")
		return false
	for offer_value in offers:
		if typeof(offer_value) != TYPE_DICTIONARY:
			_fail("Offer should be dictionary: %s" % str(offer_value))
			return false
		var offer: Dictionary = offer_value
		if bool(offer.get("eligible", true)):
			_fail("Expected offer to be disabled: %s" % JSON.stringify(offer))
			return false
		if str(offer.get("disabled_reason", "")).find(expected_text) < 0:
			_fail("Expected disabled reason to contain '%s': %s" % [expected_text, JSON.stringify(offer)])
			return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	print("BANK_LOAN_OFFER_CONTRACT_FAIL: %s" % message)
	get_tree().quit(1)
