extends GdUnitTestSuite

const UnitActionManager = preload("res://Gameplay/unit_action_manager.gd")

class GoalProbe extends GoalManager:
	var last_coord: Vector2i = Vector2i(-999, -999)
	var custom_goals: Dictionary = {}

	func set_goal(coord: Vector2i, goal: Goal) -> void:
		custom_goals[coord] = goal

	func clear_goals() -> void:
		custom_goals.clear()

	func get_goal_at_cell(coord: Vector2i):
		last_coord = coord
		return custom_goals.get(coord)

	func get_goal_count() -> int:
		return custom_goals.size()

	func get_goal_node(index: int):
		var values := custom_goals.values()
		if index >= 0 and index < values.size():
			return values[index]
		return null

	func get_target(index: int) -> Vector2i:
		var keys := custom_goals.keys()
		if index >= 0 and index < keys.size():
			return keys[index]
		return Vector2i.ZERO

func test_unit_action_manager_is_callable() -> void:
	# Verify UnitActionManager class exists and is accessible
	assert_object(UnitActionManager).is_not_null()

func test_is_unit_stuck_called_with_null_unit() -> void:
	# Verify is_unit_stuck returns true for null/invalid unit
	var result = UnitActionManager.is_unit_stuck(null, null, null)
	assert_bool(result).is_true()

func test_get_available_actions_called() -> void:
	# Verify get_available_actions is callable (returns empty array for null unit)
	var result = UnitActionManager.get_available_actions(null, null, null)
	assert_array(result).is_empty()

func test_format_action_label_reports_counts() -> void:
	var label := UnitActionManager._format_action_label("Attack", 2, 3)
	assert_str(label).contains("2 adjacent")
	assert_str(label).contains("3 reachable")

func test_has_reachable_adjacent_respects_distance() -> void:
	var coords := [Vector2i(0, 1), Vector2i(2, 2)]
	var result := UnitActionManager._has_reachable_adjacent(coords, Vector2i(0, 0), TileSet.TILE_OFFSET_AXIS_VERTICAL, 1.5)
	assert_bool(result).is_true()

func test_can_reach_coord_detects_exact_tile() -> void:
	var coords := [Vector2i(5, 5), Vector2i(3, 1)]
	assert_bool(UnitActionManager._can_reach_coord(coords, Vector2i(3, 1))).is_true()

func test_get_available_actions_uses_unit_manager_coord() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(4, 7), true)
	var goal_probe: GoalProbe = auto_free(GoalProbe.new())
	unit._goal_manager = goal_probe

	UnitActionManager.get_available_actions(unit, null, manager)

	assert_int(goal_probe.last_coord.x).is_equal(4)
	assert_int(goal_probe.last_coord.y).is_equal(7)

func test_work_on_goal_only_available_on_same_tile() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	var goal_probe: GoalProbe = auto_free(GoalProbe.new())
	var on_tile_goal: Goal = Goal.new()
	on_tile_goal.position = Vector2.ZERO
	goal_probe.set_goal(Vector2i(0, 0), on_tile_goal)
	unit._goal_manager = goal_probe

	var actions_on_tile = UnitActionManager.get_available_actions(unit, null, manager)
	var has_goal_action := false
	for action in actions_on_tile:
		if action.get("type", "") == "work_on_goal":
			has_goal_action = true
			break
	assert_bool(has_goal_action).is_true()

	goal_probe.clear_goals()
	goal_probe.set_goal(Vector2i(1, 0), on_tile_goal)

	var actions_off_tile = UnitActionManager.get_available_actions(unit, null, manager)
	var has_goal_when_off_tile := false
	for action in actions_off_tile:
		if action.get("type", "") == "work_on_goal":
			has_goal_when_off_tile = true
			break
	assert_bool(has_goal_when_off_tile).is_false()


func test_get_available_actions_uses_tentative_coord_for_goal() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	var goal_probe: GoalProbe = auto_free(GoalProbe.new())
	var goal: Goal = Goal.new()
	goal.position = Vector2.ZERO
	goal_probe.set_goal(Vector2i(1, 0), goal)
	unit._goal_manager = goal_probe
	unit.set_tentative_move(Vector2i(1, 0), [], 1)
	var actions = UnitActionManager.get_available_actions(unit, null, manager)
	assert_int(goal_probe.last_coord.x).is_equal(1)
	assert_int(goal_probe.last_coord.y).is_equal(0)
	var has_goal_action := false
	for action in actions:
		if action.get("type", "") == "work_on_goal":
			has_goal_action = true
			break
	assert_bool(has_goal_action).is_true()
