# purpose: [v2] The Forge minigame wired with Juice hit-stop pause, screen shake, and floating rating text.
# depends on: MinigameBase, Balance, Juice
# signals emitted: finished(score: float)
# signals listened to: none

extends MinigameBase

@export_group("Forge Mechanics")
@export var total_strikes: int = 5
@export var base_cursor_speed: float = 320.0
@export var speed_increase_per_strike: float = 1.08
@export var tier_speed_mults: Array[float] = [1.0, 1.25, 1.5]
@export var tier_sweet_spot_fractions: Array[float] = [0.18, 0.14, 0.11]
@export var falloff_tolerance_factor: float = 1.5
@export var hit_stop_duration_sec: float = 0.06

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
var _hit_stop_timer: float = 0.0

func setup(diff: Dictionary) -> void:
	super.setup(diff)
	_tier = diff.get("tier", 1)
	var tier_idx: int = clampi(_tier - 1, 0, 2)
	var speed_mult: float = diff.get("speed_mult", 1.0) * tier_speed_mults[tier_idx]
	_cursor_speed = base_cursor_speed * speed_mult

func start() -> void:
	super.start()
	_current_strike_idx = 0
	_strike_scores.clear()
	_bar_width = maxf(200.0, strike_bar_panel.size.x)
	var tier_idx: int = clampi(_tier - 1, 0, 2)
	var width_frac: float = tier_sweet_spot_fractions[tier_idx]
	if difficulty.get("window_mult", 1.0) > 1.0:
		width_frac *= difficulty.get("window_mult", 1.0)

	_sweet_half_width = (_bar_width * width_frac) * 0.5
	_sweet_center_x = _bar_width * 0.5
	_setup_sweet_spot()
	_cursor_pos_x = 0.0
	_cursor_dir = 1.0
	_update_strike_ui()

func _setup_sweet_spot() -> void:
	var w: float = _sweet_half_width * 2.0
	sweet_spot_panel.custom_minimum_size.x = w
	sweet_spot_panel.size.x = w
	sweet_spot_panel.position.x = _sweet_center_x - _sweet_half_width

func _process(delta: float) -> void:
	if not is_active:
		return

	if _hit_stop_timer > 0.0:
		_hit_stop_timer -= delta
		return

	_cursor_pos_x += _cursor_speed * _cursor_dir * delta
	if _cursor_pos_x >= _bar_width - 8.0:
		_cursor_pos_x = _bar_width - 8.0
		_cursor_dir = -1.0
	elif _cursor_pos_x <= 0.0:
		_cursor_pos_x = 0.0
		_cursor_dir = 1.0

	cursor_panel.position.x = _cursor_pos_x

func _gui_input(event: InputEvent) -> void:
	if not is_active or _hit_stop_timer > 0.0:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_trigger_strike()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active or _hit_stop_timer > 0.0:
		return
	if (event.is_action("ui_accept") or event.is_action("ui_select")) and event.is_pressed() and not event.is_echo():
		_trigger_strike()

func _trigger_strike() -> void:
	var dist: float = absf(_cursor_pos_x - _sweet_center_x)
	var s: float = clampf(1.0 - (dist / (falloff_tolerance_factor * _sweet_half_width)), 0.0, 1.0)
	_strike_scores.append(s)
	_hit_stop_timer = hit_stop_duration_sec

	# Juice impact hooks
	Juice.hit_stop(get_tree(), hit_stop_duration_sec)
	Juice.shake(strike_bar_panel, 3.5 * s, 0.12)

	# Feedback rating and floating text
	var rating_text: String = ""
	var rating_color: Color = Color.WHITE
	if s >= 0.90:
		rating_text = tr("MINIGAME_FORGE_STRIKE_PERFECT") + " (%.0f%%)" % (s * 100.0)
		rating_color = Color(0.168, 0.513, 0.729, 1.0)
	elif s >= 0.50:
		rating_text = tr("MINIGAME_FORGE_STRIKE_GOOD") + " (%.0f%%)" % (s * 100.0)
		rating_color = Color(0.992, 0.682, 0.380, 1.0)
	else:
		rating_text = tr("MINIGAME_FORGE_STRIKE_MISS") + " (%.0f%%)" % (s * 100.0)
		rating_color = Color(0.843, 0.098, 0.109, 1.0)

	feedback_label.text = rating_text
	Juice.spawn_floating_text(self, rating_text, cursor_panel.global_position, rating_color)

	_current_strike_idx += 1
	_cursor_speed *= speed_increase_per_strike
	_sweet_center_x = _bar_width * randf_range(0.35, 0.65)
	_setup_sweet_spot()
	_update_strike_ui()

	if _current_strike_idx >= total_strikes:
		var sum: float = 0.0
		for val in _strike_scores: sum += val
		var final_score: float = sum / float(total_strikes)
		_finish(final_score)

func _update_strike_ui() -> void:
	strike_count_label.text = "Strike %d / %d" % [mini(_current_strike_idx + 1, total_strikes), total_strikes]
	var pips = pips_container.get_children()
	for i in range(pips.size()):
		if pips[i] is ColorRect:
			if i < _strike_scores.size():
				var score_val = _strike_scores[i]
				pips[i].color = Color(0.168, 0.513, 0.729, 1.0) if score_val >= 0.5 else Color(0.843, 0.098, 0.109, 1.0)
			else:
				pips[i].color = Color(0.3, 0.3, 0.35, 1.0)
