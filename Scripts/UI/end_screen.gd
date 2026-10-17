# purpose: [v2] End screen displaying victory or defeat, pathway status, and final rank grade (S/A/B/C).
# depends on: Control, GameManager, EconomyManager, CommissionManager
# signals emitted: none
# signals listened to: EventBus.run_ended

extends Control

@onready var title_label: Label = %TitleLabel
@onready var desc_label: Label = %DescLabel
@onready var rank_label: Label = %RankLabel
@onready var stats_label: Label = %StatsLabel
@onready var restart_button: Button = %RestartButton

func _ready() -> void:
	EventBus.run_ended.connect(_on_run_ended)

func _on_run_ended(victory: bool, reason: StringName) -> void:
	if victory:
		title_label.text = tr("END_VICTORY_TITLE")
		desc_label.text = tr("END_VICTORY_DESC")
		var rank: String = GameManager.calculate_final_rank()
		rank_label.text = "FINAL GRADE: RANK " + rank
		stats_label.text = "Pathway: %s | Closing Cash: %d cr | Debt: 0 cr | Cleared on Day %d | Rating: %.1f★" % [
			GameManager.pathway.to_upper(), EconomyManager.credits, GameManager.debt_cleared_day, CommissionManager.shop_rating() * 5.0
		]
	else:
		if reason == &"seized":
			title_label.text = tr("END_GAME_OVER_TITLE")
			desc_label.text = tr("END_SEIZED_DESC")
		else:
			title_label.text = tr("END_TIMEOUT_TITLE")
			desc_label.text = tr("END_TIMEOUT_DESC")

		rank_label.text = "FINAL GRADE: FAILED"
		stats_label.text = "Debt Remaining: %d cr | Strikes: %d / 3 | Net Worth: %d cr" % [
			EconomyManager.debt, EconomyManager.strikes, EconomyManager.net_worth()
		]

func _on_restart_button_pressed() -> void:
	GameManager.start_new_run()
