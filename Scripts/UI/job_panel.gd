# purpose: [v3] One active contract in the workshop: header, materials/power/quality line, the blueprint preview and the part cells. v3: the PATH contract (Champion Build) is unmistakable: thick magenta border + dark purple background, a pulsing "[★] PATH GOAL" banner, and a status line (progress, quality needed, entry fee, deadline) with a Register button when the build is ready. v2: the preview comes from ItemPreview.create(job) into PreviewHolder. All text is clipped, so a long language can never widen the screen.
# depends on: PanelContainer, CommissionState, ItemPreview, PartCell, CommissionManager, NumberFormat, GamePalette, SettingsManager
# signals emitted: part_clicked(job, part_index), sim_clicked(job, part_index), reforge_clicked(part_index)
# signals listened to: PartCell.part_pressed, sim_pressed, reforge_pressed, RegisterButton.pressed

class_name JobPanel
extends PanelContainer

signal part_clicked(job: CommissionState, part_index: int)
signal sim_clicked(job: CommissionState, part_index: int)
signal reforge_clicked(part_index: int)

const PART_CELL_SCENE = preload("res://Scenes/UI/part_cell.tscn")
const CHAMPION_BG: Color = Color(0.16, 0.08, 0.22, 1.0)

@onready var champion_banner: Label = %ChampionBanner
@onready var header_label: Label = %HeaderLabel
@onready var stats_label: Label = %StatsLabel
@onready var preview_holder: CenterContainer = %PreviewHolder
@onready var champion_row: HBoxContainer = %ChampionRow
@onready var champion_status: Label = %ChampionStatus
@onready var register_button: Button = %RegisterButton
@onready var parts_row: HFlowContainer = %PartsRow

var _job: CommissionState

func _ready() -> void:
	register_button.pressed.connect(_on_register_pressed)

## Call AFTER add_child. pop_index = part that just finished (plays the snap-in animation), -1 = none.
func setup(job: CommissionState, pop_index: int = -1) -> void:
	_job = job
	_style_for(job)
	_fill_texts(job)
	_fill_champion(job)
	for child in preview_holder.get_children():
		preview_holder.remove_child(child)
		child.queue_free()
	var preview: ItemPreview = ItemPreview.create(job)
	preview_holder.add_child(preview) # in the tree first: the preview's @onready nodes must exist
	preview.setup(job, pop_index)
	for child in parts_row.get_children():
		parts_row.remove_child(child)
		child.queue_free()
	for i in range(job.parts.size()):
		var cell: PartCell = PART_CELL_SCENE.instantiate()
		parts_row.add_child(cell)
		cell.setup(job, i)
		cell.part_pressed.connect(_on_part_pressed)
		cell.sim_pressed.connect(_on_sim_pressed)
		cell.reforge_pressed.connect(_on_reforge_pressed)

## The path contract looks different from every other job: border, background and a banner (never colour alone).
func _style_for(job: CommissionState) -> void:
	var champion: bool = job.data.is_champion_build
	champion_banner.visible = champion
	if champion:
		var sb := StyleBoxFlat.new()
		sb.bg_color = CHAMPION_BG
		sb.border_color = GamePalette.NEON_MAGENTA
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(2)
		sb.set_content_margin_all(2)
		add_theme_stylebox_override("panel", sb)
		if not SettingsManager.reduced_flashing:
			var tw: Tween = champion_banner.create_tween().set_loops()
			tw.tween_property(champion_banner, "modulate:a", 0.55, 0.7)
			tw.tween_property(champion_banner, "modulate:a", 1.0, 0.7)
	else:
		remove_theme_stylebox_override("panel")

func _fill_champion(job: CommissionState) -> void:
	champion_row.visible = job.data.is_champion_build
	register_button.visible = false
	if not job.data.is_champion_build:
		return
	var cfg: BalanceConfig = Balance.cfg
	var need: int = roundi(cfg.champion_min_quality * 100.0)
	var vars: Dictionary = {
		"done": _done_count(job), "total": job.parts.size(), "need": need,
		"fee": NumberFormat.format_credits(cfg.champion_build_sponsorship),
		"deadline": cfg.champion_deadline_day, "now": roundi(job.calculate_quality() * 100.0),
	}
	var text: String = ""
	var color: Color = GamePalette.NEUTRAL_TEXT
	if TimeManager.day > cfg.champion_deadline_day:
		text = GamePalette.ICON_FAIL + NumberFormat.render(tr("CHAMPION_STATUS_CLOSED"), vars)
		color = GamePalette.NEGATIVE
	elif job.is_complete():
		if job.calculate_quality() >= cfg.champion_min_quality:
			text = GamePalette.ICON_PASS + NumberFormat.render(tr("CHAMPION_STATUS_READY"), vars)
			color = GamePalette.POSITIVE
			register_button.visible = true
			register_button.text = NumberFormat.render(tr("CHAMPION_REGISTER"), vars)
		else:
			text = GamePalette.ICON_WARN + NumberFormat.render(tr("CHAMPION_STATUS_LOW"), vars)
			color = GamePalette.ACCENT
	else:
		text = GamePalette.ICON_INFO + NumberFormat.render(tr("CHAMPION_STATUS_PROGRESS"), vars)
	champion_status.text = text
	champion_status.add_theme_color_override("font_color", color)

func _done_count(job: CommissionState) -> int:
	var n: int = 0
	for s in job.part_scores:
		if s >= 0.0:
			n += 1
	return n

func _fill_texts(job: CommissionState) -> void:
	if job.data.is_champion_build:
		header_label.text = "T%d %s" % [job.tier, tr(job.data.title_key)]
		if job.is_complete():
			header_label.text += " | %s %d%% / %d%%" % [tr("WORKSHOP_QUALITY"), roundi(job.calculate_quality() * 100.0), roundi(Balance.cfg.champion_min_quality * 100.0)]
	else:
		var due: String = tr("OFFER_DEADLINE") + " " + tr("HUD_DAY") + " %d" % job.deadline_day
		header_label.text = "T%d %s | %s | %s" % [job.tier, tr(job.data.title_key), NumberFormat.format_credits(job.payout), due]
	header_label.tooltip_text = header_label.text

	var draw: float = job.total_power_draw()
	var limit: float = job.data.power_limit_watts
	var over: bool = limit > 0.0 and draw > limit and not job.data.is_champion_build
	var bits: Array[String] = []
	bits.append("%s %s / %s" % [tr("WORKSHOP_MATERIALS"), NumberFormat.format_credits(job.materials_spent), NumberFormat.format_credits(job.budget_cap)])
	if limit > 0.0 and not job.data.is_champion_build:
		bits.append(("! " if over else "") + "%s %d / %d W" % [tr("WORKSHOP_POWER"), roundi(draw), roundi(limit)])
	if job.has_finished_part():
		bits.append("%s %d%%" % [tr("WORKSHOP_QUALITY"), roundi(job.calculate_quality() * 100.0)])
	stats_label.text = "  |  ".join(bits)
	stats_label.tooltip_text = stats_label.text
	stats_label.add_theme_color_override("font_color", GamePalette.NEGATIVE if over else GamePalette.ACCENT)

## Registers the build now (pays the entry fee). On success the popup plays and this panel disappears.
func _on_register_pressed() -> void:
	if CommissionManager.register_champion_now():
		queue_free()
		return
	var fee: String = NumberFormat.format_credits(Balance.cfg.champion_build_sponsorship)
	champion_status.text = GamePalette.ICON_WARN + NumberFormat.render(tr("CHAMPION_FEE_NEEDED"), {"fee": fee, "deadline": Balance.cfg.champion_deadline_day})
	champion_status.add_theme_color_override("font_color", GamePalette.NEGATIVE)

func _on_part_pressed(part_index: int) -> void:
	part_clicked.emit(_job, part_index)

func _on_sim_pressed(part_index: int) -> void:
	sim_clicked.emit(_job, part_index)

func _on_reforge_pressed(part_index: int) -> void:
	reforge_clicked.emit(part_index)
