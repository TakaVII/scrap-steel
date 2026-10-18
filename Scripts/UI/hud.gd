# purpose: [v5 manual fix] Two-row compact HUD for the 480x270 viewport. Fixes: stale "next installment" on installment day, Assist interest rate read from the run (not the live setting), no hard-coded English.
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

var _shown_credits: int = 0
var _shown_debt: int = 0

func _ready() -> void:
	EventBus.credits_changed.connect(_on_credits_changed)
	EventBus.debt_changed.connect(_on_debt_changed)
	EventBus.action_points_changed.connect(_on_action_points_changed)
	EventBus.day_started.connect(_on_day_started)
	EventBus.tech_points_changed.connect(_on_tech_points_changed)
	EventBus.locale_changed.connect(_on_locale_changed)
	_update_all()

func _credits_prefix() -> String:
	return GamePalette.ICON_PASS + tr("HUD_CREDITS") + ": "

func _debt_prefix() -> String:
	return GamePalette.ICON_WARN + tr("HUD_DEBT") + ": "

func _update_all() -> void:
	_shown_credits = EconomyManager.credits
	_shown_debt = EconomyManager.debt
	credits_label.text = _credits_prefix() + "%d cr" % _shown_credits
	credits_label.add_theme_color_override("font_color", GamePalette.POSITIVE)
	debt_label.text = _debt_prefix() + "%d cr" % _shown_debt
	debt_label.add_theme_color_override("font_color", GamePalette.NEGATIVE if _shown_debt > 0 else GamePalette.NEUTRAL_TEXT)
	_update_interest()
	_on_action_points_changed(TimeManager.ap, TimeManager.ap_max)
	_on_day_started(TimeManager.day)
	_on_tech_points_changed(EconomyManager.tech_points)
	_update_installment()

func _on_credits_changed(new_val: int, _delta: int) -> void:
	Juice.animate_number(self, credits_label, _shown_credits, new_val, _credits_prefix(), " cr", 0.4)
	_shown_credits = new_val

func _on_debt_changed(new_val: int, _delta: int) -> void:
	Juice.animate_number(self, debt_label, _shown_debt, new_val, _debt_prefix(), " cr", 0.4)
	_shown_debt = new_val
	debt_label.add_theme_color_override("font_color", GamePalette.NEGATIVE if new_val > 0 else GamePalette.NEUTRAL_TEXT)
	_update_interest()
	_update_installment()

func _on_action_points_changed(cur: int, max_val: int) -> void:
	ap_label.text = GamePalette.ICON_INFO + tr("HUD_AP") + ": %d / %d" % [cur, max_val]

func _on_day_started(day: int) -> void:
	day_label.text = tr("HUD_DAY") + ": %d / %d" % [day, Balance.cfg.campaign_days]
	_update_installment()

func _on_tech_points_changed(val: int) -> void:
	tp_label.text = GamePalette.ICON_STAR + tr("HUD_TP") + ": %d" % val

func _on_locale_changed(_loc: String) -> void:
	_update_all()

func _update_interest() -> void:
	interest_label.text = GamePalette.ICON_FAIL + tr("HUD_INTEREST") + ": -%d cr" % EconomyManager.projected_interest()
	interest_label.add_theme_color_override("font_color", GamePalette.ACCENT)

## Next installment STRICTLY after today (today's was already charged this morning).
func _update_installment() -> void:
	var next_day: int = -1
	for d in Balance.cfg.installment_days:
		if d > TimeManager.day:
			next_day = d
			break
	if next_day != -1 and EconomyManager.debt > 0:
		installment_label.text = GamePalette.ICON_WARN + tr("HUD_NEXT_INSTALLMENT") + ": " + tr("HUD_DAY") + " %d (%d cr)" % [next_day, EconomyManager.next_installment_amount()]
		installment_label.add_theme_color_override("font_color", GamePalette.NEGATIVE)
	else:
		installment_label.text = GamePalette.ICON_PASS + tr("HUD_NEXT_INSTALLMENT") + ": " + tr("COMMON_NONE")
		installment_label.add_theme_color_override("font_color", GamePalette.POSITIVE)
