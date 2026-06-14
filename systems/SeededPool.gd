extends RefCounted


static func pick_value_with_random_number_generator(values: Array, rng: RandomNumberGenerator, default_value: Variant = null) -> Variant:
	if values.is_empty():
		return default_value
	return values[rng.randi_range(0, values.size() - 1)]


static func pick_string_with_random_number_generator(
	values: Array,
	preferred_values: Array,
	excluded_values: Array,
	rng: RandomNumberGenerator,
	default_value: String = ""
) -> String:
	var pool: Array = string_candidate_pool(values, preferred_values, excluded_values)
	if pool.is_empty():
		return default_value
	return str(pick_value_with_random_number_generator(pool, rng, default_value))


static func pick_value_at_index(values: Array, index: int, default_value: Variant = null) -> Variant:
	if values.is_empty():
		return default_value
	return values[clamp(index, 0, values.size() - 1)]


static func string_candidate_pool(values: Array, preferred_values: Array = [], excluded_values: Array = []) -> Array:
	var preferred_pool: Array = []
	for preferred_value in preferred_values:
		var preferred_word: String = str(preferred_value)
		if values.has(preferred_word) and not excluded_values.has(preferred_word):
			preferred_pool.append(preferred_word)
	if not preferred_pool.is_empty():
		return preferred_pool

	var general_pool: Array = []
	for value in values:
		var word: String = str(value)
		if not excluded_values.has(word):
			general_pool.append(word)
	return general_pool
