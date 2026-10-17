# purpose: [v2] Production minigame controller mounting scenes under CanvasLayer 50, locking day progression, and routing results through CraftingManager.
# depends on: EventBus, GameManager, TimeManager, SettingsManager, UpgradeManager, CraftingManager, ItemPartData, PartResult, CommissionState
# signals emitted: EventBus.minigame_started, EventBus.minigame_finished
# signals listened to: none

extends Node

const SCENES: Dictionary = {
	ItemPartData.MinigameType.FORGE: "res://Scenes/Minigames/forge.tscn",
	ItemPartData.MinigameType.CALIBRATE: "res://Scenes/Minigames/calibrator.tscn",
	ItemPartData.MinigameType.ASSEMBLE: "res://Scenes/Minigames/assembler.tscn",
}

var _layer: CanvasLayer
var _job: Dictionary = {}

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 50
	add_child(_layer)

## Returns false (no AP spent) if player cannot afford part AP
func launch(commission: CommissionState, part_index: int) -> bool:
	var part: ItemPartData = commission.parts[part_index]
	if not TimeManager.spend_ap(part.ap_cost):
		return false

	GameManager.begin_minigame()
	_job = {
		"commission": commission,
		"part_index": part_index,
		"part": part,
		"tier": commission.tier
	}

	var difficulty: Dictionary = SettingsManager.minigame_difficulty(commission.tier)
	if difficulty.get("assist_skip", false):
		_complete(0.70)
		return true

	var scene_path: String = SCENES.get(part.minigame_type, "res://Scenes/Minigames/calibrator.tscn")
	var packed: PackedScene = load(scene_path) as PackedScene
	if not packed:
		_complete(0.70)
		return true

	var game: MinigameBase = packed.instantiate() as MinigameBase
	_layer.add_child(game)
	game.setup(difficulty)
	game.finished.connect(_on_finished.bind(game), CONNECT_ONE_SHOT)
	EventBus.minigame_started.emit(part, commission.tier)
	game.start()
	return true

func _on_finished(score: float, game: MinigameBase) -> void:
	game.queue_free()
	_complete(score)

func _complete(score: float) -> void:
	var result := PartResult.new()
	result.commission = _job.get("commission")
	result.part_index = _job.get("part_index", 0)
	result.part = _job.get("part")
	var effective_score: float = clampf(score + UpgradeManager.score_bonus(), 0.0, 1.0)
	result.score = effective_score
	CraftingManager.apply_result(result)
	EventBus.minigame_finished.emit(result)
