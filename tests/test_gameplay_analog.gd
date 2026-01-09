extends GdUnitTestSuite

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

func _set_axis(scene: Node, axis: Vector2) -> void:
	var evx := InputEventJoypadMotion.new()
	evx.axis = JOY_AXIS_LEFT_X
	evx.axis_value = axis.x
	scene._unhandled_input(evx)
	var evy := InputEventJoypadMotion.new()
	evy.axis = JOY_AXIS_LEFT_Y
	evy.axis_value = axis.y
	scene._unhandled_input(evy)

func test_analog_move_even_column_uses_matching_action() -> void:
	# Skip in headless CI where joystick events are unreliable
	if OS.has_feature("headless"):
		return
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)

	# Start at an even x coordinate
	scene.set_player_coord(Vector2i(2, 2))
	var vectors: Dictionary = scene._analog_vectors_for(scene.player_coord)
	var action := "move_d"
	var dir_map: Dictionary = scene._direction_map(scene.player_coord)
	assert_that(vectors.has(action)).is_true()
	assert_that(dir_map.has(action)).is_true()

	var old: Vector2i = scene.player_coord
	_set_axis(scene, vectors[action])
	@warning_ignore("redundant_await")
	var changed := await _wait_for_player_coord_change(runner, scene, old, 10)
	assert_that(changed).is_true()
	assert_that(scene.player_coord).is_equal(Vector2i(2, 2) + dir_map[action])

func test_analog_move_odd_column_uses_matching_action() -> void:
	# Skip in headless CI where joystick events are unreliable
	if OS.has_feature("headless"):
		return
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)

	# Start at an odd x coordinate
	scene.set_player_coord(Vector2i(1, 2))
	var vectors: Dictionary = scene._analog_vectors_for(scene.player_coord)
	var action := "move_d"
	var dir_map: Dictionary = scene._direction_map(scene.player_coord)
	assert_that(vectors.has(action)).is_true()
	assert_that(dir_map.has(action)).is_true()

	var old2: Vector2i = scene.player_coord
	_set_axis(scene, vectors[action])
	@warning_ignore("redundant_await")
	var changed2 := await _wait_for_player_coord_change(runner, scene, old2, 10)
	assert_that(changed2).is_true()
	assert_that(scene.player_coord).is_equal(Vector2i(1, 2) + dir_map[action])

func _wait_for_player_coord_change(runner, scene, old_coord: Vector2i, max_frames: int) -> bool:
	for i in range(max_frames):
		await runner.simulate_frames(1)
		if scene.player_coord != old_coord:
			return true
	return false
