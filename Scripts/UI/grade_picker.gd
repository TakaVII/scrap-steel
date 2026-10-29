# purpose: Modal that asks which material grade to use for a part (Scrap / Standard / Premium) before its minigame starts. Built in code, added by workshop_screen.gd. Shows the cost of each grade (with today's market price), the budget left, and why a grade is unavailable.
# depends on: Control, CraftingManager, CommissionManager, MaterialGrade, NumberFormat, Balance, GamePalette
# signals emitted: picked(grade: int)
# signals listened to: none

class_name GradePicker
extends Control

signal picked(grade: int)

const PANEL_WIDTH: float = 340.0

var _title: Label
var _info: Label
var _buttons: Array[Button] = []
var _descs: Array[Label] = []

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	add_child(dim)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)

	_title = Label.new()
	_title.add_theme_color_override("font_color", GamePalette.ACCENT)
	vbox.add_child(_title)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_info)
	vbox.add_child(HSeparator.new())
	for g in range(3):
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 20)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_grade_pressed.bind(g))
		vbox.add_child(b)
		_buttons.append(b)
		var d := Label.new()
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_constant_override("line_spacing", 0)
		d.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 1.0))
		vbox.add_child(d)
		_descs.append(d)
	var cancel := Button.new()
	cancel.text = "COMMON_CLOSE"
	cancel.pressed.connect(_close)
	vbox.add_child(cancel)

func open(job: CommissionState, part_index: int) -> void:
	var part: ItemPartData = job.parts[part_index]
	_title.text = tr("GRADE_PICK_TITLE") + ": " + tr(part.display_key)
	var bits: Array[String] = []
	bits.append("%s: %d" % [tr("HUD_AP"), CraftingManager.part_ap(job, part_index)])
	bits.append(tr("GRADE_BUDGET_LEFT") + ": " + NumberFormat.format_credits(maxi(0, job.budget_cap - job.materials_spent)))
	if not job.data.is_champion_build:
		bits.append(NumberFormat.render(tr("GRADE_MARKET"), {"pct": _pct_text(CommissionManager.market_mult)}))
	_info.text = "  |  ".join(bits)
	for g in range(3):
		var cost: int = CraftingManager.max_part_cost(job, part_index, g)
		var reason: StringName = CraftingManager.can_start(job, part_index, g)
		var champion_block: bool = job.data.is_champion_build and g == MaterialGrade.Grade.SCRAP
		_buttons[g].text = "%s  -  %s" % [tr(MaterialGrade.name_key(g)), NumberFormat.format_credits(cost)]
		_buttons[g].disabled = reason != &"" or champion_block
		_descs[g].text = _describe(g, champion_block, reason)
	visible = true
	_buttons[MaterialGrade.Grade.STANDARD].grab_focus()

func _describe(g: int, champion_block: bool, reason: StringName) -> String:
	var text: String = ""
	match g:
		MaterialGrade.Grade.SCRAP:
			text = NumberFormat.render(tr("GRADE_DESC_SCRAP"), {"cap": roundi(Balance.cfg.scrap_quality_cap * 100.0)})
		MaterialGrade.Grade.PREMIUM:
			text = NumberFormat.render(tr("GRADE_DESC_PREMIUM"), {"bonus": roundi(Balance.cfg.premium_quality_bonus * 100.0)})
		_:
			text = tr("GRADE_DESC_STANDARD")
	if champion_block:
		text = tr("GRADE_NO_SCRAP")
	elif reason == &"no_funds":
		text += " " + tr("WORKSHOP_NO_FUNDS")
	elif reason == &"over_budget":
		text += " " + tr("WORKSHOP_NO_BUDGET")
	return text

static func _pct_text(mult: float) -> String:
	var p: int = roundi((mult - 1.0) * 100.0)
	return ("+" if p >= 0 else "") + str(p) + "%"

func _on_grade_pressed(g: int) -> void:
	visible = false
	picked.emit(g)

func _close() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
