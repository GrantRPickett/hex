extends GdUnitTestSuite


var _manager: GoalManager
var _grid: TileMapLayer

func before_test() -> void:
	_manager = auto_free(GoalManager.new())
	_grid = auto_free(TileMapLayer.new())
	_grid.tile_set = auto_free(TileSet.new())

	# Add children to a parent so they can be managed if needed,
	# though for unit tests we just need the references.
	add_child(_manager)

func test_setup_positions_sprites() -> void:
	var goals: Array[Vector2i] = [Vector2i(3, 3), Vector2i(4, 4)]
	var goal1 = auto_free(Goal.new())
	goal1.position = _grid.map_to_local(goals[0])
	var goal2 = auto_free(Goal.new())
	goal2.position = _grid.map_to_local(goals[1])
	var goal_nodes: Array[Goal] = [goal1, goal2]

	_manager.setup(goals, goal_nodes, _grid)

	assert_vector(_manager.get_target(0)).is_equal(Vector2i(3, 3))
	assert_vector(_manager.get_target(1)).is_equal(Vector2i(4, 4))
	assert_vector(_manager.get_goal_node(0).coord).is_equal(Vector2i(3, 3))
	assert_vector(_manager.get_goal_node(1).coord).is_equal(Vector2i(4, 4))

	# Verify goal nodes are visible
	assert_bool(_manager.get_goal_node(0).visible).is_true()
	assert_bool(_manager.get_goal_node(1).visible).is_true()

func test_setup_hides_unused_sprites() -> void:
	var goals: Array[Vector2i] = [Vector2i(3, 3)]
	var goal1 = auto_free(Goal.new())
	goal1.position = _grid.map_to_local(goals[0])
	var goal2 = auto_free(Goal.new())
	goal2.position = Vector2i.ZERO
	var goal_nodes: Array[Goal] = [goal1, goal2]

	_manager.setup(goals, goal_nodes, _grid)

	assert_bool(_manager.get_goal_node(0).visible).is_true()
	assert_bool(_manager.get_goal_node(1).visible).is_false()

func test_set_target_updates_value() -> void:
	var goals: Array[Vector2i] = [Vector2i(0, 0)]
	var goal1 = auto_free(Goal.new())
	goal1.position = _grid.map_to_local(goals[0])
	var goal_nodes: Array[Goal] = [goal1]
	_manager.setup(goals, goal_nodes, _grid)
	_manager.set_target(0, Vector2i(5, 5))
	assert_vector(_manager.get_target(0)).is_equal(Vector2i(5, 5))
	# GoalManager updates the node position to world coordinates
	var expected_pos = _grid.map_to_local(Vector2i(5, 5))
	assert_vector(_manager.get_goal_node(0).position).is_equal(expected_pos)

func test_get_targets() -> void:
	var goals: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 2)]
	var goal1 = auto_free(Goal.new())
	goal1.position = _grid.map_to_local(goals[0])
	var goal2 = auto_free(Goal.new())
	goal2.position = _grid.map_to_local(goals[1])
	var goal_nodes: Array[Goal] = [goal1, goal2]
	_manager.setup(goals, goal_nodes, _grid)
	var targets = _manager.get_targets()
	assert_array(targets).is_equal(goals)