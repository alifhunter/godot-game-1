extends Node

const RUN_SEED := 20260614
const THESIS_BOARD_WIDGET_SCRIPT = preload("res://scripts/ui/widgets/ThesisBoardWidget.gd")


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)

	var sector_details: Dictionary = _collect_sector_macro_details()
	if sector_details.size() < 3:
		_fail("Expected at least 3 sector macro samples, got %d." % sector_details.size())
		return
	var unique_details: Dictionary = {}
	for detail_value in sector_details.values():
		unique_details[str(detail_value)] = true
	if unique_details.size() != sector_details.size():
		_fail("Expected sector macro details to differ by sector: %s" % JSON.stringify(sector_details))
		return

	var guidance: Dictionary = _collect_guidance_samples()
	if not _assert_contains(str(guidance.get("income", "")), "dividend coverage", "income guidance"):
		return
	if not _assert_contains(str(guidance.get("event", "")), "catalyst date", "event guidance"):
		return
	if not _assert_contains(str(guidance.get("position", "")), "macro volatility", "position guidance"):
		return
	if str(guidance.get("income", "")) == str(guidance.get("event", "")) or str(guidance.get("event", "")) == str(guidance.get("position", "")):
		_fail("Expected stance/horizon guidance samples to differ: %s" % JSON.stringify(guidance))
		return

	print("THESIS_CONTENT_DEPTH_OK %s" % JSON.stringify({
		"sector_samples": sector_details,
		"guidance_samples": guidance.keys()
	}))
	get_tree().quit(0)


func _collect_sector_macro_details() -> Dictionary:
	var sector_details: Dictionary = {}
	for company_id_value in RunState.company_order:
		if sector_details.size() >= 3:
			break
		var company_id: String = str(company_id_value)
		if not RunState.ensure_company_full_detail(company_id):
			continue
		var company: Dictionary = GameManager.get_company_snapshot(company_id, true, true, true)
		var sector_id: String = str(company.get("sector_id", "")).strip_edges()
		if sector_id.is_empty() or sector_details.has(sector_id):
			continue
		var detail: String = _detail_for_option(ThesisManager.thesis_sector_macro_options(GameManager, company), "GDP growth")
		if detail.find("Sector lens:") == -1:
			_fail("Expected sector macro detail for %s to include a sector lens: %s" % [sector_id, detail])
			return {}
		sector_details[sector_id] = detail
	return sector_details


func _collect_guidance_samples() -> Dictionary:
	var widget = THESIS_BOARD_WIDGET_SCRIPT.new()
	var evidence_rows: Array = [_make_evidence("fundamentals", "Business quality", "Strong", "The business has a usable anchor.", "support")]
	var report: Dictionary = {"missing_notes": []}
	var guidance: Dictionary = {
		"income": widget._thesis_next_research_summary(evidence_rows, report, "income", "income").to_lower(),
		"event": widget._thesis_next_research_summary(evidence_rows, report, "bullish", "event").to_lower(),
		"position": widget._thesis_next_research_summary(evidence_rows, report, "bearish", "position").to_lower()
	}
	widget.queue_free()
	return guidance


func _detail_for_option(options: Array, label: String) -> String:
	for option_value in options:
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		if str(option.get("label", "")) == label:
			return str(option.get("detail", ""))
	return ""


func _make_evidence(category: String, label: String, value: String, detail: String, interpretation: String) -> Dictionary:
	return {
		"category": category,
		"label": label,
		"value": value,
		"detail": detail,
		"impact": ThesisVocabulary.impact_for_interpretation(interpretation),
		"interpretation": interpretation,
		"source_label": "Test"
	}


func _assert_contains(text: String, expected: String, label: String) -> bool:
	if text.find(expected) == -1:
		_fail("Expected %s to include '%s': %s" % [label, expected, text])
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	print("THESIS_CONTENT_DEPTH_FAIL: %s" % message)
	get_tree().quit(1)
