# Content Surface Generation Enhancement - Plan & Progress Log

This plan derives news, Twooter, Network, and thesis clues from structured story facts so content can scale without hand-authoring every possible variant.
**Status: complete - Tasks 1-6 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** Top-down research creates a content explosion: macro news, sector news, company news, Twooter chatter, private network clues, and financial statement notes. The solution is not to manually write everything. The game should generate surface-specific content from a shared dossier while preserving each surface's role and information quality.

## Where everything lives

| What | Where |
|---|---|
| News surface | `systems/NewsFeedSystem.gd`, `data/news/news_feed_data.json` |
| Twooter surface | `systems/TwooterFeedSystem.gd`, `systems/TwooterInteractionSystem.gd`, `data/social/twooter_feed_data.json` |
| Network surface | `systems/ContactNetworkSystem.gd`, `data/network/contact_network_data.json` |
| Thesis surface | `systems/ThesisManager.gd`, `systems/ThesisVocabulary.gd`, `data/thesis/thesis_content.json` |
| Planned source of truth | Company story dossier system |
| Tests/probes | `scenes/tests/ContentSurfaceNewsPreviewTest.tscn`, `scenes/tests/ContentSurfaceTwooterPreviewTest.tscn`, `scenes/tests/ContentSurfaceNetworkPrivateClueTest.tscn`, `scenes/tests/ContentSurfaceThesisEvidenceCaptureTest.tscn`, `scenes/tests/ContentSurfaceConsistencyReachabilityTest.tscn` |
| Key functions | Locate by feed builders, interaction routing, contact tip generation, and thesis evidence generation |

## Goals

- Define what each content surface is allowed to reveal.
- Generate surface content from dossier facts rather than duplicating truth in each system.
- Keep generated content deterministic and testable.

## Non-goals

- Do not replace all existing authored content in one pass.
- Do not make every clue equally reliable.
- Do not make private Network information appear in public Twooter unless intentionally leaked.

## Working rules

- Each generated item should reference a source fact id or story id.
- Public/private information boundaries must be explicit.
- Generated text should vary by surface but not contradict the underlying facts.
- Preserve existing authored content while introducing generated content gradually.
- Generated visible text must not expose hidden ids, truth-state labels, source-quality labels, or relationship gates.
- Metadata may retain traceability fields for tests and thesis reports, but player-facing copy must stay surface-appropriate.

## Surface Reveal Rules

Task 1 locks the reveal contract for generated content. The existing dossier already emits `news`, `twooter`, `network`, and `statement_note` clue rows with timing, reliability, detail, and visibility fields. The content generation layer should consume those rows instead of creating a second truth store.

### Shared Generated Item Metadata

Every generated content item should carry these fields, even when visible copy only shows a subset:

| Field | Purpose |
|---|---|
| `surface_id` | Target surface such as `macro_news`, `sector_news`, `company_news`, `twooter`, `network`, `statement_note`, or `thesis`. |
| `source_system_id` | Usually `company_story_dossier`; can later support macro, commodity, relationship, or corporate-action generators. |
| `story_id` | Stable dossier story id when the item comes from a company story. |
| `company_id` / `ticker` | Company reference when applicable. Macro-only items may leave this blank. |
| `source_fact_ids` | Source facts used to produce the item. Required for tests and thesis traceability. |
| `source_clue_ids` | Source clue rows used to produce the item. |
| `visibility` | `public`, `private`, `filing`, or `internal`. |
| `earliest_day_index` / `latest_day_index` | Reveal window inherited from the source clue when available. |
| `detail_level` | `macro`, `sector`, `low`, `medium`, `high`, or `specific`. |
| `reliability` | Surface-adjusted reliability, not a visible confidence label. |
| `public_status` / `stage_id` | Story lifecycle state for deterministic timing and tone. |
| `leak_risk` | Non-zero only when private information is intentionally allowed to leak into public chatter. |

### Surface Contract

| Surface | Visibility | Allowed reveal | Reliability | Delay | Detail level | Must not reveal |
|---|---|---|---|---|---|---|
| Macro news | Public | Global, government, rate, FX, inflation, and commodity regime facts. Can name affected sectors but should not name private company stories unless already public. | Medium, broad, often lagging. | Same day to 5 days after macro state. | Macro to sector. | Private contacts, inner-circle source identity, exact unreleased company actions, direct trade calls. |
| Sector news | Public | Sector/subsector pressure, commodity pass-through, regulation, demand shifts, and broad winner/loser groups. | Medium. | 1 to 10 days after macro/sector signal. | Sector to company-watchlist hint. | Private dossier facts, exact company-specific unreleased metrics, network source quality. |
| Company news | Public | Public dossier clues from `public_clues`, reported corporate actions, confirmed/questioned/disputed status, visible event outcomes. | Uses public clue reliability; generally lower than filings and good network tips. | Source clue reveal window, usually started day to 21 days. | Low to medium. | Hidden `truth_state`, source quality, private contact language, buy/sell instructions, unreleased direct tips. |
| Twooter chatter | Public | Rumor, sentiment, jokes, skepticism, weak pattern matching, and noisy public interpretation of company or sector facts. | Low to medium-low; can disagree. | Usually 2 to 28 days after public clue start. | Low. | Network-only private facts unless `leak_risk` explicitly permits a vague leak; no exact source identity or relationship gate. |
| Network tips | Private | Contextual or specific private clue rows from `private_clues`; better contact stages can reveal more direct company, timing, and metric context. | Medium to high depending source quality and relationship stage. | Usually 6 to 45 days after story start. | Contextual to specific. | Public feed visibility, ungated inner-circle direct tips, hidden implementation ids in player copy. |
| Annual filing / statement notes | Filing | Accounting footprints, note paragraphs, segment data, related-party hints, commitments, risks, and subsequent events from `statement_clues` and disclosure packets. | Medium-high for historical facts, slower and less current. | Period/filing delay; not an immediate public rumor surface. | Medium to high, but formal and indirect. | Direct trade answers, private source quality, current unreleased tips, explicit truth labels. |
| Thesis evidence | Internal player reasoning | Captured visible excerpts from other surfaces plus traceability metadata for reports. | Inherits source surface reliability. | Immediate after player capture. | Same as captured source. | New facts that were not visible or legitimately captured by the player. |

### Public Leak Rules

- Public surfaces are `macro_news`, `sector_news`, `company_news`, and `twooter`.
- Public surfaces may expose only facts whose source visibility is public, filing, macro, sector, or intentionally leaked.
- A private clue may leak into Twooter only when the source row has `leak_risk > 0.0`; even then the copy must be vague and cannot name the source or exact private detail.
- Company news should not consume `private_clues` directly. If private information becomes public, the story should first update `public_status` or emit a public clue.
- Network tips can mention source quality in private metadata, but visible copy should phrase it as relationship texture, not as `source_quality`.
- Filings can confirm or contradict public narratives, but they should feel delayed and document-like.

### Detail Ladder

| Detail | Meaning | Typical surfaces |
|---|---|---|
| `macro` | Mentions broad macro or commodity movement without company names. | Macro news. |
| `sector` | Names sectors/subsectors and broad exposure groups. | Macro news, sector news. |
| `low` | Names a company or ticker but stays vague about mechanism and timing. | Company news, Twooter. |
| `medium` | Gives a visible mechanism such as capex, margin, contracts, receivables, inventory, or segment movement. | Company news, filings, better Twooter accounts. |
| `high` | Connects mechanism and metric but still avoids direct recommendations. | Filings, high-quality Network tips. |
| `specific` | Gives actionably direct company/timing context. | Trusted or inner-circle Network only. |

### Reliability Rules

- Reliability is metadata for tests, sorting, and thesis reporting; it should not appear as a visible confidence label.
- Public news should not exceed high-quality filing or trusted private network reliability for the same story.
- Twooter reliability should be capped below company news except for verified accounts in later tasks.
- Network reliability can exceed public surfaces only after relationship gates are met.
- Filings are reliable for historical numbers and disclosed commitments, but stale for current rumors.
- `fraud_risk`, `overhyped`, and `uncertain` stories should produce more disagreement, contradiction, or absence signals across surfaces.

### Initial Implementation Order

1. Task 2 should generate `macro_news`, `sector_news`, and `company_news` preview rows from public dossier/macro facts only.
2. Task 3 should generate `twooter` preview rows from public or explicitly leaked facts, with noisier tone and lower reliability.
3. Task 4 should generate `network` private clue rows with relationship gates and directness rules.
4. Task 5 should make all generated surfaces capturable as thesis evidence without adding new facts at capture time.
5. Task 6 should verify consistency: no public private-leak violations, no unreachable important story, no generated item without traceability.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Define surface reveal rules | ~10-20% | Complete |
| 2 | Add generated news previews | ~15-30% | Complete |
| 3 | Add generated Twooter previews | ~15-30% | Complete |
| 4 | Add Network private clue integration | ~15-30% | Complete |
| 5 | Add thesis evidence integration | ~10-20% | Complete |
| 6 | Add consistency and reachability tests | ~15-25% | Complete |

Recommended batching: complete. Task 6 is the final guard for generated content surface consistency, privacy boundaries, reachability, and thesis capture paths.

## Progress log

### 2026-06-14 - Plan created

- Created this enhancement plan from the top-down market brainstorming session.
- Current inventory:
  - News, Twooter, Network, and thesis content already exist.
  - New top-down systems would multiply content requirements if every item is authored separately.
  - A generated content layer should depend on the dossier system.
- No code or data changes were made by this planning step.

### 2026-06-22 - Task 1 complete

- Added the surface reveal contract for generated content.
- The contract defines required generated-item metadata, allowed reveal scope, reliability, delay, and detail level for:
  - macro news
  - sector news
  - company news
  - Twooter chatter
  - Network tips
  - annual filing / statement notes
  - thesis evidence
- Public leak rules now explicitly prevent Network-only private facts, inner-circle source identity, source-quality labels, hidden truth-state labels, and direct trade instructions from appearing in public generated copy.
- Locked the initial implementation order:
  - Task 2 starts with generated public news previews
  - Task 3 adds public/noisy Twooter previews
  - Task 4 adds gated private Network clues
  - Task 5 makes generated surfaces capturable as thesis evidence
  - Task 6 adds consistency and reachability tests
- No runtime code, data, UI, or gameplay behavior changed by this task.
- Verification:
  - design review completed in this file
  - `git diff --check` -> passed

### 2026-06-22 - Task 2 complete

- Added generated public news preview sources inside `NewsFeedSystem`.
- Public previews are generated from active dossier `public_clues` with `surface_id = "news"` and `visibility = "public"`.
- Generated preview surfaces now include:
  - `company_news` from public company dossier clues
  - `sector_news` from public sector facts
  - `macro_news` from public macro/commodity facts
- Existing authored news/event/public-brief articles remain in the same snapshot; generated previews are appended through the outlet feed builder and deduped by article id.
- Generated articles retain traceability metadata for tests and thesis/report follow-up:
  - `generated_content_surface`
  - `generated_surface_id`
  - `source_system_id`
  - `story_id`
  - `source_fact_ids`
  - `source_clue_ids`
  - `source_company_ids`
  - `source_sector_ids`
  - `visibility`, `detail_level`, `reliability`, and `leak_risk`
- Visible generated news copy avoids hidden ids, truth-state labels, source-quality labels, private clue language, and direct trade instructions.
- Added `ContentSurfaceNewsPreviewTest` as the fixed-seed regression guard.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceNewsPreviewTest.tscn` -> `CONTENT_SURFACE_NEWS_PREVIEW_OK {"authored_article_count":12,"day_index":26,"generated_article_count":28,"hash":"219414638","issue_count":0,"issues":[],"seed":20260622,"surface_counts":{"company_news":16,"macro_news":4,"sector_news":8}}`
  - Steam initialization warnings appeared in headless mode and are expected local noise.

### 2026-06-22 - Task 3 complete

- Added generated public Twooter preview sources inside `TwooterFeedSystem`.
- Generated Twooter posts consume active dossier `public_clues` with `surface_id = "twooter"` and `visibility = "public"`.
- Generated previews now cover company, sector, and macro/commodity chatter while preserving existing authored Twooter posts in the same snapshot.
- Generated posts vary account voice and visible confidence label by scope and account type, including noisier rumor/retail/flow/sector/macro voices.
- Public generated Twooter copy avoids private Network-only clue language, hidden ids, truth-state labels, source-quality labels, relationship gates, direct source identity, and direct trade instructions.
- Generated post metadata keeps traceability for tests and future thesis/report integration:
  - `generated_content_surface`
  - `generated_surface_id = "twooter"`
  - `source_system_id = "company_story_dossier"`
  - `story_id`
  - `source_fact_ids`
  - `source_clue_ids`
  - `source_company_ids`
  - `source_sector_ids`
  - `visibility`, `detail_level`, `reliability`, and `leak_risk`
- Added `ContentSurfaceTwooterPreviewTest` with fixed-seed hash `2185776077`.
- Updated `TwooterNetworkProgressionTest` to seed the legacy `network_source_followup` branch explicitly before auditing its progression. Current routing intentionally starts fresh Network-source contacts through relationship-stage trees, so the test now checks the branch it intends to exercise without changing gameplay behavior.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceTwooterPreviewTest.tscn` -> `CONTENT_SURFACE_TWOOTER_PREVIEW_OK {"account_voice_count":4,"authored_post_count":8,"confidence_label_count":4,"day_index":28,"generated_post_count":8,"hash":"2185776077","issue_count":0,"issues":[],"scope_counts":{"company":4,"macro":1,"sector":3},"seed":20260622}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/TwooterDialogReachabilityTest.tscn` -> `TWOOTER_DIALOG_REACHABILITY_OK`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/TwooterRoutingRulesTest.tscn` -> `TWOOTER_ROUTING_RULES_OK`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/TwooterNetworkLoopTest.tscn` -> `TWOOTER_NETWORK_LOOP_OK`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/TwooterNetworkProgressionTest.tscn` -> `TWOOTER_NETWORK_PROGRESSION_OK`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/TwooterOutcomeConsequencesTest.tscn` -> `TWOOTER_OUTCOME_CONSEQUENCES_OK`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/TwooterMessageCooldownTest.tscn` -> `TWOOTER_MESSAGE_COOLDOWN_OK`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/TwooterFallbackDialogTest.tscn` -> `TWOOTER_FALLBACK_DIALOG_OK`
  - Steam initialization warnings and existing multi-option Network dialog warnings appeared in headless mode and are expected local noise.

### 2026-06-22 - Task 4 complete

- Added generated private Network clue integration inside `ContactNetworkSystem.request_tip`.
- Network tip requests now prefer an eligible active dossier `private_clue` with `surface_id = "network"` and `visibility = "private"` before falling back to the existing corporate-action/contact-arc tip flow.
- Generated Network tips respect:
  - clue reveal window
  - `required_recognition_min`
  - `required_relationship_stage`
  - contact relationship
  - contact/source quality for specific directness
- Trusted-but-not-inner contacts can receive stronger private reads, but `specific` directness is downgraded to `high` unless the contact has inner-level relationship, recognition, and source quality.
- Inner-level contacts can receive `specific` generated Network reads when the clue and contact quality justify it.
- Generated Network tip results and journal rows preserve traceability metadata:
  - `generated_content_surface`
  - `generated_surface_id = "network"`
  - `source_system_id = "company_story_dossier"`
  - `story_id`
  - `source_fact_ids`
  - `source_clue_ids`
  - `source_company_ids`
  - `source_sector_ids`
  - `visibility`, `detail_level`, `reliability`, `leak_risk`, `source_quality`, and directness fields
- Added `ContentSurfaceNetworkPrivateClueTest` with fixed-seed hash `160102873`.
- The test uses a real fixed-seed generated dossier/private clue, then upgrades that one clue in test state to `specific`/`operator` so the relationship/directness gate is exercised deterministically without changing default dossier generation.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceNetworkPrivateClueTest.tscn` -> `CONTENT_SURFACE_NETWORK_PRIVATE_CLUE_OK {"company_id":"kelola_mart_sentosa","day_index":75,"hash":"160102873","inner_confidence":"High conviction","inner_directness":"specific","inner_journal_generated":true,"issue_count":0,"issues":[],"seed":20260622,"story_id":"story|kelola_mart_sentosa|capex_expansion|1676237476","trusted_confidence":"Early but credible","trusted_directness":"high","trusted_journal_generated":true}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/NetworkThirtyDayScenarioTest.tscn` -> `CONTACT_NETWORK_30_DAY_OK ... "scenario_hash":"1539516458" ...`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/NetworkHighRecognitionScenarioTest.tscn` -> `CONTACT_NETWORK_HIGH_RECOGNITION_OK ... "twooter_stage":"inner_circle_candidate" ... "direct_tip_direction":"buy" ...`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/NetworkInnerCircleProgressionAuditTest.tscn` -> `NETWORK_INNER_CIRCLE_BASELINE_OK hash=1825575415 stages=4 high_after_exposed=false high_before_exposed=false`
  - Steam initialization warnings and existing multi-option Network dialog warnings appeared in headless mode and are expected local noise.

### 2026-06-22 - Task 5 complete

- Added generated-surface thesis evidence preservation across Research Tray capture, thesis attachment, direct thesis evidence add, save/load normalization, and report generation.
- Generated News and Twooter capture payload builders now forward surface metadata from visible generated items into evidence rows:
  - `generated_content_surface`
  - `generated_surface_id`
  - `source_system_id`
  - `story_id`
  - `source_fact_ids`
  - `source_clue_ids`
  - company/sector/source visibility and reliability fields
- Network journal snapshot rows now preserve generated Network tip provenance from saved tip rows, so generated Network reads have a capturable evidence shape.
- Annual filing capture metadata now tags filing excerpts as generated surface evidence and aliases existing `fact_ids` / `clue_ids` into the shared `source_fact_ids` / `source_clue_ids` contract.
- `ThesisEvidenceCaptureSystem`, `ThesisManager`, and `RunState` now preserve the shared generated-surface metadata through:
  - Research Tray rows
  - attached thesis evidence
  - direct thesis evidence add
  - saved/reloaded research rows
  - saved/reloaded thesis evidence rows
- Added `ContentSurfaceThesisEvidenceCaptureTest` with fixed-seed hash `650364612`.
- The test captures generated News, Twooter, Network, and filing evidence for the same company/story, attaches them to a thesis, generates a thesis report, and verifies save/load preservation without visible hidden-id leaks.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceThesisEvidenceCaptureTest.tscn` -> `CONTENT_SURFACE_THESIS_EVIDENCE_CAPTURE_OK {"capture_count":4,"company_id":"kelola_mart_sentosa","hash":"650364612","issue_count":0,"issues":[],"saved_attached_count":4,"seed":20260622,"story_id":"story|kelola_mart_sentosa|capex_expansion|1676237476"}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceNewsPreviewTest.tscn` -> unchanged hash `219414638`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceTwooterPreviewTest.tscn` -> unchanged hash `2185776077`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceNetworkPrivateClueTest.tscn` -> unchanged hash `160102873`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ThesisResearchTrayTest.tscn` -> `THESIS_RESEARCH_TRAY_OK`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ThesisFingerprintTest.tscn` -> unchanged thesis/report hashes
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualReportFidelityCaptureTest.tscn` -> unchanged hash `906899410`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - Steam initialization warnings appeared in headless mode and are expected local noise.

### 2026-06-22 - Task 6 complete

- Added `ContentSurfaceConsistencyReachabilityTest` as the fixed-seed consistency and reachability guard for generated content surfaces.
- The test builds a catalog-backed fixed-seed run, selects one story with generated News, Twooter, Network, and annual filing paths, and validates all four surfaces against the shared generated-item metadata contract.
- The guard checks:
  - no missing source system, story id, source fact ids, or source clue ids
  - public News and Twooter remain `public`, have zero leak risk, do not reference private Network clue ids, do not carry source-quality metadata, and do not show hidden ids or direct trade instructions in visible copy
  - Network rows remain `private` and carry a private clue path
  - filing rows remain `filing`
  - every important fact/clue used by the story's selected surfaces has at least one reachable generated path
  - generated surface rows can still be captured as thesis evidence without losing fact/clue traceability
- Locked fixed-seed consistency hash `2369856367`.
- Content Surface Generation is now complete through Task 6.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceConsistencyReachabilityTest.tscn` -> `CONTENT_SURFACE_CONSISTENCY_REACHABILITY_OK {"company_id":"kelola_mart_sentosa","hash":"2369856367","important_clue_count":4,"important_fact_count":4,"issue_count":0,"issues":[],"seed":20260622,"story_id":"story|kelola_mart_sentosa|capex_expansion|1676237476","surface_count":4,"thesis_capture_count":4}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceNewsPreviewTest.tscn` -> unchanged hash `219414638`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceTwooterPreviewTest.tscn` -> unchanged hash `2185776077`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceNetworkPrivateClueTest.tscn` -> unchanged hash `160102873`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceThesisEvidenceCaptureTest.tscn` -> unchanged hash `650364612`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`
  - `/Users/user/.local/bin/godot --headless -e --quit` -> passed
  - `git diff --check` -> passed
  - Steam initialization warnings and headless RID cleanup warnings appeared in headless mode and are expected local noise.

---

## Task 1 - Define surface reveal rules

Problem: Content systems need clear boundaries before generated clues can be trusted.

1. Define what macro news, sector news, company news, Twooter chatter, Network tips, and filings can reveal.
2. Define reliability, delay, and detail level per surface.
3. Document what should never leak publicly.
4. Verify:
   - Design review in this doc.
   - `git diff --check`

Implementation status: complete. The surface reveal contract now defines shared generated-item metadata, public/private boundaries, detail levels, reliability rules, and the implementation order for Tasks 2-6. This task is documentation-only by design.

## Task 2 - Add generated news previews

Problem: News should be able to surface macro, sector, and company facts from the dossier.

1. Generate a small number of news preview items from structured facts.
2. Keep existing authored news intact.
3. Include source fact ids for testability.
4. Verify:
   - Generated preview test.
   - No duplicate spam in quick smoke.

Implementation status: complete. `NewsFeedSystem` now derives a bounded set of public generated preview articles from active dossier news clues, preserving authored articles and carrying source fact/clue traceability. The fixed-seed preview test covers company, sector, and macro generated news surfaces plus public/private leak checks.

## Task 3 - Add generated Twooter previews

Problem: Twooter should reflect public chatter without becoming the canonical truth store.

1. Generate Twooter preview posts from public story facts.
2. Vary tone and confidence by account type.
3. Avoid exposing private Network-only clues.
4. Verify:
   - Generated Twooter preview test.
   - Existing Twooter interaction tests.

Implementation status: complete. `TwooterFeedSystem` now derives bounded public generated Twooter posts from active dossier Twooter clues, preserving authored posts and carrying source fact/clue traceability. The fixed-seed preview test covers company, sector, and macro generated Twooter scopes, account voice variation, public confidence-label variation, authored-post coexistence, and public/private leak checks.

## Task 4 - Add Network private clue integration

Problem: Trusted contacts should reveal better information than public surfaces.

1. Map dossier private clues to Network contact stages.
2. Respect relationship/recognition thresholds.
3. Keep inner-circle tips direct only when the relationship and source quality justify it.
4. Verify:
   - Contact network targeted scenario.
   - Inner-circle scenario remains coherent.

Implementation status: complete. `ContactNetworkSystem.request_tip` now maps eligible dossier `private_clues` into generated Network tip results and journal rows before using the older fallback tip flow. The fixed-seed test covers traceability, public-copy hidden-token safety, trusted-stage directness downgrade, inner-level specific directness, and journal persistence.

## Task 5 - Add thesis evidence integration

Problem: Generated content should be capturable as thesis evidence.

1. Add evidence shapes for generated news, Twooter, Network, and filing clues.
2. Keep source fact ids available for report generation.
3. Verify:
   - Thesis evidence capture test.
   - Thesis report still renders.

Implementation status: complete. Generated News, Twooter, Network, and filing evidence now share a preserved metadata contract through Research Tray capture, thesis attachment, direct evidence add, thesis report generation, and save/load. The fixed-seed capture test covers all four generated surfaces on one company/story and verifies source fact/clue traceability plus hidden-id safety.

## Task 6 - Add consistency and reachability tests

Problem: Generated content can become unreachable or contradictory as rules grow.

1. Add a fixed-seed test that generates all surfaces for a story.
2. Check that public/private rules hold.
3. Check that at least one clue path exists for important story facts.
4. Verify:
   - Consistency test passes.
   - Quick smoke.

Implementation status: complete. `ContentSurfaceConsistencyReachabilityTest` now generates News, Twooter, Network, filing, and thesis-capture paths for one fixed-seed story and verifies public/private boundaries, fact/clue traceability, important fact/clue reachability, and hidden-token safety. The pinned fixed-seed hash is `2369856367`.

## Known traps

- Hand-authored exceptions can drift from generated story truth.
- Public surfaces should have noise and disagreement; private clues should be better but still not always perfect.
- Generated text should be concise enough for UI constraints.
