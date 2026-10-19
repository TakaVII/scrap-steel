# purpose: [v6] Decluttered two-row HUD. Row 1: credits, debt (+interest per day), AP, tech points, day. Row 2: next installment (always visible, spec "never cut") and strikes. Icons are optional (Assets/Textures/UI/icon_credit|debt|ap|tp.png); without them a short text tag is shown. Number tweens are killed before a new one starts.
# depends on: Control, EventBus, EconomyManager, TimeManager, Balance, GamePalette, NumberFormat, SpriteKit
# signals emitted: none
# signals listened to: EventBus.credits_changed, debt_changed, action_points_changed, day_started, tech_points_changed, locale_changed, strike_issued

extends Control

const NEAR_DUE_DAYS: int = 2

@onready var credits_icon: TextureRect = %CreditsIcon
@onready var credits_label: Label = %CreditsLabel
@onready var debt_icon: TextureRect = %DebtIcon
@onready var debt_label: Label = %DebtLabel
@onready var ap_icon: TextureRect = %ApIcon
@onready var ap_label: Label = %ApLabel
@onready var tp_icon: TextureRect = %TpIcon
@onready var tp_label: Label = %TpLabel
@onready var day_label: Label = %DayLabel
@onready var installment_label: Label = %InstallmentLabel
@onready var strikes_label: Label = %StrikesLabel

var _shown_credits: int = 0
var _shown_debt: int = 0
var _tween_credits: Tween
var _tween_debt: Tween

func _ready() -> void:
	EventBus.credits_changed.connect(_on_credits_changed)
	EventBus.debt_changed.connect(_on_debt_changed)
	EventBus.action_points_changed.connect(_on_action_points_changed)
	EventBus.day_started.connect(_on_day_started)
	EventBus.tech_points_changed.connect(_on_tech_points_changed)
	EventBus.locale_changed.connect(_on_locale_changed)
	EventBus.strike_issued.connect(_on_strike_issued)
	_apply_icon(credits_icon, "credit")
	_apply_icon(debt_icon, "debt")
	_apply_icon(ap_icon, "ap")
	_apply_icon(tp_icon, "tp")
	_update_all()

func _apply_icon(rect: TextureRect, icon_name: String) -> void:
	var t: Texture2D = SpriteKit.tex(SpriteKit.UI + "icon_" + icon_name + ".png")
	rect.texture = t
	rect.visible = t != null

## Text tag shown only when the icon art is missing.
func _tag(icon: TextureRect, key: String) -> String:
	return "" if icon.visible else tr(key) + " "

func _update_all() -> void:
	_shown_credits = EconomyManager.credits
	_shown_debt = EconomyManager.debt
	_set_credits_text(_shown_credits)
	_set_debt_text(_shown_debt)
	_on_action_points_changed(TimeManager.ap, TimeManager.ap_max)
	_on_day_started(TimeManager.day)
	_on_tech_points_changed(EconomyManager.tech_points)
	_update_strikes()

# ---------------------------------------------------------------- credits and debt

func _set_credits_text(v: Variant) -> void:
	credits_label.text = _tag(credits_icon, "HUD_CREDITS") + NumberFormat.format_credits(roundi(float(v)))
	credits_label.add_theme_color_override("font_color", GamePalette.POSITIVE)

func _set_debt_text(v: Variant) -> void:
	var value: int = roundi(float(v))
	var text: String = _tag(debt_icon, "HUD_DEBT") + NumberFormat.format_credits(value)
	if value > 0:
		text += "  +" + NumberFormat.group(EconomyManager.projected_interest()) + tr("HUD_PER_DAY")
	debt_label.text = text
	debt_label.add_theme_color_override("font_color", GamePalette.NEGATIVE if value > 0 else GamePalette.NEUTRAL_TEXT)
	debt_label.tooltip_text = NumberFormat.render(tr("HUD_TIP_DEBT"), {"interest": NumberFormat.format_credits(EconomyManager.projected_interest())})

func _on_credits_changed(new_val: int, _delta: int) -> void:
	if _tween_credits and _tween_credits.is_valid():
		_tween_credits.kill()
	_tween_credits = create_tween()
	_tween_credits.tween_method(_set_credits_text, _shown_credits, new_val, 0.4)
	_shown_credits = new_val

func _on_debt_changed(new_val: int, _delta: int) -> void:
	if _tween_debt and _tween_debt.is_valid():
		_tween_debt.kill()
	_tween_debt = create_tween()
	_tween_debt.tween_method(_set_debt_text, _shown_debt, new_val, 0.4)
	_shown_debt = new_val
	_update_installment()

# ---------------------------------------------------------------- the rest

func _on_action_points_changed(cur: int, max_val: int) -> void:
	ap_label.text = _tag(ap_icon, "HUD_AP") + "%d/%d" % [cur, max_val]

func _on_day_started(day: int) -> void:
	day_label.text = tr("HUD_DAY") + " %d/%d" % [day, Balance.cfg.campaign_days]
	_update_installment()
	_update_strikes()

func _on_tech_points_changed(val: int) -> void:
	tp_label.text = _tag(tp_icon, "HUD_TP") + str(val)

func _on_locale_changed(_loc: String) -> void:
	_update_all()
	_update_installment()

func _on_strike_issued(_strikes: int) -> void:
	_update_strikes()

func _update_strikes() -> void:
	if EconomyManager.strikes > 0:
		strikes_label.text = tr("MORNING_STRIKES_WARNING") + " %d/%d" % [EconomyManager.strikes, Balance.cfg.max_strikes]
		strikes_label.add_theme_color_override("font_color", GamePalette.NEGATIVE)
	else:
		strikes_label.text = ""

## Next installment STRICTLY after today (today's was already charged this morning).
func _update_installment() -> void:
	var next_day: int = -1
	for d in Balance.cfg.installment_days:
		if d > TimeManager.day:
			next_day = d
			break
	if next_day != -1 and EconomyManager.debt > 0:
		installment_label.text = tr("HUD_NEXT_INSTALLMENT") + ": " + tr("HUD_DAY") + " %d - %s" % [next_day, NumberFormat.format_credits(EconomyManager.next_installment_amount())]
		var near: bool = next_day - TimeManager.day <= NEAR_DUE_DAYS
		installment_label.add_theme_color_override("font_color", GamePalette.NEGATIVE if near else GamePalette.ACCENT)
	else:
		installment_label.text = tr("HUD_NEXT_INSTALLMENT") + ": " + tr("COMMON_NONE")
		installment_label.add_theme_color_override("font_color", GamePalette.NEUTRAL_TEXT)
