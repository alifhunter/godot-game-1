# 2026-06-13 30-Day Full Smoke

## Date And Tester
- Date: 2026-06-13
- Tester: Codex

## Context
- Workspace: `/Users/user/Documents/gorengangame/godot-game-1`
- Repo state: dirty worktree with existing docs restructure, Twooter interaction work, and Godot MCP files.
- Test type: full headless smoke with local IO.

## Command

```sh
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-local-io
```

## Failures Found
- RUPSLB overlay layout assertion failed because the overlay root could be zero-sized in headless smoke, so the centered vertical meeting card was laid out against an invalid root rect.
- Debug Start RUPSLB control failed for a selected held stock because a delayed portfolio refresh cleared direct All Stock selection while Watchlist remained the active list tab.
- CEO-change execution initially exposed the old CEO through company snapshots even after the completed CEO-change result named the new CEO.

## Fixes Applied
- `RupslbMeetingOverlay.gd`: sync the overlay root to the viewport before build/configure/resize, with a 1280x720 fallback for headless zero-size cases.
- `StockController.gd`: added a one-shot preserve flag so direct All Stock selection survives the next active-list sync without forcing the visible tab away from Watchlist.
- `GameRoot.gd`: refresh selected-stock debug controls after stock selection changes.
- `CorporateActionApplications.gd` and `GameManager.gd`: align management roster snapshots with completed CEO-change results.

## Final Result
- Result: PASS
- Final marker: `SMOKE_OK normal_equity=94543418.11 grind_equity=667906.95 grind_down_days=16`
- Final summary line: `Retail distribution hit CAST hardest and kept the day defensive.`

## Expected Headless Noise
- Steam API warnings appeared because Steam was not running.
- RID/ObjectDB/resource leak warnings appeared at Godot headless exit.

## Follow-Up
- No remaining smoke-test assertion failure from the RUPSLB layout, selected held-stock debug control, Watchlist default tab, or CEO-change roster checks.
