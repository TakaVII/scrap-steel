# purpose: Workshop interactive screen for spending AP on simulated parts, activating overtime, and ending the day.
# depends on: Control, GameManager, TimeManager, CommissionManager, EconomyManager
# signals emitted: none
# signals listened to: EventBus.action_points_changed

extends Control

@onready var ap_display_label: Label = %ApDisplayLabel
@onready var complete_part_button: Button = %CompletePartButton
@onready var overtime_button: Button = %OvertimeButton
@onready var end_day_button: Button = %EndDayButton
@onready var status_info_label: Label = %StatusInfoLabel

func _ready() -> void:
	EventBus.action_points_changed.connect(_on_action_points_changed)
	_update_buttons()

func _on_action_points_changed(_cur: int, _max: int) -> void:
	_update_buttons()

func _update_buttons() -> void:
	ap_display_label.text = "Workshop Active | Available AP: %d / %d" % [TimeManager.ap, TimeManager.ap_max]
	complete_part_button.disabled = TimeManager.ap < 2
	overtime_button.disabled = not TimeManager.can_take_overtime()

func _on_complete_part_button_pressed() -> void:
	status_info_label.text = "Completed simulated Tier 1 part (-2 AP, bought materials, received payout)."
	CommissionManager.simulate_part_completion(2)
	_update_buttons()

func _on_overtime_button_pressed() -> void:
	if TimeManager.take_overtime():
		status_info_label.text = "Overtime activated! +2 AP gained tonight. (-150 cr, -1 AP tomorrow)"
	else:
		status_info_label.text = "Cannot take overtime (already used or insufficient credits)."
	_update_buttons()

func _on_end_day_button_pressed() -> void:
	GameManager.request_end_day()
