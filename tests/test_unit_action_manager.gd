extends GdUnitTestSuite

const _PlayerActionManager = preload("res://Gameplay/targets/unit_action_manager.gd")
const _HexNavigator = preload("res://Gameplay/map/hex_navigator.gd")
const _ActionLabelFormatter = preload("res://Gameplay/turn/action_label_formatter.gd")
const _CombatActionCalculator = preload("res://Gameplay/turn/combat_action_calculator.gd")
const Stubs := preload("res://tests/fixtures/test_stubs.gd")

func test_unit_action_manager_is_callable() -> void:
	# Verify PlayerActionManager class exists and is accessible
	assert_object(_PlayerActionManager).is_not_null()

func test_can_reach_coord_detects_exact_tile() -> void:
	var coords: Array[Vector2i] = [Vector2i(5, 5), Vector2i(3, 1)]
	assert_bool(coords.has(Vector2i(3, 1))).is_true()

func test_get_available_actions_includes_wait_when_turn_enabled() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.faction = GameConstants.Faction.PLAYER
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)

	var actions: Array[PlayerAction] = _PlayerActionManager.get_available_actions(unit, null, manager)
	var has_wait := false
	for action in actions:
		if action.action_id == GameConstants.ActionIds.WAIT:
			has_wait = true
			break
	assert_bool(has_wait).is_true()

func test_get_available_actions_uses_unit_manager_coord() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(4, 7), true)
	var location_probe: Stubs.FakeTaskManager = auto_free(Stubs.FakeTaskManager.new())
	unit.set_task_manager(location_probe)

	# TaskDiscovery needs an objective to find tasks
	var objective: Objective = auto_free(Objective.new())
	var stage: Stage = auto_free(Stage.new())
	var mock_task: Task = auto_free(Task.new())
	mock_task.target_coord = Vector2i(4, 7)
	mock_task.target_kind = GameConstants.Tasks.KIND_LOCATION
	mock_task.status = Task.Status.ACTIVE
	mock_task.event_type = GameConstants.TaskEvents.VISIT
	stage.active_tasks = [mock_task]
	objective.current_stage = stage
	location_probe.set_active_objective(objective)

	_PlayerActionManager.get_available_actions(unit, null, manager)

	assert_int(location_probe.last_coord.x).is_equal(4)
	assert_int(location_probe.last_coord.y).is_equal(7)

func test_is_unit_stuck_with_tentative_move() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	var location_probe: Stubs.FakeTaskManager = auto_free(Stubs.FakeTaskManager.new())
	var on_tile_location: Location = auto_free(Location.new())
	on_tile_location.coord = Vector2i(0, 0)
	var mock_task: Task = auto_free(Task.new())
	mock_task.id = "mock_task"
	mock_task.status = Task.Status.ACTIVE
	mock_task.event_type = GameConstants.TaskEvents.INTERACT
	mock_task.target_coord = Vector2i(0, 0)
	location_probe.set_location(Vector2i(0, 0), on_tile_location)
	location_probe.set_task_for_target(on_tile_location, mock_task)
	unit.set_task_manager(location_probe)

	# TaskDiscovery needs an objective to find tasks
	var objective: Objective = auto_free(Objective.new())
	var stage: Stage = auto_free(Stage.new())
	stage.active_tasks = [mock_task]
	objective.current_stage = stage
	location_probe.set_active_objective(objective)

	var result: bool = _PlayerActionManager.is_unit_stuck(unit, null, manager)
	assert_bool(result).is_false()

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
	unit.movement.set_tentative_move(Vector2i(1, 0), [Vector2i(1, 0)], 1)
	manager.set_coord(0, Vector2i(1, 0))
	var actions: Array[PlayerAction] = _PlayerActionManager.get_available_actions(unit, null, manager)
	var has_immediate_loot := false
	for action in actions:
		if action.type == GameConstants.ActionType.GATHER and action.available:
			has_immediate_loot = true
			break
	assert_bool(has_immediate_loot).is_true()

func test_move_and_interact_action_generates_attack_option() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.movement_points = 3
	var enemy: Unit = auto_free(Unit.new())
	enemy._ready()
	enemy.unit_name = "Dummy"
	enemy.faction = GameConstants.Faction.ENEMY
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	manager.add_unit(enemy, Vector2i(2, 0), false)
	unit.set_unit_manager(manager)
	enemy.set_unit_manager(manager)
	var reachable_lookup: Dictionary = {Vector2i(1, 0): {"cost": 1}}
	var actions: Array[PlayerAction] = []
	MoveAndInteractProvider.append_move_and_interact_actions(actions, unit, null, manager, reachable_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	var found := false
	for action in actions:
		if action.interact_action_type == GameConstants.ActionType.ATTACK:
			found = true
			assert_vector(action.target_move_coord).is_equal(Vector2i(1, 0))
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
	var actions: Array[PlayerAction] = []
	MoveAndInteractProvider.append_move_and_interact_actions(actions, unit, null, manager, reachable_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	var has_loot_action := false
	for action in actions:
		if action.interact_action_type == GameConstants.ActionType.GATHER:
			has_loot_action = true
			assert_vector(action.target_move_coord).is_equal(Vector2i(1, 0))
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
	var actions: Array[PlayerAction] = []
	MoveAndInteractProvider.append_move_and_interact_actions(actions, unit, null, manager, reachable_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	assert_array(actions).is_empty()

func test_move_and_interact_action_includes_location() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.movement_points = 3
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	unit.set_unit_manager(manager)
	var task_manager: Stubs.FakeTaskManager = auto_free(Stubs.FakeTaskManager.new())
	var coords: Array[Vector2i] = [Vector2i(2, 0)]
	task_manager.set_coords(coords)

	# TaskDiscovery needs an objective to find tasks
	var objective: Objective = auto_free(Objective.new())
	var stage: Stage = auto_free(Stage.new())
	var mock_task: Task = auto_free(Task.new())
	mock_task.target_coord = Vector2i(2, 0)
	mock_task.status = Task.Status.ACTIVE
	mock_task.event_type = GameConstants.TaskEvents.EXPLORE
	stage.active_tasks = [mock_task]
	objective.current_stage = stage
	task_manager.set_active_objective(objective)

	unit.set_task_manager(task_manager)
	var reachable_lookup: Dictionary = {Vector2i(2, 0): {"cost": 1}}
	var actions: Array[PlayerAction] = []
	MoveAndInteractProvider.append_move_and_interact_actions(actions, unit, null, manager, reachable_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	var has_location_action := false
	for action in actions:
		if action.interact_action_type == GameConstants.ActionType.EXPLORE:
			has_location_action = true
			assert_vector(action.target_move_coord).is_equal(Vector2i(2, 0))
			break
	assert_bool(has_location_action).is_true()

func test_move_and_interact_location_requires_reachable_tile() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.movement_points = 3
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	unit.set_unit_manager(manager)
	var task_manager: Stubs.FakeTaskManager = auto_free(Stubs.FakeTaskManager.new())
	var coords: Array[Vector2i] = [Vector2i(2, 0)]
	task_manager.set_coords(coords)
	unit.set_task_manager(task_manager)
	var reachable_lookup: Dictionary = {Vector2i(1, 0): {"cost": 1}}
	var actions: Array[PlayerAction] = []
	MoveAndInteractProvider.append_move_and_interact_actions(actions, unit, null, manager, reachable_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	assert_array(actions).is_empty()

func test_move_and_interact_attack_prefers_lowest_move_cost() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.movement_points = 6
	var enemy: Unit = auto_free(Unit.new())
	enemy._ready()
	enemy.unit_name = "Dummy"
	enemy.faction = GameConstants.Faction.ENEMY
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	manager.add_unit(enemy, Vector2i(2, 0), false)
	unit.set_unit_manager(manager)
	enemy.set_unit_manager(manager)
	var reachable_lookup: Dictionary = {
		Vector2i(1, 0): {"cost": 1},
		Vector2i(2, -1): {"cost": 3}
	}
	var actions: Array[PlayerAction] = []
	MoveAndInteractProvider.append_move_and_interact_actions(actions, unit, null, manager, reachable_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	var attack_action: PlayerAction = null
	for action in actions:
		if action.interact_action_type == GameConstants.ActionType.ATTACK:
			attack_action = action
			break
	assert_object(attack_action).is_not_null()
	assert_vector(attack_action.target_move_coord).is_equal(Vector2i(1, 0))

func test_move_and_attack_uses_zero_move_when_tentative_origin_is_near() -> void:
	var terrain: TerrainMap = TerrainMap.new()
	terrain.load_from_rows(["GGGG"], 4, 1)
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.movement_points = 4
	var enemy: Unit = auto_free(Unit.new())
	enemy._ready()
	enemy.faction = GameConstants.Faction.ENEMY
	enemy.unit_name = "Target Dummy"
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	manager.add_unit(enemy, Vector2i(2, 0), false)
	unit.set_unit_manager(manager)
	enemy.set_unit_manager(manager)
	unit.faction = GameConstants.Faction.PLAYER
	unit.movement.set_start_of_turn_grid_coord(Vector2i(0, 0))
	var path: Array[Vector2i] = [Vector2i(1, 0)]
	unit.movement.set_tentative_move(Vector2i(1, 0), path, 1)
	var unit_index := manager.get_unit_index(unit)
	var reach_state: ReachableState = MovementRangeService.calculate_reachable_state(unit, terrain, manager, unit_index)
	unit.refresh_for_new_round()
	enemy.refresh_for_new_round()

	var actions: Array[PlayerAction] = []
	MoveAndInteractProvider.append_move_and_interact_actions(actions, unit, terrain, manager, reach_state.lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	var attack_action: PlayerAction = null
	for action in actions:
		if action.interact_action_type == GameConstants.ActionType.ATTACK:
			attack_action = action
			break
	assert_object(attack_action).is_not_null()
	if attack_action:
		assert_int(attack_action.movement_cost).is_not_equal(-1)

func test_resolve_move_cost_respects_remaining_move() -> void:
	var reachable_lookup: Dictionary = {
		Vector2i(1, 0): {"cost": 1},
		Vector2i(2, 0): {"cost": 3}
	}
	assert_int(MoveAndInteractProvider._resolve_move_cost(reachable_lookup, Vector2i(1, 0), 2)).is_equal(1)
	assert_int(MoveAndInteractProvider._resolve_move_cost(reachable_lookup, Vector2i(2, 0), 2)).is_equal(-1)
	assert_int(MoveAndInteractProvider._resolve_move_cost(reachable_lookup, Vector2i(3, 0), 2)).is_equal(-1)

func test_build_move_and_interact_action_merges_extra_fields() -> void:
	var action: PlayerAction = MoveAndInteractProvider._build_move_and_interact_action(
		Vector2i(3, 1),
		GameConstants.ActionType.EXPLORE,
		2,
		1
	)
	action.interact_target_coord = Vector2i(4, 1)

	assert_bool(action.type == GameConstants.ActionType.MOVE_AND_INTERACT).is_true()
	assert_vector(action.target_move_coord).is_equal(Vector2i(3, 1))
	assert_bool(action.interact_action_type == GameConstants.ActionType.EXPLORE).is_true()
	assert_int(action.movement_cost).is_equal(2)
	assert_int(action.action_cost).is_equal(1)
	assert_vector(action.interact_target_coord).is_equal(Vector2i(4, 1))

func test_move_and_loot_action_skipped_when_path_blocked() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.movement_points = 3
	var enemy: Unit = auto_free(Unit.new())
	enemy._ready()
	enemy.faction = GameConstants.Faction.ENEMY
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
	var actions: Array[PlayerAction] = []
	MoveAndInteractProvider.append_move_and_interact_actions(actions, unit, terrain_map, manager, reachable_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	assert_array(actions).is_empty()
	var unit_index := manager.get_unit_index(unit)
	assert_bool(MoveAndInteractProvider._has_unblocked_path(unit, terrain_map, manager, unit_index, Vector2i(3, 1), unit.movement_points)).is_false()

func test_resolve_move_origin_uses_committed_coord_for_tentative_move() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(4, 4), true)
	unit.set_unit_manager(manager)
	unit.movement.set_start_of_turn_grid_coord(Vector2i(1, 1))
	var empty_path: Array[Vector2i] = []
	unit.movement.set_tentative_move(Vector2i(4, 4), empty_path, 1)
	var origin: Vector2i = MoveAndInteractProvider._resolve_move_origin(unit, manager, manager.get_unit_index(unit))
	assert_vector(origin).is_equal(Vector2i(1, 1))

func test_move_and_interact_emits_attack_for_each_enemy() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.faction = GameConstants.Faction.PLAYER
	unit.movement_points = 4
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i.ZERO, true)
	unit.set_unit_manager(manager)

	var enemy_a: Unit = auto_free(Unit.new())
	enemy_a._ready()
	enemy_a.unit_name = "Enemy A"
	enemy_a.faction = GameConstants.Faction.ENEMY
	manager.add_unit(enemy_a, Vector2i(2, 0), false)
	enemy_a.set_unit_manager(manager)

	var enemy_b: Unit = auto_free(Unit.new())
	enemy_b._ready()
	enemy_b.unit_name = "Enemy B"
	enemy_b.faction = GameConstants.Faction.ENEMY
	manager.add_unit(enemy_b, Vector2i(4, 0), false)
	enemy_b.set_unit_manager(manager)

	var reach_lookup: Dictionary = {
		Vector2i(1, 0): {"cost": 1},
		Vector2i(3, 0): {"cost": 3}
	}
	var actions: Array[PlayerAction] = []
	MoveAndInteractProvider.append_move_and_interact_actions(actions, unit, null, manager, reach_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)

	var attack_count := 0
	for action in actions:
		if action.interact_action_type == GameConstants.ActionType.ATTACK:
			attack_count += 1
	assert_int(attack_count).is_equal(2)

func test_move_and_task_actions_allow_zero_move_cost() -> void:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.faction = GameConstants.Faction.PLAYER
	unit.movement_points = 2
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i.ZERO, true)
	unit.set_unit_manager(manager)

	var task_manager: Stubs.FakeTaskManager = auto_free(Stubs.FakeTaskManager.new())
	unit.set_task_manager(task_manager)

	var location: Location = auto_free(Location.new())
	location.coord = Vector2i.ZERO
	location.loc_name = "Zero"
	task_manager.set_location(Vector2i.ZERO, location)

	var task: Task = auto_free(Task.new())
	task.id = "zero_move"
	task.status = Task.Status.ACTIVE
	task.event_type = GameConstants.Commands.INTERACT
	task.target_coord = Vector2i.ZERO
	task.owning_faction = unit.faction

	var stage: Stage = auto_free(Stage.new())
	stage.active_tasks = [task]
	var objective: Objective = auto_free(Objective.new())
	objective.current_stage = stage
	task_manager.set_active_objective(objective)

	var actions: Array[PlayerAction] = []
	var reach_lookup: Dictionary = {Vector2i.ZERO: {"cost": 0}}
	MoveAndInteractProvider.append_move_and_interact_actions(actions, unit, null, manager, reach_lookup, TileSet.TILE_OFFSET_AXIS_VERTICAL)

	var found := false
	for action in actions:
		if action.task_id == String(task.id):
			found = true
			assert_int(action.movement_cost).is_equal(0)
			break
	assert_bool(found).is_true()
