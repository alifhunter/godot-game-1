# 2026-06-13 Contact Network 30-Day Scenario

## Context

- Tester: Codex
- Branch/worktree: local dirty worktree with Contact Network System enhancement tasks in progress.
- Scope: targeted 30-trading-day Contact Network scenario after the Task 7 system split.

## Command

```bash
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkThirtyDayScenarioTest.tscn
```

## Result

Passed.

```text
CONTACT_NETWORK_30_DAY_OK {"company_discoveries":25,"conflict_tips_seeded":2,"contacts_met":2,"days_completed":30,"discoveries_count":25,"final_cash":115616977.45,"final_day_index":31,"final_equity":117958677.45,"final_trade_date":{"day":14,"month":2,"weekday":4,"year":2020},"followups_sent":12,"journal_rows":18,"journal_type_counts":{"followup":5,"property_development_lead":2,"social_reaction":5,"tip":2,"tip_result":4},"met_count":2,"network_request_results":1,"network_tip_reactions":12,"network_tip_results":24,"overdue_pending_requests":0,"overdue_pending_tips":0,"primary_ticker":"METE","relationships":{"avg":75.5,"max":87,"min":64,"values":[87,64]},"request_status_counts":{"completed":1},"requested_days":30,"requests_created":1,"scenario_hash":"2044234134","secondary_ticker":"DADE","seed":706133,"source_checks_sent":1,"tip_outcome_counts":{"Missed badly":3,"Still pending":1,"Useful read":7,"Useful warning":1},"tip_status_counts":{"resolved":11,"unresolved":1},"tips_requested":10}
```

## Coverage

- Seeded a fresh deterministic run.
- Discovered company-linked Network contacts.
- Met two low-recognition contacts through `GameManager.meet_contact`.
- Requested tips through `GameManager.request_contact_tip`.
- Accepted and completed one position request through `GameManager.accept_contact_request`.
- Seeded a deterministic conflict pair to exercise source cross-checks.
- Advanced 30 trading days through `GameManager.simulate_opening_session`.
- Verified due request processing, due tip resolution, Network reactions, follow-ups, source checks, journal rows, relationships, and overdue pending-item cleanup.

## Notes

- Steam initialization warnings appeared because Steam is not running in this headless test environment.
- No Contact Network assertion failures.
- No overdue pending Network tips or requests at the end of the run.
