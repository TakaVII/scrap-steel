# purpose: [v2] Debug cheat keys available in debug builds for rapid economy, progression, and telemetry testing.
# depends on: EconomyManager, TimeManager, GameManager, EventBus, Telemetry
# signals emitted: none
# signals listened to: none
extends Node

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() and not OS.has_feature("editor"):
		return
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
	var key_event: InputEventKey = event as InputEventKey
	match key_event.keycode:
		KEY_F1:
			EconomyManager.add_credits(1000, "Debug cheat +1000 credits", &"income")
			print("CHEAT: +1000 Credits added. Current balance: ", EconomyManager.credits)
		KEY_F2:
			print("CHEAT: Skipping current day directly to Night Summary.")
			if GameManager.phase == GameManager.Phase.WORKSHOP:
				GameManager.request_end_day()
			elif GameManager.phase == GameManager.Phase.MORNING:
				GameManager.begin_workshop()
				GameManager.request_end_day()
		KEY_F3:
			TimeManager.ap = mini(TimeManager.ap + 4, 12)
			EventBus.action_points_changed.emit(TimeManager.ap, TimeManager.ap_max)
			print("CHEAT: +4 AP granted. Current AP: ", TimeManager.ap)
		KEY_F4:
			EconomyManager.add_tech_points(3)
			print("CHEAT: +3 Tech Points granted. Current TP: ", EconomyManager.tech_points)
		KEY_F6:
			print("CHEAT STATE DUMP -> Day: ", TimeManager.day, " | Credits: ", EconomyManager.credits, " | Debt: ", EconomyManager.debt, " | Strikes: ", EconomyManager.strikes)
		KEY_F7:
			TimeManager.day = 27
			print("CHEAT: Jumped to Day 27.")
		KEY_F9:
			Telemetry.print_telemetry_debug()
