# purpose: [STUB Phase 1] Save manager stub providing interface for daily autosaves and save state checks.
# depends on: Node
# signals emitted: none
# signals listened to: none

extends Node

func autosave() -> void:
	# In Phase 1, save state is logged in memory
	print("SaveManager: Autosave recorded for Day ", TimeManager.day)

func has_save() -> bool:
	return false

func load_save() -> bool:
	return false
