# purpose: The Calibrator minigame balancing tuning bar over drifting RPM zone with Hold or Toggle controls.
# depends on: MinigameBase, Balance
# signals emitted: finished(score: float)
# signals listened to: none

extends MinigameBase

@export_group("Calibrator Mechanics")
@export var round_duration_sec: float = 15.0
@export var bar_rise_speed: float = 240.0
@export var bar_gravity_speed: float = 200.0
@export var base_drift_speed: float = 45.0
@export var tier_speed_mults: Array[float] = [1.0, 1.3, 1.6]
@export var tier_zone_height_fractions: Array[float] = [0.28, 0.22, 0.18]
@export var input_mode_toggle: bool = false

@onready var track_panel: Control = %TrackPanel
@onready var rpm_target_zone: Panel = %RpmTargetZone
@onready var tuning_bar: Panel = %TuningBar
@onready var timer_label: Label = %TimerLabel
@onready var score_progress: ProgressBar = %ScoreProgress
@onready var instruct_label: Label = %InstructLabel
@onready var status_label: Label = %StatusLabel

var _time_remaining: float = 15.0
var _time_in_zone: float = 0.0
var _tier: int = 1
var _bar_pos_y: float = 100.0
var _bar_velocity_y: float = 0.0
var _target_zone_y: float = 80.0
var _drift_dir: float = 1.0
var _zone_height: float = 50.0
var _track_height: float = 180.0
var _is_pressing_rise: bool = false
var _toggle_rising: bool = false
var _speed_mult: float = 1.0

func setup(diff: Dictionary) -> void:
	super.setup(diff)
	_tier = diff.get("tier", 1)
	_speed_mult = diff.get("speed_mult", 1.0)
	input_mode_toggle = diff.get("input_mode_toggle", false)
	_time_remaining = round_duration_sec

func start() -> void:
	super.start()
	_track_height = maxf(120.0, track_panel.size.y)
	var tier_idx: int = clampi(_tier - 1, 0, 2)
	var h_frac: float = tier_zone_height_fractions[tier_idx]
	if difficulty.get("window_mult", 1.0) > 1.0:
		h_frac *= difficulty.get("window_mult", 1.0)
	_zone_height = _track_height * h_frac
	rpm_target_zone.custom_minimum_size.y = _zone_height
	rpm_target_zone.size.y = _zone_height

	_bar_pos_y = _track_height * 0.5
	_target_zone_y = _track_height * 0.4
	_update_visuals()

	if input_mode_toggle:
		instruct_label.text = tr("MINIGAME_CALIBRATOR_INSTRUCT_TOGGLE")
	else:
		instruct_label.text = tr("MINIGAME_CALIBRATOR_INSTRUCT_HOLD")

func _process(delta: float) -> void:
	if not is_active:
		return

	_time_remaining -= delta
	if _time_remaining <= 0.0:
		_time_remaining = 0.0
		var final_score: float = _time_in_zone / round_duration_sec
		_finish(final_score)
		return

	# Handle bar physics with delta
	var should_rise: bool = _toggle_rising if input_mode_toggle else _is_pressing_rise
	if should_rise:
		_bar_pos_y -= bar_rise_speed * delta
	else:
		_bar_pos_y += bar_gravity_speed * delta
	_bar_pos_y = clampf(_bar_pos_y, 0.0, _track_height - 10.0)

	# Handle RPM zone drift
	var drift_speed: float = base_drift_speed * tier_speed_mults[clampi(_tier - 1, 0, 2)] * _speed_mult
	_target_zone_y += drift_speed * _drift_dir * delta
	if _target_zone_y <= 0.0:
		_target_zone_y = 0.0
		_drift_dir = 1.0
	elif _target_zone_y >= _track_height - _zone_height:
		_target_zone_y = _track_height - _zone_height
		_drift_dir = -1.0

	# Check overlap
	var bar_center: float = _bar_pos_y + 5.0
	var in_zone: bool = bar_center >= _target_zone_y and bar_center <= (_target_zone_y + _zone_height)
	if in_zone:
		_time_in_zone += delta
		status_label.text = tr("MINIGAME_CALIBRATOR_STABILIZED")
	else:
		status_label.text = ""

	_update_visuals()

func _update_visuals() -> void:
	tuning_bar.position.y = _bar_pos_y
	rpm_target_zone.position.y = _target_zone_y
	timer_label.text = "%.1fs" % _time_remaining
	score_progress.value = (_time_in_zone / round_duration_sec) * 100.0

func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if input_mode_toggle:
			if event.pressed:
				_toggle_rising = not _toggle_rising
		else:
			_is_pressing_rise = event.pressed

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action("ui_accept") or event.is_action("ui_select"):
		if input_mode_toggle:
			if event.is_pressed() and not event.is_echo():
				_toggle_rising = not _toggle_rising
		else:
			_is_pressing_rise = event.is_pressed()
