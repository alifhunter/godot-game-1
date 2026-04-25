extends CanvasLayer

const FISHBOWL_SHADER := preload("res://assets/shaders/fishbowl_screen.gdshader")

var overlay_rect: ColorRect = null
var overlay_material: ShaderMaterial = null


func _ready() -> void:
	layer = 4090
	follow_viewport_enabled = true
	_build_overlay()


func _build_overlay() -> void:
	overlay_material = ShaderMaterial.new()
	overlay_material.shader = FISHBOWL_SHADER

	overlay_rect = ColorRect.new()
	overlay_rect.name = "FishbowlScreenOverlay"
	overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_rect.color = Color.WHITE
	overlay_rect.material = overlay_material
	overlay_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay_rect)
