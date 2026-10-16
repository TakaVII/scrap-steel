# purpose: Persistent HUD displaying credits, debt, daily interest, AP, day progress, and next installment due.
# depends on: Control, EventBus, EconomyManager, TimeManager, Balance
# signals emitted: none
# signals listened to: EventBus.credits_changed, debt_changed, action_points_changed, day_started, tech_points_changed

extends Control

@onready var credits_label: Label = %CreditsLabel
@onready var debt_label: Label = %DebtLabel
@onready var interest_label: Label = %InterestLabel
@onready var ap_label: Label = %ApLabel
@onready var day_label: Label = %DayLabel
@onready var installment_label: Label = %InstallmentLabel
@onready var tp_label: Label = %TpLabel

func _ready() -> void:
	EventBus.credits_changed.connect(_on_credits_changed)
	EventBus.debt_changed.connect(_on_debt_changed)
	EventBus.action_points_changed.connect(_on_action_points_changed)
	EventBus.day_started.connect(_on_day_started)
	EventBus.tech_points_changed.connect(_on_tech_points_changed)
	_refresh_all()

func _refresh_all() -> void:
	_on_credits_changed(EconomyManager.credits, 0)
	_on_debt_changed(EconomyManager.debt, 0)
	_on_action_points_changed(TimeManager.ap, TimeManager.ap_max)
	_on_day_started(TimeManager.day)
	_on_tech_points_changed(EconomyManager.tech_points)

func _on_credits_changed(new_val: int, _d: int) -> void:
	credits_label.text = tr("HUD_CREDITS") + ": " + NumberFormat.format_credits(new_val)

func _on_debt_changed(new_val: int, _d: int) -> void:
	debt_label.text = tr("HUD_DEBT") + ": " + NumberFormat.format_credits(new_val)
	var est_interest: int = roundi(new_val * Balance.cfg.daily_interest_rate)
	interest_label.text = "(-" + str(est_interest) + " cr/day)"
	_update_installment_preview()

func _on_action_points_changed(current: int, max_val: int) -> void:
	ap_label.text = tr("HUD_AP") + ": %d/%d" % [current, max_val]

func _on_day_started(day: int) -> void:
	day_label.text = tr("HUD_DAY") + ": %d/%d" % [day, Balance.cfg.campaign_days]
	_update_installment_preview()

func _on_tech_points_changed(val: int) -> void:
	tp_label.text = tr("HUD_TP") + ": %d" % val

func _update_installment_preview() -> void:
	var next_day: int = -1
	for d in Balance.cfg.installment_days:
		if d >= TimeManager.day:
			next_day = d
			break
	if next_day != -1 and EconomyManager.debt > 0:
		var raw_due: int = maxi(Balance.cfg.installment_min, roundi(EconomyManager.debt * Balance.cfg.installment_pct))
		var due: int = mini(raw_due, EconomyManager.debt)
		installment_label.text = tr("HUD_NEXT_INSTALLMENT") + ": Day %d (%d cr)" % [next_day, due]
	else:
		installment_label.text = tr("HUD_NEXT_INSTALLMENT") + ": " + tr("COMMON_NONE")

func _on_ledger_button_pressed() -> void:
	var root := get_tree().root.get_node_or_null("Main")
	if root:
		var ledger := root.get_node_or_null("%LedgerPanel")
		if ledger:
			ledger.visible = not ledger.visible
