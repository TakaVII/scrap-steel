# purpose: [v5] Workshop. v5: every contract shows payout, due day, materials vs budget, power draw vs limit (with a "!" when over) and current quality; starting a part opens the material GRADE picker; today's market price is shown; part buttons show tier-based AP. Keeps: part button signal binding, start checks with feedback, Champion Build re-forge buttons, debug-only dev-sim button.
# depends on: Control, GameManager, TimeManager, CommissionManager, MinigameController, CraftingManager, EconomyManager, GradePicker, MaterialGrade, PartResult
# signals emitted: none
# signals listened to: EventBus.action_points_changed, EventBus.phase_changed, EventBus.minigame_finished

extends Control

const PART_BUTTON_SCENE = preload("res://Scenes/UI/part_button.tscn")

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
	_picker = GradePicker.new()
	add_child(_picker)
	_picker.picked.connect(_on_grade_picked)
	_update_ui()

func _on_phase_changed(new_phase: int, _old_phase: int) -> void:
	if new_phase == GameManager.Phase.WORKSHOP:
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
	ap_display_label.text = tr("WORKSHOP_TITLE") + " | " + tr("HUD_AP") + ": %d / %d" % [TimeManager.ap, TimeManager.ap_max] + " | " + _market_text()
	overtime_button.disabled = not TimeManager.can_take_overtime()

	for child in active_jobs_container.get_children():
		child.queue_free()

	var jobs: Array[CommissionState] = CommissionManager.active_jobs()
	if jobs.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = tr("WORKSHOP_NO_JOBS")
		active_jobs_container.add_child(empty_lbl)
		return

	for job in jobs:
		active_jobs_container.add_child(_build_job_panel(job))
	_pop_job = null
	_pop_idx = -1

func _build_job_panel(job: CommissionState) -> PanelContainer:
	var job_panel := PanelContainer.new()
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 3)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var header := Label.new()
	header.clip_text = true
	if job.data.is_champion_build:
		header.text = "T%d %s" % [job.tier, tr(job.data.title_key)]
		if job.is_complete():
			header.text += " | Q %d%% / %d%%" % [roundi(job.calculate_quality() * 100.0), roundi(Balance.cfg.champion_min_quality * 100.0)]
	else:
		var due: String = tr("OFFER_DEADLINE") + " " + tr("HUD_DAY") + " %d" % job.deadline_day
		header.text = "T%d %s | %s | %s" % [job.tier, tr(job.data.title_key), NumberFormat.format_credits(job.payout), due]
	vbox.add_child(header)

	var stats := Label.new()
	stats.clip_text = true
	var draw: float = job.total_power_draw()
	var limit: float = job.data.power_limit_watts
	var over: bool = limit > 0.0 and draw > limit and not job.data.is_champion_build
	var bits: Array[String] = []
	bits.append("%s %s / %s" % [tr("WORKSHOP_MATERIALS"), NumberFormat.format_credits(job.materials_spent), NumberFormat.format_credits(job.budget_cap)])
	if limit > 0.0 and not job.data.is_champion_build:
		bits.append(("! " if over else "") + "%s %d / %d W" % [tr("WORKSHOP_POWER"), roundi(draw), roundi(limit)])
	if job.has_finished_part():
		bits.append("%s %d%%" % [tr("WORKSHOP_QUALITY"), roundi(job.calculate_quality() * 100.0)])
	stats.text = "  |  ".join(bits)
	stats.add_theme_color_override("font_color", GamePalette.NEGATIVE if over else GamePalette.ACCENT)
	vbox.add_child(stats)

	var preview := ItemPreview.new()
	vbox.add_child(preview)
	preview.setup(job, _pop_idx if job == _pop_job else -1)

	var parts_row := HFlowContainer.new()
	parts_row.add_theme_constant_override("h_separation", 4)
	parts_row.add_theme_constant_override("v_separation", 2)
	for part_idx in range(job.parts.size()):
		parts_row.add_child(_build_part_cell(job, part_idx))
	vbox.add_child(parts_row)

	margin.add_child(vbox)
	job_panel.add_child(margin)
	return job_panel

func _build_part_cell(job: CommissionState, part_idx: int) -> VBoxContainer:
	var part: ItemPartData = job.parts[part_idx]
	var part_score: float = job.part_scores[part_idx]
	var grade: int = job.part_grades[part_idx] if part_idx < job.part_grades.size() else -1
	var quality: float = job.part_quality[part_idx] if part_idx < job.part_quality.size() else -1.0
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 1)

	var btn: Button = PART_BUTTON_SCENE.instantiate()
	cell.add_child(btn)
	btn.setup(part_idx, part, part_score, job.tier, CraftingManager.max_part_cost(job, part_idx), CraftingManager.part_ap(job, part_idx), grade, quality)
	btn.part_selected.connect(_on_part_clicked.bind(job)) # signal passes part_index; bind adds job

	if part_score < 0.0 and OS.is_debug_build():
		var sim_btn := Button.new()
		sim_btn.text = tr("WORKSHOP_DEV_SIM")
		sim_btn.custom_minimum_size = Vector2(0, 14)
		sim_btn.pressed.connect(_on_dev_sim_clicked.bind(job, part_idx))
		cell.add_child(sim_btn)

	if job.data.is_champion_build and CommissionManager.can_reforge_champion_part(part_idx):
		var re_btn := Button.new()
		re_btn.text = tr("WORKSHOP_REFORGE_BTN")
		re_btn.custom_minimum_size = Vector2(0, 14)
		re_btn.pressed.connect(_on_reforge_clicked.bind(part_idx))
		cell.add_child(re_btn)
	return cell

func _on_part_clicked(part_idx: int, job: CommissionState) -> void:
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
