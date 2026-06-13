# [Feature/System Name] Enhancement - Plan & Progress Log

[One short paragraph explaining what this work improves and why it matters.]
**Status: planned - Tasks 1-N not started.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** [Summarize the review finding or product need in 2-4 sentences. Be specific about what is already working, what risk remains, and what this plan is meant to change.]

## Where everything lives

| What | Where |
|---|---|
| Primary runtime owner | `[path/to/main_file.gd]` - [responsibilities it currently owns] |
| Data/config | `[path/to/data_or_config.json]` - [schema or content owned here] |
| UI entry point | `[path/to/controller_or_scene.gd]` - [how the player reaches it] |
| Runtime state | `[state key / RunState field]` - [saved state shape and normalizer owner] |
| Tests/probes | `[path/to/test_scene_or_script]` - [existing or planned coverage] |
| Editor/source tooling | `[path/to/tool]` - [only if content is generated or validated elsewhere] |
| Key functions (line refs drift; locate by name) | `[function_a]`, `[function_b]`, `[function_c]` |

## Goals

- [Primary measurable improvement.]
- [Secondary improvement.]
- [Player-facing or developer-facing outcome.]

## Non-goals

- [Explicitly out-of-scope work.]
- [Risky adjacent refactor that should not ride along.]

## Working rules

- One task per checkpoint commit; verify before each commit.
- Keep edits scoped to the task. Do not mix behavior changes, content changes, and refactors unless the task says so.
- Gates:
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
- If editing JSON, also run: `python3 -m json.tool [path/to/file.json] > /dev/null`
- If editing generated/exported content, update the source file and run the source tool validation/export path. Do not edit only the runtime output.
- Determinism: keep simulation, routing, text choice, and test probes stable. Prefer existing seed-key/hash patterns over random calls.
- Save compatibility: new saved keys must have normalizer defaults. Do not rename or remove saved keys without a migration plan.
- Behavior tasks should add targeted probes before broad smoke. Prefer committed test scenes for durable coverage; use temporary probes only for one-off investigation and delete them before finalizing.
- The full smoke has known pre-existing coverage/layout issues in some flows; quick smoke is the standard gate unless this task specifically targets full UI coverage.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | [Task title] | ~5-15% | Not started |
| 2 | [Task title] | ~10-20% | Not started |
| 3 | [Task title] | ~15-30% | Not started |

Recommended batching: **Session 1 = Task 1** ([why it is the right first slice]). **Session 2 = Task 2** ([dependency or risk note]). **Task 3** should wait until [stabilizing condition].

## Progress log

### [YYYY-MM-DD] - Plan created

- Created this enhancement plan from [review/source/request].
- Current inventory:
  - [Important count or fact.]
  - [Important count or fact.]
  - [Known baseline behavior.]
- No code or data changes were made by this planning step.

### [YYYY-MM-DD] - Task 1 complete

- [What changed.]
- [What stayed intentionally unchanged.]
- Verification:
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`

---

## Task 1 - [Task Title]

Problem: [State the specific problem this task solves. Keep it narrow enough that completion is obvious.]

1. [Concrete implementation step.]
2. [Concrete implementation step.]
3. [Concrete implementation step.]
4. Verify:
   - [Targeted test/probe and expected sentinel.]
   - [JSON/tooling validation if relevant.]
   - gates and quick smoke.

## Task 2 - [Task Title]

Problem: [State the next specific problem.]

1. [Concrete implementation step.]
2. [Concrete implementation step.]
3. [Compatibility or determinism constraint.]
4. Verify:
   - [Targeted test/probe and expected sentinel.]
   - gates and quick smoke.

## Task 3 - [Task Title]

Problem: [State the next specific problem.]

1. [Concrete implementation step.]
2. [Concrete implementation step.]
3. [Risk-control step: add coverage, feature flag, migration, or fallback.]
4. Verify:
   - [Targeted test/probe and expected sentinel.]
   - optional long-run audit if behavior/performance risk justifies it.
   - gates and quick smoke.

## Known traps

- SmokeTest pokes some UI internals directly. If controller/root state names move, grep for both direct property reads and `set("<name>", ...)` calls.
- Godot `validate_script` can produce misleading class-name warnings on some standalone files; confirm with dependent scripts or the headless editor gate.
- Dict round-trip perf matters in daily simulation and snapshot hot paths. Do not add wrapper/copy layers there without measuring.
- Runtime JSON and editor/source JSON can drift. Keep source and exported runtime data in sync when the feature owns authored content.
- Branch/account/message dictionaries are saved. Any added keys need defaults in every normalizer path.
- Long-run audits can be slow because event history/state grows. Use targeted probes first, quick smoke second, and longer audits only when the task changes simulation behavior.
