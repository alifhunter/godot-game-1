#!/usr/bin/env python3
"""Dev-only Company Narrative editor server.

Uses only Python stdlib. The editable source lives next to this file and exports
to the Godot runtime company narrative JSON files under data/companies.
"""

from __future__ import annotations

import argparse
import copy
import json
import mimetypes
import re
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse


TOOL_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = TOOL_DIR.parents[1]
SOURCE_PATH = TOOL_DIR / "company_narrative_source.json"
STATIC_DIR = TOOL_DIR / "static"
ARCHETYPES_PATH = PROJECT_ROOT / "data" / "companies" / "company_archetypes.json"
WORDS_PATH = PROJECT_ROOT / "data" / "companies" / "company_words.json"
PROFILE_DATA_PATH = PROJECT_ROOT / "data" / "companies" / "company_profile_data.json"
SECTORS_PATH = PROJECT_ROOT / "data" / "sectors" / "sectors.json"

ANCHOR_FIELDS = [
    "base_price",
    "quality",
    "growth",
    "risk",
    "market_cap",
    "free_float_pct",
    "avg_daily_value",
    "net_profit_margin",
    "debt_to_equity",
]
PROFILE_POOL_FIELDS = ["descriptor_pool", "verb_pool", "differentiator_pool", "tag_pool"]
SECTOR_POOL_FIELDS = ["business_pool", "scope_pool", "differentiator_pool", "tag_pool"]
SIZE_POOL_FIELDS = ["descriptor_pool", "tag_pool"]
PROFILE_TOKENS = {
    "COMPANY",
    "SECTOR",
    "ARCHETYPE",
    "SIZE_DESCRIPTOR",
    "ARCHETYPE_DESCRIPTOR",
    "ARCHETYPE_VERB",
    "SECTOR_BUSINESS",
    "AGE",
    "FOUNDED",
    "EMPLOYEES",
    "REVENUE",
    "REVENUE_UNIT",
}
KNOWN_NARRATIVE_TAGS = [
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
    "capex_cycle",
]


def read_json(path: Path):
    raw = path.read_text(encoding="utf-8-sig")
    return json.loads(raw)


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(payload, ensure_ascii=False, indent=2)
    path.write_text(encoded + "\n", encoding="utf-8")


def import_runtime_source() -> dict:
    return {
        "schema_version": 1,
        "archetype_templates": normalize_archetype_templates(read_json(ARCHETYPES_PATH)),
        "word_data": normalize_word_data(read_json(WORDS_PATH)),
        "profile_data": normalize_profile_data(read_json(PROFILE_DATA_PATH)),
        "notes": "Imported from data/companies company narrative runtime files.",
    }


def load_source() -> dict:
    if not SOURCE_PATH.exists():
        return import_runtime_source()
    try:
        source = read_json(SOURCE_PATH)
    except (json.JSONDecodeError, OSError):
        return import_runtime_source()
    if not isinstance(source, dict):
        return import_runtime_source()
    source = copy.deepcopy(source)
    source["schema_version"] = int(source.get("schema_version", 1) or 1)
    source["archetype_templates"] = normalize_archetype_templates(source.get("archetype_templates", []))
    source["word_data"] = normalize_word_data(source.get("word_data", {}))
    source["profile_data"] = normalize_profile_data(source.get("profile_data", {}))
    source["notes"] = str(source.get("notes", ""))
    if not source["archetype_templates"] and not source["profile_data"].get("archetypes", {}):
        return import_runtime_source()
    return source


def normalize_archetype_templates(value) -> list[dict]:
    if not isinstance(value, list):
        return []
    templates: list[dict] = []
    for row in value:
        if not isinstance(row, dict):
            continue
        template = copy.deepcopy(row)
        template["id"] = slug_id(template.get("id", ""))
        template["ticker"] = normalize_ticker(template.get("ticker", template["id"]))
        template["name"] = str(template.get("name", "")).strip()
        template["sector_id"] = str(template.get("sector_id", "")).strip()
        template["narrative_tags"] = normalize_string_array(template.get("narrative_tags", []))
        anchors = template.get("anchors", {})
        if not isinstance(anchors, dict):
            anchors = {}
        template["anchors"] = {field: normalize_float(anchors.get(field, 0.0), 0.0) for field in ANCHOR_FIELDS}
        templates.append(template)
    return templates


def normalize_word_data(value) -> dict:
    if not isinstance(value, dict):
        value = {}
    words = normalize_word_list(value.get("unique_words", []))
    return {
        "unique_words": words,
        "total_count": len(words),
    }


def normalize_profile_data(value) -> dict:
    if not isinstance(value, dict):
        value = {}
    profile = copy.deepcopy(value)
    meta = profile.get("_meta", {})
    if not isinstance(meta, dict):
        meta = {}
    profile["_meta"] = {
        "version": str(meta.get("version", "1.0.0")).strip() or "1.0.0",
        "description": str(meta.get("description", "")).strip(),
    }
    profile["reference_year"] = normalize_int(profile.get("reference_year", 2020), 2020)
    settings = profile.get("sentence_settings", {})
    if not isinstance(settings, dict):
        settings = {}
    profile["sentence_settings"] = {
        "optional_third_sentence_probability": normalize_float(settings.get("optional_third_sentence_probability", 0.55), 0.55)
    }
    sentence_templates = profile.get("sentence_templates", {})
    if not isinstance(sentence_templates, dict):
        sentence_templates = {}
    profile["sentence_templates"] = {
        "primary_pool": normalize_string_array(sentence_templates.get("primary_pool", []))
    }
    profile["archetype_weights_by_sector"] = normalize_weight_map(profile.get("archetype_weights_by_sector", {}))
    profile["archetypes"] = normalize_profile_archetypes(profile.get("archetypes", {}))
    profile["sizes"] = normalize_sizes(profile.get("sizes", {}))
    profile["sectors"] = normalize_sector_profiles(profile.get("sectors", {}))
    profile["narrative_tag_sentences"] = normalize_pool_map(profile.get("narrative_tag_sentences", {}))
    profile["global_differentiator_pool"] = normalize_string_array(profile.get("global_differentiator_pool", []))
    return profile


def normalize_profile_archetypes(value) -> dict:
    if not isinstance(value, dict):
        return {}
    rows: dict = {}
    for key, row in value.items():
        archetype_id = slug_id(key)
        if not archetype_id or not isinstance(row, dict):
            continue
        item = copy.deepcopy(row)
        item["label"] = str(item.get("label", archetype_id.replace("_", " ").title())).strip()
        item["tone"] = str(item.get("tone", "")).strip()
        item["age_range"] = normalize_number_pair(item.get("age_range", [1, 20]), int)
        item["allowed_sizes"] = [normalize_int(size, 0) for size in normalize_string_array_or_list(item.get("allowed_sizes", []))]
        size_weights = item.get("size_weights", {})
        if not isinstance(size_weights, dict):
            size_weights = {}
        item["size_weights"] = {str(normalize_int(size_id, 0)): normalize_float(weight, 0.0) for size_id, weight in size_weights.items()}
        for field in PROFILE_POOL_FIELDS:
            item[field] = normalize_string_array(item.get(field, []))
        rows[archetype_id] = item
    return rows


def normalize_sizes(value) -> dict:
    if not isinstance(value, dict):
        return {}
    rows: dict = {}
    for key, row in value.items():
        size_id = str(normalize_int(key, 0))
        if not isinstance(row, dict):
            continue
        item = copy.deepcopy(row)
        item["label"] = str(item.get("label", size_id)).strip()
        item["employee_range"] = normalize_number_pair(item.get("employee_range", [1, 100]), int)
        item["revenue_hint_range"] = normalize_number_pair(item.get("revenue_hint_range", [0, 1]), float)
        for field in SIZE_POOL_FIELDS:
            item[field] = normalize_string_array(item.get(field, []))
        rows[size_id] = item
    return rows


def normalize_sector_profiles(value) -> dict:
    if not isinstance(value, dict):
        return {}
    rows: dict = {}
    for key, row in value.items():
        sector_id = str(key).strip()
        if not sector_id or not isinstance(row, dict):
            continue
        item = copy.deepcopy(row)
        for field in SECTOR_POOL_FIELDS:
            item[field] = normalize_string_array(item.get(field, []))
        rows[sector_id] = item
    return rows


def normalize_weight_map(value) -> dict:
    if not isinstance(value, dict):
        return {}
    rows: dict = {}
    for sector_id, weights in value.items():
        if not isinstance(weights, dict):
            continue
        clean_sector_id = str(sector_id).strip()
        if not clean_sector_id:
            continue
        rows[clean_sector_id] = {slug_id(archetype_id): normalize_float(weight, 0.0) for archetype_id, weight in weights.items() if slug_id(archetype_id)}
    return rows


def normalize_pool_map(value) -> dict:
    if not isinstance(value, dict):
        return {}
    return {slug_id(key): normalize_string_array(row) for key, row in value.items() if slug_id(key)}


def normalize_number_pair(value, caster) -> list:
    rows = normalize_string_array_or_list(value)
    if len(rows) == 1:
        rows = [rows[0], rows[0]]
    elif len(rows) < 2:
        rows = [0, 0]
    left = cast_number(rows[0], caster)
    right = cast_number(rows[1], caster)
    return [left, right]


def cast_number(value, caster):
    try:
        if caster is int:
            return int(float(value))
        return caster(value)
    except (TypeError, ValueError):
        return caster(0)


def normalize_string_array_or_list(value) -> list:
    if isinstance(value, list):
        return value
    if isinstance(value, str):
        return [line.strip() for line in value.splitlines() if line.strip()]
    return []


def normalize_string_array(value) -> list[str]:
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        return [line.strip() for line in value.splitlines() if line.strip()]
    return []


def normalize_word_list(value) -> list[str]:
    words = normalize_string_array(value)
    seen: set[str] = set()
    unique_words: list[str] = []
    for word in words:
        clean = re.sub(r"\s+", " ", word).strip()
        if not clean or clean in seen:
            continue
        seen.add(clean)
        unique_words.append(clean)
    return unique_words


def normalize_int(value, fallback: int = 0) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return fallback


def normalize_float(value, fallback: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return fallback


def slug_id(value) -> str:
    return re.sub(r"[^a-z0-9_]+", "_", str(value).strip().lower()).strip("_")


def normalize_ticker(value) -> str:
    return re.sub(r"[^A-Za-z]", "", str(value)).upper()[:4]


def export_runtime_payloads(source: dict) -> dict:
    normalized = {
        "archetype_templates": normalize_archetype_templates(source.get("archetype_templates", [])),
        "word_data": normalize_word_data(source.get("word_data", {})),
        "profile_data": normalize_profile_data(source.get("profile_data", {})),
    }
    return normalized


def load_sector_ids() -> set[str]:
    try:
        sectors = read_json(SECTORS_PATH)
    except (json.JSONDecodeError, OSError):
        return set()
    if not isinstance(sectors, list):
        return set()
    return {str(row.get("id", "")).strip() for row in sectors if isinstance(row, dict) and str(row.get("id", "")).strip()}


def validate_source(source: dict) -> dict:
    errors: list[str] = []
    warnings: list[str] = []
    if not isinstance(source, dict):
        return {"valid": False, "errors": ["Source must be an object."], "warnings": []}
    sector_ids = load_sector_ids()
    archetype_templates = normalize_archetype_templates(source.get("archetype_templates", []))
    word_data = normalize_word_data(source.get("word_data", {}))
    profile_data = normalize_profile_data(source.get("profile_data", {}))
    validate_archetype_templates(archetype_templates, profile_data, sector_ids, errors, warnings)
    validate_word_data(word_data, errors, warnings)
    validate_profile_data(profile_data, archetype_templates, sector_ids, errors, warnings)
    return {"valid": len(errors) == 0, "errors": errors, "warnings": warnings}


def validate_archetype_templates(
    templates: list[dict],
    profile_data: dict,
    sector_ids: set[str],
    errors: list[str],
    warnings: list[str],
) -> None:
    if not templates:
        errors.append("archetype_templates must contain at least one seeded company template.")
        return
    seen_ids: set[str] = set()
    seen_tickers: set[str] = set()
    known_tags = set(profile_data.get("narrative_tag_sentences", {}).keys()) | set(KNOWN_NARRATIVE_TAGS)
    for index, template in enumerate(templates):
        template_id = str(template.get("id", "")).strip()
        label = template_id or f"archetype_templates[{index}]"
        if not template_id:
            errors.append(f"{label}: id is required.")
        elif template_id in seen_ids:
            errors.append(f"{label}: id must be unique.")
        seen_ids.add(template_id)
        ticker = str(template.get("ticker", "")).strip()
        if not re.fullmatch(r"[A-Z]{4}", ticker):
            errors.append(f"{label}: ticker must be exactly four uppercase letters.")
        elif ticker in seen_tickers:
            errors.append(f"{label}: ticker must be unique.")
        seen_tickers.add(ticker)
        if not str(template.get("name", "")).strip():
            errors.append(f"{label}: name is required.")
        sector_id = str(template.get("sector_id", "")).strip()
        if sector_ids and sector_id not in sector_ids:
            errors.append(f"{label}: unknown sector_id '{sector_id}'.")
        if not template.get("narrative_tags", []):
            warnings.append(f"{label}: narrative_tags is empty; generated companies from this template may feel generic.")
        for tag in template.get("narrative_tags", []):
            if tag not in known_tags:
                warnings.append(f"{label}: narrative tag '{tag}' has no sentence pool.")
        anchors = template.get("anchors", {})
        if not isinstance(anchors, dict):
            errors.append(f"{label}: anchors must be an object.")
            continue
        for field in ANCHOR_FIELDS:
            if field not in anchors:
                errors.append(f"{label}: anchors.{field} is required.")
        validate_anchor_ranges(anchors, label, errors)


def validate_anchor_ranges(anchors: dict, label: str, errors: list[str]) -> None:
    for field in ["base_price", "market_cap", "avg_daily_value"]:
        if float(anchors.get(field, 0.0)) <= 0:
            errors.append(f"{label}: anchors.{field} must be positive.")
    for field in ["quality", "growth", "risk"]:
        value = float(anchors.get(field, 0.0))
        if value < 0 or value > 100:
            errors.append(f"{label}: anchors.{field} must be between 0 and 100.")
    free_float = float(anchors.get("free_float_pct", 0.0))
    if free_float < 0 or free_float > 100:
        errors.append(f"{label}: anchors.free_float_pct must be between 0 and 100.")
    if float(anchors.get("debt_to_equity", 0.0)) < 0:
        errors.append(f"{label}: anchors.debt_to_equity must be non-negative.")


def validate_word_data(word_data: dict, errors: list[str], warnings: list[str]) -> None:
    words = word_data.get("unique_words", [])
    if not isinstance(words, list) or not words:
        errors.append("word_data.unique_words must be a non-empty array.")
        return
    if len(words) < 80:
        warnings.append("word_data.unique_words has fewer than 80 entries; generated company names may repeat.")
    if len(words) != len(set(words)):
        errors.append("word_data.unique_words contains duplicate entries after normalization.")
    for index, word in enumerate(words):
        if not re.search(r"[A-Za-z]", str(word)):
            errors.append(f"word_data.unique_words[{index}] must contain at least one letter.")
    if int(word_data.get("total_count", 0)) != len(words):
        warnings.append("word_data.total_count differs from unique_words length; export will rewrite it.")


def validate_profile_data(
    profile_data: dict,
    archetype_templates: list[dict],
    sector_ids: set[str],
    errors: list[str],
    warnings: list[str],
) -> None:
    reference_year = int(profile_data.get("reference_year", 0))
    if reference_year < 1900 or reference_year > 2100:
        errors.append("profile_data.reference_year should be between 1900 and 2100.")
    probability = float(profile_data.get("sentence_settings", {}).get("optional_third_sentence_probability", -1.0))
    if probability < 0.0 or probability > 1.0:
        errors.append("sentence_settings.optional_third_sentence_probability must be between 0 and 1.")
    primary_pool = profile_data.get("sentence_templates", {}).get("primary_pool", [])
    validate_template_pool(primary_pool, "sentence_templates.primary_pool", errors, warnings)
    archetypes = profile_data.get("archetypes", {})
    sizes = profile_data.get("sizes", {})
    sectors = profile_data.get("sectors", {})
    weights = profile_data.get("archetype_weights_by_sector", {})
    narrative_tags = profile_data.get("narrative_tag_sentences", {})
    if not archetypes:
        errors.append("profile_data.archetypes must contain at least one archetype.")
    if not sizes:
        errors.append("profile_data.sizes must contain at least one size bucket.")
    validate_profile_archetypes(archetypes, sizes, errors, warnings)
    validate_sizes(sizes, errors, warnings)
    validate_sector_profiles(sectors, sector_ids, errors, warnings)
    validate_weights(weights, archetypes, sectors, errors, warnings)
    validate_narrative_tag_sentences(narrative_tags, archetype_templates, errors, warnings)
    validate_template_pool(profile_data.get("global_differentiator_pool", []), "global_differentiator_pool", errors, warnings, min_count=1)


def validate_profile_archetypes(archetypes: dict, sizes: dict, errors: list[str], warnings: list[str]) -> None:
    size_ids = set(str(key) for key in sizes.keys())
    for archetype_id, archetype in archetypes.items():
        label = f"archetypes.{archetype_id}"
        if not str(archetype.get("label", "")).strip():
            errors.append(f"{label}.label is required.")
        validate_pair(archetype.get("age_range", []), f"{label}.age_range", errors, minimum_allowed=0)
        allowed_sizes = [str(int(size_id)) for size_id in archetype.get("allowed_sizes", [])]
        if not allowed_sizes:
            errors.append(f"{label}.allowed_sizes must contain at least one size id.")
        for size_id in allowed_sizes:
            if size_id not in size_ids:
                errors.append(f"{label}.allowed_sizes references unknown size '{size_id}'.")
            if size_id not in archetype.get("size_weights", {}):
                errors.append(f"{label}.size_weights is missing allowed size '{size_id}'.")
        for size_id, weight in archetype.get("size_weights", {}).items():
            if str(size_id) not in size_ids:
                warnings.append(f"{label}.size_weights references unused/unknown size '{size_id}'.")
            if float(weight) <= 0:
                errors.append(f"{label}.size_weights.{size_id} must be positive.")
        for field in PROFILE_POOL_FIELDS:
            validate_template_pool(archetype.get(field, []), f"{label}.{field}", errors, warnings, min_count=1)


def validate_sizes(sizes: dict, errors: list[str], warnings: list[str]) -> None:
    for size_id, size in sizes.items():
        label = f"sizes.{size_id}"
        if not str(size.get("label", "")).strip():
            errors.append(f"{label}.label is required.")
        validate_pair(size.get("employee_range", []), f"{label}.employee_range", errors, minimum_allowed=1)
        validate_pair(size.get("revenue_hint_range", []), f"{label}.revenue_hint_range", errors, minimum_allowed=0)
        for field in SIZE_POOL_FIELDS:
            validate_template_pool(size.get(field, []), f"{label}.{field}", errors, warnings, min_count=1)


def validate_sector_profiles(sectors: dict, sector_ids: set[str], errors: list[str], warnings: list[str]) -> None:
    if sector_ids:
        for sector_id in sector_ids:
            if sector_id not in sectors:
                errors.append(f"sectors.{sector_id} is required for generated company profiles.")
    for sector_id, sector in sectors.items():
        label = f"sectors.{sector_id}"
        if sector_ids and sector_id not in sector_ids:
            warnings.append(f"{label} is not present in data/sectors/sectors.json.")
        for field in SECTOR_POOL_FIELDS:
            validate_template_pool(sector.get(field, []), f"{label}.{field}", errors, warnings, min_count=1)


def validate_weights(weights: dict, archetypes: dict, sectors: dict, errors: list[str], warnings: list[str]) -> None:
    archetype_ids = set(archetypes.keys())
    for sector_id in sectors.keys():
        sector_weights = weights.get(sector_id, {})
        if not isinstance(sector_weights, dict) or not sector_weights:
            errors.append(f"archetype_weights_by_sector.{sector_id} must be a non-empty object.")
            continue
        for archetype_id in archetype_ids:
            if archetype_id not in sector_weights:
                errors.append(f"archetype_weights_by_sector.{sector_id}.{archetype_id} is required.")
        for archetype_id, weight in sector_weights.items():
            if archetype_id not in archetype_ids:
                warnings.append(f"archetype_weights_by_sector.{sector_id}.{archetype_id} references unknown archetype.")
            if float(weight) <= 0:
                errors.append(f"archetype_weights_by_sector.{sector_id}.{archetype_id} must be positive.")


def validate_narrative_tag_sentences(
    narrative_tags: dict,
    archetype_templates: list[dict],
    errors: list[str],
    warnings: list[str],
) -> None:
    used_tags = set(KNOWN_NARRATIVE_TAGS)
    for template in archetype_templates:
        used_tags.update(template.get("narrative_tags", []))
    for tag in sorted(used_tags):
        if tag not in narrative_tags:
            errors.append(f"narrative_tag_sentences.{tag} is required because generation can use it.")
    for tag, pool in narrative_tags.items():
        validate_template_pool(pool, f"narrative_tag_sentences.{tag}", errors, warnings, min_count=1)


def validate_pair(value, label: str, errors: list[str], minimum_allowed: float = 0.0) -> None:
    if not isinstance(value, list) or len(value) < 2:
        errors.append(f"{label} must contain [min, max].")
        return
    left = float(value[0])
    right = float(value[1])
    if left < minimum_allowed or right < minimum_allowed:
        errors.append(f"{label} values must be >= {minimum_allowed}.")
    if left > right:
        errors.append(f"{label} min must be <= max.")


def validate_template_pool(
    pool,
    label: str,
    errors: list[str],
    warnings: list[str],
    min_count: int = 1,
) -> None:
    if not isinstance(pool, list):
        errors.append(f"{label} must be an array.")
        return
    clean_pool = [str(row).strip() for row in pool if str(row).strip()]
    if len(clean_pool) < min_count:
        errors.append(f"{label} needs at least {min_count} non-empty line(s).")
        return
    if len(clean_pool) == 1:
        warnings.append(f"{label} has only one line; add variants when possible.")
    validate_tokens(clean_pool, label, warnings)


def validate_tokens(lines: list[str], label: str, warnings: list[str]) -> None:
    for line_index, line in enumerate(lines):
        for token in re.findall(r"\{([A-Z0-9_]+)\}", line):
            if token not in PROFILE_TOKENS:
                warnings.append(f"{label}[{line_index}] uses unknown template token {{{token}}}.")


class CompanyNarrativeEditorHandler(BaseHTTPRequestHandler):
    server_version = "CompanyNarrativeEditor/1.0"

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/api/source":
            self.send_json(load_source())
            return
        if parsed.path == "/api/validate":
            self.send_json(validate_source(load_source()))
            return
        if parsed.path == "/" or parsed.path == "/index.html":
            self.serve_file(STATIC_DIR / "index.html")
            return
        if parsed.path.startswith("/static/"):
            relative = unquote(parsed.path.removeprefix("/static/"))
            self.serve_file((STATIC_DIR / relative).resolve())
            return
        self.send_error(404, "Not found")

    def do_POST(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/api/source":
            payload = self.read_json_body()
            source = self.normalize_posted_source(payload)
            write_json(SOURCE_PATH, source)
            self.send_json({"saved": True, "validation": validate_source(source)})
            return
        if parsed.path == "/api/validate":
            payload = self.read_json_body(required=False)
            source = self.normalize_posted_source(payload) if payload else load_source()
            self.send_json(validate_source(source))
            return
        if parsed.path == "/api/export":
            payload = self.read_json_body(required=False)
            source = self.normalize_posted_source(payload) if payload else load_source()
            validation = validate_source(source)
            if not validation["valid"]:
                self.send_json({"exported": False, "validation": validation}, status=400)
                return
            payloads = export_runtime_payloads(source)
            write_json(SOURCE_PATH, source)
            write_json(ARCHETYPES_PATH, payloads["archetype_templates"])
            write_json(WORDS_PATH, payloads["word_data"])
            write_json(PROFILE_DATA_PATH, payloads["profile_data"])
            self.send_json({
                "exported": True,
                "paths": [str(ARCHETYPES_PATH), str(WORDS_PATH), str(PROFILE_DATA_PATH)],
                "validation": validation,
            })
            return
        self.send_error(404, "Not found")

    def read_json_body(self, required: bool = True):
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0:
            if required:
                self.send_error(400, "Missing JSON body")
            return None
        raw = self.rfile.read(length).decode("utf-8")
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            self.send_error(400, "Invalid JSON")
            return None

    def normalize_posted_source(self, payload) -> dict:
        if isinstance(payload, dict):
            source = copy.deepcopy(payload)
        else:
            source = load_source()
        source["schema_version"] = int(source.get("schema_version", 1) or 1)
        source["archetype_templates"] = normalize_archetype_templates(source.get("archetype_templates", []))
        source["word_data"] = normalize_word_data(source.get("word_data", {}))
        source["profile_data"] = normalize_profile_data(source.get("profile_data", {}))
        source["notes"] = str(source.get("notes", ""))
        return source

    def serve_file(self, path: Path) -> None:
        try:
            resolved = path.resolve()
            static_root = STATIC_DIR.resolve()
            if resolved != static_root and static_root not in resolved.parents:
                self.send_error(403, "Forbidden")
                return
            data = resolved.read_bytes()
        except OSError:
            self.send_error(404, "Not found")
            return
        content_type = mimetypes.guess_type(str(resolved))[0] or "application/octet-stream"
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def send_json(self, payload, status: int = 200) -> None:
        data = json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, format: str, *args) -> None:
        print("[company-narrative-editor] " + format % args)


def run_server(host: str, port: int) -> None:
    server = ThreadingHTTPServer((host, port), CompanyNarrativeEditorHandler)
    print(f"Company Narrative editor running at http://{host}:{port}")
    print("Press Ctrl+C to stop.")
    server.serve_forever()


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Dev-only Company Narrative content editor")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8771)
    parser.add_argument("--validate", action="store_true", help="Validate the editable source and exit.")
    parser.add_argument("--export", action="store_true", help="Export source to runtime JSON and exit.")
    parser.add_argument("--dry-run", action="store_true", help="Do not write runtime JSON when exporting.")
    args = parser.parse_args(argv)

    source = load_source()
    validation = validate_source(source)
    if args.validate:
        print(json.dumps(validation, ensure_ascii=False, indent=2))
        return 0 if validation["valid"] else 1
    if args.export:
        if not validation["valid"]:
            print(json.dumps(validation, ensure_ascii=False, indent=2))
            return 1
        payloads = export_runtime_payloads(source)
        if args.dry_run:
            encoded = json.dumps(payloads, ensure_ascii=False, indent=2)
            print(f"Dry-run export OK: {len(encoded)} bytes")
        else:
            write_json(SOURCE_PATH, source)
            write_json(ARCHETYPES_PATH, payloads["archetype_templates"])
            write_json(WORDS_PATH, payloads["word_data"])
            write_json(PROFILE_DATA_PATH, payloads["profile_data"])
            print(f"Exported {ARCHETYPES_PATH}, {WORDS_PATH}, {PROFILE_DATA_PATH}")
        if validation["warnings"]:
            print(json.dumps({"warnings": validation["warnings"]}, ensure_ascii=False, indent=2))
        return 0

    run_server(args.host, args.port)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
