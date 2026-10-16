# purpose: End screen evaluating victory, seizure, or timeout with final financial balance.
# depends on: Control, EventBus, GameManager, EconomyManager, TimeManager
# signals emitted: none
# signals listened to: EventBus.run_ended

extends Control

@onready var outcome_title_label: Label = %OutcomeTitleLabel
@onready var outcome_details_label: Label = %OutcomeDetailsLabel
@onready var final_stats_label: Label = %FinalStatsLabel

func _ready() -> void:
	EventBus.run_ended.connect(_on_run_ended)

func _on_run_ended(victory: bool, reason: StringName) -> void:
	if victory:
		outcome_title_label.text = tr("END_VICTORY_TITLE")
		outcome_details_label.text = tr("END_VICTORY_DESC")
	else:
		outcome_title_label.text = tr("END_GAME_OVER_TITLE")
		if reason == &"seized":
			outcome_details_label.text = tr("END_SEIZED_DESC")
		else:
			outcome_details_label.text = tr("END_TIMEOUT_DESC")

	final_stats_label.text = "Days: %d | Final Credits: %s | Final Debt: %s | Strikes: %d" % [
		TimeManager.day,
		NumberFormat.format_credits(EconomyManager.credits),
		NumberFormat.format_credits(EconomyManager.debt),
		EconomyManager.strikes
	]

func _on_restart_button_pressed() -> void:
	GameManager.start_new_run()
