# purpose: [v3 manual fix] JSON autosave (user://savegame.json) every morning with FULL restore: contracts, offers, warranty claims, qualities, upgrades, AP. Continue no longer re-charges rent/installments.
# depends on: EconomyManager, TimeManager, GameManager, CommissionManager, UpgradeManager, EventBus, Balance
# signals emitted: none
# signals listened to: none

extends Node

const SAVE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 2 # v1 saves lacked contracts/claims and are ignored

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func autosave() -> bool:
	var upgrades: Array = []
	for u in UpgradeManager.purchased_upgrades:
		upgrades.append(String(u))
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"day": TimeManager.day,
		"ap": TimeManager.ap,
		"ap_max": TimeManager.ap_max,
		"overtime_last_night": TimeManager.was_overtime_last_night(),
		"credits": EconomyManager.credits,
		"debt": EconomyManager.debt,
		"strikes": EconomyManager.strikes,
		"tech_points": EconomyManager.tech_points,
		"interest_rate": EconomyManager.interest_rate,
		"pathway": String(GameManager.pathway),
		"debt_cleared_day": GameManager.debt_cleared_day,
		"upgrades": upgrades,
		"commission": CommissionManager.serialize()
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true

func load_save() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var json := JSON.new()
	var parse_err: Error = json.parse(file.get_as_text())
	file.close()
	if parse_err != OK or typeof(json.data) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = json.data
	if int(d.get("version", 1)) < SAVE_VERSION:
		return false

	EconomyManager.new_run(Balance.cfg)
	TimeManager.new_run()
	UpgradeManager.new_run()

	EconomyManager.credits = int(d.get("credits", 0))
	EconomyManager.debt = int(d.get("debt", 0))
	EconomyManager.strikes = int(d.get("strikes", 0))
	EconomyManager.tech_points = int(d.get("tech_points", 0))
	EconomyManager.interest_rate = float(d.get("interest_rate", Balance.cfg.daily_interest_rate))
	GameManager.pathway = StringName(d.get("pathway", "mech"))
	GameManager.debt_cleared_day = int(d.get("debt_cleared_day", 0))
	for upg in d.get("upgrades", []):
		UpgradeManager.purchased_upgrades.append(StringName(upg))

	CommissionManager.restore(d.get("commission", {}))
	# Day/AP last so day_started reaches the HUD after the upgrades exist.
	TimeManager.restore(int(d.get("day", 1)), int(d.get("ap", Balance.cfg.base_ap)),
			int(d.get("ap_max", Balance.cfg.base_ap)), bool(d.get("overtime_last_night", false)))

	EventBus.credits_changed.emit(EconomyManager.credits, 0)
	EventBus.debt_changed.emit(EconomyManager.debt, 0)
	EventBus.tech_points_changed.emit(EconomyManager.tech_points)
	GameManager.resume_from_save()
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
