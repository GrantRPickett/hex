#class_name AudioBusController
extends Node

var _music_player: AudioStreamPlayer

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	# Ensure common buses exist in headless/test runs
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_ensure_bus("UI")
	_ensure_bus("Environment")
	_ensure_bus("Narrative")
	_music_player.bus = "Music"
	add_child(_music_player)

	# Apply saved settings
	_apply_saved_settings()

	# Disable audio output in headless environments
	if OS.has_feature("headless"):
		for i in AudioServer.get_bus_count():
			AudioServer.set_bus_mute(i, true)

func _apply_saved_settings() -> void:
	var gc = GameConfig
	if not gc: return
	
	var buses = {
		"Master": [GameConfig.Paths.AUDIO_MASTER, GameConfig.Paths.AUDIO_MASTER_MUTED],
		"Music": [GameConfig.Paths.AUDIO_MUSIC, GameConfig.Paths.AUDIO_MUSIC_MUTED],
		"SFX": [GameConfig.Paths.AUDIO_SFX, GameConfig.Paths.AUDIO_SFX_MUTED],
		"UI": [GameConfig.Paths.AUDIO_UI, GameConfig.Paths.AUDIO_UI_MUTED],
		"Environment": [GameConfig.Paths.AUDIO_ENVIRONMENT, GameConfig.Paths.AUDIO_ENVIRONMENT_MUTED],
		"Narrative": [GameConfig.Paths.AUDIO_NARRATIVE, GameConfig.Paths.AUDIO_NARRATIVE_MUTED]
	}
	
	for bus_name in buses:
		var paths = buses[bus_name]
		var vol = gc.get_value(paths[0], get_bus_volume_db(bus_name))
		var muted = gc.get_value(paths[1], is_bus_muted(bus_name))
		set_bus_volume_db(bus_name, float(vol))
		mute_bus(bus_name, bool(muted))

func set_bus_volume_db(bus_name: String, volume_db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, volume_db)

func get_bus_volume_db(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return 0.0
	return AudioServer.get_bus_volume_db(idx)

func mute_bus(bus_name: String, mute := true) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, mute)

func is_bus_muted(bus_name: String) -> bool:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return false
	return AudioServer.is_bus_mute(idx)

func play_music(stream: AudioStream, bus_name: String = "Music") -> void:
	if not stream:
		return
	_music_player.stop()
	_music_player.stream = stream
	_music_player.bus = bus_name
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func _ensure_bus(bus_name: String) -> void:
	# Create the bus if missing so tests can address named buses.
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		return
	AudioServer.add_bus(AudioServer.get_bus_count())
	var new_index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(new_index, bus_name)
