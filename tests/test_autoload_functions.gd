extends GdUnitTestSuite

var _captured_event_name := ""
var _captured_event_payload: Variant = null
var _config_signal_count := 0
var _config_signal_path := ""
var _config_signal_value: Variant = null

func test_audio_bus_controller_set_and_get_volume_db() -> void:
	var target_bus := "Music"
	var expected_volume := -8.0

	AudioBusController.set_bus_volume_db(target_bus, expected_volume)
	var current_volume := AudioBusController.get_bus_volume_db(target_bus)

	assert_that(current_volume).is_equal(expected_volume)

func test_audio_bus_controller_mute_bus_reflects_state() -> void:
	var target_bus := "SFX"

	AudioBusController.mute_bus(target_bus, true)
	assert_that(AudioBusController.is_bus_muted(target_bus)).is_true()

	AudioBusController.mute_bus(target_bus, false)
	assert_that(AudioBusController.is_bus_muted(target_bus)).is_false()

func test_audio_bus_controller_play_music_assigns_stream_and_bus() -> void:
	var stream := AudioStreamGenerator.new()
	var player := _get_music_player()
	assert_that(player).is_not_null()

	AudioBusController.play_music(stream, "Music")

	assert_that(player.stream).is_equal(stream)
	assert_that(player.bus).is_equal("Music")
	assert_that(player.is_playing()).is_true()

	AudioBusController.stop_music()

func test_audio_bus_controller_stop_music_halts_playback() -> void:
	var stream := AudioStreamGenerator.new()
	var player := _get_music_player()
	assert_that(player).is_not_null()

	AudioBusController.play_music(stream)
	AudioBusController.stop_music()

	assert_that(player.is_playing()).is_false()

func test_event_bus_emit_event_duplicates_payload() -> void:
	var slot := Callable(self, "_capture_event")
	EventBus.event_emitted.connect(slot)

	var payload := {
		"level": "res://test_level",
		"tags": ["alpha", "beta"],
	}
	EventBus.emit_event("custom_event", payload)
	EventBus.event_emitted.disconnect(slot)

	payload["tags"].append("mutated")

	assert_that(_captured_event_name).is_equal("custom_event")
	assert_that(_captured_event_payload).is_not_null()
	assert_that(_captured_event_payload["tags"].size()).is_equal(2)
	assert_that(payload["tags"].size()).is_equal(3)

func test_game_config_set_value_emits_signal() -> void:
	_reset_config_signal_state()
	var slot := Callable(self, "_capture_config_change")
	GameConfig.config_changed.connect(slot)

	var path := "audio/music_db"
	var new_value := -5.0
	GameConfig.set_value(path, new_value)

	GameConfig.config_changed.disconnect(slot)
	assert_that(_config_signal_count).is_equal(1)
	assert_that(_config_signal_path).is_equal(path)
	assert_that(_config_signal_value).is_equal(new_value)
	assert_that(GameConfig.get_value(path)).is_equal(new_value)

func test_game_config_save_and_load_round_trip() -> void:
	var original_path := GameConfig.config_path
	var temp_path := "user://gdunit_game_config_roundtrip.cfg"
	_delete_user_file(temp_path)

	GameConfig.config_path = temp_path
	GameConfig.reset_to_defaults()

	var expected_master := -12.5
	GameConfig.set_value("audio/master_db", expected_master)
	GameConfig.set_value("controls/invert_y", true)
	GameConfig.save_config()

	GameConfig.reset_to_defaults()
	GameConfig.load_config()

	assert_that(GameConfig.get_value("audio/master_db")).is_equal(expected_master)
	assert_that(GameConfig.get_value("controls/invert_y")).is_true()

	GameConfig.config_path = original_path
	GameConfig.reset_to_defaults()
	GameConfig.load_config()
	_delete_user_file(temp_path)

func test_input_mapper_map_action_registers_keys_and_buttons() -> void:
	var action := "gdunit_test_action"
	InputMapper.clear_action(action)

	InputMapper.map_action(action, [Key.KEY_A], [JoyButton.JOY_BUTTON_B])
	var events := InputMap.action_get_events(action)

	assert_that(InputMap.has_action(action)).is_true()
	assert_that(events.size()).is_equal(2)
	assert_that(_has_key_event(events, Key.KEY_A)).is_true()
	assert_that(_has_button_event(events, JoyButton.JOY_BUTTON_B)).is_true()

	InputMapper.clear_action(action)

func test_input_mapper_apply_configs_uses_fallback_when_empty() -> void:
	var action := "gdunit_fallback_action"
	InputMapper.clear_action(action)

	InputMapper.apply_configs([], [{
		"action": action,
		"keys": [Key.KEY_B],
	}])

	assert_that(InputMap.has_action(action)).is_true()
	assert_that(_has_key_event(InputMap.action_get_events(action), Key.KEY_B)).is_true()

	InputMapper.clear_action(action)

# Helpers
func _capture_event(event_name: String, payload) -> void:
	_captured_event_name = event_name
	_captured_event_payload = payload

func _reset_config_signal_state() -> void:
	_config_signal_count = 0
	_config_signal_path = ""
	_config_signal_value = null

func _capture_config_change(path: String, value) -> void:
	_config_signal_count += 1
	_config_signal_path = path
	_config_signal_value = value

func _delete_user_file(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)

func _get_music_player() -> AudioStreamPlayer:
	for child in AudioBusController.get_children():
		if child is AudioStreamPlayer:
			return child
	return null

func _has_key_event(events: Array, keycode: Key) -> bool:
	for event in events:
		if event is InputEventKey and event.keycode == keycode:
			return true
	return false

func _has_button_event(events: Array, button_index: JoyButton) -> bool:
	for event in events:
		if event is InputEventJoypadButton and event.button_index == button_index:
			return true
	return false
