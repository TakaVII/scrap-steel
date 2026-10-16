# purpose: Runtime mutable state tracking active progress, barter modifiers, part scores, and delivery of a contract.
# depends on: RefCounted, CommissionData, ItemPartData
# signals emitted: none
# signals listened to: none

class_name CommissionState
extends RefCounted

var data: CommissionData
var parts: Array[ItemPartData] = []
var tier: int = 1
var barter: int = CommissionData.Barter.NONE # CommissionData.Barter
var accepted_day: int = 0
var deadline_day: int = 0
var budget_cap: int = 0
var payout: int = 0
var part_scores: Array[float] = [] # -1.0 = pending, 0.0..1.0 = finished
var part_power: Array[float] = []
var materials_spent: int = 0
var delivered: bool = false
var late_days: int = 0

func is_complete() -> bool:
	if parts.is_empty():
		return false
	for score in part_scores:
		if score < 0.0:
			return false
	return true

func average_score() -> float:
	var total: float = 0.0
	var count: int = 0
	for s in part_scores:
		if s >= 0.0:
			total += s
			count += 1
	return (total / count) if count > 0 else 0.0

func calculate_quality() -> float:
	return 0.50 + 0.50 * average_score()

func total_power_draw() -> float:
	var sum_w: float = 0.0
	for w in part_power:
		sum_w += w
	return sum_w
