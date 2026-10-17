// purpose: Additive pulsing neon glow for cyber panels, contract cards, and strike indicators.
// uniforms: neon_color (#00e5ff), pulse_speed (2.0), glow_intensity (0.8), border_thickness (0.05)
// compatibility: Compatibility renderer friendly. Uses pure UV distance fields.

shader_type canvas_item;

uniform vec4 neon_color : source_color = vec4(0.0, 0.898, 1.0, 1.0);
uniform float pulse_speed : hint_range(0.1, 10.0, 0.1) = 2.0;
uniform float glow_intensity : hint_range(0.0, 2.0, 0.05) = 0.80;
uniform float border_thickness : hint_range(0.01, 0.20, 0.01) = 0.05;

void fragment() {
	// Distance to nearest edge of the Control rect
	float edge_x = min(UV.x, 1.0 - UV.x);
	float edge_y = min(UV.y, 1.0 - UV.y);
	float edge_dist = min(edge_x, edge_y);

	// Sinusoidal pulsing
	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed);
	float glow = smoothstep(border_thickness, 0.0, edge_dist) * glow_intensity * pulse;

	COLOR = vec4(neon_color.rgb, neon_color.a * glow);
}
