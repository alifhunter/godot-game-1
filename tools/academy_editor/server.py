#!/usr/bin/env python3
"""Dev-only Academy content editor server.

Uses only Python stdlib. The editable source lives next to this file and exports
to the Godot runtime catalog at data/academy/academy_catalog.json.
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
SOURCE_PATH = TOOL_DIR / "academy_source.json"
STATIC_DIR = TOOL_DIR / "static"
RUNTIME_PATH = PROJECT_ROOT / "data" / "academy" / "academy_catalog.json"
ASSET_DIR = PROJECT_ROOT / "assets" / "academy" / "lessons"
ASSET_RES_PREFIX = "res://assets/academy/lessons/"
ALLOWED_IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}


def read_json(path: Path):
    with path.open("r", encoding="utf-8") as file:
        return json.load(file)


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(payload, ensure_ascii=False, indent=2)
    path.write_text(encoded + "\n", encoding="utf-8")


def slugify(value: str, fallback: str = "academy-image") -> str:
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
    source = {
        "schema_version": 1,
        "catalog": normalize_catalog_for_source(catalog),
        "notes": "Imported from data/academy/academy_catalog.json."
    }
    return source


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
    for category in catalog.get("categories", []):
        if not isinstance(category, dict):
            continue
        for section in category.get("sections", []):
            if not isinstance(section, dict):
                continue
            if str(section.get("kind", "lesson")) != "lesson":
                continue
            blocks = section.get("content_blocks", [])
            if isinstance(blocks, list) and blocks:
                continue
            generated_blocks = []
            for page in section.get("pages", []):
                if not isinstance(page, dict):
                    continue
                generated_blocks.append({
                    "type": "text",
                    "heading": str(page.get("heading", "")),
                    "body": str(page.get("body", "")),
                    "infoboxes": [],
                    "images": []
                })
            section["content_blocks"] = generated_blocks
    return catalog


def export_runtime_catalog(source: dict) -> dict:
    catalog = normalize_catalog_for_source(source.get("catalog", {}))
    runtime = copy.deepcopy(catalog)
    for category in runtime.get("categories", []):
        if not isinstance(category, dict):
            continue
        for section in category.get("sections", []):
            if not isinstance(section, dict):
                continue
            if str(section.get("kind", "lesson")) != "lesson":
                continue
            blocks = section.get("content_blocks", [])
            if not isinstance(blocks, list) or not blocks:
                continue
            pages = []
            for block in blocks:
                if not isinstance(block, dict) or str(block.get("type", "text")) != "text":
                    continue
                heading = str(block.get("heading", "")).strip()
                body = str(block.get("body", "")).strip()
                if heading or body:
                    pages.append({"heading": heading, "body": body})
            section["pages"] = pages
    return runtime


def validate_source(source: dict) -> dict:
    errors: list[str] = []
    warnings: list[str] = []
    catalog = normalize_catalog_for_source(source.get("catalog", {}))

    category_ids: set[str] = set()
    for category_index, category in enumerate(catalog.get("categories", [])):
        if not isinstance(category, dict):
            errors.append(f"categories[{category_index}] must be an object.")
            continue
        category_id = str(category.get("id", "")).strip()
        label = category_id or f"category[{category_index}]"
        if not category_id:
            errors.append(f"{label}: category id is required.")
        elif category_id in category_ids:
            errors.append(f"{label}: category id must be unique.")
        category_ids.add(category_id)

        status = str(category.get("status", "coming_soon"))
        sections = category.get("sections", [])
        if status == "playable" and (not isinstance(sections, list) or not sections):
            errors.append(f"{label}: playable categories must have sections.")
        if not isinstance(sections, list):
            continue

        section_ids: set[str] = set()
        for section_index, section in enumerate(sections):
            if not isinstance(section, dict):
                errors.append(f"{label}: sections[{section_index}] must be an object.")
                continue
            section_id = str(section.get("id", "")).strip()
            section_label = f"{label}/{section_id or section_index}"
            if not section_id:
                errors.append(f"{section_label}: section id is required.")
            elif section_id in section_ids:
                errors.append(f"{section_label}: section id must be unique within its category.")
            section_ids.add(section_id)

            kind = str(section.get("kind", "lesson"))
            if kind == "lesson":
                validate_lesson_blocks(section, section_label, errors, warnings)
                validate_quick_checks(section, section_label, errors)

        validate_quiz(category, label, section_ids, errors)

    validate_glossary(catalog.get("glossary", []), errors)
    return {"valid": len(errors) == 0, "errors": errors, "warnings": warnings}


def validate_lesson_blocks(section: dict, section_label: str, errors: list[str], warnings: list[str]) -> None:
    blocks = section.get("content_blocks", [])
    if not isinstance(blocks, list) or not blocks:
        errors.append(f"{section_label}: lesson sections need at least one content block.")
        return
    has_useful_block = False
    for block_index, block in enumerate(blocks):
        if not isinstance(block, dict):
            errors.append(f"{section_label}: content_blocks[{block_index}] must be an object.")
            continue
        block_type = str(block.get("type", "text"))
        if block_type == "text":
            has_inline_images = validate_text_images(block, section_label, block_index, errors, warnings)
            if str(block.get("heading", "")).strip() or str(block.get("body", "")).strip() or has_inline_images:
                has_useful_block = True
            validate_infoboxes(block, section_label, block_index, errors)
            continue
        if block_type == "image":
            if not validate_image_reference(block, section_label, f"image block {block_index}", errors, warnings):
                continue
            has_useful_block = True
            continue
        if block_type == "key_insights":
            title = str(block.get("title", "")).strip()
            bullets = block.get("bullets", [])
            if not isinstance(bullets, list):
                errors.append(f"{section_label}: key insights block {block_index} bullets must be an array.")
                continue
            useful_bullets = [str(bullet).strip() for bullet in bullets if str(bullet).strip()]
            if not title and not useful_bullets:
                errors.append(f"{section_label}: key insights block {block_index} needs a title or at least one bullet.")
                continue
            has_useful_block = True
            continue
        errors.append(f"{section_label}: unsupported content block type '{block_type}'.")
    if not has_useful_block:
        errors.append(f"{section_label}: lesson sections need at least one non-empty text, image, or key insights block.")


def validate_image_reference(image: dict, section_label: str, item_label: str, errors: list[str], warnings: list[str]) -> bool:
    asset_path = str(image.get("asset_path", "")).strip()
    if not asset_path.startswith(ASSET_RES_PREFIX):
        errors.append(f"{section_label}: {item_label} must use {ASSET_RES_PREFIX}.")
        return False
    disk_path = res_path_to_disk(asset_path)
    if disk_path == None or not disk_path.exists():
        warnings.append(f"{section_label}: {item_label} points to a missing file; the game will show a placeholder.")
    return True


def validate_text_images(block: dict, section_label: str, block_index: int, errors: list[str], warnings: list[str]) -> bool:
    images = block.get("images", [])
    if images in (None, ""):
        return False
    if not isinstance(images, list):
        errors.append(f"{section_label}: text block {block_index} images must be an array.")
        return False
    has_valid_image = False
    for image_index, image in enumerate(images):
        if not isinstance(image, dict):
            errors.append(f"{section_label}: text block {block_index} image {image_index} must be an object.")
            continue
        if validate_image_reference(image, section_label, f"text block {block_index} image {image_index}", errors, warnings):
            has_valid_image = True
    return has_valid_image


def validate_infoboxes(block: dict, section_label: str, block_index: int, errors: list[str]) -> None:
    infoboxes = block.get("infoboxes", [])
    if infoboxes in (None, ""):
        return
    if not isinstance(infoboxes, list):
        errors.append(f"{section_label}: text block {block_index} infoboxes must be an array.")
        return
    for infobox_index, infobox in enumerate(infoboxes):
        if not isinstance(infobox, dict):
            errors.append(f"{section_label}: text block {block_index} infobox {infobox_index} must be an object.")
            continue
        title = str(infobox.get("title", "")).strip()
        body = str(infobox.get("body", "")).strip()
        if not title and not body:
            errors.append(f"{section_label}: text block {block_index} infobox {infobox_index} needs a title or body.")


def validate_quick_checks(section: dict, section_label: str, errors: list[str]) -> None:
    check_ids: set[str] = set()
    for check_index, check in enumerate(section.get("checks", [])):
        if not isinstance(check, dict):
            errors.append(f"{section_label}: checks[{check_index}] must be an object.")
            continue
        check_id = str(check.get("id", "")).strip()
        check_label = f"{section_label}/check:{check_id or check_index}"
        if not check_id:
            errors.append(f"{check_label}: quick check id is required.")
        elif check_id in check_ids:
            errors.append(f"{check_label}: quick check id must be unique in its section.")
        check_ids.add(check_id)
        if not str(check.get("question", "")).strip():
            errors.append(f"{check_label}: question is required.")
        options = check.get("options", [])
        if not isinstance(options, list) or len(options) < 2:
            errors.append(f"{check_label}: at least two options are required.")
            continue
        correct_count = 0
        option_ids: set[str] = set()
        for option_index, option in enumerate(options):
            if not isinstance(option, dict):
                errors.append(f"{check_label}: option {option_index} must be an object.")
                continue
            option_id = str(option.get("id", "")).strip()
            if not option_id or option_id in option_ids:
                errors.append(f"{check_label}: option ids must be unique and non-empty.")
            option_ids.add(option_id)
            if not str(option.get("label", "")).strip():
                errors.append(f"{check_label}: option {option_id or option_index} label is required.")
            if not str(option.get("feedback", "")).strip():
                errors.append(f"{check_label}: option {option_id or option_index} feedback is required.")
            if bool(option.get("correct", False)):
                correct_count += 1
        if correct_count != 1:
            errors.append(f"{check_label}: exactly one option must be correct.")


def validate_quiz(category: dict, category_label: str, section_ids: set[str], errors: list[str]) -> None:
    if "quiz_passing_score" in category:
        passing_score = float(category.get("quiz_passing_score", -1))
        if passing_score < 0.0 or passing_score > 1.0:
            errors.append(f"{category_label}: quiz_passing_score must be between 0 and 1.")
    for required_id in category.get("quiz_required_section_ids", []):
        if str(required_id) not in section_ids:
            errors.append(f"{category_label}: required quiz section '{required_id}' does not exist.")

    question_ids: set[str] = set()
    for question_index, question in enumerate(category.get("quiz_questions", [])):
        if not isinstance(question, dict):
            errors.append(f"{category_label}: quiz question {question_index} must be an object.")
            continue
        question_id = str(question.get("id", "")).strip()
        question_label = f"{category_label}/quiz:{question_id or question_index}"
        if not question_id:
            errors.append(f"{question_label}: question id is required.")
        elif question_id in question_ids:
            errors.append(f"{question_label}: question id must be unique.")
        question_ids.add(question_id)
        if not str(question.get("prompt", "")).strip():
            errors.append(f"{question_label}: prompt is required.")
        options = question.get("options", [])
        if not isinstance(options, list) or len(options) < 2:
            errors.append(f"{question_label}: at least two options are required.")
            continue
        option_ids = {str(option.get("id", "")).strip() for option in options if isinstance(option, dict)}
        correct_answer_id = str(question.get("correct_answer_id", "")).strip()
        if correct_answer_id not in option_ids:
            errors.append(f"{question_label}: correct_answer_id must match an option id.")
        if not str(question.get("feedback_correct", "")).strip():
            errors.append(f"{question_label}: feedback_correct is required.")
        if not str(question.get("feedback_wrong", "")).strip():
            errors.append(f"{question_label}: feedback_wrong is required.")


def validate_glossary(glossary, errors: list[str]) -> None:
    if not isinstance(glossary, list):
        errors.append("glossary must be an array.")
        return
    seen_terms: set[str] = set()
    for index, row in enumerate(glossary):
        if not isinstance(row, dict):
            errors.append(f"glossary[{index}] must be an object.")
            continue
        term = str(row.get("term", "")).strip()
        if not term:
            errors.append(f"glossary[{index}]: term is required.")
        elif term.lower() in seen_terms:
            errors.append(f"glossary[{index}]: term must be unique.")
        seen_terms.add(term.lower())
        if not str(row.get("definition", "")).strip():
            errors.append(f"glossary[{index}]: definition is required.")


class AcademyEditorHandler(BaseHTTPRequestHandler):
    server_version = "AcademyEditor/1.0"

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
        filename = str(payload.get("filename", "academy-image.png"))
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
        if disk_path == None or not disk_path.exists():
            self.send_error(404, "Asset not found")
            return
        self.serve_file(disk_path)

    def serve_file(self, path: Path) -> None:
        try:
            resolved = path.resolve()
            if STATIC_DIR.resolve() not in resolved.parents and PROJECT_ROOT.resolve() not in resolved.parents:
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
        print("[academy-editor] " + format % args)


def run_server(host: str, port: int) -> None:
    server = ThreadingHTTPServer((host, port), AcademyEditorHandler)
    print(f"Academy editor running at http://{host}:{port}")
    print("Press Ctrl+C to stop.")
    server.serve_forever()


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Dev-only Academy content editor")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
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
