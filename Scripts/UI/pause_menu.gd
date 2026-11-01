# purpose: In-game pause menu (Resume, Settings, Return to Main Menu, Quit). Opened with ESC / P by PopupCloser (Scripts/Main/popup_closer.gd). Pauses the scene tree while open; this node and the settings menu run in PROCESS_MODE_ALWAYS so they stay usable. Quit is hidden in web builds (a browser tab cannot be closed by the game). "Return to Main Menu" is disabled during a minigame (finish the part first); progress is autosaved every morning.
# depends on: Control, GameManager
# signals emitted: settings_requested()
# signals listened to: button presses (connected in pause_menu.tscn)

extends Control

signal settings_requested()

@onready var hint_label: Label = %HintLabel
@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	quit_button.visible = not OS.has_feature("web")

func open() -> void:
	var in_minigame: bool = GameManager.phase == GameManager.Phase.MINIGAME
	main_menu_button.disabled = in_minigame
	hint_label.text = tr("PAUSE_HINT_MINIGAME") if in_minigame else tr("PAUSE_HINT")
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()

func close() -> void:
	visible = false
	get_tree().paused = false

func _on_resume_button_pressed() -> void:
	close()

func _on_settings_button_pressed() -> void:
	settings_requested.emit()

func _on_main_menu_button_pressed() -> void:
	close()
	GameManager.return_to_menu()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
