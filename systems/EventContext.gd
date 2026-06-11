class_name EventContext
extends RefCounted

# ─── Event aggregation ───────────────────────────────────────────────────────
var event_tags: Array = []
var active_events: Array = []
var hidden_story_flags: Array = []

# ─── Price formation inputs ──────────────────────────────────────────────────
var event_bias: float = 0.0
var event_volatility_multiplier: float = 1.0
var passive_flow_pressure: float = 0.0
var volume_activity_multiplier: float = 1.0
var depth_liquidity_multiplier: float = 1.0

# ─── Identity ────────────────────────────────────────────────────────────────
var sector_id: String = ""

# ─── Dirty tip overlay ───────────────────────────────────────────────────────
var dirty_tip_pressure: float = 0.0
var dirty_tip_offer_id: String = ""

# ─── Subsystem overlays (opaque dict payloads from other systems) ────────────
var gorengan_campaign: Dictionary = {}
var gorengan_campaign_modifiers: Dictionary = {}
var abnormal_move_context: Dictionary = {}


static func from_dict(d: Dictionary) -> EventContext:
	var c := EventContext.new()
	if d.is_empty():
		return c
	c.event_tags = d.get("event_tags", []).duplicate() if typeof(d.get("event_tags", [])) == TYPE_ARRAY else []
	c.active_events = d.get("active_events", []).duplicate(true) if typeof(d.get("active_events", [])) == TYPE_ARRAY else []
	c.hidden_story_flags = d.get("hidden_story_flags", []).duplicate() if typeof(d.get("hidden_story_flags", [])) == TYPE_ARRAY else []
	c.event_bias = float(d.get("event_bias", 0.0))
	c.event_volatility_multiplier = float(d.get("event_volatility_multiplier", 1.0))
	c.passive_flow_pressure = float(d.get("passive_flow_pressure", 0.0))
	c.volume_activity_multiplier = float(d.get("volume_activity_multiplier", 1.0))
	c.depth_liquidity_multiplier = float(d.get("depth_liquidity_multiplier", 1.0))
	c.sector_id = str(d.get("sector_id", ""))
	c.dirty_tip_pressure = float(d.get("dirty_tip_pressure", 0.0))
	c.dirty_tip_offer_id = str(d.get("dirty_tip_offer_id", ""))
	c.gorengan_campaign = d.get("gorengan_campaign", {}).duplicate(true) if typeof(d.get("gorengan_campaign", {})) == TYPE_DICTIONARY else {}
	c.gorengan_campaign_modifiers = d.get("gorengan_campaign_modifiers", {}).duplicate(true) if typeof(d.get("gorengan_campaign_modifiers", {})) == TYPE_DICTIONARY else {}
	c.abnormal_move_context = d.get("abnormal_move_context", {}).duplicate(true) if typeof(d.get("abnormal_move_context", {})) == TYPE_DICTIONARY else {}
	return c


func to_dict() -> Dictionary:
	var d: Dictionary = {
		"event_tags": event_tags.duplicate(),
		"active_events": active_events.duplicate(true),
		"hidden_story_flags": hidden_story_flags.duplicate(),
		"event_bias": event_bias,
		"event_volatility_multiplier": event_volatility_multiplier,
		"passive_flow_pressure": passive_flow_pressure,
		"volume_activity_multiplier": volume_activity_multiplier,
		"depth_liquidity_multiplier": depth_liquidity_multiplier,
		"sector_id": sector_id,
	}
	# Overlay keys are only present when the corresponding system touched the
	# context, matching the original dict pipeline's sparse shape.
	if not dirty_tip_offer_id.is_empty() or dirty_tip_pressure != 0.0:
		d["dirty_tip_pressure"] = dirty_tip_pressure
		d["dirty_tip_offer_id"] = dirty_tip_offer_id
	if not gorengan_campaign.is_empty():
		d["gorengan_campaign"] = gorengan_campaign.duplicate(true)
	if not gorengan_campaign_modifiers.is_empty():
		d["gorengan_campaign_modifiers"] = gorengan_campaign_modifiers.duplicate(true)
	if not abnormal_move_context.is_empty():
		d["abnormal_move_context"] = abnormal_move_context.duplicate(true)
	return d


func add_hidden_flag(flag: String) -> void:
	if not flag.is_empty() and not hidden_story_flags.has(flag):
		hidden_story_flags.append(flag)


func add_event_tag(tag: String) -> void:
	if not tag.is_empty() and not event_tags.has(tag):
		event_tags.append(tag)
