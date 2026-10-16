# purpose: [v2] Morning briefing screen hosting ContractCard instances, BarterPanel, lease billing, and installment warnings.
# depends on: Control, GameManager, EconomyManager, TimeManager, CommissionManager, Balance
# signals emitted: none
# signals listened to: EventBus.phase_changed

extends Control

const CONTRACT_CARD_SCENE = preload("res://Scenes/UI/contract_card.tscn")

@onready var morning_title_label: Label = %MorningTitleLabel
@onready var rent_info_label: Label = %RentInfoLabel
@onready var installment_info_label: Label = %InstallmentInfoLabel
@onready var strikes_warning_label: Label = %StrikesWarningLabel
@onready var contracts_container: HBoxContainer = %ContractsContainer
@onready var barter_panel: Control = %BarterPanel
@onready var open_shop_button: Button = %OpenShopButton

func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	if barter_panel:
		barter_panel.barter_resolved.connect(_on_barter_resolved)

func _on_phase_changed(new_phase: int, _old_phase: int) -> void:
	if new_phase == GameManager.Phase.MORNING:
		_refresh_morning_data()

func _refresh_morning_data() -> void:
	morning_title_label.text = tr("MORNING_TITLE") + " — " + tr("HUD_DAY") + " %d" % TimeManager.day
	rent_info_label.text = tr("MORNING_RENT_CHARGED") + ": %d cr" % Balance.cfg.daily_rent

	if Balance.cfg.installment_days.has(TimeManager.day):
		var due: int = maxi(Balance.cfg.installment_min, roundi(EconomyManager.debt * Balance.cfg.installment_pct))
		installment_info_label.text = tr("MORNING_INSTALLMENT_DUE") + ": %d cr" % mini(due, EconomyManager.debt)
		installment_info_label.visible = true
	else:
		installment_info_label.visible = false

	if EconomyManager.strikes > 0:
		strikes_warning_label.text = tr("MORNING_STRIKES_WARNING") + ": %d / %d" % [EconomyManager.strikes, Balance.cfg.max_strikes]
		strikes_warning_label.visible = true
	else:
		strikes_warning_label.visible = false

	# Clear and rebuild contract offers
	for child in contracts_container.get_children():
		child.queue_free()

	for offer in CommissionManager.offers:
		var card = CONTRACT_CARD_SCENE.instantiate()
		contracts_container.add_child(card)
		card.setup(offer)
		card.barter_requested.connect(_on_barter_requested)
		card.accept_direct.connect(_on_accept_direct)

func _on_barter_requested(offer_id: int) -> void:
	for offer in CommissionManager.offers:
		if offer.id == offer_id:
			barter_panel.open_for_offer(offer)
			break

func _on_accept_direct(offer_id: int) -> void:
	CommissionManager.accept_offer(offer_id, CommissionData.Barter.NONE)
	_refresh_morning_data()

func _on_barter_resolved(offer_id: int, choice: int) -> void:
	CommissionManager.accept_offer(offer_id, choice)
	_refresh_morning_data()

func _on_open_shop_button_pressed() -> void:
	GameManager.begin_workshop()
