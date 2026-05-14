#!/usr/bin/env python3
"""Dev-only Balance / Upgrades editor server.

Uses only Python stdlib. The editable source lives next to this file and exports
to the Godot runtime upgrade catalog at data/upgrades/upgrade_catalog.json.
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
SOURCE_PATH = TOOL_DIR / "balance_upgrades_source.json"
STATIC_DIR = TOOL_DIR / "static"
RUNTIME_PATH = PROJECT_ROOT / "data" / "upgrades" / "upgrade_catalog.json"

REQUIRED_TRACK_IDS = [
    "trading_fee",
    "news_content",
    "chart_indicators",
    "daily_action_points",
]
TIER_KEYS = ["4", "3", "2", "1"]
PAID_TIER_KEYS = ["3", "2", "1"]
KNOWN_INDICATOR_IDS = [
    "sma_3",
    "sma_5",
    "sma_10",
    "sma_20",
    "sma_50",
    "sma_60",
    "sma_100",
    "sma_200",
    "ema_20",
    "rsi_14",
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
        "catalog": normalize_catalog(read_json(RUNTIME_PATH)),
        "notes": "Imported from data/upgrades/upgrade_catalog.json.",
    }


def load_source() -> dict:
    if not SOURCE_PATH.exists():
        return import_runtime_source()
    try:
        source = read_json(SOURCE_PATH)
    except (json.JSONDecodeError, OSError):
        return import_runtime_source()
    if isinstance(source, dict) and isinstance(source.get("tracks"), list):
        source = {"schema_version": 1, "catalog": {"tracks": source.get("tracks", [])}}
    if not isinstance(source, dict):
        return import_runtime_source()
    source = copy.deepcopy(source)
    source["schema_version"] = int(source.get("schema_version", 1) or 1)
    source["catalog"] = normalize_catalog(source.get("catalog", {}))
    source["notes"] = str(source.get("notes", ""))
    if not source["catalog"].get("tracks"):
        return import_runtime_source()
    return source


def normalize_catalog(value) -> dict:
    if isinstance(value, list):
        value = {"tracks": value}
    if not isinstance(value, dict):
        value = {}
    return {
        "tracks": normalize_tracks(value.get("tracks", [])),
    }


def normalize_tracks(value) -> list[dict]:
    if not isinstance(value, list):
        return []
    tracks: list[dict] = []
    for row in value:
        if not isinstance(row, dict):
            continue
        track = copy.deepcopy(row)
        track["id"] = slug_id(track.get("id", ""))
        track["label"] = str(track.get("label", track["id"].replace("_", " ").title())).strip()
        track["description"] = str(track.get("description", "")).strip()
        track["tiers"] = normalize_tiers(track.get("tiers", {}))
        tracks.append(track)
    return tracks


def normalize_tiers(value) -> dict:
    if not isinstance(value, dict):
        return {}
    tiers: dict = {}
    tier_keys = sorted(
        [normalize_tier_key(key) for key in value.keys() if normalize_tier_key(key)],
        key=lambda item: int(item),
        reverse=True,
    )
    for tier_key in tier_keys:
        tier = normalize_tier_data(value.get(tier_key, value.get(int(tier_key), {})))
        tiers[tier_key] = tier
    return tiers


def normalize_tier_data(value) -> dict:
    tier = copy.deepcopy(value) if isinstance(value, dict) else {}
    normalized: dict = {}
    if "cost" in tier:
        normalized["cost"] = normalize_number(tier.get("cost", 0.0), 0.0)
    normalized["effect_label"] = str(tier.get("effect_label", "")).strip()
    if "buy_fee_rate" in tier:
        normalized["buy_fee_rate"] = normalize_float(tier.get("buy_fee_rate", 0.0), 0.0)
    if "sell_fee_rate" in tier:
        normalized["sell_fee_rate"] = normalize_float(tier.get("sell_fee_rate", 0.0), 0.0)
    if "content_level" in tier:
        normalized["content_level"] = normalize_int(tier.get("content_level", 1), 1)
    if "indicator_ids" in tier:
        normalized["indicator_ids"] = normalize_string_array(tier.get("indicator_ids", []))
    if "daily_action_limit" in tier:
        normalized["daily_action_limit"] = normalize_int(tier.get("daily_action_limit", 0), 0)
    for key, value in tier.items():
        if key not in normalized:
            normalized[str(key)] = value
    return normalized


def normalize_tier_key(value) -> str:
    try:
        tier = int(value)
    except (TypeError, ValueError):
        return ""
    if tier < 1 or tier > 99:
        return ""
    return str(tier)


def normalize_string_array(value) -> list[str]:
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        return [line.strip() for line in value.splitlines() if line.strip()]
    return []


def normalize_number(value, fallback: float = 0.0):
    number = normalize_float(value, fallback)
    if float(number).is_integer():
        return int(number)
    return number


def normalize_int(value, fallback: int = 0) -> int:
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return fallback


def normalize_float(value, fallback: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return fallback


def slug_id(value) -> str:
    return re.sub(r"[^a-z0-9_]+", "_", str(value).strip().lower()).strip("_")


def export_runtime_catalog(source: dict) -> dict:
    return normalize_catalog(source.get("catalog", {}))


def validate_source(source: dict) -> dict:
    errors: list[str] = []
    warnings: list[str] = []
    if not isinstance(source, dict):
        return {"valid": False, "errors": ["Source must be an object."], "warnings": []}
    catalog = normalize_catalog(source.get("catalog", {}))
    validate_catalog(catalog, errors, warnings)
    return {"valid": len(errors) == 0, "errors": errors, "warnings": warnings}


def validate_catalog(catalog: dict, errors: list[str], warnings: list[str]) -> None:
    tracks = catalog.get("tracks", [])
    if not isinstance(tracks, list) or not tracks:
        errors.append("catalog.tracks must contain at least one upgrade track.")
        return

    track_by_id: dict[str, dict] = {}
    seen_ids: set[str] = set()
    for index, track in enumerate(tracks):
        if not isinstance(track, dict):
            errors.append(f"catalog.tracks[{index}] must be an object.")
            continue
        track_id = str(track.get("id", "")).strip()
        label = track_id or f"catalog.tracks[{index}]"
        if not track_id:
            errors.append(f"{label}: id is required.")
            continue
        if track_id in seen_ids:
            errors.append(f"{label}: track id must be unique.")
        seen_ids.add(track_id)
        track_by_id[track_id] = track
        validate_track(track, errors, warnings)
        if track_id not in REQUIRED_TRACK_IDS:
            warnings.append(f"{label}: custom upgrade tracks render in the shop, but RunState will not persist purchases until UPGRADE_TRACK_IDS supports this id.")

    for required_id in REQUIRED_TRACK_IDS:
        if required_id not in track_by_id:
            errors.append(f"catalog.tracks must include required track '{required_id}'.")


def validate_track(track: dict, errors: list[str], warnings: list[str]) -> None:
    track_id = str(track.get("id", "")).strip()
    if not str(track.get("label", "")).strip():
        errors.append(f"{track_id}: label is required.")
    if not str(track.get("description", "")).strip():
        warnings.append(f"{track_id}: description is empty.")
    tiers = track.get("tiers", {})
    if not isinstance(tiers, dict):
        errors.append(f"{track_id}: tiers must be an object.")
        return
    for tier_key in TIER_KEYS:
        if tier_key not in tiers:
            errors.append(f"{track_id}: tier {tier_key} is required.")
    for tier_key, tier in tiers.items():
        if normalize_tier_key(tier_key) != str(tier_key):
            warnings.append(f"{track_id}: tier key '{tier_key}' will be ignored by runtime tier logic.")
        if not isinstance(tier, dict):
            errors.append(f"{track_id}.tiers.{tier_key} must be an object.")
            continue
        if not str(tier.get("effect_label", "")).strip():
            errors.append(f"{track_id}.tiers.{tier_key}.effect_label is required.")
        cost = float(tier.get("cost", 0.0))
        if str(tier_key) in PAID_TIER_KEYS and cost <= 0.0:
            errors.append(f"{track_id}.tiers.{tier_key}.cost must be positive so the tier can be purchased.")
        if cost < 0.0:
            errors.append(f"{track_id}.tiers.{tier_key}.cost must be non-negative.")

    validate_cost_curve(track_id, tiers, warnings)
    if track_id == "trading_fee":
        validate_trading_fee_track(tiers, errors, warnings)
    elif track_id == "news_content":
        validate_content_track(track_id, tiers, errors, warnings)
    elif track_id == "chart_indicators":
        validate_chart_track(tiers, errors, warnings)
    elif track_id == "daily_action_points":
        validate_daily_action_track(tiers, errors, warnings)


def validate_cost_curve(track_id: str, tiers: dict, warnings: list[str]) -> None:
    paid_costs = [float(tiers.get(tier_key, {}).get("cost", 0.0)) for tier_key in PAID_TIER_KEYS]
    if paid_costs != sorted(paid_costs):
        warnings.append(f"{track_id}: paid tier costs usually increase from tier 3 to tier 1.")
    if float(tiers.get("4", {}).get("cost", 0.0)) > 0.0:
        warnings.append(f"{track_id}: tier 4 is the default tier; cost is ignored by purchase flow.")


def validate_trading_fee_track(tiers: dict, errors: list[str], warnings: list[str]) -> None:
    buy_rates: list[float] = []
    sell_rates: list[float] = []
    for tier_key in TIER_KEYS:
        tier = tiers.get(tier_key, {})
        for field in ["buy_fee_rate", "sell_fee_rate"]:
            if field not in tier:
                errors.append(f"trading_fee.tiers.{tier_key}.{field} is required; RunState reads this field.")
                continue
            value = float(tier.get(field, 0.0))
            if value <= 0.0 or value > 0.05:
                errors.append(f"trading_fee.tiers.{tier_key}.{field} should be between 0 and 0.05.")
        buy_rates.append(float(tier.get("buy_fee_rate", 0.0)))
        sell_rates.append(float(tier.get("sell_fee_rate", 0.0)))
    if buy_rates != sorted(buy_rates, reverse=True):
        warnings.append("trading_fee: buy_fee_rate should not get worse as tiers improve from 4 to 1.")
    if sell_rates != sorted(sell_rates, reverse=True):
        warnings.append("trading_fee: sell_fee_rate should not get worse as tiers improve from 4 to 1.")


def validate_content_track(track_id: str, tiers: dict, errors: list[str], warnings: list[str]) -> None:
    levels: list[int] = []
    for tier_key in TIER_KEYS:
        tier = tiers.get(tier_key, {})
        if "content_level" not in tier:
            errors.append(f"{track_id}.tiers.{tier_key}.content_level is required.")
            continue
        level = int(tier.get("content_level", 0))
        if level < 1 or level > 4:
            errors.append(f"{track_id}.tiers.{tier_key}.content_level must be between 1 and 4.")
        levels.append(level)
    if levels != sorted(levels):
        warnings.append(f"{track_id}: content_level should increase as tiers improve from 4 to 1.")


def validate_chart_track(tiers: dict, errors: list[str], warnings: list[str]) -> None:
    previous: set[str] = set()
    for tier_key in TIER_KEYS:
        tier = tiers.get(tier_key, {})
        if "indicator_ids" not in tier:
            errors.append(f"chart_indicators.tiers.{tier_key}.indicator_ids is required.")
            continue
        indicators = tier.get("indicator_ids", [])
        if not isinstance(indicators, list):
            errors.append(f"chart_indicators.tiers.{tier_key}.indicator_ids must be an array.")
            indicators = []
        clean = [str(indicator_id).strip() for indicator_id in indicators if str(indicator_id).strip()]
        if len(clean) != len(set(clean)):
            warnings.append(f"chart_indicators.tiers.{tier_key}.indicator_ids contains duplicates.")
        for indicator_id in clean:
            if indicator_id not in KNOWN_INDICATOR_IDS:
                warnings.append(f"chart_indicators.tiers.{tier_key}: unknown indicator id '{indicator_id}'.")
        current = set(clean)
        if not previous.issubset(current):
            warnings.append(f"chart_indicators.tiers.{tier_key}: improved tiers usually keep indicators from lower tiers.")
        previous = current


def validate_daily_action_track(tiers: dict, errors: list[str], warnings: list[str]) -> None:
    limits: list[int] = []
    for tier_key in TIER_KEYS:
        tier = tiers.get(tier_key, {})
        if "daily_action_limit" not in tier:
            errors.append(f"daily_action_points.tiers.{tier_key}.daily_action_limit is required; RunState reads this field.")
            continue
        limit = int(tier.get("daily_action_limit", 0))
        if limit <= 0 or limit > 200:
            errors.append(f"daily_action_points.tiers.{tier_key}.daily_action_limit should be between 1 and 200.")
        limits.append(limit)
    if limits != sorted(limits):
        warnings.append("daily_action_points: daily_action_limit should increase as tiers improve from 4 to 1.")


class BalanceUpgradesEditorHandler(BaseHTTPRequestHandler):
    server_version = "BalanceUpgradesEditor/1.0"

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
        if isinstance(payload, dict):
            source = copy.deepcopy(payload)
        else:
            source = load_source()
        if isinstance(source.get("tracks"), list) and "catalog" not in source:
            source["catalog"] = {"tracks": source.get("tracks", [])}
        source["schema_version"] = int(source.get("schema_version", 1) or 1)
        source["catalog"] = normalize_catalog(source.get("catalog", {}))
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
        print("[balance-upgrades-editor] " + format % args)


def run_server(host: str, port: int) -> None:
    server = ThreadingHTTPServer((host, port), BalanceUpgradesEditorHandler)
    print(f"Balance / Upgrades editor running at http://{host}:{port}")
    print("Press Ctrl+C to stop.")
    server.serve_forever()


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Dev-only Balance / Upgrades content editor")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8772)
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
