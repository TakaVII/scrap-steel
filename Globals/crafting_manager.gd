# purpose: [v4] Crafting: start-checks (AP, funds, budget cap) and material charging. v4: material GRADE (Scrap/Standard/Premium) + daily market price + AP by tier. Champion Build parts split the 7,000 cr by AP, ignore the market and use their base AP. Never lets credits go negative.
# depends on: Balance, EventBus, EconomyManager, TimeManager, UpgradeManager, CommissionManager, MaterialGrade, ItemPartData, PartResult, CommissionState
# signals emitted: none
# signals listened to: none

extends Node

## AP the part costs inside this contract (tier based; Champion Build uses the base value).
func part_ap(commission: CommissionState, part_index: int) -> int:
	var part: ItemPartData = commission.parts[part_index]
	if commission.data.is_champion_build:
		return part.ap_cost
	return part.ap_for_tier(commission.tier)

## Nominal cost before market, grade and discounts. Champion Build: the whole build totals champion_build_cost_materials, split by AP.
func nominal_part_cost(commission: CommissionState, part_index: int) -> int:
	var part: ItemPartData = commission.parts[part_index]
	if commission.data.is_champion_build:
		var total_ap: int = 0
		for p in commission.parts:
			total_ap += p.ap_cost
		return roundi(float(Balance.cfg.champion_build_cost_materials) * float(part.ap_cost) / float(maxi(1, total_ap)))
	return part.nominal_material_cost(commission.tier)

func market_mult_for(commission: CommissionState) -> float:
	if commission.data.is_champion_build:
		return 1.0
	return CommissionManager.market_mult

## Cost of the part with the given grade. score < 0 = worst case (no Forge saving), score >= 0 = the final charge.
func part_cost(commission: CommissionState, part_index: int, grade: int, score: float = -1.0) -> int:
	var cost: float = float(nominal_part_cost(commission, part_index))
	cost *= market_mult_for(commission)
	cost *= MaterialGrade.cost_mult(grade)
	if UpgradeManager.has_upgrade(&"supplier_network"):
		cost *= 0.90
	if score >= 0.0 and commission.parts[part_index].minigame_type == ItemPartData.MinigameType.FORGE:
		cost *= (1.0 - Balance.cfg.forge_waste_reduction * score)
	if commission.reforging_parts.has(part_index):
		cost *= Balance.cfg.champion_reforge_cost_fraction
	return roundi(cost)

## Worst-case charge (Forge savings depend on the score, so they are not assumed).
func max_part_cost(commission: CommissionState, part_index: int, grade: int = MaterialGrade.Grade.STANDARD) -> int:
	return part_cost(commission, part_index, grade)

## Returns &"" when the part can be started, otherwise a reason: &"done", &"no_ap", &"no_funds", &"over_budget".
func can_start(commission: CommissionState, part_index: int, grade: int = MaterialGrade.Grade.STANDARD) -> StringName:
	if commission.part_scores[part_index] >= 0.0:
		return &"done"
	if not TimeManager.has_ap(part_ap(commission, part_index)):
		return &"no_ap"
	var cost: int = max_part_cost(commission, part_index, grade)
	if cost > EconomyManager.credits:
		return &"no_funds"
	if cost > commission.budget_cap - commission.materials_spent:
		return &"over_budget"
	return &""

func apply_result(result: PartResult) -> void:
	var commission: CommissionState = result.commission
	var part: ItemPartData = result.part
	var idx: int = result.part_index

	var final_cost: int = part_cost(commission, idx, result.grade, result.score)
	if commission.reforging_parts.has(idx):
		commission.reforging_parts.erase(idx)

	# Never negative credits: charge at most what the player has (can_start already checked the worst case).
	var charged: int = mini(final_cost, EconomyManager.credits)
	if charged > 0:
		EconomyManager.try_spend(charged, tr("LEDGER_MATERIALS") + ": " + tr(part.display_key), &"materials")
	result.material_cost_charged = charged
	commission.materials_spent += charged

	# Deterministic power draw (spec C4)
	var draw: float = part.base_power_watts
	if part.minigame_type == ItemPartData.MinigameType.CALIBRATE:
		draw = part.base_power_watts * (1.30 - 0.40 * result.score)
	result.power_watts = draw

	# Quality: raw score -> 0.5..1.0, then the material grade (Scrap capped, Premium bonus).
	result.quality = MaterialGrade.adjust_quality(result.grade, 0.50 + 0.50 * result.score)

	while commission.part_quality.size() <= idx:
		commission.part_quality.append(-1.0)
	while commission.part_grades.size() <= idx:
		commission.part_grades.append(-1)
	commission.part_scores[idx] = result.score
	commission.part_power[idx] = draw
	commission.part_quality[idx] = result.quality
	commission.part_grades[idx] = result.grade
