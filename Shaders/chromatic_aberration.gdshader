// purpose: Screen-reading impact pulse for sweet-spot hits and minigame strikes.
// uniforms: aberration_amount (0.005), pulse_strength (0.0)
// compatibility: Uses hint_screen_texture. VERIFY: hint_screen_texture in Godot 4.7.2 Compatibility renderer.

shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float aberration_amount : hint_range(0.0, 0.05, 0.001) = 0.005;
uniform float pulse_strength : hint_range(0.0, 1.0, 0.05) = 0.0;

void fragment() {
	vec2 offset = vec2(aberration_amount * pulse_strength, 0.0);
	float r = texture(screen_texture, SCREEN_UV + offset).r;
	float g = texture(screen_texture, SCREEN_UV).g;
	float b = texture(screen_texture, SCREEN_UV - offset).b;
	COLOR = vec4(r, g, b, 1.0);
}
