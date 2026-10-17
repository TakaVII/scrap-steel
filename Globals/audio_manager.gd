# purpose: [v2] Production audio manager with dynamic bus creation, loop crossfading, pooled SFX, and web unlock.
# depends on: AudioServer, SettingsManager, EventBus
# signals emitted: none
# signals listened to: none

extends Node

const SFX_POOL_SIZE: int = 8

var _master_bus_idx: int = 0
var _music_bus_idx: int = 0
var _sfx_bus_idx: int = 0

var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _current_player: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_idx: int = 0
var _web_audio_unlocked: bool = false

func _ready() -> void:
	_init_buses()
	_init_music_players()
	_init_sfx_pool()

func _input(event: InputEvent) -> void:
	if _web_audio_unlocked:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
		_unlock_web_audio()

func _unlock_web_audio() -> void:
	_web_audio_unlocked = true
	if _current_player and not _current_player.playing:
		_current_player.play()

func _init_buses() -> void:
	_master_bus_idx = AudioServer.get_bus_index("Master")

	_music_bus_idx = AudioServer.get_bus_index("Music")
	if _music_bus_idx == -1:
		AudioServer.add_bus()
		_music_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(_music_bus_idx, "Music")
		AudioServer.set_bus_send(_music_bus_idx, "Master")

	_sfx_bus_idx = AudioServer.get_bus_index("SFX")
	if _sfx_bus_idx == -1:
		AudioServer.add_bus()
		_sfx_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(_sfx_bus_idx, "SFX")
		AudioServer.set_bus_send(_sfx_bus_idx, "Master")

func _init_music_players() -> void:
	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.bus = "Music"
	add_child(_music_player_a)

	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.bus = "Music"
	add_child(_music_player_b)

func _init_sfx_pool() -> void:
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

## Crossfades between ambient workshop loop and high-intensity minigame loop
func crossfade_music(stream: AudioStream, duration: float = 1.0) -> void:
	if not stream:
		return
	var incoming := _music_player_b if _current_player == _music_player_a else _music_player_a
	var outgoing := _current_player

	incoming.stream = stream
	incoming.volume_db = -40.0
	if _web_audio_unlocked:
		incoming.play()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(incoming, "volume_db", 0.0, duration)
	if outgoing and outgoing.playing:
		tween.tween_property(outgoing, "volume_db", -40.0, duration)
		tween.chain().tween_callback(outgoing.stop)

	_current_player = incoming

## Plays sound effect using pooled players with pitch variation
func play_sfx(stream: AudioStream, pitch_variance: float = 0.05) -> void:
	if not stream:
		return
	var player: AudioStreamPlayer = _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % SFX_POOL_SIZE

	player.stream = stream
	player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	if _web_audio_unlocked:
		player.play()

func set_master_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(_master_bus_idx, linear_to_db(clampf(linear, 0.0001, 1.0)))

func set_music_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(_music_bus_idx, linear_to_db(clampf(linear, 0.0001, 1.0)))

func set_sfx_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(_sfx_bus_idx, linear_to_db(clampf(linear, 0.0001, 1.0)))
