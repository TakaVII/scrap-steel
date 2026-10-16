# purpose: Morning briefing screen displaying fixed lease deductions, syndicate installments, and strikes warnings.
# depends on: Control, GameManager, EconomyManager, TimeManager, Balance
# signals emitted: none
# signals listened to: EventBus.phase_changed

extends Control

@onready var morning_title_label: Label = %MorningTitleLabel
@onready var rent_info_label: Label = %RentInfoLabel
@onready var installment_info_label: Label = %InstallmentInfoLabel
@onready var strikes_warning_label: Label = %StrikesWarningLabel
@onready var offers_count_label: Label = %OffersCountLabel

func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)

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

	offers_count_label.text = tr("MORNING_NEW_OFFERS") + ": 4 " + tr("COMMON_AVAILABLE")

func _on_open_shop_button_pressed() -> void:
	GameManager.begin_workshop()
