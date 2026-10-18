# purpose: [v5 manual fix] Settings + accessibility. Persists to user://settings.cfg, applies UI text size through the project Theme, RTL window direction, focus-mute via Window signals, and minigame difficulty (accessibility multipliers ONLY; tier scaling lives inside each minigame).
# depends on: Node, EventBus, AudioManager
# signals emitted: EventBus.settings_changed, EventBus.locale_changed
# signals listened to: Window.focus_entered, Window.focus_exited

extends Node

const SETTINGS_PATH: String = "user://settings.cfg"
const THEME_PATH: String = "res://Assets/Themes/default_theme.tres"
## Base UI text size for the 480x270 viewport. Tune here if your pixel font looks blurry (try its native multiples).
const FONT_SIZE_NORMAL: int = 8
const FONT_SIZE_LARGE: int = 10

var colorblind_mode: bool = false
var slow_mode: bool = false
var assist_skip_minigames: bool = false
var input_mode_toggle: bool = false
var reduced_flashing: bool = false
var simple_language: bool = false
var large_text: bool = false
var assist_economy: bool = false
var current_locale: String = "en"
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0
var mute_on_focus_loss: bool = true:
	set(value):
		mute_on_focus_loss = value
		_persist()

var _theme: Theme = null
var _loading: bool = true

func _ready() -> void:
	_load_settings()
	_loading = false
	_setup_theme()
	apply_text_size()
	set_language(current_locale)
	var win: Window = get_window()
	win.focus_exited.connect(_on_focus_changed.bind(false)) # VERIFY: Window.focus_exited fires on web tab blur
	win.focus_entered.connect(_on_focus_changed.bind(true))
	call_deferred("_apply_audio") # AudioManager creates its buses in its own _ready (later autoload)

func _setup_theme() -> void:
	if ResourceLoader.exists(THEME_PATH):
		_theme = load(THEME_PATH) as Theme
	if _theme:
		get_window().theme = _theme
	else:
		push_warning("SettingsManager: %s missing. Run Scripts/Tools/build_ui_theme.gd. Using fallback font size." % THEME_PATH)
		ThemeDB.fallback_font_size = FONT_SIZE_NORMAL # VERIFY: ThemeDB.fallback_font_size in 4.7.2

func apply_text_size() -> void:
	var size: int = FONT_SIZE_LARGE if large_text else FONT_SIZE_NORMAL
	if _theme:
		_theme.default_font_size = size
	else:
		ThemeDB.fallback_font_size = size

func _apply_audio() -> void:
	AudioManager.set_master_volume(master_volume)
	AudioManager.set_music_volume(music_volume)
	AudioManager.set_sfx_volume(sfx_volume)

func _on_focus_changed(focused: bool) -> void:
	if not mute_on_focus_loss:
		return
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not focused)

# ---------------------------------------------------------------- persistence

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	colorblind_mode = cfg.get_value("a11y", "colorblind", false)
	slow_mode = cfg.get_value("a11y", "slow_mode", false)
	assist_skip_minigames = cfg.get_value("a11y", "skip_minigames", false)
	input_mode_toggle = cfg.get_value("a11y", "input_toggle", false)
	reduced_flashing = cfg.get_value("a11y", "reduced_flashing", false)
	simple_language = cfg.get_value("a11y", "simple_language", false)
	large_text = cfg.get_value("a11y", "large_text", false)
	assist_economy = cfg.get_value("game", "assist_economy", false)
	current_locale = cfg.get_value("game", "locale", "en")
	master_volume = cfg.get_value("audio", "master", 1.0)
	music_volume = cfg.get_value("audio", "music", 1.0)
	sfx_volume = cfg.get_value("audio", "sfx", 1.0)
	mute_on_focus_loss = cfg.get_value("audio", "mute_on_focus_loss", true)

func _persist() -> void:
	if _loading:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("a11y", "colorblind", colorblind_mode)
	cfg.set_value("a11y", "slow_mode", slow_mode)
	cfg.set_value("a11y", "skip_minigames", assist_skip_minigames)
	cfg.set_value("a11y", "input_toggle", input_mode_toggle)
	cfg.set_value("a11y", "reduced_flashing", reduced_flashing)
	cfg.set_value("a11y", "simple_language", simple_language)
	cfg.set_value("a11y", "large_text", large_text)
	cfg.set_value("game", "assist_economy", assist_economy)
	cfg.set_value("game", "locale", current_locale)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "mute_on_focus_loss", mute_on_focus_loss)
	cfg.save(SETTINGS_PATH)

func _changed() -> void:
	_persist()
	EventBus.settings_changed.emit()

# ---------------------------------------------------------------- setters (called by settings_menu.gd)

func set_language(locale_code: String) -> void:
	current_locale = locale_code
	TranslationServer.set_locale(locale_code)
	# RTL follows the locale automatically (Window has no settable layout_direction in this build).
	# VERIFY: switch to Arabic and check that the HUD rows and Settings mirror.
	_persist()
	EventBus.locale_changed.emit(locale_code)
	EventBus.settings_changed.emit()

func set_assist_economy(enable: bool) -> void:
	assist_economy = enable # applies at the START of the next run only
	_changed()

func set_colorblind_mode(enable: bool) -> void:
	colorblind_mode = enable
	_changed()

func set_slow_mode(enable: bool) -> void:
	slow_mode = enable
	_changed()

func set_skip_minigames(enable: bool) -> void:
	assist_skip_minigames = enable
	_changed()

func set_input_mode_toggle(enable: bool) -> void:
	input_mode_toggle = enable
	_changed()

func set_reduced_flashing(enable: bool) -> void:
	reduced_flashing = enable
	_changed()

func set_simple_language(enable: bool) -> void:
	simple_language = enable
	_changed()

func set_large_text(enable: bool) -> void:
	large_text = enable
	apply_text_size()
	_changed()

func set_master_vol(val: float) -> void:
	master_volume = clampf(val, 0.0, 1.0)
	AudioManager.set_master_volume(master_volume)
	_persist()

func set_music_vol(val: float) -> void:
	music_volume = clampf(val, 0.0, 1.0)
	AudioManager.set_music_volume(music_volume)
	_persist()

func set_sfx_vol(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)
	AudioManager.set_sfx_volume(sfx_volume)
	_persist()

## Accessibility multipliers ONLY. Tier scaling (spec C9) is applied inside each minigame.
## Before this fix tier scaling was applied twice (Forge T3 ran at 2.25x speed instead of 1.5x).
func minigame_difficulty(tier: int) -> Dictionary:
	return {
		"tier": tier,
		"speed_mult": 0.75 if slow_mode else 1.0,
		"window_mult": 1.25 if slow_mode else 1.0,
		"assist_skip": assist_skip_minigames,
		"input_mode_toggle": input_mode_toggle,
		"reduced_flashing": reduced_flashing
	}
