# purpose: Core financial logic manager handling credits, debt, rent, interest, installments, and strikes.
# depends on: Balance (Balance.cfg), EventBus
# signals emitted: EventBus.credits_changed, debt_changed, ledger_entry_added, installment_due, strike_issued, tech_points_changed
# signals listened to: none

extends Node

var credits: int = 0
var debt: int = 0
var strikes: int = 0
var tech_points: int = 0
var day_totals: Dictionary = {}

func new_run(config: BalanceConfig) -> void:
	credits = config.start_credits
	debt = config.start_debt
	strikes = 0
	tech_points = 0
	_reset_day_totals()
	EventBus.credits_changed.emit(credits, 0)
	EventBus.debt_changed.emit(debt, 0)

func _reset_day_totals() -> void:
	day_totals = {
		"revenue": 0,
		"materials": 0,
		"rent": 0,
		"interest": 0,
		"fines": 0,
		"refunds": 0,
		"upgrades": 0,
		"debt_paid": 0
	}

func add_credits(amount: int, description: String, category: StringName = &"income") -> void:
	credits += amount
	if category == &"income":
		day_totals["revenue"] += amount
	EventBus.credits_changed.emit(credits, amount)
	EventBus.ledger_entry_added.emit(description, amount, category)

func try_spend(amount: int, description: String, category: StringName) -> bool:
	if amount > credits:
		return false
	credits -= amount
	_track_expense(category, amount)
	EventBus.credits_changed.emit(credits, -amount)
	EventBus.ledger_entry_added.emit(description, -amount, category)
	return true

func _track_expense(category: StringName, amount: int) -> void:
	match category:
		&"materials":
			day_totals["materials"] += amount
		&"rent":
			day_totals["rent"] += amount
		&"fine":
			day_totals["fines"] += amount
		&"refund":
			day_totals["refunds"] += amount
		&"upgrade":
			day_totals["upgrades"] += amount

func charge_rent() -> void:
	var rent: int = Balance.cfg.daily_rent
	var paid: int = mini(credits, rent)
	if paid > 0:
		try_spend(paid, tr("LEDGER_RENT"), &"rent")
	var shortfall: int = rent - paid
	if shortfall > 0:
		var penalty_debt: int = roundi(shortfall * (1.0 + Balance.cfg.late_fee_rate))
		_add_debt(penalty_debt, tr("LEDGER_RENT_SHORTFALL"))

func apply_interest() -> int:
	if debt <= 0:
		return 0
	var interest: int = roundi(debt * Balance.cfg.daily_interest_rate)
	day_totals["interest"] += interest
	_add_debt(interest, tr("LEDGER_INTEREST"))
	return interest

func process_installment(day: int) -> void:
	if not Balance.cfg.installment_days.has(day) or debt <= 0:
		return
	var raw_due: int = maxi(Balance.cfg.installment_min, roundi(debt * Balance.cfg.installment_pct))
	var due: int = mini(raw_due, debt)
	EventBus.installment_due.emit(day, due)
	var paid: int = mini(credits, due)
	if paid > 0:
		pay_debt(paid, tr("LEDGER_INSTALLMENT"))
	if paid < due:
		strikes += 1
		var fee: int = roundi((due - paid) * Balance.cfg.late_fee_rate)
		_add_debt(fee, tr("LEDGER_STRIKE_FEE"))
		EventBus.strike_issued.emit(strikes)

func pay_debt(amount: int, description: String = "Debt repayment") -> int:
	var pay: int = mini(mini(amount, credits), debt)
	if pay <= 0:
		return 0
	credits -= pay
	debt -= pay
	day_totals["debt_paid"] += pay
	EventBus.credits_changed.emit(credits, -pay)
	EventBus.debt_changed.emit(debt, -pay)
	EventBus.ledger_entry_added.emit(description, -pay, &"debt")
	return pay

func _add_debt(amount: int, description: String) -> void:
	debt += amount
	EventBus.debt_changed.emit(debt, amount)
	EventBus.ledger_entry_added.emit(description, amount, &"debt_added")

func net_worth() -> int:
	return credits - debt

func is_seized() -> bool:
	return debt >= Balance.cfg.seize_debt_threshold or strikes >= Balance.cfg.max_strikes

func add_tech_points(n: int) -> void:
	tech_points += n
	EventBus.tech_points_changed.emit(tech_points)
