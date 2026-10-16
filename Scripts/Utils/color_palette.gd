# purpose: Colorblind-safe palette definition eliminating misleading green shades (spec §C10).
# depends on: RefCounted
# signals emitted: none
# signals listened to: none

class_name ColorPalette
extends RefCounted

const POSITIVE: Color = Color(0.169, 0.514, 0.729, 1.0) # #2b83ba Blue
const NEGATIVE: Color = Color(0.843, 0.098, 0.110, 1.0) # #d7191c Vermilion
const ACCENT: Color = Color(0.992, 0.682, 0.380, 1.0)   # #fdae61 Amber
const NEUTRAL_TEXT: Color = Color(0.910, 0.902, 0.941, 1.0) # #e8e6f0 Near-white
const BACKGROUND: Color = Color(0.078, 0.067, 0.122, 1.0)   # #14111f Deep Indigo
const NEON_CYAN: Color = Color(0.0, 0.898, 1.0, 1.0)        # #00e5ff
const NEON_MAGENTA: Color = Color(1.0, 0.165, 0.616, 1.0)   # #ff2a9d
