extends Node

const TWOOTER_FEED_SYSTEM_SCRIPT := preload("res://systems/TwooterFeedSystem.gd")

const RUN_SEED := 20260622
const CATALOG_COMPANY_COUNT := 30
const EXPECTED_PREVIEW_HASH := "2185776077"
const REQUIRED_GENERATED_SCOPES := ["company", "sector", "macro"]


class MockDossierRunState:
	extends RefCounted

	var state: Dictionary = {}

	func get_company_story_dossier_state() -> Dictionary:
		return state.duplicate(true)


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)

	var report: Dictionary = _build_report()
	if int(report.get("generated_post_count", 0)) <= 0:
		_fail("Expected generated dossier Twooter preview posts.")
		return
	if int(report.get("authored_post_count", 0)) <= 0:
		_fail("Expected existing authored/ambient Twooter posts to remain present.")
		return
	if int(report.get("issue_count", 0)) != 0:
		_fail("Generated Twooter preview issues: %s" % JSON.stringify(report.get("issues", [])))
		return
	for scope_id in REQUIRED_GENERATED_SCOPES:
		if int(report.get("scope_counts", {}).get(scope_id, 0)) <= 0:
			_fail("Expected generated Twooter scope '%s' to appear." % scope_id)
			return
	if int(report.get("account_voice_count", 0)) < 2:
		_fail("Expected generated Twooter posts to use at least two account voices.")
		return
	if int(report.get("confidence_label_count", 0)) < 2:
		_fail("Expected generated Twooter posts to vary public confidence labels by account type.")
		return
	if EXPECTED_PREVIEW_HASH != "BASELINE_PENDING" and str(report.get("hash", "")) != EXPECTED_PREVIEW_HASH:
		_fail("Generated Twooter preview fingerprint changed. expected=%s actual=%s." % [
			EXPECTED_PREVIEW_HASH,
			str(report.get("hash", ""))
		])
		return

	report.erase("payload")
	print("CONTENT_SURFACE_TWOOTER_PREVIEW_OK %s" % JSON.stringify(report))
	get_tree().quit(0)


func _build_report() -> Dictionary:
	_setup_fixed_seed_run()
	var target_day_index: int = _best_public_twooter_day_index()
	if target_day_index < 0:
		return {
			"seed": RUN_SEED,
			"generated_post_count": 0,
			"authored_post_count": 0,
			"issue_count": 1,
			"issues": ["no_public_twooter_clue_day"],
			"scope_counts": {},
			"hash": "",
			"payload": ""
		}
	RunState.day_index = target_day_index
	var trade_date: Dictionary = {
		"weekday": 1 + (target_day_index % 5),
		"day": 1 + (target_day_index % 28),
		"month": 1 + int(target_day_index / 28) % 12,
		"year": 2020,
		"day_index": target_day_index
	}
	var company_rows: Array = GameManager.get_company_market_rows(true)
	var market_history: Array = [_market_entry_for_rows(company_rows, trade_date, target_day_index)]
	var snapshot: Dictionary = TWOOTER_FEED_SYSTEM_SCRIPT.new().build_social_snapshot(
		RunState,
		DataRepository.get_twooter_feed_data(),
		company_rows,
		market_history,
		[],
		[],
		[],
		trade_date,
		4
	)
	var synthetic_snapshot: Dictionary = _build_synthetic_macro_snapshot()

	var generated_posts: Array = []
	var authored_post_count: int = 0
	for snapshot_value in [snapshot, synthetic_snapshot]:
		if typeof(snapshot_value) != TYPE_DICTIONARY:
			continue
		var snapshot_row: Dictionary = snapshot_value
		for post_value in snapshot_row.get("posts", []):
			if typeof(post_value) != TYPE_DICTIONARY:
				continue
			var post: Dictionary = post_value
			if bool(post.get("generated_content_surface", false)):
				generated_posts.append(post)
			else:
				authored_post_count += 1

	var issues: Array[String] = []
	var scope_counts: Dictionary = {}
	var voice_counts: Dictionary = {}
	var confidence_counts: Dictionary = {}
	var payload_lines: Array[String] = []
	for post_value in generated_posts:
		var post: Dictionary = post_value
		_validate_generated_post(post, issues, scope_counts, voice_counts, confidence_counts)
		payload_lines.append(_post_payload_line(post))

	payload_lines.sort()
	var payload: String = "\n".join(payload_lines)
	return {
		"seed": RUN_SEED,
		"day_index": target_day_index,
		"generated_post_count": generated_posts.size(),
		"authored_post_count": authored_post_count,
		"scope_counts": _sorted_int_dictionary(scope_counts),
		"account_voice_count": voice_counts.size(),
		"confidence_label_count": confidence_counts.size(),
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


func _best_public_twooter_day_index() -> int:
	var day_counts: Dictionary = {}
	var dossier_state: Dictionary = RunState.get_company_story_dossier_state()
	var dossier_index: Dictionary = dossier_state.get("dossier_index", {})
	for dossier_value in dossier_index.values():
		if typeof(dossier_value) != TYPE_DICTIONARY:
			continue
		var dossier: Dictionary = dossier_value
		for clue_value in dossier.get("public_clues", []):
			if typeof(clue_value) != TYPE_DICTIONARY:
				continue
			var clue: Dictionary = clue_value
			if str(clue.get("surface_id", "")) != "twooter" or str(clue.get("visibility", "")) != "public":
				continue
			var earliest: int = int(clue.get("earliest_day_index", 0))
			var latest: int = int(clue.get("latest_day_index", earliest))
			for day_index in range(earliest, latest + 1):
				day_counts[day_index] = int(day_counts.get(day_index, 0)) + 1
	var best_day: int = -1
	var best_count: int = 0
	for day_value in day_counts.keys():
		var day_index: int = int(day_value)
		var count: int = int(day_counts.get(day_index, 0))
		if count > best_count:
			best_count = count
			best_day = day_index
	return best_day


func _build_synthetic_macro_snapshot() -> Dictionary:
	var story_id: String = "story|synthetic_energy|commodity_tailwind|twooter_preview"
	var clue_id: String = "clue|%s|twooter|01" % story_id
	var fact_id: String = "fact|%s|commodity|coal" % story_id
	var synthetic_run_state := MockDossierRunState.new()
	synthetic_run_state.state = {
		"dossier_index": {
			story_id: {
				"story_id": story_id,
				"company_id": "synthetic_energy",
				"ticker": "SYN",
				"archetype_id": "commodity_tailwind",
				"story_family": "company_story",
				"public_status": "rumor",
				"stage_id": "public_chatter",
				"priority": 0.72,
				"public_clues": [{
					"clue_id": clue_id,
					"fact_ids": [fact_id],
					"surface_id": "twooter",
					"visibility": "public",
					"earliest_day_index": 0,
					"latest_day_index": 16,
					"detail_level": "low",
					"reliability": 0.44,
					"tone": "positive",
					"leak_risk": 0.0
				}],
				"cause_facts": [
					{
						"fact_id": "fact|%s|sector|energy" % story_id,
						"fact_type": "sector",
						"source_id": "energy",
						"direction": "positive",
						"strength": 0.52,
						"related_company_ids": ["synthetic_energy"],
						"related_sector_ids": ["energy"]
					},
					{
						"fact_id": fact_id,
						"fact_type": "commodity",
						"source_id": "coal",
						"direction": "positive",
						"strength": 0.72,
						"related_company_ids": ["synthetic_energy"],
						"related_sector_ids": ["energy"]
					}
				]
			}
		}
	}
	var trade_date: Dictionary = {
		"weekday": 1,
		"day": 6,
		"month": 1,
		"year": 2020,
		"day_index": 5
	}
	var company_rows: Array = [{
		"id": "synthetic_energy",
		"ticker": "SYN",
		"name": "Synthetic Energy",
		"sector_id": "energy",
		"sector_name": "Energy",
		"current_price": 1000.0,
		"previous_close": 990.0,
		"daily_change_pct": 0.0101
	}]
	var market_history: Array = [{
		"day_index": 5,
		"trade_date": trade_date.duplicate(true),
		"average_change_pct": 0.004,
		"advancers": 1,
		"decliners": 0,
		"biggest_winner": company_rows[0].duplicate(true),
		"biggest_loser": company_rows[0].duplicate(true)
	}]
	return TWOOTER_FEED_SYSTEM_SCRIPT.new().build_social_snapshot(
		synthetic_run_state,
		DataRepository.get_twooter_feed_data(),
		company_rows,
		market_history,
		[],
		[],
		[],
		trade_date,
		4
	)


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


func _validate_generated_post(
	post: Dictionary,
	issues: Array[String],
	scope_counts: Dictionary,
	voice_counts: Dictionary,
	confidence_counts: Dictionary
) -> void:
	var post_id: String = str(post.get("id", ""))
	var scope_id: String = str(post.get("generated_scope_id", ""))
	_increment(scope_counts, scope_id)
	_increment(voice_counts, str(post.get("account_voice", "")))
	_increment(confidence_counts, str(post.get("public_confidence_label", "")))
	if str(post.get("generated_surface_id", "")) != "twooter":
		issues.append("bad_surface:%s" % post_id)
	if str(post.get("source_system_id", "")) != "company_story_dossier":
		issues.append("bad_source_system:%s" % post_id)
	if str(post.get("visibility", "")) != "public":
		issues.append("bad_visibility:%s" % post_id)
	if float(post.get("leak_risk", 1.0)) > 0.0:
		issues.append("bad_leak_risk:%s" % post_id)
	if str(post.get("story_id", "")).is_empty():
		issues.append("missing_story_id:%s" % post_id)
	if _string_array(post.get("source_fact_ids", [])).is_empty():
		issues.append("missing_fact_ids:%s" % post_id)
	if _string_array(post.get("source_clue_ids", [])).is_empty():
		issues.append("missing_clue_ids:%s" % post_id)
	if _visible_copy_leaks_private_terms(post):
		issues.append("visible_private_leak:%s" % post_id)


func _visible_copy_leaks_private_terms(post: Dictionary) -> bool:
	var thread_text: String = " ".join(_string_array(post.get("thread_lines", [])))
	var visible_text: String = " ".join([
		str(post.get("post_text", "")),
		str(post.get("context_hint", "")),
		thread_text
	]).to_lower()
	var forbidden_terms: Array = [
		"truth_state",
		"source_quality",
		"relationship_stage",
		"inner_circle",
		"private clue",
		"network clue",
		"clue|",
		"fact|",
		"story|"
	]
	for term in forbidden_terms:
		if visible_text.contains(str(term)):
			return true
	return false


func _post_payload_line(post: Dictionary) -> String:
	return "%s|%s|%s|%s|%s|%s|facts=%s|clues=%s" % [
		str(post.get("account_id", "")),
		str(post.get("account_voice", "")),
		str(post.get("generated_scope_id", "")),
		str(post.get("public_confidence_label", "")),
		str(post.get("story_id", "")),
		str(post.get("post_text", "")),
		_array_payload(_string_array(post.get("source_fact_ids", []))),
		_array_payload(_string_array(post.get("source_clue_ids", [])))
	]


func _string_array(source_value: Variant) -> Array:
	var source_array: Array = []
	if typeof(source_value) == TYPE_ARRAY:
		source_array = source_value
	else:
		source_array = [source_value]
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
	var string_values: Array = []
	for value in values:
		string_values.append(str(value))
	string_values.sort()
	return ",".join(string_values)


func _sorted_int_dictionary(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var keys: Array = source.keys()
	keys.sort()
	for key_value in keys:
		var key: String = str(key_value)
		result[key] = int(source.get(key_value, 0))
	return result


func _increment(counts: Dictionary, key: String) -> void:
	if key.strip_edges().is_empty():
		key = "unknown"
	counts[key] = int(counts.get(key, 0)) + 1


func _stable_hash(text: String) -> String:
	var hash_value: int = 2166136261
	for index in range(text.length()):
		hash_value = int((hash_value ^ text.unicode_at(index)) * 16777619) & 0xFFFFFFFF
	return str(hash_value)


func _fail(message: String) -> void:
	push_error(message)
	print("CONTENT_SURFACE_TWOOTER_PREVIEW_FAIL %s" % message)
	get_tree().quit(1)
