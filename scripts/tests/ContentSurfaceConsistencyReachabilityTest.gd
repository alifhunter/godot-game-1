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
const EXPECTED_CONSISTENCY_HASH := "2369856367"

var _network_system = CONTACT_NETWORK_SYSTEM_SCRIPT.new()


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var report: Dictionary = _build_report()
	if int(report.get("issue_count", 0)) != 0:
		_fail("Generated content surface consistency issues: %s" % JSON.stringify(report.get("issues", [])))
		return
	if EXPECTED_CONSISTENCY_HASH != "BASELINE_PENDING" and str(report.get("hash", "")) != EXPECTED_CONSISTENCY_HASH:
		_fail("Generated content surface consistency hash changed. expected=%s actual=%s." % [
			EXPECTED_CONSISTENCY_HASH,
			str(report.get("hash", ""))
		])
		return

	report.erase("payload")
	print("CONTENT_SURFACE_CONSISTENCY_REACHABILITY_OK %s" % JSON.stringify(report))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	_setup_fixed_seed_run()
	var context: Dictionary = _surface_context()
	if context.is_empty():
		return _issue_report(["no_complete_surface_context"], "", "", "", 0)
	var company_id: String = str(context.get("company_id", ""))
	var story_id: String = str(context.get("story_id", ""))

	var news_article: Dictionary = _generated_news_article(context)
	var twooter_post: Dictionary = _generated_twooter_post(context)
	var network_journal: Dictionary = _generated_network_journal(context)
	var filing_payload: Dictionary = _generated_filing_payload(company_id, story_id)

	var generated_rows: Array = [
		_surface_row("news", news_article),
		_surface_row("twooter", twooter_post),
		_surface_row("network", network_journal),
		_surface_row("statement_note", filing_payload)
	]
	var issues: Array[String] = []
	var payload_lines: Array[String] = []
	var expected_surface_keys: Array = ["news", "twooter", "network", "statement_note"]
	for index in range(generated_rows.size()):
		var row: Dictionary = generated_rows[index] if typeof(generated_rows[index]) == TYPE_DICTIONARY else {}
		if row.is_empty():
			issues.append("missing_surface:%s" % str(expected_surface_keys[index]))
			continue
		_validate_surface_row(row, context, issues)
		payload_lines.append(_surface_payload_line(row))

	var reachability: Dictionary = _validate_reachability(generated_rows, context, filing_payload, issues)
	for fact_id in _sorted_keys(reachability.get("fact_paths", {})):
		payload_lines.append("fact_path|%s|%s" % [
			str(fact_id),
			_array_payload(reachability.get("fact_paths", {}).get(fact_id, []))
		])
	for clue_id in _sorted_keys(reachability.get("clue_paths", {})):
		payload_lines.append("clue_path|%s|%s" % [
			str(clue_id),
			_array_payload(reachability.get("clue_paths", {}).get(clue_id, []))
		])

	var thesis_capture_count: int = _validate_thesis_capture_paths(generated_rows, issues)
	payload_lines.append("thesis_capture_count|%d" % thesis_capture_count)

	payload_lines.sort()
	var payload: String = "\n".join(payload_lines)
	return {
		"seed": RUN_SEED,
		"company_id": company_id,
		"story_id": story_id,
		"surface_count": generated_rows.size(),
		"important_fact_count": int(reachability.get("important_fact_count", 0)),
		"important_clue_count": int(reachability.get("important_clue_count", 0)),
		"thesis_capture_count": thesis_capture_count,
		"issue_count": issues.size(),
		"issues": issues,
		"hash": _stable_hash(payload),
		"payload": payload
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
		var story_id: String = str(dossier.get("story_id", ""))
		var filing_payload: Dictionary = _generated_filing_payload(company_id, story_id)
		if filing_payload.is_empty():
			continue
		rows.append({
			"company_id": company_id,
			"story_id": story_id,
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


func _generated_filing_payload(company_id: String, story_id: String) -> Dictionary:
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
		var story_ids: Array = _string_array(note.get("source_story_ids", []))
		if not story_ids.has(story_id):
			continue
		var fact_ids: Array = _string_array(note.get("fact_ids", []))
		var clue_ids: Array = _string_array(note.get("clue_ids", []))
		if fact_ids.is_empty() or clue_ids.is_empty():
			continue
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
			"source_id": "content_surface_consistency_filing_%s_%s" % [company_id, _token(note_id)],
			"generated_content_surface": true,
			"generated_surface_id": "statement_note",
			"source_system_id": "company_story_dossier",
			"surface_id": "statement_note",
			"story_id": story_id,
			"visibility": "filing",
			"detail_level": str(note.get("detail_level", "")),
			"fact_ids": fact_ids,
			"clue_ids": clue_ids,
			"source_fact_ids": fact_ids.duplicate(true),
			"source_clue_ids": clue_ids.duplicate(true),
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


func _surface_row(surface_key: String, source: Dictionary) -> Dictionary:
	if source.is_empty():
		return {}
	var row: Dictionary = source.duplicate(true)
	row["surface_key"] = surface_key
	row["surface_id"] = str(row.get("surface_id", row.get("generated_surface_id", surface_key)))
	if str(row.get("generated_surface_id", "")).strip_edges().is_empty():
		row["generated_surface_id"] = str(row.get("surface_id", surface_key))
	row["visible_text"] = _visible_text_for_surface(surface_key, row)
	return row


func _visible_text_for_surface(surface_key: String, row: Dictionary) -> String:
	match surface_key:
		"news":
			return " ".join([
				str(row.get("headline", "")),
				str(row.get("deck", "")),
				str(row.get("body", ""))
			])
		"twooter":
			return " ".join([
				str(row.get("post_text", "")),
				str(row.get("context_hint", ""))
			])
		"network":
			return " ".join([
				str(row.get("title", "")),
				str(row.get("detail", "")),
				str(row.get("status", ""))
			])
		_:
			return " ".join([
				str(row.get("label", "")),
				str(row.get("value", "")),
				str(row.get("detail", "")),
				str(row.get("source_excerpt", ""))
			])


func _validate_surface_row(row: Dictionary, context: Dictionary, issues: Array[String]) -> void:
	var surface_key: String = str(row.get("surface_key", ""))
	var surface_id: String = str(row.get("generated_surface_id", ""))
	if not bool(row.get("generated_content_surface", false)):
		issues.append("not_generated:%s" % surface_key)
	if str(row.get("source_system_id", "")) != "company_story_dossier":
		issues.append("bad_source_system:%s:%s" % [surface_key, str(row.get("source_system_id", ""))])
	if str(row.get("story_id", "")) != str(context.get("story_id", "")):
		issues.append("story_mismatch:%s:%s" % [surface_key, str(row.get("story_id", ""))])
	if _source_fact_ids_for_row(row).is_empty():
		issues.append("missing_fact_trace:%s" % surface_key)
	if _source_clue_ids_for_row(row).is_empty():
		issues.append("missing_clue_trace:%s" % surface_key)
	if str(row.get("visibility", "")).strip_edges().is_empty():
		issues.append("missing_visibility:%s" % surface_key)
	if surface_key == "news" and not (surface_id in ["company_news", "sector_news", "macro_news"]):
		issues.append("unexpected_news_surface:%s" % surface_id)
	if surface_key == "twooter" and surface_id != "twooter":
		issues.append("unexpected_twooter_surface:%s" % surface_id)
	if surface_key == "network" and surface_id != "network":
		issues.append("unexpected_network_surface:%s" % surface_id)
	if surface_key == "statement_note" and surface_id != "statement_note":
		issues.append("unexpected_statement_surface:%s" % surface_id)

	var private_clue_ids: Array = _private_clue_ids(context)
	if surface_key in ["news", "twooter"]:
		if str(row.get("visibility", "")) != "public":
			issues.append("public_surface_not_public:%s:%s" % [surface_key, str(row.get("visibility", ""))])
		if float(row.get("leak_risk", 0.0)) > 0.0:
			issues.append("public_surface_leak_risk:%s:%s" % [surface_key, str(row.get("leak_risk", 0.0))])
		if _arrays_intersect(_source_clue_ids_for_row(row), private_clue_ids):
			issues.append("public_surface_private_clue:%s" % surface_key)
		if row.has("source_quality"):
			issues.append("public_surface_source_quality_metadata:%s" % surface_key)
		if _visible_copy_leaks_hidden_tokens(row):
			issues.append("public_visible_hidden_token:%s" % surface_key)
		if _visible_copy_has_direct_trade_instruction(row):
			issues.append("public_visible_trade_instruction:%s" % surface_key)
	elif surface_key == "network":
		if str(row.get("visibility", "")) != "private":
			issues.append("network_surface_not_private:%s" % str(row.get("visibility", "")))
		if not _arrays_intersect(_source_clue_ids_for_row(row), private_clue_ids):
			issues.append("network_surface_missing_private_clue_path")
		if _visible_copy_leaks_hidden_tokens(row):
			issues.append("network_visible_hidden_token")
	elif surface_key == "statement_note":
		if str(row.get("visibility", "")) != "filing":
			issues.append("statement_surface_not_filing:%s" % str(row.get("visibility", "")))
		if _visible_copy_leaks_hidden_tokens(row):
			issues.append("statement_visible_hidden_token")


func _validate_reachability(generated_rows: Array, context: Dictionary, filing_payload: Dictionary, issues: Array[String]) -> Dictionary:
	var known_fact_ids: Array = _known_fact_ids(context, filing_payload)
	var important_fact_ids: Array = _important_fact_ids(context, filing_payload)
	var important_clue_ids: Array = _important_clue_ids(context, filing_payload)
	var fact_paths: Dictionary = {}
	var clue_paths: Dictionary = {}
	for row_value in generated_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if row.is_empty():
			continue
		var surface_key: String = str(row.get("surface_key", ""))
		for fact_id_value in _source_fact_ids_for_row(row):
			var fact_id: String = str(fact_id_value)
			if not known_fact_ids.has(fact_id):
				issues.append("unknown_fact_path:%s:%s" % [surface_key, fact_id])
			if not fact_paths.has(fact_id):
				fact_paths[fact_id] = []
			fact_paths[fact_id].append(surface_key)
		for clue_id_value in _source_clue_ids_for_row(row):
			var clue_id: String = str(clue_id_value)
			if not clue_paths.has(clue_id):
				clue_paths[clue_id] = []
			clue_paths[clue_id].append(surface_key)

	if important_fact_ids.size() < 3:
		issues.append("too_few_important_facts:%d" % important_fact_ids.size())
	if important_clue_ids.size() < 4:
		issues.append("too_few_important_clues:%d" % important_clue_ids.size())
	for fact_id_value in important_fact_ids:
		var fact_id: String = str(fact_id_value)
		if not fact_paths.has(fact_id) or _string_array(fact_paths.get(fact_id, [])).is_empty():
			issues.append("unreachable_important_fact:%s" % fact_id)
	for clue_id_value in important_clue_ids:
		var clue_id: String = str(clue_id_value)
		if not clue_paths.has(clue_id) or _string_array(clue_paths.get(clue_id, [])).is_empty():
			issues.append("unreachable_important_clue:%s" % clue_id)

	for fact_id in fact_paths.keys():
		fact_paths[fact_id] = _string_array(fact_paths.get(fact_id, []))
	for clue_id in clue_paths.keys():
		clue_paths[clue_id] = _string_array(clue_paths.get(clue_id, []))
	return {
		"important_fact_count": important_fact_ids.size(),
		"important_clue_count": important_clue_ids.size(),
		"fact_paths": fact_paths,
		"clue_paths": clue_paths
	}


func _validate_thesis_capture_paths(generated_rows: Array, issues: Array[String]) -> int:
	var capture_count: int = 0
	for row_value in generated_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if row.is_empty():
			continue
		var payload: Dictionary = _capture_payload_for_surface(row)
		if payload.is_empty():
			issues.append("empty_capture_payload:%s" % str(row.get("surface_key", "")))
			continue
		var result: Dictionary = GameManager.capture_research_evidence(payload)
		if not bool(result.get("success", false)):
			issues.append("capture_failed:%s:%s" % [str(row.get("surface_key", "")), str(result.get("message", ""))])
			continue
		var evidence: Dictionary = result.get("evidence", {}) if typeof(result.get("evidence", {})) == TYPE_DICTIONARY else {}
		if not bool(evidence.get("generated_content_surface", false)):
			issues.append("captured_not_generated:%s" % str(row.get("surface_key", "")))
		if _source_fact_ids_for_row(evidence).is_empty():
			issues.append("captured_missing_fact_trace:%s" % str(row.get("surface_key", "")))
		if _source_clue_ids_for_row(evidence).is_empty():
			issues.append("captured_missing_clue_trace:%s" % str(row.get("surface_key", "")))
		if _visible_copy_leaks_hidden_tokens(evidence):
			issues.append("captured_visible_hidden_token:%s" % str(row.get("surface_key", "")))
		capture_count += 1
	return capture_count


func _capture_payload_for_surface(row: Dictionary) -> Dictionary:
	var surface_key: String = str(row.get("surface_key", ""))
	var payload: Dictionary = {}
	match surface_key:
		"news":
			payload = {
				"source_type": "news_article",
				"category": "news",
				"source_label": "Generated News",
				"source_id": "content_surface_consistency_news_%s" % _token(str(row.get("id", ""))),
				"company_id": str(row.get("target_company_id", "")),
				"ticker": str(row.get("target_ticker", "")),
				"label": str(row.get("headline", "News article")),
				"value": str(row.get("headline", "")),
				"detail": str(row.get("deck", row.get("body", ""))),
				"impact": "mixed"
			}
		"twooter":
			payload = {
				"source_type": "twooter_post",
				"category": "twooter",
				"source_label": "Twooter",
				"source_id": "content_surface_consistency_twooter_%s" % _token(str(row.get("id", ""))),
				"company_id": str(row.get("target_company_id", "")),
				"ticker": str(row.get("target_ticker", "")),
				"label": "Twooter post: @%s" % str(row.get("account_handle", "")),
				"value": str(row.get("post_text", "")),
				"detail": str(row.get("context_hint", "")),
				"impact": "mixed"
			}
		"network":
			payload = {
				"source_type": "network_journal",
				"category": "network_intel",
				"source_label": "Network",
				"source_id": "content_surface_consistency_network_%s" % _token(str(row.get("id", ""))),
				"company_id": str(row.get("target_company_id", "")),
				"ticker": str(row.get("target_ticker", "")),
				"label": str(row.get("title", "Network tip")),
				"value": str(row.get("status", "recorded")),
				"detail": str(row.get("detail", "")),
				"impact": "mixed"
			}
		_:
			payload = {
				"source_type": "financial_statement",
				"category": "financials",
				"source_label": "Annual Filing",
				"source_id": str(row.get("source_id", "")),
				"company_id": str(row.get("company_id", "")),
				"label": str(row.get("label", "Annual filing note")),
				"value": str(row.get("value", "Annual note")),
				"detail": str(row.get("detail", "")),
				"impact": "mixed"
			}
	return _copy_surface_metadata(payload, row)


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
		"recognition_score",
		"fact_ids",
		"clue_ids",
		"source_story_ids",
		"note_id",
		"statement_id",
		"statement_period_label",
		"statement_scope",
		"statement_consolidated",
		"filing_capture_type",
		"filing_excerpt_type",
		"filing_section_id",
		"filing_section_label",
		"filing_excerpt_id",
		"filing_visible_label",
		"filing_visible_text",
		"source_excerpt"
	]:
		var key: String = str(key_value)
		if source.has(key):
			payload[key] = source.get(key)
	if str(payload.get("surface_id", "")).strip_edges().is_empty() and not str(payload.get("generated_surface_id", "")).strip_edges().is_empty():
		payload["surface_id"] = str(payload.get("generated_surface_id", "")).strip_edges()
	return payload


func _known_fact_ids(context: Dictionary, filing_payload: Dictionary) -> Array:
	var dossier: Dictionary = context.get("dossier", {}) if typeof(context.get("dossier", {})) == TYPE_DICTIONARY else {}
	var ids: Array = []
	for fact_value in dossier.get("cause_facts", []):
		if typeof(fact_value) == TYPE_DICTIONARY:
			ids.append(str(fact_value.get("fact_id", "")))
	for clue_value in dossier.get("public_clues", []):
		if typeof(clue_value) == TYPE_DICTIONARY:
			ids.append_array(_string_array(clue_value.get("fact_ids", [])))
	for clue_value in dossier.get("private_clues", []):
		if typeof(clue_value) == TYPE_DICTIONARY:
			ids.append_array(_string_array(clue_value.get("fact_ids", [])))
	for clue_value in dossier.get("statement_clues", []):
		if typeof(clue_value) == TYPE_DICTIONARY:
			ids.append_array(_string_array(clue_value.get("fact_ids", [])))
	ids.append_array(_source_fact_ids_for_row(filing_payload))
	return _string_array(ids)


func _important_fact_ids(context: Dictionary, filing_payload: Dictionary) -> Array:
	var ids: Array = []
	for key in ["news_clue", "twooter_clue", "network_clue"]:
		var clue: Dictionary = context.get(key, {}) if typeof(context.get(key, {})) == TYPE_DICTIONARY else {}
		ids.append_array(_string_array(clue.get("fact_ids", [])))
	ids.append_array(_source_fact_ids_for_row(filing_payload))
	return _string_array(ids)


func _important_clue_ids(context: Dictionary, filing_payload: Dictionary) -> Array:
	var ids: Array = []
	for key in ["news_clue", "twooter_clue", "network_clue"]:
		var clue: Dictionary = context.get(key, {}) if typeof(context.get(key, {})) == TYPE_DICTIONARY else {}
		ids.append(str(clue.get("clue_id", "")))
	ids.append_array(_source_clue_ids_for_row(filing_payload))
	return _string_array(ids)


func _private_clue_ids(context: Dictionary) -> Array:
	var dossier: Dictionary = context.get("dossier", {}) if typeof(context.get("dossier", {})) == TYPE_DICTIONARY else {}
	var ids: Array = []
	for clue_value in dossier.get("private_clues", []):
		if typeof(clue_value) == TYPE_DICTIONARY:
			ids.append(str(clue_value.get("clue_id", "")))
	return _string_array(ids)


func _source_fact_ids_for_row(row: Dictionary) -> Array:
	var ids: Array = _string_array(row.get("source_fact_ids", []))
	if ids.is_empty():
		ids = _string_array(row.get("fact_ids", []))
	return ids


func _source_clue_ids_for_row(row: Dictionary) -> Array:
	var ids: Array = _string_array(row.get("source_clue_ids", []))
	if ids.is_empty():
		ids = _string_array(row.get("clue_ids", []))
	return ids


func _visible_copy_leaks_hidden_tokens(row: Dictionary) -> bool:
	var text: String = str(row.get("visible_text", ""))
	if text.strip_edges().is_empty():
		text = " ".join([
			str(row.get("label", "")),
			str(row.get("value", "")),
			str(row.get("detail", "")),
			str(row.get("source_excerpt", "")),
			str(row.get("filing_visible_text", ""))
		])
	text = text.to_lower()
	for term in [
		"story|",
		"fact|",
		"clue|",
		"truth_state",
		"source_quality",
		"relationship_stage",
		"required_relationship",
		"leak_risk"
	]:
		if text.contains(term):
			return true
	return false


func _visible_copy_has_direct_trade_instruction(row: Dictionary) -> bool:
	var text: String = str(row.get("visible_text", "")).to_lower()
	for term in ["buy today", "sell today", "strong buy", "strong sell", "hold until", "all in"]:
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
			"last_source_type": "content_surface_consistency_test"
		}
		discoveries[contact_id] = _discovery_row(contact_id, company_id, day_index)
	contacts[INNER_CONTACT_ID] = {
		"contact_id": INNER_CONTACT_ID,
		"met": true,
		"relationship": 72,
		"met_day_index": day_index,
		"last_source_type": "content_surface_consistency_test"
	}
	discoveries[INNER_CONTACT_ID] = _discovery_row(INNER_CONTACT_ID, company_id, day_index)
	RunState.set_network_contacts(contacts)
	RunState.set_network_discoveries(discoveries)


func _discovery_row(contact_id: String, company_id: String, day_index: int) -> Dictionary:
	return {
		"contact_id": contact_id,
		"discovered": true,
		"source_type": "content_surface_consistency_test",
		"source_id": "generated_surface_consistency_test",
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


func _surface_payload_line(row: Dictionary) -> String:
	return "%s|id=%s|visibility=%s|story=%s|facts=%s|clues=%s|text=%s" % [
		str(row.get("surface_key", "")),
		str(row.get("generated_surface_id", "")),
		str(row.get("visibility", "")),
		str(row.get("story_id", "")),
		_array_payload(_source_fact_ids_for_row(row)),
		_array_payload(_source_clue_ids_for_row(row)),
		_compact_text(str(row.get("visible_text", "")))
	]


func _issue_report(issues: Array, company_id: String, story_id: String, payload: String, thesis_capture_count: int) -> Dictionary:
	return {
		"seed": RUN_SEED,
		"company_id": company_id,
		"story_id": story_id,
		"surface_count": 0,
		"important_fact_count": 0,
		"important_clue_count": 0,
		"thesis_capture_count": thesis_capture_count,
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
	result.sort()
	return result


func _arrays_intersect(left: Array, right: Array) -> bool:
	var right_set: Dictionary = {}
	for value in right:
		right_set[str(value)] = true
	for value in left:
		if right_set.has(str(value)):
			return true
	return false


func _sorted_keys(source: Dictionary) -> Array:
	var rows: Array = []
	for key in source.keys():
		rows.append(str(key))
	rows.sort()
	return rows


func _array_payload(values: Array) -> String:
	var rows: Array = []
	for value in values:
		rows.append(str(value))
	rows.sort()
	return ",".join(rows)


func _compact_text(value: String) -> String:
	var text: String = value.strip_edges()
	while text.contains("\n"):
		text = text.replace("\n", " ")
	while text.contains("  "):
		text = text.replace("  ", " ")
	if text.length() > 160:
		return text.substr(0, 160)
	return text


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
	print("CONTENT_SURFACE_CONSISTENCY_REACHABILITY_FAIL %s" % message)
	get_tree().quit(1)
