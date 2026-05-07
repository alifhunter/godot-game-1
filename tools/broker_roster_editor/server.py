#!/usr/bin/env python3
"""Dev-only Broker Roster editor server.

Uses only Python stdlib. The editable source lives next to this file and exports
to the Godot runtime roster at data/brokers/broker_roster.json.
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
SOURCE_PATH = TOOL_DIR / "broker_roster_source.json"
STATIC_DIR = TOOL_DIR / "static"
RUNTIME_PATH = PROJECT_ROOT / "data" / "brokers" / "broker_roster.json"

BROKER_TYPES = ["foreign", "retail", "institution", "bandar", "zombie"]
PLAYER_BROKER_CODE = "XL"
PLAYER_BROKER_NAME = "PT. Sobat Loser"
KNOWN_PERSONALITY_TAGS = [
    "robotic",
    "trading",
    "quality_buyer",
    "retail_facing",
    "dumb_money",
    "market_maker",
    "smart_money",
    "quiet_accumulator",
    "follow_the_wave",
    "speculative",
    "distributor",
    "evil_to_retail",
    "defensive",
    "government",
    "retail",
    "player",
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
        "roster": normalize_roster(read_json(RUNTIME_PATH)),
        "notes": "Imported from data/brokers/broker_roster.json.",
    }


def load_source() -> dict:
    if not SOURCE_PATH.exists():
        return import_runtime_source()
    try:
        source = read_json(SOURCE_PATH)
    except (json.JSONDecodeError, OSError):
        return import_runtime_source()
    if isinstance(source, list):
        source = {"schema_version": 1, "roster": source}
    if not isinstance(source, dict) or not isinstance(source.get("roster"), list):
        return import_runtime_source()
    source = copy.deepcopy(source)
    source["schema_version"] = int(source.get("schema_version", 1) or 1)
    source["roster"] = normalize_roster(source.get("roster", []))
    source["notes"] = str(source.get("notes", ""))
    return source


def normalize_roster(value) -> list[dict]:
    if not isinstance(value, list):
        return []
    roster: list[dict] = []
    for row in value:
        if not isinstance(row, dict):
            continue
        broker = copy.deepcopy(row)
        broker["code"] = normalize_code(broker.get("code", ""))
        broker["company_name"] = str(broker.get("company_name", "")).strip()
        broker["broker_type"] = str(broker.get("broker_type", "retail")).strip() or "retail"
        broker["personality_tags"] = normalize_string_array(broker.get("personality_tags", []))
        roster.append(broker)
    return roster


def normalize_code(value) -> str:
    return re.sub(r"[^A-Za-z0-9]", "", str(value)).upper()[:4]


def normalize_string_array(value) -> list[str]:
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        return [line.strip() for line in value.splitlines() if line.strip()]
    return []


def export_runtime_roster(source: dict) -> list[dict]:
    return normalize_roster(source.get("roster", []))


def validate_source(source: dict) -> dict:
    errors: list[str] = []
    warnings: list[str] = []
    if not isinstance(source, dict):
        return {"valid": False, "errors": ["Source must be an object with a roster array."], "warnings": []}
    roster = normalize_roster(source.get("roster", []))
    validate_roster(roster, errors, warnings)
    return {"valid": len(errors) == 0, "errors": errors, "warnings": warnings}


def validate_roster(roster: list[dict], errors: list[str], warnings: list[str]) -> None:
    if not roster:
        errors.append("roster must contain at least one broker.")
        return
    if len(roster) < 10:
        warnings.append("roster has fewer than 10 brokers; the top broker table can feel repetitive.")

    seen_codes: set[str] = set()
    type_counts: dict[str, int] = {broker_type: 0 for broker_type in BROKER_TYPES}
    tag_counts: dict[str, int] = {}
    player_broker = None
    for index, broker in enumerate(roster):
        code = str(broker.get("code", "")).strip()
        label = code or f"roster[{index}]"
        if not code:
            errors.append(f"{label}: code is required.")
        elif not re.fullmatch(r"[A-Z0-9]{2}", code):
            errors.append(f"{label}: code must be exactly two uppercase letters/numbers.")
        elif code in seen_codes:
            errors.append(f"{label}: broker code must be unique.")
        seen_codes.add(code)

        company_name = str(broker.get("company_name", "")).strip()
        if not company_name:
            errors.append(f"{label}: company_name is required.")
        broker_type = str(broker.get("broker_type", "")).strip()
        if broker_type not in BROKER_TYPES:
            errors.append(f"{label}: broker_type must be one of {', '.join(BROKER_TYPES)}.")
        else:
            type_counts[broker_type] += 1
        tags = broker.get("personality_tags", [])
        if not isinstance(tags, list) or not tags:
            errors.append(f"{label}: personality_tags must contain at least one tag.")
            tags = []
        clean_tags = [str(tag).strip() for tag in tags if str(tag).strip()]
        if len(clean_tags) != len(set(clean_tags)):
            warnings.append(f"{label}: personality_tags contains duplicate tags.")
        for tag in clean_tags:
            tag_counts[tag] = tag_counts.get(tag, 0) + 1
            if tag not in KNOWN_PERSONALITY_TAGS:
                warnings.append(f"{label}: unknown personality tag '{tag}' is not read by BrokerFlowSystem.")
        if code == PLAYER_BROKER_CODE:
            player_broker = broker

    for broker_type, count in type_counts.items():
        if count <= 0:
            errors.append(f"roster must include at least one '{broker_type}' broker for broker pressure totals.")
    if player_broker is None:
        errors.append(f"roster must include player broker {PLAYER_BROKER_CODE}.")
    else:
        if str(player_broker.get("company_name", "")).strip() != PLAYER_BROKER_NAME:
            warnings.append(f"{PLAYER_BROKER_CODE}: company_name differs from RunState.PLAYER_BROKER_NAME.")
        if str(player_broker.get("broker_type", "")).strip() != "retail":
            warnings.append(f"{PLAYER_BROKER_CODE}: player broker is expected to stay broker_type 'retail'.")

    behavior_requirements = {
        "smart_money or quiet_accumulator": ["smart_money", "quiet_accumulator"],
        "dumb_money": ["dumb_money"],
        "market_maker": ["market_maker"],
        "distributor or evil_to_retail": ["distributor", "evil_to_retail"],
        "quality_buyer or defensive": ["quality_buyer", "defensive"],
    }
    for label, tags in behavior_requirements.items():
        if not any(tag_counts.get(tag, 0) > 0 for tag in tags):
            warnings.append(f"roster has no {label} tag coverage; broker-flow behavior variety may be thin.")


class BrokerRosterEditorHandler(BaseHTTPRequestHandler):
    server_version = "BrokerRosterEditor/1.0"

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
            write_json(RUNTIME_PATH, export_runtime_roster(source))
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
        if isinstance(payload, dict) and isinstance(payload.get("roster"), list):
            source = copy.deepcopy(payload)
        elif isinstance(payload, list):
            source = {"schema_version": 1, "roster": copy.deepcopy(payload)}
        else:
            source = load_source()
        source["schema_version"] = int(source.get("schema_version", 1) or 1)
        source["roster"] = normalize_roster(source.get("roster", []))
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
        print("[broker-roster-editor] " + format % args)


def run_server(host: str, port: int) -> None:
    server = ThreadingHTTPServer((host, port), BrokerRosterEditorHandler)
    print(f"Broker Roster editor running at http://{host}:{port}")
    print("Press Ctrl+C to stop.")
    server.serve_forever()


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Dev-only Broker Roster content editor")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8770)
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
        runtime_roster = export_runtime_roster(source)
        if args.dry_run:
            encoded = json.dumps(runtime_roster, ensure_ascii=False, indent=2)
            print(f"Dry-run export OK: {len(encoded)} bytes")
        else:
            write_json(SOURCE_PATH, source)
            write_json(RUNTIME_PATH, runtime_roster)
            print(f"Exported {RUNTIME_PATH}")
        if validation["warnings"]:
            print(json.dumps({"warnings": validation["warnings"]}, ensure_ascii=False, indent=2))
        return 0

    run_server(args.host, args.port)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
