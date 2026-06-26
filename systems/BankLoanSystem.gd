extends RefCounted

const STABLE_RNG = preload("res://systems/StableRng.gd")

const DEFAULT_MIN_PRINCIPAL := 1000000.0
const DEFAULT_STEP_SIZE := 500000.0
const DEFAULT_MIN_OUTFLOW_PCT := 0.28
const DEFAULT_DEFAULT_OUTFLOW_MONTHS := 0.75
const DEFAULT_PAYMENT_BURDEN_PCT := 0.16

const LENDER_SUBSECTORS := {
	"banking": true,
	"large_bank": true,
	"mid_market_bank": true,
	"small_bank": true,
	"regional_bank": true,
	"sharia_bank": true,
	"digital_bank": true,
	"trade_finance_bank": true,
	"micro_lending_bank": true
}

const SUBSECTOR_TERMS := {
	"large_bank": {
		"equity_cap_pct": 0.90,
		"payment_burden_pct": 0.14,
		"payment_count": 10,
		"repayment_multiplier": 1.08,
		"risk_tier": "low",
		"priority": 10,
		"step_size": 1000000.0
	},
	"regional_bank": {
		"equity_cap_pct": 0.80,
		"payment_burden_pct": 0.14,
		"payment_count": 10,
		"repayment_multiplier": 1.10,
		"risk_tier": "low",
		"priority": 15,
		"step_size": 1000000.0
	},
	"banking": {
		"equity_cap_pct": 0.72,
		"payment_burden_pct": 0.16,
		"payment_count": 9,
		"repayment_multiplier": 1.12,
		"risk_tier": "moderate",
		"priority": 20,
		"step_size": 1000000.0
	},
	"mid_market_bank": {
		"equity_cap_pct": 0.68,
		"payment_burden_pct": 0.16,
		"payment_count": 9,
		"repayment_multiplier": 1.12,
		"risk_tier": "moderate",
		"priority": 22,
		"step_size": 1000000.0
	},
	"trade_finance_bank": {
		"equity_cap_pct": 0.62,
		"payment_burden_pct": 0.17,
		"payment_count": 8,
		"repayment_multiplier": 1.11,
		"risk_tier": "moderate",
		"priority": 25,
		"step_size": 1000000.0
	},
	"sharia_bank": {
		"equity_cap_pct": 0.56,
		"payment_burden_pct": 0.17,
		"payment_count": 8,
		"repayment_multiplier": 1.10,
		"risk_tier": "moderate",
		"priority": 30,
		"step_size": 1000000.0
	},
	"digital_bank": {
		"equity_cap_pct": 0.56,
		"payment_burden_pct": 0.20,
		"payment_count": 6,
		"repayment_multiplier": 1.16,
		"risk_tier": "high",
		"priority": 45,
		"step_size": 500000.0
	},
	"small_bank": {
		"equity_cap_pct": 0.48,
		"payment_burden_pct": 0.21,
		"payment_count": 6,
		"repayment_multiplier": 1.18,
		"risk_tier": "high",
		"priority": 50,
		"step_size": 500000.0
	},
	"micro_lending_bank": {
		"equity_cap_pct": 0.38,
		"payment_burden_pct": 0.22,
		"payment_count": 5,
		"repayment_multiplier": 1.22,
		"risk_tier": "very_high",
		"priority": 60,
		"step_size": 500000.0
	}
}

const DIFFICULTY_BALANCE := {
	"conservative": {
		"equity_cap_multiplier": 0.85,
		"payment_burden_multiplier": 0.80,
		"min_outflow_pct": 0.25,
		"default_outflow_months": 0.55
	},
	"normal": {
		"equity_cap_multiplier": 1.00,
		"payment_burden_multiplier": 0.90,
		"min_outflow_pct": 0.28,
		"default_outflow_months": 0.70
	},
	"hard": {
		"equity_cap_multiplier": 1.10,
		"payment_burden_multiplier": 1.00,
		"min_outflow_pct": 0.27,
		"default_outflow_months": 0.78
	},
	"grind": {
		"equity_cap_multiplier": 1.25,
		"payment_burden_multiplier": 1.15,
		"min_outflow_pct": 0.25,
		"default_outflow_months": 0.82
	}
}


static func is_bank_lender(company: Dictionary) -> bool:
	var company_id: String = str(company.get("id", "")).strip_edges()
	if company_id.is_empty():
		return false
	var sector_id: String = _sector_id(company)
	if sector_id != "finance":
		return false
	return LENDER_SUBSECTORS.has(_subsector(company))


static func build_lender_offers(selected_companies: Array, run_context: Dictionary = {}, finance_snapshot: Dictionary = {}) -> Array:
	var offers: Array = []
	for company_value in selected_companies:
		if typeof(company_value) != TYPE_DICTIONARY:
			continue
		var company: Dictionary = company_value
		if not is_bank_lender(company):
			continue
		offers.append(_build_offer(company, run_context, finance_snapshot))

	offers.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_priority: int = int(left.get("offer_priority", 999))
		var right_priority: int = int(right.get("offer_priority", 999))
		if left_priority == right_priority:
			var left_ticker: String = str(left.get("lender_ticker", ""))
			var right_ticker: String = str(right.get("lender_ticker", ""))
			if left_ticker == right_ticker:
				return str(left.get("lender_id", "")) < str(right.get("lender_id", ""))
			return left_ticker < right_ticker
		return left_priority < right_priority
	)
	return offers


static func _build_offer(company: Dictionary, run_context: Dictionary, finance_snapshot: Dictionary) -> Dictionary:
	var subsector_id: String = _subsector(company)
	var terms: Dictionary = SUBSECTOR_TERMS.get(subsector_id, SUBSECTOR_TERMS.get("banking", {}))
	var run_seed: int = int(run_context.get("run_seed", run_context.get("seed", 0)))
	var equity: float = max(float(finance_snapshot.get("equity", run_context.get("equity", 0.0))), 0.0)
	var monthly_outflow: float = max(float(finance_snapshot.get("monthly_outflow", run_context.get("monthly_outflow", 0.0))), 0.0)
	var step_size: float = max(float(terms.get("step_size", DEFAULT_STEP_SIZE)), 1.0)
	var payment_count: int = max(int(terms.get("payment_count", 6)), 1)
	var repayment_multiplier: float = _repayment_multiplier(company, terms, run_seed)
	var min_principal: float = _min_principal(monthly_outflow, run_context, step_size)
	var max_principal: float = _max_principal(equity, monthly_outflow, terms, run_context, step_size, payment_count, repayment_multiplier)
	var default_principal: float = _default_principal(min_principal, max_principal, monthly_outflow, step_size, run_context)
	var total_repayment_at_default: float = default_principal * repayment_multiplier
	var monthly_payment_at_default: float = total_repayment_at_default / float(payment_count)
	var total_repayment_at_max: float = max_principal * repayment_multiplier
	var monthly_payment_at_max: float = total_repayment_at_max / float(payment_count)
	var default_burden_pct: float = _payment_burden_pct(monthly_payment_at_default, monthly_outflow)
	var max_burden_pct: float = _payment_burden_pct(monthly_payment_at_max, monthly_outflow)
	var max_payment_burden_pct: float = _max_payment_burden_pct(terms, run_context)
	var disabled_reason: String = _disabled_reason(min_principal, max_principal, finance_snapshot)

	return {
		"offer_id": "bank_loan:%s:%s" % [run_seed, str(company.get("id", ""))],
		"lender_id": str(company.get("id", "")),
		"lender_ticker": str(company.get("ticker", "")),
		"lender_name": str(company.get("name", "")),
		"lender_subsector": subsector_id,
		"min_principal": min_principal,
		"max_principal": max_principal,
		"step_size": step_size,
		"default_principal": default_principal,
		"payment_count": payment_count,
		"repayment_multiplier": repayment_multiplier,
		"monthly_rate_label": _monthly_rate_label(repayment_multiplier, payment_count, subsector_id),
		"risk_tier": str(terms.get("risk_tier", "moderate")),
		"approval_reason": _approval_reason(company, max_principal, payment_count, repayment_multiplier),
		"balance_note": _balance_note(max_burden_pct),
		"disabled_reason": disabled_reason,
		"eligible": disabled_reason.is_empty(),
		"offer_priority": int(terms.get("priority", 999)),
		"total_repayment_at_default": total_repayment_at_default,
		"monthly_payment_at_default": monthly_payment_at_default,
		"total_repayment_at_max": total_repayment_at_max,
		"monthly_payment_at_max": monthly_payment_at_max,
		"payment_burden_pct_at_default": default_burden_pct,
		"payment_burden_pct_at_max": max_burden_pct,
		"max_payment_burden_pct": max_payment_burden_pct
	}


static func _sector_id(company: Dictionary) -> String:
	return str(company.get("sector_id", company.get("sector", ""))).strip_edges().to_lower()


static func _subsector(company: Dictionary) -> String:
	return str(company.get("subsector", "")).strip_edges().to_lower()


static func _min_principal(monthly_outflow: float, run_context: Dictionary, step_size: float) -> float:
	var profile: Dictionary = _difficulty_balance_profile(run_context)
	var outflow_floor: float = monthly_outflow * float(profile.get("min_outflow_pct", DEFAULT_MIN_OUTFLOW_PCT))
	return _round_up_to_step(max(DEFAULT_MIN_PRINCIPAL, outflow_floor), step_size)


static func _max_principal(equity: float, monthly_outflow: float, terms: Dictionary, run_context: Dictionary, step_size: float, payment_count: int, repayment_multiplier: float) -> float:
	var profile: Dictionary = _difficulty_balance_profile(run_context)
	var equity_cap_multiplier: float = float(profile.get("equity_cap_multiplier", 1.0))
	var equity_cap: float = max(equity * float(terms.get("equity_cap_pct", 0.0)) * equity_cap_multiplier, 0.0)
	var raw_cap: float = equity_cap
	if monthly_outflow > 0.0:
		var monthly_payment_cap: float = monthly_outflow * _max_payment_burden_pct(terms, run_context)
		var principal_cap_by_payment: float = monthly_payment_cap * float(max(payment_count, 1)) / max(repayment_multiplier, 0.0001)
		raw_cap = min(equity_cap, principal_cap_by_payment)
	return _round_down_to_step(max(raw_cap, 0.0), step_size)


static func _difficulty_balance_profile(run_context: Dictionary) -> Dictionary:
	var profile_id: String = _difficulty_profile_id(run_context)
	var profile: Dictionary = DIFFICULTY_BALANCE.get(profile_id, DIFFICULTY_BALANCE.get("normal", {}))
	return profile


static func _difficulty_profile_id(run_context: Dictionary) -> String:
	var explicit_multiplier: float = float(run_context.get("bank_loan_cap_multiplier", 0.0))
	if explicit_multiplier > 0.0:
		if explicit_multiplier <= 0.90:
			return "conservative"
		if explicit_multiplier >= 1.20:
			return "grind"
		if explicit_multiplier >= 1.05:
			return "hard"
		return "normal"
	var difficulty_text: String = "%s|%s|%s" % [
		str(run_context.get("difficulty_id", "")),
		str(run_context.get("start_mode", "")),
		str(run_context.get("mode", ""))
	]
	difficulty_text = difficulty_text.to_lower()
	if difficulty_text.find("grind") >= 0:
		return "grind"
	if difficulty_text.find("hard") >= 0:
		return "hard"
	if difficulty_text.find("conservative") >= 0 or difficulty_text.find("easy") >= 0:
		return "conservative"
	return "normal"


static func _max_payment_burden_pct(terms: Dictionary, run_context: Dictionary) -> float:
	var profile: Dictionary = _difficulty_balance_profile(run_context)
	var burden_pct: float = float(terms.get("payment_burden_pct", DEFAULT_PAYMENT_BURDEN_PCT))
	var burden_multiplier: float = float(profile.get("payment_burden_multiplier", 1.0))
	return clamp(burden_pct * burden_multiplier, 0.08, 0.30)


static func _repayment_multiplier(company: Dictionary, terms: Dictionary, run_seed: int) -> float:
	var company_id: String = str(company.get("id", ""))
	var jitter: float = (STABLE_RNG.unit_float(["bank_loan_terms", run_seed, company_id]) - 0.5) * 0.02
	return snappedf(clamp(float(terms.get("repayment_multiplier", 1.12)) + jitter, 1.02, 1.35), 0.001)


static func _default_principal(min_principal: float, max_principal: float, monthly_outflow: float, step_size: float, run_context: Dictionary) -> float:
	if max_principal + 0.0001 < min_principal:
		return 0.0
	var profile: Dictionary = _difficulty_balance_profile(run_context)
	var target: float = max(min_principal, monthly_outflow * float(profile.get("default_outflow_months", DEFAULT_DEFAULT_OUTFLOW_MONTHS)))
	return clamp(_round_down_to_step(target, step_size), min_principal, max_principal)


static func _payment_burden_pct(monthly_payment: float, monthly_outflow: float) -> float:
	if monthly_outflow <= 0.0:
		return 0.0
	return max(monthly_payment, 0.0) / monthly_outflow


static func _balance_note(max_burden_pct: float) -> String:
	if max_burden_pct >= 0.20:
		return "High payment drag."
	if max_burden_pct >= 0.14:
		return "Meaningful monthly drag."
	return "Conservative payment drag."


static func _disabled_reason(min_principal: float, max_principal: float, finance_snapshot: Dictionary) -> String:
	if bool(finance_snapshot.get("bankrupt", false)):
		return "Bankrupt runs cannot take regular bank loans."
	var active_bank_loan: Dictionary = finance_snapshot.get("active_bank_loan", {})
	if not active_bank_loan.is_empty():
		return "A regular bank loan is already active."
	if max_principal + 0.0001 < min_principal:
		return "Current equity and monthly outflow do not support a regular bank loan."
	return ""


static func _approval_reason(company: Dictionary, max_principal: float, payment_count: int, repayment_multiplier: float) -> String:
	return "%s can offer up to %s across %d monthly payments at %.1f%% total repayment premium." % [
		str(company.get("ticker", company.get("name", "This lender"))),
		_format_currency(max_principal),
		payment_count,
		(repayment_multiplier - 1.0) * 100.0
	]


static func _monthly_rate_label(repayment_multiplier: float, payment_count: int, subsector_id: String) -> String:
	var monthly_simple_rate: float = ((repayment_multiplier - 1.0) / float(max(payment_count, 1))) * 100.0
	var label_prefix: String = "Simple monthly rate"
	if subsector_id == "sharia_bank":
		label_prefix = "Simple monthly margin"
	return "%s %.2f%%" % [label_prefix, monthly_simple_rate]


static func _round_up_to_step(value: float, step_size: float) -> float:
	if step_size <= 0.0:
		return value
	return ceil(value / step_size) * step_size


static func _round_down_to_step(value: float, step_size: float) -> float:
	if step_size <= 0.0:
		return value
	return floor(value / step_size) * step_size


static func _format_currency(value: float) -> String:
	if value >= 1000000000.0:
		return "Rp%.1fb" % (value / 1000000000.0)
	if value >= 1000000.0:
		return "Rp%.1fm" % (value / 1000000.0)
	return "Rp%d" % int(round(value))
