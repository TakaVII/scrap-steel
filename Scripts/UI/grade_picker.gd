# purpose: [v2] Modal that asks which material grade to use for a part (Scrap / Standard / Premium) before its minigame starts. v2: COMPACT layout. Each grade is ONE row (button with name and cost on the left, a 2-line description on the right) instead of button + description stacked, so the whole panel is about 120 px tall at the normal font and still fits when the font is tall. The panel is pushed below the HUD (it reads the top margin that main.gd gives the workshop screen) and never grows past the screen. Built in code, added by workshop_screen.gd. Shows today's market price, the budget left, and why a grade is unavailable.
# depends on: Control, CraftingManager, CommissionManager, MaterialGrade, NumberFormat, Balance, GamePalette
# signals emitted: picked(grade: int)
# signals listened to: none

class_name GradePicker
extends Control

signal picked(grade: int)

const PANEL_WIDTH: float = 440.0
const GRADE_BUTTON_WIDTH: float = 124.0
const ROW_HEIGHT: float = 20.0
const SIDE_MARGIN_PX: int = 6
const BOTTOM_MARGIN_PX: int = 6
## Used only when the workshop screen's top margin cannot be read.
const DEFAULT_TOP_INSET: int = 34

var _outer: MarginContainer
var _title: Label
var _info: Label
var _buttons: Array[Button] = []
var _descs: Array[Label] = []

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# The margin container keeps the panel inside the free area (below the HUD, above the screen bottom).
	_outer = MarginContainer.new()
	_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outer.add_theme_constant_override("margin_left", SIDE_MARGIN_PX)
	_outer.add_theme_constant_override("margin_right", SIDE_MARGIN_PX)
	_outer.add_theme_constant_override("margin_bottom", BOTTOM_MARGIN_PX)
	_outer.add_theme_constant_override("margin_top", DEFAULT_TOP_INSET)
	add_child(_outer)
	_outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)

	_title = Label.new()
	_title.clip_text = true
	_title.add_theme_color_override("font_color", GamePalette.ACCENT)
	vbox.add_child(_title)
	_info = Label.new()
	_info.clip_text = true
	vbox.add_child(_info)
	vbox.add_child(HSeparator.new())

	for g in range(3):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)
		var b := Button.new()
		b.custom_minimum_size = Vector2(GRADE_BUTTON_WIDTH, ROW_HEIGHT)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(_on_grade_pressed.bind(g))
		row.add_child(b)
		_buttons.append(b)
		var d := Label.new()
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.max_lines_visible = 2
		d.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		d.add_theme_constant_override("line_spacing", 0)
		d.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 1.0))
		row.add_child(d)
		_descs.append(d)

	var cancel := Button.new()
	cancel.text = "COMMON_CLOSE"
	cancel.pressed.connect(_close)
	vbox.add_child(cancel)

## The workshop screen's top margin is set by main.gd to sit just under the HUD, so the picker follows it.
func _top_inset() -> int:
	var host: Node = get_parent()
	if host != null:
		var m: Control = host.get_node_or_null("MarginContainer") as Control
		if m != null:
			return m.get_theme_constant("margin_top")
	return DEFAULT_TOP_INSET

func open(job: CommissionState, part_index: int) -> void:
	var part: ItemPartData = job.parts[part_index]
	_outer.add_theme_constant_override("margin_top", _top_inset())
	_title.text = tr("GRADE_PICK_TITLE") + ": " + tr(part.display_key)
	var bits: Array[String] = []
	bits.append("%s: %d" % [tr("HUD_AP"), CraftingManager.part_ap(job, part_index)])
	bits.append(tr("GRADE_BUDGET_LEFT") + ": " + NumberFormat.format_credits(maxi(0, job.budget_cap - job.materials_spent)))
	if not job.data.is_champion_build:
		bits.append(NumberFormat.render(tr("GRADE_MARKET"), {"pct": _pct_text(CommissionManager.market_mult)}))
	_info.text = "  |  ".join(bits)
	var first_enabled: int = -1
	for g in range(3):
		var cost: int = CraftingManager.max_part_cost(job, part_index, g)
		var reason: StringName = CraftingManager.can_start(job, part_index, g)
		var champion_block: bool = job.data.is_champion_build and g == MaterialGrade.Grade.SCRAP
		_buttons[g].text = "%s - %s" % [tr(MaterialGrade.name_key(g)), NumberFormat.format_credits(cost)]
		_buttons[g].disabled = reason != &"" or champion_block
		_descs[g].text = _describe(g, champion_block, reason)
		_descs[g].tooltip_text = _descs[g].text
		if first_enabled == -1 and not _buttons[g].disabled:
			first_enabled = g
	visible = true
	if _buttons[MaterialGrade.Grade.STANDARD].disabled == false:
		_buttons[MaterialGrade.Grade.STANDARD].grab_focus()
	elif first_enabled != -1:
		_buttons[first_enabled].grab_focus()

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
