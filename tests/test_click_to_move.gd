extends GdUnitTestSuite

const LevelScript := preload("res://level/level.gd")
const GenericEnemyScene := preload("res://Gameplay/scene_templates/generic_enemy.tscn")

func _register(node: Node) -> Node:
	if node == null:
		return node
	return auto_free(node)

func _get_screen_pos(scene: Node2D, coord: Vector2i) -> Vector2:
	var grid: TileMapLayer = scene.get_node("Grid")
	var local_pos: Vector2 = grid.map_to_local(coord)
	var global_pos = grid.to_global(local_pos)
	# InputController uses grid.get_viewport().get_canvas_transform().affine_inverse()
	# so we should multiply by the canvas transform here to get a "screen" pos that reverses correctly.
	return grid.get_canvas_transform() * global_pos

func test_click_to_move_single_hex() -> void:
	# Setup a scene with one player unit
	var _runner = scene_runner("res://Gameplay/gameplay.tscn")
	_runner.simulate_frames(10)

	var _scene = _runner.scene()
	var level: LevelScript = LevelScript.new()
	level.player_starts = [Vector2i(1, 1)] as Array[Vector2i]
	var task_entry := LevelTaskEntry.new()
	task_entry.coord = Vector2i(4, 4)
	level.locations.append(task_entry)

	_scene.level = level
	_scene.set_level_and_rebuild(level)
	_runner.simulate_frames(10) # Enough for spawning and roster build

	# Ensure it is the player's turn
	_scene._game_state.turn_controller.rebuild_turn_roster()
	_scene._game_state.turn_controller.start_next_turn()
	_runner.simulate_frames(2)

	# Unit starts at (1, 1)
	assert_that(_scene._game_state.unit_manager.get_coord(0)).is_equal(Vector2i(1, 1))

	# Click on near hex (2, 1) - should move there
	var screen_pos: Vector2i = _get_screen_pos(_scene, Vector2i(2, 1))

	_scene._game_state.input_controller._on_primary_action_at(screen_pos)
	_runner.simulate_frames(10)

	# Unit should have moved
	assert_that(_scene._game_state.unit_manager.get_coord(0)).is_equal(Vector2i(2, 1))

func test_click_to_move_multi_hex_path() -> void:
	# Setup a scene with one player unit
	var _runner = scene_runner("res://Gameplay/gameplay.tscn")
	_runner.simulate_frames(10)

	var _scene = _runner.scene()
	var level: LevelScript = LevelScript.new()
	level.player_starts = [Vector2i(1, 1)] as Array[Vector2i]
	var task_entry := LevelTaskEntry.new()
	task_entry.coord = Vector2i(4, 4)
	level.locations.append(task_entry)

	_scene.level = level
	_scene.set_level_and_rebuild(level)
	_runner.simulate_frames(10)

	# Ensure it is the player's turn
	_scene._game_state.turn_controller.rebuild_turn_roster()
	_scene._game_state.turn_controller.start_next_turn()
	_runner.simulate_frames(2)

	# Unit starts at (1, 1)
	assert_that(_scene._game_state.unit_manager.get_coord(0)).is_equal(Vector2i(1, 1))

	# Click on hex at (3, 1) - should move along path
	var screen_pos: Vector2i = _get_screen_pos(_scene, Vector2i(3, 1))

	_scene._game_state.input_controller._on_primary_action_at(screen_pos)
	_runner.simulate_frames(10)

	# Unit should have moved
	var new_coord: Vector2i = _scene._game_state.unit_manager.get_coord(0)
	assert_that(new_coord).is_not_equal(Vector2i(1, 1))

func test_click_to_move_cannot_move_out_of_range() -> void:
	# Setup a scene with one player unit with limited movement
	var _runner = scene_runner("res://Gameplay/gameplay.tscn")
	_runner.simulate_frames(10)

	var _scene = _runner.scene()
	var level: LevelScript = LevelScript.new()
	level.player_starts = [Vector2i(1, 1)] as Array[Vector2i]
	var task_entry := LevelTaskEntry.new()
	task_entry.coord = Vector2i(4, 4)
	level.locations.append(task_entry)

	_scene.level = level
	_scene.set_level_and_rebuild(level)
	_runner.simulate_frames(10)

	# Set unit movement to 0 to prevent moving
	var unit: Unit = _scene._game_state.unit_manager.get_unit(0)
	if unit:
		unit.movement.consume_move(unit.movement.get_remaining_movement_points())

	var initial_coord: Vector2i = _scene._game_state.unit_manager.get_coord(0)

	# Try to click on a hex far away
	var screen_pos: Vector2i = _get_screen_pos(_scene, Vector2i(4, 4))

	_scene._game_state.input_controller._on_primary_action_at(screen_pos)
	_runner.simulate_frames(10) # Allow movement to conclude and signals to propagate

	# Unit should not have moved (no AP)
	assert_that(_scene._game_state.unit_manager.get_coord(0)).is_equal(initial_coord)

func test_move_controller_request_move_to_coord_moves_unit():
	# Given
	var _runner = scene_runner("res://Gameplay/gameplay.tscn")
	_runner.simulate_frames(10)

	var _scene = _runner.scene()
	var level: LevelScript = LevelScript.new()
	level.player_starts = [Vector2i(1, 1)] as Array[Vector2i]
	_scene.level = level
	_scene.set_level_and_rebuild(level)
	_runner.simulate_frames(10)

	var selected_unit_index: int = 0
	var _initial_coord: Vector2i = _scene._game_state.unit_manager.get_coord(selected_unit_index)
	var target_coord: Vector2i = Vector2i(2, 1) # An near hex

	# When
	_scene._game_state.move_controller.request_move_to_coord(target_coord)
	_runner.simulate_frames(10) # Allow movement to process

	# Then
	assert_that(_scene._game_state.unit_manager.get_coord(selected_unit_index)).is_equal(target_coord)

func test_confirm_move_consumes_incremental_cost() -> void:
	var runner = scene_runner("res://Gameplay/gameplay.tscn")
	runner.simulate_frames(10)
	var scene = runner.scene()
	var level: LevelScript = LevelScript.new()
	level.player_starts = [Vector2i(1, 1)] as Array[Vector2i]
	scene.level = level
	scene.set_level_and_rebuild(level)
	runner.simulate_frames(10)
	var move_controller: MoveController = scene._game_state.move_controller
	var unit_manager: UnitManager = scene._game_state.unit_manager
	var unit: Unit = unit_manager.get_unit(0)

	# Ensure unit is selected and it's their turn
	unit_manager.select_index(0)
	scene._game_state.turn_controller.rebuild_turn_roster()
	scene._game_state.turn_controller.start_next_turn()
	runner.simulate_frames(2)

	var initial_mp := unit.movement.get_remaining_movement_points()
	move_controller.request_move_to_coord(Vector2i(2, 1))
	runner.simulate_frames(2)
	move_controller.confirm_move()
	runner.simulate_frames(2)
	assert_that(unit.movement.get_remaining_movement_points()).is_equal(initial_mp - 1)

	move_controller.request_move_to_coord(Vector2i(3, 1))
	runner.simulate_frames(2)
	move_controller.confirm_move()
	runner.simulate_frames(2)
	assert_that(unit.movement.get_remaining_movement_points()).is_equal(initial_mp - 2)


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
	runner.simulate_frames(10)
	var scene = runner.scene()
	var level: LevelScript = LevelScript.new()
	level.player_starts = [Vector2i(1, 1)] as Array[Vector2i]
	level.enemy_roster_definition = _make_enemy_roster_definition([Vector2i(1, 2)])
	scene.level = level
	scene.set_level_and_rebuild(level)
	runner.simulate_frames(10)

	var move_controller: MoveController = scene._game_state.move_controller
	var unit_manager: UnitManager = scene._game_state.unit_manager
	var unit: Unit = unit_manager.get_unit(0)

	unit_manager.select_index(0)
	scene._game_state.turn_controller.rebuild_turn_roster()
	scene._game_state.turn_controller.start_next_turn()
	runner.simulate_frames(2)

	var initial_mp := unit.movement.get_remaining_movement_points()
	move_controller.request_move_to_coord(Vector2i(2, 1))
	runner.simulate_frames(2)

	# First confirm should trigger warning (leaving threatened hex)
	move_controller.confirm_move()
	runner.simulate_frames(2)
	assert_that(unit.movement.get_remaining_movement_points()).is_equal(initial_mp)

	# Second confirm should actually move
	move_controller.confirm_move()
	runner.simulate_frames(2)
	assert_that(unit.movement.get_remaining_movement_points()).is_equal(initial_mp - 1)
