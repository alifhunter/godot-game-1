extends RefCounted

const SCHEMA_VERSION := 1
const SOURCE_SYSTEM_ID := "annual_filing_document"
const DOCUMENT_TYPE := "annual_filing"
const DOCUMENT_STATUS := "r1_lazy_contract_ready"
const FILING_VERSION := "annual_filing_reader_r1"
const CACHE_OWNER := "in_memory_runtime"
const GENERATION_TIMING := "lazy_on_request"
const DEFAULT_LANGUAGE_ID := "en"
const DEFAULT_SECTOR_STYLE_ID := "generic_annual_filing"
const PAGE_SIZE_HINT := "A4"
const FILING_ANATOMY_SCHEMA_VERSION := 1
const FILING_ANATOMY_STATUS := "r2_anatomy_schema_ready"
const ACCOUNTING_FOOTPRINT_SCHEMA_VERSION := 1
const ACCOUNTING_FOOTPRINT_STATUS := "task3_accounting_footprints_ready"
const FILING_PROSE_SCHEMA_VERSION := 1
const FILING_PROSE_STATUS := "task4_prose_library_ready"
const VISIBLE_FILING_SCHEMA_VERSION := 1
const VISIBLE_FILING_STATUS := "task5_visible_filing_ready"
const VISIBLE_FILING_GENERATION_STATUS := "task5_visible_filing_generated"
const FILING_PROFILE_SCHEMA_VERSION := 1
const FILING_PROFILE_STATUS := "task2_profile_contract_ready"
const FILING_PROFILE_VERSION := "annual_filing_profile_r1"
const DEFAULT_FILING_PROFILE_ID := "default_general"
const STORY_NOTE_FACT_SCHEMA_VERSION := 1
const STORY_NOTE_FACT_STATUS := "task1_story_note_contract_ready"
const STORY_NOTE_FACT_PACKET_SCHEMA_VERSION := 1
const STORY_NOTE_FACT_PACKET_STATUS := "task2_story_fact_packets_ready"
const STORY_NOTE_FACT_PACKET_DEFAULT_MIN_COUNT := 3
const STORY_NOTE_FACT_PACKET_DEFAULT_MAX_COUNT := 9
const STORY_NOTE_FACT_PACKET_CAPTURE_GROUP := "annual_filing_story_note"
const STORY_NOTE_FACT_PACKET_VISIBILITY_LEVEL := "filing_note"
const STORY_NOTE_PROSE_SCHEMA_VERSION := 1
const STORY_NOTE_PROSE_STATUS := "task3_story_note_renderers_ready"
const STORY_NOTE_PLACEMENT_SCHEMA_VERSION := 1
const STORY_NOTE_PLACEMENT_STATUS := "task4_cross_note_placement_ready"

const STORY_NOTE_PLACEMENT_ROLES := [
	"primary_note",
	"secondary_note",
	"policy_or_risk_echo"
]

const STORY_NOTE_PROSE_ROLES := [
	"agreement_lead",
	"facility_detail",
	"commitment_detail",
	"segment_context",
	"policy_noise",
	"subsequent_event"
]

const STORY_NOTE_PROSE_FORBIDDEN_PHRASES := [
	"related note classifications",
	"note classifications",
	"classifications connect",
	"same basis as the consolidated statements",
	"should be read together",
	"this disclosure should be read together",
	"the note presentation should be read together",
	"supporting schedule includes",
	"describes the recognition and movement",
	"source ids",
	"truth_state",
	"source_quality",
	"disclosure_quality",
	"confidence",
	"evidence card",
	"catatan",
	"laporan",
	"million_idr"
]

const VISIBLE_FILING_ASSEMBLY_PRIORITY := [
	"statement_rows",
	"compact_table",
	"comparative_movement",
	"cross_reference",
	"formal_lead_in",
	"limited_prose"
]

const VISIBLE_FILING_PROFILE_BALANCE_TARGETS := {
	"default_general": {
		"min_table_to_note_prose_ratio": 0.20,
		"max_note_paragraphs_with_tables": 2,
		"max_note_paragraphs_without_tables": 2,
		"max_front_matter_paragraphs": 2,
		"max_primary_statement_paragraphs": 1
	},
	"industrial_trading": {
		"min_table_to_note_prose_ratio": 0.25,
		"max_note_paragraphs_with_tables": 2,
		"max_note_paragraphs_without_tables": 2,
		"max_front_matter_paragraphs": 2,
		"max_primary_statement_paragraphs": 1
	},
	"bank": {
		"min_table_to_note_prose_ratio": 1.0,
		"max_note_paragraphs_with_tables": 1,
		"max_note_paragraphs_without_tables": 2,
		"max_front_matter_paragraphs": 2,
		"max_primary_statement_paragraphs": 1
	}
}

const FILING_PROFILE_DEFINITIONS := {
	"default_general": {
		"profile_id": "default_general",
		"profile_version": FILING_PROFILE_VERSION,
		"profile_label": "Default general annual filing",
		"statement_model": "general_company",
		"selection_priority": 0,
		"expected_section_mode": "generic_existing_anatomy",
		"notes": "Fallback profile for sectors without a dedicated filing anatomy yet."
	},
	"industrial_trading": {
		"profile_id": "industrial_trading",
		"profile_version": FILING_PROFILE_VERSION,
		"profile_label": "Industrial and trading annual filing",
		"statement_model": "industrial_trading_company",
		"selection_priority": 40,
		"expected_section_mode": "task3_future_profile_anatomy",
		"sector_ids": ["basicindustry", "energy", "industrial", "infra", "transport"],
		"subsector_terms": ["logistics", "mining", "manufacturing", "industrial", "equipment", "commodity", "plantation", "shipping", "port", "toll", "utility", "power"],
		"notes": "AKR-style base profile for trading, logistics, industrial, infrastructure, energy, and commodity-exposed operators."
	},
	"bank": {
		"profile_id": "bank",
		"profile_version": FILING_PROFILE_VERSION,
		"profile_label": "Bank annual filing",
		"statement_model": "banking_company",
		"selection_priority": 80,
		"expected_section_mode": "task3_future_profile_anatomy",
		"sector_ids": ["finance"],
		"subsector_terms": ["bank", "banking", "large_bank", "mid_market_bank", "small_bank", "sharia_bank", "regional_bank", "digital_bank", "trade_finance_bank", "micro_lending_bank"],
		"business_terms": ["commercial bank", "bank with", "banking", "deposit franchise", "deposits", "transaction banking", "sharia bank", "digital bank", "trade finance bank", "micro-lending bank"],
		"moat_terms": ["deposit", "payroll", "credit_underwriting", "faith_based_deposits"],
		"notes": "Bank-specific filing profile for loans, deposits, allowances, securities, capital adequacy, liquidity, and credit risk."
	}
}

const STORY_NOTE_FACT_REQUIRED_FIELDS := [
	"fact_id",
	"company_id",
	"story_type",
	"note_container",
	"counterparty_id",
	"counterparty_name",
	"agreement_type",
	"effective_date",
	"term_months",
	"term_text",
	"amount",
	"currency",
	"source_system",
	"source_ids",
	"visibility_level",
	"capture_group"
]

const STORY_NOTE_FACT_CONTAINER_DEFINITIONS := {
	"significant_agreements": {
		"container_id": "significant_agreements",
		"label": "Significant Agreements",
		"purpose": "Dealerships, distribution rights, supply/offtake contracts, project contracts, and operating agreements."
	},
	"commitments_contingencies": {
		"container_id": "commitments_contingencies",
		"label": "Commitments, Agreements, And Contingencies",
		"purpose": "Long-term purchase commitments, guarantees, project obligations, and contract risk."
	},
	"bank_facilities_guarantees": {
		"container_id": "bank_facilities_guarantees",
		"label": "Bank Facilities And Guarantees",
		"purpose": "Credit lines, trade facilities, bank guarantees, hedging facilities, and covenants."
	},
	"segment_operations": {
		"container_id": "segment_operations",
		"label": "Segment Operations",
		"purpose": "Business-line revenue, profit, asset split, geographic exposure, and new segment contribution."
	},
	"government_pricing_subsidies": {
		"container_id": "government_pricing_subsidies",
		"label": "Government Pricing And Subsidies",
		"purpose": "Subsidized pricing, regulated tariffs, reimbursement claims, and public-sector dependence."
	},
	"subsidiaries_leases": {
		"container_id": "subsidiaries_leases",
		"label": "Subsidiaries And Leases",
		"purpose": "Land rights, right-of-use assets, subsidiaries, and operating locations."
	},
	"related_parties": {
		"container_id": "related_parties",
		"label": "Related Party Transactions",
		"purpose": "Parent, subsidiary, customer, supplier, or management-linked relationships."
	},
	"project_construction": {
		"container_id": "project_construction",
		"label": "Project And Construction Notes",
		"purpose": "EPC work, capacity buildout, terminal/storage/project timelines, and completion terms."
	},
	"customers_suppliers": {
		"container_id": "customers_suppliers",
		"label": "Customers And Suppliers",
		"purpose": "Customer concentration, supplier dependence, dealership principal, and major counterparties."
	},
	"subsequent_events": {
		"container_id": "subsequent_events",
		"label": "Subsequent Events",
		"purpose": "Post-year-end contracts, financing, acquisitions, divestments, and approvals."
	},
	"accounting_policies": {
		"container_id": "accounting_policies",
		"label": "Accounting Policies",
		"purpose": "Formal policy texture and sector-specific filing noise."
	}
}

const STORY_NOTE_FACT_PROFILE_CONTAINER_ALLOWLISTS := {
	"default_general": [
		"significant_agreements",
		"commitments_contingencies",
		"bank_facilities_guarantees",
		"segment_operations",
		"government_pricing_subsidies",
		"subsidiaries_leases",
		"related_parties",
		"project_construction",
		"customers_suppliers",
		"subsequent_events",
		"accounting_policies"
	],
	"industrial_trading": [
		"significant_agreements",
		"commitments_contingencies",
		"bank_facilities_guarantees",
		"segment_operations",
		"government_pricing_subsidies",
		"subsidiaries_leases",
		"related_parties",
		"project_construction",
		"customers_suppliers",
		"subsequent_events",
		"accounting_policies"
	],
	"bank": [
		"bank_facilities_guarantees",
		"commitments_contingencies",
		"segment_operations",
		"government_pricing_subsidies",
		"subsidiaries_leases",
		"related_parties",
		"customers_suppliers",
		"subsequent_events",
		"accounting_policies"
	]
}

const STORY_NOTE_FACT_STORY_TYPE_DEFINITIONS := {
	"dealership_agreement": {
		"story_type": "dealership_agreement",
		"label": "Dealership agreement",
		"allowed_note_containers": ["significant_agreements", "customers_suppliers", "commitments_contingencies"],
		"requires_counterparty": true,
		"requires_term": true,
		"requires_amount": false
	},
	"supply_or_offtake_agreement": {
		"story_type": "supply_or_offtake_agreement",
		"label": "Supply or offtake agreement",
		"allowed_note_containers": ["significant_agreements", "customers_suppliers", "commitments_contingencies"],
		"requires_counterparty": true,
		"requires_term": true,
		"requires_amount": false
	},
	"bank_facility": {
		"story_type": "bank_facility",
		"label": "Bank facility",
		"allowed_note_containers": ["bank_facilities_guarantees", "commitments_contingencies"],
		"requires_counterparty": true,
		"requires_term": true,
		"requires_amount": true
	},
	"bank_guarantee": {
		"story_type": "bank_guarantee",
		"label": "Bank guarantee",
		"allowed_note_containers": ["bank_facilities_guarantees", "commitments_contingencies", "significant_agreements"],
		"requires_counterparty": true,
		"requires_term": true,
		"requires_amount": true
	},
	"lease_or_land_right": {
		"story_type": "lease_or_land_right",
		"label": "Lease or land right",
		"allowed_note_containers": ["subsidiaries_leases", "commitments_contingencies"],
		"requires_counterparty": true,
		"requires_term": true,
		"requires_amount": true
	},
	"government_subsidy": {
		"story_type": "government_subsidy",
		"label": "Government subsidy",
		"allowed_note_containers": ["government_pricing_subsidies", "segment_operations"],
		"requires_counterparty": true,
		"requires_term": false,
		"requires_amount": true
	},
	"project_contract": {
		"story_type": "project_contract",
		"label": "Project contract",
		"allowed_note_containers": ["project_construction", "significant_agreements", "commitments_contingencies"],
		"requires_counterparty": true,
		"requires_term": true,
		"requires_amount": true
	},
	"segment_expansion": {
		"story_type": "segment_expansion",
		"label": "Segment expansion",
		"allowed_note_containers": ["segment_operations"],
		"requires_counterparty": false,
		"requires_term": false,
		"requires_amount": false
	},
	"related_party_transaction": {
		"story_type": "related_party_transaction",
		"label": "Related party transaction",
		"allowed_note_containers": ["related_parties", "subsidiaries_leases"],
		"requires_counterparty": true,
		"requires_term": false,
		"requires_amount": true
	},
	"subsidiary_commitment": {
		"story_type": "subsidiary_commitment",
		"label": "Subsidiary commitment",
		"allowed_note_containers": ["subsidiaries_leases", "commitments_contingencies"],
		"requires_counterparty": true,
		"requires_term": true,
		"requires_amount": true
	},
	"subsequent_event": {
		"story_type": "subsequent_event",
		"label": "Subsequent event",
		"allowed_note_containers": ["subsequent_events"],
		"requires_counterparty": false,
		"requires_term": false,
		"requires_amount": false
	}
}

const BANK_FILING_NOTE_SECTION_SCHEMA := [
	{
		"section_id": "note_bank_company_information",
		"filing_title": "Notes - Bank Company Information",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 10,
		"page_end": 12,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["company_information"],
		"read_mode": "note_group",
		"clue_density": "medium",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph",
		"virtual_page_group": "notes_identity",
		"supports_capture": true,
		"purpose": "Bank identity, license, branch network, principal activities, and ownership context."
	},
	{
		"section_id": "note_bank_accounting_policies",
		"filing_title": "Notes - Accounting Policies And Significant Estimates",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 13,
		"page_end": 34,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["basis_of_preparation"],
		"read_mode": "note_group",
		"clue_density": "low",
		"boilerplate_density": "high",
		"evidence_capture_mode": "paragraph",
		"virtual_page_group": "notes_policy",
		"supports_capture": true,
		"purpose": "Bank accounting policy noise, loan impairment estimates, fair value policy, and regulatory presentation basis."
	},
	{
		"section_id": "note_bank_cash_reserves",
		"filing_title": "Notes - Cash And Statutory Reserves",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 35,
		"page_end": 42,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["cash_and_cash_equivalents"],
		"read_mode": "note_group",
		"clue_density": "medium",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_bank_assets",
		"supports_capture": true,
		"purpose": "Cash, Bank Indonesia current accounts, statutory reserves, and immediate liquidity."
	},
	{
		"section_id": "note_bank_placements",
		"filing_title": "Notes - Placements With Bank Indonesia And Other Banks",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 43,
		"page_end": 50,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["cash_and_cash_equivalents", "financial_assets"],
		"read_mode": "note_group",
		"clue_density": "medium",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_bank_assets",
		"supports_capture": true,
		"purpose": "Short-term placements, interbank balances, and liquidity deployment."
	},
	{
		"section_id": "note_bank_securities",
		"filing_title": "Notes - Marketable Securities",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 51,
		"page_end": 60,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["financial_assets"],
		"read_mode": "note_group",
		"clue_density": "medium",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_bank_assets",
		"supports_capture": true,
		"purpose": "Securities classification, government bonds, trading book, and amortized-cost balances."
	},
	{
		"section_id": "note_bank_loans_financing",
		"filing_title": "Notes - Loans And Sharia Financing",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 61,
		"page_end": 78,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["trade_receivables", "loans_financing"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_bank_loans",
		"supports_capture": true,
		"purpose": "Loans by stage, product, economic sector, borrower class, and credit quality."
	},
	{
		"section_id": "note_bank_allowance_impairment",
		"filing_title": "Notes - Allowance For Impairment Losses",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 79,
		"page_end": 86,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["trade_receivables", "allowance_impairment"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_bank_loans",
		"supports_capture": true,
		"purpose": "Expected credit loss allowance, movements by stage, write-offs, and recoveries."
	},
	{
		"section_id": "note_bank_deposits",
		"filing_title": "Notes - Deposits From Customers And Other Banks",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 87,
		"page_end": 98,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["debt_and_borrowings", "customer_deposits"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_bank_funding",
		"supports_capture": true,
		"purpose": "Customer deposits, deposits from other banks, funding mix, related-party deposits, and deposit cost clues."
	},
	{
		"section_id": "note_bank_temporary_syirkah_funds",
		"filing_title": "Notes - Temporary Syirkah Funds",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 99,
		"page_end": 104,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["temporary_syirkah_funds", "debt_and_borrowings"],
		"read_mode": "note_group",
		"clue_density": "medium",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_bank_funding",
		"supports_capture": true,
		"purpose": "Sharia funding balances and profit-sharing deposit texture when the bank profile needs it."
	},
	{
		"section_id": "note_bank_interest_income",
		"filing_title": "Notes - Interest Income And Sharia Income",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 105,
		"page_end": 114,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["revenue", "finance_income", "interest_income"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_bank_performance",
		"supports_capture": true,
		"purpose": "Interest income by source, sharia income, fee income, and cost of funds context."
	},
	{
		"section_id": "note_bank_related_parties",
		"filing_title": "Notes - Related Party Transactions",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 115,
		"page_end": 122,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["related_party_transactions"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_relationships",
		"supports_capture": true,
		"purpose": "Balances and transactions with shareholders, affiliated borrowers, and key management."
	},
	{
		"section_id": "note_bank_capital_adequacy",
		"filing_title": "Notes - Capital Adequacy",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 123,
		"page_end": 130,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["equity_and_dividends", "capital_adequacy"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_bank_capital",
		"supports_capture": true,
		"purpose": "Capital adequacy ratio, risk-weighted assets, Tier 1 capital, and regulatory capital buffer."
	},
	{
		"section_id": "note_bank_credit_risk",
		"filing_title": "Notes - Credit Risk",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 131,
		"page_end": 142,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["financial_risk_management", "trade_receivables", "credit_risk"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "high",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_bank_risk",
		"supports_capture": true,
		"purpose": "Credit risk framework, credit quality, collectibility, concentrations, and non-performing exposure."
	},
	{
		"section_id": "note_bank_liquidity_risk",
		"filing_title": "Notes - Liquidity Risk",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 143,
		"page_end": 150,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["financial_risk_management", "debt_and_borrowings", "liquidity_risk"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "high",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_bank_risk",
		"supports_capture": true,
		"purpose": "Maturity profile, funding concentration, deposit tenor, and liquidity reserve coverage."
	},
	{
		"section_id": "note_bank_regulatory_compliance",
		"filing_title": "Notes - Regulatory Reserves And Compliance",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 151,
		"page_end": 158,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["commitments_contingencies_and_subsequent_events", "regulatory_compliance"],
		"read_mode": "note_group",
		"clue_density": "medium",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_bank_regulatory",
		"supports_capture": true,
		"purpose": "Minimum reserve compliance, legal lending limit, regulator correspondence, and post-reporting-date compliance context."
	}
]

const FILING_PROSE_TEMPLATE_DEFINITIONS := {
	"company_information": {
		"section_ids": ["note_company_information"],
		"default_role": "routine_boilerplate",
		"clue_density": "low"
	},
	"accounting_policies": {
		"section_ids": ["note_accounting_policies"],
		"default_role": "accounting_policy",
		"clue_density": "none"
	},
	"estimates_and_judgments": {
		"section_ids": ["note_accounting_policies"],
		"default_role": "estimate_context",
		"clue_density": "low"
	},
	"receivables": {
		"section_ids": ["note_financial_assets_receivables"],
		"default_role": "account_note_context",
		"clue_density": "medium"
	},
	"bank_cash_reserves": {
		"section_ids": ["note_bank_cash_reserves", "note_bank_placements", "note_bank_securities"],
		"default_role": "bank_asset_context",
		"clue_density": "medium"
	},
	"bank_loans": {
		"section_ids": ["note_bank_loans_financing", "note_bank_allowance_impairment"],
		"default_role": "bank_credit_context",
		"clue_density": "medium"
	},
	"bank_funding": {
		"section_ids": ["note_bank_deposits", "note_bank_temporary_syirkah_funds"],
		"default_role": "bank_funding_context",
		"clue_density": "medium"
	},
	"bank_capital": {
		"section_ids": ["note_bank_capital_adequacy"],
		"default_role": "bank_capital_context",
		"clue_density": "medium"
	},
	"bank_credit_risk": {
		"section_ids": ["note_bank_credit_risk"],
		"default_role": "bank_credit_risk_context",
		"clue_density": "medium"
	},
	"bank_liquidity_risk": {
		"section_ids": ["note_bank_liquidity_risk"],
		"default_role": "bank_liquidity_risk_context",
		"clue_density": "medium"
	},
	"bank_regulatory": {
		"section_ids": ["note_bank_regulatory_compliance"],
		"default_role": "bank_regulatory_context",
		"clue_density": "medium"
	},
	"inventories": {
		"section_ids": ["note_inventories"],
		"default_role": "account_note_context",
		"clue_density": "medium"
	},
	"ppe_capex": {
		"section_ids": ["note_ppe_investments"],
		"default_role": "account_note_context",
		"clue_density": "medium"
	},
	"borrowings": {
		"section_ids": ["note_liabilities_borrowings"],
		"default_role": "account_note_context",
		"clue_density": "medium"
	},
	"revenue": {
		"section_ids": ["note_revenue_expenses_tax_equity"],
		"default_role": "account_note_context",
		"clue_density": "medium"
	},
	"segment": {
		"section_ids": ["note_segment_information"],
		"default_role": "segment_context",
		"clue_density": "medium"
	},
	"related_party": {
		"section_ids": ["note_related_parties"],
		"default_role": "related_party_context",
		"clue_density": "medium"
	},
	"commitments": {
		"section_ids": ["note_commitments_contingencies"],
		"default_role": "commitment_context",
		"clue_density": "medium"
	},
	"risk_management": {
		"section_ids": ["note_financial_risk_management"],
		"default_role": "risk_context",
		"clue_density": "medium"
	},
	"subsequent_events": {
		"section_ids": ["note_non_cash_subsequent_events"],
		"default_role": "subsequent_event_context",
		"clue_density": "medium"
	}
}

const SECTOR_STYLE_VOCABULARY := {
	"generic_annual_filing": {
		"entity_label": "the Group",
		"business_lines": "its operating activities",
		"asset_base": "operating assets",
		"inventory_label": "inventories",
		"customer_label": "customers",
		"risk_focus": "credit, liquidity, market, commodity, currency, and interest rate risks",
		"segment_basis": "business lines and operating activities"
	},
	"bank_annual_filing": {
		"entity_label": "the Bank",
		"business_lines": "commercial banking, lending, deposit services, treasury activities, and fee-based banking services",
		"asset_base": "branch assets, digital banking infrastructure, and banking operating assets",
		"inventory_label": "financial assets",
		"customer_label": "borrowers, depositors, and other banking counterparties",
		"risk_focus": "credit, market, liquidity, operational, capital, and regulatory risks",
		"segment_basis": "banking products, borrower segments, treasury activities, and funding sources"
	},
	"trading_logistics_industrial_estate": {
		"entity_label": "the Group",
		"business_lines": "trading and distribution, logistics services, and industrial estate operations",
		"asset_base": "terminals, warehouses, land, infrastructure, and operating equipment",
		"inventory_label": "fuel, merchandise, and project-related inventories",
		"customer_label": "industrial, distribution, and logistics customers",
		"risk_focus": "commodity price, credit, liquidity, currency, interest rate, and supply-chain risks",
		"segment_basis": "trading, logistics, and estate operations"
	}
}

const ACCOUNTING_FOOTPRINT_TYPES := {
	"numeric_movement": {
		"visible_label": "Statement amount movement",
		"evidence_capture_mode": "line_item",
		"default_filing_section_id": "financial_position"
	},
	"statement_row_note_reference": {
		"visible_label": "Statement row note reference",
		"evidence_capture_mode": "line_item_note_ref",
		"default_filing_section_id": "financial_position"
	},
	"note_paragraph": {
		"visible_label": "Note paragraph",
		"evidence_capture_mode": "paragraph",
		"default_filing_section_id": "note_revenue_expenses_tax_equity"
	},
	"compact_table_row": {
		"visible_label": "Note table row",
		"evidence_capture_mode": "table_row",
		"default_filing_section_id": "note_financial_assets_receivables"
	},
	"cross_note_reference": {
		"visible_label": "Cross-note reference",
		"evidence_capture_mode": "cross_reference",
		"default_filing_section_id": "note_revenue_expenses_tax_equity"
	},
	"auditor_risk_focus": {
		"visible_label": "Auditor focus area",
		"evidence_capture_mode": "paragraph",
		"default_filing_section_id": "independent_auditor_report"
	},
	"segment_movement": {
		"visible_label": "Segment movement",
		"evidence_capture_mode": "paragraph_table",
		"default_filing_section_id": "note_segment_information"
	},
	"risk_management_language": {
		"visible_label": "Risk management language",
		"evidence_capture_mode": "paragraph",
		"default_filing_section_id": "note_financial_risk_management"
	},
	"subsequent_event_language": {
		"visible_label": "Subsequent event language",
		"evidence_capture_mode": "paragraph",
		"default_filing_section_id": "note_non_cash_subsequent_events"
	}
}

const ARCHETYPE_FOOTPRINT_PATTERNS := {
	"commodity_tailwind": {
		"pattern_id": "commodity_tailwind",
		"footprint_types": ["numeric_movement", "statement_row_note_reference", "note_paragraph", "compact_table_row", "cross_note_reference", "segment_movement", "risk_management_language"],
		"default_note_types": ["revenue", "segment_information", "inventories"]
	},
	"commodity_headwind": {
		"pattern_id": "commodity_headwind",
		"footprint_types": ["numeric_movement", "statement_row_note_reference", "note_paragraph", "compact_table_row", "cross_note_reference", "segment_movement", "risk_management_language"],
		"default_note_types": ["inventories", "cash_flow_information", "segment_information"]
	},
	"capex_expansion": {
		"pattern_id": "capex_expansion",
		"footprint_types": ["numeric_movement", "statement_row_note_reference", "note_paragraph", "compact_table_row", "cross_note_reference", "auditor_risk_focus", "risk_management_language", "subsequent_event_language"],
		"default_note_types": ["property_plant_and_equipment", "cash_flow_information", "commitments_contingencies_and_subsequent_events"]
	},
	"contract_win": {
		"pattern_id": "contract_win",
		"footprint_types": ["numeric_movement", "statement_row_note_reference", "note_paragraph", "compact_table_row", "cross_note_reference", "segment_movement", "subsequent_event_language"],
		"default_note_types": ["revenue", "segment_information", "trade_receivables", "commitments_contingencies_and_subsequent_events"]
	},
	"margin_recovery": {
		"pattern_id": "margin_recovery",
		"footprint_types": ["numeric_movement", "statement_row_note_reference", "note_paragraph", "compact_table_row", "cross_note_reference", "segment_movement", "risk_management_language"],
		"default_note_types": ["revenue", "cost_of_revenue_and_gross_profit", "inventories", "segment_information"]
	},
	"balance_sheet_stress": {
		"pattern_id": "balance_sheet_stress",
		"footprint_types": ["numeric_movement", "statement_row_note_reference", "note_paragraph", "compact_table_row", "cross_note_reference", "auditor_risk_focus", "risk_management_language", "subsequent_event_language"],
		"default_note_types": ["debt_and_borrowings", "cash_flow_information", "commitments_contingencies_and_subsequent_events"]
	},
	"governance_risk": {
		"pattern_id": "governance_risk",
		"footprint_types": ["statement_row_note_reference", "note_paragraph", "compact_table_row", "cross_note_reference", "auditor_risk_focus", "risk_management_language", "subsequent_event_language"],
		"default_note_types": ["related_party_transactions", "trade_receivables", "commitments_contingencies_and_subsequent_events"]
	},
	"fraud_signal": {
		"pattern_id": "fraud_signal",
		"footprint_types": ["numeric_movement", "statement_row_note_reference", "note_paragraph", "compact_table_row", "cross_note_reference", "auditor_risk_focus", "risk_management_language"],
		"default_note_types": ["trade_receivables", "inventories", "related_party_transactions"]
	},
	"turnaround": {
		"pattern_id": "turnaround",
		"footprint_types": ["numeric_movement", "statement_row_note_reference", "note_paragraph", "compact_table_row", "cross_note_reference", "segment_movement", "risk_management_language"],
		"default_note_types": ["segment_information", "cash_flow_information", "debt_and_borrowings"]
	},
	"corporate_action_use_of_proceeds": {
		"pattern_id": "corporate_action_use_of_proceeds",
		"footprint_types": ["numeric_movement", "statement_row_note_reference", "note_paragraph", "compact_table_row", "cross_note_reference", "auditor_risk_focus", "risk_management_language", "subsequent_event_language"],
		"default_note_types": ["cash_flow_information", "property_plant_and_equipment", "debt_and_borrowings", "equity_and_dividends"]
	},
	"default": {
		"pattern_id": "default",
		"footprint_types": ["numeric_movement", "statement_row_note_reference", "note_paragraph", "cross_note_reference"],
		"default_note_types": []
	}
}

const FILING_SECTION_SCHEMA := [
	{
		"section_id": "cover",
		"filing_title": "Consolidated Financial Statements",
		"localized_title": "",
		"document_part": "front_matter",
		"page_label": "Cover",
		"source_section_id": "",
		"source_array": "",
		"read_mode": "cover",
		"clue_density": "none",
		"boilerplate_density": "low",
		"evidence_capture_mode": "none",
		"virtual_page_group": "front_matter",
		"supports_capture": false,
		"purpose": "Company identity, fiscal year, report type, currency, and unit."
	},
	{
		"section_id": "directors_statement",
		"filing_title": "Statement of Responsibility of the Directors",
		"localized_title": "",
		"document_part": "front_matter",
		"page_label": "Responsibility",
		"source_section_id": "",
		"source_array": "",
		"read_mode": "formal_statement",
		"clue_density": "low",
		"boilerplate_density": "high",
		"evidence_capture_mode": "paragraph",
		"virtual_page_group": "front_matter",
		"supports_capture": true,
		"purpose": "Formal responsibility statement and low-clue document texture."
	},
	{
		"section_id": "independent_auditor_report",
		"filing_title": "Independent Auditor's Report",
		"localized_title": "",
		"document_part": "front_matter",
		"page_label": "Auditor",
		"source_section_id": "",
		"source_array": "",
		"read_mode": "auditor_report",
		"clue_density": "medium",
		"boilerplate_density": "high",
		"evidence_capture_mode": "paragraph",
		"virtual_page_group": "front_matter",
		"supports_capture": true,
		"purpose": "Audit opinion, key audit matter, and risk focus without giving a trade answer."
	},
	{
		"section_id": "table_of_contents",
		"filing_title": "Table of Contents",
		"localized_title": "",
		"document_part": "front_matter",
		"page_label": "Contents",
		"source_section_id": "",
		"source_array": "",
		"read_mode": "table_of_contents",
		"clue_density": "none",
		"boilerplate_density": "low",
		"evidence_capture_mode": "none",
		"virtual_page_group": "front_matter",
		"supports_capture": false,
		"purpose": "A4-style navigation and page labels."
	},
	{
		"section_id": "financial_position",
		"filing_title": "Consolidated Statement of Financial Position",
		"localized_title": "",
		"document_part": "primary_statement",
		"page_start": 1,
		"page_end": 3,
		"source_section_id": "financial_position",
		"source_array": "financial_position",
		"read_mode": "statement_rows",
		"clue_density": "medium",
		"boilerplate_density": "low",
		"evidence_capture_mode": "line_item",
		"virtual_page_group": "primary_statements",
		"supports_capture": true,
		"purpose": "Balance sheet rows with note references."
	},
	{
		"section_id": "profit_or_loss_and_oci",
		"filing_title": "Consolidated Statement of Profit or Loss and Other Comprehensive Income",
		"localized_title": "",
		"document_part": "primary_statement",
		"page_start": 4,
		"page_end": 5,
		"source_section_id": "profit_or_loss_and_oci",
		"source_array": "profit_or_loss_and_oci",
		"read_mode": "statement_rows",
		"clue_density": "medium",
		"boilerplate_density": "low",
		"evidence_capture_mode": "line_item",
		"virtual_page_group": "primary_statements",
		"supports_capture": true,
		"purpose": "Revenue, margin, operating result, finance cost, and tax."
	},
	{
		"section_id": "changes_in_equity",
		"filing_title": "Consolidated Statement of Changes in Equity",
		"localized_title": "",
		"document_part": "primary_statement",
		"page_start": 6,
		"page_end": 7,
		"source_section_id": "changes_in_equity",
		"source_array": "changes_in_equity",
		"read_mode": "statement_rows",
		"clue_density": "low",
		"boilerplate_density": "low",
		"evidence_capture_mode": "line_item",
		"virtual_page_group": "primary_statements",
		"supports_capture": true,
		"purpose": "Dividends, retained earnings, issuance, and buyback effects."
	},
	{
		"section_id": "cash_flows",
		"filing_title": "Consolidated Statement of Cash Flows",
		"localized_title": "",
		"document_part": "primary_statement",
		"page_start": 8,
		"page_end": 9,
		"source_section_id": "cash_flows",
		"source_array": "cash_flows",
		"read_mode": "statement_rows",
		"clue_density": "medium",
		"boilerplate_density": "low",
		"evidence_capture_mode": "line_item",
		"virtual_page_group": "primary_statements",
		"supports_capture": true,
		"purpose": "Operating, investing, financing, capex, debt, and cash bridge."
	},
	{
		"section_id": "note_company_information",
		"filing_title": "Notes - Company Information",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 10,
		"page_end": 12,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["company_information"],
		"read_mode": "note_group",
		"clue_density": "medium",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph",
		"virtual_page_group": "notes_identity",
		"supports_capture": true,
		"purpose": "Business lines, locations, subsidiaries, ownership, and employees."
	},
	{
		"section_id": "note_accounting_policies",
		"filing_title": "Notes - Accounting Policies And Significant Estimates",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 13,
		"page_end": 34,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["basis_of_preparation"],
		"read_mode": "note_group",
		"clue_density": "low",
		"boilerplate_density": "high",
		"evidence_capture_mode": "paragraph",
		"virtual_page_group": "notes_policy",
		"supports_capture": true,
		"purpose": "Formal accounting basis, policy noise, and estimate language."
	},
	{
		"section_id": "note_financial_assets_receivables",
		"filing_title": "Notes - Cash, Financial Assets, And Trade Receivables",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 35,
		"page_end": 48,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["cash_and_cash_equivalents", "trade_receivables"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_assets",
		"supports_capture": true,
		"purpose": "Cash, customer collectability, aging, concentration, and credit-risk clues."
	},
	{
		"section_id": "note_inventories",
		"filing_title": "Notes - Inventories",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 49,
		"page_end": 53,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["inventories"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_assets",
		"supports_capture": true,
		"purpose": "Inventory buildup, write-downs, commodity exposure, and stored-customer-goods clues."
	},
	{
		"section_id": "note_ppe_investments",
		"filing_title": "Notes - Investments And Property, Plant, And Equipment",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 54,
		"page_end": 66,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["property_plant_and_equipment"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_assets",
		"supports_capture": true,
		"purpose": "Capex, expansion assets, associates, and project-footprint clues."
	},
	{
		"section_id": "note_liabilities_borrowings",
		"filing_title": "Notes - Liabilities And Borrowings",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 67,
		"page_end": 78,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["debt_and_borrowings"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_liabilities",
		"supports_capture": true,
		"purpose": "Debt, lease, refinancing, maturity, and covenant clues."
	},
	{
		"section_id": "note_revenue_expenses_tax_equity",
		"filing_title": "Notes - Equity, Revenue, Expenses, And Tax",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 79,
		"page_end": 101,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["equity_and_dividends", "revenue", "cost_of_revenue_and_gross_profit", "operating_expenses"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_performance",
		"supports_capture": true,
		"purpose": "Revenue mix, margin movement, dividends, expenses, and tax effects."
	},
	{
		"section_id": "note_related_parties",
		"filing_title": "Notes - Related Party Transactions",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 102,
		"page_end": 109,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": [],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_relationships",
		"supports_capture": true,
		"purpose": "Subtle transaction patterns, conflicts, management fees, leases, and intra-group dealings."
	},
	{
		"section_id": "note_segment_information",
		"filing_title": "Notes - Segment Information",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 110,
		"page_end": 119,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["segment_information"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "low",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_segments",
		"supports_capture": true,
		"purpose": "Top-down sector/subsector verification through segment revenue, profit, assets, and capex."
	},
	{
		"section_id": "note_commitments_contingencies",
		"filing_title": "Notes - Commitments, Agreements, And Contingencies",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 120,
		"page_end": 130,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["commitments_contingencies_and_subsequent_events"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph",
		"virtual_page_group": "notes_commitments",
		"supports_capture": true,
		"purpose": "Expansion, partnerships, long-term agreements, obligations, claims, and contingent matters."
	},
	{
		"section_id": "note_financial_risk_management",
		"filing_title": "Notes - Financial Risk Management",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 131,
		"page_end": 138,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": [],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "high",
		"evidence_capture_mode": "paragraph_table",
		"virtual_page_group": "notes_risk",
		"supports_capture": true,
		"purpose": "Commodity, credit, FX, interest-rate, liquidity, and capital-risk language."
	},
	{
		"section_id": "note_non_cash_subsequent_events",
		"filing_title": "Notes - Non-Cash Activities And Subsequent Events",
		"localized_title": "",
		"document_part": "notes",
		"page_start": 139,
		"page_end": 140,
		"source_section_id": "notes",
		"source_array": "notes",
		"source_note_types": ["cash_flow_information", "commitments_contingencies_and_subsequent_events"],
		"read_mode": "note_group",
		"clue_density": "high",
		"boilerplate_density": "medium",
		"evidence_capture_mode": "paragraph",
		"virtual_page_group": "notes_subsequent",
		"supports_capture": true,
		"purpose": "Non-cash investing/financing changes and after-reporting-date macro/company events."
	}
]


static func build_request_contract(
	annual_statement: Dictionary,
	run_seed: int,
	company_id: String,
	options: Dictionary = {}
) -> Dictionary:
	if annual_statement.is_empty():
		return {}
	var safe_company_id: String = _safe_company_id(annual_statement, company_id)
	var fiscal_year: int = _fiscal_year(annual_statement, options)
	if safe_company_id.is_empty() or fiscal_year <= 0:
		return {}
	var filing_version: String = str(options.get("filing_version", FILING_VERSION)).strip_edges()
	if filing_version.is_empty():
		filing_version = FILING_VERSION
	var language_id: String = str(options.get("language_id", DEFAULT_LANGUAGE_ID)).strip_edges()
	if language_id.is_empty():
		language_id = DEFAULT_LANGUAGE_ID
	var sector_style_id: String = str(options.get("sector_style_id", annual_statement.get("sector_style_id", DEFAULT_SECTOR_STYLE_ID))).strip_edges()
	if sector_style_id.is_empty():
		sector_style_id = DEFAULT_SECTOR_STYLE_ID
	var filing_profile: Dictionary = select_filing_profile(annual_statement, options)
	var filing_profile_id: String = str(filing_profile.get("profile_id", DEFAULT_FILING_PROFILE_ID)).strip_edges()
	if filing_profile_id.is_empty() or not FILING_PROFILE_DEFINITIONS.has(filing_profile_id):
		filing_profile_id = DEFAULT_FILING_PROFILE_ID
		filing_profile = filing_profile_definition(filing_profile_id)
	var filing_profile_version: String = str(filing_profile.get("profile_version", FILING_PROFILE_VERSION)).strip_edges()
	if filing_profile_version.is_empty():
		filing_profile_version = FILING_PROFILE_VERSION
	var source_state_hash: String = source_state_hash(annual_statement)
	var filing_section_schema: Array = build_filing_section_schema(annual_statement, filing_profile_id)
	var filing_table_of_contents: Array = build_filing_table_of_contents(filing_section_schema)
	var r3_source_section_map: Array = build_r3_source_section_map(filing_section_schema)
	var accounting_footprints: Array = build_accounting_footprint_packets(annual_statement, filing_section_schema)
	var filing_prose_packets: Array = build_filing_prose_packets(annual_statement, filing_section_schema, accounting_footprints, sector_style_id)
	var story_note_company_definition: Dictionary = _story_note_company_definition_from_options(options, annual_statement, safe_company_id)
	var story_note_source_context: Dictionary = _story_note_source_context_from_options(options)
	var story_note_options: Dictionary = options.duplicate(true)
	story_note_options["filing_profile_id"] = filing_profile_id
	story_note_options["fiscal_year"] = fiscal_year
	var story_note_fact_packets: Array = build_story_note_fact_packets(
		story_note_company_definition,
		annual_statement,
		story_note_source_context,
		story_note_options
	)
	var story_note_fact_hash_value: String = story_note_fact_packet_hash(story_note_fact_packets)
	var story_note_placement_plan: Array = build_story_note_placement_plan(
		story_note_fact_packets,
		annual_statement,
		filing_section_schema,
		filing_profile_id,
		story_note_options
	)
	var story_note_placement_hash_value: String = story_note_placement_plan_hash(story_note_placement_plan)
	var story_note_prose_options: Dictionary = options.duplicate(true)
	story_note_prose_options["story_note_placement_plan"] = story_note_placement_plan
	var story_note_prose_packets: Array = build_story_note_prose_packets(
		story_note_fact_packets,
		annual_statement,
		filing_section_schema,
		filing_profile_id,
		story_note_prose_options
	)
	var story_note_prose_hash_value: String = story_note_prose_hash(story_note_prose_packets)
	var schema_hash: String = _stable_hash(_filing_schema_payload(filing_section_schema, filing_table_of_contents, r3_source_section_map))
	var footprint_hash: String = _stable_hash(_accounting_footprint_payload(accounting_footprints))
	var prose_hash: String = _stable_hash(_filing_prose_payload(filing_prose_packets))
	var cache_key: String = build_cache_key(
		run_seed,
		safe_company_id,
		fiscal_year,
		filing_version,
		source_state_hash,
		language_id,
		sector_style_id,
		schema_hash,
		footprint_hash,
		prose_hash,
		filing_profile_id,
		filing_profile_version,
		story_note_prose_hash_value
	)
	return {
		"schema_version": SCHEMA_VERSION,
		"source_system_id": SOURCE_SYSTEM_ID,
		"document_type": DOCUMENT_TYPE,
		"document_status": DOCUMENT_STATUS,
		"generation_timing": GENERATION_TIMING,
		"cache_owner": CACHE_OWNER,
		"cache_key": cache_key,
		"cache_key_parts": {
			"run_seed": run_seed,
			"company_id": safe_company_id,
			"fiscal_year": fiscal_year,
			"filing_version": filing_version,
			"language_id": language_id,
			"sector_style_id": sector_style_id,
			"filing_profile_id": filing_profile_id,
			"filing_profile_version": filing_profile_version,
			"source_state_hash": source_state_hash,
			"filing_schema_hash": schema_hash,
			"accounting_footprint_hash": footprint_hash,
			"filing_prose_hash": prose_hash,
			"story_note_fact_packet_hash": story_note_fact_hash_value,
			"story_note_placement_plan_hash": story_note_placement_hash_value,
			"story_note_prose_hash": story_note_prose_hash_value
		},
		"invalidation_fields": [
			"fiscal_year",
			"filing_version",
			"language_id",
			"sector_style_id",
			"filing_profile_id",
			"filing_profile_version",
			"source_state_hash",
			"filing_schema_hash",
			"accounting_footprint_hash",
			"filing_prose_hash",
			"story_note_fact_packet_hash",
			"story_note_placement_plan_hash",
			"story_note_prose_hash"
		],
		"run_seed": run_seed,
		"company_id": safe_company_id,
		"fiscal_year": fiscal_year,
		"filing_version": filing_version,
		"language_id": language_id,
		"sector_style_id": sector_style_id,
		"filing_profile_schema_version": FILING_PROFILE_SCHEMA_VERSION,
		"filing_profile_status": FILING_PROFILE_STATUS,
		"filing_profile_id": filing_profile_id,
		"filing_profile_version": filing_profile_version,
		"filing_profile_label": str(filing_profile.get("profile_label", "")),
		"filing_profile_selection": filing_profile.duplicate(true),
		"source_state_hash": source_state_hash,
		"filing_schema_hash": schema_hash,
		"accounting_footprint_hash": footprint_hash,
		"filing_prose_hash": prose_hash,
		"filing_anatomy_schema_version": FILING_ANATOMY_SCHEMA_VERSION,
		"filing_anatomy_status": FILING_ANATOMY_STATUS,
		"accounting_footprint_schema_version": ACCOUNTING_FOOTPRINT_SCHEMA_VERSION,
		"accounting_footprint_status": ACCOUNTING_FOOTPRINT_STATUS,
		"filing_prose_schema_version": FILING_PROSE_SCHEMA_VERSION,
		"filing_prose_status": FILING_PROSE_STATUS,
		"story_note_fact_packet_schema_version": STORY_NOTE_FACT_PACKET_SCHEMA_VERSION,
		"story_note_fact_packet_status": STORY_NOTE_FACT_PACKET_STATUS,
		"story_note_fact_packet_hash": story_note_fact_hash_value,
		"story_note_fact_packet_count": story_note_fact_packets.size(),
		"story_note_placement_schema_version": STORY_NOTE_PLACEMENT_SCHEMA_VERSION,
		"story_note_placement_status": STORY_NOTE_PLACEMENT_STATUS,
		"story_note_placement_plan_hash": story_note_placement_hash_value,
		"story_note_placement_plan_count": story_note_placement_plan.size(),
		"story_note_prose_schema_version": STORY_NOTE_PROSE_SCHEMA_VERSION,
		"story_note_prose_status": STORY_NOTE_PROSE_STATUS,
		"story_note_prose_hash": story_note_prose_hash_value,
		"story_note_prose_count": story_note_prose_packets.size(),
		"filing_section_schema": filing_section_schema,
		"filing_table_of_contents": filing_table_of_contents,
		"r3_source_section_map": r3_source_section_map,
		"accounting_footprint_packets": accounting_footprints,
		"accounting_footprint_type_counts": _accounting_footprint_type_counts(accounting_footprints),
		"accounting_footprint_story_counts": _accounting_footprint_story_counts(accounting_footprints),
		"filing_prose_packets": filing_prose_packets,
		"filing_prose_role_counts": _filing_prose_role_counts(filing_prose_packets),
		"filing_prose_section_counts": _filing_prose_section_counts(filing_prose_packets),
		"story_note_fact_packets": story_note_fact_packets,
		"story_note_fact_packet_summary": story_note_fact_packet_summary(story_note_fact_packets, filing_profile_id),
		"story_note_placement_plan": story_note_placement_plan,
		"story_note_placement_plan_summary": story_note_placement_plan_summary(story_note_placement_plan),
		"story_note_placement_validation_errors": validate_story_note_placement_plan(story_note_placement_plan),
		"story_note_prose_packets": story_note_prose_packets,
		"story_note_prose_role_counts": _story_note_prose_role_counts(story_note_prose_packets),
		"story_note_prose_section_counts": _story_note_prose_section_counts(story_note_prose_packets),
		"story_note_prose_validation_errors": validate_story_note_prose_packets(story_note_prose_packets),
		"source_statement_id": str(annual_statement.get("statement_id", "")),
		"page_size_hint": str(annual_statement.get("page_size_hint", PAGE_SIZE_HINT)),
		"saved_cache_allowed": false,
		"saved_cache_policy": "derive_display_from_source_state",
		"full_filing_generation_status": "contract_only_until_task_5"
	}


static func build_cache_key(
	run_seed: int,
	company_id: String,
	fiscal_year: int,
	filing_version: String = FILING_VERSION,
	source_state_hash_value: String = "",
	language_id: String = DEFAULT_LANGUAGE_ID,
	sector_style_id: String = DEFAULT_SECTOR_STYLE_ID,
	filing_schema_hash_value: String = "",
	accounting_footprint_hash_value: String = "",
	filing_prose_hash_value: String = "",
	filing_profile_id: String = DEFAULT_FILING_PROFILE_ID,
	filing_profile_version: String = FILING_PROFILE_VERSION,
	story_note_prose_hash_value: String = ""
) -> String:
	var parts: Array = [
		"annual_filing",
		str(run_seed),
		_cache_token(company_id),
		str(fiscal_year),
		_cache_token(filing_version),
		_cache_token(language_id),
		_cache_token(sector_style_id),
		_cache_token(source_state_hash_value),
		_cache_token(filing_schema_hash_value),
		_cache_token(accounting_footprint_hash_value),
		_cache_token(filing_prose_hash_value),
		_cache_token(filing_profile_id),
		_cache_token(filing_profile_version),
		_cache_token(story_note_prose_hash_value)
	]
	return "|".join(parts)


static func build_document_from_statement(
	annual_statement: Dictionary,
	run_seed: int,
	company_id: String,
	options: Dictionary = {}
) -> Dictionary:
	var contract: Dictionary = build_request_contract(annual_statement, run_seed, company_id, options)
	if contract.is_empty():
		return {}
	var source_copy: Dictionary = annual_statement.duplicate(true)
	var document: Dictionary = contract.duplicate(true)
	document["document_id"] = "annual_filing_document|%s|%d|%s" % [
		str(document.get("company_id", "")),
		int(document.get("fiscal_year", 0)),
		str(document.get("source_state_hash", ""))
	]
	document["title"] = "Consolidated Financial Statements"
	document["report_title"] = "Consolidated Financial Statements"
	document["company_name"] = str(options.get("company_name", annual_statement.get("company_name", document.get("company_id", "")))).strip_edges()
	document["ticker"] = str(options.get("ticker", annual_statement.get("ticker", ""))).strip_edges()
	document["statement_period_label"] = str(annual_statement.get("statement_period_label", "FY%d" % int(document.get("fiscal_year", 0))))
	document["source_annual_statement"] = source_copy
	var visible_document: Dictionary = build_visible_filing_document(source_copy, document, options)
	for key in visible_document.keys():
		document[key] = visible_document.get(key)
	for source_array in ["financial_position", "profit_or_loss_and_oci", "changes_in_equity", "cash_flows"]:
		document[source_array] = _variant_array(source_copy.get(source_array, []))
	document["display_source"] = "visible_filing_document"
	document["visible_sections_materialized"] = true
	document["visible_document_generated"] = true
	document["full_filing_generation_status"] = VISIBLE_FILING_GENERATION_STATUS
	document["cache_hit"] = false
	document["cache_status"] = "miss_built"
	return document


static func get_or_build_document(
	cache: Dictionary,
	annual_statement: Dictionary,
	run_seed: int,
	company_id: String,
	options: Dictionary = {}
) -> Dictionary:
	var contract: Dictionary = build_request_contract(annual_statement, run_seed, company_id, options)
	if contract.is_empty():
		return {}
	var cache_key: String = str(contract.get("cache_key", ""))
	if cache.has(cache_key) and typeof(cache.get(cache_key)) == TYPE_DICTIONARY:
		var cached: Dictionary = cache.get(cache_key).duplicate(true)
		cached["cache_hit"] = true
		cached["cache_status"] = "hit"
		return cached
	var document: Dictionary = build_document_from_statement(annual_statement, run_seed, company_id, options)
	if document.is_empty():
		return {}
	cache[cache_key] = document.duplicate(true)
	return document


static func source_state_hash(annual_statement: Dictionary) -> String:
	return _stable_hash(_source_state_payload(annual_statement))


static func document_hash(document: Dictionary) -> String:
	return _stable_hash(_document_contract_payload(document))


static func filing_schema_hash(annual_statement: Dictionary = {}, filing_profile_id: String = DEFAULT_FILING_PROFILE_ID) -> String:
	var filing_section_schema: Array = build_filing_section_schema(annual_statement, filing_profile_id)
	var filing_table_of_contents: Array = build_filing_table_of_contents(filing_section_schema)
	var r3_source_section_map: Array = build_r3_source_section_map(filing_section_schema)
	return _stable_hash(_filing_schema_payload(filing_section_schema, filing_table_of_contents, r3_source_section_map))


static func accounting_footprint_hash(annual_statement: Dictionary, filing_section_schema: Array = []) -> String:
	return _stable_hash(_accounting_footprint_payload(build_accounting_footprint_packets(annual_statement, filing_section_schema)))


static func accounting_footprint_type_definitions() -> Dictionary:
	return ACCOUNTING_FOOTPRINT_TYPES.duplicate(true)


static func filing_prose_template_definitions() -> Dictionary:
	return FILING_PROSE_TEMPLATE_DEFINITIONS.duplicate(true)


static func sector_style_vocabulary_definitions() -> Dictionary:
	return SECTOR_STYLE_VOCABULARY.duplicate(true)


static func filing_profile_definitions() -> Dictionary:
	return FILING_PROFILE_DEFINITIONS.duplicate(true)


static func filing_profile_definition(profile_id: String) -> Dictionary:
	var safe_profile_id: String = _resolved_filing_profile_id(profile_id)
	return FILING_PROFILE_DEFINITIONS.get(safe_profile_id, FILING_PROFILE_DEFINITIONS.get(DEFAULT_FILING_PROFILE_ID, {})).duplicate(true)


static func story_note_fact_required_fields() -> Array:
	return STORY_NOTE_FACT_REQUIRED_FIELDS.duplicate(true)


static func story_note_fact_story_types() -> Array:
	var rows: Array = []
	for story_type_value in STORY_NOTE_FACT_STORY_TYPE_DEFINITIONS.keys():
		var story_type: String = str(story_type_value).strip_edges()
		if not story_type.is_empty():
			rows.append(story_type)
	rows.sort()
	return rows


static func story_note_fact_story_type_definitions() -> Dictionary:
	return STORY_NOTE_FACT_STORY_TYPE_DEFINITIONS.duplicate(true)


static func story_note_fact_container_definitions() -> Dictionary:
	return STORY_NOTE_FACT_CONTAINER_DEFINITIONS.duplicate(true)


static func story_note_fact_profile_container_allowlists() -> Dictionary:
	return STORY_NOTE_FACT_PROFILE_CONTAINER_ALLOWLISTS.duplicate(true)


static func story_note_allowed_containers_for_profile(profile_id: String) -> Array:
	var safe_profile_id: String = _resolved_filing_profile_id(profile_id)
	var rows: Array = _string_array(STORY_NOTE_FACT_PROFILE_CONTAINER_ALLOWLISTS.get(safe_profile_id, []))
	rows.sort()
	return rows


static func story_note_allowed_containers_for_story_type(story_type: String, profile_id: String = "") -> Array:
	var safe_story_type: String = story_type.strip_edges().to_lower()
	var story_type_definition: Dictionary = STORY_NOTE_FACT_STORY_TYPE_DEFINITIONS.get(safe_story_type, {})
	var rows: Array = _string_array(story_type_definition.get("allowed_note_containers", []))
	if not profile_id.strip_edges().is_empty():
		var profile_rows: Array = story_note_allowed_containers_for_profile(profile_id)
		var filtered_rows: Array = []
		for container_value in rows:
			var container_id: String = str(container_value).strip_edges()
			if profile_rows.has(container_id):
				filtered_rows.append(container_id)
		rows = filtered_rows
	rows.sort()
	return rows


static func normalize_story_note_fact(fact: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for field_value in STORY_NOTE_FACT_REQUIRED_FIELDS:
		var field_id: String = str(field_value).strip_edges()
		normalized[field_id] = fact.get(field_id, _story_note_fact_default_value(field_id))
	normalized["fact_id"] = str(normalized.get("fact_id", "")).strip_edges()
	normalized["company_id"] = str(normalized.get("company_id", "")).strip_edges()
	normalized["story_type"] = str(normalized.get("story_type", "")).strip_edges().to_lower()
	normalized["note_container"] = str(normalized.get("note_container", "")).strip_edges().to_lower()
	normalized["counterparty_id"] = str(normalized.get("counterparty_id", "")).strip_edges()
	normalized["counterparty_name"] = str(normalized.get("counterparty_name", "")).strip_edges()
	normalized["agreement_type"] = str(normalized.get("agreement_type", "")).strip_edges()
	normalized["effective_date"] = str(normalized.get("effective_date", "")).strip_edges()
	normalized["term_months"] = int(normalized.get("term_months", 0))
	normalized["term_text"] = str(normalized.get("term_text", "")).strip_edges()
	normalized["amount"] = float(normalized.get("amount", 0.0))
	normalized["currency"] = str(normalized.get("currency", "")).strip_edges().to_upper()
	normalized["source_system"] = str(normalized.get("source_system", "")).strip_edges()
	normalized["source_ids"] = _string_array(normalized.get("source_ids", []))
	normalized["visibility_level"] = str(normalized.get("visibility_level", "")).strip_edges()
	normalized["capture_group"] = str(normalized.get("capture_group", "")).strip_edges()
	return normalized


static func validate_story_note_fact(fact: Dictionary, profile_id: String = DEFAULT_FILING_PROFILE_ID) -> Array:
	var errors: Array = []
	var normalized: Dictionary = normalize_story_note_fact(fact)
	var story_type: String = str(normalized.get("story_type", "")).strip_edges()
	var note_container: String = str(normalized.get("note_container", "")).strip_edges()
	var story_type_definition: Dictionary = STORY_NOTE_FACT_STORY_TYPE_DEFINITIONS.get(story_type, {})
	for field_value in STORY_NOTE_FACT_REQUIRED_FIELDS:
		var field_id: String = str(field_value).strip_edges()
		if not normalized.has(field_id):
			errors.append("missing_required_field:%s" % field_id)
	if str(normalized.get("fact_id", "")).is_empty():
		errors.append("empty_fact_id")
	if str(normalized.get("company_id", "")).is_empty():
		errors.append("empty_company_id")
	if story_type.is_empty() or not STORY_NOTE_FACT_STORY_TYPE_DEFINITIONS.has(story_type):
		errors.append("unknown_story_type:%s" % story_type)
	if note_container.is_empty() or not STORY_NOTE_FACT_CONTAINER_DEFINITIONS.has(note_container):
		errors.append("unknown_note_container:%s" % note_container)
	var allowed_story_containers: Array = story_note_allowed_containers_for_story_type(story_type, profile_id)
	if not allowed_story_containers.has(note_container):
		errors.append("container_not_allowed_for_story_type:%s:%s" % [story_type, note_container])
	if _string_array(normalized.get("source_ids", [])).is_empty():
		errors.append("missing_source_ids")
	if str(normalized.get("source_system", "")).is_empty():
		errors.append("missing_source_system")
	if str(normalized.get("visibility_level", "")).is_empty():
		errors.append("missing_visibility_level")
	if str(normalized.get("capture_group", "")).is_empty():
		errors.append("missing_capture_group")
	if bool(story_type_definition.get("requires_counterparty", false)):
		if str(normalized.get("counterparty_id", "")).is_empty():
			errors.append("missing_counterparty_id")
		if str(normalized.get("counterparty_name", "")).is_empty():
			errors.append("missing_counterparty_name")
	if bool(story_type_definition.get("requires_term", false)):
		if int(normalized.get("term_months", 0)) <= 0 and str(normalized.get("term_text", "")).is_empty():
			errors.append("missing_term")
	if bool(story_type_definition.get("requires_amount", false)):
		if float(normalized.get("amount", 0.0)) <= 0.0:
			errors.append("missing_amount")
		if str(normalized.get("currency", "")).is_empty():
			errors.append("missing_currency")
	return errors


static func story_note_fact_schema_hash() -> String:
	return _stable_hash(_story_note_fact_contract_payload())


static func story_note_fact_contract_summary() -> Dictionary:
	return {
		"story_note_fact_schema_version": STORY_NOTE_FACT_SCHEMA_VERSION,
		"story_note_fact_status": STORY_NOTE_FACT_STATUS,
		"required_fields": story_note_fact_required_fields(),
		"story_types": story_note_fact_story_types(),
		"note_containers": story_note_fact_container_definitions(),
		"profile_container_allowlists": story_note_fact_profile_container_allowlists(),
		"schema_hash": story_note_fact_schema_hash(),
		"visible_prose_generated": false
	}


static func build_story_note_fact_packets(
	company_definition: Dictionary = {},
	annual_statement: Dictionary = {},
	source_context: Dictionary = {},
	options: Dictionary = {}
) -> Array:
	var company_id: String = _story_note_company_id(company_definition, annual_statement, options)
	if company_id.is_empty():
		return []
	var profile_id: String = _story_note_profile_id(company_definition, annual_statement, options)
	var rows: Array = []
	rows = _story_note_append_valid_facts(rows, _story_note_facts_from_dossiers(company_definition, annual_statement, source_context, options, profile_id), profile_id)
	rows = _story_note_append_valid_facts(rows, _story_note_facts_from_relationship_edges(company_definition, annual_statement, source_context, options, profile_id), profile_id)
	rows = _story_note_append_valid_facts(rows, _story_note_facts_from_relationship_events(company_definition, annual_statement, source_context, options, profile_id), profile_id)
	rows = _story_note_append_valid_facts(rows, _story_note_facts_from_annual_statement(company_definition, annual_statement, source_context, options, profile_id), profile_id)
	rows = _story_note_append_valid_facts(rows, _story_note_facts_from_runtime_rows(company_definition, annual_statement, source_context, options, profile_id), profile_id)
	rows = _story_note_unique_sorted_facts(rows)

	var min_count: int = max(0, int(options.get("min_story_note_fact_packets", STORY_NOTE_FACT_PACKET_DEFAULT_MIN_COUNT)))
	if rows.size() < min_count:
		rows = _story_note_append_valid_facts(rows, _story_note_fallback_facts_from_company_metadata(company_definition, annual_statement, source_context, options, profile_id, min_count - rows.size()), profile_id)
		rows = _story_note_unique_sorted_facts(rows)

	var max_count: int = max(1, int(options.get("max_story_note_fact_packets", STORY_NOTE_FACT_PACKET_DEFAULT_MAX_COUNT)))
	if rows.size() > max_count:
		rows = rows.slice(0, max_count)
	return rows


static func validate_story_note_fact_packet_set(packets: Array, profile_id: String = DEFAULT_FILING_PROFILE_ID) -> Array:
	var errors: Array = []
	var seen_fact_ids: Dictionary = {}
	for index in range(packets.size()):
		if typeof(packets[index]) != TYPE_DICTIONARY:
			errors.append("packet_%d_not_dictionary" % index)
			continue
		var fact: Dictionary = packets[index]
		var fact_id: String = str(fact.get("fact_id", "")).strip_edges()
		if fact_id.is_empty():
			errors.append("packet_%d_empty_fact_id" % index)
		elif seen_fact_ids.has(fact_id):
			errors.append("duplicate_fact_id:%s" % fact_id)
		else:
			seen_fact_ids[fact_id] = true
		for visible_field in ["visible_text", "paragraph", "body", "rendered_text"]:
			if fact.has(visible_field):
				errors.append("packet_%d_has_visible_prose_field:%s" % [index, visible_field])
		errors.append_array(validate_story_note_fact(fact, profile_id))
		if str(fact.get("story_type", "")) == "bank_facility" and str(fact.get("source_system", "")) == "company_universe_catalog" and _resolved_filing_profile_id(profile_id) != "bank":
			var source_text: String = " ".join(_string_array(fact.get("source_ids", []))).to_lower()
			if not _text_matches_any_term(source_text, ["bank", "facility", "funding", "debt", "loan", "refinancing"]):
				errors.append("unsupported_non_bank_facility_fallback:%s" % fact_id)
	return errors


static func story_note_fact_packet_hash(packets: Array) -> String:
	return _stable_hash(_story_note_fact_packet_payload(packets))


static func story_note_fact_packet_summary(packets: Array, profile_id: String = DEFAULT_FILING_PROFILE_ID) -> Dictionary:
	return {
		"story_note_fact_packet_schema_version": STORY_NOTE_FACT_PACKET_SCHEMA_VERSION,
		"story_note_fact_packet_status": STORY_NOTE_FACT_PACKET_STATUS,
		"packet_count": packets.size(),
		"profile_id": _resolved_filing_profile_id(profile_id),
		"packet_hash": story_note_fact_packet_hash(packets),
		"validation_errors": validate_story_note_fact_packet_set(packets, profile_id),
		"visible_prose_generated": false
	}


static func story_note_prose_roles() -> Array:
	return STORY_NOTE_PROSE_ROLES.duplicate(true)


static func story_note_prose_forbidden_phrases() -> Array:
	return STORY_NOTE_PROSE_FORBIDDEN_PHRASES.duplicate(true)


static func story_note_placement_roles() -> Array:
	return STORY_NOTE_PLACEMENT_ROLES.duplicate(true)


static func build_story_note_placement_plan(
	story_note_fact_packets: Array,
	annual_statement: Dictionary = {},
	filing_section_schema: Array = [],
	filing_profile_id: String = DEFAULT_FILING_PROFILE_ID,
	options: Dictionary = {}
) -> Array:
	var profile_id: String = _resolved_filing_profile_id(filing_profile_id)
	var schema_rows: Array = filing_section_schema if not filing_section_schema.is_empty() else build_filing_section_schema(annual_statement, profile_id)
	var rows: Array = []
	var seen_fact_section: Dictionary = {}
	var max_per_fact: int = max(1, int(options.get("max_story_note_placements_per_fact", 3)))
	for fact_value in _story_note_unique_sorted_facts(story_note_fact_packets):
		if typeof(fact_value) != TYPE_DICTIONARY:
			continue
		var fact: Dictionary = normalize_story_note_fact(fact_value)
		if not validate_story_note_fact(fact, profile_id).is_empty():
			continue
		var fact_placements: Array = _story_note_placements_for_fact(fact, annual_statement, schema_rows, profile_id, options)
		var fact_placement_count: int = 0
		for placement_value in fact_placements:
			if typeof(placement_value) != TYPE_DICTIONARY:
				continue
			if fact_placement_count >= max_per_fact:
				break
			var placement: Dictionary = placement_value.duplicate(true)
			var section_id: String = str(placement.get("filing_section_id", "")).strip_edges()
			var fact_id: String = str(fact.get("fact_id", "")).strip_edges()
			if section_id.is_empty() or fact_id.is_empty():
				continue
			var fact_section_key: String = "%s|%s" % [fact_id, section_id]
			if seen_fact_section.has(fact_section_key):
				continue
			placement["schema_version"] = STORY_NOTE_PLACEMENT_SCHEMA_VERSION
			placement["placement_status"] = STORY_NOTE_PLACEMENT_STATUS
			placement["placement_order"] = rows.size() + 1
			if str(placement.get("placement_id", "")).strip_edges().is_empty():
				placement["placement_id"] = "story_note_placement|%s|%s|%s" % [
					_cache_token(fact_id),
					_cache_token(str(placement.get("placement_role", ""))),
					_cache_token(section_id)
				]
			rows.append(placement)
			seen_fact_section[fact_section_key] = true
			fact_placement_count += 1
	return rows


static func validate_story_note_placement_plan(plan: Array) -> Array:
	var errors: Array = []
	var seen_placement_ids: Dictionary = {}
	var seen_fact_section: Dictionary = {}
	for index in range(plan.size()):
		if typeof(plan[index]) != TYPE_DICTIONARY:
			errors.append("placement_%d_not_dictionary" % index)
			continue
		var row: Dictionary = plan[index]
		var placement_id: String = str(row.get("placement_id", "")).strip_edges()
		var placement_role: String = str(row.get("placement_role", "")).strip_edges()
		var paragraph_role: String = str(row.get("paragraph_role", "")).strip_edges()
		var section_id: String = str(row.get("filing_section_id", "")).strip_edges()
		var fact_ids: Array = _string_array(row.get("source_story_note_fact_ids", []))
		if placement_id.is_empty():
			errors.append("placement_%d_missing_placement_id" % index)
		elif seen_placement_ids.has(placement_id):
			errors.append("placement_%d_duplicate_placement_id:%s" % [index, placement_id])
		else:
			seen_placement_ids[placement_id] = true
		if not STORY_NOTE_PLACEMENT_ROLES.has(placement_role):
			errors.append("placement_%d_unknown_role:%s" % [index, placement_role])
		if not STORY_NOTE_PROSE_ROLES.has(paragraph_role):
			errors.append("placement_%d_unknown_paragraph_role:%s" % [index, paragraph_role])
		if section_id.is_empty():
			errors.append("placement_%d_missing_section_id" % index)
		if fact_ids.is_empty():
			errors.append("placement_%d_missing_story_note_fact_source" % index)
		if typeof(row.get("fact", {})) != TYPE_DICTIONARY:
			errors.append("placement_%d_missing_fact_payload" % index)
		for fact_id_value in fact_ids:
			var fact_section_key: String = "%s|%s" % [str(fact_id_value), section_id]
			if seen_fact_section.has(fact_section_key):
				errors.append("placement_%d_duplicate_fact_section:%s" % [index, fact_section_key])
			seen_fact_section[fact_section_key] = true
	return errors


static func story_note_placement_plan_hash(plan: Array) -> String:
	return _stable_hash(_story_note_placement_plan_payload(plan))


static func story_note_placement_plan_summary(plan: Array) -> Dictionary:
	return {
		"story_note_placement_schema_version": STORY_NOTE_PLACEMENT_SCHEMA_VERSION,
		"story_note_placement_status": STORY_NOTE_PLACEMENT_STATUS,
		"placement_count": plan.size(),
		"placement_hash": story_note_placement_plan_hash(plan),
		"role_counts": _story_note_placement_role_counts(plan),
		"section_counts": _story_note_placement_section_counts(plan),
		"fact_section_span_counts": _story_note_placement_fact_span_counts(plan),
		"validation_errors": validate_story_note_placement_plan(plan)
	}


static func build_story_note_prose_packets(
	story_note_fact_packets: Array,
	annual_statement: Dictionary = {},
	filing_section_schema: Array = [],
	filing_profile_id: String = DEFAULT_FILING_PROFILE_ID,
	options: Dictionary = {}
) -> Array:
	var profile_id: String = _resolved_filing_profile_id(filing_profile_id)
	var schema_rows: Array = filing_section_schema if not filing_section_schema.is_empty() else build_filing_section_schema(annual_statement, profile_id)
	var placement_plan: Array = _variant_array(options.get("story_note_placement_plan", []))
	if placement_plan.is_empty():
		placement_plan = build_story_note_placement_plan(story_note_fact_packets, annual_statement, schema_rows, profile_id, options)
	placement_plan.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("placement_order", 0)) < int(right.get("placement_order", 0))
	)
	var rows: Array = []
	var seen_text_by_section: Dictionary = {}
	var section_counts: Dictionary = {}
	var max_per_section: int = max(1, int(options.get("max_story_note_prose_packets_per_section", 3)))
	for placement_value in placement_plan:
		if typeof(placement_value) != TYPE_DICTIONARY:
			continue
		var placement: Dictionary = placement_value
		var fact_payload: Variant = placement.get("fact", {})
		if typeof(fact_payload) != TYPE_DICTIONARY:
			continue
		var fact: Dictionary = normalize_story_note_fact(fact_payload)
		if not validate_story_note_fact(fact, profile_id).is_empty():
			continue
		var section_id: String = str(placement.get("filing_section_id", "")).strip_edges()
		if section_id.is_empty():
			continue
		var section_count: int = int(section_counts.get(section_id, 0))
		if section_count >= max_per_section:
			continue
		var text: String = _story_note_rendered_text_for_placement(fact, placement, annual_statement, options).strip_edges()
		if text.is_empty() or _story_note_text_has_forbidden_phrase(text):
			continue
		var text_key: String = _story_note_text_key(text)
		var section_seen: Dictionary = seen_text_by_section.get(section_id, {}) if typeof(seen_text_by_section.get(section_id, {})) == TYPE_DICTIONARY else {}
		if section_seen.has(text_key):
			continue
		section_seen[text_key] = true
		seen_text_by_section[section_id] = section_seen
		var row: Dictionary = _story_note_prose_row(rows.size() + 1, section_id, fact, text, schema_rows, options, placement)
		if row.is_empty():
			continue
		rows.append(row)
		section_counts[section_id] = section_count + 1
	return rows


static func validate_story_note_prose_packets(packets: Array) -> Array:
	var errors: Array = []
	var seen_by_section: Dictionary = {}
	for index in range(packets.size()):
		if typeof(packets[index]) != TYPE_DICTIONARY:
			errors.append("prose_%d_not_dictionary" % index)
			continue
		var row: Dictionary = packets[index]
		var section_id: String = str(row.get("filing_section_id", "")).strip_edges()
		var text: String = str(row.get("visible_text", "")).strip_edges()
		var role: String = str(row.get("paragraph_role", "")).strip_edges()
		if section_id.is_empty():
			errors.append("prose_%d_missing_section_id" % index)
		if text.is_empty():
			errors.append("prose_%d_missing_visible_text" % index)
		if not STORY_NOTE_PROSE_ROLES.has(role):
			errors.append("prose_%d_unknown_role:%s" % [index, role])
		if _string_array(row.get("source_story_note_fact_ids", [])).is_empty():
			errors.append("prose_%d_missing_story_note_fact_source" % index)
		if bool(row.get("visible_truth_labels_allowed", true)):
			errors.append("prose_%d_visible_truth_labels_allowed" % index)
		if bool(row.get("hidden_source_ids_visible", true)):
			errors.append("prose_%d_hidden_source_ids_visible" % index)
		if _story_note_text_has_forbidden_phrase(text):
			errors.append("prose_%d_forbidden_phrase" % index)
		for hidden_token in ["story|", "packet|", "placement|", "truth_state", "source_quality", "disclosure_quality", "confidence"]:
			if text.to_lower().find(str(hidden_token)) != -1:
				errors.append("prose_%d_hidden_token:%s" % [index, str(hidden_token)])
		var section_seen: Dictionary = seen_by_section.get(section_id, {}) if typeof(seen_by_section.get(section_id, {})) == TYPE_DICTIONARY else {}
		var text_key: String = _story_note_text_key(text)
		if section_seen.has(text_key):
			errors.append("prose_%d_duplicate_visible_text:%s" % [index, section_id])
		section_seen[text_key] = true
		seen_by_section[section_id] = section_seen
	return errors


static func story_note_prose_hash(packets: Array) -> String:
	return _stable_hash(_story_note_prose_payload(packets))


static func story_note_prose_summary(packets: Array) -> Dictionary:
	return {
		"story_note_prose_schema_version": STORY_NOTE_PROSE_SCHEMA_VERSION,
		"story_note_prose_status": STORY_NOTE_PROSE_STATUS,
		"prose_count": packets.size(),
		"prose_hash": story_note_prose_hash(packets),
		"role_counts": _story_note_prose_role_counts(packets),
		"section_counts": _story_note_prose_section_counts(packets),
		"validation_errors": validate_story_note_prose_packets(packets)
	}


static func select_filing_profile(annual_statement: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var context: Dictionary = _filing_profile_context(annual_statement, options)
	var explicit_profile_id: String = str(options.get("filing_profile_id", options.get("profile_id", ""))).strip_edges()
	if FILING_PROFILE_DEFINITIONS.has(explicit_profile_id):
		return _filing_profile_selection_row(explicit_profile_id, "explicit_option", context)
	var sector_id: String = str(context.get("sector_id", "")).strip_edges().to_lower()
	var subsector_id: String = str(context.get("subsector_id", "")).strip_edges().to_lower()
	var business_text: String = str(context.get("business_text", "")).strip_edges().to_lower()
	var moat_text: String = str(context.get("moat_text", "")).strip_edges().to_lower()
	if _context_matches_filing_profile("bank", sector_id, subsector_id, business_text, moat_text):
		return _filing_profile_selection_row("bank", "finance_bank_context", context)
	if _context_matches_filing_profile("industrial_trading", sector_id, subsector_id, business_text, moat_text):
		return _filing_profile_selection_row("industrial_trading", "industrial_trading_context", context)
	return _filing_profile_selection_row(DEFAULT_FILING_PROFILE_ID, "fallback_default", context)


static func resolve_filing_profile_id(annual_statement: Dictionary = {}, options: Dictionary = {}) -> String:
	return str(select_filing_profile(annual_statement, options).get("profile_id", DEFAULT_FILING_PROFILE_ID))


static func filing_prose_hash(
	annual_statement: Dictionary,
	filing_section_schema: Array = [],
	accounting_footprints: Array = [],
	sector_style_id: String = DEFAULT_SECTOR_STYLE_ID
) -> String:
	return _stable_hash(_filing_prose_payload(build_filing_prose_packets(annual_statement, filing_section_schema, accounting_footprints, sector_style_id)))


static func build_visible_filing_document(
	annual_statement: Dictionary,
	contract: Dictionary,
	options: Dictionary = {}
) -> Dictionary:
	if annual_statement.is_empty() or contract.is_empty():
		return {}
	var schema_rows: Array = _variant_array(contract.get("filing_section_schema", []))
	var prose_rows: Array = _variant_array(contract.get("filing_prose_packets", []))
	prose_rows.append_array(_variant_array(contract.get("story_note_prose_packets", [])))
	var footprint_rows: Array = _variant_array(contract.get("accounting_footprint_packets", []))
	var visible_sections: Array = _build_visible_filing_sections(annual_statement, schema_rows, prose_rows, footprint_rows)
	var visible_sections_by_id: Dictionary = {}
	var section_order: Array = []
	var paragraph_count: int = 0
	var table_count: int = 0
	var table_row_count: int = 0
	var cross_reference_count: int = 0
	var display_block_count: int = 0
	var report_section_map: Array = []
	for section_value in visible_sections:
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		var section_id: String = str(section.get("section_id", "")).strip_edges()
		if section_id.is_empty():
			continue
		visible_sections_by_id[section_id] = section.duplicate(true)
		section_order.append(section_id)
		paragraph_count += _variant_array(section.get("paragraphs", [])).size()
		var compact_tables: Array = _variant_array(section.get("compact_tables", []))
		table_count += compact_tables.size()
		for table_value in compact_tables:
			if typeof(table_value) == TYPE_DICTIONARY:
				table_row_count += _variant_array(table_value.get("rows", [])).size()
		cross_reference_count += _variant_array(section.get("cross_references", [])).size()
		display_block_count += _variant_array(section.get("display_blocks", [])).size()
		if section_id != "table_of_contents":
			report_section_map.append(_visible_section_report_map_row(section))
	var visible_hash: String = _stable_hash(_visible_filing_payload(visible_sections))
	var filing_profile_id: String = _resolved_filing_profile_id(str(contract.get("filing_profile_id", DEFAULT_FILING_PROFILE_ID)))
	return {
		"visible_filing_schema_version": VISIBLE_FILING_SCHEMA_VERSION,
		"visible_filing_status": VISIBLE_FILING_STATUS,
		"visible_filing_hash": visible_hash,
		"visible_filing_sections": visible_sections,
		"visible_filing_sections_by_id": visible_sections_by_id,
		"visible_filing_section_order": section_order,
		"visible_filing_section_count": visible_sections.size(),
		"visible_filing_paragraph_count": paragraph_count,
		"visible_filing_table_count": table_count,
		"visible_filing_table_row_count": table_row_count,
		"visible_filing_cross_reference_count": cross_reference_count,
		"visible_filing_display_block_count": display_block_count,
		"visible_filing_assembly_priority": VISIBLE_FILING_ASSEMBLY_PRIORITY.duplicate(true),
		"visible_filing_profile_balance": _visible_filing_profile_balance(filing_profile_id, visible_sections),
		"visible_generation_sources": _visible_generation_sources(annual_statement, contract, options),
		"annual_report_section_map": report_section_map,
		"table_of_contents": _variant_array(contract.get("filing_table_of_contents", [])),
		"report_title": "Consolidated Financial Statements",
		"fiscal_year": int(contract.get("fiscal_year", annual_statement.get("fiscal_year", 0))),
		"comparative_year": int(annual_statement.get("comparative_year", 0)),
		"currency": str(annual_statement.get("currency", "")),
		"unit": str(annual_statement.get("unit", "")),
		"audit_status": str(annual_statement.get("audit_status", "audited"))
	}


static func visible_filing_hash(document: Dictionary) -> String:
	return _stable_hash(_visible_filing_payload(_variant_array(document.get("visible_filing_sections", []))))


static func build_filing_section_schema(annual_statement: Dictionary = {}, filing_profile_id: String = DEFAULT_FILING_PROFILE_ID) -> Array:
	var source_sections: Dictionary = _source_sections_by_id(annual_statement)
	var source_schema: Array = _filing_section_schema_for_profile(filing_profile_id)
	var rows: Array = []
	for index in range(source_schema.size()):
		var row: Dictionary = source_schema[index].duplicate(true)
		row["schema_version"] = FILING_ANATOMY_SCHEMA_VERSION
		row["section_order"] = index + 1
		row["filing_profile_id"] = _resolved_filing_profile_id(filing_profile_id)
		row["page_label"] = _page_label(row)
		var source_section_id: String = str(row.get("source_section_id", "")).strip_edges()
		if source_sections.has(source_section_id):
			var source_section: Dictionary = source_sections.get(source_section_id, {})
			row["r3_source_read_mode"] = str(source_section.get("read_mode", ""))
			row["r3_source_capture_mode"] = str(source_section.get("capture_mode", ""))
			row["r3_source_page_label"] = _page_label(source_section)
		else:
			row["r3_source_read_mode"] = ""
			row["r3_source_capture_mode"] = ""
			row["r3_source_page_label"] = ""
		rows.append(row)
	return rows


static func _filing_section_schema_for_profile(filing_profile_id: String) -> Array:
	var safe_profile_id: String = _resolved_filing_profile_id(filing_profile_id)
	if safe_profile_id == "bank":
		return _bank_filing_section_schema()
	return FILING_SECTION_SCHEMA.duplicate(true)


static func _bank_filing_section_schema() -> Array:
	var rows: Array = []
	for index in range(min(8, FILING_SECTION_SCHEMA.size())):
		if typeof(FILING_SECTION_SCHEMA[index]) == TYPE_DICTIONARY:
			rows.append(FILING_SECTION_SCHEMA[index].duplicate(true))
	for section_value in BANK_FILING_NOTE_SECTION_SCHEMA:
		if typeof(section_value) == TYPE_DICTIONARY:
			rows.append(section_value.duplicate(true))
	return rows


static func build_filing_table_of_contents(filing_section_schema: Array = []) -> Array:
	var source_rows: Array = filing_section_schema if not filing_section_schema.is_empty() else build_filing_section_schema()
	var rows: Array = []
	for row_value in source_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = row_value
		rows.append({
			"schema_version": FILING_ANATOMY_SCHEMA_VERSION,
			"section_id": str(section.get("section_id", "")),
			"document_part": str(section.get("document_part", "")),
			"filing_title": str(section.get("filing_title", "")),
			"localized_title": str(section.get("localized_title", "")),
			"page_label": str(section.get("page_label", "")),
			"section_order": int(section.get("section_order", rows.size() + 1)),
			"virtual_page_group": str(section.get("virtual_page_group", ""))
		})
	return rows


static func build_r3_source_section_map(filing_section_schema: Array = []) -> Array:
	var source_rows: Array = filing_section_schema if not filing_section_schema.is_empty() else build_filing_section_schema()
	var grouped: Dictionary = {}
	for row_value in source_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var source_section_id: String = str(row.get("source_section_id", "")).strip_edges()
		if source_section_id.is_empty():
			source_section_id = "front_matter"
		if not grouped.has(source_section_id):
			grouped[source_section_id] = {
				"source_section_id": source_section_id,
				"filing_section_ids": [],
				"source_arrays": [],
				"note_type_filters": [],
				"mapping_role": "expanded_note_groups" if source_section_id == "notes" else ("front_matter" if source_section_id == "front_matter" else "direct_statement")
			}
		var group: Dictionary = grouped[source_section_id]
		_append_unique(group["filing_section_ids"], str(row.get("section_id", "")))
		_append_unique(group["source_arrays"], str(row.get("source_array", "")))
		for note_type in _variant_array(row.get("source_note_types", [])):
			_append_unique(group["note_type_filters"], str(note_type))
	var keys: Array = grouped.keys()
	keys.sort()
	var rows: Array = []
	for key_value in keys:
		rows.append(grouped.get(key_value, {}).duplicate(true))
	return rows


static func build_accounting_footprint_packets(annual_statement: Dictionary, filing_section_schema: Array = []) -> Array:
	if annual_statement.is_empty():
		return []
	var schema_rows: Array = filing_section_schema if not filing_section_schema.is_empty() else build_filing_section_schema(annual_statement)
	var line_lookup: Dictionary = _statement_line_lookup(annual_statement)
	var row_model_lookup: Dictionary = _accounting_row_model_lookup(annual_statement)
	var note_lookup: Dictionary = _note_lookup_by_type(annual_statement)
	var section_lookup: Dictionary = _filing_section_lookup_by_note_type(schema_rows)
	var packet_refs: Array = _disclosure_packet_refs_from_annual_statement(annual_statement)
	var rows: Array = []
	var row_index: int = 1
	for packet_value in packet_refs:
		if typeof(packet_value) != TYPE_DICTIONARY:
			continue
		var packet_ref: Dictionary = packet_value
		var footprint_types: Array = _footprint_types_for_packet(packet_ref)
		for type_value in footprint_types:
			var footprint_type: String = str(type_value).strip_edges()
			if footprint_type.is_empty():
				continue
			var row: Dictionary = _accounting_footprint_row(
				row_index,
				footprint_type,
				packet_ref,
				line_lookup,
				row_model_lookup,
				note_lookup,
				section_lookup
			)
			if row.is_empty():
				continue
			rows.append(row)
			row_index += 1
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if str(left.get("story_id", "")) != str(right.get("story_id", "")):
			return str(left.get("story_id", "")) < str(right.get("story_id", ""))
		if str(left.get("source_disclosure_packet_id", "")) != str(right.get("source_disclosure_packet_id", "")):
			return str(left.get("source_disclosure_packet_id", "")) < str(right.get("source_disclosure_packet_id", ""))
		var left_type_order: int = _footprint_type_order(str(left.get("footprint_type", "")))
		var right_type_order: int = _footprint_type_order(str(right.get("footprint_type", "")))
		if left_type_order != right_type_order:
			return left_type_order < right_type_order
		return str(left.get("footprint_id", "")) < str(right.get("footprint_id", ""))
	)
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		row["footprint_order"] = index + 1
	return rows


static func build_filing_prose_packets(
	annual_statement: Dictionary,
	filing_section_schema: Array = [],
	accounting_footprints: Array = [],
	sector_style_id: String = DEFAULT_SECTOR_STYLE_ID
) -> Array:
	if annual_statement.is_empty():
		return []
	var schema_rows: Array = filing_section_schema if not filing_section_schema.is_empty() else build_filing_section_schema(annual_statement)
	var footprint_rows: Array = accounting_footprints if not accounting_footprints.is_empty() else build_accounting_footprint_packets(annual_statement, schema_rows)
	var filing_profile_id: String = _filing_profile_id_from_schema(schema_rows)
	var resolved_style_id: String = _sector_style_id_for_profile(filing_profile_id, sector_style_id)
	var style: Dictionary = _sector_style_vocabulary(resolved_style_id)
	var line_lookup: Dictionary = _statement_line_lookup(annual_statement)
	var note_lookup: Dictionary = _note_lookup_by_type(annual_statement)
	var footprints_by_section: Dictionary = _footprints_by_section(footprint_rows)
	var rows: Array = []
	var paragraph_order: int = 1
	for section_value in schema_rows:
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		var section_id: String = str(section.get("section_id", "")).strip_edges()
		if section_id.is_empty() or section_id == "table_of_contents":
			continue
		var template_type: String = _section_prose_template_type(section_id)
		var boilerplate: Dictionary = _filing_prose_row(
			paragraph_order,
			section,
			template_type,
			"routine_boilerplate",
			"none",
			_routine_prose_text(section, annual_statement, style, template_type),
			{},
			resolved_style_id
		)
		if not boilerplate.is_empty():
			rows.append(boilerplate)
			paragraph_order += 1
		if section_id in ["note_accounting_policies", "note_bank_accounting_policies"]:
			var estimates_row: Dictionary = _filing_prose_row(
				paragraph_order,
				section,
				"estimates_and_judgments",
				"estimate_context",
				"low",
				_estimates_prose_text(annual_statement, style),
				{},
				resolved_style_id
			)
			if not estimates_row.is_empty():
				rows.append(estimates_row)
				paragraph_order += 1
		var section_footprints: Array = _variant_array(footprints_by_section.get(section_id, []))
		for footprint_value in section_footprints:
			if typeof(footprint_value) != TYPE_DICTIONARY:
				continue
			var footprint: Dictionary = footprint_value
			var role: String = _footprint_prose_role(footprint)
			var clue_density: String = "medium" if str(footprint.get("story_exposure", "")) == "fragment" else "low"
			var text: String = _footprint_prose_text(footprint, line_lookup, note_lookup, annual_statement, style, template_type)
			var footprint_row: Dictionary = _filing_prose_row(
				paragraph_order,
				section,
				template_type,
				role,
				clue_density,
				text,
				footprint,
				resolved_style_id
			)
			if not footprint_row.is_empty():
				rows.append(footprint_row)
				paragraph_order += 1
	return rows


static func _filing_prose_row(
	paragraph_order: int,
	section: Dictionary,
	template_type: String,
	paragraph_role: String,
	clue_density: String,
	visible_text: String,
	footprint: Dictionary,
	sector_style_id: String
) -> Dictionary:
	var section_id: String = str(section.get("section_id", "")).strip_edges()
	var text: String = visible_text.strip_edges()
	if section_id.is_empty() or text.is_empty():
		return {}
	var footprint_id: String = str(footprint.get("footprint_id", "")).strip_edges()
	var source_packet_id: String = str(footprint.get("source_disclosure_packet_id", "")).strip_edges()
	var story_id: String = str(footprint.get("story_id", "")).strip_edges()
	return {
		"schema_version": FILING_PROSE_SCHEMA_VERSION,
		"prose_status": FILING_PROSE_STATUS,
		"paragraph_id": "filing_prose|%s|%03d" % [section_id, paragraph_order],
		"paragraph_order": paragraph_order,
		"filing_section_id": section_id,
		"section_order": int(section.get("section_order", 0)),
		"section_title": str(section.get("filing_title", "")),
		"template_type": template_type,
		"paragraph_role": paragraph_role,
		"clue_density": clue_density,
		"boilerplate_density": str(section.get("boilerplate_density", "")),
		"visible_text": text,
		"visible_truth_labels_allowed": false,
		"hidden_source_ids_visible": false,
		"sector_style_id": _resolved_sector_style_id(sector_style_id),
		"source_footprint_ids": [footprint_id] if not footprint_id.is_empty() else [],
		"source_disclosure_packet_ids": [source_packet_id] if not source_packet_id.is_empty() else [],
		"source_disclosure_placement_ids": [str(footprint.get("source_disclosure_placement_id", "")).strip_edges()] if not str(footprint.get("source_disclosure_placement_id", "")).strip_edges().is_empty() else [],
		"source_story_ids": [story_id] if not story_id.is_empty() else [],
		"statement_line_ids": _string_array(footprint.get("statement_line_ids", [])),
		"statement_metric_ids": _string_array(footprint.get("statement_metric_ids", [])),
		"metric_ids": _string_array(footprint.get("metric_ids", [])),
		"note_ids": _string_array(footprint.get("note_ids", [])),
		"note_type": str(footprint.get("source_note_type", "")),
		"footprint_type": str(footprint.get("footprint_type", "")),
		"story_exposure": str(footprint.get("story_exposure", "")),
		"traceability_mode": "internal_source_ids_only"
	}


static func _section_prose_template_type(section_id: String) -> String:
	match section_id:
		"cover":
			return "company_information"
		"directors_statement":
			return "accounting_policies"
		"independent_auditor_report":
			return "estimates_and_judgments"
		"financial_position", "changes_in_equity":
			return "accounting_policies"
		"profit_or_loss_and_oci":
			return "revenue"
		"cash_flows":
			return "ppe_capex"
		"note_company_information":
			return "company_information"
		"note_bank_company_information":
			return "company_information"
		"note_accounting_policies":
			return "accounting_policies"
		"note_bank_accounting_policies":
			return "accounting_policies"
		"note_financial_assets_receivables":
			return "receivables"
		"note_bank_cash_reserves", "note_bank_placements", "note_bank_securities":
			return "bank_cash_reserves"
		"note_bank_loans_financing", "note_bank_allowance_impairment":
			return "bank_loans"
		"note_inventories":
			return "inventories"
		"note_ppe_investments":
			return "ppe_capex"
		"note_liabilities_borrowings":
			return "borrowings"
		"note_bank_deposits", "note_bank_temporary_syirkah_funds":
			return "bank_funding"
		"note_bank_capital_adequacy":
			return "bank_capital"
		"note_bank_liquidity_risk":
			return "bank_liquidity_risk"
		"note_bank_regulatory_compliance":
			return "bank_regulatory"
		"note_revenue_expenses_tax_equity":
			return "revenue"
		"note_bank_interest_income":
			return "revenue"
		"note_related_parties":
			return "related_party"
		"note_bank_related_parties":
			return "related_party"
		"note_segment_information":
			return "segment"
		"note_commitments_contingencies":
			return "commitments"
		"note_financial_risk_management":
			return "risk_management"
		"note_bank_credit_risk":
			return "bank_credit_risk"
		"note_non_cash_subsequent_events":
			return "subsequent_events"
	return "accounting_policies"


static func _routine_prose_text(section: Dictionary, annual_statement: Dictionary, style: Dictionary, template_type: String) -> String:
	var section_id: String = str(section.get("section_id", "")).strip_edges()
	var fiscal_year: int = int(annual_statement.get("fiscal_year", 0))
	var comparative_year: int = int(annual_statement.get("comparative_year", fiscal_year - 1))
	var company_name: String = str(annual_statement.get("company_name", "the Company")).strip_edges()
	if company_name.is_empty():
		company_name = "the Company"
	var entity_label: String = str(style.get("entity_label", "the Group"))
	var business_lines: String = str(style.get("business_lines", "its operating activities"))
	var inventory_label: String = str(style.get("inventory_label", "inventories"))
	var customer_label: String = str(style.get("customer_label", "customers"))
	var asset_base: String = str(style.get("asset_base", "operating assets"))
	var risk_focus: String = str(style.get("risk_focus", "credit, liquidity, market, currency, and interest rate risks"))
	var segment_basis: String = str(style.get("segment_basis", "business lines and operating activities"))
	match section_id:
		"cover":
			return "%s presents consolidated financial statements for the year ended 31 December %d with comparative information for %d." % [company_name, fiscal_year, comparative_year]
		"directors_statement":
			return "The Directors are responsible for the preparation and fair presentation of the consolidated financial statements in accordance with the accounting policies adopted by %s." % entity_label
		"independent_auditor_report":
			return "The audit was conducted on the consolidated financial statements as a whole, and the matters discussed in this report were addressed in that context."
		"financial_position":
			return "The consolidated statement of financial position should be read together with the related notes, which describe the composition and measurement of assets, liabilities, and equity."
		"profit_or_loss_and_oci":
			return "The consolidated statement of profit or loss and other comprehensive income presents the full-year performance of %s before the related note disclosures." % entity_label
		"changes_in_equity":
			return "The consolidated statement of changes in equity reconciles opening and closing equity after profit for the year, distributions, and other movements."
		"cash_flows":
			return "The consolidated statement of cash flows classifies cash movements into operating, investing, and financing activities for the year."
	match template_type:
		"company_information":
			return "%s is engaged principally in %s, and the consolidated financial statements include the parent entity and controlled entities." % [entity_label.capitalize(), business_lines]
		"accounting_policies":
			return "The consolidated financial statements have been prepared using accounting policies applied consistently to material classes of transactions and account balances."
		"receivables":
			return "Trade receivables arise from transactions with %s and are reviewed for collectability based on contractual terms, aging, and available settlement information." % customer_label
		"bank_cash_reserves":
			match section_id:
				"note_bank_cash_reserves":
					return "Cash and statutory reserve balances comprise cash on hand, current accounts with Bank Indonesia, and balances with other banks available for daily settlement activities."
				"note_bank_placements":
					return "Placements with Bank Indonesia and other banks are presented by counterparty group and original maturity to show how short-term liquidity is deployed."
				"note_bank_securities":
					return "Marketable securities are classified by portfolio purpose and measurement basis, including instruments held for liquidity management and treasury income."
			return "Bank financial assets are grouped by counterparty, maturity, and measurement basis before the related risk disclosures."
		"bank_loans":
			if section_id == "note_bank_allowance_impairment":
				return "Allowance for impairment losses is measured from credit-risk staging, historical loss experience, forward-looking factors, and specific borrower conditions."
			return "Loans and sharia financing are presented by credit stage, product type, and economic sector after deducting allowance for impairment losses."
		"bank_funding":
			if section_id == "note_bank_temporary_syirkah_funds":
				return "Temporary syirkah funds represent profit-sharing investment funds where the Bank manages customer funds under sharia banking arrangements."
			return "Deposits from customers and other banks are grouped by product, counterparty, and maturity because funding mix affects liquidity and interest expense."
		"bank_capital":
			return "Capital adequacy is monitored using regulatory capital and risk-weighted assets, with ratios compared against minimum requirements set by the banking regulator."
		"bank_credit_risk":
			return "Credit risk disclosures summarize borrower quality, collateral discipline, impairment coverage, and management's monitoring of performing and non-performing exposure."
		"bank_liquidity_risk":
			return "Liquidity risk disclosures group financial liabilities by contractual maturity and are read together with cash, placements, securities, and deposit concentration."
		"bank_regulatory":
			return "Regulatory reserve and compliance disclosures cover minimum statutory reserves, liquidity buffers, net open position, and other banking prudential requirements."
		"inventories":
			return "%s are stated after considering their condition, expected use, and realizable value at the reporting date." % inventory_label.capitalize()
		"ppe_capex":
			return "Property, plant, and equipment includes %s used in the ordinary course of operations and is presented after accumulated depreciation." % asset_base
		"borrowings":
			return "Borrowings are presented according to contractual maturity, currency, and applicable financing terms as at the reporting date."
		"revenue":
			return "Revenue, expenses, and tax are recognized for the year when the underlying performance obligation, cost, or taxable event is reflected in the consolidated accounts."
		"segment":
			return "Operating segments are presented on the basis reviewed by management, including results by %s." % segment_basis
		"related_party":
			return "Related-party balances and transactions are disclosed when relationships require separate presentation from transactions with third parties."
		"commitments":
			return "Commitments, agreements, and contingencies are disclosed when contractual or legal matters remain outstanding at the reporting date."
		"risk_management":
			return "Financial risk management describes how %s monitors %s arising from its financial instruments and operating arrangements." % [entity_label, risk_focus]
		"subsequent_events":
			return "Events after the reporting period are evaluated up to the date the consolidated financial statements are authorized for issue."
	return "The section should be read together with the related notes and statement rows."


static func _estimates_prose_text(annual_statement: Dictionary, style: Dictionary) -> String:
	var entity_label: String = str(style.get("entity_label", "the Group"))
	var fiscal_year: int = int(annual_statement.get("fiscal_year", 0))
	return "In preparing the %d consolidated financial statements, management makes estimates for recoverability, useful lives, impairment indicators, provisions, and fair presentation of material account balances of %s." % [fiscal_year, entity_label]


static func _footprint_prose_role(footprint: Dictionary) -> String:
	match str(footprint.get("footprint_type", "")):
		"numeric_movement", "statement_row_note_reference":
			return "quantified_footprint"
		"compact_table_row":
			return "supporting_table_context"
		"cross_note_reference":
			return "cross_reference_context"
		"auditor_risk_focus":
			return "audit_focus_context"
		"segment_movement":
			return "segment_context"
		"risk_management_language":
			return "risk_context"
		"subsequent_event_language":
			return "subsequent_event_context"
	return "note_context"


static func _footprint_prose_text(
	footprint: Dictionary,
	line_lookup: Dictionary,
	note_lookup: Dictionary,
	annual_statement: Dictionary,
	style: Dictionary,
	template_type: String = ""
) -> String:
	var footprint_type: String = str(footprint.get("footprint_type", "")).strip_edges()
	var line: Dictionary = _first_line_for_footprint(footprint, line_lookup)
	var note_type: String = str(footprint.get("source_note_type", "")).strip_edges()
	var note_label: String = _note_label(note_type, note_lookup)
	var section_id: String = str(footprint.get("filing_section_id", "")).strip_edges()
	var line_label: String = str(line.get("label", note_label)).strip_edges()
	if line_label.is_empty():
		line_label = note_label
	var amount_text: String = _line_amount_text(line, annual_statement)
	var entity_label: String = str(style.get("entity_label", "the Group"))
	var segment_basis: String = str(style.get("segment_basis", "business lines and operating activities"))
	var risk_focus: String = str(style.get("risk_focus", "credit, liquidity, market, currency, and interest rate risks"))
	var table_label: String = _section_specific_table_label(section_id, template_type, line_label)
	match footprint_type:
		"numeric_movement":
			return "%s is presented at %s for the year, with comparative movement shown in the related statement row or note table." % [line_label, amount_text]
		"statement_row_note_reference":
			return "%s is supported by %s, where the balance is broken out using the categories applied in the filing." % [line_label, note_label]
		"note_paragraph":
			return _section_specific_note_context(section_id, template_type, note_label, entity_label)
		"compact_table_row":
			return "%s includes %s as one of the selected annual amounts for the section." % [table_label, line_label]
		"cross_note_reference":
			return _section_specific_cross_note_context(section_id, template_type, note_label)
		"auditor_risk_focus":
			return "The auditor considered the measurement of %s in planning procedures and evaluating whether the related balances were presented fairly." % note_label
		"segment_movement":
			return "Segment rows group revenue, result, assets, and selected movements by %s for comparison with the consolidated statements." % segment_basis
		"risk_management_language":
			return "%s manages %s through counterparty limits, maturity monitoring, sensitivity review, and periodic reporting to management." % [entity_label.capitalize(), risk_focus]
		"subsequent_event_language":
			return "Subsequent-event disclosure is considered when after-period conditions affect commitments, financing, operations, or other matters described elsewhere in the notes."
	return "The note disclosure provides additional context for the related consolidated statement account."


static func _section_specific_note_context(section_id: String, template_type: String, note_label: String, entity_label: String) -> String:
	match template_type:
		"bank_cash_reserves":
			return "%s sets out the counterparty and maturity profile of liquid financial assets held for settlement, reserve, and treasury purposes." % note_label
		"bank_loans":
			return "%s sets out the credit-stage, product, borrower-sector, and impairment context used to assess the Bank's earning assets." % note_label
		"bank_funding":
			return "%s sets out customer and interbank funding balances by product, party, and maturity profile." % note_label
		"bank_capital":
			return "%s presents regulatory capital, risk-weighted assets, and minimum capital monitoring used by management." % note_label
		"bank_credit_risk":
			return "%s explains the credit-risk framework, including staging, collateral review, watchlist monitoring, and impairment coverage." % note_label
		"bank_liquidity_risk":
			return "%s presents contractual maturity buckets and funding concentrations used in liquidity monitoring." % note_label
		"bank_regulatory":
			return "%s covers prudential reserve, liquidity-buffer, and regulatory ratio requirements applicable to the Bank." % note_label
		"receivables":
			return "%s sets out customer balances, aging, allowance, and concentration information for receivables." % note_label
		"inventories":
			return "%s sets out inventory categories, valuation basis, and write-down considerations at the reporting date." % note_label
		"ppe_capex":
			return "%s sets out cost, accumulated depreciation, additions, disposals, and construction-in-progress movements." % note_label
		"borrowings":
			return "%s sets out financing balances by lender type, maturity, currency, and security arrangements." % note_label
		"revenue":
			return "%s presents revenue, cost, expenses, tax, and equity movements using the presentation applied in the statements." % note_label
		"segment":
			return "%s presents operating information reviewed by management for the reportable segments." % note_label
		"related_party":
			return "%s separates transactions and balances with parties related to %s from third-party activity." % [note_label, entity_label]
		"commitments":
			return "%s presents outstanding contractual, legal, and contingent matters existing at the reporting date." % note_label
		"risk_management":
			return "%s explains the risk framework applied to financial instruments, exposures, and operating commitments." % note_label
		"subsequent_events":
			return "%s presents non-cash activity and events identified after the reporting date but before authorization." % note_label
	return "%s provides the related note context for the consolidated statement account." % note_label


static func _section_specific_table_label(section_id: String, template_type: String, line_label: String) -> String:
	match template_type:
		"bank_cash_reserves":
			return "The banking asset table"
		"bank_loans":
			return "The credit exposure table"
		"bank_funding":
			return "The funding table"
		"bank_capital":
			return "The regulatory capital table"
		"bank_credit_risk":
			return "The credit-risk table"
		"bank_liquidity_risk":
			return "The maturity table"
		"bank_regulatory":
			return "The regulatory compliance table"
		"segment":
			return "The segment table"
		"risk_management":
			return "The risk table"
		"related_party":
			return "The related-party table"
	if section_id.contains("inventory"):
		return "The inventory table"
	if section_id.contains("receivable"):
		return "The receivables table"
	if section_id.contains("borrow"):
		return "The financing table"
	if line_label.strip_edges().is_empty():
		return "The note table"
	return "The note table"


static func _section_specific_cross_note_context(section_id: String, template_type: String, note_label: String) -> String:
	match template_type:
		"bank_cash_reserves":
			return "Liquidity rows also depend on the related funding, marketable securities, and risk disclosures elsewhere in the banking notes."
		"bank_loans":
			return "Loan balances connect to impairment allowance, credit-risk quality, interest income, and related-party banking disclosures."
		"bank_funding":
			return "Funding balances connect to liquidity maturity, interest expense, related-party deposits, and regulatory reserve disclosures."
		"bank_capital":
			return "Capital adequacy connects regulatory capital to credit exposure, risk-weighted assets, and prudential compliance notes."
		"bank_credit_risk":
			return "Credit-risk rows connect loan staging, allowance coverage, collateral monitoring, and sector concentration disclosures."
		"bank_liquidity_risk":
			return "Liquidity-risk rows connect deposit maturity, placements, securities, and statutory reserve disclosures."
		"bank_regulatory":
			return "Regulatory compliance rows connect reserve balances, liquidity buffers, capital adequacy, and post-reporting-date prudential matters."
		"segment":
			return "Segment rows connect operating results to revenue, cost, asset, and commitment disclosures."
		"related_party":
			return "Related-party rows connect balances and transactions to receivable, payable, financing, and commitment disclosures."
		"risk_management":
			return "Risk rows connect financial assets, borrowings, commitments, and sensitivity disclosures."
	if not note_label.strip_edges().is_empty():
		return "Cross-note references connect %s with related statement rows and schedules." % note_label
	return "Cross-note references connect related statement rows and schedules."


static func _first_line_for_footprint(footprint: Dictionary, line_lookup: Dictionary) -> Dictionary:
	for metric_value in _variant_array(footprint.get("statement_metric_ids", [])):
		var metric_id: String = str(metric_value).strip_edges()
		if line_lookup.has(metric_id):
			return line_lookup.get(metric_id, {})
	for metric_value in _variant_array(footprint.get("metric_ids", [])):
		var metric_id: String = _statement_metric_for_packet_metric(str(metric_value))
		if line_lookup.has(metric_id):
			return line_lookup.get(metric_id, {})
	return {}


static func _line_amount_text(line: Dictionary, annual_statement: Dictionary) -> String:
	if line.is_empty():
		return "the amount shown in the statement"
	return _amount_label(float(line.get("value", 0.0)), str(line.get("format", "currency")), annual_statement)


static func _amount_label(value: float, format_id: String, annual_statement: Dictionary) -> String:
	match format_id:
		"ratio":
			return "%.2f" % value
		"shares":
			return "%s shares" % _format_number(value)
	var abs_value: float = absf(value)
	var sign: String = "-" if value < 0.0 else ""
	var display_value: float = abs_value
	if _display_currency_amounts_in_millions(format_id, annual_statement):
		display_value = abs_value / 1000000.0
		return "%s%s" % [sign, _format_number(display_value)]
	if format_id == "currency":
		return _compact_currency_amount_label(value)
	return "%s%s" % [sign, _format_number(display_value)]


static func _compact_currency_amount_label(value: float) -> String:
	var abs_value: float = absf(value)
	var sign: String = "-" if value < 0.0 else ""
	var display_value: float = abs_value
	var suffix: String = ""
	if abs_value >= 1000000000000.0:
		display_value = abs_value / 1000000000000.0
		suffix = "t"
	elif abs_value >= 1000000000.0:
		display_value = abs_value / 1000000000.0
		suffix = "b"
	elif abs_value >= 1000000.0:
		display_value = abs_value / 1000000.0
		suffix = "m"
	if suffix.is_empty():
		return "%s%s" % [sign, _format_number(display_value)]
	if display_value >= 100.0:
		return "%s%s%s" % [sign, _format_number(round(display_value)), suffix]
	return "%s%.1f%s" % [sign, display_value, suffix]


static func _display_currency_amounts_in_millions(format_id: String, annual_statement: Dictionary) -> bool:
	if format_id != "currency":
		return false
	var unit: String = str(annual_statement.get("unit", "")).strip_edges().to_lower()
	if unit == "million_idr":
		return true
	return false


static func _format_number(value: float) -> String:
	var snap_step: float = 0.1 if absf(value) < 100000.0 else 1.0
	var rounded: float = snappedf(value, snap_step)
	var text: String = ""
	if absf(rounded - round(rounded)) < 0.05:
		text = str(int(round(rounded)))
	else:
		text = "%.1f" % rounded
	var decimal_part: String = ""
	var dot_index: int = text.find(".")
	if dot_index >= 0:
		decimal_part = text.substr(dot_index)
		text = text.substr(0, dot_index)
	var groups: Array[String] = []
	while text.length() > 3:
		groups.push_front(text.substr(text.length() - 3, 3))
		text = text.substr(0, text.length() - 3)
	if not text.is_empty():
		groups.push_front(text)
	return ",".join(groups) + decimal_part


static func _note_label(note_type: String, note_lookup: Dictionary) -> String:
	if note_lookup.has(note_type):
		var note: Dictionary = note_lookup.get(note_type, {})
		var title: String = str(note.get("title", "")).strip_edges()
		if not title.is_empty():
			var note_number: int = int(note.get("note_number", 0))
			return "Note %d - %s" % [note_number, title] if note_number > 0 else title
	if note_type.strip_edges().is_empty():
		return "the related note"
	return note_type.replace("_", " ").capitalize()


static func _sector_style_vocabulary(sector_style_id: String) -> Dictionary:
	var style_id: String = _resolved_sector_style_id(sector_style_id)
	return SECTOR_STYLE_VOCABULARY.get(style_id, SECTOR_STYLE_VOCABULARY.get(DEFAULT_SECTOR_STYLE_ID, {})).duplicate(true)


static func _sector_style_id_for_profile(filing_profile_id: String, sector_style_id: String) -> String:
	var safe_profile_id: String = _resolved_filing_profile_id(filing_profile_id)
	if safe_profile_id == "bank":
		return "bank_annual_filing"
	return _resolved_sector_style_id(sector_style_id)


static func _resolved_sector_style_id(sector_style_id: String) -> String:
	var style_id: String = sector_style_id.strip_edges()
	if style_id.is_empty():
		return DEFAULT_SECTOR_STYLE_ID
	if SECTOR_STYLE_VOCABULARY.has(style_id):
		return style_id
	match style_id:
		"finance", "bank", "banking":
			return "bank_annual_filing"
		"energy", "industrial", "infrastructure", "logistics", "materials":
			return "trading_logistics_industrial_estate"
	return DEFAULT_SECTOR_STYLE_ID


static func _resolved_filing_profile_id(profile_id: String) -> String:
	var safe_profile_id: String = profile_id.strip_edges()
	if safe_profile_id.is_empty() or not FILING_PROFILE_DEFINITIONS.has(safe_profile_id):
		return DEFAULT_FILING_PROFILE_ID
	return safe_profile_id


static func _filing_profile_id_from_schema(schema_rows: Array) -> String:
	for row_value in schema_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var profile_id: String = str(row.get("filing_profile_id", "")).strip_edges()
		if not profile_id.is_empty():
			return _resolved_filing_profile_id(profile_id)
	return DEFAULT_FILING_PROFILE_ID


static func _filing_profile_context(annual_statement: Dictionary, options: Dictionary) -> Dictionary:
	var sector_id: String = str(options.get("sector_id", options.get("sector", ""))).strip_edges()
	if sector_id.is_empty():
		sector_id = str(options.get("sector_style_id", annual_statement.get("sector_id", annual_statement.get("sector", "")))).strip_edges()
	var subsector_id: String = str(options.get("subsector_id", options.get("subsector", annual_statement.get("subsector_id", annual_statement.get("subsector", ""))))).strip_edges()
	var company_id: String = str(options.get("company_id", annual_statement.get("company_id", ""))).strip_edges()
	var ticker: String = str(options.get("ticker", annual_statement.get("ticker", ""))).strip_edges()
	var company_name: String = str(options.get("company_name", annual_statement.get("company_name", ""))).strip_edges()
	var business_summary: String = str(options.get("business_summary", annual_statement.get("business_summary", ""))).strip_edges()
	var story_text: String = " ".join(_string_array(options.get("story_hooks", annual_statement.get("story_hooks", []))))
	var moat_text: String = " ".join(_string_array(options.get("moat_tags", annual_statement.get("moat_tags", []))))
	var business_text: String = " ".join([
		company_id,
		ticker,
		company_name,
		sector_id,
		subsector_id,
		business_summary,
		story_text
	])
	return {
		"company_id": company_id,
		"ticker": ticker,
		"company_name": company_name,
		"sector_id": sector_id.to_lower(),
		"subsector_id": subsector_id.to_lower(),
		"business_text": business_text.to_lower(),
		"moat_text": moat_text.to_lower(),
		"has_sector_context": not sector_id.is_empty(),
		"has_subsector_context": not subsector_id.is_empty()
	}


static func _context_matches_filing_profile(profile_id: String, sector_id: String, subsector_id: String, business_text: String, moat_text: String) -> bool:
	var definition: Dictionary = filing_profile_definition(profile_id)
	var sector_ids: Array = _string_array(definition.get("sector_ids", []))
	if not sector_ids.is_empty() and not sector_ids.has(sector_id):
		return false
	var subsector_terms: Array = _string_array(definition.get("subsector_terms", []))
	if _text_matches_any_term(subsector_id, subsector_terms):
		return true
	var business_terms: Array = _string_array(definition.get("business_terms", []))
	if _text_matches_any_term(business_text, business_terms):
		return true
	var moat_terms: Array = _string_array(definition.get("moat_terms", []))
	if _text_matches_any_term(moat_text, moat_terms):
		return true
	return profile_id == "industrial_trading" and sector_ids.has(sector_id)


static func _filing_profile_selection_row(profile_id: String, selection_reason: String, context: Dictionary) -> Dictionary:
	var definition: Dictionary = filing_profile_definition(profile_id)
	definition["selection_reason"] = selection_reason
	definition["selection_context"] = {
		"company_id": str(context.get("company_id", "")),
		"ticker": str(context.get("ticker", "")),
		"sector_id": str(context.get("sector_id", "")),
		"subsector_id": str(context.get("subsector_id", "")),
		"has_sector_context": bool(context.get("has_sector_context", false)),
		"has_subsector_context": bool(context.get("has_subsector_context", false))
	}
	return definition


static func _story_note_fact_default_value(field_id: String) -> Variant:
	match field_id:
		"term_months":
			return 0
		"amount":
			return 0.0
		"source_ids":
			return []
	return ""


static func _story_note_fact_contract_payload() -> String:
	var lines: Array[String] = []
	lines.append("schema_version=%d" % STORY_NOTE_FACT_SCHEMA_VERSION)
	lines.append("status=%s" % STORY_NOTE_FACT_STATUS)
	var required_fields: Array = STORY_NOTE_FACT_REQUIRED_FIELDS.duplicate(true)
	required_fields.sort()
	lines.append("required_fields=%s" % "|".join(required_fields))
	var container_ids: Array = STORY_NOTE_FACT_CONTAINER_DEFINITIONS.keys()
	container_ids.sort()
	for container_value in container_ids:
		var container_id: String = str(container_value)
		var definition: Dictionary = STORY_NOTE_FACT_CONTAINER_DEFINITIONS.get(container_id, {})
		lines.append("container=%s:%s:%s" % [
			container_id,
			str(definition.get("label", "")),
			str(definition.get("purpose", ""))
		])
	var profile_ids: Array = STORY_NOTE_FACT_PROFILE_CONTAINER_ALLOWLISTS.keys()
	profile_ids.sort()
	for profile_value in profile_ids:
		var profile_id: String = str(profile_value)
		var allowed_containers: Array = _string_array(STORY_NOTE_FACT_PROFILE_CONTAINER_ALLOWLISTS.get(profile_id, []))
		allowed_containers.sort()
		lines.append("profile_allowlist=%s:%s" % [profile_id, "|".join(allowed_containers)])
	var story_type_ids: Array = STORY_NOTE_FACT_STORY_TYPE_DEFINITIONS.keys()
	story_type_ids.sort()
	for story_type_value in story_type_ids:
		var story_type: String = str(story_type_value)
		var definition: Dictionary = STORY_NOTE_FACT_STORY_TYPE_DEFINITIONS.get(story_type, {})
		var allowed_note_containers: Array = _string_array(definition.get("allowed_note_containers", []))
		allowed_note_containers.sort()
		lines.append("story_type=%s:%s:%s:%s:%s:%s" % [
			story_type,
			str(definition.get("label", "")),
			"|".join(allowed_note_containers),
			str(bool(definition.get("requires_counterparty", false))),
			str(bool(definition.get("requires_term", false))),
			str(bool(definition.get("requires_amount", false)))
		])
	return "\n".join(lines)


static func _story_note_facts_from_dossiers(
	company_definition: Dictionary,
	annual_statement: Dictionary,
	source_context: Dictionary,
	options: Dictionary,
	profile_id: String
) -> Array:
	var company_id: String = _story_note_company_id(company_definition, annual_statement, options)
	var rows: Array = []
	for dossier_value in _story_note_context_rows(source_context, ["company_dossiers", "dossiers", "story_dossiers"]):
		if typeof(dossier_value) != TYPE_DICTIONARY:
			continue
		var dossier: Dictionary = dossier_value
		if str(dossier.get("company_id", "")).strip_edges() != company_id:
			continue
		var packets: Array = _variant_array(dossier.get("disclosure_packets", []))
		if packets.is_empty():
			continue
		var packet_limit: int = min(3, packets.size())
		for packet_index in range(packet_limit):
			if typeof(packets[packet_index]) != TYPE_DICTIONARY:
				continue
			var packet: Dictionary = packets[packet_index]
			var story_type: String = _story_note_story_type_from_dossier(dossier, packet)
			var note_container: String = _story_note_container_for_section(story_type, str(packet.get("section_id", "")), profile_id)
			if story_type.is_empty() or note_container.is_empty():
				continue
			var counterparty: Dictionary = _story_note_counterparty_for_company(company_id, source_context)
			if _story_note_story_type_requires(story_type, "requires_counterparty") and counterparty.is_empty():
				continue
			rows.append(_story_note_fact_from_parts(
				"story_fact|dossier|%s|%s" % [company_id, _cache_token(str(packet.get("packet_id", packet_index)))],
				company_id,
				story_type,
				note_container,
				counterparty,
				_story_note_agreement_type_for_story(story_type, str(dossier.get("archetype_id", ""))),
				_story_note_effective_date(packet, annual_statement, options),
				_story_note_term_months(story_type, packet),
				_story_note_term_text(story_type, packet),
				_story_note_amount_for_fact(story_type, annual_statement, packet, company_definition, options),
				_story_note_currency(annual_statement, packet),
				"company_story_dossier",
				_story_note_source_ids(packet, [
					str(dossier.get("story_id", "")),
					str(packet.get("packet_id", "")),
					str(packet.get("placement_id", ""))
				]),
				STORY_NOTE_FACT_PACKET_VISIBILITY_LEVEL,
				STORY_NOTE_FACT_PACKET_CAPTURE_GROUP
			))
	return rows


static func _story_note_facts_from_relationship_edges(
	company_definition: Dictionary,
	annual_statement: Dictionary,
	source_context: Dictionary,
	options: Dictionary,
	profile_id: String
) -> Array:
	var company_id: String = _story_note_company_id(company_definition, annual_statement, options)
	var rows: Array = []
	for edge_value in _story_note_context_rows(source_context, ["relationship_edges", "relationship_graph_edges", "edges"]):
		if typeof(edge_value) != TYPE_DICTIONARY:
			continue
		var edge: Dictionary = edge_value
		var source_company_id: String = str(edge.get("source_company_id", "")).strip_edges()
		var target_company_id: String = str(edge.get("target_company_id", "")).strip_edges()
		if source_company_id != company_id and target_company_id != company_id:
			continue
		var relationship_type: String = str(edge.get("relationship_type", "")).strip_edges()
		var story_type: String = _story_note_story_type_from_relationship(relationship_type)
		if story_type.is_empty():
			continue
		var note_container: String = _story_note_container_for_relationship(story_type, relationship_type, profile_id)
		if note_container.is_empty():
			continue
		var counterparty: Dictionary = _story_note_counterparty_from_edge(company_id, edge, source_context)
		if _story_note_story_type_requires(story_type, "requires_counterparty") and counterparty.is_empty():
			continue
		rows.append(_story_note_fact_from_parts(
			"story_fact|relationship_edge|%s|%s" % [company_id, _cache_token(str(edge.get("edge_id", relationship_type)))],
			company_id,
			story_type,
			note_container,
			counterparty,
			_story_note_agreement_type_for_relationship(relationship_type),
			_story_note_effective_date(edge, annual_statement, options),
			_story_note_term_months(story_type, edge),
			_story_note_term_text(story_type, edge),
			_story_note_amount_for_fact(story_type, annual_statement, edge, company_definition, options),
			_story_note_currency(annual_statement, edge),
			"company_relationship_graph",
			_story_note_source_ids(edge, [str(edge.get("edge_id", ""))]),
			STORY_NOTE_FACT_PACKET_VISIBILITY_LEVEL,
			STORY_NOTE_FACT_PACKET_CAPTURE_GROUP
		))
	return rows


static func _story_note_facts_from_relationship_events(
	company_definition: Dictionary,
	annual_statement: Dictionary,
	source_context: Dictionary,
	options: Dictionary,
	profile_id: String
) -> Array:
	var company_id: String = _story_note_company_id(company_definition, annual_statement, options)
	var rows: Array = []
	for event_value in _story_note_context_rows(source_context, ["relationship_events", "relationship_graph_events"]):
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_value
		if str(event.get("target_company_id", event.get("company_id", ""))).strip_edges() != company_id:
			continue
		var relationship_type: String = str(event.get("relationship_type", "")).strip_edges()
		var story_type: String = _story_note_story_type_from_relationship(relationship_type)
		if story_type.is_empty():
			story_type = "subsequent_event"
		var note_container: String = _story_note_container_for_relationship(story_type, relationship_type, profile_id)
		if note_container.is_empty():
			note_container = _story_note_first_allowed_container(story_type, ["subsequent_events"], profile_id)
		if note_container.is_empty():
			continue
		var counterparty: Dictionary = _story_note_counterparty_from_event(event)
		if _story_note_story_type_requires(story_type, "requires_counterparty") and counterparty.is_empty():
			continue
		rows.append(_story_note_fact_from_parts(
			"story_fact|relationship_event|%s|%s" % [company_id, _cache_token(str(event.get("relationship_event_id", event.get("arc_id", ""))))],
			company_id,
			story_type,
			note_container,
			counterparty,
			_story_note_agreement_type_for_relationship(relationship_type),
			_story_note_effective_date(event, annual_statement, options),
			_story_note_term_months(story_type, event),
			_story_note_term_text(story_type, event),
			_story_note_amount_for_fact(story_type, annual_statement, event, company_definition, options),
			_story_note_currency(annual_statement, event),
			"company_relationship_graph",
			_story_note_source_ids(event, [
				str(event.get("relationship_event_id", "")),
				str(event.get("relationship_edge_id", "")),
				str(event.get("arc_id", ""))
			]),
			STORY_NOTE_FACT_PACKET_VISIBILITY_LEVEL,
			STORY_NOTE_FACT_PACKET_CAPTURE_GROUP
		))
	return rows


static func _story_note_facts_from_annual_statement(
	company_definition: Dictionary,
	annual_statement: Dictionary,
	source_context: Dictionary,
	options: Dictionary,
	profile_id: String
) -> Array:
	var company_id: String = _story_note_company_id(company_definition, annual_statement, options)
	var rows: Array = []
	for note_value in _variant_array(annual_statement.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		var source_ids: Array = _story_note_source_ids(note, [str(note.get("note_id", ""))])
		if source_ids.is_empty():
			continue
		var note_type: String = str(note.get("note_type", "")).strip_edges()
		var story_type: String = _story_note_story_type_from_note_type(note_type)
		if story_type.is_empty():
			continue
		var note_container: String = _story_note_container_for_note_type(story_type, note_type, profile_id)
		if note_container.is_empty():
			continue
		var counterparty: Dictionary = _story_note_counterparty_for_company(company_id, source_context)
		if _story_note_story_type_requires(story_type, "requires_counterparty") and counterparty.is_empty():
			continue
		rows.append(_story_note_fact_from_parts(
			"story_fact|annual_statement|%s|%s" % [company_id, _cache_token(str(note.get("note_id", note_type)))],
			company_id,
			story_type,
			note_container,
			counterparty,
			_story_note_agreement_type_for_story(story_type, note_type),
			_story_note_effective_date(note, annual_statement, options),
			_story_note_term_months(story_type, note),
			_story_note_term_text(story_type, note),
			_story_note_amount_for_fact(story_type, annual_statement, note, company_definition, options),
			_story_note_currency(annual_statement, note),
			"annual_statement_builder",
			source_ids,
			STORY_NOTE_FACT_PACKET_VISIBILITY_LEVEL,
			STORY_NOTE_FACT_PACKET_CAPTURE_GROUP
		))
	return rows


static func _story_note_facts_from_runtime_rows(
	company_definition: Dictionary,
	annual_statement: Dictionary,
	source_context: Dictionary,
	options: Dictionary,
	profile_id: String
) -> Array:
	var company_id: String = _story_note_company_id(company_definition, annual_statement, options)
	var rows: Array = []
	var runtime_sources: Array = [
		["active_company_arcs", "living_company_arc"],
		["corporate_action_events", "corporate_action"],
		["roadmap_milestones", "company_roadmap"],
		["company_events", "company_event"],
		["event_history", "event_history"]
	]
	for source_spec in runtime_sources:
		var context_key: String = str(source_spec[0])
		var source_system: String = str(source_spec[1])
		for row_value in _story_note_context_rows(source_context, [context_key]):
			if typeof(row_value) != TYPE_DICTIONARY:
				continue
			var row: Dictionary = row_value
			if not _story_note_runtime_row_matches_company(row, company_id):
				continue
			var story_type: String = _story_note_story_type_from_runtime_row(row, source_system)
			var note_container: String = _story_note_first_allowed_container(story_type, ["subsequent_events", "project_construction", "commitments_contingencies"], profile_id)
			if story_type.is_empty() or note_container.is_empty():
				continue
			var counterparty: Dictionary = _story_note_counterparty_from_event(row)
			if _story_note_story_type_requires(story_type, "requires_counterparty") and counterparty.is_empty():
				continue
			rows.append(_story_note_fact_from_parts(
				"story_fact|%s|%s|%s" % [source_system, company_id, _cache_token(_story_note_row_id(row))],
				company_id,
				story_type,
				note_container,
				counterparty,
				_story_note_agreement_type_for_story(story_type, str(row.get("category", row.get("event_id", "")))),
				_story_note_effective_date(row, annual_statement, options),
				_story_note_term_months(story_type, row),
				_story_note_term_text(story_type, row),
				_story_note_amount_for_fact(story_type, annual_statement, row, company_definition, options),
				_story_note_currency(annual_statement, row),
				source_system,
				_story_note_source_ids(row, [_story_note_row_id(row)]),
				STORY_NOTE_FACT_PACKET_VISIBILITY_LEVEL,
				STORY_NOTE_FACT_PACKET_CAPTURE_GROUP
			))
	return rows


static func _story_note_fallback_facts_from_company_metadata(
	company_definition: Dictionary,
	annual_statement: Dictionary,
	source_context: Dictionary,
	options: Dictionary,
	profile_id: String,
	needed_count: int
) -> Array:
	var rows: Array = []
	if needed_count <= 0:
		return rows
	var company_id: String = _story_note_company_id(company_definition, annual_statement, options)
	for hook_value in _variant_array(company_definition.get("relationship_hooks", [])):
		if rows.size() >= needed_count or typeof(hook_value) != TYPE_DICTIONARY:
			continue
		var hook: Dictionary = hook_value
		var relationship_type: String = str(hook.get("type", "")).strip_edges()
		var story_type: String = _story_note_story_type_from_relationship(relationship_type)
		if story_type.is_empty():
			continue
		var note_container: String = _story_note_container_for_relationship(story_type, relationship_type, profile_id)
		if note_container.is_empty():
			continue
		var target_sector: String = str(hook.get("target_sector", "counterparty")).strip_edges()
		var counterparty: Dictionary = {
			"counterparty_id": "catalog_counterparty|%s|%s|%s" % [company_id, relationship_type, target_sector],
			"counterparty_name": "%s counterparty" % _story_note_title_case(target_sector)
		}
		rows.append(_story_note_fact_from_parts(
			"story_fact|company_universe|%s|relationship_hook|%s|%s" % [company_id, _cache_token(relationship_type), rows.size()],
			company_id,
			story_type,
			note_container,
			counterparty,
			_story_note_agreement_type_for_relationship(relationship_type),
			_story_note_effective_date(hook, annual_statement, options),
			_story_note_term_months(story_type, hook),
			_story_note_term_text(story_type, hook),
			_story_note_amount_for_fact(story_type, annual_statement, hook, company_definition, options),
			_story_note_currency(annual_statement, hook),
			"company_universe_catalog",
			["company_universe|%s|relationship_hook|%s|%s" % [company_id, _cache_token(relationship_type), _cache_token(target_sector)]],
			STORY_NOTE_FACT_PACKET_VISIBILITY_LEVEL,
			STORY_NOTE_FACT_PACKET_CAPTURE_GROUP
		))

	for hook_value in _string_array(company_definition.get("story_hooks", [])):
		if rows.size() >= needed_count:
			continue
		var hook: String = str(hook_value).strip_edges()
		var story_type: String = _story_note_story_type_from_catalog_hook(hook, profile_id)
		if story_type.is_empty():
			continue
		var note_container: String = _story_note_container_for_catalog_hook(story_type, hook, profile_id)
		if note_container.is_empty():
			continue
		var counterparty: Dictionary = _story_note_counterparty_for_catalog_hook(company_id, hook, story_type)
		if _story_note_story_type_requires(story_type, "requires_counterparty") and counterparty.is_empty():
			continue
		rows.append(_story_note_fact_from_parts(
			"story_fact|company_universe|%s|story_hook|%s" % [company_id, _cache_token(hook)],
			company_id,
			story_type,
			note_container,
			counterparty,
			_story_note_agreement_type_for_story(story_type, hook),
			_story_note_effective_date({"source_id": hook}, annual_statement, options),
			_story_note_term_months(story_type, {"source_id": hook}),
			_story_note_term_text(story_type, {"source_id": hook}),
			_story_note_amount_for_fact(story_type, annual_statement, {"source_id": hook}, company_definition, options),
			_story_note_currency(annual_statement, {}),
			"company_universe_catalog",
			["company_universe|%s|story_hook|%s" % [company_id, _cache_token(hook)]],
			STORY_NOTE_FACT_PACKET_VISIBILITY_LEVEL,
			STORY_NOTE_FACT_PACKET_CAPTURE_GROUP
		))

	if rows.size() < needed_count:
		var exposure_fact: Dictionary = _story_note_commodity_exposure_fallback(company_definition, annual_statement, options, profile_id)
		if not exposure_fact.is_empty():
			rows.append(exposure_fact)
	if rows.size() < needed_count:
		rows.append(_story_note_business_summary_fallback(company_definition, annual_statement, options, profile_id))
	return rows


static func _story_note_fact_from_parts(
	fact_id: String,
	company_id: String,
	story_type: String,
	note_container: String,
	counterparty: Dictionary,
	agreement_type: String,
	effective_date: String,
	term_months: int,
	term_text: String,
	amount: float,
	currency: String,
	source_system: String,
	source_ids: Array,
	visibility_level: String,
	capture_group: String
) -> Dictionary:
	return normalize_story_note_fact({
		"fact_id": fact_id,
		"company_id": company_id,
		"story_type": story_type,
		"note_container": note_container,
		"counterparty_id": str(counterparty.get("counterparty_id", "")),
		"counterparty_name": str(counterparty.get("counterparty_name", "")),
		"agreement_type": agreement_type,
		"effective_date": effective_date,
		"term_months": term_months,
		"term_text": term_text,
		"amount": amount,
		"currency": currency,
		"source_system": source_system,
		"source_ids": source_ids,
		"visibility_level": visibility_level,
		"capture_group": capture_group
	})


static func _story_note_append_valid_facts(source_rows: Array, candidate_rows: Array, profile_id: String) -> Array:
	var rows: Array = source_rows.duplicate(true)
	for candidate_value in candidate_rows:
		if typeof(candidate_value) != TYPE_DICTIONARY:
			continue
		var fact: Dictionary = normalize_story_note_fact(candidate_value)
		if validate_story_note_fact(fact, profile_id).is_empty():
			rows.append(fact)
	return rows


static func _story_note_unique_sorted_facts(source_rows: Array) -> Array:
	var by_id: Dictionary = {}
	for row_value in source_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = normalize_story_note_fact(row_value)
		var fact_id: String = str(row.get("fact_id", "")).strip_edges()
		if fact_id.is_empty() or by_id.has(fact_id):
			continue
		by_id[fact_id] = row
	var fact_ids: Array = by_id.keys()
	fact_ids.sort()
	var rows: Array = []
	for fact_id in fact_ids:
		rows.append(by_id.get(fact_id, {}).duplicate(true))
	return rows


static func _story_note_fact_packet_payload(packets: Array) -> String:
	var lines: Array[String] = []
	lines.append("schema_version=%d" % STORY_NOTE_FACT_PACKET_SCHEMA_VERSION)
	lines.append("status=%s" % STORY_NOTE_FACT_PACKET_STATUS)
	for packet_value in _story_note_unique_sorted_facts(packets):
		if typeof(packet_value) != TYPE_DICTIONARY:
			continue
		var packet: Dictionary = packet_value
		var fields: Array[String] = []
		for field_value in STORY_NOTE_FACT_REQUIRED_FIELDS:
			var field_id: String = str(field_value)
			var field_text: String = "|".join(_string_array(packet.get(field_id, []))) if field_id == "source_ids" else str(packet.get(field_id, ""))
			fields.append("%s=%s" % [field_id, field_text])
		lines.append(";".join(fields))
	return "\n".join(lines)


static func _story_note_placement_plan_payload(plan: Array) -> String:
	var lines: Array[String] = []
	lines.append("schema_version=%d" % STORY_NOTE_PLACEMENT_SCHEMA_VERSION)
	lines.append("status=%s" % STORY_NOTE_PLACEMENT_STATUS)
	for row_value in plan:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var fact: Dictionary = row.get("fact", {}) if typeof(row.get("fact", {})) == TYPE_DICTIONARY else {}
		lines.append("%d:%s:%s:%s:%s:%s:%s:%s:%s" % [
			int(row.get("placement_order", 0)),
			str(row.get("placement_id", "")),
			str(row.get("placement_role", "")),
			str(row.get("paragraph_role", "")),
			str(row.get("filing_section_id", "")),
			str(row.get("story_type", "")),
			str(row.get("note_container", "")),
			_array_payload(row.get("source_story_note_fact_ids", [])),
			str(fact.get("fact_id", ""))
		])
	return "\n".join(lines)


static func _story_note_prose_payload(packets: Array) -> String:
	var lines: Array[String] = []
	lines.append("schema_version=%d" % STORY_NOTE_PROSE_SCHEMA_VERSION)
	lines.append("status=%s" % STORY_NOTE_PROSE_STATUS)
	for row_value in packets:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("%d:%s:%s:%s:%s:%s:%s:%s:%s" % [
			int(row.get("paragraph_order", 0)),
			str(row.get("paragraph_id", "")),
			str(row.get("filing_section_id", "")),
			str(row.get("template_type", "")),
			str(row.get("paragraph_role", "")),
			str(row.get("clue_density", "")),
			str(row.get("boilerplate_density", "")),
			_array_payload(row.get("source_story_note_fact_ids", [])),
			str(row.get("visible_text", ""))
		])
	return "\n".join(lines)


static func _story_note_prose_row(
	row_index: int,
	section_id: String,
	fact: Dictionary,
	visible_text: String,
	filing_section_schema: Array,
	options: Dictionary,
	placement: Dictionary = {}
) -> Dictionary:
	var safe_section_id: String = section_id.strip_edges()
	var text: String = visible_text.strip_edges()
	if safe_section_id.is_empty() or text.is_empty():
		return {}
	var section: Dictionary = _filing_section_by_id(filing_section_schema, safe_section_id)
	var fact_id: String = str(fact.get("fact_id", "")).strip_edges()
	var paragraph_role: String = str(placement.get("paragraph_role", _story_note_paragraph_role(fact))).strip_edges()
	if not STORY_NOTE_PROSE_ROLES.has(paragraph_role):
		paragraph_role = _story_note_paragraph_role(fact)
	var placement_role: String = str(placement.get("placement_role", "primary_note")).strip_edges()
	if not STORY_NOTE_PLACEMENT_ROLES.has(placement_role):
		placement_role = "primary_note"
	var placement_id: String = str(placement.get("placement_id", "")).strip_edges()
	return {
		"schema_version": STORY_NOTE_PROSE_SCHEMA_VERSION,
		"prose_status": STORY_NOTE_PROSE_STATUS,
		"paragraph_id": "story_note_prose|%s|%03d" % [safe_section_id, row_index],
		"paragraph_order": -1000 + row_index,
		"filing_section_id": safe_section_id,
		"section_order": int(section.get("section_order", 0)),
		"section_title": str(section.get("filing_title", "")),
		"template_type": "story_note_%s_%s" % [str(fact.get("story_type", "")), placement_role],
		"paragraph_role": paragraph_role,
		"clue_density": "high" if paragraph_role != "policy_noise" else "low",
		"boilerplate_density": "low",
		"visible_text": text,
		"visible_truth_labels_allowed": false,
		"hidden_source_ids_visible": false,
		"sector_style_id": str(options.get("sector_style_id", DEFAULT_SECTOR_STYLE_ID)),
		"source_footprint_ids": [],
		"source_disclosure_packet_ids": _story_note_source_ids_by_prefix(fact, "packet|"),
		"source_disclosure_placement_ids": _story_note_source_ids_by_prefix(fact, "placement|"),
		"source_story_ids": _story_note_source_ids_by_prefix(fact, "story|"),
		"source_story_note_placement_ids": [placement_id] if not placement_id.is_empty() else [],
		"story_note_placement_role": placement_role,
		"source_story_note_fact_ids": [fact_id] if not fact_id.is_empty() else [],
		"statement_line_ids": [],
		"statement_metric_ids": [],
		"metric_ids": [],
		"note_ids": [],
		"note_type": str(fact.get("note_container", "")),
		"footprint_type": "story_note_fact",
		"story_exposure": "filing_note",
		"traceability_mode": "internal_source_ids_only"
	}


static func _story_note_filing_section_id(fact: Dictionary, profile_id: String, filing_section_schema: Array) -> String:
	var note_container: String = str(fact.get("note_container", "")).strip_edges()
	var story_type: String = str(fact.get("story_type", "")).strip_edges()
	var candidates: Array = []
	if _resolved_filing_profile_id(profile_id) == "bank":
		match note_container:
			"bank_facilities_guarantees":
				candidates = ["note_bank_loans_financing", "note_bank_liquidity_risk", "note_bank_credit_risk"]
			"commitments_contingencies":
				candidates = ["note_bank_liquidity_risk", "note_bank_credit_risk", "note_bank_regulatory_compliance"]
			"segment_operations", "customers_suppliers", "government_pricing_subsidies":
				candidates = ["note_bank_interest_income", "note_bank_loans_financing", "note_bank_credit_risk"]
			"subsidiaries_leases":
				candidates = ["note_bank_company_information", "note_bank_loans_financing"]
			"related_parties":
				candidates = ["note_bank_related_parties"]
			"subsequent_events":
				candidates = ["note_bank_regulatory_compliance", "note_bank_company_information"]
			"accounting_policies":
				candidates = ["note_bank_accounting_policies"]
			_:
				candidates = ["note_bank_company_information", "note_bank_loans_financing"]
	else:
		match note_container:
			"significant_agreements", "customers_suppliers":
				candidates = ["note_commitments_contingencies", "note_segment_information", "note_revenue_expenses_tax_equity"]
			"commitments_contingencies":
				candidates = ["note_commitments_contingencies", "note_liabilities_borrowings"]
			"bank_facilities_guarantees":
				candidates = ["note_liabilities_borrowings", "note_commitments_contingencies", "note_financial_risk_management"]
			"segment_operations":
				candidates = ["note_segment_information", "note_revenue_expenses_tax_equity"]
			"government_pricing_subsidies":
				candidates = ["note_revenue_expenses_tax_equity", "note_segment_information"]
			"subsidiaries_leases", "project_construction":
				candidates = ["note_ppe_investments", "note_commitments_contingencies", "note_segment_information"]
			"related_parties":
				candidates = ["note_related_parties"]
			"subsequent_events":
				candidates = ["note_non_cash_subsequent_events", "note_commitments_contingencies"]
			"accounting_policies":
				candidates = ["note_accounting_policies"]
			_:
				candidates = ["note_segment_information", "note_commitments_contingencies"]
	if story_type == "bank_guarantee" and not candidates.has("note_commitments_contingencies"):
		candidates.push_front("note_commitments_contingencies")
	for candidate_value in candidates:
		var candidate_id: String = str(candidate_value).strip_edges()
		if _filing_schema_has_section(filing_section_schema, candidate_id):
			return candidate_id
	for section_value in filing_section_schema:
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		if str(section.get("document_part", "")).strip_edges() == "notes":
			return str(section.get("section_id", "")).strip_edges()
	return ""


static func _story_note_placements_for_fact(
	fact: Dictionary,
	annual_statement: Dictionary,
	filing_section_schema: Array,
	profile_id: String,
	options: Dictionary
) -> Array:
	var rows: Array = []
	var primary_section_id: String = _story_note_filing_section_id(fact, profile_id, filing_section_schema)
	if primary_section_id.is_empty():
		return rows
	rows.append(_story_note_placement_row(fact, "primary_note", primary_section_id, profile_id, rows.size() + 1))
	if not _story_note_fact_is_material(fact):
		return rows
	var used_sections: Array = [primary_section_id]
	var secondary_section_id: String = _story_note_first_existing_section(
		_story_note_secondary_section_candidates(fact, primary_section_id, profile_id),
		filing_section_schema,
		used_sections
	)
	if not secondary_section_id.is_empty():
		rows.append(_story_note_placement_row(fact, "secondary_note", secondary_section_id, profile_id, rows.size() + 1))
		used_sections.append(secondary_section_id)
	var echo_section_id: String = _story_note_first_existing_section(
		_story_note_echo_section_candidates(fact, primary_section_id, profile_id),
		filing_section_schema,
		used_sections
	)
	if not echo_section_id.is_empty():
		rows.append(_story_note_placement_row(fact, "policy_or_risk_echo", echo_section_id, profile_id, rows.size() + 1))
	return rows


static func _story_note_placement_row(
	fact: Dictionary,
	placement_role: String,
	section_id: String,
	profile_id: String,
	local_order: int
) -> Dictionary:
	var fact_id: String = str(fact.get("fact_id", "")).strip_edges()
	var safe_role: String = placement_role.strip_edges()
	if not STORY_NOTE_PLACEMENT_ROLES.has(safe_role):
		safe_role = "primary_note"
	var paragraph_role: String = _story_note_paragraph_role_for_placement(fact, safe_role, section_id)
	return {
		"schema_version": STORY_NOTE_PLACEMENT_SCHEMA_VERSION,
		"placement_status": STORY_NOTE_PLACEMENT_STATUS,
		"placement_id": "story_note_placement|%s|%s|%s" % [
			_cache_token(fact_id),
			_cache_token(safe_role),
			_cache_token(section_id)
		],
		"placement_order": local_order,
		"placement_role": safe_role,
		"paragraph_role": paragraph_role,
		"filing_section_id": section_id.strip_edges(),
		"filing_profile_id": _resolved_filing_profile_id(profile_id),
		"story_type": str(fact.get("story_type", "")).strip_edges(),
		"note_container": str(fact.get("note_container", "")).strip_edges(),
		"source_story_note_fact_ids": [fact_id] if not fact_id.is_empty() else [],
		"source_ids": _string_array(fact.get("source_ids", [])),
		"fact": fact.duplicate(true)
	}


static func _story_note_fact_is_material(fact: Dictionary) -> bool:
	if absf(float(fact.get("amount", 0.0))) > 0.0:
		return true
	var story_type: String = str(fact.get("story_type", "")).strip_edges()
	return story_type in [
		"dealership_agreement",
		"supply_or_offtake_agreement",
		"bank_facility",
		"bank_guarantee",
		"lease_or_land_right",
		"government_subsidy",
		"project_contract",
		"segment_expansion",
		"related_party_transaction",
		"subsidiary_commitment",
		"subsequent_event"
	]


static func _story_note_secondary_section_candidates(fact: Dictionary, primary_section_id: String, profile_id: String) -> Array:
	var story_type: String = str(fact.get("story_type", "")).strip_edges()
	if _resolved_filing_profile_id(profile_id) == "bank":
		match story_type:
			"bank_facility":
				return ["note_bank_liquidity_risk", "note_bank_credit_risk", "note_bank_capital_adequacy"]
			"bank_guarantee":
				return ["note_bank_loans_financing", "note_bank_liquidity_risk", "note_bank_credit_risk"]
			"related_party_transaction":
				return ["note_bank_loans_financing", "note_bank_credit_risk", "note_bank_related_parties"]
			"government_subsidy", "segment_expansion":
				return ["note_bank_interest_income", "note_bank_regulatory_compliance", "note_bank_credit_risk"]
			"subsequent_event":
				return ["note_bank_company_information", "note_bank_regulatory_compliance"]
			_:
				return ["note_bank_credit_risk", "note_bank_liquidity_risk", "note_bank_loans_financing"]
	match story_type:
		"dealership_agreement", "supply_or_offtake_agreement":
			return ["note_segment_information", "note_revenue_expenses_tax_equity", "note_commitments_contingencies"]
		"bank_facility":
			return ["note_commitments_contingencies", "note_financial_risk_management", "note_segment_information"]
		"bank_guarantee":
			return ["note_liabilities_borrowings", "note_financial_risk_management", "note_commitments_contingencies"]
		"lease_or_land_right", "subsidiary_commitment":
			return ["note_commitments_contingencies", "note_ppe_investments", "note_segment_information"]
		"government_subsidy":
			return ["note_segment_information", "note_revenue_expenses_tax_equity", "note_trade_receivables"]
		"project_contract":
			return ["note_commitments_contingencies", "note_segment_information", "note_ppe_investments"]
		"segment_expansion":
			return ["note_revenue_expenses_tax_equity", "note_ppe_investments", "note_commitments_contingencies"]
		"related_party_transaction":
			return ["note_commitments_contingencies", "note_segment_information", "note_related_parties"]
		"subsequent_event":
			return ["note_commitments_contingencies", "note_segment_information", "note_non_cash_subsequent_events"]
	return ["note_segment_information", "note_commitments_contingencies", "note_financial_risk_management"]


static func _story_note_echo_section_candidates(fact: Dictionary, primary_section_id: String, profile_id: String) -> Array:
	var story_type: String = str(fact.get("story_type", "")).strip_edges()
	if _resolved_filing_profile_id(profile_id) == "bank":
		match story_type:
			"bank_facility", "bank_guarantee":
				return ["note_bank_credit_risk", "note_bank_liquidity_risk", "note_bank_capital_adequacy"]
			"government_subsidy", "subsequent_event":
				return ["note_bank_regulatory_compliance", "note_bank_accounting_policies"]
			_:
				return ["note_bank_accounting_policies", "note_bank_credit_risk"]
	match story_type:
		"bank_facility", "bank_guarantee":
			return ["note_financial_risk_management", "note_accounting_policies"]
		"government_subsidy":
			return ["note_trade_receivables", "note_accounting_policies"]
		"subsequent_event":
			return ["note_financial_risk_management", "note_accounting_policies"]
		_:
			return ["note_accounting_policies", "note_financial_risk_management"]


static func _story_note_first_existing_section(candidates: Array, filing_section_schema: Array, excluded_sections: Array = []) -> String:
	for candidate_value in candidates:
		var candidate_id: String = str(candidate_value).strip_edges()
		if candidate_id.is_empty() or excluded_sections.has(candidate_id):
			continue
		if _filing_schema_has_section(filing_section_schema, candidate_id):
			return candidate_id
	return ""


static func _story_note_paragraph_role_for_placement(fact: Dictionary, placement_role: String, section_id: String) -> String:
	var safe_placement_role: String = placement_role.strip_edges()
	var safe_section_id: String = section_id.strip_edges()
	if safe_placement_role == "primary_note":
		return _story_note_paragraph_role(fact)
	if safe_placement_role == "policy_or_risk_echo":
		return "policy_noise"
	if safe_section_id in ["note_financial_risk_management", "note_accounting_policies", "note_bank_accounting_policies", "note_bank_credit_risk", "note_bank_liquidity_risk", "note_bank_capital_adequacy", "note_bank_regulatory_compliance"]:
		return "policy_noise"
	if safe_section_id in ["note_segment_information", "note_revenue_expenses_tax_equity", "note_bank_interest_income"]:
		return "segment_context"
	if safe_section_id in ["note_liabilities_borrowings", "note_bank_loans_financing"]:
		return "facility_detail"
	if safe_section_id in ["note_non_cash_subsequent_events"]:
		return "subsequent_event"
	if safe_section_id in ["note_commitments_contingencies", "note_ppe_investments", "note_related_parties", "note_bank_related_parties"]:
		return "commitment_detail"
	return _story_note_paragraph_role(fact)


static func _story_note_paragraph_role(fact: Dictionary) -> String:
	var note_container: String = str(fact.get("note_container", "")).strip_edges()
	var story_type: String = str(fact.get("story_type", "")).strip_edges()
	if note_container == "accounting_policies":
		return "policy_noise"
	if note_container == "subsequent_events" or story_type == "subsequent_event":
		return "subsequent_event"
	match story_type:
		"dealership_agreement", "supply_or_offtake_agreement":
			return "agreement_lead"
		"bank_facility", "bank_guarantee":
			return "facility_detail"
		"project_contract", "lease_or_land_right", "subsidiary_commitment", "related_party_transaction":
			return "commitment_detail"
		"segment_expansion", "government_subsidy":
			return "segment_context"
	return "agreement_lead"


static func _story_note_rendered_text_for_placement(
	fact: Dictionary,
	placement: Dictionary,
	annual_statement: Dictionary,
	options: Dictionary
) -> String:
	var placement_role: String = str(placement.get("placement_role", "primary_note")).strip_edges()
	match placement_role:
		"secondary_note":
			return _story_note_secondary_rendered_text(fact, placement, annual_statement, options)
		"policy_or_risk_echo":
			return _story_note_echo_rendered_text(fact, placement, annual_statement, options)
	return _story_note_rendered_text(fact, annual_statement, options)


static func _story_note_secondary_rendered_text(
	fact: Dictionary,
	placement: Dictionary,
	annual_statement: Dictionary,
	options: Dictionary
) -> String:
	var story_type: String = str(fact.get("story_type", "")).strip_edges()
	var counterparty_name: String = _story_note_counterparty_display_name(fact)
	var agreement_type: String = _story_note_agreement_display_name(str(fact.get("agreement_type", "")))
	var term_phrase: String = _story_note_term_display_phrase(fact)
	var amount_phrase: String = _story_note_amount_display_phrase(fact)
	var section_id: String = str(placement.get("filing_section_id", "")).strip_edges()
	match story_type:
		"dealership_agreement", "supply_or_offtake_agreement":
			return _story_note_clean_text("Revenue from the related operating segment is disclosed with activity arising from the %s with %s when sales are delivered under the arrangement." % [agreement_type, counterparty_name])
		"bank_facility":
			return _story_note_clean_text("The related credit facility with %s supports working capital, trade, guarantee, or hedging activity under sub-limits, with maturity and covenant requirements monitored under the financing agreement." % counterparty_name)
		"bank_guarantee":
			return _story_note_clean_text("This agreement is supported by a bank guarantee issued by a bank for the benefit of %s amounting to %s. The guarantee remains outstanding while the related commercial arrangement is effective." % [counterparty_name, amount_phrase])
		"lease_or_land_right":
			return _story_note_clean_text("Lease payments and right-of-use obligations from the %s with %s are presented over %s and considered with the Group's operating commitments." % [agreement_type, counterparty_name, term_phrase])
		"government_subsidy":
			return _story_note_clean_text("The related receivable is presented as part of regulated operating claims from %s when the subsidy or reimbursement becomes collectible under the applicable pricing mechanism." % counterparty_name)
		"project_contract":
			return _story_note_clean_text("Remaining commitments under the %s with %s follow project milestones, including construction and service obligations over %s." % [agreement_type, counterparty_name, term_phrase])
		"segment_expansion":
			return _story_note_clean_text("Revenue, assets, and commitments from the related operating segment are disclosed with the segment's current-year performance and future activity.")
		"related_party_transaction":
			return _story_note_clean_text("Balances with %s are presented separately from third-party balances, and transactions are measured according to the terms approved for the related-party relationship." % counterparty_name)
		"subsidiary_commitment":
			return _story_note_clean_text("The subsidiary arrangement with %s is reflected through asset, lease, and commitment disclosures according to the rights and obligations held by the Group." % counterparty_name)
		"subsequent_event":
			return _story_note_clean_text("The after-reporting-date arrangement is presented with subsequent events and may affect commitments or financing activity in the next reporting period.")
	if section_id.find("risk") != -1:
		return _story_note_echo_rendered_text(fact, placement, annual_statement, options)
	return _story_note_clean_text("The arrangement with %s is cross-referenced through the related note because its rights, obligations, and operating effects affect more than one part of the filing." % counterparty_name)


static func _story_note_echo_rendered_text(
	fact: Dictionary,
	placement: Dictionary,
	annual_statement: Dictionary,
	options: Dictionary
) -> String:
	var section_id: String = str(placement.get("filing_section_id", "")).strip_edges()
	var story_type: String = str(fact.get("story_type", "")).strip_edges()
	if section_id.find("risk") != -1 or story_type in ["bank_facility", "bank_guarantee"]:
		return _story_note_clean_text("Credit, liquidity, currency, interest-rate, and covenant exposures from this arrangement are monitored through counterparty limits, maturity review, and periodic reporting to management.")
	if story_type == "government_subsidy":
		return _story_note_clean_text("Regulated claims are recognized when the Group has enforceable rights to reimbursement and collection is supported by the applicable pricing mechanism.")
	return _story_note_clean_text("The Group applies its revenue, asset, liability, and impairment policies to rights and obligations arising from this arrangement.")


static func _story_note_rendered_text(fact: Dictionary, annual_statement: Dictionary, options: Dictionary) -> String:
	var story_type: String = str(fact.get("story_type", "")).strip_edges()
	var counterparty_name: String = _story_note_counterparty_display_name(fact)
	var agreement_type: String = _story_note_agreement_display_name(str(fact.get("agreement_type", "")))
	var date_phrase: String = _story_note_date_phrase(str(fact.get("effective_date", "")))
	var term_phrase: String = _story_note_term_display_phrase(fact)
	var amount_phrase: String = _story_note_amount_display_phrase(fact)
	match story_type:
		"dealership_agreement":
			return _story_note_clean_text("On %s, the Company entered into a %s with %s. The agreement is valid for %s and may be renewed or terminated in accordance with written terms agreed by the parties." % [date_phrase, agreement_type, counterparty_name, term_phrase])
		"supply_or_offtake_agreement":
			return _story_note_clean_text("The Company entered into a %s with %s on %s for the supply, purchase, or delivery of goods and services used in its operations. The arrangement is valid for %s and remains subject to volume, delivery, and settlement terms in the agreement." % [agreement_type, counterparty_name, date_phrase, term_phrase])
		"bank_facility":
			return _story_note_clean_text("On %s, the Company obtained a %s from %s with an available amount of %s. The facility may be used for working capital, trade, guarantee, or hedging needs under sub-limits set out in the agreement, and the Company is required to maintain certain financial ratios." % [date_phrase, agreement_type, counterparty_name, amount_phrase])
		"bank_guarantee":
			return _story_note_clean_text("In connection with the %s with %s, the Company is required to provide a bank guarantee amounting to %s. The guarantee is held while the related agreement remains effective." % [agreement_type, counterparty_name, amount_phrase])
		"lease_or_land_right":
			return _story_note_clean_text("The Company has a %s with %s covering land, operating locations, or right-of-use assets used in its operations. The arrangement covers %s and is presented according to the contractual rights and renewal conditions in the agreement." % [agreement_type, counterparty_name, term_phrase])
		"government_subsidy":
			return _story_note_clean_text("The Company recognizes %s from %s for the subsidized or reimbursable portion of regulated sales and operating claims. Amounts are recorded when the related claim is approved or becomes collectible under the applicable regulation." % [amount_phrase, counterparty_name])
		"project_contract":
			return _story_note_clean_text("On %s, the Company signed a %s with %s to carry out construction, engineering, operating, or support work for the related project. The contract covers %s, including any construction period and service term specified in the agreement." % [date_phrase, agreement_type, counterparty_name, term_phrase])
		"segment_expansion":
			return _story_note_clean_text("Management reviews the %s as part of operating segment performance, including revenue, operating profit, assets, and commitments attributable to the segment." % agreement_type)
		"related_party_transaction":
			return _story_note_clean_text("The Company recorded %s with %s during the year. Balances and transactions with the related party are presented separately from third-party balances and transactions." % [agreement_type, counterparty_name])
		"subsidiary_commitment":
			return _story_note_clean_text("A subsidiary of the Company has a %s with %s for operations or assets used in the business. The arrangement covers %s and is presented within the Group's commitments and non-current asset disclosures." % [agreement_type, counterparty_name, term_phrase])
		"subsequent_event":
			return _story_note_clean_text("After the reporting date, the Company recorded a %s with %s dated %s. The event is disclosed as a subsequent arrangement affecting future operating commitments or financing activities." % [agreement_type, counterparty_name, date_phrase])
	return _story_note_clean_text("The Company presents %s in the annual filing for the year ended 31 December %d." % [agreement_type, int(annual_statement.get("fiscal_year", options.get("fiscal_year", 2019)))])


static func _story_note_counterparty_display_name(fact: Dictionary) -> String:
	var counterparty_name: String = str(fact.get("counterparty_name", "")).strip_edges()
	if counterparty_name.is_empty():
		return "a counterparty"
	if counterparty_name.find("|") != -1:
		return _story_note_title_case(counterparty_name)
	return counterparty_name


static func _story_note_agreement_display_name(agreement_type: String) -> String:
	var text: String = agreement_type.strip_edges()
	if text.is_empty():
		return "business arrangement"
	return text


static func _story_note_date_phrase(effective_date: String) -> String:
	var text: String = effective_date.strip_edges()
	if text.is_empty():
		return "the reporting year"
	return text


static func _story_note_term_display_phrase(fact: Dictionary) -> String:
	var term_text: String = str(fact.get("term_text", "")).strip_edges()
	if not term_text.is_empty():
		return term_text
	var term_months: int = int(fact.get("term_months", 0))
	if term_months <= 0:
		return "the period set out in the agreement"
	if term_months % 12 == 0:
		var years: int = int(term_months / 12)
		return "%d-year period" % years
	return "%d-month period" % term_months


static func _story_note_amount_display_phrase(fact: Dictionary) -> String:
	var amount: float = absf(float(fact.get("amount", 0.0)))
	var currency: String = str(fact.get("currency", "IDR")).strip_edges().to_upper()
	if currency.is_empty():
		currency = "IDR"
	if amount <= 0.0:
		return "an amount determined under the agreement"
	var suffix: String = ""
	var display_amount: float = amount
	if amount >= 1000000000000.0:
		display_amount = amount / 1000000000000.0
		suffix = " trillion"
	elif amount >= 1000000000.0:
		display_amount = amount / 1000000000.0
		suffix = " billion"
	elif amount >= 1000000.0:
		display_amount = amount / 1000000.0
		suffix = " million"
	if suffix.is_empty():
		return "%s %s" % [currency, _story_note_integer_with_separators(int(round(amount)))]
	return "%s %.1f%s" % [currency, display_amount, suffix]


static func _story_note_integer_with_separators(value: int) -> String:
	var source: String = str(value)
	var result: String = ""
	var count: int = 0
	for index in range(source.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = source.substr(index, 1) + result
		count += 1
	return result


static func _story_note_clean_text(text: String) -> String:
	var cleaned: String = text.strip_edges()
	while cleaned.find("  ") != -1:
		cleaned = cleaned.replace("  ", " ")
	cleaned = cleaned.replace(" ,", ",")
	cleaned = cleaned.replace(" .", ".")
	return cleaned


static func _story_note_text_key(text: String) -> String:
	return _story_note_clean_text(text).to_lower()


static func _story_note_text_has_forbidden_phrase(text: String) -> bool:
	var lower_text: String = text.to_lower()
	for phrase_value in STORY_NOTE_PROSE_FORBIDDEN_PHRASES:
		var phrase: String = str(phrase_value).strip_edges().to_lower()
		if not phrase.is_empty() and lower_text.find(phrase) != -1:
			return true
	return false


static func _story_note_source_ids_by_prefix(fact: Dictionary, prefix: String) -> Array:
	var rows: Array = []
	for source_id_value in _string_array(fact.get("source_ids", [])):
		var source_id: String = str(source_id_value).strip_edges()
		if source_id.begins_with(prefix):
			rows.append(source_id)
	return rows


static func _story_note_placement_role_counts(rows: Array) -> Dictionary:
	var counts: Dictionary = {}
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var role: String = str(row_value.get("placement_role", "")).strip_edges()
		if role.is_empty():
			continue
		counts[role] = int(counts.get(role, 0)) + 1
	return counts


static func _story_note_placement_section_counts(rows: Array) -> Dictionary:
	var counts: Dictionary = {}
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var section_id: String = str(row_value.get("filing_section_id", "")).strip_edges()
		if section_id.is_empty():
			continue
		counts[section_id] = int(counts.get(section_id, 0)) + 1
	return counts


static func _story_note_placement_fact_span_counts(rows: Array) -> Dictionary:
	var sections_by_fact: Dictionary = {}
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var section_id: String = str(row.get("filing_section_id", "")).strip_edges()
		if section_id.is_empty():
			continue
		for fact_id_value in _string_array(row.get("source_story_note_fact_ids", [])):
			var fact_id: String = str(fact_id_value).strip_edges()
			if fact_id.is_empty():
				continue
			var fact_sections: Array = _string_array(sections_by_fact.get(fact_id, []))
			fact_sections = _array_with_value(fact_sections, section_id)
			sections_by_fact[fact_id] = fact_sections
	var counts: Dictionary = {}
	for fact_id_value in sections_by_fact.keys():
		counts[str(fact_id_value)] = _string_array(sections_by_fact.get(fact_id_value, [])).size()
	return counts


static func _story_note_prose_role_counts(rows: Array) -> Dictionary:
	var counts: Dictionary = {}
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var role: String = str(row_value.get("paragraph_role", "")).strip_edges()
		if role.is_empty():
			continue
		counts[role] = int(counts.get(role, 0)) + 1
	return counts


static func _story_note_prose_section_counts(rows: Array) -> Dictionary:
	var counts: Dictionary = {}
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var section_id: String = str(row_value.get("filing_section_id", "")).strip_edges()
		if section_id.is_empty():
			continue
		counts[section_id] = int(counts.get(section_id, 0)) + 1
	return counts


static func _filing_schema_has_section(filing_section_schema: Array, section_id: String) -> bool:
	return not _filing_section_by_id(filing_section_schema, section_id).is_empty()


static func _filing_section_by_id(filing_section_schema: Array, section_id: String) -> Dictionary:
	var safe_section_id: String = section_id.strip_edges()
	for section_value in filing_section_schema:
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		if str(section.get("section_id", "")).strip_edges() == safe_section_id:
			return section.duplicate(true)
	return {}


static func _story_note_company_definition_from_options(options: Dictionary, annual_statement: Dictionary, company_id: String) -> Dictionary:
	var definition: Dictionary = {}
	if typeof(options.get("company_definition", {})) == TYPE_DICTIONARY:
		definition = options.get("company_definition", {}).duplicate(true)
	for key in ["id", "company_id"]:
		if str(definition.get(key, "")).strip_edges().is_empty():
			definition[key] = company_id
	for key in ["ticker", "name", "company_name", "sector_id", "sector", "subsector_id", "subsector", "business_summary"]:
		if not str(definition.get(key, "")).strip_edges().is_empty():
			continue
		if options.has(key):
			definition[key] = options.get(key)
		elif annual_statement.has(key):
			definition[key] = annual_statement.get(key)
	for key in ["moat_tags", "story_hooks", "relationship_hooks"]:
		if not _variant_array(definition.get(key, [])).is_empty():
			continue
		if options.has(key):
			definition[key] = _variant_array(options.get(key, []))
	if not definition.has("commodity_exposures") and typeof(options.get("commodity_exposures", {})) == TYPE_DICTIONARY:
		definition["commodity_exposures"] = options.get("commodity_exposures", {}).duplicate(true)
	return definition


static func _story_note_source_context_from_options(options: Dictionary) -> Dictionary:
	for key in ["story_note_source_context", "annual_filing_story_source_context", "source_context"]:
		if typeof(options.get(key, {})) == TYPE_DICTIONARY:
			return options.get(key, {}).duplicate(true)
	var context: Dictionary = {}
	for key in [
		"company_definitions",
		"company_dossiers",
		"dossiers",
		"story_dossiers",
		"relationship_edges",
		"relationship_graph_edges",
		"edges",
		"relationship_events",
		"relationship_graph_events",
		"active_company_arcs",
		"corporate_action_events",
		"roadmap_milestones",
		"company_events",
		"event_history"
	]:
		if options.has(key):
			context[key] = options.get(key)
	return context


static func _story_note_context_rows(source_context: Dictionary, keys: Array) -> Array:
	var rows: Array = []
	for key_value in keys:
		var key: String = str(key_value)
		if not source_context.has(key):
			continue
		var source_value: Variant = source_context.get(key)
		if typeof(source_value) == TYPE_ARRAY:
			rows.append_array(source_value)
		elif typeof(source_value) == TYPE_DICTIONARY:
			var dictionary_value: Dictionary = source_value
			for nested_key in dictionary_value.keys():
				var nested_value: Variant = dictionary_value.get(nested_key)
				if typeof(nested_value) == TYPE_DICTIONARY:
					rows.append(nested_value)
				elif typeof(nested_value) == TYPE_ARRAY:
					rows.append_array(nested_value)
	return rows


static func _story_note_company_id(company_definition: Dictionary, annual_statement: Dictionary, options: Dictionary) -> String:
	for value in [options.get("company_id", ""), company_definition.get("id", ""), company_definition.get("company_id", ""), annual_statement.get("company_id", "")]:
		var company_id: String = str(value).strip_edges()
		if not company_id.is_empty():
			return company_id
	return ""


static func _story_note_profile_id(company_definition: Dictionary, annual_statement: Dictionary, options: Dictionary) -> String:
	var explicit_profile_id: String = str(options.get("filing_profile_id", options.get("profile_id", ""))).strip_edges()
	if not explicit_profile_id.is_empty():
		return _resolved_filing_profile_id(explicit_profile_id)
	var profile_options: Dictionary = {
		"company_id": _story_note_company_id(company_definition, annual_statement, options),
		"ticker": str(company_definition.get("ticker", annual_statement.get("ticker", ""))),
		"company_name": str(company_definition.get("name", annual_statement.get("company_name", ""))),
		"sector_id": str(company_definition.get("sector_id", company_definition.get("sector", annual_statement.get("sector_id", "")))),
		"subsector_id": str(company_definition.get("subsector_id", company_definition.get("subsector", annual_statement.get("subsector_id", "")))),
		"business_summary": str(company_definition.get("business_summary", annual_statement.get("business_summary", ""))),
		"moat_tags": _variant_array(company_definition.get("moat_tags", [])),
		"story_hooks": _variant_array(company_definition.get("story_hooks", []))
	}
	return resolve_filing_profile_id(annual_statement, profile_options)


static func _story_note_story_type_requires(story_type: String, requirement_id: String) -> bool:
	var definition: Dictionary = STORY_NOTE_FACT_STORY_TYPE_DEFINITIONS.get(story_type, {})
	return bool(definition.get(requirement_id, false))


static func _story_note_story_type_from_dossier(dossier: Dictionary, packet: Dictionary) -> String:
	var archetype_id: String = str(dossier.get("archetype_id", "")).strip_edges()
	var note_type: String = str(packet.get("note_type", dossier.get("note_type", ""))).strip_edges()
	match archetype_id:
		"contract_win":
			return "supply_or_offtake_agreement"
		"capex_expansion":
			return "segment_expansion"
		"commodity_tailwind", "commodity_headwind", "margin_recovery", "turnaround":
			return "segment_expansion"
		"governance_risk", "fraud_signal":
			return "related_party_transaction"
		"balance_sheet_stress":
			return "bank_facility"
		"corporate_action_use_of_proceeds":
			return "subsequent_event"
	match note_type:
		"customer_contract":
			return "supply_or_offtake_agreement"
		"debt_maturity":
			return "bank_facility"
		"governance_note", "statement_contradiction":
			return "related_party_transaction"
		"use_of_proceeds":
			return "subsequent_event"
	return "segment_expansion"


static func _story_note_story_type_from_relationship(relationship_type: String) -> String:
	match relationship_type:
		"supplier", "customer":
			return "supply_or_offtake_agreement"
		"partner":
			return "project_contract"
		"parent", "subsidiary":
			return "related_party_transaction"
		"acquirer_candidate", "target_candidate":
			return "subsequent_event"
	return ""


static func _story_note_story_type_from_note_type(note_type: String) -> String:
	match note_type:
		"segment_information", "revenue", "cost_of_revenue_and_gross_profit", "operating_expenses":
			return "segment_expansion"
		"commitments_contingencies_and_subsequent_events":
			return "subsequent_event"
		"related_party_transactions":
			return "related_party_transaction"
		"debt_and_borrowings":
			return "bank_facility"
		"property_plant_and_equipment":
			return "segment_expansion"
	return ""


static func _story_note_story_type_from_runtime_row(row: Dictionary, source_system: String) -> String:
	var category: String = str(row.get("category", row.get("event_id", row.get("milestone_family", "")))).to_lower()
	var source_text: String = "%s %s %s" % [source_system, category, str(row.get("source_system", ""))]
	if _text_matches_any_term(source_text, ["corporate", "subsequent", "resolution", "execution", "filing", "approval"]):
		return "subsequent_event"
	if _text_matches_any_term(source_text, ["project", "milestone", "roadmap", "capex", "construction"]):
		return "project_contract"
	return "subsequent_event"


static func _story_note_story_type_from_catalog_hook(hook: String, profile_id: String) -> String:
	var text: String = hook.to_lower()
	if _resolved_filing_profile_id(profile_id) == "bank" and _text_matches_any_term(text, ["loan", "deposit", "credit", "financing", "bank", "facility"]):
		return "bank_facility"
	if _text_matches_any_term(text, ["debt", "refinancing", "funding", "loan", "bank", "facility"]):
		return "bank_facility"
	if _text_matches_any_term(text, ["government", "subsidy", "tariff", "reserve_contract", "program"]):
		return "government_subsidy"
	if _text_matches_any_term(text, ["contract", "tender", "ppa", "order", "charter", "customer", "supplier"]):
		return "supply_or_offtake_agreement"
	if _text_matches_any_term(text, ["lease", "land", "concession"]):
		return "lease_or_land_right"
	if _text_matches_any_term(text, ["project", "capex", "expansion", "rollout", "capacity", "plant", "terminal", "network", "smelter"]):
		return "segment_expansion"
	return ""


static func _story_note_container_for_section(story_type: String, section_id: String, profile_id: String) -> String:
	match section_id:
		"commitments_contingencies":
			return _story_note_first_allowed_container(story_type, ["commitments_contingencies", "significant_agreements"], profile_id)
		"debt_and_borrowings", "cash_flow_information":
			return _story_note_first_allowed_container(story_type, ["bank_facilities_guarantees", "commitments_contingencies"], profile_id)
		"related_party_transactions":
			return _story_note_first_allowed_container(story_type, ["related_parties"], profile_id)
		"segment_information", "revenue", "inventories":
			return _story_note_first_allowed_container(story_type, ["segment_operations"], profile_id)
		"property_plant_and_equipment":
			return _story_note_first_allowed_container(story_type, ["project_construction", "subsidiaries_leases", "segment_operations"], profile_id)
		"subsequent_events":
			return _story_note_first_allowed_container(story_type, ["subsequent_events"], profile_id)
	return _story_note_first_allowed_container(story_type, ["significant_agreements", "segment_operations", "commitments_contingencies"], profile_id)


static func _story_note_container_for_relationship(story_type: String, relationship_type: String, profile_id: String) -> String:
	match relationship_type:
		"supplier", "customer":
			return _story_note_first_allowed_container(story_type, ["customers_suppliers", "significant_agreements", "commitments_contingencies"], profile_id)
		"partner":
			return _story_note_first_allowed_container(story_type, ["project_construction", "significant_agreements", "commitments_contingencies"], profile_id)
		"parent", "subsidiary":
			return _story_note_first_allowed_container(story_type, ["related_parties", "subsidiaries_leases"], profile_id)
		"acquirer_candidate", "target_candidate":
			return _story_note_first_allowed_container(story_type, ["subsequent_events"], profile_id)
	return ""


static func _story_note_container_for_note_type(story_type: String, note_type: String, profile_id: String) -> String:
	match note_type:
		"segment_information", "revenue", "cost_of_revenue_and_gross_profit", "operating_expenses":
			return _story_note_first_allowed_container(story_type, ["segment_operations"], profile_id)
		"commitments_contingencies_and_subsequent_events":
			return _story_note_first_allowed_container(story_type, ["subsequent_events", "commitments_contingencies"], profile_id)
		"related_party_transactions":
			return _story_note_first_allowed_container(story_type, ["related_parties"], profile_id)
		"debt_and_borrowings":
			return _story_note_first_allowed_container(story_type, ["bank_facilities_guarantees", "commitments_contingencies"], profile_id)
		"property_plant_and_equipment":
			return _story_note_first_allowed_container(story_type, ["project_construction", "segment_operations"], profile_id)
	return ""


static func _story_note_container_for_catalog_hook(story_type: String, hook: String, profile_id: String) -> String:
	var text: String = hook.to_lower()
	if _text_matches_any_term(text, ["government", "subsidy", "tariff", "reserve_contract", "program"]):
		return _story_note_first_allowed_container(story_type, ["government_pricing_subsidies", "segment_operations"], profile_id)
	if _text_matches_any_term(text, ["debt", "refinancing", "funding", "loan", "bank", "facility"]):
		return _story_note_first_allowed_container(story_type, ["bank_facilities_guarantees", "commitments_contingencies"], profile_id)
	if _text_matches_any_term(text, ["lease", "land", "concession"]):
		return _story_note_first_allowed_container(story_type, ["subsidiaries_leases", "commitments_contingencies"], profile_id)
	if _text_matches_any_term(text, ["contract", "tender", "ppa", "order", "charter", "customer", "supplier"]):
		return _story_note_first_allowed_container(story_type, ["customers_suppliers", "significant_agreements"], profile_id)
	return _story_note_first_allowed_container(story_type, ["segment_operations"], profile_id)


static func _story_note_first_allowed_container(story_type: String, preferred_containers: Array, profile_id: String) -> String:
	var allowed: Array = story_note_allowed_containers_for_story_type(story_type, profile_id)
	for container_value in preferred_containers:
		var container_id: String = str(container_value).strip_edges()
		if allowed.has(container_id):
			return container_id
	return str(allowed.front()) if not allowed.is_empty() else ""


static func _story_note_counterparty_for_company(company_id: String, source_context: Dictionary) -> Dictionary:
	for edge_value in _story_note_context_rows(source_context, ["relationship_edges", "relationship_graph_edges", "edges"]):
		if typeof(edge_value) != TYPE_DICTIONARY:
			continue
		var counterparty: Dictionary = _story_note_counterparty_from_edge(company_id, edge_value, source_context)
		if not counterparty.is_empty():
			return counterparty
	for event_value in _story_note_context_rows(source_context, ["relationship_events", "relationship_graph_events"]):
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_value
		if str(event.get("target_company_id", event.get("company_id", ""))).strip_edges() == company_id:
			var counterparty: Dictionary = _story_note_counterparty_from_event(event)
			if not counterparty.is_empty():
				return counterparty
	return {}


static func _story_note_counterparty_from_edge(company_id: String, edge: Dictionary, source_context: Dictionary) -> Dictionary:
	var source_company_id: String = str(edge.get("source_company_id", "")).strip_edges()
	var target_company_id: String = str(edge.get("target_company_id", "")).strip_edges()
	var counterparty_id: String = ""
	if source_company_id == company_id:
		counterparty_id = target_company_id
	elif target_company_id == company_id:
		counterparty_id = source_company_id
	if counterparty_id.is_empty():
		return {}
	return {
		"counterparty_id": counterparty_id,
		"counterparty_name": _story_note_company_name_for_id(counterparty_id, source_context, edge)
	}


static func _story_note_counterparty_from_event(event: Dictionary) -> Dictionary:
	var counterparty_id: String = str(event.get("counterparty_company_id", event.get("counterparty_id", ""))).strip_edges()
	if counterparty_id.is_empty():
		return {}
	return {
		"counterparty_id": counterparty_id,
		"counterparty_name": str(event.get("counterparty_company_name", event.get("counterparty_name", _story_note_title_case(counterparty_id))))
	}


static func _story_note_counterparty_for_catalog_hook(company_id: String, hook: String, story_type: String) -> Dictionary:
	if not _story_note_story_type_requires(story_type, "requires_counterparty"):
		return {}
	var text: String = hook.to_lower()
	var label: String = "Commercial counterparty"
	if _text_matches_any_term(text, ["government", "subsidy", "tariff", "program"]):
		label = "Government counterparty"
	elif _text_matches_any_term(text, ["bank", "facility", "debt", "refinancing", "funding", "loan"]):
		label = "Financing bank"
	elif _text_matches_any_term(text, ["supplier", "input", "procurement"]):
		label = "Supplier counterparty"
	elif _text_matches_any_term(text, ["customer", "contract", "tender", "ppa", "charter", "order"]):
		label = "Customer counterparty"
	return {
		"counterparty_id": "catalog_counterparty|%s|%s" % [company_id, _cache_token(hook)],
		"counterparty_name": label
	}


static func _story_note_company_name_for_id(company_id: String, source_context: Dictionary, edge: Dictionary) -> String:
	if company_id == str(edge.get("source_company_id", "")):
		var source_name: String = str(edge.get("source_company_name", edge.get("source_name", ""))).strip_edges()
		if not source_name.is_empty():
			return source_name
	if company_id == str(edge.get("target_company_id", "")):
		var target_name: String = str(edge.get("target_company_name", edge.get("target_name", ""))).strip_edges()
		if not target_name.is_empty():
			return target_name
	for definition_value in _story_note_context_rows(source_context, ["company_definitions", "companies"]):
		if typeof(definition_value) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = definition_value
		if str(definition.get("id", definition.get("company_id", ""))).strip_edges() == company_id:
			return str(definition.get("name", definition.get("company_name", _story_note_title_case(company_id))))
	return _story_note_title_case(company_id)


static func _story_note_agreement_type_for_relationship(relationship_type: String) -> String:
	match relationship_type:
		"supplier":
			return "supplier arrangement"
		"customer":
			return "customer arrangement"
		"partner":
			return "project cooperation agreement"
		"parent", "subsidiary":
			return "related party arrangement"
		"acquirer_candidate", "target_candidate":
			return "corporate transaction event"
	return "commercial arrangement"


static func _story_note_agreement_type_for_story(story_type: String, context_text: String) -> String:
	var text: String = context_text.to_lower()
	match story_type:
		"dealership_agreement":
			return "dealership agreement"
		"supply_or_offtake_agreement":
			if _text_matches_any_term(text, ["ppa", "power"]):
				return "power purchase agreement"
			if _text_matches_any_term(text, ["charter"]):
				return "charter agreement"
			return "supply or offtake agreement"
		"bank_facility":
			return "bank facility"
		"bank_guarantee":
			return "bank guarantee"
		"lease_or_land_right":
			return "lease or land-right arrangement"
		"government_subsidy":
			return "government subsidy or reimbursement arrangement"
		"project_contract":
			return "project contract"
		"segment_expansion":
			return "segment development"
		"related_party_transaction":
			return "related party transaction"
		"subsidiary_commitment":
			return "subsidiary commitment"
		"subsequent_event":
			return "subsequent event"
	return "business arrangement"


static func _story_note_effective_date(source_row: Dictionary, annual_statement: Dictionary, options: Dictionary) -> String:
	for key in ["effective_date", "event_date", "date", "announcement_date"]:
		var value: String = str(source_row.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	var fiscal_year: int = int(options.get("fiscal_year", annual_statement.get("fiscal_year", 2019)))
	if fiscal_year <= 0:
		fiscal_year = 2019
	var source_id: String = _story_note_row_id(source_row)
	var month: int = 1 + int(_stable_hash("%s|month" % source_id)) % 12
	var day: int = 1 + int(_stable_hash("%s|day" % source_id)) % 24
	return "%04d-%02d-%02d" % [fiscal_year, month, day]


static func _story_note_term_months(story_type: String, source_row: Dictionary) -> int:
	for key in ["term_months", "duration_months", "contract_months"]:
		if int(source_row.get(key, 0)) > 0:
			return int(source_row.get(key, 0))
	match story_type:
		"lease_or_land_right":
			return 120
		"project_contract":
			return 36
		"bank_facility", "bank_guarantee":
			return 12
		"supply_or_offtake_agreement", "dealership_agreement":
			return 24
		"subsidiary_commitment":
			return 60
	return 0


static func _story_note_term_text(story_type: String, source_row: Dictionary) -> String:
	var explicit_text: String = str(source_row.get("term_text", source_row.get("duration_text", ""))).strip_edges()
	if not explicit_text.is_empty():
		return explicit_text
	match story_type:
		"lease_or_land_right":
			return "long-term operating period, subject to renewal and compliance with agreement terms"
		"project_contract":
			return "project term tied to completion milestones and service period"
		"bank_facility":
			return "facility availability reviewed periodically under the financing agreement"
		"bank_guarantee":
			return "guarantee held while the related commercial agreement remains effective"
		"supply_or_offtake_agreement", "dealership_agreement":
			return "renewable commercial term unless terminated under the agreement"
		"government_subsidy":
			return "recognized when claims are approved under applicable regulation"
		"subsidiary_commitment":
			return "commitment period follows the underlying subsidiary arrangement"
	return ""


static func _story_note_amount_for_fact(story_type: String, annual_statement: Dictionary, source_row: Dictionary, company_definition: Dictionary, options: Dictionary) -> float:
	for key in ["amount", "value", "contract_value", "facility_limit", "commitment_amount"]:
		if float(source_row.get(key, 0.0)) > 0.0:
			return snappedf(float(source_row.get(key, 0.0)), 0.001)
	if not _story_note_story_type_requires(story_type, "requires_amount"):
		return 0.0
	var basis: float = 0.0
	match story_type:
		"bank_facility", "bank_guarantee":
			basis = max(_story_note_statement_line_value(annual_statement, "financial_position", ["debt", "cash", "current_liabilities"]), 100000000.0)
			return snappedf(max(1000000.0, basis * 0.18), 0.001)
		"lease_or_land_right", "subsidiary_commitment":
			basis = max(_story_note_statement_line_value(annual_statement, "financial_position", ["property_plant_equipment", "right_of_use_assets", "non_current_assets"]), 100000000.0)
			return snappedf(max(1000000.0, basis * 0.08), 0.001)
		"government_subsidy":
			basis = max(_story_note_statement_line_value(annual_statement, "profit_or_loss_and_oci", ["revenue"]), 100000000.0)
			return snappedf(max(1000000.0, basis * 0.03), 0.001)
		"project_contract", "related_party_transaction":
			basis = max(_story_note_statement_line_value(annual_statement, "profit_or_loss_and_oci", ["revenue"]), 100000000.0)
			return snappedf(max(1000000.0, basis * 0.10), 0.001)
	return 0.0


static func _story_note_currency(annual_statement: Dictionary, source_row: Dictionary) -> String:
	var currency: String = str(source_row.get("currency", annual_statement.get("currency", annual_statement.get("presentation_currency", "IDR")))).strip_edges().to_upper()
	return "IDR" if currency.is_empty() else currency


static func _story_note_source_ids(source_row: Dictionary, seed_ids: Array) -> Array:
	var ids: Array = []
	for seed_id in seed_ids:
		ids = _array_with_value(ids, str(seed_id))
	for key in ["source_ids", "source_fact_ids", "fact_ids", "source_clue_ids", "clue_ids", "effect_ids", "source_disclosure_packet_ids", "disclosure_packet_ids"]:
		for source_id in _string_array(source_row.get(key, [])):
			ids = _array_with_value(ids, source_id)
	ids.sort()
	return ids


static func _story_note_statement_line_value(annual_statement: Dictionary, section_id: String, metric_ids: Array) -> float:
	for metric_value in metric_ids:
		var metric_id: String = str(metric_value)
		for line_value in _variant_array(annual_statement.get(section_id, [])):
			if typeof(line_value) != TYPE_DICTIONARY:
				continue
			var line: Dictionary = line_value
			if str(line.get("id", "")) == metric_id or str(line.get("metric_id", "")) == metric_id:
				return absf(float(line.get("value", 0.0)))
	return 0.0


static func _story_note_runtime_row_matches_company(row: Dictionary, company_id: String) -> bool:
	for key in ["company_id", "target_company_id", "target_id", "issuer_company_id"]:
		if str(row.get(key, "")).strip_edges() == company_id:
			return true
	return false


static func _story_note_row_id(row: Dictionary) -> String:
	for key in ["fact_id", "packet_id", "placement_id", "edge_id", "relationship_event_id", "arc_id", "event_id", "id", "milestone_id", "source_id"]:
		var row_id: String = str(row.get(key, "")).strip_edges()
		if not row_id.is_empty():
			return row_id
	return _stable_hash(JSON.stringify(row))


static func _story_note_commodity_exposure_fallback(company_definition: Dictionary, annual_statement: Dictionary, options: Dictionary, profile_id: String) -> Dictionary:
	var company_id: String = _story_note_company_id(company_definition, annual_statement, options)
	var exposures: Dictionary = company_definition.get("commodity_exposures", {}) if typeof(company_definition.get("commodity_exposures", {})) == TYPE_DICTIONARY else {}
	if exposures.is_empty():
		return {}
	var best_commodity: String = ""
	var best_abs_exposure: float = 0.0
	for commodity_value in exposures.keys():
		var commodity_id: String = str(commodity_value).strip_edges()
		var exposure: float = absf(float(exposures.get(commodity_id, 0.0)))
		if exposure > best_abs_exposure:
			best_commodity = commodity_id
			best_abs_exposure = exposure
	if best_commodity.is_empty() or best_abs_exposure < 0.12:
		return {}
	var story_type: String = "segment_expansion"
	var note_container: String = _story_note_first_allowed_container(story_type, ["segment_operations"], profile_id)
	return _story_note_fact_from_parts(
		"story_fact|company_universe|%s|commodity_exposure|%s" % [company_id, _cache_token(best_commodity)],
		company_id,
		story_type,
		note_container,
		{},
		"commodity-linked segment exposure",
		_story_note_effective_date({"source_id": best_commodity}, annual_statement, options),
		0,
		"",
		0.0,
		_story_note_currency(annual_statement, {}),
		"company_universe_catalog",
		["company_universe|%s|commodity_exposure|%s" % [company_id, _cache_token(best_commodity)]],
		STORY_NOTE_FACT_PACKET_VISIBILITY_LEVEL,
		STORY_NOTE_FACT_PACKET_CAPTURE_GROUP
	)


static func _story_note_business_summary_fallback(company_definition: Dictionary, annual_statement: Dictionary, options: Dictionary, profile_id: String) -> Dictionary:
	var company_id: String = _story_note_company_id(company_definition, annual_statement, options)
	var story_type: String = "segment_expansion"
	return _story_note_fact_from_parts(
		"story_fact|company_universe|%s|business_summary" % company_id,
		company_id,
		story_type,
		_story_note_first_allowed_container(story_type, ["segment_operations"], profile_id),
		{},
		"ordinary operating segment context",
		_story_note_effective_date({"source_id": "business_summary"}, annual_statement, options),
		0,
		"",
		0.0,
		_story_note_currency(annual_statement, {}),
		"company_universe_catalog",
		["company_universe|%s|business_summary" % company_id],
		STORY_NOTE_FACT_PACKET_VISIBILITY_LEVEL,
		STORY_NOTE_FACT_PACKET_CAPTURE_GROUP
	)


static func _story_note_title_case(value: String) -> String:
	var words: Array = []
	for word_value in value.replace("_", " ").replace("|", " ").split(" ", false):
		var word: String = str(word_value).strip_edges()
		if word.is_empty():
			continue
		words.append(word.substr(0, 1).to_upper() + word.substr(1).to_lower())
	return " ".join(words)


static func _text_matches_any_term(text: String, terms: Array) -> bool:
	var lower_text: String = text.to_lower()
	for term_value in terms:
		var term: String = str(term_value).strip_edges().to_lower()
		if not term.is_empty() and lower_text.find(term) != -1:
			return true
	return false


static func _footprints_by_section(footprints: Array) -> Dictionary:
	var rows: Dictionary = {}
	for row_value in footprints:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var section_id: String = str(row.get("filing_section_id", "")).strip_edges()
		if section_id.is_empty():
			continue
		var section_rows: Array = _variant_array(rows.get(section_id, []))
		section_rows.append(row.duplicate(true))
		rows[section_id] = section_rows
	for section_key in rows.keys():
		var section_rows: Array = _variant_array(rows.get(section_key, []))
		section_rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
			return int(left.get("footprint_order", 0)) < int(right.get("footprint_order", 0))
		)
		rows[section_key] = section_rows
	return rows


static func _safe_company_id(annual_statement: Dictionary, company_id: String) -> String:
	var result: String = company_id.strip_edges()
	if result.is_empty():
		result = str(annual_statement.get("company_id", "")).strip_edges()
	return result


static func _fiscal_year(annual_statement: Dictionary, options: Dictionary) -> int:
	var fiscal_year: int = int(options.get("fiscal_year", annual_statement.get("fiscal_year", annual_statement.get("statement_year", 0))))
	if fiscal_year <= 0:
		fiscal_year = int(annual_statement.get("comparative_year", 0)) + 1
	return fiscal_year


static func _source_state_payload(annual_statement: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("statement_id=%s" % str(annual_statement.get("statement_id", "")))
	lines.append("company_id=%s" % str(annual_statement.get("company_id", "")))
	lines.append("fiscal_year=%d" % int(annual_statement.get("fiscal_year", 0)))
	lines.append("comparative_year=%d" % int(annual_statement.get("comparative_year", 0)))
	lines.append("scope=%s:%s" % [str(annual_statement.get("statement_scope", "")), str(annual_statement.get("consolidated", false))])
	lines.append("period=%s" % str(annual_statement.get("statement_period_label", "")))
	lines.append("sections=%s" % _section_payload(_variant_array(annual_statement.get("annual_report_section_map", []))))
	lines.append("toc=%s" % _section_payload(_variant_array(annual_statement.get("table_of_contents", []))))
	for source_array in ["financial_position", "profit_or_loss_and_oci", "changes_in_equity", "cash_flows"]:
		lines.append("rows:%s:%s" % [source_array, _statement_rows_payload(_variant_array(annual_statement.get(source_array, [])))])
	lines.append("notes=%s" % _notes_payload(_variant_array(annual_statement.get("notes", []))))
	lines.append("note_index=%s" % _notes_payload(_variant_array(annual_statement.get("note_index", []))))
	var traceability: Dictionary = annual_statement.get("traceability", {}) if typeof(annual_statement.get("traceability", {})) == TYPE_DICTIONARY else {}
	lines.append("traceability=%s" % _dict_payload(traceability, [
		"post_start_enrichment_status",
		"post_start_source_story_ids",
		"post_start_source_disclosure_packet_ids",
		"post_start_source_disclosure_placement_ids",
		"post_start_source_disclosure_section_ids",
		"disclosure_packet_render_status",
		"disclosure_packet_render_visible_paragraph_count",
		"accounting_continuity_failed_count"
	]))
	return "\n".join(lines)


static func _document_contract_payload(document: Dictionary) -> String:
	var lines: Array[String] = []
	for key in [
		"schema_version",
		"source_system_id",
		"document_type",
		"document_status",
		"generation_timing",
		"cache_owner",
		"cache_key",
		"run_seed",
		"company_id",
		"fiscal_year",
		"filing_version",
		"language_id",
		"sector_style_id",
		"filing_profile_schema_version",
		"filing_profile_status",
		"filing_profile_id",
		"filing_profile_version",
		"source_state_hash",
		"filing_schema_hash",
		"accounting_footprint_hash",
		"filing_prose_hash",
		"filing_anatomy_status",
		"accounting_footprint_status",
		"filing_prose_status",
		"story_note_fact_packet_status",
		"story_note_fact_packet_hash",
		"story_note_placement_status",
		"story_note_placement_plan_hash",
		"story_note_prose_status",
		"story_note_prose_hash",
		"visible_filing_status",
		"visible_filing_hash",
		"source_statement_id",
		"page_size_hint",
		"saved_cache_allowed",
		"saved_cache_policy",
		"full_filing_generation_status"
	]:
		lines.append("%s=%s" % [key, str(document.get(key, ""))])
	lines.append("filing_sections=%s" % _filing_sections_payload(_variant_array(document.get("filing_section_schema", []))))
	lines.append("filing_toc=%s" % _filing_toc_payload(_variant_array(document.get("filing_table_of_contents", []))))
	lines.append("r3_map=%s" % _r3_source_map_payload(_variant_array(document.get("r3_source_section_map", []))))
	lines.append("footprints=%s" % _accounting_footprint_payload(_variant_array(document.get("accounting_footprint_packets", []))))
	lines.append("prose=%s" % _filing_prose_payload(_variant_array(document.get("filing_prose_packets", []))))
	lines.append("story_facts=%s" % _story_note_fact_packet_payload(_variant_array(document.get("story_note_fact_packets", []))))
	lines.append("story_placements=%s" % _story_note_placement_plan_payload(_variant_array(document.get("story_note_placement_plan", []))))
	lines.append("story_prose=%s" % _story_note_prose_payload(_variant_array(document.get("story_note_prose_packets", []))))
	lines.append("visible=%s" % _visible_filing_payload(_variant_array(document.get("visible_filing_sections", []))))
	return "\n".join(lines)


static func _disclosure_packet_refs_from_annual_statement(annual_statement: Dictionary) -> Array:
	var rows: Array = []
	for note_value in _variant_array(annual_statement.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		for packet_value in _variant_array(note.get("disclosure_packet_refs", [])):
			if typeof(packet_value) != TYPE_DICTIONARY:
				continue
			var packet: Dictionary = packet_value.duplicate(true)
			var packet_id: String = str(packet.get("packet_id", "")).strip_edges()
			if packet_id.is_empty():
				continue
			packet["source_note_id"] = str(note.get("note_id", "")).strip_edges()
			packet["source_note_number"] = int(note.get("note_number", 0))
			packet["source_note_type"] = str(note.get("note_type", "")).strip_edges()
			if str(packet.get("annual_statement_note_type", "")).strip_edges().is_empty():
				packet["annual_statement_note_type"] = str(note.get("note_type", "")).strip_edges()
			if str(packet.get("archetype_id", "")).strip_edges().is_empty():
				packet["archetype_id"] = _archetype_from_packet(packet)
			rows = _append_unique_dictionary(rows, packet, "packet_id")
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if str(left.get("story_id", "")) != str(right.get("story_id", "")):
			return str(left.get("story_id", "")) < str(right.get("story_id", ""))
		var left_priority: int = int(left.get("render_priority", 0))
		var right_priority: int = int(right.get("render_priority", 0))
		if left_priority != right_priority:
			return left_priority > right_priority
		return str(left.get("packet_id", "")) < str(right.get("packet_id", ""))
	)
	return rows


static func _footprint_types_for_packet(packet_ref: Dictionary) -> Array:
	var archetype_id: String = _archetype_from_packet(packet_ref)
	var pattern: Dictionary = _footprint_pattern(archetype_id)
	var types: Array = _variant_array(pattern.get("footprint_types", []))
	if types.is_empty():
		types = _variant_array(ARCHETYPE_FOOTPRINT_PATTERNS.get("default", {}).get("footprint_types", []))
	var section_id: String = str(packet_ref.get("section_id", "")).strip_edges()
	var note_type: String = str(packet_ref.get("annual_statement_note_type", packet_ref.get("source_note_type", ""))).strip_edges()
	if not _string_array(packet_ref.get("metric_ids", [])).is_empty():
		types = _array_with_value(types, "numeric_movement")
		types = _array_with_value(types, "statement_row_note_reference")
	types = _array_with_value(types, "note_paragraph")
	if _supports_compact_table(section_id, note_type):
		types = _array_with_value(types, "compact_table_row")
	if not _string_array(packet_ref.get("cross_reference_section_ids", [])).is_empty():
		types = _array_with_value(types, "cross_note_reference")
	if section_id == "segment_information" or note_type == "segment_information":
		types = _array_with_value(types, "segment_movement")
	if section_id == "subsequent_events" or note_type == "commitments_contingencies_and_subsequent_events":
		types = _array_with_value(types, "subsequent_event_language")
	if section_id in ["debt_and_borrowings", "related_party_transactions", "inventories", "trade_receivables"] or str(packet_ref.get("subtlety", "")) in ["conflicting", "missing"]:
		types = _array_with_value(types, "risk_management_language")
	return _valid_footprint_types(types)


static func _accounting_footprint_row(
	row_index: int,
	footprint_type: String,
	packet_ref: Dictionary,
	line_lookup: Dictionary,
	row_model_lookup: Dictionary,
	note_lookup: Dictionary,
	section_lookup: Dictionary
) -> Dictionary:
	if not ACCOUNTING_FOOTPRINT_TYPES.has(footprint_type):
		return {}
	var type_definition: Dictionary = ACCOUNTING_FOOTPRINT_TYPES.get(footprint_type, {})
	var packet_id: String = str(packet_ref.get("packet_id", "")).strip_edges()
	var story_id: String = str(packet_ref.get("story_id", "")).strip_edges()
	if packet_id.is_empty() or story_id.is_empty():
		return {}
	var archetype_id: String = _archetype_from_packet(packet_ref)
	var metric_ids: Array = _string_array(packet_ref.get("metric_ids", []))
	var statement_metrics: Array = _statement_metrics_for_packet(metric_ids, footprint_type)
	var note_type: String = _target_note_type_for_footprint(footprint_type, packet_ref)
	var filing_section_id: String = _target_filing_section_for_footprint(footprint_type, packet_ref, note_type, section_lookup, statement_metrics, line_lookup)
	var statement_sections: Array = _statement_sections_for_metrics(statement_metrics, line_lookup)
	var line_ids: Array = _line_ids_for_metrics(statement_metrics, line_lookup)
	var note_ids: Array = _note_ids_for_note_type(note_type, note_lookup)
	var note_refs: Array = _note_refs_for_metrics(statement_metrics, row_model_lookup)
	var subtlety: String = str(packet_ref.get("subtlety", "implied")).strip_edges()
	if subtlety.is_empty():
		subtlety = "implied"
	var packet_role: String = str(packet_ref.get("packet_role", "supporting_evidence")).strip_edges()
	return {
		"schema_version": ACCOUNTING_FOOTPRINT_SCHEMA_VERSION,
		"footprint_id": "footprint|%s|%02d|%s" % [packet_id, row_index, footprint_type],
		"footprint_order": row_index,
		"source_system_id": SOURCE_SYSTEM_ID,
		"footprint_type": footprint_type,
		"footprint_pattern_id": str(_footprint_pattern(archetype_id).get("pattern_id", "default")),
		"filing_section_id": filing_section_id,
		"source_disclosure_packet_id": packet_id,
		"source_disclosure_placement_id": str(packet_ref.get("placement_id", "")).strip_edges(),
		"source_disclosure_section_id": str(packet_ref.get("section_id", "")).strip_edges(),
		"story_id": story_id,
		"archetype_id": archetype_id,
		"source_note_type": note_type,
		"source_note_id": str(packet_ref.get("source_note_id", "")).strip_edges(),
		"source_note_number": int(packet_ref.get("source_note_number", 0)),
		"statement_sections": statement_sections,
		"statement_line_ids": line_ids,
		"statement_note_refs": note_refs,
		"note_ids": note_ids,
		"metric_ids": metric_ids,
		"statement_metric_ids": statement_metrics,
		"effect_ids": _string_array(packet_ref.get("effect_ids", [])),
		"fact_ids": _string_array(packet_ref.get("fact_ids", [])),
		"clue_ids": _string_array(packet_ref.get("clue_ids", [])),
		"cross_reference_section_ids": _string_array(packet_ref.get("cross_reference_section_ids", [])),
		"cross_reference_note_types": _note_types_for_disclosure_sections(packet_ref.get("cross_reference_section_ids", [])),
		"visible_label": str(type_definition.get("visible_label", footprint_type.replace("_", " ").capitalize())),
		"neutral_caption": _footprint_neutral_caption(footprint_type, note_type, filing_section_id),
		"evidence_capture_mode": str(type_definition.get("evidence_capture_mode", "")),
		"reader_effort": str(packet_ref.get("reader_effort", "medium")).strip_edges(),
		"evidence_density": str(packet_ref.get("evidence_density", "partial")).strip_edges(),
		"subtlety": subtlety,
		"fragment_role": str(packet_ref.get("fragment_role", "context")).strip_edges(),
		"packet_role": packet_role,
		"story_exposure": "complete" if subtlety == "direct" and packet_role == "primary_evidence" else "fragment",
		"reveals_trade_answer": false,
		"visible_truth_labels_allowed": false,
		"traceability_mode": "internal_source_ids_only"
	}


static func _archetype_from_packet(packet_ref: Dictionary) -> String:
	var archetype_id: String = str(packet_ref.get("archetype_id", "")).strip_edges()
	if not archetype_id.is_empty():
		return archetype_id
	var story_id: String = str(packet_ref.get("story_id", "")).strip_edges()
	var story_parts: PackedStringArray = story_id.split("|")
	if story_parts.size() >= 3:
		return str(story_parts[2]).strip_edges()
	var note_type: String = str(packet_ref.get("note_type", packet_ref.get("source_note_type", ""))).strip_edges()
	match note_type:
		"capex_progress":
			return "capex_expansion"
		"margin_bridge":
			return "margin_recovery"
		"commodity_price_realization":
			return "commodity_tailwind"
		"input_cost_pressure":
			return "commodity_headwind"
		"customer_contract":
			return "contract_win"
		"turnaround_progress":
			return "turnaround"
		"governance_note":
			return "governance_risk"
		"debt_maturity":
			return "balance_sheet_stress"
		"statement_contradiction":
			return "fraud_signal"
		"use_of_proceeds":
			return "corporate_action_use_of_proceeds"
	return "default"


static func _footprint_pattern(archetype_id: String) -> Dictionary:
	if ARCHETYPE_FOOTPRINT_PATTERNS.has(archetype_id):
		return ARCHETYPE_FOOTPRINT_PATTERNS.get(archetype_id, {}).duplicate(true)
	return ARCHETYPE_FOOTPRINT_PATTERNS.get("default", {}).duplicate(true)


static func _target_note_type_for_footprint(footprint_type: String, packet_ref: Dictionary) -> String:
	match footprint_type:
		"auditor_risk_focus":
			return "auditor_report"
		"segment_movement":
			return "segment_information"
		"risk_management_language":
			return "financial_risk_management"
		"subsequent_event_language":
			return "commitments_contingencies_and_subsequent_events"
	var note_type: String = str(packet_ref.get("annual_statement_note_type", packet_ref.get("source_note_type", ""))).strip_edges()
	if note_type.is_empty():
		note_type = _note_type_from_disclosure_section_id(str(packet_ref.get("section_id", "")))
	if note_type.is_empty():
		var pattern: Dictionary = _footprint_pattern(_archetype_from_packet(packet_ref))
		var defaults: Array = _variant_array(pattern.get("default_note_types", []))
		note_type = str(defaults.front()).strip_edges() if not defaults.is_empty() else "revenue"
	return note_type


static func _target_filing_section_for_footprint(
	footprint_type: String,
	packet_ref: Dictionary,
	note_type: String,
	section_lookup: Dictionary,
	statement_metrics: Array,
	line_lookup: Dictionary
) -> String:
	match footprint_type:
		"auditor_risk_focus":
			return "independent_auditor_report"
		"segment_movement":
			return "note_segment_information"
		"risk_management_language":
			return "note_financial_risk_management"
		"subsequent_event_language":
			return "note_non_cash_subsequent_events"
		"numeric_movement", "statement_row_note_reference":
			for metric_value in statement_metrics:
				var metric_id: String = str(metric_value)
				if line_lookup.has(metric_id):
					var line: Dictionary = line_lookup.get(metric_id, {})
					var section_id: String = str(line.get("section_id", "")).strip_edges()
					if not section_id.is_empty():
						return section_id
		"cross_note_reference":
			var cross_note_types: Array = _note_types_for_disclosure_sections(packet_ref.get("cross_reference_section_ids", []))
			for cross_note_type_value in cross_note_types:
				var cross_note_type: String = str(cross_note_type_value)
				if section_lookup.has(cross_note_type):
					return str(section_lookup.get(cross_note_type, ""))
	if section_lookup.has(note_type):
		return str(section_lookup.get(note_type, ""))
	var default_section_id: String = str(ACCOUNTING_FOOTPRINT_TYPES.get(footprint_type, {}).get("default_filing_section_id", "")).strip_edges()
	return default_section_id if not default_section_id.is_empty() else "note_revenue_expenses_tax_equity"


static func _footprint_neutral_caption(footprint_type: String, note_type: String, filing_section_id: String) -> String:
	var note_label: String = note_type.replace("_", " ").capitalize()
	var section_label: String = filing_section_id.replace("_", " ").capitalize()
	match footprint_type:
		"numeric_movement":
			return "Amount movement connected to %s." % note_label
		"statement_row_note_reference":
			return "Statement line with note reference to %s." % note_label
		"note_paragraph":
			return "Narrative paragraph in %s." % section_label
		"compact_table_row":
			return "Supporting table row in %s." % section_label
		"cross_note_reference":
			return "Reference trail across related notes."
		"auditor_risk_focus":
			return "Audit focus area for reader comparison."
		"segment_movement":
			return "Segment movement for top-down comparison."
		"risk_management_language":
			return "Risk management wording for exposure comparison."
		"subsequent_event_language":
			return "After-period wording for follow-up comparison."
	return "Filing evidence item."


static func _statement_line_lookup(annual_statement: Dictionary) -> Dictionary:
	var rows: Dictionary = {}
	for source_array in ["financial_position", "profit_or_loss_and_oci", "changes_in_equity", "cash_flows"]:
		for row_value in _variant_array(annual_statement.get(source_array, [])):
			if typeof(row_value) != TYPE_DICTIONARY:
				continue
			var row: Dictionary = row_value
			var metric_id: String = str(row.get("metric_id", row.get("id", ""))).strip_edges()
			if not metric_id.is_empty():
				rows[metric_id] = row
	return rows


static func _accounting_row_model_lookup(annual_statement: Dictionary) -> Dictionary:
	var rows: Dictionary = {}
	for row_value in _variant_array(annual_statement.get("accounting_row_model", [])):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var metric_id: String = str(row.get("metric_id", "")).strip_edges()
		if not metric_id.is_empty():
			rows[metric_id] = row
	return rows


static func _note_lookup_by_type(annual_statement: Dictionary) -> Dictionary:
	var rows: Dictionary = {}
	for note_value in _variant_array(annual_statement.get("notes", [])):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		var note_type: String = str(note.get("note_type", "")).strip_edges()
		if not note_type.is_empty():
			rows[note_type] = note
	return rows


static func _filing_section_lookup_by_note_type(filing_section_schema: Array) -> Dictionary:
	var rows: Dictionary = {}
	for section_value in filing_section_schema:
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		var section_id: String = str(section.get("section_id", "")).strip_edges()
		for note_type_value in _variant_array(section.get("source_note_types", [])):
			var note_type: String = str(note_type_value).strip_edges()
			if not note_type.is_empty() and not rows.has(note_type):
				rows[note_type] = section_id
	for note_type in [
		"related_party_transactions",
		"financial_risk_management",
		"auditor_report",
		"cost_of_revenue_and_gross_profit",
		"operating_expenses",
		"revenue",
		"cash_flow_information",
		"equity_and_dividends"
	]:
		if rows.has(note_type):
			continue
		match note_type:
			"related_party_transactions":
				rows[note_type] = "note_related_parties"
			"financial_risk_management":
				rows[note_type] = "note_financial_risk_management"
			"auditor_report":
				rows[note_type] = "independent_auditor_report"
			"cost_of_revenue_and_gross_profit", "operating_expenses", "revenue", "equity_and_dividends":
				rows[note_type] = "note_revenue_expenses_tax_equity"
			"cash_flow_information":
				rows[note_type] = "note_non_cash_subsequent_events"
	return rows


static func _statement_metrics_for_packet(metric_ids: Array, footprint_type: String) -> Array:
	var rows: Array = []
	for metric_value in metric_ids:
		var metric_id: String = _statement_metric_for_packet_metric(str(metric_value))
		if not metric_id.is_empty():
			rows = _array_with_value(rows, metric_id)
	if rows.is_empty() and footprint_type in ["numeric_movement", "statement_row_note_reference"]:
		rows.append("revenue")
	return rows


static func _statement_metric_for_packet_metric(metric_id: String) -> String:
	match metric_id:
		"gross_margin":
			return "gross_profit"
		"operating_margin":
			return "operating_income"
		"debt":
			return "debt_and_borrowings"
		"capex":
			return "purchase_of_ppe"
		"working_capital":
			return "working_capital_changes"
		"inventory":
			return "inventories"
		"receivables":
			return "trade_receivables"
		"customer_concentration":
			return "trade_receivables"
		"backlog":
			return "revenue"
		"production_volume":
			return "revenue"
		_:
			return metric_id


static func _statement_sections_for_metrics(metric_ids: Array, line_lookup: Dictionary) -> Array:
	var rows: Array = []
	for metric_value in metric_ids:
		var metric_id: String = str(metric_value)
		if not line_lookup.has(metric_id):
			continue
		var line: Dictionary = line_lookup.get(metric_id, {})
		rows = _array_with_value(rows, str(line.get("section_id", "")))
	return rows


static func _line_ids_for_metrics(metric_ids: Array, line_lookup: Dictionary) -> Array:
	var rows: Array = []
	for metric_value in metric_ids:
		var metric_id: String = str(metric_value)
		if not line_lookup.has(metric_id):
			continue
		var line: Dictionary = line_lookup.get(metric_id, {})
		rows = _array_with_value(rows, str(line.get("line_id", "")))
	return rows


static func _note_refs_for_metrics(metric_ids: Array, row_model_lookup: Dictionary) -> Array:
	var rows: Array = []
	for metric_value in metric_ids:
		var metric_id: String = str(metric_value)
		if not row_model_lookup.has(metric_id):
			continue
		var model: Dictionary = row_model_lookup.get(metric_id, {})
		rows = _array_with_value(rows, str(model.get("note_ref", "")))
	return rows


static func _note_ids_for_note_type(note_type: String, note_lookup: Dictionary) -> Array:
	if note_lookup.has(note_type):
		return [str(note_lookup.get(note_type, {}).get("note_id", ""))]
	return []


static func _note_types_for_disclosure_sections(section_ids: Variant) -> Array:
	var rows: Array = []
	for section_value in _variant_array(section_ids):
		rows = _array_with_value(rows, _note_type_from_disclosure_section_id(str(section_value)))
	return rows


static func _note_type_from_disclosure_section_id(section_id: String) -> String:
	if section_id in [
		"revenue",
		"cost_of_revenue_and_gross_profit",
		"operating_expenses",
		"segment_information",
		"cash_and_cash_equivalents",
		"trade_receivables",
		"inventories",
		"property_plant_and_equipment",
		"debt_and_borrowings",
		"equity_and_dividends",
		"cash_flow_information",
		"related_party_transactions",
		"commitments_contingencies_and_subsequent_events"
	]:
		return section_id
	if section_id.contains("receivable"):
		return "trade_receivables"
	if section_id.contains("inventory"):
		return "inventories"
	if section_id.contains("related"):
		return "related_party_transactions"
	if section_id.contains("ppe") or section_id.contains("capex") or section_id.contains("plant"):
		return "property_plant_and_equipment"
	if section_id.contains("debt") or section_id.contains("borrowing"):
		return "debt_and_borrowings"
	if section_id.contains("cash_flow") or section_id.contains("cashflow"):
		return "cash_flow_information"
	if section_id.contains("segment"):
		return "segment_information"
	if section_id.contains("revenue") or section_id.contains("customer"):
		return "revenue"
	if section_id.contains("commitment") or section_id.contains("contingenc") or section_id.contains("subsequent"):
		return "commitments_contingencies_and_subsequent_events"
	return ""


static func _supports_compact_table(section_id: String, note_type: String) -> bool:
	return section_id in ["trade_receivables", "inventories", "property_plant_and_equipment", "debt_and_borrowings", "segment_information", "related_party_transactions"] or note_type in ["trade_receivables", "inventories", "property_plant_and_equipment", "debt_and_borrowings", "segment_information", "related_party_transactions"]


static func _valid_footprint_types(source_value: Variant) -> Array:
	var rows: Array = []
	for type_value in _variant_array(source_value):
		var footprint_type: String = str(type_value).strip_edges()
		if ACCOUNTING_FOOTPRINT_TYPES.has(footprint_type):
			rows = _array_with_value(rows, footprint_type)
	return rows


static func _footprint_type_order(footprint_type: String) -> int:
	var types: Array = [
		"numeric_movement",
		"statement_row_note_reference",
		"note_paragraph",
		"compact_table_row",
		"cross_note_reference",
		"auditor_risk_focus",
		"segment_movement",
		"risk_management_language",
		"subsequent_event_language"
	]
	var index: int = types.find(footprint_type)
	return index if index >= 0 else 999


static func _accounting_footprint_type_counts(footprints: Array) -> Dictionary:
	var counts: Dictionary = {}
	for row_value in footprints:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var footprint_type: String = str(row.get("footprint_type", "")).strip_edges()
		if footprint_type.is_empty():
			continue
		counts[footprint_type] = int(counts.get(footprint_type, 0)) + 1
	return counts


static func _accounting_footprint_story_counts(footprints: Array) -> Dictionary:
	var counts: Dictionary = {}
	for row_value in footprints:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var story_id: String = str(row.get("story_id", "")).strip_edges()
		if story_id.is_empty():
			continue
		counts[story_id] = int(counts.get(story_id, 0)) + 1
	return counts


static func _accounting_footprint_payload(rows: Array) -> String:
	var lines: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("%d:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [
			int(row.get("footprint_order", 0)),
			str(row.get("footprint_type", "")),
			str(row.get("footprint_pattern_id", "")),
			str(row.get("filing_section_id", "")),
			str(row.get("source_disclosure_packet_id", "")),
			str(row.get("source_disclosure_placement_id", "")),
			str(row.get("source_disclosure_section_id", "")),
			str(row.get("story_id", "")),
			str(row.get("archetype_id", "")),
			str(row.get("source_note_type", "")),
			_array_payload(row.get("statement_sections", [])),
			_array_payload(row.get("statement_line_ids", [])),
			_array_payload(row.get("note_ids", [])),
			_array_payload(row.get("metric_ids", [])),
			_array_payload(row.get("cross_reference_section_ids", [])),
			str(row.get("subtlety", "")),
			str(row.get("story_exposure", ""))
		])
	return ";".join(lines)


static func _filing_prose_role_counts(prose_rows: Array) -> Dictionary:
	var counts: Dictionary = {}
	for row_value in prose_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var role: String = str(row.get("paragraph_role", "")).strip_edges()
		if role.is_empty():
			continue
		counts[role] = int(counts.get(role, 0)) + 1
	return counts


static func _filing_prose_section_counts(prose_rows: Array) -> Dictionary:
	var counts: Dictionary = {}
	for row_value in prose_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var section_id: String = str(row.get("filing_section_id", "")).strip_edges()
		if section_id.is_empty():
			continue
		counts[section_id] = int(counts.get(section_id, 0)) + 1
	return counts


static func _visible_filing_profile_balance(filing_profile_id: String, visible_sections: Array) -> Dictionary:
	var profile_id: String = _resolved_filing_profile_id(filing_profile_id)
	var target: Dictionary = _visible_balance_target_for_profile(profile_id)
	var paragraph_count: int = 0
	var note_paragraph_count: int = 0
	var story_note_paragraph_count: int = 0
	var table_count: int = 0
	var table_row_count: int = 0
	var cross_reference_count: int = 0
	var display_block_count: int = 0
	for section_value in visible_sections:
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		var section_paragraph_count: int = _variant_array(section.get("paragraphs", [])).size()
		paragraph_count += section_paragraph_count
		if str(section.get("document_part", "")) == "notes":
			for paragraph_value in _variant_array(section.get("paragraphs", [])):
				if typeof(paragraph_value) != TYPE_DICTIONARY:
					continue
				var paragraph: Dictionary = paragraph_value
				if STORY_NOTE_PROSE_ROLES.has(str(paragraph.get("paragraph_role", ""))):
					story_note_paragraph_count += 1
				else:
					note_paragraph_count += 1
		for table_value in _variant_array(section.get("compact_tables", [])):
			if typeof(table_value) != TYPE_DICTIONARY:
				continue
			var table: Dictionary = table_value
			table_count += 1
			table_row_count += _variant_array(table.get("rows", [])).size()
		cross_reference_count += _variant_array(section.get("cross_references", [])).size()
		display_block_count += _variant_array(section.get("display_blocks", [])).size()
	var ratio_denominator: int = max(note_paragraph_count, 1)
	var actual_ratio: float = float(table_count) / float(ratio_denominator)
	var min_ratio: float = float(target.get("min_table_to_note_prose_ratio", 0.0))
	return {
		"filing_profile_id": profile_id,
		"assembly_priority": VISIBLE_FILING_ASSEMBLY_PRIORITY.duplicate(true),
		"paragraph_count": paragraph_count,
		"note_paragraph_count": note_paragraph_count,
		"story_note_paragraph_count": story_note_paragraph_count,
		"table_count": table_count,
		"table_row_count": table_row_count,
		"cross_reference_count": cross_reference_count,
		"display_block_count": display_block_count,
		"target_table_to_note_prose_ratio": min_ratio,
		"actual_table_to_note_prose_ratio": actual_ratio,
		"target_met": actual_ratio >= min_ratio
	}


static func _visible_balance_target_for_profile(filing_profile_id: String) -> Dictionary:
	var profile_id: String = _resolved_filing_profile_id(filing_profile_id)
	if VISIBLE_FILING_PROFILE_BALANCE_TARGETS.has(profile_id):
		return VISIBLE_FILING_PROFILE_BALANCE_TARGETS.get(profile_id, {}).duplicate(true)
	return VISIBLE_FILING_PROFILE_BALANCE_TARGETS.get(DEFAULT_FILING_PROFILE_ID, {}).duplicate(true)


static func _build_visible_filing_sections(
	annual_statement: Dictionary,
	schema_rows: Array,
	prose_rows: Array,
	footprint_rows: Array
) -> Array:
	var prose_by_section: Dictionary = _filing_prose_by_section(prose_rows)
	var footprints_by_section: Dictionary = _footprints_by_section(footprint_rows)
	var line_lookup: Dictionary = _statement_line_lookup(annual_statement)
	var note_lookup: Dictionary = _note_lookup_by_type(annual_statement)
	var rows: Array = []
	for section_value in schema_rows:
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var source_section: Dictionary = section_value
		var section_id: String = str(source_section.get("section_id", "")).strip_edges()
		if section_id.is_empty():
			continue
		var section: Dictionary = _visible_section_base(source_section, rows.size() + 1)
		var compact_tables: Array = _visible_compact_tables_for_section(section_id, footprints_by_section, line_lookup, note_lookup, annual_statement)
		var cross_references: Array = []
		var raw_paragraphs: Array = _visible_paragraphs_for_section(section_id, prose_by_section)
		var paragraphs: Array = _limited_visible_paragraphs_for_section(source_section, raw_paragraphs, compact_tables, cross_references)
		section["paragraphs"] = paragraphs
		section["compact_tables"] = compact_tables
		section["cross_references"] = cross_references
		section["display_blocks"] = _visible_display_blocks_for_section(section, compact_tables, cross_references, paragraphs)
		if str(source_section.get("document_part", "")) == "primary_statement":
			var source_array: String = str(source_section.get("source_array", section_id)).strip_edges()
			section["statement_rows"] = _variant_array(annual_statement.get(source_array, []))
		if not _visible_section_should_materialize(source_section, section):
			continue
		rows.append(section)
	return rows


static func _visible_section_base(source_section: Dictionary, fallback_order: int) -> Dictionary:
	var section_order: int = int(source_section.get("section_order", fallback_order))
	var title: String = _visible_section_title(source_section)
	return {
		"schema_version": VISIBLE_FILING_SCHEMA_VERSION,
		"visible_filing_status": VISIBLE_FILING_STATUS,
		"section_id": str(source_section.get("section_id", "")).strip_edges(),
		"section_order": section_order,
		"section_number": str(section_order),
		"title": title,
		"filing_title": title,
		"localized_title": "",
		"page_label": str(source_section.get("page_label", "")).strip_edges(),
		"document_part": str(source_section.get("document_part", "")).strip_edges(),
		"read_mode": str(source_section.get("read_mode", "")).strip_edges(),
		"source_section_id": str(source_section.get("source_section_id", "")).strip_edges(),
		"source_array": str(source_section.get("source_array", "")).strip_edges(),
		"source_note_types": _string_array(source_section.get("source_note_types", [])),
		"clue_density": str(source_section.get("clue_density", "")).strip_edges(),
		"boilerplate_density": str(source_section.get("boilerplate_density", "")).strip_edges(),
		"evidence_capture_mode": str(source_section.get("evidence_capture_mode", "")).strip_edges(),
		"virtual_page_group": str(source_section.get("virtual_page_group", "")).strip_edges(),
		"supports_capture": bool(source_section.get("supports_capture", false)),
		"purpose": str(source_section.get("purpose", "")).strip_edges()
	}


static func _visible_section_title(source_section: Dictionary) -> String:
	var title: String = str(source_section.get("filing_title", source_section.get("title", ""))).strip_edges()
	if str(source_section.get("document_part", "")).strip_edges() == "notes" and title.begins_with("Notes - "):
		return title.trim_prefix("Notes - ").strip_edges()
	return title


static func _visible_section_should_materialize(source_section: Dictionary, section: Dictionary) -> bool:
	var section_id: String = str(section.get("section_id", source_section.get("section_id", ""))).strip_edges()
	var document_part: String = str(section.get("document_part", source_section.get("document_part", ""))).strip_edges()
	if section_id == "table_of_contents":
		return true
	if document_part == "primary_statement":
		return true
	if document_part == "front_matter":
		return section_id == "cover"
	if not _variant_array(section.get("compact_tables", [])).is_empty():
		return true
	if not _variant_array(section.get("cross_references", [])).is_empty():
		return true
	for paragraph_value in _variant_array(section.get("paragraphs", [])):
		if typeof(paragraph_value) != TYPE_DICTIONARY:
			continue
		var paragraph: Dictionary = paragraph_value
		if STORY_NOTE_PROSE_ROLES.has(str(paragraph.get("paragraph_role", ""))):
			return true
	return false


static func _visible_section_report_map_row(section: Dictionary) -> Dictionary:
	return {
		"schema_version": int(section.get("schema_version", VISIBLE_FILING_SCHEMA_VERSION)),
		"section_id": str(section.get("section_id", "")),
		"section_order": int(section.get("section_order", 0)),
		"section_number": str(section.get("section_number", "")),
		"title": str(section.get("title", "")),
		"filing_title": str(section.get("filing_title", "")),
		"localized_title": "",
		"page_label": str(section.get("page_label", "")),
		"document_part": str(section.get("document_part", "")),
		"read_mode": str(section.get("read_mode", "")),
		"source_array": str(section.get("source_array", "")),
		"evidence_capture_mode": str(section.get("evidence_capture_mode", "")),
		"virtual_page_group": str(section.get("virtual_page_group", "")),
		"supports_capture": bool(section.get("supports_capture", false))
	}


static func _filing_prose_by_section(prose_rows: Array) -> Dictionary:
	var rows: Dictionary = {}
	for row_value in prose_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var section_id: String = str(row.get("filing_section_id", "")).strip_edges()
		if section_id.is_empty():
			continue
		var section_rows: Array = _variant_array(rows.get(section_id, []))
		section_rows.append(row.duplicate(true))
		rows[section_id] = section_rows
	for section_key in rows.keys():
		var section_rows: Array = _variant_array(rows.get(section_key, []))
		section_rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
			return int(left.get("paragraph_order", 0)) < int(right.get("paragraph_order", 0))
		)
		rows[section_key] = section_rows
	return rows


static func _visible_paragraphs_for_section(section_id: String, prose_by_section: Dictionary) -> Array:
	var rows: Array = []
	var row_index_by_text: Dictionary = {}
	var order: int = 1
	for prose_value in _variant_array(prose_by_section.get(section_id, [])):
		if typeof(prose_value) != TYPE_DICTIONARY:
			continue
		var prose: Dictionary = prose_value
		var text: String = str(prose.get("visible_text", "")).strip_edges()
		if text.is_empty():
			continue
		var text_key: String = text.to_lower()
		if row_index_by_text.has(text_key):
			var existing_index: int = int(row_index_by_text.get(text_key, -1))
			if existing_index >= 0 and existing_index < rows.size():
				var existing_row: Dictionary = rows[existing_index]
				_merge_visible_paragraph_sources(existing_row, prose)
				existing_row["deduped_source_count"] = int(existing_row.get("deduped_source_count", 1)) + 1
				rows[existing_index] = existing_row
			continue
		var row: Dictionary = {
			"paragraph_id": str(prose.get("paragraph_id", "visible_paragraph|%s|%03d" % [section_id, order])),
			"paragraph_index": order,
			"paragraph_order": int(prose.get("paragraph_order", order)),
			"paragraph_role": str(prose.get("paragraph_role", "")),
			"template_type": str(prose.get("template_type", "")),
			"clue_density": str(prose.get("clue_density", "")),
			"boilerplate_density": str(prose.get("boilerplate_density", "")),
			"text": text,
			"source_footprint_ids": _string_array(prose.get("source_footprint_ids", [])),
			"source_disclosure_packet_ids": _string_array(prose.get("source_disclosure_packet_ids", [])),
			"source_story_ids": _string_array(prose.get("source_story_ids", [])),
			"source_story_note_fact_ids": _string_array(prose.get("source_story_note_fact_ids", [])),
			"statement_line_ids": _string_array(prose.get("statement_line_ids", [])),
			"note_ids": _string_array(prose.get("note_ids", [])),
			"footprint_type": str(prose.get("footprint_type", "")),
			"visible_truth_labels_allowed": false,
			"hidden_source_ids_visible": false,
			"deduped_source_count": 1
		}
		row_index_by_text[text_key] = rows.size()
		rows.append(row)
		order += 1
	return rows


static func _merge_visible_paragraph_sources(target: Dictionary, prose: Dictionary) -> void:
	_merge_unique_array_field(target, "source_footprint_ids", prose.get("source_footprint_ids", []))
	_merge_unique_array_field(target, "source_disclosure_packet_ids", prose.get("source_disclosure_packet_ids", []))
	_merge_unique_array_field(target, "source_story_ids", prose.get("source_story_ids", []))
	_merge_unique_array_field(target, "source_story_note_fact_ids", prose.get("source_story_note_fact_ids", []))
	_merge_unique_array_field(target, "statement_line_ids", prose.get("statement_line_ids", []))
	_merge_unique_array_field(target, "note_ids", prose.get("note_ids", []))


static func _limited_visible_paragraphs_for_section(
	source_section: Dictionary,
	raw_paragraphs: Array,
	compact_tables: Array,
	cross_references: Array
) -> Array:
	if raw_paragraphs.is_empty():
		return []
	var profile_id: String = _resolved_filing_profile_id(str(source_section.get("filing_profile_id", DEFAULT_FILING_PROFILE_ID)))
	var document_part: String = str(source_section.get("document_part", "")).strip_edges()
	var target: Dictionary = _visible_balance_target_for_profile(profile_id)
	var max_count: int = int(target.get("max_note_paragraphs_without_tables", 2))
	match document_part:
		"front_matter":
			max_count = int(target.get("max_front_matter_paragraphs", 2))
		"primary_statement":
			max_count = int(target.get("max_primary_statement_paragraphs", 1))
		"notes":
			if not compact_tables.is_empty():
				max_count = int(target.get("max_note_paragraphs_with_tables", 1))
			elif not cross_references.is_empty():
				max_count = int(target.get("max_note_paragraphs_without_tables", 2))
	if max_count <= 0:
		return []
	var ordered: Array = raw_paragraphs.duplicate(true)
	ordered.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_priority: int = _visible_paragraph_priority(left)
		var right_priority: int = _visible_paragraph_priority(right)
		if left_priority != right_priority:
			return left_priority < right_priority
		return int(left.get("paragraph_order", 0)) < int(right.get("paragraph_order", 0))
	)
	var rows: Array = []
	for paragraph_value in ordered:
		if typeof(paragraph_value) != TYPE_DICTIONARY:
			continue
		if rows.size() >= max_count:
			break
		rows.append(paragraph_value)
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("paragraph_order", 0)) < int(right.get("paragraph_order", 0))
	)
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		row["paragraph_index"] = index + 1
		row["visible_paragraph_limit_applied"] = raw_paragraphs.size() > rows.size()
		row["source_paragraph_count_before_limit"] = raw_paragraphs.size()
		rows[index] = row
	return rows


static func _visible_paragraph_priority(paragraph: Dictionary) -> int:
	var role: String = str(paragraph.get("paragraph_role", "")).strip_edges()
	var footprint_type: String = str(paragraph.get("footprint_type", "")).strip_edges()
	if role in STORY_NOTE_PROSE_ROLES:
		return -1
	if role == "routine_boilerplate":
		return 0
	if role == "estimate_context":
		return 1
	if footprint_type in ["auditor_risk_focus", "risk_management_language", "subsequent_event_language"]:
		return 2
	if not _string_array(paragraph.get("source_footprint_ids", [])).is_empty():
		return 3
	return 4


static func _visible_display_blocks_for_section(section: Dictionary, compact_tables: Array, cross_references: Array, paragraphs: Array) -> Array:
	var section_id: String = str(section.get("section_id", "")).strip_edges()
	var blocks: Array = []
	var block_order: int = 1
	for table_index in range(compact_tables.size()):
		var table: Dictionary = compact_tables[table_index] if typeof(compact_tables[table_index]) == TYPE_DICTIONARY else {}
		if table.is_empty():
			continue
		blocks.append(_visible_display_block_row(section_id, block_order, "compact_table", str(table.get("table_id", "")), table_index, "note_table"))
		block_order += 1
	for reference_index in range(cross_references.size()):
		var reference: Dictionary = cross_references[reference_index] if typeof(cross_references[reference_index]) == TYPE_DICTIONARY else {}
		if reference.is_empty():
			continue
		blocks.append(_visible_display_block_row(section_id, block_order, "cross_reference", str(reference.get("cross_reference_id", "")), reference_index, "note_reference"))
		block_order += 1
	for paragraph_index in range(paragraphs.size()):
		var paragraph: Dictionary = paragraphs[paragraph_index] if typeof(paragraphs[paragraph_index]) == TYPE_DICTIONARY else {}
		if paragraph.is_empty():
			continue
		var block_kind: String = "formal_lead_in" if str(paragraph.get("paragraph_role", "")) in ["routine_boilerplate", "estimate_context"] else "limited_prose"
		blocks.append(_visible_display_block_row(section_id, block_order, "paragraph", str(paragraph.get("paragraph_id", "")), paragraph_index, block_kind))
		block_order += 1
	return blocks


static func _visible_display_block_row(
	section_id: String,
	block_order: int,
	block_type: String,
	source_id: String,
	source_index: int,
	block_kind: String
) -> Dictionary:
	return {
		"block_id": "visible_block|%s|%03d" % [section_id, block_order],
		"block_order": block_order,
		"block_type": block_type,
		"block_kind": block_kind,
		"source_id": source_id,
		"source_index": source_index,
		"assembly_priority": VISIBLE_FILING_ASSEMBLY_PRIORITY.duplicate(true)
	}


static func _visible_compact_tables_for_section(
	section_id: String,
	footprints_by_section: Dictionary,
	line_lookup: Dictionary,
	note_lookup: Dictionary,
	annual_statement: Dictionary
) -> Array:
	var tables: Array = _bank_compact_tables_for_section(section_id, line_lookup, note_lookup, annual_statement)
	var table_rows: Array = []
	for footprint_value in _variant_array(footprints_by_section.get(section_id, [])):
		if typeof(footprint_value) != TYPE_DICTIONARY:
			continue
		var footprint: Dictionary = footprint_value
		if str(footprint.get("footprint_type", "")) != "compact_table_row":
			continue
		var line: Dictionary = _first_line_for_footprint(footprint, line_lookup)
		var caption: String = str(line.get("label", footprint.get("neutral_caption", ""))).strip_edges()
		if caption.is_empty():
			caption = "Selected amount"
		table_rows.append({
			"caption": caption,
			"fy_value": _line_amount_text(line, annual_statement),
			"related_note": "",
			"source_footprint_id": str(footprint.get("footprint_id", "")),
			"source_footprint_ids": _string_array([str(footprint.get("footprint_id", ""))]),
			"source_disclosure_packet_id": str(footprint.get("source_disclosure_packet_id", "")),
			"source_disclosure_packet_ids": _string_array([str(footprint.get("source_disclosure_packet_id", ""))]),
			"statement_line_ids": _string_array(footprint.get("statement_line_ids", [])),
			"note_ids": _string_array(footprint.get("note_ids", [])),
			"deduped_source_count": 1
			})
	if table_rows.is_empty() and section_id == "note_segment_information":
		table_rows = _default_segment_compact_table_rows(line_lookup, note_lookup, annual_statement)
	table_rows = _dedupe_visible_table_rows(table_rows)
	if not table_rows.is_empty():
		tables.append({
			"table_id": "visible_table|%s|selected_amounts" % section_id,
			"title": "Selected annual amounts",
			"rows": table_rows
		})
	return tables


static func _bank_compact_tables_for_section(
	section_id: String,
	line_lookup: Dictionary,
	note_lookup: Dictionary,
	annual_statement: Dictionary
) -> Array:
	if not _is_bank_filing_section_id(section_id):
		return []
	var total_assets: float = max(_line_value_for_metric(line_lookup, "total_assets", 0.0), 1.0)
	var cash: float = max(_line_value_for_metric(line_lookup, "cash", total_assets * 0.08), total_assets * 0.03)
	var equity: float = max(_line_value_for_metric(line_lookup, "equity", total_assets * 0.12), total_assets * 0.05)
	var total_liabilities: float = max(_line_value_for_metric(line_lookup, "total_liabilities", total_assets - equity), total_assets * 0.55)
	var revenue: float = max(_line_value_for_metric(line_lookup, "revenue", total_assets * 0.09), 1.0)
	var finance_income: float = max(_line_value_for_metric(line_lookup, "finance_income", revenue * 0.08), revenue * 0.02)
	var finance_cost: float = absf(_line_value_for_metric(line_lookup, "finance_cost", revenue * 0.04))
	var net_income: float = max(_line_value_for_metric(line_lookup, "net_income", revenue * 0.12), 0.0)
	var loans: float = max(_line_value_for_metric(line_lookup, "trade_receivables", total_assets * 0.58), total_assets * 0.38)
	var deposits: float = max(total_liabilities * _bank_ratio(annual_statement, "deposits", 0.72, 0.86), loans * 0.88)
	var securities: float = max(total_assets * _bank_ratio(annual_statement, "securities", 0.10, 0.18), cash * 0.80)
	var placements: float = max(total_assets * _bank_ratio(annual_statement, "placements", 0.05, 0.12), cash * 0.35)
	var allowance_rate: float = _bank_ratio(annual_statement, "allowance_rate", 0.022, 0.058)
	var allowance: float = max(loans * allowance_rate, 1.0)
	var risk_weighted_assets: float = max(loans * _bank_ratio(annual_statement, "rwa", 0.95, 1.22), total_assets * 0.48)
	var car_ratio: float = _safe_ratio(equity, risk_weighted_assets, 0.16) * 100.0
	var note_label: String = _bank_section_note_label(section_id)
	match section_id:
		"note_bank_cash_reserves":
			return [
				_bank_table(section_id, "Cash and reserve balances", [
					_bank_table_row("Cash on hand and teller cash", cash * 0.10, note_label, annual_statement, "bank_cash_on_hand", ["cash"]),
					_bank_table_row("Current accounts with Bank Indonesia", cash * 0.48, note_label, annual_statement, "bank_central_bank_reserve", ["cash"]),
					_bank_table_row("Current accounts with other banks", cash * 0.42, note_label, annual_statement, "bank_other_bank_current_accounts", ["cash"])
				])
			]
		"note_bank_placements":
			return [
				_bank_table(section_id, "Placements by counterparty", [
					_bank_table_row("Placements with Bank Indonesia", placements * 0.52, note_label, annual_statement, "bank_placements_bi", ["cash"]),
					_bank_table_row("Placements with domestic banks", placements * 0.33, note_label, annual_statement, "bank_placements_domestic", ["cash"]),
					_bank_table_row("Placements with overseas banks", placements * 0.15, note_label, annual_statement, "bank_placements_overseas", ["cash"])
				])
			]
		"note_bank_securities":
			return [
				_bank_table(section_id, "Securities by class", [
					_bank_table_row("Government bonds", securities * 0.58, note_label, annual_statement, "bank_securities_government", []),
					_bank_table_row("Corporate bonds", securities * 0.24, note_label, annual_statement, "bank_securities_corporate", []),
					_bank_table_row("Securities measured at fair value", securities * 0.18, note_label, annual_statement, "bank_securities_fair_value", [])
				])
			]
		"note_bank_loans_financing":
			return [
				_bank_table(section_id, "Loans by credit stage", [
					_bank_table_row("Stage 1 performing loans", loans * 0.82, note_label, annual_statement, "bank_loans_stage_1", ["trade_receivables"]),
					_bank_table_row("Stage 2 watchlist loans", loans * 0.12, note_label, annual_statement, "bank_loans_stage_2", ["trade_receivables"]),
					_bank_table_row("Stage 3 impaired loans", loans * 0.06, note_label, annual_statement, "bank_loans_stage_3", ["trade_receivables"])
				]),
				_bank_table(section_id, "Loans by product type", [
					_bank_table_row("Working capital loans", loans * 0.44, note_label, annual_statement, "bank_loans_working_capital", ["trade_receivables"]),
					_bank_table_row("Investment loans", loans * 0.31, note_label, annual_statement, "bank_loans_investment", ["trade_receivables"]),
					_bank_table_row("Consumer and payroll loans", loans * 0.25, note_label, annual_statement, "bank_loans_consumer_payroll", ["trade_receivables"])
				]),
				_bank_table(section_id, "Loans by economic sector", [
					_bank_table_row("Trading, services, and SME", loans * 0.30, note_label, annual_statement, "bank_loans_trading_services_sme", ["trade_receivables"]),
					_bank_table_row("Manufacturing and industrial", loans * 0.24, note_label, annual_statement, "bank_loans_manufacturing", ["trade_receivables"]),
					_bank_table_row("Property and construction", loans * 0.18, note_label, annual_statement, "bank_loans_property", ["trade_receivables"]),
					_bank_table_row("Consumer and other sectors", loans * 0.28, note_label, annual_statement, "bank_loans_consumer_other", ["trade_receivables"])
				])
			]
		"note_bank_allowance_impairment":
			return [
				_bank_table(section_id, "Allowance movement by stage", [
					_bank_table_row("Stage 1 allowance", allowance * 0.26, note_label, annual_statement, "bank_allowance_stage_1", ["trade_receivables"]),
					_bank_table_row("Stage 2 allowance", allowance * 0.31, note_label, annual_statement, "bank_allowance_stage_2", ["trade_receivables"]),
					_bank_table_row("Stage 3 allowance", allowance * 0.43, note_label, annual_statement, "bank_allowance_stage_3", ["trade_receivables"]),
					_bank_table_row("Total allowance for impairment losses", allowance, note_label, annual_statement, "bank_allowance_total", ["trade_receivables"])
				])
			]
		"note_bank_deposits":
			return [
				_bank_table(section_id, "Deposits by type", [
					_bank_table_row("Demand deposits", deposits * 0.25, note_label, annual_statement, "bank_deposits_demand", ["debt_and_borrowings"]),
					_bank_table_row("Savings deposits", deposits * 0.29, note_label, annual_statement, "bank_deposits_savings", ["debt_and_borrowings"]),
					_bank_table_row("Time deposits", deposits * 0.40, note_label, annual_statement, "bank_deposits_time", ["debt_and_borrowings"]),
					_bank_table_row("Deposits from other banks", deposits * 0.06, note_label, annual_statement, "bank_deposits_other_banks", ["debt_and_borrowings"])
				]),
				_bank_table(section_id, "Deposits by party", [
					_bank_table_row("Third-party customer deposits", deposits * 0.93, note_label, annual_statement, "bank_deposits_third_party", ["debt_and_borrowings"]),
					_bank_table_row("Related-party deposits", deposits * 0.04, note_label, annual_statement, "bank_deposits_related_party", ["debt_and_borrowings"]),
					_bank_table_row("Interbank funding", deposits * 0.03, note_label, annual_statement, "bank_deposits_interbank", ["debt_and_borrowings"])
				])
			]
		"note_bank_temporary_syirkah_funds":
			var syirkah: float = deposits * _bank_ratio(annual_statement, "syirkah", 0.00, 0.16)
			return [
				_bank_table(section_id, "Temporary syirkah funds by product", [
					_bank_table_row("Mudharabah savings", syirkah * 0.32, note_label, annual_statement, "bank_syirkah_savings", ["debt_and_borrowings"]),
					_bank_table_row("Mudharabah time deposits", syirkah * 0.58, note_label, annual_statement, "bank_syirkah_time_deposits", ["debt_and_borrowings"]),
					_bank_table_row("Restricted investment accounts", syirkah * 0.10, note_label, annual_statement, "bank_syirkah_restricted", ["debt_and_borrowings"])
				])
			]
		"note_bank_interest_income":
			return [
				_bank_table(section_id, "Interest and sharia income by source", [
					_bank_table_row("Loans and sharia financing income", revenue * 0.69, note_label, annual_statement, "bank_interest_income_loans", ["revenue"]),
					_bank_table_row("Securities income", max(finance_income, revenue * 0.06), note_label, annual_statement, "bank_interest_income_securities", ["finance_income"]),
					_bank_table_row("Placements with banks", revenue * 0.07, note_label, annual_statement, "bank_interest_income_placements", ["finance_income"]),
					_bank_table_row("Fees and commissions", revenue * 0.18, note_label, annual_statement, "bank_fee_commission_income", ["revenue"])
				])
			]
		"note_bank_related_parties":
			return [
				_bank_table(section_id, "Related-party bank balances", [
					_bank_table_row("Loans to related parties", loans * 0.035, note_label, annual_statement, "bank_related_party_loans", ["trade_receivables"]),
					_bank_table_row("Deposits from related parties", deposits * 0.040, note_label, annual_statement, "bank_related_party_deposits", ["debt_and_borrowings"]),
					_bank_table_row("Key management compensation", max(net_income * 0.018, revenue * 0.002), note_label, annual_statement, "bank_related_party_management", ["general_admin_expenses"])
				])
			]
		"note_bank_capital_adequacy":
			return [
				_bank_table(section_id, "Capital adequacy and risk-weighted assets", [
					_bank_table_row("Core capital", equity * 0.82, note_label, annual_statement, "bank_core_capital", ["equity"]),
					_bank_table_row("Risk-weighted assets", risk_weighted_assets, note_label, annual_statement, "bank_risk_weighted_assets", ["total_assets"]),
					_bank_table_row("Capital adequacy ratio", car_ratio, note_label, annual_statement, "bank_car_ratio", ["equity"], "percent")
				])
			]
		"note_bank_credit_risk":
			return [
				_bank_table(section_id, "Credit risk quality indicators", [
					_bank_table_row("Current and performing exposure", loans * 0.82, note_label, annual_statement, "bank_credit_current", ["trade_receivables"]),
					_bank_table_row("Special mention exposure", loans * 0.12, note_label, annual_statement, "bank_credit_special_mention", ["trade_receivables"]),
					_bank_table_row("Non-performing exposure", loans * 0.06, note_label, annual_statement, "bank_credit_non_performing", ["trade_receivables"]),
					_bank_table_row("Allowance coverage of impaired exposure", _safe_ratio(allowance, loans * 0.06, 0.7) * 100.0, note_label, annual_statement, "bank_credit_coverage", ["trade_receivables"], "percent")
				])
			]
		"note_bank_liquidity_risk":
			return [
				_bank_table(section_id, "Contractual maturity of financial liabilities", [
					_bank_table_row("Due within 1 month", deposits * 0.32, note_label, annual_statement, "bank_liquidity_one_month", ["debt_and_borrowings"]),
					_bank_table_row("Due over 1-3 months", deposits * 0.24, note_label, annual_statement, "bank_liquidity_three_months", ["debt_and_borrowings"]),
					_bank_table_row("Due over 3-12 months", deposits * 0.29, note_label, annual_statement, "bank_liquidity_twelve_months", ["debt_and_borrowings"]),
					_bank_table_row("Due over 1 year", deposits * 0.15, note_label, annual_statement, "bank_liquidity_over_year", ["debt_and_borrowings"])
				])
			]
		"note_bank_regulatory_compliance":
			return [
				_bank_table(section_id, "Regulatory reserve and compliance indicators", [
					_bank_table_row("Primary statutory reserve", deposits * 0.065, note_label, annual_statement, "bank_primary_reserve", ["cash"]),
					_bank_table_row("Macroprudential liquidity buffer", securities * 0.24, note_label, annual_statement, "bank_macroprudential_buffer", []),
					_bank_table_row("Net open position ratio", _bank_ratio(annual_statement, "nop", 0.6, 4.8), note_label, annual_statement, "bank_net_open_position", [], "percent")
				])
			]
	return []


static func _default_segment_compact_table_rows(line_lookup: Dictionary, note_lookup: Dictionary, annual_statement: Dictionary) -> Array:
	var rows: Array = []
	var metric_specs: Array = [
		["revenue", "revenue"],
		["gross_profit", "cost_of_revenue_and_gross_profit"],
		["property_plant_equipment", "property_plant_and_equipment"]
	]
	for spec_value in metric_specs:
		var spec: Array = spec_value
		var metric_id: String = str(spec[0])
		if not line_lookup.has(metric_id):
			continue
		var line: Dictionary = line_lookup.get(metric_id, {}) if typeof(line_lookup.get(metric_id, {})) == TYPE_DICTIONARY else {}
		if line.is_empty():
			continue
		rows.append({
			"caption": str(line.get("label", metric_id.replace("_", " ").capitalize())),
			"fy_value": _line_amount_text(line, annual_statement),
			"related_note": "",
			"source_footprint_id": "default_segment_amount|%s" % metric_id,
			"source_footprint_ids": _string_array(["default_segment_amount|%s" % metric_id]),
			"source_disclosure_packet_id": "",
			"source_disclosure_packet_ids": [],
			"statement_line_ids": _string_array([str(line.get("line_id", ""))]),
			"note_ids": [],
			"deduped_source_count": 1
		})
	return rows


static func _is_bank_filing_section_id(section_id: String) -> bool:
	return section_id.strip_edges().begins_with("note_bank_")


static func _bank_table(section_id: String, table_title: String, rows: Array) -> Dictionary:
	return {
		"table_id": "visible_table|%s|%s" % [section_id, _cache_token(table_title)],
		"title": table_title,
		"rows": _dedupe_visible_table_rows(rows)
	}


static func _bank_table_row(
	caption: String,
	value: float,
	related_note: String,
	annual_statement: Dictionary,
	source_id: String,
	statement_metric_ids: Array = [],
	format_id: String = "currency"
) -> Dictionary:
	return {
		"row_id": source_id,
		"caption": caption,
		"fy_value": _bank_row_value_text(value, annual_statement, format_id),
		"related_note": "",
		"source_footprint_id": "bank_profile_table|%s" % source_id,
		"source_footprint_ids": _string_array(["bank_profile_table|%s" % source_id]),
		"source_disclosure_packet_id": "",
		"source_disclosure_packet_ids": [],
		"statement_line_ids": _string_array(statement_metric_ids),
		"note_ids": [],
		"deduped_source_count": 1,
		"filing_profile_id": "bank",
		"bank_table_model": true
	}


static func _bank_row_value_text(value: float, annual_statement: Dictionary, format_id: String) -> String:
	match format_id:
		"percent", "percentage":
			return "%.2f%%" % value
		"ratio":
			return "%.2f" % value
	return _amount_label(value, "currency", annual_statement)


static func _bank_section_note_label(section_id: String) -> String:
	match section_id:
		"note_bank_cash_reserves":
			return "Cash and statutory reserves"
		"note_bank_placements":
			return "Placements with Bank Indonesia and other banks"
		"note_bank_securities":
			return "Marketable securities"
		"note_bank_loans_financing":
			return "Loans and sharia financing"
		"note_bank_allowance_impairment":
			return "Allowance for impairment losses"
		"note_bank_deposits":
			return "Deposits from customers and other banks"
		"note_bank_temporary_syirkah_funds":
			return "Temporary syirkah funds"
		"note_bank_interest_income":
			return "Interest income and sharia income"
		"note_bank_related_parties":
			return "Related party transactions"
		"note_bank_capital_adequacy":
			return "Capital adequacy"
		"note_bank_credit_risk":
			return "Credit risk"
		"note_bank_liquidity_risk":
			return "Liquidity risk"
		"note_bank_regulatory_compliance":
			return "Regulatory reserves and compliance"
	return section_id.replace("_", " ").capitalize()


static func _line_value_for_metric(line_lookup: Dictionary, metric_id: String, fallback_value: float = 0.0) -> float:
	var safe_metric_id: String = metric_id.strip_edges()
	if safe_metric_id.is_empty() or not line_lookup.has(safe_metric_id):
		return fallback_value
	var line: Dictionary = line_lookup.get(safe_metric_id, {}) if typeof(line_lookup.get(safe_metric_id, {})) == TYPE_DICTIONARY else {}
	return float(line.get("value", fallback_value))


static func _bank_ratio(annual_statement: Dictionary, salt: String, min_value: float, max_value: float) -> float:
	var low: float = min(min_value, max_value)
	var high: float = max(min_value, max_value)
	var seed_text: String = "%s|%s|%s|%s" % [
		str(annual_statement.get("statement_id", "")),
		str(annual_statement.get("company_id", "")),
		str(annual_statement.get("fiscal_year", "")),
		salt
	]
	var hash_value: int = int(_stable_hash(seed_text))
	var normalized: float = float(hash_value % 10000) / 10000.0
	return low + (high - low) * normalized


static func _safe_ratio(numerator: float, denominator: float, fallback_value: float = 0.0) -> float:
	if is_zero_approx(denominator):
		return fallback_value
	return numerator / denominator


static func _dedupe_visible_table_rows(source_rows: Array) -> Array:
	var rows: Array = []
	var row_index_by_key: Dictionary = {}
	for row_value in source_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var key: String = "%s|%s|%s" % [
			str(row.get("caption", "")).strip_edges().to_lower(),
			str(row.get("fy_value", "")).strip_edges().to_lower(),
			str(row.get("related_note", "")).strip_edges().to_lower()
		]
		if row_index_by_key.has(key):
			var existing_index: int = int(row_index_by_key.get(key, -1))
			if existing_index >= 0 and existing_index < rows.size():
				var existing_row: Dictionary = rows[existing_index]
				_merge_unique_array_field(existing_row, "source_footprint_ids", row.get("source_footprint_ids", []))
				_merge_unique_array_field(existing_row, "source_footprint_ids", str(row.get("source_footprint_id", "")))
				_merge_unique_array_field(existing_row, "source_disclosure_packet_ids", row.get("source_disclosure_packet_ids", []))
				_merge_unique_array_field(existing_row, "source_disclosure_packet_ids", str(row.get("source_disclosure_packet_id", "")))
				_merge_unique_array_field(existing_row, "statement_line_ids", row.get("statement_line_ids", []))
				_merge_unique_array_field(existing_row, "note_ids", row.get("note_ids", []))
				existing_row["deduped_source_count"] = int(existing_row.get("deduped_source_count", 1)) + int(row.get("deduped_source_count", 1))
				rows[existing_index] = existing_row
			continue
		row_index_by_key[key] = rows.size()
		rows.append(row.duplicate(true))
	return rows


static func _visible_cross_references_for_section(
	section_id: String,
	footprints_by_section: Dictionary,
	note_lookup: Dictionary
) -> Array:
	var rows: Array = []
	var row_index_by_display_key: Dictionary = {}
	var reference_index: int = 1
	for footprint_value in _variant_array(footprints_by_section.get(section_id, [])):
		if typeof(footprint_value) != TYPE_DICTIONARY:
			continue
		var footprint: Dictionary = footprint_value
		if str(footprint.get("footprint_type", "")) != "cross_note_reference":
			continue
		var target_labels: Array[String] = []
		for note_type_value in _string_array(footprint.get("cross_reference_note_types", [])):
			var label: String = _note_label(str(note_type_value), note_lookup)
			if not label.is_empty() and not target_labels.has(label):
				target_labels.append(label)
		if target_labels.is_empty():
			var source_label: String = _note_label(str(footprint.get("source_note_type", "")), note_lookup)
			if not source_label.is_empty():
				target_labels.append(source_label)
		var display_text: String = _visible_cross_reference_text(section_id, target_labels)
		var target_note_types: Array = _string_array(footprint.get("cross_reference_note_types", []))
		var display_key: String = "%s|%s" % [display_text.to_lower(), _array_payload(target_note_types)]
		if row_index_by_display_key.has(display_key):
			var existing_index: int = int(row_index_by_display_key.get(display_key, -1))
			if existing_index >= 0 and existing_index < rows.size():
				var existing_row: Dictionary = rows[existing_index]
				_merge_unique_array_field(existing_row, "source_footprint_ids", str(footprint.get("footprint_id", "")))
				_merge_unique_array_field(existing_row, "source_disclosure_packet_ids", str(footprint.get("source_disclosure_packet_id", "")))
				_merge_unique_array_field(existing_row, "source_story_ids", str(footprint.get("story_id", "")))
				_merge_unique_array_field(existing_row, "target_note_ids", footprint.get("note_ids", []))
				existing_row["deduped_source_count"] = int(existing_row.get("deduped_source_count", 1)) + 1
				rows[existing_index] = existing_row
			continue
		var source_footprint_id: String = str(footprint.get("footprint_id", ""))
		var source_packet_id: String = str(footprint.get("source_disclosure_packet_id", ""))
		var source_story_id: String = str(footprint.get("story_id", ""))
		var row: Dictionary = {
			"cross_reference_id": "visible_cross_reference|%s|%03d" % [section_id, reference_index],
			"display_text": display_text,
			"source_footprint_id": source_footprint_id,
			"source_footprint_ids": [source_footprint_id] if not source_footprint_id.is_empty() else [],
			"source_disclosure_packet_id": source_packet_id,
			"source_disclosure_packet_ids": [source_packet_id] if not source_packet_id.is_empty() else [],
			"source_story_id": source_story_id,
			"source_story_ids": [source_story_id] if not source_story_id.is_empty() else [],
			"target_note_types": target_note_types,
			"target_note_ids": _string_array(footprint.get("note_ids", [])),
			"deduped_source_count": 1
		}
		row_index_by_display_key[display_key] = rows.size()
		rows.append(row)
		reference_index += 1
	return rows


static func _visible_cross_reference_text(section_id: String, target_labels: Array) -> String:
	var joined_labels: String = ", ".join(_string_array(target_labels))
	if joined_labels.is_empty():
		joined_labels = "related notes in the consolidated financial statements"
	if _is_bank_filing_section_id(section_id):
		match section_id:
			"note_bank_cash_reserves", "note_bank_placements", "note_bank_securities":
				return "Bank liquidity and treasury balances connect to %s." % joined_labels
			"note_bank_loans_financing", "note_bank_allowance_impairment":
				return "Loan rows connect to %s." % joined_labels
			"note_bank_deposits", "note_bank_temporary_syirkah_funds":
				return "Funding rows connect to %s." % joined_labels
			"note_bank_capital_adequacy":
				return "Capital ratio rows connect to %s." % joined_labels
			"note_bank_credit_risk":
				return "Credit-risk disclosures connect to %s." % joined_labels
			"note_bank_liquidity_risk":
				return "Liquidity maturity rows connect to %s." % joined_labels
			"note_bank_regulatory_compliance":
				return "Regulatory reserve disclosures connect to %s." % joined_labels
		return "Banking note rows connect to %s." % joined_labels
	match section_id:
		"note_segment_information":
			return "Segment rows reconcile to %s." % joined_labels
		"note_related_parties":
			return "Related-party balances connect to %s." % joined_labels
		"note_financial_risk_management":
			return "Risk-management disclosures draw on %s." % joined_labels
		"note_commitments_contingencies":
			return "Commitment and contingency rows connect to %s." % joined_labels
		"note_non_cash_subsequent_events":
			return "Subsequent-event and non-cash activity rows connect to %s." % joined_labels
	return "Related note rows connect to %s." % joined_labels


static func _visible_generation_sources(
	annual_statement: Dictionary,
	contract: Dictionary,
	options: Dictionary
) -> Dictionary:
	var traceability: Dictionary = annual_statement.get("traceability", {}) if typeof(annual_statement.get("traceability", {})) == TYPE_DICTIONARY else {}
	return {
		"generation_mode": "on_button_request",
		"annual_statement_payload": true,
		"company_profile": not str(options.get("company_name", annual_statement.get("company_name", ""))).strip_edges().is_empty(),
		"story_dossier_packet_count": _variant_array(contract.get("accounting_footprint_packets", [])).size(),
		"story_note_fact_packet_count": _variant_array(contract.get("story_note_fact_packets", [])).size(),
		"story_note_placement_plan_count": _variant_array(contract.get("story_note_placement_plan", [])).size(),
		"story_note_placement_plan_hash": str(contract.get("story_note_placement_plan_hash", "")),
		"story_note_prose_packet_count": _variant_array(contract.get("story_note_prose_packets", [])).size(),
		"story_note_prose_hash": str(contract.get("story_note_prose_hash", "")),
		"living_arc_state": not _string_array(traceability.get("post_start_source_story_ids", [])).is_empty(),
		"corporate_action_event_roadmap_state": not _string_array(traceability.get("post_start_source_disclosure_packet_ids", [])).is_empty(),
		"macro_commodity_state": typeof(annual_statement.get("macro_context", {})) == TYPE_DICTIONARY and not annual_statement.get("macro_context", {}).is_empty(),
		"filing_profile_id": str(contract.get("filing_profile_id", DEFAULT_FILING_PROFILE_ID)),
		"filing_profile_version": str(contract.get("filing_profile_version", FILING_PROFILE_VERSION)),
		"saved_to_run_state": false
	}


static func _filing_prose_payload(rows: Array) -> String:
	var lines: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("%d:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [
			int(row.get("paragraph_order", 0)),
			str(row.get("paragraph_id", "")),
			str(row.get("filing_section_id", "")),
			str(row.get("template_type", "")),
			str(row.get("paragraph_role", "")),
			str(row.get("clue_density", "")),
			str(row.get("boilerplate_density", "")),
			str(row.get("sector_style_id", "")),
			_array_payload(row.get("source_footprint_ids", [])),
			_array_payload(row.get("source_disclosure_packet_ids", [])),
			_array_payload(row.get("source_story_ids", [])),
			_array_payload(row.get("statement_line_ids", [])),
			str(row.get("visible_text", ""))
		])
	return ";".join(lines)


static func _visible_filing_payload(rows: Array) -> String:
	var lines: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = row_value
		lines.append("section:%d:%s:%s:%s:%s:%s:%s:%s:%s" % [
			int(section.get("section_order", 0)),
			str(section.get("section_id", "")),
			str(section.get("document_part", "")),
			str(section.get("title", "")),
			str(section.get("page_label", "")),
			str(section.get("read_mode", "")),
			_variant_array(section.get("paragraphs", [])).size(),
			_variant_array(section.get("compact_tables", [])).size(),
			_variant_array(section.get("display_blocks", [])).size()
		])
		for block_value in _variant_array(section.get("display_blocks", [])):
			if typeof(block_value) != TYPE_DICTIONARY:
				continue
			var block: Dictionary = block_value
			lines.append("block:%s:%d:%s:%s:%s:%s" % [
				str(block.get("block_id", "")),
				int(block.get("block_order", 0)),
				str(block.get("block_type", "")),
				str(block.get("block_kind", "")),
				str(block.get("source_id", "")),
				int(block.get("source_index", -1))
			])
		for paragraph_value in _variant_array(section.get("paragraphs", [])):
			if typeof(paragraph_value) != TYPE_DICTIONARY:
				continue
			var paragraph: Dictionary = paragraph_value
			lines.append("paragraph:%s:%d:%s:%s:%s:%s" % [
				str(paragraph.get("paragraph_id", "")),
				int(paragraph.get("paragraph_index", 0)),
				str(paragraph.get("paragraph_role", "")),
				str(paragraph.get("clue_density", "")),
				_array_payload(paragraph.get("source_footprint_ids", [])),
				str(paragraph.get("text", ""))
			])
		for table_value in _variant_array(section.get("compact_tables", [])):
			if typeof(table_value) != TYPE_DICTIONARY:
				continue
			var table: Dictionary = table_value
			lines.append("table:%s:%s:%s" % [
				str(table.get("table_id", "")),
				str(table.get("title", "")),
				_visible_table_payload(_variant_array(table.get("rows", [])))
			])
		for reference_value in _variant_array(section.get("cross_references", [])):
			if typeof(reference_value) != TYPE_DICTIONARY:
				continue
			var reference: Dictionary = reference_value
			lines.append("xref:%s:%s:%s:%s" % [
				str(reference.get("cross_reference_id", "")),
				str(reference.get("display_text", "")),
				str(reference.get("source_footprint_id", "")),
				_array_payload(reference.get("target_note_types", []))
			])
	return "\n".join(lines)


static func _visible_table_payload(rows: Array) -> String:
	var lines: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("%s:%s:%s:%s" % [
			str(row.get("caption", "")),
			str(row.get("fy_value", "")),
			str(row.get("related_note", "")),
			str(row.get("source_footprint_id", ""))
		])
	return "|".join(lines)


static func _source_sections_by_id(annual_statement: Dictionary) -> Dictionary:
	var rows: Dictionary = {}
	for row_value in _variant_array(annual_statement.get("annual_report_section_map", [])):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var section_id: String = str(row.get("section_id", "")).strip_edges()
		if not section_id.is_empty():
			rows[section_id] = row
	return rows


static func _page_label(row: Dictionary) -> String:
	var explicit_label: String = str(row.get("page_label", "")).strip_edges()
	if not explicit_label.is_empty():
		return explicit_label
	var page_start: int = int(row.get("page_start", 0))
	var page_end: int = int(row.get("page_end", 0))
	if page_start <= 0 and page_end <= 0:
		return ""
	if page_start <= 0:
		page_start = page_end
	if page_end <= 0:
		page_end = page_start
	if page_start == page_end:
		return str(page_start)
	return "%d-%d" % [page_start, page_end]


static func _append_unique(target: Array, source_value: Variant) -> void:
	var text: String = str(source_value).strip_edges()
	if text.is_empty() or target.has(text):
		return
	target.append(text)


static func _merge_unique_array_field(target: Dictionary, target_key: String, source_value: Variant) -> void:
	var rows: Array = _variant_array(target.get(target_key, []))
	if typeof(source_value) == TYPE_ARRAY:
		for item_value in source_value:
			_append_unique(rows, item_value)
	else:
		_append_unique(rows, source_value)
	target[target_key] = rows


static func _filing_schema_payload(section_schema: Array, table_of_contents: Array, r3_source_map: Array) -> String:
	return "\n".join([
		"version=%d" % FILING_ANATOMY_SCHEMA_VERSION,
		"status=%s" % FILING_ANATOMY_STATUS,
		"sections=%s" % _filing_sections_payload(section_schema),
		"toc=%s" % _filing_toc_payload(table_of_contents),
		"r3_map=%s" % _r3_source_map_payload(r3_source_map)
	])


static func _filing_sections_payload(rows: Array) -> String:
	var lines: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("%d:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [
			int(row.get("section_order", 0)),
			str(row.get("section_id", "")),
			str(row.get("document_part", "")),
			str(row.get("filing_title", "")),
			str(row.get("localized_title", "")),
			str(row.get("page_label", "")),
			str(row.get("source_section_id", "")),
			str(row.get("source_array", "")),
			str(row.get("read_mode", "")),
			str(row.get("clue_density", "")),
			str(row.get("boilerplate_density", "")),
			str(row.get("evidence_capture_mode", "")),
			str(row.get("virtual_page_group", "")),
			str(row.get("supports_capture", "")),
			_array_payload(row.get("source_note_types", []))
		])
	return ";".join(lines)


static func _filing_toc_payload(rows: Array) -> String:
	var lines: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("%d:%s:%s:%s:%s:%s" % [
			int(row.get("section_order", 0)),
			str(row.get("section_id", "")),
			str(row.get("document_part", "")),
			str(row.get("filing_title", "")),
			str(row.get("page_label", "")),
			str(row.get("virtual_page_group", ""))
		])
	return ";".join(lines)


static func _r3_source_map_payload(rows: Array) -> String:
	var lines: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("%s:%s:%s:%s:%s" % [
			str(row.get("source_section_id", "")),
			str(row.get("mapping_role", "")),
			_array_payload(row.get("filing_section_ids", [])),
			_array_payload(row.get("source_arrays", [])),
			_array_payload(row.get("note_type_filters", []))
		])
	return ";".join(lines)


static func _section_payload(rows: Array) -> String:
	var lines: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("%s:%s:%s:%s:%s" % [
			str(row.get("section_id", "")),
			str(row.get("section_number", "")),
			str(row.get("page_label", "")),
			str(row.get("page_start", "")),
			str(row.get("page_end", ""))
		])
	return ";".join(lines)


static func _statement_rows_payload(rows: Array) -> String:
	var lines: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("%s:%s:%s:%s" % [
			str(row.get("id", row.get("line_id", ""))),
			str(row.get("note_number", "")),
			str(row.get("value", "")),
			str(row.get("comparative_value", ""))
		])
	return ";".join(lines)


static func _notes_payload(rows: Array) -> String:
	var lines: Array[String] = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		lines.append("%s:%s:%s:%s:%s:%s" % [
			str(row.get("note_number", "")),
			str(row.get("note_type", "")),
			str(row.get("body_text_key", "")),
			_array_payload(row.get("disclosure_packet_refs", [])),
			_array_payload(row.get("source_disclosure_packet_ids", [])),
			str(_variant_array(row.get("cross_note_references", [])).size())
		])
	return ";".join(lines)


static func _dict_payload(source: Dictionary, keys: Array) -> String:
	var lines: Array[String] = []
	for key_value in keys:
		var key: String = str(key_value)
		var value: Variant = source.get(key, "")
		if typeof(value) == TYPE_ARRAY:
			lines.append("%s=[%s]" % [key, _array_payload(value)])
		else:
			lines.append("%s=%s" % [key, str(value)])
	return ";".join(lines)


static func _array_payload(source_value: Variant) -> String:
	var values: Array[String] = []
	for item_value in _variant_array(source_value):
		var text: String = str(item_value).strip_edges()
		if not text.is_empty() and not values.has(text):
			values.append(text)
	values.sort()
	return "|".join(values)


static func _string_array(source_value: Variant) -> Array:
	var rows: Array = []
	for item_value in _variant_array(source_value):
		rows = _array_with_value(rows, str(item_value))
	return rows


static func _array_with_value(source_array: Array, source_value: Variant) -> Array:
	var rows: Array = source_array.duplicate(true)
	var text: String = str(source_value).strip_edges()
	if not text.is_empty() and not rows.has(text):
		rows.append(text)
	return rows


static func _append_unique_dictionary(source_array: Array, source_row: Dictionary, id_key: String) -> Array:
	var rows: Array = source_array.duplicate(true)
	var source_id: String = str(source_row.get(id_key, "")).strip_edges()
	if source_id.is_empty():
		return rows
	for row_value in rows:
		if typeof(row_value) == TYPE_DICTIONARY and str(row_value.get(id_key, "")).strip_edges() == source_id:
			return rows
	rows.append(source_row.duplicate(true))
	return rows


static func _variant_array(source_value: Variant) -> Array:
	if typeof(source_value) == TYPE_ARRAY:
		return source_value.duplicate(true)
	return []


static func _cache_token(value: Variant) -> String:
	var text: String = str(value).strip_edges()
	if text.is_empty():
		return "none"
	text = text.replace("|", "_")
	text = text.replace(" ", "_")
	text = text.replace("/", "_")
	text = text.replace("\\", "_")
	return text


static func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int(hash_value ^ text.unicode_at(index))
		hash_value = int((hash_value * 16777619) & 0x7fffffff)
	return str(hash_value)
