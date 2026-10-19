# purpose: Reusable dialogue box (portrait, name, typewriter text). play(seq_id, lines) shows a sequence; click or Space/Enter advances (finishes typing first); Esc skips the whole sequence. Lines come from StoryData: {who, key, vars, mood, act}.
# depends on: Control, PortraitView, ClientRoster, NumberFormat
# signals emitted: sequence_finished(seq_id), line_shown(index, line)
# signals listened to: none

extends Control

signal sequence_finished(seq_id: StringName)
signal line_shown(index: int, line: Dictionary)

const CHARS_PER_SEC: float = 60.0

@onready var dim: ColorRect = %Dim
@onready var portrait_holder: Control = %PortraitHolder
@onready var name_label: Label = %NameLabel
@onready var text_label: Label = %TextLabel
@onready var hint_label: Label = %HintLabel

var _seq_id: StringName = &""
var _lines: Array = []
var _index: int = -1
var _typing: bool = false
var _tween: Tween
var _portrait: PortraitView

func _ready() -> void:
	visible = false
	_portrait = PortraitView.new()
	portrait_holder.add_child(_portrait)
	_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_gui_input)
	hint_label.text = tr("DIALOGUE_CONTINUE")

func is_playing() -> bool:
	return visible

func play(seq_id: StringName, lines: Array) -> void:
	if lines.is_empty():
		sequence_finished.emit(seq_id)
		return
	_seq_id = seq_id
	_lines = lines
	_index = -1
	visible = true
	_advance()

## Closes the box immediately (emits sequence_finished once).
func skip_all() -> void:
	if visible:
		_close()

func _advance() -> void:
	if _typing:
		_finish_typing()
		return
	_index += 1
	if _index >= _lines.size():
		_close()
		return
	_show_line(_lines[_index])

func _show_line(line: Dictionary) -> void:
	var who: StringName = StringName(line.get("who", "narrator"))
	var narrator: bool = who == &"narrator"
	portrait_holder.visible = not narrator
	name_label.text = "" if narrator else ClientRoster.display_name(who)
	if not narrator:
		_portrait.setup(who, 52, StringName(line.get("mood", "neutral")))
	var raw: String = tr(String(line.get("key", "")))
	text_label.text = NumberFormat.render(raw, line.get("vars", {}))
	text_label.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	_typing = true
	_tween = create_tween()
	_tween.tween_property(text_label, "visible_ratio", 1.0, maxf(0.15, float(text_label.text.length()) / CHARS_PER_SEC))
	_tween.finished.connect(func() -> void:
		_typing = false
	)
	line_shown.emit(_index, line)

func _finish_typing() -> void:
	if _tween:
		_tween.kill()
	text_label.visible_ratio = 1.0
	_typing = false

func _close() -> void:
	if _tween:
		_tween.kill()
	_typing = false
	visible = false
	sequence_finished.emit(_seq_id)

func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()

func _input(event: InputEvent) -> void:
	if not visible or event.is_echo():
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
