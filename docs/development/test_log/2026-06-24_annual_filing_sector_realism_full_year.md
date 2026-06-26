# Annual Filing Sector Realism Full-Year Player Scenario

## Run
- Seed: `20260622`
- Trading days completed: `225/225`
- Final trade date: `{"day":3,"month":12,"weekday":3,"year":2020}`
- Elapsed: `232511.74ms`

## Player Action
- Bought: `BORI` `bank_orang_indonesia` (Bank Orang Indonesia)
- Shares: `500` at `9322.0`, final price `2417.0`, held return `-74.07%`
- Selection reason: fixed catalog bank annual filing scenario target

## Annual Filing Evidence
- Opened bank filing: `true`
- Opened company: `bank_orang_indonesia`
- Filing profile: `bank`
- Visible filing hash: `1227774838`
- Generation timing/cache: `lazy_on_request` / `miss_built`
- Visible sections/tables: `21` / `18`
- Story-note facts/prose: `6` / `5`
- Captures attached: `3`
- Capture types: `statement_row, note_table_row, note_paragraph`

## Thesis
- Thesis id: `thesis_bank_orang_indonesia_001`
- Evidence count: `5`
- Final report success: `true`
- Attached provenance groups: `commodity, sector, filing`

## Portfolio
- Cash: `1890338.5`
- Market value: `1208500.0`
- Equity: `3098838.5`
- Holdings count: `1`

## Market
- Best stock: `DIGN` `diagnostik_sehat` return `770.43%`
- Worst stock: `SKSI` `sistem_karya_siber` return `-96.97%`
- Average return: `-47.88%`; median return: `-75.05%`; advancers/decliners: `4/66`

## Events
- Scheduled/company/corporate/index/special: `19/280/229/55/0`
- Dirty tip offers/results: `0/0`
- Network request/tip results: `0/0`
- Top event IDs: `[{"count":259,"id":"earnings_miss"},{"count":150,"id":"cash_dividend"},{"count":24,"id":"stock_dividend"},{"count":22,"id":"strategic_merger_acquisition"},{"count":21,"id":"earnings_beat"},{"count":16,"id":"mscy_index_watch"},{"count":15,"id":"rights_issue"},{"count":12,"id":"ftsi_index_watch"},{"count":10,"id":"stock_buyback"},{"count":8,"id":"restructuring"},{"count":6,"id":"ftsi_index_exclusion"},{"count":6,"id":"ftsi_index_inclusion"}]`

## Gorengan And Attention
- Gorengan started/dump peak/success peak: `24/7/0`
- Attention tier counts: `{"clue_due":17,"company_watch":94,"digestion":109,"headline_reserved":1,"normal":1,"quiet":3}`
- Attention lane counts: `{"company":111,"digestion":109,"macro":2,"quiet":3}`
- Scenario focus days: `0`

## Raw Summary
```json
{
	"annual_filing": {
		"cache_status": "miss_built",
		"capture_count": 3,
		"capture_types": [
			"statement_row",
			"note_table_row",
			"note_paragraph"
		],
		"generation_timing": "lazy_on_request",
		"opened_bank_filing": true,
		"opened_company_id": "bank_orang_indonesia",
		"profile_id": "bank",
		"story_note_fact_count": 6,
		"story_note_prose_count": 5,
		"visible_filing_hash": "1227774838",
		"visible_section_count": 21,
		"visible_table_count": 18
	},
	"attention_director": {
		"avg_best_company_attention_score": 0.8243,
		"avg_dirty_market_pressure": 0.0,
		"avg_market_stress_score": 0.2319,
		"force_company_arc_days": 17,
		"force_special_days": 1,
		"lane_counts": {
			"company": 111,
			"digestion": 109,
			"macro": 2,
			"quiet": 3
		},
		"scenario_company_focus_days": 0,
		"suppressed_special_days": 177,
		"tier_counts": {
			"clue_due": 17,
			"company_watch": 94,
			"digestion": 109,
			"headline_reserved": 1,
			"normal": 1,
			"quiet": 3
		}
	},
	"days_completed": 225,
	"elapsed_msec": 232511.74,
	"events": {
		"company_events": 280,
		"corporate_action_events": 229,
		"corporate_category_counts": {
			"corporate_action_cancellation": 1,
			"corporate_action_clarification": 8,
			"corporate_action_denial": 2,
			"corporate_action_execution": 122,
			"corporate_action_filing": 8,
			"corporate_action_resolution": 62,
			"corporate_action_rumor": 16,
			"corporate_action_speculation": 8,
			"corporate_meeting": 2
		},
		"dirty_tip_offers": 0,
		"dirty_tip_results": 0,
		"event_family_counts": {
			"company": 290,
			"corporate_action": 229,
			"index_review": 55,
			"market": 3,
			"person": 4,
			"sector": 2
		},
		"index_review_events": 55,
		"network_request_results": 0,
		"network_tip_results": 0,
		"quarterly_report_events": 280,
		"scheduled_events": 19,
		"special_events": 0,
		"top_event_id_counts": [
			{
				"count": 259,
				"id": "earnings_miss"
			},
			{
				"count": 150,
				"id": "cash_dividend"
			},
			{
				"count": 24,
				"id": "stock_dividend"
			},
			{
				"count": 22,
				"id": "strategic_merger_acquisition"
			},
			{
				"count": 21,
				"id": "earnings_beat"
			},
			{
				"count": 16,
				"id": "mscy_index_watch"
			},
			{
				"count": 15,
				"id": "rights_issue"
			},
			{
				"count": 12,
				"id": "ftsi_index_watch"
			},
			{
				"count": 10,
				"id": "stock_buyback"
			},
			{
				"count": 8,
				"id": "restructuring"
			},
			{
				"count": 6,
				"id": "ftsi_index_exclusion"
			},
			{
				"count": 6,
				"id": "ftsi_index_inclusion"
			}
		]
	},
	"final_day_index": 226,
	"final_trade_date": {
		"day": 3,
		"month": 12,
		"weekday": 3,
		"year": 2020
	},
	"game_launch": {
		"scene": "res://scenes/game/GameRoot.tscn",
		"validated_controls": [
			"StockAppButton",
			"NewsAppButton",
			"ThesisAppButton",
			"DesktopAdvanceDayButton"
		]
	},
	"gorengan": {
		"dump_seen_active_count_peak": 7,
		"started": 24,
		"successful_active_count_peak": 0
	},
	"news": {
		"article_count": 32,
		"outlet_counts": {
			"gorengan_daily": 9,
			"harian_investor": 10,
			"ordal_news": 5,
			"waduh_finance": 8
		},
		"top_topic_counts": [
			{
				"count": 24,
				"id": "sector"
			},
			{
				"count": 14,
				"id": "market_wrap"
			},
			{
				"count": 10,
				"id": "company"
			},
			{
				"count": 8,
				"id": "corporate_action"
			},
			{
				"count": 7,
				"id": "earnings"
			},
			{
				"count": 7,
				"id": "filing"
			},
			{
				"count": 7,
				"id": "index_review"
			},
			{
				"count": 7,
				"id": "meeting"
			},
			{
				"count": 7,
				"id": "property_development"
			},
			{
				"count": 6,
				"id": "chatter"
			}
		]
	},
	"player_action": {
		"bought_company_id": "bank_orang_indonesia",
		"buy_cost": 4667991.5,
		"buy_price": 9322.0,
		"final_price": 2417.0,
		"held_return_pct": -74.07,
		"holding_average_price_end": 9335.98,
		"holding_shares_end": 500,
		"name": "Bank Orang Indonesia",
		"selection_reason": "fixed catalog bank annual filing scenario target",
		"selection_score": 81.3,
		"shares_bought": 500,
		"ticker": "BORI"
	},
	"portfolio": {
		"cash": 1890338.5,
		"equity": 3098838.5,
		"holdings_count": 1,
		"market_value": 1208500.0,
		"realized_pnl": 0.0
	},
	"price_exposure": {
		"active_stock_days": 15750,
		"avg_abs_drift_bps": 1.5115,
		"avg_drift_bps": -0.2486
	},
	"requested_trading_days": 225,
	"seed": 20260622,
	"stocks": {
		"advancers": 4,
		"average_return_pct": -47.88,
		"best_stock": {
			"company_id": "diagnostik_sehat",
			"final_price": 136423.0,
			"high_return_pct": 0.0,
			"last_daily_change_pct": 0.2,
			"name": "Diagnostik Sehat",
			"return_pct": 770.43,
			"sector_id": "health",
			"start_price": 15673.0,
			"ticker": "DIGN"
		},
		"bottom_5": [
			{
				"company_id": "armada_kurir_nusantara",
				"final_price": 64.0,
				"high_return_pct": 0.0,
				"last_daily_change_pct": 0.0,
				"name": "Armada Kurir Nusantara",
				"return_pct": -92.51,
				"sector_id": "transport",
				"start_price": 854.0,
				"ticker": "AKRN"
			},
			{
				"company_id": "mall_regency_prima",
				"final_price": 50.0,
				"high_return_pct": 0.0,
				"last_daily_change_pct": 0.0,
				"name": "Mall Regency Prima",
				"return_pct": -93.02,
				"sector_id": "property",
				"start_price": 716.0,
				"ticker": "MREG"
			},
			{
				"company_id": "rare_bumi_mineral",
				"final_price": 52.0,
				"high_return_pct": 0.0,
				"last_daily_change_pct": 0.0,
				"name": "Rare Bumi Mineral",
				"return_pct": -93.82,
				"sector_id": "basicindustry",
				"start_price": 842.0,
				"ticker": "RBUM"
			},
			{
				"company_id": "robotik_pabrik_nusantara",
				"final_price": 180.0,
				"high_return_pct": 0.0,
				"last_daily_change_pct": -1.1,
				"name": "Robotik Pabrik Nusantara",
				"return_pct": -95.4,
				"sector_id": "industrial",
				"start_price": 3913.0,
				"ticker": "RBPN"
			},
			{
				"company_id": "sistem_karya_siber",
				"final_price": 50.0,
				"high_return_pct": 0.0,
				"last_daily_change_pct": 0.0,
				"name": "Sistem Karya Siber",
				"return_pct": -96.97,
				"sector_id": "tech",
				"start_price": 1649.0,
				"ticker": "SKSI"
			}
		],
		"company_count": 70,
		"decliners": 66,
		"flat": 0,
		"median_return_pct": -75.05,
		"top_5": [
			{
				"company_id": "diagnostik_sehat",
				"final_price": 136423.0,
				"high_return_pct": 0.0,
				"last_daily_change_pct": 0.2,
				"name": "Diagnostik Sehat",
				"return_pct": 770.43,
				"sector_id": "health",
				"start_price": 15673.0,
				"ticker": "DIGN"
			},
			{
				"company_id": "kelola_mart_sentosa",
				"final_price": 1640.0,
				"high_return_pct": 0.0,
				"last_daily_change_pct": 0.31,
				"name": "Kelola Mart Sentosa",
				"return_pct": 434.2,
				"sector_id": "consumer",
				"start_price": 307.0,
				"ticker": "KELA"
			},
			{
				"company_id": "bank_mega_samudra",
				"final_price": 1390.0,
				"high_return_pct": 0.0,
				"last_daily_change_pct": 0.0,
				"name": "Bank Mega Samudra",
				"return_pct": 329.01,
				"sector_id": "finance",
				"start_price": 324.0,
				"ticker": "BMSA"
			},
			{
				"company_id": "awan_data_nusantara",
				"final_price": 2231.0,
				"high_return_pct": 0.0,
				"last_daily_change_pct": 0.45,
				"name": "Awan Data Nusantara",
				"return_pct": 257.53,
				"sector_id": "tech",
				"start_price": 624.0,
				"ticker": "AWDN"
			},
			{
				"company_id": "sari_boga_makmur",
				"final_price": 281.0,
				"high_return_pct": 0.0,
				"last_daily_change_pct": -3.44,
				"name": "Sari Boga Makmur",
				"return_pct": -23.01,
				"sector_id": "consumer",
				"start_price": 365.0,
				"ticker": "SARI"
			}
		],
		"worst_stock": {
			"company_id": "sistem_karya_siber",
			"final_price": 50.0,
			"high_return_pct": 0.0,
			"last_daily_change_pct": 0.0,
			"name": "Sistem Karya Siber",
			"return_pct": -96.97,
			"sector_id": "tech",
			"start_price": 1649.0,
			"ticker": "SKSI"
		}
	},
	"success": true,
	"thesis": {
		"attached_groups": [
			"commodity",
			"sector",
			"filing"
		],
		"evidence_count": 5,
		"final_report_message": "Research note generated. Spent 7 AP.",
		"final_report_success": true,
		"thesis_id": "thesis_bank_orang_indonesia_001"
	}
}
```
