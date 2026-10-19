# purpose: [v5] Phase router. v5: the Ledger opens with the quick_ledger action (L), and the tutorial can show the HUD while it explains debt (spec D7, C10).
# depends on: Node, GameManager, EventBus
# signals emitted: none
# signals listened to: EventBus.phase_changed, PathwaySelect.hud_requested, MainMenu.open_settings_requested, SettingsMenu.closed

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
@onready var ledger_panel: Control = %LedgerPanel

func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	if main_menu.has_signal("open_settings_requested"):
		main_menu.open_settings_requested.connect(_on_open_settings)
	if settings_menu.has_signal("closed"):
		settings_menu.closed.connect(_on_settings_closed)
	if pathway_select.has_signal("hud_requested"):
		pathway_select.hud_requested.connect(_on_tutorial_hud_requested)

	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ledger_panel.visible = false
	_update_views(GameManager.phase)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quick_ledger") and not event.is_echo():
		var p: int = GameManager.phase
		if p == GameManager.Phase.MENU or p == GameManager.Phase.TUTORIAL or p == GameManager.Phase.MINIGAME:
			return
		ledger_panel.visible = not ledger_panel.visible
		get_viewport().set_input_as_handled()

func _on_open_settings() -> void:
	settings_menu.visible = true

func _on_settings_closed() -> void:
	settings_menu.visible = false

func _on_tutorial_hud_requested(show_hud: bool) -> void:
	if GameManager.phase == GameManager.Phase.TUTORIAL:
		hud.visible = show_hud

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
	if in_menu or end_screen.visible:
		ledger_panel.visible = false
