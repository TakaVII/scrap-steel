# purpose: Connects the game to AudioManager (nothing called it before, so the game was silent). Music by phase with crossfade, a click on every Button, and SFX for deliveries, strikes, installments, upgrades, fines and overtime. Missing audio files are skipped silently (see Docs/audio_spec.md for names).
# depends on: Node, AudioManager, EventBus, GameManager, Sfx
# signals emitted: none
# signals listened to: EventBus.phase_changed, run_ended, commission_delivered, strike_issued, installment_due, upgrade_purchased, ledger_entry_added, SceneTree.node_added

extends Node

const MUSIC: Dictionary = {
	"workshop": "res://Assets/Audio/music_workshop_loop.ogg",
	"minigame": "res://Assets/Audio/music_minigame_loop.ogg",
	"night": "res://Assets/Audio/music_night_summary.ogg",
	"victory": "res://Assets/Audio/music_victory_sting.ogg",
	"seizure": "res://Assets/Audio/music_seizure_sting.ogg",
}
const CROSSFADE_SEC: float = 1.0

var _current: String = ""

func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.commission_delivered.connect(_on_commission_delivered)
	EventBus.strike_issued.connect(_on_strike_issued)
	EventBus.installment_due.connect(_on_installment_due)
	EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
	EventBus.ledger_entry_added.connect(_on_ledger_entry_added)
	get_tree().node_added.connect(_on_node_added)
	_hook_buttons(get_tree().root)
	_play_music("workshop")

# ---------------------------------------------------------------- music

func _play_music(key: String) -> void:
	if key == _current:
		return
	var path: String = MUSIC.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	_current = key
	AudioManager.crossfade_music(load(path) as AudioStream, CROSSFADE_SEC)

func _on_phase_changed(new_phase: int, _old_phase: int) -> void:
	if new_phase == GameManager.Phase.MINIGAME:
		_play_music("minigame")
	elif new_phase == GameManager.Phase.NIGHT:
		_play_music("night")
	elif new_phase == GameManager.Phase.VICTORY or new_phase == GameManager.Phase.GAME_OVER:
		pass # run_ended picks the sting
	else:
		_play_music("workshop")

func _on_run_ended(victory: bool, reason: StringName) -> void:
	if victory:
		_play_music("victory")
	elif reason == &"seized":
		_play_music("seizure")
	else:
		_play_music("night")

# ---------------------------------------------------------------- sfx

func _on_commission_delivered(_c: Resource, _q: float, _p: int) -> void:
	Sfx.play("stamp")
	Sfx.play("credit_coin")

func _on_strike_issued(_strikes: int) -> void:
	Sfx.play("warning")

func _on_installment_due(_day: int, _amount: int) -> void:
	Sfx.play("installment_due")

func _on_upgrade_purchased(_id: StringName) -> void:
	Sfx.play("upgrade_buy")

func _on_ledger_entry_added(_desc: String, _amount: int, category: StringName) -> void:
	if category == &"fine" or category == &"refund":
		Sfx.play("warning")
	elif category == &"overtime":
		Sfx.play("overtime_activate")

# ---------------------------------------------------------------- ui click on every Button

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_connect_click(node as BaseButton)

func _hook_buttons(node: Node) -> void:
	if node is BaseButton:
		_connect_click(node as BaseButton)
	for child in node.get_children():
		_hook_buttons(child)

func _connect_click(btn: BaseButton) -> void:
	if not btn.pressed.is_connected(_on_button_pressed):
		btn.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	Sfx.play("ui_click")
