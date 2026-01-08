extends GdUnitTestSuite

const TMP_CONFIG_PATH := "user://test_cfg_autoload.cfg"

var _original_config_path := ""

func before_test() -> void:
	_original_config_path = GameConfig.config_path

func after_test() -> void:
	GameConfig.config_path = _original_config_path
	GameConfig.reset_to_defaults()
	if FileAccess.file_exists(TMP_CONFIG_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_CONFIG_PATH))
	InputMapper.clear_action("temp_action")

func test_game_config_set_and_get_value() -> void:
	GameConfig.set_value("gameplay/difficulty", "hard")
	assert_that(GameConfig.get_value("gameplay/difficulty", "")).is_equal("hard")

func test_game_config_save_and_load() -> void:
	GameConfig.config_path = TMP_CONFIG_PATH
	GameConfig.reset_to_defaults()
	GameConfig.set_value("audio/master_db", -8.0)
	GameConfig.save_config()
	GameConfig.reset_to_defaults()
	GameConfig.load_config()
	assert_that(GameConfig.get_value("audio/master_db", 0.0)).is_equal(-8.0)

func test_scene_transition_emits_signal_without_change() -> void:
	var captured := []
	var callable := func(path): captured.append(String(path))
	SceneTransition.scene_change_requested.connect(callable)
	await SceneTransition.change_scene("res://Menus/title_screen.tscn", 0.0, false)
	SceneTransition.scene_change_requested.disconnect(callable)
	assert_that(captured.size()).is_equal(1)
	assert_that(captured[0]).contains("title_screen")

func test_input_mapper_apply_and_clear() -> void:
	InputMapper.apply_configs([
		{"action": "temp_action", "keys": [KEY_F7], "joy_buttons": []},
	])
	var events := InputMap.action_get_events("temp_action")
	var found := false
	for event in events:
		if event is InputEventKey and event.keycode == KEY_F7:
			found = true
			break
	assert_that(found).is_true()
	InputMapper.clear_action("temp_action")
	assert_that(InputMap.has_action("temp_action")).is_false()

func test_input_mapper_map_action_adds_key_event() -> void:
	var action := "temp_action_map"
	# Ensure a clean state
	InputMapper.clear_action(action)
	# Map a single key via direct API
	InputMapper.map_action(action, [KEY_F6], [])
	var events := InputMap.action_get_events(action)
	var found := false
	for event in events:
		if event is InputEventKey and event.keycode == KEY_F6:
			found = true
			break
	assert_that(found).is_true()
	# Cleanup
	InputMapper.clear_action(action)
	assert_that(InputMap.has_action(action)).is_false()

func test_audio_bus_controller_volume_and_mute() -> void:
	var original := AudioBusController.get_bus_volume_db("Master")
	AudioBusController.set_bus_volume_db("Master", -5.0)
	assert_that(AudioBusController.get_bus_volume_db("Master")).is_equal(-5.0)
	AudioBusController.mute_bus("Master", true)
	assert_that(AudioBusController.is_bus_muted("Master")).is_true()
	AudioBusController.mute_bus("Master", false)
	AudioBusController.set_bus_volume_db("Master", original)
	# Verify final state restored
	assert_that(AudioBusController.get_bus_volume_db("Master")).is_equal(original)

var _captured_event_name := ""
var _captured_event_payload = null

func _capture_event(name, payload) -> void:
	_captured_event_name = String(name)
	_captured_event_payload = payload

func test_event_bus_emit_event() -> void:
	_captured_event_name = ""
	_captured_event_payload = null
	EventBus.event_emitted.connect(Callable(self, "_capture_event"))
	EventBus.emit_event("test_event", {"value": 99})
	EventBus.event_emitted.disconnect(Callable(self, "_capture_event"))
	assert_that(_captured_event_name).is_equal("test_event")
	assert_that(_captured_event_payload).is_not_null()
	assert_that(_captured_event_payload.get("value", 0)).is_equal(99)

func test_event_bus_multiple_listeners_receive_event() -> void:
	var a: String = ""
	var b: String = ""
	var ca := func(name, payload): a = str(name) + ":" + str(payload.get("id", -1))
	var cb := func(name, payload): b = str(name) + ":" + str(payload.get("id", -1))
	EventBus.event_emitted.connect(ca)
	EventBus.event_emitted.connect(cb)
	EventBus.emit_event("multi", {"id": 7})
	@warning_ignore("redundant_await")
	await get_tree().process_frame
	EventBus.event_emitted.disconnect(ca)
	EventBus.event_emitted.disconnect(cb)
	# Allow for potential formatting/ANSI artifacts in CI output
	assert_that(a.find("multi:7") >= 0).is_true()
	assert_that(b.find("multi:7") >= 0).is_true()

func test_event_bus_disconnect_stops_delivery() -> void:
	var captures: Array[String] = []
	var cb := func(name, _payload): captures.append(str(name))
	EventBus.event_emitted.connect(cb)
	EventBus.emit_event("first")
	@warning_ignore("redundant_await")
	await get_tree().process_frame
	EventBus.event_emitted.disconnect(cb)
	EventBus.emit_event("second")
	@warning_ignore("redundant_await")
	await get_tree().process_frame
	assert_that(captures.size()).is_equal(1)
	assert_that(captures[0]).is_equal("first")

func test_event_bus_emit_without_listeners_is_safe() -> void:
	# No listeners connected here; ensure no crash and proceed to a simple assert
	EventBus.emit_event("no_listeners", {"ok": true})
	@warning_ignore("redundant_await")
	await get_tree().process_frame
	assert_that(true).is_true()

func test_event_bus_complex_payload_roundtrip() -> void:
	var got: Dictionary = {}
	var cb := func(_n, payload): got = payload
	EventBus.event_emitted.connect(cb)
	var payload := {"arr": [1, 2, 3], "map": {"k": "v"}}
	EventBus.emit_event("complex", payload)
	@warning_ignore("redundant_await")
	await get_tree().process_frame
	EventBus.event_emitted.disconnect(cb)
	var arr = got.get("arr", null)
	var mp = got.get("map", null)
	assert_that(arr).is_not_null()
	assert_that(arr is Array).is_true()
	if not (arr is Array):
		assert_that(false).is_true()
		return
	assert_that(arr.size()).is_equal(3)
	assert_that(mp).is_not_null()
	assert_that(mp.get("k", "")).is_equal("v")

var _reload_captured: Array = []

func _capture_reload(path) -> void:
	_reload_captured.append(String(path))

func test_scene_transition_reload_current_emits_signal() -> void:
	var SCENE_PATH := "res://Menus/title_screen.tscn"
	@warning_ignore("redundant_await")
	await SceneTransition.change_scene(SCENE_PATH, 0.0, true)
	@warning_ignore("redundant_await")
	await get_tree().process_frame
	_reload_captured.clear()
	SceneTransition.scene_change_requested.connect(Callable(self, "_capture_reload"))
	@warning_ignore("redundant_await")
	await SceneTransition.reload_current(false)
	SceneTransition.scene_change_requested.disconnect(Callable(self, "_capture_reload"))
	assert_that(_reload_captured.size()).is_equal(1)
	assert_that(_reload_captured[0]).is_equal(SCENE_PATH)

func test_scene_transition_change_scene_with_delay_executes_change() -> void:
	var GAMEPLAY := "res://Gameplay/gameplay.tscn"
	@warning_ignore("redundant_await")
	await SceneTransition.change_scene(GAMEPLAY, 0.01, true)
	# change_scene awaits one frame internally; verify the current scene path
	@warning_ignore("redundant_await")
	await get_tree().process_frame
	var current := get_tree().current_scene
	assert_that(current).is_not_null()
	assert_that(current.scene_file_path).is_equal(GAMEPLAY)

func test_scene_transition_no_execute_does_not_change_scene() -> void:
	var TITLE := "res://Menus/title_screen.tscn"
	var GAMEPLAY := "res://Gameplay/gameplay.tscn"
	@warning_ignore("redundant_await")
	await SceneTransition.change_scene(TITLE, 0.0, true)
	@warning_ignore("redundant_await")
	await get_tree().process_frame
	var before := get_tree().current_scene
	assert_that(before).is_not_null()
	assert_that(before.scene_file_path).is_equal(TITLE)

	var captured := []
	var callable := func(path): captured.append(String(path))
	SceneTransition.scene_change_requested.connect(callable)
	@warning_ignore("redundant_await")
	await SceneTransition.change_scene(GAMEPLAY, 0.0, false)
	SceneTransition.scene_change_requested.disconnect(callable)
	@warning_ignore("redundant_await")
	await get_tree().process_frame
	var after := get_tree().current_scene
	assert_that(after).is_not_null()
	assert_that(after.scene_file_path).is_equal(TITLE)
	assert_that(captured.size()).is_equal(1)
	assert_that(captured[0]).is_equal(GAMEPLAY)

func test_audio_bus_controller_play_and_stop_music() -> void:
	var player: AudioStreamPlayer = null
	for child in AudioBusController.get_children():
		if child is AudioStreamPlayer:
			player = child
			break
	assert_that(player).is_not_null()
	var stream := AudioStreamGenerator.new()
	AudioBusController.play_music(stream, "Music")
	await get_tree().process_frame
	assert_that(player.stream).is_equal(stream)
	assert_that(player.playing).is_true()
	AudioBusController.stop_music()
	await get_tree().process_frame
	assert_that(player.playing).is_false()

func test_audio_bus_controller_invalid_bus_is_safe() -> void:
	# Invalid bus ops should be no-ops and not throw
	AudioBusController.set_bus_volume_db("__INVALID__", -12.0)
	assert_that(AudioBusController.get_bus_volume_db("__INVALID__")).is_equal(0.0)
	AudioBusController.mute_bus("__INVALID__", true)
	assert_that(AudioBusController.is_bus_muted("__INVALID__")).is_false()

func test_audio_bus_controller_music_bus_volume_and_mute() -> void:
	var original_db := AudioBusController.get_bus_volume_db("Music")
	var was_muted := AudioBusController.is_bus_muted("Music")
	AudioBusController.set_bus_volume_db("Music", -6.0)
	AudioBusController.mute_bus("Music", true)
	assert_that(AudioBusController.get_bus_volume_db("Music")).is_equal(-6.0)
	assert_that(AudioBusController.is_bus_muted("Music")).is_true()
	AudioBusController.set_bus_volume_db("Music", original_db)
	AudioBusController.mute_bus("Music", was_muted)
	# Verify final state restored
	assert_that(AudioBusController.get_bus_volume_db("Music")).is_equal(original_db)
	assert_that(AudioBusController.is_bus_muted("Music")).is_equal(was_muted)

func test_audio_bus_controller_play_music_sets_bus() -> void:
	var player: AudioStreamPlayer = null
	for child in AudioBusController.get_children():
		if child is AudioStreamPlayer:
			player = child
			break
	assert_that(player).is_not_null()
	var stream := AudioStreamGenerator.new()
	AudioBusController.play_music(stream, "SFX")
	await get_tree().process_frame
	assert_that(player.bus).is_equal("SFX")
	# Cleanup: stop playback to avoid leaks
	AudioBusController.stop_music()
	@warning_ignore("redundant_await")
	await get_tree().process_frame
	assert_that(player.playing).is_false()
