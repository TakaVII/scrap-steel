# purpose: [v7] Phase router. v7: (1) the whole UI is forced LEFT-TO-RIGHT (Arabic text still shapes right-to-left inside labels, but the layout no longer mirrors: rows, grids and columns stay as in English/Spanish); (2) the pause menu can open the settings menu, and the settings menu runs while the tree is paused. v6: every screen is kept BELOW the HUD (the HUD bar's real height becomes each screen's top margin). v5: Ledger opens with quick_ledger (L); the tutorial can show the HUD.
# depends on: Node, GameManager, EventBus
# signals emitted: none
# signals listened to: EventBus.phase_changed, PathwaySelect.hud_requested, MainMenu.open_settings_requested, PauseMenu.settings_requested, SettingsMenu.closed, HUD/Margin.minimum_size_changed

extends Node

const HUD_GAP_PX: int = 2
const HUD_FALLBACK_PX: int = 30

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
@onready var pause_menu: Control = %PauseMenu
@onready var story_dialogue: Control = %StoryDialogue
@onready var menu_backdrop: Control = %MenuBackdrop

func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	if main_menu.has_signal("open_settings_requested"):
		main_menu.open_settings_requested.connect(_on_open_settings)
	if settings_menu.has_signal("closed"):
		settings_menu.closed.connect(_on_settings_closed)
	if pathway_select.has_signal("hud_requested"):
		pathway_select.hud_requested.connect(_on_tutorial_hud_requested)
	if pause_menu.has_signal("settings_requested"):
		pause_menu.settings_requested.connect(_on_open_settings)

	# The settings menu must keep working while the pause menu has paused the tree.
	settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	_force_left_to_right()

	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ledger_panel.visible = false
	var bar: Control = hud.get_node_or_null("Margin") as Control
	if bar != null:
		bar.minimum_size_changed.connect(_sync_hud_inset)
	_update_views(GameManager.phase)
	_sync_hud_inset.call_deferred()

## Arabic keeps its shaped, right-to-left TEXT, but the layout stays as in English. Each top-level screen is forced
## to LTR (children inherit it); the Window property is also set when it exists in this build.
## VERIFY: Window.layout_direction / Control.layout_direction in the 4.7.2 class reference.
func _force_left_to_right() -> void:
	var roots: Array[Control] = [hud, main_menu, morning_screen, workshop_screen, night_summary, pathway_select,
			end_screen, settings_menu, ledger_panel, pause_menu, story_dialogue]
	for c in roots:
		c.layout_direction = Control.LAYOUT_DIRECTION_LTR
	get_window().set("layout_direction", Control.LAYOUT_DIRECTION_LTR)

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
	_sync_hud_inset()

func _update_views(current_phase: int) -> void:
	main_menu.visible = (current_phase == GameManager.Phase.MENU)
	menu_backdrop.visible = (current_phase == GameManager.Phase.MENU)
	pathway_select.visible = (current_phase == GameManager.Phase.TUTORIAL)
	morning_screen.visible = (current_phase == GameManager.Phase.MORNING)
	workshop_screen.visible = (current_phase == GameManager.Phase.WORKSHOP)
	night_summary.visible = (current_phase == GameManager.Phase.NIGHT)
	end_screen.visible = (current_phase == GameManager.Phase.VICTORY or current_phase == GameManager.Phase.GAME_OVER)

	var in_menu: bool = (current_phase == GameManager.Phase.MENU or current_phase == GameManager.Phase.TUTORIAL)
	hud.visible = not in_menu and not end_screen.visible
	if in_menu or end_screen.visible:
		ledger_panel.visible = false

## Gives each screen's content margin the real height of the HUD bar, so no button can hide under it.
func _sync_hud_inset() -> void:
	var bar: Control = hud.get_node_or_null("Margin") as Control
	var height: int = HUD_FALLBACK_PX
	if bar != null:
		height = ceili(maxf(bar.size.y, bar.get_combined_minimum_size().y))
	var inset: int = height + HUD_GAP_PX
	# [screen, name of the MarginContainer that holds its content]
	var targets: Array = [
		[morning_screen, "Margin"],
		[workshop_screen, "MarginContainer"],
		[night_summary, "Margin"],
		[pathway_select, "PathwayPanel"],
	]
	for t in targets:
		var screen: Control = t[0] as Control
		var holder: Control = screen.get_node_or_null(String(t[1])) as Control
		if holder != null:
			holder.add_theme_constant_override("margin_top", inset)
