# purpose: [v3] Dialogue box that plays BEATS from StoryData: say (typewriter with pauses on punctuation, optional blip sound, portrait bob), pause (silent beat), choice (reply buttons, keys 1-3; loop = topic menu), act (side effect). play(seq_id, lines) / skip_all() / is_playing() keep their v2 API, so pathway_select.gd and story_director.gd are unchanged. Click or Space advances (finishes typing first); Esc skips the whole sequence.
# depends on: Control, PortraitView, ClientRoster, NumberFormat, SettingsManager, EventBus, GamePalette, Juice, Sfx
# signals emitted: sequence_finished(seq_id), line_shown(index, line)
# signals listened to: EventBus.settings_changed

extends Control

signal sequence_finished(seq_id: StringName)
signal line_shown(index: int, line: Dictionary)

const DEFAULT_CPS: float = 60.0
const PLAYER_CPS: float = 95.0
## Dialogue text is this many px bigger than the UI base size. If the pixel font looks blurry at 10, try 12 (bonus 4).
const TEXT_SIZE_BONUS: int = 2
const HOLD_STRONG: String = ".!?"
const HOLD_SOFT: String = ",;:"
const HOLD_STRONG_SEC: float = 0.18
const HOLD_SOFT_SEC: float = 0.08
const BLIP_EVERY: int = 3
const PLAYER_ID: StringName = &"player"

@onready var dim: ColorRect = %Dim
@onready var box: Control = $BoxMargin
@onready var portrait_holder: Control = %PortraitHolder
@onready var name_label: Label = %NameLabel
@onready var text_label: Label = %TextLabel
@onready var hint_label: Label = %HintLabel
@onready var choice_margin: Control = %ChoiceMargin
@onready var choice_box: VBoxContainer = %ChoiceBox

var _seq_id: StringName = &""
var _lines: Array = []
var _index: int = -1
var _typing: bool = false
var _choosing: bool = false
var _waiting: bool = false
var _reveal: float = 0.0
var _cps: float = DEFAULT_CPS
var _hold: float = 0.0
var _checked: int = 0
var _auto_sec: float = 0.0
## Incremented on every advance/close: delayed callbacks (pause, auto-continue) compare it and do nothing when stale.
var _token: int = 0
var _bob: Tween
var _portrait: PortraitView

func _ready() -> void:
	visible = false
	choice_margin.visible = false
	_portrait = PortraitView.new()
	portrait_holder.add_child(_portrait)
	_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_gui_input)
	hint_label.text = "DIALOGUE_CONTINUE" # a key: Label auto-translates it and follows locale changes
	EventBus.settings_changed.connect(_apply_font)
	_apply_font()
	set_process(false)

func _apply_font() -> void:
	var base: int = SettingsManager.FONT_SIZE_LARGE if SettingsManager.large_text else SettingsManager.FONT_SIZE_NORMAL
	text_label.add_theme_font_size_override("font_size", base + TEXT_SIZE_BONUS)

func is_playing() -> bool:
	return visible

func play(seq_id: StringName, lines: Array) -> void:
	if lines.is_empty():
		sequence_finished.emit(seq_id)
		return
	_token += 1
	_clear_choices()
	_seq_id = seq_id
	_lines = lines.duplicate()
	_index = -1
	_typing = false
	_choosing = false
	_waiting = false
	visible = true
	_advance()

## Closes the box immediately (emits sequence_finished once).
func skip_all() -> void:
	if visible:
		_close()

# ---------------------------------------------------------------- flow

func _advance() -> void:
	if _choosing:
		return
	_token += 1
	if _typing:
		_finish_typing()
		return
	_waiting = false
	_index += 1
	_run_beat()

func _run_beat() -> void:
	if _index >= _lines.size():
		_close()
		return
	var beat: Dictionary = _lines[_index]
	match String(beat.get("type", "say")):
		"pause":
			_do_pause(float(beat.get("sec", 0.4)))
		"choice":
			_show_choice(beat)
		"act":
			_apply_act(beat)
			_advance()
		_:
			_show_line(beat)

func _do_pause(sec: float) -> void:
	_waiting = true
	hint_label.visible = false
	var t: int = _token
	await get_tree().create_timer(sec).timeout
	if t == _token and _waiting and visible:
		_waiting = false
		_advance()

func _apply_act(beat: Dictionary) -> void:
	var what: StringName = StringName(beat.get("what", ""))
	if what == &"shake":
		Juice.shake(box, 2.0, 0.15)
	elif what == &"sfx":
		Sfx.play(String(beat.get("name", "")))

# ---------------------------------------------------------------- say

func _show_line(line: Dictionary) -> void:
	var who: StringName = StringName(line.get("who", "narrator"))
	var narrator: bool = who == &"narrator"
	var is_player: bool = who == PLAYER_ID
	portrait_holder.visible = not narrator and not is_player
	if narrator:
		name_label.text = ""
	elif is_player:
		name_label.text = "DLG_YOU" # a key: auto-translated
	else:
		name_label.text = ClientRoster.display_name(who)
		_portrait.setup(who, 52, StringName(line.get("mood", "neutral")))
	var raw: String = tr(String(line.get("key", "")))
	text_label.text = NumberFormat.render(raw, line.get("vars", {}))
	text_label.add_theme_color_override("font_color", GamePalette.NEON_CYAN if is_player else GamePalette.NEUTRAL_TEXT)
	text_label.visible_characters = 0
	_typing = true
	_reveal = 0.0
	_checked = 0
	_hold = 0.0
	_cps = PLAYER_CPS if is_player else float(line.get("cps", DEFAULT_CPS))
	_auto_sec = float(line.get("auto", 0.0))
	hint_label.visible = true
	_start_bob(not narrator and not is_player)
	if StringName(line.get("fx", "")) == &"shake":
		Juice.shake(box, 2.0, 0.15)
	set_process(true)
	line_shown.emit(_index, line)

func _process(delta: float) -> void:
	if not _typing:
		set_process(false)
		return
	if _hold > 0.0:
		_hold -= delta
		return
	var total: int = text_label.text.length()
	_reveal += delta * _cps
	while _checked < total and float(_checked) < _reveal:
		var ch: String = text_label.text.substr(_checked, 1)
		_checked += 1
		if HOLD_STRONG.contains(ch):
			_hold = HOLD_STRONG_SEC
		elif HOLD_SOFT.contains(ch):
			_hold = HOLD_SOFT_SEC
		elif ch != " " and _checked % BLIP_EVERY == 0:
			Sfx.play("dialogue_blip")
		if _hold > 0.0:
			_reveal = float(_checked)
			break
	text_label.visible_characters = _checked
	if _checked >= total:
		_finish_typing()

func _finish_typing() -> void:
	_typing = false
	text_label.visible_characters = -1
	_stop_bob()
	if _auto_sec > 0.0:
		_start_auto(_auto_sec)

func _start_auto(sec: float) -> void:
	var t: int = _token
	await get_tree().create_timer(sec).timeout
	if t == _token and visible and not _typing and not _choosing:
		_advance()

func _start_bob(on: bool) -> void:
	_stop_bob()
	if not on or SettingsManager.reduced_flashing:
		return
	_bob = create_tween().set_loops()
	_bob.tween_property(_portrait, "position:y", -1.0, 0.12)
	_bob.tween_property(_portrait, "position:y", 0.0, 0.12)

func _stop_bob() -> void:
	if _bob and _bob.is_valid():
		_bob.kill()
	_bob = null
	_portrait.position.y = 0.0

# ---------------------------------------------------------------- choice

func _show_choice(beat: Dictionary) -> void:
	_clear_choices()
	_choosing = true
	hint_label.visible = false
	var options: Array = beat.get("options", [])
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var b := Button.new()
		b.text = "%d. %s" % [i + 1, tr(String(opt.get("key", "")))]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.custom_minimum_size = Vector2(0, 18)
		b.pressed.connect(_on_choice_picked.bind(opt, beat))
		choice_box.add_child(b)
	choice_margin.visible = true
	if choice_box.get_child_count() > 0:
		(choice_box.get_child(0) as Button).grab_focus()

func _on_choice_picked(opt: Dictionary, beat: Dictionary) -> void:
	_clear_choices()
	_choosing = false
	choice_margin.visible = false
	# The player speaks the chosen text, then the reply lines play.
	var inject: Array = [{"type": "say", "who": PLAYER_ID, "key": opt.get("key", "")}]
	inject.append_array(opt.get("then", []))
	if bool(beat.get("loop", false)):
		var remaining: Array = []
		var has_topic: bool = false
		for o in beat.get("options", []):
			if o.get("key", "") == opt.get("key", ""):
				continue
			remaining.append(o)
			if not bool(o.get("exit", false)):
				has_topic = true
		if has_topic and not bool(opt.get("exit", false)):
			inject.append({"type": "choice", "options": remaining, "loop": true})
	for i in range(inject.size()):
		_lines.insert(_index + 1 + i, inject[i])
	_advance()

func _clear_choices() -> void:
	for c in choice_box.get_children():
		choice_box.remove_child(c)
		c.queue_free()

# ---------------------------------------------------------------- closing and input

func _close() -> void:
	_token += 1
	_typing = false
	_choosing = false
	_waiting = false
	_stop_bob()
	_clear_choices()
	choice_margin.visible = false
	visible = false
	set_process(false)
	sequence_finished.emit(_seq_id)

func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()

func _input(event: InputEvent) -> void:
	if not visible or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
		return
	if _choosing:
		# Keys 1..3 pick a reply; Enter/Space press the focused button (not handled here).
		if event is InputEventKey and event.pressed:
			var n: int = int(event.keycode) - KEY_1
			if n >= 0 and n < choice_box.get_child_count():
				get_viewport().set_input_as_handled()
				(choice_box.get_child(n) as Button).pressed.emit()
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()
