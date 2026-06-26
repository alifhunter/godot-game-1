# 2026-06-26 Performance Recovery Full Regression

## Summary

Performance Recovery task 8 regression completed on macOS using Godot `4.6.2.stable.official.71f334935`.

- Main result: PASS for targeted broker/save/perf tests and the 225-day player scenario.
- Product quick smoke: blocked by the known unrelated FTUE organic-chain assertion.
- Full-year scenario: `232,511.74ms` for 225 trading days, or `1,033.39ms/day`, with the 70-company catalog roster enabled.
- Normal-play explicit save flush is now cheap because the scheduled post-recap save drains first: `12.91ms`.
- Remaining performance risk: scheduled post-recap save still costs about `410ms`, and late-year 70-company normalization has visible spikes.

## Commands

```bash
/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_broker_compact_task8.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/BrokerHistoryCompactContractTest.tscn
/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_broker_migration_task8.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/BrokerHistoryMigrationTest.tscn
/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_broker_range_task8.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/BrokerRangeHistoryTest.tscn
/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_broker_hot_path_task8.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/BrokerHistoryHotPathPerfTest.tscn
/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_normal_play_task8.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/NormalPlayPerfTest.tscn -- --smoke-local-io
/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_quick_smoke_task8.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io
/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_full_year_task8.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/FullYearPlayerScenarioTest.tscn
```

## Targeted Tests

| Test | Result | Key metric |
|---|---|---|
| `BrokerHistoryCompactContractTest.tscn` | PASS | `BROKER_HISTORY_COMPACT_CONTRACT_OK v1_bytes=2083 v2_bytes=566 rows=20` |
| `BrokerHistoryMigrationTest.tscn` | PASS | `BROKER_HISTORY_MIGRATION_OK legacy_rows=126 migrated_rows=90 saved_rows=90` |
| `BrokerRangeHistoryTest.tscn` | PASS | `BROKER_RANGE_HISTORY_OK compact=45 mode=compact` |
| `BrokerHistoryHotPathPerfTest.tscn` | PASS | `BROKER_HISTORY_HOT_PATH_OK days=30 normalize_median=40.39ms normalize_late_max=58.99ms history_rows=50` |
| `NormalPlayPerfTest.tscn` | PASS | `NORMAL_PLAY_PERF_OK` |
| Quick smoke | Known unrelated failure | `First-month smoke found more than 2 organic chains through day 25` |
| `FullYearPlayerScenarioTest.tscn` | PASS | `FULL_YEAR_PLAYER_SCENARIO_OK` |

## Normal-Play Metrics

| Metric | Value |
|---|---:|
| Open Network | `266.55ms` |
| Open Stock | `262.12ms` |
| Open News | `629.22ms` |
| Open Network with News already open | `400.56ms` |
| Advance Day, Network open | `1,315.25ms` |
| Advance Day, desktop only | `1,383.78ms` |
| Advance Day, Stock open | `1,099.58ms` |
| Advance Day, News + Network open | `1,245.18ms` |
| Scheduled post-recap save flush | `409.97ms` |
| Explicit forced save flush after scheduled flush | `12.91ms` |
| Local save size | `3,464,461 bytes` |

Save phase split from the final scheduled flush:

| Save phase | Value |
|---|---:|
| `to_save_dict_ms` | `191.014ms` |
| `serialize_ms` | `51.043ms` |
| `write_ms` | `4.275ms` |
| `replace_ms` | `6.585ms` |
| `save_run_ms` | `76.259ms` |
| `context_total_ms` | `381.817ms` |

Largest save sections:

| Section | Bytes |
|---|---:|
| `companies` | `1,692,153` |
| `company_story_dossier_state` | `705,262` |
| `quarterly_report_calendar` | `405,316` |
| `news_archive_articles` | `151,317` |
| `event_history` | `91,500` |

Broker-history payload:

| Metric | Value |
|---|---:|
| Company count | `30` |
| Rows/company | `25` |
| Total broker-history bytes | `480,957` |
| Average broker-history bytes/company | `16,031.9` |

## Full-Year Player Scenario

| Metric | Value |
|---|---:|
| Seed | `20260622` |
| Trading days requested | `225` |
| Trading days completed | `225` |
| Company count | `70` |
| Elapsed | `232,511.74ms` |
| Elapsed/day | `1,033.39ms` |
| Startup setup | `6,024.74ms` |
| Final trade date | `2020-12-03` |

Player and thesis sanity:

| Metric | Value |
|---|---|
| Bought stock | `BORI` / Bank Orang Indonesia |
| Shares bought | `500` |
| Buy price | `9,322.0` |
| Final price | `2,417.0` |
| Held return | `-74.07%` |
| Ending cash | `1,890,338.5` |
| Ending equity | `3,098,838.5` |
| Ending market value | `1,208,500.0` |
| Holdings count | `1` |
| Thesis evidence count | `5` |
| Thesis evidence groups | `commodity`, `sector`, `filing` |
| Thesis final report | Success |

Market outcome:

| Metric | Value |
|---|---:|
| Average stock return | `-47.88%` |
| Median stock return | `-75.05%` |
| Advancers / decliners / flat | `4 / 66 / 0` |
| Best stock | `DIGN` / Diagnostik Sehat, `+770.43%` |
| Worst stock | `SKSI` / Sistem Karya Siber, `-96.97%` |
| Price exposure active stock-days | `15,750` |
| Average drift | `-0.2486 bps` |
| Average absolute drift | `1.5115 bps` |

Events and content:

| Metric | Value |
|---|---:|
| Company events | `280` |
| Corporate action events | `229` |
| Quarterly report events | `280` |
| Index review events | `55` |
| Scheduled events | `19` |
| Special events | `0` |
| Gorengan campaigns started | `24` |
| Gorengan dump active peak | `7` |
| Gorengan successful active peak | `0` |
| News articles | `32` |

Attention director:

| Metric | Value |
|---|---:|
| Average best company attention score | `0.8243` |
| Average market stress score | `0.2319` |
| Company lane days | `111` |
| Digestion lane days | `109` |
| Macro lane days | `2` |
| Quiet lane days | `3` |
| Suppressed special days | `177` |

Annual filing check:

| Metric | Value |
|---|---|
| Generation timing | `lazy_on_request` |
| Cache status | `miss_built` |
| Opened filing company | `bank_orang_indonesia` |
| Filing profile | `bank` |
| Visible section count | `21` |
| Visible table count | `18` |
| Story note fact/prose count | `6 / 5` |
| Capture count/types | `3`: statement row, note table row, note paragraph |

## Remaining Risk

- The save recovery worked for player-facing explicit flushes, but the scheduled post-recap save still costs about `410ms`. The expensive piece is payload construction, especially `RunState.to_save_dict()`, not disk write.
- The 70-company late-year path still has normalization spikes. In this run, late-year `normalize_companies` samples reached `524.01ms` and `675.66ms` near day 200.
- Quick smoke still fails on the known FTUE organic-chain assertion. It should be fixed separately from performance recovery.
