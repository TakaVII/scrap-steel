# purpose: Optional-sprite helpers. Every function returns null/false when the PNG does not exist, so the game keeps its placeholder look until the art is dropped in by filename (see Docs/sprite_spec.md).
# depends on: RefCounted
# signals emitted: none
# signals listened to: none

class_name SpriteKit
extends RefCounted

const MG: String = "res://Assets/Textures/Minigames/"
const UI: String = "res://Assets/Textures/UI/"
const BG: String = "res://Assets/Textures/Backgrounds/"

static var _cache: Dictionary = {}

## Cached texture lookup. Returns null when the file does not exist.
static func tex(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	_cache[path] = t
	return t

## Horizontal strip -> AnimatedSprite2D. anims = {"name": [frame indexes]}. Null when the file is missing.
static func animated(path: String, frame_w: int, frame_h: int, anims: Dictionary, fps: float = 12.0) -> AnimatedSprite2D:
	var t: Texture2D = tex(path)
	if t == null:
		return null
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	for anim_name in anims.keys():
		frames.add_animation(StringName(anim_name))
		frames.set_animation_speed(StringName(anim_name), fps)
		frames.set_animation_loop(StringName(anim_name), false)
		for idx in anims[anim_name]:
			var at := AtlasTexture.new()
			at.atlas = t
			at.region = Rect2(int(idx) * frame_w, 0, frame_w, frame_h)
			frames.add_frame(StringName(anim_name), at)
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = frames
	return spr

## Replaces a Panel's flat style with a stretched texture. False when the file is missing.
static func swap_panel(panel: Panel, path: String) -> bool:
	var t: Texture2D = tex(path)
	if t == null:
		return false
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(r)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	return true

## Same, but 9-slice (for bars whose height changes with the tier).
static func swap_panel_nine(panel: Panel, path: String, margin: int) -> bool:
	var t: Texture2D = tex(path)
	if t == null:
		return false
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var n := NinePatchRect.new()
	n.texture = t
	n.patch_margin_left = margin
	n.patch_margin_right = margin
	n.patch_margin_top = margin
	n.patch_margin_bottom = margin
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(n)
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	return true
