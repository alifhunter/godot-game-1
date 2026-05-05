# Known Issues

Build: `0.1.0-ea` / `2026.05.03.1`

Use this list for Steam Early Access tester notes. Keep entries short, player-facing, and tied to a workaround when one exists.

| ID | Area | Issue | Status / Workaround |
|---|---|---|---|
| KI-001 | Performance | Advancing a day can briefly hitch, especially with `Grind` rosters or several apps open. | Known. Close heavy apps like News/Network before long fast-forward sessions if it feels chunky. |
| KI-002 | Startup/detail loading | Some company detail panels can briefly show loading placeholders after a fresh run opens. | Known. Wait a moment or reopen the stock detail after background generation finishes. |
| KI-003 | Display/accessibility | The global fishbowl screen effect has no in-game toggle yet. | Known. Tune shader defaults in development builds if needed. |
| KI-004 | Resolution/layout | The UI is tuned for a desktop 16:9 layout. Very small windows or unusual aspect ratios may crowd dense trading screens. | Known. Use a larger window or fullscreen when testing. |
| KI-005 | Market depth | Synthetic market depth, ARB/ARA locks, and large-order impact are still being tuned. | Known. Report any impossible price moves, stuck order states, or confusing depth reads. |
| KI-006 | Charts | Pattern history is intentionally imperfect and noisy; some setups fail or only partially confirm. | By design, but report charts that look broken, impossible, blank, or unreadably extreme. |
| KI-007 | Fundamentals | Financial statements and key stats are simplified for learning and gameplay. | Known limitation. Do not treat generated numbers as real-world accounting guidance. |
| KI-008 | Intraday trading | There are no hourly/minute candles or intraday sessions yet. | Deferred. Current simulation is daily-candle based. |
| KI-009 | Save compatibility | Early Access saves may need compatibility handling if the schema changes heavily between builds. | Keep the build number with any bug report that involves saves. |
| KI-010 | Headless logs | Windows test runs can end with `Failed to read the root certificate store` after successful smoke output. | Non-blocking Godot/Windows warning in local headless verification. |

## Reporting Priority

Please prioritize reports for:

- crashes, freezes, or soft-locks
- unreadable text or controls that cannot be clicked
- impossible market prices, ARB/ARA violations, or invalid order behavior
- save/load loss or corrupted saves
- broken first-hour tutorial guidance
- blank News, Twooter, Network, or chart views
