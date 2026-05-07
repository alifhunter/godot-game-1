#!/usr/bin/env python3
"""Dev-only Network / Contact content editor server.

Uses only Python stdlib. The editable source lives next to this file and exports
to the Godot runtime catalog at data/network/contact_network_data.json.
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
SOURCE_PATH = TOOL_DIR / "network_source.json"
STATIC_DIR = TOOL_DIR / "static"
RUNTIME_PATH = PROJECT_ROOT / "data" / "network" / "contact_network_data.json"
SECTORS_PATH = PROJECT_ROOT / "data" / "sectors" / "sectors.json"

REQUIRED_TOP_LEVEL_KEYS = [
    "base_contact_cap",
    "relationship_default",
    "person_name_pools",
    "meeting_lead_profiles",
    "contacts",
    "tip_templates",
    "request_templates",
]
MEETING_STAGES = ["seating", "host_intro", "agenda_reveal", "vote"]
AFFILIATION_TYPES = ["floater", "insider_template"]
INSIDER_ROLES = ["ceo", "cfo", "commissioner"]
TONE_VALUES = ["positive", "negative", "mixed"]
TEMPLATE_TOKENS = {
    "contact",
    "ticker",
    "company",
    "agenda",
    "sector",
    "role",
}


def read_json(path: Path):
    raw = path.read_text(encoding="utf-8-sig")
    return json.loads(raw)


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(payload, ensure_ascii=False, indent=2)
    path.write_text(encoded + "\n", encoding="utf-8")


def import_runtime_source() -> dict:
    catalog = read_json(RUNTIME_PATH)
    return {
        "schema_version": 1,
        "catalog": normalize_catalog_for_source(catalog),
        "notes": "Imported from data/network/contact_network_data.json.",
    }


def load_source() -> dict:
    if not SOURCE_PATH.exists():
        return import_runtime_source()
    try:
        source = read_json(SOURCE_PATH)
    except (json.JSONDecodeError, OSError):
        return import_runtime_source()
    if not isinstance(source, dict) or not isinstance(source.get("catalog"), dict):
        return import_runtime_source()
    source = copy.deepcopy(source)
    source["schema_version"] = int(source.get("schema_version", 1))
    source["catalog"] = normalize_catalog_for_source(source.get("catalog", {}))
    return source


def load_sector_ids() -> set[str]:
    try:
        sectors = read_json(SECTORS_PATH)
    except (json.JSONDecodeError, OSError):
        return set()
    if not isinstance(sectors, list):
        return set()
    return {str(row.get("id", "")).strip() for row in sectors if isinstance(row, dict) and str(row.get("id", "")).strip()}


def normalize_catalog_for_source(catalog: dict) -> dict:
    catalog = copy.deepcopy(catalog if isinstance(catalog, dict) else {})
    catalog["base_contact_cap"] = int(catalog.get("base_contact_cap", 2) or 2)
    catalog["relationship_default"] = int(catalog.get("relationship_default", 25) or 25)
    catalog["person_name_pools"] = normalize_person_name_pools(catalog.get("person_name_pools", {}))
    catalog["meeting_lead_profiles"] = normalize_meeting_profiles(catalog.get("meeting_lead_profiles", []))
    catalog["contacts"] = normalize_contacts(catalog.get("contacts", []))
    catalog["tip_templates"] = normalize_pool_map(catalog.get("tip_templates", {}))
    catalog["request_templates"] = normalize_string_map(catalog.get("request_templates", {}))
    return catalog


def normalize_person_name_pools(value) -> dict:
    if not isinstance(value, dict):
        value = {}
    return {
        "first_names": normalize_string_array(value.get("first_names", [])),
        "family_names": normalize_string_array(value.get("family_names", [])),
    }


def normalize_meeting_profiles(value) -> list[dict]:
    if not isinstance(value, list):
        return []
    profiles: list[dict] = []
    for row in value:
        if not isinstance(row, dict):
            continue
        profile = copy.deepcopy(row)
        profile["id"] = str(profile.get("id", "")).strip()
        profile["tier"] = str(profile.get("tier", "")).strip()
        profile["role_label"] = str(profile.get("role_label", "")).strip()
        profile["recognition_required"] = int(profile.get("recognition_required", 0) or 0)
        profile["sector_match_required"] = bool(profile.get("sector_match_required", False))
        profile["category_ids"] = normalize_string_array(profile.get("category_ids", []))
        profile["speech_bubbles"] = normalize_string_array(profile.get("speech_bubbles", []))
        profile["stage_speech_bubbles"] = normalize_stage_speech_bubbles(profile.get("stage_speech_bubbles", {}))
        profile["approach_prompt"] = str(profile.get("approach_prompt", ""))
        profile["success_responses"] = normalize_string_array(profile.get("success_responses", []))
        profile["locked_copy"] = str(profile.get("locked_copy", ""))
        profiles.append(profile)
    return profiles


def normalize_stage_speech_bubbles(value) -> dict:
    if not isinstance(value, dict):
        value = {}
    return {stage: normalize_string_array(value.get(stage, [])) for stage in MEETING_STAGES}


def normalize_contacts(value) -> list[dict]:
    if not isinstance(value, list):
        return []
    contacts: list[dict] = []
    for row in value:
        if not isinstance(row, dict):
            continue
        contact = copy.deepcopy(row)
        contact["id"] = str(contact.get("id", "")).strip()
        contact["display_name"] = str(contact.get("display_name", "")).strip()
        contact["role"] = str(contact.get("role", "")).strip()
        contact["sector_ids"] = normalize_string_array(contact.get("sector_ids", []))
        contact["categories"] = normalize_string_array(contact.get("categories", []))
        contact["recognition_required"] = int(contact.get("recognition_required", 0) or 0)
        contact["base_relationship"] = int(contact.get("base_relationship", 25) or 25)
        contact["reliability"] = clamp_float(contact.get("reliability", 0.5), 0.0, 1.0)
        contact["tone"] = str(contact.get("tone", "mixed")).strip() or "mixed"
        contact["intro"] = str(contact.get("intro", ""))
        contact["affiliation_type"] = str(contact.get("affiliation_type", "floater")).strip() or "floater"
        if contact["affiliation_type"] == "insider_template":
            contact["affiliation_role"] = str(contact.get("affiliation_role", "")).strip()
        elif "affiliation_role" in contact:
            contact.pop("affiliation_role", None)
        contacts.append(contact)
    return contacts


def normalize_string_array(value) -> list[str]:
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        return [line.strip() for line in value.splitlines() if line.strip()]
    return []


def normalize_pool_map(value) -> dict:
    if not isinstance(value, dict):
        return {}
    return {str(key).strip(): normalize_string_array(row) for key, row in value.items() if str(key).strip()}


def normalize_string_map(value) -> dict:
    if not isinstance(value, dict):
        return {}
    return {str(key).strip(): str(row) for key, row in value.items() if str(key).strip()}


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

    sector_ids = load_sector_ids()
    validate_globals(catalog, errors)
    validate_person_names(catalog.get("person_name_pools", {}), errors, warnings)
    validate_meeting_profiles(catalog.get("meeting_lead_profiles", []), errors, warnings)
    validate_contacts(catalog.get("contacts", []), sector_ids, errors, warnings)
    validate_tip_templates(catalog.get("tip_templates", {}), errors, warnings)
    validate_request_templates(catalog.get("request_templates", {}), errors, warnings)
    return {"valid": len(errors) == 0, "errors": errors, "warnings": warnings}


def validate_globals(catalog: dict, errors: list[str]) -> None:
    if int(catalog.get("base_contact_cap", 0)) < 1:
        errors.append("base_contact_cap must be at least 1.")
    relationship_default = int(catalog.get("relationship_default", -1))
    if relationship_default < 0 or relationship_default > 100:
        errors.append("relationship_default must be between 0 and 100.")


def validate_person_names(pools: dict, errors: list[str], warnings: list[str]) -> None:
    for key in ["first_names", "family_names"]:
        rows = pools.get(key, [])
        if not isinstance(rows, list) or not rows:
            errors.append(f"person_name_pools.{key} must be a non-empty array.")
        elif len(rows) < 10:
            warnings.append(f"person_name_pools.{key} has fewer than 10 names; generation variety may feel thin.")


def validate_meeting_profiles(profiles: list[dict], errors: list[str], warnings: list[str]) -> None:
    if len(profiles) < 4:
        errors.append("meeting_lead_profiles must include at least four reusable RUPSLB lead profiles.")
    seen_ids: set[str] = set()
    for index, profile in enumerate(profiles):
        profile_id = str(profile.get("id", "")).strip()
        label = profile_id or f"meeting_lead_profiles[{index}]"
        if not profile_id:
            errors.append(f"{label}: id is required.")
        elif profile_id in seen_ids:
            errors.append(f"{label}: id must be unique.")
        seen_ids.add(profile_id)
        for field in ["tier", "role_label", "approach_prompt", "locked_copy"]:
            if not str(profile.get(field, "")).strip():
                errors.append(f"{label}: {field} is required.")
        recognition = int(profile.get("recognition_required", 0))
        if recognition < 0 or recognition > 100:
            errors.append(f"{label}: recognition_required must be between 0 and 100.")
        if not profile.get("category_ids", []):
            errors.append(f"{label}: category_ids must contain at least one category.")
        validate_template_pool(profile.get("speech_bubbles", []), f"{label}.speech_bubbles", errors, warnings)
        validate_template_pool(profile.get("success_responses", []), f"{label}.success_responses", errors, warnings)
        stage_bubbles = profile.get("stage_speech_bubbles", {})
        if not isinstance(stage_bubbles, dict):
            errors.append(f"{label}: stage_speech_bubbles must be an object.")
            continue
        for stage in MEETING_STAGES:
            validate_template_pool(stage_bubbles.get(stage, []), f"{label}.stage_speech_bubbles.{stage}", errors, warnings)


def validate_contacts(contacts: list[dict], sector_ids: set[str], errors: list[str], warnings: list[str]) -> None:
    if not contacts:
        errors.append("contacts must contain at least one contact.")
        return
    seen_ids: set[str] = set()
    insider_roles: set[str] = set()
    for index, contact in enumerate(contacts):
        contact_id = str(contact.get("id", "")).strip()
        label = contact_id or f"contacts[{index}]"
        if not contact_id:
            errors.append(f"{label}: id is required.")
        elif contact_id in seen_ids:
            errors.append(f"{label}: contact id must be unique.")
        seen_ids.add(contact_id)
        for field in ["display_name", "role", "intro"]:
            if not str(contact.get(field, "")).strip():
                errors.append(f"{label}: {field} is required.")
        affiliation_type = str(contact.get("affiliation_type", "")).strip()
        if affiliation_type not in AFFILIATION_TYPES:
            errors.append(f"{label}: affiliation_type must be one of {', '.join(AFFILIATION_TYPES)}.")
        if affiliation_type == "insider_template":
            role = str(contact.get("affiliation_role", "")).strip()
            if role not in INSIDER_ROLES:
                errors.append(f"{label}: insider_template affiliation_role must be ceo, cfo, or commissioner.")
            else:
                insider_roles.add(role)
        elif "affiliation_role" in contact:
            errors.append(f"{label}: floater contacts must not define affiliation_role.")
        if not contact.get("sector_ids", []):
            warnings.append(f"{label}: sector_ids is empty; discovery matching may be weak.")
        for sector_id in contact.get("sector_ids", []):
            if sector_ids and sector_id not in sector_ids:
                errors.append(f"{label}: unknown sector id '{sector_id}'.")
        if not contact.get("categories", []):
            warnings.append(f"{label}: categories is empty; discovery matching may be weak.")
        recognition = int(contact.get("recognition_required", 0))
        if recognition < 0 or recognition > 100:
            errors.append(f"{label}: recognition_required must be between 0 and 100.")
        relationship = int(contact.get("base_relationship", 0))
        if relationship < 0 or relationship > 100:
            errors.append(f"{label}: base_relationship must be between 0 and 100.")
        reliability = float(contact.get("reliability", 0.0))
        if reliability < 0.0 or reliability > 1.0:
            errors.append(f"{label}: reliability must be between 0 and 1.")
        tone = str(contact.get("tone", "")).strip()
        if tone not in TONE_VALUES:
            warnings.append(f"{label}: tone '{tone}' is outside the usual positive/negative/mixed set.")
    for role in INSIDER_ROLES:
        if role not in insider_roles:
            errors.append(f"contacts must include at least one insider_template with affiliation_role '{role}'.")


def validate_tip_templates(templates: dict, errors: list[str], warnings: list[str]) -> None:
    for tone in TONE_VALUES:
        validate_template_pool(templates.get(tone, []), f"tip_templates.{tone}", errors, warnings)


def validate_request_templates(templates: dict, errors: list[str], warnings: list[str]) -> None:
    if not isinstance(templates, dict) or not templates:
        errors.append("request_templates must be a non-empty object.")
        return
    for tone in TONE_VALUES:
        text = str(templates.get(tone, "")).strip()
        if not text:
            errors.append(f"request_templates.{tone} is required.")
        validate_template_tokens([text], f"request_templates.{tone}", warnings)


def validate_template_pool(pool, label: str, errors: list[str], warnings: list[str]) -> None:
    if not isinstance(pool, list):
        errors.append(f"{label} must be an array.")
        return
    clean_pool = [str(row).strip() for row in pool if str(row).strip()]
    if not clean_pool:
        errors.append(f"{label} needs at least one non-empty line.")
    elif len(clean_pool) == 1:
        warnings.append(f"{label} has only one line; add variants when possible.")
    validate_template_tokens(clean_pool, label, warnings)


def validate_template_tokens(lines: list[str], label: str, warnings: list[str]) -> None:
    for line_index, line in enumerate(lines):
        for token in re.findall(r"\{([a-zA-Z0-9_]+)\}", line):
            if token not in TEMPLATE_TOKENS:
                warnings.append(f"{label}[{line_index}] uses unknown template token {{{token}}}.")


class NetworkEditorHandler(BaseHTTPRequestHandler):
    server_version = "NetworkEditor/1.0"

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
        elif isinstance(payload, dict):
            source = {"schema_version": 1, "catalog": copy.deepcopy(payload)}
        else:
            source = load_source()
        source["schema_version"] = int(source.get("schema_version", 1))
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
        print("[network-editor] " + format % args)


def run_server(host: str, port: int) -> None:
    server = ThreadingHTTPServer((host, port), NetworkEditorHandler)
    print(f"Network editor running at http://{host}:{port}")
    print("Press Ctrl+C to stop.")
    server.serve_forever()


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Dev-only Network / Contact content editor")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8768)
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
