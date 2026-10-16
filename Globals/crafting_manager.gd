# purpose: Crafting and parts execution manager deducting material costs with Forge and Supplier discounts.
# depends on: Balance, EventBus, EconomyManager, UpgradeManager, ItemPartData, PartResult
# signals emitted: none
# signals listened to: none

extends Node

func apply_result(result: PartResult) -> void:
	var commission = result.commission
	var part = result.part
	var idx = result.part_index

	# Calculate nominal material cost for part
	var nominal_cost: int = part.nominal_material_cost(commission.tier)
	var final_cost: float = float(nominal_cost)

	# 1. Supplier Network R&D upgrade (-10% material cost)
	if UpgradeManager.has_upgrade(&"supplier_network"):
		final_cost *= 0.90

	# 2. Forge scrap waste reduction (up to -30% based on score)
	if part.minigame_type == ItemPartData.MinigameType.FORGE:
		final_cost *= (1.0 - Balance.cfg.forge_waste_reduction * result.score)

	var charged_mat: int = int(round(final_cost))
	result.material_cost_charged = charged_mat

	# Deduct material cost through EconomyManager
	if not EconomyManager.try_spend(charged_mat, tr("LEDGER_MATERIALS") + ": " + tr(part.display_key), &"materials"):
		# If broke, roll into debt shortfall
		EconomyManager.add_credits(-charged_mat, tr("LEDGER_MATERIALS") + " (Debt Funded)", &"materials")

	commission.materials_spent += charged_mat

	# Calculate power draw (deterministic rule from spec §C4)
	var draw: float = part.base_power_watts
	if part.minigame_type == ItemPartData.MinigameType.CALIBRATE:
		draw = part.base_power_watts * (1.30 - 0.40 * result.score)

	result.power_watts = draw
	commission.part_scores[idx] = result.score
	commission.part_power[idx] = draw
