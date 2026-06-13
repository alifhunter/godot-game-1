# Twooter Interaction System Enhancement - Plan & Progress Log

Improves the Twooter interaction engine after the social dialog content pass.
**Status: complete - Tasks 1-6 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** `TwooterInteractionSystem.gd` is doing the right job as the rules engine for authored Twooter content. It loads `twooter_feed_data.json`, enriches snapshots, routes public/private dialog trees, resolves selected options, applies consequences, and bridges some outcomes into Network. The next risk is not missing content, but reachability and maintainability: some authored trees are only reachable through profile preferences, routing is still mostly hardcoded, outcomes are conservative, fallback trees can drift from JSON, and the file owns too many responsibilities.

## Where everything lives

| What | Where |
|---|---|
| Interaction engine | `systems/TwooterInteractionSystem.gd` - action definitions, minimal emergency fallback dialog tree, snapshot enrichment, option resolution, reply rendering, Network bridge, state normalization, and stable delegate wrappers for routing/outcomes |
| Dialog router | `systems/TwooterDialogRouter.gd` - public/private tree selection, data-driven routing rules, profile preferences, branch normalization, surface validation, and graduation handoff checks |
| Outcome resolver | `systems/TwooterOutcomeResolver.gd` - dialog outcome effect dictionaries, labels, timeline notes, timeline text composition, and Network confidence labels |
| Dialog data | `data/social/twooter_feed_data.json` -> `dialog_routing`, `dialog_trees` (11 trees, 25 nodes, 71 options), `relationship_reply_pools`, `network_source_reply_pools`, `soft_cooldown_reply_pool`, `interaction_response_pools` |
| Content source/editor | `tools/twooter_editor/twooter_source.json` and `tools/twooter_editor/server.py` - editor-side source and validation for exported Twooter content |
| Runtime state | `twooter_social_state` in `RunState` -> account states, post interactions, liked posts, message rows, Network contact definitions, `dialog_state.{accounts,posts}` |
| Save normalizer | `systems/TwooterStateSystem.gd` and `TwooterInteractionSystem.normalize_social_state` |
| Entry points | `autoloads/GameManager.gd` passes `DataRepository.get_twooter_feed_data()` into `TwooterInteractionSystem` for snapshots, public replies, private messages, and message-thread options |
| Network-generated accounts | `systems/ContactNetworkSystem.gd:_contact_twooter_dialog_trees` assigns Network-contact preferred dialog tree lists |
| Key engine functions (line refs drift; locate by name) | `_dialog_trees` (~806), `_dialog_branch` (~854), `_select_public_tree_id` (~881), `_select_message_tree_id` (~894), `_profile_preferred_tree_id` (~921), `_tree_dialog_options` (~942), `_record_dialog_branch_progress` (~1284), `_dialog_outcome_effect` (~1320), `_apply_network_bridge` (~1677), `normalize_social_state` (~597) |

## Working rules

- One task per checkpoint commit; verify before each commit.
- Gates: `python3 -m json.tool data/social/twooter_feed_data.json > /dev/null` after JSON edits; `git diff --check`; `/Users/user/.local/bin/godot --headless -e --quit`; quick smoke `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`.
- If editing `tools/twooter_editor/twooter_source.json`, validate/export with the Twooter editor workflow instead of editing only runtime JSON.
- Determinism: text and routing choices must remain deterministic. Keep `hash(seed_key)` style for text selection and stable day/account/tree keys for audits. Do not introduce `randi()` into dialog routing.
- Save compat: branch/account/message dictionaries may gain new keys only when both normalizers default them. Do not rename/remove existing saved keys.
- Behavior tasks should add targeted probes before broad smoke. Prefer temporary probe scripts for one-off verification and delete them before finalizing.
- The full smoke has a known pre-existing RUPSLB issue; quick smoke is the gate unless the task specifically targets full UI coverage.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Dialog reachability audit and instrumentation | ~10-15% | Complete |
| 2 | Network tree progression and profile routing | ~15-20% | Complete |
| 3 | Data-driven routing rules | ~20-30% | Complete |
| 4 | Outcome consequence expansion | ~15-20% | Complete |
| 5 | Default dialog fallback cleanup | ~5-10% | Complete |
| 6 | System boundary split | ~25-35% | Complete |

Recommended batching: **Session 1 = Task 1** (instrumentation and proof, low behavior risk). **Session 2 = Task 2** (Network-source reachability design). **Session 3 = Task 4** (small consequence expansion with targeted probes). **Session 4 = Task 3** (data-driven routing; higher blast radius). **Task 5** can ride with any content-source cleanup. **Task 6** should wait until routing/outcomes stabilize.

## Progress log

### 2026-06-13 - Plan created

- Created this enhancement plan from the post-social-dialog review.
- Current inventory:
  - `twooter_feed_data.json` has 11 dialog trees, 24 nodes, 68 options.
  - Only `clean_intro` and `source_check` currently have authored `graduation` metadata.
  - Network-specific trees exist in JSON and are selected through generated account `social_profile.dialog_trees`, not by direct hardcoded names in `_select_message_tree_id`.
- No code or data changes were made by this planning step.

### 2026-06-13 - Task 1 complete

- Added `scripts/tests/TwooterDialogReachabilityTest.gd` and `scenes/tests/TwooterDialogReachabilityTest.tscn`.
- The audit is test-only and does not add saved runtime state or player-facing UI.
- Coverage:
  - Private trees: `clean_intro`, `thesis_review`, `trust_building`, `event_invite`, `suspicious_boundary`, `network_source_followup`, `network_relationship_probe`, `network_insider_boundary`, `network_guarded_source`.
  - Public trees: `market_read`, `source_check`, `trust_building`.
  - Captures offered tree ids, selected option ids, blocked option rows, cooldown rows, and graduation completion.
- Baseline finding: `network_relationship_probe` is renderable and selectable when pre-selected as the active/preferred tree. Task 2 remains responsible for real progression from secondary Network profile lists.
- Verification:
  - `python3 -m json.tool data/social/twooter_feed_data.json > /dev/null`
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterDialogReachabilityTest.tscn` -> `TWOOTER_DIALOG_REACHABILITY_OK`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`

### 2026-06-13 - Task 2 complete

- Added a data-authored graduation on `network_source_followup`:
  - after 3 clean source-followup steps, the tree presents `relationship_handoff`
  - selecting a handoff option graduates the saved branch into `network_relationship_probe`
- Mirrored the new graduation and handoff node in both `data/social/twooter_feed_data.json` and `tools/twooter_editor/twooter_source.json`.
- Added `scripts/tests/TwooterNetworkProgressionTest.gd` and `scenes/tests/TwooterNetworkProgressionTest.tscn`.
- Profile inventory from `ContactNetworkSystem._contact_twooter_dialog_trees`:
  - reporter -> `network_source_followup`, `network_relationship_probe`, `source_check`
  - analyst -> `network_source_followup`, `network_relationship_probe`, `thesis_review`
  - floater -> `network_source_followup`, `network_relationship_probe`, `source_check`
  - insider -> `network_insider_boundary`, `network_source_followup`, `source_check`
  - suspicious -> `network_guarded_source`, `suspicious_boundary`, `source_check`
- Verification result:
  - reporter, analyst, and floater first show `network_source_followup`, complete the handoff, and persist `network_relationship_probe`
  - insider and suspicious profiles remain on their boundary trees, including after synthetic high step counts
- Verification:
  - `python3 -m json.tool data/social/twooter_feed_data.json > /dev/null`
  - `python3 -m json.tool tools/twooter_editor/twooter_source.json > /dev/null`
  - `python3 tools/twooter_editor/server.py --validate`
  - `python3 tools/twooter_editor/server.py --export --dry-run`
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterNetworkProgressionTest.tscn` -> `TWOOTER_NETWORK_PROGRESSION_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterDialogReachabilityTest.tscn` -> `TWOOTER_DIALOG_REACHABILITY_OK`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`

### 2026-06-13 - Task 3 complete

- Added optional `dialog_routing.public_rules` and `dialog_routing.private_rules` to the authored Twooter feed data.
- Runtime routing now checks ordered data rules before falling back to the previous hardcoded selection behavior.
- Supported routing conditions:
  - `risk_profile`
  - `network_source`
  - `relationship_lt` / `relationship_gte`
  - `credibility_lt` / `credibility_gte`
  - `relationship_stage`
  - `thread_rows_gte`
  - `post_category_contains_any`
- Added special `tree_id: "profile_preferred"` support so data rules can still resolve generated Network/contact profile tree preferences.
- Mirrored the routing config in both `data/social/twooter_feed_data.json` and `tools/twooter_editor/twooter_source.json`.
- Extended `tools/twooter_editor/server.py` validation so bad routing rules, invalid condition keys/types, missing tree ids, and surface mismatches fail editor validation.
- Added `scripts/tests/TwooterRoutingRulesTest.gd` and `scenes/tests/TwooterRoutingRulesTest.tscn`.
- Verification:
  - `python3 -m json.tool data/social/twooter_feed_data.json > /dev/null`
  - `python3 -m json.tool tools/twooter_editor/twooter_source.json > /dev/null`
  - `python3 tools/twooter_editor/server.py --validate`
  - `python3 tools/twooter_editor/server.py --export --dry-run`
  - `PYTHONPYCACHEPREFIX=/private/tmp/godot_pycache python3 -m py_compile tools/twooter_editor/server.py`
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterRoutingRulesTest.tscn` -> `TWOOTER_ROUTING_RULES_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterDialogReachabilityTest.tscn` -> `TWOOTER_DIALOG_REACHABILITY_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterNetworkProgressionTest.tscn` -> `TWOOTER_NETWORK_PROGRESSION_OK`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`

### 2026-06-13 - Task 4 complete

- Expanded outcome mechanics in `TwooterInteractionSystem.gd` for the previously mostly-visible outcomes:
  - `thesis_response` now adds a small credibility outcome bump only when a shareable thesis was actually selected.
  - `contact_discovery` now adds a small Network lead-quality bump for Network-source accounts.
  - `event_invite` now adds a small relationship bump and logs an event opportunity flag.
- Kept outcome effects on the existing `gain_multiplier` path, including the same-day repeat no-op path.
- Tightened the existing thesis grade bonus so it also respects the same social gain multiplier instead of bypassing same-day caps.
- Extended timeline and Network journal notes so the mechanical effect is visible instead of hidden:
  - journal rows now store outcome relationship, credibility, contact-discovery, event-invite, and thesis-response metadata.
  - confidence labels now identify contact discovery, thesis review, and event invite outcomes.
- Added `scripts/tests/TwooterOutcomeConsequencesTest.gd` and `scenes/tests/TwooterOutcomeConsequencesTest.tscn`.
- Verification:
  - `python3 -m json.tool data/social/twooter_feed_data.json > /dev/null`
  - `python3 -m json.tool tools/twooter_editor/twooter_source.json > /dev/null`
  - `python3 tools/twooter_editor/server.py --validate`
  - `python3 tools/twooter_editor/server.py --export --dry-run`
  - `PYTHONPYCACHEPREFIX=/private/tmp/godot_pycache python3 -m py_compile tools/twooter_editor/server.py`
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterOutcomeConsequencesTest.tscn` -> `TWOOTER_OUTCOME_CONSEQUENCES_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterRoutingRulesTest.tscn` -> `TWOOTER_ROUTING_RULES_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterNetworkProgressionTest.tscn` -> `TWOOTER_NETWORK_PROGRESSION_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterDialogReachabilityTest.tscn` -> `TWOOTER_DIALOG_REACHABILITY_OK`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`

### 2026-06-13 - Task 5 complete

- Reduced `DEFAULT_DIALOG_TREES` from a multi-tree legacy content copy to one emergency `clean_intro` tree.
- The fallback tree keeps only enough content for safe degraded operation:
  - one private action path
  - one public reply path
  - source-check and clean-read outcome coverage
- Added `FALLBACK_DIALOG_TREE_ID` and exact tree lookup so missing profile/routing tree ids no longer count as valid just because `clean_intro` exists.
- `_dialog_branch` now normalizes missing selected tree ids to `clean_intro`, including stale saved branches.
- Runtime JSON loading remains unchanged: `_dialog_trees(feed_data)` still uses authored `dialog_trees` whenever they are present.
- Added `scripts/tests/TwooterFallbackDialogTest.gd` and `scenes/tests/TwooterFallbackDialogTest.tscn`.
- Verification:
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterFallbackDialogTest.tscn` -> `TWOOTER_FALLBACK_DIALOG_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterRoutingRulesTest.tscn` -> `TWOOTER_ROUTING_RULES_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterOutcomeConsequencesTest.tscn` -> `TWOOTER_OUTCOME_CONSEQUENCES_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterNetworkProgressionTest.tscn` -> `TWOOTER_NETWORK_PROGRESSION_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterDialogReachabilityTest.tscn` -> `TWOOTER_DIALOG_REACHABILITY_OK`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`

### 2026-06-13 - Task 6 complete

- Extracted `systems/TwooterDialogRouter.gd`.
- `TwooterDialogRouter.gd` now owns:
  - public/private tree selection
  - data-driven routing rule matching
  - profile preferred tree lookup
  - tree surface validation
  - dialog branch normalization
  - graduation metadata and graduation node handoff checks
- Extracted `systems/TwooterOutcomeResolver.gd`.
- `TwooterOutcomeResolver.gd` now owns:
  - outcome effect dictionaries
  - outcome labels
  - timeline/journal note text
  - timeline text composition
  - Network confidence labels
- `TwooterInteractionSystem.gd` keeps thin delegate wrappers so internal call sites, `GameManager` APIs, fallback data, Network bridge behavior, and saved branch shape remain stable.
- Deferred `TwooterDialogRenderer.gd` and a dedicated state normalizer because rendering/template selection and save normalization have broader coupling than routing/outcomes. They remain future candidates, not required for this stabilized split.
- Verification:
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterOutcomeConsequencesTest.tscn` -> `TWOOTER_OUTCOME_CONSEQUENCES_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterRoutingRulesTest.tscn` -> `TWOOTER_ROUTING_RULES_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterFallbackDialogTest.tscn` -> `TWOOTER_FALLBACK_DIALOG_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterNetworkProgressionTest.tscn` -> `TWOOTER_NETWORK_PROGRESSION_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterDialogReachabilityTest.tscn` -> `TWOOTER_DIALOG_REACHABILITY_OK`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`

### 2026-06-13 - Additional Task 6 drift-risk cleanup

- Removed duplicated pure helper bodies left behind by the boundary split.
- `TwooterInteractionSystem._relationship_stage()` now delegates to `TwooterDialogRouter.relationship_stage()` so saved relationship-stage labels and routing-rule thresholds share one implementation.
- `TwooterInteractionSystem._is_network_source_account()` now delegates to `TwooterOutcomeResolver.is_network_source_account()`.
- `TwooterDialogRouter.gd` also delegates network-source classification to `TwooterOutcomeResolver.gd` instead of keeping inline duplicate checks.
- Verification:
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterRoutingRulesTest.tscn` -> `TWOOTER_ROUTING_RULES_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterOutcomeConsequencesTest.tscn` -> `TWOOTER_OUTCOME_CONSEQUENCES_OK`
  - `/Users/user/.local/bin/godot --headless -e --quit`

---

## Task 1 - Dialog Reachability Audit And Instrumentation

Problem: all dialog trees are authored and valid, but not all are proven reachable in normal play. In particular, `_profile_preferred_tree_id` returns the first valid profile tree, so secondary trees such as `network_relationship_probe` may rarely or never appear unless another system moves the branch there.

1. Add a focused audit path that can run without UI and report:
   - tree ids offered in public reply options
   - tree ids offered in private message options
   - selected option ids
   - blocked option ids and block reasons
   - graduations triggered
   - soft cooldowns triggered
2. Prefer a test scene or test script over permanent player-facing UI. A good target is a `TwooterDialogReachabilityTest` that creates representative accounts/states and calls `get_twooter_message_thread()` / `get_twooter_snapshot()`.
3. Cover these scenarios:
   - regular account, low relationship -> `clean_intro`
   - regular account, public market post -> `market_read`
   - source/corporate public post -> `source_check`
   - higher relationship/credibility -> `thesis_review`, `trust_building`, `event_invite`
   - suspicious profile -> `suspicious_boundary`
   - Network contact insider -> `network_insider_boundary`
   - Network contact suspicious/noisy -> `network_guarded_source`
   - Network contact analyst/reporter/floater -> `network_source_followup`
   - secondary Network relationship tree -> `network_relationship_probe`
4. Decide whether instrumentation is test-only or a runtime debug summary. If runtime, store it outside saved game state or behind a debug-only path.
5. Verify:
   - targeted reachability test prints a compact success line with every expected tree id
   - gates
   - quick smoke remains exact

## Task 2 - Network Tree Progression And Profile Routing

Problem: generated Network-contact accounts get a preferred tree list, but the current selector only chooses the first valid private tree. Secondary trees in the list are not stage-aware, so the profile list behaves more like a fallback list than a progression list.

1. Inventory current generated profile lists from `ContactNetworkSystem._contact_twooter_dialog_trees`.
2. Add a small progression rule for Network contacts. Candidate approaches:
   - relationship/credibility thresholds choose later profile trees
   - branch `step_count` or `last_outcome` can advance from `network_source_followup` to `network_relationship_probe`
   - data-authored `graduation` metadata can hand off from one Network tree to another
3. Start with minimal behavior:
   - `network_source_followup` can graduate into `network_relationship_probe` for reporters/analysts/floaters.
   - `network_insider_boundary` and `network_guarded_source` should not bypass their boundary tree too quickly.
4. Keep suspicious and insider safety first. Boundary trees should remain dominant when `risk_profile == "suspicious"` or affiliation type is insider.
5. Verify:
   - targeted Network-contact probe shows first tree, then second tree after progression
   - Network source route still passes the SmokeTest News -> Twooter checks
   - gates

## Task 3 - Data-Driven Routing Rules

Problem: `_select_public_tree_id` and `_select_message_tree_id` still hardcode most routing thresholds and tree ids. This works, but it means tuning social progression requires engine edits instead of data edits.

1. Add optional routing config under `twooter_feed_data.json`, for example:
   - `dialog_routing.public_rules`
   - `dialog_routing.private_rules`
   - threshold names such as `intro_relationship_ceiling`, `thesis_review_credibility`, `trust_relationship`, `trust_thread_rows`
2. Keep existing constants as fallback defaults. If the JSON config is absent or invalid, current behavior must remain unchanged.
3. Support only simple conditions first:
   - `risk_profile`
   - `network_source`
   - `relationship_lt/gte`
   - `credibility_lt/gte`
   - `relationship_stage`
   - `thread_rows_gte`
   - post category contains any of a configured list
4. Avoid building a generic scripting language. Use a small, explicit matcher that is easy to validate.
5. Add validation to the Twooter editor for referenced tree ids and threshold value types.
6. Verify:
   - targeted routing probe with default data matches current hardcoded outputs
   - targeted routing probe with temporary override proves JSON routing can change selection
   - JSON validation, editor validation, gates, quick smoke

## Task 4 - Outcome Consequence Expansion

Problem: outcomes now exist and some have effects, but `contact_discovery`, `event_invite`, and `thesis_response` are mostly visible/logging outcomes. The player can choose better social behavior without always seeing meaningful mechanical texture.

1. Inventory current outcomes and where they appear:
   - `source_check`
   - `clean_read`
   - `suspicious_boundary`
   - `contact_discovery`
   - `event_invite`
   - `thesis_response`
2. Add conservative effects with constants:
   - `thesis_response`: small credibility bump only when a shareable thesis was actually selected.
   - `contact_discovery`: small Network lead-quality or contact-intro nudge when the account is a Network source.
   - `event_invite`: unlock/log a social room opportunity, or add a future Network request hook, but avoid free money.
3. Preserve daily anti-grind caps. Outcome effects must continue to flow through the same multiplier/cap path used by base action deltas.
4. Make effects visible in timeline/journal text. A hidden number change is not enough.
5. Verify:
   - targeted probe per new effect
   - same-day repeat still clamps or no-ops as intended
   - gates and quick smoke

## Task 5 - Default Dialog Fallback Cleanup

Problem: `DEFAULT_DIALOG_TREES` is a large hardcoded fallback that can drift from `twooter_feed_data.json`. It is useful as an emergency fallback, but it should not look like a second source of truth.

1. Decide the desired fallback policy:
   - tiny emergency `clean_intro` only
   - generated fallback from editor source
   - keep current fallback but mark as minimal legacy fallback
2. If reducing the fallback, keep enough content for:
   - one private action path
   - one public reply path
   - no script errors if JSON fails to load
3. Add a test or probe that temporarily passes `{}` as feed data and confirms the fallback still produces valid options.
4. Do not remove runtime JSON loading. `_dialog_trees(feed_data)` should still prefer authored data.
5. Verify:
   - fallback probe
   - editor parse
   - quick smoke

## Task 6 - System Boundary Split

Problem: `TwooterInteractionSystem.gd` owns too many responsibilities: state normalization, routing, option building, text rendering, consequence resolution, Network bridge, and fallback content. The file is still workable, but future changes will become slower and riskier.

1. Split only after Tasks 1-4 make behavior clearer. Do not refactor while routing semantics are still moving.
2. Candidate extracted files:
   - `TwooterDialogRouter.gd` for `_select_*`, `_dialog_branch`, graduation, profile preferences
   - `TwooterDialogRenderer.gd` for `_render_dialog_pool`, template rendering, blocked/player/account line selection
   - `TwooterOutcomeResolver.gd` for `_dialog_outcome_effect`, labels, timeline notes
   - `TwooterSocialStateNormalizer.gd` only if it can share logic cleanly with `TwooterStateSystem.gd`
3. Keep public `GameManager` APIs unchanged.
4. Move one responsibility at a time. After each extraction, run the gates before moving the next one.
5. Avoid new allocation-heavy wrapper layers in daily simulation or snapshot hot paths.
6. Verify:
   - editor parse after every extraction
   - targeted dialog tests from Task 1
   - quick smoke
   - optional 225-day `MarketYearAudit` after the final split

## Known traps

- `DEFAULT_DIALOG_TREES` is fallback, not the main content path. Runtime JSON is loaded by `DataRepository` and passed into `TwooterInteractionSystem` by `GameManager`.
- Network-specific trees are selected through generated `social_profile.dialog_trees`; static JSON accounts currently do not declare those lists.
- `_profile_preferred_tree_id` returns the first valid tree. Adding more ids to a profile list does not automatically create progression.
- The visible option limit is 3. More usable options in a node are hidden and should trigger the existing warning.
- `option_id` must stay threaded through UI -> `GameManager` -> `TwooterInteractionSystem`; falling back to text/action matching can reintroduce stale-click bugs.
- Branch state is saved. Any new branch keys must be defaulted in both normalizers.
- JSON content edits should keep `tools/twooter_editor/twooter_source.json` and `data/social/twooter_feed_data.json` in sync when the editor source is being used.
- SmokeTest reads UI internals directly. If controller/root state names move, grep for both direct property reads and `set("<name>", ...)` calls.
- Long-run audits can be slow because event history/state grows. Use targeted probes first, quick smoke second, and `MarketYearAudit` only when behavior or performance risk justifies it.
