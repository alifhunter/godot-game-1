extends Node

signal day_started(day_index)
signal price_formed(day_index)
signal portfolio_changed
signal advance_day_portfolio_valued
signal watchlist_changed
signal network_changed
signal social_changed
signal upgrades_changed
signal daily_actions_changed
signal academy_changed
@warning_ignore("unused_signal") # emitted by ThesisManager via gm.
signal thesis_changed
signal life_changed
signal summary_ready(summary)
signal broker_flow_generated(day_index)
signal run_started
signal run_loaded
signal run_loading_started(difficulty_id)
signal run_loading_progress(stage_id, stage_label, stage_index, stage_count, progress_ratio)
signal run_loading_detail_updated(subprogress_text, log_lines)
signal run_loading_finished
signal company_detail_ready(company_id)

const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"
const GAME_SCENE := "res://scenes/game/GameRoot.tscn"
const IDX_PRICE_RULES = preload("res://systems/IDXPriceRules.gd")
const STABLE_RNG = preload("res://systems/StableRng.gd")
const BANK_LOAN_SYSTEM = preload("res://systems/BankLoanSystem.gd")
const DEFAULT_DIFFICULTY_ID := "normal"
const STARTING_CASH := 100000000.0
const CONSOLE_CASH_GRANT_AMOUNT := 999999999999.0
const PLAYER_MAJOR_SHAREHOLDER_THRESHOLD := 0.05
const PLAYER_CONTROL_SHAREHOLDER_THRESHOLD := 0.50
const THESIS_REPORT_ACTION_COST := 7
const BROKER_RANGE_CATALOG := [
	{"id": "1d", "label": "1D", "days": 1},
	{"id": "5d", "label": "5D", "days": 5},
	{"id": "1m", "label": "1M", "days": 22},
	{"id": "3m", "label": "3M", "days": 66},
	{"id": "6m", "label": "6M", "days": 126},
	{"id": "ytd", "label": "YTD", "days": -1},
	{"id": "1y", "label": "1Y", "days": 252}
]
const BROKER_RANGE_TOP_ROW_COUNT := 10
const GOVERNANCE_CONTROL_ACTIONS := [
	{
		"id": "rights_issue",
		"label": "Rights Issue",
		"detail": "Raise capital through record-date shareholder entitlements."
	},
	{
		"id": "private_placement",
		"label": "Private Placement",
		"detail": "Place new shares with a targeted strategic investor."
	},
	{
		"id": "stock_buyback",
		"label": "Stock Buyback",
		"detail": "Ask shareholders to approve a buyback mandate."
	},
	{
		"id": "stock_split",
		"label": "Stock Split",
		"detail": "Reset share count and reference price through split terms."
	},
	{
		"id": "strategic_merger_acquisition",
		"label": "Strategic M&A",
		"detail": "Put a strategic acquisition or cash-out proposal to shareholders."
	},
	{
		"id": "backdoor_listing",
		"label": "Backdoor Listing",
		"detail": "Propose a control-change and asset-injection agenda."
	},
	{
		"id": "restructuring",
		"label": "Restructuring",
		"detail": "Put a balance-sheet rescue package to shareholders."
	},
	{
		"id": "ceo_change",
		"label": "CEO Change",
		"detail": "Propose a leadership slate and execution reset."
	}
]
const DEBUG_CORPORATE_ACTION_GENERATOR_GROUPS := [
	{
		"id": "rupslb",
		"label": "Selected Stock RUPSLB",
		"generators": [
			{
				"id": "rights_issue_rupslb",
				"label": "Start RUPSLB",
				"full_label": "Rights Issue RUPSLB",
				"method": "debug_schedule_next_day_rights_issue_rupslb",
				"mode": "rupslb",
				"requires_holding": true,
				"requires_no_live_chain": true,
				"description": "Schedule a next-day rights issue RUPSLB for the selected held stock."
			},
			{
				"id": "private_placement_rupslb",
				"label": "Private Placement",
				"full_label": "Private Placement RUPSLB",
				"method": "debug_schedule_next_day_private_placement_rupslb",
				"mode": "rupslb",
				"requires_holding": true,
				"requires_no_live_chain": true,
				"description": "Schedule a next-day private placement RUPSLB for the selected held stock."
			},
			{
				"id": "stock_buyback_rupslb",
				"label": "Buyback",
				"full_label": "Stock Buyback RUPSLB",
				"method": "debug_schedule_next_day_stock_buyback_rupslb",
				"mode": "rupslb",
				"requires_holding": true,
				"requires_no_live_chain": true,
				"description": "Schedule a next-day stock buyback RUPSLB for the selected held stock."
			},
			{
				"id": "stock_split_rupslb",
				"label": "Split",
				"full_label": "Stock Split RUPSLB",
				"method": "debug_schedule_next_day_stock_split_rupslb",
				"mode": "rupslb",
				"requires_holding": true,
				"requires_no_live_chain": true,
				"description": "Schedule a next-day stock split RUPSLB for the selected held stock."
			},
			{
				"id": "tender_offer_rupslb",
				"label": "Tender Offer",
				"full_label": "Tender Offer RUPSLB",
				"method": "debug_schedule_next_day_tender_offer_rupslb",
				"mode": "rupslb",
				"requires_holding": true,
				"requires_no_live_chain": true,
				"description": "Schedule a next-day tender offer RUPSLB for the selected held stock."
			},
			{
				"id": "strategic_mna_rupslb",
				"label": "Strategic M&A",
				"full_label": "Strategic M&A RUPSLB",
				"method": "debug_schedule_next_day_strategic_mna_rupslb",
				"mode": "rupslb",
				"requires_holding": true,
				"requires_no_live_chain": true,
				"description": "Schedule a next-day strategic M&A RUPSLB for the selected held stock."
			},
			{
				"id": "backdoor_listing_rupslb",
				"label": "Backdoor Listing",
				"full_label": "Backdoor Listing RUPSLB",
				"method": "debug_schedule_next_day_backdoor_listing_rupslb",
				"mode": "rupslb",
				"requires_holding": true,
				"requires_no_live_chain": true,
				"description": "Schedule a next-day backdoor listing RUPSLB for the selected held stock."
			},
			{
				"id": "restructuring_rupslb",
				"label": "Restructuring",
				"full_label": "Restructuring RUPSLB",
				"method": "debug_schedule_next_day_restructuring_rupslb",
				"mode": "rupslb",
				"requires_holding": true,
				"requires_no_live_chain": true,
				"description": "Schedule a next-day restructuring RUPSLB for the selected held stock."
			},
			{
				"id": "ceo_change_rupslb",
				"label": "CEO Change",
				"full_label": "CEO Change RUPSLB",
				"method": "debug_schedule_next_day_ceo_change_rupslb",
				"mode": "rupslb",
				"requires_holding": true,
				"requires_no_live_chain": true,
				"description": "Schedule a next-day CEO-change RUPSLB for the selected held stock."
			}
		]
	},
	{
		"id": "dividend",
		"label": "Selected Stock Dividends",
		"generators": [
			{
				"id": "cash_dividend",
				"label": "Cash Dividend",
				"full_label": "Cash Dividend",
				"method": "debug_schedule_next_day_cash_dividend",
				"mode": "dividend",
				"requires_holding": false,
				"requires_no_live_chain": false,
				"description": "Schedule a debug cash dividend for the selected stock."
			},
			{
				"id": "stock_dividend",
				"label": "Stock Dividend",
				"full_label": "Stock Dividend",
				"method": "debug_schedule_next_day_stock_dividend",
				"mode": "dividend",
				"requires_holding": false,
				"requires_no_live_chain": false,
				"description": "Schedule a debug stock dividend for the selected stock."
			}
		]
	},
	{
		"id": "execution",
		"label": "Selected Stock Force Execution",
		"generators": [
			{
				"id": "stock_buyback_execution",
				"label": "Execute Buyback",
				"full_label": "Stock Buyback Execution",
				"method": "debug_force_stock_buyback_execution",
				"mode": "execution",
				"requires_holding": false,
				"requires_no_live_chain": true,
				"description": "Force a stock buyback chain directly into execution for the selected stock."
			},
			{
				"id": "stock_split_execution",
				"label": "Execute Split",
				"full_label": "Stock Split Execution",
				"method": "debug_force_stock_split_execution",
				"mode": "execution",
				"requires_holding": false,
				"requires_no_live_chain": true,
				"description": "Force a stock split chain directly into execution for the selected stock."
			},
			{
				"id": "tender_offer_execution",
				"label": "Execute Tender",
				"full_label": "Tender Offer Execution",
				"method": "debug_force_tender_offer_execution",
				"mode": "execution",
				"requires_holding": false,
				"requires_no_live_chain": true,
				"description": "Force a tender offer chain directly into execution for the selected stock."
			},
			{
				"id": "strategic_mna_execution",
				"label": "Execute M&A",
				"full_label": "Strategic M&A Execution",
				"method": "debug_force_strategic_mna_execution",
				"mode": "execution",
				"requires_holding": false,
				"requires_no_live_chain": true,
				"description": "Force a strategic M&A chain directly into execution for the selected stock."
			},
			{
				"id": "backdoor_listing_execution",
				"label": "Execute Backdoor",
				"full_label": "Backdoor Listing Execution",
				"method": "debug_force_backdoor_listing_execution",
				"mode": "execution",
				"requires_holding": false,
				"requires_no_live_chain": true,
				"description": "Force a backdoor listing chain directly into execution for the selected stock."
			},
			{
				"id": "restructuring_execution",
				"label": "Execute Restructure",
				"full_label": "Restructuring Execution",
				"method": "debug_force_restructuring_execution",
				"mode": "execution",
				"requires_holding": false,
				"requires_no_live_chain": true,
				"description": "Force a restructuring chain directly into execution for the selected stock."
			},
			{
				"id": "ceo_change_execution",
				"label": "Execute CEO",
				"full_label": "CEO Change Execution",
				"method": "debug_force_ceo_change_execution",
				"mode": "execution",
				"requires_holding": false,
				"requires_no_live_chain": true,
				"description": "Force a CEO-change chain directly into execution for the selected stock."
			}
		]
	}
]
const DEBUG_COMPANY_ROADMAP_GENERATOR_GROUPS := [
	{
		"id": "selected_stock_roadmap",
		"label": "Selected Stock Roadmap",
		"generators": [
			{
				"id": "roadmap_primary",
				"label": "Primary Milestone",
				"full_label": "Primary Roadmap Milestone",
				"description": "Start the selected stock's generated roadmap priority as a public business event."
			},
			{
				"id": "roadmap_physical",
				"label": "Physical Project",
				"full_label": "Physical Roadmap Project",
				"description": "Start a sector-compatible physical site project and push explicit city/theme metadata into property intel."
			},
			{
				"id": "roadmap_financing",
				"label": "Financing Arc",
				"full_label": "Roadmap Financing Arc",
				"description": "Start a large roadmap milestone that seeks a generated finance-sector partner when one is eligible."
			},
			{
				"id": "roadmap_corporate_funding",
				"label": "Funding Action",
				"full_label": "Roadmap Corporate Funding",
				"description": "Start a large roadmap milestone that requests a corporate-action funding route."
			}
		]
	}
]
const DEBUG_LIFE_DEVELOPMENT_GENERATOR_GROUPS := [
	{
		"id": "life_property_intel",
		"label": "Life Property Intel",
		"generators": [
			{
				"id": "life_bekasi_modern_city",
				"label": "Bekasi Modern City",
				"location_id": "bekasi",
				"theme": "modern_city",
				"impact_tier": "major",
				"source_type": "network",
				"outcome_override": "confirmed_big",
				"description": "Create a high-impact Bekasi property watch that will confirm when processed."
			},
			{
				"id": "life_karawang_industrial",
				"label": "Karawang Industrial",
				"location_id": "karawang",
				"theme": "industrial_estate",
				"impact_tier": "major",
				"source_type": "news",
				"outcome_override": "",
				"description": "Create a Karawang industrial-estate property watch."
			},
			{
				"id": "life_surabaya_port_delay",
				"label": "Surabaya Port Delay",
				"location_id": "surabaya",
				"theme": "port_logistics",
				"impact_tier": "major",
				"source_type": "news",
				"outcome_override": "delayed",
				"description": "Create a Surabaya port/logistics property watch that delays on resolution."
			},
			{
				"id": "life_bandung_toll_cancel",
				"label": "Bandung Toll Cancel",
				"location_id": "bandung",
				"theme": "toll_exit",
				"impact_tier": "moderate",
				"source_type": "network",
				"outcome_override": "cancelled",
				"description": "Create a Bandung toll-exit property watch that cancels on resolution."
			}
		]
	}
]
const DEBUG_COMPANY_ARC_EVENT_IDS := {
	"earnings_beat": true,
	"earnings_miss": true,
	"strategic_acquisition": true,
	"integration_overhang": true
}
const DIFFICULTY_ORDER := ["chill", "normal", "grind"]
const NEW_RUN_FINAL_STEP_HOLD_SECONDS := 0.08
const NEW_RUN_LOADING_STEPS := [
	{"id": "seed", "label": "Preparing market seed"},
	{"id": "companies", "label": "Creating companies"},
	{"id": "financials", "label": "Creating financials"},
	{"id": "corporate_actions", "label": "Preparing corporate calendar"},
	{"id": "opening_day", "label": "Simulating opening session"},
	{"id": "save", "label": "Saving run"},
	{"id": "launch", "label": "Opening trading desk"}
]
const NETWORK_ACTION_COSTS := {
	"meet": 1,
	"tip": 2,
	"request": 1,
	"referral": 2,
	"followup": 1,
	"source_check": 1
}
const LIFE_BASIC_EXPENSES_MONTHLY := 2250000.0
const LIFE_EMERGENCY_LOAN_MINIMUM := 1000000.0
const LIFE_EMERGENCY_LOAN_EQUITY_CAP_PCT := 0.35
const LIFE_EMERGENCY_LOAN_MONTHLY_OUTFLOW_CAP := 4.0
const LIFE_EMERGENCY_LOAN_PAYMENT_COUNT := 6
const LIFE_EMERGENCY_LOAN_REPAYMENT_MULTIPLIER := 1.24
const LIFE_BASICS_TIERS := [
	{
		"id": "bare",
		"label": "Bare minimum",
		"monthly_cost": 1250000.0,
		"stress_delta": 3.0,
		"happiness_delta": -3.0,
		"detail": "Cheapest survival setup. Saves cash, but pressure builds quickly."
	},
	{
		"id": "lean",
		"label": "Lean",
		"monthly_cost": 1750000.0,
		"stress_delta": 1.0,
		"happiness_delta": -1.0,
		"detail": "Tight basics with little buffer. Useful short term, tiring over time."
	},
	{
		"id": "stable",
		"label": "Stable",
		"monthly_cost": LIFE_BASIC_EXPENSES_MONTHLY,
		"stress_delta": 0.0,
		"happiness_delta": 0.0,
		"detail": "Food, transport, phone, utilities, and a small daily buffer."
	},
	{
		"id": "comfortable",
		"label": "Comfortable",
		"monthly_cost": 3250000.0,
		"stress_delta": -1.0,
		"happiness_delta": 1.0,
		"detail": "More room for basics and less daily friction, at a higher cash hurdle."
	}
]
const LIFE_HOUSING_OPTIONS := [
	{
		"id": "family_home",
		"label": "Family support",
		"monthly_cost": 750000.0,
		"detail": "Lowest fixed cost. Good while building capital, but not fully independent."
	},
	{
		"id": "kost_room",
		"label": "Kost room",
		"monthly_cost": 2500000.0,
		"detail": "Simple monthly rent with predictable overhead."
	},
	{
		"id": "apartment",
		"label": "Apartment",
		"monthly_cost": 7500000.0,
		"detail": "Higher comfort and privacy, but it raises the monthly hurdle."
	}
]
const LIFE_LIFESTYLE_OPTIONS := [
	{
		"id": "frugal",
		"label": "Frugal",
		"monthly_cost": 1750000.0,
		"detail": "Keeps optional spending tight and maximizes runway."
	},
	{
		"id": "balanced",
		"label": "Balanced",
		"monthly_cost": 3750000.0,
		"detail": "Normal discretionary budget with some room for comfort."
	},
	{
		"id": "status",
		"label": "Status",
		"monthly_cost": 9000000.0,
		"detail": "Lifestyle inflation. Comfortable, but demanding on cash flow."
	}
]
const LIFE_ASSET_SELL_MULTIPLIER := 0.95
const LIFE_PROPERTY_LOCATIONS := [
	{"id": "jakarta", "label": "Jakarta", "market_factor": 1.0},
	{"id": "bogor", "label": "Bogor", "market_factor": 0.74},
	{"id": "depok", "label": "Depok", "market_factor": 0.78},
	{"id": "tangerang", "label": "Tangerang", "market_factor": 0.9},
	{"id": "bekasi", "label": "Bekasi", "market_factor": 0.82},
	{"id": "karawang", "label": "Karawang", "market_factor": 0.8},
	{"id": "bandung", "label": "Bandung", "market_factor": 0.85},
	{"id": "surabaya", "label": "Surabaya", "market_factor": 0.88},
	{"id": "semarang", "label": "Semarang", "market_factor": 0.68},
	{"id": "medan", "label": "Medan", "market_factor": 0.7},
	{"id": "makassar", "label": "Makassar", "market_factor": 0.66},
	{"id": "batam", "label": "Batam", "market_factor": 0.84},
	{"id": "balikpapan", "label": "Balikpapan", "market_factor": 0.78},
	{"id": "denpasar", "label": "Bali", "market_factor": 1.08}
]
const LIFE_DEVELOPMENT_THEMES := [
	{"id": "modern_city", "label": "Modern city", "detail": "A master-planned district could pull demand toward the location."},
	{"id": "toll_exit", "label": "Toll road exit", "detail": "A new toll access point could shorten travel time and lift land value."},
	{"id": "transit_corridor", "label": "Transit corridor", "detail": "Rail or busway expansion could make the area easier to live and work in."},
	{"id": "industrial_estate", "label": "Industrial estate", "detail": "Factories and warehouses could create jobs, traffic, and rental demand."},
	{"id": "hospital_university", "label": "Hospital/university campus", "detail": "A large institution could stabilize local housing and commercial demand."},
	{"id": "resort_zone", "label": "Resort/tourism zone", "detail": "Tourism investment could lift premium housing and villa values."},
	{"id": "port_logistics", "label": "Port/logistics expansion", "detail": "Cargo capacity and warehouses could pull workers and suppliers into the area."}
]
const LIFE_DEVELOPMENT_IMPACT_TIERS := {
	"minor": {"label": "Minor", "base_multiplier": 1.08, "big_win_multiplier": 1.18, "resolve_days": 5},
	"moderate": {"label": "Moderate", "base_multiplier": 1.18, "big_win_multiplier": 1.42, "resolve_days": 7},
	"major": {"label": "Major", "base_multiplier": 1.35, "big_win_multiplier": 1.95, "resolve_days": 9},
	"transformational": {"label": "Transformational", "base_multiplier": 1.62, "big_win_multiplier": 2.8, "resolve_days": 12}
}
const LIFE_DEVELOPMENT_RELEVANT_SECTORS := {
	"property": true,
	"infra": true,
	"transport": true,
	"industrial": true,
	"health": true
}
const LIFE_PROPERTY_CATALOG := [
	{
		"id": "kost_room",
		"label": "Kost Room",
		"price": 350000000.0,
		"monthly_upkeep": 900000.0,
		"rent_income": 2400000.0,
		"status_value": 2.0,
		"stress_delta": -0.2,
		"happiness_delta": 0.4,
		"detail": "Compact rental asset with steady but modest cash flow."
	},
	{
		"id": "kontrakan",
		"label": "Kontrakan",
		"price": 650000000.0,
		"monthly_upkeep": 1400000.0,
		"rent_income": 4200000.0,
		"status_value": 4.0,
		"stress_delta": -0.3,
		"happiness_delta": 0.5,
		"detail": "Small landed rental property with better independence than a room."
	},
	{
		"id": "basic_apartment",
		"label": "Basic Apartment",
		"price": 950000000.0,
		"monthly_upkeep": 2600000.0,
		"rent_income": 6200000.0,
		"status_value": 7.0,
		"stress_delta": -0.5,
		"happiness_delta": 0.8,
		"detail": "Simple city apartment; useful as a first owned base."
	},
	{
		"id": "comfortable_apartment",
		"label": "Comfortable Apartment",
		"price": 1800000000.0,
		"monthly_upkeep": 4600000.0,
		"rent_income": 10500000.0,
		"status_value": 12.0,
		"stress_delta": -0.8,
		"happiness_delta": 1.1,
		"detail": "Better privacy, better building services, and a clearer status signal."
	},
	{
		"id": "terraced_house",
		"label": "Terraced House",
		"price": 2600000000.0,
		"monthly_upkeep": 6200000.0,
		"rent_income": 14000000.0,
		"status_value": 17.0,
		"stress_delta": -1.0,
		"happiness_delta": 1.4,
		"detail": "A proper rumah tapak step: more space, more upkeep, more identity."
	},
	{
		"id": "cluster_townhouse",
		"label": "Cluster/Townhouse",
		"price": 4200000000.0,
		"monthly_upkeep": 9500000.0,
		"rent_income": 22000000.0,
		"status_value": 25.0,
		"stress_delta": -1.2,
		"happiness_delta": 1.8,
		"detail": "Gated comfort that starts changing how people read your standing."
	},
	{
		"id": "villa",
		"label": "Villa",
		"price": 8500000000.0,
		"monthly_upkeep": 18500000.0,
		"rent_income": 39000000.0,
		"status_value": 36.0,
		"stress_delta": -1.4,
		"happiness_delta": 2.2,
		"detail": "High-comfort retreat with strong lifestyle value and chunky burn."
	},
	{
		"id": "luxury_condo",
		"label": "Luxury Condo",
		"price": 12500000000.0,
		"monthly_upkeep": 26000000.0,
		"rent_income": 56000000.0,
		"status_value": 46.0,
		"stress_delta": -1.6,
		"happiness_delta": 2.5,
		"detail": "Visible city status with building fees that never sleep."
	},
	{
		"id": "mansion",
		"label": "Mansion",
		"price": 100000000000.0,
		"monthly_upkeep": 220000000.0,
		"rent_income": 0.0,
		"status_value": 95.0,
		"stress_delta": -2.4,
		"happiness_delta": 3.6,
		"detail": "Ultra-luxury trophy home pricing with maintenance bills to match."
	}
]
const LIFE_CAR_CATALOG := [
	{
		"id": "used_car",
		"label": "Practical Used Car",
		"price": 90000000.0,
		"monthly_upkeep": 1200000.0,
		"status_value": 2.0,
		"stress_delta": -0.2,
		"happiness_delta": 0.4,
		"detail": "Reliable enough to stop every trip feeling improvised."
	},
	{
		"id": "city_car",
		"label": "City Car",
		"price": 180000000.0,
		"monthly_upkeep": 1800000.0,
		"status_value": 4.0,
		"stress_delta": -0.3,
		"happiness_delta": 0.6,
		"detail": "Easy daily mobility with manageable burn."
	},
	{
		"id": "family_mpv",
		"label": "Family MPV",
		"price": 320000000.0,
		"monthly_upkeep": 2600000.0,
		"status_value": 7.0,
		"stress_delta": -0.4,
		"happiness_delta": 0.8,
		"detail": "Comfortable, ordinary, and quietly useful."
	},
	{
		"id": "sedan",
		"label": "Executive Sedan",
		"price": 650000000.0,
		"monthly_upkeep": 4600000.0,
		"status_value": 13.0,
		"stress_delta": -0.5,
		"happiness_delta": 1.0,
		"detail": "A cleaner arrival signal for meetings and dinners."
	},
	{
		"id": "luxury_suv",
		"label": "Luxury Sedan/SUV",
		"price": 1650000000.0,
		"monthly_upkeep": 10500000.0,
		"status_value": 28.0,
		"stress_delta": -0.7,
		"happiness_delta": 1.5,
		"detail": "Status on wheels, with maintenance bills to match."
	},
	{
		"id": "sports_luxury",
		"label": "Sports/Luxury Starter",
		"price": 4200000000.0,
		"monthly_upkeep": 24000000.0,
		"status_value": 48.0,
		"stress_delta": -0.8,
		"happiness_delta": 2.0,
		"detail": "Pure dopamine and public attention. Also pure monthly burn."
	}
]
const LOAD_RUN_LOADING_STEPS := [
	{"id": "load_save", "label": "Reading save file"},
	{"id": "restore_state", "label": "Restoring run state"},
	{"id": "corporate_actions", "label": "Refreshing corporate calendar"},
	{"id": "load_launch", "label": "Opening trading desk"}
]
const STARTUP_PERF_LOG_PREFIX := "[perf][startup]"
const ADVANCE_PERF_LOG_PREFIX := "[perf][advance]"
const DASHBOARD_REPORT_ROW_CACHE_LIMIT := 8
const FIRST_MONTH_WINDOW_DAYS := 30
const FIRST_MONTH_LIFE_WARNING_DAYS := 3
const FIRST_MONTH_DASHBOARD_LOOKAHEAD_DAYS := 5
const FIRST_MONTH_SAME_DAY_MEETING_CTA_LIMIT := 2
const DIFFICULTY_PRESETS := {
	"chill": {
		"id": "chill",
		"label": "Chill",
		"starting_cash": 1000000000.0,
		"company_count": 20,
		"use_company_universe_catalog": true,
		"market_swing_range": 0.02,
		"volatility_multiplier": 0.75,
		"event_interval_days": 14.0,
		"broker_impact_multiplier": 0.85,
		"daily_move_cap": 0.08,
		"volatility_label": "Low",
		"event_label": "Every 14 Days",
		"description": "A forgiving tape with calmer moves, slower event cadence, and plenty of cash to experiment."
	},
	"normal": {
		"id": "normal",
		"label": "Normal",
		"starting_cash": 100000000.0,
		"company_count": 30,
		"use_company_universe_catalog": true,
		"market_swing_range": 0.035,
		"volatility_multiplier": 1.0,
		"event_interval_days": 10.0,
		"broker_impact_multiplier": 1.0,
		"daily_move_cap": 0.12,
		"volatility_label": "Normal",
		"event_label": "Every 10 Days",
		"description": "The balanced prototype experience with readable tape, meaningful bankroll pressure, and a tighter market roster."
	},
	"grind": {
		"id": "grind",
		"label": "Grind",
		"starting_cash": 10000000.0,
		"company_count": 50,
		"use_company_universe_catalog": true,
		"market_swing_range": 0.055,
		"volatility_multiplier": 1.35,
		"event_interval_days": 7.0,
		"broker_impact_multiplier": 1.2,
		"daily_move_cap": 0.18,
		"volatility_label": "High",
		"event_label": "Every 7 Days",
		"description": "A leaner hard mode with sharper moves, tighter bankroll pressure, and regular news catalysts."
	}
}

var market_simulator = preload("res://systems/MarketSimulator.gd").new()
var summary_system = preload("res://systems/SummaryInsightSystem.gd").new()
var broker_flow_system = preload("res://systems/BrokerFlowSystem.gd").new()
var trading_calendar = preload("res://systems/TradingCalendar.gd").new()
var company_roster_generator = preload("res://systems/CompanyRosterGenerator.gd").new()
var macro_state_system = preload("res://systems/MacroStateSystem.gd").new()
var commodity_macro_contract = preload("res://systems/CommodityMacroContract.gd").new()
var chart_system = preload("res://systems/ChartSystem.gd").new()
var chart_pattern_system = preload("res://systems/ChartPatternSystem.gd").new()
var news_feed_system = preload("res://systems/NewsFeedSystem.gd").new()
var twooter_feed_system = preload("res://systems/TwooterFeedSystem.gd").new()
var twooter_interaction_system = preload("res://systems/TwooterInteractionSystem.gd").new()
var contact_network_system = preload("res://systems/ContactNetworkSystem.gd").new()
var dirty_tip_system = preload("res://systems/DirtyTipSystem.gd").new()
var corporate_action_system = preload("res://systems/CorporateActionSystem.gd").new()
var index_review_system = preload("res://systems/IndexReviewSystem.gd").new()
var company_roadmap_system = preload("res://systems/CompanyRoadmapSystem.gd").new()
var company_event_system = preload("res://systems/CompanyEventSystem.gd").new()
var person_event_system = preload("res://systems/PersonEventSystem.gd").new()
var special_event_system = preload("res://systems/SpecialEventSystem.gd").new()
var academy_system = preload("res://systems/AcademySystem.gd").new()
var thesis_report_system = preload("res://systems/ThesisReportSystem.gd").new()
var thesis_evidence_capture_system = preload("res://systems/ThesisEvidenceCaptureSystem.gd").new()
var background_company_detail_hydration_running: bool = false
var loading_detail_log_lines: Array = []
var company_market_rows_cache: Dictionary = {}
var news_snapshot_cache: Dictionary = {}
var dashboard_event_snapshot_cache: Dictionary = {}
var daily_activity_snapshot_cache: Dictionary = {}
var broker_range_snapshot_cache: Dictionary = {}


func _ready() -> void:
	DataRepository.reload_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_flush_pending_save_if_needed()


func _request_autosave(reason: String) -> void:
	SaveManager.request_save(reason)


func _save_active_run_now(reason: String) -> bool:
	if not RunState.has_active_run():
		return false
	return SaveManager.save_current_run_now(reason)


func _flush_pending_save_if_needed() -> bool:
	if not SaveManager.has_pending_save():
		return true
	return SaveManager.flush_pending_save()


func flush_pending_save_if_needed() -> bool:
	return _flush_pending_save_if_needed()


func save_active_run_now(reason: String = "manual_save") -> bool:
	return _save_active_run_now(reason)


func start_new_run(run_seed: int = 0, difficulty_id: String = DEFAULT_DIFFICULTY_ID, tutorial_enabled: bool = false) -> void:
	if run_seed == 0:
		run_seed = int(Time.get_unix_time_from_system())

	SaveManager.prepare_slot_for_new_run()
	var difficulty_config: Dictionary = get_difficulty_config(difficulty_id)
	var company_definitions: Array = build_company_roster(run_seed, difficulty_config)
	RunState.setup_new_run(run_seed, company_definitions, difficulty_config, tutorial_enabled)
	_reset_steam_progress_for_active_run()
	background_company_detail_hydration_running = false
	_invalidate_company_market_rows_cache()
	_invalidate_dashboard_event_snapshot_cache()
	_invalidate_daily_activity_snapshot_cache()
	_invalidate_broker_range_snapshot_cache()
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	index_review_system.ensure_initialized(RunState, DataRepository)
	simulate_opening_session(false)
	_save_active_run_now("start_new_run")
	run_started.emit()
	_enter_game_scene()


func start_new_run_with_loading(
	run_seed: int = 0,
	difficulty_id: String = DEFAULT_DIFFICULTY_ID,
	tutorial_enabled: bool = false
) -> void:
	if run_seed == 0:
		run_seed = int(Time.get_unix_time_from_system())

	SaveManager.prepare_slot_for_new_run()
	var difficulty_config: Dictionary = get_difficulty_config(difficulty_id)
	background_company_detail_hydration_running = false
	loading_detail_log_lines.clear()
	run_loading_started.emit(str(difficulty_config.get("id", difficulty_id)))
	_emit_run_loading_detail("", [])
	_emit_run_loading_step(0)
	await get_tree().process_frame

	_emit_run_loading_step(1)
	var company_definitions: Array = build_company_roster(run_seed, difficulty_config)
	await get_tree().process_frame

	_emit_run_loading_step(2)
	await get_tree().process_frame
	var financials_started_at_usec: int = Time.get_ticks_usec()
	await RunState.setup_new_run_batched(
		run_seed,
		company_definitions,
		difficulty_config,
		tutorial_enabled,
		Callable(self, "_on_new_run_financial_batch_progress"),
		5,
		Callable(self, "_on_new_run_financial_batch_detail")
	)
	_reset_steam_progress_for_active_run()
	_log_startup_perf_elapsed("new_run_financials_total", financials_started_at_usec, " companies=%d" % company_definitions.size())
	_invalidate_company_market_rows_cache()
	_invalidate_dashboard_event_snapshot_cache()
	_invalidate_daily_activity_snapshot_cache()
	_invalidate_broker_range_snapshot_cache()
	_emit_run_loading_step(3)
	var corporate_started_at_usec: int = Time.get_ticks_usec()
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	index_review_system.ensure_initialized(RunState, DataRepository)
	_log_startup_perf_elapsed("new_run_corporate_actions", corporate_started_at_usec)
	await get_tree().process_frame

	_emit_run_loading_step(4)
	var opening_started_at_usec: int = Time.get_ticks_usec()
	simulate_opening_session(false)
	_log_startup_perf_elapsed("new_run_opening_session", opening_started_at_usec)
	await get_tree().process_frame

	_emit_run_loading_step(5)
	var save_started_at_usec: int = Time.get_ticks_usec()
	_save_active_run_now("start_new_run_with_loading")
	_log_startup_perf_elapsed("new_run_save", save_started_at_usec)
	run_started.emit()
	await _hold_loading_stage(NEW_RUN_FINAL_STEP_HOLD_SECONDS)

	_emit_run_loading_step(6)
	await _hold_loading_stage(NEW_RUN_FINAL_STEP_HOLD_SECONDS)
	_emit_run_loading_detail("", [])
	run_loading_finished.emit()
	var launch_started_at_usec: int = Time.get_ticks_usec()
	_enter_game_scene()
	_log_startup_perf_elapsed("new_run_enter_game_scene", launch_started_at_usec)


func load_run_from_save(slot_id: String = "") -> bool:
	var saved_run: Dictionary = SaveManager.load_run(slot_id)
	if saved_run.is_empty():
		return false

	RunState.load_from_dict(saved_run)
	_sync_steam_progress_from_run_state()
	background_company_detail_hydration_running = false
	_invalidate_company_market_rows_cache()
	_invalidate_dashboard_event_snapshot_cache()
	_invalidate_daily_activity_snapshot_cache()
	_invalidate_broker_range_snapshot_cache()
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	index_review_system.ensure_initialized(RunState, DataRepository)
	run_loaded.emit()
	_enter_game_scene()
	return true


func load_run_from_save_with_loading(slot_id: String = "") -> bool:
	_emit_load_run_loading_step(0)
	await get_tree().process_frame

	var load_started_at_usec: int = Time.get_ticks_usec()
	var saved_run: Dictionary = SaveManager.load_run(slot_id)
	_log_startup_perf_elapsed("load_run_read_parse", load_started_at_usec)
	if saved_run.is_empty():
		run_loading_finished.emit()
		return false

	_emit_load_run_loading_step(1)
	var restore_started_at_usec: int = Time.get_ticks_usec()
	RunState.load_from_dict(saved_run)
	_sync_steam_progress_from_run_state()
	_log_startup_perf_elapsed("load_run_restore_state", restore_started_at_usec)
	background_company_detail_hydration_running = false
	_invalidate_company_market_rows_cache()
	_invalidate_dashboard_event_snapshot_cache()
	_invalidate_daily_activity_snapshot_cache()
	_invalidate_broker_range_snapshot_cache()
	_emit_load_run_loading_step(2)
	var corporate_started_at_usec: int = Time.get_ticks_usec()
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	index_review_system.ensure_initialized(RunState, DataRepository)
	_log_startup_perf_elapsed("load_run_corporate_actions", corporate_started_at_usec)
	run_loaded.emit()
	await get_tree().process_frame

	_emit_load_run_loading_step(3)
	await get_tree().process_frame
	run_loading_finished.emit()
	var launch_started_at_usec: int = Time.get_ticks_usec()
	_enter_game_scene()
	_log_startup_perf_elapsed("load_run_enter_game_scene", launch_started_at_usec)
	return true


func return_to_menu() -> void:
	_flush_pending_save_if_needed()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func quit_game() -> void:
	_flush_pending_save_if_needed()
	get_tree().quit()


func advance_day() -> Dictionary:
	return _advance_day_internal(true, true)


func advance_day_deferred_save() -> Dictionary:
	return _advance_day_internal(true, true, false)


func simulate_opening_session(save_after: bool = false) -> Dictionary:
	return _advance_day_internal(save_after, false)


func _advance_day_internal(save_after: bool = true, emit_runtime_signals: bool = true, flush_save_immediately: bool = true) -> Dictionary:
	if not RunState.has_active_run():
		return {}
	var finance_gate: Dictionary = resolve_advance_day_finance_gate()
	if not bool(finance_gate.get("success", false)):
		return finance_gate
	var log_advance_perf: bool = _should_log_advance_perf(save_after, emit_runtime_signals)
	var total_started_at_usec: int = Time.get_ticks_usec()

	var simulation: Dictionary = _advance_phase_simulate_market(log_advance_perf, emit_runtime_signals)
	var day_result: Dictionary = simulation.get("day_result", {})
	var life_results: Dictionary = _advance_phase_apply_life(log_advance_perf, simulation.get("previous_trade_date", {}))
	var event_results: Dictionary = _advance_phase_process_events(log_advance_perf, day_result, simulation.get("previous_trade_date", {}), life_results)
	_advance_phase_emit_market_signals(log_advance_perf, emit_runtime_signals, life_results, event_results)
	var summary: Dictionary = _advance_phase_build_summary_and_news(log_advance_perf, simulation.get("company_market_rows", []))
	_advance_phase_save_and_announce(log_advance_perf, save_after, emit_runtime_signals, flush_save_immediately, summary)
	_log_advance_perf_elapsed(log_advance_perf, "total", total_started_at_usec, " save_after=%s emit_runtime_signals=%s flush_save_immediately=%s" % [str(save_after), str(emit_runtime_signals), str(flush_save_immediately)])
	return {
		"day_result": day_result,
		"summary": summary
	}


func _advance_phase_simulate_market(log_advance_perf: bool, emit_runtime_signals: bool) -> Dictionary:
	var phase_started_at_usec: int = Time.get_ticks_usec()
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	index_review_system.ensure_initialized(RunState, DataRepository)
	_log_advance_perf_elapsed(log_advance_perf, "ensure_corporate_actions", phase_started_at_usec)
	if emit_runtime_signals:
		phase_started_at_usec = Time.get_ticks_usec()
		day_started.emit(RunState.day_index + 1)
		_log_advance_perf_elapsed(log_advance_perf, "emit_day_started", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var day_result: Dictionary = market_simulator.simulate_day(RunState, DataRepository, broker_flow_system, corporate_action_system)
	_log_advance_perf_elapsed(log_advance_perf, "simulate_day", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var previous_trade_date: Dictionary = RunState.current_trade_date.duplicate(true)
	RunState.apply_day_result(day_result)
	_invalidate_broker_range_snapshot_cache()
	_log_advance_perf_elapsed(log_advance_perf, "apply_day_result", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var company_market_rows: Array = get_company_market_rows(true)
	_log_advance_perf_elapsed(log_advance_perf, "build_company_market_rows", phase_started_at_usec, " count=%d" % company_market_rows.size())
	return {
		"day_result": day_result,
		"previous_trade_date": previous_trade_date,
		"company_market_rows": company_market_rows
	}


func _advance_phase_apply_life(log_advance_perf: bool, previous_trade_date: Dictionary) -> Dictionary:
	var phase_started_at_usec: int = Time.get_ticks_usec()
	var life_obligation_result: Dictionary = LifeManager.apply_life_monthly_obligation_if_due(self, previous_trade_date, RunState.current_trade_date)
	_log_advance_perf_elapsed(log_advance_perf, "apply_life_obligation", phase_started_at_usec, " amount=%.2f" % float(life_obligation_result.get("amount", 0.0)))
	phase_started_at_usec = Time.get_ticks_usec()
	var life_loan_payment_result: Dictionary = LifeManager.apply_life_loan_payment_if_due(previous_trade_date, RunState.current_trade_date)
	_log_advance_perf_elapsed(log_advance_perf, "apply_life_loan_payment", phase_started_at_usec, " amount=%.2f" % float(life_loan_payment_result.get("amount", 0.0)))
	phase_started_at_usec = Time.get_ticks_usec()
	var life_bank_loan_payment_result: Dictionary = LifeManager.apply_bank_loan_payment_if_due(previous_trade_date, RunState.current_trade_date)
	_log_advance_perf_elapsed(log_advance_perf, "apply_bank_loan_payment", phase_started_at_usec, " amount=%.2f" % float(life_bank_loan_payment_result.get("amount", 0.0)))
	phase_started_at_usec = Time.get_ticks_usec()
	var life_legal_result: Dictionary = LifeManager.apply_life_legal_state_update()
	_log_advance_perf_elapsed(log_advance_perf, "apply_life_legal", phase_started_at_usec, " remaining=%d" % int(life_legal_result.get("days_remaining", 0)))
	phase_started_at_usec = Time.get_ticks_usec()
	var life_wellbeing_result: Dictionary = LifeManager.apply_life_daily_wellbeing_update(self)
	_log_advance_perf_elapsed(log_advance_perf, "apply_life_wellbeing", phase_started_at_usec, " stress=%.2f" % float(life_wellbeing_result.get("stress_value", 0.0)))
	return {
		"obligation": life_obligation_result,
		"loan_payment": life_loan_payment_result,
		"bank_loan_payment": life_bank_loan_payment_result,
		"legal": life_legal_result,
		"wellbeing": life_wellbeing_result
	}


func _advance_phase_process_events(log_advance_perf: bool, day_result: Dictionary, previous_trade_date: Dictionary, life_results: Dictionary) -> Dictionary:
	var phase_started_at_usec: int = Time.get_ticks_usec()
	var network_results: Array = contact_network_system.process_due_requests(RunState, DataRepository)
	_log_advance_perf_elapsed(log_advance_perf, "process_due_requests", phase_started_at_usec, " count=%d" % network_results.size())
	phase_started_at_usec = Time.get_ticks_usec()
	var network_tip_results: Array = contact_network_system.process_due_tip_memories(RunState, DataRepository)
	_log_advance_perf_elapsed(log_advance_perf, "process_due_tip_memories", phase_started_at_usec, " count=%d" % network_tip_results.size())
	phase_started_at_usec = Time.get_ticks_usec()
	var life_development_results: Array = process_life_development_leads()
	_log_advance_perf_elapsed(log_advance_perf, "process_life_development_leads", phase_started_at_usec, " count=%d" % life_development_results.size())
	phase_started_at_usec = Time.get_ticks_usec()
	var dirty_tip_results: Array = dirty_tip_system.process_due_cases(RunState, DataRepository)
	_log_advance_perf_elapsed(log_advance_perf, "process_dirty_tip_cases", phase_started_at_usec, " count=%d" % dirty_tip_results.size())
	phase_started_at_usec = Time.get_ticks_usec()
	var dirty_tip_offer_resolution: Dictionary = dirty_tip_system.resolve_day(
		RunState,
		DataRepository,
		day_result.get("attention_directives", {}),
		RunState.day_index,
		day_result.get("trade_date", previous_trade_date)
	)
	var dirty_tip_offers: Array = dirty_tip_offer_resolution.get("offers", []).duplicate(true)
	_log_advance_perf_elapsed(log_advance_perf, "resolve_dirty_tip_offer", phase_started_at_usec, " count=%d reason=%s" % [dirty_tip_offers.size(), str(dirty_tip_offer_resolution.get("reason", ""))])
	var life_legal_result: Dictionary = life_results.get("legal", {})
	if not life_legal_result.is_empty():
		RunState.last_day_results["life_legal"] = life_legal_result.duplicate(true)
	if not network_results.is_empty():
		RunState.last_day_results["network_request_results"] = network_results.duplicate(true)
	if not network_tip_results.is_empty():
		RunState.last_day_results["network_tip_results"] = network_tip_results.duplicate(true)
	if not life_development_results.is_empty():
		RunState.last_day_results["life_development_results"] = life_development_results.duplicate(true)
	if not dirty_tip_results.is_empty():
		RunState.last_day_results["dirty_tip_results"] = dirty_tip_results.duplicate(true)
	if not dirty_tip_offers.is_empty():
		RunState.last_day_results["dirty_tip_offers"] = dirty_tip_offers.duplicate(true)
	phase_started_at_usec = Time.get_ticks_usec()
	_rebuild_dashboard_event_snapshot_cache("", log_advance_perf)
	_log_advance_perf_elapsed(log_advance_perf, "build_dashboard_event_cache", phase_started_at_usec)
	return {
		"network_results": network_results,
		"network_tip_results": network_tip_results,
		"life_development_results": life_development_results,
		"dirty_tip_results": dirty_tip_results,
		"dirty_tip_offers": dirty_tip_offers
	}


func _advance_phase_emit_market_signals(log_advance_perf: bool, emit_runtime_signals: bool, life_results: Dictionary, event_results: Dictionary) -> void:
	var network_results: Array = event_results.get("network_results", [])
	var network_tip_results: Array = event_results.get("network_tip_results", [])
	var life_development_results: Array = event_results.get("life_development_results", [])
	var dirty_tip_results: Array = event_results.get("dirty_tip_results", [])
	var dirty_tip_offers: Array = event_results.get("dirty_tip_offers", [])
	var phase_started_at_usec: int = 0
	if (not network_results.is_empty() or not network_tip_results.is_empty() or not life_development_results.is_empty() or not dirty_tip_results.is_empty() or not dirty_tip_offers.is_empty()) and emit_runtime_signals:
		phase_started_at_usec = Time.get_ticks_usec()
		network_changed.emit()
		_log_advance_perf_elapsed(log_advance_perf, "emit_network_changed", phase_started_at_usec)
	if emit_runtime_signals:
		phase_started_at_usec = Time.get_ticks_usec()
		broker_flow_generated.emit(RunState.day_index)
		_log_advance_perf_elapsed(log_advance_perf, "emit_broker_flow_generated", phase_started_at_usec)
		phase_started_at_usec = Time.get_ticks_usec()
		price_formed.emit(RunState.day_index)
		_log_advance_perf_elapsed(log_advance_perf, "emit_price_formed", phase_started_at_usec)
		phase_started_at_usec = Time.get_ticks_usec()
		daily_actions_changed.emit()
		_log_advance_perf_elapsed(log_advance_perf, "emit_daily_actions_changed", phase_started_at_usec)
		if not life_results.get("obligation", {}).is_empty() or not life_results.get("loan_payment", {}).is_empty() or not life_results.get("bank_loan_payment", {}).is_empty() or not life_results.get("legal", {}).is_empty() or not life_results.get("wellbeing", {}).is_empty() or not life_development_results.is_empty() or _dirty_tip_results_include_legal(dirty_tip_results):
			phase_started_at_usec = Time.get_ticks_usec()
			life_changed.emit()
			_log_advance_perf_elapsed(log_advance_perf, "emit_life_changed", phase_started_at_usec)


func _advance_phase_build_summary_and_news(log_advance_perf: bool, company_market_rows: Array) -> Dictionary:
	var phase_started_at_usec: int = Time.get_ticks_usec()
	var summary: Dictionary = summary_system.build_daily_summary(RunState, DataRepository, log_advance_perf, company_market_rows)
	_log_advance_perf_elapsed(log_advance_perf, "build_daily_summary", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	RunState.set_daily_summary(summary)
	_log_advance_perf_elapsed(log_advance_perf, "set_daily_summary", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var feed_context: Dictionary = _build_news_feed_context(log_advance_perf, company_market_rows)
	var news_snapshot: Dictionary = _build_news_snapshot(-1, log_advance_perf, feed_context)
	_log_advance_perf_elapsed(log_advance_perf, "build_news_snapshot", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_cache_news_snapshot(news_snapshot, get_unlocked_news_intel_level())
	RunState.record_news_snapshot(news_snapshot)
	_log_advance_perf_elapsed(log_advance_perf, "record_news_snapshot", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	_rebuild_daily_activity_snapshot_cache(news_snapshot, "", log_advance_perf, feed_context)
	_log_advance_perf_elapsed(log_advance_perf, "build_daily_activity_cache", phase_started_at_usec)
	_record_steam_day_advanced()
	return summary


func _advance_phase_save_and_announce(log_advance_perf: bool, save_after: bool, emit_runtime_signals: bool, flush_save_immediately: bool, summary: Dictionary) -> void:
	var phase_started_at_usec: int = 0
	if save_after:
		phase_started_at_usec = Time.get_ticks_usec()
		if flush_save_immediately:
			_save_active_run_now("advance_day")
			_log_advance_perf_elapsed(log_advance_perf, "save_active_run", phase_started_at_usec)
		else:
			_request_autosave("advance_day")
			_log_advance_perf_elapsed(log_advance_perf, "request_save", phase_started_at_usec)
	if emit_runtime_signals:
		phase_started_at_usec = Time.get_ticks_usec()
		summary_ready.emit(summary)
		_log_advance_perf_elapsed(log_advance_perf, "emit_summary_ready", phase_started_at_usec)
		phase_started_at_usec = Time.get_ticks_usec()
		advance_day_portfolio_valued.emit()
		_log_advance_perf_elapsed(log_advance_perf, "emit_advance_day_portfolio_valued", phase_started_at_usec)


func _dirty_tip_results_include_legal(results: Array) -> bool:
	for result_value in results:
		if typeof(result_value) != TYPE_DICTIONARY:
			continue
		var result: Dictionary = result_value
		if str(result.get("status", "")) == "caught" or int(result.get("legal_days", 0)) > 0 or float(result.get("fine_amount", 0.0)) > 0.0:
			return true
	return false


func buy_company(company_id: String, shares: int = 1) -> Dictionary:
	var block_reason: String = get_life_action_block_reason("buy")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var result: Dictionary = RunState.buy_company(company_id, shares)
	if result.get("success", false):
		_record_steam_trade_progress(company_id, "buy")
		_invalidate_dashboard_event_snapshot_cache()
		_request_autosave("buy_company")
		portfolio_changed.emit()
	return result


func sell_company(company_id: String, shares: int = 1) -> Dictionary:
	var block_reason: String = get_life_action_block_reason("sell")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var result: Dictionary = RunState.sell_company(company_id, shares)
	if result.get("success", false):
		_record_steam_trade_progress(company_id, "sell")
		_invalidate_dashboard_event_snapshot_cache()
		_request_autosave("sell_company")
		portfolio_changed.emit()
	return result


func buy_lots(company_id: String, lots: int = 1) -> Dictionary:
	return buy_company(company_id, lots_to_shares(lots))


func sell_lots(company_id: String, lots: int = 1) -> Dictionary:
	return sell_company(company_id, lots_to_shares(lots))


func estimate_buy_lots(company_id: String, lots: int = 1) -> Dictionary:
	return RunState.estimate_buy_order(company_id, lots_to_shares(lots))


func estimate_sell_lots(company_id: String, lots: int = 1) -> Dictionary:
	return RunState.estimate_sell_order(company_id, lots_to_shares(lots))


func add_company_to_watchlist(company_id: String) -> Dictionary:
	var result: Dictionary = RunState.add_to_watchlist(company_id)
	if result.get("success", false):
		_record_steam_progress_event("watchlist_added", {"company_id": company_id})
		_request_autosave("watchlist_add")
		watchlist_changed.emit()
	return result


func remove_company_from_watchlist(company_id: String) -> Dictionary:
	var result: Dictionary = RunState.remove_from_watchlist(company_id)
	if result.get("success", false):
		_request_autosave("watchlist_remove")
		watchlist_changed.emit()
	return result


func get_upgrade_shop_snapshot() -> Dictionary:
	var cash_available: float = float(RunState.player_portfolio.get("cash", 0.0))
	var upgrade_block_reason: String = get_life_action_block_reason("upgrade")
	var tracks: Array = []
	for track_value in DataRepository.get_upgrade_catalog().get("tracks", []):
		if typeof(track_value) != TYPE_DICTIONARY:
			continue
		var track: Dictionary = track_value
		var track_id: String = str(track.get("id", ""))
		if track_id.is_empty():
			continue
		var current_tier: int = RunState.get_upgrade_tier(track_id)
		var current_data: Dictionary = _upgrade_tier_data(track, current_tier)
		var next_tier: int = current_tier - 1
		var next_data: Dictionary = _upgrade_tier_data(track, next_tier)
		var next_cost: float = float(next_data.get("cost", 0.0)) if next_tier >= 1 else 0.0
		tracks.append({
			"id": track_id,
			"label": str(track.get("label", track_id.capitalize())),
			"description": str(track.get("description", "")),
			"tier": current_tier,
			"effect_label": str(current_data.get("effect_label", "Tier %d" % current_tier)),
			"next_tier": next_tier if next_tier >= 1 else 0,
			"next_effect_label": str(next_data.get("effect_label", "")),
			"next_cost": next_cost,
			"maxed": current_tier <= 1,
			"affordable": upgrade_block_reason.is_empty() and cash_available + 0.0001 >= next_cost and next_cost > 0.0,
			"can_purchase": upgrade_block_reason.is_empty() and current_tier > 1 and cash_available + 0.0001 >= next_cost and next_cost > 0.0,
			"block_reason": upgrade_block_reason
		})

	return {
		"cash": cash_available,
		"tracks": tracks,
		"daily_action": RunState.get_daily_action_snapshot()
	}


func purchase_upgrade(track_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var block_reason: String = get_life_action_block_reason("upgrade")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}

	var track: Dictionary = _upgrade_track(track_id)
	if track.is_empty():
		return {"success": false, "message": "Unknown upgrade."}

	var normalized_track_id: String = str(track.get("id", track_id))
	var current_tier: int = RunState.get_upgrade_tier(normalized_track_id)
	if current_tier <= 1:
		return {"success": false, "message": "%s is already maxed." % str(track.get("label", "Upgrade"))}

	var next_tier: int = current_tier - 1
	var next_data: Dictionary = _upgrade_tier_data(track, next_tier)
	var cost: float = float(next_data.get("cost", 0.0))
	if cost <= 0.0:
		return {"success": false, "message": "That upgrade tier has no price."}

	var cash_available: float = float(RunState.player_portfolio.get("cash", 0.0))
	if cost > cash_available + 0.0001:
		return {"success": false, "message": "Not enough cash for that upgrade."}

	RunState.player_portfolio["cash"] = cash_available - cost
	RunState.refresh_cash_stress_state()
	RunState.set_upgrade_tier(normalized_track_id, next_tier)
	_invalidate_daily_activity_snapshot_cache()
	_record_steam_progress_event("upgrade_purchased", {"track_id": normalized_track_id, "tier": next_tier})
	_request_autosave("purchase_upgrade")
	upgrades_changed.emit()
	portfolio_changed.emit()
	if normalized_track_id == "daily_action_points":
		daily_actions_changed.emit()
	return {
		"success": true,
		"message": "%s upgraded to tier %d." % [str(track.get("label", "Upgrade")), next_tier],
		"track_id": normalized_track_id,
		"tier": next_tier,
		"cash": float(RunState.player_portfolio.get("cash", 0.0))
	}


func execute_console_command(command_text: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}

	var normalized_command: String = command_text.strip_edges().to_lower()
	match normalized_command:
		"cuankus":
			var cash_before: float = float(RunState.player_portfolio.get("cash", 0.0))
			RunState.player_portfolio["cash"] = cash_before + CONSOLE_CASH_GRANT_AMOUNT
			RunState.refresh_cash_stress_state()
			_request_autosave("console_cuankus")
			portfolio_changed.emit()
			return {
				"success": true,
				"message": "Cuankus! Cash added: Rp999.999.999.999.",
				"command": normalized_command,
				"cash": float(RunState.player_portfolio.get("cash", 0.0))
			}
		"ordalbos":
			for track_id in RunState.UPGRADE_TRACK_IDS:
				RunState.set_upgrade_tier(str(track_id), 1)
			_invalidate_daily_activity_snapshot_cache()
			_request_autosave("console_ordalbos")
			upgrades_changed.emit()
			daily_actions_changed.emit()
			return {
				"success": true,
				"message": "Ordal bos unlocked every upgrade.",
				"command": normalized_command,
				"upgrade_tiers": RunState.get_upgrade_tiers()
			}

	return {
		"success": false,
		"message": "Unknown command: %s" % command_text.strip_edges(),
		"command": normalized_command
	}


func debug_grant_company_control(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var normalized_company_id: String = company_id.strip_edges().to_lower()
	if normalized_company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	var definition: Dictionary = RunState.get_effective_company_definition(normalized_company_id, false, false)
	if definition.is_empty():
		return {"success": false, "message": "Pick a valid stock first."}
	var ownership: Dictionary = get_company_ownership_snapshot(normalized_company_id)
	var control_required_shares: int = int(ownership.get("control_required_shares", 0))
	if control_required_shares <= 0:
		return {"success": false, "message": "That company has no usable share structure."}
	var ticker: String = str(definition.get("ticker", normalized_company_id.to_upper()))
	if bool(ownership.get("is_control_shareholder", false)):
		return {
			"success": true,
			"message": "%s is already under player control." % ticker,
			"company_id": normalized_company_id,
			"ticker": ticker,
			"shares_granted": 0,
			"shares_owned": int(ownership.get("shares_owned", 0)),
			"control_required_shares": control_required_shares,
			"ownership_pct": float(ownership.get("ownership_pct", 0.0)),
			"already_controlled": true
		}

	var current_shares: int = max(int(ownership.get("shares_owned", 0)), 0)
	var shares_to_grant: int = max(control_required_shares - current_shares, 0)
	if shares_to_grant <= 0:
		return {"success": false, "message": "%s could not calculate missing control shares." % ticker}
	var runtime: Dictionary = RunState.get_company(normalized_company_id)
	var current_price: float = max(float(runtime.get("current_price", definition.get("base_price", 0.0))), 0.0)
	var holdings: Dictionary = RunState.player_portfolio.get("holdings", {})
	var holding: Dictionary = holdings.get(normalized_company_id, {
		"company_id": normalized_company_id,
		"shares": 0,
		"average_price": current_price
	}).duplicate(true)
	var holding_shares: int = max(int(holding.get("shares", 0)), 0)
	var current_average: float = float(holding.get("average_price", current_price))
	var new_share_total: int = holding_shares + shares_to_grant
	var new_average: float = current_price
	if new_share_total > 0:
		new_average = ((current_average * float(holding_shares)) + (current_price * float(shares_to_grant))) / float(new_share_total)
	holding["company_id"] = normalized_company_id
	holding["shares"] = new_share_total
	holding["average_price"] = new_average
	holdings[normalized_company_id] = holding
	RunState.player_portfolio["holdings"] = holdings

	var updated_ownership: Dictionary = get_company_ownership_snapshot(normalized_company_id)
	_request_autosave("debug_grant_company_control")
	portfolio_changed.emit()
	return {
		"success": true,
		"message": "Debug control: granted %s share(s) of %s. Player now owns %.2f%%." % [
			_format_grouped_integer(shares_to_grant),
			ticker,
			float(updated_ownership.get("ownership_pct", 0.0)) * 100.0
		],
		"company_id": normalized_company_id,
		"ticker": ticker,
		"shares_granted": shares_to_grant,
		"shares_owned": int(updated_ownership.get("shares_owned", new_share_total)),
		"control_required_shares": int(updated_ownership.get("control_required_shares", control_required_shares)),
		"ownership_pct": float(updated_ownership.get("ownership_pct", 0.0)),
		"already_controlled": false
	}


func get_debug_corporate_action_generator_catalog() -> Array:
	var groups: Array = []
	for group_value in DEBUG_CORPORATE_ACTION_GENERATOR_GROUPS:
		if typeof(group_value) == TYPE_DICTIONARY:
			groups.append(group_value.duplicate(true))
	return groups


func debug_generate_corporate_action(generator_id: String, company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var generator: Dictionary = _debug_corporate_action_generator_by_id(generator_id)
	if generator.is_empty():
		return {"success": false, "message": "Unknown corporate-action generator."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	var method_name: String = str(generator.get("method", ""))
	if method_name.is_empty() or not has_method(method_name):
		return {"success": false, "message": "Corporate-action generator is not wired yet."}
	var generated_value = call(method_name, company_id)
	if typeof(generated_value) != TYPE_DICTIONARY:
		return {"success": false, "message": "Corporate-action generator did not return a result."}
	var result: Dictionary = generated_value
	result["generator_id"] = str(generator.get("id", generator_id))
	result["generator_label"] = str(generator.get("full_label", generator.get("label", "Corporate Action")))
	return result


func get_debug_index_review_generator_catalog() -> Array:
	return index_review_system.get_debug_generator_catalog(DataRepository)


func debug_generate_index_review(generator_id: String, company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var generator: Dictionary = _debug_index_review_generator_by_id(generator_id)
	if generator.is_empty():
		return {"success": false, "message": "Unknown index-review generator."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	index_review_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = index_review_system.debug_force_review_event(
		RunState,
		DataRepository,
		str(generator.get("provider_id", "")),
		str(generator.get("side", "include")),
		company_id
	)
	if result.is_empty():
		return {"success": false, "message": "Could not generate an index-review event for that company."}
	RunState.set_index_review_state(result.get("index_review_state", {}))
	RunState.debug_add_company_arc(result.get("arc", {}), result.get("event", {}))
	_invalidate_dashboard_event_snapshot_cache()
	_invalidate_daily_activity_snapshot_cache()
	_request_autosave("debug_generate_index_review")
	var event: Dictionary = result.get("event", {})
	return {
		"success": true,
		"message": "Generated %s for %s." % [
			str(generator.get("label", "index review")),
			str(event.get("target_ticker", company_id.to_upper()))
		],
		"generator_id": generator_id,
		"generator_label": str(generator.get("label", "Index Review")),
		"event": event.duplicate(true),
		"action": result.get("action", {}).duplicate(true)
	}


func get_debug_company_roadmap_generator_catalog() -> Array:
	var groups: Array = []
	for group_value in DEBUG_COMPANY_ROADMAP_GENERATOR_GROUPS:
		if typeof(group_value) == TYPE_DICTIONARY:
			groups.append(group_value.duplicate(true))
	return groups


func debug_generate_company_roadmap(generator_id: String, company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var generator: Dictionary = _debug_company_roadmap_generator_by_id(generator_id)
	if generator.is_empty():
		return {"success": false, "message": "Unknown roadmap generator."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = company_roadmap_system.debug_force_milestone(
		RunState,
		DataRepository,
		corporate_action_system,
		company_id,
		generator_id,
		get_current_trade_date(),
		max(int(RunState.day_index), 1)
	)
	if not bool(result.get("success", false)):
		return result
	RunState.set_company_roadmap_state(result.get("company_roadmap_state", {}))
	if result.has("active_corporate_action_chains"):
		RunState.set_active_corporate_action_chains(result.get("active_corporate_action_chains", {}))
	if result.has("corporate_meeting_calendar"):
		RunState.set_corporate_meeting_calendar(result.get("corporate_meeting_calendar", {}))
	var start_event: Dictionary = result.get("started_event", {})
	var first_arc: bool = true
	for arc_value in result.get("active_company_arcs", []):
		if typeof(arc_value) != TYPE_DICTIONARY:
			continue
		var arc: Dictionary = arc_value
		RunState.debug_add_company_arc(arc, start_event if first_arc else {})
		first_arc = false
	for event_value in result.get("corporate_action_events", []):
		if typeof(event_value) == TYPE_DICTIONARY:
			RunState.debug_add_recorded_event(event_value)
	_invalidate_dashboard_event_snapshot_cache()
	_invalidate_daily_activity_snapshot_cache()
	_invalidate_news_snapshot_cache()
	_request_autosave("debug_generate_company_roadmap")
	var milestone: Dictionary = result.get("milestone", {})
	var ticker: String = str(milestone.get("ticker", company_id.to_upper()))
	var funding_label: String = str(milestone.get("funding_outcome", "started")).replace("_", " ")
	return {
		"success": true,
		"message": "Generated %s for %s (%s)." % [
			str(generator.get("full_label", generator.get("label", "roadmap milestone"))),
			ticker,
			funding_label
		],
		"generator_id": generator_id,
		"generator_label": str(generator.get("full_label", generator.get("label", "Roadmap"))),
		"milestone": milestone.duplicate(true),
		"event": start_event.duplicate(true)
	}


func get_debug_life_development_generator_catalog() -> Array:
	return LifeManager.get_debug_life_development_generator_catalog(self)


func debug_generate_life_development(generator_id: String) -> Dictionary:
	return LifeManager.debug_generate_life_development(self, generator_id)


func debug_force_rights_issue_rupslb(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_force_rights_issue_rupslb(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not force a same-day rights issue RUPSLB for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	return {
		"success": true,
		"message": "Forced same-day rights issue RUPSLB created.",
		"chain": result.get("chain", {}).duplicate(true),
		"meeting": result.get("meeting", {}).duplicate(true)
	}


func debug_schedule_next_day_rights_issue_rupslb(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	var holding: Dictionary = RunState.get_holding(company_id)
	if int(holding.get("shares", 0)) < get_lot_size():
		return {"success": false, "message": "Own at least 1 lot first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_schedule_next_day_rights_issue_rupslb(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not schedule a next-day rights issue RUPSLB for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_schedule_next_day_rupslb")
	var meeting: Dictionary = result.get("meeting", {}).duplicate(true)
	return {
		"success": true,
		"message": "Scheduled next-day rights issue RUPSLB for %s on %s." % [
			str(meeting.get("ticker", company_id.to_upper())),
			format_trade_date(meeting.get("trade_date", {}))
		],
		"chain": result.get("chain", {}).duplicate(true),
		"meeting": meeting
	}


func debug_schedule_next_day_private_placement_rupslb(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	var holding: Dictionary = RunState.get_holding(company_id)
	if int(holding.get("shares", 0)) < get_lot_size():
		return {"success": false, "message": "Own at least 1 lot first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_schedule_next_day_private_placement_rupslb(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not schedule a next-day private placement RUPSLB for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_schedule_next_day_private_placement_rupslb")
	var meeting: Dictionary = result.get("meeting", {}).duplicate(true)
	return {
		"success": true,
		"message": "Scheduled next-day private placement RUPSLB for %s." % str(meeting.get("ticker", company_id.to_upper())),
		"chain": result.get("chain", {}).duplicate(true),
		"meeting": meeting
	}


func debug_schedule_next_day_stock_buyback_rupslb(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	var holding: Dictionary = RunState.get_holding(company_id)
	if int(holding.get("shares", 0)) < get_lot_size():
		return {"success": false, "message": "Own at least 1 lot first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_schedule_next_day_stock_buyback_rupslb(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not schedule a next-day stock buyback RUPSLB for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_schedule_next_day_stock_buyback_rupslb")
	var meeting: Dictionary = result.get("meeting", {}).duplicate(true)
	return {
		"success": true,
		"message": "Scheduled next-day stock buyback RUPSLB for %s." % str(meeting.get("ticker", company_id.to_upper())),
		"chain": result.get("chain", {}).duplicate(true),
		"meeting": meeting
	}


func debug_schedule_next_day_stock_split_rupslb(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	var holding: Dictionary = RunState.get_holding(company_id)
	if int(holding.get("shares", 0)) < get_lot_size():
		return {"success": false, "message": "Own at least 1 lot first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_schedule_next_day_stock_split_rupslb(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not schedule a next-day stock split RUPSLB for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_schedule_next_day_stock_split_rupslb")
	var meeting: Dictionary = result.get("meeting", {}).duplicate(true)
	return {
		"success": true,
		"message": "Scheduled next-day stock split RUPSLB for %s." % str(meeting.get("ticker", company_id.to_upper())),
		"chain": result.get("chain", {}).duplicate(true),
		"meeting": meeting
	}


func debug_schedule_next_day_tender_offer_rupslb(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	var holding: Dictionary = RunState.get_holding(company_id)
	if int(holding.get("shares", 0)) < get_lot_size():
		return {"success": false, "message": "Own at least 1 lot first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_schedule_next_day_tender_offer_rupslb(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not schedule a next-day tender offer RUPSLB for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_schedule_next_day_tender_offer_rupslb")
	var meeting: Dictionary = result.get("meeting", {}).duplicate(true)
	return {
		"success": true,
		"message": "Scheduled next-day tender offer RUPSLB for %s." % str(meeting.get("ticker", company_id.to_upper())),
		"chain": result.get("chain", {}).duplicate(true),
		"meeting": meeting
	}


func debug_schedule_next_day_strategic_mna_rupslb(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	var holding: Dictionary = RunState.get_holding(company_id)
	if int(holding.get("shares", 0)) < get_lot_size():
		return {"success": false, "message": "Own at least 1 lot first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_schedule_next_day_strategic_mna_rupslb(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not schedule a next-day strategic M&A RUPSLB for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_schedule_next_day_strategic_mna_rupslb")
	var meeting: Dictionary = result.get("meeting", {}).duplicate(true)
	return {
		"success": true,
		"message": "Scheduled next-day strategic M&A RUPSLB for %s." % str(meeting.get("ticker", company_id.to_upper())),
		"chain": result.get("chain", {}).duplicate(true),
		"meeting": meeting
	}


func debug_schedule_next_day_backdoor_listing_rupslb(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	var holding: Dictionary = RunState.get_holding(company_id)
	if int(holding.get("shares", 0)) < get_lot_size():
		return {"success": false, "message": "Own at least 1 lot first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_schedule_next_day_backdoor_listing_rupslb(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not schedule a next-day backdoor listing RUPSLB for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_schedule_next_day_backdoor_listing_rupslb")
	var meeting: Dictionary = result.get("meeting", {}).duplicate(true)
	return {
		"success": true,
		"message": "Scheduled next-day backdoor listing RUPSLB for %s." % str(meeting.get("ticker", company_id.to_upper())),
		"chain": result.get("chain", {}).duplicate(true),
		"meeting": meeting
	}


func debug_schedule_next_day_restructuring_rupslb(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	var holding: Dictionary = RunState.get_holding(company_id)
	if int(holding.get("shares", 0)) < get_lot_size():
		return {"success": false, "message": "Own at least 1 lot first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_schedule_next_day_restructuring_rupslb(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not schedule a next-day restructuring RUPSLB for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_schedule_next_day_restructuring_rupslb")
	var meeting: Dictionary = result.get("meeting", {}).duplicate(true)
	return {
		"success": true,
		"message": "Scheduled next-day restructuring RUPSLB for %s." % str(meeting.get("ticker", company_id.to_upper())),
		"chain": result.get("chain", {}).duplicate(true),
		"meeting": meeting
	}


func debug_schedule_next_day_ceo_change_rupslb(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	var holding: Dictionary = RunState.get_holding(company_id)
	if int(holding.get("shares", 0)) < get_lot_size():
		return {"success": false, "message": "Own at least 1 lot first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_schedule_next_day_ceo_change_rupslb(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not schedule a next-day CEO-change RUPSLB for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_schedule_next_day_ceo_change_rupslb")
	var meeting: Dictionary = result.get("meeting", {}).duplicate(true)
	return {
		"success": true,
		"message": "Scheduled next-day CEO-change RUPSLB for %s." % str(meeting.get("ticker", company_id.to_upper())),
		"chain": result.get("chain", {}).duplicate(true),
		"meeting": meeting
	}


func get_stock_contact_tip_options(company_id: String) -> Dictionary:
	var rows: Array = []
	if not RunState.has_active_run():
		return {
			"enabled": false,
			"company_id": "",
			"rows": rows,
			"status_text": "Start or load a run first.",
			"tooltip_text": "Start or load a run first."
		}
	if company_id.is_empty():
		return {
			"enabled": false,
			"company_id": "",
			"rows": rows,
			"status_text": "Pick a stock first.",
			"tooltip_text": "Select a stock in STOCKBOT first."
		}
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	if definition.is_empty():
		return {
			"enabled": false,
			"company_id": "",
			"rows": rows,
			"status_text": "Pick a valid stock first.",
			"tooltip_text": "Select a valid stock in STOCKBOT first."
		}
	var ticker: String = str(definition.get("ticker", company_id.to_upper()))
	var sector_id: String = str(definition.get("sector_id", ""))
	var network_snapshot: Dictionary = get_network_snapshot()
	var met_count: int = 0
	var already_asked_count: int = 0
	for contact_value in network_snapshot.get("contacts", []):
		if typeof(contact_value) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = contact_value
		if not bool(contact.get("met", false)):
			continue
		met_count += 1
		if int(contact.get("last_tip_request_day_index", -9999)) == RunState.day_index:
			already_asked_count += 1
			continue
		var relevance: Dictionary = _stock_contact_tip_relevance(contact, company_id, sector_id)
		if int(relevance.get("group", 99)) >= 90:
			continue
		var role_text: String = str(contact.get("role", contact.get("affiliation_role", "Contact")))
		var relevance_label: String = str(relevance.get("label", "Market read"))
		rows.append({
			"id": str(contact.get("id", "")),
			"label": "%s - %s" % [str(contact.get("display_name", "Contact")), relevance_label],
			"display_name": str(contact.get("display_name", "Contact")),
			"role": role_text,
			"relationship": int(contact.get("relationship", 0)),
			"relevance_group": int(relevance.get("group", 99)),
			"relevance_score": int(relevance.get("score", 0)),
			"relevance_label": relevance_label
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("relevance_group", 99)) != int(b.get("relevance_group", 99)):
			return int(a.get("relevance_group", 99)) < int(b.get("relevance_group", 99))
		if int(a.get("relationship", 0)) != int(b.get("relationship", 0)):
			return int(a.get("relationship", 0)) > int(b.get("relationship", 0))
		if int(a.get("relevance_score", 0)) != int(b.get("relevance_score", 0)):
			return int(a.get("relevance_score", 0)) > int(b.get("relevance_score", 0))
		return str(a.get("label", "")) < str(b.get("label", ""))
	)
	var tip_cost: int = get_network_action_cost("tip")
	if rows.is_empty():
		var status_text: String = "Meet a relevant Network contact before asking about %s." % ticker
		var tooltip_text: String = "Discover and meet contacts from News or referrals first."
		if met_count > 0 and already_asked_count >= met_count:
			status_text = "You already asked every relevant contact today."
			tooltip_text = "Wait until tomorrow before asking these contacts for another read."
		elif met_count > 0:
			status_text = "No met contact has a clean read on %s yet." % ticker
			tooltip_text = "Read linked News or ask for referrals to discover better contacts."
		return {
			"enabled": false,
			"company_id": company_id,
			"rows": rows,
			"status_text": status_text,
			"tooltip_text": tooltip_text
		}
	if not _can_spend_network_action("tip"):
		return {
			"enabled": false,
			"company_id": company_id,
			"rows": rows,
			"status_text": "Need %d AP to ask a contact about %s." % [tip_cost, ticker],
			"tooltip_text": _network_action_no_ap_message("tip")
		}
	return {
		"enabled": true,
		"company_id": company_id,
		"rows": rows,
		"status_text": "Ask a contact for a read on %s (%d AP)." % [ticker, tip_cost],
		"tooltip_text": "Ask a met Network contact for corporate-action or tape context."
	}


func ask_stock_contact_tip(company_id: String, contact_id: String = "") -> Dictionary:
	var option_state: Dictionary = get_stock_contact_tip_options(company_id)
	if not bool(option_state.get("enabled", false)):
		return {"success": false, "message": str(option_state.get("status_text", "Could not ask a contact."))}
	var selected_contact_id: String = str(contact_id)
	if selected_contact_id.is_empty():
		var rows: Array = option_state.get("rows", [])
		if not rows.is_empty() and typeof(rows[0]) == TYPE_DICTIONARY:
			selected_contact_id = str(rows[0].get("id", ""))
	if selected_contact_id.is_empty():
		return {"success": false, "message": "Pick a Network contact first."}
	return request_contact_tip(selected_contact_id, company_id)


func get_governance_control_options(company_id: String) -> Dictionary:
	var rows: Array = _governance_control_action_rows()
	if not RunState.has_active_run():
		return {
			"enabled": false,
			"company_id": "",
			"rows": rows,
			"status_text": "Start or load a run first.",
			"tooltip_text": "Start or load a run first."
		}
	if company_id.is_empty():
		return {
			"enabled": false,
			"company_id": "",
			"rows": rows,
			"status_text": "Pick a stock first.",
			"tooltip_text": "Select a controlled company first."
		}
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	if definition.is_empty():
		return {
			"enabled": false,
			"company_id": "",
			"rows": rows,
			"status_text": "Pick a valid stock first.",
			"tooltip_text": "Select a valid controlled company first."
		}
	var ticker: String = str(definition.get("ticker", company_id.to_upper()))
	var ownership: Dictionary = get_company_ownership_snapshot(company_id)
	var ownership_pct: float = float(ownership.get("ownership_pct", 0.0))
	if not bool(ownership.get("is_control_shareholder", false)):
		var needed_shares: int = int(ownership.get("control_shares_needed", 0))
		return {
			"enabled": false,
			"company_id": company_id,
			"rows": rows,
			"ownership": ownership,
			"status_text": "Governance locked: own %.2f%% of %s. Need >50%% control%s." % [
				ownership_pct * 100.0,
				ticker,
				" (%d more share(s))" % needed_shares if needed_shares > 0 else ""
			],
			"tooltip_text": "Normal shareholders can attend and vote, but agenda-setting unlocks only after majority ownership."
		}
	var corporate_snapshot: Dictionary = get_company_corporate_action_snapshot(company_id)
	if bool(corporate_snapshot.get("has_live_chain", false)):
		return {
			"enabled": false,
			"company_id": company_id,
			"rows": rows,
			"ownership": ownership,
			"status_text": "%s already has a live corporate action." % ticker,
			"tooltip_text": "Resolve the current corporate-action chain before setting another agenda."
		}
	return {
		"enabled": true,
		"company_id": company_id,
		"rows": rows,
		"ownership": ownership,
		"status_text": "Majority control unlocked for %s. Pick an agenda for the next RUPSLB." % ticker,
		"tooltip_text": "Use majority ownership to schedule a company-direction RUPSLB agenda."
	}


func get_company_management_snapshot(selected_company_id: String = "") -> Dictionary:
	var controlled_rows: Array = []
	var candidate_rows: Array = []
	if not RunState.has_active_run():
		return {
			"unlocked": false,
			"controlled_rows": controlled_rows,
			"candidate_rows": candidate_rows,
			"selected_company_id": "",
			"selected_options": get_governance_control_options(""),
			"status_text": "Start or load a run first."
		}
	var holdings: Dictionary = RunState.player_portfolio.get("holdings", {})
	for company_id_value in holdings.keys():
		var company_id: String = str(company_id_value)
		var holding: Dictionary = holdings.get(company_id, {})
		if int(holding.get("shares", 0)) <= 0:
			continue
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		if definition.is_empty():
			continue
		var ownership: Dictionary = get_company_ownership_snapshot(company_id)
		var row: Dictionary = {
			"company_id": company_id,
			"ticker": str(definition.get("ticker", company_id.to_upper())),
			"name": str(definition.get("name", company_id.to_upper())),
			"shares_owned": int(ownership.get("shares_owned", 0)),
			"shares_outstanding": float(ownership.get("shares_outstanding", 0.0)),
			"ownership_pct": float(ownership.get("ownership_pct", 0.0)),
			"is_control_shareholder": bool(ownership.get("is_control_shareholder", false)),
			"control_shares_needed": int(ownership.get("control_shares_needed", 0)),
			"control_required_shares": int(ownership.get("control_required_shares", 0))
		}
		if bool(row.get("is_control_shareholder", false)):
			controlled_rows.append(row)
		else:
			candidate_rows.append(row)
	controlled_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("ownership_pct", 0.0)) > float(b.get("ownership_pct", 0.0))
	)
	candidate_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("ownership_pct", 0.0)) > float(b.get("ownership_pct", 0.0))
	)
	var resolved_company_id: String = selected_company_id
	var controlled_ids: Array = []
	for row_value in controlled_rows:
		if typeof(row_value) == TYPE_DICTIONARY:
			controlled_ids.append(str(row_value.get("company_id", "")))
	if resolved_company_id.is_empty() or not controlled_ids.has(resolved_company_id):
		resolved_company_id = str(controlled_rows[0].get("company_id", "")) if not controlled_rows.is_empty() else ""
	var selected_options: Dictionary = get_governance_control_options(resolved_company_id)
	var status_text: String = "You have no company yet."
	if not controlled_rows.is_empty():
		status_text = "Manage company direction for %d controlled holding(s)." % controlled_rows.size()
	elif not candidate_rows.is_empty():
		status_text = "You have no company yet."
	return {
		"unlocked": not controlled_rows.is_empty(),
		"controlled_rows": controlled_rows,
		"candidate_rows": candidate_rows,
		"selected_company_id": resolved_company_id,
		"selected_options": selected_options,
		"status_text": status_text
	}


func request_governance_control_action(company_id: String, action_id: String) -> Dictionary:
	var block_reason: String = get_life_action_block_reason("governance")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var option_state: Dictionary = get_governance_control_options(company_id)
	if not bool(option_state.get("enabled", false)):
		return {"success": false, "message": str(option_state.get("status_text", "Governance control is locked."))}
	var action: Dictionary = _governance_control_action_by_id(action_id)
	if action.is_empty():
		return {"success": false, "message": "Pick a governance agenda first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.schedule_player_control_rupslb(RunState, DataRepository, company_id, str(action.get("id", "")))
	if result.is_empty():
		return {"success": false, "message": "Could not schedule a controlled RUPSLB for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("governance_control_request")
	network_changed.emit()
	var meeting: Dictionary = result.get("meeting", {}).duplicate(true)
	return {
		"success": true,
		"message": "Majority control used: scheduled %s RUPSLB for %s on %s." % [
			str(action.get("label", "Corporate Action")),
			str(meeting.get("ticker", company_id.to_upper())),
			format_trade_date(meeting.get("trade_date", {}))
		],
		"action_id": str(action.get("id", "")),
		"chain": result.get("chain", {}).duplicate(true),
		"meeting": meeting
	}


func _governance_control_action_rows() -> Array:
	var rows: Array = []
	for action_value in GOVERNANCE_CONTROL_ACTIONS:
		var action: Dictionary = action_value
		rows.append(action.duplicate(true))
	return rows


func _governance_control_action_by_id(action_id: String) -> Dictionary:
	for action_value in GOVERNANCE_CONTROL_ACTIONS:
		var action: Dictionary = action_value
		if str(action.get("id", "")) == action_id:
			return action.duplicate(true)
	return {}


func _debug_corporate_action_generator_by_id(generator_id: String) -> Dictionary:
	for group_value in DEBUG_CORPORATE_ACTION_GENERATOR_GROUPS:
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


func _debug_index_review_generator_by_id(generator_id: String) -> Dictionary:
	for group_value in get_debug_index_review_generator_catalog():
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


func _debug_company_roadmap_generator_by_id(generator_id: String) -> Dictionary:
	for group_value in DEBUG_COMPANY_ROADMAP_GENERATOR_GROUPS:
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


func _stock_contact_tip_relevance(contact: Dictionary, company_id: String, sector_id: String) -> Dictionary:
	var score: int = int(contact.get("relationship", 0))
	var group: int = 90
	var label: String = "Market read"
	var affiliation_type: String = str(contact.get("affiliation_type", "floater"))
	var target_company_ids: Array = contact.get("target_company_ids", [])
	var company_linked: bool = false
	if target_company_ids.has(company_id):
		score += 80
		company_linked = true
	if str(contact.get("target_company_id", "")) == company_id:
		score += 60
		company_linked = true
	if str(contact.get("affiliated_company_id", "")) == company_id or str(contact.get("company_id", "")) == company_id:
		score += 100
		company_linked = true
	if company_linked and affiliation_type != "floater":
		group = 0
		label = "Company insider"
	elif company_linked:
		group = 1
		label = "Company lead"
	var sector_linked: bool = false
	if not sector_id.is_empty():
		if str(contact.get("target_sector_id", "")) == sector_id:
			score += 30
			sector_linked = true
		var sector_ids: Array = contact.get("sector_ids", [])
		if sector_ids.has(sector_id):
			score += 20
			sector_linked = true
	if not company_linked and sector_linked:
		group = 2
		label = "Sector read"
	if str(contact.get("affiliation_type", "floater")) == "floater":
		score += 10
	return {
		"group": group,
		"score": score,
		"label": label
	}


func debug_force_stock_buyback_execution(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_force_stock_buyback_execution(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not force stock buyback execution for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_force_stock_buyback_execution")
	return {
		"success": true,
		"message": "Forced stock buyback execution for %s." % str(result.get("chain", {}).get("target_ticker", company_id.to_upper())),
		"chain": result.get("chain", {}).duplicate(true)
	}


func debug_force_stock_split_execution(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_force_stock_split_execution(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not force stock split execution for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_force_stock_split_execution")
	return {
		"success": true,
		"message": "Forced stock split execution for %s." % str(result.get("chain", {}).get("target_ticker", company_id.to_upper())),
		"chain": result.get("chain", {}).duplicate(true)
	}


func debug_force_tender_offer_execution(company_id: String, force_go_private: bool = false) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_force_tender_offer_execution(RunState, DataRepository, company_id, force_go_private)
	if result.is_empty():
		return {"success": false, "message": "Could not force tender offer execution for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_force_tender_offer_execution")
	return {
		"success": true,
		"message": "Forced tender offer execution for %s." % str(result.get("chain", {}).get("target_ticker", company_id.to_upper())),
		"chain": result.get("chain", {}).duplicate(true)
	}


func debug_force_strategic_mna_execution(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_force_strategic_mna_execution(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not force strategic M&A execution for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_force_strategic_mna_execution")
	return {
		"success": true,
		"message": "Forced strategic M&A execution for %s." % str(result.get("chain", {}).get("target_ticker", company_id.to_upper())),
		"chain": result.get("chain", {}).duplicate(true)
	}


func debug_force_backdoor_listing_execution(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_force_backdoor_listing_execution(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not force backdoor listing execution for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_force_backdoor_listing_execution")
	return {
		"success": true,
		"message": "Forced backdoor listing execution for %s." % str(result.get("chain", {}).get("target_ticker", company_id.to_upper())),
		"chain": result.get("chain", {}).duplicate(true)
	}


func debug_force_restructuring_execution(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_force_restructuring_execution(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not force restructuring execution for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_force_restructuring_execution")
	return {
		"success": true,
		"message": "Forced restructuring execution for %s." % str(result.get("chain", {}).get("target_ticker", company_id.to_upper())),
		"chain": result.get("chain", {}).duplicate(true)
	}


func debug_force_ceo_change_execution(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_force_ceo_change_execution(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not force CEO-change execution for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_force_ceo_change_execution")
	return {
		"success": true,
		"message": "Forced CEO-change execution for %s." % str(result.get("chain", {}).get("target_ticker", company_id.to_upper())),
		"chain": result.get("chain", {}).duplicate(true)
	}


func debug_schedule_next_day_cash_dividend(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_schedule_next_day_cash_dividend(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not schedule a next-day cash dividend for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_schedule_next_day_cash_dividend")
	var dividend: Dictionary = result.get("dividend", {}).duplicate(true)
	return {
		"success": true,
		"message": "Scheduled next-day cash dividend for %s." % str(dividend.get("ticker", company_id.to_upper())),
		"dividend": dividend
	}


func debug_schedule_next_day_stock_dividend(company_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if company_id.is_empty():
		return {"success": false, "message": "Pick a stock first."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.debug_schedule_next_day_stock_dividend(RunState, DataRepository, company_id)
	if result.is_empty():
		return {"success": false, "message": "Could not schedule a next-day stock dividend for that company."}
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("debug_schedule_next_day_stock_dividend")
	var dividend: Dictionary = result.get("dividend", {}).duplicate(true)
	return {
		"success": true,
		"message": "Scheduled next-day stock dividend for %s." % str(dividend.get("ticker", company_id.to_upper())),
		"dividend": dividend
	}


func get_unlocked_news_intel_level() -> int:
	return 1


func get_unlocked_twooter_access_tier() -> int:
	return 4


func get_unlocked_chart_indicator_ids() -> Array:
	var track: Dictionary = _upgrade_track("chart_indicators")
	var tier_data: Dictionary = _upgrade_tier_data(track, RunState.get_upgrade_tier("chart_indicators"))
	return tier_data.get("indicator_ids", []).duplicate()


func get_daily_action_snapshot() -> Dictionary:
	return RunState.get_daily_action_snapshot()


func get_thesis_report_action_cost() -> int:
	return THESIS_REPORT_ACTION_COST


func try_spend_daily_action(action_id: String, metadata: Dictionary = {}) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var block_reason: String = get_life_action_block_reason(action_id)
	if not block_reason.is_empty():
		return {
			"success": false,
			"message": block_reason,
			"snapshot": RunState.get_daily_action_snapshot()
		}
	if not RunState.can_spend_daily_action(1):
		return {
			"success": false,
			"message": "No daily action points left.",
			"action_id": action_id,
			"metadata": metadata.duplicate(true),
			"snapshot": RunState.get_daily_action_snapshot()
		}
	var result: Dictionary = RunState.spend_daily_action(1)
	if bool(result.get("success", false)):
		_request_autosave("spend_daily_action")
		daily_actions_changed.emit()
	result["action_id"] = action_id
	result["metadata"] = metadata.duplicate(true)
	return result


func get_network_action_cost(action_id: String) -> int:
	return int(NETWORK_ACTION_COSTS.get(action_id, 1))


func _can_spend_network_action(action_id: String) -> bool:
	if not get_life_action_block_reason(action_id).is_empty():
		return false
	return RunState.can_spend_daily_action(get_network_action_cost(action_id))


func _spend_network_action(action_id: String) -> Dictionary:
	var block_reason: String = get_life_action_block_reason(action_id)
	if not block_reason.is_empty():
		return {
			"success": false,
			"message": block_reason,
			"snapshot": RunState.get_daily_action_snapshot()
		}
	return RunState.spend_daily_action(get_network_action_cost(action_id))


func _network_action_no_ap_message(action_id: String) -> String:
	var block_reason: String = get_life_action_block_reason(action_id)
	if not block_reason.is_empty():
		return block_reason
	return "Need %d AP for this Network action." % get_network_action_cost(action_id)


func get_academy_snapshot(category_id: String = "mindset", section_id: String = "") -> Dictionary:
	var requested_category_id: String = category_id
	if requested_category_id.is_empty():
		requested_category_id = str(RunState.get_academy_progress().get("last_category_id", "mindset"))
	var requested_section_id: String = section_id
	if requested_section_id.is_empty():
		requested_section_id = str(RunState.get_academy_progress().get("last_section_id", "survival_mindset"))
	return academy_system.build_snapshot(
		DataRepository.get_academy_catalog(),
		RunState.get_academy_progress(),
		requested_category_id,
		requested_section_id
	)


func mark_academy_section_read(category_id: String, section_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var was_read: bool = _academy_section_was_read(category_id, section_id)
	var result: Dictionary = academy_system.mark_section_read(
		DataRepository.get_academy_catalog(),
		RunState.get_academy_progress(),
		category_id,
		section_id
	)
	if bool(result.get("success", false)):
		RunState.set_academy_progress(result.get("progress", {}))
		if not was_read:
			_record_steam_progress_event("academy_lesson_completed", {
				"category_id": category_id,
				"section_id": section_id
			})
		_request_autosave("academy_mark_read")
		academy_changed.emit()
	return result


func submit_academy_inline_check(
	category_id: String,
	section_id: String,
	check_id: String,
	answer_id: String
) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var result: Dictionary = academy_system.submit_inline_check(
		DataRepository.get_academy_catalog(),
		RunState.get_academy_progress(),
		category_id,
		section_id,
		check_id,
		answer_id
	)
	if bool(result.get("success", false)):
		RunState.set_academy_progress(result.get("progress", {}))
		_request_autosave("academy_inline_check")
		academy_changed.emit()
	return result


func submit_academy_quiz(category_id: String, answers: Dictionary) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var had_passed: bool = bool(RunState.get_academy_progress().get("quiz_passed", {}).get(category_id, false))
	var result: Dictionary = academy_system.submit_quiz(
		DataRepository.get_academy_catalog(),
		RunState.get_academy_progress(),
		category_id,
		answers
	)
	if bool(result.get("success", false)):
		RunState.set_academy_progress(result.get("progress", {}))
		if bool(result.get("passed", false)) and not had_passed:
			_record_steam_progress_event("academy_quiz_passed", {
				"category_id": category_id,
				"score_percent": int(result.get("score_percent", 0))
			})
		_request_autosave("academy_quiz")
		academy_changed.emit()
	return result


func search_academy_glossary(query: String) -> Array:
	return academy_system.search_glossary(DataRepository.get_academy_catalog(), query)


func is_academy_available() -> bool:
	return RunState.GUIDE_FLOW_SYSTEM.flow_enabled(RunState.GUIDE_FLOW_SYSTEM.FLOW_ACADEMY)


func get_academy_release_message() -> String:
	return "Academy lessons are coming soon."


func get_watchlist_company_ids() -> Array:
	return RunState.get_watchlist_company_ids()


func get_company_rows() -> Array:
	var rows: Array = []
	for company_id in RunState.company_order:
		rows.append(get_company_snapshot(str(company_id), false, false, false))
	return rows


func get_company_market_rows(force_refresh: bool = false) -> Array:
	if not RunState.has_active_run():
		company_market_rows_cache = {}
		return []
	var cache_key: String = _company_market_rows_cache_key()
	if (
		force_refresh or
		company_market_rows_cache.is_empty() or
		str(company_market_rows_cache.get("cache_key", "")) != cache_key
	):
		company_market_rows_cache = {
			"cache_key": cache_key,
			"rows": _build_company_market_rows()
		}
	return company_market_rows_cache.get("rows", []).duplicate(true)


func get_report_calendar_snapshot(year_value: int = 0, month_value: int = 0) -> Dictionary:
	var trade_date: Dictionary = RunState.get_current_trade_date()
	var resolved_year: int = int(trade_date.get("year", 2020)) if year_value <= 0 else year_value
	var resolved_month: int = int(trade_date.get("month", 1)) if month_value <= 0 else month_value
	if _is_current_report_calendar_month(resolved_year, resolved_month):
		return get_dashboard_event_snapshot().get("report_calendar_snapshot", {}).duplicate(true)
	return RunState.get_report_calendar_month(resolved_year, resolved_month)


func get_upcoming_report_rows(limit: int = 8) -> Array:
	if limit > 0 and limit <= DASHBOARD_REPORT_ROW_CACHE_LIMIT:
		var rows: Array = get_dashboard_event_snapshot().get("upcoming_report_rows", []).duplicate(true)
		if rows.size() > limit:
			rows = rows.slice(0, limit)
		return rows
	return RunState.get_upcoming_quarterly_reports(limit)


func get_dashboard_event_snapshot(force_refresh: bool = false) -> Dictionary:
	if not RunState.has_active_run():
		return _empty_dashboard_event_snapshot()
	var cache_key: String = _dashboard_event_snapshot_cache_key()
	if (
		force_refresh or
		dashboard_event_snapshot_cache.is_empty() or
		str(dashboard_event_snapshot_cache.get("cache_key", "")) != cache_key
	):
		_rebuild_dashboard_event_snapshot_cache(cache_key)
	return dashboard_event_snapshot_cache.duplicate(true)


func get_corporate_meeting_snapshot(day_index: int = -1) -> Dictionary:
	if not RunState.has_active_run():
		return {"day_index": 0, "trade_date": {}, "today_rows": [], "upcoming_rows": [], "all_rows": []}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	return corporate_action_system.get_meeting_snapshot(RunState, day_index)


func _rebuild_dashboard_event_snapshot_cache(cache_key: String = "", log_phase_details: bool = false) -> Dictionary:
	if not RunState.has_active_run():
		dashboard_event_snapshot_cache = _empty_dashboard_event_snapshot()
		return dashboard_event_snapshot_cache
	var phase_started_at_usec: int = Time.get_ticks_usec()
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	_log_advance_perf_elapsed(log_phase_details, "build_dashboard_event_cache:ensure_corporate_actions", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	index_review_system.ensure_initialized(RunState, DataRepository)
	_log_advance_perf_elapsed(log_phase_details, "build_dashboard_event_cache:ensure_index_reviews", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var trade_date: Dictionary = RunState.get_current_trade_date()
	var report_calendar_snapshot: Dictionary = RunState.get_report_calendar_month(
		int(trade_date.get("year", 2020)),
		int(trade_date.get("month", 1))
	)
	_log_advance_perf_elapsed(log_phase_details, "build_dashboard_event_cache:report_calendar", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var meeting_snapshot: Dictionary = corporate_action_system.get_dashboard_meeting_snapshot(RunState, -1, 12)
	var prioritized_today_rows: Array = _prioritized_dashboard_meeting_rows(meeting_snapshot.get("today_rows", []), true)
	var prioritized_upcoming_rows: Array = _prioritized_dashboard_meeting_rows(meeting_snapshot.get("upcoming_rows", []), false)
	meeting_snapshot["today_rows"] = prioritized_today_rows.duplicate(true)
	meeting_snapshot["upcoming_rows"] = prioritized_upcoming_rows.duplicate(true)
	_log_advance_perf_elapsed(log_phase_details, "build_dashboard_event_cache:meeting_snapshot", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var index_review_snapshot: Dictionary = index_review_system.get_dashboard_snapshot(RunState, DataRepository, 10)
	_log_advance_perf_elapsed(log_phase_details, "build_dashboard_event_cache:index_reviews", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var upcoming_report_rows: Array = RunState.get_upcoming_quarterly_reports(DASHBOARD_REPORT_ROW_CACHE_LIMIT)
	_log_advance_perf_elapsed(log_phase_details, "build_dashboard_event_cache:upcoming_reports", phase_started_at_usec)
	var resolved_cache_key: String = cache_key if not cache_key.is_empty() else _dashboard_event_snapshot_cache_key()
	dashboard_event_snapshot_cache = {
		"cache_key": resolved_cache_key,
		"day_index": RunState.day_index,
		"trade_date": trade_date,
		"report_calendar_snapshot": report_calendar_snapshot,
		"upcoming_report_rows": upcoming_report_rows,
		"corporate_meeting_snapshot": meeting_snapshot,
		"upcoming_meeting_rows": prioritized_upcoming_rows.duplicate(true),
		"index_review_snapshot": index_review_snapshot,
		"upcoming_index_review_rows": index_review_snapshot.get("upcoming_rows", []).duplicate(true)
	}
	return dashboard_event_snapshot_cache


func _invalidate_dashboard_event_snapshot_cache() -> void:
	dashboard_event_snapshot_cache = {}


func _invalidate_company_market_rows_cache() -> void:
	company_market_rows_cache = {}


func _invalidate_broker_range_snapshot_cache() -> void:
	broker_range_snapshot_cache = {}


func _empty_dashboard_event_snapshot() -> Dictionary:
	return {
		"cache_key": "",
		"day_index": RunState.day_index if RunState.has_active_run() else 0,
		"trade_date": RunState.get_current_trade_date() if RunState.has_active_run() else {},
		"report_calendar_snapshot": {},
		"upcoming_report_rows": [],
		"corporate_meeting_snapshot": {
			"day_index": RunState.day_index if RunState.has_active_run() else 0,
			"trade_date": RunState.get_current_trade_date() if RunState.has_active_run() else {},
			"today_rows": [],
			"upcoming_rows": [],
			"all_rows": []
		},
		"upcoming_meeting_rows": [],
		"index_review_snapshot": {
			"day_index": RunState.day_index if RunState.has_active_run() else 0,
			"trade_date": RunState.get_current_trade_date() if RunState.has_active_run() else {},
			"upcoming_rows": [],
			"providers": []
		},
		"upcoming_index_review_rows": []
	}


func _prioritized_dashboard_meeting_rows(rows: Array, only_same_day: bool = false) -> Array:
	var current_trading_day_number: int = max(RunState.day_index + 1, 1)
	var same_day_rows: Array = []
	var other_rows: Array = []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value.duplicate(true)
		if int(row.get("trading_day_number", 0)) == current_trading_day_number:
			same_day_rows.append(row)
		elif not only_same_day:
			other_rows.append(row)
	same_day_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var left_priority: int = _dashboard_meeting_priority(a)
		var right_priority: int = _dashboard_meeting_priority(b)
		if left_priority == right_priority:
			return str(a.get("ticker", "")) < str(b.get("ticker", ""))
		return left_priority > right_priority
	)
	if same_day_rows.size() > FIRST_MONTH_SAME_DAY_MEETING_CTA_LIMIT:
		same_day_rows = same_day_rows.slice(0, FIRST_MONTH_SAME_DAY_MEETING_CTA_LIMIT)
	if only_same_day:
		return same_day_rows
	var result: Array = same_day_rows
	for row_value in other_rows:
		result.append(row_value)
	return result


func _dashboard_meeting_priority(row: Dictionary) -> int:
	var company_id: String = str(row.get("company_id", ""))
	var priority: int = 0
	var holding: Dictionary = RunState.player_portfolio.get("holdings", {}).get(company_id, {})
	if int(holding.get("shares", 0)) > 0:
		priority += 100
	if RunState.is_in_watchlist(company_id):
		priority += 50
	if bool(row.get("interactive_v1", false)):
		priority += 10
	return priority


func _is_current_report_calendar_month(year_value: int, month_value: int) -> bool:
	if not RunState.has_active_run():
		return false
	var trade_date: Dictionary = RunState.get_current_trade_date()
	return int(trade_date.get("year", 2020)) == year_value and int(trade_date.get("month", 1)) == month_value


func _dashboard_event_snapshot_cache_key() -> String:
	if not RunState.has_active_run():
		return ""
	var trade_date: Dictionary = RunState.get_current_trade_date()
	var holding_parts: Array = []
	var holdings: Dictionary = RunState.player_portfolio.get("holdings", {})
	for company_id_value in holdings.keys():
		var company_id: String = str(company_id_value)
		var holding: Dictionary = holdings.get(company_id, {})
		holding_parts.append("%s:%d" % [company_id, int(holding.get("shares", 0))])
	holding_parts.sort()
	var attended_parts: Array = []
	for meeting_id_value in RunState.attended_meetings.keys():
		var meeting_id: String = str(meeting_id_value)
		var attended_row: Dictionary = RunState.attended_meetings.get(meeting_id, {})
		if bool(attended_row.get("attended", false)):
			attended_parts.append("%s:%d" % [meeting_id, int(attended_row.get("day_index", 0))])
	attended_parts.sort()
	var meeting_parts: Array = []
	for date_key_value in RunState.corporate_meeting_calendar.keys():
		var date_key: String = str(date_key_value)
		for meeting_value in RunState.corporate_meeting_calendar.get(date_key, []):
			var meeting: Dictionary = meeting_value
			meeting_parts.append("%s:%s:%d" % [
				str(meeting.get("id", "")),
				str(meeting.get("status", "")),
				int(meeting.get("trading_day_number", 0))
			])
	meeting_parts.sort()
	var index_review_parts: Array = []
	var index_state: Dictionary = RunState.get_index_review_state()
	var providers: Dictionary = index_state.get("providers", {})
	for provider_id_value in providers.keys():
		var provider_id: String = str(provider_id_value)
		var provider_state: Dictionary = providers.get(provider_id, {})
		var member_count: int = provider_state.get("members", []).size()
		var watch_count: int = provider_state.get("candidate_watch", []).size()
		var schedule_flags: Array = []
		for review_value in provider_state.get("schedule", {}).values():
			if typeof(review_value) != TYPE_DICTIONARY:
				continue
			var review: Dictionary = review_value
			schedule_flags.append("%s:%d:%d:%s:%s" % [
				str(review.get("id", "")),
				int(review.get("announcement_day_number", 0)),
				int(review.get("effective_day_number", 0)),
				str(review.get("announcement_emitted", false)),
				str(review.get("effective_applied", false))
			])
		schedule_flags.sort()
		index_review_parts.append("%s:%d:%d:%s" % [provider_id, member_count, watch_count, "|".join(schedule_flags)])
	index_review_parts.sort()
	return "%d|%s|%s|%s|%s|%s" % [
		RunState.day_index,
		trading_calendar.to_key(trade_date),
		str(STABLE_RNG.seed_from_parts(["dashboard_holdings", "|".join(holding_parts)])),
		str(STABLE_RNG.seed_from_parts(["dashboard_attended", "|".join(attended_parts)])),
		str(STABLE_RNG.seed_from_parts(["dashboard_meetings", "|".join(meeting_parts)])),
		str(STABLE_RNG.seed_from_parts(["dashboard_index_reviews", "|".join(index_review_parts)]))
	]


func get_corporate_meeting_detail(meeting_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	return corporate_action_system.get_meeting_detail(RunState, meeting_id)


func get_company_corporate_action_snapshot(company_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	return corporate_action_system.get_company_snapshot(RunState, company_id)


func get_company_corporate_action_timeline(company_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	return corporate_action_system.get_company_timeline_snapshot(RunState, company_id)


func get_index_review_snapshot() -> Dictionary:
	if not RunState.has_active_run():
		return {"day_index": 0, "trade_date": {}, "upcoming_rows": [], "providers": []}
	index_review_system.ensure_initialized(RunState, DataRepository)
	return index_review_system.get_dashboard_snapshot(RunState, DataRepository, 10)


func get_company_index_review_snapshot(company_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {}
	index_review_system.ensure_initialized(RunState, DataRepository)
	return index_review_system.get_company_index_snapshot(RunState, DataRepository, company_id)


func get_corporate_dividend_snapshot(company_id: String = "") -> Dictionary:
	if not RunState.has_active_run():
		return {}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	return corporate_action_system.get_dividend_snapshot(RunState, company_id)


func attend_corporate_meeting(meeting_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.attend_meeting(RunState, meeting_id)
	if bool(result.get("success", false)):
		_record_steam_progress_event("rupslb_attended", {"meeting_id": meeting_id})
		_invalidate_dashboard_event_snapshot_cache()
		_request_autosave("corporate_meeting_attend")
		network_changed.emit()
	return result


func start_corporate_meeting_session(meeting_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.start_meeting_session(RunState, DataRepository, meeting_id)
	if bool(result.get("success", false)):
		result["session"] = _decorate_corporate_meeting_session_snapshot(result.get("session", {}))
		_invalidate_dashboard_event_snapshot_cache()
		_request_autosave("corporate_meeting_session_start")
		network_changed.emit()
	return result


func get_corporate_meeting_session_snapshot(meeting_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	return _decorate_corporate_meeting_session_snapshot(
		corporate_action_system.get_meeting_session_snapshot(RunState, DataRepository, meeting_id)
	)


func _decorate_corporate_meeting_session_snapshot(session_snapshot: Dictionary) -> Dictionary:
	if session_snapshot.is_empty():
		return {}
	return contact_network_system.decorate_meeting_session_snapshot(
		RunState,
		DataRepository,
		session_snapshot,
		_can_spend_network_action("meet"),
		get_network_action_cost("meet")
	)


func set_corporate_meeting_session_stage(meeting_id: String, stage_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.set_meeting_session_stage(RunState, DataRepository, meeting_id, stage_id)
	if bool(result.get("success", false)):
		result["session"] = _decorate_corporate_meeting_session_snapshot(result.get("session", {}))
		_request_autosave("corporate_meeting_session_stage")
	return result


func submit_corporate_meeting_vote(meeting_id: String, agenda_id: String, vote_choice: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var detail: Dictionary = corporate_action_system.get_meeting_detail(RunState, meeting_id)
	if detail.is_empty():
		return {"success": false, "message": "Meeting not found."}
	var ownership_snapshot: Dictionary = detail.get("ownership_snapshot", {}).duplicate(true)
	if ownership_snapshot.is_empty():
		ownership_snapshot = get_company_ownership_snapshot(str(detail.get("company_id", "")))
	var result: Dictionary = corporate_action_system.submit_meeting_vote(
		RunState,
		DataRepository,
		meeting_id,
		agenda_id,
		vote_choice,
		ownership_snapshot
	)
	if bool(result.get("success", false)):
		result["session"] = _decorate_corporate_meeting_session_snapshot(result.get("session", {}))
		_record_steam_progress_event("corporate_vote_submitted", {
			"meeting_id": meeting_id,
			"agenda_id": agenda_id,
			"vote_choice": vote_choice
		})
		_invalidate_dashboard_event_snapshot_cache()
		_request_autosave("corporate_meeting_vote")
		network_changed.emit()
	return result


func approach_corporate_meeting_lead(meeting_id: String, lead_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if not _can_spend_network_action("meet"):
		return {"success": false, "message": _network_action_no_ap_message("meet")}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var session_snapshot: Dictionary = get_corporate_meeting_session_snapshot(meeting_id)
	var result: Dictionary = contact_network_system.approach_meeting_lead(
		RunState,
		DataRepository,
		session_snapshot,
		lead_id,
		true,
		get_network_action_cost("meet")
	)
	if bool(result.get("success", false)):
		_spend_network_action("meet")
		result["action_cost"] = get_network_action_cost("meet")
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("meeting_lead_approach")
		daily_actions_changed.emit()
		network_changed.emit()
	return result


func close_corporate_meeting_session(meeting_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.close_meeting_session(RunState, meeting_id)
	if bool(result.get("success", false)):
		_request_autosave("corporate_meeting_session_close")
	return result


func get_company_ownership_snapshot(company_id: String) -> Dictionary:
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	var holding: Dictionary = RunState.get_holding(company_id)
	if definition.is_empty():
		return {}

	var financials: Dictionary = definition.get("financials", {})
	var shares_outstanding: float = max(
		float(definition.get("shares_outstanding", financials.get("shares_outstanding", 0.0))),
		0.0
	)
	var shares_owned: int = int(holding.get("shares", 0))
	var control_required_shares: int = 0
	if shares_outstanding > 0.0:
		control_required_shares = int(floor(shares_outstanding * PLAYER_CONTROL_SHAREHOLDER_THRESHOLD)) + 1
	var ownership_pct: float = 0.0
	if shares_outstanding > 0.0:
		ownership_pct = clamp(float(shares_owned) / shares_outstanding, 0.0, 1.0)

	var free_float_pct: float = clamp(float(financials.get("free_float_pct", 0.0)) / 100.0, 0.0, 1.0)
	var owner_concentration_pct: float = clamp(1.0 - free_float_pct, 0.0, 1.0)
	var player_public_float_pct: float = min(ownership_pct, free_float_pct)
	var player_control_block_pct: float = max(ownership_pct - player_public_float_pct, 0.0)
	var public_float_pct: float = max(free_float_pct - player_public_float_pct, 0.0)
	var remaining_control_pct: float = max(owner_concentration_pct - player_control_block_pct, 0.0)
	var shareholder_rows: Array = []
	if remaining_control_pct > 0.0:
		shareholder_rows.append({
			"name": "Controlling Group",
			"ownership_pct": remaining_control_pct,
			"role": "Founder / strategic holder"
		})
	if ownership_pct >= PLAYER_MAJOR_SHAREHOLDER_THRESHOLD:
		shareholder_rows.append({
			"name": "Player",
			"ownership_pct": ownership_pct,
			"role": "Controlling shareholder" if control_required_shares > 0 and shares_owned >= control_required_shares else "Major shareholder"
		})
	if public_float_pct > 0.0:
		shareholder_rows.append({
			"name": "Public Float",
			"ownership_pct": public_float_pct,
			"role": "Market holders"
		})
	shareholder_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("ownership_pct", 0.0)) > float(b.get("ownership_pct", 0.0))
	)
	return {
		"company_id": company_id,
		"shares_owned": shares_owned,
		"shares_outstanding": shares_outstanding,
		"ownership_pct": ownership_pct,
		"player_pct": ownership_pct,
		"controller_pct": remaining_control_pct,
		"public_pct": public_float_pct,
		"is_major_shareholder": ownership_pct >= PLAYER_MAJOR_SHAREHOLDER_THRESHOLD,
		"major_shareholder_threshold": PLAYER_MAJOR_SHAREHOLDER_THRESHOLD,
		"is_control_shareholder": control_required_shares > 0 and shares_owned >= control_required_shares,
		"control_shareholder_threshold": PLAYER_CONTROL_SHAREHOLDER_THRESHOLD,
		"control_required_shares": control_required_shares,
		"control_shares_needed": max(control_required_shares - shares_owned, 0),
		"shareholder_rows": shareholder_rows
	}


func get_company_snapshot(
	company_id: String,
	include_price_history: bool = false,
	include_financial_history: bool = false,
	include_statement_history: bool = false
) -> Dictionary:
	var definition: Dictionary = RunState.get_effective_company_definition(
		company_id,
		include_financial_history,
		include_statement_history
	)
	var runtime: Dictionary = RunState.get_company(company_id)
	if definition.is_empty() or runtime.is_empty():
		return {}

	var sector_definition: Dictionary = DataRepository.get_sector_definition(str(definition.get("sector_id", "")))
	var holding: Dictionary = RunState.get_holding(company_id)
	var previous_close: float = RunState.get_previous_close(company_id)
	var current_price: float = float(runtime.get("current_price", 0.0))
	var listing_board: String = str(definition.get("listing_board", "main"))
	var ar_limits: Dictionary = runtime.get("ar_limits", IDX_PRICE_RULES.auto_rejection_limits(previous_close, listing_board))
	var daily_change_pct: float = 0.0
	if not is_zero_approx(previous_close):
		daily_change_pct = (current_price - previous_close) / previous_close

	var shares_owned: int = int(holding.get("shares", 0))
	var lot_size: int = get_lot_size()
	var average_price: float = float(holding.get("average_price", 0.0))
	var financials: Dictionary = definition.get("financials", {}).duplicate(true)
	var ownership_snapshot: Dictionary = get_company_ownership_snapshot(company_id)
	var financial_history: Array = []
	if include_financial_history:
		financial_history = definition.get("financial_history", []).duplicate(true)
	var starting_price: float = float(runtime.get("starting_price", current_price))
	var ytd_open_price: float = float(runtime.get("ytd_open_price", starting_price))
	var since_start_pct: float = 0.0
	var ytd_change_pct: float = 0.0
	if not is_zero_approx(starting_price):
		since_start_pct = (current_price - starting_price) / starting_price
	if not is_zero_approx(ytd_open_price):
		ytd_change_pct = (current_price - ytd_open_price) / ytd_open_price
	var include_detail_payloads: bool = include_price_history or include_financial_history or include_statement_history
	var broker_flow_view: Dictionary = _build_broker_flow_view(runtime.get("broker_flow", {}), include_detail_payloads)
	var index_review_snapshot: Dictionary = get_company_index_review_snapshot(company_id)
	var market_depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	var impactability_snapshot: Dictionary = _build_impactability_snapshot(definition, runtime, market_depth_context)
	var player_market_impact: Dictionary = runtime.get("player_market_impact", {}).duplicate(true)
	var shareholder_rows: Array = ownership_snapshot.get("shareholder_rows", [])
	var company_profile: Dictionary = runtime.get("company_profile", {})
	var delisting_watch: Dictionary = company_profile.get("delisting_watch", {}).duplicate(true) if typeof(company_profile) == TYPE_DICTIONARY else {}
	var acquisition_result: Dictionary = company_profile.get("acquisition_result", {}).duplicate(true) if typeof(company_profile) == TYPE_DICTIONARY else {}
	var backdoor_listing_result: Dictionary = company_profile.get("backdoor_listing_result", {}).duplicate(true) if typeof(company_profile) == TYPE_DICTIONARY else {}
	var backdoor_sponsor_lockup: Dictionary = company_profile.get("backdoor_sponsor_lockup", {}).duplicate(true) if typeof(company_profile) == TYPE_DICTIONARY else {}
	var backdoor_milestone_state: Dictionary = company_profile.get("backdoor_milestone_state", {}).duplicate(true) if typeof(company_profile) == TYPE_DICTIONARY else {}
	var restructuring_result: Dictionary = company_profile.get("restructuring_result", {}).duplicate(true) if typeof(company_profile) == TYPE_DICTIONARY else {}
	var ceo_change_result: Dictionary = company_profile.get("ceo_change_result", {}).duplicate(true) if typeof(company_profile) == TYPE_DICTIONARY else {}
	var management_roster: Array = definition.get("management_roster", []).duplicate(true)
	if typeof(company_profile) == TYPE_DICTIONARY and typeof(company_profile.get("management_roster", [])) == TYPE_ARRAY:
		management_roster = company_profile.get("management_roster", []).duplicate(true)
	if not ceo_change_result.is_empty():
		management_roster = _management_roster_with_ceo_change_result(
			management_roster,
			ceo_change_result,
			company_id,
			definition
		)
	var snapshot: Dictionary = {
		"id": company_id,
		"detail_status": str(definition.get("detail_status", "ready")),
		"ticker": definition.get("ticker", company_id.to_upper()),
		"name": definition.get("name", ""),
		"sector_id": str(definition.get("sector_id", "")),
		"sector_name": sector_definition.get("name", "Unknown"),
		"archetype_id": str(definition.get("archetype_id", "")),
		"archetype_label": str(definition.get("archetype_label", "")),
		"company_size_id": int(definition.get("company_size_id", 0)),
		"company_size_label": str(definition.get("company_size_label", "")),
		"company_age": int(definition.get("company_age", 0)),
		"founded_year": int(definition.get("founded_year", 0)),
		"employee_count": int(definition.get("employee_count", 0)),
		"profile_revenue": float(definition.get("profile_revenue", 0.0)),
		"profile_revenue_value": float(definition.get("profile_revenue_value", 0.0)),
		"profile_revenue_unit": str(definition.get("profile_revenue_unit", "")),
		"profile_description": str(definition.get("profile_description", "")),
		"profile_tags": definition.get("profile_tags", []).duplicate(),
		"management_roster": management_roster,
		"location_profile": definition.get("location_profile", {}).duplicate(true),
		"roadmap_profile": definition.get("roadmap_profile", {}).duplicate(true),
		"current_price": current_price,
		"previous_close": previous_close,
		"daily_change_pct": daily_change_pct,
		"quality_score": int(definition.get("quality_score", 0)),
		"growth_score": int(definition.get("growth_score", 0)),
		"risk_score": int(definition.get("risk_score", 0)),
		"financials": financials,
		"financial_history": financial_history,
		"financial_statement_snapshot": definition.get("financial_statement_snapshot", {}).duplicate(true),
		"narrative_tags": definition.get("narrative_tags", []).duplicate(),
		"sentiment": float(runtime.get("sentiment", 0.0)),
		"event_tags": runtime.get("active_event_tags", []).duplicate(),
		"active_events": runtime.get("active_events", []).duplicate(true),
		"starting_price": starting_price,
		"ytd_open_price": ytd_open_price,
		"ytd_reference_year": int(runtime.get("ytd_reference_year", int(RunState.get_current_trade_date().get("year", 2020)))),
		"since_start_pct": since_start_pct,
		"ytd_change_pct": ytd_change_pct,
		"broker_flow": broker_flow_view,
		"index_review": index_review_snapshot,
		"market_depth_context": market_depth_context,
		"impactability": impactability_snapshot,
		"player_market_impact": player_market_impact,
		"player_market_impact_summary": str(player_market_impact.get("impact_summary", "")),
		"hidden_story_flags": runtime.get("hidden_story_flags", []).duplicate(),
		"listing_status": str(company_profile.get("listing_status", "listed")) if typeof(company_profile) == TYPE_DICTIONARY else "listed",
		"listing_status_label": str(company_profile.get("listing_status_label", "Listed")) if typeof(company_profile) == TYPE_DICTIONARY else "Listed",
		"trade_disabled": bool(company_profile.get("trade_disabled", false)) if typeof(company_profile) == TYPE_DICTIONARY else false,
		"delisting_watch": delisting_watch,
		"acquisition_result": acquisition_result,
		"backdoor_listing_result": backdoor_listing_result,
		"backdoor_sponsor_lockup": backdoor_sponsor_lockup,
		"backdoor_milestone_state": backdoor_milestone_state,
		"restructuring_result": restructuring_result,
		"ceo_change_result": ceo_change_result,
		"listing_board": listing_board,
		"shares_owned": shares_owned,
		"lots_owned": int(floor(float(shares_owned) / float(lot_size))),
		"odd_lot_remainder": int(posmod(shares_owned, lot_size)),
		"tick_size": get_tick_size_for_price(current_price),
		"ara_price": float(ar_limits.get("upper_price", current_price)),
		"arb_price": float(ar_limits.get("lower_price", current_price)),
		"ara_label": str(ar_limits.get("upper_label", "")),
		"arb_label": str(ar_limits.get("lower_label", "")),
		"average_price": average_price,
		"market_value": shares_owned * current_price,
		"unrealized_pnl": (current_price - average_price) * shares_owned,
		"ownership_pct": float(ownership_snapshot.get("ownership_pct", 0.0)),
		"is_major_shareholder": bool(ownership_snapshot.get("is_major_shareholder", false)),
		"shareholder_rows": shareholder_rows.duplicate(true),
		"shares_outstanding": float(ownership_snapshot.get("shares_outstanding", 0.0))
	}

	if include_price_history:
		snapshot["price_history"] = runtime.get("price_history", []).duplicate()
		snapshot["price_bars"] = runtime.get("price_bars", []).duplicate(true)
	if include_detail_payloads:
		snapshot["broker_flow_history"] = runtime.get("broker_flow_history", []).duplicate(true)

	return snapshot


func _management_roster_with_ceo_change_result(
	management_roster: Array,
	ceo_change_result: Dictionary,
	company_id: String,
	definition: Dictionary
) -> Array:
	var new_ceo_name: String = str(ceo_change_result.get("new_ceo_name", ""))
	if new_ceo_name.is_empty():
		return management_roster.duplicate(true)
	var day_index: int = int(ceo_change_result.get("day_index", RunState.day_index))
	var next_contact_id: String = "insider_%s_ceo_%d" % [company_id, day_index]
	var next_roster: Array = []
	var has_new_ceo: bool = false
	var new_ceo_base_row: Dictionary = {}
	for management_value in management_roster:
		if typeof(management_value) != TYPE_DICTIONARY:
			continue
		var management: Dictionary = management_value.duplicate(true)
		var management_id: String = str(management.get("id", management.get("contact_id", "")))
		if management_id == next_contact_id:
			next_roster.append(_incoming_ceo_roster_row(management, ceo_change_result, definition, company_id, next_contact_id))
			has_new_ceo = true
			continue
		if str(management.get("affiliation_role", "")) == "ceo" and str(management.get("affiliation_type", "insider")) != "free_agent":
			if new_ceo_base_row.is_empty():
				new_ceo_base_row = management.duplicate(true)
			next_roster.append(_departed_ceo_roster_row(management, ceo_change_result, definition, company_id))
			continue
		next_roster.append(management)
	if not has_new_ceo:
		next_roster.insert(0, _incoming_ceo_roster_row(new_ceo_base_row, ceo_change_result, definition, company_id, next_contact_id))
	return next_roster


func _incoming_ceo_roster_row(
	base_row: Dictionary,
	ceo_change_result: Dictionary,
	definition: Dictionary,
	company_id: String,
	contact_id: String
) -> Dictionary:
	var management: Dictionary = base_row.duplicate(true)
	var new_ceo_name: String = str(ceo_change_result.get("new_ceo_name", ""))
	management.erase("previous_display_name")
	management.erase("former_affiliation_role")
	management.erase("former_company_id")
	management.erase("departed")
	management.erase("departed_day_index")
	management["contact_id"] = contact_id
	management["id"] = contact_id
	management["display_name"] = new_ceo_name
	management["affiliation_type"] = "insider"
	management["affiliation_role"] = "ceo"
	management["company_id"] = company_id
	management["affiliated_company_id"] = company_id
	management["sector_id"] = str(definition.get("sector_id", management.get("sector_id", "")))
	management["role"] = "CEO"
	management["role_label"] = "CEO"
	management["recognition_required"] = int(management.get("recognition_required", 50))
	management["base_relationship"] = int(management.get("base_relationship", 18))
	management["reliability"] = float(management.get("reliability", 0.68))
	management["tone"] = "constructive"
	management["intro"] = "%s serves as CEO at %s after a shareholder-approved leadership reset focused on %s." % [
		new_ceo_name,
		str(definition.get("name", company_id.to_upper())),
		str(ceo_change_result.get("mandate", "execution reset"))
	]
	return management


func _departed_ceo_roster_row(
	management: Dictionary,
	ceo_change_result: Dictionary,
	definition: Dictionary,
	company_id: String
) -> Dictionary:
	var departed: Dictionary = management.duplicate(true)
	var contact_id: String = str(departed.get("id", departed.get("contact_id", "")))
	if contact_id.is_empty():
		contact_id = "insider_%s_ceo" % company_id
	var previous_name: String = str(ceo_change_result.get("previous_ceo_name", ""))
	if previous_name.is_empty():
		previous_name = str(departed.get("display_name", ""))
	departed["contact_id"] = contact_id
	departed["id"] = contact_id
	departed["display_name"] = previous_name
	departed["previous_display_name"] = previous_name
	departed["affiliation_type"] = "free_agent"
	departed["affiliation_role"] = "former_ceo"
	departed["former_affiliation_role"] = "ceo"
	departed["company_id"] = company_id
	departed["affiliated_company_id"] = company_id
	departed["former_company_id"] = company_id
	departed["sector_id"] = str(definition.get("sector_id", departed.get("sector_id", "")))
	departed["role"] = "Former CEO"
	departed["role_label"] = "Former CEO"
	departed["departed"] = true
	departed["departed_day_index"] = int(ceo_change_result.get("day_index", RunState.day_index))
	departed["intro"] = "%s previously served as CEO at %s before the shareholder-approved leadership reset. They are now a free-agent market contact with residual visibility into the issuer." % [
		previous_name,
		str(definition.get("name", company_id.to_upper()))
	]
	return departed


func _build_impactability_snapshot(definition: Dictionary, runtime: Dictionary, market_depth_context: Dictionary) -> Dictionary:
	var financials: Dictionary = definition.get("financials", {})
	var company_profile: Dictionary = runtime.get("company_profile", {})
	var delisting_watch: Dictionary = company_profile.get("delisting_watch", {}) if typeof(company_profile) == TYPE_DICTIONARY else {}
	var acquisition_result: Dictionary = company_profile.get("acquisition_result", {}) if typeof(company_profile) == TYPE_DICTIONARY else {}
	var listing_status: String = str(company_profile.get("listing_status", "listed")) if typeof(company_profile) == TYPE_DICTIONARY else "listed"
	var current_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
	var market_cap: float = max(float(financials.get("market_cap", current_price * 1000000000.0)), current_price * 1000000.0)
	var free_float_floor: float = 0.02 if not delisting_watch.is_empty() else 0.07
	var free_float_ratio: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, free_float_floor, 0.85)
	var avg_daily_value: float = max(float(financials.get("avg_daily_value", current_price * 250000.0)), current_price * 1000.0)
	var synthetic_daily_value: float = max(float(market_depth_context.get("synthetic_daily_value", 0.0)), avg_daily_value)
	var ask_depth_value: float = max(float(market_depth_context.get("ask_depth_value", 0.0)), 0.0)
	var bid_depth_value: float = max(float(market_depth_context.get("bid_depth_value", 0.0)), 0.0)
	var visible_depth_value: float = _min_positive_float([
		ask_depth_value,
		bid_depth_value,
		synthetic_daily_value * 0.5,
		avg_daily_value
	], avg_daily_value)
	var player_cash: float = max(float(RunState.player_portfolio.get("cash", 0.0)), 0.0)
	var cash_to_adv_ratio: float = player_cash / max(avg_daily_value, 1.0)
	var cash_to_depth_ratio: float = player_cash / max(visible_depth_value, 1.0)
	var free_float_value: float = max(market_cap * free_float_ratio, current_price * float(get_lot_size()))
	var cash_to_float_ratio: float = player_cash / max(free_float_value, 1.0)
	var one_lot_cost: float = current_price * float(get_lot_size())

	var label: String = "Normal depth"
	var tone: String = "muted"
	if free_float_ratio <= 0.22 or cash_to_depth_ratio >= 1.20 or cash_to_float_ratio >= 0.012:
		label = "Thin float"
		tone = "warning"
	elif cash_to_depth_ratio >= 0.42 or cash_to_adv_ratio >= 0.24:
		label = "Impactable"
		tone = "warning"
	elif free_float_ratio >= 0.42 and cash_to_depth_ratio <= 0.10 and visible_depth_value >= avg_daily_value * 1.18:
		label = "Deep tape"
		tone = "positive"
	if not delisting_watch.is_empty():
		var watch_state: String = str(delisting_watch.get("state", "public_float_warning"))
		label = "Go-private" if watch_state == "go_private_cashout" else "Delisting watch"
		tone = "negative" if watch_state == "go_private_cashout" else "warning"
	if listing_status == "acquired_cashout":
		label = "Acquired"
		tone = "negative"

	return {
		"label": label,
		"tone": tone,
		"detail": "%sCash %.2fx ADV / %.2fx visible depth; float %.0f%%." % [
			"%s. " % str(acquisition_result.get("label", "Acquired / cashed out")) if listing_status == "acquired_cashout" else ("%s. " % str(delisting_watch.get("label", "")) if not delisting_watch.is_empty() else ""),
			cash_to_adv_ratio,
			cash_to_depth_ratio,
			free_float_ratio * 100.0
		],
		"one_lot_cost": one_lot_cost,
		"cash_to_adv_ratio": cash_to_adv_ratio,
		"cash_to_depth_ratio": cash_to_depth_ratio,
		"cash_to_float_ratio": cash_to_float_ratio,
		"free_float_ratio": free_float_ratio,
		"free_float_value": free_float_value,
		"avg_daily_value": avg_daily_value,
		"synthetic_daily_value": synthetic_daily_value,
		"ask_depth_value": ask_depth_value,
		"bid_depth_value": bid_depth_value,
		"visible_depth_value": visible_depth_value
	}


func _min_positive_float(values: Array, fallback_value: float) -> float:
	var best_value: float = 0.0
	for value_variant in values:
		var value: float = float(value_variant)
		if value <= 0.0:
			continue
		if best_value <= 0.0 or value < best_value:
			best_value = value
	if best_value <= 0.0:
		return max(fallback_value, 1.0)
	return best_value


func get_company_market_depth_snapshot(company_id: String) -> Dictionary:
	var runtime: Dictionary = RunState.get_company(company_id)
	if runtime.is_empty():
		return {}

	var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
	var depth_context: Dictionary = runtime.get("market_depth_context", {}).duplicate(true)
	if depth_context.is_empty():
		var current_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
		var financials: Dictionary = definition.get("financials", {})
		var market_cap: float = max(float(financials.get("market_cap", current_price * 1000000000.0)), current_price * 1000000.0)
		var shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", market_cap / current_price))), 1.0)
		var profile: Dictionary = runtime.get("company_profile", {})
		var delisting_watch: Dictionary = profile.get("delisting_watch", {}) if typeof(profile) == TYPE_DICTIONARY else {}
		var free_float_floor: float = 0.02 if not delisting_watch.is_empty() else 0.07
		var free_float_ratio: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, free_float_floor, 0.85)
		depth_context = {
			"current_price": current_price,
			"market_cap": market_cap,
			"shares_outstanding": shares_outstanding,
			"free_float_ratio": free_float_ratio,
			"free_float_shares": shares_outstanding * free_float_ratio,
			"avg_daily_value": max(float(financials.get("avg_daily_value", current_price * 250000.0)), current_price * 1000.0),
			"ask_depth_value": 0.0,
			"bid_depth_value": 0.0,
			"synthetic_daily_value": 0.0
		}
	return depth_context


func get_player_market_impact_snapshot(company_id: String) -> Dictionary:
	var runtime: Dictionary = RunState.get_company(company_id)
	if runtime.is_empty():
		return {}
	var impact: Dictionary = runtime.get("player_market_impact", {}).duplicate(true)
	if impact.is_empty():
		impact = RunState.get_player_market_flow_context(company_id, RunState.day_index + 1)
		impact["impact_summary"] = ""
		impact["limit_lock"] = ""
		impact["limit_source"] = ""
	return impact


func _build_broker_flow_view(broker_flow: Dictionary, include_rows: bool) -> Dictionary:
	if broker_flow.is_empty():
		return {}

	var broker_flow_view: Dictionary = broker_flow.duplicate(true)
	if not include_rows:
		broker_flow_view.erase("buy_brokers")
		broker_flow_view.erase("sell_brokers")
		broker_flow_view.erase("net_buy_brokers")
		broker_flow_view.erase("net_sell_brokers")
		broker_flow_view.erase("broker_rows")
	return broker_flow_view


func get_broker_range_catalog() -> Array:
	var catalog: Array = []
	for range_value in BROKER_RANGE_CATALOG:
		if typeof(range_value) == TYPE_DICTIONARY:
			catalog.append(range_value.duplicate(true))
	return catalog


func get_company_broker_flow_snapshot(company_id: String, range_id: String = "1d") -> Dictionary:
	var runtime: Dictionary = RunState.get_company(company_id)
	if runtime.is_empty():
		return {}
	var range_definition: Dictionary = _broker_range_definition(range_id)
	var selected_compact_rows: Array = _broker_history_rows_for_range(runtime.get("broker_flow_history", []), range_definition)
	if int(range_definition.get("days", 1)) == 1:
		var latest_flow: Dictionary = _build_broker_flow_view(runtime.get("broker_flow", {}), true)
		return _stamp_broker_range_metadata(latest_flow, range_definition, selected_compact_rows, "latest")

	if not selected_compact_rows.is_empty():
		var cache_key: String = _broker_range_snapshot_cache_key(company_id, range_definition, selected_compact_rows)
		var cached_snapshot_value = broker_range_snapshot_cache.get(cache_key, {})
		if typeof(cached_snapshot_value) == TYPE_DICTIONARY:
			var cached_snapshot: Dictionary = cached_snapshot_value
			if not cached_snapshot.is_empty():
				return cached_snapshot.duplicate(true)
		var range_snapshot: Dictionary = _aggregate_compact_broker_flow_range(
			RunState.broker_history_v2_entries_to_range_rows(selected_compact_rows),
			range_definition
		)
		if not range_snapshot.is_empty():
			broker_range_snapshot_cache[cache_key] = range_snapshot.duplicate(true)
		return range_snapshot

	var fallback_flow: Dictionary = _build_broker_flow_view(runtime.get("broker_flow", {}), true)
	return _stamp_broker_range_metadata(fallback_flow, range_definition, [], "latest")


func _broker_range_definition(range_id: String) -> Dictionary:
	var normalized_id: String = range_id.to_lower()
	for range_value in BROKER_RANGE_CATALOG:
		if typeof(range_value) != TYPE_DICTIONARY:
			continue
		var range_definition: Dictionary = range_value
		if str(range_definition.get("id", "")).to_lower() == normalized_id:
			return range_definition.duplicate(true)
	return BROKER_RANGE_CATALOG[0].duplicate(true)


func _broker_history_rows_for_range(history_value: Variant, range_definition: Dictionary) -> Array:
	var rows: Array = []
	if typeof(history_value) != TYPE_ARRAY:
		return rows
	for entry_value in history_value:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		rows.append(entry_value)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("day_index", 0)) < int(b.get("day_index", 0))
	)
	if rows.is_empty():
		return rows

	var range_days: int = int(range_definition.get("days", 1))
	if range_days > 0:
		return _duplicate_broker_history_rows(rows.slice(max(rows.size() - range_days, 0), rows.size()))

	var current_year: int = int(RunState.get_current_trade_date().get("year", 0))
	var ytd_rows: Array = []
	for row_value in rows:
		var row: Dictionary = row_value
		var trade_date: Dictionary = row.get("trade_date", {}) if typeof(row.get("trade_date", {})) == TYPE_DICTIONARY else {}
		if int(trade_date.get("year", 0)) == current_year:
			ytd_rows.append(row)
	if ytd_rows.is_empty():
		ytd_rows.append(rows.back())
	return _duplicate_broker_history_rows(ytd_rows)


func _duplicate_broker_history_rows(rows: Array) -> Array:
	var duplicated_rows: Array = []
	for row_value in rows:
		if typeof(row_value) == TYPE_DICTIONARY:
			var row: Dictionary = row_value
			duplicated_rows.append(row.duplicate(true))
	return duplicated_rows


func _broker_range_snapshot_cache_key(company_id: String, range_definition: Dictionary, history_rows: Array) -> String:
	var first_day_index: int = RunState.day_index
	var last_day_index: int = RunState.day_index
	var last_total_value: float = 0.0
	if not history_rows.is_empty():
		var first_row: Dictionary = history_rows.front() if typeof(history_rows.front()) == TYPE_DICTIONARY else {}
		var last_row: Dictionary = history_rows.back() if typeof(history_rows.back()) == TYPE_DICTIONARY else {}
		first_day_index = int(first_row.get("day_index", first_day_index))
		last_day_index = int(last_row.get("day_index", last_day_index))
		last_total_value = float(last_row.get("total_value", 0.0))
	return "%s|%s|%d|%d|%d|%d|%.2f" % [
		company_id,
		str(range_definition.get("id", "1d")),
		RunState.day_index,
		history_rows.size(),
		first_day_index,
		last_day_index,
		last_total_value
	]


func _aggregate_compact_broker_flow_range(history_rows: Array, range_definition: Dictionary) -> Dictionary:
	var broker_type_totals: Dictionary = {}
	var score_weighted_total: float = 0.0
	var net_pressure_weighted_total: float = 0.0
	var smart_pressure_weighted_total: float = 0.0
	var entry_weight_total: float = 0.0
	var retail_weighted_total: float = 0.0
	var foreign_weighted_total: float = 0.0
	var institution_weighted_total: float = 0.0
	var bandar_weighted_total: float = 0.0
	var zombie_weighted_total: float = 0.0
	var total_buy_value: float = 0.0
	var total_sell_value: float = 0.0

	for entry_value in history_rows:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_value
		var entry_weight: float = max(float(entry.get("total_value", 0.0)), float(entry.get("total_buy_value", 0.0)), float(entry.get("total_sell_value", 0.0)), 1.0)
		entry_weight_total += entry_weight
		score_weighted_total += clamp(float(entry.get("action_meter_score", 0.0)), -1.0, 1.0) * entry_weight
		net_pressure_weighted_total += clamp(float(entry.get("net_pressure", 0.0)), -1.0, 1.0) * entry_weight
		smart_pressure_weighted_total += clamp(float(entry.get("smart_money_pressure", 0.0)), -1.0, 1.0) * entry_weight
		retail_weighted_total += float(entry.get("retail_net", 0.0)) * entry_weight
		foreign_weighted_total += float(entry.get("foreign_net", 0.0)) * entry_weight
		institution_weighted_total += float(entry.get("institution_net", 0.0)) * entry_weight
		bandar_weighted_total += float(entry.get("bandar_net", 0.0)) * entry_weight
		zombie_weighted_total += float(entry.get("zombie_net", 0.0)) * entry_weight
		total_buy_value += max(float(entry.get("total_buy_value", 0.0)), 0.0)
		total_sell_value += max(float(entry.get("total_sell_value", 0.0)), 0.0)
		_merge_broker_type_totals(broker_type_totals, entry.get("broker_type_totals", {}))

	var buy_brokers: Array = _aggregate_compact_broker_rows(history_rows, "top_buy_brokers", BROKER_RANGE_TOP_ROW_COUNT)
	var sell_brokers: Array = _aggregate_compact_broker_rows(history_rows, "top_sell_brokers", BROKER_RANGE_TOP_ROW_COUNT)
	var net_buy_brokers: Array = _aggregate_compact_broker_rows(history_rows, "top_net_buy_brokers", BROKER_RANGE_TOP_ROW_COUNT)
	var net_sell_brokers: Array = _aggregate_compact_broker_rows(history_rows, "top_net_sell_brokers", BROKER_RANGE_TOP_ROW_COUNT)
	var action_meter_score: float = clamp(score_weighted_total / max(entry_weight_total, 1.0), -1.0, 1.0)
	var net_pressure: float = clamp(net_pressure_weighted_total / max(entry_weight_total, 1.0), -1.0, 1.0)
	var broker_flow: Dictionary = {
		"net_pressure": net_pressure,
		"smart_money_pressure": clamp(smart_pressure_weighted_total / max(entry_weight_total, 1.0), -1.0, 1.0),
		"retail_net": retail_weighted_total / max(entry_weight_total, 1.0),
		"foreign_net": foreign_weighted_total / max(entry_weight_total, 1.0),
		"institution_net": institution_weighted_total / max(entry_weight_total, 1.0),
		"bandar_net": bandar_weighted_total / max(entry_weight_total, 1.0),
		"zombie_net": zombie_weighted_total / max(entry_weight_total, 1.0),
		"dominant_buyer": _dominant_broker_actor_from_scores({
			"retail": retail_weighted_total,
			"foreign": foreign_weighted_total,
			"institution": institution_weighted_total,
			"bandar": bandar_weighted_total,
			"zombie": zombie_weighted_total
		}, true),
		"dominant_seller": _dominant_broker_actor_from_scores({
			"retail": retail_weighted_total,
			"foreign": foreign_weighted_total,
			"institution": institution_weighted_total,
			"bandar": bandar_weighted_total,
			"zombie": zombie_weighted_total
		}, false),
		"dominant_buy_broker_code": _broker_row_code(buy_brokers),
		"dominant_buy_broker_name": _broker_row_name(buy_brokers),
		"dominant_buy_broker_type": _broker_row_type(buy_brokers),
		"dominant_sell_broker_code": _broker_row_code(sell_brokers),
		"dominant_sell_broker_name": _broker_row_name(sell_brokers),
		"dominant_sell_broker_type": _broker_row_type(sell_brokers),
		"flow_tag": _broker_flow_tag_for_score(net_pressure),
		"action_meter_score": action_meter_score,
		"action_meter_label": _broker_meter_label_for_score(action_meter_score),
		"buy_brokers": buy_brokers,
		"sell_brokers": sell_brokers,
		"net_buy_brokers": net_buy_brokers,
		"net_sell_brokers": net_sell_brokers,
		"broker_rows": [],
		"broker_type_totals": broker_type_totals,
		"broker_trade_value": max(total_buy_value, total_sell_value, (total_buy_value + total_sell_value) * 0.5),
		"broker_trade_shares": 0.0
	}
	return _stamp_broker_range_metadata(broker_flow, range_definition, history_rows, "compact")


func _stamp_broker_range_metadata(broker_flow: Dictionary, range_definition: Dictionary, history_rows: Array, history_mode: String) -> Dictionary:
	if broker_flow.is_empty():
		return {}
	var stamped_flow: Dictionary = broker_flow.duplicate(true)
	var start_date: Dictionary = {}
	var end_date: Dictionary = {}
	if not history_rows.is_empty():
		var first_row: Dictionary = history_rows.front() if typeof(history_rows.front()) == TYPE_DICTIONARY else {}
		var last_row: Dictionary = history_rows.back() if typeof(history_rows.back()) == TYPE_DICTIONARY else {}
		start_date = first_row.get("trade_date", {}) if typeof(first_row.get("trade_date", {})) == TYPE_DICTIONARY else {}
		end_date = last_row.get("trade_date", {}) if typeof(last_row.get("trade_date", {})) == TYPE_DICTIONARY else {}
	stamped_flow["range_id"] = str(range_definition.get("id", "1d"))
	stamped_flow["range_label"] = str(range_definition.get("label", "1D"))
	stamped_flow["range_day_count"] = max(history_rows.size(), 1 if history_mode == "latest" else 0)
	stamped_flow["history_mode"] = history_mode
	stamped_flow["history_start_date"] = start_date.duplicate(true)
	stamped_flow["history_end_date"] = end_date.duplicate(true)
	return stamped_flow


func _ensure_broker_activity_aggregate_row(broker_map: Dictionary, broker_row: Dictionary) -> Dictionary:
	var code: String = str(broker_row.get("code", ""))
	var aggregate_row: Dictionary = broker_map.get(code, {})
	if not aggregate_row.is_empty():
		return aggregate_row
	aggregate_row = {
		"code": code,
		"company_name": str(broker_row.get("company_name", broker_row.get("name", ""))),
		"broker_type": str(broker_row.get("broker_type", "")),
		"personality_tags": [],
		"buy_value": 0.0,
		"sell_value": 0.0,
		"buy_lots": 0.0,
		"sell_lots": 0.0,
		"buy_shares": 0.0,
		"sell_shares": 0.0,
		"buy_price_weight": 0.0,
		"sell_price_weight": 0.0
	}
	broker_map[code] = aggregate_row
	return aggregate_row


func _finalize_broker_activity_rows(broker_map: Dictionary) -> Array:
	var rows: Array = []
	for row_value in broker_map.values():
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value.duplicate(true)
		row["buy_avg_price"] = float(row.get("buy_price_weight", 0.0)) / max(float(row.get("buy_value", 0.0)), 1.0)
		row["sell_avg_price"] = float(row.get("sell_price_weight", 0.0)) / max(float(row.get("sell_value", 0.0)), 1.0)
		row.erase("buy_price_weight")
		row.erase("sell_price_weight")
		rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_value: float = float(a.get("buy_value", 0.0)) + float(a.get("sell_value", 0.0))
		var b_value: float = float(b.get("buy_value", 0.0)) + float(b.get("sell_value", 0.0))
		if is_equal_approx(a_value, b_value):
			return str(a.get("code", "")) < str(b.get("code", ""))
		return a_value > b_value
	)
	return rows


func _merge_broker_personality_tags(target_row: Dictionary, tags_value: Variant) -> void:
	if typeof(tags_value) != TYPE_ARRAY:
		return
	var tags: Array = target_row.get("personality_tags", [])
	for tag_value in tags_value:
		var tag: String = str(tag_value)
		if tag.is_empty() or tag in tags:
			continue
		tags.append(tag)
	target_row["personality_tags"] = tags


func _broker_side_rows_from_activity(activity_rows: Array, side: String, limit: int) -> Array:
	var rows: Array = []
	var value_key: String = "%s_value" % side
	var lots_key: String = "%s_lots" % side
	var avg_key: String = "%s_avg_price" % side
	for row_value in activity_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var value: float = max(float(row.get(value_key, 0.0)), 0.0)
		if value <= 0.0:
			continue
		rows.append({
			"code": str(row.get("code", "")),
			"company_name": str(row.get("company_name", "")),
			"broker_type": str(row.get("broker_type", "")),
			"personality_tags": row.get("personality_tags", []).duplicate() if typeof(row.get("personality_tags", [])) == TYPE_ARRAY else [],
			"value": value,
			"lots": max(float(row.get(lots_key, 0.0)), 0.0),
			"avg_price": max(float(row.get(avg_key, 0.0)), 0.0)
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("value", 0.0)), float(b.get("value", 0.0))):
			return str(a.get("code", "")) < str(b.get("code", ""))
		return float(a.get("value", 0.0)) > float(b.get("value", 0.0))
	)
	if limit > 0 and rows.size() > limit:
		rows = rows.slice(0, limit)
	return rows


func _broker_net_rows_from_activity(activity_rows: Array, side: String, limit: int) -> Array:
	var rows: Array = []
	for row_value in activity_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var buy_value: float = max(float(row.get("buy_value", 0.0)), 0.0)
		var sell_value: float = max(float(row.get("sell_value", 0.0)), 0.0)
		var net_value: float = buy_value - sell_value
		if side == "buy" and net_value <= 0.0:
			continue
		if side == "sell" and net_value >= 0.0:
			continue
		var abs_value: float = abs(net_value)
		if abs_value <= 0.0:
			continue
		rows.append({
			"code": str(row.get("code", "")),
			"company_name": str(row.get("company_name", "")),
			"broker_type": str(row.get("broker_type", "")),
			"personality_tags": row.get("personality_tags", []).duplicate() if typeof(row.get("personality_tags", [])) == TYPE_ARRAY else [],
			"value": abs_value,
			"lots": abs(float(row.get("buy_lots", 0.0)) - float(row.get("sell_lots", 0.0))),
			"avg_price": max(float(row.get("buy_avg_price", row.get("sell_avg_price", 0.0))) if side == "buy" else float(row.get("sell_avg_price", row.get("buy_avg_price", 0.0))), 0.0),
			"net_side": side
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("value", 0.0)), float(b.get("value", 0.0))):
			return str(a.get("code", "")) < str(b.get("code", ""))
		return float(a.get("value", 0.0)) > float(b.get("value", 0.0))
	)
	if limit > 0 and rows.size() > limit:
		rows = rows.slice(0, limit)
	return rows


func _aggregate_compact_broker_rows(history_rows: Array, rows_key: String, limit: int) -> Array:
	var broker_map: Dictionary = {}
	for entry_value in history_rows:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_value
		var rows_value: Variant = entry.get(rows_key, [])
		if typeof(rows_value) != TYPE_ARRAY:
			continue
		for row_value in rows_value:
			if typeof(row_value) != TYPE_DICTIONARY:
				continue
			var row: Dictionary = row_value
			var code: String = str(row.get("code", ""))
			if code.is_empty():
				continue
			var aggregate_row: Dictionary = broker_map.get(code, {
				"code": code,
				"company_name": str(row.get("company_name", "")),
				"broker_type": str(row.get("broker_type", "")),
				"value": 0.0,
				"lots": 0.0,
				"avg_price_weight": 0.0,
				"net_side": str(row.get("net_side", ""))
			})
			var value: float = max(float(row.get("value", 0.0)), 0.0)
			aggregate_row["value"] = float(aggregate_row.get("value", 0.0)) + value
			aggregate_row["lots"] = float(aggregate_row.get("lots", 0.0)) + max(float(row.get("lots", 0.0)), 0.0)
			aggregate_row["avg_price_weight"] = float(aggregate_row.get("avg_price_weight", 0.0)) + (max(float(row.get("avg_price", 0.0)), 0.0) * value)
			broker_map[code] = aggregate_row
	var rows: Array = []
	for aggregate_value in broker_map.values():
		if typeof(aggregate_value) != TYPE_DICTIONARY:
			continue
		var aggregate_row: Dictionary = aggregate_value.duplicate(true)
		aggregate_row["avg_price"] = float(aggregate_row.get("avg_price_weight", 0.0)) / max(float(aggregate_row.get("value", 0.0)), 1.0)
		aggregate_row.erase("avg_price_weight")
		rows.append(aggregate_row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("value", 0.0)), float(b.get("value", 0.0))):
			return str(a.get("code", "")) < str(b.get("code", ""))
		return float(a.get("value", 0.0)) > float(b.get("value", 0.0))
	)
	if limit > 0 and rows.size() > limit:
		rows = rows.slice(0, limit)
	return rows


func _merge_broker_type_totals(target_totals: Dictionary, totals_value: Variant) -> void:
	if typeof(totals_value) != TYPE_DICTIONARY:
		return
	for type_key_value in totals_value.keys():
		var type_key: String = str(type_key_value)
		if type_key.is_empty():
			continue
		var source_total: Dictionary = totals_value[type_key_value] if typeof(totals_value[type_key_value]) == TYPE_DICTIONARY else {}
		if source_total.is_empty():
			continue
		if not target_totals.has(type_key):
			target_totals[type_key] = {
				"buy_value": 0.0,
				"sell_value": 0.0,
				"buy_lots": 0.0,
				"sell_lots": 0.0,
				"buy_shares": 0.0,
				"sell_shares": 0.0,
				"net_value": 0.0,
				"net_lots": 0.0
			}
		var target_total: Dictionary = target_totals[type_key]
		for numeric_key_value in ["buy_value", "sell_value", "buy_lots", "sell_lots", "buy_shares", "sell_shares"]:
			var numeric_key: String = str(numeric_key_value)
			target_total[numeric_key] = float(target_total.get(numeric_key, 0.0)) + max(float(source_total.get(numeric_key, 0.0)), 0.0)
		target_total["net_value"] = float(target_total.get("buy_value", 0.0)) - float(target_total.get("sell_value", 0.0))
		target_total["net_lots"] = float(target_total.get("buy_lots", 0.0)) - float(target_total.get("sell_lots", 0.0))
		target_totals[type_key] = target_total


func _broker_type_totals_from_activity_rows(activity_rows: Array) -> Dictionary:
	var totals: Dictionary = {}
	for row_value in activity_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var broker_type: String = str(row.get("broker_type", "retail"))
		if broker_type.is_empty():
			broker_type = "retail"
		if not totals.has(broker_type):
			totals[broker_type] = {
				"buy_value": 0.0,
				"sell_value": 0.0,
				"buy_lots": 0.0,
				"sell_lots": 0.0,
				"buy_shares": 0.0,
				"sell_shares": 0.0,
				"net_value": 0.0,
				"net_lots": 0.0
			}
		var type_total: Dictionary = totals[broker_type]
		type_total["buy_value"] = float(type_total.get("buy_value", 0.0)) + max(float(row.get("buy_value", 0.0)), 0.0)
		type_total["sell_value"] = float(type_total.get("sell_value", 0.0)) + max(float(row.get("sell_value", 0.0)), 0.0)
		type_total["buy_lots"] = float(type_total.get("buy_lots", 0.0)) + max(float(row.get("buy_lots", 0.0)), 0.0)
		type_total["sell_lots"] = float(type_total.get("sell_lots", 0.0)) + max(float(row.get("sell_lots", 0.0)), 0.0)
		type_total["buy_shares"] = float(type_total.get("buy_shares", 0.0)) + max(float(row.get("buy_shares", 0.0)), 0.0)
		type_total["sell_shares"] = float(type_total.get("sell_shares", 0.0)) + max(float(row.get("sell_shares", 0.0)), 0.0)
		type_total["net_value"] = float(type_total.get("buy_value", 0.0)) - float(type_total.get("sell_value", 0.0))
		type_total["net_lots"] = float(type_total.get("buy_lots", 0.0)) - float(type_total.get("sell_lots", 0.0))
		totals[broker_type] = type_total
	return totals


func _dominant_broker_actor_from_scores(scores: Dictionary, positive_side: bool) -> String:
	var best_key: String = "balanced"
	var best_value: float = -INF if positive_side else INF
	for key_value in scores.keys():
		var key: String = str(key_value)
		var value: float = float(scores[key_value])
		if positive_side:
			if value > best_value:
				best_value = value
				best_key = key
		else:
			if value < best_value:
				best_value = value
				best_key = key
	return best_key


func _broker_row_code(rows: Array) -> String:
	return str(rows[0].get("code", "")) if not rows.is_empty() and typeof(rows[0]) == TYPE_DICTIONARY else ""


func _broker_row_name(rows: Array) -> String:
	return str(rows[0].get("company_name", "")) if not rows.is_empty() and typeof(rows[0]) == TYPE_DICTIONARY else ""


func _broker_row_type(rows: Array) -> String:
	return str(rows[0].get("broker_type", "")) if not rows.is_empty() and typeof(rows[0]) == TYPE_DICTIONARY else ""


func _broker_flow_tag_for_score(score: float) -> String:
	if score > 0.18:
		return "accumulation"
	if score < -0.18:
		return "distribution"
	return "neutral"


func _broker_meter_label_for_score(score: float) -> String:
	if score >= 0.60:
		return "Big Acc"
	if score >= 0.18:
		return "Accumulation"
	if score <= -0.60:
		return "Big Dist"
	if score <= -0.18:
		return "Distribution"
	return "Neutral"


func _company_market_rows_cache_key() -> String:
	var trade_date: Dictionary = RunState.get_current_trade_date()
	return "%d|%d|%d|%d|%d|%d|%d" % [
		RunState.run_seed,
		RunState.day_index,
		int(trade_date.get("year", 0)),
		int(trade_date.get("month", 0)),
		int(trade_date.get("day", 0)),
		RunState.company_order.size(),
		RunState.event_history.size()
	]


func _build_company_market_rows() -> Array:
	var rows: Array = []
	var sector_name_cache: Dictionary = {}
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var runtime: Dictionary = RunState.get_company(company_id)
		if runtime.is_empty():
			continue
		var definition: Dictionary = RunState.company_definitions.get(company_id, {})
		if definition.is_empty():
			definition = DataRepository.get_company_archetype(company_id)
		if definition.is_empty():
			continue
		var company_profile: Dictionary = runtime.get("company_profile", {}) if typeof(runtime.get("company_profile", {})) == TYPE_DICTIONARY else {}
		var sector_id: String = str(company_profile.get("sector_id", definition.get("sector_id", "")))
		var sector_name: String = str(sector_name_cache.get(sector_id, ""))
		if sector_name.is_empty():
			var sector_definition: Dictionary = DataRepository.get_sector_definition(sector_id)
			sector_name = str(sector_definition.get("name", sector_id.capitalize()))
			sector_name_cache[sector_id] = sector_name
		var current_price: float = float(runtime.get("current_price", definition.get("base_price", 0.0)))
		var previous_close: float = float(runtime.get("previous_close", current_price))
		var daily_change_pct: float = float(runtime.get("daily_change_pct", 0.0))
		if is_zero_approx(daily_change_pct) and not is_zero_approx(previous_close):
			daily_change_pct = (current_price - previous_close) / previous_close
		rows.append({
			"id": company_id,
			"ticker": str(definition.get("ticker", company_id.to_upper())),
			"name": str(company_profile.get("name", definition.get("name", ""))),
			"sector_id": sector_id,
			"sector_name": sector_name,
			"current_price": current_price,
			"previous_close": previous_close,
			"daily_change_pct": daily_change_pct,
			"event_tags": runtime.get("active_event_tags", []).duplicate(),
			"listing_status": str(company_profile.get("listing_status", "listed")),
			"listing_status_label": str(company_profile.get("listing_status_label", "Listed")),
			"trade_disabled": bool(company_profile.get("trade_disabled", false)),
			"broker_flow": _build_compact_broker_flow_view(runtime.get("broker_flow", {}))
		})
	return rows


func _build_compact_broker_flow_view(broker_flow: Dictionary) -> Dictionary:
	if broker_flow.is_empty():
		return {}
	var compact_view: Dictionary = {}
	var keys: Array = [
		"net_pressure",
		"flow_tag",
		"dominant_buyer",
		"dominant_seller",
		"dominant_buy_broker_code",
		"dominant_sell_broker_code",
		"dominant_buy_broker_name",
		"dominant_sell_broker_name",
		"dominant_buy_broker_type",
		"dominant_sell_broker_type",
		"action_meter_score",
		"action_meter_label"
	]
	for key_value in keys:
		var key: String = str(key_value)
		if broker_flow.has(key):
			compact_view[key] = broker_flow.get(key)
	return compact_view


func get_company_chart_snapshot(company_id: String, range_id: String = "1m", enabled_indicator_ids: Array = []) -> Dictionary:
	var chart_bars: Array = RunState.get_company_chart_bars(company_id)
	if chart_bars.is_empty():
		return {}
	return chart_system.build_chart_snapshot_from_bars(chart_bars, range_id, enabled_indicator_ids)


func get_portfolio_snapshot() -> Dictionary:
	var holdings_rows: Array = []
	var invested_cost_total: float = 0.0
	var unrealized_pnl_total: float = 0.0
	for company_id in RunState.player_portfolio.get("holdings", {}).keys():
		var snapshot: Dictionary = get_company_snapshot(str(company_id), false)
		var holding: Dictionary = RunState.get_holding(str(company_id))
		var shares: int = int(holding.get("shares", 0))
		var invested_cost: float = float(holding.get("average_price", 0.0)) * float(shares)
		var unrealized_pnl: float = float(snapshot.get("unrealized_pnl", 0.0))
		var pnl_pct: float = 0.0
		if invested_cost > 0.0:
			pnl_pct = unrealized_pnl / invested_cost

		invested_cost_total += invested_cost
		unrealized_pnl_total += unrealized_pnl
		holdings_rows.append({
			"company_id": company_id,
			"ticker": snapshot.get("ticker", str(company_id).to_upper()),
			"shares": shares,
			"lots": int(floor(float(shares) / float(get_lot_size()))),
			"average_price": float(holding.get("average_price", 0.0)),
			"current_price": float(snapshot.get("current_price", 0.0)),
			"invested_cost": invested_cost,
			"market_value": float(snapshot.get("market_value", 0.0)),
			"unrealized_pnl": unrealized_pnl,
			"unrealized_pnl_pct": pnl_pct
		})

	holdings_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("ticker", "")) < str(b.get("ticker", ""))
	)

	var unrealized_pnl_pct_total: float = 0.0
	if invested_cost_total > 0.0:
		unrealized_pnl_pct_total = unrealized_pnl_total / invested_cost_total

	return {
		"cash": float(RunState.player_portfolio.get("cash", 0.0)),
		"realized_pnl": float(RunState.player_portfolio.get("realized_pnl", 0.0)),
		"invested_cost": invested_cost_total,
		"market_value": RunState.get_portfolio_market_value(),
		"unrealized_pnl": unrealized_pnl_total,
		"unrealized_pnl_pct": unrealized_pnl_pct_total,
		"equity": RunState.get_total_equity(),
		"holdings": holdings_rows
	}


func _get_portfolio_totals_snapshot() -> Dictionary:
	var cash: float = float(RunState.player_portfolio.get("cash", 0.0))
	var market_value: float = RunState.get_portfolio_market_value()
	return {
		"cash": cash,
		"realized_pnl": float(RunState.player_portfolio.get("realized_pnl", 0.0)),
		"market_value": market_value,
		"equity": cash + market_value
	}


func get_first_month_balance_snapshot() -> Dictionary:
	if not RunState.has_active_run():
		return {
			"day_index": 0,
			"trading_day_number": 1,
			"cash": STARTING_CASH,
			"equity": STARTING_CASH,
			"monthly_outflow": 8500000.0,
			"runway_months": STARTING_CASH / 8500000.0,
			"next_life_payment": {},
			"daily_action": {"used": 0, "remaining": 10, "limit": 10},
			"active_corporate_chains": [],
			"upcoming_meetings": [],
			"next_five_trading_days": [],
			"warning_rows": []
		}

	var portfolio: Dictionary = get_portfolio_snapshot()
	var life: Dictionary = get_life_snapshot()
	var daily_action: Dictionary = get_daily_action_snapshot()
	var monthly_outflow: float = max(float(life.get("monthly_outflow", 8500000.0)), 0.0)
	var cash: float = float(portfolio.get("cash", 0.0))
	var runway_months: float = 999.0
	if monthly_outflow > 0.0:
		runway_months = cash / monthly_outflow
	var active_chain_rows: Array = _first_month_active_corporate_chain_rows()
	var dashboard_events: Dictionary = get_dashboard_event_snapshot()
	var upcoming_meeting_rows: Array = dashboard_events.get("upcoming_meeting_rows", []).duplicate(true)
	var next_life_payment: Dictionary = life.get("next_life_payment", {}).duplicate(true)
	var next_five_rows: Array = _build_first_month_next_five_rows(life, dashboard_events, active_chain_rows)
	var warning_rows: Array = _build_first_month_warning_rows(
		cash,
		monthly_outflow,
		runway_months,
		next_life_payment,
		daily_action,
		active_chain_rows
	)
	return {
		"day_index": RunState.day_index,
		"trading_day_number": max(RunState.day_index + 1, 1),
		"trade_date": get_current_trade_date(),
		"cash": cash,
		"equity": float(portfolio.get("equity", 0.0)),
		"monthly_outflow": monthly_outflow,
		"runway_months": runway_months,
		"next_life_payment": next_life_payment,
		"daily_action": daily_action,
		"ap_used": int(daily_action.get("used", 0)),
		"ap_remaining": int(daily_action.get("remaining", 0)),
		"ap_limit": int(daily_action.get("limit", 0)),
		"active_corporate_chains": active_chain_rows,
		"active_corporate_chain_count": active_chain_rows.size(),
		"upcoming_meetings": upcoming_meeting_rows,
		"upcoming_meeting_count": upcoming_meeting_rows.size(),
		"next_five_trading_days": next_five_rows,
		"warning_rows": warning_rows
	}


func get_finance_status_snapshot() -> Dictionary:
	if not RunState.has_active_run():
		return {}

	var finance: Dictionary = RunState.refresh_cash_stress_state()
	var portfolio: Dictionary = get_portfolio_snapshot()
	var cash: float = float(portfolio.get("cash", 0.0))
	var equity: float = float(portfolio.get("equity", 0.0))
	var monthly_outflow: float = _life_monthly_outflow_for_state(RunState.get_player_life())
	var runway_months: float = 999.0
	if monthly_outflow > 0.0:
		runway_months = cash / monthly_outflow
	var active_loan: Dictionary = finance.get("active_loan", {})
	var cash_deficit: float = max(-cash, 0.0)
	var loan_cap: float = min(
		max(equity * LIFE_EMERGENCY_LOAN_EQUITY_CAP_PCT, 0.0),
		max(monthly_outflow * LIFE_EMERGENCY_LOAN_MONTHLY_OUTFLOW_CAP, 0.0)
	)
	var proposed_loan_amount: float = max(cash_deficit + monthly_outflow, LIFE_EMERGENCY_LOAN_MINIMUM)
	if loan_cap > 0.0:
		proposed_loan_amount = min(proposed_loan_amount, loan_cap)
	var loan_eligible: bool = (
		not bool(finance.get("bankrupt", false)) and
		active_loan.is_empty() and
		(cash < 0.0 or runway_months < 0.5) and
		loan_cap + 0.0001 >= LIFE_EMERGENCY_LOAN_MINIMUM
	)
	var loan_reason: String = "Emergency loan available."
	if bool(finance.get("bankrupt", false)):
		loan_reason = "Bankruptcy has disabled new loans."
	elif not active_loan.is_empty():
		loan_reason = "An emergency loan is already active."
	elif cash >= 0.0 and runway_months >= 0.5:
		loan_reason = "Emergency loan unlocks when cash is negative or runway is under half a month."
	elif loan_cap + 0.0001 < LIFE_EMERGENCY_LOAN_MINIMUM:
		loan_reason = "Current equity does not support a new emergency loan."

	var stress_days_remaining: int = -1
	if bool(finance.get("cash_stress_active", false)):
		stress_days_remaining = max(int(finance.get("cash_stress_deadline_day_index", RunState.day_index)) - RunState.day_index, 0)
	var next_payment: Dictionary = {}
	if not active_loan.is_empty():
		next_payment = {
			"amount": float(active_loan.get("monthly_payment", 0.0)),
			"payments_remaining": int(active_loan.get("payments_remaining", 0)),
			"covered": cash + 0.0001 >= float(active_loan.get("monthly_payment", 0.0))
		}
	var active_bank_loan: Dictionary = finance.get("active_bank_loan", {})
	var bank_next_payment: Dictionary = {}
	if not active_bank_loan.is_empty():
		bank_next_payment = {
			"amount": float(active_bank_loan.get("monthly_payment", 0.0)),
			"payments_remaining": int(active_bank_loan.get("payments_remaining", 0)),
			"covered": cash + 0.0001 >= float(active_bank_loan.get("monthly_payment", 0.0)),
			"lender_id": str(active_bank_loan.get("lender_id", "")),
			"lender_ticker": str(active_bank_loan.get("lender_ticker", ""))
		}
	var total_required_loan_reserve: float = RunState.required_loan_payment_reserve(finance)
	var finance_status: Dictionary = {
		"cash": cash,
		"equity": equity,
		"monthly_outflow": monthly_outflow,
		"runway_months": runway_months,
		"finance": finance,
		"cash_stress_active": bool(finance.get("cash_stress_active", false)),
		"cash_stress_days_remaining": stress_days_remaining,
		"cash_deficit": cash_deficit,
		"bankrupt": bool(finance.get("bankrupt", false)),
		"bankruptcy": finance.get("bankruptcy", {}).duplicate(true),
		"active_loan": active_loan.duplicate(true),
		"active_bank_loan": active_bank_loan.duplicate(true),
		"loan_next_payment": next_payment,
		"bank_loan_next_payment": bank_next_payment,
		"loan_payment_risky": not active_loan.is_empty() and cash < float(active_loan.get("monthly_payment", 0.0)) - 0.0001,
		"bank_loan_payment_risky": not active_bank_loan.is_empty() and cash < float(active_bank_loan.get("monthly_payment", 0.0)) - 0.0001,
		"total_required_loan_reserve": total_required_loan_reserve,
		"total_loan_payment_risky": total_required_loan_reserve > 0.0 and cash < total_required_loan_reserve - 0.0001,
		"loan_eligible": loan_eligible,
		"loan_eligibility_reason": loan_reason,
		"proposed_loan_amount": proposed_loan_amount if loan_eligible else 0.0,
		"loan_cap": loan_cap,
		"loan_payment_count": LIFE_EMERGENCY_LOAN_PAYMENT_COUNT,
		"loan_repayment_multiplier": LIFE_EMERGENCY_LOAN_REPAYMENT_MULTIPLIER,
		"sellable_holdings_value": _estimate_sellable_holdings_value()
	}
	finance_status["bank_loan_offers"] = get_bank_loan_offers(finance_status)
	return finance_status


func get_bank_loan_offers(finance_status: Dictionary = {}) -> Array:
	if not RunState.has_active_run():
		return []
	var source_finance_status: Dictionary = finance_status
	if source_finance_status.is_empty():
		source_finance_status = get_finance_status_snapshot()
	var run_context: Dictionary = RunState.get_difficulty_config()
	run_context["run_seed"] = RunState.run_seed
	run_context["difficulty_id"] = str(run_context.get("id", RunState.difficulty_id))
	run_context["equity"] = float(source_finance_status.get("equity", 0.0))
	run_context["monthly_outflow"] = float(source_finance_status.get("monthly_outflow", 0.0))
	return BANK_LOAN_SYSTEM.build_lender_offers(
		RunState.get_effective_company_definitions(),
		run_context,
		source_finance_status
	)


func get_life_action_block_reason(action_id: String) -> String:
	return LifeManager.get_life_action_block_reason(self, action_id)


func get_cash_stress_block_reason(action_id: String) -> String:
	if not RunState.has_active_run():
		return "No active run."
	var finance_status: Dictionary = get_finance_status_snapshot()
	if bool(finance_status.get("bankrupt", false)):
		return "Bankruptcy has disabled this action."
	var normalized_action: String = action_id.to_lower()
	var cash: float = float(finance_status.get("cash", 0.0))
	var required_loan_reserve: float = float(finance_status.get("total_required_loan_reserve", 0.0))
	if normalized_action in ["buy", "upgrade"]:
		if cash < 0.0:
			return "Cash is negative. Sell holdings, lower Life costs, or use Life > Finance before spending."
		if required_loan_reserve > 0.0 and bool(finance_status.get("total_loan_payment_risky", false)):
			return "Combined loan payment reserve is not covered. Keep cash above %s before spending." % _format_currency(required_loan_reserve)
	if normalized_action == "advance_day":
		if cash >= 0.0:
			return ""
		var finance: Dictionary = finance_status.get("finance", {})
		if not bool(finance.get("cash_stress_active", false)):
			return ""
		if RunState.day_index < int(finance.get("cash_stress_deadline_day_index", -1)):
			return ""
		var deficit: float = absf(cash)
		if float(finance_status.get("sellable_holdings_value", 0.0)) >= deficit + 0.0001:
			return "Cash stress grace expired. Sell holdings or use Life > Finance before advancing."
		if bool(finance_status.get("loan_eligible", false)):
			return "Cash stress grace expired. Use Life > Finance before advancing."
		return "BANKRUPTCY_REQUIRED"
	return ""


func resolve_advance_day_finance_gate() -> Dictionary:
	var block_reason: String = get_life_action_block_reason("advance_day")
	if block_reason.is_empty():
		return {"success": true}
	if block_reason == "BANKRUPTCY_REQUIRED":
		var bankruptcy: Dictionary = RunState.mark_bankruptcy("cash_stress_unrecoverable")
		RunState.last_day_results["bankruptcy"] = bankruptcy.duplicate(true)
		_request_autosave("bankruptcy")
		life_changed.emit()
		portfolio_changed.emit()
		return {
			"success": false,
			"bankrupt": true,
			"message": "Bankruptcy triggered. Cash stayed negative after the grace period with no recovery path.",
			"bankruptcy": bankruptcy
		}
	return {
		"success": false,
		"blocked": true,
		"message": block_reason
	}


func take_emergency_loan() -> Dictionary:
	var block_reason: String = get_life_action_block_reason("life_finance")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var finance_status: Dictionary = get_finance_status_snapshot()
	if not bool(finance_status.get("loan_eligible", false)):
		return {
			"success": false,
			"message": str(finance_status.get("loan_eligibility_reason", "Emergency loan is not available."))
		}
	var principal: float = float(finance_status.get("proposed_loan_amount", 0.0))
	var total_repayment: float = principal * LIFE_EMERGENCY_LOAN_REPAYMENT_MULTIPLIER
	var monthly_payment: float = total_repayment / float(LIFE_EMERGENCY_LOAN_PAYMENT_COUNT)
	var result: Dictionary = RunState.apply_emergency_loan_proceeds(principal, {
		"payment_count": LIFE_EMERGENCY_LOAN_PAYMENT_COUNT,
		"repayment_multiplier": LIFE_EMERGENCY_LOAN_REPAYMENT_MULTIPLIER,
		"total_repayment": total_repayment,
		"monthly_payment": monthly_payment
	})
	if bool(result.get("success", false)):
		_record_steam_progress_event("emergency_loan_taken", {
			"principal": principal,
			"monthly_payment": monthly_payment
		})
		_request_autosave("life_emergency_loan")
		life_changed.emit()
		portfolio_changed.emit()
	return result


func take_bank_loan(offer_id: String, principal: float) -> Dictionary:
	var block_reason: String = get_life_action_block_reason("life_finance")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var normalized_offer_id: String = offer_id.strip_edges()
	if normalized_offer_id.is_empty():
		return {"success": false, "message": "Select a bank lender first."}
	var finance_status: Dictionary = get_finance_status_snapshot()
	var offer: Dictionary = _find_bank_loan_offer(finance_status.get("bank_loan_offers", []), normalized_offer_id)
	if offer.is_empty():
		return {"success": false, "message": "Selected bank loan offer is no longer available."}
	var selected_amount: float = _normalize_bank_loan_principal(principal, offer)
	if selected_amount <= 0.0:
		return {"success": false, "message": "Bank loan amount must be positive."}
	var min_principal: float = float(offer.get("min_principal", 0.0))
	var max_principal: float = float(offer.get("max_principal", 0.0))
	if selected_amount + 0.0001 < min_principal:
		return {"success": false, "message": "Bank loan amount is below the selected offer minimum."}
	if max_principal > 0.0 and selected_amount > max_principal + 0.0001:
		return {"success": false, "message": "Bank loan amount exceeds the selected offer maximum."}

	var payment_count: int = max(int(offer.get("payment_count", 1)), 1)
	var repayment_multiplier: float = max(float(offer.get("repayment_multiplier", 1.0)), 1.0)
	var detail: Dictionary = offer.duplicate(true)
	detail["total_repayment"] = selected_amount * repayment_multiplier
	detail["monthly_payment"] = float(detail["total_repayment"]) / float(payment_count)
	var result: Dictionary = RunState.apply_bank_loan_proceeds(normalized_offer_id, selected_amount, detail)
	if bool(result.get("success", false)):
		_request_autosave("life_bank_loan")
		life_changed.emit()
		portfolio_changed.emit()
	return result


func _find_bank_loan_offer(offers: Array, offer_id: String) -> Dictionary:
	var normalized_offer_id: String = offer_id.strip_edges()
	for offer_value in offers:
		if typeof(offer_value) != TYPE_DICTIONARY:
			continue
		var offer: Dictionary = offer_value
		if str(offer.get("offer_id", "")) == normalized_offer_id:
			return offer
	return {}


func _normalize_bank_loan_principal(principal: float, offer: Dictionary) -> float:
	var step_size: float = max(float(offer.get("step_size", 1.0)), 1.0)
	var min_principal: float = max(float(offer.get("min_principal", 0.0)), 0.0)
	var max_principal: float = max(float(offer.get("max_principal", 0.0)), 0.0)
	var selected_amount: float = max(principal, 0.0)
	if step_size > 0.0:
		selected_amount = min_principal + round((selected_amount - min_principal) / step_size) * step_size
	if max_principal > 0.0:
		selected_amount = clamp(selected_amount, min_principal, max_principal)
	else:
		selected_amount = max(selected_amount, min_principal)
	return selected_amount


func get_life_snapshot() -> Dictionary:
	return LifeManager.get_life_snapshot(self)


func _build_daily_recap_life_snapshot(portfolio_totals: Dictionary) -> Dictionary:
	if not RunState.has_active_run():
		return {}
	var life_state: Dictionary = RunState.get_player_life()
	var monthly_outflow: float = _life_monthly_outflow_for_state(life_state)
	var cash: float = float(portfolio_totals.get("cash", RunState.player_portfolio.get("cash", 0.0)))
	var market_value: float = float(portfolio_totals.get("market_value", 0.0))
	var equity: float = float(portfolio_totals.get("equity", cash + market_value))
	var runway_months: float = 999.0
	if monthly_outflow > 0.0:
		runway_months = cash / monthly_outflow
	var finance_status: Dictionary = RunState.refresh_cash_stress_state()
	var active_loan: Dictionary = finance_status.get("active_loan", {})
	var active_bank_loan: Dictionary = finance_status.get("active_bank_loan", {})
	var total_required_loan_reserve: float = RunState.required_loan_payment_reserve(finance_status)
	finance_status["loan_payment_risky"] = (
		not active_loan.is_empty() and
		cash < float(active_loan.get("monthly_payment", 0.0)) - 0.0001
	)
	finance_status["bank_loan_payment_risky"] = (
		not active_bank_loan.is_empty() and
		cash < float(active_bank_loan.get("monthly_payment", 0.0)) - 0.0001
	)
	finance_status["total_required_loan_reserve"] = total_required_loan_reserve
	finance_status["total_loan_payment_risky"] = total_required_loan_reserve > 0.0 and cash < total_required_loan_reserve - 0.0001
	return {
		"cash": cash,
		"equity": equity,
		"market_value": market_value,
		"monthly_outflow": monthly_outflow,
		"next_life_payment": _build_next_life_payment_snapshot(monthly_outflow),
		"runway_months": runway_months,
		"finance": finance_status
	}


func _build_daily_recap_first_month_snapshot(portfolio_totals: Dictionary, life_snapshot: Dictionary, daily_action: Dictionary) -> Dictionary:
	var cash: float = float(portfolio_totals.get("cash", RunState.player_portfolio.get("cash", 0.0)))
	var market_value: float = float(portfolio_totals.get("market_value", 0.0))
	var equity: float = float(portfolio_totals.get("equity", cash + market_value))
	var monthly_outflow: float = max(float(life_snapshot.get("monthly_outflow", 0.0)), 0.0)
	var runway_months: float = 999.0
	if monthly_outflow > 0.0:
		runway_months = cash / monthly_outflow
	return {
		"day_index": RunState.day_index,
		"trading_day_number": max(RunState.day_index + 1, 1),
		"trade_date": get_current_trade_date(),
		"cash": cash,
		"equity": equity,
		"monthly_outflow": monthly_outflow,
		"runway_months": runway_months,
		"next_life_payment": life_snapshot.get("next_life_payment", {}).duplicate(true),
		"daily_action": daily_action.duplicate(true),
		"ap_used": int(daily_action.get("used", 0)),
		"ap_remaining": int(daily_action.get("remaining", 0)),
		"ap_limit": int(daily_action.get("limit", 0))
	}


func _build_next_life_payment_snapshot(monthly_outflow: float = -1.0) -> Dictionary:
	if not RunState.has_active_run():
		return {}
	var resolved_outflow: float = monthly_outflow
	if resolved_outflow < 0.0:
		var obligation: Dictionary = _build_life_monthly_obligation()
		resolved_outflow = float(obligation.get("amount", 8500000.0))
	resolved_outflow = max(resolved_outflow, 0.0)
	var current_trade_date: Dictionary = get_current_trade_date()
	var current_year: int = int(current_trade_date.get("year", 2020))
	var current_month: int = int(current_trade_date.get("month", 1))
	for offset in range(1, 34):
		var candidate_date: Dictionary = trading_calendar.advance_trade_days(current_trade_date, offset)
		if (
			int(candidate_date.get("year", current_year)) != current_year or
			int(candidate_date.get("month", current_month)) != current_month
		):
			var trading_day_number: int = trading_calendar.trade_index_for_date(candidate_date)
			return {
				"trade_date": candidate_date,
				"date_key": trading_calendar.to_key(candidate_date),
				"date_text": format_trade_date(candidate_date),
				"amount": resolved_outflow,
				"due_in_trading_days": offset,
				"trading_day_number": trading_day_number,
				"warning": offset <= FIRST_MONTH_LIFE_WARNING_DAYS
			}
	return {}


func _first_month_active_corporate_chain_rows() -> Array:
	var rows: Array = []
	var chains: Dictionary = RunState.get_active_corporate_action_chains()
	var chain_ids: Array = chains.keys()
	chain_ids.sort()
	for chain_id_value in chain_ids:
		var chain_id: String = str(chain_id_value)
		var chain: Dictionary = chains.get(chain_id, {})
		if chain.is_empty():
			continue
		var request_source: String = str(chain.get("request_source", "organic"))
		var company_id: String = str(chain.get("company_id", ""))
		var ticker: String = str(chain.get("target_ticker", ""))
		if ticker.is_empty() and not company_id.is_empty():
			ticker = str(RunState.get_effective_company_definition(company_id).get("ticker", company_id.to_upper()))
		rows.append({
			"chain_id": chain_id,
			"company_id": company_id,
			"ticker": ticker,
			"family": str(chain.get("family", "")),
			"family_label": str(chain.get("family_label", chain.get("family", "Corporate action"))),
			"stage": str(chain.get("stage", "")),
			"status": str(chain.get("status", "active")),
			"next_review_day_number": int(chain.get("next_review_day_index", chain.get("last_advanced_day_index", RunState.day_index + 1))),
			"request_source": request_source,
			"organic": _is_organic_corporate_chain_source(request_source)
		})
	return rows


func _is_organic_corporate_chain_source(request_source: String) -> bool:
	var normalized_source: String = request_source.strip_edges()
	if normalized_source.is_empty() or normalized_source == "organic":
		return true
	if normalized_source == "guided_first_hour":
		return false
	return not normalized_source.begins_with("debug")


func _build_first_month_next_five_rows(life: Dictionary, dashboard_events: Dictionary, active_chain_rows: Array) -> Array:
	var lookahead: Dictionary = {}
	var current_trade_date: Dictionary = get_current_trade_date()
	for offset in range(FIRST_MONTH_DASHBOARD_LOOKAHEAD_DAYS):
		var candidate_date: Dictionary = trading_calendar.advance_trade_days(current_trade_date, offset)
		lookahead[trading_calendar.to_key(candidate_date)] = {
			"trade_date": candidate_date,
			"due_in_trading_days": offset
		}

	var rows: Array = []
	var next_life_payment: Dictionary = life.get("next_life_payment", {})
	var life_key: String = str(next_life_payment.get("date_key", ""))
	if lookahead.has(life_key):
		var life_day: Dictionary = lookahead.get(life_key, {})
		rows.append({
			"type": "life",
			"priority": 100,
			"sort_key": "%s|0|life" % life_key,
			"trade_date": next_life_payment.get("trade_date", {}),
			"date_text": str(next_life_payment.get("date_text", "")),
			"due_in_trading_days": int(life_day.get("due_in_trading_days", next_life_payment.get("due_in_trading_days", 0))),
			"label": "Life payment",
			"detail": "Due %s for %s." % [
				str(next_life_payment.get("date_text", "")),
				_format_currency_compact(float(next_life_payment.get("amount", 0.0)))
			]
		})

	for meeting_value in dashboard_events.get("upcoming_meeting_rows", []):
		if typeof(meeting_value) != TYPE_DICTIONARY:
			continue
		var meeting: Dictionary = meeting_value
		var meeting_date: Dictionary = meeting.get("trade_date", {})
		var meeting_key: String = trading_calendar.to_key(meeting_date)
		if not lookahead.has(meeting_key):
			continue
		var priority: int = 70
		if bool(meeting.get("interactive_v1", false)):
			priority += 10
		rows.append({
			"type": "meeting",
			"priority": priority,
			"sort_key": "%s|1|%s" % [meeting_key, str(meeting.get("ticker", ""))],
			"trade_date": meeting_date,
			"date_text": format_trade_date(meeting_date),
			"due_in_trading_days": int(lookahead.get(meeting_key, {}).get("due_in_trading_days", 0)),
			"company_id": str(meeting.get("company_id", "")),
			"ticker": str(meeting.get("ticker", "")),
			"label": "%s %s" % [str(meeting.get("ticker", "")), str(meeting.get("meeting_label", "Meeting"))],
			"detail": str(meeting.get("public_summary", "Upcoming meeting."))
		})

	for report_value in dashboard_events.get("upcoming_report_rows", []):
		if typeof(report_value) != TYPE_DICTIONARY:
			continue
		var report: Dictionary = report_value
		var report_date: Dictionary = report.get("report_date", {})
		var report_key: String = str(report.get("date_key", trading_calendar.to_key(report_date)))
		if not lookahead.has(report_key):
			continue
		rows.append({
			"type": "report",
			"priority": 50,
			"sort_key": "%s|2|%s" % [report_key, str(report.get("ticker", ""))],
			"trade_date": report_date,
			"date_text": format_trade_date(report_date),
			"due_in_trading_days": int(lookahead.get(report_key, {}).get("due_in_trading_days", 0)),
			"company_id": str(report.get("company_id", "")),
			"ticker": str(report.get("ticker", "")),
			"label": "%s report" % str(report.get("ticker", "")),
			"detail": str(report.get("period_label", "Quarterly filing"))
		})

	for chain_value in active_chain_rows:
		if typeof(chain_value) != TYPE_DICTIONARY:
			continue
		var chain: Dictionary = chain_value
		var next_review_day_number: int = int(chain.get("next_review_day_number", 0))
		if next_review_day_number <= 0:
			continue
		var chain_date: Dictionary = trading_calendar.trade_date_for_index(next_review_day_number)
		var chain_key: String = trading_calendar.to_key(chain_date)
		if not lookahead.has(chain_key):
			continue
		rows.append({
			"type": "corporate",
			"priority": 45,
			"sort_key": "%s|3|%s" % [chain_key, str(chain.get("ticker", ""))],
			"trade_date": chain_date,
			"date_text": format_trade_date(chain_date),
			"due_in_trading_days": int(lookahead.get(chain_key, {}).get("due_in_trading_days", 0)),
			"company_id": str(chain.get("company_id", "")),
			"ticker": str(chain.get("ticker", "")),
			"label": "%s corporate action" % str(chain.get("ticker", "")),
			"detail": "%s is in %s." % [
				str(chain.get("family_label", "Corporate action")),
				_public_corporate_stage_label(str(chain.get("stage", "review")))
			]
		})

	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if str(a.get("sort_key", "")) == str(b.get("sort_key", "")):
			return int(a.get("priority", 0)) > int(b.get("priority", 0))
		return str(a.get("sort_key", "")) < str(b.get("sort_key", ""))
	)
	if rows.size() > 8:
		rows = rows.slice(0, 8)
	return rows


func _public_corporate_stage_label(stage_id: String) -> String:
	match stage_id:
		"hidden_positioning":
			return "quiet positioning"
		"unusual_activity":
			return "unusual trading"
		"rumor_leak":
			return "market speculation"
		"formal_agenda_or_filing":
			return "formal notice"
		"meeting_or_call":
			return "meeting notice"
		"resolution":
			return "resolution watch"
		_:
			return stage_id.replace("_", " ")


func _build_first_month_warning_rows(
	cash: float,
	monthly_outflow: float,
	runway_months: float,
	next_life_payment: Dictionary,
	daily_action: Dictionary,
	active_chain_rows: Array
) -> Array:
	var rows: Array = []
	if not next_life_payment.is_empty() and bool(next_life_payment.get("warning", false)):
		rows.append({
			"id": "life_due",
			"severity": "warning",
			"text": "Next Life payment: %s due %s." % [
				_format_currency_compact(float(next_life_payment.get("amount", monthly_outflow))),
				str(next_life_payment.get("date_text", "soon"))
			]
		})
	var remaining_ap: int = int(daily_action.get("remaining", 0))
	var limit_ap: int = int(daily_action.get("limit", 0))
	if limit_ap > 0 and remaining_ap <= 2:
		rows.append({
			"id": "low_ap",
			"severity": "note",
			"text": "AP pressure: %d AP left. Basic trading, chart reading, Portfolio, and Dashboard review still work." % remaining_ap
		})
	if monthly_outflow > 0.0 and cash < monthly_outflow:
		rows.append({
			"id": "cash_below_month",
			"severity": "warning",
			"text": "Cash is below one month of Life costs; raise cash before the next due date."
		})
	elif monthly_outflow > 0.0 and runway_months < 3.0:
		rows.append({
			"id": "thin_runway",
			"severity": "note",
			"text": "Runway is %.1f months. Keep new positions small until cash recovers." % runway_months
		})
	var organic_count: int = 0
	for chain_value in active_chain_rows:
		if typeof(chain_value) == TYPE_DICTIONARY and bool(chain_value.get("organic", true)):
			organic_count += 1
	if RunState.day_index + 1 <= FIRST_MONTH_WINDOW_DAYS and organic_count >= 2:
		rows.append({
			"id": "busy_corporate_tape",
			"severity": "note",
			"text": "Corporate tape is busy: %d organic chains are live. Prioritize held or watched names." % organic_count
		})
	return rows


func set_life_plan(housing_id: String, lifestyle_id: String, basics_tier_id: String = "") -> Dictionary:
	return LifeManager.set_life_plan(self, housing_id, lifestyle_id, basics_tier_id)


func process_life_development_leads() -> Array:
	return LifeManager.process_life_development_leads(self)


func debug_force_life_development_lead(location_id: String, theme: String = "modern_city", impact_tier: String = "major", source_type: String = "network", outcome_override: String = "") -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	return LifeManager.debug_force_life_development_lead(self, location_id, theme, impact_tier, source_type, outcome_override)


func discover_life_development_lead_from_article(article: Dictionary) -> Dictionary:
	return LifeManager.discover_life_development_lead_from_article(self, article)


func get_life_development_lead_for_article(article: Dictionary) -> Dictionary:
	return LifeManager.get_life_development_lead_for_article(self, article)


func purchase_life_property(catalog_id: String, location_id: String = "", make_primary: bool = false) -> Dictionary:
	return LifeManager.purchase_life_property(self, catalog_id, location_id, make_primary)


func set_primary_residence(property_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var block_reason: String = get_life_action_block_reason("life_plan")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var life_state: Dictionary = RunState.get_player_life()
	var properties: Array = life_state.get("properties", []).duplicate(true)
	var found: bool = false
	for index in range(properties.size()):
		if typeof(properties[index]) != TYPE_DICTIONARY:
			continue
		var property_row: Dictionary = properties[index]
		var is_target: bool = str(property_row.get("id", "")) == property_id
		property_row["is_primary"] = is_target
		if is_target:
			property_row["rented_out"] = false
			found = true
		properties[index] = property_row
	if not found:
		return {"success": false, "message": "Property not found."}
	life_state["properties"] = properties
	life_state["updated_day_index"] = RunState.day_index
	life_state["updated_trade_date"] = get_current_trade_date()
	RunState.set_player_life(life_state)
	_request_autosave("life_primary_residence")
	life_changed.emit()
	return {"success": true, "message": "Primary residence updated.", "snapshot": get_life_snapshot()}


func set_property_rental(property_id: String, rented_out: bool) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var block_reason: String = get_life_action_block_reason("life_plan")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var life_state: Dictionary = RunState.get_player_life()
	var properties: Array = life_state.get("properties", []).duplicate(true)
	var found: bool = false
	for index in range(properties.size()):
		if typeof(properties[index]) != TYPE_DICTIONARY:
			continue
		var property_row: Dictionary = properties[index]
		if str(property_row.get("id", "")) != property_id:
			continue
		if bool(property_row.get("is_primary", false)) and rented_out:
			return {"success": false, "message": "Primary residence cannot be rented out."}
		property_row["rented_out"] = rented_out
		properties[index] = property_row
		found = true
		break
	if not found:
		return {"success": false, "message": "Property not found."}
	life_state["properties"] = properties
	life_state["updated_day_index"] = RunState.day_index
	life_state["updated_trade_date"] = get_current_trade_date()
	RunState.set_player_life(life_state)
	_request_autosave("life_property_rental")
	life_changed.emit()
	return {
		"success": true,
		"message": "Property rental updated." if rented_out else "Property rental stopped.",
		"snapshot": get_life_snapshot()
	}


func sell_life_property(property_id: String) -> Dictionary:
	return LifeManager.sell_life_property(self, property_id)


func purchase_life_car(catalog_id: String) -> Dictionary:
	return LifeManager.purchase_life_car(self, catalog_id)


func set_active_life_car(car_id: String) -> Dictionary:
	return LifeManager.set_active_life_car(self, car_id)


func sell_life_car(car_id: String) -> Dictionary:
	return LifeManager.sell_life_car(self, car_id)


func _build_life_monthly_obligation() -> Dictionary:
	var life_state: Dictionary = RunState.get_player_life()
	var housing: Dictionary = _life_option_by_id(LIFE_HOUSING_OPTIONS, str(life_state.get("housing_id", "")))
	var lifestyle: Dictionary = _life_option_by_id(LIFE_LIFESTYLE_OPTIONS, str(life_state.get("lifestyle_id", "")))
	var basics_tier: Dictionary = _life_basics_tier_by_id(str(life_state.get("basics_tier_id", RunState.LIFE_DEFAULT_BASICS_TIER_ID)))
	var asset_summary: Dictionary = _build_life_asset_summary(life_state)
	var owned_primary: bool = bool(asset_summary.get("owned_primary_residence", false))
	var housing_cost: float = max(float(asset_summary.get("primary_residence_cost", housing.get("monthly_cost", 0.0) if not owned_primary else 0.0)), 0.0)
	if not owned_primary:
		housing_cost = max(float(housing.get("monthly_cost", 0.0)), 0.0)
	var basics_cost: float = max(float(basics_tier.get("monthly_cost", LIFE_BASIC_EXPENSES_MONTHLY)), 0.0)
	var lifestyle_cost: float = max(float(lifestyle.get("monthly_cost", 0.0)), 0.0)
	var monthly_extra: float = max(float(life_state.get("monthly_extra", 0.0)), 0.0)
	var non_primary_property_upkeep: float = max(float(asset_summary.get("non_primary_property_upkeep", 0.0)), 0.0)
	var car_upkeep: float = max(float(asset_summary.get("car_upkeep", 0.0)), 0.0)
	var rental_income: float = max(float(asset_summary.get("rental_income", 0.0)), 0.0)
	var gross_outflow: float = housing_cost + basics_cost + lifestyle_cost + monthly_extra + non_primary_property_upkeep + car_upkeep
	var amount: float = max(gross_outflow - rental_income, 0.0)
	return {
		"company_id": "life",
		"side": "life_obligation",
		"amount": amount,
		"housing_id": str(housing.get("id", "")),
		"housing_label": str(housing.get("label", "")),
		"housing_cost": housing_cost,
		"owned_primary_residence": owned_primary,
		"primary_property_id": str(asset_summary.get("primary_property", {}).get("id", "")),
		"basics_tier_id": str(basics_tier.get("id", "")),
		"basics_tier_label": str(basics_tier.get("label", "")),
		"basic_expenses": basics_cost,
		"lifestyle_id": str(lifestyle.get("id", "")),
		"lifestyle_label": str(lifestyle.get("label", "")),
		"lifestyle_cost": lifestyle_cost,
		"monthly_extra": monthly_extra,
		"non_primary_property_upkeep": non_primary_property_upkeep,
		"car_upkeep": car_upkeep,
		"asset_upkeep": float(asset_summary.get("asset_upkeep", 0.0)),
		"rental_income": rental_income,
		"gross_outflow": gross_outflow,
		"net_lifestyle_cashflow": float(asset_summary.get("net_lifestyle_cashflow", 0.0))
	}


func _life_monthly_outflow_for_state(life_state: Dictionary) -> float:
	var housing: Dictionary = _life_option_by_id(LIFE_HOUSING_OPTIONS, str(life_state.get("housing_id", "")))
	var lifestyle: Dictionary = _life_option_by_id(LIFE_LIFESTYLE_OPTIONS, str(life_state.get("lifestyle_id", "")))
	var basics_tier: Dictionary = _life_basics_tier_by_id(str(life_state.get("basics_tier_id", RunState.LIFE_DEFAULT_BASICS_TIER_ID)))
	var asset_summary: Dictionary = _build_life_asset_summary(life_state)
	var owned_primary: bool = bool(asset_summary.get("owned_primary_residence", false))
	var housing_cost: float = max(float(asset_summary.get("primary_residence_cost", 0.0)), 0.0) if owned_primary else max(float(housing.get("monthly_cost", 0.0)), 0.0)
	var gross_outflow: float = (
		housing_cost +
		max(float(basics_tier.get("monthly_cost", LIFE_BASIC_EXPENSES_MONTHLY)), 0.0) +
		max(float(lifestyle.get("monthly_cost", 0.0)), 0.0) +
		max(float(life_state.get("monthly_extra", 0.0)), 0.0) +
		max(float(asset_summary.get("non_primary_property_upkeep", 0.0)), 0.0) +
		max(float(asset_summary.get("car_upkeep", 0.0)), 0.0)
	)
	return max(gross_outflow - max(float(asset_summary.get("rental_income", 0.0)), 0.0), 0.0)


func _estimate_sellable_holdings_value() -> float:
	var total: float = 0.0
	var holdings: Dictionary = RunState.player_portfolio.get("holdings", {})
	for company_id_value in holdings.keys():
		var company_id: String = str(company_id_value)
		var holding: Dictionary = holdings.get(company_id_value, {})
		var shares: int = int(holding.get("shares", 0))
		if shares <= 0:
			continue
		var estimate: Dictionary = RunState.estimate_sell_order(company_id, shares)
		if bool(estimate.get("success", false)):
			total += max(float(estimate.get("net_proceeds", 0.0)), 0.0)
	return total


func _build_life_asset_summary(life_state: Dictionary) -> Dictionary:
	var properties: Array = life_state.get("properties", []).duplicate(true)
	var cars: Array = life_state.get("cars", []).duplicate(true)
	var property_value: float = 0.0
	var car_value: float = 0.0
	var property_upkeep: float = 0.0
	var non_primary_property_upkeep: float = 0.0
	var car_upkeep: float = 0.0
	var rental_income: float = 0.0
	var status_value: float = 0.0
	var stress_delta: float = 0.0
	var happiness_delta: float = 0.0
	var primary_property: Dictionary = {}
	var active_car: Dictionary = {}
	for property_value_variant in properties:
		if typeof(property_value_variant) != TYPE_DICTIONARY:
			continue
		var property_row: Dictionary = property_value_variant
		var current_value: float = max(float(property_row.get("current_value", property_row.get("purchase_price", 0.0))), 0.0)
		var monthly_upkeep: float = max(float(property_row.get("monthly_upkeep", 0.0)), 0.0)
		property_value += current_value
		property_upkeep += monthly_upkeep
		status_value += max(float(property_row.get("status_value", 0.0)), 0.0)
		if bool(property_row.get("is_primary", false)) and primary_property.is_empty():
			primary_property = property_row.duplicate(true)
			stress_delta += float(property_row.get("stress_delta", 0.0))
			happiness_delta += float(property_row.get("happiness_delta", 0.0))
		else:
			non_primary_property_upkeep += monthly_upkeep
			if bool(property_row.get("rented_out", false)):
				rental_income += max(float(property_row.get("rent_income", 0.0)), 0.0)
	for car_value_variant in cars:
		if typeof(car_value_variant) != TYPE_DICTIONARY:
			continue
		var car_row: Dictionary = car_value_variant
		car_value += max(float(car_row.get("current_value", car_row.get("purchase_price", 0.0))), 0.0)
		car_upkeep += max(float(car_row.get("monthly_upkeep", 0.0)), 0.0)
		status_value += max(float(car_row.get("status_value", 0.0)), 0.0)
		if bool(car_row.get("is_active", false)) and active_car.is_empty():
			active_car = car_row.duplicate(true)
			stress_delta += float(car_row.get("stress_delta", 0.0))
			happiness_delta += float(car_row.get("happiness_delta", 0.0))
	var primary_residence_cost: float = max(float(primary_property.get("monthly_upkeep", 0.0)), 0.0) if not primary_property.is_empty() else 0.0
	var asset_upkeep: float = property_upkeep + car_upkeep
	return {
		"properties": properties,
		"cars": cars,
		"primary_property": primary_property,
		"active_car": active_car,
		"owned_primary_residence": not primary_property.is_empty(),
		"primary_residence_cost": primary_residence_cost,
		"property_value": property_value,
		"car_value": car_value,
		"asset_value": property_value + car_value,
		"property_upkeep": property_upkeep,
		"non_primary_property_upkeep": non_primary_property_upkeep,
		"car_upkeep": car_upkeep,
		"asset_upkeep": asset_upkeep,
		"rental_income": rental_income,
		"net_lifestyle_cashflow": rental_income - asset_upkeep,
		"status_value": status_value,
		"stress_delta": stress_delta,
		"happiness_delta": happiness_delta
	}


func _life_thesis_public_image_score() -> float:
	var score: float = 0.0
	for thesis_value in RunState.get_player_theses().values():
		if typeof(thesis_value) != TYPE_DICTIONARY:
			continue
		var thesis: Dictionary = thesis_value
		if str(thesis.get("status", "open")) != "open":
			continue
		score += min(float(thesis.get("evidence", []).size()), 5.0) * 0.7
		if not thesis.get("report", {}).is_empty():
			score += 1.5
	return min(score, 8.0)


func _life_location_by_id(location_id: String) -> Dictionary:
	var normalized_location_id: String = _normalize_life_location_id(location_id)
	for location_value in LIFE_PROPERTY_LOCATIONS:
		if typeof(location_value) != TYPE_DICTIONARY:
			continue
		var location: Dictionary = location_value
		if str(location.get("id", "")) == normalized_location_id:
			return location.duplicate(true)
	for location_value in LIFE_PROPERTY_LOCATIONS:
		if typeof(location_value) == TYPE_DICTIONARY:
			return location_value.duplicate(true)
	return {"id": "jakarta", "label": "Jakarta", "market_factor": 1.0}


func _normalize_life_location_id(location_id: String) -> String:
	var normalized_location_id: String = location_id.strip_edges().to_lower()
	if normalized_location_id == "bodetabek" or normalized_location_id == "jabodetabek":
		var redirects: Array = ["bogor", "depok", "tangerang", "bekasi", "karawang"]
		var index: int = int(STABLE_RNG.seed_from_parts([RunState.run_seed, "legacy_life_location", normalized_location_id]) % redirects.size())
		return str(redirects[index])
	if normalized_location_id == "bali":
		return "denpasar"
	if normalized_location_id.is_empty():
		return "jakarta"
	return normalized_location_id


func _is_life_development_story_article(article: Dictionary) -> bool:
	return bool(article.get("is_property_development_story", false)) or str(article.get("category", "")) == "property_development"


func _life_development_news_source_id(article: Dictionary) -> String:
	var source_id: String = str(article.get("property_development_source_article_id", "")).strip_edges()
	if source_id.is_empty():
		source_id = str(article.get("source_article_id", "")).strip_edges()
	if source_id.is_empty():
		source_id = str(article.get("id", "")).strip_edges()
	if source_id.is_empty():
		source_id = "news_%d" % RunState.day_index
	return source_id


func _life_development_news_source_note(article: Dictionary, location_id: String, theme: String, intel_level: int) -> String:
	var location_label: String = _life_location_label(location_id)
	var theme_label: String = _life_development_theme_label(theme).to_lower()
	var source_name: String = _life_development_source_name(article)
	match clamp(intel_level, 1, 4):
		1:
			return "%s is drawing property-desk attention because its reported business move could affect future site demand. The city and sponsor have not been publicly named." % source_name
		2:
			return "Reporters are now watching %s for signs of a defined project. The sponsor, project name, and official filings have not surfaced." % location_label
		3:
			return "Reporting now points to a possible %s around %s. Public confirmation is still pending." % [theme_label, location_label]
		_:
			return "Several public signals now point to a possible %s around %s. Reporters are watching for formal filings or official confirmation." % [theme_label, location_label]


func _life_development_source_name(article: Dictionary) -> String:
	var ticker: String = str(article.get("target_ticker", "")).strip_edges()
	if not ticker.is_empty():
		return ticker
	var company_name: String = str(article.get("target_company_name", "")).strip_edges()
	if not company_name.is_empty():
		return company_name
	var sector_name: String = str(article.get("sector_name", "")).strip_edges()
	if not sector_name.is_empty():
		return sector_name
	return "The original report"


func _life_development_low_clarity_theme_label(article: Dictionary, theme: String) -> String:
	var sector_id: String = str(article.get("target_sector_id", ""))
	if sector_id == "health":
		return "Hospital site watch"
	if sector_id == "transport":
		return "Transit site watch"
	if sector_id == "industrial":
		return "Industrial site watch"
	if sector_id == "infra":
		return "Infrastructure site watch"
	if theme == "hospital_university":
		return "Campus site watch"
	return "Site-demand watch"


func _life_development_sector_angle(article: Dictionary, theme: String) -> String:
	match str(article.get("target_sector_id", "")):
		"health":
			return "For healthcare names, the property signal is not their stock move by itself; it is the chance that a hospital, clinic, or medical-campus expansion pulls demand into a specific area."
		"transport":
			return "For transport names, the property signal usually comes from route access, stations, depots, or passenger-flow changes."
		"industrial":
			return "For industrial names, the property signal usually comes from factory, warehouse, supplier, or worker-housing demand around a site."
		"infra":
			return "For infrastructure names, the property signal usually comes from new access, utilities, concessions, or construction corridors."
	if theme == "hospital_university":
		return "The property signal is tied to a possible institutional campus rather than ordinary share-price chatter."
	return "The property signal is tied to possible site demand rather than the stock move alone."


func _article_can_seed_life_development(article: Dictionary) -> bool:
	if _is_life_development_story_article(article):
		return false
	if (
		not str(article.get("property_development_location_id", "")).strip_edges().is_empty() and
		not str(article.get("property_development_theme", "")).strip_edges().is_empty()
	):
		return true
	var sector_id: String = str(article.get("target_sector_id", ""))
	var text: String = ("%s %s %s %s %s" % [
		str(article.get("category", "")),
		str(article.get("event_family", "")),
		str(article.get("headline", "")),
		str(article.get("deck", "")),
		str(article.get("body", ""))
	]).to_lower()
	if sector_id == "health":
		return _text_mentions_health_development(text)
	if LIFE_DEVELOPMENT_RELEVANT_SECTORS.has(sector_id):
		return true
	for keyword in ["property", "infrastructure", "construction", "toll", "transit", "industrial estate", "port", "logistics", "hospital", "university", "resort", "tourism"]:
		if text.find(keyword) >= 0:
			return true
	return false


func _life_development_location_for_seed(seed_value: String) -> String:
	if LIFE_PROPERTY_LOCATIONS.is_empty():
		return "jakarta"
	var index: int = int(STABLE_RNG.seed_from_parts([RunState.run_seed, "life_development_location", seed_value]) % LIFE_PROPERTY_LOCATIONS.size())
	var location: Dictionary = LIFE_PROPERTY_LOCATIONS[index]
	return str(location.get("id", "jakarta"))


func _life_development_location_for_article(article: Dictionary, seed_value: String) -> String:
	var explicit_location_raw: String = str(article.get("property_development_location_id", "")).strip_edges()
	if not explicit_location_raw.is_empty():
		return _normalize_life_location_id(explicit_location_raw)
	return _life_development_location_for_seed(seed_value)


func _life_development_theme_for_article(article: Dictionary, seed_value: String) -> String:
	var explicit_theme: String = str(article.get("property_development_theme", "")).strip_edges()
	if not explicit_theme.is_empty():
		return explicit_theme
	var sector_id: String = str(article.get("target_sector_id", ""))
	if sector_id == "health":
		return "hospital_university"
	if sector_id == "transport":
		return "transit_corridor"
	if sector_id == "industrial":
		return "industrial_estate"
	if sector_id == "infra":
		var infra_text: String = ("%s %s %s" % [str(article.get("headline", "")), str(article.get("deck", "")), str(article.get("body", ""))]).to_lower()
		if infra_text.find("port") >= 0 or infra_text.find("logistics") >= 0:
			return "port_logistics"
		if infra_text.find("transit") >= 0 or infra_text.find("rail") >= 0 or infra_text.find("busway") >= 0:
			return "transit_corridor"
		return "toll_exit"
	return _life_development_theme_for_text("%s %s %s" % [
		str(article.get("headline", "")),
		str(article.get("deck", "")),
		str(article.get("body", ""))
	], seed_value)


func _life_development_theme_for_text(text: String, seed_value: String) -> String:
	var lower_text: String = text.to_lower()
	if lower_text.find("toll") >= 0:
		return "toll_exit"
	if lower_text.find("transit") >= 0 or lower_text.find("rail") >= 0 or lower_text.find("busway") >= 0:
		return "transit_corridor"
	if lower_text.find("industrial") >= 0 or lower_text.find("warehouse") >= 0:
		return "industrial_estate"
	if lower_text.find("hospital") >= 0 or lower_text.find("university") >= 0 or lower_text.find("campus") >= 0:
		return "hospital_university"
	if lower_text.find("resort") >= 0 or lower_text.find("tourism") >= 0:
		return "resort_zone"
	if lower_text.find("port") >= 0 or lower_text.find("logistics") >= 0:
		return "port_logistics"
	var index: int = int(STABLE_RNG.seed_from_parts([RunState.run_seed, "life_development_theme", seed_value]) % LIFE_DEVELOPMENT_THEMES.size())
	return str(LIFE_DEVELOPMENT_THEMES[index].get("id", "modern_city"))


func _text_mentions_health_development(text: String) -> bool:
	var lower_text: String = text.to_lower()
	for keyword in ["hospital", "clinic", "medical campus", "campus", "healthcare complex", "new wing", "beds", "facility", "facilities", "land acquisition", "site", "expansion", "build", "construction", "permit"]:
		if lower_text.find(keyword) >= 0:
			return true
	return false


func _life_development_clarity_label(clarity_level: int) -> String:
	match clamp(clarity_level, 1, 4):
		1:
			return "Developing report"
		2:
			return "Area reported"
		3:
			return "Project reported"
		_:
			return "Public signals"


func _life_location_label(location_id: String) -> String:
	return str(_life_location_by_id(location_id).get("label", "Jakarta"))


func _life_development_theme_label(theme: String) -> String:
	for theme_value in LIFE_DEVELOPMENT_THEMES:
		if typeof(theme_value) == TYPE_DICTIONARY and str(theme_value.get("id", "")) == theme:
			return str(theme_value.get("label", theme.capitalize()))
	return theme.capitalize()


func _network_contact_definition_by_id(contact_id: String) -> Dictionary:
	for contact_value in DataRepository.get_contact_network_data().get("contacts", []):
		if typeof(contact_value) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = contact_value
		if str(contact.get("id", "")) == contact_id:
			return contact.duplicate(true)
	return {}


func _network_contact_display_name(contact_id: String) -> String:
	var contact: Dictionary = _network_contact_definition_by_id(contact_id)
	return str(contact.get("display_name", contact_id))


func _life_option_by_id(options: Array, option_id: String) -> Dictionary:
	for option_value in options:
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		if str(option.get("id", "")) == option_id:
			return option.duplicate(true)
	if options.is_empty() or typeof(options[0]) != TYPE_DICTIONARY:
		return {}
	return options[0].duplicate(true)


func _life_basics_tier_by_id(tier_id: String) -> Dictionary:
	for tier_value in LIFE_BASICS_TIERS:
		if typeof(tier_value) != TYPE_DICTIONARY:
			continue
		var tier: Dictionary = tier_value
		if str(tier.get("id", "")) == tier_id:
			return tier.duplicate(true)
	for tier_value in LIFE_BASICS_TIERS:
		if typeof(tier_value) == TYPE_DICTIONARY:
			var tier: Dictionary = tier_value
			if str(tier.get("id", "")) == RunState.LIFE_DEFAULT_BASICS_TIER_ID:
				return tier.duplicate(true)
	return LIFE_BASICS_TIERS[0].duplicate(true)


func get_sector_rows() -> Array:
	var grouped_rows: Dictionary = {}
	var ordered_rows: Array = []

	for company_id in RunState.company_order:
		var snapshot: Dictionary = get_company_snapshot(str(company_id), false)
		var sector_id: String = str(snapshot.get("sector_id", ""))
		if sector_id.is_empty():
			continue

		var sector_definition: Dictionary = DataRepository.get_sector_definition(sector_id)
		if not grouped_rows.has(sector_id):
			grouped_rows[sector_id] = {
				"id": sector_id,
				"name": str(sector_definition.get("name", sector_id.capitalize())),
				"trend_bias": float(sector_definition.get("trend_bias", 0.0)),
				"volatility_bias": float(sector_definition.get("volatility_bias", 0.0)),
				"company_count": 0,
				"advancers": 0,
				"decliners": 0,
				"change_sum": 0.0,
				"strongest_ticker": "",
				"strongest_change_pct": 0.0,
				"strongest_flow_tag": "neutral",
				"strongest_flow_pressure": -1.0
			}

		var sector_row: Dictionary = grouped_rows[sector_id]
		var daily_change_pct: float = float(snapshot.get("daily_change_pct", 0.0))
		var broker_flow: Dictionary = snapshot.get("broker_flow", {})
		var pressure_value: float = abs(float(broker_flow.get("net_pressure", 0.0)))

		sector_row["company_count"] = int(sector_row.get("company_count", 0)) + 1
		sector_row["change_sum"] = float(sector_row.get("change_sum", 0.0)) + daily_change_pct
		if daily_change_pct > 0.0:
			sector_row["advancers"] = int(sector_row.get("advancers", 0)) + 1
		elif daily_change_pct < 0.0:
			sector_row["decliners"] = int(sector_row.get("decliners", 0)) + 1

		if pressure_value > float(sector_row.get("strongest_flow_pressure", -1.0)):
			sector_row["strongest_ticker"] = str(snapshot.get("ticker", ""))
			sector_row["strongest_change_pct"] = daily_change_pct
			sector_row["strongest_flow_tag"] = str(broker_flow.get("flow_tag", "neutral"))
			sector_row["strongest_flow_pressure"] = pressure_value

		grouped_rows[sector_id] = sector_row

	for sector_definition_value in DataRepository.get_sector_definitions():
		var sector_definition: Dictionary = sector_definition_value
		var sector_id: String = str(sector_definition.get("id", ""))
		if not grouped_rows.has(sector_id):
			continue

		var grouped_row: Dictionary = grouped_rows[sector_id].duplicate(true)
		var company_count: int = int(grouped_row.get("company_count", 0))
		var average_change_pct: float = 0.0
		if company_count > 0:
			average_change_pct = float(grouped_row.get("change_sum", 0.0)) / float(company_count)

		grouped_row["average_change_pct"] = average_change_pct
		ordered_rows.append(grouped_row)

	return ordered_rows


func get_latest_summary() -> Dictionary:
	return RunState.daily_summary.duplicate(true)


func get_daily_activity_snapshot(force_refresh: bool = false) -> Dictionary:
	if not RunState.has_active_run():
		return _empty_daily_activity_snapshot()
	var cache_key: String = _daily_activity_snapshot_cache_key()
	if (
		force_refresh or
		daily_activity_snapshot_cache.is_empty() or
		str(daily_activity_snapshot_cache.get("cache_key", "")) != cache_key
	):
		_rebuild_daily_activity_snapshot_cache({}, cache_key)
	return daily_activity_snapshot_cache.duplicate(true)


func get_daily_recap_snapshot() -> Dictionary:
	if not RunState.has_active_run():
		return {}
	var summary: Dictionary = get_latest_summary()
	var dashboard_event_snapshot: Dictionary = get_dashboard_event_snapshot()
	var daily_activity_snapshot: Dictionary = get_daily_activity_snapshot()
	var activity_counts: Dictionary = daily_activity_snapshot.get("activity_counts", {}).duplicate(true)
	var portfolio_totals: Dictionary = _get_portfolio_totals_snapshot()
	var daily_action: Dictionary = get_daily_action_snapshot()
	var life_snapshot: Dictionary = _build_daily_recap_life_snapshot(portfolio_totals)
	var first_month_balance_snapshot: Dictionary = _build_daily_recap_first_month_snapshot(portfolio_totals, life_snapshot, daily_action)
	return {
		"day_index": RunState.day_index,
		"trade_date": get_current_trade_date(),
		"summary": summary,
		"market_sentiment": RunState.market_sentiment,
		"portfolio": portfolio_totals,
		"life": life_snapshot,
		"last_day_results": RunState.last_day_results.duplicate(true),
		"dashboard_events": dashboard_event_snapshot,
		"first_month_balance": first_month_balance_snapshot,
		"activity_counts": activity_counts,
		"badges": get_desktop_app_badge_snapshot(activity_counts),
		"daily_action": daily_action
	}


func get_desktop_app_badge_snapshot(activity_counts: Dictionary = {}) -> Dictionary:
	if not RunState.has_active_run():
		return {}
	var resolved_counts: Dictionary = activity_counts
	var badge_day_index: int = RunState.day_index
	if resolved_counts.is_empty():
		var cached_badges: Dictionary = RunState.get_desktop_app_badge_counts()
		resolved_counts = cached_badges.get("counts", {})
		badge_day_index = int(cached_badges.get("day_index", RunState.day_index))
	var rows: Dictionary = {}
	for app_id in ["news", "social", "network"]:
		var count: int = max(int(resolved_counts.get(app_id, 0)), 0)
		var seen_day: int = RunState.get_desktop_app_seen_day(app_id)
		var visible: bool = count > 0 and badge_day_index == RunState.day_index and seen_day < badge_day_index
		rows[app_id] = {
			"visible": visible,
			"count": count,
			"label": str(min(count, 9)) if count > 0 and count < 10 else ("9+" if count >= 10 else "!"),
			"day_index": badge_day_index,
			"seen_day_index": seen_day
		}
	return rows


func _rebuild_daily_activity_snapshot_cache(news_snapshot: Dictionary = {}, cache_key: String = "", log_phase_details: bool = false, feed_context: Dictionary = {}) -> Dictionary:
	if not RunState.has_active_run():
		daily_activity_snapshot_cache = _empty_daily_activity_snapshot()
		return daily_activity_snapshot_cache
	var phase_started_at_usec: int = Time.get_ticks_usec()
	var resolved_news_snapshot: Dictionary = news_snapshot
	if resolved_news_snapshot.is_empty():
		resolved_news_snapshot = _build_news_snapshot()
	_log_advance_perf_elapsed(log_phase_details, "build_daily_activity_cache:resolve_news", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var social_activity_count: int = _count_twooter_current_day_activity(feed_context)
	_log_advance_perf_elapsed(log_phase_details, "build_daily_activity_cache:social_count", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var network_activity_count: int = contact_network_system.count_current_day_activity(RunState)
	_log_advance_perf_elapsed(log_phase_details, "build_daily_activity_cache:network_count", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var activity_counts: Dictionary = {
		"news": _count_news_articles(resolved_news_snapshot),
		"social": social_activity_count,
		"network": network_activity_count,
	}
	_log_advance_perf_elapsed(log_phase_details, "build_daily_activity_cache:count_activity", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	RunState.set_desktop_app_badge_counts(activity_counts)
	_log_advance_perf_elapsed(log_phase_details, "build_daily_activity_cache:set_badges", phase_started_at_usec)
	var resolved_cache_key: String = cache_key if not cache_key.is_empty() else _daily_activity_snapshot_cache_key()
	daily_activity_snapshot_cache = {
		"cache_key": resolved_cache_key,
		"day_index": RunState.day_index,
		"trade_date": RunState.get_current_trade_date(),
		"activity_counts": activity_counts,
		"badge_counts": RunState.get_desktop_app_badge_counts()
	}
	return daily_activity_snapshot_cache


func _invalidate_daily_activity_snapshot_cache() -> void:
	daily_activity_snapshot_cache = {}


func _cache_news_snapshot(snapshot: Dictionary, unlocked_intel_level: int = -1) -> void:
	if not RunState.has_active_run() or snapshot.is_empty():
		news_snapshot_cache = {}
		return
	var resolved_intel_level: int = unlocked_intel_level
	if resolved_intel_level < 1:
		resolved_intel_level = get_unlocked_news_intel_level()
	news_snapshot_cache = {
		"cache_key": _news_snapshot_cache_key(resolved_intel_level),
		"snapshot": snapshot.duplicate(true)
	}


func _invalidate_news_snapshot_cache() -> void:
	news_snapshot_cache = {}


func _news_snapshot_cache_key(unlocked_intel_level: int) -> String:
	if not RunState.has_active_run():
		return ""
	var trade_date: Dictionary = RunState.get_current_trade_date()
	var life_state: Dictionary = RunState.get_player_life()
	return "%d|%s|news:%d|companies:%d|market:%d|events:%d|special:%d|arcs:%d|development:%d" % [
		RunState.day_index,
		trading_calendar.to_key(trade_date),
		unlocked_intel_level,
		RunState.company_order.size(),
		RunState.market_history.size(),
		RunState.event_history.size(),
		RunState.active_special_events.size(),
		RunState.active_company_arcs.size(),
		life_state.get("development_leads", []).size()
	]


func _empty_daily_activity_snapshot() -> Dictionary:
	return {
		"cache_key": "",
		"day_index": RunState.day_index if RunState.has_active_run() else 0,
		"trade_date": RunState.get_current_trade_date() if RunState.has_active_run() else {},
		"activity_counts": {
			"news": 0,
			"social": 0,
			"network": 0
		},
		"badge_counts": RunState.get_desktop_app_badge_counts() if RunState.has_active_run() else {
			"day_index": 0,
			"counts": {
				"news": 0,
				"social": 0,
				"network": 0
			}
		}
	}


func _daily_activity_snapshot_cache_key() -> String:
	if not RunState.has_active_run():
		return ""
	var trade_date: Dictionary = RunState.get_current_trade_date()
	var twooter_state: Dictionary = RunState.get_twooter_social_state()
	return "%d|%s|news:%d|social:%d|twooter_posts:%d|twooter_likes:%d|twooter_messages:%d|events:%d|tips:%d|requests:%d|discoveries:%d|contacts:%d" % [
		RunState.day_index,
		trading_calendar.to_key(trade_date),
		get_unlocked_news_intel_level(),
		get_unlocked_twooter_access_tier(),
		twooter_state.get("post_interactions", {}).size(),
		twooter_state.get("liked_posts", {}).size(),
		twooter_state.get("messages", {}).size(),
		RunState.event_history.size(),
		RunState.network_tip_journal.size(),
		RunState.network_requests.size(),
		RunState.network_discoveries.size(),
		RunState.network_contacts.size()
	]


func mark_desktop_app_seen(app_id: String) -> void:
	if RunState.get_desktop_app_seen_day(app_id) >= RunState.day_index:
		return
	RunState.mark_desktop_app_seen(app_id)
	_request_autosave("desktop_app_seen")


func _count_news_articles(news_snapshot: Dictionary) -> int:
	var seen_article_ids: Dictionary = {}
	var outlet_lookup: Dictionary = {}
	for outlet_value in news_snapshot.get("outlets", []):
		var outlet: Dictionary = outlet_value
		outlet_lookup[str(outlet.get("id", ""))] = bool(outlet.get("unlocked", true))
	for feed_value in news_snapshot.get("feeds", {}).values():
		var feed: Dictionary = feed_value
		var outlet_id: String = str(feed.get("outlet_id", ""))
		if not bool(outlet_lookup.get(outlet_id, true)):
			continue
		for article_value in feed.get("articles", []):
			var article: Dictionary = article_value
			var article_id: String = str(article.get("id", article.get("headline", "")))
			if article_id.is_empty() or seen_article_ids.has(article_id):
				continue
			seen_article_ids[article_id] = true
	return seen_article_ids.size()


func _count_twooter_current_day_activity(feed_context: Dictionary = {}) -> int:
	var social_trade_date: Dictionary = {}
	if feed_context.has("trade_date"):
		social_trade_date = feed_context.get("trade_date", {}).duplicate(true)
	else:
		social_trade_date = get_current_trade_date()
		social_trade_date["day_index"] = RunState.day_index
	var market_history: Array = []
	if feed_context.has("market_history"):
		market_history = feed_context.get("market_history", [])
	else:
		market_history = get_market_history()
	var event_history: Array = []
	if feed_context.has("event_history"):
		event_history = feed_context.get("event_history", [])
	else:
		event_history = get_event_history()
	var active_special_events: Array = []
	if feed_context.has("active_special_events"):
		active_special_events = feed_context.get("active_special_events", [])
	else:
		active_special_events = get_active_special_events()
	var active_company_arcs: Array = []
	if feed_context.has("active_company_arcs"):
		active_company_arcs = feed_context.get("active_company_arcs", [])
	else:
		active_company_arcs = get_active_company_arcs()
	var company_rows: Array = []
	if feed_context.has("company_rows"):
		company_rows = feed_context.get("company_rows", [])
	else:
		company_rows = get_company_rows()
	var count: int = twooter_feed_system.count_social_posts(
		DataRepository.get_twooter_feed_data(),
		market_history,
		event_history,
		active_special_events,
		active_company_arcs,
		social_trade_date,
		get_unlocked_twooter_access_tier(),
		company_rows
	)
	return count + _count_twooter_current_day_interactions()


func _count_twooter_current_day_interactions() -> int:
	var count: int = 0
	var social_state: Dictionary = RunState.get_twooter_social_state()
	for interaction_value in social_state.get("post_interactions", {}).values():
		if typeof(interaction_value) != TYPE_DICTIONARY:
			continue
		var interaction: Dictionary = interaction_value
		for reply_value in interaction.get("replies", []):
			if typeof(reply_value) == TYPE_DICTIONARY and int(reply_value.get("day_index", -9999)) == RunState.day_index:
				count += 1
	for like_value in social_state.get("liked_posts", {}).values():
		if typeof(like_value) == TYPE_DICTIONARY and int(like_value.get("day_index", -9999)) == RunState.day_index:
			count += 1
	for thread_value in social_state.get("messages", {}).values():
		if typeof(thread_value) != TYPE_DICTIONARY:
			continue
		var thread: Dictionary = thread_value
		for row_value in thread.get("rows", []):
			if typeof(row_value) != TYPE_DICTIONARY:
				continue
			var row: Dictionary = row_value
			if int(row.get("day_index", -9999)) != RunState.day_index:
				continue
			if str(row.get("sender", "")) == "player" or str(row.get("action_id", "")) == "network_followup_reaction":
				count += 1
	return count


func _count_network_current_day_activity(network_snapshot: Dictionary) -> int:
	var count: int = 0
	for row_value in network_snapshot.get("journal", []):
		var row: Dictionary = row_value
		if int(row.get("day_index", -9999)) == RunState.day_index:
			count += 1
	return count


func get_trade_history() -> Array:
	var rows: Array = []
	var raw_history: Array = RunState.get_trade_history()

	for index in range(raw_history.size() - 1, -1, -1):
		var entry: Dictionary = raw_history[index]
		var company_id: String = str(entry.get("company_id", ""))
		var definition: Dictionary = RunState.get_effective_company_definition(company_id)
		rows.append({
			"day_index": int(entry.get("day_index", 0)),
			"company_id": company_id,
			"ticker": str(definition.get("ticker", company_id.to_upper())),
			"side": str(entry.get("side", "")),
			"lots": int(entry.get("lots", 0)),
			"shares": int(entry.get("shares", 0)),
			"price_per_share": float(entry.get("price_per_share", 0.0)),
			"gross_value": float(entry.get("gross_value", 0.0)),
			"fee_rate": float(entry.get("fee_rate", 0.0)),
			"fee": float(entry.get("fee", 0.0)),
			"net_cash_impact": float(entry.get("net_cash_impact", 0.0)),
			"cash_after": float(entry.get("cash_after", 0.0)),
			"realized_pnl": float(entry.get("realized_pnl", 0.0))
		})

	return rows


func get_event_history() -> Array:
	return RunState.get_event_history()


func get_market_history() -> Array:
	return RunState.get_market_history()


func get_active_company_arcs() -> Array:
	return RunState.get_active_company_arcs()


func get_active_special_events() -> Array:
	return RunState.get_active_special_events()


func get_network_snapshot() -> Dictionary:
	if not RunState.has_active_run():
		return {
			"recognition": {"score": 0.0, "label": "Unknown", "contact_cap": 2},
			"contacts": [],
			"discoveries": [],
			"requests": [],
			"met_count": 0,
			"contact_cap": 2
		}
	return contact_network_system.build_snapshot(RunState, DataRepository)


func discover_network_contacts_from_article(article: Dictionary) -> Array:
	if not RunState.has_active_run() or article.is_empty():
		return []
	var discovered: Array = contact_network_system.discover_from_article(RunState, DataRepository, article)
	var development_lead: Dictionary = LifeManager.maybe_create_life_development_lead_from_news_article(self, article) if _is_life_development_story_article(article) else {}
	if bool(development_lead.get("success", false)) and not bool(development_lead.get("duplicate", false)):
		life_changed.emit()
		network_changed.emit()
	if not discovered.is_empty() or bool(development_lead.get("success", false)):
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("discover_network_from_article")
	return discovered


func discover_network_contacts_for_company(company_id: String) -> Array:
	if not RunState.has_active_run() or company_id.is_empty():
		return []
	var discovered: Array = contact_network_system.discover_for_company(RunState, DataRepository, company_id)
	if not discovered.is_empty():
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("discover_network_for_company")
	return discovered


func meet_contact(contact_id: String, source_context: Dictionary = {}) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if not _can_spend_network_action("meet"):
		return {"success": false, "message": _network_action_no_ap_message("meet")}
	var result: Dictionary = contact_network_system.meet_contact(RunState, DataRepository, contact_id, source_context)
	if bool(result.get("success", false)):
		_spend_network_action("meet")
		result["action_cost"] = get_network_action_cost("meet")
		_record_steam_progress_event("network_contact_met", {
			"contact_id": contact_id,
			"source_context": source_context.duplicate(true)
		})
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("network_meet")
		daily_actions_changed.emit()
		network_changed.emit()
	return result


func request_contact_tip(contact_id: String, company_id: String = "") -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if not _can_spend_network_action("tip"):
		return {"success": false, "message": _network_action_no_ap_message("tip")}
	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = contact_network_system.request_tip(RunState, DataRepository, corporate_action_system, contact_id, company_id)
	if bool(result.get("success", false)):
		var development_lead: Dictionary = LifeManager.maybe_create_life_development_lead_from_network_tip(self, contact_id, result)
		if bool(development_lead.get("success", false)):
			result["development_lead"] = development_lead.get("lead", {}).duplicate(true)
		_spend_network_action("tip")
		result["action_cost"] = get_network_action_cost("tip")
		_record_steam_progress_event("network_tip_requested", {
			"contact_id": contact_id,
			"company_id": company_id
		})
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("network_tip")
		daily_actions_changed.emit()
		if result.has("development_lead"):
			life_changed.emit()
		network_changed.emit()
	return result


func accept_dirty_tip_offer(offer_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var block_reason: String = get_life_action_block_reason("network")
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason}
	var result: Dictionary = dirty_tip_system.accept_offer(RunState, offer_id)
	_after_dirty_tip_decision(result, "dirty_tip_accept")
	return result


func decline_dirty_tip_offer(offer_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var result: Dictionary = dirty_tip_system.decline_offer(RunState, offer_id)
	_after_dirty_tip_decision(result, "dirty_tip_decline")
	return result


func report_dirty_tip_offer(offer_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var result: Dictionary = dirty_tip_system.report_offer(RunState, offer_id)
	_after_dirty_tip_decision(result, "dirty_tip_report")
	return result


func debug_force_dirty_tip_offer(company_id: String = "") -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var target_company_id: String = company_id.strip_edges()
	if target_company_id.is_empty() and not RunState.company_order.is_empty():
		target_company_id = str(RunState.company_order[0])
	if target_company_id.is_empty():
		return {"success": false, "message": "No stock universe is loaded yet."}
	var definition: Dictionary = RunState.get_effective_company_definition(target_company_id, false, false)
	if definition.is_empty():
		return {"success": false, "message": "Pick a valid stock first."}
	var directives: Dictionary = {
		"selected_lane": "dirty_market",
		"dirty_market_pressure": 1.0,
		"focus_company_ids": [target_company_id],
		"focus_company_weights": {target_company_id: 2.0}
	}
	var result: Dictionary = dirty_tip_system.resolve_day(
		RunState,
		DataRepository,
		directives,
		max(RunState.day_index, 0),
		RunState.get_current_trade_date(),
		target_company_id
	)
	var offers: Array = result.get("offers", [])
	if offers.is_empty():
		result["success"] = false
		result["message"] = "Dirty tip could not be forced: %s." % str(result.get("reason", "unknown"))
		return result
	result["success"] = true
	result["company_id"] = target_company_id
	result["ticker"] = str(definition.get("ticker", target_company_id.to_upper()))
	result["message"] = "Dirty tip offer forced for %s." % str(result.get("ticker", target_company_id.to_upper()))
	_invalidate_daily_activity_snapshot_cache()
	_request_autosave("debug_dirty_tip_offer")
	network_changed.emit()
	return result


func debug_force_dirty_tip_jail(company_id: String = "") -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var target_company_id: String = company_id.strip_edges()
	if target_company_id.is_empty() and not RunState.company_order.is_empty():
		target_company_id = str(RunState.company_order[0])
	if target_company_id.is_empty():
		return {"success": false, "message": "No stock universe is loaded yet."}
	var definition: Dictionary = RunState.get_effective_company_definition(target_company_id, false, false)
	if definition.is_empty():
		return {"success": false, "message": "Pick a valid stock first."}

	var life_state: Dictionary = RunState.get_player_life()
	var legal_state: Dictionary = life_state.get("legal_state", {}) if typeof(life_state.get("legal_state", {})) == TYPE_DICTIONARY else {}
	if bool(legal_state.get("active", false)) and int(legal_state.get("days_remaining", 0)) > 0:
		return {"success": false, "message": "Legal hold is already active."}

	var offer: Dictionary = _debug_open_dirty_tip_request(target_company_id)
	if offer.is_empty():
		var offer_result: Dictionary = debug_force_dirty_tip_offer(target_company_id)
		if not bool(offer_result.get("success", false)):
			return offer_result
		var offers: Array = offer_result.get("offers", [])
		if offers.is_empty() or typeof(offers[0]) != TYPE_DICTIONARY:
			return {"success": false, "message": "Dirty tip jail could not create an offer."}
		offer = offers[0]
	var offer_id: String = str(offer.get("id", ""))
	if str(offer.get("status", "")) == "offered":
		var accept_result: Dictionary = dirty_tip_system.accept_offer(RunState, offer_id)
		if not bool(accept_result.get("success", false)):
			return accept_result
	elif str(offer.get("status", "")) != "accepted":
		return {"success": false, "message": "Dirty tip jail needs an offered or accepted case."}

	var requests: Dictionary = RunState.get_network_requests()
	var request: Dictionary = requests.get(offer_id, {}).duplicate(true)
	if request.is_empty():
		return {"success": false, "message": "Dirty tip jail could not find the accepted case."}
	request["debug_force_caught"] = true
	request["due_day_index"] = int(RunState.day_index)
	request["active_until_day_index"] = int(RunState.day_index)
	request["journal_detail"] = "Debug forced a caught dirty-tip case on %s." % str(request.get("target_ticker", target_company_id.to_upper()))
	requests[offer_id] = request.duplicate(true)
	RunState.set_network_requests(requests)

	var dirty_tip_results: Array = dirty_tip_system.process_due_cases(RunState, DataRepository)
	if dirty_tip_results.is_empty():
		return {"success": false, "message": "Dirty tip jail did not resolve a case."}
	var caught_result: Dictionary = {}
	for result_value in dirty_tip_results:
		if typeof(result_value) != TYPE_DICTIONARY:
			continue
		var result_row: Dictionary = result_value
		if str(result_row.get("id", "")) == offer_id:
			caught_result = result_row
			break
	if caught_result.is_empty() and typeof(dirty_tip_results[0]) == TYPE_DICTIONARY:
		caught_result = dirty_tip_results[0]
	if str(caught_result.get("status", "")) != "caught":
		return {"success": false, "message": "Dirty tip jail resolved without a caught outcome."}

	RunState.last_day_results["dirty_tip_results"] = dirty_tip_results.duplicate(true)
	var updated_life_state: Dictionary = RunState.get_player_life()
	var updated_legal_state: Dictionary = updated_life_state.get("legal_state", {}) if typeof(updated_life_state.get("legal_state", {})) == TYPE_DICTIONARY else {}
	RunState.last_day_results["life_legal"] = {
		"legal_hold_day_completed": false,
		"legal_hold_active": bool(updated_legal_state.get("active", false)),
		"days_before": int(updated_legal_state.get("days_remaining", 0)),
		"days_remaining": int(updated_legal_state.get("days_remaining", 0)),
		"case_id": str(updated_legal_state.get("case_id", offer_id)),
		"target_company_id": str(updated_legal_state.get("target_company_id", target_company_id)),
		"target_ticker": str(updated_legal_state.get("target_ticker", definition.get("ticker", target_company_id.to_upper()))),
		"status": str(updated_legal_state.get("status", "held")),
		"trade_date": RunState.get_current_trade_date()
	}
	_invalidate_daily_activity_snapshot_cache()
	_request_autosave("debug_force_dirty_tip_jail")
	network_changed.emit()
	life_changed.emit()
	portfolio_changed.emit()
	return {
		"success": true,
		"message": "Debug jail: %s caught, fine %s, legal hold %d day(s)." % [
			str(definition.get("ticker", target_company_id.to_upper())),
			_format_currency(float(caught_result.get("fine_amount", 0.0))),
			int(caught_result.get("legal_days", updated_legal_state.get("days_remaining", 0)))
		],
		"company_id": target_company_id,
		"ticker": str(definition.get("ticker", target_company_id.to_upper())),
		"offer": offer.duplicate(true),
		"result": caught_result.duplicate(true),
		"legal_state": updated_legal_state.duplicate(true)
	}


func debug_force_hospital_stress() -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	return LifeManager.debug_force_hospital_stress(self)


func _debug_open_dirty_tip_request(company_id: String) -> Dictionary:
	for request_value in RunState.get_network_requests().values():
		if typeof(request_value) != TYPE_DICTIONARY:
			continue
		var request: Dictionary = request_value
		if str(request.get("request_type", "")) != "dirty_tip":
			continue
		if not (str(request.get("status", "")) in ["offered", "accepted"]):
			continue
		if str(request.get("target_company_id", "")) != company_id:
			continue
		return request.duplicate(true)
	return {}


func _after_dirty_tip_decision(result: Dictionary, save_reason: String) -> void:
	if not bool(result.get("success", false)):
		return
	_invalidate_daily_activity_snapshot_cache()
	_request_autosave(save_reason)
	network_changed.emit()


func accept_contact_request(contact_id: String, company_id: String = "") -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if not _can_spend_network_action("request"):
		return {"success": false, "message": _network_action_no_ap_message("request")}
	var result: Dictionary = contact_network_system.accept_request(RunState, DataRepository, contact_id, company_id)
	if bool(result.get("success", false)):
		_spend_network_action("request")
		result["action_cost"] = get_network_action_cost("request")
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("network_request")
		daily_actions_changed.emit()
		network_changed.emit()
	return result


func request_contact_referral(contact_id: String, company_id: String = "", affiliation_role: String = "") -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if not _can_spend_network_action("referral"):
		return {"success": false, "message": _network_action_no_ap_message("referral")}
	var result: Dictionary = contact_network_system.request_referral(RunState, DataRepository, contact_id, company_id, affiliation_role)
	if bool(result.get("success", false)):
		_spend_network_action("referral")
		result["action_cost"] = get_network_action_cost("referral")
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("network_referral")
		daily_actions_changed.emit()
		network_changed.emit()
	return result


func follow_up_contact_tip(contact_id: String, followup_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if not _can_spend_network_action("followup"):
		return {"success": false, "message": _network_action_no_ap_message("followup")}
	var result: Dictionary = contact_network_system.follow_up_tip(RunState, DataRepository, contact_id, followup_id)
	if bool(result.get("success", false)):
		_spend_network_action("followup")
		result["action_cost"] = get_network_action_cost("followup")
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("network_tip_followup")
		daily_actions_changed.emit()
		network_changed.emit()
	return result


func ask_contact_source_check(contact_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if not _can_spend_network_action("source_check"):
		return {"success": false, "message": _network_action_no_ap_message("source_check")}
	var result: Dictionary = contact_network_system.ask_source_check(RunState, DataRepository, contact_id)
	if bool(result.get("success", false)):
		_spend_network_action("source_check")
		result["action_cost"] = get_network_action_cost("source_check")
		_invalidate_daily_activity_snapshot_cache()
		_request_autosave("network_source_check")
		daily_actions_changed.emit()
		network_changed.emit()
	return result


func get_debug_event_generator_catalog() -> Array:
	var group_labels: Dictionary = {
		"market": "Market Events",
		"company": "Company Events",
		"company_arc": "Company Arcs",
		"person": "Person Events",
		"special": "Special Events"
	}
	var group_order: Array = ["market", "company", "company_arc", "person", "special"]
	var grouped_events: Dictionary = {}
	for group_id_value in group_order:
		grouped_events[str(group_id_value)] = []

	for event_definition_value in DataRepository.get_event_definitions():
		var event_definition: Dictionary = event_definition_value
		var event_id: String = str(event_definition.get("id", ""))
		if event_id.is_empty():
			continue

		var group_id: String = "company_arc" if DEBUG_COMPANY_ARC_EVENT_IDS.has(event_id) else str(event_definition.get("event_family", ""))
		if not grouped_events.has(group_id):
			continue

		grouped_events[group_id].append({
			"event_id": event_id,
			"description": str(event_definition.get("description", ""))
		})

	var catalog: Array = []
	for group_id_value in group_order:
		var group_id: String = str(group_id_value)
		var events: Array = grouped_events.get(group_id, [])
		events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return str(a.get("event_id", "")) < str(b.get("event_id", ""))
		)
		catalog.append({
			"id": group_id,
			"label": str(group_labels.get(group_id, group_id.capitalize())),
			"events": events
		})

	return catalog


func debug_generate_event(event_id: String) -> Dictionary:
	if not OS.is_debug_build():
		return {"success": false, "message": "Debug tools are only available in debug builds."}
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run to modify."}

	var event_definition: Dictionary = DataRepository.get_event_definition(event_id)
	if event_definition.is_empty():
		return {"success": false, "message": "Unknown debug event id."}

	var trade_date: Dictionary = get_current_trade_date()
	var day_number: int = max(int(RunState.day_index), 1)
	var macro_state: Dictionary = get_current_macro_state()
	var generated_event: Dictionary = {}
	var event_family: String = str(event_definition.get("event_family", ""))

	if DEBUG_COMPANY_ARC_EVENT_IDS.has(event_id):
		var generated_arc: Dictionary = company_event_system.build_debug_company_arc(
			RunState,
			trade_date,
			day_number,
			macro_state,
			event_id
		)
		if generated_arc.is_empty():
			return {"success": false, "message": "Could not build that company arc right now."}

		var arc_start_event: Dictionary = company_event_system.build_arc_start_event(
			generated_arc,
			trade_date,
			day_number
		)
		RunState.debug_add_company_arc(generated_arc, arc_start_event)
		generated_event = arc_start_event
	elif event_family == "company":
		generated_event = company_event_system.build_debug_company_event(
			RunState,
			trade_date,
			day_number,
			macro_state,
			event_id
		)
		if generated_event.is_empty():
			return {"success": false, "message": "Could not find a company match for that event."}
		RunState.debug_add_recorded_event(generated_event)
	elif event_family == "person":
		generated_event = person_event_system.build_debug_person_event(
			RunState,
			trade_date,
			day_number,
			macro_state,
			_build_debug_sector_sentiments(),
			float(RunState.market_sentiment),
			event_id
		)
		if generated_event.is_empty():
			return {"success": false, "message": "Could not find a person-event target right now."}
		RunState.debug_add_recorded_event(generated_event)
	elif event_family == "special":
		generated_event = special_event_system.build_debug_special_event(
			RunState,
			trade_date,
			day_number,
			macro_state,
			event_id
		)
		if generated_event.is_empty():
			return {"success": false, "message": "Could not build that special event right now."}
		RunState.debug_add_special_event(generated_event)
	elif event_family == "market":
		generated_event = _build_debug_market_event(event_definition, trade_date)
		if generated_event.is_empty():
			return {"success": false, "message": "Could not build that market event right now."}
		RunState.debug_add_recorded_event(generated_event)
	else:
		return {"success": false, "message": "No debug generator is defined for that event family."}

	_invalidate_daily_activity_snapshot_cache()
	_invalidate_news_snapshot_cache()
	_request_autosave("debug_generate_event")
	return {
		"success": true,
		"message": _build_debug_generated_message(generated_event, event_definition),
		"event": generated_event
	}


func _build_news_feed_context(log_phase_details: bool = false, company_rows: Array = []) -> Dictionary:
	var phase_started_at_usec: int = Time.get_ticks_usec()
	var news_trade_date: Dictionary = get_current_trade_date()
	news_trade_date["day_index"] = RunState.day_index
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:trade_date", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var resolved_company_rows: Array = company_rows
	if resolved_company_rows.is_empty():
		resolved_company_rows = get_company_market_rows()
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:company_rows", phase_started_at_usec, " count=%d" % resolved_company_rows.size())
	phase_started_at_usec = Time.get_ticks_usec()
	var market_history: Array = get_market_history()
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:market_history", phase_started_at_usec, " count=%d" % market_history.size())
	phase_started_at_usec = Time.get_ticks_usec()
	var event_history: Array = get_event_history()
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:event_history", phase_started_at_usec, " count=%d" % event_history.size())
	phase_started_at_usec = Time.get_ticks_usec()
	var active_special_events: Array = get_active_special_events()
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:special_events", phase_started_at_usec, " count=%d" % active_special_events.size())
	phase_started_at_usec = Time.get_ticks_usec()
	var active_company_arcs: Array = get_active_company_arcs()
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:company_arcs", phase_started_at_usec, " count=%d" % active_company_arcs.size())
	return {
		"trade_date": news_trade_date,
		"company_rows": resolved_company_rows,
		"market_history": market_history,
		"event_history": event_history,
		"active_special_events": active_special_events,
		"active_company_arcs": active_company_arcs
	}


func _build_news_snapshot(unlocked_intel_level: int = -1, log_phase_details: bool = false, feed_context: Dictionary = {}) -> Dictionary:
	var phase_started_at_usec: int = Time.get_ticks_usec()
	if unlocked_intel_level < 1:
		unlocked_intel_level = get_unlocked_news_intel_level()
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:access", phase_started_at_usec)
	if not RunState.has_active_run():
		return {
			"intel_level": max(unlocked_intel_level, 1),
			"outlets": [],
			"feeds": {}
		}

	var resolved_feed_context: Dictionary = feed_context
	if resolved_feed_context.is_empty():
		resolved_feed_context = _build_news_feed_context(log_phase_details)
	phase_started_at_usec = Time.get_ticks_usec()
	var feed_data: Dictionary = DataRepository.get_news_feed_data()
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:feed_data", phase_started_at_usec)
	phase_started_at_usec = Time.get_ticks_usec()
	var news_snapshot: Dictionary = news_feed_system.build_news_snapshot(
		RunState,
		feed_data,
		resolved_feed_context.get("company_rows", []),
		resolved_feed_context.get("market_history", []),
		resolved_feed_context.get("event_history", []),
		resolved_feed_context.get("active_special_events", []),
		resolved_feed_context.get("active_company_arcs", []),
		resolved_feed_context.get("trade_date", {}),
		unlocked_intel_level
	)
	news_snapshot = _with_life_development_news_articles(news_snapshot)
	_log_advance_perf_elapsed(log_phase_details, "build_news_snapshot:feed_system", phase_started_at_usec)
	return news_snapshot


func get_news_snapshot(unlocked_intel_level: int = -1) -> Dictionary:
	if unlocked_intel_level < 1:
		unlocked_intel_level = get_unlocked_news_intel_level()
	var cache_key: String = _news_snapshot_cache_key(unlocked_intel_level)
	if (
		not news_snapshot_cache.is_empty()
		and str(news_snapshot_cache.get("cache_key", "")) == cache_key
		and news_snapshot_cache.has("snapshot")
	):
		return news_snapshot_cache.get("snapshot", {}).duplicate(true)
	var snapshot: Dictionary = _build_news_snapshot(unlocked_intel_level)
	_cache_news_snapshot(snapshot, unlocked_intel_level)
	RunState.record_news_snapshot(snapshot)
	return snapshot


func get_news_archive_years(outlet_id: String) -> Array:
	return RunState.get_news_archive_years(outlet_id)


func get_news_archive_months(outlet_id: String, year: int) -> Array:
	return RunState.get_news_archive_months(outlet_id, year)


func get_news_archive_article_summaries(outlet_id: String, year: int, month: int) -> Array:
	return RunState.get_news_archive_article_summaries(outlet_id, year, month)


func get_news_archive_article(article_id: String) -> Dictionary:
	return RunState.get_news_archive_article(article_id)


func _with_life_development_news_articles(snapshot: Dictionary) -> Dictionary:
	if not RunState.has_active_run() or snapshot.is_empty():
		return snapshot
	var feeds: Dictionary = snapshot.get("feeds", {}).duplicate(true)
	if feeds.is_empty():
		return snapshot
	for outlet_id_value in feeds.keys():
		var outlet_id: String = str(outlet_id_value)
		var feed: Dictionary = feeds.get(outlet_id, {}).duplicate(true)
		var articles: Array = feed.get("articles", []).duplicate(true)
		var additions: Array = _build_life_development_news_articles_for_feed(outlet_id, feed, articles)
		if additions.is_empty():
			continue
		articles.append_array(additions)
		articles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if float(a.get("priority", 0.0)) == float(b.get("priority", 0.0)):
				if int(a.get("day_index", -1)) == int(b.get("day_index", -1)):
					return str(a.get("headline", "")) < str(b.get("headline", ""))
				return int(a.get("day_index", -1)) > int(b.get("day_index", -1))
			return float(a.get("priority", 0.0)) > float(b.get("priority", 0.0))
		)
		feed["articles"] = articles
		feeds[outlet_id] = feed
	snapshot["feeds"] = feeds
	return snapshot


func _build_life_development_news_articles_for_feed(outlet_id: String, feed: Dictionary, source_articles: Array) -> Array:
	var additions: Array = []
	var seen_ids: Dictionary = {}
	for article_value in source_articles:
		if typeof(article_value) != TYPE_DICTIONARY:
			continue
		var article: Dictionary = article_value
		seen_ids[str(article.get("id", ""))] = true

	var outlet_level: int = clamp(int(feed.get("intel_level", 1)), 1, 4)
	var outlet_label: String = str(feed.get("outlet_label", "News"))
	for article_value in source_articles:
		if additions.size() >= 2 or typeof(article_value) != TYPE_DICTIONARY:
			continue
		var source_article: Dictionary = article_value
		if not _article_can_seed_life_development(source_article):
			continue
		var property_article: Dictionary = _build_life_development_news_article(outlet_id, outlet_label, outlet_level, source_article)
		var property_article_id: String = str(property_article.get("id", ""))
		if property_article_id.is_empty() or seen_ids.has(property_article_id):
			continue
		seen_ids[property_article_id] = true
		additions.append(property_article)
	return additions


func _build_life_development_news_article(outlet_id: String, outlet_label: String, outlet_level: int, source_article: Dictionary) -> Dictionary:
	var source_id: String = _life_development_news_source_id(source_article)
	var seed_value: String = "%s|%s|%s" % [
		source_id,
		str(source_article.get("headline", "")),
		str(source_article.get("target_sector_id", ""))
	]
	var location_id: String = _life_development_location_for_article(source_article, seed_value)
	var theme: String = _life_development_theme_for_article(source_article, seed_value)
	var intel_level: int = clamp(int(source_article.get("intel_level", outlet_level)), 1, 4)
	var reliability_by_level: Array = [0.0, 46.0, 56.0, 66.0, 76.0]
	var reliability: float = float(reliability_by_level[intel_level])
	var location_label: String = _life_location_label(location_id)
	var theme_label: String = _life_development_theme_label(theme)
	var visible_location_label: String = location_label if intel_level >= 2 else "Location not named"
	var visible_theme_label: String = theme_label if intel_level >= 3 else _life_development_low_clarity_theme_label(source_article, theme)
	var trade_date: Dictionary = source_article.get("trade_date", get_current_trade_date()).duplicate(true)
	var day_index: int = int(source_article.get("day_index", RunState.day_index))
	var article_id: String = "property_development|%s|%s|%d" % [
		outlet_id,
		_life_development_article_token(source_id),
		day_index
	]
	return {
		"id": article_id,
		"source_article_id": article_id,
		"property_development_source_article_id": source_id,
		"is_property_development_story": true,
		"outlet_id": outlet_id,
		"outlet_label": outlet_label,
		"intel_level": intel_level,
		"public_depth_level": 1,
		"access_model": "free_topic_coverage",
		"coverage_type": str(source_article.get("coverage_type", "market_wrap_chatter")),
		"topic_ids": ["market_wrap", "property_development", "sector"],
		"headline": _life_development_news_headline(intel_level, visible_location_label, visible_theme_label),
		"deck": _life_development_news_deck(intel_level, visible_location_label, visible_theme_label),
		"body": _life_development_news_body(source_article, location_id, theme, intel_level, reliability),
		"day_index": day_index,
		"trade_date": trade_date,
		"progress_label": "Developing",
		"category": "property_development",
		"tone": "mixed",
		"target_company_id": "",
		"target_ticker": "",
		"target_company_name": "",
		"target_sector_id": "property",
		"sector_name": "Property",
		"person_name": "",
		"event_family": "life_development",
		"source_chain_id": "",
		"chain_family": "",
		"meeting_id": "",
		"venue_type": "",
		"author_id": "property_desk",
		"author_name": "%s Property Desk" % outlet_label,
		"author_role": "Property Watch",
		"author_contact_id": str(source_article.get("author_contact_id", "")),
		"public_section_label": "Property Watch",
		"public_status_label": _life_development_clarity_label(intel_level),
		"outlet_logo_asset": str(source_article.get("outlet_logo_asset", "")),
		"author_portrait_asset": str(source_article.get("author_portrait_asset", "")),
		"article_image_asset": str(source_article.get("article_image_asset", "")),
		"image_slot": "brief",
		"public_story_angle": "Property development",
		"public_confidence_label": _life_development_news_confidence_label(reliability),
		"public_continuity_phrase": "Follow-up to earlier market coverage",
		"property_development_clarity": intel_level,
		"property_development_location_id": location_id,
		"property_development_theme": theme,
		"property_development_location_label": visible_location_label,
		"property_development_theme_label": visible_theme_label,
		"priority": 3.05 + (float(intel_level) * 0.08)
	}


func _life_development_news_headline(intel_level: int, location_label: String, theme_label: String) -> String:
	match clamp(intel_level, 1, 4):
		1:
			return "Property watch opens on possible site-demand catalyst"
		2:
			return "Property desk narrows site-demand watch to %s" % location_label
		3:
			return "%s property watch centers on %s" % [location_label, theme_label.to_lower()]
		_:
			return "%s development signals point to %s" % [theme_label, location_label]


func _life_development_news_deck(intel_level: int, location_label: String, theme_label: String) -> String:
	match clamp(intel_level, 1, 4):
		1:
			return "Early reporting points to possible site demand, but no city or sponsor has been confirmed."
		2:
			return "The likely area is clearer, while the sponsor and project scope still need confirmation."
		3:
			return "The article now points toward %s, with public confirmation still pending." % theme_label.to_lower()
		_:
			return "Public signals now link the development theme to %s, though formal filings still matter." % location_label


func _life_development_news_body(source_article: Dictionary, location_id: String, theme: String, intel_level: int, reliability: float) -> String:
	var note: String = _life_development_news_source_note(source_article, location_id, theme, intel_level)
	var location_label: String = _life_location_label(location_id)
	var theme_label: String = _life_development_theme_label(theme).to_lower()
	var sector_angle: String = _life_development_sector_angle(source_article, theme)
	var paragraphs: Array = [note]
	if intel_level <= 1:
		paragraphs.append("%s The location is not confirmed yet, but the possible %s angle could matter for nearby land, rentals, and small commercial space if it becomes public." % [sector_angle, theme_label])
	elif intel_level == 2:
		paragraphs.append("%s The working area is %s, but the market still needs a project name, sponsor, and filing trail before treating it as investable property news." % [sector_angle, location_label])
	else:
		paragraphs.append("%s The reported angle is a possible %s around %s. Confirmation would matter most to properties with direct exposure to that location." % [sector_angle, theme_label, location_label])
	paragraphs.append(_life_development_news_reliability_sentence(reliability))
	return "\n\n".join(paragraphs)


func _life_development_news_confidence_label(reliability: float) -> String:
	if reliability >= 70.0:
		return "Public signals building"
	if reliability >= 56.0:
		return "Reporting active"
	return "Early report"


func _life_development_news_reliability_sentence(reliability: float) -> String:
	if reliability >= 70.0:
		return "The story will matter more if it is followed by permits, land filings, or an official announcement."
	if reliability >= 56.0:
		return "The next useful proof would be a named sponsor, a clearer site, or formal paperwork."
	return "For now, this is a reported story rather than a confirmed development."


func _life_development_article_token(value: String) -> String:
	var token: String = value.to_lower()
	var cleaned: String = ""
	for index in range(token.length()):
		var character: String = token.substr(index, 1)
		var code: int = character.unicode_at(0)
		if (code >= 48 and code <= 57) or (code >= 97 and code <= 122):
			cleaned += character
		else:
			cleaned += "_"
	while cleaned.contains("__"):
		cleaned = cleaned.replace("__", "_")
	cleaned = cleaned.strip_edges().trim_prefix("_").trim_suffix("_")
	if cleaned.is_empty():
		cleaned = "article"
	return cleaned.left(64)


func get_twooter_snapshot(unlocked_access_tier: int = -1) -> Dictionary:
	if unlocked_access_tier < 1:
		unlocked_access_tier = get_unlocked_twooter_access_tier()
	if not RunState.has_active_run():
		return {
			"access_tier": max(unlocked_access_tier, 1),
			"tier_label": "Public chatter",
			"accounts": [],
			"posts": [],
			"message_threads": [],
			"shareable_theses": [],
			"trending_rows": [],
			"who_to_follow": []
		}

	var snapshot: Dictionary = _build_twooter_base_snapshot(unlocked_access_tier)
	return twooter_interaction_system.enhance_snapshot(
		snapshot,
		RunState.get_twooter_social_state(),
		DataRepository.get_twooter_feed_data(),
		RunState.get_player_theses(),
		RunState.get_daily_action_snapshot(),
		RunState.day_index
	)


func interact_with_twooter_post(post_id: String, action_id: String, thesis_id: String = "", player_reply_text: String = "", option_id: String = "") -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "Start a run before using Twooter."}
	var snapshot: Dictionary = get_twooter_snapshot()
	var validation: Dictionary = twooter_interaction_system.validate_post_interaction(RunState, snapshot, post_id, action_id, thesis_id)
	if not bool(validation.get("success", false)):
		return validation
	var spent_ap: bool = false
	var spend_result: Dictionary = {}
	if twooter_interaction_system.is_private_action(action_id):
		var block_reason: String = get_life_action_block_reason("twooter_%s" % action_id)
		if not block_reason.is_empty():
			return {"success": false, "message": block_reason, "snapshot": RunState.get_daily_action_snapshot()}
		if not RunState.can_spend_daily_action(1):
			return {"success": false, "message": "Need 1 AP for that Twooter message.", "snapshot": RunState.get_daily_action_snapshot()}
		spend_result = RunState.spend_daily_action(1)
		if not bool(spend_result.get("success", false)):
			return spend_result
		spent_ap = true
	var result: Dictionary = twooter_interaction_system.apply_post_interaction(
		RunState,
		DataRepository.get_twooter_feed_data(),
		snapshot,
		post_id,
		action_id,
		thesis_id,
		player_reply_text,
		option_id
	)
	if not bool(result.get("success", false)):
		if spent_ap:
			RunState.refund_daily_action(1)
			daily_actions_changed.emit()
		return result
	_after_twooter_interaction(spent_ap, bool(result.get("network_changed", false)), "twooter_post_interaction")
	result["snapshot"] = get_twooter_snapshot()
	return result


func send_twooter_message(account_id: String, action_id: String, thesis_id: String = "", player_message_text: String = "", option_id: String = "") -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "Start a run before using Twooter."}
	var snapshot: Dictionary = get_twooter_snapshot()
	var validation: Dictionary = twooter_interaction_system.validate_account_action(snapshot, account_id, action_id, thesis_id)
	if not bool(validation.get("success", false)):
		return validation
	if not twooter_interaction_system.is_private_action(action_id):
		return {"success": false, "message": "Use public Twooter actions from the Home feed."}
	var block_reason: String = get_life_action_block_reason("twooter_%s" % action_id)
	if not block_reason.is_empty():
		return {"success": false, "message": block_reason, "snapshot": RunState.get_daily_action_snapshot()}
	if not RunState.can_spend_daily_action(1):
		return {"success": false, "message": "Need 1 AP for that Twooter message.", "snapshot": RunState.get_daily_action_snapshot()}
	var spend_result: Dictionary = RunState.spend_daily_action(1)
	if not bool(spend_result.get("success", false)):
		return spend_result
	var result: Dictionary = twooter_interaction_system.apply_message_action(
		RunState,
		DataRepository.get_twooter_feed_data(),
		snapshot,
		account_id,
		action_id,
		thesis_id,
		player_message_text,
		option_id
	)
	if not bool(result.get("success", false)):
		RunState.refund_daily_action(1)
		daily_actions_changed.emit()
		return result
	_after_twooter_interaction(true, bool(result.get("network_changed", false)), "twooter_message")
	result["snapshot"] = get_twooter_snapshot()
	return result


func follow_twooter_account(account_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "Start a run before using Twooter."}
	var result: Dictionary = twooter_interaction_system.apply_follow_account(RunState, get_twooter_snapshot(), account_id)
	if bool(result.get("success", false)):
		_after_twooter_interaction(false, bool(result.get("network_changed", false)), "twooter_follow")
		result["snapshot"] = get_twooter_snapshot()
	return result


func like_twooter_post(post_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "Start a run before using Twooter."}
	var result: Dictionary = twooter_interaction_system.apply_like_post(RunState, get_twooter_snapshot(), post_id)
	if bool(result.get("success", false)):
		_after_twooter_interaction(false, bool(result.get("network_changed", false)), "twooter_like")
		result["snapshot"] = get_twooter_snapshot()
	return result


func get_twooter_message_thread(account_id: String) -> Dictionary:
	if not RunState.has_active_run():
		return {"account": {}, "rows": []}
	var snapshot: Dictionary = get_twooter_snapshot()
	return twooter_interaction_system.get_message_thread(
		RunState.get_twooter_social_state(),
		snapshot.get("accounts", []),
		account_id,
		RunState.day_index,
		snapshot.get("shareable_theses", []),
		DataRepository.get_twooter_feed_data(),
		RunState.get_daily_action_snapshot()
	)


func _build_twooter_base_snapshot(unlocked_access_tier: int = -1) -> Dictionary:
	if unlocked_access_tier < 1:
		unlocked_access_tier = get_unlocked_twooter_access_tier()
	var social_trade_date: Dictionary = get_current_trade_date()
	social_trade_date["day_index"] = RunState.day_index

	var snapshot: Dictionary = twooter_feed_system.build_social_snapshot(
		RunState,
		DataRepository.get_twooter_feed_data(),
		get_company_rows(),
		get_market_history(),
		get_event_history(),
		get_active_special_events(),
		get_active_company_arcs(),
		social_trade_date,
		unlocked_access_tier
	)
	snapshot["accounts"] = _merge_network_twooter_accounts(snapshot.get("accounts", []))
	_annotate_twooter_account_post_counts(snapshot)
	return snapshot


func _merge_network_twooter_accounts(accounts: Array) -> Array:
	var rows: Array = []
	var seen: Dictionary = {}
	for account_value in accounts:
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value.duplicate(true)
		var account_id: String = str(account.get("id", ""))
		if account_id.is_empty() or seen.has(account_id):
			continue
		seen[account_id] = true
		rows.append(account)
	for account_value in contact_network_system.build_twooter_accounts(RunState, DataRepository):
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value.duplicate(true)
		var account_id: String = str(account.get("id", ""))
		if account_id.is_empty() or seen.has(account_id):
			continue
		account["unlocked"] = true
		seen[account_id] = true
		rows.append(account)
	return rows


func _annotate_twooter_account_post_counts(snapshot: Dictionary) -> void:
	var post_counts: Dictionary = {}
	for post_value in snapshot.get("posts", []):
		if typeof(post_value) != TYPE_DICTIONARY:
			continue
		var account_id: String = str(post_value.get("account_id", ""))
		if account_id.is_empty():
			continue
		post_counts[account_id] = int(post_counts.get(account_id, 0)) + 1
	var accounts: Array = []
	for account_value in snapshot.get("accounts", []):
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value.duplicate(true)
		var account_id: String = str(account.get("id", ""))
		var post_count: int = int(post_counts.get(account_id, 0))
		account["public_post_count"] = post_count
		account["has_public_posts"] = post_count > 0
		accounts.append(account)
	snapshot["accounts"] = accounts


func _after_twooter_interaction(spent_ap: bool, changed_network: bool, autosave_reason: String) -> void:
	_invalidate_daily_activity_snapshot_cache()
	_request_autosave(autosave_reason)
	social_changed.emit()
	if spent_ap:
		daily_actions_changed.emit()
	if changed_network:
		network_changed.emit()


func get_thesis_board_snapshot() -> Dictionary:
	return ThesisManager.get_thesis_board_snapshot(self)


func get_research_tray_snapshot(company_id: String = "") -> Dictionary:
	return ThesisManager.get_research_tray_snapshot(self, company_id)


func capture_research_evidence(payload: Dictionary) -> Dictionary:
	return ThesisManager.capture_research_evidence(self, payload)


func attach_research_evidence_to_thesis(thesis_id: String, evidence_id: String, interpretation: String = "watch", note: String = "") -> Dictionary:
	return ThesisManager.attach_research_evidence_to_thesis(self, thesis_id, evidence_id, interpretation, note)


func update_thesis_evidence_interpretation(thesis_id: String, evidence_id: String, fields: Dictionary = {}) -> Dictionary:
	return ThesisManager.update_thesis_evidence_interpretation(self, thesis_id, evidence_id, fields)


func get_thesis_evidence_options(company_id: String) -> Dictionary:
	return ThesisManager.get_thesis_evidence_options(self, company_id)


func get_company_story_dossier_evidence_options(company_id: String) -> Array:
	return ThesisManager.get_company_story_dossier_evidence_options(self, company_id)


func get_commodity_macro_summary(sector_id: String = "") -> Dictionary:
	return commodity_macro_contract.build_summary(get_current_macro_state(), sector_id)


func get_commodity_macro_evidence_options(company_id: String = "", sector_id: String = "") -> Array:
	var context: Dictionary = {}
	var normalized_company_id: String = company_id.strip_edges()
	if not normalized_company_id.is_empty():
		context = get_company_snapshot(normalized_company_id, true, true, true)
		var definition: Dictionary = RunState.get_effective_company_definition(normalized_company_id, false, false)
		context["company_id"] = normalized_company_id
		if str(context.get("sector_id", "")).strip_edges().is_empty():
			context["sector_id"] = str(definition.get("sector_id", ""))
		if typeof(context.get("commodity_exposures", {})) != TYPE_DICTIONARY or context.get("commodity_exposures", {}).is_empty():
			context["commodity_exposures"] = definition.get("commodity_exposures", {}).duplicate(true)
	elif not sector_id.strip_edges().is_empty():
		context["sector_id"] = sector_id.strip_edges()
	return commodity_macro_contract.build_evidence_rows(get_current_macro_state(), context)


func get_chart_pattern_catalog() -> Array:
	return chart_pattern_system.get_pattern_catalog()


func get_open_theses_for_company(company_id: String) -> Array:
	return ThesisManager.get_open_theses_for_company(company_id)


func evaluate_chart_pattern_claim(
	company_id: String,
	range_id: String,
	pattern_id: String,
	start_anchor: Dictionary,
	end_anchor: Dictionary
) -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	var company: Dictionary = get_company_snapshot(company_id, false, false, false)
	if company.is_empty():
		return {"success": false, "message": "Unknown company selection."}
	var chart_snapshot: Dictionary = get_company_chart_snapshot(company_id, range_id, [])
	if chart_snapshot.is_empty():
		return {"success": false, "message": "Chart history is not ready yet."}
	var result: Dictionary = chart_pattern_system.evaluate_pattern_claim({
		"company_id": str(company_id),
		"ticker": str(company.get("ticker", company_id.to_upper())),
		"range_id": str(chart_snapshot.get("range_id", range_id)),
		"range_label": str(chart_snapshot.get("range_label", get_chart_range_label(range_id))),
		"pattern_id": pattern_id,
		"start_anchor": start_anchor.duplicate(true),
		"end_anchor": end_anchor.duplicate(true),
		"bars": chart_snapshot.get("bars", []).duplicate(true),
		"current_price": float(company.get("current_price", 0.0)),
		"trade_date": get_current_trade_date()
	})
	if bool(result.get("success", false)):
		_record_steam_progress_event("chart_pattern_claimed", {
			"company_id": company_id,
			"range_id": range_id,
			"pattern_id": pattern_id
		})
	return result


func add_chart_pattern_evidence_to_thesis(thesis_id: String, claim: Dictionary) -> Dictionary:
	return ThesisManager.add_chart_pattern_evidence_to_thesis(self, thesis_id, claim)


func create_thesis(company_id: String, stance: String, horizon: String, title: String = "") -> Dictionary:
	return ThesisManager.create_thesis(self, company_id, stance, horizon, title)


func update_thesis_meta(thesis_id: String, fields: Dictionary) -> Dictionary:
	return ThesisManager.update_thesis_meta(self, thesis_id, fields)


func add_thesis_evidence(thesis_id: String, evidence: Dictionary) -> Dictionary:
	return ThesisManager.add_thesis_evidence(self, thesis_id, evidence)


func remove_thesis_evidence(thesis_id: String, evidence_id: String) -> Dictionary:
	return ThesisManager.remove_thesis_evidence(self, thesis_id, evidence_id)


func generate_thesis_report(thesis_id: String) -> Dictionary:
	return ThesisManager.generate_thesis_report(self, thesis_id)


func refresh_thesis_review(thesis_id: String) -> Dictionary:
	return ThesisManager.refresh_thesis_review(self, thesis_id)


func close_thesis(thesis_id: String) -> Dictionary:
	return ThesisManager.close_thesis(self, thesis_id)




func get_difficulty_options() -> Array:
	var options: Array = []

	for difficulty_id in DIFFICULTY_ORDER:
		options.append(get_difficulty_config(str(difficulty_id)))

	return options


func build_company_roster(run_seed: int, selected_difficulty_config: Dictionary) -> Array:
	var started_at_usec: int = Time.get_ticks_usec()
	var difficulty_config: Dictionary = selected_difficulty_config.duplicate(true)
	if difficulty_config.is_empty():
		difficulty_config = get_difficulty_config(DEFAULT_DIFFICULTY_ID)

	var company_count: int = int(difficulty_config.get("company_count", DataRepository.get_company_archetypes().size()))
	var base_macro_state: Dictionary = macro_state_system.build_year_state(
		run_seed,
		2020,
		DataRepository.get_sector_definitions(),
		{},
		DataRepository.get_commodity_indicator_catalog()
	)
	var generated_roster: Array = []
	if bool(difficulty_config.get("use_company_universe_catalog", false)):
		var catalog_validation: Dictionary = DataRepository.get_company_universe_validation_result()
		if bool(catalog_validation.get("valid", false)):
			generated_roster = company_roster_generator.generate_catalog_roster(
				DataRepository.get_company_universe_companies(),
				DataRepository.get_company_archetypes(),
				DataRepository.get_sector_definitions(),
				run_seed,
				company_count,
				base_macro_state
			)
			if generated_roster.size() != company_count:
				push_warning("Company universe catalog roster requested %d companies but produced %d; falling back to procedural roster." % [
					company_count,
					generated_roster.size()
				])
				generated_roster = []
		else:
			push_warning("Company universe catalog validation failed; falling back to procedural roster. issues=%s" % JSON.stringify(catalog_validation.get("issues", [])))
	if generated_roster.is_empty():
		generated_roster = company_roster_generator.generate_roster(
			DataRepository.get_company_archetypes(),
			DataRepository.get_sector_definitions(),
			DataRepository.get_company_word_data(),
			run_seed,
			company_count,
			base_macro_state
		)
	_log_startup_perf_elapsed("build_company_roster", started_at_usec, " companies=%d" % generated_roster.size())
	return generated_roster


func get_difficulty_config(difficulty_id: String) -> Dictionary:
	var normalized_id: String = difficulty_id.to_lower()
	if not DIFFICULTY_PRESETS.has(normalized_id):
		normalized_id = DEFAULT_DIFFICULTY_ID

	return DIFFICULTY_PRESETS[normalized_id].duplicate(true)


func get_current_difficulty_config() -> Dictionary:
	return RunState.get_difficulty_config()


func get_current_difficulty_label() -> String:
	var current_config: Dictionary = get_current_difficulty_config()
	if current_config.is_empty():
		current_config = get_difficulty_config(DEFAULT_DIFFICULTY_ID)

	return str(current_config.get("label", "Normal"))


func get_current_trade_date() -> Dictionary:
	return RunState.get_current_trade_date()


func get_current_macro_state() -> Dictionary:
	return RunState.get_current_macro_state()


func get_macro_state_history() -> Array:
	return RunState.get_macro_state_history()


func get_next_trade_date() -> Dictionary:
	return RunState.get_next_trade_date()


func format_trade_date(date_info: Dictionary) -> String:
	return trading_calendar.format_date(date_info)


func _format_currency(value: float) -> String:
	return UIFormatter.format_currency(value)


func _format_decimal(value: float, decimal_places: int = 2, use_grouping: bool = true) -> String:
	return UIFormatter.format_decimal(value, decimal_places, use_grouping)


func _format_grouped_integer(value: int) -> String:
	return UIFormatter.format_grouped_integer(value)


func _format_currency_compact(value: float) -> String:
	return UIFormatter.format_currency_compact(value)


func should_show_tutorial() -> bool:
	return RunState.should_show_tutorial()


func mark_tutorial_shown() -> void:
	RunState.mark_tutorial_shown()
	_request_autosave("tutorial_shown")


func get_ftue_snapshot() -> Dictionary:
	return RunState.get_ftue_snapshot()


func advance_ftue_step(step_id: String = "") -> bool:
	var advanced: bool = RunState.advance_ftue_step(step_id)
	if advanced:
		_request_autosave("ftue_advance")
	return advanced


func skip_ftue() -> bool:
	var skipped: bool = RunState.skip_ftue()
	if skipped:
		_request_autosave("ftue_skip")
	return skipped


func mark_ftue_completed() -> bool:
	var completed: bool = RunState.mark_ftue_completed()
	if completed:
		_request_autosave("ftue_completed")
	return completed


func get_guide_snapshot() -> Dictionary:
	var snapshot: Dictionary = RunState.get_guide_snapshot()
	var anchor_company_id: String = str(snapshot.get("anchor_company_id", ""))
	if not anchor_company_id.is_empty():
		var definition: Dictionary = RunState.get_effective_company_definition(anchor_company_id, false, false)
		snapshot["anchor_ticker"] = str(definition.get("ticker", anchor_company_id.to_upper()))
		snapshot["anchor_company_name"] = str(definition.get("name", anchor_company_id.to_upper()))
	else:
		snapshot["anchor_ticker"] = ""
		snapshot["anchor_company_name"] = ""
	if not str(snapshot.get("seeded_meeting_id", "")).is_empty():
		snapshot["seeded_meeting"] = get_corporate_meeting_detail(str(snapshot.get("seeded_meeting_id", "")))
	return snapshot


func start_guide_flow(flow_id: String) -> bool:
	var started: bool = RunState.start_guide_flow(flow_id)
	if started:
		_request_autosave("guide_start_%s" % flow_id)
	return started


func advance_guide_step(flow_id: String = "", step_id: String = "") -> bool:
	var advanced: bool = RunState.advance_guide_step(flow_id, step_id)
	if advanced:
		_request_autosave("guide_advance")
	return advanced


func skip_guide_flow(flow_id: String = "") -> bool:
	var skipped: bool = RunState.skip_guide_flow(flow_id)
	if skipped:
		_request_autosave("guide_skip")
	return skipped


func complete_guide_flow(flow_id: String = "") -> bool:
	var completed: bool = RunState.complete_guide_flow(flow_id)
	if completed:
		_request_autosave("guide_complete")
	return completed


func dismiss_guide_prompt(flow_id: String) -> bool:
	var dismissed: bool = RunState.dismiss_guide_prompt(flow_id)
	if dismissed:
		_request_autosave("guide_prompt_dismiss")
	return dismissed


func get_available_guide_flows() -> Array:
	return RunState.get_available_guide_flows()


func get_contextual_guide_prompt(context_id: String) -> Dictionary:
	return RunState.get_contextual_guide_prompt(context_id)


func should_show_first_hour_guide() -> bool:
	return RunState.should_show_first_hour_guide()


func get_first_hour_guide_snapshot() -> Dictionary:
	var snapshot: Dictionary = RunState.get_first_hour_guide_snapshot()
	var anchor_company_id: String = str(snapshot.get("anchor_company_id", ""))
	if not anchor_company_id.is_empty():
		var definition: Dictionary = RunState.get_effective_company_definition(anchor_company_id, false, false)
		snapshot["anchor_ticker"] = str(definition.get("ticker", anchor_company_id.to_upper()))
		snapshot["anchor_company_name"] = str(definition.get("name", anchor_company_id.to_upper()))
	else:
		snapshot["anchor_ticker"] = ""
		snapshot["anchor_company_name"] = ""
	if not str(snapshot.get("seeded_meeting_id", "")).is_empty():
		var detail: Dictionary = get_corporate_meeting_detail(str(snapshot.get("seeded_meeting_id", "")))
		snapshot["seeded_meeting"] = detail
	return snapshot


func advance_first_hour_guide_step(step_id: String = "") -> bool:
	var advanced: bool = RunState.advance_first_hour_guide_step(step_id)
	if advanced:
		_request_autosave("first_hour_guide_advance")
	return advanced


func skip_first_hour_guide() -> bool:
	var skipped: bool = RunState.skip_first_hour_guide()
	if skipped:
		_request_autosave("first_hour_guide_skip")
	return skipped


func mark_first_hour_guide_completed() -> bool:
	var completed: bool = RunState.mark_first_hour_guide_completed()
	if completed:
		_request_autosave("first_hour_guide_completed")
	return completed


func ensure_first_hour_guide_hook() -> Dictionary:
	if not RunState.has_active_run():
		return {"success": false, "message": "No active run."}
	if not RunState.should_show_first_hour_guide():
		return {"success": false, "message": "Guided First Week is not active."}
	var snapshot: Dictionary = RunState.get_first_hour_guide_snapshot()
	if str(snapshot.get("current_step_id", "")) != "seeded_rupslb":
		return {"success": false, "message": "The guided RUPSLB hook is not due yet."}

	var existing_meeting_id: String = str(snapshot.get("seeded_meeting_id", "")).strip_edges()
	var existing_chain_id: String = str(snapshot.get("seeded_chain_id", "")).strip_edges()
	if not existing_meeting_id.is_empty() and not get_corporate_meeting_detail(existing_meeting_id).is_empty():
		return {
			"success": true,
			"message": "Guided RUPSLB already scheduled.",
			"meeting": get_corporate_meeting_detail(existing_meeting_id),
			"chain": RunState.get_active_corporate_action_chains().get(existing_chain_id, {}).duplicate(true)
		}

	var company_id: String = _eligible_first_hour_guide_company_id(str(snapshot.get("anchor_company_id", "")))
	if company_id.is_empty():
		return {
			"success": false,
			"blocked": true,
			"message": "Buy or hold one stock to unlock the first event."
		}
	if RunState.set_first_hour_guide_anchor_company_id(company_id):
		_request_autosave("first_hour_guide_anchor")

	corporate_action_system.ensure_initialized(RunState, DataRepository)
	var result: Dictionary = corporate_action_system.schedule_guided_first_hour_stock_split_rupslb(
		RunState,
		DataRepository,
		company_id
	)
	if result.is_empty():
		return {
			"success": false,
			"blocked": true,
			"message": "A live corporate action is already using that stock. Hold another stock to unlock the first event."
		}

	var chain: Dictionary = result.get("chain", {}).duplicate(true)
	var meeting: Dictionary = result.get("meeting", {}).duplicate(true)
	RunState.set_first_hour_guide_seeded_hook(str(chain.get("chain_id", "")), str(meeting.get("id", "")))
	_invalidate_dashboard_event_snapshot_cache()
	_request_autosave("first_hour_guide_seeded_rupslb")
	return {
		"success": true,
		"message": "Guided stock-split RUPSLB scheduled for %s." % str(meeting.get("ticker", company_id.to_upper())),
		"chain": chain,
		"meeting": meeting
	}


func _eligible_first_hour_guide_company_id(preferred_company_id: String = "") -> String:
	var preferred_id: String = preferred_company_id.strip_edges()
	if _is_first_hour_guide_company_eligible(preferred_id):
		return preferred_id
	var holdings: Dictionary = RunState.player_portfolio.get("holdings", {})
	var candidates: Array = []
	for company_id_value in holdings.keys():
		var company_id: String = str(company_id_value)
		if _is_first_hour_guide_company_eligible(company_id):
			candidates.append(company_id)
	candidates.sort()
	return str(candidates[0]) if not candidates.is_empty() else ""


func _is_first_hour_guide_company_eligible(company_id: String) -> bool:
	if company_id.is_empty() or RunState.get_company(company_id).is_empty():
		return false
	if int(RunState.get_holding(company_id).get("shares", 0)) < get_lot_size():
		return false
	return not bool(get_company_corporate_action_snapshot(company_id).get("has_live_chain", false))


func get_lot_size() -> int:
	return int(RunState.LOT_SIZE)


func get_buy_fee_rate() -> float:
	return RunState.get_effective_buy_fee_rate()


func get_sell_fee_rate() -> float:
	return RunState.get_effective_sell_fee_rate()


func lots_to_shares(lots: int) -> int:
	return max(lots, 0) * get_lot_size()


func get_tick_size_for_price(price: float) -> float:
	return IDX_PRICE_RULES.tick_size_for_reference_price(price)


func get_chart_range_label(range_id: String) -> String:
	return chart_system.get_range_label(range_id)


func get_chart_indicator_catalog() -> Array:
	var unlocked_lookup: Dictionary = {}
	for indicator_id_value in get_unlocked_chart_indicator_ids():
		unlocked_lookup[str(indicator_id_value)] = true
	var catalog: Array = []
	for indicator_value in chart_system.get_indicator_catalog():
		var indicator: Dictionary = indicator_value
		var indicator_id: String = str(indicator.get("id", ""))
		indicator["unlocked"] = unlocked_lookup.has(indicator_id)
		catalog.append(indicator)
	return catalog


func _upgrade_track(track_id: String) -> Dictionary:
	for track_value in DataRepository.get_upgrade_catalog().get("tracks", []):
		if typeof(track_value) != TYPE_DICTIONARY:
			continue
		var track: Dictionary = track_value
		if str(track.get("id", "")) == track_id:
			return track.duplicate(true)
	return {}


func _upgrade_tier_data(track: Dictionary, tier: int) -> Dictionary:
	if track.is_empty() or tier < 1:
		return {}
	var tiers: Dictionary = track.get("tiers", {})
	return tiers.get(str(tier), {}).duplicate(true)


func _content_level_for_upgrade(track_id: String) -> int:
	var track: Dictionary = _upgrade_track(track_id)
	var tier_data: Dictionary = _upgrade_tier_data(track, RunState.get_upgrade_tier(track_id))
	if tier_data.has("content_level"):
		return int(tier_data.get("content_level", 1))
	return clamp(5 - RunState.get_upgrade_tier(track_id), 1, 4)


func _build_debug_sector_sentiments() -> Dictionary:
	var sector_sentiments: Dictionary = {}
	for sector_row_value in get_sector_rows():
		var sector_row: Dictionary = sector_row_value
		sector_sentiments[str(sector_row.get("id", ""))] = float(sector_row.get("average_change_pct", 0.0))

	if sector_sentiments.is_empty():
		for sector_definition_value in DataRepository.get_sector_definitions():
			var sector_definition: Dictionary = sector_definition_value
			sector_sentiments[str(sector_definition.get("id", ""))] = float(sector_definition.get("trend_bias", 0.0))

	return sector_sentiments


func _build_debug_market_event(event_definition: Dictionary, trade_date: Dictionary) -> Dictionary:
	var event_id: String = str(event_definition.get("id", ""))
	if event_id.is_empty():
		return {}

	var event_data: Dictionary = {
		"event_id": event_id,
		"scope": str(event_definition.get("scope", "market")),
		"event_family": str(event_definition.get("event_family", "market")),
		"category": str(event_definition.get("category", "market")),
		"tone": str(event_definition.get("tone", "mixed")),
		"duration_days": int(event_definition.get("duration_days", 1)),
		"trade_date": trade_date.duplicate(true),
		"sentiment_shift": float(event_definition.get("sentiment_shift", 0.0)),
		"description": str(event_definition.get("description", "")),
		"broker_bias": str(event_definition.get("broker_bias", "balanced"))
	}

	if str(event_definition.get("scope", "market")) == "market":
		event_data["headline"] = "Risk-off pressure hits the tape"
		event_data["headline_detail"] = "A manually injected market headline pushes traders into defense mode."
		return event_data

	var sector_sentiments: Dictionary = _build_debug_sector_sentiments()
	var target_sector_id: String = _pick_debug_market_sector(event_id, sector_sentiments)
	if target_sector_id.is_empty():
		return {}

	var sector_definition: Dictionary = DataRepository.get_sector_definition(target_sector_id)
	var sector_name: String = str(sector_definition.get("name", target_sector_id.capitalize()))
	event_data["target_sector_id"] = target_sector_id
	if event_id == "sector_tailwind":
		event_data["headline"] = "%s catches a sector tailwind" % sector_name
		event_data["headline_detail"] = "A fresh wave of buyers rotates into %s and keeps the tape constructive." % sector_name
	else:
		event_data["headline"] = "%s runs into a sector headwind" % sector_name
		event_data["headline_detail"] = "Sellers lean on %s as the sector tone rolls over." % sector_name

	return event_data


func _pick_debug_market_sector(event_id: String, sector_sentiments: Dictionary) -> String:
	var selected_sector_id: String = ""
	var selected_value: float = -INF if event_id == "sector_tailwind" else INF

	for sector_id_value in sector_sentiments.keys():
		var sector_id: String = str(sector_id_value)
		var sentiment_value: float = float(sector_sentiments.get(sector_id, 0.0))
		if event_id == "sector_tailwind":
			if sentiment_value > selected_value:
				selected_value = sentiment_value
				selected_sector_id = sector_id
		elif sentiment_value < selected_value:
			selected_value = sentiment_value
			selected_sector_id = sector_id

	if not selected_sector_id.is_empty():
		return selected_sector_id

	for sector_definition_value in DataRepository.get_sector_definitions():
		return str(sector_definition_value.get("id", ""))
	return ""


func _build_debug_generated_message(event_data: Dictionary, event_definition: Dictionary) -> String:
	var event_label: String = _format_debug_event_label(str(event_definition.get("id", "")))
	var target_ticker: String = str(event_data.get("target_ticker", ""))
	if not target_ticker.is_empty():
		return "%s generated for %s." % [event_label, target_ticker]

	var person_name: String = str(event_data.get("person_name", ""))
	if not person_name.is_empty():
		return "%s generated from %s." % [event_label, person_name]

	var target_sector_id: String = str(event_data.get("target_sector_id", ""))
	if not target_sector_id.is_empty():
		var sector_definition: Dictionary = DataRepository.get_sector_definition(target_sector_id)
		return "%s generated for %s." % [event_label, str(sector_definition.get("name", target_sector_id.capitalize()))]

	return "%s generated." % event_label


func _format_debug_event_label(event_id: String) -> String:
	var words: Array = event_id.split("_", false)
	for index in range(words.size()):
		words[index] = str(words[index]).capitalize()
	return " ".join(words)


func _emit_run_loading_step(step_index: int) -> void:
	_emit_loading_step_from_list(NEW_RUN_LOADING_STEPS, step_index)


func _on_new_run_financial_batch_progress(done_count: int, total_count: int) -> void:
	if total_count <= 0:
		_emit_run_loading_step_with_progress(2, 1.0)
		return
	_emit_run_loading_step_with_progress(2, float(done_count) / float(total_count))


func _steam_progress_manager() -> Node:
	return get_node_or_null("/root/SteamProgressManager")


func _reset_steam_progress_for_active_run() -> void:
	var progress_manager: Node = _steam_progress_manager()
	if progress_manager != null and progress_manager.has_method("reset_for_active_run"):
		progress_manager.call("reset_for_active_run")


func _sync_steam_progress_from_run_state() -> void:
	var progress_manager: Node = _steam_progress_manager()
	if progress_manager != null and progress_manager.has_method("sync_from_run_state"):
		progress_manager.call("sync_from_run_state", true, true)


func _record_steam_progress_event(event_id: String, payload: Dictionary = {}, count: int = 1) -> void:
	var progress_manager: Node = _steam_progress_manager()
	if progress_manager != null and progress_manager.has_method("record_event"):
		progress_manager.call("record_event", event_id, payload, count)


func _record_steam_trade_progress(company_id: String, side: String) -> void:
	var progress_manager: Node = _steam_progress_manager()
	if progress_manager == null or not progress_manager.has_method("record_trade"):
		return
	if RunState.trade_history.is_empty():
		return
	var latest_trade: Dictionary = RunState.trade_history[RunState.trade_history.size() - 1]
	if str(latest_trade.get("company_id", "")) != company_id or str(latest_trade.get("side", "")) != side:
		return
	progress_manager.call("record_trade", latest_trade.duplicate(true), get_company_ownership_snapshot(company_id))


func _record_steam_day_advanced() -> void:
	var progress_manager: Node = _steam_progress_manager()
	if progress_manager != null and progress_manager.has_method("record_day_advanced"):
		progress_manager.call("record_day_advanced", {})


func _academy_section_was_read(category_id: String, section_id: String) -> bool:
	var read_sections: Dictionary = RunState.get_academy_progress().get("read_sections", {})
	var read_list: Array = read_sections.get(category_id, [])
	return read_list.has(section_id)


func _on_new_run_financial_batch_detail(done_count: int, total_count: int, batch_company_ids: Array) -> void:
	var subprogress_text: String = "%d / %d companies prepared" % [done_count, max(total_count, 0)]
	for company_id_value in batch_company_ids:
		var company_id: String = str(company_id_value)
		if company_id.is_empty():
			continue
		var definition: Dictionary = RunState.get_effective_company_definition(company_id, false, false)
		var ticker: String = str(definition.get("ticker", company_id.to_upper()))
		loading_detail_log_lines.append("Built core profile for %s" % ticker)
	while loading_detail_log_lines.size() > 3:
		loading_detail_log_lines.remove_at(0)
	_emit_run_loading_detail(subprogress_text, loading_detail_log_lines)


func _hold_loading_stage(duration_seconds: float) -> void:
	if duration_seconds <= 0.0:
		await get_tree().process_frame
		return

	await get_tree().create_timer(duration_seconds).timeout


func _emit_load_run_loading_step(step_index: int) -> void:
	_emit_loading_step_from_list(LOAD_RUN_LOADING_STEPS, step_index)


func _emit_run_loading_step_with_progress(step_index: int, stage_progress_ratio: float) -> void:
	_emit_loading_step_from_list(NEW_RUN_LOADING_STEPS, step_index, stage_progress_ratio)


func _emit_run_loading_detail(subprogress_text: String, log_lines: Array) -> void:
	run_loading_detail_updated.emit(subprogress_text, log_lines.duplicate())


func _emit_loading_step_from_list(steps: Array, step_index: int, stage_progress_ratio: float = 0.0) -> void:
	if steps.is_empty():
		run_loading_progress.emit("", "", 0, 0, 1.0)
		return

	var clamped_index: int = clamp(step_index, 0, steps.size() - 1)
	var step: Dictionary = steps[clamped_index]
	var denominator: float = max(float(steps.size() - 1), 1.0)
	var current_step_progress: float = float(clamped_index) / denominator
	var next_step_progress: float = min(float(clamped_index + 1), denominator) / denominator
	var progress_ratio: float = lerp(current_step_progress, next_step_progress, clamp(stage_progress_ratio, 0.0, 1.0))
	run_loading_progress.emit(
		str(step.get("id", "")),
		str(step.get("label", "")),
		clamped_index + 1,
		steps.size(),
		progress_ratio
	)


func start_background_company_detail_hydration(priority_company_ids: Array = []) -> void:
	if not RunState.has_active_run():
		return
	for company_id_value in priority_company_ids:
		RunState.queue_company_detail_hydration(str(company_id_value), true)
	var should_queue_full_roster: bool = priority_company_ids.is_empty() or (
		not background_company_detail_hydration_running and
		not RunState.has_pending_company_detail_hydration()
	)
	if should_queue_full_roster:
		for company_id_value in RunState.company_order:
			RunState.queue_company_detail_hydration(str(company_id_value), false)
	if background_company_detail_hydration_running:
		return
	background_company_detail_hydration_running = true
	call_deferred("_background_company_detail_hydration_loop")


func _background_company_detail_hydration_loop() -> void:
	while RunState.has_pending_company_detail_hydration():
		var company_id: String = RunState.dequeue_company_detail_hydration()
		if company_id.is_empty():
			break
		if RunState.ensure_company_full_detail(company_id, false):
			company_detail_ready.emit(company_id)
		await get_tree().process_frame
	background_company_detail_hydration_running = false


func _should_log_startup_perf() -> bool:
	return OS.is_debug_build()


func _should_log_advance_perf(save_after: bool, emit_runtime_signals: bool) -> bool:
	return OS.is_debug_build() and (save_after or emit_runtime_signals)


func _log_startup_perf_elapsed(label: String, started_at_usec: int, extra: String = "") -> void:
	if not _should_log_startup_perf():
		return
	var elapsed_msec: float = max(float(Time.get_ticks_usec() - started_at_usec) / 1000.0, 0.0)
	if extra.is_empty():
		print("%s %s %.2fms" % [STARTUP_PERF_LOG_PREFIX, label, elapsed_msec])
		return
	print("%s %s %.2fms%s" % [STARTUP_PERF_LOG_PREFIX, label, elapsed_msec, extra])


func _log_advance_perf_elapsed(enabled: bool, label: String, started_at_usec: int, extra: String = "") -> void:
	if not enabled:
		return
	var elapsed_msec: float = max(float(Time.get_ticks_usec() - started_at_usec) / 1000.0, 0.0)
	if extra.is_empty():
		print("%s %s %.2fms" % [ADVANCE_PERF_LOG_PREFIX, label, elapsed_msec])
		return
	print("%s %s %.2fms%s" % [ADVANCE_PERF_LOG_PREFIX, label, elapsed_msec, extra])


func _enter_game_scene() -> void:
	var current_scene = get_tree().current_scene
	if current_scene != null and current_scene.scene_file_path == GAME_SCENE:
		return

	get_tree().change_scene_to_file(GAME_SCENE)
