# purpose: Part interactive button displaying component name, AP cost, nominal material cost, and completion status.
# depends on: Button, ItemPartData, NumberFormat
# signals emitted: part_selected(part_index: int)
# signals listened to: none

extends Button

signal part_selected(part_index: int)

var part_index: int = 0
var part_data: ItemPartData
var score: float = -1.0

func setup(idx: int, part: ItemPartData, current_score: float, tier: int) -> void:
	part_index = idx
	part_data = part
	score = current_score

	var cost: int = part.nominal_material_cost(tier)
	if score >= 0.0:
		text = "%s [DONE: %d%%]" % [tr(part.display_key), int(round((0.5 + 0.5 * score) * 100.0))]
		disabled = true
	else:
		text = "%s (%d AP | %s)" % [tr(part.display_key), part.ap_cost, NumberFormat.format_credits(cost)]
		disabled = false

func _on_pressed() -> void:
	part_selected.emit(part_index)
