# purpose: Manages the 30-day campaign calendar, action points (AP), and overtime mechanics.
# depends on: Balance (Balance.cfg), UpgradeManager, EconomyManager, EventBus
# signals emitted: EventBus.action_points_changed, day_started
# signals listened to: none

extends Node

var day: int = 0
var ap: int = 0
var ap_max: int = 6
var _fatigue_next_day: int = 0
var _overtime_last_night: bool = false
var _overtime_tonight: bool = false

func new_run() -> void:
	day = 0
	ap = 0
	_fatigue_next_day = 0
	_overtime_last_night = false
	_overtime_tonight = false

func begin_day() -> void:
	day += 1
	ap_max = Balance.cfg.base_ap + UpgradeManager.bonus_ap()
	ap = maxi(1, ap_max - _fatigue_next_day)
	_fatigue_next_day = 0
	_overtime_last_night = _overtime_tonight
	_overtime_tonight = false
	EventBus.action_points_changed.emit(ap, ap_max)
	EventBus.day_started.emit(day)

func has_ap(amount: int) -> bool:
	return ap >= amount

func spend_ap(amount: int) -> bool:
	if ap < amount:
		return false
	ap -= amount
	EventBus.action_points_changed.emit(ap, ap_max)
	return true

func can_take_overtime() -> bool:
	return not _overtime_last_night and not _overtime_tonight and EconomyManager.credits >= Balance.cfg.overtime_cost

func take_overtime() -> bool:
	if not can_take_overtime():
		return false
	if not EconomyManager.try_spend(Balance.cfg.overtime_cost, tr("LEDGER_OVERTIME"), &"overtime"):
		return false
	ap += Balance.cfg.overtime_ap
	_overtime_tonight = true
	_fatigue_next_day = Balance.cfg.overtime_next_day_ap_penalty
	EventBus.action_points_changed.emit(ap, ap_max)
	return true
