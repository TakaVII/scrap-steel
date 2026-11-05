# purpose: [v6] Workshop. v6: the contracts are instances of Scenes/UI/job_panel.tscn (JobPanel) instead of nodes built in code; the header is one clipped line plus two short buttons, so Spanish/Arabic can no longer widen the screen. Keeps: material GRADE picker, tier-based AP, today's market price, start checks with feedback, Champion Build re-forge, debug-only dev-sim button.
# depends on: Control, GameManager, TimeManager, CommissionManager, MinigameController, CraftingManager, EconomyManager, GradePicker, MaterialGrade, PartResult, JobPanel
# signals emitted: none
# signals listened to: EventBus.action_points_changed, EventBus.phase_changed, EventBus.minigame_finished, JobPanel.part_clicked / sim_clicked / reforge_clicked

extends Control

const JOB_PANEL_SCENE = preload("res://Scenes/UI/job_panel.tscn")

@onready var ap_display_label: Label = %ApDisplayLabel
@onready var active_jobs_container: VBoxContainer = %ActiveJobsContainer
@onready var overtime_button: Button = %OvertimeButton
@onready var end_day_button: Button = %EndDayButton
@onready var status_info_label: Label = %StatusInfoLabel

var _picker: GradePicker
var _pending_job: CommissionState
var _pending_idx: int = -1
## The part that just finished: its blueprint slot plays the "snap into place" animation on the next rebuild.
var _pop_job: CommissionState = null
var _pop_idx: int = -1

func _ready() -> void:
	EventBus.action_points_changed.connect(_on_action_points_changed)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.minigame_finished.connect(_on_minigame_finished)
	EventBus.locale_changed.connect(_on_locale_changed)
	_picker = GradePicker.new()
	add_child(_picker)
	_picker.picked.connect(_on_grade_picked)
	_update_ui()

func _on_phase_changed(new_phase: int, _old_phase: int) -> void:
	if new_phase == GameManager.Phase.WORKSHOP:
		_update_ui()

func _on_locale_changed(_loc: String) -> void:
	_update_ui()

func _on_action_points_changed(_cur: int, _max: int) -> void:
	_update_ui()

func _on_minigame_finished(result: PartResult) -> void:
	_pop_job = result.commission
	_pop_idx = result.part_index
	status_info_label.text = "%s: %d%% | %s | %d cr" % [tr(result.part.display_key), roundi(result.quality * 100.0), tr(MaterialGrade.name_key(result.grade)), result.material_cost_charged]
	_update_ui()

func _reason_text(reason: StringName) -> String:
	match reason:
		&"no_ap":
			return tr("WORKSHOP_NO_AP")
		&"no_funds":
			return tr("WORKSHOP_NO_FUNDS")
		&"over_budget":
			return tr("WORKSHOP_NO_BUDGET")
	return ""

func _market_text() -> String:
	var p: int = roundi((CommissionManager.market_mult - 1.0) * 100.0)
	return NumberFormat.render(tr("GRADE_MARKET"), {"pct": ("+" if p >= 0 else "") + str(p) + "%"})

func _update_ui() -> void:
	ap_display_label.text = tr("HUD_AP") + ": %d / %d" % [TimeManager.ap, TimeManager.ap_max] + " | " + _market_text()
	ap_display_label.tooltip_text = ap_display_label.text
	overtime_button.disabled = not TimeManager.can_take_overtime()

	for child in active_jobs_container.get_children():
		child.queue_free()

	var jobs: Array[CommissionState] = CommissionManager.active_jobs()
	
	var ordered: Array[CommissionState] = []
	for j in jobs:
		if j.data.is_champion_build:
			ordered.append(j)
	for j in jobs:
		if not j.data.is_champion_build:
			ordered.append(j)
	jobs = ordered
	
	if jobs.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = tr("WORKSHOP_NO_JOBS")
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		active_jobs_container.add_child(empty_lbl)
		return

	for job in jobs:
		var panel: JobPanel = JOB_PANEL_SCENE.instantiate()
		active_jobs_container.add_child(panel)
		panel.setup(job, _pop_idx if job == _pop_job else -1)
		panel.part_clicked.connect(_on_part_clicked)
		panel.sim_clicked.connect(_on_dev_sim_clicked)
		panel.reforge_clicked.connect(_on_reforge_clicked)
	_pop_job = null
	_pop_idx = -1

func _on_part_clicked(job: CommissionState, part_idx: int) -> void:
	var reason: StringName = CraftingManager.can_start(job, part_idx)
	if reason == &"no_ap" or reason == &"done":
		status_info_label.text = _reason_text(reason)
		return
	# no_funds / over_budget at Standard may still be fine with Scrap: the picker explains each grade.
	_pending_job = job
	_pending_idx = part_idx
	status_info_label.text = ""
	_picker.open(job, part_idx)

func _on_grade_picked(grade: int) -> void:
	if _pending_job == null:
		return
	if not MinigameController.launch(_pending_job, _pending_idx, grade):
		status_info_label.text = tr("WORKSHOP_LAUNCH_FAILED")

func _on_reforge_clicked(part_idx: int) -> void:
	CommissionManager.reforge_champion_part(part_idx)
	_update_ui()

func _on_dev_sim_clicked(job: CommissionState, part_idx: int) -> void:
	var reason: StringName = CraftingManager.can_start(job, part_idx)
	if reason != &"":
		status_info_label.text = _reason_text(reason)
		return
	TimeManager.spend_ap(CraftingManager.part_ap(job, part_idx))
	var res := PartResult.new()
	res.commission = job
	res.part_index = part_idx
	res.part = job.parts[part_idx]
	res.score = randf_range(0.65, 0.95)
	CraftingManager.apply_result(res)
	EventBus.minigame_finished.emit(res)

func _on_overtime_button_pressed() -> void:
	if TimeManager.take_overtime():
		status_info_label.text = tr("WORKSHOP_OVERTIME_BTN")
	_update_ui()

func _on_end_day_button_pressed() -> void:
	GameManager.request_end_day()
