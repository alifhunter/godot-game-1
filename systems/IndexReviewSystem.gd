extends RefCounted

const STABLE_RNG = preload("res://systems/StableRng.gd")
const TRADING_CALENDAR_SCRIPT = preload("res://systems/TradingCalendar.gd")

const STATE_SCHEMA_VERSION := 1
const DEFAULT_INITIAL_MEMBERSHIP_RATIO := 0.28
const DEFAULT_MINIMUM_MEMBERS := 5
const DEFAULT_MAXIMUM_REVIEW_TURNOVER := 4
const DEFAULT_CANDIDATE_WATCH_COUNT := 4
const DEFAULT_WATCH_LEAD_TRADING_DAYS := 5
const DEFAULT_SCHEDULE_YEARS_AHEAD := 2
const PASSIVE_FLOW_EFFECTIVE_DAYS := 3
const COOLDOWN_DAYS := 3

var trading_calendar = TRADING_CALENDAR_SCRIPT.new()


func ensure_initialized(run_state, data_repository) -> Dictionary:
	var catalog: Dictionary = _catalog(data_repository)
	var state: Dictionary = _normalized_state(run_state.get_index_review_state() if run_state.has_method("get_index_review_state") else {})
	if catalog.is_empty():
		if run_state.has_method("set_index_review_state"):
			run_state.set_index_review_state(state)
		return state

	var changed: bool = false
	var provider_lookup: Dictionary = state.get("providers", {}).duplicate(true)
	for provider_value in catalog.get("providers", []):
		if typeof(provider_value) != TYPE_DICTIONARY:
			continue
		var provider: Dictionary = provider_value
		var provider_id: String = str(provider.get("id", "")).strip_edges().to_lower()
		if provider_id.is_empty():
			continue
		var provider_state: Dictionary = provider_lookup.get(provider_id, {}).duplicate(true)
		provider_state["id"] = provider_id
		provider_state["label"] = str(provider.get("label", provider_id.to_upper()))
		provider_state["full_label"] = str(provider.get("full_label", provider_state.get("label", provider_id.to_upper())))
		provider_state["review_months"] = _normalize_int_array(provider.get("review_months", []))
		provider_state["announcement_day"] = int(provider.get("announcement_day", 10))
		provider_state["effective_day"] = int(provider.get("effective_day", 20))
		if not provider_state.has("members") or typeof(provider_state.get("members")) != TYPE_ARRAY:
			provider_state["members"] = _initial_members_for_provider(run_state, provider_id, catalog)
			changed = true
		if not provider_state.has("schedule") or typeof(provider_state.get("schedule")) != TYPE_DICTIONARY:
			provider_state["schedule"] = {}
			changed = true
		if not provider_state.has("candidate_watch") or typeof(provider_state.get("candidate_watch")) != TYPE_ARRAY:
			provider_state["candidate_watch"] = []
			changed = true
		provider_lookup[provider_id] = provider_state

	state["providers"] = provider_lookup
	changed = _ensure_review_schedule(state, catalog, run_state.get_current_trade_date()) or changed
	state = _prune_state_for_current_day(state, run_state.day_index + 1)
	if run_state.has_method("set_index_review_state"):
		run_state.set_index_review_state(state)
	return state


func resolve_day(run_state, data_repository, trade_date: Dictionary, day_number: int, macro_state: Dictionary = {}) -> Dictionary:
	var state: Dictionary = ensure_initialized(run_state, data_repository)
	var catalog: Dictionary = _catalog(data_repository)
	var events: Array = []
	var active_arcs: Array = _active_arcs_for_day(run_state.get_active_company_arcs(), day_number)
	state = _apply_due_membership_actions(state, run_state, trade_date, day_number, events)
	state = _resolve_scheduled_reviews(state, catalog, run_state, trade_date, day_number, macro_state, events, active_arcs)
	if run_state.has_method("set_index_review_state"):
		run_state.set_index_review_state(state)
	return {
		"index_review_state": state.duplicate(true),
		"index_review_events": events.duplicate(true),
		"active_company_arcs": active_arcs.duplicate(true)
	}


func get_dashboard_snapshot(run_state, data_repository, limit: int = 8) -> Dictionary:
	var state: Dictionary = ensure_initialized(run_state, data_repository)
	var rows: Array = []
	var current_day_number: int = max(run_state.day_index + 1, 1)
	var providers: Dictionary = state.get("providers", {})
	for provider_state_value in providers.values():
		if typeof(provider_state_value) != TYPE_DICTIONARY:
			continue
		var provider_state: Dictionary = provider_state_value
		for schedule_value in provider_state.get("schedule", {}).values():
			if typeof(schedule_value) != TYPE_DICTIONARY:
				continue
			var schedule: Dictionary = schedule_value
			var announcement_day_number: int = int(schedule.get("announcement_day_number", 0))
			var effective_day_number: int = int(schedule.get("effective_day_number", 0))
			if announcement_day_number >= current_day_number:
				rows.append(_build_dashboard_row(provider_state, schedule, "announcement", announcement_day_number))
			if effective_day_number >= current_day_number and bool(schedule.get("announcement_emitted", false)):
				rows.append(_build_dashboard_row(provider_state, schedule, "effective", effective_day_number))

	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("trading_day_number", 0)) == int(b.get("trading_day_number", 0)):
			return str(a.get("provider_label", "")) < str(b.get("provider_label", ""))
		return int(a.get("trading_day_number", 0)) < int(b.get("trading_day_number", 0))
	)
	if limit > 0 and rows.size() > limit:
		rows = rows.slice(0, limit)
	return {
		"day_index": run_state.day_index,
		"trade_date": run_state.get_current_trade_date(),
		"upcoming_rows": rows,
		"providers": _provider_summary_rows(state)
	}


func get_company_index_snapshot(run_state, data_repository, company_id: String) -> Dictionary:
	if company_id.is_empty():
		return {}
	var state: Dictionary = ensure_initialized(run_state, data_repository)
	var rows: Array = []
	var membership_labels: Array = []
	var candidate_labels: Array = []
	var current_day_number: int = max(run_state.day_index + 1, 1)
	for provider_state_value in state.get("providers", {}).values():
		if typeof(provider_state_value) != TYPE_DICTIONARY:
			continue
		var provider_state: Dictionary = provider_state_value
		var provider_id: String = str(provider_state.get("id", ""))
		var provider_label: String = str(provider_state.get("label", provider_id.to_upper()))
		var members: Array = provider_state.get("members", [])
		var is_member: bool = members.has(company_id)
		var candidate_row: Dictionary = _candidate_watch_for_company(provider_state, company_id, current_day_number)
		var candidate_label: String = str(candidate_row.get("label", ""))
		if is_member:
			membership_labels.append(provider_label)
		if not candidate_label.is_empty():
			candidate_labels.append(candidate_label)
		rows.append({
			"provider_id": provider_id,
			"provider_label": provider_label,
			"full_label": str(provider_state.get("full_label", provider_label)),
			"is_member": is_member,
			"candidate_watch": candidate_row,
			"status_label": _provider_company_status_label(provider_label, is_member, candidate_row)
		})
	return {
		"company_id": company_id,
		"membership_labels": membership_labels,
		"candidate_labels": candidate_labels,
		"rows": rows,
		"summary_label": _company_index_summary_label(membership_labels, candidate_labels)
	}


func get_debug_generator_catalog(data_repository) -> Array:
	var groups: Array = []
	for provider_value in _catalog(data_repository).get("providers", []):
		if typeof(provider_value) != TYPE_DICTIONARY:
			continue
		var provider: Dictionary = provider_value
		var provider_id: String = str(provider.get("id", "")).strip_edges().to_lower()
		if provider_id.is_empty():
			continue
		var provider_label: String = str(provider.get("label", provider_id.to_upper()))
		groups.append({
			"id": provider_id,
			"label": "%s Index Review" % provider_label,
			"generators": [
				{
					"id": "%s_inclusion" % provider_id,
					"provider_id": provider_id,
					"side": "include",
					"label": "%s Inclusion" % provider_label,
					"description": "Force a same-day %s inclusion announcement for the selected stock." % provider_label
				},
				{
					"id": "%s_exclusion" % provider_id,
					"provider_id": provider_id,
					"side": "exclude",
					"label": "%s Exclusion" % provider_label,
					"description": "Force a same-day %s exclusion announcement for the selected stock." % provider_label
				}
			]
		})
	return groups


func debug_force_review_event(run_state, data_repository, provider_id: String, side: String, company_id: String) -> Dictionary:
	if company_id.is_empty():
		return {}
	var state: Dictionary = ensure_initialized(run_state, data_repository)
	var normalized_provider_id: String = provider_id.strip_edges().to_lower()
	var providers: Dictionary = state.get("providers", {})
	if not providers.has(normalized_provider_id):
		return {}
	var provider_state: Dictionary = providers.get(normalized_provider_id, {}).duplicate(true)
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	if definition.is_empty():
		return {}

	var normalized_side: String = "exclude" if side == "exclude" else "include"
	var current_day_number: int = max(run_state.day_index, 1)
	var current_trade_date: Dictionary = run_state.get_current_trade_date()
	var effective_day_number: int = current_day_number + 1
	var effective_date: Dictionary = trading_calendar.trade_date_for_index(effective_day_number)
	var review_id: String = "%s_debug_%s_%s" % [normalized_provider_id, normalized_side, current_day_number]
	var score_row: Dictionary = _score_row_for_company(run_state, normalized_provider_id, company_id)
	var action: Dictionary = _build_membership_action(
		provider_state,
		review_id,
		definition,
		normalized_side,
		current_day_number,
		effective_day_number,
		current_trade_date,
		effective_date,
		score_row
	)
	action["debug_generated"] = true
	var pending_actions: Array = state.get("pending_membership_actions", []).duplicate(true)
	pending_actions.append(action.duplicate(true))
	state["pending_membership_actions"] = pending_actions
	provider_state["candidate_watch"] = _merge_candidate_watch_rows(
		provider_state.get("candidate_watch", []),
		[_candidate_watch_row(action)]
	)
	providers[normalized_provider_id] = provider_state
	state["providers"] = providers
	state = _append_history(state, _history_row(provider_state, {"id": review_id}, [action], "debug"))
	var arc: Dictionary = _decorate_arc_for_day(_build_index_review_arc(action, current_day_number), current_day_number)
	var event: Dictionary = _build_action_event(action, "announcement", current_trade_date, current_day_number)
	return {
		"index_review_state": state,
		"arc": arc,
		"event": event,
		"action": action
	}


func _catalog(data_repository) -> Dictionary:
	if data_repository == null or not data_repository.has_method("get_index_review_catalog"):
		return {}
	return data_repository.get_index_review_catalog()


func _normalized_state(source_state: Variant) -> Dictionary:
	var state: Dictionary = source_state.duplicate(true) if typeof(source_state) == TYPE_DICTIONARY else {}
	if state.is_empty():
		state = {
			"schema_version": STATE_SCHEMA_VERSION,
			"providers": {},
			"pending_membership_actions": [],
			"review_history": []
		}
	state["schema_version"] = STATE_SCHEMA_VERSION
	if typeof(state.get("providers", {})) != TYPE_DICTIONARY:
		state["providers"] = {}
	if typeof(state.get("pending_membership_actions", [])) != TYPE_ARRAY:
		state["pending_membership_actions"] = []
	if typeof(state.get("review_history", [])) != TYPE_ARRAY:
		state["review_history"] = []
	return state


func _ensure_review_schedule(state: Dictionary, catalog: Dictionary, current_trade_date: Dictionary) -> bool:
	var changed: bool = false
	var current_year: int = int(current_trade_date.get("year", trading_calendar.start_date().get("year", 2020)))
	var years_ahead: int = max(int(catalog.get("schedule_years_ahead", DEFAULT_SCHEDULE_YEARS_AHEAD)), 1)
	var providers: Dictionary = state.get("providers", {}).duplicate(true)
	for provider_id_value in providers.keys():
		var provider_id: String = str(provider_id_value)
		var provider_state: Dictionary = providers.get(provider_id, {}).duplicate(true)
		var schedule: Dictionary = provider_state.get("schedule", {}).duplicate(true)
		var review_months: Array = _normalize_int_array(provider_state.get("review_months", []))
		for year_value in range(current_year, current_year + years_ahead + 1):
			for month_value in review_months:
				var review_key: String = "%s_%04d_%02d" % [provider_id, year_value, int(month_value)]
				if schedule.has(review_key):
					continue
				schedule[review_key] = _build_schedule_row(provider_state, review_key, year_value, int(month_value), catalog)
				changed = true
		provider_state["schedule"] = schedule
		providers[provider_id] = provider_state
	state["providers"] = providers
	return changed


func _build_schedule_row(provider_state: Dictionary, review_key: String, year_value: int, month_value: int, catalog: Dictionary) -> Dictionary:
	var announcement_date: Dictionary = trading_calendar.trade_date_on_or_after(year_value, month_value, int(provider_state.get("announcement_day", 10)))
	var effective_date: Dictionary = trading_calendar.trade_date_on_or_after(year_value, month_value, int(provider_state.get("effective_day", 20)))
	var announcement_day_number: int = trading_calendar.trade_index_for_date(announcement_date)
	var effective_day_number: int = trading_calendar.trade_index_for_date(effective_date)
	var watch_lead_days: int = max(int(catalog.get("watch_lead_trading_days", DEFAULT_WATCH_LEAD_TRADING_DAYS)), 1)
	var watch_day_number: int = max(announcement_day_number - watch_lead_days, 1)
	return {
		"id": review_key,
		"provider_id": str(provider_state.get("id", "")),
		"provider_label": str(provider_state.get("label", "")),
		"year": year_value,
		"month": month_value,
		"announcement_date": announcement_date,
		"announcement_day_number": announcement_day_number,
		"effective_date": effective_date,
		"effective_day_number": effective_day_number,
		"watch_date": trading_calendar.trade_date_for_index(watch_day_number),
		"watch_day_number": watch_day_number,
		"watch_created": false,
		"announcement_emitted": false,
		"effective_applied": false,
		"review_plan": {},
		"no_change": false
	}


func _resolve_scheduled_reviews(
	state: Dictionary,
	catalog: Dictionary,
	run_state,
	trade_date: Dictionary,
	day_number: int,
	macro_state: Dictionary,
	events: Array,
	active_arcs: Array
) -> Dictionary:
	var providers: Dictionary = state.get("providers", {}).duplicate(true)
	for provider_id_value in providers.keys():
		var provider_id: String = str(provider_id_value)
		var provider_state: Dictionary = providers.get(provider_id, {}).duplicate(true)
		var schedule: Dictionary = provider_state.get("schedule", {}).duplicate(true)
		var schedule_keys: Array = schedule.keys()
		schedule_keys.sort()
		for review_key_value in schedule_keys:
			var review_key: String = str(review_key_value)
			var review: Dictionary = schedule.get(review_key, {}).duplicate(true)
			if review.is_empty():
				continue
			if day_number >= int(review.get("watch_day_number", 0)) and not bool(review.get("watch_created", false)):
				var watch_result: Dictionary = _create_watch_plan(provider_state, review, catalog, run_state, macro_state, day_number)
				provider_state = watch_result.get("provider_state", provider_state).duplicate(true)
				review = watch_result.get("review", review).duplicate(true)
				active_arcs.append_array(watch_result.get("arcs", []))
			if day_number >= int(review.get("announcement_day_number", 0)) and not bool(review.get("announcement_emitted", false)):
				var announcement_result: Dictionary = _emit_review_announcement(provider_state, review, catalog, run_state, trade_date, day_number)
				provider_state = announcement_result.get("provider_state", provider_state).duplicate(true)
				review = announcement_result.get("review", review).duplicate(true)
				events.append_array(announcement_result.get("events", []))
				active_arcs.append_array(announcement_result.get("arcs", []))
				state["pending_membership_actions"] = _merge_pending_actions(
					state.get("pending_membership_actions", []),
					announcement_result.get("pending_actions", [])
				)
				state = _append_history(state, _history_row(provider_state, review, announcement_result.get("pending_actions", []), "announcement"))
			schedule[review_key] = review
		provider_state["schedule"] = schedule
		providers[provider_id] = provider_state
	state["providers"] = providers
	return state


func _create_watch_plan(
	provider_state: Dictionary,
	review: Dictionary,
	catalog: Dictionary,
	run_state,
	macro_state: Dictionary,
	day_number: int
) -> Dictionary:
	var resolved_provider_state: Dictionary = provider_state.duplicate(true)
	var resolved_review: Dictionary = review.duplicate(true)
	var plan: Dictionary = resolved_review.get("review_plan", {}).duplicate(true)
	if plan.is_empty():
		plan = _build_review_plan(resolved_provider_state, resolved_review, catalog, run_state, macro_state)
	resolved_review["review_plan"] = plan
	resolved_review["watch_created"] = true
	resolved_review["no_change"] = plan.get("actions", []).is_empty()
	resolved_provider_state["candidate_watch"] = _merge_candidate_watch_rows(
		resolved_provider_state.get("candidate_watch", []),
		plan.get("candidate_watch", [])
	)
	var arcs: Array = []
	for action_value in plan.get("actions", []):
		if typeof(action_value) != TYPE_DICTIONARY:
			continue
		var action: Dictionary = action_value
		var arc: Dictionary = _decorate_arc_for_day(_build_index_review_arc(action, day_number), day_number)
		if not arc.is_empty():
			arcs.append(arc)
	return {
		"provider_state": resolved_provider_state,
		"review": resolved_review,
		"arcs": arcs
	}


func _emit_review_announcement(
	provider_state: Dictionary,
	review: Dictionary,
	catalog: Dictionary,
	run_state,
	trade_date: Dictionary,
	day_number: int
) -> Dictionary:
	var resolved_provider_state: Dictionary = provider_state.duplicate(true)
	var resolved_review: Dictionary = review.duplicate(true)
	var plan: Dictionary = resolved_review.get("review_plan", {}).duplicate(true)
	var arcs: Array = []
	if plan.is_empty():
		var watch_result: Dictionary = _create_watch_plan(resolved_provider_state, resolved_review, catalog, run_state, {}, day_number)
		resolved_provider_state = watch_result.get("provider_state", resolved_provider_state).duplicate(true)
		resolved_review = watch_result.get("review", resolved_review).duplicate(true)
		plan = resolved_review.get("review_plan", {}).duplicate(true)
		arcs = watch_result.get("arcs", []).duplicate(true)

	var events: Array = []
	var pending_actions: Array = []
	for action_value in plan.get("actions", []):
		if typeof(action_value) != TYPE_DICTIONARY:
			continue
		var action: Dictionary = action_value.duplicate(true)
		events.append(_build_action_event(action, "announcement", trade_date, day_number))
		pending_actions.append(action)
	if pending_actions.is_empty():
		events.append(_build_no_change_event(resolved_provider_state, resolved_review, trade_date, day_number))
	resolved_review["announcement_emitted"] = true
	resolved_review["announced_day_number"] = day_number
	resolved_review["affected_count"] = pending_actions.size()
	resolved_review["no_change"] = pending_actions.is_empty()
	return {
		"provider_state": resolved_provider_state,
		"review": resolved_review,
		"events": events,
		"pending_actions": pending_actions,
		"arcs": arcs
	}


func _apply_due_membership_actions(state: Dictionary, run_state, trade_date: Dictionary, day_number: int, events: Array) -> Dictionary:
	var pending: Array = state.get("pending_membership_actions", []).duplicate(true)
	if pending.is_empty():
		return state
	var providers: Dictionary = state.get("providers", {}).duplicate(true)
	var remaining: Array = []
	for action_value in pending:
		if typeof(action_value) != TYPE_DICTIONARY:
			continue
		var action: Dictionary = action_value.duplicate(true)
		if bool(action.get("applied", false)) or day_number < int(action.get("effective_day_number", 0)):
			remaining.append(action)
			continue
		var provider_id: String = str(action.get("provider_id", ""))
		if not providers.has(provider_id):
			continue
		var provider_state: Dictionary = providers.get(provider_id, {}).duplicate(true)
		var members: Array = provider_state.get("members", []).duplicate()
		var company_id: String = str(action.get("company_id", ""))
		if str(action.get("side", "")) == "include":
			if not members.has(company_id):
				members.append(company_id)
		elif str(action.get("side", "")) == "exclude":
			members.erase(company_id)
		members.sort()
		provider_state["members"] = members
		provider_state["candidate_watch"] = _remove_candidate_watch_row(provider_state.get("candidate_watch", []), action)
		providers[provider_id] = provider_state
		action["applied"] = true
		action["applied_day_number"] = day_number
		events.append(_build_action_event(action, "effective", trade_date, day_number))
		state = _append_history(state, _history_row(provider_state, {"id": str(action.get("review_id", ""))}, [action], "effective"))
	state["providers"] = providers
	state["pending_membership_actions"] = remaining
	state = _mark_effective_reviews_applied(state, day_number)
	return state


func _mark_effective_reviews_applied(state: Dictionary, day_number: int) -> Dictionary:
	var providers: Dictionary = state.get("providers", {}).duplicate(true)
	for provider_id_value in providers.keys():
		var provider_id: String = str(provider_id_value)
		var provider_state: Dictionary = providers.get(provider_id, {}).duplicate(true)
		var schedule: Dictionary = provider_state.get("schedule", {}).duplicate(true)
		for review_key_value in schedule.keys():
			var review_key: String = str(review_key_value)
			var review: Dictionary = schedule.get(review_key, {}).duplicate(true)
			if day_number >= int(review.get("effective_day_number", 0)) and bool(review.get("announcement_emitted", false)):
				review["effective_applied"] = true
			schedule[review_key] = review
		provider_state["schedule"] = schedule
		providers[provider_id] = provider_state
	state["providers"] = providers
	return state


func _build_review_plan(provider_state: Dictionary, review: Dictionary, catalog: Dictionary, run_state, _macro_state: Dictionary) -> Dictionary:
	var provider_id: String = str(provider_state.get("id", ""))
	var members: Array = provider_state.get("members", []).duplicate()
	var target_count: int = _target_member_count(run_state, catalog)
	if not members.is_empty():
		target_count = clamp(members.size(), 1, max(run_state.company_order.size(), 1))
	var ranked_rows: Array = _ranked_score_rows(run_state, provider_id)
	var desired_members: Array = []
	for row_value in ranked_rows:
		if desired_members.size() >= target_count:
			break
		var row: Dictionary = row_value
		if bool(row.get("eligible", true)):
			desired_members.append(str(row.get("company_id", "")))

	var additions: Array = []
	var removals: Array = []
	for desired_id_value in desired_members:
		var desired_id: String = str(desired_id_value)
		if not members.has(desired_id):
			additions.append(desired_id)
	for member_value in members:
		var member_id: String = str(member_value)
		if not desired_members.has(member_id):
			removals.append(member_id)

	additions = _sort_company_ids_by_rank(additions, ranked_rows, true)
	removals = _sort_company_ids_by_rank(removals, ranked_rows, false)
	var max_turnover: int = max(int(catalog.get("maximum_review_turnover", DEFAULT_MAXIMUM_REVIEW_TURNOVER)), 0)
	var actions: Array = []
	while actions.size() < max_turnover and (not additions.is_empty() or not removals.is_empty()):
		if not additions.is_empty() and actions.size() < max_turnover:
			var include_company_id: String = str(additions.pop_front())
			actions.append(_action_for_company(provider_state, review, run_state, include_company_id, "include", ranked_rows))
		if not removals.is_empty() and actions.size() < max_turnover:
			var exclude_company_id: String = str(removals.pop_front())
			actions.append(_action_for_company(provider_state, review, run_state, exclude_company_id, "exclude", ranked_rows))

	var candidate_watch: Array = []
	for action_value in actions:
		if typeof(action_value) == TYPE_DICTIONARY:
			candidate_watch.append(_candidate_watch_row(action_value))
	candidate_watch.append_array(_near_cutoff_candidate_rows(provider_state, review, run_state, ranked_rows, members, desired_members, catalog))
	return {
		"provider_id": provider_id,
		"review_id": str(review.get("id", "")),
		"generated_day_number": run_state.day_index + 1,
		"target_member_count": target_count,
		"actions": actions,
		"candidate_watch": candidate_watch,
		"ranked_count": ranked_rows.size()
	}


func _action_for_company(
	provider_state: Dictionary,
	review: Dictionary,
	run_state,
	company_id: String,
	side: String,
	ranked_rows: Array
) -> Dictionary:
	var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
	return _build_membership_action(
		provider_state,
		str(review.get("id", "")),
		definition,
		side,
		int(review.get("announcement_day_number", 0)),
		int(review.get("effective_day_number", 0)),
		review.get("announcement_date", {}),
		review.get("effective_date", {}),
		_rank_row_for_company(ranked_rows, company_id)
	)


func _build_membership_action(
	provider_state: Dictionary,
	review_id: String,
	definition: Dictionary,
	side: String,
	announcement_day_number: int,
	effective_day_number: int,
	announcement_date: Dictionary,
	effective_date: Dictionary,
	score_row: Dictionary
) -> Dictionary:
	var company_id: String = str(definition.get("id", score_row.get("company_id", "")))
	var normalized_side: String = "exclude" if side == "exclude" else "include"
	var category: String = "index_exclusion" if normalized_side == "exclude" else "index_inclusion"
	return {
		"action_id": "%s_%s_%s_%s" % [review_id, normalized_side, company_id, announcement_day_number],
		"review_id": review_id,
		"provider_id": str(provider_state.get("id", "")),
		"provider_label": str(provider_state.get("label", "")),
		"provider_full_label": str(provider_state.get("full_label", provider_state.get("label", ""))),
		"side": normalized_side,
		"category": category,
		"company_id": company_id,
		"ticker": str(definition.get("ticker", company_id.to_upper())),
		"company_name": str(definition.get("name", company_id.to_upper())),
		"target_sector_id": str(definition.get("sector_id", "")),
		"announcement_day_number": announcement_day_number,
		"effective_day_number": effective_day_number,
		"announcement_date": announcement_date.duplicate(true),
		"effective_date": effective_date.duplicate(true),
		"rank": int(score_row.get("rank", 0)),
		"eligibility_score": float(score_row.get("eligibility_score", 0.0)),
		"applied": false
	}


func _build_index_review_arc(action: Dictionary, start_day_number: int) -> Dictionary:
	var side_sign: float = 1.0 if str(action.get("side", "include")) == "include" else -1.0
	var announcement_day_number: int = int(action.get("announcement_day_number", start_day_number))
	var effective_day_number: int = int(action.get("effective_day_number", announcement_day_number + 1))
	var phase_schedule: Array = []
	var hidden_days: int = max(announcement_day_number - start_day_number, 0)
	if hidden_days > 0:
		phase_schedule.append(_build_index_phase_entry(
			"pre_review_positioning",
			"Pre-review positioning",
			hidden_days,
			side_sign * 0.0025,
			1.04,
			"hidden",
			"index_review_%s_%s_watch" % [str(action.get("provider_id", "")), str(action.get("side", ""))],
			side_sign * 0.16,
			1.14,
			1.00
		))
	phase_schedule.append(_build_index_phase_entry(
		"announcement",
		"Index announcement",
		max(effective_day_number - announcement_day_number, 1),
		side_sign * 0.0065,
		1.12,
		"visible",
		"",
		side_sign * 0.38,
		1.45,
		1.10
	))
	phase_schedule.append(_build_index_phase_entry(
		"effective_flow",
		"Effective passive flow",
		PASSIVE_FLOW_EFFECTIVE_DAYS,
		side_sign * 0.0085,
		1.18,
		"visible",
		"",
		side_sign * 0.72,
		1.78,
		1.24
	))
	phase_schedule.append(_build_index_phase_entry(
		"cooldown",
		"Cooldown",
		COOLDOWN_DAYS,
		side_sign * 0.0015,
		1.04,
		"visible",
		"",
		side_sign * 0.14,
		1.14,
		1.06
	))
	var duration_days: int = _total_phase_duration(phase_schedule)
	return {
		"arc_id": str(action.get("action_id", "")),
		"source_system": "index_review",
		"scope": "company",
		"event_id": "%s_index_%s" % [str(action.get("provider_id", "")), "exclusion" if str(action.get("side", "")) == "exclude" else "inclusion"],
		"event_family": "index_review",
		"category": str(action.get("category", "")),
		"tone": "negative" if side_sign < 0.0 else "positive",
		"target_company_id": str(action.get("company_id", "")),
		"target_sector_id": str(action.get("target_sector_id", "")),
		"target_ticker": str(action.get("ticker", "")),
		"target_company_name": str(action.get("company_name", "")),
		"provider_id": str(action.get("provider_id", "")),
		"provider_label": str(action.get("provider_label", "")),
		"provider_full_label": str(action.get("provider_full_label", "")),
		"review_id": str(action.get("review_id", "")),
		"index_side": str(action.get("side", "")),
		"trade_date": action.get("announcement_date", {}).duplicate(true),
		"description": _action_description(action, "announcement"),
		"broker_bias": "foreign_institution",
		"phase_schedule": phase_schedule,
		"duration_days": duration_days,
		"start_day_index": start_day_number,
		"end_day_index": start_day_number + duration_days - 1,
		"announcement_day_number": announcement_day_number,
		"effective_day_number": effective_day_number,
		"hidden_story_flag": "index_review_%s_%s_watch" % [str(action.get("provider_id", "")), str(action.get("side", ""))]
	}


func _build_index_phase_entry(
	phase_id: String,
	label: String,
	duration_days: int,
	sentiment_shift: float,
	volatility_multiplier: float,
	visibility: String,
	hidden_flag: String,
	passive_flow_pressure: float,
	volume_multiplier: float,
	depth_multiplier: float
) -> Dictionary:
	return {
		"id": phase_id,
		"label": label,
		"duration_days": max(duration_days, 1),
		"sentiment_shift": sentiment_shift,
		"volatility_multiplier": volatility_multiplier,
		"visibility": visibility,
		"hidden_flag": hidden_flag,
		"passive_flow_pressure": passive_flow_pressure,
		"volume_activity_multiplier": volume_multiplier,
		"depth_liquidity_multiplier": depth_multiplier
	}


func _active_arcs_for_day(stored_arcs: Array, day_number: int) -> Array:
	var active_arcs: Array = []
	for arc_value in stored_arcs:
		if typeof(arc_value) != TYPE_DICTIONARY:
			continue
		var arc_data: Dictionary = arc_value.duplicate(true)
		if str(arc_data.get("source_system", "")) != "index_review":
			continue
		if int(arc_data.get("end_day_index", 0)) < day_number:
			continue
		var decorated_arc: Dictionary = _decorate_arc_for_day(arc_data, day_number)
		if not decorated_arc.is_empty():
			active_arcs.append(decorated_arc)
	return active_arcs


func _decorate_arc_for_day(arc: Dictionary, day_number: int) -> Dictionary:
	var phase_schedule: Array = arc.get("phase_schedule", []).duplicate(true)
	if phase_schedule.is_empty():
		return {}
	var elapsed_days: int = max(day_number - int(arc.get("start_day_index", day_number)) + 1, 1)
	var running_total: int = 0
	for phase_value in phase_schedule:
		if typeof(phase_value) != TYPE_DICTIONARY:
			continue
		var phase: Dictionary = phase_value
		var duration_days: int = max(int(phase.get("duration_days", 1)), 1)
		var start_offset: int = running_total + 1
		var end_offset: int = running_total + duration_days
		if elapsed_days <= end_offset:
			arc["current_phase_id"] = str(phase.get("id", ""))
			arc["current_phase_label"] = str(phase.get("label", ""))
			arc["phase_day_index"] = elapsed_days - start_offset + 1
			arc["phase_duration_days"] = duration_days
			arc["phase_sentiment_shift"] = float(phase.get("sentiment_shift", 0.0))
			arc["phase_volatility_multiplier"] = float(phase.get("volatility_multiplier", 1.0))
			arc["phase_visibility"] = str(phase.get("visibility", "visible"))
			arc["phase_hidden_flag"] = str(phase.get("hidden_flag", arc.get("hidden_story_flag", "")))
			arc["phase_passive_flow_pressure"] = float(phase.get("passive_flow_pressure", 0.0))
			arc["phase_volume_activity_multiplier"] = float(phase.get("volume_activity_multiplier", 1.0))
			arc["phase_depth_liquidity_multiplier"] = float(phase.get("depth_liquidity_multiplier", 1.0))
			return arc
		running_total += duration_days
	return {}


func _build_action_event(action: Dictionary, stage: String, trade_date: Dictionary, day_number: int) -> Dictionary:
	var provider_id: String = str(action.get("provider_id", ""))
	var side: String = str(action.get("side", "include"))
	var event_id: String = "%s_index_%s" % [provider_id, "exclusion" if side == "exclude" else "inclusion"]
	var tone: String = "negative" if side == "exclude" else "positive"
	var provider_label: String = str(action.get("provider_label", provider_id.to_upper()))
	var ticker: String = str(action.get("ticker", ""))
	var side_label: String = "exclusion" if side == "exclude" else "inclusion"
	var headline: String = "%s %s announced for %s" % [provider_label, side_label, ticker]
	if stage == "effective":
		headline = "%s %s now effective for %s" % [provider_label, side_label, ticker]
	return {
		"event_id": event_id,
		"event_family": "index_review",
		"category": str(action.get("category", "")),
		"scope": "company",
		"tone": tone,
		"target_company_id": str(action.get("company_id", "")),
		"target_sector_id": str(action.get("target_sector_id", "")),
		"target_ticker": ticker,
		"target_company_name": str(action.get("company_name", ticker)),
		"provider_id": provider_id,
		"provider_label": provider_label,
		"provider_full_label": str(action.get("provider_full_label", provider_label)),
		"review_id": str(action.get("review_id", "")),
		"review_stage": stage,
		"headline": headline,
		"summary": _action_description(action, stage),
		"headline_detail": _action_description(action, stage),
		"description": _action_description(action, stage),
		"sentiment_shift": 0.007 if side == "include" else -0.007,
		"passive_flow_pressure": 0.72 if side == "include" and stage == "effective" else (-0.72 if side == "exclude" and stage == "effective" else 0.38 * (1.0 if side == "include" else -1.0)),
		"trade_date": trade_date.duplicate(true),
		"day_index": day_number
	}


func _build_no_change_event(provider_state: Dictionary, review: Dictionary, trade_date: Dictionary, day_number: int) -> Dictionary:
	var provider_label: String = str(provider_state.get("label", "Index"))
	return {
		"event_id": "index_review_no_change",
		"event_family": "index_review",
		"category": "index_watch",
		"scope": "market",
		"tone": "mixed",
		"provider_id": str(provider_state.get("id", "")),
		"provider_label": provider_label,
		"provider_full_label": str(provider_state.get("full_label", provider_label)),
		"review_id": str(review.get("id", "")),
		"review_stage": "announcement",
		"headline": "%s review ends with no membership change" % provider_label,
		"summary": "%s completed its quarterly review without membership changes for this cycle." % provider_label,
		"headline_detail": "%s completed its quarterly review without membership changes for this cycle." % provider_label,
		"description": "%s completed its quarterly review without membership changes for this cycle." % provider_label,
		"sentiment_shift": 0.0,
		"trade_date": trade_date.duplicate(true),
		"day_index": day_number
	}


func _action_description(action: Dictionary, stage: String) -> String:
	var provider_label: String = str(action.get("provider_label", "Index"))
	var ticker: String = str(action.get("ticker", ""))
	var side: String = str(action.get("side", "include"))
	var effective_text: String = trading_calendar.format_date(action.get("effective_date", {})) if typeof(action.get("effective_date", {})) == TYPE_DICTIONARY else "the effective date"
	if side == "exclude":
		if stage == "effective":
			return "%s removal for %s is now effective, shifting passive flow away from the stock." % [provider_label, ticker]
		return "%s announced %s as an index removal candidate, with passive selling expected around %s." % [provider_label, ticker, effective_text]
	if stage == "effective":
		return "%s inclusion for %s is now effective, adding passive-flow demand to the stock." % [provider_label, ticker]
	return "%s announced %s as an index inclusion candidate, with passive buying expected around %s." % [provider_label, ticker, effective_text]


func _build_dashboard_row(provider_state: Dictionary, review: Dictionary, event_type: String, trading_day_number: int) -> Dictionary:
	var trade_date: Dictionary = trading_calendar.trade_date_for_index(trading_day_number)
	var provider_label: String = str(provider_state.get("label", "Index"))
	var affected_count: int = int(review.get("affected_count", review.get("review_plan", {}).get("actions", []).size()))
	var label: String = "%s review announcement" % provider_label
	var summary: String = "%s quarterly review announcement. Effective date follows later in the same month." % provider_label
	if event_type == "effective":
		label = "%s review effective date" % provider_label
		summary = "%s membership changes become effective. Passive buying or selling can affect names in the review." % provider_label
	if affected_count <= 0 and bool(review.get("no_change", false)):
		summary = "%s review has no membership changes recorded for this cycle." % provider_label
	return {
		"id": "%s_%s" % [str(review.get("id", "")), event_type],
		"type": "index_review",
		"provider_id": str(provider_state.get("id", "")),
		"provider_label": provider_label,
		"event_type": event_type,
		"label": label,
		"public_summary": summary,
		"affected_count": affected_count,
		"trade_date": trade_date,
		"date_key": trading_calendar.to_key(trade_date),
		"trading_day_number": trading_day_number
	}


func _initial_members_for_provider(run_state, provider_id: String, catalog: Dictionary) -> Array:
	var ranked_rows: Array = _ranked_score_rows(run_state, provider_id)
	var target_count: int = _target_member_count(run_state, catalog)
	var members: Array = []
	for row_value in ranked_rows:
		if members.size() >= target_count:
			break
		var row: Dictionary = row_value
		if not bool(row.get("eligible", true)):
			continue
		members.append(str(row.get("company_id", "")))
	members.sort()
	return members


func _target_member_count(run_state, catalog: Dictionary) -> int:
	var company_count: int = max(run_state.company_order.size(), 0)
	if company_count <= 0:
		return 0
	var ratio: float = clamp(float(catalog.get("initial_membership_ratio", DEFAULT_INITIAL_MEMBERSHIP_RATIO)), 0.05, 0.85)
	var minimum_members: int = max(int(catalog.get("minimum_members", DEFAULT_MINIMUM_MEMBERS)), 1)
	return clamp(int(round(float(company_count) * ratio)), min(minimum_members, company_count), company_count)


func _ranked_score_rows(run_state, provider_id: String) -> Array:
	var metric_rows: Array = _company_metric_rows(run_state)
	var market_cap_bounds: Dictionary = _metric_bounds(metric_rows, "market_cap")
	var daily_value_bounds: Dictionary = _metric_bounds(metric_rows, "avg_daily_value")
	var rows: Array = []
	for metric_value in metric_rows:
		var metric: Dictionary = metric_value
		var score: float = _eligibility_score(metric, provider_id, market_cap_bounds, daily_value_bounds)
		var eligible: bool = not bool(metric.get("trade_disabled", false)) and score > 0.08
		var row: Dictionary = metric.duplicate(true)
		row["eligibility_score"] = score
		row["eligible"] = eligible
		rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("eligibility_score", 0.0)), float(b.get("eligibility_score", 0.0))):
			return str(a.get("company_id", "")) < str(b.get("company_id", ""))
		return float(a.get("eligibility_score", 0.0)) > float(b.get("eligibility_score", 0.0))
	)
	for row_index in range(rows.size()):
		var row: Dictionary = rows[row_index]
		row["rank"] = row_index + 1
		rows[row_index] = row
	return rows


func _score_row_for_company(run_state, provider_id: String, company_id: String) -> Dictionary:
	for row_value in _ranked_score_rows(run_state, provider_id):
		if typeof(row_value) == TYPE_DICTIONARY and str(row_value.get("company_id", "")) == company_id:
			return row_value
	return {"company_id": company_id, "rank": 0, "eligibility_score": 0.0}


func _company_metric_rows(run_state) -> Array:
	var rows: Array = []
	for company_id_value in run_state.company_order:
		var company_id: String = str(company_id_value)
		var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
		var runtime: Dictionary = run_state.get_company(company_id)
		if definition.is_empty() or runtime.is_empty():
			continue
		var financials: Dictionary = definition.get("financials", {})
		var profile: Dictionary = runtime.get("company_profile", {})
		var current_price: float = max(float(runtime.get("current_price", definition.get("base_price", 1.0))), 1.0)
		var shares_outstanding: float = max(float(financials.get("shares_outstanding", definition.get("shares_outstanding", 0.0))), 1.0)
		var market_cap: float = max(float(financials.get("market_cap", current_price * shares_outstanding)), current_price * shares_outstanding)
		var avg_daily_value: float = max(float(financials.get("avg_daily_value", current_price * 250000.0)), current_price * 1000.0)
		var free_float_ratio: float = clamp(float(financials.get("free_float_pct", 35.0)) / 100.0, 0.0, 1.0)
		var narrative_tags: Array = definition.get("narrative_tags", []).duplicate()
		rows.append({
			"company_id": company_id,
			"ticker": str(definition.get("ticker", company_id.to_upper())),
			"company_name": str(definition.get("name", company_id.to_upper())),
			"sector_id": str(definition.get("sector_id", "")),
			"market_cap": market_cap,
			"avg_daily_value": avg_daily_value,
			"free_float_ratio": free_float_ratio,
			"quality_score": clamp(float(definition.get("quality_score", 50.0)) / 100.0, 0.0, 1.0),
			"risk_score": clamp(float(definition.get("risk_score", 50.0)) / 100.0, 0.0, 1.0),
			"narrative_tags": narrative_tags,
			"trade_disabled": bool(profile.get("trade_disabled", false)) if typeof(profile) == TYPE_DICTIONARY else false,
			"delisting_watch": profile.get("delisting_watch", {}) if typeof(profile) == TYPE_DICTIONARY else {},
			"restructuring_result": profile.get("restructuring_result", {}) if typeof(profile) == TYPE_DICTIONARY else {}
		})
	return rows


func _eligibility_score(metric: Dictionary, provider_id: String, market_cap_bounds: Dictionary, daily_value_bounds: Dictionary) -> float:
	var market_cap_score: float = _log_score(float(metric.get("market_cap", 0.0)), market_cap_bounds)
	var daily_value_score: float = _log_score(float(metric.get("avg_daily_value", 0.0)), daily_value_bounds)
	var free_float_score: float = clamp(float(metric.get("free_float_ratio", 0.0)) / 0.65, 0.0, 1.0)
	var quality_score: float = clamp(float(metric.get("quality_score", 0.5)), 0.0, 1.0)
	var tags: Array = metric.get("narrative_tags", [])
	var tag_score: float = 0.0
	if "foreign_watchlist" in tags:
		tag_score += 0.48
	if "institution_quality" in tags:
		tag_score += 0.44
	if "supportive_balance_sheet" in tags:
		tag_score += 0.12
	tag_score = clamp(tag_score, 0.0, 1.0)
	var score: float = (
		market_cap_score * 0.38 +
		daily_value_score * 0.28 +
		free_float_score * 0.18 +
		quality_score * 0.08 +
		tag_score * 0.08
	)
	var provider_tiebreaker: float = float(STABLE_RNG.seed_from_parts([provider_id, metric.get("company_id", ""), "index_score"]) % 1000) / 100000.0
	score += provider_tiebreaker
	var risk_score: float = clamp(float(metric.get("risk_score", 0.5)), 0.0, 1.0)
	if risk_score >= 0.65:
		score -= (risk_score - 0.65) * 0.42
	if bool(metric.get("trade_disabled", false)):
		score -= 0.55
	if typeof(metric.get("delisting_watch", {})) == TYPE_DICTIONARY and not metric.get("delisting_watch", {}).is_empty():
		score -= 0.32
	if typeof(metric.get("restructuring_result", {})) == TYPE_DICTIONARY and not metric.get("restructuring_result", {}).is_empty():
		score -= 0.24
	return clamp(score, 0.0, 1.0)


func _metric_bounds(metric_rows: Array, key: String) -> Dictionary:
	var minimum: float = INF
	var maximum: float = -INF
	for row_value in metric_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var value: float = max(float(row.get(key, 0.0)), 1.0)
		minimum = min(minimum, value)
		maximum = max(maximum, value)
	if minimum == INF:
		minimum = 1.0
	if maximum == -INF:
		maximum = minimum
	return {"min": minimum, "max": maximum}


func _log_score(value: float, bounds: Dictionary) -> float:
	var minimum: float = max(float(bounds.get("min", 1.0)), 1.0)
	var maximum: float = max(float(bounds.get("max", minimum)), minimum)
	if is_equal_approx(maximum, minimum):
		return 0.5
	var log_minimum: float = log(minimum)
	var log_maximum: float = log(maximum)
	if is_equal_approx(log_maximum, log_minimum):
		return 0.5
	return clamp((log(max(value, 1.0)) - log_minimum) / (log_maximum - log_minimum), 0.0, 1.0)


func _sort_company_ids_by_rank(company_ids: Array, ranked_rows: Array, ascending: bool) -> Array:
	var rows: Array = []
	for company_id_value in company_ids:
		rows.append(_rank_row_for_company(ranked_rows, str(company_id_value)))
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("rank", 9999)) == int(b.get("rank", 9999)):
			return str(a.get("company_id", "")) < str(b.get("company_id", ""))
		return int(a.get("rank", 9999)) < int(b.get("rank", 9999)) if ascending else int(a.get("rank", 9999)) > int(b.get("rank", 9999))
	)
	var sorted_ids: Array = []
	for row_value in rows:
		if typeof(row_value) == TYPE_DICTIONARY:
			sorted_ids.append(str(row_value.get("company_id", "")))
	return sorted_ids


func _rank_row_for_company(ranked_rows: Array, company_id: String) -> Dictionary:
	for row_value in ranked_rows:
		if typeof(row_value) == TYPE_DICTIONARY and str(row_value.get("company_id", "")) == company_id:
			return row_value.duplicate(true)
	return {"company_id": company_id, "rank": 9999, "eligibility_score": 0.0}


func _near_cutoff_candidate_rows(
	provider_state: Dictionary,
	review: Dictionary,
	run_state,
	ranked_rows: Array,
	members: Array,
	desired_members: Array,
	catalog: Dictionary
) -> Array:
	var rows: Array = []
	var max_rows: int = max(int(catalog.get("candidate_watch_count", DEFAULT_CANDIDATE_WATCH_COUNT)), 0)
	if max_rows <= 0:
		return rows
	var target_count: int = max(desired_members.size(), members.size())
	for row_index in range(ranked_rows.size()):
		if rows.size() >= max_rows:
			break
		var row: Dictionary = ranked_rows[row_index]
		var company_id: String = str(row.get("company_id", ""))
		if company_id.is_empty():
			continue
		var near_cutoff: bool = abs(int(row.get("rank", row_index + 1)) - target_count) <= 3
		if not near_cutoff:
			continue
		var side: String = "watch"
		if not members.has(company_id) and int(row.get("rank", 9999)) <= target_count + 3:
			side = "include"
		elif members.has(company_id) and not desired_members.has(company_id):
			side = "exclude"
		var definition: Dictionary = run_state.get_effective_company_definition(company_id, false, false)
		if definition.is_empty():
			continue
		var action: Dictionary = _build_membership_action(
			provider_state,
			str(review.get("id", "")),
			definition,
			side if side != "watch" else "include",
			int(review.get("announcement_day_number", 0)),
			int(review.get("effective_day_number", 0)),
			review.get("announcement_date", {}),
			review.get("effective_date", {}),
			row
		)
		if side == "watch":
			action["category"] = "index_watch"
			action["side"] = "watch"
		rows.append(_candidate_watch_row(action))
	return rows


func _candidate_watch_row(action: Dictionary) -> Dictionary:
	var side: String = str(action.get("side", "watch"))
	var provider_label: String = str(action.get("provider_label", "Index"))
	var side_label: String = "watch"
	if side == "include":
		side_label = "inclusion candidate"
	elif side == "exclude":
		side_label = "exclusion risk"
	return {
		"provider_id": str(action.get("provider_id", "")),
		"provider_label": provider_label,
		"company_id": str(action.get("company_id", "")),
		"ticker": str(action.get("ticker", "")),
		"side": side,
		"category": str(action.get("category", "index_watch")),
		"label": "%s %s" % [provider_label, side_label],
		"review_id": str(action.get("review_id", "")),
		"announcement_day_number": int(action.get("announcement_day_number", 0)),
		"effective_day_number": int(action.get("effective_day_number", 0)),
		"rank": int(action.get("rank", 0)),
		"eligibility_score": float(action.get("eligibility_score", 0.0))
	}


func _merge_candidate_watch_rows(existing_rows: Array, next_rows: Array) -> Array:
	var rows_by_key: Dictionary = {}
	for row_value in existing_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		rows_by_key["%s|%s|%s" % [str(row.get("provider_id", "")), str(row.get("company_id", "")), str(row.get("review_id", ""))]] = row.duplicate(true)
	for row_value in next_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		rows_by_key["%s|%s|%s" % [str(row.get("provider_id", "")), str(row.get("company_id", "")), str(row.get("review_id", ""))]] = row.duplicate(true)
	var rows: Array = rows_by_key.values()
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("effective_day_number", 0)) == int(b.get("effective_day_number", 0)):
			return str(a.get("ticker", "")) < str(b.get("ticker", ""))
		return int(a.get("effective_day_number", 0)) < int(b.get("effective_day_number", 0))
	)
	return rows


func _remove_candidate_watch_row(existing_rows: Array, action: Dictionary) -> Array:
	var rows: Array = []
	var provider_id: String = str(action.get("provider_id", ""))
	var company_id: String = str(action.get("company_id", ""))
	var review_id: String = str(action.get("review_id", ""))
	for row_value in existing_rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("provider_id", "")) == provider_id and str(row.get("company_id", "")) == company_id and str(row.get("review_id", "")) == review_id:
			continue
		rows.append(row.duplicate(true))
	return rows


func _candidate_watch_for_company(provider_state: Dictionary, company_id: String, current_day_number: int) -> Dictionary:
	var best_row: Dictionary = {}
	for row_value in provider_state.get("candidate_watch", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("company_id", "")) != company_id:
			continue
		if int(row.get("effective_day_number", 0)) + COOLDOWN_DAYS < current_day_number:
			continue
		if best_row.is_empty() or int(row.get("effective_day_number", 0)) < int(best_row.get("effective_day_number", 999999)):
			best_row = row.duplicate(true)
	return best_row


func _merge_pending_actions(existing_actions: Array, next_actions: Array) -> Array:
	var actions_by_id: Dictionary = {}
	for action_value in existing_actions:
		if typeof(action_value) == TYPE_DICTIONARY:
			actions_by_id[str(action_value.get("action_id", ""))] = action_value.duplicate(true)
	for action_value in next_actions:
		if typeof(action_value) == TYPE_DICTIONARY:
			actions_by_id[str(action_value.get("action_id", ""))] = action_value.duplicate(true)
	return actions_by_id.values()


func _append_history(state: Dictionary, row: Dictionary) -> Dictionary:
	if row.is_empty():
		return state
	var history: Array = state.get("review_history", []).duplicate(true)
	history.append(row)
	if history.size() > 96:
		history = history.slice(history.size() - 96, history.size())
	state["review_history"] = history
	return state


func _history_row(provider_state: Dictionary, review: Dictionary, actions: Array, stage: String) -> Dictionary:
	return {
		"id": "%s|%s|%d" % [str(review.get("id", "")), stage, actions.size()],
		"provider_id": str(provider_state.get("id", "")),
		"provider_label": str(provider_state.get("label", "")),
		"review_id": str(review.get("id", "")),
		"stage": stage,
		"action_count": actions.size(),
		"actions": actions.duplicate(true)
	}


func _provider_summary_rows(state: Dictionary) -> Array:
	var rows: Array = []
	for provider_state_value in state.get("providers", {}).values():
		if typeof(provider_state_value) != TYPE_DICTIONARY:
			continue
		var provider_state: Dictionary = provider_state_value
		rows.append({
			"provider_id": str(provider_state.get("id", "")),
			"provider_label": str(provider_state.get("label", "")),
			"member_count": provider_state.get("members", []).size(),
			"candidate_watch_count": provider_state.get("candidate_watch", []).size()
		})
	return rows


func _provider_company_status_label(provider_label: String, is_member: bool, candidate_row: Dictionary) -> String:
	if not candidate_row.is_empty():
		return str(candidate_row.get("label", ""))
	return "%s member" % provider_label if is_member else "Not in %s" % provider_label


func _company_index_summary_label(membership_labels: Array, candidate_labels: Array) -> String:
	var parts: Array = []
	if not membership_labels.is_empty():
		parts.append("Member: %s" % ", ".join(membership_labels))
	if not candidate_labels.is_empty():
		parts.append("Watch: %s" % ", ".join(candidate_labels))
	if parts.is_empty():
		return "No MSCY/FTSI membership"
	return " | ".join(parts)


func _prune_state_for_current_day(state: Dictionary, current_day_number: int) -> Dictionary:
	var providers: Dictionary = state.get("providers", {}).duplicate(true)
	for provider_id_value in providers.keys():
		var provider_id: String = str(provider_id_value)
		var provider_state: Dictionary = providers.get(provider_id, {}).duplicate(true)
		var pruned_watch: Array = []
		for row_value in provider_state.get("candidate_watch", []):
			if typeof(row_value) != TYPE_DICTIONARY:
				continue
			var row: Dictionary = row_value
			if int(row.get("effective_day_number", 0)) + COOLDOWN_DAYS >= current_day_number:
				pruned_watch.append(row.duplicate(true))
		provider_state["candidate_watch"] = pruned_watch
		providers[provider_id] = provider_state
	state["providers"] = providers
	return state


func _normalize_int_array(source_values: Variant) -> Array:
	var values: Array = []
	if typeof(source_values) != TYPE_ARRAY:
		return values
	for value in source_values:
		var int_value: int = int(value)
		if int_value <= 0 or values.has(int_value):
			continue
		values.append(int_value)
	values.sort()
	return values


func _total_phase_duration(phase_schedule: Array) -> int:
	var total: int = 0
	for phase_value in phase_schedule:
		if typeof(phase_value) == TYPE_DICTIONARY:
			total += max(int(phase_value.get("duration_days", 1)), 1)
	return total
