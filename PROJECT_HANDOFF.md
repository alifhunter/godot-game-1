# The Daytrader Game Handoff

Read this file first in the next session.

## Project Snapshot
- Engine: Godot `4.6.1`
- Project path: `c:\Users\Alif\Documents\godot game 1\new-game-project`
- Current milestone: `first playable prototype`
- Start date in-game: `Thursday, 2 January 2020`
- Current structure: top navbar + body-row sidebar app shell with modular views and widget scenes

## Current Playable State
- Main menu supports `New Run`, `Load Run`, `Quit`
- `New Game` now opens a dedicated difficulty selector screen with four difficulty cards and a separate `Continue` step
- After the player confirms difficulty, a simple loading screen shows staged setup progress:
  - `Preparing market seed`
  - `Creating companies`
  - `Creating financials`
  - `Saving run`
  - `Opening trading desk`
- New Run supports difficulty presets:
  - `Newbie`
  - `Normal`
  - `Hard`
  - `Hardcore`
- Difficulty now also controls generated roster size:
  - `Newbie`: `20` companies
  - `Normal`: `50` companies
  - `Hard`: `100` companies
  - `Hardcore`: `200` companies
- Tutorial checkbox exists and currently shows a simple one-time popup
- Player loop is:
  - choose stock
  - read setup
  - inspect the generated `2010-2019` company history
  - trade in lots
  - advance day
  - review result
- Buy/sell feedback now appears as a bottom-right toast with manual close + `5s` auto-hide
- Portfolio screen now reads more like a broker app layout:
  - top summary strip
  - left holdings table
  - right history table
  - both lower tables now scroll horizontally on tighter widths so columns stay reachable

## Implemented Systems
- Core autoloads:
  - `autoloads/GameManager.gd`
  - `autoloads/RunState.gd`
  - `autoloads/DataRepository.gd`
  - `autoloads/SaveManager.gd`
- Market simulation:
  - `systems/MarketSimulator.gd`
  - daily price change uses market sentiment, sector sentiment, events, broker flow, mean reversion, and noise
- Broker flow:
  - `systems/BrokerFlowSystem.gd`
  - broker archetypes: retail, foreign, institution, zombie
- Summary system:
  - `systems/SummaryInsightSystem.gd`
- IDX price rules:
  - `systems/IDXPriceRules.gd`
  - tick size ladder implemented
  - ARA/ARB implemented
- Trading calendar:
  - `systems/TradingCalendar.gd`
  - skips weekends and 2020 IDX holiday list from `data/calendar/idx_holidays.json`
- Procedural company generation:
  - `systems/CompanyGenerator.gd`
  - generates hidden traits
  - generates annual financial history from `2010` to `2019`
  - derives 2020 opening fundamentals
  - derives `quality_score`, `growth_score`, `risk_score`, `base_volatility`, and `base_price`
- Procedural roster generation:
  - `systems/CompanyRosterGenerator.gd`
  - builds a fresh company list each run from archetype anchors + word-bank names
  - generates `2-3` word company names, unique `4-letter` tickers, sector assignment, and listing board

## Trading Rules
- Lot size: `1 lot = 100 shares`
- Buy fee: `0.15%`
- Sell fee: `0.25%`
- Trade history panel records:
  - day
  - ticker
  - side
  - lots
  - shares
  - price
  - gross
  - fee
  - cash impact
  - realized P/L on sells

## UI Layout
- Main menu flow:
  - `scenes/main_menu/MainMenu.tscn`
  - `scripts/ui/MainMenu.gd`
  - screens now switch between `Home`, `Difficulty selector`, and `Loading`
- Root shell:
  - `scenes/game/GameRoot.tscn`
  - `scripts/ui/GameRoot.gd`
- Navbar now sits at the top of the screen, with the sidebar below it in the main body row
- Sidebar sections:
  - `Dashboard`
  - `Markets`
  - `Portfolio`
  - `Help`
- View scenes:
  - `scenes/game/views/DashboardView.tscn`
  - `scenes/game/views/MarketsView.tscn`
  - `scenes/game/views/PortfolioView.tscn`
  - `scenes/game/views/HelpView.tscn`
- Widget scenes:
  - `scenes/game/widgets/DeskWidget.tscn`
  - `scenes/game/widgets/OrderWidget.tscn`
  - `scenes/game/widgets/CompanyDetailWidget.tscn`
  - `scenes/game/widgets/BrokerWidget.tscn`
  - `scenes/game/widgets/SummaryWidget.tscn`
  - `scenes/game/widgets/WatchlistWidget.tscn`
  - `scenes/game/widgets/SectorWidget.tscn`
  - `scenes/game/widgets/PortfolioWidget.tscn`
  - `scenes/game/widgets/TradeHistoryWidget.tscn`
- Portfolio view now uses:
  - a full-width top summary strip for `Trading Balance`, `Invested`, `P&L`, and `Total Equity`
  - a left holdings table with ticker, current price, average price, lot balance, invested cost, P&L, and `%`
  - a right history table with action, net amount, qty, price, and date
  - both lower tables keep their headers and rows inside horizontally scrollable containers

## Important Design Decisions
- `company_archetypes.json` is now the static archetype seed file, not the live runtime roster
- `company_archetypes.json` stores cleaner templates with runtime-generation anchors grouped under `anchors`
- `company_words.json` now holds the procedural naming bank used to randomize company names each run
- Runtime company stats are generated per run and saved in `RunState`
- Runtime company definitions are also saved in `RunState`, so generated names/tickers/sectors survive save/load cleanly
- The rest of the game should use:
  - `RunState.get_effective_company_definition(company_id)`
  - `RunState.get_effective_company_definitions()`
  instead of reading only static `DataRepository` company definitions for gameplay logic
- UI dates should use `GameManager.format_trade_date(...)` and `RunState` calendar state, not local date math
- Layout is modular enough for future widget rearranging, but drag/drop user customization is not implemented yet
- The selected-company dashboard panel now includes an in-panel generated history view fed from runtime `financial_history`
- Most static explanatory copy has been removed from the live game layout and moved into the in-game `Help` section for a cleaner shell
- Sidebar chrome is now stripped down:
  - no `WORKSPACE`
  - no `Market Sections`
  - no sidebar `Current focus`
- Navbar branding copy is now stripped down:
  - no `MARKET DESK`
  - no `Modular Play Space`
- The old dashboard `TRADING DESK` label/status area has been removed in favor of a bottom-right order toast with a close button and `5s` auto-hide

## Company Data Model
- Static template still lives in:
  - `data/companies/company_archetypes.json`
- Procedural naming bank lives in:
  - `data/companies/company_words.json`
- Static company templates now mainly carry:
  - seed identity fields like `id`, `ticker`, `name`, `sector_id`
  - `narrative_tags`
  - compact generator inputs under `anchors`
- A real run no longer uses the five static companies directly:
  - `GameManager.build_company_roster(...)` generates the live roster for the selected difficulty
  - each generated company gets its own `id`, `ticker`, `name`, `sector_id`, `listing_board`, `narrative_tags`, and mutated `anchors`
- Runtime generated profile is stored in each company runtime as `company_profile`
- Generated profile currently includes:
  - `base_price`
  - `quality_score`
  - `growth_score`
  - `risk_score`
  - `base_volatility`
  - `financials`
  - `financial_history`
  - `generation_traits`
  - `shares_outstanding`
- `financial_history` currently contains annual rows for `2010-2019`
- `GameManager.get_portfolio_snapshot()` now also exposes:
  - `invested_cost`
  - `unrealized_pnl`
  - `unrealized_pnl_pct`
  - per-holding `invested_cost` and `unrealized_pnl_pct`

## Testing
- Smoke scene:
  - `scenes/tests/SmokeTest.tscn`
  - script: `scripts/tests/SmokeTest.gd`
- Smoke test currently verifies:
  - main menu `New Game` opens the dedicated difficulty selector
  - selector renders four difficulty cards
  - `Continue` stays disabled until a difficulty card is chosen
  - loading screen exposes a progress bar node
  - difficulty-based company counts load (`50` on Normal, `200` on Hardcore)
  - generated company names are `2-3` words
  - generated tickers are unique `4-letter` codes
  - dashboard buy flow shows the new order toast
  - opening trade date is `2020-01-02`
  - trade history is created
  - prices stay on IDX ticks
  - prices stay inside ARA/ARB
  - financial snapshot exists
  - financial history has 10 rows
  - financial history spans `2010-2019`
  - dashboard company history panel is populated from generated runtime history
  - Hardcore path has at least one down day
- Last known passing smoke output:
  - `SMOKE_OK normal_equity=99999985.15 hardcore_equity=965847.0 hardcore_down_days=7 summary=Zombie distribution hit MECH hardest and kept the day defensive.`

## Known Limitations
- Trading calendar currently has 2020 holidays only
- No quarterly financial simulation yet
- No price chart widget yet
- No onboarding beyond a simple tutorial popup
- No player-custom widget layout yet
- Company generator still uses the compact `anchors` values in `company_archetypes.json` as runtime generation inputs
- `200`-name Hardcore rosters are playable, but the Markets screen still has no search/sort/filter tools yet
- Portfolio holdings/history tables are display-focused right now:
  - no sorting
  - no filtering
  - no row actions yet
  - horizontal scrolling solves clipping, but the tables still need a stronger responsive/mobile treatment later

## Recommended Next Steps (Confirm user first)
- Add price chart + recent company timeline
- Extend trading calendar beyond 2020
- Consider quarterly report events driven by generated fundamentals
- Add score-explanation UI:
  - why quality is high/low
  - why growth is high/low
  - why risk is high/low

## Good Re-entry Prompt
Use something like:

`Read PROJECT_HANDOFF.md first, then continue the Daytrader Game from there.`
