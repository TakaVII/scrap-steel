# purpose: [v3] ALL story dialogue as data. A sequence is an Array of BEATS. Edit lines here (structure) and in translations.csv (text, keys TUT_*, DLG_*, TIP_*, DAX_*, INST_*, D12_*). See Docs/dialogue_guide.md.
# Beat types: _say (a spoken line), _pause (silent beat), _choice (the player picks a reply; optional loop = topic menu), _act (side effect).
# depends on: RefCounted, Balance, EconomyManager, NumberFormat
# signals emitted: none
# signals listened to: none

class_name StoryData
extends RefCounted

# ---------------------------------------------------------------- beat builders

## A spoken line. who: &"narrator", &"player", or a ClientRoster id (&"mara", &"kane"...). act: &"show_hud" etc. (read by pathway_select via line_shown).
## extra keys you can add to the dictionary afterwards: "fx" (&"shake"), "cps" (typing speed), "auto" (seconds to auto-continue).
static func _say(who: StringName, key: String, vars: Dictionary = {}, mood: StringName = &"neutral", act: StringName = &"") -> Dictionary:
	return {"type": "say", "who": who, "key": key, "vars": vars, "mood": mood, "act": act}

## Silent beat: the box waits `sec` seconds (a click skips it). Gives scenes rhythm.
static func _pause(sec: float) -> Dictionary:
	return {"type": "pause", "sec": sec}

## One reply option. `then` = the lines that follow the reply. exit = true ends a looping menu.
static func _opt(key: String, then: Array = [], exit: bool = false) -> Dictionary:
	return {"key": key, "then": then, "exit": exit}

## The player chooses a reply. The chosen text is spoken by the player, then its `then` lines play.
## loop = true: after the reply the menu comes back without the used option, until an exit option is picked (or only the exit is left).
static func _choice(options: Array, loop: bool = false) -> Dictionary:
	return {"type": "choice", "options": options, "loop": loop}

## Side effect without a line: name = a sound in Assets/Audio (sfx_<name>.ogg) or &"shake".
static func _act(what: StringName, name: String = "") -> Dictionary:
	return {"type": "act", "what": what, "name": name}

# ---------------------------------------------------------------- shared values

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

# ---------------------------------------------------------------- scenes

static func sequence(id: StringName) -> Array:
	var v: Dictionary = vars()
	match id:
		# ---- Tutorial scene 1: the garage at night
		&"prologue":
			return [
				_say(&"narrator", "TUT_P1"),
				_say(&"narrator", "TUT_P2"),
				_pause(0.5),
				_say(&"narrator", "TUT_P3"),
				_pause(0.4),
				_say(&"narrator", "TUT_P4"),
			]
		# ---- Tutorial scene 2: Mara walks in (conversation, then the guided forge job)
		&"job_intro":
			return [
				_say(&"mara", "DLG_J1"),
				_choice([
					_opt("DLG_J1_OPT_A", [_say(&"mara", "DLG_J1_A", {}, &"happy")]),
					_opt("DLG_J1_OPT_B", [_say(&"mara", "DLG_J1_B")]),
				]),
				_say(&"mara", "DLG_J2"),
				_say(&"narrator", "TUT_J2"),
				_say(&"narrator", "TUT_J3"),
			]
		# ---- Tutorial scene 3: Kane. Debt, interest and the first installment are said to you; strikes and rent are topics you ask about.
		&"kane_intro":
			return [
				_say(&"narrator", "TUT_K1"),
				_pause(0.4),
				_say(&"kane", "TUT_K2"),
				_choice([
					_opt("DLG_K_OPT_A", [_say(&"kane", "DLG_K_A", {}, &"unhappy")]),
					_opt("DLG_K_OPT_B", [_say(&"kane", "DLG_K_B")]),
				]),
				_say(&"kane", "TUT_K3", v, &"neutral", &"show_hud"),
				_say(&"kane", "TUT_K4", v),
				_say(&"kane", "TUT_K5", v),
				_choice([
					_opt("DLG_Q_STRIKE", [_say(&"kane", "TUT_K6", v)]),
					_opt("DLG_Q_RENT", [_say(&"kane", "TUT_K7", v)]),
					_opt("DLG_Q_DONE", [], true),
				], true),
				_say(&"kane", "TUT_K8", v),
			]
		&"path_reputation":
			return [_say(&"kane", "TUT_PATH_REP")]
		&"path_mech":
			return [_say(&"kane", "TUT_PATH_MECH")]
		&"path_drifter":
			return [_say(&"kane", "TUT_PATH_DRIFT")]
		# ---- In-game beats (story_director.gd)
		&"day1":
			return [_say(&"narrator", "TIP_D1_1"), _say(&"narrator", "TIP_D1_2")]
		&"first_delivery":
			return [_say(&"narrator", "TIP_FIRST")]
		&"dax_1":
			return [_say(&"narrator", "DAX_1")]
		&"dax_2":
			return [_say(&"narrator", "DAX_2")]
		&"dax_3":
			return [_say(&"narrator", "DAX_3")]
		&"installment_ok":
			return [_say(&"kane", "INST_OK", v)]
		&"installment_short":
			return [_say(&"kane", "INST_SHORT", v, &"unhappy")]
		&"chapter_1":
			return [_say(&"narrator", "CH1_DONE")]
		&"personal":
			return [_say(&"kane", "PERSONAL", v)]
		&"day12_reputation":
			return [_say(&"seraph", "D12_REP", v), _say(&"narrator", "D12_COMMON", v)]
		&"day12_mech":
			return [_say(&"ironhead", "D12_MECH", v), _say(&"narrator", "D12_COMMON", v)]
		&"day12_drifter":
			return [_say(&"gideon", "D12_DRIFT", v), _say(&"narrator", "D12_COMMON", v)]
	return []

## Mara's reaction to the tutorial forge job, by score.
static func job_done_sequence(score: float) -> Array:
	var key: String = "TUT_J4L"
	var mood: StringName = &"unhappy"
	if score >= 0.70:
		key = "TUT_J4G"
		mood = &"happy"
	elif score >= 0.40:
		key = "TUT_J4O"
		mood = &"neutral"
	return [
		_say(&"mara", key, {}, mood),
		_say(&"narrator", "TUT_J5"),
		_pause(0.3),
		_say(&"mara", "DLG_J6", {}, &"happy"),
	]
