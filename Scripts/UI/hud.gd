# purpose: [v7] Header redesign. Three bordered clusters: MONEY (credits, debt + interest/day, "% repaid" bar), CENTER (day + 30-day track with installment days, next installment with a have/need bar that pulses when due soon and short), RIGHT (AP battery cells, tech points, strike boxes). Credit/debt changes float a small +/- number under the value. Icons are optional (Assets/Textures/UI/icon_credit|debt|ap|tp.png, 10x10).
# depends on: Control, HudPips, EventBus, EconomyManager, TimeManager, Balance, GamePalette, NumberFormat, SpriteKit, SettingsManager
# signals emitted: none
# signals listened to: EventBus.credits_changed, debt_changed, action_points_changed, day_started, tech_points_changed, locale_changed, strike_issued, settings_changed

extends Control

const NEAR_DUE_DAYS: int = 2
const DELTA_FLOAT_PX: float = 8.0
const DELTA_SEC: float = 0.9

@onready var credits_icon: TextureRect = %CreditsIcon
@onready var credits_label: Label = %CreditsLabel
@onready var debt_icon: TextureRect = %DebtIcon
@onready var debt_label: Label = %DebtLabel
@onready var debt_bar: ProgressBar = %DebtBar
@onready var ap_icon: TextureRect = %ApIcon
@onready var ap_label: Label = %ApLabel
@onready var ap_pips: HudPips = %ApPips
@onready var tp_icon: TextureRect = %TpIcon
@onready var tp_label: Label = %TpLabel
@onready var strike_pips: HudPips = %StrikePips
@onready var day_label: Label = %DayLabel
@onready var day_pips: HudPips = %DayPips
@onready var center_panel: PanelContainer = %CenterPanel
@onready var installment_label: Label = %InstallmentLabel
@onready var installment_bar: ProgressBar = %InstallmentBar

var _shown_credits: int = 0
var _shown_debt: int = 0
var _tween_credits: Tween
var _tween_debt: Tween
var _pulse_tween: Tween
var _pulsing: bool = false
var _fill_ok: StyleBoxFlat
var _fill_warn: StyleBoxFlat
var _fill_late: StyleBoxFlat

func _ready() -> void:
	EventBus.credits_changed.connect(_on_credits_changed)
	EventBus.debt_changed.connect(_on_debt_changed)
	EventBus.action_points_changed.connect(_on_action_points_changed)
	EventBus.day_started.connect(_on_day_started)
	EventBus.tech_points_changed.connect(_on_tech_points_changed)
	EventBus.locale_changed.connect(_on_locale_changed)
	EventBus.strike_issued.connect(_on_strike_issued)
	EventBus.settings_changed.connect(_on_settings_changed)
	_fill_ok = _flat(GamePalette.POSITIVE)
	_fill_warn = _flat(GamePalette.ACCENT)
	_fill_late = _flat(GamePalette.NEGATIVE)
	_apply_icon(credits_icon, "credit")
	_apply_icon(debt_icon, "debt")
	_apply_icon(ap_icon, "ap")
	_apply_icon(tp_icon, "tp")
	_update_all()

func _flat(c: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	return sb

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
	_update_debt_bar(value)

## Share of the starting debt already repaid (starting debt follows the Standard / Assist preset).
func _update_debt_bar(value: int) -> void:
	var assist: bool = is_equal_approx(EconomyManager.interest_rate, Balance.cfg.assist_interest_rate)
	var start: int = Balance.cfg.assist_start_debt if assist else Balance.cfg.start_debt
	var ref: int = maxi(maxi(start, EconomyManager.debt), 1)
	debt_bar.value = clampf(1.0 - float(value) / float(ref), 0.0, 1.0) * 100.0

func _on_credits_changed(new_val: int, delta: int) -> void:
	if _tween_credits and _tween_credits.is_valid():
		_tween_credits.kill()
	_tween_credits = create_tween()
	_tween_credits.tween_method(_set_credits_text, _shown_credits, new_val, 0.4)
	_shown_credits = new_val
	_spawn_delta(credits_label, delta, true)
	_update_installment()

func _on_debt_changed(new_val: int, delta: int) -> void:
	if _tween_debt and _tween_debt.is_valid():
		_tween_debt.kill()
	_tween_debt = create_tween()
	_tween_debt.tween_method(_set_debt_text, _shown_debt, new_val, 0.4)
	_shown_debt = new_val
	_spawn_delta(debt_label, delta, false)
	_update_installment()

## Small +/- number that drifts down under a value and fades. Sign + colour (never colour alone).
func _spawn_delta(anchor: Control, amount: int, good_when_positive: bool) -> void:
	if amount == 0 or not is_visible_in_tree():
		return
	var lbl := Label.new()
	lbl.text = ("+" if amount > 0 else "") + NumberFormat.group(amount)
	var good: bool = (amount > 0) == good_when_positive
	lbl.add_theme_color_override("font_color", GamePalette.POSITIVE if good else GamePalette.NEGATIVE)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 5
	add_child(lbl)
	var origin: Vector2 = anchor.global_position - global_position + Vector2(anchor.size.x * 0.5, anchor.size.y)
	lbl.position = origin
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", origin.y + DELTA_FLOAT_PX, DELTA_SEC)
	tw.tween_property(lbl, "modulate:a", 0.0, DELTA_SEC * 0.6).set_delay(DELTA_SEC * 0.4)
	tw.chain().tween_callback(lbl.queue_free)

# ---------------------------------------------------------------- the rest

func _on_action_points_changed(cur: int, max_val: int) -> void:
	ap_label.text = _tag(ap_icon, "HUD_AP") + "%d/%d" % [cur, max_val]
	var base: Array[int] = [max_val]
	ap_pips.set_state(cur, maxi(max_val, cur), base)

func _on_day_started(day: int) -> void:
	day_label.text = tr("HUD_DAY") + " %d/%d" % [day, Balance.cfg.campaign_days]
	day_pips.set_state(day, Balance.cfg.campaign_days, Balance.cfg.installment_days)
	_update_installment()
	_update_strikes()

func _on_tech_points_changed(val: int) -> void:
	tp_label.text = _tag(tp_icon, "HUD_TP") + str(val)

func _on_locale_changed(_loc: String) -> void:
	_update_all()

func _on_strike_issued(_strikes: int) -> void:
	_update_strikes()

func _on_settings_changed() -> void:
	_update_installment() # re-evaluates the pulse (reduced flashing)

func _update_strikes() -> void:
	strike_pips.set_state(EconomyManager.strikes, Balance.cfg.max_strikes)
	strike_pips.tooltip_text = tr("MORNING_STRIKES_WARNING") + " %d/%d" % [EconomyManager.strikes, Balance.cfg.max_strikes]

## Next installment STRICTLY after today (today's was already charged this morning).
func _update_installment() -> void:
	var next_day: int = -1
	for d in Balance.cfg.installment_days:
		if d > TimeManager.day:
			next_day = d
			break
	if next_day == -1 or EconomyManager.debt <= 0:
		installment_label.text = tr("HUD_NEXT_INSTALLMENT") + ": " + tr("COMMON_NONE")
		installment_label.add_theme_color_override("font_color", GamePalette.NEUTRAL_TEXT)
		installment_bar.visible = false
		_set_pulse(false)
		return
	var due: int = EconomyManager.next_installment_amount()
	var have: int = EconomyManager.credits
	var near: bool = next_day - TimeManager.day <= NEAR_DUE_DAYS
	var short: bool = have < due
	var prefix: String = "! " if (near and short) else ""
	installment_label.text = prefix + tr("HUD_NEXT_INSTALLMENT") + ": " + tr("HUD_DAY") + " %d - %s" % [next_day, NumberFormat.format_credits(due)]
	installment_label.add_theme_color_override("font_color", GamePalette.NEGATIVE if (near and short) else GamePalette.ACCENT)
	installment_bar.visible = true
	installment_bar.value = clampf(float(have) / float(maxi(1, due)), 0.0, 1.0) * 100.0
	installment_bar.tooltip_text = NumberFormat.format_credits(have) + " / " + NumberFormat.format_credits(due)
	var fill: StyleBoxFlat = _fill_ok
	if short:
		fill = _fill_late if near else _fill_warn
	installment_bar.add_theme_stylebox_override("fill", fill)
	_set_pulse(near and short)

func _set_pulse(wanted: bool) -> void:
	var on: bool = wanted and not SettingsManager.reduced_flashing
	if on == _pulsing:
		return
	_pulsing = on
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	center_panel.modulate = Color.WHITE
	if on:
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(center_panel, "modulate", Color(1.0, 0.75, 0.75), 0.5)
		_pulse_tween.tween_property(center_panel, "modulate", Color.WHITE, 0.5)
