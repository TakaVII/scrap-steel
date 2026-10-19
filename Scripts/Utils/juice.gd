# purpose: [v2] Feedback juice utility: screen shake (now drift-safe when shakes overlap), hit-stop, rolling number tweens, floating text.
# depends: SettingsManager, Engine, SceneTree, Tween
# signals emitted: none
# signals listened to: none

class_name Juice
extends RefCounted

const SHAKE_ORIGIN: StringName = &"_shake_origin"
const SHAKE_TWEEN: StringName = &"_shake_tween"

## Shakes a CanvasLayer (offset) or a Control that is NOT managed by a container (position).
## Overlapping shakes reuse the first origin, so the node always returns to where it started.
static func shake(target: Node, intensity: float = 4.0, duration: float = 0.15) -> void:
	if SettingsManager.reduced_flashing or target == null:
		return
	var is_layer: bool = target is CanvasLayer
	if target.has_meta(SHAKE_TWEEN):
		var old: Tween = target.get_meta(SHAKE_TWEEN) as Tween
		if old and old.is_valid():
			old.kill()
	var origin: Vector2
	if target.has_meta(SHAKE_ORIGIN):
		origin = target.get_meta(SHAKE_ORIGIN)
	else:
		origin = (target as CanvasLayer).offset if is_layer else (target as Control).position
		target.set_meta(SHAKE_ORIGIN, origin)
	var tween := target.create_tween()
	target.set_meta(SHAKE_TWEEN, tween)
	var steps: int = maxi(1, int(duration / 0.03))
	for i in range(steps):
		var jitter := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(target, "offset" if is_layer else "position", origin + jitter, 0.03)
	tween.tween_property(target, "offset" if is_layer else "position", origin, 0.03)
	tween.tween_callback(func() -> void:
		target.remove_meta(SHAKE_ORIGIN)
		target.remove_meta(SHAKE_TWEEN)
	)

## Dips time_scale briefly. The timer ignores time scale so the restore is always on time.
static func hit_stop(tree: SceneTree, duration_sec: float = 0.06) -> void:
	if SettingsManager.reduced_flashing or not tree:
		return
	Engine.time_scale = 0.05
	var timer := tree.create_timer(duration_sec, true, false, true)
	timer.timeout.connect(func() -> void:
		Engine.time_scale = 1.0
	)

## Smoothly rolls a numeric label over a duration.
static func animate_number(node: Node, label: Label, from_val: int, to_val: int, prefix: String = "", suffix: String = "", duration: float = 0.4) -> void:
	if not node or not label:
		return
	var tween := node.create_tween()
	tween.tween_method(func(val: Variant) -> void:
		label.text = "%s%d%s" % [prefix, roundi(float(val)), suffix]
	, from_val, to_val, duration)

## Spawns drifting floating text.
static func spawn_floating_text(parent: Control, text_msg: String, pos: Vector2, text_color: Color = Color.WHITE) -> void:
	if not parent:
		return
	var lbl := Label.new()
	lbl.text = text_msg
	lbl.position = pos
	lbl.modulate = text_color
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)

	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", pos.y - 20.0, 0.6)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(lbl.queue_free)
