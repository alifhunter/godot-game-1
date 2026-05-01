extends RefCounted

const STABLE_RNG = preload("res://systems/StableRng.gd")
const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const FALLBACK_WORDS := [
	"Global",
	"Prima",
	"Digital",
	"Energy",
	"Capital",
	"Resources",
	"Indonesia",
	"Nusantara"
]
const BRAND_WORD_HINTS := [
	"Abadi",
	"Andalan",
	"Aneka",
	"Anugerah",
	"Artha",
	"Asa",
	"Avia",
	"Bayu",
	"Berkah",
	"Berlian",
	"Bina",
	"Bintang",
	"Buana",
	"Cahaya",
	"Cemerlang",
	"Citra",
	"Darma",
	"Delta",
	"Dewata",
	"Dharma",
	"Dian",
	"Duta",
	"Elang",
	"Era",
	"Eureka",
	"Fajar",
	"Fortune",
	"Garda",
	"Gema",
	"Gemilang",
	"Global",
	"Golden",
	"Graha",
	"Harapan",
	"Harta",
	"Hebat",
	"Heritage",
	"Idea",
	"Indah",
	"Intan",
	"Inti",
	"Jaya",
	"Karya",
	"Kencana",
	"Kirana",
	"Kreasi",
	"Krida",
	"Kumala",
	"Kurnia",
	"Kusuma",
	"Laksana",
	"Lestari",
	"Mahkota",
	"Makmur",
	"Mandiri",
	"Mentari",
	"Mitra",
	"Mulia",
	"Natura",
	"Neo",
	"Nusa",
	"Nusantara",
	"Pacific",
	"Pelita",
	"Perdana",
	"Perkasa",
	"Persada",
	"Pertiwi",
	"Pratama",
	"Prima",
	"Puncak",
	"Puri",
	"Pusaka",
	"Raja",
	"Ratu",
	"Raya",
	"Sarana",
	"Sari",
	"Satya",
	"Segar",
	"Sejahtera",
	"Selaras",
	"Sembada",
	"Semesta",
	"Sentosa",
	"Sentra",
	"Setia",
	"Sinar",
	"Sinergi",
	"Strategic",
	"Sukses",
	"Sumber",
	"Superior",
	"Surya",
	"Tera",
	"Terang",
	"Tiara",
	"Titan",
	"Unggul",
	"Utama",
	"Victoria",
	"Vision",
	"Wahana",
	"Wijaya",
	"Wira"
]
const TAIL_WORD_HINTS := [
	"Asia",
	"Global",
	"Indo",
	"Indonesia",
	"International",
	"Internasional",
	"Jaya",
	"Lestari",
	"Makmur",
	"Nusantara",
	"Persada",
	"Prima",
	"Raya",
	"Sejahtera",
	"Semesta",
	"Sentosa",
	"Utama",
	"Worldwide"
]
const NARRATIVE_TAG_POOL := [
	"domestic_demand",
	"quiet_execution",
	"stealth_interest",
	"retail_favorite",
	"narrative_hot",
	"commodity_beta",
	"policy_beta",
	"foreign_watchlist",
	"institution_quality",
	"supportive_balance_sheet",
	"capex_cycle"
]
const SECTOR_KEYWORD_HINTS := {
	"consumer": ["Food", "Store", "Dairy", "Boga", "Resto", "Retail", "Supermarket", "Segar"],
	"industrial": ["Industrial", "Industries", "Steel", "Beton", "Cable", "Works", "Technic", "Teknik"],
	"energy": ["Energy", "Energi", "Gas", "Power", "Mineral", "Resources", "Tambang", "Mines"],
	"tech": ["Digital", "Data", "Technology", "Technologies", "Teknologi", "Systems", "Networks", "Informatika"],
	"infra": ["Infrastructure", "Infrastruktur", "Konstruksi", "Towerindo", "Terminal", "Maintenance", "Works", "Services"],
	"transport": ["Transport", "Transportasi", "Shipping", "Marine", "Maritim", "Pelayaran", "Logistics", "Tanker"],
	"health": ["Healthcare", "Medical", "Farma", "Laboratorium", "Laboratoria", "Hospital", "Clinic", "Ingredient"],
	"finance": ["Bank", "Finance", "Financial", "Capital", "Kapital", "Investama", "Investindo", "Insurance"],
	"basicindustry": ["Chemical", "Paper", "Pulp", "Timber", "Starch", "Steel", "Metals", "Kimia"],
	"property": ["Property", "Properti", "Land", "Estate", "Realty", "Regency", "Developments", "Hotels"],
	"noncyclical": ["Food", "Dairy", "Plantation", "Plantations", "Sawit", "Store", "Segar", "Garam"]
}
const SECTOR_NARRATIVE_HINTS := {
	"consumer": ["domestic_demand", "quiet_execution", "retail_favorite"],
	"industrial": ["capex_cycle", "policy_beta", "institution_quality"],
	"energy": ["commodity_beta", "foreign_watchlist", "policy_beta"],
	"tech": ["narrative_hot", "retail_favorite", "stealth_interest"],
	"infra": ["capex_cycle", "policy_beta", "institution_quality"],
	"transport": ["foreign_watchlist", "commodity_beta", "retail_favorite"],
	"health": ["institution_quality", "supportive_balance_sheet", "quiet_execution"],
	"finance": ["institution_quality", "supportive_balance_sheet", "foreign_watchlist"],
	"basicindustry": ["commodity_beta", "capex_cycle", "policy_beta"],
	"property": ["policy_beta", "stealth_interest", "retail_favorite"],
	"noncyclical": ["domestic_demand", "quiet_execution", "supportive_balance_sheet"]
}
const DEFAULT_SECTOR_BIAS := {
	"quality": 0.0,
	"growth": 0.0,
	"risk": 0.0,
	"margin": 0.0,
	"debt": 0.0,
	"free_float": 0.0,
	"price": 0.0,
	"scale": 0.0,
	"turnover": 0.0
}
const SECTOR_BIASES := {
	"consumer": {
		"quality": 2.0,
		"growth": 2.0,
		"risk": -3.0,
		"margin": 1.0,
		"debt": -0.15,
		"free_float": 2.0,
		"price": 0.00,
		"scale": -0.05,
		"turnover": 0.0002
	},
	"industrial": {
		"quality": 0.0,
		"growth": -1.0,
		"risk": 4.0,
		"margin": -0.5,
		"debt": 0.15,
		"free_float": 1.0,
		"price": 0.03,
		"scale": 0.08,
		"turnover": 0.0001
	},
	"energy": {
		"quality": -1.0,
		"growth": 4.0,
		"risk": 7.0,
		"margin": 1.2,
		"debt": 0.18,
		"free_float": 4.0,
		"price": 0.05,
		"scale": 0.12,
		"turnover": 0.0004
	},
	"tech": {
		"quality": 1.0,
		"growth": 12.0,
		"risk": 10.0,
		"margin": 2.5,
		"debt": -0.20,
		"free_float": -2.0,
		"price": -0.03,
		"scale": -0.12,
		"turnover": 0.0003
	},
	"infra": {
		"quality": 3.0,
		"growth": 1.0,
		"risk": 3.0,
		"margin": -1.0,
		"debt": 0.30,
		"free_float": 3.0,
		"price": 0.02,
		"scale": 0.20,
		"turnover": 0.0002
	},
	"transport": {
		"quality": -2.0,
		"growth": 1.0,
		"risk": 8.0,
		"margin": -1.8,
		"debt": 0.20,
		"free_float": 2.0,
		"price": -0.02,
		"scale": 0.00,
		"turnover": 0.0001
	},
	"health": {
		"quality": 6.0,
		"growth": 7.0,
		"risk": -1.0,
		"margin": 3.0,
		"debt": -0.25,
		"free_float": -1.0,
		"price": 0.06,
		"scale": -0.10,
		"turnover": 0.0000
	},
	"finance": {
		"quality": 6.0,
		"growth": 2.0,
		"risk": 1.0,
		"margin": 2.0,
		"debt": 0.10,
		"free_float": 8.0,
		"price": 0.08,
		"scale": 0.30,
		"turnover": 0.0006
	},
	"basicindustry": {
		"quality": -2.0,
		"growth": 0.0,
		"risk": 7.0,
		"margin": -1.6,
		"debt": 0.22,
		"free_float": 1.0,
		"price": 0.00,
		"scale": 0.10,
		"turnover": 0.0000
	},
	"property": {
		"quality": 0.0,
		"growth": -2.0,
		"risk": 6.0,
		"margin": 0.8,
		"debt": 0.35,
		"free_float": 1.0,
		"price": 0.02,
		"scale": 0.16,
		"turnover": -0.0001
	},
	"noncyclical": {
		"quality": 4.0,
		"growth": 1.0,
		"risk": -4.0,
		"margin": 1.8,
		"debt": -0.12,
		"free_float": 2.0,
		"price": 0.03,
		"scale": 0.00,
		"turnover": 0.0002
	}
}


func generate_roster(
	archetype_templates: Array,
	sector_definitions: Array,
	company_word_data: Dictionary,
	run_seed: int,
	company_count: int
) -> Array:
	if company_count <= 0:
		return archetype_templates.duplicate(true)

	if archetype_templates.is_empty():
		return []

	var words: Array = _extract_words(company_word_data)
	var sector_rotation: Array = _build_sector_rotation(sector_definitions, company_count, run_seed)
	var used_names := {}
	var used_tickers := {}
	var generated_definitions: Array = []

	for company_index in range(company_count):
		var sector_definition: Dictionary = {}
		if not sector_rotation.is_empty():
			sector_definition = sector_rotation[company_index].duplicate(true)
		var sector_id: String = str(sector_definition.get("id", "consumer"))
		var template: Dictionary = _pick_template(archetype_templates, sector_id, run_seed, company_index)
		var name_words: Array = _build_unique_name_words(words, sector_id, used_names, run_seed, company_index)
		var ticker: String = _build_unique_ticker(name_words, sector_id, used_tickers)
		var listing_board: String = _derive_listing_board(template, sector_id, run_seed, company_index)
		generated_definitions.append({
			"id": ticker.to_lower(),
			"ticker": ticker,
			"name": _join_words(name_words),
			"sector_id": sector_id,
			"listing_board": listing_board,
			"narrative_tags": _build_narrative_tags(template, sector_id, run_seed, company_index),
			"anchors": _build_anchors(template, sector_id, run_seed, company_index)
		})

	_apply_nominal_price_profiles(generated_definitions, run_seed)
	return generated_definitions


func _extract_words(company_word_data: Dictionary) -> Array:
	var extracted_words: Array = []
	for word_value in company_word_data.get("unique_words", []):
		var word: String = str(word_value).strip_edges()
		if not word.is_empty():
			extracted_words.append(word)

	if extracted_words.is_empty():
		return FALLBACK_WORDS.duplicate()

	return extracted_words


func _build_sector_rotation(sector_definitions: Array, company_count: int, run_seed: int) -> Array:
	if sector_definitions.is_empty():
		return []

	var rng: RandomNumberGenerator = _rng_for(run_seed, "sector_rotation")
	var sector_rotation: Array = []
	while sector_rotation.size() < company_count:
		var cycle: Array = sector_definitions.duplicate(true)
		_shuffle_array(cycle, rng)
		for sector_definition_value in cycle:
			sector_rotation.append(sector_definition_value)
			if sector_rotation.size() >= company_count:
				break
	return sector_rotation


func _pick_template(archetype_templates: Array, sector_id: String, run_seed: int, company_index: int) -> Dictionary:
	var matching_templates: Array = []
	for template_value in archetype_templates:
		var template: Dictionary = template_value
		if str(template.get("sector_id", "")) == sector_id:
			matching_templates.append(template)

	var pool: Array = matching_templates if not matching_templates.is_empty() else archetype_templates
	var rng: RandomNumberGenerator = _rng_for(run_seed, "template_%s_%d" % [sector_id, company_index])
	var template_index: int = rng.randi_range(0, pool.size() - 1)
	return pool[template_index].duplicate(true)


func _build_unique_name_words(
	words: Array,
	sector_id: String,
	used_names: Dictionary,
	run_seed: int,
	company_index: int
) -> Array:
	for attempt in range(96):
		var rng: RandomNumberGenerator = _rng_for(run_seed, "name_%d_%d" % [company_index, attempt])
		var word_count: int = 2 if rng.randf() < 0.68 else 3
		var sector_keywords: Array = SECTOR_KEYWORD_HINTS.get(sector_id, [])
		var name_words: Array = []
		name_words.append(_pick_word(words, BRAND_WORD_HINTS, rng, name_words))
		name_words.append(_pick_word(words, sector_keywords, rng, name_words))
		if word_count == 3:
			name_words.append(_pick_word(words, TAIL_WORD_HINTS, rng, name_words))

		while name_words.size() < word_count:
			name_words.append(_pick_word(words, [], rng, name_words))

		var normalized_words: Array = _compact_words(name_words)
		if normalized_words.size() != word_count:
			continue

		var company_name: String = _join_words(normalized_words)
		if not used_names.has(company_name):
			used_names[company_name] = true
			return normalized_words

	var fallback_sector_word: String = sector_id.capitalize()
	if words.has(fallback_sector_word):
		return ["Global", fallback_sector_word]
	return ["Global", "Prima"]


func _pick_word(words: Array, preferred_words: Array, rng: RandomNumberGenerator, excluded_words: Array) -> String:
	var preferred_pool: Array = []
	for preferred_word_value in preferred_words:
		var preferred_word: String = str(preferred_word_value)
		if words.has(preferred_word) and not excluded_words.has(preferred_word):
			preferred_pool.append(preferred_word)

	if not preferred_pool.is_empty():
		return str(preferred_pool[rng.randi_range(0, preferred_pool.size() - 1)])

	var general_pool: Array = []
	for word_value in words:
		var word: String = str(word_value)
		if not excluded_words.has(word):
			general_pool.append(word)

	if general_pool.is_empty():
		return ""

	return str(general_pool[rng.randi_range(0, general_pool.size() - 1)])


func _compact_words(name_words: Array) -> Array:
	var compacted_words: Array = []
	for word_value in name_words:
		var word: String = str(word_value).strip_edges()
		if word.is_empty() or compacted_words.has(word):
			continue
		compacted_words.append(word)
	return compacted_words


func _build_unique_ticker(name_words: Array, sector_id: String, used_tickers: Dictionary) -> String:
	var normalized_words: Array = []
	for word_value in name_words:
		var normalized_word: String = _letters_only(str(word_value)).to_upper()
		if not normalized_word.is_empty():
			normalized_words.append(normalized_word)

	var ticker_candidates: Array = _ticker_candidates(normalized_words, sector_id)
	for candidate_value in ticker_candidates:
		var candidate: String = _normalize_ticker(str(candidate_value))
		if candidate.length() == 4 and not used_tickers.has(candidate):
			used_tickers[candidate] = true
			return candidate

	var compact_name: String = _letters_only(_join_words(normalized_words)).to_upper()
	var base: String = _pad_to_length(compact_name.substr(0, min(3, compact_name.length())), compact_name + "COMPANY", 3)
	for letter_index in range(ALPHABET.length()):
		var candidate: String = base + ALPHABET.substr(letter_index, 1)
		if not used_tickers.has(candidate):
			used_tickers[candidate] = true
			return candidate

	for first_index in range(ALPHABET.length()):
		for second_index in range(ALPHABET.length()):
			var candidate: String = compact_name.substr(0, min(2, compact_name.length()))
			candidate = _pad_to_length(candidate, compact_name + "SECTOR", 2)
			candidate += ALPHABET.substr(first_index, 1)
			candidate += ALPHABET.substr(second_index, 1)
			if not used_tickers.has(candidate):
				used_tickers[candidate] = true
				return candidate

	used_tickers["CMPX"] = true
	return "CMPX"


func _ticker_candidates(normalized_words: Array, sector_id: String) -> Array:
	var candidates: Array = []
	if normalized_words.is_empty():
		return candidates

	var first_word: String = normalized_words[0]
	var second_word: String = normalized_words[1] if normalized_words.size() > 1 else first_word
	var third_word: String = normalized_words[2] if normalized_words.size() > 2 else second_word
	var initials: String = ""
	for word_value in normalized_words:
		var word: String = str(word_value)
		if not word.is_empty():
			initials += word.substr(0, 1)

	_add_candidate(candidates, first_word.substr(0, 2) + second_word.substr(0, 2))
	_add_candidate(candidates, first_word.substr(0, 3) + second_word.substr(0, 1))
	_add_candidate(candidates, first_word.substr(0, 1) + second_word.substr(0, 3))
	_add_candidate(candidates, first_word.substr(0, 2) + third_word.substr(0, 2))
	_add_candidate(candidates, first_word.substr(0, 1) + second_word.substr(0, 1) + third_word.substr(0, 2))
	_add_candidate(candidates, first_word.substr(0, 2) + second_word.substr(0, 1) + third_word.substr(0, 1))
	_add_candidate(candidates, initials.substr(0, 4))
	_add_candidate(candidates, (first_word + second_word + third_word).substr(0, 4))
	_add_candidate(candidates, (first_word.substr(0, 2) + _letters_only(sector_id).to_upper()).substr(0, 4))

	return candidates


func _add_candidate(candidates: Array, candidate: String) -> void:
	var normalized_candidate: String = _normalize_ticker(candidate)
	if normalized_candidate.length() == 4 and not candidates.has(normalized_candidate):
		candidates.append(normalized_candidate)


func _normalize_ticker(candidate: String) -> String:
	var normalized: String = _letters_only(candidate).to_upper()
	if normalized.length() < 4:
		normalized = _pad_to_length(normalized, normalized + "TICKER", 4)
	return normalized.substr(0, min(4, normalized.length()))


func _build_narrative_tags(template: Dictionary, sector_id: String, run_seed: int, company_index: int) -> Array:
	var rng: RandomNumberGenerator = _rng_for(run_seed, "tags_%s_%d" % [sector_id, company_index])
	var narrative_tags: Array = []
	var template_tags: Array = template.get("narrative_tags", [])
	var sector_tags: Array = SECTOR_NARRATIVE_HINTS.get(sector_id, NARRATIVE_TAG_POOL)

	if not template_tags.is_empty():
		_add_unique_tag(narrative_tags, str(template_tags[rng.randi_range(0, template_tags.size() - 1)]))
		if template_tags.size() > 1 and rng.randf() < 0.35:
			_add_unique_tag(narrative_tags, str(template_tags[rng.randi_range(0, template_tags.size() - 1)]))

	if not sector_tags.is_empty():
		_add_unique_tag(narrative_tags, str(sector_tags[rng.randi_range(0, sector_tags.size() - 1)]))
		if rng.randf() < 0.45:
			_add_unique_tag(narrative_tags, str(sector_tags[rng.randi_range(0, sector_tags.size() - 1)]))

	if rng.randf() < 0.20:
		_add_unique_tag(narrative_tags, str(NARRATIVE_TAG_POOL[rng.randi_range(0, NARRATIVE_TAG_POOL.size() - 1)]))

	if narrative_tags.is_empty():
		narrative_tags.append("quiet_execution")

	if narrative_tags.size() > 3:
		return narrative_tags.slice(0, 3)

	return narrative_tags


func _add_unique_tag(narrative_tags: Array, tag: String) -> void:
	if tag.is_empty() or narrative_tags.has(tag):
		return
	narrative_tags.append(tag)


func _build_anchors(template: Dictionary, sector_id: String, run_seed: int, company_index: int) -> Dictionary:
	var template_anchors: Dictionary = template.get("anchors", {})
	var sector_bias: Dictionary = SECTOR_BIASES.get(sector_id, DEFAULT_SECTOR_BIAS)
	var rng: RandomNumberGenerator = _rng_for(run_seed, "anchors_%s_%d" % [sector_id, company_index])

	var quality: float = clamp(
		float(template_anchors.get("quality", 58.0)) +
		float(sector_bias.get("quality", 0.0)) +
		rng.randf_range(-9.0, 9.0),
		35.0,
		88.0
	)
	var growth: float = clamp(
		float(template_anchors.get("growth", 58.0)) +
		float(sector_bias.get("growth", 0.0)) +
		rng.randf_range(-10.0, 10.0),
		35.0,
		92.0
	)
	var risk: float = clamp(
		float(template_anchors.get("risk", 42.0)) +
		float(sector_bias.get("risk", 0.0)) +
		rng.randf_range(-9.0, 9.0),
		20.0,
		86.0
	)
	var market_cap_multiplier: float = clamp(
		1.0 + float(sector_bias.get("scale", 0.0)) + rng.randf_range(-0.22, 0.28),
		0.45,
		1.95
	)
	var market_cap: float = max(
		float(template_anchors.get("market_cap", 1000000000000.0)) * market_cap_multiplier,
		250000000000.0
	)
	var free_float_pct: float = clamp(
		float(template_anchors.get("free_float_pct", 28.0)) +
		float(sector_bias.get("free_float", 0.0)) +
		rng.randf_range(-6.0, 6.0),
		7.0,
		60.0
	)
	var net_profit_margin: float = clamp(
		float(template_anchors.get("net_profit_margin", 7.5)) +
		float(sector_bias.get("margin", 0.0)) +
		rng.randf_range(-2.2, 2.2),
		1.5,
		18.5
	)
	var debt_to_equity: float = clamp(
		float(template_anchors.get("debt_to_equity", 0.75)) +
		float(sector_bias.get("debt", 0.0)) +
		rng.randf_range(-0.25, 0.25),
		0.05,
		1.70
	)
	var market_cap_trillions: float = market_cap / 1000000000000.0
	var size_score: float = clamp((market_cap_trillions - 1.4) / 4.4, 0.0, 1.0)
	var float_score: float = clamp((free_float_pct - 24.0) / 26.0, 0.0, 1.0)
	var financial_score: float = clamp(
		(((quality - 50.0) / 38.0) * 0.40) +
		(((net_profit_margin - 5.0) / 10.0) * 0.34) +
		((1.0 - (debt_to_equity / 1.70)) * 0.26),
		0.0,
		1.0
	)
	var premium_score: float = clamp(
		(size_score * 0.46) +
		(financial_score * 0.34) +
		(float_score * 0.20),
		0.0,
		1.0
	)
	var base_price: float = float(template_anchors.get("base_price", 120.0))
	base_price *= (1.0 + float(sector_bias.get("price", 0.0))) * rng.randf_range(0.80, 1.26)
	base_price *= lerp(1.0, 6.6, premium_score)
	base_price = max(
		base_price,
		lerp(70.0, 1400.0, premium_score * clamp((financial_score + float_score) * 0.55, 0.18, 1.0))
	)
	base_price = clamp(base_price, 50.0, 2400.0)
	var turnover_ratio: float = clamp(
		0.0010 +
		((growth / 100.0) * 0.0008) +
		((risk / 100.0) * 0.0006) +
		((free_float_pct / 100.0) * 0.0012) +
		float(sector_bias.get("turnover", 0.0)) +
		rng.randf_range(-0.0002, 0.0002),
		0.0007,
		0.0065
	)
	var avg_daily_value: float = max(market_cap * turnover_ratio, 600000000.0)

	return {
		"base_price": round(base_price),
		"quality": int(round(quality)),
		"growth": int(round(growth)),
		"risk": int(round(risk)),
		"market_cap": _round_to_step(market_cap, 10000000000.0),
		"free_float_pct": _round_to_step(free_float_pct, 0.1),
		"avg_daily_value": _round_to_step(avg_daily_value, 10000000.0),
		"net_profit_margin": _round_to_step(net_profit_margin, 0.1),
		"debt_to_equity": _round_to_step(debt_to_equity, 0.01)
	}


func _apply_nominal_price_profiles(generated_definitions: Array, run_seed: int) -> void:
	if generated_definitions.is_empty():
		return

	var band_targets: Dictionary = _nominal_price_band_targets(generated_definitions.size())
	var ranked_indices: Array = _rank_definition_indices_for_nominal_price(generated_definitions)
	var assigned_indices := {}
	var profile_slot: int = 0

	for band_name_value in ["flagship", "elite", "premium"]:
		var band_name: String = str(band_name_value)
		var band_count: int = int(band_targets.get(band_name, 0))
		if band_count <= 0:
			continue

		var assigned_band_count: int = 0
		for ranked_index_value in ranked_indices:
			var ranked_index: int = int(ranked_index_value)
			if assigned_indices.has(ranked_index):
				continue

			_apply_high_price_profile(generated_definitions[ranked_index], band_name, run_seed, profile_slot)
			assigned_indices[ranked_index] = true
			assigned_band_count += 1
			profile_slot += 1
			if assigned_band_count >= band_count:
				break

	for definition_index in range(generated_definitions.size()):
		if assigned_indices.has(definition_index):
			continue
		_apply_default_capital_structure(generated_definitions[definition_index], run_seed, definition_index)


func _nominal_price_band_targets(company_count: int) -> Dictionary:
	if company_count >= 200:
		return {
			"premium": 18,
			"elite": 7,
			"flagship": 4
		}
	if company_count >= 100:
		return {
			"premium": 10,
			"elite": 4,
			"flagship": 2
		}
	if company_count >= 50:
		return {
			"premium": 5,
			"elite": 2,
			"flagship": 1
		}
	if company_count >= 20:
		return {
			"premium": 2,
			"elite": 1,
			"flagship": 0
		}
	return {
		"premium": 1,
		"elite": 0,
		"flagship": 0
	}


func _rank_definition_indices_for_nominal_price(generated_definitions: Array) -> Array:
	var scored_indices: Array = []
	for definition_index in range(generated_definitions.size()):
		scored_indices.append({
			"index": definition_index,
			"score": _nominal_price_score(generated_definitions[definition_index])
		})

	scored_indices.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return float(left.get("score", 0.0)) > float(right.get("score", 0.0))
	)

	var ranked_indices: Array = []
	for scored_entry_value in scored_indices:
		ranked_indices.append(int(scored_entry_value.get("index", 0)))
	return ranked_indices


func _nominal_price_score(definition: Dictionary) -> float:
	var anchors: Dictionary = definition.get("anchors", {})
	var narrative_tags: Array = definition.get("narrative_tags", []).duplicate()
	var market_cap: float = float(anchors.get("market_cap", 1000000000000.0))
	var quality: float = float(anchors.get("quality", 58.0))
	var margin: float = float(anchors.get("net_profit_margin", 7.5))
	var debt_to_equity: float = float(anchors.get("debt_to_equity", 0.75))
	var free_float_pct: float = float(anchors.get("free_float_pct", 28.0))
	var score: float = (
		log(max(market_cap, 1000000000.0)) * 13.0 +
		quality * 0.95 +
		margin * 4.4 +
		free_float_pct * 0.32 -
		debt_to_equity * 18.0
	)
	if "institution_quality" in narrative_tags:
		score += 14.0
	if "supportive_balance_sheet" in narrative_tags:
		score += 8.0
	if "foreign_watchlist" in narrative_tags:
		score += 6.0
	if "quiet_execution" in narrative_tags:
		score += 4.0
	if "stealth_interest" in narrative_tags:
		score += max(18.0 - free_float_pct, 0.0) * 0.80
	if "retail_favorite" in narrative_tags or "narrative_hot" in narrative_tags:
		score += max(22.0 - free_float_pct, 0.0) * 0.44
	return score


func _apply_high_price_profile(definition: Dictionary, band_name: String, run_seed: int, profile_slot: int) -> void:
	var anchors: Dictionary = definition.get("anchors", {}).duplicate(true)
	var rng: RandomNumberGenerator = _rng_for(run_seed, "nominal_profile_%s_%d" % [band_name, profile_slot])
	var style: String = _preferred_high_price_style(definition, band_name)
	var band_range: Dictionary = _band_range_for_style(band_name, style)
	var floor_value: float = rng.randf_range(
		float(band_range.get("floor_min", 5000.0)),
		float(band_range.get("floor_max", 7000.0))
	)
	var ceiling_value: float = rng.randf_range(
		max(float(band_range.get("ceiling_min", floor_value * 1.25)), floor_value * 1.15),
		max(float(band_range.get("ceiling_max", floor_value * 1.45)), floor_value * 1.25)
	)
	var target_anchor_price: float = rng.randf_range(floor_value * 0.94, ceiling_value * 0.88)
	var market_cap: float = float(anchors.get("market_cap", 1000000000000.0))
	var current_avg_daily_value: float = float(anchors.get("avg_daily_value", 1000000000.0))

	anchors["capital_structure_style"] = style
	anchors["target_price_floor"] = _round_to_step(floor_value, 5.0)
	anchors["target_price_ceiling"] = _round_to_step(ceiling_value, 5.0)
	anchors["base_price"] = round(clamp(target_anchor_price, 50.0, 45000.0))

	match style:
		"institutional_premium":
			anchors["free_float_pct"] = _round_to_step(
				clamp(max(float(anchors.get("free_float_pct", 28.0)), rng.randf_range(24.0, 46.0)), 22.0, 55.0),
				0.1
			)
			anchors["owner_concentration_pct"] = _round_to_step(rng.randf_range(38.0, 60.0), 0.1)
			anchors["avg_daily_value"] = _round_to_step(
				max(current_avg_daily_value, market_cap * rng.randf_range(0.0023, 0.0068)),
				10000000.0
			)
		"owner_controlled":
			anchors["free_float_pct"] = _round_to_step(
				clamp(min(float(anchors.get("free_float_pct", 18.0)), rng.randf_range(7.0, 16.0)), 7.0, 18.0),
				0.1
			)
			anchors["owner_concentration_pct"] = _round_to_step(rng.randf_range(72.0, 90.0), 0.1)
			anchors["avg_daily_value"] = _round_to_step(
				max(current_avg_daily_value, market_cap * rng.randf_range(0.0010, 0.0038)),
				10000000.0
			)
		_:
			anchors["owner_concentration_pct"] = _round_to_step(
				clamp(100.0 - float(anchors.get("free_float_pct", 28.0)) + rng.randf_range(-6.0, 6.0), 35.0, 78.0),
				0.1
			)

	definition["anchors"] = anchors


func _preferred_high_price_style(definition: Dictionary, band_name: String) -> String:
	var anchors: Dictionary = definition.get("anchors", {})
	var narrative_tags: Array = definition.get("narrative_tags", []).duplicate()
	var market_cap: float = float(anchors.get("market_cap", 1000000000000.0))
	var free_float_pct: float = float(anchors.get("free_float_pct", 28.0))
	var quality: float = float(anchors.get("quality", 58.0))
	var margin: float = float(anchors.get("net_profit_margin", 7.5))
	var institutional_score: float = (
		clamp((market_cap - 1800000000000.0) / 4200000000000.0, 0.0, 1.0) * 0.42 +
		clamp((free_float_pct - 24.0) / 22.0, 0.0, 1.0) * 0.24 +
		clamp((quality - 58.0) / 24.0, 0.0, 1.0) * 0.20 +
		clamp((margin - 7.0) / 7.0, 0.0, 1.0) * 0.14
	)
	var scarcity_score: float = (
		clamp((market_cap - 1100000000000.0) / 3200000000000.0, 0.0, 1.0) * 0.30 +
		clamp((18.0 - free_float_pct) / 12.0, 0.0, 1.0) * 0.30 +
		clamp((quality - 54.0) / 28.0, 0.0, 1.0) * 0.14 +
		(0.26 if (
			"stealth_interest" in narrative_tags or
			"retail_favorite" in narrative_tags or
			"narrative_hot" in narrative_tags
		) else 0.0)
	)

	if band_name == "flagship" and scarcity_score > institutional_score + 0.08:
		return "owner_controlled"
	if free_float_pct <= 16.0 and scarcity_score >= 0.48:
		return "owner_controlled"
	if quality >= 64.0 and market_cap >= 2200000000000.0:
		return "institutional_premium"
	return "institutional_premium" if institutional_score >= scarcity_score else "owner_controlled"


func _band_range_for_style(band_name: String, style: String) -> Dictionary:
	if band_name == "flagship":
		if style == "owner_controlled":
			return {
				"floor_min": 21000.0,
				"floor_max": 26000.0,
				"ceiling_min": 28000.0,
				"ceiling_max": 42000.0
			}
		return {
			"floor_min": 18000.0,
			"floor_max": 24000.0,
			"ceiling_min": 24000.0,
			"ceiling_max": 34000.0
		}
	if band_name == "elite":
		if style == "owner_controlled":
			return {
				"floor_min": 11000.0,
				"floor_max": 15000.0,
				"ceiling_min": 15000.0,
				"ceiling_max": 23000.0
			}
		return {
			"floor_min": 10000.0,
			"floor_max": 13500.0,
			"ceiling_min": 13500.0,
			"ceiling_max": 19000.0
		}
	if style == "owner_controlled":
		return {
			"floor_min": 5500.0,
			"floor_max": 8000.0,
			"ceiling_min": 8000.0,
			"ceiling_max": 12500.0
		}
	return {
		"floor_min": 5000.0,
		"floor_max": 7200.0,
		"ceiling_min": 7200.0,
		"ceiling_max": 10500.0
	}


func _apply_default_capital_structure(definition: Dictionary, run_seed: int, definition_index: int) -> void:
	var anchors: Dictionary = definition.get("anchors", {}).duplicate(true)
	var rng: RandomNumberGenerator = _rng_for(run_seed, "capital_structure_%d" % definition_index)
	var free_float_pct: float = float(anchors.get("free_float_pct", 28.0))
	var market_cap: float = float(anchors.get("market_cap", 1000000000000.0))
	var quality: float = float(anchors.get("quality", 58.0))
	var margin: float = float(anchors.get("net_profit_margin", 7.5))
	var narrative_tags: Array = definition.get("narrative_tags", []).duplicate()
	var style: String = "balanced"

	if market_cap >= 3500000000000.0 and free_float_pct >= 28.0 and quality >= 66.0 and margin >= 7.0:
		style = "institutional_premium"
	elif free_float_pct <= 15.0 and market_cap >= 900000000000.0 and (
		"stealth_interest" in narrative_tags or
		"retail_favorite" in narrative_tags or
		"narrative_hot" in narrative_tags
	):
		style = "owner_controlled"
	elif free_float_pct >= 38.0:
		style = "wide_float"

	anchors["capital_structure_style"] = style
	if not anchors.has("owner_concentration_pct"):
		match style:
			"wide_float":
				anchors["owner_concentration_pct"] = _round_to_step(
					clamp(100.0 - free_float_pct + rng.randf_range(-10.0, 4.0), 25.0, 60.0),
					0.1
				)
			"institutional_premium":
				anchors["owner_concentration_pct"] = _round_to_step(
					clamp(100.0 - free_float_pct + rng.randf_range(-6.0, 6.0), 34.0, 68.0),
					0.1
				)
			"owner_controlled":
				anchors["owner_concentration_pct"] = _round_to_step(
					clamp(rng.randf_range(70.0, 88.0), 68.0, 90.0),
					0.1
				)
			_:
				anchors["owner_concentration_pct"] = _round_to_step(
					clamp(100.0 - free_float_pct + rng.randf_range(-4.0, 8.0), 38.0, 78.0),
					0.1
				)

	definition["anchors"] = anchors


func _derive_listing_board(template: Dictionary, sector_id: String, run_seed: int, company_index: int) -> String:
	var template_anchors: Dictionary = template.get("anchors", {})
	var sector_bias: Dictionary = SECTOR_BIASES.get(sector_id, DEFAULT_SECTOR_BIAS)
	var rng: RandomNumberGenerator = _rng_for(run_seed, "board_%s_%d" % [sector_id, company_index])
	var market_cap_score: float = float(template_anchors.get("market_cap", 1000000000000.0))
	var risk_score: float = float(template_anchors.get("risk", 42.0)) + float(sector_bias.get("risk", 0.0))
	var development_probability: float = 0.10
	if market_cap_score < 1100000000000.0:
		development_probability += 0.12
	if risk_score > 58.0:
		development_probability += 0.12
	if sector_id in ["tech", "property", "transport"]:
		development_probability += 0.08
	return "development" if rng.randf() < development_probability else "main"


func _round_to_step(value: float, step: float) -> float:
	if step <= 0.0:
		return value
	return round(value / step) * step


func _letters_only(source: String) -> String:
	var compacted: String = ""
	for character_index in range(source.length()):
		var character: String = source.substr(character_index, 1)
		if character.unicode_at(0) >= 65 and character.unicode_at(0) <= 90:
			compacted += character
		elif character.unicode_at(0) >= 97 and character.unicode_at(0) <= 122:
			compacted += character
	return compacted


func _pad_to_length(source: String, filler: String, target_length: int) -> String:
	var padded: String = source
	var filler_source: String = filler if not filler.is_empty() else "XXXX"
	var filler_index: int = 0
	while padded.length() < target_length:
		padded += filler_source.substr(filler_index % filler_source.length(), 1)
		filler_index += 1
	return padded


func _join_words(words: Array) -> String:
	var parts: Array = []
	for word_value in words:
		var word: String = str(word_value).strip_edges()
		if not word.is_empty():
			parts.append(word)
	return " ".join(parts)


func _shuffle_array(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var temp = values[index]
		values[index] = values[swap_index]
		values[swap_index] = temp


func _rng_for(run_seed: int, salt: String) -> RandomNumberGenerator:
	return STABLE_RNG.rng([run_seed, "company_roster", salt])
