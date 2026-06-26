extends RefCounted

const STABLE_RNG = preload("res://systems/StableRng.gd")

const SCHEMA_VERSION := 1
const SOURCE_SYSTEM_ID := "company_story_dossier"
const DEFAULT_DOSSIERS_PER_COMPANY := 1
const DEFAULT_MAX_DOSSIERS := 30
const DEFAULT_START_DAY_MIN := 5
const DEFAULT_START_DAY_MAX := 75
const DEFAULT_RESOLUTION_MIN_DAYS := 45
const DEFAULT_RESOLUTION_MAX_DAYS := 170

const TRUTH_STATES := ["real", "delayed", "failed", "overhyped", "fraud_risk", "uncertain"]
const PUBLIC_STATUSES := ["silent", "rumor", "reported", "confirmed", "questioned", "disputed", "resolved"]
const STAGE_IDS := ["seeded", "public_chatter", "private_whisper", "filing_hint", "execution_window", "resolution", "aftermath"]
const DISCLOSURE_PLACEMENT_SCHEMA_VERSION := 1
const DISCLOSURE_PACKET_SCHEMA_VERSION := 1
const DISCLOSURE_SURFACE_ID := "annual_report"
const DISCLOSURE_SUBTLETY_BANDS := ["direct", "implied", "buried", "conflicting", "missing"]
const DISCLOSURE_READER_EFFORT_BY_SUBTLETY := {
	"direct": "low",
	"implied": "medium",
	"buried": "high",
	"conflicting": "high",
	"missing": "high"
}
const DISCLOSURE_EVIDENCE_DENSITY_BY_SUBTLETY := {
	"direct": "clear",
	"implied": "partial",
	"buried": "thin",
	"conflicting": "contradictory",
	"missing": "absent"
}
const DISCLOSURE_FRAGMENT_ROLES_BY_SUBTLETY := {
	"direct": "anchor",
	"implied": "context",
	"buried": "cross_check",
	"conflicting": "risk_signal",
	"missing": "absence_signal"
}

const DISCLOSURE_SECTION_DEFINITIONS := {
	"revenue": {
		"label": "Revenue",
		"group": "profit_or_loss",
		"annual_statement_note_type": "revenue"
	},
	"segment_information": {
		"label": "Segment Information",
		"group": "notes",
		"annual_statement_note_type": "segment_information"
	},
	"trade_receivables": {
		"label": "Trade Receivables",
		"group": "financial_position",
		"annual_statement_note_type": "trade_receivables"
	},
	"inventories": {
		"label": "Inventories",
		"group": "financial_position",
		"annual_statement_note_type": "inventories"
	},
	"property_plant_and_equipment": {
		"label": "Property, Plant, And Equipment",
		"group": "financial_position",
		"annual_statement_note_type": "property_plant_and_equipment"
	},
	"debt_and_borrowings": {
		"label": "Debt And Borrowings",
		"group": "financial_position",
		"annual_statement_note_type": "debt_and_borrowings"
	},
	"related_party_transactions": {
		"label": "Related Party Transactions",
		"group": "notes",
		"annual_statement_note_type": "related_party_transactions"
	},
	"commitments_contingencies": {
		"label": "Commitments And Contingencies",
		"group": "notes",
		"annual_statement_note_type": "commitments_contingencies_and_subsequent_events"
	},
	"subsequent_events": {
		"label": "Subsequent Events",
		"group": "notes",
		"annual_statement_note_type": "commitments_contingencies_and_subsequent_events"
	},
	"cash_flow_information": {
		"label": "Cash Flow Information",
		"group": "cash_flows",
		"annual_statement_note_type": "cash_flow_information"
	}
}

const NOTE_TYPE_DISCLOSURE_SECTIONS := {
	"capex_progress": ["property_plant_and_equipment", "cash_flow_information", "commitments_contingencies", "subsequent_events"],
	"margin_bridge": ["segment_information", "inventories", "revenue", "cash_flow_information"],
	"commodity_price_realization": ["revenue", "segment_information", "inventories", "cash_flow_information"],
	"input_cost_pressure": ["inventories", "segment_information", "cash_flow_information", "revenue"],
	"customer_contract": ["revenue", "segment_information", "trade_receivables", "commitments_contingencies"],
	"turnaround_progress": ["segment_information", "cash_flow_information", "debt_and_borrowings", "subsequent_events"],
	"governance_note": ["related_party_transactions", "trade_receivables", "commitments_contingencies", "subsequent_events"],
	"debt_maturity": ["debt_and_borrowings", "cash_flow_information", "commitments_contingencies", "subsequent_events"],
	"statement_contradiction": ["trade_receivables", "inventories", "related_party_transactions", "cash_flow_information"],
	"use_of_proceeds": ["cash_flow_information", "property_plant_and_equipment", "debt_and_borrowings", "subsequent_events"]
}

const METRIC_DISCLOSURE_SECTIONS := {
	"revenue": ["revenue", "segment_information", "trade_receivables"],
	"gross_margin": ["revenue", "segment_information", "inventories"],
	"operating_margin": ["segment_information", "cash_flow_information"],
	"net_income": ["revenue", "segment_information", "cash_flow_information"],
	"cash": ["cash_flow_information", "debt_and_borrowings"],
	"debt": ["debt_and_borrowings", "cash_flow_information"],
	"capex": ["property_plant_and_equipment", "cash_flow_information", "commitments_contingencies"],
	"working_capital": ["trade_receivables", "inventories", "cash_flow_information"],
	"inventory": ["inventories", "cash_flow_information"],
	"receivables": ["trade_receivables", "related_party_transactions"],
	"customer_concentration": ["revenue", "segment_information", "trade_receivables"],
	"production_volume": ["segment_information", "property_plant_and_equipment"],
	"backlog": ["revenue", "segment_information", "commitments_contingencies"]
}

const ARCHETYPE_DISCLOSURE_SECTIONS := {
	"capex_expansion": ["property_plant_and_equipment", "commitments_contingencies", "cash_flow_information"],
	"margin_recovery": ["revenue", "segment_information", "inventories"],
	"commodity_tailwind": ["revenue", "segment_information", "inventories"],
	"commodity_headwind": ["inventories", "cash_flow_information", "segment_information"],
	"contract_win": ["revenue", "segment_information", "trade_receivables", "commitments_contingencies"],
	"turnaround": ["segment_information", "cash_flow_information", "debt_and_borrowings"],
	"governance_risk": ["related_party_transactions", "trade_receivables", "commitments_contingencies"],
	"balance_sheet_stress": ["debt_and_borrowings", "cash_flow_information", "subsequent_events"],
	"fraud_signal": ["trade_receivables", "inventories", "related_party_transactions"],
	"corporate_action_use_of_proceeds": ["cash_flow_information", "property_plant_and_equipment", "debt_and_borrowings", "subsequent_events"]
}

const ARCHETYPE_DEFINITIONS := {
	"capex_expansion": {
		"story_family": "growth_project",
		"base_priority": 0.62,
		"price_bias": 0.58,
		"sector_ids": ["consumer", "industrial", "infra", "property", "energy", "tech", "transport", "basicindustry"],
		"hook_keywords": ["capex", "expansion", "rollout", "capacity", "plant", "warehouse", "terminal", "network", "store", "franchise", "data_center", "fleet", "project"],
		"moat_keywords": ["scale", "network", "distribution", "density", "infrastructure", "execution", "capacity"],
		"metric_ids": ["capex", "cash", "debt", "production_volume"],
		"note_type": "capex_progress",
		"truth_weights": {"real": 34, "delayed": 26, "failed": 14, "overhyped": 12, "fraud_risk": 4, "uncertain": 10}
	},
	"margin_recovery": {
		"story_family": "earnings_quality",
		"base_priority": 0.58,
		"price_bias": 0.46,
		"sector_ids": ["consumer", "noncyclical", "industrial", "transport", "basicindustry", "property"],
		"hook_keywords": ["margin", "normalization", "recovery", "reset", "pricing", "premiumization", "cost", "efficiency"],
		"moat_keywords": ["pricing", "brand", "supplier", "scale", "procurement", "efficiency"],
		"metric_ids": ["gross_margin", "operating_margin", "net_income"],
		"note_type": "margin_bridge",
		"truth_weights": {"real": 32, "delayed": 16, "failed": 14, "overhyped": 18, "fraud_risk": 4, "uncertain": 16}
	},
	"commodity_tailwind": {
		"story_family": "macro_linked",
		"base_priority": 0.64,
		"price_bias": 0.52,
		"sector_ids": ["energy", "noncyclical", "basicindustry", "industrial"],
		"hook_keywords": ["commodity", "volume", "export", "price", "cycle", "recovery", "royalty", "smelter"],
		"moat_keywords": ["reserve", "concession", "upstream", "procurement", "scale"],
		"metric_ids": ["revenue", "gross_margin", "production_volume"],
		"note_type": "commodity_price_realization",
		"truth_weights": {"real": 38, "delayed": 13, "failed": 9, "overhyped": 20, "fraud_risk": 4, "uncertain": 16}
	},
	"commodity_headwind": {
		"story_family": "macro_linked",
		"base_priority": 0.60,
		"price_bias": -0.52,
		"sector_ids": ["consumer", "transport", "industrial", "property", "noncyclical", "basicindustry"],
		"hook_keywords": ["pressure", "squeeze", "overhang", "shortage", "cost", "inventory", "input", "working_capital"],
		"moat_keywords": ["procurement", "supplier", "warehouse", "cost_control"],
		"metric_ids": ["gross_margin", "working_capital", "inventory"],
		"note_type": "input_cost_pressure",
		"truth_weights": {"real": 34, "delayed": 10, "failed": 20, "overhyped": 12, "fraud_risk": 4, "uncertain": 20}
	},
	"contract_win": {
		"story_family": "demand_signal",
		"base_priority": 0.66,
		"price_bias": 0.62,
		"sector_ids": ["infra", "industrial", "tech", "health", "transport", "finance", "property", "consumer"],
		"hook_keywords": ["contract", "customer", "backlog", "government", "distribution", "partnership", "enterprise", "tender"],
		"moat_keywords": ["customer", "license", "relationship", "distribution", "network", "platform"],
		"metric_ids": ["revenue", "backlog", "customer_concentration"],
		"note_type": "customer_contract",
		"truth_weights": {"real": 34, "delayed": 18, "failed": 12, "overhyped": 18, "fraud_risk": 4, "uncertain": 14}
	},
	"turnaround": {
		"story_family": "execution_reset",
		"base_priority": 0.54,
		"price_bias": 0.38,
		"sector_ids": ["consumer", "transport", "property", "industrial", "finance", "health", "tech"],
		"hook_keywords": ["turnaround", "reset", "restructuring", "closure", "utilization", "recovery", "cost", "asset_sale"],
		"moat_keywords": ["management", "asset", "brand", "regional", "network"],
		"metric_ids": ["operating_margin", "cash", "debt"],
		"note_type": "turnaround_progress",
		"truth_weights": {"real": 24, "delayed": 18, "failed": 20, "overhyped": 16, "fraud_risk": 4, "uncertain": 18}
	},
	"governance_risk": {
		"story_family": "risk_control",
		"base_priority": 0.50,
		"price_bias": -0.58,
		"sector_ids": [],
		"hook_keywords": ["governance", "audit", "management", "related_party", "dispute", "delay", "regulator", "license"],
		"moat_keywords": ["family", "license", "concession", "related", "single_customer"],
		"metric_ids": ["cash", "debt", "receivables"],
		"note_type": "governance_note",
		"truth_weights": {"real": 18, "delayed": 8, "failed": 18, "overhyped": 12, "fraud_risk": 24, "uncertain": 20}
	},
	"balance_sheet_stress": {
		"story_family": "funding_risk",
		"base_priority": 0.52,
		"price_bias": -0.48,
		"sector_ids": ["property", "transport", "infra", "industrial", "finance", "tech"],
		"hook_keywords": ["debt", "refinancing", "working_capital", "rights_issue", "cash", "covenant", "funding"],
		"moat_keywords": ["leverage", "capital_intensive", "asset_heavy"],
		"metric_ids": ["debt", "cash", "working_capital"],
		"note_type": "debt_maturity",
		"truth_weights": {"real": 30, "delayed": 10, "failed": 18, "overhyped": 8, "fraud_risk": 10, "uncertain": 24}
	},
	"fraud_signal": {
		"story_family": "quality_warning",
		"base_priority": 0.46,
		"price_bias": -0.66,
		"sector_ids": [],
		"hook_keywords": ["fraud", "aggressive", "mismatch", "receivable", "inventory", "audit", "regulator", "claim"],
		"moat_keywords": ["opaque", "single_customer", "related_party"],
		"metric_ids": ["receivables", "inventory", "cash"],
		"note_type": "statement_contradiction",
		"truth_weights": {"real": 10, "delayed": 6, "failed": 18, "overhyped": 18, "fraud_risk": 34, "uncertain": 14}
	},
	"corporate_action_use_of_proceeds": {
		"story_family": "capital_allocation",
		"base_priority": 0.56,
		"price_bias": 0.34,
		"sector_ids": [],
		"hook_keywords": ["rights", "placement", "acquisition", "buyback", "proceeds", "dilution", "merger", "asset_sale"],
		"moat_keywords": ["acquirer", "capital", "asset", "platform"],
		"metric_ids": ["cash", "debt", "capex"],
		"note_type": "use_of_proceeds",
		"truth_weights": {"real": 26, "delayed": 18, "failed": 16, "overhyped": 18, "fraud_risk": 6, "uncertain": 16}
	}
}


func generate_dossiers(run_seed: int, company_definitions: Array, macro_state: Dictionary = {}, options: Dictionary = {}) -> Array:
	var max_dossiers: int = int(options.get("max_dossiers", min(company_definitions.size(), DEFAULT_MAX_DOSSIERS)))
	var dossiers_per_company: int = max(1, int(options.get("dossiers_per_company", DEFAULT_DOSSIERS_PER_COMPANY)))
	if max_dossiers <= 0:
		return []

	var candidate_rows: Array = []
	for company_index in range(company_definitions.size()):
		if typeof(company_definitions[company_index]) != TYPE_DICTIONARY:
			continue
		var company_definition: Dictionary = company_definitions[company_index]
		var ranked_candidates: Array = _ranked_candidates(run_seed, company_definition, macro_state, company_index)
		var limit: int = min(dossiers_per_company, ranked_candidates.size())
		for candidate_index in range(limit):
			var candidate: Dictionary = ranked_candidates[candidate_index]
			candidate_rows.append({
				"company_definition": company_definition,
				"company_index": company_index,
				"slot_index": candidate_index,
				"candidate": candidate,
				"score": float(candidate.get("score", 0.0))
			})

	candidate_rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if is_equal_approx(float(left.get("score", 0.0)), float(right.get("score", 0.0))):
			var left_company: Dictionary = left.get("company_definition", {})
			var right_company: Dictionary = right.get("company_definition", {})
			return str(left_company.get("id", "")) < str(right_company.get("id", ""))
		return float(left.get("score", 0.0)) > float(right.get("score", 0.0))
	)
	if candidate_rows.size() > max_dossiers:
		candidate_rows = candidate_rows.slice(0, max_dossiers)

	var dossiers: Array = []
	for row_value in candidate_rows:
		var row: Dictionary = row_value
		dossiers.append(generate_company_dossier(
			run_seed,
			row.get("company_definition", {}),
			macro_state,
			int(row.get("company_index", 0)),
			{
				"slot_index": int(row.get("slot_index", 0)),
				"candidate": row.get("candidate", {})
			}
		))

	dossiers.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if is_equal_approx(float(left.get("priority", 0.0)), float(right.get("priority", 0.0))):
			return str(left.get("story_id", "")) < str(right.get("story_id", ""))
		return float(left.get("priority", 0.0)) > float(right.get("priority", 0.0))
	)
	return dossiers


func generate_company_dossier(run_seed: int, company_definition: Dictionary, macro_state: Dictionary = {}, company_index: int = 0, options: Dictionary = {}) -> Dictionary:
	var candidate: Dictionary = options.get("candidate", {})
	if candidate.is_empty():
		var ranked_candidates: Array = _ranked_candidates(run_seed, company_definition, macro_state, company_index)
		candidate = ranked_candidates[0] if not ranked_candidates.is_empty() else {"archetype_id": "turnaround", "hook_id": "turnaround", "score": 1.0}
	var slot_index: int = int(options.get("slot_index", 0))
	var archetype_id: String = str(candidate.get("archetype_id", "turnaround"))
	var archetype: Dictionary = _archetype(archetype_id)
	var hook_id: String = str(candidate.get("hook_id", _fallback_hook_for_archetype(archetype_id)))
	var company_id: String = str(company_definition.get("id", "company_%d" % company_index))
	var ticker: String = str(company_definition.get("ticker", company_id.substr(0, min(4, company_id.length())).to_upper()))
	var story_seed: int = STABLE_RNG.seed_from_parts([run_seed, SOURCE_SYSTEM_ID, company_id, archetype_id, hook_id, slot_index])
	var story_hash: String = str(story_seed)
	var story_id: String = "story|%s|%s|%s" % [company_id, archetype_id, story_hash]
	var truth_state: String = _select_truth_state(run_seed, company_definition, macro_state, archetype_id, story_id)
	var started_day: int = STABLE_RNG.int_between([run_seed, story_id, "start_day"], DEFAULT_START_DAY_MIN, DEFAULT_START_DAY_MAX)
	var duration_days: int = STABLE_RNG.int_between([run_seed, story_id, "resolution_days"], DEFAULT_RESOLUTION_MIN_DAYS, DEFAULT_RESOLUTION_MAX_DAYS)
	var expected_resolution_day: int = started_day + duration_days
	var confidence: float = _internal_confidence(run_seed, story_id, candidate, truth_state)
	var priority: float = snappedf(clamp(float(candidate.get("score", 0.0)) / 6.0, 0.05, 1.0), 0.001)
	var stage_id: String = _stage_for_seed(run_seed, story_id, priority)
	var public_status: String = _public_status_for_truth(run_seed, story_id, truth_state, stage_id)
	var cause_facts: Array = _build_cause_facts(story_id, company_definition, macro_state, candidate, archetype_id, truth_state)
	var timeline: Array = _build_timeline(story_id, started_day, expected_resolution_day, truth_state, cause_facts)
	var financial_effects: Array = _build_financial_effects(story_id, archetype_id, truth_state, confidence)
	var price_effects: Dictionary = _build_price_effects(story_id, archetype_id, truth_state, confidence, duration_days, candidate)
	var public_clues: Array = _build_public_clues(story_id, archetype_id, public_status, started_day, cause_facts, truth_state)
	var private_clues: Array = _build_private_clues(story_id, archetype_id, started_day, cause_facts, truth_state, priority)
	var statement_clues: Array = _build_statement_clues(story_id, archetype_id, expected_resolution_day, financial_effects, truth_state)
	var disclosure_placements: Array = _build_disclosure_placements(story_id, archetype_id, cause_facts, financial_effects, statement_clues, truth_state, public_status, stage_id)
	var disclosure_packets: Array = _build_disclosure_packets(story_id, archetype_id, disclosure_placements)
	var thesis_hooks: Array = _build_thesis_hooks(story_id, archetype_id, company_definition, cause_facts, financial_effects)
	var resolution_conditions: Array = _build_resolution_conditions(story_id, archetype_id, truth_state, expected_resolution_day, financial_effects)

	return {
		"schema_version": SCHEMA_VERSION,
		"story_id": story_id,
		"company_id": company_id,
		"ticker": ticker,
		"archetype_id": archetype_id,
		"story_family": str(archetype.get("story_family", "company_story")),
		"hook_id": hook_id,
		"truth_state": truth_state,
		"public_status": public_status,
		"stage_id": stage_id,
		"priority": priority,
		"confidence": confidence,
		"started_day_index": started_day,
		"expected_resolution_day_index": expected_resolution_day,
		"resolved_day_index": -1,
		"outcome_state": "",
		"cause_facts": cause_facts,
		"timeline": timeline,
		"financial_effects": financial_effects,
		"price_effects": price_effects,
		"public_clues": public_clues,
		"private_clues": private_clues,
		"statement_clues": statement_clues,
		"disclosure_placements": disclosure_placements,
		"disclosure_packets": disclosure_packets,
		"thesis_hooks": thesis_hooks,
		"resolution_conditions": resolution_conditions,
		"traceability": _build_traceability(run_seed, story_id, company_definition, hook_id, cause_facts, public_clues, private_clues, statement_clues, financial_effects, disclosure_placements, disclosure_packets)
	}


func ranked_archetype_candidates(run_seed: int, company_definition: Dictionary, macro_state: Dictionary = {}, company_index: int = 0) -> Array:
	return _ranked_candidates(run_seed, company_definition, macro_state, company_index)


func disclosure_section_definitions() -> Dictionary:
	return DISCLOSURE_SECTION_DEFINITIONS.duplicate(true)


func disclosure_subtlety_bands() -> Array:
	return DISCLOSURE_SUBTLETY_BANDS.duplicate()


func disclosure_artifacts_for_dossier(dossier: Dictionary) -> Dictionary:
	var story_id: String = str(dossier.get("story_id", "")).strip_edges()
	if story_id.is_empty():
		return {
			"disclosure_placements": [],
			"disclosure_packets": []
		}
	var archetype_id: String = str(dossier.get("archetype_id", "turnaround")).strip_edges()
	if archetype_id.is_empty():
		archetype_id = "turnaround"
	var placements: Array = _rows_with_id(dossier.get("disclosure_placements", []), "placement_id")
	if placements.is_empty():
		placements = _build_disclosure_placements(
			story_id,
			archetype_id,
			_variant_array(dossier.get("cause_facts", [])),
			_variant_array(dossier.get("financial_effects", [])),
			_variant_array(dossier.get("statement_clues", [])),
			str(dossier.get("truth_state", "uncertain")),
			str(dossier.get("public_status", "silent")),
			str(dossier.get("stage_id", "seeded"))
		)
	var packets: Array = _rows_with_id(dossier.get("disclosure_packets", []), "packet_id")
	if packets.is_empty() and not placements.is_empty():
		packets = _build_disclosure_packets(story_id, archetype_id, placements)
	return {
		"disclosure_placements": placements,
		"disclosure_packets": packets
	}


func disclosure_placements_for_dossiers(dossiers: Array, section_id: String = "", options: Dictionary = {}) -> Array:
	return disclosure_rows_for_dossiers(dossiers, "placements", section_id, options)


func disclosure_packets_for_dossiers(dossiers: Array, section_id: String = "", options: Dictionary = {}) -> Array:
	return disclosure_rows_for_dossiers(dossiers, "packets", section_id, options)


func disclosure_rows_for_dossiers(dossiers: Array, row_kind: String = "packets", section_id: String = "", options: Dictionary = {}) -> Array:
	var normalized_kind: String = row_kind.strip_edges().to_lower()
	var artifact_key: String = "disclosure_placements" if normalized_kind in ["placement", "placements"] else "disclosure_packets"
	var normalized_section_id: String = section_id.strip_edges()
	var rows: Array = []
	for dossier_value in dossiers:
		if typeof(dossier_value) != TYPE_DICTIONARY:
			continue
		var dossier: Dictionary = dossier_value
		var artifacts: Dictionary = disclosure_artifacts_for_dossier(dossier)
		var source_rows: Array = _variant_array(artifacts.get(artifact_key, []))
		for row_value in source_rows:
			if typeof(row_value) != TYPE_DICTIONARY:
				continue
			var source_row: Dictionary = row_value
			if not normalized_section_id.is_empty() and str(source_row.get("section_id", "")).strip_edges() != normalized_section_id:
				continue
			var row: Dictionary = source_row.duplicate(true)
			row["company_id"] = str(dossier.get("company_id", "")).strip_edges()
			row["ticker"] = str(dossier.get("ticker", "")).strip_edges()
			row["archetype_id"] = str(dossier.get("archetype_id", "")).strip_edges()
			rows.append(row)
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_story_id: String = str(left.get("story_id", ""))
		var right_story_id: String = str(right.get("story_id", ""))
		if left_story_id != right_story_id:
			return left_story_id < right_story_id
		var left_section_id: String = str(left.get("section_id", ""))
		var right_section_id: String = str(right.get("section_id", ""))
		if left_section_id != right_section_id:
			return left_section_id < right_section_id
		var left_priority: int = int(left.get("render_priority", 999 - int(left.get("scattering_index", 0))))
		var right_priority: int = int(right.get("render_priority", 999 - int(right.get("scattering_index", 0))))
		if left_priority != right_priority:
			return left_priority > right_priority
		return str(left.get("packet_id", left.get("placement_id", ""))) < str(right.get("packet_id", right.get("placement_id", "")))
	)
	var limit: int = int(options.get("limit", rows.size()))
	if limit > 0 and rows.size() > limit:
		rows = rows.slice(0, limit)
	return rows


func build_preview_rows(dossiers: Array, surface_id: String = "summary", options: Dictionary = {}) -> Array:
	var normalized_surface_id: String = _normalize_preview_surface_id(surface_id)
	var limit: int = int(options.get("limit", dossiers.size()))
	var rows: Array = []
	for dossier_value in dossiers:
		if typeof(dossier_value) != TYPE_DICTIONARY:
			continue
		var preview: Dictionary = build_preview(dossier_value, normalized_surface_id)
		if preview.is_empty():
			continue
		rows.append(preview)
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_story_id: String = str(left.get("story_id", ""))
		var right_story_id: String = str(right.get("story_id", ""))
		if left_story_id == right_story_id:
			return str(left.get("preview_id", "")) < str(right.get("preview_id", ""))
		return left_story_id < right_story_id
	)
	if limit > 0 and rows.size() > limit:
		rows = rows.slice(0, limit)
	return rows


func build_preview(dossier: Dictionary, surface_id: String = "summary") -> Dictionary:
	var story_id: String = str(dossier.get("story_id", "")).strip_edges()
	var company_id: String = str(dossier.get("company_id", "")).strip_edges()
	var ticker: String = str(dossier.get("ticker", "")).strip_edges()
	if story_id.is_empty() or company_id.is_empty() or ticker.is_empty():
		return {}

	var normalized_surface_id: String = _normalize_preview_surface_id(surface_id)
	var clue: Dictionary = _preview_clue_for_surface(dossier, normalized_surface_id)
	var fact_ids: Array = _preview_fact_ids(dossier, clue)
	var effect_ids: Array = _effect_ids(dossier.get("financial_effects", []))
	var metric_ids: Array = _preview_metric_ids(dossier, clue)
	var clue_ids: Array = _preview_clue_ids(clue)
	var traceability: Dictionary = dossier.get("traceability", {}) if typeof(dossier.get("traceability", {})) == TYPE_DICTIONARY else {}
	var public_status: String = str(dossier.get("public_status", "silent"))
	var stage_id: String = str(dossier.get("stage_id", "seeded"))
	var archetype_id: String = str(dossier.get("archetype_id", ""))
	var headline: String = _preview_headline(ticker, archetype_id, normalized_surface_id, public_status)
	var deck: String = _preview_deck(dossier, fact_ids, metric_ids)
	var body: String = _preview_body(dossier, normalized_surface_id, fact_ids, metric_ids, clue)

	return {
		"schema_version": SCHEMA_VERSION,
		"source_system_id": SOURCE_SYSTEM_ID,
		"preview_id": "preview|%s|%s" % [story_id, normalized_surface_id],
		"surface_id": normalized_surface_id,
		"story_id": story_id,
		"company_id": company_id,
		"ticker": ticker,
		"archetype_id": archetype_id,
		"story_family": str(dossier.get("story_family", "")),
		"public_status": public_status,
		"stage_id": stage_id,
		"headline": headline,
		"deck": deck,
		"body": body,
		"fact_ids": fact_ids,
		"clue_ids": clue_ids,
		"effect_ids": effect_ids,
		"metric_ids": metric_ids,
		"labels": {
			"surface": _preview_surface_label(normalized_surface_id),
			"archetype": _preview_archetype_label(archetype_id),
			"status": _preview_status_label(public_status),
			"stage": _preview_stage_label(stage_id)
		},
		"traceability": {
			"source_fact_ids": _unique_string_array(traceability.get("source_fact_ids", fact_ids)),
			"evidence_ids": _unique_string_array(traceability.get("evidence_ids", clue_ids)),
			"generated_surface_ids": _unique_string_array(traceability.get("generated_surface_ids", [normalized_surface_id])),
			"price_effect_ids": _unique_string_array(traceability.get("price_effect_ids", [])),
			"statement_effect_ids": _unique_string_array(traceability.get("statement_effect_ids", effect_ids))
		}
	}


func _ranked_candidates(run_seed: int, company_definition: Dictionary, macro_state: Dictionary, company_index: int) -> Array:
	var rows: Array = []
	for archetype_id_value in ARCHETYPE_DEFINITIONS.keys():
		var archetype_id: String = str(archetype_id_value)
		var row: Dictionary = _score_candidate(run_seed, company_definition, macro_state, company_index, archetype_id)
		rows.append(row)
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if is_equal_approx(float(left.get("score", 0.0)), float(right.get("score", 0.0))):
			return str(left.get("archetype_id", "")) < str(right.get("archetype_id", ""))
		return float(left.get("score", 0.0)) > float(right.get("score", 0.0))
	)
	return rows


func _score_candidate(run_seed: int, company_definition: Dictionary, macro_state: Dictionary, company_index: int, archetype_id: String) -> Dictionary:
	var archetype: Dictionary = _archetype(archetype_id)
	var company_id: String = str(company_definition.get("id", "company_%d" % company_index))
	var score: float = float(archetype.get("base_priority", 0.4))
	var sector_id: String = str(company_definition.get("sector_id", ""))
	var matching_inputs: Array = []

	var sector_ids: Array = archetype.get("sector_ids", [])
	if sector_ids.is_empty() or sector_ids.has(sector_id):
		score += 0.65
		matching_inputs.append("sector:%s" % sector_id)

	var hook_match: Dictionary = _best_hook_match(company_definition.get("story_hooks", []), archetype_id, archetype.get("hook_keywords", []))
	score += float(hook_match.get("score", 0.0))
	var hook_id: String = str(hook_match.get("hook_id", ""))
	if not hook_id.is_empty():
		matching_inputs.append("hook:%s" % hook_id)
	else:
		hook_id = _fallback_hook_for_archetype(archetype_id)

	var tag_score: float = _keyword_array_score(company_definition.get("moat_tags", []), archetype.get("moat_keywords", []), 0.22)
	tag_score += _keyword_array_score(company_definition.get("narrative_tags", []), archetype.get("hook_keywords", []), 0.14)
	score += tag_score
	if tag_score > 0.0:
		matching_inputs.append("tags")

	var commodity_fit: Dictionary = _commodity_fit(company_definition, macro_state, archetype_id)
	score += float(commodity_fit.get("score", 0.0))
	if not str(commodity_fit.get("commodity_id", "")).is_empty():
		matching_inputs.append("commodity:%s" % str(commodity_fit.get("commodity_id", "")))

	var sector_bias: float = _sector_bias(macro_state, sector_id)
	if archetype_id in ["capex_expansion", "contract_win", "margin_recovery", "turnaround"] and sector_bias > 0.0:
		score += clamp(sector_bias * 45.0, 0.0, 0.45)
		matching_inputs.append("sector_tailwind")
	elif archetype_id in ["commodity_headwind", "balance_sheet_stress", "governance_risk"] and sector_bias < 0.0:
		score += clamp(absf(sector_bias) * 45.0, 0.0, 0.45)
		matching_inputs.append("sector_headwind")

	var roadmap_profile: Dictionary = company_definition.get("roadmap_profile", {})
	if (not roadmap_profile.is_empty()) and archetype_id in ["capex_expansion", "corporate_action_use_of_proceeds"]:
		score += 0.26
		matching_inputs.append("roadmap:%s" % str(roadmap_profile.get("primary_family_id", "")))

	var price_traits: Dictionary = company_definition.get("price_traits", {})
	score += clamp(float(price_traits.get("event_sensitivity", 0.0)) * 0.34, 0.0, 0.18)
	score += float(STABLE_RNG.seed_from_parts([run_seed, SOURCE_SYSTEM_ID, "candidate_noise", company_id, archetype_id]) % 1000) / 1000.0 * 0.18

	return {
		"archetype_id": archetype_id,
		"hook_id": hook_id,
		"score": snappedf(clamp(score, 0.0, 6.0), 0.001),
		"matching_inputs": matching_inputs,
		"commodity_id": str(commodity_fit.get("commodity_id", "")),
		"commodity_contribution": snappedf(float(commodity_fit.get("contribution", 0.0)), 0.001),
		"commodity_direction": str(commodity_fit.get("direction", "mixed"))
	}


func _best_hook_match(story_hooks_value: Variant, archetype_id: String, keywords: Array) -> Dictionary:
	if typeof(story_hooks_value) != TYPE_ARRAY:
		return {"hook_id": "", "score": 0.0}
	var best_hook: String = ""
	var best_score: float = 0.0
	for hook_value in story_hooks_value:
		var hook_id: String = str(hook_value)
		var normalized_hook: String = hook_id.to_lower()
		var score: float = 0.0
		if normalized_hook == archetype_id:
			score += 2.7
		for keyword_value in keywords:
			var keyword: String = str(keyword_value).to_lower()
			if not keyword.is_empty() and normalized_hook.find(keyword) >= 0:
				score += 0.72
		if score > best_score:
			best_score = score
			best_hook = hook_id
	return {"hook_id": best_hook, "score": min(best_score, 2.9)}


func _keyword_array_score(source_value: Variant, keywords: Array, weight: float) -> float:
	if typeof(source_value) != TYPE_ARRAY:
		return 0.0
	var score: float = 0.0
	for item_value in source_value:
		var item: String = str(item_value).to_lower()
		for keyword_value in keywords:
			var keyword: String = str(keyword_value).to_lower()
			if not keyword.is_empty() and item.find(keyword) >= 0:
				score += weight
	return min(score, 0.9)


func _commodity_fit(company_definition: Dictionary, macro_state: Dictionary, archetype_id: String) -> Dictionary:
	var exposures_value: Variant = company_definition.get("commodity_exposures", {})
	var indicators_value: Variant = macro_state.get("commodity_indicators", {})
	if typeof(exposures_value) != TYPE_DICTIONARY or typeof(indicators_value) != TYPE_DICTIONARY:
		return {"score": 0.0, "commodity_id": "", "contribution": 0.0, "direction": "mixed"}
	var exposures: Dictionary = exposures_value
	var indicators: Dictionary = indicators_value
	var best_id: String = ""
	var best_contribution: float = 0.0
	for commodity_id_value in exposures.keys():
		var commodity_id: String = str(commodity_id_value)
		if not indicators.has(commodity_id):
			continue
		var exposure: float = clamp(float(exposures.get(commodity_id_value, 0.0)), -1.0, 1.0)
		var commodity_signal_score: float = _commodity_signal(indicators.get(commodity_id, {}))
		var contribution: float = clamp(exposure * commodity_signal_score, -1.0, 1.0)
		if absf(contribution) > absf(best_contribution):
			best_contribution = contribution
			best_id = commodity_id

	var score: float = 0.0
	if archetype_id == "commodity_tailwind" and best_contribution > 0.0:
		score = clamp(best_contribution * 2.8, 0.0, 1.45)
	elif archetype_id == "commodity_headwind" and best_contribution < 0.0:
		score = clamp(absf(best_contribution) * 2.8, 0.0, 1.45)
	elif archetype_id == "margin_recovery" and best_contribution > 0.0:
		score = clamp(best_contribution * 1.1, 0.0, 0.48)
	elif archetype_id == "balance_sheet_stress" and best_contribution < 0.0:
		score = clamp(absf(best_contribution) * 0.8, 0.0, 0.35)

	return {
		"score": score,
		"commodity_id": best_id,
		"contribution": best_contribution,
		"direction": "positive" if best_contribution >= 0.0 else "negative"
	}


func _commodity_signal(indicator: Dictionary) -> float:
	var ytd_signal: float = clamp(float(indicator.get("ytd_move", 0.0)) / 20.0, -1.0, 1.0)
	var regime_signal: float = 0.0
	match str(indicator.get("regime", "neutral")):
		"bull":
			regime_signal = 1.0
		"firm":
			regime_signal = 0.5
		"soft":
			regime_signal = -0.5
		"bear":
			regime_signal = -1.0
	var driver_score: float = clamp(float(indicator.get("driver_score", 0.0)), -1.0, 1.0)
	return clamp((ytd_signal * 0.52) + (regime_signal * 0.30) + (driver_score * 0.18), -1.0, 1.0)


func _select_truth_state(run_seed: int, company_definition: Dictionary, macro_state: Dictionary, archetype_id: String, story_id: String) -> String:
	var archetype: Dictionary = _archetype(archetype_id)
	var weights: Dictionary = archetype.get("truth_weights", {})
	var adjusted: Dictionary = {}
	var price_traits: Dictionary = company_definition.get("price_traits", {})
	var quality_bias: float = float(price_traits.get("quality_bias", 0.0))
	var risk_bias: float = float(price_traits.get("risk_bias", 0.0))
	for truth_value in TRUTH_STATES:
		var truth: String = str(truth_value)
		var weight: float = float(weights.get(truth, 1.0))
		if truth == "real":
			weight += max(quality_bias, 0.0) * 20.0
		elif truth in ["failed", "fraud_risk"]:
			weight += max(risk_bias, 0.0) * 18.0
		elif truth == "overhyped":
			weight += max(float(price_traits.get("retail_attention_bias", 0.0)), 0.0) * 12.0
		adjusted[truth] = max(weight, 0.0)
	return _weighted_pick([run_seed, story_id, "truth"], adjusted)


func _weighted_pick(seed_parts: Array, weights: Dictionary) -> String:
	var total: float = 0.0
	for key_value in weights.keys():
		total += max(float(weights.get(key_value, 0.0)), 0.0)
	if total <= 0.0:
		return "uncertain"
	var roll: float = STABLE_RNG.unit_float(seed_parts) * total
	var cursor: float = 0.0
	var sorted_keys: Array = weights.keys()
	sorted_keys.sort()
	for key_value in sorted_keys:
		var key: String = str(key_value)
		cursor += max(float(weights.get(key_value, 0.0)), 0.0)
		if roll <= cursor:
			return key
	return str(sorted_keys.back()) if not sorted_keys.is_empty() else "uncertain"


func _internal_confidence(run_seed: int, story_id: String, candidate: Dictionary, truth_state: String) -> float:
	var base: float = 0.46 + clamp(float(candidate.get("score", 0.0)) / 6.0, 0.0, 1.0) * 0.22
	match truth_state:
		"real", "fraud_risk":
			base += 0.08
		"uncertain":
			base -= 0.10
	var noise: float = (STABLE_RNG.unit_float([run_seed, story_id, "confidence"]) - 0.5) * 0.10
	return snappedf(clamp(base + noise, 0.20, 0.92), 0.001)


func _stage_for_seed(run_seed: int, story_id: String, priority: float) -> String:
	var roll: float = STABLE_RNG.unit_float([run_seed, story_id, "stage"]) + (priority * 0.16)
	if roll >= 0.92:
		return "execution_window"
	if roll >= 0.78:
		return "filing_hint"
	if roll >= 0.62:
		return "private_whisper"
	if roll >= 0.32:
		return "public_chatter"
	return "seeded"


func _public_status_for_truth(run_seed: int, story_id: String, truth_state: String, stage_id: String) -> String:
	if stage_id == "seeded":
		return "silent"
	if stage_id == "public_chatter":
		return "rumor"
	if truth_state in ["fraud_risk", "failed"] and stage_id in ["filing_hint", "execution_window"]:
		return "questioned" if STABLE_RNG.unit_float([run_seed, story_id, "questioned"]) > 0.35 else "reported"
	if truth_state == "overhyped" and stage_id in ["filing_hint", "execution_window"]:
		return "reported"
	if truth_state == "real" and stage_id == "execution_window":
		return "confirmed"
	return "reported"


func _build_cause_facts(story_id: String, company_definition: Dictionary, macro_state: Dictionary, candidate: Dictionary, archetype_id: String, truth_state: String) -> Array:
	var facts: Array = []
	var company_id: String = str(company_definition.get("id", ""))
	var hook_id: String = str(candidate.get("hook_id", _fallback_hook_for_archetype(archetype_id)))
	facts.append(_fact(story_id, "company_trait", hook_id, _direction_for_truth(truth_state), float(candidate.get("score", 0.0)) / 6.0, [str(candidate.get("archetype_id", archetype_id))], [company_id], []))

	var sector_id: String = str(company_definition.get("sector_id", ""))
	var sector_bias: float = _sector_bias(macro_state, sector_id)
	if not sector_id.is_empty():
		var sector_direction: String = "positive" if sector_bias >= 0.0 else "negative"
		facts.append(_fact(story_id, "sector", sector_id, sector_direction, clamp(absf(sector_bias) * 30.0, 0.12, 0.78), ["sector_bias"], [company_id], [sector_id]))

	var commodity_id: String = str(candidate.get("commodity_id", ""))
	if not commodity_id.is_empty():
		var commodity_direction: String = str(candidate.get("commodity_direction", "mixed"))
		facts.append(_fact(story_id, "commodity", commodity_id, commodity_direction, clamp(absf(float(candidate.get("commodity_contribution", 0.0))), 0.10, 0.88), ["commodity_exposure"], [company_id], [sector_id]))

	var macro_fact: Dictionary = _strongest_macro_fact(company_definition, macro_state, story_id, company_id, sector_id)
	if not macro_fact.is_empty():
		facts.append(macro_fact)

	var roadmap_profile: Dictionary = company_definition.get("roadmap_profile", {})
	if (not roadmap_profile.is_empty()) and archetype_id in ["capex_expansion", "corporate_action_use_of_proceeds", "turnaround"]:
		var roadmap_id: String = str(roadmap_profile.get("primary_family_id", "roadmap"))
		facts.append(_fact(story_id, "roadmap", roadmap_id, "positive", 0.52, ["company_roadmap"], [company_id], [sector_id]))

	return facts


func _fact(story_id: String, fact_type: String, source_id: String, direction: String, strength: float, tags: Array, related_company_ids: Array, related_sector_ids: Array) -> Dictionary:
	return {
		"fact_id": "fact|%s|%s|%s" % [story_id, fact_type, source_id],
		"fact_type": fact_type,
		"source_id": source_id,
		"direction": direction,
		"strength": snappedf(clamp(strength, 0.0, 1.0), 0.001),
		"confidence": snappedf(clamp(0.35 + (strength * 0.5), 0.25, 0.92), 0.001),
		"related_sector_ids": _unique_string_array(related_sector_ids),
		"related_company_ids": _unique_string_array(related_company_ids),
		"tags": _unique_string_array(tags)
	}


func _strongest_macro_fact(company_definition: Dictionary, macro_state: Dictionary, story_id: String, company_id: String, sector_id: String) -> Dictionary:
	var exposures_value: Variant = company_definition.get("macro_exposures", {})
	if typeof(exposures_value) != TYPE_DICTIONARY:
		return {}
	var exposures: Dictionary = exposures_value
	var best_id: String = ""
	var best_contribution: float = 0.0
	for macro_id_value in exposures.keys():
		var macro_id: String = str(macro_id_value)
		var exposure: float = clamp(float(exposures.get(macro_id_value, 0.0)), -1.0, 1.0)
		var macro_signal_score: float = _macro_signal(macro_id, macro_state)
		var contribution: float = exposure * macro_signal_score
		if absf(contribution) > absf(best_contribution):
			best_contribution = contribution
			best_id = macro_id
	if best_id.is_empty() or absf(best_contribution) < 0.08:
		return {}
	return _fact(story_id, "macro", best_id, "positive" if best_contribution >= 0.0 else "negative", clamp(absf(best_contribution), 0.08, 0.82), ["macro_exposure"], [company_id], [sector_id])


func _macro_signal(macro_id: String, macro_state: Dictionary) -> float:
	var gdp_growth: float = float(macro_state.get("gdp_growth", 5.0))
	var inflation_yoy: float = float(macro_state.get("inflation_yoy", 3.2))
	var employment_index: float = float(macro_state.get("employment_index", 0.58))
	var policy_rate: float = float(macro_state.get("policy_rate", 5.0))
	var risk_appetite: float = float(macro_state.get("risk_appetite", 0.5))
	match macro_id:
		"domestic_demand", "global_trade", "industrial_activity", "energy_demand":
			return clamp((gdp_growth - 4.8) / 3.0, -1.0, 1.0)
		"consumer_confidence", "employment", "tourism_flow", "urban_mobility":
			return clamp((employment_index - 0.50) * 2.0, -1.0, 1.0)
		"interest_rate":
			return clamp((policy_rate - 5.0) / 3.0, -1.0, 1.0)
		"inflation", "logistics_cost", "fx":
			return clamp((inflation_yoy - 3.2) / 3.2, -1.0, 1.0)
		"market_liquidity", "retail_participation", "digital_adoption":
			return clamp((risk_appetite - 0.5) * 2.0, -1.0, 1.0)
		"credit_cycle", "property_cycle":
			return clamp(((gdp_growth - 4.8) / 3.0 * 0.45) - ((policy_rate - 5.0) / 3.0 * 0.55), -1.0, 1.0)
		_:
			return clamp(_sector_bias(macro_state, str(macro_id)) * 35.0, -1.0, 1.0)


func _build_timeline(story_id: String, started_day: int, expected_resolution_day: int, truth_state: String, cause_facts: Array) -> Array:
	var fact_ids: Array = _fact_ids(cause_facts)
	var midpoint: int = int(round(float(started_day + expected_resolution_day) * 0.5))
	return [
		_timeline_row(story_id, "public_chatter", started_day, started_day + 18, "public", ["news", "twooter"], fact_ids, _tone_for_truth(truth_state), 0.42),
		_timeline_row(story_id, "private_whisper", started_day + 8, midpoint, "private", ["network"], fact_ids, _tone_for_truth(truth_state), 0.68),
		_timeline_row(story_id, "filing_hint", midpoint - 8, expected_resolution_day, "filing", ["statement_note", "thesis"], fact_ids, _tone_for_truth(truth_state), 0.76),
		_timeline_row(story_id, "resolution", expected_resolution_day, expected_resolution_day + 12, "public", ["news", "filing", "thesis"], fact_ids, _tone_for_truth(truth_state), 0.82)
	]


func _timeline_row(story_id: String, stage_id: String, start_day: int, end_day: int, visibility: String, surface_ids: Array, fact_ids: Array, tone: String, reliability: float) -> Dictionary:
	return {
		"stage_id": stage_id,
		"start_day_index": start_day,
		"end_day_index": max(start_day, end_day),
		"visibility": visibility,
		"unlock_surface_ids": _unique_string_array(surface_ids),
		"fact_ids": _unique_string_array(fact_ids),
		"expected_tone": tone,
		"reliability": snappedf(clamp(reliability, 0.0, 1.0), 0.001),
		"timeline_id": "timeline|%s|%s" % [story_id, stage_id]
	}


func _build_financial_effects(story_id: String, archetype_id: String, truth_state: String, confidence: float) -> Array:
	var archetype: Dictionary = _archetype(archetype_id)
	var metric_ids: Array = archetype.get("metric_ids", [])
	var rows: Array = []
	for index in range(min(metric_ids.size(), 3)):
		var metric_id: String = str(metric_ids[index])
		var direction: String = _financial_direction(archetype_id, truth_state, metric_id)
		rows.append({
			"effect_id": "effect|%s|%s" % [story_id, metric_id],
			"metric_id": metric_id,
			"statement_section": _statement_section_for_metric(metric_id),
			"direction": direction,
			"magnitude_band": _magnitude_band(archetype_id, truth_state, index),
			"timing": "next_quarter" if index == 0 else "two_quarters",
			"persistence": _persistence_for_truth(truth_state),
			"confidence": confidence,
			"truth_states": _effect_truth_states(truth_state),
			"note_type": str(archetype.get("note_type", "story_note")),
			"explain_tags": [archetype_id, truth_state]
		})
	return rows


func _build_price_effects(story_id: String, archetype_id: String, truth_state: String, confidence: float, duration_days: int, candidate: Dictionary) -> Dictionary:
	var archetype: Dictionary = _archetype(archetype_id)
	var base_bias: float = float(archetype.get("price_bias", 0.0))
	var truth_modifier: float = _truth_price_modifier(truth_state)
	var matching_score: float = clamp(float(candidate.get("score", 0.0)) / 6.0, 0.0, 1.0)
	var sentiment: float = clamp(base_bias * truth_modifier * (0.62 + matching_score * 0.38), -0.42, 0.42)
	var drift_bps: float = clamp(sentiment * 38.0 * confidence, -18.0, 18.0)
	var activity: float = absf(sentiment) * 0.75 + confidence * 0.25
	return {
		"price_effect_id": "price|%s|primary" % story_id,
		"sentiment_bias": snappedf(sentiment, 0.001),
		"drift_bps": snappedf(drift_bps, 0.001),
		"volatility_multiplier": snappedf(clamp(1.0 + activity * 0.18, 0.96, 1.14), 0.001),
		"volume_multiplier": snappedf(clamp(1.0 + activity * 0.24, 0.96, 1.20), 0.001),
		"confidence": confidence,
		"duration_days": clamp(duration_days, 15, 180),
		"explain_tags": [archetype_id, truth_state],
		"truth_state_modifiers": {
			"real": 1.0,
			"delayed": 0.35,
			"failed": -0.62,
			"overhyped": 0.28,
			"fraud_risk": -0.85,
			"uncertain": 0.10
		}
	}


func _build_public_clues(story_id: String, archetype_id: String, public_status: String, started_day: int, cause_facts: Array, truth_state: String) -> Array:
	var fact_ids: Array = _fact_ids(cause_facts)
	return [
		{
			"clue_id": "clue|%s|news|01" % story_id,
			"fact_ids": fact_ids,
			"surface_id": "news",
			"visibility": "public",
			"earliest_day_index": started_day,
			"latest_day_index": started_day + 21,
			"detail_level": "low",
			"reliability": snappedf(_public_reliability(truth_state), 0.001),
			"tone": _tone_for_truth(truth_state),
			"leak_risk": 0.0,
			"text_key": "%s_public_%s" % [archetype_id, public_status]
		},
		{
			"clue_id": "clue|%s|twooter|01" % story_id,
			"fact_ids": fact_ids,
			"surface_id": "twooter",
			"visibility": "public",
			"earliest_day_index": started_day + 2,
			"latest_day_index": started_day + 28,
			"detail_level": "low",
			"reliability": snappedf(clamp(_public_reliability(truth_state) - 0.12, 0.15, 0.75), 0.001),
			"tone": _tone_for_truth(truth_state),
			"leak_risk": 0.0,
			"text_key": "%s_twooter_%s" % [archetype_id, public_status]
		}
	]


func _build_private_clues(story_id: String, archetype_id: String, started_day: int, cause_facts: Array, truth_state: String, priority: float) -> Array:
	return [
		{
			"clue_id": "clue|%s|network|01" % story_id,
			"fact_ids": _fact_ids(cause_facts),
			"surface_id": "network",
			"visibility": "private",
			"earliest_day_index": started_day + 6,
			"latest_day_index": started_day + 45,
			"required_relationship_stage": "recognized" if priority < 0.68 else "trusted",
			"required_recognition_min": 45 if priority < 0.68 else 70,
			"source_quality": "operator" if truth_state in ["real", "delayed"] else "skeptic",
			"directness": "specific" if priority >= 0.62 else "contextual",
			"reliability": snappedf(_private_reliability(truth_state), 0.001),
			"leak_risk": snappedf(clamp(0.10 + priority * 0.20, 0.0, 0.45), 0.001),
			"text_key": "%s_network_%s" % [archetype_id, truth_state]
		}
	]


func _build_statement_clues(story_id: String, archetype_id: String, expected_resolution_day: int, financial_effects: Array, truth_state: String) -> Array:
	return [
		{
			"clue_id": "clue|%s|statement|01" % story_id,
			"fact_ids": [],
			"surface_id": "statement_note",
			"visibility": "filing",
			"earliest_day_index": max(0, expected_resolution_day - 20),
			"latest_day_index": expected_resolution_day + 25,
			"period_offset": 1,
			"statement_section": "notes",
			"note_type": str(_archetype(archetype_id).get("note_type", "story_note")),
			"metric_ids": _effect_metric_ids(financial_effects),
			"disclosure_quality": _disclosure_quality(truth_state),
			"reliability": snappedf(_statement_reliability(truth_state), 0.001),
			"text_key": "%s_statement_%s" % [archetype_id, truth_state]
		}
	]


func _build_disclosure_placements(story_id: String, archetype_id: String, cause_facts: Array, financial_effects: Array, statement_clues: Array, truth_state: String, public_status: String, stage_id: String) -> Array:
	var archetype: Dictionary = _archetype(archetype_id)
	var note_type: String = str(archetype.get("note_type", "story_note"))
	var fact_ids: Array = _fact_ids(cause_facts)
	var effect_ids: Array = _effect_ids(financial_effects)
	var clue_ids: Array = _clue_ids_from_rows(statement_clues)
	var metric_ids: Array = _effect_metric_ids(financial_effects)
	var candidate_section_ids: Array = _disclosure_sections_for_story(archetype_id, note_type, metric_ids)
	var clue_reliability: float = _statement_clue_reliability(statement_clues)
	var scattering_plan: Dictionary = _disclosure_scattering_plan(story_id, truth_state, public_status, stage_id, clue_reliability, candidate_section_ids.size())
	var section_ids: Array = _scattered_disclosure_sections(candidate_section_ids, int(scattering_plan.get("section_count", candidate_section_ids.size())))
	var rows: Array = []
	for index in range(section_ids.size()):
		var section_id: String = str(section_ids[index])
		var section_definition: Dictionary = DISCLOSURE_SECTION_DEFINITIONS.get(section_id, {})
		var subtlety: String = _disclosure_subtlety_for_placement(story_id, truth_state, public_status, stage_id, clue_reliability, index, section_ids.size())
		rows.append({
			"placement_id": "placement|%s|%02d|%s" % [story_id, index + 1, section_id],
			"schema_version": DISCLOSURE_PLACEMENT_SCHEMA_VERSION,
			"source_system_id": SOURCE_SYSTEM_ID,
			"story_id": story_id,
			"surface_id": DISCLOSURE_SURFACE_ID,
			"section_id": section_id,
			"section_label": str(section_definition.get("label", section_id)),
			"section_group": str(section_definition.get("group", "notes")),
			"annual_statement_note_type": str(section_definition.get("annual_statement_note_type", section_id)),
			"placement_role": _disclosure_placement_role(index),
			"note_type": note_type,
			"visibility": "filing",
			"subtlety": subtlety,
			"reader_effort": str(DISCLOSURE_READER_EFFORT_BY_SUBTLETY.get(subtlety, "medium")),
			"evidence_density": str(DISCLOSURE_EVIDENCE_DENSITY_BY_SUBTLETY.get(subtlety, "partial")),
			"fragment_role": str(DISCLOSURE_FRAGMENT_ROLES_BY_SUBTLETY.get(subtlety, "context")),
			"scattering_strategy": str(scattering_plan.get("strategy", "evidence_trail")),
			"scattering_index": index,
			"scattering_total": section_ids.size(),
			"fact_ids": fact_ids,
			"effect_ids": _effect_ids_for_disclosure_section(section_id, financial_effects, effect_ids),
			"clue_ids": clue_ids,
			"metric_ids": _metric_ids_for_disclosure_section(section_id, financial_effects, metric_ids),
			"statement_sections": _statement_sections_for_disclosure_section(section_id, financial_effects),
			"source_note_types": [note_type],
			"source_metric_ids": metric_ids,
			"text_key": "%s_disclosure_%s" % [archetype_id, section_id]
		})
	return rows


func _build_disclosure_packets(story_id: String, archetype_id: String, disclosure_placements: Array) -> Array:
	var packets: Array = []
	var section_ids: Array = _placement_section_ids(disclosure_placements)
	for index in range(disclosure_placements.size()):
		if typeof(disclosure_placements[index]) != TYPE_DICTIONARY:
			continue
		var placement: Dictionary = disclosure_placements[index]
		var placement_id: String = str(placement.get("placement_id", ""))
		var section_id: String = str(placement.get("section_id", ""))
		var subtlety: String = str(placement.get("subtlety", "implied"))
		var packet_id: String = "packet|%s|%02d|%s" % [story_id, index + 1, section_id]
		packets.append({
			"packet_id": packet_id,
			"schema_version": DISCLOSURE_PACKET_SCHEMA_VERSION,
			"source_system_id": SOURCE_SYSTEM_ID,
			"story_id": story_id,
			"placement_id": placement_id,
			"surface_id": str(placement.get("surface_id", DISCLOSURE_SURFACE_ID)),
			"section_id": section_id,
			"section_label": str(placement.get("section_label", section_id)),
			"section_group": str(placement.get("section_group", "notes")),
			"annual_statement_note_type": str(placement.get("annual_statement_note_type", section_id)),
			"note_type": str(placement.get("note_type", "")),
			"subtlety": subtlety,
			"reader_effort": str(placement.get("reader_effort", "medium")),
			"evidence_density": str(placement.get("evidence_density", "partial")),
			"fragment_role": str(placement.get("fragment_role", "context")),
			"scattering_strategy": str(placement.get("scattering_strategy", "evidence_trail")),
			"packet_role": _disclosure_packet_role(str(placement.get("placement_role", "")), subtlety),
			"render_priority": _disclosure_packet_render_priority(index, subtlety),
			"fact_ids": _unique_string_array(placement.get("fact_ids", [])),
			"effect_ids": _unique_string_array(placement.get("effect_ids", [])),
			"clue_ids": _unique_string_array(placement.get("clue_ids", [])),
			"metric_ids": _unique_string_array(placement.get("metric_ids", [])),
			"statement_sections": _unique_string_array(placement.get("statement_sections", [])),
			"source_note_types": _unique_string_array(placement.get("source_note_types", [])),
			"source_metric_ids": _unique_string_array(placement.get("source_metric_ids", [])),
			"phrase_ids": _disclosure_packet_phrase_ids(archetype_id, placement),
			"render_tokens": _disclosure_packet_render_tokens(placement),
			"cross_reference_section_ids": _disclosure_packet_cross_reference_sections(section_id, section_ids),
			"text_key": str(placement.get("text_key", "%s_disclosure_%s" % [archetype_id, section_id]))
		})
	return packets


func _build_thesis_hooks(story_id: String, archetype_id: String, company_definition: Dictionary, cause_facts: Array, financial_effects: Array) -> Array:
	return [
		{
			"thesis_hook_id": "thesis|%s|story" % story_id,
			"story_id": story_id,
			"archetype_id": archetype_id,
			"company_id": str(company_definition.get("id", "")),
			"evidence_category": "company_story",
			"vocabulary_tags": _unique_string_array([archetype_id, str(company_definition.get("sector_id", ""))]),
			"fact_ids": _fact_ids(cause_facts),
			"metric_ids": _effect_metric_ids(financial_effects)
		}
	]


func _build_resolution_conditions(story_id: String, archetype_id: String, truth_state: String, expected_resolution_day: int, financial_effects: Array) -> Array:
	var metric_ids: Array = _effect_metric_ids(financial_effects)
	var metric_id: String = str(metric_ids.front()) if not metric_ids.is_empty() else "revenue"
	return [
		{
			"condition_id": "condition|%s|primary" % story_id,
			"condition_type": "metric_threshold",
			"metric_id": metric_id,
			"operator": ">=" if _direction_for_truth(truth_state) == "positive" else "<=",
			"threshold": snappedf(_resolution_threshold(archetype_id, truth_state), 0.001),
			"evaluation_day_index": expected_resolution_day,
			"success_outcome": _success_outcome_for_truth(truth_state),
			"failure_outcome": _failure_outcome_for_truth(truth_state),
			"truth_state_if_success": truth_state if truth_state != "uncertain" else "real",
			"truth_state_if_failure": "failed" if truth_state != "fraud_risk" else "fraud_risk"
		}
	]


func _build_traceability(run_seed: int, story_id: String, company_definition: Dictionary, hook_id: String, cause_facts: Array, public_clues: Array, private_clues: Array, statement_clues: Array, financial_effects: Array, disclosure_placements: Array, disclosure_packets: Array) -> Dictionary:
	var surface_ids: Array = []
	var evidence_ids: Array = []
	for clue_value in public_clues + private_clues + statement_clues:
		var clue: Dictionary = clue_value
		surface_ids.append(str(clue.get("surface_id", "")))
		evidence_ids.append(str(clue.get("clue_id", "")))
	var price_effect_ids: Array = ["price|%s|primary" % story_id]
	var statement_effect_ids: Array = []
	for effect_value in financial_effects:
		var effect: Dictionary = effect_value
		statement_effect_ids.append(str(effect.get("effect_id", "")))
	var disclosure_placement_ids: Array = []
	var disclosure_section_ids: Array = []
	for placement_value in disclosure_placements:
		if typeof(placement_value) != TYPE_DICTIONARY:
			continue
		var placement: Dictionary = placement_value
		disclosure_placement_ids.append(str(placement.get("placement_id", "")))
		disclosure_section_ids.append(str(placement.get("section_id", "")))
	var disclosure_packet_ids: Array = []
	for packet_value in disclosure_packets:
		if typeof(packet_value) != TYPE_DICTIONARY:
			continue
		var packet: Dictionary = packet_value
		disclosure_packet_ids.append(str(packet.get("packet_id", "")))
	return {
		"seed_parts": [run_seed, SOURCE_SYSTEM_ID, str(company_definition.get("id", "")), hook_id],
		"source_company_hook_ids": [hook_id],
		"source_fact_ids": _fact_ids(cause_facts),
		"generated_surface_ids": _unique_string_array(surface_ids),
		"evidence_ids": _unique_string_array(evidence_ids),
		"price_effect_ids": price_effect_ids,
		"statement_effect_ids": statement_effect_ids,
		"disclosure_placement_ids": _unique_string_array(disclosure_placement_ids),
		"disclosure_section_ids": _unique_string_array(disclosure_section_ids),
		"disclosure_packet_ids": _unique_string_array(disclosure_packet_ids)
	}


func _placement_section_ids(disclosure_placements: Array) -> Array:
	var section_ids: Array = []
	for placement_value in disclosure_placements:
		if typeof(placement_value) != TYPE_DICTIONARY:
			continue
		var placement: Dictionary = placement_value
		section_ids.append(str(placement.get("section_id", "")))
	return _unique_string_array(section_ids)


func _disclosure_packet_role(placement_role: String, subtlety: String) -> String:
	if subtlety == "direct":
		return "primary_evidence"
	if subtlety == "conflicting":
		return "challenge_evidence"
	if subtlety == "missing":
		return "absence_evidence"
	if placement_role == "primary":
		return "anchor_evidence"
	if placement_role == "supporting":
		return "supporting_evidence"
	return "cross_reference_evidence"


func _disclosure_packet_render_priority(index: int, subtlety: String) -> int:
	var base_priority: int = 100 - index * 7
	match subtlety:
		"direct":
			base_priority += 15
		"conflicting":
			base_priority += 12
		"missing":
			base_priority += 6
		"buried":
			base_priority -= 8
		_:
			base_priority += 0
	return int(clamp(base_priority, 1, 120))


func _disclosure_packet_phrase_ids(archetype_id: String, placement: Dictionary) -> Array:
	var note_type: String = str(placement.get("note_type", "story_note"))
	var section_id: String = str(placement.get("section_id", "notes"))
	var subtlety: String = str(placement.get("subtlety", "implied"))
	var fragment_role: String = str(placement.get("fragment_role", "context"))
	var phrase_ids: Array = [
		"phrase|story_dossier|%s|%s|%s" % [archetype_id, section_id, subtlety],
		"phrase|story_dossier|%s|%s" % [note_type, fragment_role],
		"phrase|story_dossier|section|%s" % section_id
	]
	var metric_ids: Array = _unique_string_array(placement.get("metric_ids", []))
	if not metric_ids.is_empty():
		phrase_ids.append("phrase|story_dossier|metric|%s" % str(metric_ids.front()))
	return _unique_string_array(phrase_ids)


func _disclosure_packet_render_tokens(placement: Dictionary) -> Array:
	var tokens: Array = [
		"section:%s" % str(placement.get("section_id", "")),
		"note_type:%s" % str(placement.get("note_type", "")),
		"subtlety:%s" % str(placement.get("subtlety", "implied")),
		"density:%s" % str(placement.get("evidence_density", "partial")),
		"fragment:%s" % str(placement.get("fragment_role", "context"))
	]
	for metric_id in _unique_string_array(placement.get("metric_ids", [])):
		tokens.append("metric:%s" % str(metric_id))
	return _unique_string_array(tokens)


func _disclosure_packet_cross_reference_sections(section_id: String, section_ids: Array) -> Array:
	var refs: Array = []
	for ref_section_value in section_ids:
		var ref_section_id: String = str(ref_section_value)
		if ref_section_id.is_empty() or ref_section_id == section_id:
			continue
		refs.append(ref_section_id)
		if refs.size() >= 2:
			break
	return refs


func _disclosure_scattering_plan(story_id: String, truth_state: String, public_status: String, stage_id: String, clue_reliability: float, candidate_count: int) -> Dictionary:
	var max_count: int = max(candidate_count, 1)
	var base_count: int = 2
	match truth_state:
		"real":
			base_count = 3
		"delayed":
			base_count = 3
		"failed":
			base_count = 3
		"overhyped":
			base_count = 2
		"fraud_risk":
			base_count = 4
		_:
			base_count = 2
	if stage_id in ["filing_hint", "execution_window", "resolution", "aftermath"]:
		base_count += 1
	if public_status in ["confirmed", "questioned", "disputed", "resolved"]:
		base_count += 1
	if clue_reliability < 0.70 and truth_state in ["failed", "fraud_risk", "uncertain"]:
		base_count += 1
	var jitter: int = STABLE_RNG.int_between([story_id, "disclosure_scatter_jitter", public_status, stage_id], 0, 1)
	var section_count: int = int(clamp(base_count + jitter, 1, max_count))
	return {
		"section_count": section_count,
		"strategy": _disclosure_scattering_strategy(truth_state, public_status, stage_id, clue_reliability)
	}


func _disclosure_scattering_strategy(truth_state: String, public_status: String, stage_id: String, clue_reliability: float) -> String:
	if truth_state == "real":
		return "confirmation_trail" if _direct_disclosure_allowed(public_status, stage_id, clue_reliability) else "evidence_trail"
	if truth_state == "delayed":
		return "timing_gap_trail"
	if truth_state == "failed":
		return "breakdown_trail"
	if truth_state == "overhyped":
		return "thin_support_trail"
	if truth_state == "fraud_risk":
		return "control_risk_trail"
	return "mixed_evidence_trail"


func _scattered_disclosure_sections(candidate_section_ids: Array, target_count: int) -> Array:
	var section_ids: Array = _valid_disclosure_sections(candidate_section_ids)
	if section_ids.is_empty():
		section_ids = ["segment_information"]
	var safe_count: int = int(clamp(target_count, 1, section_ids.size()))
	if safe_count >= section_ids.size():
		return section_ids
	return section_ids.slice(0, safe_count)


func _disclosure_subtlety_for_placement(story_id: String, truth_state: String, public_status: String, stage_id: String, clue_reliability: float, index: int, total_count: int) -> String:
	var last_index: int = max(total_count - 1, 0)
	match truth_state:
		"real":
			if index == 0 and _direct_disclosure_allowed(public_status, stage_id, clue_reliability):
				return "direct" if STABLE_RNG.unit_float([story_id, "disclosure_directness", index]) >= 0.25 else "implied"
			return "implied" if index <= 1 else "buried"
		"delayed":
			if index == 0:
				return "implied"
			if index == last_index and total_count >= 3:
				return "missing"
			return "buried"
		"failed":
			if index == 0:
				return "conflicting"
			if index == last_index:
				return "missing"
			return "buried"
		"overhyped":
			if index == 0:
				return "implied"
			if index == last_index:
				return "missing" if STABLE_RNG.unit_float([story_id, "disclosure_thin_support", index]) >= 0.35 else "conflicting"
			return "buried"
		"fraud_risk":
			if index == 0 or (index == 1 and total_count >= 4):
				return "conflicting"
			if index == last_index:
				return "missing"
			return "buried"
		_:
			return "implied" if index == 0 else "buried"


func _direct_disclosure_allowed(public_status: String, stage_id: String, clue_reliability: float) -> bool:
	if public_status in ["confirmed", "resolved"]:
		return true
	if stage_id in ["filing_hint", "execution_window", "resolution", "aftermath"]:
		return true
	return clue_reliability >= 0.86


func _statement_clue_reliability(statement_clues: Array) -> float:
	for clue_value in statement_clues:
		if typeof(clue_value) != TYPE_DICTIONARY:
			continue
		var clue: Dictionary = clue_value
		return clamp(float(clue.get("reliability", 0.50)), 0.0, 1.0)
	return 0.50


func _disclosure_sections_for_story(archetype_id: String, note_type: String, metric_ids: Array) -> Array:
	var section_ids: Array = []
	section_ids.append_array(NOTE_TYPE_DISCLOSURE_SECTIONS.get(note_type, []))
	section_ids.append_array(ARCHETYPE_DISCLOSURE_SECTIONS.get(archetype_id, []))
	for metric_id_value in metric_ids:
		section_ids.append_array(_disclosure_sections_for_metric(str(metric_id_value)))
	if section_ids.is_empty():
		section_ids = ["segment_information", "cash_flow_information"]
	return _valid_disclosure_sections(section_ids)


func _disclosure_sections_for_metric(metric_id: String) -> Array:
	return _valid_disclosure_sections(METRIC_DISCLOSURE_SECTIONS.get(metric_id, []))


func _valid_disclosure_sections(section_ids: Array) -> Array:
	var result: Array = []
	for section_id_value in section_ids:
		var section_id: String = str(section_id_value).strip_edges()
		if section_id.is_empty() or result.has(section_id):
			continue
		if not DISCLOSURE_SECTION_DEFINITIONS.has(section_id):
			continue
		result.append(section_id)
	return result


func _disclosure_placement_role(index: int) -> String:
	match index:
		0:
			return "primary"
		1, 2:
			return "supporting"
		_:
			return "corroborating"


func _effect_ids_for_disclosure_section(section_id: String, financial_effects: Array, fallback_effect_ids: Array) -> Array:
	var ids: Array = []
	for effect_value in financial_effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_value
		var metric_id: String = str(effect.get("metric_id", ""))
		if _disclosure_sections_for_metric(metric_id).has(section_id):
			ids.append(str(effect.get("effect_id", "")))
	return _unique_string_array(ids if not ids.is_empty() else fallback_effect_ids)


func _metric_ids_for_disclosure_section(section_id: String, financial_effects: Array, fallback_metric_ids: Array) -> Array:
	var ids: Array = []
	for effect_value in financial_effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_value
		var metric_id: String = str(effect.get("metric_id", ""))
		if _disclosure_sections_for_metric(metric_id).has(section_id):
			ids.append(metric_id)
	return _unique_string_array(ids if not ids.is_empty() else fallback_metric_ids)


func _statement_sections_for_disclosure_section(section_id: String, financial_effects: Array) -> Array:
	var sections: Array = []
	for effect_value in financial_effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_value
		var metric_id: String = str(effect.get("metric_id", ""))
		if _disclosure_sections_for_metric(metric_id).has(section_id):
			sections.append(str(effect.get("statement_section", "")))
	if sections.is_empty():
		for effect_value in financial_effects:
			if typeof(effect_value) != TYPE_DICTIONARY:
				continue
			var fallback_effect: Dictionary = effect_value
			sections.append(str(fallback_effect.get("statement_section", "")))
	return _unique_string_array(sections)


func _archetype(archetype_id: String) -> Dictionary:
	if ARCHETYPE_DEFINITIONS.has(archetype_id):
		return ARCHETYPE_DEFINITIONS.get(archetype_id, {})
	return ARCHETYPE_DEFINITIONS.get("turnaround", {})


func _fallback_hook_for_archetype(archetype_id: String) -> String:
	match archetype_id:
		"capex_expansion":
			return "capacity_expansion"
		"margin_recovery":
			return "margin_recovery"
		"commodity_tailwind":
			return "commodity_tailwind"
		"commodity_headwind":
			return "input_cost_pressure"
		"contract_win":
			return "contract_win"
		"corporate_action_use_of_proceeds":
			return "use_of_proceeds"
		_:
			return archetype_id


func _sector_bias(macro_state: Dictionary, sector_id: String) -> float:
	var sector_biases_value: Variant = macro_state.get("sector_biases", {})
	if typeof(sector_biases_value) != TYPE_DICTIONARY:
		return 0.0
	return clamp(float(sector_biases_value.get(sector_id, 0.0)), -0.03, 0.03)


func _direction_for_truth(truth_state: String) -> String:
	if truth_state in ["real", "delayed"]:
		return "positive"
	if truth_state in ["failed", "fraud_risk"]:
		return "negative"
	return "mixed"


func _tone_for_truth(truth_state: String) -> String:
	match truth_state:
		"real":
			return "positive"
		"delayed", "uncertain":
			return "mixed"
		"overhyped":
			return "hyped"
		_:
			return "negative"


func _financial_direction(archetype_id: String, truth_state: String, metric_id: String) -> String:
	if archetype_id in ["commodity_headwind", "governance_risk", "balance_sheet_stress", "fraud_signal"]:
		if metric_id in ["debt", "working_capital", "inventory", "receivables"]:
			return "up"
		return "down"
	if truth_state in ["failed", "fraud_risk"]:
		if metric_id in ["debt", "inventory", "receivables"]:
			return "up"
		return "down"
	if truth_state == "overhyped":
		return "mixed"
	return "up"


func _statement_section_for_metric(metric_id: String) -> String:
	if metric_id in ["cash", "debt", "working_capital", "inventory", "receivables"]:
		return "balance_sheet"
	if metric_id in ["capex", "production_volume", "backlog", "customer_concentration"]:
		return "notes"
	return "income_statement"


func _magnitude_band(archetype_id: String, truth_state: String, index: int) -> String:
	if archetype_id in ["contract_win", "capex_expansion"] and truth_state == "real" and index == 0:
		return "large"
	if truth_state in ["fraud_risk", "failed"] and index == 0:
		return "large"
	if truth_state == "delayed":
		return "moderate"
	if truth_state == "overhyped":
		return "small"
	return "moderate" if index == 0 else "small"


func _persistence_for_truth(truth_state: String) -> String:
	match truth_state:
		"real":
			return "durable"
		"delayed":
			return "deferred"
		"failed", "fraud_risk":
			return "negative"
		_:
			return "temporary"


func _effect_truth_states(truth_state: String) -> Array:
	if truth_state == "uncertain":
		return ["real", "delayed", "failed", "overhyped"]
	return [truth_state]


func _truth_price_modifier(truth_state: String) -> float:
	match truth_state:
		"real":
			return 1.0
		"delayed":
			return 0.35
		"failed":
			return -0.62
		"overhyped":
			return 0.28
		"fraud_risk":
			return -0.85
		_:
			return 0.10


func _public_reliability(truth_state: String) -> float:
	match truth_state:
		"real":
			return 0.62
		"delayed":
			return 0.48
		"failed", "fraud_risk":
			return 0.36
		"overhyped":
			return 0.32
		_:
			return 0.42


func _private_reliability(truth_state: String) -> float:
	match truth_state:
		"real", "fraud_risk":
			return 0.84
		"delayed", "failed":
			return 0.74
		"overhyped":
			return 0.68
		_:
			return 0.62


func _statement_reliability(truth_state: String) -> float:
	return 0.88 if truth_state != "fraud_risk" else 0.58


func _disclosure_quality(truth_state: String) -> String:
	match truth_state:
		"real":
			return "clear"
		"delayed", "uncertain":
			return "partial"
		"fraud_risk":
			return "contradictory"
		_:
			return "weak"


func _resolution_threshold(archetype_id: String, truth_state: String) -> float:
	if truth_state in ["failed", "fraud_risk"]:
		return -0.08
	if archetype_id in ["contract_win", "capex_expansion"]:
		return 0.16
	if archetype_id in ["margin_recovery", "commodity_tailwind"]:
		return 0.08
	return 0.05


func _success_outcome_for_truth(truth_state: String) -> String:
	match truth_state:
		"real":
			return "confirmed"
		"delayed":
			return "partially_confirmed"
		"fraud_risk":
			return "exposed"
		"failed":
			return "missed"
		"overhyped":
			return "expectations_reset"
		_:
			return "mixed"


func _failure_outcome_for_truth(truth_state: String) -> String:
	match truth_state:
		"real":
			return "delayed"
		"fraud_risk":
			return "exposed"
		"overhyped":
			return "quietly_faded"
		_:
			return "missed"


func _fact_ids(cause_facts: Array) -> Array:
	var ids: Array = []
	for fact_value in cause_facts:
		if typeof(fact_value) != TYPE_DICTIONARY:
			continue
		var fact: Dictionary = fact_value
		ids.append(str(fact.get("fact_id", "")))
	return _unique_string_array(ids)


func _clue_ids_from_rows(clues: Array) -> Array:
	var ids: Array = []
	for clue_value in clues:
		if typeof(clue_value) != TYPE_DICTIONARY:
			continue
		var clue: Dictionary = clue_value
		ids.append(str(clue.get("clue_id", "")))
	return _unique_string_array(ids)


func _effect_metric_ids(financial_effects: Array) -> Array:
	var ids: Array = []
	for effect_value in financial_effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_value
		ids.append(str(effect.get("metric_id", "")))
	return _unique_string_array(ids)


func _effect_ids(financial_effects: Array) -> Array:
	var ids: Array = []
	for effect_value in financial_effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_value
		ids.append(str(effect.get("effect_id", "")))
	return _unique_string_array(ids)


func _normalize_preview_surface_id(surface_id: String) -> String:
	var normalized: String = surface_id.strip_edges().to_lower()
	if normalized in ["news", "twooter", "network", "statement_note", "summary"]:
		return normalized
	if normalized == "statement" or normalized == "filing":
		return "statement_note"
	if normalized == "internal_summary":
		return "summary"
	return "summary"


func _preview_clue_for_surface(dossier: Dictionary, surface_id: String) -> Dictionary:
	var target_surface_id: String = "news" if surface_id == "summary" else surface_id
	for field_name in ["public_clues", "private_clues", "statement_clues"]:
		var clues_value: Variant = dossier.get(field_name, [])
		if typeof(clues_value) != TYPE_ARRAY:
			continue
		for clue_value in clues_value:
			if typeof(clue_value) != TYPE_DICTIONARY:
				continue
			var clue: Dictionary = clue_value
			if str(clue.get("surface_id", "")) == target_surface_id:
				return clue
	return {}


func _preview_fact_ids(dossier: Dictionary, clue: Dictionary) -> Array:
	var clue_fact_ids: Array = _unique_string_array(clue.get("fact_ids", []))
	if not clue_fact_ids.is_empty():
		return clue_fact_ids
	return _fact_ids(dossier.get("cause_facts", []))


func _preview_metric_ids(dossier: Dictionary, clue: Dictionary) -> Array:
	var clue_metric_ids: Array = _unique_string_array(clue.get("metric_ids", []))
	if not clue_metric_ids.is_empty():
		return clue_metric_ids
	return _effect_metric_ids(dossier.get("financial_effects", []))


func _preview_clue_ids(clue: Dictionary) -> Array:
	if clue.is_empty():
		return []
	return _unique_string_array([str(clue.get("clue_id", ""))])


func _preview_headline(ticker: String, archetype_id: String, surface_id: String, public_status: String) -> String:
	var archetype_label: String = _preview_archetype_label(archetype_id)
	var status_label: String = _preview_status_label(public_status)
	match surface_id:
		"news":
			return "%s %s story draws %s coverage" % [ticker, archetype_label, status_label]
		"twooter":
			return "%s chatter circles a %s setup" % [ticker, archetype_label]
		"network":
			return "%s contact note flags %s" % [ticker, archetype_label]
		"statement_note":
			return "%s filing note tracks %s" % [ticker, archetype_label]
		_:
			return "%s %s story preview" % [ticker, archetype_label]


func _preview_deck(dossier: Dictionary, fact_ids: Array, metric_ids: Array) -> String:
	var fact_phrase: String = _preview_fact_phrase(dossier, fact_ids)
	var metric_phrase: String = _preview_metric_phrase(metric_ids)
	return "Watch %s through %s." % [fact_phrase, metric_phrase]


func _preview_body(dossier: Dictionary, surface_id: String, fact_ids: Array, metric_ids: Array, clue: Dictionary) -> String:
	var surface_label: String = _preview_surface_label(surface_id)
	var stage_label: String = _preview_stage_label(str(dossier.get("stage_id", "seeded")))
	var status_label: String = _preview_status_label(str(dossier.get("public_status", "silent")))
	var timing_phrase: String = _preview_timing_phrase(dossier, clue)
	var fact_phrase: String = _preview_fact_phrase(dossier, fact_ids)
	var metric_phrase: String = _preview_metric_phrase(metric_ids)
	return "%s preview for the %s stage. Public status is %s; %s points to %s, with %s as the financial follow-through." % [
		surface_label,
		stage_label,
		status_label,
		timing_phrase,
		fact_phrase,
		metric_phrase
	]


func _preview_timing_phrase(dossier: Dictionary, clue: Dictionary) -> String:
	if clue.is_empty():
		return "the story window"
	var earliest_day: int = int(clue.get("earliest_day_index", dossier.get("started_day_index", 0)))
	var latest_day: int = int(clue.get("latest_day_index", dossier.get("expected_resolution_day_index", earliest_day)))
	if latest_day <= earliest_day:
		return "around day %d" % earliest_day
	return "days %d-%d" % [earliest_day, latest_day]


func _preview_fact_phrase(dossier: Dictionary, fact_ids: Array) -> String:
	var fact_index: Dictionary = {}
	var facts_value: Variant = dossier.get("cause_facts", [])
	if typeof(facts_value) == TYPE_ARRAY:
		for fact_value in facts_value:
			if typeof(fact_value) != TYPE_DICTIONARY:
				continue
			var fact: Dictionary = fact_value
			fact_index[str(fact.get("fact_id", ""))] = fact

	var labels: Array = []
	for fact_id_value in fact_ids:
		var fact_id: String = str(fact_id_value)
		if not fact_index.has(fact_id):
			continue
		var fact_row: Dictionary = fact_index.get(fact_id, {})
		labels.append(_preview_fact_label(fact_row))
		if labels.size() >= 2:
			break
	if labels.is_empty():
		return "tracked dossier facts"
	return " and ".join(labels)


func _preview_fact_label(fact: Dictionary) -> String:
	var fact_type: String = str(fact.get("fact_type", "")).strip_edges()
	var source_id: String = str(fact.get("source_id", "")).strip_edges()
	var direction: String = str(fact.get("direction", "")).strip_edges()
	var direction_label: String = _preview_token_label(direction) if not direction.is_empty() else "Mixed"
	if fact_type.is_empty() and source_id.is_empty():
		return "dossier facts"
	if source_id.is_empty():
		return "%s %s" % [direction_label, _preview_token_label(fact_type)]
	return "%s %s %s" % [direction_label, _preview_token_label(fact_type), _preview_token_label(source_id)]


func _preview_metric_phrase(metric_ids: Array) -> String:
	var labels: Array = []
	for metric_id_value in metric_ids:
		var metric_id: String = str(metric_id_value).strip_edges()
		if metric_id.is_empty():
			continue
		labels.append(_preview_metric_label(metric_id))
		if labels.size() >= 3:
			break
	if labels.is_empty():
		return "tracked metrics"
	return ", ".join(labels)


func _preview_metric_label(metric_id: String) -> String:
	match metric_id:
		"gross_margin":
			return "gross margin"
		"operating_margin":
			return "operating margin"
		"net_income":
			return "net income"
		"production_volume":
			return "production volume"
		"working_capital":
			return "working capital"
		"customer_concentration":
			return "customer concentration"
		_:
			return _preview_token_label(metric_id).to_lower()


func _preview_surface_label(surface_id: String) -> String:
	match surface_id:
		"news":
			return "News"
		"twooter":
			return "Twooter"
		"network":
			return "Network"
		"statement_note":
			return "Statement note"
		_:
			return "Internal summary"


func _preview_archetype_label(archetype_id: String) -> String:
	match archetype_id:
		"capex_expansion":
			return "Capex Expansion"
		"margin_recovery":
			return "Margin Recovery"
		"commodity_tailwind":
			return "Commodity Tailwind"
		"commodity_headwind":
			return "Commodity Headwind"
		"contract_win":
			return "Contract Win"
		"turnaround":
			return "Turnaround"
		"governance_risk":
			return "Governance Risk"
		"balance_sheet_stress":
			return "Balance Sheet Stress"
		"fraud_signal":
			return "Statement Quality Risk"
		"corporate_action_use_of_proceeds":
			return "Use Of Proceeds"
		_:
			return _preview_token_label(archetype_id)


func _preview_status_label(public_status: String) -> String:
	return _preview_token_label(public_status)


func _preview_stage_label(stage_id: String) -> String:
	return _preview_token_label(stage_id)


func _preview_token_label(token: String) -> String:
	var normalized: String = token.strip_edges().replace("-", "_").replace(" ", "_").to_lower()
	if normalized.is_empty():
		return "Unknown"
	if normalized in ["cpo", "fx", "gdp"]:
		return normalized.to_upper()
	var words: PackedStringArray = normalized.split("_", false)
	var labels: Array = []
	for word in words:
		var clean_word: String = str(word).strip_edges()
		if clean_word.is_empty():
			continue
		labels.append(clean_word.substr(0, 1).to_upper() + clean_word.substr(1).to_lower())
	if labels.is_empty():
		return "Unknown"
	return " ".join(labels)


func _rows_with_id(source_value: Variant, id_key: String) -> Array:
	var rows: Array = []
	for row_value in _variant_array(source_value):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get(id_key, "")).strip_edges().is_empty():
			continue
		rows.append(row.duplicate(true))
	return rows


func _variant_array(source_value: Variant) -> Array:
	if typeof(source_value) == TYPE_ARRAY:
		return source_value.duplicate(true)
	return []


func _unique_string_array(source: Array) -> Array:
	var seen: Dictionary = {}
	var result: Array = []
	for value in source:
		var text: String = str(value).strip_edges()
		if text.is_empty() or seen.has(text):
			continue
		seen[text] = true
		result.append(text)
	return result
