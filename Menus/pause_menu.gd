extends Control

signal resume_requested
signal controls_requested
signal quit_requested

@onready var _volume_slider: HSlider = $Panel/VBox/VolumeRow/Volume
@onready var _mute_check: CheckButton = $Panel/VBox/VolumeRow/Mute

func _ready() -> void:
	set_process_unhandled_input(true)
	var audio_bus_controller = get_tree().root.get_node_or_null("AudioBusController")
	if audio_bus_controller == null:
		push_error("AudioBusController autoload not found!")
		return
	var game_config = get_tree().root.get_node_or_null("GameConfig")
	if game_config == null:
		push_error("GameConfig autoload not found!")
		return
	if is_instance_valid(_volume_slider):
		_volume_slider.min_value = -40.0
		_volume_slider.max_value = 0.0
		_volume_slider.step = 0.5
		var saved_db = game_config.get_value("audio/music_db", audio_bus_controller.get_bus_volume_db("Music"))
		_volume_slider.value = float(saved_db)
		audio_bus_controller.set_bus_volume_db("Music", float(saved_db))
		_volume_slider.value_changed.connect(_on_volume_changed)
	if is_instance_valid(_mute_check):
		var saved_muted = game_config.get_value("audio/music_muted", audio_bus_controller.is_bus_muted("Music"))
		_mute_check.button_pressed = bool(saved_muted)
		audio_bus_controller.mute_bus("Music", bool(saved_muted))
		_mute_check.toggled.connect(_on_mute_toggled)

func _on_resume_pressed() -> void:
	resume_requested.emit()

func _on_controls_pressed() -> void:
	controls_requested.emit()

func _on_quit_pressed() -> void:
	quit_requested.emit()

func _on_volume_changed(value: float) -> void:
	var audio_bus_controller = get_tree().root.get_node_or_null("AudioBusController")
	if audio_bus_controller != null:
		audio_bus_controller.set_bus_volume_db("Music", value)
	var game_config = get_tree().root.get_node_or_null("GameConfig")
	if game_config != null:
		game_config.set_value("audio/music_db", value)
		game_config.save_config()

func _on_mute_toggled(pressed: bool) -> void:
	var audio_bus_controller = get_tree().root.get_node_or_null("AudioBusController")
	if audio_bus_controller != null:
		audio_bus_controller.mute_bus("Music", pressed)
	var game_config = get_tree().root.get_node_or_null("GameConfig")
	if game_config != null:
		game_config.set_value("audio/music_muted", pressed)
		game_config.save_config()
