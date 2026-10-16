# purpose: [STUB Phase 1] Commission manager providing fake offers and simulated part completion for Phase 1 testing.
# depends on: Node, EventBus, EconomyManager, TimeManager
# signals emitted: none
# signals listened to: none

extends Node

var current_offers_count: int = 4
var active_jobs_count: int = 1

func new_run() -> void:
	current_offers_count = 4
	active_jobs_count = 1

func set_pathway(_p: StringName) -> void:
	pass

func generate_offers(_day: int) -> void:
	current_offers_count = 4

func resolve_evening(_day: int) -> void:
	pass

func pathway_objective_met() -> bool:
	# Default stub for testing: true if debt is 0
	return EconomyManager.debt == 0

## Phase 1 simulated part completion triggered by workshop test button
func simulate_part_completion(ap_cost: int = 2) -> void:
	if not TimeManager.spend_ap(ap_cost):
		return
	var fake_score: float = 0.75
	var gross_pay: int = int(ap_cost * 350.0 * (0.5 + 0.5 * fake_score))
	var mat_cost: int = int(gross_pay * 0.50)
	if EconomyManager.try_spend(mat_cost, tr("LEDGER_MATERIALS"), &"materials"):
		EconomyManager.add_credits(gross_pay, tr("LEDGER_COMMISSION_PAYOUT"), &"income")
		if fake_score >= 0.75:
			EconomyManager.add_tech_points(1)
