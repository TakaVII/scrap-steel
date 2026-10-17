# purpose: [v3] Part button with redundant shape status icons ([✓] DONE vs [◆] AVAILABLE) using GamePalette (spec §C10).
# depends on: Button, ItemPartData, NumberFormat, GamePalette
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
		var quality_pct: int = int(round((0.5 + 0.5 * score) * 100.0))
		text = "[✓] %s (%d%%)" % [tr(part.display_key), quality_pct]
		disabled = true
		add_theme_color_override("font_color", GamePalette.POSITIVE)
	else:
		text = "[◆] %s (%d AP | %s)" % [tr(part.display_key), part.ap_cost, NumberFormat.format_credits(cost)]
		disabled = false
		add_theme_color_override("font_color", GamePalette.NEUTRAL_TEXT)

func _on_pressed() -> void:
	part_selected.emit(part_index)
