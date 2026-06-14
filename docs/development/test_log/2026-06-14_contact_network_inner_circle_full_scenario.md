# 2026-06-14 Contact Network Inner-Circle Full Scenario

## Context

- Tester: Codex
- Branch/worktree: local dirty worktree with Contact Network inner-circle dialog enhancement tasks in progress.
- Scope: deterministic Task 6 full-path coverage from public bridge lead to inner-circle direct-tip proof.

## Command

```bash
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkInnerCircleFullScenarioTest.tscn
```

## Result

Passed.

- Sentinel: `CONTACT_NETWORK_INNER_CIRCLE_FULL_SCENARIO_OK`
- Scenario hash: `205923456`
- Seed: `706134`
- Target ticker: `HEFI`

## Scenario Path

1. Started from a fresh run.
2. Seeded top-tier recognition through existing recognition inputs so the player reached `Market Name`.
3. Discovered bridge contact `pak_budihardjo_energy_dir` / `Budihardjo Sutanto` from a public `policy_post` article lead.
4. Confirmed public lead did not expose inner-circle contact `pak_gunawan_personal_lawyer` / `Gunawan Sutrisno`.
5. Met bridge contact through the public lead.
6. Applied deterministic accelerated bridge track-record fixture:
   - relationship before growth: `14`
   - relationship after growth: `62`
   - method: `accelerated_track_record_seed`
   - track-record outcome: `Useful read`
7. Requested an `inner_circle` referral from the bridge contact.
8. Met the referred inner-circle contact.
9. Set the inner-circle Network relationship to `72`, then opened the generated Network Twooter account.
10. Seeded Twooter state to inner-circle candidate and selected the direct-tip option.
11. Verified referral journal proof, direct-tip journal proof, and Twooter timeline proof.

## Public Bridge Lead

- Bridge source type: `news`
- Saved bridge discovery: one discovery row.
- Returned public row list included the bridge contact twice because the contact matched both author and lead scoring paths; the saved discovery map de-duplicated the runtime state.
- Inner-circle public exposure: `false`

## Dialog Options

Visible options in `network_inner_circle_source` / node `open`:

| Option | Action | Label | Player text |
|---|---|---|---|
| `direct_tip` | `ask_tip` | Direct read | If you had to make this practical, what would you tell me to watch or do? |
| `entry_timing` | `ask_tip` | Entry timing | When should I review the read before deciding whether it still deserves attention? |
| `private_referral` | `ask_source_private` | Private intro | If you introduce me, what should the question be so I do not waste the room? |

Chosen option:

- option id: `direct_tip`
- action id: `ask_tip`
- dialog outcome: `direct_tip`
- player text: `If you had to make this practical, what would you tell me to watch or do?`
- reply text: `Buy HEFI next week and hold for 3 trading days. Confidence: high-trust read. Risk: the paperwork or formal notice slips. Boundary: confirm it against public tape, filings, or the next dated checkpoint`

## Final Relationship Values

- Network relationship: `75`
- Twooter relationship: `75`
- Twooter credibility: `49`
- Twooter importance: `57`
- Twooter stage: `inner_circle_candidate`

## Referral Provenance

- referral type: `inner_circle`
- source type: `referral`
- access label: `Inner-circle contact`
- referred by contact id: `pak_budihardjo_energy_dir`
- referred by contact name: `Budihardjo Sutanto`
- referral day label: `Day 1`
- referral journal title: `Referral | Inner-circle contact | Gunawan Sutrisno`
- referral journal detail: `Budihardjo Sutanto introduced this lead. Day 1. Access: Inner-circle contact. Context: HEFI.`

## Direct-Tip Payload

```json
{
  "ticker": "HEFI",
  "direction": "buy",
  "direction_label": "Buy",
  "entry_timing": "next week",
  "hold_period": "for 3 trading days",
  "confidence_label": "high-trust read",
  "risk_note": "the paperwork or formal notice slips",
  "public_boundary_note": "confirm it against public tape, filings, or the next dated checkpoint",
  "truth_label": "Filing-Backed",
  "source_read_type": "network_profile"
}
```

## Journal And Timeline Proof

- direct-tip journal title: `Twooter | Inner-circle Direct Read | HEFI`
- direct-tip journal detail: `Inner-circle direct read: Buy HEFI, next week, hold for 3 trading days. Confidence: high-trust read. Risk: the paperwork or formal notice slips. Boundary: confirm it against public tape, filings, or the next dated checkpoint.`
- Twooter timeline outcome: `direct_tip`
- Twooter timeline text: `Buy HEFI next week and hold for 3 trading days. Confidence: high-trust read. Risk: the paperwork or formal notice slips. Boundary: confirm it against public tape, filings, or the next dated checkpoint Direct tip: inner-circle read recorded.`

## Notes

- This is the deterministic CI-style full-path scenario. It starts fresh but uses accelerated recognition and bridge track-record fixtures so the private referral path can be covered in seconds.
- Existing longer coverage remains in `NetworkThirtyDayScenarioTest` and the contact-network test logs.
- The direct-tip payload only records/journals the read; it does not alter due-tip market processing, so a 120-day market audit was not required for this task.
- Steam initialization warnings appeared because Steam is not running in this headless test environment.
