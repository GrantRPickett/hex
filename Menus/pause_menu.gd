extends Control

signal resume_requested
signal controls_requested
signal quit_requested

@onready var _volume_slider: HSlider = $Panel/VBox/VolumeRow/Volume
@onready var _mute_check: CheckButton = $Panel/VBox/VolumeRow/Mute

func _ready() -> void:
    set_process_unhandled_input(true)
    if is_instance_valid(_volume_slider):
        _volume_slider.min_value = -40.0
        _volume_slider.max_value = 0.0
        _volume_slider.step = 0.5
        var saved_db = GameConfig.get_value("audio/music_db", AudioBusController.get_bus_volume_db("Music"))
        _volume_slider.value = float(saved_db)
        AudioBusController.set_bus_volume_db("Music", float(saved_db))
        _volume_slider.value_changed.connect(_on_volume_changed)
    if is_instance_valid(_mute_check):
        var saved_muted = GameConfig.get_value("audio/music_muted", AudioBusController.is_bus_muted("Music"))
        _mute_check.button_pressed = bool(saved_muted)
        AudioBusController.mute_bus("Music", bool(saved_muted))
        _mute_check.toggled.connect(_on_mute_toggled)

func _on_resume_pressed() -> void:
    resume_requested.emit()

func _on_controls_pressed() -> void:
    controls_requested.emit()

func _on_quit_pressed() -> void:
    quit_requested.emit()

func _on_volume_changed(value: float) -> void:
    AudioBusController.set_bus_volume_db("Music", value)
    GameConfig.set_value("audio/music_db", value)
    GameConfig.save_config()

func _on_mute_toggled(pressed: bool) -> void:
    AudioBusController.mute_bus("Music", pressed)
    GameConfig.set_value("audio/music_muted", pressed)
    GameConfig.save_config()
