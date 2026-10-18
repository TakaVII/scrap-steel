# purpose: [v4 manual fix] Part button. Cost is passed in (Champion Build parts do not use the archetype nominal cost). Compact height for the 480x270 viewport.
# depends on: Button, ItemPartData, NumberFormat, GamePalette
# signals emitted: part_selected(part_index: int)
# signals listened to: none

extends Button

signal part_selected(part_index: int)

var part_index: int = 0
var part_data: ItemPartData
var score: float = -1.0

func setup(idx: int, part: ItemPartData, current_score: float, _tier: int, cost: int) -> void:
	part_index = idx
	part_data = part
	score = current_score
	custom_minimum_size = Vector2(0, 18)

	if score >= 0.0:
		var quality_pct: int = roundi((0.5 + 0.5 * score) * 100.0)
		text = "%s%s (%d%%)" % [GamePalette.ICON_PASS, tr(part.display_key), quality_pct]
		disabled = true
		add_theme_color_override("font_color", GamePalette.POSITIVE)
	else:
		text = "%s%s (%d AP | %s)" % [GamePalette.ICON_INFO, tr(part.display_key), part.ap_cost, NumberFormat.format_credits(cost)]
		disabled = false
		add_theme_color_override("font_color", GamePalette.NEUTRAL_TEXT)

func _on_pressed() -> void:
	part_selected.emit(part_index)
