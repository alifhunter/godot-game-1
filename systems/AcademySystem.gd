extends RefCounted

const DEFAULT_CATEGORY_ID := "technical"
const DEFAULT_SECTION_ID := "intro"
const QUIZ_SECTION_ID := "quiz"
const GLOSSARY_SECTION_ID := "glossary"


func build_snapshot(
	catalog: Dictionary,
	progress: Dictionary,
	category_id: String = DEFAULT_CATEGORY_ID,
	section_id: String = ""
) -> Dictionary:
	var normalized_progress: Dictionary = _normalize_progress(progress)
	var categories: Array = _category_snapshots(catalog, normalized_progress, category_id)
	var selected_category: Dictionary = _category_by_id(catalog, category_id)
	if selected_category.is_empty():
		selected_category = _category_by_id(catalog, DEFAULT_CATEGORY_ID)
	if selected_category.is_empty():
		return {
			"categories": categories,
			"category_id": "",
			"coming_soon": true,
			"sections": [],
			"selected_section": {},
			"progress": normalized_progress
		}

	var selected_category_id: String = str(selected_category.get("id", DEFAULT_CATEGORY_ID))
	var coming_soon: bool = str(selected_category.get("status", "coming_soon")) != "playable"
	var module_progress: Dictionary = _module_progress_snapshot(selected_category, normalized_progress)
	var quiz_state: Dictionary = _quiz_state(selected_category, normalized_progress)
	var sections: Array = []
	var selected_section: Dictionary = {}
	if not coming_soon:
		sections = _section_snapshots(selected_category, normalized_progress)
		selected_section = _resolve_selected_section(sections, section_id)

	var snapshot: Dictionary = {
		"categories": categories,
		"category_id": selected_category_id,
		"category_label": str(selected_category.get("label", selected_category_id.capitalize())),
		"category_summary": str(selected_category.get("summary", "")),
		"coming_soon": coming_soon,
		"coming_soon_copy": str(selected_category.get("coming_soon_copy", "Coming soon.")),
		"sections": sections,
		"selected_section": selected_section,
		"selected_section_id": str(selected_section.get("id", "")),
		"progress": module_progress,
		"quiz": quiz_state,
		"badge": selected_category.get("badge", {}).duplicate(true) if typeof(selected_category.get("badge", {})) == TYPE_DICTIONARY else {},
		"glossary": _search_glossary(catalog, "")
	}
	return snapshot


func mark_section_read(
	catalog: Dictionary,
	progress: Dictionary,
	category_id: String,
	section_id: String
) -> Dictionary:
	var normalized_progress: Dictionary = _normalize_progress(progress)
	var category: Dictionary = _category_by_id(catalog, category_id)
	if category.is_empty() or str(category.get("status", "")) != "playable":
		return {"success": false, "message": "Academy category is not available.", "progress": normalized_progress}

	var section: Dictionary = _section_by_id(category, section_id)
	if section.is_empty() or bool(section.get("locked", false)) or str(section.get("kind", "lesson")) == "quiz":
		return {"success": false, "message": "That section cannot be marked read yet.", "progress": normalized_progress}

	var category_key: String = str(category.get("id", category_id))
	var read_sections: Dictionary = normalized_progress.get("read_sections", {})
	var read_list: Array = read_sections.get(category_key, [])
	if not read_list.has(section_id):
		read_list.append(section_id)
	read_sections[category_key] = read_list
	normalized_progress["read_sections"] = read_sections
	normalized_progress["last_category_id"] = category_key
	normalized_progress["last_section_id"] = section_id
	return {
		"success": true,
		"message": "%s marked read." % str(section.get("label", section_id)),
		"progress": normalized_progress,
		"snapshot": build_snapshot(catalog, normalized_progress, category_key, section_id)
	}


func submit_inline_check(
	catalog: Dictionary,
	progress: Dictionary,
	category_id: String,
	section_id: String,
	check_id: String,
	answer_id: String
) -> Dictionary:
	var normalized_progress: Dictionary = _normalize_progress(progress)
	var category: Dictionary = _category_by_id(catalog, category_id)
	var section: Dictionary = _section_by_id(category, section_id)
	var check: Dictionary = _check_by_id(section, check_id)
	if check.is_empty():
		return {"success": false, "message": "Quick check not found.", "progress": normalized_progress}

	var answer: Dictionary = _answer_by_id(check.get("options", []), answer_id)
	if answer.is_empty():
		return {"success": false, "message": "Answer not found.", "progress": normalized_progress}

	var category_key: String = str(category.get("id", category_id))
	var inline_checks: Dictionary = normalized_progress.get("inline_checks", {})
	var category_checks: Dictionary = inline_checks.get(category_key, {})
	var section_checks: Dictionary = category_checks.get(section_id, {})
	var is_correct: bool = bool(answer.get("correct", false))
	var feedback_text: String = str(answer.get("feedback", ""))
	if feedback_text.is_empty():
		feedback_text = str(check.get("feedback_correct", "")) if is_correct else str(check.get("feedback_wrong", ""))
	section_checks[check_id] = {
		"answer_id": answer_id,
		"correct": is_correct,
		"feedback": feedback_text
	}
	category_checks[section_id] = section_checks
	inline_checks[category_key] = category_checks
	normalized_progress["inline_checks"] = inline_checks
	normalized_progress["last_category_id"] = category_key
	normalized_progress["last_section_id"] = section_id
	return {
		"success": true,
		"correct": is_correct,
		"message": "Correct." if is_correct else "Try that one again.",
		"feedback": str(section_checks[check_id].get("feedback", "")),
		"progress": normalized_progress,
		"snapshot": build_snapshot(catalog, normalized_progress, category_key, section_id)
	}


func submit_quiz(catalog: Dictionary, progress: Dictionary, category_id: String, answers: Dictionary) -> Dictionary:
	var normalized_progress: Dictionary = _normalize_progress(progress)
	var category: Dictionary = _category_by_id(catalog, category_id)
	if category.is_empty() or str(category.get("status", "")) != "playable":
		return {"success": false, "message": "Quiz not available.", "progress": normalized_progress}

	var quiz_state: Dictionary = _quiz_state(category, normalized_progress)
	if bool(quiz_state.get("locked", true)):
		return {
			"success": false,
			"message": "Read the required sections first.",
			"locked": true,
			"unread_required_sections": quiz_state.get("unread_required_sections", []).duplicate(true),
			"progress": normalized_progress
		}

	var questions: Array = category.get("quiz_questions", [])
	var feedback_rows: Array = []
	var correct_count: int = 0
	for question_value in questions:
		var question: Dictionary = question_value
		var question_id: String = str(question.get("id", ""))
		var chosen_answer_id: String = str(answers.get(question_id, ""))
		var correct_answer_id: String = str(question.get("correct_answer_id", ""))
		var is_correct: bool = chosen_answer_id == correct_answer_id
		if is_correct:
			correct_count += 1
		feedback_rows.append({
			"id": question_id,
			"prompt": str(question.get("prompt", "")),
			"chosen_answer_id": chosen_answer_id,
			"correct_answer_id": correct_answer_id,
			"correct": is_correct,
			"feedback": str(question.get("feedback_correct", "")) if is_correct else str(question.get("feedback_wrong", "Review the related section and try again."))
		})

	var total_questions: int = max(questions.size(), 1)
	var score_ratio: float = float(correct_count) / float(total_questions)
	var passing_score: float = float(category.get("quiz_passing_score", 0.8))
	var passed: bool = score_ratio + 0.0001 >= passing_score
	var category_key: String = str(category.get("id", category_id))
	var attempts: Dictionary = normalized_progress.get("quiz_attempts", {})
	attempts[category_key] = int(attempts.get(category_key, 0)) + 1
	normalized_progress["quiz_attempts"] = attempts

	var best_scores: Dictionary = normalized_progress.get("quiz_best_score", {})
	best_scores[category_key] = max(float(best_scores.get(category_key, 0.0)), score_ratio)
	normalized_progress["quiz_best_score"] = best_scores

	var passed_map: Dictionary = normalized_progress.get("quiz_passed", {})
	if passed:
		passed_map[category_key] = true
	normalized_progress["quiz_passed"] = passed_map

	var badge: Dictionary = category.get("badge", {})
	var badge_id: String = str(badge.get("id", ""))
	if passed and not badge_id.is_empty():
		var badges: Array = normalized_progress.get("badges", [])
		if not badges.has(badge_id):
			badges.append(badge_id)
		normalized_progress["badges"] = badges
		var completed_modules: Array = normalized_progress.get("completed_modules", [])
		if not completed_modules.has(category_key):
			completed_modules.append(category_key)
		normalized_progress["completed_modules"] = completed_modules

	var quiz_section_id: String = _section_id_by_kind(category, "quiz", QUIZ_SECTION_ID)
	normalized_progress["last_category_id"] = category_key
	normalized_progress["last_section_id"] = quiz_section_id
	return {
		"success": true,
		"passed": passed,
		"score": score_ratio,
		"score_percent": int(round(score_ratio * 100.0)),
		"correct_count": correct_count,
		"total_questions": questions.size(),
		"passing_score": passing_score,
		"feedback": feedback_rows,
		"badge_granted": passed and not badge_id.is_empty(),
		"badge": badge.duplicate(true) if typeof(badge) == TYPE_DICTIONARY else {},
		"progress": normalized_progress,
		"snapshot": build_snapshot(catalog, normalized_progress, category_key, quiz_section_id)
	}


func search_glossary(catalog: Dictionary, query: String) -> Array:
	return _search_glossary(catalog, query)


func _category_snapshots(catalog: Dictionary, progress: Dictionary, selected_category_id: String) -> Array:
	var rows: Array = []
	for category_value in catalog.get("categories", []):
		var category: Dictionary = category_value
		var category_id: String = str(category.get("id", ""))
		rows.append({
			"id": category_id,
			"label": str(category.get("label", category_id.capitalize())),
			"status": str(category.get("status", "coming_soon")),
			"selected": category_id == selected_category_id,
			"progress": _module_progress_snapshot(category, progress)
		})
	return rows


func _section_snapshots(category: Dictionary, progress: Dictionary) -> Array:
	var rows: Array = []
	var category_id: String = str(category.get("id", DEFAULT_CATEGORY_ID))
	var read_lookup: Dictionary = _read_lookup(progress, category_id)
	var quiz_state: Dictionary = _quiz_state(category, progress)
	for section_value in category.get("sections", []):
		var section: Dictionary = section_value
		var section_id: String = str(section.get("id", ""))
		var kind: String = str(section.get("kind", "lesson"))
		var locked: bool = kind == "quiz" and bool(quiz_state.get("locked", true))
		var section_row: Dictionary = section.duplicate(true)
		section_row["read"] = bool(read_lookup.get(section_id, false))
		section_row["locked"] = locked
		if locked:
			var unread_labels: Array[String] = []
			for unread_value in quiz_state.get("unread_required_sections", []):
				var unread: Dictionary = unread_value
				unread_labels.append(str(unread.get("label", "")))
			section_row["lock_reason"] = "Read %s first." % ", ".join(unread_labels)
		rows.append(section_row)
	return rows


func _resolve_selected_section(sections: Array, section_id: String) -> Dictionary:
	var fallback: Dictionary = {}
	for section_value in sections:
		var section: Dictionary = section_value
		if fallback.is_empty() and not bool(section.get("locked", false)):
			fallback = section
		if str(section.get("id", "")) == section_id and not bool(section.get("locked", false)):
			return section
	return fallback


func _module_progress_snapshot(category: Dictionary, progress: Dictionary) -> Dictionary:
	var category_id: String = str(category.get("id", DEFAULT_CATEGORY_ID))
	var readable_count: int = 0
	var read_count: int = 0
	var read_lookup: Dictionary = _read_lookup(progress, category_id)
	for section_value in category.get("sections", []):
		var section: Dictionary = section_value
		var kind: String = str(section.get("kind", "lesson"))
		if kind == "quiz" or kind == "glossary":
			continue
		readable_count += 1
		if bool(read_lookup.get(str(section.get("id", "")), false)):
			read_count += 1
	var quiz_passed: bool = bool(progress.get("quiz_passed", {}).get(category_id, false))
	return {
		"read_count": read_count,
		"readable_count": readable_count,
		"read_ratio": float(read_count) / float(max(readable_count, 1)),
		"quiz_attempts": int(progress.get("quiz_attempts", {}).get(category_id, 0)),
		"best_score": float(progress.get("quiz_best_score", {}).get(category_id, 0.0)),
		"quiz_passed": quiz_passed,
		"badge_earned": progress.get("badges", []).has(str(category.get("badge", {}).get("id", "")))
	}


func _quiz_state(category: Dictionary, progress: Dictionary) -> Dictionary:
	var category_id: String = str(category.get("id", DEFAULT_CATEGORY_ID))
	var read_lookup: Dictionary = _read_lookup(progress, category_id)
	var unread: Array = []
	for required_id_value in category.get("quiz_required_section_ids", []):
		var required_id: String = str(required_id_value)
		if not bool(read_lookup.get(required_id, false)):
			var required_section: Dictionary = _section_by_id(category, required_id)
			unread.append({
				"id": required_id,
				"label": str(required_section.get("label", required_id.capitalize()))
			})
	var best_score: float = float(progress.get("quiz_best_score", {}).get(category_id, 0.0))
	return {
		"locked": not unread.is_empty(),
		"unread_required_sections": unread,
		"passing_score": float(category.get("quiz_passing_score", 0.8)),
		"best_score": best_score,
		"best_score_percent": int(round(best_score * 100.0)),
		"attempts": int(progress.get("quiz_attempts", {}).get(category_id, 0)),
		"passed": bool(progress.get("quiz_passed", {}).get(category_id, false)),
		"question_count": category.get("quiz_questions", []).size()
	}


func _read_lookup(progress: Dictionary, category_id: String) -> Dictionary:
	var lookup: Dictionary = {}
	for section_id_value in progress.get("read_sections", {}).get(category_id, []):
		lookup[str(section_id_value)] = true
	return lookup


func _category_by_id(catalog: Dictionary, category_id: String) -> Dictionary:
	for category_value in catalog.get("categories", []):
		var category: Dictionary = category_value
		if str(category.get("id", "")) == category_id:
			return category.duplicate(true)
	return {}


func _section_by_id(category: Dictionary, section_id: String) -> Dictionary:
	for section_value in category.get("sections", []):
		var section: Dictionary = section_value
		if str(section.get("id", "")) == section_id:
			return section.duplicate(true)
	return {}


func _section_id_by_kind(category: Dictionary, kind: String, fallback: String) -> String:
	for section_value in category.get("sections", []):
		var section: Dictionary = section_value
		if str(section.get("kind", "")) == kind:
			return str(section.get("id", fallback))
	return fallback


func _check_by_id(section: Dictionary, check_id: String) -> Dictionary:
	for check_value in section.get("checks", []):
		var check: Dictionary = check_value
		if str(check.get("id", "")) == check_id:
			return check.duplicate(true)
	return {}


func _answer_by_id(options: Array, answer_id: String) -> Dictionary:
	for option_value in options:
		var option: Dictionary = option_value
		if str(option.get("id", "")) == answer_id:
			return option.duplicate(true)
	return {}


func _search_glossary(catalog: Dictionary, query: String) -> Array:
	var normalized_query: String = query.strip_edges().to_lower()
	var rows: Array = []
	for term_value in catalog.get("glossary", []):
		var term: Dictionary = term_value
		var label: String = str(term.get("term", ""))
		var definition: String = str(term.get("definition", ""))
		if normalized_query.is_empty() or label.to_lower().contains(normalized_query) or definition.to_lower().contains(normalized_query):
			rows.append(term.duplicate(true))
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("term", "")) < str(b.get("term", ""))
	)
	return rows


func _normalize_progress(source_progress: Dictionary) -> Dictionary:
	var normalized: Dictionary = RunState._normalize_academy_progress(source_progress)
	return normalized
