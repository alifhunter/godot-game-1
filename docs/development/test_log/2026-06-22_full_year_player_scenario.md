# 2026-06-22 Full-Year Player Scenario

## Scope

Full-year automated player scenario for a 225-trading-day run.

This test opens the real game scene through Godot, validates the main app buttons, buys one stock, creates a thesis, attaches evidence, advances a full trading year, regenerates the thesis report, and records market, portfolio, event, attention, news, and gorengan metrics.

## Test setup

- Date: 2026-06-22
- Tester: Codex
- Godot: `/Users/user/.local/bin/godot`
- Scene: `res://scenes/tests/FullYearPlayerScenarioTest.tscn`
- Game scene opened by test: `res://scenes/game/GameRoot.tscn`
- Seed: `20260622`
- Trading days requested: `225`
- Investment ratio for passing run: `5%` of starting cash
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
- The test frees the live `GameRoot` before the long simulation phase so 225 trading days can advance through the fast simulation path instead of repainting the full UI every day.

## Overall result

Pass.

- 225 trading days completed.
- Game scene opened and core app buttons were present.
- One stock was bought and still held at the end of the year.
- One thesis was created.
- Three evidence groups were attached: `commodity`, `sector`, `filing`.
- Final thesis report generated successfully: `Research note generated. Spent 7 AP.`
- No assertion failures in the passing run.

## Calibration notes

Two earlier allocations found useful balance boundaries:

- `35%` starting-cash allocation failed at day offset `164` because cash-stress grace expired.
- `10%` allocation completed the 225-day simulation but ended with negative cash and failed final thesis-report validation.
- `5%` allocation completed, preserved positive cash, and passed final thesis-report validation.

This suggests a normal player who buys too aggressively without maintaining living cash can still hit cash stress during a year-long hold.

## Runtime

| Metric | Value |
|---|---:|
| Days completed | `225` |
| Final day index | `226` |
| Final trade date | `2020-12-03` |
| Elapsed time | `259,771.97 ms` |
| Average elapsed per trading day | `1,154.54 ms` |

Performance note:

- Late-run state application commonly printed around `220-580 ms` per day for `30` companies.
- `normalize_companies` dominated the per-day state-application timing in the logged output.

## Player action

Selected stock:

| Field | Value |
|---|---|
| Ticker | `MASA` |
| Company | `Mahkota Sawit Lestari` |
| Company id | `masa` |
| Selection reason | Highest initial combined quality/growth, public news, commodity, and story evidence score |
| Selection score | `152.7` |

Trade:

| Metric | Value |
|---|---:|
| Shares bought | `500` |
| Buy price | `9,551.00` |
| Buy cost | `4,782,663.25` |
| End average price | `9,565.33` |
| End shares held | `500` |
| Final price | `86,151.00` |
| Held return | `802.01%` |

Portfolio at year end:

| Metric | Value |
|---|---:|
| Cash | `1,792,961.75` |
| Market value | `43,075,500.00` |
| Equity | `44,868,461.75` |
| Holdings count | `1` |
| Realized P/L | `0.00` |

## Stock movement

Universe summary:

| Metric | Value |
|---|---:|
| Company count | `30` |
| Average return | `51.19%` |
| Median return | `-52.29%` |
| Advancers | `8` |
| Decliners | `22` |
| Flat | `0` |

Best performer:

| Field | Value |
|---|---|
| Ticker | `SERE` |
| Company | `Sembada Resto` |
| Sector | `consumer` |
| Start price | `1,322.00` |
| Final price | `11,927.00` |
| Return | `802.19%` |
| Last daily change | `-4.98%` |

Worst performer:

| Field | Value |
|---|---|
| Ticker | `SAES` |
| Company | `Sari Estate Indonesia` |
| Sector | `property` |
| Start price | `689.00` |
| Final price | `50.00` |
| Return | `-92.74%` |
| Last daily change | `0.00%` |

Top 5:

| Ticker | Company | Sector | Return |
|---|---|---|---:|
| `SERE` | Sembada Resto | consumer | `802.19%` |
| `MASA` | Mahkota Sawit Lestari | noncyclical | `802.01%` |
| `SECH` | Sejahtera Chemical | basicindustry | `520.36%` |
| `NURE` | Nusantara Realty | property | `477.16%` |
| `MIIN` | Mitra Ingredient | health | `106.95%` |

Bottom 5:

| Ticker | Company | Sector | Return |
|---|---|---|---:|
| `PEPR` | Perdana Properti International | property | `-86.63%` |
| `HASH` | Harapan Shipping | transport | `-89.25%` |
| `PETA` | Persada Tanker | transport | `-89.86%` |
| `MAWO` | Mandiri Works | infra | `-92.15%` |
| `SAES` | Sari Estate Indonesia | property | `-92.74%` |

## Event metrics

| Metric | Count |
|---|---:|
| Scheduled events | `20` |
| Company events | `120` |
| Quarterly report events | `120` |
| Corporate action events | `242` |
| Index review events | `44` |
| Special events | `0` |
| Dirty tip offers | `0` |
| Dirty tip results | `0` |
| Network request results | `0` |
| Network tip results | `0` |

Event family counts:

| Family | Count |
|---|---:|
| `corporate_action` | `242` |
| `company` | `128` |
| `index_review` | `44` |
| `market` | `4` |
| `person` | `4` |
| `sector` | `4` |

Corporate action category counts:

| Category | Count |
|---|---:|
| `corporate_action_execution` | `73` |
| `corporate_action_resolution` | `47` |
| `corporate_action_rumor` | `47` |
| `corporate_action_clarification` | `23` |
| `corporate_action_filing` | `23` |
| `corporate_action_speculation` | `23` |
| `corporate_action_denial` | `4` |
| `corporate_meeting` | `2` |

Top event ids:

| Event id | Count |
|---|---:|
| `earnings_miss` | `106` |
| `rights_issue` | `103` |
| `cash_dividend` | `60` |
| `private_placement` | `35` |
| `stock_buyback` | `21` |
| `stock_dividend` | `18` |
| `mscy_index_watch` | `16` |
| `earnings_beat` | `14` |
| `ftsi_index_watch` | `12` |
| `stock_split` | `5` |
| `index_review_no_change` | `4` |
| `mscy_index_exclusion` | `4` |

## Gorengan metrics

| Metric | Value |
|---|---:|
| Campaigns started | `11` |
| Active dump-seen peak | `6` |
| Active successful peak | `0` |

Note:

- The peak fields are snapshot counts from active gorengan state, not unique lifetime completion counts.

## Attention director

Lane counts:

| Lane | Days |
|---|---:|
| `digestion` | `151` |
| `company` | `65` |
| `macro` | `6` |
| `quiet` | `3` |

Tier counts:

| Tier | Days |
|---|---:|
| `digestion` | `151` |
| `company_watch` | `48` |
| `clue_due` | `17` |
| `normal` | `5` |
| `quiet` | `3` |
| `headline_reserved` | `1` |

Other attention metrics:

| Metric | Value |
|---|---:|
| Force company arc days | `17` |
| Force special days | `1` |
| Suppressed special days | `178` |
| Scenario company focus days | `0` |
| Average best company attention score | `0.7956` |
| Average market stress score | `0.2024` |
| Average dirty market pressure | `0.0000` |

Summary:

- Attention was mostly in digestion mode, which matches the heavy event/corporate-action calendar.
- Special events were effectively suppressed for most of the year.
- Company attention still appeared regularly through `company_watch` and `clue_due` days.

## News metrics

| Metric | Value |
|---|---:|
| Article count | `32` |

Outlet counts:

| Outlet | Count |
|---|---:|
| `harian_investor` | `10` |
| `gorengan_daily` | `9` |
| `ordal_news` | `7` |
| `waduh_finance` | `6` |

Top topic counts:

| Topic | Count |
|---|---:|
| `sector` | `25` |
| `market_wrap` | `15` |
| `company` | `12` |
| `corporate_action` | `8` |
| `earnings` | `8` |
| `filing` | `8` |
| `index_review` | `8` |
| `meeting` | `8` |
| `property_development` | `8` |
| `chatter` | `6` |

## Price exposure metrics

| Metric | Value |
|---|---:|
| Active stock-days | `6,750` |
| Average drift bps | `0.0` |
| Average absolute drift bps | `0.0` |

Note:

- Exposure contexts existed, but aggregate drift fields were zero in this run. This may be expected if no direct drift was active, or it may indicate the audit should capture a more specific exposure-impact field in a future test.

## Follow-up actions

- Consider a separate portfolio stress test around year-long holds and living-expense pressure.
- Consider a targeted gorengan audit that records unique campaign outcomes, not only active snapshot peaks.
- Consider a price exposure audit that captures per-stock exposure signals and realized effect fields more explicitly.
- Keep the full-year scenario as a regression guard for thesis creation, evidence attachment, final report generation, and portfolio survival.
