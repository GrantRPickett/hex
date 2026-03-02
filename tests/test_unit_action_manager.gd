extends GdUnitTestSuite

const UnitActionManager = preload("res://Gameplay/targets/unit_action_manager.gd")
const HexNavigator = preload("res://Gameplay/map/hex_navigator.gd")
const ActionLabelFormatter = preload("res://Gameplay/turn/action_label_formatter.gd")
const CombatActionCalculator = preload("res://Gameplay/turn/combat_action_calculator.gd")
const WeatherChangeSkill = preload("res://Gameplay/skills/weather_change_skill.gd")

const LootManager = preload("res://Gameplay/targets/loot_manager.gd")
const Loot = preload("res://Gameplay/targets/loot.gd")
const InventoryItem = preload("res://Gameplay/targets/inventory_item.gd")
const TerrainMap = preload("res://Gameplay/map/terrain_map.gd")

class FakeWeatherManager extends RefCounted:
	var channeling_unit: Unit = null

	func get_channeling_unit():
		return channeling_unit
class SimpleTaskManager extends TaskManager:
	var coords: Array[Vector2i] = []
	var required_attribute := "grit"

	func set_coords(values: Array[Vector2i]) -> void:
		coords = values

	func get_location_count() -> int:
		return coords.size()

	func get_target(index: int) -> Vector2i:
		if index >= 0 and index < coords.size():
			return coords[index]
		return Vector2i(-1, -1)

	func get_location_at(coord: Vector2i) -> Location:
		if coord in coords:
			var loc := Location.new()
			loc.coord = coord
			loc.loc_name = "Mock Location"
			return loc
		return null

	func get_task_for_target(target: Target) -> Task:
		if target and target is Location and target.coord in coords:
			var t := Task.new()
			t.id = "mock_task"
			t.status = Task.Status.ACTIVE
			t.required_attribute = required_attribute
			return t
		return null

	func get_required_type(index: int, faction: int = Unit.Faction.PLAYER) -> String:
		return required_attribute

class TaskProbe extends TaskManager:
	var last_coord: Vector2i = Vector2i(-999, -999)
	var custom_locations: Dictionary = {}
	var custom_tasks: Dictionary = {}

	func set_location(coord: Vector2i, location_node: Node) -> void:
		custom_locations[coord] = location_node

	func set_task_for_location(location_node: Node, task_obj) -> void:
		custom_tasks[location_node] = task_obj

	func clear_locations() -> void:
		custom_locations.clear()
		custom_tasks.clear()

	func get_active_objective():
		var sc = GDScript.new()
		sc.source_code = "extends RefCounted\nvar is_active = true\nvar current_stage = null"
		sc.reload()
		var obj = sc.new()

		var stage_sc = GDScript.new()
		stage_sc.source_code = "extends RefCounted\nvar active_tasks = []"
		stage_sc.reload()
		var stage = stage_sc.new()
		stage.active_tasks = custom_tasks.values().filter(func(t): return t != null)

		obj.current_stage = stage
		return obj

	func get_location_at(coord: Vector2i):
		last_coord = coord
		return custom_locations.get(coord)

	func get_task_for_target(loc):
		return custom_tasks.get(loc)

	func get_location_count() -> int:
		return custom_locations.size()

	func get_target(index: int) -> Vector2i:
		var keys := custom_locations.keys()
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
	var location_probe: TaskProbe = auto_free(TaskProbe.new())
	unit.set_task_manager(location_probe)

	UnitActionManager.get_available_actions(unit, null, manager)

	assert_int(location_probe.last_coord.x).is_equal(4)
	assert_int(location_probe.last_coord.y).is_equal(7)

func test_work_on_task_only_available_on_same_tile() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	unit.faction = Unit.Faction.PLAYER
	var location_probe: TaskProbe = auto_free(TaskProbe.new())
	var on_tile_location: Location = auto_free(Location.new())
	on_tile_location.coord = Vector2i(0, 0)
	on_tile_location.loc_name = "Mock Location"
	var mock_task: Task = auto_free(Task.new())
	mock_task.id = "mock_task"
	mock_task.status = Task.Status.ACTIVE
	mock_task.event_type = "interact"
	mock_task.target_coord = Vector2i(0, 0)
	location_probe.set_location(Vector2i(0, 0), on_tile_location)
	location_probe.set_task_for_location(on_tile_location, mock_task)
	unit.set_task_manager(location_probe)

	var actions_on_tile = UnitActionManager.get_available_actions(unit, null, manager)
	var has_location_action := false
	for action in actions_on_tile:
		if action.get("type", "") == "work_on_task":
			has_location_action = true
			break
	assert_bool(has_location_action).is_true()

	location_probe.clear_locations()
	location_probe.set_location(Vector2i(1, 0), on_tile_location)

	var actions_off_tile = UnitActionManager.get_available_actions(unit, null, manager)
	var has_location_when_off_tile := false
	for action in actions_off_tile:
		if action.get("type", "") == "work_on_task":
			has_location_when_off_tile = true
			break
	assert_bool(has_location_when_off_tile).is_false()


func test_get_available_actions_uses_tentative_coord_for_location() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	unit.faction = Unit.Faction.PLAYER
	var location_probe: TaskProbe = auto_free(TaskProbe.new())
	var location: Location = auto_free(Location.new())
	location.coord = Vector2i(1, 0)
	location.loc_name = "Mock Location"
	var mock_task: Task = auto_free(Task.new())
	mock_task.id = "mock_task"
	mock_task.status = Task.Status.ACTIVE
	mock_task.event_type = "interact"
	mock_task.target_coord = Vector2i(1, 0)
	location_probe.set_location(Vector2i(1, 0), location)
	location_probe.set_task_for_location(location, mock_task)
	unit.set_task_manager(location_probe)
	unit.set_tentative_move(Vector2i(1, 0), [], 1)
	var actions = UnitActionManager.get_available_actions(unit, null, manager)
	assert_int(location_probe.last_coord.x).is_equal(1)
	assert_int(location_probe.last_coord.y).is_equal(0)
	var has_location_action := false
	for action in actions:
		if action.get("type", "") == "work_on_task":
			has_location_action = true
			break
	assert_bool(has_location_action).is_true()

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


func test_move_and_interact_action_generates_attack_option() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.movement_points = 3
	var enemy: Unit = auto_free(Unit.new())
	enemy._ready()
	enemy.unit_name = "Dummy"
	enemy.faction = Unit.Faction.ENEMY
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	manager.add_unit(enemy, Vector2i(2, 0), false)
	unit.set_unit_manager(manager)
	enemy.set_unit_manager(manager)
	var reachable_lookup: Dictionary = {Vector2i(1, 0): {"cost": 1}}
	var actions: Array[Dictionary] = []
	UnitActionManager._append_move_and_interact_actions(actions, unit, null, manager, reachable_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	var found := false
	for action in actions:
		if action.get("interact_action_type", "") == "attack":
			found = true
			assert_vector(action.get("target_move_coord", Vector2i.ZERO)).is_equal(Vector2i(1, 0))
			break
	assert_bool(found).is_true()

func test_move_and_interact_action_includes_loot() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.movement_points = 3
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	unit.set_unit_manager(manager)
	var loot_manager := LootManager.new()
	var loot := Loot.new()
	loot.add_items([InventoryItem.new()])
	loot_manager.add_loot(loot, Vector2i(1, 0))
	unit.set_loot_manager(loot_manager)
	var reachable_lookup: Dictionary = {Vector2i(1, 0): {"cost": 1}}
	var actions: Array[Dictionary] = []
	UnitActionManager._append_move_and_interact_actions(actions, unit, null, manager, reachable_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	var has_loot_action := false
	for action in actions:
		if action.get("interact_action_type", "") == "loot":
			has_loot_action = true
			assert_vector(action.get("target_move_coord", Vector2i.ZERO)).is_equal(Vector2i(1, 0))
			break
	assert_bool(has_loot_action).is_true()

func test_move_and_interact_loot_requires_reachable_tile() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.movement_points = 3
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	unit.set_unit_manager(manager)
	var loot_manager := LootManager.new()
	var loot := Loot.new()
	loot.add_items([InventoryItem.new()])
	loot_manager.add_loot(loot, Vector2i(1, 0))
	unit.set_loot_manager(loot_manager)
	var reachable_lookup: Dictionary = {Vector2i(2, 0): {"cost": 1}}
	var actions: Array[Dictionary] = []
	UnitActionManager._append_move_and_interact_actions(actions, unit, null, manager, reachable_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	assert_array(actions).is_empty()

func test_move_and_interact_action_includes_location() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.movement_points = 3
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	unit.set_unit_manager(manager)
	var task_manager: TaskManager = auto_free(SimpleTaskManager.new())
	var coords: Array[Vector2i] = [Vector2i(2, 0)]
	task_manager.set_coords(coords)
	unit.set_task_manager(task_manager)
	var reachable_lookup: Dictionary = {Vector2i(2, 0): {"cost": 1}}
	var actions: Array[Dictionary] = []
	UnitActionManager._append_move_and_interact_actions(actions, unit, null, manager, reachable_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	var has_location_action := false
	for action in actions:
		if action.get("interact_action_type", "") == "work_on_task":
			has_location_action = true
			assert_vector(action.get("target_move_coord", Vector2i.ZERO)).is_equal(Vector2i(2, 0))
			break
	assert_bool(has_location_action).is_true()

func test_move_and_interact_location_requires_reachable_tile() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.movement_points = 3
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	unit.set_unit_manager(manager)
	var task_manager: TaskManager = auto_free(SimpleTaskManager.new())
	var coords: Array[Vector2i] = [Vector2i(2, 0)]
	task_manager.set_coords(coords)
	unit.set_task_manager(task_manager)
	var reachable_lookup: Dictionary = {Vector2i(1, 0): {"cost": 1}}
	var actions: Array[Dictionary] = []
	UnitActionManager._append_move_and_interact_actions(actions, unit, null, manager, reachable_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	assert_array(actions).is_empty()


func test_move_and_interact_attack_prefers_lowest_move_cost() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.movement_points = 6
	var enemy: Unit = auto_free(Unit.new())
	enemy._ready()
	enemy.unit_name = "Dummy"
	enemy.faction = Unit.Faction.ENEMY
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	manager.add_unit(enemy, Vector2i(2, 0), false)
	unit.set_unit_manager(manager)
	enemy.set_unit_manager(manager)
	var reachable_lookup: Dictionary = {
		Vector2i(1, 0): {"cost": 1},
		Vector2i(2, -1): {"cost": 3}
	}
	var actions: Array[Dictionary] = []
	UnitActionManager._append_move_and_interact_actions(actions, unit, null, manager, reachable_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	var attack_action := {}
	for action in actions:
		if action.get("interact_action_type", "") == "attack":
			attack_action = action
			break
	assert_dict(attack_action).is_not_null()
	assert_vector(attack_action.get("target_move_coord", Vector2i.ZERO)).is_equal(Vector2i(1, 0))

func test_move_and_attack_uses_zero_move_when_tentative_origin_is_adjacent() -> void:
	var terrain: TerrainMap = TerrainMap.new()
	terrain.load_from_rows(["GGGG"], 4, 1)
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.movement_points = 4
	var enemy: Unit = auto_free(Unit.new())
	enemy._ready()
	enemy.faction = Unit.Faction.ENEMY
	enemy.unit_name = "Target Dummy"
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	manager.add_unit(enemy, Vector2i(2, 0), false)
	unit.set_unit_manager(manager)
	enemy.set_unit_manager(manager)
	unit.faction = Unit.Faction.PLAYER
	unit.movement_behavior.set_start_of_turn_grid_coord(Vector2i(0, 0))
	var path: Array[Vector2i] = [Vector2i(1, 0)]
	unit.set_tentative_move(Vector2i(1, 0), path, 1)
	var unit_index := manager.get_unit_index(unit)
	var reach_state := ReachableStateCalculator.calculate(unit, terrain, manager, unit_index)
	unit.refresh_for_new_round()
	enemy.refresh_for_new_round()

	var actions: Array[Dictionary] = []
	UnitActionManager._append_move_and_interact_actions(actions, unit, terrain, manager, reach_state.lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	var attack_action := {}
	for action in actions:
		if action.get("interact_action_type", "") == "attack":
			attack_action = action
			break
	assert_dict(attack_action).is_not_null()
	# The test expects reachable_lookup to be calculated from ORIGIN (0,0)
	# Hence destination (1,0) should have cost 1.
	if attack_action.is_empty():
		push_error("No attack action found in test_move_and_attack_uses_zero_move")
	assert_int(attack_action.get("movement_cost", -1)).is_not_equal(-1)
	assert_str(attack_action.get("label", "")).is_not_empty()
func test_resolve_move_cost_respects_remaining_move() -> void:
	var reachable_lookup := {
		Vector2i(1, 0): {"cost": 1},
		Vector2i(2, 0): {"cost": 3}
	}
	assert_int(UnitActionManager._resolve_move_cost(reachable_lookup, Vector2i(1, 0), 2)).is_equal(1)
	assert_int(UnitActionManager._resolve_move_cost(reachable_lookup, Vector2i(2, 0), 2)).is_equal(-1)
	assert_int(UnitActionManager._resolve_move_cost(reachable_lookup, Vector2i(3, 0), 2)).is_equal(-1)

func test_build_move_and_interact_action_merges_extra_fields() -> void:
	var extra := {
		"location_index": 2,
		"interact_target_coord": Vector2i(4, 1)
	}
	var action := UnitActionManager._build_move_and_interact_action(
		"Move & Work Task (M2/A1)",
		Vector2i(3, 1),
		"task",
		2,
		1,
		extra
	)
	assert_str(action.get("type", "")).is_equal("move_and_interact")
	assert_vector(action.get("target_move_coord", Vector2i.ZERO)).is_equal(Vector2i(3, 1))
	assert_str(action.get("interact_action_type", "")).is_equal("task")
	assert_int(action.get("movement_cost", -1)).is_equal(2)
	assert_int(action.get("action_cost", -1)).is_equal(1)
	assert_int(action.get("location_index", -1)).is_equal(2)
	assert_vector(action.get("interact_target_coord", Vector2i.ZERO)).is_equal(Vector2i(4, 1))

func test_move_and_loot_action_skipped_when_path_blocked() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.movement_points = 3
	var enemy: Unit = auto_free(Unit.new())
	enemy._ready()
	enemy.faction = Unit.Faction.ENEMY
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(1, 1), true)
	manager.add_unit(enemy, Vector2i(2, 1), false)
	unit.set_unit_manager(manager)
	enemy.set_unit_manager(manager)
	var terrain_map: TerrainMap = auto_free(TerrainMap.new())
	terrain_map.load_from_rows(["GGG"], 3, 1)
	var loot_manager := LootManager.new()
	var loot := Loot.new()
	loot.add_items([InventoryItem.new()])
	loot_manager.add_loot(loot, Vector2i(3, 1))
	unit.set_loot_manager(loot_manager)
	var reachable_lookup: Dictionary = {Vector2i(3, 1): {"cost": 2}}
	var actions: Array[Dictionary] = []
	UnitActionManager._append_move_and_interact_actions(actions, unit, terrain_map, manager, reachable_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	assert_array(actions).is_empty()
	var unit_index := manager.get_unit_index(unit)
	assert_bool(UnitActionManager._has_unblocked_path(unit, terrain_map, manager, unit_index, Vector2i(3, 1), unit.movement_points)).is_false()

func test_resolve_move_origin_uses_committed_coord_for_tentative_move() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(4, 4), true)
	unit.set_unit_manager(manager)
	unit.movement_behavior.set_start_of_turn_grid_coord(Vector2i(1, 1))
	var empty_path: Array[Vector2i] = []
	unit.movement_behavior.set_tentative_move(Vector2i(4, 4), empty_path, 1)
	var origin = UnitActionManager._resolve_move_origin(unit, manager, manager.get_unit_index(unit))
	assert_vector(origin).is_equal(Vector2i(1, 1))
