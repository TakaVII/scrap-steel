# purpose: [v3] Contract offer card with redundant archetype shape badges ([▲ MECH], [● DRIFT], [◆ CYBER]) and GamePalette (spec §C10).
# depends on: Control, CommissionData, NumberFormat, GamePalette
# signals emitted: barter_requested(offer_id: int), accept_direct(offer_id: int)
# signals listened to: none

extends PanelContainer

signal barter_requested(offer_id: int)
signal accept_direct(offer_id: int)

@onready var title_label: Label = %TitleLabel
@onready var type_badge: Label = %TypeBadge
@onready var tier_badge: Label = %TierBadge
@onready var payout_label: Label = %PayoutLabel
@onready var budget_cap_label: Label = %BudgetCapLabel
@onready var margin_label: Label = %MarginLabel
@onready var credits_per_ap_label: Label = %CreditsPerApLabel
@onready var deadline_label: Label = %DeadlineLabel
@onready var power_limit_label: Label = %PowerLimitLabel
@onready var ap_label: Label = %ApLabel

var offer_data: CommissionData

func setup(data: CommissionData) -> void:
	offer_data = data
	title_label.text = tr(data.title_key)
	tier_badge.text = "[◆ T%d]" % data.tier

	match data.type:
		CommissionData.Type.CAR:
			type_badge.text = "[● DRIFT CAR]"
			type_badge.add_theme_color_override("font_color", GamePalette.ACCENT)
		CommissionData.Type.MECH:
			type_badge.text = "[▲ MECH]"
			type_badge.add_theme_color_override("font_color", GamePalette.NEON_CYAN)
		CommissionData.Type.CYBER:
			type_badge.text = "[◆ CYBERWARE]"
			type_badge.add_theme_color_override("font_color", GamePalette.NEON_MAGENTA)

	payout_label.text = "[✓] " + NumberFormat.format_credits(data.base_payout)
	payout_label.add_theme_color_override("font_color", GamePalette.POSITIVE)

	budget_cap_label.text = "Max Mat: %d cr" % data.budget_cap
	ap_label.text = "%d AP" % data.total_ap
	deadline_label.text = "%d Days" % data.deadline_days
	power_limit_label.text = "< %d W" % int(data.power_limit_watts)

	var est_mat: int = int(round(data.base_payout * 0.50))
	var est_profit: int = data.base_payout - est_mat
	var margin_pct: float = float(est_profit) / float(data.base_payout)
	margin_label.text = "Margin: ~%d%%" % int(round(margin_pct * 100.0))
	margin_label.add_theme_color_override("font_color", GamePalette.POSITIVE)

	var cr_per_ap: int = int(round(float(data.base_payout) / float(maxi(1, data.total_ap))))
	credits_per_ap_label.text = "%d cr/AP" % cr_per_ap

func _on_barter_button_pressed() -> void:
	if offer_data:
		barter_requested.emit(offer_data.id)

func _on_accept_button_pressed() -> void:
	if offer_data:
		accept_direct.emit(offer_data.id)
