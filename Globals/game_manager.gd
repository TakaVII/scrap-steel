# purpose: [v3 manual fix] Game state router. Morning logic now runs BEFORE the MORNING phase is announced (UI used to render stale day/offers). Adds resume_from_save, return_to_menu, save deletion on run end.
# depends on: Balance, EventBus, EconomyManager, TimeManager, CommissionManager, UpgradeManager, SaveManager
# signals emitted: EventBus.phase_changed, run_ended, night_summary_ready
# signals listened to: EventBus.minigame_finished, EventBus.debt_changed

extends Node

enum Phase { MENU, TUTORIAL, MORNING, WORKSHOP, MINIGAME, EVENING, NIGHT, GAME_OVER, VICTORY }

var phase: Phase = Phase.MENU
var pathway: StringName = &"mech"
var debt_cleared_day: int = 0

func _ready() -> void:
	EventBus.minigame_finished.connect(func(_r: RefCounted) -> void:
		if phase == Phase.MINIGAME:
			_set_phase(Phase.WORKSHOP)
	)
	EventBus.debt_changed.connect(_on_debt_changed)

func _on_debt_changed(new_debt: int, _delta: int) -> void:
	if new_debt <= 0 and debt_cleared_day == 0 and TimeManager.day > 0:
		debt_cleared_day = TimeManager.day

func start_new_run() -> void:
	debt_cleared_day = 0
	EconomyManager.new_run(Balance.cfg)
	TimeManager.new_run()
	CommissionManager.new_run()
	UpgradeManager.new_run()
	_set_phase(Phase.TUTORIAL)

func return_to_menu() -> void:
	_set_phase(Phase.MENU)

func choose_pathway(p: StringName) -> void:
	pathway = p
	CommissionManager.set_pathway(p)
	enter_morning()

func enter_morning() -> void:
	EconomyManager.start_day()
	TimeManager.begin_day()
	EconomyManager.charge_rent()
	EconomyManager.process_installment(TimeManager.day)
	if _check_seizure():
		return
	CommissionManager.generate_offers(TimeManager.day)
	SaveManager.autosave()
	_set_phase(Phase.MORNING) # announce LAST so the UI reads final data

## Called by SaveManager after restoring state. No rent, no installment, no new offers.
func resume_from_save() -> void:
	_set_phase(Phase.MORNING)

func begin_workshop() -> void:
	_set_phase(Phase.WORKSHOP)

func begin_minigame() -> void:
	_set_phase(Phase.MINIGAME)

func request_end_day() -> void:
	if phase != Phase.WORKSHOP:
		return
	_set_phase(Phase.EVENING)
	CommissionManager.resolve_evening(TimeManager.day)
	_enter_night()

func _enter_night() -> void:
	_set_phase(Phase.NIGHT)
	var interest: int = EconomyManager.apply_interest()
	if _check_seizure():
		return
	var summary: Dictionary = EconomyManager.day_totals.duplicate()
	summary["interest"] = interest
	summary["day"] = TimeManager.day
	summary["credits"] = EconomyManager.credits
	summary["debt"] = EconomyManager.debt
	summary["net_worth"] = EconomyManager.net_worth()
	summary["strikes"] = EconomyManager.strikes
	EventBus.night_summary_ready.emit(summary)

func finish_night() -> void:
	if TimeManager.day >= Balance.cfg.campaign_days:
		_resolve_ending()
	else:
		enter_morning()

func _check_seizure() -> bool:
	if EconomyManager.is_seized():
		_end_run(false, &"seized")
		return true
	return false

func _resolve_ending() -> void:
	var won: bool = EconomyManager.debt == 0 and CommissionManager.pathway_objective_met()
	_end_run(won, &"victory" if won else &"timeout")

func calculate_final_rank() -> String:
	var nw: int = EconomyManager.net_worth()
	var cleared_day: int = debt_cleared_day if debt_cleared_day > 0 else 30
	if nw >= 15000 and cleared_day <= 18:
		return "S"
	elif nw >= 10000 and cleared_day <= 24:
		return "A"
	elif nw >= 9000 and cleared_day <= 30:
		return "B"
	return "C"

func _end_run(victory: bool, reason: StringName) -> void:
	SaveManager.delete_save() # a finished run cannot be continued
	_set_phase(Phase.VICTORY if victory else Phase.GAME_OVER)
	EventBus.run_ended.emit(victory, reason)

func _set_phase(p: Phase) -> void:
	var old: Phase = phase
	phase = p
	EventBus.phase_changed.emit(p, old)
