extends RefCounted

const FLOW_WATCHLIST := "watchlist_flow"
const FLOW_TRADE := "trade_flow"
const FLOW_RESEARCH := "research_flow"
const FLOW_FUNDAMENTAL := "fundamental_flow"
const FLOW_TECHNICAL := "technical_flow"
const FLOW_THESIS := "thesis_flow"
const FLOW_LIFE_FINANCE := "life_finance_flow"
const FLOW_CORPORATE_EVENT := "corporate_event_flow"
const FLOW_ACADEMY := "academy_flow"

const FLOW_ORDER := [
	FLOW_WATCHLIST,
	FLOW_TRADE,
	FLOW_RESEARCH,
	FLOW_FUNDAMENTAL,
	FLOW_TECHNICAL,
	FLOW_THESIS,
	FLOW_LIFE_FINANCE,
	FLOW_CORPORATE_EVENT,
	FLOW_ACADEMY
]

const RELEASE_LOCKED_FLOW_IDS := {
	FLOW_ACADEMY: "coming_soon"
}

const CONTEXT_FLOW_IDS := {
	"watchlist": FLOW_WATCHLIST,
	"trade": FLOW_TRADE,
	"research": FLOW_RESEARCH,
	"fundamental": FLOW_FUNDAMENTAL,
	"technical": FLOW_TECHNICAL,
	"thesis": FLOW_THESIS,
	"life_finance": FLOW_LIFE_FINANCE,
	"corporate_event": FLOW_CORPORATE_EVENT,
	"academy": FLOW_ACADEMY,
	"news": FLOW_RESEARCH,
	"twooter": FLOW_RESEARCH,
	"key_stats": FLOW_FUNDAMENTAL,
	"financials": FLOW_FUNDAMENTAL,
	"chart": FLOW_TECHNICAL,
	"life": FLOW_LIFE_FINANCE,
	"rupslb": FLOW_CORPORATE_EVENT
}

const FLOW_CATALOG := {
	FLOW_WATCHLIST: {
		"id": FLOW_WATCHLIST,
		"label": "Watchlist Flow",
		"short_label": "Watchlist",
		"description": "Pick one company and save it so the rest of the loop has a real subject.",
		"context_id": "watchlist",
		"starter": true,
		"steps": [
			{
				"id": "open_stockbot",
				"title": "Start With STOCKBOT",
				"objective": "Open STOCKBOT from the desktop.",
				"body": "STOCKBOT is where you choose a company, inspect the setup, and build your first watchlist.",
				"target_key": "stockbot_app",
				"action_hint": "Open STOCKBOT."
			},
			{
				"id": "open_all_stock",
				"title": "Use All Stock",
				"objective": "Switch the list to All Stock.",
				"body": "The first watchlist entry should come from the full market, not an empty watchlist tab.",
				"target_key": "stock_list_tabs",
				"required_app": "stock",
				"action_hint": "Open Trade, then choose All Stock"
			},
			{
				"id": "select_stock",
				"title": "Choose One Company",
				"objective": "Select any company that looks worth studying.",
				"body": "You only need one name to start. The goal is to make the later trade and recap concrete.",
				"target_key": "all_stock_rows",
				"required_app": "stock",
				"action_hint": "Select one company."
			},
			{
				"id": "add_watchlist",
				"title": "Save The Company",
				"objective": "Add the selected company to Watchlist.",
				"body": "Watchlist turns the market into a short queue of names you intend to revisit.",
				"target_key": "all_stock_rows",
				"required_app": "stock",
				"action_hint": "Open Trade, then press Watch"
			},
			{
				"id": "handoff",
				"title": "Watchlist Ready",
				"objective": "Keep this company as your first learning target.",
				"body": "Next, make one tiny trade so Daily Recap can show how decisions connect to market movement.",
				"target_key": "",
				"action_hint": "Continue to the trade guide."
			}
		]
	},
	FLOW_TRADE: {
		"id": FLOW_TRADE,
		"label": "Trade Flow",
		"short_label": "Trade",
		"description": "Inspect one setup, buy a small starter lot, then read the next Daily Recap.",
		"context_id": "trade",
		"starter": true,
		"steps": [
			{
				"id": "inspect_setup",
				"title": "Inspect Before Buying",
				"objective": "Open one research tab for the selected company.",
				"body": "Price alone is not a thesis. Check at least one detail before using cash.",
				"target_key": "work_tabs",
				"required_app": "stock",
				"action_hint": "Open Key Stats, Financials, Broker, or Profile."
			},
			{
				"id": "buy_one_lot",
				"title": "Make A Tiny Trade",
				"objective": "Buy one small starter lot.",
				"body": "One lot is enough to make tomorrow's recap meaningful without making the first decision too loud.",
				"target_key": "submit_order_button",
				"required_app": "stock",
				"action_hint": "Buy one lot."
			},
			{
				"id": "open_portfolio",
				"title": "Check Portfolio",
				"objective": "Open Portfolio after the fill.",
				"body": "Portfolio tells you what you own, how much cash is left, and whether the order landed cleanly.",
				"target_key": "portfolio_button",
				"required_app": "stock",
				"action_hint": "Open Portfolio."
			},
			{
				"id": "close_stockbot",
				"title": "Close STOCKBOT",
				"objective": "Close STOCKBOT after checking Portfolio.",
				"body": "You have confirmed the starter position. Close the window so the desktop Advance Day button is reachable.",
				"target_key": "stockbot_close_button",
				"required_app": "stock",
				"action_hint": "Close STOCKBOT."
			},
			{
				"id": "advance_day",
				"title": "Let The Market Close",
				"objective": "Advance one trading day.",
				"body": "Advancing the day prints new price movement, news, portfolio changes, and Daily Recap.",
				"target_key": "advance_day_button",
				"action_hint": "Press Advance Day."
			},
			{
				"id": "read_recap",
				"title": "Read Daily Recap",
				"objective": "Review the recap, then continue.",
				"body": "The recap connects your starter position with what changed in the market.",
				"target_key": "daily_recap_continue",
				"action_hint": "Close Daily Recap."
			},
			{
				"id": "handoff",
				"title": "Starter Loop Complete",
				"objective": "Take control from here.",
				"body": "The main loop is now yours: choose a company, research it, trade deliberately, then review the next day.",
				"target_key": "",
				"action_hint": "Finish the starter guide."
			}
		]
	},
	FLOW_RESEARCH: {
		"id": FLOW_RESEARCH,
		"label": "Research Flow",
		"short_label": "Research",
		"description": "Use News or Twooter to find a clue, event, or related company worth investigating.",
		"context_id": "research",
		"steps": [
			{
				"id": "open_research_app",
				"title": "Open A Research Feed",
				"objective": "Open News or Twooter.",
				"body": "Feeds are for context: catalysts, rumors, mood shifts, and names you might otherwise miss.",
				"target_key": "research_app",
				"action_hint": "Open News or Twooter."
			},
			{
				"id": "inspect_context",
				"title": "Inspect One Clue",
				"objective": "Select one article, post, event, or account.",
				"body": "You are looking for a company, a risk, or a reason to compare one stock with another.",
				"target_key": "research_feed",
				"action_hint": "Select one item."
			},
			{
				"id": "handoff",
				"title": "Research Has A Job",
				"objective": "Turn the clue into your next inspection target.",
				"body": "When a feed gives you a name or catalyst, move back to STOCKBOT and test it against fundamentals or chart behavior.",
				"target_key": "",
				"action_hint": "Use the clue when you are ready."
			}
		]
	},
	FLOW_FUNDAMENTAL: {
		"id": FLOW_FUNDAMENTAL,
		"label": "Fundamental Flow",
		"short_label": "Fundamental",
		"description": "Read Key Stats and Financials as evidence rather than as a wall of numbers.",
		"context_id": "fundamental",
		"steps": [
			{
				"id": "open_key_stats",
				"title": "Read One Metric",
				"objective": "Use Key Stats to pick one profitability, growth, or risk clue.",
				"body": "You do not need every number. Find one metric that changes your confidence, then cross-check it.",
				"target_key": "work_tabs",
				"required_app": "stock",
				"action_hint": "Read Key Stats, then open Financials."
			},
			{
				"id": "open_financials",
				"title": "Cross-Check Financials",
				"objective": "Open Financials and compare the setup against the statements.",
				"body": "Financials are useful when they confirm, contradict, or sharpen the story you saw in Key Stats.",
				"target_key": "work_tabs",
				"required_app": "stock",
				"action_hint": "Open Financials."
			},
			{
				"id": "handoff",
				"title": "Use Evidence",
				"objective": "Keep or discard the company based on what changed your view.",
				"body": "If the metric matters, click the row and add it to the Research Tray. Thesis Board uses captured facts, not generated evidence lists.",
				"target_key": "",
				"action_hint": "Apply the evidence."
			}
		]
	},
	FLOW_TECHNICAL: {
		"id": FLOW_TECHNICAL,
		"label": "Technical Flow",
		"short_label": "Technical",
		"description": "Use the chart controls to inspect price behavior and mark one pattern region.",
		"context_id": "technical",
		"steps": [
			{
				"id": "use_chart_tool",
				"title": "Use A Chart Control",
				"objective": "Open Chart, then change range/display controls or mark one pattern region.",
				"body": "A useful chart read should point to a zone, not just a feeling.",
				"target_key": "chart_controls",
				"required_app": "stock",
				"action_hint": "Use a chart control or pattern tool."
			},
			{
				"id": "handoff",
				"title": "Chart Read Complete",
				"objective": "Use the chart as supporting evidence, not as the whole decision.",
				"body": "Capture the pattern into the Research Tray if it changes the story. A thesis gets stronger when chart reads are arranged beside fundamentals, news, and flow.",
				"target_key": "",
				"action_hint": "Use the chart read when ready."
			}
		]
	},
	FLOW_THESIS: {
		"id": FLOW_THESIS,
		"label": "Thesis Flow",
		"short_label": "Thesis",
		"description": "Capture evidence from real app surfaces, arrange it in Thesis Board, and decide whether to generate the thesis now or later.",
		"context_id": "thesis",
		"steps": [
			{
				"id": "capture_evidence",
				"title": "Capture One Fact",
				"objective": "Add one real metric, chart read, article, or flow row to the Research Tray.",
				"body": "The new thesis flow starts outside the board. Inspect a stock in STOCKBOT, then click a useful row or chart claim and choose Add to Research Tray.",
				"target_key": "research_capture",
				"required_app": "stock",
				"action_hint": "Capture one Research Tray item."
			},
			{
				"id": "open_thesis",
				"title": "Open Thesis Board",
				"objective": "Open Thesis Board after capturing evidence.",
				"body": "Thesis Board is where captured facts become a memo. It should not be the first place you learn the stock.",
				"target_key": "thesis_app",
				"required_app": "thesis",
				"action_hint": "Open Thesis Board."
			},
			{
				"id": "create_thesis",
				"title": "Start A Draft",
				"objective": "Press Create Thesis to open the builder.",
				"body": "Start a draft only after something from the market made you curious enough to save it.",
				"target_key": "thesis_create_button",
				"required_app": "thesis",
				"action_hint": "Start a thesis draft."
			},
			{
				"id": "save_thesis",
				"title": "Set The Frame",
				"objective": "Pick stock, stance, and timeframe, then save the thesis.",
				"body": "The frame tells the memo what question it is answering: which company, what stance, and over what horizon.",
				"target_key": "thesis_save_button",
				"required_app": "thesis",
				"action_hint": "Save the thesis frame."
			},
			{
				"id": "add_evidence",
				"title": "Arrange Evidence",
				"objective": "Attach at least one captured evidence item.",
				"body": "Move captured evidence into the thesis board and classify what it means: support, risk, contradiction, watch, or invalidation.",
				"target_key": "thesis_evidence_grid",
				"required_app": "thesis",
				"action_hint": "Attach captured evidence."
			},
			{
				"id": "generate_or_defer",
				"title": "Report Or Defer",
				"objective": "Generate the report if it matters now, or defer it for a later day.",
				"body": "Generate Thesis spends AP and turns your attached evidence into a memo. It is fine to defer until the board has enough facts.",
				"target_key": "thesis_report_button",
				"required_app": "thesis",
				"action_hint": "Generate or defer the report."
			},
			{
				"id": "handoff",
				"title": "Review Later",
				"objective": "Revisit the thesis after another market day.",
				"body": "Good thesis work is a review habit: compare evidence against what actually happened.",
				"target_key": "",
				"action_hint": "Review it after a later day."
			}
		]
	},
	FLOW_LIFE_FINANCE: {
		"id": FLOW_LIFE_FINANCE,
		"label": "Life Finance Flow",
		"short_label": "Life",
		"description": "Review runway, monthly cost, and recovery options before cash pressure becomes a surprise.",
		"context_id": "life_finance",
		"steps": [
			{
				"id": "open_life",
				"title": "Review Your Runway",
				"objective": "Check monthly cost and runway before changing risk.",
				"body": "Life is where investing discipline meets cash runway. Basics spending now also shapes daily pressure.",
				"target_key": "life_basics_slider",
				"required_app": "life",
				"action_hint": "Review Basics, then update the plan."
			},
			{
				"id": "open_finance",
				"title": "Review Finance",
				"objective": "Open the Finance tab and read runway/monthly cost.",
				"body": "Emergency loans are recovery tools, not starter goals. Use them only when the run actually needs it.",
				"target_key": "life_tabs",
				"required_app": "life",
				"action_hint": "Open Finance."
			},
			{
				"id": "handoff",
				"title": "Cash Plan Set",
				"objective": "Keep enough cash for upcoming obligations.",
				"body": "Before larger trades, check whether tomorrow's decision still leaves room for life costs.",
				"target_key": "",
				"action_hint": "Use Finance when cash gets tight."
			}
		]
	},
	FLOW_CORPORATE_EVENT: {
		"id": FLOW_CORPORATE_EVENT,
		"label": "Corporate Event Flow",
		"short_label": "Corporate",
		"description": "Attend a low-stakes stock-split RUPSLB and learn how event rooms create leads.",
		"context_id": "corporate_event",
		"steps": [
			{
				"id": "schedule_event",
				"title": "Seed A Practice Event",
				"objective": "Create a guided low-stakes stock-split RUPSLB.",
				"body": "This event guide appears when corporate meetings matter; it is no longer mandatory in the starter loop.",
				"target_key": "advance_day_button",
				"action_hint": "Let the event appear on the calendar."
			},
			{
				"id": "attend_rupslb",
				"title": "Attend The RUPSLB",
				"objective": "Open the seeded corporate meeting when it arrives.",
				"body": "Meetings can expose votes, room leads, and corporate action context beyond the headline.",
				"target_key": "rupslb_overlay",
				"action_hint": "Attend the event."
			},
			{
				"id": "approach_lead",
				"title": "Approach One Lead",
				"objective": "Talk to one approachable room lead, or finish the meeting if none remain.",
				"body": "Room leads turn event attendance into network progress.",
				"target_key": "rupslb_lead",
				"action_hint": "Approach an available lead."
			},
			{
				"id": "handoff",
				"title": "Event Loop Learned",
				"objective": "Use future events as context, not chores.",
				"body": "Corporate events are optional opportunities. Attend when the company, vote, or network angle matters.",
				"target_key": "",
				"action_hint": "Finish the event guide."
			}
		]
	},
	FLOW_ACADEMY: {
		"id": FLOW_ACADEMY,
		"label": "Academy Flow",
		"short_label": "Academy",
		"description": "Read one short lesson and connect it to the tool you were using.",
		"context_id": "academy",
		"steps": [
			{
				"id": "open_academy",
				"title": "Choose A Lesson",
				"objective": "Pick one short Academy lesson.",
				"body": "Academy explains concepts when you want them; start by choosing any unlocked lesson that looks useful.",
				"target_key": "academy_app",
				"action_hint": "Choose one lesson."
			},
			{
				"id": "read_lesson",
				"title": "Read One Lesson",
				"objective": "Mark one short lesson as read.",
				"body": "Use lessons as references. The goal is recognition, not a forced quiz.",
				"target_key": "academy_mark_read",
				"required_app": "academy",
				"action_hint": "Read or mark one lesson."
			},
			{
				"id": "handoff",
				"title": "Concept Saved",
				"objective": "Return to the question that sent you here.",
				"body": "When a concept clicks, go back to the company, chart, thesis, or portfolio choice that made it relevant.",
				"target_key": "",
				"action_hint": "Return when ready."
			}
		]
	}
}


static func default_state(enabled: bool = false) -> Dictionary:
	var state := {
		"enabled": enabled,
		"auto_prompt_enabled": enabled,
		"active_flow_id": "",
		"active_step_id": "",
		"completed_flow_ids": [],
		"skipped_flow_ids": [],
		"dismissed_prompt_flow_ids": [],
		"completed_step_ids": {},
		"anchor_company_id": "",
		"seeded_meeting_id": "",
		"seeded_chain_id": "",
		"last_prompt_flow_id": "",
		"starter_handoff_seen": false
	}
	if enabled:
		state["active_flow_id"] = FLOW_WATCHLIST
		state["active_step_id"] = first_step_for_flow(FLOW_WATCHLIST)
	return state


static func flow_exists(flow_id: String) -> bool:
	return FLOW_CATALOG.has(flow_id)


static func flow_enabled(flow_id: String) -> bool:
	return FLOW_CATALOG.has(flow_id) and flow_release_status(flow_id) == "available"


static func flow_release_status(flow_id: String) -> String:
	var release_value: Variant = RELEASE_LOCKED_FLOW_IDS.get(flow_id, null)
	if release_value == null:
		return "available"
	if typeof(release_value) == TYPE_STRING and not str(release_value).strip_edges().is_empty():
		return str(release_value).strip_edges()
	return "coming_soon"


static func flow(flow_id: String) -> Dictionary:
	if not FLOW_CATALOG.has(flow_id):
		return {}
	return FLOW_CATALOG[flow_id].duplicate(true)


static func flows() -> Array:
	var rows: Array = []
	for flow_id_value in FLOW_ORDER:
		rows.append(flow(str(flow_id_value)))
	return rows


static func first_step_for_flow(flow_id: String) -> String:
	var flow_data: Dictionary = FLOW_CATALOG.get(flow_id, {})
	var steps: Array = flow_data.get("steps", [])
	if steps.is_empty():
		return ""
	var first_step: Dictionary = steps[0]
	return str(first_step.get("id", ""))


static func step_ids_for_flow(flow_id: String) -> Array:
	var ids: Array = []
	var flow_data: Dictionary = FLOW_CATALOG.get(flow_id, {})
	for step_value in flow_data.get("steps", []):
		if typeof(step_value) != TYPE_DICTIONARY:
			continue
		ids.append(str(step_value.get("id", "")))
	return ids


static func step(flow_id: String, step_id: String) -> Dictionary:
	var flow_data: Dictionary = FLOW_CATALOG.get(flow_id, {})
	for step_value in flow_data.get("steps", []):
		if typeof(step_value) != TYPE_DICTIONARY:
			continue
		var step_data: Dictionary = step_value
		if str(step_data.get("id", "")) == step_id:
			return step_data.duplicate(true)
	return {}


static func next_step_for_flow(flow_id: String, step_id: String) -> String:
	var ids: Array = step_ids_for_flow(flow_id)
	var current_index: int = ids.find(step_id)
	if current_index < 0 or current_index + 1 >= ids.size():
		return ""
	return str(ids[current_index + 1])


static func step_index(flow_id: String, step_id: String) -> int:
	return max(step_ids_for_flow(flow_id).find(step_id), 0)


static func step_count(flow_id: String) -> int:
	return max(step_ids_for_flow(flow_id).size(), 1)


static func flow_for_context(context_id: String) -> String:
	var flow_id: String = str(CONTEXT_FLOW_IDS.get(context_id.strip_edges().to_lower(), ""))
	return flow_id if flow_enabled(flow_id) else ""
