extends RefCounted
class_name ThesisVocabulary

const INTERPRETATION_SUPPORT := "support"
const INTERPRETATION_RISK := "risk"
const INTERPRETATION_CONTRADICTION := "contradiction"
const INTERPRETATION_WATCH := "watch"
const INTERPRETATION_INVALIDATION := "invalidation"

const IMPACT_POSITIVE := "positive"
const IMPACT_NEGATIVE := "negative"
const IMPACT_MIXED := "mixed"

const STANCE_BULLISH := "bullish"
const STANCE_BEARISH := "bearish"
const STANCE_INCOME := "income"
const STANCE_WATCH := "watch"

const HORIZON_SWING := "swing"
const HORIZON_POSITION := "position"
const HORIZON_INCOME := "income"
const HORIZON_EVENT := "event"

const CATEGORY_FUNDAMENTALS := "fundamentals"
const CATEGORY_KEY_STATS := "key_stats"
const CATEGORY_FINANCIALS := "financials"
const CATEGORY_VALUATION := "valuation"
const CATEGORY_PRICE_ACTION := "price_action"
const CATEGORY_BROKER_FLOW := "broker_flow"
const CATEGORY_OWNERSHIP := "ownership"
const CATEGORY_MANAGEMENT := "management"
const CATEGORY_SECTOR_MACRO := "sector_macro"
const CATEGORY_NEWS := "news"
const CATEGORY_TWOOTER := "twooter"
const CATEGORY_NETWORK_INTEL := "network_intel"
const CATEGORY_CORPORATE_EVENTS := "corporate_events"
const CATEGORY_RISK_INVALIDATION := "risk_invalidation"

const DEFAULT_INTERPRETATION := INTERPRETATION_WATCH
const DEFAULT_IMPACT := IMPACT_MIXED
const DEFAULT_STANCE := STANCE_BULLISH
const DEFAULT_HORIZON := HORIZON_SWING

const VALID_INTERPRETATIONS := {
	"support": true,
	"risk": true,
	"contradiction": true,
	"watch": true,
	"invalidation": true
}

const VALID_IMPACTS := {
	"positive": true,
	"negative": true,
	"mixed": true
}

const VALID_STANCES := {
	"bullish": true,
	"bearish": true,
	"income": true,
	"watch": true
}

const VALID_HORIZONS := {
	"swing": true,
	"position": true,
	"income": true,
	"event": true
}

const VALID_CATEGORIES := {
	"fundamentals": true,
	"key_stats": true,
	"financials": true,
	"valuation": true,
	"price_action": true,
	"broker_flow": true,
	"ownership": true,
	"management": true,
	"sector_macro": true,
	"news": true,
	"twooter": true,
	"network_intel": true,
	"corporate_events": true,
	"risk_invalidation": true
}

const CATEGORY_LABELS := {
	"fundamentals": "Fundamentals / Key Stats",
	"key_stats": "Key Stats",
	"financials": "Financials",
	"valuation": "Valuation",
	"price_action": "Price Action",
	"broker_flow": "Broker Flow",
	"ownership": "Ownership",
	"management": "Management",
	"sector_macro": "Sector / Macro",
	"news": "News",
	"twooter": "Twooter",
	"network_intel": "Network Intel",
	"corporate_events": "Corporate Events",
	"risk_invalidation": "Risk / Invalidation"
}

const REPORT_MEMO_PILLARS := [
	{"id": "anchor", "label": "Anchor", "categories": ["fundamentals", "key_stats", "financials", "valuation", "ownership", "management"], "missing_note": "Capture a business, financial, ownership, or valuation anchor."},
	{"id": "price", "label": "Price", "categories": ["price_action"], "missing_note": "Capture price action or a chart pattern."},
	{"id": "tape", "label": "Tape", "categories": ["broker_flow"], "missing_note": "Capture broker flow or tape evidence."},
	{"id": "catalyst", "label": "Catalyst", "categories": ["sector_macro", "news", "twooter", "network_intel", "corporate_events"], "missing_note": "Capture a catalyst, source read, or market-context item."},
	{"id": "risk", "label": "Risk", "categories": ["risk_invalidation"], "missing_note": "Attach at least one risk or invalidation item."}
]

const UI_EVIDENCE_DISCIPLINE_PILLARS := [
	{"id": "anchor", "label": "Anchor", "categories": ["fundamentals", "financials", "valuation", "ownership", "management"], "focus_category": "fundamentals"},
	{"id": "price", "label": "Price", "categories": ["price_action"], "focus_category": "price_action"},
	{"id": "tape", "label": "Tape", "categories": ["broker_flow"], "focus_category": "broker_flow"},
	{"id": "catalyst", "label": "Catalyst", "categories": ["sector_macro", "news", "twooter", "network_intel", "corporate_events"], "focus_category": "sector_macro"},
	{"id": "risk", "label": "Invalidation", "categories": ["risk_invalidation"], "focus_category": "risk_invalidation"}
]

const STANCE_OPTIONS := [
	{"id": "bullish", "label": "Bullish"},
	{"id": "bearish", "label": "Bearish"},
	{"id": "income", "label": "Income"},
	{"id": "watch", "label": "Watch"}
]

const HORIZON_OPTIONS := [
	{"id": "swing", "label": "Swing"},
	{"id": "position", "label": "Position"},
	{"id": "income", "label": "Income"},
	{"id": "event", "label": "Event"}
]

const EVIDENCE_TABS := [
	{"id": "support", "label": "Support"},
	{"id": "risk", "label": "Risk"},
	{"id": "contradiction", "label": "Contradict"},
	{"id": "watch", "label": "Watch"},
	{"id": "invalidation", "label": "Invalidation"}
]


static func normalize_interpretation(value: String, warn_on_unknown: bool = false, context: String = "") -> String:
	var normalized: String = value.to_lower().strip_edges()
	if VALID_INTERPRETATIONS.has(normalized):
		return normalized
	if warn_on_unknown and not normalized.is_empty():
		_warn_invalid_value("interpretation", normalized, DEFAULT_INTERPRETATION, VALID_INTERPRETATIONS, context)
		assert(false, "Unknown thesis interpretation '%s'." % normalized)
	return DEFAULT_INTERPRETATION


static func normalize_impact(value: String, warn_on_unknown: bool = false, context: String = "") -> String:
	var normalized: String = value.to_lower().strip_edges()
	if VALID_IMPACTS.has(normalized):
		return normalized
	if warn_on_unknown and not normalized.is_empty():
		_warn_invalid_value("impact", normalized, DEFAULT_IMPACT, VALID_IMPACTS, context)
	return DEFAULT_IMPACT


static func normalize_category(value: String, warn_on_unknown: bool = false, context: String = "") -> String:
	var normalized: String = value.to_lower().strip_edges()
	if normalized.is_empty() or VALID_CATEGORIES.has(normalized):
		return normalized
	if warn_on_unknown:
		_warn_invalid_value("category", normalized, normalized, VALID_CATEGORIES, context)
		assert(false, "Unknown thesis evidence category '%s'." % normalized)
	return normalized


static func normalize_stance(value: String) -> String:
	var normalized: String = value.to_lower().strip_edges()
	if VALID_STANCES.has(normalized):
		return normalized
	return DEFAULT_STANCE


static func normalize_horizon(value: String) -> String:
	var normalized: String = value.to_lower().strip_edges()
	if VALID_HORIZONS.has(normalized):
		return normalized
	return DEFAULT_HORIZON


static func category_label(category: String) -> String:
	var normalized: String = normalize_category(category, false)
	var labels: Dictionary = _content_dictionary("category_labels")
	return str(labels.get(normalized, CATEGORY_LABELS.get(normalized, normalized.capitalize())))


static func interpretation_label(value: String) -> String:
	var normalized: String = normalize_interpretation(value)
	var labels: Dictionary = _content_dictionary("interpretation_labels")
	match normalized:
		INTERPRETATION_SUPPORT:
			return str(labels.get(normalized, "Supporting Evidence"))
		INTERPRETATION_RISK:
			return str(labels.get(normalized, "Risk"))
		INTERPRETATION_CONTRADICTION:
			return str(labels.get(normalized, "Contradiction"))
		INTERPRETATION_INVALIDATION:
			return str(labels.get(normalized, "Invalidation"))
	return str(labels.get(normalized, "Watch Item"))


static func source_label(source_type: String, fallback: String = "") -> String:
	var normalized: String = source_type.to_lower().strip_edges()
	var labels: Dictionary = _content_dictionary("source_labels")
	var resolved_fallback: String = fallback
	if resolved_fallback.is_empty():
		resolved_fallback = normalized.capitalize()
	return str(labels.get(normalized, resolved_fallback))


static func report_memo_pillars() -> Array:
	return _content_array_or_fallback("report_memo_pillars", REPORT_MEMO_PILLARS)


static func ui_evidence_discipline_pillars() -> Array:
	return _content_array_or_fallback("ui_evidence_discipline_pillars", UI_EVIDENCE_DISCIPLINE_PILLARS)


static func stance_options() -> Array:
	return _content_array_or_fallback("stance_options", STANCE_OPTIONS)


static func horizon_options() -> Array:
	return _content_array_or_fallback("horizon_options", HORIZON_OPTIONS)


static func evidence_tabs() -> Array:
	return _content_array_or_fallback("evidence_tabs", EVIDENCE_TABS)


static func memo_state_label(state_id: String, fallback: String) -> String:
	var states: Dictionary = _content_dictionary("memo_states")
	return str(states.get(state_id, fallback))


static func grade_title(grade: String, fallback: String) -> String:
	var grade_copy: Dictionary = _content_dictionary("grade_copy")
	var value = grade_copy.get(grade, grade_copy.get("default", {}))
	var row: Dictionary = value if typeof(value) == TYPE_DICTIONARY else {}
	return str(row.get("title", fallback))


static func grade_subcopy(grade: String, fallback: String) -> String:
	var grade_copy: Dictionary = _content_dictionary("grade_copy")
	var value = grade_copy.get(grade, grade_copy.get("default", {}))
	var row: Dictionary = value if typeof(value) == TYPE_DICTIONARY else {}
	return str(row.get("subcopy", fallback))


static func report_tone_for_memo_state(memo_state: String) -> String:
	var tones: Dictionary = _content_dictionary("report_tone_by_memo_state")
	return str(tones.get(memo_state, ""))


static func report_section_title(section_id: String, fallback: String) -> String:
	var sections: Dictionary = _content_dictionary("report_sections")
	return str(sections.get(section_id, fallback))


static func report_empty_bullet(empty_id: String, fallback: String) -> String:
	var bullets: Dictionary = _content_dictionary("report_empty_bullets")
	return str(bullets.get(empty_id, fallback))


static func report_learning_note(note_id: String, fallback: String) -> String:
	var notes: Dictionary = _content_dictionary("report_learning_notes")
	return str(notes.get(note_id, fallback))


static func band_label(band_id: String, score: int, fallback: String) -> String:
	var row: Dictionary = _band_row(band_id, score)
	return str(row.get("label", fallback))


static func band_detail(band_id: String, score: int, fallback: String) -> String:
	var row: Dictionary = _band_row(band_id, score)
	return str(row.get("detail", fallback))


static func sector_macro_focus(sector_id: String) -> String:
	var focus_rows: Dictionary = _content_dictionary("sector_macro_focus")
	var normalized: String = sector_id.to_lower().strip_edges()
	if focus_rows.has(normalized):
		return str(focus_rows.get(normalized, ""))
	match normalized:
		"consumer":
			return "watch domestic purchasing power, distribution strength, and margin pass-through"
		"noncyclical":
			return "watch staple demand, payout durability, and cost pass-through"
		"industrial":
			return "watch the capex cycle, order books, and operating leverage"
		"energy":
			return "watch commodity prices, lifting costs, and capex discipline"
		"tech":
			return "watch user retention, monetization, and margin durability"
		"infra", "infrastructure":
			return "watch utilization, contract tenor, funding cost, and regulated returns"
		"transport", "logistics":
			return "watch route utilization, fuel sensitivity, and freight or passenger demand"
		"health", "healthcare":
			return "watch regulated demand, product mix, and compliance risk"
		"finance", "financial":
			return "watch credit quality, funding cost, and deposit resilience"
		"basicindustry", "materials", "basic_materials":
			return "watch plant utilization, input spreads, and downstream demand"
		"property", "realestate", "real_estate":
			return "watch presales, occupancy, project delivery, and rate sensitivity"
	return str(focus_rows.get("default", "watch sector demand, margin sensitivity, and funding conditions"))


static func next_research_focus_sentences(stance: String, horizon: String) -> Array:
	var focus: Dictionary = _content_dictionary("next_research_focus")
	var stance_rows: Dictionary = focus.get("stance", {}) if typeof(focus.get("stance", {})) == TYPE_DICTIONARY else {}
	var horizon_rows: Dictionary = focus.get("horizon", {}) if typeof(focus.get("horizon", {})) == TYPE_DICTIONARY else {}
	var sentences: Array = []
	var normalized_stance: String = normalize_stance(stance)
	if stance_rows.has(normalized_stance):
		sentences.append(str(stance_rows.get(normalized_stance, "")))
	else:
		match normalized_stance:
			STANCE_BULLISH:
				sentences.append("For a bullish stance, confirm that upside is supported by fresh buyers, not only a good story.")
			STANCE_BEARISH:
				sentences.append("For a bearish stance, look for evidence that weakness is company-specific and not just broad market fear.")
			STANCE_INCOME:
				sentences.append("For an income stance, prioritize dividend coverage, payout durability, and cash-flow resilience.")
			STANCE_WATCH:
				sentences.append("For a watch stance, define the trigger that would move the idea from observation to action.")
	var normalized_horizon: String = normalize_horizon(horizon)
	if horizon_rows.has(normalized_horizon):
		sentences.append(str(horizon_rows.get(normalized_horizon, "")))
	else:
		match normalized_horizon:
			HORIZON_SWING:
				sentences.append("For a swing horizon, focus on the next few sessions: price level, tape confirmation, and a near-term catalyst.")
			HORIZON_POSITION:
				sentences.append("For a position horizon, check sizing against macro volatility, balance-sheet risk, and whether the thesis can survive several bad weeks.")
			HORIZON_INCOME:
				sentences.append("For an income horizon, recheck payout coverage, cash generation, and whether rate moves change the yield tradeoff.")
			HORIZON_EVENT:
				sentences.append("For an event horizon, pin the catalyst date, expected disclosure, and the stop if the market prices it early.")
	return sentences


static func impact_for_interpretation(value: String) -> String:
	match normalize_interpretation(value):
		INTERPRETATION_SUPPORT:
			return IMPACT_POSITIVE
		INTERPRETATION_RISK, INTERPRETATION_CONTRADICTION, INTERPRETATION_INVALIDATION:
			return IMPACT_NEGATIVE
		_:
			return IMPACT_MIXED


static func validate_impact_for_interpretation(impact: String, interpretation: String, context: String = "") -> String:
	var resolved_interpretation: String = normalize_interpretation(interpretation, true, context)
	var resolved_impact: String = normalize_impact(impact, true, context)
	var expected_impact: String = impact_for_interpretation(resolved_interpretation)
	if _impact_contradicts_interpretation(resolved_impact, resolved_interpretation):
		push_warning("Thesis evidence%s impact '%s' does not match interpretation '%s'; corrected to '%s'." % [
			_context_suffix(context),
			resolved_impact,
			resolved_interpretation,
			expected_impact
		])
		return expected_impact
	return resolved_impact


static func _impact_contradicts_interpretation(impact: String, interpretation: String) -> bool:
	match interpretation:
		INTERPRETATION_SUPPORT:
			return impact == IMPACT_NEGATIVE
		INTERPRETATION_RISK, INTERPRETATION_CONTRADICTION, INTERPRETATION_INVALIDATION:
			return impact == IMPACT_POSITIVE
	return false


static func _warn_invalid_value(kind: String, value: String, fallback: String, valid_values: Dictionary, context: String = "") -> void:
	push_warning("Unknown thesis %s%s '%s'; using '%s'. Valid: %s." % [
		kind,
		_context_suffix(context),
		value,
		fallback,
		_sorted_key_list(valid_values)
	])


static func _context_suffix(context: String) -> String:
	var trimmed: String = context.strip_edges()
	return "" if trimmed.is_empty() else " [%s]" % trimmed


static func _sorted_key_list(values: Dictionary) -> String:
	var keys: Array = []
	for key_value in values.keys():
		keys.append(str(key_value))
	keys.sort()
	return ", ".join(keys)


static func _content_dictionary(key: String) -> Dictionary:
	var catalog: Dictionary = DataRepository.get_thesis_content_catalog()
	var value = catalog.get(key, {})
	if typeof(value) == TYPE_DICTIONARY:
		return value.duplicate(true)
	return {}


static func _content_array_or_fallback(key: String, fallback: Array) -> Array:
	var catalog: Dictionary = DataRepository.get_thesis_content_catalog()
	var value = catalog.get(key, [])
	if typeof(value) == TYPE_ARRAY and not value.is_empty():
		return value.duplicate(true)
	return fallback.duplicate(true)


static func _band_row(band_id: String, score: int) -> Dictionary:
	var bands: Dictionary = _content_dictionary("band_copy")
	var rows: Array = bands.get(band_id, []) if typeof(bands.get(band_id, [])) == TYPE_ARRAY else []
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if score >= int(row.get("min", -999999)):
			return row
	return {}
