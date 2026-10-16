# purpose: Interactive bartering panel displaying the 3 financial options (Deposit, Profit Share, Rush) and terms preview.
# depends on: Control, CommissionData, NumberFormat, CommissionManager
# signals emitted: barter_resolved(offer_id: int, choice: int), cancelled()
# signals listened to: none

extends Control

signal barter_resolved(offer_id: int, choice: int)
signal cancelled()

@onready var preview_title_label: Label = %PreviewTitleLabel
@onready var preview_desc_label: Label = %PreviewDescLabel
@onready var inspections_label: Label = %InspectionsLabel

var current_offer: CommissionData

func open_for_offer(offer: CommissionData) -> void:
	current_offer = offer
	visible = true
	inspections_label.text = "Negotiations Left Today: %d / 3" % (3 - CommissionManager.inspections_used_today)
	_on_option_standard_hover()

func _on_option_standard_hover() -> void:
	preview_title_label.text = "Standard Contract Terms"
	preview_desc_label.text = "Standard delivery. Full payout paid upon completion according to delivered quality."

func _on_option_deposit_hover() -> void:
	preview_title_label.text = "Option A: Advance Cash Flow Deposit"
	preview_desc_label.text = "+20% of payout paid immediately to finance components. Final payout reduced by 10%."

func _on_option_profit_share_hover() -> void:
	preview_title_label.text = "Option B: Equity Profit Sharing"
	preview_desc_label.text = "Tight material budget cap (x0.85). Payout x1.30 if Quality >= 90%, but penalized x0.90 if Quality < 75%."

func _on_option_rush_hover() -> void:
	preview_title_label.text = "Option C: Rush Delivery"
	preview_desc_label.text = "+25% premium payout bonus, but deadline strictly compressed to exactly 1 day."

func _on_deposit_button_pressed() -> void:
	if current_offer:
		barter_resolved.emit(current_offer.id, CommissionData.Barter.ADVANCE_DEPOSIT)
		visible = false

func _on_profit_share_button_pressed() -> void:
	if current_offer:
		barter_resolved.emit(current_offer.id, CommissionData.Barter.PROFIT_SHARE)
		visible = false

func _on_rush_button_pressed() -> void:
	if current_offer:
		barter_resolved.emit(current_offer.id, CommissionData.Barter.RUSH)
		visible = false

func _on_standard_button_pressed() -> void:
	if current_offer:
		barter_resolved.emit(current_offer.id, CommissionData.Barter.NONE)
		visible = false

func _on_cancel_button_pressed() -> void:
	visible = false
	cancelled.emit()
