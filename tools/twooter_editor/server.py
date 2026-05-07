#!/usr/bin/env python3
"""Dev-only Twooter content editor server.

Uses only Python stdlib. The editable source lives next to this file and exports
to the Godot runtime catalog at data/social/twooter_feed_data.json.
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
SOURCE_PATH = TOOL_DIR / "twooter_source.json"
STATIC_DIR = TOOL_DIR / "static"
RUNTIME_PATH = PROJECT_ROOT / "data" / "social" / "twooter_feed_data.json"

REQUIRED_TOP_LEVEL_KEYS = [
    "prototype_default_access_tier",
    "post_limit",
    "tier_labels",
    "accounts",
    "voice_templates",
    "thread_templates",
    "continuity_templates",
    "fallback_templates",
    "fallback_posts",
]
REQUIRED_TIER_LABELS = ["1", "2", "3", "4"]
REQUIRED_FALLBACK_KEYS = ["all"]
KNOWN_TEMPLATE_TOKENS = {
    "target_ticker",
    "target_company_name",
    "provider_label",
    "sector_name",
    "person_name",
    "scope",
    "description",
    "tone",
    "category",
    "public_topic_label",
    "public_confidence_label",
    "public_continuity_phrase",
    "continuity_phrase",
    "public_context_hint",
    "market_change",
    "advancers",
    "decliners",
    "biggest_winner",
    "biggest_loser",
}


def read_json(path: Path):
    with path.open("r", encoding="utf-8") as file:
        return json.load(file)


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(payload, ensure_ascii=False, indent=2)
    path.write_text(encoded + "\n", encoding="utf-8")


def import_runtime_source() -> dict:
    catalog = read_json(RUNTIME_PATH)
    return {
        "schema_version": 1,
        "catalog": normalize_catalog_for_source(catalog),
        "notes": "Imported from data/social/twooter_feed_data.json.",
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
    catalog["prototype_default_access_tier"] = int(catalog.get("prototype_default_access_tier", 1) or 1)
    catalog["post_limit"] = int(catalog.get("post_limit", 18) or 18)
    catalog["tier_labels"] = normalize_string_map(catalog.get("tier_labels", {}))
    catalog["accounts"] = normalize_accounts(catalog.get("accounts", []))
    catalog["voice_templates"] = normalize_nested_pool_map(catalog.get("voice_templates", {}))
    catalog["thread_templates"] = normalize_nested_pool_map(catalog.get("thread_templates", {}))
    catalog["continuity_templates"] = normalize_pool_map(catalog.get("continuity_templates", {}))
    catalog["fallback_templates"] = normalize_pool_map(catalog.get("fallback_templates", {}))
    catalog["fallback_posts"] = normalize_pool_map(catalog.get("fallback_posts", {}))
    return catalog


def normalize_accounts(value) -> list[dict]:
    if not isinstance(value, list):
        return []
    accounts: list[dict] = []
    for row in value:
        if not isinstance(row, dict):
            continue
        account = copy.deepcopy(row)
        account["id"] = str(account.get("id", "")).strip()
        account["display_name"] = str(account.get("display_name", "")).strip()
        account["handle"] = str(account.get("handle", "")).strip()
        account["tier"] = int(account.get("tier", 1) or 1)
        account["verified"] = bool(account.get("verified", False))
        account["voice"] = str(account.get("voice", "")).strip()
        if "thread_preference" in account:
            account["thread_preference"] = bool(account.get("thread_preference", False))
        if "person_id" in account:
            account["person_id"] = str(account.get("person_id", "")).strip()
        accounts.append(account)
    return accounts


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


def export_runtime_catalog(source: dict) -> dict:
    return normalize_catalog_for_source(source.get("catalog", {}))


def validate_source(source: dict) -> dict:
    errors: list[str] = []
    warnings: list[str] = []
    catalog = normalize_catalog_for_source(source.get("catalog", {}))
    for key in REQUIRED_TOP_LEVEL_KEYS:
        if key not in catalog:
            errors.append(f"Missing top-level key: {key}.")

    validate_tier_labels(catalog.get("tier_labels", {}), errors)
    voice_ids = set(catalog.get("voice_templates", {}).keys())
    thread_voice_ids = set(catalog.get("thread_templates", {}).keys())
    validate_accounts(catalog.get("accounts", []), voice_ids, thread_voice_ids, errors, warnings)
    validate_nested_pool_map(catalog.get("voice_templates", {}), "voice_templates", errors, warnings)
    validate_nested_pool_map(catalog.get("thread_templates", {}), "thread_templates", errors, warnings, allow_empty=True)
    validate_pool_map(catalog.get("continuity_templates", {}), "continuity_templates", errors, warnings)
    validate_pool_map(catalog.get("fallback_templates", {}), "fallback_templates", errors, warnings)
    validate_pool_map(catalog.get("fallback_posts", {}), "fallback_posts", errors, warnings)

    for key in REQUIRED_FALLBACK_KEYS:
        if key not in catalog.get("fallback_posts", {}):
            errors.append(f"fallback_posts.{key} is required.")
        if key not in catalog.get("fallback_templates", {}):
            errors.append(f"fallback_templates.{key} is required.")
    if "fallback" not in catalog.get("continuity_templates", {}):
        errors.append("continuity_templates.fallback is required.")

    default_tier = int(catalog.get("prototype_default_access_tier", 0))
    if default_tier < 1 or default_tier > 4:
        errors.append("prototype_default_access_tier must be between 1 and 4.")
    if int(catalog.get("post_limit", 0)) < 1:
        errors.append("post_limit must be at least 1.")

    return {"valid": len(errors) == 0, "errors": errors, "warnings": warnings}


def validate_tier_labels(tier_labels: dict, errors: list[str]) -> None:
    if not isinstance(tier_labels, dict) or not tier_labels:
        errors.append("tier_labels must be a non-empty object.")
        return
    for tier in REQUIRED_TIER_LABELS:
        if not str(tier_labels.get(tier, "")).strip():
            errors.append(f"tier_labels.{tier} is required.")


def validate_accounts(accounts: list[dict], voice_ids: set[str], thread_voice_ids: set[str], errors: list[str], warnings: list[str]) -> None:
    if not accounts:
        errors.append("accounts must contain at least one account.")
        return
    seen_ids: set[str] = set()
    seen_handles: set[str] = set()
    for index, account in enumerate(accounts):
        account_id = str(account.get("id", "")).strip()
        label = account_id or f"accounts[{index}]"
        if not account_id:
            errors.append(f"{label}: id is required.")
        elif account_id in seen_ids:
            errors.append(f"{label}: account id must be unique.")
        seen_ids.add(account_id)
        if not str(account.get("display_name", "")).strip():
            errors.append(f"{label}: display_name is required.")
        handle = str(account.get("handle", "")).strip()
        if not handle:
            errors.append(f"{label}: handle is required.")
        elif not handle.startswith("@"):
            warnings.append(f"{label}: handle should start with @.")
        elif handle.lower() in seen_handles:
            errors.append(f"{label}: handle must be unique.")
        seen_handles.add(handle.lower())
        tier = int(account.get("tier", 0))
        if tier < 1 or tier > 4:
            errors.append(f"{label}: tier must be between 1 and 4.")
        voice = str(account.get("voice", "")).strip()
        if not voice:
            errors.append(f"{label}: voice is required.")
        elif voice not in voice_ids:
            errors.append(f"{label}: voice '{voice}' does not exist in voice_templates.")
        if bool(account.get("thread_preference", False)) and voice not in thread_voice_ids:
            warnings.append(f"{label}: thread_preference is enabled but no thread_templates entry exists for voice '{voice}'.")


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


def validate_nested_pool_map(nested_map: dict, label: str, errors: list[str], warnings: list[str], allow_empty: bool = False) -> None:
    if not isinstance(nested_map, dict) or not nested_map:
        if not allow_empty:
            errors.append(f"{label} must be a non-empty object.")
        return
    for group_key, group in nested_map.items():
        group_label = f"{label}.{group_key}"
        if not isinstance(group, dict) or not group:
            errors.append(f"{group_label} must be a non-empty object.")
            continue
        validate_pool_map(group, group_label, errors, warnings)


def validate_template_tokens(lines: list[str], label: str, warnings: list[str]) -> None:
    for line_index, line in enumerate(lines):
        for token in re.findall(r"\{([a-zA-Z0-9_]+)\}", line):
            if token not in KNOWN_TEMPLATE_TOKENS:
                warnings.append(f"{label}[{line_index}] uses unknown template token {{{token}}}.")


class TwooterEditorHandler(BaseHTTPRequestHandler):
    server_version = "TwooterEditor/1.0"

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
        print("[twooter-editor] " + format % args)


def run_server(host: str, port: int) -> None:
    server = ThreadingHTTPServer((host, port), TwooterEditorHandler)
    print(f"Twooter editor running at http://{host}:{port}")
    print("Press Ctrl+C to stop.")
    server.serve_forever()


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Dev-only Twooter content editor")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8767)
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
