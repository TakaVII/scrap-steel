# purpose: Night summary UI presenting day revenue, material costs, lease, interest, and net cash change.
# depends on: Control, EventBus, GameManager, EconomyManager
# signals emitted: none
# signals listened to: EventBus.night_summary_ready

extends Control

@onready var night_title_label: Label = %NightTitleLabel
@onready var revenue_label: Label = %RevenueLabel
@onready var materials_label: Label = %MaterialsLabel
@onready var rent_label: Label = %RentLabel
@onready var interest_label: Label = %InterestLabel
@onready var net_profit_label: Label = %NetProfitLabel
@onready var debt_remaining_label: Label = %DebtRemainingLabel
@onready var debt_pay_input: LineEdit = %DebtPayInput
@onready var feedback_quote_label: Label = %FeedbackQuoteLabel

func _ready() -> void:
	EventBus.night_summary_ready.connect(_on_night_summary_ready)

func _on_night_summary_ready(summary: Dictionary) -> void:
	var day: int = summary.get("day", 1)
	var rev: int = summary.get("revenue", 0)
	var mat: int = summary.get("materials", 0)
	var rnt: int = summary.get("rent", 0)
	var intr: int = summary.get("interest", 0)
	var net: int = rev - mat - rnt - intr

	night_title_label.text = tr("NIGHT_TITLE") + " — " + tr("HUD_DAY") + " %d" % day
	revenue_label.text = tr("NIGHT_REVENUE") + ": +" + NumberFormat.format_credits(rev)
	materials_label.text = tr("NIGHT_MATERIALS") + ": -" + NumberFormat.format_credits(mat)
	rent_label.text = tr("NIGHT_RENT") + ": -" + NumberFormat.format_credits(rnt)
	interest_label.text = tr("NIGHT_INTEREST") + ": -" + NumberFormat.format_credits(intr)
	net_profit_label.text = tr("NIGHT_NET_PROFIT") + ": " + (("+" if net >= 0 else "") + NumberFormat.format_credits(net))
	debt_remaining_label.text = tr("HUD_DEBT") + ": " + NumberFormat.format_credits(summary.get("debt", 0))

	if intr > 0:
		feedback_quote_label.text = tr("NIGHT_FEEDBACK_INTEREST") % intr
	else:
		feedback_quote_label.text = tr("NIGHT_FEEDBACK_DEBT_FREE")

func _on_pay_debt_button_pressed() -> void:
	var amount: int = debt_pay_input.text.to_int()
	if amount > 0:
		EconomyManager.pay_debt(amount, tr("LEDGER_VOLUNTARY_DEBT_PAY"))
		debt_remaining_label.text = tr("HUD_DEBT") + ": " + NumberFormat.format_credits(EconomyManager.debt)
		debt_pay_input.text = ""

func _on_next_day_button_pressed() -> void:
	GameManager.finish_night()
