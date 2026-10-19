class_name Sfx
extends RefCounted
 
const PREFIX: String = "res://Assets/Audio/sfx_"
 
static var _cache: Dictionary = {}
 
static func play(sfx_name: String) -> void:
	var s: AudioStream = _load_stream(sfx_name)
	if s != null:
		AudioManager.play_sfx(s)
 
static func _load_stream(sfx_name: String) -> AudioStream:
	if _cache.has(sfx_name):
		return _cache[sfx_name]
	var s: AudioStream = null
	var path: String = PREFIX + sfx_name + ".ogg"
	if ResourceLoader.exists(path):
		s = load(path) as AudioStream
	_cache[sfx_name] = s
	return s
