# purpose: [v5] Part button. Cost, AP, material grade and final quality are passed in (Champion Build parts do not use the archetype nominal cost; AP depends on the contract tier).
# depends on: Button, ItemPartData, MaterialGrade, NumberFormat, GamePalette
# signals emitted: part_selected(part_index: int)
# signals listened to: none

extends Button

signal part_selected(part_index: int)

var part_index: int = 0
var part_data: ItemPartData
var score: float = -1.0

## ap_cost < 0 = use the part's base AP. grade/quality < 0 = unknown (part not finished).
func setup(idx: int, part: ItemPartData, current_score: float, _tier: int, cost: int, ap_cost: int = -1, grade: int = -1, quality: float = -1.0) -> void:
	part_index = idx
	part_data = part
	score = current_score
	custom_minimum_size = Vector2(0, 18)
	var ap: int = ap_cost if ap_cost >= 0 else part.ap_cost

	if score >= 0.0:
		var quality_pct: int = roundi((quality if quality >= 0.0 else 0.5 + 0.5 * score) * 100.0)
		var grade_txt: String = ""
		if grade >= 0:
			grade_txt = " | " + tr(MaterialGrade.name_key(grade))
		text = "%s%s (%d%%%s)" % [GamePalette.ICON_PASS, tr(part.display_key), quality_pct, grade_txt]
		disabled = true
		add_theme_color_override("font_color", GamePalette.POSITIVE)
	else:
		text = "%s%s (%d AP | %s)" % [GamePalette.ICON_INFO, tr(part.display_key), ap, NumberFormat.format_credits(cost)]
		disabled = false
		add_theme_color_override("font_color", GamePalette.NEUTRAL_TEXT)

func _on_pressed() -> void:
	part_selected.emit(part_index)
