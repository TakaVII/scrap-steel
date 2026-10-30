# purpose: Live "workpiece" shown in the corner of a minigame panel: the icon of the part being made, a glow ring and sparks that REACT to how well you are doing. Forge: heat and sparks on every strike, bigger and brighter for a better strike. Calibrator: steady glow and sparks while the needle is inside the bar, vibration when it is far away. Assembler: lights up as the wire grows, red burst on a short circuit. It reads the minigame's state by name (get()), so the minigame scripts do not need to change; unknown or renamed variables are simply ignored.
# depends on: Control, MinigameBase, ItemPartData, SpriteKit, GamePalette, Juice, SettingsManager, MaterialGrade
# signals emitted: none
# signals listened to: none

class_name PartStage
extends Control

const PARTS: String = "res://Assets/Textures/Parts/"
const FX: String = "res://Assets/Textures/Minigames/"
const STAGE_PX: float = 48.0
const ICON_PX: float = 32.0
const CORNER_MARGIN: float = 8.0
const ENERGY_RATE: float = 3.0
const SHAKE_MAX_PX: float = 2.5

var _game: MinigameBase
var _kind: int = ItemPartData.MinigameType.FORGE
var _holder: Control
var _icon: TextureRect
var _ring: TextureRect
var _sparks: CPUParticles2D
var _energy: float = 0.0
var _target: float = 0.1
var _strikes_seen: int = 0
var _hazards_seen: int = 0
var _red_timer: float = 0.0
var _time: float = 0.0
var _premium: bool = false

func attach(game: MinigameBase, part: ItemPartData, grade: int) -> void:
	_game = game
	_kind = part.minigame_type
	_premium = grade == MaterialGrade.Grade.PREMIUM
	custom_minimum_size = Vector2(STAGE_PX, STAGE_PX)
	size = Vector2(STAGE_PX, STAGE_PX)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder = Control.new()
	_holder.position = Vector2(STAGE_PX - ICON_PX, STAGE_PX - ICON_PX) * 0.5
	_holder.size = Vector2(ICON_PX, ICON_PX)
	_holder.pivot_offset = Vector2(ICON_PX, ICON_PX) * 0.5
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_holder)
	var ring_tex: Texture2D = SpriteKit.tex(FX + "fx_glow_ring.png")
	if ring_tex != null:
		_ring = TextureRect.new()
		_ring.texture = ring_tex
		_ring.size = Vector2(ICON_PX, ICON_PX)
		_ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_ring.stretch_mode = TextureRect.STRETCH_SCALE
		_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_ring.material = mat
		_ring.modulate = Color(GamePalette.NEON_MAGENTA if _premium else GamePalette.NEON_CYAN, 0.0)
		_holder.add_child(_ring)
	var icon_tex: Texture2D = SpriteKit.tex(PARTS + "part_%s.png" % String(part.part_id))
	if icon_tex != null:
		_icon = TextureRect.new()
		_icon.texture = icon_tex
		_icon.size = Vector2(ICON_PX, ICON_PX)
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_SCALE
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_holder.add_child(_icon)
	else:
		var fb := ColorRect.new()
		fb.color = Color(0.3, 0.3, 0.4, 1.0)
		fb.size = Vector2(ICON_PX, ICON_PX)
		_holder.add_child(fb)
	_sparks = CPUParticles2D.new()
	_sparks.emitting = false
	_sparks.amount = 12
	_sparks.lifetime = 0.45
	_sparks.direction = Vector2(0, -1)
	_sparks.spread = 120.0
	_sparks.initial_velocity_min = 25.0
	_sparks.initial_velocity_max = 70.0
	_sparks.gravity = Vector2(0, 110)
	_sparks.scale_amount_min = 1.5
	_sparks.scale_amount_max = 2.5
	_sparks.color = GamePalette.ACCENT
	_sparks.position = Vector2(STAGE_PX, STAGE_PX) * 0.5
	add_child(_sparks)

func _process(delta: float) -> void:
	if not is_instance_valid(_game):
		queue_free()
		return
	_time += delta
	_place()
	match _kind:
		ItemPartData.MinigameType.FORGE:
			_read_forge()
		ItemPartData.MinigameType.CALIBRATE:
			_read_calibrator()
		_:
			_read_assembler()
	_energy = move_toward(_energy, _target, ENERGY_RATE * delta)
	if _red_timer > 0.0:
		_red_timer -= delta
	_apply_visuals()

## Bottom-right corner of the minigame panel (falls back to the screen corner).
func _place() -> void:
	var panel: Control = _game.get_node_or_null("CenterContainer/MainPanel") as Control
	if panel != null:
		global_position = panel.get_global_rect().end - Vector2(STAGE_PX + CORNER_MARGIN, STAGE_PX + CORNER_MARGIN)
	else:
		global_position = get_viewport_rect().size - Vector2(STAGE_PX + CORNER_MARGIN, STAGE_PX + CORNER_MARGIN)

func _apply_visuals() -> void:
	var calm: bool = SettingsManager.reduced_flashing
	var pulse: float = 1.0 if calm else 0.8 + 0.2 * sin(_time * 6.0)
	if _ring != null:
		var base: Color = GamePalette.NEGATIVE if _red_timer > 0.0 else (GamePalette.NEON_MAGENTA if _premium else GamePalette.NEON_CYAN)
		_ring.modulate = Color(base, clampf(_energy * pulse, 0.0, 1.0))
	if _icon != null:
		var heat: Color = Color(0.62, 0.62, 0.74, 1.0).lerp(Color(1.0, 0.85, 0.6, 1.0), _energy)
		if _red_timer > 0.0:
			heat = Color(1.0, 0.45, 0.45, 1.0)
		_icon.modulate = heat

# ---------------------------------------------------------------- reading the minigames

func _read_forge() -> void:
	var scores: Variant = _game.get("_strike_scores")
	if not (scores is Array):
		return
	var arr: Array = scores
	var total: float = 0.0
	for v in arr:
		total += float(v)
	if not arr.is_empty():
		_target = clampf(total / float(arr.size()), 0.15, 1.0) # the part gets hotter the better you hit
	if arr.size() > _strikes_seen:
		_strikes_seen = arr.size()
		_on_strike(float(arr[arr.size() - 1]))

func _on_strike(s: float) -> void:
	_energy = minf(1.0, _energy + 0.5 * s)
	_sparks.amount = 4 + roundi(14.0 * s)
	_sparks.color = GamePalette.NEON_CYAN if s >= 0.9 else GamePalette.ACCENT
	_sparks.restart()
	_sparks.emitting = true
	Juice.shake(_holder, 3.0 * s, 0.12)

func _read_calibrator() -> void:
	var inside: Variant = _game.get("_was_in_zone")
	var needle: Variant = _game.get("_target_y")
	var bar_top: Variant = _game.get("_bar_y")
	var bar_h: Variant = _game.get("_bar_h")
	var is_in: bool = inside is bool and inside
	_target = 1.0 if is_in else 0.15
	if _sparks.emitting != is_in:
		_sparks.emitting = is_in
	# Vibrates when the bar is far from the needle: the engine is out of tune.
	if not is_in and needle is float and bar_top is float and bar_h is float and not SettingsManager.reduced_flashing:
		var distance: float = absf(float(needle) - (float(bar_top) + float(bar_h) * 0.5))
		var amp: float = clampf(distance * 5.0, 0.0, SHAKE_MAX_PX)
		_holder.position = Vector2(STAGE_PX - ICON_PX, STAGE_PX - ICON_PX) * 0.5 + Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
	else:
		_holder.position = Vector2(STAGE_PX - ICON_PX, STAGE_PX - ICON_PX) * 0.5

func _read_assembler() -> void:
	var path: Variant = _game.get("_player_path")
	var budget: Variant = _game.get("_wire_budget")
	var hazards: Variant = _game.get("_hazards_hit")
	if path is Array and budget is int:
		var used: int = maxi(0, (path as Array).size() - 1)
		_target = clampf(float(used) / float(maxi(1, int(budget))) * 1.2, 0.1, 1.0)
	if hazards is int and int(hazards) > _hazards_seen:
		_hazards_seen = int(hazards)
		_red_timer = 0.4
		_sparks.color = GamePalette.NEGATIVE
		_sparks.amount = 14
		_sparks.restart()
		_sparks.emitting = true
		Juice.shake(_holder, 3.0, 0.15)
