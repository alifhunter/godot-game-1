extends Node

const RUN_SEED := 516126
const REACTION_ACTION_ID := "network_followup_reaction"


func _ready() -> void:
	DataRepository.reload_all()
	SaveManager.set_autosave_enabled(false)
	var difficulty_config: Dictionary = GameManager.get_difficulty_config(GameManager.DEFAULT_DIFFICULTY_ID)
	var company_definitions: Array = GameManager.build_company_roster(RUN_SEED, difficulty_config)
	RunState.setup_new_run(RUN_SEED, company_definitions, difficulty_config, false)
	GameManager.simulate_opening_session(false)
	RunState.daily_action_day_index = RunState.day_index
	RunState.daily_actions_used = 0

	var source_context: Dictionary = _create_twooter_source_memory()
	if source_context.is_empty():
		_fail("Network consequence test expected a News -> Twooter source memory.")
		return
	var network_context: Dictionary = _create_network_tip_memory(str(source_context.get("contact_id", "")))
	if network_context.is_empty():
		_fail("Network consequence test expected a regular Network tip memory.")
		return

	var source_tip_id: String = str(source_context.get("tip_id", ""))
	var source_contact_id: String = str(source_context.get("contact_id", ""))
	var source_account_id: String = str(source_context.get("account_id", ""))
	var network_tip_id: String = str(network_context.get("tip_id", ""))
	var network_contact_id: String = str(network_context.get("contact_id", ""))
	var network_account_id: String = str(network_context.get("account_id", ""))
	var legacy_tip_id: String = _add_legacy_tip_without_reaction_fields(network_context)
	var pending_save: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(pending_save)
	if (
		bool(RunState.get_network_tip_journal().get(source_tip_id, {}).get("reaction_sent", false))
		or bool(RunState.get_network_tip_journal().get(network_tip_id, {}).get("reaction_sent", false))
	):
		_fail("Network consequence test expected pending reactions to survive save/load as unsent.")
		return

	for _day in range(5):
		_advance_test_day()
		var journal: Dictionary = RunState.get_network_tip_journal()
		if bool(journal.get(source_tip_id, {}).get("reaction_sent", false)) and bool(journal.get(network_tip_id, {}).get("reaction_sent", false)):
			break

	var reacted_journal: Dictionary = RunState.get_network_tip_journal()
	var source_tip: Dictionary = reacted_journal.get(source_tip_id, {})
	var network_tip: Dictionary = reacted_journal.get(network_tip_id, {})
	if not _reaction_record_is_complete(source_tip) or not _reaction_record_is_complete(network_tip):
		_fail("Network consequence test expected both source and Network memories to receive complete reaction fields.")
		return
	if bool(reacted_journal.get(legacy_tip_id, {}).get("reaction_sent", false)):
		_fail("Network consequence test expected legacy rows without reaction fields to stay quiet.")
		return
	if int(GameManager.get_daily_action_snapshot().get("used", 0)) != 0:
		_fail("Network consequence test expected inbound reaction DMs to spend no AP.")
		return
	if _reaction_message_count(source_account_id) != 1 or _reaction_message_count(network_account_id) != 1:
		_fail("Network consequence test expected exactly one inbound Twooter reaction DM per memory.")
		return
	if _player_reaction_message_count(source_account_id) > 0 or _player_reaction_message_count(network_account_id) > 0:
		_fail("Network consequence test expected reactions to be account-only messages, not fake player replies.")
		return

	var network_snapshot: Dictionary = GameManager.get_network_snapshot()
	var source_row: Dictionary = _network_row_for_contact(network_snapshot, source_contact_id)
	var network_row: Dictionary = _network_row_for_contact(network_snapshot, network_contact_id)
	if (
		str(source_row.get("last_reaction_note", "")).strip_edges().is_empty()
		or str(network_row.get("last_reaction_note", "")).strip_edges().is_empty()
		or _journal_reaction_count(network_snapshot.get("journal", []), source_contact_id) != 1
		or _journal_reaction_count(network_snapshot.get("journal", []), network_contact_id) != 1
	):
		_fail("Network consequence test expected Network rows and journal to expose social reaction summaries.")
		return
	var network_delta: int = int(network_tip.get("reaction_relationship_delta", 0))
	var source_delta: int = int(source_tip.get("reaction_relationship_delta", 0))
	if abs(network_delta) > 1 or source_delta < 0 or source_delta > 2:
		_fail("Network consequence test expected modest coaching-scale relationship deltas.")
		return

	var sent_save: Dictionary = RunState.to_save_dict()
	RunState.load_from_dict(sent_save)
	if (
		not bool(RunState.get_network_tip_journal().get(source_tip_id, {}).get("reaction_sent", false))
		or not bool(RunState.get_network_tip_journal().get(network_tip_id, {}).get("reaction_sent", false))
		or _reaction_message_count(source_account_id) != 1
		or _reaction_message_count(network_account_id) != 1
	):
		_fail("Network consequence test expected sent reactions and inbound DMs to survive save/load.")
		return

	print("NETWORK_CONSEQUENCE_FOLLOWUP_OK source=%s network=%s" % [source_contact_id, network_contact_id])
	get_tree().quit(0)


func _create_twooter_source_memory() -> Dictionary:
	var news_snapshot: Dictionary = GameManager.get_news_snapshot()
	for article_value in _news_articles(news_snapshot):
		if typeof(article_value) != TYPE_DICTIONARY:
			continue
		var article: Dictionary = article_value
		var leads: Array = GameManager.discover_network_contacts_from_article(article)
		for lead_value in leads:
			if typeof(lead_value) != TYPE_DICTIONARY:
				continue
			var lead: Dictionary = lead_value
			var account_id: String = str(lead.get("twooter_account_id", ""))
			var contact_id: String = str(lead.get("id", ""))
			if account_id.is_empty() or contact_id.is_empty():
				continue
			var thread: Dictionary = GameManager.get_twooter_message_thread(account_id)
			var option: Dictionary = _enabled_option_by_action(thread.get("dialog_options", []), "message_check_in")
			if option.is_empty():
				continue
			RunState.daily_action_day_index = RunState.day_index
			RunState.daily_actions_used = 0
			var result: Dictionary = GameManager.send_twooter_message(
				account_id,
				"message_check_in",
				str(option.get("thesis_id", "")),
				str(option.get("player_text", ""))
			)
			if not bool(result.get("success", false)):
				continue
			var tip_id: String = _latest_twooter_tip_id(contact_id)
			if tip_id.is_empty():
				continue
			return {
				"contact_id": contact_id,
				"account_id": account_id,
				"tip_id": tip_id
			}
	return {}


func _create_network_tip_memory(excluded_contact_id: String) -> Dictionary:
	for company_id_value in RunState.company_order:
		var company_id: String = str(company_id_value)
		var leads: Array = GameManager.discover_network_contacts_for_company(company_id)
		for lead_value in leads:
			if typeof(lead_value) != TYPE_DICTIONARY:
				continue
			var lead: Dictionary = lead_value
			var contact_id: String = str(lead.get("id", ""))
			if contact_id.is_empty() or contact_id == excluded_contact_id:
				continue
			var contacts: Dictionary = RunState.get_network_contacts()
			var runtime: Dictionary = contacts.get(contact_id, {})
			runtime["met"] = true
			runtime["relationship"] = max(int(runtime.get("relationship", 25)), 45)
			contacts[contact_id] = runtime
			RunState.set_network_contacts(contacts)
			RunState.daily_action_day_index = RunState.day_index
			RunState.daily_actions_used = 0
			var result: Dictionary = GameManager.request_contact_tip(contact_id, company_id)
			if not bool(result.get("success", false)):
				continue
			var tip_id: String = _latest_network_tip_id(contact_id)
			var account_id: String = _twooter_account_id_for_contact(contact_id)
			if tip_id.is_empty() or account_id.is_empty():
				continue
			return {
				"contact_id": contact_id,
				"account_id": account_id,
				"tip_id": tip_id
			}
	return {}


func _add_legacy_tip_without_reaction_fields(context: Dictionary) -> String:
	var source_tip_id: String = str(context.get("tip_id", ""))
	var journal: Dictionary = RunState.get_network_tip_journal()
	var legacy_tip: Dictionary = journal.get(source_tip_id, {}).duplicate(true)
	var legacy_tip_id: String = "legacy_no_reaction_%s" % source_tip_id
	legacy_tip["id"] = legacy_tip_id
	legacy_tip["status"] = "resolved"
	legacy_tip["created_day_index"] = RunState.day_index - 10
	legacy_tip["resolve_day_index"] = RunState.day_index - 7
	legacy_tip["resolved_day_index"] = RunState.day_index - 7
	legacy_tip["outcome_label"] = "Useful read"
	legacy_tip["outcome_note"] = "Legacy row from before Network reactions existed."
	for key in [
		"reaction_due_day_index",
		"reaction_sent",
		"reaction_label",
		"reaction_note",
		"reaction_relationship_delta",
		"reaction_reliability_delta",
		"reaction_twooter_account_id",
		"reaction_twooter_handle"
	]:
		legacy_tip.erase(key)
	journal[legacy_tip_id] = legacy_tip
	RunState.set_network_tip_journal(journal)
	return legacy_tip_id


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


func _enabled_option_by_action(options: Array, action_id: String) -> Dictionary:
	for option_value in options:
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		var option_action_id: String = str(option.get("action_id", option.get("id", "")))
		if option_action_id == action_id and bool(option.get("enabled", true)):
			return option
	return {}


func _latest_twooter_tip_id(contact_id: String) -> String:
	var best_id: String = ""
	var best_day: int = -9999
	for tip_id_value in RunState.get_network_tip_journal().keys():
		var tip_id: String = str(tip_id_value)
		var tip: Dictionary = RunState.get_network_tip_journal().get(tip_id, {})
		if str(tip.get("contact_id", "")) != contact_id or str(tip.get("journal_type", "")) != "twooter_social":
			continue
		if int(tip.get("created_day_index", 0)) >= best_day:
			best_day = int(tip.get("created_day_index", 0))
			best_id = tip_id
	return best_id


func _latest_network_tip_id(contact_id: String) -> String:
	var best_id: String = ""
	var best_day: int = -9999
	for tip_id_value in RunState.get_network_tip_journal().keys():
		var tip_id: String = str(tip_id_value)
		var tip: Dictionary = RunState.get_network_tip_journal().get(tip_id, {})
		if str(tip.get("contact_id", "")) != contact_id or str(tip.get("journal_type", "")) == "twooter_social":
			continue
		if int(tip.get("created_day_index", 0)) >= best_day:
			best_day = int(tip.get("created_day_index", 0))
			best_id = tip_id
	return best_id


func _twooter_account_id_for_contact(contact_id: String) -> String:
	for account_value in GameManager.get_twooter_snapshot().get("accounts", []):
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value
		var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
		if str(profile.get("network_contact_id", "")) == contact_id:
			return str(account.get("id", ""))
	return ""


func _reaction_record_is_complete(tip: Dictionary) -> bool:
	return (
		bool(tip.get("reaction_sent", false))
		and int(tip.get("reaction_day_index", -1)) == RunState.day_index
		and not str(tip.get("reaction_label", "")).strip_edges().is_empty()
		and not str(tip.get("reaction_note", "")).strip_edges().is_empty()
		and not str(tip.get("reaction_twooter_account_id", "")).strip_edges().is_empty()
	)


func _reaction_message_count(account_id: String) -> int:
	return _message_count(account_id, "account", REACTION_ACTION_ID)


func _player_reaction_message_count(account_id: String) -> int:
	return _message_count(account_id, "player", REACTION_ACTION_ID)


func _message_count(account_id: String, sender: String, action_id: String) -> int:
	var social_state: Dictionary = RunState.get_twooter_social_state()
	var messages: Dictionary = social_state.get("messages", {}) if typeof(social_state.get("messages", {})) == TYPE_DICTIONARY else {}
	var thread: Dictionary = messages.get(account_id, {}) if typeof(messages.get(account_id, {})) == TYPE_DICTIONARY else {}
	var count: int = 0
	for row_value in thread.get("rows", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("sender", "")) == sender and str(row.get("action_id", "")) == action_id:
			count += 1
	return count


func _network_row_for_contact(network_snapshot: Dictionary, contact_id: String) -> Dictionary:
	for bucket_name in ["contacts", "discoveries"]:
		for row_value in network_snapshot.get(bucket_name, []):
			if typeof(row_value) != TYPE_DICTIONARY:
				continue
			var row: Dictionary = row_value
			if str(row.get("id", "")) == contact_id:
				return row
	return {}


func _journal_reaction_count(rows: Array, contact_id: String) -> int:
	var count: int = 0
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("contact_id", "")) == contact_id and str(row.get("type", "")) == "social_reaction":
			count += 1
	return count


func _advance_test_day() -> void:
	GameManager.call("_advance_day_internal", false, true, false)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
