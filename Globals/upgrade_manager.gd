# purpose: [STUB Phase 1] R&D upgrade manager stub returning zero bonuses until full implementation in Phase 4.
# depends on: Node, EventBus
# signals emitted: none
# signals listened to: none

extends Node

var purchased_upgrades: Array[StringName] = []

func new_run() -> void:
	purchased_upgrades.clear()

func bonus_ap() -> int:
	return 0

func score_bonus() -> float:
	return 0.0

func has_upgrade(id: StringName) -> bool:
	return purchased_upgrades.has(id)
