# purpose: [v4 manual fix] Main menu. Continue button now refreshes every time the menu is shown (after a run ends it used to stay stale).
# depends on: Control, GameManager, SaveManager
# signals emitted: open_settings_requested()
# signals listened to: none

extends Control

signal open_settings_requested()

@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton

func _ready() -> void:
	visibility_changed.connect(_refresh_continue)
	_refresh_continue()

func _refresh_continue() -> void:
	if visible:
		continue_button.disabled = not SaveManager.has_save()

func _on_new_game_button_pressed() -> void:
	GameManager.start_new_run()

func _on_continue_button_pressed() -> void:
	if not SaveManager.load_save():
		continue_button.disabled = true

func _on_settings_button_pressed() -> void:
	open_settings_requested.emit()
