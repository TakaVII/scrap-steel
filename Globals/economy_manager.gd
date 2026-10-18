# purpose: [v3 manual fix] Core financial logic: ledger, rent, interest, installments, debt. Daily totals now reset every morning; shortfalls become debt instead of free money.
# depends on: Balance (Balance.cfg), SettingsManager, EventBus
# signals emitted: EventBus.credits_changed, debt_changed, ledger_entry_added, installment_due, strike_issued, tech_points_changed
# signals listened to: none

extends Node

var credits: int = 0
var debt: int = 0
var strikes: int = 0
var tech_points: int = 0
## Interest rate locked at run start (Standard or Assist preset). Saved with the run.
var interest_rate: float = 0.02
var day_totals: Dictionary = {}
## {"day": int, "due": int, "paid": int} for the installment processed this morning.
var last_installment: Dictionary = {}

func new_run(config: BalanceConfig) -> void:
	if SettingsManager.assist_economy:
		credits = config.assist_start_credits
		debt = config.assist_start_debt
		interest_rate = config.assist_interest_rate
	else:
		credits = config.start_credits
		debt = config.start_debt
		interest_rate = config.daily_interest_rate
	strikes = 0
	tech_points = 0
	last_installment = {}
	start_day()
	EventBus.credits_changed.emit(credits, 0)
	EventBus.debt_changed.emit(debt, 0)
	EventBus.tech_points_changed.emit(tech_points)

## Call once at the start of every morning, BEFORE rent is charged.
func start_day() -> void:
	day_totals = {
		"revenue": 0, "materials": 0, "rent": 0, "interest": 0, "fines": 0,
		"refunds": 0, "upgrades": 0, "debt_paid": 0,
		"ap_used": 0, "jobs_delivered": 0, "quality_sum": 0.0
	}
	last_installment = {}

func add_credits(amount: int, description: String, category: StringName = &"income") -> void:
	credits += amount
	if category == &"income":
		day_totals["revenue"] += amount
	EventBus.credits_changed.emit(credits, amount)
	EventBus.ledger_entry_added.emit(description, amount, category)

## Returns false (and changes nothing) if the player cannot afford it.
func try_spend(amount: int, description: String, category: StringName) -> bool:
	if amount > credits:
		return false
	credits -= amount
	_track_expense(category, amount)
	EventBus.credits_changed.emit(credits, -amount)
	EventBus.ledger_entry_added.emit(description, -amount, category)
	return true

## Charges what the player can pay; the shortfall becomes debt plus the late fee (same rule as rent).
func charge_with_shortfall(amount: int, description: String, category: StringName, shortfall_description: String) -> void:
	var paid: int = mini(credits, amount)
	if paid > 0:
		try_spend(paid, description, category)
	var shortfall: int = amount - paid
	if shortfall > 0:
		_add_debt(roundi(shortfall * (1.0 + Balance.cfg.late_fee_rate)), shortfall_description)

func _track_expense(category: StringName, amount: int) -> void:
	match category:
		&"materials":
			day_totals["materials"] += amount
		&"rent", &"overtime":
			day_totals["rent"] += amount # NIGHT_RENT line = lease + overtime overhead
		&"fine":
			day_totals["fines"] += amount
		&"refund":
			day_totals["refunds"] += amount
		&"upgrade":
			day_totals["upgrades"] += amount

func charge_rent() -> void:
	charge_with_shortfall(Balance.cfg.daily_rent, tr("LEDGER_RENT"), &"rent", tr("LEDGER_RENT_SHORTFALL"))

func projected_interest() -> int:
	return roundi(debt * interest_rate)

func apply_interest() -> int:
	if debt <= 0:
		return 0
	var interest: int = projected_interest()
	day_totals["interest"] += interest
	_add_debt(interest, tr("LEDGER_INTEREST"))
	return interest

func next_installment_amount() -> int:
	var raw_due: int = maxi(Balance.cfg.installment_min, roundi(debt * Balance.cfg.installment_pct))
	return mini(raw_due, debt)

func process_installment(day: int) -> void:
	if not Balance.cfg.installment_days.has(day) or debt <= 0:
		return
	var due: int = next_installment_amount()
	EventBus.installment_due.emit(day, due)
	var paid: int = mini(credits, due)
	if paid > 0:
		pay_debt(paid, tr("LEDGER_INSTALLMENT"))
	last_installment = {"day": day, "due": due, "paid": paid}
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
