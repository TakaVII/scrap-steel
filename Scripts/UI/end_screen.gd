# purpose: [v6] End screen with a real moment. Victory: gold/magenta flash, confetti, the headline slams in (CHAMPION OF THE COLOSSEUM...), the rank stamps down with a shake, text types out. Defeat: the screen darkens to red, the headline fades in and flickers (SEIZED / EVICTED / SO CLOSE), slow typing. The button unlocks at the end so a fast click cannot skip it. Reduced flashing: no flash, shake or flicker. v5: victory text per pathway, Kane's closing line on defeat.
# depends on: Control, GameManager, EconomyManager, CommissionManager, SettingsManager, Juice, GamePalette, Sfx
# signals emitted: none
# signals listened to: EventBus.run_ended

extends Control

const VICTORY_KEYS: Dictionary = {
	&"reputation": "END_VICTORY_REP",
	&"mech": "END_VICTORY_MECH",
	&"drifter": "END_VICTORY_DRIFT",
}
const HEAD_KEYS: Dictionary = {
	&"reputation": "END_HEAD_REP",
	&"mech": "END_HEAD_MECH",
	&"drifter": "END_HEAD_DRIFT",
}
const VICTORY_TINT: Color = Color(1.0, 0.165, 0.616, 0.28)
const DEFEAT_TINT: Color = Color(0.45, 0.02, 0.04, 0.62)
const TYPE_SEC_VICTORY: float = 1.4
const TYPE_SEC_DEFEAT: float = 2.4

@onready var tint: ColorRect = %Tint
@onready var confetti: CPUParticles2D = %Confetti
@onready var panel: PanelContainer = %Panel
@onready var headline_label: Label = %HeadlineLabel
@onready var title_label: Label = %TitleLabel
@onready var desc_label: Label = %DescLabel
@onready var rank_label: Label = %RankLabel
@onready var stats_label: Label = %StatsLabel
@onready var restart_button: Button = %RestartButton

var _tween: Tween

func _ready() -> void:
	EventBus.run_ended.connect(_on_run_ended)

func _on_run_ended(victory: bool, reason: StringName) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	restart_button.disabled = true
	confetti.emitting = false
	if victory:
		headline_label.text = tr(HEAD_KEYS.get(GameManager.pathway, "END_HEAD_MECH"))
		title_label.text = tr("END_VICTORY_TITLE")
		desc_label.text = tr(VICTORY_KEYS.get(GameManager.pathway, "END_VICTORY_DESC"))
		rank_label.text = tr("END_RANK") + " " + GameManager.calculate_final_rank()
		stats_label.text = _victory_stats()
		headline_label.add_theme_color_override("font_color", GamePalette.ACCENT)
		_style_panel(GamePalette.ACCENT)
	else:
		match reason:
			&"seized":
				headline_label.text = tr("END_HEAD_SEIZED")
				title_label.text = tr("END_GAME_OVER_TITLE")
				desc_label.text = tr("END_SEIZED_DESC")
			&"evicted":
				headline_label.text = tr("END_HEAD_EVICTED")
				title_label.text = tr("END_EVICTED_TITLE")
				desc_label.text = tr("END_EVICTED_DESC")
			_:
				headline_label.text = tr("END_HEAD_TIMEOUT")
				title_label.text = tr("END_TIMEOUT_TITLE")
				desc_label.text = tr("END_TIMEOUT_DESC")
		rank_label.text = ""
		stats_label.text = _defeat_stats()
		headline_label.add_theme_color_override("font_color", GamePalette.NEGATIVE)
		_style_panel(GamePalette.NEGATIVE)
	await get_tree().process_frame # container sizes must be real before pivots are set
	_play(victory)

func _victory_stats() -> String:
	var cleared: String = tr("HUD_DAY") + " %d" % GameManager.debt_cleared_day if GameManager.debt_cleared_day > 0 else tr("END_STAT_NEVER")
	return "%s: %s\n%s: %s\n%s: %.1f / 5" % [
		tr("END_STAT_NETWORTH"), NumberFormat.format_credits(EconomyManager.net_worth()),
		tr("END_STAT_CLEARED"), cleared,
		tr("END_STAT_RATING"), CommissionManager.shop_rating() * 5.0
	]

func _defeat_stats() -> String:
	return "%s: %s\n%s: %d / %d   %s: %d / %d\n%s: %s" % [
		tr("HUD_DEBT"), NumberFormat.format_credits(EconomyManager.debt),
		tr("END_STAT_STRIKES"), EconomyManager.strikes, Balance.cfg.max_strikes,
		tr("MORNING_RENT_STRIKES"), EconomyManager.rent_strikes, Balance.cfg.max_rent_strikes,
		tr("END_STAT_NETWORTH"), NumberFormat.format_credits(EconomyManager.net_worth())
	]

func _style_panel(border: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = GamePalette.BACKGROUND
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(2)
	panel.add_theme_stylebox_override("panel", sb)

func _play(victory: bool) -> void:
	var calm: bool = SettingsManager.reduced_flashing
	var type_sec: float = TYPE_SEC_VICTORY if victory else TYPE_SEC_DEFEAT
	headline_label.pivot_offset = headline_label.size * 0.5
	rank_label.pivot_offset = rank_label.size * 0.5
	var target_tint: Color = VICTORY_TINT if victory else DEFEAT_TINT
	if calm:
		target_tint.a *= 0.5
	tint.color = Color(target_tint, 0.0)
	panel.modulate.a = 0.0
	headline_label.modulate.a = 0.0
	rank_label.modulate.a = 0.0
	desc_label.visible_ratio = 0.0
	stats_label.visible_ratio = 0.0

	_tween = create_tween()
	_tween.tween_property(tint, "color:a", target_tint.a, 0.8)
	_tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.5)
	if victory:
		headline_label.scale = Vector2(2.4, 2.4)
		_tween.tween_property(headline_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.parallel().tween_property(headline_label, "modulate:a", 1.0, 0.2)
		_tween.tween_callback(_impact.bind(4.0, "stamp"))
		rank_label.scale = Vector2(3.0, 3.0)
		_tween.tween_property(rank_label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.parallel().tween_property(rank_label, "modulate:a", 1.0, 0.15)
		_tween.tween_callback(_impact.bind(3.0, "upgrade_buy"))
		_tween.tween_callback(func() -> void: confetti.emitting = true)
	else:
		_tween.tween_property(headline_label, "modulate:a", 1.0, 0.9)
		if not calm:
			for i in range(3):
				_tween.tween_property(headline_label, "modulate:a", 0.25, 0.06)
				_tween.tween_property(headline_label, "modulate:a", 1.0, 0.06)
		_tween.tween_callback(_impact.bind(2.0, "warning"))
	_tween.tween_property(desc_label, "visible_ratio", 1.0, type_sec)
	_tween.tween_property(stats_label, "visible_ratio", 1.0, 0.6)
	_tween.tween_callback(func() -> void:
		restart_button.disabled = false
		restart_button.grab_focus())

func _impact(strength: float, sfx_name: String) -> void:
	Juice.shake(self, strength, 0.2)
	Sfx.play(sfx_name)

func _on_restart_button_pressed() -> void:
	confetti.emitting = false
	GameManager.return_to_menu()
