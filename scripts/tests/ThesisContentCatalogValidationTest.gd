extends Node


func _ready() -> void:
	DataRepository.reload_all()
	var catalog: Dictionary = DataRepository.get_thesis_content_catalog()
	if catalog.is_empty():
		_fail("Thesis content catalog is empty.")
		return
	if not _assert_required_dictionaries(catalog):
		return
	if not _assert_required_arrays(catalog):
		return
	if not _assert_labels_non_empty():
		return
	if not _assert_band_copy():
		return
	if not _assert_guidance_copy():
		return
	print("THESIS_CONTENT_CATALOG_VALIDATION_OK %s" % JSON.stringify({
		"category_labels": DataRepository.get_thesis_content_catalog().get("category_labels", {}).size(),
		"report_pillars": ThesisVocabulary.report_memo_pillars().size(),
		"ui_pillars": ThesisVocabulary.ui_evidence_discipline_pillars().size()
	}))
	get_tree().quit(0)


func _assert_required_dictionaries(catalog: Dictionary) -> bool:
	for key in [
		"category_labels",
		"interpretation_labels",
		"source_labels",
		"memo_states",
		"grade_copy",
		"report_tone_by_memo_state",
		"report_sections",
		"report_empty_bullets",
		"report_learning_notes",
		"band_copy",
		"sector_macro_focus",
		"next_research_focus"
	]:
		if typeof(catalog.get(key, {})) != TYPE_DICTIONARY or catalog.get(key, {}).is_empty():
			_fail("Expected non-empty thesis content dictionary '%s'." % key)
			return false
	return true


func _assert_required_arrays(catalog: Dictionary) -> bool:
	for key in [
		"report_memo_pillars",
		"ui_evidence_discipline_pillars",
		"stance_options",
		"horizon_options",
		"evidence_tabs"
	]:
		if typeof(catalog.get(key, [])) != TYPE_ARRAY or catalog.get(key, []).is_empty():
			_fail("Expected non-empty thesis content array '%s'." % key)
			return false
	return true


func _assert_labels_non_empty() -> bool:
	for category_value in ThesisVocabulary.VALID_CATEGORIES.keys():
		var category: String = str(category_value)
		if ThesisVocabulary.category_label(category).strip_edges().is_empty():
			_fail("Missing category label for '%s'." % category)
			return false
	for interpretation_value in ThesisVocabulary.VALID_INTERPRETATIONS.keys():
		var interpretation: String = str(interpretation_value)
		if ThesisVocabulary.interpretation_label(interpretation).strip_edges().is_empty():
			_fail("Missing interpretation label for '%s'." % interpretation)
			return false
	return true


func _assert_band_copy() -> bool:
	var checks: Array = [
		["quality", 80, "Excellent"],
		["quality", 35, "Weak"],
		["growth", 80, "Accelerating"],
		["growth", 34, "Stalling"],
		["risk", 80, "High"],
		["risk", 24, "Low"]
	]
	for check_value in checks:
		var check: Array = check_value
		var band_id: String = str(check[0])
		var score: int = int(check[1])
		var expected: String = str(check[2])
		var actual: String = ThesisVocabulary.band_label(band_id, score, "")
		if actual != expected:
			_fail("Expected %s band score %d label '%s', got '%s'." % [band_id, score, expected, actual])
			return false
		if ThesisVocabulary.band_detail(band_id, score, "").strip_edges().is_empty():
			_fail("Missing %s band score %d detail." % [band_id, score])
			return false
	return true


func _assert_guidance_copy() -> bool:
	var energy_focus: String = ThesisVocabulary.sector_macro_focus("energy")
	if energy_focus.find("commodity prices") == -1:
		_fail("Energy sector focus did not load expected copy: %s" % energy_focus)
		return false
	var income_guidance: String = " ".join(ThesisVocabulary.next_research_focus_sentences("income", "income")).to_lower()
	if income_guidance.find("dividend coverage") == -1:
		_fail("Income guidance missing dividend coverage: %s" % income_guidance)
		return false
	var event_guidance: String = " ".join(ThesisVocabulary.next_research_focus_sentences("bullish", "event")).to_lower()
	if event_guidance.find("catalyst date") == -1:
		_fail("Event guidance missing catalyst date: %s" % event_guidance)
		return false
	var pillars: Array = ThesisVocabulary.report_memo_pillars()
	for pillar_value in pillars:
		if typeof(pillar_value) != TYPE_DICTIONARY:
			_fail("Report pillar is not a dictionary.")
			return false
		var pillar: Dictionary = pillar_value
		if str(pillar.get("id", "")).strip_edges().is_empty() or str(pillar.get("missing_note", "")).strip_edges().is_empty():
			_fail("Report pillar has missing id or missing_note: %s" % JSON.stringify(pillar))
			return false
		if typeof(pillar.get("categories", [])) != TYPE_ARRAY or pillar.get("categories", []).is_empty():
			_fail("Report pillar has no categories: %s" % JSON.stringify(pillar))
			return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	print("THESIS_CONTENT_CATALOG_VALIDATION_FAIL: %s" % message)
	get_tree().quit(1)
