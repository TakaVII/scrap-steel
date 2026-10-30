# purpose: [v5] Mounts minigames under CanvasLayer 50. Checks AP/funds/budget BEFORE spending AP. v5: takes the material grade (Premium = faster/shorter minigame, Scrap = slower/longer) and the tier-based AP cost. The F5 cheat only works in debug builds.
# depends on: EventBus, GameManager, TimeManager, SettingsManager, UpgradeManager, CraftingManager, DebugCheats, MaterialGrade, ItemPartData, PartResult, CommissionState
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

## Returns false (no AP spent) if the part cannot be started.
func launch(commission: CommissionState, part_index: int, grade: int = MaterialGrade.Grade.STANDARD) -> bool:
	if GameManager.phase != GameManager.Phase.WORKSHOP:
		return false
	if CraftingManager.can_start(commission, part_index, grade) != &"":
		return false
	var part: ItemPartData = commission.parts[part_index]
	if not TimeManager.spend_ap(CraftingManager.part_ap(commission, part_index)):
		return false

	GameManager.begin_minigame()
	_job = {"commission": commission, "part_index": part_index, "part": part, "tier": commission.tier, "grade": grade}

	var difficulty: Dictionary = SettingsManager.minigame_difficulty(commission.tier)
	# Material grade: Premium is harder (faster cursor / less time), Scrap is easier. The minigames read speed_mult and window_mult.
	difficulty["speed_mult"] = float(difficulty.get("speed_mult", 1.0)) * MaterialGrade.speed_mult(grade)
	difficulty["window_mult"] = float(difficulty.get("window_mult", 1.0)) * MaterialGrade.window_mult(grade)
	if difficulty.get("assist_skip", false):
		_complete(0.70)
		return true

	var packed: PackedScene = load(SCENES.get(part.minigame_type, "")) as PackedScene
	if not packed:
		push_warning("MinigameController: scene missing for part %s, auto-completing at 0.70" % part.part_id)
		_complete(0.70)
		return true

	var game: MinigameBase = packed.instantiate() as MinigameBase
	_layer.add_child(game)
	game.setup(difficulty)
	game.finished.connect(_on_finished.bind(game), CONNECT_ONE_SHOT)
	EventBus.minigame_started.emit(part, commission.tier)
	game.start()
	# Live workpiece in the corner of the panel (reads the minigame state; harmless if art is missing).
	var stage := PartStage.new()
	_layer.add_child(stage)
	stage.attach(game, part, grade)
	return true

func _on_finished(score: float, game: MinigameBase) -> void:
	game.queue_free()
	_complete(score)

func _complete(score: float) -> void:
	var result := PartResult.new()
	result.commission = _job.get("commission")
	result.part_index = _job.get("part_index", 0)
	result.part = _job.get("part")
	result.grade = int(_job.get("grade", MaterialGrade.Grade.STANDARD))
	var cheat: bool = OS.is_debug_build() and DebugCheats.force_perfect_score
	var raw: float = 1.0 if cheat else score
	result.score = clampf(raw + UpgradeManager.score_bonus(), 0.0, 1.0)
	CraftingManager.apply_result(result)
	EventBus.minigame_finished.emit(result)
