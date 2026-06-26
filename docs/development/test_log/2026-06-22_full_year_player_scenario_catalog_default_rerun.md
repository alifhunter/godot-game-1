# 2026-06-22 Full-Year Player Scenario - Catalog Default Rerun

## Scope

Full-year automated player scenario after enabling the company universe catalog as the default roster source.

This test opens the real game scene through Godot, validates the main app buttons, buys one stock, creates a thesis, attaches evidence, advances a full trading year, regenerates the thesis report, and records market, portfolio, event, attention, news, gorengan, and price-exposure metrics.

## Test setup

- Date: 2026-06-22
- Tester: Codex
- Godot: `/Users/user/.local/bin/godot`
- Scene: `res://scenes/tests/FullYearPlayerScenarioTest.tscn`
- Game scene opened by test: `res://scenes/game/GameRoot.tscn`
- Seed: `20260622`
- Trading days requested: `225`
- Company roster mode: default catalog-backed roster
- Player flow: automated headless scenario, not manual mouse clicks

Command:

```bash
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FullYearPlayerScenarioTest.tscn
```

Validated controls in `GameRoot`:

- `StockAppButton`
- `NewsAppButton`
- `ThesisAppButton`
- `DesktopAdvanceDayButton`

Known warning noise:

- Steam init warnings are expected in local headless runs when Steam is not running.
- The test emitted one thesis vocabulary warning where evidence impact was corrected from `negative` to `positive` for a `support` interpretation.

## Overall result

Pass.

- 225 trading days completed.
- Game scene opened and core app buttons were present.
- One stock was bought and still held at the end of the year.
- One thesis was created.
- Three evidence groups were attached: `commodity`, `sector`, `filing`.
- Final thesis report generated successfully: `Research note generated. Spent 7 AP.`
- No assertion failures in the passing run.

## Runtime

| Metric | Value |
|---|---:|
| Days completed | `225` |
| Final day index | `226` |
| Final trade date | `2020-12-03` |
| Elapsed time | `296,122.22 ms` |
| Average elapsed per trading day | `1,316.10 ms` |

Performance note:

- Late-run state application commonly printed around `250-525 ms` per day for `30` companies.
- `normalize_companies` dominated the per-day state-application timing in the logged output.

## Player action

Selected stock:

| Field | Value |
|---|---|
| Ticker | `SDNX` |
| Company | `Satelit Data Nusantara` |
| Company id | `satelit_data_nusantara` |
| Selection reason | Highest initial combined quality/growth, public news, commodity, and story evidence score |
| Selection score | `139.0` |

Trade:

| Metric | Value |
|---|---:|
| Shares bought | `2,000` |
| Buy price | `2,397.00` |
| Buy cost | `4,801,191.00` |
| End average price | `2,400.60` |
| End shares held | `2,000` |
| Final price | `8,022.00` |
| Held return | `234.67%` |

Portfolio at year end:

| Metric | Value |
|---|---:|
| Cash | `1,757,709.00` |
| Market value | `16,044,000.00` |
| Equity | `17,801,709.00` |
| Holdings count | `1` |
| Realized P/L | `0.00` |

## Stock movement

Universe summary:

| Metric | Value |
|---|---:|
| Company count | `30` |
| Average return | `6.69%` |
| Median return | `-72.34%` |
| Advancers | `7` |
| Decliners | `23` |
| Flat | `0` |

Best performer:

| Field | Value |
|---|---|
| Ticker | `FBKP` |
| Company | `Fiber Kota Prima` |
| Sector | `infra` |
| Start price | `8,821.00` |
| Final price | `74,746.00` |
| Return | `747.36%` |
| Last daily change | `0.20%` |

Worst performer:

| Field | Value |
|---|---|
| Ticker | `KOMP` |
| Company | `Kota Mandiri Property` |
| Sector | `property` |
| Start price | `796.00` |
| Final price | `50.00` |
| Return | `-93.72%` |
| Last daily change | `-3.85%` |

Top 5:

| Ticker | Company | Sector | Return |
|---|---|---|---:|
| `FBKP` | Fiber Kota Prima | infra | `747.36%` |
| `WIKN` | Wisata Kuliner Nusantara | consumer | `707.03%` |
| `SDNX` | Satelit Data Nusantara | tech | `234.67%` |
| `SRDG` | Sekuritas Rakyat Digital | finance | `101.07%` |
| `KIMS` | Kimia Sentosa | basicindustry | `46.03%` |

Bottom 5:

| Ticker | Company | Sector | Return |
|---|---|---|---:|
| `KELA` | Kelola Mart Sentosa | consumer | `-87.27%` |
| `NKLM` | Nikel Makmur | basicindustry | `-88.13%` |
| `KBLK` | Kapal Bulk Sentosa | transport | `-89.66%` |
| `AKRN` | Armada Kurir Nusantara | transport | `-90.06%` |
| `KOMP` | Kota Mandiri Property | property | `-93.72%` |

## Event metrics

| Metric | Count |
|---|---:|
| Scheduled events | `21` |
| Company events | `120` |
| Quarterly report events | `120` |
| Corporate action events | `160` |
| Index review events | `47` |
| Special events | `0` |
| Dirty tip offers | `0` |
| Dirty tip results | `0` |
| Network request results | `0` |
| Network tip results | `0` |

Event family counts:

| Family | Count |
|---|---:|
| `corporate_action` | `160` |
| `company` | `129` |
| `index_review` | `47` |
| `person` | `5` |
| `market` | `4` |
| `sector` | `3` |

Corporate action category counts:

| Category | Count |
|---|---:|
| `corporate_action_execution` | `63` |
| `corporate_action_resolution` | `35` |
| `corporate_action_rumor` | `22` |
| `corporate_action_clarification` | `11` |
| `corporate_action_filing` | `11` |
| `corporate_action_speculation` | `11` |
| `corporate_action_denial` | `3` |
| `corporate_meeting` | `3` |
| `corporate_action_cancellation` | `1` |

Top event ids:

| Event id | Count |
|---|---:|
| `earnings_miss` | `104` |
| `cash_dividend` | `72` |
| `rights_issue` | `30` |
| `stock_buyback` | `28` |
| `earnings_beat` | `16` |
| `mscy_index_watch` | `16` |
| `ftsi_index_watch` | `12` |
| `stock_dividend` | `12` |
| `private_placement` | `8` |
| `rumor_wave_positive` | `8` |
| `ftsi_index_exclusion` | `6` |
| `ftsi_index_inclusion` | `6` |

## Gorengan metrics

| Metric | Value |
|---|---:|
| Campaigns started | `10` |
| Active dump-seen peak | `2` |
| Active successful peak | `0` |

Note:

- The peak fields are snapshot counts from active gorengan state, not unique lifetime completion counts.

## Attention director

Lane counts:

| Lane | Days |
|---|---:|
| `company` | `118` |
| `digestion` | `103` |
| `quiet` | `3` |
| `macro` | `1` |

Tier counts:

| Tier | Days |
|---|---:|
| `digestion` | `103` |
| `company_watch` | `92` |
| `clue_due` | `26` |
| `quiet` | `3` |
| `headline_reserved` | `1` |

Other attention metrics:

| Metric | Value |
|---|---:|
| Force company arc days | `26` |
| Force special days | `1` |
| Suppressed special days | `164` |
| Scenario company focus days | `225` |
| Average best company attention score | `0.8619` |
| Average market stress score | `0.2178` |
| Average dirty market pressure | `0.0000` |

Summary:

- Attention was split mostly between company and digestion lanes.
- The scenario company stayed in focus for all 225 trading days.
- Special events were suppressed for most of the year.

## News metrics

| Metric | Value |
|---|---:|
| Article count | `27` |

Outlet counts:

| Outlet | Count |
|---|---:|
| `harian_investor` | `11` |
| `gorengan_daily` | `9` |
| `waduh_finance` | `6` |
| `ordal_news` | `1` |

Top topic counts:

| Topic | Count |
|---|---:|
| `sector` | `19` |
| `market_wrap` | `13` |
| `company` | `10` |
| `corporate_action` | `9` |
| `earnings` | `8` |
| `filing` | `8` |
| `index_review` | `8` |
| `meeting` | `8` |
| `chatter` | `6` |
| `property_development` | `6` |

## Price exposure metrics

| Metric | Value |
|---|---:|
| Active stock-days | `6,750` |
| Average drift bps | `0.0164` |
| Average absolute drift bps | `1.8261` |

## Follow-up actions

- Watch performance on long UI-backed yearly scenarios; late-run `normalize_companies` is still the largest visible per-day cost.
- Compare this catalog-default run against the older MASA/procedural-era log before drawing balance conclusions, because the default company universe changed.
- Consider adding a timestamped or numbered log filename in the test runner if full-year scenarios are rerun multiple times in one day.
