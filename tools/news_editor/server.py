#!/usr/bin/env python3
"""Dev-only News content editor server.

Uses only Python stdlib. The editable source lives next to this file and exports
to the Godot runtime catalog at data/news/news_feed_data.json.
"""

from __future__ import annotations

import argparse
import base64
import copy
import json
import mimetypes
import re
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlparse


TOOL_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = TOOL_DIR.parents[1]
SOURCE_PATH = TOOL_DIR / "news_source.json"
STATIC_DIR = TOOL_DIR / "static"
RUNTIME_PATH = PROJECT_ROOT / "data" / "news" / "news_feed_data.json"
ASSET_DIR = PROJECT_ROOT / "assets" / "news"
ASSET_RES_PREFIX = "res://assets/news/"
ALLOWED_IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}

REQUIRED_TOP_LEVEL_KEYS = [
    "prototype_default_intel_level",
    "article_limit",
    "outlets",
    "authors",
    "progress_labels",
    "reference_signals",
    "driver_phrases",
    "watch_phrases",
    "body_slots",
    "voice_profiles",
]
REQUIRED_PROGRESS_LABELS = ["early", "developing", "follow_through", "recap"]
REQUIRED_BODY_SLOT_GROUPS = [
    "market_reaction_templates",
    "source_color_templates",
    "continuity_templates",
    "closing_templates",
]
REQUIRED_VOICE_TEMPLATE_SECTIONS = ["headline_templates", "deck_templates", "lead_templates"]
VOICE_STAGE_FALLBACK = "recap"
KNOWN_TEMPLATE_TOKENS = {
    "target_company_id",
    "target_ticker",
    "target_company_name",
    "target_sector_id",
    "sector_name",
    "person_name",
    "provider_label",
    "scope",
    "tone",
    "focus_label",
    "subject_label",
    "subject_reference",
    "headline_hint",
    "detail_hint",
    "detail_blend",
    "current_price",
    "price_action_label",
    "market_change",
    "market_state_label",
    "breadth_summary",
    "advancers",
    "decliners",
    "biggest_winner",
    "biggest_loser",
    "whisper_phrase",
    "desk_watch",
    "formal_phrase",
    "analysis_phrase",
    "reaction_phrase",
    "market_jargon",
    "driver_phrase",
    "watch_phrase",
    "phase_phrase",
    "flow_label",
    "stance_word",
    "trade_day_label",
    "public_story_angle",
    "public_confidence_label",
    "public_continuity_phrase",
    "continuity_phrase",
}


def read_json(path: Path):
    with path.open("r", encoding="utf-8") as file:
        return json.load(file)


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(payload, ensure_ascii=False, indent=2)
    path.write_text(encoded + "\n", encoding="utf-8")


def slugify(value: str, fallback: str = "news-asset") -> str:
    normalized = re.sub(r"[^a-zA-Z0-9._-]+", "-", value.strip()).strip("-._")
    return normalized or fallback


def make_unique_asset_path(filename: str) -> Path:
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    safe_name = slugify(Path(filename).stem)
    suffix = Path(filename).suffix.lower()
    if suffix not in ALLOWED_IMAGE_EXTENSIONS:
        suffix = ".png"
    candidate = ASSET_DIR / f"{safe_name}{suffix}"
    counter = 2
    while candidate.exists():
        candidate = ASSET_DIR / f"{safe_name}-{counter}{suffix}"
        counter += 1
    return candidate


def res_path_to_disk(res_path: str) -> Path | None:
    if not res_path.startswith("res://"):
        return None
    relative_path = res_path.removeprefix("res://")
    disk_path = (PROJECT_ROOT / relative_path).resolve()
    try:
        disk_path.relative_to(PROJECT_ROOT.resolve())
    except ValueError:
        return None
    return disk_path


def import_runtime_source() -> dict:
    catalog = read_json(RUNTIME_PATH)
    return {
        "schema_version": 1,
        "catalog": normalize_catalog_for_source(catalog),
        "notes": "Imported from data/news/news_feed_data.json.",
    }


def load_source() -> dict:
    if not SOURCE_PATH.exists():
        return import_runtime_source()
    try:
        source = read_json(SOURCE_PATH)
    except json.JSONDecodeError:
        return import_runtime_source()
    if not isinstance(source, dict) or not isinstance(source.get("catalog"), dict):
        return import_runtime_source()
    source = copy.deepcopy(source)
    source["schema_version"] = int(source.get("schema_version", 1))
    source["catalog"] = normalize_catalog_for_source(source.get("catalog", {}))
    return source


def normalize_catalog_for_source(catalog: dict) -> dict:
    catalog = copy.deepcopy(catalog if isinstance(catalog, dict) else {})
    catalog["prototype_default_intel_level"] = int(catalog.get("prototype_default_intel_level", 1) or 1)
    catalog["article_limit"] = int(catalog.get("article_limit", 12) or 12)
    catalog["outlets"] = normalize_object_array(catalog.get("outlets", []))
    catalog["authors"] = normalize_object_array(catalog.get("authors", []))
    for outlet in catalog["outlets"]:
        outlet["id"] = str(outlet.get("id", "")).strip()
        outlet["label"] = str(outlet.get("label", "")).strip()
        outlet["voice"] = str(outlet.get("voice", outlet.get("id", ""))).strip()
        outlet["intel_level"] = int(outlet.get("intel_level", 1) or 1)
        outlet["tagline"] = str(outlet.get("tagline", ""))
        outlet["summary"] = str(outlet.get("summary", ""))
        if "logo_asset" in outlet:
            outlet["logo_asset"] = str(outlet.get("logo_asset", ""))
    for author in catalog["authors"]:
        author["id"] = str(author.get("id", "")).strip()
        author["display_name"] = str(author.get("display_name", "")).strip()
        author["role"] = str(author.get("role", "")).strip()
        author["outlet_ids"] = normalize_string_array(author.get("outlet_ids", []))
        author["specialties"] = normalize_string_array(author.get("specialties", []))
        author["sector_ids"] = normalize_string_array(author.get("sector_ids", []))
        author["contact_id"] = str(author.get("contact_id", ""))
        author["portrait_asset"] = str(author.get("portrait_asset", ""))
        author["lead_frequency"] = clamp_float(author.get("lead_frequency", 0.0), 0.0, 1.0)
    catalog["progress_labels"] = normalize_string_map(catalog.get("progress_labels", {}))
    catalog["reference_signals"] = normalize_pool_map(catalog.get("reference_signals", {}))
    catalog["driver_phrases"] = normalize_pool_map(catalog.get("driver_phrases", {}))
    catalog["watch_phrases"] = normalize_pool_map(catalog.get("watch_phrases", {}))
    catalog["body_slots"] = normalize_nested_pool_map(catalog.get("body_slots", {}))
    catalog["voice_profiles"] = normalize_voice_profiles(catalog.get("voice_profiles", {}))
    return catalog


def normalize_object_array(value) -> list[dict]:
    if not isinstance(value, list):
        return []
    return [copy.deepcopy(row) for row in value if isinstance(row, dict)]


def normalize_string_array(value) -> list[str]:
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        return [line.strip() for line in value.splitlines() if line.strip()]
    return []


def normalize_string_map(value) -> dict:
    if not isinstance(value, dict):
        return {}
    return {str(key).strip(): str(row) for key, row in value.items() if str(key).strip()}


def normalize_pool_map(value) -> dict:
    if not isinstance(value, dict):
        return {}
    return {
        str(key).strip(): normalize_string_array(row)
        for key, row in value.items()
        if str(key).strip()
    }


def normalize_nested_pool_map(value) -> dict:
    if not isinstance(value, dict):
        return {}
    normalized: dict = {}
    for group_key, group_value in value.items():
        group_id = str(group_key).strip()
        if not group_id:
            continue
        normalized[group_id] = normalize_pool_map(group_value)
    return normalized


def normalize_voice_profiles(value) -> dict:
    if not isinstance(value, dict):
        return {}
    profiles: dict = {}
    for profile_key, profile_value in value.items():
        profile_id = str(profile_key).strip()
        if not profile_id or not isinstance(profile_value, dict):
            continue
        profile = copy.deepcopy(profile_value)
        profile["headline_prefixes"] = normalize_string_array(profile.get("headline_prefixes", []))
        for section in REQUIRED_VOICE_TEMPLATE_SECTIONS:
            profile[section] = normalize_pool_map(profile.get(section, {}))
        profile["context_templates"] = normalize_string_array(profile.get("context_templates", []))
        profile["impact_templates"] = normalize_string_array(profile.get("impact_templates", []))
        profiles[profile_id] = profile
    return profiles


def clamp_float(value, min_value: float, max_value: float) -> float:
    try:
        number = float(value)
    except (TypeError, ValueError):
        number = min_value
    return max(min(number, max_value), min_value)


def export_runtime_catalog(source: dict) -> dict:
    return normalize_catalog_for_source(source.get("catalog", {}))


def validate_source(source: dict) -> dict:
    errors: list[str] = []
    warnings: list[str] = []
    catalog = normalize_catalog_for_source(source.get("catalog", {}))
    for key in REQUIRED_TOP_LEVEL_KEYS:
        if key not in catalog:
            errors.append(f"Missing top-level key: {key}.")

    outlets = catalog.get("outlets", [])
    outlet_ids = validate_outlets(outlets, catalog, errors, warnings)
    validate_authors(catalog.get("authors", []), outlet_ids, errors, warnings)
    validate_progress_labels(catalog.get("progress_labels", {}), errors)
    validate_pool_map(catalog.get("reference_signals", {}), "reference_signals", errors, warnings)
    validate_pool_map(catalog.get("driver_phrases", {}), "driver_phrases", errors, warnings)
    validate_pool_map(catalog.get("watch_phrases", {}), "watch_phrases", errors, warnings)
    validate_body_slots(catalog.get("body_slots", {}), errors, warnings)
    validate_voice_profiles(catalog.get("voice_profiles", {}), outlets, errors, warnings)

    default_level = int(catalog.get("prototype_default_intel_level", 0))
    max_level = max([int(outlet.get("intel_level", 1)) for outlet in outlets], default=1)
    if default_level < 1 or default_level > max(max_level, 1):
        errors.append("prototype_default_intel_level must be between 1 and the highest outlet intel level.")
    if int(catalog.get("article_limit", 0)) < 1:
        errors.append("article_limit must be at least 1.")

    return {"valid": len(errors) == 0, "errors": errors, "warnings": warnings}


def validate_outlets(outlets: list[dict], catalog: dict, errors: list[str], warnings: list[str]) -> set[str]:
    if not outlets:
        errors.append("outlets must contain at least one outlet.")
    outlet_ids: set[str] = set()
    voice_profiles = catalog.get("voice_profiles", {})
    for index, outlet in enumerate(outlets):
        outlet_id = str(outlet.get("id", "")).strip()
        label = outlet_id or f"outlets[{index}]"
        if not outlet_id:
            errors.append(f"{label}: id is required.")
        elif outlet_id in outlet_ids:
            errors.append(f"{label}: outlet id must be unique.")
        outlet_ids.add(outlet_id)
        if not str(outlet.get("label", "")).strip():
            errors.append(f"{label}: label is required.")
        voice_id = str(outlet.get("voice", "")).strip()
        if not voice_id:
            warnings.append(f"{label}: voice is empty; runtime will fall back to outlet id.")
        elif voice_id not in voice_profiles:
            errors.append(f"{label}: voice '{voice_id}' does not exist in voice_profiles.")
        intel_level = int(outlet.get("intel_level", 0))
        if intel_level < 1 or intel_level > 4:
            warnings.append(f"{label}: intel_level is outside the usual 1-4 range.")
        if not str(outlet.get("tagline", "")).strip():
            warnings.append(f"{label}: tagline is empty.")
        if not str(outlet.get("summary", "")).strip():
            warnings.append(f"{label}: summary is empty.")
        validate_optional_asset_path(str(outlet.get("logo_asset", "")).strip(), f"{label}: logo_asset", errors, warnings)
    return outlet_ids


def validate_authors(authors: list[dict], outlet_ids: set[str], errors: list[str], warnings: list[str]) -> None:
    author_ids: set[str] = set()
    if not authors:
        warnings.append("authors is empty; runtime will fall back to outlet desk bylines.")
    for index, author in enumerate(authors):
        author_id = str(author.get("id", "")).strip()
        label = author_id or f"authors[{index}]"
        if not author_id:
            errors.append(f"{label}: id is required.")
        elif author_id in author_ids:
            errors.append(f"{label}: author id must be unique.")
        author_ids.add(author_id)
        if not str(author.get("display_name", "")).strip():
            errors.append(f"{label}: display_name is required.")
        if not str(author.get("role", "")).strip():
            errors.append(f"{label}: role is required.")
        for outlet_id in author.get("outlet_ids", []):
            if str(outlet_id) not in outlet_ids:
                errors.append(f"{label}: outlet id '{outlet_id}' does not exist.")
        if not author.get("specialties", []):
            warnings.append(f"{label}: specialties is empty.")
        lead_frequency = float(author.get("lead_frequency", 0.0))
        if lead_frequency < 0.0 or lead_frequency > 1.0:
            errors.append(f"{label}: lead_frequency must be between 0 and 1.")
        if lead_frequency > 0.0 and not str(author.get("contact_id", "")).strip():
            warnings.append(f"{label}: lead_frequency is positive but contact_id is empty.")
        validate_optional_asset_path(str(author.get("portrait_asset", "")).strip(), f"{label}: portrait_asset", errors, warnings)


def validate_progress_labels(progress_labels: dict, errors: list[str]) -> None:
    if not isinstance(progress_labels, dict) or not progress_labels:
        errors.append("progress_labels must be a non-empty object.")
        return
    for key in REQUIRED_PROGRESS_LABELS:
        if not str(progress_labels.get(key, "")).strip():
            errors.append(f"progress_labels.{key} is required.")


def validate_pool_map(pool_map: dict, label: str, errors: list[str], warnings: list[str]) -> None:
    if not isinstance(pool_map, dict) or not pool_map:
        errors.append(f"{label} must be a non-empty object.")
        return
    for key, pool in pool_map.items():
        row_label = f"{label}.{key}"
        if not isinstance(pool, list):
            errors.append(f"{row_label} must be an array.")
            continue
        clean_pool = [str(row).strip() for row in pool if str(row).strip()]
        if not clean_pool:
            errors.append(f"{row_label} needs at least one non-empty line.")
        elif len(clean_pool) == 1:
            warnings.append(f"{row_label} has only one line; add variants when possible.")
        validate_template_tokens(clean_pool, row_label, warnings)


def validate_body_slots(body_slots: dict, errors: list[str], warnings: list[str]) -> None:
    if not isinstance(body_slots, dict) or not body_slots:
        errors.append("body_slots must be a non-empty object.")
        return
    for group_key in REQUIRED_BODY_SLOT_GROUPS:
        if group_key not in body_slots:
            errors.append(f"body_slots.{group_key} is required.")
    for group_key, group in body_slots.items():
        group_label = f"body_slots.{group_key}"
        if not isinstance(group, dict) or not group:
            errors.append(f"{group_label} must be a non-empty object.")
            continue
        if group_key == "continuity_templates":
            for continuity_key in ["with_prior", "without_prior"]:
                if continuity_key not in group:
                    errors.append(f"{group_label}.{continuity_key} is required for continuity article bodies.")
        elif "fallback" not in group:
            errors.append(f"{group_label}.fallback is required for safe runtime fallback.")
        validate_pool_map(group, group_label, errors, warnings)


def validate_voice_profiles(voice_profiles: dict, outlets: list[dict], errors: list[str], warnings: list[str]) -> None:
    if not isinstance(voice_profiles, dict) or not voice_profiles:
        errors.append("voice_profiles must be a non-empty object.")
        return
    outlet_voice_ids = {str(outlet.get("voice", outlet.get("id", ""))).strip() for outlet in outlets}
    for voice_id in outlet_voice_ids:
        if voice_id and voice_id not in voice_profiles:
            errors.append(f"voice_profiles.{voice_id} is required because an outlet uses it.")
    for voice_id, profile in voice_profiles.items():
        label = f"voice_profiles.{voice_id}"
        if not isinstance(profile, dict):
            errors.append(f"{label} must be an object.")
            continue
        prefixes = profile.get("headline_prefixes", [])
        if not isinstance(prefixes, list) or not [str(row).strip() for row in prefixes if str(row).strip()]:
            warnings.append(f"{label}.headline_prefixes is empty.")
        for section in REQUIRED_VOICE_TEMPLATE_SECTIONS:
            section_map = profile.get(section, {})
            section_label = f"{label}.{section}"
            if not isinstance(section_map, dict) or not section_map:
                errors.append(f"{section_label} must be a non-empty object.")
                continue
            if VOICE_STAGE_FALLBACK not in section_map:
                errors.append(f"{section_label}.{VOICE_STAGE_FALLBACK} is required as the runtime fallback stage.")
            validate_pool_map(section_map, section_label, errors, warnings)
        for section in ["context_templates", "impact_templates"]:
            pool = profile.get(section, [])
            if not isinstance(pool, list) or not [str(row).strip() for row in pool if str(row).strip()]:
                errors.append(f"{label}.{section} needs at least one template.")
            else:
                validate_template_tokens(pool, f"{label}.{section}", warnings)


def validate_template_tokens(lines: list[str], label: str, warnings: list[str]) -> None:
    for line_index, line in enumerate(lines):
        for token in re.findall(r"\{([a-zA-Z0-9_]+)\}", line):
            if token not in KNOWN_TEMPLATE_TOKENS:
                warnings.append(f"{label}[{line_index}] uses unknown template token {{{token}}}.")


def validate_optional_asset_path(asset_path: str, label: str, errors: list[str], warnings: list[str]) -> None:
    if not asset_path:
        return
    if not asset_path.startswith("res://"):
        errors.append(f"{label} must use a res:// path.")
        return
    disk_path = res_path_to_disk(asset_path)
    if disk_path is None or not disk_path.exists():
        warnings.append(f"{label} points to a missing file; runtime will show a placeholder or empty slot.")


class NewsEditorHandler(BaseHTTPRequestHandler):
    server_version = "NewsEditor/1.0"

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/api/source":
            self.send_json(load_source())
            return
        if parsed.path == "/api/validate":
            self.send_json(validate_source(load_source()))
            return
        if parsed.path == "/asset":
            query = parse_qs(parsed.query)
            self.serve_asset(str(query.get("path", [""])[0]))
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
        if parsed.path == "/api/upload":
            self.handle_upload()
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
        elif isinstance(payload, dict):
            source = {"schema_version": 1, "catalog": copy.deepcopy(payload)}
        else:
            source = load_source()
        source["schema_version"] = int(source.get("schema_version", 1))
        source["catalog"] = normalize_catalog_for_source(source.get("catalog", {}))
        return source

    def handle_upload(self) -> None:
        payload = self.read_json_body()
        if not isinstance(payload, dict):
            self.send_json({"error": "Upload payload must be an object."}, status=400)
            return
        filename = str(payload.get("filename", "news-asset.png"))
        data_url = str(payload.get("data_url", ""))
        if "," in data_url:
            data_url = data_url.split(",", 1)[1]
        try:
            data = base64.b64decode(data_url, validate=True)
        except Exception:
            self.send_json({"error": "Upload data must be base64."}, status=400)
            return
        target_path = make_unique_asset_path(filename)
        target_path.write_bytes(data)
        res_path = ASSET_RES_PREFIX + target_path.name
        self.send_json({"asset_path": res_path, "filename": target_path.name})

    def serve_asset(self, res_path: str) -> None:
        disk_path = res_path_to_disk(res_path)
        if disk_path is None or not disk_path.exists():
            self.send_error(404, "Asset not found")
            return
        self.serve_file(disk_path)

    def serve_file(self, path: Path) -> None:
        try:
            resolved = path.resolve()
            static_root = STATIC_DIR.resolve()
            project_root = PROJECT_ROOT.resolve()
            if resolved != static_root and static_root not in resolved.parents and project_root not in resolved.parents:
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
        print("[news-editor] " + format % args)


def run_server(host: str, port: int) -> None:
    server = ThreadingHTTPServer((host, port), NewsEditorHandler)
    print(f"News editor running at http://{host}:{port}")
    print("Press Ctrl+C to stop.")
    server.serve_forever()


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Dev-only News content editor")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8766)
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
