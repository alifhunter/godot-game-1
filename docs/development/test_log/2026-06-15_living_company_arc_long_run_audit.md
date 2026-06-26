# 2026-06-15 Living Company Arc Long-Run Audit

## Scope

Task 5 verification for `docs/development/top_down_market/LIVING_COMPANY_ARC_SYSTEM_ENHANCEMENT.md`.

This audit validates that living company arc state remains bounded during a deterministic multi-month run and records whether companies keep cycling through active, cooldown, and eligible states.

## Test setup

- Godot: `/Users/user/.local/bin/godot`
- Scene: `res://scenes/tests/LivingCompanyArcLongRunAuditTest.tscn`
- Seed: `20260615`
- Difficulty: `normal`
- Company source: company universe catalog
- Company count: `50`
- Trading days: `120`

Command:

```bash
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/LivingCompanyArcLongRunAuditTest.tscn -- --living-arc-audit-seed 20260615 --living-arc-audit-difficulty normal --living-arc-audit-days 120 --living-arc-audit-use-catalog --living-arc-audit-company-count 50
```

Known warning noise:

- Steam init warnings are expected in headless local runs when Steam is not running.

## Overall result

Pass.

- 120 trading days completed.
- No script errors or assertion failures.
- No duplicate active arc ids or active company ids.
- Global recent completed history stayed capped at `80`.
- Per-company completed arc rows stayed capped at `8`.
- Story-memory recent arc ids stayed at or below `5`.
- Story-memory recent story tags stayed at or below `12`.

## Runtime result

- Days completed: `120`
- Final day index: `121`
- Final trade date: `2020-07-03`
- Companies: `50`
- Audit elapsed: `185,608.302 ms`

## Living arc metrics

Final status:

| Status | Companies |
|---|---:|
| Active | `6` |
| Cooling down | `26` |
| Eligible | `18` |
| Suppressed | `0` |

Lifecycle activity:

| Metric | Count |
|---|---:|
| Global completed arc count | `426` |
| Recent completed arc rows retained | `80` |
| Companies with any living activity | `40` |
| Stagnant companies | `10` |
| Repeat-activity companies | `37` |
| Max active arc count | `15` |
| Max active company count | `14` |
| Max cooldowned companies | `34` |
| Max completed rows per company | `8` |

Status stock-days:

| Status | Stock-days |
|---|---:|
| Active | `741` |
| Cooling down | `1,294` |
| Eligible | `4,015` |

## Event counts

| Event group | Count |
|---|---:|
| Started company arcs | `3` |
| Company arc phase events | `9` |
| Company roadmap events | `14` |
| Corporate action events | `180` |
| Index review events | `30` |

## Completion mix

Source completion counts retained in recent history:

| Source | Count |
|---|---:|
| Corporate action | `71` |
| Company roadmap | `6` |
| Index review | `3` |

Tone completion counts retained in recent history:

| Tone | Count |
|---|---:|
| Positive | `66` |
| Mixed | `12` |
| Negative | `2` |

Top retained completion event ids:

| Event id | Count |
|---|---:|
| `stock_buyback` | `41` |
| `cash_dividend` | `28` |
| `roadmap_financing_partner` | `3` |
| `ftsi_index_exclusion` | `2` |
| `roadmap_gas_power_asset` | `2` |
| `stock_dividend` | `2` |
| `ftsi_index_inclusion` | `1` |
| `roadmap_supplier_park` | `1` |

## Most active companies

| Ticker | Company | Completed count | Final status | Last source | Last event |
|---|---|---:|---|---|---|
| `DCES` | Data Center Estate | `68` | eligible | company_roadmap | roadmap_township_phase |
| `DIGN` | Diagnostik Sehat | `64` | active | corporate_action | stock_buyback |
| `TSAM` | Tanker Samudra | `47` | cooling_down | corporate_action | rights_issue |
| `BDGK` | Bank Digital Karya | `41` | active | corporate_action | stock_buyback |
| `RKGN` | Rel Kargo Nusantara | `34` | cooling_down | corporate_action | rights_issue |

## Notes

- The state-growth part of Task 5 passes: compact saved histories remain bounded even with frequent activity.
- Corporate actions dominate living arc completions in this run. This is not a state-growth bug, but it is a balancing signal. If the feed feels too noisy later, consider grouping repeated corporate action phases into fewer living completion rows or adding source-specific completion dedupe.
- Ten companies had no living arc activity after 120 trading days. That is acceptable for this first pass because the design does not require every company to have a story at all times.
