# purpose: Feedback juice utility managing screen shake, hit-stop pauses, rolling number tweens, and floating text.
# depends: SettingsManager, Engine, SceneTree, Tween
# signals emitted: none
# signals listened to: none

class_name Juice
extends RefCounted

## Triggers screen shake by offsetting a CanvasLayer or Control node, respecting reduced flashing setting
static func shake(target: Node, intensity: float = 4.0, duration: float = 0.15) -> void:
	if SettingsManager.reduced_flashing:
		return
	if not target:
		return
	var orig_pos: Vector2 = target.offset if (target is CanvasLayer) else (target as Control).position
	var tween := target.create_tween()
	var steps: int = int(duration / 0.03)
	for i in range(steps):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		if target is CanvasLayer:
			tween.tween_property(target, "offset", orig_pos + offset, 0.03)
		else:
			tween.tween_property(target, "position", orig_pos + offset, 0.03)
	if target is CanvasLayer:
		tween.tween_property(target, "offset", orig_pos, 0.03)
	else:
		tween.tween_property(target, "position", orig_pos, 0.03)

## Pauses engine time briefly for hit-stop tactile impact
static func hit_stop(tree: SceneTree, duration_sec: float = 0.06) -> void:
	if SettingsManager.reduced_flashing or not tree:
		return
	Engine.time_scale = 0.05
	var timer := tree.create_timer(duration_sec, true, false, true)
	timer.timeout.connect(func() -> void:
		Engine.time_scale = 1.0
	)

## Smoothly rolls up/down a numerical label over duration
static func animate_number(node: Node, label: Label, from_val: int, to_val: int, prefix: String = "", suffix: String = "", duration: float = 0.4) -> void:
	if not node or not label:
		return
	var tween := node.create_tween()
	tween.tween_method(func(val: int) -> void:
		label.text = "%s%d%s" % [prefix, val, suffix]
	, from_val, to_val, duration)

## Spawns drifting floating rating text
static func spawn_floating_text(parent: Control, text_msg: String, pos: Vector2, text_color: Color = Color.WHITE) -> void:
	if not parent:
		return
	var lbl := Label.new()
	lbl.text = text_msg
	lbl.position = pos
	lbl.modulate = text_color
	parent.add_child(lbl)

	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", pos.y - 20.0, 0.6)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(lbl.queue_free)
