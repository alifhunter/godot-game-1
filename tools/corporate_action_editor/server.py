#!/usr/bin/env python3
"""Dev-only Corporate Action catalog editor server.

Uses only Python stdlib. The editable source lives next to this file and exports
to the Godot runtime catalog at data/corporate_actions/corporate_action_catalog.json.
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
SOURCE_PATH = TOOL_DIR / "corporate_action_source.json"
STATIC_DIR = TOOL_DIR / "static"
RUNTIME_PATH = PROJECT_ROOT / "data" / "corporate_actions" / "corporate_action_catalog.json"

REQUIRED_TOP_LEVEL_KEYS = [
    "review_interval_days",
    "annual_rups",
    "cash_dividend",
    "stock_dividend",
    "stock_buyback",
    "stock_split",
    "tender_offer",
    "strategic_merger_acquisition",
    "backdoor_listing",
    "ceo_change",
    "rights_issue",
    "restructuring",
    "meeting_defaults",
    "stage_order",
    "stage_templates",
    "families",
]
V1_FAMILY_IDS = [
    "rights_issue",
    "stock_buyback",
    "stock_split",
    "tender_offer",
    "strategic_merger_acquisition",
    "backdoor_listing",
    "ceo_change",
    "private_placement",
    "restructuring",
]
CONFIG_SECTIONS = [
    "annual_rups",
    "cash_dividend",
    "stock_dividend",
    "stock_buyback",
    "stock_split",
    "tender_offer",
    "strategic_merger_acquisition",
    "backdoor_listing",
    "ceo_change",
    "rights_issue",
    "restructuring",
    "meeting_defaults",
]
SESSION_STAGE_ORDER = ["arrival", "seating", "host_intro", "agenda_reveal", "vote", "result"]
STAGE_REQUIRED_FIELDS = [
    "label",
    "visibility",
    "tone",
    "category",
    "article_stage",
    "progress_key",
    "sentiment_shift",
    "volatility_multiplier",
]
PRESENTATION_REQUIRED_FIELDS = [
    "stage_labels",
    "host_intro_lines",
    "observer_copy",
    "vote_prompt",
    "approved_result_copy",
    "rejected_result_copy",
]
VALID_VISIBILITIES = ["hidden", "visible"]
VALID_TONES = ["positive", "negative", "mixed"]
VALID_ARTICLE_STAGES = ["whisper", "analysis", "confirmation", "recap"]
VALID_PROGRESS_KEYS = ["early", "developing", "follow_through", "recap"]
VALID_VENUES = ["annual_rups", "rupslb"]
TENDER_BUTTON_FIELDS = ["agree_button_label", "disagree_button_label", "abstain_button_label"]


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
        "catalog": normalize_catalog_for_source(read_json(RUNTIME_PATH)),
        "notes": "Imported from data/corporate_actions/corporate_action_catalog.json.",
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
    if isinstance(source.get("catalog"), dict):
        catalog = source.get("catalog", {})
    elif looks_like_runtime_catalog(source):
        catalog = source
        source = {"schema_version": 1, "catalog": catalog}
    else:
        return import_runtime_source()
    if not any(key in catalog for key in REQUIRED_TOP_LEVEL_KEYS):
        return import_runtime_source()
    source = copy.deepcopy(source)
    source["schema_version"] = int(source.get("schema_version", 1) or 1)
    source["catalog"] = normalize_catalog_for_source(catalog)
    return source


def looks_like_runtime_catalog(value) -> bool:
    return isinstance(value, dict) and ("families" in value or "stage_templates" in value or "review_interval_days" in value)


def normalize_catalog_for_source(catalog: dict) -> dict:
    catalog = copy.deepcopy(catalog if isinstance(catalog, dict) else {})
    catalog["review_interval_days"] = normalize_int(catalog.get("review_interval_days", 5), 5)
    for section in CONFIG_SECTIONS:
        catalog[section] = normalize_deep_value(catalog.get(section, {}))
    catalog["stage_order"] = normalize_string_array(catalog.get("stage_order", []))
    catalog["stage_templates"] = normalize_stage_templates(catalog.get("stage_templates", {}), catalog["stage_order"])
    catalog["families"] = normalize_families(catalog.get("families", []))
    return catalog


def normalize_stage_templates(value, stage_order: list[str]) -> dict:
    if not isinstance(value, dict):
        value = {}
    templates: dict = {}
    for stage_id in stage_order:
        row = value.get(stage_id, {})
        if not isinstance(row, dict):
            row = {}
        row = copy.deepcopy(row)
        row["label"] = str(row.get("label", stage_id.replace("_", " ").title()))
        row["visibility"] = str(row.get("visibility", "visible")).strip() or "visible"
        row["tone"] = str(row.get("tone", "mixed")).strip() or "mixed"
        row["category"] = str(row.get("category", "corporate_action_rumor")).strip()
        row["article_stage"] = str(row.get("article_stage", "analysis")).strip() or "analysis"
        row["progress_key"] = str(row.get("progress_key", "developing")).strip() or "developing"
        row["sentiment_shift"] = normalize_float(row.get("sentiment_shift", 0.0), 0.0)
        row["volatility_multiplier"] = normalize_float(row.get("volatility_multiplier", 1.0), 1.0)
        templates[stage_id] = row
    for stage_id, row in value.items():
        clean_stage_id = str(stage_id).strip()
        if clean_stage_id and clean_stage_id not in templates and isinstance(row, dict):
            templates[clean_stage_id] = normalize_deep_value(row)
    return templates


def normalize_families(value) -> list[dict]:
    if not isinstance(value, list):
        return []
    families: list[dict] = []
    for row in value:
        if not isinstance(row, dict):
            continue
        family = copy.deepcopy(row)
        family["id"] = str(family.get("id", "")).strip()
        family["enabled"] = bool(family.get("enabled", False))
        family["label"] = str(family.get("label", family["id"].replace("_", " ").title())).strip()
        family["default_venue_type"] = str(family.get("default_venue_type", "annual_rups")).strip() or "annual_rups"
        family["mutually_exclusive_families"] = normalize_string_array(family.get("mutually_exclusive_families", []))
        family["supports_delay"] = bool(family.get("supports_delay", False))
        family["prefers_denial_response"] = bool(family.get("prefers_denial_response", False))
        family["story_bias"] = normalize_float(family.get("story_bias", 1.0), 1.0)
        family["agendas"] = normalize_agendas(family.get("agendas", []))
        family["meeting_presentation"] = normalize_meeting_presentation(family.get("meeting_presentation", {}))
        families.append(family)
    return families


def normalize_agendas(value) -> list[dict]:
    if not isinstance(value, list):
        return []
    agendas: list[dict] = []
    for row in value:
        if not isinstance(row, dict):
            continue
        agendas.append({
            "id": str(row.get("id", "")).strip(),
            "label": str(row.get("label", "")).strip(),
            "description": str(row.get("description", "")).strip(),
        })
    return agendas


def normalize_meeting_presentation(value) -> dict:
    if not isinstance(value, dict):
        value = {}
    presentation = copy.deepcopy(value)
    stage_labels = presentation.get("stage_labels", {})
    if not isinstance(stage_labels, dict):
        stage_labels = {}
    presentation["stage_labels"] = {
        stage_id: str(stage_labels.get(stage_id, stage_id.replace("_", " ").title()))
        for stage_id in SESSION_STAGE_ORDER
    }
    presentation["host_intro_lines"] = normalize_string_array(presentation.get("host_intro_lines", []))
    for field in ["observer_copy", "vote_prompt", "approved_result_copy", "rejected_result_copy", *TENDER_BUTTON_FIELDS]:
        if field in presentation:
            presentation[field] = str(presentation.get(field, "")).strip()
    for field in ["observer_copy", "vote_prompt", "approved_result_copy", "rejected_result_copy"]:
        presentation[field] = str(presentation.get(field, "")).strip()
    return presentation


def normalize_deep_value(value):
    if isinstance(value, dict):
        return {str(key).strip(): normalize_deep_value(row) for key, row in value.items() if str(key).strip()}
    if isinstance(value, list):
        return [normalize_deep_value(row) for row in value]
    if isinstance(value, bool):
        return value
    if isinstance(value, int) and not isinstance(value, bool):
        return value
    if isinstance(value, float):
        return value
    if isinstance(value, str):
        trimmed = value.strip()
        if trimmed.lower() in ["true", "false"]:
            return trimmed.lower() == "true"
        if re.fullmatch(r"-?\d+", trimmed):
            try:
                return int(trimmed)
            except ValueError:
                return trimmed
        if re.fullmatch(r"-?(?:\d+\.\d*|\d*\.\d+)", trimmed):
            try:
                return float(trimmed)
            except ValueError:
                return trimmed
        return value
    return value


def normalize_string_array(value) -> list[str]:
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        return [line.strip() for line in value.splitlines() if line.strip()]
    return []


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


def export_runtime_catalog(source: dict) -> dict:
    return normalize_catalog_for_source(source.get("catalog", {}))


def validate_source(source: dict) -> dict:
    errors: list[str] = []
    warnings: list[str] = []
    raw_catalog = source.get("catalog", {}) if isinstance(source, dict) else {}
    if not isinstance(raw_catalog, dict):
        return {"valid": False, "errors": ["Source catalog must be an object."], "warnings": []}
    for key in REQUIRED_TOP_LEVEL_KEYS:
        if key not in raw_catalog:
            errors.append(f"Missing top-level key: {key}.")
    catalog = normalize_catalog_for_source(raw_catalog)
    validate_global_config(catalog, errors, warnings)
    validate_stage_templates(catalog, errors, warnings)
    validate_families(catalog, errors, warnings)
    return {"valid": len(errors) == 0, "errors": errors, "warnings": warnings}


def validate_global_config(catalog: dict, errors: list[str], warnings: list[str]) -> None:
    if int(catalog.get("review_interval_days", 0)) < 1:
        errors.append("review_interval_days must be at least 1.")
    annual = catalog.get("annual_rups", {})
    if not isinstance(annual, dict):
        errors.append("annual_rups must be an object.")
    else:
        start_year = int(annual.get("start_year", 0))
        end_year = int(annual.get("end_year", 0))
        start_month = int(annual.get("start_month", 0))
        end_month = int(annual.get("end_month", 0))
        if start_year > end_year:
            errors.append("annual_rups.start_year must be <= end_year.")
        if start_month < 1 or start_month > 12 or end_month < 1 or end_month > 12:
            errors.append("annual_rups start/end months must be between 1 and 12.")
        elif start_month > end_month:
            errors.append("annual_rups.start_month must be <= end_month.")
    for section in CONFIG_SECTIONS:
        value = catalog.get(section, {})
        if not isinstance(value, dict):
            errors.append(f"{section} must be an object.")
            continue
        validate_numeric_pairs(value, section, errors)
        validate_numeric_bounds(value, section, errors, warnings)
        if "enabled" in value and not isinstance(value.get("enabled"), bool):
            errors.append(f"{section}.enabled must be true or false.")
    validate_meeting_defaults(catalog.get("meeting_defaults", {}), errors)
    validate_stock_split_config(catalog.get("stock_split", {}), errors)


def validate_meeting_defaults(defaults: dict, errors: list[str]) -> None:
    if not isinstance(defaults, dict):
        errors.append("meeting_defaults must be an object.")
        return
    for key in ["earnings_call", "rupslb", "annual_rups"]:
        if key not in defaults:
            errors.append(f"meeting_defaults.{key} is required.")
        elif not isinstance(defaults.get(key), dict):
            errors.append(f"meeting_defaults.{key} must be an object.")


def validate_stock_split_config(config: dict, errors: list[str]) -> None:
    for key in ["split_ratios", "reverse_split_ratios"]:
        rows = config.get(key, [])
        if not isinstance(rows, list) or not rows:
            errors.append(f"stock_split.{key} must be a non-empty array.")
            continue
        for index, value in enumerate(rows):
            if not isinstance(value, (int, float)) or int(value) < 2:
                errors.append(f"stock_split.{key}[{index}] must be an integer >= 2.")


def validate_stage_templates(catalog: dict, errors: list[str], warnings: list[str]) -> None:
    stage_order = catalog.get("stage_order", [])
    templates = catalog.get("stage_templates", {})
    if not isinstance(stage_order, list) or not stage_order:
        errors.append("stage_order must be a non-empty array.")
        return
    if len(stage_order) != len(set(stage_order)):
        errors.append("stage_order contains duplicate stage ids.")
    if not isinstance(templates, dict):
        errors.append("stage_templates must be an object.")
        return
    for index, stage_id in enumerate(stage_order):
        label = f"stage_templates.{stage_id}"
        if not stage_id:
            errors.append(f"stage_order[{index}] is empty.")
            continue
        if stage_id not in templates:
            errors.append(f"{label} is missing.")
            continue
        row = templates.get(stage_id, {})
        if not isinstance(row, dict):
            errors.append(f"{label} must be an object.")
            continue
        for field in STAGE_REQUIRED_FIELDS:
            if field not in row or str(row.get(field, "")).strip() == "":
                errors.append(f"{label}.{field} is required.")
        if str(row.get("visibility", "")) not in VALID_VISIBILITIES:
            errors.append(f"{label}.visibility must be hidden or visible.")
        if str(row.get("tone", "")) not in VALID_TONES:
            errors.append(f"{label}.tone should be positive, negative, or mixed.")
        if str(row.get("article_stage", "")) not in VALID_ARTICLE_STAGES:
            warnings.append(f"{label}.article_stage is outside the usual article stages.")
        if str(row.get("progress_key", "")) not in VALID_PROGRESS_KEYS:
            warnings.append(f"{label}.progress_key is outside the usual progress keys.")
        sentiment = float(row.get("sentiment_shift", 0.0))
        if sentiment < -1.0 or sentiment > 1.0:
            errors.append(f"{label}.sentiment_shift must stay between -1 and 1.")
        volatility = float(row.get("volatility_multiplier", 1.0))
        if volatility <= 0.0 or volatility > 5.0:
            errors.append(f"{label}.volatility_multiplier must be > 0 and <= 5.")


def validate_families(catalog: dict, errors: list[str], warnings: list[str]) -> None:
    families = catalog.get("families", [])
    if not isinstance(families, list) or not families:
        errors.append("families must be a non-empty array.")
        return
    seen_ids: set[str] = set()
    family_ids: set[str] = set()
    for index, family in enumerate(families):
        if not isinstance(family, dict):
            errors.append(f"families[{index}] must be an object.")
            continue
        family_id = str(family.get("id", "")).strip()
        label = family_id or f"families[{index}]"
        if not family_id:
            errors.append(f"{label}: id is required.")
        elif family_id in seen_ids:
            errors.append(f"{label}: family id must be unique.")
        seen_ids.add(family_id)
        family_ids.add(family_id)
        if not str(family.get("label", "")).strip():
            errors.append(f"{label}: label is required.")
        if not isinstance(family.get("enabled", False), bool):
            errors.append(f"{label}: enabled must be true or false.")
        venue = str(family.get("default_venue_type", "")).strip()
        if venue not in VALID_VENUES:
            errors.append(f"{label}: default_venue_type must be annual_rups or rupslb.")
        for field in ["supports_delay", "prefers_denial_response"]:
            if not isinstance(family.get(field, False), bool):
                errors.append(f"{label}: {field} must be true or false.")
        story_bias = float(family.get("story_bias", 0.0))
        if story_bias <= 0.0:
            errors.append(f"{label}: story_bias must be > 0.")
        elif story_bias > 1.5:
            warnings.append(f"{label}: story_bias above 1.5 may spawn this family very aggressively.")
        if family_id != "private_placement" and family_id and family_id not in catalog:
            warnings.append(f"{label}: no top-level numeric config section named '{family_id}'.")
        for exclusive_id in family.get("mutually_exclusive_families", []):
            if exclusive_id not in V1_FAMILY_IDS and exclusive_id not in family_ids:
                warnings.append(f"{label}: mutually_exclusive_families references unknown family '{exclusive_id}'.")
        validate_agendas(family.get("agendas", []), label, errors)
        validate_meeting_presentation(family.get("meeting_presentation", {}), label, family_id, errors, warnings)
    for family_id in V1_FAMILY_IDS:
        if family_id not in seen_ids:
            errors.append(f"families must include v1 family '{family_id}'.")
    for family in families:
        if isinstance(family, dict) and str(family.get("id", "")) in V1_FAMILY_IDS and not bool(family.get("enabled", False)):
            warnings.append(f"{family.get('id')}: v1 family is disabled; organic/debug generation will skip it.")


def validate_agendas(agendas, family_label: str, errors: list[str]) -> None:
    if not isinstance(agendas, list) or not agendas:
        errors.append(f"{family_label}: agendas must contain at least one agenda.")
        return
    seen_ids: set[str] = set()
    for index, agenda in enumerate(agendas):
        if not isinstance(agenda, dict):
            errors.append(f"{family_label}.agendas[{index}] must be an object.")
            continue
        agenda_id = str(agenda.get("id", "")).strip()
        if not agenda_id:
            errors.append(f"{family_label}.agendas[{index}].id is required.")
        elif agenda_id in seen_ids:
            errors.append(f"{family_label}: duplicate agenda id '{agenda_id}'.")
        seen_ids.add(agenda_id)
        for field in ["label", "description"]:
            if not str(agenda.get(field, "")).strip():
                errors.append(f"{family_label}.{agenda_id or index}: {field} is required.")


def validate_meeting_presentation(presentation, family_label: str, family_id: str, errors: list[str], warnings: list[str]) -> None:
    if not isinstance(presentation, dict):
        errors.append(f"{family_label}: meeting_presentation must be an object.")
        return
    for field in PRESENTATION_REQUIRED_FIELDS:
        if field not in presentation:
            errors.append(f"{family_label}.meeting_presentation.{field} is required.")
    stage_labels = presentation.get("stage_labels", {})
    if not isinstance(stage_labels, dict):
        errors.append(f"{family_label}.meeting_presentation.stage_labels must be an object.")
    else:
        for stage_id in SESSION_STAGE_ORDER:
            if not str(stage_labels.get(stage_id, "")).strip():
                errors.append(f"{family_label}.meeting_presentation.stage_labels.{stage_id} is required.")
    host_lines = presentation.get("host_intro_lines", [])
    if not isinstance(host_lines, list) or not [line for line in host_lines if str(line).strip()]:
        errors.append(f"{family_label}.meeting_presentation.host_intro_lines needs at least one line.")
    elif len(host_lines) == 1:
        warnings.append(f"{family_label}.meeting_presentation.host_intro_lines has only one line.")
    for field in ["observer_copy", "vote_prompt", "approved_result_copy", "rejected_result_copy"]:
        if not str(presentation.get(field, "")).strip():
            errors.append(f"{family_label}.meeting_presentation.{field} is required.")
    if family_id == "tender_offer":
        for field in TENDER_BUTTON_FIELDS:
            if not str(presentation.get(field, "")).strip():
                errors.append(f"{family_label}.meeting_presentation.{field} is required for tender offer elections.")


def validate_numeric_pairs(value: dict, label: str, errors: list[str]) -> None:
    for key, row in value.items():
        if isinstance(row, dict):
            validate_numeric_pairs(row, f"{label}.{key}", errors)
    for key, min_value in value.items():
        if not isinstance(min_value, (int, float)) or isinstance(min_value, bool):
            continue
        max_key = matching_max_key(str(key), value)
        if not max_key:
            continue
        max_value = value.get(max_key)
        if isinstance(max_value, (int, float)) and not isinstance(max_value, bool) and float(min_value) > float(max_value):
            errors.append(f"{label}.{key} must be <= {label}.{max_key}.")


def matching_max_key(key: str, value: dict) -> str:
    candidates: list[str] = []
    if key.startswith("minimum_"):
        candidates.append("maximum_" + key.removeprefix("minimum_"))
    if key.startswith("min_"):
        candidates.append("max_" + key.removeprefix("min_"))
    if "_minimum_" in key:
        candidates.append(key.replace("_minimum_", "_maximum_", 1))
    if key.endswith("_min_days"):
        candidates.append(key.removesuffix("_min_days") + "_max_days")
    if key.endswith("_minimum_days"):
        candidates.append(key.removesuffix("_minimum_days") + "_maximum_days")
    for candidate in candidates:
        if candidate in value:
            return candidate
    return ""


def validate_numeric_bounds(value: dict, label: str, errors: list[str], warnings: list[str]) -> None:
    for key, row in value.items():
        child_label = f"{label}.{key}"
        if isinstance(row, dict):
            validate_numeric_bounds(row, child_label, errors, warnings)
            continue
        if isinstance(row, bool) or not isinstance(row, (int, float)):
            continue
        number = float(row)
        key_text = str(key)
        if key_text.endswith("_days") or key_text.endswith("_count") or "delay" in key_text and key_text.endswith("_days"):
            if number < 0:
                errors.append(f"{child_label} must be non-negative.")
        if key_text.endswith("_probability") or key_text.endswith("_probability_pct"):
            if number < 0:
                errors.append(f"{child_label} must be non-negative.")
            if key_text.endswith("_probability") and number > 1:
                warnings.append(f"{child_label} is above 1.0; confirm this is intentional.")
            if key_text.endswith("_probability_pct") and number > 100:
                errors.append(f"{child_label} must be <= 100.")
        if key_text.endswith("_score") and (number < 0 or number > 1):
            errors.append(f"{child_label} score fields must stay between 0 and 1.")
        if key_text.endswith("_multiplier") and number <= 0:
            errors.append(f"{child_label} multiplier fields must be positive.")


class CorporateActionEditorHandler(BaseHTTPRequestHandler):
    server_version = "CorporateActionEditor/1.0"

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
            write_json(SOURCE_PATH, source)
            write_json(RUNTIME_PATH, export_runtime_catalog(source))
            self.send_json({"exported": True, "path": str(RUNTIME_PATH), "validation": validation})
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
        if isinstance(payload, dict) and isinstance(payload.get("catalog"), dict):
            source = copy.deepcopy(payload)
        elif looks_like_runtime_catalog(payload):
            source = {"schema_version": 1, "catalog": copy.deepcopy(payload)}
        else:
            source = load_source()
        source["schema_version"] = int(source.get("schema_version", 1) or 1)
        source["catalog"] = normalize_catalog_for_source(source.get("catalog", {}))
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
        print("[corporate-action-editor] " + format % args)


def run_server(host: str, port: int) -> None:
    server = ThreadingHTTPServer((host, port), CorporateActionEditorHandler)
    print(f"Corporate Action editor running at http://{host}:{port}")
    print("Press Ctrl+C to stop.")
    server.serve_forever()


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Dev-only Corporate Action content editor")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8769)
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
        runtime_catalog = export_runtime_catalog(source)
        if args.dry_run:
            encoded = json.dumps(runtime_catalog, ensure_ascii=False, indent=2)
            print(f"Dry-run export OK: {len(encoded)} bytes")
        else:
            write_json(SOURCE_PATH, source)
            write_json(RUNTIME_PATH, runtime_catalog)
            print(f"Exported {RUNTIME_PATH}")
        if validation["warnings"]:
            print(json.dumps({"warnings": validation["warnings"]}, ensure_ascii=False, indent=2))
        return 0

    run_server(args.host, args.port)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
