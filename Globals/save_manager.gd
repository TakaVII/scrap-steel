# purpose: [v2] Production JSON save manager persisting state to user://savegame.json every morning.
# depends on: EconomyManager, TimeManager, GameManager, CommissionManager, UpgradeManager, SettingsManager
# signals emitted: none
# signals listened to: none

extends Node

const SAVE_PATH: String = "user://savegame.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func autosave() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return false

	var active_contracts_data: Array[Dictionary] = []
	for contract in CommissionManager.active_contracts:
		active_contracts_data.append({
			"id": contract.data.id,
			"tier": contract.tier,
			"barter": contract.barter,
			"accepted_day": contract.accepted_day,
			"deadline_day": contract.deadline_day,
			"budget_cap": contract.budget_cap,
			"payout": contract.payout,
			"materials_spent": contract.materials_spent,
			"part_scores": contract.part_scores,
			"part_power": contract.part_power,
			"delivered": contract.delivered,
			"late_days": contract.late_days
		})

	var data: Dictionary = {
		"day": TimeManager.day,
		"credits": EconomyManager.credits,
		"debt": EconomyManager.debt,
		"strikes": EconomyManager.strikes,
		"tech_points": EconomyManager.tech_points,
		"pathway": String(GameManager.pathway),
		"debt_cleared_day": GameManager.debt_cleared_day,
		"upgrades": UpgradeManager.purchased_upgrades,
		"active_contracts": active_contracts_data,
		"delivered_qualities": CommissionManager.delivered_qualities,
		"champion_completed": CommissionManager.champion_completed,
		"champion_registration_paid": CommissionManager.champion_registration_paid,
		"settings": {
			"colorblind": SettingsManager.colorblind_mode,
			"slow_mode": SettingsManager.slow_mode,
			"assist_skip": SettingsManager.assist_skip_minigames,
			"input_toggle": SettingsManager.input_mode_toggle
		}
	}

	var json_str: String = JSON.stringify(data)
	file.store_string(json_str)
	file.close()
	return true

func load_save() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false

	var json_str: String = file.get_as_text()
	file.close()

	var test_json := JSON.new()
	if test_json.parse(json_str) != OK:
		return false

	var data: Dictionary = test_json.data
	TimeManager.day = int(data.get("day", 1)) - 1
	EconomyManager.credits = int(data.get("credits", 2000))
	EconomyManager.debt = int(data.get("debt", 10000))
	EconomyManager.strikes = int(data.get("strikes", 0))
	EconomyManager.tech_points = int(data.get("tech_points", 0))
	GameManager.pathway = StringName(data.get("pathway", "mech"))
	GameManager.debt_cleared_day = int(data.get("debt_cleared_day", 0))
	CommissionManager.set_pathway(GameManager.pathway)
	CommissionManager.champion_completed = bool(data.get("champion_completed", false))
	CommissionManager.champion_registration_paid = bool(data.get("champion_registration_paid", false))

	UpgradeManager.purchased_upgrades.clear()
	for upg in data.get("upgrades", []):
		UpgradeManager.purchased_upgrades.append(StringName(upg))

	CommissionManager.delivered_qualities.clear()
	for q in data.get("delivered_qualities", []):
		CommissionManager.delivered_qualities.append(float(q))

	var settings_dict: Dictionary = data.get("settings", {})
	SettingsManager.colorblind_mode = bool(settings_dict.get("colorblind", false))
	SettingsManager.slow_mode = bool(settings_dict.get("slow_mode", false))
	SettingsManager.assist_skip_minigames = bool(settings_dict.get("assist_skip", false))
	SettingsManager.input_mode_toggle = bool(settings_dict.get("input_toggle", false))

	GameManager.enter_morning()
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
