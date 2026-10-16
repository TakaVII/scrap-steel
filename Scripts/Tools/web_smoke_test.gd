# purpose: Early validation script for web export: verifies Arabic RTL text rendering, Web Audio gate, and frame rate.
# depends on: Control, EventBus, AudioServer
# signals emitted: none
# signals listened to: none

extends Control

@onready var fps_label: Label = %FpsLabel
@onready var audio_status_label: Label = %AudioStatusLabel
@onready var start_audio_button: Button = %StartAudioButton
@onready var resolution_label: Label = %ResolutionLabel

var _audio_unlocked: bool = false
var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_update_resolution_display()
	get_viewport().size_changed.connect(_update_resolution_display)

func _process(_delta: float) -> void:
	fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

func _update_resolution_display() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	resolution_label.text = "Viewport: %d x %d" % [int(vp_size.x), int(vp_size.y)]

func _on_start_audio_button_pressed() -> void:
	if _audio_unlocked:
		return
	_audio_unlocked = true
	audio_status_label.text = "Audio Status: Unlocked (Playing 440Hz Sine Tone)"
	start_audio_button.disabled = true
	
	# Generate a soft 440Hz beep to confirm Web Audio output without external assets
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.2
	_player.stream = gen
	_player.play()
	var playback: AudioStreamGeneratorPlayback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		var sample_hz: float = 22050.0
		var tone_hz: float = 440.0
		var num_samples: int = int(sample_hz * 0.15)
		for i in range(num_samples):
			var sample: float = sin(2.0 * PI * tone_hz * float(i) / sample_hz) * 0.2
			playback.push_frame(Vector2(sample, sample))
