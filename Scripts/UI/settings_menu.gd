# purpose: Settings and accessibility menu modal implementing all spec §C10 features, RTL language switching, and Assist economy toggle.
# depends on: Control, SettingsManager, AudioManager, EventBus
# signals emitted: closed()
# signals listened to: none

extends Control

signal closed()

@onready var locale_option: OptionButton = %LocaleOption
@onready var assist_economy_check: CheckBox = %AssistEconomyCheck
@onready var colorblind_check: CheckBox = %ColorblindCheck
@onready var slow_mode_check: CheckBox = %SlowModeCheck
@onready var skip_minigames_check: CheckBox = %SkipMinigamesCheck
@onready var input_mode_check: CheckBox = %InputModeCheck
@onready var reduced_flashing_check: CheckBox = %ReducedFlashingCheck
@onready var simple_language_check: CheckBox = %SimpleLanguageCheck
@onready var large_text_check: CheckBox = %LargeTextCheck
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var mute_focus_check: CheckBox = %MuteFocusCheck
@onready var title_label: Label = %TitleLabel
@onready var back_button: Button = %BackButton

func _ready() -> void:
	_populate_locales()
	_sync_ui_from_settings()

func _populate_locales() -> void:
	locale_option.clear()
	locale_option.add_item("English (EN)", 0)
	locale_option.add_item("Español (ES)", 1)
	locale_option.add_item("العربية (AR - RTL)", 2)

	match SettingsManager.current_locale:
		"es": locale_option.selected = 1
		"ar": locale_option.selected = 2
		_: locale_option.selected = 0

func _sync_ui_from_settings() -> void:
	assist_economy_check.button_pressed = SettingsManager.assist_economy
	colorblind_check.button_pressed = SettingsManager.colorblind_mode
	slow_mode_check.button_pressed = SettingsManager.slow_mode
	skip_minigames_check.button_pressed = SettingsManager.assist_skip_minigames
	input_mode_check.button_pressed = SettingsManager.input_mode_toggle
	reduced_flashing_check.button_pressed = SettingsManager.reduced_flashing
	simple_language_check.button_pressed = SettingsManager.simple_language
	large_text_check.button_pressed = SettingsManager.large_text
	mute_focus_check.button_pressed = SettingsManager.mute_on_focus_loss

	master_slider.value = SettingsManager.master_volume
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume

func _on_locale_option_item_selected(index: int) -> void:
	match index:
		0: SettingsManager.set_language("en")
		1: SettingsManager.set_language("es")
		2: SettingsManager.set_language("ar")

func _on_assist_economy_check_toggled(button_pressed: bool) -> void:
	SettingsManager.set_assist_economy(button_pressed)

func _on_colorblind_check_toggled(button_pressed: bool) -> void:
	SettingsManager.set_colorblind_mode(button_pressed)

func _on_slow_mode_check_toggled(button_pressed: bool) -> void:
	SettingsManager.set_slow_mode(button_pressed)

func _on_skip_minigames_check_toggled(button_pressed: bool) -> void:
	SettingsManager.set_skip_minigames(button_pressed)

func _on_input_mode_check_toggled(button_pressed: bool) -> void:
	SettingsManager.set_input_mode_toggle(button_pressed)

func _on_reduced_flashing_check_toggled(button_pressed: bool) -> void:
	SettingsManager.set_reduced_flashing(button_pressed)

func _on_simple_language_check_toggled(button_pressed: bool) -> void:
	SettingsManager.set_simple_language(button_pressed)

func _on_large_text_check_toggled(button_pressed: bool) -> void:
	SettingsManager.set_large_text(button_pressed)

func _on_mute_focus_check_toggled(button_pressed: bool) -> void:
	SettingsManager.mute_on_focus_loss = button_pressed

func _on_master_slider_value_changed(value: float) -> void:
	SettingsManager.set_master_vol(value)

func _on_music_slider_value_changed(value: float) -> void:
	SettingsManager.set_music_vol(value)

func _on_sfx_slider_value_changed(value: float) -> void:
	SettingsManager.set_sfx_vol(value)

func _on_back_button_pressed() -> void:
	visible = false
	closed.emit()
