# purpose: Main menu UI controller managing new game startup and continue states.
# depends on: Control, GameManager, SaveManager
# signals emitted: none
# signals listened to: none

extends Control

@onready var continue_button: Button = %ContinueButton

func _ready() -> void:
	continue_button.disabled = not SaveManager.has_save()

func _on_new_game_button_pressed() -> void:
	GameManager.start_new_run()

func _on_continue_button_pressed() -> void:
	if SaveManager.has_save():
		SaveManager.load_save()
