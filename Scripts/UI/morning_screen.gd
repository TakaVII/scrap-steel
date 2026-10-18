# purpose: [v3 manual fix] Morning briefing. Now refreshes with final data (GameManager announces MORNING last), shows the REAL installment result, enforces max negotiations per day, and gives feedback when a job cannot be accepted.
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
# Not marked as unique in the scene (v1 draft): referenced by path. Mark it unique later if you edit the scene.
@onready var instruction_label: Label = $MarginContainer/VBoxContainer/HBoxBottom/InstructionLabel

func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	if barter_panel:
		barter_panel.barter_resolved.connect(_on_barter_resolved)

func _on_phase_changed(new_phase: int, _old_phase: int) -> void:
	if new_phase == GameManager.Phase.MORNING:
		_refresh_morning_data()

func _refresh_morning_data() -> void:
	morning_title_label.text = tr("MORNING_TITLE") + " - " + tr("HUD_DAY") + " %d" % TimeManager.day
	rent_info_label.text = tr("MORNING_RENT_CHARGED") + ": %d cr" % Balance.cfg.daily_rent
	instruction_label.text = tr("MORNING_HINT")

	var inst: Dictionary = EconomyManager.last_installment
	if inst.get("day", -1) == TimeManager.day:
		var short: bool = int(inst["paid"]) < int(inst["due"])
		installment_info_label.text = (GamePalette.ICON_WARN if short else GamePalette.ICON_PASS) + tr("MORNING_INSTALLMENT_DUE") + ": %d / %d cr" % [inst["paid"], inst["due"]]
		installment_info_label.add_theme_color_override("font_color", GamePalette.NEGATIVE if short else GamePalette.POSITIVE)
		installment_info_label.visible = true
	else:
		installment_info_label.visible = false

	if EconomyManager.strikes > 0:
		strikes_warning_label.text = GamePalette.ICON_WARN + tr("MORNING_STRIKES_WARNING") + ": %d / %d" % [EconomyManager.strikes, Balance.cfg.max_strikes]
		strikes_warning_label.visible = true
	else:
		strikes_warning_label.visible = false

	for child in contracts_container.get_children():
		child.queue_free()
	for offer in CommissionManager.offers:
		var card = CONTRACT_CARD_SCENE.instantiate()
		contracts_container.add_child(card)
		card.setup(offer)
		card.barter_requested.connect(_on_barter_requested)
		card.accept_direct.connect(_on_accept_direct)

func _on_barter_requested(offer_id: int) -> void:
	if CommissionManager.inspections_used_today >= Balance.cfg.max_inspections_per_day:
		instruction_label.text = tr("MORNING_NEGOTIATIONS_USED")
		return
	for offer in CommissionManager.offers:
		if offer.id == offer_id:
			CommissionManager.inspections_used_today += 1
			barter_panel.open_for_offer(offer)
			break

func _try_accept(offer_id: int, choice: int) -> void:
	if not CommissionManager.accept_offer(offer_id, choice):
		instruction_label.text = tr("MORNING_MAX_JOBS")
		return
	_refresh_morning_data()

func _on_accept_direct(offer_id: int) -> void:
	_try_accept(offer_id, CommissionData.Barter.NONE)

func _on_barter_resolved(offer_id: int, choice: int) -> void:
	_try_accept(offer_id, choice)

func _on_open_shop_button_pressed() -> void:
	GameManager.begin_workshop()
