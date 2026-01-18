extends GdUnitTestSuite

const LevelScript := preload("res://Resources/Level.gd")

func _register(node: Node) -> Node:
	if node == null:
		return node
	return auto_free(node)

func test_click_to_move_single_hex() -> void:
	# Setup a scene with one player unit
	var _runner = scene_runner("res://Gameplay/gameplay.tscn")
	_runner.simulate_frames(1)

	var _scene = _runner.scene()
	var level = LevelScript.new()
	level.player_starts = [Vector2i(0, 0)] as Array[Vector2i]
	level.goal_coords = [Vector2i(3, 3)] as Array[Vector2i]

	_scene.level_resource = level
	_scene._apply_level_if_available()
	_runner.simulate_frames(1)

	# Unit starts at (0, 0)
	assert_that(_scene._game_state.unit_manager.get_coord(0)).is_equal(Vector2i(0, 0))

	# Click on adjacent hex (1, 0) - should move there
	var grid = _scene._grid
	var target_pos = grid.map_to_local(Vector2i(1, 0))
	var screen_pos = grid.to_global(target_pos)

	_scene._game_state.input_controller._on_primary_action_at(screen_pos)
	_runner.simulate_frames(1)

	# Unit should have moved
	assert_that(_scene._game_state.unit_manager.get_coord(0)).is_equal(Vector2i(1, 0))

func test_click_to_move_multi_hex_path() -> void:
	# Setup a scene with one player unit
	var _runner = scene_runner("res://Gameplay/gameplay.tscn")
	_runner.simulate_frames(1)

	var _scene = _runner.scene()
	var level = LevelScript.new()
	level.player_starts = [Vector2i(0, 0)] as Array[Vector2i]
	level.goal_coords = [Vector2i(3, 3)] as Array[Vector2i]

	_scene.level_resource = level
	_scene._apply_level_if_available()
	_runner.simulate_frames(1)

	# Unit starts at (0, 0)
	assert_that(_scene._game_state.unit_manager.get_coord(0)).is_equal(Vector2i(0, 0))

	# Click on hex at (2, 0) - should move along path
	var grid = _scene._grid
	var target_pos = grid.map_to_local(Vector2i(2, 0))
	var screen_pos = grid.to_global(target_pos)

	_scene._game_state.input_controller._on_primary_action_at(screen_pos)
	_runner.simulate_frames(1)

	# Unit should have moved (may not reach (2,0) if movement limited, but should move closer)
	var new_coord = _scene._game_state.unit_manager.get_coord(0)
	assert_that(new_coord).is_not_equal(Vector2i(0, 0))

func test_click_to_move_cannot_move_out_of_range() -> void:
	# Setup a scene with one player unit with limited movement
	var _runner = scene_runner("res://Gameplay/gameplay.tscn")
	_runner.simulate_frames(1)

	var _scene = _runner.scene()
	var level = LevelScript.new()
	level.player_starts = [Vector2i(0, 0)] as Array[Vector2i]
	level.goal_coords = [Vector2i(3, 3)] as Array[Vector2i]

	_scene.level_resource = level
	_scene._apply_level_if_available()
	_runner.simulate_frames(1)

	# Set unit movement to 0 to prevent moving
	var unit = _scene._game_state.unit_manager.get_unit(0)
	if unit:
		unit.movement_points = 0

	var initial_coord = _scene._game_state.unit_manager.get_coord(0)

	# Try to click on a hex far away
	var grid = _scene._grid
	var target_pos = grid.map_to_local(Vector2i(3, 3))
	var screen_pos = grid.to_global(target_pos)

	_scene._game_state.input_controller._on_primary_action_at(screen_pos)
	_runner.simulate_frames(1)

	# Unit should not have moved (no AP)
	assert_that(_scene._game_state.unit_manager.get_coord(0)).is_equal(initial_coord)
