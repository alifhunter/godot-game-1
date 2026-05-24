extends CanvasLayer

const FISHBOWL_SHADER := preload("res://assets/shaders/fishbowl_screen.gdshader")
const DEFAULT_ENABLED := true

var overlay_rect: ColorRect = null
var overlay_material: ShaderMaterial = null
var disclaimer_splash_active := false
var overlay_enabled := DEFAULT_ENABLED


func _ready() -> void:
	layer = 4090
	follow_viewport_enabled = false
	_build_overlay()


func _build_overlay() -> void:
	overlay_rect = ColorRect.new()
	overlay_rect.name = "FishbowlScreenOverlay"
	overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_rect.color = Color.TRANSPARENT
	overlay_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay_rect)
	if overlay_enabled:
		_ensure_overlay_material()
	_sync_overlay_visibility()


func set_enabled(enabled: bool) -> void:
	overlay_enabled = enabled
	if overlay_enabled:
		_ensure_overlay_material()
	_sync_overlay_visibility()


func is_enabled() -> bool:
	return overlay_enabled


func set_disclaimer_splash_active(active: bool) -> void:
	disclaimer_splash_active = active
	_sync_overlay_visibility()


func _ensure_overlay_material() -> void:
	if overlay_material == null:
		overlay_material = ShaderMaterial.new()
		overlay_material.shader = FISHBOWL_SHADER
	if overlay_rect != null:
		overlay_rect.color = Color.WHITE
		overlay_rect.material = overlay_material


func _sync_overlay_visibility() -> void:
	if overlay_rect != null:
		overlay_rect.visible = overlay_enabled and not disclaimer_splash_active
