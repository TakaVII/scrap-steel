# purpose: One part of a workshop contract: the part button plus the optional debug [Dev Sim] button and the Champion Build Re-forge button. Built from Scenes/UI/part_cell.tscn; replaces the code that used to build this cell inside workshop_screen.gd.
# depends on: VBoxContainer, CommissionState, ItemPartData, CraftingManager, CommissionManager
# signals emitted: part_pressed(part_index), sim_pressed(part_index), reforge_pressed(part_index)
# signals listened to: PartButton.part_selected, SimButton.pressed, ReforgeButton.pressed (connected in _ready)

class_name PartCell
extends VBoxContainer

signal part_pressed(part_index: int)
signal sim_pressed(part_index: int)
signal reforge_pressed(part_index: int)

@onready var part_button: Button = %PartButton
@onready var sim_button: Button = %SimButton
@onready var reforge_button: Button = %ReforgeButton

var _idx: int = 0

func _ready() -> void:
	part_button.part_selected.connect(_on_part_selected)
	sim_button.pressed.connect(_on_sim_pressed)
	reforge_button.pressed.connect(_on_reforge_pressed)

## Call AFTER add_child.
func setup(job: CommissionState, part_idx: int) -> void:
	_idx = part_idx
	var part: ItemPartData = job.parts[part_idx]
	var score: float = job.part_scores[part_idx]
	var grade: int = job.part_grades[part_idx] if part_idx < job.part_grades.size() else -1
	var quality: float = job.part_quality[part_idx] if part_idx < job.part_quality.size() else -1.0
	part_button.setup(part_idx, part, score, job.tier, CraftingManager.max_part_cost(job, part_idx), CraftingManager.part_ap(job, part_idx), grade, quality)
	sim_button.visible = score < 0.0 and OS.is_debug_build()
	reforge_button.visible = job.data.is_champion_build and CommissionManager.can_reforge_champion_part(part_idx)

func _on_part_selected(part_index: int) -> void:
	part_pressed.emit(part_index)

func _on_sim_pressed() -> void:
	sim_pressed.emit(_idx)

func _on_reforge_pressed() -> void:
	reforge_pressed.emit(_idx)
