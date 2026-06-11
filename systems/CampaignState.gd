class_name CampaignState
extends RefCounted

# ─── Core identity ───────────────────────────────────────────────────────────
var version: int = 1
var active: bool = false
var company_id: String = ""
var ticker: String = ""
var tier: String = "common"

# ─── Lifecycle ───────────────────────────────────────────────────────────────
var phase: String = "accumulation"
var wave: String = "1"
var start_day_index: int = 0
var start_price: float = 1.0
var target_return_pct: float = 3.0
var required_hard_catalysts: int = 3

# ─── Catalyst progress ───────────────────────────────────────────────────────
var hard_chain_ids: Array = []
var soft_chain_ids: Array = []
var hard_catalyst_count: int = 0
var soft_catalyst_count: int = 0
var catalyst_progress: float = 0.0
var last_hard_catalyst_day_index: int = -1

# ─── Heat and streaks ────────────────────────────────────────────────────────
var regulatory_heat: float = 0.0
var retail_heat: float = 0.0
var green_limit_streak: int = 0
var dump_limit_streak: int = 0

# ─── Regulatory milestones ───────────────────────────────────────────────────
var uma_issued: bool = false
var uma_day_index: int = -1
var suspension_seen: bool = false
var suspension_day_index: int = -1
var split_pressure: bool = false
var split_required: bool = false
var split_scheduled: bool = false
var split_executed: bool = false

# ─── Returns and gate ────────────────────────────────────────────────────────
var realized_return_pct: float = 0.0
var last_realized_return_pct: float = 0.0
var gate_locked: bool = false
var next_needed_beat: String = "first rumor"

# ─── Distribution tracking ───────────────────────────────────────────────────
var distribution_started_day_index: int = -1

# ─── Price and day tracking ──────────────────────────────────────────────────
var last_daily_change_pct: float = 0.0
var last_limit_lock: String = ""
var last_close_price: float = 0.0
var last_pre_close_day_index: int = -1
var last_pre_close_price: float = 0.0
var last_updated_day_index: int = -1


static func from_dict(d: Dictionary) -> CampaignState:
	var s := CampaignState.new()
	if d.is_empty():
		return s
	s.version = int(d.get("version", 1))
	s.active = bool(d.get("active", false))
	s.company_id = str(d.get("company_id", ""))
	s.ticker = str(d.get("ticker", s.company_id))
	s.tier = _safe_tier(str(d.get("tier", "common")))
	s.phase = str(d.get("phase", "accumulation"))
	s.wave = str(d.get("wave", "1"))
	s.start_day_index = int(d.get("start_day_index", 0))
	s.start_price = max(float(d.get("start_price", 1.0)), 1.0)
	s.target_return_pct = max(float(d.get("target_return_pct", 3.0)), 0.75)
	s.required_hard_catalysts = max(int(d.get("required_hard_catalysts", 3)), 1)
	s.hard_chain_ids = _clean_strings(d.get("hard_chain_ids", []))
	s.soft_chain_ids = _clean_strings(d.get("soft_chain_ids", []))
	s.hard_catalyst_count = s.hard_chain_ids.size()
	s.soft_catalyst_count = s.soft_chain_ids.size()
	s.catalyst_progress = clamp(float(d.get("catalyst_progress", 0.0)), 0.0, 1.0)
	s.last_hard_catalyst_day_index = int(d.get("last_hard_catalyst_day_index", -1))
	s.regulatory_heat = clamp(float(d.get("regulatory_heat", 0.0)), 0.0, 1.0)
	s.retail_heat = clamp(float(d.get("retail_heat", 0.0)), 0.0, 1.0)
	s.green_limit_streak = max(int(d.get("green_limit_streak", 0)), 0)
	s.dump_limit_streak = max(int(d.get("dump_limit_streak", 0)), 0)
	s.uma_issued = bool(d.get("uma_issued", false))
	s.uma_day_index = int(d.get("uma_day_index", -1))
	s.suspension_seen = bool(d.get("suspension_seen", false))
	s.suspension_day_index = int(d.get("suspension_day_index", -1))
	s.split_pressure = bool(d.get("split_pressure", false))
	s.split_required = bool(d.get("split_required", false))
	s.split_scheduled = bool(d.get("split_scheduled", false))
	s.split_executed = bool(d.get("split_executed", false))
	s.realized_return_pct = float(d.get("realized_return_pct", 0.0))
	s.last_realized_return_pct = float(d.get("last_realized_return_pct", s.realized_return_pct))
	s.gate_locked = bool(d.get("gate_locked", false))
	s.next_needed_beat = str(d.get("next_needed_beat", "first rumor"))
	s.distribution_started_day_index = int(d.get("distribution_started_day_index", -1))
	s.last_daily_change_pct = float(d.get("last_daily_change_pct", 0.0))
	s.last_limit_lock = str(d.get("last_limit_lock", ""))
	s.last_close_price = float(d.get("last_close_price", 0.0))
	s.last_pre_close_day_index = int(d.get("last_pre_close_day_index", -1))
	s.last_pre_close_price = float(d.get("last_pre_close_price", 0.0))
	s.last_updated_day_index = int(d.get("last_updated_day_index", -1))
	return s


func to_dict() -> Dictionary:
	return {
		"version": version,
		"active": active,
		"company_id": company_id,
		"ticker": ticker,
		"tier": tier,
		"phase": phase,
		"wave": wave,
		"start_day_index": start_day_index,
		"start_price": start_price,
		"target_return_pct": target_return_pct,
		"required_hard_catalysts": required_hard_catalysts,
		"hard_chain_ids": hard_chain_ids.duplicate(),
		"soft_chain_ids": soft_chain_ids.duplicate(),
		"hard_catalyst_count": hard_catalyst_count,
		"soft_catalyst_count": soft_catalyst_count,
		"catalyst_progress": catalyst_progress,
		"last_hard_catalyst_day_index": last_hard_catalyst_day_index,
		"regulatory_heat": regulatory_heat,
		"retail_heat": retail_heat,
		"green_limit_streak": green_limit_streak,
		"dump_limit_streak": dump_limit_streak,
		"uma_issued": uma_issued,
		"uma_day_index": uma_day_index,
		"suspension_seen": suspension_seen,
		"suspension_day_index": suspension_day_index,
		"split_pressure": split_pressure,
		"split_required": split_required,
		"split_scheduled": split_scheduled,
		"split_executed": split_executed,
		"realized_return_pct": realized_return_pct,
		"last_realized_return_pct": last_realized_return_pct,
		"gate_locked": gate_locked,
		"next_needed_beat": next_needed_beat,
		"distribution_started_day_index": distribution_started_day_index,
		"last_daily_change_pct": last_daily_change_pct,
		"last_limit_lock": last_limit_lock,
		"last_close_price": last_close_price,
		"last_pre_close_day_index": last_pre_close_day_index,
		"last_pre_close_price": last_pre_close_price,
		"last_updated_day_index": last_updated_day_index,
	}


static func _safe_tier(tier: String) -> String:
	if tier in ["common", "rare", "legendary"]:
		return tier
	return "common"


static func _clean_strings(source) -> Array:
	if typeof(source) != TYPE_ARRAY:
		return []
	var result: Array = []
	for item in source:
		var s: String = str(item)
		if not s.is_empty() and not result.has(s):
			result.append(s)
	return result
