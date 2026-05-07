#!/usr/bin/env python3
"""Dev-only Content Lint Dashboard and generated preview server.

Uses only Python stdlib. This is a read-only dashboard: it aggregates the
existing content-editor validators and renders deterministic sample previews
from the current runtime JSON files.
"""

from __future__ import annotations

import argparse
import copy
import importlib.util
import json
import mimetypes
import random
import re
import sys
import time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlparse


TOOL_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = TOOL_DIR.parents[1]
STATIC_DIR = TOOL_DIR / "static"

TOOL_SPECS = [
    {
        "id": "academy",
        "label": "Academy",
        "port": 8765,
        "description": "Lesson catalog, pages, blocks, quiz data, and lesson metadata.",
        "server": PROJECT_ROOT / "tools" / "academy_editor" / "server.py",
        "source": PROJECT_ROOT / "tools" / "academy_editor" / "academy_source.json",
        "runtime": ["data/academy/academy_catalog.json"],
    },
    {
        "id": "news",
        "label": "News",
        "port": 8766,
        "description": "News outlets, authors, body slots, voice templates, and generated article copy pools.",
        "server": PROJECT_ROOT / "tools" / "news_editor" / "server.py",
        "source": PROJECT_ROOT / "tools" / "news_editor" / "news_source.json",
        "runtime": ["data/news/news_feed_data.json"],
    },
    {
        "id": "twooter",
        "label": "Twooter",
        "port": 8767,
        "description": "Social accounts, post templates, fallback pools, threads, and continuity copy.",
        "server": PROJECT_ROOT / "tools" / "twooter_editor" / "server.py",
        "source": PROJECT_ROOT / "tools" / "twooter_editor" / "twooter_source.json",
        "runtime": ["data/social/twooter_feed_data.json"],
    },
    {
        "id": "network",
        "label": "Network",
        "port": 8768,
        "description": "Contacts, relationship gates, tip copy, request copy, meetings, and lead templates.",
        "server": PROJECT_ROOT / "tools" / "network_editor" / "server.py",
        "source": PROJECT_ROOT / "tools" / "network_editor" / "network_source.json",
        "runtime": ["data/network/contact_network_data.json"],
    },
    {
        "id": "corporate_action",
        "label": "Corporate Action",
        "port": 8769,
        "description": "Corporate-action stages, agendas, family metadata, and market impact parameters.",
        "server": PROJECT_ROOT / "tools" / "corporate_action_editor" / "server.py",
        "source": PROJECT_ROOT / "tools" / "corporate_action_editor" / "corporate_action_source.json",
        "runtime": ["data/corporate_actions/corporate_action_catalog.json"],
    },
    {
        "id": "broker_roster",
        "label": "Broker Roster",
        "port": 8770,
        "description": "Broker identities, desks, style tags, flow bias, and roster presentation data.",
        "server": PROJECT_ROOT / "tools" / "broker_roster_editor" / "server.py",
        "source": PROJECT_ROOT / "tools" / "broker_roster_editor" / "broker_roster_source.json",
        "runtime": ["data/brokers/broker_roster.json"],
    },
    {
        "id": "company_narrative",
        "label": "Company Narrative",
        "port": 8771,
        "description": "Company archetypes, naming words, profile copy, and generated roster narrative pools.",
        "server": PROJECT_ROOT / "tools" / "company_narrative_editor" / "server.py",
        "source": PROJECT_ROOT / "tools" / "company_narrative_editor" / "company_narrative_source.json",
        "runtime": [
            "data/companies/company_archetypes.json",
            "data/companies/company_words.json",
            "data/companies/company_profile_data.json",
        ],
    },
    {
        "id": "balance_upgrades",
        "label": "Balance / Upgrades",
        "port": 8772,
        "description": "Upgrade catalog costs, unlocks, balance metadata, and progression copy.",
        "server": PROJECT_ROOT / "tools" / "balance_upgrades_editor" / "server.py",
        "source": PROJECT_ROOT / "tools" / "balance_upgrades_editor" / "balance_upgrades_source.json",
        "runtime": ["data/upgrades/upgrade_catalog.json"],
    },
    {
        "id": "event_content",
        "label": "Event Content",
        "port": 8773,
        "description": "Market event definitions, special events, tone, scope, duration, and shock parameters.",
        "server": PROJECT_ROOT / "tools" / "event_content_editor" / "server.py",
        "source": PROJECT_ROOT / "tools" / "event_content_editor" / "event_content_source.json",
        "runtime": ["data/events/events.json"],
    },
]

RUNTIME_FILES = sorted({
    path
    for spec in TOOL_SPECS
    for path in spec["runtime"]
} | {
    "data/sectors/sectors.json",
    "data/steam/achievement_catalog.json",
    "data/calendar/idx_holidays.json",
    "data/index_reviews/index_review_catalog.json",
})

TOKEN_RE = re.compile(r"\{([A-Za-z0-9_]+)\}")
UNRESOLVED_TOKEN_RE = re.compile(r"\{[A-Za-z0-9_]+\}")
MULTI_PUNCT_RE = re.compile(r"(\.{2,}|!!+|\?\?+)")
SPACE_BEFORE_PUNCT_RE = re.compile(r"\s+[,.!?;:]")


def read_json(path: Path):
    raw = path.read_text(encoding="utf-8-sig")
    return json.loads(raw)


def import_module_from_path(module_id: str, path: Path):
    spec = importlib.util.spec_from_file_location(f"content_lint_{module_id}", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not import module from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def run_tool_validator(spec: dict) -> dict:
    started = time.perf_counter()
    result = {
        "id": spec["id"],
        "label": spec["label"],
        "description": spec.get("description", ""),
        "port": spec.get("port", 0),
        "launch_url": f"http://127.0.0.1:{spec.get('port', 0)}" if spec.get("port") else "",
        "launch_command": python_tool_command(spec["server"]),
        "validate_command": python_tool_command(spec["server"], "--validate"),
        "dry_run_export_command": python_tool_command(spec["server"], "--export", "--dry-run"),
        "source": relative_path(spec["source"]),
        "runtime": spec["runtime"],
        "valid": False,
        "errors": [],
        "warnings": [],
        "duration_ms": 0,
    }
    try:
        if not spec["server"].exists():
            raise FileNotFoundError(spec["server"])
        module = import_module_from_path(spec["id"], spec["server"])
        source = module.load_source()
        validation = module.validate_source(source)
        result["valid"] = bool(validation.get("valid", False))
        result["errors"] = [str(row) for row in validation.get("errors", [])]
        result["warnings"] = [str(row) for row in validation.get("warnings", [])]
        result["source_exists"] = bool(spec["source"].exists())
    except Exception as exc:  # noqa: BLE001 - dashboard must report failures, not crash.
        result["valid"] = False
        result["errors"] = [f"Validator failed: {exc}"]
        result["source_exists"] = bool(spec["source"].exists())
    result["duration_ms"] = round((time.perf_counter() - started) * 1000, 2)
    return result


def lint_runtime_file(relative: str) -> dict:
    path = PROJECT_ROOT / relative
    result = {
        "path": relative,
        "valid": False,
        "type": "",
        "count": 0,
        "bytes": 0,
        "errors": [],
        "warnings": [],
        "token_count": 0,
        "sample_tokens": [],
    }
    try:
        result["bytes"] = path.stat().st_size
        value = read_json(path)
        result["valid"] = True
        result["type"] = type(value).__name__
        if isinstance(value, list):
            result["count"] = len(value)
        elif isinstance(value, dict):
            result["count"] = len(value)
        tokens = scan_tokens(value)
        result["token_count"] = sum(tokens.values())
        result["sample_tokens"] = sorted(tokens.keys())[:12]
        result["warnings"].extend(generic_id_warnings(value, relative))
    except Exception as exc:  # noqa: BLE001
        result["errors"].append(str(exc))
    return result


def scan_tokens(value) -> dict[str, int]:
    counts: dict[str, int] = {}
    if isinstance(value, str):
        for token in TOKEN_RE.findall(value):
            counts[token] = counts.get(token, 0) + 1
    elif isinstance(value, list):
        for row in value:
            merge_counts(counts, scan_tokens(row))
    elif isinstance(value, dict):
        for row in value.values():
            merge_counts(counts, scan_tokens(row))
    return counts


def merge_counts(target: dict[str, int], source: dict[str, int]) -> None:
    for key, count in source.items():
        target[key] = target.get(key, 0) + count


def generic_id_warnings(value, relative: str) -> list[str]:
    warnings: list[str] = []
    if isinstance(value, list) and value and all(isinstance(row, dict) for row in value):
        ids = [str(row.get("id", "")).strip() for row in value if str(row.get("id", "")).strip()]
        if len(ids) != len(set(ids)):
            warnings.append(f"{relative}: duplicate id values detected.")
    if isinstance(value, dict):
        for key, row in value.items():
            if isinstance(row, list) and row and all(isinstance(item, dict) for item in row):
                ids = [str(item.get("id", "")).strip() for item in row if str(item.get("id", "")).strip()]
                if len(ids) != len(set(ids)):
                    warnings.append(f"{relative}.{key}: duplicate id values detected.")
    return warnings


def build_dashboard() -> dict:
    tools = [run_tool_validator(spec) for spec in TOOL_SPECS]
    runtime_files = [lint_runtime_file(path) for path in RUNTIME_FILES]
    cross_lints = build_cross_lints(tools, runtime_files)
    total_errors = sum(len(row.get("errors", [])) for row in tools) + sum(len(row.get("errors", [])) for row in runtime_files)
    total_warnings = (
        sum(len(row.get("warnings", [])) for row in tools)
        + sum(len(row.get("warnings", [])) for row in runtime_files)
        + len([row for row in cross_lints if row.get("severity") == "warning"])
    )
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "summary": {
            "tools": len(tools),
            "valid_tools": len([row for row in tools if row.get("valid")]),
            "runtime_files": len(runtime_files),
            "valid_runtime_files": len([row for row in runtime_files if row.get("valid")]),
            "errors": total_errors,
            "warnings": total_warnings,
        },
        "tools": tools,
        "runtime_files": runtime_files,
        "cross_lints": cross_lints,
    }


def build_cross_lints(tools: list[dict], runtime_files: list[dict]) -> list[dict]:
    lints: list[dict] = []
    for tool in tools:
        if not tool.get("source_exists", False):
            lints.append({
                "severity": "warning",
                "message": f"{tool.get('label')}: source wrapper does not exist yet; validator imported runtime JSON.",
            })
    for row in runtime_files:
        if row.get("token_count", 0) > 0:
            lints.append({
                "severity": "note",
                "message": f"{row.get('path')}: {row.get('token_count')} template token references across runtime copy.",
            })
    return lints


def relative_path(path: Path) -> str:
    try:
        return str(path.relative_to(PROJECT_ROOT))
    except ValueError:
        return str(path)


def python_tool_command(path: Path, *args: str) -> str:
    parts = ["python3", relative_path(path), *args]
    return " ".join(parts)


def build_preview(seed: int = 42) -> dict:
    rng = random.Random(seed)
    event_rows = read_json(PROJECT_ROOT / "data" / "events" / "events.json")
    company_profile_data = read_json(PROJECT_ROOT / "data" / "companies" / "company_profile_data.json")
    company_words = read_json(PROJECT_ROOT / "data" / "companies" / "company_words.json")
    sectors = read_json(PROJECT_ROOT / "data" / "sectors" / "sectors.json")
    news_data = read_json(PROJECT_ROOT / "data" / "news" / "news_feed_data.json")
    twooter_data = read_json(PROJECT_ROOT / "data" / "social" / "twooter_feed_data.json")
    network_data = read_json(PROJECT_ROOT / "data" / "network" / "contact_network_data.json")
    corporate_data = read_json(PROJECT_ROOT / "data" / "corporate_actions" / "corporate_action_catalog.json")
    academy_data = read_json(PROJECT_ROOT / "data" / "academy" / "academy_catalog.json")

    event = rng.choice(event_rows)
    sector = rng.choice(sectors)
    context = preview_context(event, sector)
    preview = {
        "seed": seed,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "sections": [
            company_preview_section(rng, company_profile_data, company_words, sectors),
            event_preview_section(rng, event_rows),
            news_preview_section(rng, news_data, context),
            twooter_preview_section(rng, twooter_data, context),
            network_preview_section(rng, network_data, context),
            corporate_preview_section(rng, corporate_data, context),
            academy_preview_section(rng, academy_data),
        ],
    }
    normalize_preview_payload(preview)
    preview["quality"] = collect_preview_quality(preview)
    preview["quality_summary"] = {
        "issues": len(preview["quality"]),
        "errors": len([row for row in preview["quality"] if row.get("severity") == "error"]),
        "warnings": len([row for row in preview["quality"] if row.get("severity") == "warning"]),
    }
    return preview


def preview_context(event: dict, sector: dict) -> dict:
    ticker = "MBNK"
    company_name = "Mock Bank Tbk"
    scope = str(event.get("scope", "company"))
    sector_name = str(sector.get("name", "Finance"))
    provider_label = str(event.get("provider_label", "MSCY"))
    focus_label = ticker
    if scope == "market":
        focus_label = "Index Gorengan"
    elif scope == "sector":
        focus_label = sector_name
    elif str(event.get("person_name", "")).strip():
        focus_label = str(event.get("person_name", "")).strip()
    if str(event.get("event_family", "")) == "index_review" or str(event.get("category", "")).startswith("index_"):
        focus_label = ticker if scope == "company" else provider_label
    detail = str(event.get("headline_detail_template") or event.get("description") or "the setup is still developing")
    return {
        "target_ticker": ticker,
        "ticker": ticker,
        "target_company_name": company_name,
        "company_name": company_name,
        "company": company_name,
        "contact": "contact",
        "agenda": "the next market update",
        "provider_label": provider_label,
        "focus_label": focus_label,
        "scope": scope,
        "headline_hint": str(event.get("headline_template", "")),
        "detail_hint": detail,
        "sector_name": sector_name,
        "market_change": "mixed with selective buying",
        "market_state_label": "mixed",
        "advancers": "142",
        "decliners": "136",
        "breadth_summary": "winners and losers are split across the board",
        "driver_phrase": str(event.get("description", "a fresh market driver is changing positioning")),
        "detail_blend": detail,
        "subject_reference": company_name,
        "desk_watch": "Dealers are watching whether the move gets follow-through",
        "formal_phrase": "The formal read is still developing",
        "analysis_phrase": "The market wants confirmation",
        "reaction_phrase": "waiting for confirmation",
        "watch_phrase": "The next session should show whether the move has real depth.",
        "price_action_label": "trying to hold its first reaction",
        "flow_label": "broker flow is still mixed",
        "market_jargon": "leadership has not fully broadened",
        "whisper_phrase": "Early desk chatter suggests",
        "continuity_phrase": "This follows an earlier market read.",
        "biggest_winner": "MBNK",
        "biggest_loser": "RISK",
        "tone": str(event.get("tone", "mixed")),
        "event_id": str(event.get("id", "")),
        "category": str(event.get("category", "")),
    }


def company_preview_section(rng: random.Random, profile_data: dict, word_data: dict, sectors: list[dict]) -> dict:
    words = word_data.get("unique_words", [])
    archetypes = profile_data.get("archetypes", {})
    sizes = profile_data.get("sizes", {})
    templates = profile_data.get("sentence_templates", {}).get("primary_pool", [])
    rows = []
    for index in range(6):
        company_words = rng.sample(words, 2) if len(words) >= 2 else ["Mock", "Company"]
        name = " ".join(company_words) + " Tbk"
        ticker = "".join(word[0] for word in company_words).upper().ljust(4, "X")[:4]
        sector = rng.choice(sectors) if sectors else {"id": "finance", "name": "Finance"}
        archetype_id, archetype = rng.choice(list(archetypes.items())) if archetypes else ("balanced", {})
        size_id, size = rng.choice(list(sizes.items())) if sizes else ("2", {})
        context = {
            "COMPANY": name,
            "SECTOR": sector.get("name", sector.get("id", "sector")),
            "ARCHETYPE": archetype.get("label", archetype_id),
            "SIZE_DESCRIPTOR": choose(rng, size.get("descriptor_pool", []), "mid-sized"),
            "ARCHETYPE_DESCRIPTOR": choose(rng, archetype.get("descriptor_pool", []), "focused"),
            "ARCHETYPE_VERB": choose(rng, archetype.get("verb_pool", []), "operates in"),
            "SECTOR_BUSINESS": choose(rng, profile_data.get("sectors", {}).get(sector.get("id", ""), {}).get("business_pool", []), "a core business line"),
            "AGE": str(rng.randint(6, 40)),
            "FOUNDED": str(rng.randint(1985, 2018)),
            "EMPLOYEES": f"{rng.randint(120, 9000):,}",
            "REVENUE": str(rng.randint(1, 90)),
            "REVENUE_UNIT": "trillion",
        }
        template = choose(rng, templates, "{COMPANY} is a {SIZE_DESCRIPTOR} {SECTOR} company.")
        rows.append({
            "title": f"{ticker} - {name}",
            "meta": f"{sector.get('name', sector.get('id', 'Sector'))} / {archetype.get('label', archetype_id)} / size {size_id}",
            "body": ensure_terminal_punctuation(render_template(template, context)),
        })
    return {"id": "companies", "label": "Company Narrative Samples", "items": rows}


def event_preview_section(rng: random.Random, events: list[dict]) -> dict:
    rows = []
    for event in rng.sample(events, min(6, len(events))):
        headline = event.get("headline_template") or event.get("id", "event").replace("_", " ").title()
        detail = event.get("headline_detail_template") or event.get("description", "")
        rows.append({
            "title": str(headline),
            "meta": "%s / %s / %s / shift %.3f" % (
                event.get("event_family", ""),
                event.get("scope", ""),
                event.get("tone", ""),
                float(event.get("sentiment_shift", 0.0)),
            ),
            "body": str(detail),
        })
    return {"id": "events", "label": "Event Definition Samples", "items": rows}


def news_preview_section(rng: random.Random, data: dict, context: dict) -> dict:
    outlets = data.get("outlets", [])
    authors = data.get("authors", [])
    voice_profiles = data.get("voice_profiles", {})
    outlet = choose(rng, outlets, {})
    voice_id = outlet.get("voice", next(iter(voice_profiles.keys()), ""))
    voice = voice_profiles.get(voice_id, {})
    stage = "confirmation" if context.get("tone") == "positive" else "analysis"
    headline = render_template(choose_template(rng, voice.get("headline_templates", {}), stage), context)
    deck = render_template(choose_template(rng, voice.get("deck_templates", {}), stage), context)
    lead = render_template(choose_template(rng, voice.get("lead_templates", {}), stage), context)
    impact = render_template(choose_template(rng, voice.get("impact_templates", {}), stage), context)
    author = choose(rng, authors, {})
    return {
        "id": "news",
        "label": "Generated News Preview",
        "items": [{
            "title": headline or "Generated article headline",
            "meta": "%s / %s" % (outlet.get("label", "Outlet"), author.get("display_name", "Reporter")),
            "body": "\n".join(row for row in [deck, lead, impact] if row),
        }],
    }


def twooter_preview_section(rng: random.Random, data: dict, context: dict) -> dict:
    accounts = data.get("accounts", [])
    voices = data.get("voice_templates", {})
    fallback = data.get("fallback_templates", {})
    fallback_posts = data.get("fallback_posts", {})
    rows = []
    for account in rng.sample(accounts, min(6, len(accounts))):
        voice = voices.get(account.get("voice", ""), {})
        template = ""
        keys = twooter_template_keys(context)
        for key in keys:
            template = choose(rng, voice.get(key, []), "")
            if template:
                break
        if not template:
            for key in keys:
                template = choose(rng, fallback.get(key, []), "")
                if template:
                    break
        if not template and isinstance(fallback_posts, dict):
            template = choose(rng, fallback_posts.get("all", []), "")
        if not template:
            template = choose(rng, fallback_posts, "")
        rows.append({
            "title": "%s %s" % (account.get("display_name", "Account"), account.get("handle", "")),
            "meta": "tier %s / %s" % (account.get("tier", ""), account.get("voice", "")),
            "body": render_template(template, context),
        })
    return {"id": "twooter", "label": "Generated Twooter Posts", "items": rows}


def twooter_template_keys(context: dict) -> list[str]:
    category = str(context.get("category", ""))
    tone = str(context.get("tone", "mixed"))
    scope = str(context.get("scope", "company"))
    keys = []
    if category:
        keys.append(category)
    if category.startswith("index_"):
        keys.append("index_review")
    if category.startswith("corporate_action"):
        keys.append("corporate_action")
    if category == "corporate_meeting":
        keys.append("corporate_meeting")
    if scope == "market":
        keys.extend([f"market_{tone}", "market_wrap"])
    elif scope == "sector":
        keys.append(f"sector_{tone}")
    else:
        keys.append(f"company_{tone}")
    family_key = category_family_key(category, scope)
    if family_key:
        keys.append(family_key)
    keys.extend([f"company_{tone}", "company", "all"])
    unique = []
    for key in keys:
        if key and key not in unique:
            unique.append(key)
    return unique


def category_family_key(category: str, scope: str) -> str:
    if category.startswith("index_"):
        return "index_review"
    if category.startswith("corporate_action"):
        return "corporate_action"
    if category == "corporate_meeting":
        return "corporate_meeting"
    if category in ["earnings", "management", "market_wrap"]:
        return category
    if "commodity" in category:
        return "commodity"
    if scope == "market":
        return "market_wrap"
    return "company"


def network_preview_section(rng: random.Random, data: dict, context: dict) -> dict:
    contacts = data.get("contacts", [])
    contact = choose(rng, contacts, {})
    tip_templates = flatten_strings(data.get("tip_templates", {}))
    request_templates = flatten_strings(data.get("request_templates", {}))
    return {
        "id": "network",
        "label": "Network Contact Preview",
        "items": [
            {
                "title": contact.get("display_name", "Contact"),
                "meta": "%s / %s" % (contact.get("role", ""), ",".join(contact.get("categories", []))),
                "body": contact.get("intro", ""),
            },
            {
                "title": "Tip / Request Copy",
                "meta": "generated from template pools",
                "body": "\n".join([
                    render_template(choose(rng, tip_templates, "No tip template."), context),
                    render_template(choose(rng, request_templates, "No request template."), context),
                ]),
            },
        ],
    }


def corporate_preview_section(rng: random.Random, data: dict, context: dict) -> dict:
    stage_templates = data.get("stage_templates", {})
    family_keys = [
        key for key, value in data.items()
        if isinstance(value, dict) and key not in ["meeting_defaults", "family_metadata", "family_agendas"]
    ]
    rows = []
    stage_rows = []
    if isinstance(stage_templates, dict):
        stage_rows = [{"id": key, **value} for key, value in stage_templates.items() if isinstance(value, dict)]
    elif isinstance(stage_templates, list):
        stage_rows = [row for row in stage_templates if isinstance(row, dict)]
    if stage_rows:
        stage = choose(rng, stage_rows, {})
        rows.append({
            "title": stage.get("label", stage.get("id", "Stage")),
            "meta": "stage template / sentiment %.3f" % float(stage.get("sentiment_shift", 0.0)),
            "body": render_template(stage.get("description", stage.get("public_summary", stage.get("category", ""))), context),
        })
    for key in rng.sample(family_keys, min(3, len(family_keys))):
        family = data.get(key, {})
        rows.append({
            "title": key.replace("_", " ").title(),
            "meta": "enabled %s" % family.get("enabled", "n/a"),
            "body": ", ".join(sorted(family.keys())[:8]),
        })
    return {"id": "corporate_actions", "label": "Corporate Action Preview", "items": rows}


def academy_preview_section(rng: random.Random, data: dict) -> dict:
    categories = data.get("categories", [])
    playable_sections = [
        (category, section)
        for category in categories
        for section in category.get("sections", [])
        if section.get("content_blocks") or section.get("pages")
    ]
    category, section = choose(rng, playable_sections, ({}, {}))
    blocks = section.get("content_blocks", [])
    pages = section.get("pages", [])
    content_rows = [academy_content_body(row) for row in [*blocks, *pages]]
    content_rows = [row for row in content_rows if row.strip()]
    body = choose(rng, content_rows, "")
    return {
        "id": "academy",
        "label": "Academy Lesson Preview",
        "items": [{
            "title": "%s / %s" % (category.get("label", "Academy"), section.get("title", section.get("label", section.get("id", "Section")))),
            "meta": "lesson content sample",
            "body": body,
        }],
    }


def academy_content_body(row: dict) -> str:
    parts = [
        str(row.get("heading", row.get("title", row.get("label", "")))),
        str(row.get("body", row.get("text", row.get("description", "")))),
    ]
    bullets = row.get("bullets", [])
    if isinstance(bullets, list) and bullets:
        parts.extend(f"- {bullet}" for bullet in bullets)
    return "\n".join(part for part in parts if str(part).strip()).strip()


def choose(rng: random.Random, value, default):
    if isinstance(value, list) and value:
        return rng.choice(value)
    return default


def choose_template(rng: random.Random, container, preferred_key: str) -> str:
    if isinstance(container, list):
        return choose(rng, container, "")
    if not isinstance(container, dict):
        return ""
    if preferred_key in container:
        return choose_template(rng, container.get(preferred_key), preferred_key)
    for fallback_key in ["confirmation", "analysis", "public_brief", "whisper", "market_wrap", "recap"]:
        if fallback_key in container:
            return choose_template(rng, container.get(fallback_key), fallback_key)
    for value in container.values():
        template = choose_template(rng, value, preferred_key)
        if template:
            return template
    return ""


def render_template(template: str, context: dict) -> str:
    def replace(match: re.Match) -> str:
        token = match.group(1)
        return str(context.get(token, context.get(token.lower(), "{%s}" % token)))

    return TOKEN_RE.sub(replace, str(template or ""))


def normalize_preview_payload(preview: dict) -> None:
    for section in preview.get("sections", []):
        for item in section.get("items", []):
            item["title"] = clean_copy(item.get("title", ""))
            item["meta"] = clean_copy(item.get("meta", ""))
            item["body"] = clean_copy(item.get("body", ""), preserve_newlines=True)


def clean_copy(value, preserve_newlines: bool = False) -> str:
    text = str(value or "").replace("\r\n", "\n").replace("\r", "\n")
    if preserve_newlines:
        lines = [re.sub(r"[ \t]+", " ", line).strip() for line in text.split("\n")]
        text = "\n".join(lines)
        text = re.sub(r"\n{3,}", "\n\n", text)
    else:
        text = re.sub(r"\s+", " ", text)
    replacements = [
        (" .", "."),
        (" ,", ","),
        (" ;", ";"),
        (" :", ":"),
        (" !", "!"),
        (" ?", "?"),
        ("?.", "?"),
        ("!.", "!"),
        ("..", "."),
        ("!!", "!"),
        ("??", "?"),
    ]
    for _ in range(3):
        for old, new in replacements:
            text = text.replace(old, new)
    return text.strip()


def ensure_terminal_punctuation(value) -> str:
    text = clean_copy(value)
    if text and text[-1] not in ".!?":
        text += "."
    return text


def collect_preview_quality(preview: dict) -> list[dict]:
    issues: list[dict] = []
    for section in preview.get("sections", []):
        section_id = str(section.get("id", ""))
        section_label = str(section.get("label", section_id))
        for index, item in enumerate(section.get("items", []), start=1):
            item_title = clean_copy(item.get("title", "")) or f"item {index}"
            for field in ["title", "meta", "body"]:
                text = str(item.get(field, ""))
                context = {
                    "section_id": section_id,
                    "section_label": section_label,
                    "item_index": index,
                    "item_title": item_title,
                    "field": field,
                }
                if field in ["title", "body"] and not text.strip():
                    issues.append(preview_issue(context, "warning", f"{field} is empty.", text))
                if UNRESOLVED_TOKEN_RE.search(text):
                    issues.append(preview_issue(context, "error", f"{field} has an unresolved template token.", text))
                if MULTI_PUNCT_RE.search(text):
                    issues.append(preview_issue(context, "warning", f"{field} has repeated punctuation.", text))
                if re.search(r"[ \t]{2,}", text):
                    issues.append(preview_issue(context, "warning", f"{field} has repeated spaces.", text))
                if SPACE_BEFORE_PUNCT_RE.search(text):
                    issues.append(preview_issue(context, "warning", f"{field} has a space before punctuation.", text))
                if field == "title" and len(text) > 110:
                    issues.append(preview_issue(context, "warning", "title is longer than 110 characters.", text))
                if field == "body" and len(text) > 1800:
                    issues.append(preview_issue(context, "warning", "body is longer than 1800 characters.", text))
    return issues


def preview_issue(context: dict, severity: str, message: str, sample: str) -> dict:
    compact_sample = clean_copy(sample, preserve_newlines=False)
    if len(compact_sample) > 220:
        compact_sample = compact_sample[:217].rstrip() + "..."
    return {
        **context,
        "severity": severity,
        "message": message,
        "sample": compact_sample,
    }


def build_preview_scan(seed: int = 42, count: int = 20) -> dict:
    bounded_count = max(1, min(int(count), 200))
    rows = []
    total_issues = 0
    for current_seed in range(seed, seed + bounded_count):
        preview = build_preview(current_seed)
        issues = preview.get("quality", [])
        total_issues += len(issues)
        rows.append({
            "seed": current_seed,
            "section_count": len(preview.get("sections", [])),
            "item_count": sum(len(section.get("items", [])) for section in preview.get("sections", [])),
            "issue_count": len(issues),
            "issues": issues[:12],
        })
    return {
        "seed": seed,
        "count": bounded_count,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "total_issues": total_issues,
        "seeds_with_issues": len([row for row in rows if row.get("issue_count", 0) > 0]),
        "rows": rows,
    }


def flatten_strings(value) -> list[str]:
    rows: list[str] = []
    if isinstance(value, str):
        rows.append(value)
    elif isinstance(value, list):
        for row in value:
            rows.extend(flatten_strings(row))
    elif isinstance(value, dict):
        for row in value.values():
            rows.extend(flatten_strings(row))
    return rows


class ContentLintDashboardHandler(BaseHTTPRequestHandler):
    server_version = "ContentLintDashboard/1.0"

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/api/dashboard":
            self.send_json(build_dashboard())
            return
        if parsed.path == "/api/preview":
            params = parse_qs(parsed.query)
            seed = int(params.get("seed", ["42"])[0] or 42)
            self.send_json(build_preview(seed))
            return
        if parsed.path == "/api/preview-scan":
            params = parse_qs(parsed.query)
            seed = int(params.get("seed", ["42"])[0] or 42)
            count = int(params.get("count", ["20"])[0] or 20)
            self.send_json(build_preview_scan(seed, count))
            return
        if parsed.path == "/" or parsed.path == "/index.html":
            self.serve_file(STATIC_DIR / "index.html")
            return
        if parsed.path.startswith("/static/"):
            relative = unquote(parsed.path.removeprefix("/static/"))
            self.serve_file((STATIC_DIR / relative).resolve())
            return
        self.send_error(404, "Not found")

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
        print("[content-lint-dashboard] " + format % args)


def run_server(host: str, port: int) -> None:
    server = ThreadingHTTPServer((host, port), ContentLintDashboardHandler)
    print(f"Content Lint Dashboard running at http://{host}:{port}")
    print("Press Ctrl+C to stop.")
    server.serve_forever()


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Dev-only content lint dashboard and generated preview tool")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8774)
    parser.add_argument("--validate", action="store_true", help="Run dashboard lints and exit.")
    parser.add_argument("--preview", action="store_true", help="Print generated preview JSON and exit.")
    parser.add_argument("--preview-scan", action="store_true", help="Scan generated previews across multiple seeds and exit.")
    parser.add_argument("--seed", type=int, default=42, help="Preview seed.")
    parser.add_argument("--count", type=int, default=20, help="Preview scan seed count.")
    args = parser.parse_args(argv)

    if args.validate:
        dashboard = build_dashboard()
        print(json.dumps(dashboard, ensure_ascii=False, indent=2))
        return 0 if int(dashboard.get("summary", {}).get("errors", 1)) == 0 else 1
    if args.preview:
        print(json.dumps(build_preview(args.seed), ensure_ascii=False, indent=2))
        return 0
    if args.preview_scan:
        scan = build_preview_scan(args.seed, args.count)
        print(json.dumps(scan, ensure_ascii=False, indent=2))
        return 0 if int(scan.get("total_issues", 1)) == 0 else 1

    run_server(args.host, args.port)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
