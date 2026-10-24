# purpose: [v6] Night summary + R&D shop. v6: two columns (numbers left, upgrades right, vertical scroll), short header labels so no language can widen the screen, top margin below the HUD. v5: feedback and client mail are fixed single lines (clipped), so they can no longer grow and push the Next Morning button off screen. v4: no hardcoded English, thousands separators, safe feedback formatting, and a "client mail" line (satisfied/unhappy quote from the client of today's delivery).
# depends on: Control, GameManager, EconomyManager, UpgradeManager, UpgradeData, NumberFormat, ClientRoster
# signals emitted: none
# signals listened to: EventBus.night_summary_ready, EventBus.upgrade_purchased, EventBus.commission_delivered, EventBus.day_started

extends Control

const UPGRADE_CARD_SCENE = preload("res://Scenes/UI/upgrade_card.tscn")
const MAIL_HAPPY_MIN_QUALITY: float = 0.75
const MAIL_UNHAPPY_MAX_QUALITY: float = 0.50

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
@onready var upgrades_container: VBoxContainer = %UpgradesContainer
@onready var next_day_button: Button = %NextDayButton

## Deliveries of the current day: {"client": StringName, "q": float}
var _mail: Array[Dictionary] = []
var _mail_label: Label

func _ready() -> void:
	EventBus.night_summary_ready.connect(_on_night_summary_ready)
	EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
	EventBus.commission_delivered.connect(_on_commission_delivered)
	EventBus.day_started.connect(_on_day_started)
	# NextDayButton.pressed is already connected in night_summary.tscn (do not connect it twice).
	_style_wrapped(feedback_label)
	_mail_label = Label.new()
	_style_wrapped(_mail_label)
	_mail_label.add_theme_color_override("font_color", GamePalette.ACCENT)
	_mail_label.visible = false
	var holder: Node = feedback_label.get_parent()
	holder.add_child(_mail_label)
	holder.move_child(_mail_label, feedback_label.get_index() + 1)

## Wraps to at most 2 lines and then ellipsizes, so the left column has a fixed maximum height.
func _style_wrapped(l: Label) -> void:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.max_lines_visible = 2
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.add_theme_constant_override("line_spacing", 0)

func _on_day_started(_day: int) -> void:
	_mail.clear()

func _on_commission_delivered(commission: Resource, quality: float, _payout: int) -> void:
	var data: CommissionData = commission as CommissionData
	if data != null:
		_mail.append({"client": data.client_id, "q": quality})

func _on_night_summary_ready(summary: Dictionary) -> void:
	title_label.text = tr("NIGHT_TITLE") + " - " + tr("HUD_DAY") + " %d" % int(summary.get("day", 1))
	revenue_label.text = "+" + NumberFormat.format_credits(int(summary.get("revenue", 0)))
	materials_label.text = "-" + NumberFormat.format_credits(int(summary.get("materials", 0)))
	rent_label.text = "-" + NumberFormat.format_credits(int(summary.get("rent", 0)))
	interest_label.text = "-" + NumberFormat.format_credits(int(summary.get("interest", 0)))
	fines_label.text = "-" + NumberFormat.format_credits(int(summary.get("fines", 0)))
	refunds_label.text = "-" + NumberFormat.format_credits(int(summary.get("refunds", 0)))
	upgrades_spent_label.text = "-" + NumberFormat.format_credits(int(summary.get("upgrades", 0)))

	var rev: int = int(summary.get("revenue", 0))
	var spent: int = int(summary.get("materials", 0)) + int(summary.get("rent", 0)) + int(summary.get("interest", 0)) + int(summary.get("fines", 0)) + int(summary.get("refunds", 0)) + int(summary.get("upgrades", 0))
	var net: int = rev - spent
	net_profit_label.text = ("+" if net >= 0 else "") + NumberFormat.format_credits(net)

	current_balance_label.text = tr("HUD_CREDITS") + ": " + NumberFormat.format_credits(int(summary.get("credits", 0)))
	current_debt_label.text = tr("HUD_DEBT") + ": " + NumberFormat.format_credits(int(summary.get("debt", 0)))

	var intr: int = int(summary.get("interest", 0))
	var text: String = ""
	if intr > 0:
		text = NumberFormat.fmt(tr("NIGHT_FEEDBACK_INTEREST"), NumberFormat.group(intr))
	else:
		text = tr("NIGHT_FEEDBACK_DEBT_FREE")
	feedback_label.text = text
	var mail: String = _client_mail()
	_mail_label.text = mail
	_mail_label.visible = mail != ""
	_build_upgrades()

## One client quote: the unhappiest if someone got a poor job, otherwise the happiest good one.
func _client_mail() -> String:
	if _mail.is_empty():
		return ""
	var worst: Dictionary = _mail[0]
	var best: Dictionary = _mail[0]
	for m in _mail:
		if float(m["q"]) < float(worst["q"]):
			worst = m
		if float(m["q"]) > float(best["q"]):
			best = m
	var pick: Dictionary = {}
	var kind: String = ""
	if float(worst["q"]) < MAIL_UNHAPPY_MAX_QUALITY:
		pick = worst
		kind = "UNHAPPY"
	elif float(best["q"]) >= MAIL_HAPPY_MIN_QUALITY:
		pick = best
		kind = "SATISFIED"
	if pick.is_empty() or ClientRoster.get_client(pick["client"]).is_empty():
		return ""
	return "%s: \"%s\"" % [ClientRoster.display_name(pick["client"]), tr(ClientRoster.line_key(pick["client"], kind))]

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
