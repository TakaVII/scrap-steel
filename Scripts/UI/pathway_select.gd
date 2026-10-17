# purpose: Restructuring meeting and tutorial cards introducing debt, installments, and 3 career pathways.
# depends on: Control, GameManager, EventBus
# signals emitted: none
# signals listened to: none

extends Control

@onready var story_label: Label = %StoryLabel
@onready var next_step_button: Button = %NextStepButton
@onready var pathways_container: HBoxContainer = %PathwaysContainer
@onready var hud_callout_label: Label = %HudCalloutLabel

var _step: int = 0

func _ready() -> void:
	pathways_container.visible = false
	_show_step(0)

func _show_step(s: int) -> void:
	_step = s
	match s:
		0:
			story_label.text = tr("TUTORIAL_BEAT_0_TEXT")
			hud_callout_label.text = tr("TUTORIAL_BEAT_0_CALLOUT")
			next_step_button.text = tr("TUTORIAL_CONTINUE")
			pathways_container.visible = false
		1:
			story_label.text = tr("TUTORIAL_BEAT_1_TEXT")
			hud_callout_label.text = tr("TUTORIAL_BEAT_1_HUD_HINT")
			next_step_button.text = tr("TUTORIAL_PICK_PATHWAY")
			pathways_container.visible = false
		2:
			story_label.text = tr("TUTORIAL_BEAT_2_SELECT")
			hud_callout_label.text = tr("TUTORIAL_BEAT_2_HINT")
			next_step_button.visible = false
			pathways_container.visible = true

func _on_next_step_button_pressed() -> void:
	_show_step(_step + 1)

func _on_reputation_button_pressed() -> void:
	GameManager.choose_pathway(&"reputation")

func _on_mech_button_pressed() -> void:
	GameManager.choose_pathway(&"mech")

func _on_drifter_button_pressed() -> void:
	GameManager.choose_pathway(&"drifter")
