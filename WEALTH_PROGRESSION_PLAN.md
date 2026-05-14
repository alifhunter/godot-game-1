# Wealth Progression and Life Systems Plan

## Design Intent
The player should make their real money through markets, not side activities. Life, social, and wealth systems should make money feel useful, create pressure, express status, and open new market-facing opportunities without turning into a better income source than stocks.

This plan was written after discussing lessons from a STONKS-9800 review. The key takeaway is not to copy its gambling loops. Indonesia already has enough gambling harm; this project should avoid gambling, betting, paid random reward loops, and side games that become the main payday.

## Core Rule
Side systems can provide:
- information
- reputation
- stress recovery
- monthly costs
- modest passive income
- better organization
- access to meetings, contacts, or company-control tools

Side systems should not provide:
- gambling or betting
- casino-style minigames
- paid random reward loops
- side activities that out-earn trading on average
- obscure traps for normal player behavior

## Main Takeaways
1. Protect the stock-market fantasy.

   Trading, investing, thesis work, liquidity reading, shareholder action, and company control should remain the most important ways to build wealth.

2. Make trading friction legible.

   Thin float, visible depth, ARA/ARB locks, slow exits, and market impact can be fun if players understand what is happening. If selling takes time, the UI should explain the market structure instead of making the player feel stalled.

3. Give wealth something to become.

   Money should unlock a visible life and legacy path: housing, workspace, staff, family office, philanthropy, property holdings, and eventually holding-company or controlled-company progression.

4. Keep side systems market-adjacent.

   Network, Life, Academy, RUPSLB meetings, and Company control should feed back into market choices, reputation, resilience, and long-run strategy.

5. Make interactive moments clear before they start.

   Any future speech, meeting, negotiation, source interview, or analyst presentation interaction should explain controls, cost, success condition, and consequence category up front.

6. Make progression visible.

   Recognition, stats, upgrades, and social standing should visibly change what people will tell the player, what meetings open, what financing terms are available, and what company actions become credible.

## Proposed Progression Ladder
Early game:
- Build a cash buffer.
- Learn watchlist and thesis basics.
- Make the first small trade.
- Read Daily Recap and market context.
- Meet the first useful contact.

Mid game:
- Upgrade News, Academy, and Network access while growing Twooter relationships and credibility through public chatter and private messages.
- Attend the first RUPS or RUPSLB.
- Use source cross-checks before acting on tips.
- Build a dividend or growth thesis.
- Buy better housing or workspace while managing monthly burn.
- Reach higher recognition tiers.

Late game:
- Accumulate meaningful ownership stakes.
- Survive drawdowns, legal risk, liquidity traps, and cash stress.
- Influence corporate actions through shareholder power.
- Launch a foundation or public legacy project.
- Build a family office or holding company.
- Gain majority control and use the Company app for direction-setting.

## Candidate Systems
### Next Ambition
A lightweight guidance panel that suggests meaningful goals without becoming a rigid quest log.

Example ambitions:
- Build a 3-month cash buffer.
- Write a thesis before buying.
- Add 5 names to the watchlist.
- Attend the first shareholder meeting.
- Meet the first Network contact.
- Acquire 5% of a company.
- Reach Known Trader recognition.
- Control a company through majority ownership.
- Launch a foundation.

Rewards should usually be recognition, unlock hints, small mood/stress benefits, or better access. Avoid raw cash rewards.

### Wealth Path
Add long-term uses for money that express status and create strategic tradeoffs.

Possible branches:
- Housing: stress recovery, monthly burn, status.
- Workspace: research comfort, focus, small tool or UI advantages.
- Staff: modest Life/Network efficiency improvements.
- Family office: portfolio organization, reporting, and late-game identity.
- Foundation: reputation, public recognition, relationship openings.
- Property/business holdings: modest stable income with upkeep and risk.
- Holding company: late-game bridge into controlled-company play.

### Social And Meeting Actions
Keep social play useful, bounded, and transparent.

Twooter should be the player's primary free social and information-gathering surface:
- Public posts are ambient market chatter that can be replied to for relationship, exposure, and credibility growth.
- Public interaction should have diminishing same-day gains so it feels social, not farmable.
- Private actions such as messaging, connecting, asking for sources, requesting tips, or sharing a thesis should spend existing daily AP.
- Useful outcomes should flow into Network as journal entries, discoveries, invitations, requests, or suspicious approaches.
- Strong relationships can eventually open late-game inner-circle introductions, but those chains should be market-facing and risk-aware instead of direct payday loops.

Every action should show:
- AP or time cost
- stress or reputation cost, if any
- locked requirement, if any
- likely benefit category
- whether the action can affect market, relationship, or legal risk

Avoid hidden severe penalties for using a system the game encourages.

## First Implementation Slice
Start with `Next Ambition` and clearer wealth direction because it solves the biggest planning problem without destabilizing balance.

Suggested first pass:
1. Add a Life or desktop-facing ambitions panel.
2. Define 6-10 progression goals from existing state.
3. Tie goals to existing systems only:
   - cash buffer
   - first thesis
   - first Network contact
   - first meeting attendance
   - first housing/lifestyle upgrade
   - first 5% ownership stake
   - first majority-control unlock
4. Give non-cash rewards:
   - recognition
   - stress/mood relief
   - unlock hints
   - journal/achievement-style completion markers
5. Add concise copy that points players toward the next market-facing step.

## Balance Guardrails
- Side income should be modest, slow, and capped relative to trading upside.
- Wealth spending should create identity and tradeoffs, not mandatory chores.
- Monthly costs should be legible before purchase.
- Player mistakes should create recovery paths where possible.
- No gambling, betting, or casino framing.
- Do not add disconnected minigames unless they directly serve market, meeting, or reputation decisions.

## Later Ideas
- Market memorabilia or art collection as optional vanity/achievement content, with little or no investment edge.
- Public philanthropy, scholarships, and foundation actions that raise reputation over time.
- Office upgrades that make the player feel more established without becoming pay-to-win.
- Analyst presentation or shareholder speech interactions with clear controls and simple outcomes.
- Family-office dashboard for late-game holdings, dividends, cash runway, and controlled companies.
