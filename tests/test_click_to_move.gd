extends GdUnitTestSuite

const LevelScript := preload("res://Resources/Level.gd")
const UnitRosterDefinition := preload("res://Resources/rosters/unit_roster_definition.gd")
const LevelUnitSpawnEntry := preload("res://Resources/level_data/level_unit_spawn_entry.gd")
const GenericEnemyScene := preload("res://Gameplay/generic_enemy.tscn")

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
	level.player_starts = [Vector2i(1, 1)] as Array[Vector2i]
	level.location_coords = [Vector2i(4, 4)] as Array[Vector2i]

	_scene.level_resource = level
	_scene._apply_level_if_available()
	_runner.simulate_frames(1)

	# Unit starts at (1, 1)
	assert_that(_scene._game_state.unit_manager.get_coord(0)).is_equal(Vector2i(1, 1))

	# Click on adjacent hex (2, 1) - should move there
	var grid = _scene._grid
	var target_pos = grid.map_to_local(Vector2i(2, 1))
	var screen_pos = grid.to_global(target_pos)

	_scene._game_state.input_controller._on_primary_action_at(screen_pos)
	_runner.simulate_frames(1)

	# Unit should have moved
	assert_that(_scene._game_state.unit_manager.get_coord(0)).is_equal(Vector2i(2, 1))

func test_click_to_move_multi_hex_path() -> void:
	# Setup a scene with one player unit
	var _runner = scene_runner("res://Gameplay/gameplay.tscn")
	_runner.simulate_frames(1)

	var _scene = _runner.scene()
	var level = LevelScript.new()
	level.player_starts = [Vector2i(1, 1)] as Array[Vector2i]
	level.location_coords = [Vector2i(4, 4)] as Array[Vector2i]

	_scene.level_resource = level
	_scene._apply_level_if_available()
	_runner.simulate_frames(1)

	# Unit starts at (1, 1)
	assert_that(_scene._game_state.unit_manager.get_coord(0)).is_equal(Vector2i(1, 1))

	# Click on hex at (3, 1) - should move along path
	var grid = _scene._grid
	var target_pos = grid.map_to_local(Vector2i(3, 1))
	var screen_pos = grid.to_global(target_pos)

	_scene._game_state.input_controller._on_primary_action_at(screen_pos)
	_runner.simulate_frames(1)

	# Unit should have moved (may not reach (3,1) if movement limited, but should move closer)
	var new_coord = _scene._game_state.unit_manager.get_coord(0)
	assert_that(new_coord).is_not_equal(Vector2i(1, 1))

func test_click_to_move_cannot_move_out_of_range() -> void:
	# Setup a scene with one player unit with limited movement
	var _runner = scene_runner("res://Gameplay/gameplay.tscn")
	_runner.simulate_frames(1)

	var _scene = _runner.scene()
	var level = LevelScript.new()
	level.player_starts = [Vector2i(1, 1)] as Array[Vector2i]
	level.location_coords = [Vector2i(4, 4)] as Array[Vector2i]

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
	var target_pos = grid.map_to_local(Vector2i(4, 4))
	var screen_pos = grid.to_global(target_pos)

	_scene._game_state.input_controller._on_primary_action_at(screen_pos)
	_runner.simulate_frames(1)

	# Unit should not have moved (no AP)
	assert_that(_scene._game_state.unit_manager.get_coord(0)).is_equal(initial_coord)

func test_move_controller_request_move_to_coord_moves_unit():
	# Given
	var _runner = scene_runner("res://Gameplay/gameplay.tscn")
	_runner.simulate_frames(1)

	var _scene = _runner.scene()
	var level = LevelScript.new()
	level.player_starts = [Vector2i(1, 1)] as Array[Vector2i]
	_scene.level_resource = level
	_scene._apply_level_if_available()
	_runner.simulate_frames(1)

	var selected_unit_index = 0
	var initial_coord = _scene._game_state.unit_manager.get_coord(selected_unit_index)
	var target_coord = Vector2i(2, 1) # An adjacent hex

	# When
	_scene._game_state.move_controller.request_move_to_coord(target_coord)
	_runner.simulate_frames(1) # Allow movement to process

	# Then
	assert_that(_scene._game_state.unit_manager.get_coord(selected_unit_index)).is_equal(target_coord)

func test_confirm_move_consumes_incremental_cost() -> void:
	var runner = scene_runner("res://Gameplay/gameplay.tscn")
	runner.simulate_frames(1)
	var scene = runner.scene()
	var level = LevelScript.new()
	level.player_starts = [Vector2i(1, 1)] as Array[Vector2i]
	scene.level_resource = level
	scene._apply_level_if_available()
	runner.simulate_frames(1)
	var move_controller: MoveController = scene._game_state.move_controller
	var unit_manager: UnitManager = scene._game_state.unit_manager
	var unit: Unit = unit_manager.get_unit(0)
	var initial_mp := unit.get_remaining_movement_points()
	move_controller.request_move_to_coord(Vector2i(2, 1))
	runner.simulate_frames(1)
	move_controller.confirm_move()
	runner.simulate_frames(1)
	assert_that(unit.get_remaining_movement_points()).is_equal(initial_mp - 1)
	move_controller.request_move_to_coord(Vector2i(3, 1))
	runner.simulate_frames(1)
	move_controller.confirm_move()
	runner.simulate_frames(1)
	assert_that(unit.get_remaining_movement_points()).is_equal(initial_mp - 2)


func _make_enemy_roster_definition(coords: Array[Vector2i]) -> UnitRosterDefinition:
	var roster := UnitRosterDefinition.new()
	for coord in coords:
		var entry := LevelUnitSpawnEntry.new()
		entry.coord = coord
		entry.unit_scene = GenericEnemyScene
		roster.spawn_entries.append(entry)
	return roster

func test_confirm_move_requires_warning_when_leaving_threatened_hex() -> void:
	var runner = scene_runner("res://Gameplay/gameplay.tscn")
	runner.simulate_frames(1)
	var scene = runner.scene()
	var level = LevelScript.new()
	level.player_starts = [Vector2i(1, 1)] as Array[Vector2i]
	level.enemy_roster_definition = _make_enemy_roster_definition([Vector2i(1, 2)])
	scene.level_resource = level
	scene._apply_level_if_available()
	runner.simulate_frames(1)
	var move_controller: MoveController = scene._game_state.move_controller
	var unit_manager: UnitManager = scene._game_state.unit_manager
	var unit: Unit = unit_manager.get_unit(0)
	var initial_mp := unit.get_remaining_movement_points()
	move_controller.request_move_to_coord(Vector2i(2, 1))
	runner.simulate_frames(1)
	move_controller.confirm_move()
	runner.simulate_frames(1)
	assert_that(unit.get_remaining_movement_points()).is_equal(initial_mp)
	move_controller.confirm_move()
	runner.simulate_frames(1)
	assert_that(unit.get_remaining_movement_points()).is_equal(initial_mp - 1)

