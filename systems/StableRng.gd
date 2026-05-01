extends RefCounted

const DEFAULT_VERSION := 1
const FNV_OFFSET := 2166136261
const FNV_PRIME := 16777619
const FNV_MASK := 0xffffffff


static func seed_from_parts(parts: Array, version: int = DEFAULT_VERSION) -> int:
	var source: String = "rng_v%d" % version
	for part_value in parts:
		source += "|%s" % str(part_value)

	var hash_value: int = FNV_OFFSET
	for character_index in range(source.length()):
		hash_value = int((hash_value ^ source.unicode_at(character_index)) * FNV_PRIME) & FNV_MASK
	if hash_value == 0:
		return 1
	return hash_value


static func rng(parts: Array, version: int = DEFAULT_VERSION) -> RandomNumberGenerator:
	var generator: RandomNumberGenerator = RandomNumberGenerator.new()
	generator.seed = seed_from_parts(parts, version)
	return generator


static func unit_float(parts: Array, version: int = DEFAULT_VERSION) -> float:
	return float(seed_from_parts(parts, version) % 1000000) / 1000000.0


static func int_between(parts: Array, min_value: int, max_value: int, version: int = DEFAULT_VERSION) -> int:
	if max_value <= min_value:
		return min_value
	return min_value + int(seed_from_parts(parts, version) % (max_value - min_value + 1))
