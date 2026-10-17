# purpose: [v3] Workshop screen launching real MinigameBase instances through MinigameController with dev sim fallback.
# depends on: Control, GameManager, TimeManager, CommissionManager, MinigameController, CraftingManager, EconomyManager, PartResult
# signals emitted: none
# signals listened to: EventBus.action_points_changed, EventBus.phase_changed, EventBus.minigame_finished

extends Control

const PART_BUTTON_SCENE = preload("res://Scenes/UI/part_button.tscn")

@onready var ap_display_label: Label = %ApDisplayLabel
@onready var active_jobs_container: VBoxContainer = %ActiveJobsContainer
@onready var overtime_button: Button = %OvertimeButton
@onready var end_day_button: Button = %EndDayButton
@onready var status_info_label: Label = %StatusInfoLabel

func _ready() -> void:
	EventBus.action_points_changed.connect(_on_action_points_changed)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.minigame_finished.connect(_on_minigame_finished)
	_update_ui()

func _on_phase_changed(new_phase: int, _old_phase: int) -> void:
	if new_phase == GameManager.Phase.WORKSHOP:
		_update_ui()

func _on_action_points_changed(_cur: int, _max: int) -> void:
	_update_ui()

func _on_minigame_finished(result: PartResult) -> void:
	status_info_label.text = "Minigame complete: %s (score %.2f). Charged %d cr materials." % [
		tr(result.part.display_key), result.score, result.material_cost_charged
	]
	_update_ui()

func _update_ui() -> void:
	ap_display_label.text = "Workshop Active | Available AP: %d / %d" % [TimeManager.ap, TimeManager.ap_max]
	overtime_button.disabled = not TimeManager.can_take_overtime()

	for child in active_jobs_container.get_children():
		child.queue_free()

	var jobs = CommissionManager.active_jobs()
	if jobs.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No active contracts. Return to Morning to accept client offers."
		active_jobs_container.add_child(empty_lbl)
		return

	for job_idx in range(jobs.size()):
		var job = jobs[job_idx]
		var job_panel := PanelContainer.new()
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 6)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_right", 6)
		margin.add_theme_constant_override("margin_bottom", 4)

		var vbox := VBoxContainer.new()
		var header := Label.new()
		header.text = "[%s] %s | Payout: %d cr | Budget Spent: %d / %d cr" % [
			"T%d" % job.tier, tr(job.data.title_key), job.payout, job.materials_spent, job.budget_cap
		]
		vbox.add_child(header)

		var parts_hbox := HBoxContainer.new()
		parts_hbox.add_theme_constant_override("separation", 6)

		for part_idx in range(job.parts.size()):
			var part = job.parts[part_idx]
			var part_score = job.part_scores[part_idx]
			var part_vbox := VBoxContainer.new()

			var btn = PART_BUTTON_SCENE.instantiate()
			part_vbox.add_child(btn)
			btn.setup(part_idx, part, part_score, job.tier)
			btn.part_selected.connect(_on_part_clicked.bind(job, part_idx))

			# Developer simulation button kept as requested
			if part_score < 0.0:
				var sim_btn := Button.new()
				sim_btn.text = tr("WORKSHOP_DEV_SIM")
				sim_btn.custom_minimum_size = Vector2(0, 18)
				sim_btn.pressed.connect(_on_dev_sim_clicked.bind(job, part_idx))
				part_vbox.add_child(sim_btn)

			parts_hbox.add_child(part_vbox)

		vbox.add_child(parts_hbox)
		margin.add_child(vbox)
		job_panel.add_child(margin)
		active_jobs_container.add_child(job_panel)

func _on_part_clicked(part_idx: int, job: CommissionState) -> void:
	var part = job.parts[part_idx]
	if not TimeManager.has_ap(part.ap_cost):
		status_info_label.text = "Insufficient AP to launch minigame."
		return

	# Launch real minigame via MinigameController
	if not MinigameController.launch(job, part_idx):
		status_info_label.text = "Failed to launch minigame."

func _on_dev_sim_clicked(job: CommissionState, part_idx: int) -> void:
	var part = job.parts[part_idx]
	if not TimeManager.has_ap(part.ap_cost):
		status_info_label.text = "Insufficient AP for simulation."
		return
	TimeManager.spend_ap(part.ap_cost)
	var fake_score: float = randf_range(0.65, 0.95)
	var res := PartResult.new()
	res.commission = job
	res.part_index = part_idx
	res.part = part
	res.score = fake_score
	CraftingManager.apply_result(res)
	EventBus.minigame_finished.emit(res)

func _on_overtime_button_pressed() -> void:
	if TimeManager.take_overtime():
		status_info_label.text = "Overtime activated! +2 AP gained tonight."
	else:
		status_info_label.text = "Cannot take overtime (already used or insufficient credits)."
	_update_ui()

func _on_end_day_button_pressed() -> void:
	GameManager.request_end_day()
