# purpose: [v2 manual fix] R&D upgrade card. Fixes broken "%s"/"%d" formatting (translations contain the placeholders) and uses the run's real interest rate.
# depends on: Control, UpgradeData, UpgradeManager, EconomyManager
# signals emitted: buy_requested(id: StringName)
# signals listened to: none

extends PanelContainer

signal buy_requested(id: StringName)

@onready var title_label: Label = %TitleLabel
@onready var desc_label: Label = %DescLabel
@onready var cost_label: Label = %CostLabel
@onready var payback_label: Label = %PaybackLabel
@onready var debt_compare_label: Label = %DebtCompareLabel
@onready var buy_button: Button = %BuyButton

var _upgrade_id: StringName = &""

func setup(data: UpgradeData) -> void:
	_upgrade_id = data.id
	title_label.text = tr(data.title_key)
	desc_label.text = tr(data.desc_key)
	cost_label.text = "%d cr  |  %d TP" % [data.cost_credits, data.cost_tp]
	payback_label.text = tr("UPG_PAYBACK_PREFIX") % ("%.1f" % data.payback_days)
	debt_compare_label.text = tr("UPG_DEBT_INTEREST_COMPARE") % EconomyManager.projected_interest()
	_update_state()

func _update_state() -> void:
	if UpgradeManager.has_upgrade(_upgrade_id):
		buy_button.text = tr("UPG_OWNED")
		buy_button.disabled = true
	else:
		buy_button.text = tr("UPG_PURCHASE")
		buy_button.disabled = not UpgradeManager.can_purchase(_upgrade_id)

func _on_buy_button_pressed() -> void:
	buy_requested.emit(_upgrade_id)
