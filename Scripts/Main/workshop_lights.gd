# purpose: Animated additive lights for the garage backdrop (tutorial scene and main menu). The sprite workshop_bg.png has NO baked light; this scene adds glow/cone textures (Assets/Textures/Backgrounds/light_*.png) with Add blending and animates their brightness: lamp flicker, slow pulses, neon buzz, lightning flashes in the window. Reduced flashing = static lights, no animation.
# depends on: Control, SettingsManager, EventBus
# signals emitted: none
# signals listened to: EventBus.settings_changed

extends Control

enum Mode { BREATHE, FLICKER, BUZZ, LIGHTNING }

## Global brightness multiplier for every light.
@export_range(0.0, 2.0, 0.05) var intensity: float = 1.0

## node = unique name in workshop_lights.tscn. alpha = base brightness (modulate alpha, Add blend).
## speed = cycles per second (BREATHE), amp = pulse depth (BREATHE) or flash strength (LIGHTNING), phase = offset so lights do not move in sync.
const LIGHT_DEFS: Array = [
	{"node": "LampLeftGlow", "mode": Mode.FLICKER, "alpha": 0.60, "speed": 0.0, "amp": 0.0, "phase": 0.0},
	{"node": "LampLeftCone", "mode": Mode.FLICKER, "alpha": 0.30, "speed": 0.0, "amp": 0.0, "phase": 0.0},
	{"node": "LampCenterGlow", "mode": Mode.BREATHE, "alpha": 0.35, "speed": 0.30, "amp": 0.06, "phase": 2.1},
	{"node": "LampRightGlow", "mode": Mode.BREATHE, "alpha": 0.60, "speed": 0.45, "amp": 0.14, "phase": 4.0},
	{"node": "LampRightCone", "mode": Mode.BREATHE, "alpha": 0.30, "speed": 0.45, "amp": 0.14, "phase": 4.0},
	{"node": "NeonGlowL", "mode": Mode.BUZZ, "alpha": 0.40, "speed": 0.0, "amp": 0.0, "phase": 0.0},
	{"node": "NeonGlowC", "mode": Mode.BUZZ, "alpha": 0.40, "speed": 0.0, "amp": 0.0, "phase": 0.0},
	{"node": "NeonGlowR", "mode": Mode.BUZZ, "alpha": 0.40, "speed": 0.0, "amp": 0.0, "phase": 0.0},
	{"node": "WindowGlowCyan", "mode": Mode.LIGHTNING, "alpha": 0.25, "speed": 0.0, "amp": 0.45, "phase": 0.0},
	{"node": "WindowGlowPink", "mode": Mode.BREATHE, "alpha": 0.30, "speed": 0.35, "amp": 0.18, "phase": 1.0},
	{"node": "FloorCyan", "mode": Mode.BREATHE, "alpha": 0.30, "speed": 0.45, "amp": 0.14, "phase": 4.0},
	{"node": "FloorPink", "mode": Mode.BREATHE, "alpha": 0.30, "speed": 0.35, "amp": 0.18, "phase": 1.0},
]

const FLICKER_THRESHOLD: float = 0.55
const FLICKER_DIP: float = 0.45
const BUZZ_GATE: float = 0.60
const BUZZ_DIP: float = 0.35
const BUZZ_HZ: float = 45.0
const LIGHTNING_MIN_SEC: float = 6.0
const LIGHTNING_MAX_SEC: float = 12.0
const LIGHTNING_DECAY_PER_SEC: float = 3.5

var _nodes: Array[TextureRect] = []
var _defs: Array[Dictionary] = []
var _tints: Array[Color] = []
var _levels: PackedFloat32Array = PackedFloat32Array()
var _next_event: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0

func _ready() -> void:
	for def: Dictionary in LIGHT_DEFS:
		var node: TextureRect = get_node_or_null("%" + String(def["node"])) as TextureRect
		if node == null:
			push_warning("WorkshopLights: node %s not found in the scene." % def["node"])
			continue
		_nodes.append(node)
		_defs.append(def)
		_tints.append(node.modulate)
		_levels.append(0.0)
		_next_event.append(randf_range(LIGHTNING_MIN_SEC, LIGHTNING_MAX_SEC))
	EventBus.settings_changed.connect(_apply_motion_setting)
	_apply_motion_setting()

func _apply_motion_setting() -> void:
	var animate: bool = not SettingsManager.reduced_flashing
	set_process(animate)
	if not animate:
		for i in range(_nodes.size()):
			_set_alpha(i, float(_defs[i]["alpha"]))

func _set_alpha(i: int, a: float) -> void:
	var t: Color = _tints[i]
	_nodes[i].modulate = Color(t.r, t.g, t.b, clampf(a * intensity, 0.0, 1.0))

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	for i in range(_nodes.size()):
		var def: Dictionary = _defs[i]
		var base: float = float(def["alpha"])
		var phase: float = float(def["phase"])
		var a: float = base
		match int(def["mode"]):
			Mode.BREATHE:
				a = base * (1.0 + float(def["amp"]) * sin(_time * float(def["speed"]) * TAU + phase))
			Mode.FLICKER:
				var n: float = sin(_time * 7.3 + phase) * sin(_time * 4.1 + phase * 1.7)
				if n > FLICKER_THRESHOLD:
					a = base * (1.0 - FLICKER_DIP)
			Mode.BUZZ:
				if sin(_time * 0.9 + phase) > BUZZ_GATE:
					a = base * (1.0 - BUZZ_DIP * (0.5 + 0.5 * sin(_time * BUZZ_HZ)))
			Mode.LIGHTNING:
				if _time >= _next_event[i]:
					_levels[i] = 1.0
					_next_event[i] = _time + randf_range(LIGHTNING_MIN_SEC, LIGHTNING_MAX_SEC)
				_levels[i] = maxf(0.0, _levels[i] - delta * LIGHTNING_DECAY_PER_SEC)
				a = base + float(def["amp"]) * _levels[i]
		_set_alpha(i, a)
