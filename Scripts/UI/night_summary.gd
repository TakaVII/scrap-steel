# purpose: [v2] Night summary rendering financial ledger totals and R&D upgrade shop with payback comparisons.
# depends on: Control, GameManager, EconomyManager, UpgradeManager, UpgradeData
# signals emitted: none
# signals listened to: EventBus.night_summary_ready, EventBus.upgrade_purchased

extends Control

const UPGRADE_CARD_SCENE = preload("res://Scenes/UI/upgrade_card.tscn")

@onready var title_label: Label = %TitleLabel
@onready var revenue_label: Label = %RevenueLabel
@onready var materials_label: Label = %MaterialsLabel
@onready var rent_label: Label = %RentLabel
@onready var interest_label: Label = %InterestLabel
@onready var fines_label: Label = %FinesLabel
@onready var refunds_label: Label = %RefundsLabel
@onready var upgrades_spent_label: Label = %UpgradesSpentLabel
@onready var net_profit_label: Label = %NetProfitLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var current_balance_label: Label = %CurrentBalanceLabel
@onready var current_debt_label: Label = %CurrentDebtLabel
@onready var upgrades_container: HBoxContainer = %UpgradesContainer
@onready var next_day_button: Button = %NextDayButton

func _ready() -> void:
	EventBus.night_summary_ready.connect(_on_night_summary_ready)
	EventBus.upgrade_purchased.connect(_on_upgrade_purchased)

func _on_night_summary_ready(summary: Dictionary) -> void:
	title_label.text = "NIGHT SUMMARY — DAY %d" % summary.get("day", 1)
	revenue_label.text = "+%d cr" % summary.get("revenue", 0)
	materials_label.text = "-%d cr" % summary.get("materials", 0)
	rent_label.text = "-%d cr" % summary.get("rent", 0)
	interest_label.text = "-%d cr" % summary.get("interest", 0)
	fines_label.text = "-%d cr" % summary.get("fines", 0)
	refunds_label.text = "-%d cr" % summary.get("refunds", 0)
	upgrades_spent_label.text = "-%d cr" % summary.get("upgrades", 0)

	var rev: int = summary.get("revenue", 0)
	var exp: int = summary.get("materials", 0) + summary.get("rent", 0) + summary.get("interest", 0) + summary.get("fines", 0) + summary.get("refunds", 0) + summary.get("upgrades", 0)
	var net: int = rev - exp
	net_profit_label.text = "%s%d cr" % ["+" if net >= 0 else "", net]

	current_balance_label.text = "Cash: %d cr" % summary.get("credits", 0)
	current_debt_label.text = "Syndicate Debt: %d cr" % summary.get("debt", 0)

	var intr: int = summary.get("interest", 0)
	if intr > 0:
		feedback_label.text = tr("NIGHT_FEEDBACK_INTEREST") % intr
	else:
		feedback_label.text = tr("NIGHT_FEEDBACK_DEBT_FREE")

	_build_upgrades()

func _build_upgrades() -> void:
	for child in upgrades_container.get_children():
		child.queue_free()

	for upg in UpgradeManager.available_upgrades:
		var card = UPGRADE_CARD_SCENE.instantiate()
		upgrades_container.add_child(card)
		card.setup(upg)
		card.buy_requested.connect(_on_buy_requested)

func _on_buy_requested(id: StringName) -> void:
	if UpgradeManager.purchase_upgrade(id):
		_build_upgrades()

func _on_upgrade_purchased(_id: StringName) -> void:
	_build_upgrades()

func _on_next_day_button_pressed() -> void:
	GameManager.finish_night()
