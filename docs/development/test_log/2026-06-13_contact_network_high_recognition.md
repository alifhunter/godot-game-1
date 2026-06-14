# 2026-06-13 Contact Network High-Recognition Scenario

## Context

- Tester: Codex
- Branch/worktree: local dirty worktree with Contact Network System enhancement tasks in progress.
- Scope: targeted high-recognition and inner-circle Contact Network scenario.

## Command

```bash
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkHighRecognitionScenarioTest.tscn
```

## Result

Passed.

```text
CONTACT_NETWORK_HIGH_RECOGNITION_OK {"contact_cap":12,"dialog_chosen_action_id":"ask_source_private","dialog_chosen_option_id":"public_trail","dialog_message_rows":2,"dialog_network_changed":true,"dialog_node_id":"open","dialog_options":[{"action_id":"message_check_in","blocked_reason":"","enabled":true,"label":"Context","node_id":"open","option_id":"news_context_intro","player_text":"I found your handle from a News source lead. I want to ask one clean follow-up, not force a shortcut.","tree_id":"network_source_followup"},{"action_id":"ask_source_private","blocked_reason":"","enabled":true,"label":"Public trail","node_id":"open","option_id":"public_trail","player_text":"Can you point me toward the boring public evidence instead of the exciting version of the story?","tree_id":"network_source_followup"},{"action_id":"connect","blocked_reason":"","enabled":true,"label":"Connect","node_id":"open","option_id":"ask_to_connect","player_text":"I want to keep this as a proper source relationship, not a one-off favor.","tree_id":"network_source_followup"}],"dialog_outcome":"source_check","dialog_player_text":"Can you point me toward the boring public evidence instead of the exciting version of the story?","dialog_relationship_delta":2,"dialog_reply_text":"You have earned a better answer, but not a shortcut. Use the context to sharpen your thesis, not replace it.","dialog_tree_id":"network_source_followup","final_day_index":5,"high_tip_outcome":"Useful read","high_tip_status":"resolved","met_count":10,"network_relationship":78,"public_after_exposed":false,"public_after_rows":["bram_sovereign_fund","dani_activist_investor","galih_bonds_issuance","gilang_structured_fin","harun_govt_affairs","hendrawan_debt_restructure","ibu_irma_insurance_broker","ibu_priyatni_dirjen","indah_ratings_analyst","journalist_raka_pradipta","kurnia_legal_dd","laras_sukuk_desk","nurul_compliance","pak_eri_reit_mgr","pak_gunadi_ib_md","pak_hary_ib_origination","pak_haryadi_bumn_holding","pak_hendra_regulator","pak_kemal_distressed","pak_leman_debt_analyst","pak_margono_controlling_bloc","pak_noer_bkn_official","pak_pandu_conglomerate_dir","pak_seno_family_director","pak_sunaryo_family_trust","pak_supriyadi_valuer","pak_suripto_bumn_dir","pak_tito_sovereign_invst","pak_uwais_regulator_dir","yanto_ib_equity_capital"],"recognition_after":{"contact_cap":12,"contact_score":30.0,"equity_score":40.0,"label":"Market Name","ownership_score":29.94,"score":99.94,"tier_index":4},"recognition_before":{"contact_cap":2,"contact_score":0.0,"equity_score":0.0,"label":"Unknown","ownership_score":0.0,"score":0.0,"tier_index":0},"referral_bridge_contact_id":"pak_budihardjo_energy_dir","referral_connection_score":110,"referral_contact_id":"pak_gunawan_personal_lawyer","referral_privacy_gate":"inner_circle","referral_referred_by_contact_id":"pak_budihardjo_energy_dir","referral_source_type":"referral","referral_success":true,"referral_type":"inner_circle","scenario_hash":"1626147722","seed":706134,"target_contact_id":"pak_gunawan_personal_lawyer","target_contact_name":"Gunawan Sutrisno","target_ticker":"HEFI","twooter_account_id":"network_pak_gunawan_personal_lawyer","twooter_credibility":51,"twooter_importance":57,"twooter_relationship":75,"twooter_stage":"inner_circle_candidate"}
```

## Coverage

- Verified a 95-recognition contact does not discover before the recognition gate is met.
- Seeded a top-tier recognition state through the actual recognition inputs: equity, invested holdings, and met-contact count.
- Verified the same high-recognition contact remains hidden from public News/source discovery after reaching `Market Name`.
- Verified `pak_budihardjo_energy_dir` can privately refer `pak_gunawan_personal_lawyer` with `source_type: "referral"` and `privacy_gate: "inner_circle"`.
- Verified the referred high-recognition contact becomes discoverable and meetable only through the private referral unlock.
- Met the high-recognition contact through `GameManager.meet_contact`.
- Seeded the generated Network Twooter account into an inner-circle relationship state and verified the saved/enhanced account stage is `inner_circle_candidate`.
- Opened the generated Network Twooter message thread, captured the available dialog options, selected the enabled `public_trail` option, and verified a player message, account reply, `source_check` dialog outcome, message rows, and Network bridge change.
- Requested a tip from the high-recognition contact and advanced four trading days until the tip resolved.

## 2026-06-14 Task 3 Rerun Addendum

Task 3 changed the high-recognition dialog route from the legacy `network_source_followup` tree to the stage-specific `network_inner_circle_source` tree.

- Sentinel: `CONTACT_NETWORK_HIGH_RECOGNITION_OK`
- Scenario hash: `704355409`
- Dialog tree: `network_inner_circle_source`
- Chosen option: `direct_tip`
- Chosen action: `ask_tip`
- Dialog outcome: `clean_read`
- Visible options:
  - `direct_tip` / `Direct read`
  - `entry_timing` / `Entry timing`
  - `private_referral` / `Private intro`
- Structured direct-tip payloads are still pending Task 4; this rerun proves the stage-specific route and option set are now active.

## 2026-06-14 Task 4 Rerun Addendum

Task 4 changed the inner-circle `direct_tip` option from a generic `clean_read` reply to a structured direct-tip payload.

- Sentinel: `CONTACT_NETWORK_HIGH_RECOGNITION_OK`
- Scenario hash: `232446936`
- Dialog tree: `network_inner_circle_source`
- Chosen option: `direct_tip`
- Chosen action: `ask_tip`
- Dialog outcome: `direct_tip`
- Direct-tip direction: `buy`
- Direct-tip entry timing: `next week`
- Direct-tip hold period: `for 3 trading days`
- Direct-tip confidence: `high-trust read`
- Direct-tip risk note: `the paperwork or formal notice slips`
- Direct-tip reply:
  - `Buy HEFI next week and hold for 3 trading days. Confidence: high-trust read. Risk: the paperwork or formal notice slips. Boundary: confirm it against public tape, filings, or the next dated checkpoint`

## 2026-06-14 Task 5 Rerun Addendum

Task 5 added player-facing referral/direct-tip provenance to Network snapshots, journal rows, and the existing Network UI.

- Sentinel: `CONTACT_NETWORK_HIGH_RECOGNITION_OK`
- Scenario hash: `232446936`
- Referral access label: `Inner-circle contact`
- Referral source: `Budihardjo Sutanto`
- Referral day label: `Day 1`
- Referral journal title:
  - `Referral | Inner-circle contact | Gunawan Sutrisno`
- Referral journal detail:
  - `Budihardjo Sutanto introduced this lead. Day 1. Access: Inner-circle contact. Context: HEFI.`
- Direct-tip journal title:
  - `Twooter | Inner-circle Direct Read | HEFI`
- Direct-tip journal detail:
  - `Inner-circle direct read: Buy HEFI, next week, hold for 3 trading days. Confidence: high-trust read. Risk: the paperwork or formal notice slips. Boundary: confirm it against public tape, filings, or the next dated checkpoint.`
- Network snapshot audit hash updated from `1423212622` to `805271236` because journal/contact/discovery rows now include provenance and direct-tip audit fields.

## Notes

- This is intentionally not a long natural grind. It is a deterministic late-game fixture, so the coverage runs in seconds while still testing the real recognition gate, private referral unlock, Network meet flow, Network Twooter account synthesis, private dialog routing, and high-contact tip resolution.
- Historical first-run output above shows the pre-Task-3 `network_source_followup` route. Current Task 3 behavior routes the same inner-circle Network account to `network_inner_circle_source`.
- Steam initialization warnings appeared because Steam is not running in this headless test environment.
