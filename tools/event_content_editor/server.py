#!/usr/bin/env python3
"""Dev-only Event Content editor server.

Uses only Python stdlib. The editable source lives next to this file and exports
to the Godot runtime event definitions at data/events/events.json.
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
SOURCE_PATH = TOOL_DIR / "event_content_source.json"
STATIC_DIR = TOOL_DIR / "static"
RUNTIME_PATH = PROJECT_ROOT / "data" / "events" / "events.json"
SECTORS_PATH = PROJECT_ROOT / "data" / "sectors" / "sectors.json"

SCOPES = ["market", "sector", "company"]
EVENT_FAMILIES = ["market", "company", "person", "special", "corporate_action", "index_review"]
TONES = ["positive", "negative", "mixed", "neutral"]
BROKER_BIASES = ["foreign", "retail", "institution", "foreign_institution", "bandar", "zombie", "balanced"]
SHOCK_APPLY_BIAS_SIGNS = ["all", "positive", "negative"]
SHOCK_LIMIT_SIDES = ["upper", "lower"]
SHOCK_POST_SHOCK_MODES = ["", "sideways"]
REQUIRED_EVENT_IDS = [
    "sector_tailwind",
    "sector_headwind",
    "risk_off_headline",
    "earnings_beat",
    "earnings_miss",
    "strategic_acquisition",
    "integration_overhang",
    "product_launch",
    "product_recall",
    "management_upgrade",
    "management_exit",
    "trump_tariff_barrage",
    "trump_deal_optimism",
    "musk_ai_hype",
    "musk_meme_pump",
    "musk_controversy_spiral",
    "covid_wave",
    "geopolitical_turmoil",
    "commodity_price_shock",
]
CORPORATE_EVENT_IDS = ["cash_dividend", "stock_dividend", "private_placement"]
OPTIONAL_INT_FIELDS = ["duration_days_min", "duration_days_max", "min_year", "max_year", "min_month", "max_month"]
OPTIONAL_FLOAT_FIELDS = ["market_bias_shift", "volatility_multiplier"]
BASE_FIELD_ORDER = [
    "id",
    "scope",
    "event_family",
    "category",
    "tone",
    "duration_days",
    "duration_days_min",
    "duration_days_max",
    "once_per_run",
    "min_year",
    "max_year",
    "min_month",
    "max_month",
    "person_id",
    "person_name",
    "sentiment_shift",
    "market_bias_shift",
    "volatility_multiplier",
    "broker_bias",
    "shock_profile",
    "sector_biases",
    "headline_template",
    "headline_detail_template",
    "description",
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
        "events": normalize_events(read_json(RUNTIME_PATH)),
        "notes": "Imported from data/events/events.json.",
    }


def load_source() -> dict:
    if not SOURCE_PATH.exists():
        return import_runtime_source()
    try:
        source = read_json(SOURCE_PATH)
    except (json.JSONDecodeError, OSError):
        return import_runtime_source()
    if isinstance(source, list):
        source = {"schema_version": 1, "events": source}
    if not isinstance(source, dict) or not isinstance(source.get("events"), list):
        return import_runtime_source()
    source = copy.deepcopy(source)
    source["schema_version"] = int(source.get("schema_version", 1) or 1)
    source["events"] = normalize_events(source.get("events", []))
    source["notes"] = str(source.get("notes", ""))
    if not source["events"]:
        return import_runtime_source()
    return source


def normalize_events(value) -> list[dict]:
    if not isinstance(value, list):
        return []
    events: list[dict] = []
    for row in value:
        if not isinstance(row, dict):
            continue
        event = normalize_event(row)
        if event.get("id"):
            events.append(event)
    return events


def normalize_event(row: dict) -> dict:
    raw = copy.deepcopy(row)
    event_id = slug_id(raw.get("id", ""))
    event_family = str(raw.get("event_family", "market")).strip() or "market"
    event = {
        "id": event_id,
        "scope": str(raw.get("scope", "market")).strip() or "market",
        "event_family": event_family,
        "category": slug_id(raw.get("category", event_family)) or event_family,
        "tone": str(raw.get("tone", "mixed")).strip() or "mixed",
        "duration_days": max(normalize_int(raw.get("duration_days", 1), 1), 0),
        "sentiment_shift": normalize_float(raw.get("sentiment_shift", 0.0), 0.0),
        "broker_bias": str(raw.get("broker_bias", "balanced")).strip() or "balanced",
        "description": str(raw.get("description", "")).strip(),
    }
    if event_family == "person" or raw.get("person_id") is not None or raw.get("person_name") is not None:
        event["person_id"] = slug_id(raw.get("person_id", ""))
        event["person_name"] = str(raw.get("person_name", "")).strip()
    for field in OPTIONAL_INT_FIELDS:
        if field in raw:
            event[field] = max(normalize_int(raw.get(field, 0), 0), 0)
    if "once_per_run" in raw:
        event["once_per_run"] = normalize_bool(raw.get("once_per_run", False))
    for field in OPTIONAL_FLOAT_FIELDS:
        if field in raw:
            event[field] = normalize_float(raw.get(field, 0.0), 0.0)
    if "shock_profile" in raw:
        event["shock_profile"] = normalize_shock_profile(raw.get("shock_profile", {}))
    if "sector_biases" in raw:
        event["sector_biases"] = normalize_sector_biases(raw.get("sector_biases", {}))
    if "headline_template" in raw or event_family == "special":
        event["headline_template"] = str(raw.get("headline_template", "")).strip()
    if "headline_detail_template" in raw or event_family == "special":
        event["headline_detail_template"] = str(raw.get("headline_detail_template", "")).strip()

    for key, value in raw.items():
        if key not in event:
            event[str(key)] = value
    return order_event_fields(event)


def order_event_fields(event: dict) -> dict:
    ordered = {}
    for field in BASE_FIELD_ORDER:
        if field in event:
            ordered[field] = event[field]
    for key, value in event.items():
        if key not in ordered:
            ordered[key] = value
    return ordered


def normalize_shock_profile(value) -> dict:
    if not isinstance(value, dict):
        return {}
    profile = copy.deepcopy(value)
    if "apply_bias_sign" in profile:
        profile["apply_bias_sign"] = str(profile.get("apply_bias_sign", "all")).strip() or "all"
    if "limit_side" in profile:
        profile["limit_side"] = str(profile.get("limit_side", "lower")).strip() or "lower"
    if "post_shock_mode" in profile:
        profile["post_shock_mode"] = str(profile.get("post_shock_mode", "")).strip()
    for field in ["shock_days"]:
        if field in profile:
            profile[field] = max(normalize_int(profile.get(field, 0), 0), 0)
    for field in ["limit_ratio", "sideways_band_ratio"]:
        if field in profile:
            profile[field] = normalize_float(profile.get(field, 0.0), 0.0)
    return profile


def normalize_sector_biases(value) -> dict:
    if not isinstance(value, dict):
        return {}
    return {str(key).strip(): normalize_float(row, 0.0) for key, row in value.items() if str(key).strip()}


def normalize_bool(value) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.strip().lower() in ["true", "1", "yes", "y", "on"]
    return bool(value)


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


def export_runtime_events(source: dict) -> list[dict]:
    return normalize_events(source.get("events", []))


def load_sector_ids() -> set[str]:
    try:
        sectors = read_json(SECTORS_PATH)
    except (json.JSONDecodeError, OSError):
        return set()
    if not isinstance(sectors, list):
        return set()
    return {str(row.get("id", "")).strip() for row in sectors if isinstance(row, dict) and str(row.get("id", "")).strip()}


def reference_data() -> dict:
    sector_ids = sorted(load_sector_ids())
    return {
        "scopes": SCOPES,
        "event_families": EVENT_FAMILIES,
        "tones": TONES,
        "broker_biases": BROKER_BIASES,
        "sector_ids": sector_ids,
        "required_event_ids": REQUIRED_EVENT_IDS,
        "corporate_event_ids": CORPORATE_EVENT_IDS,
    }


def validate_source(source: dict) -> dict:
    errors: list[str] = []
    warnings: list[str] = []
    if not isinstance(source, dict):
        return {"valid": False, "errors": ["Source must be an object with an events array."], "warnings": []}
    events = normalize_events(source.get("events", []))
    validate_events(events, load_sector_ids(), errors, warnings)
    return {"valid": len(errors) == 0, "errors": errors, "warnings": warnings}


def validate_events(events: list[dict], sector_ids: set[str], errors: list[str], warnings: list[str]) -> None:
    if not events:
        errors.append("events must contain at least one event definition.")
        return

    seen_ids: set[str] = set()
    events_by_id: dict[str, dict] = {}
    family_counts: dict[str, int] = {}
    for index, event in enumerate(events):
        event_id = str(event.get("id", "")).strip()
        label = event_id or f"events[{index}]"
        if not event_id:
            errors.append(f"{label}: id is required.")
            continue
        if event_id in seen_ids:
            errors.append(f"{label}: event id must be unique.")
        seen_ids.add(event_id)
        events_by_id[event_id] = event
        family = str(event.get("event_family", "")).strip()
        family_counts[family] = family_counts.get(family, 0) + 1
        validate_event(event, sector_ids, errors, warnings)

    for required_id in REQUIRED_EVENT_IDS:
        if required_id not in events_by_id:
            errors.append(f"events must include required runtime event '{required_id}'.")
    for event_id in CORPORATE_EVENT_IDS:
        if event_id not in events_by_id:
            warnings.append(f"events is missing corporate-action event '{event_id}'; generated corporate-action events may lose fallback metadata.")
    for family in ["market", "company", "person", "special"]:
        if family_counts.get(family, 0) <= 0:
            errors.append(f"events must include at least one '{family}' event family.")


def validate_event(event: dict, sector_ids: set[str], errors: list[str], warnings: list[str]) -> None:
    event_id = str(event.get("id", "")).strip()
    scope = str(event.get("scope", "")).strip()
    family = str(event.get("event_family", "")).strip()
    tone = str(event.get("tone", "")).strip()
    if scope not in SCOPES:
        errors.append(f"{event_id}: scope must be one of {', '.join(SCOPES)}.")
    if family not in EVENT_FAMILIES:
        errors.append(f"{event_id}: event_family must be one of {', '.join(EVENT_FAMILIES)}.")
    if not str(event.get("category", "")).strip():
        errors.append(f"{event_id}: category is required.")
    if tone not in TONES:
        errors.append(f"{event_id}: tone must be one of {', '.join(TONES)}.")
    duration_days = int(event.get("duration_days", 0))
    if duration_days <= 0:
        errors.append(f"{event_id}: duration_days must be positive.")
    validate_duration_window(event, event_id, errors, warnings)
    validate_numeric_effects(event, event_id, errors, warnings)
    broker_bias = str(event.get("broker_bias", "")).strip()
    if broker_bias not in BROKER_BIASES:
        warnings.append(f"{event_id}: broker_bias '{broker_bias}' is not a known broker pressure bucket.")
    if not str(event.get("description", "")).strip():
        errors.append(f"{event_id}: description is required.")
    if family == "person":
        if not str(event.get("person_id", "")).strip():
            errors.append(f"{event_id}: person_id is required for person events.")
        if not str(event.get("person_name", "")).strip():
            errors.append(f"{event_id}: person_name is required for person events.")
    if family == "special":
        validate_special_event(event, sector_ids, event_id, errors, warnings)
    elif "sector_biases" in event and event.get("sector_biases"):
        warnings.append(f"{event_id}: sector_biases only affect active special events.")
    elif "shock_profile" in event and event.get("shock_profile"):
        warnings.append(f"{event_id}: shock_profile only affects active special events.")


def validate_duration_window(event: dict, event_id: str, errors: list[str], warnings: list[str]) -> None:
    has_min = "duration_days_min" in event
    has_max = "duration_days_max" in event
    if has_min != has_max:
        warnings.append(f"{event_id}: duration_days_min and duration_days_max should be edited together.")
    if not has_min and not has_max:
        return
    duration_days = int(event.get("duration_days", 0))
    min_days = int(event.get("duration_days_min", duration_days))
    max_days = int(event.get("duration_days_max", duration_days))
    if min_days <= 0 or max_days <= 0:
        errors.append(f"{event_id}: duration_days_min/max must be positive.")
    if min_days > max_days:
        errors.append(f"{event_id}: duration_days_min must be <= duration_days_max.")
    if duration_days and (duration_days < min_days or duration_days > max_days):
        warnings.append(f"{event_id}: duration_days is outside the min/max window used by special-event randomization.")


def validate_numeric_effects(event: dict, event_id: str, errors: list[str], warnings: list[str]) -> None:
    sentiment_shift = float(event.get("sentiment_shift", 0.0))
    if sentiment_shift < -0.5 or sentiment_shift > 0.5:
        errors.append(f"{event_id}: sentiment_shift should stay between -0.5 and 0.5.")
    elif abs(sentiment_shift) > 0.08:
        warnings.append(f"{event_id}: sentiment_shift is large; this can dominate daily price action.")
    if "market_bias_shift" in event:
        market_bias_shift = float(event.get("market_bias_shift", 0.0))
        if market_bias_shift < -0.2 or market_bias_shift > 0.2:
            errors.append(f"{event_id}: market_bias_shift should stay between -0.2 and 0.2.")
        elif abs(market_bias_shift) > 0.05:
            warnings.append(f"{event_id}: market_bias_shift is larger than the special-event aggregate clamp.")
    if "volatility_multiplier" in event:
        volatility_multiplier = float(event.get("volatility_multiplier", 1.0))
        if volatility_multiplier <= 0:
            errors.append(f"{event_id}: volatility_multiplier must be positive.")
        elif volatility_multiplier > 2.4:
            warnings.append(f"{event_id}: volatility_multiplier exceeds the special-event aggregate clamp.")


def validate_special_event(event: dict, sector_ids: set[str], event_id: str, errors: list[str], warnings: list[str]) -> None:
    for field in ["duration_days_min", "duration_days_max", "market_bias_shift", "volatility_multiplier"]:
        if field not in event:
            errors.append(f"{event_id}: {field} is required for special events.")
    for field in ["headline_template", "headline_detail_template"]:
        if not str(event.get(field, "")).strip():
            errors.append(f"{event_id}: {field} is required for active special-event News/Twooter context.")
    for month_field in ["min_month", "max_month"]:
        if month_field in event:
            month = int(event.get(month_field, 0))
            if month < 1 or month > 12:
                errors.append(f"{event_id}: {month_field} must be between 1 and 12.")
    if "min_year" in event and "max_year" in event and int(event.get("min_year", 0)) > int(event.get("max_year", 0)):
        errors.append(f"{event_id}: min_year must be <= max_year.")
    validate_sector_biases(event.get("sector_biases", {}), sector_ids, event_id, errors, warnings)
    validate_shock_profile(event.get("shock_profile", {}), event_id, errors, warnings)


def validate_sector_biases(value, sector_ids: set[str], event_id: str, errors: list[str], warnings: list[str]) -> None:
    if not isinstance(value, dict) or not value:
        warnings.append(f"{event_id}: sector_biases is empty; this special event will only affect market-level bias.")
        return
    for sector_id, bias in value.items():
        if sector_ids and str(sector_id) not in sector_ids:
            errors.append(f"{event_id}: sector_biases references unknown sector '{sector_id}'.")
        bias_value = float(bias)
        if bias_value < -0.2 or bias_value > 0.2:
            errors.append(f"{event_id}: sector_biases.{sector_id} should stay between -0.2 and 0.2.")
        elif abs(bias_value) > 0.04:
            warnings.append(f"{event_id}: sector_biases.{sector_id} is large for a multi-day market shock.")


def validate_shock_profile(value, event_id: str, errors: list[str], warnings: list[str]) -> None:
    if not isinstance(value, dict) or not value:
        warnings.append(f"{event_id}: shock_profile is empty; no limit-script price behavior will apply.")
        return
    apply_bias_sign = str(value.get("apply_bias_sign", "all"))
    if apply_bias_sign not in SHOCK_APPLY_BIAS_SIGNS:
        errors.append(f"{event_id}: shock_profile.apply_bias_sign must be one of {', '.join(SHOCK_APPLY_BIAS_SIGNS)}.")
    limit_side = str(value.get("limit_side", "lower"))
    if limit_side not in SHOCK_LIMIT_SIDES:
        errors.append(f"{event_id}: shock_profile.limit_side must be one of {', '.join(SHOCK_LIMIT_SIDES)}.")
    if "post_shock_mode" in value and str(value.get("post_shock_mode", "")) not in SHOCK_POST_SHOCK_MODES:
        warnings.append(f"{event_id}: shock_profile.post_shock_mode is not currently handled by MarketSimulator.")
    shock_days = int(value.get("shock_days", 0))
    if shock_days < 0:
        errors.append(f"{event_id}: shock_profile.shock_days must be non-negative.")
    limit_ratio = float(value.get("limit_ratio", 1.0))
    if limit_ratio < 0.0 or limit_ratio > 1.0:
        errors.append(f"{event_id}: shock_profile.limit_ratio must be between 0 and 1.")
    if "sideways_band_ratio" in value:
        band_ratio = float(value.get("sideways_band_ratio", 0.0))
        if band_ratio <= 0.0 or band_ratio > 0.5:
            warnings.append(f"{event_id}: shock_profile.sideways_band_ratio is usually between 0.02 and 0.2.")


class EventContentEditorHandler(BaseHTTPRequestHandler):
    server_version = "EventContentEditor/1.0"

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/api/source":
            self.send_json(load_source())
            return
        if parsed.path == "/api/validate":
            self.send_json(validate_source(load_source()))
            return
        if parsed.path == "/api/reference":
            self.send_json(reference_data())
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
            write_json(RUNTIME_PATH, export_runtime_events(source))
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
        if isinstance(payload, dict) and isinstance(payload.get("events"), list):
            source = copy.deepcopy(payload)
        elif isinstance(payload, list):
            source = {"schema_version": 1, "events": copy.deepcopy(payload)}
        else:
            source = load_source()
        source["schema_version"] = int(source.get("schema_version", 1) or 1)
        source["events"] = normalize_events(source.get("events", []))
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
        print("[event-content-editor] " + format % args)


def run_server(host: str, port: int) -> None:
    server = ThreadingHTTPServer((host, port), EventContentEditorHandler)
    print(f"Event Content editor running at http://{host}:{port}")
    print("Press Ctrl+C to stop.")
    server.serve_forever()


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Dev-only Event Content editor")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8773)
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
        runtime_events = export_runtime_events(source)
        if args.dry_run:
            encoded = json.dumps(runtime_events, ensure_ascii=False, indent=2)
            print(f"Dry-run export OK: {len(encoded)} bytes")
        else:
            write_json(SOURCE_PATH, source)
            write_json(RUNTIME_PATH, runtime_events)
            print(f"Exported {RUNTIME_PATH}")
        if validation["warnings"]:
            print(json.dumps({"warnings": validation["warnings"]}, ensure_ascii=False, indent=2))
        return 0

    run_server(args.host, args.port)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
