extends Node

const ANNUAL_FILING_DOCUMENT = preload("res://systems/AnnualFilingDocument.gd")

const RUN_SEED := 20260624
const EXPECTED_HASH := "2022638696"
const REQUIRED_BANK_TOC_BUTTONS := [
	"FinancialStatementReportTocButton_note_bank_loans_financing",
	"FinancialStatementReportTocButton_note_bank_credit_risk",
	"FinancialStatementReportTocButton_note_bank_liquidity_risk"
]
const REQUIRED_CAPTURE_TYPES := [
	"statement_row",
	"note_paragraph",
	"note_table_row"
]
const HIDDEN_VISIBLE_TOKENS := [
	"truth_state",
	"source_quality",
	"source quality",
	"confidence_label",
	"packet|",
	"story|",
	"placement|",
	"catatan",
	"laporan",
	"million_idr",
	"related note classifications",
	"note classifications",
	"classifications connect"
]
const FORBIDDEN_GENERIC_PHRASES := [
	"related note classifications",
	"same basis as the consolidated statements",
	"supporting schedule includes",
	"describes the recognition and movement",
	"the note presentation should be read together",
	"this disclosure should be read together"
]

var game_root: Node = null
var bank_company_id: String = ""


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var result: Dictionary = await _run_smoke()
	if not bool(result.get("success", false)):
		_fail(str(result.get("message", "annual filing bank reader UI smoke failed")))
		return

	var hash: String = _stable_hash(str(result.get("payload", "")))
	if EXPECTED_HASH != "BASELINE_PENDING" and hash != EXPECTED_HASH:
		_fail("Annual filing bank reader UI smoke hash changed. expected=%s actual=%s." % [EXPECTED_HASH, hash])
		return

	print("ANNUAL_FILING_BANK_READER_UI_SMOKE_OK %s" % JSON.stringify({
		"hash": hash,
		"company_id": str(result.get("company_id", "")),
		"profile": str(result.get("profile", "")),
		"section_count": int(result.get("section_count", 0)),
		"table_count": int(result.get("table_count", 0)),
		"table_row_count": int(result.get("table_row_count", 0)),
		"capture_count": int(result.get("capture_count", 0)),
		"visible_filing_hash": str(result.get("visible_filing_hash", ""))
	}))
	get_tree().quit(0)


func _run_smoke() -> Dictionary:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config = difficulty_config.duplicate(true)
	difficulty_config["use_company_universe_catalog"] = true
	difficulty_config["company_count"] = 100
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	if company_definitions.is_empty():
		return _case_fail("Expected catalog company definitions.")
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	bank_company_id = _first_bank_company_id()
	if bank_company_id.is_empty():
		return _case_fail("Expected catalog roster to include at least one bank company.")
	if not RunState.ensure_company_full_detail(bank_company_id):
		return _case_fail("Could not hydrate full bank detail for %s." % bank_company_id)

	var non_bank_validation: Dictionary = _validate_non_bank_filing_still_renders()
	if not bool(non_bank_validation.get("success", false)):
		return non_bank_validation

	if get_window() != null:
		get_window().size = Vector2i(1440, 900)
	game_root = load("res://scenes/game/GameRoot.tscn").instantiate()
	add_child(game_root)
	await _frames(3)

	if game_root.has_method("_set_active_app"):
		game_root.call("_set_active_app", "stock")
	await _frames(2)
	if game_root.has_method("_on_all_stock_selected"):
		game_root.call("_on_all_stock_selected", bank_company_id)
	await _frames(3)

	var stock_controller: Object = game_root.get("stock_controller") as Object
	if stock_controller == null:
		return _case_fail("Expected GameRoot stock controller.")
	stock_controller.call("_sync_dynamic_refs_from_root")
	var work_tabs: TabContainer = game_root.find_child("WorkTabs", true, false) as TabContainer
	if work_tabs == null:
		return _case_fail("Expected WorkTabs in stock UI.")
	if not _select_tab_by_name(work_tabs, "Financials"):
		return _case_fail("Expected Financials tab in stock UI.")
	stock_controller.call("_refresh_visible_trade_workspace_tab")
	await _frames(3)

	var report_button: Button = game_root.find_child("FinancialStatementReportButton", true, false) as Button
	if report_button == null:
		return _case_fail("Expected View Consolidated Financial Statement button.")
	if report_button.text != "View Consolidated Financial Statement":
		return _case_fail("Unexpected annual filing button text: %s." % report_button.text)
	if not _annual_filing_runtime_cache(stock_controller).is_empty():
		return _case_fail("Annual filing reader should not populate runtime cache before the button is clicked.")
	if _run_state_contains_derived_filing_document():
		return _case_fail("RunState should not contain derived annual filing display data before click.")

	report_button.emit_signal("pressed")
	await _frames(4)
	var first_validation: Dictionary = await _validate_reader_after_open(stock_controller, "miss_built")
	if not bool(first_validation.get("success", false)):
		return first_validation
	var first_document: Dictionary = first_validation.get("document", {}) if typeof(first_validation.get("document", {})) == TYPE_DICTIONARY else {}
	if _annual_filing_runtime_cache(stock_controller).size() != 1:
		return _case_fail("Expected one annual filing document in UI runtime cache after first open.")
	if _run_state_contains_derived_filing_document():
		return _case_fail("RunState should not save/cache derived annual filing display data after click.")

	stock_controller.call("_close_financial_statement_report_overlay")
	await _frames(2)
	report_button.emit_signal("pressed")
	await _frames(4)
	var second_validation: Dictionary = await _validate_reader_after_open(stock_controller, "hit")
	if not bool(second_validation.get("success", false)):
		return second_validation
	var second_document: Dictionary = second_validation.get("document", {}) if typeof(second_validation.get("document", {})) == TYPE_DICTIONARY else {}

	var capture_validation: Dictionary = _validate_capture_and_thesis_survival()
	if not bool(capture_validation.get("success", false)):
		return capture_validation

	return {
		"success": true,
		"payload": _payload(first_document, second_document, capture_validation),
		"company_id": bank_company_id,
		"profile": str(second_document.get("filing_profile_id", "")),
		"section_count": int(second_document.get("visible_filing_section_count", 0)),
		"table_count": int(second_document.get("visible_filing_table_count", 0)),
		"table_row_count": int(second_document.get("visible_filing_table_row_count", 0)),
		"capture_count": int(capture_validation.get("capture_count", 0)),
		"visible_filing_hash": str(second_document.get("visible_filing_hash", ""))
	}


func _validate_reader_after_open(stock_controller: Object, expected_cache_status: String) -> Dictionary:
	var overlay: Control = game_root.find_child("FinancialStatementReportOverlay", true, false) as Control
	if overlay == null or not overlay.visible:
		return _case_fail("Expected financial statement report overlay to be visible.")
	var page_panel: Control = game_root.find_child("FinancialStatementReportPage", true, false) as Control
	var reader_scroll: ScrollContainer = game_root.find_child("FinancialStatementReportScroll", true, false) as ScrollContainer
	var page_scroll: ScrollContainer = game_root.find_child("FinancialStatementReportPageScroll", true, false) as ScrollContainer
	var body: VBoxContainer = game_root.find_child("FinancialStatementReportBody", true, false) as VBoxContainer
	if page_panel == null or reader_scroll == null or page_scroll == null or body == null:
		return _case_fail("Expected A4 reader page, outer reader scroll, page scroll, and body nodes.")
	var document: Dictionary = stock_controller.get("financial_statement_report_document_context")
	if document.is_empty():
		return _case_fail("Expected annual filing document context after opening reader.")
	if str(document.get("cache_status", "")) != expected_cache_status:
		return _case_fail("Expected annual filing cache status %s, got %s." % [expected_cache_status, str(document.get("cache_status", ""))])
	if str(document.get("filing_profile_id", "")) != "bank":
		return _case_fail("Expected bank filing profile in reader document.")
	if not bool(document.get("visible_document_generated", false)):
		return _case_fail("Expected visible annual filing document in reader.")
	if int(document.get("visible_filing_section_count", 0)) < 14:
		return _case_fail("Expected compact bank visible filing sections in reader.")
	if int(document.get("visible_filing_table_count", 0)) < 8:
		return _case_fail("Expected bank reader to render table-heavy filing.")
	if int(document.get("visible_filing_table_row_count", 0)) < 20:
		return _case_fail("Expected bank reader document to include table rows.")
	var balance: Dictionary = document.get("visible_filing_profile_balance", {}) if typeof(document.get("visible_filing_profile_balance", {})) == TYPE_DICTIONARY else {}
	if str(balance.get("filing_profile_id", "")) != "bank" or not bool(balance.get("target_met", false)):
		return _case_fail("Expected bank filing profile balance to be visible and target-met.")
	if int(balance.get("story_note_paragraph_count", 0)) <= 0:
		return _case_fail("Expected bank reader to include story-bearing note paragraphs.")
	var key_parts: Dictionary = document.get("cache_key_parts", {}) if typeof(document.get("cache_key_parts", {})) == TYPE_DICTIONARY else {}
	if str(key_parts.get("filing_profile_version", "")) != str(document.get("filing_profile_version", "")):
		return _case_fail("Expected UI cache key parts to include filing profile version.")
	if str(key_parts.get("source_state_hash", "")) != str(document.get("source_state_hash", "")):
		return _case_fail("Expected UI cache key parts to include source-state hash.")
	if not _string_array(document.get("invalidation_fields", [])).has("filing_profile_version"):
		return _case_fail("Expected annual filing invalidation fields to include filing profile version.")
	if not _string_array(document.get("invalidation_fields", [])).has("source_state_hash"):
		return _case_fail("Expected annual filing invalidation fields to include source-state hash.")
	var visible_document_validation: Dictionary = _validate_visible_document_surface(document)
	if not bool(visible_document_validation.get("success", false)):
		return visible_document_validation

	if str(page_panel.get_meta("page_size_hint", "")) != "A4":
		return _case_fail("Expected financial statement reader page to carry A4 size hint.")
	if page_panel.size.x <= 0.0 or page_panel.size.y <= 0.0:
		return _case_fail("Expected A4 reader page to have layout size.")
	var ratio: float = page_panel.size.y / max(page_panel.size.x, 1.0)
	if ratio < 1.30 or ratio > 1.55:
		return _case_fail("Expected A4-like reader ratio, got %s." % String.num(ratio, 3))
	if page_panel.size.y > reader_scroll.size.y + 2.0:
		return _case_fail("Expected A4 reader page height to fit inside the outer reader viewport. page=%s viewport=%s." % [
			String.num(page_panel.size.y, 1),
			String.num(reader_scroll.size.y, 1)
		])
	if page_panel.get_global_rect().end.y > reader_scroll.get_global_rect().end.y + 2.0:
		return _case_fail("Expected A4 reader page bottom to stay inside the reader viewport.")
	if reader_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_AUTO:
		return _case_fail("Expected outer A4 reader scroll to be automatic as a cutoff guard.")
	if page_scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		return _case_fail("Expected A4 page horizontal scroll to stay disabled.")
	if page_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_AUTO:
		return _case_fail("Expected A4 page vertical scroll to stay automatic.")
	var scroll_bar: VScrollBar = page_scroll.get_v_scroll_bar()
	if scroll_bar == null or scroll_bar.max_value <= page_scroll.size.y:
		return _case_fail("Expected table-heavy bank reader body to be vertically scrollable.")
	if _max_control_width_with_prefix(body, "FinancialStatementReportNoteCompactTableRow") > page_scroll.size.x + 12.0:
		return _case_fail("Expected bank note table rows to remain bounded inside the A4 page scroll.")

	for button_name in REQUIRED_BANK_TOC_BUTTONS:
		var toc_button: Button = game_root.find_child(str(button_name), true, false) as Button
		if toc_button == null:
			return _case_fail("Expected bank-only TOC button %s." % str(button_name))
	var credit_button: Button = game_root.find_child("FinancialStatementReportTocButton_note_bank_credit_risk", true, false) as Button
	if credit_button != null:
		page_scroll.scroll_vertical = 0
		credit_button.emit_signal("pressed")
		await _frames(2)
		if page_scroll.scroll_vertical <= 0:
			return _case_fail("Expected bank-only section navigation to update page scroll.")

	var rendered_table_count: int = _count_nodes_named(body, "FinancialStatementReportNoteCompactTable")
	var rendered_table_row_count: int = _count_nodes_named(body, "FinancialStatementReportNoteCompactTableRow")
	var rendered_chunk_count: int = int(body.get_meta("rendered_chunk_count", 0))
	if rendered_table_count < 8 or rendered_table_row_count < 16 or rendered_chunk_count < 8:
		return _case_fail("Expected bank reader to render bounded table/chunk controls; tables=%d rows=%d chunks=%d." % [rendered_table_count, rendered_table_row_count, rendered_chunk_count])
	if _count_controls(overlay) > 900:
		return _case_fail("Bank reader UI control count exceeded expected bound.")
	return {
		"success": true,
		"document": document.duplicate(true),
		"rendered_table_count": rendered_table_count,
		"rendered_table_row_count": rendered_table_row_count,
		"rendered_chunk_count": rendered_chunk_count
	}


func _validate_capture_and_thesis_survival() -> Dictionary:
	var body: VBoxContainer = game_root.find_child("FinancialStatementReportBody", true, false) as VBoxContainer
	if body == null:
		return _case_fail("Expected reader body for capture validation.")
	var payloads: Dictionary = {}
	_collect_annual_filing_capture_payloads(body, payloads, REQUIRED_CAPTURE_TYPES)
	for capture_type in REQUIRED_CAPTURE_TYPES:
		var payload: Dictionary = payloads.get(str(capture_type), {}) if typeof(payloads.get(str(capture_type), {})) == TYPE_DICTIONARY else {}
		var validation_message: String = _validate_annual_filing_capture_payload(payload, str(capture_type))
		if not validation_message.is_empty():
			return _case_fail(validation_message)

	var thesis_result: Dictionary = GameManager.create_thesis(bank_company_id, "bullish", "position", "Bank Filing Reader UI Smoke")
	if not bool(thesis_result.get("success", false)):
		return _case_fail("Expected thesis creation to succeed for bank reader capture smoke.")
	var thesis_id: String = str(thesis_result.get("thesis", {}).get("id", ""))
	var captured_ids: Array = []
	for capture_type in REQUIRED_CAPTURE_TYPES:
		var payload: Dictionary = payloads.get(str(capture_type), {})
		var capture_result: Dictionary = GameManager.capture_research_evidence(payload)
		if not bool(capture_result.get("success", false)):
			return _case_fail("Expected %s annual filing evidence capture to succeed: %s." % [str(capture_type), str(capture_result.get("message", ""))])
		var evidence: Dictionary = capture_result.get("evidence", {}) if typeof(capture_result.get("evidence", {})) == TYPE_DICTIONARY else {}
		captured_ids.append(str(evidence.get("id", "")))
		var attach_result: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(evidence.get("id", "")), "support")
		if not bool(attach_result.get("success", false)):
			return _case_fail("Expected %s annual filing evidence to attach to thesis." % str(capture_type))
	var direct_payload: Dictionary = payloads.get("note_table_row", {}).duplicate(true)
	direct_payload["interpretation"] = "support"
	var direct_add: Dictionary = GameManager.add_thesis_evidence(thesis_id, direct_payload)
	if not bool(direct_add.get("success", false)):
		return _case_fail("Expected direct annual filing table-row evidence add to succeed.")

	var save_payload: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(save_payload)
	for captured_id_value in captured_ids:
		var loaded_evidence: Dictionary = RunState.get_research_evidence(str(captured_id_value))
		if loaded_evidence.is_empty():
			return _case_fail("Expected captured annual filing evidence %s after save/load." % str(captured_id_value))
		if str(loaded_evidence.get("source_type", "")) != "financial_statement":
			return _case_fail("Expected captured annual filing evidence to preserve source_type after save/load.")
		var loaded_validation: String = _validate_annual_filing_capture_payload(loaded_evidence, str(loaded_evidence.get("filing_capture_type", "")))
		if not loaded_validation.is_empty():
			return _case_fail("Expected loaded annual filing evidence to preserve payload contract: %s" % loaded_validation)
	var loaded_thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	if loaded_thesis.is_empty():
		return _case_fail("Expected bank filing thesis after save/load.")
	var loaded_thesis_evidence: Array = _variant_array(loaded_thesis.get("evidence", []))
	if loaded_thesis_evidence.size() < REQUIRED_CAPTURE_TYPES.size():
		return _case_fail("Expected attached/direct annual filing evidence to survive on thesis after save/load.")
	var thesis_capture_types: Array = []
	for thesis_row_value in loaded_thesis_evidence:
		if typeof(thesis_row_value) != TYPE_DICTIONARY:
			continue
		var thesis_row: Dictionary = thesis_row_value
		if str(thesis_row.get("source_type", "")) != "financial_statement":
			continue
		_append_unique_string(thesis_capture_types, str(thesis_row.get("filing_capture_type", "")))
		var thesis_validation: String = _validate_annual_filing_capture_payload(thesis_row, str(thesis_row.get("filing_capture_type", "")))
		if not thesis_validation.is_empty():
			return _case_fail("Expected thesis annual filing row to preserve payload contract: %s" % thesis_validation)
	for required_capture_type in REQUIRED_CAPTURE_TYPES:
		if not thesis_capture_types.has(str(required_capture_type)):
			return _case_fail("Expected thesis evidence to preserve annual filing capture type %s." % str(required_capture_type))
	return {
		"success": true,
		"capture_count": REQUIRED_CAPTURE_TYPES.size(),
		"captured_ids": captured_ids
	}


func _first_bank_company_id() -> String:
	for id_value in RunState.company_order:
		var candidate_id: String = str(id_value)
		var row: Dictionary = RunState.get_company(candidate_id)
		if _company_looks_like_bank(candidate_id, row):
			return candidate_id
	return ""


func _validate_non_bank_filing_still_renders() -> Dictionary:
	var company_id: String = ""
	for id_value in RunState.company_order:
		var candidate_id: String = str(id_value)
		if candidate_id == bank_company_id:
			continue
		var row: Dictionary = RunState.get_company(candidate_id)
		if not _company_looks_like_bank(candidate_id, row):
			company_id = candidate_id
			break
	if company_id.is_empty():
		return _case_fail("Expected a non-bank company in catalog roster.")
	if not RunState.ensure_company_full_detail(company_id):
		return _case_fail("Could not hydrate full non-bank detail for %s." % company_id)
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, true, true)
	var snapshot: Dictionary = definition.get("financial_statement_snapshot", {}) if typeof(definition.get("financial_statement_snapshot", {})) == TYPE_DICTIONARY else {}
	var annual: Dictionary = snapshot.get("annual_statement", {}) if typeof(snapshot.get("annual_statement", {})) == TYPE_DICTIONARY else {}
	if annual.is_empty():
		return _case_fail("Expected annual statement for non-bank company %s." % company_id)
	var options: Dictionary = _options_from_definition(definition, company_id)
	var document: Dictionary = ANNUAL_FILING_DOCUMENT.build_document_from_statement(annual, int(RunState.run_seed), company_id, options)
	if not bool(document.get("visible_document_generated", false)):
		return _case_fail("Expected non-bank filing to still render visible sections.")
	if str(document.get("filing_profile_id", "")) == "bank":
		return _case_fail("Expected non-bank filing not to use bank profile.")
	if int(document.get("visible_filing_section_count", 0)) <= 0:
		return _case_fail("Expected non-bank visible filing sections.")
	if _string_array(document.get("visible_filing_section_order", [])).has("note_bank_loans_financing"):
		return _case_fail("Expected non-bank filing not to include bank-only loan note section.")
	return _case_ok()


func _company_looks_like_bank(company_id: String, row: Dictionary) -> bool:
	var identity_text: String = " ".join([
		company_id,
		str(row.get("id", "")),
		str(row.get("universe_catalog_id", "")),
		str(row.get("ticker", "")),
		str(row.get("name", "")),
		str(row.get("subsector_id", row.get("subsector", ""))),
		str(row.get("filing_profile_id", ""))
	]).to_lower()
	if _text_has_bank_marker(identity_text):
		return true

	var sector_text: String = str(row.get("sector_id", row.get("sector", ""))).to_lower()
	if sector_text != "finance" and sector_text.find("financial") == -1:
		return false

	var finance_profile_text: String = " ".join([
		sector_text,
		str(row.get("business_summary", "")),
		str(row.get("narrative_tags", [])),
		str(row.get("story_hooks", []))
	]).to_lower()
	return _text_has_bank_marker(finance_profile_text)


func _text_has_bank_marker(text: String) -> bool:
	var lower_text: String = text.to_lower()
	return (
		lower_text.find("bank") != -1 or
		lower_text.find("banking") != -1 or
		lower_text.find("deposit franchise") != -1 or
		lower_text.find("commercial lending") != -1 or
		lower_text.find("sharia") != -1
	)


func _validate_visible_document_surface(document: Dictionary) -> Dictionary:
	if int(document.get("visible_filing_cross_reference_count", 0)) != 0:
		return _case_fail("Expected annual filing reader not to expose cross-reference/classification blocks.")
	for section_value in _variant_array(document.get("visible_filing_sections", [])):
		if typeof(section_value) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_value
		var visible_section_text: String = " ".join([
			str(section.get("title", "")),
			str(section.get("localized_title", ""))
		]).to_lower()
		for forbidden_value in HIDDEN_VISIBLE_TOKENS:
			var forbidden: String = str(forbidden_value)
			if visible_section_text.find(forbidden) != -1:
				return _case_fail("Expected annual filing visible section title fields to hide %s." % forbidden)
		for paragraph_value in _variant_array(section.get("paragraphs", [])):
			if typeof(paragraph_value) != TYPE_DICTIONARY:
				continue
			var paragraph: Dictionary = paragraph_value
			var paragraph_text: String = str(paragraph.get("text", "")).strip_edges().to_lower()
			for forbidden_value in HIDDEN_VISIBLE_TOKENS:
				var forbidden: String = str(forbidden_value)
				if paragraph_text.find(forbidden) != -1:
					return _case_fail("Expected annual filing paragraph visible text to hide %s." % forbidden)
			for phrase_value in FORBIDDEN_GENERIC_PHRASES:
				var phrase: String = str(phrase_value)
				if paragraph_text.find(phrase) != -1:
					return _case_fail("Expected annual filing paragraph to remove generator phrase %s." % phrase)
		for table_value in _variant_array(section.get("compact_tables", [])):
			if typeof(table_value) != TYPE_DICTIONARY:
				continue
			var table: Dictionary = table_value
			for row_value in _variant_array(table.get("rows", [])):
				if typeof(row_value) != TYPE_DICTIONARY:
					continue
				var row: Dictionary = row_value
				if not str(row.get("related_note", "")).strip_edges().is_empty():
					return _case_fail("Expected annual filing table row not to expose related-note metadata.")
				if str(row.get("fy_value", "")).strip_edges().length() > 14:
					return _case_fail("Expected annual filing table values to stay compact: %s." % str(row.get("fy_value", "")))
				var row_text: String = " ".join([
					str(row.get("caption", "")),
					str(row.get("fy_value", ""))
				]).to_lower()
				for forbidden_value in HIDDEN_VISIBLE_TOKENS:
					var forbidden: String = str(forbidden_value)
					if row_text.find(forbidden) != -1:
						return _case_fail("Expected annual filing table row visible text to hide %s." % forbidden)
	return _case_ok()


func _options_from_definition(definition: Dictionary, fallback_company_id: String) -> Dictionary:
	return {
		"company_id": str(definition.get("id", fallback_company_id)),
		"ticker": str(definition.get("ticker", "")),
		"company_name": str(definition.get("name", "")),
		"sector_style_id": str(definition.get("sector_id", definition.get("sector", ""))),
		"sector_id": str(definition.get("sector_id", definition.get("sector", ""))),
		"subsector_id": str(definition.get("subsector_id", definition.get("subsector", ""))),
		"business_summary": str(definition.get("business_summary", "")),
		"moat_tags": _variant_array(definition.get("moat_tags", [])),
		"story_hooks": _variant_array(definition.get("story_hooks", []))
	}


func _select_tab_by_name(tab_container: TabContainer, desired_name: String) -> bool:
	for index in range(tab_container.get_child_count()):
		var child: Node = tab_container.get_child(index)
		if child != null and str(child.name) == desired_name:
			tab_container.current_tab = index
			return true
	return false


func _annual_filing_runtime_cache(stock_controller: Object) -> Dictionary:
	var cache_value: Variant = stock_controller.get("annual_filing_document_cache")
	return cache_value if typeof(cache_value) == TYPE_DICTIONARY else {}


func _run_state_contains_derived_filing_document() -> bool:
	var save_text: String = JSON.stringify(RunState.to_save_dict())
	return (
		save_text.contains("annual_filing_document") or
		save_text.contains("annual_filing_reader_r1") or
		save_text.contains("visible_filing_sections") or
		save_text.contains("visible_filing_sections_by_id")
	)


func _collect_annual_filing_capture_payloads(root: Node, payloads: Dictionary, capture_types: Array) -> void:
	if root == null:
		return
	if root.has_meta("financial_statement_capture_payload"):
		var payload_value: Variant = root.get_meta("financial_statement_capture_payload", {})
		if typeof(payload_value) == TYPE_DICTIONARY:
			var payload: Dictionary = payload_value
			var capture_type: String = str(payload.get("filing_capture_type", "")).strip_edges()
			if capture_types.has(capture_type) and _should_collect_annual_filing_payload(payloads, capture_type, payload):
				payloads[capture_type] = payload.duplicate(true)
	for child in root.get_children():
		_collect_annual_filing_capture_payloads(child, payloads, capture_types)


func _should_collect_annual_filing_payload(payloads: Dictionary, capture_type: String, payload: Dictionary) -> bool:
	if not payloads.has(capture_type):
		return true
	if capture_type != "note_paragraph":
		return false
	var existing: Dictionary = payloads.get(capture_type, {}) if typeof(payloads.get(capture_type, {})) == TYPE_DICTIONARY else {}
	return (
		_string_array(existing.get("source_story_note_fact_ids", [])).is_empty()
		and not _string_array(payload.get("source_story_note_fact_ids", [])).is_empty()
	)


func _validate_annual_filing_capture_payload(payload: Dictionary, expected_capture_type: String) -> String:
	if payload.is_empty():
		return "Expected annual filing %s payload to be populated." % expected_capture_type
	if str(payload.get("source_type", "")) != "financial_statement":
		return "Expected annual filing %s payload source_type to be financial_statement." % expected_capture_type
	if str(payload.get("source_label", "")) != "Annual Filing":
		return "Expected annual filing %s payload source_label to be Annual Filing." % expected_capture_type
	if str(payload.get("filing_capture_type", "")) != expected_capture_type:
		return "Expected annual filing payload type %s, got %s." % [expected_capture_type, str(payload.get("filing_capture_type", ""))]
	if str(payload.get("provenance_group", "")) != "filing":
		return "Expected annual filing %s payload provenance_group to be filing." % expected_capture_type
	if str(payload.get("provenance_label", "")) != "Annual Filing":
		return "Expected annual filing %s payload provenance_label to be Annual Filing." % expected_capture_type
	if str(payload.get("provenance_surface", "")) != "annual_filing_reader":
		return "Expected annual filing %s payload provenance_surface to be annual_filing_reader." % expected_capture_type
	if str(payload.get("source_system_id", "")) != "annual_filing_document":
		return "Expected annual filing %s payload source_system_id to be annual_filing_document." % expected_capture_type
	for required_key_value in ["filing_section_id", "filing_section_label", "filing_excerpt_id", "filing_visible_label", "filing_visible_text", "source_excerpt", "source_id", "label", "value"]:
		var required_key: String = str(required_key_value)
		if str(payload.get(required_key, "")).strip_edges().is_empty():
			return "Expected annual filing %s payload to include %s." % [expected_capture_type, required_key]
	if expected_capture_type == "note_table_row":
		for table_key_value in ["filing_table_id", "filing_table_title", "filing_table_row_id", "filing_table_row_caption", "filing_table_row_value"]:
			var table_key: String = str(table_key_value)
			if str(payload.get(table_key, "")).strip_edges().is_empty():
				return "Expected annual filing table row payload to include %s." % table_key
	if expected_capture_type == "note_paragraph":
		if str(payload.get("story_note_fact_id", "")).strip_edges().is_empty():
			return "Expected annual filing note paragraph payload to preserve hidden story_note_fact_id."
		if _string_array(payload.get("source_story_note_fact_ids", [])).is_empty():
			return "Expected annual filing note paragraph payload to preserve source_story_note_fact_ids."
	var visible_text: String = " ".join([
		str(payload.get("label", "")),
		str(payload.get("value", "")),
		str(payload.get("detail", "")),
		str(payload.get("filing_visible_label", "")),
		str(payload.get("filing_visible_text", "")),
		str(payload.get("source_excerpt", ""))
	]).to_lower()
	for forbidden_value in HIDDEN_VISIBLE_TOKENS:
		var forbidden: String = str(forbidden_value)
		if visible_text.find(forbidden) != -1:
			return "Expected annual filing %s visible payload fields to hide %s." % [expected_capture_type, forbidden]
	return ""


func _count_nodes_with_name_prefix(root: Node, node_name_prefix: String) -> int:
	if root == null:
		return 0
	var count: int = 1 if str(root.name).begins_with(node_name_prefix) else 0
	for child in root.get_children():
		count += _count_nodes_with_name_prefix(child, node_name_prefix)
	return count


func _count_nodes_named(root: Node, node_name: String) -> int:
	if root == null:
		return 0
	var count: int = 1 if str(root.name) == node_name else 0
	for child in root.get_children():
		count += _count_nodes_named(child, node_name)
	return count


func _count_controls(root: Node) -> int:
	if root == null:
		return 0
	var count: int = 1 if root is Control else 0
	for child in root.get_children():
		count += _count_controls(child)
	return count


func _max_control_width_with_prefix(root: Node, node_name_prefix: String) -> float:
	if root == null:
		return 0.0
	var max_width: float = 0.0
	if root is Control and str(root.name).begins_with(node_name_prefix):
		max_width = max(max_width, (root as Control).size.x)
	for child in root.get_children():
		max_width = max(max_width, _max_control_width_with_prefix(child, node_name_prefix))
	return max_width


func _payload(first_document: Dictionary, second_document: Dictionary, capture_validation: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("first=%s:%s:%s" % [
		str(first_document.get("cache_status", "")),
		str(first_document.get("filing_profile_id", "")),
		str(first_document.get("visible_filing_hash", ""))
	])
	lines.append("second=%s:%s:%s" % [
		str(second_document.get("cache_status", "")),
		str(second_document.get("filing_profile_id", "")),
		str(second_document.get("visible_filing_hash", ""))
	])
	lines.append("cache_key=%s" % str(second_document.get("cache_key", "")))
	lines.append("source_hash=%s" % str(second_document.get("source_state_hash", "")))
	lines.append("profile_version=%s" % str(second_document.get("filing_profile_version", "")))
	lines.append("counts=%d:%d:%d:%d" % [
		int(second_document.get("visible_filing_section_count", 0)),
		int(second_document.get("visible_filing_table_count", 0)),
		int(second_document.get("visible_filing_table_row_count", 0)),
		int(second_document.get("visible_filing_display_block_count", 0))
	])
	lines.append("sections=%s" % "|".join(_string_array(second_document.get("visible_filing_section_order", []))))
	lines.append("captures=%d:%s" % [
		int(capture_validation.get("capture_count", 0)),
		"|".join(_string_array(capture_validation.get("captured_ids", [])))
	])
	return "\n".join(lines)


func _variant_array(source: Variant) -> Array:
	return source if typeof(source) == TYPE_ARRAY else []


func _string_array(source: Variant) -> Array:
	var result: Array = []
	if typeof(source) != TYPE_ARRAY:
		return result
	for value in source:
		result.append(str(value))
	return result


func _append_unique_string(rows: Array, value: String) -> Array:
	var text: String = value.strip_edges()
	if text.is_empty() or rows.has(text):
		return rows
	rows.append(text)
	return rows


func _frames(count: int) -> void:
	for _index in range(max(count, 0)):
		await get_tree().process_frame


func _case_ok() -> Dictionary:
	return {"success": true}


func _case_fail(message: String) -> Dictionary:
	return {"success": false, "message": message}


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int(hash_value ^ text.unicode_at(index))
		hash_value = int((hash_value * 16777619) & 0x7fffffff)
	return str(hash_value)


func _fail(message: String) -> void:
	push_error(message)
	printerr("ANNUAL_FILING_BANK_READER_UI_SMOKE_FAIL %s" % message)
	get_tree().quit(1)
