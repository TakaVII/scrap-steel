# purpose: ONE place for the ESC key. Closes the top-most popup (settings, pause menu, ledger, barter), and when nothing is open and a run is in progress, opens the pause menu. Runs in PROCESS_MODE_ALWAYS so it still receives ESC while the tree is paused. The grade picker and the dialogue box keep handling ESC themselves (they consume the event first).
# depends on: Node, GameManager, PauseMenu, SettingsMenu, LedgerPanel, MorningScreen/BarterPanel
# signals emitted: SettingsMenu.closed, BarterPanel.cancelled (same signals their own close buttons emit)
# signals listened to: none

extends Node

@onready var pause_menu: Control = %PauseMenu
@onready var settings_menu: Control = %SettingsMenu
@onready var ledger_panel: Control = %LedgerPanel
@onready var morning_screen: Control = %MorningScreen

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if not (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		return
	if _close_top_popup():
		get_viewport().set_input_as_handled()
		return
	if _run_in_progress():
		pause_menu.open()
		get_viewport().set_input_as_handled()

## Closes the highest popup that is open. Returns true if one was closed.
func _close_top_popup() -> bool:
	if settings_menu.visible:
		settings_menu.visible = false
		settings_menu.closed.emit()
		return true
	if pause_menu.visible:
		pause_menu.close()
		return true
	if ledger_panel.visible:
		ledger_panel.visible = false
		return true
	var barter: Control = morning_screen.get_node_or_null("BarterPanel") as Control
	if barter != null and barter.visible:
		barter.visible = false
		barter.cancelled.emit() # same as the "Walk away" button
		return true
	return false

func _run_in_progress() -> bool:
	var p: int = GameManager.phase
	return p != GameManager.Phase.MENU and p != GameManager.Phase.GAME_OVER and p != GameManager.Phase.VICTORY
