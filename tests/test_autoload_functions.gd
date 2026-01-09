extends GdUnitTestSuite

# Test coverage for autoload functions

func test_audio_bus_controller_set_bus_volume_db() -> void:
	# Test setting volume for a bus
	var master_bus := "Master"
	var test_volume := -10.0

	AudioBusController.set_bus_volume_db(master_bus, test_volume)
	await get_tree().process_frame
	# Should set without errors

func test_audio_bus_controller_mute_bus() -> void:
	# Test muting a bus
	var master_bus := "Master"

	AudioBusController.mute_bus(master_bus, true)
	await get_tree().process_frame

	AudioBusController.mute_bus(master_bus, false)
	await get_tree().process_frame
	# Should mute/unmute without errors

func test_audio_bus_controller_play_music() -> void:
	# Test music playback without providing invalid audio
	# Simply call to verify function exists and runs without error
	AudioBusController.play_music(null)
	await get_tree().process_frame

func test_audio_bus_controller_stop_music() -> void:
	# Test stopping music
	AudioBusController.stop_music()
	await get_tree().process_frame
	# Should stop without errors

func test_event_bus_emit_event() -> void:
	# Test event emission - just verify it exists and runs without crash
	EventBus.emit_event("test_event", {})
	await get_tree().process_frame

func test_game_config_reset_to_defaults() -> void:
	# Save original value
	var original: Variant = GameConfig.get_value("audio/master_db", 0.0)

	# Change value
	GameConfig.set_value("audio/master_db", -50.0)
	assert_that(GameConfig.get_value("audio/master_db")).is_equal(-50.0)

	# Reset
	GameConfig.reset_to_defaults()
	var after_reset: Variant = GameConfig.get_value("audio/master_db", 0.0)

	# Restore original
	GameConfig.set_value("audio/master_db", original)

func test_game_config_get_value() -> void:
	# Test getting existing value
	var value: Variant = GameConfig.get_value("audio/master_db")
	assert_that(value).is_not_null()

	# Test getting with default
	var missing: Variant = GameConfig.get_value("nonexistent/path", "DEFAULT")
	assert_that(missing).is_equal("DEFAULT")

func test_game_config_save_config() -> void:
	# Test saving config
	GameConfig.set_value("test_key", "test_value")
	GameConfig.save_config()
	await get_tree().process_frame
	# Should save without errors

func test_game_config_load_config() -> void:
	# Test loading config
	GameConfig.load_config()
	await get_tree().process_frame
	# Should load without errors

func test_input_mapper_apply_configs() -> void:
	# Test applying input configs - just verify it doesn't crash
	InputMapper.apply_configs([])
	await get_tree().process_frame

func test_input_mapper_map_action() -> void:
	# Test mapping an action
	var action_name := "test_action"
	InputMapper.map_action(action_name, [Key.KEY_A as int])
	await get_tree().process_frame
	# Should map without errors
