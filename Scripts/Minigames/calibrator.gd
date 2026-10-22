# purpose: [v5] The Calibrator, Stardew-fishing style, with game feel. The player's bar has VELOCITY (hold = lift, release = gravity with momentum, soft floor bounce); the target needle wanders erratically and sometimes DARTS (it blinks first as a warning). Difficulty scales hard with the contract tier. Feel: bar trail, sparks while the needle is inside, streak counter, glowing bar, shake on darts and lost streaks, result popup. Score = time the needle is inside the bar / round duration (spec C9). Track units are 0..1 (0 = top).
# depends on: MinigameBase, SpriteKit, Sfx, Juice, GamePalette, NumberFormat
# signals emitted: finished(score: float)
# signals listened to: none

extends MinigameBase

@export_group("Calibrator Mechanics")
@export var round_duration_sec: float = 15.0
## Track units per second squared. Holding lifts, releasing lets gravity pull.
@export var lift_accel: float = 2.6
@export var base_gravity_accel: float = 1.9
## Higher tiers pull harder, so hovering needs finer control.
@export var tier_gravity_mults: Array[float] = [1.0, 1.15, 1.3]
@export var max_speed: float = 1.4
@export var floor_bounce: float = 0.35
## Player bar height as a fraction of the track, by contract tier (bigger = easier).
@export var tier_bar_fractions: Array[float] = [0.30, 0.21, 0.14]
@export var needle_px: float = 12.0
@export_group("Target Motion")
## How quickly the needle chases its goal (per second), by tier.
@export var tier_response: Array[float] = [2.5, 4.0, 6.0]
## Largest jump between goals (track units), by tier.
@export var tier_max_jump: Array[float] = [0.35, 0.55, 0.80]
@export var tier_dart_chance: Array[float] = [0.05, 0.20, 0.40]
## Divides the wait between goals (higher = busier needle).
@export var tier_retarget_speed: Array[float] = [1.0, 1.25, 1.6]
@export var dart_response_mult: float = 3.0
@export var retarget_min_sec: float = 0.5
@export var retarget_max_sec: float = 1.4
@export var dart_warning_sec: float = 0.25
@export var dart_hold_sec: float = 0.35
@export var min_goal_distance: float = 0.12
@export var input_mode_toggle: bool = false
@export_group("Game Feel")
@export var trail_min_speed: float = 0.35
@export var streak_shake_min_sec: float = 1.5

@onready var track_panel: Control = %TrackPanel
@onready var rpm_target_zone: Panel = %RpmTargetZone
@onready var tuning_bar: Panel = %TuningBar
@onready var timer_label: Label = %TimerLabel
@onready var score_progress: ProgressBar = %ScoreProgress
@onready var instruct_label: Label = %InstructLabel
@onready var status_label: Label = %StatusLabel

var _tier: int = 1
var _speed_mult: float = 1.0
var _time_remaining: float = 15.0
var _time_in_zone: float = 0.0
var _track_w: float = 100.0
var _track_h: float = 160.0
var _bar_h: float = 0.25   # normalized
var _bar_y: float = 0.7    # normalized top of the bar
var _bar_v: float = 0.0
var _target_y: float = 0.4 # normalized centre of the needle
var _goal_y: float = 0.4
var _pending_goal: float = 0.4
var _retarget_t: float = 0.5
var _warn_t: float = 0.0
var _darting: bool = false
var _is_pressing_rise: bool = false
var _toggle_rising: bool = false
var _was_in_zone: bool = false
var _streak: float = 0.0
var _last_tenth: int = -1
var _style_idle: StyleBoxFlat
var _style_hot: StyleBoxFlat
var _bar_is_sprite: bool = false
var _trail: CPUParticles2D
var _zone_fx: CPUParticles2D

func setup(diff: Dictionary) -> void:
	super.setup(diff)
	_tier = diff.get("tier", 1)
	_speed_mult = float(diff.get("speed_mult", 1.0))
	input_mode_toggle = diff.get("input_mode_toggle", false)
	_time_remaining = round_duration_sec

func start() -> void:
	await get_tree().process_frame # containers need one frame before sizes are real
	if not is_inside_tree():
		return
	super.start()
	var ti: int = clampi(_tier - 1, 0, 2)
	_track_w = maxf(40.0, track_panel.size.x)
	_track_h = maxf(60.0, track_panel.size.y)
	_bar_h = tier_bar_fractions[ti] * maxf(1.0, float(difficulty.get("window_mult", 1.0)))
	_bar_y = 1.0 - _bar_h
	_bar_v = 0.0
	_target_y = 0.4
	_goal_y = 0.4
	_retarget_t = 0.4
	_warn_t = 0.0
	_darting = false
	_setup_visuals()
	_build_fx()
	_update_visuals()
	instruct_label.text = tr("MINIGAME_CALIBRATOR_INSTRUCT_TOGGLE") if input_mode_toggle else tr("MINIGAME_CALIBRATOR_INSTRUCT_HOLD")

func _setup_visuals() -> void:
	var bar_px: float = _bar_h * _track_h
	tuning_bar.custom_minimum_size = Vector2(_track_w, bar_px)
	tuning_bar.size = Vector2(_track_w, bar_px)
	tuning_bar.position.x = 0.0
	var needle_w: float = _track_w * 0.4
	rpm_target_zone.custom_minimum_size = Vector2(needle_w, needle_px)
	rpm_target_zone.size = Vector2(needle_w, needle_px)
	rpm_target_zone.position.x = (_track_w - needle_w) * 0.5
	# Sprites replace the flat boxes when the PNGs exist (Docs/sprite_spec.md).
	_bar_is_sprite = SpriteKit.swap_panel_nine(tuning_bar, SpriteKit.MG + "calibrator_bar.png", 6)
	if not _bar_is_sprite:
		_style_idle = _flat(Color(GamePalette.POSITIVE, 0.45), GamePalette.NEON_CYAN)
		_style_hot = _flat(Color(GamePalette.POSITIVE, 0.85), Color.WHITE)
		tuning_bar.add_theme_stylebox_override("panel", _style_idle)
	if not SpriteKit.swap_panel(rpm_target_zone, SpriteKit.MG + "calibrator_needle.png"):
		rpm_target_zone.add_theme_stylebox_override("panel", _flat(GamePalette.ACCENT, Color.WHITE))

func _flat(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	return sb

## Particle effects (no art needed): a trail behind the bar and sparks while the needle is inside.
func _build_fx() -> void:
	if _trail != null:
		return
	_trail = CPUParticles2D.new()
	_trail.emitting = false
	_trail.amount = 14
	_trail.lifetime = 0.3
	_trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_trail.emission_rect_extents = Vector2(_track_w * 0.45, 1.0)
	_trail.spread = 15.0
	_trail.initial_velocity_min = 25.0
	_trail.initial_velocity_max = 55.0
	_trail.gravity = Vector2.ZERO
	_trail.scale_amount_min = 1.0
	_trail.scale_amount_max = 2.0
	_trail.color = Color(GamePalette.NEON_CYAN, 0.7)
	tuning_bar.add_child(_trail)

	_zone_fx = CPUParticles2D.new()
	_zone_fx.emitting = false
	_zone_fx.amount = 10
	_zone_fx.lifetime = 0.4
	_zone_fx.spread = 180.0
	_zone_fx.initial_velocity_min = 20.0
	_zone_fx.initial_velocity_max = 55.0
	_zone_fx.gravity = Vector2.ZERO
	_zone_fx.scale_amount_min = 1.0
	_zone_fx.scale_amount_max = 2.5
	_zone_fx.color = GamePalette.ACCENT
	track_panel.add_child(_zone_fx)

func _process(delta: float) -> void:
	if not is_active:
		return
	_time_remaining -= delta
	if _time_remaining <= 0.0:
		_time_remaining = 0.0
		_end_round()
		return
	_step_bar(delta)
	_step_target(delta)

	var margin: float = (needle_px / _track_h) * 0.5
	var in_zone: bool = _target_y >= _bar_y - margin and _target_y <= _bar_y + _bar_h + margin
	if in_zone:
		_time_in_zone += delta
		_streak += delta
	if in_zone != _was_in_zone: # only touch styles/particles when the state changes (no per-frame allocations)
		_on_zone_changed(in_zone)
	_update_visuals()

func _on_zone_changed(in_zone: bool) -> void:
	_was_in_zone = in_zone
	if not _bar_is_sprite:
		tuning_bar.add_theme_stylebox_override("panel", _style_hot if in_zone else _style_idle)
	_zone_fx.emitting = in_zone
	score_progress.modulate = Color.WHITE if in_zone else Color(0.65, 0.65, 0.75, 1.0)
	if in_zone:
		Sfx.play("calibrator_tick")
	else:
		status_label.text = ""
		if _streak >= streak_shake_min_sec:
			Juice.shake(self, 2.0, 0.12)
			Sfx.play("strike_miss")
		_streak = 0.0

func _end_round() -> void:
	_zone_fx.emitting = false
	_trail.emitting = false
	finish_with_delay(_time_in_zone / round_duration_sec)

## Velocity physics: lift while held, gravity otherwise, soft bounce on the floor, hard stop at the ceiling.
func _step_bar(delta: float) -> void:
	var rising: bool = _toggle_rising if input_mode_toggle else _is_pressing_rise
	var gravity: float = base_gravity_accel * tier_gravity_mults[clampi(_tier - 1, 0, 2)]
	var accel: float = -lift_accel if rising else gravity
	_bar_v = clampf(_bar_v + accel * delta, -max_speed, max_speed)
	_bar_y += _bar_v * delta
	var floor_y: float = 1.0 - _bar_h
	if _bar_y >= floor_y:
		_bar_y = floor_y
		_bar_v = -_bar_v * floor_bounce if _bar_v > 0.15 else 0.0
	elif _bar_y <= 0.0:
		_bar_y = 0.0
		_bar_v = 0.0
	# Trail behind the bar, opposite to its movement.
	var moving: bool = absf(_bar_v) > trail_min_speed
	if moving != _trail.emitting:
		_trail.emitting = moving
	if moving:
		_trail.direction = Vector2(0.0, 1.0 if _bar_v < 0.0 else -1.0)
		_trail.position = Vector2(_track_w * 0.5, tuning_bar.size.y if _bar_v < 0.0 else 0.0)

## Erratic target: wanders to random goals with smoothing; sometimes it blinks (warning) and then darts.
func _step_target(delta: float) -> void:
	var ti: int = clampi(_tier - 1, 0, 2)
	if _warn_t > 0.0:
		_warn_t -= delta
		if SettingsManager.reduced_flashing:
			rpm_target_zone.modulate.a = 0.6
		else:
			rpm_target_zone.modulate.a = 0.35 if int(_warn_t * 24.0) % 2 == 0 else 1.0
		if _warn_t <= 0.0:
			rpm_target_zone.modulate.a = 1.0
			_goal_y = _pending_goal
			_darting = true
			_retarget_t = dart_hold_sec
			Juice.shake(self, 1.5, 0.1)
	else:
		_retarget_t -= delta
		if _retarget_t <= 0.0:
			_pick_new_goal()
	var response: float = tier_response[ti] * _speed_mult * (dart_response_mult if _darting else 1.0)
	_target_y = lerpf(_target_y, _goal_y, 1.0 - exp(-response * delta))

func _pick_new_goal() -> void:
	var ti: int = clampi(_tier - 1, 0, 2)
	_darting = false
	var jump: float = tier_max_jump[ti]
	var offset: float = randf_range(-jump, jump)
	if absf(offset) < min_goal_distance:
		offset = min_goal_distance * (1.0 if offset >= 0.0 else -1.0)
	var goal: float = _target_y + offset
	if goal < 0.05 or goal > 0.95: # bounce off the ends instead of sticking to them
		goal = _target_y - offset
	goal = clampf(goal, 0.05, 0.95)
	if randf() < tier_dart_chance[ti]:
		_pending_goal = goal
		_warn_t = dart_warning_sec # telegraph first, then dart
		_retarget_t = 999.0
	else:
		_goal_y = goal
		_retarget_t = randf_range(retarget_min_sec, retarget_max_sec) / (tier_retarget_speed[ti] * maxf(0.1, _speed_mult))

func _update_visuals() -> void:
	tuning_bar.position.y = _bar_y * _track_h
	var needle_y: float = _target_y * _track_h
	rpm_target_zone.position.y = needle_y - needle_px * 0.5
	_zone_fx.position = Vector2(_track_w * 0.5, needle_y)
	var tenth: int = int(_time_remaining * 10.0)
	if tenth != _last_tenth:
		_last_tenth = tenth
		timer_label.text = "%.1fs" % _time_remaining
		timer_label.add_theme_color_override("font_color", GamePalette.NEGATIVE if _time_remaining < 3.0 else GamePalette.NEUTRAL_TEXT)
		if _was_in_zone and _streak >= 0.5:
			status_label.text = NumberFormat.render(tr("MINIGAME_CALIBRATOR_STREAK"), {"s": "%.1f" % _streak})
	score_progress.value = (_time_in_zone / round_duration_sec) * 100.0

## "hold" action = Space / Up + left mouse (Project Settings > Input Map).
func _input(event: InputEvent) -> void:
	if not is_active or not event.is_action("hold") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if input_mode_toggle:
		if event.is_pressed():
			_toggle_rising = not _toggle_rising
	else:
		_is_pressing_rise = event.is_pressed()
