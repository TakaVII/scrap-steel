# purpose: [v4] The Forge. Skill shrinks the window: every successful strike narrows the sweet spot (a miss widens it back, never past its start width), a flat "perfect core" scores 1.0, and outside it the score falls off linearly. Juice: sparks (CPUParticles2D, no art needed), root shake, hit-stop on the cursor, optional hammer sprite (Assets/Textures/Minigames/forge_hammer.png, 4 frames of 32x32).
# depends on: MinigameBase, SpriteKit, Sfx, Juice, GamePalette
# signals emitted: finished(score: float)
# signals listened to: none

extends MinigameBase

@export_group("Forge Mechanics")
@export var total_strikes: int = 5
@export var base_cursor_speed: float = 320.0
@export var speed_increase_per_strike: float = 1.08
@export var tier_speed_mults: Array[float] = [1.0, 1.25, 1.5]
## Sweet-spot width as a fraction of the bar at the first strike (it shrinks from here).
@export var tier_start_width_fractions: Array[float] = [0.24, 0.19, 0.15]
@export var min_width_fraction: float = 0.06
@export var shrink_on_success: float = 0.85
@export var widen_on_fail: float = 1.12
@export var success_threshold: float = 0.60
@export var fail_threshold: float = 0.25
## Centre of the sweet spot that scores exactly 1.0 (fraction of the half-width).
@export var perfect_core_fraction: float = 0.20
## The score reaches 0 at this many half-widths from the centre.
@export var falloff_tolerance_factor: float = 1.2
@export var center_min: float = 0.20
@export var center_max: float = 0.80
@export var hit_stop_duration_sec: float = 0.06
@export var sweet_resize_sec: float = 0.18

@onready var strike_bar_panel: Control = %StrikeBarPanel
@onready var sweet_spot_panel: Panel = %SweetSpotPanel
@onready var cursor_panel: Panel = %CursorPanel
@onready var pips_container: HBoxContainer = %PipsContainer
@onready var strike_count_label: Label = %StrikeCountLabel
@onready var feedback_label: Label = %FeedbackLabel

var _tier: int = 1
var _current_strike_idx: int = 0
var _strike_scores: Array[float] = []
var _cursor_pos_x: float = 0.0
var _cursor_speed: float = 320.0
var _cursor_dir: float = 1.0
var _bar_width: float = 340.0
var _sweet_center_x: float = 170.0
var _sweet_half_width: float = 30.0
var _start_width_frac: float = 0.24
var _width_frac: float = 0.24
var _vis_center: float = 170.0
var _vis_half: float = 30.0
var _hit_stop_timer: float = 0.0
var _sweet_tween: Tween
var _core_rect: ColorRect
var _sparks: CPUParticles2D
var _hammer: AnimatedSprite2D
var _juice_built: bool = false

func setup(diff: Dictionary) -> void:
	super.setup(diff)
	_tier = diff.get("tier", 1)
	var tier_idx: int = clampi(_tier - 1, 0, 2)
	_cursor_speed = base_cursor_speed * tier_speed_mults[tier_idx] * float(diff.get("speed_mult", 1.0))

func start() -> void:
	await get_tree().process_frame # containers need one frame before sizes are real
	if not is_inside_tree():
		return
	super.start()
	_current_strike_idx = 0
	_strike_scores.clear()
	_bar_width = maxf(100.0, strike_bar_panel.size.x)
	var window_mult: float = float(difficulty.get("window_mult", 1.0))
	_start_width_frac = tier_start_width_fractions[clampi(_tier - 1, 0, 2)] * maxf(1.0, window_mult)
	_width_frac = _start_width_frac
	_sweet_half_width = _bar_width * _width_frac * 0.5
	_sweet_center_x = _bar_width * 0.5
	_build_juice_nodes()
	_apply_visual(_sweet_center_x, _sweet_half_width)
	_cursor_pos_x = 0.0
	_cursor_dir = 1.0
	_update_strike_ui()

func _build_juice_nodes() -> void:
	if _juice_built:
		return
	_juice_built = true
	sweet_spot_panel.modulate = Color(GamePalette.NEON_CYAN, 0.55)
	cursor_panel.modulate = GamePalette.ACCENT
	_core_rect = ColorRect.new()
	_core_rect.color = Color(1, 1, 1, 0.55)
	_core_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sweet_spot_panel.add_child(_core_rect)

	_sparks = CPUParticles2D.new()
	_sparks.emitting = false
	_sparks.one_shot = true
	_sparks.amount = 10
	_sparks.lifetime = 0.35
	_sparks.explosiveness = 1.0
	_sparks.direction = Vector2(0, -1)
	_sparks.spread = 70.0
	_sparks.initial_velocity_min = 40.0
	_sparks.initial_velocity_max = 95.0
	_sparks.gravity = Vector2(0, 170)
	_sparks.scale_amount_min = 2.0
	_sparks.scale_amount_max = 3.0
	_sparks.color = GamePalette.ACCENT
	strike_bar_panel.add_child(_sparks)

	_hammer = SpriteKit.animated(SpriteKit.MG + "forge_hammer.png", 32, 32, {"idle": [0], "strike": [1, 2, 3, 0]}, 18.0)
	if _hammer != null:
		strike_bar_panel.add_child(_hammer)
		_hammer.play(&"idle")

## Moves the sweet-spot panel and its perfect-core marker. Logic uses _sweet_center_x/_sweet_half_width; this is only the picture.
func _apply_visual(center: float, half: float) -> void:
	_vis_center = center
	_vis_half = half
	var w: float = half * 2.0
	sweet_spot_panel.custom_minimum_size.x = w
	sweet_spot_panel.size.x = w
	sweet_spot_panel.position.x = center - half
	var core_w: float = w * perfect_core_fraction
	_core_rect.size = Vector2(core_w, sweet_spot_panel.size.y)
	_core_rect.position = Vector2((w - core_w) * 0.5, 0.0)

func _process(delta: float) -> void:
	if not is_active:
		return
	if _hit_stop_timer > 0.0:
		_hit_stop_timer -= delta
		return
	var max_x: float = _bar_width - cursor_panel.size.x
	_cursor_pos_x += _cursor_speed * _cursor_dir * delta
	if _cursor_pos_x >= max_x:
		_cursor_pos_x = max_x
		_cursor_dir = -1.0
	elif _cursor_pos_x <= 0.0:
		_cursor_pos_x = 0.0
		_cursor_dir = 1.0
	cursor_panel.position.x = _cursor_pos_x
	if _hammer != null:
		_hammer.position = Vector2(_cursor_pos_x + cursor_panel.size.x * 0.5, -16.0)

## "strike" action = Space + left mouse (Project Settings > Input Map). _input sees clicks even when Controls would swallow them.
func _input(event: InputEvent) -> void:
	if not is_active or _hit_stop_timer > 0.0:
		return
	if event.is_action_pressed("strike"):
		get_viewport().set_input_as_handled()
		_trigger_strike()

func _score_strike(cursor_center: float) -> float:
	var dist: float = absf(cursor_center - _sweet_center_x)
	var core: float = _sweet_half_width * perfect_core_fraction
	if dist <= core:
		return 1.0
	var outer: float = _sweet_half_width * falloff_tolerance_factor
	return clampf(1.0 - (dist - core) / maxf(0.001, outer - core), 0.0, 1.0)

func _trigger_strike() -> void:
	var cursor_center: float = _cursor_pos_x + cursor_panel.size.x * 0.5
	var s: float = _score_strike(cursor_center)
	_strike_scores.append(s)
	_hit_stop_timer = hit_stop_duration_sec
	_play_hit_juice(cursor_center, s)

	var rating_text: String
	var rating_color: Color
	if s >= 0.90:
		rating_text = tr("MINIGAME_FORGE_STRIKE_PERFECT")
		rating_color = GamePalette.POSITIVE
	elif s >= 0.50:
		rating_text = tr("MINIGAME_FORGE_STRIKE_GOOD")
		rating_color = GamePalette.ACCENT
	else:
		rating_text = tr("MINIGAME_FORGE_STRIKE_MISS")
		rating_color = GamePalette.NEGATIVE
	rating_text += " (%d%%)" % roundi(s * 100.0)
	feedback_label.text = rating_text
	feedback_label.add_theme_color_override("font_color", rating_color)

	_current_strike_idx += 1
	_cursor_speed *= speed_increase_per_strike
	_adapt_window(s)
	_update_strike_ui()

	if _current_strike_idx >= total_strikes:
		var sum: float = 0.0
		for val in _strike_scores:
			sum += val
		_finish(sum / float(total_strikes))

## Skill shrinks the window: success narrows it, a clear miss widens it back (never past the start width).
func _adapt_window(s: float) -> void:
	if s >= success_threshold:
		_width_frac = maxf(min_width_fraction, _width_frac * shrink_on_success)
	elif s <= fail_threshold:
		_width_frac = minf(_start_width_frac, _width_frac * widen_on_fail)
	var new_half: float = _bar_width * _width_frac * 0.5
	var new_center: float = clampf(_bar_width * randf_range(center_min, center_max), new_half, _bar_width - new_half)
	_sweet_center_x = new_center
	_sweet_half_width = new_half
	if _sweet_tween and _sweet_tween.is_valid():
		_sweet_tween.kill()
	var from_c: float = _vis_center
	var from_h: float = _vis_half
	_sweet_tween = create_tween()
	_sweet_tween.tween_method(func(t: float) -> void:
		_apply_visual(lerpf(from_c, new_center, t), lerpf(from_h, new_half, t))
	, 0.0, 1.0, sweet_resize_sec)

func _play_hit_juice(cursor_center: float, s: float) -> void:
	Sfx.play("strike_hit" if s >= 0.5 else "strike_miss")
	Juice.shake(self, 3.0 * s, 0.12)
	if _hammer != null:
		_hammer.play(&"strike")
	_sparks.position = Vector2(cursor_center, strike_bar_panel.size.y * 0.5)
	_sparks.amount = 4 + roundi(14.0 * s)
	_sparks.color = GamePalette.NEON_CYAN if s >= 0.9 else GamePalette.ACCENT
	_sparks.restart()

func _update_strike_ui() -> void:
	strike_count_label.text = NumberFormat.render(tr("MINIGAME_FORGE_STRIKE_COUNT"), {"n": mini(_current_strike_idx + 1, total_strikes), "total": total_strikes})
	var pips: Array[Node] = pips_container.get_children()
	for i in range(pips.size()):
		if pips[i] is ColorRect:
			if i < _strike_scores.size():
				pips[i].color = GamePalette.POSITIVE if _strike_scores[i] >= 0.5 else GamePalette.NEGATIVE
			else:
				pips[i].color = Color(0.3, 0.3, 0.35, 1.0)
