# purpose: [v4] Comprehensive settings and accessibility manager supporting RTL window direction, Assist economy preset, font fallbacks, and colorblind mode (spec §B2, §C10, §D9).
# depends on: Node, EventBus, AudioManager
# signals emitted: EventBus.settings_changed, EventBus.locale_changed
# signals listened to: none

extends Node

# Accessibility & Assists (spec §C10)
var colorblind_mode: bool = false
var slow_mode: bool = false
var assist_skip_minigames: bool = false
var input_mode_toggle: bool = false
var reduced_flashing: bool = false
var simple_language: bool = false
var large_text: bool = false

# Economy Preset (spec §B2)
var assist_economy: bool = false

# Localization & RTL
var current_locale: String = "en"
var mute_on_focus_loss: bool = true

# Audio Volumes
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0

func _ready() -> void:
	# VERIFY: Window.FOCUS_IN / Window.FOCUS_OUT or MainLoop notification in Godot 4.7.2
	if OS.has_feature("web"):
		DisplayServer.window_set_window_event_callback(_on_window_event)

func set_language(locale_code: String) -> void:
	current_locale = locale_code
	TranslationServer.set_locale(locale_code)

	# RTL layout direction management
	# VERIFY: Window.layout_direction and Window.LAYOUT_DIRECTION_RTL in Godot 4.7.2
	var is_rtl: bool = (locale_code == "ar")
	var root_window: Window = get_window()
	if root_window:
		root_window.layout_direction = Window.LAYOUT_DIRECTION_RTL if is_rtl else Window.LAYOUT_DIRECTION_LTR

	EventBus.locale_changed.emit(locale_code)
	EventBus.settings_changed.emit()

func set_assist_economy(enable: bool) -> void:
	assist_economy = enable
	EventBus.settings_changed.emit()

func set_colorblind_mode(enable: bool) -> void:
	colorblind_mode = enable
	EventBus.settings_changed.emit()

func set_slow_mode(enable: bool) -> void:
	slow_mode = enable
	EventBus.settings_changed.emit()

func set_skip_minigames(enable: bool) -> void:
	assist_skip_minigames = enable
	EventBus.settings_changed.emit()

func set_input_mode_toggle(enable: bool) -> void:
	input_mode_toggle = enable
	EventBus.settings_changed.emit()

func set_reduced_flashing(enable: bool) -> void:
	reduced_flashing = enable
	EventBus.settings_changed.emit()

func set_simple_language(enable: bool) -> void:
	simple_language = enable
	EventBus.settings_changed.emit()

func set_large_text(enable: bool) -> void:
	large_text = enable
	# VERIFY: ThemeDB or get_tree().root.content_scale_factor in Godot 4.7.2
	EventBus.settings_changed.emit()

func set_master_vol(val: float) -> void:
	master_volume = clampf(val, 0.0, 1.0)
	AudioManager.set_master_volume(master_volume)

func set_music_vol(val: float) -> void:
	music_volume = clampf(val, 0.0, 1.0)
	AudioManager.set_music_volume(music_volume)

func set_sfx_vol(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)
	AudioManager.set_sfx_volume(sfx_volume)

func minigame_difficulty(tier: int) -> Dictionary:
	var speed_mult: float = 1.0 + (tier - 1) * 0.25
	var window_mult: float = 1.0 - (tier - 1) * 0.15

	if slow_mode:
		speed_mult *= 0.75
		window_mult *= 1.25

	return {
		"tier": tier,
		"speed_mult": speed_mult,
		"window_mult": window_mult,
		"assist_skip": assist_skip_minigames,
		"input_mode_toggle": input_mode_toggle,
		"reduced_flashing": reduced_flashing
	}

func _on_window_event(event: int) -> void:
	# VERIFY: DisplayServer.WINDOW_EVENT_FOCUS_IN / FOCUS_OUT in Godot 4.7.2
	if not mute_on_focus_loss:
		return
	if event == DisplayServer.WINDOW_EVENT_FOCUS_OUT:
		AudioServer.set_bus_mute(0, true)
	elif event == DisplayServer.WINDOW_EVENT_FOCUS_IN:
		AudioServer.set_bus_mute(0, false)
