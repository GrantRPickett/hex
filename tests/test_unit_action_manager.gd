extends GdUnitTestSuite

const UnitActionManager = preload("res://Gameplay/unit_action_manager.gd")
const HexNavigator = preload("res://Gameplay/hex_navigator.gd")
const ActionLabelFormatter = preload("res://Gameplay/action_label_formatter.gd")
const CombatActionCalculator = preload("res://Gameplay/combat_action_calculator.gd")
const WeatherChangeSkill = preload("res://Gameplay/weather_change_skill.gd")

class FakeWeatherManager extends RefCounted:
	var channeling_unit: Unit = null

	func get_channeling_unit():
		return channeling_unit

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
	var label := ActionLabelFormatter.format("Attack", 2, 3)
	assert_str(label).contains("2 adjacent")
	assert_str(label).contains("3 reachable")

func test_has_reachable_adjacent_respects_distance() -> void:
	var coords := [Vector2i(0, 1), Vector2i(2, 2)]
	var calculator = CombatActionCalculator.new()
	var result := calculator.has_reachable_adjacent(coords, Vector2i(0, 0), TileSet.TILE_OFFSET_AXIS_VERTICAL, 1.5)
	assert_bool(result).is_true()

func test_attack_action_defaults_to_first_reachable_target() -> void:
	var calculator := CombatActionCalculator.new()
	var attacker: Unit = auto_free(Unit.new())
	var reachable_enemy: Unit = auto_free(Unit.new())
	var actions: Array[Dictionary] = []
	calculator._add_attack_action(actions, attacker, [], [reachable_enemy])
	assert_int(actions.size()).is_equal(1)
	var action: Dictionary = actions[0]
	assert_object(action.get("target")).is_equal(reachable_enemy)
	var targets: Array = action.get("targets", [])
	assert_int(targets.size()).is_equal(1)
	assert_object(targets[0]).is_equal(reachable_enemy)
	assert_bool(action.get("available", false)).is_false()


func test_attack_action_targets_include_adjacent_and_reachable_units() -> void:
	var calculator := CombatActionCalculator.new()
	var attacker: Unit = auto_free(Unit.new())
	var adjacent_enemy: Unit = auto_free(Unit.new())
	var reachable_enemy: Unit = auto_free(Unit.new())
	var actions: Array[Dictionary] = []
	calculator._add_attack_action(actions, attacker, [adjacent_enemy], [reachable_enemy])
	assert_int(actions.size()).is_equal(1)
	var action: Dictionary = actions[0]
	var targets: Array = action.get("targets", [])
	assert_int(targets.size()).is_equal(2)
	assert_object(targets[0]).is_equal(adjacent_enemy)
	assert_object(targets[1]).is_equal(reachable_enemy)
	assert_bool(action.get("available", false)).is_true()



func test_aid_action_defaults_to_first_reachable_target() -> void:
	var calculator := CombatActionCalculator.new()
	var healer: Unit = auto_free(Unit.new())
	var reachable_ally: Unit = auto_free(Unit.new())
	reachable_ally.max_willpower = 10
	reachable_ally.willpower = 5
	var actions: Array[Dictionary] = []
	calculator._add_aid_action(actions, [], [reachable_ally])
	assert_int(actions.size()).is_equal(1)
	var action: Dictionary = actions[0]
	assert_object(action.get("target")).is_equal(reachable_ally)
	var targets: Array = action.get("targets", [])
	assert_int(targets.size()).is_equal(1)
	assert_object(targets[0]).is_equal(reachable_ally)
	assert_bool(action.get("available", false)).is_false()
	assert_bool(action.get("reachable", false)).is_true()


func test_aid_action_targets_include_adjacent_and_reachable_units() -> void:
	var calculator := CombatActionCalculator.new()
	var healer: Unit = auto_free(Unit.new())
	var adjacent_ally: Unit = auto_free(Unit.new())
	var reachable_ally: Unit = auto_free(Unit.new())
	reachable_ally.max_willpower = 10
	reachable_ally.willpower = 5
	var actions: Array[Dictionary] = []
	calculator._add_aid_action(actions, [adjacent_ally], [reachable_ally])
	assert_int(actions.size()).is_equal(1)
	var action: Dictionary = actions[0]
	var targets: Array = action.get("targets", [])
	assert_int(targets.size()).is_equal(2)
	assert_object(targets[0]).is_equal(adjacent_ally)
	assert_object(targets[1]).is_equal(reachable_ally)
	assert_bool(action.get("available", false)).is_true()
	assert_bool(action.get("reachable", false)).is_true()




func test_can_reach_coord_detects_exact_tile() -> void:
	var coords := [Vector2i(5, 5), Vector2i(3, 1)]
	assert_bool(HexNavigator.can_reach_coord(coords, Vector2i(3, 1))).is_true()

func test_get_available_actions_uses_unit_manager_coord() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(4, 7), true)
	var goal_probe: GoalProbe = auto_free(GoalProbe.new())
	unit.set_goal_manager(goal_probe)

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
	unit.set_goal_manager(goal_probe)

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
	unit.set_goal_manager(goal_probe)
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

func test_loot_action_available_after_tentative_move() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	unit.set_unit_manager(manager)
	manager.add_unit(unit, Vector2i.ZERO, true)
	var loot_manager: LootManager = auto_free(LootManager.new())
	var loot := Loot.new()
	loot.position = Vector2(64, 0)
	loot_manager.add_loot(loot, Vector2i(1, 0))
	unit.set_loot_manager(loot_manager)
	unit.position = Vector2.ZERO
	unit.set_tentative_move(Vector2i(1, 0), [Vector2i(1, 0)], 1)
	manager.set_coord(0, Vector2i(1, 0))
	var actions := UnitActionManager.get_available_actions(unit, null, manager)
	var has_immediate_loot := false
	for action in actions:
		if action.get("type", "") == "loot" and action.get("available", false):
			has_immediate_loot = true
			break
	assert_bool(has_immediate_loot).is_true()

func test_unit_initializes_with_empty_skills_array() -> void:
	var unit := Unit.new()
	assert_array(unit.skills).is_empty()

func test_weather_skill_action_respects_channeling_state() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i.ZERO, true)
	var weather_skill: WeatherChangeSkill = WeatherChangeSkill.new()
	weather_skill.skill_name = "Test Channel"
	unit.skills.append(weather_skill)
	var weather := FakeWeatherManager.new()
	weather.channeling_unit = null
	var actions := UnitActionManager.get_available_actions_with_weather(unit, null, manager, weather)
	var skill_action := _find_skill_action(actions, weather_skill)
	assert_dict(skill_action).is_not_null()
	assert_bool(skill_action.available).is_true()
	weather.channeling_unit = unit
	actions = UnitActionManager.get_available_actions_with_weather(unit, null, manager, weather)
	skill_action = _find_skill_action(actions, weather_skill)
	assert_dict(skill_action).is_not_null()
	assert_bool(skill_action.available).is_false()

func _find_skill_action(actions: Array, skill: Skill) -> Dictionary:
	for action in actions:
		if action.get("type", "") == "skill" and action.get("skill") == skill:
			return action
	return {}
