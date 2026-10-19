# purpose: [v4] The Calibrator, Stardew-fishing style. The player's bar has VELOCITY: holding lifts it, releasing lets gravity pull it back with momentum, and it bounces softly on the floor. The target needle wanders erratically (random goals, smoothed, with occasional darts). Score = time the needle is inside the bar / round duration (spec C9). Positions are in track units 0..1 (0 = top) so it is layout-independent and frame-rate independent.
# depends on: MinigameBase, SpriteKit, Sfx, GamePalette
# signals emitted: finished(score: float)
# signals listened to: none

extends MinigameBase

@export_group("Calibrator Mechanics")
@export var round_duration_sec: float = 15.0
## Track units per second squared. Holding lifts, releasing lets gravity pull. Hover needs ~42% hold.
@export var lift_accel: float = 2.6
@export var gravity_accel: float = 1.9
@export var max_speed: float = 1.4
@export var floor_bounce: float = 0.35
## Player bar height as a fraction of the track (spec C9 zone heights).
@export var tier_bar_fractions: Array[float] = [0.28, 0.22, 0.18]
@export var needle_px: float = 12.0
@export_group("Target Motion")
## How quickly the needle chases its goal (per second). Higher = snappier.
@export var tier_response: Array[float] = [3.0, 4.0, 5.0]
## Largest jump between goals, in track units.
@export var tier_max_jump: Array[float] = [0.45, 0.60, 0.80]
@export var tier_dart_chance: Array[float] = [0.10, 0.20, 0.30]
@export var dart_response_mult: float = 3.0
@export var retarget_min_sec: float = 0.5
@export var retarget_max_sec: float = 1.4
@export var dart_retarget_sec: float = 0.35
@export var min_goal_distance: float = 0.12
@export var input_mode_toggle: bool = false

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
var _retarget_t: float = 0.5
var _darting: bool = false
var _is_pressing_rise: bool = false
var _toggle_rising: bool = false
var _was_in_zone: bool = false
var _last_tenth: int = -1
var _style_idle: StyleBoxFlat
var _style_hot: StyleBoxFlat
var _bar_is_sprite: bool = false

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
	_darting = false
	_setup_visuals()
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

func _process(delta: float) -> void:
	if not is_active:
		return
	_time_remaining -= delta
	if _time_remaining <= 0.0:
		_time_remaining = 0.0
		_finish(_time_in_zone / round_duration_sec)
		return
	_step_bar(delta)
	_step_target(delta)

	var margin: float = (needle_px / _track_h) * 0.5
	var in_zone: bool = _target_y >= _bar_y - margin and _target_y <= _bar_y + _bar_h + margin
	if in_zone:
		_time_in_zone += delta
	if in_zone != _was_in_zone: # only touch the label/style when the state changes (no per-frame allocations)
		_was_in_zone = in_zone
		status_label.text = tr("MINIGAME_CALIBRATOR_STABILIZED") if in_zone else ""
		if not _bar_is_sprite:
			tuning_bar.add_theme_stylebox_override("panel", _style_hot if in_zone else _style_idle)
		if in_zone:
			Sfx.play("calibrator_tick")
	_update_visuals()

## Velocity physics: lift while held, gravity otherwise, soft bounce on the floor, hard stop at the ceiling.
func _step_bar(delta: float) -> void:
	var rising: bool = _toggle_rising if input_mode_toggle else _is_pressing_rise
	var accel: float = -lift_accel if rising else gravity_accel
	_bar_v = clampf(_bar_v + accel * delta, -max_speed, max_speed)
	_bar_y += _bar_v * delta
	var floor_y: float = 1.0 - _bar_h
	if _bar_y >= floor_y:
		_bar_y = floor_y
		_bar_v = -_bar_v * floor_bounce if _bar_v > 0.15 else 0.0
	elif _bar_y <= 0.0:
		_bar_y = 0.0
		_bar_v = 0.0

## Erratic target: wanders to random goals with smoothing, and sometimes darts across the track.
func _step_target(delta: float) -> void:
	_retarget_t -= delta
	if _retarget_t <= 0.0:
		_pick_new_goal()
	var ti: int = clampi(_tier - 1, 0, 2)
	var response: float = tier_response[ti] * _speed_mult * (dart_response_mult if _darting else 1.0)
	_target_y = lerpf(_target_y, _goal_y, 1.0 - exp(-response * delta))

func _pick_new_goal() -> void:
	var ti: int = clampi(_tier - 1, 0, 2)
	_darting = randf() < tier_dart_chance[ti]
	var jump: float = tier_max_jump[ti]
	var offset: float = randf_range(-jump, jump)
	if absf(offset) < min_goal_distance:
		offset = min_goal_distance * (1.0 if offset >= 0.0 else -1.0)
	var goal: float = _target_y + offset
	if goal < 0.05 or goal > 0.95: # bounce off the ends instead of sticking to them
		goal = _target_y - offset
	_goal_y = clampf(goal, 0.05, 0.95)
	var wait: float = randf_range(retarget_min_sec, retarget_max_sec) / maxf(0.1, _speed_mult)
	_retarget_t = dart_retarget_sec if _darting else wait

func _update_visuals() -> void:
	tuning_bar.position.y = _bar_y * _track_h
	rpm_target_zone.position.y = _target_y * _track_h - needle_px * 0.5
	var tenth: int = int(_time_remaining * 10.0)
	if tenth != _last_tenth:
		_last_tenth = tenth
		timer_label.text = "%.1fs" % _time_remaining
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
