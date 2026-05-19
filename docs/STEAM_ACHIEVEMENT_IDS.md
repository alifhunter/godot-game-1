# Steam Stats And Achievement IDs

Status: implemented in-game, pending Steamworks stat/achievement setup for App ID `4739020`.

Source data: `data/steam/achievement_catalog.json`
Runtime integration: `autoloads/SteamProgressManager.gd`

Official reference:
- Steam Stats and Achievements: https://partner.steamgames.com/doc/features/achievements
- Step by Step Achievements: https://partner.steamgames.com/doc/features/achievements/ach_guide

## Naming Rules

- Use stable uppercase API names like `ACH_FIRST_TRADE`.
- Do not rename API names after publishing unless we are ready to migrate code and Steamworks config together.
- Display names and descriptions can be adjusted/localized later.
- Keep the initial Early Access set modest. It should reward learning, survival, and different play styles, not push players into unhealthy grinding.

## Initial Achievement Set

| API Name | Display Name | Trigger |
| --- | --- | --- |
| `ACH_FIRST_TRADE` | First Ticket | First successful buy or sell order |
| `ACH_FIRST_PROFIT` | Green Exit | First realized profitable sell |
| `ACH_FIRST_WATCHLIST` | On The Radar | First watchlist add |
| `ACH_READ_FIRST_NEWS` | Read The Room | First opened News article detail |
| `ACH_CHECK_KEY_STATS` | Helicopter View | First opened Key Stats tab |
| `ACH_FIRST_CHART_PATTERN` | Pattern Claim | First accepted chart pattern claim |
| `ACH_FIRST_THESIS` | Write The Case | First thesis created |
| `ACH_FIRST_UPGRADE` | Tool Upgrade | First upgrade purchase |
| `ACH_MEET_FIRST_CONTACT` | First Handshake | First Network contact met |
| `ACH_FIRST_TIP` | Market Whisper | First Network tip received |
| `ACH_ATTEND_RUPSLB` | Minority Holder | First interactive RUPSLB attended |
| `ACH_SURVIVE_FIRST_MONTH` | First Month Survived | Reach roughly 20 trading days |
| `ACH_FIRST_GREEN_MONTH` | Close Green | Finish a month with positive portfolio performance |
| `ACH_RECOVER_DRAWDOWN` | Back From Red | Recover above prior high after a meaningful drawdown |
| `ACH_COMPLETE_FIRST_ACADEMY_LESSON` | Study Session | First Academy lesson completed |
| `ACH_COMPLETE_TECHNICAL_PATH` | Chart Student | First technical Academy path completed |
| `ACH_NORMAL_MONTH` | Normal Pressure | Survive one month on Normal |
| `ACH_GRIND_MONTH` | Grind Mode Survivor | Survive one month on Grind |
| `ACH_OPERATOR_SCARS` | Operator Scars | Hidden optional speculative survival moment |
| `ACH_CONTROL_ROOM` | Control Room | Hidden optional majority-control milestone |

## Implemented Stats

| API Name | Type | Use |
| --- | --- | --- |
| `STAT_TRADES_PLACED` | `INT` | Progress for first trade and future trade-count goals |
| `STAT_PROFITABLE_SELLS` | `INT` | Progress for profitable exits |
| `STAT_DAYS_SURVIVED` | `INT` | Progress for survival milestones |
| `STAT_GREEN_MONTHS` | `INT` | Progress for monthly performance milestones |
| `STAT_ACADEMY_LESSONS_COMPLETED` | `INT` | Progress for learning milestones |
| `STAT_NETWORK_CONTACTS_MET` | `INT` | Progress for Network milestones |
| `STAT_RUPSLB_ATTENDED` | `INT` | Progress for corporate-action attendance |
| `STAT_THESES_CREATED` | `INT` | Progress for thesis milestones |
| `STAT_UPGRADES_PURCHASED` | `INT` | Progress for upgrade milestones |
| `STAT_CHART_PATTERNS_CLAIMED` | `INT` | Progress for chart-learning milestones |
| `STAT_BUY_ORDERS` | `INT` | Buy-side order count |
| `STAT_SELL_ORDERS` | `INT` | Sell-side order count |
| `STAT_LOTS_TRADED` | `INT` | Total exchange lots traded |
| `STAT_WATCHLIST_ADDS` | `INT` | Watchlist adds |
| `STAT_NEWS_ARTICLES_READ` | `INT` | News article detail opens |
| `STAT_STOCKBOT_TAB_VIEWS` | `INT` | Stockbot research tab opens |
| `STAT_KEY_STATS_INSPECTED` | `INT` | Key Stats tab opens |
| `STAT_FINANCIALS_INSPECTED` | `INT` | Financials tab opens |
| `STAT_BROKER_FLOW_INSPECTED` | `INT` | Broker tab opens |
| `STAT_CORP_ACTION_INSPECTED` | `INT` | Corp. Action tab opens |
| `STAT_PROFILE_INSPECTED` | `INT` | Profile tab opens |
| `STAT_RESEARCH_EVIDENCE_CAPTURED` | `INT` | Thesis tray captures |
| `STAT_RESEARCH_EVIDENCE_ATTACHED` | `INT` | Evidence attached to theses |
| `STAT_NETWORK_TIPS_REQUESTED` | `INT` | Network tip requests |
| `STAT_CORPORATE_MEETING_VOTES` | `INT` | Corporate meeting votes |
| `STAT_ACADEMY_QUIZZES_PASSED` | `INT` | Academy quiz passes |
| `STAT_LIFE_PROPERTIES_PURCHASED` | `INT` | Life property purchases |
| `STAT_LIFE_CARS_PURCHASED` | `INT` | Life car purchases |
| `STAT_EMERGENCY_LOANS_TAKEN` | `INT` | Emergency loans taken |

## Runtime Notes

- Gameplay code records events through `SteamProgressManager`; it keeps a local mirror in the save under `steam_progress`.
- The manager syncs local stats to Steam with `requestCurrentStats`, `setStatInt`, `setAchievement`, and `storeStats` when Steam is available.
- `steam/progress/store_enabled=true` controls Steam writes. Tests can disable this while still validating local progress.
- Old saves backfill durable totals where possible: days survived, current watchlist size, thesis count, research tray count, upgrades, Academy progress, contacts met, RUPSLB attendance, and Life assets.

## Steamworks Setup Notes

- Create stats first, then achievements that use progress stats.
- Use `Client` as the setter for this first pass.
- Use exact API names from `data/steam/achievement_catalog.json`; random/generated ticker names should never be Steam stat IDs.
- Icons are still needed before public release:
  - achieved icon
  - unachieved icon
- After Steamworks setup is published, run `SteamProgressManagerTest.tscn` locally and then a real Steam branch smoke to confirm unlocks and stats appear.
