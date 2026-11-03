# purpose: [v2 scene-based] Blueprint of the item a contract builds (drift car / mech / cyberware) with each part sitting ON the spot where it goes in the finished item. The layout is in the scenes: item_preview_car / _mech / _cyber.tscn. Each has a Blueprint picture and one Marker2D per part archetype under %Markers, named Slot_<ARCHETYPE> (e.g. Slot_MOTOR). DRAG THE MARKERS in the editor to tune where every part lands. Slots are PartSlot scenes created on %SlotsLayer. Two parts of the same archetype stack with a small offset. Use ItemPreview.create(job) to get the right scene.
# depends on: Control, PartSlot, CommissionState, CommissionData, ItemPartData
# signals emitted: none
# signals listened to: none

class_name ItemPreview
extends Control

## Loaded at runtime with load(): preload would be a circular dependency (the scenes use this script).
const SCENE_PATHS: Dictionary = {
	CommissionData.Type.CAR: "res://Scenes/UI/item_preview_car.tscn",
	CommissionData.Type.MECH: "res://Scenes/UI/item_preview_mech.tscn",
	CommissionData.Type.CYBER: "res://Scenes/UI/item_preview_cyber.tscn",
}
const PART_SLOT_PATH: String = "res://Scenes/UI/part_slot.tscn"
const STACK_OFFSET: Vector2 = Vector2(5, 5)
const Q_POOR: float = 0.50
const Q_OK: float = 0.75
const Q_GREAT: float = 0.90

@onready var blueprint: TextureRect = %Blueprint
@onready var quality_label: Label = %QualityLabel
@onready var markers: Control = %Markers
@onready var slots_layer: Control = %SlotsLayer

static func quality_color(q: float) -> Color:
	if q < Q_POOR:
		return GamePalette.NEGATIVE
	if q < Q_OK:
		return GamePalette.ACCENT
	if q < Q_GREAT:
		return GamePalette.POSITIVE
	return GamePalette.NEON_CYAN

## Instances the preview scene for the contract's item type. Add it to the tree, THEN call setup().
static func create(job: CommissionState) -> ItemPreview:
	var path: String = SCENE_PATHS.get(job.data.type, SCENE_PATHS[CommissionData.Type.CAR])
	var preview: ItemPreview = (load(path) as PackedScene).instantiate() as ItemPreview
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return preview

func setup(job: CommissionState, pop_index: int = -1) -> void:
	for child in slots_layer.get_children():
		slots_layer.remove_child(child)
		child.queue_free()
	var done: int = _done_count(job)
	var progress: float = float(done) / float(maxi(1, job.parts.size()))
	var b: float = 0.45 + 0.55 * progress # the blueprint "powers up" as parts are finished
	var tint: Color = Color(b, b, b, 1.0)
	quality_label.visible = done > 0
	if done > 0:
		var q: float = job.calculate_quality()
		tint = tint.lerp(quality_color(q), 0.30 * progress)
		quality_label.text = "%d%%" % roundi(q * 100.0)
		quality_label.add_theme_color_override("font_color", quality_color(q))
	blueprint.modulate = tint

	var packed: PackedScene = load(PART_SLOT_PATH) as PackedScene
	var used: Dictionary = {}
	for i in range(job.parts.size()):
		var slot: PartSlot = packed.instantiate() as PartSlot
		slots_layer.add_child(slot)
		var key: String = ItemPartData.Archetype.keys()[job.parts[i].archetype]
		var marker: Node2D = markers.get_node_or_null("Slot_" + key) as Node2D
		var center: Vector2 = marker.position if marker != null else _fallback_center(i, job.parts.size())
		var n: int = int(used.get(key, 0))
		used[key] = n + 1
		center += STACK_OFFSET * float(n)
		slot.position = center - Vector2(PartSlot.SLOT_PX, PartSlot.SLOT_PX) * 0.5
		slot.setup(job, i, i == pop_index)

## A marker is missing in the scene (renamed or deleted): spread the slots along the bottom edge.
func _fallback_center(i: int, count: int) -> Vector2:
	var step: float = size.x / float(maxi(1, count))
	return Vector2(step * (float(i) + 0.5), size.y - PartSlot.SLOT_PX * 0.5)

func _done_count(job: CommissionState) -> int:
	var n: int = 0
	for s in job.part_scores:
		if s >= 0.0:
			n += 1
	return n
