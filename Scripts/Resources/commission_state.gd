# purpose: [v3] Runtime mutable state of a contract: progress, barter modifiers, part scores, material grades and part qualities, delivery. v2: deposit_paid and reforging_parts.
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
var part_scores: Array[float] = [] # -1.0 = pending, 0.0..1.0 = finished (raw minigame score)
var part_power: Array[float] = []
## MaterialGrade.Grade used for each finished part (-1 = pending).
var part_grades: Array[int] = []
## Part quality after the grade (0.5..1.0, -1.0 = pending). The contract quality is their mean.
var part_quality: Array[float] = []
var materials_spent: int = 0
var delivered: bool = false
var late_days: int = 0
## Advance deposit already received (Barter A). Subtracted from the cash paid at delivery.
var deposit_paid: int = 0
## Barter: this client's number for the chosen term (profit-share multiplier at quality 90%+).
var term_param: float = 0.0
## Barter (supplied parts): material cost multiplier for this contract.
var cost_mult: float = 1.0
## Champion Build only: part indexes being re-forged (the redo costs a fraction of the material cost).
var reforging_parts: Array[int] = []

func add_part_slot(part: ItemPartData) -> void:
	parts.append(part)
	part_scores.append(-1.0)
	part_power.append(0.0)
	part_grades.append(-1)
	part_quality.append(-1.0)

func is_complete() -> bool:
	if parts.is_empty():
		return false
	for score in part_scores:
		if score < 0.0:
			return false
	return true

func has_finished_part() -> bool:
	for score in part_scores:
		if score >= 0.0:
			return true
	return false

func average_score() -> float:
	var total: float = 0.0
	var count: int = 0
	for s in part_scores:
		if s >= 0.0:
			total += s
			count += 1
	return (total / count) if count > 0 else 0.0

## Mean of the part qualities (grade included). Falls back to the old score-based formula for old saves / dev-sim parts.
func calculate_quality() -> float:
	var total: float = 0.0
	var count: int = 0
	for q in part_quality:
		if q >= 0.0:
			total += q
			count += 1
	if count == 0:
		return 0.50 + 0.50 * average_score()
	return total / count

## Share of finished parts built with Scrap material (raises the warranty-claim chance).
func scrap_ratio() -> float:
	var scrap: int = 0
	for g in part_grades:
		if g == MaterialGrade.Grade.SCRAP:
			scrap += 1
	return float(scrap) / float(maxi(1, parts.size()))

func total_power_draw() -> float:
	var sum_w: float = 0.0
	for w in part_power:
		sum_w += w
	return sum_w
