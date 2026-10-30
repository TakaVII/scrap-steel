# purpose: Blueprint of the item a contract builds (drift car / mech / cyberware) plus one slot per part. Slots start as ghosts; a finished part shows its icon with the QUALITY made visible: crack + rust overlays and a shake when poor, clean when good, a pulsing glow ring and sparks when excellent, the material-grade badge, the tier frame and the quality %. pop_index plays the "snap into place" animation (scale pop, white flash, sparks, sound). Uses the sprites in Assets/Textures/Parts and Minigames when they exist; colored placeholders otherwise.
# depends on: HBoxContainer, CommissionState, CommissionData, SpriteKit, GamePalette, Juice, Sfx, SettingsManager
# signals emitted: none
# signals listened to: none

class_name ItemPreview
extends HBoxContainer

const PARTS: String = "res://Assets/Textures/Parts/"
const FX: String = "res://Assets/Textures/Minigames/"
const BLUEPRINT_PX: Vector2 = Vector2(96, 64)
const SLOT_PX: float = 36.0
const ICON_PX: float = 32.0
const ICON_OFFSET: Vector2 = Vector2(2, 2)
const LABEL_H: float = 11.0
const TIER_FRAMES: Array[String] = ["frame_tier1_scrap.png", "frame_tier2_standard.png", "frame_tier3_prototype.png"]
const GRADE_BADGES: Array[String] = ["badge_grade_scrap.png", "badge_grade_standard.png", "badge_grade_premium.png"]
const TYPE_NAMES: Dictionary = {CommissionData.Type.CAR: "car", CommissionData.Type.MECH: "mech", CommissionData.Type.CYBER: "cyber"}
const Q_POOR: float = 0.50
const Q_OK: float = 0.75
const Q_GREAT: float = 0.90

func setup(job: CommissionState, pop_index: int = -1) -> void:
	add_theme_constant_override("separation", 6)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	add_child(_build_blueprint(job))
	for i in range(job.parts.size()):
		add_child(_build_slot(job, i, i == pop_index))

# ---------------------------------------------------------------- helpers

static func quality_color(q: float) -> Color:
	if q < Q_POOR:
		return GamePalette.NEGATIVE
	if q < Q_OK:
		return GamePalette.ACCENT
	if q < Q_GREAT:
		return GamePalette.POSITIVE
	return GamePalette.NEON_CYAN

func _tex_rect(path: String, px: Vector2, pos: Vector2 = Vector2.ZERO) -> TextureRect:
	var t: Texture2D = SpriteKit.tex(path)
	if t == null:
		return null
	var r := TextureRect.new()
	r.texture = t
	r.position = pos
	r.custom_minimum_size = px
	r.size = px
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _label(text_value: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text_value
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _done_count(job: CommissionState) -> int:
	var n: int = 0
	for s in job.part_scores:
		if s >= 0.0:
			n += 1
	return n

# ---------------------------------------------------------------- blueprint

func _build_blueprint(job: CommissionState) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = BLUEPRINT_PX
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var type_name: String = TYPE_NAMES.get(job.data.type, "car")
	var art: TextureRect = _tex_rect(PARTS + "item_blueprint_%s.png" % type_name, BLUEPRINT_PX)
	if art != null:
		holder.add_child(art)
	else:
		var bg := ColorRect.new()
		bg.color = GamePalette.BACKGROUND
		bg.size = BLUEPRINT_PX
		holder.add_child(bg)
		holder.add_child(_label(type_name.to_upper(), GamePalette.NEON_CYAN))
	var done: int = _done_count(job)
	var progress: float = float(done) / float(maxi(1, job.parts.size()))
	var b: float = 0.45 + 0.55 * progress # the blueprint "powers up" as parts are finished
	var tint: Color = Color(b, b, b, 1.0)
	if done > 0:
		tint = tint.lerp(quality_color(job.calculate_quality()), 0.30 * progress)
	holder.modulate = tint
	if done > 0:
		var q_label: Label = _label("%d%%" % roundi(job.calculate_quality() * 100.0), quality_color(job.calculate_quality()))
		q_label.position = Vector2(2, BLUEPRINT_PX.y - LABEL_H - 1.0)
		holder.add_child(q_label)
	return holder

# ---------------------------------------------------------------- slots

func _build_slot(job: CommissionState, idx: int, pop: bool) -> Control:
	var part: ItemPartData = job.parts[idx]
	var done: bool = job.part_scores[idx] >= 0.0
	var q: float = -1.0
	if done:
		q = job.part_quality[idx] if idx < job.part_quality.size() and job.part_quality[idx] >= 0.0 else 0.5 + 0.5 * job.part_scores[idx]
	var grade: int = job.part_grades[idx] if idx < job.part_grades.size() else -1

	var slot := Control.new()
	slot.custom_minimum_size = Vector2(SLOT_PX, SLOT_PX + LABEL_H)
	slot.mouse_filter = Control.MOUSE_FILTER_PASS
	slot.tooltip_text = tr(part.display_key) + (" - %d%%" % roundi(q * 100.0) if done else "")

	var bg: TextureRect = _tex_rect(PARTS + "slot_empty.png", Vector2(SLOT_PX, SLOT_PX))
	if bg != null:
		slot.add_child(bg)
	else:
		var box := ColorRect.new()
		box.color = Color(0.15, 0.13, 0.22, 1.0)
		box.size = Vector2(SLOT_PX, SLOT_PX)
		slot.add_child(box)

	var holder := Control.new() # everything that pops and shakes together
	holder.position = ICON_OFFSET
	holder.size = Vector2(ICON_PX, ICON_PX)
	holder.pivot_offset = Vector2(ICON_PX, ICON_PX) * 0.5
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(holder)

	# Glow ring behind the icon: only for excellent work.
	if done and q >= Q_GREAT:
		var ring: TextureRect = _tex_rect(FX + "fx_glow_ring.png", Vector2(ICON_PX, ICON_PX))
		if ring != null:
			ring.modulate = Color(GamePalette.NEON_CYAN, 0.9)
			var mat := CanvasItemMaterial.new()
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			ring.material = mat
			holder.add_child(ring)
			if not SettingsManager.reduced_flashing:
				_pulse_ring.call_deferred(ring)

	var icon: TextureRect = _tex_rect(PARTS + "part_%s.png" % String(part.part_id), Vector2(ICON_PX, ICON_PX))
	if icon != null:
		holder.add_child(icon)
		if not done:
			icon.modulate = Color(0.55, 0.55, 0.70, 0.45) # ghost: not built yet
	else:
		var fallback := _label(String(part.part_id).substr(0, 3).to_upper(), GamePalette.NEUTRAL_TEXT if done else Color(0.5, 0.5, 0.6, 0.6))
		holder.add_child(fallback)

	var frame: TextureRect = _tex_rect(PARTS + TIER_FRAMES[clampi(job.tier - 1, 0, 2)], Vector2(ICON_PX, ICON_PX))
	if frame != null:
		holder.add_child(frame)

	if done:
		# Quality you can SEE (never colour alone): rust and cracks for poor work.
		if q < Q_OK:
			var rust: TextureRect = _tex_rect(PARTS + "overlay_rust.png", Vector2(ICON_PX, ICON_PX))
			if rust != null:
				rust.modulate = Color(1, 1, 1, clampf((Q_OK - q) / 0.25, 0.25, 1.0))
				holder.add_child(rust)
		if q < Q_POOR:
			var crack: TextureRect = _tex_rect(PARTS + "overlay_crack.png", Vector2(ICON_PX, ICON_PX))
			if crack != null:
				holder.add_child(crack)
		if grade >= 0:
			var badge: TextureRect = _tex_rect(PARTS + GRADE_BADGES[clampi(grade, 0, 2)], Vector2(16, 16), Vector2(ICON_PX - 14.0, ICON_PX - 14.0))
			if badge != null:
				holder.add_child(badge)
		var q_label: Label = _label("%d%%" % roundi(q * 100.0), quality_color(q))
		q_label.position = Vector2(2, SLOT_PX - 1.0)
		slot.add_child(q_label)

	if pop and done:
		_play_pop.call_deferred(slot, holder, q)
	return slot

func _pulse_ring(ring: TextureRect) -> void:
	if not is_instance_valid(ring) or not ring.is_inside_tree():
		return
	var tw: Tween = ring.create_tween().set_loops()
	tw.tween_property(ring, "modulate:a", 0.45, 0.8)
	tw.tween_property(ring, "modulate:a", 0.95, 0.8)

## The "snap into place" moment: scale pop, white flash, sparks and a sound that match the quality.
func _play_pop(slot: Control, holder: Control, q: float) -> void:
	if not is_instance_valid(slot) or not slot.is_inside_tree():
		return
	holder.scale = Vector2(1.6, 1.6)
	var tw: Tween = holder.create_tween()
	tw.tween_property(holder, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not SettingsManager.reduced_flashing:
		var flash := ColorRect.new()
		flash.color = Color(1, 1, 1, 0.85)
		flash.size = Vector2(ICON_PX, ICON_PX)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(flash)
		var ft: Tween = flash.create_tween()
		ft.tween_property(flash, "color:a", 0.0, 0.3)
		ft.tween_callback(flash.queue_free)
	var sparks := CPUParticles2D.new()
	sparks.emitting = false
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = 4 + roundi(14.0 * q)
	sparks.lifetime = 0.4
	sparks.direction = Vector2(0, -1)
	sparks.spread = 120.0
	sparks.initial_velocity_min = 30.0
	sparks.initial_velocity_max = 80.0
	sparks.gravity = Vector2(0, 120)
	sparks.scale_amount_min = 1.5
	sparks.scale_amount_max = 2.5
	sparks.color = quality_color(q) if q >= Q_POOR else GamePalette.ACCENT
	sparks.position = Vector2(SLOT_PX, SLOT_PX) * 0.5
	slot.add_child(sparks)
	sparks.restart()
	if q < Q_POOR:
		Juice.shake(holder, 3.0, 0.25) # poor work rattles
		Sfx.play("strike_miss")
	elif q >= Q_GREAT:
		Sfx.play("upgrade_buy")
	else:
		Sfx.play("strike_hit")
