# purpose: All story dialogue as data. Each sequence is an Array of lines {who, key, vars, mood, act}. Text lives in translations.csv (keys TUT_*, TIP_*, DAX_*, INST_*, D12_*); {placeholders} are filled here from the live run (debt, interest, rent...), never hardcoded.
# depends on: RefCounted, Balance, EconomyManager, NumberFormat
# signals emitted: none
# signals listened to: none

class_name StoryData
extends RefCounted

static func _line(who: StringName, key: String, vars: Dictionary = {}, mood: StringName = &"neutral", act: StringName = &"") -> Dictionary:
	return {"who": who, "key": key, "vars": vars, "mood": mood, "act": act}

## Values shared by many lines. Read at play time so the Assist preset shows its own numbers.
static func vars() -> Dictionary:
	var first_due_day: int = 0
	if not Balance.cfg.installment_days.is_empty():
		first_due_day = Balance.cfg.installment_days[0]
	return {
		"debt": NumberFormat.format_credits(EconomyManager.debt),
		"rate": str(roundi(EconomyManager.interest_rate * 100.0)),
		"interest": NumberFormat.format_credits(EconomyManager.projected_interest()),
		"due": NumberFormat.format_credits(EconomyManager.next_installment_amount()),
		"due_day": str(first_due_day),
		"rent": NumberFormat.format_credits(Balance.cfg.daily_rent),
		"limit": NumberFormat.format_credits(Balance.cfg.seize_debt_threshold),
		"strikes": str(EconomyManager.strikes),
		"max_strikes": str(Balance.cfg.max_strikes),
		"reserve": NumberFormat.format_credits(Balance.cfg.reserve_target),
		"cost": NumberFormat.format_credits(Balance.cfg.champion_build_cost_materials),
		"fee": NumberFormat.format_credits(Balance.cfg.champion_build_sponsorship),
		"quality": str(roundi(Balance.cfg.champion_min_quality * 100.0)),
		"unlock": str(Balance.cfg.champion_unlock_day),
		"deadline": str(Balance.cfg.champion_deadline_day),
	}

static func sequence(id: StringName) -> Array:
	var v: Dictionary = vars()
	match id:
		&"prologue":
			return [
				_line(&"narrator", "TUT_P1"),
				_line(&"narrator", "TUT_P2"),
				_line(&"narrator", "TUT_P3"),
				_line(&"narrator", "TUT_P4"),
			]
		&"job_intro":
			return [
				_line(&"mara", "TUT_J1"),
				_line(&"narrator", "TUT_J2"),
				_line(&"narrator", "TUT_J3"),
			]
		&"kane_intro":
			return [
				_line(&"narrator", "TUT_K1"),
				_line(&"kane", "TUT_K2"),
				_line(&"kane", "TUT_K3", v, &"neutral", &"show_hud"),
				_line(&"kane", "TUT_K4", v),
				_line(&"kane", "TUT_K5", v),
				_line(&"kane", "TUT_K6", v),
				_line(&"narrator", "TUT_K7", v),
				_line(&"kane", "TUT_K8", v),
			]
		&"path_reputation":
			return [_line(&"kane", "TUT_PATH_REP")]
		&"path_mech":
			return [_line(&"kane", "TUT_PATH_MECH")]
		&"path_drifter":
			return [_line(&"kane", "TUT_PATH_DRIFT")]
		&"day1":
			return [_line(&"narrator", "TIP_D1_1"), _line(&"narrator", "TIP_D1_2")]
		&"first_delivery":
			return [_line(&"narrator", "TIP_FIRST")]
		&"dax_1":
			return [_line(&"narrator", "DAX_1")]
		&"dax_2":
			return [_line(&"narrator", "DAX_2")]
		&"dax_3":
			return [_line(&"narrator", "DAX_3")]
		&"installment_ok":
			return [_line(&"kane", "INST_OK", v)]
		&"installment_short":
			return [_line(&"kane", "INST_SHORT", v, &"unhappy")]
		&"chapter_1":
			return [_line(&"narrator", "CH1_DONE")]
		&"personal":
			return [_line(&"kane", "PERSONAL", v)]
		&"day12_reputation":
			return [_line(&"seraph", "D12_REP", v), _line(&"narrator", "D12_COMMON", v)]
		&"day12_mech":
			return [_line(&"ironhead", "D12_MECH", v), _line(&"narrator", "D12_COMMON", v)]
		&"day12_drifter":
			return [_line(&"gideon", "D12_DRIFT", v), _line(&"narrator", "D12_COMMON", v)]
	return []

## Reaction to the tutorial forge job, by score.
static func job_done_sequence(score: float) -> Array:
	var key: String = "TUT_J4L"
	var mood: StringName = &"unhappy"
	if score >= 0.70:
		key = "TUT_J4G"
		mood = &"happy"
	elif score >= 0.40:
		key = "TUT_J4O"
		mood = &"neutral"
	return [_line(&"mara", key, {}, mood), _line(&"narrator", "TUT_J5")]
