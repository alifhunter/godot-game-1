# The Daytrader Game

`The Daytrader Game` is a Godot `4.6.1` prototype about reading a procedurally generated market, trading stocks, and learning from event-driven moves.

The project is currently in a `first playable prototype` state. A new run lands on a desktop-style shell where the player opens:

- `STOCKBOT` for trading and research
- `News` for event-driven intel articles
- `Twooter` for faster social chatter and personality-driven signal

Everything is local, deterministic, and data-driven. Companies, financial history, event flows, news copy, and social posts are generated from seeded systems and editable JSON content pools.

## Current Prototype Highlights

- Desktop-first game flow:
  - `Main Menu -> Difficulty -> Loading -> Desktop`
  - `Load Run -> Loading -> Desktop`
- Four difficulty presets with different roster sizes:
  - `Newbie`: `25` companies
  - `Normal`: `50` companies
  - `Hard`: `75` companies
  - `Hardcore`: `100` companies
- Procedural company generation:
  - unique names and tickers
  - sector assignment and board assignment
  - annual financial history from `2010-2019`
  - deterministic narrative company profiles
- Trading terminal features inside `STOCKBOT`:
  - `Dashboard`
  - `Trade`
  - `Portfolio`
  - `Help`
- Trade workspace features:
  - watchlist, all-stock, and portfolio stock lists
  - chart with `1D / 1W / 1M / 1Y / 5Y / YTD`
  - `Line / Candle` chart modes
  - zoom controls
  - axes, hover readout, and crosshair
  - simplified `Key Stats`, `Financials`, `Analyzer`, and `Profile` tabs
- Event-driven market layer:
  - macro state generation
  - company events
  - person-of-interest events
  - multi-day special market arcs
- Research layer:
  - `News` renders event-driven articles from current market/event state
  - `Twooter` renders a smaller mobile-style feed of short posts from tiered accounts
- Save/load support:
  - runtime-generated companies persist across saves
  - watchlist persists
  - event and market history persist

## Design Direction

The project is intentionally trying to feel more like a world than a flat menu stack:

- the player boots into a desktop
- the trading terminal is an app, not the whole game
- news and social are separate information surfaces
- procedural systems are meant to support both gameplay and learning

The current financial statement layer is intentionally simplified. It is designed to be coherent and useful for learning, not to fully reproduce real-world accounting rules.

## Tech Notes

- Engine: `Godot 4.6.1`
- Language: `GDScript`
- Content model:
  - logic lives in `autoloads/`, `systems/`, and `scripts/`
  - editable content pools live in `data/`
- Deterministic content includes:
  - company generation
  - narrative profiles
  - event timelines
  - news articles
  - social posts

## Run Locally

1. Install `Godot 4.6.1`.
2. Open [`project.godot`](./project.godot).
3. Run the main project scene from the Godot editor.

If you want to inspect the latest implementation status first, read [`PROJECT_HANDOFF.md`](./PROJECT_HANDOFF.md).

## Project Structure

```text
autoloads/   Core runtime state, save/load, data access, game orchestration
systems/     Market, company, event, chart, news, and social generation systems
data/        Editable JSON content for sectors, companies, events, news, social, calendar
scenes/      Main menu, game shell, widgets, and tests
scripts/     UI scripts and smoke-test logic
```

## Important Systems

- [`autoloads/GameManager.gd`](./autoloads/GameManager.gd)
  - high-level game flow, snapshots, trading actions, and app-facing accessors
- [`autoloads/RunState.gd`](./autoloads/RunState.gd)
  - runtime save state, generated companies, history, watchlist, and caches
- [`systems/CompanyGenerator.gd`](./systems/CompanyGenerator.gd)
  - company financials, annual history, derived quarterly statements, and historical chart anchors
- [`systems/CompanyNarrativeGenerator.gd`](./systems/CompanyNarrativeGenerator.gd)
  - archetype, size, tags, and profile description generation
- [`systems/MarketSimulator.gd`](./systems/MarketSimulator.gd)
  - daily market simulation
- [`systems/NewsFeedSystem.gd`](./systems/NewsFeedSystem.gd)
  - event-driven news rendering
- [`systems/TwooterFeedSystem.gd`](./systems/TwooterFeedSystem.gd)
  - event-driven social feed rendering

## Current Limitations

- No intraday simulation yet
- Financial statements are simplified and educational, not filing-accurate
- `News` and `Twooter` still use prototype access levels instead of a real perk system
- `Twooter` currently favors a simple mobile-feed presentation over richer account pages or filtering
- Chart indicators exist in backend, but player-facing indicator controls are still limited

## Next Directions

Likely next steps include:

- deeper perk-driven intel access
- richer `News` and `Twooter` content pools
- more chart polish and indicator UX
- more educational overlays around fundamentals and market behavior
- more content around event interpretation and player progression

