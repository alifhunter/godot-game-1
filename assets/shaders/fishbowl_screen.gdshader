shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float curvature : hint_range(0.0, 0.35, 0.005) = 0.01;
uniform float zoom_compensation : hint_range(0.9, 1.2, 0.005) = 1.0;
uniform float vignette_strength : hint_range(0.0, 0.6, 0.01) = 0.22;

void fragment() {
	vec2 centered_uv = (SCREEN_UV - vec2(0.5)) * 2.0;
	float radius_sq = dot(centered_uv, centered_uv);
	float vignette = smoothstep(0.45, 1.45, radius_sq);
	float vignette_alpha = vignette_strength * vignette;

	if (curvature <= 0.0001 && abs(zoom_compensation - 1.0) <= 0.0001) {
		COLOR = vec4(0.0, 0.0, 0.0, vignette_alpha);
	} else {
		vec2 warped = centered_uv * (1.0 + curvature * radius_sq);
		vec2 edge_guard = SCREEN_PIXEL_SIZE * 2.0;
		vec2 sample_uv = clamp(warped / (2.0 * zoom_compensation) + vec2(0.5), edge_guard, vec2(1.0) - edge_guard);
		vec4 screen_color = texture(screen_texture, sample_uv);
		vec3 color = screen_color.rgb * (1.0 - vignette_alpha);
		COLOR = vec4(color, 1.0);
	}
}
