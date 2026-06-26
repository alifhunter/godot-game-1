extends Node

const NEWS_FEED_SYSTEM_SCRIPT := preload("res://systems/NewsFeedSystem.gd")
const TWOOTER_FEED_SYSTEM_SCRIPT := preload("res://systems/TwooterFeedSystem.gd")
const CONTACT_NETWORK_SYSTEM_SCRIPT := preload("res://systems/ContactNetworkSystem.gd")

const RUN_SEED := 20260622
const CATALOG_COMPANY_COUNT := 30
const INNER_CONTACT_ID := "pak_gunawan_personal_lawyer"
const RECOGNITION_SEED_CONTACT_IDS := [
	"journalist_ayu_larasati",
	"budi_supply_chain",
	"andika_brokerage_sales",
	"aryo_port_ops",
	"pak_asep_coal_hauler",
	"aulia_consumer_brand",
	"bagas_fuel_station_mgr",
	"pak_bonar_cement_sales"
]
const EXPECTED_CAPTURE_HASH := "650364612"

var _network_system = CONTACT_NETWORK_SYSTEM_SCRIPT.new()


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var report: Dictionary = _build_report()
	if int(report.get("issue_count", 0)) != 0:
		_fail("Generated surface thesis evidence issues: %s" % JSON.stringify(report.get("issues", [])))
		return
	if EXPECTED_CAPTURE_HASH != "BASELINE_PENDING" and str(report.get("hash", "")) != EXPECTED_CAPTURE_HASH:
		_fail("Generated surface thesis evidence hash changed. expected=%s actual=%s." % [
			EXPECTED_CAPTURE_HASH,
			str(report.get("hash", ""))
		])
		return

	report.erase("payload")
	print("CONTENT_SURFACE_THESIS_EVIDENCE_CAPTURE_OK %s" % JSON.stringify(report))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	_setup_fixed_seed_run()
	var context: Dictionary = _surface_context()
	if context.is_empty():
		return _issue_report(["no_complete_surface_context"], "", "", "")
	var company_id: String = str(context.get("company_id", ""))
	var story_id: String = str(context.get("story_id", ""))

	var news_article: Dictionary = _generated_news_article(context)
	var twooter_post: Dictionary = _generated_twooter_post(context)
	var network_journal: Dictionary = _generated_network_journal(context)
	var filing_payload: Dictionary = _generated_filing_payload(company_id)

	var payloads: Array = [
		_news_capture_payload(news_article),
		_twooter_capture_payload(twooter_post),
		_network_capture_payload(network_journal),
		filing_payload
	]
	var issues: Array[String] = []
	var expected_surfaces: Array = ["company_news", "twooter", "network", "statement_note"]
	for index in range(payloads.size()):
		var payload: Dictionary = payloads[index] if typeof(payloads[index]) == TYPE_DICTIONARY else {}
		if payload.is_empty():
			issues.append("missing_payload:%s" % str(expected_surfaces[index]))
	if not issues.is_empty():
		return _issue_report(issues, company_id, story_id, "")

	var thesis_result: Dictionary = GameManager.create_thesis(company_id, "bullish", "swing", "Generated Surface Evidence Thesis")
	if not bool(thesis_result.get("success", false)):
		return _issue_report(["thesis_create_failed"], company_id, story_id, str(thesis_result.get("message", "")))
	var thesis_id: String = str(thesis_result.get("thesis", {}).get("id", ""))
	var captured_ids: Array[String] = []
	var payload_lines: Array[String] = []
	for index in range(payloads.size()):
		var payload: Dictionary = payloads[index]
		var capture_result: Dictionary = GameManager.capture_research_evidence(payload.duplicate(true))
		if not bool(capture_result.get("success", false)):
			issues.append("capture_failed:%s:%s" % [str(expected_surfaces[index]), str(capture_result.get("message", ""))])
			continue
		var evidence: Dictionary = capture_result.get("evidence", {}) if typeof(capture_result.get("evidence", {})) == TYPE_DICTIONARY else {}
		captured_ids.append(str(evidence.get("id", "")))
		_validate_captured_evidence(str(expected_surfaces[index]), evidence, issues)
		var attach_result: Dictionary = GameManager.attach_research_evidence_to_thesis(thesis_id, str(evidence.get("id", "")), "support")
		if not bool(attach_result.get("success", false)):
			issues.append("attach_failed:%s:%s" % [str(expected_surfaces[index]), str(attach_result.get("message", ""))])
		else:
			_validate_captured_evidence("%s_attached" % str(expected_surfaces[index]), attach_result.get("evidence", {}), issues)
		payload_lines.append(_evidence_payload_line(str(expected_surfaces[index]), evidence))

	var report_result: Dictionary = GameManager.generate_thesis_report(thesis_id)
	if not bool(report_result.get("success", false)):
		issues.append("thesis_report_failed:%s" % str(report_result.get("message", "")))
	elif int(report_result.get("report", {}).get("evidence_count", 0)) < expected_surfaces.size():
		issues.append("thesis_report_missing_evidence_count")

	var save_dict: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(save_dict)
	for evidence_id in captured_ids:
		var saved_evidence: Dictionary = RunState.get_research_evidence(str(evidence_id))
		_validate_captured_evidence("saved_%s" % str(evidence_id), saved_evidence, issues)
	var saved_thesis: Dictionary = RunState.get_player_thesis(thesis_id)
	var saved_evidence_rows: Array = saved_thesis.get("evidence", []) if typeof(saved_thesis.get("evidence", [])) == TYPE_ARRAY else []
	if saved_evidence_rows.size() < expected_surfaces.size():
		issues.append("saved_thesis_missing_generated_evidence")
	for evidence_value in saved_evidence_rows:
		if typeof(evidence_value) == TYPE_DICTIONARY:
			_validate_captured_evidence("saved_attached", evidence_value, issues)

	payload_lines.sort()
	var payload_text: String = "\n".join(payload_lines)
	return {
		"seed": RUN_SEED,
		"company_id": company_id,
		"story_id": story_id,
		"capture_count": captured_ids.size(),
		"saved_attached_count": saved_evidence_rows.size(),
		"issue_count": issues.size(),
		"issues": issues,
		"hash": _stable_hash(payload_text),
		"payload": payload_text
	}


func _setup_fixed_seed_run() -> void:
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	difficulty_config["company_count"] = CATALOG_COMPANY_COUNT
	difficulty_config["use_company_universe_catalog"] = true
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0


func _surface_context() -> Dictionary:
	var rows: Array = []
	var dossier_state: Dictionary = RunState.get_company_story_dossier_state()
	var dossier_index: Dictionary = dossier_state.get("dossier_index", {})
	for dossier_value in dossier_index.values():
		if typeof(dossier_value) != TYPE_DICTIONARY:
			continue
		var dossier: Dictionary = dossier_value
		var news_clue: Dictionary = _first_public_clue(dossier, "news")
		var twooter_clue: Dictionary = _first_public_clue(dossier, "twooter")
		var network_clue: Dictionary = _first_private_network_clue(dossier)
		if news_clue.is_empty() or twooter_clue.is_empty() or network_clue.is_empty():
			continue
		var company_id: String = str(dossier.get("company_id", ""))
		if _generated_filing_payload(company_id).is_empty():
			continue
		rows.append({
			"company_id": company_id,
			"story_id": str(dossier.get("story_id", "")),
			"dossier": dossier.duplicate(true),
			"news_clue": news_clue,
			"twooter_clue": twooter_clue,
			"network_clue": network_clue,
			"score": float(dossier.get("priority", 0.0)) + float(news_clue.get("reliability", 0.0)) + float(twooter_clue.get("reliability", 0.0)) + float(network_clue.get("reliability", 0.0))
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("score", 0.0)), float(b.get("score", 0.0))):
			return str(a.get("story_id", "")) < str(b.get("story_id", ""))
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	if rows.is_empty():
		return {}
	return rows[0].duplicate(true)


func _first_public_clue(dossier: Dictionary, surface_id: String) -> Dictionary:
	for clue_value in dossier.get("public_clues", []):
		if typeof(clue_value) != TYPE_DICTIONARY:
			continue
		var clue: Dictionary = clue_value
		if str(clue.get("surface_id", "")) == surface_id and str(clue.get("visibility", "")) == "public":
			return clue.duplicate(true)
	return {}


func _first_private_network_clue(dossier: Dictionary) -> Dictionary:
	for clue_value in dossier.get("private_clues", []):
		if typeof(clue_value) != TYPE_DICTIONARY:
			continue
		var clue: Dictionary = clue_value
		if str(clue.get("surface_id", "")) == "network" and str(clue.get("visibility", "")) == "private":
			return clue.duplicate(true)
	return {}


func _generated_news_article(context: Dictionary) -> Dictionary:
	var clue: Dictionary = context.get("news_clue", {}) if typeof(context.get("news_clue", {})) == TYPE_DICTIONARY else {}
	RunState.day_index = int(clue.get("earliest_day_index", 0))
	var trade_date: Dictionary = _trade_date_for_day(RunState.day_index)
	var company_rows: Array = GameManager.get_company_market_rows(true)
	var snapshot: Dictionary = NEWS_FEED_SYSTEM_SCRIPT.new().build_news_snapshot(
		RunState,
		DataRepository.get_news_feed_data(),
		company_rows,
		[_market_entry_for_rows(company_rows, trade_date, RunState.day_index)],
		[],
		[],
		[],
		trade_date,
		4
	)
	for feed_value in snapshot.get("feeds", {}).values():
		if typeof(feed_value) != TYPE_DICTIONARY:
			continue
		for article_value in feed_value.get("articles", []):
			if typeof(article_value) != TYPE_DICTIONARY:
				continue
			var article: Dictionary = article_value
			if bool(article.get("generated_content_surface", false)) and str(article.get("story_id", "")) == str(context.get("story_id", "")):
				return article.duplicate(true)
	return {}


func _generated_twooter_post(context: Dictionary) -> Dictionary:
	var clue: Dictionary = context.get("twooter_clue", {}) if typeof(context.get("twooter_clue", {})) == TYPE_DICTIONARY else {}
	RunState.day_index = int(clue.get("earliest_day_index", 0))
	var trade_date: Dictionary = _trade_date_for_day(RunState.day_index)
	var company_rows: Array = GameManager.get_company_market_rows(true)
	var snapshot: Dictionary = TWOOTER_FEED_SYSTEM_SCRIPT.new().build_social_snapshot(
		RunState,
		DataRepository.get_twooter_feed_data(),
		company_rows,
		[_market_entry_for_rows(company_rows, trade_date, RunState.day_index)],
		[],
		[],
		[],
		trade_date,
		4
	)
	for post_value in snapshot.get("posts", []):
		if typeof(post_value) != TYPE_DICTIONARY:
			continue
		var post: Dictionary = post_value
		if bool(post.get("generated_content_surface", false)) and str(post.get("story_id", "")) == str(context.get("story_id", "")):
			return post.duplicate(true)
	return {}


func _generated_network_journal(context: Dictionary) -> Dictionary:
	var company_id: String = str(context.get("company_id", ""))
	var clue: Dictionary = context.get("network_clue", {}) if typeof(context.get("network_clue", {})) == TYPE_DICTIONARY else {}
	RunState.day_index = int(clue.get("earliest_day_index", 0))
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0
	_seed_high_recognition_state(company_id, RunState.day_index)
	var result: Dictionary = _network_system.request_tip(
		RunState,
		DataRepository,
		GameManager.corporate_action_system,
		INNER_CONTACT_ID,
		company_id
	)
	if not bool(result.get("success", false)):
		return {}
	var snapshot: Dictionary = GameManager.get_network_snapshot()
	for row_value in snapshot.get("journal", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if bool(row.get("generated_content_surface", false)) and str(row.get("story_id", "")) == str(context.get("story_id", "")):
			return row.duplicate(true)
	return {}


func _generated_filing_payload(company_id: String) -> Dictionary:
	if company_id.strip_edges().is_empty():
		return {}
	if not RunState.ensure_company_full_detail(company_id):
		return {}
	RunState.refresh_annual_statement_post_start_enrichment(company_id)
	var definition: Dictionary = RunState.get_effective_company_definition(company_id, true, true)
	var snapshot: Dictionary = definition.get("financial_statement_snapshot", {}) if typeof(definition.get("financial_statement_snapshot", {})) == TYPE_DICTIONARY else {}
	var annual: Dictionary = snapshot.get("annual_statement", {}) if typeof(snapshot.get("annual_statement", {})) == TYPE_DICTIONARY else {}
	for note_value in annual.get("notes", []):
		if typeof(note_value) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = note_value
		var fact_ids: Array = _string_array(note.get("fact_ids", []))
		var clue_ids: Array = _string_array(note.get("clue_ids", []))
		if fact_ids.is_empty() or clue_ids.is_empty():
			continue
		var story_ids: Array = _string_array(note.get("source_story_ids", []))
		var note_id: String = str(note.get("note_id", ""))
		var summary: String = str(note.get("summary", "")).strip_edges()
		if summary.is_empty():
			continue
		return {
			"source_type": "financial_statement",
			"category": "financials",
			"company_id": company_id,
			"source_label": "Annual Filing",
			"label": str(note.get("title", "Annual filing note")),
			"value": "Annual note",
			"detail": summary,
			"source_id": "content_surface_filing_%s_%s" % [company_id, _token(note_id)],
			"generated_content_surface": true,
			"generated_surface_id": "statement_note",
			"source_system_id": "company_story_dossier",
			"surface_id": "statement_note",
			"story_id": str(story_ids[0]) if not story_ids.is_empty() else "",
			"visibility": "filing",
			"detail_level": str(note.get("detail_level", "")),
			"fact_ids": fact_ids,
			"clue_ids": clue_ids,
			"source_story_ids": story_ids,
			"note_id": note_id,
			"note_type": str(note.get("note_type", "")),
			"statement_id": str(annual.get("statement_id", "")),
			"statement_period_label": str(annual.get("statement_period_label", "FY2019")),
			"statement_scope": "annual",
			"statement_consolidated": true,
			"filing_capture_type": "note_section",
			"filing_excerpt_type": "note_section",
			"filing_section_id": str(note.get("note_type", "notes")),
			"filing_section_label": str(note.get("title", "Annual filing note")),
			"filing_excerpt_id": note_id,
			"filing_visible_label": str(note.get("title", "Annual filing note")),
			"filing_visible_text": summary,
			"source_excerpt": summary
		}
	return {}


func _news_capture_payload(article: Dictionary) -> Dictionary:
	if article.is_empty():
		return {}
	var payload: Dictionary = {
		"source_type": "news_article",
		"category": "news",
		"source_label": "Generated News",
		"source_id": "content_surface_news_%s" % _token(str(article.get("id", ""))),
		"company_id": str(article.get("target_company_id", "")),
		"ticker": str(article.get("target_ticker", "")),
		"label": str(article.get("headline", "News article")),
		"value": str(article.get("headline", "")),
		"detail": str(article.get("deck", article.get("body", ""))),
		"impact": "mixed"
	}
	return _copy_surface_metadata(payload, article)


func _twooter_capture_payload(post: Dictionary) -> Dictionary:
	if post.is_empty():
		return {}
	var payload: Dictionary = {
		"source_type": "twooter_post",
		"category": "twooter",
		"source_label": "Twooter",
		"source_id": "content_surface_twooter_%s" % _token(str(post.get("id", ""))),
		"company_id": str(post.get("target_company_id", "")),
		"ticker": str(post.get("target_ticker", "")),
		"label": "Twooter post: @%s" % str(post.get("account_handle", "")),
		"value": str(post.get("post_text", "")),
		"detail": str(post.get("context_hint", "")),
		"impact": "mixed"
	}
	return _copy_surface_metadata(payload, post)


func _network_capture_payload(journal: Dictionary) -> Dictionary:
	if journal.is_empty():
		return {}
	var payload: Dictionary = {
		"source_type": "network_journal",
		"category": "network_intel",
		"source_label": "Network",
		"source_id": "content_surface_network_%s" % _token(str(journal.get("id", ""))),
		"company_id": str(journal.get("target_company_id", "")),
		"ticker": str(journal.get("target_ticker", "")),
		"label": str(journal.get("title", "Network tip")),
		"value": str(journal.get("status", "recorded")),
		"detail": str(journal.get("detail", "")),
		"impact": "mixed"
	}
	return _copy_surface_metadata(payload, journal)


func _copy_surface_metadata(payload: Dictionary, source: Dictionary) -> Dictionary:
	for key_value in [
		"generated_content_surface",
		"generated_surface_id",
		"generated_scope_id",
		"source_system_id",
		"story_id",
		"story_family",
		"archetype_id",
		"public_status",
		"stage_id",
		"visibility",
		"detail_level",
		"reliability",
		"leak_risk",
		"source_fact_ids",
		"source_clue_ids",
		"source_company_ids",
		"source_sector_ids",
		"source_quality",
		"directness",
		"original_directness",
		"required_relationship_stage",
		"required_recognition_min",
		"network_relationship",
		"recognition_score"
	]:
		var key: String = str(key_value)
		if source.has(key):
			payload[key] = source.get(key)
	if str(payload.get("surface_id", "")).strip_edges().is_empty() and not str(payload.get("generated_surface_id", "")).strip_edges().is_empty():
		payload["surface_id"] = str(payload.get("generated_surface_id", "")).strip_edges()
	return payload


func _validate_captured_evidence(label: String, row: Dictionary, issues: Array[String]) -> void:
	if row.is_empty():
		issues.append("empty_evidence:%s" % label)
		return
	if not bool(row.get("generated_content_surface", false)):
		issues.append("not_generated:%s" % label)
	if str(row.get("generated_surface_id", "")).strip_edges().is_empty():
		issues.append("missing_generated_surface:%s" % label)
	if str(row.get("source_system_id", "")).strip_edges().is_empty():
		issues.append("missing_source_system:%s" % label)
	if str(row.get("story_id", "")).strip_edges().is_empty():
		issues.append("missing_story_id:%s" % label)
	if _string_array(row.get("source_fact_ids", [])).is_empty():
		issues.append("missing_source_fact_ids:%s" % label)
	if _string_array(row.get("source_clue_ids", [])).is_empty():
		issues.append("missing_source_clue_ids:%s" % label)
	if _visible_copy_leaks_hidden_ids(row):
		issues.append("visible_hidden_id_leak:%s" % label)


func _visible_copy_leaks_hidden_ids(row: Dictionary) -> bool:
	var text: String = " ".join([
		str(row.get("label", "")),
		str(row.get("value", "")),
		str(row.get("detail", ""))
	]).to_lower()
	for term in ["story|", "fact|", "clue|", "truth_state", "source_quality"]:
		if text.contains(term):
			return true
	return false


func _seed_high_recognition_state(company_id: String, day_index: int) -> void:
	RunState.player_portfolio["cash"] = 5000000.0
	var holdings: Dictionary = {}
	var seeded_holdings: int = 0
	for company_id_value in RunState.company_order:
		if seeded_holdings >= 6:
			break
		var holding_company_id: String = str(company_id_value)
		var company: Dictionary = RunState.get_company(holding_company_id)
		var current_price: float = max(float(company.get("current_price", 0.0)), 1.0)
		holdings[holding_company_id] = {
			"company_id": holding_company_id,
			"shares": max(100, int(floor(200000000.0 / current_price / 100.0)) * 100),
			"average_price": current_price
		}
		seeded_holdings += 1
	RunState.player_portfolio["holdings"] = holdings

	var contacts: Dictionary = RunState.get_network_contacts()
	var discoveries: Dictionary = RunState.get_network_discoveries()
	for contact_id_value in RECOGNITION_SEED_CONTACT_IDS:
		var contact_id: String = str(contact_id_value)
		contacts[contact_id] = {
			"contact_id": contact_id,
			"met": true,
			"relationship": 45,
			"met_day_index": day_index,
			"last_source_type": "content_surface_thesis_test"
		}
		discoveries[contact_id] = _discovery_row(contact_id, company_id, day_index)
	contacts[INNER_CONTACT_ID] = {
		"contact_id": INNER_CONTACT_ID,
		"met": true,
		"relationship": 72,
		"met_day_index": day_index,
		"last_source_type": "content_surface_thesis_test"
	}
	discoveries[INNER_CONTACT_ID] = _discovery_row(INNER_CONTACT_ID, company_id, day_index)
	RunState.set_network_contacts(contacts)
	RunState.set_network_discoveries(discoveries)


func _discovery_row(contact_id: String, company_id: String, day_index: int) -> Dictionary:
	return {
		"contact_id": contact_id,
		"discovered": true,
		"source_type": "content_surface_thesis_test",
		"source_id": "generated_surface_thesis_test",
		"target_company_id": company_id,
		"target_company_ids": [company_id],
		"lead_score": 100,
		"day_index": day_index
	}


func _market_entry_for_rows(company_rows: Array, trade_date: Dictionary, day_index: int) -> Dictionary:
	var total_change: float = 0.0
	var advancers: int = 0
	var decliners: int = 0
	var biggest_winner: Dictionary = {}
	var biggest_loser: Dictionary = {}
	for row_value in company_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var change_pct: float = float(row.get("daily_change_pct", 0.0))
		total_change += change_pct
		if change_pct >= 0.0:
			advancers += 1
		else:
			decliners += 1
		if biggest_winner.is_empty() or change_pct > float(biggest_winner.get("daily_change_pct", -999.0)):
			biggest_winner = row.duplicate(true)
		if biggest_loser.is_empty() or change_pct < float(biggest_loser.get("daily_change_pct", 999.0)):
			biggest_loser = row.duplicate(true)
	return {
		"day_index": day_index,
		"trade_date": trade_date.duplicate(true),
		"average_change_pct": total_change / float(max(company_rows.size(), 1)),
		"advancers": advancers,
		"decliners": decliners,
		"biggest_winner": biggest_winner,
		"biggest_loser": biggest_loser
	}


func _trade_date_for_day(day_index: int) -> Dictionary:
	return {
		"weekday": 1 + (day_index % 5),
		"day": 1 + (day_index % 28),
		"month": 1 + int(day_index / 28) % 12,
		"year": 2020,
		"day_index": day_index
	}


func _evidence_payload_line(surface_id: String, row: Dictionary) -> String:
	return "%s|source=%s|story=%s|facts=%s|clues=%s|label=%s|value=%s" % [
		surface_id,
		str(row.get("source_type", "")),
		str(row.get("story_id", "")),
		_array_payload(_string_array(row.get("source_fact_ids", []))),
		_array_payload(_string_array(row.get("source_clue_ids", []))),
		str(row.get("label", "")),
		str(row.get("value", ""))
	]


func _issue_report(issues: Array, company_id: String, story_id: String, payload: String) -> Dictionary:
	return {
		"seed": RUN_SEED,
		"company_id": company_id,
		"story_id": story_id,
		"capture_count": 0,
		"saved_attached_count": 0,
		"issue_count": issues.size(),
		"issues": issues,
		"hash": _stable_hash(payload),
		"payload": payload
	}


func _string_array(source_value: Variant) -> Array:
	var source_array: Array = source_value if typeof(source_value) == TYPE_ARRAY else [source_value]
	var result: Array = []
	var seen: Dictionary = {}
	for item_value in source_array:
		var item: String = str(item_value).strip_edges()
		if item.is_empty() or seen.has(item):
			continue
		seen[item] = true
		result.append(item)
	return result


func _array_payload(values: Array) -> String:
	var rows: Array = []
	for value in values:
		rows.append(str(value))
	rows.sort()
	return ",".join(rows)


func _token(value: String) -> String:
	var token: String = value.strip_edges().to_lower()
	for ch in ["|", " ", "/", "\\", ":", ".", ",", "(", ")"]:
		token = token.replace(ch, "_")
	while token.contains("__"):
		token = token.replace("__", "_")
	return token.strip_edges().trim_prefix("_").trim_suffix("_")


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int((hash_value ^ text.unicode_at(index)) * 16777619) & 0xFFFFFFFF
	return str(hash_value)


func _fail(message: String) -> void:
	push_error(message)
	print("CONTENT_SURFACE_THESIS_EVIDENCE_CAPTURE_FAIL %s" % message)
	get_tree().quit(1)
