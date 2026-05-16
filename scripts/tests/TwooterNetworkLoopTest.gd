extends Node

const RUN_SEED := 516026


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0

	var context: Dictionary = _discover_news_source_context()
	if context.is_empty():
		_fail("Twooter Network loop expected at least one News article to discover a source with a generated Twooter account.")
		return

	var article: Dictionary = context.get("article", {})
	var lead: Dictionary = context.get("lead", {})
	var contact_id: String = str(lead.get("id", ""))
	var account_id: String = str(lead.get("twooter_account_id", ""))
	var handle: String = str(lead.get("twooter_handle", ""))
	var article_id: String = str(article.get("id", ""))
	var news_discovery: Dictionary = RunState.get_network_discoveries().get(contact_id, {})
	if (
		contact_id.is_empty()
		or article_id.is_empty()
		or not account_id.begins_with("network_")
		or not handle.begins_with("@")
		or str(news_discovery.get("source_type", "")) != "news"
		or str(news_discovery.get("source_id", "")) != article_id
	):
		_fail("Twooter Network loop expected the News lead to preserve contact id, article id, generated account id, and handle context.")
		return

	var social_snapshot: Dictionary = GameManager.get_twooter_snapshot()
	var source_account: Dictionary = _account_by_id(social_snapshot.get("accounts", []), account_id)
	var social_profile: Dictionary = source_account.get("social_profile", {}) if typeof(source_account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	if (
		source_account.is_empty()
		or str(social_profile.get("account_origin", "")) != "network_contact"
		or not bool(social_profile.get("network_source", false))
		or str(social_profile.get("network_contact_id", "")) != contact_id
		or str(social_profile.get("target_company_id", "")) != str(news_discovery.get("target_company_id", ""))
		or str(social_profile.get("target_ticker", "")).strip_edges().is_empty()
	):
		_fail("Twooter Network loop expected generated source accounts to carry Network-contact and target-company context.")
		return

	var first_thread: Dictionary = GameManager.get_twooter_message_thread(account_id)
	var source_option: Dictionary = _enabled_option_by_action(first_thread.get("dialog_options", []), "message_check_in")
	if (
		source_option.is_empty()
		or not str(source_option.get("tree_id", "")).begins_with("network_")
		or _contains_malformed_social_template_text(str(source_option.get("player_text", "")))
	):
		_fail("Twooter Network loop expected a clean News/source-specific first DM option.")
		return

	var ap_before_source: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var source_result: Dictionary = GameManager.send_twooter_message(
		account_id,
		"message_check_in",
		str(source_option.get("thesis_id", "")),
		str(source_option.get("player_text", ""))
	)
	var ap_after_source: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var source_rows: Array = _message_rows(account_id)
	var source_discovery: Dictionary = RunState.get_network_discoveries().get(contact_id, {})
	var source_contact_runtime: Dictionary = RunState.get_network_contacts().get(contact_id, {})
	if (
		not bool(source_result.get("success", false))
		or not bool(source_result.get("network_changed", false))
		or ap_after_source != ap_before_source + 1
		or source_rows.size() < 2
		or str(source_rows[source_rows.size() - 2].get("sender", "")) != "player"
		or str(source_rows[source_rows.size() - 1].get("sender", "")) != "account"
		or bool(source_contact_runtime.get("met", false))
		or str(source_discovery.get("source_type", "")) != "twooter"
		or str(source_discovery.get("source_label", "")) != "Twooter handle from News"
		or str(source_discovery.get("twooter_origin", "")) != "news_handle"
		or str(source_discovery.get("twooter_account_id", "")) != account_id
		or str(source_discovery.get("twooter_handle", "")) != handle
		or str(source_discovery.get("twooter_action_id", "")) != "message_check_in"
		or not bool(source_discovery.get("source_only", false))
	):
		_fail("Twooter Network loop expected a source-only DM to spend AP, write message rows, and create provenance-rich Network discovery without marking the contact met.")
		return

	var source_network_snapshot: Dictionary = GameManager.get_network_snapshot()
	var source_discovery_row: Dictionary = _row_by_id(source_network_snapshot.get("discoveries", []), contact_id)
	var source_discovery_journal: Dictionary = _journal_row(source_network_snapshot.get("journal", []), contact_id, "twooter_discovery")
	if (
		source_discovery_row.is_empty()
		or str(source_discovery_row.get("source_label", "")).strip_edges().is_empty()
		or str(source_discovery_row.get("source_note", "")).find(handle) == -1
		or str(source_discovery_row.get("twooter_handle", "")) != handle
		or not bool(source_discovery_row.get("source_only", false))
		or source_discovery_journal.is_empty()
		or str(source_discovery_journal.get("title", "")).find("Twooter handle from News") == -1
		or str(source_discovery_journal.get("detail", "")).find(handle) == -1
	):
		_fail("Twooter Network loop expected Network snapshot discovery and journal rows to expose Twooter provenance.")
		return

	var followup_thread: Dictionary = GameManager.get_twooter_message_thread(account_id)
	var promote_option: Dictionary = _first_enabled_non_check_in_option(followup_thread.get("dialog_options", []))
	if promote_option.is_empty():
		_fail("Twooter Network loop expected a follow-up private action after the source-only DM.")
		return
	var promote_text: String = str(promote_option.get("player_text", ""))
	if _contains_malformed_social_template_text(promote_text):
		_fail("Twooter Network loop expected the follow-up DM option to avoid malformed template text.")
		return
	var ap_before_promote: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var journal_before_promote: int = RunState.get_network_tip_journal().size()
	var promote_result: Dictionary = GameManager.send_twooter_message(
		account_id,
		str(promote_option.get("action_id", promote_option.get("id", ""))),
		str(promote_option.get("thesis_id", "")),
		promote_text
	)
	var ap_after_promote: int = int(GameManager.get_daily_action_snapshot().get("used", 0))
	var promoted_contact_runtime: Dictionary = RunState.get_network_contacts().get(contact_id, {})
	var promoted_discovery: Dictionary = RunState.get_network_discoveries().get(contact_id, {})
	var promoted_network_snapshot: Dictionary = GameManager.get_network_snapshot()
	var promoted_contact_row: Dictionary = _row_by_id(promoted_network_snapshot.get("contacts", []), contact_id)
	var promoted_journal: Dictionary = _journal_row(promoted_network_snapshot.get("journal", []), contact_id, "twooter")
	if (
		not bool(promote_result.get("success", false))
		or not bool(promote_result.get("network_changed", false))
		or ap_after_promote != ap_before_promote + 1
		or RunState.get_network_tip_journal().size() <= journal_before_promote
		or not bool(promoted_contact_runtime.get("met", false))
		or str(promoted_discovery.get("source_type", "")) != "twooter"
		or str(promoted_discovery.get("twooter_account_id", "")) != account_id
		or str(promoted_discovery.get("twooter_handle", "")) != handle
		or promoted_contact_row.is_empty()
		or str(promoted_contact_row.get("twooter_handle", "")) != handle
		or promoted_journal.is_empty()
		or str(promoted_journal.get("detail", "")).find(handle) == -1
	):
		_fail("Twooter Network loop expected a follow-up DM to promote the source into Network while preserving Twooter provenance.")
		return

	var visible_social_text: String = "%s\n%s\n%s\n%s" % [
		str(source_option.get("player_text", "")),
		str(source_result.get("reply_text", "")),
		promote_text,
		str(promote_result.get("reply_text", ""))
	]
	if _contains_malformed_social_template_text(visible_social_text):
		_fail("Twooter Network loop expected source conversation text to avoid unresolved or malformed templates.")
		return

	print("TWOOTER_NETWORK_LOOP_OK contact=%s account=%s action=%s" % [
		contact_id,
		account_id,
		str(promote_option.get("action_id", promote_option.get("id", "")))
	])
	get_tree().quit(0)


func _discover_news_source_context() -> Dictionary:
	var news_snapshot: Dictionary = GameManager.get_news_snapshot()
	var articles: Array = _news_articles(news_snapshot)
	for article_value in articles:
		if typeof(article_value) != TYPE_DICTIONARY:
			continue
		var article: Dictionary = article_value
		var discovered: Array = GameManager.discover_network_contacts_from_article(article)
		for lead_value in discovered:
			if typeof(lead_value) != TYPE_DICTIONARY:
				continue
			var lead: Dictionary = lead_value
			var account_id: String = str(lead.get("twooter_account_id", ""))
			var handle: String = str(lead.get("twooter_handle", ""))
			if not account_id.begins_with("network_") or not handle.begins_with("@"):
				continue
			return {
				"article": article.duplicate(true),
				"lead": lead.duplicate(true)
			}
	return {}


func _news_articles(news_snapshot: Dictionary) -> Array:
	var rows: Array = []
	var feeds: Dictionary = news_snapshot.get("feeds", {}) if typeof(news_snapshot.get("feeds", {})) == TYPE_DICTIONARY else {}
	for feed_value in feeds.values():
		if typeof(feed_value) != TYPE_DICTIONARY:
			continue
		var feed: Dictionary = feed_value
		for article_value in feed.get("articles", []):
			if typeof(article_value) == TYPE_DICTIONARY:
				rows.append(article_value)
	return rows


func _account_by_id(accounts: Array, account_id: String) -> Dictionary:
	for account_value in accounts:
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value
		if str(account.get("id", "")) == account_id:
			return account
	return {}


func _enabled_option_by_action(options: Array, action_id: String) -> Dictionary:
	for option_value in options:
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		var option_action_id: String = str(option.get("action_id", option.get("id", "")))
		if option_action_id == action_id and bool(option.get("enabled", true)):
			return option
	return {}


func _first_enabled_non_check_in_option(options: Array) -> Dictionary:
	for option_value in options:
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		var option_action_id: String = str(option.get("action_id", option.get("id", "")))
		if option_action_id != "message_check_in" and bool(option.get("enabled", true)):
			return option
	return {}


func _message_rows(account_id: String) -> Array:
	var social_state: Dictionary = RunState.get_twooter_social_state()
	var messages: Dictionary = social_state.get("messages", {}) if typeof(social_state.get("messages", {})) == TYPE_DICTIONARY else {}
	var thread: Dictionary = messages.get(account_id, {}) if typeof(messages.get(account_id, {})) == TYPE_DICTIONARY else {}
	return thread.get("rows", []).duplicate(true) if typeof(thread.get("rows", [])) == TYPE_ARRAY else []


func _row_by_id(rows: Array, contact_id: String) -> Dictionary:
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("id", "")) == contact_id or str(row.get("contact_id", "")) == contact_id:
			return row
	return {}


func _journal_row(rows: Array, contact_id: String, row_type: String) -> Dictionary:
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("contact_id", "")) == contact_id and str(row.get("type", "")) == row_type:
			return row
	return {}


func _contains_malformed_social_template_text(text: String) -> bool:
	var lower_text: String = text.to_lower()
	return (
		text.find("{") >= 0
		or text.find("}") >= 0
		or lower_text.find("for ,") != -1
		or lower_text.find("for .") != -1
		or lower_text.find("for  ") != -1
	)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
