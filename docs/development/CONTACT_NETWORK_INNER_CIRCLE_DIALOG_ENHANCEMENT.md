# Contact Network Inner-Circle Dialog Enhancement - Plan & Progress Log

Builds a staged relationship/dialog progression for Network contacts so private conversations deepen gradually, high-privacy contacts are reached through referrals instead of public News exposure, and true inner-circle contacts can give structured direct trade guidance only when the player has earned that access.
**Status: Tasks 1-6 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** The current system already has Network contact relationship points, Twooter relationship stages, generated Network-source accounts, deterministic tip resolution, and working bridge tests. The gap is progression design: named stages do not yet own fully distinct dialog option sets, high-recognition contacts can still be surfaced through News/source discovery paths in tests, and inner-circle `ask_tip` replies remain process/source-check flavored instead of using a structured high-trust direct tip payload. This plan turns that into a privacy-preserving progression system: low/mid contacts introduce the player upward, stage-specific dialog options unlock gradually, and direct tips are gated by inner-circle access plus deterministic contact/tip data.

## Where everything lives

| What | Where |
|---|---|
| Primary runtime owner | `systems/ContactNetworkSystem.gd` - public facade for Network discovery, meetings, tips, referrals, relationship mutation, snapshot rows, and Network -> Twooter account synthesis |
| Network helper modules | `systems/NetworkDiscovery.gd` - discovery limits and meeting scoring; `systems/NetworkContactPresenter.gd` - contact rows and generated Network Twooter accounts; `systems/NetworkTipResolver.gd` - tip outcome scoring, follow-up/source-check/direct-read text; `systems/NetworkJournalBuilder.gd` - journal rows |
| Twooter dialog owner | `systems/TwooterInteractionSystem.gd` - private message options, send handling, relationship/stage updates, Network bridge writes; `systems/TwooterDialogRouter.gd` - stage/routing rules; `systems/TwooterOutcomeResolver.gd` - dialog outcome effects |
| Data/config | `data/network/contact_network_data.json` - contacts, recognition requirements, base relationships, meeting lead profiles, tip/request templates; `data/social/twooter_feed_data.json` - dialog routing, trees, option text, reply pools, outcome-bearing dialog options |
| UI entry points | `scripts/ui/controllers/NetworkController.gd` - Network app; Twooter UI/controller paths should be located with `rg "SocialMessage|Twooter|dialog_options" scripts/ui` before implementation |
| Runtime state | `RunState.network_contacts`, `network_discoveries`, `network_requests`, `network_tip_journal`, and `twooter_social_state.account_states/messages/dialog_state`; saved-state defaults must be owned by current RunState/Twooter normalizer paths |
| Tests/probes | Current baselines: `NetworkSnapshotAuditTest`, `NetworkThirtyDayScenarioTest`, `NetworkHighRecognitionScenarioTest`, `TwooterRoutingRulesTest`, `TwooterDialogReachabilityTest`, `TwooterNetworkProgressionTest`, `TwooterOutcomeConsequencesTest`; planned new coverage listed below |
| Reference docs/logs | `docs/development/CONTACT_NETWORK_SYSTEM_ENHANCEMENT.md`, `docs/development/TWOOTER_INTERACTION_SYSTEM_ENHANCEMENT.md`, `docs/development/test_log/2026-06-13_contact_network_high_recognition.md` |
| Key functions (line refs drift; locate by name) | `ContactNetworkSystem.discover_network_contacts_from_article`, `discover_network_contacts_for_company`, `request_tip`, `build_twooter_accounts`, `_adjust_relationship`; `TwooterInteractionSystem.get_message_thread`, `apply_message_action`, `_message_dialog_options`, `_tree_dialog_options`; `TwooterDialogRouter.select_message_tree_id`, `relationship_stage` |

## Goals

- Make private Network-source dialog options visibly progress by relationship stage: stranger -> familiar -> trusted -> inner-circle candidate.
- Expand each stage into a richer option pool, not just a different reply tone: target 4-6 authored options per stage, with at least 3 visible/enabled in normal conditions.
- Prevent high-privacy inner-circle contacts from being directly exposed by public News/source leads; require referral paths from suitable mid/high recognition contacts.
- Add deterministic structured direct-tip payloads for inner-circle contacts, including ticker, direction, timeframe, hold period, confidence, and risk note.
- Keep blunt trade guidance rare and earned: only inner-circle relationship state plus valid contact/tip conditions can produce "buy/sell/watch X over Y timeframe" style replies.
- Add durable test coverage for privacy gates, referral unlocks, stage-specific options, and direct inner-circle tip rendering.

## Non-goals

- No illegal/inside-information fantasy framing. Direct tips should still be framed as high-trust market reads with risk and public/ethical boundaries.
- No random or nondeterministic dialog/tip generation.
- No broad UI redesign. Only add UI labels/surfaces needed to make referral provenance and direct tip payloads understandable.
- No retuning of market simulation, stock returns, or base tip resolution unless a task explicitly introduces a new direct-tip payload field.
- No removal of existing lower-stage Twooter dialog content; stage-specific options should extend or route around it safely.

## Working rules

- One task per checkpoint commit; verify before each commit.
- Keep edits scoped to the task. Do not mix behavior changes, content changes, and refactors unless the task says so.
- Gates:
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
- If editing JSON, also run:
  - `python3 -m json.tool data/network/contact_network_data.json > /dev/null`
  - `python3 -m json.tool data/social/twooter_feed_data.json > /dev/null`
- Determinism: all dialog/tip variants must use existing stable seed-key patterns. No `randi`, `randf`, `Time`, or unseeded random calls.
- Save compatibility: any new saved keys need normalizer defaults. Prefer computed snapshot fields where persistence is not required.
- Privacy rule: contacts above the configured inner-circle privacy threshold must not be discoverable from public article leads unless a test explicitly proves the contact was already referred/met.
- Behavior tasks should add targeted probes before broad smoke. Use committed test scenes for privacy/direct-tip coverage.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Baseline map + stage/progression probe | ~10-15% | Complete |
| 2 | Referral-gated high-privacy discovery | ~15-25% | Complete |
| 3 | Expanded stage-specific Network private dialog routing/options | ~25-35% | Complete |
| 4 | Inner-circle direct tip payload resolver | ~20-30% | Complete |
| 5 | UI/journal/snapshot surfacing for referrals and direct tips | ~10-20% | Complete |
| 6 | Full scenario coverage and tuning pass | ~15-25% | Complete |

Recommended batching: **Session 1 = Task 1** because it records the current behavior and creates failing/guardrail probes before changing privacy rules. **Session 2 = Task 2** because referral gating changes discovery behavior and should land before dialog/content work. **Tasks 3-4** should be implemented together only if Task 2 is stable; otherwise keep them separate. **Task 6** should wait until all behavior/content is in place.

## Progress log

### 2026-06-13 - Plan created

- Created this enhancement plan from the product direction discussed after the Contact Network high-recognition test.
- Current inventory:
  - Network contacts have a numeric `relationship` value stored in `RunState.network_contacts`.
  - Twooter accounts have numeric `relationship` plus named stages: `stranger`, `familiar`, `trusted`, `inner_circle_candidate`.
  - Current stage thresholds are `familiar >= 18`, `trusted >= 45`, and `inner_circle_candidate >= 70 relationship + >=45 credibility + >=55 importance`.
  - Current named-stage differentiation is partial: it affects route selection, option locks, and reply pools, but not a complete per-stage option set.
  - Desired direction: each stage should have multiple player choices that express different intent, such as verify, ask, share work, build trust, request referral, ask timing, ask risk, or close the loop.
  - Current high-recognition test proves a 95-recognition contact can be seeded to inner-circle state and can send a Network-source private dialog option, but the active route remains `network_source_followup`, not a dedicated inner-circle direct-tip route.
  - Product direction: inner-circle contacts should not be exposed directly by public News/source leads; they should be reached through referrals from suitable 70-90 recognition contacts.
- No code or data changes were made by this planning step.

### 2026-06-13 - Task 1 completed

- Added `scripts/tests/NetworkInnerCircleProgressionAuditTest.gd`, `scripts/tests/NetworkInnerCircleProgressionAuditTest.gd.uid`, and `scenes/tests/NetworkInnerCircleProgressionAuditTest.tscn`.
- The probe captures current generated Network-source private dialog options for all four current Twooter stages:
  - `stranger`
  - `familiar`
  - `trusted`
  - `inner_circle_candidate`
- Locked baseline hash `529559669`.
- Current baseline facts:
  - all four stages route to `network_source_followup`;
  - all four stages expose 3 enabled options from node `open`;
  - option ids are currently `news_context_intro`, `public_trail`, and `ask_to_connect` at every stage;
  - the rendered player lines vary by deterministic seed, but the option set does not yet materially progress by named stage;
  - the 95-recognition contact `pak_gunawan_personal_lawyer` is hidden before top-tier recognition and exposed from the public News-style article lead after `Market Name` recognition is seeded.
- This is a baseline/guardrail only; no gameplay behavior was changed.
- Verification:
  - `git diff --check` passed.
  - `/Users/user/.local/bin/godot --headless -e --quit` passed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkInnerCircleProgressionAuditTest.tscn` -> `NETWORK_INNER_CIRCLE_BASELINE_OK hash=529559669 stages=4 high_after_exposed=true high_before_exposed=false`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`.

### 2026-06-13 - Task 2 completed

- Added referral-gated privacy policy in `systems/ContactNetworkSystem.gd`:
  - contacts with `recognition_required >= 90` now require private referral/met state instead of public News/source discovery;
  - bridge contacts must be floaters with `recognition_required >= 70` and `< 90`;
  - inner-circle referral requires the bridge contact to be met, pass existing referral relationship/cooldown checks, and have either `relationship >= 60` or a recent useful interaction signal.
- Updated public discovery paths so article authors, article/company leads, and company insiders skip referral-required contacts from public exposure.
- Added the `inner_circle` referral branch to `request_referral`, preserving the existing generated company-insider referral path for normal calls.
- Added referral unlock metadata:
  - `source_type: "referral"`
  - `referred_by_contact_id`
  - `referral_day_index`
  - `privacy_gate: "inner_circle"`
  - `referral_required: true`
- Updated generated Network Twooter account synthesis so referral-required contacts stay hidden until privately referred or met.
- Updated Network contact rows to surface referral provenance fields for tests and later UI work.
- Updated `NetworkInnerCircleProgressionAuditTest` from the Task 1 historical baseline hash to Task 2 guardrail hash `1009474557`.
- Updated `NetworkHighRecognitionScenarioTest` so the full path is:
  - high-recognition contact hidden before recognition;
  - still hidden from public News/source discovery after `Market Name`;
  - `pak_budihardjo_energy_dir` privately refers `pak_gunawan_personal_lawyer`;
  - referred contact becomes meetable with referral provenance;
  - Twooter account appears only after referral/met and the existing dialog/tip path still completes.
- Verification:
  - `git diff --check` passed.
  - `/Users/user/.local/bin/godot --headless -e --quit` passed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkInnerCircleProgressionAuditTest.tscn` -> `NETWORK_INNER_CIRCLE_BASELINE_OK hash=1009474557 stages=4 high_after_exposed=false high_before_exposed=false`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkHighRecognitionScenarioTest.tscn` -> `CONTACT_NETWORK_HIGH_RECOGNITION_OK ... scenario_hash=1626147722`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkSnapshotAuditTest.tscn` -> `NETWORK_SNAPSHOT_AUDIT_OK hash=1423212622 contacts=2 discoveries=3 journal=18`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkThirtyDayScenarioTest.tscn` -> `CONTACT_NETWORK_30_DAY_OK ... scenario_hash=2044234134`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`.

### 2026-06-14 - Task 3 completed

- Added dedicated stage-specific Network-source private dialog trees in `data/social/twooter_feed_data.json`:
  - `network_stranger_source`
  - `network_familiar_source`
  - `network_trusted_source`
  - `network_inner_circle_source`
- Added stage-specific private routing rules so generated Network-source accounts route by `relationship_stage` after higher-priority boundary/privacy routes.
- Preserved guarded/boundary behavior:
  - Network insider profiles still route to `network_insider_boundary`.
  - suspicious/guarded Network profiles still route to `network_guarded_source`.
  - legacy `network_source_followup` and `network_relationship_probe` remain reachable for forced/saved branches.
- Added `affiliation_role` condition support in `systems/TwooterDialogRouter.gd` so profile-preferred insider routing can be expressed in data instead of relying on fallback order.
- Expanded authored options by stage:
  - stranger: 5 authored options; visible set starts with `source_context`, `public_trail`, `boundary_check`.
  - familiar: 6 authored options; visible set starts with `clean_read`, `second_source`, `connect_properly`.
  - trusted: 6 authored options; visible set starts with `guarded_tip`, `referral_probe`, `position_sizing`.
  - inner-circle: 6 authored options; visible set starts with `direct_tip`, `entry_timing`, `private_referral`.
- Updated `TwooterRoutingRulesTest` and `TwooterDialogReachabilityTest` to cover every Network stage tree plus boundary/fallback cases.
- Updated `NetworkInnerCircleProgressionAuditTest` so it asserts:
  - each stage routes to the expected tree;
  - each stage exposes at least 3 enabled visible options;
  - each stage authors at least 4 options;
  - visible option ids differ by stage;
  - inner-circle fixtures include enough exposure to survive production account-state normalization.
- Updated the progression audit guardrail hash to `1825575415`.
- Current limitation carried into Task 4:
  - `direct_tip` is now the inner-circle dialog option, but it still uses the existing `ask_tip`/`clean_read` style outcome and generic reply text. Structured "buy/hold/timeframe/risk" payloads are Task 4.
- Known warning:
  - The private-message UI currently displays 3 option buttons. These stage trees intentionally author 5-6 options, so headless tests print `more than 3 usable private options; extra options are hidden`. This is expected for Task 3 unless the UI cap is changed later.
- Verification:
  - `python3 -m json.tool data/network/contact_network_data.json > /dev/null` passed.
  - `python3 -m json.tool data/social/twooter_feed_data.json > /dev/null` passed.
  - `git diff --check` passed.
  - `/Users/user/.local/bin/godot --headless -e --quit` passed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterRoutingRulesTest.tscn` -> `TWOOTER_ROUTING_RULES_OK`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterDialogReachabilityTest.tscn` -> `TWOOTER_DIALOG_REACHABILITY_OK`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkInnerCircleProgressionAuditTest.tscn` -> `NETWORK_INNER_CIRCLE_BASELINE_OK hash=1825575415 stages=4 high_after_exposed=false high_before_exposed=false`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkHighRecognitionScenarioTest.tscn` -> `CONTACT_NETWORK_HIGH_RECOGNITION_OK ... dialog_tree_id=network_inner_circle_source dialog_chosen_option_id=direct_tip scenario_hash=704355409`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`.

### 2026-06-14 - Task 4 completed

- Added deterministic direct-tip payload construction in `systems/NetworkTipResolver.gd`.
- `direct_tip` now produces structured metadata when the player is speaking to a valid inner-circle Network-source account:
  - `ticker`
  - `direction`
  - `direction_label`
  - `entry_timing`
  - `hold_period`
  - `confidence_label`
  - `risk_note`
  - `public_boundary_note`
  - `truth_label`
  - `source_read_type`
  - optional `source_tip_id`
- Added direct-tip guards:
  - only `network_contact`/Network-source accounts can produce direct-tip payloads;
  - account stage must be `inner_circle_candidate`;
  - backing Network contact must be met;
  - referral-required/private contacts must have referral/inner-circle provenance;
  - target ticker/company context must be present.
- Added Network-generated account metadata in `systems/NetworkContactPresenter.gd` so direct tips can use contact reliability, recognition requirement, and tone without looking up full contact data from the Twooter system.
- Added `direct_tip` as a distinct dialog outcome in `systems/TwooterOutcomeResolver.gd`.
- Updated `systems/TwooterInteractionSystem.gd` so direct-tip payloads:
  - override the normal generic reply text;
  - are stored in `outcome_effect.direct_tip_payload`;
  - are copied into Twooter social Network journal rows;
  - add timeline/journal notes as `Direct tip: inner-circle read recorded.`
- Added `direct_tip_reply_templates` to `data/social/twooter_feed_data.json`.
- Changed inner-circle `direct_tip` option outcome from `clean_read` to `direct_tip`; lower-stage read options remain `clean_read`.
- Updated `TwooterOutcomeConsequencesTest`:
  - validates direct-tip payload metadata and journal fields;
  - verifies trusted-stage Network accounts do not expose `direct_tip`;
  - updated stale contact-discovery fixture to use the Task 3 `connect_properly` option.
- Updated `NetworkHighRecognitionScenarioTest` to require a successful direct-tip payload on the private referral path.
- Current high-recognition direct-tip sample:
  - `Buy HEFI next week and hold for 3 trading days. Confidence: high-trust read. Risk: the paperwork or formal notice slips. Boundary: confirm it against public tape, filings, or the next dated checkpoint`
- Verification:
  - `python3 -m json.tool data/network/contact_network_data.json > /dev/null` passed.
  - `python3 -m json.tool data/social/twooter_feed_data.json > /dev/null` passed.
  - `git diff --check` passed.
  - `/Users/user/.local/bin/godot --headless -e --quit` passed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterOutcomeConsequencesTest.tscn` -> `TWOOTER_OUTCOME_CONSEQUENCES_OK ... direct_tip.direction=buy`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkHighRecognitionScenarioTest.tscn` -> `CONTACT_NETWORK_HIGH_RECOGNITION_OK ... dialog_outcome=direct_tip direct_tip_direction=buy scenario_hash=232446936`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkInnerCircleProgressionAuditTest.tscn` -> `NETWORK_INNER_CIRCLE_BASELINE_OK hash=1825575415 stages=4 high_after_exposed=false high_before_exposed=false`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterRoutingRulesTest.tscn` -> `TWOOTER_ROUTING_RULES_OK`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterDialogReachabilityTest.tscn` -> `TWOOTER_DIALOG_REACHABILITY_OK`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkSnapshotAuditTest.tscn` -> `NETWORK_SNAPSHOT_AUDIT_OK hash=1423212622 contacts=2 discoveries=3 journal=18`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkThirtyDayScenarioTest.tscn` -> `CONTACT_NETWORK_30_DAY_OK ... scenario_hash=2044234134`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`.

### 2026-06-14 - Task 5 completed

- Added player-facing referral provenance fields to Network contact/discovery snapshot rows:
  - `access_label`
  - `provenance_label`
  - `referred_by_contact_name`
  - `referral_day_label`
  - `referral_note`
- Normal referrals now stamp `referral_day_index` consistently with inner-circle referrals.
- Preserved private referral provenance through later Network Twooter messages:
  - the existing discovery keeps `source_type: "referral"`;
  - Twooter/source metadata is recorded as supplemental metadata instead of replacing the referral source;
  - this keeps the referral journal row visible after an inner-circle direct-tip DM.
- Expanded Network journal row fields for provenance/direct-tip audit:
  - referral rows now expose `access_label`, `referred_by_contact_name`, and `referral_day_index`;
  - direct-tip rows now expose direction, entry timing, hold period, confidence, and risk fields.
- Updated Network journal wording:
  - referral rows now render as `Referral | Inner-circle contact | Gunawan Sutrisno` or `Referral | Private referral | ...`;
  - direct-tip rows now render as `Twooter | Inner-circle Direct Read | HEFI`;
  - direct-tip details include confidence, risk, and boundary language.
- Updated `scripts/ui/controllers/NetworkController.gd` to surface the new fields in the existing dense Network UI:
  - contact list prefix uses `Inner-circle contact` / `Private referral`;
  - contact detail metadata shows referral source and day;
  - journal detail panel shows access, referred-by, direct read, and risk lines when present.
- Updated tests:
  - `NetworkHighRecognitionScenarioTest` now asserts referral provenance fields, referral journal wording, and direct-tip journal fields.
  - `NetworkSnapshotAuditTest` now includes the new journal/snapshot fields and has updated hash `805271236`.
- Current high-recognition Task 5 sample:
  - referral journal title: `Referral | Inner-circle contact | Gunawan Sutrisno`
  - referral journal detail: `Budihardjo Sutanto introduced this lead. Day 1. Access: Inner-circle contact. Context: HEFI.`
  - direct-tip journal title: `Twooter | Inner-circle Direct Read | HEFI`
  - direct-tip journal detail: `Inner-circle direct read: Buy HEFI, next week, hold for 3 trading days. Confidence: high-trust read. Risk: the paperwork or formal notice slips. Boundary: confirm it against public tape, filings, or the next dated checkpoint.`
- Verification:
  - `python3 -m json.tool data/network/contact_network_data.json > /dev/null` passed.
  - `python3 -m json.tool data/social/twooter_feed_data.json > /dev/null` passed.
  - `/Users/user/.local/bin/godot --headless -e --quit` passed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkHighRecognitionScenarioTest.tscn` -> `CONTACT_NETWORK_HIGH_RECOGNITION_OK ... scenario_hash=232446936`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkSnapshotAuditTest.tscn` -> `NETWORK_SNAPSHOT_AUDIT_OK hash=805271236 contacts=2 discoveries=3 journal=18`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterOutcomeConsequencesTest.tscn` -> `TWOOTER_OUTCOME_CONSEQUENCES_OK ... direct_tip.direction=buy`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterRoutingRulesTest.tscn` -> `TWOOTER_ROUTING_RULES_OK`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterDialogReachabilityTest.tscn` -> `TWOOTER_DIALOG_REACHABILITY_OK`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkInnerCircleProgressionAuditTest.tscn` -> `NETWORK_INNER_CIRCLE_BASELINE_OK hash=1825575415 stages=4 high_after_exposed=false high_before_exposed=false`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkThirtyDayScenarioTest.tscn` -> `CONTACT_NETWORK_30_DAY_OK ... scenario_hash=2044234134`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`.

### 2026-06-14 - Task 6 completed

- Added deterministic full-path scenario coverage:
  - `scripts/tests/NetworkInnerCircleFullScenarioTest.gd`
  - `scripts/tests/NetworkInnerCircleFullScenarioTest.gd.uid`
  - `scenes/tests/NetworkInnerCircleFullScenarioTest.tscn`
- The scenario starts from a fresh run and verifies:
  - public News-style lead exposes the 85-recognition bridge contact `pak_budihardjo_energy_dir`;
  - public lead does not expose referral-required inner-circle contact `pak_gunawan_personal_lawyer`;
  - bridge contact is met through the public lead;
  - bridge relationship grows from `14` to `62` through an accelerated deterministic track-record fixture;
  - bridge contact can unlock the inner-circle referral;
  - referred contact preserves referral provenance in discovery/met rows;
  - generated Network Twooter account reaches `inner_circle_candidate`;
  - `network_inner_circle_source` exposes the direct-tip option set;
  - choosing `direct_tip` records a structured direct-tip payload, Network journal row, and Twooter timeline proof.
- Locked full-scenario hash `205923456`.
- Added test log:
  - `docs/development/test_log/2026-06-14_contact_network_inner_circle_full_scenario.md`
- Observed tuning note:
  - the immediate public-lead return list includes the bridge contact twice because it matches both author and lead-scoring paths;
  - saved Network discovery state is still de-duplicated by contact id, so this is not blocking Task 6;
  - a later polish pass can de-duplicate immediate discovery result rows if the UI ever surfaces them directly.
- 120-day `MarketYearAudit` was not run because Task 6 did not change due-tip processing or market-facing direct-tip outcomes; the direct-tip payload remains journal/timeline metadata.
- Verification:
  - `python3 -m json.tool data/network/contact_network_data.json > /dev/null` passed.
  - `python3 -m json.tool data/social/twooter_feed_data.json > /dev/null` passed.
  - `git diff --check` passed.
  - `/Users/user/.local/bin/godot --headless -e --quit` passed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkInnerCircleFullScenarioTest.tscn` -> `CONTACT_NETWORK_INNER_CIRCLE_FULL_SCENARIO_OK ... scenario_hash=205923456`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkHighRecognitionScenarioTest.tscn` -> `CONTACT_NETWORK_HIGH_RECOGNITION_OK ... scenario_hash=232446936`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkSnapshotAuditTest.tscn` -> `NETWORK_SNAPSHOT_AUDIT_OK hash=805271236 contacts=2 discoveries=3 journal=18`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkThirtyDayScenarioTest.tscn` -> `CONTACT_NETWORK_30_DAY_OK ... scenario_hash=2044234134`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterRoutingRulesTest.tscn` -> `TWOOTER_ROUTING_RULES_OK`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterDialogReachabilityTest.tscn` -> `TWOOTER_DIALOG_REACHABILITY_OK`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterOutcomeConsequencesTest.tscn` -> `TWOOTER_OUTCOME_CONSEQUENCES_OK ... direct_tip.direction=buy`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkInnerCircleProgressionAuditTest.tscn` -> `NETWORK_INNER_CIRCLE_BASELINE_OK hash=1825575415 stages=4 high_after_exposed=false high_before_exposed=false`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`.

### 2026-06-14 - Small addition: Network -> Twooter DM bridge

- Added a Network contact detail button for contacts with a generated Twooter account:
  - button text: `Open Twooter DM`
  - source file: `scripts/ui/controllers/NetworkController.gd`
- The button opens Twooter directly into the Message view with the selected contact's generated account selected.
- This preserves the intended product split:
  - Network remains the CRM/mission log for contacts, referrals, tips, provenance, and durable work items.
  - Twooter remains the conversation surface where the player chooses private dialog options.
- The button does not spend AP and does not send a message; it only navigates to the relevant Twooter DM.

---

## Task 1 - Baseline Map + Stage/Progression Probe

Problem: before changing privacy and stage routing, the project needs a precise baseline showing which contacts can currently be discovered from News/source leads, which dialog tree each relationship stage receives, and what options are visible at each stage.

1. Add a targeted probe scene/script, e.g. `scripts/tests/NetworkInnerCircleProgressionAuditTest.gd` and `scenes/tests/NetworkInnerCircleProgressionAuditTest.tscn`.
2. Build deterministic fixtures for one generated Network source at each Twooter stage: `stranger`, `familiar`, `trusted`, `inner_circle_candidate`.
3. Capture visible private dialog options per stage: `tree_id`, `node_id`, `option_id`, `action_id`, `label`, `enabled`, `blocked_reason`, rendered `player_text`, and option count.
4. Capture current high-recognition contact exposure behavior from article/company discovery so Task 2 can prove privacy behavior changed intentionally.
5. Print a compact sentinel like `NETWORK_INNER_CIRCLE_BASELINE_OK` with a stable hash.
6. Verify:
   - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkInnerCircleProgressionAuditTest.tscn` -> `NETWORK_INNER_CIRCLE_BASELINE_OK`
   - gates and quick smoke.

## Task 2 - Referral-Gated High-Privacy Discovery

Problem: inner-circle/high-privacy contacts should not be discovered directly from public News/source leads. Public leads should expose lower/mid contacts first; access to high-recognition contacts should come through earned referrals.

1. Define a clear privacy/referral policy in data or constants:
   - suggested initial gate: contacts with `recognition_required >= 90` require referral, not public article discovery.
   - contacts around `70-90` recognition can act as bridge/referral contacts when relationship and credibility conditions are met.
2. Update discovery logic so article/company lead discovery skips referral-required contacts unless a saved referral/unlock exists.
3. Add referral unlock state in the least invasive shape possible, e.g. saved discovery metadata with `source_type: "referral"`, `referred_by_contact_id`, and `referral_day_index`; add normalizer defaults where needed.
4. Add/extend a referral API path from an eligible bridge contact:
   - requirements should include Network relationship, recognition tier, recent useful interaction/tip follow-up, and contact category fit.
   - output should create a discoverable/meetable inner-circle contact without implying public exposure.
5. Update generated Twooter account synthesis so referral-required contacts remain hidden until referred/met.
6. Verify:
   - new privacy/referral test sentinel proves high-recognition contacts do not appear from public News leads.
   - same test proves an eligible bridge contact can refer one.
   - `NetworkSnapshotAuditTest`, `NetworkThirtyDayScenarioTest`, and gates/quick smoke.

## Task 3 - Expanded Stage-Specific Network Private Dialog Routing/Options

Problem: named stages currently affect route locks and reply flavor, but the player does not get a clearly different option set at each relationship stage. Each stage should offer several choices that feel appropriate to the trust level, so progression changes the player's tactical options instead of only changing background text.

1. Add dedicated Network private dialog trees or nodes for:
   - `network_stranger_source`
   - `network_familiar_source`
   - `network_trusted_source`
   - `network_inner_circle_source`
2. Route generated Network-source accounts by stage after respecting privacy/referral requirements.
3. Add a richer authored option matrix. Target 4-6 options per stage, with at least 3 normally visible/enabled after common setup:
   - stranger:
     - `source_context` / Context - explain how the player found the handle and ask for safe public context.
     - `public_trail` / Public trail - ask what filings, dated news, or volume to verify first.
     - `boundary_check` / Boundary - make clear the player is not asking for private information.
     - `watch_item_soft` / Watch item - ask for one low-conviction watch item, not a trade signal.
     - `close_loop` / Close loop - end politely and preserve trust.
   - familiar:
     - `clean_read` / Clean read - ask for a verifiable read on the current ticker.
     - `second_source` / Second source - ask what public source would confirm or reject the lead.
     - `share_thesis` / Share thesis - share written work if a thesis exists.
     - `connect_properly` / Connect - ask to turn the one-off source into a real contact.
     - `risk_check` / Risk check - ask what would make the contact cautious.
     - `followup_timing` / Timing - ask when the next public checkpoint matters.
   - trusted:
     - `guarded_tip` / Guarded read - ask for a stronger read, still framed with caveats.
     - `challenge_thesis` / Challenge thesis - ask the contact to attack the player's written assumptions.
     - `referral_probe` / Referral - ask whether there is someone better suited to the topic.
     - `position_sizing` / Sizing - ask how carefully to size the idea, not just whether it is right.
     - `event_room` / Room - ask about a higher-context room or conversation.
     - `source_conflict` / Conflict - ask what would make two sources disagree.
   - inner-circle:
     - `direct_tip` / Direct read - ask for the clearest actionable read available.
     - `entry_timing` / Entry timing - ask whether the read is for today, tomorrow, this week, next week, or next month.
     - `hold_period` / Hold period - ask how long the read should stay valid before review.
     - `conviction_risk` / Conviction risk - ask what would invalidate the read or force a smaller position.
     - `private_referral` / Private intro - ask for a carefully bounded introduction to another high-privacy contact.
     - `no_trade_boundary` / No-trade boundary - let the contact say "do nothing" when the setup is not clean enough.
4. Give each option a clear outcome class where appropriate:
   - `source_check` for verification/source asks.
   - `clean_read` for normal actionable watch reads.
   - `thesis_response` for written thesis review.
   - `contact_discovery` for connection/referral outcomes.
   - `event_invite` for room/access outcomes.
   - new direct-tip outcome only if Task 4 needs it; otherwise reuse `clean_read` with direct-tip payload metadata.
5. Add option requirements so deeper actions are blocked with clear text when relationship/credibility/importance/referral path is insufficient.
6. Preserve current fallback routes for non-Network accounts and suspicious/boundary profiles.
7. Verify:
   - `TwooterRoutingRulesTest` and `TwooterDialogReachabilityTest` cover each Network stage tree.
   - `NetworkInnerCircleProgressionAuditTest` proves visible options differ by stage and each stage exposes the expected minimum option count.
   - JSON validation, gates, and quick smoke.

## Task 4 - Inner-Circle Direct Tip Payload Resolver

Problem: inner-circle `ask_tip` should be able to produce a concrete, actionable high-trust read when a valid contact has one, instead of only generic process/source-check language.

1. Add a deterministic direct-tip payload builder in `NetworkTipResolver` or a focused helper:
   - `ticker`
   - `direction` (`buy`, `avoid`, `watch`, `sell/reduce` only if the game supports it cleanly)
   - `entry_timing` (`today`, `tomorrow`, `this week`, `next week`, `next month`)
   - `hold_period`
   - `confidence_label`
   - `risk_note`
   - `public_boundary_note`
2. Tie payload strength to contact reliability, relationship, recognition tier, and current tip truth/outcome data.
3. Add inner-circle dialog rendering tokens in `twooter_feed_data.json` so replies can say things like:
   - "Buy {ticker} this week and hold through {hold_period}; risk is {risk_note}."
   - "Watch {ticker} until {entry_timing}; do not size it unless {risk_note} clears."
4. Add guardrails:
   - no direct payload if contact is not referred/met through a valid path.
   - no direct payload if relationship stage drops below `inner_circle_candidate`.
   - no direct payload if there is no eligible active tip/read.
5. Record direct-tip metadata in journal/timeline rows only where useful for later audit; avoid unnecessary saved-state bloat.
6. Verify:
   - targeted direct-tip test proves inner-circle direct payload appears.
   - same test proves trusted/familiar contacts do not receive direct payload.
   - `TwooterOutcomeConsequencesTest`, `NetworkHighRecognitionScenarioTest`, JSON validation, gates, and quick smoke.

## Task 5 - UI/Journal/Snapshot Surfacing For Referral And Direct Tips

Problem: if referral and direct-tip mechanics exist but the UI/journal does not explain provenance, the player cannot tell why access was earned or why a tip is stronger than normal.

1. Add minimal Network snapshot/journal fields for referral provenance:
   - referred by contact name.
   - referral day.
   - privacy/access label such as `Private referral` or `Inner-circle contact`.
2. Add direct-tip journal/timeline wording that distinguishes:
   - normal tip.
   - clean read/source check.
   - inner-circle direct read.
3. Keep UI dense and consistent with the existing Network/Twooter app design. Do not add a new visual system.
4. Ensure text does not imply guaranteed outcome; include confidence/risk language.
5. Verify:
   - targeted test asserts journal fields/rows.
   - quick smoke covers Network/Twooter UI surfaces.
   - gates and quick smoke.

## Task 6 - Full Scenario Coverage And Tuning Pass

Problem: the final feature crosses discovery, relationships, Twooter routing, direct tips, and journal output. It needs scenario-level coverage beyond unit routing tests.

1. Extend or add a scenario test that starts from a fresh run and deterministically reaches:
   - public lead -> mid/high bridge contact.
   - bridge contact relationship growth.
   - referral unlock for an inner-circle contact.
   - inner-circle Twooter message thread.
   - direct tip option/reply.
   - journal/timeline proof.
2. Keep one accelerated fixture for deterministic CI-style coverage and one longer smoke/progression path if feasible.
3. Add a test log under `docs/development/test_log/` with the exact options, chosen dialog, reply, final relationship values, referral provenance, direct-tip payload, and scenario hash.
4. Run at least:
   - targeted progression test.
   - `NetworkSnapshotAuditTest`.
   - `NetworkThirtyDayScenarioTest`.
   - `NetworkHighRecognitionScenarioTest`.
   - `TwooterRoutingRulesTest`.
   - `TwooterDialogReachabilityTest`.
   - `TwooterOutcomeConsequencesTest`.
   - quick smoke.
5. Consider a 120-day `MarketYearAudit` if direct-tip payloads change due-tip processing or market-facing outcomes.

## Known traps

- Network-source profile routing currently takes precedence over the generic `event_invite` route. Stage-specific Network routes must be explicit, or inner-circle accounts will keep using `network_source_followup`.
- `relationship_stage` is saved into `twooter_social_state.account_states`; any threshold changes must go through `TwooterDialogRouter.relationship_stage` and remain delegated from `TwooterInteractionSystem`.
- Public discovery and generated Twooter account synthesis are separate paths. Hiding a contact from article discovery is not enough if `build_twooter_accounts` still exposes it.
- A contact's Network `relationship` and its generated Twooter account `relationship` are related but not identical. Tests must assert both when referral/direct-tip behavior bridges them.
- Direct tips can easily become overpowered. Keep payload frequency and strength tied to reliability, relationship, and valid tip state.
- JSON dialog trees can become unreachable if route conditions, action IDs, or requirements drift. Always run routing/reachability tests after editing `twooter_feed_data.json`.
- Long scenario tests should print compact structured payloads. Avoid giant logs that make future diffs unreadable.
