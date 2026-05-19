# Buy High Sell Low Stock Trading Simulator

`Buy High Sell Low Stock Trading Simulator` is a Godot `4.6.1` prototype about reading a procedurally generated market, trading stocks, and learning from event-driven moves.

The project is currently in a `first playable prototype` state. A new run lands on a desktop-style shell where the player opens:

- `STOCKBOT` for trading and research
- `News` for event-driven intel articles
- `Twooter` for faster social chatter and personality-driven signal
- `Network` for contact leads, tips, requests, and referrals
- `Upgrades` for cash-bought progression perks

Everything is local, deterministic, and data-driven. Companies, financial history, event flows, news copy, and social posts are generated from seeded systems and editable JSON content pools.

## Current Prototype Highlights

- Desktop-first game flow:
  - `Main Menu -> Difficulty -> Loading -> Desktop`
  - `Load Run -> Loading -> Desktop`
- Three difficulty presets with different roster sizes, event pace, and volatility:
  - `Chill`: `20` companies, events every `14` days, `Low` volatility
  - `Normal`: `30` companies, events every `10` days, `Normal` volatility
  - `Grind`: `50` companies, events every `7` days, `High` volatility
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
- Progression layer:
  - `Upgrades` spends portfolio cash on lower trading fees, richer News and Twooter access, chart indicators, and daily Network action points
  - `Network` spends daily action points on meeting contacts, asking for tips, accepting requests, and seeking referrals
- Save/load support:
  - runtime-generated companies persist across saves
  - watchlist persists
  - event and market history persist
  - upgrade tiers and Network state persist

## Design Direction

The project is intentionally trying to feel more like a world than a flat menu stack:

- the player boots into a desktop
- the trading terminal is an app, not the whole game
- news and social are separate information surfaces
- procedural systems are meant to support both gameplay and learning

The current financial statement layer is intentionally simplified. It is designed to be coherent and useful for learning, not to fully reproduce real-world accounting rules.

Shared UI styling is documented in [`docs/DESIGN_SYSTEM.md`](./docs/DESIGN_SYSTEM.md). New screens should extend `UiTheme` first, then consume the shared tokens/components from feature scripts.

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

## Content Tools

- [`tools/academy_editor`](./tools/academy_editor/README.md) edits Academy lesson content and exports `data/academy/academy_catalog.json`.
- [`tools/news_editor`](./tools/news_editor/README.md) edits News outlet, author, phrase, body-slot, and voice-profile pools and exports `data/news/news_feed_data.json`.
- [`tools/twooter_editor`](./tools/twooter_editor/README.md) edits Twooter accounts, post templates, thread templates, and fallback pools and exports `data/social/twooter_feed_data.json`.
- [`tools/network_editor`](./tools/network_editor/README.md) edits Network contacts, insider templates, RUPSLB room lead profiles, and tip/request templates and exports `data/network/contact_network_data.json`.
- [`tools/corporate_action_editor`](./tools/corporate_action_editor/README.md) edits corporate-action generator rules, stage templates, family agendas, and RUPSLB meeting copy and exports `data/corporate_actions/corporate_action_catalog.json`.
- [`tools/broker_roster_editor`](./tools/broker_roster_editor/README.md) edits broker codes, broker type buckets, and personality tags and exports `data/brokers/broker_roster.json`.
- [`tools/company_narrative_editor`](./tools/company_narrative_editor/README.md) edits seeded company templates, generated name words, profile archetypes, sector/size copy pools, and narrative tag sentences and exports `data/companies/company_archetypes.json`, `data/companies/company_words.json`, and `data/companies/company_profile_data.json`.
- [`tools/balance_upgrades_editor`](./tools/balance_upgrades_editor/README.md) edits upgrade costs, shop copy, trading fee rates, content unlock levels, chart indicator unlocks, and Network AP limits and exports `data/upgrades/upgrade_catalog.json`.
- [`tools/event_content_editor`](./tools/event_content_editor/README.md) edits market, company, person, corporate-action, and special event definitions and exports `data/events/events.json`.
- [`tools/content_lint_dashboard`](./tools/content_lint_dashboard/README.md) runs all content-editor validators, checks runtime JSON health, and renders generated copy previews without writing runtime data.

For Steam Early Access testing prep:

- [`EULA.txt`](./EULA.txt) is the proprietary game product license for public builds.
- [`THIRD_PARTY_NOTICES.txt`](./THIRD_PARTY_NOTICES.txt) is the bundled third-party notice file to ship beside `BHSL.exe`.
- [`GODOT_COPYRIGHT.txt`](./GODOT_COPYRIGHT.txt) is the Godot Engine third-party copyright file to ship beside `BHSL.exe`.
- [`docs/STEAM_BUILD_UPLOAD_GUIDE.md`](./docs/STEAM_BUILD_UPLOAD_GUIDE.md) is the repeatable Godot export, SteamPipe upload, branch, launch-option, and Cloud verification guide.
- [`docs/STEAM_PLAYTEST_CHECKLIST.md`](./docs/STEAM_PLAYTEST_CHECKLIST.md) is the Steam-launch platform checklist for testers.
- [`docs/RELEASE_LICENSE_AUDIT.md`](./docs/RELEASE_LICENSE_AUDIT.md) tracks third-party notices, owned-asset confirmations, and licensed-content release checks.
- [`docs/KNOWN_ISSUES.md`](./docs/KNOWN_ISSUES.md) tracks current player-facing issues and workarounds.
- [`docs/BUG_REPORT_TEMPLATE.md`](./docs/BUG_REPORT_TEMPLATE.md) is the tester bug-report format.
- [`docs/STEAM_ACHIEVEMENT_IDS.md`](./docs/STEAM_ACHIEVEMENT_IDS.md) lists the future Steam achievement/stat API draft; public Early Access currently ships with Steam achievement/stat writes disabled.
- [`docs/STEAM_CLOUD_SAVE_PATHS.md`](./docs/STEAM_CLOUD_SAVE_PATHS.md) maps the current save files to Steam Auto-Cloud setup.

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
- `Twooter` has account filtering, but richer account pages are still future work
- Chart indicators are a first pass and still need deeper presentation polish

## Next Directions

Likely next steps include:

- richer `News` and `Twooter` content pools
- more chart polish and indicator UX
- more educational overlays around fundamentals and market behavior
- more content around event interpretation and player progression
