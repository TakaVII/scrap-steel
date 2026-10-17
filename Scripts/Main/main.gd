# purpose: [v4] Phase router managing SettingsMenu modal display alongside screens and CrtOverlay (spec §D7, §C10).
# depends on: Node, GameManager, EventBus
# signals emitted: none
# signals listened to: EventBus.phase_changed

extends Node

@onready var hud: Control = %HUD
@onready var main_menu: Control = %MainMenu
@onready var morning_screen: Control = %MorningScreen
@onready var workshop_screen: Control = %WorkshopScreen
@onready var night_summary: Control = %NightSummary
@onready var pathway_select: Control = %PathwaySelect
@onready var end_screen: Control = %EndScreen
@onready var crt_overlay: ColorRect = %CrtOverlay
@onready var settings_menu: Control = %SettingsMenu

func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	if main_menu.has_signal("open_settings_requested"):
		main_menu.open_settings_requested.connect(_on_open_settings)
	if settings_menu.has_signal("closed"):
		settings_menu.closed.connect(_on_settings_closed)

	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_views(GameManager.phase)

func _on_open_settings() -> void:
	settings_menu.visible = true

func _on_settings_closed() -> void:
	settings_menu.visible = false

func _on_phase_changed(new_phase: int, _old_phase: int) -> void:
	_update_views(new_phase)

func _update_views(current_phase: int) -> void:
	main_menu.visible = (current_phase == GameManager.Phase.MENU)
	pathway_select.visible = (current_phase == GameManager.Phase.TUTORIAL)
	morning_screen.visible = (current_phase == GameManager.Phase.MORNING)
	workshop_screen.visible = (current_phase == GameManager.Phase.WORKSHOP)
	night_summary.visible = (current_phase == GameManager.Phase.NIGHT)
	end_screen.visible = (current_phase == GameManager.Phase.VICTORY or current_phase == GameManager.Phase.GAME_OVER)

	var in_menu: bool = (current_phase == GameManager.Phase.MENU or current_phase == GameManager.Phase.TUTORIAL)
	hud.visible = not in_menu and not end_screen.visible
