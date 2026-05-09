extends RefCounted

const STABLE_RNG = preload("res://systems/StableRng.gd")
const UINT32_RANGE := 4294967296.0
const MULBERRY32_INCREMENT := 0x6D2B79F5
const PROFILE_SCALE_VERSION := 1
const SCALE_TIER_SIZE_IDS := {
	"micro": 0,
	"small": 1,
	"mid": 2,
	"large": 3,
	"giant": 4
}
const SIZE_TAG_RULES := {
	"micro-cap": {"max": 0},
	"small-cap": {"min": 1, "max": 1},
	"mid-cap": {"min": 2, "max": 2},
	"large-cap": {"min": 3},
	"mega-cap": {"min": 4},
	"blue-chip": {"min": 3},
	"systemic": {"min": 4},
	"institutional-grade": {"min": 3},
	"market-followed": {"min": 3},
	"market-leader": {"min": 3},
	"national-champion": {"min": 3}
}


func build_profile(
	template: Dictionary,
	sector_definition: Dictionary,
	financials: Dictionary,
	run_seed: int,
	company_id: String
) -> Dictionary:
	var profile_data: Dictionary = DataRepository.get_company_profile_data_ref()
	if profile_data.is_empty():
		return {}

	var sector_id: String = str(sector_definition.get("id", template.get("sector_id", "")))
	var sectors: Dictionary = profile_data.get("sectors", {})
	if not sectors.has(sector_id):
		return {}

	var sector_data: Dictionary = sectors.get(sector_id, {}).duplicate(true)
	var sector_name: String = str(sector_definition.get("name", sector_id.capitalize()))
	var rng: Dictionary = _make_rng(_seed_from(run_seed, company_id))
	var scale_size_id: int = _size_id_from_scale(template, financials)
	var archetype_id: String = _pick_archetype_id(profile_data, sector_id, rng, scale_size_id)
	if archetype_id.is_empty():
		return {}

	var archetype_data: Dictionary = profile_data.get("archetypes", {}).get(archetype_id, {}).duplicate(true)
	var size_id: int = _pick_size_id(profile_data, archetype_data, float(financials.get("revenue", 0.0)), rng, scale_size_id)
	var size_data: Dictionary = profile_data.get("sizes", {}).get(str(size_id), {}).duplicate(true)
	var age: int = _pick_age(archetype_data, size_id, rng)
	var reference_year: int = int(profile_data.get("reference_year", 2020))
	var founded_year: int = max(reference_year - age, 1870)
	var employees: int = _pick_employees(size_data, archetype_data, age, rng)
	var revenue: float = max(float(financials.get("revenue", 0.0)), 0.0)
	var compact_revenue: Dictionary = _compact_revenue(revenue)
	var description: String = _build_description(
		profile_data,
		template,
		sector_name,
		sector_data,
		archetype_data,
		size_data,
		age,
		founded_year,
		employees,
		compact_revenue,
		rng
	)
	var tags: Array = _build_tags(profile_data, sector_id, archetype_id, size_id, rng)

	return {
		"profile_seed": int(rng.get("initial_seed", 0)),
		"profile_scale_version": PROFILE_SCALE_VERSION,
		"archetype_id": archetype_id,
		"archetype_label": str(archetype_data.get("label", archetype_id.capitalize())),
		"company_size_id": size_id,
		"company_size_label": str(size_data.get("label", "Unknown")),
		"company_age": age,
		"founded_year": founded_year,
		"employee_count": employees,
		"profile_revenue": revenue,
		"profile_revenue_value": float(compact_revenue.get("value", 0.0)),
		"profile_revenue_unit": str(compact_revenue.get("unit", "")),
		"profile_description": description,
		"profile_tags": tags
	}


func _pick_archetype_id(profile_data: Dictionary, sector_id: String, rng: Dictionary, size_id: int = -1) -> String:
	var sector_weights: Dictionary = profile_data.get("archetype_weights_by_sector", {}).get(sector_id, {})
	if sector_weights.is_empty():
		return ""

	var archetypes: Dictionary = profile_data.get("archetypes", {})
	var archetype_ids: Array = sector_weights.keys()
	archetype_ids.sort()
	var options: Array = []
	var weights: Array = []
	for archetype_id_value in archetype_ids:
		var archetype_id: String = str(archetype_id_value)
		var archetype_data: Dictionary = archetypes.get(archetype_id, {})
		if size_id >= 0 and not _archetype_supports_size(archetype_data, size_id):
			continue
		options.append(archetype_id)
		weights.append(max(float(sector_weights.get(archetype_id, 0.0)), 0.01))

	if options.is_empty():
		for archetype_id_value in archetype_ids:
			var archetype_id: String = str(archetype_id_value)
			options.append(archetype_id)
			weights.append(max(float(sector_weights.get(archetype_id, 0.0)), 0.01))
	return str(_pick_weighted(options, weights, rng))


func _pick_size_id(profile_data: Dictionary, archetype_data: Dictionary, revenue: float, rng: Dictionary, scale_size_id: int = -1) -> int:
	var sizes: Dictionary = profile_data.get("sizes", {})
	if scale_size_id >= 0 and sizes.has(str(scale_size_id)):
		return scale_size_id

	var size_weights: Dictionary = archetype_data.get("size_weights", {})
	var allowed_sizes: Array = archetype_data.get("allowed_sizes", [])
	var options: Array = []
	var weights: Array = []

	for size_value in allowed_sizes:
		var size_id: int = int(size_value)
		var size_data: Dictionary = sizes.get(str(size_id), {})
		if size_data.is_empty():
			continue

		var weight: float = max(float(size_weights.get(str(size_id), 1.0)), 0.01)
		weight *= _revenue_hint_weight(revenue, size_data.get("revenue_hint_range", []))
		options.append(size_id)
		weights.append(weight)

	if options.is_empty():
		return 1
	return int(_pick_weighted(options, weights, rng))


func _size_id_from_scale(template: Dictionary, financials: Dictionary) -> int:
	var anchors: Dictionary = template.get("anchors", {})
	var scale_tier: String = str(anchors.get("scale_tier", "")).strip_edges().to_lower()
	if SCALE_TIER_SIZE_IDS.has(scale_tier):
		return int(SCALE_TIER_SIZE_IDS.get(scale_tier, -1))

	var market_cap: float = float(financials.get("market_cap", anchors.get("market_cap", 0.0)))
	if market_cap <= 0.0:
		return -1
	if market_cap < 950000000000.0:
		return 0
	if market_cap < 2500000000000.0:
		return 1
	if market_cap < 10000000000000.0:
		return 2
	if market_cap < 35000000000000.0:
		return 3
	return 4


func _archetype_supports_size(archetype_data: Dictionary, size_id: int) -> bool:
	for allowed_size_value in archetype_data.get("allowed_sizes", []):
		if int(allowed_size_value) == size_id:
			return true
	return false


func _pick_age(archetype_data: Dictionary, size_id: int, rng: Dictionary) -> int:
	var age_range: Array = archetype_data.get("age_range", [3, 20])
	var minimum_age: int = int(age_range[0]) if age_range.size() > 0 else 3
	var maximum_age: int = int(age_range[1]) if age_range.size() > 1 else minimum_age
	if maximum_age <= minimum_age:
		return minimum_age

	var size_bias: float = clamp(float(size_id) / 4.0, 0.0, 1.0)
	var blend: float = clamp((_next_float(rng) + size_bias) * 0.5, 0.0, 1.0)
	return int(round(lerp(float(minimum_age), float(maximum_age), blend)))


func _pick_employees(size_data: Dictionary, archetype_data: Dictionary, age: int, rng: Dictionary) -> int:
	var employee_range: Array = size_data.get("employee_range", [100, 1000])
	var minimum_employees: int = int(employee_range[0]) if employee_range.size() > 0 else 100
	var maximum_employees: int = int(employee_range[1]) if employee_range.size() > 1 else minimum_employees
	if maximum_employees <= minimum_employees:
		return minimum_employees

	var age_range: Array = archetype_data.get("age_range", [1, 20])
	var minimum_age: float = float(age_range[0]) if age_range.size() > 0 else 1.0
	var maximum_age: float = float(age_range[1]) if age_range.size() > 1 else minimum_age
	var age_ratio: float = 0.5
	if maximum_age > minimum_age:
		age_ratio = clamp((float(age) - minimum_age) / (maximum_age - minimum_age), 0.0, 1.0)

	var blend: float = clamp((_next_float(rng) + age_ratio) * 0.5, 0.0, 1.0)
	var raw_value: float = lerp(float(minimum_employees), float(maximum_employees), blend)
	return _round_employee_count(int(round(raw_value)))


func _build_description(
	profile_data: Dictionary,
	template: Dictionary,
	sector_name: String,
	sector_data: Dictionary,
	archetype_data: Dictionary,
	size_data: Dictionary,
	age: int,
	founded_year: int,
	employees: int,
	compact_revenue: Dictionary,
	rng: Dictionary
) -> String:
	var company_name: String = str(template.get("name", "Unknown Company"))
	var primary_template: String = _pick_string(profile_data.get("sentence_templates", {}).get("primary_pool", []), rng)
	var sector_business: String = _pick_string(sector_data.get("business_pool", []), rng)
	var scope_sentence: String = _pick_string(sector_data.get("scope_pool", []), rng)
	var size_descriptor: String = _pick_string(size_data.get("descriptor_pool", []), rng)
	var archetype_descriptor: String = _pick_string(archetype_data.get("descriptor_pool", []), rng)
	var archetype_verb: String = _pick_string(archetype_data.get("verb_pool", []), rng)
	var tokens: Dictionary = {
		"{COMPANY}": company_name,
		"{SECTOR}": sector_name,
		"{ARCHETYPE}": str(archetype_data.get("label", "")),
		"{SIZE_DESCRIPTOR}": size_descriptor,
		"{ARCHETYPE_DESCRIPTOR}": archetype_descriptor,
		"{ARCHETYPE_VERB}": archetype_verb,
		"{SECTOR_BUSINESS}": sector_business,
		"{AGE}": str(age),
		"{FOUNDED}": str(founded_year),
		"{EMPLOYEES}": _format_integer(employees),
		"{REVENUE}": String.num(float(compact_revenue.get("value", 0.0)), 2),
		"{REVENUE_UNIT}": str(compact_revenue.get("unit", ""))
	}

	var sentences: Array = []
	var primary_sentence: String = _fill_template(primary_template, tokens)
	if not primary_sentence.is_empty():
		sentences.append(primary_sentence)
	if not scope_sentence.is_empty():
		sentences.append(_fill_template(scope_sentence, tokens))

	var probability: float = float(profile_data.get("sentence_settings", {}).get("optional_third_sentence_probability", 0.55))
	if _next_float(rng) <= probability:
		var differentiator_pool: Array = []
		for sentence_value in archetype_data.get("differentiator_pool", []):
			differentiator_pool.append(sentence_value)
		for sentence_value in sector_data.get("differentiator_pool", []):
			differentiator_pool.append(sentence_value)
		for tag_value in template.get("narrative_tags", []):
			for sentence_value in profile_data.get("narrative_tag_sentences", {}).get(str(tag_value), []):
				differentiator_pool.append(sentence_value)
		for sentence_value in profile_data.get("global_differentiator_pool", []):
			differentiator_pool.append(sentence_value)
		var differentiator: String = _pick_string(differentiator_pool, rng)
		if not differentiator.is_empty():
			sentences.append(_fill_template(differentiator, tokens))

	return _join_sentences(sentences)


func _build_tags(profile_data: Dictionary, sector_id: String, archetype_id: String, size_id: int, rng: Dictionary) -> Array:
	var tags: Array = []
	var archetype_pool: Array = profile_data.get("archetypes", {}).get(archetype_id, {}).get("tag_pool", [])
	var sector_pool: Array = profile_data.get("sectors", {}).get(sector_id, {}).get("tag_pool", [])
	var size_pool: Array = profile_data.get("sizes", {}).get(str(size_id), {}).get("tag_pool", [])
	var combined_pool: Array = []

	_add_unique_tag(tags, _pick_string(archetype_pool, rng))
	_add_unique_tag(tags, _pick_string(sector_pool, rng))
	if _next_float(rng) < 0.82:
		_add_unique_tag(tags, _pick_string(size_pool, rng))

	for tag_value in archetype_pool:
		combined_pool.append(tag_value)
	for tag_value in sector_pool:
		combined_pool.append(tag_value)
	for tag_value in size_pool:
		combined_pool.append(tag_value)

	if _next_float(rng) < 0.48:
		_add_unique_tag(tags, _pick_string(combined_pool, rng))

	while tags.size() < 2 and not combined_pool.is_empty():
		_add_unique_tag(tags, _pick_string(combined_pool, rng))
	tags = _filter_size_consistent_tags(tags, size_id)
	while tags.size() < 2 and not size_pool.is_empty():
		_add_unique_tag(tags, _pick_string(size_pool, rng))
	tags = _filter_size_consistent_tags(tags, size_id)
	if tags.size() > 4:
		return tags.slice(0, 4)
	return tags


func _filter_size_consistent_tags(tags: Array, size_id: int) -> Array:
	var filtered: Array = []
	for tag_value in tags:
		var tag: String = str(tag_value).strip_edges()
		if tag.is_empty() or filtered.has(tag):
			continue
		if not _tag_matches_size(tag, size_id):
			continue
		filtered.append(tag)
	return filtered


func _tag_matches_size(tag: String, size_id: int) -> bool:
	var normalized_tag: String = tag.strip_edges().to_lower()
	if not SIZE_TAG_RULES.has(normalized_tag):
		return true
	var rule: Dictionary = SIZE_TAG_RULES.get(normalized_tag, {})
	var minimum_size: int = int(rule.get("min", 0))
	var maximum_size: int = int(rule.get("max", 4))
	return size_id >= minimum_size and size_id <= maximum_size


func _compact_revenue(revenue: float) -> Dictionary:
	var absolute_revenue: float = absf(revenue)
	if absolute_revenue >= 1000000000000.0:
		return {"value": revenue / 1000000000000.0, "unit": "T"}
	if absolute_revenue >= 1000000000.0:
		return {"value": revenue / 1000000000.0, "unit": "B"}
	if absolute_revenue >= 1000000.0:
		return {"value": revenue / 1000000.0, "unit": "M"}
	return {"value": revenue, "unit": ""}


func _revenue_hint_weight(revenue: float, revenue_hint_range: Array) -> float:
	if revenue <= 0.0 or revenue_hint_range.size() < 2:
		return 1.0

	var minimum_value: float = float(revenue_hint_range[0])
	var maximum_value: float = float(revenue_hint_range[1])
	if revenue >= minimum_value and revenue <= maximum_value:
		return 3.0
	if revenue < minimum_value:
		var minimum_ratio: float = revenue / max(minimum_value, 1.0)
		return 1.8 if minimum_ratio >= 0.55 else 0.75
	var maximum_ratio: float = maximum_value / max(revenue, 1.0)
	return 1.8 if maximum_ratio >= 0.55 else 0.75


func _fill_template(template_text: String, tokens: Dictionary) -> String:
	var resolved_text: String = str(template_text).strip_edges()
	for token_value in tokens.keys():
		var token: String = str(token_value)
		resolved_text = resolved_text.replace(token, str(tokens[token]))
	return resolved_text.strip_edges()


func _join_sentences(sentences: Array) -> String:
	var normalized_sentences: Array = []
	for sentence_value in sentences:
		var sentence: String = str(sentence_value).strip_edges()
		if sentence.is_empty():
			continue
		var last_character: String = sentence.substr(sentence.length() - 1, 1)
		if last_character not in [".", "!", "?"]:
			sentence += "."
		normalized_sentences.append(sentence)
	return " ".join(normalized_sentences)


func _pick_string(pool: Array, rng: Dictionary) -> String:
	if pool.is_empty():
		return ""
	return str(pool[_next_int(rng, 0, pool.size() - 1)])


func _pick_weighted(options: Array, weights: Array, rng: Dictionary) -> Variant:
	if options.is_empty():
		return null
	if options.size() != weights.size():
		return options[0]

	var total_weight: float = 0.0
	for weight_value in weights:
		total_weight += max(float(weight_value), 0.0)
	if total_weight <= 0.0:
		return options[0]

	var roll: float = _next_float(rng) * total_weight
	var running_total: float = 0.0
	for index in range(options.size()):
		running_total += max(float(weights[index]), 0.0)
		if roll <= running_total:
			return options[index]
	return options[options.size() - 1]


func _next_int(rng: Dictionary, minimum: int, maximum: int) -> int:
	if maximum <= minimum:
		return minimum
	return minimum + int(floor(_next_float(rng) * float((maximum - minimum) + 1)))


func _make_rng(seed_value: int) -> Dictionary:
	return {
		"state": _mask32(seed_value),
		"initial_seed": _mask32(seed_value)
	}


func _next_float(rng: Dictionary) -> float:
	var state: int = _mask32(int(rng.get("state", 0)) + MULBERRY32_INCREMENT)
	rng["state"] = state
	var value: int = state
	value = _imul32(value ^ _unsigned_right_shift(value, 15), value | 1)
	value = _mask32(value ^ _mask32(value + _imul32(value ^ _unsigned_right_shift(value, 7), value | 61)))
	return float(_mask32(value ^ _unsigned_right_shift(value, 14))) / UINT32_RANGE


func _imul32(left: int, right: int) -> int:
	var left_low: int = left & 0xffff
	var left_high: int = _unsigned_right_shift(left, 16) & 0xffff
	var right_low: int = right & 0xffff
	var right_high: int = _unsigned_right_shift(right, 16) & 0xffff
	var low: int = left_low * right_low
	var high: int = ((left_high * right_low) + (left_low * right_high)) & 0xffff
	return _mask32(low + (high << 16))


func _unsigned_right_shift(value: int, bits: int) -> int:
	return (_mask32(value) >> bits)


func _mask32(value: int) -> int:
	return value & 0xffffffff


func _seed_from(run_seed: int, company_id: String) -> int:
	return _mask32(STABLE_RNG.seed_from_parts([run_seed, "company_narrative", company_id]))


func _round_employee_count(value: int) -> int:
	var safe_value: int = max(value, 1)
	if safe_value >= 100000:
		return int(round(float(safe_value) / 1000.0) * 1000.0)
	if safe_value >= 10000:
		return int(round(float(safe_value) / 250.0) * 250.0)
	if safe_value >= 1000:
		return int(round(float(safe_value) / 50.0) * 50.0)
	if safe_value >= 250:
		return int(round(float(safe_value) / 10.0) * 10.0)
	return safe_value


func _format_integer(value: int) -> String:
	var negative: bool = value < 0
	var digits: String = str(abs(value))
	var groups: Array = []
	while digits.length() > 3:
		groups.push_front(digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	if not digits.is_empty():
		groups.push_front(digits)
	var joined: String = ",".join(groups)
	return "-%s" % joined if negative else joined


func _add_unique_tag(tags: Array, tag: String) -> void:
	var normalized_tag: String = str(tag).strip_edges().to_lower()
	if normalized_tag.is_empty() or tags.has(normalized_tag):
		return
	tags.append(normalized_tag)
