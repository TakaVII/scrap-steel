# purpose: Material grades (Scrap / Standard / Premium) chosen per part before its minigame. All numbers come from Balance.cfg (Materials group).
# depends on: RefCounted, Balance
# signals emitted: none
# signals listened to: none

class_name MaterialGrade
extends RefCounted

enum Grade { SCRAP, STANDARD, PREMIUM }

const NAME_KEYS: Array[String] = ["GRADE_SCRAP", "GRADE_STANDARD", "GRADE_PREMIUM"]

static func _i(grade: int) -> int:
	return clampi(grade, 0, 2)

static func name_key(grade: int) -> String:
	return NAME_KEYS[_i(grade)]

static func cost_mult(grade: int) -> float:
	return Balance.cfg.grade_cost_mult[_i(grade)]

static func speed_mult(grade: int) -> float:
	return Balance.cfg.grade_speed_mult[_i(grade)]

static func window_mult(grade: int) -> float:
	return Balance.cfg.grade_window_mult[_i(grade)]

## Part quality (0.5 .. 1.0) after the grade: Scrap is capped, Premium gets a bonus. The grade never changes the payout directly, only through quality.
static func adjust_quality(grade: int, quality: float) -> float:
	if grade == Grade.SCRAP:
		return minf(quality, Balance.cfg.scrap_quality_cap)
	if grade == Grade.PREMIUM:
		return minf(1.0, quality + Balance.cfg.premium_quality_bonus)
	return quality
