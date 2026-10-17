// purpose: Compatibility-safe CRT scanline and vignette overlay shader running on a top CanvasLayer ColorRect.
// uniforms: scanline_count (270.0), scanline_intensity (0.12), vignette_intensity (0.35), vignette_opacity (0.60)
// compatibility: Pure procedural math on UVs. No screen_texture read required, ensuring 100% web and Compatibility compatibility.

shader_type canvas_item;

uniform float scanline_count : hint_range(50.0, 600.0, 1.0) = 270.0;
uniform float scanline_intensity : hint_range(0.0, 1.0, 0.02) = 0.12;
uniform float vignette_intensity : hint_range(0.0, 2.0, 0.05) = 0.35;
uniform float vignette_opacity : hint_range(0.0, 1.0, 0.05) = 0.60;

void fragment() {
	// 1. Procedural scanlines based on target vertical resolution (270p)
	float scan = sin(UV.y * scanline_count * 3.14159265);
	float scan_factor = 1.0 - (scanline_intensity * (0.5 + 0.5 * scan));

	// 2. Procedural corner vignette
	vec2 uv_centered = (UV - 0.5) * 2.0;
	float vig = 1.0 - dot(uv_centered, uv_centered) * (vignette_intensity * 0.5);
	vig = clamp(vig, 0.0, 1.0);

	// 3. Darkening composite
	float alpha = (1.0 - (scan_factor * vig)) * vignette_opacity;
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
