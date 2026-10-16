# purpose: Minimal settings manager for Phase 1, supplying minigame difficulty parameters and assist flags.
# depends on: Node, EventBus
# signals emitted: none
# signals listened to: none

extends Node

var colorblind_mode: bool = false
var slow_mode: bool = false
var assist_skip_minigames: bool = false
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0

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
		"assist_skip": assist_skip_minigames
	}
