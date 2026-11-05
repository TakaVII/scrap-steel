# purpose: [v2] Plays the story beats of spec C2 outside the tutorial. v2: Kane's installment lines escalate (Day 8/15/22/29, strike 1/2), a "debt cleared" beat when debt reaches 0, a Day 28 warning. Beats: Day 1 tip, Dax's notes (Days 5/15/25), installment results (Kane), chapter 1 end (Day 8), pathway client (Day 12), "personal now" (Day 22), first-payout ledger tip. Beats are queued and shown one at a time in %StoryDialogue.
# depends on: Node, EventBus, GameManager, TimeManager, EconomyManager, CommissionManager, StoryData
# signals emitted: none
# signals listened to: EventBus.phase_changed, EventBus.commission_delivered, EventBus.debt_changed, DialogueBox.sequence_finished

extends Node

const DAX_DAYS: Dictionary = {5: &"dax_1", 15: &"dax_2", 25: &"dax_3"}
const PATHWAY_DAY: int = 12
const PERSONAL_DAY: int = 22
const CHAPTER_ONE_DAY: int = 8
const FINALE_DAY: int = 28

@onready var dialogue: Control = %StoryDialogue

var _played: Dictionary = {}
var _queue: Array[StringName] = []
var _first_delivery_pending: bool = false
var _cleared_pending: bool = false

func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.commission_delivered.connect(_on_commission_delivered)
	EventBus.debt_changed.connect(_on_debt_changed)
	dialogue.sequence_finished.connect(_on_sequence_finished)

func _on_phase_changed(new_phase: int, _old_phase: int) -> void:
	if new_phase == GameManager.Phase.TUTORIAL:
		_played.clear()
		_queue.clear()
		_first_delivery_pending = false
		_cleared_pending = false
	elif new_phase == GameManager.Phase.MORNING:
		_queue_morning(TimeManager.day)
		_queue_cleared()
	elif new_phase == GameManager.Phase.NIGHT:
		if _first_delivery_pending:
			_first_delivery_pending = false
			_enqueue(&"first_delivery", &"first_delivery")
		_queue_cleared()
	elif new_phase == GameManager.Phase.MENU or new_phase == GameManager.Phase.GAME_OVER or new_phase == GameManager.Phase.VICTORY:
		_queue.clear()
		dialogue.skip_all()
	_pump()

func _on_commission_delivered(_commission: Resource, _quality: float, _payout: int) -> void:
	if not _played.has(&"first_delivery"):
		_first_delivery_pending = true

## Debt reached zero: Kane reacts at the next morning or night (never in the middle of a minigame).
func _on_debt_changed(new_debt: int, _delta: int) -> void:
	if new_debt <= 0 and TimeManager.day > 0 and not _played.has(&"kane_cleared"):
		_cleared_pending = true

func _queue_cleared() -> void:
	if _cleared_pending:
		_cleared_pending = false
		_enqueue(&"kane_cleared", &"kane_cleared")

func _queue_morning(day: int) -> void:
	var inst: Dictionary = EconomyManager.last_installment
	if int(inst.get("day", -1)) == day:
		var paid_in_full: bool = int(inst.get("paid", 0)) >= int(inst.get("due", 0))
		if paid_in_full:
			_enqueue(StringName("inst_%d" % day), StringName("installment_ok_%d" % day))
		else:
			_enqueue(StringName("inst_%d" % day), StringName("installment_short_%d" % clampi(EconomyManager.strikes, 1, 2)))
		if day == CHAPTER_ONE_DAY:
			_enqueue(&"chapter_1", &"chapter_1")
		if day == PERSONAL_DAY:
			_enqueue(&"personal", &"personal")
	if EconomyManager.rent_strikes == 1:
		_enqueue(&"rent_strike_1", &"rent_strike")
	if day == 1:
		_enqueue(&"day1", &"day1")
	if DAX_DAYS.has(day):
		_enqueue(StringName("dax_%d" % day), DAX_DAYS[day])
	if day == PATHWAY_DAY:
		_enqueue(&"day12", StringName("day12_" + String(GameManager.pathway)))
	if day == FINALE_DAY:
		_enqueue(&"finale_28", &"finale_28")

## once_id guards against replays within a run; seq_id selects the StoryData sequence.
func _enqueue(once_id: StringName, seq_id: StringName) -> void:
	if _played.has(once_id):
		return
	_played[once_id] = true
	_queue.append(seq_id)

func _pump() -> void:
	if dialogue.is_playing() or _queue.is_empty():
		return
	var seq_id: StringName = _queue.pop_front()
	var lines: Array = StoryData.sequence(seq_id)
	if lines.is_empty():
		_pump()
		return
	dialogue.play(seq_id, lines)

func _on_sequence_finished(_seq_id: StringName) -> void:
	_pump()
