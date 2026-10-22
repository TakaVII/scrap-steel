# purpose: [v2] Base class for all skill minigames: lifecycle hooks, the finished(score) signal, and shared game-feel helpers: show_result_popup() (rating word + resulting quality) and finish_with_delay() (lets the player SEE the result before the minigame closes).
# depends on: Control, Juice, GamePalette
# signals emitted: finished(score: float)
# signals listened to: none

class_name MinigameBase
extends Control

signal finished(score: float)

const RESULT_DELAY_SEC: float = 0.75
const POPUP_FONT_SIZE: int = 16

var difficulty: Dictionary = {}
var is_active: bool = false

func setup(diff: Dictionary) -> void:
	difficulty = diff

func start() -> void:
	is_active = true

func _finish(score: float) -> void:
	if not is_active:
		return
	is_active = false
	finished.emit(clampf(score, 0.0, 1.0))

## Stops the game now, shows the result, and emits finished after `delay` seconds.
func finish_with_delay(score: float, delay: float = RESULT_DELAY_SEC) -> void:
	if not is_active:
		return
	is_active = false
	show_result_popup(score)
	await get_tree().create_timer(delay).timeout
	finished.emit(clampf(score, 0.0, 1.0))

## Floating rating word + part quality (quality = 50% + 50% x score, spec C4).
func show_result_popup(score: float) -> void:
	var key: String = "MG_RESULT_POOR"
	var color: Color = GamePalette.NEGATIVE
	if score >= 0.90:
		key = "MG_RESULT_PERFECT"
		color = GamePalette.NEON_CYAN
	elif score >= 0.75:
		key = "MG_RESULT_GREAT"
		color = GamePalette.POSITIVE
	elif score >= 0.50:
		key = "MG_RESULT_OK"
		color = GamePalette.ACCENT
	var text: String = "%s  %d%%" % [tr(key), roundi((0.5 + 0.5 * score) * 100.0)]
	Juice.spawn_floating_text(self, text, Vector2(size.x * 0.5 - 60.0, size.y * 0.5 - 12.0), color, POPUP_FONT_SIZE)
