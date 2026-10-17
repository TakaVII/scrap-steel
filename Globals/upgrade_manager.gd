# purpose: [v2] Production R&D manager handling 5 upgrade cards, credit/TP purchases, and ROI calculations.
# depends on: Balance, EventBus, EconomyManager, UpgradeData
# signals emitted: EventBus.upgrade_purchased
# signals listened to: none

extends Node

var purchased_upgrades: Array[StringName] = []
var available_upgrades: Array[UpgradeData] = []

func _ready() -> void:
	_init_upgrades()

func new_run() -> void:
	purchased_upgrades.clear()

func _init_upgrades() -> void:
	available_upgrades.clear()

	var u1 := UpgradeData.new()
	u1.id = &"supplier_network"
	u1.title_key = "UPG_SUPPLIER_TITLE"
	u1.desc_key = "UPG_SUPPLIER_DESC"
	u1.cost_credits = 800
	u1.cost_tp = 2
	u1.payback_days = 6.6
	available_upgrades.append(u1)

	var u2 := UpgradeData.new()
	u2.id = &"warranty_insurance"
	u2.title_key = "UPG_WARRANTY_TITLE"
	u2.desc_key = "UPG_WARRANTY_DESC"
	u2.cost_credits = 600
	u2.cost_tp = 2
	u2.payback_days = 12.8
	available_upgrades.append(u2)

	var u3 := UpgradeData.new()
	u3.id = &"client_rolodex"
	u3.title_key = "UPG_ROLODEX_TITLE"
	u3.desc_key = "UPG_ROLODEX_DESC"
	u3.cost_credits = 1400
	u3.cost_tp = 3
	u3.payback_days = 11.8
	available_upgrades.append(u3)

	var u4 := UpgradeData.new()
	u4.id = &"second_bench"
	u4.title_key = "UPG_BENCH_TITLE"
	u4.desc_key = "UPG_BENCH_DESC"
	u4.cost_credits = 2500
	u4.cost_tp = 4
	u4.payback_days = 14.5
	available_upgrades.append(u4)

	var u5 := UpgradeData.new()
	u5.id = &"precision_tools"
	u5.title_key = "UPG_PRECISION_TITLE"
	u5.desc_key = "UPG_PRECISION_DESC"
	u5.cost_credits = 1500
	u5.cost_tp = 3
	u5.payback_days = 22.4
	available_upgrades.append(u5)

func can_purchase(upgrade_id: StringName) -> bool:
	if has_upgrade(upgrade_id):
		return false
	var upg := get_upgrade(upgrade_id)
	if not upg:
		return false
	return EconomyManager.credits >= upg.cost_credits and EconomyManager.tech_points >= upg.cost_tp

func purchase_upgrade(upgrade_id: StringName) -> bool:
	if not can_purchase(upgrade_id):
		return false
	var upg := get_upgrade(upgrade_id)
	if not EconomyManager.try_spend(upg.cost_credits, tr("NIGHT_UPGRADES") + ": " + tr(upg.title_key), &"upgrade"):
		return false
	EconomyManager.tech_points -= upg.cost_tp
	EventBus.tech_points_changed.emit(EconomyManager.tech_points)
	purchased_upgrades.append(upgrade_id)
	EventBus.upgrade_purchased.emit(upgrade_id)
	return true

func has_upgrade(id: StringName) -> bool:
	return purchased_upgrades.has(id)

func get_upgrade(id: StringName) -> UpgradeData:
	for u in available_upgrades:
		if u.id == id:
			return u
	return null

func bonus_ap() -> int:
	return 1 if has_upgrade(&"second_bench") else 0

func score_bonus() -> float:
	return 0.04 if has_upgrade(&"precision_tools") else 0.0
