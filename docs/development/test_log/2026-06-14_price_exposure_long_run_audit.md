# 2026-06-14 Price Exposure Long-Run Audit

## Scope

Task 5 verification for `docs/development/top_down_market/PRICE_ENGINE_EXPOSURE_INTEGRATION_ENHANCEMENT.md`.

This audit validates the catalog-backed price exposure integration over longer deterministic runs.

## Test setup

- Godot: `/Users/user/.local/bin/godot`
- Scene: `res://scenes/tests/MarketYearAudit.tscn`
- Seed: `20260614`
- Difficulty: `normal`
- Company source: company universe catalog
- Company count: `50`
- Report mode: compact audit report

Commands:

```bash
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/MarketYearAudit.tscn -- --audit-seed 20260614 --audit-difficulty normal --audit-days 120 --audit-use-catalog --audit-company-count 50 --audit-compact-report
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/MarketYearAudit.tscn -- --audit-seed 20260614 --audit-difficulty normal --audit-days 225 --audit-use-catalog --audit-company-count 50 --audit-compact-report
```

Known warning noise:

- Steam init warnings are expected in headless local runs when Steam is not running.
- A discarded parser-pipe attempt crashed during Godot startup while opening `user://logs/...`; direct headless runs completed and are the recorded results.

## Overall result

Pass.

- 120-day audit completed.
- 225-day audit completed.
- No script errors, assertion failures, or new runtime spam appeared beyond known Steam/headless warning noise.
- Price exposure telemetry populated every stock-day:
  - 120-day run: `6,000` stock-days
  - 225-day run: `11,250` stock-days

## 120-day result

Runtime:

- Days completed: `120`
- Final trade date: `2020-07-02`
- Elapsed: `47,474.079 ms`
- Companies: `50`

Portfolio:

- Cash: `100,000,000`
- Market value: `0`
- Equity: `100,000,000`
- Holdings: `0`

Stock movement:

- Advancers: `11`
- Decliners: `39`
- Average return: `-25.26%`
- Median return: `-37.73%`
- Final price at floor: `0`
- Floor zombies: `0`
- Stocks over `200%`: `1`

Highest performer:

- `DCES` Data Center Estate
- Return: `261.60%`
- Final price: `2,260`
- Gorengan phase: `markup`, common tier, wave `3`

Lowest performer:

- `RASA` Rasa Kopi Nusantara
- Return: `-91.76%`
- Final price: `62`
- Gorengan phase: `cooldown`, common tier, wave `C`

Top 5:

| Ticker | Company | Return |
|---|---|---:|
| DCES | Data Center Estate | `261.60%` |
| SWIT | Sawit Bumi Raya | `80.95%` |
| BVKN | Biotek Vaksin Nusa | `59.37%` |
| DDCA | Dompet Digital Capital | `55.64%` |
| SPWR | Surya Power Nusantara | `48.34%` |

Events:

| Metric | Count |
|---|---:|
| Scheduled events | `12` |
| Scheduled company events | `9` |
| Scheduled person events | `2` |
| Company report events | `102` |
| Quarterly filings applied | `102` |
| Corporate action events | `195` |
| Corporate action hard events | `140` |
| Corporate action rumor/soft events | `49` |
| Index review events | `26` |
| Company arc events | `9` |
| Company roadmap events | `13` |
| Special events | `9` |
| Policy parody events | `5` |
| Abnormal move stock-days | `1,907` |
| Floor stabilizer stock-days | `225` |

Most common event ids:

- `cash_dividend`: `98`
- `earnings_miss`: `90`
- `rights_issue`: `34`
- `private_placement`: `30`
- `stock_buyback`: `25`
- `earnings_beat`: `20`

Gorengan campaigns:

- Started: `20`
- Dump seen: `2`
- Successful executed: `0`
- By tier: common `18`, rare `1`, legendary `1`
- Largest active campaign high: `DCES` at `340.80%` max realized return

Price exposure:

- Active stock-days: `6,000`
- Positive drift stock-days: `2,400`
- Negative drift stock-days: `3,600`
- Average drift: `0.2214 bps`
- Average absolute drift: `1.9594 bps`
- Average confidence: `0.2469`
- Average volatility multiplier: `1.0164`
- Average volume multiplier: `1.0291`
- Positive-exposure average return: `-19.74%`
- Negative-exposure average return: `-28.94%`

Top exposure tailwinds:

| Ticker | Summary | Avg drift | Return |
|---|---|---:|---:|
| BARA | Thermal Coal, Energy Demand, Global Trade | `15.33 bps` | `-36.91%` |
| KMIG | Crude Oil, Energy Demand, Global Trade | `10.31 bps` | `16.40%` |
| SWIT | Crude Palm Oil, Export Policy, Fx | `7.43 bps` | `80.95%` |
| KMIN | Thermal Coal, Global Trade, Interest Rate | `3.79 bps` | `-20.14%` |
| PLBN | Global Trade, Thermal Coal, Crude Palm Oil | `3.44 bps` | `-38.60%` |

Top exposure headwinds:

| Ticker | Summary | Avg drift | Return |
|---|---|---:|---:|
| AKRN | Refined Fuel, Interest Rate, Digital Adoption | `-4.84 bps` | `-77.93%` |
| SSMA | Silica Sand, Solar Demand, Global Trade | `-3.45 bps` | `-48.28%` |
| PDGP | Interest Rate, Digital Adoption, Consumer Confidence | `-2.76 bps` | `-50.65%` |
| KOMP | Interest Rate, Property Cycle, Infrastructure Budget | `-2.68 bps` | `-77.38%` |
| KIMS | Crude Oil, Industrial Activity, Fx | `-2.63 bps` | `-34.30%` |

Turnover:

- Average market value per day: `9.09T`
- Average gorengan value per day: `5.67T`
- Max market value: `22.82T` on day `97`
- Max gorengan value: `18.37T` on day `97`

## 225-day result

Runtime:

- Days completed: `225`
- Final trade date: `2020-12-02`
- Elapsed: `108,071.925 ms`
- Companies: `50`

Portfolio:

- Cash: `100,000,000`
- Market value: `0`
- Equity: `100,000,000`
- Holdings: `0`

Stock movement:

- Advancers: `14`
- Decliners: `36`
- Average return: `19.25%`
- Median return: `-59.90%`
- Final price at floor: `2`
- Floor zombies: `2`
- Stocks over `200%`: `7`

Highest performer:

- `SWIT` Sawit Bumi Raya
- Return: `732.33%`
- Final price: `66,062`
- Exposure tailwind: Crude Palm Oil, Export Policy, Fx

Lowest performer:

- `KBLK` Kapal Bulk Sentosa
- Return: `-94.25%`
- Final price: `217`
- Gorengan phase: `markup`, common tier, wave `3`

Top 5:

| Ticker | Company | Return |
|---|---|---:|
| SWIT | Sawit Bumi Raya | `732.33%` |
| SPWR | Surya Power Nusantara | `554.63%` |
| BVKN | Biotek Vaksin Nusa | `378.40%` |
| DCES | Data Center Estate | `362.40%` |
| KELA | Kelola Mart Sentosa | `334.70%` |

Events:

| Metric | Count |
|---|---:|
| Scheduled events | `22` |
| Scheduled company events | `13` |
| Scheduled sector events | `1` |
| Scheduled person events | `2` |
| Company report events | `200` |
| Quarterly filings applied | `200` |
| Corporate action events | `226` |
| Corporate action hard events | `156` |
| Corporate action rumor/soft events | `64` |
| Index review events | `44` |
| Company arc events | `29` |
| Company roadmap events | `28` |
| Special events | `18` |
| Policy parody events | `9` |
| Abnormal move stock-days | `6,296` |
| Floor stabilizer stock-days | `1,080` |
| Floor zombie stock-days | `96` |

Special events:

- `commodity_price_shock`: `3`
- `covid_wave`: `2`
- `geopolitical_turmoil`: `4`
- `policy_commodity_export_gate`: `3`
- `policy_fiscal_guardian_swap`: `2`
- `policy_free_lunch_budget_balloon`: `1`
- `policy_market_speech_jolt`: `3`

Most common event ids:

- `earnings_miss`: `174`
- `cash_dividend`: `105`
- `earnings_beat`: `46`
- `rights_issue`: `43`
- `stock_buyback`: `39`
- `private_placement`: `30`

Gorengan campaigns:

- Started: `22`
- Dump seen: `5`
- Successful executed: `0`
- By tier: common `20`, rare `1`, legendary `1`
- Largest active campaign highs:
  - `SPWR`: `626.06%`
  - `DCES`: `623.20%`
  - `BVKN`: `421.67%`
  - `KELA`: `354.38%`
  - `GRLE`: `321.83%`

Price exposure:

- Active stock-days: `11,250`
- Positive drift stock-days: `4,500`
- Negative drift stock-days: `6,750`
- Average drift: `0.2214 bps`
- Average absolute drift: `1.9594 bps`
- Average confidence: `0.2469`
- Average volatility multiplier: `1.0164`
- Average volume multiplier: `1.0291`
- Positive-exposure average return: `56.28%`
- Negative-exposure average return: `-5.43%`

Top exposure tailwinds:

| Ticker | Summary | Avg drift | Return |
|---|---|---:|---:|
| BARA | Thermal Coal, Energy Demand, Global Trade | `15.33 bps` | `-66.11%` |
| KMIG | Crude Oil, Energy Demand, Global Trade | `10.31 bps` | `36.70%` |
| SWIT | Crude Palm Oil, Export Policy, Fx | `7.43 bps` | `732.33%` |
| KMIN | Thermal Coal, Global Trade, Interest Rate | `3.79 bps` | `-9.72%` |
| PLBN | Global Trade, Thermal Coal, Crude Palm Oil | `3.44 bps` | `-74.32%` |

Top exposure headwinds:

| Ticker | Summary | Avg drift | Return |
|---|---|---:|---:|
| AKRN | Refined Fuel, Interest Rate, Digital Adoption | `-4.84 bps` | `-86.38%` |
| SSMA | Silica Sand, Solar Demand, Global Trade | `-3.45 bps` | `-70.76%` |
| PDGP | Interest Rate, Digital Adoption, Consumer Confidence | `-2.76 bps` | `-81.02%` |
| KOMP | Interest Rate, Property Cycle, Infrastructure Budget | `-2.68 bps` | `-83.63%` |
| KIMS | Crude Oil, Industrial Activity, Fx | `-2.63 bps` | `-58.19%` |

Turnover:

- Average market value per day: `23.48T`
- Average gorengan value per day: `19.04T`
- Max market value: `53.40T` on day `193`
- Max gorengan value: `44.00T` on day `199`

## Notes

- The average exposure drift stayed identical between 120 and 225 days because the current commodity/macro state is yearly in this seed; each stock keeps the same exposure shape during 2020.
- The exposure resolver is influencing outcomes without overriding stronger systems. Example: `SWIT` had a moderate positive CPO/export tailwind and became the best 225-day stock, while `BARA` had the strongest coal tailwind but still declined under other price/event forces.
- Gorengan campaigns dominate some top performers, which is expected. Exposure should be interpreted as one bounded axis, not a guaranteed winner label.
- Player portfolio remains flat because the audit advances market state only; it does not execute trades.
