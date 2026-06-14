extends Node

const RUN_SEED := 20260614
const COMPANY_ID := "anre"
const THESIS_EVIDENCE_CAPTURE_SCRIPT = preload("res://systems/ThesisEvidenceCaptureSystem.gd")


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0
	if not RunState.ensure_company_full_detail(COMPANY_ID):
		_fail("Could not hydrate pinned company %s." % COMPANY_ID)
		return

	var thesis_result: Dictionary = GameManager.create_thesis(COMPANY_ID, "bullish", "swing", "Vocabulary Validation Thesis")
	if not bool(thesis_result.get("success", false)):
		_fail("Expected thesis creation to succeed: %s" % str(thesis_result.get("message", "")))
		return
	var thesis_id: String = str(thesis_result.get("thesis", {}).get("id", ""))
	var add_result: Dictionary = GameManager.add_thesis_evidence(thesis_id, {
		"category": "broker_flow",
		"category_label": "Broker Flow",
		"label": "Mismatched classified broker read",
		"value": "Positive flow, classified as risk",
		"detail": "The test deliberately sends a positive impact with a risk interpretation.",
		"impact": "positive",
		"interpretation": "risk",
		"source_label": "Validation"
	})
	if not bool(add_result.get("success", false)):
		_fail("Expected mismatched classified evidence to be accepted after correction: %s" % str(add_result.get("message", "")))
		return
	var thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	var evidence_rows: Array = thesis.get("evidence", [])
	if evidence_rows.is_empty():
		_fail("Expected corrected evidence to be saved on the thesis.")
		return
	var corrected_row: Dictionary = evidence_rows[0] if typeof(evidence_rows[0]) == TYPE_DICTIONARY else {}
	if str(corrected_row.get("interpretation", "")) != "risk":
		_fail("Expected interpretation to remain risk, got %s." % str(corrected_row.get("interpretation", "")))
		return
	if str(corrected_row.get("impact", "")) != "negative":
		_fail("Expected risk interpretation to correct impact to negative, got %s." % str(corrected_row.get("impact", "")))
		return
	if str(corrected_row.get("category", "")) != "broker_flow":
		_fail("Expected broker_flow category to remain stable, got %s." % str(corrected_row.get("category", "")))
		return

	var capture_system = THESIS_EVIDENCE_CAPTURE_SCRIPT.new()
	var attached: Dictionary = capture_system.normalize_attached_evidence({
		"category": "news",
		"label": "Negative impact classified as support",
		"value": "Negative wording",
		"impact": "negative"
	}, "support")
	if str(attached.get("impact", "")) != "positive":
		_fail("Expected support interpretation to correct impact to positive, got %s." % str(attached.get("impact", "")))
		return

	var invalid_impact_capture: Dictionary = capture_system.normalize_capture({
		"source_type": "broker_summary",
		"company_id": COMPANY_ID,
		"category": "broker_flow",
		"label": "Invalid impact vocabulary",
		"value": "Invalid",
		"impact": "moon"
	})
	if str(invalid_impact_capture.get("impact", "")) != "mixed":
		_fail("Expected invalid impact vocabulary to fall back to mixed, got %s." % str(invalid_impact_capture.get("impact", "")))
		return

	print("THESIS_VOCABULARY_VALIDATION_OK %s" % JSON.stringify({
		"manager_corrected_impact": str(corrected_row.get("impact", "")),
		"attached_corrected_impact": str(attached.get("impact", "")),
		"invalid_impact_fallback": str(invalid_impact_capture.get("impact", ""))
	}))
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	print("THESIS_VOCABULARY_VALIDATION_FAIL: %s" % message)
	get_tree().quit(1)
