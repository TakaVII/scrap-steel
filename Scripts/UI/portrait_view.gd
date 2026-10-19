# purpose: Client/speaker portrait. Loads res://Assets/Textures/Portraits/<id>.png (mood variants <id>_<mood>.png). Until the art exists it draws a colored square with initials, so cards and dialogue work today.
# depends on: Control, ClientRoster
# signals emitted: none
# signals listened to: none

class_name PortraitView
extends Control

const DIR: String = "res://Assets/Textures/Portraits/"

var _bg: ColorRect
var _tex: TextureRect
var _initials: Label

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg = ColorRect.new()
	_tex = TextureRect.new()
	_initials = Label.new()
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for n in [_bg, _tex, _initials]:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(n)
		n.set_anchors_preset(Control.PRESET_FULL_RECT)

## px = side length in logical pixels. mood: &"neutral", &"happy" or &"unhappy" (falls back to neutral art).
func setup(id: StringName, px: int = 48, mood: StringName = &"neutral") -> void:
	custom_minimum_size = Vector2(px, px)
	var path: String = DIR + String(id) + ".png"
	if mood != &"neutral":
		var mood_path: String = DIR + String(id) + "_" + String(mood) + ".png"
		if ResourceLoader.exists(mood_path):
			path = mood_path
	if ResourceLoader.exists(path):
		_tex.texture = load(path) as Texture2D
		_tex.visible = true
		_initials.visible = false
		_bg.color = Color(0.08, 0.07, 0.12, 1.0)
	else:
		_tex.visible = false
		_initials.visible = true
		_initials.text = _initials_for(id)
		_bg.color = Color.from_hsv(float(String(id).hash() % 360) / 360.0, 0.45, 0.45)

func _initials_for(id: StringName) -> String:
	var out: String = ""
	for word in ClientRoster.display_name(id).split(" ", false):
		var w: String = String(word).trim_prefix("'")
		if w.length() > 0 and out.length() < 2:
			out += w.substr(0, 1).to_upper()
	return out
