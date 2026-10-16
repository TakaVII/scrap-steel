# purpose: [STUB Phase 1] Minigame controller stub that bypasses canvas mini-games and returns simulated results.
# depends on: Node, EventBus
# signals emitted: none
# signals listened to: none

extends Node

func launch_simulated(score: float = 0.75) -> void:
	var dummy_result := RefCounted.new()
	EventBus.minigame_finished.emit(dummy_result)
