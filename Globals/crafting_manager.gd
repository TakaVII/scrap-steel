# purpose: [v3 manual fix] Crafting: start-checks (AP, funds, budget cap) and material charging with Supplier/Forge discounts. Champion Build parts split the 7,000 cr by AP. Never lets credits go negative.
# depends on: Balance, EventBus, EconomyManager, TimeManager, UpgradeManager, ItemPartData, PartResult, CommissionState
# signals emitted: none
# signals listened to: none

extends Node

## Nominal cost before any discount. Champion Build: the whole build totals champion_build_cost_materials, split by AP.
func nominal_part_cost(commission: CommissionState, part_index: int) -> int:
	var part: ItemPartData = commission.parts[part_index]
	if commission.data.is_champion_build:
		var total_ap: int = 0
		for p in commission.parts:
			total_ap += p.ap_cost
		return roundi(float(Balance.cfg.champion_build_cost_materials) * float(part.ap_cost) / float(maxi(1, total_ap)))
	return part.nominal_material_cost(commission.tier)

## Worst-case charge (Forge savings depend on the score, so they are not assumed).
func max_part_cost(commission: CommissionState, part_index: int) -> int:
	var cost: float = float(nominal_part_cost(commission, part_index))
	if UpgradeManager.has_upgrade(&"supplier_network"):
		cost *= 0.90
	if commission.reforging_parts.has(part_index):
		cost *= Balance.cfg.champion_reforge_cost_fraction
	return roundi(cost)

## Returns &"" when the part can be started, otherwise a reason: &"done", &"no_ap", &"no_funds", &"over_budget".
func can_start(commission: CommissionState, part_index: int) -> StringName:
	if commission.part_scores[part_index] >= 0.0:
		return &"done"
	var part: ItemPartData = commission.parts[part_index]
	if not TimeManager.has_ap(part.ap_cost):
		return &"no_ap"
	var cost: int = max_part_cost(commission, part_index)
	if cost > EconomyManager.credits:
		return &"no_funds"
	if cost > commission.budget_cap - commission.materials_spent:
		return &"over_budget"
	return &""

func apply_result(result: PartResult) -> void:
	var commission: CommissionState = result.commission
	var part: ItemPartData = result.part
	var idx: int = result.part_index

	var final_cost: float = float(nominal_part_cost(commission, idx))
	if UpgradeManager.has_upgrade(&"supplier_network"):
		final_cost *= 0.90
	if part.minigame_type == ItemPartData.MinigameType.FORGE:
		final_cost *= (1.0 - Balance.cfg.forge_waste_reduction * result.score)
	if commission.reforging_parts.has(idx):
		final_cost *= Balance.cfg.champion_reforge_cost_fraction
		commission.reforging_parts.erase(idx)

	# Never negative credits: charge at most what the player has (can_start already checked the worst case).
	var charged: int = mini(roundi(final_cost), EconomyManager.credits)
	if charged > 0:
		EconomyManager.try_spend(charged, tr("LEDGER_MATERIALS") + ": " + tr(part.display_key), &"materials")
	result.material_cost_charged = charged
	commission.materials_spent += charged

	# Deterministic power draw (spec C4)
	var draw: float = part.base_power_watts
	if part.minigame_type == ItemPartData.MinigameType.CALIBRATE:
		draw = part.base_power_watts * (1.30 - 0.40 * result.score)
	result.power_watts = draw
	commission.part_scores[idx] = result.score
	commission.part_power[idx] = draw
