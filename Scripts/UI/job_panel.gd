# purpose: One active contract in the workshop: header, materials/power/quality line, the blueprint preview and the part cells. Built from Scenes/UI/job_panel.tscn (it used to be assembled node by node in workshop_screen.gd). All text is clipped, so a long language can never widen the screen.
# depends on: PanelContainer, CommissionState, ItemPreview, PartCell, NumberFormat, GamePalette
# signals emitted: part_clicked(job, part_index), sim_clicked(job, part_index), reforge_clicked(part_index)
# signals listened to: PartCell.part_pressed, sim_pressed, reforge_pressed

class_name JobPanel
extends PanelContainer

signal part_clicked(job: CommissionState, part_index: int)
signal sim_clicked(job: CommissionState, part_index: int)
signal reforge_clicked(part_index: int)

const PART_CELL_SCENE = preload("res://Scenes/UI/part_cell.tscn")

@onready var header_label: Label = %HeaderLabel
@onready var stats_label: Label = %StatsLabel
@onready var preview: ItemPreview = %Preview
@onready var parts_row: HFlowContainer = %PartsRow

var _job: CommissionState

## Call AFTER add_child. pop_index = part that just finished (plays the snap-in animation), -1 = none.
func setup(job: CommissionState, pop_index: int = -1) -> void:
	_job = job
	_fill_texts(job)
	preview.setup(job, pop_index)
	for child in parts_row.get_children():
		parts_row.remove_child(child)
		child.queue_free()
	for i in range(job.parts.size()):
		var cell: PartCell = PART_CELL_SCENE.instantiate()
		parts_row.add_child(cell)
		cell.setup(job, i)
		cell.part_pressed.connect(_on_part_pressed)
		cell.sim_pressed.connect(_on_sim_pressed)
		cell.reforge_pressed.connect(_on_reforge_pressed)

func _fill_texts(job: CommissionState) -> void:
	if job.data.is_champion_build:
		header_label.text = "T%d %s" % [job.tier, tr(job.data.title_key)]
		if job.is_complete():
			header_label.text += " | %s %d%% / %d%%" % [tr("WORKSHOP_QUALITY"), roundi(job.calculate_quality() * 100.0), roundi(Balance.cfg.champion_min_quality * 100.0)]
	else:
		var due: String = tr("OFFER_DEADLINE") + " " + tr("HUD_DAY") + " %d" % job.deadline_day
		header_label.text = "T%d %s | %s | %s" % [job.tier, tr(job.data.title_key), NumberFormat.format_credits(job.payout), due]
	header_label.tooltip_text = header_label.text

	var draw: float = job.total_power_draw()
	var limit: float = job.data.power_limit_watts
	var over: bool = limit > 0.0 and draw > limit and not job.data.is_champion_build
	var bits: Array[String] = []
	bits.append("%s %s / %s" % [tr("WORKSHOP_MATERIALS"), NumberFormat.format_credits(job.materials_spent), NumberFormat.format_credits(job.budget_cap)])
	if limit > 0.0 and not job.data.is_champion_build:
		bits.append(("! " if over else "") + "%s %d / %d W" % [tr("WORKSHOP_POWER"), roundi(draw), roundi(limit)])
	if job.has_finished_part():
		bits.append("%s %d%%" % [tr("WORKSHOP_QUALITY"), roundi(job.calculate_quality() * 100.0)])
	stats_label.text = "  |  ".join(bits)
	stats_label.tooltip_text = stats_label.text
	stats_label.add_theme_color_override("font_color", GamePalette.NEGATIVE if over else GamePalette.ACCENT)

func _on_part_pressed(part_index: int) -> void:
	part_clicked.emit(_job, part_index)

func _on_sim_pressed(part_index: int) -> void:
	sim_clicked.emit(_job, part_index)

func _on_reforge_pressed(part_index: int) -> void:
	reforge_clicked.emit(part_index)
