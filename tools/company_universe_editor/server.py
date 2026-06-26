#!/usr/bin/env python3
"""Dev-only Company Universe catalog editor server.

Uses only Python stdlib. The editable source lives next to this file after the
first save and exports to the Godot runtime company universe catalog.
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
SOURCE_PATH = TOOL_DIR / "company_universe_source.json"
STATIC_DIR = TOOL_DIR / "static"
RUNTIME_PATH = PROJECT_ROOT / "data" / "companies" / "company_universe_catalog.json"
SECTORS_PATH = PROJECT_ROOT / "data" / "sectors" / "sectors.json"
COMMODITY_PATH = PROJECT_ROOT / "data" / "macro" / "commodity_indicator_catalog.json"

PRICE_TRAIT_FIELDS = [
    "liquidity_profile",
    "volatility_profile",
    "quality_bias",
    "growth_bias",
    "risk_bias",
    "retail_attention_bias",
    "event_sensitivity",
]
NUMERIC_PRICE_TRAIT_FIELDS = [
    "quality_bias",
    "growth_bias",
    "risk_bias",
    "retail_attention_bias",
    "event_sensitivity",
]
ARRAY_FIELDS = ["moat_tags", "relationship_hooks", "story_hooks"]
EXPOSURE_FIELDS = ["commodity_exposures", "macro_exposures"]
HOOK_TYPES = ["supplier", "customer", "partner", "competitor", "borrower", "carrier", "landlord", "lender", "tenant", "acquirer", "target"]
HOOK_VISIBILITIES = ["public", "semi_public", "private"]
LIQUIDITY_PROFILES = ["thin", "mid", "liquid"]
VOLATILITY_PROFILES = ["low", "moderate", "high", "very_high"]
SNAKE_RE = re.compile(r"^[a-z0-9_]+$")
TICKER_RE = re.compile(r"^[A-Z0-9]{3,6}$")


def read_json(path: Path):
    raw = path.read_text(encoding="utf-8-sig")
    return json.loads(raw)


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(payload, ensure_ascii=False, indent=2)
    path.write_text(encoded + "\n", encoding="utf-8")


def import_runtime_source() -> dict:
    source = normalize_source(read_json(RUNTIME_PATH))
    source.setdefault("status", "planning_seed")
    source.setdefault(
        "description",
        "Catalog-backed company universe for top-down market research.",
    )
    source.setdefault("field_notes", default_field_notes())
    return source


def load_source() -> dict:
    if not SOURCE_PATH.exists():
        return import_runtime_source()
    try:
        source = read_json(SOURCE_PATH)
    except (json.JSONDecodeError, OSError):
        return import_runtime_source()
    if not isinstance(source, dict):
        return import_runtime_source()
    source = normalize_source(source)
    if not source.get("companies"):
        return import_runtime_source()
    return source


def normalize_source(value) -> dict:
    if not isinstance(value, dict):
        value = {}
    source = copy.deepcopy(value)
    source["schema_version"] = normalize_int(source.get("schema_version", 1), 1)
    source["status"] = str(source.get("status", "planning_seed")).strip() or "planning_seed"
    source["description"] = str(source.get("description", "")).strip()
    field_notes = source.get("field_notes", {})
    source["field_notes"] = field_notes if isinstance(field_notes, dict) else default_field_notes()
    source["companies"] = normalize_companies(source.get("companies", []))
    return source


def default_field_notes() -> dict:
    return {
        "sector": "Uses existing CompanyGenerator sector ids.",
        "subsector": "More granular business grouping for top-down filters and story targeting.",
        "commodity_exposures": "Signed sensitivity where positive benefits from higher commodity prices and negative is input-cost pressure.",
        "macro_exposures": "Signed sensitivity to macro drivers where positive benefits from stronger driver values.",
        "price_traits": "Normalized hints for price-engine integration.",
        "relationship_hooks": "Potential graph edges for supplier/customer/partner/competitor/acquirer logic.",
        "story_hooks": "Machine-readable story seeds for dossier, news, Twooter, Network, filing, and thesis systems.",
    }


def normalize_companies(value) -> list[dict]:
    if not isinstance(value, list):
        return []
    companies: list[dict] = []
    for row in value:
        if not isinstance(row, dict):
            continue
        company = normalize_company(row)
        if company.get("id") or company.get("ticker") or company.get("name"):
            companies.append(company)
    return companies


def normalize_company(row: dict) -> dict:
    raw = copy.deepcopy(row)
    company_id = slug_id(raw.get("id", ""))
    ticker = normalize_ticker(raw.get("ticker", company_id[:4]))
    price_traits = raw.get("price_traits", {})
    if not isinstance(price_traits, dict):
        price_traits = {}
    company = {
        "id": company_id,
        "ticker": ticker,
        "name": str(raw.get("name", "")).strip(),
        "sector": str(raw.get("sector", "")).strip(),
        "subsector": slug_id(raw.get("subsector", "")),
        "business_summary": str(raw.get("business_summary", "")).strip(),
        "moat_tags": normalize_string_array(raw.get("moat_tags", [])),
        "commodity_exposures": normalize_exposure_map(raw.get("commodity_exposures", {})),
        "macro_exposures": normalize_exposure_map(raw.get("macro_exposures", {})),
        "price_traits": {
            "liquidity_profile": str(price_traits.get("liquidity_profile", "mid")).strip() or "mid",
            "volatility_profile": str(price_traits.get("volatility_profile", "moderate")).strip() or "moderate",
            "quality_bias": clamp_float(price_traits.get("quality_bias", 0.0), -1.0, 1.0),
            "growth_bias": clamp_float(price_traits.get("growth_bias", 0.0), -1.0, 1.0),
            "risk_bias": clamp_float(price_traits.get("risk_bias", 0.0), -1.0, 1.0),
            "retail_attention_bias": clamp_float(price_traits.get("retail_attention_bias", 0.0), -1.0, 1.0),
            "event_sensitivity": clamp_float(price_traits.get("event_sensitivity", 0.0), -1.0, 1.0),
        },
        "relationship_hooks": normalize_relationship_hooks(raw.get("relationship_hooks", [])),
        "story_hooks": normalize_string_array(raw.get("story_hooks", [])),
    }
    return company


def normalize_relationship_hooks(value) -> list[dict]:
    if not isinstance(value, list):
        return []
    hooks: list[dict] = []
    for row in value:
        if not isinstance(row, dict):
            continue
        hook_type = str(row.get("type", "partner")).strip() or "partner"
        visibility = str(row.get("visibility", "semi_public")).strip() or "semi_public"
        hooks.append({
            "type": hook_type,
            "target_sector": str(row.get("target_sector", "")).strip(),
            "target_subsector": slug_id(row.get("target_subsector", "")),
            "strength": clamp_float(row.get("strength", 0.3), 0.0, 1.0),
            "visibility": visibility,
        })
    return hooks


def normalize_exposure_map(value) -> dict:
    if not isinstance(value, dict):
        return {}
    rows: dict = {}
    for key, raw_value in value.items():
        exposure_id = slug_id(key)
        if not exposure_id:
            continue
        rows[exposure_id] = clamp_float(raw_value, -1.0, 1.0)
    return rows


def export_runtime_payload(source: dict) -> dict:
    normalized = normalize_source(source)
    return {
        "schema_version": normalized.get("schema_version", 1),
        "status": normalized.get("status", "planning_seed"),
        "description": normalized.get("description", ""),
        "field_notes": normalized.get("field_notes", default_field_notes()),
        "companies": normalized.get("companies", []),
    }


def validate_source(source: dict) -> dict:
    normalized = normalize_source(source)
    errors: list[str] = []
    warnings: list[str] = []
    sectors = load_sector_ids()
    commodity_ids = load_commodity_ids()
    companies = normalized.get("companies", [])
    seen_ids: dict[str, int] = {}
    seen_tickers: dict[str, int] = {}
    sector_counts: dict[str, int] = {}
    commodity_exposure_keys: set[str] = set()

    if not companies:
        errors.append("companies must contain at least one company.")

    for index, company in enumerate(companies):
        path = f"companies[{index}]"
        company_id = company.get("id", "")
        ticker = company.get("ticker", "")
        sector = company.get("sector", "")
        subsector = company.get("subsector", "")

        if not company_id:
            errors.append(f"{path}.id is empty.")
        elif not is_snake(company_id):
            errors.append(f"{path}.id '{company_id}' must be snake_case.")
        elif company_id in seen_ids:
            errors.append(f"{path}.id '{company_id}' duplicates companies[{seen_ids[company_id]}].")
        else:
            seen_ids[company_id] = index

        if not ticker:
            errors.append(f"{path}.ticker is empty.")
        elif not TICKER_RE.match(ticker):
            errors.append(f"{path}.ticker '{ticker}' must be 3-6 uppercase letters/numbers.")
        elif ticker in seen_tickers:
            errors.append(f"{path}.ticker '{ticker}' duplicates companies[{seen_tickers[ticker]}].")
        else:
            seen_tickers[ticker] = index

        for field in ["name", "business_summary"]:
            if not str(company.get(field, "")).strip():
                errors.append(f"{path}.{field} is empty.")

        if not sector:
            errors.append(f"{path}.sector is empty.")
        elif sector not in sectors:
            errors.append(f"{path}.sector '{sector}' is not in data/sectors/sectors.json.")
        else:
            sector_counts[sector] = sector_counts.get(sector, 0) + 1

        if not subsector:
            errors.append(f"{path}.subsector is empty.")
        elif not is_snake(subsector):
            errors.append(f"{path}.subsector '{subsector}' must be snake_case.")

        for field in ARRAY_FIELDS:
            if not isinstance(company.get(field), list):
                errors.append(f"{path}.{field} must be an array.")

        if not company.get("moat_tags"):
            warnings.append(f"{path}.moat_tags is empty.")
        if not company.get("story_hooks"):
            warnings.append(f"{path}.story_hooks is empty.")

        for exposure_field in EXPOSURE_FIELDS:
            exposure_map = company.get(exposure_field, {})
            if not isinstance(exposure_map, dict):
                errors.append(f"{path}.{exposure_field} must be a dictionary.")
                continue
            for exposure_id, exposure in exposure_map.items():
                if exposure_field == "commodity_exposures":
                    commodity_exposure_keys.add(str(exposure_id))
                if not is_snake(str(exposure_id)):
                    errors.append(f"{path}.{exposure_field}.{exposure_id} must be snake_case.")
                if not isinstance(exposure, (int, float)):
                    errors.append(f"{path}.{exposure_field}.{exposure_id} must be numeric.")
                elif exposure < -1.0 or exposure > 1.0:
                    errors.append(f"{path}.{exposure_field}.{exposure_id} is outside -1.0..1.0.")

        price_traits = company.get("price_traits", {})
        if not isinstance(price_traits, dict):
            errors.append(f"{path}.price_traits must be a dictionary.")
        else:
            for field in PRICE_TRAIT_FIELDS:
                if field not in price_traits:
                    errors.append(f"{path}.price_traits missing '{field}'.")
            if price_traits.get("liquidity_profile") not in LIQUIDITY_PROFILES:
                warnings.append(f"{path}.price_traits.liquidity_profile should be one of {', '.join(LIQUIDITY_PROFILES)}.")
            if price_traits.get("volatility_profile") not in VOLATILITY_PROFILES:
                warnings.append(f"{path}.price_traits.volatility_profile should be one of {', '.join(VOLATILITY_PROFILES)}.")
            for field in NUMERIC_PRICE_TRAIT_FIELDS:
                value = price_traits.get(field)
                if not isinstance(value, (int, float)):
                    errors.append(f"{path}.price_traits.{field} must be numeric.")
                elif value < -1.0 or value > 1.0:
                    errors.append(f"{path}.price_traits.{field} is outside -1.0..1.0.")

        hooks = company.get("relationship_hooks", [])
        if isinstance(hooks, list):
            for hook_index, hook in enumerate(hooks):
                hook_path = f"{path}.relationship_hooks[{hook_index}]"
                if not isinstance(hook, dict):
                    errors.append(f"{hook_path} must be a dictionary.")
                    continue
                if hook.get("type") not in HOOK_TYPES:
                    warnings.append(f"{hook_path}.type should be one of {', '.join(HOOK_TYPES)}.")
                target_sector = str(hook.get("target_sector", "")).strip()
                if not target_sector:
                    errors.append(f"{hook_path}.target_sector is empty.")
                elif target_sector not in sectors:
                    errors.append(f"{hook_path}.target_sector '{target_sector}' is unknown.")
                if not str(hook.get("target_subsector", "")).strip():
                    errors.append(f"{hook_path}.target_subsector is empty.")
                strength = hook.get("strength")
                if not isinstance(strength, (int, float)):
                    errors.append(f"{hook_path}.strength must be numeric.")
                elif strength < 0.0 or strength > 1.0:
                    errors.append(f"{hook_path}.strength is outside 0.0..1.0.")
                if hook.get("visibility") not in HOOK_VISIBILITIES:
                    warnings.append(f"{hook_path}.visibility should be one of {', '.join(HOOK_VISIBILITIES)}.")

    unknown_commodities = sorted(key for key in commodity_exposure_keys if commodity_ids and key not in commodity_ids)
    for commodity_id in unknown_commodities:
        warnings.append(f"commodity_exposures uses '{commodity_id}', which is not in commodity_indicator_catalog.json.")

    if len(companies) < 30:
        warnings.append("Catalog has fewer than 30 companies; default runs request a 30-company roster.")
    if len(sector_counts) < 8:
        warnings.append(f"Catalog covers only {len(sector_counts)} sectors; current target is broad cross-sector coverage.")

    return {
        "valid": not errors,
        "errors": errors,
        "warnings": warnings,
        "summary": {
            "company_count": len(companies),
            "unique_ids": len(seen_ids),
            "unique_tickers": len(seen_tickers),
            "sector_counts": dict(sorted(sector_counts.items())),
            "commodity_exposure_keys": sorted(
                set().union(*(company.get("commodity_exposures", {}).keys() for company in companies))
            ),
            "macro_exposure_keys": sorted(
                set().union(*(company.get("macro_exposures", {}).keys() for company in companies))
            ),
        },
    }


def load_sector_ids() -> set[str]:
    try:
        rows = read_json(SECTORS_PATH)
    except (json.JSONDecodeError, OSError):
        return set()
    if not isinstance(rows, list):
        return set()
    return {str(row.get("id", "")).strip() for row in rows if isinstance(row, dict) and row.get("id")}


def load_commodity_ids() -> set[str]:
    try:
        data = read_json(COMMODITY_PATH)
    except (json.JSONDecodeError, OSError):
        return set()
    if isinstance(data, dict):
        rows = data.get("commodities", data.get("indicators", []))
    else:
        rows = data
    if not isinstance(rows, list):
        return set()
    ids: set[str] = set()
    for row in rows:
        if isinstance(row, dict):
            commodity_id = str(row.get("id", "")).strip()
            if commodity_id:
                ids.add(commodity_id)
    return ids


def build_metadata() -> dict:
    return {
        "sectors": sorted(load_sector_ids()),
        "commodity_ids": sorted(load_commodity_ids()),
        "hook_types": HOOK_TYPES,
        "hook_visibilities": HOOK_VISIBILITIES,
        "liquidity_profiles": LIQUIDITY_PROFILES,
        "volatility_profiles": VOLATILITY_PROFILES,
        "runtime_path": relative_path(RUNTIME_PATH),
        "source_path": relative_path(SOURCE_PATH),
    }


def slug_id(value) -> str:
    return re.sub(r"[^a-z0-9_]+", "_", str(value or "").strip().lower()).strip("_")


def normalize_ticker(value) -> str:
    return re.sub(r"[^A-Z0-9]+", "", str(value or "").upper())[:6]


def normalize_string_array(value) -> list[str]:
    if isinstance(value, str):
        value = value.splitlines()
    if not isinstance(value, list):
        return []
    rows: list[str] = []
    for item in value:
        text = str(item).strip()
        if text and text not in rows:
            rows.append(text)
    return rows


def normalize_int(value, default: int) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def clamp_float(value, low: float, high: float) -> float:
    try:
        number = float(value)
    except (TypeError, ValueError):
        number = 0.0
    return max(low, min(high, number))


def is_snake(value: str) -> bool:
    return bool(SNAKE_RE.match(value))


def relative_path(path: Path) -> str:
    try:
        return str(path.relative_to(PROJECT_ROOT))
    except ValueError:
        return str(path)


class Handler(BaseHTTPRequestHandler):
    server_version = "CompanyUniverseEditor/1.0"

    def log_message(self, format: str, *args) -> None:
        print("[company-universe-editor] " + format % args)

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/api/source":
            self.send_json(load_source())
            return
        if parsed.path == "/api/validate":
            self.send_json(validate_source(load_source()))
            return
        if parsed.path == "/api/metadata":
            self.send_json(build_metadata())
            return
        self.serve_static(parsed.path)

    def do_POST(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/api/source":
            source = normalize_source(self.read_json_body())
            write_json(SOURCE_PATH, source)
            self.send_json({"saved": True, "path": relative_path(SOURCE_PATH), "validation": validate_source(source)})
            return
        if parsed.path == "/api/validate":
            source = normalize_source(self.read_json_body())
            self.send_json(validate_source(source))
            return
        if parsed.path == "/api/export":
            source = normalize_source(self.read_json_body())
            validation = validate_source(source)
            if not validation.get("valid"):
                self.send_json({"error": "Source is invalid; fix validation errors before export.", "validation": validation}, status=400)
                return
            payload = export_runtime_payload(source)
            write_json(SOURCE_PATH, source)
            write_json(RUNTIME_PATH, payload)
            self.send_json({
                "exported": True,
                "source_path": relative_path(SOURCE_PATH),
                "runtime_path": relative_path(RUNTIME_PATH),
                "validation": validation,
            })
            return
        self.send_json({"error": "Not found"}, status=404)

    def read_json_body(self):
        length = int(self.headers.get("Content-Length", "0") or "0")
        raw = self.rfile.read(length)
        if not raw:
            return {}
        return json.loads(raw.decode("utf-8"))

    def send_json(self, payload, status: int = 200) -> None:
        encoded = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def serve_static(self, request_path: str) -> None:
        clean_path = unquote(request_path).lstrip("/")
        if not clean_path:
            clean_path = "static/index.html"
        if clean_path.startswith("static/"):
            path = TOOL_DIR / clean_path
        else:
            path = STATIC_DIR / clean_path
        try:
            resolved = path.resolve()
            if not str(resolved).startswith(str(TOOL_DIR.resolve())) or not resolved.exists() or not resolved.is_file():
                raise FileNotFoundError(path)
            content_type = mimetypes.guess_type(str(resolved))[0] or "application/octet-stream"
            data = resolved.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        except OSError:
            self.send_json({"error": "Not found"}, status=404)


def run_server(host: str, port: int) -> None:
    server = ThreadingHTTPServer((host, port), Handler)
    print(f"Company Universe Editor running at http://{host}:{port}")
    print(f"Editable source: {relative_path(SOURCE_PATH)}")
    print(f"Runtime output: {relative_path(RUNTIME_PATH)}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping Company Universe Editor.")
    finally:
        server.server_close()


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Company Universe catalog editor.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8775)
    parser.add_argument("--validate", action="store_true", help="Validate the editable source and exit.")
    parser.add_argument("--export", action="store_true", help="Export source to runtime JSON and exit.")
    parser.add_argument("--dry-run", action="store_true", help="With --export, validate and print target without writing runtime JSON.")
    args = parser.parse_args(argv)

    source = load_source()
    validation = validate_source(source)

    if args.validate:
        print(json.dumps(validation, ensure_ascii=False, indent=2))
        return 0 if validation.get("valid") else 1

    if args.export:
        if not validation.get("valid"):
            print(json.dumps(validation, ensure_ascii=False, indent=2), file=sys.stderr)
            return 1
        payload = export_runtime_payload(source)
        if args.dry_run:
            print(json.dumps({
                "dry_run": True,
                "runtime_path": relative_path(RUNTIME_PATH),
                "company_count": len(payload.get("companies", [])),
                "validation": validation,
            }, ensure_ascii=False, indent=2))
            return 0
        write_json(SOURCE_PATH, source)
        write_json(RUNTIME_PATH, payload)
        print(json.dumps({
            "exported": True,
            "source_path": relative_path(SOURCE_PATH),
            "runtime_path": relative_path(RUNTIME_PATH),
            "company_count": len(payload.get("companies", [])),
        }, ensure_ascii=False, indent=2))
        return 0

    run_server(args.host, args.port)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
