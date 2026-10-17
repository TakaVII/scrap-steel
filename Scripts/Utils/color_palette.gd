# purpose: [v3] Colorblind-safe palette without green, pairing every state with an icon/shape (check, cross, triangle) and text (spec §C10). Renamed class_name to GamePalette to prevent shadowing Godot 4 built-in ColorPalette class.
# depends on: RefCounted
# signals emitted: none
# signals listened to: none

class_name GamePalette
extends RefCounted

# Strict Colorblind Triad (no green)
const POSITIVE: Color = Color(0.169, 0.514, 0.729, 1.0)     # #2b83ba Blue
const NEGATIVE: Color = Color(0.843, 0.098, 0.110, 1.0)     # #d7191c Vermilion
const ACCENT: Color = Color(0.992, 0.682, 0.380, 1.0)       # #fdae61 Amber
const NEUTRAL_TEXT: Color = Color(0.910, 0.902, 0.941, 1.0) # #e8e6f0 Near-white
const BACKGROUND: Color = Color(0.078, 0.067, 0.122, 1.0)   # #14111f Deep Indigo
const NEON_CYAN: Color = Color(0.0, 0.898, 1.0, 1.0)        # #00e5ff Cyan
const NEON_MAGENTA: Color = Color(1.0, 0.165, 0.616, 1.0)   # #ff2a9d Magenta

# Redundant Shape/Icon Cues (spec §C10: every color cue must have shape/icon redundancy)
const ICON_PASS: String = "[✓] "
const ICON_FAIL: String = "[✗] "
const ICON_WARN: String = "[▲] "
const ICON_INFO: String = "[◆] "
const ICON_STAR: String = "[★] "

static func get_color(is_positive: bool) -> Color:
	return POSITIVE if is_positive else NEGATIVE

static func format_status_text(text: String, is_positive: bool) -> String:
	var icon: String = ICON_PASS if is_positive else ICON_FAIL
	return icon + text

static func format_warning_text(text: String) -> String:
	return ICON_WARN + text

static func format_info_text(text: String) -> String:
	return ICON_INFO + text
