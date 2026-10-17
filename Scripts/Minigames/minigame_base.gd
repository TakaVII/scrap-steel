# purpose: Base class for all skill minigames providing lifecycle hooks and finished score signal.
# depends on: Control
# signals emitted: finished(score: float)
# signals listened to: none

class_name MinigameBase
extends Control

signal finished(score: float)

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
