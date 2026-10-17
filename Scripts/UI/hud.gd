# purpose: [v4] Always-visible HUD top bar with redundant shape icons ([✓], [▲], [◆]) using GamePalette and RTL directional mirroring (spec §C10, §D7, §D9).
# depends on: Control, EventBus, EconomyManager, TimeManager, Balance, Juice, GamePalette
# signals emitted: none
# signals listened to: EventBus.credits_changed, debt_changed, action_points_changed, day_started, tech_points_changed, locale_changed

extends Control

@onready var credits_label: Label = %CreditsLabel
@onready var debt_label: Label = %DebtLabel
@onready var interest_label: Label = %InterestLabel
@onready var ap_label: Label = %ApLabel
@onready var day_label: Label = %DayLabel
@onready var installment_label: Label = %InstallmentLabel
@onready var tp_label: Label = %TpLabel

var _current_displayed_credits: int = 2000
var _current_displayed_debt: int = 10000

func _ready() -> void:
	EventBus.credits_changed.connect(_on_credits_changed)
	EventBus.debt_changed.connect(_on_debt_changed)
	EventBus.action_points_changed.connect(_on_action_points_changed)
	EventBus.day_started.connect(_on_day_started)
	EventBus.tech_points_changed.connect(_on_tech_points_changed)
	EventBus.locale_changed.connect(_on_locale_changed)
	_update_all()

func _update_all() -> void:
	credits_label.text = "[✓] " + tr("HUD_CREDITS") + ": %d cr" % EconomyManager.credits
	credits_label.add_theme_color_override("font_color", GamePalette.POSITIVE)

	debt_label.text = "[▲] " + tr("HUD_DEBT") + ": %d cr" % EconomyManager.debt
	debt_label.add_theme_color_override("font_color", GamePalette.NEGATIVE if EconomyManager.debt > 0 else GamePalette.NEUTRAL_TEXT)

	_update_interest()
	ap_label.text = "[◆] " + tr("HUD_AP") + ": %d / %d" % [TimeManager.ap, TimeManager.ap_max]
	day_label.text = tr("HUD_DAY") + ": %d / %d" % [TimeManager.day, Balance.cfg.campaign_days]
	_update_installment()
	tp_label.text = "[★] " + tr("HUD_TP") + ": %d" % EconomyManager.tech_points

func _on_credits_changed(new_val: int, _delta: int) -> void:
	var prefix: String = "[✓] " + tr("HUD_CREDITS") + ": "
	Juice.animate_number(self, credits_label, _current_displayed_credits, new_val, prefix, " cr", 0.4)
	_current_displayed_credits = new_val

func _on_debt_changed(new_val: int, _delta: int) -> void:
	var prefix: String = "[▲] " + tr("HUD_DEBT") + ": "
	Juice.animate_number(self, debt_label, _current_displayed_debt, new_val, prefix, " cr", 0.4)
	_current_displayed_debt = new_val
	_update_interest()
	_update_installment()

func _on_action_points_changed(cur: int, max_val: int) -> void:
	ap_label.text = "[◆] " + tr("HUD_AP") + ": %d / %d" % [cur, max_val]

func _on_day_started(day: int) -> void:
	day_label.text = tr("HUD_DAY") + ": %d / %d" % [day, Balance.cfg.campaign_days]
	_update_installment()

func _on_tech_points_changed(val: int) -> void:
	tp_label.text = "[★] " + tr("HUD_TP") + ": %d" % val

func _on_locale_changed(_loc: String) -> void:
	_update_all()

func _update_interest() -> void:
	var rate: float = 0.01 if SettingsManager.assist_economy else Balance.cfg.daily_interest_rate
	var daily_int: int = roundi(EconomyManager.debt * rate)
	interest_label.text = "[✗] " + tr("HUD_INTEREST") + ": -%d cr" % daily_int
	interest_label.add_theme_color_override("font_color", GamePalette.ACCENT)

func _update_installment() -> void:
	var next_day: int = -1
	for d in Balance.cfg.installment_days:
		if d >= TimeManager.day:
			next_day = d
			break
	if next_day != -1 and EconomyManager.debt > 0:
		var raw_due: int = maxi(Balance.cfg.installment_min, roundi(EconomyManager.debt * Balance.cfg.installment_pct))
		var due: int = mini(raw_due, EconomyManager.debt)
		installment_label.text = "[▲] " + tr("HUD_NEXT_INSTALLMENT") + ": Day %d (%d cr)" % [next_day, due]
		installment_label.add_theme_color_override("font_color", GamePalette.NEGATIVE)
	else:
		installment_label.text = "[✓] " + tr("HUD_NEXT_INSTALLMENT") + ": " + tr("COMMON_NONE")
		installment_label.add_theme_color_override("font_color", GamePalette.POSITIVE)
