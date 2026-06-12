# Social Dialog Enhancement — Plan & Progress Log

Improves the Twooter social dialog system based on the 2026-06-12 read-only review.
**Status: not started.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** the engine is a solid, well-engineered *gating* system (deterministic text selection, visible blocked options with in-fiction reasons, soft cooldowns, stage-layered reply pools, strong writing) — but the content shape can't deliver real conversations yet: all 11 trees are ping-pong loops, replies don't acknowledge which option you picked, and the two fields a deeper system needs (`outcome`, `step_count`) are authored/tracked but consumed by nothing.

## Where everything lives

| What | Where |
|---|---|
| Dialog engine | `systems/TwooterInteractionSystem.gd` (~2,270 lines) — trees/nodes/options resolution, requirements, cooldowns, reply rendering |
| Dialog data | `data/social/twooter_feed_data.json` → `dialog_trees` (11 trees, 22 nodes, 66 options), `relationship_reply_pools`, `network_source_reply_pools`, `interaction_response_pools` |
| Branch state (saved) | `twooter_social_state.dialog_state.{accounts,posts}[key]` = `{tree_id, node_id, last_option_id, last_action_id, repeat_count, last_day_index, cooldown_until_day, cooldown_reason, step_count}` — normalized in `systems/TwooterStateSystem.gd:normalize_dialog_branch` and `TwooterInteractionSystem._normalize_dialog_branch` |
| UI | `scripts/ui/controllers/SocialController.gd` (dialog options are rows from `_tree_dialog_options`; clicks route through GameManager `interact_with_twooter_post` / `send_twooter_message`) |
| Key engine functions (line refs drift; locate by name) | `_dialog_branch` (~784), `_select_public_tree_id` (~808), `_select_message_tree_id` (~821), `_tree_dialog_options` (~869), `_dialog_option_block_reason` (~915), `_resolve_dialog_selection` (~1002), `_dialog_reply_text` (~1081), `_record_dialog_branch_progress` (~1171), `_render_dialog_pool` (~1230) |

## Working rules (same as the god-file refactor)

- One task per checkpoint commit; verify before each commit.
- Gates: `godot --headless -e --quit` → zero `SCRIPT ERROR`/`Parse Error`; quick smoke `godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` → `SMOKE_QUICK_OK normal_equity=94765318.11` exactly (smoke exercises social interaction paths and surfaces runtime Invalid-access errors).
- Tasks 1/2/3 change BEHAVIOR by design (new replies, consumed outcomes, tree endings) — the smoke equity must still match (dialog text doesn't feed price formation), but if any smoke social assertion fails, check whether the assertion or the change is wrong before "fixing" either.
- Determinism: text selection must stay `hash(seed)`-based with composed string keys; never `randi()`. New seeds should extend the existing `account|tree|option|day|counter` key style.
- Save compat: `dialog_state` branch dicts may gain NEW keys (normalizers default them) but must not rename/remove existing ones.
- The FULL smoke has a pre-existing RUPSLB failure — quick smoke is the gate. Godot CLI at `~/.local/bin/godot`.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Per-option reply pools | ~10% | ⬜ |
| 4 | Exact option matching via `option_id` | ~5% | ⬜ |
| 5 | Name tree-selection thresholds + warning hygiene | ~5% | ⬜ |
| 2 | Wire `outcome` into network bridge / credibility | ~15–20% | ⬜ |
| 3 | Tree endings via `step_count` graduation | ~15–20% | ⬜ |
| 6 | Content pass: widen hot pools, per-option replies for top trees | ~10% (mostly writing) | ⬜ |

Recommended batching: **Session 1 = tasks 1+4+5** (mechanical, ~20–25% of a usage window). **Session 2 = task 2, Session 3 = task 3** (design work; do separately, playtest each). **Task 6** rides along after 1 lands.

---

## Task 1 — Per-option reply pools (biggest feel-win per effort)

Problem: `account_replies` live on the NODE and are shared by all its options — picking "Pushback" vs "Watch only" draws the same 5-line pool, so choices feel unheard.

1. Data schema: allow an optional `account_replies: []` array on each OPTION in `dialog_trees`. Node-level pool stays as fallback.
2. Engine: in `_resolve_dialog_selection`, after `_raw_dialog_option(...)`, prefer `raw_option.get("account_replies", [])` when non-empty, else the node pool (current behavior). One change site — the selection dict's `account_replies` value.
3. `_relationship_dialog_reply_pool` keeps appending stage pools on top — unchanged.
4. Content: author per-option replies for at least the three hottest trees (`clean_intro`, `source_check`, `market_read`) — 3–5 lines per option that ACKNOWLEDGE the choice ("Good pushback — here's what would change my mind…" vs "Watching is fine, but set your trigger now…").
5. Verify: gates + manual: open Twooter, click two different options on the same account, confirm distinct reply voices.

## Task 4 — Exact option matching (small, surgical)

Problem: `_resolve_dialog_selection` re-derives the clicked option from `action_id` + `player_text` STRING EQUALITY; if the day advances between render and click, re-rendered text mismatches and it silently falls back to the first enabled row with that `action_id` — possibly a different option than displayed.

1. The option rows from `_tree_dialog_options` already carry `option_id`. Thread it through the click path: SocialController → `GameManager.interact_with_twooter_post` / `send_twooter_message` → `apply_post_interaction` / `apply_message_action` → `_apply_interaction` → `_resolve_dialog_selection` (add an `option_id: String = ""` default param at each hop; default keeps old callers working).
2. In `_resolve_dialog_selection`: when `option_id` is non-empty, match on it exactly (still verifying enabled/block state); fall back to the current action_id+text heuristic only when empty.
3. While there: two options sharing one `action_id` in a node are first-enabled-wins — with option_id matching this ambiguity disappears for UI-driven calls. Leave a one-line comment.
4. Verify: gates + grep SmokeTest for `interact_with_twooter_post`/`send_twooter_message` callers (signatures keep defaults, so no test edits expected).

## Task 5 — Threshold constants + warning hygiene

1. Extract magic numbers in `_select_public_tree_id` / `_select_message_tree_id` into named consts at the top of `TwooterInteractionSystem.gd`, 5a-style: `DIALOG_TRUST_TREE_RELATIONSHIP` (18), `DIALOG_INTRO_RELATIONSHIP_CEILING` (5), `DIALOG_THESIS_REVIEW_CREDIBILITY` (12), `DIALOG_SOURCE_CHECK_CREDIBILITY` (8), `DIALOG_TRUST_THREAD_ROWS` (4), plus the `relationship >= 8` stage-pool threshold in `_relationship_dialog_reply_pool` → `DIALOG_FAMILIAR_REPLY_RELATIONSHIP`. Values unchanged.
2. Warning hygiene in this file (it missed the `20211ee` cleanup batch): rename `seed: String` params (shadowing global `seed()`) to `seed_key` in `_render_dialog_pool`, `_dialog_option_blocked_text`, `_self_aware_player_text` and call-internal uses.
3. Optional: in `_tree_dialog_options`, the 3-option cap silently truncates via `continue` — add a `push_warning` when a node has >3 usable options (data mistake detector), and keep the cap.
4. Verify: gates only (pure rename/extract).

## Task 2 — Wire `outcome` into consequences (design work)

Problem: options author `outcome` ("source_check", "clean_read", …) in JSON; `_resolve_dialog_selection` plumbs it into the selection dict (~line 1058) and NOTHING consumes it.

1. Inventory authored outcomes first: `python3 -c "import json; d=json.load(open('data/social/twooter_feed_data.json')); print(sorted({o.get('outcome') for t in d['dialog_trees'].values() for n in t['nodes'].values() for o in n.get('options',[]) if o.get('outcome')}))"`.
2. Consumption point: `_apply_interaction` (post path) and `apply_message_action` (private path) — both already call `_apply_network_bridge` (~1476), which is the natural sink. Suggested first effects (keep small and legible):
   - `source_check` → small credibility bonus on the account_state delta, and if the account is a network source, nudge the tip-journal quality the bridge already writes.
   - `clean_read` → small relationship-progress bonus (mirrors `like_relationship_progress` mechanics).
   - Boundary-respecting outcomes in `network_insider_boundary`/`suspicious_boundary` trees → reduce `regulatory`/risk exposure or at minimum a distinct timeline entry text.
3. Record the outcome in the branch (`last_outcome`) and in the timeline row text so the player can SEE the consequence — new dict key, normalizer default `""` (save-compat rule).
4. Numbers should be constants (Task 5 style), conservative (these stack with existing gain multipliers and daily caps — check `_social_gain_multiplier` and `_daily_social_action_count` first so outcomes don't bypass the anti-grind caps).
5. Verify: gates + manual playtest of one source_check conversation confirming the visible effect; check the daily-cap path still clamps.

## Task 3 — Tree endings via `step_count` graduation (design work)

Problem: every tree topology is a loop (`source↔verify`, `probe→probe`, …) — conversations oscillate forever; `step_count` is tracked per branch and never read.

1. Data schema: optional per-tree `graduation: {steps: N, node: "finale_node_id", next_tree: "tree_id"}`. Add a terminal node per tree (a payoff: an invite, a tip pointer, a respectful close) whose options can be empty or a single "wrap up" action.
2. Engine: in `_dialog_branch` (or `_tree_dialog_options` entry), when `branch.step_count >= graduation.steps`, route `node_id` to the finale node; after the finale selection resolves, `_record_dialog_branch_progress` resets the branch to `graduation.next_tree` (entry node, `step_count` 0). The stage-based `_select_message_tree_id` already picks richer trees at higher stages — `next_tree` should usually hand off to the next stage's tree so graduation feels like progress.
3. Keep loops for ungraduated trees (no `graduation` key = current behavior, zero data migration).
4. Start with TWO trees only (`clean_intro` → graduate into `thesis_review`; `source_check` → graduate into `trust_building`), playtest the feel, then extend.
5. Verify: gates + manual: run a conversation past N steps, confirm finale fires once and the branch lands in the next tree (check `dialog_state` via the debug overlay or a temporary print).

## Task 6 — Content pass (rides along)

- Widen the most-seen pools from 5 to ~8–10 lines: `clean_intro` and `market_read` node replies, `relationship_reply_pools.familiar`, and the soft-cooldown pool in `_dialog_cooldown_reply_text` (hardcoded 3 lines — move to data while at it, keeping the hardcoded list as fallback per `_stage_reply_pool` convention).
- Keep the voice: evidence-first mentor, Indonesian market flavor, no em-dash-free constraint... follow the existing line style in the JSON.
- Per-option replies for remaining trees (Task 1 covered the top three).

## Known traps (from the god-file sessions — they apply here too)

- SmokeTest pokes UI internals: if any state key moves, grep it for BOTH `game_root.<var>` reads and `game_root.set("<var>", ...)` writes (set() silently no-ops on deleted vars).
- `validate_script` on a `class_name` file reports a spurious "hides a global script class" error — validate dependents instead.
- Editing JSON: the file is 2,364 lines — validate with `python3 -m json.tool data/social/twooter_feed_data.json > /dev/null` after every edit batch.
- Dict round-trip perf: don't introduce per-frame or per-day wrapper/copy layers in hot paths (see CompanyRuntime lesson in `GOD_FILES_ENHANCEMENT.md`).
