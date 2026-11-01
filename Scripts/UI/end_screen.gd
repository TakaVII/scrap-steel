# purpose: [v5] End screen. v5: the "Day" word in the stats line is translated (HUD_DAY). v4: "RANK" label is translated (END_RANK). v3: Restart button returns to the MAIN MENU.
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
		rank_label.text = tr("END_RANK") + " " + GameManager.calculate_final_rank()
		stats_label.text = "%s | %d cr | %s %d | %.1f*" % [
			String(GameManager.pathway).to_upper(), EconomyManager.credits,
			tr("HUD_DAY"), GameManager.debt_cleared_day, CommissionManager.shop_rating() * 5.0
		]
	else:
		if reason == &"seized":
			title_label.text = tr("END_GAME_OVER_TITLE")
			desc_label.text = tr("END_SEIZED_DESC")
		else:
			title_label.text = tr("END_TIMEOUT_TITLE")
			desc_label.text = tr("END_TIMEOUT_DESC")
		rank_label.text = ""
		stats_label.text = "%s: %d cr | %s: %d / %d | %d cr" % [
			tr("HUD_DEBT"), EconomyManager.debt, tr("MORNING_STRIKES_WARNING"),
			EconomyManager.strikes, Balance.cfg.max_strikes, EconomyManager.net_worth()
		]

func _on_restart_button_pressed() -> void:
	GameManager.return_to_menu()
