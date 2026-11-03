# purpose: One part slot inside an item preview (scene: Scenes/UI/part_slot.tscn). Ghost until the part is built; then it shows the part icon with the QUALITY made visible: rust + cracks + rattle when poor, clean when good, pulsing glow ring when excellent, the material-grade badge, the tier frame and the quality %. pop = plays the "snap into place" animation (scale pop, white flash, sparks, sound). Layout, sizes, particle settings and the glow material live in the SCENE: tune them there. Textures are chosen here because they depend on the part, tier and grade.
# depends on: Control, ItemPreview, CommissionState, SpriteKit, GamePalette, Juice, Sfx, SettingsManager
# signals emitted: none
# signals listened to: none

class_name PartSlot
extends Control

const PARTS: String = "res://Assets/Textures/Parts/"
const FX: String = "res://Assets/Textures/Minigames/"
## Keep in sync with the root size of part_slot.tscn (the preview centres the slot on its marker with it).
const SLOT_PX: float = 28.0
const TIER_FRAMES: Array[String] = ["frame_tier1_scrap.png", "frame_tier2_standard.png", "frame_tier3_prototype.png"]
const GRADE_BADGES: Array[String] = ["badge_grade_scrap.png", "badge_grade_standard.png", "badge_grade_premium.png"]
const Q_POOR: float = 0.50
const Q_OK: float = 0.75
const Q_GREAT: float = 0.90

@onready var backdrop: ColorRect = %Backdrop
@onready var slot_bg: TextureRect = %SlotBg
@onready var holder: Control = %Holder
@onready var ring: TextureRect = %Ring
@onready var icon: TextureRect = %Icon
@onready var fallback_label: Label = %FallbackLabel
@onready var frame: TextureRect = %Frame
@onready var rust: TextureRect = %Rust
@onready var crack: TextureRect = %Crack
@onready var badge: TextureRect = %Badge
@onready var flash: ColorRect = %Flash
@onready var quality_label: Label = %QualityLabel
@onready var sparks: CPUParticles2D = %Sparks

## Call AFTER add_child (the @onready nodes must exist).
func setup(job: CommissionState, idx: int, pop: bool) -> void:
	var part: ItemPartData = job.parts[idx]
	var done: bool = job.part_scores[idx] >= 0.0
	var q: float = -1.0
	if done:
		q = job.part_quality[idx] if idx < job.part_quality.size() and job.part_quality[idx] >= 0.0 else Balance.cfg.part_quality(job.tier, job.part_scores[idx])
	var grade: int = job.part_grades[idx] if idx < job.part_grades.size() else -1
	tooltip_text = tr(part.display_key) + (" - %d%%" % roundi(q * 100.0) if done else "")

	var bg_tex: Texture2D = SpriteKit.tex(PARTS + "slot_empty.png")
	slot_bg.visible = bg_tex != null
	slot_bg.texture = bg_tex
	backdrop.visible = bg_tex == null

	var icon_tex: Texture2D = SpriteKit.tex(PARTS + "part_%s.png" % String(part.part_id))
	icon.visible = icon_tex != null
	icon.texture = icon_tex
	fallback_label.visible = icon_tex == null
	fallback_label.text = String(part.part_id).substr(0, 3).to_upper()
	icon.modulate = Color.WHITE if done else Color(0.55, 0.55, 0.70, 0.45) # ghost: not built yet
	fallback_label.modulate = Color.WHITE if done else Color(0.5, 0.5, 0.6, 0.6)

	var frame_tex: Texture2D = SpriteKit.tex(PARTS + TIER_FRAMES[clampi(job.tier - 1, 0, 2)])
	frame.visible = frame_tex != null
	frame.texture = frame_tex

	# Glow ring behind the icon: only for excellent work.
	var ring_tex: Texture2D = SpriteKit.tex(FX + "fx_glow_ring.png")
	ring.visible = done and q >= Q_GREAT and ring_tex != null
	ring.texture = ring_tex
	if ring.visible:
		ring.modulate = Color(GamePalette.NEON_CYAN, 0.9)
		if not SettingsManager.reduced_flashing:
			_pulse_ring.call_deferred()

	# Quality you can SEE (never colour alone): rust and cracks for poor work.
	var rust_tex: Texture2D = SpriteKit.tex(PARTS + "overlay_rust.png")
	rust.visible = done and q < Q_OK and rust_tex != null
	rust.texture = rust_tex
	if rust.visible:
		rust.modulate = Color(1, 1, 1, clampf((Q_OK - q) / 0.25, 0.25, 1.0))
	var crack_tex: Texture2D = SpriteKit.tex(PARTS + "overlay_crack.png")
	crack.visible = done and q < Q_POOR and crack_tex != null
	crack.texture = crack_tex
	var badge_tex: Texture2D = null
	if done and grade >= 0:
		badge_tex = SpriteKit.tex(PARTS + GRADE_BADGES[clampi(grade, 0, 2)])
	badge.visible = badge_tex != null
	badge.texture = badge_tex

	quality_label.visible = done
	if done:
		quality_label.text = "%d%%" % roundi(q * 100.0)
		quality_label.add_theme_color_override("font_color", ItemPreview.quality_color(q))
	if pop and done:
		_play_pop.call_deferred(q)

func _pulse_ring() -> void:
	if not is_instance_valid(ring) or not ring.is_inside_tree():
		return
	var tw: Tween = ring.create_tween().set_loops()
	tw.tween_property(ring, "modulate:a", 0.45, 0.8)
	tw.tween_property(ring, "modulate:a", 0.95, 0.8)

## The "snap into place" moment: scale pop, white flash, sparks and a sound that match the quality.
func _play_pop(q: float) -> void:
	if not is_inside_tree():
		return
	holder.scale = Vector2(1.6, 1.6)
	var tw: Tween = holder.create_tween()
	tw.tween_property(holder, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not SettingsManager.reduced_flashing:
		flash.visible = true
		flash.color.a = 0.85
		var ft: Tween = flash.create_tween()
		ft.tween_property(flash, "color:a", 0.0, 0.3)
		ft.tween_callback(flash.hide)
	sparks.amount = 4 + roundi(14.0 * q)
	sparks.color = ItemPreview.quality_color(q) if q >= Q_POOR else GamePalette.ACCENT
	sparks.restart()
	if q < Q_POOR:
		Juice.shake(holder, 3.0, 0.25) # poor work rattles
		Sfx.play("strike_miss")
	elif q >= Q_GREAT:
		Sfx.play("upgrade_buy")
	else:
		Sfx.play("strike_hit")
