# purpose: [v2] Tutorial (spec C2 beats 0-1): prologue -> guided first forge job with Mara -> Collector Kane explains debt, interest, installments and strikes (HUD shown) -> choose pathway -> Kane reacts -> run starts. Replays from the start every time it is shown. Skip button jumps to the pathway choice.
# depends on: Control, DialogueBox, StoryData, NumberFormat, GameManager, Balance, SettingsManager, MinigameBase
# signals emitted: hud_requested(show: bool)
# signals listened to: DialogueBox.sequence_finished, DialogueBox.line_shown

extends Control

signal hud_requested(show: bool)

enum Step { PROLOGUE, JOB_INTRO, JOB, JOB_DONE, KANE, CHOOSE, PICKED }

const FORGE_SCENE: String = "res://Scenes/Minigames/forge.tscn"
const TUTORIAL_FORGE_SPEED: float = 0.75
const TUTORIAL_FORGE_WINDOW: float = 1.3
const RESULT_PAUSE_SEC: float = 0.1 # the Forge already waits to show its result

@onready var scene_art: TextureRect = %SceneArt
@onready var minigame_host: Control = %MinigameHost
@onready var pathway_panel: Control = %PathwayPanel
@onready var dialogue: Control = %Dialogue
@onready var skip_button: Button = %SkipButton
@onready var rep_button: Button = %RepButton
@onready var mech_button: Button = %MechButton
@onready var drifter_button: Button = %DrifterButton
@onready var desc_rep: Label = %DescRep
@onready var desc_mech: Label = %DescMech
@onready var desc_drifter: Label = %DescDrifter

var _step: Step = Step.PROLOGUE
var _active: bool = false
var _skipping: bool = false
var _forge: MinigameBase
var _job_score: float = 0.0
var _picked: StringName = &""

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	dialogue.sequence_finished.connect(_on_sequence_finished)
	dialogue.line_shown.connect(_on_line_shown)
	skip_button.pressed.connect(_on_skip_pressed)
	rep_button.pressed.connect(_on_pick.bind(&"reputation"))
	mech_button.pressed.connect(_on_pick.bind(&"mech"))
	drifter_button.pressed.connect(_on_pick.bind(&"drifter"))
	var bg: Texture2D = SpriteKit.tex(SpriteKit.BG + "workshop_bg.png")
	scene_art.texture = bg
	scene_art.visible = bg != null
	_on_visibility_changed()

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		if not _active:
			_start()
	else:
		_active = false
		_cleanup_forge()

func _start() -> void:
	_active = true
	_skipping = false
	_cleanup_forge()
	pathway_panel.visible = false
	skip_button.visible = true
	_set_cards_disabled(false)
	hud_requested.emit(false)
	_play(Step.PROLOGUE)

func _play(step: Step) -> void:
	_step = step
	match step:
		Step.PROLOGUE:
			dialogue.play(&"prologue", StoryData.sequence(&"prologue"))
		Step.JOB_INTRO:
			dialogue.play(&"job_intro", StoryData.sequence(&"job_intro"))
		Step.JOB:
			_start_forge()
		Step.JOB_DONE:
			dialogue.play(&"job_done", StoryData.job_done_sequence(_job_score))
		Step.KANE:
			dialogue.play(&"kane_intro", StoryData.sequence(&"kane_intro"))
		Step.CHOOSE:
			_show_choose()
		Step.PICKED:
			dialogue.play(StringName("path_" + String(_picked)), StoryData.sequence(StringName("path_" + String(_picked))))

func _on_sequence_finished(_seq_id: StringName) -> void:
	if not _active or _skipping:
		return
	match _step:
		Step.PROLOGUE:
			_play(Step.JOB_INTRO)
		Step.JOB_INTRO:
			_play(Step.JOB)
		Step.JOB_DONE:
			_play(Step.KANE)
		Step.KANE:
			_play(Step.CHOOSE)
		Step.PICKED:
			_active = false
			GameManager.choose_pathway(_picked)

func _on_line_shown(_index: int, line: Dictionary) -> void:
	if StringName(line.get("act", "")) == &"show_hud":
		hud_requested.emit(true)

# ---------------------------------------------------------------- guided forge job

func _start_forge() -> void:
	var packed: PackedScene = load(FORGE_SCENE) as PackedScene
	if packed == null:
		_job_score = 0.7
		_play(Step.JOB_DONE)
		return
	_forge = packed.instantiate() as MinigameBase
	minigame_host.add_child(_forge)
	_forge.setup({
		"tier": 1,
		"speed_mult": TUTORIAL_FORGE_SPEED,
		"window_mult": TUTORIAL_FORGE_WINDOW,
		"assist_skip": false,
		"input_mode_toggle": false,
		"reduced_flashing": SettingsManager.reduced_flashing,
	})
	_forge.finished.connect(_on_forge_finished, CONNECT_ONE_SHOT)
	_forge.start()

func _on_forge_finished(score: float) -> void:
	_job_score = score
	await get_tree().create_timer(RESULT_PAUSE_SEC).timeout
	if not _active or _skipping or _step != Step.JOB:
		return
	_cleanup_forge()
	_play(Step.JOB_DONE)

func _cleanup_forge() -> void:
	if is_instance_valid(_forge):
		_forge.queue_free()
	_forge = null

# ---------------------------------------------------------------- skip + pathway cards

func _on_skip_pressed() -> void:
	_skipping = true
	dialogue.skip_all()
	_cleanup_forge()
	_skipping = false
	_play(Step.CHOOSE)

func _show_choose() -> void:
	var v: Dictionary = StoryData.vars()
	desc_rep.text = NumberFormat.render(tr("PATH_REP_DESC"), v)
	desc_mech.text = NumberFormat.render(tr("PATH_MECH_DESC"), v)
	desc_drifter.text = NumberFormat.render(tr("PATH_DRIFT_DESC"), v)
	skip_button.visible = false
	pathway_panel.visible = true
	hud_requested.emit(true)

func _set_cards_disabled(disabled: bool) -> void:
	rep_button.disabled = disabled
	mech_button.disabled = disabled
	drifter_button.disabled = disabled

func _on_pick(path_id: StringName) -> void:
	_picked = path_id
	_set_cards_disabled(true)
	_play(Step.PICKED)
