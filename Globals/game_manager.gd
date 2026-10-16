# purpose: High-level state machine router governing day phases, win/loss evaluation, and run transitions.
# depends on: Balance, EventBus, EconomyManager, TimeManager, CommissionManager, UpgradeManager, SaveManager
# signals emitted: EventBus.phase_changed, run_ended, night_summary_ready
# signals listened to: EventBus.minigame_finished

extends Node

enum Phase { MENU, TUTORIAL, MORNING, WORKSHOP, MINIGAME, EVENING, NIGHT, GAME_OVER, VICTORY }

var phase: Phase = Phase.MENU
var pathway: StringName = &"mech"

func _ready() -> void:
	EventBus.minigame_finished.connect(func(_r: RefCounted) -> void:
		if phase == Phase.MINIGAME:
			_set_phase(Phase.WORKSHOP)
	)

func start_new_run() -> void:
	EconomyManager.new_run(Balance.cfg)
	TimeManager.new_run()
	CommissionManager.new_run()
	UpgradeManager.new_run()
	enter_morning()

func enter_morning() -> void:
	_set_phase(Phase.MORNING)
	TimeManager.begin_day()
	EconomyManager.charge_rent()
	EconomyManager.process_installment(TimeManager.day)
	if _check_seizure():
		return
	CommissionManager.generate_offers(TimeManager.day)
	SaveManager.autosave()

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

func _end_run(victory: bool, reason: StringName) -> void:
	_set_phase(Phase.VICTORY if victory else Phase.GAME_OVER)
	EventBus.run_ended.emit(victory, reason)

func _set_phase(p: Phase) -> void:
	var old: Phase = phase
	phase = p
	EventBus.phase_changed.emit(p, old)
