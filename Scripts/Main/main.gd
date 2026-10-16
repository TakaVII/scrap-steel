# purpose: Phase router script that binds to EventBus.phase_changed to display the active UI screen.
# depends on: Control, EventBus, GameManager
# signals emitted: none
# signals listened to: EventBus.phase_changed

extends Control

@onready var hud: Control = %HUD
@onready var main_menu: Control = %MainMenu
@onready var morning_screen: Control = %MorningScreen
@onready var workshop_screen: Control = %WorkshopScreen
@onready var night_summary: Control = %NightSummary
@onready var end_screen: Control = %EndScreen
@onready var ledger_panel: Control = %LedgerPanel

func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	_hide_all_screens()
	main_menu.visible = true
	hud.visible = false
	ledger_panel.visible = false

func _hide_all_screens() -> void:
	main_menu.visible = false
	morning_screen.visible = false
	workshop_screen.visible = false
	night_summary.visible = false
	end_screen.visible = false

func _on_phase_changed(new_phase: int, _old_phase: int) -> void:
	_hide_all_screens()
	match new_phase:
		GameManager.Phase.MENU:
			main_menu.visible = true
			hud.visible = false
		GameManager.Phase.MORNING:
			hud.visible = true
			morning_screen.visible = true
		GameManager.Phase.WORKSHOP:
			hud.visible = true
			workshop_screen.visible = true
		GameManager.Phase.NIGHT:
			hud.visible = true
			night_summary.visible = true
		GameManager.Phase.GAME_OVER, GameManager.Phase.VICTORY:
			hud.visible = true
			end_screen.visible = true
